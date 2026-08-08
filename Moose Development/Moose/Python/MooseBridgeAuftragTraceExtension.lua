-- Optional AUFTRAG tracing and diagnostic extension for MOOSE Bridge.
--
-- Load after MooseBridge.lua and, when used together with execution commands,
-- after MooseBridgeAuftragExecutionExtension.lua. This file only adds read-only
-- tracing helpers and does not change AUFTRAG execution semantics.

if not MOOSE_BRIDGE then error("Load MooseBridge.lua before MooseBridgeAuftragTraceExtension.lua") end

local function trace_safe_tostring(value)
  if value == nil then return "nil" end
  return tostring(value)
end

local function trace_split_object_id(object_id)
  if type(object_id) ~= "string" then return nil, nil end
  local prefix, name = string.match(object_id, "^([^:]+):(.+)$")
  if not prefix or not name then return nil, nil end
  return string.upper(prefix), name
end

local function trace_append_unique(result, seen, value)
  if value == nil then return end
  local text = tostring(value)
  if text == "" or seen[text] then return end
  result[#result + 1] = text
  seen[text] = true
end

local function trace_bool(value)
  if value == nil then return false end
  return value and true or false
end

local function trace_table_count(value)
  if type(value) ~= "table" then return 0 end
  local count = 0
  for _, _ in pairs(value) do count = count + 1 end
  return count
end

function MOOSE_BRIDGE:_TraceAuftragId(value)
  if type(value) ~= "table" then return nil end
  return self:_AuftragObjectId(value)
end

function MOOSE_BRIDGE:_TraceCollectAuftragIds(queue)
  local result = {}; local seen = {}
  if type(queue) ~= "table" then return result end
  for _, auftrag in pairs(queue) do
    trace_append_unique(result, seen, self:_TraceAuftragId(auftrag))
  end
  return result
end

function MOOSE_BRIDGE:_TraceQueueContainsAuftrag(queue, auftrag_id)
  if type(queue) ~= "table" then return false end
  for _, auftrag in pairs(queue) do
    if self:_TraceAuftragId(auftrag) == auftrag_id then return true end
  end
  return false
end

function MOOSE_BRIDGE:_TraceFindAuftrag(auftrag_id)
  if type(auftrag_id) ~= "string" or auftrag_id == "" then return nil, nil end

  if type(self.TrackedAuftraege) == "table" and type(self.TrackedAuftraege[auftrag_id]) == "table" then
    return self.TrackedAuftraege[auftrag_id], "bridge.tracked"
  end

  if _DATABASE and type(_DATABASE.LEGIONS) == "table" then
    for _, legion in pairs(_DATABASE.LEGIONS) do
      local queues = {legion.missionqueue, legion.missions, legion.auftraege, legion.missionQueue}
      for _, queue in ipairs(queues) do
        if type(queue) == "table" then
          for _, auftrag in pairs(queue) do
            if self:_TraceAuftragId(auftrag) == auftrag_id then return auftrag, "legion.queue" end
          end
        end
      end
    end
  end

  -- MOOSE stores all OPSGROUP specializations here despite the FLIGHTGROUPS name.
  if _DATABASE and type(_DATABASE.FLIGHTGROUPS) == "table" then
    for _, opsgroup in pairs(_DATABASE.FLIGHTGROUPS) do
      local current = opsgroup.currentmission or opsgroup.missioncurrent or opsgroup.currentMission
      if self:_TraceAuftragId(current) == auftrag_id then return current, "opsgroup.current" end
      local queues = {opsgroup.missionqueue, opsgroup.missions, opsgroup.auftraege, opsgroup.missionQueue}
      for _, queue in ipairs(queues) do
        if type(queue) == "table" then
          for _, auftrag in pairs(queue) do
            if self:_TraceAuftragId(auftrag) == auftrag_id then return auftrag, "opsgroup.queue" end
          end
        end
      end
    end
  end

  return nil, nil
end

function MOOSE_BRIDGE:_TraceLegionItem(legion_name, legion, auftrag_id, source)
  local item = self:_BuildLegionSnapshotItem(legion_name, legion, source)
  if type(item) ~= "table" then return nil end
  item.missionqueue_count = trace_table_count(legion and legion.missionqueue)
  item.missionqueue_contains_auftrag = self:_TraceQueueContainsAuftrag(legion and legion.missionqueue, auftrag_id)
  item.is_running = tostring(item.state or "") == "Running"
  return item
end

function MOOSE_BRIDGE:_TraceCohortItem(cohort_name, cohort, source)
  local item = self:_BuildCohortSnapshotItem(cohort_name, cohort, source)
  if type(item) ~= "table" then return nil end
  item.asset_count = item.asset_count or trace_table_count(cohort and cohort.assets)
  item.stock_asset_count = item.stock_asset_count or trace_table_count(cohort and cohort.stock)
  item.spawned_asset_count = item.spawned_asset_count or trace_table_count(cohort and cohort.spawnedassets)
  item.opsgroup_count = item.opsgroup_count or trace_table_count(cohort and cohort.opsgroups)
  return item
end

function MOOSE_BRIDGE:_TraceOpsGroupItem(opsgroup_name, opsgroup, auftrag_id, source)
  local item = self:_BuildOpsGroupSnapshotItem(opsgroup_name, opsgroup, source)
  if type(item) ~= "table" then return nil end
  item.current_contains_auftrag = item.auftrag_current_id == auftrag_id
  item.queue_contains_auftrag = self:_TraceQueueContainsAuftrag(opsgroup and opsgroup.missionqueue, auftrag_id)
  item.missionqueue_count = trace_table_count(opsgroup and opsgroup.missionqueue)
  return item
end

function MOOSE_BRIDGE:_TraceCollectLegions(auftrag_id)
  local result = {}
  if _DATABASE and type(_DATABASE.LEGIONS) == "table" then
    for name, legion in pairs(_DATABASE.LEGIONS) do
      local ok, item = pcall(function() return self:_TraceLegionItem(name, legion, auftrag_id, "database.LEGIONS") end)
      if ok and item then result[#result + 1] = item end
    end
  end
  return result
end

function MOOSE_BRIDGE:_TraceCollectCohorts()
  local result = {}; local seen = {}
  if _DATABASE and type(_DATABASE.LEGIONS) == "table" then
    for _, legion in pairs(_DATABASE.LEGIONS) do
      if type(legion.cohorts) == "table" then
        for name, cohort in pairs(legion.cohorts) do
          local ok, item = pcall(function() return self:_TraceCohortItem(name, cohort, "legion.cohorts") end)
          if ok and item and item.object_id and not seen[item.object_id] then
            result[#result + 1] = item
            seen[item.object_id] = true
          end
        end
      end
    end
  end
  return result
end

function MOOSE_BRIDGE:_TraceCollectOpsGroups(auftrag_id)
  local result = {}; local seen = {}
  for name, opsgroup in pairs(self.RegisteredOpsGroups or {}) do
    local ok, item = pcall(function() return self:_TraceOpsGroupItem(name, opsgroup, auftrag_id, "registered") end)
    if ok and item and item.object_id and not seen[item.object_id] then
      result[#result + 1] = item
      seen[item.object_id] = true
    end
  end
  -- MOOSE stores all OPSGROUP specializations here despite the FLIGHTGROUPS name.
  if _DATABASE and type(_DATABASE.FLIGHTGROUPS) == "table" then
    for name, opsgroup in pairs(_DATABASE.FLIGHTGROUPS) do
      local ok, item = pcall(function() return self:_TraceOpsGroupItem(name, opsgroup, auftrag_id, "database.FLIGHTGROUPS") end)
      if ok and item and item.object_id and not seen[item.object_id] then
        result[#result + 1] = item
        seen[item.object_id] = true
      end
    end
  end
  return result
end

function MOOSE_BRIDGE:_TraceBuild(auftrag_id)
  local auftrag, source = self:_TraceFindAuftrag(auftrag_id)
  local auftrag_item = nil
  if type(auftrag) == "table" then
    local ok, item = pcall(function() return self:_BuildAuftragSnapshotItem(auftrag, source or "trace") end)
    if ok then auftrag_item = item end
  end

  local legions = self:_TraceCollectLegions(auftrag_id)
  local cohorts = self:_TraceCollectCohorts()
  local opsgroups = self:_TraceCollectOpsGroups(auftrag_id)

  local matching_legions = {}
  for _, legion in ipairs(legions) do
    if legion.missionqueue_contains_auftrag then matching_legions[#matching_legions + 1] = legion.object_id end
  end

  local matching_opsgroups = {}
  for _, opsgroup in ipairs(opsgroups) do
    if opsgroup.current_contains_auftrag or opsgroup.queue_contains_auftrag then matching_opsgroups[#matching_opsgroups + 1] = opsgroup.object_id end
  end

  return {
    action="auftrag.trace",
    auftrag_id=auftrag_id,
    found=auftrag_item ~= nil,
    source=source,
    auftrag=auftrag_item,
    legions=legions,
    cohorts=cohorts,
    opsgroups=opsgroups,
    matching_legion_ids=matching_legions,
    matching_opsgroup_ids=matching_opsgroups,
    counts={
      legions=#legions,
      cohorts=#cohorts,
      opsgroups=#opsgroups,
      matching_legions=#matching_legions,
      matching_opsgroups=#matching_opsgroups,
    },
  }
end

function MOOSE_BRIDGE:RegisterAuftragTraceCommands()
  self:RegisterCommand("auftrag.trace", function(cmd)
    local p = self:_CommandParams(cmd)
    local auftrag_id = p.auftrag_id or p.object_id or p.id
    if type(auftrag_id) ~= "string" or auftrag_id == "" then error("auftrag.trace requires auftrag_id") end
    local prefix, _ = trace_split_object_id(auftrag_id)
    if prefix ~= "AUFTRAG" then error("auftrag.trace requires an AUFTRAG:<id> object id") end
    return self:_TraceBuild(auftrag_id)
  end)
end

local _moose_bridge_base_register_default_commands_for_trace = MOOSE_BRIDGE.RegisterDefaultCommands

function MOOSE_BRIDGE:RegisterDefaultCommands()
  _moose_bridge_base_register_default_commands_for_trace(self)
  self:RegisterAuftragTraceCommands()
end
