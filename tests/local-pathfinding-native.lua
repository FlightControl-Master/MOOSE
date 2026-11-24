-- P0-I3 Lua 5.1 regressions: real Core methods with native-shaped dependencies.
-- Does not validate native terrain, controller execution or DCS physics.
local P0 = dofile("tests/support/local-pathfinding.lua")
local Native = dofile("tests/support/local-pathfinding-native.lua")
local Loader = dofile("tests/support/local-pathfinding-loader.lua")
local Codec = P0.Codec
local originalOS = os
local passed, failed = 0, 0
local fixture

local function equal(actual, expected)
  assert(actual == expected, "expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

local function same(first, second)
  local compared = Codec.Compare(first, second)
  assert(compared.Verdict == "passed", "difference at " .. (compared.Difference and compared.Difference.Path or "?"))
end

local function raises(callback, fragment)
  local ok, failure = pcall(callback)
  assert(not ok, "expected an error")
  if fragment then
    assert(tostring(failure):find(fragment, 1, true), tostring(failure))
  end
  return failure
end

local function test(name, callback)
  os = originalOS
  fixture = P0.Fixtures.Install()
  fixture.ActiveTerrain = P0.Fixtures.Terrain(P0.Fixtures.Definition("open_water"))
  local ok, failure = pcall(callback)
  os = originalOS
  if ok then
    passed = passed + 1
    print("PASS " .. name)
  else
    failed = failed + 1
    print("FAIL " .. name .. ": " .. tostring(failure))
  end
end

local function environment(options)
  options = options or {}
  local context = setmetatable({Globals = _G, Completed = true, Sealed = true},
    {__index = Loader.New({
      SchemaVersion = 1, RunId = "unit", BuildToken = "build", PreparedBytes = 0,
      Limits = {MaxMemberBytes = 4096, MaxSourceBytes = 8192, MaxPackageBytes = 32768},
      Members = {{Index = 1, LogicalPath = "unit.lua", PreparedPath = "prepared/unit",
        LoadedPath = "loaded/unit", Bytes = 1, SHA256 = string.rep("a", 64)}},
    }, {Root = "unused"})})
  options.Guard = options.Guard or context:Checkpoint()
  return Native.NewEnvironment(options)
end

local function case(name, start, goal)
  return Native.Case(name or "open-request", start or {x = 0, y = 0, z = 0},
    goal or {x = 500, y = 0, z = 0}, land.SurfaceType)
end

local function finish(job)
  local count = 0
  while job:Step() do
    count = count + 1
    assert(count < 30000, "job did not complete")
    equal(land, job.Environment.NativeLand)
    equal(os, originalOS)
  end
  return job.Result
end

test("native cases keep measured terrain separate from analytic definitions", function()
  local input = case()
  equal(input.Environment.ReplayCapability, "native_capture")
  equal(input.Environment.Terrain.Depth, nil)
  equal(input.Execution.Clock, "unavailable")
  equal(input.Search.Cost.Weight, 1)
  local env = environment()
  local job = Native.NewJob(env, function()
    local result, tape = P0.RecordRun(input, env)
    return {Result = result, Tape = tape}
  end)
  local captured = finish(job)
  equal(captured.Result.End.Verdict, "passed")
  equal(captured.Result.ReplayCapability, "native_capture")
  equal(captured.Result.Requests[1].Native.SearchCPUSeconds, nil)
  equal(captured.Tape.Complete, true)
  equal(env.Cleanup.Restored, true)
  equal(#env.Cleanup.Errors, 0)
  equal(fixture.ForbiddenCalls, 0)
  equal(fixture.DrawingCalls, 0)
end)

test("Lua 5.1 work yields only after restoring terrain and clock", function()
  local env = environment()
  local input = case()
  local job = Native.NewJob(env, function()
    return P0.RecordRun(input, env)
  end)
  equal(job:Step(), true)
  equal(land, env.NativeLand)
  equal(os, originalOS)
  local sentinel = originalOS.time
  local session = env.Session
  local seenClock, seenTime
  env.Yielding = false
  env:Operation("clock_probe", function()
    seenClock, seenTime = os.clock, os.time
  end)
  env.Yielding = true
  equal(seenClock, nil)
  equal(seenTime, sentinel)
  equal(session, env.Session)
  finish(job)
end)

test("native shaped search replays exact actions and never calls live terrain", function()
  local input, env = case(), environment()
  local original = finish(Native.NewJob(env, function()
    local result, tape = P0.RecordRun(input, env, "same")
    return {Result = result, Tape = tape}
  end))
  local counts = fixture.ActiveTerrain.Calls
  local before = Codec.Copy(counts)
  local checked = environment({ExpectedJournal = env.Journal})
  local replay = finish(Native.NewJob(checked, function()
    return P0.ReplayRun(input, checked, original.Tape, "same")
  end))
  equal(P0.CompareRuns(original.Result, replay).Verdict, "passed")
  same(counts, before)
  equal(checked.FirstIssue, nil)
end)

test("independent connection and depth probes reject an interior island", function()
  fixture.ActiveTerrain = P0.Fixtures.Terrain(P0.Fixtures.Definition("island"))
  local env = environment()
  local input = case("coast-probe", nil, {x = 2000, y = 0, z = 0})
  local captured = finish(Native.NewJob(env, function()
    local result, tape = Native.RecordProbe(input, env)
    return {Result = result, Tape = tape}
  end))
  equal(captured.Result.Stages.connection.Status, "blocked")
  equal(captured.Result.Stages.depth.Status, "blocked")
  equal(captured.Result.CaptureComplete, true)
  local replayEnv = environment({ExpectedJournal = env.Journal})
  local replay = finish(Native.NewJob(replayEnv, function()
    return Native.ReplayProbe(input, replayEnv, captured.Tape)
  end))
  same(Native.SemanticReport(captured.Result), Native.SemanticReport(replay))
  equal(replay.TerrainTranscript.Verdict, "passed")
end)

test("missing depth remains unavailable in both independent native probe stages", function()
  fixture.ActiveTerrain = P0.Fixtures.Terrain(P0.Fixtures.Definition("missing_data"))
  local input, env = case("shallow-probe"), environment()
  local result = finish(Native.NewJob(env, function()
    return Native.RecordProbe(input, env)
  end))
  equal(result.Stages.connection.Status, "unavailable")
  equal(result.Stages.depth.Status, "unavailable")
  equal(result.CaptureComplete, true)
end)

test("native terrain exceptions remain original errors with restored bindings", function()
  local nativeError = {}
  land.getSurfaceType = function()
    error(nativeError, 0)
  end
  local env = environment()
  local job = Native.NewJob(env, function()
    return P0.RecordRun(case(), env)
  end)
  local failure = raises(function() finish(job) end)
  equal(failure, nativeError)
  equal(job.State, "error")
  equal(land, env.NativeLand)
  equal(os, originalOS)
  equal(env.Sessions[1]:Export().Complete, false)
end)

test("loaded class method replacement stops before more terrain queries", function()
  local env = environment()
  local job = Native.NewJob(env, function()
    return P0.RecordRun(case(), env)
  end)
  job:Step()
  local before = Codec.Copy(fixture.ActiveTerrain.Calls)
  ASTAR.StepSearch = function() error("replacement should not execute") end
  raises(function() finish(job) end, "binding changed")
  same(fixture.ActiveTerrain.Calls, before)
  equal(env.Cleanup.Restored, true)
end)

test("foreign terrain ownership is rejected without overwriting it", function()
  local env = environment()
  local job = Native.NewJob(env, function()
    return P0.RecordRun(case(), env)
  end)
  job:Step()
  local foreign = {}
  land = foreign
  raises(function() finish(job) end, "binding changed")
  equal(land, foreign)
  equal(env.Cleanup.Restored, false)
end)

test("cancellation and late resume cannot start a second search", function()
  local env = environment()
  local job = Native.NewJob(env, function()
    return P0.RecordRun(case(), env)
  end)
  job:Step()
  job:Cancel("explicit")
  local before = Codec.Copy(fixture.ActiveTerrain.Calls)
  equal(job:Step(), false)
  job:Cancel("again")
  equal(job.Reason, "explicit")
  same(fixture.ActiveTerrain.Calls, before)
  equal(env.Cleanup.Restored, true)
end)

test("first action mismatch rejects replay before its native operation", function()
  local env = environment({ExpectedJournal = {{Sequence = 1, Operation = "wrong"}}})
  local job = Native.NewJob(env, function()
    return P0.RecordRun(case(), env)
  end)
  equal(raises(function() finish(job) end), env.Abort)
  equal(env.FirstIssue.Kind, "action_mismatch")
  equal(fixture.ActiveTerrain.Calls.Surface, 0)
end)

test("zone inputs use only one horizontal lookup and configured zero altitude", function()
  local seen = {}
  local points = {
    ["ASTAR Start 1"] = {x = 0, y = 0}, ["ASTAR Goal 1"] = {x = 1000, y = 0},
    ["PATHLINE Shallow Start"] = {x = 0, y = 100},
    ["PATHLINE Shallow Goal"] = {x = 1000, y = 100},
    ["PATHLINE Coast Start"] = {x = 0, y = 200},
    ["PATHLINE Coast Goal"] = {x = 1000, y = 200},
  }
  local cases = Native.ResolveCases(function(name)
    return {GetVec2 = function()
      seen[name] = (seen[name] or 0) + 1
      return points[name]
    end, GetVec3 = function() error("hidden altitude lookup") end}
  end, land.SurfaceType)
  equal(#cases, 3)
  equal(cases[1].Route.Goal.x, 500)
  equal(cases[1].Route.Start.y, 0)
  for _, count in pairs(seen) do
    equal(count, 1)
  end
  equal(fixture.ActiveTerrain.Calls.Surface, 0)
end)

test("native source claims remain unverified until independent host proof", function()
  local input = case()
  input.Environment.SourceVerification = "loaded_verified"
  raises(function() P0.ResolveCase(input) end, "no trusted source verification")
  equal(fixture.ActiveTerrain.Calls.Surface, 0)
end)

local function matrix()
  local terrain = P0.Fixtures.Definition("island")
  terrain.Regions[2] = {XMin = 600, XMax = 1400, ZMin = 750, ZMax = 1250, Depth = 5}
  fixture.ActiveTerrain = P0.Fixtures.Terrain(terrain)
  return {
    case("open-request", {x = 0, y = 0, z = -1000}, {x = 500, y = 0, z = -1000}),
    case("shallow-probe", {x = 0, y = 0, z = 1000}, {x = 2000, y = 0, z = 1000}),
    case("coast-probe", nil, {x = 2000, y = 0, z = 0}),
  }
end

test("complete native matrix replays separate search, preparation and probe consumers", function()
  local cases, env = matrix(), environment()
  local recorded = finish(Native.NewJob(env, function() return Native.RunCases(cases, env) end))
  equal(Native.Assertions(recorded).Verdict, "passed")
  equal(#env.Sessions, 4)
  local counts = Codec.Copy(fixture.ActiveTerrain.Calls)
  local replayEnv = environment({ExpectedJournal = env.Journal})
  local replay = finish(Native.NewJob(replayEnv, function()
    return Native.RunCases(cases, replayEnv, recorded)
  end))
  equal(Native.CompareResults(recorded, replay).Verdict, "passed")
  equal(Native.Assertions(replay).Verdict, "passed")
  same(fixture.ActiveTerrain.Calls, counts)
  for _, session in ipairs(replayEnv.Sessions) do equal(session:Report().Verdict, "passed") end
  equal(fixture.ForbiddenCalls, 0)
  equal(fixture.DrawingCalls, 0)
  local original = recorded[1].Search.Requests[1].Native.Candidates[1].Positions[1].x
  replay[1].Search.Requests[1].Native.Candidates[1].Positions[1].x = original + 1
  equal(recorded[1].Search.Requests[1].Native.Candidates[1].Positions[1].x, original)
  equal(Native.CompareResults(recorded, replay).Verdict, "failed")
end)

local function scheduler()
  local schedule = {Now = 0, Count = 0, Removed = 0, Capture = {}}
  function schedule.getTime() return schedule.Now end
  function schedule.scheduleFunction(callback, argument, time)
    schedule.Capture.Callback, schedule.Time, schedule.Argument = callback, time, argument
    schedule.Count = schedule.Count + 1
    return schedule.Count
  end
  function schedule.removeFunction(id) schedule.Removed = schedule.Removed + 1 end
  function schedule:Tick()
    self.Now = self.Time
    self.Time = self.Capture.Callback(self.Argument, self.Now)
    return self.Time
  end
  return schedule
end

test("one timer chain completes once and late callbacks remain inert", function()
  local env, schedule = environment(), scheduler()
  local finished = 0
  local job = Native.NewJob(env, function() return P0.RecordRun(case(), env) end)
  job:StartTimer(schedule, function() finished = finished + 1 end)
  raises(function() job:StartTimer(schedule, function() end) end, "duplicate timer")
  while schedule:Tick() do
    equal(land, env.NativeLand)
    equal(os, originalOS)
  end
  equal(schedule.Count, 1)
  equal(finished, 1)
  equal(schedule.Capture.Callback(nil, schedule.Now), nil)
  equal(finished, 1)
end)

test("explicit timer cancellation finalizes once and removes its owned timer", function()
  local env, schedule = environment(), scheduler()
  local finished = 0
  local job = Native.NewJob(env, function() return P0.RecordRun(case(), env) end)
  job:StartTimer(schedule, function() finished = finished + 1 end)
  schedule:Tick()
  job:Cancel("operator")
  equal(schedule.Removed, 1)
  equal(finished, 1)
  equal(schedule.Capture.Callback(nil, schedule.Now), nil)
  equal(finished, 1)
  equal(env.Sessions[1]:Export().Complete, false)
end)

test("timer evidence failure does not replace the original terrain exception", function()
  local nativeError = {}
  land.getSurfaceType = function() error(nativeError, 0) end
  local env, schedule = environment(), scheduler()
  local job = Native.NewJob(env, function() return P0.RecordRun(case(), env) end)
  job:StartTimer(schedule, function() error("writer failed") end)
  local failure = raises(function() while schedule:Tick() do end end)
  equal(failure, nativeError)
  assert(job.PersistenceFailure:find("writer failed", 1, true))
end)

test("CPU measurement and accelerated simulation have independent limits", function()
  local env, now, cpu = environment(), 0, 0
  local job = Native.NewJob(env, function() return P0.RecordRun(case(), env) end, {
    SimulationTime = function() return now end,
    CPUClock = function() cpu = cpu + 0.001; return cpu end,
    MaxSimulationSeconds = 10,
  })
  equal(job:Step(), true)
  equal(job.Timing.CPUSeconds, 0.001)
  now = 11
  equal(job:Step(), false)
  equal(job.Reason, "simulation_limit")
  equal(job.Timing.SimulationSeconds, 11)
  equal(job.Timing.CPUSeconds, 0.001)
  equal(env.Cleanup.Restored, true)
end)

test("invalid clock failure closes scopes instead of leaving live work", function()
  local env, calls = environment(), 0
  local job = Native.NewJob(env, function() return P0.RecordRun(case(), env) end, {
    CPUClock = function()
      calls = calls + 1
      return calls == 1 and 1 or 0
    end,
  })
  raises(function() job:Step() end, "invalid CPU clock")
  equal(job.State, "error")
  equal(env.Cleanup.Restored, true)
  equal(env.Sessions[1]:Export().Complete, false)
end)

test("unsupported native terrain access is a gap with restored ownership", function()
  local input, env = case(), environment()
  local session = P0.Transcript.NewCapture({InputIdentity = Codec.Encode({Case = input}),
    LuaVersion = _VERSION, SourceVerification = "unverified", SourceManifest = {}},
    input.Execution.Transcript)
  env:RegisterSession(session)
  local job = Native.NewJob(env, function()
    return env:WithSession(input, session, function()
      env:Operation("unsupported", function() return land.getHeight({x = 0, y = 0}) end)
    end)
  end)
  raises(function() finish(job) end)
  equal(session:Report().Verdict, "inconclusive")
  equal(env.Cleanup.Restored, true)
end)

test("zero-based sparse profile returns preserve trailing nil through native scopes", function()
  land.profile = function()
    return {[0] = {x = 0, y = -30, z = 0}, [3] = {x = 100, y = -5, z = 0}}, false, nil
  end
  local input, env = case(), environment()
  local manifest = {InputIdentity = Codec.Encode({Case = input}), LuaVersion = _VERSION,
    SourceVerification = "unverified", SourceManifest = {}}
  local session = P0.Transcript.NewCapture(manifest, input.Execution.Transcript)
  env:RegisterSession(session)
  -- Resolve the native function inside the scope rather than capturing it outside.
  local function execute(environment, current)
    return environment:WithSession(input, current, function()
      return Codec.Pack(environment:Operation("profile_probe", function(first, last)
        return land.profile(first, last)
      end, {x = 0, y = 0, z = 0}, {x = 100, y = 0, z = 0}))
    end)
  end
  local result = finish(Native.NewJob(env, function() return execute(env, session) end))
  equal(result.Arity, 3)
  equal(result.Values[2], false)
  equal(result.Values[3], nil)
  equal(result.Values[1][0].y, -30)
  equal(result.Values[1][1], nil)
  local tape = session:Export()
  land.profile = function() error("native replay fallback") end
  local replayEnv = environment({ExpectedJournal = env.Journal})
  local replaySession = P0.Transcript.NewReplay(manifest, tape, input.Execution.Transcript)
  replayEnv:RegisterSession(replaySession)
  local replay = finish(Native.NewJob(replayEnv, function() return execute(replayEnv, replaySession) end))
  same(result, replay)
  equal(replaySession:Report().Verdict, "passed")
end)

test("call cap produces incomplete capture without another native request", function()
  local input = case()
  input.Execution.Transcript.MaxCallsPerStage = 0
  local env = environment()
  local job = Native.NewJob(env, function() return P0.RecordRun(input, env) end)
  local ok = pcall(function() finish(job) end)
  equal(fixture.ActiveTerrain.Calls.Surface, 0)
  equal(env.Sessions[1]:Export().Complete, false)
  equal(env.Sessions[1]:Report().FirstIssue.Kind, "capture_limit")
  equal(land, env.NativeLand)
end)

test("unused action tail prevents complete replay", function()
  local input, env = case(), environment()
  local original = finish(Native.NewJob(env, function()
    local result, tape = P0.RecordRun(input, env)
    return {Result = result, Tape = tape}
  end))
  local journal = Codec.Copy(env.Journal)
  journal[#journal + 1] = {Sequence = #journal + 1, Operation = "never"}
  local replayEnv = environment({ExpectedJournal = journal})
  local job = Native.NewJob(replayEnv, function() return P0.ReplayRun(input, replayEnv, original.Tape) end)
  finish(job)
  equal(job.State, "error")
  equal(replayEnv.FirstIssue.Kind, "unconsumed_action")
end)

test("isolated DCS runner writes completion last after restored callbacks", function()
  local cases = matrix()
  local schedule = scheduler()
  timer = schedule
  local positions = {
    ["ASTAR Start 1"] = {x = 0, y = -1000}, ["ASTAR Goal 1"] = {x = 2000, y = -1000},
    ["PATHLINE Shallow Start"] = {x = 0, y = 1000}, ["PATHLINE Shallow Goal"] = {x = 2000, y = 1000},
    ["PATHLINE Coast Start"] = {x = 0, y = 0}, ["PATHLINE Coast Goal"] = {x = 2000, y = 0},
  }
  ZONE = {FindByName = function(_, name) return {GetVec2 = function() return positions[name] end} end}
  local logs, files, order = {}, {}, {}
  env = {mission = {theatre = "PersianGulf"}, info = function(message)
    equal(os, originalOS)
    logs[#logs + 1] = message
  end}
  local reference = {SchemaVersion = 1, RunId = "test", BuildToken = "test-token", TestedSources = {},
    Members = {{Index = 1, LogicalPath = "unit", PreparedPath = "prepared/1", LoadedPath = "loaded/1",
      Bytes = 1, SHA256 = string.rep("a", 64)}},
    Limits = {MaxMemberBytes = 4096, MaxSourceBytes = 8192, MaxPackageBytes = 32768}}
  local context = Loader.New(reference, {Root = "unused"})
  context.Completed, context.Sealed = true, true
  function context:Write(path, bytes)
    equal(land, fixture.FixtureLand)
    assert(not files[path], "overwrite")
    order[#order + 1], files[path] = path, bytes
    return {Path = path, Bytes = #bytes}
  end
  local runner = assert(loadfile("tests/support/local-pathfinding-dcs.lua"))(function(path) return dofile(path) end)
  local job = runner.Start(context)
  while schedule:Tick() do end
  equal(job.State, "complete")
  equal(order[#order], "completion.json")
  local completion = Codec.Decode(files["completion.json"])
  equal(completion.Complete, true)
  equal(completion.SourceVerification, "pending_host_verification")
  equal(Codec.Decode(files["results.json"]).Assertions.Verdict, "passed")
  equal(#logs, 6)
  equal(fixture.DrawingCalls, 0)
  equal(fixture.ForbiddenCalls, 0)
end)

test("simulation clock reversal is an error and cancels owned work", function()
  local now, environment = 10, environment()
  local job = Native.NewJob(environment, function() return P0.RecordRun(case(), environment) end,
    {SimulationTime = function() return now end})
  job:Step()
  now = 9
  raises(function() job:Step() end, "invalid simulation clock")
  equal(job.State, "error")
  equal(environment.Cleanup.Restored, true)
end)

test("an obsolete job cannot act after replacement of its owner", function()
  local env = environment()
  local job = Native.NewJob(env, function() return P0.RecordRun(case(), env) end)
  job:Step()
  local before = Codec.Copy(fixture.ActiveTerrain.Calls)
  env.Job = {}
  raises(function() job:Step() end, "obsolete job")
  same(fixture.ActiveTerrain.Calls, before)
  equal(env.Cleanup.Restored, true)
end)

test("batch capture stops after a call cap instead of admitting later cases", function()
  local cases, env = matrix(), environment()
  cases[1].Execution.Transcript.MaxCallsPerStage = 0
  local completed = 0
  env.OnCase = function() completed = completed + 1 end
  local job = Native.NewJob(env, function() return Native.RunCases(cases, env) end)
  pcall(function() finish(job) end)
  assert(completed <= 1)
  equal(#env.Sessions, 1)
  equal(fixture.ActiveTerrain.Calls.Surface, 0)
  equal(env.Sessions[1]:Report().FirstIssue.Kind, "capture_limit")
end)

test("surface enum replacement cannot silently alter frozen native inputs", function()
  local env = environment()
  local job = Native.NewJob(env, function() return P0.RecordRun(case(), env) end)
  job:Step()
  land.SurfaceType.WATER = 4
  raises(function() job:Step() end, "enum ownership")
  equal(job.State, "error")
  equal(env.Sessions[1]:Export().Complete, false)
  equal(land, env.NativeLand)
end)

test("secondary CPU failure does not replace an original native exception", function()
  local original, invalid = {}, false
  land.getSurfaceType = function()
    invalid = true
    error(original, 0)
  end
  local env = environment()
  local job = Native.NewJob(env, function() return P0.RecordRun(case(), env) end, {
    CPUClock = function() return invalid and 0 or 1 end,
  })
  equal(raises(function() finish(job) end), original)
  assert(job.MeasurementFailure:find("invalid CPU clock", 1, true))
  equal(env.Cleanup.Restored, true)
end)

print(string.format("%d passed, %d failed (P0-I3; Lua 5.1)", passed, failed))
os.exit(failed == 0 and 0 or 1)
