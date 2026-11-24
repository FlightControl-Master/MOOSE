-- P0-I3 loader regressions. In-memory file capabilities expose each failure.
-- No DCS globals are installed and no production files are modified.
local Loader = dofile("tests/support/local-pathfinding-loader.lua")
local passed, failed = 0, 0
local function test(name, callback)
  local ok, failure = pcall(callback)
  if ok then
    passed = passed + 1
    print("PASS " .. name)
  else
    failed = failed + 1
    print("FAIL " .. name .. ": " .. tostring(failure))
  end
end
local function equal(first, second) assert(first == second, tostring(first) .. " ~= " .. tostring(second)) end
local function raises(callback, fragment)
  local ok, failure = pcall(callback)
  assert(not ok, "missing error")
  if fragment then assert(tostring(failure):find(fragment, 1, true), tostring(failure)) end
  return failure
end
local function setup(sources, options)
  options = options or {}
  local files, reference = {}, {SchemaVersion = 1, RunId = "unit", BuildToken = "token",
    Members = {}, Limits = {MaxMemberBytes = 4096, MaxSourceBytes = 8192, MaxPackageBytes = 32768}}
  for index, source in ipairs(sources) do
    reference.Members[index] = {Index = index, LogicalPath = source.Path,
      PreparedPath = "prepared/" .. index, LoadedPath = "loaded/" .. index,
      Bytes = #source.Bytes, SHA256 = string.rep("a", 64)}
    files["root/prepared/" .. index] = source.Bytes
  end
  local capability = {}
  function capability.open(path, mode)
    if mode == "rb" and files[path] == nil then return nil, "missing" end
    local file = {Closed = false}
    function file:read(size)
      if options.ReadError then return nil, "read_error" end
      return files[path]:sub(1, size)
    end
    function file:write(bytes)
      if options.WriteError then return nil, "write_error" end
      files[path] = bytes
      return self
    end
    function file:close()
      self.Closed = true
      capability.Closed = (capability.Closed or 0) + 1
      if options.CloseError then return nil, "close_error" end
      return true
    end
    return file
  end
  local function rename(first, second)
    if options.RenameError then return nil, "rename_error" end
    assert(files[second] == nil, "overwrite")
    files[second], files[first] = files[first], nil
    return true
  end
  local globals = setmetatable({}, {__index = _G})
  globals._G = globals
  local compile = options.Compile or loadstring
  local context = Loader.New(reference, {Root = "root", IO = capability, Rename = rename,
    Globals = globals, Compile = compile})
  return context, files, reference, capability, globals
end

test("compiler receives exactly the archived CRLF and UTF-8 bytes", function()
  local bytes = "-- Grüße\r\nreturn 42\r\n"
  local context, files
  context, files = setup({{Path = "unit.lua", Bytes = bytes}}, {Compile = function(buffer, path)
    equal(files["root/loaded/1"], buffer)
    -- A checkout/source replacement after read cannot change this compiled buffer.
    files["root/prepared/1"] = "error('different version')"
    return loadstring(buffer, path)
  end})
  equal(context:Load("unit.lua"), 42)
  equal(files["root/loaded/1"], bytes)
  equal(#context.Events, 4)
end)

test("deduplicated module returns preserve cached false and trailing nil", function()
  local context = setup({{Path = "unit.lua", Bytes = "return false, nil, 0, nil"}})
  local function check(...)
    equal(select("#", ...), 4)
    local first, second, third = ...
    equal(first, false)
    equal(second, nil)
    equal(third, 0)
  end
  check(context:Load("unit.lua"))
  check(context:Load("unit.lua"))
  equal(context.Events[5].Kind, "deduplicated")
end)

test("failed chunk never has a returned load event", function()
  local context, files = setup({{Path = "unit.lua", Bytes = "error('original failure')"}})
  raises(function() context:Load("unit.lua") end, "original failure")
  equal(context.Events[3].Kind, "entered")
  equal(#context.Events, 3)
  equal(context.Loaded["unit.lua"], nil)
  assert(files["root/loaded/1"])
end)

test("undeclared, traversing, cyclic and post-checkpoint loads stop", function()
  local context = setup({{Path = "tests/support/unit.lua",
    Bytes = "local import=...; return import('tests/support/unit.lua')"}})
  raises(function() context:Load("../unit.lua") end, "traversal")
  raises(function() context:Load("missing.lua") end, "undeclared")
  raises(function() context:Load("tests/support/unit.lua") end, "cyclic")
  context.Sealed = true
  raises(function() context:Load("tests/support/unit.lua") end, "after checkpoint")
end)

test("BOM, shebang and binary chunks are explicitly rejected", function()
  for _, prefix in ipairs({"\239\187\191", "#!", "\27"}) do
    local context = setup({{Path = "unit.lua", Bytes = prefix .. "return 1"}})
    raises(function() context:Load("unit.lua") end, "unsupported")
    equal(#context.Events, 0)
  end
end)

test("source length and package caps reject before publication", function()
  local context, files, reference = setup({{Path = "unit.lua", Bytes = "return 1"}})
  files["root/prepared/1"] = "return 12"
  raises(function() context:Load("unit.lua") end, "length mismatch")
  equal(files["root/loaded/1"], nil)
  reference.Limits.MaxPackageBytes = 1
  raises(function() context:Write("result", "12", 2) end, "package limit")
end)

for _, kind in ipairs({"ReadError", "WriteError", "CloseError", "RenameError"}) do
  test(kind .. " closes owned files and prevents final loaded member", function()
    local options = {}
    options[kind] = true
    local context, files, _, capability = setup({{Path = "unit.lua", Bytes = "return 1"}}, options)
    raises(function() context:Load("unit.lua") end, kind:gsub("Error", "_error"):lower())
    equal(files["root/loaded/1"], nil)
    assert(capability.Closed > 0)
    equal(#context.Events, 0)
  end)
end

test("existing final and partial files are never overwritten", function()
  for _, suffix in ipairs({"", ".partial"}) do
    local context, files = setup({{Path = "unit.lua", Bytes = "return 1"}})
    files["root/loaded/1" .. suffix] = "previous"
    raises(function() context:Load("unit.lua") end, "overwrite")
    equal(files["root/loaded/1" .. suffix], "previous")
  end
end)

test("same buffer loader adoption validates archived bytes", function()
  local context, files = setup({{Path = "loader.lua", Bytes = "return 1"}})
  files["root/loaded/1"] = "return 2"
  raises(function() context:AdoptLoader("loader.lua", "return 1") end, "buffer mismatch")
  files["root/loaded/1"] = "return 1"
  context:AdoptLoader("loader.lua", "return 1")
  equal(context.Events[4].Kind, "returned")
end)

test("capabilities, aliases and sparse manifests cannot be silently accepted", function()
  local context, _, reference = setup({{Path = "unit.lua", Bytes = "return 1"}})
  reference.Members[2] = reference.Members[1]
  raises(function() Loader.New(reference, {Root = "root"}) end, "member order")
  reference.Members[2] = nil
  reference.Members[256] = reference.Members[1]
  raises(function() Loader.New(reference, {Root = "root"}) end, "sparse")
  reference.Members[256] = nil
  raises(function() Loader.New(reference, {Root = "root", IO = false, Rename = false,
    Compile = false}) end, nil)
  equal(context.Completed, false)
end)

test("bootstrap restores file adapters after an include exception", function()
  local context, _, _, _, globals = setup({{Path = "Moose Development/Moose/Modules.lua",
    Bytes = "__Moose.Include('Scripts/Moose/missing.lua')"}})
  globals.__Moose, globals.ASTAR, globals.PATHLINE = nil, nil, nil
  -- Avoid inherited test globals masking the intended isolated namespace.
  setmetatable(globals, nil)
  globals.pcall, globals.unpack, globals.assert = pcall, unpack, assert
  local originalLoad, originalDo = function() end, function() end
  globals.loadfile, globals.dofile = originalLoad, originalDo
  raises(function() context:Bootstrap() end, "undeclared source")
  equal(globals.loadfile, originalLoad)
  equal(globals.dofile, originalDo)
  equal(context.Completed, false)
end)

test("run identity and late load evidence changes invalidate the checkpoint", function()
  local context, _, reference = setup({{Path = "unit.lua", Bytes = "return 1"}})
  context.Completed, context.Sealed = true, true
  local check = context:Checkpoint()
  check()
  reference.BuildToken = "different"
  raises(check, "run identity")
  reference.BuildToken = "token"
  check()
  context.Events[1] = {}
  raises(check, "run identity")
end)

print(string.format("%d passed, %d failed (P0-I3 loader; Lua 5.1)", passed, failed))
os.exit(failed == 0 and 0 or 1)
