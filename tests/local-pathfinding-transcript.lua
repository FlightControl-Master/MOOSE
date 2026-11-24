-- P0-I2 exact terrain record/replay regressions. Run from the repository root
-- in a separate Lua 5.1 process. Uses actual Core methods in isolated fixtures;
-- does not test DCS terrain, loaded-byte verification, physics or controllers.
local P0 = dofile("tests/support/local-pathfinding.lua")
local Codec, Fixtures, Transcript = P0.Codec, P0.Fixtures, P0.Transcript
local environment = Fixtures.Install()
local savedOS, savedLand, terrainFactory = os, land, Fixtures.Terrain
local passed, failed = 0, 0

local function equal(actual, expected)
  assert(actual == expected, "expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

local function same(first, second)
  local result = Codec.Compare(first, second)
  assert(result.Verdict == "passed", "difference at " .. (result.Difference and result.Difference.Path or "?"))
end

local function test(name, callback)
  local ok, failure = pcall(callback)
  os, land, Fixtures.Terrain = savedOS, savedLand, terrainFactory
  environment.ActiveTerrain = nil
  if ok then
    passed = passed + 1
    print("PASS " .. name)
  else
    failed = failed + 1
    print("FAIL " .. name .. ": " .. tostring(failure))
  end
end

local function raises(callback, fragment)
  local ok, failure = pcall(callback)
  assert(not ok, "expected an error")
  if fragment then
    assert(tostring(failure):find(fragment, 1, true), tostring(failure))
  end
  return failure
end

local function abort(session, callback, kind, verdict)
  local failure = raises(callback)
  assert(session:IsAbort(failure), "expected the owned abort signal")
  local report = session:Report()
  equal(report.FirstIssue.Kind, kind)
  equal(report.FirstIssue.Verdict, verdict or "inconclusive")
  return report.FirstIssue
end

local function manifest(identity)
  return {InputIdentity = identity or "unit", LuaVersion = _VERSION,
    SourceVerification = "unverified", SourceManifest = {}}
end

local function capture(limits)
  local session = Transcript.NewCapture(manifest(), limits)
  session:Begin("search", "unit", 1, 0)
  return session
end

local function capturedOne(name, callback, ...)
  local session = capture()
  session:Call(name, callback, ...)
  equal(session:Finish(true).Verdict, "passed")
  return session:Export()
end

local function replay(data, limits)
  local session = Transcript.NewReplay(manifest(), data, limits)
  session:Begin("search", "unit", 1, 0)
  return session
end

local function compact(kind, distance, experiment)
  local case = Fixtures.Case(kind or "open_water", experiment)
  case.VariantId = "compact-exact-transcript"
  case.Search.Grid.Type, case.Search.Grid.Spacing = "rectangular", 100
  case.Search.Grid.MaxCells = 500
  case.Search.Window = {Ahead = 400, Width = 400, Behind = 100}
  case.Route.Goal.x = distance or 200
  if case.Actions[2] then
    case.Actions[2].Goal = Codec.Copy(case.Route.Goal)
  end
  return case
end

local function forbidLive()
  local queries = 0
  Fixtures.Terrain = function(definition)
    local provider = terrainFactory(definition)
    local function forbidden()
      queries = queries + 1
      error("live terrain accessed during strict replay")
    end
    provider.Surface, provider.Depth, provider.Profile = forbidden, forbidden, forbidden
    return provider
  end
  return function() equal(queries, 0) end
end

test("exact Vec2 Vec3 binary64 inputs and nil false zero return arity survive JSON", function()
  local first, last = {x = 0.10000000000000002, y = 7, z = 1e-200}, {x = 1e200, y = -9, z = 11}
  local captureSession = capture()
  local returns = Codec.Pack(captureSession:Call("land.getSurfaceHeightWithSeabed",
    function(...) same(Codec.Pack(...), Codec.Pack(first, last, nil, false, 0, nil)); return 0, nil, false, 0, nil end,
    first, last, nil, false, 0, nil))
  equal(returns.Arity, 5)
  equal(returns.Values[1], 0)
  equal(returns.Values[3], false)
  captureSession:Finish(true)
  local data = assert(Transcript.Decode(Transcript.Encode(captureSession:Export())))
  local session = replay(data)
  local replayed = Codec.Pack(session:Call("land.getSurfaceHeightWithSeabed",
    function() error("must not call live") end, first, last, nil, false, 0, nil))
  same(replayed, returns)
  equal(session:Finish(true).Verdict, "passed")
  equal(session:Counts().Depth, 1)
end)

test("zero return values and one returned nil remain different", function()
  for _, callback in ipairs({function() end, function() return nil end}) do
    local data = capturedOne("land.getSurfaceType", callback, {x = 1, y = 2})
    local expected = data.Tapes[1].Calls[1].Returns.Arity
    local session = replay(data)
    equal(select("#", session:Call("land.getSurfaceType", nil, {x = 1, y = 2})), expected)
    session:Finish(true)
  end
end)

test("zero-indexed sparse malformed profiles duplicate points and mixed keys stay exact", function()
  local point = {x = 3, y = -4, z = 5}
  local profile = {[0] = point, [2] = Codec.Copy(point), [4] = false,
    ["2"] = {x = 0 / 0, y = math.huge, z = -math.huge}, [true] = "bad-record"}
  local data = capturedOne("land.profile", function() return profile, nil end,
    {x = 0, y = 0, z = 0}, {x = 10, y = 0, z = 0})
  profile[0].y = 99
  local decoded = assert(Transcript.Decode(Transcript.Encode(data)))
  same(decoded, data)
  local session = replay(decoded)
  local returns = Codec.Pack(session:Call("land.profile", nil,
    {x = 0, y = 0, z = 0}, {x = 10, y = 0, z = 0}))
  equal(returns.Arity, 2)
  same(returns, data.Tapes[1].Calls[1].Returns)
  equal(returns.Values[1][1], nil)
  equal(returns.Values[1][0].y, -4)
  equal(session:Finish(true).StageCounts.search.ProfileRecords, 5)
end)

test("capturing detaches arguments before native mutation and responses before consumer mutation", function()
  local input = {x = 0, y = 1}
  local session = capture()
  local returned = session:Call("land.getSurfaceType", function(position)
    position.y = 2
    return position
  end, input)
  returned.y = 3
  session:Finish(true)
  local data = session:Export()
  equal(data.Tapes[1].Calls[1].Arguments.Values[1].y, 1)
  equal(data.Tapes[1].Calls[1].Returns.Values[1].y, 2)
  local replaySession = replay(data)
  replaySession:Call("land.getSurfaceType", nil, {x = 0, y = 1}).y = 8
  replaySession:Finish(true)
  equal(data.Tapes[1].Calls[1].Returns.Values[1].y, 2)
  replaySession:Export().Tapes[1].Calls[1].Returns.Values[1].y = 9
  equal(data.Tapes[1].Calls[1].Returns.Values[1].y, 2)
end)

test("negative zero is preserved and is an exact argument mismatch against positive zero", function()
  local negative = -1 / math.huge
  equal(1 / Codec.Copy(negative), -math.huge)
  equal(Codec.Compare(negative, 0).Verdict, "failed")
  local data = capturedOne("land.getSurfaceType", function() return negative end, {x = negative, y = 0})
  local session = replay(data)
  local issue = abort(session, function()
    session:Call("land.getSurfaceType", nil, {x = 0, y = 0})
  end, "arguments_mismatch", "failed")
  equal(issue.Difference.Path, "$.Values[1].x")
  equal(1 / issue.Difference.Expected.Value, -math.huge)
end)

test("first argument mismatch reports tape sequence path and exact unrounded coordinate", function()
  local data = capturedOne("land.getSurfaceType", function() return 3 end, {x = 1, y = 2})
  local session = replay(data)
  local calls = 0
  local issue = abort(session, function()
    session:Call("land.getSurfaceType", function() calls = calls + 1 end, {x = 1 + 1e-12, y = 2})
  end, "arguments_mismatch", "failed")
  equal(issue.TapeIndex, 1)
  equal(issue.Sequence, 1)
  equal(issue.Scope.Stage, "search")
  equal(issue.Difference.Path, "$.Values[1].x")
  equal(issue.Difference.Expected.Value, 1)
  equal(issue.Difference.Actual.Value, 1 + 1e-12)
  local first = Codec.Copy(issue)
  abort(session, function() session:Call("land.profile", nil) end, "arguments_mismatch", "failed")
  same(session:Finish(true).FirstIssue, first)
  equal(calls, 0)
end)

test("bounded mismatch excerpts preserve UTF8 and distinguish table versus nil without dumping profiles", function()
  local value = string.rep("a", 127) .. "\195\164" .. string.rep("b", 100)
  local data = capturedOne("land.getSurfaceType", function() return 3 end, value)
  local session = replay(data)
  local issue = abort(session, function()
    session:Call("land.getSurfaceType", nil, value .. "changed")
  end, "arguments_mismatch", "failed")
  equal(issue.Difference.Expected.Value, string.rep("a", 127))
  equal(issue.Difference.Expected.Bytes, #value)
  equal(issue.Difference.Expected.Truncated, true)
  session:Finish(false)
  assert(Transcript.Decode(Transcript.Encode(session:Export())))
  data = capturedOne("land.profile", function() return {} end, {many = {points = true}})
  session = replay(data)
  issue = abort(session, function() session:Call("land.profile", nil, nil) end, "arguments_mismatch", "failed")
  equal(issue.Difference.Expected.Type, "table")
  equal(issue.Difference.Actual.Type, "nil")
  equal(issue.Difference.Expected.Value, nil)
end)

test("argument arity and field presence are compared before any replay response", function()
  local data = capturedOne("land.getSurfaceType", function() return 3 end, {x = 0, y = 0}, nil)
  local session = replay(data)
  equal(abort(session, function()
    session:Call("land.getSurfaceType", nil, {x = 0, y = 0})
  end, "arguments_mismatch", "failed").Difference.Path, "$.Arity")
  session:Finish(false)
  session = replay(data)
  equal(abort(session, function()
    session:Call("land.getSurfaceType", nil, {x = 0, y = 0, z = 0}, nil)
  end, "arguments_mismatch", "failed").Difference.Path, "$.Values[1].z")
end)

test("function order mismatches without nearby or live fallback", function()
  local data = capturedOne("land.getSurfaceType", function() return 3 end, {x = 0, y = 0})
  local session = replay(data)
  local issue = abort(session, function()
    session:Call("land.getSurfaceHeightWithSeabed", nil, {x = 0, y = 0})
  end, "function_mismatch", "failed")
  equal(issue.ExpectedFunction, "land.getSurfaceType")
  equal(issue.ActualFunction, "land.getSurfaceHeightWithSeabed")
end)

test("extra query is a missing-call gap and unused recorded query fails at scope close", function()
  local data = capturedOne("land.getSurfaceType", function() return 3 end, {x = 0, y = 0})
  local session = replay(data)
  session:Call("land.getSurfaceType", nil, {x = 0, y = 0})
  equal(abort(session, function()
    session:Call("land.getSurfaceType", nil, {x = 0, y = 0})
  end, "missing_call").Sequence, 2)
  session:Finish(false)
  session = replay(data)
  equal(abort(session, function() session:Close() end, "unconsumed_call", "failed").Sequence, 1)
end)

test("stage consumer request and candidate boundaries never share cursors", function()
  local session = capture()
  session:Call("land.getSurfaceType", function() return 3 end, {x = 0, y = 0})
  session:Begin("connection", "identity-a", 1, 1)
  session:Call("land.getSurfaceType", function() return 2 end, {x = 0, y = 0})
  session:Begin("depth", "identity-a", 1, 1)
  session:Call("land.getSurfaceType", function() return 1 end, {x = 0, y = 0})
  session:Finish(true)
  local data = session:Export()
  local replaySession = replay(data)
  equal(replaySession:Call("land.getSurfaceType", nil, {x = 0, y = 0}), 3)
  replaySession:Begin("connection", "identity-a", 1, 1)
  equal(replaySession:Call("land.getSurfaceType", nil, {x = 0, y = 0}), 2)
  replaySession:Begin("depth", "identity-a", 1, 1)
  equal(replaySession:Call("land.getSurfaceType", nil, {x = 0, y = 0}), 1)
  equal(replaySession:Finish(true).Verdict, "passed")
  for _, changed in ipairs({
    {"depth", "identity-a", 1, 1}, {"connection", "identity-b", 1, 1},
    {"connection", "identity-a", 2, 1}, {"connection", "identity-a", 1, 2},
  }) do
    replaySession = replay(data)
    replaySession:Call("land.getSurfaceType", nil, {x = 0, y = 0})
    local issue = abort(replaySession, function() replaySession:Begin(unpack(changed)) end, "scope_mismatch", "failed")
    equal(issue.TapeIndex, 2)
    equal(issue.Sequence, 1)
  end
end)

test("empty stage boundaries are retained and remaining or missing tapes are reported", function()
  local session = capture()
  session:Begin("connection", "unit", 1, 1)
  session:Finish(true)
  local data = session:Export()
  local replaySession = replay(data)
  local issue = replaySession:Finish(true).FirstIssue
  equal(issue.Kind, "unconsumed_tape")
  equal(issue.TapeIndex, 2)
  replaySession = replay(data)
  replaySession:Begin("connection", "unit", 1, 1)
  abort(replaySession, function() replaySession:Begin("depth", "unit", 1, 1) end, "missing_tape")
end)

test("call caps include warm scopes of the same stage but are separate between stages", function()
  local session = capture({MaxCallsPerStage = 1})
  local live = 0
  local function sample() live = live + 1; return 3 end
  session:Call("land.getSurfaceType", sample)
  session:Begin("connection", "unit", 1, 1)
  session:Call("land.getSurfaceType", sample)
  session:Begin("search", "unit", 2, 0)
  abort(session, function() session:Call("land.getSurfaceType", sample) end, "capture_limit")
  equal(live, 2)
  equal(session:Finish(false).StageCounts.search.Calls, 1)
  equal(session:Export().Complete, false)
  session = capture({MaxCallsPerStage = 0})
  abort(session, function() session:Call("land.getSurfaceType", sample) end, "capture_limit")
  equal(live, 2)
end)

test("profile record cap counts zero sparse and malformed entries after an atomic response", function()
  local session = capture({MaxProfileRecordsPerStage = 2})
  local live = 0
  local function profile()
    live = live + 1
    return {[0] = false, [2] = {x = 0, y = -30, z = 0}}
  end
  session:Call("land.profile", profile)
  session:Begin("search", "unit", 2, 0)
  local issue = abort(session, function() session:Call("land.profile", profile) end, "capture_limit")
  equal(issue.Exhausted, "profile_records")
  equal(live, 2)
  equal(session:Report().StageCounts.search.ProfileRecords, 2)
  equal(#session:Finish(false).FirstIssue.Scope.Consumer, 4)
  equal(#session:Export().Tapes[2].Calls, 0)
end)

test("byte caps reject known large arguments before admission and large results after admission", function()
  for _, largeArguments in ipairs({true, false}) do
    local session = capture({MaxBytes = 6500})
    local live = 0
    local function native()
      live = live + 1
      return string.rep("x", 8000)
    end
    abort(session, function()
      session:Call("land.getSurfaceType", native, largeArguments and string.rep("x", 8000) or 0)
    end, "capture_limit")
    equal(live, largeArguments and 0 or 1)
    session:Finish(false)
    local data = session:Export()
    equal(data.Complete, false)
    assert(#Transcript.Encode(data) <= 6500)
    equal(#data.Tapes[1].Calls, 0)
  end
end)

test("byte accounting includes scopes separators and issue header without repeatedly encoding history", function()
  local session = capture({MaxBytes = 6500})
  local live = 0
  repeat
    local ok, failure = pcall(session.Call, session, "land.getSurfaceType", function() live = live + 1; return 3 end,
      {x = live, y = 0})
    if not ok then
      assert(session:IsAbort(failure))
      break
    end
  until live > 100
  local report = session:Finish(false)
  equal(report.FirstIssue.Kind, "capture_limit")
  equal(report.FirstIssue.Exhausted, "bytes")
  local data = session:Export()
  assert(#Transcript.Encode(data) <= 6500)
  assert(live < 100)
end)

test("unsupported terrain functions and calls outside a stage are explicit gaps", function()
  local session = capture()
  local live = 0
  abort(session, function()
    session:Call("land.getHeight", function() live = live + 1 end, {x = 0, y = 0})
  end, "unsupported_function")
  equal(live, 0)
  session = Transcript.NewCapture(manifest())
  abort(session, function() session:Call("land.profile", nil) end, "missing_scope")
end)

test("string native exceptions are replayed unchanged and error objects are not serialized", function()
  local session = capture()
  local message = "fixture terrain failure"
  equal(raises(function()
    session:Call("land.profile", function() error(message, 0) end, 1, 2)
  end), message)
  equal(session:Finish(true).Verdict, "passed")
  local data = session:Export()
  equal(data.Tapes[1].Calls[1].Outcome, "error")
  local replaySession = replay(data)
  equal(raises(function() replaySession:Call("land.profile", nil, 1, 2) end), message)
  equal(replaySession:Finish(true).Verdict, "passed")
  session = capture()
  local object = {native = true}
  equal(raises(function() session:Call("land.profile", function() error(object, 0) end) end), object)
  equal(session:Finish(false).FirstIssue.Kind, "unsupported_error")
  equal(#session:Export().Tapes[1].Calls, 0)
end)

test("native errors take priority over record-size caps and stay native errors", function()
  local session = capture({MaxBytes = 6500})
  local message = string.rep("native error ", 1000)
  equal(raises(function() session:Call("land.profile", function() error(message, 0) end) end), message)
  equal(session:Finish(false).FirstIssue.Exhausted, "error_record")
  assert(#Transcript.Encode(session:Export()) <= 6500)
end)

test("code graphs metatables cycles and oversize nesting are non-replayable data", function()
  local cycle = {}
  cycle[1] = cycle
  for _, data in ipairs({function() end, setmetatable({}, {}), cycle}) do
    local session = capture()
    abort(session, function() session:Call("land.profile", function() return data end) end, "unsupported_data")
    equal(session:Finish(false).Complete, false)
    equal(#session:Export().Tapes[1].Calls, 0)
  end
  local nested = {}
  local current = nested
  for _ = 1, 70 do
    current[1] = {}
    current = current[1]
  end
  local session = capture()
  equal(abort(session, function()
    session:Call("land.profile", function() return nested end)
  end, "capture_limit").Exhausted, "depth_limit")
end)

test("incomplete captures cannot replay even their available prefix", function()
  local session = capture()
  session:Call("land.getSurfaceType", function() return 3 end)
  session:Finish(false)
  local replaySession = Transcript.NewReplay(manifest(), session:Export())
  equal(replaySession:Report().FirstIssue.Kind, "capture_incomplete")
  abort(replaySession, function() replaySession:Begin("search", "unit", 1, 0) end, "capture_incomplete")
end)

test("malformed or physically truncated JSON is an inconclusive decoding gap", function()
  local data = capturedOne("land.getSurfaceType", function() return 3 end)
  local bytes = Transcript.Encode(data)
  for _, invalid in ipairs({bytes:sub(1, -2), "return {}", '{"SchemaVersion":1,', "{}", bytes .. "x"}) do
    local decoded, issue = Transcript.Decode(invalid)
    equal(decoded, nil)
    equal(issue.Kind, "invalid_transcript_document")
    equal(issue.Verdict, "inconclusive")
  end
end)

test("schema rejects untrusted call records packs tape order caps and extra fields", function()
  local data = capturedOne("land.getSurfaceType", function() return 3 end, {x = 0, y = 0})
  local changes = {
    function(t) t.SchemaVersion = 2 end,
    function(t) t.Unknown = true end,
    function(t) t.Tapes[1].Unknown = true end,
    function(t) t.Tapes[1].Index = 2 end,
    function(t) t.Tapes[1].Closed = false end,
    function(t) t.Tapes[1].Calls[1].Sequence = 2 end,
    function(t) t.Tapes[1].Calls[1].Function = "land.getHeight" end,
    function(t) t.Tapes[1].Calls[1].Outcome = "success" end,
    function(t) t.Tapes[1].Calls[1].Error = "bad" end,
    function(t) t.Tapes[1].Calls[1].Arguments.Arity = 0 end,
    function(t) t.Tapes[1].Calls[1].Returns.Values[0] = 1 end,
    function(t) t.Tapes[1].Calls[2] = t.Tapes[1].Calls[1]; t.Tapes[1].Calls[1] = nil end,
    function(t) t.Limits.MaxCallsPerStage = 0 end,
    function(t) t.Limits.MaxBytes = false end,
    function(t) t.Manifest.SourceVerification = "verified" end,
  }
  for _, change in ipairs(changes) do
    local changed = Codec.Copy(data)
    change(changed)
    raises(function() Transcript.NewReplay(manifest(), changed) end, "P0 transcript:")
    local decoded = Transcript.Decode(Codec.Encode(changed))
    equal(decoded, nil)
  end
end)

test("decoder enforces declared byte caps and rejects malformed issue metadata before replay", function()
  local data = capturedOne("land.profile", function() return string.rep("x", 8000) end)
  data.Limits.MaxBytes = 6500
  equal(Transcript.Decode(Codec.Encode(data)), nil)
  raises(function() Transcript.NewReplay(manifest(), data) end, "byte_limit")
  local session = capture({MaxCallsPerStage = 0})
  abort(session, function() session:Call("land.getSurfaceType", nil) end, "capture_limit")
  session:Finish(false)
  data = session:Export()
  data.Issue.Scope.Consumer = false
  equal(Transcript.Decode(Codec.Encode(data)), nil)
end)

test("decoder enforces supplied call profile and byte admission caps before handing off data", function()
  local data = capturedOne("land.profile", function()
    return {[0] = {x = 0, y = -30, z = 0}, [1] = {x = 1, y = -30, z = 0}}
  end)
  local bytes = Transcript.Encode(data)
  for _, limits in ipairs({{MaxCallsPerStage = 0}, {MaxProfileRecordsPerStage = 1}, {MaxBytes = #bytes - 1}}) do
    local decoded, issue = Transcript.Decode(bytes, limits)
    equal(decoded, nil)
    equal(issue.Verdict, "inconclusive")
  end
  assert(Transcript.Decode(bytes, {MaxCallsPerStage = 1, MaxProfileRecordsPerStage = 2, MaxBytes = #bytes}))
end)

test("input Lua and source-manifest changes fail before terrain and source proof remains unverified", function()
  local data = capturedOne("land.getSurfaceType", function() return 3 end)
  local changed = manifest("other")
  local session = Transcript.NewReplay(changed, data)
  equal(session:Report().FirstIssue.Kind, "input_mismatch")
  equal(session:Counts().Surface, 0)
  changed = Codec.Copy(data)
  changed.Manifest.LuaVersion = "Lua other"
  session = Transcript.NewReplay(manifest(), changed)
  equal(session:Report().FirstIssue.Kind, "environment_mismatch")
  changed = manifest()
  changed.SourceManifest = {{Path = "Core/Astar.lua", SHA256 = string.rep("a", 64)}}
  session = Transcript.NewReplay(changed, data)
  equal(session:Report().FirstIssue.Kind, "input_mismatch")
  session = replay(data)
  session:Call("land.getSurfaceType", nil)
  local report = session:Finish(true)
  equal(report.SourceVerified, false)
  equal(report.SourceVerification, "unverified")
end)

test("replay admission checks smaller call profile and byte limits before any query", function()
  local data = capturedOne("land.profile", function()
    return {[0] = {x = 0, y = -30, z = 0}, [1] = {x = 1, y = -30, z = 0}}
  end, 1, 2)
  for _, limits in ipairs({{MaxCallsPerStage = 0}, {MaxProfileRecordsPerStage = 1}}) do
    local session = Transcript.NewReplay(manifest(), data, limits)
    equal(session:Report().FirstIssue.Kind, "capture_limit")
    equal(session:Counts().Profile, 0)
    session:Finish(false)
    assert(Transcript.Decode(Transcript.Encode(session:Export())))
  end
  data = capturedOne("land.profile", function() return string.rep("x", 8000) end)
  local session = Transcript.NewReplay(manifest(), data, {MaxBytes = 6500})
  equal(session:Report().FirstIssue.Exhausted, "bytes")
  equal(session:Counts().Profile, 0)
end)

test("invalid limits and finished sessions cannot admit new work or export active data", function()
  for _, limits in ipairs({false, {MaxCallsPerStage = false}, {MaxBytes = 0},
    {MaxProfileRecordsPerStage = 1.5}, {Extra = 1}, {MaxBytes = 64 * 1024 * 1024 + 1}}) do
    raises(function() Transcript.NewCapture(manifest(), limits) end, "P0 transcript:")
  end
  raises(function() Transcript.NewCapture(manifest(), {MaxBytes = 100}) end)
  local session = capture()
  raises(function() session:Export() end, "finish before exporting")
  same(session:Finish(true), session:Finish(false))
  raises(function() session:Call("land.profile", nil) end, "session finished")
end)

test("actual ASTAR search record replay matches reports and never calls live terrain", function()
  local case = compact()
  local result, data = P0.RecordRun(case, environment, "capture-run")
  equal(result.TerrainTranscript.Verdict, "passed")
  equal(data.Complete, true)
  equal(data.Tapes[1].Scope.Stage, "search")
  assert(#data.Tapes[1].Calls > 0)
  local check = forbidLive()
  local replayed = P0.ReplayRun(case, environment, assert(Transcript.Decode(Transcript.Encode(data))), "replay-run")
  check()
  equal(replayed.TerrainTranscript.Verdict, "passed")
  equal(P0.CompareRuns(result, replayed).Verdict, "passed")
  equal(P0.CompareRuns(result, replayed, true).Verdict, "inconclusive")
  same(result.End.SearchTerrainCalls, replayed.End.SearchTerrainCalls)
  equal(os, savedOS)
  equal(land, savedLand)
  equal(environment.ActiveTerrain, nil)
end)

test("replay cannot silently record when its transcript is false or a preparation request is absent", function()
  local case = compact()
  raises(function() P0.ReplayRun(case, environment, false) end, "expected record")
  raises(function() P0.RecordPreparation(case, nil, environment) end, "requires a request")
  raises(function() P0.ReplayPreparation(case, nil, environment, {}) end, "requires a request")
end)

test("actual warm retarget cancellation and invalidation replay public action history", function()
  local case = compact()
  case.Actions = {
    case.Actions[1], case.Actions[2],
    {Kind = "step", MaxNodes = 1, UntilComplete = false},
    {Kind = "retarget", Start = Codec.Copy(case.Route.Start), Goal = {x = 100, y = 0, z = 100}},
    {Kind = "step", UntilComplete = true},
    {Kind = "start", Start = Codec.Copy(case.Route.Start), Goal = {x = 100, y = 0, z = 100}},
    {Kind = "step", UntilComplete = true},
    {Kind = "start", Start = Codec.Copy(case.Route.Start), Goal = Codec.Copy(case.Route.Goal)},
    {Kind = "step", MaxNodes = 1, UntilComplete = false},
    {Kind = "invalidate_terrain", Terrain = Fixtures.Definition("open_water")},
  }
  local result, data = P0.RecordRun(case, environment)
  equal(#data.Tapes, 4)
  local check = forbidLive()
  local replayed = P0.ReplayRun(case, environment, data)
  check()
  equal(P0.CompareRuns(result, replayed).Verdict, "passed")
  equal(replayed.TerrainTranscript.Verdict, "passed")
end)

test("virtual-follow tapes preserve request indices and exact arrival across several windows", function()
  local case = compact("open_water", 1200, "virtual_follow")
  local result, data = P0.RecordRun(case, environment)
  assert(#data.Tapes > 1)
  for index, tape in ipairs(data.Tapes) do
    equal(tape.Scope.RequestIndex, index)
    equal(tape.Scope.Consumer, "virtual_follow")
  end
  local check = forbidLive()
  local replayed = P0.ReplayRun(case, environment, data)
  check()
  equal(P0.CompareRuns(result, replayed).Verdict, "passed")
  equal(replayed.End.VirtualGoalReached, true)
end)

test("identity connection and dense stages record separate ordered tapes for each candidate", function()
  local case = compact()
  local searched = P0.Run(case, environment)
  local request = Codec.Copy(searched.Requests[1])
  local raw = Codec.Copy(request.Native.Candidates[1])
  raw.CandidateId, raw.GeometryId = "copy/2", "copy/2/raw"
  request.Native.Candidates[2] = raw
  local control = {ConsumerId = "identity-a"}
  local result, data = P0.RecordPreparation(case, request, environment, control)
  equal(#data.Tapes, 4)
  for index, tape in ipairs(data.Tapes) do
    equal(tape.Scope.Stage, index % 2 == 1 and "connection" or "depth")
    equal(tape.Scope.CandidateIndex, math.ceil(index / 2))
    equal(tape.Scope.Consumer, "identity-a")
  end
  local check = forbidLive()
  local replayed = P0.ReplayPreparation(case, request, environment, data, control)
  check()
  same(replayed.Candidates, result.Candidates)
  same(replayed.TerrainCalls, result.TerrainCalls)
  equal(replayed.Status, "unverified")
  equal(replayed.ExecutionValidated, false)
  equal(replayed.TerrainTranscript.Verdict, "passed")
end)

test("preparation replay resolves equivalent defaults and rejects a different consumer before queries", function()
  local case = compact()
  local request = P0.Run(case, environment).Requests[1]
  local _, data = P0.RecordPreparation(case, request, environment)
  local check = forbidLive()
  local result = P0.ReplayPreparation(case, request, environment, data,
    {ContextId = "identity", CurrentContextId = "identity", ConsumerId = "identity"})
  check()
  equal(result.TerrainTranscript.Verdict, "passed")
  result = P0.ReplayPreparation(case, request, environment, data, {ConsumerId = "other"})
  equal(result.TerrainTranscript.FirstIssue.Kind, "input_mismatch")
  equal(result.TerrainCalls.Surface, 0)
  equal(result.Status, "error")
end)

test("missing data and a dense-only shoal retain their stage results during replay", function()
  for _, missing in ipairs({true, false}) do
    local case = compact()
    case.Search.Depth.CorridorWidth = 50
    case.Environment.Terrain.Regions = {{XMin = 40, XMax = 80, ZMin = 7, ZMax = 10,
      Depth = missing and 30 or 2, Missing = missing}}
    local raw = P0.Run(case, environment).Requests[1]
    local result, data = P0.RecordPreparation(case, raw, environment)
    equal(result.Candidates[1].Connection.Status, "clear")
    equal(result.Candidates[1].Depth.Status, missing and "unavailable" or "blocked")
    local check = forbidLive()
    local replayed = P0.ReplayPreparation(case, raw, environment, data)
    check()
    same(replayed.Candidates, result.Candidates)
    equal(replayed.TerrainTranscript.Verdict, "passed")
    Fixtures.Terrain = terrainFactory
  end
end)

test("driver input and slice schedule differences stop before queries with explicit mismatch", function()
  local case = compact()
  local _, data = P0.RecordRun(case, environment)
  case.Execution.SliceNodes = 1
  local check = forbidLive()
  local replayed = P0.ReplayRun(case, environment, data)
  check()
  equal(replayed.End.Status, "error")
  equal(replayed.End.Reason, "terrain_replay_mismatch")
  equal(replayed.End.Verdict, "failed")
  equal(replayed.TerrainTranscript.FirstIssue.Kind, "input_mismatch")
  equal(replayed.End.SearchTerrainCalls.Surface, 0)
end)

test("first driver query mismatch cancels native search and restores all fixture bindings", function()
  local case = compact()
  local _, data = P0.RecordRun(case, environment)
  data.Tapes[1].Calls[1].Arguments.Values[1].x =
    data.Tapes[1].Calls[1].Arguments.Values[1].x + 1e-9
  local check = forbidLive()
  local replayed = P0.ReplayRun(case, environment, data)
  check()
  equal(replayed.End.Verdict, "failed")
  equal(replayed.End.CaptureComplete, false)
  equal(replayed.TerrainTranscript.FirstIssue.Kind, "arguments_mismatch")
  equal(replayed.Requests[1].Native.Status, "cancelled")
  equal(replayed.Requests[1].Native.StopReason, "cancelled")
  equal(land, savedLand)
  equal(os, savedOS)
  equal(environment.ActiveTerrain, nil)
end)

test("driver search caps stop at first limit and incomplete captures cannot pass negative assertions", function()
  local case = compact()
  case.Execution.Transcript = {MaxCallsPerStage = 0}
  local result, data = P0.RecordRun(case, environment)
  equal(result.End.Status, "limited")
  equal(result.End.Reason, "capture_limit")
  equal(result.End.Verdict, "inconclusive")
  equal(data.Complete, false)
  equal(result.End.SearchTerrainCalls.Surface, 0)
  equal(result.Requests[1].Native.Status, "cancelled")
  local check = forbidLive()
  local replayed = P0.ReplayRun(case, environment, data)
  check()
  equal(replayed.TerrainTranscript.Verdict, "inconclusive")
  equal(replayed.End.Verdict, "inconclusive")
end)

test("ordinary result-size limits retain capture-limit status and cannot grant a transcript pass", function()
  local case = compact()
  local request = P0.Run(case, environment).Requests[1]
  case.Execution.MaxArtifactBytes = 1500
  local result, data = P0.RecordRun(case, environment)
  equal(result.End.Status, "limited")
  equal(result.End.Reason, "capture_limit")
  equal(result.End.Verdict, "inconclusive")
  equal(result.TerrainTranscript.FirstIssue.Kind, "capture_incomplete")
  equal(data.Complete, false)
  assert(#Codec.Encode(result) <= 1500)
  result, data = P0.RecordPreparation(case, request, environment)
  equal(result.Status, "limited")
  equal(result.Reason, "capture_limit")
  equal(result.CaptureComplete, false)
  equal(data.Complete, false)
  assert(#Codec.Encode(result) <= 1500)
end)

test("validation gap stops later candidate stages and retains PATHLINE's native error report", function()
  local case = compact()
  local request = P0.Run(case, environment).Requests[1]
  request.Native.Candidates[2] = Codec.Copy(request.Native.Candidates[1])
  request.Native.Candidates[2].CandidateId = "second"
  case.Execution.Transcript = {MaxCallsPerStage = 0}
  local result, data = P0.RecordPreparation(case, request, environment)
  equal(result.Status, "limited")
  equal(result.Reason, "capture_limit")
  equal(result.CaptureComplete, false)
  equal(result.Candidates[1].Connection.Status, "limited")
  equal(result.Candidates[1].Connection.Native.Status, "error")
  equal(result.Candidates[1].Depth, nil)
  equal(result.Candidates[2].Status, "not_run")
  equal(result.Candidates[2].Reason, "capture_limit")
  equal(#data.Tapes, 1)
  equal(data.Complete, false)
  equal(land, savedLand)
end)

test("validation replay mismatch does not consume a later stage tape or admit more candidates", function()
  local case = compact()
  local request = P0.Run(case, environment).Requests[1]
  request.Native.Candidates[2] = Codec.Copy(request.Native.Candidates[1])
  request.Native.Candidates[2].CandidateId = "second"
  local _, data = P0.RecordPreparation(case, request, environment)
  data.Tapes[1].Calls[1].Arguments.Values[1].x = 999
  local check = forbidLive()
  local result = P0.ReplayPreparation(case, request, environment, data)
  check()
  equal(result.Status, "error")
  equal(result.TerrainTranscript.Verdict, "failed")
  equal(result.TerrainTranscript.FirstIssue.Kind, "arguments_mismatch")
  equal(result.Candidates[1].Connection.Native.Status, "error")
  equal(result.Candidates[1].Depth, nil)
  equal(result.Candidates[2].Status, "not_run")
  equal(result.Candidates[2].Reason, "terrain_replay_mismatch")
end)

test("cancellation context mismatch and no-candidate preparation replay empty scopes without terrain", function()
  local case = compact()
  local request = P0.Run(case, environment).Requests[1]
  for _, control in ipairs({{CancelAfterSlices = 0}, {ContextId = "new", CurrentContextId = "old"}}) do
    local result, data = P0.RecordPreparation(case, request, environment, control)
    equal(#data.Tapes, 1)
    equal(#data.Tapes[1].Calls, 0)
    local check = forbidLive()
    local replayed = P0.ReplayPreparation(case, request, environment, data, control)
    check()
    same(replayed.Candidates, result.Candidates)
    equal(replayed.TerrainTranscript.Verdict, "passed")
    Fixtures.Terrain = terrainFactory
  end
  request.Native.Candidates = {}
  local result, data = P0.RecordPreparation(case, request, environment)
  equal(result.Status, "not_run")
  equal(#data.Tapes, 0)
  equal(P0.ReplayPreparation(case, request, environment, data).TerrainTranscript.Verdict, "passed")
end)

test("native driver exceptions propagate with environment restored and fixture-only binding is enforced", function()
  local case = compact()
  case.Environment.Terrain.ErrorFunction = "Surface"
  raises(function() P0.RecordRun(case, environment) end, "P0 fixture: injected Surface error")
  equal(land, savedLand)
  equal(os, savedOS)
  equal(environment.ActiveTerrain, nil)
  case = compact()
  land = {SurfaceType = savedLand.SurfaceType}
  raises(function() P0.RecordRun(case, environment) end, "owned standalone fixture")
  equal(os, savedOS)
  equal(environment.ActiveTerrain, nil)
end)

test("fixture setup failures restore land clock and prior active terrain before rethrowing", function()
  local previous = {Id = "previous"}
  environment.ActiveTerrain = previous
  local failure = {programming = true}
  Fixtures.Terrain = function() error(failure, 0) end
  equal(raises(function() P0.RecordRun(compact(), environment) end), failure)
  equal(land, savedLand)
  equal(os, savedOS)
  equal(environment.ActiveTerrain, previous)
end)

test("native preparation exceptions still propagate after evaluator and fixture cleanup", function()
  local case = compact()
  local request = P0.Run(case, environment).Requests[1]
  case.Environment.Terrain.ErrorFunction = "Profile"
  raises(function()
    P0.RecordPreparation(case, request, environment)
  end, "P0 fixture: injected Profile error")
  equal(land, savedLand)
  equal(os, savedOS)
  equal(environment.ActiveTerrain, nil)
end)

equal(environment.ForbiddenCalls, 0)
print(string.format("%d passed, %d failed (P0-I2; %s)", passed, failed, _VERSION))
if failed > 0 then
  savedOS.exit(1)
end
