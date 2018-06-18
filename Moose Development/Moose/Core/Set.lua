--- **Core** -- SET_ classes define **collections** of objects to perform **bulk actions** and logically **group** objects.
-- 
-- ===
-- 
-- SET_ classes group objects of the same type into a collection, which is either:
-- 
--   * Manually managed using the **:Add...()** or **:Remove...()** methods. The initial SET can be filtered with the **@{#SET_BASE.FilterOnce}()** method
--   * Dynamically updated when new objects are created or objects are destroyed using the **@{#SET_BASE.FilterStart}()** method.
--   
-- Various types of SET_ classes are available:
-- 
--   * @{#SET_UNIT}: Defines a colleciton of @{Wrapper.Unit}s filtered by filter criteria.
--   * @{#SET_GROUP}: Defines a collection of @{Wrapper.Group}s filtered by filter criteria.
--   * @{#SET_CLIENT}: Defines a collection of @{Client}s filterd by filter criteria.
--   * @{#SET_AIRBASE}: Defines a collection of @{Wrapper.Airbase}s filtered by filter criteria.
-- 
-- These classes are derived from @{#SET_BASE}, which contains the main methods to manage SETs.
-- 
-- A multitude of other methods are available in SET_ classes that allow to:
-- 
--   * Validate the presence of objects in the SET.
--   * Trigger events when objects in the SET change a zone presence.
-- 
-- ===
-- 
-- ### Author: **FlightControl**
-- ### Contributions: 
-- 
-- ===
-- 
-- @module Core.Set
-- @image Core_Sets.JPG


--- @type SET_BASE
-- @field #table Filter
-- @field #table Set
-- @field #table List
-- @field Core.Scheduler#SCHEDULER CallScheduler
-- @extends Core.Base#BASE


--- The @{Core.Set#SET_BASE} class defines the core functions that define a collection of objects.
-- A SET provides iterators to iterate the SET, but will **temporarily** yield the ForEach interator loop at defined **"intervals"** to the mail simulator loop.
-- In this way, large loops can be done while not blocking the simulator main processing loop.
-- The default **"yield interval"** is after 10 objects processed.
-- The default **"time interval"** is after 0.001 seconds.
-- 
-- ## Add or remove objects from the SET
-- 
-- Some key core functions are @{Core.Set#SET_BASE.Add} and @{Core.Set#SET_BASE.Remove} to add or remove objects from the SET in your logic.
-- 
-- ## Define the SET iterator **"yield interval"** and the **"time interval"**
-- 
-- Modify the iterator intervals with the @{Core.Set#SET_BASE.SetInteratorIntervals} method.
-- You can set the **"yield interval"**, and the **"time interval"**. (See above).
-- 
-- @field #SET_BASE SET_BASE 
SET_BASE = {
  ClassName = "SET_BASE",
  Filter = {},
  Set = {},
  List = {},
  Index = {},
}


--- Creates a new SET_BASE object, building a set of units belonging to a coalitions, categories, countries, types or with defined prefix names.
-- @param #SET_BASE self
-- @return #SET_BASE
-- @usage
-- -- Define a new SET_BASE Object. This DBObject will contain a reference to all Group and Unit Templates defined within the ME and the DCSRTE.
-- DBObject = SET_BASE:New()
function SET_BASE:New( Database )

  -- Inherits from BASE
  local self = BASE:Inherit( self, FSM:New() ) -- Core.Set#SET_BASE
  
  self.Database = Database

  self:SetStartState( "Started" )
  
  --- Added Handler OnAfter for SET_BASE
  -- @function [parent=#SET_BASE] OnAfterAdded
  -- @param #SET_BASE self
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param #string ObjectName The name of the object.
  -- @param Object The object.
  
  
  self:AddTransition( "*",  "Added", "*" )
  
  --- Removed Handler OnAfter for SET_BASE
  -- @function [parent=#SET_BASE] OnAfterRemoved
  -- @param #SET_BASE self
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param #string ObjectName The name of the object.
  -- @param Object The object.
  
  self:AddTransition( "*",  "Removed", "*" )

  self.YieldInterval = 10
  self.TimeInterval = 0.001

  self.Set = {}
  self.Index = {}
  
  self.CallScheduler = SCHEDULER:New( self )

  self:SetEventPriority( 2 )

  return self
end

--- Finds an @{Core.Base#BASE} object based on the object Name.
-- @param #SET_BASE self
-- @param #string ObjectName
-- @return Core.Base#BASE The Object found.
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

--- Gets a list of the Names of the Objects in the Set.
-- @param #SET_BASE self
-- @return #SET_BASE self
function SET_BASE:GetSetNames()  -- R2.3
  self:F2()
  
  local Names = {}
  
  for Name, Object in pairs( self.Set ) do
    table.insert( Names, Name )
  end
  
  return Names
end


--- Gets a list of the Objects in the Set.
-- @param #SET_BASE self
-- @return #SET_BASE self
function SET_BASE:GetSetObjects()  -- R2.3
  self:F2()
  
  local Objects = {}
  
  for Name, Object in pairs( self.Set ) do
    table.insert( Objects, Object )
  end
  
  return Objects
end


--- Removes a @{Core.Base#BASE} object from the @{Core.Set#SET_BASE} and derived classes, based on the Object Name.
-- @param #SET_BASE self
-- @param #string ObjectName
-- @param NoTriggerEvent (optional) When `true`, the :Remove() method will not trigger a **Removed** event.
function SET_BASE:Remove( ObjectName, NoTriggerEvent )
  self:F2( { ObjectName = ObjectName } )

  local Object = self.Set[ObjectName]
  
  if Object then  
    for Index, Key in ipairs( self.Index ) do
      if Key == ObjectName then
        table.remove( self.Index, Index )
        self.Set[ObjectName] = nil
        break
      end
    end
    -- When NoTriggerEvent is true, then no Removed event will be triggered.
    if not NoTriggerEvent then
      self:Removed( ObjectName, Object )
    end
  end
end


--- Adds a @{Core.Base#BASE} object in the @{Core.Set#SET_BASE}, using a given ObjectName as the index.
-- @param #SET_BASE self
-- @param #string ObjectName
-- @param Core.Base#BASE Object
-- @return Core.Base#BASE The added BASE Object.
function SET_BASE:Add( ObjectName, Object )
  self:F2( { ObjectName = ObjectName, Object = Object } )

  -- Ensure that the existing element is removed from the Set before a new one is inserted to the Set
  if self.Set[ObjectName] then
    self:Remove( ObjectName, true )
  end
  self.Set[ObjectName] = Object
  table.insert( self.Index, ObjectName )
  
  self:Added( ObjectName, Object )
end

--- Adds a @{Core.Base#BASE} object in the @{Core.Set#SET_BASE}, using the Object Name as the index.
-- @param #SET_BASE self
-- @param Wrapper.Object#OBJECT Object
-- @return Core.Base#BASE The added BASE Object.
function SET_BASE:AddObject( Object )
  self:F2( Object.ObjectName )
  
  self:T( Object.UnitName )
  self:T( Object.ObjectName )
  self:Add( Object.ObjectName, Object )
  
end




--- Gets a @{Core.Base#BASE} object from the @{Core.Set#SET_BASE} and derived classes, based on the Object Name.
-- @param #SET_BASE self
-- @param #string ObjectName
-- @return Core.Base#BASE
function SET_BASE:Get( ObjectName )
  self:F( ObjectName )

  local Object = self.Set[ObjectName]
  
  self:T3( { ObjectName, Object } )
  return Object
end

--- Gets the first object from the @{Core.Set#SET_BASE} and derived classes.
-- @param #SET_BASE self
-- @return Core.Base#BASE
function SET_BASE:GetFirst()

  local ObjectName = self.Index[1]
  local FirstObject = self.Set[ObjectName]
  self:T3( { FirstObject } )
  return FirstObject 
end

--- Gets the last object from the @{Core.Set#SET_BASE} and derived classes.
-- @param #SET_BASE self
-- @return Core.Base#BASE
function SET_BASE:GetLast()

  local ObjectName = self.Index[#self.Index]
  local LastObject = self.Set[ObjectName]
  self:T3( { LastObject } )
  return LastObject 
end

--- Gets a random object from the @{Core.Set#SET_BASE} and derived classes.
-- @param #SET_BASE self
-- @return Core.Base#BASE
function SET_BASE:GetRandom()

  local RandomItem = self.Set[self.Index[math.random(#self.Index)]]
  self:T3( { RandomItem } )
  return RandomItem
end


--- Retrieves the amount of objects in the @{Core.Set#SET_BASE} and derived classes.
-- @param #SET_BASE self
-- @return #number Count
function SET_BASE:Count()

  return self.Index and #self.Index or 0
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
  
  -- Follow alive players and clients
  --self:HandleEvent( EVENTS.PlayerEnterUnit, self._EventOnPlayerEnterUnit )
  --self:HandleEvent( EVENTS.PlayerLeaveUnit, self._EventOnPlayerLeaveUnit )
  
  
  return self
end

--- Starts the filtering of the Dead events for the collection.
-- @param #SET_BASE self
-- @return #SET_BASE self
function SET_BASE:FilterDeads() --R2.1 allow deads to be filtered to automatically handle deads in the collection.

  self:HandleEvent( EVENTS.Dead, self._EventOnDeadOrCrash )
  
  return self
end

--- Starts the filtering of the Crash events for the collection.
-- @param #SET_BASE self
-- @return #SET_BASE self
function SET_BASE:FilterCrashes() --R2.1 allow crashes to be filtered to automatically handle crashes in the collection.

  self:HandleEvent( EVENTS.Crash, self._EventOnDeadOrCrash )
  
  return self
end

--- Stops the filtering for the defined collection.
-- @param #SET_BASE self
-- @return #SET_BASE self
function SET_BASE:FilterStop()

  self:UnHandleEvent( EVENTS.Birth )
  self:UnHandleEvent( EVENTS.Dead )
  self:UnHandleEvent( EVENTS.Crash )
  
  return self
end

--- Iterate the SET_BASE while identifying the nearest object from a @{Core.Point#POINT_VEC2}.
-- @param #SET_BASE self
-- @param Core.Point#POINT_VEC2 PointVec2 A @{Core.Point#POINT_VEC2} object from where to evaluate the closest object in the set.
-- @return Core.Base#BASE The closest object.
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
-- @param Core.Event#EVENTDATA Event
function SET_BASE:_EventOnBirth( Event )
  self:F3( { Event } )

  if Event.IniDCSUnit then
    local ObjectName, Object = self:AddInDatabase( Event )
    self:T3( ObjectName, Object )
    if Object and self:IsIncludeObject( Object ) then
      self:Add( ObjectName, Object )
      --self:_EventOnPlayerEnterUnit( Event )
    end
  end
end

--- Handles the OnDead or OnCrash event for alive units set.
-- @param #SET_BASE self
-- @param Core.Event#EVENTDATA Event
function SET_BASE:_EventOnDeadOrCrash( Event )
  self:F( { Event } )

  if Event.IniDCSUnit then
    local ObjectName, Object = self:FindInDatabase( Event )
    if ObjectName then
      self:Remove( ObjectName )
    end
  end
end

--- Handles the OnPlayerEnterUnit event to fill the active players table (with the unit filter applied).
-- @param #SET_BASE self
-- @param Core.Event#EVENTDATA Event
--function SET_BASE:_EventOnPlayerEnterUnit( Event )
--  self:F3( { Event } )
--
--  if Event.IniDCSUnit then
--    local ObjectName, Object = self:AddInDatabase( Event )
--    self:T3( ObjectName, Object )
--    if self:IsIncludeObject( Object ) then
--      self:Add( ObjectName, Object )
--      --self:_EventOnPlayerEnterUnit( Event )
--    end
--  end
--end

--- Handles the OnPlayerLeaveUnit event to clean the active players table.
-- @param #SET_BASE self
-- @param Core.Event#EVENTDATA Event
--function SET_BASE:_EventOnPlayerLeaveUnit( Event )
--  self:F3( { Event } )
--
--  local ObjectName = Event.IniDCSUnit
--  if Event.IniDCSUnit then
--    if Event.IniDCSGroup then
--      local GroupUnits = Event.IniDCSGroup:getUnits()
--      local PlayerCount = 0
--      for _, DCSUnit in pairs( GroupUnits ) do
--        if DCSUnit ~= Event.IniDCSUnit then
--          if DCSUnit:getPlayerName() ~= nil then
--            PlayerCount = PlayerCount + 1
--          end
--        end
--      end
--      self:E(PlayerCount)
--      if PlayerCount == 0 then
--        self:Remove( Event.IniDCSGroupName )
--      end
--    end
--  end
--end

-- Iterators

--- Iterate the SET_BASE and derived classes and call an iterator function for the given SET_BASE, providing the Object for each element within the set and optional parameters.
-- @param #SET_BASE self
-- @param #function IteratorFunction The function that will be called.
-- @return #SET_BASE self
function SET_BASE:ForEach( IteratorFunction, arg, Set, Function, FunctionArguments )
  self:F3( arg )
  
  Set = Set or self:GetSet()
  arg = arg or {}
  
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

  --self.CallScheduler:Schedule( self, Schedule, {}, self.TimeInterval, self.TimeInterval, 0 )
  Schedule()
  
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

--- Gets a string with all the object names.
-- @param #SET_BASE self
-- @return #string A string with the names of the objects.
function SET_BASE:GetObjectNames()
  self:F3()

  local ObjectNames = ""
  for ObjectName, Object in pairs( self.Set ) do
    ObjectNames = ObjectNames .. ObjectName .. ", "
  end
  
  return ObjectNames
end

--- Flushes the current SET_BASE contents in the log ... (for debugging reasons).
-- @param #SET_BASE self
-- @param Core.Base#BASE MasterObject (optional) The master object as a reference.
-- @return #string A string with the names of the objects.
function SET_BASE:Flush( MasterObject )
  self:F3()

  local ObjectNames = ""
  for ObjectName, Object in pairs( self.Set ) do
    ObjectNames = ObjectNames .. ObjectName .. ", "
  end
  self:I( { MasterObject = MasterObject and MasterObject:GetClassNameAndID(), "Objects in Set:", ObjectNames } )
  
  return ObjectNames
end


--- @type SET_GROUP
-- @extends Core.Set#SET_BASE

--- Mission designers can use the @{Core.Set#SET_GROUP} class to build sets of groups belonging to certain:
-- 
--  * Coalitions
--  * Categories
--  * Countries
--  * Starting with certain prefix strings.
--  
-- ## SET_GROUP constructor
-- 
-- Create a new SET_GROUP object with the @{#SET_GROUP.New} method:
-- 
--    * @{#SET_GROUP.New}: Creates a new SET_GROUP object.
-- 
-- ## Add or Remove GROUP(s) from SET_GROUP
-- 
-- GROUPS can be added and removed using the @{Core.Set#SET_GROUP.AddGroupsByName} and @{Core.Set#SET_GROUP.RemoveGroupsByName} respectively. 
-- These methods take a single GROUP name or an array of GROUP names to be added or removed from SET_GROUP.
-- 
-- ## SET_GROUP filter criteria
-- 
-- You can set filter criteria to define the set of groups within the SET_GROUP.
-- Filter criteria are defined by:
-- 
--    * @{#SET_GROUP.FilterCoalitions}: Builds the SET_GROUP with the groups belonging to the coalition(s).
--    * @{#SET_GROUP.FilterCategories}: Builds the SET_GROUP with the groups belonging to the category(ies).
--    * @{#SET_GROUP.FilterCountries}: Builds the SET_GROUP with the gruops belonging to the country(ies).
--    * @{#SET_GROUP.FilterPrefixes}: Builds the SET_GROUP with the groups starting with the same prefix string(s).
-- 
-- For the Category Filter, extra methods have been added:
-- 
--    * @{#SET_GROUP.FilterCategoryAirplane}: Builds the SET_GROUP from airplanes.
--    * @{#SET_GROUP.FilterCategoryHelicopter}: Builds the SET_GROUP from helicopters.
--    * @{#SET_GROUP.FilterCategoryGround}: Builds the SET_GROUP from ground vehicles or infantry.
--    * @{#SET_GROUP.FilterCategoryShip}: Builds the SET_GROUP from ships.
--    * @{#SET_GROUP.FilterCategoryStructure}: Builds the SET_GROUP from structures.
-- 
--   
-- Once the filter criteria have been set for the SET_GROUP, you can start filtering using:
-- 
--    * @{#SET_GROUP.FilterStart}: Starts the filtering of the groups within the SET_GROUP and add or remove GROUP objects **dynamically**.
-- 
-- Planned filter criteria within development are (so these are not yet available):
-- 
--    * @{#SET_GROUP.FilterZones}: Builds the SET_GROUP with the groups within a @{Core.Zone#ZONE}.
-- 
-- ## SET_GROUP iterators
-- 
-- Once the filters have been defined and the SET_GROUP has been built, you can iterate the SET_GROUP with the available iterator methods.
-- The iterator methods will walk the SET_GROUP set, and call for each element within the set a function that you provide.
-- The following iterator methods are currently available within the SET_GROUP:
-- 
--   * @{#SET_GROUP.ForEachGroup}: Calls a function for each alive group it finds within the SET_GROUP.
--   * @{#SET_GROUP.ForEachGroupCompletelyInZone}: Iterate the SET_GROUP and call an iterator function for each **alive** GROUP presence completely in a @{Zone}, providing the GROUP and optional parameters to the called function.
--   * @{#SET_GROUP.ForEachGroupPartlyInZone}: Iterate the SET_GROUP and call an iterator function for each **alive** GROUP presence partly in a @{Zone}, providing the GROUP and optional parameters to the called function.
--   * @{#SET_GROUP.ForEachGroupNotInZone}: Iterate the SET_GROUP and call an iterator function for each **alive** GROUP presence not in a @{Zone}, providing the GROUP and optional parameters to the called function.
--
--
-- ## SET_GROUP trigger events on the GROUP objects.
-- 
-- The SET is derived from the FSM class, which provides extra capabilities to track the contents of the GROUP objects in the SET_GROUP.
-- 
-- ### When a GROUP object crashes or is dead, the SET_GROUP will trigger a **Dead** event.
-- 
-- You can handle the event using the OnBefore and OnAfter event handlers. 
-- The event handlers need to have the paramters From, Event, To, GroupObject.
-- The GroupObject is the GROUP object that is dead and within the SET_GROUP, and is passed as a parameter to the event handler.
-- See the following example:
-- 
--        -- Create the SetCarrier SET_GROUP collection.
--
--        local SetHelicopter = SET_GROUP:New():FilterPrefixes( "Helicopter" ):FilterStart()
-- 
--        -- Put a Dead event handler on SetCarrier, to ensure that when a carrier is destroyed, that all internal parameters are reset.
--
--        function SetHelicopter:OnAfterDead( From, Event, To, GroupObject )
--          self:F( { GroupObject = GroupObject:GetName() } )
--        end
-- 
-- While this is a good example, there is a catch.
-- Imageine you want to execute the code above, the the self would need to be from the object declared outside (above) the OnAfterDead method.
-- So, the self would need to contain another object. Fortunately, this can be done, but you must use then the **`.`** notation for the method.
-- See the modified example:
-- 
--        -- Now we have a constructor of the class AI_CARGO_DISPATCHER, that receives the SetHelicopter as a parameter.
--        -- Within that constructor, we want to set an enclosed event handler OnAfterDead for SetHelicopter.
--        -- But within the OnAfterDead method, we want to refer to the self variable of the AI_CARGO_DISPATCHER.
-- 
--        function AI_CARGO_DISPATCHER:New( SetCarrier, SetCargo, SetDeployZones )
--         
--          local self = BASE:Inherit( self, FSM:New() ) -- #AI_CARGO_DISPATCHER
-- 
--          -- Put a Dead event handler on SetCarrier, to ensure that when a carrier is destroyed, that all internal parameters are reset.
--          -- Note the "." notation, and the explicit declaration of SetHelicopter, which would be using the ":" notation the implicit self variable declaration.
--
--          function SetHelicopter.OnAfterDead( SetHelicopter, From, Event, To, GroupObject )
--            SetHelicopter:F( { GroupObject = GroupObject:GetName() } )
--            self.PickupCargo[GroupObject] = nil  -- So here I clear the PickupCargo table entry of the self object AI_CARGO_DISPATCHER.
--            self.CarrierHome[GroupObject] = nil
--          end
--        
--        end
-- 
-- ===
-- @field #SET_GROUP SET_GROUP 
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
      ground = Group.Category.GROUND, -- R2.2
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

--- Gets the Set.
-- @param #SET_GROUP self
-- @return #SET_GROUP self
function SET_GROUP:GetAliveSet()
  self:F2()
  
  local AliveSet = SET_GROUP:New()
  
  -- Clean the Set before returning with only the alive Groups.
  for GroupName, GroupObject in pairs( self.Set ) do
    if GroupObject then
      if GroupObject:IsAlive() then
        AliveSet:Add( GroupName, GroupObject )
      end
    end
  end
  
  return AliveSet.Set or {}
end


--- Add GROUP(s) to SET_GROUP.
-- @param Core.Set#SET_GROUP self
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
-- @param Core.Set#SET_GROUP self
-- @param Wrapper.Group#GROUP RemoveGroupNames A single name or an array of GROUP names.
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
-- @return Wrapper.Group#GROUP The found Group.
function SET_GROUP:FindGroup( GroupName )

  local GroupFound = self.Set[GroupName]
  return GroupFound
end

--- Iterate the SET_GROUP while identifying the nearest object from a @{Core.Point#POINT_VEC2}.
-- @param #SET_GROUP self
-- @param Core.Point#POINT_VEC2 PointVec2 A @{Core.Point#POINT_VEC2} object from where to evaluate the closest object in the set.
-- @return Wrapper.Group#GROUP The closest group.
function SET_GROUP:FindNearestGroupFromPointVec2( PointVec2 )
  self:F2( PointVec2 )
  
  local NearestGroup = nil
  local ClosestDistance = nil
  
  for ObjectID, ObjectData in pairs( self.Set ) do
    if NearestGroup == nil then
      NearestGroup = ObjectData
      ClosestDistance = PointVec2:DistanceFromVec2( ObjectData:GetVec2() )
    else
      local Distance = PointVec2:DistanceFromVec2( ObjectData:GetVec2() )
      if Distance < ClosestDistance then
        NearestGroup = ObjectData
        ClosestDistance = Distance
      end
    end
  end
  
  return NearestGroup
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

--- Builds a set of groups out of ground category.
-- @param #SET_GROUP self
-- @return #SET_GROUP self
function SET_GROUP:FilterCategoryGround()
  self:FilterCategories( "ground" )
  return self
end

--- Builds a set of groups out of airplane category.
-- @param #SET_GROUP self
-- @return #SET_GROUP self
function SET_GROUP:FilterCategoryAirplane()
  self:FilterCategories( "plane" )
  return self
end

--- Builds a set of groups out of helicopter category.
-- @param #SET_GROUP self
-- @return #SET_GROUP self
function SET_GROUP:FilterCategoryHelicopter()
  self:FilterCategories( "helicopter" )
  return self
end

--- Builds a set of groups out of ship category.
-- @param #SET_GROUP self
-- @return #SET_GROUP self
function SET_GROUP:FilterCategoryShip()
  self:FilterCategories( "ship" )
  return self
end

--- Builds a set of groups out of structure category.
-- @param #SET_GROUP self
-- @return #SET_GROUP self
function SET_GROUP:FilterCategoryStructure()
  self:FilterCategories( "structure" )
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
    self:HandleEvent( EVENTS.Birth, self._EventOnBirth )
    self:HandleEvent( EVENTS.Dead, self._EventOnDeadOrCrash )
    self:HandleEvent( EVENTS.Crash, self._EventOnDeadOrCrash )
  end
  
  
  
  return self
end

--- Handles the OnDead or OnCrash event for alive groups set.
-- Note: The GROUP object in the SET_GROUP collection will only be removed if the last unit is destroyed of the GROUP.
-- @param #SET_GROUP self
-- @param Core.Event#EVENTDATA Event
function SET_GROUP:_EventOnDeadOrCrash( Event )
  self:F( { Event } )

  if Event.IniDCSUnit then
    local ObjectName, Object = self:FindInDatabase( Event )
    if ObjectName then
      if Event.IniDCSGroup:getSize() == 1 then -- Only remove if the last unit of the group was destroyed.
        self:Remove( ObjectName )
      end
    end
  end
end

--- Handles the Database to check on an event (birth) that the Object was added in the Database.
-- This is required, because sometimes the _DATABASE birth event gets called later than the SET_BASE birth event!
-- @param #SET_GROUP self
-- @param Core.Event#EVENTDATA Event
-- @return #string The name of the GROUP
-- @return #table The GROUP
function SET_GROUP:AddInDatabase( Event )
  self:F3( { Event } )

  if Event.IniObjectCategory == 1 then
    if not self.Database[Event.IniDCSGroupName] then
      self.Database[Event.IniDCSGroupName] = GROUP:Register( Event.IniDCSGroupName )
      self:T3( self.Database[Event.IniDCSGroupName] )
    end
  end
  
  return Event.IniDCSGroupName, self.Database[Event.IniDCSGroupName]
end

--- Handles the Database to check on any event that Object exists in the Database.
-- This is required, because sometimes the _DATABASE event gets called later than the SET_BASE event or vise versa!
-- @param #SET_GROUP self
-- @param Core.Event#EVENTDATA Event
-- @return #string The name of the GROUP
-- @return #table The GROUP
function SET_GROUP:FindInDatabase( Event )
  self:F3( { Event } )

  return Event.IniDCSGroupName, self.Database[Event.IniDCSGroupName]
end

--- Iterate the SET_GROUP and call an iterator function for each GROUP object, providing the GROUP and optional parameters.
-- @param #SET_GROUP self
-- @param #function IteratorFunction The function that will be called when there is an alive GROUP in the SET_GROUP. The function needs to accept a GROUP parameter.
-- @return #SET_GROUP self
function SET_GROUP:ForEachGroup( IteratorFunction, ... )
  self:F2( arg )
  
  self:ForEach( IteratorFunction, arg, self:GetSet() )

  return self
end

--- Iterate the SET_GROUP and call an iterator function for each **alive** GROUP object, providing the GROUP and optional parameters.
-- @param #SET_GROUP self
-- @param #function IteratorFunction The function that will be called when there is an alive GROUP in the SET_GROUP. The function needs to accept a GROUP parameter.
-- @return #SET_GROUP self
function SET_GROUP:ForEachGroupAlive( IteratorFunction, ... )
  self:F2( arg )
  
  self:ForEach( IteratorFunction, arg, self:GetAliveSet() )

  return self
end

--- Iterate the SET_GROUP and call an iterator function for each **alive** GROUP presence completely in a @{Zone}, providing the GROUP and optional parameters to the called function.
-- @param #SET_GROUP self
-- @param Core.Zone#ZONE ZoneObject The Zone to be tested for.
-- @param #function IteratorFunction The function that will be called when there is an alive GROUP in the SET_GROUP. The function needs to accept a GROUP parameter.
-- @return #SET_GROUP self
function SET_GROUP:ForEachGroupCompletelyInZone( ZoneObject, IteratorFunction, ... )
  self:F2( arg )
  
  self:ForEach( IteratorFunction, arg, self:GetSet(),
    --- @param Core.Zone#ZONE_BASE ZoneObject
    -- @param Wrapper.Group#GROUP GroupObject
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
-- @param Core.Zone#ZONE ZoneObject The Zone to be tested for.
-- @param #function IteratorFunction The function that will be called when there is an alive GROUP in the SET_GROUP. The function needs to accept a GROUP parameter.
-- @return #SET_GROUP self
function SET_GROUP:ForEachGroupPartlyInZone( ZoneObject, IteratorFunction, ... )
  self:F2( arg )
  
  self:ForEach( IteratorFunction, arg, self:GetSet(),
    --- @param Core.Zone#ZONE_BASE ZoneObject
    -- @param Wrapper.Group#GROUP GroupObject
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
-- @param Core.Zone#ZONE ZoneObject The Zone to be tested for.
-- @param #function IteratorFunction The function that will be called when there is an alive GROUP in the SET_GROUP. The function needs to accept a GROUP parameter.
-- @return #SET_GROUP self
function SET_GROUP:ForEachGroupNotInZone( ZoneObject, IteratorFunction, ... )
  self:F2( arg )
  
  self:ForEach( IteratorFunction, arg, self:GetSet(),
    --- @param Core.Zone#ZONE_BASE ZoneObject
    -- @param Wrapper.Group#GROUP GroupObject
    function( ZoneObject, GroupObject )
      if GroupObject:IsNotInZone( ZoneObject ) then
        return true
      else
        return false
      end
    end, { ZoneObject } )

  return self
end

--- Iterate the SET_GROUP and return true if all the @{Wrapper.Group#GROUP} are completely in the @{Core.Zone#ZONE}
-- @param #SET_GROUP self
-- @param Core.Zone#ZONE ZoneObject The Zone to be tested for.
-- @return #boolean true if all the @{Wrapper.Group#GROUP} are completly in the @{Core.Zone#ZONE}, false otherwise
-- @usage
-- local MyZone = ZONE:New("Zone1")
-- local MySetGroup = SET_GROUP:New()
-- MySetGroup:AddGroupsByName({"Group1", "Group2"})
--
-- if MySetGroup:AllCompletelyInZone(MyZone) then
--   MESSAGE:New("All the SET's GROUP are in zone !", 10):ToAll()
-- else
--   MESSAGE:New("Some or all SET's GROUP are outside zone !", 10):ToAll()
-- end
function SET_GROUP:AllCompletelyInZone(Zone)
  self:F2(Zone)
  local Set = self:GetSet()
  for GroupID, GroupData in pairs(Set) do -- For each GROUP in SET_GROUP
    if not GroupData:IsCompletelyInZone(Zone) then 
      return false
    end
  end
  return true
end

--- Iterate the SET_GROUP and return true if at least one of the @{Wrapper.Group#GROUP} is completely inside the @{Core.Zone#ZONE}
-- @param #SET_GROUP self
-- @param Core.Zone#ZONE ZoneObject The Zone to be tested for.
-- @return #boolean true if at least one of the @{Wrapper.Group#GROUP} is completly inside the @{Core.Zone#ZONE}, false otherwise.
-- @usage
-- local MyZone = ZONE:New("Zone1")
-- local MySetGroup = SET_GROUP:New()
-- MySetGroup:AddGroupsByName({"Group1", "Group2"})
--
-- if MySetGroup:AnyCompletelyInZone(MyZone) then
--   MESSAGE:New("At least one GROUP is completely in zone !", 10):ToAll()
-- else
--   MESSAGE:New("No GROUP is completely in zone !", 10):ToAll()
-- end
function SET_GROUP:AnyCompletelyInZone(Zone)
  self:F2(Zone)
  local Set = self:GetSet()
  for GroupID, GroupData in pairs(Set) do -- For each GROUP in SET_GROUP
    if GroupData:IsCompletelyInZone(Zone) then 
      return true
    end
  end
  return false
end

--- Iterate the SET_GROUP and return true if at least one @{#UNIT} of one @{GROUP} of the @{SET_GROUP} is in @{ZONE}
-- @param #SET_GROUP self
-- @param Core.Zone#ZONE ZoneObject The Zone to be tested for.
-- @return #boolean true if at least one of the @{Wrapper.Group#GROUP} is partly or completly inside the @{Core.Zone#ZONE}, false otherwise.
-- @usage
-- local MyZone = ZONE:New("Zone1")
-- local MySetGroup = SET_GROUP:New()
-- MySetGroup:AddGroupsByName({"Group1", "Group2"})
--
-- if MySetGroup:AnyPartlyInZone(MyZone) then
--   MESSAGE:New("At least one GROUP has at least one UNIT in zone !", 10):ToAll()
-- else
--   MESSAGE:New("No UNIT of any GROUP is in zone !", 10):ToAll()
-- end
function SET_GROUP:AnyInZone(Zone)
  self:F2(Zone)
  local Set = self:GetSet()
  for GroupID, GroupData in pairs(Set) do -- For each GROUP in SET_GROUP
    if GroupData:IsPartlyInZone(Zone) or GroupData:IsCompletelyInZone(Zone) then 
      return true
    end
  end
  return false
end

--- Iterate the SET_GROUP and return true if at least one @{GROUP} of the @{SET_GROUP} is partly in @{ZONE}.
-- Will return false if a @{GROUP} is fully in the @{ZONE}
-- @param #SET_GROUP self
-- @param Core.Zone#ZONE ZoneObject The Zone to be tested for.
-- @return #boolean true if at least one of the @{Wrapper.Group#GROUP} is partly or completly inside the @{Core.Zone#ZONE}, false otherwise.
-- @usage
-- local MyZone = ZONE:New("Zone1")
-- local MySetGroup = SET_GROUP:New()
-- MySetGroup:AddGroupsByName({"Group1", "Group2"})
--
-- if MySetGroup:AnyPartlyInZone(MyZone) then
--   MESSAGE:New("At least one GROUP is partially in the zone, but none are fully in it !", 10):ToAll()
-- else
--   MESSAGE:New("No GROUP are in zone, or one (or more) GROUP is completely in it !", 10):ToAll()
-- end
function SET_GROUP:AnyPartlyInZone(Zone)
  self:F2(Zone)
  local IsPartlyInZone = false
  local Set = self:GetSet()
  for GroupID, GroupData in pairs(Set) do -- For each GROUP in SET_GROUP
    if GroupData:IsCompletelyInZone(Zone) then
      return false
    elseif GroupData:IsPartlyInZone(Zone) then 
      IsPartlyInZone = true -- at least one GROUP is partly in zone
    end
  end
  
  if IsPartlyInZone then
    return true
  else
    return false
  end
end

--- Iterate the SET_GROUP and return true if no @{GROUP} of the @{SET_GROUP} is in @{ZONE}
-- This could also be achieved with `not SET_GROUP:AnyPartlyInZone(Zone)`, but it's easier for the 
-- mission designer to add a dedicated method
-- @param #SET_GROUP self
-- @param Core.Zone#ZONE ZoneObject The Zone to be tested for.
-- @return #boolean true if no @{Wrapper.Group#GROUP} is inside the @{Core.Zone#ZONE} in any way, false otherwise.
-- @usage
-- local MyZone = ZONE:New("Zone1")
-- local MySetGroup = SET_GROUP:New()
-- MySetGroup:AddGroupsByName({"Group1", "Group2"})
--
-- if MySetGroup:NoneInZone(MyZone) then
--   MESSAGE:New("No GROUP is completely in zone !", 10):ToAll()
-- else
--   MESSAGE:New("No UNIT of any GROUP is in zone !", 10):ToAll()
-- end
function SET_GROUP:NoneInZone(Zone)
  self:F2(Zone)
  local Set = self:GetSet()
  for GroupID, GroupData in pairs(Set) do -- For each GROUP in SET_GROUP
    if not GroupData:IsNotInZone(Zone) then -- If the GROUP is in Zone in any way
      return false
    end
  end
  return true
end

--- Iterate the SET_GROUP and count how many GROUPs are completely in the Zone
-- That could easily be done with SET_GROUP:ForEachGroupCompletelyInZone(), but this function
-- provides an easy to use shortcut...
-- @param #SET_GROUP self
-- @param Core.Zone#ZONE ZoneObject The Zone to be tested for.
-- @return #number the number of GROUPs completely in the Zone
-- @usage
-- local MyZone = ZONE:New("Zone1")
-- local MySetGroup = SET_GROUP:New()
-- MySetGroup:AddGroupsByName({"Group1", "Group2"})
--
-- MESSAGE:New("There are " .. MySetGroup:CountInZone(MyZone) .. " GROUPs in the Zone !", 10):ToAll()
function SET_GROUP:CountInZone(Zone)
  self:F2(Zone)
  local Count = 0
  local Set = self:GetSet()
  for GroupID, GroupData in pairs(Set) do -- For each GROUP in SET_GROUP
    if GroupData:IsCompletelyInZone(Zone) then 
      Count = Count + 1
    end
  end
  return Count
end

--- Iterate the SET_GROUP and count how many UNITs are completely in the Zone
-- @param #SET_GROUP self
-- @param Core.Zone#ZONE ZoneObject The Zone to be tested for.
-- @return #number the number of GROUPs completely in the Zone
-- @usage
-- local MyZone = ZONE:New("Zone1")
-- local MySetGroup = SET_GROUP:New()
-- MySetGroup:AddGroupsByName({"Group1", "Group2"})
--
-- MESSAGE:New("There are " .. MySetGroup:CountUnitInZone(MyZone) .. " UNITs in the Zone !", 10):ToAll()
function SET_GROUP:CountUnitInZone(Zone)
  self:F2(Zone)
  local Count = 0
  local Set = self:GetSet()
  for GroupID, GroupData in pairs(Set) do -- For each GROUP in SET_GROUP
    Count = Count + GroupData:CountInZone(Zone)
  end
  return Count
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
-- @param Wrapper.Group#GROUP MooseGroup
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
      if string.find( MooseGroup:GetName(), GroupPrefix:gsub ("-", "%%-"), 1 ) then
        MooseGroupPrefix = true
      end
    end
    MooseGroupInclude = MooseGroupInclude and MooseGroupPrefix
  end

  self:T2( MooseGroupInclude )
  return MooseGroupInclude
end


do -- SET_UNIT

  --- @type SET_UNIT
  -- @extends Core.Set#SET_BASE
  
  --- Mission designers can use the SET_UNIT class to build sets of units belonging to certain:
  -- 
  --  * Coalitions
  --  * Categories
  --  * Countries
  --  * Unit types
  --  * Starting with certain prefix strings.
  --  
  -- ## SET_UNIT constructor
  --
  -- Create a new SET_UNIT object with the @{#SET_UNIT.New} method:
  -- 
  --    * @{#SET_UNIT.New}: Creates a new SET_UNIT object.
  --   
  -- ## Add or Remove UNIT(s) from SET_UNIT
  --
  -- UNITs can be added and removed using the @{Core.Set#SET_UNIT.AddUnitsByName} and @{Core.Set#SET_UNIT.RemoveUnitsByName} respectively. 
  -- These methods take a single UNIT name or an array of UNIT names to be added or removed from SET_UNIT.
  -- 
  -- ## SET_UNIT filter criteria
  -- 
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
  --    * @{#SET_UNIT.FilterZones}: Builds the SET_UNIT with the units within a @{Core.Zone#ZONE}.
  -- 
  -- ## SET_UNIT iterators
  -- 
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
  -- ## SET_UNIT atomic methods
  -- 
  -- Various methods exist for a SET_UNIT to perform actions or calculations and retrieve results from the SET_UNIT:
  -- 
  --   * @{#SET_UNIT.GetTypeNames}(): Retrieve the type names of the @{Wrapper.Unit}s in the SET, delimited by a comma.
  -- 
  -- ## SET_UNIT iterators
  -- 
  -- Once the filters have been defined and the SET_UNIT has been built, you can iterate the SET_UNIT with the available iterator methods.
  -- The iterator methods will walk the SET_UNIT set, and call for each element within the set a function that you provide.
  -- The following iterator methods are currently available within the SET_UNIT:
  -- 
  --   * @{#SET_UNIT.ForEachUnit}: Calls a function for each alive group it finds within the SET_UNIT.
  --   * @{#SET_UNIT.ForEachUnitInZone}: Iterate the SET_UNIT and call an iterator function for each **alive** UNIT object presence completely in a @{Zone}, providing the UNIT object and optional parameters to the called function.
  --   * @{#SET_UNIT.ForEachUnitNotInZone}: Iterate the SET_UNIT and call an iterator function for each **alive** UNIT object presence not in a @{Zone}, providing the UNIT object and optional parameters to the called function.
  --
  -- ## SET_UNIT trigger events on the UNIT objects.
  -- 
  -- The SET is derived from the FSM class, which provides extra capabilities to track the contents of the UNIT objects in the SET_UNIT.
  -- 
  -- ### When a UNIT object crashes or is dead, the SET_UNIT will trigger a **Dead** event.
  -- 
  -- You can handle the event using the OnBefore and OnAfter event handlers. 
  -- The event handlers need to have the paramters From, Event, To, GroupObject.
  -- The GroupObject is the UNIT object that is dead and within the SET_UNIT, and is passed as a parameter to the event handler.
  -- See the following example:
  -- 
  --        -- Create the SetCarrier SET_UNIT collection.
  --
  --        local SetHelicopter = SET_UNIT:New():FilterPrefixes( "Helicopter" ):FilterStart()
  -- 
  --        -- Put a Dead event handler on SetCarrier, to ensure that when a carrier unit is destroyed, that all internal parameters are reset.
  --
  --        function SetHelicopter:OnAfterDead( From, Event, To, UnitObject )
  --          self:F( { UnitObject = UnitObject:GetName() } )
  --        end
  -- 
  -- While this is a good example, there is a catch.
  -- Imageine you want to execute the code above, the the self would need to be from the object declared outside (above) the OnAfterDead method.
  -- So, the self would need to contain another object. Fortunately, this can be done, but you must use then the **`.`** notation for the method.
  -- See the modified example:
  -- 
  --        -- Now we have a constructor of the class AI_CARGO_DISPATCHER, that receives the SetHelicopter as a parameter.
  --        -- Within that constructor, we want to set an enclosed event handler OnAfterDead for SetHelicopter.
  --        -- But within the OnAfterDead method, we want to refer to the self variable of the AI_CARGO_DISPATCHER.
  -- 
  --        function ACLASS:New( SetCarrier, SetCargo, SetDeployZones )
  --         
  --          local self = BASE:Inherit( self, FSM:New() ) -- #AI_CARGO_DISPATCHER
  -- 
  --          -- Put a Dead event handler on SetCarrier, to ensure that when a carrier is destroyed, that all internal parameters are reset.
  --          -- Note the "." notation, and the explicit declaration of SetHelicopter, which would be using the ":" notation the implicit self variable declaration.
  --
  --          function SetHelicopter.OnAfterDead( SetHelicopter, From, Event, To, UnitObject )
  --            SetHelicopter:F( { UnitObject = UnitObject:GetName() } )
  --            self.array[UnitObject] = nil  -- So here I clear the array table entry of the self object ACLASS.
  --          end
  --        
  --        end
  -- ===
  -- @field #SET_UNIT SET_UNIT
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
  
  
  --- Get the first unit from the set.
  -- @function [parent=#SET_UNIT] GetFirst
  -- @param #SET_UNIT self
  -- @return Wrapper.Unit#UNIT The UNIT object.
  
  --- Creates a new SET_UNIT object, building a set of units belonging to a coalitions, categories, countries, types or with defined prefix names.
  -- @param #SET_UNIT self
  -- @return #SET_UNIT
  -- @usage
  -- -- Define a new SET_UNIT Object. This DBObject will contain a reference to all alive Units.
  -- DBObject = SET_UNIT:New()
  function SET_UNIT:New()
  
    -- Inherits from BASE
    local self = BASE:Inherit( self, SET_BASE:New( _DATABASE.UNITS ) ) -- Core.Set#SET_UNIT
  
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
  -- @param Core.Set#SET_UNIT self
  -- @param Wrapper.Unit#UNIT RemoveUnitNames A single name or an array of UNIT names.
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
  -- @return Wrapper.Unit#UNIT The found Unit.
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

    self.Filter.Coalitions = {}
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
      self:HandleEvent( EVENTS.Birth, self._EventOnBirth )
      self:HandleEvent( EVENTS.Dead, self._EventOnDeadOrCrash )
      self:HandleEvent( EVENTS.Crash, self._EventOnDeadOrCrash )
    end
    
    return self
  end

  
  
  --- Handles the Database to check on an event (birth) that the Object was added in the Database.
  -- This is required, because sometimes the _DATABASE birth event gets called later than the SET_BASE birth event!
  -- @param #SET_UNIT self
  -- @param Core.Event#EVENTDATA Event
  -- @return #string The name of the UNIT
  -- @return #table The UNIT
  function SET_UNIT:AddInDatabase( Event )
    self:F3( { Event } )
  
    if Event.IniObjectCategory == 1 then
      if not self.Database[Event.IniDCSUnitName] then
        self.Database[Event.IniDCSUnitName] = UNIT:Register( Event.IniDCSUnitName )
        self:T3( self.Database[Event.IniDCSUnitName] )
      end
    end
    
    return Event.IniDCSUnitName, self.Database[Event.IniDCSUnitName]
  end
  
  --- Handles the Database to check on any event that Object exists in the Database.
  -- This is required, because sometimes the _DATABASE event gets called later than the SET_BASE event or vise versa!
  -- @param #SET_UNIT self
  -- @param Core.Event#EVENTDATA Event
  -- @return #string The name of the UNIT
  -- @return #table The UNIT
  function SET_UNIT:FindInDatabase( Event )
    self:F2( { Event.IniDCSUnitName, self.Set[Event.IniDCSUnitName], Event } )
  
  
    return Event.IniDCSUnitName, self.Set[Event.IniDCSUnitName]
  end
  
  
  do -- Is Zone methods
  
    --- Check if minimal one element of the SET_UNIT is in the Zone.
    -- @param #SET_UNIT self
    -- @param Core.Zone#ZONE ZoneTest The Zone to be tested for.
    -- @return #boolean
    function SET_UNIT:IsPartiallyInZone( ZoneTest )
      
      local IsPartiallyInZone = false
      
      local function EvaluateZone( ZoneUnit )
      
        local ZoneUnitName =  ZoneUnit:GetName()
        self:F( { ZoneUnitName = ZoneUnitName } )
        if self:FindUnit( ZoneUnitName ) then
          IsPartiallyInZone = true
          self:F( { Found = true } )
          return false
        end
        
        return true
      end

      ZoneTest:SearchZone( EvaluateZone )
      
      return IsPartiallyInZone
    end
    
    
    --- Check if no element of the SET_UNIT is in the Zone.
    -- @param #SET_UNIT self
    -- @param Core.Zone#ZONE ZoneObject The Zone to be tested for.
    -- @return #boolean
    function SET_UNIT:IsNotInZone( Zone )
      
      local IsNotInZone = true
      
      local function EvaluateZone( ZoneUnit )
      
        local ZoneUnitName =  ZoneUnit:GetName()
        if self:FindUnit( ZoneUnitName ) then
          IsNotInZone = false
          return false
        end
        
        return true
      end
      
      Zone:SearchZone( EvaluateZone )
      
      return IsNotInZone
    end
    
  
    --- Check if minimal one element of the SET_UNIT is in the Zone.
    -- @param #SET_UNIT self
    -- @param #function IteratorFunction The function that will be called when there is an alive UNIT in the SET_UNIT. The function needs to accept a UNIT parameter.
    -- @return #SET_UNIT self
    function SET_UNIT:ForEachUnitInZone( IteratorFunction, ... )
      self:F2( arg )
      
      self:ForEach( IteratorFunction, arg, self:GetSet() )
    
      return self
    end
    
  
  end
  
  
  --- Iterate the SET_UNIT and call an interator function for each **alive** UNIT, providing the UNIT and optional parameters.
  -- @param #SET_UNIT self
  -- @param #function IteratorFunction The function that will be called when there is an alive UNIT in the SET_UNIT. The function needs to accept a UNIT parameter.
  -- @return #SET_UNIT self
  function SET_UNIT:ForEachUnit( IteratorFunction, ... )
    self:F2( arg )
    
    self:ForEach( IteratorFunction, arg, self:GetSet() )
  
    return self
  end
  
  --- Iterate the SET_UNIT **sorted *per Threat Level** and call an interator function for each **alive** UNIT, providing the UNIT and optional parameters.
  -- 
  -- @param #SET_UNIT self
  -- @param #number FromThreatLevel The TreatLevel to start the evaluation **From** (this must be a value between 0 and 10).
  -- @param #number ToThreatLevel The TreatLevel to stop the evaluation **To** (this must be a value between 0 and 10).
  -- @param #function IteratorFunction The function that will be called when there is an alive UNIT in the SET_UNIT. The function needs to accept a UNIT parameter.
  -- @return #SET_UNIT self
  -- @usage
  -- 
  --     UnitSet:ForEachUnitPerThreatLevel( 10, 0,
  --       -- @param Wrapper.Unit#UNIT UnitObject The UNIT object in the UnitSet, that will be passed to the local function for evaluation.
  --       function( UnitObject )
  --         .. logic ..
  --       end
  --     )
  -- 
  function SET_UNIT:ForEachUnitPerThreatLevel( FromThreatLevel, ToThreatLevel, IteratorFunction, ... ) --R2.1 Threat Level implementation
    self:F2( arg )
    
    local ThreatLevelSet = {}
    
    if self:Count() ~= 0 then
      for UnitName, UnitObject in pairs( self.Set ) do
        local Unit = UnitObject -- Wrapper.Unit#UNIT
      
        local ThreatLevel = Unit:GetThreatLevel()
        ThreatLevelSet[ThreatLevel] = ThreatLevelSet[ThreatLevel] or {}
        ThreatLevelSet[ThreatLevel].Set = ThreatLevelSet[ThreatLevel].Set or {}
        ThreatLevelSet[ThreatLevel].Set[UnitName] = UnitObject
        self:F( { ThreatLevel = ThreatLevel, ThreatLevelSet = ThreatLevelSet[ThreatLevel].Set } )
      end
      
      local ThreatLevelIncrement = FromThreatLevel <= ToThreatLevel and 1 or -1
      
      for ThreatLevel = FromThreatLevel, ToThreatLevel, ThreatLevelIncrement do
        self:F( { ThreatLevel = ThreatLevel } )
        local ThreatLevelItem = ThreatLevelSet[ThreatLevel]
        if ThreatLevelItem then
          self:ForEach( IteratorFunction, arg, ThreatLevelItem.Set )
        end
      end
    end
    
    return self
  end
  
  
  
  --- Iterate the SET_UNIT and call an iterator function for each **alive** UNIT presence completely in a @{Zone}, providing the UNIT and optional parameters to the called function.
  -- @param #SET_UNIT self
  -- @param Core.Zone#ZONE ZoneObject The Zone to be tested for.
  -- @param #function IteratorFunction The function that will be called when there is an alive UNIT in the SET_UNIT. The function needs to accept a UNIT parameter.
  -- @return #SET_UNIT self
  function SET_UNIT:ForEachUnitCompletelyInZone( ZoneObject, IteratorFunction, ... )
    self:F2( arg )
    
    self:ForEach( IteratorFunction, arg, self:GetSet(),
      --- @param Core.Zone#ZONE_BASE ZoneObject
      -- @param Wrapper.Unit#UNIT UnitObject
      function( ZoneObject, UnitObject )
        if UnitObject:IsInZone( ZoneObject ) then
          return true
        else
          return false
        end
      end, { ZoneObject } )
  
    return self
  end
  
  --- Iterate the SET_UNIT and call an iterator function for each **alive** UNIT presence not in a @{Zone}, providing the UNIT and optional parameters to the called function.
  -- @param #SET_UNIT self
  -- @param Core.Zone#ZONE ZoneObject The Zone to be tested for.
  -- @param #function IteratorFunction The function that will be called when there is an alive UNIT in the SET_UNIT. The function needs to accept a UNIT parameter.
  -- @return #SET_UNIT self
  function SET_UNIT:ForEachUnitNotInZone( ZoneObject, IteratorFunction, ... )
    self:F2( arg )
    
    self:ForEach( IteratorFunction, arg, self:GetSet(),
      --- @param Core.Zone#ZONE_BASE ZoneObject
      -- @param Wrapper.Unit#UNIT UnitObject
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
      local TextUnit = UnitData -- Wrapper.Unit#UNIT
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
      local ThreatUnit = UnitData -- Wrapper.Unit#UNIT
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
  
  --- Calculate the maxium A2G threat level of the SET_UNIT.
  -- @param #SET_UNIT self
  -- @return #number The maximum threatlevel
  function SET_UNIT:CalculateThreatLevelA2G()
    
    local MaxThreatLevelA2G = 0
    local MaxThreatText = ""
    for UnitName, UnitData in pairs( self:GetSet() ) do
      local ThreatUnit = UnitData -- Wrapper.Unit#UNIT
      local ThreatLevelA2G, ThreatText = ThreatUnit:GetThreatLevel()
      if ThreatLevelA2G > MaxThreatLevelA2G then
        MaxThreatLevelA2G = ThreatLevelA2G
        MaxThreatText = ThreatText
      end
    end
  
    self:F( { MaxThreatLevelA2G = MaxThreatLevelA2G, MaxThreatText = MaxThreatText } )
    return MaxThreatLevelA2G, MaxThreatText
    
  end
  
  --- Get the center coordinate of the SET_UNIT.
  -- @param #SET_UNIT self
  -- @return Core.Point#COORDINATE The center coordinate of all the units in the set, including heading in degrees and speed in mps in case of moving units.
  function SET_UNIT:GetCoordinate()
  
    local Coordinate = self:GetFirst():GetCoordinate()
    
    local x1 = Coordinate.x
    local x2 = Coordinate.x
    local y1 = Coordinate.y
    local y2 = Coordinate.y
    local z1 = Coordinate.z
    local z2 = Coordinate.z
    local MaxVelocity = 0
    local AvgHeading = nil
    local MovingCount = 0
  
    for UnitName, UnitData in pairs( self:GetSet() ) do
    
      local Unit = UnitData -- Wrapper.Unit#UNIT
      local Coordinate = Unit:GetCoordinate()
  
      x1 = ( Coordinate.x < x1 ) and Coordinate.x or x1
      x2 = ( Coordinate.x > x2 ) and Coordinate.x or x2
      y1 = ( Coordinate.y < y1 ) and Coordinate.y or y1
      y2 = ( Coordinate.y > y2 ) and Coordinate.y or y2
      z1 = ( Coordinate.y < z1 ) and Coordinate.z or z1
      z2 = ( Coordinate.y > z2 ) and Coordinate.z or z2
  
      local Velocity = Coordinate:GetVelocity()
      if Velocity ~= 0  then
        MaxVelocity = ( MaxVelocity < Velocity ) and Velocity or MaxVelocity
        local Heading = Coordinate:GetHeading()
        AvgHeading = AvgHeading and ( AvgHeading + Heading ) or Heading
        MovingCount = MovingCount + 1
      end
    end
  
    AvgHeading = AvgHeading and ( AvgHeading / MovingCount )
    
    Coordinate.x = ( x2 - x1 ) / 2 + x1
    Coordinate.y = ( y2 - y1 ) / 2 + y1
    Coordinate.z = ( z2 - z1 ) / 2 + z1
    Coordinate:SetHeading( AvgHeading )
    Coordinate:SetVelocity( MaxVelocity )
  
    self:F( { Coordinate = Coordinate } )
    return Coordinate
  
  end
  
  --- Get the maximum velocity of the SET_UNIT.
  -- @param #SET_UNIT self
  -- @return #number The speed in mps in case of moving units.
  function SET_UNIT:GetVelocity()
  
    local Coordinate = self:GetFirst():GetCoordinate()
    
    local MaxVelocity = 0
  
    for UnitName, UnitData in pairs( self:GetSet() ) do
    
      local Unit = UnitData -- Wrapper.Unit#UNIT
      local Coordinate = Unit:GetCoordinate()
  
      local Velocity = Coordinate:GetVelocity()
      if Velocity ~= 0  then
        MaxVelocity = ( MaxVelocity < Velocity ) and Velocity or MaxVelocity
      end
    end
  
    self:F( { MaxVelocity = MaxVelocity } )
    return MaxVelocity
  
  end
  
  --- Get the average heading of the SET_UNIT.
  -- @param #SET_UNIT self
  -- @return #number Heading Heading in degrees and speed in mps in case of moving units.
  function SET_UNIT:GetHeading()
  
    local HeadingSet = nil
    local MovingCount = 0
  
    for UnitName, UnitData in pairs( self:GetSet() ) do
    
      local Unit = UnitData -- Wrapper.Unit#UNIT
      local Coordinate = Unit:GetCoordinate()
  
      local Velocity = Coordinate:GetVelocity()
      if Velocity ~= 0  then
        local Heading = Coordinate:GetHeading()
        if HeadingSet == nil then
          HeadingSet = Heading
        else
          local HeadingDiff = ( HeadingSet - Heading + 180 + 360 ) % 360 - 180
          HeadingDiff = math.abs( HeadingDiff )
          if HeadingDiff > 5 then
            HeadingSet = nil
            break
          end
        end        
      end
    end
  
    return HeadingSet
  
  end
  
  
  
  --- Returns if the @{Set} has targets having a radar (of a given type).
  -- @param #SET_UNIT self
  -- @param DCS#Unit.RadarType RadarType
  -- @return #number The amount of radars in the Set with the given type
  function SET_UNIT:HasRadar( RadarType )
    self:F2( RadarType )
  
    local RadarCount = 0
    for UnitID, UnitData in pairs( self:GetSet()) do
      local UnitSensorTest = UnitData -- Wrapper.Unit#UNIT
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
      local UnitSEAD = UnitData -- Wrapper.Unit#UNIT
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
      local UnitTest = UnitData -- Wrapper.Unit#UNIT
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
      local UnitTest = UnitData -- Wrapper.Unit#UNIT
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
  -- @param Wrapper.Unit#UNIT MUnit
  -- @return #SET_UNIT self
  function SET_UNIT:IsIncludeObject( MUnit )
    self:F2( MUnit )
    local MUnitInclude = true
  
    if self.Filter.Coalitions then
      local MUnitCoalition = false
      for CoalitionID, CoalitionName in pairs( self.Filter.Coalitions ) do
        self:F( { "Coalition:", MUnit:GetCoalition(), self.FilterMeta.Coalitions[CoalitionName], CoalitionName } )
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
  
  
  --- Retrieve the type names of the @{Wrapper.Unit}s in the SET, delimited by an optional delimiter.
  -- @param #SET_UNIT self
  -- @param #string Delimiter (optional) The delimiter, which is default a comma.
  -- @return #string The types of the @{Wrapper.Unit}s delimited.
  function SET_UNIT:GetTypeNames( Delimiter )
  
    Delimiter = Delimiter or ", "
    local TypeReport = REPORT:New()
    local Types = {}
    
    for UnitName, UnitData in pairs( self:GetSet() ) do
    
      local Unit = UnitData -- Wrapper.Unit#UNIT
      local UnitTypeName = Unit:GetTypeName()
      
      if not Types[UnitTypeName] then
        Types[UnitTypeName] = UnitTypeName
        TypeReport:Add( UnitTypeName )
      end
    end
    
    return TypeReport:Text( Delimiter )
  end
  
end

do -- SET_STATIC

  --- @type SET_STATIC
  -- @extends Core.Set#SET_BASE
  
  --- Mission designers can use the SET_STATIC class to build sets of Statics belonging to certain:
  -- 
  --  * Coalitions
  --  * Categories
  --  * Countries
  --  * Static types
  --  * Starting with certain prefix strings.
  --  
  -- ## SET_STATIC constructor
  --
  -- Create a new SET_STATIC object with the @{#SET_STATIC.New} method:
  -- 
  --    * @{#SET_STATIC.New}: Creates a new SET_STATIC object.
  --   
  -- ## Add or Remove STATIC(s) from SET_STATIC
  --
  -- STATICs can be added and removed using the @{Core.Set#SET_STATIC.AddStaticsByName} and @{Core.Set#SET_STATIC.RemoveStaticsByName} respectively. 
  -- These methods take a single STATIC name or an array of STATIC names to be added or removed from SET_STATIC.
  -- 
  -- ## SET_STATIC filter criteria
  -- 
  -- You can set filter criteria to define the set of units within the SET_STATIC.
  -- Filter criteria are defined by:
  -- 
  --    * @{#SET_STATIC.FilterCoalitions}: Builds the SET_STATIC with the units belonging to the coalition(s).
  --    * @{#SET_STATIC.FilterCategories}: Builds the SET_STATIC with the units belonging to the category(ies).
  --    * @{#SET_STATIC.FilterTypes}: Builds the SET_STATIC with the units belonging to the unit type(s).
  --    * @{#SET_STATIC.FilterCountries}: Builds the SET_STATIC with the units belonging to the country(ies).
  --    * @{#SET_STATIC.FilterPrefixes}: Builds the SET_STATIC with the units starting with the same prefix string(s).
  --   
  -- Once the filter criteria have been set for the SET_STATIC, you can start filtering using:
  -- 
  --   * @{#SET_STATIC.FilterStart}: Starts the filtering of the units within the SET_STATIC.
  -- 
  -- Planned filter criteria within development are (so these are not yet available):
  -- 
  --    * @{#SET_STATIC.FilterZones}: Builds the SET_STATIC with the units within a @{Core.Zone#ZONE}.
  -- 
  -- ## SET_STATIC iterators
  -- 
  -- Once the filters have been defined and the SET_STATIC has been built, you can iterate the SET_STATIC with the available iterator methods.
  -- The iterator methods will walk the SET_STATIC set, and call for each element within the set a function that you provide.
  -- The following iterator methods are currently available within the SET_STATIC:
  -- 
  --   * @{#SET_STATIC.ForEachStatic}: Calls a function for each alive unit it finds within the SET_STATIC.
  --   * @{#SET_GROUP.ForEachGroupCompletelyInZone}: Iterate the SET_GROUP and call an iterator function for each **alive** GROUP presence completely in a @{Zone}, providing the GROUP and optional parameters to the called function.
  --   * @{#SET_GROUP.ForEachGroupNotInZone}: Iterate the SET_GROUP and call an iterator function for each **alive** GROUP presence not in a @{Zone}, providing the GROUP and optional parameters to the called function.
  --   
  -- Planned iterators methods in development are (so these are not yet available):
  -- 
  --   * @{#SET_STATIC.ForEachStaticInZone}: Calls a function for each unit contained within the SET_STATIC.
  --   * @{#SET_STATIC.ForEachStaticCompletelyInZone}: Iterate and call an iterator function for each **alive** STATIC presence completely in a @{Zone}, providing the STATIC and optional parameters to the called function.
  --   * @{#SET_STATIC.ForEachStaticNotInZone}: Iterate and call an iterator function for each **alive** STATIC presence not in a @{Zone}, providing the STATIC and optional parameters to the called function.
  -- 
  -- ## SET_STATIC atomic methods
  -- 
  -- Various methods exist for a SET_STATIC to perform actions or calculations and retrieve results from the SET_STATIC:
  -- 
  --   * @{#SET_STATIC.GetTypeNames}(): Retrieve the type names of the @{Static}s in the SET, delimited by a comma.
  -- 
  -- ===
  -- @field #SET_STATIC SET_STATIC
  SET_STATIC = {
    ClassName = "SET_STATIC",
    Statics = {},
    Filter = {
      Coalitions = nil,
      Categories = nil,
      Types = nil,
      Countries = nil,
      StaticPrefixes = nil,
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
        ground = Unit.Category.GROUND_STATIC,
        ship = Unit.Category.SHIP,
        structure = Unit.Category.STRUCTURE,
      },
    },
  }
  
  
  --- Get the first unit from the set.
  -- @function [parent=#SET_STATIC] GetFirst
  -- @param #SET_STATIC self
  -- @return Wrapper.Static#STATIC The STATIC object.
  
  --- Creates a new SET_STATIC object, building a set of units belonging to a coalitions, categories, countries, types or with defined prefix names.
  -- @param #SET_STATIC self
  -- @return #SET_STATIC
  -- @usage
  -- -- Define a new SET_STATIC Object. This DBObject will contain a reference to all alive Statics.
  -- DBObject = SET_STATIC:New()
  function SET_STATIC:New()
  
    -- Inherits from BASE
    local self = BASE:Inherit( self, SET_BASE:New( _DATABASE.STATICS ) ) -- Core.Set#SET_STATIC
  
    return self
  end
  
  --- Add STATIC(s) to SET_STATIC.
  -- @param #SET_STATIC self
  -- @param #string AddStatic A single STATIC.
  -- @return #SET_STATIC self
  function SET_STATIC:AddStatic( AddStatic )
    self:F2( AddStatic:GetName() )
  
    self:Add( AddStatic:GetName(), AddStatic )
      
    return self
  end
  
  
  --- Add STATIC(s) to SET_STATIC.
  -- @param #SET_STATIC self
  -- @param #string AddStaticNames A single name or an array of STATIC names.
  -- @return #SET_STATIC self
  function SET_STATIC:AddStaticsByName( AddStaticNames )
  
    local AddStaticNamesArray = ( type( AddStaticNames ) == "table" ) and AddStaticNames or { AddStaticNames }
    
    self:T( AddStaticNamesArray )
    for AddStaticID, AddStaticName in pairs( AddStaticNamesArray ) do
      self:Add( AddStaticName, STATIC:FindByName( AddStaticName ) )
    end
      
    return self
  end
  
  --- Remove STATIC(s) from SET_STATIC.
  -- @param Core.Set#SET_STATIC self
  -- @param Wrapper.Static#STATIC RemoveStaticNames A single name or an array of STATIC names.
  -- @return self
  function SET_STATIC:RemoveStaticsByName( RemoveStaticNames )
  
    local RemoveStaticNamesArray = ( type( RemoveStaticNames ) == "table" ) and RemoveStaticNames or { RemoveStaticNames }
    
    for RemoveStaticID, RemoveStaticName in pairs( RemoveStaticNamesArray ) do
      self:Remove( RemoveStaticName )
    end
      
    return self
  end
  
  
  --- Finds a Static based on the Static Name.
  -- @param #SET_STATIC self
  -- @param #string StaticName
  -- @return Wrapper.Static#STATIC The found Static.
  function SET_STATIC:FindStatic( StaticName )
  
    local StaticFound = self.Set[StaticName]
    return StaticFound
  end
  
  
  
  --- Builds a set of units of coalitions.
  -- Possible current coalitions are red, blue and neutral.
  -- @param #SET_STATIC self
  -- @param #string Coalitions Can take the following values: "red", "blue", "neutral".
  -- @return #SET_STATIC self
  function SET_STATIC:FilterCoalitions( Coalitions )
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
  -- @param #SET_STATIC self
  -- @param #string Categories Can take the following values: "plane", "helicopter", "ground", "ship".
  -- @return #SET_STATIC self
  function SET_STATIC:FilterCategories( Categories )
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
  -- @param #SET_STATIC self
  -- @param #string Types Can take those type strings known within DCS world.
  -- @return #SET_STATIC self
  function SET_STATIC:FilterTypes( Types )
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
  -- @param #SET_STATIC self
  -- @param #string Countries Can take those country strings known within DCS world.
  -- @return #SET_STATIC self
  function SET_STATIC:FilterCountries( Countries )
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
  -- @param #SET_STATIC self
  -- @param #string Prefixes The prefix of which the unit name starts with.
  -- @return #SET_STATIC self
  function SET_STATIC:FilterPrefixes( Prefixes )
    if not self.Filter.StaticPrefixes then
      self.Filter.StaticPrefixes = {}
    end
    if type( Prefixes ) ~= "table" then
      Prefixes = { Prefixes }
    end
    for PrefixID, Prefix in pairs( Prefixes ) do
      self.Filter.StaticPrefixes[Prefix] = Prefix
    end
    return self
  end
  
  
  --- Starts the filtering.
  -- @param #SET_STATIC self
  -- @return #SET_STATIC self
  function SET_STATIC:FilterStart()
  
    if _DATABASE then
      self:_FilterStart()
      self:HandleEvent( EVENTS.Birth, self._EventOnBirth )
      self:HandleEvent( EVENTS.Dead, self._EventOnDeadOrCrash )
      self:HandleEvent( EVENTS.Crash, self._EventOnDeadOrCrash )
    end
    
    return self
  end
  
  --- Handles the Database to check on an event (birth) that the Object was added in the Database.
  -- This is required, because sometimes the _DATABASE birth event gets called later than the SET_BASE birth event!
  -- @param #SET_STATIC self
  -- @param Core.Event#EVENTDATA Event
  -- @return #string The name of the STATIC
  -- @return #table The STATIC
  function SET_STATIC:AddInDatabase( Event )
    self:F3( { Event } )
  
    if Event.IniObjectCategory == Object.Category.STATIC then
      if not self.Database[Event.IniDCSStaticName] then
        self.Database[Event.IniDCSStaticName] = STATIC:Register( Event.IniDCSStaticName )
        self:T3( self.Database[Event.IniDCSStaticName] )
      end
    end
    
    return Event.IniDCSStaticName, self.Database[Event.IniDCSStaticName]
  end
  
  --- Handles the Database to check on any event that Object exists in the Database.
  -- This is required, because sometimes the _DATABASE event gets called later than the SET_BASE event or vise versa!
  -- @param #SET_STATIC self
  -- @param Core.Event#EVENTDATA Event
  -- @return #string The name of the STATIC
  -- @return #table The STATIC
  function SET_STATIC:FindInDatabase( Event )
    self:F2( { Event.IniDCSStaticName, self.Set[Event.IniDCSStaticName], Event } )
  
  
    return Event.IniDCSStaticName, self.Set[Event.IniDCSStaticName]
  end
  
  
  do -- Is Zone methods
  
    --- Check if minimal one element of the SET_STATIC is in the Zone.
    -- @param #SET_STATIC self
    -- @param Core.Zone#ZONE Zone The Zone to be tested for.
    -- @return #boolean
    function SET_STATIC:IsPatriallyInZone( Zone )
      
      local IsPartiallyInZone = false
      
      local function EvaluateZone( ZoneStatic )
      
        local ZoneStaticName =  ZoneStatic:GetName()
        if self:FindStatic( ZoneStaticName ) then
          IsPartiallyInZone = true
          return false
        end
        
        return true
      end
      
      return IsPartiallyInZone
    end
    
    
    --- Check if no element of the SET_STATIC is in the Zone.
    -- @param #SET_STATIC self
    -- @param Core.Zone#ZONE ZoneObject The Zone to be tested for.
    -- @return #boolean
    function SET_STATIC:IsNotInZone( Zone )
      
      local IsNotInZone = true
      
      local function EvaluateZone( ZoneStatic )
      
        local ZoneStaticName =  ZoneStatic:GetName()
        if self:FindStatic( ZoneStaticName ) then
          IsNotInZone = false
          return false
        end
        
        return true
      end
      
      Zone:Search( EvaluateZone )
      
      return IsNotInZone
    end
    
  
    --- Check if minimal one element of the SET_STATIC is in the Zone.
    -- @param #SET_STATIC self
    -- @param #function IteratorFunction The function that will be called when there is an alive STATIC in the SET_STATIC. The function needs to accept a STATIC parameter.
    -- @return #SET_STATIC self
    function SET_STATIC:ForEachStaticInZone( IteratorFunction, ... )
      self:F2( arg )
      
      self:ForEach( IteratorFunction, arg, self:GetSet() )
    
      return self
    end
    
  
  end
  
  
  --- Iterate the SET_STATIC and call an interator function for each **alive** STATIC, providing the STATIC and optional parameters.
  -- @param #SET_STATIC self
  -- @param #function IteratorFunction The function that will be called when there is an alive STATIC in the SET_STATIC. The function needs to accept a STATIC parameter.
  -- @return #SET_STATIC self
  function SET_STATIC:ForEachStatic( IteratorFunction, ... )
    self:F2( arg )
    
    self:ForEach( IteratorFunction, arg, self:GetSet() )
  
    return self
  end
  
  
  --- Iterate the SET_STATIC and call an iterator function for each **alive** STATIC presence completely in a @{Zone}, providing the STATIC and optional parameters to the called function.
  -- @param #SET_STATIC self
  -- @param Core.Zone#ZONE ZoneObject The Zone to be tested for.
  -- @param #function IteratorFunction The function that will be called when there is an alive STATIC in the SET_STATIC. The function needs to accept a STATIC parameter.
  -- @return #SET_STATIC self
  function SET_STATIC:ForEachStaticCompletelyInZone( ZoneObject, IteratorFunction, ... )
    self:F2( arg )
    
    self:ForEach( IteratorFunction, arg, self:GetSet(),
      --- @param Core.Zone#ZONE_BASE ZoneObject
      -- @param Wrapper.Static#STATIC StaticObject
      function( ZoneObject, StaticObject )
        if StaticObject:IsInZone( ZoneObject ) then
          return true
        else
          return false
        end
      end, { ZoneObject } )
  
    return self
  end
  
  --- Iterate the SET_STATIC and call an iterator function for each **alive** STATIC presence not in a @{Zone}, providing the STATIC and optional parameters to the called function.
  -- @param #SET_STATIC self
  -- @param Core.Zone#ZONE ZoneObject The Zone to be tested for.
  -- @param #function IteratorFunction The function that will be called when there is an alive STATIC in the SET_STATIC. The function needs to accept a STATIC parameter.
  -- @return #SET_STATIC self
  function SET_STATIC:ForEachStaticNotInZone( ZoneObject, IteratorFunction, ... )
    self:F2( arg )
    
    self:ForEach( IteratorFunction, arg, self:GetSet(),
      --- @param Core.Zone#ZONE_BASE ZoneObject
      -- @param Wrapper.Static#STATIC StaticObject
      function( ZoneObject, StaticObject )
        if StaticObject:IsNotInZone( ZoneObject ) then
          return true
        else
          return false
        end
      end, { ZoneObject } )
  
    return self
  end
  
  --- Returns map of unit types.
  -- @param #SET_STATIC self
  -- @return #map<#string,#number> A map of the unit types found. The key is the StaticTypeName and the value is the amount of unit types found.
  function SET_STATIC:GetStaticTypes()
    self:F2()
  
    local MT = {} -- Message Text
    local StaticTypes = {}
    
    for StaticID, StaticData in pairs( self:GetSet() ) do
      local TextStatic = StaticData -- Wrapper.Static#STATIC
      if TextStatic:IsAlive() then
        local StaticType = TextStatic:GetTypeName()
    
        if not StaticTypes[StaticType] then
          StaticTypes[StaticType] = 1
        else
          StaticTypes[StaticType] = StaticTypes[StaticType] + 1
        end
      end
    end
  
    for StaticTypeID, StaticType in pairs( StaticTypes ) do
      MT[#MT+1] = StaticType .. " of " .. StaticTypeID
    end
  
    return StaticTypes
  end
  
  
  --- Returns a comma separated string of the unit types with a count in the  @{Set}.
  -- @param #SET_STATIC self
  -- @return #string The unit types string
  function SET_STATIC:GetStaticTypesText()
    self:F2()
  
    local MT = {} -- Message Text
    local StaticTypes = self:GetStaticTypes()
    
    for StaticTypeID, StaticType in pairs( StaticTypes ) do
      MT[#MT+1] = StaticType .. " of " .. StaticTypeID
    end
  
    return table.concat( MT, ", " )
  end
  
  --- Get the center coordinate of the SET_STATIC.
  -- @param #SET_STATIC self
  -- @return Core.Point#COORDINATE The center coordinate of all the units in the set, including heading in degrees and speed in mps in case of moving units.
  function SET_STATIC:GetCoordinate()
  
    local Coordinate = self:GetFirst():GetCoordinate()
    
    local x1 = Coordinate.x
    local x2 = Coordinate.x
    local y1 = Coordinate.y
    local y2 = Coordinate.y
    local z1 = Coordinate.z
    local z2 = Coordinate.z
    local MaxVelocity = 0
    local AvgHeading = nil
    local MovingCount = 0
  
    for StaticName, StaticData in pairs( self:GetSet() ) do
    
      local Static = StaticData -- Wrapper.Static#STATIC
      local Coordinate = Static:GetCoordinate()
  
      x1 = ( Coordinate.x < x1 ) and Coordinate.x or x1
      x2 = ( Coordinate.x > x2 ) and Coordinate.x or x2
      y1 = ( Coordinate.y < y1 ) and Coordinate.y or y1
      y2 = ( Coordinate.y > y2 ) and Coordinate.y or y2
      z1 = ( Coordinate.y < z1 ) and Coordinate.z or z1
      z2 = ( Coordinate.y > z2 ) and Coordinate.z or z2
  
      local Velocity = Coordinate:GetVelocity()
      if Velocity ~= 0  then
        MaxVelocity = ( MaxVelocity < Velocity ) and Velocity or MaxVelocity
        local Heading = Coordinate:GetHeading()
        AvgHeading = AvgHeading and ( AvgHeading + Heading ) or Heading
        MovingCount = MovingCount + 1
      end
    end
  
    AvgHeading = AvgHeading and ( AvgHeading / MovingCount )
    
    Coordinate.x = ( x2 - x1 ) / 2 + x1
    Coordinate.y = ( y2 - y1 ) / 2 + y1
    Coordinate.z = ( z2 - z1 ) / 2 + z1
    Coordinate:SetHeading( AvgHeading )
    Coordinate:SetVelocity( MaxVelocity )
  
    self:F( { Coordinate = Coordinate } )
    return Coordinate
  
  end
  
  --- Get the maximum velocity of the SET_STATIC.
  -- @param #SET_STATIC self
  -- @return #number The speed in mps in case of moving units.
  function SET_STATIC:GetVelocity()
  
    return 0
  
  end
  
  --- Get the average heading of the SET_STATIC.
  -- @param #SET_STATIC self
  -- @return #number Heading Heading in degrees and speed in mps in case of moving units.
  function SET_STATIC:GetHeading()
  
    local HeadingSet = nil
    local MovingCount = 0
  
    for StaticName, StaticData in pairs( self:GetSet() ) do
    
      local Static = StaticData -- Wrapper.Static#STATIC
      local Coordinate = Static:GetCoordinate()
  
      local Velocity = Coordinate:GetVelocity()
      if Velocity ~= 0  then
        local Heading = Coordinate:GetHeading()
        if HeadingSet == nil then
          HeadingSet = Heading
        else
          local HeadingDiff = ( HeadingSet - Heading + 180 + 360 ) % 360 - 180
          HeadingDiff = math.abs( HeadingDiff )
          if HeadingDiff > 5 then
            HeadingSet = nil
            break
          end
        end        
      end
    end
  
    return HeadingSet
  
  end
  
  
  ---
  -- @param #SET_STATIC self
  -- @param Wrapper.Static#STATIC MStatic
  -- @return #SET_STATIC self
  function SET_STATIC:IsIncludeObject( MStatic )
    self:F2( MStatic )
    local MStaticInclude = true
  
    if self.Filter.Coalitions then
      local MStaticCoalition = false
      for CoalitionID, CoalitionName in pairs( self.Filter.Coalitions ) do
        self:T3( { "Coalition:", MStatic:GetCoalition(), self.FilterMeta.Coalitions[CoalitionName], CoalitionName } )
        if self.FilterMeta.Coalitions[CoalitionName] and self.FilterMeta.Coalitions[CoalitionName] == MStatic:GetCoalition() then
          MStaticCoalition = true
        end
      end
      MStaticInclude = MStaticInclude and MStaticCoalition
    end
    
    if self.Filter.Categories then
      local MStaticCategory = false
      for CategoryID, CategoryName in pairs( self.Filter.Categories ) do
        self:T3( { "Category:", MStatic:GetDesc().category, self.FilterMeta.Categories[CategoryName], CategoryName } )
        if self.FilterMeta.Categories[CategoryName] and self.FilterMeta.Categories[CategoryName] == MStatic:GetDesc().category then
          MStaticCategory = true
        end
      end
      MStaticInclude = MStaticInclude and MStaticCategory
    end
    
    if self.Filter.Types then
      local MStaticType = false
      for TypeID, TypeName in pairs( self.Filter.Types ) do
        self:T3( { "Type:", MStatic:GetTypeName(), TypeName } )
        if TypeName == MStatic:GetTypeName() then
          MStaticType = true
        end
      end
      MStaticInclude = MStaticInclude and MStaticType
    end
    
    if self.Filter.Countries then
      local MStaticCountry = false
      for CountryID, CountryName in pairs( self.Filter.Countries ) do
        self:T3( { "Country:", MStatic:GetCountry(), CountryName } )
        if country.id[CountryName] == MStatic:GetCountry() then
          MStaticCountry = true
        end
      end
      MStaticInclude = MStaticInclude and MStaticCountry
    end
  
    if self.Filter.StaticPrefixes then
      local MStaticPrefix = false
      for StaticPrefixId, StaticPrefix in pairs( self.Filter.StaticPrefixes ) do
        self:T3( { "Prefix:", string.find( MStatic:GetName(), StaticPrefix, 1 ), StaticPrefix } )
        if string.find( MStatic:GetName(), StaticPrefix, 1 ) then
          MStaticPrefix = true
        end
      end
      MStaticInclude = MStaticInclude and MStaticPrefix
    end
  
    self:T2( MStaticInclude )
    return MStaticInclude
  end
  
  
  --- Retrieve the type names of the @{Static}s in the SET, delimited by an optional delimiter.
  -- @param #SET_STATIC self
  -- @param #string Delimiter (optional) The delimiter, which is default a comma.
  -- @return #string The types of the @{Static}s delimited.
  function SET_STATIC:GetTypeNames( Delimiter )
  
    Delimiter = Delimiter or ", "
    local TypeReport = REPORT:New()
    local Types = {}
    
    for StaticName, StaticData in pairs( self:GetSet() ) do
    
      local Static = StaticData -- Wrapper.Static#STATIC
      local StaticTypeName = Static:GetTypeName()
      
      if not Types[StaticTypeName] then
        Types[StaticTypeName] = StaticTypeName
        TypeReport:Add( StaticTypeName )
      end
    end
    
    return TypeReport:Text( Delimiter )
  end
  
end


--- SET_CLIENT


--- @type SET_CLIENT
-- @extends Core.Set#SET_BASE



--- Mission designers can use the @{Core.Set#SET_CLIENT} class to build sets of units belonging to certain:
-- 
--  * Coalitions
--  * Categories
--  * Countries
--  * Client types
--  * Starting with certain prefix strings.
--  
-- ## SET_CLIENT constructor
-- 
-- Create a new SET_CLIENT object with the @{#SET_CLIENT.New} method:
-- 
--    * @{#SET_CLIENT.New}: Creates a new SET_CLIENT object.
--   
-- ## Add or Remove CLIENT(s) from SET_CLIENT 
-- 
-- CLIENTs can be added and removed using the @{Core.Set#SET_CLIENT.AddClientsByName} and @{Core.Set#SET_CLIENT.RemoveClientsByName} respectively. 
-- These methods take a single CLIENT name or an array of CLIENT names to be added or removed from SET_CLIENT.
-- 
-- ## SET_CLIENT filter criteria
-- 
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
--    * @{#SET_CLIENT.FilterZones}: Builds the SET_CLIENT with the clients within a @{Core.Zone#ZONE}.
-- 
-- ## SET_CLIENT iterators
-- 
-- Once the filters have been defined and the SET_CLIENT has been built, you can iterate the SET_CLIENT with the available iterator methods.
-- The iterator methods will walk the SET_CLIENT set, and call for each element within the set a function that you provide.
-- The following iterator methods are currently available within the SET_CLIENT:
-- 
--   * @{#SET_CLIENT.ForEachClient}: Calls a function for each alive client it finds within the SET_CLIENT.
-- 
-- ===
-- @field #SET_CLIENT SET_CLIENT 
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
-- @param Core.Set#SET_CLIENT self
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
-- @param Core.Set#SET_CLIENT self
-- @param Wrapper.Client#CLIENT RemoveClientNames A single name or an array of CLIENT names.
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
-- @return Wrapper.Client#CLIENT The found Client.
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
    self:HandleEvent( EVENTS.Birth, self._EventOnBirth )
    self:HandleEvent( EVENTS.Dead, self._EventOnDeadOrCrash )
    self:HandleEvent( EVENTS.Crash, self._EventOnDeadOrCrash )
  end
  
  return self
end

--- Handles the Database to check on an event (birth) that the Object was added in the Database.
-- This is required, because sometimes the _DATABASE birth event gets called later than the SET_BASE birth event!
-- @param #SET_CLIENT self
-- @param Core.Event#EVENTDATA Event
-- @return #string The name of the CLIENT
-- @return #table The CLIENT
function SET_CLIENT:AddInDatabase( Event )
  self:F3( { Event } )

  return Event.IniDCSUnitName, self.Database[Event.IniDCSUnitName]
end

--- Handles the Database to check on any event that Object exists in the Database.
-- This is required, because sometimes the _DATABASE event gets called later than the SET_BASE event or vise versa!
-- @param #SET_CLIENT self
-- @param Core.Event#EVENTDATA Event
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
  
  self:ForEach( IteratorFunction, arg, self:GetSet() )

  return self
end

--- Iterate the SET_CLIENT and call an iterator function for each **alive** CLIENT presence completely in a @{Zone}, providing the CLIENT and optional parameters to the called function.
-- @param #SET_CLIENT self
-- @param Core.Zone#ZONE ZoneObject The Zone to be tested for.
-- @param #function IteratorFunction The function that will be called when there is an alive CLIENT in the SET_CLIENT. The function needs to accept a CLIENT parameter.
-- @return #SET_CLIENT self
function SET_CLIENT:ForEachClientInZone( ZoneObject, IteratorFunction, ... )
  self:F2( arg )
  
  self:ForEach( IteratorFunction, arg, self:GetSet(),
    --- @param Core.Zone#ZONE_BASE ZoneObject
    -- @param Wrapper.Client#CLIENT ClientObject
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
-- @param Core.Zone#ZONE ZoneObject The Zone to be tested for.
-- @param #function IteratorFunction The function that will be called when there is an alive CLIENT in the SET_CLIENT. The function needs to accept a CLIENT parameter.
-- @return #SET_CLIENT self
function SET_CLIENT:ForEachClientNotInZone( ZoneObject, IteratorFunction, ... )
  self:F2( arg )
  
  self:ForEach( IteratorFunction, arg, self:GetSet(),
    --- @param Core.Zone#ZONE_BASE ZoneObject
    -- @param Wrapper.Client#CLIENT ClientObject
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
-- @param Wrapper.Client#CLIENT MClient
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

--- SET_PLAYER


--- @type SET_PLAYER
-- @extends Core.Set#SET_BASE



--- Mission designers can use the @{Core.Set#SET_PLAYER} class to build sets of units belonging to alive players:
-- 
-- ## SET_PLAYER constructor
-- 
-- Create a new SET_PLAYER object with the @{#SET_PLAYER.New} method:
-- 
--    * @{#SET_PLAYER.New}: Creates a new SET_PLAYER object.
--   
-- ## SET_PLAYER filter criteria
-- 
-- You can set filter criteria to define the set of clients within the SET_PLAYER.
-- Filter criteria are defined by:
-- 
--    * @{#SET_PLAYER.FilterCoalitions}: Builds the SET_PLAYER with the clients belonging to the coalition(s).
--    * @{#SET_PLAYER.FilterCategories}: Builds the SET_PLAYER with the clients belonging to the category(ies).
--    * @{#SET_PLAYER.FilterTypes}: Builds the SET_PLAYER with the clients belonging to the client type(s).
--    * @{#SET_PLAYER.FilterCountries}: Builds the SET_PLAYER with the clients belonging to the country(ies).
--    * @{#SET_PLAYER.FilterPrefixes}: Builds the SET_PLAYER with the clients starting with the same prefix string(s).
--   
-- Once the filter criteria have been set for the SET_PLAYER, you can start filtering using:
-- 
--   * @{#SET_PLAYER.FilterStart}: Starts the filtering of the clients within the SET_PLAYER.
-- 
-- Planned filter criteria within development are (so these are not yet available):
-- 
--    * @{#SET_PLAYER.FilterZones}: Builds the SET_PLAYER with the clients within a @{Core.Zone#ZONE}.
-- 
-- ## SET_PLAYER iterators
-- 
-- Once the filters have been defined and the SET_PLAYER has been built, you can iterate the SET_PLAYER with the available iterator methods.
-- The iterator methods will walk the SET_PLAYER set, and call for each element within the set a function that you provide.
-- The following iterator methods are currently available within the SET_PLAYER:
-- 
--   * @{#SET_PLAYER.ForEachClient}: Calls a function for each alive client it finds within the SET_PLAYER.
-- 
-- ===
-- @field #SET_PLAYER SET_PLAYER 
SET_PLAYER = {
  ClassName = "SET_PLAYER",
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


--- Creates a new SET_PLAYER object, building a set of clients belonging to a coalitions, categories, countries, types or with defined prefix names.
-- @param #SET_PLAYER self
-- @return #SET_PLAYER
-- @usage
-- -- Define a new SET_PLAYER Object. This DBObject will contain a reference to all Clients.
-- DBObject = SET_PLAYER:New()
function SET_PLAYER:New()
  -- Inherits from BASE
  local self = BASE:Inherit( self, SET_BASE:New( _DATABASE.PLAYERS ) )

  return self
end

--- Add CLIENT(s) to SET_PLAYER.
-- @param Core.Set#SET_PLAYER self
-- @param #string AddClientNames A single name or an array of CLIENT names.
-- @return self
function SET_PLAYER:AddClientsByName( AddClientNames )

  local AddClientNamesArray = ( type( AddClientNames ) == "table" ) and AddClientNames or { AddClientNames }
  
  for AddClientID, AddClientName in pairs( AddClientNamesArray ) do
    self:Add( AddClientName, CLIENT:FindByName( AddClientName ) )
  end
    
  return self
end

--- Remove CLIENT(s) from SET_PLAYER.
-- @param Core.Set#SET_PLAYER self
-- @param Wrapper.Client#CLIENT RemoveClientNames A single name or an array of CLIENT names.
-- @return self
function SET_PLAYER:RemoveClientsByName( RemoveClientNames )

  local RemoveClientNamesArray = ( type( RemoveClientNames ) == "table" ) and RemoveClientNames or { RemoveClientNames }
  
  for RemoveClientID, RemoveClientName in pairs( RemoveClientNamesArray ) do
    self:Remove( RemoveClientName.ClientName )
  end
    
  return self
end


--- Finds a Client based on the Player Name.
-- @param #SET_PLAYER self
-- @param #string PlayerName
-- @return Wrapper.Client#CLIENT The found Client.
function SET_PLAYER:FindClient( PlayerName )

  local ClientFound = self.Set[PlayerName]
  return ClientFound
end



--- Builds a set of clients of coalitions joined by specific players.
-- Possible current coalitions are red, blue and neutral.
-- @param #SET_PLAYER self
-- @param #string Coalitions Can take the following values: "red", "blue", "neutral".
-- @return #SET_PLAYER self
function SET_PLAYER:FilterCoalitions( Coalitions )
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


--- Builds a set of clients out of categories joined by players.
-- Possible current categories are plane, helicopter, ground, ship.
-- @param #SET_PLAYER self
-- @param #string Categories Can take the following values: "plane", "helicopter", "ground", "ship".
-- @return #SET_PLAYER self
function SET_PLAYER:FilterCategories( Categories )
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


--- Builds a set of clients of defined client types joined by players.
-- Possible current types are those types known within DCS world.
-- @param #SET_PLAYER self
-- @param #string Types Can take those type strings known within DCS world.
-- @return #SET_PLAYER self
function SET_PLAYER:FilterTypes( Types )
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
-- @param #SET_PLAYER self
-- @param #string Countries Can take those country strings known within DCS world.
-- @return #SET_PLAYER self
function SET_PLAYER:FilterCountries( Countries )
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
-- @param #SET_PLAYER self
-- @param #string Prefixes The prefix of which the client name starts with.
-- @return #SET_PLAYER self
function SET_PLAYER:FilterPrefixes( Prefixes )
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
-- @param #SET_PLAYER self
-- @return #SET_PLAYER self
function SET_PLAYER:FilterStart()

  if _DATABASE then
    self:_FilterStart()
    self:HandleEvent( EVENTS.Birth, self._EventOnBirth )
    self:HandleEvent( EVENTS.Dead, self._EventOnDeadOrCrash )
    self:HandleEvent( EVENTS.Crash, self._EventOnDeadOrCrash )
  end
  
  return self
end

--- Handles the Database to check on an event (birth) that the Object was added in the Database.
-- This is required, because sometimes the _DATABASE birth event gets called later than the SET_BASE birth event!
-- @param #SET_PLAYER self
-- @param Core.Event#EVENTDATA Event
-- @return #string The name of the CLIENT
-- @return #table The CLIENT
function SET_PLAYER:AddInDatabase( Event )
  self:F3( { Event } )

  return Event.IniDCSUnitName, self.Database[Event.IniDCSUnitName]
end

--- Handles the Database to check on any event that Object exists in the Database.
-- This is required, because sometimes the _DATABASE event gets called later than the SET_BASE event or vise versa!
-- @param #SET_PLAYER self
-- @param Core.Event#EVENTDATA Event
-- @return #string The name of the CLIENT
-- @return #table The CLIENT
function SET_PLAYER:FindInDatabase( Event )
  self:F3( { Event } )

  return Event.IniDCSUnitName, self.Database[Event.IniDCSUnitName]
end

--- Iterate the SET_PLAYER and call an interator function for each **alive** CLIENT, providing the CLIENT and optional parameters.
-- @param #SET_PLAYER self
-- @param #function IteratorFunction The function that will be called when there is an alive CLIENT in the SET_PLAYER. The function needs to accept a CLIENT parameter.
-- @return #SET_PLAYER self
function SET_PLAYER:ForEachPlayer( IteratorFunction, ... )
  self:F2( arg )
  
  self:ForEach( IteratorFunction, arg, self:GetSet() )

  return self
end

--- Iterate the SET_PLAYER and call an iterator function for each **alive** CLIENT presence completely in a @{Zone}, providing the CLIENT and optional parameters to the called function.
-- @param #SET_PLAYER self
-- @param Core.Zone#ZONE ZoneObject The Zone to be tested for.
-- @param #function IteratorFunction The function that will be called when there is an alive CLIENT in the SET_PLAYER. The function needs to accept a CLIENT parameter.
-- @return #SET_PLAYER self
function SET_PLAYER:ForEachPlayerInZone( ZoneObject, IteratorFunction, ... )
  self:F2( arg )
  
  self:ForEach( IteratorFunction, arg, self:GetSet(),
    --- @param Core.Zone#ZONE_BASE ZoneObject
    -- @param Wrapper.Client#CLIENT ClientObject
    function( ZoneObject, ClientObject )
      if ClientObject:IsInZone( ZoneObject ) then
        return true
      else
        return false
      end
    end, { ZoneObject } )

  return self
end

--- Iterate the SET_PLAYER and call an iterator function for each **alive** CLIENT presence not in a @{Zone}, providing the CLIENT and optional parameters to the called function.
-- @param #SET_PLAYER self
-- @param Core.Zone#ZONE ZoneObject The Zone to be tested for.
-- @param #function IteratorFunction The function that will be called when there is an alive CLIENT in the SET_PLAYER. The function needs to accept a CLIENT parameter.
-- @return #SET_PLAYER self
function SET_PLAYER:ForEachPlayerNotInZone( ZoneObject, IteratorFunction, ... )
  self:F2( arg )
  
  self:ForEach( IteratorFunction, arg, self:GetSet(),
    --- @param Core.Zone#ZONE_BASE ZoneObject
    -- @param Wrapper.Client#CLIENT ClientObject
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
-- @param #SET_PLAYER self
-- @param Wrapper.Client#CLIENT MClient
-- @return #SET_PLAYER self
function SET_PLAYER:IsIncludeObject( MClient )
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

--- @type SET_AIRBASE
-- @extends Core.Set#SET_BASE

--- Mission designers can use the @{Core.Set#SET_AIRBASE} class to build sets of airbases optionally belonging to certain:
-- 
--  * Coalitions
--  
-- ## SET_AIRBASE constructor
-- 
-- Create a new SET_AIRBASE object with the @{#SET_AIRBASE.New} method:
-- 
--    * @{#SET_AIRBASE.New}: Creates a new SET_AIRBASE object.
--   
-- ## Add or Remove AIRBASEs from SET_AIRBASE 
-- 
-- AIRBASEs can be added and removed using the @{Core.Set#SET_AIRBASE.AddAirbasesByName} and @{Core.Set#SET_AIRBASE.RemoveAirbasesByName} respectively. 
-- These methods take a single AIRBASE name or an array of AIRBASE names to be added or removed from SET_AIRBASE.
-- 
-- ## SET_AIRBASE filter criteria 
-- 
-- You can set filter criteria to define the set of clients within the SET_AIRBASE.
-- Filter criteria are defined by:
-- 
--    * @{#SET_AIRBASE.FilterCoalitions}: Builds the SET_AIRBASE with the airbases belonging to the coalition(s).
--   
-- Once the filter criteria have been set for the SET_AIRBASE, you can start filtering using:
-- 
--   * @{#SET_AIRBASE.FilterStart}: Starts the filtering of the airbases within the SET_AIRBASE.
-- 
-- ## SET_AIRBASE iterators
-- 
-- Once the filters have been defined and the SET_AIRBASE has been built, you can iterate the SET_AIRBASE with the available iterator methods.
-- The iterator methods will walk the SET_AIRBASE set, and call for each airbase within the set a function that you provide.
-- The following iterator methods are currently available within the SET_AIRBASE:
-- 
--   * @{#SET_AIRBASE.ForEachAirbase}: Calls a function for each airbase it finds within the SET_AIRBASE.
-- 
-- ===
-- @field #SET_AIRBASE SET_AIRBASE
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
-- @param Core.Set#SET_AIRBASE self
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
-- @param Core.Set#SET_AIRBASE self
-- @param Wrapper.Airbase#AIRBASE RemoveAirbaseNames A single name or an array of AIRBASE names.
-- @return self
function SET_AIRBASE:RemoveAirbasesByName( RemoveAirbaseNames )

  local RemoveAirbaseNamesArray = ( type( RemoveAirbaseNames ) == "table" ) and RemoveAirbaseNames or { RemoveAirbaseNames }
  
  for RemoveAirbaseID, RemoveAirbaseName in pairs( RemoveAirbaseNamesArray ) do
    self:Remove( RemoveAirbaseName )
  end
    
  return self
end


--- Finds a Airbase based on the Airbase Name.
-- @param #SET_AIRBASE self
-- @param #string AirbaseName
-- @return Wrapper.Airbase#AIRBASE The found Airbase.
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
  
    -- We use the BaseCaptured event, which is generated by DCS when a base got captured.
    self:HandleEvent( EVENTS.BaseCaptured )

    -- We initialize the first set.
    for ObjectName, Object in pairs( self.Database ) do
      if self:IsIncludeObject( Object ) then
        self:Add( ObjectName, Object )
      else
        self:RemoveAirbasesByName( ObjectName )
      end
    end
  end
  
  return self
end

--- Starts the filtering.
-- @param #SET_AIRBASE self
-- @param Core.Event#EVENT EventData
-- @return #SET_AIRBASE self
function SET_AIRBASE:OnEventBaseCaptured(EventData)

  -- When a base got captured, we reevaluate the set.
  for ObjectName, Object in pairs( self.Database ) do
    if self:IsIncludeObject( Object ) then
      -- We add captured bases on yet in the set.
      self:Add( ObjectName, Object )
    else
      -- We remove captured bases that are not anymore part of the set.
      self:RemoveAirbasesByName( ObjectName )
    end
  end

end

--- Handles the Database to check on an event (birth) that the Object was added in the Database.
-- This is required, because sometimes the _DATABASE birth event gets called later than the SET_BASE birth event!
-- @param #SET_AIRBASE self
-- @param Core.Event#EVENTDATA Event
-- @return #string The name of the AIRBASE
-- @return #table The AIRBASE
function SET_AIRBASE:AddInDatabase( Event )
  self:F3( { Event } )

  return Event.IniDCSUnitName, self.Database[Event.IniDCSUnitName]
end

--- Handles the Database to check on any event that Object exists in the Database.
-- This is required, because sometimes the _DATABASE event gets called later than the SET_BASE event or vise versa!
-- @param #SET_AIRBASE self
-- @param Core.Event#EVENTDATA Event
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
  
  self:ForEach( IteratorFunction, arg, self:GetSet() )

  return self
end

--- Iterate the SET_AIRBASE while identifying the nearest @{Wrapper.Airbase#AIRBASE} from a @{Core.Point#POINT_VEC2}.
-- @param #SET_AIRBASE self
-- @param Core.Point#POINT_VEC2 PointVec2 A @{Core.Point#POINT_VEC2} object from where to evaluate the closest @{Wrapper.Airbase#AIRBASE}.
-- @return Wrapper.Airbase#AIRBASE The closest @{Wrapper.Airbase#AIRBASE}.
function SET_AIRBASE:FindNearestAirbaseFromPointVec2( PointVec2 )
  self:F2( PointVec2 )
  
  local NearestAirbase = self:FindNearestObjectFromPointVec2( PointVec2 )
  return NearestAirbase
end



---
-- @param #SET_AIRBASE self
-- @param Wrapper.Airbase#AIRBASE MAirbase
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

--- @type SET_CARGO
-- @extends Core.Set#SET_BASE

--- Mission designers can use the @{Core.Set#SET_CARGO} class to build sets of cargos optionally belonging to certain:
-- 
--  * Coalitions
--  * Types
--  * Name or Prefix
--  
-- ## SET_CARGO constructor
-- 
-- Create a new SET_CARGO object with the @{#SET_CARGO.New} method:
-- 
--    * @{#SET_CARGO.New}: Creates a new SET_CARGO object.
--   
-- ## Add or Remove CARGOs from SET_CARGO 
-- 
-- CARGOs can be added and removed using the @{Core.Set#SET_CARGO.AddCargosByName} and @{Core.Set#SET_CARGO.RemoveCargosByName} respectively. 
-- These methods take a single CARGO name or an array of CARGO names to be added or removed from SET_CARGO.
-- 
-- ## SET_CARGO filter criteria 
-- 
-- You can set filter criteria to automatically maintain the SET_CARGO contents.
-- Filter criteria are defined by:
-- 
--    * @{#SET_CARGO.FilterCoalitions}: Builds the SET_CARGO with the cargos belonging to the coalition(s).
--    * @{#SET_CARGO.FilterPrefixes}: Builds the SET_CARGO with the cargos containing the prefix string(s).
--    * @{#SET_CARGO.FilterTypes}: Builds the SET_CARGO with the cargos belonging to the cargo type(s).
--    * @{#SET_CARGO.FilterCountries}: Builds the SET_CARGO with the cargos belonging to the country(ies).
--   
-- Once the filter criteria have been set for the SET_CARGO, you can start filtering using:
-- 
--   * @{#SET_CARGO.FilterStart}: Starts the filtering of the cargos within the SET_CARGO.
-- 
-- ## SET_CARGO iterators
-- 
-- Once the filters have been defined and the SET_CARGO has been built, you can iterate the SET_CARGO with the available iterator methods.
-- The iterator methods will walk the SET_CARGO set, and call for each cargo within the set a function that you provide.
-- The following iterator methods are currently available within the SET_CARGO:
-- 
--   * @{#SET_CARGO.ForEachCargo}: Calls a function for each cargo it finds within the SET_CARGO.
-- 
-- @field #SET_CARGO SET_CARGO
-- 
SET_CARGO = {
  ClassName = "SET_CARGO",
  Cargos = {},
  Filter = {
    Coalitions = nil,
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
  },
}


--- Creates a new SET_CARGO object, building a set of cargos belonging to a coalitions and categories.
-- @param #SET_CARGO self
-- @return #SET_CARGO
-- @usage
-- -- Define a new SET_CARGO Object. The DatabaseSet will contain a reference to all Cargos.
-- DatabaseSet = SET_CARGO:New()
function SET_CARGO:New() --R2.1
  -- Inherits from BASE
  local self = BASE:Inherit( self, SET_BASE:New( _DATABASE.CARGOS ) ) -- #SET_CARGO

  return self
end


--- (R2.1) Add CARGO to SET_CARGO.
-- @param Core.Set#SET_CARGO self
-- @param Cargo.Cargo#CARGO Cargo A single cargo.
-- @return self
function SET_CARGO:AddCargo( Cargo ) --R2.4

  self:Add( Cargo:GetName(), Cargo )
    
  return self
end


--- (R2.1) Add CARGOs to SET_CARGO.
-- @param Core.Set#SET_CARGO self
-- @param #string AddCargoNames A single name or an array of CARGO names.
-- @return self
function SET_CARGO:AddCargosByName( AddCargoNames ) --R2.1

  local AddCargoNamesArray = ( type( AddCargoNames ) == "table" ) and AddCargoNames or { AddCargoNames }
  
  for AddCargoID, AddCargoName in pairs( AddCargoNamesArray ) do
    self:Add( AddCargoName, CARGO:FindByName( AddCargoName ) )
  end
    
  return self
end

--- (R2.1) Remove CARGOs from SET_CARGO.
-- @param Core.Set#SET_CARGO self
-- @param Wrapper.Cargo#CARGO RemoveCargoNames A single name or an array of CARGO names.
-- @return self
function SET_CARGO:RemoveCargosByName( RemoveCargoNames ) --R2.1

  local RemoveCargoNamesArray = ( type( RemoveCargoNames ) == "table" ) and RemoveCargoNames or { RemoveCargoNames }
  
  for RemoveCargoID, RemoveCargoName in pairs( RemoveCargoNamesArray ) do
    self:Remove( RemoveCargoName.CargoName )
  end
    
  return self
end


--- (R2.1) Finds a Cargo based on the Cargo Name.
-- @param #SET_CARGO self
-- @param #string CargoName
-- @return Wrapper.Cargo#CARGO The found Cargo.
function SET_CARGO:FindCargo( CargoName ) --R2.1

  local CargoFound = self.Set[CargoName]
  return CargoFound
end



--- (R2.1) Builds a set of cargos of coalitions.
-- Possible current coalitions are red, blue and neutral.
-- @param #SET_CARGO self
-- @param #string Coalitions Can take the following values: "red", "blue", "neutral".
-- @return #SET_CARGO self
function SET_CARGO:FilterCoalitions( Coalitions ) --R2.1
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

--- (R2.1) Builds a set of cargos of defined cargo types.
-- Possible current types are those types known within DCS world.
-- @param #SET_CARGO self
-- @param #string Types Can take those type strings known within DCS world.
-- @return #SET_CARGO self
function SET_CARGO:FilterTypes( Types ) --R2.1
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


--- (R2.1) Builds a set of cargos of defined countries.
-- Possible current countries are those known within DCS world.
-- @param #SET_CARGO self
-- @param #string Countries Can take those country strings known within DCS world.
-- @return #SET_CARGO self
function SET_CARGO:FilterCountries( Countries ) --R2.1
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


--- (R2.1) Builds a set of cargos of defined cargo prefixes.
-- All the cargos starting with the given prefixes will be included within the set.
-- @param #SET_CARGO self
-- @param #string Prefixes The prefix of which the cargo name starts with.
-- @return #SET_CARGO self
function SET_CARGO:FilterPrefixes( Prefixes ) --R2.1
  if not self.Filter.CargoPrefixes then
    self.Filter.CargoPrefixes = {}
  end
  if type( Prefixes ) ~= "table" then
    Prefixes = { Prefixes }
  end
  for PrefixID, Prefix in pairs( Prefixes ) do
    self.Filter.CargoPrefixes[Prefix] = Prefix
  end
  return self
end



--- (R2.1) Starts the filtering.
-- @param #SET_CARGO self
-- @return #SET_CARGO self
function SET_CARGO:FilterStart() --R2.1

  if _DATABASE then
    self:_FilterStart()
    self:HandleEvent( EVENTS.NewCargo )
    self:HandleEvent( EVENTS.DeleteCargo )
  end
  
  return self
end


--- (R2.1) Handles the Database to check on an event (birth) that the Object was added in the Database.
-- This is required, because sometimes the _DATABASE birth event gets called later than the SET_BASE birth event!
-- @param #SET_CARGO self
-- @param Core.Event#EVENTDATA Event
-- @return #string The name of the CARGO
-- @return #table The CARGO
function SET_CARGO:AddInDatabase( Event ) --R2.1
  self:F3( { Event } )

  return Event.IniDCSUnitName, self.Database[Event.IniDCSUnitName]
end

--- (R2.1) Handles the Database to check on any event that Object exists in the Database.
-- This is required, because sometimes the _DATABASE event gets called later than the SET_BASE event or vise versa!
-- @param #SET_CARGO self
-- @param Core.Event#EVENTDATA Event
-- @return #string The name of the CARGO
-- @return #table The CARGO
function SET_CARGO:FindInDatabase( Event ) --R2.1
  self:F3( { Event } )

  return Event.IniDCSUnitName, self.Database[Event.IniDCSUnitName]
end

--- (R2.1) Iterate the SET_CARGO and call an interator function for each CARGO, providing the CARGO and optional parameters.
-- @param #SET_CARGO self
-- @param #function IteratorFunction The function that will be called when there is an alive CARGO in the SET_CARGO. The function needs to accept a CARGO parameter.
-- @return #SET_CARGO self
function SET_CARGO:ForEachCargo( IteratorFunction, ... ) --R2.1
  self:F2( arg )
  
  self:ForEach( IteratorFunction, arg, self:GetSet() )

  return self
end

--- (R2.1) Iterate the SET_CARGO while identifying the nearest @{Cargo.Cargo#CARGO} from a @{Core.Point#POINT_VEC2}.
-- @param #SET_CARGO self
-- @param Core.Point#POINT_VEC2 PointVec2 A @{Core.Point#POINT_VEC2} object from where to evaluate the closest @{Cargo.Cargo#CARGO}.
-- @return Wrapper.Cargo#CARGO The closest @{Cargo.Cargo#CARGO}.
function SET_CARGO:FindNearestCargoFromPointVec2( PointVec2 ) --R2.1
  self:F2( PointVec2 )
  
  local NearestCargo = self:FindNearestObjectFromPointVec2( PointVec2 )
  return NearestCargo
end

function SET_CARGO:FirstCargoWithState( State )
  
  local FirstCargo = nil
  
  for CargoName, Cargo in pairs( self.Set ) do
    if Cargo:Is( State ) then
      FirstCargo = Cargo
      break
    end
  end
  
  return FirstCargo
end

function SET_CARGO:FirstCargoWithStateAndNotDeployed( State )
  
  local FirstCargo = nil
  
  for CargoName, Cargo in pairs( self.Set ) do
    if Cargo:Is( State ) and not Cargo:IsDeployed() then
      FirstCargo = Cargo
      break
    end
  end
  
  return FirstCargo
end


--- Iterate the SET_CARGO while identifying the first @{Cargo.Cargo#CARGO} that is UnLoaded.
-- @param #SET_CARGO self
-- @return Cargo.Cargo#CARGO The first @{Cargo.Cargo#CARGO}.
function SET_CARGO:FirstCargoUnLoaded()
  local FirstCargo = self:FirstCargoWithState( "UnLoaded" )
  return FirstCargo
end


--- Iterate the SET_CARGO while identifying the first @{Cargo.Cargo#CARGO} that is UnLoaded and not Deployed.
-- @param #SET_CARGO self
-- @return Cargo.Cargo#CARGO The first @{Cargo.Cargo#CARGO}.
function SET_CARGO:FirstCargoUnLoadedAndNotDeployed()
  local FirstCargo = self:FirstCargoWithStateAndNotDeployed( "UnLoaded" )
  return FirstCargo
end


--- Iterate the SET_CARGO while identifying the first @{Cargo.Cargo#CARGO} that is Loaded.
-- @param #SET_CARGO self
-- @return Cargo.Cargo#CARGO The first @{Cargo.Cargo#CARGO}.
function SET_CARGO:FirstCargoLoaded()
  local FirstCargo = self:FirstCargoWithState( "Loaded" )
  return FirstCargo
end


--- Iterate the SET_CARGO while identifying the first @{Cargo.Cargo#CARGO} that is Deployed.
-- @param #SET_CARGO self
-- @return Cargo.Cargo#CARGO The first @{Cargo.Cargo#CARGO}.
function SET_CARGO:FirstCargoDeployed()
  local FirstCargo = self:FirstCargoWithState( "Deployed" )
  return FirstCargo
end




--- (R2.1) 
-- @param #SET_CARGO self
-- @param AI.AI_Cargo#AI_CARGO MCargo
-- @return #SET_CARGO self
function SET_CARGO:IsIncludeObject( MCargo ) --R2.1
  self:F2( MCargo )

  local MCargoInclude = true

  if MCargo then
    local MCargoName = MCargo:GetName()
  
    if self.Filter.Coalitions then
      local MCargoCoalition = false
      for CoalitionID, CoalitionName in pairs( self.Filter.Coalitions ) do
        local CargoCoalitionID = MCargo:GetCoalition()
        self:T3( { "Coalition:", CargoCoalitionID, self.FilterMeta.Coalitions[CoalitionName], CoalitionName } )
        if self.FilterMeta.Coalitions[CoalitionName] and self.FilterMeta.Coalitions[CoalitionName] == CargoCoalitionID then
          MCargoCoalition = true
        end
      end
      self:F( { "Evaluated Coalition", MCargoCoalition } )
      MCargoInclude = MCargoInclude and MCargoCoalition
    end

    if self.Filter.Types then
      local MCargoType = false
      for TypeID, TypeName in pairs( self.Filter.Types ) do
        self:T3( { "Type:", MCargo:GetType(), TypeName } )
        if TypeName == MCargo:GetType() then
          MCargoType = true
        end
      end
      self:F( { "Evaluated Type", MCargoType } )
      MCargoInclude = MCargoInclude and MCargoType
    end
    
    if self.Filter.CargoPrefixes then
      local MCargoPrefix = false
      for CargoPrefixId, CargoPrefix in pairs( self.Filter.CargoPrefixes ) do
        self:T3( { "Prefix:", string.find( MCargo.Name, CargoPrefix, 1 ), CargoPrefix } )
        if string.find( MCargo.Name, CargoPrefix, 1 ) then
          MCargoPrefix = true
        end
      end
      self:F( { "Evaluated Prefix", MCargoPrefix } )
      MCargoInclude = MCargoInclude and MCargoPrefix
    end
  end
    
  self:T2( MCargoInclude )
  return MCargoInclude
end

--- (R2.1) Handles the OnEventNewCargo event for the Set.
-- @param #SET_CARGO self
-- @param Core.Event#EVENTDATA EventData
function SET_CARGO:OnEventNewCargo( EventData ) --R2.1

  self:F( { "New Cargo", EventData } )

  if EventData.Cargo then
    if EventData.Cargo and self:IsIncludeObject( EventData.Cargo ) then
      self:Add( EventData.Cargo.Name , EventData.Cargo  )
    end
  end
end

--- (R2.1) Handles the OnDead or OnCrash event for alive units set.
-- @param #SET_CARGO self
-- @param Core.Event#EVENTDATA EventData
function SET_CARGO:OnEventDeleteCargo( EventData ) --R2.1
  self:F3( { EventData } )

  if EventData.Cargo then
    local Cargo = _DATABASE:FindCargo( EventData.Cargo.Name )
    if Cargo and Cargo.Name then

    -- When cargo was deleted, it may probably be because of an S_EVENT_DEAD.
    -- However, in the loading logic, an S_EVENT_DEAD is also generated after a Destroy() call.
    -- And this is a problem because it will remove all entries from the SET_CARGOs.
    -- To prevent this from happening, the Cargo object has a flag NoDestroy.
    -- When true, the SET_CARGO won't Remove the Cargo object from the set.
    -- This flag is switched off after the event handlers have been called in the EVENT class.
      self:F( { CargoNoDestroy=Cargo.NoDestroy } )
      if Cargo.NoDestroy then
      else
        self:Remove( Cargo.Name )
      end
    end
  end
end



--- @type SET_ZONE
-- @extends Core.Set#SET_BASE

--- Mission designers can use the @{Core.Set#SET_ZONE} class to build sets of zones of various types.
-- 
-- ## SET_ZONE constructor
-- 
-- Create a new SET_ZONE object with the @{#SET_ZONE.New} method:
-- 
--    * @{#SET_ZONE.New}: Creates a new SET_ZONE object.
--   
-- ## Add or Remove ZONEs from SET_ZONE 
-- 
-- ZONEs can be added and removed using the @{Core.Set#SET_ZONE.AddZonesByName} and @{Core.Set#SET_ZONE.RemoveZonesByName} respectively. 
-- These methods take a single ZONE name or an array of ZONE names to be added or removed from SET_ZONE.
-- 
-- ## SET_ZONE filter criteria 
-- 
-- You can set filter criteria to build the collection of zones in SET_ZONE.
-- Filter criteria are defined by:
-- 
--    * @{#SET_ZONE.FilterPrefixes}: Builds the SET_ZONE with the zones having a certain text pattern of prefix.
--   
-- Once the filter criteria have been set for the SET_ZONE, you can start filtering using:
-- 
--   * @{#SET_ZONE.FilterStart}: Starts the filtering of the zones within the SET_ZONE.
-- 
-- ## SET_ZONE iterators
-- 
-- Once the filters have been defined and the SET_ZONE has been built, you can iterate the SET_ZONE with the available iterator methods.
-- The iterator methods will walk the SET_ZONE set, and call for each airbase within the set a function that you provide.
-- The following iterator methods are currently available within the SET_ZONE:
-- 
--   * @{#SET_ZONE.ForEachZone}: Calls a function for each zone it finds within the SET_ZONE.
-- 
-- ===
-- @field #SET_ZONE SET_ZONE
SET_ZONE = {
  ClassName = "SET_ZONE",
  Zones = {},
  Filter = {
    Prefixes = nil,
  },
  FilterMeta = {
  },
}


--- Creates a new SET_ZONE object, building a set of zones.
-- @param #SET_ZONE self
-- @return #SET_ZONE self
-- @usage
-- -- Define a new SET_ZONE Object. The DatabaseSet will contain a reference to all Zones.
-- DatabaseSet = SET_ZONE:New()
function SET_ZONE:New()
  -- Inherits from BASE
  local self = BASE:Inherit( self, SET_BASE:New( _DATABASE.ZONES ) )

  return self
end

--- Add ZONEs to SET_ZONE.
-- @param Core.Set#SET_ZONE self
-- @param #string AddZoneNames A single name or an array of ZONE_BASE names.
-- @return self
function SET_ZONE:AddZonesByName( AddZoneNames )

  local AddZoneNamesArray = ( type( AddZoneNames ) == "table" ) and AddZoneNames or { AddZoneNames }
  
  for AddAirbaseID, AddZoneName in pairs( AddZoneNamesArray ) do
    self:Add( AddZoneName, ZONE:FindByName( AddZoneName ) )
  end
    
  return self
end

--- Remove ZONEs from SET_ZONE.
-- @param Core.Set#SET_ZONE self
-- @param Core.Zone#ZONE_BASE RemoveZoneNames A single name or an array of ZONE_BASE names.
-- @return self
function SET_ZONE:RemoveZonesByName( RemoveZoneNames )

  local RemoveZoneNamesArray = ( type( RemoveZoneNames ) == "table" ) and RemoveZoneNames or { RemoveZoneNames }
  
  for RemoveZoneID, RemoveZoneName in pairs( RemoveZoneNamesArray ) do
    self:Remove( RemoveZoneName )
  end
    
  return self
end


--- Finds a Zone based on the Zone Name.
-- @param #SET_ZONE self
-- @param #string ZoneName
-- @return Core.Zone#ZONE_BASE The found Zone.
function SET_ZONE:FindZone( ZoneName )

  local ZoneFound = self.Set[ZoneName]
  return ZoneFound
end


--- Get a random zone from the set.
-- @param #SET_ZONE self
-- @return Core.Zone#ZONE_BASE The random Zone.
-- @return #nil if no zone in the collection.
function SET_ZONE:GetRandomZone()

  if self:Count() ~= 0 then

    local Index = self.Index
    local ZoneFound = nil -- Core.Zone#ZONE_BASE

    -- Loop until a zone has been found.
    -- The :GetZoneMaybe() call will evaluate the probability for the zone to be selected.
    -- If the zone is not selected, then nil is returned by :GetZoneMaybe() and the loop continues!  
    while not ZoneFound do
      local ZoneRandom = math.random( 1, #Index )
      ZoneFound = self.Set[Index[ZoneRandom]]:GetZoneMaybe() 
    end
  
    return ZoneFound
  end
  
  return nil
end


--- Set a zone probability.
-- @param #SET_ZONE self
-- @param #string ZoneName The name of the zone.
function SET_ZONE:SetZoneProbability( ZoneName, ZoneProbability )
  local Zone = self:FindZone( ZoneName )
  Zone:SetZoneProbability( ZoneProbability )
end




--- Builds a set of zones of defined zone prefixes.
-- All the zones starting with the given prefixes will be included within the set.
-- @param #SET_ZONE self
-- @param #string Prefixes The prefix of which the zone name starts with.
-- @return #SET_ZONE self
function SET_ZONE:FilterPrefixes( Prefixes )
  if not self.Filter.Prefixes then
    self.Filter.Prefixes = {}
  end
  if type( Prefixes ) ~= "table" then
    Prefixes = { Prefixes }
  end
  for PrefixID, Prefix in pairs( Prefixes ) do
    self.Filter.Prefixes[Prefix] = Prefix
  end
  return self
end


--- Starts the filtering.
-- @param #SET_ZONE self
-- @return #SET_ZONE self
function SET_ZONE:FilterStart()

  if _DATABASE then
  
    -- We initialize the first set.
    for ObjectName, Object in pairs( self.Database ) do
      if self:IsIncludeObject( Object ) then
        self:Add( ObjectName, Object )
      else
        self:RemoveZonesByName( ObjectName )
      end
    end
  end

  self:HandleEvent( EVENTS.NewZone )
  self:HandleEvent( EVENTS.DeleteZone )
  
  return self
end

--- Handles the Database to check on an event (birth) that the Object was added in the Database.
-- This is required, because sometimes the _DATABASE birth event gets called later than the SET_BASE birth event!
-- @param #SET_ZONE self
-- @param Core.Event#EVENTDATA Event
-- @return #string The name of the AIRBASE
-- @return #table The AIRBASE
function SET_ZONE:AddInDatabase( Event )
  self:F3( { Event } )

  return Event.IniDCSUnitName, self.Database[Event.IniDCSUnitName]
end

--- Handles the Database to check on any event that Object exists in the Database.
-- This is required, because sometimes the _DATABASE event gets called later than the SET_BASE event or vise versa!
-- @param #SET_ZONE self
-- @param Core.Event#EVENTDATA Event
-- @return #string The name of the AIRBASE
-- @return #table The AIRBASE
function SET_ZONE:FindInDatabase( Event )
  self:F3( { Event } )

  return Event.IniDCSUnitName, self.Database[Event.IniDCSUnitName]
end

--- Iterate the SET_ZONE and call an interator function for each ZONE, providing the ZONE and optional parameters.
-- @param #SET_ZONE self
-- @param #function IteratorFunction The function that will be called when there is an alive ZONE in the SET_ZONE. The function needs to accept a AIRBASE parameter.
-- @return #SET_ZONE self
function SET_ZONE:ForEachZone( IteratorFunction, ... )
  self:F2( arg )
  
  self:ForEach( IteratorFunction, arg, self:GetSet() )

  return self
end


---
-- @param #SET_ZONE self
-- @param Core.Zone#ZONE_BASE MZone
-- @return #SET_ZONE self
function SET_ZONE:IsIncludeObject( MZone )
  self:F2( MZone )

  local MZoneInclude = true

  if MZone then
    local MZoneName = MZone:GetName()
  
    if self.Filter.Prefixes then
      local MZonePrefix = false
      for ZonePrefixId, ZonePrefix in pairs( self.Filter.Prefixes ) do
        self:T3( { "Prefix:", string.find( MZoneName, ZonePrefix, 1 ), ZonePrefix } )
        if string.find( MZoneName, ZonePrefix, 1 ) then
          MZonePrefix = true
        end
      end
      self:T( { "Evaluated Prefix", MZonePrefix } )
      MZoneInclude = MZoneInclude and MZonePrefix
    end
  end
   
  self:T2( MZoneInclude )
  return MZoneInclude
end

--- Handles the OnEventNewZone event for the Set.
-- @param #SET_ZONE self
-- @param Core.Event#EVENTDATA EventData
function SET_ZONE:OnEventNewZone( EventData ) --R2.1

  self:F( { "New Zone", EventData } )

  if EventData.Zone then
    if EventData.Zone and self:IsIncludeObject( EventData.Zone ) then
      self:Add( EventData.Zone.ZoneName , EventData.Zone  )
    end
  end
end

--- Handles the OnDead or OnCrash event for alive units set.
-- @param #SET_ZONE self
-- @param Core.Event#EVENTDATA EventData
function SET_ZONE:OnEventDeleteZone( EventData ) --R2.1
  self:F3( { EventData } )

  if EventData.Zone then
    local Zone = _DATABASE:FindZone( EventData.Zone.ZoneName )
    if Zone and Zone.ZoneName then

    -- When cargo was deleted, it may probably be because of an S_EVENT_DEAD.
    -- However, in the loading logic, an S_EVENT_DEAD is also generated after a Destroy() call.
    -- And this is a problem because it will remove all entries from the SET_ZONEs.
    -- To prevent this from happening, the Zone object has a flag NoDestroy.
    -- When true, the SET_ZONE won't Remove the Zone object from the set.
    -- This flag is switched off after the event handlers have been called in the EVENT class.
      self:F( { ZoneNoDestroy=Zone.NoDestroy } )
      if Zone.NoDestroy then
      else
        self:Remove( Zone.ZoneName )
      end
    end
  end
end
