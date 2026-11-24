-- P0-I3 isolated DCS entry. Loaded by the byte-preserving test loader only.
-- File capabilities are required; this helper never changes DCS sanitization.
local import = assert(..., "P0 DCS: test loader required")
local P0 = import("tests/support/local-pathfinding.lua")
local Native = import("tests/support/local-pathfinding-native.lua")
local Codec = P0.Codec
local Runner = {}

function Runner.Start(context)
  assert(_VERSION == "Lua 5.1", "P0 DCS: Lua 5.1 required")
  assert(env and type(env.info) == "function" and timer and type(timer.getTime) == "function",
    "P0 DCS: logging/timer unavailable")
  assert(env.mission and env.mission.theatre == "PersianGulf", "P0 DCS: setup_required PersianGulf mission")
  local reference = context.Reference
  local guard = context:Checkpoint()
  local function log(message)
    guard()
    env.info("[P0 DCS CAPTURE] " .. reference.RunId .. " " .. reference.BuildToken .. " " .. message)
  end
  local members = {}
  local function write(path, data, maximum)
    local bytes = Codec.Encode(data, {MaxBytes = maximum or 4 * 1024 * 1024, MaxItems = 32000000})
    members[#members + 1] = context:Write(path, bytes, maximum or 4 * 1024 * 1024)
  end
  -- Capability failure occurs before case setup or any terrain query.
  context:Write("capability.txt", "P0-I3 binary write/close/rename succeeded\n", 1024)
  local cases, zones = Native.ResolveCases(function(name) return ZONE:FindByName(name) end,
    land.SurfaceType, reference.TestedSources)
  write("inputs.json", {SchemaVersion = 1, RunId = reference.RunId, BuildToken = reference.BuildToken,
    Cases = cases, Zones = zones, Environment = {LuaVersion = _VERSION, Theatre = env.mission.theatre,
      DCSBuild = "unknown", TerrainRevision = "unknown", ClockPolicy = "count_driven",
      BootstrapTrust = "host_prepared_entry_and_DCS_executable"}})
  write("load-events.json", {SchemaVersion = 1, RunId = reference.RunId, BuildToken = reference.BuildToken,
    Events = context.Events, BootstrapComplete = context.Completed})
  local environment = Native.NewEnvironment({Guard = guard})
  local stored, publishedSessions = {}, {}
  environment.OnCase = function(index, item)
    local summary = {}
    for key, value in pairs(item) do
      if key ~= "SearchTape" and key ~= "PreparationTape" and key ~= "ProbeTape" then
        summary[key] = Codec.Copy(value)
      end
    end
    for _, key in ipairs({"SearchTape", "PreparationTape", "ProbeTape"}) do
      if item[key] then
        local path = "tapes/" .. index .. "-" .. key .. ".json"
        write(path, item[key], 8 * 1024 * 1024)
        summary[key] = {Path = path}
      end
    end
    stored[index] = summary
    for _, session in ipairs(environment.Sessions) do
      publishedSessions[session] = true
    end
    log("END case=" .. item.Case.CaseId)
  end
  local clock = os and type(os.clock) == "function" and os.clock or nil
  local job = Native.NewJob(environment, function()
    return Native.RunCases(cases, environment)
  end, {SimulationTime = timer.getTime, CPUClock = clock, MaxSimulationSeconds = 1200})
  log("LOAD COMPLETE schema=1 source=pending_host_verification")
  log("BEGIN schema=1")
  job:StartTimer(timer, function(finished)
    -- Bindings are already restored; finalization never runs inside a proxy.
    local stable = pcall(guard)
    local complete = finished.State == "complete" and stable and environment.BindingsStable
      and environment.Cleanup.Restored and #environment.Cleanup.Errors == 0 and #stored == 3
    local firstIssue = environment.FirstIssue
    for _, session in ipairs(environment.Sessions) do
      complete = complete and session:Export().Complete == true and session:Report().FirstIssue == nil
      firstIssue = firstIssue or session:Report().FirstIssue
    end
    -- Preserve unfinished/error scopes too, without turning them into replay input.
    if not complete then
      for index, session in ipairs(environment.Sessions) do
        if not publishedSessions[session] then
          write("tapes/failure-" .. index .. ".json", session:Export(), 8 * 1024 * 1024)
        end
      end
    end
    write("actions.json", {SchemaVersion = 1, RunId = reference.RunId,
      BuildToken = reference.BuildToken, Actions = environment.Journal})
    local assertions = finished.Result and Native.Assertions(finished.Result)
    write("results.json", {SchemaVersion = 1, RunId = reference.RunId, BuildToken = reference.BuildToken,
      Cases = stored, Assertions = assertions, Timing = finished.Timing,
      Slices = finished.Slices, FirstIssue = firstIssue})
    -- Completion is the last published member. Failure leaves no success marker.
    local completion = {SchemaVersion = 1, RunId = reference.RunId, BuildToken = reference.BuildToken,
      Complete = complete == true, State = finished.State, SourceVerification = "pending_host_verification",
      BindingsStable = stable and environment.BindingsStable or false, Cleanup = environment.Cleanup,
      Members = members, Failure = finished.Failure and Native.BoundedText(finished.Failure),
      Reason = finished.Reason, FirstIssue = firstIssue, Assertions = assertions,
      MeasurementFailure = finished.MeasurementFailure}
    context:Write("completion.json", Codec.Encode(completion, {MaxBytes = 4 * 1024 * 1024}), 4 * 1024 * 1024)
    if complete then
      log("CAPTURE COMPLETE source=pending_host_verification")
    else
      -- A foreign binding prevents normal log(), so do not clobber it to log.
      env.info("[P0 DCS CAPTURE] " .. reference.RunId .. " " .. reference.BuildToken .. " INCOMPLETE")
    end
  end, 0.1)
  return job
end

return Runner
