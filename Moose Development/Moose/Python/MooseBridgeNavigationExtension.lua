--- Player navigation and radio-menu support for MOOSE_BRIDGE.
--
-- Load after MooseBridgeDcsEventsExtension.lua and before constructing the bridge.

if not MOOSE_BRIDGE then error("Load MooseBridge.lua before MooseBridgeNavigationExtension.lua") end
if MOOSE_BRIDGE._NavigationExtensionLoaded then return end
MOOSE_BRIDGE._NavigationExtensionLoaded = true

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
    local terrain_elevation
    if land and type(land.getHeight) == "function" then
      local terrain_ok, terrain = pcall(land.getHeight, {x=x, y=z})
      if terrain_ok then terrain_elevation = tonumber(terrain) end
    end
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
      terrain_elevation_m=terrain_elevation,
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
end

--- Read-only preflight and ownership inspection, independent of occupied slots.
function MOOSE_BRIDGE:_NavigationRuntimeStatus()
  local config = self.PlayerTestMenuConfig
  local drawings = type(self._DrawDebugOverlay) == "function" and type(self._ClearDebugOverlay) == "function"
  return {api_version=1, instance_id=self.InstanceId,
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
      {"Navigation status", "status"}, {"Flight status", "flight_status"},
      {"Next waypoint", "waypoint_next"}, {"Previous waypoint", "waypoint_previous"}}
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
      and action ~= "waypoint_next" and action ~= "waypoint_previous"
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

