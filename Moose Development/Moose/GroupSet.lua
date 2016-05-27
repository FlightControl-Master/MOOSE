--- Create and manage a set of groups. 
-- 
-- @{#GROUPSET} class
-- ==================
-- Mission designers can use the GROUPSET class to build sets of groups belonging to certain:
-- 
--  * Coalitions
--  * Categories
--  * Countries
--  * Starting with certain prefix strings.
--  
-- GROUPSET construction methods:
-- =================================
-- Create a new GROUPSET object with the @{#GROUPSET.New} method:
-- 
--    * @{#GROUPSET.New}: Creates a new GROUPSET object.
--   
-- 
-- GROUPSET filter criteria: 
-- =========================
-- You can set filter criteria to define the set of groups within the GROUPSET.
-- Filter criteria are defined by:
-- 
--    * @{#GROUPSET.FilterCoalitions}: Builds the GROUPSET with the groups belonging to the coalition(s).
--    * @{#GROUPSET.FilterCategories}: Builds the GROUPSET with the groups belonging to the category(ies).
--    * @{#GROUPSET.FilterCountries}: Builds the GROUPSET with the gruops belonging to the country(ies).
--    * @{#GROUPSET.FilterPrefixes}: Builds the GROUPSET with the groups starting with the same prefix string(s).
--   
-- Once the filter criteria have been set for the GROUPSET, you can start filtering using:
-- 
--   * @{#GROUPSET.FilterStart}: Starts the filtering of the groups within the GROUPSET.
-- 
-- Planned filter criteria within development are (so these are not yet available):
-- 
--    * @{#GROUPSET.FilterZones}: Builds the GROUPSET with the groups within a @{Zone#ZONE}.
-- 
-- 
-- GROUPSET iterators:
-- ===================
-- Once the filters have been defined and the GROUPSET has been built, you can iterate the GROUPSET with the available iterator methods.
-- The iterator methods will walk the GROUPSET set, and call for each element within the set a function that you provide.
-- The following iterator methods are currently available within the GROUPSET:
-- 
--   * @{#GROUPSET.ForEachGroup}: Calls a function for each alive group it finds within the GROUPSET.
-- 
-- @module GroupSet
-- @author FlightControl

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Group" )
Include.File( "Set" )


--- GROUPSET class
-- @type GROUPSET
-- @extends Set#SET
GROUPSET = {
  ClassName = "GROUPSET",
  Units = {},
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


--- Creates a new GROUPSET object, building a set of groups belonging to a coalitions, categories, countries, types or with defined prefix names.
-- @param #GROUPSET self
-- @return #GROUPSET
-- @usage
-- -- Define a new GROUPSET Object. This DBObject will contain a reference to all alive GROUPS.
-- DBObject = GROUPSET:New()
function GROUPSET:New()

  -- Inherits from BASE
  local self = BASE:Inherit( self, SET:New( _DATABASE.GROUPS ) )

  return self
end


--- Finds a Group based on the Group Name.
-- @param #GROUPSET self
-- @param #string GroupName
-- @return Group#GROUP The found Group.
function GROUPSET:FindUnit( GroupName )

  local GroupFound = self.Set[GroupName]
  return GroupFound
end



--- Builds a set of groups of coalitions.
-- Possible current coalitions are red, blue and neutral.
-- @param #GROUPSET self
-- @param #string Coalitions Can take the following values: "red", "blue", "neutral".
-- @return #GROUPSET self
function GROUPSET:FilterCoalitions( Coalitions )
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
-- @param #GROUPSET self
-- @param #string Categories Can take the following values: "plane", "helicopter", "ground", "ship".
-- @return #GROUPSET self
function GROUPSET:FilterCategories( Categories )
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
-- @param #GROUPSET self
-- @param #string Countries Can take those country strings known within DCS world.
-- @return #GROUPSET self
function GROUPSET:FilterCountries( Countries )
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
-- @param #GROUPSET self
-- @param #string Prefixes The prefix of which the group name starts with.
-- @return #GROUPSET self
function GROUPSET:FilterPrefixes( Prefixes )
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
-- @param #GROUPSET self
-- @return #GROUPSET self
function GROUPSET:FilterStart()

  if _DATABASE then
    self:_FilterStart()
  end
  
  return self
end

--- Handles the Database to check on an event (birth) that the Object was added in the Database.
-- This is required, because sometimes the _DATABASE birth event gets called later than the SET birth event!
-- @param #GROUPSET self
-- @param Event#EVENTDATA Event
-- @return #string The name of the GROUP
-- @return #table The GROUP
function GROUPSET:AddInDatabase( Event )
  self:F3( { Event } )

  if not self.Database[Event.IniDCSGroupName] then
    self.Database[Event.IniDCSGroupName] = GROUP:Register( Event.IniDCSGroupName )
    self:T3( self.Database[Event.IniDCSGroupName] )
  end
  
  return Event.IniDCSGroupName, self.Database[Event.IniDCSGroupName]
end

--- Handles the Database to check on any event that Object exists in the Database.
-- This is required, because sometimes the _DATABASE event gets called later than the SET event or vise versa!
-- @param #GROUPSET self
-- @param Event#EVENTDATA Event
-- @return #string The name of the GROUP
-- @return #table The GROUP
function GROUPSET:FindInDatabase( Event )
  self:F3( { Event } )

  return Event.IniDCSGroupName, self.Database[Event.IniDCSGroupName]
end

--- Interate the GROUPSET and call an interator function for each **alive** GROUP, providing the GROUP and optional parameters.
-- @param #GROUPSET self
-- @param #function IteratorFunction The function that will be called when there is an alive GROUP in the GROUPSET. The function needs to accept a GROUP parameter.
-- @return #GROUPSET self
function GROUPSET:ForEachUnit( IteratorFunction, ... )
  self:F2( arg )
  
  self:ForEach( IteratorFunction, arg, self.Set )

  return self
end


----- Interate the GROUPSET and call an interator function for each **alive** player, providing the Group of the player and optional parameters.
---- @param #GROUPSET self
---- @param #function IteratorFunction The function that will be called when there is an alive player in the GROUPSET. The function needs to accept a GROUP parameter.
---- @return #GROUPSET self
--function GROUPSET:ForEachPlayer( IteratorFunction, ... )
--  self:F2( arg )
--  
--  self:ForEach( IteratorFunction, arg, self.PlayersAlive )
--  
--  return self
--end
--
--
----- Interate the GROUPSET and call an interator function for each client, providing the Client to the function and optional parameters.
---- @param #GROUPSET self
---- @param #function IteratorFunction The function that will be called when there is an alive player in the GROUPSET. The function needs to accept a CLIENT parameter.
---- @return #GROUPSET self
--function GROUPSET:ForEachClient( IteratorFunction, ... )
--  self:F2( arg )
--  
--  self:ForEach( IteratorFunction, arg, self.Clients )
--
--  return self
--end


---
-- @param #GROUPSET self
-- @param Group#GROUP MooseGroup
-- @return #GROUPSET self
function GROUPSET:IsIncludeObject( MooseGroup )
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


