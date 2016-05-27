--- Manage sets of units and groups. 
-- 
-- @{#Set} class
-- ==================
-- Mission designers can use the SET class to build sets of units belonging to certain:
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
-- SET construction methods:
-- =================================
-- Create a new SET object with the @{#SET.New} method:
-- 
--    * @{#SET.New}: Creates a new SET object.
--   
-- 
-- SET filter criteria: 
-- =========================
-- You can set filter criteria to define the set of units within the SET.
-- Filter criteria are defined by:
-- 
--    * @{#SET.FilterCoalitions}: Builds the SET with the units belonging to the coalition(s).
--    * @{#SET.FilterCategories}: Builds the SET with the units belonging to the category(ies).
--    * @{#SET.FilterTypes}: Builds the SET with the units belonging to the unit type(s).
--    * @{#SET.FilterCountries}: Builds the SET with the units belonging to the country(ies).
--    * @{#SET.FilterUnitPrefixes}: Builds the SET with the units starting with the same prefix string(s).
--   
-- Once the filter criteria have been set for the SET, you can start filtering using:
-- 
--   * @{#SET.FilterStart}: Starts the filtering of the units within the SET.
-- 
-- Planned filter criteria within development are (so these are not yet available):
-- 
--    * @{#SET.FilterGroupPrefixes}: Builds the SET with the groups of the units starting with the same prefix string(s).
--    * @{#SET.FilterZones}: Builds the SET with the units within a @{Zone#ZONE}.
-- 
-- 
-- SET iterators:
-- ===================
-- Once the filters have been defined and the SET has been built, you can iterate the SET with the available iterator methods.
-- The iterator methods will walk the SET set, and call for each element within the set a function that you provide.
-- The following iterator methods are currently available within the SET:
-- 
--   * @{#SET.ForEachAliveUnit}: Calls a function for each alive unit it finds within the SET.
--   
-- Planned iterators methods in development are (so these are not yet available):
-- 
--   * @{#SET.ForEachUnit}: Calls a function for each unit contained within the SET.
--   * @{#SET.ForEachGroup}: Calls a function for each group contained within the SET.
--   * @{#SET.ForEachUnitInZone}: Calls a function for each unit within a certain zone contained within the SET.
-- 
-- ====
-- @module Set
-- @author FlightControl

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Menu" )
Include.File( "Group" )
Include.File( "Unit" )
Include.File( "Event" )
Include.File( "Client" )

--- SET class
-- @type SET
-- @extends Base#BASE
SET = {
  ClassName = "SET",
  Set = {},
  Database = {},
}

--- Creates a new SET object, building a set of units belonging to a coalitions, categories, countries, types or with defined prefix names.
-- @param #SET self
-- @return #SET
-- @usage
-- -- Define a new SET Object. This DBObject will contain a reference to all Group and Unit Templates defined within the ME and the DCSRTE.
-- DBObject = SET:New()
function SET:New( Database )

  -- Inherits from BASE
  local self = BASE:Inherit( self, BASE:New() )
  
  self.Database = Database

  return self
end

--- Finds an Object based on the Object Name.
-- @param #SET self
-- @param #string ObjectName
-- @return #table The Object found.
function SET:_Find( ObjectName )

  local ObjectFound = self.Set[ObjectName]
  return ObjectFound
end

--- Adds a Object based on the Object Name.
-- @param #SET self
-- @param #string ObjectName
-- @param #table Object
-- @return #table The added Object.
function SET:_Add( ObjectName, Object )

  self.Set[ObjectName] = Object
end

--- Starts the filtering for the defined collection.
-- @param #SET self
-- @return #SET self
function SET:_FilterStart()

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
---- @param #SET self
---- @return #SET self
--function SET:_RegisterPlayers()
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
-- @param #SET self
-- @param Event#EVENTDATA Event
function SET:_EventOnBirth( Event )
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
-- @param #SET self
-- @param Event#EVENTDATA Event
function SET:_EventOnDeadOrCrash( Event )
  self:F3( { Event } )

  if Event.IniDCSUnit then
    local ObjectName, Object = self:FindInDatabase( Event )
    if ObjectName and Object then
      self:_Delete( ObjectName )
    end
  end
end

----- Handles the OnPlayerEnterUnit event to fill the active players table (with the unit filter applied).
---- @param #SET self
---- @param Event#EVENTDATA Event
--function SET:_EventOnPlayerEnterUnit( Event )
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
---- @param #SET self
---- @param Event#EVENTDATA Event
--function SET:_EventOnPlayerLeaveUnit( Event )
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

--- Iterators

--- Interate the SET and call an interator function for the given set, providing the Object for each element within the set and optional parameters.
-- @param #SET self
-- @param #function IteratorFunction The function that will be called when there is an alive player in the SET.
-- @return #SET self
function SET:ForEach( IteratorFunction, arg, Set )
  self:F3( arg )
  
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


----- Interate the SET and call an interator function for each **alive** unit, providing the Unit and optional parameters.
---- @param #SET self
---- @param #function IteratorFunction The function that will be called when there is an alive unit in the SET. The function needs to accept a UNIT parameter.
---- @return #SET self
--function SET:ForEachDCSUnitAlive( IteratorFunction, ... )
--  self:F3( arg )
--  
--  self:ForEach( IteratorFunction, arg, self.DCSUnitsAlive )
--
--  return self
--end
--
----- Interate the SET and call an interator function for each **alive** player, providing the Unit of the player and optional parameters.
---- @param #SET self
---- @param #function IteratorFunction The function that will be called when there is an alive player in the SET. The function needs to accept a UNIT parameter.
---- @return #SET self
--function SET:ForEachPlayer( IteratorFunction, ... )
--  self:F3( arg )
--  
--  self:ForEach( IteratorFunction, arg, self.PlayersAlive )
--  
--  return self
--end
--
--
----- Interate the SET and call an interator function for each client, providing the Client to the function and optional parameters.
---- @param #SET self
---- @param #function IteratorFunction The function that will be called when there is an alive player in the SET. The function needs to accept a CLIENT parameter.
---- @return #SET self
--function SET:ForEachClient( IteratorFunction, ... )
--  self:F3( arg )
--  
--  self:ForEach( IteratorFunction, arg, self.Clients )
--
--  return self
--end


--- Decides whether to include the Object
-- @param #SET self
-- @param #table Object
-- @return #SET self
function SET:IsIncludeObject( Object )
  self:F3( Object )
  
  return true
end

--- Flushes the current SET contents in the log ... (for debug reasons).
-- @param #SET self
-- @return #SET self
function SET:Flush()
  self:F3()

  local ObjectNames = ""
  for ObjectName, Object in pairs( self.Set ) do
    ObjectNames = ObjectNames .. ObjectName .. ", "
  end
  self:T( { "Objects in Set:", ObjectNames } )
end


