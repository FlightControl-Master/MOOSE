--- **Core** - Define collections of objects to perform bulk actions and logically group objects.
--
-- ===
--
-- ## Features:
--
--   * Dynamically maintain collections of objects.
--   * Manually modify the collection, by adding or removing objects.
--   * Collections of different types.
--   * Validate the presence of objects in the collection.
--   * Perform bulk actions on collection.
--
-- ===
--
-- Group objects or data of the same type into a collection, which is either:
--
--   * Manually managed using the **:Add...()** or **:Remove...()** methods. The initial SET can be filtered with the **@{#SET_BASE.FilterOnce}()** method.
--   * Dynamically updated when new objects are created or objects are destroyed using the **@{#SET_BASE.FilterStart}()** method.
--
-- Various types of SET_ classes are available:
--
--   * @{#SET_GROUP}: Defines a collection of @{Wrapper.Group}s filtered by filter criteria.
--   * @{#SET_UNIT}: Defines a collection of @{Wrapper.Unit}s filtered by filter criteria.
--   * @{#SET_STATIC}: Defines a collection of @{Wrapper.Static}s filtered by filter criteria.
--   * @{#SET_CLIENT}: Defines a collection of @{Wrapper.Client}s filtered by filter criteria.
--   * @{#SET_AIRBASE}: Defines a collection of @{Wrapper.Airbase}s filtered by filter criteria.
--   * @{#SET_CARGO}: Defines a collection of @{Cargo.Cargo}s filtered by filter criteria.
--   * @{#SET_ZONE}: Defines a collection of @{Core.Zone}s filtered by filter criteria.
--   * @{#SET_SCENERY}: Defines a collection of @{Wrapper.Scenery}s added via a filtered @{#SET_ZONE}.
--   * @{#SET_DYNAMICCARGO}: Defines a collection of @{Wrapper.DynamicCargo}s filtered by filter criteria.
--
-- These classes are derived from @{#SET_BASE}, which contains the main methods to manage the collections.
--
-- A multitude of other methods are available in the individual set classes that allow to:
--
--   * Validate the presence of objects in the SET.
--   * Trigger events when objects in the SET change a zone presence.
--
-- ## Notes on `FilterPrefixes()`:  
-- 
-- This filter always looks for a **partial match** somewhere in the given field. LUA regular expression apply here, so special characters in names like minus, dot, hash (#) etc might lead to unexpected results. 
-- Have a read through the following to understand the application of regular expressions: [LUA regular expressions](https://riptutorial.com/lua/example/20315/lua-pattern-matching).  
-- For example, setting a filter like so `FilterPrefixes("Huey")` is perfectly all right, whilst `FilterPrefixes("UH-1H Al-Assad")` might not be due to the minus signs. A quick fix here is to use a dot (.) 
-- in place of the special character, or escape it with a percentage sign (%), i.e. either `FilterPrefixes("UH.1H Al.Assad")` or `FilterPrefixes("UH%-1H Al%-Assad")` will give you the expected results.
--
-- ===
--
-- ### Author: **FlightControl**
-- ### Contributions: **funkyfranky**, **applevangelist**
--
-- ===
--
-- @module Core.Set
-- @image Core_Sets.JPG

do -- SET_BASE
  
  ---
  -- @type SET_BASE
  -- @field #table Filter Table of filters.
  -- @field #table Set Table of objects.
  -- @field #table Index Table of indices.
  -- @field #table List Unused table.
  -- @field Core.Scheduler#SCHEDULER CallScheduler
  -- @field #SET_BASE.Filters Filter Filters
  -- @extends Core.Base#BASE

  --- The @{Core.Set#SET_BASE} class defines the core functions that define a collection of objects.
  -- A SET provides iterators to iterate the SET, but will **temporarily** yield the ForEach iterator loop at defined **"intervals"** to the mail simulator loop.
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
  -- Modify the iterator intervals with the @{Core.Set#SET_BASE.SetIteratorIntervals} method.
  -- You can set the **"yield interval"**, and the **"time interval"**. (See above).
  --
  -- @field #SET_BASE SET_BASE
  SET_BASE = {
    ClassName = "SET_BASE",
    Filter = {},
    Set = {},
    List = {},
    Index = {},
    Database = nil,
    CallScheduler = nil,
    
  }

  --- Filters
  -- @type SET_BASE.Filters
  -- @field #table Coalition Coalitions
  -- @field #table Prefix Prefixes.

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

    self:AddTransition( "*", "Added", "*" )

    --- Removed Handler OnAfter for SET_BASE
    -- @function [parent=#SET_BASE] OnAfterRemoved
    -- @param #SET_BASE self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @param #string ObjectName The name of the object.
    -- @param Object The object.

    self:AddTransition( "*", "Removed", "*" )

    self.YieldInterval = 10
    self.TimeInterval = 0.001

    self.Set = {}
    self.Index = {}

    self.CallScheduler = SCHEDULER:New( self )

    self:SetEventPriority( 2 )

    return self
  end
  
  --- [Internal] Add a functional filter
  -- @param #SET_BASE self
  -- @param #function ConditionFunction If this function returns `true`, the object is added to the SET. The function needs to take a CONTROLLABLE object as first argument.
  -- @param ... Condition function arguments, if any.
  -- @return #boolean If true, at least one condition is true
  function SET_BASE:FilterFunction(ConditionFunction, ...)
  
    local condition={}
    condition.func=ConditionFunction
    condition.arg={}
    
    if arg then
      condition.arg=arg
    end
    
    if not self.Filter.Functions then self.Filter.Functions = {} end
    table.insert(self.Filter.Functions, condition)
    
    return self
  end
    
  --- [Internal] Check if the condition functions returns true.
  -- @param #SET_BASE self
  -- @param Wrapper.Controllable#CONTROLLABLE Object The object to filter for
  -- @return #boolean If true, if **all** conditions are true
  function SET_BASE:_EvalFilterFunctions(Object) 
    -- All conditions must be true.
    for _,_condition in pairs(self.Filter.Functions or {}) do
      local condition=_condition
      -- Call function.
      if condition.func(Object,unpack(condition.arg)) == false then
        return false
      end
    end  
    -- No condition was false.
    return true
  end
  
  --- Clear the Objects in the Set.
  -- @param #SET_BASE self
  -- @param #boolean TriggerEvent If `true`, an event remove is triggered for each group that is removed from the set.
  -- @return #SET_BASE self
  function SET_BASE:Clear(TriggerEvent)

    for Name, Object in pairs( self.Set ) do
      self:Remove( Name, not TriggerEvent )
    end

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
    --self:F2()

    return self.Set or {}
  end

  --- Gets a list of the Names of the Objects in the Set.
  -- @param #SET_BASE self
  -- @return #table Table of names.
  function SET_BASE:GetSetNames() -- R2.3
    --self:F2()

    local Names = {}

    for Name, Object in pairs( self.Set ) do
      table.insert( Names, Name )
    end

    return Names
  end

  --- Returns a table of the Objects in the Set.
  -- @param #SET_BASE self
  -- @return #table Table of objects.
  function SET_BASE:GetSetObjects() -- R2.3
    --self:F2()

    local Objects = {}

    for Name, Object in pairs( self.Set ) do
      table.insert( Objects, Object )
    end

    return Objects
  end

  --- Removes a @{Core.Base#BASE} object from the @{Core.Set#SET_BASE} and derived classes, based on the Object Name.
  -- @param #SET_BASE self
  -- @param #string ObjectName
  -- @param #boolean NoTriggerEvent (Optional) When `true`, the :Remove() method will not trigger a **Removed** event.
  function SET_BASE:Remove( ObjectName, NoTriggerEvent )
    --self:F2( { ObjectName = ObjectName } )
    
    local TriggerEvent = true
    if NoTriggerEvent then 
      TriggerEvent = false
    else
      TriggerEvent = true
    end
    
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
      if TriggerEvent then
        self:Removed( ObjectName, Object )
      end
    end
  end

  --- Adds a @{Core.Base#BASE} object in the @{Core.Set#SET_BASE}, using a given ObjectName as the index.
  -- @param #SET_BASE self
  -- @param #string ObjectName The name of the object.
  -- @param Core.Base#BASE Object The object itself.
  -- @return Core.Base#BASE The added BASE Object.
  function SET_BASE:Add( ObjectName, Object )
  
    -- Debug info.
    --self:T2( { ObjectName = ObjectName, Object = Object } )

    -- Ensure that the existing element is removed from the Set before a new one is inserted to the Set
    if self.Set[ObjectName] then
      self:Remove( ObjectName, true )
    end

    -- Add object to set.
    self.Set[ObjectName] = Object

    -- Add Object name to Index.
    table.insert( self.Index, ObjectName )

    -- Trigger Added event.
    self:Added( ObjectName, Object )
    
    return self
  end

  --- Adds a @{Core.Base#BASE} object in the @{Core.Set#SET_BASE}, using the Object Name as the index.
  -- @param #SET_BASE self
  -- @param Wrapper.Object#OBJECT Object
  -- @return Core.Base#BASE The added BASE Object.
  function SET_BASE:AddObject( Object )
    --self:F2( Object.ObjectName )

    --self:T( Object.UnitName )
    --self:T( Object.ObjectName )
    self:Add( Object.ObjectName, Object )

  end

  --- Sort the set by name.
  -- @param #SET_BASE self
  -- @return Core.Base#BASE The added BASE Object.
  function SET_BASE:SortByName()
  
    local function sort(a, b)
      return a<b
    end
  
    table.sort(self.Index)
  
  end

  --- Add a SET to this set.
  -- @param #SET_BASE self
  -- @param Core.Set#SET_BASE SetToAdd Set to add.
  -- @return #SET_BASE self
  function SET_BASE:AddSet(SetToAdd)
    
    if not SetToAdd then return self end
    
    for _,ObjectB in pairs(SetToAdd.Set) do
      self:AddObject(ObjectB)
    end

    return self
  end


  --- Get the *union* of two sets.
  -- @param #SET_BASE self
  -- @param Core.Set#SET_BASE SetB Set *B*.
  -- @return Core.Set#SET_BASE The union set, i.e. contains objects that are in set *A* **or** in set *B*.
  function SET_BASE:GetSetUnion( SetB )

    local union = SET_BASE:New()

    for _, ObjectA in pairs( self.Set ) do
      union:AddObject( ObjectA )
    end

    for _, ObjectB in pairs( SetB.Set ) do
      union:AddObject( ObjectB )
    end

    return union
  end

  --- Get the *intersection* of this set, called *A*, and another set.
  -- @param #SET_BASE self
  -- @param Core.Set#SET_BASE SetB Set other set, called *B*.
  -- @return Core.Set#SET_BASE A set of objects that is included in set *A* **and** in set *B*.
  function SET_BASE:GetSetIntersection(SetB)

    local intersection=SET_BASE:New()

    local union=self:GetSetUnion(SetB)

    for _,Object in pairs(union.Set) do
      if self:IsIncludeObject(Object) and SetB:IsIncludeObject(Object) then
        intersection:AddObject(Object)
      end
    end

    return intersection
  end

  --- Get the *complement* of two sets.
  -- @param #SET_BASE self
  -- @param Core.Set#SET_BASE SetB Set other set, called *B*.
  -- @return Core.Set#SET_BASE The set of objects that are in set *B* but **not** in this set *A*.
  function SET_BASE:GetSetComplement( SetB )

    local complement = self:GetSetUnion(SetB)
    local intersection = self:GetSetIntersection(SetB)

    for _,Object in pairs(intersection.Set) do
        complement:Remove(Object.ObjectName,true)
    end

    return complement
  end

  --- Compare two sets.
  -- @param #SET_BASE self
  -- @param Core.Set#SET_BASE SetA First set.
  -- @param Core.Set#SET_BASE SetB Set to be merged into first set.
  -- @return Core.Set#SET_BASE The set of objects that are included in SetA and SetB.
  function SET_BASE:CompareSets( SetA, SetB )

    for _, ObjectB in pairs( SetB.Set ) do
      if SetA:IsIncludeObject( ObjectB ) then
        SetA:Add( ObjectB )
      end
    end

    return SetA
  end

  --- Gets a @{Core.Base#BASE} object from the @{Core.Set#SET_BASE} and derived classes, based on the Object Name.
  -- @param #SET_BASE self
  -- @param #string ObjectName
  -- @return Core.Base#BASE
  function SET_BASE:Get( ObjectName )
    --self:F( ObjectName )

    local Object = self.Set[ObjectName]

    --self:T3( { ObjectName, Object } )
    return Object
  end

  --- Gets the first object from the @{Core.Set#SET_BASE} and derived classes.
  -- @param #SET_BASE self
  -- @return Core.Base#BASE
  function SET_BASE:GetFirst()
    local ObjectName = self.Index[1]
    local FirstObject = self.Set[ObjectName]
    --self:T3( { FirstObject } )
    return FirstObject
  end

  --- Gets the last object from the @{Core.Set#SET_BASE} and derived classes.
  -- @param #SET_BASE self
  -- @return Core.Base#BASE
  function SET_BASE:GetLast()
    local tablemax = table.maxn(self.Index)
    local ObjectName = self.Index[tablemax]
    local LastObject = self.Set[ObjectName]
    --self:T3( { LastObject } )
    return LastObject
  end

  --- Gets a random object from the @{Core.Set#SET_BASE} and derived classes.
  -- @param #SET_BASE self
  -- @return Core.Base#BASE or nil if none found or the SET is empty!
  function SET_BASE:GetRandom()
    local tablemax = 0
    for _,_ind in pairs(self.Index) do
      tablemax = tablemax + 1
    end
    --local tablemax = table.maxn(self.Index)
    local RandomItem = self.Set[self.Index[math.random(1,tablemax)]]
    --self:T3( { RandomItem } )
    return RandomItem
  end
  
  --- Gets a random object from the @{Core.Set#SET_BASE} and derived classes. A bit slower than @{#SET_BASE.GetRandom}() but tries to ensure you get an object back if the SET is not empty. 
  -- @param #SET_BASE self
  -- @return Core.Base#BASE or nil if  the SET is empty!
  function SET_BASE:GetRandomSurely()
    local tablemax = 0
    local sorted = {}
    for _,_obj in pairs(self.Set) do
      tablemax = tablemax + 1
      sorted[tablemax] = _obj
    end
    --local tablemax = table.maxn(self.Index)
    --local RandomItem = self.Set[self.Index[math.random(1,tablemax)]]
    local RandomItem = sorted[math.random(1,tablemax)]
    --self:T3( { RandomItem } )
    return RandomItem
  end

  --- Retrieves the amount of objects in the @{Core.Set#SET_BASE} and derived classes.
  -- @param #SET_BASE self
  -- @return #number Count
  function SET_BASE:Count()
    return self.Index and table.maxn(self.Index) or 0
  end

  --- Copies the Filter criteria from a given Set (for rebuilding a new Set based on an existing Set).
  -- @param #SET_BASE self
  -- @param #SET_BASE BaseSet
  -- @return #SET_BASE
  function SET_BASE:SetDatabase( BaseSet )

    -- Copy the filter criteria of the BaseSet
    local OtherFilter = UTILS.DeepCopy( BaseSet.Filter )
    self.Filter = OtherFilter

    -- Now base the new Set on the BaseSet
    self.Database = BaseSet:GetSet()
    return self
  end

  --- Define the SET iterator **"limit"**.
  -- @param #SET_BASE self
  -- @param #number Limit Defines how many objects are evaluated of the set as part of the Some iterators. The default is 1.
  -- @return #SET_BASE self
  function SET_BASE:SetSomeIteratorLimit( Limit )

    self.SomeIteratorLimit = Limit or 1

    return self
  end

  --- Get the SET iterator **"limit"**.
  -- @param #SET_BASE self
  -- @return #number Defines how many objects are evaluated of the set as part of the Some iterators.
  function SET_BASE:GetSomeIteratorLimit()

    return self.SomeIteratorLimit or self:Count()
  end

  --- Filters for the defined collection.
  -- @param #SET_BASE self
  -- @return #SET_BASE self
  function SET_BASE:FilterOnce()
  
    --self:Clear()

    for ObjectName, Object in pairs( self.Database ) do

      if self:IsIncludeObject( Object ) then
        self:Add( ObjectName, Object )
      else
        self:Remove(ObjectName, true)
      end
    end

    return self
  end
  
  --- Clear all filters. You still need to apply :FilterOnce()
  -- @param #SET_BASE self
  -- @return #SET_BASE self
  function SET_BASE:FilterClear()
  
    for key,value in pairs(self.Filter) do
      self.Filter[key]={}
    end

    return self
  end  

  --- Starts the filtering for the defined collection.
  -- @param #SET_BASE self
  -- @return #SET_BASE self
  function SET_BASE:_FilterStart()

    for ObjectName, Object in pairs( self.Database ) do

      if self:IsIncludeObject( Object ) then
        self:Add( ObjectName, Object )
      end
    end

    -- Follow alive players and clients
    -- self:HandleEvent( EVENTS.PlayerEnterUnit, self._EventOnPlayerEnterUnit )
    -- self:HandleEvent( EVENTS.PlayerLeaveUnit, self._EventOnPlayerLeaveUnit )

    return self
  end

  --- Starts the filtering of the Dead events for the collection.
  -- @param #SET_BASE self
  -- @return #SET_BASE self
  function SET_BASE:FilterDeads() -- R2.1 allow deads to be filtered to automatically handle deads in the collection.

    self:HandleEvent( EVENTS.Dead, self._EventOnDeadOrCrash )

    return self
  end

  --- Starts the filtering of the Crash events for the collection.
  -- @param #SET_BASE self
  -- @return #SET_BASE self
  function SET_BASE:FilterCrashes() -- R2.1 allow crashes to be filtered to automatically handle crashes in the collection.

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

  --- Iterate the SET_BASE while identifying the nearest object in the set from a @{Core.Point#POINT_VEC2}.
  -- @param #SET_BASE self
  -- @param Core.Point#POINT_VEC2 PointVec2 A @{Core.Point#COORDINATE} or @{Core.Point#POINT_VEC2} object (but **not** a simple DCS#Vec2!) from where to evaluate the closest object in the set.
  -- @return Core.Base#BASE The closest object.
  -- @usage
  --          myset:FindNearestObjectFromPointVec2( ZONE:New("Test Zone"):GetCoordinate() )
  function SET_BASE:FindNearestObjectFromPointVec2( PointVec2 )
    --self:F2( PointVec2 )

    local NearestObject = nil
    local ClosestDistance = nil

    for ObjectID, ObjectData in pairs( self.Set ) do
      if NearestObject == nil then
        NearestObject = ObjectData
        ClosestDistance = PointVec2:DistanceFromPointVec2( ObjectData:GetCoordinate() )
      else
        local Distance = PointVec2:DistanceFromPointVec2( ObjectData:GetCoordinate() )
        if Distance < ClosestDistance then
          NearestObject = ObjectData
          ClosestDistance = Distance
        end
      end
    end

    return NearestObject
  end

  --- Events

  --- Handles the OnBirth event for the Set.
  -- @param #SET_BASE self
  -- @param Core.Event#EVENTDATA Event
  function SET_BASE:_EventOnBirth( Event )
    --self:F3( { Event } )

    if Event.IniDCSUnit then
      local ObjectName, Object = self:AddInDatabase( Event )
      --self:T3( ObjectName, Object )
      if Object and self:IsIncludeObject( Object ) then
        self:Add( ObjectName, Object )
        -- self:_EventOnPlayerEnterUnit( Event )
      end
    end
  end

  --- Handles the OnDead or OnCrash event for alive units set.
  -- @param #SET_BASE self
  -- @param Core.Event#EVENTDATA Event
  function SET_BASE:_EventOnDeadOrCrash( Event )
    --self:F( { Event } )

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
  -- function SET_BASE:_EventOnPlayerEnterUnit( Event )
  --  --self:F3( { Event } )
  --
  --  if Event.IniDCSUnit then
  --    local ObjectName, Object = self:AddInDatabase( Event )
  --    self:T3( ObjectName, Object )
  --    if self:IsIncludeObject( Object ) then
  --      self:Add( ObjectName, Object )
  --      --self:_EventOnPlayerEnterUnit( Event )
  --    end
  --  end
  -- end

  --- Handles the OnPlayerLeaveUnit event to clean the active players table.
  -- @param #SET_BASE self
  -- @param Core.Event#EVENTDATA Event
  -- function SET_BASE:_EventOnPlayerLeaveUnit( Event )
  --  --self:F3( { Event } )
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
  -- end

  -- Iterators

  --- Iterate the SET_BASE and derived classes and call an iterator function for the given SET_BASE, providing the Object for each element within the set and optional parameters.
  -- @param #SET_BASE self
  -- @param #function IteratorFunction The function that will be called.
  -- @param #table arg Arguments of the IteratorFunction.
  -- @param #SET_BASE Set (Optional) The set to use. Default self:GetSet().
  -- @param #function Function (Optional) A function returning a #boolean true/false. Only if true, the IteratorFunction is called.
  -- @param #table FunctionArguments (Optional) Function arguments.
  -- @return #SET_BASE self
  function SET_BASE:ForEach( IteratorFunction, arg, Set, Function, FunctionArguments )
    --self:F3( arg )

    Set = Set or self:GetSet()
    arg = arg or {}

    local function CoRoutine()
      local Count = 0
      for ObjectID, ObjectData in pairs( Set ) do
        local Object = ObjectData
        --self:T3( Object )
        if Function then
          if Function( unpack( FunctionArguments or {} ), Object ) == true then
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
      --self:T3( { status, res } )

      if status == false then
        error( res )
      end
      if res == false then
        return true -- resume next time the loop
      end

      return false
    end

    -- self.CallScheduler:Schedule( self, Schedule, {}, self.TimeInterval, self.TimeInterval, 0 )
    Schedule()

    return self
  end

  --- Iterate the SET_BASE and derived classes and call an iterator function for the given SET_BASE, providing the Object for each element within the set and optional parameters.
  -- @param #SET_BASE self
  -- @param #function IteratorFunction The function that will be called.
  -- @return #SET_BASE self
  function SET_BASE:ForSome( IteratorFunction, arg, Set, Function, FunctionArguments )
    --self:F3( arg )

    Set = Set or self:GetSet()
    arg = arg or {}

    local Limit = self:GetSomeIteratorLimit()

    local function CoRoutine()
      local Count = 0
      for ObjectID, ObjectData in pairs( Set ) do
        local Object = ObjectData
        --self:T3( Object )
        if Function then
          if Function( unpack( FunctionArguments ), Object ) == true then
            IteratorFunction( Object, unpack( arg ) )
          end
        else
          IteratorFunction( Object, unpack( arg ) )
        end
        Count = Count + 1
        if Count >= Limit then
          break
        end
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
      --self:T3( { status, res } )

      if status == false then
        error( res )
      end
      if res == false then
        return true -- resume next time the loop
      end

      return false
    end

    -- self.CallScheduler:Schedule( self, Schedule, {}, self.TimeInterval, self.TimeInterval, 0 )
    Schedule()

    return self
  end


  ----- Iterate the SET_BASE and call an iterator function for each **alive** unit, providing the Unit and optional parameters.
  -- @param #SET_BASE self
  -- @param #function IteratorFunction The function that will be called when there is an alive unit in the SET_BASE. The function needs to accept a UNIT parameter.
  ---- @return #SET_BASE self
  -- function SET_BASE:ForEachDCSUnitAlive( IteratorFunction, ... )
  --  --self:F3( arg )
  --
  --  self:ForEach( IteratorFunction, arg, self.DCSUnitsAlive )
  --
  --  return self
  -- end
  --
  ----- Iterate the SET_BASE and call an iterator function for each **alive** player, providing the Unit of the player and optional parameters.
  -- @param #SET_BASE self
  -- @param #function IteratorFunction The function that will be called when there is an alive player in the SET_BASE. The function needs to accept a UNIT parameter.
  ---- @return #SET_BASE self
  -- function SET_BASE:ForEachPlayer( IteratorFunction, ... )
  --  --self:F3( arg )
  --
  --  self:ForEach( IteratorFunction, arg, self.PlayersAlive )
  --
  --  return self
  -- end
  --
  --
  ----- Iterate the SET_BASE and call an iterator function for each client, providing the Client to the function and optional parameters.
  -- @param #SET_BASE self
  -- @param #function IteratorFunction The function that will be called when there is an alive player in the SET_BASE. The function needs to accept a CLIENT parameter.
  ---- @return #SET_BASE self
  -- function SET_BASE:ForEachClient( IteratorFunction, ... )
  --  --self:F3( arg )
  --
  --  self:ForEach( IteratorFunction, arg, self.Clients )
  --
  --  return self
  -- end

  --- Decides whether to include the Object.
  -- @param #SET_BASE self
  -- @param #table Object
  -- @return #SET_BASE self
  function SET_BASE:IsIncludeObject( Object )
    --self:F3( Object )

    return true
  end

  --- Decides whether an object is in the SET
  -- @param #SET_BASE self
  -- @param #table Object
  -- @return #boolean `true` if object is in set and `false` otherwise.
  function SET_BASE:IsInSet( Object )
    --self:F3( Object )
    local outcome = false
    local name = Object:GetName()
    --self:I("SET_BASE: Objectname = "..name)
    self:ForEach(
      function(object)
        --self:I("SET_BASE: In set objectname = "..object:GetName())
        if object:GetName() == name then
          outcome = true
        end
      end
    )
    return outcome
  end
  
  --- Decides whether an object is **not** in the SET
  -- @param #SET_BASE self
  -- @param #table Object
  -- @return #SET_BASE self
  function SET_BASE:IsNotInSet( Object )
    --self:F3( Object )
    return not self:IsInSet(Object)
  end

  --- Gets a string with all the object names.
  -- @param #SET_BASE self
  -- @return #string A string with the names of the objects.
  function SET_BASE:GetObjectNames()
    --self:F3()

    local ObjectNames = ""
    for ObjectName, Object in pairs( self.Set ) do
      ObjectNames = ObjectNames .. ObjectName .. ", "
    end

    return ObjectNames
  end

  --- Flushes the current SET_BASE contents in the log ... (for debugging reasons).
  -- @param #SET_BASE self
  -- @param Core.Base#BASE MasterObject (Optional) The master object as a reference.
  -- @return #string A string with the names of the objects.
  function SET_BASE:Flush( MasterObject )
    --self:F3()

    local ObjectNames = ""
    for ObjectName, Object in pairs( self.Set ) do
      ObjectNames = ObjectNames .. ObjectName .. ", "
    end
    --self:F( { MasterObject = MasterObject and MasterObject:GetClassNameAndID(), "Objects in Set:", ObjectNames } )

    return ObjectNames
  end

end

do 

  -- SET_GROUP
  
  ---
  -- @type SET_GROUP #SET_GROUP
  -- @field Core.Timer#TIMER ZoneTimer
  -- @field #number ZoneTimerInterval
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
  --    * @{#SET_GROUP.FilterCountries}: Builds the SET_GROUP with the groups belonging to the country(ies).
  --    * @{#SET_GROUP.FilterPrefixes}: Builds the SET_GROUP with the groups *containing* the given string in the group name. **Attention!** LUA regular expression apply here, so special characters in names like minus, dot, hash (#) etc might lead to unexpected results. 
  -- Have a read through here to understand the application of regular expressions: [LUA regular expressions](https://riptutorial.com/lua/example/20315/lua-pattern-matching)
  --    * @{#SET_GROUP.FilterActive}: Builds the SET_GROUP with the groups that are only active. Groups that are inactive (late activation) won't be included in the set!
  --
  -- For the Category Filter, extra methods have been added:
  --
  --    * @{#SET_GROUP.FilterCategoryAirplane}: Builds the SET_GROUP from airplanes.
  --    * @{#SET_GROUP.FilterCategoryHelicopter}: Builds the SET_GROUP from helicopters.
  --    * @{#SET_GROUP.FilterCategoryGround}: Builds the SET_GROUP from ground vehicles or infantry.
  --    * @{#SET_GROUP.FilterCategoryShip}: Builds the SET_GROUP from ships.
  --    * @{#SET_GROUP.FilterCategoryStructure}: Builds the SET_GROUP from structures.
  --    * @{#SET_GROUP.FilterZones}: Builds the SET_GROUP with the groups within a @{Core.Zone#ZONE}.
  --    * @{#SET_GROUP.FilterFunction}: Builds the SET_GROUP with a custom condition.
  --
  -- Once the filter criteria have been set for the SET_GROUP, you can start filtering using:
  --
  --    * @{#SET_GROUP.FilterStart}: Starts the filtering of the groups within the SET_GROUP and add or remove GROUP objects **dynamically**.
  --    * @{#SET_GROUP.FilterOnce}: Filters of the groups **once**.
  --
  -- ## SET_GROUP iterators
  --
  -- Once the filters have been defined and the SET_GROUP has been built, you can iterate the SET_GROUP with the available iterator methods.
  -- The iterator methods will walk the SET_GROUP set, and call for each element within the set a function that you provide.
  -- The following iterator methods are currently available within the SET_GROUP:
  --
  --   * @{#SET_GROUP.ForEachGroup}: Calls a function for each alive group it finds within the SET_GROUP.
  --   * @{#SET_GROUP.ForEachGroupCompletelyInZone}: Iterate the SET_GROUP and call an iterator function for each **alive** GROUP presence completely in a @{Core.Zone}, providing the GROUP and optional parameters to the called function.
  --   * @{#SET_GROUP.ForEachGroupPartlyInZone}: Iterate the SET_GROUP and call an iterator function for each **alive** GROUP presence partly in a @{Core.Zone}, providing the GROUP and optional parameters to the called function.
  --   * @{#SET_GROUP.ForEachGroupNotInZone}: Iterate the SET_GROUP and call an iterator function for each **alive** GROUP presence not in a @{Core.Zone}, providing the GROUP and optional parameters to the called function.
  --
  --
  -- ## SET_GROUP trigger events on the GROUP objects.
  --
  -- The SET is derived from the FSM class, which provides extra capabilities to track the contents of the GROUP objects in the SET_GROUP.
  --
  -- ### When a GROUP object crashes or is dead, the SET_GROUP will trigger a **Dead** event.
  --
  -- You can handle the event using the OnBefore and OnAfter event handlers.
  -- The event handlers need to have the parameters From, Event, To, GroupObject.
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
  --          --self:F( { GroupObject = GroupObject:GetName() } )
  --        end
  --
  -- While this is a good example, there is a catch.
  -- Imagine you want to execute the code above, the the self would need to be from the object declared outside (above) the OnAfterDead method.
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
      Zones = nil,
      Functions = nil,
      Alive = nil,
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
    local self = BASE:Inherit( self, SET_BASE:New( _DATABASE.GROUPS ) ) -- #SET_GROUP

    self:FilterActive( false )

    return self
       
    --- Filter the set once
    -- @function [parent=#SET_GROUP] FilterOnce
    -- @param #SET_GROUP self
    -- @return #SET_GROUP self
    
    
  end
  
  --- Get a *new* set that only contains alive groups.
  -- @param #SET_GROUP self
  -- @return #SET_GROUP Set of alive groups.
  function SET_GROUP:GetAliveSet()
    --self:F2()

    local AliveSet = SET_GROUP:New()

    -- Clean the Set before returning with only the alive Groups.
    for GroupName, GroupObject in pairs( self.Set ) do
      local GroupObject = GroupObject -- Wrapper.Group#GROUP
      if GroupObject then
        if GroupObject:IsAlive() then
          AliveSet:Add( GroupName, GroupObject )
        end
      end
    end

    return AliveSet.Set or {}
  end

  --- Returns a report of of unit types.
  -- @param #SET_GROUP self
  -- @return Core.Report#REPORT A report of the unit types found. The key is the UnitTypeName and the value is the amount of unit types found.
  function SET_GROUP:GetUnitTypeNames()
    --self:F2()

    local MT = {} -- Message Text
    local UnitTypes = {}

    local ReportUnitTypes = REPORT:New()

    for GroupID, GroupData in pairs( self:GetSet() ) do
      local Units = GroupData:GetUnits()
      for UnitID, UnitData in pairs( Units ) do
        if UnitData:IsAlive() then
          local UnitType = UnitData:GetTypeName()

          if not UnitTypes[UnitType] then
            UnitTypes[UnitType] = 1
          else
            UnitTypes[UnitType] = UnitTypes[UnitType] + 1
          end
        end
      end
    end

    for UnitTypeID, UnitType in pairs( UnitTypes ) do
      ReportUnitTypes:Add( UnitType .. " of " .. UnitTypeID )
    end

    return ReportUnitTypes
  end

  --- Add a GROUP to SET_GROUP.
  -- Note that for each unit in the group that is set, a default cargo bay limit is initialized.
  -- @param Core.Set#SET_GROUP self
  -- @param Wrapper.Group#GROUP group The group which should be added to the set.
  -- @param #boolean DontSetCargoBayLimit If true, do not attempt to auto-add the cargo bay limit per unit in this group.
  -- @return Core.Set#SET_GROUP self
  function SET_GROUP:AddGroup( group, DontSetCargoBayLimit )

    self:Add( group:GetName(), group )
    
    if not DontSetCargoBayLimit then
      -- I set the default cargo bay weight limit each time a new group is added to the set.
      -- TODO Why is this here in the first place?
      for UnitID, UnitData in pairs( group:GetUnits() or {} ) do
        if UnitData and UnitData:IsAlive() then
          UnitData:SetCargoBayWeightLimit()
        end
      end
    end
    
    return self
  end

  --- Add GROUP(s) to SET_GROUP.
  -- @param Core.Set#SET_GROUP self
  -- @param #string AddGroupNames A single name or an array of GROUP names.
  -- @return Core.Set#SET_GROUP self
  function SET_GROUP:AddGroupsByName( AddGroupNames )

    local AddGroupNamesArray = (type( AddGroupNames ) == "table") and AddGroupNames or { AddGroupNames }

    for AddGroupID, AddGroupName in pairs( AddGroupNamesArray ) do
      self:Add( AddGroupName, GROUP:FindByName( AddGroupName ) )
    end

    return self
  end

  --- Remove GROUP(s) from SET_GROUP.
  -- @param Core.Set#SET_GROUP self
  -- @param Wrapper.Group#GROUP RemoveGroupNames A single name or an array of GROUP names.
  -- @return Core.Set#SET_GROUP self
  function SET_GROUP:RemoveGroupsByName( RemoveGroupNames )

    local RemoveGroupNamesArray = (type( RemoveGroupNames ) == "table") and RemoveGroupNames or { RemoveGroupNames }

    for RemoveGroupID, RemoveGroupName in pairs( RemoveGroupNamesArray ) do
      self:Remove( RemoveGroupName )
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
    --self:F2( PointVec2 )

    local NearestGroup = nil -- Wrapper.Group#GROUP
    local ClosestDistance = nil
    
    local Set = self:GetAliveSet()
    
    for ObjectID, ObjectData in pairs( Set ) do
      if NearestGroup == nil then
        NearestGroup = ObjectData
        ClosestDistance = PointVec2:DistanceFromPointVec2( ObjectData:GetCoordinate() )
      else
        local Distance = PointVec2:DistanceFromPointVec2( ObjectData:GetCoordinate() )
        if Distance < ClosestDistance then
          NearestGroup = ObjectData
          ClosestDistance = Distance
        end
      end
    end

    return NearestGroup
  end

  --- Builds a set of groups in zones.
  -- @param #SET_GROUP self
  -- @param #table Zones Table of Core.Zone#ZONE Zone objects, or a Core.Set#SET_ZONE
  -- @param #boolean Clear If `true`, clear any previously defined filters.
  -- @return #SET_GROUP self
  function SET_GROUP:FilterZones( Zones, Clear )
  
    if Clear or not self.Filter.Zones then
      self.Filter.Zones = {}
    end
    
    local zones = {}
    if Zones.ClassName and Zones.ClassName == "SET_ZONE" then
      zones = Zones.Set
    elseif type( Zones ) ~= "table" or (type( Zones ) == "table" and Zones.ClassName) then
      self:E( "***** FilterZones needs either a table of ZONE Objects or a SET_ZONE as parameter!" )
      return self
    else
      zones = Zones
    end
    
    for _, Zone in pairs( zones ) do
      local zonename = Zone:GetName()
      self.Filter.Zones[zonename] = Zone
    end
    
    return self
  end
  
  --- [User] Add a custom condition function.
  -- @function [parent=#SET_GROUP] FilterFunction
  -- @param #SET_GROUP self
  -- @param #function ConditionFunction If this function returns `true`, the object is added to the SET. The function needs to take a GROUP object as first argument.
  -- @param ... Condition function arguments if any.
  -- @return #SET_GROUP self
  -- @usage
  --          -- Image you want to exclude a specific GROUP from a SET:
  --          local groundset = SET_GROUP:New():FilterCoalitions("blue"):FilterCategoryGround():FilterFunction(
  --          -- The function needs to take a GROUP object as first - and in this case, only - argument.
  --          function(grp)
  --              local isinclude = true
  --              if grp:GetName() == "Exclude Me" then isinclude = false end
  --              return isinclude
  --          end
  --          ):FilterOnce()
  --          BASE:I(groundset:Flush())

  
  --- Builds a set of groups of coalitions.
  -- Possible current coalitions are red, blue and neutral.
  -- @param #SET_GROUP self
  -- @param #string Coalitions Can take the following values: "red", "blue", "neutral".
  -- @param #boolean Clear If `true`, clear any previously defined filters.
  -- @return #SET_GROUP self
  function SET_GROUP:FilterCoalitions( Coalitions, Clear )
  
    if Clear or (not self.Filter.Coalitions) then
      self.Filter.Coalitions = {}
    end
    
    -- Ensure table.
    Coalitions = UTILS.EnsureTable(Coalitions, false)
    
    for CoalitionID, Coalition in pairs( Coalitions ) do
      self.Filter.Coalitions[Coalition] = Coalition
    end
    
    return self
  end

  --- Builds a set of groups out of categories.
  -- Possible current categories are plane, helicopter, ground, ship.
  -- @param #SET_GROUP self
  -- @param #string Categories Can take the following values: "plane", "helicopter", "ground", "ship".
  -- @param #boolean Clear If `true`, clear any previously defined filters.
  -- @return #SET_GROUP self
  function SET_GROUP:FilterCategories( Categories, Clear )
  
    if Clear or not self.Filter.Categories then
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

  --- Builds a set of groups that contain the given string in their group name.
  -- **Attention!** Bad naming convention as this **does not** filter only **prefixes** but all groups that **contain** the string.
  -- @param #SET_GROUP self
  -- @param #string Prefixes The string pattern(s) that needs to be contained in the group name. Can also be passed as a `#table` of strings.
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
  
  --- [Internal] Private function for use of continous zone filter
  -- @param #SET_GROUP self
  -- @return #SET_GROUP self
  function SET_GROUP:_ContinousZoneFilter()
    
    local Database = _DATABASE.GROUPS
    
    for ObjectName, Object in pairs( Database ) do
      if self:IsIncludeObject( Object ) and self:IsNotInSet(Object) then
        self:Add( ObjectName, Object )
      elseif (not self:IsIncludeObject( Object )) and self:IsInSet(Object) then
        self:Remove(ObjectName)
      end
    end
    
    return self
    
  end

  --- Builds a set of groups that are active, ie in the mission but not yet activated (false) or actived (true).
  -- Only the groups that are active will be included within the set.
  -- @param #SET_GROUP self
  -- @param #boolean Active (Optional) Include only active groups to the set.
  -- Include inactive groups if you provide false.
  -- @return #SET_GROUP self
  -- @usage
  --
  -- -- Include only active groups to the set.
  -- GroupSet = SET_GROUP:New():FilterActive():FilterStart()
  --
  -- -- Include only active groups to the set of the blue coalition, and filter one time.
  -- GroupSet = SET_GROUP:New():FilterActive():FilterCoalition( "blue" ):FilterOnce()
  --
  -- -- Include only active groups to the set of the blue coalition, and filter one time.
  -- -- Later, reset to include back inactive groups to the set.
  -- GroupSet = SET_GROUP:New():FilterActive():FilterCoalition( "blue" ):FilterOnce()
  -- ... logic ...
  -- GroupSet = SET_GROUP:New():FilterActive( false ):FilterCoalition( "blue" ):FilterOnce()
  --
  function SET_GROUP:FilterActive( Active )
    Active = Active or not (Active == false)
    self.Filter.Active = Active
    return self
  end
  
  --- Build a set of groups that are alive.
  -- @param #SET_GROUP self
  -- @return #SET_GROUP self
  function SET_GROUP:FilterAlive()
    self.Filter.Alive = true
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
      self:HandleEvent( EVENTS.RemoveUnit, self._EventOnDeadOrCrash )
      self:HandleEvent( EVENTS.UnitLost, self._EventOnDeadOrCrash )
      self:HandleEvent( EVENTS.PlayerLeaveUnit, self._EventOnDeadOrCrash )
      if self.Filter.Zones then
        self.ZoneTimer = TIMER:New(self._ContinousZoneFilter,self)
        local timing = self.ZoneTimerInterval or 30
        self.ZoneTimer:Start(timing,timing)
      end
    end

    return self
  end
  
  --- Set filter timer interval for FilterZones if using active filtering with FilterStart().
  -- @param #SET_GROUP self
  -- @param #number Seconds Seconds between check intervals, defaults to 30. **Caution** - do not be too agressive with timing! Groups are usually not moving fast enough
  -- to warrant a check of below 10 seconds.
  -- @return #SET_GROUP self
  function SET_GROUP:FilterZoneTimer(Seconds)
    self.ZoneTimerInterval = Seconds or 30
    return self
  end
  
  --- Stops the filtering.
  -- @param #SET_GROUP self
  -- @return #SET_GROUP self
  function SET_GROUP:FilterStop()

    if _DATABASE then
      
      self:UnHandleEvent(EVENTS.Birth)
      self:UnHandleEvent(EVENTS.Dead)
      self:UnHandleEvent(EVENTS.Crash)
      self:UnHandleEvent(EVENTS.RemoveUnit)
      self:UnHandleEvent(EVENTS.UnitLost)
      
      if self.Filter.Zones and self.ZoneTimer and self.ZoneTimer:IsRunning() then
        self.ZoneTimer:Stop()
      end
    end

    return self
  end


  --- Handles the OnDead or OnCrash event for alive groups set.
  -- Note: The GROUP object in the SET_GROUP collection will only be removed if the last unit is destroyed of the GROUP.
  -- @param #SET_GROUP self
  -- @param Core.Event#EVENTDATA Event
  function SET_GROUP:_EventOnDeadOrCrash( Event )
    --self:F( { Event } )

    if Event.IniDCSUnit then
      local ObjectName, Object = self:FindInDatabase( Event )
      if ObjectName then
        local size = 1
        if Event.IniDCSGroup then
         size = Event.IniDCSGroup:getSize()
        end
        if size == 1 then -- Only remove if the last unit of the group was destroyed.
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
    --self:F3( { Event } )

    if Event.IniObjectCategory == Object.Category.UNIT then
      if not self.Database[Event.IniDCSGroupName] then
        self.Database[Event.IniDCSGroupName] = GROUP:Register( Event.IniDCSGroupName )
        --self:T(3( self.Database[Event.IniDCSGroupName] )
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
    --self:F3( { Event } )

    return Event.IniDCSGroupName, self.Database[Event.IniDCSGroupName]
  end

  --- Iterate the SET_GROUP and call an iterator function for each GROUP object, providing the GROUP and optional parameters.
  -- @param #SET_GROUP self
  -- @param #function IteratorFunction The function that will be called for all GROUP in the SET_GROUP. The function needs to accept a GROUP parameter.
  -- @return #SET_GROUP self
  function SET_GROUP:ForEachGroup( IteratorFunction, ... )
    --self:F2( arg )

    self:ForEach( IteratorFunction, arg, self:GetSet() )

    return self
  end

  --- Iterate the SET_GROUP and call an iterator function for some GROUP objects, providing the GROUP and optional parameters.
  -- @param #SET_GROUP self
  -- @param #function IteratorFunction The function that will be called for some GROUP in the SET_GROUP. The function needs to accept a GROUP parameter.
  -- @return #SET_GROUP self
  function SET_GROUP:ForSomeGroup( IteratorFunction, ... )
    --self:F2( arg )

    self:ForSome( IteratorFunction, arg, self:GetSet() )

    return self
  end

  --- Iterate the SET_GROUP and call an iterator function for each **alive** GROUP object, providing the GROUP and optional parameters.
  -- @param #SET_GROUP self
  -- @param #function IteratorFunction The function that will be called when there is an alive GROUP in the SET_GROUP. The function needs to accept a GROUP parameter.
  -- @return #SET_GROUP self
  function SET_GROUP:ForEachGroupAlive( IteratorFunction, ... )
    --self:F2( arg )

    self:ForEach( IteratorFunction, arg, self:GetAliveSet() )

    return self
  end

  --- Iterate the SET_GROUP and call an iterator function for some **alive** GROUP objects, providing the GROUP and optional parameters.
  -- @param #SET_GROUP self
  -- @param #function IteratorFunction The function that will be called when there is an alive GROUP in the SET_GROUP. The function needs to accept a GROUP parameter.
  -- @return #SET_GROUP self
  function SET_GROUP:ForSomeGroupAlive( IteratorFunction, ... )
    --self:F2( arg )

    self:ForSome( IteratorFunction, arg, self:GetAliveSet() )

    return self
  end

  --- Activate late activated groups.
  -- @param #SET_GROUP self
  -- @param #number Delay Delay in seconds.
  -- @return #SET_GROUP self
  function SET_GROUP:Activate(Delay)
    local Set = self:GetSet()
    for GroupID, GroupData in pairs(Set) do -- For each GROUP in SET_GROUP
      local group=GroupData --Wrapper.Group#GROUP
      if group and group:IsAlive()==false then
        group:Activate(Delay)
      end
    end
    return self
  end


  --- Iterate the SET_GROUP and call an iterator function for each **alive** GROUP presence completely in a @{Core.Zone}, providing the GROUP and optional parameters to the called function.
  -- @param #SET_GROUP self
  -- @param Core.Zone#ZONE ZoneObject The Zone to be tested for.
  -- @param #function IteratorFunction The function that will be called when there is an alive GROUP in the SET_GROUP. The function needs to accept a GROUP parameter.
  -- @return #SET_GROUP self
  function SET_GROUP:ForEachGroupCompletelyInZone( ZoneObject, IteratorFunction, ... )
    --self:F2( arg )

    self:ForEach( IteratorFunction, arg, self:GetSet(),
      -- @param Core.Zone#ZONE_BASE ZoneObject
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

  --- Iterate the SET_GROUP and call an iterator function for each **alive** GROUP presence partly in a @{Core.Zone}, providing the GROUP and optional parameters to the called function.
  -- @param #SET_GROUP self
  -- @param Core.Zone#ZONE ZoneObject The Zone to be tested for.
  -- @param #function IteratorFunction The function that will be called when there is an alive GROUP in the SET_GROUP. The function needs to accept a GROUP parameter.
  -- @return #SET_GROUP self
  function SET_GROUP:ForEachGroupPartlyInZone( ZoneObject, IteratorFunction, ... )
    --self:F2( arg )

    self:ForEach( IteratorFunction, arg, self:GetSet(),
      -- @param Core.Zone#ZONE_BASE ZoneObject
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

  --- Iterate the SET_GROUP and call an iterator function for each **alive** GROUP presence not in a @{Core.Zone}, providing the GROUP and optional parameters to the called function.
  -- @param #SET_GROUP self
  -- @param Core.Zone#ZONE ZoneObject The Zone to be tested for.
  -- @param #function IteratorFunction The function that will be called when there is an alive GROUP in the SET_GROUP. The function needs to accept a GROUP parameter.
  -- @return #SET_GROUP self
  function SET_GROUP:ForEachGroupNotInZone( ZoneObject, IteratorFunction, ... )
    --self:F2( arg )

    self:ForEach( IteratorFunction, arg, self:GetSet(),
      -- @param Core.Zone#ZONE_BASE ZoneObject
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
  -- @param Core.Zone#ZONE Zone The Zone to be tested for.
  -- @return #boolean true if all the @{Wrapper.Group#GROUP} are completely in the @{Core.Zone#ZONE}, false otherwise
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
  function SET_GROUP:AllCompletelyInZone( Zone )
    --self:F2( Zone )
    local Set = self:GetSet()
    for GroupID, GroupData in pairs( Set ) do -- For each GROUP in SET_GROUP
      if not GroupData:IsCompletelyInZone( Zone ) then
        return false
      end
    end
    return true
  end

  --- Iterate the SET_GROUP and call an iterator function for each alive GROUP that has any unit in the @{Core.Zone}, providing the GROUP and optional parameters to the called function.
  -- @param #SET_GROUP self
  -- @param Core.Zone#ZONE ZoneObject The Zone to be tested for.
  -- @param #function IteratorFunction The function that will be called when there is an alive GROUP in the SET_GROUP. The function needs to accept a GROUP parameter.
  -- @return #SET_GROUP self
  function SET_GROUP:ForEachGroupAnyInZone( ZoneObject, IteratorFunction, ... )
    --self:F2( arg )

    self:ForEach( IteratorFunction, arg, self:GetSet(),
      -- @param Core.Zone#ZONE_BASE ZoneObject
      -- @param Wrapper.Group#GROUP GroupObject
      function( ZoneObject, GroupObject )
        if GroupObject:IsAnyInZone( ZoneObject ) then
          return true
        else
          return false
        end
      end, { ZoneObject } )

    return self
  end

  --- Iterate the SET_GROUP and return true if at least one of the @{Wrapper.Group#GROUP} is completely inside the @{Core.Zone#ZONE}
  -- @param #SET_GROUP self
  -- @param Core.Zone#ZONE Zone The Zone to be tested for.
  -- @return #boolean true if at least one of the @{Wrapper.Group#GROUP} is completely inside the @{Core.Zone#ZONE}, false otherwise.
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
  function SET_GROUP:AnyCompletelyInZone( Zone )
    --self:F2( Zone )
    local Set = self:GetSet()
    for GroupID, GroupData in pairs( Set ) do -- For each GROUP in SET_GROUP
      if GroupData:IsCompletelyInZone( Zone ) then
        return true
      end
    end
    return false
  end

  --- Iterate the SET_GROUP and return true if at least one @{#UNIT} of one @{Wrapper.Group#GROUP} of the @{#SET_GROUP} is in @{Core.Zone}
  -- @param #SET_GROUP self
  -- @param Core.Zone#ZONE Zone The Zone to be tested for.
  -- @return #boolean true if at least one of the @{Wrapper.Group#GROUP} is partly or completely inside the @{Core.Zone#ZONE}, false otherwise.
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
  function SET_GROUP:AnyInZone( Zone )
    --self:F2( Zone )
    local Set = self:GetSet()
    for GroupID, GroupData in pairs( Set ) do -- For each GROUP in SET_GROUP
      if GroupData:IsPartlyInZone( Zone ) or GroupData:IsCompletelyInZone( Zone ) then
        return true
      end
    end
    return false
  end

  --- Iterate the SET_GROUP and return true if at least one @{Wrapper.Group#GROUP} of the @{#SET_GROUP} is partly in @{Core.Zone}.
  -- Will return false if a @{Wrapper.Group#GROUP} is fully in the @{Core.Zone}
  -- @param #SET_GROUP self
  -- @param Core.Zone#ZONE Zone The Zone to be tested for.
  -- @return #boolean true if at least one of the @{Wrapper.Group#GROUP} is partly or completely inside the @{Core.Zone#ZONE}, false otherwise.
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
  function SET_GROUP:AnyPartlyInZone( Zone )
    --self:F2( Zone )
    local IsPartlyInZone = false
    local Set = self:GetSet()
    for GroupID, GroupData in pairs( Set ) do -- For each GROUP in SET_GROUP
      if GroupData:IsCompletelyInZone( Zone ) then
        return false
      elseif GroupData:IsPartlyInZone( Zone ) then
        IsPartlyInZone = true -- at least one GROUP is partly in zone
      end
    end

    if IsPartlyInZone then
      return true
    else
      return false
    end
  end

  --- Iterate the SET_GROUP and return true if no @{Wrapper.Group#GROUP} of the @{#SET_GROUP} is in @{Core.Zone}
  -- This could also be achieved with `not SET_GROUP:AnyPartlyInZone(Zone)`, but it's easier for the
  -- mission designer to add a dedicated method
  -- @param #SET_GROUP self
  -- @param Core.Zone#ZONE Zone The Zone to be tested for.
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
  function SET_GROUP:NoneInZone( Zone )
    --self:F2( Zone )
    local Set = self:GetSet()
    for GroupID, GroupData in pairs( Set ) do -- For each GROUP in SET_GROUP
      if not GroupData:IsNotInZone( Zone ) then -- If the GROUP is in Zone in any way
        return false
      end
    end
    return true
  end

  --- Iterate the SET_GROUP and count how many GROUPs are completely in the Zone
  -- That could easily be done with SET_GROUP:ForEachGroupCompletelyInZone(), but this function
  -- provides an easy to use shortcut...
  -- @param #SET_GROUP self
  -- @param Core.Zone#ZONE Zone The Zone to be tested for.
  -- @return #number the number of GROUPs completely in the Zone
  -- @usage
  -- local MyZone = ZONE:New("Zone1")
  -- local MySetGroup = SET_GROUP:New()
  -- MySetGroup:AddGroupsByName({"Group1", "Group2"})
  --
  -- MESSAGE:New("There are " .. MySetGroup:CountInZone(MyZone) .. " GROUPs in the Zone !", 10):ToAll()
  function SET_GROUP:CountInZone( Zone )
    --self:F2( Zone )
    local Count = 0
    local Set = self:GetSet()
    for GroupID, GroupData in pairs( Set ) do -- For each GROUP in SET_GROUP
      if GroupData:IsCompletelyInZone( Zone ) then
        Count = Count + 1
      end
    end
    return Count
  end

  --- Iterate the SET_GROUP and count how many UNITs are completely in the Zone
  -- @param #SET_GROUP self
  -- @param Core.Zone#ZONE Zone The Zone to be tested for.
  -- @return #number the number of GROUPs completely in the Zone
  -- @usage
  -- local MyZone = ZONE:New("Zone1")
  -- local MySetGroup = SET_GROUP:New()
  -- MySetGroup:AddGroupsByName({"Group1", "Group2"})
  --
  -- MESSAGE:New("There are " .. MySetGroup:CountUnitInZone(MyZone) .. " UNITs in the Zone !", 10):ToAll()
  function SET_GROUP:CountUnitInZone( Zone )
    --self:F2( Zone )
    local Count = 0
    local Set = self:GetSet()
    for GroupID, GroupData in pairs( Set ) do -- For each GROUP in SET_GROUP
      Count = Count + GroupData:CountInZone( Zone )
    end
    return Count
  end

  --- Iterate the SET_GROUP and count how many GROUPs and UNITs are alive.
  -- @param #SET_GROUP self
  -- @return #number The number of GROUPs alive.
  -- @return #number The number of UNITs alive.
  function SET_GROUP:CountAlive()
    local CountG = 0
    local CountU = 0

    local Set = self:GetSet()

    for GroupID, GroupData in pairs( Set ) do -- For each GROUP in SET_GROUP
      if GroupData and GroupData:IsAlive() then

        CountG = CountG + 1

        -- Count Units.
        for _, _unit in pairs( GroupData:GetUnits() ) do
          local unit = _unit -- Wrapper.Unit#UNIT
          if unit and unit:IsAlive() then
            CountU = CountU + 1
          end
        end
      end

    end

    return CountG, CountU
  end

  ----- Iterate the SET_GROUP and call an iterator function for each **alive** player, providing the Group of the player and optional parameters.
  -- @param #SET_GROUP self
  -- @param #function IteratorFunction The function that will be called when there is an alive player in the SET_GROUP. The function needs to accept a GROUP parameter.
  ---- @return #SET_GROUP self
  -- function SET_GROUP:ForEachPlayer( IteratorFunction, ... )
  --  --self:F2( arg )
  --
  --  self:ForEach( IteratorFunction, arg, self.PlayersAlive )
  --
  --  return self
  -- end
  --
  --
  ----- Iterate the SET_GROUP and call an iterator function for each client, providing the Client to the function and optional parameters.
  -- @param #SET_GROUP self
  -- @param #function IteratorFunction The function that will be called when there is an alive player in the SET_GROUP. The function needs to accept a CLIENT parameter.
  ---- @return #SET_GROUP self
  -- function SET_GROUP:ForEachClient( IteratorFunction, ... )
  --  --self:F2( arg )
  --
  --  self:ForEach( IteratorFunction, arg, self.Clients )
  --
  --  return self
  -- end

  ---
  -- @param #SET_GROUP self
  -- @param Wrapper.Group#GROUP MGroup The group that is checked for inclusion.
  -- @return #SET_GROUP self
  function SET_GROUP:IsIncludeObject( MGroup )
    --self:F2( MGroup )
    local MGroupInclude = true
    
    if self.Filter.Alive == true then
      local MGroupAlive = false
      --self:F( { Active = self.Filter.Active } )
      if MGroup and MGroup:IsAlive() then
        MGroupAlive = true
      end
      MGroupInclude = MGroupInclude and MGroupAlive
    end
    
    if self.Filter.Active ~= nil then
      local MGroupActive = false
      --self:F( { Active = self.Filter.Active } )
      if self.Filter.Active == false or (self.Filter.Active == true and MGroup:IsActive() == true) then
        MGroupActive = true
      end
      MGroupInclude = MGroupInclude and MGroupActive
    end

    if self.Filter.Coalitions and MGroupInclude then
      local MGroupCoalition = false
      for CoalitionID, CoalitionName in pairs( self.Filter.Coalitions ) do
        --self:T3( { "Coalition:", MGroup:GetCoalition(), self.FilterMeta.Coalitions[CoalitionName], CoalitionName } )
        if self.FilterMeta.Coalitions[CoalitionName] and self.FilterMeta.Coalitions[CoalitionName] == MGroup:GetCoalition() then
          MGroupCoalition = true
        end
      end
      MGroupInclude = MGroupInclude and MGroupCoalition
    end

    if self.Filter.Categories and MGroupInclude then
      local MGroupCategory = false
      for CategoryID, CategoryName in pairs( self.Filter.Categories ) do
        --self:I( { "Category:", MGroup:GetCategory(), self.FilterMeta.Categories[CategoryName], CategoryName } )
        if self.FilterMeta.Categories[CategoryName] and self.FilterMeta.Categories[CategoryName] == MGroup:GetCategory() then
          MGroupCategory = true
        end
      end
      MGroupInclude = MGroupInclude and MGroupCategory
      --self:I("Is Included: "..tostring(MGroupInclude))
    end

    if self.Filter.Countries and MGroupInclude then
      local MGroupCountry = false
      for CountryID, CountryName in pairs( self.Filter.Countries ) do
        --self:T3( { "Country:", MGroup:GetCountry(), CountryName } )
        if country.id[CountryName] == MGroup:GetCountry() then
          MGroupCountry = true
        end
      end
      MGroupInclude = MGroupInclude and MGroupCountry
    end

    if self.Filter.GroupPrefixes and MGroupInclude then
      local MGroupPrefix = false
      for GroupPrefixId, GroupPrefix in pairs( self.Filter.GroupPrefixes ) do
        --self:I( { "Prefix:", MGroup:GetName(), GroupPrefix } )
        if string.find(MGroup:GetName(), string.gsub(GroupPrefix,"-","%%-"),1) then
          MGroupPrefix = true
        end
      end
      MGroupInclude = MGroupInclude and MGroupPrefix
      --self:I("Is Included: "..tostring(MGroupInclude))
    end
    
    if self.Filter.Zones and MGroupInclude then
      local MGroupZone = false
      for ZoneName, Zone in pairs( self.Filter.Zones ) do
        --self:T( "Zone:", ZoneName )
        if MGroup:IsInZone(Zone) then
          MGroupZone = true
        end
      end
      MGroupInclude = MGroupInclude and MGroupZone
    end
    
    if self.Filter.Functions and MGroupInclude then
      local MGroupFunc = false
      MGroupFunc = self:_EvalFilterFunctions(MGroup)
      MGroupInclude = MGroupInclude and MGroupFunc
    end
     
    --self:I( MGroupInclude )
    return MGroupInclude
  end

  --- Get the closest group of the set with respect to a given reference coordinate. Optionally, only groups of given coalitions are considered in the search.
  -- @param #SET_GROUP self
  -- @param Core.Point#COORDINATE Coordinate Reference Coordinate from which the closest group is determined.
  -- @param #table Coalitions (Optional) Table of coalition #number entries to filter for.
  -- @return Wrapper.Group#GROUP The closest group (if any).
  -- @return #number Distance in meters to the closest group.
  function SET_GROUP:GetClosestGroup(Coordinate, Coalitions)
  
    local Set = self:GetSet()
    
    local dmin=math.huge
    local gmin=nil
    
    for GroupID, GroupData in pairs( Set ) do -- For each GROUP in SET_GROUP
      local group=GroupData --Wrapper.Group#GROUP
      
      if group and group:IsAlive() and (Coalitions==nil or UTILS.IsAnyInTable(Coalitions, group:GetCoalition())) then
      
        local coord=group:GetCoordinate()
        
        local d
        
        if coord ~= nil then
          -- Distance between ref. coordinate and group coordinate.
          d=UTILS.VecDist3D(Coordinate, coord)
        
          if d<dmin then
            dmin=d
            gmin=group
          end
        end
      end
    
    end
    
    return gmin, dmin
  end

  --- Iterate the SET_GROUP and set for each unit the default cargo bay weight limit.
  -- Because within a group, the type of carriers can differ, each cargo bay weight limit is set on @{Wrapper.Unit} level.
  -- @param #SET_GROUP self
  -- @usage
  -- -- Set the default cargo bay weight limits of the carrier units.
  -- local MySetGroup = SET_GROUP:New()
  -- MySetGroup:SetCargoBayWeightLimit()
  function SET_GROUP:SetCargoBayWeightLimit()
    local Set = self:GetSet()
    for GroupID, GroupData in pairs( Set ) do -- For each GROUP in SET_GROUP
      for UnitName, UnitData in pairs( GroupData:GetUnits() ) do
        -- local UnitData = UnitData -- Wrapper.Unit#UNIT
        UnitData:SetCargoBayWeightLimit()
      end
    end
  end

end

do -- SET_UNIT
  
  ---
  -- @type SET_UNIT SET\_UNIT
  -- @field Core.Timer#TIMER ZoneTimer
  -- @field #number ZoneTimerInterval
  -- @extends Core.Set#SET_BASE

  --- Mission designers can use the SET_UNIT class to build sets of units belonging to certain:
  --
  --  * Coalitions
  --  * Categories
  --  * Countries
  --  * Unit types
  --  * Starting with certain prefix strings.
  --
  -- ## 1) SET_UNIT constructor
  --
  -- Create a new SET_UNIT object with the @{#SET_UNIT.New} method:
  --
  --    * @{#SET_UNIT.New}: Creates a new SET_UNIT object.
  --
  -- ## 2) Add or Remove UNIT(s) from SET_UNIT
  --
  -- UNITs can be added and removed using the @{Core.Set#SET_UNIT.AddUnitsByName} and @{Core.Set#SET_UNIT.RemoveUnitsByName} respectively.
  -- These methods take a single UNIT name or an array of UNIT names to be added or removed from SET_UNIT.
  --
  -- ## 3) SET_UNIT filter criteria
  --
  -- You can set filter criteria to define the set of units within the SET_UNIT.
  -- Filter criteria are defined by:
  --
  --    * @{#SET_UNIT.FilterCoalitions}: Builds the SET_UNIT with the units belonging to the coalition(s).
  --    * @{#SET_UNIT.FilterCategories}: Builds the SET_UNIT with the units belonging to the category(ies).
  --    * @{#SET_UNIT.FilterTypes}: Builds the SET_UNIT with the units belonging to the unit type(s).
  --    * @{#SET_UNIT.FilterCountries}: Builds the SET_UNIT with the units belonging to the country(ies).
  --    * @{#SET_UNIT.FilterPrefixes}: Builds the SET_UNIT with the units sharing the same string(s) in their name. **Attention!** LUA regular expression apply here, so special characters in names like minus, dot, hash (#) etc might lead to unexpected results. 
  -- Have a read through here to understand the application of regular expressions: [LUA regular expressions](https://riptutorial.com/lua/example/20315/lua-pattern-matching)
  --    * @{#SET_UNIT.FilterActive}: Builds the SET_UNIT with the units that are only active. Units that are inactive (late activation) won't be included in the set!
  --    * @{#SET_UNIT.FilterZones}: Builds the SET_UNIT with the units within a @{Core.Zone#ZONE}.
  --    * @{#SET_UNIT.FilterFunction}: Builds the SET_UNIT with a custom condition.
  --    
  -- Once the filter criteria have been set for the SET_UNIT, you can start filtering using:
  --
  --   * @{#SET_UNIT.FilterStart}: Starts the filtering of the units **dynamically**.
  --   * @{#SET_UNIT.FilterOnce}: Filters of the units **once**.
  --
  -- ## 4) SET_UNIT iterators
  --
  -- Once the filters have been defined and the SET_UNIT has been built, you can iterate the SET_UNIT with the available iterator methods.
  -- The iterator methods will walk the SET_UNIT set, and call for each element within the set a function that you provide.
  -- The following iterator methods are currently available within the SET_UNIT:
  --
  --   * @{#SET_UNIT.ForEachUnit}: Calls a function for each alive unit it finds within the SET_UNIT.
  --   * @{#SET_UNIT.ForEachUnitInZone}: Iterate the SET_UNIT and call an iterator function for each **alive** UNIT object presence completely in a @{Core.Zone}, providing the UNIT object and optional parameters to the called function.
  --   * @{#SET_UNIT.ForEachUnitNotInZone}: Iterate the SET_UNIT and call an iterator function for each **alive** UNIT object presence not in a @{Core.Zone}, providing the UNIT object and optional parameters to the called function.
  --   * @{#SET_UNIT:ForEachUnitPerThreatLevel}: Iterate the SET_UNIT **sorted *per Threat Level** and call an iterator function for each **alive** UNIT, providing the UNIT and optional parameters
  --
  -- ## 5) SET_UNIT atomic methods
  --
  -- Various methods exist for a SET_UNIT to perform actions or calculations and retrieve results from the SET_UNIT:
  --
  --   * @{#SET_UNIT.GetTypeNames}(): Retrieve the type names of the @{Wrapper.Unit}s in the SET, delimited by a comma.
  --
  -- ## 6) SET_UNIT trigger events on the UNIT objects.
  --
  -- The SET is derived from the FSM class, which provides extra capabilities to track the contents of the UNIT objects in the SET_UNIT.
  --
  -- ### 6.1) When a UNIT object crashes or is dead, the SET_UNIT will trigger a **Dead** event.
  --
  -- You can handle the event using the OnBefore and OnAfter event handlers.
  -- The event handlers need to have the parameters From, Event, To, GroupObject.
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
  --          --self:F( { UnitObject = UnitObject:GetName() } )
  --        end
  --
  -- While this is a good example, there is a catch.
  -- Imagine you want to execute the code above, the the self would need to be from the object declared outside (above) the OnAfterDead method.
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
      Zones = nil,
      Functions = nil,
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
    local self = BASE:Inherit( self, SET_BASE:New( _DATABASE.UNITS ) ) -- #SET_UNIT

    self:FilterActive( false )
    
    --- Count Alive Units
    -- @function [parent=#SET_UNIT] CountAlive
    -- @param #SET_UNIT self
    -- @return #SET_UNIT self
    
    return self
  end

  --- Add UNIT(s) to SET_UNIT.
  -- @param #SET_UNIT self
  -- @param Wrapper.Unit#UNIT Unit A single UNIT.
  -- @return #SET_UNIT self
  function SET_UNIT:AddUnit( Unit )
    --self:F2( Unit:GetName() )

    self:Add( Unit:GetName(), Unit )
    
    if Unit:IsInstanceOf("UNIT") then
      -- Set the default cargo bay limit each time a new unit is added to the set.
      Unit:SetCargoBayWeightLimit()
    end
    
    return self
  end

  --- Add UNIT(s) to SET_UNIT.
  -- @param #SET_UNIT self
  -- @param #string AddUnitNames A single name or an array of UNIT names.
  -- @return #SET_UNIT self
  function SET_UNIT:AddUnitsByName( AddUnitNames )

    local AddUnitNamesArray = (type( AddUnitNames ) == "table") and AddUnitNames or { AddUnitNames }

    --self:T( AddUnitNamesArray )
    for AddUnitID, AddUnitName in pairs( AddUnitNamesArray ) do
      self:Add( AddUnitName, UNIT:FindByName( AddUnitName ) )
    end

    return self
  end

  --- Remove UNIT(s) from SET_UNIT.
  -- @param Core.Set#SET_UNIT self
  -- @param #table RemoveUnitNames A single name or an array of UNIT names.
  -- @return Core.Set#SET_UNIT self
  function SET_UNIT:RemoveUnitsByName( RemoveUnitNames )

    local RemoveUnitNamesArray = (type( RemoveUnitNames ) == "table") and RemoveUnitNames or { RemoveUnitNames }

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

  --- Builds a set of UNITs that contain a given string in their unit name.
  -- **Attention!** Bad naming convention as this **does not** filter only **prefixes** but all units that **contain** the string. 
  -- @param #SET_UNIT self
  -- @param #string Prefixes The string pattern(s) that needs to be contained in the unit name. Can also be passed as a `#table` of strings.
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
  
  --- Builds a set of units in zones.
  -- @param #SET_UNIT self
  -- @param #table Zones Table of Core.Zone#ZONE Zone objects, or a Core.Set#SET_ZONE
  -- @return #SET_UNIT self
  function SET_UNIT:FilterZones( Zones )
    if not self.Filter.Zones then
      self.Filter.Zones = {}
    end
    local zones = {}
    if Zones.ClassName and Zones.ClassName == "SET_ZONE" then
      zones = Zones.Set
    elseif type( Zones ) ~= "table" or (type( Zones ) == "table" and Zones.ClassName ) then
      self:E("***** FilterZones needs either a table of ZONE Objects or a SET_ZONE as parameter!")
      return self     
    else
      zones = Zones
    end
    for _,Zone in pairs( zones ) do
      local zonename = Zone:GetName()
      self.Filter.Zones[zonename] = Zone
    end
    return self
  end
  
  --- Builds a set of units that are only active.
  -- Only the units that are active will be included within the set.
  -- @param #SET_UNIT self
  -- @param #boolean Active (Optional) Include only active units to the set.
  -- Include inactive units if you provide false.
  -- @return #SET_UNIT self
  -- @usage
  --
  -- -- Include only active units to the set.
  -- UnitSet = SET_UNIT:New():FilterActive():FilterStart()
  --
  -- -- Include only active units to the set of the blue coalition, and filter one time.
  -- UnitSet = SET_UNIT:New():FilterActive():FilterCoalition( "blue" ):FilterOnce()
  --
  -- -- Include only active units to the set of the blue coalition, and filter one time.
  -- -- Later, reset to include back inactive units to the set.
  -- UnitSet = SET_UNIT:New():FilterActive():FilterCoalition( "blue" ):FilterOnce()
  -- ... logic ...
  -- UnitSet = SET_UNIT:New():FilterActive( false ):FilterCoalition( "blue" ):FilterOnce()
  --
  function SET_UNIT:FilterActive( Active )
    Active = Active or not (Active == false)
    self.Filter.Active = Active
    return self
  end
  
  --- Builds a set of units which exist and are alive.
  -- @param #SET_UNIT self
  -- @return #SET_UNIT self
  function SET_UNIT:FilterAlive()
    self:FilterFunction(
      function(unit)
        if unit and unit:IsExist() and unit:IsAlive() then
          return true
        else
          return false
        end
      end
    )
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

  --- Iterate the SET_UNIT and count how many UNITs are alive.
  -- @param #SET_UNIT self
  -- @return #number The number of UNITs alive.
  function SET_UNIT:CountAlive()

    local Set = self:GetSet()

    local CountU = 0
    for UnitID, UnitData in pairs( Set ) do -- For each GROUP in SET_GROUP
      if UnitData and UnitData:IsAlive() then
        CountU = CountU + 1
      end

    end

    return CountU
  end
  
  --- Gets the alive set.
  -- @param #SET_UNIT self
  -- @return #table Table of SET objects
  -- @return #SET_UNIT AliveSet 
  function SET_UNIT:GetAliveSet()

    local AliveSet = SET_UNIT:New()

    -- Clean the Set before returning with only the alive Groups.
    for GroupName, GroupObject in pairs(self.Set) do    
      local GroupObject=GroupObject --Wrapper.Client#CLIENT
      
      if GroupObject and GroupObject:IsAlive() then      
        AliveSet:Add(GroupName, GroupObject)
      end
    end

    return AliveSet.Set or {}, AliveSet
  end
  
  --- [Internal] Private function for use of continous zone filter
  -- @param #SET_UNIT self
  -- @return #SET_UNIT self
  function SET_UNIT:_ContinousZoneFilter()
    
    local Database = _DATABASE.UNITS
    
    for ObjectName, Object in pairs( Database ) do
      if self:IsIncludeObject( Object ) and self:IsNotInSet(Object) then
        self:Add( ObjectName, Object )
      elseif (not self:IsIncludeObject( Object )) and self:IsInSet(Object) then
        self:Remove(ObjectName)
      end
    end
    
    return self
    
  end
  
  --- Set filter timer interval for FilterZones if using active filtering with FilterStart().
  -- @param #SET_UNIT self
  -- @param #number Seconds Seconds between check intervals, defaults to 30. **Caution** - do not be too agressive with timing! Groups are usually not moving fast enough
  -- to warrant a check of below 10 seconds.
  -- @return #SET_UNIT self
  function SET_UNIT:FilterZoneTimer(Seconds)
    self.ZoneTimerInterval = Seconds or 30
    return self
  end
  
  --- Stops the filtering.
  -- @param #SET_UNIT self
  -- @return #SET_UNIT self
  function SET_UNIT:FilterStop()

    if _DATABASE then
      
      self:UnHandleEvent(EVENTS.Birth)
      self:UnHandleEvent(EVENTS.Dead)
      self:UnHandleEvent(EVENTS.Crash)
      self:UnHandleEvent(EVENTS.RemoveUnit)
      
      if self.Filter.Zones and self.ZoneTimer and self.ZoneTimer:IsRunning() then
        self.ZoneTimer:Stop()
      end
    end

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
      self:HandleEvent( EVENTS.RemoveUnit, self._EventOnDeadOrCrash )
      self:HandleEvent( EVENTS.UnitLost, self._EventOnDeadOrCrash )
      if self.Filter.Zones then
        self.ZoneTimer = TIMER:New(self._ContinousZoneFilter,self)
        local timing = self.ZoneTimerInterval or 30
        self.ZoneTimer:Start(timing,timing)
      end
    end

    return self
  end

  --- [User] Add a custom condition function.
  -- @function [parent=#SET_UNIT] FilterFunction
  -- @param #SET_UNIT self
  -- @param #function ConditionFunction If this function returns `true`, the object is added to the SET. The function needs to take a UNIT object as first argument.
  -- @param ... Condition function arguments if any.
  -- @return #SET_UNIT self
  -- @usage
  --          -- Image you want to exclude a specific UNIT from a SET:
  --          local groundset = SET_UNIT:New():FilterCoalitions("blue"):FilterCategories("ground"):FilterFunction(
  --          -- The function needs to take a UNIT object as first - and in this case, only - argument.
  --          function(unit)
  --              local isinclude = true
  --              if unit:GetName() == "Exclude Me" then isinclude = false end
  --              return isinclude
  --          end
  --          ):FilterOnce()
  --          BASE:I(groundset:Flush())


  --- Handles the Database to check on an event (birth) that the Object was added in the Database.
  -- This is required, because sometimes the _DATABASE birth event gets called later than the SET_BASE birth event!
  -- @param #SET_UNIT self
  -- @param Core.Event#EVENTDATA Event
  -- @return #string The name of the UNIT
  -- @return #table The UNIT
  function SET_UNIT:AddInDatabase( Event )
    --self:F3( { Event } )

    if Event.IniObjectCategory == Object.Category.UNIT then
      if not self.Database[Event.IniDCSUnitName] then
        self.Database[Event.IniDCSUnitName] = UNIT:Register( Event.IniDCSUnitName )
        --self:T3( self.Database[Event.IniDCSUnitName] )
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
    --self:F2( { Event.IniDCSUnitName, self.Set[Event.IniDCSUnitName], Event } )

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

        local ZoneUnitName = ZoneUnit:GetName()
        --self:F( { ZoneUnitName = ZoneUnitName } )
        if self:FindUnit( ZoneUnitName ) then
          IsPartiallyInZone = true
          --self:F( { Found = true } )
          return false
        end

        return true
      end

      ZoneTest:SearchZone( EvaluateZone )

      return IsPartiallyInZone
    end

    --- Check if no element of the SET_UNIT is in the Zone.
    -- @param #SET_UNIT self
    -- @param Core.Zone#ZONE Zone The Zone to be tested for.
    -- @return #boolean
    function SET_UNIT:IsNotInZone( Zone )

      local IsNotInZone = true

      local function EvaluateZone( ZoneUnit )

        local ZoneUnitName = ZoneUnit:GetName()
        if self:FindUnit( ZoneUnitName ) then
          IsNotInZone = false
          return false
        end

        return true
      end

      Zone:SearchZone( EvaluateZone )

      return IsNotInZone
    end

  end


  --- Iterate the SET_UNIT and call an iterator function for each **alive** UNIT, providing the UNIT and optional parameters.
  -- @param #SET_UNIT self
  -- @param #function IteratorFunction The function that will be called when there is an alive UNIT in the SET_UNIT. The function needs to accept a UNIT parameter.
  -- @return #SET_UNIT self
  function SET_UNIT:ForEachUnit( IteratorFunction, ... )
    --self:F2( arg )

    self:ForEach( IteratorFunction, arg, self:GetSet() )

    return self
  end

  --- Get the SET of the SET_UNIT **sorted per Threat Level**.
  --
  -- @param #SET_UNIT self
  -- @param #number FromThreatLevel The TreatLevel to start the evaluation **From** (this must be a value between 0 and 10).
  -- @param #number ToThreatLevel The TreatLevel to stop the evaluation **To** (this must be a value between 0 and 10).
  -- @return #SET_UNIT self
  function SET_UNIT:GetSetPerThreatLevel( FromThreatLevel, ToThreatLevel )
    --self:F2( arg )

    local ThreatLevelSet = {}

    if self:Count() ~= 0 then
      for UnitName, UnitObject in pairs( self.Set ) do
        local Unit = UnitObject -- Wrapper.Unit#UNIT

        local ThreatLevel = Unit:GetThreatLevel()
        ThreatLevelSet[ThreatLevel] = ThreatLevelSet[ThreatLevel] or {}
        ThreatLevelSet[ThreatLevel].Set = ThreatLevelSet[ThreatLevel].Set or {}
        ThreatLevelSet[ThreatLevel].Set[UnitName] = UnitObject
        --self:F( { ThreatLevel = ThreatLevel, ThreatLevelSet = ThreatLevelSet[ThreatLevel].Set } )
      end

      local OrderedPerThreatLevelSet = {}

      local ThreatLevelIncrement = FromThreatLevel <= ToThreatLevel and 1 or -1

      for ThreatLevel = FromThreatLevel, ToThreatLevel, ThreatLevelIncrement do
        --self:F( { ThreatLevel = ThreatLevel } )
        local ThreatLevelItem = ThreatLevelSet[ThreatLevel]
        if ThreatLevelItem then
          for UnitName, UnitObject in pairs( ThreatLevelItem.Set ) do
            table.insert( OrderedPerThreatLevelSet, UnitObject )
          end
        end
      end

      return OrderedPerThreatLevelSet
    end

  end


  --- Iterate the SET_UNIT **sorted *per Threat Level** and call an iterator function for each **alive** UNIT, providing the UNIT and optional parameters.
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
  function SET_UNIT:ForEachUnitPerThreatLevel( FromThreatLevel, ToThreatLevel, IteratorFunction, ... ) -- R2.1 Threat Level implementation
    --self:F2( arg )

    local ThreatLevelSet = {}

    if self:Count() ~= 0 then
      for UnitName, UnitObject in pairs( self.Set ) do
        local Unit = UnitObject -- Wrapper.Unit#UNIT

        local ThreatLevel = Unit:GetThreatLevel()
        ThreatLevelSet[ThreatLevel] = ThreatLevelSet[ThreatLevel] or {}
        ThreatLevelSet[ThreatLevel].Set = ThreatLevelSet[ThreatLevel].Set or {}
        ThreatLevelSet[ThreatLevel].Set[UnitName] = UnitObject
        --self:F( { ThreatLevel = ThreatLevel, ThreatLevelSet = ThreatLevelSet[ThreatLevel].Set } )
      end

      local ThreatLevelIncrement = FromThreatLevel <= ToThreatLevel and 1 or -1

      for ThreatLevel = FromThreatLevel, ToThreatLevel, ThreatLevelIncrement do
        --self:F( { ThreatLevel = ThreatLevel } )
        local ThreatLevelItem = ThreatLevelSet[ThreatLevel]
        if ThreatLevelItem then
          self:ForEach( IteratorFunction, arg, ThreatLevelItem.Set )
        end
      end
    end

    return self
  end

  --- Iterate the SET_UNIT and call an iterator function for each **alive** UNIT presence completely in a @{Core.Zone}, providing the UNIT and optional parameters to the called function.
  -- @param #SET_UNIT self
  -- @param Core.Zone#ZONE ZoneObject The Zone to be tested for.
  -- @param #function IteratorFunction The function that will be called when there is an alive UNIT in the SET_UNIT. The function needs to accept a UNIT parameter.
  -- @return #SET_UNIT self
  function SET_UNIT:ForEachUnitCompletelyInZone( ZoneObject, IteratorFunction, ... )
    --self:F2( arg )

    self:ForEach( IteratorFunction, arg, self:GetSet(),
      -- @param Core.Zone#ZONE_BASE ZoneObject
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

  --- Iterate the SET_UNIT and call an iterator function for each **alive** UNIT presence not in a @{Core.Zone}, providing the UNIT and optional parameters to the called function.
  -- @param #SET_UNIT self
  -- @param Core.Zone#ZONE ZoneObject The Zone to be tested for.
  -- @param #function IteratorFunction The function that will be called when there is an alive UNIT in the SET_UNIT. The function needs to accept a UNIT parameter.
  -- @return #SET_UNIT self
  function SET_UNIT:ForEachUnitNotInZone( ZoneObject, IteratorFunction, ... )
    --self:F2( arg )

    self:ForEach( IteratorFunction, arg, self:GetSet(),
      -- @param Core.Zone#ZONE_BASE ZoneObject
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
    --self:F2()

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
      MT[#MT + 1] = UnitType .. " of " .. UnitTypeID
    end

    return UnitTypes
  end

  --- Returns a comma separated string of the unit types with a count in the  @{Core.Set}.
  -- @param #SET_UNIT self
  -- @return #string The unit types string
  function SET_UNIT:GetUnitTypesText()
    --self:F2()

    local MT = {} -- Message Text
    local UnitTypes = self:GetUnitTypes()

    for UnitTypeID, UnitType in pairs( UnitTypes ) do
      MT[#MT + 1] = UnitType .. " of " .. UnitTypeID
    end

    return table.concat( MT, ", " )
  end

  --- Returns map of unit threat levels.
  -- @param #SET_UNIT self
  -- @return #table.
  function SET_UNIT:GetUnitThreatLevels()
    --self:F2()

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

  --- Calculate the maximum A2G threat level of the SET_UNIT.
  -- @param #SET_UNIT self
  -- @return #number The maximum threat level
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

    --self:F( { MaxThreatLevelA2G = MaxThreatLevelA2G, MaxThreatText = MaxThreatText } )
    return MaxThreatLevelA2G, MaxThreatText

  end

  --- Get the center coordinate of the SET_UNIT.
  -- @param #SET_UNIT self
  -- @return Core.Point#COORDINATE The center coordinate of all the units in the set, including heading in degrees and speed in mps in case of moving units.
  function SET_UNIT:GetCoordinate()
    
    local function GetSetVec3(units)
      -- Init.
      local x=0 
      local y=0 
      local z=0 
      local n=0
      -- Loop over all units.
      for _,unit in pairs(units) do
        local vec3=nil --DCS#Vec3
        if unit and unit:IsAlive() then
          vec3 = unit:GetVec3()
        end
        if vec3 then
          -- Sum up posits.
          x=x+vec3.x
          y=y+vec3.y
          z=z+vec3.z
          -- Increase counter.
          n=n+1
        end
      end
      if n>0 then
        -- Average.
        local Vec3={x=x/n, y=y/n, z=z/n} --DCS#Vec3
        return Vec3
      end
      return nil
    end
    
    local Coordinate = nil
    local Vec3 = GetSetVec3(self.Set)
    if Vec3 then
      Coordinate = COORDINATE:NewFromVec3(Vec3)
    end

    if Coordinate then
      local heading = self:GetHeading() or 0
      local velocity = self:GetVelocity() or 0
      Coordinate:SetHeading( heading )
      Coordinate:SetVelocity( velocity )
      --self:T(UTILS.PrintTableToLog(Coordinate))
    end

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
      if Velocity ~= 0 then
        MaxVelocity = (MaxVelocity < Velocity) and Velocity or MaxVelocity
      end
    end

    --self:F( { MaxVelocity = MaxVelocity } )
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
      if Velocity ~= 0 then
        local Heading = Coordinate:GetHeading()
        if HeadingSet == nil then
          HeadingSet = Heading
        else
          local HeadingDiff = (HeadingSet - Heading + 180 + 360) % 360 - 180
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

  --- Returns if the @{Core.Set} has targets having a radar (of a given type).
  -- @param #SET_UNIT self
  -- @param DCS#Unit.RadarType RadarType
  -- @return #number The amount of radars in the Set with the given type
  function SET_UNIT:HasRadar( RadarType )
    --self:F2( RadarType )

    local RadarCount = 0
    for UnitID, UnitData in pairs( self:GetSet() ) do
      local UnitSensorTest = UnitData -- Wrapper.Unit#UNIT
      local HasSensors
      if RadarType then
        HasSensors = UnitSensorTest:HasSensors( Unit.SensorType.RADAR, RadarType )
      else
        HasSensors = UnitSensorTest:HasSensors( Unit.SensorType.RADAR )
      end
      --self:T3( HasSensors )
      if HasSensors then
        RadarCount = RadarCount + 1
      end
    end

    return RadarCount
  end

  --- Returns if the @{Core.Set} has targets that can be SEADed.
  -- @param #SET_UNIT self
  -- @return #number The amount of SEADable units in the Set
  function SET_UNIT:HasSEAD()
    --self:F2()

    local SEADCount = 0
    for UnitID, UnitData in pairs( self:GetSet() ) do
      local UnitSEAD = UnitData -- Wrapper.Unit#UNIT
      if UnitSEAD:IsAlive() then
        local UnitSEADAttributes = UnitSEAD:GetDesc().attributes

        local HasSEAD = UnitSEAD:HasSEAD()

        --self:T3( HasSEAD )
        if HasSEAD then
          SEADCount = SEADCount + 1
        end
      end
    end

    return SEADCount
  end

  --- Returns if the @{Core.Set} has ground targets.
  -- @param #SET_UNIT self
  -- @return #number The amount of ground targets in the Set.
  function SET_UNIT:HasGroundUnits()
    --self:F2()

    local GroundUnitCount = 0
    for UnitID, UnitData in pairs( self:GetSet() ) do
      local UnitTest = UnitData -- Wrapper.Unit#UNIT
      if UnitTest:IsGround() then
        GroundUnitCount = GroundUnitCount + 1
      end
    end

    return GroundUnitCount
  end

  --- Returns if the @{Core.Set} has air targets.
  -- @param #SET_UNIT self
  -- @return #number The amount of air targets in the Set.
  function SET_UNIT:HasAirUnits()
    --self:F2()

    local AirUnitCount = 0
    for UnitID, UnitData in pairs( self:GetSet() ) do
      local UnitTest = UnitData -- Wrapper.Unit#UNIT
      if UnitTest:IsAir() then
        AirUnitCount = AirUnitCount + 1
      end
    end

    return AirUnitCount
  end

  --- Returns if the @{Core.Set} has friendly ground units.
  -- @param #SET_UNIT self
  -- @return #number The amount of ground targets in the Set.
  function SET_UNIT:HasFriendlyUnits( FriendlyCoalition )
    --self:F2()

    local FriendlyUnitCount = 0
    for UnitID, UnitData in pairs( self:GetSet() ) do
      local UnitTest = UnitData -- Wrapper.Unit#UNIT
      if UnitTest:IsFriendly( FriendlyCoalition ) then
        FriendlyUnitCount = FriendlyUnitCount + 1
      end
    end

    return FriendlyUnitCount
  end



  ----- Iterate the SET_UNIT and call an iterator function for each **alive** player, providing the Unit of the player and optional parameters.
  -- @param #SET_UNIT self
  -- @param #function IteratorFunction The function that will be called when there is an alive player in the SET_UNIT. The function needs to accept a UNIT parameter.
  ---- @return #SET_UNIT self
  -- function SET_UNIT:ForEachPlayer( IteratorFunction, ... )
  --  --self:F2( arg )
  --
  --  self:ForEach( IteratorFunction, arg, self.PlayersAlive )
  --
  --  return self
  -- end
  --
  --
  ----- Iterate the SET_UNIT and call an iterator function for each client, providing the Client to the function and optional parameters.
  -- @param #SET_UNIT self
  -- @param #function IteratorFunction The function that will be called when there is an alive player in the SET_UNIT. The function needs to accept a CLIENT parameter.
  ---- @return #SET_UNIT self
  -- function SET_UNIT:ForEachClient( IteratorFunction, ... )
  --  --self:F2( arg )
  --
  --  self:ForEach( IteratorFunction, arg, self.Clients )
  --
  --  return self
  -- end

  ---
  -- @param #SET_UNIT self
  -- @param Wrapper.Unit#UNIT MUnit
  -- @return #SET_UNIT self
  function SET_UNIT:IsIncludeObject( MUnit )
    --self:F2( {MUnit} )

    local MUnitInclude = false

    if MUnit:IsAlive() ~= nil then

      MUnitInclude = true

      if self.Filter.Active ~= nil then
        local MUnitActive = false
        if self.Filter.Active == false or (self.Filter.Active == true and MUnit:IsActive() == true) then
          MUnitActive = true
        end
        MUnitInclude = MUnitInclude and MUnitActive
      end

      if self.Filter.Coalitions and MUnitInclude then
        local MUnitCoalition = false
        for CoalitionID, CoalitionName in pairs( self.Filter.Coalitions ) do
          --self:F( { "Coalition:", MUnit:GetCoalition(), self.FilterMeta.Coalitions[CoalitionName], CoalitionName } )
          if self.FilterMeta.Coalitions[CoalitionName] and self.FilterMeta.Coalitions[CoalitionName] == MUnit:GetCoalition() then
            MUnitCoalition = true
          end
        end
        MUnitInclude = MUnitInclude and MUnitCoalition
      end

      if self.Filter.Categories and MUnitInclude then
        local MUnitCategory = false
        for CategoryID, CategoryName in pairs( self.Filter.Categories ) do
          --self:T3( { "Category:", MUnit:GetDesc().category, self.FilterMeta.Categories[CategoryName], CategoryName } )
          if self.FilterMeta.Categories[CategoryName] and self.FilterMeta.Categories[CategoryName] == MUnit:GetDesc().category then
            MUnitCategory = true
          end
        end
        MUnitInclude = MUnitInclude and MUnitCategory
      end

      if self.Filter.Types and MUnitInclude then
        local MUnitType = false
        for TypeID, TypeName in pairs( self.Filter.Types ) do
          --self:T3( { "Type:", MUnit:GetTypeName(), TypeName } )
          if TypeName == MUnit:GetTypeName() then
            MUnitType = true
          end
        end
        MUnitInclude = MUnitInclude and MUnitType
      end

      if self.Filter.Countries and MUnitInclude then
        local MUnitCountry = false
        for CountryID, CountryName in pairs( self.Filter.Countries ) do
          --self:T3( { "Country:", MUnit:GetCountry(), CountryName } )
          if country.id[CountryName] == MUnit:GetCountry() then
            MUnitCountry = true
          end
        end
        MUnitInclude = MUnitInclude and MUnitCountry
      end

      if self.Filter.UnitPrefixes and MUnitInclude then
        local MUnitPrefix = false
        for UnitPrefixId, UnitPrefix in pairs( self.Filter.UnitPrefixes ) do
          --self:T3( { "Prefix:", string.find( MUnit:GetName(), UnitPrefix, 1 ), UnitPrefix } )
          if string.find( MUnit:GetName(), UnitPrefix, 1 ) then
            MUnitPrefix = true
          end
        end
        MUnitInclude = MUnitInclude and MUnitPrefix
      end

      if self.Filter.RadarTypes and MUnitInclude then
        local MUnitRadar = false
        for RadarTypeID, RadarType in pairs( self.Filter.RadarTypes ) do
          --self:T3( { "Radar:", RadarType } )
          if MUnit:HasSensors( Unit.SensorType.RADAR, RadarType ) == true then
            if MUnit:GetRadar() == true then -- This call is necessary to evaluate the SEAD capability.
              --self:T3( "RADAR Found" )
            end
            MUnitRadar = true
          end
        end
        MUnitInclude = MUnitInclude and MUnitRadar
      end

      if self.Filter.SEAD and MUnitInclude then
        local MUnitSEAD = false
        if MUnit:HasSEAD() == true then
          --self:T3( "SEAD Found" )
          MUnitSEAD = true
        end
        MUnitInclude = MUnitInclude and MUnitSEAD
      end
    end
    
    if self.Filter.Zones and MUnitInclude then
      local MGroupZone = false
      for ZoneName, Zone in pairs( self.Filter.Zones ) do
        --self:T3( "Zone:", ZoneName )
        if MUnit:IsInZone(Zone) then
          MGroupZone = true
        end
      end
      MUnitInclude = MUnitInclude  and MGroupZone
    end
    
    if self.Filter.Functions and MUnitInclude then
      local MUnitFunc = self:_EvalFilterFunctions(MUnit)
      MUnitInclude = MUnitInclude  and MUnitFunc
    end
    
    --self:T2( MUnitInclude )
    return MUnitInclude
  end

  --- Retrieve the type names of the @{Wrapper.Unit}s in the SET, delimited by an optional delimiter.
  -- @param #SET_UNIT self
  -- @param #string Delimiter (Optional) The delimiter, which is default a comma.
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

  --- Iterate the SET_UNIT and set for each unit the default cargo bay weight limit.
  -- @param #SET_UNIT self
  -- @usage
  -- -- Set the default cargo bay weight limits of the carrier units.
  -- local MySetUnit = SET_UNIT:New()
  -- MySetUnit:SetCargoBayWeightLimit()
  function SET_UNIT:SetCargoBayWeightLimit()
    local Set = self:GetSet()
    for UnitID, UnitData in pairs( Set ) do -- For each UNIT in SET_UNIT
      -- local UnitData = UnitData -- Wrapper.Unit#UNIT
      UnitData:SetCargoBayWeightLimit()
    end
  end

end

do -- SET_STATIC
  
  ---
  -- @type SET_STATIC
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
  --    * @{#SET_STATIC.FilterPrefixes}: Builds the SET_STATIC with the units containing the same string(s) in their name. **Attention!** LUA regular expression apply here, so special characters in names like minus, dot, hash (#) etc might lead to unexpected results. 
  -- Have a read through here to understand the application of regular expressions: [LUA regular expressions](https://riptutorial.com/lua/example/20315/lua-pattern-matching)
  --    * @{#SET_STATIC.FilterZones}: Builds the SET_STATIC with the units within a @{Core.Zone#ZONE}.
  --    * @{#SET_STATIC.FilterFunction}: Builds the SET_STATIC with a custom condition.
  --    
  -- Once the filter criteria have been set for the SET_STATIC, you can start filtering using:
  --
  --   * @{#SET_STATIC.FilterStart}: Starts the filtering of the units within the SET_STATIC.
  --
  -- ## SET_STATIC iterators
  --
  -- Once the filters have been defined and the SET_STATIC has been built, you can iterate the SET_STATIC with the available iterator methods.
  -- The iterator methods will walk the SET_STATIC set, and call for each element within the set a function that you provide.
  -- The following iterator methods are currently available within the SET_STATIC:
  --
  --   * @{#SET_STATIC.ForEachStatic}: Calls a function for each alive unit it finds within the SET_STATIC.
  --   * @{#SET_STATIC.ForEachStaticCompletelyInZone}: Iterate the SET_STATIC and call an iterator function for each **alive** STATIC presence completely in a @{Core.Zone}, providing the STATIC and optional parameters to the called function.
  --   * @{#SET_STATIC.ForEachStaticInZone}: Iterate the SET_STATIC and call an iterator function for each **alive** STATIC presence completely in a @{Core.Zone}, providing the STATIC and optional parameters to the called function.
  --   * @{#SET_STATIC.ForEachStaticNotInZone}: Iterate the SET_STATIC and call an iterator function for each **alive** STATIC presence not in a @{Core.Zone}, providing the STATIC and optional parameters to the called function.
  --
  -- ## SET_STATIC atomic methods
  --
  -- Various methods exist for a SET_STATIC to perform actions or calculations and retrieve results from the SET_STATIC:
  --
  --   * @{#SET_STATIC.GetTypeNames}(): Retrieve the type names of the @{Wrapper.Static}s in the SET, delimited by a comma.
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
      Zones = nil,
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
  -- @param Wrapper.Static#STATIC AddStatic A single STATIC.
  -- @return #SET_STATIC self
  function SET_STATIC:AddStatic( AddStatic )
    --self:F2( AddStatic:GetName() )

    self:Add( AddStatic:GetName(), AddStatic )

    return self
  end

  --- Add STATIC(s) to SET_STATIC.
  -- @param #SET_STATIC self
  -- @param #string AddStaticNames A single name or an array of STATIC names.
  -- @return #SET_STATIC self
  function SET_STATIC:AddStaticsByName( AddStaticNames )

    local AddStaticNamesArray = (type( AddStaticNames ) == "table") and AddStaticNames or { AddStaticNames }

    --self:T(( AddStaticNamesArray )
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

    local RemoveStaticNamesArray = (type( RemoveStaticNames ) == "table") and RemoveStaticNames or { RemoveStaticNames }

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
  
  
   --- Builds a set of statics in zones.
  -- @param #SET_STATIC self
  -- @param #table Zones Table of Core.Zone#ZONE Zone objects, or a Core.Set#SET_ZONE
  -- @return #SET_STATIC self
  function SET_STATIC:FilterZones( Zones )
    if not self.Filter.Zones then
      self.Filter.Zones = {}
    end
    local zones = {}
    if Zones.ClassName and Zones.ClassName == "SET_ZONE" then
      zones = Zones.Set
    elseif type( Zones ) ~= "table" or (type( Zones ) == "table" and Zones.ClassName ) then
      self:E("***** FilterZones needs either a table of ZONE Objects or a SET_ZONE as parameter!")
      return self     
    else
      zones = Zones
    end
    for _,Zone in pairs( zones ) do
      local zonename = Zone:GetName()
      self.Filter.Zones[zonename] = Zone
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
  
  --- [User] Add a custom condition function.
  -- @function [parent=#SET_STATIC] FilterFunction
  -- @param #SET_STATIC self
  -- @param #function ConditionFunction If this function returns `true`, the object is added to the SET. The function needs to take a STATIC object as first argument.
  -- @param ... Condition function arguments if any.
  -- @return #SET_STATIC self
  -- @usage
  --          -- Image you want to exclude a specific CLIENT from a SET:
  --          local groundset = SET_STATIC:New():FilterCoalitions("blue"):FilterActive(true):FilterFunction(
  --          -- The function needs to take a STATIC object as first - and in this case, only - argument.
  --          function(static)
  --              local isinclude = true
  --              if static:GetName() == "Exclude Me" then isinclude = false end
  --              return isinclude
  --          end
  --          ):FilterOnce()
  --          BASE:I(groundset:Flush())
  
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

  --- Builds a set of STATICs that contain the given string in their name.
  -- **Attention!** Bad naming convention as this **does not** filter only **prefixes** but all statics that **contain** the string. 
  -- @param #SET_STATIC self
  -- @param #string Prefixes The string pattern(s) that need to be contained in the static name. Can also be passed as a `#table` of strings.
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
      self:HandleEvent( EVENTS.UnitLost, self._EventOnDeadOrCrash )
    end

    return self
  end

  --- Iterate the SET_STATIC and count how many STATICSs are alive.
  -- @param #SET_STATIC self
  -- @return #number The number of UNITs alive.
  function SET_STATIC:CountAlive()

    local Set = self:GetSet()

    local CountU = 0
    for UnitID, UnitData in pairs( Set ) do
      if UnitData and UnitData:IsAlive() then
        CountU = CountU + 1
      end

    end

    return CountU
  end

  --- Handles the Database to check on an event (birth) that the Object was added in the Database.
  -- This is required, because sometimes the _DATABASE birth event gets called later than the SET_BASE birth event!
  -- @param #SET_STATIC self
  -- @param Core.Event#EVENTDATA Event
  -- @return #string The name of the STATIC
  -- @return #table The STATIC
  function SET_STATIC:AddInDatabase( Event )
    --self:F3( { Event } )

    if Event.IniObjectCategory == Object.Category.STATIC then
      if not self.Database[Event.IniDCSUnitName] then
        self.Database[Event.IniDCSUnitName] = STATIC:Register( Event.IniDCSUnitName )
        --self:T(3( self.Database[Event.IniDCSUnitName] )
      end
    end

    return Event.IniDCSUnitName, self.Database[Event.IniDCSUnitName]
  end

  --- Handles the Database to check on any event that Object exists in the Database.
  -- This is required, because sometimes the _DATABASE event gets called later than the SET_BASE event or vise versa!
  -- @param #SET_STATIC self
  -- @param Core.Event#EVENTDATA Event
  -- @return #string The name of the STATIC
  -- @return #table The STATIC
  function SET_STATIC:FindInDatabase( Event )
    --self:F2( { Event.IniDCSUnitName, self.Set[Event.IniDCSUnitName], Event } )

    return Event.IniDCSUnitName, self.Set[Event.IniDCSUnitName]
  end

  do -- Is Zone methods

    --- Check if minimal one element of the SET_STATIC is in the Zone.
    -- @param #SET_STATIC self
    -- @param Core.Zone#ZONE Zone The Zone to be tested for.
    -- @return #boolean
    function SET_STATIC:IsPartiallyInZone( Zone )

      local IsPartiallyInZone = false

      local function EvaluateZone( ZoneStatic )

        local ZoneStaticName = ZoneStatic:GetName()
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
    -- @param Core.Zone#ZONE Zone The Zone to be tested for.
    -- @return #boolean
    function SET_STATIC:IsNotInZone( Zone )

      local IsNotInZone = true

      local function EvaluateZone( ZoneStatic )

        local ZoneStaticName = ZoneStatic:GetName()
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
      --self:F2( arg )

      self:ForEach( IteratorFunction, arg, self:GetSet() )

      return self
    end

  end


  --- Iterate the SET_STATIC and call an iterator function for each **alive** STATIC, providing the STATIC and optional parameters.
  -- @param #SET_STATIC self
  -- @param #function IteratorFunction The function that will be called when there is an alive STATIC in the SET_STATIC. The function needs to accept a STATIC parameter.
  -- @return #SET_STATIC self
  function SET_STATIC:ForEachStatic( IteratorFunction, ... )
    --self:F2( arg )

    self:ForEach( IteratorFunction, arg, self:GetSet() )

    return self
  end

  --- Iterate the SET_STATIC and call an iterator function for each **alive** STATIC presence completely in a @{Core.Zone}, providing the STATIC and optional parameters to the called function.
  -- @param #SET_STATIC self
  -- @param Core.Zone#ZONE ZoneObject The Zone to be tested for.
  -- @param #function IteratorFunction The function that will be called when there is an alive STATIC in the SET_STATIC. The function needs to accept a STATIC parameter.
  -- @return #SET_STATIC self
  function SET_STATIC:ForEachStaticCompletelyInZone( ZoneObject, IteratorFunction, ... )
    --self:F2( arg )

    self:ForEach( IteratorFunction, arg, self:GetSet(),
      -- @param Core.Zone#ZONE_BASE ZoneObject
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

  --- Iterate the SET_STATIC and call an iterator function for each **alive** STATIC presence not in a @{Core.Zone}, providing the STATIC and optional parameters to the called function.
  -- @param #SET_STATIC self
  -- @param Core.Zone#ZONE ZoneObject The Zone to be tested for.
  -- @param #function IteratorFunction The function that will be called when there is an alive STATIC in the SET_STATIC. The function needs to accept a STATIC parameter.
  -- @return #SET_STATIC self
  function SET_STATIC:ForEachStaticNotInZone( ZoneObject, IteratorFunction, ... )
    --self:F2( arg )

    self:ForEach( IteratorFunction, arg, self:GetSet(),
      -- @param Core.Zone#ZONE_BASE ZoneObject
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
    --self:F2()

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
      MT[#MT + 1] = StaticType .. " of " .. StaticTypeID
    end

    return StaticTypes
  end

  --- Returns a comma separated string of the unit types with a count in the  @{Core.Set}.
  -- @param #SET_STATIC self
  -- @return #string The unit types string
  function SET_STATIC:GetStaticTypesText()
    --self:F2()

    local MT = {} -- Message Text
    local StaticTypes = self:GetStaticTypes()

    for StaticTypeID, StaticType in pairs( StaticTypes ) do
      MT[#MT + 1] = StaticType .. " of " .. StaticTypeID
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

      x1 = (Coordinate.x < x1) and Coordinate.x or x1
      x2 = (Coordinate.x > x2) and Coordinate.x or x2
      y1 = (Coordinate.y < y1) and Coordinate.y or y1
      y2 = (Coordinate.y > y2) and Coordinate.y or y2
      z1 = (Coordinate.y < z1) and Coordinate.z or z1
      z2 = (Coordinate.y > z2) and Coordinate.z or z2

      local Velocity = Coordinate:GetVelocity()
      if Velocity ~= 0 then
        MaxVelocity = (MaxVelocity < Velocity) and Velocity or MaxVelocity
        local Heading = Coordinate:GetHeading()
        AvgHeading = AvgHeading and (AvgHeading + Heading) or Heading
        MovingCount = MovingCount + 1
      end
    end

    AvgHeading = AvgHeading and (AvgHeading / MovingCount)

    Coordinate.x = (x2 - x1) / 2 + x1
    Coordinate.y = (y2 - y1) / 2 + y1
    Coordinate.z = (z2 - z1) / 2 + z1
    Coordinate:SetHeading( AvgHeading )
    Coordinate:SetVelocity( MaxVelocity )

    --self:F( { Coordinate = Coordinate } )
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
      if Velocity ~= 0 then
        local Heading = Coordinate:GetHeading()
        if HeadingSet == nil then
          HeadingSet = Heading
        else
          local HeadingDiff = (HeadingSet - Heading + 180 + 360) % 360 - 180
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

  --- Calculate the maximum A2G threat level of the SET_STATIC.
  -- @param #SET_STATIC self
  -- @return #number The maximum threatlevel
  function SET_STATIC:CalculateThreatLevelA2G()

    local MaxThreatLevelA2G = 0
    local MaxThreatText = ""
    for StaticName, StaticData in pairs( self:GetSet() ) do
      local ThreatStatic = StaticData -- Wrapper.Static#STATIC
      local ThreatLevelA2G, ThreatText = ThreatStatic:GetThreatLevel()
      if ThreatLevelA2G > MaxThreatLevelA2G then
        MaxThreatLevelA2G = ThreatLevelA2G
        MaxThreatText = ThreatText
      end
    end

    --self:F( { MaxThreatLevelA2G = MaxThreatLevelA2G, MaxThreatText = MaxThreatText } )
    return MaxThreatLevelA2G, MaxThreatText

  end

  ---
  -- @param #SET_STATIC self
  -- @param Wrapper.Static#STATIC MStatic
  -- @return #SET_STATIC self
  function SET_STATIC:IsIncludeObject( MStatic )
    --self:F2( MStatic )
    local MStaticInclude = true

    if self.Filter.Coalitions then
      local MStaticCoalition = false
      for CoalitionID, CoalitionName in pairs( self.Filter.Coalitions ) do
        --self:T(3( { "Coalition:", MStatic:GetCoalition(), self.FilterMeta.Coalitions[CoalitionName], CoalitionName } )
        if self.FilterMeta.Coalitions[CoalitionName] and self.FilterMeta.Coalitions[CoalitionName] == MStatic:GetCoalition() then
          MStaticCoalition = true
        end
      end
      MStaticInclude = MStaticInclude and MStaticCoalition
    end

    if self.Filter.Categories then
      local MStaticCategory = false
      for CategoryID, CategoryName in pairs( self.Filter.Categories ) do
        --self:T(3( { "Category:", MStatic:GetDesc().category, self.FilterMeta.Categories[CategoryName], CategoryName } )
        if self.FilterMeta.Categories[CategoryName] and self.FilterMeta.Categories[CategoryName] == MStatic:GetDesc().category then
          MStaticCategory = true
        end
      end
      MStaticInclude = MStaticInclude and MStaticCategory
    end

    if self.Filter.Types then
      local MStaticType = false
      for TypeID, TypeName in pairs( self.Filter.Types ) do
        --self:T(3( { "Type:", MStatic:GetTypeName(), TypeName } )
        if TypeName == MStatic:GetTypeName() then
          MStaticType = true
        end
      end
      MStaticInclude = MStaticInclude and MStaticType
    end

    if self.Filter.Countries then
      local MStaticCountry = false
      for CountryID, CountryName in pairs( self.Filter.Countries ) do
        --self:T(3( { "Country:", MStatic:GetCountry(), CountryName } )
        if country.id[CountryName] == MStatic:GetCountry() then
          MStaticCountry = true
        end
      end
      MStaticInclude = MStaticInclude and MStaticCountry
    end

    if self.Filter.StaticPrefixes then
      local MStaticPrefix = false
      for StaticPrefixId, StaticPrefix in pairs( self.Filter.StaticPrefixes ) do
        --self:T(3( { "Prefix:", string.find( MStatic:GetName(), StaticPrefix, 1 ), StaticPrefix } )
        if string.find( MStatic:GetName(), StaticPrefix, 1 ) then
          MStaticPrefix = true
        end
      end
      MStaticInclude = MStaticInclude and MStaticPrefix
    end
    
    if self.Filter.Zones then
      local MStaticZone = false
      for ZoneName, Zone in pairs( self.Filter.Zones ) do
        --self:T(3( "Zone:", ZoneName )
        if MStatic and MStatic:IsInZone(Zone) then
          MStaticZone = true
        end
      end
      MStaticInclude = MStaticInclude and MStaticZone
    end
    
    if self.Filter.Functions and MStaticInclude then
      local MClientFunc = self:_EvalFilterFunctions(MStatic)
      MStaticInclude = MStaticInclude and MClientFunc
    end
    
    --self:T(2( MStaticInclude )
    return MStaticInclude
  end

  --- Retrieve the type names of the @{Wrapper.Static}s in the SET, delimited by an optional delimiter.
  -- @param #SET_STATIC self
  -- @param #string Delimiter (Optional) The delimiter, which is default a comma.
  -- @return #string The types of the @{Wrapper.Static}s delimited.
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

  --- Get the closest static of the set with respect to a given reference coordinate. Optionally, only statics of given coalitions are considered in the search.
  -- @param #SET_STATIC self
  -- @param Core.Point#COORDINATE Coordinate Reference Coordinate from which the closest static is determined.
  -- @return Wrapper.Static#STATIC The closest static (if any).
  -- @return #number Distance in meters to the closest static.
  function SET_STATIC:GetClosestStatic(Coordinate, Coalitions)
  
    local Set = self:GetSet()
    
    local dmin=math.huge
    local gmin=nil
    
    for GroupID, GroupData in pairs( Set ) do -- For each STATIC in SET_STATIC
      local group=GroupData --Wrapper.Static#STATIC
      
      if group and group:IsAlive() and (Coalitions==nil or UTILS.IsAnyInTable(Coalitions, group:GetCoalition())) then
      
        local coord=group:GetCoord()
        
        -- Distance between ref. coordinate and group coordinate.
        local d=UTILS.VecDist3D(Coordinate, coord)
      
        if d<dmin then
          dmin=d
          gmin=group
        end
        
      end
    
    end
    
    return gmin, dmin
  end

end

do -- SET_CLIENT
  
  ---
  -- @type SET_CLIENT
  -- @field Core.Timer#TIMER ZoneTimer
  -- @field #number ZoneTimerInterval
  -- @extends Core.Set#SET_BASE

  --- Mission designers can use the @{Core.Set#SET_CLIENT} class to build sets of units belonging to certain:
  --
  --  * Coalitions
  --  * Categories
  --  * Countries
  --  * Client types
  --  * Starting with certain prefix strings.
  --
  -- ## 1) SET_CLIENT constructor
  --
  -- Create a new SET_CLIENT object with the @{#SET_CLIENT.New} method:
  --
  --    * @{#SET_CLIENT.New}: Creates a new SET_CLIENT object.
  --
  -- ## 2) Add or Remove CLIENT(s) from SET_CLIENT
  --
  -- CLIENTs can be added and removed using the @{Core.Set#SET_CLIENT.AddClientsByName} and @{Core.Set#SET_CLIENT.RemoveClientsByName} respectively.
  -- These methods take a single CLIENT name or an array of CLIENT names to be added or removed from SET_CLIENT.
  --
  -- ## 3) SET_CLIENT filter criteria
  --
  -- You can set filter criteria to define the set of clients within the SET_CLIENT.
  -- Filter criteria are defined by:
  --
  --    * @{#SET_CLIENT.FilterCoalitions}: Builds the SET_CLIENT with the clients belonging to the coalition(s).
  --    * @{#SET_CLIENT.FilterCategories}: Builds the SET_CLIENT with the clients belonging to the category(ies).
  --    * @{#SET_CLIENT.FilterTypes}: Builds the SET_CLIENT with the clients belonging to the client type(s).
  --    * @{#SET_CLIENT.FilterCountries}: Builds the SET_CLIENT with the clients belonging to the country(ies).
  --    * @{#SET_CLIENT.FilterPrefixes}: Builds the SET_CLIENT with the clients containing the same string(s) in their unit/pilot name. **Attention!** LUA regular expression apply here, so special characters in names like minus, dot, hash (#) etc might lead to unexpected results. 
  -- Have a read through here to understand the application of regular expressions: [LUA regular expressions](https://riptutorial.com/lua/example/20315/lua-pattern-matching)
  --    * @{#SET_CLIENT.FilterActive}: Builds the SET_CLIENT with the units that are only active. Units that are inactive (late activation) won't be included in the set!
  --    * @{#SET_CLIENT.FilterZones}: Builds the SET_CLIENT with the clients within a @{Core.Zone#ZONE}.
  --    * @{#SET_CLIENT.FilterFunction}: Builds the SET_CLIENT with a custom condition.
  --    
  -- Once the filter criteria have been set for the SET_CLIENT, you can start filtering using:
  --
  --   * @{#SET_CLIENT.FilterStart}: Starts the filtering of the clients **dynamically**.
  --   * @{#SET_CLIENT.FilterOnce}: Filters the clients **once**.
  --
  -- ## 4) SET_CLIENT iterators
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
      Zones = nil,
      Playernames = nil,
      Callsigns = nil,
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
    local self = BASE:Inherit( self, SET_BASE:New( _DATABASE.CLIENTS ) ) -- #SET_CLIENT

    self:FilterActive( false )

    return self
  end

  --- Add CLIENT(s) to SET_CLIENT.
  -- @param Core.Set#SET_CLIENT self
  -- @param #string AddClientNames A single name or an array of CLIENT names.
  -- @return self
  function SET_CLIENT:AddClientsByName( AddClientNames )

    local AddClientNamesArray = (type( AddClientNames ) == "table") and AddClientNames or { AddClientNames }

    for AddClientID, AddClientName in pairs( AddClientNamesArray ) do
      self:Add( AddClientName, CLIENT:FindByName( AddClientName ) )
    end

    return self
  end

  --- Remove CLIENT(s) from SET_CLIENT.
  -- @param Core.Set#SET_CLIENT self
  -- @param Wrapper.Client#CLIENT RemoveClientNames A single object or an array of CLIENT objects.
  -- @return self
  function SET_CLIENT:RemoveClientsByName( RemoveClientNames )

    local RemoveClientNamesArray = (type( RemoveClientNames ) == "table") and RemoveClientNames or { RemoveClientNames }

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

  --- Builds a set of clients of certain callsigns.
  -- @param #SET_CLIENT self
  -- @param #string Callsigns Can be a single string e.g. "Ford", or a table of strings e.g. {"Uzi","Enfield","Chevy"}. Refers to the callsigns as they can be set in the mission editor.
  -- @return #SET_CLIENT self
  function SET_CLIENT:FilterCallsigns( Callsigns )
    if not self.Filter.Callsigns then
      self.Filter.Callsigns = {}
    end
    if type( Callsigns ) ~= "table" then
      Callsigns = { Callsigns }
    end
    for callsignID, callsign in pairs( Callsigns ) do
      self.Filter.Callsigns[callsign] = callsign
    end
    return self
  end

  --- Builds a set of clients of certain playernames.
  -- @param #SET_CLIENT self
  -- @param #string Playernames Can be a single string e.g. "Apple", or a table of strings e.g. {"Walter","Hermann","Gonzo"}. Useful if you have e.g. a common squadron prefix.
  -- @return #SET_CLIENT self
  function SET_CLIENT:FilterPlayernames( Playernames )
    if not self.Filter.Playernames then
      self.Filter.Playernames = {}
    end
    if type( Playernames ) ~= "table" then
      Playernames = { Playernames }
    end
    for PlayernameID, playername in pairs( Playernames ) do
      self.Filter.Playernames[playername] = playername
    end
    return self
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

  --- Builds a set of CLIENTs that contain the given string in their **unit/pilot** name and **NOT** the group name!
  -- **Attention!** Bad naming convention as this **does not** filter only **prefixes** but all clients that **contain** the string. Pattern matching applies.
  -- @param #SET_CLIENT self
  -- @param #string Prefixes The string pattern(s) that needs to be contained in the unit/pilot name. Can also be passed as a `#table` of strings.
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

  --- Builds a set of clients that are only active.
  -- Only the clients that are active will be included within the set.
  -- @param #SET_CLIENT self
  -- @param #boolean Active (Optional) Include only active clients to the set.
  -- Include inactive clients if you provide false.
  -- @return #SET_CLIENT self
  -- @usage
  --
  -- -- Include only active clients to the set.
  -- ClientSet = SET_CLIENT:New():FilterActive():FilterStart()
  --
  -- -- Include only active clients to the set of the blue coalition, and filter one time.
  -- ClientSet = SET_CLIENT:New():FilterActive():FilterCoalition( "blue" ):FilterOnce()
  --
  -- -- Include only active clients to the set of the blue coalition, and filter one time.
  -- -- Later, reset to include back inactive clients to the set.
  -- ClientSet = SET_CLIENT:New():FilterActive():FilterCoalition( "blue" ):FilterOnce()
  -- ... logic ...
  -- ClientSet = SET_CLIENT:New():FilterActive( false ):FilterCoalition( "blue" ):FilterOnce()
  --
  function SET_CLIENT:FilterActive( Active )
    Active = Active or not (Active == false)
    self.Filter.Active = Active
    return self
  end

  --- Builds a set of units which exist and are alive.
  -- @param #SET_CLIENT self
  -- @return #SET_CLIENT self
  function SET_CLIENT:FilterAlive()
    self:FilterFunction(
      function(unit)
        if unit and unit:IsExist() and unit:IsAlive() then
          return true
        else
          return false
        end
      end
    )
    return self
  end


   --- Builds a set of clients in zones.
  -- @param #SET_CLIENT self
  -- @param #table Zones Table of Core.Zone#ZONE Zone objects, or a Core.Set#SET_ZONE
  -- @return #SET_CLIENT self
  function SET_CLIENT:FilterZones( Zones )
    if not self.Filter.Zones then
      self.Filter.Zones = {}
    end
    local zones = {}
    if Zones.ClassName and Zones.ClassName == "SET_ZONE" then
      zones = Zones.Set
    elseif type( Zones ) ~= "table" or (type( Zones ) == "table" and Zones.ClassName ) then
      self:E("***** FilterZones needs either a table of ZONE Objects or a SET_ZONE as parameter!")
      return self     
    else
      zones = Zones
    end
    for _,Zone in pairs( zones ) do
      local zonename = Zone:GetName()
      self.Filter.Zones[zonename] = Zone
    end
    return self
  end

  --- [Internal] Private function for use of continous zone filter
  -- @param #SET_CLIENT self
  -- @return #SET_CLIENT self
  function SET_CLIENT:_ContinousZoneFilter()
    
    local Database = _DATABASE.CLIENTS
    
    for ObjectName, Object in pairs( Database ) do
      if self:IsIncludeObject( Object ) and self:IsNotInSet(Object) then
        self:Add( ObjectName, Object )
      elseif (not self:IsIncludeObject( Object )) and self:IsInSet(Object) then
        self:Remove(ObjectName)
      end
    end
    
    return self
    
  end

  --- Set filter timer interval for FilterZones if using active filtering with FilterStart().
  -- @param #SET_CLIENT self
  -- @param #number Seconds Seconds between check intervals, defaults to 30. **Caution** - do not be too agressive with timing! Groups are usually not moving fast enough
  -- to warrant a check of below 10 seconds.
  -- @return #SET_CLIENT self
  function SET_CLIENT:FilterZoneTimer(Seconds)
    self.ZoneTimerInterval = Seconds or 30
    return self
  end
  
  --- Stops the filtering.
  -- @param #SET_CLIENT self
  -- @return #SET_CLIENT self
  function SET_CLIENT:FilterStop()

    if _DATABASE then
      
      self:UnHandleEvent(EVENTS.Birth)
      self:UnHandleEvent(EVENTS.Dead)
      self:UnHandleEvent(EVENTS.Crash)
      --self:UnHandleEvent(EVENTS.PlayerEnterUnit)
      self:UnHandleEvent(EVENTS.PlayerLeaveUnit)
      
      if self.Filter.Zones and self.ZoneTimer and self.ZoneTimer:IsRunning() then
        self.ZoneTimer:Stop()
      end
    end

    return self
  end

  --- Starts the filtering.
  -- @param #SET_CLIENT self
  -- @return #SET_CLIENT self
  function SET_CLIENT:FilterStart()

    if _DATABASE then
      self:HandleEvent( EVENTS.Birth, self._EventOnBirth )
      self:HandleEvent( EVENTS.Dead, self._EventOnDeadOrCrash )
      self:HandleEvent( EVENTS.Crash, self._EventOnDeadOrCrash )
      --self:HandleEvent( EVENTS.PlayerEnterUnit, self._EventPlayerEnterUnit)
      self:HandleEvent( EVENTS.PlayerLeaveUnit, self._EventPlayerLeaveUnit)
      --self:SetEventPriority(1)
      if self.Filter.Zones then
        self.ZoneTimer = TIMER:New(self._ContinousZoneFilter,self)
        local timing = self.ZoneTimerInterval or 30
        self.ZoneTimer:Start(timing,timing)
      end
      self:_FilterStart()
    end

    return self
  end
  
  --- Handle CA slots addition
  -- @param #SET_CLIENT self
  -- @param Core.Event#EVENTDATA Event
  -- @return #SET_CLIENT self
  function SET_CLIENT:_EventPlayerEnterUnit(Event)
    --self:I( "_EventPlayerEnterUnit" )
    if Event.IniDCSUnit then
      if Event.IniObjectCategory == Object.Category.UNIT and Event.IniGroup and Event.IniGroup:IsGround() then
        -- CA Slot entered
        local ObjectName, Object = self:AddInDatabase( Event )
        --self:T(( ObjectName, UTILS.PrintTableToLog(Object) )
        if Object and self:IsIncludeObject( Object ) then
          self:Add( ObjectName, Object )
        end
      end
    end
    return self
  end
  
  --- Handle CA slots removal
  -- @param #SET_CLIENT self
  -- @param Core.Event#EVENTDATA Event
  -- @return #SET_CLIENT self
  function SET_CLIENT:_EventPlayerLeaveUnit(Event)
    --self:I( "_EventPlayerLeaveUnit" )
    if Event.IniDCSUnit then
      if Event.IniObjectCategory == Object.Category.UNIT and Event.IniGroup then --and Event.IniGroup:IsGround() then
        -- CA Slot left
        local ObjectName, Object = self:FindInDatabase( Event )
        if ObjectName then
          self:Remove( ObjectName )
        end
      end
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
    --self:F3( { Event } )

    return Event.IniDCSUnitName, self.Database[Event.IniDCSUnitName]
  end

  --- Handles the Database to check on any event that Object exists in the Database.
  -- This is required, because sometimes the _DATABASE event gets called later than the SET_BASE event or vise versa!
  -- @param #SET_CLIENT self
  -- @param Core.Event#EVENTDATA Event
  -- @return #string The name of the CLIENT
  -- @return #table The CLIENT
  function SET_CLIENT:FindInDatabase( Event )
    --self:F3( { Event } )

    return Event.IniDCSUnitName, self.Database[Event.IniDCSUnitName]
  end

  --- Iterate the SET_CLIENT and call an iterator function for each **alive** CLIENT, providing the CLIENT and optional parameters.
  -- @param #SET_CLIENT self
  -- @param #function IteratorFunction The function that will be called when there is an alive CLIENT in the SET_CLIENT. The function needs to accept a CLIENT parameter.
  -- @return #SET_CLIENT self
  function SET_CLIENT:ForEachClient( IteratorFunction, ... )
    --self:F2( arg )

    self:ForEach( IteratorFunction, arg, self:GetSet() )

    return self
  end

  --- Iterate the SET_CLIENT and call an iterator function for each **alive** CLIENT presence completely in a @{Core.Zone}, providing the CLIENT and optional parameters to the called function.
  -- @param #SET_CLIENT self
  -- @param Core.Zone#ZONE ZoneObject The Zone to be tested for.
  -- @param #function IteratorFunction The function that will be called when there is an alive CLIENT in the SET_CLIENT. The function needs to accept a CLIENT parameter.
  -- @return #SET_CLIENT self
  function SET_CLIENT:ForEachClientInZone( ZoneObject, IteratorFunction, ... )
    --self:F2( arg )

    self:ForEach( IteratorFunction, arg, self:GetSet(),
      -- @param Core.Zone#ZONE_BASE ZoneObject
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

  --- Iterate the SET_CLIENT and call an iterator function for each **alive** CLIENT presence not in a @{Core.Zone}, providing the CLIENT and optional parameters to the called function.
  -- @param #SET_CLIENT self
  -- @param Core.Zone#ZONE ZoneObject The Zone to be tested for.
  -- @param #function IteratorFunction The function that will be called when there is an alive CLIENT in the SET_CLIENT. The function needs to accept a CLIENT parameter.
  -- @return #SET_CLIENT self
  function SET_CLIENT:ForEachClientNotInZone( ZoneObject, IteratorFunction, ... )
    --self:F2( arg )

    self:ForEach( IteratorFunction, arg, self:GetSet(),
      -- @param Core.Zone#ZONE_BASE ZoneObject
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

  --- Iterate the SET_CLIENT and count alive units.
  -- @param #SET_CLIENT self
  -- @return #number count
  function SET_CLIENT:CountAlive()

    local Set = self:GetSet()

    local CountU = 0
    for UnitID, UnitData in pairs( Set ) do -- For each GROUP in SET_GROUP
      if UnitData and UnitData:IsAlive() then
        CountU = CountU + 1
      end

    end

    return CountU
  end
  
  
  --- Gets the alive set.
  -- @param #SET_CLIENT self
  -- @return #table Table of SET objects
  function SET_CLIENT:GetAliveSet()

    local AliveSet = SET_CLIENT:New()

    -- Clean the Set before returning with only the alive Groups.
    for GroupName, GroupObject in pairs(self.Set) do    
      local GroupObject=GroupObject --Wrapper.Client#CLIENT
      
      if GroupObject and GroupObject:IsAlive() then      
        AliveSet:Add(GroupName, GroupObject)
      end
    end

    return AliveSet.Set or {}
  end

  --- [User] Add a custom condition function.
  -- @function [parent=#SET_CLIENT] FilterFunction
  -- @param #SET_CLIENT self
  -- @param #function ConditionFunction If this function returns `true`, the object is added to the SET. The function needs to take a CLIENT object as first argument.
  -- @param ... Condition function arguments if any.
  -- @return #SET_CLIENT self
  -- @usage
  --          -- Image you want to exclude a specific CLIENT from a SET:
  --          local groundset = SET_CLIENT:New():FilterCoalitions("blue"):FilterActive(true):FilterFunction(
  --          -- The function needs to take a UNIT object as first - and in this case, only - argument.
  --          function(client)
  --              local isinclude = true
  --              if client:GetPlayerName() == "Exclude Me" then isinclude = false end
  --              return isinclude
  --          end
  --          ):FilterOnce()
  --          BASE:I(groundset:Flush())


  ---
  -- @param #SET_CLIENT self
  -- @param Wrapper.Client#CLIENT MClient
  -- @return #SET_CLIENT self
  function SET_CLIENT:IsIncludeObject( MClient )
    --self:F2( MClient )

    local MClientInclude = true

    if MClient then
      local MClientName = MClient.UnitName

      if self.Filter.Active ~= nil then
        local MClientActive = false
        if self.Filter.Active == false or (self.Filter.Active == true and MClient:IsActive() == true and MClient:IsAlive() == true) then
          MClientActive = true
        end
        --self:T( { "Evaluated Active", MClientActive } )
        MClientInclude = MClientInclude and MClientActive
      end

      if self.Filter.Coalitions and MClientInclude then
        local MClientCoalition = false
        for CoalitionID, CoalitionName in pairs( self.Filter.Coalitions ) do
          local ClientCoalitionID = _DATABASE:GetCoalitionFromClientTemplate( MClientName )
          if ClientCoalitionID==nil and MClient:IsAlive()~=nil then
            ClientCoalitionID=MClient:GetCoalition()
          end
          --self:T3( { "Coalition:", ClientCoalitionID, self.FilterMeta.Coalitions[CoalitionName], CoalitionName } )
          if self.FilterMeta.Coalitions[CoalitionName] and ClientCoalitionID and self.FilterMeta.Coalitions[CoalitionName] == ClientCoalitionID then
            MClientCoalition = true
          end
        end
        --self:T( { "Evaluated Coalition", MClientCoalition } )
        MClientInclude = MClientInclude and MClientCoalition
      end
      
      if self.Filter.Categories and MClientInclude then
        local MClientCategory = false
        for CategoryID, CategoryName in pairs( self.Filter.Categories ) do
          local ClientCategoryID = _DATABASE:GetCategoryFromClientTemplate( MClientName )
          local UnitCategory = 0
          if ClientCategoryID==nil and MClient:IsExist() then
            ClientCategoryID,UnitCategory=MClient:GetCategory()
            --self:T3("Applying Category Workaround .. Outcome: Obj is "..tostring(ClientCategoryID).." Unit is "..tostring(UnitCategory))
            --self:T(3( { "Category:", UnitCategory, self.FilterMeta.Categories[CategoryName], CategoryName } )
            if self.FilterMeta.Categories[CategoryName] and UnitCategory and self.FilterMeta.Categories[CategoryName] == UnitCategory then
              MClientCategory = true
            end
            --self:T3("Filter Outcome is "..tostring(MClientCategory))
          else
            --self:T3( { "Category:", ClientCategoryID, self.FilterMeta.Categories[CategoryName], CategoryName } )
            if self.FilterMeta.Categories[CategoryName] and ClientCategoryID and self.FilterMeta.Categories[CategoryName] == ClientCategoryID then
              MClientCategory = true
            end
          end
        end
        --self:T( { "Evaluated Category", MClientCategory } )
        MClientInclude = MClientInclude and MClientCategory
      end

      if self.Filter.Types and MClientInclude then
        local MClientType = false
        for TypeID, TypeName in pairs( self.Filter.Types ) do
          --self:T3( { "Type:", MClient:GetTypeName(), TypeName } )
          if TypeName == MClient:GetTypeName() then
            MClientType = true
          end
        end
        --self:T(( { "Evaluated Type", MClientType } )
        MClientInclude = MClientInclude and MClientType
      end

      if self.Filter.Countries and MClientInclude then
        local MClientCountry = false
        for CountryID, CountryName in pairs( self.Filter.Countries ) do
          local ClientCountryID = _DATABASE:GetCountryFromClientTemplate( MClientName )
          if ClientCountryID==nil and MClient:IsAlive()~=nil then
            ClientCountryID=MClient:GetCountry()
          end
          --self:T(3( { "Country:", ClientCountryID, country.id[CountryName], CountryName } )
          if country.id[CountryName] and ClientCountryID and country.id[CountryName] == ClientCountryID then
            MClientCountry = true
          end
        end
        --self:T(( { "Evaluated Country", MClientCountry } )
        MClientInclude = MClientInclude and MClientCountry
      end

      if self.Filter.ClientPrefixes and MClientInclude then
        local MClientPrefix = false
        for ClientPrefixId, ClientPrefix in pairs( self.Filter.ClientPrefixes ) do
          --self:T3( { "Prefix:", string.find( MClient.UnitName, ClientPrefix, 1 ), ClientPrefix } )
          if string.find( MClient.UnitName, ClientPrefix, 1 ) then
            MClientPrefix = true
          end
        end
        --self:T( { "Evaluated Prefix", MClientPrefix } )
        MClientInclude = MClientInclude and MClientPrefix
      end

    if self.Filter.Zones and MClientInclude then
      local MClientZone = false
      for ZoneName, Zone in pairs( self.Filter.Zones ) do
      --self:T3( "Zone:", ZoneName )
      local unit = MClient:GetClientGroupUnit()
      if unit and unit:IsInZone(Zone) then
        MClientZone = true
      end
      end
      MClientInclude = MClientInclude and MClientZone
    end
    
    if self.Filter.Playernames and MClientInclude then
      local MClientPlayername = false
      local playername = MClient:GetPlayerName() or "Unknown"
      --self:T(playername)
      for _,_Playername in pairs(self.Filter.Playernames) do
        if playername and string.find(playername,_Playername) then
          MClientPlayername = true
        end
      end
      --self:T( { "Evaluated Playername", MClientPlayername } )
      MClientInclude = MClientInclude and MClientPlayername
    end
    
    if self.Filter.Callsigns and MClientInclude then
      local MClientCallsigns = false
      local callsign = MClient:GetCallsign()
      --self:I(callsign)
      for _,_Callsign in pairs(self.Filter.Callsigns) do
        if callsign and string.find(callsign,_Callsign,1,true) then
          MClientCallsigns = true
        end
      end
      --self:T( { "Evaluated Callsign", MClientCallsigns } )
      MClientInclude = MClientInclude and MClientCallsigns
    end
    
    if self.Filter.Functions and MClientInclude then
      local MClientFunc = self:_EvalFilterFunctions(MClient)
      MClientInclude = MClientInclude and MClientFunc
    end
    
  end
    --self:T2( MClientInclude )
    return MClientInclude
  end

end

do -- SET_PLAYER

  ---
  -- @type SET_PLAYER
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
  --    * @{#SET_PLAYER.FilterPrefixes}: Builds the SET_PLAYER with the clients sharing the same string(s) in their unit/pilot name. **Attention!** LUA regular expression apply here, so special characters in names like minus, dot, hash (#) etc might lead to unexpected results. 
  -- Have a read through here to understand the application of regular expressions: [LUA regular expressions](https://riptutorial.com/lua/example/20315/lua-pattern-matching)
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
      Zones = nil,
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

    local AddClientNamesArray = (type( AddClientNames ) == "table") and AddClientNames or { AddClientNames }

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

    local RemoveClientNamesArray = (type( RemoveClientNames ) == "table") and RemoveClientNames or { RemoveClientNames }

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
  
  --- Builds a set of players in zones.
  -- @param #SET_PLAYER self
  -- @param #table Zones Table of Core.Zone#ZONE Zone objects, or a Core.Set#SET_ZONE
  -- @return #SET_PLAYER self
  function SET_PLAYER:FilterZones( Zones )
    if not self.Filter.Zones then
      self.Filter.Zones = {}
    end
    local zones = {}
    if Zones.ClassName and Zones.ClassName == "SET_ZONE" then
      zones = Zones.Set
    elseif type( Zones ) ~= "table" or (type( Zones ) == "table" and Zones.ClassName ) then
      self:E("***** FilterZones needs either a table of ZONE Objects or a SET_ZONE as parameter!")
      return self     
    else
      zones = Zones
    end
    for _,Zone in pairs( zones ) do
      local zonename = Zone:GetName()
      self.Filter.Zones[zonename] = Zone
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

  --- Builds a set of PLAYERs that contain the given string in their unit/pilot name.
  -- **Attention!** Bad naming convention as this **does not** filter only **prefixes** but all player clients that **contain** the string. 
  -- @param #SET_PLAYER self
  -- @param #string Prefixes The string pattern(s) that needs to be contained in the unit/pilot name. Can also be passed as a `#table` of strings.
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
      self:HandleEvent( EVENTS.PlayerLeaveUnit, self._EventOnDeadOrCrash )
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
    --self:F3( { Event } )

    return Event.IniDCSUnitName, self.Database[Event.IniDCSUnitName]
  end

  --- Handles the Database to check on any event that Object exists in the Database.
  -- This is required, because sometimes the _DATABASE event gets called later than the SET_BASE event or vise versa!
  -- @param #SET_PLAYER self
  -- @param Core.Event#EVENTDATA Event
  -- @return #string The name of the CLIENT
  -- @return #table The CLIENT
  function SET_PLAYER:FindInDatabase( Event )
    --self:F3( { Event } )

    return Event.IniDCSUnitName, self.Database[Event.IniDCSUnitName]
  end

  --- Iterate the SET_PLAYER and call an iterator function for each **alive** CLIENT, providing the CLIENT and optional parameters.
  -- @param #SET_PLAYER self
  -- @param #function IteratorFunction The function that will be called when there is an alive CLIENT in the SET_PLAYER. The function needs to accept a CLIENT parameter.
  -- @return #SET_PLAYER self
  function SET_PLAYER:ForEachPlayer( IteratorFunction, ... )
    --self:F2( arg )

    self:ForEach( IteratorFunction, arg, self:GetSet() )

    return self
  end

  --- Iterate the SET_PLAYER and call an iterator function for each **alive** CLIENT presence completely in a @{Core.Zone}, providing the CLIENT and optional parameters to the called function.
  -- @param #SET_PLAYER self
  -- @param Core.Zone#ZONE ZoneObject The Zone to be tested for.
  -- @param #function IteratorFunction The function that will be called when there is an alive CLIENT in the SET_PLAYER. The function needs to accept a CLIENT parameter.
  -- @return #SET_PLAYER self
  function SET_PLAYER:ForEachPlayerInZone( ZoneObject, IteratorFunction, ... )
    --self:F2( arg )

    self:ForEach( IteratorFunction, arg, self:GetSet(),
      -- @param Core.Zone#ZONE_BASE ZoneObject
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

  --- Iterate the SET_PLAYER and call an iterator function for each **alive** CLIENT presence not in a @{Core.Zone}, providing the CLIENT and optional parameters to the called function.
  -- @param #SET_PLAYER self
  -- @param Core.Zone#ZONE ZoneObject The Zone to be tested for.
  -- @param #function IteratorFunction The function that will be called when there is an alive CLIENT in the SET_PLAYER. The function needs to accept a CLIENT parameter.
  -- @return #SET_PLAYER self
  function SET_PLAYER:ForEachPlayerNotInZone( ZoneObject, IteratorFunction, ... )
    --self:F2( arg )

    self:ForEach( IteratorFunction, arg, self:GetSet(),
      -- @param Core.Zone#ZONE_BASE ZoneObject
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
    --self:F2( MClient )

    local MClientInclude = true

    if MClient then
      local MClientName = MClient.UnitName

      if self.Filter.Coalitions and MClientInclude then
        local MClientCoalition = false
        for CoalitionID, CoalitionName in pairs( self.Filter.Coalitions ) do
          local ClientCoalitionID = _DATABASE:GetCoalitionFromClientTemplate( MClientName )
          if ClientCoalitionID==nil and MClient:IsAlive()~=nil then
            ClientCoalitionID=MClient:GetCoalition()
          end
          --self:T(3( { "Coalition:", ClientCoalitionID, self.FilterMeta.Coalitions[CoalitionName], CoalitionName } )
          if self.FilterMeta.Coalitions[CoalitionName] and ClientCoalitionID and self.FilterMeta.Coalitions[CoalitionName] == ClientCoalitionID then
            MClientCoalition = true
          end
        end
        --self:T(( { "Evaluated Coalition", MClientCoalition } )
        MClientInclude = MClientInclude and MClientCoalition
      end

      if self.Filter.Categories and MClientInclude then
        local MClientCategory = false
        for CategoryID, CategoryName in pairs( self.Filter.Categories ) do
          local ClientCategoryID = _DATABASE:GetCategoryFromClientTemplate( MClientName )
          local UnitCategory = 0
          if ClientCategoryID==nil and MClient:IsExist() then
            ClientCategoryID,UnitCategory=MClient:GetCategory()
            --self:T(3( { "Category:", UnitCategory, self.FilterMeta.Categories[CategoryName], CategoryName } )
            if self.FilterMeta.Categories[CategoryName] and UnitCategory and self.FilterMeta.Categories[CategoryName] == UnitCategory then
              MClientCategory = true
            end
          else
            --self:T(3( { "Category:", ClientCategoryID, self.FilterMeta.Categories[CategoryName], CategoryName } )
            if self.FilterMeta.Categories[CategoryName] and ClientCategoryID and self.FilterMeta.Categories[CategoryName] == ClientCategoryID then
              MClientCategory = true
            end
          end
        end
        --self:T(( { "Evaluated Category", MClientCategory } )
        MClientInclude = MClientInclude and MClientCategory
      end

      if self.Filter.Types then
        local MClientType = false
        for TypeID, TypeName in pairs( self.Filter.Types ) do
          --self:T(3( { "Type:", MClient:GetTypeName(), TypeName } )
          if TypeName == MClient:GetTypeName() then
            MClientType = true
          end
        end
        --self:T(( { "Evaluated Type", MClientType } )
        MClientInclude = MClientInclude and MClientType
      end

      if self.Filter.Countries then
        local MClientCountry = false
        for CountryID, CountryName in pairs( self.Filter.Countries ) do
          local ClientCountryID = _DATABASE:GetCountryFromClientTemplate( MClientName )
          --self:T(3( { "Country:", ClientCountryID, country.id[CountryName], CountryName } )
          if country.id[CountryName] and country.id[CountryName] == ClientCountryID then
            MClientCountry = true
          end
        end
        --self:T(( { "Evaluated Country", MClientCountry } )
        MClientInclude = MClientInclude and MClientCountry
      end

      if self.Filter.ClientPrefixes then
        local MClientPrefix = false
        for ClientPrefixId, ClientPrefix in pairs( self.Filter.ClientPrefixes ) do
          --self:T(3( { "Prefix:", string.find( MClient.UnitName, ClientPrefix, 1 ), ClientPrefix } )
          if string.find( MClient.UnitName, ClientPrefix, 1 ) then
            MClientPrefix = true
          end
        end
        --self:T(( { "Evaluated Prefix", MClientPrefix } )
        MClientInclude = MClientInclude and MClientPrefix
      end
    end
    
    if self.Filter.Zones then
      local MClientZone = false
      for ZoneName, Zone in pairs( self.Filter.Zones ) do
        --self:T(3( "Zone:", ZoneName )
        local unit = MClient:GetClientGroupUnit()
        if unit and unit:IsInZone(Zone) then
          MClientZone = true
        end
      end
      MClientInclude = MClientInclude and MClientZone
    end
    
    if self.Filter.Functions and MClientInclude then
      local MClientFunc = self:_EvalFilterFunctions(MClient)
      MClientInclude = MClientInclude and MClientFunc
    end
    
    --self:T(2( MClientInclude )
    return MClientInclude
  end

end

do -- SET_AIRBASE
  
  ---
  -- @type SET_AIRBASE
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

  --- Add an AIRBASE object to SET_AIRBASE.
  -- @param Core.Set#SET_AIRBASE self
  -- @param Wrapper.Airbase#AIRBASE airbase Airbase that should be added to the set.
  -- @return self
  function SET_AIRBASE:AddAirbase( airbase )

    self:Add( airbase:GetName(), airbase )

    return self
  end

  --- Add AIRBASEs to SET_AIRBASE.
  -- @param Core.Set#SET_AIRBASE self
  -- @param #string AddAirbaseNames A single name or an array of AIRBASE names.
  -- @return self
  function SET_AIRBASE:AddAirbasesByName( AddAirbaseNames )

    local AddAirbaseNamesArray = (type( AddAirbaseNames ) == "table") and AddAirbaseNames or { AddAirbaseNames }

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

    local RemoveAirbaseNamesArray = (type( RemoveAirbaseNames ) == "table") and RemoveAirbaseNames or { RemoveAirbaseNames }

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

  --- Finds an Airbase in range of a coordinate.
  -- @param #SET_AIRBASE self
  -- @param Core.Point#COORDINATE Coordinate
  -- @param #number Range
  -- @return Wrapper.Airbase#AIRBASE The found Airbase.
  function SET_AIRBASE:FindAirbaseInRange( Coordinate, Range )

    local AirbaseFound = nil

    for AirbaseName, AirbaseObject in pairs( self.Set ) do

      local AirbaseCoordinate = AirbaseObject:GetCoordinate()
      local Distance = Coordinate:Get2DDistance( AirbaseCoordinate )

      --self:F( { Distance = Distance } )

      if Distance <= Range then
        AirbaseFound = AirbaseObject
        break
      end

    end

    return AirbaseFound
  end

  --- Finds a random Airbase in the set.
  -- @param #SET_AIRBASE self
  -- @return Wrapper.Airbase#AIRBASE The found Airbase.
  function SET_AIRBASE:GetRandomAirbase()

    local RandomAirbase = self:GetRandom()
    --self:F( { RandomAirbase = RandomAirbase:GetName() } )

    return RandomAirbase
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
      self:HandleEvent( EVENTS.Dead )

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

  --- Base capturing event.
  -- @param #SET_AIRBASE self
  -- @param Core.Event#EVENT EventData
  function SET_AIRBASE:OnEventBaseCaptured( EventData )

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

  --- Dead event.
  -- @param #SET_AIRBASE self
  -- @param Core.Event#EVENT EventData
  function SET_AIRBASE:OnEventDead( EventData )

    local airbaseName, airbase = self:FindInDatabase( EventData )

    if airbase and (airbase:IsShip() or airbase:IsHelipad()) then
      self:RemoveAirbasesByName( airbaseName )
    end

  end

  --- Handles the Database to check on an event (birth) that the Object was added in the Database.
  -- This is required, because sometimes the _DATABASE birth event gets called later than the SET_BASE birth event!
  -- @param #SET_AIRBASE self
  -- @param Core.Event#EVENTDATA Event Event data.
  -- @return #string The name of the AIRBASE.
  -- @return Wrapper.Airbase#AIRBASE The AIRBASE object.
  function SET_AIRBASE:AddInDatabase( Event )
    return Event.IniDCSUnitName, self.Database[Event.IniDCSUnitName]
  end

  --- Handles the Database to check on any event that Object exists in the Database.
  -- This is required, because sometimes the _DATABASE event gets called later than the SET_BASE event or vise versa!
  -- @param #SET_AIRBASE self
  -- @param Core.Event#EVENTDATA Event Event data.
  -- @return #string The name of the AIRBASE.
  -- @return Wrapper.Airbase#AIRBASE The AIRBASE object.
  function SET_AIRBASE:FindInDatabase( Event )
    --self:F3( { Event } )

    return Event.IniDCSUnitName, self.Database[Event.IniDCSUnitName]
  end

  --- Iterate the SET_AIRBASE and call an iterator function for each AIRBASE, providing the AIRBASE and optional parameters.
  -- @param #SET_AIRBASE self
  -- @param #function IteratorFunction The function that will be called when there is an alive AIRBASE in the SET_AIRBASE. The function needs to accept a AIRBASE parameter.
  -- @return #SET_AIRBASE self
  function SET_AIRBASE:ForEachAirbase( IteratorFunction, ... )
    --self:F2( arg )

    self:ForEach( IteratorFunction, arg, self:GetSet() )

    return self
  end

  --- Iterate the SET_AIRBASE while identifying the nearest @{Wrapper.Airbase#AIRBASE} from a @{Core.Point#POINT_VEC2}.
  -- @param #SET_AIRBASE self
  -- @param Core.Point#POINT_VEC2 PointVec2 A @{Core.Point#POINT_VEC2} object from where to evaluate the closest @{Wrapper.Airbase#AIRBASE}.
  -- @return Wrapper.Airbase#AIRBASE The closest @{Wrapper.Airbase#AIRBASE}.
  function SET_AIRBASE:FindNearestAirbaseFromPointVec2( PointVec2 )
    --self:F2( PointVec2 )

    local NearestAirbase = self:FindNearestObjectFromPointVec2( PointVec2 )
    return NearestAirbase
  end

  ---
  -- @param #SET_AIRBASE self
  -- @param Wrapper.Airbase#AIRBASE MAirbase
  -- @return #SET_AIRBASE self
  function SET_AIRBASE:IsIncludeObject( MAirbase )
    --self:F2( MAirbase )

    local MAirbaseInclude = true

    if MAirbase then
      local MAirbaseName = MAirbase:GetName()

      if self.Filter.Coalitions then
        local MAirbaseCoalition = false
        for CoalitionID, CoalitionName in pairs( self.Filter.Coalitions ) do
          local AirbaseCoalitionID = _DATABASE:GetCoalitionFromAirbase( MAirbaseName )
          --self:T(3( { "Coalition:", AirbaseCoalitionID, self.FilterMeta.Coalitions[CoalitionName], CoalitionName } )
          if self.FilterMeta.Coalitions[CoalitionName] and self.FilterMeta.Coalitions[CoalitionName] == AirbaseCoalitionID then
            MAirbaseCoalition = true
          end
        end
        --self:T(( { "Evaluated Coalition", MAirbaseCoalition } )
        MAirbaseInclude = MAirbaseInclude and MAirbaseCoalition
      end

      if self.Filter.Categories and MAirbaseInclude then
        local MAirbaseCategory = false
        for CategoryID, CategoryName in pairs( self.Filter.Categories ) do
          local AirbaseCategoryID = _DATABASE:GetCategoryFromAirbase( MAirbaseName )
          --self:T(3( { "Category:", AirbaseCategoryID, self.FilterMeta.Categories[CategoryName], CategoryName } )
          if self.FilterMeta.Categories[CategoryName] and self.FilterMeta.Categories[CategoryName] == AirbaseCategoryID then
            MAirbaseCategory = true
          end
        end
        --self:T(( { "Evaluated Category", MAirbaseCategory } )
        MAirbaseInclude = MAirbaseInclude and MAirbaseCategory
      end
    end
    
    if self.Filter.Functions and MAirbaseInclude then
      local MClientFunc = self:_EvalFilterFunctions(MAirbase)
      MAirbaseInclude = MAirbaseInclude and MClientFunc
    end

    --self:T(2( MAirbaseInclude )
    return MAirbaseInclude
  end

end

do -- SET_CARGO
  
  ---
  -- @type SET_CARGO
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
  --    * @{#SET_CARGO.FilterPrefixes}: Builds the SET_CARGO with the cargos containing the same string(s). **Attention!** LUA regular expression apply here, so special characters in names like minus, dot, hash (#) etc might lead to unexpected results. 
  -- Have a read through here to understand the application of regular expressions: [LUA regular expressions](https://riptutorial.com/lua/example/20315/lua-pattern-matching)
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
  function SET_CARGO:New() -- R2.1
    -- Inherits from BASE
    local self = BASE:Inherit( self, SET_BASE:New( _DATABASE.CARGOS ) ) -- #SET_CARGO

    return self
  end

  --- (R2.1) Add CARGO to SET_CARGO.
  -- @param Core.Set#SET_CARGO self
  -- @param Cargo.Cargo#CARGO Cargo A single cargo.
  -- @return  Core.Set#SET_CARGO self
  function SET_CARGO:AddCargo( Cargo ) -- R2.4

    self:Add( Cargo:GetName(), Cargo )

    return self
  end

  --- (R2.1) Add CARGOs to SET_CARGO.
  -- @param Core.Set#SET_CARGO self
  -- @param #string AddCargoNames A single name or an array of CARGO names.
  -- @return  Core.Set#SET_CARGO self
  function SET_CARGO:AddCargosByName( AddCargoNames ) -- R2.1

    local AddCargoNamesArray = (type( AddCargoNames ) == "table") and AddCargoNames or { AddCargoNames }

    for AddCargoID, AddCargoName in pairs( AddCargoNamesArray ) do
      self:Add( AddCargoName, CARGO:FindByName( AddCargoName ) )
    end

    return self
  end

  --- (R2.1) Remove CARGOs from SET_CARGO.
  -- @param Core.Set#SET_CARGO self
  -- @param Cargo.Cargo#CARGO RemoveCargoNames A single name or an array of CARGO names.
  -- @return Core.Set#SET_CARGO self
  function SET_CARGO:RemoveCargosByName( RemoveCargoNames ) -- R2.1

    local RemoveCargoNamesArray = (type( RemoveCargoNames ) == "table") and RemoveCargoNames or { RemoveCargoNames }

    for RemoveCargoID, RemoveCargoName in pairs( RemoveCargoNamesArray ) do
      self:Remove( RemoveCargoName.CargoName )
    end

    return self
  end

  --- (R2.1) Finds a Cargo based on the Cargo Name.
  -- @param #SET_CARGO self
  -- @param #string CargoName
  -- @return Cargo.Cargo#CARGO The found Cargo.
  function SET_CARGO:FindCargo( CargoName ) -- R2.1

    local CargoFound = self.Set[CargoName]
    return CargoFound
  end

  --- (R2.1) Builds a set of cargos of coalitions.
  -- Possible current coalitions are red, blue and neutral.
  -- @param #SET_CARGO self
  -- @param #string Coalitions Can take the following values: "red", "blue", "neutral".
  -- @return #SET_CARGO self
  function SET_CARGO:FilterCoalitions( Coalitions ) -- R2.1
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
  function SET_CARGO:FilterTypes( Types ) -- R2.1
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
  function SET_CARGO:FilterCountries( Countries ) -- R2.1
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

  --- Builds a set of CARGOs that contain a given string in their name.
  -- **Attention!** Bad naming convention as this **does not** filter only **prefixes** but all cargos that **contain** the string. 
  -- @param #SET_CARGO self
  -- @param #string Prefixes The string pattern(s) that need to be in the cargo name. Can also be passed as a `#table` of strings.
  -- @return #SET_CARGO self
  function SET_CARGO:FilterPrefixes( Prefixes ) -- R2.1
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
  function SET_CARGO:FilterStart() -- R2.1

    if _DATABASE then
      self:_FilterStart()
      self:HandleEvent( EVENTS.NewCargo )
      self:HandleEvent( EVENTS.DeleteCargo )
    end

    return self
  end

  --- Stops the filtering for the defined collection.
  -- @param #SET_CARGO self
  -- @return #SET_CARGO self
  function SET_CARGO:FilterStop()

    self:UnHandleEvent( EVENTS.NewCargo )
    self:UnHandleEvent( EVENTS.DeleteCargo )

    return self
  end

  --- (R2.1) Handles the Database to check on an event (birth) that the Object was added in the Database.
  -- This is required, because sometimes the _DATABASE birth event gets called later than the SET_BASE birth event!
  -- @param #SET_CARGO self
  -- @param Core.Event#EVENTDATA Event
  -- @return #string The name of the CARGO
  -- @return #table The CARGO
  function SET_CARGO:AddInDatabase( Event ) -- R2.1
    --self:F3( { Event } )

    return Event.IniDCSUnitName, self.Database[Event.IniDCSUnitName]
  end

  --- (R2.1) Handles the Database to check on any event that Object exists in the Database.
  -- This is required, because sometimes the _DATABASE event gets called later than the SET_BASE event or vise versa!
  -- @param #SET_CARGO self
  -- @param Core.Event#EVENTDATA Event
  -- @return #string The name of the CARGO
  -- @return #table The CARGO
  function SET_CARGO:FindInDatabase( Event ) -- R2.1
    --self:F3( { Event } )

    return Event.IniDCSUnitName, self.Database[Event.IniDCSUnitName]
  end

  --- (R2.1) Iterate the SET_CARGO and call an iterator function for each CARGO, providing the CARGO and optional parameters.
  -- @param #SET_CARGO self
  -- @param #function IteratorFunction The function that will be called when there is an alive CARGO in the SET_CARGO. The function needs to accept a CARGO parameter.
  -- @return #SET_CARGO self
  function SET_CARGO:ForEachCargo( IteratorFunction, ... ) -- R2.1
    --self:F2( arg )

    self:ForEach( IteratorFunction, arg, self:GetSet() )

    return self
  end

  --- (R2.1) Iterate the SET_CARGO while identifying the nearest @{Cargo.Cargo#CARGO} from a @{Core.Point#POINT_VEC2}.
  -- @param #SET_CARGO self
  -- @param Core.Point#POINT_VEC2 PointVec2 A @{Core.Point#POINT_VEC2} object from where to evaluate the closest @{Cargo.Cargo#CARGO}.
  -- @return Cargo.Cargo#CARGO The closest @{Cargo.Cargo#CARGO}.
  function SET_CARGO:FindNearestCargoFromPointVec2( PointVec2 ) -- R2.1
    --self:F2( PointVec2 )

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
  function SET_CARGO:IsIncludeObject( MCargo ) -- R2.1
    --self:F2( MCargo )

    local MCargoInclude = true

    if MCargo then
      local MCargoName = MCargo:GetName()

      if self.Filter.Coalitions then
        local MCargoCoalition = false
        for CoalitionID, CoalitionName in pairs( self.Filter.Coalitions ) do
          local CargoCoalitionID = MCargo:GetCoalition()
          --self:T(3( { "Coalition:", CargoCoalitionID, self.FilterMeta.Coalitions[CoalitionName], CoalitionName } )
          if self.FilterMeta.Coalitions[CoalitionName] and self.FilterMeta.Coalitions[CoalitionName] == CargoCoalitionID then
            MCargoCoalition = true
          end
        end
        --self:F( { "Evaluated Coalition", MCargoCoalition } )
        MCargoInclude = MCargoInclude and MCargoCoalition
      end

      if self.Filter.Types then
        local MCargoType = false
        for TypeID, TypeName in pairs( self.Filter.Types ) do
          --self:T(3( { "Type:", MCargo:GetType(), TypeName } )
          if TypeName == MCargo:GetType() then
            MCargoType = true
          end
        end
        --self:F( { "Evaluated Type", MCargoType } )
        MCargoInclude = MCargoInclude and MCargoType
      end

      if self.Filter.CargoPrefixes then
        local MCargoPrefix = false
        for CargoPrefixId, CargoPrefix in pairs( self.Filter.CargoPrefixes ) do
          --self:T(3( { "Prefix:", string.find( MCargo.Name, CargoPrefix, 1 ), CargoPrefix } )
          if string.find( MCargo.Name, CargoPrefix, 1 ) then
            MCargoPrefix = true
          end
        end
        --self:F( { "Evaluated Prefix", MCargoPrefix } )
        MCargoInclude = MCargoInclude and MCargoPrefix
      end
    end
    
    if self.Filter.Functions and MCargoInclude then
      local MClientFunc = self:_EvalFilterFunctions(MCargo)
      MCargoInclude = MCargoInclude and MClientFunc
    end

    --self:T(2( MCargoInclude )
    return MCargoInclude
  end

  --- (R2.1) Handles the OnEventNewCargo event for the Set.
  -- @param #SET_CARGO self
  -- @param Core.Event#EVENTDATA EventData
  function SET_CARGO:OnEventNewCargo( EventData ) -- R2.1

    --self:F( { "New Cargo", EventData } )

    if EventData.Cargo then
      if EventData.Cargo and self:IsIncludeObject( EventData.Cargo ) then
        self:Add( EventData.Cargo.Name, EventData.Cargo )
      end
    end
  end

  --- (R2.1) Handles the OnDead or OnCrash event for alive units set.
  -- @param #SET_CARGO self
  -- @param Core.Event#EVENTDATA EventData
  function SET_CARGO:OnEventDeleteCargo( EventData ) -- R2.1
    --self:F3( { EventData } )

    if EventData.Cargo then
      local Cargo = _DATABASE:FindCargo( EventData.Cargo.Name )
      if Cargo and Cargo.Name then

        -- When cargo was deleted, it may probably be because of an S_EVENT_DEAD.
        -- However, in the loading logic, an S_EVENT_DEAD is also generated after a Destroy() call.
        -- And this is a problem because it will remove all entries from the SET_CARGOs.
        -- To prevent this from happening, the Cargo object has a flag NoDestroy.
        -- When true, the SET_CARGO won't Remove the Cargo object from the set.
        -- This flag is switched off after the event handlers have been called in the EVENT class.
        --self:F( { CargoNoDestroy = Cargo.NoDestroy } )
        if Cargo.NoDestroy then
        else
          self:Remove( Cargo.Name )
        end
      end
    end
  end

end

do -- SET_ZONE
  
  ---
  -- @type SET_ZONE
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
  --    * @{#SET_ZONE.FilterPrefixes}: Builds the SET_ZONE with the zones having a certain text pattern in their name. **Attention!** LUA regular expression apply here, so special characters in names like minus, dot, hash (#) etc might lead to unexpected results. 
  -- Have a read through here to understand the application of regular expressions: [LUA regular expressions](https://riptutorial.com/lua/example/20315/lua-pattern-matching)
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
    Checktime = 5,
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

  --- Add ZONEs by a search name to SET_ZONE.
  -- @param Core.Set#SET_ZONE self
  -- @param #string AddZoneNames A single name or an array of ZONE_BASE names.
  -- @return self
  function SET_ZONE:AddZonesByName( AddZoneNames )

    local AddZoneNamesArray = (type( AddZoneNames ) == "table") and AddZoneNames or { AddZoneNames }

    for AddAirbaseID, AddZoneName in pairs( AddZoneNamesArray ) do
      self:Add( AddZoneName, ZONE:FindByName( AddZoneName ) )
    end

    return self
  end

  --- Add ZONEs to SET_ZONE.
  -- @param Core.Set#SET_ZONE self
  -- @param Core.Zone#ZONE_BASE Zone A ZONE_BASE object.
  -- @return self
  function SET_ZONE:AddZone( Zone )

    self:Add( Zone:GetName(), Zone )

    return self
  end

  --- Remove ZONEs from SET_ZONE.
  -- @param Core.Set#SET_ZONE self
  -- @param Core.Zone#ZONE_BASE RemoveZoneNames A single name or an array of ZONE_BASE names.
  -- @return self
  function SET_ZONE:RemoveZonesByName( RemoveZoneNames )

    local RemoveZoneNamesArray = (type( RemoveZoneNames ) == "table") and RemoveZoneNames or { RemoveZoneNames }

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
  -- @param #number margin Number of tries to find a zone
  -- @return Core.Zone#ZONE_BASE The random Zone.
  -- @return #nil if no zone in the collection.
  function SET_ZONE:GetRandomZone( margin )

    local margin = margin or 100
    if self:Count() ~= 0 then

      local Index = self.Index
      local ZoneFound = nil -- Core.Zone#ZONE_BASE

      -- Loop until a zone has been found.
      -- The :GetZoneMaybe() call will evaluate the probability for the zone to be selected.
      -- If the zone is not selected, then nil is returned by :GetZoneMaybe() and the loop continues!
      local counter = 0
      while (not ZoneFound) or (counter < margin) do
        local ZoneRandom = math.random( 1, #Index )
        ZoneFound = self.Set[Index[ZoneRandom]]:GetZoneMaybe()
        counter = counter + 1
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

  --- Builds a set of ZONEs that contain the given string in their name.
  -- **ATTENTION!** Bad naming convention as this **does not** filter only **prefixes** but all zones that **contain** the string. 
  -- @param #SET_ZONE self
  -- @param #string Prefixes The string pattern(s) that need to be contained in the zone name. Can also be passed as a `#table` of strings.
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

  --- Stops the filtering for the defined collection.
  -- @param #SET_ZONE self
  -- @return #SET_ZONE self
  function SET_ZONE:FilterStop()

    self:UnHandleEvent( EVENTS.NewZone )
    self:UnHandleEvent( EVENTS.DeleteZone )

    return self
  end

  --- Handles the Database to check on an event (birth) that the Object was added in the Database.
  -- This is required, because sometimes the _DATABASE birth event gets called later than the SET_BASE birth event!
  -- @param #SET_ZONE self
  -- @param Core.Event#EVENTDATA Event
  -- @return #string The name of the AIRBASE
  -- @return #table The AIRBASE
  function SET_ZONE:AddInDatabase( Event )
    --self:F3( { Event } )

    return Event.IniDCSUnitName, self.Database[Event.IniDCSUnitName]
  end

  --- Handles the Database to check on any event that Object exists in the Database.
  -- This is required, because sometimes the _DATABASE event gets called later than the SET_BASE event or vise versa!
  -- @param #SET_ZONE self
  -- @param Core.Event#EVENTDATA Event
  -- @return #string The name of the AIRBASE
  -- @return #table The AIRBASE
  function SET_ZONE:FindInDatabase( Event )
    --self:F3( { Event } )

    return Event.IniDCSUnitName, self.Database[Event.IniDCSUnitName]
  end

  --- Iterate the SET_ZONE and call an iterator function for each ZONE, providing the ZONE and optional parameters.
  -- @param #SET_ZONE self
  -- @param #function IteratorFunction The function that will be called when there is an alive ZONE in the SET_ZONE. The function needs to accept a AIRBASE parameter.
  -- @return #SET_ZONE self
  function SET_ZONE:ForEachZone( IteratorFunction, ... )
    --self:F2( arg )

    self:ForEach( IteratorFunction, arg, self:GetSet() )

    return self
  end

  --- Draw all zones in the set on the F10 map.
  -- @param #SET_ZONE self
  -- @param #number Coalition Coalition: All=-1, Neutral=0, Red=1, Blue=2. Default -1=All.
  -- @param #table Color RGB color table {r, g, b}, e.g. {1,0,0} for red.
  -- @param #number Alpha Transparency [0,1]. Default 1.
  -- @param #table FillColor RGB color table {r, g, b}, e.g. {1,0,0} for red. Default is same as `Color` value.
  -- @param #number FillAlpha Transparency [0,1]. Default 0.15.
  -- @param #number LineType Line type: 0=No line, 1=Solid, 2=Dashed, 3=Dotted, 4=Dot dash, 5=Long dash, 6=Two dash. Default 1=Solid.
  -- @param #boolean ReadOnly (Optional) Mark is readonly and cannot be removed by users. Default false.
  -- @return #SET_ZONE self
  function SET_ZONE:DrawZone(Coalition, Color, Alpha, FillColor, FillAlpha, LineType, ReadOnly)
  
    for _,_zone in pairs(self.Set) do
      local zone=_zone --Core.Zone#ZONE
      zone:DrawZone(Coalition, Color, Alpha, FillColor, FillAlpha, LineType, ReadOnly)
    end

    return self
  end
  
  --- Get the average aggregated coordinate of this set of zones.
  -- @param #SET_ZONE self
  -- @return Core.Point#COORDINATE
  function SET_ZONE:GetAverageCoordinate()
    local x,y,z = 0,0,0
    local count = 0
    for _,_zone in pairs(self.Set) do
      local zone=_zone --Core.Zone#ZONE
      local vec3 = zone:GetVec3()
      x = x + vec3.x
      y = y + vec3.y
      z = z + vec3.z
      count = count + 1
    end
    if count > 1 then
      x = x/count
      y = y/count
      z = z/count
    end
    local coord = COORDINATE:New(x,y,z)
    return coord
  end

  --- Private function.
  -- @param #SET_ZONE self
  -- @param Core.Zone#ZONE_BASE MZone
  -- @return #SET_ZONE self
  function SET_ZONE:IsIncludeObject( MZone )
    --self:F2( MZone )

    local MZoneInclude = true

    if MZone then
      local MZoneName = MZone:GetName()

      if self.Filter.Prefixes then
        local MZonePrefix = false
        for ZonePrefixId, ZonePrefix in pairs( self.Filter.Prefixes ) do
          --self:T(2( { "Prefix:", string.find( MZoneName, ZonePrefix, 1 ), ZonePrefix } )
          if string.find( MZoneName, ZonePrefix, 1 ) then
            MZonePrefix = true
          end
        end
        --self:T(( { "Evaluated Prefix", MZonePrefix } )
        MZoneInclude = MZoneInclude and MZonePrefix
      end
    end
    
    if self.Filter.Functions and MZoneInclude then
      local MClientFunc = self:_EvalFilterFunctions(MZone)
      MZoneInclude = MZoneInclude and MClientFunc
    end

    --self:T(2( MZoneInclude )
    return MZoneInclude
  end

  --- Handles the OnEventNewZone event for the Set.
  -- @param #SET_ZONE self
  -- @param Core.Event#EVENTDATA EventData
  function SET_ZONE:OnEventNewZone( EventData ) -- R2.1

    --self:F( { "New Zone", EventData } )

    if EventData.Zone then
      if EventData.Zone and self:IsIncludeObject( EventData.Zone ) then
        self:Add( EventData.Zone.ZoneName, EventData.Zone )
      end
    end
  end

  --- Handles the OnDead or OnCrash event for alive units set.
  -- @param #SET_ZONE self
  -- @param Core.Event#EVENTDATA EventData
  function SET_ZONE:OnEventDeleteZone( EventData ) -- R2.1
    --self:F3( { EventData } )

    if EventData.Zone then
      local Zone = _DATABASE:FindZone( EventData.Zone.ZoneName )
      if Zone and Zone.ZoneName then

        -- When cargo was deleted, it may probably be because of an S_EVENT_DEAD.
        -- However, in the loading logic, an S_EVENT_DEAD is also generated after a Destroy() call.
        -- And this is a problem because it will remove all entries from the SET_ZONEs.
        -- To prevent this from happening, the Zone object has a flag NoDestroy.
        -- When true, the SET_ZONE won't Remove the Zone object from the set.
        -- This flag is switched off after the event handlers have been called in the EVENT class.
        --self:F( { ZoneNoDestroy = Zone.NoDestroy } )
        if Zone.NoDestroy then
        else
          self:Remove( Zone.ZoneName )
        end
      end
    end
  end

  --- Validate if a coordinate is in one of the zones in the set.
  -- Returns the ZONE object where the coordinate is located.
  -- If zones overlap, the first zone that validates the test is returned.
  -- @param #SET_ZONE self
  -- @param Core.Point#COORDINATE Coordinate The coordinate to be searched.
  -- @return Core.Zone#ZONE_BASE The zone (if any) that validates the coordinate location.
  function SET_ZONE:IsCoordinateInZone( Coordinate )

    for _, Zone in pairs( self:GetSet() ) do
      local Zone = Zone -- Core.Zone#ZONE_BASE
      if Zone:IsCoordinateInZone( Coordinate ) then
        return Zone
      end
    end

    return nil
  end
  
  --- Get the closest zone to a given coordinate.
  -- @param #SET_ZONE self
  -- @param Core.Point#COORDINATE Coordinate The reference coordinate from which the closest zone is determined.
  -- @return Core.Zone#ZONE_BASE The closest zone (if any).
  -- @return #number Distance to ref coordinate in meters.
  function SET_ZONE:GetClosestZone( Coordinate )

    local dmin=math.huge
    local zmin=nil
    for _, Zone in pairs( self:GetSet() ) do
      local Zone = Zone -- Core.Zone#ZONE_BASE
      local d=Zone:Get2DDistance(Coordinate)
      if d<dmin then
        dmin=d
        zmin=Zone
      end
    end

    return zmin, dmin
  end  
  
  --- Set the check time for SET_ZONE:Trigger()
  -- @param #SET_ZONE self
  -- @param #number seconds Check every seconds for objects entering or leaving the zone. Defaults to 5 secs.
  -- @return #SET_ZONE self
  function SET_ZONE:SetCheckTime(seconds)
    self.Checktime = seconds or 5
    return self
  end
  
  --- Start watching if the Object or Objects move into or out of our set of zones.
  -- @param #SET_ZONE self
  -- @param Wrapper.Controllable#CONTROLLABLE Objects Object or Objects to watch, can be of type UNIT, GROUP, CLIENT, or SET\_UNIT, SET\_GROUP, SET\_CLIENT
  -- @return #SET_ZONE self
  -- @usage
  --          -- Create a SET_GROUP and a SET_ZONE for this:
  -- 
  --          local groupset = SET_GROUP:New():FilterPrefixes("Aerial"):FilterStart()
  --          
  --          -- Trigger will check each zone of the SET_ZONE every 5 secs for objects entering or leaving from the groupset
  --          local zoneset = SET_ZONE:New():FilterPrefixes("Target Zone"):FilterOnce():Trigger(groupset)
  --          
  --          -- Draw zones on map so we see what's going on
  --          zoneset:ForEachZone(
  --            function(zone)
  --              zone:DrawZone(-1, {0,1,0}, Alpha, FillColor, FillAlpha, 4, ReadOnly)
  --            end 
  --          )
  --          
  --          -- This FSM function will be called for entering objects
  --          function zoneset:OnAfterEnteredZone(From,Event,To,Controllable,Zone)
  --            MESSAGE:New("Group "..Controllable:GetName() .. " entered zone "..Zone:GetName(),10,"Set Trigger"):ToAll()
  --          end
  --          
  --          -- This FSM function will be called for leaving objects
  --          function zoneset:OnAfterLeftZone(From,Event,To,Controllable,Zone)
  --            MESSAGE:New("Group "..Controllable:GetName() .. " left zone "..Zone:GetName(),10,"Set Trigger"):ToAll()
  --          end
  --          
  --          -- Stop watching after 1 hour
  --          zoneset:__TriggerStop(3600)
  function SET_ZONE:Trigger(Objects)
    --self:I("Added Set_Zone Trigger")
    self:AddTransition("*","TriggerStart","TriggerRunning")
    self:AddTransition("*","EnteredZone","*")
    self:AddTransition("*","LeftZone","*")
    self:AddTransition("*","TriggerRunCheck","*")
    self:AddTransition("*","TriggerStop","TriggerStopped")
    self:TriggerStart()
    self.checkobjects = Objects
    if UTILS.IsInstanceOf(Objects,"SET_BASE") then
      self.objectset = Objects.Set
    else
      self.objectset = {Objects}
    end
    self:_TriggerCheck(true)
    self:__TriggerRunCheck(self.Checktime)
    return self
    
    ------------------------
    --- Pseudo Functions ---
    ------------------------
    
    --- Triggers the FSM event "TriggerStop". Stops the SET_ZONE Trigger.
    -- @function [parent=#SET_ZONE] TriggerStop
    -- @param #SET_ZONE self
  
    --- Triggers the FSM event "TriggerStop" after a delay. 
    -- @function [parent=#SET_ZONE] __TriggerStop
    -- @param #SET_ZONE self
    -- @param #number delay Delay in seconds.
    
    --- On After "EnteredZone" event. An observed object has entered the zone.
    -- @function [parent=#SET_ZONE] OnAfterEnteredZone
    -- @param #SET_ZONE self
    -- @param #string From From state.
    -- @param #string Event Event.
    -- @param #string To To state.
    -- @param Wrapper.Controllable#CONTROLLABLE Controllable The controllable entering the zone.
    -- @param Core.Zone#ZONE_BASE Zone The zone entered.
  
    --- On After "LeftZone" event. An observed object has left the zone.
    -- @function [parent=#SET_ZONE] OnAfterLeftZone
    -- @param #SET_ZONE self
    -- @param #string From From state.
    -- @param #string Event Event.
    -- @param #string To To state.
    -- @param Wrapper.Controllable#CONTROLLABLE Controllable The controllable leaving the zone.
    -- @param Core.Zone#ZONE_BASE Zone The zone left.
  end
  
  --- (Internal) Check the assigned objects for being in/out of the zone
  -- @param #SET_ZONE self
  -- @param #boolean fromstart If true, do the init of the objects
  -- @return #SET_ZONE self
  function SET_ZONE:_TriggerCheck(fromstart)
    --self:I("_TriggerCheck | FromStart = "..tostring(fromstart))
    if fromstart then
      for _,_object in pairs(self.objectset) do
        local obj = _object -- Wrapper.Controllable#CONTROLLABLE
        if obj and obj:IsAlive() then
          for _,_zone in pairs(self.Set) do
            if not obj.TriggerInZone then obj.TriggerInZone = {} end
            if _zone:IsCoordinateInZone(obj:GetCoordinate()) then
              obj.TriggerInZone[_zone.ZoneName] = true
            else
              obj.TriggerInZone[_zone.ZoneName] = false
            end
            --self:I("Object "..obj:GetName().." is in zone = "..tostring(obj.TriggerInZone[_zone.ZoneName]))
          end
        end
      end
    else
      for _,_object in pairs(self.objectset) do
        local obj = _object -- Wrapper.Controllable#CONTROLLABLE
        if obj and obj:IsAlive() then
          for _,_zone in pairs(self.Set) do
            -- Check for pop-up objects
            if not obj.TriggerInZone then
              -- has not been tagged previously - wasn't in set! 
              obj.TriggerInZone = {}
            end
            if not obj.TriggerInZone[_zone.ZoneName] then
              -- has not been tagged previously - wasn't in set! 
              obj.TriggerInZone[_zone.ZoneName] = false 
            end
            -- is obj in zone?
            local inzone = _zone:IsCoordinateInZone(obj:GetCoordinate())
            --self:I("Object "..obj:GetName().." is in zone: "..tostring(inzone))
            if inzone and not obj.TriggerInZone[_zone.ZoneName] then
              -- wasn't in zone before
              --self:I("Newly entered")
              self:__EnteredZone(0.5,obj,_zone)
              obj.TriggerInZone[_zone.ZoneName] = true
            elseif (not inzone) and obj.TriggerInZone[_zone.ZoneName] then
              -- has left the zone
              --self:I("Newly left")
              self:__LeftZone(0.5,obj,_zone)
              obj.TriggerInZone[_zone.ZoneName] = false
            else
              --self:I("Not left or not entered, or something went wrong!")
            end
          end
        end
      end
    end 
    return self
  end
  
  --- (Internal) Check the assigned objects for being in/out of the zone
  -- @param #SET_ZONE self
  -- @param #string From
  -- @param #string Event
  -- @param #string to
  -- @return #SET_ZONE self
  function SET_ZONE:onafterTriggerRunCheck(From,Event,To)
    --self:I("onafterTriggerRunCheck")
    --self:I({From, Event, To})  
    if self:GetState() ~= "TriggerStopped" then
      self:_TriggerCheck()
      self:__TriggerRunCheck(self.Checktime)
    end
    return self
  end
end

do -- SET_ZONE_GOAL
  
  ---
  -- @type SET_ZONE_GOAL
  -- @extends Core.Set#SET_BASE

  --- Mission designers can use the @{Core.Set#SET_ZONE_GOAL} class to build sets of zones of various types.
  --
  -- ## SET_ZONE_GOAL constructor
  --
  -- Create a new SET_ZONE_GOAL object with the @{#SET_ZONE_GOAL.New} method:
  --
  --    * @{#SET_ZONE_GOAL.New}: Creates a new SET_ZONE_GOAL object.
  --
  -- ## Add or Remove ZONEs from SET_ZONE_GOAL
  --
  -- ZONEs can be added and removed using the @{Core.Set#SET_ZONE_GOAL.AddZonesByName} and @{Core.Set#SET_ZONE_GOAL.RemoveZonesByName} respectively.
  -- These methods take a single ZONE name or an array of ZONE names to be added or removed from SET_ZONE_GOAL.
  --
  -- ## SET_ZONE_GOAL filter criteria
  --
  -- You can set filter criteria to build the collection of zones in SET_ZONE_GOAL.
  -- Filter criteria are defined by:
  --
  --    * @{#SET_ZONE_GOAL.FilterPrefixes}: Builds the SET_ZONE_GOAL with the zones having a certain text pattern in their name. **Attention!** LUA regular expression apply here, so special characters in names like minus, dot, hash (#) etc might lead to unexpected results. 
  -- Have a read through here to understand the application of regular expressions: [LUA regular expressions](https://riptutorial.com/lua/example/20315/lua-pattern-matching)
  --
  -- Once the filter criteria have been set for the SET_ZONE_GOAL, you can start filtering using:
  --
  --   * @{#SET_ZONE_GOAL.FilterStart}: Starts the filtering of the zones within the SET_ZONE_GOAL.
  --
  -- ## SET_ZONE_GOAL iterators
  --
  -- Once the filters have been defined and the SET_ZONE_GOAL has been built, you can iterate the SET_ZONE_GOAL with the available iterator methods.
  -- The iterator methods will walk the SET_ZONE_GOAL set, and call for each airbase within the set a function that you provide.
  -- The following iterator methods are currently available within the SET_ZONE_GOAL:
  --
  --   * @{#SET_ZONE_GOAL.ForEachZone}: Calls a function for each zone it finds within the SET_ZONE_GOAL.
  --
  -- ===
  -- @field #SET_ZONE_GOAL SET_ZONE_GOAL
  SET_ZONE_GOAL = {
    ClassName = "SET_ZONE_GOAL",
    Zones = {},
    Filter = {
      Prefixes = nil,
    },
      FilterMeta = {
    },
  }

  --- Creates a new SET_ZONE_GOAL object, building a set of zones.
  -- @param #SET_ZONE_GOAL self
  -- @return #SET_ZONE_GOAL self
  -- @usage
  -- -- Define a new SET_ZONE_GOAL Object. The DatabaseSet will contain a reference to all Zones.
  -- DatabaseSet = SET_ZONE_GOAL:New()
  function SET_ZONE_GOAL:New()
    -- Inherits from BASE
    local self = BASE:Inherit( self, SET_BASE:New( _DATABASE.ZONES_GOAL ) )

    return self
  end

  --- Add ZONEs to SET_ZONE_GOAL.
  -- @param Core.Set#SET_ZONE_GOAL self
  -- @param Core.Zone#ZONE_BASE Zone A ZONE_BASE object.
  -- @return self
  function SET_ZONE_GOAL:AddZone( Zone )

    self:Add( Zone:GetName(), Zone )

    return self
  end

  --- Remove ZONEs from SET_ZONE_GOAL.
  -- @param Core.Set#SET_ZONE_GOAL self
  -- @param Core.Zone#ZONE_BASE RemoveZoneNames A single name or an array of ZONE_BASE names.
  -- @return self
  function SET_ZONE_GOAL:RemoveZonesByName( RemoveZoneNames )

    local RemoveZoneNamesArray = (type( RemoveZoneNames ) == "table") and RemoveZoneNames or { RemoveZoneNames }

    for RemoveZoneID, RemoveZoneName in pairs( RemoveZoneNamesArray ) do
      self:Remove( RemoveZoneName )
    end

    return self
  end

  --- Finds a Zone based on the Zone Name.
  -- @param #SET_ZONE_GOAL self
  -- @param #string ZoneName
  -- @return Core.Zone#ZONE_BASE The found Zone.
  function SET_ZONE_GOAL:FindZone( ZoneName )

    local ZoneFound = self.Set[ZoneName]
    return ZoneFound
  end

  --- Get a random zone from the set.
  -- @param #SET_ZONE_GOAL self
  -- @return Core.Zone#ZONE_BASE The random Zone.
  -- @return #nil if no zone in the collection.
  function SET_ZONE_GOAL:GetRandomZone()

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
  -- @param #SET_ZONE_GOAL self
  -- @param #string ZoneName The name of the zone.
  function SET_ZONE_GOAL:SetZoneProbability( ZoneName, ZoneProbability )
    local Zone = self:FindZone( ZoneName )
    Zone:SetZoneProbability( ZoneProbability )
  end

  --- Builds a set of ZONE_GOALs that contain the given string in their name.
  -- **ATTENTION!** Bad naming convention as this **does not** filter only **prefixes** but all zones that **contain** the string. 
  -- @param #SET_ZONE_GOAL self
  -- @param #string Prefixes The string pattern(s) that needs to be contained in the zone name. Can also be passed as a `#table` of strings.
  -- @return #SET_ZONE_GOAL self
  function SET_ZONE_GOAL:FilterPrefixes( Prefixes )
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
  -- @param #SET_ZONE_GOAL self
  -- @return #SET_ZONE_GOAL self
  function SET_ZONE_GOAL:FilterStart()

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

    self:HandleEvent( EVENTS.NewZoneGoal )
    self:HandleEvent( EVENTS.DeleteZoneGoal )

    return self
  end

  --- Stops the filtering for the defined collection.
  -- @param #SET_ZONE_GOAL self
  -- @return #SET_ZONE_GOAL self
  function SET_ZONE_GOAL:FilterStop()

    self:UnHandleEvent( EVENTS.NewZoneGoal )
    self:UnHandleEvent( EVENTS.DeleteZoneGoal )

    return self
  end

  --- Handles the Database to check on an event (birth) that the Object was added in the Database.
  -- This is required, because sometimes the _DATABASE birth event gets called later than the SET_BASE birth event!
  -- @param #SET_ZONE_GOAL self
  -- @param Core.Event#EVENTDATA Event
  -- @return #string The name of the AIRBASE
  -- @return #table The AIRBASE
  function SET_ZONE_GOAL:AddInDatabase( Event )
    --self:F3( { Event } )

    return Event.IniDCSUnitName, self.Database[Event.IniDCSUnitName]
  end

  --- Handles the Database to check on any event that Object exists in the Database.
  -- This is required, because sometimes the _DATABASE event gets called later than the SET_BASE event or vise versa!
  -- @param #SET_ZONE_GOAL self
  -- @param Core.Event#EVENTDATA Event
  -- @return #string The name of the AIRBASE
  -- @return #table The AIRBASE
  function SET_ZONE_GOAL:FindInDatabase( Event )
    --self:F3( { Event } )

    return Event.IniDCSUnitName, self.Database[Event.IniDCSUnitName]
  end

  --- Iterate the SET_ZONE_GOAL and call an iterator function for each ZONE, providing the ZONE and optional parameters.
  -- @param #SET_ZONE_GOAL self
  -- @param #function IteratorFunction The function that will be called when there is an alive ZONE in the SET_ZONE_GOAL. The function needs to accept a AIRBASE parameter.
  -- @return #SET_ZONE_GOAL self
  function SET_ZONE_GOAL:ForEachZone( IteratorFunction, ... )
    --self:F2( arg )

    self:ForEach( IteratorFunction, arg, self:GetSet() )

    return self
  end

  ---
  -- @param #SET_ZONE_GOAL self
  -- @param Core.Zone#ZONE_BASE MZone
  -- @return #SET_ZONE_GOAL self
  function SET_ZONE_GOAL:IsIncludeObject( MZone )
    --self:F2( MZone )

    local MZoneInclude = true

    if MZone then
      local MZoneName = MZone:GetName()

      if self.Filter.Prefixes then
        local MZonePrefix = false
        for ZonePrefixId, ZonePrefix in pairs( self.Filter.Prefixes ) do
          --self:T(3( { "Prefix:", string.find( MZoneName, ZonePrefix, 1 ), ZonePrefix } )
          if string.find( MZoneName, ZonePrefix, 1 ) then
            MZonePrefix = true
          end
        end
        --self:T(( { "Evaluated Prefix", MZonePrefix } )
        MZoneInclude = MZoneInclude and MZonePrefix
      end
    end
    
    if self.Filter.Functions and MZoneInclude then
      local MClientFunc = self:_EvalFilterFunctions(MZone)
      MZoneInclude = MZoneInclude and MClientFunc
    end

    --self:T(2( MZoneInclude )
    return MZoneInclude
  end

  --- Handles the OnEventNewZone event for the Set.
  -- @param #SET_ZONE_GOAL self
  -- @param Core.Event#EVENTDATA EventData
  function SET_ZONE_GOAL:OnEventNewZoneGoal( EventData )

    -- Debug info.
    --self:T(( { "New Zone Capture Coalition", EventData } )
    --self:T(( { "Zone Capture Coalition", EventData.ZoneGoal } )

    if EventData.ZoneGoal then
      if EventData.ZoneGoal and self:IsIncludeObject( EventData.ZoneGoal ) then
        --self:T(( { "Adding Zone Capture Coalition", EventData.ZoneGoal.ZoneName, EventData.ZoneGoal } )
        self:Add( EventData.ZoneGoal.ZoneName, EventData.ZoneGoal )
      end
    end
  end

  --- Handles the OnDead or OnCrash event for alive units set.
  -- @param #SET_ZONE_GOAL self
  -- @param Core.Event#EVENTDATA EventData
  function SET_ZONE_GOAL:OnEventDeleteZoneGoal( EventData ) -- R2.1
    --self:F3( { EventData } )

    if EventData.ZoneGoal then
      local Zone = _DATABASE:FindZone( EventData.ZoneGoal.ZoneName )
      if Zone and Zone.ZoneName then

        -- When cargo was deleted, it may probably be because of an S_EVENT_DEAD.
        -- However, in the loading logic, an S_EVENT_DEAD is also generated after a Destroy() call.
        -- And this is a problem because it will remove all entries from the SET_ZONE_GOALs.
        -- To prevent this from happening, the Zone object has a flag NoDestroy.
        -- When true, the SET_ZONE_GOAL won't Remove the Zone object from the set.
        -- This flag is switched off after the event handlers have been called in the EVENT class.
        --self:F( { ZoneNoDestroy = Zone.NoDestroy } )
        if Zone.NoDestroy then
        else
          self:Remove( Zone.ZoneName )
        end
      end
    end
  end

  --- Validate if a coordinate is in one of the zones in the set.
  -- Returns the ZONE object where the coordiante is located.
  -- If zones overlap, the first zone that validates the test is returned.
  -- @param #SET_ZONE_GOAL self
  -- @param Core.Point#COORDINATE Coordinate The coordinate to be searched.
  -- @return Core.Zone#ZONE_BASE The zone that validates the coordinate location.
  -- @return #nil No zone has been found.
  function SET_ZONE_GOAL:IsCoordinateInZone( Coordinate )

    for _, Zone in pairs( self:GetSet() ) do
      local Zone = Zone -- Core.Zone#ZONE_BASE
      if Zone:IsCoordinateInZone( Coordinate ) then
        return Zone
      end
    end

    return nil
  end

end

do -- SET_OPSZONE
  
  ---
  -- @type SET_OPSZONE
  -- @extends Core.Set#SET_BASE

  --- Mission designers can use the @{Core.Set#SET_OPSZONE} class to build sets of zones of various types.
  --
  -- ## SET_OPSZONE constructor
  --
  -- Create a new SET_OPSZONE object with the @{#SET_OPSZONE.New} method:
  --
  --    * @{#SET_OPSZONE.New}: Creates a new SET_OPSZONE object.
  --
  -- ## Add or Remove ZONEs from SET_OPSZONE
  --
  -- ZONEs can be added and removed using the @{Core.Set#SET_OPSZONE.AddZonesByName} and @{Core.Set#SET_OPSZONE.RemoveZonesByName} respectively.
  -- These methods take a single ZONE name or an array of ZONE names to be added or removed from SET_OPSZONE.
  --
  -- ## SET_OPSZONE filter criteria
  --
  -- You can set filter criteria to build the collection of zones in SET_OPSZONE.
  -- Filter criteria are defined by:
  --
  --    * @{#SET_OPSZONE.FilterPrefixes}: Builds the SET_OPSZONE with the zones having a certain text pattern in their name. **Attention!** LUA regular expression apply here, so special characters in names like minus, dot, hash (#) etc might lead to unexpected results. 
  -- Have a read through here to understand the application of regular expressions: [LUA regular expressions](https://riptutorial.com/lua/example/20315/lua-pattern-matching)
  --
  -- Once the filter criteria have been set for the SET_OPSZONE, you can start filtering using:
  --
  --   * @{#SET_OPSZONE.FilterStart}: Starts the filtering of the zones within the SET_OPSZONE.
  --
  -- ## SET_OPSZONE iterators
  --
  -- Once the filters have been defined and the SET_OPSZONE has been built, you can iterate the SET_OPSZONE with the available iterator methods.
  -- The iterator methods will walk the SET_OPSZONE set, and call for each airbase within the set a function that you provide.
  -- The following iterator methods are currently available within the SET_OPSZONE:
  --
  --   * @{#SET_OPSZONE.ForEachZone}: Calls a function for each zone it finds within the SET_OPSZONE.
  --
  -- ===
  -- @field #SET_OPSZONE SET_OPSZONE
  SET_OPSZONE = {
    ClassName = "SET_OPSZONE",
    Zones = {},
    Filter = {
      Prefixes   = nil,
      Coalitions = nil,      
    },
    FilterMeta = {
      Coalitions = {
        red     = coalition.side.RED,
        blue    = coalition.side.BLUE,
        neutral = coalition.side.NEUTRAL,
      },
    }, --FilterMeta
  }

  --- Creates a new SET_OPSZONE object, building a set of zones.
  -- @param #SET_OPSZONE self
  -- @return #SET_OPSZONE self
  function SET_OPSZONE:New()
  
    -- Inherits from BASE
    local self = BASE:Inherit( self, SET_BASE:New( _DATABASE.OPSZONES ) )

    return self
  end

  --- Add an OPSZONE to set.
  -- @param Core.Set#SET_OPSZONE self
  -- @param Ops.OpsZone#OPSZONE Zone The OPSZONE object.
  -- @return #SET_OPSZONE self
  function SET_OPSZONE:AddZone( Zone )

    self:Add( Zone:GetName(), Zone )

    return self
  end 

  --- Remove ZONEs from SET_OPSZONE.
  -- @param Core.Set#SET_OPSZONE self
  -- @param #table RemoveZoneNames A single name or an array of OPSZONE names.
  -- @return #SET_OPSZONE  self
  function SET_OPSZONE:RemoveZonesByName( RemoveZoneNames )

    local RemoveZoneNamesArray = (type( RemoveZoneNames ) == "table") and RemoveZoneNames or { RemoveZoneNames }
    
    --UTILS.EnsureTable(Object,ReturnNil)

    for RemoveZoneID, RemoveZoneName in pairs( RemoveZoneNamesArray ) do
      self:Remove( RemoveZoneName )
    end

    return self
  end

  --- Finds a Zone based on its name.
  -- @param #SET_OPSZONE self
  -- @param #string ZoneName
  -- @return Ops.OpsZone#OPSZONE The found Zone.
  function SET_OPSZONE:FindZone( ZoneName )

    local ZoneFound = self.Set[ZoneName]
    
    return ZoneFound
  end

  --- Get a random zone from the set.
  -- @param #SET_OPSZONE self
  -- @return Ops.OpsZone#OPSZONE The random Zone.
  function SET_OPSZONE:GetRandomZone()

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
  -- @param #SET_OPSZONE self
  -- @param #string ZoneName The name of the zone.
  -- @param #number Probability The probability in percent.
  function SET_OPSZONE:SetZoneProbability( ZoneName, Probability )
    local Zone = self:FindZone( ZoneName )
    Zone:SetZoneProbability( Probability )
    return self
  end

  --- Builds a set of OPSZONEs that contain the given string in their name.
  -- **ATTENTION!** Bad naming convention as this **does not** filter only **prefixes** but all zones that **contain** the string. 
  -- @param #SET_OPSZONE self
  -- @param #string Prefixes The string pattern(s) that needs to be contained in the zone name. Can also be passed as a `#table` of strings.
  -- @return #SET_OPSZONE self
  function SET_OPSZONE:FilterPrefixes( Prefixes )
  
    if not self.Filter.Prefixes then
      self.Filter.Prefixes = {}
    end
    
    Prefixes=UTILS.EnsureTable(Prefixes, false)
    
    for PrefixID, Prefix in pairs( Prefixes ) do
      self.Filter.Prefixes[Prefix] = Prefix
    end
    
    return self
  end
  
  --- Builds a set of groups of coalitions. Possible current coalitions are red, blue and neutral.
  -- @param #SET_OPSZONE self
  -- @param #string Coalitions Can take the following values: "red", "blue", "neutral" or combinations as a table, for example `{"red", "neutral"}`.
  -- @return #SET_OPSZONE self
  function SET_OPSZONE:FilterCoalitions(Coalitions)
  
    -- Create an empty set.
    if not self.Filter.Coalitions then
      self.Filter.Coalitions={}
    end
    
    -- Ensure we got a table.
    Coalitions=UTILS.EnsureTable(Coalitions, false)
    
    -- Set filter.
    for CoalitionID, Coalition in pairs( Coalitions ) do
      self.Filter.Coalitions[Coalition] = Coalition
    end
    
    return self
  end  

  --- Filters for the defined collection.
  -- @param #SET_OPSZONE self
  -- @return #SET_OPSZONE self
  function SET_OPSZONE:FilterOnce()

    for ObjectName, Object in pairs( self.Database ) do
    
      -- First remove the object (without creating an event).
      self:Remove(ObjectName, true)

      if self:IsIncludeObject( Object ) then
        self:Add( ObjectName, Object )
      end
      
    end

    return self
  end
  
  --- Clear all filters. You still need to apply `FilterOnce()` to have an effect on the set.
  -- @param #SET_OPSZONE self
  -- @return #SET_OPSZONE self
  function SET_OPSZONE:FilterClear()
  
    local parent=self:GetParent(self, SET_OPSZONE) --#SET_BASE

    parent:FilterClear()

    return self
  end  


  --- Starts the filtering.
  -- @param #SET_OPSZONE self
  -- @return #SET_OPSZONE self
  function SET_OPSZONE:FilterStart()

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

    self:HandleEvent( EVENTS.NewZoneGoal )
    self:HandleEvent( EVENTS.DeleteZoneGoal )

    return self
  end

  --- Stops the filtering for the defined collection.
  -- @param #SET_OPSZONE self
  -- @return #SET_OPSZONE self
  function SET_OPSZONE:FilterStop()

    self:UnHandleEvent( EVENTS.NewZoneGoal )
    self:UnHandleEvent( EVENTS.DeleteZoneGoal )

    return self
  end

  --- Handles the Database to check on an event (birth) that the Object was added in the Database.
  -- This is required, because sometimes the _DATABASE birth event gets called later than the SET_BASE birth event!
  -- @param #SET_OPSZONE self
  -- @param Core.Event#EVENTDATA Event
  -- @return #string The name of the AIRBASE
  -- @return #table The AIRBASE
  function SET_OPSZONE:AddInDatabase( Event )
    --self:F3( { Event } )

    return Event.IniDCSUnitName, self.Database[Event.IniDCSUnitName]
  end

  --- Handles the Database to check on any event that Object exists in the Database.
  -- This is required, because sometimes the _DATABASE event gets called later than the SET_BASE event or vise versa!
  -- @param #SET_OPSZONE self
  -- @param Core.Event#EVENTDATA Event
  -- @return #string The name of the AIRBASE
  -- @return #table The AIRBASE
  function SET_OPSZONE:FindInDatabase( Event )
    --self:F3( { Event } )

    return Event.IniDCSUnitName, self.Database[Event.IniDCSUnitName]
  end

  --- Iterate the SET_OPSZONE and call an iterator function for each ZONE, providing the ZONE and optional parameters.
  -- @param #SET_OPSZONE self
  -- @param #function IteratorFunction The function that will be called when there is an alive ZONE in the SET_OPSZONE. The function needs to accept a AIRBASE parameter.
  -- @return #SET_OPSZONE self
  function SET_OPSZONE:ForEachZone( IteratorFunction, ... )
    --self:F2( arg )

    self:ForEach( IteratorFunction, arg, self:GetSet() )

    return self
  end

  --- Private function that checks if an object is contained in the set or filtered.
  -- @param #SET_OPSZONE self
  -- @param Ops.OpsZone#OPSZONE MZone The OPSZONE object.
  -- @return #SET_OPSZONE self
  function SET_OPSZONE:IsIncludeObject( MZone )
    --self:F2( MZone )

    local MZoneInclude = true

    if MZone then
    
      local MZoneName = MZone:GetName()

      if self.Filter.Prefixes then
      
        local MZonePrefix = false
        
        -- Loop over prefixes.
        for ZonePrefixId, ZonePrefix in pairs( self.Filter.Prefixes ) do
        
          -- Prifix
          --self:T(3( { "Prefix:", string.find( MZoneName, ZonePrefix, 1 ), ZonePrefix } )
          
          if string.find(MZoneName, ZonePrefix, 1) then
            MZonePrefix = true
            break --Break the loop as we found the prefix.
          end
          
        end
        
        --self:T(( { "Evaluated Prefix", MZonePrefix } )
        
        MZoneInclude = MZoneInclude and MZonePrefix
      end
    
      -- Filter coalitions.
      if self.Filter.Coalitions then
      
        local MGroupCoalition = false
        
        local coalition=MZone:GetOwner()
        
        for _, CoalitionName in pairs( self.Filter.Coalitions ) do
        
          if self.FilterMeta.Coalitions[CoalitionName] and self.FilterMeta.Coalitions[CoalitionName]==coalition then
            MGroupCoalition = true
            break -- Break the loop the coalition is contains.      
          end
          
        end
      
        MZoneInclude = MZoneInclude and MGroupCoalition
      end
    
    end    
    
    if self.Filter.Functions and MZoneInclude then
      local MClientFunc = self:_EvalFilterFunctions(MZone)
      MZoneInclude = MZoneInclude and MClientFunc
    end
    
    --self:T(2( MZoneInclude )
    return MZoneInclude
  end

  --- Handles the OnEventNewZone event for the Set.
  -- @param #SET_OPSZONE self
  -- @param Core.Event#EVENTDATA EventData
  function SET_OPSZONE:OnEventNewZoneGoal( EventData )

    -- Debug info.
    --self:T(( { "New Zone Capture Coalition", EventData } )
    --self:T(( { "Zone Capture Coalition", EventData.ZoneGoal } )

    if EventData.ZoneGoal then
      if EventData.ZoneGoal and self:IsIncludeObject( EventData.ZoneGoal ) then
        --self:T(( { "Adding Zone Capture Coalition", EventData.ZoneGoal.ZoneName, EventData.ZoneGoal } )
        self:Add( EventData.ZoneGoal.ZoneName, EventData.ZoneGoal )
      end
    end
  end

  --- Handles the OnDead or OnCrash event for alive units set.
  -- @param #SET_OPSZONE self
  -- @param Core.Event#EVENTDATA EventData
  function SET_OPSZONE:OnEventDeleteZoneGoal( EventData ) -- R2.1
    --self:F3( { EventData } )

    if EventData.ZoneGoal then
      local Zone = _DATABASE:FindZone( EventData.ZoneGoal.ZoneName )
      if Zone and Zone.ZoneName then

        -- When cargo was deleted, it may probably be because of an S_EVENT_DEAD.
        -- However, in the loading logic, an S_EVENT_DEAD is also generated after a Destroy() call.
        -- And this is a problem because it will remove all entries from the SET_OPSZONEs.
        -- To prevent this from happening, the Zone object has a flag NoDestroy.
        -- When true, the SET_OPSZONE won't Remove the Zone object from the set.
        -- This flag is switched off after the event handlers have been called in the EVENT class.
        --self:F( { ZoneNoDestroy = Zone.NoDestroy } )
        if Zone.NoDestroy then
        else
          self:Remove( Zone.ZoneName )
        end
      end
    end
  end
  
  --- Start all opszones of the set.
  -- @param #SET_OPSZONE self
  -- @return #SET_OPSZONE self
  function SET_OPSZONE:Start()

    for _,_Zone in pairs( self:GetSet() ) do
      local Zone = _Zone --Ops.OpsZone#OPSZONE
      if Zone:IsStopped() then
        Zone:Start()
      end
    end  

    return self
  end  

  --- Validate if a coordinate is in one of the zones in the set.
  -- Returns the ZONE object where the coordiante is located.
  -- If zones overlap, the first zone that validates the test is returned.
  -- @param #SET_OPSZONE self
  -- @param Core.Point#COORDINATE Coordinate The coordinate to be searched.
  -- @return Core.Zone#ZONE_BASE The zone that validates the coordinate location.
  -- @return #nil No zone has been found.
  function SET_OPSZONE:IsCoordinateInZone( Coordinate )

    for _,_Zone in pairs( self:GetSet() ) do
      local Zone = _Zone --Ops.OpsZone#OPSZONE
      if Zone:GetZone():IsCoordinateInZone( Coordinate ) then
        return Zone
      end
    end

    return nil
  end


  --- Get the closest OPSZONE from a given reference coordinate. Only started zones are considered.
  -- @param #SET_OPSZONE self
  -- @param Core.Point#COORDINATE Coordinate The reference coordinate from which the closest zone is determined.
  -- @param #table Coalitions Only consider the given coalition(s), *e.g.* `{coaliton.side.RED}` to find the closest red zone.
  -- @return Ops.OpsZone#OPSZONE The closest OPSZONE (if any).
  -- @return #number Distance to ref coordinate in meters.
  function SET_OPSZONE:GetClosestZone( Coordinate, Coalitions )
   
    Coalitions=UTILS.EnsureTable(Coalitions, true)

    local dmin=math.huge --#number
    local zmin=nil       --Ops.OpsZone#OPSZONE
    
    for _,_opszone in pairs(self:GetSet()) do
      local opszone=_opszone --Ops.OpsZone#OPSZONE
            
      local coal=opszone:GetOwner()
      
      if opszone:IsStarted() and (Coalitions==nil or (Coalitions and UTILS.IsInTable(Coalitions, coal))) then
      
        -- Get 2D distance.
        local d=opszone:GetZone():Get2DDistance(Coordinate)
        
        if d<dmin then        
          dmin=d
          zmin=opszone
        end
        
      end
    end

    return zmin, dmin
  end  

end


do -- SET_OPSGROUP
  
  ---
  -- @type SET_OPSGROUP
  -- @extends Core.Set#SET_BASE

  --- Mission designers can use the @{Core.Set#SET_OPSGROUP} class to build sets of OPS groups belonging to certain:
  --
  --  * Coalitions
  --  * Categories
  --  * Countries
  --  * Contain a certain string pattern
  --
  -- ## SET_OPSGROUP constructor
  --
  -- Create a new SET_OPSGROUP object with the @{#SET_OPSGROUP.New} method:
  --
  --    * @{#SET_OPSGROUP.New}: Creates a new SET_OPSGROUP object.
  --
  -- ## Add or Remove GROUP(s) from SET_OPSGROUP
  --
  -- GROUPS can be added and removed using the @{Core.Set#SET_OPSGROUP.AddGroupsByName} and @{Core.Set#SET_OPSGROUP.RemoveGroupsByName} respectively.
  -- These methods take a single GROUP name or an array of GROUP names to be added or removed from SET_OPSGROUP.
  --
  -- ## SET_OPSGROUP filter criteria
  --
  -- You can set filter criteria to define the set of groups within the SET_OPSGROUP.
  -- Filter criteria are defined by:
  --
  --    * @{#SET_OPSGROUP.FilterCoalitions}: Builds the SET_OPSGROUP with the groups belonging to the coalition(s).
  --    * @{#SET_OPSGROUP.FilterCategories}: Builds the SET_OPSGROUP with the groups belonging to the category(ies).
  --    * @{#SET_OPSGROUP.FilterCountries}: Builds the SET_OPSGROUP with the groups belonging to the country(ies).
  --    * @{#SET_OPSGROUP.FilterPrefixes}: Builds the SET_OPSGROUP with the groups *containing* the given string in the group name. **Attention!** LUA regular expression apply here, so special characters in names like minus, dot, hash (#) etc might lead to unexpected results. 
  -- Have a read through here to understand the application of regular expressions: [LUA regular expressions](https://riptutorial.com/lua/example/20315/lua-pattern-matching)
  --    * @{#SET_OPSGROUP.FilterActive}: Builds the SET_OPSGROUP with the groups that are only active. Groups that are inactive (late activation) won't be included in the set!
  --
  -- For the Category Filter, extra methods have been added:
  --
  --    * @{#SET_OPSGROUP.FilterCategoryAirplane}: Builds the SET_OPSGROUP from airplanes.
  --    * @{#SET_OPSGROUP.FilterCategoryHelicopter}: Builds the SET_OPSGROUP from helicopters.
  --    * @{#SET_OPSGROUP.FilterCategoryGround}: Builds the SET_OPSGROUP from ground vehicles or infantry.
  --    * @{#SET_OPSGROUP.FilterCategoryShip}: Builds the SET_OPSGROUP from ships.
  --
  --
  -- Once the filter criteria have been set for the SET_OPSGROUP, you can start filtering using:
  --
  --    * @{#SET_OPSGROUP.FilterStart}: Starts the filtering of the groups within the SET_OPSGROUP and add or remove GROUP objects **dynamically**.
  --    * @{#SET_OPSGROUP.FilterOnce}: Filters of the groups **once**.
  --
  --
  -- ## SET_OPSGROUP iterators
  --
  -- Once the filters have been defined and the SET_OPSGROUP has been built, you can iterate the SET_OPSGROUP with the available iterator methods.
  -- The iterator methods will walk the SET_OPSGROUP set, and call for each element within the set a function that you provide.
  -- The following iterator methods are currently available within the SET_OPSGROUP:
  --
  --   * @{#SET_OPSGROUP.ForEachGroup}: Calls a function for each alive group it finds within the SET_OPSGROUP.
  --
  -- ## SET_OPSGROUP trigger events on the GROUP objects.
  --
  -- The SET is derived from the FSM class, which provides extra capabilities to track the contents of the GROUP objects in the SET_OPSGROUP.
  --
  -- ### When a GROUP object crashes or is dead, the SET_OPSGROUP will trigger a **Dead** event.
  --
  -- You can handle the event using the OnBefore and OnAfter event handlers.
  -- The event handlers need to have the parameters From, Event, To, GroupObject.
  -- The GroupObject is the GROUP object that is dead and within the SET_OPSGROUP, and is passed as a parameter to the event handler.
  -- See the following example:
  --
  --        -- Create the SetCarrier SET_OPSGROUP collection.
  --
  --        local SetHelicopter = SET_OPSGROUP:New():FilterPrefixes( "Helicopter" ):FilterStart()
  --
  --        -- Put a Dead event handler on SetCarrier, to ensure that when a carrier is destroyed, that all internal parameters are reset.
  --
  --        function SetHelicopter:OnAfterDead( From, Event, To, GroupObject )
  --          --self:F( { GroupObject = GroupObject:GetName() } )
  --        end
  --
  --
  -- ===
  -- 
  -- @field #SET_OPSGROUP SET_OPSGROUP
  -- 
  SET_OPSGROUP = {
    ClassName = "SET_OPSGROUP",
    Filter = {
      Coalitions    = nil,
      Categories    = nil,
      Countries     = nil,
      GroupPrefixes = nil,
    },
    FilterMeta = {
      Coalitions = {
        red     = coalition.side.RED,
        blue    = coalition.side.BLUE,
        neutral = coalition.side.NEUTRAL,
      },
      Categories = {
        plane      = Group.Category.AIRPLANE,
        helicopter = Group.Category.HELICOPTER,
        ground     = Group.Category.GROUND,
        ship       = Group.Category.SHIP,
      },
    }, -- FilterMeta
  }


  --- Creates a new SET_OPSGROUP object, building a set of groups belonging to a coalitions, categories, countries, types or with defined prefix names.
  -- @param #SET_OPSGROUP self
  -- @return #SET_OPSGROUP self
  function SET_OPSGROUP:New()

    -- Inherit SET_BASE.
    local self = BASE:Inherit(self, SET_BASE:New(_DATABASE.GROUPS)) -- #SET_OPSGROUP

    -- Include non activated 
    self:FilterActive( false )

    return self
  end

  --- Gets a **new** set that only contains alive groups.
  -- @param #SET_OPSGROUP self
  -- @return #SET_OPSGROUP self
  function SET_OPSGROUP:GetAliveSet()

    local AliveSet = SET_OPSGROUP:New()

    -- Clean the Set before returning with only the alive Groups.
    for GroupName, GroupObject in pairs(self.Set) do    
      local GroupObject=GroupObject --Wrapper.Group#GROUP
      
      if GroupObject and GroupObject:IsAlive() then      
        AliveSet:Add(GroupName, GroupObject)
      end
    end

    return AliveSet.Set or {}
  end
  
  --- Adds a @{Core.Base#BASE} object in the @{Core.Set#SET_BASE}, using a given ObjectName as the index.
  -- @param #SET_BASE self
  -- @param #string ObjectName The name of the object.
  -- @param Core.Base#BASE Object The object itself.
  -- @return Core.Base#BASE The added BASE Object.
  function SET_OPSGROUP:Add(ObjectName, Object)
    --self:T(( { ObjectName = ObjectName, Object = Object } )

    -- Ensure that the existing element is removed from the Set before a new one is inserted to the Set
    if self.Set[ObjectName] then
      self:Remove(ObjectName, true)
    end
    
    local object=nil --Ops.OpsGroup#OPSGROUP
    if Object:IsInstanceOf("GROUP") then
    
      ---
      -- GROUP Object
      ---
    
      -- Fist, look up in the DATABASE if an OPSGROUP already exists.
      object=_DATABASE:FindOpsGroup(ObjectName)
    
      if not object then
      
        if Object:IsShip() then
          object=NAVYGROUP:New(Object)
        elseif Object:IsGround() then
          object=ARMYGROUP:New(Object)
        elseif Object:IsAir() then
          object=FLIGHTGROUP:New(Object)
        else
          env.error("ERROR: Unknown category of group object!")
        end
      end
      
    elseif Object:IsInstanceOf("OPSGROUP") then
      -- We already have an OPSGROUP.
      object=Object
    else
      env.error("ERROR: Object must be a GROUP or OPSGROUP!")
    end
    
    -- Add object to set.
    self.Set[ObjectName]=object

    -- Add Object name to Index.
    table.insert(self.Index, ObjectName)

    -- Trigger Added event.
    self:Added(ObjectName, object)
  end
  
  --- Adds a @{Core.Base#BASE} object in the @{Core.Set#SET_BASE}, using the Object Name as the index.
  -- @param #SET_BASE self
  -- @param Ops.OpsGroup#OPSGROUP Object Ops group
  -- @return Core.Base#BASE The added BASE Object.
  function SET_OPSGROUP:AddObject(Object)
    self:Add(Object.groupname, Object)
  end  

  --- Add a GROUP or OPSGROUP object to the set.
  -- **NOTE** that an OPSGROUP is automatically created from the GROUP if it does not exist already.
  -- @param Core.Set#SET_OPSGROUP self
  -- @param Wrapper.Group#GROUP group The GROUP which should be added to the set. Can also be given as an #OPSGROUP object.
  -- @return Core.Set#SET_OPSGROUP self
  function SET_OPSGROUP:AddGroup(group)
  
    local groupname=group:GetName()
    
    self:Add(groupname, group )

    return self
  end

  --- Add GROUP(s) or OPSGROUP(s) to the set.
  -- @param Core.Set#SET_OPSGROUP self
  -- @param #string AddGroupNames A single name or an array of GROUP names.
  -- @return Core.Set#SET_OPSGROUP self
  function SET_OPSGROUP:AddGroupsByName( AddGroupNames )

    local AddGroupNamesArray = ( type( AddGroupNames ) == "table" ) and AddGroupNames or { AddGroupNames }

    for AddGroupID, AddGroupName in pairs( AddGroupNamesArray ) do
      self:Add(AddGroupName, GROUP:FindByName(AddGroupName))
    end

    return self
  end

  --- Remove GROUP(s) or OPSGROUP(s) from the set.
  -- @param Core.Set#SET_OPSGROUP self
  -- @param Wrapper.Group#GROUP RemoveGroupNames A single name or an array of GROUP names.
  -- @return Core.Set#SET_OPSGROUP self
  function SET_OPSGROUP:RemoveGroupsByName( RemoveGroupNames )

    local RemoveGroupNamesArray = ( type( RemoveGroupNames ) == "table" ) and RemoveGroupNames or { RemoveGroupNames }

    for RemoveGroupID, RemoveGroupName in pairs( RemoveGroupNamesArray ) do
      self:Remove( RemoveGroupName )
    end

    return self
  end

  --- Finds an OPSGROUP based on the group name.
  -- @param #SET_OPSGROUP self
  -- @param #string GroupName Name of the group.
  -- @return Ops.OpsGroup#OPSGROUP The found OPSGROUP (FLIGHTGROUP, ARMYGROUP or NAVYGROUP) or `#nil` if the group is not in the set.
  function SET_OPSGROUP:FindGroup(GroupName)
    local GroupFound = self.Set[GroupName]
    return GroupFound
  end
  
  --- Finds a FLIGHTGROUP based on the group name.
  -- @param #SET_OPSGROUP self
  -- @param #string GroupName Name of the group.
  -- @return Ops.FlightGroup#FLIGHTGROUP The found FLIGHTGROUP or `#nil` if the group is not in the set.
  function SET_OPSGROUP:FindFlightGroup(GroupName)
    local GroupFound = self:FindGroup(GroupName)
    return GroupFound
  end
  
  --- Finds a ARMYGROUP based on the group name.
  -- @param #SET_OPSGROUP self
  -- @param #string GroupName Name of the group.
  -- @return Ops.ArmyGroup#ARMYGROUP The found ARMYGROUP or `#nil` if the group is not in the set.
  function SET_OPSGROUP:FindArmyGroup(GroupName)
    local GroupFound = self:FindGroup(GroupName)
    return GroupFound
  end  


  --- Finds a NAVYGROUP based on the group name.
  -- @param #SET_OPSGROUP self
  -- @param #string GroupName Name of the group.
  -- @return Ops.NavyGroup#NAVYGROUP The found NAVYGROUP or `#nil` if the group is not in the set.
  function SET_OPSGROUP:FindNavyGroup(GroupName)
    local GroupFound = self:FindGroup(GroupName)
    return GroupFound
  end  
    
  --- Builds a set of groups of coalitions.
  -- Possible current coalitions are red, blue and neutral.
  -- @param #SET_OPSGROUP self
  -- @param #string Coalitions Can take the following values: "red", "blue", "neutral" or combinations as a table, for example `{"red", "neutral"}`.
  -- @param #boolean Clear If `true`, clear any previously defined filters.
  -- @return #SET_OPSGROUP self
  function SET_OPSGROUP:FilterCoalitions(Coalitions, Clear)
  
    -- Create an empty set.
    if Clear or not self.Filter.Coalitions then
      self.Filter.Coalitions={}
    end
    
    -- Ensure we got a table.
    if type(Coalitions)~="table" then
      Coalitions = {Coalitions}
    end
    
    -- Set filter.
    for CoalitionID, Coalition in pairs( Coalitions ) do
      self.Filter.Coalitions[Coalition] = Coalition
    end
    
    return self
  end


  --- Builds a set of groups out of categories.
  -- 
  -- Possible current categories are:
  -- 
  -- * "plane" for fixed wing groups
  -- * "helicopter" for rotary wing groups
  -- * "ground" for ground groups
  -- * "ship" for naval groups
  -- 
  -- @param #SET_OPSGROUP self
  -- @param #string Categories Can take the following values: "plane", "helicopter", "ground", "ship" or combinations as a table, for example `{"plane", "helicopter"}`.
  -- @param #boolean Clear If `true`, clear any previously defined filters.
  -- @return #SET_OPSGROUP self
  function SET_OPSGROUP:FilterCategories( Categories, Clear )
  
    if Clear or not self.Filter.Categories then
      self.Filter.Categories={}
    end
    
    if type(Categories)~="table" then
      Categories={Categories}
    end
    
    for CategoryID, Category in pairs( Categories ) do
      self.Filter.Categories[Category] = Category
    end
    
    return self
  end

  --- Builds a set of groups out of ground category.
  -- @param #SET_OPSGROUP self
  -- @return #SET_OPSGROUP self
  function SET_OPSGROUP:FilterCategoryGround()
    self:FilterCategories("ground")
    return self
  end

  --- Builds a set of groups out of airplane category.
  -- @param #SET_OPSGROUP self
  -- @return #SET_OPSGROUP self
  function SET_OPSGROUP:FilterCategoryAirplane()
    self:FilterCategories("plane")
    return self
  end
  
  --- Builds a set of groups out of aicraft category (planes and helicopters).
  -- @param #SET_OPSGROUP self
  -- @return #SET_OPSGROUP self
  function SET_OPSGROUP:FilterCategoryAircraft()
    self:FilterCategories({"plane", "helicopter"})
    return self
  end  

  --- Builds a set of groups out of helicopter category.
  -- @param #SET_OPSGROUP self
  -- @return #SET_OPSGROUP self
  function SET_OPSGROUP:FilterCategoryHelicopter()
    self:FilterCategories( "helicopter" )
    return self
  end

  --- Builds a set of groups out of ship category.
  -- @param #SET_OPSGROUP self
  -- @return #SET_OPSGROUP self
  function SET_OPSGROUP:FilterCategoryShip()
    self:FilterCategories("ship")
    return self
  end

  --- Builds a set of groups of defined countries.
  -- @param #SET_OPSGROUP self
  -- @param #string Countries Can take those country strings known within DCS world.
  -- @param #boolean Clear If `true`, clear any previously defined filters.
  -- @return #SET_OPSGROUP self
  function SET_OPSGROUP:FilterCountries(Countries, Clear)
  
    -- Create empty table if necessary.
    if Clear or not self.Filter.Countries then
      self.Filter.Countries = {}
    end
    
    -- Ensure input is a table.
    if type(Countries)~="table" then
      Countries={Countries}
    end
    
    -- Set filter.
    for CountryID, Country in pairs( Countries ) do
      self.Filter.Countries[Country] = Country
    end
    
    return self
  end


  --- Builds a set of groups that contain the given string in their group name.
  -- **Attention!** Bad naming convention as this **does not** filter only **prefixes** but all groups that **contain** the string. 
  -- @param #SET_OPSGROUP self
  -- @param #string Prefixes The string pattern(s) that needs to be contained in the group name. Can also be passed as a `#table` of strings.
  -- @param #boolean Clear If `true`, clear any previously defined filters.
  -- @return #SET_OPSGROUP self
  function SET_OPSGROUP:FilterPrefixes(Prefixes, Clear)
  
    -- Create emtpy table if necessary.
    if Clear or not self.Filter.GroupPrefixes then
      self.Filter.GroupPrefixes={}
    end
    
    -- Ensure we have a table.
    if type(Prefixes)~="table" then
      Prefixes={Prefixes}
    end
    
    -- Set group prefixes.
    for PrefixID, Prefix in pairs(Prefixes) do
      self.Filter.GroupPrefixes[Prefix]=Prefix
    end
    
    return self
  end

  --- Builds a set of groups that are only active.
  -- Only the groups that are active will be included within the set.
  -- @param #SET_OPSGROUP self
  -- @param #boolean Active (optional) Include only active groups to the set.
  -- Include inactive groups if you provide false.
  -- @return #SET_OPSGROUP self
  -- @usage
  --
  -- -- Include only active groups to the set.
  -- GroupSet = SET_OPSGROUP:New():FilterActive():FilterStart()
  --
  -- -- Include only active groups to the set of the blue coalition, and filter one time.
  -- GroupSet = SET_OPSGROUP:New():FilterActive():FilterCoalition( "blue" ):FilterOnce()
  --
  -- -- Include only active groups to the set of the blue coalition, and filter one time.
  -- -- Later, reset to include back inactive groups to the set.
  -- GroupSet = SET_OPSGROUP:New():FilterActive():FilterCoalition( "blue" ):FilterOnce()
  -- ... logic ...
  -- GroupSet = SET_OPSGROUP:New():FilterActive( false ):FilterCoalition( "blue" ):FilterOnce()
  --
  function SET_OPSGROUP:FilterActive( Active )
    Active = Active or not ( Active == false )
    self.Filter.Active = Active
    return self
  end


  --- Starts the filtering.
  -- @param #SET_OPSGROUP self
  -- @return #SET_OPSGROUP self
  function SET_OPSGROUP:FilterStart()

    if _DATABASE then
      self:_FilterStart()
      self:HandleEvent( EVENTS.Birth, self._EventOnBirth )
      self:HandleEvent( EVENTS.Dead, self._EventOnDeadOrCrash )
      self:HandleEvent( EVENTS.Crash, self._EventOnDeadOrCrash )
      self:HandleEvent( EVENTS.RemoveUnit, self._EventOnDeadOrCrash )
      self:HandleEvent( EVENTS.UnitLost, self._EventOnDeadOrCrash )
    end

    return self
  end
  
  --- Activate late activated groups in the set.
  -- @param #SET_OPSGROUP self
  -- @param #number Delay Delay in seconds.
  -- @return #SET_OPSGROUP self
  function SET_OPSGROUP:Activate(Delay)
    local Set = self:GetSet()
    for GroupID, GroupData in pairs(Set) do
      local group=GroupData --Ops.OpsGroup#OPSGROUP
      if group and group:IsAlive()==false then
        group:Activate(Delay)
      end
    end
    return self
  end  

  --- Handles the OnBirth event for the Set.
  -- @param #SET_OPSGROUP self
  -- @param Core.Event#EVENTDATA Event Event data.
function SET_OPSGROUP:_EventOnBirth(Event)
    --self:F3( { Event } )

    if Event.IniDCSUnit and Event.IniDCSGroup then
        local DCSgroup = Event.IniDCSGroup --DCS#Group

        -- group:CountAliveUnits() alternative as this fails for Respawn/Teleport
        local CountAliveActive = 0
        for index, data in pairs(DCSgroup:getUnits()) do
            if data:isExist() and data:isActive() then
                CountAliveActive = CountAliveActive + 1
            end
        end

        if DCSgroup:getInitialSize() == DCSgroup:getSize() then

            local groupname, group = self:AddInDatabase(Event)

            -- group:CountAliveUnits() alternative
            if group and CountAliveActive == DCSgroup:getInitialSize() then
                if group and self:IsIncludeObject(group) then
                    self:Add(groupname, group)
                end
            end
        end
    end
  end

  --- Handles the OnDead or OnCrash event for alive groups set.
  -- Note: The GROUP object in the SET_OPSGROUP collection will only be removed if the last unit is destroyed of the GROUP.
  -- @param #SET_OPSGROUP self
  -- @param Core.Event#EVENTDATA Event
  function SET_OPSGROUP:_EventOnDeadOrCrash( Event )
    --self:F( { Event } )

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
  -- @param #SET_OPSGROUP self
  -- @param Core.Event#EVENTDATA Event Event data.
  -- @return #string The name of the GROUP.
  -- @return Wrapper.Group#GROUP The GROUP object.
  function SET_OPSGROUP:AddInDatabase( Event )
  
    if Event.IniObjectCategory==Object.Category.UNIT then
    
      if not self.Database[Event.IniDCSGroupName] then
        self.Database[Event.IniDCSGroupName] = GROUP:Register( Event.IniDCSGroupName )
      end
      
    end

    return Event.IniDCSGroupName, self.Database[Event.IniDCSGroupName]
  end

  --- Handles the Database to check on any event that Object exists in the Database.
  -- This is required, because sometimes the _DATABASE event gets called later than the SET_BASE event or vise versa!
  -- @param #SET_OPSGROUP self
  -- @param Core.Event#EVENTDATA Event Event data table.
  -- @return #string The name of the GROUP.
  -- @return Wrapper.Group#GROUP The GROUP object.
  function SET_OPSGROUP:FindInDatabase(Event)
    return Event.IniDCSGroupName, self.Database[Event.IniDCSGroupName]
  end

  --- Iterate the set and call an iterator function for each OPSGROUP object.
  -- @param #SET_OPSGROUP self
  -- @param #function IteratorFunction The function that will be called for all OPSGROUPs in the set. **NOTE** that the function must have the OPSGROUP as first parameter!
  -- @param ... (Optional) arguments passed to the `IteratorFunction`.
  -- @return #SET_OPSGROUP self
  function SET_OPSGROUP:ForEachGroup( IteratorFunction, ... )

    self:ForEach(IteratorFunction, arg, self:GetSet())

    return self
  end

  --- Check include object.
  -- @param #SET_OPSGROUP self
  -- @param Wrapper.Group#GROUP MGroup The group that is checked for inclusion.
  -- @return #SET_OPSGROUP self
  function SET_OPSGROUP:IsIncludeObject(MGroup)
  
    -- Assume it is and check later if not.
    local MGroupInclude=true

    -- Filter active.
    if self.Filter.Active~=nil then
    
      local MGroupActive = false
      
      if self.Filter.Active==false or (self.Filter.Active==true and MGroup:IsActive()==true) then
        MGroupActive = true
      end
      
      MGroupInclude = MGroupInclude and MGroupActive
    end

    -- Filter coalitions.
    if self.Filter.Coalitions and MGroupInclude then
    
      local MGroupCoalition = false
      
      for CoalitionID, CoalitionName in pairs( self.Filter.Coalitions ) do
        if self.FilterMeta.Coalitions[CoalitionName] and self.FilterMeta.Coalitions[CoalitionName]==MGroup:GetCoalition() then
          MGroupCoalition = true      
        end
      end
      
      MGroupInclude = MGroupInclude and MGroupCoalition
    end

    -- Filter categories.
    if self.Filter.Categories and MGroupInclude then
    
      local MGroupCategory = false
      
      for CategoryID, CategoryName in pairs( self.Filter.Categories ) do
        if self.FilterMeta.Categories[CategoryName] and self.FilterMeta.Categories[CategoryName]==MGroup:GetCategory() then
          MGroupCategory = true
        end
      end
      
      MGroupInclude = MGroupInclude and MGroupCategory
    end

    -- Filter countries.
    if self.Filter.Countries and MGroupInclude then
      local MGroupCountry = false
      for CountryID, CountryName in pairs( self.Filter.Countries ) do
        if country.id[CountryName] == MGroup:GetCountry() then
          MGroupCountry = true
        end
      end
      MGroupInclude = MGroupInclude and MGroupCountry
    end

    -- Filter "prefixes".
    if self.Filter.GroupPrefixes and MGroupInclude then
    
      local MGroupPrefix = false
      
      for GroupPrefixId, GroupPrefix in pairs( self.Filter.GroupPrefixes ) do
        if string.find( MGroup:GetName(), GroupPrefix:gsub ("-", "%%-"), 1 ) then --Not sure why "-" is replaced by "%-" ?! - So we can still match group names with a dash in them
          MGroupPrefix = true
        end
      end
      
      MGroupInclude = MGroupInclude and MGroupPrefix
    end
    
    if self.Filter.Functions and MGroupInclude then
      local MClientFunc = self:_EvalFilterFunctions(MGroup)
      MGroupInclude = MGroupInclude and MClientFunc
    end
    
    return MGroupInclude
  end
  
end
            
do -- SET_SCENERY

  ---
  -- @type SET_SCENERY
  -- @extends Core.Set#SET_BASE

  --- Mission designers can use the SET_SCENERY class to build sets of scenery belonging to certain:
  --
  --  * Zone Sets
  --
  -- ## SET_SCENERY constructor
  --
  -- Create a new SET_SCENERY object with the @{#SET_SCENERY.New} method:
  --
  --    * @{#SET_SCENERY.New}: Creates a new SET_SCENERY object.
  --
  -- ## Add or Remove SCENERY(s) from SET_SCENERY
  --
  -- SCENERYs can be added and removed using the @{Core.Set#SET_SCENERY.AddSceneryByName} and @{Core.Set#SET_SCENERY.RemoveSceneryByName} respectively.
  -- These methods take a single SCENERY name or an array of SCENERY names to be added or removed from SET_SCENERY.
  --
  -- ## SET_SCENERY filter criteria
  --
  -- N/A at the moment
  --    
  -- ## SET_SCENERY iterators
  --
  -- Once the filters have been defined and the SET_SCENERY has been built, you can iterate the SET_SCENERY with the available iterator methods.
  -- The iterator methods will walk the SET_SCENERY set, and call for each element within the set a function that you provide.
  -- The following iterator methods are currently available within the SET_SCENERY:
  --
  --   * @{#SET_SCENERY.ForEachScenery}: Calls a function for each alive object it finds within the SET_SCENERY.
  --
  -- ## SET_SCENERY atomic methods
  --
  -- N/A at the moment
  --
  -- ===
  -- @field #SET_SCENERY SET_SCENERY
  SET_SCENERY = {
    ClassName = "SET_SCENERY",
    Scenerys = {},
    Filter = {
      SceneryPrefixes = nil,
      SceneryRoles = nil,
      Zones = nil,
    },
  }

  --- Creates a new SET_SCENERY object. Scenery is **not** auto-registered in the Moose database, there are too many objects on each map. Hence we need to find them first. For this we are using a SET_ZONE. 
  -- @param #SET_SCENERY self
  -- @param #SET_ZONE ZoneSet SET_ZONE of ZONE objects as created by right-clicks on the map in the mission editor, choosing "assign as...". Rename the zones for grouping purposes, e.g. all sections of a bridge as "Bridge-1" to "Bridge-3".
  -- @return #SET_SCENERY
  -- @usage
  -- -- Define a new SET_SCENERY Object. This Object will contain a reference to all added Scenery Objects.
  --    ZoneSet = SET_ZONE:New():FilterPrefixes("Bridge"):FilterOnce()
  --    mysceneryset = SET_SCENERY:New(ZoneSet)
  function SET_SCENERY:New(ZoneSet)
  
    local zoneset = {}  
      -- Inherits from BASE
    local self = BASE:Inherit( self, SET_BASE:New( zoneset ) ) -- Core.Set#SET_SCENERY
    
    local zonenames = {}
    
    if ZoneSet then
      for _,_zone in pairs(ZoneSet.Set) do
        --self:T(("Zone type handed: "..tostring(_zone.ClassName))
        table.insert(zonenames,_zone:GetName())
      end   
      self:AddSceneryByName(zonenames)
    end
    
    return self
  end
  
  --- Creates a new SET_SCENERY object. Scenery is **not** auto-registered in the Moose database, there are too many objects on each map. Hence we need to find them first. For this we scan the zone. 
  -- @param #SET_SCENERY self
  -- @param Core.Zone#ZONE Zone The zone to be scanned. Can be a ZONE_RADIUS (round) or a ZONE_POLYGON (e.g. Quad-Point)
  -- @return #SET_SCENERY
  function SET_SCENERY:NewFromZone(Zone)
    local zone = Zone -- Core.Zone#ZONE_RADIUS
    if type(Zone) == "string" then
      zone = ZONE:FindByName(Zone)
    end
    zone:Scan({Object.Category.SCENERY})
    return zone:GetScannedSetScenery()
  end
  
  --- Add SCENERY(s) to SET_SCENERY.
  -- @param #SET_SCENERY self
  -- @param Wrapper.Scenery#SCENERY AddScenery A single SCENERY object.
  -- @return #SET_SCENERY self
  function SET_SCENERY:AddScenery( AddScenery )
    --self:F2( AddScenery:GetName() )

    self:Add( AddScenery:GetName(), AddScenery )

    return self
  end


  --- Add SCENERY(s) to SET_SCENERY.
  -- @param #SET_SCENERY self
  -- @param #string AddSceneryNames A single name or an array of SCENERY zone names.
  -- @return #SET_SCENERY self
  function SET_SCENERY:AddSceneryByName( AddSceneryNames )

    local AddSceneryNamesArray = ( type( AddSceneryNames ) == "table" ) and AddSceneryNames or { AddSceneryNames }

    --self:T(( AddSceneryNamesArray )
    for AddSceneryID, AddSceneryName in pairs( AddSceneryNamesArray ) do
      self:Add( AddSceneryName, SCENERY:FindByZoneName( AddSceneryName ) )
    end

    return self
  end

  --- Remove SCENERY(s) from SET_SCENERY.
  -- @param Core.Set#SET_SCENERY self
  -- @param Wrapper.Scenery#SCENERY RemoveSceneryNames A single name or an array of SCENERY zone names.
  -- @return self
  function SET_SCENERY:RemoveSceneryByName( RemoveSceneryNames )

    local RemoveSceneryNamesArray = ( type( RemoveSceneryNames ) == "table" ) and RemoveSceneryNames or { RemoveSceneryNames }

    for RemoveSceneryID, RemoveSceneryName in pairs( RemoveSceneryNamesArray ) do
      self:Remove( RemoveSceneryName )
    end

    return self
  end

  --- Finds a Scenery in the SET, based on the Scenery Name.
  -- @param #SET_SCENERY self
  -- @param #string SceneryName
  -- @return Wrapper.Scenery#SCENERY The found Scenery.
  function SET_SCENERY:FindScenery( SceneryName )
    local SceneryFound = self.Set[SceneryName]
    return SceneryFound
  end

   --- Builds a set of scenery objects in zones.
  -- @param #SET_SCENERY self
  -- @param #table Zones Table of Core.Zone#ZONE Zone objects, or a Core.Set#SET_ZONE
  -- @return #SET_SCENERY self
  function SET_SCENERY:FilterZones( Zones )
    if not self.Filter.Zones then
      self.Filter.Zones = {}
    end
    local zones = {}
    if Zones.ClassName and Zones.ClassName == "SET_ZONE" then
      zones = Zones.Set
    elseif type( Zones ) ~= "table" or (type( Zones ) == "table" and Zones.ClassName ) then
      self:E("***** FilterZones needs either a table of ZONE Objects or a SET_ZONE as parameter!")
      return self     
    else
      zones = Zones
    end
    for _,Zone in pairs( zones ) do
      local zonename = Zone:GetName()
      --self:T((zonename)
      self.Filter.Zones[zonename] = Zone
    end
    return self
  end

  --- Builds a set of SCENERYs that contain the given string in their name.
  -- **Attention!** Bad naming convention as this **does not** filter only **prefixes** but all scenery that **contain** the string. 
  -- @param #SET_SCENERY self
  -- @param #string Prefixes The string pattern(s) that need to be contained in the scenery name. Can also be passed as a `#table` of strings.
  -- @return #SET_SCENERY self
  function SET_SCENERY:FilterPrefixes( Prefixes )
    if not self.Filter.SceneryPrefixes then
      self.Filter.SceneryPrefixes = {}
    end
    if type( Prefixes ) ~= "table" then
      Prefixes = { Prefixes }
    end
    for PrefixID, Prefix in pairs( Prefixes ) do
      --self:T((Prefix)
      self.Filter.SceneryPrefixes[Prefix] = Prefix
    end
    return self
  end
  
  --- Builds a set of SCENERYs that **contain** an exact match of the "ROLE" property.
  -- @param #SET_SCENERY self
  -- @param #string Role The string pattern(s) that needs to exactly match the scenery "ROLE" property from the ME quad-zone properties. Can also be passed as a `#table` of strings.
  -- @return #SET_SCENERY self
  function SET_SCENERY:FilterRoles( Role )
    if not self.Filter.SceneryRoles then
      self.Filter.SceneryRoles = {}
    end
    if type( Role ) ~= "table" then
      Role = { Role }
    end
    for PrefixID, Prefix in pairs( Role ) do
      --self:T(Prefix)
      self.Filter.SceneryRoles[Prefix] = Prefix
    end
    return self
  end
  
  --- Iterate the SET_SCENERY and count how many SCENERYSs are alive.
  -- @param #SET_SCENERY self
  -- @return #number The number of SCENERYSs alive.
  function SET_SCENERY:CountAlive()

    local Set = self:GetSet()

    local CountU = 0
    for UnitID, UnitData in pairs(Set) do
      if UnitData and UnitData:IsAlive() then
        CountU = CountU + 1
      end

    end

    return CountU
  end
  
  --- Get a table of alive objects.
  -- @param #SET_SCENERY self
  -- @return #table Table of alive objects
  -- @return Core.Set#SET_SCENERY SET of alive objects
  function SET_SCENERY:GetAliveSet()
    --self:F2()

    local AliveSet = SET_SCENERY:New()

    -- Clean the Set before returning with only the alive Groups.
    for GroupName, GroupObject in pairs( self.Set ) do
      local GroupObject = GroupObject -- Wrapper.Group#GROUP
      if GroupObject then
        if GroupObject:IsAlive() then
          AliveSet:Add( GroupName, GroupObject )
        end
      end
    end

    return AliveSet.Set or {}, AliveSet
  end
  
  --- Iterate the SET_SCENERY and call an iterator function for each **alive** SCENERY, providing the SCENERY and optional parameters.
  -- @param #SET_SCENERY self
  -- @param #function IteratorFunction The function that will be called when there is an alive SCENERY in the SET_SCENERY. The function needs to accept a SCENERY parameter.
  -- @return #SET_SCENERY self
  function SET_SCENERY:ForEachScenery( IteratorFunction, ... )
    --self:F2( arg )
    self:ForEach( IteratorFunction, arg, self:GetSet() )
    return self
  end

  --- Get the center coordinate of the SET_SCENERY.
  -- @param #SET_SCENERY self
  -- @return Core.Point#COORDINATE The center coordinate of all the objects in the set.
  function SET_SCENERY:GetCoordinate()
    --[[
    local Coordinate = COORDINATE:New({0,0,0})

    local Item = self:GetRandomSurely()
    
    if Item then
      Coordinate:GetCoordinate()
    end
    --]]
    
    local Coordinate = self:GetFirst():GetCoordinate()
    
    local x1 = Coordinate.x
    local x2 = Coordinate.x
    local y1 = Coordinate.y
    local y2 = Coordinate.y
    local z1 = Coordinate.z
    local z2 = Coordinate.z

    for SceneryName, SceneryData in pairs( self:GetSet() ) do

      local Scenery = SceneryData -- Wrapper.Scenery#SCENERY
      local Coordinate = Scenery:GetCoordinate()

      x1 = ( Coordinate.x < x1 ) and Coordinate.x or x1
      x2 = ( Coordinate.x > x2 ) and Coordinate.x or x2
      y1 = ( Coordinate.y < y1 ) and Coordinate.y or y1
      y2 = ( Coordinate.y > y2 ) and Coordinate.y or y2
      z1 = ( Coordinate.y < z1 ) and Coordinate.z or z1
      z2 = ( Coordinate.y > z2 ) and Coordinate.z or z2

    end

    Coordinate.x = ( x2 - x1 ) / 2 + x1
    Coordinate.y = ( y2 - y1 ) / 2 + y1
    Coordinate.z = ( z2 - z1 ) / 2 + z1

    --self:F( { Coordinate = Coordinate } )
    return Coordinate

  end

  --- [Internal] Determine if an object is to be included in the SET
  -- @param #SET_SCENERY self
  -- @param Wrapper.Scenery#SCENERY MScenery
  -- @return #SET_SCENERY self
  function SET_SCENERY:IsIncludeObject( MScenery )
    --self:T(( MScenery.SceneryName )

    local MSceneryInclude = true
    
    if MScenery then
      local MSceneryName = MScenery:GetName()
      
      -- Filter Prefixes
      if self.Filter.Prefixes then
        local MSceneryPrefix = false
        for ZonePrefixId, ZonePrefix in pairs( self.Filter.Prefixes ) do
          --self:T(( { "Prefix:", string.find( MSceneryName, ZonePrefix, 1 ), ZonePrefix } )
          if string.find( MSceneryName, ZonePrefix, 1 ) then
            MSceneryPrefix = true
          end
        end
        --self:T(( { "Evaluated Prefix", MSceneryPrefix } )
        MSceneryInclude = MSceneryInclude and MSceneryPrefix
      end
      
      if self.Filter.Zones then
        local MSceneryZone = false
        for ZoneName, Zone in pairs( self.Filter.Zones ) do
          --self:T(( "Zone:", ZoneName )
          local coord = MScenery:GetCoordinate()
          if coord and Zone:IsCoordinateInZone(coord) then
            MSceneryZone = true
          end
          --self:T(( { "Evaluated Zone", MSceneryZone } )
        end
        MSceneryInclude = MSceneryInclude and MSceneryZone
      end

      -- Filter Roles
      if self.Filter.SceneryRoles then
        local MSceneryRole = false
        local Role = MScenery:GetProperty("ROLE") or "none"
        for ZoneRoleId, ZoneRole in pairs( self.Filter.SceneryRoles ) do
          --self:T(( { "Role:", ZoneRole, Role } )
          if ZoneRole == Role then
            MSceneryRole = true
          end
        end
        --self:T(( { "Evaluated Role ", MSceneryRole } )
        MSceneryInclude = MSceneryInclude and MSceneryRole
      end
    end
    
    if self.Filter.Functions and MSceneryInclude then
      local MClientFunc = self:_EvalFilterFunctions(MScenery)
      MSceneryInclude = MSceneryInclude and MClientFunc
    end
    
    --self:T(2( MSceneryInclude )
    return MSceneryInclude
  end
  
  --- Filters for the defined collection.
  -- @param #SET_SCENERY self
  -- @return #SET_SCENERY self
  function SET_SCENERY:FilterOnce()

    for ObjectName, Object in pairs( self:GetSet() ) do
      --self:T((ObjectName)
      if self:IsIncludeObject( Object ) then
        self:Add( ObjectName, Object )
      else
        self:Remove(ObjectName, true)
      end
    end

    return self --FilteredSet
  end
  
  
  --- Count overall initial (Life0) lifepoints of the SET objects.
  -- @param #SET_SCENERY self
  -- @return #number LIfe0Points
  function SET_SCENERY:GetLife0()
    local life0 = 0
    self:ForEachScenery(
      function(obj)
        local Obj = obj -- Wrapper.Scenery#SCENERY
        life0 = life0 + Obj:GetLife0()
      end
    )
    return life0
  end
  
  --- Count overall current lifepoints of the SET objects.
  -- @param #SET_SCENERY self
  -- @return #number LifePoints
  function SET_SCENERY:GetLife()
    local life = 0
    self:ForEachScenery(
      function(obj)
        local Obj = obj -- Wrapper.Scenery#SCENERY
        life = life + Obj:GetLife()
      end
    )
    return life
  end
  
  --- Calculate current relative lifepoints of the SET objects, i.e. Life divided by Life0 as percentage value, eg 75 meaning 75% alive. 
  -- **CAVEAT**: Some objects change their life value or "hitpoints" **after** the first hit. Hence we will adjust the Life0 value to 120% 
  -- of the last life value if life exceeds life0 ata any point.
  -- Thus we will get a smooth percentage decrease, if you use this e.g. as success criteria for a bombing task.
  -- @param #SET_SCENERY self
  -- @return #number LifePoints
  function SET_SCENERY:GetRelativeLife()
    local life = self:GetLife()
    local life0 = self:GetLife0()
    --self:T(2(string.format("Set Lifepoints: %d life0 | %d life",life0,life))
    local rlife = math.floor((life / life0) * 100)
    return rlife
  end
  
end

-- TODO SET_DYNAMICCARGO

do -- SET_DYNAMICCARGO
  
  ---
  -- @type SET_DYNAMICCARGO
  -- @field #table Filter Table of filters.
  -- @field #table Set Table of objects.
  -- @field #table Index Table of indices.
  -- @field #table List Unused table.
  -- @field Core.Scheduler#SCHEDULER CallScheduler.
  -- @field #SET_DYNAMICCARGO.Filters Filter Filters.
  -- @field #number ZoneTimerInterval.
  -- @field Core.Timer#TIMER ZoneTimer Timer for active filtering of zones.
  -- @extends Core.Set#SET_BASE
  
  ---
  -- @type SET_DYNAMICCARGO.Filters
  -- @field #string Coalitions
  -- @field #string Types
  -- @field #string Countries
  -- @field #string StaticPrefixes
  -- @field #string Zones
  
  --- The @{Core.Set#SET_DYNAMICCARGO} class defines the functions that define a collection of objects form @{Wrapper.DynamicCargo#DYNAMICCARGO}.
  -- A SET provides iterators to iterate the SET.
  --- Mission designers can use the SET_DYNAMICCARGO class to build sets of cargos belonging to certain:
  --
  --  * Coalitions
  --  * Categories
  --  * Countries
  --  * Static types
  --  * Starting with certain prefix strings.
  --  * Etc.
  --
  -- ## SET_DYNAMICCARGO constructor
  --
  -- Create a new SET_DYNAMICCARGO object with the @{#SET_DYNAMICCARGO.New} method:
  --
  --    * @{#SET_DYNAMICCARGO.New}: Creates a new SET_DYNAMICCARGO object.
  --
  -- ## SET_DYNAMICCARGO filter criteria
  --
  -- You can set filter criteria to define the set of objects within the SET_DYNAMICCARGO.
  -- Filter criteria are defined by:
  --
  --    * @{#SET_DYNAMICCARGO.FilterCoalitions}: Builds the SET_DYNAMICCARGO with the objects belonging to the coalition(s).
  --    * @{#SET_DYNAMICCARGO.FilterTypes}: Builds the SET_DYNAMICCARGO with the cargos belonging to the statiy type name(s).
  --    * @{#SET_DYNAMICCARGO.FilterCountries}: Builds the SET_DYNAMICCARGO with the objects belonging to the country(ies).
  --    * @{#SET_DYNAMICCARGO.FilterNamePatterns}, @{#SET_DYNAMICCARGO.FilterPrefixes}: Builds the SET_DYNAMICCARGO with the cargo containing the same string(s) in their name. **Attention!** LUA regular expression apply here, so special characters in names like minus, dot, hash (#) etc might lead to unexpected results. 
  -- Have a read through here to understand the application of regular expressions: [LUA regular expressions](https://riptutorial.com/lua/example/20315/lua-pattern-matching)
  --    * @{#SET_DYNAMICCARGO.FilterZones}: Builds the SET_DYNAMICCARGO with the cargo within a @{Core.Zone#ZONE}.
  --    * @{#SET_DYNAMICCARGO.FilterFunction}: Builds the SET_DYNAMICCARGO with a custom condition.
  --    * @{#SET_DYNAMICCARGO.FilterCurrentOwner}: Builds the SET_DYNAMICCARGO with a specific owner name.
  --    * @{#SET_DYNAMICCARGO.FilterIsLoaded}: Builds the SET_DYNAMICCARGO which is in state LOADED.
  --    * @{#SET_DYNAMICCARGO.FilterIsNew}: Builds the SET_DYNAMICCARGO with is in state NEW.
  --    * @{#SET_DYNAMICCARGO.FilterIsUnloaded}: Builds the SET_DYNAMICCARGO with is in state UNLOADED.
  --    
  -- Once the filter criteria have been set for the SET\_DYNAMICCARGO, you can start and stop filtering using:
  --
  --   * @{#SET_DYNAMICCARGO.FilterStart}: Starts the continous filtering of the objects within the SET_DYNAMICCARGO.
  --   * @{#SET_DYNAMICCARGO.FilterStop}: Stops the continous filtering of the objects within the SET_DYNAMICCARGO.
  --   * @{#SET_DYNAMICCARGO.FilterOnce}: Filters once for the objects within the SET_DYNAMICCARGO.
  --
  -- ## SET_DYNAMICCARGO iterators
  --
  -- Once the filters have been defined and the SET\_DYNAMICCARGO has been built, you can iterate the SET\_DYNAMICCARGO with the available iterator methods.
  -- The iterator methods will walk the SET\_DYNAMICCARGO set, and call for each element within the set a function that you provide.
  -- The following iterator methods are currently available within the SET\_DYNAMICCARGO:
  --
  --   * @{#SET_DYNAMICCARGO.ForEach}: Calls a function for each alive dynamic cargo it finds within the SET\_DYNAMICCARGO.
  --
  -- ## SET_DYNAMICCARGO atomic methods
  --
  -- Various methods exist for a SET_DYNAMICCARGO to perform actions or calculations and retrieve results from the SET\_DYNAMICCARGO:
  --
  --   * @{#SET_DYNAMICCARGO.GetOwnerClientObjects}(): Retrieve the type names of the @{Wrapper.Static}s in the SET, delimited by a comma.
  --   * @{#SET_DYNAMICCARGO.GetOwnerNames}(): Retrieve the type names of the @{Wrapper.Static}s in the SET, delimited by a comma.
  --   * @{#SET_DYNAMICCARGO.GetStorageObjects}(): Retrieve the type names of the @{Wrapper.Static}s in the SET, delimited by a comma.  
  -- 
  -- ===
  -- @field #SET_DYNAMICCARGO SET_DYNAMICCARGO
  SET_DYNAMICCARGO = {
    ClassName = "SET_DYNAMICCARGO",
    Filter = {},
    Set = {},
    List = {},
    Index = {},
    Database = nil,
    CallScheduler = nil,
    Filter = {
      Coalitions = nil,
      Types = nil,
      Countries = nil,
      StaticPrefixes = nil,
      Zones = nil,
    },
    FilterMeta = {
      Coalitions = {
        red = coalition.side.RED,
        blue = coalition.side.BLUE,
        neutral = coalition.side.NEUTRAL,
      }
    },
    ZoneTimerInterval = 20,
    ZoneTimer = nil,
  }
  
  --- Creates a new SET_DYNAMICCARGO object, building a set of units belonging to a coalitions, categories, countries, types or with defined prefix names.
  -- @param #SET_DYNAMICCARGO self
  -- @return #SET_DYNAMICCARGO
  -- @usage
  -- -- Define a new SET_DYNAMICCARGO Object. This DBObject will contain a reference to all alive Statics.
  -- DBObject = SET_DYNAMICCARGO:New()
  function SET_DYNAMICCARGO:New()

    --- Inherits from BASE
    local self = BASE:Inherit( self, SET_BASE:New( _DATABASE.DYNAMICCARGO ) ) -- Core.Set#SET_DYNAMICCARGO

    return self
  end
  
  ---
  -- @param #SET_DYNAMICCARGO self
  -- @param Wrapper.DynamicCargo#DYNAMICCARGO DCargo
  -- @return #SET_DYNAMICCARGO self
  function SET_DYNAMICCARGO:IsIncludeObject( DCargo )
    --self:F2( DCargo )
    local DCargoInclude = true

    if self.Filter.Coalitions then
      local DCargoCoalition = false
      for CoalitionID, CoalitionName in pairs( self.Filter.Coalitions ) do
        --self:T2( { "Coalition:", DCargo:GetCoalition(), self.FilterMeta.Coalitions[CoalitionName], CoalitionName } )
        if self.FilterMeta.Coalitions[CoalitionName] and self.FilterMeta.Coalitions[CoalitionName] == DCargo:GetCoalition() then
          DCargoCoalition = true
        end
      end
      DCargoInclude = DCargoInclude and DCargoCoalition
    end

    if self.Filter.Types then
      local DCargoType = false
      for TypeID, TypeName in pairs( self.Filter.Types ) do
        --self:T2( { "Type:", DCargo:GetTypeName(), TypeName } )
        if TypeName == DCargo:GetTypeName() then
          DCargoType = true
        end
      end
      DCargoInclude = DCargoInclude and DCargoType
    end

    if self.Filter.Countries then
      local DCargoCountry = false
      for CountryID, CountryName in pairs( self.Filter.Countries ) do
        --self:T2( { "Country:", DCargo:GetCountry(), CountryName } )
        if country.id[CountryName] == DCargo:GetCountry() then
          DCargoCountry = true
        end
      end
      DCargoInclude = DCargoInclude and DCargoCountry
    end

    if self.Filter.StaticPrefixes then
      local DCargoPrefix = false
      for StaticPrefixId, StaticPrefix in pairs( self.Filter.StaticPrefixes ) do
        --self:T2( { "Prefix:", string.find( DCargo:GetName(), StaticPrefix, 1 ), StaticPrefix } )
        if string.find( DCargo:GetName(), StaticPrefix, 1 ) then
          DCargoPrefix = true
        end
      end
      DCargoInclude = DCargoInclude and DCargoPrefix
    end
    
    if self.Filter.Zones then
      local DCargoZone = false
      for ZoneName, Zone in pairs( self.Filter.Zones ) do
        --self:T2( "In zone: "..ZoneName )
        if DCargo and DCargo:IsInZone(Zone) then
          DCargoZone = true
        end
      end
      DCargoInclude = DCargoInclude and DCargoZone
    end
    
    if self.Filter.Functions and DCargoInclude then
      local MClientFunc = self:_EvalFilterFunctions(DCargo)
      DCargoInclude = DCargoInclude and MClientFunc
    end
    
    --self:T2( DCargoInclude )
    return DCargoInclude
  end
  
  --- Builds a set of dynamic cargo of defined coalitions.
  -- Possible current coalitions are red, blue and neutral.
  -- @param #SET_DYNAMICCARGO self
  -- @param #string Coalitions Can take the following values: "red", "blue", "neutral".
  -- @return #SET_DYNAMICCARGO self
  function SET_DYNAMICCARGO:FilterCoalitions( Coalitions )
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
  
  --- Builds a set of dynamic cargo of defined dynamic cargo type names.
  -- @param #SET_DYNAMICCARGO self
  -- @param #string Types Can take those type name strings known within DCS world.
  -- @return #SET_DYNAMICCARGO self
  function SET_DYNAMICCARGO:FilterTypes( Types )
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
  
  --- [User] Add a custom condition function.
  -- @function [parent=#SET_DYNAMICCARGO] FilterFunction
  -- @param #SET_DYNAMICCARGO self
  -- @param #function ConditionFunction If this function returns `true`, the object is added to the SET. The function needs to take a DYNAMICCARGO object as first argument.
  -- @param ... Condition function arguments if any.
  -- @return #SET_DYNAMICCARGO self
  -- @usage
  --          -- Image you want to exclude a specific DYNAMICCARGO from a SET:
  --          local cargoset = SET_DYNAMICCARGO:New():FilterCoalitions("blue"):FilterFunction(
  --          -- The function needs to take a DYNAMICCARGO object as first - and in this case, only - argument.
  --          function(dynamiccargo)
  --              local isinclude = true
  --              if dynamiccargo:GetName() == "Exclude Me" then isinclude = false end
  --              return isinclude
  --          end
  --          ):FilterOnce()
  --          BASE:I(cargoset:Flush())
  
  --- Builds a set of dynamic cargo of defined countries.
  -- Possible current countries are those known within DCS world.
  -- @param #SET_DYNAMICCARGO self
  -- @param #string Countries Can take those country strings known within DCS world.
  -- @return #SET_DYNAMICCARGO self
  function SET_DYNAMICCARGO:FilterCountries( Countries )
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

  --- Builds a set of DYNAMICCARGOs that contain the given string in their name.
  -- **Attention!** Bad naming convention as this **does not** filter only **prefixes** but all names that **contain** the string. LUA Regex applies.
  -- @param #SET_DYNAMICCARGO self
  -- @param #string Prefixes The string pattern(s) that need to be contained in the dynamic cargo name. Can also be passed as a `#table` of strings.
  -- @return #SET_DYNAMICCARGO self
  function SET_DYNAMICCARGO:FilterPrefixes( Prefixes )
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
  
  --- Builds a set of DYNAMICCARGOs that contain the given string in their name.
  -- **Attention!** LUA Regex applies!
  -- @param #SET_DYNAMICCARGO self
  -- @param #string Patterns The string pattern(s) that need to be contained in the dynamic cargo name. Can also be passed as a `#table` of strings.
  -- @return #SET_DYNAMICCARGO self
  function SET_DYNAMICCARGO:FilterNamePattern( Patterns )
    return self:FilterPrefixes(Patterns)
  end
   
  --- Builds a set of DYNAMICCARGOs that are in state DYNAMICCARGO.State.LOADED (i.e. is on board of a Chinook).
  -- @param #SET_DYNAMICCARGO self
  -- @return #SET_DYNAMICCARGO self
  function SET_DYNAMICCARGO:FilterIsLoaded()
    self:FilterFunction(
      function(cargo)
        if cargo and cargo.CargoState and cargo.CargoState == DYNAMICCARGO.State.LOADED then
          return true
        else
          return false
        end
      end
    )
    return self
  end
  
  --- Builds a set of DYNAMICCARGOs that are in state DYNAMICCARGO.State.LOADED (i.e. was on board of a Chinook previously and is now unloaded).
  -- @param #SET_DYNAMICCARGO self
  -- @return #SET_DYNAMICCARGO self
  function SET_DYNAMICCARGO:FilterIsUnloaded()
    self:FilterFunction(
      function(cargo)
        if cargo and cargo.CargoState and cargo.CargoState == DYNAMICCARGO.State.UNLOADED then
          return true
        else
          return false
        end
      end
    )
    return self
  end
  
  --- Builds a set of DYNAMICCARGOs that are in state DYNAMICCARGO.State.NEW (i.e. new and never loaded into a Chinook).
  -- @param #SET_DYNAMICCARGO self
  -- @return #SET_DYNAMICCARGO self
  function SET_DYNAMICCARGO:FilterIsNew()
    self:FilterFunction(
      function(cargo)
        if cargo and cargo.CargoState and cargo.CargoState == DYNAMICCARGO.State.NEW then
          return true
        else
          return false
        end
      end
    )
    return self
  end
  
  --- Builds a set of DYNAMICCARGOs that are owned at the moment by this player name.
  -- @param #SET_DYNAMICCARGO self
  -- @param #string PlayerName
  -- @return #SET_DYNAMICCARGO self
  function SET_DYNAMICCARGO:FilterCurrentOwner(PlayerName)
    self:FilterFunction(
      function(cargo)
        if cargo and cargo.Owner and string.find(cargo.Owner,PlayerName,1,true) then
          return true
        else
          return false
        end
      end
    )
    return self
  end
  
  --- Builds a set of dynamic cargo in zones.
  -- @param #SET_DYNAMICCARGO self
  -- @param #table Zones Table of Core.Zone#ZONE Zone objects, or a Core.Set#SET_ZONE
  -- @return #SET_DYNAMICCARGO self
  function SET_DYNAMICCARGO:FilterZones( Zones )
    if not self.Filter.Zones then
      self.Filter.Zones = {}
    end
    local zones = {}
    if Zones.ClassName and Zones.ClassName == "SET_ZONE" then
      zones = Zones.Set
    elseif type( Zones ) ~= "table" or (type( Zones ) == "table" and Zones.ClassName ) then
      self:E("***** FilterZones needs either a table of ZONE Objects or a SET_ZONE as parameter!")
      return self     
    else
      zones = Zones
    end
    for _,Zone in pairs( zones ) do
      local zonename = Zone:GetName()
      self.Filter.Zones[zonename] = Zone
    end
    return self
  end
  
  --- Starts the filtering.
  -- @param #SET_DYNAMICCARGO self
  -- @return #SET_DYNAMICCARGO self
  function SET_DYNAMICCARGO:FilterStart()
    if _DATABASE then
      self:HandleEvent( EVENTS.NewDynamicCargo, self._EventHandlerDCAdd )
      self:HandleEvent( EVENTS.DynamicCargoRemoved, self._EventHandlerDCRemove )
      if self.Filter.Zones then
        self.ZoneTimer = TIMER:New(self._ContinousZoneFilter,self)
        local timing = self.ZoneTimerInterval or 30
        self.ZoneTimer:Start(timing,timing)
      end
      self:_FilterStart()
    end

    return self
  end
  
    --- Stops the filtering.
  -- @param #SET_DYNAMICCARGO self
  -- @return #SET_DYNAMICCARGO self
  function SET_DYNAMICCARGO:FilterStop()
    if _DATABASE then
      self:UnHandleEvent( EVENTS.NewDynamicCargo)
      self:UnHandleEvent( EVENTS.DynamicCargoRemoved )
      if self.ZoneTimer and self.ZoneTimer:IsRunning() then
        self.ZoneTimer:Stop()
      end
    end

    return self
  end
  
  --- [Internal] Private function for use of continous zone filter
  -- @param #SET_DYNAMICCARGO self
  -- @return #SET_DYNAMICCARGO self
  function SET_DYNAMICCARGO:_ContinousZoneFilter()   
    local Database = _DATABASE.DYNAMICCARGO  
    for ObjectName, Object in pairs( Database ) do
      if self:IsIncludeObject( Object ) and self:IsNotInSet(Object) then
        self:Add( ObjectName, Object )
      elseif (not self:IsIncludeObject( Object )) and self:IsInSet(Object) then
        self:Remove(ObjectName)
      end
    end
    
    return self  
  end
  
  --- Handles the events for the Set.
  -- @param #SET_DYNAMICCARGO self
  -- @param Core.Event#EVENTDATA Event
  function SET_DYNAMICCARGO:_EventHandlerDCAdd( Event )
    if Event.IniDynamicCargo and Event.IniDynamicCargoName then
      if not _DATABASE.DYNAMICCARGO[Event.IniDynamicCargoName] then
        _DATABASE:AddDynamicCargo( Event.IniDynamicCargoName )
      end
      local ObjectName, Object = self:FindInDatabase( Event )
      if Object and self:IsIncludeObject( Object ) then
        self:Add( ObjectName, Object )
      end
    end
    
    return self
  end
  
   --- Handles the remove event for dynamic cargo set.
  -- @param #SET_DYNAMICCARGO self
  -- @param Core.Event#EVENTDATA Event
  function SET_DYNAMICCARGO:_EventHandlerDCRemove( Event )
    if Event.IniDCSUnitName then
      local ObjectName, Object = self:FindInDatabase( Event )
      if ObjectName then
        self:Remove( ObjectName )
      end
    end
    
    return self
  end
  
  --- Handles the Database to check on any event that Object exists in the Database.
  -- This is required, because sometimes the _DATABASE event gets called later than the SET_DYNAMICCARGO event or vise versa!
  -- @param #SET_DYNAMICCARGO self
  -- @param Core.Event#EVENTDATA Event
  -- @return #string The name of the DYNAMICCARGO
  -- @return Wrapper.DynamicCargo#DYNAMICCARGO The DYNAMICCARGO object
  function SET_DYNAMICCARGO:FindInDatabase( Event )
    return Event.IniDCSUnitName, self.Set[Event.IniDCSUnitName]
  end
  
  --- Set filter timer interval for FilterZones if using active filtering with FilterStart().
  -- @param #SET_DYNAMICCARGO self
  -- @param #number Seconds Seconds between check intervals, defaults to 30. **Caution** - do not be too agressive with timing! Objects are usually not moving fast enough
  -- to warrant a check of below 10 seconds.
  -- @return #SET_DYNAMICCARGO self
  function SET_DYNAMICCARGO:FilterZoneTimer(Seconds) 
    self.ZoneTimerInterval = Seconds or 30
    return self
  end
  
  --- This filter is N/A for SET_DYNAMICCARGO
  -- @param #SET_DYNAMICCARGO self
  -- @return #SET_DYNAMICCARGO self
  function SET_DYNAMICCARGO:FilterDeads()
    return self
  end

  --- This filter is N/A for SET_DYNAMICCARGO
  -- @param #SET_DYNAMICCARGO self
  -- @return #SET_DYNAMICCARGO self
  function SET_DYNAMICCARGO:FilterCrashes()
    return self
  end
  
  --- Returns a list of current owners (playernames) indexed by playername from the SET.
  -- @param #SET_DYNAMICCARGO self
  -- @return #list<#string> Ownerlist
  function SET_DYNAMICCARGO:GetOwnerNames()
    local owners = {}
    self:ForEach(
      function(cargo)
        if cargo and cargo.Owner then
          table.insert(owners, cargo.Owner, cargo.Owner)
        end
      end
    )  
    return owners
  end
  
  --- Returns a list of @{Wrapper.Storage#STORAGE} objects from the SET indexed by cargo name.
  -- @param #SET_DYNAMICCARGO self
  -- @return #list<Wrapper.Storage#STORAGE> Storagelist
  function SET_DYNAMICCARGO:GetStorageObjects()
    local owners = {}
    self:ForEach(
      function(cargo)
        if cargo and cargo.warehouse then
          table.insert(owners, cargo.StaticName, cargo.warehouse)
        end
      end
    )  
    return owners
  end
  
  --- Returns a list of current owners (Wrapper.Client#CLIENT objects) indexed by playername from the SET.
  -- @param #SET_DYNAMICCARGO self
  -- @return #list<#string> Ownerlist
  function SET_DYNAMICCARGO:GetOwnerClientObjects()
    local owners = {}
    self:ForEach(
      function(cargo)
        if cargo and cargo.Owner then
          local client = CLIENT:FindByPlayerName(cargo.Owner)
          if client then
            table.insert(owners, cargo.Owner, client)
          end
        end
      end
    )  
    return owners
  end

end
