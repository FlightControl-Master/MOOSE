-- P0-I3 test-only native binding and cooperative work. Never controls a vessel.
local import = ...
if type(import) ~= "function" then
  import = dofile
end
local P0 = import("tests/support/local-pathfinding.lua")
local Codec, Transcript = P0.Codec, P0.Transcript
local Native = {}
local Environment = {}
Environment.__index = Environment
local Job = {}
Job.__index = Job

local function boundedText(value)
  if type(value) == "string" then
    -- Error excerpts are diagnostics, not replay substitutes.
    local excerpt = value:sub(1, 512):gsub("[\128-\255]+$", "")
    if not Codec.TryEncode(excerpt, {MaxBytes = 4096}) then
      return "<non-UTF8 string>"
    end
    return excerpt
  end
  return "<" .. type(value) .. ">"
end

-- Bind only the atomic operation; restore before error propagation or yielding.
function Environment:Scoped(callback, ...)
  local globals = self.Globals
  assert(globals.land == self.NativeLand and globals.os == self.NativeOS,
    "P0 native: foreign terrain/clock ownership")
  assert(self.NativeLand.SurfaceType == self.NativeSurfaceTypes
    and Codec.Compare(self.SurfaceTypes, self.NativeSurfaceTypes).Verdict == "passed",
    "P0 native: surface enum ownership changed")
  local session = assert(self.Session, "P0 native: missing session")
  local proxy = {SurfaceType = self.NativeLand.SurfaceType}
  for _, name in ipairs({"getSurfaceType", "getSurfaceHeightWithSeabed", "profile"}) do
    local original = self.Functions[name]
    proxy[name] = function(...)
      return session:Call("land." .. name, original, ...)
    end
  end
  setmetatable(proxy, {__index = function(_, name)
    return session:Call("land." .. tostring(name), nil)
  end})
  local clock = {}
  for key, value in pairs(self.NativeOS or {}) do
    if key ~= "clock" then
      clock[key] = value
    end
  end
  globals.land, globals.os = proxy, clock
  local outcome = Codec.Pack(pcall(callback, ...))
  local ownership = globals.land == proxy and globals.os == clock
  if globals.land == proxy then
    globals.land = self.NativeLand
  end
  if globals.os == clock then
    globals.os = self.NativeOS
  end
  if not outcome.Values[1] then
    error(outcome.Values[2], 0)
  end
  assert(ownership, "P0 native: operation ownership changed")
  return unpack(outcome.Values, 2, outcome.Arity)
end

function Environment:RegisterSession(session)
  assert(#self.Sessions < 16, "P0 native: session limit")
  self.Sessions[#self.Sessions + 1] = session
end

function Environment:WithSession(case, session, callback)
  assert(case.Environment.ReplayCapability == "native_capture"
    and case.Execution.Clock == "unavailable" and case.Execution.Debug == false,
    "P0 native: incompatible case")
  for name, value in pairs(case.Environment.SurfaceTypes) do
    assert(self.NativeLand.SurfaceType[name] == value, "P0 native: surface enum mismatch")
  end
  local previous = self.Session
  self.Session = assert(session, "P0 native: capture/replay session required")
  local identity = Codec.Decode(session.Data.Manifest.InputIdentity)
  local request = identity.Request
  local stage = request and "connection" or "search"
  if identity.Probe then
    stage = "connection"
  end
  session:Begin(stage, "setup:" .. case.Experiment, request and request.RequestIndex or 1,
    stage == "search" and 0 or 1)
  local result = callback()
  self.Session = previous
  return result
end

function Environment:Track(kind, object)
  assert(#self.Owned < 256, "P0 native: owned object limit")
  self.Owned[#self.Owned + 1] = {Kind = kind, Object = assert(object), Session = self.Session}
end

function Environment:Operation(name, callback, ...)
  assert(not self.Stopped, "P0 native: obsolete work")
  self.Guard()
  local session = self.Session
  local before = session:Counts()
  local entry = {Sequence = #self.Journal + 1, Operation = name, Arguments = Codec.Pack(...),
    Scope = session.Active and Codec.Copy(session.Active.Scope)}
  local encoded = Codec.Encode(entry, {MaxBytes = self.MaxJournalBytes})
  assert(#self.Journal < self.MaxOperations and self.JournalBytes + #encoded <= self.MaxJournalBytes,
    "P0 native: action journal limit")
  -- Store only plain action arguments, never captured closures or class objects.
  self.Journal[#self.Journal + 1] = Codec.Decode(encoded)
  self.JournalBytes = self.JournalBytes + #encoded
  if self.ExpectedJournal then
    local expected = self.ExpectedJournal[#self.Journal]
    local compared = expected and Codec.Compare(expected, entry)
    if not expected or compared.Verdict ~= "passed" then
      self.FirstIssue = {Kind = "action_mismatch", Verdict = "failed", Sequence = #self.Journal,
        Difference = compared and compared.Difference}
      error(self.Abort, 0)
    end
  end
  local returned = Codec.Pack(self:Scoped(callback, ...))
  self.Guard()
  if name == "geometry" then
    assert(Codec.Compare(before, session:Counts()).Verdict == "passed",
      "P0 native: geometry queried terrain")
  end
  -- Yield only after Scoped's protected call has returned (Lua 5.1).
  if self.Yielding then
    coroutine.yield("operation")
  end
  return unpack(returned.Values, 1, returned.Arity)
end

function Environment:Finish(complete)
  self.Stopped = true
  local cleanupErrors = {}
  local stable, bindingFailure = pcall(self.Guard)
  self.BindingsStable = stable
  if not stable then
    cleanupErrors[#cleanupErrors + 1] = boundedText(bindingFailure)
  end
  for _, owned in ipairs(self.Owned) do
    self.Session = owned.Session
    local ok, failure = pcall(function()
      self:Scoped(function()
        if owned.Kind == "search" then
          owned.Object:CancelSearch()
        else
          PATHLINE.CancelValidation(owned.Object, "test_cleanup")
        end
      end)
    end)
    if not ok then
      cleanupErrors[#cleanupErrors + 1] = boundedText(failure)
    end
  end
  self.Session = nil
  for _, session in ipairs(self.Sessions) do
    session:Finish(complete)
  end
  if self.ExpectedJournal and #self.Journal < #self.ExpectedJournal then
    self.FirstIssue = self.FirstIssue or {Kind = "unconsumed_action", Verdict = "failed",
      Sequence = #self.Journal + 1}
  end
  self.Cleanup = {Restored = self.Globals.land == self.NativeLand and self.Globals.os == self.NativeOS,
    Errors = cleanupErrors}
  self.Owned = {}
  return self.Cleanup
end

function Native.NewEnvironment(options)
  options = options or {}
  local globals = options.Globals or _G
  local native = globals.land
  assert(type(native) == "table" and type(native.SurfaceType) == "table",
    "P0 native: terrain unavailable")
  local self = setmetatable({
    Globals = globals, NativeLand = native, NativeOS = globals.os, Functions = {},
    NativeSurfaceTypes = native.SurfaceType, SurfaceTypes = Codec.Copy(native.SurfaceType),
    Sessions = {}, Owned = {}, Journal = {}, JournalBytes = 0, Abort = {},
    MaxOperations = options.MaxOperations or 30000,
    MaxJournalBytes = options.MaxJournalBytes or 4 * 1024 * 1024,
    Guard = assert(options.Guard, "P0 native: explicit binding guard required"),
    ExpectedJournal = options.ExpectedJournal and Codec.Copy(options.ExpectedJournal),
    Yielding = true, Stopped = false,
  }, Environment)
  assert(self.MaxOperations >= 1 and self.MaxOperations <= 30000
    and self.MaxOperations % 1 == 0 and self.MaxJournalBytes >= 1
    and self.MaxJournalBytes <= 4 * 1024 * 1024, "P0 native: invalid action limits")
  for _, name in ipairs({"getSurfaceType", "getSurfaceHeightWithSeabed", "profile"}) do
    self.Functions[name] = assert(type(native[name]) == "function" and native[name],
      "P0 native: missing land." .. name)
  end
  return self
end

function Native.NewJob(environment, callback, options)
  options = options or {}
  assert(not environment.Job, "P0 native: environment already has a job")
  local self = setmetatable({Environment = environment, State = "running",
    Thread = coroutine.create(callback), MaxSimulationSeconds = options.MaxSimulationSeconds or 1200,
    SimulationTime = options.SimulationTime, CPUClock = options.CPUClock,
    Timing = {CPUKind = options.CPUClock and "measured_inclusive_runner" or "unavailable",
      SimulationKind = options.SimulationTime and "measured" or "unavailable", WallKind = "unavailable"},
    Slices = 0}, Job)
  assert(type(self.MaxSimulationSeconds) == "number" and self.MaxSimulationSeconds > 0
    and self.MaxSimulationSeconds <= 1200, "P0 native: invalid simulation limit")
  assert(self.SimulationTime == nil or type(self.SimulationTime) == "function",
    "P0 native: invalid simulation clock")
  assert(self.CPUClock == nil or type(self.CPUClock) == "function", "P0 native: invalid CPU clock")
  self.StartSimulation = self.SimulationTime and self.SimulationTime()
  if self.SimulationTime then
    assert(type(self.StartSimulation) == "number" and math.abs(self.StartSimulation) < math.huge,
      "P0 native: invalid simulation clock")
  end
  environment.Job = self
  return self
end

function Job:Cancel(reason)
  if self.State ~= "running" then
    return
  end
  self.State, self.Reason = "cancelled", reason or "test_cancel"
  self.Environment:Finish(false)
  if self.TimerId then
    self.Scheduler.removeFunction(self.TimerId)
    self.TimerId = nil
  end
  self:Notify()
end

function Job:Notify()
  if self.OnFinish and not self.Notified then
    self.Notified = true
    self.OnFinish(self)
  end
end

-- coroutine.resume is the outer protected boundary; errors propagate unchanged.
function Job:Advance()
  if self.State ~= "running" then
    return false
  end
  assert(self.Environment.Job == self, "P0 native: obsolete job ownership")
  if self.SimulationTime then
    local elapsed = self.SimulationTime() - self.StartSimulation
    assert(type(elapsed) == "number" and elapsed >= 0 and elapsed < math.huge,
      "P0 native: invalid simulation clock")
    self.Timing.SimulationSeconds = elapsed
    if elapsed >= self.MaxSimulationSeconds then
      self:Cancel("simulation_limit")
      return false
    end
  end
  local cpuStart = self.CPUClock and self.CPUClock()
  local outcome = Codec.Pack(coroutine.resume(self.Thread))
  self.Slices = self.Slices + 1
  local clockOK, clockFailure = true, nil
  if self.CPUClock then
    clockOK, clockFailure = pcall(function()
      local elapsed = self.CPUClock() - cpuStart
      assert(type(elapsed) == "number" and elapsed >= 0 and elapsed < math.huge,
        "P0 native: invalid CPU clock")
      self.Timing.CPUSeconds = (self.Timing.CPUSeconds or 0) + elapsed
      self.Timing.WorstSliceCPUSeconds = math.max(self.Timing.WorstSliceCPUSeconds or 0, elapsed)
    end)
    if not clockOK then
      self.MeasurementFailure = boundedText(clockFailure)
    end
  end
  if not outcome.Values[1] then
    self.State, self.Failure = "error", outcome.Values[2]
    self.Environment:Finish(false)
    error(self.Failure, 0)
  end
  if not clockOK then
    error(clockFailure, 0)
  end
  if coroutine.status(self.Thread) == "dead" then
    self.Result = outcome.Values[2]
    self.State = "complete"
    local cleanup = self.Environment:Finish(true)
    if not cleanup.Restored or #cleanup.Errors > 0 or self.Environment.FirstIssue then
      self.State, self.Reason = "error", "cleanup_or_action_mismatch"
    end
    return false
  end
  assert(outcome.Values[2] == "operation", "P0 native: unexpected coroutine yield")
  return true
end

function Job:Step()
  local ok, pending = pcall(self.Advance, self)
  if not ok then
    if self.State == "running" then
      self.State, self.Failure = "error", pending
      self.Environment:Finish(false)
    end
    error(pending, 0)
  end
  return pending
end

function Job:StartTimer(scheduler, onFinish, interval)
  assert(self.State == "running" and not self.Scheduler, "P0 native: duplicate timer chain")
  interval = interval or 0.1
  assert(type(interval) == "number" and interval > 0 and interval < math.huge,
    "P0 native: invalid timer interval")
  assert(type(scheduler.scheduleFunction) == "function" and type(scheduler.removeFunction) == "function"
    and type(scheduler.getTime) == "function", "P0 native: timer unavailable")
  self.Scheduler = scheduler
  self.OnFinish = onFinish
  local function tick(_, time)
    if self.State ~= "running" then
      return nil
    end
    local ok, pending = pcall(self.Step, self)
    if not ok then
      -- Persistence is secondary; it cannot replace the original terrain error.
      local saved, failure = pcall(self.Notify, self)
      if not saved then
        self.PersistenceFailure = boundedText(failure)
      end
      self.TimerId = nil
      error(pending, 0)
    end
    if not pending then
      self.TimerId = nil
      self:Notify()
      return nil
    end
    return time + interval
  end
  self.TimerId = scheduler.scheduleFunction(tick, nil, scheduler.getTime() + interval)
  assert(self.TimerId ~= nil, "P0 native: timer registration failed")
  return self
end

-- Input construction uses data helpers only; Fixtures.Install is never called.
function Native.Case(name, start, goal, surfaceTypes, sourceManifest)
  local case = P0.Fixtures.Case("open_water", name == "open-request" and "virtual_follow" or "fixed_pose_prepare")
  case.CaseId, case.Revision, case.VariantId = name, "p0-i3-1", "native-smoke-compact-weight1"
  case.Environment = {ReplayCapability = "native_capture", LuaVersion = _VERSION,
    SourceVerification = "unverified", SourceManifest = Codec.Copy(sourceManifest or {}),
    Terrain = {Id = "PersianGulf", Revision = "unknown"},
    SurfaceTypes = {WATER = surfaceTypes.WATER, SHALLOW_WATER = surfaceTypes.SHALLOW_WATER}}
  case.Route.Start, case.Route.Goal = Codec.Copy(start), Codec.Copy(goal)
  case.Pose.Position = Codec.Copy(start)
  case.Search.Window = {Ahead = 1200, Width = 800, Behind = 400}
  case.Execution.Clock, case.Execution.SliceNodes = "unavailable", 32
  case.Execution.MaxWorkItemsPerRequest, case.Execution.MaxRequests = 200000, 2
  case.Execution.MaxValidationSlices, case.Execution.MaxArtifactBytes = 10000, 4 * 1024 * 1024
  case.Execution.Transcript = {MaxCallsPerStage = 20000, MaxProfileRecordsPerStage = 200000,
    MaxBytes = 8 * 1024 * 1024}
  case.Provenance.Terrain = "measured"
  case.Actions[1].Position = Codec.Copy(start)
  if name == "open-request" then
    case.Expected.VirtualGoalReached = true
  else
    case.Actions[2].Start, case.Actions[2].Goal = Codec.Copy(start), Codec.Copy(goal)
    case.Expected = {}
  end
  return P0.ResolveCase(case)
end

function Native.ResolveCases(findZone, surfaces, sourceManifest)
  local names = {"ASTAR Start 1", "ASTAR Goal 1", "PATHLINE Shallow Start",
    "PATHLINE Shallow Goal", "PATHLINE Coast Start", "PATHLINE Coast Goal"}
  local positions = {}
  for _, name in ipairs(names) do
    local zone = assert(findZone(name), "P0 native: setup_required missing zone " .. name)
    local center = zone:GetVec2()
    assert(type(center) == "table", "P0 native: setup_required invalid zone")
    positions[name] = {x = center.x, y = 0, z = center.y}
    for _, coordinate in ipairs({center.x, center.y}) do
      assert(type(coordinate) == "number" and math.abs(coordinate) < math.huge,
        "P0 native: setup_required invalid coordinate")
    end
  end
  local first, target = positions[names[1]], positions[names[2]]
  local dx, dz = target.x - first.x, target.z - first.z
  local length = math.sqrt(dx * dx + dz * dz)
  assert(length > 0 and length < math.huge, "P0 native: setup_required coincident endpoints")
  local shortGoal = {x = first.x + 500 * dx / length, y = 0, z = first.z + 500 * dz / length}
  local cases = {Native.Case("open-request", first, shortGoal, surfaces, sourceManifest)}
  for index, name in ipairs({"shallow-probe", "coast-probe"}) do
    local start, goal = positions[names[index * 2 + 1]], positions[names[index * 2 + 2]]
    assert(start.x ~= goal.x or start.z ~= goal.z, "P0 native: setup_required coincident probe endpoints")
    cases[#cases + 1] = Native.Case(name, start, goal, surfaces, sourceManifest)
  end
  return cases, positions
end

local function probe(input, environment, captured)
  local case = P0.ResolveCase(input)
  local manifest = {InputIdentity = Codec.Encode({Case = case, Probe = true}), LuaVersion = _VERSION,
    SourceVerification = "unverified", SourceManifest = case.Environment.SourceManifest}
  local session = captured and Transcript.NewReplay(manifest, captured, case.Execution.Transcript)
    or Transcript.NewCapture(manifest, case.Execution.Transcript)
  environment:RegisterSession(session)
  local result = environment:WithSession(case, session, function()
    local planner = environment:Operation("planner", function()
      local created = P0.CreatePlanner(case)
      environment:Track("search", created)
      return created
    end)
    local geometry, reason = environment:Operation("geometry", PATHLINE.CreateGeometry,
      {case.Route.Start, case.Route.Goal}, case.Validation.Geometry)
    assert(geometry, reason)
    local result = {CaseId = case.CaseId, Origin = "configured_reference_segment", Selected = false,
      ExecutionValidated = false, Slices = 0, Stages = {}}
    local evaluator = PATHLINE.CreateConnectionEvaluator(function(first, last)
      local valid, cost, evidence = planner:EvaluateConnection(first, last)
      local report = {Status = evidence.Status, Reason = evidence.Reason}
      if evidence.Depth then
        local depth = evidence.Depth
        report.Evidence = {Depth = depth.Depth, SurfaceType = depth.SurfaceType,
          Cause = depth.Cause, Source = "ASTAR.EvaluateConnection"}
        if depth.Point then
          report.Evidence.Position = {x = depth.Point.x, z = depth.Point.z}
        end
      end
      if valid then
        report.Cost = cost
      end
      return report
    end, {CostUnits = case.Validation.Connection.CostUnits})
    local depth, failure = PATHLINE.CreateDepthEvaluator(case.Validation.Depth)
    assert(depth, failure)
    for index, descriptor in ipairs({{Name = "Connection", Stage = "connection", Evaluator = evaluator},
      {Name = "Depth", Stage = "depth", Evaluator = depth}}) do
      local context = case.CaseId .. "/" .. descriptor.Stage
      session:Begin(descriptor.Stage, case.CaseId, 1, 1)
      local limits = Codec.Copy(case.Execution[descriptor.Name].Total)
      limits.ContextId = context
      local job, report = environment:Operation("start_validation", function()
        local created, initial = PATHLINE.StartValidation(geometry, descriptor.Evaluator, limits)
        environment:Track("validation", created)
        return created, initial
      end, limits)
      while report.Status == "running" do
        if result.Slices >= case.Execution.MaxValidationSlices then
          report = environment:Operation("cancel_validation", function()
            return PATHLINE.CancelValidation(job, "driver_validation_slice_limit")
          end)
          result.CaptureComplete = false
        else
          report = environment:Operation("step_validation", function(budget, current)
            return PATHLINE.StepValidation(job, budget, current)
          end, case.Execution[descriptor.Name].Slice, context)
          result.Slices = result.Slices + 1
        end
      end
      result.Stages[descriptor.Stage] = report
      session:Close()
      if result.CaptureComplete == false or report.Status == "limited"
        or report.Status == "cancelled" or report.Status == "error" then
        result.CaptureComplete = false
        break
      end
    end
    if result.CaptureComplete == nil then
      result.CaptureComplete = true
    end
    result.TerrainTranscript = session:Finish(result.CaptureComplete)
    return result
  end)
  return result, session:Export()
end

function Native.RecordProbe(input, environment)
  return probe(input, environment)
end

function Native.ReplayProbe(input, environment, captured)
  assert(captured ~= nil, "P0 native: missing probe tape")
  return probe(input, environment, captured)
end

-- One copied case batch; no terrain queries occur until the job is stepped.
function Native.RunCases(cases, environment, replayed)
  local results = {}
  for index, case in ipairs(Codec.Copy(cases)) do
    local item = {Case = case}
    results[index] = item
    local expected = replayed and assert(replayed[index], "P0 native: missing replay case")
    if case.CaseId == "open-request" then
      if expected then
        item.Search, item.SearchTape = P0.ReplayRun(case, environment, expected.SearchTape, "native/open-request")
      else
        item.Search, item.SearchTape = P0.RecordRun(case, environment, "native/open-request")
      end
      local request = item.Search.Requests[1]
      if request and item.Search.End.CaptureComplete then
        local preparation = {ConsumerId = "fixed-pose", ContextId = "native/open-request"}
        if expected then
          item.Preparation, item.PreparationTape =
            P0.ReplayPreparation(case, request, environment, expected.PreparationTape, preparation)
        else
          item.Preparation, item.PreparationTape = P0.RecordPreparation(case, request, environment, preparation)
        end
      end
    elseif expected then
      item.Probe, item.ProbeTape = Native.ReplayProbe(case, environment, expected.ProbeTape)
    else
      item.Probe, item.ProbeTape = Native.RecordProbe(case, environment)
    end
    if environment.OnCase then
      environment.OnCase(index, item)
    end
    if item.Search and item.Search.End.CaptureComplete == false
      or item.Preparation and item.Preparation.CaptureComplete == false
      or item.Probe and item.Probe.CaptureComplete == false then
      break
    end
  end
  return results
end

function Native.Assertions(results)
  local checks = {}
  local first = results[1]
  checks.OpenSearch = first and first.Search and first.Search.End.Verdict == "passed"
    and first.Search.End.VirtualGoalReached == true or false
  checks.OpenPreparation = first and first.Preparation and first.Preparation.CaptureComplete
    and first.Preparation.Status == "unverified" or false
  checks.ShallowComplete = results[2] and results[2].Probe and results[2].Probe.CaptureComplete
    and results[2].Probe.Stages.connection ~= nil and results[2].Probe.Stages.depth ~= nil or false
  checks.CoastBlocked = results[3] and results[3].Probe and results[3].Probe.CaptureComplete
    and results[3].Probe.Stages.connection.Status == "blocked"
    and results[3].Probe.Stages.depth.Status == "blocked" or false
  local verdict = "passed"
  for _, passed in pairs(checks) do
    if not passed then
      verdict = "failed"
    end
  end
  return {Verdict = verdict, Checks = checks}
end

function Native.CompareResults(first, second)
  if #first ~= #second then
    return {Verdict = "failed", Difference = {Path = "$.Cases", Expected = #first, Actual = #second}}
  end
  for index, expected in ipairs(first) do
    local actual = second[index]
    local result = Codec.Compare(expected.Case, actual.Case)
    if result.Verdict ~= "passed" then
      return result
    end
    if expected.Search then
      result = P0.CompareRuns(expected.Search, actual.Search)
      if result.Verdict ~= "passed" then
        return result
      end
      result = Codec.Compare(Native.SemanticReport(expected.Preparation),
        Native.SemanticReport(actual.Preparation))
    else
      result = Codec.Compare(Native.SemanticReport(expected.Probe), Native.SemanticReport(actual.Probe))
    end
    if result.Verdict ~= "passed" then
      return result
    end
  end
  return {Kind = "native_core_semantic", Verdict = "passed", SourceVerified = false}
end

-- Query verification is reported separately; these are capture-mode diagnostics.
function Native.SemanticReport(report)
  local copy = Codec.Copy(report)
  if copy then
    copy.TerrainTranscript, copy.ReplayCapability = nil, nil
  end
  return copy
end

Native.BoundedText = boundedText
return Native
