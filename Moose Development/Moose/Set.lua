--- This module contains the SET classes.
-- 
-- ===
-- 
-- 1) @{Set#SET_BASE} class, extends @{Base#BASE}
-- ==============================================
-- The @{Set#SET_BASE} class defines the core functions that define a collection of objects.
-- A SET provides iterators to iterate the SET, but will **temporarily** yield the ForEach interator loop at defined **"intervals"** to the mail simulator loop.
-- In this way, large loops can be done while not blocking the simulator main processing loop.
-- The default **"yield interval"** is after 10 objects processed.
-- The default **"time interval"** is after 0.001 seconds.
-- 
-- 1.1) Add or remove objects from the SET
-- ---------------------------------------
-- Some key core functions are @{Set#SET_BASE.Add} and @{Set#SET_BASE.Remove} to add or remove objects from the SET in your logic.
-- 
-- 1.2) Define the SET iterator **"yield interval"** and the **"time interval"**
-- -----------------------------------------------------------------------------
-- Modify the iterator intervals with the @{Set#SET_BASE.SetInteratorIntervals} method.
-- You can set the **"yield interval"**, and the **"time interval"**. (See above).
-- 
-- ===
-- 
-- 2) @{Set#SET_GROUP} class, extends @{Set#SET_BASE}
-- ==================================================
-- Mission designers can use the @{Set#SET_GROUP} class to build sets of groups belonging to certain:
-- 
--  * Coalitions
--  * Categories
--  * Countries
--  * Starting with certain prefix strings.
--  
-- 2.1) SET_GROUP construction method:
-- -----------------------------------
-- Create a new SET_GROUP object with the @{#SET_GROUP.New} method:
-- 
--    * @{#SET_GROUP.New}: Creates a new SET_GROUP object.
-- 
-- 2.2) Add or Remove GROUP(s) from SET_GROUP: 
-- -------------------------------------------
-- GROUPS can be added and removed using the @{Set#SET_GROUP.AddGroupsByName} and @{Set#SET_GROUP.RemoveGroupsByName} respectively. 
-- These methods take a single GROUP name or an array of GROUP names to be added or removed from SET_GROUP.
-- 
-- 2.3) SET_GROUP filter criteria: 
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
--    * @{#SET_GROUP.FilterStart}: Starts the filtering of the groups within the SET_GROUP and add or remove GROUP objects **dynamically**.
-- 
-- Planned filter criteria within development are (so these are not yet available):
-- 
--    * @{#SET_GROUP.FilterZones}: Builds the SET_GROUP with the groups within a @{Zone#ZONE}.
-- 
-- 2.4) SET_GROUP iterators:
-- -------------------------
-- Once the filters have been defined and the SET_GROUP has been built, you can iterate the SET_GROUP with the available iterator methods.
-- The iterator methods will walk the SET_GROUP set, and call for each element within the set a function that you provide.
-- The following iterator methods are currently available within the SET_GROUP:
-- 
--   * @{#SET_GROUP.ForEachGroup}: Calls a function for each alive group it finds within the SET_GROUP.
--   * @{#SET_GROUP.ForEachGroupCompletelyInZone}: Iterate the SET_GROUP and call an iterator function for each **alive** GROUP presence completely in a @{Zone}, providing the GROUP and optional parameters to the called function.
--   * @{#SET_GROUP.ForEachGroupPartlyInZone}: Iterate the SET_GROUP and call an iterator function for each **alive** GROUP presence partly in a @{Zone}, providing the GROUP and optional parameters to the called function.
--   * @{#SET_GROUP.ForEachGroupNotInZone}: Iterate the SET_GROUP and call an iterator function for each **alive** GROUP presence not in a @{Zone}, providing the GROUP and optional parameters to the called function.
-- 
-- ====
-- 
-- 3) @{Set#SET_UNIT} class, extends @{Set#SET_BASE}
-- ===================================================
-- Mission designers can use the @{Set#SET_UNIT} class to build sets of units belonging to certain:
-- 
--  * Coalitions
--  * Categories
--  * Countries
--  * Unit types
--  * Starting with certain prefix strings.
--  
-- 3.1) SET_UNIT construction method:
-- ----------------------------------
-- Create a new SET_UNIT object with the @{#SET_UNIT.New} method:
-- 
--    * @{#SET_UNIT.New}: Creates a new SET_UNIT object.
--   
-- 3.2) Add or Remove UNIT(s) from SET_UNIT: 
-- -----------------------------------------
-- UNITs can be added and removed using the @{Set#SET_UNIT.AddUnitsByName} and @{Set#SET_UNIT.RemoveUnitsByName} respectively. 
-- These methods take a single UNIT name or an array of UNIT names to be added or removed from SET_UNIT.
-- 
-- 3.3) SET_UNIT filter criteria: 
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
-- 3.4) SET_UNIT iterators:
-- ------------------------
-- Once the filters have been defined and the SET_UNIT has been built, you can iterate the SET_UNIT with the available iterator methods.
-- The iterator methods will walk the SET_UNIT set, and call for each element within the set a function that you provide.
-- The following iterator methods are currently available within the SET_UNIT:
-- 
--   * @{#SET_UNIT.ForEachUnit}: Calls a function for each alive unit it finds within the SET_UNIT.
--   * @{#SET_GROUP.ForEachGroupCompletelyInZone}: Iterate the SET_GROUP and call an iterator function for each **alive** GROUP presence completely in a @{Zone}, providing the GROUP and optional parameters to the called function.
--   * @{#SET_GROUP.ForEachGroupNotInZone}: Iterate the SET_GROUP and call an iterator function for each **alive** GROUP presence not in a @{Zone}, providing the GROUP and optional parameters to the called function.
--   
-- Planned iterators methods in development are (so these are not yet available):
-- 
--   * @{#SET_UNIT.ForEachUnitInUnit}: Calls a function for each unit contained within the SET_UNIT.
--   * @{#SET_UNIT.ForEachUnitCompletelyInZone}: Iterate and call an iterator function for each **alive** UNIT presence completely in a @{Zone}, providing the UNIT and optional parameters to the called function.
--   * @{#SET_UNIT.ForEachUnitNotInZone}: Iterate and call an iterator function for each **alive** UNIT presence not in a @{Zone}, providing the UNIT and optional parameters to the called function.
-- 
-- ===
-- 
-- 4) @{Set#SET_CLIENT} class, extends @{Set#SET_BASE}
-- ===================================================
-- Mission designers can use the @{Set#SET_CLIENT} class to build sets of units belonging to certain:
-- 
--  * Coalitions
--  * Categories
--  * Countries
--  * Client types
--  * Starting with certain prefix strings.
--  
-- 4.1) SET_CLIENT construction method:
-- ----------------------------------
-- Create a new SET_CLIENT object with the @{#SET_CLIENT.New} method:
-- 
--    * @{#SET_CLIENT.New}: Creates a new SET_CLIENT object.
--   
-- 4.2) Add or Remove CLIENT(s) from SET_CLIENT: 
-- -----------------------------------------
-- CLIENTs can be added and removed using the @{Set#SET_CLIENT.AddClientsByName} and @{Set#SET_CLIENT.RemoveClientsByName} respectively. 
-- These methods take a single CLIENT name or an array of CLIENT names to be added or removed from SET_CLIENT.
-- 
-- 4.3) SET_CLIENT filter criteria: 
-- ------------------------------
-- You can set filter criteria to define the set of clients within the SET_CLIENT.
-- Filter criteria are defined by:
-- 
--    * @{#SET_CLIENT.FilterCoalitions}: Builds the SET_CLIENT with the clients belonging to the coalition(s).
--    * @{#SET_CLIENT.FilterCategories}: Builds the SET_CLIENT with the clients belonging to the category(ies).
--    * @{#SET_CLIENT.FilterTypes}: Builds the SET_CLIENT with the clients belonging to the client type(s).
--    * @{#SET_CLIENT.FilterCountries}: Builds the SET_CLIENT with the clients belonging to the country(ies).
--    * @{#SET_CLIENT.FilterPrefixes}: Builds the SET_CLIENT with the clients starting with the same prefix string(s).
--   
-- Once the filter criteria have been set for the SET_CLIENT, you can start filtering using:
-- 
--   * @{#SET_CLIENT.FilterStart}: Starts the filtering of the clients within the SET_CLIENT.
-- 
-- Planned filter criteria within development are (so these are not yet available):
-- 
--    * @{#SET_CLIENT.FilterZones}: Builds the SET_CLIENT with the clients within a @{Zone#ZONE}.
-- 
-- 4.4) SET_CLIENT iterators:
-- ------------------------
-- Once the filters have been defined and the SET_CLIENT has been built, you can iterate the SET_CLIENT with the available iterator methods.
-- The iterator methods will walk the SET_CLIENT set, and call for each element within the set a function that you provide.
-- The following iterator methods are currently available within the SET_CLIENT:
-- 
--   * @{#SET_CLIENT.ForEachClient}: Calls a function for each alive client it finds within the SET_CLIENT.
-- 
-- ====
-- 
-- 5) @{Set#SET_AIRBASE} class, extends @{Set#SET_BASE}
-- ====================================================
-- Mission designers can use the @{Set#SET_AIRBASE} class to build sets of airbases optionally belonging to certain:
-- 
--  * Coalitions
--  
-- 5.1) SET_AIRBASE construction
-- -----------------------------
-- Create a new SET_AIRBASE object with the @{#SET_AIRBASE.New} method:
-- 
--    * @{#SET_AIRBASE.New}: Creates a new SET_AIRBASE object.
--   
-- 5.2) Add or Remove AIRBASEs from SET_AIRBASE 
-- --------------------------------------------
-- AIRBASEs can be added and removed using the @{Set#SET_AIRBASE.AddAirbasesByName} and @{Set#SET_AIRBASE.RemoveAirbasesByName} respectively. 
-- These methods take a single AIRBASE name or an array of AIRBASE names to be added or removed from SET_AIRBASE.
-- 
-- 5.3) SET_AIRBASE filter criteria 
-- --------------------------------
-- You can set filter criteria to define the set of clients within the SET_AIRBASE.
-- Filter criteria are defined by:
-- 
--    * @{#SET_AIRBASE.FilterCoalitions}: Builds the SET_AIRBASE with the airbases belonging to the coalition(s).
--   
-- Once the filter criteria have been set for the SET_AIRBASE, you can start filtering using:
-- 
--   * @{#SET_AIRBASE.FilterStart}: Starts the filtering of the airbases within the SET_AIRBASE.
-- 
-- 5.4) SET_AIRBASE iterators:
-- ---------------------------
-- Once the filters have been defined and the SET_AIRBASE has been built, you can iterate the SET_AIRBASE with the available iterator methods.
-- The iterator methods will walk the SET_AIRBASE set, and call for each airbase within the set a function that you provide.
-- The following iterator methods are currently available within the SET_AIRBASE:
-- 
--   * @{#SET_AIRBASE.ForEachAirbase}: Calls a function for each airbase it finds within the SET_AIRBASE.
-- 
-- ====
-- 
-- ### Contributions: 
-- 
--   * Mechanist : Concept & Testing
-- 
-- ### Authors: 
-- 
--   * FlightControl : Design & Programming
-- 
-- @module Set


--- SET_BASE class
-- @type SET_BASE
-- @field #table Filter
-- @field #table Set
-- @field #table List
-- @extends Base#BASE
SET_BASE = {
  ClassName = "SET_BASE",
  Filter = {},
  Set = {},
  List = {},
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

  self.YieldInterval = 10
  self.TimeInterval = 0.001

  self.List = {}
  self.List.__index = self.List
  self.List = setmetatable( { Count = 0 }, self.List )

  return self
end

--- Finds an @{Base#BASE} object based on the object Name.
-- @param #SET_BASE self
-- @param #string ObjectName
-- @return Base#BASE The Object found.
function SET_BASE:_Find( ObjectName )

  local ObjectFound = self.Set[ObjectName]
  return ObjectFound
end


--- Gets the Set.
-- @param #SET_BASE self
-- @return #SET_BASE self
function SET_BASE:GetSet()
	self:F2()
	
  return self.Set
end

--- Adds a @{Base#BASE} object in the @{Set#SET_BASE}, using the Object Name as the index.
-- @param #SET_BASE self
-- @param #string ObjectName
-- @param Base#BASE Object
-- @return Base#BASE The added BASE Object.
function SET_BASE:Add( ObjectName, Object )
  self:F2( ObjectName )

  local t = { _ = Object }

  if self.List.last then
    self.List.last._next = t
    t._prev = self.List.last
    self.List.last = t
  else
    -- this is the first node
    self.List.first = t
    self.List.last = t
  end
  
  self.List.Count = self.List.Count + 1
  
  self.Set[ObjectName] = t._
  
end

--- Removes a @{Base#BASE} object from the @{Set#SET_BASE} and derived classes, based on the Object Name.
-- @param #SET_BASE self
-- @param #string ObjectName
function SET_BASE:Remove( ObjectName )
  self:F( ObjectName )

  local t = self.Set[ObjectName]
  
  self:E( { ObjectName, t } )

  if t then  
    if t._next then
      if t._prev then
        t._next._prev = t._prev
        t._prev._next = t._next
      else
        -- this was the first node
        t._next._prev = nil
        self.List._first = t._next
      end
    elseif t._prev then
      -- this was the last node
      t._prev._next = nil
      self.List._last = t._prev
    else
      -- this was the only node
      self.List._first = nil
      self.List._last = nil
    end
  
    t._next = nil
    t._prev = nil
    self.List.Count = self.List.Count - 1
    
    self.Set[ObjectName] = nil
  end
  
end

--- Retrieves the amount of objects in the @{Set#SET_BASE} and derived classes.
-- @param #SET_BASE self
-- @return #number Count
function SET_BASE:Count()

  return self.List.Count
end



--- Copies the Filter criteria from a given Set (for rebuilding a new Set based on an existing Set).
-- @param #SET_BASE self
-- @param #SET_BASE BaseSet
-- @return #SET_BASE
function SET_BASE:SetDatabase( BaseSet )

  -- Copy the filter criteria of the BaseSet
  local OtherFilter = routines.utils.deepCopy( BaseSet.Filter )
  self.Filter = OtherFilter
  
  -- Now base the new Set on the BaseSet
  self.Database = BaseSet:GetSet()
  return self
end



--- Define the SET iterator **"yield interval"** and the **"time interval"**.
-- @param #SET_BASE self
-- @param #number YieldInterval Sets the frequency when the iterator loop will yield after the number of objects processed. The default frequency is 10 objects processed.
-- @param #number TimeInterval Sets the time in seconds when the main logic will resume the iterator loop. The default time is 0.001 seconds.
-- @return #SET_BASE self
function SET_BASE:SetIteratorIntervals( YieldInterval, TimeInterval )

  self.YieldInterval = YieldInterval
  self.TimeInterval = TimeInterval
  
  return self
end


--- Filters for the defined collection.
-- @param #SET_BASE self
-- @return #SET_BASE self
function SET_BASE:FilterOnce()

  for ObjectName, Object in pairs( self.Database ) do

    if self:IsIncludeObject( Object ) then
      self:Add( ObjectName, Object )
    end
  end
  
  return self
end

--- Starts the filtering for the defined collection.
-- @param #SET_BASE self
-- @return #SET_BASE self
function SET_BASE:_FilterStart()

  for ObjectName, Object in pairs( self.Database ) do

    if self:IsIncludeObject( Object ) then
      self:E( { "Adding Object:", ObjectName } )
      self:Add( ObjectName, Object )
    end
  end
  
  _EVENTDISPATCHER:OnBirth( self._EventOnBirth, self )
  _EVENTDISPATCHER:OnDead( self._EventOnDeadOrCrash, self )
  _EVENTDISPATCHER:OnCrash( self._EventOnDeadOrCrash, self )
  
  -- Follow alive players and clients
  _EVENTDISPATCHER:OnPlayerEnterUnit( self._EventOnPlayerEnterUnit, self )
  _EVENTDISPATCHER:OnPlayerLeaveUnit( self._EventOnPlayerLeaveUnit, self )
  
  
  return self
end

--- Stops the filtering for the defined collection.
-- @param #SET_BASE self
-- @return #SET_BASE self
function SET_BASE:FilterStop()

  _EVENTDISPATCHER:OnBirthRemove( self )
  _EVENTDISPATCHER:OnDeadRemove( self )
  _EVENTDISPATCHER:OnCrashRemove( self )
  
  return self
end

--- Iterate the SET_BASE while identifying the nearest object from a @{Point#POINT_VEC2}.
-- @param #SET_BASE self
-- @param Point#POINT_VEC2 PointVec2 A @{Point#POINT_VEC2} object from where to evaluate the closest object in the set.
-- @return Base#BASE The closest object.
function SET_BASE:FindNearestObjectFromPointVec2( PointVec2 )
  self:F2( PointVec2 )
  
  local NearestObject = nil
  local ClosestDistance = nil
  
  for ObjectID, ObjectData in pairs( self.Set ) do
    if NearestObject == nil then
      NearestObject = ObjectData
      ClosestDistance = PointVec2:DistanceFromVec2( ObjectData:GetVec2() )
    else
      local Distance = PointVec2:DistanceFromVec2( ObjectData:GetVec2() )
      if Distance < ClosestDistance then
        NearestObject = ObjectData
        ClosestDistance = Distance
      end
    end
  end
  
  return NearestObject
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
      self:Add( ObjectName, Object )
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
    if ObjectName and Object ~= nil then
      self:Remove( ObjectName )
    end
  end
end

--- Handles the OnPlayerEnterUnit event to fill the active players table (with the unit filter applied).
-- @param #SET_BASE self
-- @param Event#EVENTDATA Event
function SET_BASE:_EventOnPlayerEnterUnit( Event )
  self:F3( { Event } )

  if Event.IniDCSUnit then
    local ObjectName, Object = self:AddInDatabase( Event )
    self:T3( ObjectName, Object )
    if self:IsIncludeObject( Object ) then
      self:Add( ObjectName, Object )
      --self:_EventOnPlayerEnterUnit( Event )
    end
  end
end

--- Handles the OnPlayerLeaveUnit event to clean the active players table.
-- @param #SET_BASE self
-- @param Event#EVENTDATA Event
function SET_BASE:_EventOnPlayerLeaveUnit( Event )
  self:F3( { Event } )

  local ObjectName = Event.IniDCSUnit
  if Event.IniDCSUnit then
    if Event.IniDCSGroup then
      local GroupUnits = Event.IniDCSGroup:getUnits()
      local PlayerCount = 0
      for _, DCSUnit in pairs( GroupUnits ) do
        if DCSUnit ~= Event.IniDCSUnit then
          if DCSUnit:getPlayer() ~= nil then
            PlayerCount = PlayerCount + 1
          end
        end
      end
      self:E(PlayerCount)
      if PlayerCount == 0 then
        self:Remove( Event.IniDCSGroupName )
      end
    end
  end
end

-- Iterators

--- Iterate the SET_BASE and derived classes and call an iterator function for the given SET_BASE, providing the Object for each element within the set and optional parameters.
-- @param #SET_BASE self
-- @param #function IteratorFunction The function that will be called.
-- @return #SET_BASE self
function SET_BASE:ForEach( IteratorFunction, arg, Set, Function, FunctionArguments )
  self:F3( arg )
  
  local function CoRoutine()
    local Count = 0
    for ObjectID, ObjectData in pairs( Set ) do
      local Object = ObjectData
        self:T3( Object )
        if Function then
          if Function( unpack( FunctionArguments ), Object ) == true then
            IteratorFunction( Object, unpack( arg ) )
          end
        else
          IteratorFunction( Object, unpack( arg ) )
        end
        Count = Count + 1
--        if Count % self.YieldInterval == 0 then
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
    
    return false
  end

  local Scheduler = SCHEDULER:New( self, Schedule, {}, self.TimeInterval, self.TimeInterval, 0 )
  
  return self
end


----- Iterate the SET_BASE and call an interator function for each **alive** unit, providing the Unit and optional parameters.
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
----- Iterate the SET_BASE and call an interator function for each **alive** player, providing the Unit of the player and optional parameters.
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
----- Iterate the SET_BASE and call an interator function for each client, providing the Client to the function and optional parameters.
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

--- Flushes the current SET_BASE contents in the log ... (for debugging reasons).
-- @param #SET_BASE self
-- @return #string A string with the names of the objects.
function SET_BASE:Flush()
  self:F3()

  local ObjectNames = ""
  for ObjectName, Object in pairs( self.Set ) do
    ObjectNames = ObjectNames .. ObjectName .. ", "
  end
  self:E( { "Objects in Set:", ObjectNames } )
  
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

--- Add GROUP(s) to SET_GROUP.
-- @param Set#SET_GROUP self
-- @param #string AddGroupNames A single name or an array of GROUP names.
-- @return self
function SET_GROUP:AddGroupsByName( AddGroupNames )

  local AddGroupNamesArray = ( type( AddGroupNames ) == "table" ) and AddGroupNames or { AddGroupNames }
  
  for AddGroupID, AddGroupName in pairs( AddGroupNamesArray ) do
    self:Add( AddGroupName, GROUP:FindByName( AddGroupName ) )
  end
    
  return self
end

--- Remove GROUP(s) from SET_GROUP.
-- @param Set#SET_GROUP self
-- @param Group#GROUP RemoveGroupNames A single name or an array of GROUP names.
-- @return self
function SET_GROUP:RemoveGroupsByName( RemoveGroupNames )

  local RemoveGroupNamesArray = ( type( RemoveGroupNames ) == "table" ) and RemoveGroupNames or { RemoveGroupNames }
  
  for RemoveGroupID, RemoveGroupName in pairs( RemoveGroupNamesArray ) do
    self:Remove( RemoveGroupName.GroupName )
  end
    
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


----- Iterate the SET_GROUP and call an interator function for each **alive** player, providing the Group of the player and optional parameters.
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
----- Iterate the SET_GROUP and call an interator function for each client, providing the Client to the function and optional parameters.
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

--- Add UNIT(s) to SET_UNIT.
-- @param #SET_UNIT self
-- @param #string AddUnit A single UNIT.
-- @return #SET_UNIT self
function SET_UNIT:AddUnit( AddUnit )
  self:F2( AddUnit:GetName() )

  self:Add( AddUnit:GetName(), AddUnit )
    
  return self
end


--- Add UNIT(s) to SET_UNIT.
-- @param #SET_UNIT self
-- @param #string AddUnitNames A single name or an array of UNIT names.
-- @return #SET_UNIT self
function SET_UNIT:AddUnitsByName( AddUnitNames )

  local AddUnitNamesArray = ( type( AddUnitNames ) == "table" ) and AddUnitNames or { AddUnitNames }
  
  self:T( AddUnitNamesArray )
  for AddUnitID, AddUnitName in pairs( AddUnitNamesArray ) do
    self:Add( AddUnitName, UNIT:FindByName( AddUnitName ) )
  end
    
  return self
end

--- Remove UNIT(s) from SET_UNIT.
-- @param Set#SET_UNIT self
-- @param Unit#UNIT RemoveUnitNames A single name or an array of UNIT names.
-- @return self
function SET_UNIT:RemoveUnitsByName( RemoveUnitNames )

  local RemoveUnitNamesArray = ( type( RemoveUnitNames ) == "table" ) and RemoveUnitNames or { RemoveUnitNames }
  
  for RemoveUnitID, RemoveUnitName in pairs( RemoveUnitNamesArray ) do
    self:Remove( RemoveUnitName )
  end
    
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

--- Builds a set of units having a radar of give types.
-- All the units having a radar of a given type will be included within the set.
-- @param #SET_UNIT self
-- @param #table RadarTypes The radar types.
-- @return #SET_UNIT self
function SET_UNIT:FilterHasRadar( RadarTypes )

  self.Filter.RadarTypes = self.Filter.RadarTypes or {}
  if type( RadarTypes ) ~= "table" then
    RadarTypes = { RadarTypes }
  end
  for RadarTypeID, RadarType in pairs( RadarTypes ) do
    self.Filter.RadarTypes[RadarType] = RadarType
  end
  return self
end

--- Builds a set of SEADable units.
-- @param #SET_UNIT self
-- @return #SET_UNIT self
function SET_UNIT:FilterHasSEAD()

  self.Filter.SEAD = true
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
  self:E( { Event.IniDCSUnitName, self.Set[Event.IniDCSUnitName], Event } )


  return Event.IniDCSUnitName, self.Set[Event.IniDCSUnitName]
end

--- Iterate the SET_UNIT and call an interator function for each **alive** UNIT, providing the UNIT and optional parameters.
-- @param #SET_UNIT self
-- @param #function IteratorFunction The function that will be called when there is an alive UNIT in the SET_UNIT. The function needs to accept a UNIT parameter.
-- @return #SET_UNIT self
function SET_UNIT:ForEachUnit( IteratorFunction, ... )
  self:F2( arg )
  
  self:ForEach( IteratorFunction, arg, self.Set )

  return self
end

--- Iterate the SET_UNIT and call an iterator function for each **alive** UNIT presence completely in a @{Zone}, providing the UNIT and optional parameters to the called function.
-- @param #SET_UNIT self
-- @param Zone#ZONE ZoneObject The Zone to be tested for.
-- @param #function IteratorFunction The function that will be called when there is an alive UNIT in the SET_UNIT. The function needs to accept a UNIT parameter.
-- @return #SET_UNIT self
function SET_UNIT:ForEachUnitCompletelyInZone( ZoneObject, IteratorFunction, ... )
  self:F2( arg )
  
  self:ForEach( IteratorFunction, arg, self.Set,
    --- @param Zone#ZONE_BASE ZoneObject
    -- @param Unit#UNIT UnitObject
    function( ZoneObject, UnitObject )
      if UnitObject:IsCompletelyInZone( ZoneObject ) then
        return true
      else
        return false
      end
    end, { ZoneObject } )

  return self
end

--- Iterate the SET_UNIT and call an iterator function for each **alive** UNIT presence not in a @{Zone}, providing the UNIT and optional parameters to the called function.
-- @param #SET_UNIT self
-- @param Zone#ZONE ZoneObject The Zone to be tested for.
-- @param #function IteratorFunction The function that will be called when there is an alive UNIT in the SET_UNIT. The function needs to accept a UNIT parameter.
-- @return #SET_UNIT self
function SET_UNIT:ForEachUnitNotInZone( ZoneObject, IteratorFunction, ... )
  self:F2( arg )
  
  self:ForEach( IteratorFunction, arg, self.Set,
    --- @param Zone#ZONE_BASE ZoneObject
    -- @param Unit#UNIT UnitObject
    function( ZoneObject, UnitObject )
      if UnitObject:IsNotInZone( ZoneObject ) then
        return true
      else
        return false
      end
    end, { ZoneObject } )

  return self
end

--- Returns map of unit types.
-- @param #SET_UNIT self
-- @return #map<#string,#number> A map of the unit types found. The key is the UnitTypeName and the value is the amount of unit types found.
function SET_UNIT:GetUnitTypes()
  self:F2()

  local MT = {} -- Message Text
  local UnitTypes = {}
  
  for UnitID, UnitData in pairs( self:GetSet() ) do
    local TextUnit = UnitData -- Unit#UNIT
    if TextUnit:IsAlive() then
      local UnitType = TextUnit:GetTypeName()
  
      if not UnitTypes[UnitType] then
        UnitTypes[UnitType] = 1
      else
        UnitTypes[UnitType] = UnitTypes[UnitType] + 1
      end
    end
  end

  for UnitTypeID, UnitType in pairs( UnitTypes ) do
    MT[#MT+1] = UnitType .. " of " .. UnitTypeID
  end

  return UnitTypes
end


--- Returns a comma separated string of the unit types with a count in the  @{Set}.
-- @param #SET_UNIT self
-- @return #string The unit types string
function SET_UNIT:GetUnitTypesText()
  self:F2()

  local MT = {} -- Message Text
  local UnitTypes = self:GetUnitTypes()
  
  for UnitTypeID, UnitType in pairs( UnitTypes ) do
    MT[#MT+1] = UnitType .. " of " .. UnitTypeID
  end

  return table.concat( MT, ", " )
end

--- Returns map of unit threat levels.
-- @param #SET_UNIT self
-- @return #table.
function SET_UNIT:GetUnitThreatLevels()
  self:F2()

  local UnitThreatLevels = {}
  
  for UnitID, UnitData in pairs( self:GetSet() ) do
    local ThreatUnit = UnitData -- Unit#UNIT
    if ThreatUnit:IsAlive() then
      local UnitThreatLevel, UnitThreatLevelText = ThreatUnit:GetThreatLevel()
      local ThreatUnitName = ThreatUnit:GetName()
  
      UnitThreatLevels[UnitThreatLevel] = UnitThreatLevels[UnitThreatLevel] or {}
      UnitThreatLevels[UnitThreatLevel].UnitThreatLevelText = UnitThreatLevelText
      UnitThreatLevels[UnitThreatLevel].Units = UnitThreatLevels[UnitThreatLevel].Units or {}
      UnitThreatLevels[UnitThreatLevel].Units[ThreatUnitName] = ThreatUnit
    end
  end

  return UnitThreatLevels
end

--- Returns if the @{Set} has targets having a radar (of a given type).
-- @param #SET_UNIT self
-- @param DCSUnit#Unit.RadarType RadarType
-- @return #number The amount of radars in the Set with the given type
function SET_UNIT:HasRadar( RadarType )
  self:F2( RadarType )

  local RadarCount = 0
  for UnitID, UnitData in pairs( self:GetSet()) do
    local UnitSensorTest = UnitData -- Unit#UNIT
    local HasSensors
    if RadarType then
      HasSensors = UnitSensorTest:HasSensors( Unit.SensorType.RADAR, RadarType )
    else
      HasSensors = UnitSensorTest:HasSensors( Unit.SensorType.RADAR )
    end
    self:T3(HasSensors)
    if HasSensors then
      RadarCount = RadarCount + 1
    end
  end

  return RadarCount
end

--- Returns if the @{Set} has targets that can be SEADed.
-- @param #SET_UNIT self
-- @return #number The amount of SEADable units in the Set
function SET_UNIT:HasSEAD()
  self:F2()

  local SEADCount = 0
  for UnitID, UnitData in pairs( self:GetSet()) do
    local UnitSEAD = UnitData -- Unit#UNIT
    if UnitSEAD:IsAlive() then
      local UnitSEADAttributes = UnitSEAD:GetDesc().attributes
  
      local HasSEAD = UnitSEAD:HasSEAD()
         
      self:T3(HasSEAD)
      if HasSEAD then
        SEADCount = SEADCount + 1
      end
    end
  end

  return SEADCount
end

--- Returns if the @{Set} has ground targets.
-- @param #SET_UNIT self
-- @return #number The amount of ground targets in the Set.
function SET_UNIT:HasGroundUnits()
  self:F2()

  local GroundUnitCount = 0
  for UnitID, UnitData in pairs( self:GetSet()) do
    local UnitTest = UnitData -- Unit#UNIT
    if UnitTest:IsGround() then
      GroundUnitCount = GroundUnitCount + 1
    end
  end

  return GroundUnitCount
end

--- Returns if the @{Set} has friendly ground units.
-- @param #SET_UNIT self
-- @return #number The amount of ground targets in the Set.
function SET_UNIT:HasFriendlyUnits( FriendlyCoalition )
  self:F2()

  local FriendlyUnitCount = 0
  for UnitID, UnitData in pairs( self:GetSet()) do
    local UnitTest = UnitData -- Unit#UNIT
    if UnitTest:IsFriendly( FriendlyCoalition ) then
      FriendlyUnitCount = FriendlyUnitCount + 1
    end
  end

  return FriendlyUnitCount
end



----- Iterate the SET_UNIT and call an interator function for each **alive** player, providing the Unit of the player and optional parameters.
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
----- Iterate the SET_UNIT and call an interator function for each client, providing the Client to the function and optional parameters.
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

  if self.Filter.RadarTypes then
    local MUnitRadar = false
    for RadarTypeID, RadarType in pairs( self.Filter.RadarTypes ) do
      self:T3( { "Radar:", RadarType } )
      if MUnit:HasSensors( Unit.SensorType.RADAR, RadarType ) == true then
        if MUnit:GetRadar() == true then -- This call is necessary to evaluate the SEAD capability.
          self:T3( "RADAR Found" )
        end
        MUnitRadar = true
      end
    end
    MUnitInclude = MUnitInclude and MUnitRadar
  end

  if self.Filter.SEAD then
    local MUnitSEAD = false
    if MUnit:HasSEAD() == true then
      self:T3( "SEAD Found" )
      MUnitSEAD = true
    end
    MUnitInclude = MUnitInclude and MUnitSEAD
  end

  self:T2( MUnitInclude )
  return MUnitInclude
end


--- SET_CLIENT

--- SET_CLIENT class
-- @type SET_CLIENT
-- @extends Set#SET_BASE
SET_CLIENT = {
  ClassName = "SET_CLIENT",
  Clients = {},
  Filter = {
    Coalitions = nil,
    Categories = nil,
    Types = nil,
    Countries = nil,
    ClientPrefixes = nil,
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


--- Creates a new SET_CLIENT object, building a set of clients belonging to a coalitions, categories, countries, types or with defined prefix names.
-- @param #SET_CLIENT self
-- @return #SET_CLIENT
-- @usage
-- -- Define a new SET_CLIENT Object. This DBObject will contain a reference to all Clients.
-- DBObject = SET_CLIENT:New()
function SET_CLIENT:New()
  -- Inherits from BASE
  local self = BASE:Inherit( self, SET_BASE:New( _DATABASE.CLIENTS ) )

  return self
end

--- Add CLIENT(s) to SET_CLIENT.
-- @param Set#SET_CLIENT self
-- @param #string AddClientNames A single name or an array of CLIENT names.
-- @return self
function SET_CLIENT:AddClientsByName( AddClientNames )

  local AddClientNamesArray = ( type( AddClientNames ) == "table" ) and AddClientNames or { AddClientNames }
  
  for AddClientID, AddClientName in pairs( AddClientNamesArray ) do
    self:Add( AddClientName, CLIENT:FindByName( AddClientName ) )
  end
    
  return self
end

--- Remove CLIENT(s) from SET_CLIENT.
-- @param Set#SET_CLIENT self
-- @param Client#CLIENT RemoveClientNames A single name or an array of CLIENT names.
-- @return self
function SET_CLIENT:RemoveClientsByName( RemoveClientNames )

  local RemoveClientNamesArray = ( type( RemoveClientNames ) == "table" ) and RemoveClientNames or { RemoveClientNames }
  
  for RemoveClientID, RemoveClientName in pairs( RemoveClientNamesArray ) do
    self:Remove( RemoveClientName.ClientName )
  end
    
  return self
end


--- Finds a Client based on the Client Name.
-- @param #SET_CLIENT self
-- @param #string ClientName
-- @return Client#CLIENT The found Client.
function SET_CLIENT:FindClient( ClientName )

  local ClientFound = self.Set[ClientName]
  return ClientFound
end



--- Builds a set of clients of coalitions.
-- Possible current coalitions are red, blue and neutral.
-- @param #SET_CLIENT self
-- @param #string Coalitions Can take the following values: "red", "blue", "neutral".
-- @return #SET_CLIENT self
function SET_CLIENT:FilterCoalitions( Coalitions )
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


--- Builds a set of clients out of categories.
-- Possible current categories are plane, helicopter, ground, ship.
-- @param #SET_CLIENT self
-- @param #string Categories Can take the following values: "plane", "helicopter", "ground", "ship".
-- @return #SET_CLIENT self
function SET_CLIENT:FilterCategories( Categories )
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


--- Builds a set of clients of defined client types.
-- Possible current types are those types known within DCS world.
-- @param #SET_CLIENT self
-- @param #string Types Can take those type strings known within DCS world.
-- @return #SET_CLIENT self
function SET_CLIENT:FilterTypes( Types )
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


--- Builds a set of clients of defined countries.
-- Possible current countries are those known within DCS world.
-- @param #SET_CLIENT self
-- @param #string Countries Can take those country strings known within DCS world.
-- @return #SET_CLIENT self
function SET_CLIENT:FilterCountries( Countries )
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


--- Builds a set of clients of defined client prefixes.
-- All the clients starting with the given prefixes will be included within the set.
-- @param #SET_CLIENT self
-- @param #string Prefixes The prefix of which the client name starts with.
-- @return #SET_CLIENT self
function SET_CLIENT:FilterPrefixes( Prefixes )
  if not self.Filter.ClientPrefixes then
    self.Filter.ClientPrefixes = {}
  end
  if type( Prefixes ) ~= "table" then
    Prefixes = { Prefixes }
  end
  for PrefixID, Prefix in pairs( Prefixes ) do
    self.Filter.ClientPrefixes[Prefix] = Prefix
  end
  return self
end




--- Starts the filtering.
-- @param #SET_CLIENT self
-- @return #SET_CLIENT self
function SET_CLIENT:FilterStart()

  if _DATABASE then
    self:_FilterStart()
  end
  
  return self
end

--- Handles the Database to check on an event (birth) that the Object was added in the Database.
-- This is required, because sometimes the _DATABASE birth event gets called later than the SET_BASE birth event!
-- @param #SET_CLIENT self
-- @param Event#EVENTDATA Event
-- @return #string The name of the CLIENT
-- @return #table The CLIENT
function SET_CLIENT:AddInDatabase( Event )
  self:F3( { Event } )

  return Event.IniDCSUnitName, self.Database[Event.IniDCSUnitName]
end

--- Handles the Database to check on any event that Object exists in the Database.
-- This is required, because sometimes the _DATABASE event gets called later than the SET_BASE event or vise versa!
-- @param #SET_CLIENT self
-- @param Event#EVENTDATA Event
-- @return #string The name of the CLIENT
-- @return #table The CLIENT
function SET_CLIENT:FindInDatabase( Event )
  self:F3( { Event } )

  return Event.IniDCSUnitName, self.Database[Event.IniDCSUnitName]
end

--- Iterate the SET_CLIENT and call an interator function for each **alive** CLIENT, providing the CLIENT and optional parameters.
-- @param #SET_CLIENT self
-- @param #function IteratorFunction The function that will be called when there is an alive CLIENT in the SET_CLIENT. The function needs to accept a CLIENT parameter.
-- @return #SET_CLIENT self
function SET_CLIENT:ForEachClient( IteratorFunction, ... )
  self:F2( arg )
  
  self:ForEach( IteratorFunction, arg, self.Set )

  return self
end

--- Iterate the SET_CLIENT and call an iterator function for each **alive** CLIENT presence completely in a @{Zone}, providing the CLIENT and optional parameters to the called function.
-- @param #SET_CLIENT self
-- @param Zone#ZONE ZoneObject The Zone to be tested for.
-- @param #function IteratorFunction The function that will be called when there is an alive CLIENT in the SET_CLIENT. The function needs to accept a CLIENT parameter.
-- @return #SET_CLIENT self
function SET_CLIENT:ForEachClientInZone( ZoneObject, IteratorFunction, ... )
  self:F2( arg )
  
  self:ForEach( IteratorFunction, arg, self.Set,
    --- @param Zone#ZONE_BASE ZoneObject
    -- @param Client#CLIENT ClientObject
    function( ZoneObject, ClientObject )
      if ClientObject:IsInZone( ZoneObject ) then
        return true
      else
        return false
      end
    end, { ZoneObject } )

  return self
end

--- Iterate the SET_CLIENT and call an iterator function for each **alive** CLIENT presence not in a @{Zone}, providing the CLIENT and optional parameters to the called function.
-- @param #SET_CLIENT self
-- @param Zone#ZONE ZoneObject The Zone to be tested for.
-- @param #function IteratorFunction The function that will be called when there is an alive CLIENT in the SET_CLIENT. The function needs to accept a CLIENT parameter.
-- @return #SET_CLIENT self
function SET_CLIENT:ForEachClientNotInZone( ZoneObject, IteratorFunction, ... )
  self:F2( arg )
  
  self:ForEach( IteratorFunction, arg, self.Set,
    --- @param Zone#ZONE_BASE ZoneObject
    -- @param Client#CLIENT ClientObject
    function( ZoneObject, ClientObject )
      if ClientObject:IsNotInZone( ZoneObject ) then
        return true
      else
        return false
      end
    end, { ZoneObject } )

  return self
end

---
-- @param #SET_CLIENT self
-- @param Client#CLIENT MClient
-- @return #SET_CLIENT self
function SET_CLIENT:IsIncludeObject( MClient )
  self:F2( MClient )

  local MClientInclude = true

  if MClient then
    local MClientName = MClient.UnitName
  
    if self.Filter.Coalitions then
      local MClientCoalition = false
      for CoalitionID, CoalitionName in pairs( self.Filter.Coalitions ) do
        local ClientCoalitionID = _DATABASE:GetCoalitionFromClientTemplate( MClientName )
        self:T3( { "Coalition:", ClientCoalitionID, self.FilterMeta.Coalitions[CoalitionName], CoalitionName } )
        if self.FilterMeta.Coalitions[CoalitionName] and self.FilterMeta.Coalitions[CoalitionName] == ClientCoalitionID then
          MClientCoalition = true
        end
      end
      self:T( { "Evaluated Coalition", MClientCoalition } )
      MClientInclude = MClientInclude and MClientCoalition
    end
    
    if self.Filter.Categories then
      local MClientCategory = false
      for CategoryID, CategoryName in pairs( self.Filter.Categories ) do
        local ClientCategoryID = _DATABASE:GetCategoryFromClientTemplate( MClientName )
        self:T3( { "Category:", ClientCategoryID, self.FilterMeta.Categories[CategoryName], CategoryName } )
        if self.FilterMeta.Categories[CategoryName] and self.FilterMeta.Categories[CategoryName] == ClientCategoryID then
          MClientCategory = true
        end
      end
      self:T( { "Evaluated Category", MClientCategory } )
      MClientInclude = MClientInclude and MClientCategory
    end
    
    if self.Filter.Types then
      local MClientType = false
      for TypeID, TypeName in pairs( self.Filter.Types ) do
        self:T3( { "Type:", MClient:GetTypeName(), TypeName } )
        if TypeName == MClient:GetTypeName() then
          MClientType = true
        end
      end
      self:T( { "Evaluated Type", MClientType } )
      MClientInclude = MClientInclude and MClientType
    end
    
    if self.Filter.Countries then
      local MClientCountry = false
      for CountryID, CountryName in pairs( self.Filter.Countries ) do
        local ClientCountryID = _DATABASE:GetCountryFromClientTemplate(MClientName)
        self:T3( { "Country:", ClientCountryID, country.id[CountryName], CountryName } )
        if country.id[CountryName] and country.id[CountryName] == ClientCountryID then
          MClientCountry = true
        end
      end
      self:T( { "Evaluated Country", MClientCountry } )
      MClientInclude = MClientInclude and MClientCountry
    end
  
    if self.Filter.ClientPrefixes then
      local MClientPrefix = false
      for ClientPrefixId, ClientPrefix in pairs( self.Filter.ClientPrefixes ) do
        self:T3( { "Prefix:", string.find( MClient.UnitName, ClientPrefix, 1 ), ClientPrefix } )
        if string.find( MClient.UnitName, ClientPrefix, 1 ) then
          MClientPrefix = true
        end
      end
      self:T( { "Evaluated Prefix", MClientPrefix } )
      MClientInclude = MClientInclude and MClientPrefix
    end
  end
  
  self:T2( MClientInclude )
  return MClientInclude
end

--- SET_AIRBASE

--- SET_AIRBASE class
-- @type SET_AIRBASE
-- @extends Set#SET_BASE
SET_AIRBASE = {
  ClassName = "SET_AIRBASE",
  Airbases = {},
  Filter = {
    Coalitions = nil,
  },
  FilterMeta = {
    Coalitions = {
      red = coalition.side.RED,
      blue = coalition.side.BLUE,
      neutral = coalition.side.NEUTRAL,
    },
    Categories = {
      airdrome = Airbase.Category.AIRDROME,
      helipad = Airbase.Category.HELIPAD,
      ship = Airbase.Category.SHIP,
    },
  },
}


--- Creates a new SET_AIRBASE object, building a set of airbases belonging to a coalitions and categories.
-- @param #SET_AIRBASE self
-- @return #SET_AIRBASE self
-- @usage
-- -- Define a new SET_AIRBASE Object. The DatabaseSet will contain a reference to all Airbases.
-- DatabaseSet = SET_AIRBASE:New()
function SET_AIRBASE:New()
  -- Inherits from BASE
  local self = BASE:Inherit( self, SET_BASE:New( _DATABASE.AIRBASES ) )

  return self
end

--- Add AIRBASEs to SET_AIRBASE.
-- @param Set#SET_AIRBASE self
-- @param #string AddAirbaseNames A single name or an array of AIRBASE names.
-- @return self
function SET_AIRBASE:AddAirbasesByName( AddAirbaseNames )

  local AddAirbaseNamesArray = ( type( AddAirbaseNames ) == "table" ) and AddAirbaseNames or { AddAirbaseNames }
  
  for AddAirbaseID, AddAirbaseName in pairs( AddAirbaseNamesArray ) do
    self:Add( AddAirbaseName, AIRBASE:FindByName( AddAirbaseName ) )
  end
    
  return self
end

--- Remove AIRBASEs from SET_AIRBASE.
-- @param Set#SET_AIRBASE self
-- @param Airbase#AIRBASE RemoveAirbaseNames A single name or an array of AIRBASE names.
-- @return self
function SET_AIRBASE:RemoveAirbasesByName( RemoveAirbaseNames )

  local RemoveAirbaseNamesArray = ( type( RemoveAirbaseNames ) == "table" ) and RemoveAirbaseNames or { RemoveAirbaseNames }
  
  for RemoveAirbaseID, RemoveAirbaseName in pairs( RemoveAirbaseNamesArray ) do
    self:Remove( RemoveAirbaseName.AirbaseName )
  end
    
  return self
end


--- Finds a Airbase based on the Airbase Name.
-- @param #SET_AIRBASE self
-- @param #string AirbaseName
-- @return Airbase#AIRBASE The found Airbase.
function SET_AIRBASE:FindAirbase( AirbaseName )

  local AirbaseFound = self.Set[AirbaseName]
  return AirbaseFound
end



--- Builds a set of airbases of coalitions.
-- Possible current coalitions are red, blue and neutral.
-- @param #SET_AIRBASE self
-- @param #string Coalitions Can take the following values: "red", "blue", "neutral".
-- @return #SET_AIRBASE self
function SET_AIRBASE:FilterCoalitions( Coalitions )
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


--- Builds a set of airbases out of categories.
-- Possible current categories are plane, helicopter, ground, ship.
-- @param #SET_AIRBASE self
-- @param #string Categories Can take the following values: "airdrome", "helipad", "ship".
-- @return #SET_AIRBASE self
function SET_AIRBASE:FilterCategories( Categories )
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

--- Starts the filtering.
-- @param #SET_AIRBASE self
-- @return #SET_AIRBASE self
function SET_AIRBASE:FilterStart()

  if _DATABASE then
    self:_FilterStart()
  end
  
  return self
end


--- Handles the Database to check on an event (birth) that the Object was added in the Database.
-- This is required, because sometimes the _DATABASE birth event gets called later than the SET_BASE birth event!
-- @param #SET_AIRBASE self
-- @param Event#EVENTDATA Event
-- @return #string The name of the AIRBASE
-- @return #table The AIRBASE
function SET_AIRBASE:AddInDatabase( Event )
  self:F3( { Event } )

  return Event.IniDCSUnitName, self.Database[Event.IniDCSUnitName]
end

--- Handles the Database to check on any event that Object exists in the Database.
-- This is required, because sometimes the _DATABASE event gets called later than the SET_BASE event or vise versa!
-- @param #SET_AIRBASE self
-- @param Event#EVENTDATA Event
-- @return #string The name of the AIRBASE
-- @return #table The AIRBASE
function SET_AIRBASE:FindInDatabase( Event )
  self:F3( { Event } )

  return Event.IniDCSUnitName, self.Database[Event.IniDCSUnitName]
end

--- Iterate the SET_AIRBASE and call an interator function for each AIRBASE, providing the AIRBASE and optional parameters.
-- @param #SET_AIRBASE self
-- @param #function IteratorFunction The function that will be called when there is an alive AIRBASE in the SET_AIRBASE. The function needs to accept a AIRBASE parameter.
-- @return #SET_AIRBASE self
function SET_AIRBASE:ForEachAirbase( IteratorFunction, ... )
  self:F2( arg )
  
  self:ForEach( IteratorFunction, arg, self.Set )

  return self
end

--- Iterate the SET_AIRBASE while identifying the nearest @{Airbase#AIRBASE} from a @{Point#POINT_VEC2}.
-- @param #SET_AIRBASE self
-- @param Point#POINT_VEC2 PointVec2 A @{Point#POINT_VEC2} object from where to evaluate the closest @{Airbase#AIRBASE}.
-- @return Airbase#AIRBASE The closest @{Airbase#AIRBASE}.
function SET_AIRBASE:FindNearestAirbaseFromPointVec2( PointVec2 )
  self:F2( PointVec2 )
  
  local NearestAirbase = self:FindNearestObjectFromPointVec2( PointVec2 )
  return NearestAirbase
end



---
-- @param #SET_AIRBASE self
-- @param Airbase#AIRBASE MAirbase
-- @return #SET_AIRBASE self
function SET_AIRBASE:IsIncludeObject( MAirbase )
  self:F2( MAirbase )

  local MAirbaseInclude = true

  if MAirbase then
    local MAirbaseName = MAirbase:GetName()
  
    if self.Filter.Coalitions then
      local MAirbaseCoalition = false
      for CoalitionID, CoalitionName in pairs( self.Filter.Coalitions ) do
        local AirbaseCoalitionID = _DATABASE:GetCoalitionFromAirbase( MAirbaseName )
        self:T3( { "Coalition:", AirbaseCoalitionID, self.FilterMeta.Coalitions[CoalitionName], CoalitionName } )
        if self.FilterMeta.Coalitions[CoalitionName] and self.FilterMeta.Coalitions[CoalitionName] == AirbaseCoalitionID then
          MAirbaseCoalition = true
        end
      end
      self:T( { "Evaluated Coalition", MAirbaseCoalition } )
      MAirbaseInclude = MAirbaseInclude and MAirbaseCoalition
    end
    
    if self.Filter.Categories then
      local MAirbaseCategory = false
      for CategoryID, CategoryName in pairs( self.Filter.Categories ) do
        local AirbaseCategoryID = _DATABASE:GetCategoryFromAirbase( MAirbaseName )
        self:T3( { "Category:", AirbaseCategoryID, self.FilterMeta.Categories[CategoryName], CategoryName } )
        if self.FilterMeta.Categories[CategoryName] and self.FilterMeta.Categories[CategoryName] == AirbaseCategoryID then
          MAirbaseCategory = true
        end
      end
      self:T( { "Evaluated Category", MAirbaseCategory } )
      MAirbaseInclude = MAirbaseInclude and MAirbaseCategory
    end
  end
   
  self:T2( MAirbaseInclude )
  return MAirbaseInclude
end
