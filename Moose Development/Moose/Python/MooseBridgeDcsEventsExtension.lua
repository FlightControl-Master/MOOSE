--- DCS world event forwarding for MOOSE_BRIDGE.
--
-- Load after MooseBridge.lua and before constructing/starting the bridge.
-- DCS events are normalized here; Python never needs to understand the raw
-- world event table or MOOSE EVENTDATA implementation details.

if not MOOSE_BRIDGE then error("Load MooseBridge.lua before MooseBridgeDcsEventsExtension.lua") end
-- Repeated dofile() must not stack command-registration wrappers. Updates need
-- a fresh mission, not a reload into a running bridge instance.
if MOOSE_BRIDGE._DcsEventsExtensionLoaded then return end
MOOSE_BRIDGE._DcsEventsExtensionLoaded = true

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
  self:_ClearSpeechQueues()
  self.SpeechConfig = nil
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
  self:RegisterCommand("player.menu.navigation.status", function(cmd)
    return self:_NavigationRuntimeStatus()
  end)
  self:RegisterCommand("player.menu.navigation.context", function(cmd)
    local params = cmd.params or {}
    local entry = self:_NavigationMenuEntry(params)
    return self:_NavigationMenuPayload(entry.group:GetName(), entry)
  end)
  self:RegisterCommand("player.menu.navigation.flight_status", function(cmd)
    return self:_GetPlayerFlightStatus(cmd.params or {})
  end)
  self:RegisterCommand("player.menu.navigation.navaids.page", function(cmd)
    return self:_UpdateNavaidMenuPage(cmd.params or {})
  end)
  self:RegisterCommand("player.menu.navigation.navaids.initialize", function(cmd)
    return self:_InitializeNavaidMenus(cmd.params or {})
  end)
  self:RegisterCommand("player.menu.navigation.navaids.overlay", function(cmd)
    return self:_UpdateNavaidOverlay(cmd.params or {})
  end)
  self:RegisterCommand("player.menu.navigation.airfields.resolve", function(cmd)
    return self:_ResolveNavigationAirbases(cmd.params or {})
  end)
  self:RegisterCommand("player.menu.navigation.airfields.page", function(cmd)
    return self:_UpdateAirfieldMenuPage(cmd.params or {})
  end)
  self:RegisterCommand("player.menu.navigation.airfields.initialize", function(cmd)
    return self:_InitializeAirfieldMenu(cmd.params or {})
  end)
  self:RegisterCommand("player.menu.navigation.message", function(cmd)
    local params = cmd.params or {}
    local entry = self:_NavigationMenuEntry(params)
    if params.navaid_type ~= nil then
      local state = self:_NavaidMenuGuard(entry, params)
      if params.station_key ~= nil and (not state.keys[params.station_key] or type(params.unit_id) ~= "string") then
        error("Navaid selection is not on this page or has no reference aircraft")
      end
    end
    if params.airfield_revision ~= nil then
      local state = self:_AirfieldMenuGuard(entry, params)
      if type(params.station_key) ~= "string" or not state.keys[params.station_key]
        or type(params.unit_id) ~= "string" then
        error("Airfield selection is not on this page or has no reference aircraft")
      end
    end
    if params.selection_id ~= nil then self:_NavaidSelectionGuard(entry, params) end
    if params.unit_id ~= nil then
      local unit_name = self:_FlightStatusReferenceUnit(entry)
      if params.unit_id ~= "UNIT:" .. unit_name then error("Flight status reference aircraft changed") end
    end
    if type(params.text) ~= "string" or #params.text == 0 or #params.text > 2000 then
      error("navigation message text must contain 1..2000 bytes")
    end
    local duration = params.duration_s == nil and 10 or params.duration_s
    if type(duration) ~= "number" or not (duration >= 1 and duration <= 30) then
      error("navigation message duration_s must be between 1 and 30 seconds")
    end
    MESSAGE:New(params.text, duration, "Navigation"):ToGroup(entry.group)
    local result = {delivered=true}
    if params.navaid_type ~= nil and params.station_key ~= nil then
      entry.navaid_selection_serial = (entry.navaid_selection_serial or 0) + 1
      entry.navaid_selection = {id=tostring(entry.navaid_selection_serial), unit_id=params.unit_id,
        theater_id=params.theater_id, kind=params.navaid_type, key=params.station_key}
      result.selection_id = entry.navaid_selection.id
    end
    return result
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
  self:RegisterCommand("speech.status", function(cmd)
    return self:_SpeechStatus()
  end)
  self:RegisterCommand("speech.configure", function(cmd)
    return self:_ConfigureSpeech(cmd.params or {})
  end)
  self:RegisterCommand("speech.test_tone", function(cmd)
    return self:_SpeechTestTone(cmd.params or {})
  end)
  self:RegisterCommand("speech.enqueue", function(cmd)
    return self:_EnqueueSpeech(cmd.params or {})
  end)
  self:RegisterCommand("speech.clear", function(cmd)
    return self:_ClearSpeechCommand(cmd.params or {})
  end)
end

--- Read-only preflight and ownership inspection, independent of occupied slots.
function MOOSE_BRIDGE:_NavigationRuntimeStatus()
  local config = self.PlayerTestMenuConfig
  local drawings = type(self._DrawDebugOverlay) == "function" and type(self._ClearDebugOverlay) == "function"
  return {api_version=1, instance_id=tostring(self) .. ":" .. tostring(env and env.mission),
    theater_id=env and env.mission and env.mission.theatre or nil,
    ready=MENU_GROUP ~= nil and MENU_GROUP_COMMAND ~= nil and MESSAGE ~= nil and _DATABASE ~= nil,
    capabilities={player_lifecycle=type(self._ForwardPlayerAircraftEvent) == "function",
      route=type(self._GetFlightGroupRoute) == "function" and drawings,
      flight_status=type(self._GetPlayerFlightStatus) == "function",
      navaids=type(self._UpdateNavaidMenuPage) == "function",
      navaids_initialize=type(self._InitializeNavaidMenus) == "function",
      navaid_overlay=type(self._UpdateNavaidOverlay) == "function" and drawings and type(self._CreateMapMarker) == "function",
      airfield_radios=type(self._ResolveNavigationAirbases) == "function"
        and type(self._UpdateAirfieldMenuPage) == "function" and type(self._InitializeAirfieldMenu) == "function",
      airfield_runways=type(self._BuildNavigationRunwayData) == "function",
      speech=type(self._ConfigureSpeech) == "function" and type(self._EnqueueSpeech) == "function"},
    enabled=config ~= nil, owner_id=config and config.owner_id or nil,
    mode=config and config.mode or nil}
end

local function speech_number(value, minimum, maximum)
  return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
    and value >= minimum and value <= maximum
end

local function speech_string(value, maximum)
  return type(value) == "string" and #value > 0 and #value <= maximum and not value:find("[%c]")
end

local function speech_now()
  return timer and timer.getTime and timer.getTime() or 0
end

local function speech_coalition_id(value)
  if value == 0 or value == "neutral" then return 0 end
  if value == 1 or value == "red" then return 1 end
  if value == 2 or value == "blue" then return 2 end
  return nil
end

function MOOSE_BRIDGE:_SpeechStatus()
  local available = type(HoundTTS) == "table" and type(HoundTTS.Transmit) == "function"
    and type(HoundTTS.TestTone) == "function" and type(HoundTTS.getSpeechTime) == "function"
    and type(MSRS) == "table" and type(MSRS.New) == "function"
  local config = self.SpeechConfig
  local sender_count, pending_count, active_count, network_count = 0, 0, 0, 0
  for _, sender in pairs(self.SpeechSenders or {}) do
    sender_count = sender_count + 1
    pending_count = pending_count + #(sender.queue or {})
    if sender.active then active_count = active_count + 1 end
  end
  for _ in pairs(self.SpeechNetworks or {}) do network_count = network_count + 1 end
  return {api_version=2, available=available, enabled=config ~= nil,
    owner_id=config and config.owner_id or nil,
    profile_count=config and config.profile_count or 0,
    hound_host=type(HoundTTS) == "table" and HoundTTS.SRS_HOST or nil,
    hound_transmitter=type(HoundTTS) == "table" and HoundTTS.DEFAULT_TRANSMITTER or nil,
    sender_count=sender_count, network_count=network_count,
    pending_count=pending_count, active_count=active_count,
    synthetic_only=true, human_ptt_observed=false}
end

function MOOSE_BRIDGE:_ClearSpeechQueues()
  self.SpeechSenders = {}
  self.SpeechNetworks = {}
  self.SpeechTransmitters = {}
  self.SpeechIntentHistory = {}
  self.SpeechSerial = 0
end

function MOOSE_BRIDGE:_ValidateSpeechProfile(profile, fallback_id)
  if type(profile) ~= "table" then error("speech profile is required") end
  local profile_id = profile.profile_id or fallback_id
  if not speech_string(profile_id, 128) then error("speech profile profile_id is invalid") end
  if not speech_string(profile.network_id, 128) then error("speech profile network_id is invalid") end
  for _, key in ipairs({"srs_path", "srs_host", "provider", "voice", "label"}) do
    if not speech_string(profile[key], key == "srs_path" and 512 or 128) then
      error("speech profile " .. key .. " is invalid")
    end
  end
  if not speech_number(profile.srs_port, 1, 65535)
    or profile.srs_port ~= math.floor(profile.srs_port) then error("speech profile srs_port is invalid") end
  if not speech_number(profile.frequency_mhz, 1, 1000) then error("speech profile frequency_mhz is invalid") end
  if profile.modulation ~= "AM" and profile.modulation ~= "FM" then
    error("speech profile modulation must be AM or FM")
  end
  if not speech_number(profile.volume, 0, 1) then error("speech profile volume is invalid") end
  if not speech_number(profile.speed, 0.1, 4) then error("speech profile speed is invalid") end
  if not speech_number(profile.interval_s, 0, 30) then error("speech profile interval_s is invalid") end
  if profile.arbitration ~= "strict" and profile.arbitration ~= "disciplined"
    and profile.arbitration ~= "congested" and profile.arbitration ~= "uncontrolled" then
    error("speech profile arbitration is invalid")
  end
  if not speech_number(profile.backoff_min_s, 0, 30)
    or not speech_number(profile.backoff_max_s, profile.backoff_min_s, 30) then
    error("speech profile backoff range is invalid")
  end
  if not speech_number(profile.collision_probability, 0, 1) then
    error("speech profile collision_probability is invalid")
  end
  if type(profile.emergency_break_in) ~= "boolean" then
    error("speech profile emergency_break_in must be boolean")
  end
  local hound_host = HoundTTS.SRS_HOST or "127.0.0.1"
  if profile.srs_host ~= hound_host then
    error("speech profile srs_host does not match HoundTTS.SRS_HOST (" .. tostring(hound_host) .. ")")
  end
  if HoundTTS.DEFAULT_TRANSMITTER ~= "srs" then
    error("HoundTTS.DEFAULT_TRANSMITTER must be 'srs', not '"
      .. tostring(HoundTTS.DEFAULT_TRANSMITTER) .. "'; Piper belongs in DEFAULT_PROVIDER")
  end
  return {profile_id=profile_id, network_id=profile.network_id,
    srs_path=profile.srs_path, srs_host=profile.srs_host, srs_port=profile.srs_port,
    frequency_mhz=profile.frequency_mhz, modulation=profile.modulation,
    provider=profile.provider, voice=profile.voice, label=profile.label,
    volume=profile.volume, speed=profile.speed, interval_s=profile.interval_s,
    arbitration=profile.arbitration, backoff_min_s=profile.backoff_min_s,
    backoff_max_s=profile.backoff_max_s,
    collision_probability=profile.collision_probability,
    emergency_break_in=profile.emergency_break_in}
end

function MOOSE_BRIDGE:_ConfigureSpeech(params)
  if params.expected_instance_id ~= nil and params.expected_instance_id ~= self:_NavigationRuntimeStatus().instance_id then
    error("Speech bridge instance changed")
  end
  if type(params.enabled) ~= "boolean" then error("enabled must be boolean") end
  if not speech_string(params.owner_id, 128) then
    error("owner_id must be a non-empty string of at most 128 characters")
  end
  if not params.enabled then
    if self.SpeechConfig and self.SpeechConfig.owner_id == params.owner_id then
      self:_ClearSpeechQueues()
      self.SpeechConfig = nil
    end
    return self:_SpeechStatus()
  end
  if not self:_SpeechStatus().available then
    error("HoundTTS and MSRS with the Hound backend are required for speech")
  end
  local requested = params.profiles
  if requested == nil and type(params.profile) == "table" then requested = {params.profile} end
  if type(requested) ~= "table" or #requested == 0 or #requested > 64 then
    error("profiles must contain 1..64 speech profiles")
  end
  local profiles, networks, frequencies = {}, {}, {}
  for index, item in ipairs(requested) do
    local profile = self:_ValidateSpeechProfile(item, index == 1 and "default" or nil)
    if profiles[profile.profile_id] then error("duplicate speech profile_id " .. profile.profile_id) end
    local signature = table.concat({profile.frequency_mhz, profile.modulation, profile.arbitration,
      profile.interval_s, profile.backoff_min_s, profile.backoff_max_s,
      profile.collision_probability, tostring(profile.emergency_break_in)}, ":")
    if networks[profile.network_id] and networks[profile.network_id] ~= signature then
      error("profiles on one network_id must use the same frequency and arbitration policy")
    end
    local frequency_key = string.format("%.3f:%s", profile.frequency_mhz, profile.modulation)
    if frequencies[frequency_key] and frequencies[frequency_key] ~= profile.network_id then
      error("profiles on one frequency/modulation must use the same network_id")
    end
    networks[profile.network_id] = signature
    frequencies[frequency_key] = profile.network_id
    profiles[profile.profile_id] = profile
  end
  self:_ClearSpeechQueues()
  self.SpeechConfig = {owner_id=params.owner_id, profiles=profiles, profile_count=#requested}
  return self:_SpeechStatus()
end

function MOOSE_BRIDGE:_SpeechProfileGuard(params)
  if not self.SpeechConfig or self.SpeechConfig.owner_id ~= params.owner_id then
    error("Speech service is not owned by this client")
  end
  local profile = self.SpeechConfig.profiles[params.profile_id]
  if not profile then error("Unknown speech profile_id") end
  return profile
end

function MOOSE_BRIDGE:_SpeechSenderKey(sender)
  if type(sender) ~= "table" or not speech_string(sender.sender_id, 128)
    or not speech_string(sender.radio_id, 128) then error("speech sender identity is invalid") end
  if sender.kind ~= "player" and sender.kind ~= "unit" and sender.kind ~= "group"
    and sender.kind ~= "airbase" and sender.kind ~= "coordinate" then
    error("speech sender kind is invalid")
  end
  return table.concat({sender.kind, sender.sender_id, sender.radio_id}, ":")
end

function MOOSE_BRIDGE:_ResolveSpeechSender(sender)
  local sender_key = self:_SpeechSenderKey(sender)
  local object, coordinate, coalition_id
  if sender.kind == "player" then
    if not speech_string(sender.group_id, 256) or not speech_string(sender.session_id, 128) then
      error("player speech sender requires group_id and session_id")
    end
    local entry = self:_NavigationMenuEntry({owner_id=self.SpeechConfig.owner_id,
      group_id=sender.group_id, session_id=sender.session_id})
    local _, _, wrapper = self:_FlightStatusReferenceUnit(entry)
    object = wrapper
    coordinate = self:_SafeCall(wrapper, "GetCoordinate")
    coalition_id = self:_SafeCall(entry.group, "GetCoalition")
  elseif sender.kind == "coordinate" then
    if not speech_number(sender.x, -20000000, 20000000)
      or not speech_number(sender.y, -100000, 1000000)
      or not speech_number(sender.z, -20000000, 20000000)
      or type(COORDINATE) ~= "table" or type(COORDINATE.New) ~= "function" then
      error("coordinate speech sender is invalid")
    end
    coordinate = COORDINATE:New(sender.x, sender.y, sender.z)
    coalition_id = speech_coalition_id(sender.coalition)
  else
    if not speech_string(sender.object_id, 256) then error("speech sender object_id is invalid") end
    local prefix, name = string.match(sender.object_id, "^(%u+):(.+)$")
    local expected = sender.kind == "unit" and "UNIT" or sender.kind == "group" and "GROUP" or "AIRBASE"
    if prefix ~= expected or not _DATABASE then error("speech sender object_id does not match its kind") end
    local collection = expected == "UNIT" and _DATABASE.UNITS
      or expected == "GROUP" and _DATABASE.GROUPS or _DATABASE.AIRBASES
    object = type(collection) == "table" and collection[name] or nil
    if not object then error("speech sender DCS object is unavailable") end
    if expected == "UNIT" and self:_SafeCall(object, "IsExist") == false then
      error("speech sender unit no longer exists")
    end
    if expected == "GROUP" and self:_SafeCall(object, "IsAlive") == false then
      error("speech sender group is no longer alive")
    end
    coordinate = self:_SafeCall(object, "GetCoordinate")
    coalition_id = self:_SafeCall(object, "GetCoalition")
  end
  coalition_id = speech_coalition_id(coalition_id)
  if not coordinate then error("speech sender coordinate is unavailable") end
  if coalition_id == nil then error("speech sender coalition is unavailable") end
  return {key=sender_key, descriptor=sender, object=object,
    coordinate=coordinate, coalition_id=coalition_id}
end

function MOOSE_BRIDGE:_SpeechNetwork(profile, coalition_id)
  local key = table.concat({coalition_id, profile.network_id,
    string.format("%.3f", profile.frequency_mhz), profile.modulation}, ":")
  self.SpeechNetworks = self.SpeechNetworks or {}
  local network = self.SpeechNetworks[key]
  if not network then
    network = {key=key, network_id=profile.network_id, coalition_id=coalition_id,
      mode=profile.arbitration, active={}, busy_until=0}
    self.SpeechNetworks[key] = network
  end
  return network
end

function MOOSE_BRIDGE:_SpeechTransmitter(profile, coalition_id)
  local modulation = profile.modulation == "AM" and radio.modulation.AM or radio.modulation.FM
  local key = table.concat({profile.profile_id, coalition_id}, ":")
  self.SpeechTransmitters = self.SpeechTransmitters or {}
  local item = self.SpeechTransmitters[key]
  if not item then
    local msrs = MSRS:New(profile.srs_path, profile.frequency_mhz, modulation, MSRS.Backend.HOUND)
    msrs:SetProvider(profile.provider)
    msrs:SetCoalition(coalition_id)
    msrs:SetVoice(profile.voice)
    msrs:SetVolume(profile.volume)
    msrs:SetLabel(profile.label)
    msrs:SetPort(profile.srs_port)
    item = {msrs=msrs, key=key}
    self.SpeechTransmitters[key] = item
  end
  return item
end

function MOOSE_BRIDGE:_SpeechTestTone(params)
  local profile = self:_SpeechProfileGuard(params)
  local sender = self:_ResolveSpeechSender(params.sender)
  HoundTTS.TestTone(string.format("%.3f", profile.frequency_mhz), profile.modulation,
    sender.coalition_id, 2, profile.volume)
  return {requested=true, frequency_mhz=profile.frequency_mhz,
    modulation=profile.modulation, coalition=sender.coalition_id,
    profile_id=profile.profile_id, sender_id=params.sender.sender_id}
end

function MOOSE_BRIDGE:_EnqueueSpeech(params)
  local profile = self:_SpeechProfileGuard(params)
  if not speech_string(params.intent_id, 128) then error("speech intent_id is invalid") end
  self.SpeechIntentHistory = self.SpeechIntentHistory or {}
  local previous = self.SpeechIntentHistory[params.intent_id]
  if previous then
    return {queued=previous.status == "queued", duplicate=true, status=previous.status,
      intent_id=params.intent_id, sender_queue_depth=previous.sender_queue_depth or 0,
      frequency_mhz=profile.frequency_mhz, modulation=profile.modulation,
      provider=profile.provider, voice=profile.voice}
  end
  if not speech_string(params.text, 1000) then error("speech text must contain 1..1000 printable bytes") end
  local priority = params.priority == nil and 50 or params.priority
  if not speech_number(priority, 1, 100) or priority ~= math.floor(priority) then
    error("speech priority must be an integer from 1 to 100")
  end
  if params.urgency ~= "routine" and params.urgency ~= "urgent" and params.urgency ~= "emergency" then
    error("speech urgency must be routine, urgent, or emergency")
  end
  if not speech_number(params.ttl_s, 0.1, 3600) then error("speech ttl_s must be between 0.1 and 3600") end
  if params.dedupe_key ~= nil and not speech_string(params.dedupe_key, 128) then
    error("speech dedupe_key is invalid")
  end
  local resolved = self:_ResolveSpeechSender(params.sender)
  local ok, duration = pcall(HoundTTS.getSpeechTime, params.text, profile.speed, false)
  if not ok or not speech_number(duration, 0.1, 600) then
    error("HoundTTS could not estimate the speech duration")
  end
  self.SpeechSenders = self.SpeechSenders or {}
  local sender = self.SpeechSenders[resolved.key]
  if not sender then
    sender = {key=resolved.key, descriptor=params.sender, queue={}}
    self.SpeechSenders[resolved.key] = sender
  end
  if params.dedupe_key then
    for index=#sender.queue, 1, -1 do
      if sender.queue[index].dedupe_key == params.dedupe_key then
        self.SpeechIntentHistory[sender.queue[index].intent_id] = {
          status="superseded", completed_at=speech_now()}
        table.remove(sender.queue, index)
      end
    end
  end
  self.SpeechSerial = (self.SpeechSerial or 0) + 1
  local now = speech_now()
  local network = self:_SpeechNetwork(profile, resolved.coalition_id)
  local intent = {intent_id=params.intent_id, profile=profile, sender=params.sender,
    sender_key=resolved.key, network_key=network.key, text=params.text,
    priority=priority, urgency=params.urgency, dedupe_key=params.dedupe_key,
    duration=duration, created_at=now, expires_at=now + params.ttl_s,
    available_at=now, serial=self.SpeechSerial, owner_id=params.owner_id}
  sender.queue[#sender.queue + 1] = intent
  table.sort(sender.queue, function(a, b)
    return a.priority > b.priority or (a.priority == b.priority and a.serial < b.serial)
  end)
  self.SpeechIntentHistory[params.intent_id] = {status="queued", created_at=now,
    sender_key=resolved.key, sender_queue_depth=#sender.queue}
  return {queued=true, estimated_duration_s=duration,
    sender_queue_depth=#sender.queue, network_id=profile.network_id,
    network_mode=profile.arbitration, intent_id=params.intent_id,
    frequency_mhz=profile.frequency_mhz, modulation=profile.modulation,
    provider=profile.provider, voice=profile.voice, priority=priority,
    urgency=params.urgency, expires_at=now + params.ttl_s}
end

function MOOSE_BRIDGE:_SpeechDrop(sender, index, status, now, reason)
  local intent = table.remove(sender.queue, index)
  if not intent then return nil end
  self.SpeechIntentHistory[intent.intent_id] = {status=status, completed_at=now,
    sender_key=sender.key, reason=reason}
  local ok, err = pcall(function()
    self:SendEvent("speech.intent." .. status, {intent_id=intent.intent_id,
      profile_id=intent.profile.profile_id, network_id=intent.profile.network_id,
      sender_id=intent.sender.sender_id, radio_id=intent.sender.radio_id,
      reason=reason})
  end)
  if not ok then self:_Log("Failed to forward speech intent state: " .. tostring(err)) end
  return intent
end

function MOOSE_BRIDGE:_StartSpeechIntent(sender, intent, network, now)
  local ok_resolve, resolved = pcall(function() return self:_ResolveSpeechSender(intent.sender) end)
  if not ok_resolve then
    self:_SpeechDrop(sender, 1, "dropped", now, "sender unavailable: " .. tostring(resolved))
    return false
  end
  if resolved.coalition_id ~= network.coalition_id then
    self:_SpeechDrop(sender, 1, "dropped", now, "sender coalition changed")
    return false
  end
  local transmitter = self:_SpeechTransmitter(intent.profile, resolved.coalition_id)
  local ok_play, err = pcall(function()
    transmitter.msrs:PlayTextExt(intent.text, nil, nil, nil, nil, nil, nil, nil, nil,
      resolved.coordinate, intent.profile.speed, nil)
  end)
  if not ok_play then
    self:_SpeechDrop(sender, 1, "dropped", now, "MSRS transmission failed: " .. tostring(err))
    return false
  end
  table.remove(sender.queue, 1)
  local transmission = {intent=intent, sender_key=sender.key, network_key=network.key,
    started_at=now, ends_at=now + intent.duration,
    guard_until=now + intent.duration + intent.profile.interval_s}
  sender.active = transmission
  network.active[intent.intent_id] = transmission
  if transmission.guard_until > network.busy_until then network.busy_until = transmission.guard_until end
  self.SpeechIntentHistory[intent.intent_id] = {status="transmitting", started_at=now,
    sender_key=sender.key, sender_queue_depth=#sender.queue}
  local ok_event, event_err = pcall(function()
    self:SendEvent("speech.transmission.started", {intent_id=intent.intent_id,
      profile_id=intent.profile.profile_id, network_id=intent.profile.network_id,
      sender_id=intent.sender.sender_id, radio_id=intent.sender.radio_id,
      priority=intent.priority, urgency=intent.urgency,
      estimated_duration_s=intent.duration})
  end)
  if not ok_event then self:_Log("Failed to forward speech start: " .. tostring(event_err)) end
  return true
end

function MOOSE_BRIDGE:_SpeechBackoff(intent)
  local minimum, maximum = intent.profile.backoff_min_s, intent.profile.backoff_max_s
  if maximum <= minimum then return minimum end
  return minimum + ((intent.serial * 7919) % 1000) / 1000 * (maximum - minimum)
end

function MOOSE_BRIDGE:_SpeechCollision(intent)
  return ((intent.serial * 7919) % 1000) / 1000 < intent.profile.collision_probability
end

function MOOSE_BRIDGE:_SpeechTick(now)
  if not self.SpeechConfig then return self end
  now = type(now) == "number" and now or speech_now()
  for _, sender in pairs(self.SpeechSenders or {}) do
    local active = sender.active
    if active and now >= active.ends_at then
      sender.active = nil
      local network = self.SpeechNetworks and self.SpeechNetworks[active.network_key]
      if network then network.active[active.intent.intent_id] = nil end
      self.SpeechIntentHistory[active.intent.intent_id] = {status="completed", completed_at=now,
        sender_key=sender.key, sender_queue_depth=#sender.queue}
      local ok, err = pcall(function()
        self:SendEvent("speech.transmission.completed", {intent_id=active.intent.intent_id,
          profile_id=active.intent.profile.profile_id, network_id=active.intent.profile.network_id,
          sender_id=active.intent.sender.sender_id, radio_id=active.intent.sender.radio_id})
      end)
      if not ok then self:_Log("Failed to forward speech completion: " .. tostring(err)) end
    end
    for index=#sender.queue, 1, -1 do
      if now >= sender.queue[index].expires_at then
        self:_SpeechDrop(sender, index, "expired", now, "time-to-live elapsed")
      end
    end
  end
  local candidates = {}
  for _, sender in pairs(self.SpeechSenders or {}) do
    local intent = not sender.active and sender.queue[1] or nil
    if intent and now >= intent.available_at then
      candidates[intent.network_key] = candidates[intent.network_key] or {}
      candidates[intent.network_key][#candidates[intent.network_key] + 1] = {sender=sender, intent=intent}
    end
  end
  for network_key, list in pairs(candidates) do
    local network = self.SpeechNetworks[network_key]
    table.sort(list, function(a, b)
      return a.intent.priority > b.intent.priority
        or (a.intent.priority == b.intent.priority and a.intent.serial < b.intent.serial)
    end)
    local busy = now < (network.busy_until or 0)
    if network.mode == "uncontrolled" then
      for _, candidate in ipairs(list) do
        self:_StartSpeechIntent(candidate.sender, candidate.intent, network, now)
      end
    elseif not busy then
      local first = table.remove(list, 1)
      if first then self:_StartSpeechIntent(first.sender, first.intent, network, now) end
      if network.mode == "congested" then
        for _, candidate in ipairs(list) do
          if self:_SpeechCollision(candidate.intent) then
            self:_StartSpeechIntent(candidate.sender, candidate.intent, network, now)
          end
        end
      end
      for _, candidate in ipairs(list) do
        if candidate.sender.queue[1] == candidate.intent then
          candidate.intent.available_at = math.max(candidate.intent.available_at,
            network.busy_until + (network.mode == "strict" and 0 or self:_SpeechBackoff(candidate.intent)))
        end
      end
    else
      local break_in
      for _, candidate in ipairs(list) do
        if candidate.intent.urgency == "emergency" and candidate.intent.profile.emergency_break_in then
          break_in = candidate
          break
        end
      end
      if break_in then self:_StartSpeechIntent(break_in.sender, break_in.intent, network, now) end
      if not break_in and network.mode == "congested" then
        for _, candidate in ipairs(list) do
          if self:_SpeechCollision(candidate.intent) then
            self:_StartSpeechIntent(candidate.sender, candidate.intent, network, now)
            break
          end
        end
      end
      for _, candidate in ipairs(list) do
        if candidate.sender.queue[1] == candidate.intent then
          candidate.intent.available_at = math.max(candidate.intent.available_at,
            network.busy_until + (network.mode == "strict" and 0 or self:_SpeechBackoff(candidate.intent)))
        end
      end
    end
  end
  for intent_id, history in pairs(self.SpeechIntentHistory or {}) do
    if history.completed_at and now - history.completed_at > 3600 then
      self.SpeechIntentHistory[intent_id] = nil
    end
  end
  return self
end

function MOOSE_BRIDGE:_ClearSpeechCommand(params)
  if not self.SpeechConfig or self.SpeechConfig.owner_id ~= params.owner_id then
    error("Speech service is not owned by this client")
  end
  if params.sender == nil then
    local active = {}
    for key, sender in pairs(self.SpeechSenders or {}) do
      for index=#sender.queue, 1, -1 do
        self:_SpeechDrop(sender, index, "canceled", speech_now(), "cleared by owner")
      end
      if sender.active then active[key] = sender end
    end
    self.SpeechSenders = active
    return {cleared=true, scope="all_pending"}
  end
  local key = self:_SpeechSenderKey(params.sender)
  local sender = self.SpeechSenders and self.SpeechSenders[key]
  local removed = sender and #sender.queue or 0
  if sender then
    for index=#sender.queue, 1, -1 do
      self:_SpeechDrop(sender, index, "canceled", speech_now(), "sender queue cleared by owner")
    end
  end
  return {cleared=true, scope="sender", sender_key=key, removed=removed}
end

function MOOSE_BRIDGE:_RemoveSpeechMenuSession(entry)
  for _, sender in pairs(self.SpeechSenders or {}) do
    for index=#sender.queue, 1, -1 do
      local descriptor = sender.queue[index].sender
      if descriptor.kind == "player" and descriptor.group_id == "GROUP:" .. entry.group:GetName()
        and descriptor.session_id == entry.session_id then
        self:_SpeechDrop(sender, index, "dropped", speech_now(), "player menu session ended")
      end
    end
  end
end

-- The bridge already ticks at 5 Hz. Compose speech arbitration into that
-- scheduler instead of creating one scheduler per sender or radio network.
local _speech_bridge_tick = MOOSE_BRIDGE._Tick
if type(_speech_bridge_tick) == "function" then
  function MOOSE_BRIDGE:_Tick(...)
    local result = _speech_bridge_tick(self, ...)
    if self.SpeechConfig then
      local ok, err = pcall(function() self:_SpeechTick() end)
      if not ok then self:_Log("Speech arbitration tick failed: " .. tostring(err)) end
    end
    return result
  end
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
    theater_id=env and env.mission and env.mission.theatre or nil,
    opsgroup_id=opsgroup and ("OPSGROUP:" .. group_name) or nil}
end

-- Reserve one position for DCS back navigation: at most nine owned children.
-- Type pages: seven types + More types. Station pages: six + refresh + prev/next.
local navaid_types = {{"TACAN", "TACAN"}, {"VOR", "VOR"}, {"DME", "DME"},
  {"VOR_DME", "VOR/DME"}, {"VORTAC", "VORTAC"}, {"NDB", "NDB"}, {"ILS", "ILS"},
  {"RSBN", "RSBN"}, {"PRMG", "PRMG"}, {"ICLS", "ICLS"}, {"OTHER", "Other / unknown"}}

function MOOSE_BRIDGE:_NavaidMenuGuard(entry, params)
  local state = entry.navaids and entry.navaids[params.navaid_type]
  if not state or state.revision ~= params.navaid_revision then error("Navaid menu page is stale") end
  if type(params.theater_id) ~= "string" or not env or not env.mission
    or params.theater_id ~= env.mission.theatre then error("Navaid terrain does not match the mission") end
  return state
end

function MOOSE_BRIDGE:_NavaidMenuSelected(entry, kind, revision, action, page, station_key)
  local state = entry.navaids and entry.navaids[kind]
  if not state or state.revision ~= revision then return end
  local ok = pcall(function() self:_NavigationMenuEntry({owner_id=entry.owner_id,
    group_id="GROUP:" .. entry.group:GetName(), session_id=entry.session_id}) end)
  if not ok then return end
  if action == "navaid_details" then
    if not state.keys[station_key] then return end
  else
    state.request_id = state.request_id + 1
  end
  local payload = self:_NavigationMenuPayload(entry.group:GetName(), entry)
  payload.action, payload.navaid_type = action, kind
  payload.navaid_revision, payload.request_id = revision, tostring(state.request_id)
  payload.page, payload.station_key = page, station_key
  self:SendEvent("player.menu.selected", payload)
end

function MOOSE_BRIDGE:_BuildNavaidMenuPage(entry, kind, state, items)
  local revision = state.revision
  MENU_GROUP_COMMAND:New(entry.group, "Refresh nearby", state.menu, function()
    self:_NavaidMenuSelected(entry, kind, revision, "navaids_refresh", 0)
  end)
  for _, item in ipairs(items) do
    local key = item.key
    state.keys[key] = true
    MENU_GROUP_COMMAND:New(entry.group, item.label, state.menu, function()
      self:_NavaidMenuSelected(entry, kind, revision, "navaid_details", state.page, key)
    end)
  end
  if state.page > 0 then
    MENU_GROUP_COMMAND:New(entry.group, "Previous page", state.menu, function()
      self:_NavaidMenuSelected(entry, kind, revision, "navaids_page", state.page - 1)
    end)
  end
  if state.page + 1 < state.pages then
    MENU_GROUP_COMMAND:New(entry.group, "Next page", state.menu, function()
      self:_NavaidMenuSelected(entry, kind, revision, "navaids_page", state.page + 1)
    end)
  end
end

function MOOSE_BRIDGE:_CreateNavaidMenus(entry)
  entry.navaids = {}
  local parent = MENU_GROUP:New(entry.group, "Navaids", entry.menu)
  local selected = MENU_GROUP:New(entry.group, "Selected station", parent)
  local actions = {{"Show on F10", "navaid_show"}, {"Show with bearing line", "navaid_show_line"},
    {"Hide from F10", "navaid_hide"}}
  for _, item in ipairs(actions) do
    local action = item[2]
    MENU_GROUP_COMMAND:New(entry.group, item[1], selected, function()
      self:_OnPlayerTestMenuSelected(entry.group:GetName(), entry, action)
    end)
  end
  for index, item in ipairs(navaid_types) do
    if index > 1 and (index - 1) % 7 == 0 then
      parent = MENU_GROUP:New(entry.group, "More types", parent)
    end
    local kind = item[1]
    local state = {menu=MENU_GROUP:New(entry.group, item[2], parent),
      revision=0, request_id=0, page=0, pages=1, keys={}}
    entry.navaids[kind] = state
    self:_BuildNavaidMenuPage(entry, kind, state, {})
  end
end

local function validate_navaid_page(params)
  local function integer(value, low, high)
    return type(value) == "number" and value >= low and value <= high and value == math.floor(value)
  end
  if not integer(params.pages, 1, 10000) or not integer(params.page, 0, params.pages - 1) then
    error("Invalid navaid page bounds")
  end
  if type(params.items) ~= "table" or #params.items > 6 then error("Navaid pages allow at most six stations") end
  local keys, labels, count = {}, {["Refresh nearby"]=true, ["Previous page"]=true, ["Next page"]=true}, 0
  for index, item in pairs(params.items) do
    count = count + 1
    if not integer(index, 1, #params.items) or type(item) ~= "table"
      or type(item.key) ~= "string" or #item.key == 0 or #item.key > 64 or keys[item.key]
      or type(item.label) ~= "string" or #item.label == 0 or #item.label > 120
      or item.label:find("[%c]") or labels[item.label] then error("Invalid or duplicate navaid menu item") end
    keys[item.key], labels[item.label] = true, true
  end
  if count ~= #params.items then error("Navaid items must be a contiguous array") end
end

function MOOSE_BRIDGE:_ReplaceNavaidMenuPage(entry, kind, state, params)
  -- Invalidate old callbacks before replacing their commands. The type menu stays.
  state.revision = state.revision + 1
  state.page, state.pages, state.keys = params.page, params.pages, {}
  state.menu:RemoveSubMenus()
  local ok, err = pcall(function() self:_BuildNavaidMenuPage(entry, kind, state, params.items) end)
  if not ok then
    state.revision = state.revision + 1
    state.keys, state.page, state.pages = {}, 0, 1
    state.menu:RemoveSubMenus()
    -- A transient construction failure must still allow a manual refresh.
    pcall(function() self:_BuildNavaidMenuPage(entry, kind, state, {}) end)
    error(err)
  end
  return {navaid_revision=state.revision, page=state.page, pages=state.pages}
end

function MOOSE_BRIDGE:_UpdateNavaidMenuPage(params)
  local entry = self:_NavigationMenuEntry(params)
  local state = self:_NavaidMenuGuard(entry, params)
  if state.request_id < 1 or params.request_id ~= tostring(state.request_id) then
    error("Navaid page request was superseded")
  end
  local name = self:_FlightStatusReferenceUnit(entry)
  if params.unit_id ~= "UNIT:" .. name then error("Navaid reference aircraft changed") end
  validate_navaid_page(params)
  return self:_ReplaceNavaidMenuPage(entry, params.navaid_type, state, params)
end

--- Populate all untouched types in one command, from one Python position sample.
function MOOSE_BRIDGE:_InitializeNavaidMenus(params)
  local entry = self:_NavigationMenuEntry(params)
  local name = self:_FlightStatusReferenceUnit(entry)
  if params.unit_id ~= "UNIT:" .. name then error("Navaid reference aircraft changed") end
  if type(params.theater_id) ~= "string" or not env or not env.mission
    or params.theater_id ~= env.mission.theatre then error("Navaid terrain does not match the mission") end
  if type(params.types) ~= "table" then error("Missing initial navaid pages") end
  -- Validate the entire batch before changing any menu, including skipped types.
  for kind in pairs(params.types) do
    if not entry.navaids[kind] then error("Unknown navaid type") end
  end
  for _, item in ipairs(navaid_types) do
    local page = params.types[item[1]]
    if type(page) ~= "table" or page.page ~= 0 then error("Missing initial navaid page") end
    validate_navaid_page(page)
  end
  local result = {}
  for _, item in ipairs(navaid_types) do
    local kind = item[1]
    local state = entry.navaids[kind]
    result[kind] = {initialized=false}
    -- A manual request made while Python sampled the position always wins.
    if state.revision == 0 and state.request_id == 0 then
      local ok, value = pcall(function()
        return self:_ReplaceNavaidMenuPage(entry, kind, state, params.types[kind])
      end)
      if ok then
        value.initialized = true
        result[kind] = value
      else
        result[kind].error = tostring(value)
      end
    end
  end
  return {types=result}
end

-- Airfield communications use their own paged menu. Six stations plus refresh
-- and previous/next reserve the tenth DCS position for Back navigation.
local function validate_airfield_page(params)
  local function integer(value, low, high)
    return type(value) == "number" and value >= low and value <= high and value == math.floor(value)
  end
  if not integer(params.pages, 1, 10000) or not integer(params.page, 0, params.pages - 1) then
    error("Invalid airfield page bounds")
  end
  if type(params.items) ~= "table" or #params.items > 6 then
    error("Airfield pages allow at most six stations")
  end
  local keys, labels, count = {}, {['Refresh nearby']=true, ['Previous page']=true, ['Next page']=true}, 0
  for index, item in pairs(params.items) do
    count = count + 1
    if not integer(index, 1, #params.items) or type(item) ~= "table"
      or type(item.key) ~= "string" or #item.key == 0 or #item.key > 64 or keys[item.key]
      or type(item.label) ~= "string" or #item.label == 0 or #item.label > 120
      or item.label:find("[%c]") or labels[item.label] then error("Invalid or duplicate airfield menu item") end
    keys[item.key], labels[item.label] = true, true
  end
  if count ~= #params.items then error("Airfield items must be a contiguous array") end
end

function MOOSE_BRIDGE:_AirfieldMenuGuard(entry, params)
  local state = entry.airfields
  if not state or state.revision ~= params.airfield_revision then error("Airfield menu page is stale") end
  if type(params.theater_id) ~= "string" or not env or not env.mission
    or params.theater_id ~= env.mission.theatre then error("Airfield terrain does not match the mission") end
  return state
end

function MOOSE_BRIDGE:_AirfieldMenuSelected(entry, revision, action, page, station_key)
  local state = entry.airfields
  if not state or state.revision ~= revision then return end
  local ok = pcall(function() self:_NavigationMenuEntry({owner_id=entry.owner_id,
    group_id="GROUP:" .. entry.group:GetName(), session_id=entry.session_id}) end)
  if not ok then return end
  if action == "airfield_details" then
    if not state.keys[station_key] then return end
  else
    state.request_id = state.request_id + 1
  end
  local payload = self:_NavigationMenuPayload(entry.group:GetName(), entry)
  payload.action, payload.airfield_revision = action, revision
  payload.request_id, payload.page, payload.station_key = tostring(state.request_id), page, station_key
  self:SendEvent("player.menu.selected", payload)
end

function MOOSE_BRIDGE:_BuildAirfieldMenuPage(entry, state, items)
  local revision = state.revision
  MENU_GROUP_COMMAND:New(entry.group, "Refresh nearby", state.menu, function()
    self:_AirfieldMenuSelected(entry, revision, "airfields_refresh", 0)
  end)
  for _, item in ipairs(items) do
    local key = item.key
    state.keys[key] = true
    MENU_GROUP_COMMAND:New(entry.group, item.label, state.menu, function()
      self:_AirfieldMenuSelected(entry, revision, "airfield_details", state.page, key)
    end)
  end
  if state.page > 0 then
    MENU_GROUP_COMMAND:New(entry.group, "Previous page", state.menu, function()
      self:_AirfieldMenuSelected(entry, revision, "airfields_page", state.page - 1)
    end)
  end
  if state.page + 1 < state.pages then
    MENU_GROUP_COMMAND:New(entry.group, "Next page", state.menu, function()
      self:_AirfieldMenuSelected(entry, revision, "airfields_page", state.page + 1)
    end)
  end
end

function MOOSE_BRIDGE:_CreateAirfieldMenu(entry)
  entry.airfields = {menu=MENU_GROUP:New(entry.group, "Airfields / ATC", entry.menu),
    revision=0, request_id=0, page=0, pages=1, keys={}}
  self:_BuildAirfieldMenuPage(entry, entry.airfields, {})
end

function MOOSE_BRIDGE:_ReplaceAirfieldMenuPage(entry, state, params)
  state.revision = state.revision + 1
  state.page, state.pages, state.keys = params.page, params.pages, {}
  state.menu:RemoveSubMenus()
  local ok, err = pcall(function() self:_BuildAirfieldMenuPage(entry, state, params.items) end)
  if not ok then
    state.revision = state.revision + 1
    state.keys, state.page, state.pages = {}, 0, 1
    state.menu:RemoveSubMenus()
    pcall(function() self:_BuildAirfieldMenuPage(entry, state, {}) end)
    error(err)
  end
  return {airfield_revision=state.revision, page=state.page, pages=state.pages}
end

--- Build bounded, JSON-safe runway inventory and a current MOOSE wind suggestion.
-- GetRunways() contains both directions of each physical runway. Python pairs
-- those directions by their common center and dimensions for presentation.
function MOOSE_BRIDGE:_BuildNavigationRunwayData(airbase)
  local source = self:_SafeCall(airbase, "GetRunways")
  local result = {}
  local function finite(value, minimum, maximum)
    return type(value) == "number" and value == value and value >= minimum and value <= maximum
  end
  if type(source) == "table" then
    for _, runway in pairs(source) do
      local ok, item = pcall(function()
        if type(runway) ~= "table" then error("Invalid runway") end
        local name = airbase:GetRunwayName(runway)
        local center = runway.center and runway.center:GetVec2()
        if type(name) ~= "string" or name == "" or #name > 8 or type(center) ~= "table"
          or not finite(center.x, -100000000, 100000000)
          or not finite(center.y, -100000000, 100000000)
          or not finite(runway.heading, 0, 360)
          or not finite(runway.magheading, 0, 360)
          or not finite(runway.length, 1, 20000)
          or not finite(runway.width, 1, 1000) then error("Invalid runway fields") end
        return {name=name, heading_true_deg=runway.heading,
          heading_magnetic_deg=runway.magheading, length_m=runway.length,
          width_m=runway.width, center_x=center.x, center_z=center.y,
          is_left=type(runway.isLeft) == "boolean" and runway.isLeft or nil}
      end)
      if ok then
        result[#result + 1] = item
      else
        self:_Log("Ignored invalid runway at " .. tostring(self:_SafeCall(airbase, "GetName"))
          .. ": " .. tostring(item))
      end
    end
  end
  table.sort(result, function(a, b)
    if a.center_x ~= b.center_x then return a.center_x < b.center_x end
    if a.center_z ~= b.center_z then return a.center_z < b.center_z end
    return a.name < b.name
  end)

  local status, suggestion = #result > 0 and "unavailable" or "no_runways", nil
  if #result > 0 then
    local ok_wind, wind = pcall(function()
      local coordinate = airbase:GetCoordinate()
      return coordinate and coordinate:GetWindWithTurbulenceVec3() or nil
    end)
    local norm = ok_wind and type(wind) == "table" and finite(wind.x, -10000, 10000)
      and finite(wind.y, -10000, 10000) and finite(wind.z, -10000, 10000)
      and math.sqrt(wind.x * wind.x + wind.y * wind.y + wind.z * wind.z) or nil
    if norm and norm > 0.01 then
      local ok_runway, runway = pcall(function() return airbase:GetRunwayIntoWind() end)
      local ok_name, name = pcall(function() return runway and airbase:GetRunwayName(runway) or nil end)
      if ok_runway and ok_name and type(name) == "string" and name ~= "" and name ~= "XX" then
        status, suggestion = "available", name
      end
    elseif norm then
      status = "calm"
    end
  end
  return {runways=result, runway_wind_status=status, suggested_runway=suggestion}
end

--- Match imported radioId UIDs only against live MOOSE AIRBASE:GetID().
-- Callsigns and display names are deliberately not used as fallbacks.
function MOOSE_BRIDGE:_ResolveNavigationAirbases(params)
  local entry = self:_NavigationMenuEntry(params)
  local unit_name = self:_FlightStatusReferenceUnit(entry)
  if params.unit_id ~= "UNIT:" .. unit_name then error("Airfield reference aircraft changed") end
  if type(params.theater_id) ~= "string" or not env or not env.mission
    or params.theater_id ~= env.mission.theatre then error("Airfield terrain does not match the mission") end
  if type(params.airbase_ids) ~= "table" or #params.airbase_ids > 512 then error("Invalid AIRBASE ID request") end
  local requested, count = {}, 0
  for index, value in pairs(params.airbase_ids) do
    count = count + 1
    if type(index) ~= "number" or index < 1 or index > #params.airbase_ids or index ~= math.floor(index)
      or type(value) ~= "number" or value < 0 or value > 1000000 or value ~= math.floor(value)
      or requested[value] then error("Invalid or duplicate AIRBASE ID") end
    requested[value] = true
  end
  if count ~= #params.airbase_ids then error("AIRBASE IDs must be a contiguous array") end
  local result = {}
  for airbase_name, airbase in pairs(_DATABASE and _DATABASE.AIRBASES or {}) do
    local uid = self:_SafeCall(airbase, "GetID")
    if requested[uid] then
      local ok, item = pcall(function()
        local value = self:_BuildAirbaseSnapshotItem(airbase_name, airbase)
        if not value or not value.name or value.x == nil or value.z == nil
          or value.latitude == nil or value.longitude == nil then error("AIRBASE position unavailable") end
        value.airbase_id = uid -- GetID() is authoritative for this join.
        local runway_data = self:_BuildNavigationRunwayData(airbase)
        value.runways = runway_data.runways
        value.runway_wind_status = runway_data.runway_wind_status
        value.suggested_runway = runway_data.suggested_runway
        return value
      end)
      if ok then
        result[#result + 1] = item
        requested[uid] = nil
      else
        self:_Log("Failed to resolve navigation AIRBASE " .. tostring(uid) .. ": " .. tostring(item))
      end
    end
  end
  local unresolved = {}
  for uid in pairs(requested) do unresolved[#unresolved + 1] = uid end
  table.sort(unresolved)
  table.sort(result, function(a, b) return a.airbase_id < b.airbase_id end)
  return {theater_id=params.theater_id, airbases=result, unresolved_airbase_ids=unresolved}
end

function MOOSE_BRIDGE:_UpdateAirfieldMenuPage(params)
  local entry = self:_NavigationMenuEntry(params)
  local state = self:_AirfieldMenuGuard(entry, params)
  if state.request_id < 1 or params.request_id ~= tostring(state.request_id) then
    error("Airfield page request was superseded")
  end
  local name = self:_FlightStatusReferenceUnit(entry)
  if params.unit_id ~= "UNIT:" .. name then error("Airfield reference aircraft changed") end
  validate_airfield_page(params)
  return self:_ReplaceAirfieldMenuPage(entry, state, params)
end

function MOOSE_BRIDGE:_InitializeAirfieldMenu(params)
  local entry = self:_NavigationMenuEntry(params)
  local name = self:_FlightStatusReferenceUnit(entry)
  if params.unit_id ~= "UNIT:" .. name then error("Airfield reference aircraft changed") end
  if type(params.theater_id) ~= "string" or not env or not env.mission
    or params.theater_id ~= env.mission.theatre then error("Airfield terrain does not match the mission") end
  if params.page ~= 0 then error("Initial airfield page must be page zero") end
  validate_airfield_page(params)
  local state = entry.airfields
  if not state or state.revision ~= 0 or state.request_id ~= 0 then
    return {initialized=false}
  end
  local result = self:_ReplaceAirfieldMenuPage(entry, state, params)
  result.initialized = true
  return result
end

function MOOSE_BRIDGE:_NavaidSelectionGuard(entry, params)
  local selected = entry.navaid_selection
  if not selected or type(params.selection_id) ~= "string" or selected.id ~= params.selection_id
    or selected.unit_id ~= params.unit_id or selected.theater_id ~= params.theater_id
    or not env or not env.mission or selected.theater_id ~= env.mission.theatre then
    error("Navaid selection changed; select a station again")
  end
  local name, unit = self:_FlightStatusReferenceUnit(entry)
  if selected.unit_id ~= "UNIT:" .. name then error("Navaid reference aircraft changed") end
  return unit
end

--- A separate, session-owned overlay; inspecting a station never draws it.
function MOOSE_BRIDGE:_UpdateNavaidOverlay(params)
  local entry = self:_NavigationMenuEntry(params)
  if type(params.show) ~= "boolean" then error("show must be boolean") end
  if not params.show then return {removed=self:_ClearDebugOverlay(entry.navaid_overlay_id)} end
  local unit = self:_NavaidSelectionGuard(entry, params)
  local function finite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
  end
  local point = params.point
  if type(point) ~= "table" or not finite(point.latitude) or math.abs(point.latitude) > 90
    or not finite(point.longitude) or math.abs(point.longitude) > 180
    or not finite(point.altitude) then error("Invalid navaid marker coordinates") end
  if type(params.text) ~= "string" or #params.text == 0 or #params.text > 180
    or params.text:find("[%z\1-\8\11-\31\127]") then error("Invalid navaid marker text") end
  if type(params.bearing_line) ~= "boolean" then error("bearing_line must be boolean") end
  local coalition_name = self:_CoalitionToName(self:_SafeCall(entry.group, "GetCoalition"))
  if coalition_name ~= "blue" and coalition_name ~= "red" and coalition_name ~= "neutral" then
    error("Cannot determine navaid overlay coalition")
  end
  local color = {1,0.75,0,1}
  local features = {{kind="point", points={point}, radius_m=100, color=color, fill_color={1,0.75,0,0.12}}}
  if params.bearing_line then
    local position = unit:getPosition()
    local origin = position and position.p
    if not origin or not finite(origin.x) or not finite(origin.y) or not finite(origin.z) then
      error("Navaid bearing-line origin is unavailable")
    end
    features[#features + 1] = {kind="line", points={origin, point}, color=color}
  end
  -- The drawing helper rolls back failed geometry. Also remove geometry if the
  -- label fails, and register its ID in the same overlay for all cleanup paths.
  self:_DrawDebugOverlay({overlay_id=entry.navaid_overlay_id, features=features,
    coalition=coalition_name, replace=true, read_only=true})
  local ok, marker = pcall(function()
    return self:_CreateMapMarker({point=point, text=params.text, coalition=coalition_name, read_only=true})
  end)
  if not ok then self:_ClearDebugOverlay(entry.navaid_overlay_id) error(marker) end
  local ids = self.DebugOverlays[entry.navaid_overlay_id]
  ids[#ids + 1] = marker.mark_id
  return {shown=true, coalition=coalition_name, bearing_line=params.bearing_line}
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
  return unit_name, unit, wrapper
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

--- Read DCS world telemetry and optional POSITIONABLE air data on demand.
function MOOSE_BRIDGE:_GetPlayerFlightStatus(params)
  local entry = self:_NavigationMenuEntry(params)
  local name, unit, wrapper = self:_FlightStatusReferenceUnit(entry)
  local position = unit:getPosition()
  local point = type(position) == "table" and flight_status_vector(position.p)
  if not point then error("Flight status position is unavailable") end
  local velocity_ok, velocity = pcall(function() return unit:getVelocity() end)
  velocity = velocity_ok and flight_status_vector(velocity) or nil
  local function speed(method)
    local ok, value = pcall(function() return wrapper[method](wrapper) end)
    value = ok and flight_status_number(value) or nil
    return value and value >= 0 and value or nil
  end
  local coordinate_ok, coordinate = pcall(function() return wrapper:GetCoord() end)
  if not coordinate_ok or type(coordinate) ~= "table" then coordinate = nil end
  local function coordinate_number(method)
    if not coordinate then return nil end
    local ok, value = pcall(function() return coordinate[method](coordinate) end)
    return ok and flight_status_number(value) or nil
  end
  local temperature = coordinate_number("GetTemperature")
  local pressure = coordinate_number("GetPressure")
  if pressure and pressure <= 0 then pressure = nil end
  local magnetic_declination = coordinate_number("GetMagneticDeclination")
  if magnetic_declination and math.abs(magnetic_declination) > 180 then magnetic_declination = nil end
  local flightgroup = self:_PlayerEventOpsGroup(entry.group:GetName())
  local flightgroup_state
  local is_flightgroup_ok, is_flightgroup = pcall(function()
    return flightgroup and self:_SafeCall(flightgroup, "IsFlightgroup")
  end)
  if is_flightgroup_ok and is_flightgroup then
    local state_ok, state = pcall(function() return self:_SafeCall(flightgroup, "GetState") end)
    state = state_ok and state or nil
    if type(state) == "string" and #state > 0 and #state <= 120
      and not state:find("[%z\1-\31\127]") then flightgroup_state = state end
  end
  local groundspeed, tas, estimated_ias, mach
  if velocity then
    groundspeed = speed("GetGroundSpeed")
    -- GetAirspeedTrue returns 0 for unavailable wind/coordinates. Check those
    -- prerequisites so missing air data cannot masquerade as a stopped aircraft.
    local wind_ok, wind = pcall(function() return coordinate:GetWindVec3(coordinate.y, false) end)
    if wind_ok and flight_status_vector(wind) then
      tas = speed("GetAirspeedTrue")
      estimated_ias = speed("GetAirspeedIndicatedEstimated")
      mach = speed("GetMachNumber")
    end
  end
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
  local current_name, current_unit = self:_FlightStatusReferenceUnit(entry)
  if current_name ~= name or current_unit ~= unit then error("Flight status reference aircraft changed") end
  return {owner_id=entry.owner_id, session_id=entry.session_id,
    group_id="GROUP:" .. entry.group:GetName(), unit_id="UNIT:" .. name,
    sample_time_s=flight_status_number(timer.getTime()),
    altitude_msl_m=point.y,
    terrain_elevation_m=terrain_ok and flight_status_number(terrain) or nil,
    velocity_mps=velocity,
    groundspeed_mps=groundspeed, true_airspeed_mps=tas,
    estimated_ias_mps=estimated_ias, mach_number=mach,
    temperature_c=temperature, pressure_hpa=pressure,
    magnetic_declination_deg=magnetic_declination,
    flightgroup_state=flightgroup_state,
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
    self:_RemoveSpeechMenuSession(entry)
    -- Clear each owned overlay independently; one failure must not skip another.
    for _, id in ipairs({entry.overlay_id, entry.navaid_overlay_id}) do
      local cleared, clear_err = pcall(function() self:_ClearDebugOverlay(id) end)
      if not cleared then self:_Log("Navigation overlay cleanup failed: " .. tostring(clear_err)) end
    end
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
    overlay_id="navigation-menu-" .. tostring(self.PlayerMenuSerial),
    navaid_overlay_id="navigation-navaid-" .. tostring(self.PlayerMenuSerial)}
  if config.mode == "navigation" then
    entry.menu = MENU_GROUP:New(group, "Navigation")
  else
    entry.menu = MENU_GROUP:New(group, "MoosePyBridge Test")
  end
  self.PlayerTestMenus[group_name] = entry -- Also owns a partially built tree.
  if config.mode == "navigation" then
    local actions = {{"Show route", "route_show"}, {"Hide route", "route_hide"},
      {"Navigation status", "status"}, {"Flight status", "flight_status"}}
    for _, item in ipairs(actions) do
      local action = item[2] -- One binding per callback, also on Lua 5.1.
      MENU_GROUP_COMMAND:New(group, item[1], entry.menu, function()
        self:_OnPlayerTestMenuSelected(group_name, entry, action)
      end)
    end
    self:_CreateNavaidMenus(entry)
    self:_CreateAirfieldMenu(entry)
    local copilot = MENU_GROUP:New(group, "Copilot", entry.menu)
    local copilot_actions = {{"Start monitoring", "copilot_start"},
      {"Stop monitoring", "copilot_stop"}, {"Copilot status", "copilot_status"},
      {"Enable text output", "copilot_text_on"}, {"Disable text output", "copilot_text_off"},
      {"Enable radio output", "copilot_radio_on"}, {"Disable radio output", "copilot_radio_off"},
      {"Repeat last advisory", "copilot_repeat"}}
    for _, item in ipairs(copilot_actions) do
      local action = item[2]
      MENU_GROUP_COMMAND:New(group, item[1], copilot, function()
        self:_OnPlayerTestMenuSelected(group_name, entry, action)
      end)
    end
    if self.SpeechConfig and self.SpeechConfig.owner_id == entry.owner_id then
      local speech = MENU_GROUP:New(group, "Radio diagnostics", copilot)
      local speech_actions = {{"SRS test tone", "speech_tone"},
        {"Radio check", "speech_radio_check"}, {"Queue test", "speech_queue_test"}}
      for _, item in ipairs(speech_actions) do
        local action = item[2]
        MENU_GROUP_COMMAND:New(group, item[1], speech, function()
          self:_OnPlayerTestMenuSelected(group_name, entry, action)
        end)
      end
    end
    self:SendEvent("player.menu.created", self:_NavigationMenuPayload(group_name, entry))
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
      and action ~= "flight_status"
      and action ~= "copilot_start" and action ~= "copilot_stop"
      and action ~= "copilot_status" and action ~= "copilot_repeat"
      and action ~= "copilot_text_on" and action ~= "copilot_text_off"
      and action ~= "copilot_radio_on" and action ~= "copilot_radio_off"
      and action ~= "navaid_show" and action ~= "navaid_show_line" and action ~= "navaid_hide"
      and action ~= "speech_tone" and action ~= "speech_radio_check"
      and action ~= "speech_queue_test" then return end
    local payload = self:_NavigationMenuPayload(group_name, entry)
    payload.action = action
    if action == "navaid_show" or action == "navaid_show_line" then
      payload.selection_id = entry.navaid_selection and entry.navaid_selection.id or nil
    end
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
  if params.expected_instance_id ~= nil and params.expected_instance_id ~= self:_NavigationRuntimeStatus().instance_id then
    error("Navigation bridge instance changed")
  end
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
  self:_ClearSpeechQueues()
  self.SpeechConfig = nil
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
