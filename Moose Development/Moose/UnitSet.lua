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
-- @module UnitSet
-- @author FlightControl

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Unit" )
Include.File( "Set" )


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


--- Creates a new UNITSET object, building a set of units belonging to a coalitions, categories, countries, types or with defined prefix names.
-- @param #UNITSET self
-- @return #UNITSET
-- @usage
-- -- Define a new UNITSET Object. This DBObject will contain a reference to all alive Units.
-- DBObject = UNITSET:New()
function UNITSET:New()

  -- Inherits from BASE
  local self = BASE:Inherit( self, SET:New( _DATABASE.UNITS ) )

  return self
end


--- Finds a Unit based on the Unit Name.
-- @param #UNITSET self
-- @param #string UnitName
-- @return Unit#UNIT The found Unit.
function UNITSET:FindUnit( UnitName )

  local UnitFound = self.Set[UnitName]
  return UnitFound
end



--- Builds a set of units of coalitions.
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




--- Starts the filtering.
-- @param #UNITSET self
-- @return #UNITSET self
function UNITSET:FilterStart()

  if _DATABASE then
    self:_FilterStart()
  end
  
  return self
end

--- Handles the Database to check on an event (birth) that the Object was added in the Database.
-- This is required, because sometimes the _DATABASE birth event gets called later than the SET birth event!
-- @param #UNITSET self
-- @param Event#EVENTDATA Event
-- @return #string The name of the UNIT
-- @return #table The UNIT
function UNITSET:AddInDatabase( Event )
  self:F3( { Event } )

  if not self.Database[Event.IniDCSUnitName] then
    self.Database[Event.IniDCSUnitName] = UNIT:Register( Event.IniDCSUnitName )
    self:T3( self.Database[Event.IniDCSUnitName] )
  end
  
  return Event.IniDCSUnitName, self.Database[Event.IniDCSUnitName]
end

--- Handles the Database to check on any event that Object exists in the Database.
-- This is required, because sometimes the _DATABASE event gets called later than the SET event or vise versa!
-- @param #UNITSET self
-- @param Event#EVENTDATA Event
-- @return #string The name of the UNIT
-- @return #table The UNIT
function UNITSET:FindInDatabase( Event )
  self:F3( { Event } )

  return Event.IniDCSUnitName, self.Database[Event.IniDCSUnitName]
end

--- Interate the UNITSET and call an interator function for each **alive** UNIT, providing the UNIT and optional parameters.
-- @param #UNITSET self
-- @param #function IteratorFunction The function that will be called when there is an alive UNIT in the UNITSET. The function needs to accept a UNIT parameter.
-- @return #UNITSET self
function UNITSET:ForEachUnit( IteratorFunction, ... )
  self:F2( arg )
  
  self:ForEach( IteratorFunction, arg, self.Set )

  return self
end


----- Interate the UNITSET and call an interator function for each **alive** player, providing the Unit of the player and optional parameters.
---- @param #UNITSET self
---- @param #function IteratorFunction The function that will be called when there is an alive player in the UNITSET. The function needs to accept a UNIT parameter.
---- @return #UNITSET self
--function UNITSET:ForEachPlayer( IteratorFunction, ... )
--  self:F2( arg )
--  
--  self:ForEach( IteratorFunction, arg, self.PlayersAlive )
--  
--  return self
--end
--
--
----- Interate the UNITSET and call an interator function for each client, providing the Client to the function and optional parameters.
---- @param #UNITSET self
---- @param #function IteratorFunction The function that will be called when there is an alive player in the UNITSET. The function needs to accept a CLIENT parameter.
---- @return #UNITSET self
--function UNITSET:ForEachClient( IteratorFunction, ... )
--  self:F2( arg )
--  
--  self:ForEach( IteratorFunction, arg, self.Clients )
--
--  return self
--end


---
-- @param #UNITSET self
-- @param Unit#UNIT MUnit
-- @return #UNITSET self
function UNITSET:IsIncludeObject( MUnit )
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


