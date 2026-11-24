-- Host-admitted P0-I3 replay. The host copies independently verified buffers.
-- No source or result comes from the current checkout; live terrain is forbidden.
local root = assert(arg[1], "P0 replay: admission directory required")
local function read(path)
  assert(not path:find("..", 1, true) and not path:find(":", 1, true)
    and path:sub(1, 1) ~= "/", "P0 replay: invalid path")
  local file = assert(io.open(root .. "/" .. path, "rb"))
  local bytes = assert(file:read(8 * 1024 * 1024 + 1))
  assert(file:close())
  assert(#bytes <= 8 * 1024 * 1024, "P0 replay: read limit")
  return bytes
end
local referenceBytes = read("reference.json")
-- Only the codec bootstrap uses a manifest path before JSON is available.
local codecPath = assert(referenceBytes:match('"LoadedPath":"([^"]+)","LogicalPath":"tests/support/local%-pathfinding%-codec.lua"'),
  "P0 replay: missing canonical codec member")
local codecBytes = read(codecPath)
local Codec = assert(loadstring(codecBytes, "@archived-codec"))()
local reference = Codec.Decode(referenceBytes)
assert(reference.SchemaVersion == 1 and _VERSION == "Lua 5.1", "P0 replay: incompatible runtime")
local members, loaded = {}, {}
for _, member in ipairs(reference.Members) do
  members[member.LogicalPath] = member
end
local function source(path)
  local member = assert(members[path], "P0 replay: undeclared source")
  local bytes = read(member.LoadedPath)
  assert(#bytes == member.Bytes, "P0 replay: source size mismatch")
  return assert(loadstring(bytes, "@" .. path))
end
local import
import = function(path)
  if loaded[path] then
    return loaded[path]
  end
  local result = source(path)(import)
  loaded[path] = result
  return result
end
loaded["tests/support/local-pathfinding-codec.lua"] = Codec
local P0 = import("tests/support/local-pathfinding.lua")
local Native = import("tests/support/local-pathfinding-native.lua")
local Loader = import("tests/support/local-pathfinding-loader.lua")
local inputs = Codec.Decode(read("inputs.json"))
local expected = Codec.Decode(read("results.json")).Cases
local actions = Codec.Decode(read("actions.json")).Actions
for _, case in ipairs(inputs.Cases) do
  P0.ResolveCase(case)
end
-- Validate transport data before any archived production chunk is executed.
for _, item in ipairs(expected) do
  for _, key in ipairs({"SearchTape", "PreparationTape", "ProbeTape"}) do
    if item[key] then
      local bytes = read(item[key].Path)
      local tape, issue = P0.Transcript.Decode(bytes)
      assert(tape, issue and issue.Kind)
      item[key] = tape
    end
  end
end
local fixture = P0.Fixtures.Install(function(path) return source(path)() end)
-- Declared enum substitutions agree with the frozen native inputs.
land.SurfaceType.WATER = inputs.Cases[1].Environment.SurfaceTypes.WATER
land.SurfaceType.SHALLOW_WATER = inputs.Cases[1].Environment.SurfaceTypes.SHALLOW_WATER
land.getSurfaceType = function() error("P0 replay: live surface fallback") end
land.getSurfaceHeightWithSeabed = function() error("P0 replay: live depth fallback") end
land.profile = function() error("P0 replay: live profile fallback") end
local context = Loader.New(reference, {Root = root})
context.Completed, context.Sealed = true, true
local environment = Native.NewEnvironment({Guard = context:Checkpoint(), ExpectedJournal = actions})
local job = Native.NewJob(environment, function()
  return Native.RunCases(inputs.Cases, environment, expected)
end)
local ok, failure = pcall(function()
  while job:Step() do end
end)
local report = {SchemaVersion = 1, RunId = reference.RunId, BuildToken = reference.BuildToken,
  Verdict = "inconclusive", SourceVerification = "host_admitted_buffers",
  NativePhysicsValidated = false, QueryChecks = {}, Cleanup = environment.Cleanup,
  FirstIssue = environment.FirstIssue}
if ok and job.State == "complete" then
  report.Semantic = Native.CompareResults(expected, job.Result)
  report.Assertions = Native.Assertions(job.Result)
  local queries = true
  for index, session in ipairs(environment.Sessions) do
    report.QueryChecks[index] = session:Report()
    queries = queries and report.QueryChecks[index].Verdict == "passed"
  end
  report.Verdict = queries and report.Semantic.Verdict == "passed"
    and report.Assertions.Verdict == "passed" and fixture.ForbiddenCalls == 0
    and fixture.DrawingCalls == 0 and "passed" or "failed"
else
  report.Reason = Native.BoundedText(failure or job.Reason or job.State)
  for _, session in ipairs(environment.Sessions) do
    local issue = session:Report().FirstIssue
    report.FirstIssue = report.FirstIssue or issue
  end
  if report.FirstIssue then
    report.Verdict = report.FirstIssue.Verdict
  end
end
local output = assert(io.open(root .. "/replay-result.json", "wb"))
assert(output:write(Codec.Encode(report, {MaxBytes = 4 * 1024 * 1024})))
assert(output:close())
os.exit(report.Verdict == "passed" and 0 or 1)
