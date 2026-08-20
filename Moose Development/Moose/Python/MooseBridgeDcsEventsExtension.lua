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
  if self.DcsEventForwardingStarted and self.UnHandleEvent then
    for _, event_id in ipairs(self.DcsRegisteredEvents or {}) do
      self:UnHandleEvent(event_id)
    end
  end
  self.DcsRegisteredEvents = {}
  self.DcsEventForwardingStarted = false
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
