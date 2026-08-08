MOOSE_BRIDGE = MOOSE_BRIDGE or {}
MOOSE_BRIDGE.ClassName = "MOOSE_BRIDGE"

local json = MOOSE_BRIDGE_JSON
if not json then error("Load MooseBridgeJson.lua before MooseBridge.lua") end

local function mission_time()
  if timer and timer.getTime then return timer.getTime() end
  return nil
end

local function dcs_time()
  if timer and timer.getAbsTime then return timer.getAbsTime() end
  return nil
end

local function mission_date()
  if not UTILS or not UTILS.GetDCSMissionDate then return nil end
  local ok, value = pcall(function() return UTILS.GetDCSMissionDate() end)
  if ok then return value end
  return nil
end

local function wall_time()
  if os and os.date then return os.date("!%Y-%m-%dT%H:%M:%SZ") end
  return nil
end

local function coalition_from_name(name)
  if name == "blue" then return coalition.side.BLUE end
  if name == "red" then return coalition.side.RED end
  if name == "neutral" then return coalition.side.NEUTRAL end
  return nil
end

local function safe_tostring(value)
  if value == nil then return "nil" end
  return tostring(value)
end

local function string_or_nil(value)
  if value == nil then return nil end
  return tostring(value)
end

local function append_unique(list, seen, value)
  if value == nil then return end
  local key = tostring(value)
  if seen[key] then return end
  list[#list + 1] = key
  seen[key] = true
end

function MOOSE_BRIDGE:New(host, port)
  local self = BASE and BASE:Inherit(self, BASE:New()) or {}
  if not BASE then setmetatable(self, { __index = MOOSE_BRIDGE }) end
  self.Host = host or "127.0.0.1"
  self.Port = port or 42000
  self.Socket = nil
  self.Scheduler = nil
  self.Connected = false
  self.Sequence = 0
  self.DebugOverlays = {}
  self.OutQueue = {}
  self.CommandHandlers = {}
  self.RegisteredZones = {}
  self.RegisteredOpsZones = {}
  self.RegisteredOpsGroups = {}
  self.RegisteredCommanders = {}
  self.ConnectRetryDelay = 5
  self.TickInterval = 0.2
  self.HeartbeatInterval = 5
  self.LastHeartbeat = 0
  self.LastConnectAttempt = -9999
  self.MissionDate = mission_date()
  self:RegisterDefaultCommands()
  return self
end

function MOOSE_BRIDGE:_Log(message)
  local line = "[MOOSE_BRIDGE] " .. safe_tostring(message)
  if env and env.info then env.info(line) else print(line) end
end

function MOOSE_BRIDGE:Start()
  self:_Log("Starting bridge to " .. self.Host .. ":" .. tostring(self.Port))
  if not SCHEDULER then error("MOOSE_BRIDGE requires MOOSE SCHEDULER") end
  self.Scheduler = SCHEDULER:New(self, self._Tick, {}, 0, self.TickInterval)
  if self._StartDcsEventForwarding then self:_StartDcsEventForwarding() end
  return self
end

function MOOSE_BRIDGE:Stop()
  if self._StopDcsEventForwarding then self:_StopDcsEventForwarding() end
  if self._ClearDebugOverlays then self:_ClearDebugOverlays() end
  if self.Scheduler then self.Scheduler:Stop(); self.Scheduler = nil end
  if self.Socket then self.Socket:close(); self.Socket = nil end
  self.Connected = false
  return self
end

function MOOSE_BRIDGE:_Connect()
  local now = mission_time() or 0
  if now - self.LastConnectAttempt < self.ConnectRetryDelay then return end
  self.LastConnectAttempt = now
  local socket_lib = require("socket")
  local sock = socket_lib.tcp()
  sock:settimeout(1)
  local ok, err = sock:connect(self.Host, self.Port)
  if not ok then self:_Log("Connect failed: " .. safe_tostring(err)); sock:close(); return end
  sock:settimeout(0)
  self.Socket = sock
  self.Connected = true
  self:_Log("Connected to Python bridge")
end

function MOOSE_BRIDGE:_Disconnect(reason)
  if reason then self:_Log("Disconnected: " .. safe_tostring(reason)) end
  if self.Socket then self.Socket:close(); self.Socket = nil end
  self.OutQueue = {}
  self.Connected = false
end

function MOOSE_BRIDGE:_NextId(prefix)
  self.Sequence = self.Sequence + 1
  return (prefix or "msg") .. "-" .. tostring(self.Sequence)
end

function MOOSE_BRIDGE:_NextMarkId()
  if not UTILS or not UTILS.GetMarkID then error("MOOSE UTILS.GetMarkID is not available") end
  return UTILS.GetMarkID()
end

function MOOSE_BRIDGE:_BaseMessage(message_type)
  return {version=1,type=message_type,id=self:_NextId(message_type),source="dcs",sequence=self.Sequence,mission_time=mission_time(),dcs_time=dcs_time(),mission_date=self.MissionDate,wall_time=wall_time()}
end

local function ammo_number(value)
  if type(value) == "number" then return value end
  return nil
end

local function ammo_weapon_id(desc)
  if type(desc) ~= "table" then return "unknown" end
  if desc.typeName then return tostring(desc.typeName) end
  if desc.displayName then return tostring(desc.displayName) end
  return table.concat({
    tostring(desc.category or ""),
    tostring(desc.missileCategory or ""),
    tostring(desc.guidance or ""),
  }, ":")
end

local function detailed_ammo_weapon(item)
  local desc = type(item) == "table" and type(item.desc) == "table" and item.desc or {}
  local warhead = type(desc.warhead) == "table" and desc.warhead or {}
  return {
    id=ammo_weapon_id(desc),
    count=ammo_number(item and item.count) or 0,
    category=ammo_number(desc.category),
    type_name=string_or_nil(desc.typeName),
    display_name=string_or_nil(desc.displayName),
    missile_category=ammo_number(desc.missileCategory),
    guidance=ammo_number(desc.guidance),
    range_min_m=ammo_number(desc.rangeMin),
    range_max_alt_min_m=ammo_number(desc.rangeMaxAltMin),
    range_max_alt_max_m=ammo_number(desc.rangeMaxAltMax),
    distance_min_m=ammo_number(desc.distMin),
    distance_max_m=ammo_number(desc.distMax),
    altitude_min_m=ammo_number(desc.altMin),
    altitude_max_m=ammo_number(desc.altMax),
    warhead_type=ammo_number(warhead.type),
    caliber=ammo_number(warhead.caliber),
    warhead_mass=ammo_number(warhead.mass),
    explosive_mass=ammo_number(warhead.explosiveMass),
    shaped_explosive_mass=ammo_number(warhead.shapedExplosiveMass),
    shaped_explosive_armor_thickness=ammo_number(warhead.shapedExplosiveArmorThickness),
  }
end

local function ammo_safe_call(object, method_name)
  if not object then return nil end
  local ok_method, method = pcall(function() return object[method_name] end)
  if not ok_method or type(method) ~= "function" then return nil end
  local ok, value = pcall(function() return method(object) end)
  if ok then return value end
  return nil
end

local function detailed_unit_ammunition(unit)
  local dcs_unit = ammo_safe_call(unit, "GetDCSObject")
  if not dcs_unit then return nil end
  local ok_ammo, ammo = pcall(function() return dcs_unit:getAmmo() end)
  if not ok_ammo then error(ammo) end
  local ok_desc, unit_desc = pcall(function() return dcs_unit:getDesc() end)
  if not ok_desc or type(unit_desc) ~= "table" then unit_desc = {} end

  local attributes = {}
  if type(unit_desc.attributes) == "table" then
    for name, enabled in pairs(unit_desc.attributes) do
      if enabled then attributes[#attributes + 1] = tostring(name) end
    end
    table.sort(attributes)
  end

  local by_id = {}
  if type(ammo) == "table" then
    for _, item in pairs(ammo) do
      local weapon = detailed_ammo_weapon(item)
      local existing = by_id[weapon.id]
      if existing then
        existing.count = existing.count + weapon.count
      else
        by_id[weapon.id] = weapon
      end
    end
  end

  local weapons = {}
  for _, weapon in pairs(by_id) do weapons[#weapons + 1] = weapon end
  table.sort(weapons, function(a, b) return a.id < b.id end)
  return {
    unit_name=ammo_safe_call(unit, "GetName"),
    type_name=ammo_safe_call(unit, "GetTypeName") or string_or_nil(unit_desc.typeName),
    attributes=attributes,
    life=ammo_safe_call(unit, "GetLife") or ammo_safe_call(dcs_unit, "getLife"),
    life0=ammo_safe_call(unit, "GetLife0") or ammo_safe_call(dcs_unit, "getLife0"),
    weapons=weapons,
  }
end

if UNIT and not UNIT.GetAmmoDetailed then
  --- Get compact, descriptor-preserving ammunition data for this unit.
  -- @param #UNIT self
  -- @return #table Detailed ammunition data, or nil if the DCS unit is unavailable.
  function UNIT:GetAmmoDetailed()
    return detailed_unit_ammunition(self)
  end
end

if GROUP and not GROUP.GetAmmoDetailed then
  --- Get detailed ammunition data for every available unit in this group.
  -- @param #GROUP self
  -- @return #table Group ammunition data.
  function GROUP:GetAmmoDetailed()
    local result = {group_name=self:GetName(), units={}}
    local units = self:GetUnits()
    if type(units) ~= "table" then return result end
    for _, unit in pairs(units) do
      local data = unit and unit.GetAmmoDetailed and unit:GetAmmoDetailed() or nil
      if data then result.units[#result.units + 1] = data end
    end
    table.sort(result.units, function(a, b) return tostring(a.unit_name) < tostring(b.unit_name) end)
    return result
  end
end

function MOOSE_BRIDGE:Send(message)
  if not self.Socket then
    return self
  end
  self.OutQueue[#self.OutQueue + 1] = json.encode(message)
  return self
end

function MOOSE_BRIDGE:SendHeartbeat()
  local msg = self:_BaseMessage("heartbeat")
  msg.status = "running"
  self:Send(msg)
end

function MOOSE_BRIDGE:SendSnapshot(kind, payload)
  local msg = self:_BaseMessage("snapshot")
  msg.kind = kind
  msg.payload = payload or {}
  self:Send(msg)
end

function MOOSE_BRIDGE:SendEvent(event_name, payload)
  local msg = self:_BaseMessage("event")
  msg.event = event_name
  msg.payload = payload or {}
  if type(msg.payload) == "table" then msg.payload.event = event_name end
  self:Send(msg)
end

function MOOSE_BRIDGE:SendAck(command, ok, result, error_message)
  local msg = self:_BaseMessage("ack")
  msg.correlation_id = command and command.id or nil
  msg.ok = ok and true or false
  msg.result = result
  msg.error = error_message
  self:Send(msg)
end

function MOOSE_BRIDGE:RegisterCommand(action, handler)
  self.CommandHandlers[action] = handler
  return self
end

function MOOSE_BRIDGE:RegisterZone(zone, name)
  if not zone then return self end
  local zone_name = name or self:_SafeCall(zone, "GetName") or zone.ZoneName or zone.name
  if zone_name then self.RegisteredZones[safe_tostring(zone_name)] = zone end
  return self
end

function MOOSE_BRIDGE:RegisterZones(zones)
  if type(zones) ~= "table" then return self end
  for name, zone in pairs(zones) do self:RegisterZone(zone, name) end
  return self
end

function MOOSE_BRIDGE:RegisterOpsZone(opszone, name)
  if not opszone then return self end
  local zone_name = name or self:_SafeCall(opszone, "GetName") or opszone.Name or opszone.name
  if zone_name then
    zone_name = safe_tostring(zone_name)
    self.RegisteredOpsZones[zone_name] = opszone
    if self._AttachOpsZoneEventForwarder then self:_AttachOpsZoneEventForwarder(opszone, zone_name) end
  end
  return self
end

function MOOSE_BRIDGE:RegisterOpsZones(opszones)
  if type(opszones) ~= "table" then return self end
  for name, opszone in pairs(opszones) do self:RegisterOpsZone(opszone, name) end
  return self
end

function MOOSE_BRIDGE:RegisterOpsGroup(opsgroup, name)
  if not opsgroup then return self end
  local group_name = name or self:_SafeCall(opsgroup, "GetName") or opsgroup.Name or opsgroup.name
  if group_name then self.RegisteredOpsGroups[safe_tostring(group_name)] = opsgroup end
  return self
end

function MOOSE_BRIDGE:RegisterOpsGroups(opsgroups)
  if type(opsgroups) ~= "table" then return self end
  for name, opsgroup in pairs(opsgroups) do self:RegisterOpsGroup(opsgroup, name) end
  return self
end

function MOOSE_BRIDGE:RegisterCommander(commander, name)
  if not commander then return self end
  local commander_name = name or commander.alias or self:_SafeCall(commander, "GetName")
  if commander_name then self.RegisteredCommanders[safe_tostring(commander_name)] = commander end
  return self
end

function MOOSE_BRIDGE:RegisterCommanders(commanders)
  if type(commanders) ~= "table" then return self end
  for name, commander in pairs(commanders) do self:RegisterCommander(commander, name) end
  return self
end

function MOOSE_BRIDGE:_SafeCall(object, method_name)
  if not object or not method_name then return nil end
  local ok_method, method = pcall(function() return object[method_name] end)
  if not ok_method or not method then return nil end
  local ok, value = pcall(function() return method(object) end)
  if ok then return value end
  return nil
end

function MOOSE_BRIDGE:_SafeCallArg(object, method_name, ...)
  if not object or not method_name then return nil end
  local ok_method, method = pcall(function() return object[method_name] end)
  if not ok_method or not method then return nil end
  local args = {...}
  local ok, value = pcall(function() return method(object, unpack(args)) end)
  if ok then return value end
  return nil
end

function MOOSE_BRIDGE:_DcsCall(object, method_name)
  if not object or not method_name then return nil end
  local ok, value = pcall(function() return object[method_name](object) end)
  if ok then return value end
  return nil
end

function MOOSE_BRIDGE:_ObjectName(object)
  if not object then return nil end
  local name = self:_SafeCall(object, "GetName")
  if name then return safe_tostring(name) end
  if object.alias then return safe_tostring(object.alias) end
  if object.name then return safe_tostring(object.name) end
  if object.Name then return safe_tostring(object.Name) end
  if object.groupname then return safe_tostring(object.groupname) end
  return nil
end

function MOOSE_BRIDGE:_CoalitionToName(value)
  if value == nil then return nil end
  if coalition and coalition.side then
    if value == coalition.side.BLUE then return "blue" end
    if value == coalition.side.RED then return "red" end
    if value == coalition.side.NEUTRAL then return "neutral" end
  end
  if value == 2 then return "blue" end
  if value == 1 then return "red" end
  if value == 0 then return "neutral" end
  return tostring(value)
end

function MOOSE_BRIDGE:_AirbaseCategoryToName(value)
  if value == nil then return nil end
  if Airbase and Airbase.Category then
    if value == Airbase.Category.AIRDROME then return "Airdrome" end
    if value == Airbase.Category.HELIPAD then return "Heliport" end
    if value == Airbase.Category.SHIP then return "Ship" end
  end
  if value == 0 then return "Airdrome" end
  if value == 1 then return "Heliport" end
  if value == 2 then return "Ship" end
  return "Unknown " .. tostring(value)
end

function MOOSE_BRIDGE:_BoolOrFalse(value)
  if value == nil then return false end
  return value and true or false
end

function MOOSE_BRIDGE:_NumberOrZero(value)
  if type(value) == "number" then return value end
  return 0
end

function MOOSE_BRIDGE:_NumberOrNil(value)
  if type(value) == "number" then return value end
  if type(value) == "string" then return tonumber(value) end
  return nil
end

function MOOSE_BRIDGE:_IsDcsObjectAlive(object)
  if not object then return false end
  local ok_exist, exists = pcall(function() return object:isExist() end)
  if ok_exist and not exists then return false end
  local ok_life, life = pcall(function() return object:getLife() end)
  if ok_life and type(life) == "number" then return life > 0 end
  return true
end

function MOOSE_BRIDGE:_DcsTypeName(object)
  return self:_DcsCall(object, "getTypeName")
end

function MOOSE_BRIDGE:_DcsPoint(object)
  return self:_DcsCall(object, "getPoint")
end

function MOOSE_BRIDGE:_PointFromMooseObject(object)
  if not object then return nil end
  local coordinate = self:_SafeCall(object, "GetCoordinate")
  if coordinate then
    local vec3 = self:_SafeCall(coordinate, "GetVec3")
    if vec3 then return vec3 end
  end
  local vec3 = self:_SafeCall(object, "GetVec3") or self:_SafeCall(object, "GetPointVec3")
  if vec3 then return vec3 end
  if object.Coordinate then
    vec3 = self:_SafeCall(object.Coordinate, "GetVec3")
    if vec3 then return vec3 end
  end
  if object.position then return object.position end
  return nil
end

function MOOSE_BRIDGE:_PointFromParams(params)
  local x = self:_NumberOrNil(params and params.x)
  local y = self:_NumberOrNil(params and params.y) or 0
  local z = self:_NumberOrNil(params and params.z)
  if x == nil or z == nil then error("Point commands require numeric x and z parameters") end
  return {x=x, y=y, z=z}
end

function MOOSE_BRIDGE:_SplitObjectId(object_id)
  if type(object_id) ~= "string" then return nil, nil end
  local separator = string.find(object_id, ":")
  if not separator then return nil, nil end
  return string.sub(object_id, 1, separator - 1), string.sub(object_id, separator + 1)
end

function MOOSE_BRIDGE:_PointForGroupName(name)
  local group = _DATABASE and _DATABASE.GROUPS and _DATABASE.GROUPS[name]
  if not group then return nil end
  local point = self:_PointFromMooseObject(group)
  if point then return point end
  local dcs_group = self:_SafeCall(group, "GetDCSObject")
  local ok, units = pcall(function() return dcs_group and dcs_group:getUnits() end)
  if ok and type(units) == "table" and units[1] then return self:_DcsPoint(units[1]) end
  return nil
end

function MOOSE_BRIDGE:_PointForUnitName(name)
  local unit = _DATABASE and _DATABASE.UNITS and _DATABASE.UNITS[name]
  if not unit then return nil end
  local dcs_unit = self:_SafeCall(unit, "GetDCSObject")
  return self:_DcsPoint(dcs_unit) or self:_PointFromMooseObject(unit)
end

function MOOSE_BRIDGE:_PointForStaticName(name)
  local static = _DATABASE and _DATABASE.STATICS and _DATABASE.STATICS[name]
  if not static then return nil end
  local dcs_static = self:_SafeCall(static, "GetDCSObject")
  return self:_DcsPoint(dcs_static) or self:_PointFromMooseObject(static)
end

function MOOSE_BRIDGE:_PointForAirbaseName(name)
  local airbase = _DATABASE and _DATABASE.AIRBASES and _DATABASE.AIRBASES[name]
  return self:_PointFromMooseObject(airbase)
end

function MOOSE_BRIDGE:_PointForOpsZoneName(name)
  local opszone = self.RegisteredOpsZones and self.RegisteredOpsZones[name]
  if not opszone and _DATABASE and type(_DATABASE.OPSZONES) == "table" then opszone = _DATABASE.OPSZONES[name] end
  if not opszone then return nil end
  return self:_PointFromMooseObject(opszone)
end

function MOOSE_BRIDGE:_TerritoryForName(name)
  if not _DATABASE then return nil end
  local territory = self:_SafeCallArg(_DATABASE, "FindTerritory", name)
  if not territory and type(_DATABASE.TERRITORIES) == "table" then territory = _DATABASE.TERRITORIES[name] end
  return territory
end

function MOOSE_BRIDGE:_PointForTerritoryName(name)
  local territory = self:_TerritoryForName(name)
  if not territory then return nil end
  return self:_PointFromMooseObject(territory)
end

function MOOSE_BRIDGE:_PointForZoneName(name)
  local zone = self.RegisteredZones and self.RegisteredZones[name]
  if not zone and _DATABASE and _DATABASE.ZONES then zone = _DATABASE.ZONES[name] end
  if zone then
    local point = self:_PointFromMooseObject(zone)
    if point then return point end
  end
  local opszone_point = self:_PointForOpsZoneName(name)
  if opszone_point then return opszone_point end
  if env and env.mission and env.mission.triggers and type(env.mission.triggers.zones) == "table" then
    for _, trigger_zone in pairs(env.mission.triggers.zones) do
      if trigger_zone.name == name then return {x=trigger_zone.x, y=0, z=trigger_zone.y} end
    end
  end
  return nil
end

function MOOSE_BRIDGE:_PointForObjectId(object_id)
  local object_type, name = self:_SplitObjectId(object_id)
  if not object_type or not name then error("Invalid object_id: " .. safe_tostring(object_id)) end
  if object_type == "GROUP" then return self:_PointForGroupName(name) end
  if object_type == "UNIT" then return self:_PointForUnitName(name) end
  if object_type == "STATIC" then return self:_PointForStaticName(name) end
  if object_type == "AIRBASE" then return self:_PointForAirbaseName(name) end
  if object_type == "ZONE" then return self:_PointForZoneName(name) end
  if object_type == "OPSZONE" then return self:_PointForOpsZoneName(name) end
  if object_type == "TERRITORY" then return self:_PointForTerritoryName(name) end
  error("Unsupported object_id type for point lookup: " .. safe_tostring(object_type))
end

function MOOSE_BRIDGE:_DrawZoneCoalition(value)
  if value == nil or value == "" then return -1 end
  if type(value) == "number" then return value end
  local normalized = string.lower(tostring(value))
  if normalized == "all" then return -1 end
  if normalized == "neutral" then return 0 end
  if normalized == "red" then return 1 end
  if normalized == "blue" then return 2 end
  local numeric = tonumber(value)
  if numeric ~= nil then return numeric end
  error("Unknown draw zone coalition: " .. safe_tostring(value))
end

function MOOSE_BRIDGE:_DrawZoneColor(value)
  if value == nil or value == "" then return nil end
  local normalized = string.lower(tostring(value))
  local colors = {
    red={1,0,0},
    green={0,1,0},
    blue={0,0,1},
    yellow={1,1,0},
    orange={1,0.5,0},
    white={1,1,1},
    black={0,0,0},
    grey={0.5,0.5,0.5},
    gray={0.5,0.5,0.5},
  }
  local color = colors[normalized]
  if color then return color end
  error("Unsupported draw zone color: " .. safe_tostring(value))
end

function MOOSE_BRIDGE:_DrawZoneLineType(value)
  if value == nil or value == "" then return nil end
  if type(value) == "number" then return value end
  local normalized = string.lower(tostring(value)):gsub("[%s_-]", "")
  local line_types = {none=0, solid=1, dashed=2, dotted=3, dotdash=4, longdash=5, twodash=6}
  if line_types[normalized] ~= nil then return line_types[normalized] end
  local numeric = tonumber(value)
  if numeric ~= nil then return numeric end
  error("Unsupported draw zone line_type: " .. safe_tostring(value))
end

function MOOSE_BRIDGE:_OptionalString(value)
  if value == nil or value == "" then return nil end
  return tostring(value)
end

function MOOSE_BRIDGE:_NormalizeCoordinateFormat(value)
  if value == nil or value == "" then return "xyz" end
  local normalized = string.lower(tostring(value))
  if normalized == "xyz" then return "xyz" end
  if normalized == "ll" or normalized == "latlon" or normalized == "latlong" or normalized == "latitude" then return "ll" end
  if normalized == "mgrs" then return "mgrs" end
  if normalized == "all" then return "all" end
  error("Unsupported coordinate format: " .. safe_tostring(value))
end

function MOOSE_BRIDGE:_MGRSToString(mgrs)
  if type(mgrs) ~= "table" then return nil end
  local zone = mgrs.UTMZone or mgrs.utmZone or mgrs.zone
  local digraph = mgrs.MGRSDigraph or mgrs.mgrsDigraph or mgrs.digraph
  local easting = mgrs.Easting or mgrs.easting
  local northing = mgrs.Northing or mgrs.northing
  if not zone or not digraph or easting == nil or northing == nil then return nil end
  return string.format("%s %s %05d %05d", tostring(zone), tostring(digraph), math.floor(easting + 0.5), math.floor(northing + 0.5))
end

function MOOSE_BRIDGE:_CoordinatesForPoint(point, format)
  if not point then error("Point is nil") end
  local normalized = self:_NormalizeCoordinateFormat(format)
  local result = {format=normalized, x=point.x, y=point.y or 0, z=point.z}

  if normalized == "ll" or normalized == "mgrs" or normalized == "all" then
    if not coord or not coord.LOtoLL then error("DCS coord.LOtoLL is not available") end
    local latitude, longitude = coord.LOtoLL({x=point.x, y=point.y or 0, z=point.z})
    result.latitude = latitude
    result.longitude = longitude
    result.altitude = point.y or 0
  end

  if normalized == "mgrs" or normalized == "all" then
    if not coord or not coord.LLtoMGRS then error("DCS coord.LLtoMGRS is not available") end
    local mgrs = coord.LLtoMGRS(result.latitude, result.longitude)
    result.mgrs = self:_MGRSToString(mgrs)
    result.mgrs_zone = mgrs and (mgrs.UTMZone or mgrs.utmZone or mgrs.zone) or nil
    result.mgrs_digraph = mgrs and (mgrs.MGRSDigraph or mgrs.mgrsDigraph or mgrs.digraph) or nil
    result.mgrs_easting = mgrs and (mgrs.Easting or mgrs.easting) or nil
    result.mgrs_northing = mgrs and (mgrs.Northing or mgrs.northing) or nil
  end

  return result
end

function MOOSE_BRIDGE:_AddPointFields(item, point)
  if type(item) ~= "table" or type(point) ~= "table" then return item end
  local coordinates = self:_CoordinatesForPoint(point, "ll")
  item.x = coordinates.x
  item.y = coordinates.y
  item.z = coordinates.z
  item.latitude = coordinates.latitude
  item.longitude = coordinates.longitude
  return item
end

function MOOSE_BRIDGE:_DistanceBetweenPoints(point_a, point_b)
  if not point_a or not point_b then error("Distance requires two points") end
  local dx = (point_b.x or 0) - (point_a.x or 0)
  local dy = (point_b.y or 0) - (point_a.y or 0)
  local dz = (point_b.z or 0) - (point_a.z or 0)
  return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function MOOSE_BRIDGE:_ZoneForDrawObjectId(object_id)
  local object_type, name = self:_SplitObjectId(object_id)
  if not object_type or not name then error("Invalid zone object_id: " .. safe_tostring(object_id)) end

  local zone = nil
  if object_type == "ZONE" then
    zone = self.RegisteredZones and self.RegisteredZones[name]
    if not zone and _DATABASE and _DATABASE.ZONES then zone = _DATABASE.ZONES[name] end
    if not zone and ZONE and ZONE.FindByName then zone = ZONE:FindByName(name) end
    if not zone and ZONE and ZONE.New then
      local ok, created = pcall(function() return ZONE:New(name) end)
      if ok then zone = created end
    end
  elseif object_type == "OPSZONE" then
    local opszone = self.RegisteredOpsZones and self.RegisteredOpsZones[name]
    if not opszone and _DATABASE and type(_DATABASE.OPSZONES) == "table" then opszone = _DATABASE.OPSZONES[name] end
    zone = self:_SafeCall(opszone, "GetZone") or opszone and (opszone.zone or opszone.Zone or opszone.ZONE) or opszone
  elseif object_type == "TERRITORY" then
    local territory = self:_TerritoryForName(name)
    zone = self:_SafeCall(territory, "GetZone") or territory and territory.zone
  else
    error("DrawZone requires ZONE:<name>, OPSZONE:<name>, or TERRITORY:<name>, got " .. safe_tostring(object_type))
  end

  if not zone then error("Zone not found: " .. safe_tostring(object_id)) end
  if not zone.DrawZone then error("Zone does not support DrawZone: " .. safe_tostring(object_id)) end
  return zone, name, object_type
end

function MOOSE_BRIDGE:_CoordinateFromPoint(point)
  if not COORDINATE or not COORDINATE.NewFromVec3 then error("MOOSE COORDINATE is not available") end
  if not point then error("Point is nil") end
  return COORDINATE:NewFromVec3({x=point.x, y=point.y or 0, z=point.z})
end

function MOOSE_BRIDGE:_SmokePoint(point, color)
  local coordinate = self:_CoordinateFromPoint(point)
  local smoke_color = string.lower(color or "white")
  local method_by_color = {red="SmokeRed", green="SmokeGreen", blue="SmokeBlue", orange="SmokeOrange", white="SmokeWhite"}
  local method_name = method_by_color[smoke_color]
  if not method_name then error("Unsupported smoke color: " .. safe_tostring(color)) end
  local method = coordinate[method_name]
  if not method then error("COORDINATE method unavailable: " .. method_name) end
  method(coordinate)
  return {x=point.x, y=point.y or 0, z=point.z, color=smoke_color}
end

function MOOSE_BRIDGE:_ExplosionPoint(point, power, delay)
  local explosion_power = self:_NumberOrNil(power)
  local explosion_delay = self:_NumberOrNil(delay) or 0
  if explosion_power == nil or explosion_power <= 0 then error("Explosion power must be a positive number in kg TNT") end
  if explosion_delay < 0 then error("Explosion delay must be zero or greater") end

  local coordinate = self:_CoordinateFromPoint(point)
  if not coordinate.Explosion then error("COORDINATE:Explosion is not available") end
  coordinate:Explosion(explosion_power, explosion_delay)
  return {
    x=point.x,
    y=point.y or 0,
    z=point.z,
    power_kg_tnt=explosion_power,
    delay_seconds=explosion_delay,
  }
end

function MOOSE_BRIDGE:_MarkPoint(point, text)
  local coordinate = self:_CoordinateFromPoint(point)
  local mark_text = text or "MOOSE Bridge mark"
  if coordinate.MarkToAll then
    coordinate:MarkToAll(mark_text)
  elseif trigger and trigger.action and trigger.action.markToAll then
    trigger.action.markToAll(self:_NextMarkId(), mark_text, {x=point.x, y=point.y or 0, z=point.z}, true)
  else
    error("No mark implementation available")
  end
  return {x=point.x, y=point.y or 0, z=point.z, text=mark_text}
end

function MOOSE_BRIDGE:_CountTable(value)
  if type(value) ~= "table" then return 0 end
  local count = 0
  for _, _ in pairs(value) do count = count + 1 end
  return count
end

function MOOSE_BRIDGE:_CountSet(set_object)
  if not set_object then return 0 end
  local count = self:_SafeCall(set_object, "Count") or self:_SafeCall(set_object, "CountAlive")
  if type(count) == "number" then return count end
  if type(set_object.Set) == "table" then return self:_CountTable(set_object.Set) end
  return 0
end

function MOOSE_BRIDGE:_CountUnitsInTable(units, alive_only)
  if type(units) ~= "table" then return nil end
  local count = 0
  for _, unit in pairs(units) do
    if alive_only then
      if self:_IsMooseUnitAlive(unit) then count = count + 1 end
    else
      count = count + 1
    end
  end
  return count
end

function MOOSE_BRIDGE:_IsMooseUnitAlive(unit)
  if not unit then return false end
  local alive = self:_SafeCall(unit, "IsAlive")
  if alive ~= nil then return alive and true or false end
  local dcs_unit = self:_SafeCall(unit, "GetDCSObject")
  if dcs_unit then return self:_IsDcsObjectAlive(dcs_unit) end
  return false
end

function MOOSE_BRIDGE:_CountDcsGroupUnits(group, alive_only)
  local dcs_group = self:_SafeCall(group, "GetDCSObject")
  if not dcs_group then return nil end
  local ok, units = pcall(function() return dcs_group:getUnits() end)
  if not ok or type(units) ~= "table" then return nil end
  local count = 0
  for _, unit in pairs(units) do
    if alive_only then
      if self:_IsDcsObjectAlive(unit) then count = count + 1 end
    else
      count = count + 1
    end
  end
  return count
end

function MOOSE_BRIDGE:_CountGroupUnits(group, alive_only)
  local units = self:_SafeCall(group, "GetUnits")
  local count = self:_CountUnitsInTable(units, alive_only)
  if count ~= nil then return count end
  count = self:_CountDcsGroupUnits(group, alive_only)
  if count ~= nil then return count end
  if alive_only then count = self:_SafeCall(group, "CountAliveUnits") else count = self:_SafeCall(group, "CountUnits") end
  return self:_NumberOrZero(count)
end

function MOOSE_BRIDGE:_BuildGroupSnapshotItem(group_name, group)
  local name = self:_SafeCall(group, "GetName") or group_name
  local coalition_value = self:_SafeCall(group, "GetCoalition")
  local category = self:_SafeCall(group, "GetCategoryName") or self:_SafeCall(group, "GetCategory")
  local alive = self:_SafeCall(group, "IsAlive")
  local active = self:_SafeCall(group, "IsActive")
  local unit_count = self:_CountGroupUnits(group, false)
  local alive_unit_count = self:_CountGroupUnits(group, true)
  local point = self:_PointForGroupName(name)
  local item = {object_id="GROUP:"..safe_tostring(name),dcs_name=safe_tostring(name),object_type="GROUP",category=category and safe_tostring(category) or nil,coalition=self:_CoalitionToName(coalition_value),alive=self:_BoolOrFalse(alive),active=self:_BoolOrFalse(active),unit_count=self:_NumberOrZero(unit_count),alive_unit_count=self:_NumberOrZero(alive_unit_count)}
  if point then self:_AddPointFields(item, point) end
  return item
end

function MOOSE_BRIDGE:_DebugMarkupCoalition(value)
  return self:_DrawZoneCoalition(value)
end

function MOOSE_BRIDGE:_DebugMarkupColor(value, default)
  local color = value or default
  if type(color) ~= "table" or (#color ~= 3 and #color ~= 4) then
    error("Markup color must contain RGB or RGBA values")
  end
  local result = {}
  for index = 1, 4 do
    local component = color[index]
    if component == nil and index == 4 then component = 1 end
    component = tonumber(component)
    if component == nil or component < 0 or component > 1 then
      error("Markup color components must be in range 0..1")
    end
    result[index] = component
  end
  return result
end

function MOOSE_BRIDGE:_DebugMarkupPoint(value)
  if type(value) ~= "table" then error("Markup point must be a table") end
  if type(value.latitude) == "number" and type(value.longitude) == "number" then
    if not coord or not coord.LLtoLO then error("DCS coord.LLtoLO is not available") end
    local point = coord.LLtoLO(value.latitude, value.longitude, tonumber(value.altitude) or 0)
    if not point then error("DCS could not convert markup latitude/longitude") end
    return {x=point.x, y=point.y or 0, z=point.z}
  end
  if type(value.x) == "number" and type(value.z) == "number" then
    return {x=value.x, y=tonumber(value.y) or 0, z=value.z}
  end
  error("Markup point requires latitude/longitude or x/z")
end

function MOOSE_BRIDGE:_RemoveDebugMarkIds(ids)
  if type(ids) ~= "table" or not trigger or not trigger.action or not trigger.action.removeMark then return 0 end
  local removed = 0
  for _, mark_id in ipairs(ids) do
    local ok = pcall(function() trigger.action.removeMark(mark_id) end)
    if ok then removed = removed + 1 end
  end
  return removed
end

function MOOSE_BRIDGE:_ClearDebugOverlay(overlay_id)
  local key = tostring(overlay_id or "")
  local ids = self.DebugOverlays and self.DebugOverlays[key]
  local removed = self:_RemoveDebugMarkIds(ids)
  if self.DebugOverlays then self.DebugOverlays[key] = nil end
  return removed
end

function MOOSE_BRIDGE:_ClearDebugOverlays()
  local removed = 0
  for overlay_id, _ in pairs(self.DebugOverlays or {}) do
    removed = removed + self:_ClearDebugOverlay(overlay_id)
  end
  return removed
end

function MOOSE_BRIDGE:_DrawDebugOverlay(params)
  if not trigger or not trigger.action or not trigger.action.lineToAll or not trigger.action.circleToAll then
    error("DCS trigger.action.lineToAll/circleToAll is not available")
  end
  local overlay_id = self:_OptionalString(params.overlay_id)
  if not overlay_id or overlay_id == "" then error("map.overlay.draw requires overlay_id") end
  if #overlay_id > 96 then error("overlay_id accepts at most 96 characters") end
  local features = params.features
  if type(features) ~= "table" or #features == 0 then error("map.overlay.draw requires features") end
  if #features > 200 then error("map.overlay.draw accepts at most 200 features") end

  local coalition_id = self:_DebugMarkupCoalition(params.coalition or "all")
  local line_type = self:_DrawZoneLineType(params.line_type) or 1
  local read_only = params.read_only ~= false
  local normalized = {}
  local point_count = 0
  local mark_count = 0
  local bounds = nil
  for index, feature in ipairs(features) do
    if type(feature) ~= "table" then error("Invalid markup feature at index " .. safe_tostring(index)) end
    local kind = string.lower(tostring(feature.kind or ""))
    if kind ~= "point" and kind ~= "line" and kind ~= "polygon" then
      error("Unsupported markup kind at index " .. safe_tostring(index) .. ": " .. safe_tostring(kind))
    end
    local points = feature.points
    if type(points) ~= "table" then error("Markup feature points must be a table at index " .. safe_tostring(index)) end
    local minimum = kind == "point" and 1 or kind == "line" and 2 or 3
    if #points < minimum then error("Markup feature has too few points at index " .. safe_tostring(index)) end
    local converted = {}
    for _, point in ipairs(points) do
      local converted_point = self:_DebugMarkupPoint(point)
      converted[#converted + 1] = converted_point
      if not bounds then
        bounds = {min_x=converted_point.x, max_x=converted_point.x, min_z=converted_point.z, max_z=converted_point.z}
      else
        bounds.min_x = math.min(bounds.min_x, converted_point.x)
        bounds.max_x = math.max(bounds.max_x, converted_point.x)
        bounds.min_z = math.min(bounds.min_z, converted_point.z)
        bounds.max_z = math.max(bounds.max_z, converted_point.z)
      end
    end
    point_count = point_count + #converted
    local feature_marks = kind == "point" and 1 or (#converted - 1)
    if kind == "polygon" then
      local first, last = converted[1], converted[#converted]
      if first.x ~= last.x or first.z ~= last.z then feature_marks = feature_marks + 1 end
    end
    mark_count = mark_count + feature_marks
    normalized[#normalized + 1] = {
      kind=kind,
      points=converted,
      radius=tonumber(feature.radius_m) or 100,
      color=self:_DebugMarkupColor(feature.color, {0,1,0,1}),
      fill_color=self:_DebugMarkupColor(feature.fill_color, {0,1,0,0.12}),
      line_type=self:_DrawZoneLineType(feature.line_type) or line_type,
    }
  end
  if point_count > 2000 then error("map.overlay.draw accepts at most 2000 points") end
  if mark_count > 500 then error("map.overlay.draw would create more than 500 DCS markups") end

  if params.replace ~= false then self:_ClearDebugOverlay(overlay_id) end
  if self.DebugOverlays[overlay_id] then error("Debug overlay already exists: " .. overlay_id) end
  local ids = {}
  local function draw(method, ...)
    local mark_id = self:_NextMarkId()
    local arguments = {coalition_id, mark_id}
    local values = {...}
    for _, value in ipairs(values) do arguments[#arguments + 1] = value end
    local ok, err = pcall(function() method(unpack(arguments)) end)
    if not ok then error(err) end
    ids[#ids + 1] = mark_id
  end
  local ok, draw_error = pcall(function()
    for _, feature in ipairs(normalized) do
      if feature.kind == "point" then
        draw(trigger.action.circleToAll, feature.points[1], feature.radius, feature.color, feature.fill_color, feature.line_type, read_only, "")
      else
        for point_index = 1, #feature.points - 1 do
          draw(trigger.action.lineToAll, feature.points[point_index], feature.points[point_index + 1], feature.color, feature.line_type, read_only, "")
        end
        if feature.kind == "polygon" then
          local first, last = feature.points[1], feature.points[#feature.points]
          if first.x ~= last.x or first.z ~= last.z then
            draw(trigger.action.lineToAll, last, first, feature.color, feature.line_type, read_only, "")
          end
        end
      end
    end
  end)
  if not ok then
    self:_RemoveDebugMarkIds(ids)
    error(draw_error)
  end
  self.DebugOverlays[overlay_id] = ids
  return {action="map.overlay.draw", overlay_id=overlay_id, feature_count=#normalized, point_count=point_count, mark_count=#ids, coalition=coalition_id, dcs_bounds=bounds}
end

function MOOSE_BRIDGE:BuildGroupSnapshot()
  local result = {}
  if not _DATABASE or not _DATABASE.GROUPS then return result end
  for group_name, group in pairs(_DATABASE.GROUPS) do
    local ok, item = pcall(function() return self:_BuildGroupSnapshotItem(group_name, group) end)
    if ok and item then result[#result + 1] = item else self:_Log("Failed to snapshot group " .. safe_tostring(group_name) .. ": " .. safe_tostring(item)) end
  end
  return result
end

function MOOSE_BRIDGE:_BuildUnitSnapshotItem(unit_name, unit)
  local name = self:_SafeCall(unit, "GetName") or unit_name
  local group_name = self:_SafeCall(unit, "GetGroupName")
  local group = self:_SafeCall(unit, "GetGroup")
  if not group_name and group then group_name = self:_SafeCall(group, "GetName") end
  local coalition_value = self:_SafeCall(unit, "GetCoalition")
  if coalition_value == nil and group then coalition_value = self:_SafeCall(group, "GetCoalition") end
  local category = self:_SafeCall(unit, "GetCategoryName") or self:_SafeCall(unit, "GetCategory")
  if not category and group then category = self:_SafeCall(group, "GetCategoryName") or self:_SafeCall(group, "GetCategory") end
  local dcs_unit = self:_SafeCall(unit, "GetDCSObject")
  local dcs_type = self:_SafeCall(unit, "GetTypeName") or self:_DcsTypeName(dcs_unit)
  local alive = self:_SafeCall(unit, "IsAlive")
  if alive == nil then alive = self:_IsDcsObjectAlive(dcs_unit) end
  local active = self:_SafeCall(unit, "IsActive")
  local point = self:_DcsPoint(dcs_unit)
  local item = {object_id="UNIT:"..safe_tostring(name),dcs_name=safe_tostring(name),object_type="UNIT",group_name=group_name and safe_tostring(group_name) or nil,category=category and safe_tostring(category) or nil,coalition=self:_CoalitionToName(coalition_value),dcs_type=dcs_type and safe_tostring(dcs_type) or nil,alive=self:_BoolOrFalse(alive),active=self:_BoolOrFalse(active)}
  if point then self:_AddPointFields(item, point) end
  return item
end

function MOOSE_BRIDGE:BuildUnitSnapshot()
  local result = {}
  if _DATABASE and _DATABASE.UNITS then
    for unit_name, unit in pairs(_DATABASE.UNITS) do
      local ok, item = pcall(function() return self:_BuildUnitSnapshotItem(unit_name, unit) end)
      if ok and item then result[#result + 1] = item else self:_Log("Failed to snapshot unit " .. safe_tostring(unit_name) .. ": " .. safe_tostring(item)) end
    end
    return result
  end
  if not _DATABASE or not _DATABASE.GROUPS then return result end
  for _, group in pairs(_DATABASE.GROUPS) do
    local units = self:_SafeCall(group, "GetUnits")
    if type(units) == "table" then
      for unit_name, unit in pairs(units) do
        local ok, item = pcall(function() return self:_BuildUnitSnapshotItem(unit_name, unit) end)
        if ok and item then result[#result + 1] = item else self:_Log("Failed to snapshot group unit " .. safe_tostring(unit_name) .. ": " .. safe_tostring(item)) end
      end
    end
  end
  return result
end

function MOOSE_BRIDGE:_BuildStaticSnapshotItem(static_name, static)
  local name = self:_SafeCall(static, "GetName") or static_name
  local coalition_value = self:_SafeCall(static, "GetCoalition")
  local category = self:_SafeCall(static, "GetCategoryName") or self:_SafeCall(static, "GetCategory")
  local dcs_static = self:_SafeCall(static, "GetDCSObject")
  local dcs_type = self:_SafeCall(static, "GetTypeName") or self:_DcsTypeName(dcs_static)
  local alive = self:_SafeCall(static, "IsAlive")
  if alive == nil then alive = self:_IsDcsObjectAlive(dcs_static) end
  local point = self:_DcsPoint(dcs_static) or self:_PointFromMooseObject(static)
  local item = {object_id="STATIC:"..safe_tostring(name),dcs_name=safe_tostring(name),object_type="STATIC",category=category and safe_tostring(category) or "STATIC",coalition=self:_CoalitionToName(coalition_value),dcs_type=dcs_type and safe_tostring(dcs_type) or nil,alive=self:_BoolOrFalse(alive)}
  if point then self:_AddPointFields(item, point) end
  return item
end

function MOOSE_BRIDGE:BuildStaticSnapshot()
  local result = {}
  if not _DATABASE or not _DATABASE.STATICS then return result end
  for static_name, static in pairs(_DATABASE.STATICS) do
    local ok, item = pcall(function() return self:_BuildStaticSnapshotItem(static_name, static) end)
    if ok and item then result[#result + 1] = item else self:_Log("Failed to snapshot static " .. safe_tostring(static_name) .. ": " .. safe_tostring(item)) end
  end
  return result
end

function MOOSE_BRIDGE:_BuildAirbaseSnapshotItem(airbase_name, airbase)
  local name = self:_SafeCall(airbase, "GetName") or airbase.AirbaseName or airbase_name
  local coalition_value = self:_SafeCall(airbase, "GetCoalition")
  local airbase_category = airbase.category
  local object_category_name = airbase.objectcategoryName
  local point = self:_PointFromMooseObject(airbase)
  local item = {object_id="AIRBASE:"..safe_tostring(name),dcs_name=safe_tostring(name),name=safe_tostring(name),object_type="AIRBASE",category=self:_AirbaseCategoryToName(airbase_category) or "Airbase",type=object_category_name and safe_tostring(object_category_name) or nil,source="database.AIRBASES",airbase_id=self:_NumberOrNil(airbase.AirbaseID),coalition=self:_CoalitionToName(coalition_value)}
  if point then self:_AddPointFields(item, point) end
  return item
end

function MOOSE_BRIDGE:BuildAirbaseSnapshot()
  local result = {}
  if not _DATABASE or type(_DATABASE.AIRBASES) ~= "table" then return result end
  for airbase_name, airbase in pairs(_DATABASE.AIRBASES) do
    local ok_item, item = pcall(function() return self:_BuildAirbaseSnapshotItem(airbase_name, airbase) end)
    if ok_item and item and item.dcs_name then result[#result + 1] = item else self:_Log("Failed to snapshot airbase " .. safe_tostring(airbase_name) .. ": " .. safe_tostring(item)) end
  end
  return result
end

function MOOSE_BRIDGE:_BuildAmmunitionSnapshotItem(unit_name, unit)
  if not self:_IsMooseUnitAlive(unit) or not self:_BoolOrFalse(self:_SafeCall(unit, "IsActive")) then return nil end
  local category = self:_SafeCall(unit, "GetCategoryName") or self:_SafeCall(unit, "GetCategory")
  local category_name = category and safe_tostring(category):lower() or ""
  local supported_category = category_name:find("ground", 1, true)
    or category_name:find("ship", 1, true)
    or category_name:find("naval", 1, true)
  if not supported_category then return nil end
  local details = self:_SafeCall(unit, "GetAmmoDetailed")
  if type(details) ~= "table" then
    -- MOOSE instances already present in _DATABASE may not see methods added
    -- to the UNIT class after their construction.
    local ok_details, fallback_details = pcall(function() return detailed_unit_ammunition(unit) end)
    if not ok_details then
      self:_Log("Failed to read unit ammunition " .. safe_tostring(unit_name) .. ": " .. safe_tostring(fallback_details))
      return nil
    end
    details = fallback_details
  end
  if type(details) ~= "table" then return nil end
  local name = self:_SafeCall(unit, "GetName") or unit_name
  local group_name = self:_SafeCall(unit, "GetGroupName")
  local group = self:_SafeCall(unit, "GetGroup")
  if not group_name and group then group_name = self:_SafeCall(group, "GetName") end
  return {
    object_id="UNIT:"..safe_tostring(name),
    unit_id="UNIT:"..safe_tostring(name),
    unit_name=safe_tostring(name),
    group_id=group_name and "GROUP:"..safe_tostring(group_name) or nil,
    group_name=group_name and safe_tostring(group_name) or nil,
    dcs_type=details.type_name,
    category=category and safe_tostring(category) or nil,
    attributes=details.attributes or {},
    life=details.life,
    life0=details.life0,
    weapons=details.weapons or {},
  }
end

function MOOSE_BRIDGE:BuildAmmunitionSnapshot()
  local result = {}
  if not _DATABASE or not _DATABASE.UNITS then return result end
  for unit_name, unit in pairs(_DATABASE.UNITS) do
    local ok, item = pcall(function() return self:_BuildAmmunitionSnapshotItem(unit_name, unit) end)
    if ok and item then
      result[#result + 1] = item
    elseif not ok then
      self:_Log("Failed to snapshot unit ammunition " .. safe_tostring(unit_name) .. ": " .. safe_tostring(item))
    end
  end
  return result
end

function MOOSE_BRIDGE:_BuildAirbaseNameSet()
  local names = {}
  if not _DATABASE or type(_DATABASE.AIRBASES) ~= "table" then return names end
  for airbase_name, airbase in pairs(_DATABASE.AIRBASES) do
    local name = self:_SafeCall(airbase, "GetName") or airbase.AirbaseName or airbase_name
    if name then names[safe_tostring(name)] = true end
  end
  return names
end

function MOOSE_BRIDGE:_ZoneName(zone_name, zone)
  local name = self:_SafeCall(zone, "GetName")
  if not name and zone then name = zone.ZoneName end
  return name or zone_name
end

function MOOSE_BRIDGE:_ZonePolygonVertices(zone)
  local vec2_vertices = self:_SafeCall(zone, "GetVerticiesVec2")
  if type(vec2_vertices) ~= "table" or #vec2_vertices < 3 then return nil end
  local vertices = {}
  for _, vec2 in ipairs(vec2_vertices) do
    local x = self:_NumberOrNil(vec2 and vec2.x)
    local z = self:_NumberOrNil(vec2 and vec2.y)
    if x ~= nil and z ~= nil then
      local coordinates = self:_CoordinatesForPoint({x=x, y=0, z=z}, "ll")
      vertices[#vertices + 1] = {x=x, z=z, latitude=coordinates.latitude, longitude=coordinates.longitude}
    end
  end
  if #vertices < 3 then return nil end
  return vertices
end

function MOOSE_BRIDGE:_BuildZoneSnapshotItem(zone_name, zone, source)
  local name = self:_ZoneName(zone_name, zone)
  if not name then return nil end
  local point = self:_PointFromMooseObject(zone)
  if not point and env and env.mission and env.mission.triggers and type(env.mission.triggers.zones) == "table" then
    for _, trigger_zone in pairs(env.mission.triggers.zones) do
      if trigger_zone.name == name then point = {x=trigger_zone.x, y=0, z=trigger_zone.y}; break end
    end
  end
  local vertices = self:_ZonePolygonVertices(zone)
  local radius = nil
  if not vertices then radius = self:_SafeCall(zone, "GetRadius") or zone.radius end
  local item = {object_id="ZONE:"..safe_tostring(name),dcs_name=safe_tostring(name),object_type="ZONE",category="ZONE",class_name=zone.ClassName,shape=vertices and "polygon" or "circle",source=source,radius=radius,vertices=vertices}
  if point then self:_AddPointFields(item, point) end
  return item
end

function MOOSE_BRIDGE:BuildZoneSnapshot()
  local result = {}
  local seen = {}
  local airbase_names = self:_BuildAirbaseNameSet()
  for name, zone in pairs(self.RegisteredZones or {}) do
    local ok, item = pcall(function() return self:_BuildZoneSnapshotItem(name, zone, "registered") end)
    if ok and item and item.object_id then result[#result + 1] = item; seen[item.object_id] = true end
  end
  if _DATABASE and _DATABASE.ZONES then
    for name, zone in pairs(_DATABASE.ZONES) do
      local zone_name = self:_ZoneName(name, zone)
      if zone_name and not airbase_names[safe_tostring(zone_name)] then
        local ok, item = pcall(function() return self:_BuildZoneSnapshotItem(zone_name, zone, "database.ZONES") end)
        if ok and item and item.object_id and not seen[item.object_id] then result[#result + 1] = item; seen[item.object_id] = true end
      end
    end
  end
  if env and env.mission and env.mission.triggers and type(env.mission.triggers.zones) == "table" then
    for _, zone in pairs(env.mission.triggers.zones) do
      local object_id = "ZONE:" .. safe_tostring(zone.name)
      if not seen[object_id] then
        local item = {object_id=object_id,dcs_name=safe_tostring(zone.name),object_type="ZONE",category="ZONE",shape="circle",source="mission.triggers.zones",x=zone.x,y=0,z=zone.y,radius=zone.radius}
        result[#result + 1] = item
        seen[object_id] = true
      end
    end
  end
  return result
end

function MOOSE_BRIDGE:_BuildTerritorySnapshotItem(territory_name, territory, source)
  local name = self:_SafeCall(territory, "GetName") or territory_name
  if not name then return nil end
  local zone = self:_SafeCall(territory, "GetZone") or territory.zone
  if not zone then return nil end
  local zone_name = self:_SafeCall(territory, "GetZoneName") or self:_ZoneName(nil, zone)
  local zone_item = self:_BuildZoneSnapshotItem(zone_name, zone, source .. ".zone")
  if not zone_item then return nil end
  return {
    object_id="TERRITORY:"..safe_tostring(name),
    dcs_name=safe_tostring(name),
    name=safe_tostring(name),
    object_type="TERRITORY",
    category="TERRITORY",
    class_name=territory.ClassName or "TERRITORY",
    source=source,
    zone_name=safe_tostring(zone_name),
    zone_class_name=zone.ClassName,
    coalition=self:_CoalitionToName(self:_SafeCall(territory, "GetCoalition") or territory.coalition),
    shape=zone_item.shape,
    radius=zone_item.radius,
    vertices=zone_item.vertices,
    x=zone_item.x,
    y=zone_item.y,
    z=zone_item.z,
    latitude=zone_item.latitude,
    longitude=zone_item.longitude,
  }
end

function MOOSE_BRIDGE:BuildTerritorySnapshot()
  local result = {}
  if not _DATABASE or type(_DATABASE.TERRITORIES) ~= "table" then return result end
  for name, territory in pairs(_DATABASE.TERRITORIES) do
    local ok, item = pcall(function() return self:_BuildTerritorySnapshotItem(name, territory, "database.TERRITORIES") end)
    if ok and item and item.object_id then
      result[#result + 1] = item
    else
      self:_Log("Failed to snapshot territory " .. safe_tostring(name) .. ": " .. safe_tostring(item))
    end
  end
  return result
end

function MOOSE_BRIDGE:BuildObjectSnapshot()
  local objects = {}
  local function append_all(items) for _, item in ipairs(items or {}) do objects[#objects + 1] = item end end
  append_all(self:BuildGroupSnapshot())
  append_all(self:BuildUnitSnapshot())
  append_all(self:BuildStaticSnapshot())
  append_all(self:BuildAirbaseSnapshot())
  append_all(self:BuildZoneSnapshot())
  append_all(self:BuildTerritorySnapshot())
  return objects
end

function MOOSE_BRIDGE:_OpsName(object, fallback)
  return self:_ObjectName(object) or fallback
end

function MOOSE_BRIDGE:_OpsState(object)
  return self:_SafeCall(object, "GetState") or self:_SafeCall(object, "GetStatus")
end

function MOOSE_BRIDGE:_OpsClassName(object, fallback)
  if not object then return fallback end
  return string_or_nil(object.ClassName or fallback)
end

function MOOSE_BRIDGE:_OpsGroupKind(opsgroup)
  if self:_SafeCall(opsgroup, "IsFlightgroup") then return "FLIGHTGROUP" end
  if self:_SafeCall(opsgroup, "IsArmygroup") then return "ARMYGROUP" end
  if self:_SafeCall(opsgroup, "IsNavygroup") then return "NAVYGROUP" end
  return self:_OpsClassName(opsgroup, "OPSGROUP")
end

function MOOSE_BRIDGE:_OpsCoalition(opsgroup)
  local value = self:_SafeCall(opsgroup, "GetCoalition")
  if value == nil and opsgroup then value = opsgroup.coalition end
  return self:_CoalitionToName(value)
end

function MOOSE_BRIDGE:_CollectDetectedGroupIds(opsgroup)
  local result = {}; local seen = {}
  local detected = self:_SafeCall(opsgroup, "GetDetectedGroupSet") or self:_SafeCall(opsgroup, "GetDetectedSet")
  if detected and detected.Set then
    for name, _ in pairs(detected.Set) do append_unique(result, seen, "GROUP:" .. safe_tostring(name)) end
  end
  return result
end

function MOOSE_BRIDGE:_CollectAuftragIdsFromQueue(queue)
  local result = {}; local seen = {}
  if type(queue) ~= "table" then return result end
  for _, auftrag in pairs(queue) do
    local id = self:_AuftragObjectId(auftrag)
    append_unique(result, seen, id)
  end
  return result
end

function MOOSE_BRIDGE:_AuftragNumber(auftrag)
  if not auftrag then return nil end
  return auftrag.auftragsnummer or auftrag.uid or auftrag.id
end

function MOOSE_BRIDGE:_AuftragObjectId(auftrag)
  local number = self:_AuftragNumber(auftrag)
  if number == nil then return nil end
  return "AUFTRAG:" .. safe_tostring(number)
end

function MOOSE_BRIDGE:_AuftragObjectIdFromValue(value)
  if value == nil then return nil end
  if type(value) == "table" then return self:_AuftragObjectId(value) end
  local text = safe_tostring(value)
  if string.find(text, "^AUFTRAG:") then return text end
  return "AUFTRAG:" .. text
end

function MOOSE_BRIDGE:_BuildOpsGroupSnapshotItem(group_name, opsgroup, source)
  local name = self:_OpsName(opsgroup, group_name)
  if not name then return nil end
  local group_kind = self:_OpsGroupKind(opsgroup)
  local point = self:_PointFromMooseObject(opsgroup)
  local state = self:_OpsState(opsgroup)
  local alive = self:_SafeCall(opsgroup, "IsAlive")
  local active = self:_SafeCall(opsgroup, "IsActive")
  local current = opsgroup and (opsgroup.currentmission or opsgroup.missioncurrent or opsgroup.currentMission) or nil
  local current_id = self:_AuftragObjectIdFromValue(current)
  local item = {
    object_id="OPSGROUP:"..safe_tostring(name),
    dcs_name=safe_tostring(name),
    object_type="OPSGROUP",
    category=group_kind,
    class_name=self:_OpsClassName(opsgroup, "OPSGROUP"),
    source=source,
    name=safe_tostring(name),
    group_name=safe_tostring(name),
    state=string_or_nil(state),
    coalition=self:_OpsCoalition(opsgroup),
    alive=self:_BoolOrFalse(alive),
    active=self:_BoolOrFalse(active),
    is_ai=self:_BoolOrFalse(opsgroup and opsgroup.isAI),
    is_late_activated=self:_BoolOrFalse(opsgroup and opsgroup.isLateActivated),
    is_uncontrolled=self:_BoolOrFalse(opsgroup and opsgroup.isUncontrolled),
    is_dead=self:_BoolOrFalse(opsgroup and opsgroup.isDead),
    is_destroyed=self:_BoolOrFalse(opsgroup and opsgroup.isDestroyed),
    current_wp=opsgroup and opsgroup.currentwp or nil,
    speed_cruise=opsgroup and opsgroup.speedCruise or nil,
    speed_wp=opsgroup and opsgroup.speedWp or nil,
    heading=opsgroup and opsgroup.heading or nil,
    travel_dist=opsgroup and opsgroup.traveldist or nil,
    travel_time=opsgroup and opsgroup.traveltime or nil,
    homebase_name=self:_ObjectName(opsgroup and opsgroup.homebase),
    destbase_name=self:_ObjectName(opsgroup and opsgroup.destbase),
    currbase_name=self:_ObjectName(opsgroup and opsgroup.currbase),
    auftrag_current_id=current_id,
    auftrag_queue_ids=self:_CollectAuftragIdsFromQueue(opsgroup and opsgroup.missionqueue),
    detected_group_ids=self:_CollectDetectedGroupIds(opsgroup),
  }
  if point then self:_AddPointFields(item, point) end
  return item
end

function MOOSE_BRIDGE:BuildOpsGroupSnapshot()
  local result = {}; local seen = {}
  for name, opsgroup in pairs(self.RegisteredOpsGroups or {}) do
    local ok, item = pcall(function() return self:_BuildOpsGroupSnapshotItem(name, opsgroup, "registered") end)
    if ok and item and item.object_id then result[#result + 1] = item; seen[item.object_id] = true end
  end
  -- MOOSE stores all OPSGROUP specializations here despite the FLIGHTGROUPS name.
  if _DATABASE and type(_DATABASE.FLIGHTGROUPS) == "table" then
    for name, opsgroup in pairs(_DATABASE.FLIGHTGROUPS) do
      local ok, item = pcall(function() return self:_BuildOpsGroupSnapshotItem(name, opsgroup, "database.FLIGHTGROUPS") end)
      if ok and item and item.object_id and not seen[item.object_id] then result[#result + 1] = item; seen[item.object_id] = true end
    end
  end
  return result
end

function MOOSE_BRIDGE:_AddAuftragCandidate(result, seen, auftrag, source)
  if type(auftrag) ~= "table" then return end
  local object_id = self:_AuftragObjectId(auftrag)
  if not object_id or seen[object_id] then return end
  local ok, item = pcall(function() return self:_BuildAuftragSnapshotItem(auftrag, source) end)
  if ok and item and item.object_id then
    result[#result + 1] = item
    seen[item.object_id] = true
  end
end

function MOOSE_BRIDGE:_CollectAuftragCandidatesFromOpsGroup(result, seen, opsgroup)
  if type(opsgroup) ~= "table" then return end
  if type(opsgroup.missionqueue) == "table" then
    for _, auftrag in pairs(opsgroup.missionqueue) do self:_AddAuftragCandidate(result, seen, auftrag, "opsgroup.missionqueue") end
  end
end

function MOOSE_BRIDGE:_PointFromCoordinate(coordinate)
  if not coordinate then return nil end
  local vec3 = self:_SafeCall(coordinate, "GetVec3")
  if vec3 then return vec3 end
  if coordinate.x and coordinate.z then return {x=coordinate.x, y=coordinate.y or 0, z=coordinate.z} end
  return nil
end

function MOOSE_BRIDGE:_TargetObjectId(target_object)
  if not target_object then return nil end
  local target_type = target_object.Type
  local name = target_object.Name
  if not target_type or not name then return nil end
  local prefix_by_type = {
    Group="GROUP",
    Unit="UNIT",
    Static="STATIC",
    Scenery="SCENERY",
    Airbase="AIRBASE",
    Zone="ZONE",
    OpsZone="OPSZONE",
  }
  local prefix = prefix_by_type[target_type]
  if not prefix then return nil end
  return prefix .. ":" .. safe_tostring(name)
end

function MOOSE_BRIDGE:_BuildTargetObjectSnapshot(target, target_object)
  if type(target_object) ~= "table" then return nil end
  local coordinate = self:_SafeCallArg(target, "GetTargetCoordinate", target_object) or target_object.Coordinate
  local point = self:_PointFromCoordinate(coordinate)
  local item = {
    id=target_object.ID,
    type=string_or_nil(target_object.Type),
    name=string_or_nil(target_object.Name),
    object_id=self:_TargetObjectId(target_object),
    status=string_or_nil(target_object.Status),
    n0=target_object.N0,
    n_dead=target_object.Ndead,
    n_destroyed=target_object.Ndestroyed,
    life=target_object.Life,
    life0=target_object.Life0,
  }
  if point then self:_AddPointFields(item, point) end
  return item
end

function MOOSE_BRIDGE:_BuildTargetSnapshot(target)
  if type(target) ~= "table" then return nil end
  local target_objects = {}
  if type(target.targets) == "table" then
    for _, target_object in pairs(target.targets) do
      local ok, item = pcall(function() return self:_BuildTargetObjectSnapshot(target, target_object) end)
      if ok and item then target_objects[#target_objects + 1] = item end
    end
  end

  local point = self:_SafeCall(target, "GetVec3")
  if not point then point = self:_PointFromCoordinate(self:_SafeCall(target, "GetCoordinate")) end

  local item = {
    object_id=target.uid and ("TARGET:" .. safe_tostring(target.uid)) or nil,
    name=string_or_nil(self:_SafeCall(target, "GetName") or target.name),
    state=string_or_nil(self:_SafeCall(target, "GetState")),
    category=string_or_nil(self:_SafeCall(target, "GetCategory") or target.category),
    heading=self:_SafeCall(target, "GetHeading"),
    life=self:_SafeCall(target, "GetLife") or target.life,
    life0=self:_SafeCall(target, "GetLife0") or target.life0,
    damage=self:_SafeCall(target, "GetDamage"),
    threat_level_max=self:_SafeCall(target, "GetThreatLevelMax") or target.threatlevel0,
    n0=target.N0,
    n_targets0=target.Ntargets0,
    n_destroyed=target.Ndestroyed,
    n_dead=target.Ndead,
    is_destroyed=self:_BoolOrFalse(target.isDestroyed),
    objects=target_objects,
  }
  if point then self:_AddPointFields(item, point) end
  return item
end

function MOOSE_BRIDGE:_CollectLegionNames(legions)
  local result = {}; local seen = {}
  if type(legions) ~= "table" then return result end
  for key, legion in pairs(legions) do
    local name = self:_ObjectName(legion)
    if not name and type(key) == "string" then name = key end
    append_unique(result, seen, name)
  end
  return result
end

function MOOSE_BRIDGE:_LegionKind(legion)
  if self:_SafeCall(legion, "IsAirwing") then return "AIRWING" end
  if self:_SafeCall(legion, "IsBrigade") then return "BRIGADE" end
  if self:_SafeCall(legion, "IsFleet") then return "FLEET" end
  return self:_OpsClassName(legion, "LEGION")
end

function MOOSE_BRIDGE:_LegionName(legion, fallback)
  if not legion then return fallback end
  return self:_SafeCall(legion, "GetName") or legion.alias or fallback
end

function MOOSE_BRIDGE:_CohortName(cohort, fallback)
  if not cohort then return fallback end
  return self:_SafeCall(cohort, "GetName") or cohort.name or fallback
end

function MOOSE_BRIDGE:_CohortKind(cohort)
  if not cohort then return nil end
  if cohort.isAir then return "AIR" end
  if cohort.isGround then return "GROUND" end
  if cohort.isNaval then return "NAVAL" end
  return self:_OpsClassName(cohort, "COHORT")
end

function MOOSE_BRIDGE:_CollectCohortIds(cohorts)
  local result = {}; local seen = {}
  if type(cohorts) ~= "table" then return result end
  for index, cohort in pairs(cohorts) do
    local fallback = type(index) == "string" and index or nil
    local name = self:_CohortName(cohort, fallback)
    append_unique(result, seen, name and ("COHORT:" .. safe_tostring(name)) or nil)
  end
  return result
end

function MOOSE_BRIDGE:_BuildCohortSummary(cohort, index)
  local fallback = type(index) == "string" and index or nil
  local name = self:_CohortName(cohort, fallback)
  if not name then return nil end
  return {
    object_id="COHORT:" .. safe_tostring(name),
    name=safe_tostring(name),
    category=self:_CohortKind(cohort),
    class_name=self:_OpsClassName(cohort, "COHORT"),
    is_air=self:_BoolOrFalse(cohort and cohort.isAir),
    is_ground=self:_BoolOrFalse(cohort and cohort.isGround),
    is_naval=self:_BoolOrFalse(cohort and cohort.isNaval),
  }
end

function MOOSE_BRIDGE:_BuildCohortSummaries(cohorts)
  local result = {}
  if type(cohorts) ~= "table" then return result end
  for index, cohort in pairs(cohorts) do
    local ok, item = pcall(function() return self:_BuildCohortSummary(cohort, index) end)
    if ok and item then result[#result + 1] = item end
  end
  return result
end

function MOOSE_BRIDGE:_CommanderName(commander, fallback)
  if not commander then return fallback end
  return commander.alias or self:_SafeCall(commander, "GetName") or fallback
end

function MOOSE_BRIDGE:_CollectLegionIds(legions)
  local result = {}; local seen = {}
  if type(legions) ~= "table" then return result end
  for index, legion in pairs(legions) do
    local fallback = type(index) == "string" and index or nil
    local name = self:_LegionName(legion, fallback)
    append_unique(result, seen, name and ("LEGION:" .. safe_tostring(name)) or nil)
  end
  return result
end

function MOOSE_BRIDGE:_BuildCommanderSnapshotItem(commander_name, commander, source)
  local name = self:_CommanderName(commander, commander_name)
  if not name then return nil end
  return {
    object_id="COMMANDER:" .. safe_tostring(name),
    dcs_name=safe_tostring(name),
    object_type="COMMANDER",
    category="COMMANDER",
    class_name=self:_OpsClassName(commander, "COMMANDER"),
    source=source,
    name=safe_tostring(name),
    alias=string_or_nil(commander and commander.alias),
    state=string_or_nil(self:_SafeCall(commander, "GetState")),
    coalition=self:_CoalitionToName(self:_SafeCall(commander, "GetCoalition") or (commander and commander.coalition)),
    legion_ids=self:_CollectLegionIds(commander and commander.legions),
    n_legions=self:_CountTable((commander and commander.legions) or {}),
    available_asset_count=self:_NumberOrNil(self:_SafeCall(commander, "CountAvailableAssets")),
    auftrag_queue_ids=self:_CollectAuftragIdsFromQueue(commander and commander.missionqueue),
  }
end

function MOOSE_BRIDGE:BuildCommanderSnapshot()
  local result = {}; local seen = {}
  local function add(name, commander, source)
    local ok, item = pcall(function() return self:_BuildCommanderSnapshotItem(name, commander, source) end)
    if ok and item and item.object_id and not seen[item.object_id] then
      result[#result + 1] = item
      seen[item.object_id] = true
    elseif not ok then
      self:_Log("Failed to snapshot commander " .. safe_tostring(name) .. ": " .. safe_tostring(item))
    end
  end
  for name, commander in pairs(self.RegisteredCommanders or {}) do add(name, commander, "registered") end
  if _DATABASE and type(_DATABASE.COMMANDERS) == "table" then
    for name, commander in pairs(_DATABASE.COMMANDERS) do add(name, commander, "database.COMMANDERS") end
  end
  return result
end

function MOOSE_BRIDGE:_BuildLegionSnapshotItem(legion_name, legion, source)
  local name = self:_LegionName(legion, legion_name)
  if not name then return nil end
  local point = self:_PointFromMooseObject(legion)
  local airbase = self:_SafeCall(legion, "GetAirbase")
  local item = {
    object_id="LEGION:"..safe_tostring(name),
    dcs_name=safe_tostring(name),
    object_type="LEGION",
    category=self:_LegionKind(legion),
    class_name=self:_OpsClassName(legion, "LEGION"),
    source=source,
    name=safe_tostring(name),
    alias=string_or_nil(legion and legion.alias),
    state=string_or_nil(self:_SafeCall(legion, "GetState")),
    coalition=self:_CoalitionToName(self:_SafeCall(legion, "GetCoalition")),
    coalition_name=string_or_nil(self:_SafeCall(legion, "GetCoalitionName")),
    airbase_name=string_or_nil(self:_SafeCall(legion, "GetAirbaseName") or self:_ObjectName(airbase)),
    cohort_ids=self:_CollectCohortIds(legion and legion.cohorts),
    cohorts=self:_BuildCohortSummaries(legion and legion.cohorts),
    n_cohorts=self:_CountTable((legion and legion.cohorts) or {}),
    available_asset_count=self:_NumberOrNil(self:_SafeCall(legion, "CountAvailableAssets")),
    auftrag_queue_ids=self:_CollectAuftragIdsFromQueue(legion and legion.missionqueue),
  }
  if point then self:_AddPointFields(item, point) end
  return item
end

function MOOSE_BRIDGE:BuildLegionSnapshot()
  local result = {}; local seen = {}
  if _DATABASE and type(_DATABASE.LEGIONS) == "table" then
    for name, legion in pairs(_DATABASE.LEGIONS) do
      local ok, item = pcall(function() return self:_BuildLegionSnapshotItem(name, legion, "database.LEGIONS") end)
      if ok and item and item.object_id and not seen[item.object_id] then
        result[#result + 1] = item
        seen[item.object_id] = true
      elseif not ok then
        self:_Log("Failed to snapshot legion " .. safe_tostring(name) .. ": " .. safe_tostring(item))
      end
    end
  end
  return result
end

function MOOSE_BRIDGE:_CohortObjectId(cohort, fallback)
  local name = self:_CohortName(cohort, fallback)
  if not name then return nil end
  return "COHORT:" .. safe_tostring(name)
end

function MOOSE_BRIDGE:_CollectMissionTypeNames(mission_types)
  local result = {}; local seen = {}
  if type(mission_types) ~= "table" then return result end
  for key, value in pairs(mission_types) do
    if type(value) == "string" then
      append_unique(result, seen, value)
    elseif type(key) == "string" and value then
      append_unique(result, seen, key)
    elseif value ~= nil then
      append_unique(result, seen, safe_tostring(value))
    end
  end
  return result
end

function MOOSE_BRIDGE:_CollectMissionPerformance(cohort, mission_types)
  local result = {}
  if not cohort or type(mission_types) ~= "table" then return result end
  for _, mission_type in pairs(mission_types) do
    local performance = self:_SafeCallArg(cohort, "GetMissionPeformance", mission_type)
    if performance == nil then performance = self:_SafeCallArg(cohort, "GetMissionPerformance", mission_type) end
    if type(performance) == "number" then result[safe_tostring(mission_type)] = performance end
  end
  return result
end

function MOOSE_BRIDGE:_CollectOpsGroupIdsFromSet(set_opsgroup)
  local result = {}; local seen = {}
  if not set_opsgroup then return result end

  local for_each = set_opsgroup.ForEachOpsGroup or set_opsgroup.ForEach
  if for_each then
    pcall(function()
      for_each(set_opsgroup, function(opsgroup)
        local name = self:_OpsName(opsgroup, nil)
        if name then append_unique(result, seen, "OPSGROUP:" .. safe_tostring(name)) end
      end)
    end)
  end

  if #result == 0 and type(set_opsgroup.Set) == "table" then
    for name, opsgroup in pairs(set_opsgroup.Set) do
      local opsgroup_name = self:_OpsName(opsgroup, type(name) == "string" and name or nil)
      if opsgroup_name then append_unique(result, seen, "OPSGROUP:" .. safe_tostring(opsgroup_name)) end
    end
  end

  return result
end

function MOOSE_BRIDGE:_CollectCohortIndirectMissionRanges(cohort)
  local result = {}
  local weapon_types = {
    16384,        -- HeavyRocket
    30720,        -- AnyRocket
    68719476736,  -- SubmunitionDispenserShell
    137438953472, -- GuidedShell
    206963736576, -- ConventionalShell
    258503344128, -- AnyShell
  }
  for _, weapon_type in ipairs(weapon_types) do
    local mission_range = self:_SafeCallArg(cohort, "GetMissionRange", {weapon_type})
    if type(mission_range) == "number" then
      result[string.format("%.0f", weapon_type)] = mission_range
    end
  end
  return result
end

function MOOSE_BRIDGE:_CollectCohortWeaponRanges(cohort)
  local result = {}
  if type(cohort) ~= "table" or type(cohort.weaponData) ~= "table" then return result end
  for key, weapon in pairs(cohort.weaponData) do
    if type(weapon) == "table" then
      local bit_type = self:_NumberOrNil(weapon.BitType) or self:_NumberOrNil(key)
      if bit_type ~= nil then
        result[string.format("%.0f", bit_type)] = {
          weapon_type=bit_type,
          minimum_m=self:_NumberOrNil(weapon.RangeMin),
          maximum_m=self:_NumberOrNil(weapon.RangeMax),
        }
      end
    end
  end
  return result
end

function MOOSE_BRIDGE:_AnalyzeCohortComposition(cohort)
  if type(cohort) ~= "table" or type(cohort.assets) ~= "table" then return false, nil end
  local expected_type = nil
  local expected_count = nil
  local uniform_count = true
  local inspected = false
  for _, asset in pairs(cohort.assets) do
    local units = asset and asset.template and asset.template.units
    if type(units) == "table" and #units > 0 then
      local count = #units
      if expected_count ~= nil and count ~= expected_count then uniform_count = false end
      if expected_count == nil then expected_count = count end
      for _, unit in ipairs(units) do
        local unit_type = unit and (unit.type or unit.typeName)
        if type(unit_type) ~= "string" or unit_type == "" then return false, nil end
        if expected_type ~= nil and unit_type ~= expected_type then return false, nil end
        expected_type = unit_type
        inspected = true
      end
    end
  end
  if not inspected then return false, nil end
  return true, uniform_count and expected_count or nil
end

function MOOSE_BRIDGE:_BuildCohortSnapshotItem(cohort_name, cohort, source)
  local name = self:_CohortName(cohort, cohort_name)
  if not name then return nil end
  local legion_name = self:_LegionName(cohort and cohort.legion, nil)
  local mission_types = self:_CollectMissionTypeNames(self:_SafeCall(cohort, "GetMissionTypes"))
  local opsgroups = self:_SafeCall(cohort, "GetOpsGroups")
  local point = self:_PointFromMooseObject(cohort)
  local homogeneous, units_per_asset = self:_AnalyzeCohortComposition(cohort)

  local item = {
    object_id="COHORT:"..safe_tostring(name),
    dcs_name=safe_tostring(name),
    object_type="COHORT",
    category=self:_CohortKind(cohort),
    class_name=self:_OpsClassName(cohort, "COHORT"),
    source=source,
    name=safe_tostring(name),
    legion_id=legion_name and ("LEGION:" .. safe_tostring(legion_name)) or nil,
    legion_name=string_or_nil(legion_name),
    is_air=self:_BoolOrFalse(cohort and cohort.isAir),
    is_ground=self:_BoolOrFalse(cohort and cohort.isGround),
    is_naval=self:_BoolOrFalse(cohort and cohort.isNaval),
    mission_types=mission_types,
    mission_performance=self:_CollectMissionPerformance(cohort, mission_types),
    skill=cohort and cohort.skill or nil,
    homogeneous=homogeneous,
    configured_grouping=self:_NumberOrNil(cohort and cohort.ngrouping),
    units_per_asset=units_per_asset,
    engage_range_m=self:_NumberOrNil(cohort and cohort.engageRange),
    mission_range_m=self:_NumberOrNil(self:_SafeCall(cohort, "GetMissionRange")),
    mission_ranges_by_weapon_type=self:_CollectCohortIndirectMissionRanges(cohort),
    weapon_ranges_by_type=self:_CollectCohortWeaponRanges(cohort),
    asset_count=self:_NumberOrNil(self:_SafeCall(cohort, "CountAssets")),
    stock_asset_count=self:_NumberOrNil(self:_SafeCallArg(cohort, "CountAssets", true)),
    available_asset_count=self:_NumberOrNil(self:_SafeCall(cohort, "CountAvailableAssets")),
    spawned_asset_count=self:_NumberOrNil(self:_SafeCallArg(cohort, "CountAssets", false)),
    opsgroup_count=self:_CountSet(opsgroups),
    opsgroup_ids=self:_CollectOpsGroupIdsFromSet(opsgroups),
  }
  if point then self:_AddPointFields(item, point) end
  return item
end

function MOOSE_BRIDGE:BuildCohortSnapshot()
  local result = {}; local seen = {}
  if _DATABASE and type(_DATABASE.COHORTS) == "table" then
    for name, cohort in pairs(_DATABASE.COHORTS) do
      local ok, item = pcall(function() return self:_BuildCohortSnapshotItem(name, cohort, "database.COHORTS") end)
      if ok and item and item.object_id and not seen[item.object_id] then
        result[#result + 1] = item
        seen[item.object_id] = true
      elseif not ok then
        self:_Log("Failed to snapshot cohort " .. safe_tostring(name) .. ": " .. safe_tostring(item))
      end
    end
  end
  return result
end

function MOOSE_BRIDGE:_BuildAuftragSnapshotItem(auftrag, source)
  local object_id = self:_AuftragObjectId(auftrag)
  local auftrag_type = self:_SafeCall(auftrag, "GetType") or auftrag.type
  local assigned_group_ids = {}
  local group_seen = {}
  local opsgroups = self:_SafeCall(auftrag, "GetOpsGroups")
  if type(opsgroups) == "table" then
    for _, opsgroup in pairs(opsgroups) do
      local name = self:_OpsName(opsgroup, nil)
      if name then append_unique(assigned_group_ids, group_seen, "OPSGROUP:" .. safe_tostring(name)) end
    end
  end
  return {
    object_id=object_id,
    dcs_name=safe_tostring(auftrag.name or object_id),
    object_type="AUFTRAG",
    category=string_or_nil(auftrag_type),
    source=source,
    auftragsnummer=self:_AuftragNumber(auftrag),
    name=string_or_nil(auftrag.name),
    type=string_or_nil(auftrag_type),
    status=string_or_nil(self:_SafeCall(auftrag, "GetState") or auftrag.status),
    prio=auftrag.prio,
    urgent=self:_BoolOrFalse(auftrag.urgent),
    importance=auftrag.importance,
    t_start=auftrag.Tstart,
    t_stop=auftrag.Tstop,
    duration=auftrag.duration,
    duration_exe=auftrag.durationExe,
    t_started=auftrag.Tstarted,
    t_executing=auftrag.Texecuting,
    t_push=auftrag.Tpush,
    t_over=auftrag.Tover,
    n_assigned=auftrag.Nassigned,
    n_elements=auftrag.Nelements,
    n_dead=auftrag.Ndead,
    n_kills=auftrag.Nkills,
    n_casualties=auftrag.Ncasualties,
    mission_task=string_or_nil(auftrag.missionTask),
    mission_altitude=auftrag.missionAltitude,
    mission_speed=auftrag.missionSpeed,
    mission_range=auftrag.missionRange,
    chief_name=self:_ObjectName(auftrag.chief),
    commander_name=self:_ObjectName(auftrag.commander),
    operation_name=self:_ObjectName(auftrag.operation),
    assigned_group_ids=assigned_group_ids,
    legion_names=self:_CollectLegionNames(auftrag.legions),
    target=self:_BuildTargetSnapshot(auftrag.engageTarget),
  }
end

function MOOSE_BRIDGE:BuildAuftragSnapshot()
  local result = {}; local seen = {}
  for _, opsgroup in pairs(self.RegisteredOpsGroups or {}) do self:_CollectAuftragCandidatesFromOpsGroup(result, seen, opsgroup) end
  -- MOOSE stores all OPSGROUP specializations here despite the FLIGHTGROUPS name.
  if _DATABASE and type(_DATABASE.FLIGHTGROUPS) == "table" then
    for _, opsgroup in pairs(_DATABASE.FLIGHTGROUPS) do self:_CollectAuftragCandidatesFromOpsGroup(result, seen, opsgroup) end
  end
  return result
end

function MOOSE_BRIDGE:RegisterDefaultCommands()
  self:RegisterCommand("time.get", function(cmd)
    return {action="time.get", mission_time=mission_time(), dcs_time=dcs_time(), mission_date=self.MissionDate, wall_time=wall_time()}
  end)

  self:RegisterCommand("message.to_all", function(cmd)
    local p = cmd.params or {}
    MESSAGE:New(p.text or "", p.duration or 10):ToAll()
    return {text=p.text, duration=p.duration or 10}
  end)

  self:RegisterCommand("message.to_coalition", function(cmd)
    local p = cmd.params or {}
    local side = coalition_from_name(p.coalition or "blue")
    if side == nil then error("Unknown coalition " .. safe_tostring(p.coalition)) end
    MESSAGE:New(p.text or "", p.duration or 10):ToCoalition(side)
    return {coalition=p.coalition, text=p.text, duration=p.duration or 10}
  end)

  local smoke_at_point_handler = function(cmd)
    local p = cmd.params or {}
    local point = self:_PointFromParams(p)
    return self:_SmokePoint(point, p.color or "white")
  end
  self:RegisterCommand("smoke.at_point", smoke_at_point_handler)
  self:RegisterCommand("smoke.point", smoke_at_point_handler)

  local mark_at_point_handler = function(cmd)
    local p = cmd.params or {}
    local point = self:_PointFromParams(p)
    return self:_MarkPoint(point, p.text or "MOOSE Bridge mark")
  end
  self:RegisterCommand("mark.at_point", mark_at_point_handler)
  self:RegisterCommand("mark.point", mark_at_point_handler)

  self:RegisterCommand("smoke.object", function(cmd)
    local p = cmd.params or {}; local point = self:_PointForObjectId(p.object_id)
    return self:_SmokePoint(point, p.color or "white")
  end)

  local explosion_at_point_handler = function(cmd)
    local p = cmd.params or {}
    local point = self:_PointFromParams(p)
    if p.y == nil and land and land.getHeight then
      point.y = land.getHeight({x=point.x, y=point.z})
    end
    return self:_ExplosionPoint(point, p.power, p.delay)
  end
  self:RegisterCommand("explosion.at_point", explosion_at_point_handler)
  self:RegisterCommand("explosion.point", explosion_at_point_handler)

  self:RegisterCommand("explosion.object", function(cmd)
    local p = cmd.params or {}; local point = self:_PointForObjectId(p.object_id)
    return self:_ExplosionPoint(point, p.power, p.delay)
  end)

  self:RegisterCommand("mark.object", function(cmd)
    local p = cmd.params or {}; local point = self:_PointForObjectId(p.object_id)
    return self:_MarkPoint(point, p.text or "MOOSE Bridge mark")
  end)

  self:RegisterCommand("map.overlay.draw", function(cmd)
    return self:_DrawDebugOverlay(cmd.params or {})
  end)

  self:RegisterCommand("map.overlay.clear", function(cmd)
    local p = cmd.params or {}
    local overlay_id = self:_OptionalString(p.overlay_id)
    local removed = overlay_id and self:_ClearDebugOverlay(overlay_id) or self:_ClearDebugOverlays()
    return {action="map.overlay.clear", overlay_id=overlay_id, removed=removed}
  end)

  self:RegisterCommand("object.coords", function(cmd)
    local p = cmd.params or {}
    local object_id = self:_OptionalString(p.object_id)
    local point = self:_PointForObjectId(object_id)
    local result = self:_CoordinatesForPoint(point, p.format)
    result.action = "object.coords"
    result.object_id = object_id
    return result
  end)

  self:RegisterCommand("coordinates.convert_points", function(cmd)
    local p = cmd.params or {}
    if type(p.points) ~= "table" then error("coordinates.convert_points requires points") end
    if #p.points > 5000 then error("coordinates.convert_points accepts at most 5000 points") end
    local points = {}
    for index, point in ipairs(p.points) do
      if type(point) ~= "table" or type(point.x) ~= "number" or type(point.z) ~= "number" then
        error("Invalid point at index " .. safe_tostring(index))
      end
      local converted = self:_CoordinatesForPoint({x=point.x, y=point.y or 0, z=point.z}, "ll")
      points[#points + 1] = {
        x=converted.x,
        y=converted.y,
        z=converted.z,
        latitude=converted.latitude,
        longitude=converted.longitude,
      }
    end
    return {action="coordinates.convert_points", count=#points, points=points}
  end)

  self:RegisterCommand("terrain.closest_road_points", function(cmd)
    local p = cmd.params or {}
    if not land or not land.getClosestPointOnRoads then error("DCS land.getClosestPointOnRoads is not available") end
    if type(p.points) ~= "table" or #p.points == 0 then error("terrain.closest_road_points requires points") end
    if #p.points > 500 then error("terrain.closest_road_points accepts at most 500 points") end
    local road_type = string.lower(tostring(p.road_type or "roads"))
    if road_type ~= "roads" and road_type ~= "railroads" then error("road_type must be roads or railroads") end
    local samples = {}
    for index, value in ipairs(p.points) do
      local point = self:_DebugMarkupPoint(value)
      local road_x, road_z = land.getClosestPointOnRoads(road_type, point.x, point.z)
      if type(road_x) ~= "number" or type(road_z) ~= "number" then
        error("DCS returned no closest road point at index " .. safe_tostring(index))
      end
      local road_y = land.getHeight and land.getHeight({x=road_x, y=road_z}) or 0
      local nearest = {x=road_x, y=road_y or 0, z=road_z}
      local input_coordinates = self:_CoordinatesForPoint(point, "ll")
      local nearest_coordinates = self:_CoordinatesForPoint(nearest, "ll")
      samples[#samples + 1] = {
        input_x=point.x,
        input_y=point.y or 0,
        input_z=point.z,
        input_latitude=input_coordinates.latitude,
        input_longitude=input_coordinates.longitude,
        road_x=nearest.x,
        road_y=nearest.y,
        road_z=nearest.z,
        road_latitude=nearest_coordinates.latitude,
        road_longitude=nearest_coordinates.longitude,
        distance_m=math.sqrt((road_x - point.x) ^ 2 + (road_z - point.z) ^ 2),
      }
    end
    return {action="terrain.closest_road_points", road_type=road_type, count=#samples, samples=samples}
  end)

  self:RegisterCommand("terrain.surface_types", function(cmd)
    local p = cmd.params or {}
    if not land or not land.getSurfaceType then error("DCS land.getSurfaceType is not available") end
    if type(p.points) ~= "table" or #p.points == 0 then error("terrain.surface_types requires points") end
    if #p.points > 500 then error("terrain.surface_types accepts at most 500 points") end
    local surface_names = {
      [1]="LAND",
      [2]="SHALLOW_WATER",
      [3]="WATER",
      [4]="ROAD",
      [5]="RUNWAY",
    }
    local shallow_water = land.SurfaceType and land.SurfaceType.SHALLOW_WATER or 2
    local water = land.SurfaceType and land.SurfaceType.WATER or 3
    local samples = {}
    for index, value in ipairs(p.points) do
      local point = self:_DebugMarkupPoint(value)
      local surface_type = land.getSurfaceType({x=point.x, y=point.z})
      if type(surface_type) ~= "number" then
        error("DCS returned no surface type at index " .. safe_tostring(index))
      end
      local coordinates = self:_CoordinatesForPoint(point, "ll")
      samples[#samples + 1] = {
        input_x=point.x,
        input_y=point.y or 0,
        input_z=point.z,
        input_latitude=coordinates.latitude,
        input_longitude=coordinates.longitude,
        surface_type=surface_type,
        surface_name=surface_names[surface_type] or "UNKNOWN",
        is_water=surface_type == shallow_water or surface_type == water,
      }
    end
    return {action="terrain.surface_types", count=#samples, samples=samples}
  end)

  self:RegisterCommand("object.distance", function(cmd)
    local p = cmd.params or {}
    local object_id_a = self:_OptionalString(p.object_id_a)
    local object_id_b = self:_OptionalString(p.object_id_b)
    local point_a = self:_PointForObjectId(object_id_a)
    local point_b = self:_PointForObjectId(object_id_b)
    local meters = self:_DistanceBetweenPoints(point_a, point_b)
    return {
      action="object.distance",
      object_id_a=object_id_a,
      object_id_b=object_id_b,
      distance_m=meters,
      distance_km=meters / 1000,
      distance_nm=meters / 1852,
    }
  end)

  self:RegisterCommand("zone.draw", function(cmd)
    local p = cmd.params or {}
    local object_id = self:_OptionalString(p.zone_id) or self:_OptionalString(p.object_id)
    local zone, zone_name, zone_type = self:_ZoneForDrawObjectId(object_id)
    local draw_coalition = self:_DrawZoneCoalition(p.coalition)
    local color = self:_DrawZoneColor(p.color)
    local alpha = self:_NumberOrNil(p.alpha)
    local fill_color = self:_DrawZoneColor(p.fill_color)
    local fill_alpha = self:_NumberOrNil(p.fill_alpha)
    local line_type = self:_DrawZoneLineType(p.line_type)
    zone:DrawZone(draw_coalition, color, alpha, fill_color, fill_alpha, line_type)
    return {
      action="zone.draw",
      object_id=object_id,
      zone_name=zone_name,
      zone_type=zone_type,
      coalition=draw_coalition,
      color=p.color,
      alpha=alpha,
      fill_color=p.fill_color,
      fill_alpha=fill_alpha,
      line_type=line_type,
    }
  end)

  self:RegisterCommand("territory.set_coalition", function(cmd)
    local p = cmd.params or {}
    local object_id = self:_OptionalString(p.territory_id) or self:_OptionalString(p.object_id)
    local object_type, name = self:_SplitObjectId(object_id)
    if object_type ~= "TERRITORY" or not name or name == "" then
      error("territory.set_coalition requires TERRITORY:<name>")
    end
    local territory = self:_TerritoryForName(name)
    if not territory then error("Territory not found: " .. safe_tostring(object_id)) end
    local side = coalition_from_name(p.coalition)
    if side == nil then error("Unknown coalition " .. safe_tostring(p.coalition)) end
    local previous = self:_CoalitionToName(self:_SafeCall(territory, "GetCoalition") or territory.coalition)
    local updated = self:_SafeCallArg(territory, "SetCoalition", side)
    if not updated then error("Territory rejected coalition " .. safe_tostring(p.coalition)) end
    local item = self:_BuildTerritorySnapshotItem(name, territory, "database.TERRITORIES")
    self:SendEvent("territory.coalition_changed", {
      territory_id=object_id,
      previous_coalition=previous,
      coalition=self:_CoalitionToName(side),
      territory=item,
    })
    return {
      action="territory.set_coalition",
      territory_id=object_id,
      previous_coalition=previous,
      coalition=self:_CoalitionToName(side),
    }
  end)

  self:RegisterCommand("snapshot.groups", function(cmd)
    local groups = self:BuildGroupSnapshot(); self:SendSnapshot("groups", {groups=groups}); return {kind="groups", count=#groups}
  end)

  self:RegisterCommand("snapshot.units", function(cmd)
    local units = self:BuildUnitSnapshot(); self:SendSnapshot("units", {units=units}); return {kind="units", count=#units}
  end)

  self:RegisterCommand("snapshot.ammunition", function(cmd)
    local ammunition = self:BuildAmmunitionSnapshot(); self:SendSnapshot("ammunition", {ammunition=ammunition}); return {kind="ammunition", count=#ammunition}
  end)

  self:RegisterCommand("snapshot.statics", function(cmd)
    local statics = self:BuildStaticSnapshot(); self:SendSnapshot("statics", {statics=statics}); return {kind="statics", count=#statics}
  end)

  self:RegisterCommand("snapshot.airbases", function(cmd)
    local airbases = self:BuildAirbaseSnapshot(); self:SendSnapshot("airbases", {airbases=airbases}); return {kind="airbases", count=#airbases}
  end)

  self:RegisterCommand("snapshot.zones", function(cmd)
    local zones = self:BuildZoneSnapshot(); self:SendSnapshot("zones", {zones=zones}); return {kind="zones", count=#zones}
  end)

  self:RegisterCommand("snapshot.territories", function(cmd)
    local territories = self:BuildTerritorySnapshot(); self:SendSnapshot("territories", {territories=territories}); return {kind="territories", count=#territories}
  end)

  self:RegisterCommand("snapshot.objects", function(cmd)
    local objects = self:BuildObjectSnapshot(); self:SendSnapshot("objects", {objects=objects}); return {kind="objects", count=#objects}
  end)

  self:RegisterCommand("snapshot.opszones", function(cmd)
    local opszones = self:BuildOpsZoneSnapshot(); self:SendSnapshot("opszones", {opszones=opszones}); return {kind="opszones", count=#opszones}
  end)

  self:RegisterCommand("snapshot.opsgroups", function(cmd)
    local opsgroups = self:BuildOpsGroupSnapshot(); self:SendSnapshot("opsgroups", {opsgroups=opsgroups}); return {kind="opsgroups", count=#opsgroups}
  end)

  self:RegisterCommand("snapshot.auftraege", function(cmd)
    local auftraege = self:BuildAuftragSnapshot(); self:SendSnapshot("auftraege", {auftraege=auftraege}); return {kind="auftraege", count=#auftraege}
  end)

  self:RegisterCommand("snapshot.legions", function(cmd)
    local legions = self:BuildLegionSnapshot(); self:SendSnapshot("legions", {legions=legions}); return {kind="legions", count=#legions}
  end)

  self:RegisterCommand("snapshot.commanders", function(cmd)
    local commanders = self:BuildCommanderSnapshot(); self:SendSnapshot("commanders", {commanders=commanders}); return {kind="commanders", count=#commanders}
  end)

  self:RegisterCommand("snapshot.cohorts", function(cmd)
    local cohorts = self:BuildCohortSnapshot(); self:SendSnapshot("cohorts", {cohorts=cohorts}); return {kind="cohorts", count=#cohorts}
  end)

  self:RegisterCommand("snapshot.all", function(cmd)
    local groups = self:BuildGroupSnapshot()
    local units = self:BuildUnitSnapshot()
    local statics = self:BuildStaticSnapshot()
    local airbases = self:BuildAirbaseSnapshot()
    local zones = self:BuildZoneSnapshot()
    local territories = self:BuildTerritorySnapshot()
    local opszones = self:BuildOpsZoneSnapshot()
    local opsgroups = self:BuildOpsGroupSnapshot()
    local auftraege = self:BuildAuftragSnapshot()
    local legions = self:BuildLegionSnapshot()
    local cohorts = self:BuildCohortSnapshot()
    local commanders = self:BuildCommanderSnapshot()
    self:SendSnapshot("groups", {groups=groups})
    self:SendSnapshot("units", {units=units})
    self:SendSnapshot("statics", {statics=statics})
    self:SendSnapshot("airbases", {airbases=airbases})
    self:SendSnapshot("zones", {zones=zones})
    self:SendSnapshot("territories", {territories=territories})
    self:SendSnapshot("opszones", {opszones=opszones})
    self:SendSnapshot("opsgroups", {opsgroups=opsgroups})
    self:SendSnapshot("auftraege", {auftraege=auftraege})
    self:SendSnapshot("legions", {legions=legions})
    self:SendSnapshot("cohorts", {cohorts=cohorts})
    self:SendSnapshot("commanders", {commanders=commanders})
    return {groups=#groups, units=#units, statics=#statics, airbases=#airbases, zones=#zones, territories=#territories, opszones=#opszones, opsgroups=#opsgroups, auftraege=#auftraege, legions=#legions, cohorts=#cohorts, commanders=#commanders}
  end)
end

function MOOSE_BRIDGE:_ReadLine()
  if not self.Socket then return nil, "no_socket" end
  local line, err, partial = self.Socket:receive("*l")
  if line then return line, nil end
  if err == "timeout" then return nil, nil end
  if partial and #partial > 0 then return partial, nil end
  return nil, err
end

function MOOSE_BRIDGE:_HandleCommand(line)
  local ok, command = pcall(function() return json.decode(line) end)
  if not ok or type(command) ~= "table" then self:_Log("Invalid command: " .. safe_tostring(command)); return end
  local handler = self.CommandHandlers[command.action]
  if not handler then self:SendAck(command, false, nil, "Unknown action: " .. safe_tostring(command.action)); return end
  local ok_handler, result = pcall(function() return handler(command) end)
  if ok_handler then self:SendAck(command, true, result, nil) else self:SendAck(command, false, nil, safe_tostring(result)) end
end

function MOOSE_BRIDGE:_FlushOutQueue()
  if not self.Socket or #self.OutQueue == 0 then return end
  while #self.OutQueue > 0 do
    local line = table.remove(self.OutQueue, 1)
    local ok, err = self.Socket:send(line .. "\n")
    if not ok then self:_Disconnect("send failed: " .. safe_tostring(err)); return end
  end
end

function MOOSE_BRIDGE:_Tick()
  if not self.Socket then self:_Connect() end
  if self.Socket then
    while true do
      local line, err = self:_ReadLine()
      if not line then break end
      self:_HandleCommand(line)
    end
    self:_FlushOutQueue()
  end
  local now = mission_time() or 0
  if now - self.LastHeartbeat >= self.HeartbeatInterval then
    self.LastHeartbeat = now
    self:SendHeartbeat()
  end
end
