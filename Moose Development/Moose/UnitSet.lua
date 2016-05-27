--- Create and manage a set of units. 
-- 
-- @{#UNITSET} class
-- ==================
-- Mission designers can use the UNITSET class to build sets of units belonging to certain:
-- 
--  * Coalitions
--  * Categories
--  * Countries
--  * Unit types
--  * Starting with certain prefix strings.
--  
-- This list will grow over time. Planned developments are to include filters and iterators.
-- Additional filters will be added around @{Zone#ZONEs}, Radiuses, Active players, ...
-- More iterators will be implemented in the near future ...
--
-- Administers the Initial Sets of the Mission Templates as defined within the Mission Editor.
-- 
-- UNITSET construction methods:
-- =================================
-- Create a new UNITSET object with the @{#UNITSET.New} method:
-- 
--    * @{#UNITSET.New}: Creates a new UNITSET object.
--   
-- 
-- UNITSET filter criteria: 
-- =========================
-- You can set filter criteria to define the set of units within the UNITSET.
-- Filter criteria are defined by:
-- 
--    * @{#UNITSET.FilterCoalitions}: Builds the UNITSET with the units belonging to the coalition(s).
--    * @{#UNITSET.FilterCategories}: Builds the UNITSET with the units belonging to the category(ies).
--    * @{#UNITSET.FilterTypes}: Builds the UNITSET with the units belonging to the unit type(s).
--    * @{#UNITSET.FilterCountries}: Builds the UNITSET with the units belonging to the country(ies).
--    * @{#UNITSET.FilterPrefixes}: Builds the UNITSET with the units starting with the same prefix string(s).
--   
-- Once the filter criteria have been set for the UNITSET, you can start filtering using:
-- 
--   * @{#UNITSET.FilterStart}: Starts the filtering of the units within the UNITSET.
-- 
-- Planned filter criteria within development are (so these are not yet available):
-- 
--    * @{#UNITSET.FilterZones}: Builds the UNITSET with the units within a @{Zone#ZONE}.
-- 
-- 
-- UNITSET iterators:
-- ===================
-- Once the filters have been defined and the UNITSET has been built, you can iterate the UNITSET with the available iterator methods.
-- The iterator methods will walk the UNITSET set, and call for each element within the set a function that you provide.
-- The following iterator methods are currently available within the UNITSET:
-- 
--   * @{#UNITSET.ForEachUnit}: Calls a function for each alive unit it finds within the UNITSET.
--   
-- Planned iterators methods in development are (so these are not yet available):
-- 
--   * @{#UNITSET.ForEachUnitInGroup}: Calls a function for each group contained within the UNITSET.
--   * @{#UNITSET.ForEachUnitInZone}: Calls a function for each unit within a certain zone contained within the UNITSET.
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


--- UNITSET class
-- @type UNITSET
-- @extends Set#SET
UNITSET = {
  ClassName = "UNITSET",
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


--- Creates a new UNITSET object, building a set of units belonging to a coalitions, categories, countries, types or with defined prefix names.
-- @param #UNITSET self
-- @return #UNITSET
-- @usage
-- -- Define a new UNITSET Object. This DBObject will contain a reference to all alive Units.
-- DBObject = UNITSET:New()
function UNITSET:New()

  -- Inherits from BASE
  local self = BASE:Inherit( self, SET:New( _DATABASE.Units ) )
  
  
  
--  -- Follow alive players and clients
--  _EVENTDISPATCHER:OnPlayerEnterUnit( self._EventOnPlayerEnterUnit, self )
--  _EVENTDISPATCHER:OnPlayerLeaveUnit( self._EventOnPlayerLeaveUnit, self )

--  self:_RegisterPlayers()

  return self
end

--- Finds a Unit based on the Unit Name.
-- @param #UNITSET self
-- @param #string UnitName
-- @return Unit#UNIT The found Unit.
function UNITSET:FindUnit( UnitName )

  local UnitFound = self.Units[UnitName]
  return UnitFound
end

--- Finds a Unit based on the Unit Name.
-- @param #UNITSET self
-- @param Unit#UNIT UnitName
-- @param Unit#UNIT UnitData
-- @return Unit#UNIT The added Unit.
function UNITSET:_AddUnit( UnitName, UnitData )

  self.Units[UnitName] = _DATABASE:FindUnit( UnitName )
end



--- Builds a set of units of coalitons.
-- Possible current coalitions are red, blue and neutral.
-- @param #UNITSET self
-- @param #string Coalitions Can take the following values: "red", "blue", "neutral".
-- @return #UNITSET self
function UNITSET:FilterCoalitions( Coalitions )
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
-- @param #UNITSET self
-- @param #string Categories Can take the following values: "plane", "helicopter", "ground", "ship".
-- @return #UNITSET self
function UNITSET:FilterCategories( Categories )
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
-- @param #UNITSET self
-- @param #string Types Can take those type strings known within DCS world.
-- @return #UNITSET self
function UNITSET:FilterTypes( Types )
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
-- @param #UNITSET self
-- @param #string Countries Can take those country strings known within DCS world.
-- @return #UNITSET self
function UNITSET:FilterCountries( Countries )
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
-- @param #UNITSET self
-- @param #string Prefixes The prefix of which the unit name starts with.
-- @return #UNITSET self
function UNITSET:FilterPrefixes( Prefixes )
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


----- Builds a set of units of defined group prefixes.
---- All the units starting with the given group prefixes will be included within the set.
---- @param #UNITSET self
---- @param #string Prefixes The prefix of which the group name where the unit belongs to starts with.
---- @return #UNITSET self
--function UNITSET:FilterGroupPrefixes( Prefixes )
--  if not self.Filter.GroupPrefixes then
--    self.Filter.GroupPrefixes = {}
--  end
--  if type( Prefixes ) ~= "table" then
--    Prefixes = { Prefixes }
--  end
--  for PrefixID, Prefix in pairs( Prefixes ) do
--    self.Filter.GroupPrefixes[Prefix] = Prefix
--  end
--  return self
--end


--- Starts the filtering.
-- @param #UNITSET self
-- @return #UNITSET self
function UNITSET:FilterStart()

  if _DATABASE then
    self:_FilterStart( self.DatabaseCollection )
  end
  
  FollowEventBirth( )
  
  _EVENTDISPATCHER:OnBirth( self._EventOnBirth, self )
  _EVENTDISPATCHER:OnDead( self._EventOnDeadOrCrash, self )
  _EVENTDISPATCHER:OnCrash( self._EventOnDeadOrCrash, self )
  
  return self
end

--- Events

--- Handles the OnBirth event for the alive units set.
-- @param #UNITSET self
-- @param Event#EVENTDATA Event
function UNITSET:_EventOnBirth( Event )
  self:F( { Event } )

  if Event.IniDCSUnit then
    if self:_IsIncludeUnit( Event.IniDCSUnit ) then
      self.DCSUnits[Event.IniDCSUnitName] = Event.IniDCSUnit 
      self.DCSUnitsAlive[Event.IniDCSUnitName] = Event.IniDCSUnit
      self:_AddUnit( UNIT:Register( Event.IniDCSUnit ) )
      --self.Units[Event.IniDCSUnitName] = UNIT:Register( Event.IniDCSUnit )
      
      --if not self.DCSGroups[Event.IniDCSGroupName] then
      --  self.DCSGroups[Event.IniDCSGroupName] = Event.IniDCSGroupName
      --  self.DCSGroupsAlive[Event.IniDCSGroupName] = Event.IniDCSGroupName
      --  self.Groups[Event.IniDCSGroupName] = GROUP:New( Event.IniDCSGroup )
      --end
      self:_EventOnPlayerEnterUnit( Event )
    end
  end
end

--- Handles the OnDead or OnCrash event for alive units set.
-- @param #UNITSET self
-- @param Event#EVENTDATA Event
function UNITSET:_EventOnDeadOrCrash( Event )
  self:F( { Event } )

  if Event.IniDCSUnit then
    if self.DCSUnitsAlive[Event.IniDCSUnitName] then
      self.DCSUnits[Event.IniDCSUnitName] = nil 
      self.DCSUnitsAlive[Event.IniDCSUnitName] = nil
    end
  end
end

--- Handles the OnPlayerEnterUnit event to fill the active players table (with the unit filter applied).
-- @param #UNITSET self
-- @param Event#EVENTDATA Event
function UNITSET:_EventOnPlayerEnterUnit( Event )
  self:F( { Event } )

  if Event.IniDCSUnit then
    if self:_IsIncludeUnit( Event.IniDCSUnit ) then
      if not self.PlayersAlive[Event.IniDCSUnitName] then
        self:E( { "Add player for unit:", Event.IniDCSUnitName, Event.IniDCSUnit:getPlayerName() } )
        self.PlayersAlive[Event.IniDCSUnitName] = Event.IniDCSUnit:getPlayerName()
        self.ClientsAlive[Event.IniDCSUnitName] = _DATABASE.Clients[ Event.IniDCSUnitName ]
      end
    end
  end
end

--- Handles the OnPlayerLeaveUnit event to clean the active players table.
-- @param #UNITSET self
-- @param Event#EVENTDATA Event
function UNITSET:_EventOnPlayerLeaveUnit( Event )
  self:F( { Event } )

  if Event.IniDCSUnit then
    if self:_IsIncludeUnit( Event.IniDCSUnit ) then
      if self.PlayersAlive[Event.IniDCSUnitName] then
        self:E( { "Cleaning player for unit:", Event.IniDCSUnitName, Event.IniDCSUnit:getPlayerName() } )
        self.PlayersAlive[Event.IniDCSUnitName] = nil
        self.ClientsAlive[Event.IniDCSUnitName] = nil
      end
    end
  end
end

--- Iterators

--- Interate the UNITSET and call an interator function for the given set, providing the Object for each element within the set and optional parameters.
-- @param #UNITSET self
-- @param #function IteratorFunction The function that will be called when there is an alive player in the UNITSET.
-- @return #UNITSET self
function UNITSET:ForEach( IteratorFunction, arg, Set )
  self:F( arg )
  
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
    self:T( { status, res } )
    
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


--- Interate the UNITSET and call an interator function for each **alive** unit, providing the Unit and optional parameters.
-- @param #UNITSET self
-- @param #function IteratorFunction The function that will be called when there is an alive unit in the UNITSET. The function needs to accept a UNIT parameter.
-- @return #UNITSET self
function UNITSET:ForEachDCSUnitAlive( IteratorFunction, ... )
  self:F( arg )
  
  self:ForEach( IteratorFunction, arg, self.DCSUnitsAlive )

  return self
end


--- Interate the UNITSET and call an interator function for each **alive** player, providing the Unit of the player and optional parameters.
-- @param #UNITSET self
-- @param #function IteratorFunction The function that will be called when there is an alive player in the UNITSET. The function needs to accept a UNIT parameter.
-- @return #UNITSET self
function UNITSET:ForEachPlayer( IteratorFunction, ... )
  self:F( arg )
  
  self:ForEach( IteratorFunction, arg, self.PlayersAlive )
  
  return self
end


--- Interate the UNITSET and call an interator function for each client, providing the Client to the function and optional parameters.
-- @param #UNITSET self
-- @param #function IteratorFunction The function that will be called when there is an alive player in the UNITSET. The function needs to accept a CLIENT parameter.
-- @return #UNITSET self
function UNITSET:ForEachClient( IteratorFunction, ... )
  self:F( arg )
  
  self:ForEach( IteratorFunction, arg, self.Clients )

  return self
end


---
-- @param #UNITSET self
-- @param Unit#UNIT MUnit
-- @return #UNITSET self
function UNITSET:IsIncludeObject( MUnit )
  self:F( MUnit )
  local MUnitInclude = true

  if self.Filter.Coalitions then
    local MUnitCoalition = false
    for CoalitionID, CoalitionName in pairs( self.Filter.Coalitions ) do
      self:T( { "Coalition:", MUnit:GetCoalition(), self.FilterMeta.Coalitions[CoalitionName], CoalitionName } )
      if self.FilterMeta.Coalitions[CoalitionName] and self.FilterMeta.Coalitions[CoalitionName] == MUnit:GetCoalition() then
        MUnitCoalition = true
      end
    end
    MUnitInclude = MUnitInclude and MUnitCoalition
  end
  
  if self.Filter.Categories then
    local MUnitCategory = false
    for CategoryID, CategoryName in pairs( self.Filter.Categories ) do
      self:T( { "Category:", MUnit:GetDesc().category, self.FilterMeta.Categories[CategoryName], CategoryName } )
      if self.FilterMeta.Categories[CategoryName] and self.FilterMeta.Categories[CategoryName] == MUnit:GetDesc().category then
        MUnitCategory = true
      end
    end
    MUnitInclude = MUnitInclude and MUnitCategory
  end
  
  if self.Filter.Types then
    local MUnitType = false
    for TypeID, TypeName in pairs( self.Filter.Types ) do
      self:T( { "Type:", MUnit:GetTypeName(), TypeName } )
      if TypeName == MUnit:GetTypeName() then
        MUnitType = true
      end
    end
    MUnitInclude = MUnitInclude and MUnitType
  end
  
  if self.Filter.Countries then
    local MUnitCountry = false
    for CountryID, CountryName in pairs( self.Filter.Countries ) do
      self:T( { "Country:", MUnit:GetCountry(), CountryName } )
      if country.id[CountryName] == MUnit:GetCountry() then
        MUnitCountry = true
      end
    end
    MUnitInclude = MUnitInclude and MUnitCountry
  end

  if self.Filter.UnitPrefixes then
    local MUnitPrefix = false
    for UnitPrefixId, UnitPrefix in pairs( self.Filter.UnitPrefixes ) do
      self:T( { "Unit Prefix:", string.find( MUnit:GetName(), UnitPrefix, 1 ), UnitPrefix } )
      if string.find( MUnit:GetName(), UnitPrefix, 1 ) then
        MUnitPrefix = true
      end
    end
    MUnitInclude = MUnitInclude and MUnitPrefix
  end

  self:T( MUnitInclude )
  return MUnitInclude
end


