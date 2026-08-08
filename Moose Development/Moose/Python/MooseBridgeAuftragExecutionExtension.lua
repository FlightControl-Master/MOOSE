-- Optional approval-gated AUFTRAG execution extension for MOOSE Bridge.
--
-- Load after MooseBridge.lua and before creating the bridge instance. This file
-- exposes narrow, explicit AUFTRAG creation commands. Python should only call
-- them after an advisory recommendation has passed all hard filters and the user
-- explicitly requested execution.

if not MOOSE_BRIDGE then error("Load MooseBridge.lua before MooseBridgeAuftragExecutionExtension.lua") end

local bridge_unpack = table.unpack or unpack

local function bridge_split_object_id(object_id)
  if type(object_id) ~= "string" then return nil, nil end
  local prefix, name = string.match(object_id, "^([^:]+):(.+)$")
  if not prefix or not name then return nil, nil end
  return string.upper(prefix), name
end

local function bridge_safe_tostring(value)
  if value == nil then return "nil" end
  return tostring(value)
end

local function bridge_table_keys(value)
  if type(value) ~= "table" then return "<" .. type(value) .. ">" end
  local keys = {}
  for key, _ in pairs(value) do keys[#keys + 1] = tostring(key) end
  table.sort(keys)
  return table.concat(keys, ",")
end

local function bridge_param_debug(command, params)
  return "command_keys=[" .. bridge_table_keys(command) .. "] " ..
         "params_keys=[" .. bridge_table_keys(command and command.params) .. "] " ..
         "payload_keys=[" .. bridge_table_keys(command and command.payload) .. "] " ..
         "resolved_keys=[" .. bridge_table_keys(params) .. "]"
end

local function bridge_optional_string_param(value)
  if type(value) ~= "string" then return nil end
  local trimmed = string.match(value, "^%s*(.-)%s*$")
  if trimmed == "" or string.lower(trimmed) == "null" then return nil end
  return trimmed
end

local function bridge_optional_bool(value)
  if value == nil then return nil end
  return value and true or false
end

local function bridge_bool_param(value)
  if value == nil then return nil end
  if type(value) == "boolean" then return value end
  local text = string.lower(tostring(value))
  if text == "true" or text == "1" or text == "yes" or text == "y" then return true end
  if text == "false" or text == "0" or text == "no" or text == "n" then return false end
  return value and true or false
end

local function bridge_number_param(value)
  if value == nil then return nil end
  if type(value) == "number" then return value end
  local text = bridge_optional_string_param(value)
  if not text then return nil end
  local number = tonumber(text)
  if number == nil then error("Expected number parameter, got " .. bridge_safe_tostring(value)) end
  return number
end

local function bridge_coalition_param(value)
  if value == nil then return nil end
  if type(value) == "number" then return value end
  local text = bridge_optional_string_param(value)
  if not text then return nil end
  local number = tonumber(text)
  if number ~= nil then return number end
  local normalized = string.lower(text)
  if normalized == "red" then return coalition and coalition.side and coalition.side.RED or 1 end
  if normalized == "blue" then return coalition and coalition.side and coalition.side.BLUE or 2 end
  if normalized == "neutral" then return coalition and coalition.side and coalition.side.NEUTRAL or 0 end
  error("Unknown coalition parameter: " .. bridge_safe_tostring(value))
end

local function bridge_time_param(value)
  if value == nil then return nil end
  if type(value) == "number" then return value end
  return bridge_optional_string_param(value)
end

local function bridge_auftrag_now()
  if timer and timer.getAbsTime then return timer.getAbsTime() end
  if timer and timer.getTime then return timer.getTime() end
  return nil
end

local function bridge_auftrag_summary(summary)
  if type(summary) ~= "table" then return nil end
  return {
    success=bridge_optional_bool(summary.success),
    Ntargets0=summary.Ntargets0,
    Ntargets=summary.Ntargets,
    damage=summary.damage,
    Ndestroyed=summary.Ndestroyed,
    Nkills=summary.Nkills,
    Nelements=summary.Nelements,
    targetLife=summary.targetLife,
    category=summary.category,
    Ncasualties=summary.Ncasualties,
  }
end

local function bridge_auftrag_ready_to_evaluate(auftrag)
  local tover = auftrag and auftrag.Tover or nil
  local dtevaluate = auftrag and auftrag.dTevaluate or nil
  local now = bridge_auftrag_now()
  if tover and dtevaluate and now then return now - tover >= dtevaluate end
  return false
end

function MOOSE_BRIDGE:_CommandParams(command)
  if type(command) ~= "table" then return {} end
  if type(command.params) == "table" then return command.params end
  if type(command.payload) == "table" then
    if type(command.payload.params) == "table" then return command.payload.params end
    return command.payload
  end
  return {}
end

function MOOSE_BRIDGE:_TrackAuftragReference(auftrag)
  if type(auftrag) ~= "table" then return self end
  local object_id = self:_AuftragObjectId(auftrag)
  if not object_id then return self end
  self.TrackedAuftraege = self.TrackedAuftraege or {}
  self.TrackedAuftraege[object_id] = auftrag
  return self
end

function MOOSE_BRIDGE:_FindAuftragInQueueById(queue, auftrag_id)
  if type(queue) ~= "table" then return nil end
  for _, auftrag in pairs(queue) do
    if self:_AuftragObjectId(auftrag) == auftrag_id then return auftrag end
  end
  return nil
end

function MOOSE_BRIDGE:_ResolveTrackedAuftragById(auftrag_id)
  local id = bridge_optional_string_param(auftrag_id)
  if not id then return nil, "Missing AUFTRAG id" end

  if type(self.TrackedAuftraege) == "table" and type(self.TrackedAuftraege[id]) == "table" then
    return self.TrackedAuftraege[id], nil
  end

  if _DATABASE and type(_DATABASE.LEGIONS) == "table" then
    for _, legion in pairs(_DATABASE.LEGIONS) do
      local queues = {legion.missionqueue, legion.missions, legion.auftraege, legion.missionQueue}
      for _, queue in ipairs(queues) do
        local found = self:_FindAuftragInQueueById(queue, id)
        if found then self:_TrackAuftragReference(found); return found, nil end
      end
    end
  end

  for _, commander in pairs(self.RegisteredCommanders or {}) do
    local found = self:_FindAuftragInQueueById(commander.missionqueue, id)
    if found then self:_TrackAuftragReference(found); return found, nil end
  end

  if _DATABASE and type(_DATABASE.FLIGHTGROUPS) == "table" then
    for _, opsgroup in pairs(_DATABASE.FLIGHTGROUPS) do
      local found = self:_FindAuftragInQueueById(opsgroup.missionqueue, id)
      if found then self:_TrackAuftragReference(found); return found, nil end
    end
  end

  for _, opsgroup in pairs(self.RegisteredOpsGroups or {}) do
    local found = self:_FindAuftragInQueueById(opsgroup.missionqueue, id)
    if found then self:_TrackAuftragReference(found); return found, nil end
  end

  return nil, "AUFTRAG not found: " .. id
end

function MOOSE_BRIDGE:_CommandAuftragId(cmd)
  local p = self:_CommandParams(cmd)
  return bridge_optional_string_param(p.object_id) or bridge_optional_string_param(p.auftrag_id)
end

function MOOSE_BRIDGE:_ResolveLegionById(legion_id)
  local prefix, name = bridge_split_object_id(legion_id)
  if prefix ~= "LEGION" or not name then return nil, "Invalid LEGION id " .. bridge_safe_tostring(legion_id) end

  if _DATABASE then
    local found = self:_SafeCallArg(_DATABASE, "FindLegion", name)
    if found then return found, nil end

    if type(_DATABASE.LEGIONS) == "table" then
      for key, legion in pairs(_DATABASE.LEGIONS) do
        local legion_name = self:_ObjectName(legion) or (type(key) == "string" and key or nil)
        if legion_name == name then return legion, nil end
      end
    end
  end

  return nil, "LEGION not found: " .. name
end

function MOOSE_BRIDGE:_ResolveCommanderById(commander_id)
  local prefix, name = bridge_split_object_id(commander_id)
  if prefix ~= "COMMANDER" or not name then return nil, "Invalid COMMANDER id " .. bridge_safe_tostring(commander_id) end

  for key, commander in pairs(self.RegisteredCommanders or {}) do
    local commander_name = self:_CommanderName(commander, type(key) == "string" and key or nil)
    if commander_name == name then return commander, nil end
  end
  if _DATABASE and type(_DATABASE.COMMANDERS) == "table" then
    for key, commander in pairs(_DATABASE.COMMANDERS) do
      local commander_name = self:_CommanderName(commander, type(key) == "string" and key or nil)
      if commander_name == name then return commander, nil end
    end
  end
  return nil, "COMMANDER not found: " .. name
end

function MOOSE_BRIDGE:_ResolveCohortById(cohort_id)
  local prefix, name = bridge_split_object_id(cohort_id)
  if prefix ~= "COHORT" or not name then return nil, "Invalid COHORT id " .. bridge_safe_tostring(cohort_id) end
  if _DATABASE and type(_DATABASE.COHORTS) == "table" then
    for key, cohort in pairs(_DATABASE.COHORTS) do
      local cohort_name = self:_CohortName(cohort, type(key) == "string" and key or nil)
      if cohort_name == name then return cohort, nil end
    end
  end
  return nil, "COHORT not found: " .. name
end

function MOOSE_BRIDGE:_ResolveOpsGroupById(opsgroup_id)
  local prefix, name = bridge_split_object_id(opsgroup_id)
  if prefix ~= "OPSGROUP" or not name then return nil, "Invalid OPSGROUP id " .. bridge_safe_tostring(opsgroup_id) end

  if type(self.RegisteredOpsGroups) == "table" then
    for key, opsgroup in pairs(self.RegisteredOpsGroups) do
      local opsgroup_name = self:_OpsName(opsgroup, type(key) == "string" and key or nil)
      if opsgroup_name == name then return opsgroup, nil end
    end
  end

  if _DATABASE and type(_DATABASE.FLIGHTGROUPS) == "table" then
    for key, opsgroup in pairs(_DATABASE.FLIGHTGROUPS) do
      local opsgroup_name = self:_OpsName(opsgroup, type(key) == "string" and key or nil)
      if opsgroup_name == name then return opsgroup, nil end
    end
  end

  return nil, "OPSGROUP not found: " .. name
end

function MOOSE_BRIDGE:_ResolveAuftragTargetById(target_id)
  local prefix, name = bridge_split_object_id(target_id)
  if not prefix or not name then return nil, "Invalid target id " .. bridge_safe_tostring(target_id) end

  if prefix == "GROUP" then
    if GROUP and GROUP.FindByName then
      local target = GROUP:FindByName(name)
      if target then return target, nil end
    end
    if Group and Group.getByName then
      local dcs_group = Group.getByName(name)
      if dcs_group then return dcs_group, nil end
    end
    return nil, "GROUP target not found: " .. name
  end

  if prefix == "UNIT" then
    if UNIT and UNIT.FindByName then
      local target = UNIT:FindByName(name)
      if target then return target, nil end
    end
    if Unit and Unit.getByName then
      local dcs_unit = Unit.getByName(name)
      if dcs_unit then return dcs_unit, nil end
    end
    return nil, "UNIT target not found: " .. name
  end

  if prefix == "STATIC" then
    if STATIC and STATIC.FindByName then
      local target = STATIC:FindByName(name)
      if target then return target, nil end
    end
    if StaticObject and StaticObject.getByName then
      local dcs_static = StaticObject.getByName(name)
      if dcs_static then return dcs_static, nil end
    end
    return nil, "STATIC target not found: " .. name
  end

  return nil, "Unsupported AUFTRAG target type: " .. prefix
end

function MOOSE_BRIDGE:_ResolveCoordinateFromInputs(inputs)
  local x = inputs.x ~= nil and tonumber(inputs.x) or nil
  local z = inputs.z ~= nil and tonumber(inputs.z) or nil
  local y = inputs.y ~= nil and tonumber(inputs.y) or 0

  if not x or not z then return nil, "Coordinate target requires numeric x and z" end
  if not COORDINATE or not COORDINATE.New then return nil, "COORDINATE:New is not available" end

  return COORDINATE:New(x, y, z), nil
end

function MOOSE_BRIDGE:_BuildOpsZoneSnapshotItem(zone_name, opszone, source)
  local name = self:_OpsName(opszone, zone_name)
  if not name then return nil end
  local point = self:_PointFromMooseObject(opszone)
  local state = self:_OpsState(opszone)
  local n_red = opszone and tonumber(opszone.Nred) or 0
  local n_blue = opszone and tonumber(opszone.Nblu) or 0
  local item = {
    object_id="OPSZONE:"..bridge_safe_tostring(name),
    dcs_name=bridge_safe_tostring(name),
    object_type="OPSZONE",
    category=self:_OpsClassName(opszone, "OPSZONE"),
    source=source,
    name=bridge_safe_tostring(name),
    zone_name=opszone and opszone.zoneName and tostring(opszone.zoneName) or nil,
    zone_type=opszone and opszone.zoneType and tostring(opszone.zoneType) or nil,
    zone_radius=opszone and opszone.zoneRadius or nil,
    state=state and tostring(state) or nil,
    owner_current_name=self:_CoalitionToName(opszone and opszone.ownerCurrent),
    owner_previous_name=self:_CoalitionToName(opszone and opszone.ownerPrevious),
    is_contested=n_red > 0 and n_blue > 0,
    n_red=n_red,
    n_blue=n_blue,
    n_neutral=opszone and opszone.Nnut or 0,
    threat_red=opszone and opszone.Tred or 0,
    threat_blue=opszone and opszone.Tblu or 0,
    threat_neutral=opszone and opszone.Tnut or 0,
    airbase_name=opszone and opszone.airbaseName and tostring(opszone.airbaseName) or nil,
    capture_event_callback_type=opszone and type(opszone.OnAfterCaptured) or "nil",
    capture_event_forwarder_attached=opszone and
      opszone.MooseBridgeCapturedEventForwarder ~= nil and
      opszone.OnAfterCaptured == opszone.MooseBridgeCapturedEventForwarder or false,
  }
  if point then self:_AddPointFields(item, point) end
  return item
end

--- Forward the MOOSE OPSZONE Captured event through its public callback.
-- @param Ops.OpsZone#OPSZONE opszone OPSZONE instance.
-- @param #string zone_name Registered zone name.
-- @return #MOOSE_BRIDGE self
function MOOSE_BRIDGE:_AttachOpsZoneEventForwarder(opszone, zone_name)
  if type(opszone) ~= "table" then return self end
  if opszone.MooseBridgeCapturedEventForwarder and
     opszone.OnAfterCaptured == opszone.MooseBridgeCapturedEventForwarder then
    return self
  end
  local bridge = self
  local user_callback = opszone.OnAfterCaptured
  local forwarder = function(opszone_self, From, Event, To, Coalition)
    if type(user_callback) == "function" then
      user_callback(opszone_self, From, Event, To, Coalition)
    end
    local item = bridge:_BuildOpsZoneSnapshotItem(zone_name, opszone_self, "event")
    if item and item.object_id then
      bridge:SendEvent("opszone.owner_changed", {
        opszone_id=item.object_id,
        previous_coalition=item.owner_previous_name,
        coalition=item.owner_current_name,
        capturing_coalition=bridge:_CoalitionToName(Coalition),
        fsm_event=Event,
        from_state=From,
        to_state=To,
        opszone=item,
      })
    end
  end
  opszone.OnAfterCaptured = forwarder
  opszone.MooseBridgeCapturedEventForwarder = forwarder
  return self
end

function MOOSE_BRIDGE:BuildOpsZoneSnapshot()
  local result = {}; local seen = {}
  for name, opszone in pairs(self.RegisteredOpsZones or {}) do
    self:_AttachOpsZoneEventForwarder(opszone, name)
    local ok, item = pcall(function() return self:_BuildOpsZoneSnapshotItem(name, opszone, "registered") end)
    if ok and item and item.object_id then result[#result + 1] = item; seen[item.object_id] = true end
  end
  if _DATABASE and type(_DATABASE.OPSZONES) == "table" then
    for name, opszone in pairs(_DATABASE.OPSZONES) do
      self:_AttachOpsZoneEventForwarder(opszone, name)
      local ok, item = pcall(function() return self:_BuildOpsZoneSnapshotItem(name, opszone, "database.OPSZONES") end)
      if ok and item and item.object_id and not seen[item.object_id] then result[#result + 1] = item; seen[item.object_id] = true end
    end
  end
  return result
end

function MOOSE_BRIDGE:_CoordinateTargetFromObjectId(target_id)
  local prefix, name = bridge_split_object_id(target_id)
  if not prefix or not name then return nil, "Invalid coordinate target id " .. bridge_safe_tostring(target_id) end

  local point = nil
  if prefix == "OPSZONE" then
    point = self:_PointForOpsZoneName(name)
  elseif prefix == "SCENERY" then
    return nil, "SCENERY coordinate target resolution is not available yet"
  else
    local ok, value = pcall(function() return self:_PointForObjectId(target_id) end)
    if ok then point = value else return nil, bridge_safe_tostring(value) end
  end

  if not point then return nil, "Coordinate target point not found for " .. bridge_safe_tostring(target_id) end

  local ok_coordinate, coordinate = pcall(function() return self:_CoordinateFromPoint(point) end)
  if ok_coordinate then return coordinate, nil end
  return nil, bridge_safe_tostring(coordinate)
end

function MOOSE_BRIDGE:_ResolveCoordinateAuftragTarget(inputs)
  if inputs.target_id then
    return self:_CoordinateTargetFromObjectId(inputs.target_id)
  end
  return self:_ResolveCoordinateFromInputs(inputs)
end

function MOOSE_BRIDGE:_CommonAuftragCommandInputs(cmd)
  local p = self:_CommandParams(cmd)
  local legacy_params = type(p.params) == "table" and p.params or {}
  local inputs = {
    params=p,
    commander_id=bridge_optional_string_param(p.commander_id) or bridge_optional_string_param(legacy_params.commander_id),
    legion_id=bridge_optional_string_param(p.legion_id) or bridge_optional_string_param(legacy_params.legion_id),
    opsgroup_id=bridge_optional_string_param(p.opsgroup_id) or bridge_optional_string_param(legacy_params.opsgroup_id),
    cohort_id=bridge_optional_string_param(p.cohort_id) or bridge_optional_string_param(legacy_params.cohort_id),
    allowed_legion_ids=p.allowed_legion_ids or legacy_params.allowed_legion_ids,
    allowed_cohort_ids=p.allowed_cohort_ids or legacy_params.allowed_cohort_ids,
    clock_start=bridge_time_param(p.clock_start) or bridge_time_param(p.ClockStart) or bridge_time_param(legacy_params.clock_start) or bridge_time_param(legacy_params.ClockStart),
    clock_stop=bridge_time_param(p.clock_stop) or bridge_time_param(p.ClockStop) or bridge_time_param(legacy_params.clock_stop) or bridge_time_param(legacy_params.ClockStop),
    duration=bridge_number_param(p.duration) or bridge_number_param(p.Duration) or bridge_number_param(legacy_params.duration) or bridge_number_param(legacy_params.Duration),
    required_assets_min=bridge_number_param(p.required_assets_min) or bridge_number_param(p.nassets_min) or bridge_number_param(p.NassetsMin) or bridge_number_param(legacy_params.required_assets_min) or bridge_number_param(legacy_params.nassets_min) or bridge_number_param(legacy_params.NassetsMin),
    required_assets_max=bridge_number_param(p.required_assets_max) or bridge_number_param(p.nassets_max) or bridge_number_param(p.NassetsMax) or bridge_number_param(legacy_params.required_assets_max) or bridge_number_param(legacy_params.nassets_max) or bridge_number_param(legacy_params.NassetsMax),
    weapon_type=bridge_number_param(p.weapon_type) or bridge_number_param(p.WeaponType) or bridge_number_param(legacy_params.weapon_type) or bridge_number_param(legacy_params.WeaponType),
    target_id=bridge_optional_string_param(p.target) or bridge_optional_string_param(legacy_params.target),
    opszone_id=bridge_optional_string_param(p.opszone) or bridge_optional_string_param(p.opszone_id) or bridge_optional_string_param(legacy_params.opszone) or bridge_optional_string_param(legacy_params.opszone_id),
    capture_coalition=bridge_coalition_param(p.capture_coalition) or bridge_coalition_param(p.capture_coalition_id) or bridge_coalition_param(p.CaptureCoalition) or bridge_coalition_param(legacy_params.capture_coalition) or bridge_coalition_param(legacy_params.capture_coalition_id) or bridge_coalition_param(legacy_params.CaptureCoalition),
    stay_in_zone_time_s=bridge_number_param(p.stay_in_zone_time_s) or bridge_number_param(p.stay_in_zone_time) or bridge_number_param(p.StayInZoneTime) or bridge_number_param(legacy_params.stay_in_zone_time_s) or bridge_number_param(legacy_params.stay_in_zone_time) or bridge_number_param(legacy_params.StayInZoneTime),
    zone_id=bridge_optional_string_param(p.zone) or bridge_optional_string_param(p.zone_id) or bridge_optional_string_param(legacy_params.zone) or bridge_optional_string_param(legacy_params.zone_id),
    zones=p.zones or p.zone_ids or legacy_params.zones or legacy_params.zone_ids,
    coordinate_id=bridge_optional_string_param(p.coordinate) or bridge_optional_string_param(p.coordinate_id) or bridge_optional_string_param(legacy_params.coordinate) or bridge_optional_string_param(legacy_params.coordinate_id),
    dropoff_id=bridge_optional_string_param(p.dropoff) or bridge_optional_string_param(p.dropoff_id) or bridge_optional_string_param(legacy_params.dropoff) or bridge_optional_string_param(legacy_params.dropoff_id),
    pickup_id=bridge_optional_string_param(p.pickup) or bridge_optional_string_param(p.pickup_id) or bridge_optional_string_param(legacy_params.pickup) or bridge_optional_string_param(legacy_params.pickup_id),
    x=p.x or legacy_params.x,
    y=p.y or legacy_params.y,
    z=p.z or legacy_params.z,
    dropoff_x=p.dropoff_x or legacy_params.dropoff_x,
    dropoff_y=p.dropoff_y or legacy_params.dropoff_y,
    dropoff_z=p.dropoff_z or legacy_params.dropoff_z,
    pickup_x=p.pickup_x or legacy_params.pickup_x,
    pickup_y=p.pickup_y or legacy_params.pickup_y,
    pickup_z=p.pickup_z or legacy_params.pickup_z,
    altitude_ft=p.altitude_ft or legacy_params.altitude_ft,
    selected_payload_uid=p.selected_payload_uid or legacy_params.selected_payload_uid,
    engage_weapon_type=p.engage_weapon_type or p.EngageWeaponType or legacy_params.engage_weapon_type or legacy_params.EngageWeaponType,
    divebomb=p.divebomb,
    nshots=p.nshots or p.Nshots or legacy_params.nshots or legacy_params.Nshots,
    radius_m=p.radius_m or p.radius or p.Radius or legacy_params.radius_m or legacy_params.radius or legacy_params.Radius,
    carpet_length_m=p.carpet_length_m or p.carpet_length or p.CarpetLength or legacy_params.carpet_length_m or legacy_params.carpet_length or legacy_params.CarpetLength,
    length_m=p.length_m or p.length or p.Length or legacy_params.length_m or legacy_params.length or legacy_params.Length,
    speed_kts=p.speed_kts or p.speed or p.Speed or legacy_params.speed_kts or legacy_params.speed or legacy_params.Speed,
    formation=bridge_optional_string_param(p.formation) or bridge_optional_string_param(p.Formation) or bridge_optional_string_param(legacy_params.formation) or bridge_optional_string_param(legacy_params.Formation),
    depth_m=p.depth_m or p.depth or p.Depth or legacy_params.depth_m or legacy_params.depth or legacy_params.Depth,
    heading_deg=p.heading_deg or p.heading or p.Heading or legacy_params.heading_deg or legacy_params.heading or legacy_params.Heading,
    leg_nm=p.leg_nm or p.leg or p.Leg or legacy_params.leg_nm or legacy_params.leg or legacy_params.Leg,
    refuel_system=p.refuel_system or p.RefuelSystem or legacy_params.refuel_system or legacy_params.RefuelSystem,
    target_types=p.target_types or p.TargetTypes or legacy_params.target_types or legacy_params.TargetTypes,
    range_max_nm=p.range_max_nm or p.range_max or p.RangeMax or legacy_params.range_max_nm or legacy_params.range_max or legacy_params.RangeMax,
    orbit_distance_nm=p.orbit_distance_nm or p.orbit_distance or p.OrbitDistance or legacy_params.orbit_distance_nm or legacy_params.orbit_distance or legacy_params.OrbitDistance,
    engage_max_distance_nm=p.engage_max_distance_nm or p.engage_max_distance or p.EngageMaxDistance or legacy_params.engage_max_distance_nm or legacy_params.engage_max_distance or legacy_params.EngageMaxDistance,
    offset_x=p.offset_x or legacy_params.offset_x,
    offset_y=p.offset_y or legacy_params.offset_y,
    offset_z=p.offset_z or legacy_params.offset_z,
    transport_groups=p.transport_groups or p.transport_group or p.TransportGroups or legacy_params.transport_groups or legacy_params.transport_group or legacy_params.TransportGroups,
    pickup_radius_m=p.pickup_radius_m or p.pickup_radius or p.PickupRadius or legacy_params.pickup_radius_m or legacy_params.pickup_radius or legacy_params.PickupRadius,
    no_engage_zones=p.no_engage_zones or p.no_engage_zone or p.NoEngageZones or legacy_params.no_engage_zones or legacy_params.no_engage_zone or legacy_params.NoEngageZones,
    frequency_mhz=p.frequency_mhz or p.frequency or p.Frequency or legacy_params.frequency_mhz or legacy_params.frequency or legacy_params.Frequency,
    modulation=p.modulation or p.Modulation or legacy_params.modulation or legacy_params.Modulation,
    designation=bridge_optional_string_param(p.designation) or bridge_optional_string_param(p.Designation) or bridge_optional_string_param(legacy_params.designation) or bridge_optional_string_param(legacy_params.Designation),
    data_link=p.data_link,
    ad_infinitum=p.ad_infinitum,
    randomly=p.randomly,
  }
  if inputs.divebomb == nil then inputs.divebomb = legacy_params.divebomb end
  if inputs.data_link == nil then inputs.data_link = p.datalink end
  if inputs.data_link == nil then inputs.data_link = p.DataLink end
  if inputs.data_link == nil then inputs.data_link = legacy_params.data_link end
  if inputs.data_link == nil then inputs.data_link = legacy_params.datalink end
  if inputs.data_link == nil then inputs.data_link = legacy_params.DataLink end
  if inputs.ad_infinitum == nil then inputs.ad_infinitum = p.Adinfinitum end
  if inputs.ad_infinitum == nil then inputs.ad_infinitum = legacy_params.ad_infinitum end
  if inputs.ad_infinitum == nil then inputs.ad_infinitum = legacy_params.Adinfinitum end
  if inputs.randomly == nil then inputs.randomly = p.Randomly end
  if inputs.randomly == nil then inputs.randomly = legacy_params.randomly end
  if inputs.randomly == nil then inputs.randomly = legacy_params.Randomly end

  local target_count = (inputs.commander_id and 1 or 0) + (inputs.legion_id and 1 or 0) + (inputs.opsgroup_id and 1 or 0)
  if target_count ~= 1 then error("Specify exactly one of commander_id, legion_id or opsgroup_id; " .. bridge_param_debug(cmd, p)) end

  inputs.allowed_legion_ids = self:_NormalizeStringList(inputs.allowed_legion_ids) or {}
  inputs.allowed_cohort_ids = self:_NormalizeStringList(inputs.allowed_cohort_ids) or {}
  if inputs.cohort_id then inputs.allowed_cohort_ids[#inputs.allowed_cohort_ids + 1] = inputs.cohort_id end
  if inputs.opsgroup_id and (#inputs.allowed_legion_ids > 0 or #inputs.allowed_cohort_ids > 0) then
    error("LEGION or COHORT constraints cannot be used with opsgroup_id")
  end
  if inputs.legion_id and #inputs.allowed_legion_ids > 0 then
    error("allowed_legion_ids requires commander_id")
  end

  if inputs.commander_id then
    local commander, commander_err = self:_ResolveCommanderById(inputs.commander_id)
    if not commander then error(commander_err) end
    inputs.commander = commander
  end

  if inputs.legion_id then
    local legion, legion_err = self:_ResolveLegionById(inputs.legion_id)
    if not legion then error(legion_err) end
    inputs.legion = legion
  end

  if inputs.opsgroup_id then
    local opsgroup, opsgroup_err = self:_ResolveOpsGroupById(inputs.opsgroup_id)
    if not opsgroup then error(opsgroup_err) end
    inputs.opsgroup = opsgroup
  end

  inputs.allowed_legions = {}
  for _, legion_id in ipairs(inputs.allowed_legion_ids) do
    local legion, legion_err = self:_ResolveLegionById(legion_id)
    if not legion then error(legion_err) end
    inputs.allowed_legions[#inputs.allowed_legions + 1] = legion
  end
  inputs.allowed_cohorts = {}
  for _, cohort_id in ipairs(inputs.allowed_cohort_ids) do
    local cohort, cohort_err = self:_ResolveCohortById(cohort_id)
    if not cohort then error(cohort_err) end
    inputs.allowed_cohorts[#inputs.allowed_cohorts + 1] = cohort
  end

  return inputs
end

function MOOSE_BRIDGE:_ResolveObjectAuftragTarget(inputs)
  if not inputs.target_id then return nil, "Missing target" end
  return self:_ResolveAuftragTargetById(inputs.target_id)
end

function MOOSE_BRIDGE:_ResolveGroupAuftragTarget(inputs)
  if not inputs.target_id then return nil, "Missing target" end
  local prefix = bridge_split_object_id(inputs.target_id)
  if prefix ~= "GROUP" then return nil, "Target must be GROUP:<name>" end
  return self:_ResolveAuftragTargetById(inputs.target_id)
end

function MOOSE_BRIDGE:_ResolveGroupOrUnitAuftragTarget(inputs)
  if not inputs.target_id then return nil, "Missing target" end
  local prefix = bridge_split_object_id(inputs.target_id)
  if prefix ~= "GROUP" and prefix ~= "UNIT" then return nil, "Target must be GROUP:<name> or UNIT:<name>" end
  return self:_ResolveAuftragTargetById(inputs.target_id)
end

function MOOSE_BRIDGE:_ResolvePositionableAttackAuftragTarget(inputs)
  if not inputs.target_id then return nil, "Missing target" end
  local prefix = bridge_split_object_id(inputs.target_id)
  if prefix ~= "GROUP" and prefix ~= "UNIT" and prefix ~= "STATIC" then return nil, "Target must be GROUP:<name>, UNIT:<name> or STATIC:<name>" end
  return self:_ResolveAuftragTargetById(inputs.target_id)
end

function MOOSE_BRIDGE:_ResolveUnitAuftragTarget(inputs)
  if not inputs.target_id then return nil, "Missing target" end
  local prefix = bridge_split_object_id(inputs.target_id)
  if prefix ~= "UNIT" then return nil, "Target must be UNIT:<name>" end
  return self:_ResolveAuftragTargetById(inputs.target_id)
end

function MOOSE_BRIDGE:_ResolveAirbaseAuftragTarget(inputs)
  if not inputs.target_id then return nil, "Missing target" end
  local prefix, name = bridge_split_object_id(inputs.target_id)
  if prefix ~= "AIRBASE" then return nil, "BOMBRUNWAY target must be AIRBASE:<name>" end

  if AIRBASE and AIRBASE.FindByName then
    local ok, airbase = pcall(function() return AIRBASE:FindByName(name) end)
    if ok and airbase then return airbase, nil end
  end

  return nil, "AIRBASE target not found: " .. bridge_safe_tostring(name)
end

function MOOSE_BRIDGE:_ResolveBombingTarget(inputs)
  return self:_ResolveCoordinateAuftragTarget(inputs)
end

function MOOSE_BRIDGE:_ResolveBombCarpetTarget(inputs)
  if inputs.target_id then
    local prefix = bridge_split_object_id(inputs.target_id)
    if prefix ~= "GROUP" and prefix ~= "UNIT" and prefix ~= "STATIC" then
      return nil, "BOMBCARPET target must be GROUP:<name>, UNIT:<name>, STATIC:<name> or direct x/z coordinates"
    end
  end
  return self:_ResolveCoordinateAuftragTarget(inputs)
end

function MOOSE_BRIDGE:_ResolveStrafingTarget(inputs)
  if inputs.target_id then
    local prefix = bridge_split_object_id(inputs.target_id)
    if prefix ~= "GROUP" and prefix ~= "UNIT" and prefix ~= "STATIC" then
      return nil, "STRAFING target must be GROUP:<name>, UNIT:<name>, STATIC:<name> or direct x/z coordinates"
    end
  end
  return self:_ResolveCoordinateAuftragTarget(inputs)
end

function MOOSE_BRIDGE:_ResolveArtyTarget(inputs)
  return self:_ResolveCoordinateAuftragTarget(inputs)
end

function MOOSE_BRIDGE:_ResolveStrikeTarget(inputs)
  return self:_ResolveCoordinateAuftragTarget(inputs)
end

function MOOSE_BRIDGE:_ResolveOrbitTarget(inputs)
  return self:_ResolveCoordinateAuftragTarget(inputs)
end

function MOOSE_BRIDGE:_ResolveOnGuardTarget(inputs)
  return self:_ResolveCoordinateAuftragTarget(inputs)
end

function MOOSE_BRIDGE:_ResolveZonePatrolZone(inputs)
  if not inputs.zone_id then return nil, "Missing zone" end
  local ok, zone = pcall(function() return self:_ZoneForDrawObjectId(inputs.zone_id) end)
  if ok and zone then return zone, nil end
  return nil, bridge_safe_tostring(zone)
end

function MOOSE_BRIDGE:_ResolveCaptureOpsZone(inputs)
  local opszone_id = inputs.opszone_id or inputs.zone_id or inputs.target_id
  if not opszone_id then return nil, "Missing opszone" end
  local prefix, name = bridge_split_object_id(opszone_id)
  if prefix ~= "OPSZONE" then return nil, "CAPTUREZONE requires OPSZONE:<name>, got " .. bridge_safe_tostring(opszone_id) end

  local opszone = self.RegisteredOpsZones and self.RegisteredOpsZones[name]
  if not opszone and _DATABASE and type(_DATABASE.OPSZONES) == "table" then opszone = _DATABASE.OPSZONES[name] end
  if not opszone then return nil, "OPSZONE not found: " .. bridge_safe_tostring(opszone_id) end
  inputs.opszone_id = opszone_id
  return opszone, nil
end

function MOOSE_BRIDGE:_ResolveZonePatrolCoordinate(inputs)
  if inputs.coordinate_id then
    return self:_CoordinateTargetFromObjectId(inputs.coordinate_id)
  end
  if inputs.x ~= nil or inputs.z ~= nil then
    return self:_ResolveCoordinateFromInputs(inputs)
  end
  return nil, nil
end

function MOOSE_BRIDGE:_NormalizeTargetTypes(value)
  if type(value) == "table" then return value end
  if type(value) ~= "string" or value == "" then return nil end

  local result = {}
  for item in string.gmatch(value, "([^,]+)") do
    item = item:gsub("^%s+", ""):gsub("%s+$", "")
    if item ~= "" then result[#result + 1] = item end
  end
  if #result > 0 then return result end
  return nil
end

function MOOSE_BRIDGE:_BuildOffsetVector(inputs)
  if inputs.offset_x == nil and inputs.offset_y == nil and inputs.offset_z == nil then return nil end
  return {
    x=inputs.offset_x ~= nil and tonumber(inputs.offset_x) or 0,
    y=inputs.offset_y ~= nil and tonumber(inputs.offset_y) or 0,
    z=inputs.offset_z ~= nil and tonumber(inputs.offset_z) or 0,
  }
end

function MOOSE_BRIDGE:_ResolveCoordinateFromNamedFields(object_id, x_value, y_value, z_value, label, required)
  if object_id then
    return self:_CoordinateTargetFromObjectId(object_id)
  end
  if x_value ~= nil or z_value ~= nil then
    return self:_ResolveCoordinateFromInputs({x=x_value, y=y_value, z=z_value})
  end
  if required then return nil, label .. " coordinate requires object id or numeric x and z" end
  return nil, nil
end

function MOOSE_BRIDGE:_NormalizeStringList(value)
  if type(value) == "table" then return value end
  if type(value) ~= "string" or value == "" then return nil end

  local result = {}
  for item in string.gmatch(value, "([^,]+)") do
    item = item:gsub("^%s+", ""):gsub("%s+$", "")
    if item ~= "" then result[#result + 1] = item end
  end
  if #result > 0 then return result end
  return nil
end

function MOOSE_BRIDGE:_BuildGroupSet(value)
  local group_ids = self:_NormalizeStringList(value)
  if not group_ids or #group_ids == 0 then error("TransportGroupSet requires at least one GROUP") end
  if not SET_GROUP or not SET_GROUP.New then error("SET_GROUP:New is not available") end

  local set_group = SET_GROUP:New()
  for _, group_id in ipairs(group_ids) do
    local inputs = {target_id=group_id}
    local group, group_err = self:_ResolveGroupAuftragTarget(inputs)
    if not group then error(group_err) end

    if type(set_group.AddGroup) == "function" then
      set_group:AddGroup(group)
    elseif type(set_group.Add) == "function" then
      set_group:Add(group)
    elseif type(set_group.AddObject) == "function" then
      set_group:AddObject(group)
    else
      error("SET_GROUP add method is not available")
    end
  end

  return set_group, group_ids
end

function MOOSE_BRIDGE:_CallAuftragLifecycleMethod(cmd, action, method_name)
  local auftrag_id = self:_CommandAuftragId(cmd)
  local auftrag, auftrag_err = self:_ResolveTrackedAuftragById(auftrag_id)
  if not auftrag then error(auftrag_err) end
  if type(auftrag[method_name]) ~= "function" then error("AUFTRAG:" .. method_name .. " is not available for " .. bridge_safe_tostring(auftrag_id)) end

  local ok, result = pcall(function() return auftrag[method_name](auftrag) end)
  if not ok then error("AUFTRAG:" .. method_name .. " failed: " .. bridge_safe_tostring(result)) end
  self:_TrackAuftragReference(auftrag)

  return {
    action=action,
    auftrag_id=auftrag_id,
    auftragsnummer=self:_AuftragNumber(auftrag),
    auftrag_type=self:_SafeCall(auftrag, "GetType") or auftrag.type,
    status=self:_SafeCall(auftrag, "GetState") or self:_SafeCall(auftrag, "GetStatus"),
  }
end

function MOOSE_BRIDGE:_AssignTrackedAuftrag(cmd)
  local inputs = self:_CommonAuftragCommandInputs(cmd)
  local auftrag_id = self:_CommandAuftragId(cmd)
  local auftrag, auftrag_err = self:_ResolveTrackedAuftragById(auftrag_id)
  if not auftrag then error(auftrag_err) end

  self:_AddAuftragToTarget(auftrag, inputs)
  return self:_BuildAuftragCommandResult("auftrag.assign", auftrag, inputs)
end

function MOOSE_BRIDGE:_SetCohortWeaponRange(cmd)
  local p = self:_CommandParams(cmd)
  local cohort_id = bridge_optional_string_param(p.cohort_id)
  local weapon_type = bridge_number_param(p.weapon_type)
  local minimum_m = bridge_number_param(p.minimum_m)
  local maximum_m = bridge_number_param(p.maximum_m)
  if not cohort_id then error("cohort.set_weapon_range requires cohort_id") end
  if weapon_type == nil then error("cohort.set_weapon_range requires weapon_type") end
  if minimum_m == nil then minimum_m = 0 end
  if maximum_m == nil or maximum_m <= 0 then error("cohort.set_weapon_range requires positive maximum_m") end
  if minimum_m < 0 or minimum_m > maximum_m then error("Invalid cohort weapon range") end

  local cohort, cohort_err = self:_ResolveCohortById(cohort_id)
  if not cohort then error(cohort_err) end
  if type(cohort.AddWeaponRange) ~= "function" then error("COHORT:AddWeaponRange is not available") end

  local previous = type(cohort.weaponData) == "table" and cohort.weaponData[bridge_safe_tostring(weapon_type)] or nil
  local ok, err = pcall(function()
    return cohort:AddWeaponRange(minimum_m / 1852, maximum_m / 1852, weapon_type)
  end)
  if not ok then error("COHORT:AddWeaponRange failed: " .. bridge_safe_tostring(err)) end

  return {
    action="cohort.set_weapon_range",
    cohort_id=cohort_id,
    weapon_type=weapon_type,
    minimum_m=minimum_m,
    maximum_m=maximum_m,
    previous_minimum_m=previous and previous.RangeMin or nil,
    previous_maximum_m=previous and previous.RangeMax or nil,
    mission_range_m=self:_SafeCallArg(cohort, "GetMissionRange", {weapon_type}),
  }
end

function MOOSE_BRIDGE:_BuildZoneSet(value, label, required)
  local zone_ids = self:_NormalizeStringList(value)
  if not zone_ids or #zone_ids == 0 then
    if required then error(label .. " requires at least one ZONE") end
    return nil, nil
  end
  if not SET_ZONE or not SET_ZONE.New then error("SET_ZONE:New is not available") end

  local set_zone = SET_ZONE:New()
  for _, zone_id in ipairs(zone_ids) do
    local ok_zone, zone = pcall(function() return self:_ZoneForDrawObjectId(zone_id) end)
    if not ok_zone or not zone then error(label .. " zone not found: " .. bridge_safe_tostring(zone_id)) end

    if type(set_zone.AddZone) == "function" then
      set_zone:AddZone(zone)
    elseif type(set_zone.Add) == "function" then
      set_zone:Add(zone)
    elseif type(set_zone.AddObject) == "function" then
      set_zone:AddObject(zone)
    else
      error("SET_ZONE add method is not available")
    end
  end

  return set_zone, zone_ids
end

function MOOSE_BRIDGE:_BuildNoEngageZoneSet(value)
  return self:_BuildZoneSet(value, "NoEngage", false)
end

function MOOSE_BRIDGE:_AddAuftragToLegion(auftrag, inputs)
  if not auftrag then error("AUFTRAG constructor returned nil") end
  self:_ApplyAuftragAssignments(auftrag, inputs)
  self:_ApplyAuftragTiming(auftrag, inputs)
  self:_RegisterAuftragEvents(auftrag, inputs)
  self:_SendAuftragStatusEvent(auftrag, inputs, "Planned")
  local add_ok, add_result = pcall(function() return inputs.legion:AddMission(auftrag) end)
  if not add_ok then error("LEGION:AddMission failed: " .. bridge_safe_tostring(add_result)) end
  self:_TrackAuftragReference(auftrag)
  return auftrag
end

function MOOSE_BRIDGE:_AddAuftragToCommander(auftrag, inputs)
  if not auftrag then error("AUFTRAG constructor returned nil") end
  if type(inputs.commander.AddMission) ~= "function" then error("COMMANDER:AddMission is not available") end
  self:_ApplyAuftragAssignments(auftrag, inputs)
  self:_ApplyAuftragTiming(auftrag, inputs)
  self:_RegisterAuftragEvents(auftrag, inputs)
  self:_SendAuftragStatusEvent(auftrag, inputs, "Planned")
  local add_ok, add_result = pcall(function() return inputs.commander:AddMission(auftrag) end)
  if not add_ok then error("COMMANDER:AddMission failed: " .. bridge_safe_tostring(add_result)) end
  self:_TrackAuftragReference(auftrag)
  return auftrag
end

function MOOSE_BRIDGE:_AddAuftragToOpsGroup(auftrag, inputs)
  if not auftrag then error("AUFTRAG constructor returned nil") end
  if type(inputs.opsgroup.AddMission) ~= "function" then error("OPSGROUP:AddMission is not available") end
  self:_ApplyAuftragTiming(auftrag, inputs)
  self:_RegisterAuftragEvents(auftrag, inputs)
  self:_SendAuftragStatusEvent(auftrag, inputs, "Planned")
  local add_ok, add_result = pcall(function() return inputs.opsgroup:AddMission(auftrag) end)
  if not add_ok then error("OPSGROUP:AddMission failed: " .. bridge_safe_tostring(add_result)) end
  self:_TrackAuftragReference(auftrag)
  return auftrag
end

function MOOSE_BRIDGE:_ApplyAuftragAssignments(auftrag, inputs)
  if not auftrag or not inputs then return auftrag end
  for _, legion in ipairs(inputs.allowed_legions or {}) do
    if type(auftrag.AssignLegion) ~= "function" then error("AUFTRAG:AssignLegion is not available") end
    local ok, err = pcall(function() return auftrag:AssignLegion(legion) end)
    if not ok then error("AUFTRAG:AssignLegion failed: " .. bridge_safe_tostring(err)) end
  end
  for _, cohort in ipairs(inputs.allowed_cohorts or {}) do
    if type(auftrag.AssignCohort) ~= "function" then error("AUFTRAG:AssignCohort is not available") end
    local ok, err = pcall(function() return auftrag:AssignCohort(cohort) end)
    if not ok then error("AUFTRAG:AssignCohort failed: " .. bridge_safe_tostring(err)) end
  end
  return auftrag
end

function MOOSE_BRIDGE:_ApplyAuftragTiming(auftrag, inputs)
  if not auftrag or not inputs then return auftrag end

  if inputs.clock_start ~= nil or inputs.clock_stop ~= nil then
    if type(auftrag.SetTime) ~= "function" then error("AUFTRAG:SetTime is not available") end
    local time_ok, time_err = pcall(function() return auftrag:SetTime(inputs.clock_start, inputs.clock_stop) end)
    if not time_ok then error("AUFTRAG:SetTime failed: " .. bridge_safe_tostring(time_err)) end
  end

  if inputs.duration ~= nil then
    if type(auftrag.SetDuration) ~= "function" then error("AUFTRAG:SetDuration is not available") end
    local duration_ok, duration_err = pcall(function() return auftrag:SetDuration(inputs.duration) end)
    if not duration_ok then error("AUFTRAG:SetDuration failed: " .. bridge_safe_tostring(duration_err)) end
  end

  if inputs.required_assets_min ~= nil or inputs.required_assets_max ~= nil then
    if type(auftrag.SetRequiredAssets) ~= "function" then error("AUFTRAG:SetRequiredAssets is not available") end
    local nassets_min = inputs.required_assets_min
    if nassets_min == nil then nassets_min = 1 end
    local assets_ok, assets_err = pcall(function() return auftrag:SetRequiredAssets(nassets_min, inputs.required_assets_max) end)
    if not assets_ok then error("AUFTRAG:SetRequiredAssets failed: " .. bridge_safe_tostring(assets_err)) end
  end

  if inputs.weapon_type ~= nil then
    if type(auftrag.SetWeaponType) ~= "function" then error("AUFTRAG:SetWeaponType is not available") end
    local weapon_ok, weapon_err = pcall(function() return auftrag:SetWeaponType(inputs.weapon_type) end)
    if not weapon_ok then error("AUFTRAG:SetWeaponType failed: " .. bridge_safe_tostring(weapon_err)) end
  end

  return auftrag
end

function MOOSE_BRIDGE:_SendAuftragStatusEvent(auftrag, inputs, fsm_event, From, Event, To)
  if type(auftrag) ~= "table" then return end
  local object_id = self:_AuftragObjectId(auftrag)
  local ok, err = pcall(function()
    self:SendEvent("auftrag.status", {
      auftrag_id=object_id,
      auftragsnummer=self:_AuftragNumber(auftrag),
      auftrag_type=self:_SafeCall(auftrag, "GetType") or auftrag.type,
      status=self:_SafeCall(auftrag, "GetState") or self:_SafeCall(auftrag, "GetStatus") or To,
      fsm_event=fsm_event,
      from=From,
      fsm_event_name=Event,
      to=To,
      commander_id=inputs and inputs.commander_id or nil,
      legion_id=inputs and inputs.legion_id or nil,
      opsgroup_id=inputs and inputs.opsgroup_id or nil,
      cohort_id=inputs and inputs.cohort_id or nil,
      target=inputs and (inputs.target_id or inputs.zone_id) or nil,
    })
  end)
  if not ok and env and env.error then env.error("MooseBridge AUFTRAG status event failed: " .. bridge_safe_tostring(err)) end
end

function MOOSE_BRIDGE:_SendAuftragEvaluatedEvent(auftrag, inputs, From, Event, To, Summary)
  if type(auftrag) ~= "table" then return end
  local summary = bridge_auftrag_summary(Summary)
  local object_id = self:_AuftragObjectId(auftrag)
  local ok, err = pcall(function()
    self:SendEvent("auftrag.evaluated", {
      auftrag_id=object_id,
      auftragsnummer=self:_AuftragNumber(auftrag),
      auftrag_type=self:_SafeCall(auftrag, "GetType") or auftrag.type,
      status=self:_SafeCall(auftrag, "GetState") or self:_SafeCall(auftrag, "GetStatus") or To,
      fsm_event="Evaluated",
      from=From,
      fsm_event_name=Event,
      to=To,
      commander_id=inputs and inputs.commander_id or nil,
      legion_id=inputs and inputs.legion_id or nil,
      opsgroup_id=inputs and inputs.opsgroup_id or nil,
      cohort_id=inputs and inputs.cohort_id or nil,
      target=inputs and (inputs.target_id or inputs.zone_id) or nil,
      zones=inputs and inputs.zones or nil,
      summary=summary,
      auftrag={
        object_id=object_id,
        auftragsnummer=self:_AuftragNumber(auftrag),
        type=self:_SafeCall(auftrag, "GetType") or auftrag.type,
        status=self:_SafeCall(auftrag, "GetState") or self:_SafeCall(auftrag, "GetStatus") or To,
        zones=inputs and inputs.zones or nil,
        summary_available=summary ~= nil,
        summary=summary,
      },
    })
  end)
  if not ok and env and env.error then env.error("MooseBridge OnAfterEvaluated send failed: " .. bridge_safe_tostring(err)) end
end

function MOOSE_BRIDGE:_RegisterAuftragEvents(auftrag, inputs)
  if type(auftrag) ~= "table" then return end
  if auftrag.MooseBridgeEvaluatedEventRegistered then return end

  local bridge = self
  auftrag.MooseBridgeEvaluatedEventRegistered = true
  local sent_status_events = {}

  local function register_after_event(method_event, output_event)
    output_event = output_event or method_event
    local method_name = "OnAfter" .. method_event
    local previous_handler = auftrag[method_name]
    auftrag[method_name] = function(auftrag_object, From, Event, To, ...)
      local extra = {...}
      if type(previous_handler) == "function" then
        pcall(function() previous_handler(auftrag_object, From, Event, To, bridge_unpack(extra)) end)
      end

      if output_event == "Evaluated" then
        bridge:_SendAuftragEvaluatedEvent(auftrag_object, inputs, From, Event, To, extra[1])
        return
      end

      if sent_status_events[output_event] then return end
      sent_status_events[output_event] = true
      bridge:_SendAuftragStatusEvent(auftrag_object, inputs, output_event, From, Event, To)
    end
  end

  register_after_event("Queued")
  register_after_event("Requested")
  register_after_event("Scheduled")
  register_after_event("Started")
  register_after_event("Executing")
  register_after_event("Done")
  register_after_event("Cancel")
  register_after_event("Evaluated")
end

function MOOSE_BRIDGE:_AddAuftragToTarget(auftrag, inputs)
  if inputs.opsgroup then return self:_AddAuftragToOpsGroup(auftrag, inputs) end
  if inputs.commander then return self:_AddAuftragToCommander(auftrag, inputs) end
  return self:_AddAuftragToLegion(auftrag, inputs)
end

function MOOSE_BRIDGE:_BuildAuftragCommandResult(action, auftrag, inputs)
  return {
    action=action,
    commander_id=inputs.commander_id,
    legion_id=inputs.legion_id,
    opsgroup_id=inputs.opsgroup_id,
    cohort_id=inputs.cohort_id,
    allowed_legion_ids=inputs.allowed_legion_ids,
    allowed_cohort_ids=inputs.allowed_cohort_ids,
    clock_start=inputs.clock_start,
    clock_stop=inputs.clock_stop,
    duration=inputs.duration,
    required_assets_min=inputs.required_assets_min,
    required_assets_max=inputs.required_assets_max,
    weapon_type=inputs.weapon_type,
    target=inputs.target_id,
    opszone=inputs.opszone_id,
    capture_coalition=inputs.capture_coalition,
    stay_in_zone_time_s=inputs.stay_in_zone_time_s,
    zone=inputs.zone_id,
    zones=inputs.zones,
    coordinate=inputs.coordinate_id,
    dropoff=inputs.dropoff_id,
    pickup=inputs.pickup_id,
    x=inputs.x,
    y=inputs.y,
    z=inputs.z,
    dropoff_x=inputs.dropoff_x,
    dropoff_y=inputs.dropoff_y,
    dropoff_z=inputs.dropoff_z,
    pickup_x=inputs.pickup_x,
    pickup_y=inputs.pickup_y,
    pickup_z=inputs.pickup_z,
    altitude_ft=inputs.altitude_ft,
    engage_weapon_type=inputs.engage_weapon_type,
    divebomb=inputs.divebomb,
    nshots=inputs.nshots,
    radius_m=inputs.radius_m,
    carpet_length_m=inputs.carpet_length_m,
    length_m=inputs.length_m,
    speed_kts=inputs.speed_kts,
    ad_infinitum=inputs.ad_infinitum,
    randomly=inputs.randomly,
    formation=inputs.formation,
    depth_m=inputs.depth_m,
    heading_deg=inputs.heading_deg,
    leg_nm=inputs.leg_nm,
    refuel_system=inputs.refuel_system,
    range_max_nm=inputs.range_max_nm,
    no_engage_zones=inputs.no_engage_zones,
    frequency_mhz=inputs.frequency_mhz,
    modulation=inputs.modulation,
    designation=inputs.designation,
    data_link=inputs.data_link,
    target_types=inputs.target_types,
    orbit_distance_nm=inputs.orbit_distance_nm,
    engage_max_distance_nm=inputs.engage_max_distance_nm,
    offset_x=inputs.offset_x,
    offset_y=inputs.offset_y,
    offset_z=inputs.offset_z,
    transport_groups=inputs.transport_groups,
    pickup_radius_m=inputs.pickup_radius_m,
    selected_payload_uid=inputs.selected_payload_uid,
    auftrag_id=self:_AuftragObjectId(auftrag),
    auftragsnummer=self:_AuftragNumber(auftrag),
    auftrag_type=self:_SafeCall(auftrag, "GetType") or auftrag.type,
    added=true,
  }
end

function MOOSE_BRIDGE:_CreateZonePatrolAuftrag(cmd, action, constructor_name)
  local inputs = self:_CommonAuftragCommandInputs(cmd)
  local zone, zone_err = self:_ResolveZonePatrolZone(inputs)
  if not zone then error(zone_err) end

  local coordinate, coordinate_err = self:_ResolveZonePatrolCoordinate(inputs)
  if coordinate_err then error(coordinate_err) end

  if not AUFTRAG or type(AUFTRAG[constructor_name]) ~= "function" then error("AUFTRAG:" .. constructor_name .. " is not available") end

  local altitude_ft = inputs.altitude_ft and tonumber(inputs.altitude_ft) or nil
  local speed_kts = inputs.speed_kts and tonumber(inputs.speed_kts) or nil
  local heading_deg = inputs.heading_deg and tonumber(inputs.heading_deg) or nil
  local leg_nm = inputs.leg_nm and tonumber(inputs.leg_nm) or nil
  local target_types = self:_NormalizeTargetTypes(inputs.target_types)
  inputs.target_types = target_types

  local auftrag = AUFTRAG[constructor_name](AUFTRAG, zone, altitude_ft, speed_kts, coordinate, heading_deg, leg_nm, target_types)

  self:_AddAuftragToTarget(auftrag, inputs)
  return self:_BuildAuftragCommandResult(action, auftrag, inputs)
end

function MOOSE_BRIDGE:_CreateOrbitRoleAuftrag(cmd, action, constructor_name, include_refuel_system)
  local inputs = self:_CommonAuftragCommandInputs(cmd)
  local target, target_err = self:_ResolveOrbitTarget(inputs)
  if not target then error(target_err) end

  if not AUFTRAG or type(AUFTRAG[constructor_name]) ~= "function" then error("AUFTRAG:" .. constructor_name .. " is not available") end

  local altitude_ft = inputs.altitude_ft and tonumber(inputs.altitude_ft) or nil
  local speed_kts = inputs.speed_kts and tonumber(inputs.speed_kts) or nil
  local heading_deg = inputs.heading_deg and tonumber(inputs.heading_deg) or nil
  local leg_nm = inputs.leg_nm and tonumber(inputs.leg_nm) or nil
  local refuel_system = include_refuel_system and inputs.refuel_system and tonumber(inputs.refuel_system) or nil
  local auftrag = nil

  if include_refuel_system then
    auftrag = AUFTRAG[constructor_name](AUFTRAG, target, altitude_ft, speed_kts, heading_deg, leg_nm, refuel_system)
  else
    auftrag = AUFTRAG[constructor_name](AUFTRAG, target, altitude_ft, speed_kts, heading_deg, leg_nm)
  end

  self:_AddAuftragToTarget(auftrag, inputs)
  return self:_BuildAuftragCommandResult(action, auftrag, inputs)
end

function MOOSE_BRIDGE:_CreateCasEnhancedAuftrag(cmd)
  local inputs = self:_CommonAuftragCommandInputs(cmd)
  local zone, zone_err = self:_ResolveZonePatrolZone(inputs)
  if not zone then error(zone_err) end

  if not AUFTRAG or not AUFTRAG.NewCASENHANCED then error("AUFTRAG:NewCASENHANCED is not available") end

  local altitude_ft = inputs.altitude_ft and tonumber(inputs.altitude_ft) or nil
  local speed_kts = inputs.speed_kts and tonumber(inputs.speed_kts) or nil
  local range_max_nm = inputs.range_max_nm and tonumber(inputs.range_max_nm) or nil
  local no_engage_zone_set = self:_BuildNoEngageZoneSet(inputs.no_engage_zones)
  local target_types = self:_NormalizeTargetTypes(inputs.target_types)
  inputs.no_engage_zones = self:_NormalizeStringList(inputs.no_engage_zones)
  inputs.target_types = target_types

  local auftrag = AUFTRAG:NewCASENHANCED(zone, altitude_ft, speed_kts, range_max_nm, no_engage_zone_set, target_types)

  self:_AddAuftragToTarget(auftrag, inputs)
  return self:_BuildAuftragCommandResult("auftrag.create_casenhanced", auftrag, inputs)
end

function MOOSE_BRIDGE:_CreateFacAuftrag(cmd)
  local inputs = self:_CommonAuftragCommandInputs(cmd)
  local zone, zone_err = self:_ResolveZonePatrolZone(inputs)
  if not zone then error(zone_err) end

  if not AUFTRAG or not AUFTRAG.NewFAC then error("AUFTRAG:NewFAC is not available") end

  local speed_kts = inputs.speed_kts and tonumber(inputs.speed_kts) or nil
  local altitude_ft = inputs.altitude_ft and tonumber(inputs.altitude_ft) or nil
  local frequency_mhz = inputs.frequency_mhz and tonumber(inputs.frequency_mhz) or nil
  local modulation = inputs.modulation and tonumber(inputs.modulation) or nil

  local auftrag = AUFTRAG:NewFAC(zone, speed_kts, altitude_ft, frequency_mhz, modulation)

  self:_AddAuftragToTarget(auftrag, inputs)
  return self:_BuildAuftragCommandResult("auftrag.create_fac", auftrag, inputs)
end

function MOOSE_BRIDGE:_CreatePatrolZoneAuftrag(cmd)
  local inputs = self:_CommonAuftragCommandInputs(cmd)
  local zone, zone_err = self:_ResolveZonePatrolZone(inputs)
  if not zone then error(zone_err) end

  if not AUFTRAG or not AUFTRAG.NewPATROLZONE then error("AUFTRAG:NewPATROLZONE is not available") end

  local speed_kts = inputs.speed_kts and tonumber(inputs.speed_kts) or nil
  local altitude_ft = inputs.altitude_ft and tonumber(inputs.altitude_ft) or nil
  local auftrag = AUFTRAG:NewPATROLZONE(zone, speed_kts, altitude_ft, inputs.formation)

  self:_AddAuftragToTarget(auftrag, inputs)
  return self:_BuildAuftragCommandResult("auftrag.create_patrolzone", auftrag, inputs)
end

function MOOSE_BRIDGE:_CreateReconAuftrag(cmd)
  local inputs = self:_CommonAuftragCommandInputs(cmd)
  local zone_set, zone_ids = self:_BuildZoneSet(inputs.zones, "RECON", true)
  inputs.zones = zone_ids

  if not AUFTRAG or not AUFTRAG.NewRECON then error("AUFTRAG:NewRECON is not available") end
  local speed_kts = inputs.speed_kts and tonumber(inputs.speed_kts) or nil
  local altitude_ft = inputs.altitude_ft and tonumber(inputs.altitude_ft) or nil
  local auftrag = AUFTRAG:NewRECON(
    zone_set,
    speed_kts,
    altitude_ft,
    inputs.ad_infinitum,
    inputs.randomly,
    inputs.formation
  )

  self:_AddAuftragToTarget(auftrag, inputs)
  return self:_BuildAuftragCommandResult("auftrag.create_recon", auftrag, inputs)
end

function MOOSE_BRIDGE:_CreateCaptureZoneAuftrag(cmd)
  local inputs = self:_CommonAuftragCommandInputs(cmd)
  local opszone, opszone_err = self:_ResolveCaptureOpsZone(inputs)
  if not opszone then error(opszone_err) end
  if inputs.capture_coalition == nil then error("CAPTUREZONE requires capture_coalition") end

  if not AUFTRAG or not AUFTRAG.NewCAPTUREZONE then error("AUFTRAG:NewCAPTUREZONE is not available") end

  local speed_kts = inputs.speed_kts and tonumber(inputs.speed_kts) or nil
  local altitude_ft = inputs.altitude_ft and tonumber(inputs.altitude_ft) or nil
  local stay_in_zone_time_s = inputs.stay_in_zone_time_s and tonumber(inputs.stay_in_zone_time_s) or nil
  local auftrag = AUFTRAG:NewCAPTUREZONE(opszone, inputs.capture_coalition, speed_kts, altitude_ft, inputs.formation, stay_in_zone_time_s)

  self:_AddAuftragToTarget(auftrag, inputs)
  return self:_BuildAuftragCommandResult("auftrag.create_capturezone", auftrag, inputs)
end

function MOOSE_BRIDGE:_CreateZoneOnlyAuftrag(cmd, action, constructor_name)
  local inputs = self:_CommonAuftragCommandInputs(cmd)
  local zone, zone_err = self:_ResolveZonePatrolZone(inputs)
  if not zone then error(zone_err) end

  if not AUFTRAG or type(AUFTRAG[constructor_name]) ~= "function" then error("AUFTRAG:" .. constructor_name .. " is not available") end

  local auftrag = AUFTRAG[constructor_name](AUFTRAG, zone)

  self:_AddAuftragToTarget(auftrag, inputs)
  return self:_BuildAuftragCommandResult(action, auftrag, inputs)
end

function MOOSE_BRIDGE:_CreateFacaAuftrag(cmd)
  local inputs = self:_CommonAuftragCommandInputs(cmd)
  local target, target_err = self:_ResolveGroupAuftragTarget(inputs)
  if not target then error(target_err) end

  if not AUFTRAG or not AUFTRAG.NewFACA then error("AUFTRAG:NewFACA is not available") end

  local data_link = bridge_bool_param(inputs.data_link)
  local frequency_mhz = inputs.frequency_mhz and tonumber(inputs.frequency_mhz) or nil
  local modulation = inputs.modulation and tonumber(inputs.modulation) or nil

  local auftrag = AUFTRAG:NewFACA(target, inputs.designation, data_link, frequency_mhz, modulation)

  self:_AddAuftragToTarget(auftrag, inputs)
  return self:_BuildAuftragCommandResult("auftrag.create_faca", auftrag, inputs)
end

function MOOSE_BRIDGE:_CreateSeadAuftrag(cmd)
  local inputs = self:_CommonAuftragCommandInputs(cmd)
  local target, target_err = self:_ResolveGroupOrUnitAuftragTarget(inputs)
  if not target then error(target_err) end

  if not AUFTRAG or not AUFTRAG.NewSEAD then error("AUFTRAG:NewSEAD is not available") end

  local altitude_ft = inputs.altitude_ft and tonumber(inputs.altitude_ft) or nil
  local auftrag = AUFTRAG:NewSEAD(target, altitude_ft)

  self:_AddAuftragToTarget(auftrag, inputs)
  return self:_BuildAuftragCommandResult("auftrag.create_sead", auftrag, inputs)
end

function MOOSE_BRIDGE:_CreateAntiShipAuftrag(cmd)
  local inputs = self:_CommonAuftragCommandInputs(cmd)
  local target, target_err = self:_ResolveGroupOrUnitAuftragTarget(inputs)
  if not target then error(target_err) end

  if not AUFTRAG or not AUFTRAG.NewANTISHIP then error("AUFTRAG:NewANTISHIP is not available") end

  local altitude_ft = inputs.altitude_ft and tonumber(inputs.altitude_ft) or nil
  local auftrag = AUFTRAG:NewANTISHIP(target, altitude_ft)

  self:_AddAuftragToTarget(auftrag, inputs)
  return self:_BuildAuftragCommandResult("auftrag.create_antiship", auftrag, inputs)
end

function MOOSE_BRIDGE:_CreateOnGuardAuftrag(cmd)
  local inputs = self:_CommonAuftragCommandInputs(cmd)
  local target, target_err = self:_ResolveOnGuardTarget(inputs)
  if not target then error(target_err) end

  if not AUFTRAG or not AUFTRAG.NewONGUARD then error("AUFTRAG:NewONGUARD is not available") end

  local auftrag = AUFTRAG:NewONGUARD(target)

  self:_AddAuftragToTarget(auftrag, inputs)
  return self:_BuildAuftragCommandResult("auftrag.create_onguard", auftrag, inputs)
end

function MOOSE_BRIDGE:_CreateInterceptAuftrag(cmd)
  local inputs = self:_CommonAuftragCommandInputs(cmd)
  local target, target_err = self:_ResolveGroupOrUnitAuftragTarget(inputs)
  if not target then error(target_err) end

  if not AUFTRAG or not AUFTRAG.NewINTERCEPT then error("AUFTRAG:NewINTERCEPT is not available") end

  local auftrag = AUFTRAG:NewINTERCEPT(target)

  self:_AddAuftragToTarget(auftrag, inputs)
  return self:_BuildAuftragCommandResult("auftrag.create_intercept", auftrag, inputs)
end

function MOOSE_BRIDGE:_CreateStrikeAuftrag(cmd)
  local inputs = self:_CommonAuftragCommandInputs(cmd)
  local target, target_err = self:_ResolveStrikeTarget(inputs)
  if not target then error(target_err) end

  if not AUFTRAG or not AUFTRAG.NewSTRIKE then error("AUFTRAG:NewSTRIKE is not available") end

  local altitude_ft = inputs.altitude_ft and tonumber(inputs.altitude_ft) or nil
  local engage_weapon_type = inputs.engage_weapon_type and tonumber(inputs.engage_weapon_type) or nil
  local auftrag = AUFTRAG:NewSTRIKE(target, altitude_ft, engage_weapon_type)

  self:_AddAuftragToTarget(auftrag, inputs)
  return self:_BuildAuftragCommandResult("auftrag.create_strike", auftrag, inputs)
end

function MOOSE_BRIDGE:_CreateStrafingAuftrag(cmd)
  local inputs = self:_CommonAuftragCommandInputs(cmd)
  local target, target_err = self:_ResolveStrafingTarget(inputs)
  if not target then error(target_err) end

  if not AUFTRAG or not AUFTRAG.NewSTRAFING then error("AUFTRAG:NewSTRAFING is not available") end

  local altitude_ft = inputs.altitude_ft and tonumber(inputs.altitude_ft) or nil
  local length_m = inputs.length_m and tonumber(inputs.length_m) or nil
  local auftrag = AUFTRAG:NewSTRAFING(target, altitude_ft, length_m)

  self:_AddAuftragToTarget(auftrag, inputs)
  return self:_BuildAuftragCommandResult("auftrag.create_strafing", auftrag, inputs)
end

function MOOSE_BRIDGE:_CreateBombRunwayAuftrag(cmd)
  local inputs = self:_CommonAuftragCommandInputs(cmd)
  local target, target_err = self:_ResolveAirbaseAuftragTarget(inputs)
  if not target then error(target_err) end

  if not AUFTRAG or not AUFTRAG.NewBOMBRUNWAY then error("AUFTRAG:NewBOMBRUNWAY is not available") end

  local altitude_ft = inputs.altitude_ft and tonumber(inputs.altitude_ft) or nil
  local auftrag = AUFTRAG:NewBOMBRUNWAY(target, altitude_ft)

  self:_AddAuftragToTarget(auftrag, inputs)
  return self:_BuildAuftragCommandResult("auftrag.create_bombrunway", auftrag, inputs)
end

function MOOSE_BRIDGE:_CreateBombCarpetAuftrag(cmd)
  local inputs = self:_CommonAuftragCommandInputs(cmd)
  local target, target_err = self:_ResolveBombCarpetTarget(inputs)
  if not target then error(target_err) end

  if not AUFTRAG or not AUFTRAG.NewBOMBCARPET then error("AUFTRAG:NewBOMBCARPET is not available") end

  local altitude_ft = inputs.altitude_ft and tonumber(inputs.altitude_ft) or nil
  local carpet_length_m = inputs.carpet_length_m and tonumber(inputs.carpet_length_m) or nil
  local auftrag = AUFTRAG:NewBOMBCARPET(target, altitude_ft, carpet_length_m)

  self:_AddAuftragToTarget(auftrag, inputs)
  return self:_BuildAuftragCommandResult("auftrag.create_bombcarpet", auftrag, inputs)
end

function MOOSE_BRIDGE:_CreateGroundEscortAuftrag(cmd)
  local inputs = self:_CommonAuftragCommandInputs(cmd)
  local target, target_err = self:_ResolveGroupAuftragTarget(inputs)
  if not target then error(target_err) end

  if not AUFTRAG or not AUFTRAG.NewGROUNDESCORT then error("AUFTRAG:NewGROUNDESCORT is not available") end

  local orbit_distance_nm = inputs.orbit_distance_nm and tonumber(inputs.orbit_distance_nm) or nil
  local target_types = self:_NormalizeTargetTypes(inputs.target_types)
  inputs.target_types = target_types
  local auftrag = AUFTRAG:NewGROUNDESCORT(target, orbit_distance_nm, target_types)

  self:_AddAuftragToTarget(auftrag, inputs)
  return self:_BuildAuftragCommandResult("auftrag.create_groundescort", auftrag, inputs)
end

function MOOSE_BRIDGE:_CreateGroundAttackAuftrag(cmd)
  local inputs = self:_CommonAuftragCommandInputs(cmd)
  local target, target_err = self:_ResolvePositionableAttackAuftragTarget(inputs)
  if not target then error(target_err) end

  if not AUFTRAG or not AUFTRAG.NewGROUNDATTACK then error("AUFTRAG:NewGROUNDATTACK is not available") end

  local speed_kts = inputs.speed_kts and tonumber(inputs.speed_kts) or nil
  local auftrag = AUFTRAG:NewGROUNDATTACK(target, speed_kts, inputs.formation)

  self:_AddAuftragToTarget(auftrag, inputs)
  return self:_BuildAuftragCommandResult("auftrag.create_groundattack", auftrag, inputs)
end

function MOOSE_BRIDGE:_CreateNavalEngagementAuftrag(cmd)
  local inputs = self:_CommonAuftragCommandInputs(cmd)
  local target, target_err = self:_ResolvePositionableAttackAuftragTarget(inputs)
  if not target then error(target_err) end

  if not AUFTRAG or not AUFTRAG.NewNAVALENGAGEMENT then error("AUFTRAG:NewNAVALENGAGEMENT is not available") end

  local speed_kts = inputs.speed_kts and tonumber(inputs.speed_kts) or nil
  local depth_m = inputs.depth_m and tonumber(inputs.depth_m) or nil
  local auftrag = AUFTRAG:NewNAVALENGAGEMENT(target, speed_kts, depth_m)

  self:_AddAuftragToTarget(auftrag, inputs)
  return self:_BuildAuftragCommandResult("auftrag.create_navalengagement", auftrag, inputs)
end

function MOOSE_BRIDGE:_CreateEscortAuftrag(cmd)
  local inputs = self:_CommonAuftragCommandInputs(cmd)
  local target, target_err = self:_ResolveGroupAuftragTarget(inputs)
  if not target then error(target_err) end

  if not AUFTRAG or not AUFTRAG.NewESCORT then error("AUFTRAG:NewESCORT is not available") end

  local offset_vector = self:_BuildOffsetVector(inputs)
  local engage_max_distance_nm = inputs.engage_max_distance_nm and tonumber(inputs.engage_max_distance_nm) or nil
  local target_types = self:_NormalizeTargetTypes(inputs.target_types)
  inputs.target_types = target_types
  local auftrag = AUFTRAG:NewESCORT(target, offset_vector, engage_max_distance_nm, target_types)

  self:_AddAuftragToTarget(auftrag, inputs)
  return self:_BuildAuftragCommandResult("auftrag.create_escort", auftrag, inputs)
end

function MOOSE_BRIDGE:_CreateRescueHeloAuftrag(cmd)
  local inputs = self:_CommonAuftragCommandInputs(cmd)
  local target, target_err = self:_ResolveUnitAuftragTarget(inputs)
  if not target then error(target_err) end

  if not AUFTRAG or not AUFTRAG.NewRESCUEHELO then error("AUFTRAG:NewRESCUEHELO is not available") end

  local auftrag = AUFTRAG:NewRESCUEHELO(target)

  self:_AddAuftragToTarget(auftrag, inputs)
  return self:_BuildAuftragCommandResult("auftrag.create_rescuehelo", auftrag, inputs)
end

function MOOSE_BRIDGE:_CreateTroopTransportAuftrag(cmd)
  local inputs = self:_CommonAuftragCommandInputs(cmd)
  local transport_group_set, group_ids = self:_BuildGroupSet(inputs.transport_groups)
  inputs.transport_groups = group_ids

  local dropoff_coordinate, dropoff_err = self:_ResolveCoordinateFromNamedFields(inputs.dropoff_id, inputs.dropoff_x, inputs.dropoff_y, inputs.dropoff_z, "Dropoff", true)
  if not dropoff_coordinate then error(dropoff_err) end

  local pickup_coordinate, pickup_err = self:_ResolveCoordinateFromNamedFields(inputs.pickup_id, inputs.pickup_x, inputs.pickup_y, inputs.pickup_z, "Pickup", false)
  if pickup_err then error(pickup_err) end

  if not AUFTRAG or not AUFTRAG.NewTROOPTRANSPORT then error("AUFTRAG:NewTROOPTRANSPORT is not available") end

  local pickup_radius_m = inputs.pickup_radius_m and tonumber(inputs.pickup_radius_m) or nil
  local auftrag = AUFTRAG:NewTROOPTRANSPORT(transport_group_set, dropoff_coordinate, pickup_coordinate, pickup_radius_m)

  self:_AddAuftragToTarget(auftrag, inputs)
  return self:_BuildAuftragCommandResult("auftrag.create_trooptransport", auftrag, inputs)
end

function MOOSE_BRIDGE:RegisterAuftragExecutionCommands()
  self:RegisterCommand("auftrag.create_bai", function(cmd)
    local inputs = self:_CommonAuftragCommandInputs(cmd)
    local target, target_err = self:_ResolveObjectAuftragTarget(inputs)
    if not target then error(target_err) end

    if not AUFTRAG or not AUFTRAG.NewBAI then error("AUFTRAG:NewBAI is not available") end

    local auftrag = nil
    if inputs.altitude_ft ~= nil then
      auftrag = AUFTRAG:NewBAI(target, tonumber(inputs.altitude_ft))
    else
      auftrag = AUFTRAG:NewBAI(target)
    end

    self:_AddAuftragToTarget(auftrag, inputs)
    return self:_BuildAuftragCommandResult("auftrag.create_bai", auftrag, inputs)
  end)

  self:RegisterCommand("auftrag.create_bombing", function(cmd)
    local inputs = self:_CommonAuftragCommandInputs(cmd)
    local target, target_err = self:_ResolveBombingTarget(inputs)
    if not target then error(target_err) end

    if not AUFTRAG or not AUFTRAG.NewBOMBING then error("AUFTRAG:NewBOMBING is not available") end

    local altitude_ft = inputs.altitude_ft and tonumber(inputs.altitude_ft) or nil
    local engage_weapon_type = inputs.engage_weapon_type and tonumber(inputs.engage_weapon_type) or nil
    local divebomb = bridge_bool_param(inputs.divebomb)

    local auftrag = AUFTRAG:NewBOMBING(target, altitude_ft, engage_weapon_type, divebomb)

    self:_AddAuftragToTarget(auftrag, inputs)
    return self:_BuildAuftragCommandResult("auftrag.create_bombing", auftrag, inputs)
  end)

  self:RegisterCommand("auftrag.create_arty", function(cmd)
    local inputs = self:_CommonAuftragCommandInputs(cmd)
    local target, target_err = self:_ResolveArtyTarget(inputs)
    if not target then error(target_err) end

    if not AUFTRAG or not AUFTRAG.NewARTY then error("AUFTRAG:NewARTY is not available") end

    local nshots = inputs.nshots and tonumber(inputs.nshots) or nil
    local radius_m = inputs.radius_m and tonumber(inputs.radius_m) or nil
    local auftrag = AUFTRAG:NewARTY(target, nshots, radius_m)

    self:_AddAuftragToTarget(auftrag, inputs)
    return self:_BuildAuftragCommandResult("auftrag.create_arty", auftrag, inputs)
  end)

  self:RegisterCommand("auftrag.create_orbit", function(cmd)
    local inputs = self:_CommonAuftragCommandInputs(cmd)
    local target, target_err = self:_ResolveOrbitTarget(inputs)
    if not target then error(target_err) end

    if not AUFTRAG or not AUFTRAG.NewORBIT then error("AUFTRAG:NewORBIT is not available") end

    local altitude_ft = inputs.altitude_ft and tonumber(inputs.altitude_ft) or nil
    local speed_kts = inputs.speed_kts and tonumber(inputs.speed_kts) or nil
    local heading_deg = inputs.heading_deg and tonumber(inputs.heading_deg) or nil
    local leg_nm = inputs.leg_nm and tonumber(inputs.leg_nm) or nil
    local auftrag = AUFTRAG:NewORBIT(target, altitude_ft, speed_kts, heading_deg, leg_nm)

    self:_AddAuftragToTarget(auftrag, inputs)
    return self:_BuildAuftragCommandResult("auftrag.create_orbit", auftrag, inputs)
  end)

  self:RegisterCommand("auftrag.create_awacs", function(cmd)
    return self:_CreateOrbitRoleAuftrag(cmd, "auftrag.create_awacs", "NewAWACS", false)
  end)

  self:RegisterCommand("auftrag.create_tanker", function(cmd)
    return self:_CreateOrbitRoleAuftrag(cmd, "auftrag.create_tanker", "NewTANKER", true)
  end)

  self:RegisterCommand("auftrag.create_cap", function(cmd)
    return self:_CreateZonePatrolAuftrag(cmd, "auftrag.create_cap", "NewCAP")
  end)

  self:RegisterCommand("auftrag.create_cas", function(cmd)
    return self:_CreateZonePatrolAuftrag(cmd, "auftrag.create_cas", "NewCAS")
  end)

  self:RegisterCommand("auftrag.create_casenhanced", function(cmd)
    return self:_CreateCasEnhancedAuftrag(cmd)
  end)

  self:RegisterCommand("auftrag.create_fac", function(cmd)
    return self:_CreateFacAuftrag(cmd)
  end)

  self:RegisterCommand("auftrag.create_patrolzone", function(cmd)
    return self:_CreatePatrolZoneAuftrag(cmd)
  end)

  self:RegisterCommand("auftrag.create_recon", function(cmd)
    return self:_CreateReconAuftrag(cmd)
  end)

  self:RegisterCommand("auftrag.create_capturezone", function(cmd)
    return self:_CreateCaptureZoneAuftrag(cmd)
  end)

  self:RegisterCommand("auftrag.create_faca", function(cmd)
    return self:_CreateFacaAuftrag(cmd)
  end)

  self:RegisterCommand("auftrag.create_ammosupply", function(cmd)
    return self:_CreateZoneOnlyAuftrag(cmd, "auftrag.create_ammosupply", "NewAMMOSUPPLY")
  end)

  self:RegisterCommand("auftrag.create_fuelsupply", function(cmd)
    return self:_CreateZoneOnlyAuftrag(cmd, "auftrag.create_fuelsupply", "NewFUELSUPPLY")
  end)

  self:RegisterCommand("auftrag.create_rearming", function(cmd)
    return self:_CreateZoneOnlyAuftrag(cmd, "auftrag.create_rearming", "NewREARMING")
  end)

  self:RegisterCommand("auftrag.create_airdefense", function(cmd)
    return self:_CreateZoneOnlyAuftrag(cmd, "auftrag.create_airdefense", "NewAIRDEFENSE")
  end)

  self:RegisterCommand("auftrag.create_ewr", function(cmd)
    return self:_CreateZoneOnlyAuftrag(cmd, "auftrag.create_ewr", "NewEWR")
  end)

  self:RegisterCommand("auftrag.create_nothing", function(cmd)
    return self:_CreateZoneOnlyAuftrag(cmd, "auftrag.create_nothing", "NewNOTHING")
  end)

  self:RegisterCommand("auftrag.create_sead", function(cmd)
    return self:_CreateSeadAuftrag(cmd)
  end)

  self:RegisterCommand("auftrag.create_antiship", function(cmd)
    return self:_CreateAntiShipAuftrag(cmd)
  end)

  self:RegisterCommand("auftrag.create_onguard", function(cmd)
    return self:_CreateOnGuardAuftrag(cmd)
  end)

  self:RegisterCommand("auftrag.create_intercept", function(cmd)
    return self:_CreateInterceptAuftrag(cmd)
  end)

  self:RegisterCommand("auftrag.create_strike", function(cmd)
    return self:_CreateStrikeAuftrag(cmd)
  end)

  self:RegisterCommand("auftrag.create_strafing", function(cmd)
    return self:_CreateStrafingAuftrag(cmd)
  end)

  self:RegisterCommand("auftrag.create_bombrunway", function(cmd)
    return self:_CreateBombRunwayAuftrag(cmd)
  end)

  self:RegisterCommand("auftrag.create_bombcarpet", function(cmd)
    return self:_CreateBombCarpetAuftrag(cmd)
  end)

  self:RegisterCommand("auftrag.create_groundescort", function(cmd)
    return self:_CreateGroundEscortAuftrag(cmd)
  end)

  self:RegisterCommand("auftrag.create_groundattack", function(cmd)
    return self:_CreateGroundAttackAuftrag(cmd)
  end)

  self:RegisterCommand("auftrag.create_navalengagement", function(cmd)
    return self:_CreateNavalEngagementAuftrag(cmd)
  end)

  self:RegisterCommand("auftrag.create_escort", function(cmd)
    return self:_CreateEscortAuftrag(cmd)
  end)

  self:RegisterCommand("auftrag.create_rescuehelo", function(cmd)
    return self:_CreateRescueHeloAuftrag(cmd)
  end)

  self:RegisterCommand("auftrag.create_trooptransport", function(cmd)
    return self:_CreateTroopTransportAuftrag(cmd)
  end)

  self:RegisterCommand("auftrag.cancel", function(cmd)
    return self:_CallAuftragLifecycleMethod(cmd, "auftrag.cancel", "Cancel")
  end)

  self:RegisterCommand("auftrag.pause", function(cmd)
    return self:_CallAuftragLifecycleMethod(cmd, "auftrag.pause", "Pause")
  end)

  self:RegisterCommand("auftrag.resume", function(cmd)
    return self:_CallAuftragLifecycleMethod(cmd, "auftrag.resume", "Resume")
  end)

  self:RegisterCommand("auftrag.assign", function(cmd)
    return self:_AssignTrackedAuftrag(cmd)
  end)

  self:RegisterCommand("cohort.set_weapon_range", function(cmd)
    return self:_SetCohortWeaponRange(cmd)
  end)
end

local _moose_bridge_base_add_auftrag_candidate = MOOSE_BRIDGE._AddAuftragCandidate

function MOOSE_BRIDGE:_AddAuftragCandidate(result, seen, auftrag, source)
  self:_TrackAuftragReference(auftrag)
  return _moose_bridge_base_add_auftrag_candidate(self, result, seen, auftrag, source)
end

local _moose_bridge_base_build_cohort_snapshot_item = MOOSE_BRIDGE._BuildCohortSnapshotItem

function MOOSE_BRIDGE:_BuildCohortSnapshotItem(cohort_name, cohort, source)
  local item = _moose_bridge_base_build_cohort_snapshot_item(self, cohort_name, cohort, source)
  if type(item) ~= "table" or type(cohort) ~= "table" then return item end

  local mission_range = self:_SafeCall(cohort, "GetMissionRange") or cohort.missionRange or cohort.MissionRange
  item.mission_range_m = mission_range

  return item
end

local _moose_bridge_base_build_auftrag_snapshot_item = MOOSE_BRIDGE._BuildAuftragSnapshotItem

function MOOSE_BRIDGE:_BuildAuftragSnapshotItem(auftrag, source)
  local item = _moose_bridge_base_build_auftrag_snapshot_item(self, auftrag, source)
  if type(item) ~= "table" or type(auftrag) ~= "table" then return item end

  local summary = bridge_auftrag_summary(auftrag.summary)
  item.d_tevaluate = auftrag.dTevaluate
  item.ready_to_evaluate = bridge_auftrag_ready_to_evaluate(auftrag)
  item.summary_available = summary ~= nil
  item.summary = summary

  return item
end

function MOOSE_BRIDGE:_CollectAuftragCandidatesFromLegion(result, seen, legion)
  if type(legion) ~= "table" then return end
  local queues = {
    legion.missionqueue,
    legion.missions,
    legion.auftraege,
    legion.missionQueue,
  }
  for _, queue in ipairs(queues) do
    if type(queue) == "table" then
      for _, auftrag in pairs(queue) do self:_AddAuftragCandidate(result, seen, auftrag, "legion.missionqueue") end
    end
  end
end

function MOOSE_BRIDGE:_CollectAuftragCandidatesFromTracked(result, seen)
  if type(self.TrackedAuftraege) ~= "table" then return end
  for object_id, auftrag in pairs(self.TrackedAuftraege) do
    if type(auftrag) == "table" then
      self:_AddAuftragCandidate(result, seen, auftrag, "bridge.tracked")
    else
      self.TrackedAuftraege[object_id] = nil
    end
  end
end

function MOOSE_BRIDGE:_CollectAuftragCandidatesFromCommanders(result, seen)
  for _, commander in pairs(self.RegisteredCommanders or {}) do
    if type(commander) == "table" and type(commander.missionqueue) == "table" then
      for _, auftrag in pairs(commander.missionqueue) do
        self:_AddAuftragCandidate(result, seen, auftrag, "commander.missionqueue")
      end
    end
  end
end

local _moose_bridge_base_build_auftrag_snapshot = MOOSE_BRIDGE.BuildAuftragSnapshot

function MOOSE_BRIDGE:BuildAuftragSnapshot()
  local result = _moose_bridge_base_build_auftrag_snapshot(self) or {}
  local seen = {}
  for _, item in ipairs(result) do
    if item.object_id then seen[item.object_id] = true end
  end

  if _DATABASE and type(_DATABASE.LEGIONS) == "table" then
    for _, legion in pairs(_DATABASE.LEGIONS) do
      self:_CollectAuftragCandidatesFromLegion(result, seen, legion)
    end
  end

  self:_CollectAuftragCandidatesFromCommanders(result, seen)
  self:_CollectAuftragCandidatesFromTracked(result, seen)

  return result
end

local _moose_bridge_base_register_default_commands = MOOSE_BRIDGE.RegisterDefaultCommands

function MOOSE_BRIDGE:RegisterDefaultCommands()
  _moose_bridge_base_register_default_commands(self)
  self:RegisterAuftragExecutionCommands()
end
