--- **Core** - Manages several databases containing templates, mission objects, and mission information.
--
-- ===
--
-- ## Features:
--
--   * During mission startup, scan the mission environment, and create / instantiate intelligently the different objects as defined within the mission.
--   * Manage database of DCS Group templates (as modelled using the mission editor).
--     - Group templates.
--     - Unit templates.
--     - Statics templates.
--   * Manage database of @{Wrapper.Group#GROUP} objects alive in the mission.
--   * Manage database of @{Wrapper.Unit#UNIT} objects alive in the mission.
--   * Manage database of @{Wrapper.Static#STATIC} objects alive in the mission.
--   * Manage database of players.
--   * Manage database of client slots defined using the mission editor.
--   * Manage database of airbases on the map, and from FARPs and ships as defined using the mission editor.
--   * Manage database of countries.
--   * Manage database of zone names.
--   * Manage database of hits to units and statics.
--   * Manage database of destroys of units and statics.
--   * Manage database of @{Core.Zone#ZONE_BASE} objects.
--
-- ===
--
-- ### Author: **FlightControl**
-- ### Contributions: **funkyfranky**
--
-- ===
--
-- @module Core.Database
-- @image Core_Database.JPG

--- @type DATABASE
-- @field #string ClassName Name of the class.
-- @field #table Templates Templates: Units, Groups, Statics, ClientsByName, ClientsByID.
-- @field #table CLIENTS Clients.
-- @extends Core.Base#BASE

--- Contains collections of wrapper objects defined within MOOSE that reflect objects within the simulator.
--
-- Mission designers can use the DATABASE class to refer to:
--
--  * STATICS
--  * UNITS
--  * GROUPS
--  * CLIENTS
--  * AIRBASES
--  * PLAYERSJOINED
--  * PLAYERS
--  * CARGOS
--
-- On top, for internal MOOSE administration purposes, the DATABASE administers the Unit and Group TEMPLATES as defined within the Mission Editor.
--
-- The singleton object **_DATABASE** is automatically created by MOOSE, that administers all objects within the mission.
-- Moose refers to **_DATABASE** within the framework extensively, but you can also refer to the _DATABASE object within your missions if required.
--
-- @field #DATABASE
DATABASE = {
  ClassName = "DATABASE",
  Templates = {
    Units = {},
    Groups = {},
    Statics = {},
    ClientsByName = {},
    ClientsByID = {},
  },
  UNITS = {},
  UNITS_Index = {},
  STATICS = {},
  GROUPS = {},
  PLAYERS = {},
  PLAYERSJOINED = {},
  PLAYERUNITS = {},
  CLIENTS = {},
  CARGOS = {},
  AIRBASES = {},
  COUNTRY_ID = {},
  COUNTRY_NAME = {},
  NavPoints = {},
  PLAYERSETTINGS = {},
  ZONENAMES = {},
  HITS = {},
  DESTROYS = {},
  ZONES = {},
  ZONES_GOAL = {},
  WAREHOUSES = {},
  FLIGHTGROUPS = {},
  FLIGHTCONTROLS = {},
}

local _DATABASECoalition = {
  [1] = "Red",
  [2] = "Blue",
  [3] = "Neutral",
}

local _DATABASECategory = {
  ["plane"] = Unit.Category.AIRPLANE,
  ["helicopter"] = Unit.Category.HELICOPTER,
  ["vehicle"] = Unit.Category.GROUND_UNIT,
  ["ship"] = Unit.Category.SHIP,
  ["static"] = Unit.Category.STRUCTURE,
}

--- Creates a new DATABASE object, building a set of units belonging to a coalitions, categories, countries, types or with defined prefix names.
-- @param #DATABASE self
-- @return #DATABASE
-- @usage
-- -- Define a new DATABASE Object. This DBObject will contain a reference to all Group and Unit Templates defined within the ME and the DCSRTE.
-- DBObject = DATABASE:New()
function DATABASE:New()

  -- Inherits from BASE
  local self = BASE:Inherit( self, BASE:New() ) -- #DATABASE

  self:SetEventPriority( 1 )

  self:HandleEvent( EVENTS.Birth, self._EventOnBirth )
  self:HandleEvent( EVENTS.Dead, self._EventOnDeadOrCrash )
  self:HandleEvent( EVENTS.Crash, self._EventOnDeadOrCrash )
  self:HandleEvent( EVENTS.RemoveUnit, self._EventOnDeadOrCrash )
  self:HandleEvent( EVENTS.Hit, self.AccountHits )
  self:HandleEvent( EVENTS.NewCargo )
  self:HandleEvent( EVENTS.DeleteCargo )
  self:HandleEvent( EVENTS.NewZone )
  self:HandleEvent( EVENTS.DeleteZone )
  -- self:HandleEvent( EVENTS.PlayerEnterUnit, self._EventOnPlayerEnterUnit ) -- This is not working anymore!, handling this through the birth event.
  self:HandleEvent( EVENTS.PlayerLeaveUnit, self._EventOnPlayerLeaveUnit )

  self:_RegisterTemplates()
  self:_RegisterGroupsAndUnits()
  self:_RegisterClients()
  self:_RegisterStatics()
  -- self:_RegisterAirbases()
  -- self:_RegisterPlayers()

  self.UNITS_Position = 0

  return self
end

--- Finds a Unit based on the Unit Name.
-- @param #DATABASE self
-- @param #string UnitName
-- @return Wrapper.Unit#UNIT The found Unit.
function DATABASE:FindUnit( UnitName )

  local UnitFound = self.UNITS[UnitName]
  return UnitFound
end

--- Adds a Unit based on the Unit Name in the DATABASE.
-- @param #DATABASE self
-- @param #string DCSUnitName Unit name.
-- @return Wrapper.Unit#UNIT The added unit.
function DATABASE:AddUnit( DCSUnitName )

  if not self.UNITS[DCSUnitName] then

    -- Debug info.
    self:T( { "Add UNIT:", DCSUnitName } )

    -- local UnitRegister = UNIT:Register( DCSUnitName )

    -- Register unit
    self.UNITS[DCSUnitName] = UNIT:Register( DCSUnitName )

    -- This is not used anywhere in MOOSE as far as I can see so I remove it until there comes an error somewhere.
    -- table.insert(self.UNITS_Index, DCSUnitName )
  end

  return self.UNITS[DCSUnitName]
end

--- Deletes a Unit from the DATABASE based on the Unit Name.
-- @param #DATABASE self
function DATABASE:DeleteUnit( DCSUnitName )

  self.UNITS[DCSUnitName] = nil
end

--- Adds a Static based on the Static Name in the DATABASE.
-- @param #DATABASE self
-- @param #string DCSStaticName Name of the static.
-- @return Wrapper.Static#STATIC The static object.
function DATABASE:AddStatic( DCSStaticName )

  if not self.STATICS[DCSStaticName] then
    self.STATICS[DCSStaticName] = STATIC:Register( DCSStaticName )
    return self.STATICS[DCSStaticName]
  end

  return nil
end

--- Deletes a Static from the DATABASE based on the Static Name.
-- @param #DATABASE self
function DATABASE:DeleteStatic( DCSStaticName )
  self.STATICS[DCSStaticName] = nil
end

--- Finds a STATIC based on the StaticName.
-- @param #DATABASE self
-- @param #string StaticName
-- @return Wrapper.Static#STATIC The found STATIC.
function DATABASE:FindStatic( StaticName )

  local StaticFound = self.STATICS[StaticName]
  return StaticFound
end

--- Finds a AIRBASE based on the AirbaseName.
-- @param #DATABASE self
-- @param #string AirbaseName
-- @return Wrapper.Airbase#AIRBASE The found AIRBASE.
function DATABASE:FindAirbase( AirbaseName )

  local AirbaseFound = self.AIRBASES[AirbaseName]
  return AirbaseFound
end

--- Adds a Airbase based on the Airbase Name in the DATABASE.
-- @param #DATABASE self
-- @param #string AirbaseName The name of the airbase.
-- @return Wrapper.Airbase#AIRBASE Airbase object.
function DATABASE:AddAirbase( AirbaseName )

  if not self.AIRBASES[AirbaseName] then
    self.AIRBASES[AirbaseName] = AIRBASE:Register( AirbaseName )
  end

  return self.AIRBASES[AirbaseName]
end

--- Deletes a Airbase from the DATABASE based on the Airbase Name.
-- @param #DATABASE self
-- @param #string AirbaseName The name of the airbase
function DATABASE:DeleteAirbase( AirbaseName )

  self.AIRBASES[AirbaseName] = nil
end

--- Finds an AIRBASE based on the AirbaseName.
-- @param #DATABASE self
-- @param #string AirbaseName
-- @return Wrapper.Airbase#AIRBASE The found AIRBASE.
function DATABASE:FindAirbase( AirbaseName )

  local AirbaseFound = self.AIRBASES[AirbaseName]
  return AirbaseFound
end

do -- Zones

  --- Finds a @{Zone} based on the zone name.
  -- @param #DATABASE self
  -- @param #string ZoneName The name of the zone.
  -- @return Core.Zone#ZONE_BASE The found ZONE.
  function DATABASE:FindZone( ZoneName )

    local ZoneFound = self.ZONES[ZoneName]
    return ZoneFound
  end

  --- Adds a @{Zone} based on the zone name in the DATABASE.
  -- @param #DATABASE self
  -- @param #string ZoneName The name of the zone.
  -- @param Core.Zone#ZONE_BASE Zone The zone.
  function DATABASE:AddZone( ZoneName, Zone )

    if not self.ZONES[ZoneName] then
      self.ZONES[ZoneName] = Zone
    end
  end

  --- Deletes a @{Zone} from the DATABASE based on the zone name.
  -- @param #DATABASE self
  -- @param #string ZoneName The name of the zone.
  function DATABASE:DeleteZone( ZoneName )

    self.ZONES[ZoneName] = nil
  end

  --- Private method that registers new ZONE_BASE derived objects within the DATABASE Object.
  -- @param #DATABASE self
  -- @return #DATABASE self
  function DATABASE:_RegisterZones()

    for ZoneID, ZoneData in pairs( env.mission.triggers.zones ) do
      local ZoneName = ZoneData.name

      -- Color
      local color = ZoneData.color or { 1, 0, 0, 0.15 }

      -- Create new Zone
      local Zone = nil -- Core.Zone#ZONE_BASE

      if ZoneData.type == 0 then

        ---
        -- Circular zone
        ---

        self:I( string.format( "Register ZONE: %s (Circular)", ZoneName ) )

        Zone = ZONE:New( ZoneName )

      else

        ---
        -- Quad-point zone
        ---

        self:I( string.format( "Register ZONE: %s (Polygon, Quad)", ZoneName ) )

        Zone = ZONE_POLYGON_BASE:New( ZoneName, ZoneData.verticies )

        -- for i,vec2 in pairs(ZoneData.verticies) do
        --  local coord=COORDINATE:NewFromVec2(vec2)
        --  coord:MarkToAll(string.format("%s Point %d", ZoneName, i))
        -- end

      end

      if Zone then

        -- Store color of zone.        
        Zone.Color = color

        -- Store in DB.
        self.ZONENAMES[ZoneName] = ZoneName

        -- Add zone.
        self:AddZone( ZoneName, Zone )

      end

    end

    -- Polygon zones defined by late activated groups.
    for ZoneGroupName, ZoneGroup in pairs( self.GROUPS ) do
      if ZoneGroupName:match( "#ZONE_POLYGON" ) then

        local ZoneName1 = ZoneGroupName:match( "(.*)#ZONE_POLYGON" )
        local ZoneName2 = ZoneGroupName:match( ".*#ZONE_POLYGON(.*)" )
        local ZoneName = ZoneName1 .. (ZoneName2 or "")

        -- Debug output
        self:I( string.format( "Register ZONE: %s (Polygon)", ZoneName ) )

        -- Create a new polygon zone.
        local Zone_Polygon = ZONE_POLYGON:New( ZoneName, ZoneGroup )

        -- Set color.
        Zone_Polygon:SetColor( { 1, 0, 0 }, 0.15 )

        -- Store name in DB.
        self.ZONENAMES[ZoneName] = ZoneName

        -- Add zone to DB.
        self:AddZone( ZoneName, Zone_Polygon )
      end
    end

  end

end -- zone

do -- Zone_Goal

  --- Finds a @{Zone} based on the zone name.
  -- @param #DATABASE self
  -- @param #string ZoneName The name of the zone.
  -- @return Core.Zone#ZONE_BASE The found ZONE.
  function DATABASE:FindZoneGoal( ZoneName )

    local ZoneFound = self.ZONES_GOAL[ZoneName]
    return ZoneFound
  end

  --- Adds a @{Zone} based on the zone name in the DATABASE.
  -- @param #DATABASE self
  -- @param #string ZoneName The name of the zone.
  -- @param Core.Zone#ZONE_BASE Zone The zone.
  function DATABASE:AddZoneGoal( ZoneName, Zone )

    if not self.ZONES_GOAL[ZoneName] then
      self.ZONES_GOAL[ZoneName] = Zone
    end
  end

  --- Deletes a @{Zone} from the DATABASE based on the zone name.
  -- @param #DATABASE self
  -- @param #string ZoneName The name of the zone.
  function DATABASE:DeleteZoneGoal( ZoneName )

    self.ZONES_GOAL[ZoneName] = nil
  end

end -- Zone_Goal
do -- cargo

  --- Adds a Cargo based on the Cargo Name in the DATABASE.
  -- @param #DATABASE self
  -- @param #string CargoName The name of the airbase
  function DATABASE:AddCargo( Cargo )

    if not self.CARGOS[Cargo.Name] then
      self.CARGOS[Cargo.Name] = Cargo
    end
  end

  --- Deletes a Cargo from the DATABASE based on the Cargo Name.
  -- @param #DATABASE self
  -- @param #string CargoName The name of the airbase
  function DATABASE:DeleteCargo( CargoName )

    self.CARGOS[CargoName] = nil
  end

  --- Finds an CARGO based on the CargoName.
  -- @param #DATABASE self
  -- @param #string CargoName
  -- @return Wrapper.Cargo#CARGO The found CARGO.
  function DATABASE:FindCargo( CargoName )

    local CargoFound = self.CARGOS[CargoName]
    return CargoFound
  end

  --- Checks if the Template name has a #CARGO tag.
  -- If yes, the group is a cargo.
  -- @param #DATABASE self
  -- @param #string TemplateName
  -- @return #boolean
  function DATABASE:IsCargo( TemplateName )

    TemplateName = env.getValueDictByKey( TemplateName )

    local Cargo = TemplateName:match( "#(CARGO)" )

    return Cargo and Cargo == "CARGO"
  end

  --- Private method that registers new Static Templates within the DATABASE Object.
  -- @param #DATABASE self
  -- @return #DATABASE self
  function DATABASE:_RegisterCargos()

    local Groups = UTILS.DeepCopy( self.GROUPS ) -- This is a very important statement. CARGO_GROUP:New creates a new _DATABASE.GROUP entry, which will confuse the loop. I searched 4 hours on this to find the bug!

    for CargoGroupName, CargoGroup in pairs( Groups ) do
      if self:IsCargo( CargoGroupName ) then
        local CargoInfo = CargoGroupName:match( "#CARGO(.*)" )
        local CargoParam = CargoInfo and CargoInfo:match( "%((.*)%)" )
        local CargoName1 = CargoGroupName:match( "(.*)#CARGO%(.*%)" )
        local CargoName2 = CargoGroupName:match( ".*#CARGO%(.*%)(.*)" )
        local CargoName = CargoName1 .. (CargoName2 or "")
        local Type = CargoParam and CargoParam:match( "T=([%a%d ]+),?" )
        local Name = CargoParam and CargoParam:match( "N=([%a%d]+),?" ) or CargoName
        local LoadRadius = CargoParam and tonumber( CargoParam:match( "RR=([%a%d]+),?" ) )
        local NearRadius = CargoParam and tonumber( CargoParam:match( "NR=([%a%d]+),?" ) )

        self:I( { "Register CargoGroup:", Type = Type, Name = Name, LoadRadius = LoadRadius, NearRadius = NearRadius } )
        CARGO_GROUP:New( CargoGroup, Type, Name, LoadRadius, NearRadius )
      end
    end

    for CargoStaticName, CargoStatic in pairs( self.STATICS ) do
      if self:IsCargo( CargoStaticName ) then
        local CargoInfo = CargoStaticName:match( "#CARGO(.*)" )
        local CargoParam = CargoInfo and CargoInfo:match( "%((.*)%)" )
        local CargoName = CargoStaticName:match( "(.*)#CARGO" )
        local Type = CargoParam and CargoParam:match( "T=([%a%d ]+),?" )
        local Category = CargoParam and CargoParam:match( "C=([%a%d ]+),?" )
        local Name = CargoParam and CargoParam:match( "N=([%a%d]+),?" ) or CargoName
        local LoadRadius = CargoParam and tonumber( CargoParam:match( "RR=([%a%d]+),?" ) )
        local NearRadius = CargoParam and tonumber( CargoParam:match( "NR=([%a%d]+),?" ) )

        if Category == "SLING" then
          self:I( { "Register CargoSlingload:", Type = Type, Name = Name, LoadRadius = LoadRadius, NearRadius = NearRadius } )
          CARGO_SLINGLOAD:New( CargoStatic, Type, Name, LoadRadius, NearRadius )
        else
          if Category == "CRATE" then
            self:I( { "Register CargoCrate:", Type = Type, Name = Name, LoadRadius = LoadRadius, NearRadius = NearRadius } )
            CARGO_CRATE:New( CargoStatic, Type, Name, LoadRadius, NearRadius )
          end
        end
      end
    end

  end

end -- cargo

--- Finds a CLIENT based on the ClientName.
-- @param #DATABASE self
-- @param #string ClientName
-- @return Wrapper.Client#CLIENT The found CLIENT.
function DATABASE:FindClient( ClientName )

  local ClientFound = self.CLIENTS[ClientName]
  return ClientFound
end

--- Adds a CLIENT based on the ClientName in the DATABASE.
-- @param #DATABASE self
-- @param #string ClientName Name of the Client unit.
-- @return Wrapper.Client#CLIENT The client object.
function DATABASE:AddClient( ClientName )

  if not self.CLIENTS[ClientName] then
    self.CLIENTS[ClientName] = CLIENT:Register( ClientName )
  end

  return self.CLIENTS[ClientName]
end

--- Finds a GROUP based on the GroupName.
-- @param #DATABASE self
-- @param #string GroupName
-- @return Wrapper.Group#GROUP The found GROUP.
function DATABASE:FindGroup( GroupName )

  local GroupFound = self.GROUPS[GroupName]
  return GroupFound
end

--- Adds a GROUP based on the GroupName in the DATABASE.
-- @param #DATABASE self
function DATABASE:AddGroup( GroupName )

  if not self.GROUPS[GroupName] then
    self:T( { "Add GROUP:", GroupName } )
    self.GROUPS[GroupName] = GROUP:Register( GroupName )
  end

  return self.GROUPS[GroupName]
end

--- Adds a player based on the Player Name in the DATABASE.
-- @param #DATABASE self
function DATABASE:AddPlayer( UnitName, PlayerName )

  if PlayerName then
    self:T( { "Add player for unit:", UnitName, PlayerName } )
    self.PLAYERS[PlayerName] = UnitName
    self.PLAYERUNITS[PlayerName] = self:FindUnit( UnitName )
    self.PLAYERSJOINED[PlayerName] = PlayerName
  end
end

--- Deletes a player from the DATABASE based on the Player Name.
-- @param #DATABASE self
function DATABASE:DeletePlayer( UnitName, PlayerName )

  if PlayerName then
    self:T( { "Clean player:", PlayerName } )
    self.PLAYERS[PlayerName] = nil
    self.PLAYERUNITS[PlayerName] = nil
  end
end

--- Get the player table from the DATABASE.
-- The player table contains all unit names with the key the name of the player (PlayerName).
-- @param #DATABASE self
-- @usage
--   local Players = _DATABASE:GetPlayers()
--   for PlayerName, UnitName in pairs( Players ) do
--     ..
--   end
function DATABASE:GetPlayers()
  return self.PLAYERS
end

--- Get the player table from the DATABASE, which contains all UNIT objects.
-- The player table contains all UNIT objects of the player with the key the name of the player (PlayerName).
-- @param #DATABASE self
-- @usage
--   local PlayerUnits = _DATABASE:GetPlayerUnits()
--   for PlayerName, PlayerUnit in pairs( PlayerUnits ) do
--     ..
--   end
function DATABASE:GetPlayerUnits()
  return self.PLAYERUNITS
end

--- Get the player table from the DATABASE which have joined in the mission historically.
-- The player table contains all UNIT objects with the key the name of the player (PlayerName).
-- @param #DATABASE self
-- @usage
--   local PlayersJoined = _DATABASE:GetPlayersJoined()
--   for PlayerName, PlayerUnit in pairs( PlayersJoined ) do
--     ..
--   end
function DATABASE:GetPlayersJoined()
  return self.PLAYERSJOINED
end

--- Instantiate new Groups within the DCSRTE.
-- This method expects EXACTLY the same structure as a structure within the ME, and needs 2 additional fields defined:
-- SpawnCountryID, SpawnCategoryID
-- This method is used by the SPAWN class.
-- @param #DATABASE self
-- @param #table SpawnTemplate Template of the group to spawn.
-- @return Wrapper.Group#GROUP Spawned group.
function DATABASE:Spawn( SpawnTemplate )
  self:F( SpawnTemplate.name )

  self:T( { SpawnTemplate.SpawnCountryID, SpawnTemplate.SpawnCategoryID } )

  -- Copy the spawn variables of the template in temporary storage, nullify, and restore the spawn variables.
  local SpawnCoalitionID = SpawnTemplate.CoalitionID
  local SpawnCountryID = SpawnTemplate.CountryID
  local SpawnCategoryID = SpawnTemplate.CategoryID

  -- Nullify
  SpawnTemplate.CoalitionID = nil
  SpawnTemplate.CountryID = nil
  SpawnTemplate.CategoryID = nil

  self:_RegisterGroupTemplate( SpawnTemplate, SpawnCoalitionID, SpawnCategoryID, SpawnCountryID )

  self:T3( SpawnTemplate )
  coalition.addGroup( SpawnCountryID, SpawnCategoryID, SpawnTemplate )

  -- Restore
  SpawnTemplate.CoalitionID = SpawnCoalitionID
  SpawnTemplate.CountryID = SpawnCountryID
  SpawnTemplate.CategoryID = SpawnCategoryID

  -- Ensure that for the spawned group and its units, there are GROUP and UNIT objects created in the DATABASE.
  local SpawnGroup = self:AddGroup( SpawnTemplate.name )
  for UnitID, UnitData in pairs( SpawnTemplate.units ) do
    self:AddUnit( UnitData.name )
  end

  return SpawnGroup
end

--- Set a status to a Group within the Database, this to check crossing events for example.
-- @param #DATABASE self
-- @param #string GroupName Group name.
-- @param #string Status Status.
function DATABASE:SetStatusGroup( GroupName, Status )
  self:F2( Status )

  self.Templates.Groups[GroupName].Status = Status
end

--- Get a status to a Group within the Database, this to check crossing events for example.
-- @param #DATABASE self
-- @param #string GroupName Group name.
-- @return #string Status or an empty string "".
function DATABASE:GetStatusGroup( GroupName )
  self:F2( GroupName )

  if self.Templates.Groups[GroupName] then
    return self.Templates.Groups[GroupName].Status
  else
    return ""
  end
end

--- Private method that registers new Group Templates within the DATABASE Object.
-- @param #DATABASE self
-- @param #table GroupTemplate
-- @param DCS#coalition.side CoalitionSide The coalition.side of the object.
-- @param DCS#Object.Category CategoryID The Object.category of the object.
-- @param DCS#country.id CountryID the country ID of the object.
-- @param #string GroupName (Optional) The name of the group. Default is `GroupTemplate.name`.
-- @return #DATABASE self
function DATABASE:_RegisterGroupTemplate( GroupTemplate, CoalitionSide, CategoryID, CountryID, GroupName )

  local GroupTemplateName = GroupName or env.getValueDictByKey( GroupTemplate.name )

  if not self.Templates.Groups[GroupTemplateName] then
    self.Templates.Groups[GroupTemplateName] = {}
    self.Templates.Groups[GroupTemplateName].Status = nil
  end

  -- Delete the spans from the route, it is not needed and takes memory.
  if GroupTemplate.route and GroupTemplate.route.spans then
    GroupTemplate.route.spans = nil
  end

  GroupTemplate.CategoryID = CategoryID
  GroupTemplate.CoalitionID = CoalitionSide
  GroupTemplate.CountryID = CountryID

  self.Templates.Groups[GroupTemplateName].GroupName = GroupTemplateName
  self.Templates.Groups[GroupTemplateName].Template = GroupTemplate
  self.Templates.Groups[GroupTemplateName].groupId = GroupTemplate.groupId
  self.Templates.Groups[GroupTemplateName].UnitCount = #GroupTemplate.units
  self.Templates.Groups[GroupTemplateName].Units = GroupTemplate.units
  self.Templates.Groups[GroupTemplateName].CategoryID = CategoryID
  self.Templates.Groups[GroupTemplateName].CoalitionID = CoalitionSide
  self.Templates.Groups[GroupTemplateName].CountryID = CountryID

  local UnitNames = {}

  for unit_num, UnitTemplate in pairs( GroupTemplate.units ) do

    UnitTemplate.name = env.getValueDictByKey( UnitTemplate.name )

    self.Templates.Units[UnitTemplate.name] = {}
    self.Templates.Units[UnitTemplate.name].UnitName = UnitTemplate.name
    self.Templates.Units[UnitTemplate.name].Template = UnitTemplate
    self.Templates.Units[UnitTemplate.name].GroupName = GroupTemplateName
    self.Templates.Units[UnitTemplate.name].GroupTemplate = GroupTemplate
    self.Templates.Units[UnitTemplate.name].GroupId = GroupTemplate.groupId
    self.Templates.Units[UnitTemplate.name].CategoryID = CategoryID
    self.Templates.Units[UnitTemplate.name].CoalitionID = CoalitionSide
    self.Templates.Units[UnitTemplate.name].CountryID = CountryID

    if UnitTemplate.skill and (UnitTemplate.skill == "Client" or UnitTemplate.skill == "Player") then
      self.Templates.ClientsByName[UnitTemplate.name] = UnitTemplate
      self.Templates.ClientsByName[UnitTemplate.name].CategoryID = CategoryID
      self.Templates.ClientsByName[UnitTemplate.name].CoalitionID = CoalitionSide
      self.Templates.ClientsByName[UnitTemplate.name].CountryID = CountryID
      self.Templates.ClientsByID[UnitTemplate.unitId] = UnitTemplate
    end

    UnitNames[#UnitNames + 1] = self.Templates.Units[UnitTemplate.name].UnitName
  end

  -- Debug info.
  self:T( { Group = self.Templates.Groups[GroupTemplateName].GroupName,
            Coalition = self.Templates.Groups[GroupTemplateName].CoalitionID,
            Category = self.Templates.Groups[GroupTemplateName].CategoryID,
            Country = self.Templates.Groups[GroupTemplateName].CountryID,
            Units = UnitNames,
          } )
end

--- Get group template.
-- @param #DATABASE self
-- @param #string GroupName Group name.
-- @return #table Group template table.
function DATABASE:GetGroupTemplate( GroupName )
  local GroupTemplate = self.Templates.Groups[GroupName].Template
  GroupTemplate.SpawnCoalitionID = self.Templates.Groups[GroupName].CoalitionID
  GroupTemplate.SpawnCategoryID = self.Templates.Groups[GroupName].CategoryID
  GroupTemplate.SpawnCountryID = self.Templates.Groups[GroupName].CountryID
  return GroupTemplate
end

--- Private method that registers new Static Templates within the DATABASE Object.
-- @param #DATABASE self
-- @param #table StaticTemplate Template table.
-- @param #number CoalitionID Coalition ID.
-- @param #number CategoryID Category ID.
-- @param #number CountryID Country ID.
-- @return #DATABASE self
function DATABASE:_RegisterStaticTemplate( StaticTemplate, CoalitionID, CategoryID, CountryID )

  local StaticTemplate = UTILS.DeepCopy( StaticTemplate )

  local StaticTemplateName = env.getValueDictByKey( StaticTemplate.name )

  self.Templates.Statics[StaticTemplateName] = self.Templates.Statics[StaticTemplateName] or {}

  StaticTemplate.CategoryID = CategoryID
  StaticTemplate.CoalitionID = CoalitionID
  StaticTemplate.CountryID = CountryID

  self.Templates.Statics[StaticTemplateName].StaticName = StaticTemplateName
  self.Templates.Statics[StaticTemplateName].GroupTemplate = StaticTemplate
  self.Templates.Statics[StaticTemplateName].UnitTemplate = StaticTemplate.units[1]
  self.Templates.Statics[StaticTemplateName].CategoryID = CategoryID
  self.Templates.Statics[StaticTemplateName].CoalitionID = CoalitionID
  self.Templates.Statics[StaticTemplateName].CountryID = CountryID

  -- Debug info.
  self:T( { Static = self.Templates.Statics[StaticTemplateName].StaticName,
            Coalition = self.Templates.Statics[StaticTemplateName].CoalitionID,
            Category = self.Templates.Statics[StaticTemplateName].CategoryID,
            Country = self.Templates.Statics[StaticTemplateName].CountryID,
          } )

  self:AddStatic( StaticTemplateName )

  return self
end

--- Get static group template.
-- @param #DATABASE self
-- @param #string StaticName Name of the static.
-- @return #table Static template table.
function DATABASE:GetStaticGroupTemplate( StaticName )
  if self.Templates.Statics[StaticName] then
    local StaticTemplate = self.Templates.Statics[StaticName].GroupTemplate
    return StaticTemplate, self.Templates.Statics[StaticName].CoalitionID, self.Templates.Statics[StaticName].CategoryID, self.Templates.Statics[StaticName].CountryID
  else
    self:E( "ERROR: Static group template does NOT exist for static " .. tostring( StaticName ) )
    return nil
  end
end

--- Get static unit template.
-- @param #DATABASE self
-- @param #string StaticName Name of the static.
-- @return #table Static template table.
function DATABASE:GetStaticUnitTemplate( StaticName )
  if self.Templates.Statics[StaticName] then
    local UnitTemplate = self.Templates.Statics[StaticName].UnitTemplate
    return UnitTemplate, self.Templates.Statics[StaticName].CoalitionID, self.Templates.Statics[StaticName].CategoryID, self.Templates.Statics[StaticName].CountryID
  else
    self:E( "ERROR: Static unit template does NOT exist for static " .. tostring( StaticName ) )
    return nil
  end
end

--- Get group name from unit name.
-- @param #DATABASE self
-- @param #string UnitName Name of the unit.
-- @return #string Group name.
function DATABASE:GetGroupNameFromUnitName( UnitName )
  if self.Templates.Units[UnitName] then
    return self.Templates.Units[UnitName].GroupName
  else
    self:E( "ERROR: Unit template does not exist for unit " .. tostring( UnitName ) )
    return nil
  end
end

--- Get group template from unit name.
-- @param #DATABASE self
-- @param #string UnitName Name of the unit.
-- @return #table Group template.
function DATABASE:GetGroupTemplateFromUnitName( UnitName )
  if self.Templates.Units[UnitName] then
    return self.Templates.Units[UnitName].GroupTemplate
  else
    self:E( "ERROR: Unit template does not exist for unit " .. tostring( UnitName ) )
    return nil
  end
end

--- Get coalition ID from client name.
-- @param #DATABASE self
-- @param #string ClientName Name of the Client.
-- @return #number Coalition ID.
function DATABASE:GetCoalitionFromClientTemplate( ClientName )
  return self.Templates.ClientsByName[ClientName].CoalitionID
end

--- Get category ID from client name.
-- @param #DATABASE self
-- @param #string ClientName Name of the Client.
-- @return #number Category ID.
function DATABASE:GetCategoryFromClientTemplate( ClientName )
  return self.Templates.ClientsByName[ClientName].CategoryID
end

--- Get country ID from client name.
-- @param #DATABASE self
-- @param #string ClientName Name of the Client.
-- @return #number Country ID.
function DATABASE:GetCountryFromClientTemplate( ClientName )
  return self.Templates.ClientsByName[ClientName].CountryID
end

--- Airbase

--- Get coalition ID from airbase name.
-- @param #DATABASE self
-- @param #string AirbaseName Name of the airbase.
-- @return #number Coalition ID.
function DATABASE:GetCoalitionFromAirbase( AirbaseName )
  return self.AIRBASES[AirbaseName]:GetCoalition()
end

--- Get category from airbase name.
-- @param #DATABASE self
-- @param #string AirbaseName Name of the airbase.
-- @return #number Category.
function DATABASE:GetCategoryFromAirbase( AirbaseName )
  return self.AIRBASES[AirbaseName]:GetCategory()
end

--- Private method that registers all alive players in the mission.
-- @param #DATABASE self
-- @return #DATABASE self
function DATABASE:_RegisterPlayers()

  local CoalitionsData = { AlivePlayersRed = coalition.getPlayers( coalition.side.RED ), AlivePlayersBlue = coalition.getPlayers( coalition.side.BLUE ), AlivePlayersNeutral = coalition.getPlayers( coalition.side.NEUTRAL ) }
  for CoalitionId, CoalitionData in pairs( CoalitionsData ) do
    for UnitId, UnitData in pairs( CoalitionData ) do
      self:T3( { "UnitData:", UnitData } )
      if UnitData and UnitData:isExist() then
        local UnitName = UnitData:getName()
        local PlayerName = UnitData:getPlayerName()
        if not self.PLAYERS[PlayerName] then
          self:I( { "Add player for unit:", UnitName, PlayerName } )
          self:AddPlayer( UnitName, PlayerName )
        end
      end
    end
  end

  return self
end

--- Private method that registers all Groups and Units within the mission.
-- @param #DATABASE self
-- @return #DATABASE self
function DATABASE:_RegisterGroupsAndUnits()

  local CoalitionsData = { GroupsRed = coalition.getGroups( coalition.side.RED ), GroupsBlue = coalition.getGroups( coalition.side.BLUE ), GroupsNeutral = coalition.getGroups( coalition.side.NEUTRAL ) }

  for CoalitionId, CoalitionData in pairs( CoalitionsData ) do

    for DCSGroupId, DCSGroup in pairs( CoalitionData ) do

      if DCSGroup:isExist() then

        -- Group name.
        local DCSGroupName = DCSGroup:getName()

        -- Add group.
        self:I( string.format( "Register Group: %s", tostring( DCSGroupName ) ) )
        self:AddGroup( DCSGroupName )

        -- Loop over units in group.
        for DCSUnitId, DCSUnit in pairs( DCSGroup:getUnits() ) do

          -- Get unit name.
          local DCSUnitName = DCSUnit:getName()

          -- Add unit.
          self:I( string.format( "Register Unit: %s", tostring( DCSUnitName ) ) )
          self:AddUnit( DCSUnitName )

        end
      else
        self:E( { "Group does not exist: ", DCSGroup } )
      end

    end
  end

  return self
end

--- Private method that registers all Units of skill Client or Player within the mission.
-- @param #DATABASE self
-- @return #DATABASE self
function DATABASE:_RegisterClients()

  for ClientName, ClientTemplate in pairs( self.Templates.ClientsByName ) do
    self:I( string.format( "Register Client: %s", tostring( ClientName ) ) )
    self:AddClient( ClientName )
  end

  return self
end

--- Private method that registers all Statics within the mission.
-- @param #DATABASE self
function DATABASE:_RegisterStatics()

  local CoalitionsData = { GroupsRed = coalition.getStaticObjects( coalition.side.RED ), GroupsBlue = coalition.getStaticObjects( coalition.side.BLUE ), GroupsNeutral = coalition.getStaticObjects( coalition.side.NEUTRAL ) }

  for CoalitionId, CoalitionData in pairs( CoalitionsData ) do
    for DCSStaticId, DCSStatic in pairs( CoalitionData ) do

      if DCSStatic:isExist() then
        local DCSStaticName = DCSStatic:getName()

        self:I( string.format( "Register Static: %s", tostring( DCSStaticName ) ) )
        self:AddStatic( DCSStaticName )
      else
        self:E( { "Static does not exist: ", DCSStatic } )
      end
    end
  end

  return self
end

--- Register all world airbases.
-- @param #DATABASE self
-- @return #DATABASE self
function DATABASE:_RegisterAirbases()

  for DCSAirbaseId, DCSAirbase in pairs( world.getAirbases() ) do

    -- Get the airbase name.
    local DCSAirbaseName = DCSAirbase:getName()

    -- This gave the incorrect value to be inserted into the airdromeID for DCS 2.5.6. Is fixed now.
    local airbaseID = DCSAirbase:getID()

    -- Add and register airbase.
    local airbase = self:AddAirbase( DCSAirbaseName )

    -- Unique ID.
    local airbaseUID = airbase:GetID( true )

    -- Debug output.
    local text = string.format( "Register %s: %s (ID=%d UID=%d), parking=%d [", AIRBASE.CategoryName[airbase.category], tostring( DCSAirbaseName ), airbaseID, airbaseUID, airbase.NparkingTotal )
    for _, terminalType in pairs( AIRBASE.TerminalType ) do
      if airbase.NparkingTerminal and airbase.NparkingTerminal[terminalType] then
        text = text .. string.format( "%d=%d ", terminalType, airbase.NparkingTerminal[terminalType] )
      end
    end
    text = text .. "]"
    self:I( text )

    -- Check for DCS bug IDs.
    if airbaseID ~= airbase:GetID() then
      -- self:E("WARNING: :getID does NOT match :GetID!")
    end

  end

  return self
end

--- Events

--- Handles the OnBirth event for the alive units set.
-- @param #DATABASE self
-- @param Core.Event#EVENTDATA Event
function DATABASE:_EventOnBirth( Event )
  self:F( { Event } )

  if Event.IniDCSUnit then

    if Event.IniObjectCategory == 3 then

      self:AddStatic( Event.IniDCSUnitName )

    else

      if Event.IniObjectCategory == 1 then

        self:AddUnit( Event.IniDCSUnitName )
        self:AddGroup( Event.IniDCSGroupName )

        -- Add airbase if it was spawned later in the mission.
        local DCSAirbase = Airbase.getByName( Event.IniDCSUnitName )
        if DCSAirbase then
          self:I( string.format( "Adding airbase %s", tostring( Event.IniDCSUnitName ) ) )
          self:AddAirbase( Event.IniDCSUnitName )
        end

      end
    end

    if Event.IniObjectCategory == 1 then

      Event.IniUnit = self:FindUnit( Event.IniDCSUnitName )
      Event.IniGroup = self:FindGroup( Event.IniDCSGroupName )

      -- Client
      local client = self.CLIENTS[Event.IniDCSUnitName] -- Wrapper.Client#CLIENT

      if client then
        -- TODO: create event ClientAlive
      end

      -- Get player name.  
      local PlayerName = Event.IniUnit:GetPlayerName()

      if PlayerName then

        -- Debug info.
        self:I( string.format( "Player '%s' joint unit '%s' of group '%s'", tostring( PlayerName ), tostring( Event.IniDCSUnitName ), tostring( Event.IniDCSGroupName ) ) )

        -- Add client in case it does not exist already.
        if not client then
          client = self:AddClient( Event.IniDCSUnitName )
        end

        -- Add player.
        client:AddPlayer( PlayerName )

        -- Add player.
        if not self.PLAYERS[PlayerName] then
          self:AddPlayer( Event.IniUnitName, PlayerName )
        end

        -- Player settings.
        local Settings = SETTINGS:Set( PlayerName )
        Settings:SetPlayerMenu( Event.IniUnit )

        -- Create an event.
        self:CreateEventPlayerEnterAircraft( Event.IniUnit )

      end

    end

  end

end

--- Handles the OnDead or OnCrash event for alive units set.
-- @param #DATABASE self
-- @param Core.Event#EVENTDATA Event
function DATABASE:_EventOnDeadOrCrash( Event )

  if Event.IniDCSUnit then

    local name = Event.IniDCSUnitName

    if Event.IniObjectCategory == 3 then

      ---
      -- STATICS
      ---

      if self.STATICS[Event.IniDCSUnitName] then
        self:DeleteStatic( Event.IniDCSUnitName )
      end

    else

      if Event.IniObjectCategory == 1 then

        ---
        -- UNITS
        ---

        -- Delete unit.
        if self.UNITS[Event.IniDCSUnitName] then
          self:DeleteUnit( Event.IniDCSUnitName )
        end

        -- Remove client players.
        local client = self.CLIENTS[name] -- Wrapper.Client#CLIENT

        if client then
          client:RemovePlayers()
        end

      end
    end

    -- Add airbase if it was spawned later in the mission.
    local airbase = self.AIRBASES[Event.IniDCSUnitName] -- Wrapper.Airbase#AIRBASE
    if airbase and (airbase:IsHelipad() or airbase:IsShip()) then
      self:DeleteAirbase( Event.IniDCSUnitName )
    end

  end

  -- Account destroys.
  self:AccountDestroys( Event )
end

--- Handles the OnPlayerEnterUnit event to fill the active players table (with the unit filter applied).
-- @param #DATABASE self
-- @param Core.Event#EVENTDATA Event
function DATABASE:_EventOnPlayerEnterUnit( Event )
  self:F2( { Event } )

  if Event.IniDCSUnit then
    if Event.IniObjectCategory == 1 then

      -- Add unit.
      self:AddUnit( Event.IniDCSUnitName )

      -- Ini unit.
      Event.IniUnit = self:FindUnit( Event.IniDCSUnitName )

      -- Add group.
      self:AddGroup( Event.IniDCSGroupName )

      -- Get player unit.
      local PlayerName = Event.IniDCSUnit:getPlayerName()

      if PlayerName then

        if not self.PLAYERS[PlayerName] then
          self:AddPlayer( Event.IniDCSUnitName, PlayerName )
        end

        local Settings = SETTINGS:Set( PlayerName )
        Settings:SetPlayerMenu( Event.IniUnit )

      else
        self:E( "ERROR: getPlayerName() returned nil for event PlayerEnterUnit" )
      end
    end
  end
end

--- Handles the OnPlayerLeaveUnit event to clean the active players table.
-- @param #DATABASE self
-- @param Core.Event#EVENTDATA Event
function DATABASE:_EventOnPlayerLeaveUnit( Event )
  self:F2( { Event } )

  if Event.IniUnit then

    if Event.IniObjectCategory == 1 then

      -- Try to get the player name. This can be buggy for multicrew aircraft!
      local PlayerName = Event.IniUnit:GetPlayerName()

      if PlayerName then -- and self.PLAYERS[PlayerName] then

        -- Debug info.
        self:I( string.format( "Player '%s' left unit %s", tostring( PlayerName ), tostring( Event.IniUnitName ) ) )

        -- Remove player menu.
        local Settings = SETTINGS:Set( PlayerName )
        Settings:RemovePlayerMenu( Event.IniUnit )

        -- Delete player.
        self:DeletePlayer( Event.IniUnit, PlayerName )

        -- Client stuff.
        local client = self.CLIENTS[Event.IniDCSUnitName] -- Wrapper.Client#CLIENT
        if client then
          client:RemovePlayer( PlayerName )
        end

      end
    end
  end
end

--- Iterators

--- Iterate the DATABASE and call an iterator function for the given set, providing the Object for each element within the set and optional parameters.
-- @param #DATABASE self
-- @param #function IteratorFunction The function that will be called when there is an alive player in the database.
-- @return #DATABASE self
function DATABASE:ForEach( IteratorFunction, FinalizeFunction, arg, Set )
  self:F2( arg )

  local function CoRoutine()
    local Count = 0
    for ObjectID, Object in pairs( Set ) do
      self:T2( Object )
      IteratorFunction( Object, unpack( arg ) )
      Count = Count + 1
      --        if Count % 100 == 0 then
      --          coroutine.yield( false )
      --        end
    end
    return true
  end

  --  local co = coroutine.create( CoRoutine )
  local co = CoRoutine

  local function Schedule()

    --    local status, res = coroutine.resume( co )
    local status, res = co()
    self:T3( { status, res } )

    if status == false then
      error( res )
    end
    if res == false then
      return true -- resume next time the loop
    end
    if FinalizeFunction then
      FinalizeFunction( unpack( arg ) )
    end
    return false
  end

  -- local Scheduler = SCHEDULER:New( self, Schedule, {}, 0.001, 0.001, 0 )
  Schedule()

  return self
end

--- Iterate the DATABASE and call an iterator function for each **alive** STATIC, providing the STATIC and optional parameters.
-- @param #DATABASE self
-- @param #function IteratorFunction The function that will be called for each object in the database. The function needs to accept a STATIC parameter.
-- @return #DATABASE self
function DATABASE:ForEachStatic( IteratorFunction, FinalizeFunction, ... ) -- R2.1
  self:F2( arg )

  self:ForEach( IteratorFunction, FinalizeFunction, arg, self.STATICS )

  return self
end

--- Iterate the DATABASE and call an iterator function for each **alive** UNIT, providing the UNIT and optional parameters.
-- @param #DATABASE self
-- @param #function IteratorFunction The function that will be called for each object in the database. The function needs to accept a UNIT parameter.
-- @return #DATABASE self
function DATABASE:ForEachUnit( IteratorFunction, FinalizeFunction, ... )
  self:F2( arg )

  self:ForEach( IteratorFunction, FinalizeFunction, arg, self.UNITS )

  return self
end

--- Iterate the DATABASE and call an iterator function for each **alive** GROUP, providing the GROUP and optional parameters.
-- @param #DATABASE self
-- @param #function IteratorFunction The function that will be called for each object in the database. The function needs to accept a GROUP parameter.
-- @return #DATABASE self
function DATABASE:ForEachGroup( IteratorFunction, FinalizeFunction, ... )
  self:F2( arg )

  self:ForEach( IteratorFunction, FinalizeFunction, arg, self.GROUPS )

  return self
end

--- Iterate the DATABASE and call an iterator function for each **ALIVE** player, providing the player name and optional parameters.
-- @param #DATABASE self
-- @param #function IteratorFunction The function that will be called for each object in the database. The function needs to accept the player name.
-- @return #DATABASE self
function DATABASE:ForEachPlayer( IteratorFunction, FinalizeFunction, ... )
  self:F2( arg )

  self:ForEach( IteratorFunction, FinalizeFunction, arg, self.PLAYERS )

  return self
end

--- Iterate the DATABASE and call an iterator function for each player who has joined the mission, providing the Unit of the player and optional parameters.
-- @param #DATABASE self
-- @param #function IteratorFunction The function that will be called for each object in the database. The function needs to accept a UNIT parameter.
-- @return #DATABASE self
function DATABASE:ForEachPlayerJoined( IteratorFunction, FinalizeFunction, ... )
  self:F2( arg )

  self:ForEach( IteratorFunction, FinalizeFunction, arg, self.PLAYERSJOINED )

  return self
end

--- Iterate the DATABASE and call an iterator function for each **ALIVE** player UNIT, providing the player UNIT and optional parameters.
-- @param #DATABASE self
-- @param #function IteratorFunction The function that will be called for each object in the database. The function needs to accept the player name.
-- @return #DATABASE self
function DATABASE:ForEachPlayerUnit( IteratorFunction, FinalizeFunction, ... )
  self:F2( arg )

  self:ForEach( IteratorFunction, FinalizeFunction, arg, self.PLAYERUNITS )

  return self
end

--- Iterate the DATABASE and call an iterator function for each CLIENT, providing the CLIENT to the function and optional parameters.
-- @param #DATABASE self
-- @param #function IteratorFunction The function that will be called object in the database. The function needs to accept a CLIENT parameter.
-- @return #DATABASE self
function DATABASE:ForEachClient( IteratorFunction, ... )
  self:F2( arg )

  self:ForEach( IteratorFunction, arg, self.CLIENTS )

  return self
end

--- Iterate the DATABASE and call an iterator function for each CARGO, providing the CARGO object to the function and optional parameters.
-- @param #DATABASE self
-- @param #function IteratorFunction The function that will be called for each object in the database. The function needs to accept a CLIENT parameter.
-- @return #DATABASE self
function DATABASE:ForEachCargo( IteratorFunction, ... )
  self:F2( arg )

  self:ForEach( IteratorFunction, arg, self.CARGOS )

  return self
end

--- Handles the OnEventNewCargo event.
-- @param #DATABASE self
-- @param Core.Event#EVENTDATA EventData
function DATABASE:OnEventNewCargo( EventData )
  self:F2( { EventData } )

  if EventData.Cargo then
    self:AddCargo( EventData.Cargo )
  end
end

--- Handles the OnEventDeleteCargo.
-- @param #DATABASE self
-- @param Core.Event#EVENTDATA EventData
function DATABASE:OnEventDeleteCargo( EventData )
  self:F2( { EventData } )

  if EventData.Cargo then
    self:DeleteCargo( EventData.Cargo.Name )
  end
end

--- Handles the OnEventNewZone event.
-- @param #DATABASE self
-- @param Core.Event#EVENTDATA EventData
function DATABASE:OnEventNewZone( EventData )
  self:F2( { EventData } )

  if EventData.Zone then
    self:AddZone( EventData.Zone.ZoneName, EventData.Zone )
  end
end

--- Handles the OnEventDeleteZone.
-- @param #DATABASE self
-- @param Core.Event#EVENTDATA EventData
function DATABASE:OnEventDeleteZone( EventData )
  self:F2( { EventData } )

  if EventData.Zone then
    self:DeleteZone( EventData.Zone.ZoneName )
  end
end

--- Gets the player settings
-- @param #DATABASE self
-- @param #string PlayerName
-- @return Core.Settings#SETTINGS
function DATABASE:GetPlayerSettings( PlayerName )
  self:F2( { PlayerName } )
  return self.PLAYERSETTINGS[PlayerName]
end

--- Sets the player settings
-- @param #DATABASE self
-- @param #string PlayerName
-- @param Core.Settings#SETTINGS Settings
-- @return Core.Settings#SETTINGS
function DATABASE:SetPlayerSettings( PlayerName, Settings )
  self:F2( { PlayerName, Settings } )
  self.PLAYERSETTINGS[PlayerName] = Settings
end

--- Add a flight group to the data base.
-- @param #DATABASE self
-- @param Ops.FlightGroup#FLIGHTGROUP flightgroup
function DATABASE:AddFlightGroup( flightgroup )
  self:I( { NewFlightGroup = flightgroup.groupname } )
  self.FLIGHTGROUPS[flightgroup.groupname] = flightgroup
end

--- Get a flight group from the data base.
-- @param #DATABASE self
-- @param #string groupname Group name of the flight group. Can also be passed as GROUP object.
-- @return Ops.FlightGroup#FLIGHTGROUP Flight group object.
function DATABASE:GetFlightGroup( groupname )

  -- Get group and group name.
  if type( groupname ) == "string" then
  else
    groupname = groupname:GetName()
  end

  return self.FLIGHTGROUPS[groupname]
end

--- Add a flight control to the data base.
-- @param #DATABASE self
-- @param Ops.FlightControl#FLIGHTCONTROL flightcontrol
function DATABASE:AddFlightControl( flightcontrol )
  self:F2( { flightcontrol } )
  self.FLIGHTCONTROLS[flightcontrol.airbasename] = flightcontrol
end

--- Get a flight control object from the data base.
-- @param #DATABASE self
-- @param #string airbasename Name of the associated airbase.
-- @return Ops.FlightControl#FLIGHTCONTROL The FLIGHTCONTROL object.s
function DATABASE:GetFlightControl( airbasename )
  return self.FLIGHTCONTROLS[airbasename]
end

--- @param #DATABASE self
function DATABASE:_RegisterTemplates()
  self:F2()

  self.Navpoints = {}
  self.UNITS = {}
  -- Build routines.db.units and self.Navpoints
  for CoalitionName, coa_data in pairs( env.mission.coalition ) do
    self:T( { CoalitionName = CoalitionName } )

    if (CoalitionName == 'red' or CoalitionName == 'blue' or CoalitionName == 'neutrals') and type( coa_data ) == 'table' then
      -- self.Units[coa_name] = {}

      local CoalitionSide = coalition.side[string.upper( CoalitionName )]
      if CoalitionName == "red" then
        CoalitionSide = coalition.side.RED
      elseif CoalitionName == "blue" then
        CoalitionSide = coalition.side.BLUE
      else
        CoalitionSide = coalition.side.NEUTRAL
      end

      -- build nav points DB
      self.Navpoints[CoalitionName] = {}
      if coa_data.nav_points then -- navpoints
        for nav_ind, nav_data in pairs( coa_data.nav_points ) do

          if type( nav_data ) == 'table' then
            self.Navpoints[CoalitionName][nav_ind] = routines.utils.deepCopy( nav_data )

            self.Navpoints[CoalitionName][nav_ind]['name'] = nav_data.callsignStr -- name is a little bit more self-explanatory.
            self.Navpoints[CoalitionName][nav_ind]['point'] = {} -- point is used by SSE, support it.
            self.Navpoints[CoalitionName][nav_ind]['point']['x'] = nav_data.x
            self.Navpoints[CoalitionName][nav_ind]['point']['y'] = 0
            self.Navpoints[CoalitionName][nav_ind]['point']['z'] = nav_data.y
          end
        end
      end

      -------------------------------------------------
      if coa_data.country then -- there is a country table
        for cntry_id, cntry_data in pairs( coa_data.country ) do

          local CountryName = string.upper( cntry_data.name )
          local CountryID = cntry_data.id

          self.COUNTRY_ID[CountryName] = CountryID
          self.COUNTRY_NAME[CountryID] = CountryName

          -- self.Units[coa_name][countryName] = {}
          -- self.Units[coa_name][countryName]["countryId"] = cntry_data.id

          if type( cntry_data ) == 'table' then -- just making sure

            for obj_type_name, obj_type_data in pairs( cntry_data ) do

              if obj_type_name == "helicopter" or obj_type_name == "ship" or obj_type_name == "plane" or obj_type_name == "vehicle" or obj_type_name == "static" then -- should be an unncessary check

                local CategoryName = obj_type_name

                if ((type( obj_type_data ) == 'table') and obj_type_data.group and (type( obj_type_data.group ) == 'table') and (#obj_type_data.group > 0)) then -- there's a group!

                  -- self.Units[coa_name][countryName][category] = {}

                  for group_num, Template in pairs( obj_type_data.group ) do

                    if obj_type_name ~= "static" and Template and Template.units and type( Template.units ) == 'table' then -- making sure again- this is a valid group

                      self:_RegisterGroupTemplate( Template, CoalitionSide, _DATABASECategory[string.lower( CategoryName )], CountryID )

                    else

                      self:_RegisterStaticTemplate( Template, CoalitionSide, _DATABASECategory[string.lower( CategoryName )], CountryID )

                    end -- if GroupTemplate and GroupTemplate.units then
                  end -- for group_num, GroupTemplate in pairs(obj_type_data.group) do
                end -- if ((type(obj_type_data) == 'table') and obj_type_data.group and (type(obj_type_data.group) == 'table') and (#obj_type_data.group > 0)) then
              end -- if obj_type_name == "helicopter" or obj_type_name == "ship" or obj_type_name == "plane" or obj_type_name == "vehicle" or obj_type_name == "static" then
            end -- for obj_type_name, obj_type_data in pairs(cntry_data) do
          end -- if type(cntry_data) == 'table' then
        end -- for cntry_id, cntry_data in pairs(coa_data.country) do
      end -- if coa_data.country then --there is a country table
    end -- if coa_name == 'red' or coa_name == 'blue' and type(coa_data) == 'table' then
  end -- for coa_name, coa_data in pairs(mission.coalition) do

  return self
end

--- Account the Hits of the Players.
-- @param #DATABASE self
-- @param Core.Event#EVENTDATA Event
function DATABASE:AccountHits( Event )
  self:F( { Event } )

  if Event.IniPlayerName ~= nil then -- It is a player that is hitting something
    self:T( "Hitting Something" )

    -- What is he hitting?
    if Event.TgtCategory then

      -- A target got hit
      self.HITS[Event.TgtUnitName] = self.HITS[Event.TgtUnitName] or {}
      local Hit = self.HITS[Event.TgtUnitName]

      Hit.Players = Hit.Players or {}
      Hit.Players[Event.IniPlayerName] = true
    end
  end

  -- It is a weapon initiated by a player, that is hitting something
  -- This seems to occur only with scenery and static objects.
  if Event.WeaponPlayerName ~= nil then
    self:T( "Hitting Scenery" )

    -- What is he hitting?
    if Event.TgtCategory then

      if Event.WeaponCoalition then -- A coalition object was hit, probably a static.
        -- A target got hit
        self.HITS[Event.TgtUnitName] = self.HITS[Event.TgtUnitName] or {}
        local Hit = self.HITS[Event.TgtUnitName]

        Hit.Players = Hit.Players or {}
        Hit.Players[Event.WeaponPlayerName] = true
      else -- A scenery object was hit.
      end
    end
  end
end

--- Account the destroys.
-- @param #DATABASE self
-- @param Core.Event#EVENTDATA Event
function DATABASE:AccountDestroys( Event )
  self:F( { Event } )

  local TargetUnit = nil
  local TargetGroup = nil
  local TargetUnitName = ""
  local TargetGroupName = ""
  local TargetPlayerName = ""
  local TargetCoalition = nil
  local TargetCategory = nil
  local TargetType = nil
  local TargetUnitCoalition = nil
  local TargetUnitCategory = nil
  local TargetUnitType = nil

  if Event.IniDCSUnit then

    TargetUnit = Event.IniUnit
    TargetUnitName = Event.IniDCSUnitName
    TargetGroup = Event.IniDCSGroup
    TargetGroupName = Event.IniDCSGroupName
    TargetPlayerName = Event.IniPlayerName

    TargetCoalition = Event.IniCoalition
    -- TargetCategory = TargetUnit:getCategory()
    -- TargetCategory = TargetUnit:getDesc().category  -- Workaround
    TargetCategory = Event.IniCategory
    TargetType = Event.IniTypeName

    TargetUnitType = TargetType

    self:T( { TargetUnitName, TargetGroupName, TargetPlayerName, TargetCoalition, TargetCategory, TargetType } )
  end

  local Destroyed = false

  -- What is the player destroying?
  if self.HITS[Event.IniUnitName] then -- Was there a hit for this unit for this player before registered???
    self.DESTROYS[Event.IniUnitName] = self.DESTROYS[Event.IniUnitName] or {}
    self.DESTROYS[Event.IniUnitName] = true
  end
end
