--- This module contains the SET classes.
-- 
-- ===
-- 
-- 1) @{Set#SET_BASE} class, extending @{Base#BASE}
-- ================================================
-- The @{Set#SET_BASE} class defines the core functions that define a collection of objects.
-- 
-- ===
-- 
-- 2) @{Set#SET_GROUP} class, extending @{Set#SET_BASE}
-- ====================================================
-- Mission designers can use the @{Set#SET_GROUP} class to build sets of groups belonging to certain:
-- 
--  * Coalitions
--  * Categories
--  * Countries
--  * Starting with certain prefix strings.
--  
-- 2.1) SET_GROUP construction methods:
-- ------------------------------------
-- Create a new SET_GROUP object with the @{#SET_GROUP.New} method:
-- 
--    * @{#SET_GROUP.New}: Creates a new SET_GROUP object.
-- 
-- 2.2) SET_GROUP filter criteria: 
-- -------------------------------
-- You can set filter criteria to define the set of groups within the SET_GROUP.
-- Filter criteria are defined by:
-- 
--    * @{#SET_GROUP.FilterCoalitions}: Builds the SET_GROUP with the groups belonging to the coalition(s).
--    * @{#SET_GROUP.FilterCategories}: Builds the SET_GROUP with the groups belonging to the category(ies).
--    * @{#SET_GROUP.FilterCountries}: Builds the SET_GROUP with the gruops belonging to the country(ies).
--    * @{#SET_GROUP.FilterPrefixes}: Builds the SET_GROUP with the groups starting with the same prefix string(s).
--   
-- Once the filter criteria have been set for the SET_GROUP, you can start filtering using:
-- 
--    * @{#SET_GROUP.FilterStart}: Starts the filtering of the groups within the SET_GROUP.
-- 
-- Planned filter criteria within development are (so these are not yet available):
-- 
--    * @{#SET_GROUP.FilterZones}: Builds the SET_GROUP with the groups within a @{Zone#ZONE}.
-- 
-- 
-- 2.3) SET_GROUP iterators:
-- -------------------------
-- Once the filters have been defined and the SET_GROUP has been built, you can iterate the SET_GROUP with the available iterator methods.
-- The iterator methods will walk the SET_GROUP set, and call for each element within the set a function that you provide.
-- The following iterator methods are currently available within the SET_GROUP:
-- 
--   * @{#SET_GROUP.ForEachGroup}: Calls a function for each alive group it finds within the SET_GROUP.
-- 
-- ====
-- 
-- 3) @{Set#SET_UNIT} class, extending @{Set#SET_BASE}
-- ===================================================
-- Mission designers can use the @{Set#SET_UNIT} class to build sets of units belonging to certain:
-- 
--  * Coalitions
--  * Categories
--  * Countries
--  * Unit types
--  * Starting with certain prefix strings.
--  
-- 3.1) SET_UNIT construction methods:
-- -----------------------------------
-- Create a new SET_UNIT object with the @{#SET_UNIT.New} method:
-- 
--    * @{#SET_UNIT.New}: Creates a new SET_UNIT object.
--   
-- 
-- 3.2) SET_UNIT filter criteria: 
-- ------------------------------
-- You can set filter criteria to define the set of units within the SET_UNIT.
-- Filter criteria are defined by:
-- 
--    * @{#SET_UNIT.FilterCoalitions}: Builds the SET_UNIT with the units belonging to the coalition(s).
--    * @{#SET_UNIT.FilterCategories}: Builds the SET_UNIT with the units belonging to the category(ies).
--    * @{#SET_UNIT.FilterTypes}: Builds the SET_UNIT with the units belonging to the unit type(s).
--    * @{#SET_UNIT.FilterCountries}: Builds the SET_UNIT with the units belonging to the country(ies).
--    * @{#SET_UNIT.FilterPrefixes}: Builds the SET_UNIT with the units starting with the same prefix string(s).
--   
-- Once the filter criteria have been set for the SET_UNIT, you can start filtering using:
-- 
--   * @{#SET_UNIT.FilterStart}: Starts the filtering of the units within the SET_UNIT.
-- 
-- Planned filter criteria within development are (so these are not yet available):
-- 
--    * @{#SET_UNIT.FilterZones}: Builds the SET_UNIT with the units within a @{Zone#ZONE}.
-- 
-- 3.3) SET_UNIT iterators:
-- ------------------------
-- Once the filters have been defined and the SET_UNIT has been built, you can iterate the SET_UNIT with the available iterator methods.
-- The iterator methods will walk the SET_UNIT set, and call for each element within the set a function that you provide.
-- The following iterator methods are currently available within the SET_UNIT:
-- 
--   * @{#SET_UNIT.ForEachUnit}: Calls a function for each alive unit it finds within the SET_UNIT.
--   
-- Planned iterators methods in development are (so these are not yet available):
-- 
--   * @{#SET_UNIT.ForEachUnitInGroup}: Calls a function for each group contained within the SET_UNIT.
--   * @{#SET_UNIT.ForEachUnitInZone}: Calls a function for each unit within a certain zone contained within the SET_UNIT.
-- 
-- 
-- ====
-- 
-- @module Set
-- @author FlightControl

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Menu" )
Include.File( "Group" )
Include.File( "Unit" )
Include.File( "Event" )
Include.File( "Client" )

--- SET_BASE class
-- @type SET_BASE
-- @extends Base#BASE
SET_BASE = {
  ClassName = "SET_BASE",
  Set = {},
  Database = {},
}

--- Creates a new SET_BASE object, building a set of units belonging to a coalitions, categories, countries, types or with defined prefix names.
-- @param #SET_BASE self
-- @return #SET_BASE
-- @usage
-- -- Define a new SET_BASE Object. This DBObject will contain a reference to all Group and Unit Templates defined within the ME and the DCSRTE.
-- DBObject = SET_BASE:New()
function SET_BASE:New( Database )

  -- Inherits from BASE
  local self = BASE:Inherit( self, BASE:New() )
  
  self.Database = Database

  return self
end

--- Finds an Object based on the Object Name.
-- @param #SET_BASE self
-- @param #string ObjectName
-- @return #table The Object found.
function SET_BASE:_Find( ObjectName )

  local ObjectFound = self.Set[ObjectName]
  return ObjectFound
end

--- Adds a Object based on the Object Name.
-- @param #SET_BASE self
-- @param #string ObjectName
-- @param #table Object
-- @return #table The added Object.
function SET_BASE:_Add( ObjectName, Object )

  self.Set[ObjectName] = Object
end

--- Starts the filtering for the defined collection.
-- @param #SET_BASE self
-- @return #SET_BASE self
function SET_BASE:_FilterStart()

  for ObjectName, Object in pairs( self.Database ) do

    if self:IsIncludeObject( Object ) then
      self:E( { "Adding Object:", ObjectName } )
      self:_Add( ObjectName, Object )
    end
  end
  
  _EVENTDISPATCHER:OnBirth( self._EventOnBirth, self )
  _EVENTDISPATCHER:OnDead( self._EventOnDeadOrCrash, self )
  _EVENTDISPATCHER:OnCrash( self._EventOnDeadOrCrash, self )
  
  -- Follow alive players and clients
--  _EVENTDISPATCHER:OnPlayerEnterUnit( self._EventOnPlayerEnterUnit, self )
--  _EVENTDISPATCHER:OnPlayerLeaveUnit( self._EventOnPlayerLeaveUnit, self )
  
  
  return self
end



----- Private method that registers all alive players in the mission.
---- @param #SET_BASE self
---- @return #SET_BASE self
--function SET_BASE:_RegisterPlayers()
--
--  local CoalitionsData = { AlivePlayersRed = coalition.getPlayers( coalition.side.RED ), AlivePlayersBlue = coalition.getPlayers( coalition.side.BLUE ) }
--  for CoalitionId, CoalitionData in pairs( CoalitionsData ) do
--    for UnitId, UnitData in pairs( CoalitionData ) do
--      self:T3( { "UnitData:", UnitData } )
--      if UnitData and UnitData:isExist() then
--        local UnitName = UnitData:getName()
--        if not self.PlayersAlive[UnitName] then
--          self:E( { "Add player for unit:", UnitName, UnitData:getPlayerName() } )
--          self.PlayersAlive[UnitName] = UnitData:getPlayerName()
--        end
--      end
--    end
--  end
--  
--  return self
--end

--- Events

--- Handles the OnBirth event for the Set.
-- @param #SET_BASE self
-- @param Event#EVENTDATA Event
function SET_BASE:_EventOnBirth( Event )
  self:F3( { Event } )

  if Event.IniDCSUnit then
    local ObjectName, Object = self:AddInDatabase( Event )
    self:T3( ObjectName, Object )
    if self:IsIncludeObject( Object ) then
      self:_Add( ObjectName, Object )
      --self:_EventOnPlayerEnterUnit( Event )
    end
  end
end

--- Handles the OnDead or OnCrash event for alive units set.
-- @param #SET_BASE self
-- @param Event#EVENTDATA Event
function SET_BASE:_EventOnDeadOrCrash( Event )
  self:F3( { Event } )

  if Event.IniDCSUnit then
    local ObjectName, Object = self:FindInDatabase( Event )
    if ObjectName and Object then
      self:_Delete( ObjectName )
    end
  end
end

----- Handles the OnPlayerEnterUnit event to fill the active players table (with the unit filter applied).
---- @param #SET_BASE self
---- @param Event#EVENTDATA Event
--function SET_BASE:_EventOnPlayerEnterUnit( Event )
--  self:F3( { Event } )
--
--  if Event.IniDCSUnit then
--    if self:IsIncludeObject( Event.IniDCSUnit ) then
--      if not self.PlayersAlive[Event.IniDCSUnitName] then
--        self:E( { "Add player for unit:", Event.IniDCSUnitName, Event.IniDCSUnit:getPlayerName() } )
--        self.PlayersAlive[Event.IniDCSUnitName] = Event.IniDCSUnit:getPlayerName()
--        self.ClientsAlive[Event.IniDCSUnitName] = _DATABASE.Clients[ Event.IniDCSUnitName ]
--      end
--    end
--  end
--end
--
----- Handles the OnPlayerLeaveUnit event to clean the active players table.
---- @param #SET_BASE self
---- @param Event#EVENTDATA Event
--function SET_BASE:_EventOnPlayerLeaveUnit( Event )
--  self:F3( { Event } )
--
--  if Event.IniDCSUnit then
--    if self:IsIncludeObject( Event.IniDCSUnit ) then
--      if self.PlayersAlive[Event.IniDCSUnitName] then
--        self:E( { "Cleaning player for unit:", Event.IniDCSUnitName, Event.IniDCSUnit:getPlayerName() } )
--        self.PlayersAlive[Event.IniDCSUnitName] = nil
--        self.ClientsAlive[Event.IniDCSUnitName] = nil
--      end
--    end
--  end
--end

-- Iterators

--- Interate the SET_BASE and call an interator function for the given set, providing the Object for each element within the set and optional parameters.
-- @param #SET_BASE self
-- @param #function IteratorFunction The function that will be called when there is an alive player in the SET_BASE.
-- @return #SET_BASE self
function SET_BASE:ForEach( IteratorFunction, arg, Set, Function, FunctionArguments )
  self:F3( arg )
  
  local function CoRoutine()
    local Count = 0
    for ObjectID, Object in pairs( Set ) do
        self:T2( Object )
        if Function then
          if Function( unpack( FunctionArguments ), Object ) == true then
            IteratorFunction( Object, unpack( arg ) )
          end
        else
          IteratorFunction( Object, unpack( arg ) )
        end
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
    self:T3( { status, res } )
    
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


----- Interate the SET_BASE and call an interator function for each **alive** unit, providing the Unit and optional parameters.
---- @param #SET_BASE self
---- @param #function IteratorFunction The function that will be called when there is an alive unit in the SET_BASE. The function needs to accept a UNIT parameter.
---- @return #SET_BASE self
--function SET_BASE:ForEachDCSUnitAlive( IteratorFunction, ... )
--  self:F3( arg )
--  
--  self:ForEach( IteratorFunction, arg, self.DCSUnitsAlive )
--
--  return self
--end
--
----- Interate the SET_BASE and call an interator function for each **alive** player, providing the Unit of the player and optional parameters.
---- @param #SET_BASE self
---- @param #function IteratorFunction The function that will be called when there is an alive player in the SET_BASE. The function needs to accept a UNIT parameter.
---- @return #SET_BASE self
--function SET_BASE:ForEachPlayer( IteratorFunction, ... )
--  self:F3( arg )
--  
--  self:ForEach( IteratorFunction, arg, self.PlayersAlive )
--  
--  return self
--end
--
--
----- Interate the SET_BASE and call an interator function for each client, providing the Client to the function and optional parameters.
---- @param #SET_BASE self
---- @param #function IteratorFunction The function that will be called when there is an alive player in the SET_BASE. The function needs to accept a CLIENT parameter.
---- @return #SET_BASE self
--function SET_BASE:ForEachClient( IteratorFunction, ... )
--  self:F3( arg )
--  
--  self:ForEach( IteratorFunction, arg, self.Clients )
--
--  return self
--end


--- Decides whether to include the Object
-- @param #SET_BASE self
-- @param #table Object
-- @return #SET_BASE self
function SET_BASE:IsIncludeObject( Object )
  self:F3( Object )
  
  return true
end

--- Flushes the current SET_BASE contents in the log ... (for debug reasons).
-- @param #SET_BASE self
-- @return #string A string with the names of the objects.
function SET_BASE:Flush()
  self:F3()

  local ObjectNames = ""
  for ObjectName, Object in pairs( self.Set ) do
    ObjectNames = ObjectNames .. ObjectName .. ", "
  end
  self:T( { "Objects in Set:", ObjectNames } )
  
  return ObjectNames
end

-- SET_GROUP

--- SET_GROUP class
-- @type SET_GROUP
-- @extends Set#SET_BASE
SET_GROUP = {
  ClassName = "SET_GROUP",
  Filter = {
    Coalitions = nil,
    Categories = nil,
    Countries = nil,
    GroupPrefixes = nil,
  },
  FilterMeta = {
    Coalitions = {
      red = coalition.side.RED,
      blue = coalition.side.BLUE,
      neutral = coalition.side.NEUTRAL,
    },
    Categories = {
      plane = Group.Category.AIRPLANE,
      helicopter = Group.Category.HELICOPTER,
      ground = Group.Category.GROUND_UNIT,
      ship = Group.Category.SHIP,
      structure = Group.Category.STRUCTURE,
    },
  },
}


--- Creates a new SET_GROUP object, building a set of groups belonging to a coalitions, categories, countries, types or with defined prefix names.
-- @param #SET_GROUP self
-- @return #SET_GROUP
-- @usage
-- -- Define a new SET_GROUP Object. This DBObject will contain a reference to all alive GROUPS.
-- DBObject = SET_GROUP:New()
function SET_GROUP:New()

  -- Inherits from BASE
  local self = BASE:Inherit( self, SET_BASE:New( _DATABASE.GROUPS ) )

  return self
end


--- Finds a Group based on the Group Name.
-- @param #SET_GROUP self
-- @param #string GroupName
-- @return Group#GROUP The found Group.
function SET_GROUP:FindGroup( GroupName )

  local GroupFound = self.Set[GroupName]
  return GroupFound
end



--- Builds a set of groups of coalitions.
-- Possible current coalitions are red, blue and neutral.
-- @param #SET_GROUP self
-- @param #string Coalitions Can take the following values: "red", "blue", "neutral".
-- @return #SET_GROUP self
function SET_GROUP:FilterCoalitions( Coalitions )
  if not self.Filter.Coalitions then
    self.Filter.Coalitions = {}
  end
  if type( Coalitions ) ~= "table" then
    Coalitions = { Coalitions }
  end
  for CoalitionID, Coalition in pairs( Coalitions ) do
    self.Filter.Coalitions[Coalition] = Coalition
  end
  return self
end


--- Builds a set of groups out of categories.
-- Possible current categories are plane, helicopter, ground, ship.
-- @param #SET_GROUP self
-- @param #string Categories Can take the following values: "plane", "helicopter", "ground", "ship".
-- @return #SET_GROUP self
function SET_GROUP:FilterCategories( Categories )
  if not self.Filter.Categories then
    self.Filter.Categories = {}
  end
  if type( Categories ) ~= "table" then
    Categories = { Categories }
  end
  for CategoryID, Category in pairs( Categories ) do
    self.Filter.Categories[Category] = Category
  end
  return self
end

--- Builds a set of groups of defined countries.
-- Possible current countries are those known within DCS world.
-- @param #SET_GROUP self
-- @param #string Countries Can take those country strings known within DCS world.
-- @return #SET_GROUP self
function SET_GROUP:FilterCountries( Countries )
  if not self.Filter.Countries then
    self.Filter.Countries = {}
  end
  if type( Countries ) ~= "table" then
    Countries = { Countries }
  end
  for CountryID, Country in pairs( Countries ) do
    self.Filter.Countries[Country] = Country
  end
  return self
end


--- Builds a set of groups of defined GROUP prefixes.
-- All the groups starting with the given prefixes will be included within the set.
-- @param #SET_GROUP self
-- @param #string Prefixes The prefix of which the group name starts with.
-- @return #SET_GROUP self
function SET_GROUP:FilterPrefixes( Prefixes )
  if not self.Filter.GroupPrefixes then
    self.Filter.GroupPrefixes = {}
  end
  if type( Prefixes ) ~= "table" then
    Prefixes = { Prefixes }
  end
  for PrefixID, Prefix in pairs( Prefixes ) do
    self.Filter.GroupPrefixes[Prefix] = Prefix
  end
  return self
end


--- Starts the filtering.
-- @param #SET_GROUP self
-- @return #SET_GROUP self
function SET_GROUP:FilterStart()

  if _DATABASE then
    self:_FilterStart()
  end
  
  return self
end

--- Handles the Database to check on an event (birth) that the Object was added in the Database.
-- This is required, because sometimes the _DATABASE birth event gets called later than the SET_BASE birth event!
-- @param #SET_GROUP self
-- @param Event#EVENTDATA Event
-- @return #string The name of the GROUP
-- @return #table The GROUP
function SET_GROUP:AddInDatabase( Event )
  self:F3( { Event } )

  if not self.Database[Event.IniDCSGroupName] then
    self.Database[Event.IniDCSGroupName] = GROUP:Register( Event.IniDCSGroupName )
    self:T3( self.Database[Event.IniDCSGroupName] )
  end
  
  return Event.IniDCSGroupName, self.Database[Event.IniDCSGroupName]
end

--- Handles the Database to check on any event that Object exists in the Database.
-- This is required, because sometimes the _DATABASE event gets called later than the SET_BASE event or vise versa!
-- @param #SET_GROUP self
-- @param Event#EVENTDATA Event
-- @return #string The name of the GROUP
-- @return #table The GROUP
function SET_GROUP:FindInDatabase( Event )
  self:F3( { Event } )

  return Event.IniDCSGroupName, self.Database[Event.IniDCSGroupName]
end

--- Iterate the SET_GROUP and call an iterator function for each **alive** GROUP, providing the GROUP and optional parameters.
-- @param #SET_GROUP self
-- @param #function IteratorFunction The function that will be called when there is an alive GROUP in the SET_GROUP. The function needs to accept a GROUP parameter.
-- @return #SET_GROUP self
function SET_GROUP:ForEachGroup( IteratorFunction, ... )
  self:F2( arg )
  
  self:ForEach( IteratorFunction, arg, self.Set )

  return self
end

--- Iterate the SET_GROUP and call an iterator function for each **alive** GROUP presence completely in a @{Zone}, providing the GROUP and optional parameters to the called function.
-- @param #SET_GROUP self
-- @param Zone#ZONE ZoneObject The Zone to be tested for.
-- @param #function IteratorFunction The function that will be called when there is an alive GROUP in the SET_GROUP. The function needs to accept a GROUP parameter.
-- @return #SET_GROUP self
function SET_GROUP:ForEachGroupCompletelyInZone( ZoneObject, IteratorFunction, ... )
  self:F2( arg )
  
  self:ForEach( IteratorFunction, arg, self.Set,
    --- @param Zone#ZONE_BASE ZoneObject
    -- @param Group#GROUP GroupObject
    function( ZoneObject, GroupObject )
      if GroupObject:IsCompletelyInZone( ZoneObject ) then
        return true
      else
        return false
      end
    end, { ZoneObject } )

  return self
end

--- Iterate the SET_GROUP and call an iterator function for each **alive** GROUP presence partly in a @{Zone}, providing the GROUP and optional parameters to the called function.
-- @param #SET_GROUP self
-- @param Zone#ZONE ZoneObject The Zone to be tested for.
-- @param #function IteratorFunction The function that will be called when there is an alive GROUP in the SET_GROUP. The function needs to accept a GROUP parameter.
-- @return #SET_GROUP self
function SET_GROUP:ForEachGroupPartlyInZone( ZoneObject, IteratorFunction, ... )
  self:F2( arg )
  
  self:ForEach( IteratorFunction, arg, self.Set,
    --- @param Zone#ZONE_BASE ZoneObject
    -- @param Group#GROUP GroupObject
    function( ZoneObject, GroupObject )
      if GroupObject:IsPartlyInZone( ZoneObject ) then
        return true
      else
        return false
      end
    end, { ZoneObject } )

  return self
end

--- Iterate the SET_GROUP and call an iterator function for each **alive** GROUP presence not in a @{Zone}, providing the GROUP and optional parameters to the called function.
-- @param #SET_GROUP self
-- @param Zone#ZONE ZoneObject The Zone to be tested for.
-- @param #function IteratorFunction The function that will be called when there is an alive GROUP in the SET_GROUP. The function needs to accept a GROUP parameter.
-- @return #SET_GROUP self
function SET_GROUP:ForEachGroupNotInZone( ZoneObject, IteratorFunction, ... )
  self:F2( arg )
  
  self:ForEach( IteratorFunction, arg, self.Set,
    --- @param Zone#ZONE_BASE ZoneObject
    -- @param Group#GROUP GroupObject
    function( ZoneObject, GroupObject )
      if GroupObject:IsNotInZone( ZoneObject ) then
        return true
      else
        return false
      end
    end, { ZoneObject } )

  return self
end


----- Interate the SET_GROUP and call an interator function for each **alive** player, providing the Group of the player and optional parameters.
---- @param #SET_GROUP self
---- @param #function IteratorFunction The function that will be called when there is an alive player in the SET_GROUP. The function needs to accept a GROUP parameter.
---- @return #SET_GROUP self
--function SET_GROUP:ForEachPlayer( IteratorFunction, ... )
--  self:F2( arg )
--  
--  self:ForEach( IteratorFunction, arg, self.PlayersAlive )
--  
--  return self
--end
--
--
----- Interate the SET_GROUP and call an interator function for each client, providing the Client to the function and optional parameters.
---- @param #SET_GROUP self
---- @param #function IteratorFunction The function that will be called when there is an alive player in the SET_GROUP. The function needs to accept a CLIENT parameter.
---- @return #SET_GROUP self
--function SET_GROUP:ForEachClient( IteratorFunction, ... )
--  self:F2( arg )
--  
--  self:ForEach( IteratorFunction, arg, self.Clients )
--
--  return self
--end


---
-- @param #SET_GROUP self
-- @param Group#GROUP MooseGroup
-- @return #SET_GROUP self
function SET_GROUP:IsIncludeObject( MooseGroup )
  self:F2( MooseGroup )
  local MooseGroupInclude = true

  if self.Filter.Coalitions then
    local MooseGroupCoalition = false
    for CoalitionID, CoalitionName in pairs( self.Filter.Coalitions ) do
      self:T3( { "Coalition:", MooseGroup:GetCoalition(), self.FilterMeta.Coalitions[CoalitionName], CoalitionName } )
      if self.FilterMeta.Coalitions[CoalitionName] and self.FilterMeta.Coalitions[CoalitionName] == MooseGroup:GetCoalition() then
        MooseGroupCoalition = true
      end
    end
    MooseGroupInclude = MooseGroupInclude and MooseGroupCoalition
  end
  
  if self.Filter.Categories then
    local MooseGroupCategory = false
    for CategoryID, CategoryName in pairs( self.Filter.Categories ) do
      self:T3( { "Category:", MooseGroup:GetCategory(), self.FilterMeta.Categories[CategoryName], CategoryName } )
      if self.FilterMeta.Categories[CategoryName] and self.FilterMeta.Categories[CategoryName] == MooseGroup:GetCategory() then
        MooseGroupCategory = true
      end
    end
    MooseGroupInclude = MooseGroupInclude and MooseGroupCategory
  end
  
  if self.Filter.Countries then
    local MooseGroupCountry = false
    for CountryID, CountryName in pairs( self.Filter.Countries ) do
      self:T3( { "Country:", MooseGroup:GetCountry(), CountryName } )
      if country.id[CountryName] == MooseGroup:GetCountry() then
        MooseGroupCountry = true
      end
    end
    MooseGroupInclude = MooseGroupInclude and MooseGroupCountry
  end

  if self.Filter.GroupPrefixes then
    local MooseGroupPrefix = false
    for GroupPrefixId, GroupPrefix in pairs( self.Filter.GroupPrefixes ) do
      self:T3( { "Prefix:", string.find( MooseGroup:GetName(), GroupPrefix, 1 ), GroupPrefix } )
      if string.find( MooseGroup:GetName(), GroupPrefix, 1 ) then
        MooseGroupPrefix = true
      end
    end
    MooseGroupInclude = MooseGroupInclude and MooseGroupPrefix
  end

  self:T2( MooseGroupInclude )
  return MooseGroupInclude
end

--- SET_UNIT class
-- @type SET_UNIT
-- @extends Set#SET_BASE
SET_UNIT = {
  ClassName = "SET_UNIT",
  Units = {},
  Filter = {
    Coalitions = nil,
    Categories = nil,
    Types = nil,
    Countries = nil,
    UnitPrefixes = nil,
  },
  FilterMeta = {
    Coalitions = {
      red = coalition.side.RED,
      blue = coalition.side.BLUE,
      neutral = coalition.side.NEUTRAL,
    },
    Categories = {
      plane = Unit.Category.AIRPLANE,
      helicopter = Unit.Category.HELICOPTER,
      ground = Unit.Category.GROUND_UNIT,
      ship = Unit.Category.SHIP,
      structure = Unit.Category.STRUCTURE,
    },
  },
}


--- Creates a new SET_UNIT object, building a set of units belonging to a coalitions, categories, countries, types or with defined prefix names.
-- @param #SET_UNIT self
-- @return #SET_UNIT
-- @usage
-- -- Define a new SET_UNIT Object. This DBObject will contain a reference to all alive Units.
-- DBObject = SET_UNIT:New()
function SET_UNIT:New()

  -- Inherits from BASE
  local self = BASE:Inherit( self, SET_BASE:New( _DATABASE.UNITS ) )

  return self
end


--- Finds a Unit based on the Unit Name.
-- @param #SET_UNIT self
-- @param #string UnitName
-- @return Unit#UNIT The found Unit.
function SET_UNIT:FindUnit( UnitName )

  local UnitFound = self.Set[UnitName]
  return UnitFound
end



--- Builds a set of units of coalitions.
-- Possible current coalitions are red, blue and neutral.
-- @param #SET_UNIT self
-- @param #string Coalitions Can take the following values: "red", "blue", "neutral".
-- @return #SET_UNIT self
function SET_UNIT:FilterCoalitions( Coalitions )
  if not self.Filter.Coalitions then
    self.Filter.Coalitions = {}
  end
  if type( Coalitions ) ~= "table" then
    Coalitions = { Coalitions }
  end
  for CoalitionID, Coalition in pairs( Coalitions ) do
    self.Filter.Coalitions[Coalition] = Coalition
  end
  return self
end


--- Builds a set of units out of categories.
-- Possible current categories are plane, helicopter, ground, ship.
-- @param #SET_UNIT self
-- @param #string Categories Can take the following values: "plane", "helicopter", "ground", "ship".
-- @return #SET_UNIT self
function SET_UNIT:FilterCategories( Categories )
  if not self.Filter.Categories then
    self.Filter.Categories = {}
  end
  if type( Categories ) ~= "table" then
    Categories = { Categories }
  end
  for CategoryID, Category in pairs( Categories ) do
    self.Filter.Categories[Category] = Category
  end
  return self
end


--- Builds a set of units of defined unit types.
-- Possible current types are those types known within DCS world.
-- @param #SET_UNIT self
-- @param #string Types Can take those type strings known within DCS world.
-- @return #SET_UNIT self
function SET_UNIT:FilterTypes( Types )
  if not self.Filter.Types then
    self.Filter.Types = {}
  end
  if type( Types ) ~= "table" then
    Types = { Types }
  end
  for TypeID, Type in pairs( Types ) do
    self.Filter.Types[Type] = Type
  end
  return self
end


--- Builds a set of units of defined countries.
-- Possible current countries are those known within DCS world.
-- @param #SET_UNIT self
-- @param #string Countries Can take those country strings known within DCS world.
-- @return #SET_UNIT self
function SET_UNIT:FilterCountries( Countries )
  if not self.Filter.Countries then
    self.Filter.Countries = {}
  end
  if type( Countries ) ~= "table" then
    Countries = { Countries }
  end
  for CountryID, Country in pairs( Countries ) do
    self.Filter.Countries[Country] = Country
  end
  return self
end


--- Builds a set of units of defined unit prefixes.
-- All the units starting with the given prefixes will be included within the set.
-- @param #SET_UNIT self
-- @param #string Prefixes The prefix of which the unit name starts with.
-- @return #SET_UNIT self
function SET_UNIT:FilterPrefixes( Prefixes )
  if not self.Filter.UnitPrefixes then
    self.Filter.UnitPrefixes = {}
  end
  if type( Prefixes ) ~= "table" then
    Prefixes = { Prefixes }
  end
  for PrefixID, Prefix in pairs( Prefixes ) do
    self.Filter.UnitPrefixes[Prefix] = Prefix
  end
  return self
end




--- Starts the filtering.
-- @param #SET_UNIT self
-- @return #SET_UNIT self
function SET_UNIT:FilterStart()

  if _DATABASE then
    self:_FilterStart()
  end
  
  return self
end

--- Handles the Database to check on an event (birth) that the Object was added in the Database.
-- This is required, because sometimes the _DATABASE birth event gets called later than the SET_BASE birth event!
-- @param #SET_UNIT self
-- @param Event#EVENTDATA Event
-- @return #string The name of the UNIT
-- @return #table The UNIT
function SET_UNIT:AddInDatabase( Event )
  self:F3( { Event } )

  if not self.Database[Event.IniDCSUnitName] then
    self.Database[Event.IniDCSUnitName] = UNIT:Register( Event.IniDCSUnitName )
    self:T3( self.Database[Event.IniDCSUnitName] )
  end
  
  return Event.IniDCSUnitName, self.Database[Event.IniDCSUnitName]
end

--- Handles the Database to check on any event that Object exists in the Database.
-- This is required, because sometimes the _DATABASE event gets called later than the SET_BASE event or vise versa!
-- @param #SET_UNIT self
-- @param Event#EVENTDATA Event
-- @return #string The name of the UNIT
-- @return #table The UNIT
function SET_UNIT:FindInDatabase( Event )
  self:F3( { Event } )

  return Event.IniDCSUnitName, self.Database[Event.IniDCSUnitName]
end

--- Interate the SET_UNIT and call an interator function for each **alive** UNIT, providing the UNIT and optional parameters.
-- @param #SET_UNIT self
-- @param #function IteratorFunction The function that will be called when there is an alive UNIT in the SET_UNIT. The function needs to accept a UNIT parameter.
-- @return #SET_UNIT self
function SET_UNIT:ForEachUnit( IteratorFunction, ... )
  self:F2( arg )
  
  self:ForEach( IteratorFunction, arg, self.Set )

  return self
end


----- Interate the SET_UNIT and call an interator function for each **alive** player, providing the Unit of the player and optional parameters.
---- @param #SET_UNIT self
---- @param #function IteratorFunction The function that will be called when there is an alive player in the SET_UNIT. The function needs to accept a UNIT parameter.
---- @return #SET_UNIT self
--function SET_UNIT:ForEachPlayer( IteratorFunction, ... )
--  self:F2( arg )
--  
--  self:ForEach( IteratorFunction, arg, self.PlayersAlive )
--  
--  return self
--end
--
--
----- Interate the SET_UNIT and call an interator function for each client, providing the Client to the function and optional parameters.
---- @param #SET_UNIT self
---- @param #function IteratorFunction The function that will be called when there is an alive player in the SET_UNIT. The function needs to accept a CLIENT parameter.
---- @return #SET_UNIT self
--function SET_UNIT:ForEachClient( IteratorFunction, ... )
--  self:F2( arg )
--  
--  self:ForEach( IteratorFunction, arg, self.Clients )
--
--  return self
--end


---
-- @param #SET_UNIT self
-- @param Unit#UNIT MUnit
-- @return #SET_UNIT self
function SET_UNIT:IsIncludeObject( MUnit )
  self:F2( MUnit )
  local MUnitInclude = true

  if self.Filter.Coalitions then
    local MUnitCoalition = false
    for CoalitionID, CoalitionName in pairs( self.Filter.Coalitions ) do
      self:T3( { "Coalition:", MUnit:GetCoalition(), self.FilterMeta.Coalitions[CoalitionName], CoalitionName } )
      if self.FilterMeta.Coalitions[CoalitionName] and self.FilterMeta.Coalitions[CoalitionName] == MUnit:GetCoalition() then
        MUnitCoalition = true
      end
    end
    MUnitInclude = MUnitInclude and MUnitCoalition
  end
  
  if self.Filter.Categories then
    local MUnitCategory = false
    for CategoryID, CategoryName in pairs( self.Filter.Categories ) do
      self:T3( { "Category:", MUnit:GetDesc().category, self.FilterMeta.Categories[CategoryName], CategoryName } )
      if self.FilterMeta.Categories[CategoryName] and self.FilterMeta.Categories[CategoryName] == MUnit:GetDesc().category then
        MUnitCategory = true
      end
    end
    MUnitInclude = MUnitInclude and MUnitCategory
  end
  
  if self.Filter.Types then
    local MUnitType = false
    for TypeID, TypeName in pairs( self.Filter.Types ) do
      self:T3( { "Type:", MUnit:GetTypeName(), TypeName } )
      if TypeName == MUnit:GetTypeName() then
        MUnitType = true
      end
    end
    MUnitInclude = MUnitInclude and MUnitType
  end
  
  if self.Filter.Countries then
    local MUnitCountry = false
    for CountryID, CountryName in pairs( self.Filter.Countries ) do
      self:T3( { "Country:", MUnit:GetCountry(), CountryName } )
      if country.id[CountryName] == MUnit:GetCountry() then
        MUnitCountry = true
      end
    end
    MUnitInclude = MUnitInclude and MUnitCountry
  end

  if self.Filter.UnitPrefixes then
    local MUnitPrefix = false
    for UnitPrefixId, UnitPrefix in pairs( self.Filter.UnitPrefixes ) do
      self:T3( { "Prefix:", string.find( MUnit:GetName(), UnitPrefix, 1 ), UnitPrefix } )
      if string.find( MUnit:GetName(), UnitPrefix, 1 ) then
        MUnitPrefix = true
      end
    end
    MUnitInclude = MUnitInclude and MUnitPrefix
  end

  self:T2( MUnitInclude )
  return MUnitInclude
end

