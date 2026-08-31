--- DCS world event forwarding for MOOSE_BRIDGE.
--
-- Load after MooseBridge.lua and before constructing/starting the bridge.
-- DCS events are normalized here; Python never needs to understand the raw
-- world event table or MOOSE EVENTDATA implementation details.

if not MOOSE_BRIDGE then error("Load MooseBridge.lua before MooseBridgeDcsEventsExtension.lua") end

local function bridge_event_available(event_id)
  return type(event_id) == "number" and event_id > 0
end

--- Cache current DCS ownership for all known MOOSE AIRBASE objects.
-- The DCS BaseCaptured event already exposes the new owner, so the cache is
-- needed to include the previous owner in the normalized bridge event.
function MOOSE_BRIDGE:_CacheAirbaseCoalitions()
  self.AirbaseCoalitions = self.AirbaseCoalitions or {}
  if not _DATABASE or type(_DATABASE.AIRBASES) ~= "table" then return self end
  for airbase_name, airbase in pairs(_DATABASE.AIRBASES) do
    local ok, result = pcall(function()
      local name = self:_SafeCall(airbase, "GetName") or airbase.AirbaseName or airbase_name
      local owner = self:_CoalitionToName(self:_SafeCall(airbase, "GetCoalition"))
      return name and {object_id="AIRBASE:" .. tostring(name), coalition=owner} or nil
    end)
    if ok and result and result.object_id then
      self.AirbaseCoalitions[result.object_id] = result.coalition
    elseif not ok then
      self:_Log("Failed to cache airbase " .. tostring(airbase_name) .. ": " .. tostring(result))
    end
  end
  return self
end

--- Resolve the authoritative MOOSE AIRBASE wrapper from an EVENTDATA object.
function MOOSE_BRIDGE:_AirbaseFromCapturedEvent(EventData)
  if type(EventData) ~= "table" then return nil, nil end
  local place = EventData.Place
  local name = EventData.PlaceName
  if not name and place then
    name = self:_SafeCall(place, "GetName")
  end
  if not name and EventData.place then
    local ok, value = pcall(function() return EventData.place:getName() end)
    if ok then name = value end
  end
  if not name then return nil, nil end

  local airbase = type(place) == "table" and place or nil
  if _DATABASE and type(_DATABASE.AIRBASES) == "table" then
    airbase = _DATABASE.AIRBASES[name] or airbase
  end
  if not airbase and AIRBASE and AIRBASE.FindByName then
    local ok, value = pcall(function() return AIRBASE:FindByName(name) end)
    if ok then airbase = value end
  end
  return airbase, tostring(name)
end

--- Subscribe to selected low-frequency DCS events through MOOSE.
function MOOSE_BRIDGE:_StartDcsEventForwarding()
  if self.DcsEventForwardingStarted then return self end
  if not EVENTS or not self.HandleEvent then
    self:_Log("DCS event forwarding unavailable")
    return self
  end
  self.DcsRegisteredEvents = {}
  if bridge_event_available(EVENTS.BaseCaptured) then
    self:_CacheAirbaseCoalitions()
    self:HandleEvent(EVENTS.BaseCaptured)
    self.DcsRegisteredEvents[#self.DcsRegisteredEvents + 1] = EVENTS.BaseCaptured
    self:_Log("DCS BaseCaptured event forwarding enabled")
  end
  if bridge_event_available(EVENTS.UnitLost) then
    self:HandleEvent(EVENTS.UnitLost)
    self.DcsRegisteredEvents[#self.DcsRegisteredEvents + 1] = EVENTS.UnitLost
    self:_Log("DCS UnitLost event forwarding enabled")
  end
  if bridge_event_available(EVENTS.Dead) then
    self:HandleEvent(EVENTS.Dead)
    self.DcsRegisteredEvents[#self.DcsRegisteredEvents + 1] = EVENTS.Dead
    self:_Log("DCS Dead event forwarding enabled")
  end
  if bridge_event_available(EVENTS.Kill) then
    self:HandleEvent(EVENTS.Kill)
    self.DcsRegisteredEvents[#self.DcsRegisteredEvents + 1] = EVENTS.Kill
    self:_Log("DCS Kill event forwarding enabled")
  end
  if bridge_event_available(EVENTS.PlayerEnterAircraft) then
    self:HandleEvent(EVENTS.PlayerEnterAircraft)
    self.DcsRegisteredEvents[#self.DcsRegisteredEvents + 1] = EVENTS.PlayerEnterAircraft
    self:_Log("MOOSE PlayerEnterAircraft event forwarding enabled")
  end
  if bridge_event_available(EVENTS.PlayerLeaveUnit) then
    self:HandleEvent(EVENTS.PlayerLeaveUnit)
    self.DcsRegisteredEvents[#self.DcsRegisteredEvents + 1] = EVENTS.PlayerLeaveUnit
    self:_Log("DCS PlayerLeaveUnit event forwarding enabled")
  end
  if bridge_event_available(EVENTS.MarkAdded) then
    self:HandleEvent(EVENTS.MarkAdded)
    self.DcsRegisteredEvents[#self.DcsRegisteredEvents + 1] = EVENTS.MarkAdded
    self:_Log("DCS MarkAdded event forwarding enabled")
  end
  if bridge_event_available(EVENTS.MarkChange) then
    self:HandleEvent(EVENTS.MarkChange)
    self.DcsRegisteredEvents[#self.DcsRegisteredEvents + 1] = EVENTS.MarkChange
    self:_Log("DCS MarkChange event forwarding enabled")
  end
  if bridge_event_available(EVENTS.MarkRemoved) then
    self:HandleEvent(EVENTS.MarkRemoved)
    self.DcsRegisteredEvents[#self.DcsRegisteredEvents + 1] = EVENTS.MarkRemoved
    self:_Log("DCS MarkRemoved event forwarding enabled")
  end
  if bridge_event_available(EVENTS.MissionEnd) then
    self:HandleEvent(EVENTS.MissionEnd)
    self.DcsRegisteredEvents[#self.DcsRegisteredEvents + 1] = EVENTS.MissionEnd
    self:_Log("DCS MissionEnd event forwarding enabled")
  end
  if #self.DcsRegisteredEvents == 0 then
    self:_Log("No supported DCS events available for forwarding")
    return self
  end
  self.DcsEventForwardingStarted = true
  return self
end

--- Unsubscribe from DCS events owned by this bridge instance.
function MOOSE_BRIDGE:_StopDcsEventForwarding()
  self.PlayerTestMenuConfig = nil
  self:_ClearPlayerTestMenus()
  if self.DcsEventForwardingStarted and self.UnHandleEvent then
    for _, event_id in ipairs(self.DcsRegisteredEvents or {}) do
      self:UnHandleEvent(event_id)
    end
  end
  self.DcsRegisteredEvents = {}
  self.DcsEventForwardingStarted = false
  self.PlayerAircraftSessions = {}
  self.PlayerAircraftLeaveTimes = {}
  self.PendingPlayerAircraftEnters = {}
  return self
end

--- Forward DCS S_EVENT_BASE_CAPTURED as airbase.coalition_changed.
-- @param Core.Event#EVENTDATA EventData MOOSE-normalized DCS event data.
function MOOSE_BRIDGE:OnEventBaseCaptured(EventData)
  local ok, err = pcall(function()
    local airbase, airbase_name = self:_AirbaseFromCapturedEvent(EventData)
    if not airbase or not airbase_name then
      error("BaseCaptured event has no resolvable AIRBASE")
    end

    local item = self:_BuildAirbaseSnapshotItem(airbase_name, airbase)
    if not item or not item.object_id then
      error("Could not build AIRBASE snapshot for " .. tostring(airbase_name))
    end

    self.AirbaseCoalitions = self.AirbaseCoalitions or {}
    local previous = self.AirbaseCoalitions[item.object_id]
    local current = item.coalition
    self.AirbaseCoalitions[item.object_id] = current

    if previous ~= current then
      self:SendEvent("airbase.coalition_changed", {
        dcs_event_id=EventData.id,
        dcs_event_name="S_EVENT_BASE_CAPTURED",
        dcs_event_time=EventData.time,
        airbase_id=item.object_id,
        previous_coalition=previous,
        coalition=current,
        capturing_unit_id=EventData.IniUnitName and ("UNIT:" .. tostring(EventData.IniUnitName)) or nil,
        capturing_group_id=EventData.IniGroupName and ("GROUP:" .. tostring(EventData.IniGroupName)) or nil,
        capturing_coalition=self:_CoalitionToName(EventData.IniCoalition),
        capturing_unit_type=EventData.IniTypeName and tostring(EventData.IniTypeName) or nil,
        airbase=item,
      })
    end
  end)
  if not ok then
    self:_Log("Failed to forward BaseCaptured event: " .. tostring(err))
  end
end

--- Build a tombstone and current group snapshot for a destroyed DCS object.
function MOOSE_BRIDGE:_BuildObjectDestroyedPayload(EventData)
  if type(EventData) ~= "table" then error("Destruction event data is missing") end
  local name = EventData.IniUnitName or EventData.IniDCSUnitName
  if not name then error("Destruction event has no initiator name") end

  local is_static = Object and Object.Category
    and EventData.IniObjectCategory == Object.Category.STATIC
  local is_scenery = Object and Object.Category
    and EventData.IniObjectCategory == Object.Category.SCENERY
  local object_type = is_scenery and "SCENERY" or (is_static and "STATIC" or "UNIT")
  local object_id = object_type .. ":" .. tostring(name)
  local item = nil

  if is_scenery then
    local scenery = EventData.IniDCSUnit or EventData.initiator
    if scenery then
      local ok, value = pcall(function()
        return self:_ScenerySnapshot(
          scenery,
          nil,
          name,
          EventData.IniTypeName,
          "destruction_event"
        )
      end)
      if ok then item = value end
    end
  elseif is_static then
    local static = EventData.IniUnit
    if not static and _DATABASE and _DATABASE.STATICS then static = _DATABASE.STATICS[name] end
    if static then
      local ok, value = pcall(function() return self:_BuildStaticSnapshotItem(name, static) end)
      if ok then item = value end
    end
  else
    local unit = EventData.IniUnit
    if not unit and _DATABASE and _DATABASE.UNITS then unit = _DATABASE.UNITS[name] end
    if unit then
      local ok, value = pcall(function() return self:_BuildUnitSnapshotItem(name, unit) end)
      if ok then item = value end
    end
  end

  item = item or {
    object_id=object_id,
    dcs_name=tostring(name),
    object_type=object_type,
  }
  item.object_id = object_id
  item.object_type = object_type
  item.alive = false
  item.active = false
  if is_scenery then item.life = 0 end
  item.coalition = item.coalition or self:_CoalitionToName(EventData.IniCoalition)
  item.category = item.category or (is_scenery and "Scenery"
    or (EventData.IniCategory and tostring(EventData.IniCategory) or nil))
  item.dcs_type = item.dcs_type or item.type_name
    or (EventData.IniTypeName and tostring(EventData.IniTypeName) or nil)

  local group_name = EventData.IniGroupName or EventData.IniDCSGroupName or item.group_name
  local group_item = nil
  if not is_static and not is_scenery and group_name then
    local group = EventData.IniGroup
    if not group and _DATABASE and _DATABASE.GROUPS then group = _DATABASE.GROUPS[group_name] end
    if group then
      local ok, value = pcall(function() return self:_BuildGroupSnapshotItem(group_name, group) end)
      if ok then group_item = value end
    end
    item.group_name = tostring(group_name)
  end

  return {
    object_id=object_id,
    object_type=object_type,
    group_id=group_name and ("GROUP:" .. tostring(group_name)) or nil,
    object=item,
    group=group_item,
  }
end

--- Forward one DCS destruction event as object.destroyed.
-- UnitLost and Dead can describe the same loss, depending on the DCS object
-- and destruction path. Suppress the second event without polling object state.
function MOOSE_BRIDGE:_ForwardObjectDestroyed(EventData, event_name)
  local ok, err = pcall(function()
    local payload = self:_BuildObjectDestroyedPayload(EventData)
    local event_time = tonumber(EventData.time)
    local dedup_time = event_time or (timer and timer.getTime and timer.getTime()) or 0
    self.DcsDestroyedEventTimes = self.DcsDestroyedEventTimes or {}
    local previous_time = self.DcsDestroyedEventTimes[payload.object_id]
    if previous_time and math.abs(dedup_time - previous_time) <= 2 then return end
    self.DcsDestroyedEventTimes[payload.object_id] = dedup_time

    payload.dcs_event_id = EventData.id
    payload.dcs_event_name = event_name
    payload.dcs_event_time = event_time
    self:SendEvent("object.destroyed", payload)
  end)
  if not ok then
    self:_Log("Failed to forward " .. tostring(event_name) .. " event: " .. tostring(err))
  end
end

--- Forward DCS S_EVENT_UNIT_LOST as object.destroyed.
-- @param Core.Event#EVENTDATA EventData MOOSE-normalized DCS event data.
function MOOSE_BRIDGE:OnEventUnitLost(EventData)
  self:_ForwardObjectDestroyed(EventData, "S_EVENT_UNIT_LOST")
end

--- Forward DCS S_EVENT_DEAD as object.destroyed.
-- @param Core.Event#EVENTDATA EventData MOOSE-normalized DCS event data.
function MOOSE_BRIDGE:OnEventDead(EventData)
  self:_ForwardObjectDestroyed(EventData, "S_EVENT_DEAD")
end

--- Forward an attributed DCS kill without replacing UnitLost/Dead state events.
-- @param Core.Event#EVENTDATA EventData MOOSE-normalized DCS event data.
function MOOSE_BRIDGE:OnEventKill(EventData)
  local ok, err = pcall(function()
    if type(EventData) ~= "table" then error("Kill event data is missing") end
    local killer_name = EventData.IniUnitName or EventData.IniDCSUnitName
    local target_name = EventData.TgtUnitName or EventData.TgtDCSUnitName
    if not killer_name or not target_name then error("Kill event has no killer or target name") end

    local target_is_static = Object and Object.Category
      and EventData.TgtObjectCategory == Object.Category.STATIC
    self:SendEvent("combat.kill", {
      dcs_event_id=EventData.id,
      dcs_event_name="S_EVENT_KILL",
      dcs_event_time=EventData.time,
      killer_object_id="UNIT:" .. tostring(killer_name),
      killer_group_id=EventData.IniGroupName and ("GROUP:" .. tostring(EventData.IniGroupName)) or nil,
      killer_coalition=self:_CoalitionToName(EventData.IniCoalition),
      killer_type=EventData.IniTypeName and tostring(EventData.IniTypeName) or nil,
      target_object_id=(target_is_static and "STATIC:" or "UNIT:") .. tostring(target_name),
      target_group_id=EventData.TgtGroupName and ("GROUP:" .. tostring(EventData.TgtGroupName)) or nil,
      target_coalition=self:_CoalitionToName(EventData.TgtCoalition),
      target_type=EventData.TgtTypeName and tostring(EventData.TgtTypeName) or nil,
      weapon_name=EventData.WeaponName and tostring(EventData.WeaponName) or nil,
    })
  end)
  if not ok then
    self:_Log("Failed to forward Kill event: " .. tostring(err))
  end
end

--- Resolve the OPSGROUP specialization belonging to a player's DCS group.
-- FLIGHTGROUP inherits OPSGROUP and MOOSE stores every OPSGROUP specialization
-- in DATABASE.FLIGHTGROUPS despite that collection's historical name.
function MOOSE_BRIDGE:_PlayerEventOpsGroup(group_name)
  if not group_name then return nil, nil end
  local opsgroup = self.RegisteredOpsGroups and self.RegisteredOpsGroups[group_name] or nil
  local source = opsgroup and "registered" or nil
  if not opsgroup and _DATABASE and type(_DATABASE.FLIGHTGROUPS) == "table" then
    opsgroup = _DATABASE.FLIGHTGROUPS[group_name]
    source = opsgroup and "database.FLIGHTGROUPS" or nil
  end
  return opsgroup, source
end


--- Read a FLIGHTGROUP route without changing its waypoints or DCS tasks.
-- waypoints0 is OPSGROUP's preserved Mission Editor route, including landing.
-- GetWaypoints() instead returns the processed/current operational route.
function MOOSE_BRIDGE:_GetFlightGroupRoute(params)
  local object_id = params.opsgroup_id
  if type(object_id) ~= "string" or not string.find(object_id, "^OPSGROUP:.+") then
    error("flightgroup.route.get requires an OPSGROUP: id")
  end
  local group_name = string.sub(object_id, 10)
  local opsgroup = self:_PlayerEventOpsGroup(group_name)
  if not opsgroup then error("OPSGROUP not found: " .. object_id) end
  if not self:_SafeCall(opsgroup, "IsFlightgroup") then
    error("OPSGROUP is not a FLIGHTGROUP: " .. object_id)
  end
  local source = params.route_source or "mission_editor"
  local waypoints
  if source == "mission_editor" then
    waypoints = opsgroup.waypoints0
  elseif source == "current" then
    waypoints = self:_SafeCall(opsgroup, "GetWaypoints")
  else
    error("route_source must be mission_editor or current")
  end
  if type(waypoints) ~= "table" or #waypoints == 0 then
    error("No " .. source .. " waypoints available for " .. object_id)
  end
  if #waypoints > 501 then error("Flight route exceeds the 501-waypoint display limit") end
  local items = {}
  for index, waypoint in ipairs(waypoints) do
    local x = tonumber(waypoint.x)
    local z = tonumber(waypoint.y) -- DCS route Vec2.y is world Vec3.z, not altitude.
    local altitude = tonumber(waypoint.alt)
    if not x or not z then error("Invalid coordinates at waypoint " .. tostring(index)) end
    local coordinates = self:_CoordinatesForPoint({x=x, y=0, z=z}, "ll")
    if not coordinates.latitude or not coordinates.longitude then
      error("Cannot convert waypoint " .. tostring(index) .. " to latitude/longitude")
    end
    items[#items + 1] = {
      index=index,
      uid=waypoint.uid,
      name=waypoint.name or ("WP " .. tostring(index)),
      x=x,
      z=z,
      latitude=coordinates.latitude,
      longitude=coordinates.longitude,
      altitude_m=altitude,
      altitude_type=waypoint.alt_type,
      speed_mps=tonumber(waypoint.speed),
      type=waypoint.type,
      action=waypoint.action,
    }
  end
  return {
    opsgroup_id=object_id,
    group_id="GROUP:" .. group_name,
    coalition=self:_OpsCoalition(opsgroup),
    route_source=source,
    waypoints=items,
  }
end

-- Compose with the other extensions' command registration before Bridge:New().
local _player_route_register_default_commands = MOOSE_BRIDGE.RegisterDefaultCommands
function MOOSE_BRIDGE:RegisterDefaultCommands()
  _player_route_register_default_commands(self)
  self:RegisterCommand("flightgroup.route.get", function(cmd)
    return self:_GetFlightGroupRoute(cmd.params or {})
  end)
  self:RegisterCommand("player.menu.test.configure", function(cmd)
    return self:_ConfigurePlayerTestMenus(cmd.params or {})
  end)
  self:RegisterCommand("player.menu.navigation.configure", function(cmd)
    return self:_ConfigurePlayerTestMenus(cmd.params or {}, "navigation")
  end)
  self:RegisterCommand("player.menu.navigation.context", function(cmd)
    local params = cmd.params or {}
    local entry = self:_NavigationMenuEntry(params)
    return self:_NavigationMenuPayload(entry.group:GetName(), entry)
  end)
  self:RegisterCommand("player.menu.navigation.flight_status", function(cmd)
    return self:_GetPlayerFlightStatus(cmd.params or {})
  end)
  self:RegisterCommand("player.menu.navigation.message", function(cmd)
    local params = cmd.params or {}
    local entry = self:_NavigationMenuEntry(params)
    if params.unit_id ~= nil then
      local unit_name = self:_FlightStatusReferenceUnit(entry)
      if params.unit_id ~= "UNIT:" .. unit_name then error("Flight status reference aircraft changed") end
    end
    if type(params.text) ~= "string" or #params.text == 0 or #params.text > 2000 then
      error("navigation message text must contain 1..2000 bytes")
    end
    MESSAGE:New(params.text, 10, "Navigation"):ToGroup(entry.group)
    return {delivered=true}
  end)
  self:RegisterCommand("player.menu.navigation.overlay", function(cmd)
    local params = cmd.params or {}
    local entry = self:_NavigationMenuEntry(params)
    if type(params.show) ~= "boolean" then error("show must be boolean") end
    if not params.show then
      return {removed=self:_ClearDebugOverlay(entry.overlay_id)}
    end
    local coalition_name = self:_CoalitionToName(self:_SafeCall(entry.group, "GetCoalition"))
    if coalition_name ~= "blue" and coalition_name ~= "red" and coalition_name ~= "neutral" then
      error("Cannot determine navigation overlay coalition")
    end
    return self:_DrawDebugOverlay({overlay_id=entry.overlay_id, features=params.features,
      coalition=coalition_name, replace=true, read_only=true})
  end)
end

--- Validate at execution time so delayed Python work cannot address a new slot.
function MOOSE_BRIDGE:_NavigationMenuEntry(params)
  local group_name = type(params.group_id) == "string"
    and string.match(params.group_id, "^GROUP:(.+)$") or nil
  local config = self.PlayerTestMenuConfig
  local entry = group_name and self.PlayerTestMenus and self.PlayerTestMenus[group_name]
  if not config or config.mode ~= "navigation" or config.owner_id ~= params.owner_id
    or not entry or entry.session_id ~= params.session_id
    or entry.owner_id ~= params.owner_id or not self:_SafeCall(entry.group, "IsAlive")
    or self:_SafeCall(entry.group, "GetID") ~= entry.group_id
    or #self:_PlayerTestMenuSessions(group_name) == 0 then
    error("Navigation menu session inactive")
  end
  return entry
end

function MOOSE_BRIDGE:_NavigationMenuPayload(group_name, entry)
  local opsgroup = self:_PlayerEventOpsGroup(group_name)
  return {menu_id="navigation", scope="group", owner_id=entry.owner_id,
    session_id=entry.session_id, group_id="GROUP:" .. group_name,
    group_name=group_name, group_sessions=self:_PlayerTestMenuSessions(group_name),
    opsgroup_id=opsgroup and ("OPSGROUP:" .. group_name) or nil}
end

--- Resolve exactly one live player aircraft; multicrew seats may share a unit.
-- Never use a group's first unit or cached position as a telemetry fallback.
function MOOSE_BRIDGE:_FlightStatusReferenceUnit(entry)
  local unit_name = nil
  for _, session in ipairs(self:_PlayerTestMenuSessions(entry.group:GetName())) do
    local name = session.unit_id and string.match(session.unit_id, "^UNIT:(.+)$")
    if not name or (unit_name and unit_name ~= name) then
      error("Flight status requires exactly one player aircraft per group")
    end
    unit_name = name
  end
  if not unit_name then error("No player aircraft available for flight status") end
  local wrapper = _DATABASE and _DATABASE.UNITS and _DATABASE.UNITS[unit_name]
  local unit = self:_SafeCall(wrapper, "GetDCSObject")
  if not unit or not unit:isExist() then error("Flight status aircraft is unavailable") end
  local group = unit:getGroup()
  if not group or group:getID() ~= entry.group_id then
    error("Flight status aircraft no longer belongs to this group")
  end
  return unit_name, unit
end

local function flight_status_number(value)
  if type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge then
    return value
  end
  return nil
end

local function flight_status_vector(value)
  if type(value) == "table" and flight_status_number(value.x)
    and flight_status_number(value.y) and flight_status_number(value.z) then
    return {x=value.x, y=value.y, z=value.z}
  end
  return nil
end

--- Read DCS world telemetry once; Python derives labeled flight-state quantities.
function MOOSE_BRIDGE:_GetPlayerFlightStatus(params)
  local entry = self:_NavigationMenuEntry(params)
  local name, unit = self:_FlightStatusReferenceUnit(entry)
  local position = unit:getPosition()
  local point = type(position) == "table" and flight_status_vector(position.p)
  if not point then error("Flight status position is unavailable") end
  local velocity_ok, velocity = pcall(function() return unit:getVelocity() end)
  local terrain_ok, terrain = pcall(function()
    return land.getHeight({x=point.x, y=point.z}) -- DCS land API uses Vec2.
  end)
  local north_ok, north = pcall(function()
    local lat, lon = coord.LOtoLL(point)
    if not flight_status_number(lat) or not flight_status_number(lon) or math.abs(lat) >= 89.999 then
      return nil
    end
    -- Local geographic north tangent. Subtract endpoints to avoid inverse-map
    -- round-trip offsets. Heading/track must not treat DCS grid north as TRUE.
    local a = flight_status_vector(coord.LLtoLO(lat - 0.001, lon))
    local b = flight_status_vector(coord.LLtoLO(lat + 0.001, lon))
    if not a or not b then return nil end
    return {x=b.x-a.x, y=0, z=b.z-a.z}
  end)
  return {owner_id=entry.owner_id, session_id=entry.session_id,
    group_id="GROUP:" .. entry.group:GetName(), unit_id="UNIT:" .. name,
    sample_time_s=flight_status_number(timer.getTime()),
    altitude_msl_m=point.y,
    terrain_elevation_m=terrain_ok and flight_status_number(terrain) or nil,
    velocity_mps=velocity_ok and flight_status_vector(velocity) or nil,
    forward=flight_status_vector(position.x),
    true_north=north_ok and flight_status_vector(north) or nil}
end

--- Group context, NOT the identity of the player who clicked the radio menu.
-- DCS/MOOSE group command callbacks only receive our bound arguments.
function MOOSE_BRIDGE:_PlayerTestMenuSessions(group_name)
  local sessions = {}
  for _, session in pairs(self.PlayerAircraftSessions or {}) do
    if session.group_name == group_name then
      sessions[#sessions + 1] = {
        player_name=session.player_name,
        unit_id=session.unit_name and ("UNIT:" .. session.unit_name) or nil,
      }
    end
  end
  table.sort(sessions, function(a, b)
    return (a.player_name or a.unit_id or "") < (b.player_name or b.unit_id or "")
  end)
  return sessions
end

--- Remove only this bridge's test tree, including stale MOOSE index entries.
function MOOSE_BRIDGE:_RemovePlayerTestMenu(group_name)
  local entry = self.PlayerTestMenus and self.PlayerTestMenus[group_name]
  if not entry then return end
  self.PlayerTestMenus[group_name] = nil -- Invalidate callbacks before removal.
  if entry.mode == "navigation" then
    -- Use only this entry's overlay; other scripts' F10 drawings stay untouched.
    local cleared, clear_err = pcall(function() self:_ClearDebugOverlay(entry.overlay_id) end)
    if not cleared then self:_Log("Navigation overlay cleanup failed: " .. tostring(clear_err)) end
    self:SendEvent("player.menu.closed", {menu_id="navigation", owner_id=entry.owner_id,
      session_id=entry.session_id, group_id="GROUP:" .. group_name})
  end
  local ok, err = pcall(function()
    -- MENU_GROUP:Remove() checks IsAlive(). After despawn it can leave the
    -- index intact, causing New() to reuse an obsolete GroupID on respawn.
    local owned = {}
    local function collect(menu)
      owned[#owned + 1] = menu
      for _, child in pairs(menu.Menus or {}) do collect(child) end
    end
    collect(entry.menu)
    local removed, remove_err = pcall(function() entry.menu:Remove() end)
    if not removed then self:_Log("MOOSE menu removal failed: " .. tostring(remove_err)) end
    local index = MENU_INDEX and MENU_INDEX.Group[group_name]
    for _, menu in ipairs(owned) do
      if index and index.Menus[menu.Path] == menu then
        missionCommands.removeItemForGroup(menu.GroupID, menu.MenuPath)
        index.Menus[menu.Path] = nil
      end
    end
  end)
  if not ok then self:_Log("Failed to remove player test menu: " .. tostring(err)) end
end

function MOOSE_BRIDGE:_ClearPlayerTestMenus()
  local names = {}
  for name, _ in pairs(self.PlayerTestMenus or {}) do names[#names + 1] = name end
  for _, name in ipairs(names) do self:_RemovePlayerTestMenu(name) end
end

--- Keep a single menu per occupied group; independent of FLIGHTGROUP creation.
function MOOSE_BRIDGE:_SyncPlayerTestMenu(group_name, group)
  if not group_name then return end
  local sessions = self:_PlayerTestMenuSessions(group_name)
  local config = self.PlayerTestMenuConfig
  if not config or #sessions == 0 then
    self:_RemovePlayerTestMenu(group_name)
    return
  end
  group = group or (_DATABASE and _DATABASE.GROUPS and _DATABASE.GROUPS[group_name])
  if not group or not self:_SafeCall(group, "IsAlive") then
    self:_RemovePlayerTestMenu(group_name)
    return
  end
  self.PlayerTestMenus = self.PlayerTestMenus or {}
  local entry = self.PlayerTestMenus[group_name]
  if entry and entry.group_id == group:GetID() then return end
  self:_RemovePlayerTestMenu(group_name)
  self.PlayerMenuSerial = (self.PlayerMenuSerial or 0) + 1
  entry = {group=group, group_id=group:GetID(), owner_id=config.owner_id,
    mode=config.mode, session_id=tostring(self.PlayerMenuSerial),
    overlay_id="navigation-menu-" .. tostring(self.PlayerMenuSerial)}
  if config.mode == "navigation" then
    entry.menu = MENU_GROUP:New(group, "Navigation")
  else
    entry.menu = MENU_GROUP:New(group, "MoosePyBridge Test")
  end
  self.PlayerTestMenus[group_name] = entry -- Also owns a partially built tree.
  if config.mode == "navigation" then
    local actions = {{"Show route", "route_show"}, {"Hide route", "route_hide"},
      {"Navigation status", "status"}, {"Flight status", "flight_status"},
      {"Enable hints", "hints_on"}, {"Disable hints", "hints_off"}}
    for _, item in ipairs(actions) do
      local action = item[2] -- One binding per callback, also on Lua 5.1.
      MENU_GROUP_COMMAND:New(group, item[1], entry.menu, function()
        self:_OnPlayerTestMenuSelected(group_name, entry, action)
      end)
    end
    return
  end
  MENU_GROUP_COMMAND:New(group, "Show message", entry.menu, function()
    self:_OnPlayerTestMenuSelected(group_name, entry, "message")
  end)
  MENU_GROUP_COMMAND:New(group, "Python console", entry.menu, function()
    self:_OnPlayerTestMenuSelected(group_name, entry, "python_console")
  end)
end

function MOOSE_BRIDGE:_OnPlayerTestMenuSelected(group_name, entry, action)
  local config = self.PlayerTestMenuConfig
  if not config or config.owner_id ~= entry.owner_id
    or not self.PlayerTestMenus or self.PlayerTestMenus[group_name] ~= entry then return end
  local sessions = self:_PlayerTestMenuSessions(group_name)
  if #sessions == 0 or not self:_SafeCall(entry.group, "IsAlive")
    or self:_SafeCall(entry.group, "GetID") ~= entry.group_id then return end
  if entry.mode == "navigation" then
    if action ~= "route_show" and action ~= "route_hide" and action ~= "status"
      and action ~= "flight_status" and action ~= "hints_on" and action ~= "hints_off" then return end
    local payload = self:_NavigationMenuPayload(group_name, entry)
    payload.action = action
    self:SendEvent("player.menu.selected", payload)
  elseif action == "message" then
    MESSAGE:New("Menu test successful! Group: " .. group_name, 10, "MoosePyBridge")
      :ToGroup(entry.group)
  elseif action == "python_console" then
    self:SendEvent("player.menu.selected", {
      menu_id="player-menu-test",
      action=action,
      owner_id=entry.owner_id,
      scope="group",
      group_id="GROUP:" .. group_name,
      group_name=group_name,
      group_sessions=sessions,
    })
  end
end

--- Opt-in test, enabled by the VS Code client, never by default.
-- A new run replaces an abandoned test; an old client's cleanup cannot remove it.
function MOOSE_BRIDGE:_ConfigurePlayerTestMenus(params, mode)
  if type(params.enabled) ~= "boolean" then error("enabled must be boolean") end
  if type(params.owner_id) ~= "string" or #params.owner_id == 0 or #params.owner_id > 128 then
    error("owner_id must be a non-empty string of at most 128 characters")
  end
  if params.enabled then
    if not MENU_GROUP or not MENU_GROUP_COMMAND or not MESSAGE then
      error("MOOSE MENU_GROUP, MENU_GROUP_COMMAND and MESSAGE are required")
    end
    self.PlayerTestMenuConfig = nil
    self:_ClearPlayerTestMenus()
    self.PlayerTestMenuConfig = {owner_id=params.owner_id, mode=mode or "test"}
    local ok, err = pcall(function()
      for _, session in pairs(self.PlayerAircraftSessions or {}) do
        self:_SyncPlayerTestMenu(session.group_name)
      end
    end)
    if not ok then
      self.PlayerTestMenuConfig = nil
      self:_ClearPlayerTestMenus()
      error(err)
    end
  elseif self.PlayerTestMenuConfig and self.PlayerTestMenuConfig.owner_id == params.owner_id then
    self.PlayerTestMenuConfig = nil
    self:_ClearPlayerTestMenus()
  end
  local count = 0
  for group_name in pairs(self.PlayerTestMenus or {}) do count = count + 1 end
  return {enabled=self.PlayerTestMenuConfig ~= nil, group_count=count}
end

--- Find cached enter data when PlayerLeaveUnit omits player or wrapper fields.
function MOOSE_BRIDGE:_CachedPlayerAircraftSession(player_name, unit_name)
  for key, session in pairs(self.PlayerAircraftSessions or {}) do
    if (player_name and session.player_name == player_name)
      or (not player_name and unit_name and session.unit_name == unit_name) then
      return session, key
    end
  end
  return nil, nil
end

--- Announce a player entering an aircraft in dcs.log and to that DCS group.
function MOOSE_BRIDGE:_NotifyPlayerEnteredAircraft(session, group)
  local player_name = session.player_name or "<unknown player>"
  local unit_name = session.unit_name or "<unknown unit>"
  local aircraft_type = session.aircraft_type or "<unknown aircraft>"
  local group_name = session.group_name or "<unknown group>"
  self:_Log(string.format(
    "Player/client entered aircraft: player='%s', unit='%s', type='%s', group='%s'",
    player_name,
    unit_name,
    aircraft_type,
    group_name
  ))

  if not MESSAGE then
    self:_Log("Cannot display player-enter message: MOOSE MESSAGE is unavailable")
    return self
  end
  if not group then
    self:_Log("Cannot display player-enter message: group '" .. group_name .. "' is unavailable")
    return self
  end

  local text = string.format(
    "Player %s entered aircraft slot %s (%s).",
    player_name,
    unit_name,
    aircraft_type
  )
  local ok, err = pcall(function()
    MESSAGE:New(text, 10, "MoosePyBridge"):ToGroup(group)
  end)
  if not ok then
    self:_Log("Failed to display player-enter message for group '"
      .. group_name .. "': " .. tostring(err))
  end
  return self
end

--- Record a player leaving an aircraft after enriching the event from cache.
function MOOSE_BRIDGE:_LogPlayerLeftAircraft(session)
  self:_Log(string.format(
    "Player/client left aircraft: player='%s', unit='%s', type='%s', group='%s'",
    session.player_name or "<unknown player>",
    session.unit_name or "<unknown unit>",
    session.aircraft_type or "<unknown aircraft>",
    session.group_name or "<unknown group>"
  ))
  return self
end

--- Normalize the player slot lifecycle for Python consumers.
function MOOSE_BRIDGE:_ForwardPlayerAircraftEvent(EventData, event_name, dcs_event_name, entering)
  local ok, err = pcall(function()
    if type(EventData) ~= "table" then error(dcs_event_name .. " event data is missing") end

    local player_name = EventData.IniPlayerName or EventData.PlayerName
    local unit_name = EventData.IniUnitName or EventData.IniDCSUnitName
    local cached, cache_key = self:_CachedPlayerAircraftSession(player_name, unit_name)
    player_name = player_name or (cached and cached.player_name)
    unit_name = unit_name or (cached and cached.unit_name)
    local group_name = EventData.IniGroupName or EventData.IniDCSGroupName
      or (cached and cached.group_name)
    local aircraft_type = EventData.IniTypeName or (cached and cached.aircraft_type)
    local coalition_name = self:_CoalitionToName(EventData.IniCoalition)
      or (cached and cached.coalition)
    if not player_name and not unit_name then
      error(dcs_event_name .. " has neither player nor unit identity")
    end

    local unit = EventData.IniUnit
    if not unit and unit_name and _DATABASE and type(_DATABASE.UNITS) == "table" then
      unit = _DATABASE.UNITS[unit_name]
    end
    local unit_item = nil
    if unit and unit_name then
      local snapshot_ok, value = pcall(function() return self:_BuildUnitSnapshotItem(unit_name, unit) end)
      if snapshot_ok then unit_item = value end
    end

    local group = EventData.IniGroup
    if not group and group_name and _DATABASE and type(_DATABASE.GROUPS) == "table" then
      group = _DATABASE.GROUPS[group_name]
    end
    local group_item = nil
    if group and group_name then
      local snapshot_ok, value = pcall(function() return self:_BuildGroupSnapshotItem(group_name, group) end)
      if snapshot_ok then group_item = value end
    end

    local opsgroup, opsgroup_source = self:_PlayerEventOpsGroup(group_name)
    local opsgroup_item = nil
    if opsgroup then
      local snapshot_ok, value = pcall(function()
        return self:_BuildOpsGroupSnapshotItem(group_name, opsgroup, opsgroup_source)
      end)
      if snapshot_ok then opsgroup_item = value end
    end

    local session = {
      player_name=player_name and tostring(player_name) or nil,
      unit_name=unit_name and tostring(unit_name) or nil,
      group_name=group_name and tostring(group_name) or nil,
      aircraft_type=aircraft_type and tostring(aircraft_type) or nil,
      coalition=coalition_name,
    }
    self.PlayerAircraftSessions = self.PlayerAircraftSessions or {}
    self.PlayerAircraftLeaveTimes = self.PlayerAircraftLeaveTimes or {}
    local lifecycle_key = session.player_name or (session.unit_name and ("UNIT:" .. session.unit_name))
    local lifecycle_time = tonumber(EventData.time)
      or (timer and timer.getTime and timer.getTime()) or 0
    if entering then
      local key = session.player_name or ("UNIT:" .. tostring(session.unit_name))
      if lifecycle_key then self.PlayerAircraftLeaveTimes[lifecycle_key] = nil end
      self.PlayerAircraftSessions[key] = session
      self:_NotifyPlayerEnteredAircraft(session, group)
    else
      local previous_leave = lifecycle_key and self.PlayerAircraftLeaveTimes[lifecycle_key] or nil
      if previous_leave and math.abs(lifecycle_time - previous_leave) <= 1 then
        self:_Log("Suppressed duplicate PlayerLeaveUnit for player='"
          .. tostring(session.player_name or "<unknown player>") .. "', unit='"
          .. tostring(session.unit_name or "<unknown unit>") .. "'")
        return
      end
      if lifecycle_key then self.PlayerAircraftLeaveTimes[lifecycle_key] = lifecycle_time end
      self:_LogPlayerLeftAircraft(session)
      if cache_key then self.PlayerAircraftSessions[cache_key] = nil end
    end

    self:SendEvent(event_name, {
      dcs_event_id=EventData.id,
      dcs_event_name=dcs_event_name,
      dcs_event_time=EventData.time,
      player_name=session.player_name,
      unit_id=session.unit_name and ("UNIT:" .. session.unit_name) or nil,
      unit_name=session.unit_name,
      group_id=session.group_name and ("GROUP:" .. session.group_name) or nil,
      group_name=session.group_name,
      opsgroup_id=opsgroup_item and opsgroup_item.object_id or nil,
      aircraft_type=session.aircraft_type,
      coalition=session.coalition,
      unit=unit_item,
      group=group_item,
      opsgroup=opsgroup_item,
    })
    -- Menu failures must not interrupt the established player lifecycle.
    local menu_ok, menu_err = pcall(function()
      if cached and cached.group_name ~= session.group_name then
        self:_SyncPlayerTestMenu(cached.group_name)
      end
      self:_SyncPlayerTestMenu(session.group_name, group)
    end)
    if not menu_ok then
      self:_RemovePlayerTestMenu(session.group_name)
      self:_Log("Failed to update player test menu: " .. tostring(menu_err))
    end
  end)
  if not ok then
    self:_Log("Failed to forward " .. tostring(dcs_event_name) .. " event: " .. tostring(err))
  end
end

--- Finish an entry once, resolving FLIGHTGROUP/OPSGROUP at processing time.
function MOOSE_BRIDGE:_FlushPendingPlayerAircraftEnter(EventData)
  if not self.PendingPlayerAircraftEnters or not self.PendingPlayerAircraftEnters[EventData] then return end
  self.PendingPlayerAircraftEnters[EventData] = nil
  self:_ForwardPlayerAircraftEvent(
    EventData,
    "player.aircraft.entered",
    "MOOSE_PLAYER_ENTER_AIRCRAFT",
    true
  )
end

--- Allow mission handlers for the same event to create their FLIGHTGROUP first.
function MOOSE_BRIDGE:OnEventPlayerEnterAircraft(EventData)
  if type(EventData) ~= "table" then
    self:_Log("Cannot schedule PlayerEnterAircraft: event data is missing")
    return
  end
  -- MOOSE may reuse the event table; preserve its fields and original time.
  local pending = {}
  for key, value in pairs(EventData) do pending[key] = value end
  self.PendingPlayerAircraftEnters = self.PendingPlayerAircraftEnters or {}
  -- BASE:ScheduleOnce reuses self.Scheduler and changes its MasterObject to
  -- nil. That scheduler drives _Tick and must retain the bridge as its owner.
  -- Keep this one-shot scheduler separate and alive until the entry is flushed.
  self.PendingPlayerAircraftEnters[pending] = SCHEDULER:New(self, function(bridge)
    bridge:_FlushPendingPlayerAircraftEnter(pending)
  end, {}, 0.5)
end

--- Forward DCS S_EVENT_PLAYER_LEAVE_UNIT and close the cached player session.
function MOOSE_BRIDGE:OnEventPlayerLeaveUnit(EventData)
  -- A rapid exit must never be followed by a delayed, stale entry in Python.
  -- Flush its pending entry first so Enter -> Leave ordering is preserved.
  if type(EventData) == "table" then
    local player_name = EventData.IniPlayerName or EventData.PlayerName
    local unit_name = EventData.IniUnitName or EventData.IniDCSUnitName
    for pending, _ in pairs(self.PendingPlayerAircraftEnters or {}) do
      local pending_player = pending.IniPlayerName or pending.PlayerName
      local pending_unit = pending.IniUnitName or pending.IniDCSUnitName
      if (player_name and pending_player == player_name)
        or (not player_name and unit_name and pending_unit == unit_name) then
        self:_FlushPendingPlayerAircraftEnter(pending)
      end
    end
  end
  self:_ForwardPlayerAircraftEvent(
    EventData,
    "player.aircraft.left",
    "S_EVENT_PLAYER_LEAVE_UNIT",
    false
  )
end

--- Forward one DCS F10 map-marker event without interpreting its text.
-- Marker commands remain a Python concern so the Lua bridge stays semantic
-- and does not couple mission scripts to verification workflows.
function MOOSE_BRIDGE:_ForwardMapMarker(EventData, event_name, dcs_event_name)
  local ok, err = pcall(function()
    if type(EventData) ~= "table" then error("Map marker event data is missing") end
    local marker_id = EventData.MarkID or EventData.idx
    if marker_id == nil then error("Map marker event has no marker ID") end
    local point = EventData.MarkVec3 or EventData.pos
    local coordinates = point and self:_CoordinatesForPoint(point, "ll") or {}
    self:SendEvent(event_name, {
      dcs_event_id=EventData.id,
      dcs_event_name=dcs_event_name,
      dcs_event_time=EventData.time,
      marker_id=marker_id,
      text=EventData.MarkText or EventData.text,
      coalition=self:_CoalitionToName(EventData.MarkCoalition or EventData.coalition),
      group_id=EventData.MarkGroupID or EventData.groupID,
      player_name=EventData.PlayerName,
      x=coordinates.x,
      y=coordinates.y,
      z=coordinates.z,
      latitude=coordinates.latitude,
      longitude=coordinates.longitude,
    })
  end)
  if not ok then
    self:_Log("Failed to forward " .. tostring(dcs_event_name) .. " event: " .. tostring(err))
  end
end

function MOOSE_BRIDGE:OnEventMarkAdded(EventData)
  self:_ForwardMapMarker(EventData, "map.marker.added", "S_EVENT_MARK_ADDED")
end

function MOOSE_BRIDGE:OnEventMarkChange(EventData)
  self:_ForwardMapMarker(EventData, "map.marker.changed", "S_EVENT_MARK_CHANGE")
end

function MOOSE_BRIDGE:OnEventMarkRemoved(EventData)
  self:_ForwardMapMarker(EventData, "map.marker.removed", "S_EVENT_MARK_REMOVED")
end

--- Forward DCS S_EVENT_MISSION_END as the authoritative Python session boundary.
-- Flush immediately because normal bridge scheduling stops with the mission.
-- @param Core.Event#EVENTDATA EventData MOOSE-normalized DCS event data.
function MOOSE_BRIDGE:OnEventMissionEnd(EventData)
  self.PendingPlayerAircraftEnters = {}
  self.PlayerTestMenuConfig = nil
  self:_ClearPlayerTestMenus()
  self.PlayerAircraftSessions = {}
  local ok, err = pcall(function()
    self:SendEvent("mission.ended", {
      dcs_event_id=EventData and EventData.id or nil,
      dcs_event_name="S_EVENT_MISSION_END",
      dcs_event_time=EventData and EventData.time or nil,
      reason="dcs_mission_end",
    })
    self:_FlushOutQueue()
  end)
  if not ok then
    self:_Log("Failed to forward MissionEnd event: " .. tostring(err))
  end
end
