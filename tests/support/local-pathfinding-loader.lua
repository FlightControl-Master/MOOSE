-- P0-I3 test-only byte-preserving loader. No production include is changed.
-- All paths and limits come from an independently prepared host manifest.
local Loader = {}
local Context = {}
Context.__index = Context

local function relative(path)
  assert(type(path) == "string" and #path > 0 and #path <= 1024
    and not path:find("\\", 1, true) and not path:find(":", 1, true)
    and path:sub(1, 1) ~= "/", "P0 loader: invalid member path")
  for part in path:gmatch("[^/]+") do
    assert(part ~= "." and part ~= "..", "P0 loader: path traversal")
  end
  assert(not path:find("//", 1, true) and path:sub(-1) ~= "/", "P0 loader: invalid member path")
  return path
end

local function integer(value, maximum)
  assert(type(value) == "number" and value >= 0 and value <= maximum
    and value == math.floor(value), "P0 loader: invalid size")
  return value
end

local function checkedClose(file)
  local closed, reason = file:close()
  assert(closed, "P0 loader: close failed: " .. tostring(reason))
end

-- Files are closed even after a failed read/write. The original failure wins.
local function withFile(context, path, mode, callback)
  local file, reason = context.IO.open(path, mode)
  assert(file, "P0 loader: open failed: " .. tostring(reason))
  local ok, value = pcall(callback, file)
  local closed, closeReason = pcall(checkedClose, file)
  if not ok then
    error(value, 0)
  end
  if not closed then
    error(closeReason, 0)
  end
  return value
end

function Loader.CheckSource(bytes)
  assert(type(bytes) == "string", "P0 loader: expected source bytes")
  assert(bytes:sub(1, 3) ~= "\239\187\191" and bytes:sub(1, 2) ~= "#!",
    "P0 loader: BOM/shebang source is unsupported")
  assert(bytes:sub(1, 1) ~= "\27", "P0 loader: binary chunks are unsupported")
end

-- Options are owned test capabilities, not serializable mission inputs.
function Loader.New(reference, options)
  options = options or {}
  local capabilityIO = options.IO
  if capabilityIO == nil then
    capabilityIO = io
  end
  local capabilityRename = options.Rename
  if capabilityRename == nil then
    capabilityRename = os and os.rename
  end
  local capabilityCompile = options.Compile
  if capabilityCompile == nil then
    capabilityCompile = loadstring
  end
  assert(reference.SchemaVersion == 1 and type(reference.RunId) == "string"
    and type(reference.BuildToken) == "string", "P0 loader: invalid reference")
  assert(type(reference.Members) == "table" and #reference.Members > 0
    and #reference.Members <= 256, "P0 loader: invalid member count")
  local memberCount = 0
  for key in pairs(reference.Members) do
    integer(key, 256)
    assert(key >= 1, "P0 loader: invalid member index")
    memberCount = memberCount + 1
  end
  assert(memberCount == #reference.Members, "P0 loader: sparse members")
  local self = setmetatable({
    Reference = reference, Root = assert(options.Root), IO = capabilityIO,
    Compile = capabilityCompile, Globals = options.Globals or _G,
    Rename = capabilityRename,
    Events = {}, Results = {}, Loaded = {}, Loading = {}, Members = {},
    BytesWritten = reference.PreparedBytes or 0, SourceBytes = 0,
    Limits = reference.Limits, Completed = false, Sealed = false,
  }, Context)
  assert(type(self.IO) == "table" and type(self.IO.open) == "function" and type(self.Rename) == "function"
    and type(self.Compile) == "function", "P0 loader: missing file/compiler capability")
  integer(self.Limits.MaxMemberBytes, 4 * 1024 * 1024)
  integer(self.Limits.MaxSourceBytes, 32 * 1024 * 1024)
  integer(self.Limits.MaxPackageBytes, 64 * 1024 * 1024)
  integer(self.BytesWritten, self.Limits.MaxPackageBytes)
  assert(self.Limits.MaxMemberBytes > 0 and self.Limits.MaxSourceBytes > 0
    and self.Limits.MaxPackageBytes > self.BytesWritten, "P0 loader: invalid limits")
  local ownedPaths = {}
  for index, member in ipairs(reference.Members) do
    assert(member.Index == index, "P0 loader: member order mismatch")
    relative(member.LogicalPath)
    relative(member.PreparedPath)
    relative(member.LoadedPath)
    assert(member.PreparedPath ~= member.LoadedPath and not self.Members[member.LogicalPath]
      and not ownedPaths[member.PreparedPath] and not ownedPaths[member.LoadedPath],
      "P0 loader: duplicate member")
    ownedPaths[member.PreparedPath], ownedPaths[member.LoadedPath] = true, true
    integer(member.Bytes, self.Limits.MaxMemberBytes)
    assert(type(member.SHA256) == "string" and member.SHA256:match("^%x+$")
      and #member.SHA256 == 64, "P0 loader: invalid digest")
    self.Members[member.LogicalPath] = member
  end
  return self
end

function Context:Read(path, maximum)
  relative(path)
  integer(maximum, 64 * 1024 * 1024)
  return withFile(self, self.Root .. "/" .. path, "rb", function(file)
    local bytes, reason = file:read(maximum + 1)
    assert(bytes ~= nil or reason == nil, "P0 loader: read failed: " .. tostring(reason))
    if bytes == nil then
      bytes = ""
    end
    assert(type(bytes) == "string" and #bytes <= maximum, "P0 loader: read limit")
    return bytes
  end)
end

-- No member is overwritten. A close or rename failure cannot publish completion.
function Context:Write(path, bytes, maximum)
  relative(path)
  integer(maximum, 64 * 1024 * 1024)
  assert(type(bytes) == "string" and #bytes <= maximum, "P0 loader: write limit")
  assert(self.BytesWritten + #bytes <= self.Limits.MaxPackageBytes, "P0 loader: package limit")
  for _, suffix in ipairs({"", ".partial"}) do
    local existing = self.IO.open(self.Root .. "/" .. path .. suffix, "rb")
    if existing then
      checkedClose(existing)
      error("P0 loader: refusing to overwrite member " .. path)
    end
  end
  self.BytesWritten = self.BytesWritten + #bytes
  withFile(self, self.Root .. "/" .. path .. ".partial", "wb", function(file)
    local written, reason = file:write(bytes)
    assert(written, "P0 loader: write failed: " .. tostring(reason))
  end)
  local renamed, reason = self.Rename(self.Root .. "/" .. path .. ".partial",
    self.Root .. "/" .. path)
  assert(renamed, "P0 loader: rename failed: " .. tostring(reason))
  return {Path = path, Bytes = #bytes}
end

function Context:Event(kind, member)
  assert(#self.Events < 2048, "P0 loader: event limit")
  self.Events[#self.Events + 1] = {
    Sequence = #self.Events + 1, Kind = kind, LogicalPath = member.LogicalPath,
    Index = member.Index, Bytes = member.Bytes,
  }
end

function Context:Archive(member, bytes)
  Loader.CheckSource(bytes)
  assert(#bytes == member.Bytes, "P0 loader: source length mismatch")
  assert(self.SourceBytes + #bytes <= self.Limits.MaxSourceBytes, "P0 loader: source limit")
  self:Write(member.LoadedPath, bytes, self.Limits.MaxMemberBytes)
  self.SourceBytes = self.SourceBytes + #bytes
  self:Event("archived", member)
end

-- The inspected bootstrap archives this exact buffer before compiling it.
function Context:AdoptLoader(path, bytes)
  local member = assert(self.Members[path], "P0 loader: undeclared bootstrap loader")
  assert(not self.Loaded[path], "P0 loader: duplicate bootstrap loader")
  Loader.CheckSource(bytes)
  assert(#bytes == member.Bytes and self:Read(member.LoadedPath, self.Limits.MaxMemberBytes) == bytes,
    "P0 loader: bootstrap buffer mismatch")
  self.BytesWritten = self.BytesWritten + #bytes
  self.SourceBytes = self.SourceBytes + #bytes
  assert(self.SourceBytes <= self.Limits.MaxSourceBytes
    and self.BytesWritten <= self.Limits.MaxPackageBytes, "P0 loader: bootstrap limit")
  self:Event("archived", member)
  self:Event("compiled", member)
  self:Event("entered", member)
  self:Event("returned", member)
  self.Loaded[path] = true
  self.Results[path] = {Arity = 1, Values = {Loader}}
end

function Context:Load(path)
  relative(path)
  assert(not self.Sealed, "P0 loader: load after checkpoint")
  local member = assert(self.Members[path], "P0 loader: undeclared source " .. path)
  if self.Loaded[path] then
    self:Event("deduplicated", member)
    local result = self.Results[path]
    return unpack(result.Values, 1, result.Arity)
  end
  assert(not self.Sealed and not self.Loading[path], "P0 loader: unexpected reload/cyclic import")
  self.Loading[path] = true
  local bytes = self:Read(member.PreparedPath, self.Limits.MaxMemberBytes)
  self:Archive(member, bytes)
  local chunk, reason = self.Compile(bytes, "@" .. path)
  assert(chunk, reason)
  setfenv(chunk, self.Globals)
  self:Event("compiled", member)
  self:Event("entered", member)
  local function pack(...)
    return {Arity = select("#", ...), Values = {...}}
  end
  local result
  if path:sub(1, 14) == "tests/support/" then
    result = pack(chunk(function(dependency)
      return self:Load(dependency)
    end))
  else
    result = pack(chunk())
  end
  self:Event("returned", member)
  self.Loading[path], self.Loaded[path], self.Results[path] = nil, true, result
  return unpack(result.Values, 1, result.Arity)
end

function Context:ResolveInclude(path)
  local logical = path:gsub("\\", "/"):match("/Moose/(.+)$")
  assert(logical, "P0 loader: unexpected include path")
  return "Moose Development/Moose/" .. logical
end

-- Bootstrap file adapters are temporary and never span a timer/coroutine yield.
function Context:Bootstrap()
  local globals = self.Globals
  assert(globals.__Moose == nil and globals.ASTAR == nil and globals.PATHLINE == nil,
    "P0 loader: MOOSE already loaded; restart with the isolated entry")
  local originalLoad, originalDo = globals.loadfile, globals.dofile
  local selfInclude = function(path)
    return self:Load(self:ResolveInclude(path))
  end
  local fileAdapter = function(path)
    local mapped = self.Reference.ExternalPaths[path:gsub("\\", "/")]
    assert(mapped, "P0 loader: undeclared nested load")
    return function()
      return self:Load(mapped)
    end
  end
  local doAdapter = function(path)
    return fileAdapter(path)()
  end
  globals.__Moose = {Include = selfInclude, Includes = {}}
  globals.MOOSE_DEVELOPMENT_FOLDER = "Scripts"
  globals.loadfile, globals.dofile = fileAdapter, doAdapter
  local ok, result = pcall(function()
    self:Load("Moose Development/Moose/Modules.lua")
    local P0 = self:Load("tests/support/local-pathfinding.lua")
    local Native = self:Load("tests/support/local-pathfinding-native.lua")
    local Runner = self:Load("tests/support/local-pathfinding-dcs.lua")
    self.Completed = true
    return {P0 = P0, Native = Native, Runner = Runner}
  end)
  local ownership = globals.loadfile == fileAdapter and globals.dofile == doAdapter
  if globals.loadfile == fileAdapter then
    globals.loadfile = originalLoad
  end
  if globals.dofile == doAdapter then
    globals.dofile = originalDo
  end
  if not ok then
    error(result, 0)
  end
  assert(ownership, "P0 loader: bootstrap file ownership changed")
  assert(globals.__Moose.Include == selfInclude, "P0 loader: include ownership changed")
  self.Sealed = true
  return result
end

-- Function/table identity is local runtime evidence, never serialized as a hash.
function Context:Checkpoint()
  assert(self.Completed and self.Sealed, "P0 loader: incomplete bootstrap")
  local reference, eventCount = self.Reference, #self.Events
  local runId, buildToken = reference.RunId, reference.BuildToken
  local bindings = {}
  local names = {"BASE", "UTILS", "COORDINATE", "ASTAR", "GRID", "VECTOR",
    "PATHLINE", "ZONE", "ZONE_BASE", "ZONE_RADIUS", "__Moose", "land", "timer", "os"}
  for _, name in ipairs(names) do
    local object = self.Globals[name]
    bindings[name] = {Object = object, Functions = {}, Keys = {}}
    if type(object) == "table" then
      for key, value in pairs(object) do
        if type(value) == "function" then
          bindings[name].Functions[key] = value
          bindings[name].Keys[#bindings[name].Keys + 1] = key
        end
      end
    end
    table.sort(bindings[name].Keys, function(first, second)
      return tostring(first) < tostring(second)
    end)
  end
  self.Bindings = bindings
  return function()
    assert(self.Completed and self.Sealed and self.Reference == reference
      and reference.RunId == runId and reference.BuildToken == buildToken and #self.Events == eventCount,
      "P0 loader: checkpoint/run identity changed")
    for _, name in ipairs(names) do
      local binding = bindings[name]
      local current = self.Globals[name]
      assert(current == binding.Object, "P0 loader: binding changed: " .. name)
      if type(current) == "table" then
        for _, key in ipairs(binding.Keys) do
          local value = binding.Functions[key]
          assert(current[key] == value, "P0 loader: binding changed: " .. name .. "." .. tostring(key))
        end
        local currentKeys = {}
        for key, value in pairs(current) do
          if type(value) == "function" then
            currentKeys[#currentKeys + 1] = key
          end
        end
        table.sort(currentKeys, function(first, second)
          return tostring(first) < tostring(second)
        end)
        for _, key in ipairs(currentKeys) do
          assert(binding.Functions[key] == current[key],
            "P0 loader: new function binding: " .. name .. "." .. tostring(key))
        end
      end
    end
  end
end

Loader.RelativePath = relative
return Loader
