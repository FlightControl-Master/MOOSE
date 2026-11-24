-- P0-I1 standalone analytic search/handoff regressions. Run from repo root:
-- lua tests/local-pathfinding.lua (Lua 5.1; each suite in its own process).
-- Uses actual VECTOR/GRID/ASTAR/PATHLINE methods with isolated terrain/clock.
-- No DCS physics, source-hash verification, transcript replay or vessel control.
local P0 = dofile("tests/support/local-pathfinding.lua")
local Codec, Fixtures = P0.Codec, P0.Fixtures
local environment = Fixtures.Install()
local savedOS = os
local passed, failed = 0, 0

local function equal(actual, expected)
  assert(actual == expected, "expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

local function same(actual, expected)
  local comparison = Codec.Compare(actual, expected)
  assert(comparison.Verdict == "passed", "difference at " .. (comparison.Difference and comparison.Difference.Path or "?"))
end

local function raises(callback, message)
  local ok, failure = pcall(callback)
  assert(not ok, "expected an error")
  assert(tostring(failure):find(message, 1, true), tostring(failure))
end

local function test(name, callback)
  local ok, failure = pcall(callback)
  os = savedOS
  environment.ActiveTerrain = nil
  if ok then
    passed = passed + 1
    print("PASS " .. name)
  else
    failed = failed + 1
    print("FAIL " .. name .. ": " .. tostring(failure))
  end
end

local function compact(kind, distance, experiment)
  local case = Fixtures.Case(kind or "open_water", experiment)
  case.VariantId = "compact-explicit-window"
  case.Search.Grid.Type, case.Search.Grid.Spacing = "rectangular", 100
  case.Search.Grid.MaxCells = 500
  case.Search.Window = {Ahead = 400, Width = 400, Behind = 100}
  case.Route.Goal.x = distance or 200
  if case.Actions[2] then
    case.Actions[2].Goal = Codec.Copy(case.Route.Goal)
  end
  return case
end

local function run(case, id)
  return P0.Run(case, environment, id)
end

local function final(artifact)
  return assert(artifact.Requests[#artifact.Requests]).Native
end

local function appendRequest(case, first, last, heading)
  case.Actions[#case.Actions + 1] = {Kind = "start", Start = Codec.Copy(first),
    Goal = Codec.Copy(last), Heading = heading}
  case.Actions[#case.Actions + 1] = {Kind = "step", UntilComplete = true}
end

local function requestFor(case, positions)
  local artifact = run(case)
  local request = Codec.Copy(artifact.Requests[1])
  local candidate = request.Native.Candidates[1]
  if positions then
    candidate.Positions = Codec.Copy(positions)
    candidate.ReachesGoal = true
  end
  return request
end

test("baseline resolves all shared settings without changing input", function()
  local case = Fixtures.Case("open_water")
  local before = Codec.Copy(case)
  local resolved = P0.ResolveCase(case)
  same(case, before)
  equal(resolved.Search.Cost.Weight, 1)
  equal(resolved.Search.Window.Ahead, 6000)
  equal(resolved.Search.Window.Width, 4000)
  equal(resolved.Search.Window.Behind, 1500)
  equal(resolved.Validation.Depth.MinDepth, 3.5)
  equal(resolved.Validation.Depth.CorridorWidth, 50)
  equal(resolved.Actions[2].Heading, 0)
end)

test("schema rejects unknown fields sparse arrays and false defaults", function()
  local case = compact()
  case.Search.Extra = true
  raises(function() run(case) end, "unknown field")
  case.Search.Extra = nil
  case.Actions[4], case.Actions[2] = case.Actions[2], nil
  raises(function() run(case) end, "sparse array")
  case = compact()
  case.Actions[3].Stage = false
  raises(function() run(case) end, "search-only")
  case = compact()
  case.Actions[4] = {Kind = "cancel", Reason = false}
  raises(function() run(case) end, "invalid string")
end)

test("nonfinite inputs and conflicting hard-depth copies fail before terrain", function()
  local case = compact()
  case.Route.Start.x = 0 / 0
  raises(function() run(case) end, "invalid number")
  case = compact()
  case.Validation.Depth.MinDepth = 1
  raises(function() run(case) end, "input_mismatch")
  case = compact()
  case.Environment.Terrain.ErrorFunction = "Surface"
  case.Search.Grid.Spacing = 0
  raises(function() run(case) end, "Grid.Spacing")
end)

test("zero false and missing speed remain distinct", function()
  local case = compact()
  case.Search.LearningLimit, case.Search.Cost.Weight = 0, 0
  case.Search.Depth.CorridorWidth = 0
  case.Execution.Debug = false
  case.Execution.Connection.Slice.MaxEvaluatorCalls = 0
  case.Pose.ActualSpeedMps, case.Pose.RequestedSpeedMps = 0, nil
  local resolved = P0.DecodeCase(Codec.Encode(case))
  equal(resolved.Search.LearningLimit, 0)
  equal(resolved.Execution.Connection.Slice.MaxEvaluatorCalls, 0)
  equal(resolved.Pose.ActualSpeedMps, 0)
  equal(resolved.Pose.RequestedSpeedMps, nil)
  equal(resolved.Execution.Debug, false)
  equal(run(case).End.Verdict, "passed")
end)

test("heading follows DCS axes and preserves full Vec3 inputs", function()
  local case = compact()
  case.Route.Start.y, case.Route.Goal.y = 7, 11
  case.Route.Goal.x, case.Route.Goal.z = 0, 201
  case.Actions[2].Start, case.Actions[2].Goal = Codec.Copy(case.Route.Start), Codec.Copy(case.Route.Goal)
  case.Pose.HeadingDeg = -90
  local resolved = P0.ResolveCase(case)
  equal(resolved.Actions[2].Heading, 90)
  equal(resolved.Pose.HeadingDeg, 270)
  local artifact = run(case)
  equal(artifact.Requests[1].Input.Start.y, 7)
  equal(artifact.Requests[1].Input.Goal.y, 11)
  equal(final(artifact).PlanningStart.y, 7)
end)

test("cold paired actual searches retain ordered endpoints costs and ownership", function()
  local case = Fixtures.Case("open_water")
  local first, second = run(case, "first"), run(case, "second")
  equal(P0.CompareRuns(first, second).Verdict, "passed")
  equal(first.End.Verdict, "passed")
  local candidate = final(first).Candidates[1]
  same(candidate.Positions[1], case.Route.Start)
  same(candidate.Positions[#candidate.Positions], case.Route.Goal)
  equal(candidate.Cost, 2000)
  equal(candidate.ReachesGoal, true)
  equal(candidate.Path, nil)
  candidate.Positions[1].x = -1000
  equal(final(second).Candidates[1].Positions[1].x, 0)
end)

test("one-unit slices match native semantics and do not repeat terrain calls", function()
  local case = compact()
  local normal = run(case, "normal")
  case.Execution.SliceNodes = 1
  local small = run(case, "small")
  equal(P0.CompareRuns(normal, small).Verdict, "passed")
  same(normal.End.SearchTerrainCalls, small.End.SearchTerrainCalls)
  assert(small.Requests[1].Slices > normal.Requests[1].Slices)
  assert(P0.CompareRuns(normal, small).DiagnosticDifferences)
end)

test("last admitted completion takes precedence over simultaneous driver caps", function()
  local case = compact()
  case.Execution.SliceNodes = 1
  local reference = run(case)
  case.Execution.MaxSlicesPerRequest = reference.Requests[1].Slices
  case.Execution.MaxWorkItemsPerRequest = final(reference).WorkItems
  local artifact = run(case)
  equal(artifact.End.Status, "complete")
  equal(artifact.End.Verdict, "passed")
end)

test("work then slice precedence retains native cancellation separately", function()
  local case = compact()
  case.Execution.SliceNodes = 1
  case.Execution.MaxWorkItemsPerRequest, case.Execution.MaxSlicesPerRequest = 1, 1
  case.Expected = {DriverStatus = "limited", NativeStopReason = "cancelled"}
  local artifact = run(case)
  equal(artifact.End.Reason, "driver_request_work_limit")
  same(artifact.End.Exhausted, {"work", "slice"})
  equal(final(artifact).Status, "cancelled")
  equal(final(artifact).WorkItems, 1)
  equal(artifact.Requests[1].DriverReason, "driver_request_work_limit")
  equal(artifact.End.Verdict, "passed")
end)

test("slice cap and remaining admission never become a cell failure", function()
  local case = compact()
  case.Execution.MaxSlicesPerRequest = 1
  case.Execution.SliceNodes = 1
  local artifact = run(case)
  equal(artifact.End.Reason, "driver_slice_limit")
  equal(final(artifact).StopReason, "cancelled")
  case = compact()
  case.Execution.MaxWorkItemsPerRequest = 3
  artifact = run(case)
  equal(final(artifact).WorkItems, 3)
  equal(artifact.End.Reason, "driver_request_work_limit")
end)

test("zero driver work slice request and validation caps admit no operation", function()
  local case = compact()
  case.Execution.MaxWorkItemsPerRequest = 0
  local artifact = run(case)
  equal(final(artifact).WorkItems, 0)
  same(artifact.End.SearchTerrainCalls, {Surface = 0, Depth = 0, Profile = 0})
  case.Execution.MaxWorkItemsPerRequest, case.Execution.MaxSlicesPerRequest = 400000, 0
  artifact = run(case)
  equal(artifact.End.Reason, "driver_slice_limit")
  equal(final(artifact).WorkItems, 0)
  case.Execution.MaxRequests = 0
  artifact = run(case)
  equal(artifact.End.Reason, "driver_request_limit")
  equal(#artifact.Requests, 0)
  case = compact()
  local request = run(case).Requests[1]
  case.Execution.MaxValidationSlices = 0
  local result = P0.PrepareIdentity(case, request, environment)
  equal(result.Status, "limited")
  equal(result.Slices, 0)
  same(result.TerrainCalls, {Surface = 0, Depth = 0, Profile = 0})
end)

test("expected native cell limit passes its negative test without arrival", function()
  local case = compact()
  case.Search.Grid.MaxCells = 1
  case.Expected = {DriverStatus = "complete", NativeStopReason = "cell_limit", VirtualGoalReached = false}
  local artifact = run(case)
  equal(artifact.End.Verdict, "passed")
  equal(final(artifact).BudgetLimited, true)
  equal(final(artifact).FailureReason, nil)
end)

test("virtual following observes actual copied points and reaches exact goal", function()
  local case = compact("open_water", 1200, "virtual_follow")
  case.Expected = {DriverStatus = "complete", VirtualGoalReached = true}
  local artifact = run(case)
  equal(artifact.End.Verdict, "passed")
  same(artifact.End.VirtualPosition, case.Route.Goal)
  assert(#artifact.Requests > 1)
  for index = 2, #artifact.Requests do
    local previous = artifact.Requests[index - 1].Native.Candidates[1]
    same(artifact.Requests[index].Input.Start, previous.Positions[#previous.Positions])
    assert(artifact.Requests[index].Native.Progress.Distance > 0)
  end
end)

test("virtual request limit is bounded and cannot claim global arrival", function()
  local case = compact("open_water", 1200, "virtual_follow")
  case.Execution.MaxRequests = 1
  case.Expected = {DriverStatus = "limited", VirtualGoalReached = false, RequestCount = 1}
  local artifact = run(case)
  equal(artifact.End.Verdict, "passed")
  equal(artifact.End.Reason, "driver_request_limit")
  equal(artifact.End.VirtualPosition, nil)
end)

test("virtual run rejects ignored scripted actions and nonvirtual observations", function()
  local case = compact("open_water", 1200, "virtual_follow")
  case.Actions[2] = {Kind = "cancel"}
  raises(function() run(case) end, "one explicit initial")
  case.Actions[2] = nil
  case.Actions[1].Provenance = "measured"
  raises(function() run(case) end, "one explicit initial")
end)

test("compatible warm requests retain window cache but own their reports", function()
  local case = compact()
  appendRequest(case, case.Route.Start, case.Route.Goal)
  case.Expected.WindowReused = true
  local first, second = run(case, "warm-one"), run(case, "warm-two")
  equal(P0.CompareRuns(first, second).Verdict, "passed")
  equal(first.End.Verdict, "passed")
  equal(first.Requests[1].Native.WindowReused, false)
  equal(first.Requests[2].LogicalWindowID, first.Requests[1].LogicalWindowID)
  assert(first.Requests[2].Native.RestoredCacheEntries > 0)
  equal(first.Requests[1].Native.RequestID, 1)
  equal(first.Requests[2].Native.RequestID, 2)
end)

test("explicit heading change creates a replacement window", function()
  local case = compact()
  appendRequest(case, case.Route.Start, case.Route.Goal, 30)
  case.Expected.WindowReused = false
  local artifact = run(case)
  equal(artifact.End.Verdict, "passed")
  equal(artifact.Requests[2].LogicalWindowID, 2)
end)

test("partial learning and repeated planning require no fabricated motion", function()
  local case = compact("open_water", 1200)
  appendRequest(case, case.Route.Start, case.Route.Goal)
  appendRequest(case, case.Route.Start, case.Route.Goal)
  case.Expected = {ProgressStatus = "repeated_planning"}
  local artifact = run(case)
  equal(artifact.End.Verdict, "passed")
  equal(final(artifact).Progress.Distance, 0)
  assert(final(artifact).LearningEntries > 0)
  assert(final(artifact).LearningWorkItems > 0)
end)

test("explicit directed observations detect loops but do not reject search", function()
  local case = compact()
  case.Actions = {{Kind = "observe", Position = Codec.Copy(case.Route.Start), Provenance = "virtual"}}
  for index = 1, 5 do
    case.Actions[#case.Actions + 1] = {Kind = "observe",
      Position = {x = index % 2 == 1 and 100 or 0, y = 0, z = 0}, Provenance = "virtual"}
  end
  appendRequest(case, case.Route.Start, case.Route.Goal)
  case.Expected.ProgressStatus = "loop_detected"
  equal(run(case).End.Verdict, "passed")
end)

test("explicit cancellation ends pending work and an explicit new request can start", function()
  local case = compact()
  case.Actions[3] = {Kind = "step", MaxNodes = 1, UntilComplete = false}
  case.Actions[4] = {Kind = "cancel", Reason = "explicit-test-stop"}
  case.Expected = {DriverStatus = "cancelled", NativeStopReason = "cancelled"}
  local stopped = run(case)
  equal(stopped.End.Verdict, "passed")
  equal(final(stopped).WorkItems, 1)
  equal(stopped.Requests[1].DriverReason, "explicit-test-stop")
  appendRequest(case, case.Route.Start, case.Route.Goal)
  case.Expected = {DriverStatus = "complete", NativeStopReason = "path_found"}
  local restarted = run(case)
  equal(restarted.End.Verdict, "passed")
  equal(restarted.Requests[1].Native.StopReason, "cancelled")
  equal(#restarted.Requests, 2)
end)

test("retarget captures cancelled old request and uses the new exact goal", function()
  local case = compact()
  case.Actions[3] = {Kind = "step", MaxNodes = 1, UntilComplete = false}
  local newGoal = {x = 100, y = 0, z = 101}
  case.Actions[4] = {Kind = "retarget", Start = Codec.Copy(case.Route.Start), Goal = newGoal}
  case.Actions[5] = {Kind = "step", UntilComplete = true}
  local artifact = run(case)
  equal(artifact.Requests[1].Native.StopReason, "cancelled")
  equal(artifact.Requests[1].DriverReason, "retarget")
  same(artifact.Requests[2].Input.Goal, newGoal)
  local candidate = final(artifact).Candidates[1]
  same(candidate.Positions[#candidate.Positions], newGoal)
end)

test("invalidation cancels before obsolete terrain queries", function()
  local case = compact()
  case.Actions[3] = {Kind = "step", MaxNodes = 1, UntilComplete = false}
  local changed = Fixtures.Definition("open_water")
  changed.Revision, changed.ErrorFunction = "changed", "Surface"
  case.Actions[4] = {Kind = "invalidate_terrain", Terrain = changed}
  case.Expected = {NativeStopReason = "search_changed"}
  local artifact = run(case)
  equal(artifact.End.Verdict, "passed")
  equal(final(artifact).WorkItems, 1)
  equal(artifact.Requests[1].DriverReason, "invalidate_terrain")
end)

test("source verified parity stays inconclusive and absent clocks stay absent", function()
  local case = compact()
  local first = run(case)
  case.Execution.Clock = "unavailable"
  local second = run(case)
  equal(final(second).SearchCPUSeconds, nil)
  equal(P0.CompareRuns(first, second).Verdict, "passed")
  equal(P0.CompareRuns(first, second, true).Verdict, "inconclusive")
  equal(P0.CompareRuns(first, second, true).Reason, "source_unverified")
end)

test("strict comparison reports the first exact coordinate difference", function()
  local artifact = run(compact())
  local modified = Codec.Copy(artifact)
  modified.Requests[1].Native.Candidates[1].Positions[2].x =
    modified.Requests[1].Native.Candidates[1].Positions[2].x + 1e-9
  local comparison = P0.CompareRuns(artifact, modified)
  equal(comparison.Verdict, "failed")
  equal(comparison.Difference.Path, "$.Requests[1].Native.Candidates[1].Positions[2].x")
end)

test("debug draws only copies and leaves search query counts unchanged", function()
  local case = compact()
  local normal = run(case)
  local previousDraws = environment.DrawingCalls
  case.Execution.Debug = true
  local debug = run(case)
  equal(P0.CompareRuns(normal, debug).Verdict, "passed")
  same(normal.End.SearchTerrainCalls, debug.End.SearchTerrainCalls)
  assert(environment.DrawingCalls > previousDraws)
end)

test("fanout mutation cannot corrupt another consumer or raw report", function()
  local request = run(compact()).Requests[1]
  local before = Codec.Copy(request)
  local first, second = P0.FanoutRequest(request)
  first.Native.Candidates[1].Positions[1].x = -10
  first.Input.Goal.z = -100
  same(second, before)
  same(request, before)
  local case = compact()
  local firstPrepared = P0.PrepareIdentity(case, second, environment)
  local secondPrepared = P0.PrepareIdentity(case, request, environment)
  same(firstPrepared, secondPrepared)
  firstPrepared.Candidates[1].Geometry.Positions[1].z = -10
  equal(secondPrepared.Candidates[1].Geometry.Positions[1].z, 0)
  same(request, before)
end)

test("weight variant changes cost while preserving hard clearance", function()
  local case = Fixtures.Case("shoal")
  local first = run(case)
  case.Search.Cost.Weight, case.VariantId = 10, "weight-10"
  local second = run(case)
  equal(first.End.Verdict, "passed")
  equal(second.End.Verdict, "passed")
  same(first.ResolvedCase.Search.Depth, second.ResolvedCase.Search.Depth)
  assert(final(first).Candidates[1].Cost >= final(first).Candidates[1].Length)
  assert(final(second).Candidates[1].Cost >= final(second).Candidates[1].Length)
  assert(P0.CompareRuns(first, second).Verdict == "failed")
end)

test("analytic island search finds a checked detour", function()
  local case = Fixtures.Case("island")
  local artifact = run(case)
  equal(artifact.End.Verdict, "passed")
  assert(final(artifact).Candidates[1].Length > 2000)
  local preparation = P0.PrepareIdentity(case, artifact.Requests[1], environment)
  equal(preparation.Candidates[1].Depth.Status, "clear")
  equal(preparation.Candidates[1].Status, "unverified")
end)

test("only shallow feasible passage remains valid under weight ten", function()
  local case = compact()
  case.Environment.Terrain.Depth = 5
  case.Search.Cost.Weight = 10
  local artifact = run(case)
  equal(artifact.End.Verdict, "passed")
  assert(final(artifact).Candidates[1].Cost > final(artifact).Candidates[1].Length)
  equal(P0.PrepareIdentity(case, artifact.Requests[1], environment).Candidates[1].Depth.Status, "clear")
end)

test("missing depth is unavailable rather than blocked or successful", function()
  local case = Fixtures.Case("missing_data")
  case.Expected = {NativeStopReason = "data_unavailable", DataIncomplete = true}
  local artifact = run(case)
  equal(artifact.End.Verdict, "passed")
  equal(final(artifact).FailureReason, nil)
  equal(final(artifact).CandidateCount, 0)
end)

test("unknown alternatives do not invalidate a checked candidate", function()
  local case = compact()
  case.Environment.Terrain.Regions = {{XMin = 50, XMax = 500, ZMin = 50, ZMax = 500, Missing = true}}
  local artifact = run(case)
  equal(final(artifact).DataIncomplete, true)
  equal(final(artifact).StopReason, "path_found")
  local preparation = P0.PrepareIdentity(case, artifact.Requests[1], environment)
  equal(preparation.Candidates[1].Depth.Status, "clear")
end)

test("identity reports fresh connections dense coverage and unverified maneuver", function()
  local case = compact("open_water", 200, "fixed_pose_prepare")
  local request = run(case).Requests[1]
  local before = Codec.Copy(request)
  local result = P0.PrepareIdentity(case, request, environment)
  same(request, before)
  equal(result.Status, "unverified")
  equal(result.ExecutionValidated, false)
  local candidate = result.Candidates[1]
  equal(candidate.Geometry.Status, "clear")
  equal(candidate.Connection.Native.Status, "clear")
  equal(candidate.Depth.Native.Status, "clear")
  equal(candidate.Depth.Native.Coverage.OffsetCount, 7)
  equal(candidate.Maneuver.Status, "unverified")
  equal(candidate.Selected, false)
  equal(candidate.PreparedCost, candidate.Raw.Cost)
  equal(candidate.PreparedScore, candidate.Raw.Score)
  assert(candidate.Connection.TerrainCalls.Profile > 0)
  assert(candidate.Depth.TerrainCalls.Profile > 0)
end)

test("heading and speed affect preparation inputs but never the raw search", function()
  local case = compact()
  local first = run(case)
  case.Pose.HeadingDeg, case.Pose.ActualSpeedMps, case.Pose.RequestedSpeedMps = 180, 2, 6
  local second = run(case)
  equal(P0.CompareRuns(first, second).Verdict, "passed")
  local result = P0.PrepareIdentity(case, second.Requests[1], environment)
  equal(result.Pose.HeadingDeg, 180)
  equal(result.Pose.ActualSpeedMps, 2)
  equal(result.Pose.RequestedSpeedMps, 6)
  equal(result.Candidates[1].Maneuver.Status, "unverified")
end)

test("pose mismatch and changed candidate endpoint are explicit geometry failures", function()
  local case = compact("open_water", 200, "fixed_pose_prepare")
  local request = run(case).Requests[1]
  case.Pose.Position.x = 1
  raises(function() P0.PrepareIdentity(case, request, environment) end, "pose input_mismatch")
  case.Pose.Position.x = 0
  request.Native.Candidates[1].Positions[1].x = 1
  local result = P0.PrepareIdentity(case, request, environment)
  equal(result.Candidates[1].Status, "rejected")
  equal(result.Candidates[1].Reason, "endpoint_mismatch")
  same(result.TerrainCalls, {Surface = 0, Depth = 0, Profile = 0})
end)

test("fresh connection catches changed interior shallow and land evidence", function()
  for _, field in ipairs({"Depth", "Land"}) do
    local case = compact()
    local request = requestFor(case, {{x = 0, y = 0, z = 0}, {x = 200, y = 0, z = 0}})
    case.Environment.Terrain.Regions = {{XMin = 80, XMax = 120, ZMin = -10, ZMax = 10}}
    case.Environment.Terrain.Regions[1][field] = field == "Depth" and 2 or true
    local result = P0.PrepareIdentity(case, request, environment)
    equal(result.Candidates[1].Status, "rejected")
    equal(result.Candidates[1].Connection.Native.Status, "blocked")
    assert(result.Candidates[1].Connection.Evidence.FirstFailure.Depth.Location)
    equal(result.Candidates[1].Depth, nil)
  end
end)

test("dense lateral validation sees a shoal between ASTAR edge profiles", function()
  local case = compact()
  local request = requestFor(case, {{x = 0, y = 0, z = 0}, {x = 200, y = 0, z = 0}})
  case.Environment.Terrain.Regions = {{XMin = 80, XMax = 120, ZMin = 7, ZMax = 10, Depth = 2}}
  local result = P0.PrepareIdentity(case, request, environment)
  local candidate = result.Candidates[1]
  equal(candidate.Connection.Status, "clear")
  equal(candidate.Depth.Status, "blocked")
  equal(candidate.Status, "rejected")
  assert(candidate.Depth.Native.Failure.Position)
end)

test("missing depth on a selected connection remains unavailable", function()
  local case = compact()
  local request = run(case).Requests[1]
  case.Environment.Terrain.Regions = {{XMin = 20, XMax = 180, ZMin = -100, ZMax = 100, Missing = true}}
  local candidate = P0.PrepareIdentity(case, request, environment).Candidates[1]
  equal(candidate.Status, "unavailable")
  equal(candidate.Connection.Status, "unavailable")
  equal(candidate.Connection.Native.TotalCost, nil)
end)

test("dense unavailable stage is distinct from a clear fresh connection", function()
  local case = compact()
  local request = requestFor(case, {{x = 0, y = 0, z = 0}, {x = 200, y = 0, z = 0}})
  case.Environment.Terrain.Regions = {{XMin = 80, XMax = 120, ZMin = 7, ZMax = 10, Missing = true}}
  local candidate = P0.PrepareIdentity(case, request, environment).Candidates[1]
  equal(candidate.Connection.Status, "clear")
  equal(candidate.Depth.Status, "unavailable")
  equal(candidate.Status, "unavailable")
end)

test("preparation cancellation and stale context occur before terrain access", function()
  local case = compact()
  local request = run(case).Requests[1]
  for _, control in ipairs({{CancelAfterSlices = 0}, {ContextId = 0, CurrentContextId = "new"}}) do
    local result = P0.PrepareIdentity(case, request, environment, control)
    equal(result.Candidates[1].Status, "cancelled")
    equal(result.Candidates[1].Connection.Native.Status, "cancelled")
    same(result.TerrainCalls, {Surface = 0, Depth = 0, Profile = 0})
  end
end)

test("validation total and shared slice caps retain native versus driver reasons", function()
  local case = compact()
  local request = run(case).Requests[1]
  case.Execution.Connection.Total.MaxEvaluatorCalls = 0
  local candidate = P0.PrepareIdentity(case, request, environment).Candidates[1]
  equal(candidate.Status, "limited")
  equal(candidate.Connection.Native.Status, "limited")
  equal(candidate.Connection.Native.Reason, "evaluator_limit")
  case.Execution.Connection.Total.MaxEvaluatorCalls = 4096
  case.Execution.Connection.Slice.MaxWorkUnits = 0
  case.Execution.MaxValidationSlices = 2
  candidate = P0.PrepareIdentity(case, request, environment).Candidates[1]
  equal(candidate.Status, "limited")
  equal(candidate.Connection.Native.Status, "cancelled")
  equal(candidate.Connection.Reason, "driver_validation_slice_limit")
end)

test("cancelled preparation leaves remaining ordered candidates explicitly not run", function()
  local case = compact("open_water", 1200)
  local request = run(case).Requests[1]
  assert(#request.Native.Candidates > 1)
  local result = P0.PrepareIdentity(case, request, environment, {CancelAfterSlices = 0})
  equal(#result.Candidates, #request.Native.Candidates)
  equal(result.Candidates[1].Status, "cancelled")
  for index = 2, #result.Candidates do
    equal(result.Candidates[index].Status, "not_run")
    equal(result.Candidates[index].Reason, "test_cancel")
  end
end)

test("geometry resource limits are limited and empty candidate sets are not run", function()
  local case = compact()
  local request = run(case).Requests[1]
  case.Validation.Geometry.MaxPoints = 1
  local result = P0.PrepareIdentity(case, request, environment)
  equal(result.Status, "limited")
  equal(result.Candidates[1].Status, "limited")
  equal(result.Candidates[1].Reason, "point_limit")
  same(result.TerrainCalls, {Surface = 0, Depth = 0, Profile = 0})
  request.Native.Candidates = {}
  result = P0.PrepareIdentity(case, request, environment)
  equal(result.Status, "not_run")
  equal(#result.Candidates, 0)
end)

test("preparation byte limit is incomplete and carries no ready proposal", function()
  local case = compact()
  local request = run(case).Requests[1]
  case.Execution.MaxArtifactBytes = 2000
  local result = P0.PrepareIdentity(case, request, environment)
  equal(result.CaptureComplete, false)
  equal(result.Status, "limited")
  equal(result.Reason, "capture_limit")
  equal(result.ExecutionValidated, false)
  assert(#Codec.Encode(result) <= 2000)
  same(result.TerrainCalls, {Surface = 0, Depth = 0, Profile = 0})
end)

test("small versus large validation slices preserve coverage evidence and query counts", function()
  local case = compact()
  local request = run(case).Requests[1]
  local normal = P0.PrepareIdentity(case, request, environment)
  case.Execution.Connection.Slice = {MaxWorkUnits = 1, MaxEvaluatorCalls = 1}
  case.Execution.Depth.Slice = {MaxWorkUnits = 1, MaxPointChecks = 1, MaxProfileQueries = 1}
  local small = P0.PrepareIdentity(case, request, environment)
  equal(small.Candidates[1].Status, normal.Candidates[1].Status)
  same(small.TerrainCalls, normal.TerrainCalls)
  same(small.Candidates[1].Depth.Native.Coverage, normal.Candidates[1].Depth.Native.Coverage)
  equal(small.Candidates[1].Depth.Native.Counters.WorkUnits, normal.Candidates[1].Depth.Native.Counters.WorkUnits)
  assert(small.Slices > normal.Slices)
end)

test("position candidate and event capture limits are incomplete rather than replay passes", function()
  local case = compact()
  case.Execution.MaxPositionsPerCandidate = 1
  local artifact = run(case)
  equal(artifact.End.Reason, "capture_limit")
  equal(artifact.End.CaptureComplete, false)
  equal(artifact.End.Verdict, "inconclusive")
  equal(artifact.End.UncapturedNative.StopReason, "path_found")
  equal(P0.CompareRuns(artifact, artifact).Verdict, "inconclusive")
  case = compact("open_water", 1200)
  case.Execution.MaxCandidates = 1
  artifact = run(case)
  equal(artifact.End.Reason, "capture_limit")
  same(artifact.End.Exhausted, {"candidates"})
  case = compact()
  case.Execution.MaxEvents = 2
  artifact = run(case)
  equal(artifact.End.CaptureComplete, false)
  equal(#artifact.Events, 2)
end)

test("artifact byte cap checks the whole manifest and stops before next request", function()
  local case = compact()
  local reference = run(case)
  case.Execution.MaxArtifactBytes = #Codec.Encode(reference) - 100
  local artifact = run(case)
  equal(artifact.End.CaptureComplete, false)
  equal(artifact.End.Verdict, "inconclusive")
  equal(artifact.End.Reason, "capture_limit")
  assert(#Codec.Encode(artifact) <= case.Execution.MaxArtifactBytes)
  case.Execution.MaxArtifactBytes = 2000
  artifact = run(case)
  equal(artifact.End.Reason, "capture_limit")
  assert(#Codec.Encode(artifact) <= 2000)
end)

test("native exceptions propagate after environment cleanup with no movement or timers", function()
  for _, field in ipairs({"Surface", "Depth", "Profile"}) do
    local case = compact()
    case.Environment.Terrain.ErrorFunction = field
    raises(function() run(case) end, "injected " .. field .. " error")
    equal(os, savedOS)
    equal(environment.ActiveTerrain, nil)
  end
  local case = compact()
  local request = run(case).Requests[1]
  case.Environment.Terrain.ErrorFunction = "Profile"
  raises(function() P0.PrepareIdentity(case, request, environment) end, "injected Profile error")
  equal(os, savedOS)
  equal(environment.ActiveTerrain, nil)
  equal(environment.ForbiddenCalls, 0)
end)

test("canonical JSON round trips binary64 UTF8 booleans special values and nil arity", function()
  local values = Codec.Pack(nil, false, 0, 1.0000000000000002, 5e-324, 1e308,
    "\195\164\240\159\154\162", 0 / 0, math.huge, -math.huge, nil)
  local copied = Codec.Copy(values)
  equal(copied.Arity, 11)
  equal(select("#", unpack(copied.Values, 1, copied.Arity)), 11)
  same(values, copied)
  equal(Codec.Decode('"\\ud83d\\udea2"'), "\240\159\154\162")
  equal(Codec.Encode({b = false, a = 0}), '{"a":0,"b":false}')
  equal(Codec.Encode(Codec.Copy({["$lua"] = "user-data"})),
    '{"$lua":"table","entries":[["$lua","user-data"]]}')
end)

test("sparse mixed-key profiles retain holes zero keys false and exact key types", function()
  local profile = {[0] = {x = 0, y = -30, z = 0}, [2] = false, label = 0, [true] = "flag"}
  same(Codec.Copy(profile), profile)
  equal(Codec.Copy(profile)[1], nil)
  equal(Codec.Copy(profile)[2], false)
  assert(Codec.Encode(profile):find('"$lua":"table"', 1, true))
end)

test("decoder rejects malformed tags keys unicode numbers and executable text", function()
  for _, bytes in ipairs({
    '{"a":1,"a":2}', '{"$lua":false}', '{"$lua":"nil","extra":0}',
    '{"$lua":"number","value":"unknown"}',
    '{"$lua":"table","entries":{"named":[1,2]}}',
    '{"$lua":"table","entries":[[1,2],[1,3]]}',
    '{"$lua":"table","entries":[{"1":2,"2":3}]}',
    '{"$lua":"table","entries":[[1,{"$lua":"nil"}]]}',
    '"\\ud800"', '"\\udc00"', '"\\ud800\\u1234"',
    '01', '1.e2', '1e999', '1,2', '{"a":null}', 'os.execute("anything")',
  }) do
    raises(function() Codec.Decode(bytes) end, "P0 codec:")
  end
  raises(function() Codec.Decode('"\192\128"') end, "invalid UTF-8")
end)

test("codec rejects code graphs and bounds bytes records nesting and comparison", function()
  raises(function() Codec.Encode({callback = function() end}) end, "unsupported value")
  raises(function() Codec.Encode(setmetatable({}, {})) end, "metatables")
  local cyclic = {}
  cyclic.self = cyclic
  raises(function() Codec.Compare(cyclic, cyclic) end, "cyclic data")
  raises(function() Codec.Encode("long", {MaxBytes = 2}) end, "byte_limit")
  raises(function() Codec.Decode("[1,2]", {MaxItems = 2}) end, "item_limit")
  raises(function() Codec.Decode("[[1]]", {MaxDepth = 2}) end, "depth_limit")
  local bytes, reason = Codec.TryEncode("long", {MaxBytes = 2})
  equal(bytes, nil)
  equal(reason, "byte_limit")
  raises(function() Codec.Encode(1, false) end, "expected limit record")
  raises(function() P0.Run(compact(), environment, false) end, "invalid string RunId")
  local case = compact()
  local request = run(case).Requests[1]
  raises(function() P0.PrepareIdentity(case, request, environment, false) end, "expected record")
end)

test("locale-dependent formatting cannot silently produce a different identity", function()
  local originalFormat = string.format
  string.format = function(format, ...)
    local result = originalFormat(format, ...)
    if format == "%.17g" then
      result = result:gsub("%.", ",")
    end
    return result
  end
  local ok, failure = pcall(Codec.Encode, {value = 1.5})
  string.format = originalFormat
  assert(not ok and tostring(failure):find("locale-dependent", 1, true), tostring(failure))
  equal(Codec.Copy(1.5), 1.5)
end)

print(string.format("%d passed, %d failed (P0-I1; %s)", passed, failed, _VERSION))
if failed > 0 then
  os.exit(1)
end
