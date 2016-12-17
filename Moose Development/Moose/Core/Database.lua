--- This module contains the DATABASE class, managing the database of mission objects. 
-- 
-- ====
-- 
-- 1) @{Core.Database#DATABASE} class, extends @{Core.Base#BASE}
-- ===================================================
-- Mission designers can use the DATABASE class to refer to:
-- 
--  * UNITS
--  * GROUPS
--  * CLIENTS
--  * AIRPORTS
--  * PLAYERSJOINED
--  * PLAYERS
--  
-- On top, for internal MOOSE administration purposes, the DATBASE administers the Unit and Group TEMPLATES as defined within the Mission Editor.
-- 
-- Moose will automatically create one instance of the DATABASE class into the **global** object _DATABASE.
-- Moose refers to _DATABASE within the framework extensively, but you can also refer to the _DATABASE object within your missions if required.
-- 
-- 1.1) DATABASE iterators
-- -----------------------
-- You can iterate the database with the available iterator methods.
-- The iterator methods will walk the DATABASE set, and call for each element within the set a function that you provide.
-- The following iterator methods are currently available within the DATABASE:
-- 
--   * @{#DATABASE.ForEachUnit}: Calls a function for each @{UNIT} it finds within the DATABASE.
--   * @{#DATABASE.ForEachGroup}: Calls a function for each @{GROUP} it finds within the DATABASE.
--   * @{#DATABASE.ForEachPlayer}: Calls a function for each alive player it finds within the DATABASE.
--   * @{#DATABASE.ForEachPlayerJoined}: Calls a function for each joined player it finds within the DATABASE.
--   * @{#DATABASE.ForEachClient}: Calls a function for each @{CLIENT} it finds within the DATABASE.
--   * @{#DATABASE.ForEachClientAlive}: Calls a function for each alive @{CLIENT} it finds within the DATABASE.
-- 
-- ===
-- 
-- @module Database
-- @author FlightControl

--- DATABASE class
-- @type DATABASE
-- @extends Core.Base#BASE
DATABASE = {
  ClassName = "DATABASE",
  Templates = {
    Units = {},
    Groups = {},
    ClientsByName = {},
    ClientsByID = {},
  },
  UNITS = {},
  STATICS = {},
  GROUPS = {},
  PLAYERS = {},
  PLAYERSJOINED = {},
  CLIENTS = {},
  AIRBASES = {},
  NavPoints = {},
}

local _DATABASECoalition =
  {
    [1] = "Red",
    [2] = "Blue",
  }

local _DATABASECategory =
  {
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
  local self = BASE:Inherit( self, BASE:New() )
  
  _EVENTDISPATCHER:OnBirth( self._EventOnBirth, self )
  _EVENTDISPATCHER:OnDead( self._EventOnDeadOrCrash, self )
  _EVENTDISPATCHER:OnCrash( self._EventOnDeadOrCrash, self )
  
  
  -- Follow alive players and clients
  _EVENTDISPATCHER:OnPlayerEnterUnit( self._EventOnPlayerEnterUnit, self )
  _EVENTDISPATCHER:OnPlayerLeaveUnit( self._EventOnPlayerLeaveUnit, self )
  
  self:_RegisterTemplates()
  self:_RegisterGroupsAndUnits()
  self:_RegisterClients()
  self:_RegisterStatics()
  self:_RegisterPlayers()
  self:_RegisterAirbases()
  
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
function DATABASE:AddUnit( DCSUnitName )

  if not  self.UNITS[DCSUnitName] then
    local UnitRegister = UNIT:Register( DCSUnitName )
    self.UNITS[DCSUnitName] = UNIT:Register( DCSUnitName )
  end
  
  return self.UNITS[DCSUnitName]
end


--- Deletes a Unit from the DATABASE based on the Unit Name.
-- @param #DATABASE self
function DATABASE:DeleteUnit( DCSUnitName )

  --self.UNITS[DCSUnitName] = nil 
end

--- Adds a Static based on the Static Name in the DATABASE.
-- @param #DATABASE self
function DATABASE:AddStatic( DCSStaticName )

  if not self.STATICS[DCSStaticName] then
    self.STATICS[DCSStaticName] = STATIC:Register( DCSStaticName )
  end
end


--- Deletes a Static from the DATABASE based on the Static Name.
-- @param #DATABASE self
function DATABASE:DeleteStatic( DCSStaticName )

  --self.STATICS[DCSStaticName] = nil 
end

--- Finds a STATIC based on the StaticName.
-- @param #DATABASE self
-- @param #string StaticName
-- @return Wrapper.Static#STATIC The found STATIC.
function DATABASE:FindStatic( StaticName )

  local StaticFound = self.STATICS[StaticName]
  return StaticFound
end

--- Adds a Airbase based on the Airbase Name in the DATABASE.
-- @param #DATABASE self
function DATABASE:AddAirbase( DCSAirbaseName )

  if not self.AIRBASES[DCSAirbaseName] then
    self.AIRBASES[DCSAirbaseName] = AIRBASE:Register( DCSAirbaseName )
  end
end


--- Deletes a Airbase from the DATABASE based on the Airbase Name.
-- @param #DATABASE self
function DATABASE:DeleteAirbase( DCSAirbaseName )

  --self.AIRBASES[DCSAirbaseName] = nil 
end

--- Finds a AIRBASE based on the AirbaseName.
-- @param #DATABASE self
-- @param #string AirbaseName
-- @return Wrapper.Airbase#AIRBASE The found AIRBASE.
function DATABASE:FindAirbase( AirbaseName )

  local AirbaseFound = self.AIRBASES[AirbaseName]
  return AirbaseFound
end


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
    self.GROUPS[GroupName] = GROUP:Register( GroupName )
  end  
  
  return self.GROUPS[GroupName] 
end

--- Adds a player based on the Player Name in the DATABASE.
-- @param #DATABASE self
function DATABASE:AddPlayer( UnitName, PlayerName )

  if PlayerName then
    self:E( { "Add player for unit:", UnitName, PlayerName } )
    self.PLAYERS[PlayerName] = self:FindUnit( UnitName )
    self.PLAYERSJOINED[PlayerName] = PlayerName
  end
end

--- Deletes a player from the DATABASE based on the Player Name.
-- @param #DATABASE self
function DATABASE:DeletePlayer( PlayerName )

  if PlayerName then
    self:E( { "Clean player:", PlayerName } )
    self.PLAYERS[PlayerName] = nil
  end
end


--- Instantiate new Groups within the DCSRTE.
-- This method expects EXACTLY the same structure as a structure within the ME, and needs 2 additional fields defined:
-- SpawnCountryID, SpawnCategoryID
-- This method is used by the SPAWN class.
-- @param #DATABASE self
-- @param #table SpawnTemplate
-- @return #DATABASE self
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

  self:_RegisterTemplate( SpawnTemplate, SpawnCoalitionID, SpawnCategoryID, SpawnCountryID  )

  self:T3( SpawnTemplate )
  coalition.addGroup( SpawnCountryID, SpawnCategoryID, SpawnTemplate )

  -- Restore
  SpawnTemplate.CoalitionID = SpawnCoalitionID
  SpawnTemplate.CountryID = SpawnCountryID
  SpawnTemplate.CategoryID = SpawnCategoryID

  local SpawnGroup = self:AddGroup( SpawnTemplate.name )
  return SpawnGroup
end

--- Set a status to a Group within the Database, this to check crossing events for example.
function DATABASE:SetStatusGroup( GroupName, Status )
  self:F2( Status )

  self.Templates.Groups[GroupName].Status = Status
end

--- Get a status to a Group within the Database, this to check crossing events for example.
function DATABASE:GetStatusGroup( GroupName )
  self:F2( Status )

  if self.Templates.Groups[GroupName] then
    return self.Templates.Groups[GroupName].Status
  else
    return ""
  end
end

--- Private method that registers new Group Templates within the DATABASE Object.
-- @param #DATABASE self
-- @param #table GroupTemplate
-- @return #DATABASE self
function DATABASE:_RegisterTemplate( GroupTemplate, CoalitionID, CategoryID, CountryID )

  local GroupTemplateName = env.getValueDictByKey(GroupTemplate.name)
  
  local TraceTable = {}

  if not self.Templates.Groups[GroupTemplateName] then
    self.Templates.Groups[GroupTemplateName] = {}
    self.Templates.Groups[GroupTemplateName].Status = nil
  end
  
  -- Delete the spans from the route, it is not needed and takes memory.
  if GroupTemplate.route and GroupTemplate.route.spans then 
    GroupTemplate.route.spans = nil
  end
  
  GroupTemplate.CategoryID = CategoryID
  GroupTemplate.CoalitionID = CoalitionID
  GroupTemplate.CountryID = CountryID
  
  self.Templates.Groups[GroupTemplateName].GroupName = GroupTemplateName
  self.Templates.Groups[GroupTemplateName].Template = GroupTemplate
  self.Templates.Groups[GroupTemplateName].groupId = GroupTemplate.groupId
  self.Templates.Groups[GroupTemplateName].UnitCount = #GroupTemplate.units
  self.Templates.Groups[GroupTemplateName].Units = GroupTemplate.units
  self.Templates.Groups[GroupTemplateName].CategoryID = CategoryID
  self.Templates.Groups[GroupTemplateName].CoalitionID = CoalitionID
  self.Templates.Groups[GroupTemplateName].CountryID = CountryID

  
  TraceTable[#TraceTable+1] = "Group"
  TraceTable[#TraceTable+1] = self.Templates.Groups[GroupTemplateName].GroupName

  TraceTable[#TraceTable+1] = "Coalition"
  TraceTable[#TraceTable+1] = self.Templates.Groups[GroupTemplateName].CoalitionID
  TraceTable[#TraceTable+1] = "Category"
  TraceTable[#TraceTable+1] = self.Templates.Groups[GroupTemplateName].CategoryID
  TraceTable[#TraceTable+1] = "Country"
  TraceTable[#TraceTable+1] = self.Templates.Groups[GroupTemplateName].CountryID

  TraceTable[#TraceTable+1] = "Units"

  for unit_num, UnitTemplate in pairs( GroupTemplate.units ) do

    UnitTemplate.name = env.getValueDictByKey(UnitTemplate.name)
    
    self.Templates.Units[UnitTemplate.name] = {}
    self.Templates.Units[UnitTemplate.name].UnitName = UnitTemplate.name
    self.Templates.Units[UnitTemplate.name].Template = UnitTemplate
    self.Templates.Units[UnitTemplate.name].GroupName = GroupTemplateName
    self.Templates.Units[UnitTemplate.name].GroupTemplate = GroupTemplate
    self.Templates.Units[UnitTemplate.name].GroupId = GroupTemplate.groupId
    self.Templates.Units[UnitTemplate.name].CategoryID = CategoryID
    self.Templates.Units[UnitTemplate.name].CoalitionID = CoalitionID
    self.Templates.Units[UnitTemplate.name].CountryID = CountryID

    if UnitTemplate.skill and (UnitTemplate.skill == "Client" or UnitTemplate.skill == "Player") then
      self.Templates.ClientsByName[UnitTemplate.name] = UnitTemplate
      self.Templates.ClientsByName[UnitTemplate.name].CategoryID = CategoryID
      self.Templates.ClientsByName[UnitTemplate.name].CoalitionID = CoalitionID
      self.Templates.ClientsByName[UnitTemplate.name].CountryID = CountryID
      self.Templates.ClientsByID[UnitTemplate.unitId] = UnitTemplate
    end
    
    TraceTable[#TraceTable+1] = self.Templates.Units[UnitTemplate.name].UnitName 
  end

  self:E( TraceTable )
end

function DATABASE:GetGroupTemplate( GroupName )
  local GroupTemplate = self.Templates.Groups[GroupName].Template
  GroupTemplate.SpawnCoalitionID = self.Templates.Groups[GroupName].CoalitionID
  GroupTemplate.SpawnCategoryID = self.Templates.Groups[GroupName].CategoryID
  GroupTemplate.SpawnCountryID = self.Templates.Groups[GroupName].CountryID
  return GroupTemplate
end

function DATABASE:GetGroupNameFromUnitName( UnitName )
  return self.Templates.Units[UnitName].GroupName
end

function DATABASE:GetGroupTemplateFromUnitName( UnitName )
  return self.Templates.Units[UnitName].GroupTemplate
end

function DATABASE:GetCoalitionFromClientTemplate( ClientName )
  return self.Templates.ClientsByName[ClientName].CoalitionID
end

function DATABASE:GetCategoryFromClientTemplate( ClientName )
  return self.Templates.ClientsByName[ClientName].CategoryID
end

function DATABASE:GetCountryFromClientTemplate( ClientName )
  return self.Templates.ClientsByName[ClientName].CountryID
end

--- Airbase

function DATABASE:GetCoalitionFromAirbase( AirbaseName )
  return self.AIRBASES[AirbaseName]:GetCoalition()
end

function DATABASE:GetCategoryFromAirbase( AirbaseName )
  return self.AIRBASES[AirbaseName]:GetCategory()
end



--- Private method that registers all alive players in the mission.
-- @param #DATABASE self
-- @return #DATABASE self
function DATABASE:_RegisterPlayers()

  local CoalitionsData = { AlivePlayersRed = coalition.getPlayers( coalition.side.RED ), AlivePlayersBlue = coalition.getPlayers( coalition.side.BLUE ) }
  for CoalitionId, CoalitionData in pairs( CoalitionsData ) do
    for UnitId, UnitData in pairs( CoalitionData ) do
      self:T3( { "UnitData:", UnitData } )
      if UnitData and UnitData:isExist() then
        local UnitName = UnitData:getName()
        local PlayerName = UnitData:getPlayerName()
        if not self.PLAYERS[PlayerName] then
          self:E( { "Add player for unit:", UnitName, PlayerName } )
          self:AddPlayer( UnitName, PlayerName )
        end
      end
    end
  end
  
  return self
end


--- Private method that registers all Groups and Units within in the mission.
-- @param #DATABASE self
-- @return #DATABASE self
function DATABASE:_RegisterGroupsAndUnits()

  local CoalitionsData = { GroupsRed = coalition.getGroups( coalition.side.RED ), GroupsBlue = coalition.getGroups( coalition.side.BLUE ) }
  for CoalitionId, CoalitionData in pairs( CoalitionsData ) do
    for DCSGroupId, DCSGroup in pairs( CoalitionData ) do

      if DCSGroup:isExist() then
        local DCSGroupName = DCSGroup:getName()
  
        self:E( { "Register Group:", DCSGroupName } )
        self:AddGroup( DCSGroupName )

        for DCSUnitId, DCSUnit in pairs( DCSGroup:getUnits() ) do
  
          local DCSUnitName = DCSUnit:getName()
          self:E( { "Register Unit:", DCSUnitName } )
          self:AddUnit( DCSUnitName )
        end
      else
        self:E( { "Group does not exist: ",  DCSGroup } )
      end
      
    end
  end

  return self
end

--- Private method that registers all Units of skill Client or Player within in the mission.
-- @param #DATABASE self
-- @return #DATABASE self
function DATABASE:_RegisterClients()

  for ClientName, ClientTemplate in pairs( self.Templates.ClientsByName ) do
    self:E( { "Register Client:", ClientName } )
    self:AddClient( ClientName )
  end
  
  return self
end

--- @param #DATABASE self
function DATABASE:_RegisterStatics()

  local CoalitionsData = { GroupsRed = coalition.getStaticObjects( coalition.side.RED ), GroupsBlue = coalition.getStaticObjects( coalition.side.BLUE ) }
  for CoalitionId, CoalitionData in pairs( CoalitionsData ) do
    for DCSStaticId, DCSStatic in pairs( CoalitionData ) do

      if DCSStatic:isExist() then
        local DCSStaticName = DCSStatic:getName()
  
        self:E( { "Register Static:", DCSStaticName } )
        self:AddStatic( DCSStaticName )
      else
        self:E( { "Static does not exist: ",  DCSStatic } )
      end
    end
  end

  return self
end

--- @param #DATABASE self
function DATABASE:_RegisterAirbases()

  local CoalitionsData = { AirbasesRed = coalition.getAirbases( coalition.side.RED ), AirbasesBlue = coalition.getAirbases( coalition.side.BLUE ), AirbasesNeutral = coalition.getAirbases( coalition.side.NEUTRAL ) }
  for CoalitionId, CoalitionData in pairs( CoalitionsData ) do
    for DCSAirbaseId, DCSAirbase in pairs( CoalitionData ) do

      local DCSAirbaseName = DCSAirbase:getName()

      self:E( { "Register Airbase:", DCSAirbaseName } )
      self:AddAirbase( DCSAirbaseName )
    end
  end

  return self
end


--- Events

--- Handles the OnBirth event for the alive units set.
-- @param #DATABASE self
-- @param Core.Event#EVENTDATA Event
function DATABASE:_EventOnBirth( Event )
  self:F2( { Event } )

  if Event.IniDCSUnit then
    self:AddUnit( Event.IniDCSUnitName )
    self:AddGroup( Event.IniDCSGroupName )
    self:_EventOnPlayerEnterUnit( Event )
  end
end


--- Handles the OnDead or OnCrash event for alive units set.
-- @param #DATABASE self
-- @param Core.Event#EVENTDATA Event
function DATABASE:_EventOnDeadOrCrash( Event )
  self:F2( { Event } )

  if Event.IniDCSUnit then
    if self.UNITS[Event.IniDCSUnitName] then
      self:DeleteUnit( Event.IniDCSUnitName )
      -- add logic to correctly remove a group once all units are destroyed...
    end
  end
end


--- Handles the OnPlayerEnterUnit event to fill the active players table (with the unit filter applied).
-- @param #DATABASE self
-- @param Core.Event#EVENTDATA Event
function DATABASE:_EventOnPlayerEnterUnit( Event )
  self:F2( { Event } )

  if Event.IniUnit then
    local PlayerName = Event.IniUnit:GetPlayerName()
    if not self.PLAYERS[PlayerName] then
      self:AddPlayer( Event.IniUnitName, PlayerName )
    end
  end
end


--- Handles the OnPlayerLeaveUnit event to clean the active players table.
-- @param #DATABASE self
-- @param Core.Event#EVENTDATA Event
function DATABASE:_EventOnPlayerLeaveUnit( Event )
  self:F2( { Event } )

  if Event.IniUnit then
    local PlayerName = Event.IniUnit:GetPlayerName()
    if self.PLAYERS[PlayerName] then
      self:DeletePlayer( PlayerName )
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

  local Scheduler = SCHEDULER:New( self, Schedule, {}, 0.001, 0.001, 0 )
  
  return self
end


--- Iterate the DATABASE and call an iterator function for each **alive** UNIT, providing the UNIT and optional parameters.
-- @param #DATABASE self
-- @param #function IteratorFunction The function that will be called when there is an alive UNIT in the database. The function needs to accept a UNIT parameter.
-- @return #DATABASE self
function DATABASE:ForEachUnit( IteratorFunction, FinalizeFunction, ... )
  self:F2( arg )
  
  self:ForEach( IteratorFunction, FinalizeFunction, arg, self.UNITS )

  return self
end

--- Iterate the DATABASE and call an iterator function for each **alive** GROUP, providing the GROUP and optional parameters.
-- @param #DATABASE self
-- @param #function IteratorFunction The function that will be called when there is an alive GROUP in the database. The function needs to accept a GROUP parameter.
-- @return #DATABASE self
function DATABASE:ForEachGroup( IteratorFunction, ... )
  self:F2( arg )
  
  self:ForEach( IteratorFunction, arg, self.GROUPS )

  return self
end


--- Iterate the DATABASE and call an iterator function for each **ALIVE** player, providing the player name and optional parameters.
-- @param #DATABASE self
-- @param #function IteratorFunction The function that will be called when there is an player in the database. The function needs to accept the player name.
-- @return #DATABASE self
function DATABASE:ForEachPlayer( IteratorFunction, ... )
  self:F2( arg )
  
  self:ForEach( IteratorFunction, arg, self.PLAYERS )
  
  return self
end


--- Iterate the DATABASE and call an iterator function for each player who has joined the mission, providing the Unit of the player and optional parameters.
-- @param #DATABASE self
-- @param #function IteratorFunction The function that will be called when there is was a player in the database. The function needs to accept a UNIT parameter.
-- @return #DATABASE self
function DATABASE:ForEachPlayerJoined( IteratorFunction, ... )
  self:F2( arg )
  
  self:ForEach( IteratorFunction, arg, self.PLAYERSJOINED )
  
  return self
end

--- Iterate the DATABASE and call an iterator function for each CLIENT, providing the CLIENT to the function and optional parameters.
-- @param #DATABASE self
-- @param #function IteratorFunction The function that will be called when there is an alive player in the database. The function needs to accept a CLIENT parameter.
-- @return #DATABASE self
function DATABASE:ForEachClient( IteratorFunction, ... )
  self:F2( arg )
  
  self:ForEach( IteratorFunction, arg, self.CLIENTS )

  return self
end


function DATABASE:_RegisterTemplates()
  self:F2()

  self.Navpoints = {}
  self.UNITS = {}
  --Build routines.db.units and self.Navpoints
  for CoalitionName, coa_data in pairs(env.mission.coalition) do

    if (CoalitionName == 'red' or CoalitionName == 'blue') and type(coa_data) == 'table' then
      --self.Units[coa_name] = {}

      ----------------------------------------------
      -- build nav points DB
      self.Navpoints[CoalitionName] = {}
      if coa_data.nav_points then --navpoints
        for nav_ind, nav_data in pairs(coa_data.nav_points) do

          if type(nav_data) == 'table' then
            self.Navpoints[CoalitionName][nav_ind] = routines.utils.deepCopy(nav_data)

            self.Navpoints[CoalitionName][nav_ind]['name'] = nav_data.callsignStr  -- name is a little bit more self-explanatory.
            self.Navpoints[CoalitionName][nav_ind]['point'] = {}  -- point is used by SSE, support it.
            self.Navpoints[CoalitionName][nav_ind]['point']['x'] = nav_data.x
            self.Navpoints[CoalitionName][nav_ind]['point']['y'] = 0
            self.Navpoints[CoalitionName][nav_ind]['point']['z'] = nav_data.y
          end
      end
      end
      -------------------------------------------------
      if coa_data.country then --there is a country table
        for cntry_id, cntry_data in pairs(coa_data.country) do

          local CountryName = string.upper(cntry_data.name)
          --self.Units[coa_name][countryName] = {}
          --self.Units[coa_name][countryName]["countryId"] = cntry_data.id

          if type(cntry_data) == 'table' then  --just making sure

            for obj_type_name, obj_type_data in pairs(cntry_data) do

              if obj_type_name == "helicopter" or obj_type_name == "ship" or obj_type_name == "plane" or obj_type_name == "vehicle" or obj_type_name == "static" then --should be an unncessary check

                local CategoryName = obj_type_name

                if ((type(obj_type_data) == 'table') and obj_type_data.group and (type(obj_type_data.group) == 'table') and (#obj_type_data.group > 0)) then  --there's a group!

                  --self.Units[coa_name][countryName][category] = {}

                  for group_num, GroupTemplate in pairs(obj_type_data.group) do

                    if GroupTemplate and GroupTemplate.units and type(GroupTemplate.units) == 'table' then  --making sure again- this is a valid group
                      self:_RegisterTemplate( 
                        GroupTemplate, 
                        coalition.side[string.upper(CoalitionName)], 
                        _DATABASECategory[string.lower(CategoryName)], 
                        country.id[string.upper(CountryName)] 
                      )
                    end --if GroupTemplate and GroupTemplate.units then
                  end --for group_num, GroupTemplate in pairs(obj_type_data.group) do
                end --if ((type(obj_type_data) == 'table') and obj_type_data.group and (type(obj_type_data.group) == 'table') and (#obj_type_data.group > 0)) then
              end --if obj_type_name == "helicopter" or obj_type_name == "ship" or obj_type_name == "plane" or obj_type_name == "vehicle" or obj_type_name == "static" then
          end --for obj_type_name, obj_type_data in pairs(cntry_data) do
          end --if type(cntry_data) == 'table' then
      end --for cntry_id, cntry_data in pairs(coa_data.country) do
      end --if coa_data.country then --there is a country table
    end --if coa_name == 'red' or coa_name == 'blue' and type(coa_data) == 'table' then
  end --for coa_name, coa_data in pairs(mission.coalition) do

  return self
end




