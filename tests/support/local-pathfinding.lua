-- P0 shared test driver; not a production class or a vessel/control adapter.
-- Public test functions return copied data. No private ASTAR state is restored.
local import = ...
if type(import) ~= "function" then
  import = dofile
end
local Codec = import("tests/support/local-pathfinding-codec.lua")
local Fixtures = import("tests/support/local-pathfinding-fixtures.lua")
local Transcript = import("tests/support/local-pathfinding-transcript.lua")
local P0 = {Codec = Codec, Fixtures = Fixtures, Transcript = Transcript}

-- Lua 5.1 cannot yield through pcall. The owned asynchronous adapter protects
-- each atomic operation instead and catches failures outside coroutine.resume.
local function protected(environment, callback)
  if environment.Yielding then
    return true, callback()
  end
  return pcall(callback)
end

local function operation(environment, name, callback, ...)
  if environment.Operation then
    return environment:Operation(name, callback, ...)
  end
  return callback(...)
end

local function cancelSearch(environment, search)
  return operation(environment, "cancel_search", function()
    return search:CancelSearch()
  end)
end

local function observe(environment, search, point)
  return operation(environment, "observe", function(position)
    return search:UpdateLocalProgress(position)
  end, point)
end

local function stepSearch(environment, search, nodes, seconds)
  return operation(environment, "step_search", function(maxNodes, maxSeconds)
    return search:StepSearch(maxNodes, maxSeconds)
  end, nodes, seconds)
end

local function validationOperation(environment, name, callback, job, ...)
  return operation(environment, name, function(...)
    return callback(job, ...)
  end, ...)
end

local function record(value, names, path)
  assert(type(value) == "table" and getmetatable(value) == nil, "P0: expected record " .. path)
  local allowed = {}
  for name in names:gmatch("%S+") do
    allowed[name] = true
  end
  for key in pairs(value) do
    assert(type(key) == "string" and allowed[key], "P0: unknown field " .. path .. "." .. tostring(key))
  end
end

local function finite(value, path, minimum, integer)
  assert(type(value) == "number" and math.abs(value) < math.huge
    and (minimum == nil or value >= minimum) and (not integer or value == math.floor(value)),
    "P0: invalid number " .. path)
end

local function text(value, path)
  assert(type(value) == "string" and #value > 0 and #value <= 1024, "P0: invalid string " .. path)
end

local function boolean(value, path)
  assert(type(value) == "boolean", "P0: expected boolean " .. path)
end

local function enum(value, names, path)
  for name in names:gmatch("%S+") do
    if value == name then
      return
    end
  end
  error("P0: invalid enum " .. path)
end

local function dense(value, cap, path)
  assert(type(value) == "table" and getmetatable(value) == nil, "P0: expected array " .. path)
  local count = 0
  for key in pairs(value) do
    assert(type(key) == "number" and key >= 1 and key % 1 == 0, "P0: invalid array key " .. path)
    count = count + 1
    assert(count <= cap, "P0: array_limit " .. path)
  end
  for index = 1, count do
    assert(rawget(value, index) ~= nil, "P0: sparse array " .. path)
  end
  return count
end

local function position(value, path)
  record(value, "x y z", path)
  for _, axis in ipairs({"x", "y", "z"}) do
    finite(value[axis], path .. "." .. axis)
  end
end

local function samePosition(a, b)
  return a.x == b.x and a.y == b.y and a.z == b.z
end

local function terrain(definition, path)
  record(definition, "Id Revision Depth Regions ErrorFunction", path)
  text(definition.Id, path .. ".Id")
  text(definition.Revision, path .. ".Revision")
  finite(definition.Depth, path .. ".Depth", 0)
  if definition.ErrorFunction ~= nil then
    enum(definition.ErrorFunction, "Surface Depth Profile", path)
  end
  dense(definition.Regions, 32, path .. ".Regions")
  for index, region in ipairs(definition.Regions) do
    local label = path .. ".Regions[" .. index .. "]"
    record(region, "XMin XMax ZMin ZMax Depth Land Missing", label)
    for _, field in ipairs({"XMin", "XMax", "ZMin", "ZMax"}) do
      finite(region[field], label .. "." .. field)
    end
    assert(region.XMin <= region.XMax and region.ZMin <= region.ZMax, "P0: reversed region " .. label)
    if region.Depth ~= nil then
      finite(region.Depth, label .. ".Depth", 0)
    end
    if region.Land ~= nil then
      boolean(region.Land, label .. ".Land")
    end
    if region.Missing ~= nil then
      boolean(region.Missing, label .. ".Missing")
    end
  end
end

local function budget(value, fields, path)
  record(value, fields, path)
  for field in fields:gmatch("%S+") do
    finite(value[field], path .. "." .. field, 0, true)
  end
end

local function heading(first, last)
  local dx, dz = last.x - first.x, last.z - first.z
  if dx == 0 and dz == 0 then
    return 0
  end
  return math.deg(math.atan2(dz, dx)) % 360
end

-- Resolve all explicit case data before constructing a planner or querying terrain.
-- Missing validation depth/width derive from Search; conflicting copies are errors.
function P0.ResolveCase(input)
  local case = Codec.Copy(input)
  record(case, "SchemaVersion CaseId Revision VariantId Experiment InitialState Environment Route Search Validation Pose Provenance Actions Execution Expected", "Case")
  assert(case.SchemaVersion == 1, "P0: unsupported SchemaVersion")
  for _, field in ipairs({"CaseId", "Revision", "VariantId"}) do
    text(case[field], field)
  end
  enum(case.Experiment, "request_parity virtual_follow fixed_pose_prepare", "Experiment")
  assert(case.InitialState == "cold", "P0: reconstruct warm state from cold public actions")
  local environment = case.Environment
  record(environment, "ReplayCapability Terrain LuaVersion SourceVerification SourceManifest SurfaceTypes", "Environment")
  enum(environment.ReplayCapability, "analytic native_capture", "Environment.ReplayCapability")
  assert(environment.LuaVersion == _VERSION, "P0: LuaVersion input_mismatch")
  assert(environment.SourceVerification == "unverified", "P0-I1: no trusted source verification adapter")
  dense(environment.SourceManifest, 32, "SourceManifest")
  for _, source in ipairs(environment.SourceManifest) do
    record(source, "Path SHA256", "SourceManifest entry")
    text(source.Path, "SourceManifest.Path")
    assert(type(source.SHA256) == "string" and #source.SHA256 == 64 and source.SHA256:match("^%x+$"),
      "P0: invalid SHA256")
  end
  if environment.ReplayCapability == "analytic" then
    assert(environment.SurfaceTypes == nil, "P0: analytic enums come from its fixture")
    terrain(environment.Terrain, "Environment.Terrain")
  else
    record(environment.Terrain, "Id Revision", "Environment.Terrain")
    text(environment.Terrain.Id, "Environment.Terrain.Id")
    text(environment.Terrain.Revision, "Environment.Terrain.Revision")
    record(environment.SurfaceTypes, "WATER SHALLOW_WATER", "Environment.SurfaceTypes")
    for _, field in ipairs({"WATER", "SHALLOW_WATER"}) do
      finite(environment.SurfaceTypes[field], "SurfaceTypes." .. field, 0, true)
    end
    assert(environment.SurfaceTypes.WATER ~= environment.SurfaceTypes.SHALLOW_WATER,
      "P0: native surface enums must differ")
    assert(case.Execution.Clock == "unavailable" and case.Execution.Debug == false,
      "P0: native capture requires count-driven work without drawing")
  end
  record(case.Route, "Start Goal OriginalTargetId", "Route")
  position(case.Route.Start, "Route.Start")
  position(case.Route.Goal, "Route.Goal")
  text(case.Route.OriginalTargetId, "Route.OriginalTargetId")
  local search = case.Search
  record(search, "Grid GridNeighboursOnly Window HeadingPolicy Depth Cost LearningLimit Progress", "Search")
  record(search.Grid, "Type Spacing MaxCells SurfaceTypes ZoneRestriction", "Search.Grid")
  enum(search.Grid.Type, "hexagonal rectangular", "Grid.Type")
  finite(search.Grid.Spacing, "Grid.Spacing", 1e-9)
  finite(search.Grid.MaxCells, "Grid.MaxCells", 1, true)
  assert(search.Grid.ZoneRestriction == "none", "P0-I1: zone restriction not implemented")
  local surfaces = {}
  assert(dense(search.Grid.SurfaceTypes, 2, "Grid.SurfaceTypes") > 0, "P0: empty surface types")
  for _, surface in ipairs(search.Grid.SurfaceTypes) do
    enum(surface, "WATER SHALLOW_WATER", "Grid.SurfaceTypes")
    assert(not surfaces[surface], "P0: duplicate surface type")
    surfaces[surface] = true
  end
  table.sort(search.Grid.SurfaceTypes)
  assert(search.GridNeighboursOnly == true, "P0: LOCAL requires grid neighbours")
  record(search.Window, "Ahead Width Behind", "Search.Window")
  finite(search.Window.Ahead, "Window.Ahead", 1e-9)
  finite(search.Window.Width, "Window.Width", 1e-9)
  finite(search.Window.Behind, "Window.Behind", 0)
  enum(search.HeadingPolicy, "towards_goal explicit", "Search.HeadingPolicy")
  record(search.Depth, "MinDepth CorridorWidth", "Search.Depth")
  finite(search.Depth.MinDepth, "Depth.MinDepth", 1e-9)
  finite(search.Depth.CorridorWidth, "Depth.CorridorWidth", 0)
  record(search.Cost, "Kind PreferredDepth Weight", "Search.Cost")
  assert(search.Cost.Kind == "depth", "P0-I1: depth cost required")
  finite(search.Cost.PreferredDepth, "Cost.PreferredDepth", search.Depth.MinDepth)
  finite(search.Cost.Weight, "Cost.Weight", 0)
  finite(search.LearningLimit, "LearningLimit", 0, true)
  record(search.Progress, "MinDistance HistorySize RepeatLimit", "Search.Progress")
  finite(search.Progress.MinDistance, "Progress.MinDistance", 1e-9)
  finite(search.Progress.HistorySize, "Progress.HistorySize", 4, true)
  finite(search.Progress.RepeatLimit, "Progress.RepeatLimit", 2, true)
  assert(search.Progress.HistorySize <= 256 and search.Progress.RepeatLimit < search.Progress.HistorySize,
    "P0: invalid progress bounds")
  record(case.Validation, "Geometry Connection Depth Maneuver", "Validation")
  record(case.Validation.Geometry, "MaxPoints", "Validation.Geometry")
  finite(case.Validation.Geometry.MaxPoints, "Geometry.MaxPoints", 1, true)
  record(case.Validation.Connection, "RuleSource CostUnits", "Validation.Connection")
  assert(case.Validation.Connection.RuleSource == "search"
    and case.Validation.Connection.CostUnits == "depth_weighted_meters", "P0: connection input_mismatch")
  local depth = case.Validation.Depth
  record(depth, "MinDepth CorridorWidth LongitudinalSpacing LateralSpacing MaxSectionLength MaxOffsets MaxProfilePoints MaxDirectPoints", "Validation.Depth")
  for _, field in ipairs({"MinDepth", "CorridorWidth"}) do
    if depth[field] == nil then
      depth[field] = search.Depth[field]
    end
    assert(depth[field] == search.Depth[field], "P0: validation input_mismatch " .. field)
  end
  for _, field in ipairs({"LongitudinalSpacing", "LateralSpacing", "MaxSectionLength"}) do
    finite(depth[field], "Validation.Depth." .. field, 1e-9)
  end
  for _, field in ipairs({"MaxOffsets", "MaxProfilePoints", "MaxDirectPoints"}) do
    finite(depth[field], "Validation.Depth." .. field, 1, true)
  end
  record(case.Validation.Maneuver, "Status", "Validation.Maneuver")
  assert(case.Validation.Maneuver.Status == "unverified", "P0-I1: maneuver preparation not implemented")
  record(case.Pose, "Position HeadingDeg ActualSpeedMps RequestedSpeedMps", "Pose")
  position(case.Pose.Position, "Pose.Position")
  finite(case.Pose.HeadingDeg, "Pose.HeadingDeg")
  case.Pose.HeadingDeg = case.Pose.HeadingDeg % 360
  for _, field in ipairs({"ActualSpeedMps", "RequestedSpeedMps"}) do
    if case.Pose[field] ~= nil then
      finite(case.Pose[field], "Pose." .. field, 0)
    end
  end
  if case.Experiment == "fixed_pose_prepare" then
    assert(samePosition(case.Pose.Position, case.Route.Start), "P0: pose input_mismatch")
  end
  record(case.Provenance, "Route Pose Terrain", "Provenance")
  for _, field in ipairs({"Route", "Pose", "Terrain"}) do
    enum(case.Provenance[field], "measured configured reconstructed unknown", "Provenance." .. field)
  end
  local execution = case.Execution
  record(execution, "Clock SliceNodes SliceSeconds MaxSlicesPerRequest MaxWorkItemsPerRequest MaxRequests MaxEvents MaxCandidates MaxPositionsPerCandidate MaxArtifactBytes Debug Connection Depth MaxValidationSlices Transcript", "Execution")
  execution.Transcript = Transcript.ResolveLimits(execution.Transcript)
  enum(execution.Clock, "synthetic unavailable", "Execution.Clock")
  finite(execution.SliceSeconds, "SliceSeconds", 1e-9)
  for _, field in ipairs({"SliceNodes", "MaxSlicesPerRequest", "MaxWorkItemsPerRequest",
    "MaxRequests", "MaxEvents", "MaxCandidates", "MaxPositionsPerCandidate",
    "MaxArtifactBytes", "MaxValidationSlices"}) do
    local minimum = field == "MaxSlicesPerRequest" or field == "MaxWorkItemsPerRequest"
      or field == "MaxRequests" or field == "MaxValidationSlices"
    finite(execution[field], "Execution." .. field, minimum and 0 or 1, true)
  end
  assert(execution.MaxRequests <= 200 and execution.MaxEvents >= 2 and execution.MaxEvents <= 10000
    and execution.MaxCandidates <= 8 and execution.MaxPositionsPerCandidate <= 10000
    and execution.MaxArtifactBytes <= 64 * 1024 * 1024, "P0: unsupported capture bounds")
  boolean(execution.Debug, "Execution.Debug")
  for _, field in ipairs({"Connection", "Depth"}) do
    record(execution[field], "Slice Total", "Execution." .. field)
    local fields = field == "Connection" and "MaxWorkUnits MaxEvaluatorCalls"
      or "MaxWorkUnits MaxPointChecks MaxProfileQueries"
    budget(execution[field].Slice, fields, field .. ".Slice")
    budget(execution[field].Total, fields, field .. ".Total")
  end
  dense(case.Actions, 10000, "Actions")
  for index, action in ipairs(case.Actions) do
    local path = "Actions[" .. index .. "]"
    enum(action.Kind, "observe start step cancel retarget invalidate_terrain", path .. ".Kind")
    if action.Kind == "observe" then
      record(action, "Kind Position Provenance", path)
      position(action.Position, path .. ".Position")
      enum(action.Provenance, "virtual measured configured reconstructed", path .. ".Provenance")
    elseif action.Kind == "start" or action.Kind == "retarget" then
      record(action, "Kind Start Goal Heading", path)
      position(action.Start, path .. ".Start")
      position(action.Goal, path .. ".Goal")
      if action.Heading == nil then
        assert(search.HeadingPolicy == "towards_goal", "P0: explicit heading required")
        action.Heading = heading(action.Start, action.Goal)
      else
        finite(action.Heading, path .. ".Heading")
        action.Heading = action.Heading % 360
      end
    elseif action.Kind == "step" then
      record(action, "Kind Stage MaxNodes MaxSeconds UntilComplete", path)
      if action.Stage == nil then
        action.Stage = "search"
      end
      assert(action.Stage == "search", "P0-I1: scripted steps are search-only")
      if action.MaxNodes == nil then
        action.MaxNodes = execution.SliceNodes
      end
      if action.MaxSeconds == nil then
        action.MaxSeconds = execution.SliceSeconds
      end
      if action.UntilComplete == nil then
        action.UntilComplete = true
      end
      finite(action.MaxNodes, path .. ".MaxNodes", 1, true)
      finite(action.MaxSeconds, path .. ".MaxSeconds", 1e-9)
      boolean(action.UntilComplete, path .. ".UntilComplete")
    elseif action.Kind == "cancel" then
      record(action, "Kind Reason", path)
      if action.Reason == nil then
        action.Reason = "test_cancel"
      end
      text(action.Reason, path .. ".Reason")
    else
      record(action, "Kind Terrain", path)
      assert(environment.ReplayCapability == "analytic", "P0: native terrain cannot be replaced by a fixture")
      terrain(action.Terrain, path .. ".Terrain")
    end
  end
  assert(case.Actions[1] and case.Actions[1].Kind == "observe", "P0: first action must observe an explicit position")
  if case.Experiment == "virtual_follow" then
    assert(#case.Actions == 1 and case.Actions[1].Provenance == "virtual"
      and samePosition(case.Actions[1].Position, case.Route.Start),
      "P0: virtual_follow takes one explicit initial virtual observation")
    assert(search.HeadingPolicy == "towards_goal", "P0: virtual_follow requires towards_goal")
  end
  record(case.Expected, "DriverStatus NativeStopReason VirtualGoalReached RequestCount DataIncomplete ProgressStatus WindowReused", "Expected")
  if case.Expected.DriverStatus ~= nil then
    enum(case.Expected.DriverStatus, "complete limited cancelled", "Expected.DriverStatus")
  end
  for _, field in ipairs({"NativeStopReason", "ProgressStatus"}) do
    if case.Expected[field] ~= nil then
      text(case.Expected[field], "Expected." .. field)
    end
  end
  for _, field in ipairs({"VirtualGoalReached", "DataIncomplete", "WindowReused"}) do
    if case.Expected[field] ~= nil then
      boolean(case.Expected[field], "Expected." .. field)
    end
  end
  if case.Expected.RequestCount ~= nil then
    finite(case.Expected.RequestCount, "Expected.RequestCount", 0, true)
  end
  return case
end

-- Shared public configuration for search and independently repriced probes.
-- The caller's operation boundary owns any terrain access during construction.
local function planner(case)
  local config = case.Search
  local search = ASTAR:New(config.Grid.Type == "hexagonal" and GRID.Type.HEXAGON or GRID.Type.RECTANGLE)
  local surfaces = {}
  for _, name in ipairs(config.Grid.SurfaceTypes) do
    surfaces[#surfaces + 1] = land.SurfaceType[name]
  end
  search:GetGrid():SetResolution(config.Grid.Spacing):SetMaxCells(config.Grid.MaxCells):SetValidSurfaceTypes(surfaces)
  -- StartLocalSearch enables grid adjacency when it creates the owned window.
  -- The setter requires a built grid and cannot be called on this cold instance.
  search:SetLocalWindow(config.Window.Ahead, config.Window.Width, config.Window.Behind)
  search:SetValidNeighbourDepth(config.Depth.MinDepth, config.Depth.CorridorWidth)
  search:SetCostDepth(config.Cost.PreferredDepth, config.Cost.Weight)
  search:SetLocalLearningLimit(config.LearningLimit)
  search:SetLocalProgress(config.Progress.MinDistance, config.Progress.HistorySize, config.Progress.RepeatLimit)
  return search
end

P0.CreatePlanner = planner

local function withEnvironment(environment, case, session, run)
  if environment.WithSession then
    return environment:WithSession(case, session, run)
  end
  assert(case.Environment.ReplayCapability == "analytic", "P0: native case requires an explicit adapter")
  local previousClock, previousTerrain, previousLand = os, environment.ActiveTerrain, land
  local ok, result = pcall(function()
    if session then
      assert(environment.FixtureLand == land, "P0: transcript binding requires the owned standalone fixture")
      local proxy = {SurfaceType = land.SurfaceType}
      for _, name in ipairs({"getSurfaceType", "getSurfaceHeightWithSeabed", "profile"}) do
        local live = land[name]
        proxy[name] = function(...)
          return session:Call("land." .. name, live, ...)
        end
      end
      setmetatable(proxy, {__index = function(_, name)
        return session:Call("land." .. tostring(name), nil)
      end})
      land = proxy
    end
    os = case.Execution.Clock == "synthetic" and {clock = function() return 0 end} or nil
    environment.ActiveTerrain = Fixtures.Terrain(case.Environment.Terrain)
    return run()
  end)
  land = previousLand
  environment.ActiveTerrain = previousTerrain
  os = previousClock
  if not ok then
    error(result, 0)
  end
  return result
end

local function terrainCalls(environment, session)
  return session and session:Counts() or Codec.Copy(environment.ActiveTerrain.Calls)
end

local function transcriptReason(session)
  local issue = session:Report().FirstIssue
  if issue.Kind == "capture_limit" then
    return "limited", "capture_limit"
  end
  return "error", issue.Verdict == "failed" and "terrain_replay_mismatch" or "terrain_replay_gap"
end

local function finishTranscript(session, complete, result, ending)
  if not session then
    return
  end
  result.TerrainTranscript = session:Finish(complete)
  result.ReplayCapability = session.Mode == "replay" and "recorded_exact"
    or result.ReplayCapability or "analytic"
  if result.TerrainTranscript.FirstIssue then
    if result.TerrainTranscript.FirstIssue.Kind ~= "capture_incomplete" or ending.CaptureComplete ~= false then
      ending.Status, ending.Reason = transcriptReason(session)
    end
    ending.CaptureComplete = false
    ending.Verdict = result.TerrainTranscript.Verdict
  end
end

local function nativeCopy(report, cap)
  local function withinLimit(array, limit)
    local count = 0
    for key in pairs(array) do
      assert(type(key) == "number" and key >= 1 and key % 1 == 0, "P0: invalid native array key")
      count = count + 1
      if count > limit then
        return false
      end
    end
    dense(array, limit, "native array")
    return true
  end
  if not withinLimit(report.Candidates, cap.MaxCandidates) then
    return nil, "candidates"
  end
  for _, candidate in ipairs(report.Candidates) do
    if not withinLimit(candidate.Positions, cap.MaxPositionsPerCandidate) then
      return nil, "positions"
    end
  end
  local result = {}
  for key, value in pairs(report) do
    if key ~= "Candidates" then
      result[key] = Codec.Copy(value)
    end
  end
  local count = #report.Candidates
  assert(count == report.CandidateCount, "P0: native candidate count mismatch")
  result.Candidates = {}
  for index, candidate in ipairs(report.Candidates) do
    local copy = {}
    for _, field in ipairs({"Positions", "Cost", "BaseScore", "LearnedPenalty", "Score",
      "Length", "RemainingDistance", "ReachesGoal", "Sector"}) do
      copy[field] = Codec.Copy(candidate[field])
    end
    result.Candidates[index] = copy
  end
  return result
end

local function identities(case)
  local actions = Codec.Copy(case.Actions)
  for _, action in ipairs(actions) do
    -- A complete count-driven step means "finish this request", independent of
    -- its cooperative slice size. Partial steps retain their exact schedule.
    if action.Kind == "step" and action.UntilComplete then
      action.MaxNodes, action.MaxSeconds = nil, nil
    end
  end
  return {
    Search = Codec.Encode({Route = case.Route, Search = case.Search}),
    Validation = Codec.Encode(case.Validation), Pose = Codec.Encode(case.Pose),
    Environment = Codec.Encode(case.Environment), Actions = Codec.Encode(actions),
  }
end

local function expectations(case, artifact)
  local request = artifact.Requests[#artifact.Requests]
  local native = request and request.Native or {}
  local observed = {DriverStatus = artifact.End.Status, NativeStopReason = native.StopReason,
    VirtualGoalReached = artifact.End.VirtualGoalReached, RequestCount = #artifact.Requests,
    DataIncomplete = native.DataIncomplete, ProgressStatus = native.Progress and native.Progress.Status,
    WindowReused = native.WindowReused}
  local checks = {}
  for field, expected in pairs(case.Expected) do
    checks[field] = {Passed = observed[field] == expected, Expected = expected, Observed = observed[field]}
  end
  local verdict = next(checks) and "passed" or "not_run"
  for _, check in pairs(checks) do
    if not check.Passed then
      verdict = "failed"
    end
  end
  if not artifact.End.CaptureComplete then
    verdict = "inconclusive"
  end
  artifact.End.Verdict, artifact.End.Checks = verdict, checks
end

-- Each invocation starts cold, replays explicit public actions and owns its reports.
-- Driver limits cancel native work while retaining its native cancellation reason.
local function runCase(input, environment, runId, session)
  local case = P0.ResolveCase(input)
  if runId == nil then
    runId = case.CaseId .. "/" .. case.VariantId
  end
  text(runId, "RunId")
  return withEnvironment(environment, case, session, function()
    local search = operation(environment, "planner", function()
      local instance = planner(case)
      if environment.Track then
        environment:Track("search", instance)
      end
      return instance
    end)
    local cap = case.Execution
    local artifact = {SchemaVersion = 1, RunId = runId, CaseId = case.CaseId,
      Revision = case.Revision, VariantId = case.VariantId, ResolvedCase = Codec.Copy(case),
      Identities = identities(case), SourceVerification = "unverified",
      ReplayCapability = case.Environment.ReplayCapability,
      Requests = {}, Events = {}, End = {Status = "complete", VirtualGoalReached = false},
      Timing = {CPUKind = cap.Clock, SimulationKind = "unavailable", WallKind = "unavailable"},
      Limitations = {"maneuver_not_implemented", "execution_not_validated", "source_unverified"}}
    local pending, windowMap, windowCount = nil, {}, 0
    local previousCalls = {Surface = 0, Depth = 0, Profile = 0}
    local halted = false
    local function totalCalls()
      local result = terrainCalls(environment, session)
      if not session then
        for field, count in pairs(result) do
          result[field] = previousCalls[field] + count
        end
      end
      return result
    end
    local function captureLimit(exhausted, native)
      artifact.End.Status, artifact.End.Reason = "limited", "capture_limit"
      artifact.End.CaptureComplete = false
      artifact.End.Exhausted = {exhausted}
      if native then
        artifact.End.UncapturedNative = {Status = native.Status, StopReason = native.StopReason,
          CandidateCount = native.CandidateCount}
      end
      cancelSearch(environment, search)
      halted, pending = true, nil
    end
    local function boundArtifact()
      if Codec.TryEncode(artifact, {MaxBytes = cap.MaxArtifactBytes}) then
        return
      end
      captureLimit("artifact_bytes")
      -- An incomplete capture retains a bounded header, not a truncated replay.
      artifact.ResolvedCase, artifact.Identities, artifact.Requests = nil, nil, {}
      artifact.End.RequestCount, artifact.End.Verdict, artifact.End.Checks = 0, "inconclusive", nil
      artifact.Events = {}
      assert(Codec.TryEncode(artifact, {MaxBytes = cap.MaxArtifactBytes}),
        "P0: MaxArtifactBytes cannot hold the mandatory run header")
    end
    local function event(kind, fields)
      assert(#artifact.Events < cap.MaxEvents, "P0: event capture_limit")
      fields = fields or {}
      fields.SchemaVersion, fields.RunId, fields.CaseId = 1, runId, case.CaseId
      fields.Revision, fields.VariantId = case.Revision, case.VariantId
      fields.EventSequence, fields.Kind = #artifact.Events + 1, kind
      artifact.Events[#artifact.Events + 1] = fields
    end
    event("BEGIN")
    boundArtifact()
    if halted then
      finishTranscript(session, false, artifact, artifact.End)
      boundArtifact()
      return artifact
    end
    local function capture(driverReason)
      if not pending then
        return
      end
      local native, exceeded = nativeCopy(search.LastSearchResult, cap)
      if not native then
        captureLimit(exceeded, search.LastSearchResult)
        return
      end
      local windowId = native.WindowID
      if windowId and not windowMap[windowId] then
        windowCount = windowCount + 1
        windowMap[windowId] = windowCount
      end
      pending.Native = native
      pending.NativeRequestID, pending.NativeWindowID = native.RequestID, windowId
      pending.LogicalWindowID = windowId and windowMap[windowId]
      pending.DriverReason = driverReason
      pending.SearchTerrainCalls = totalCalls()
      for field, count in pairs(pending.SearchTerrainCalls) do
        pending.SearchTerrainCalls[field] = count - pending.CallsBefore[field]
      end
      pending.CallsBefore = nil
      for index, candidate in ipairs(native.Candidates) do
        candidate.CandidateId = runId .. "/" .. pending.RequestIndex .. "/" .. index
        candidate.GeometryId = candidate.CandidateId .. "/raw"
      end
      if not Codec.TryEncode(pending, {MaxBytes = cap.MaxArtifactBytes}) then
        captureLimit("artifact_bytes", native)
        return
      end
      artifact.Requests[#artifact.Requests + 1] = pending
      event("REQUEST", {RequestIndex = pending.RequestIndex, NativeStatus = native.Status,
        NativeStopReason = native.StopReason, DriverReason = driverReason})
      pending = nil
      if session then
        session:Close()
      end
      boundArtifact()
      if halted then
        return
      end
      if cap.Debug then
        -- Debug is a consumer of copied positions, outside the search stage.
        for _, candidate in ipairs(Codec.Copy(native.Candidates)) do
          for index = 2, #candidate.Positions do
            trigger.action.lineToAll(-1, 0, candidate.Positions[index - 1], candidate.Positions[index])
          end
        end
      end
    end
    local function stop(status, reason, exhausted)
      cancelSearch(environment, search)
      capture(reason)
      if artifact.End.CaptureComplete == false then
        return
      end
      artifact.End.Status, artifact.End.Reason = status, reason
      artifact.End.Exhausted = exhausted
      halted = true
    end
    local function start(action)
      if pending then
        cancelSearch(environment, search)
        capture(action.Kind == "retarget" and "retarget" or "request_replaced")
        if halted then
          return
        end
      end
      if #artifact.Requests >= cap.MaxRequests then
        stop("limited", "driver_request_limit", {"request"})
        return
      end
      if #artifact.Events + 2 > cap.MaxEvents then
        stop("limited", "capture_limit", {"events"})
        artifact.End.CaptureComplete = false
        return
      end
      if session then
        session:Begin("search", case.Experiment, #artifact.Requests + 1, 0)
      end
      operation(environment, "start_search", function(first, goal, bearing)
        return search:StartLocalSearch(first, goal, bearing)
      end, action.Start, action.Goal, action.Heading)
      pending = {SchemaVersion = 1, RunId = runId, CaseId = case.CaseId, Revision = case.Revision,
        VariantId = case.VariantId, RequestIndex = #artifact.Requests + 1,
        RequestId = runId .. "/request/" .. (#artifact.Requests + 1),
        Input = {Start = Codec.Copy(action.Start), Goal = Codec.Copy(action.Goal), Heading = action.Heading},
        Slices = 0, CallsBefore = totalCalls()}
      artifact.End.Status, artifact.End.Reason = "complete", nil
    end
    local function step(action)
      if not pending then
        return
      end
      repeat
        -- Completion on the last admitted step takes precedence over driver caps.
        local report = search.LastSearchResult
        if report.Status ~= "running" then
          capture()
          return
        end
        local exhausted = {}
        if report.WorkItems >= cap.MaxWorkItemsPerRequest then
          exhausted[#exhausted + 1] = "work"
        end
        if pending.Slices >= cap.MaxSlicesPerRequest then
          exhausted[#exhausted + 1] = "slice"
        end
        if #exhausted > 0 then
          stop("limited", exhausted[1] == "work" and "driver_request_work_limit" or "driver_slice_limit", exhausted)
          return
        end
        local admitted = math.min(action.MaxNodes, cap.MaxWorkItemsPerRequest - report.WorkItems)
        local _, nextReport = stepSearch(environment, search, admitted, action.MaxSeconds)
        pending.Slices = pending.Slices + 1
        if nextReport.Status ~= "running" then
          capture()
          return
        end
      until not action.UntilComplete
    end
    local function apply(action)
      if action.Kind == "observe" then
        observe(environment, search, action.Position)
      elseif action.Kind == "start" or action.Kind == "retarget" then
        start(action)
      elseif action.Kind == "step" then
        step(action)
      elseif action.Kind == "cancel" then
        cancelSearch(environment, search)
        capture(action.Reason)
        if artifact.End.CaptureComplete ~= false then
          artifact.End.Status, artifact.End.Reason = "cancelled", action.Reason
        end
      else
        previousCalls = totalCalls()
        environment.ActiveTerrain = Fixtures.Terrain(action.Terrain)
        operation(environment, "invalidate_terrain", function()
          return search:InvalidateLocalCache()
        end)
        if pending then
          stepSearch(environment, search, 1, cap.SliceSeconds)
          pending.Slices = pending.Slices + 1
          capture("invalidate_terrain")
        end
      end
    end
    local ok, reason = protected(environment, function()
      if case.Experiment == "virtual_follow" then
        local current = Codec.Copy(case.Route.Start)
        apply(case.Actions[1])
        while not halted do
          start({Kind = "start", Start = current, Goal = case.Route.Goal,
            Heading = heading(current, case.Route.Goal)})
          if halted then
            break
          end
          step({MaxNodes = cap.SliceNodes, MaxSeconds = cap.SliceSeconds, UntilComplete = true})
          if halted then
            break
          end
          local request = artifact.Requests[#artifact.Requests]
          local candidate = request.Native.Candidates[1]
          if not candidate then
            artifact.End.Reason = request.Native.StopReason
            break
          end
          for index = 2, #candidate.Positions do
            observe(environment, search, candidate.Positions[index])
          end
          current = Codec.Copy(candidate.Positions[#candidate.Positions])
          if candidate.ReachesGoal then
            artifact.End.VirtualGoalReached = samePosition(current, case.Route.Goal)
            artifact.End.VirtualPosition = current
            break
          end
        end
      else
        for _, action in ipairs(case.Actions) do
          if halted then
            break
          end
          apply(action)
        end
        if pending then
          stop("cancelled", "action_sequence_ended")
        end
      end
    end)
    if not ok then
      cancelSearch(environment, search)
      if not session or not session:IsAbort(reason) then
        error(reason, 0)
      end
      capture("terrain_transcript_abort")
      artifact.End.Status, artifact.End.Reason = transcriptReason(session)
      artifact.End.CaptureComplete = false
    end
    if artifact.End.CaptureComplete == nil then
      artifact.End.CaptureComplete = true
    end
    artifact.End.RequestCount = #artifact.Requests
    artifact.End.SearchTerrainCalls = totalCalls()
    expectations(case, artifact)
    finishTranscript(session, artifact.End.CaptureComplete, artifact, artifact.End)
    event("END", {Status = artifact.End.Status, Verdict = artifact.End.Verdict, Reason = artifact.End.Reason})
    boundArtifact()
    return artifact
  end)
end

function P0.Run(input, environment, runId)
  return runCase(input, environment, runId)
end

-- Stable IDs are mapped through action order; clocks/slices remain diagnostics.
local function semantics(artifact)
  local result = {SearchIdentity = artifact.Identities.Search, ActionsIdentity = artifact.Identities.Actions,
    EnvironmentIdentity = artifact.Identities.Environment,
    Requests = {}, End = {Status = artifact.End.Status, Reason = artifact.End.Reason,
      VirtualGoalReached = artifact.End.VirtualGoalReached, CaptureComplete = artifact.End.CaptureComplete}}
  for index, request in ipairs(artifact.Requests) do
    local native = Codec.Copy(request.Native)
    native.RequestID, native.WindowID, native.SearchCPUSeconds = nil, nil, nil
    for _, attempt in ipairs(native.Attempts or {}) do
      attempt.CPUSeconds = nil
    end
    for _, candidate in ipairs(native.Candidates) do
      candidate.CandidateId, candidate.GeometryId = nil, nil
    end
    result.Requests[index] = {Input = Codec.Copy(request.Input), LogicalWindowID = request.LogicalWindowID,
      DriverReason = request.DriverReason, Native = native}
  end
  return result
end

function P0.CompareRuns(first, second, requireVerifiedSources)
  if not first.End.CaptureComplete or not second.End.CaptureComplete then
    return {Kind = "analytic_semantic", Verdict = "inconclusive", Reason = "capture_incomplete",
      SourceVerified = false}
  end
  local result = Codec.Compare(semantics(first), semantics(second))
  result.Kind = "analytic_semantic"
  result.SourceVerified = false
  local function diagnostics(artifact)
    local requests = {}
    for index, request in ipairs(artifact.Requests) do
      requests[index] = {Slices = request.Slices, TerrainCalls = request.SearchTerrainCalls}
    end
    return {Timing = artifact.Timing, Requests = requests, Pose = artifact.ResolvedCase.Pose,
      Validation = artifact.ResolvedCase.Validation}
  end
  result.DiagnosticDifferences = Codec.Compare(diagnostics(first), diagnostics(second)).Difference
  if requireVerifiedSources and result.Verdict == "passed" then
    result.Verdict, result.Reason = "inconclusive", "source_unverified"
  end
  return result
end

-- Independent snapshots isolate consumer ownership from independent search parity.
function P0.FanoutRequest(request)
  return Codec.Copy(request), Codec.Copy(request)
end

-- Captured configuration is data, never code. Resolve before any terrain access.
function P0.DecodeCase(bytes)
  return P0.ResolveCase(Codec.Decode(bytes))
end

local function horizontalMatch(first, last)
  return first.x == last.x and first.z == last.z
end

local function context(value, path)
  assert(type(value) == "string" and #value > 0 and #value <= 128
    or type(value) == "number" and value == math.floor(value) and math.abs(value) < math.huge,
    "P0: invalid context " .. path)
end

local function validateCandidate(candidate, cap)
  record(candidate, "Positions Cost BaseScore LearnedPenalty Score Length RemainingDistance ReachesGoal Sector CandidateId GeometryId",
    "Candidate")
  assert(dense(candidate.Positions, cap.MaxPositionsPerCandidate, "Candidate.Positions") > 0,
    "P0: empty candidate")
  for _, point in ipairs(candidate.Positions) do
    position(point, "Candidate.Position")
  end
  for _, field in ipairs({"Cost", "BaseScore", "LearnedPenalty", "Score", "Length", "RemainingDistance"}) do
    finite(candidate[field], "Candidate." .. field, 0)
  end
  boolean(candidate.ReachesGoal, "Candidate.ReachesGoal")
  for _, field in ipairs({"CandidateId", "GeometryId"}) do
    text(candidate[field], "Candidate." .. field)
  end
  if candidate.Sector ~= nil then
    finite(candidate.Sector, "Candidate.Sector", 1, true)
    assert(candidate.Sector <= 8, "P0: invalid candidate sector")
  end
end

-- Identity geometry only: fresh rule/cost and dense depth checks, no maneuvers,
-- candidate selection, route submission or observations at future anchors.
-- Control belongs to this standalone fixture; it models cancellation/staleness
-- without timers. Returned records, pose and raw candidates are independent.
local function preparationControl(control)
  if control == nil then
    control = {}
  end
  control = Codec.Copy(control)
  record(control, "ContextId CurrentContextId CancelAfterSlices ConsumerId", "Preparation.Control")
  if control.ConsumerId == nil then
    control.ConsumerId = "identity"
  end
  text(control.ConsumerId, "ConsumerId")
  assert(#control.ConsumerId <= 64, "P0: ConsumerId too long")
  if control.ContextId == nil then
    control.ContextId = "identity"
  end
  if control.CurrentContextId == nil then
    control.CurrentContextId = control.ContextId
  end
  context(control.ContextId, "ContextId")
  context(control.CurrentContextId, "CurrentContextId")
  if control.CancelAfterSlices ~= nil then
    finite(control.CancelAfterSlices, "CancelAfterSlices", 0, true)
  end
  return control
end

local function prepareIdentity(input, request, environment, control, session)
  local case = P0.ResolveCase(input)
  request = Codec.Copy(request)
  control = preparationControl(control)
  record(request.Input, "Start Goal Heading", "Request.Input")
  position(request.Input.Start, "Request.Start")
  position(request.Input.Goal, "Request.Goal")
  dense(request.Native.Candidates, case.Execution.MaxCandidates, "Request.Candidates")
  for _, candidate in ipairs(request.Native.Candidates) do
    validateCandidate(candidate, case.Execution)
  end
  text(request.RunId, "Request.RunId")
  finite(request.RequestIndex, "RequestIndex", 1, true)

  return withEnvironment(environment, case, session, function()
    local fresh = operation(environment, "planner", function()
      local instance = planner(case)
      if environment.Track then
        environment:Track("search", instance)
      end
      return instance
    end)
    local result = {SchemaVersion = 1, RunId = request.RunId, CaseId = case.CaseId,
      Revision = case.Revision, VariantId = case.VariantId, RequestIndex = request.RequestIndex,
      ContextId = control.ContextId, Pose = Codec.Copy(case.Pose), Identities = identities(case),
      Candidates = {}, ExecutionValidated = false, Transformation = "identity",
      Status = "not_run", Slices = 0, CaptureComplete = true,
      ReplayCapability = case.Environment.ReplayCapability,
      TerrainCalls = {Surface = 0, Depth = 0, Profile = 0},
      Timing = {CPUKind = case.Execution.Clock, SimulationKind = "unavailable", WallKind = "unavailable"}}
    local activeJob, stopReason
    local function boundResult()
      if not result.CaptureComplete then
        return false
      end
      if Codec.TryEncode(result, {MaxBytes = case.Execution.MaxArtifactBytes}) then
        return true
      end
      result.CaptureComplete, result.Status, result.Reason = false, "limited", "capture_limit"
      result.Identities, result.Pose = nil, nil
      result.Candidates = {}
      for index, raw in ipairs(request.Native.Candidates) do
        result.Candidates[index] = {CandidateIndex = index, CandidateId = raw.CandidateId,
          Status = "not_run", Reason = "capture_limit", ExecutionValidated = false}
      end
      assert(Codec.TryEncode(result, {MaxBytes = case.Execution.MaxArtifactBytes}),
        "P0: MaxArtifactBytes cannot hold the mandatory preparation header")
      return false
    end
    if not boundResult() then
      finishTranscript(session, false, result, result)
      assert(Codec.TryEncode(result, {MaxBytes = case.Execution.MaxArtifactBytes}),
        "P0: MaxArtifactBytes cannot hold the mandatory transcript preparation header")
      return result
    end
    local function validate(geometry, evaluator, kind, candidateContext, candidateIndex)
      local limits = Codec.Copy(case.Execution[kind].Total)
      limits.ContextId = candidateContext
      local job, report
      local callsBefore = terrainCalls(environment, session)
      local stage = {ContextId = candidateContext, Slices = 0}
      local ok, failure = protected(environment, function()
        if session then
          session:Begin(kind == "Connection" and "connection" or "depth", control.ConsumerId,
            request.RequestIndex, candidateIndex)
        end
        job, report = operation(environment, "start_validation", function()
          local created, initial = PATHLINE.StartValidation(geometry, evaluator, limits)
          if environment.Track then
            environment:Track("validation", created)
          end
          return created, initial
        end, limits)
        activeJob = job
        while report.Status == "running" do
          if control.CurrentContextId ~= control.ContextId then
            report = validationOperation(environment, "step_validation", PATHLINE.StepValidation,
              job, case.Execution[kind].Slice, "obsolete-context")
            stage.Status, stage.Reason = "cancelled", "context_changed"
          elseif control.CancelAfterSlices ~= nil and result.Slices >= control.CancelAfterSlices then
            report = validationOperation(environment, "cancel_validation", PATHLINE.CancelValidation,
              job, "test_cancel")
            stage.Status, stage.Reason = "cancelled", "test_cancel"
          elseif result.Slices >= case.Execution.MaxValidationSlices then
            report = validationOperation(environment, "cancel_validation", PATHLINE.CancelValidation,
              job, "driver_validation_slice_limit")
            stage.Status, stage.Reason = "limited", "driver_validation_slice_limit"
          else
            report = validationOperation(environment, "step_validation", PATHLINE.StepValidation,
              job, case.Execution[kind].Slice, candidateContext)
            result.Slices = result.Slices + 1
            stage.Slices = stage.Slices + 1
          end
        end
        if session then
          session:Close()
        end
      end)
      if not ok then
        if not session or not session:IsAbort(failure) then
          error(failure, 0)
        end
        if job then
          report = validationOperation(environment, "cancel_validation", PATHLINE.CancelValidation,
            job, "terrain_transcript_abort")
        end
        stage.Status, stage.Reason = transcriptReason(session)
      end
      activeJob = nil
      stage.Native = report
      stage.Status = stage.Status or report.Status
      stage.Reason = stage.Reason or report.Reason
      stage.TerrainCalls = {}
      for field, count in pairs(terrainCalls(environment, session)) do
        stage.TerrainCalls[field] = count - callsBefore[field]
      end
      if stage.Status == "limited" or stage.Status == "cancelled" or stage.Status == "error" then
        stopReason = stage.Reason
      end
      return stage
    end
    local ok, failure = protected(environment, function()
      for index, raw in ipairs(request.Native.Candidates) do
        local candidateContext = Codec.Encode(control.ContextId) .. "/" .. request.RequestIndex .. "/" .. index
        local candidate = {SchemaVersion = 1, RunId = request.RunId, CaseId = case.CaseId,
          Revision = case.Revision, VariantId = case.VariantId, RequestIndex = request.RequestIndex,
          CandidateIndex = index, CandidateId = raw.CandidateId, ContextId = candidateContext,
          Raw = Codec.Copy(raw), PreparedGeometryId = raw.GeometryId .. "/identity",
          Selected = false, Status = "not_run", ExecutionValidated = false,
          Maneuver = {Status = "unverified", Reason = "maneuver_not_implemented"}}
        result.Candidates[index] = candidate
        if stopReason then
          candidate.Reason = stopReason
        else
          if not boundResult() then
            break
          end
          local geometry, reason, detail = operation(environment, "geometry", PATHLINE.CreateGeometry,
            raw.Positions, case.Validation.Geometry)
          local endpointsMatch = horizontalMatch(raw.Positions[1], request.Input.Start)
            and horizontalMatch(raw.Positions[1], case.Pose.Position)
            and (not raw.ReachesGoal or horizontalMatch(raw.Positions[#raw.Positions], request.Input.Goal))
          if not geometry or not endpointsMatch then
            if reason == "point_limit" or reason == "numeric_range" then
              candidate.Status = "limited"
            else
              candidate.Status = "rejected"
            end
            candidate.Reason = reason or "endpoint_mismatch"
            candidate.Geometry = {Status = candidate.Status == "limited" and "limited" or "blocked",
              Reason = candidate.Reason, Detail = detail}
          else
            candidate.Geometry = {Status = "clear", GeometryId = candidate.PreparedGeometryId,
              Positions = PATHLINE.GetGeometryPositions(geometry)}
            local evidence = {DepthConfiguration = Codec.Copy(case.Search.Depth), EvaluatorCalls = 0}
            local evaluator = PATHLINE.CreateConnectionEvaluator(function(first, last)
              local valid, cost, native = fresh:EvaluateConnection(first, last)
              evidence.EvaluatorCalls = evidence.EvaluatorCalls + 1
              if not valid and evidence.FirstFailure == nil then
                evidence.FirstFailure = Codec.Copy(native)
              end
              local mapped = {Status = native.Status, Reason = native.Reason}
              if valid then
                mapped.Cost = cost
              end
              local depth = native.Depth
              if depth then
                mapped.Evidence = {Depth = depth.Depth, SurfaceType = depth.SurfaceType,
                  Cause = depth.Cause, Source = "ASTAR.EvaluateConnection"}
                if depth.Point then
                  mapped.Evidence.Position = {x = depth.Point.x, z = depth.Point.z}
                end
              end
              return mapped
            end, {CostUnits = case.Validation.Connection.CostUnits})
            candidate.Connection = validate(geometry, evaluator, "Connection", candidateContext .. "/connection", index)
            candidate.Connection.Evidence = evidence
            if candidate.Connection.Status == "clear" and boundResult() then
              local depthEvaluator, depthReason, depthDetail = PATHLINE.CreateDepthEvaluator(case.Validation.Depth)
              if depthEvaluator then
                candidate.Depth = validate(geometry, depthEvaluator, "Depth", candidateContext .. "/depth", index)
              else
                candidate.Depth = {Status = "limited", Reason = depthReason, Detail = depthDetail}
              end
              if candidate.Depth.Status == "clear" then
                candidate.Status = "unverified"
                candidate.Reason = "maneuver_not_implemented"
                candidate.PreparedCost = candidate.Connection.Native.TotalCost
                candidate.PreparedScore = raw.Score + candidate.PreparedCost - raw.Cost
                candidate.CostUnits = case.Validation.Connection.CostUnits
              end
            end
            local failed = candidate.Connection.Status ~= "clear" and candidate.Connection or candidate.Depth
            if failed and failed.Status ~= "clear" then
              candidate.Status = failed.Status == "blocked" and "rejected" or failed.Status
              candidate.Reason = failed.Reason
            end
          end
        end
        if not boundResult() then
          break
        end
      end
    end)
    if not ok then
      if activeJob then
        validationOperation(environment, "cancel_validation", PATHLINE.CancelValidation,
          activeJob, "evaluation_error")
      end
      error(failure, 0)
    end
    if not result.CaptureComplete then
      -- No further candidate/stage may be admitted after capture becomes incomplete.
      result.TerrainCalls = terrainCalls(environment, session)
      finishTranscript(session, false, result, result)
      assert(Codec.TryEncode(result, {MaxBytes = case.Execution.MaxArtifactBytes}),
        "P0: MaxArtifactBytes cannot hold the mandatory preparation header")
      return result
    elseif stopReason then
      local last
      for _, candidate in ipairs(result.Candidates) do
        if candidate.Status ~= "not_run" then
          last = candidate
        end
      end
      result.Status, result.Reason = last.Status, stopReason
    else
      -- Candidate order is preserved; this is a route-check summary, not selection.
      local statuses = {}
      for _, candidate in ipairs(result.Candidates) do
        statuses[candidate.Status] = true
      end
      if statuses.unverified then
        result.Status, result.Reason = "unverified", "maneuver_not_implemented"
      elseif statuses.limited then
        result.Status, result.Reason = "limited", "candidate_validation_limited"
      elseif statuses.unavailable then
        result.Status, result.Reason = "unavailable", "candidate_data_unavailable"
      elseif statuses.rejected then
        result.Status, result.Reason = "rejected", "no_candidate_passed_route_checks"
      end
    end
    result.TerrainCalls = terrainCalls(environment, session)
    finishTranscript(session, result.CaptureComplete, result, result)
    boundResult()
    return result
  end)
end

function P0.PrepareIdentity(input, request, environment, control)
  return prepareIdentity(input, request, environment, control)
end

local function transcriptManifest(case, request, control)
  local input = {Case = case}
  if request then
    input.Request = {Input = request.Input, RequestIndex = request.RequestIndex,
      Candidates = Codec.Copy(request.Native.Candidates)}
    for _, candidate in ipairs(input.Request.Candidates) do
      candidate.CandidateId, candidate.GeometryId = nil, nil
    end
    input.Control = control
  end
  return {InputIdentity = Codec.Encode(input), LuaVersion = case.Environment.LuaVersion,
    SourceVerification = "unverified", SourceManifest = Codec.Copy(case.Environment.SourceManifest)}
end

-- Transport artifacts are separate from search/preparation result limits.
-- Capturing and replaying use the same resolved case and exact slice schedule.
-- Native exceptions still propagate after session/environment cleanup.
local function recorded(case, request, environment, control, runId, captured)
  case = P0.ResolveCase(case)
  if request then
    control = preparationControl(control)
  end
  local input = transcriptManifest(case, request, control)
  local session
  if captured ~= nil then
    session = Transcript.NewReplay(input, captured, case.Execution.Transcript)
  else
    session = Transcript.NewCapture(input, case.Execution.Transcript)
  end
  if environment.RegisterSession then
    environment:RegisterSession(session)
  end
  local ok, result = protected(environment, function()
    if request then
      return prepareIdentity(case, request, environment, control, session)
    end
    return runCase(case, environment, runId, session)
  end)
  if not ok then
    session:Finish(false)
    error(result, 0)
  end
  return result, session:Export()
end

function P0.RecordRun(input, environment, runId)
  return recorded(input, nil, environment, nil, runId)
end

function P0.ReplayRun(input, environment, captured, runId)
  assert(captured ~= nil, "P0: replay requires a transcript")
  return recorded(input, nil, environment, nil, runId, captured)
end

function P0.RecordPreparation(input, request, environment, control)
  assert(type(request) == "table", "P0: preparation requires a request")
  return recorded(input, request, environment, control)
end

function P0.ReplayPreparation(input, request, environment, captured, control)
  assert(type(request) == "table", "P0: preparation requires a request")
  assert(captured ~= nil, "P0: replay requires a transcript")
  return recorded(input, request, environment, control, nil, captured)
end

return P0
