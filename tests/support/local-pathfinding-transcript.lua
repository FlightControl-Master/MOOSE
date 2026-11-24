-- P0-I2 test-only ordered terrain tapes. No native hooks, files or controllers.
-- Callers bind a session only to their isolated fixture, and always finish it.
local import = ...
if type(import) ~= "function" then
  import = dofile
end
local Codec = import("tests/support/local-pathfinding-codec.lua")
local Transcript = {}
local Session = {}
Session.__index = Session

local defaults = {
  MaxCallsPerStage = 100000,
  MaxProfileRecordsPerStage = 1000000,
  MaxBytes = 64 * 1024 * 1024,
}
local functions = {
  ["land.getSurfaceType"] = "Surface",
  ["land.getSurfaceHeightWithSeabed"] = "Depth",
  ["land.profile"] = "Profile",
}
local stages = {search = true, connection = true, depth = true}
local issueReserve = 4096
local maxTapes = 4096

local function record(value, fields, label)
  assert(type(value) == "table" and getmetatable(value) == nil,
    "P0 transcript: expected record " .. label)
  local allowed = {}
  for field in fields:gmatch("%S+") do
    allowed[field] = true
  end
  for key in pairs(value) do
    assert(allowed[key], "P0 transcript: unknown field " .. label .. "." .. tostring(key))
  end
end

local function integer(value, minimum, maximum, label)
  assert(type(value) == "number" and value >= minimum and value <= maximum
    and value == math.floor(value), "P0 transcript: invalid " .. label)
end

local function text(value, maximum, label)
  assert(type(value) == "string" and #value > 0 and #value <= maximum,
    "P0 transcript: invalid " .. label)
end

local function array(value, maximum, label)
  assert(type(value) == "table" and getmetatable(value) == nil,
    "P0 transcript: expected array " .. label)
  local count = 0
  for key in pairs(value) do
    integer(key, 1, maximum, label .. " key")
    count = count + 1
    assert(count <= maximum, "P0 transcript: array_limit " .. label)
  end
  for index = 1, count do
    assert(rawget(value, index) ~= nil, "P0 transcript: sparse array " .. label)
  end
  return count
end

function Transcript.ResolveLimits(input)
  if input == nil then
    input = {}
  end
  record(input, "MaxCallsPerStage MaxProfileRecordsPerStage MaxBytes", "Limits")
  local result = {}
  for key, maximum in pairs(defaults) do
    local value = input[key]
    if value == nil then
      value = maximum
    end
    integer(value, key == "MaxBytes" and 1 or 0, maximum, key)
    result[key] = value
  end
  return result
end

local function manifest(input)
  record(input, "InputIdentity LuaVersion SourceVerification SourceManifest", "Manifest")
  text(input.InputIdentity, 16 * 1024 * 1024, "InputIdentity")
  text(input.LuaVersion, 64, "LuaVersion")
  -- A supplied disk hash is not evidence of the bytes actually loaded.
  assert(input.SourceVerification == "unverified", "P0 transcript: no source verification adapter")
  array(input.SourceManifest, 32, "SourceManifest")
  for _, source in ipairs(input.SourceManifest) do
    record(source, "Path SHA256", "SourceManifest entry")
    text(source.Path, 1024, "SourceManifest.Path")
    assert(type(source.SHA256) == "string" and #source.SHA256 == 64
      and source.SHA256:match("^%x+$"), "P0 transcript: invalid SHA256")
  end
  return Codec.Copy(input)
end

local function scope(stage, consumer, requestIndex, candidateIndex)
  assert(stages[stage], "P0 transcript: invalid Stage")
  text(consumer, 64, "Consumer")
  integer(requestIndex, 1, 200, "RequestIndex")
  integer(candidateIndex, stage == "search" and 0 or 1, stage == "search" and 0 or 8,
    "CandidateIndex")
  return {Stage = stage, Consumer = consumer, RequestIndex = requestIndex,
    CandidateIndex = candidateIndex}
end

local function pack(value, label)
  record(value, "Arity Values", label)
  integer(value.Arity, 0, 1000000, label .. ".Arity")
  assert(type(value.Values) == "table" and getmetatable(value.Values) == nil,
    "P0 transcript: invalid " .. label .. ".Values")
  for key in pairs(value.Values) do
    integer(key, 1, value.Arity, label .. ".Values key")
  end
end

-- Count profile entries with next before allocating/sorting a copied profile.
-- The first return is the native profile; holes and nonnumeric keys still count.
local function profileRecords(name, returns, maximum)
  if name ~= "land.profile" or type(returns.Values[1]) ~= "table" then
    return 0
  end
  local count = 0
  for _ in next, returns.Values[1] do
    count = count + 1
    if count > maximum then
      return nil
    end
  end
  return count
end

local function encode(value, maximum)
  return Codec.Encode(value, {MaxBytes = maximum, MaxItems = 32000000})
end

-- Report excerpts must also be valid UTF-8 when a byte cap cuts a code point.
local function excerpt(value, maximum)
  local result = value:sub(1, maximum)
  local start = #result
  while start > 0 and result:byte(start) >= 128 and result:byte(start) < 192 do
    start = start - 1
  end
  if start > 0 then
    local byte = result:byte(start)
    local length = byte >= 240 and 4 or (byte >= 224 and 3 or (byte >= 192 and 2 or 1))
    if #result - start + 1 < length then
      result = result:sub(1, start - 1)
    end
  end
  return result
end

local function describe(value)
  local result = {Type = type(value)}
  if type(value) == "number" or type(value) == "boolean" then
    result.Value = value
  elseif type(value) == "string" then
    result.Value = excerpt(value, 128)
    if #value > 128 then
      result.Bytes, result.Truncated = #value, true
    end
  end
  return result
end

local function difference(first, second)
  local compared = Codec.Compare(first, second)
  if not compared.Difference then
    return nil
  end
  local detail = compared.Difference
  return {Path = excerpt(detail.Path, 512), PathTruncated = #detail.Path > 512,
    Expected = describe(detail.First), Actual = describe(detail.Second)}
end

local function counts()
  return {Surface = 0, Depth = 0, Profile = 0}
end

local function newSession(mode, input, limits)
  local cap = Transcript.ResolveLimits(limits)
  local data = {SchemaVersion = 1, Manifest = manifest(input), Limits = cap, Tapes = {}, Complete = false}
  local bytes = #encode(data, cap.MaxBytes)
  assert(bytes + issueReserve <= cap.MaxBytes,
    "P0 transcript: MaxBytes cannot hold the mandatory header and issue reserve")
  return setmetatable({Mode = mode, Data = data, Limits = cap, Bytes = bytes,
    StageCounts = {}, TotalCalls = counts(), TapeIndex = 0, Cursor = 0,
    Abort = {}, Finished = false}, Session)
end

function Transcript.NewCapture(input, limits)
  return newSession("record", input, limits)
end

function Session:Fail(kind, verdict, fields)
  if self.Data.Issue then
    return
  end
  fields = fields or {}
  fields.Kind, fields.Verdict = kind, verdict
  fields.TapeIndex = self.TapeIndex
  if self.Active then
    fields.Scope = Codec.Copy(self.Active.Scope)
    fields.Sequence = self.Cursor + 1
  end
  assert(#Codec.Encode(fields) <= issueReserve, "P0 transcript: issue reserve exceeded")
  self.Data.Issue, self.Data.Complete = fields, false
end

function Session:IsAbort(value)
  return value == self.Abort
end

function Session:Blocked()
  return self.Data.Issue ~= nil
end

local function halt(session)
  error(session.Abort, 0)
end

function Session:Counts()
  return Codec.Copy(self.TotalCalls)
end

function Session:Close()
  if not self.Active then
    return
  end
  if not self:Blocked() then
    if self.Mode == "record" then
      self.Active.Closed = true
      self.Bytes = self.Bytes - 1
    elseif self.Cursor < #self.Active.Calls then
      local nextCall = self.Active.Calls[self.Cursor + 1]
      self:Fail("unconsumed_call", "failed", {ExpectedFunction = nextCall.Function})
      halt(self)
    end
  end
  self.Active = nil
end

-- Scope boundaries, even empty ones, are ordered and cannot share a cursor.
function Session:Begin(stage, consumer, requestIndex, candidateIndex)
  assert(not self.Finished, "P0 transcript: session finished")
  if self:Blocked() then
    halt(self)
  end
  self:Close()
  local input = scope(stage, consumer, requestIndex, candidateIndex)
  local index = self.TapeIndex + 1
  if self.Mode == "record" then
    local tape = {Index = index, Scope = input, Calls = {}, Closed = false}
    local additional = #Codec.Encode(tape) + (index > 1 and 1 or 0)
    if index > maxTapes or self.Bytes + additional + issueReserve > self.Limits.MaxBytes then
      self.TapeIndex, self.Cursor = index, 0
      self:Fail("capture_limit", "inconclusive", {ActualScope = input,
        Exhausted = index > maxTapes and "tapes" or "bytes"})
      halt(self)
    end
    self.Data.Tapes[index] = tape
    self.Bytes = self.Bytes + additional
  else
    local expected = self.Data.Tapes[index]
    self.TapeIndex, self.Cursor, self.Active = index, 0, expected
    if not expected then
      self:Fail("missing_tape", "inconclusive", {ActualScope = input})
      halt(self)
    end
    local detail = difference(expected.Scope, input)
    if detail then
      self:Fail("scope_mismatch", "failed", {Difference = detail, ActualScope = input})
      halt(self)
    end
  end
  self.TapeIndex, self.Cursor = index, 0
  self.Active = self.Data.Tapes[index]
  if not self.StageCounts[stage] then
    self.StageCounts[stage] = {Calls = 0, ProfileRecords = 0}
  end
end

-- Return a detached bounded data snapshot. Unsupported external data is a gap.
local function snapshot(session, value, name)
  local ok, bytes, reason = pcall(Codec.TryEncode, value, {MaxBytes = session.Limits.MaxBytes})
  if not ok then
    session:Fail("unsupported_data", "inconclusive", {ActualFunction = name})
    halt(session)
  elseif not bytes then
    session:Fail("capture_limit", "inconclusive", {ActualFunction = name, Exhausted = reason})
    halt(session)
  end
  return Codec.Decode(bytes), #bytes
end

local function admit(session, name)
  if session:Blocked() then
    halt(session)
  end
  assert(not session.Finished, "P0 transcript: session finished")
  if not session.Active then
    session:Fail("missing_scope", "inconclusive", {ActualFunction = name:sub(1, 128)})
    halt(session)
  end
  if not functions[name] then
    session:Fail("unsupported_function", "inconclusive", {ActualFunction = name:sub(1, 128)})
    halt(session)
  end
  local stage = session.StageCounts[session.Active.Scope.Stage]
  if stage.Calls >= session.Limits.MaxCallsPerStage then
    session:Fail("capture_limit", "inconclusive", {ActualFunction = name, Exhausted = "calls"})
    halt(session)
  end
  return stage
end

-- Live receives the original argument values; capture owns copies made before
-- evaluation. Replay never calls Live and returns a fresh unpacked snapshot.
function Session:Call(name, live, ...)
  text(name, 128, "Function")
  local stage = admit(self, name)
  local args = snapshot(self, Codec.Pack(...), name)
  if self.Mode == "replay" then
    local entry = self.Active.Calls[self.Cursor + 1]
    if not entry then
      self:Fail("missing_call", "inconclusive", {ActualFunction = name})
      halt(self)
    end
    if entry.Function ~= name then
      self:Fail("function_mismatch", "failed", {ExpectedFunction = entry.Function, ActualFunction = name})
      halt(self)
    end
    local detail = difference(entry.Arguments, args)
    if detail then
      self:Fail("arguments_mismatch", "failed", {ExpectedFunction = name, ActualFunction = name,
        Difference = detail})
      halt(self)
    end
    self.Cursor = self.Cursor + 1
    stage.Calls = stage.Calls + 1
    self.TotalCalls[functions[name]] = self.TotalCalls[functions[name]] + 1
    if entry.Outcome == "error" then
      error(entry.Error, 0)
    end
    stage.ProfileRecords = stage.ProfileRecords + profileRecords(name, entry.Returns,
      self.Limits.MaxProfileRecordsPerStage)
    local returns = Codec.Copy(entry.Returns)
    return unpack(returns.Values, 1, returns.Arity)
  end

  assert(type(live) == "function", "P0 transcript: capture requires a live fixture function")
  -- Admission covers already-known argument bytes. Unknown response size is
  -- checked only after the atomic fixture/native call has returned.
  local entry = {Sequence = self.Cursor + 1, Function = name, Arguments = args, Outcome = "return"}
  local beforeBytes = #Codec.Encode(entry)
  local separator = self.Cursor > 0 and 1 or 0
  if self.Bytes + beforeBytes + separator + issueReserve > self.Limits.MaxBytes then
    self:Fail("capture_limit", "inconclusive", {ActualFunction = name, Exhausted = "bytes"})
    halt(self)
  end
  stage.Calls = stage.Calls + 1
  self.TotalCalls[functions[name]] = self.TotalCalls[functions[name]] + 1
  local outcome = Codec.Pack(pcall(live, ...))
  if not outcome.Values[1] then
    local failure = outcome.Values[2]
    if type(failure) == "string" then
      entry.Outcome, entry.Error = "error", failure
    else
      self:Fail("unsupported_error", "inconclusive", {ActualFunction = name})
      error(failure, 0)
    end
    -- Preserve the original exception even if its record exceeds a limit.
    local ok, bytes = pcall(Codec.TryEncode, entry, {MaxBytes = self.Limits.MaxBytes})
    if not ok or not bytes or self.Bytes + #bytes + separator + issueReserve > self.Limits.MaxBytes then
      self:Fail("capture_limit", "inconclusive", {ActualFunction = name, Exhausted = "error_record"})
    else
      self.Active.Calls[#self.Active.Calls + 1] = Codec.Decode(bytes)
      self.Cursor = self.Cursor + 1
      self.Bytes = self.Bytes + #bytes + separator
    end
    error(failure, 0)
  end
  local returns = {Arity = outcome.Arity - 1, Values = {}}
  for index = 1, returns.Arity do
    returns.Values[index] = outcome.Values[index + 1]
  end
  local count = profileRecords(name, returns, self.Limits.MaxProfileRecordsPerStage - stage.ProfileRecords)
  if not count then
    self:Fail("capture_limit", "inconclusive", {ActualFunction = name, Exhausted = "profile_records"})
    halt(self)
  end
  entry.Returns = snapshot(self, returns, name)
  local bytes = #Codec.Encode(entry)
  if self.Bytes + bytes + separator + issueReserve > self.Limits.MaxBytes then
    self:Fail("capture_limit", "inconclusive", {ActualFunction = name, Exhausted = "bytes"})
    halt(self)
  end
  self.Active.Calls[#self.Active.Calls + 1] = entry
  self.Cursor = self.Cursor + 1
  self.Bytes = self.Bytes + bytes + separator
  stage.ProfileRecords = stage.ProfileRecords + count
  return unpack(returns.Values, 1, returns.Arity)
end

-- Only the first issue survives cleanup or further attempted work.
function Session:Finish(completed)
  assert(type(completed) == "boolean", "P0 transcript: expected completion boolean")
  if self.Finished then
    return self:Report()
  end
  if not self:Blocked() then
    if not completed then
      self:Fail("capture_incomplete", "inconclusive")
    else
      local ok, failure = pcall(self.Close, self)
      if not ok and not self:IsAbort(failure) then
        error(failure, 0)
      end
      if not self:Blocked() and self.Mode == "replay" and self.TapeIndex < #self.Data.Tapes then
        self.TapeIndex = self.TapeIndex + 1
        self:Fail("unconsumed_tape", "failed",
          {ExpectedScope = Codec.Copy(self.Data.Tapes[self.TapeIndex].Scope)})
      end
    end
  end
  self.Active = nil
  self.Finished = true
  self.Data.Complete = not self:Blocked()
  return self:Report()
end

function Session:Report()
  return {Mode = self.Mode, Kind = "exact_query_sequence",
    Verdict = self:Blocked() and self.Data.Issue.Verdict or (self.Finished and "passed" or "not_run"),
    Complete = self.Finished and self.Data.Complete or false, FirstIssue = Codec.Copy(self.Data.Issue),
    StageCounts = Codec.Copy(self.StageCounts), TerrainCalls = self:Counts(),
    SourceVerification = "unverified", SourceVerified = false}
end

function Session:Export()
  assert(self.Finished, "P0 transcript: finish before exporting")
  return Codec.Decode(encode(self.Data, self.Limits.MaxBytes),
    {MaxBytes = self.Limits.MaxBytes, MaxItems = 32000000})
end

-- Validate the schema as well as the bounded JSON representation, before replay.
local function validate(input)
  record(input, "SchemaVersion Manifest Limits Tapes Complete Issue", "Transcript")
  assert(input.SchemaVersion == 1, "P0 transcript: unsupported SchemaVersion")
  manifest(input.Manifest)
  local cap = Transcript.ResolveLimits(input.Limits)
  assert(Codec.Compare(input.Limits, cap).Verdict == "passed", "P0 transcript: unresolved Limits")
  assert(type(input.Complete) == "boolean", "P0 transcript: invalid Complete")
  if input.Issue ~= nil then
    record(input.Issue, "Kind Verdict TapeIndex Scope Sequence ExpectedScope ActualScope ExpectedFunction ActualFunction Difference Exhausted", "Issue")
    text(input.Issue.Kind, 64, "Issue.Kind")
    assert(input.Issue.Verdict == "inconclusive" or input.Issue.Verdict == "failed",
      "P0 transcript: invalid Issue.Verdict")
    assert(not input.Complete and #Codec.Encode(input.Issue) <= issueReserve,
      "P0 transcript: invalid issue/completeness")
    integer(input.Issue.TapeIndex, 0, maxTapes + 1, "Issue.TapeIndex")
    if input.Issue.Sequence ~= nil then
      integer(input.Issue.Sequence, 1, defaults.MaxCallsPerStage + 1, "Issue.Sequence")
    end
    for _, field in ipairs({"Scope", "ExpectedScope", "ActualScope"}) do
      local value = input.Issue[field]
      if value ~= nil then
        record(value, "Stage Consumer RequestIndex CandidateIndex", "Issue." .. field)
        scope(value.Stage, value.Consumer, value.RequestIndex, value.CandidateIndex)
      end
    end
    for _, field in ipairs({"ExpectedFunction", "ActualFunction", "Exhausted"}) do
      if input.Issue[field] ~= nil then
        text(input.Issue[field], 128, "Issue." .. field)
      end
    end
    if input.Issue.Difference ~= nil then
      local detail = input.Issue.Difference
      record(detail, "Path PathTruncated Expected Actual", "Issue.Difference")
      text(detail.Path, 512, "Difference.Path")
      assert(type(detail.PathTruncated) == "boolean", "P0 transcript: invalid PathTruncated")
      for _, field in ipairs({"Expected", "Actual"}) do
        local value = detail[field]
        record(value, "Type Value Bytes Truncated", "Difference." .. field)
        assert(value.Type == "nil" or value.Type == "number" or value.Type == "string"
          or value.Type == "boolean" or value.Type == "table", "P0 transcript: invalid value descriptor")
        if value.Type == "string" then
          assert(type(value.Value) == "string" and #value.Value <= 128, "P0 transcript: invalid string descriptor")
        elseif value.Type == "number" or value.Type == "boolean" then
          assert(type(value.Value) == value.Type, "P0 transcript: invalid scalar descriptor")
        else
          assert(value.Value == nil, "P0 transcript: invalid nil/table descriptor")
        end
        if value.Bytes ~= nil or value.Truncated ~= nil then
          integer(value.Bytes, 129, 64 * 1024 * 1024, "descriptor Bytes")
          assert(value.Type == "string" and value.Truncated == true,
            "P0 transcript: invalid truncated descriptor")
        end
      end
    end
  end
  local totals = {}
  array(input.Tapes, maxTapes, "Tapes")
  for index, tape in ipairs(input.Tapes) do
    record(tape, "Index Scope Calls Closed", "Tape")
    assert(tape.Index == index, "P0 transcript: invalid tape sequence")
    record(tape.Scope, "Stage Consumer RequestIndex CandidateIndex", "Scope")
    local checked = scope(tape.Scope.Stage, tape.Scope.Consumer, tape.Scope.RequestIndex, tape.Scope.CandidateIndex)
    assert(type(tape.Closed) == "boolean" and (not input.Complete or tape.Closed),
      "P0 transcript: invalid Closed")
    local total = totals[checked.Stage] or {Calls = 0, ProfileRecords = 0}
    totals[checked.Stage] = total
    total.Calls = total.Calls + array(tape.Calls, cap.MaxCallsPerStage, "Calls")
    assert(total.Calls <= cap.MaxCallsPerStage, "P0 transcript: calls limit")
    for sequence, call in ipairs(tape.Calls) do
      record(call, "Sequence Function Arguments Outcome Returns Error", "Call")
      assert(call.Sequence == sequence and functions[call.Function], "P0 transcript: invalid call sequence/function")
      pack(call.Arguments, "Arguments")
      if call.Outcome == "return" then
        assert(call.Error == nil, "P0 transcript: return with Error")
        pack(call.Returns, "Returns")
        local count = profileRecords(call.Function, call.Returns, cap.MaxProfileRecordsPerStage - total.ProfileRecords)
        assert(count, "P0 transcript: profile records limit")
        total.ProfileRecords = total.ProfileRecords + count
      else
        assert(call.Outcome == "error" and type(call.Error) == "string" and call.Returns == nil,
          "P0 transcript: invalid Outcome")
      end
    end
  end
  return cap, totals, encode(input, cap.MaxBytes)
end

function Transcript.Encode(input)
  local _, _, bytes = validate(input)
  return bytes
end

-- Bad/truncated interchange data is an explicit gap, never executable code.
function Transcript.Decode(bytes, limits)
  local cap = Transcript.ResolveLimits(limits)
  local ok, data = pcall(Codec.Decode, bytes, {MaxBytes = cap.MaxBytes, MaxItems = 32000000})
  if ok then
    ok, data = pcall(function()
      local _, totals = validate(data)
      for _, stageName in ipairs({"search", "connection", "depth"}) do
        local total = totals[stageName] or {Calls = 0, ProfileRecords = 0}
        assert(total.Calls <= cap.MaxCallsPerStage
          and total.ProfileRecords <= cap.MaxProfileRecordsPerStage,
          "P0 transcript: decode admission limit")
      end
      return data
    end)
  end
  if not ok then
    return nil, {Verdict = "inconclusive", Kind = "invalid_transcript_document"}
  end
  return data
end

function Transcript.NewReplay(input, captured, limits)
  local session = newSession("replay", input, limits)
  local _, totals, bytes = validate(captured)
  if not captured.Complete then
    session:Fail("capture_incomplete", "inconclusive")
  elseif captured.Manifest.LuaVersion ~= _VERSION then
    session:Fail("environment_mismatch", "failed",
      {Difference = difference(captured.Manifest.LuaVersion, _VERSION)})
  else
    local detail = difference(captured.Manifest, session.Data.Manifest)
    if detail then
      session:Fail("input_mismatch", "failed", {Difference = detail})
    end
    -- Fixed stage order gives deterministic precedence if several caps fail.
    for _, stageName in ipairs({"search", "connection", "depth"}) do
      local total = totals[stageName] or {Calls = 0, ProfileRecords = 0}
      if total.Calls > session.Limits.MaxCallsPerStage
        or total.ProfileRecords > session.Limits.MaxProfileRecordsPerStage then
        session:Fail("capture_limit", "inconclusive", {Exhausted = total.Calls > session.Limits.MaxCallsPerStage
          and "calls" or "profile_records"})
      end
    end
    if not session:Blocked() and #bytes + issueReserve > session.Limits.MaxBytes then
      session:Fail("capture_limit", "inconclusive", {Exhausted = "bytes"})
    end
    if not session:Blocked() then
      session.Data.Tapes = Codec.Decode(bytes, {MaxBytes = session.Limits.MaxBytes,
        MaxItems = 32000000}).Tapes
    end
  end
  return session
end

return Transcript
