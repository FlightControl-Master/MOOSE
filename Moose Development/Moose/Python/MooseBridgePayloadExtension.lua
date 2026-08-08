-- Optional AIRWING payload snapshot extension for MOOSE Bridge.
--
-- Load after MooseBridge.lua when AIRWING payload availability should be included
-- in COHORT snapshots. The core Python advisory layer can then reject AIRWING
-- candidates without a compatible payload for the requested AUFTRAG type.

if not MOOSE_BRIDGE then error("Load MooseBridge.lua before MooseBridgePayloadExtension.lua") end

local function bridge_safe_tostring(value)
  if value == nil then return "nil" end
  return tostring(value)
end

local function bridge_string_or_nil(value)
  if value == nil then return nil end
  return tostring(value)
end

function MOOSE_BRIDGE:_CohortUnitType(cohort)
  if not cohort then return nil end
  local unit_type = self:_SafeCall(cohort, "GetUnitType")
  if not unit_type then unit_type = self:_SafeCall(cohort, "GetTypeName") end
  if not unit_type then unit_type = self:_SafeCall(cohort, "GetType") end
  if not unit_type then unit_type = cohort.unittype or cohort.unitType or cohort.aircrafttype or cohort.AircraftType or cohort.type end
  return unit_type and bridge_safe_tostring(unit_type) or nil
end

function MOOSE_BRIDGE:_PayloadPerformance(payload, mission_type)
  if type(payload) ~= "table" or type(payload.capabilities) ~= "table" then return nil end
  for _, capability in pairs(payload.capabilities) do
    if type(capability) == "table" and capability.MissionType == mission_type then
      return self:_NumberOrNil(capability.Performance)
    end
  end
  return nil
end

function MOOSE_BRIDGE:_SummarizePayload(payload, mission_type)
  if type(payload) ~= "table" then return nil end
  local performance = self:_PayloadPerformance(payload, mission_type)
  return {
    uid=payload.uid,
    unitname=bridge_string_or_nil(payload.unitname),
    aircrafttype=bridge_string_or_nil(payload.aircrafttype),
    navail=self:_NumberOrNil(payload.navail),
    unlimited=self:_BoolOrFalse(payload.unlimited),
    performance=performance,
  }
end

function MOOSE_BRIDGE:_PayloadAvailabilityForMission(airwing, unit_type, mission_type)
  local payloads = self:_SafeCallArg(airwing, "_FilterPlayloads", unit_type, mission_type)
  if payloads == nil then payloads = self:_SafeCallArg(airwing, "_FilterPayloads", unit_type, mission_type) end

  local result = {
    available_count=0,
    total_available=0,
    unlimited_count=0,
    best_performance=nil,
    payloads={},
  }

  if type(payloads) ~= "table" then return result end

  for _, payload in pairs(payloads) do
    local item = self:_SummarizePayload(payload, mission_type)
    if item then
      result.payloads[#result.payloads + 1] = item
      result.available_count = result.available_count + 1
      if item.unlimited then result.unlimited_count = result.unlimited_count + 1 end
      if item.navail then result.total_available = result.total_available + item.navail end
      if item.performance and (not result.best_performance or item.performance > result.best_performance) then
        result.best_performance = item.performance
      end
    end
  end

  return result
end

function MOOSE_BRIDGE:_CollectPayloadAvailability(cohort, mission_types)
  local result = {}
  if not cohort or type(mission_types) ~= "table" then return result end
  local airwing = cohort.legion
  if not airwing or not self:_SafeCall(airwing, "IsAirwing") then return result end
  local unit_type = self:_CohortUnitType(cohort)
  if not unit_type then return result end

  for _, mission_type in pairs(mission_types) do
    result[bridge_safe_tostring(mission_type)] = self:_PayloadAvailabilityForMission(airwing, unit_type, mission_type)
  end

  return result
end

local _moose_bridge_base_build_cohort_snapshot_item = MOOSE_BRIDGE._BuildCohortSnapshotItem

function MOOSE_BRIDGE:_BuildCohortSnapshotItem(cohort_name, cohort, source)
  local item = _moose_bridge_base_build_cohort_snapshot_item(self, cohort_name, cohort, source)
  if not item then return nil end
  local unit_type = self:_CohortUnitType(cohort)
  item.unit_type = unit_type
  item.payloads_by_mission = self:_CollectPayloadAvailability(cohort, item.mission_types)
  return item
end
