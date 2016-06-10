--- Manage the mission database. 
-- 
-- @{#DATABASE} class
-- ==================
-- Mission designers can use the DATABASE class to refer to:
-- 
--  * UNITS
--  * GROUPS
--  * players
--  * alive players
--  * CLIENTS
--  * alive CLIENTS
--  
-- On top, for internal MOOSE administration purposes, the DATBASE administers the Unit and Gruop templates as defined within the Mission Editor.
-- 
-- Moose will automatically create one instance of the DATABASE class into the **global** object _DATABASE.
-- Moose refers to _DATABASE within the framework extensively, but you can also refer to the _DATABASE object within your missions if required.
-- 
-- DATABASE iterators:
-- ===================
-- You can iterate the database with the available iterator methods.
-- The iterator methods will walk the DATABASE set, and call for each element within the set a function that you provide.
-- The following iterator methods are currently available within the DATABASE:
-- 
--   * @{#DATABASE.ForEachUnit}: Calls a function for each @{UNIT} it finds within the DATABASE.
--   * @{#DATABASE.ForEachGroup}: Calls a function for each @{GROUP} it finds within the DATABASE.
--   * @{#DATABASE.ForEachPlayer}: Calls a function for each player it finds within the DATABASE.
--   * @{#DATABASE.ForEachPlayerAlive}: Calls a function for each alive player it finds within the DATABASE.
--   * @{#DATABASE.ForEachClient}: Calls a function for each @{CLIENT} it finds within the DATABASE.
--   * @{#DATABASE.ForEachClientAlive}: Calls a function for each alive @{CLIENT} it finds within the DATABASE.
--   
-- @module Database
-- @author FlightControl

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Menu" )
Include.File( "Group" )
Include.File( "Static" )
Include.File( "Unit" )
Include.File( "Event" )
Include.File( "Client" )
Include.File( "Scheduler" )


--- DATABASE class
-- @type DATABASE
-- @extends Base#BASE
DATABASE = {
  ClassName = "DATABASE",
  Templates = {
    Units = {},
    Groups = {},
    ClientsByName = {},
    ClientsByID = {},
  },
  DCSUnits = {},
  DCSGroups = {},
  DCSStatics = {},
  UNITS = {},
  STATICS = {},
  GROUPS = {},
  PLAYERS = {},
  PLAYERSALIVE = {},
  CLIENTS = {},
  CLIENTSALIVE = {},
  NavPoints = {},
}

local _DATABASECoalition =
  {
    [1] = "Red",
    [2] = "Blue",
  }

local _DATABASECategory =
  {
    [Unit.Category.AIRPLANE] = "Plane",
    [Unit.Category.HELICOPTER] = "Helicopter",
    [Unit.Category.GROUND_UNIT] = "Vehicle",
    [Unit.Category.SHIP] = "Ship",
    [Unit.Category.STRUCTURE] = "Structure",
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
  
  return self
end

--- Finds a Unit based on the Unit Name.
-- @param #DATABASE self
-- @param #string UnitName
-- @return Unit#UNIT The found Unit.
function DATABASE:FindUnit( UnitName )

  local UnitFound = self.UNITS[UnitName]
  return UnitFound
end


--- Adds a Unit based on the Unit Name in the DATABASE.
-- @param #DATABASE self
function DATABASE:AddUnit( DCSUnit, DCSUnitName )

  self.DCSUnits[DCSUnitName] = DCSUnit 
  self.UNITS[DCSUnitName] = UNIT:Register( DCSUnitName )
end


--- Deletes a Unit from the DATABASE based on the Unit Name.
-- @param #DATABASE self
function DATABASE:DeleteUnit( DCSUnitName )

  self.DCSUnits[DCSUnitName] = nil 
end

--- Adds a Static based on the Static Name in the DATABASE.
-- @param #DATABASE self
function DATABASE:AddStatic( DCSStatic, DCSStaticName )

  self.DCSStatics[DCSStaticName] = DCSStatic 
  self.STATICS[DCSStaticName] = STATIC:Register( DCSStaticName )
end


--- Deletes a Static from the DATABASE based on the Static Name.
-- @param #DATABASE self
function DATABASE:DeleteStatic( DCSStaticName )

  self.DCSStatics[DCSStaticName] = nil 
end

--- Finds a STATIC based on the StaticName.
-- @param #DATABASE self
-- @param #string StaticName
-- @return Static#STATIC The found STATIC.
function DATABASE:FindStatic( StaticName )

  local StaticFound = self.STATICS[StaticName]
  return StaticFound
end


--- Finds a CLIENT based on the ClientName.
-- @param #DATABASE self
-- @param #string ClientName
-- @return Client#CLIENT The found CLIENT.
function DATABASE:FindClient( ClientName )

  local ClientFound = self.CLIENTS[ClientName]
  return ClientFound
end


--- Adds a CLIENT based on the ClientName in the DATABASE.
-- @param #DATABASE self
function DATABASE:AddClient( ClientName )

  self.CLIENTS[ClientName] = CLIENT:Register( ClientName )
  self:E( self.CLIENTS[ClientName]:GetClassNameAndID() )
end


--- Finds a GROUP based on the GroupName.
-- @param #DATABASE self
-- @param #string GroupName
-- @return Group#GROUP The found GROUP.
function DATABASE:FindGroup( GroupName )

  local GroupFound = self.GROUPS[GroupName]
  return GroupFound
end


--- Adds a GROUP based on the GroupName in the DATABASE.
-- @param #DATABASE self
function DATABASE:AddGroup( DCSGroup, GroupName )

  self.DCSGroups[GroupName] = DCSGroup
  self.GROUPS[GroupName] = GROUP:Register( GroupName )
end

--- Adds a player based on the Player Name in the DATABASE.
-- @param #DATABASE self
function DATABASE:AddPlayer( UnitName, PlayerName )

  if PlayerName then
    self:E( { "Add player for unit:", UnitName, PlayerName } )
    self.PLAYERS[PlayerName] = PlayerName
    self.PLAYERSALIVE[PlayerName] = PlayerName
    self.CLIENTSALIVE[PlayerName] = self:FindClient( UnitName )
  end
end

--- Deletes a player from the DATABASE based on the Player Name.
-- @param #DATABASE self
function DATABASE:DeletePlayer( PlayerName )

  if PlayerName then
    self:E( { "Clean player:", PlayerName } )
    self.PLAYERSALIVE[PlayerName] = nil
    self.CLIENTSALIVE[PlayerName] = nil
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
  self:F2( SpawnTemplate.name )

  self:T2( { SpawnTemplate.SpawnCountryID, SpawnTemplate.SpawnCategoryID } )

  -- Copy the spawn variables of the template in temporary storage, nullify, and restore the spawn variables.
  local SpawnCoalitionID = SpawnTemplate.SpawnCoalitionID
  local SpawnCountryID = SpawnTemplate.SpawnCountryID
  local SpawnCategoryID = SpawnTemplate.SpawnCategoryID

  -- Nullify
  SpawnTemplate.SpawnCoalitionID = nil
  SpawnTemplate.SpawnCountryID = nil
  SpawnTemplate.SpawnCategoryID = nil

  self:_RegisterTemplate( SpawnTemplate )

  self:T3( SpawnTemplate )
  coalition.addGroup( SpawnCountryID, SpawnCategoryID, SpawnTemplate )

  -- Restore
  SpawnTemplate.SpawnCoalitionID = SpawnCoalitionID
  SpawnTemplate.SpawnCountryID = SpawnCountryID
  SpawnTemplate.SpawnCategoryID = SpawnCategoryID

  local SpawnGroup = GROUP:Register( SpawnTemplate.name )
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
function DATABASE:_RegisterTemplate( GroupTemplate )

  local GroupTemplateName = env.getValueDictByKey(GroupTemplate.name)

  if not self.Templates.Groups[GroupTemplateName] then
    self.Templates.Groups[GroupTemplateName] = {}
    self.Templates.Groups[GroupTemplateName].Status = nil
  end
  
  -- Delete the spans from the route, it is not needed and takes memory.
  if GroupTemplate.route and GroupTemplate.route.spans then 
    GroupTemplate.route.spans = nil
  end
  
  self.Templates.Groups[GroupTemplateName].GroupName = GroupTemplateName
  self.Templates.Groups[GroupTemplateName].Template = GroupTemplate
  self.Templates.Groups[GroupTemplateName].groupId = GroupTemplate.groupId
  self.Templates.Groups[GroupTemplateName].UnitCount = #GroupTemplate.units
  self.Templates.Groups[GroupTemplateName].Units = GroupTemplate.units

  self:T2( { "Group", self.Templates.Groups[GroupTemplateName].GroupName, self.Templates.Groups[GroupTemplateName].UnitCount } )

  for unit_num, UnitTemplate in pairs( GroupTemplate.units ) do

    local UnitTemplateName = env.getValueDictByKey(UnitTemplate.name)
    self.Templates.Units[UnitTemplateName] = {}
    self.Templates.Units[UnitTemplateName].UnitName = UnitTemplateName
    self.Templates.Units[UnitTemplateName].Template = UnitTemplate
    self.Templates.Units[UnitTemplateName].GroupName = GroupTemplateName
    self.Templates.Units[UnitTemplateName].GroupTemplate = GroupTemplate
    self.Templates.Units[UnitTemplateName].GroupId = GroupTemplate.groupId
    self:E( {"skill",UnitTemplate.skill})
    if UnitTemplate.skill and (UnitTemplate.skill == "Client" or UnitTemplate.skill == "Player") then
      self.Templates.ClientsByName[UnitTemplateName] = UnitTemplate
      self.Templates.ClientsByID[UnitTemplate.unitId] = UnitTemplate
    end
    self:E( { "Unit", self.Templates.Units[UnitTemplateName].UnitName } )
  end
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
  
        self:E( { "Register Group:", DCSGroup, DCSGroupName } )
        self:AddGroup( DCSGroup, DCSGroupName )

        for DCSUnitId, DCSUnit in pairs( DCSGroup:getUnits() ) do
  
          local DCSUnitName = DCSUnit:getName()
          self:E( { "Register Unit:", DCSUnit, DCSUnitName } )
          self:AddUnit( DCSUnit, DCSUnitName )
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

function DATABASE:_RegisterStatics()

  local CoalitionsData = { GroupsRed = coalition.getStaticObjects( coalition.side.RED ), GroupsBlue = coalition.getStaticObjects( coalition.side.BLUE ) }
  for CoalitionId, CoalitionData in pairs( CoalitionsData ) do
    for DCSStaticId, DCSStatic in pairs( CoalitionData ) do

      if DCSStatic:isExist() then
        local DCSStaticName = DCSStatic:getName()
  
        self:E( { "Register Static:", DCSStatic, DCSStaticName } )
        self:AddStatic( DCSStatic, DCSStaticName )
      else
        self:E( { "Static does not exist: ",  DCSStatic } )
      end
    end
  end

  return self
end


--- Events

--- Handles the OnBirth event for the alive units set.
-- @param #DATABASE self
-- @param Event#EVENTDATA Event
function DATABASE:_EventOnBirth( Event )
  self:F2( { Event } )

  if Event.IniDCSUnit then
    self:AddUnit( Event.IniDCSUnit, Event.IniDCSUnitName )
    self:AddGroup( Event.IniDCSGroup, Event.IniDCSGroupName )
    self:_EventOnPlayerEnterUnit( Event )
  end
end


--- Handles the OnDead or OnCrash event for alive units set.
-- @param #DATABASE self
-- @param Event#EVENTDATA Event
function DATABASE:_EventOnDeadOrCrash( Event )
  self:F2( { Event } )

  if Event.IniDCSUnit then
    if self.DCSUnits[Event.IniDCSUnitName] then
      self:DeleteUnit( Event.IniDCSUnitName )
      -- add logic to correctly remove a group once all units are destroyed...
    end
  end
end


--- Handles the OnPlayerEnterUnit event to fill the active players table (with the unit filter applied).
-- @param #DATABASE self
-- @param Event#EVENTDATA Event
function DATABASE:_EventOnPlayerEnterUnit( Event )
  self:F2( { Event } )

  if Event.IniDCSUnit then
    local PlayerName = Event.IniDCSUnit:getPlayerName()
    if not self.PLAYERSALIVE[PlayerName] then
      self:AddPlayer( Event.IniDCSUnitName, PlayerName )
    end
  end
end


--- Handles the OnPlayerLeaveUnit event to clean the active players table.
-- @param #DATABASE self
-- @param Event#EVENTDATA Event
function DATABASE:_EventOnPlayerLeaveUnit( Event )
  self:F2( { Event } )

  if Event.IniDCSUnit then
    local PlayerName = Event.IniDCSUnit:getPlayerName()
    if self.PLAYERSALIVE[PlayerName] then
      self:DeletePlayer( PlayerName )
    end
  end
end

--- Iterators

--- Iterate the DATABASE and call an iterator function for the given set, providing the Object for each element within the set and optional parameters.
-- @param #DATABASE self
-- @param #function IteratorFunction The function that will be called when there is an alive player in the database.
-- @return #DATABASE self
function DATABASE:ForEach( IteratorFunction, arg, Set )
  self:F2( arg )
  
  local function CoRoutine()
    local Count = 0
    for ObjectID, Object in pairs( Set ) do
        self:T2( Object )
        IteratorFunction( Object, unpack( arg ) )
        Count = Count + 1
        if Count % 10 == 0 then
          coroutine.yield( false )
        end    
    end
    return true
  end
  
  local co = coroutine.create( CoRoutine )
  
  local function Schedule()
  
    local status, res = coroutine.resume( co )
    self:T2( { status, res } )
    
    if status == false then
      error( res )
    end
    if res == false then
      return true -- resume next time the loop
    end
    
    return false
  end

  local Scheduler = SCHEDULER:New( self, Schedule, {}, 0.001, 0.001, 0 )
  
  return self
end


--- Iterate the DATABASE and call an iterator function for each **alive** unit, providing the DCSUnit and optional parameters.
-- @param #DATABASE self
-- @param #function IteratorFunction The function that will be called when there is an alive unit in the database. The function needs to accept a DCSUnit parameter.
-- @return #DATABASE self
function DATABASE:ForEachDCSUnit( IteratorFunction, ... )
  self:F2( arg )
  
  self:ForEach( IteratorFunction, arg, self.DCSUnits )

  return self
end


--- Iterate the DATABASE and call an iterator function for each **alive** UNIT, providing the UNIT and optional parameters.
-- @param #DATABASE self
-- @param #function IteratorFunction The function that will be called when there is an alive UNIT in the database. The function needs to accept a UNIT parameter.
-- @return #DATABASE self
function DATABASE:ForEachUnit( IteratorFunction, ... )
  self:F2( arg )
  
  self:ForEach( IteratorFunction, arg, self.UNITS )

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


--- Iterate the DATABASE and call an iterator function for each player, providing the player name and optional parameters.
-- @param #DATABASE self
-- @param #function IteratorFunction The function that will be called when there is an player in the database. The function needs to accept the player name.
-- @return #DATABASE self
function DATABASE:ForEachPlayer( IteratorFunction, ... )
  self:F2( arg )
  
  self:ForEach( IteratorFunction, arg, self.PLAYERS )
  
  return self
end


--- Iterate the DATABASE and call an iterator function for each **alive** player, providing the Unit of the player and optional parameters.
-- @param #DATABASE self
-- @param #function IteratorFunction The function that will be called when there is an alive player in the database. The function needs to accept a UNIT parameter.
-- @return #DATABASE self
function DATABASE:ForEachPlayerAlive( IteratorFunction, ... )
  self:F2( arg )
  
  self:ForEach( IteratorFunction, arg, self.PLAYERSALIVE )
  
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

--- Iterate the DATABASE and call an iterator function for each **ALIVE** CLIENT, providing the CLIENT to the function and optional parameters.
-- @param #DATABASE self
-- @param #function IteratorFunction The function that will be called when there is an alive CLIENT in the database. The function needs to accept a CLIENT parameter.
-- @return #DATABASE self
function DATABASE:ForEachClientAlive( IteratorFunction, ... )
  self:F2( arg )
  
  self:ForEach( IteratorFunction, arg, self.CLIENTSALIVE )

  return self
end


function DATABASE:_RegisterTemplates()
  self:F2()

  self.Navpoints = {}
  self.UNITS = {}
  --Build routines.db.units and self.Navpoints
  for coa_name, coa_data in pairs(env.mission.coalition) do

    if (coa_name == 'red' or coa_name == 'blue') and type(coa_data) == 'table' then
      --self.Units[coa_name] = {}

      ----------------------------------------------
      -- build nav points DB
      self.Navpoints[coa_name] = {}
      if coa_data.nav_points then --navpoints
        for nav_ind, nav_data in pairs(coa_data.nav_points) do

          if type(nav_data) == 'table' then
            self.Navpoints[coa_name][nav_ind] = routines.utils.deepCopy(nav_data)

            self.Navpoints[coa_name][nav_ind]['name'] = nav_data.callsignStr  -- name is a little bit more self-explanatory.
            self.Navpoints[coa_name][nav_ind]['point'] = {}  -- point is used by SSE, support it.
            self.Navpoints[coa_name][nav_ind]['point']['x'] = nav_data.x
            self.Navpoints[coa_name][nav_ind]['point']['y'] = 0
            self.Navpoints[coa_name][nav_ind]['point']['z'] = nav_data.y
          end
      end
      end
      -------------------------------------------------
      if coa_data.country then --there is a country table
        for cntry_id, cntry_data in pairs(coa_data.country) do

          local countryName = string.lower(cntry_data.name)
          --self.Units[coa_name][countryName] = {}
          --self.Units[coa_name][countryName]["countryId"] = cntry_data.id

          if type(cntry_data) == 'table' then  --just making sure

            for obj_type_name, obj_type_data in pairs(cntry_data) do

              if obj_type_name == "helicopter" or obj_type_name == "ship" or obj_type_name == "plane" or obj_type_name == "vehicle" or obj_type_name == "static" then --should be an unncessary check

                local category = obj_type_name

                if ((type(obj_type_data) == 'table') and obj_type_data.group and (type(obj_type_data.group) == 'table') and (#obj_type_data.group > 0)) then  --there's a group!

                  --self.Units[coa_name][countryName][category] = {}

                  for group_num, GroupTemplate in pairs(obj_type_data.group) do

                    if GroupTemplate and GroupTemplate.units and type(GroupTemplate.units) == 'table' then  --making sure again- this is a valid group
                      self:_RegisterTemplate( GroupTemplate )
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




