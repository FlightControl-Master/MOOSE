--- **Ops** - Target.
--
-- **Main Features:**
--
--    * Manages target, number alive, life points, damage etc.
--    * Events when targets are damaged or destroyed
--    * Various target objects: UNIT, GROUP, STATIC, SCENERY, AIRBASE, COORDINATE, ZONE, SET_GROUP, SET_UNIT, SET_STATIC, SET_SCENERY, SET_ZONE
--
-- ===
--
-- ### Author: **funkyfranky**
-- ### Additions: **applevangelist**
-- 
-- @module Ops.Target
-- @image OPS_Target.png


--- TARGET class.
-- @type TARGET
-- @field #string ClassName Name of the class.
-- @field #number verbose Verbosity level.
-- @field #number uid Unique ID of the target.
-- @field #string lid Class id string for output to DCS log file.
-- @field #table targets Table of target objects.
-- @field #number targetcounter Running number to generate target object IDs.
-- @field #number life Total life points on last status update.
-- @field #number life0 Total life points of completely healthy targets.
-- @field #number threatlevel0 Initial threat level.
-- @field #number category Target category (Ground, Air, Sea).
-- @field #number N0 Number of initial target elements/units.
-- @field #number Ntargets0 Number of initial target objects.
-- @field #number Ndestroyed Number of target elements/units that were destroyed.
-- @field #number Ndead Number of target elements/units that are dead (destroyed or despawned).
-- @field #table elements Table of target elements/units.
-- @field #table casualties Table of dead element names.
-- @field #number prio Priority.
-- @field #number importance Importance.
-- @field Ops.Auftrag#AUFTRAG mission Mission attached to this target.
-- @field Ops.Intel#INTEL.Contact contact Contact attached to this target.
-- @field #boolean isDestroyed If true, target objects were destroyed.
-- @field #table resources Resource list.
-- @field #table conditionStart Start condition functions.
-- @field Ops.Operation#OPERATION operation Operation this target is part of.
-- @extends Core.Fsm#FSM

--- **It is far more important to be able to hit the target than it is to haggle over who makes a weapon or who pulls a trigger** -- Dwight D Eisenhower
--
-- ===
--
-- # The TARGET Concept
-- 
-- Define a target of your mission and monitor its status. Events are triggered when the target is damaged or destroyed.
-- 
-- A target can consist of one or multiple "objects".
--
--
-- @field #TARGET
TARGET = {
  ClassName      = "TARGET",
  verbose        =     0,
  lid            =   nil,
  targets        =    {},
  targetcounter  =     0,
  life           =     0,
  life0          =     0,
  N0             =     0,
  Ntargets0      =     0,
  Ndestroyed     =     0,
  Ndead          =     0,
  elements       =    {},
  casualties     =    {},
  threatlevel0   =     0,
  conditionStart =    {},
  TStatus        =    30,
}


--- Type.
-- @type TARGET.ObjectType
-- @field #string GROUP Target is a GROUP object.
-- @field #string UNIT Target is a UNIT object.
-- @field #string STATIC Target is a STATIC object.
-- @field #string SCENERY Target is a SCENERY object.
-- @field #string COORDINATE Target is a COORDINATE.
-- @field #string AIRBASE Target is an AIRBASE.
-- @field #string ZONE Target is a ZONE object.
-- @field #string OPSZONE Target is an OPSZONE object.
TARGET.ObjectType={
  GROUP="Group",
  UNIT="Unit",
  STATIC="Static",
  SCENERY="Scenery",
  COORDINATE="Coordinate",
  AIRBASE="Airbase",
  ZONE="Zone",
  OPSZONE="OpsZone"
}


--- Category.
-- @type TARGET.Category
-- @field #string AIRCRAFT 
-- @field #string GROUND
-- @field #string NAVAL
-- @field #string AIRBASE
-- @field #string COORDINATE
-- @field #string ZONE
TARGET.Category={
  AIRCRAFT="Aircraft",
  GROUND="Ground",
  NAVAL="Naval",
  AIRBASE="Airbase",
  COORDINATE="Coordinate",
  ZONE="Zone",
}

--- Object status.
-- @type TARGET.ObjectStatus
-- @field #string ALIVE Object is alive.
-- @field #string DEAD Object is dead.
-- @field #string DAMAGED Object is damaged.
TARGET.ObjectStatus={
  ALIVE="Alive",
  DEAD="Dead",
  DAMAGED="Damaged",
}

--- Resource.
-- @type TARGET.Resource
-- @field #string MissionType Mission type, e.g. `AUFTRAG.Type.BAI`.
-- @field #number Nmin Min number of assets.
-- @field #number Nmax Max number of assets.
-- @field #table Attributes Generalized attribute, e.g. `{GROUP.Attribute.GROUND_INFANTRY}`.
-- @field #table Properties Properties ([DCS attributes](https://wiki.hoggitworld.com/view/DCS_enum_attributes)), e.g. `"Attack helicopters"` or `"Mobile AAA"`.
-- @field Ops.Auftrag#AUFTRAG mission Attached mission.

--- Target object.
-- @type TARGET.Object
-- @field #number ID Target unique ID.
-- @field #string Name Target name.
-- @field #string Type Target type.
-- @field Wrapper.Positionable#POSITIONABLE Object The object, which can be many things, e.g. a UNIT, GROUP, STATIC, SCENERY, AIRBASE or COORDINATE object.
-- @field #number Life Life points on last status update.
-- @field #number Life0 Life points of completely healthy target.
-- @field #number N0 Number of initial elements.
-- @field #number Ndead Number of dead elements.
-- @field #number Ndestroyed Number of destroyed elements.
-- @field #string Status Status "Alive" or "Dead".
-- @field Core.Point#COORDINATE Coordinate of the target object.

--- Global target ID counter.
_TARGETID=0

--- TARGET class version.
-- @field #string version
TARGET.version="0.7.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- DONE: Had cases where target life was 0 but target was not dead. Need to figure out why! <== This is due to delayed dead event.
-- DONE: Add pseudo functions.
-- DONE: Initial object can be nil.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new TARGET object and start the FSM.
-- @param #TARGET self
-- @param #table TargetObject Target object. Can be a: UNIT, GROUP, STATIC, SCENERY, AIRBASE, COORDINATE, ZONE, SET_GROUP, SET_UNIT, SET_STATIC, SET_SCENERY, SET_ZONE
-- @return #TARGET self
function TARGET:New(TargetObject)

  -- Inherit everything from INTEL class.
  local self=BASE:Inherit(self, FSM:New()) --#TARGET

  -- Increase counter.
  _TARGETID=_TARGETID+1
  
  -- Set UID.
  self.uid=_TARGETID
  
  if TargetObject then
 
    -- Add object.
    self:AddObject(TargetObject)
    
  end
  
  -- Defaults.
  self:SetPriority()
  self:SetImportance()
  self.TStatus = 30
  
  -- Log ID.
  self.lid=string.format("TARGET #%03d | ", _TARGETID)

  -- Start state.
  self:SetStartState("Stopped")

  -- Add FSM transitions.
  --                 From State     -->      Event        -->     To State
  self:AddTransition("Stopped",            "Start",               "Alive")       -- Start FSM.
  self:AddTransition("*",                  "Status",              "*")           -- Status update.
  self:AddTransition("*",                  "Stop",                "Stopped")     -- Stop FSM.
  
  self:AddTransition("*",                  "ObjectDamaged",       "*")           -- A target object was damaged.  
  self:AddTransition("*",                  "ObjectDestroyed",     "*")           -- A target object was destroyed.
  self:AddTransition("*",                  "ObjectDead",          "*")           -- A target object is dead (destroyed or despawned).
  
  self:AddTransition("*",                  "Damaged",             "Damaged")     -- Target was damaged.
  self:AddTransition("*",                  "Destroyed",           "Dead")        -- Target was completely destroyed.
  self:AddTransition("*",                  "Dead",                "Dead")        -- Target is dead. Could be destroyed or despawned.

  ------------------------
  --- Pseudo Functions ---
  ------------------------

  --- Triggers the FSM event "Start". Starts the TARGET. Initializes parameters and starts event handlers.
  -- @function [parent=#TARGET] Start
  -- @param #TARGET self

  --- Triggers the FSM event "Start" after a delay. Starts the TARGET. Initializes parameters and starts event handlers.
  -- @function [parent=#TARGET] __Start
  -- @param #TARGET self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Stop". Stops the TARGET and all its event handlers.
  -- @param #TARGET self

  --- Triggers the FSM event "Stop" after a delay. Stops the TARGET and all its event handlers.
  -- @function [parent=#TARGET] __Stop
  -- @param #TARGET self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Status".
  -- @function [parent=#TARGET] Status
  -- @param #TARGET self

  --- Triggers the FSM event "Status" after a delay.
  -- @function [parent=#TARGET] __Status
  -- @param #TARGET self
  -- @param #number delay Delay in seconds.


  --- Triggers the FSM event "ObjectDamaged".
  -- @function [parent=#TARGET] ObjectDamaged
  -- @param #TARGET self
  -- @param #TARGET.Object Target Target object.

  --- Triggers the FSM event "ObjectDestroyed".
  -- @function [parent=#TARGET] ObjectDestroyed
  -- @param #TARGET self
  -- @param #TARGET.Object Target Target object.

  --- Triggers the FSM event "ObjectDead".
  -- @function [parent=#TARGET] ObjectDead
  -- @param #TARGET self
  -- @param #TARGET.Object Target Target object.


  --- Triggers the FSM event "Damaged".
  -- @function [parent=#TARGET] Damaged
  -- @param #TARGET self

  --- Triggers the FSM event "Destroyed".
  -- @function [parent=#TARGET] Destroyed
  -- @param #TARGET self

  --- Triggers the FSM event "Dead".
  -- @function [parent=#TARGET] Dead
  -- @param #TARGET self

  
  --- On After "ObjectDamaged" event. A (sub-) target object has been damaged, e.g. a UNIT of a GROUP, or an object of a SET
  -- @function [parent=#TARGET] OnAfterObjectDamaged
  -- @param #TARGET self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #TARGET.Object Target Target object.
  
  --- On After "ObjectDestroyed" event. A (sub-) target object has been destroyed, e.g. a UNIT of a GROUP, or an object of a SET
  -- @function [parent=#TARGET] OnAfterObjectDestroyed
  -- @param #TARGET self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #TARGET.Object Target Target object.
  
  --- On After "ObjectDead" event. A (sub-) target object is dead, e.g. a UNIT of a GROUP, or an object of a SET
  -- @function [parent=#TARGET] OnAfterObjectDead
  -- @param #TARGET self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #TARGET.Object Target Target object.

  
  --- On After "Damaged" event. Any of the target objects has been damaged.
  -- @function [parent=#TARGET] OnAfterDamaged
  -- @param #TARGET self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  
  --- On After "Destroyed" event. All target objects have been destroyed.
  -- @function [parent=#TARGET] OnAfterDestroyed
  -- @param #TARGET self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  
  --- On After "Dead" event. All target objects are dead.
  -- @function [parent=#TARGET] OnAfterDead
  -- @param #TARGET self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.

  -- Start.
  self:__Start(-0.1)

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create target data from a given object. Valid objects are:
-- 
-- * GROUP
-- * UNIT
-- * STATIC
-- * SCENERY
-- * AIRBASE
-- * COORDINATE
-- * ZONE
-- * SET_GROUP
-- * SET_UNIT
-- * SET_STATIC
-- * SET_SCENERY
-- * SET_OPSGROUP
-- * SET_ZONE
-- * SET_OPSZONE
-- 
-- @param #TARGET self
-- @param Wrapper.Positionable#POSITIONABLE Object The target UNIT, GROUP, STATIC, SCENERY, AIRBASE, COORDINATE, ZONE, SET_GROUP, SET_UNIT, SET_STATIC, SET_SCENERY, SET_ZONE
function TARGET:AddObject(Object)
    
  if Object:IsInstanceOf("SET_GROUP")    or 
     Object:IsInstanceOf("SET_UNIT")     or 
     Object:IsInstanceOf("SET_STATIC")   or 
     Object:IsInstanceOf("SET_SCENERY")  or 
     Object:IsInstanceOf("SET_OPSGROUP") or  
     Object:IsInstanceOf("SET_OPSZONE")  then

    ---
    -- Sets
    ---

    local set=Object --Core.Set#SET_GROUP
    
    for _,object in pairs(set.Set) do
      self:AddObject(object)
    end
    
  elseif  Object:IsInstanceOf("SET_ZONE") then
  
    local set=Object --Core.Set#SET_ZONE
    
    set:SortByName()
  
    for index,ZoneName in pairs(set.Index) do
      local zone=set.Set[ZoneName] --Core.Zone#ZONE
      self:_AddObject(zone)
    end
    
  else
  
    ---
    -- Groups, Units, Statics, Airbases, Coordinates
    ---
  
    if Object:IsInstanceOf("OPSGROUP") then
      self:_AddObject(Object:GetGroup()) -- We add the MOOSE GROUP object not the OPSGROUP object.
    --elseif Object:IsInstanceOf("OPSZONE") then
      --self:_AddObject(Object:GetZone())
    else
      self:_AddObject(Object)
    end
    
  end

  return self
end

--- Set priority of the target.
-- @param #TARGET self
-- @param #number Priority Priority of the target. Default 50.
-- @return #TARGET self
function TARGET:SetPriority(Priority)
  self.prio=Priority or 50
  return self
end

--- Set importance of the target.
-- @param #TARGET self
-- @param #number Importance Importance of the target. Default `nil`.
-- @return #TARGET self
function TARGET:SetImportance(Importance)
  self.importance=Importance
  return self
end

--- Add start condition.
-- @param #TARGET self
-- @param #function ConditionFunction Function that needs to be true before the mission can be started. Must return a #boolean.
-- @param ... Condition function arguments if any.
-- @return #TARGET self
function TARGET:AddConditionStart(ConditionFunction, ...)

  local condition={} --Ops.Auftrag#AUFTRAG.Condition

  condition.func=ConditionFunction
  condition.arg={}
  if arg then
    condition.arg=arg
  end

  table.insert(self.conditionStart, condition)

  return self
end

--- Add stop condition.
-- @param #TARGET self
-- @param #function ConditionFunction Function that needs to be true before the mission can be started. Must return a #boolean.
-- @param ... Condition function arguments if any.
-- @return #TARGET self
function TARGET:AddConditionStop(ConditionFunction, ...)

  local condition={} --Ops.Auftrag#AUFTRAG.Condition

  condition.func=ConditionFunction
  condition.arg={}
  if arg then
    condition.arg=arg
  end

  table.insert(self.conditionStop, condition)

  return self
end

--- Check if all given condition are true.
-- @param #TARGET self
-- @param #table Conditions Table of conditions.
-- @return #boolean If true, all conditions were true. Returns false if at least one condition returned false.
function TARGET:EvalConditionsAll(Conditions)

  -- Any stop condition must be true.
  for _,_condition in pairs(Conditions or {}) do
    local condition=_condition --Ops.Auftrag#AUFTRAG.Condition

    -- Call function.
    local istrue=condition.func(unpack(condition.arg))

    -- Any false will return false.
    if not istrue then
      return false
    end

  end

  -- All conditions were true.
  return true
end


--- Check if any of the given conditions is true.
-- @param #TARGET self
-- @param #table Conditions Table of conditions.
-- @return #boolean If true, at least one condition is true.
function TARGET:EvalConditionsAny(Conditions)

  -- Any stop condition must be true.
  for _,_condition in pairs(Conditions or {}) do
    local condition=_condition --Ops.Auftrag#AUFTRAG.Condition

    -- Call function.
    local istrue=condition.func(unpack(condition.arg))

    -- Any true will return true.
    if istrue then
      return true
    end

  end

  -- No condition was true.
  return false
end

--- Add mission type and number of required assets to resource.
-- @param #TARGET self
-- @param #string MissionType Mission Type.
-- @param #number Nmin Min number of required assets.
-- @param #number Nmax Max number of requried assets.
-- @param #table Attributes Generalized attribute(s).
-- @param #table Properties DCS attribute(s). Default `nil`.
-- @return #TARGET.Resource The resource table.
function TARGET:AddResource(MissionType, Nmin, Nmax, Attributes, Properties)
  
  -- Ensure table.
  if Attributes and type(Attributes)~="table" then
    Attributes={Attributes}
  end
  
  -- Ensure table.
  if Properties and type(Properties)~="table" then
    Properties={Properties}
  end
  
  -- Create new resource table.
  local resource={} --#TARGET.Resource
  resource.MissionType=MissionType
  resource.Nmin=Nmin or 1
  resource.Nmax=Nmax or 1
  resource.Attributes=Attributes or {}
  resource.Properties=Properties or {}
  
  -- Init resource table.
  self.resources=self.resources or {}
  
  -- Add to table.
  table.insert(self.resources, resource)
  
  -- Debug output.
  if self.verbose>10 then
    local text="Resource:"
    for _,_r in pairs(self.resources) do
      local r=_r --#TARGET.Resource
      text=text..string.format("\nmission=%s, Nmin=%d, Nmax=%d, attribute=%s, properties=%s", r.MissionType, r.Nmin, r.Nmax, tostring(r.Attributes[1]), tostring(r.Properties[1]))
    end
    self:I(self.lid..text)
  end
    
  return resource
end

--- Check if TARGET is alive.
-- @param #TARGET self
-- @return #boolean If true, target is alive.
function TARGET:IsAlive()

  for _,_target in pairs(self.targets) do
    local target=_target --Ops.Target#TARGET.Object
    if target.Status~=TARGET.ObjectStatus.DEAD then
      if self.isDestroyed then
        self:E(self.lid..string.format("ERROR: target is DESTROYED but target object status is not DEAD but %s for object %s", target.Status, target.Name))
      elseif self:IsDead() then
        self:E(self.lid..string.format("ERROR: target is DEAD but target object status is not DEAD but %s for object %s", target.Status, target.Name))
      end
      return true
    end
  end

  return false
end

--- Check if TARGET is destroyed.
-- @param #TARGET self
-- @return #boolean If true, target is destroyed.
function TARGET:IsDestroyed()
  return self.isDestroyed
end


--- Check if TARGET is dead.
-- @param #TARGET self
-- @return #boolean If true, target is dead.
function TARGET:IsDead()
  local is=self:Is("Dead")
  return is
end

--- Check if target object is dead.
-- @param #TARGET self
-- @param #TARGET.Object TargetObject The target object.
-- @return #boolean If true, target is dead.
function TARGET:IsTargetDead(TargetObject)
  local isDead=TargetObject.Status==TARGET.ObjectStatus.DEAD
  return isDead
end

--- Check if target object is alive.
-- @param #TARGET self
-- @param #TARGET.Object TargetObject The target object.
-- @return #boolean If true, target is dead.
function TARGET:IsTargetAlive(TargetObject)
  local isAlive=TargetObject.Status==TARGET.ObjectStatus.ALIVE
  return isAlive
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Start & Status
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after Start event. Starts the FLIGHTGROUP FSM and event handlers.
-- @param #TARGET self
-- @param Wrapper.Group#GROUP Group Flight group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function TARGET:onafterStart(From, Event, To)
  self:T({From, Event, To})
  -- Short info.
  local text=string.format("Starting Target")
  self:T(self.lid..text)

  self:HandleEvent(EVENTS.Dead,       self.OnEventUnitDeadOrLost)
  self:HandleEvent(EVENTS.UnitLost,   self.OnEventUnitDeadOrLost)
  self:HandleEvent(EVENTS.RemoveUnit, self.OnEventUnitDeadOrLost)

  self:__Status(-1)
  return self
end

--- On after "Status" event.
-- @param #TARGET self
-- @param Wrapper.Group#GROUP Group Flight group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function TARGET:onafterStatus(From, Event, To)
  --self:T({From, Event, To})
  
  -- FSM state.
  local fsmstate=self:GetState()
    
  -- Update damage.
  local damaged=false
  for i,_target in pairs(self.targets) do
    local target=_target --#TARGET.Object
    
    -- old life
    local life=target.Life
    
    -- curr life    
    target.Life=self:GetTargetLife(target)
    
    -- TODO: special case ED bug > life **increases** after hits on SCENERY
    if target.Life > target.Life0 then
      local delta = 2*(target.Life-target.Life0)
      target.Life0 = target.Life0 + delta
      life = target.Life0 
      self.life0 = self.life0+delta
    end
    
    -- Check if life decreased ==> damaged
    if target.Life<life then
      --target.Status = TARGET.ObjectStatus.DAMAGED
      self:ObjectDamaged(target)
      damaged=true
    end
    
    if target.Life<1 and target.Status~=TARGET.ObjectStatus.DEAD then
      self:E(self.lid..string.format("FF life is zero but no object dead event fired ==> object dead now for target object %s!", tostring(target.Name)))
      self:ObjectDead(target)
      damaged = true
    end
    
  end
  
  -- Target was damaged.
  if damaged then
    self:Damaged()
  end
  
  -- Log output verbose=1.
  if self.verbose>=1 then
    local text=string.format("%s: Targets=%d/%d [%d, %d], Life=%.1f/%.1f, Damage=%.1f", 
    fsmstate, self:CountTargets(), self.N0, self.Ndestroyed, self.Ndead, self:GetLife(), self:GetLife0(), self:GetDamage())
    if self:CountTargets() == 0 or self:GetDamage() >= 100 then
      text=text.." - Dead!"
    elseif damaged then
      text=text.." - Damaged!"
    end
    self:I(self.lid..text)
  end  
  
  -- Log output verbose=2.
  if self.verbose>=2 then
    local text="Target:"
    for i,_target in pairs(self.targets) do
      local target=_target --#TARGET.Object
      local damage=(1-target.Life/target.Life0)*100
      text=text..string.format("\n[%d] %s %s %s: Life=%.1f/%.1f, Damage=%.1f, N0=%d, Ndestroyed=%d, Ndead=%d", 
      i, target.Type, target.Name, target.Status, target.Life, target.Life0, damage, target.N0, target.Ndestroyed, target.Ndead)
    end
    self:I(self.lid..text)
  end
  
  -- Consitency check if target is still alive but all target objects are dead
  if self:IsAlive() and (self:CountTargets()==0 or self:GetDamage()>=100) then
    self:Dead()
  end
  
  -- Quick sanity check
  for i,_target in pairs(self.targets) do
    local target=_target --#TARGET.Object
    if target.Ndestroyed>target.N0 then
      self:E(self.lid..string.format("ERROR: Number of destroyed target objects greater than number of initial target objects: %d>%d!", target.Ndestroyed, target.N0))
    end
    if target.Ndestroyed>target.N0 then
      self:E(self.lid..string.format("ERROR: Number of dead target objects greater than number of initial target objects: %d>%d!", target.Ndead, target.N0))
    end
  end
  
  -- Update status again in 30 sec.
  if self:IsAlive() then
    self:__Status(-self.TStatus)
  else
    self:I(self.lid..string.format("Target is not alive any more ==> no further status updates are carried out"))
  end
  
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Events
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after "ObjectDamaged" event.
-- @param #TARGET self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #TARGET.Object Target Target object.
function TARGET:onafterObjectDamaged(From, Event, To, Target)
  self:T({From, Event, To})
  -- Debug info.
  self:T(self.lid..string.format("Object %s damaged", Target.Name))
  
  return self
end

--- On after "ObjectDestroyed" event.
-- @param #TARGET self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #TARGET.Object Target Target object.
function TARGET:onafterObjectDestroyed(From, Event, To, Target)
  self:T({From, Event, To})
  -- Debug message.
  self:T(self.lid..string.format("Object %s destroyed", Target.Name))
  
  -- Increase destroyed counter.
  self.Ndestroyed=self.Ndestroyed+1
  
  Target.Ndestroyed=Target.Ndestroyed+1
  
  Target.Life=0
  
  -- Call object dead event.
  self:ObjectDead(Target)
  
  return self
end

--- On after "ObjectDead" event.
-- @param #TARGET self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #TARGET.Object Target Target object.
function TARGET:onafterObjectDead(From, Event, To, Target)
  self:T({From, Event, To})
  -- Debug message.
  self:T(self.lid..string.format("Object %s dead", Target.Name))

  -- Set target status.
  Target.Status=TARGET.ObjectStatus.DEAD
  
  -- Increase dead object counter
  Target.Ndead=Target.Ndead+1
  
  -- Set target object life to 0.
  Target.Life=0
  
  -- Increase dead counter.
  self.Ndead=self.Ndead+1
  
  -- Check if anyone is alive?
  local dead=true
  for _,_target in pairs(self.targets) do
    local target=_target --#TARGET.Object
    if target.Status==TARGET.ObjectStatus.ALIVE then
      dead=false
      break -- break the loop because we now we are not dead
    end
  end
  
  -- All dead ==> Trigger destroyed event.
  if dead then
  
    if self.Ndestroyed==self.Ntargets0 then
  
      self.isDestroyed=true
      
      self:Destroyed()
      
    else
    
      self:Dead()
    
    end
  else
    self:Damaged()
  end
  
  return self
end

--- On after "Damaged" event.
-- @param #TARGET self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function TARGET:onafterDamaged(From, Event, To)
  self:T({From, Event, To})
  
  self:T(self.lid..string.format("TARGET damaged"))
  
  return self
end

--- On after "Destroyed" event.
-- @param #TARGET self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function TARGET:onafterDestroyed(From, Event, To)
  self:T({From, Event, To})
  
  self:T(self.lid..string.format("TARGET destroyed"))
  
  self:Dead()
  
  return self
end

--- On after "Dead" event.
-- @param #TARGET self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function TARGET:onafterDead(From, Event, To)
  self:T({From, Event, To})
  
  self:T(self.lid..string.format("TARGET dead"))
  
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Event Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Event function handling the loss of a unit.
-- @param #TARGET self
-- @param Core.Event#EVENTDATA EventData Event data.
function TARGET:OnEventUnitDeadOrLost(EventData)

  local Name=EventData and EventData.IniUnitName or nil

  -- Check that this is the right group.
  if self:IsElement(Name) and not self:IsCasualty(Name) then
  
    -- Debug info.
    self:T(self.lid..string.format("EVENT ID=%d: Unit %s dead or lost!", EventData.id, tostring(Name)))
    
    -- Add to the list of casualties.
    table.insert(self.casualties, Name)
        
    -- Try to get target Group.
    local target=self:GetTargetByName(EventData.IniGroupName)
    
    -- Try unit target.
    if not target then    
      target=self:GetTargetByName(EventData.IniUnitName)      
    end
    
    -- Check if we could find a target object.
    if target then
    
      local Ndead=target.Ndead
      local Ndestroyed=target.Ndestroyed
      if EventData.id==EVENTS.RemoveUnit then
        Ndead=Ndead+1
      else
        Ndestroyed=Ndestroyed+1
        Ndead=Ndead+1
      end
      
      
      -- Check if ALL objects are dead
      if Ndead==target.N0 then
      
        if Ndestroyed>=target.N0 then

          -- Debug message.
          self:T2(self.lid..string.format("EVENT ID=%d: target %s dead/lost ==> destroyed", EventData.id, tostring(target.Name)))
          
          target.Life = 0
          
          -- Trigger object destroyed event. This sets the Life to zero and increases Ndestroyed
          self:ObjectDestroyed(target)
          
        else
        
          -- Debug message.
          self:T2(self.lid..string.format("EVENT ID=%d: target %s removed ==> dead", EventData.id, tostring(target.Name)))
          
          target.Life = 0
          
          -- Trigger object dead event.  This sets the Life to zero and increases Ndead counter
          self:ObjectDead(target)
        
        end
      
      end

    end -- Event belongs to this TARGET 
    
  end
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Adding and Removing Targets
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create target data from a given object.
-- @param #TARGET self
-- @param Wrapper.Positionable#POSITIONABLE Object The target UNIT, GROUP, STATIC, SCENERY, AIRBASE, COORDINATE, ZONE, SET_GROUP, SET_UNIT, SET_STATIC, SET_SCENERY, SET_ZONE
function TARGET:_AddObject(Object)

  local target={}  --#TARGET.Object
  
  target.N0=0
  target.Ndead=0
  target.Ndestroyed=0
  
  if Object:IsInstanceOf("GROUP") then
  
    local group=Object --Wrapper.Group#GROUP
  
    target.Type=TARGET.ObjectType.GROUP
    target.Name=group:GetName()   
    
    target.Coordinate=group:GetCoordinate() 
        
    local units=group:GetUnits()
      
    target.Life=0 ; target.Life0=0
    for _,_unit in pairs(units or {}) do
      local unit=_unit --Wrapper.Unit#UNIT
      
      local life=unit:GetLife()
      
      target.Life=target.Life+life
      target.Life0=target.Life0+math.max(unit:GetLife0(), life)  -- There was an issue with ships that life is greater life0, which cannot be!
      
      self.threatlevel0=self.threatlevel0+unit:GetThreatLevel()
      
      table.insert(self.elements, unit:GetName())
      
      target.N0=target.N0+1
    end
  
  elseif Object:IsInstanceOf("UNIT") then
  
    local unit=Object --Wrapper.Unit#UNIT
    
    target.Type=TARGET.ObjectType.UNIT
    target.Name=unit:GetName()
    
    target.Coordinate=unit:GetCoordinate()
    
    if unit then
      target.Life=unit:GetLife()
      target.Life0=math.max(unit:GetLife0(), target.Life)  -- There was an issue with ships that life is greater life0!
      
      self.threatlevel0=self.threatlevel0+unit:GetThreatLevel()
      
      table.insert(self.elements, unit:GetName())
      
      target.N0=target.N0+1
    end

  elseif Object:IsInstanceOf("STATIC") then
  
    local static=Object --Wrapper.Static#STATIC
    
    target.Type=TARGET.ObjectType.STATIC
    target.Name=static:GetName()
    
    target.Coordinate=static:GetCoordinate()
    
    if static and static:IsAlive() then
    
      target.Life0=static:GetLife0()
      target.Life=static:GetLife()      
      target.N0=target.N0+1
      
      table.insert(self.elements, target.Name)
      
    end

  elseif Object:IsInstanceOf("SCENERY") then
  
    local scenery=Object --Wrapper.Scenery#SCENERY
    
    target.Type=TARGET.ObjectType.SCENERY
    target.Name=scenery:GetName()
    
    target.Coordinate=scenery:GetCoordinate()

    target.Life0=scenery:GetLife0()
    
    if target.Life0==0 then target.Life0 = 1 end
    
    target.Life=scenery:GetLife()
    
    target.N0=target.N0+1
    
    table.insert(self.elements, target.Name)

  elseif Object:IsInstanceOf("AIRBASE") then
  
    local airbase=Object --Wrapper.Airbase#AIRBASE
    
    target.Type=TARGET.ObjectType.AIRBASE
    target.Name=airbase:GetName()
    
    target.Coordinate=airbase:GetCoordinate()

    target.Life0=1
    target.Life=1
    
    target.N0=target.N0+1
    
    table.insert(self.elements, target.Name)

  elseif Object:IsInstanceOf("COORDINATE") then

    local coord=UTILS.DeepCopy(Object) --Core.Point#COORDINATE

    target.Type=TARGET.ObjectType.COORDINATE
    target.Name=coord:ToStringMGRS()
    
    target.Coordinate=coord

    target.Life0=1
    target.Life=1
    
    target.N0=target.N0+1
      
  elseif Object:IsInstanceOf("ZONE_BASE") then
  
    local zone=Object --Core.Zone#ZONE_BASE
    Object=zone --:GetCoordinate()
    
    target.Type=TARGET.ObjectType.ZONE
    target.Name=zone:GetName()
    
    target.Coordinate=zone:GetCoordinate()

    target.Life0=1
    target.Life=1
    
    target.N0=target.N0+1

  elseif Object:IsInstanceOf("OPSZONE") then
  
  
    local zone=Object --Ops.OpsZone#OPSZONE
    Object=zone
    
    target.Type=TARGET.ObjectType.OPSZONE
    target.Name=zone:GetName()
    
    target.Coordinate=zone:GetCoordinate()
    
    target.N0=target.N0+1

    target.Life0=1
    target.Life=1
  
  else
    self:E(self.lid.."ERROR: Unknown object type!")
    return nil
  end
  
  self.life=self.life+target.Life
  self.life0=self.life0+target.Life0
  
  self.N0=self.N0+target.N0
  self.Ntargets0=self.Ntargets0+1
 
  -- Increase counter.
  self.targetcounter=self.targetcounter+1
  
  target.ID=self.targetcounter
  target.Status=TARGET.ObjectStatus.ALIVE
  target.Object=Object
  
  table.insert(self.targets, target)
  
  if self.name==nil then
    self.name=self:GetTargetName(target)
  end
  if self.category==nil then
    self.category=self:GetTargetCategory(target)
  end
  
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Life and Damage Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get target life points.
-- @param #TARGET self
-- @return #number Number of initial life points when mission was planned.
function TARGET:GetLife0()
  return self.life0
end

--- Get current damage.
-- @param #TARGET self
-- @return #number Damage in percent.
function TARGET:GetDamage()
  local life=self:GetLife()/self:GetLife0()
  local damage=1-life
  return damage*100
end

--- Get target life points.
-- @param #TARGET self
-- @param #TARGET.Object Target Target object.
-- @return #number Life points of target.
function TARGET:GetTargetLife(Target)

  if Target.Type==TARGET.ObjectType.GROUP then

    if Target.Object and Target.Object:IsAlive() then
    
      local units=Target.Object:GetUnits()
      
      local life=0
      for _,_unit in pairs(units or {}) do
        local unit=_unit --Wrapper.Unit#UNIT
        life=life+unit:GetLife()
      end
      
      return life
    else
      return 0
    end

  elseif Target.Type==TARGET.ObjectType.UNIT then

    local unit=Target.Object --Wrapper.Unit#UNIT

    if unit and unit:IsAlive() then
    
      -- Note! According to the profiler, there is a big difference if we "return unit:GetLife()" or "local life=unit:GetLife(); return life"!
      local life=unit:GetLife()
      return life
    else
      return 0
    end
  
  elseif Target.Type==TARGET.ObjectType.STATIC then
  
    if Target.Object and Target.Object:IsAlive() then
      local life=Target.Object:GetLife()
      return life
      --return 1
    else
      return 0
    end

  elseif Target.Type==TARGET.ObjectType.SCENERY then
  
    if Target.Object and Target.Object:IsAlive(25)  then
      local life = Target.Object:GetLife()
      return life
    else
      return 0
    end
    
  elseif Target.Type==TARGET.ObjectType.AIRBASE then
  
    if Target.Status==TARGET.ObjectStatus.ALIVE then
      return 1
    else
      return 0
    end
    
  elseif Target.Type==TARGET.ObjectType.COORDINATE then
  
    return 1

  elseif Target.Type==TARGET.ObjectType.ZONE or Target.Type==TARGET.ObjectType.OPSZONE then
  
    return 1
    
  else
    self:E("ERROR: unknown target object type in GetTargetLife!")
  end
  
  return self
end

--- Get current total life points. This is the sum of all target objects.
-- @param #TARGET self
-- @return #number Life points of target.
function TARGET:GetLife()
  
  local N=0

  for _,_target in pairs(self.targets) do
    local Target=_target --#TARGET.Object
    
    N=N+self:GetTargetLife(Target)

  end
  
  return N
end

--- Get target threat level
-- @param #TARGET self
-- @param #TARGET.Object Target Target object.
-- @return #number Threat level of target.
function TARGET:GetTargetThreatLevelMax(Target)

  if Target.Type==TARGET.ObjectType.GROUP then
  
    local group=Target.Object --Wrapper.Group#GROUP

    if group and group:IsAlive() then
    
      local tl=group:GetThreatLevel()

      return tl
    else
      return 0
    end

  elseif Target.Type==TARGET.ObjectType.UNIT then

    local unit=Target.Object --Wrapper.Unit#UNIT

    if unit and unit:IsAlive() then
    
      -- Note! According to the profiler, there is a big difference if we "return unit:GetLife()" or "local life=unit:GetLife(); return life"!
      local life=unit:GetThreatLevel()
      return life
    else
      return 0
    end
  
  elseif Target.Type==TARGET.ObjectType.STATIC then
  
    return 0

  elseif Target.Type==TARGET.ObjectType.SCENERY then
  
    return 0
        
  elseif Target.Type==TARGET.ObjectType.AIRBASE then

    return 0  
    
  elseif Target.Type==TARGET.ObjectType.COORDINATE then
  
    return 0

  elseif Target.Type==TARGET.ObjectType.ZONE then
    
    local zone = Target.Object -- Core.Zone#ZONE_RADIUS
    local foundunits = {}
    if zone:IsInstanceOf("ZONE_RADIUS") or zone:IsInstanceOf("ZONE_POLYGON") then
      zone:Scan({Object.Category.UNIT},{Unit.Category.GROUND_UNIT,Unit.Category.SHIP})
      foundunits = zone:GetScannedSetUnit()
    else
      foundunits = SET_UNIT:New():FilterZones({zone}):FilterOnce()
    end
    local ThreatMax = foundunits:GetThreatLevelMax() or 0
    return ThreatMax
  
  elseif Target.Type==TARGET.ObjectType.OPSZONE then
    
    local unitset = Target.Object:GetScannedUnitSet() -- Core.Set#SET_UNIT
    local ThreatMax = unitset:GetThreatLevelMax()
    return ThreatMax
    
  else
    self:E("ERROR: unknown target object type in GetTargetThreatLevel!")
    return 0
  end
  
  return self
end


--- Get threat level.
-- @param #TARGET self
-- @return #number Threat level.
function TARGET:GetThreatLevelMax()
  
  local N=0

  for _,_target in pairs(self.targets) do
    local Target=_target --#TARGET.Object
    
    local n=self:GetTargetThreatLevelMax(Target)
    
    if n>N then
      N=n
    end

  end
  
  return N
end

--- Get target 2D position vector.
-- @param #TARGET self
-- @param #TARGET.Object Target Target object.
-- @return DCS#Vec2 Vector with x,y components.
function TARGET:GetTargetVec2(Target)

  local vec3=self:GetTargetVec3(Target)
  
  if vec3 then
    return {x=vec3.x, y=vec3.z}
  end
  
  return nil
end

--- Get target 3D position vector.
-- @param #TARGET self
-- @param #TARGET.Object Target Target object.
-- @param #boolean Average
-- @return DCS#Vec3 Vector with x,y,z components.
function TARGET:GetTargetVec3(Target, Average)

  if Target.Type==TARGET.ObjectType.GROUP then
  
    local object=Target.Object --Wrapper.Group#GROUP

    if object and object:IsAlive() then
      local vec3=object:GetVec3()
      if Average then
        vec3=object:GetAverageVec3()
      end
      
      if vec3 then
        return vec3
      else
        return nil
      end
    else
    
      return nil

    end

  elseif Target.Type==TARGET.ObjectType.UNIT then
  
    local object=Target.Object --Wrapper.Unit#UNIT

    if object and object:IsAlive() then
      local vec3=object:GetVec3()
      return vec3
    else
      return nil
    end
  
  elseif Target.Type==TARGET.ObjectType.STATIC then
  
    local object=Target.Object --Wrapper.Static#STATIC
  
    if object and object:IsAlive() then
      local vec3=object:GetVec3()
      return vec3
    else
      return nil
    end

  elseif Target.Type==TARGET.ObjectType.SCENERY then
  
    local object=Target.Object --Wrapper.Scenery#SCENERY
  
    if object then
      local vec3=object:GetVec3()
      return vec3
    else
      return nil
    end
    
  elseif Target.Type==TARGET.ObjectType.AIRBASE then
  
    local object=Target.Object --Wrapper.Airbase#AIRBASE
    
    local vec3=object:GetVec3()
    return vec3
  
    --if Target.Status==TARGET.ObjectStatus.ALIVE then      
    --end
    
  elseif Target.Type==TARGET.ObjectType.COORDINATE then
  
    local object=Target.Object --Core.Point#COORDINATE
  
    local vec3={x=object.x, y=object.y, z=object.z}
    return vec3
    
  elseif Target.Type==TARGET.ObjectType.ZONE then
  
    local object=Target.Object --Core.Zone#ZONE
  
    local vec3=object:GetVec3()
    return vec3

  elseif Target.Type==TARGET.ObjectType.OPSZONE then
  
    local object=Target.Object --Ops.OpsZone#OPSZONE
  
    local vec3=object:GetZone():GetVec3()
    return vec3
        
  end

  self:E(self.lid.."ERROR: Unknown TARGET type! Cannot get Vec3")
end

--- Get heading of the target.
-- @param #TARGET self
-- @param #TARGET.Object Target Target object.
-- @return #number Heading in degrees.
function TARGET:GetTargetHeading(Target)

  if Target.Type==TARGET.ObjectType.GROUP then
  
    local object=Target.Object --Wrapper.Group#GROUP

    if object and object:IsAlive() then
      local heading=object:GetHeading()

      if heading then
        return heading
      else
        return nil
      end
    else
    
      return nil

    end

  elseif Target.Type==TARGET.ObjectType.UNIT then
  
    local object=Target.Object --Wrapper.Unit#UNIT

    if object and object:IsAlive() then
      local heading=object:GetHeading()
      return heading
    else
      return nil
    end
  
  elseif Target.Type==TARGET.ObjectType.STATIC then
  
    local object=Target.Object --Wrapper.Static#STATIC
  
    if object and object:IsAlive() then
      local heading=object:GetHeading()
      return heading
    else
      return nil
    end

  elseif Target.Type==TARGET.ObjectType.SCENERY then
  
    local object=Target.Object --Wrapper.Scenery#SCENERY
  
    if object then
      local heading=object:GetHeading()
      return heading
    else
      return nil
    end
    
  elseif Target.Type==TARGET.ObjectType.AIRBASE then
  
    local object=Target.Object --Wrapper.Airbase#AIRBASE
    
    -- Airbase has no real heading. Return 0. Maybe take the runway heading?
    return 0
    
  elseif Target.Type==TARGET.ObjectType.COORDINATE then
  
    local object=Target.Object --Core.Point#COORDINATE
  
    -- A coordinate has no heading. Return 0.
    return 0
    
  elseif Target.Type==TARGET.ObjectType.ZONE or Target.Type==TARGET.ObjectType.OPSZONE then
  
    local object=Target.Object --Core.Zone#ZONE
  
    -- A zone has no heading. Return 0.
    return 0
        
  end

  self:E(self.lid.."ERROR: Unknown TARGET type! Cannot get heading")
end


--- Get target coordinate.
-- @param #TARGET self
-- @param #TARGET.Object Target Target object.
-- @param #boolean Average
-- @return Core.Point#COORDINATE Coordinate of the target.
function TARGET:GetTargetCoordinate(Target, Average)

  if Target.Type==TARGET.ObjectType.COORDINATE then
  
    -- Coordinate is the object itself.
    return Target.Object
    
  else
    
    -- Get updated position vector.
    local vec3=self:GetTargetVec3(Target, Average)
    
    -- Update position. This saves us to create a new COORDINATE object each time.
    if vec3 then
      Target.Coordinate.x=vec3.x
      Target.Coordinate.y=vec3.y
      Target.Coordinate.z=vec3.z
    end
    
    return Target.Coordinate
  
  end

  return nil
end

--- Get target name.
-- @param #TARGET self
-- @param #TARGET.Object Target Target object.
-- @return #string Name of the target object.
function TARGET:GetTargetName(Target)

  if Target.Type==TARGET.ObjectType.GROUP then

    if Target.Object and Target.Object:IsAlive() then

      return Target.Object:GetName()

    end

  elseif Target.Type==TARGET.ObjectType.UNIT then

    if Target.Object and Target.Object:IsAlive() then
      return Target.Object:GetName()
    end
  
  elseif Target.Type==TARGET.ObjectType.STATIC then
  
    if Target.Object and Target.Object:IsAlive() then
      return Target.Object:GetName()
    end
    
  elseif Target.Type==TARGET.ObjectType.AIRBASE then
  
    if Target.Status==TARGET.ObjectStatus.ALIVE then
      return Target.Object:GetName()
    end
    
  elseif Target.Type==TARGET.ObjectType.COORDINATE then
  
    local coord=Target.Object  --Core.Point#COORDINATE
    
    return coord:ToStringMGRS()

  elseif Target.Type==TARGET.ObjectType.ZONE then
  
    local Zone=Target.Object  --Core.Zone#ZONE
    
    return Zone:GetName()
    
  elseif Target.Type==TARGET.ObjectType.SCENERY then
  
    local Zone=Target.Object  --Core.Zone#ZONE
    
    return Zone:GetName()  
  end

  return "Unknown"
end

--- Get name.
-- @param #TARGET self
-- @return #string Name of the target usually the first object.
function TARGET:GetName()
  local name=self.name or "Unknown"
  return name
end

--- Get 2D vector.
-- @param #TARGET self
-- @return DCS#Vec2 2D vector of the target.
function TARGET:GetVec2()

  for _,_target in pairs(self.targets) do
    local Target=_target --#TARGET.Object
    
    local coordinate=self:GetTargetVec2(Target)
    
    if coordinate then
      return coordinate
    end

  end

  self:E(self.lid..string.format("ERROR: Cannot get Vec2 of target %s", self.name))
  return nil
end

--- Get 3D vector.
-- @param #TARGET self
-- @return DCS#Vec3 3D vector of the target.
function TARGET:GetVec3()

  for _,_target in pairs(self.targets) do
    local Target=_target --#TARGET.Object
    
    local coordinate=self:GetTargetVec3(Target)
    
    if coordinate then
      return coordinate
    end

  end

  self:E(self.lid..string.format("ERROR: Cannot get Vec3 of target %s", self.name))
  return nil
end

--- Get coordinate.
-- @param #TARGET self
-- @return Core.Point#COORDINATE Coordinate of the target.
function TARGET:GetCoordinate()

  for _,_target in pairs(self.targets) do
    local Target=_target --#TARGET.Object
    
    local coordinate=self:GetTargetCoordinate(Target)
    
    if coordinate then
      return coordinate
    end

  end

  self:E(self.lid..string.format("ERROR: Cannot get coordinate of target %s", tostring(self.name)))
  return nil
end

--- Get average coordinate.
-- @param #TARGET self
-- @return Core.Point#COORDINATE Coordinate of the target.
function TARGET:GetAverageCoordinate()

  for _,_target in pairs(self.targets) do
    local Target=_target --#TARGET.Object
    
    local coordinate=self:GetTargetCoordinate(Target, true)
    
    if coordinate then
      return coordinate
    end

  end

  self:E(self.lid..string.format("ERROR: Cannot get average coordinate of target %s", tostring(self.name)))
  return nil
end


--- Get coordinates of all targets. (e.g. for a SET_STATIC)
-- @param #TARGET self
-- @return #table Table with coordinates of all targets.
function TARGET:GetCoordinates()
    local coordinates={}

    for _,_target in pairs(self.targets) do
        local target=_target --#TARGET.Object

        local coordinate=self:GetTargetCoordinate(target)
        if coordinate then
            table.insert(coordinates, coordinate)
        end

    end

    return coordinates
end

--- Get heading of target.
-- @param #TARGET self
-- @return #number Heading of the target in degrees.
function TARGET:GetHeading()

  for _,_target in pairs(self.targets) do
    local Target=_target --#TARGET.Object
    
    local heading=self:GetTargetHeading(Target)
    
    if heading then
      return heading
    end

  end

  self:E(self.lid..string.format("ERROR: Cannot get heading of target %s", tostring(self.name)))
  return nil
end

--- Get category.
-- @param #TARGET self
-- @return #string Target category. See `TARGET.Category.X`, where `X=AIRCRAFT, GROUND`.
function TARGET:GetCategory()
  return self.category
end


--- Get target category.
-- @param #TARGET self
-- @param #TARGET.Object Target Target object.
-- @return #TARGET.Category Target category.
function TARGET:GetTargetCategory(Target)

  local category=nil

  if Target.Type==TARGET.ObjectType.GROUP then

    if Target.Object and Target.Object:IsAlive()~=nil then
    
      local group=Target.Object --Wrapper.Group#GROUP
      
      local cat=group:GetCategory()
      
      if cat==Group.Category.AIRPLANE or cat==Group.Category.HELICOPTER then
        category=TARGET.Category.AIRCRAFT
      elseif cat==Group.Category.GROUND or cat==Group.Category.TRAIN then
        category=TARGET.Category.GROUND
      elseif cat==Group.Category.SHIP then
        category=TARGET.Category.NAVAL
      end

    end

  elseif Target.Type==TARGET.ObjectType.UNIT then

    if Target.Object and Target.Object:IsAlive()~=nil then
      local unit=Target.Object --Wrapper.Unit#UNIT
      
      local group=unit:GetGroup()

      local cat=group:GetCategory()
      
      if cat==Group.Category.AIRPLANE or cat==Group.Category.HELICOPTER then
        category=TARGET.Category.AIRCRAFT
      elseif cat==Group.Category.GROUND or cat==Group.Category.TRAIN then
        category=TARGET.Category.GROUND
      elseif cat==Group.Category.SHIP then
        category=TARGET.Category.NAVAL
      end
      
    end
  
  elseif Target.Type==TARGET.ObjectType.STATIC then
  
    return TARGET.Category.GROUND
    
  elseif Target.Type==TARGET.ObjectType.SCENERY then
  
    return TARGET.Category.GROUND
      
  elseif Target.Type==TARGET.ObjectType.AIRBASE then
  
    return TARGET.Category.AIRBASE
    
  elseif Target.Type==TARGET.ObjectType.COORDINATE then
  
    return TARGET.Category.COORDINATE

  elseif Target.Type==TARGET.ObjectType.ZONE then
  
    return TARGET.Category.ZONE
    
  elseif Target.Type==TARGET.ObjectType.OPSZONE then
  
    return TARGET.Category.OPSZONE

  else
    self:E("ERROR: unknown target category!")
  end

  return category
end


--- Get coalition of target object. If an object has no coalition (*e.g.* a coordinate) it is returned as neutral.
-- @param #TARGET self
-- @param #TARGET.Object Target Target object.
-- @return #number Coalition number.
function TARGET:GetTargetCoalition(Target)


  -- We take neutral for objects that do not have a coalition.
  local coal=coalition.side.NEUTRAL


  if Target.Type==TARGET.ObjectType.GROUP then

    if Target.Object and Target.Object:IsAlive()~=nil then    
      local object=Target.Object --Wrapper.Group#GROUP
      
      coal=object:GetCoalition()
      
    end

  elseif Target.Type==TARGET.ObjectType.UNIT then

    if Target.Object and Target.Object:IsAlive()~=nil then
      local object=Target.Object --Wrapper.Unit#UNIT
      
      coal=object:GetCoalition()
      
    end
  
  elseif Target.Type==TARGET.ObjectType.STATIC then
    local object=Target.Object --Wrapper.Static#STATIC
    
    coal=object:GetCoalition()
    
  elseif Target.Type==TARGET.ObjectType.SCENERY then
  
    -- Scenery has no coalition.
      
  elseif Target.Type==TARGET.ObjectType.AIRBASE then
    local object=Target.Object --Wrapper.Airbase#AIRBASE
  
    coal=object:GetCoalition()
    
  elseif Target.Type==TARGET.ObjectType.COORDINATE then
  
    -- Coordinate has no coalition.

  elseif Target.Type==TARGET.ObjectType.ZONE then
  
    -- Zone has no coalition.
    
  elseif Target.Type==TARGET.ObjectType.OPSZONE then
    local object=Target.Object --Ops.OpsZone#OPSZONE
  
    coal=object:GetOwner()

  else
    self:E("ERROR: unknown target category!")
  end


  return coal
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get a target object by its name.
-- @param #TARGET self
-- @param #string ObjectName Object name.
-- @return #TARGET.Object The target object table or nil.
function TARGET:GetTargetByName(ObjectName)

  for _,_target in pairs(self.targets) do
    local target=_target --#TARGET.Object
    if ObjectName==target.Name then
      return target
    end
  end

  return nil
end


--- Get the first target objective alive.
-- @param #TARGET self
-- @param Core.Point#COORDINATE RefCoordinate (Optional) Reference coordinate to determine the closest target objective.
-- @param #table Coalitions (Optional) Only consider targets of the given coalition(s). 
-- @return #TARGET.Object The target objective.
function TARGET:GetObjective(RefCoordinate, Coalitions)

  if RefCoordinate then
  
    local dmin=math.huge
    local tmin=nil --#TARGET.Object
    
    for _,_target in pairs(self.targets) do
      local target=_target --#TARGET.Object
      
      if target.Status~=TARGET.ObjectStatus.DEAD and (Coalitions==nil or UTILS.IsInTable(UTILS.EnsureTable(Coalitions), self:GetTargetCoalition(target))) then
      
        local vec3=self:GetTargetVec3(target)
        
        local d=UTILS.VecDist3D(vec3, RefCoordinate)
        
        if d<dmin then
          dmin=d
          tmin=target
        end
      
      end
      
      
    end  
  
    return tmin  
  else

    for _,_target in pairs(self.targets) do
      local target=_target --#TARGET.Object
      if target.Status~=TARGET.ObjectStatus.DEAD and (Coalitions==nil or UTILS.IsInTable(UTILS.EnsureTable(Coalitions), self:GetTargetCoalition(target))) then
        return target
      end
    end
    
  end

  return nil
end

--- Get the first target object alive.
-- @param #TARGET self
-- @param Core.Point#COORDINATE RefCoordinate Reference coordinate to determine the closest target objective.
-- @param #table Coalitions (Optional) Only consider targets of the given coalition(s). 
-- @return Wrapper.Positionable#POSITIONABLE The target object or nil.
function TARGET:GetObject(RefCoordinate, Coalitions)

  local target=self:GetObjective(RefCoordinate, Coalitions)
  
  if target then
    return target.Object
  end

  return nil
end

--- Get all target objects.
-- @param #TARGET self
-- @return #table List of target objects.
function TARGET:GetObjects()
    local objects={}

    for _,_target in pairs(self.targets) do
        local target=_target --#TARGET.Object

        table.insert(objects, target.Object)
    end

    return objects
end

--- Count alive objects.
-- @param #TARGET self
-- @param #TARGET.Object Target Target objective.
-- @param #table Coalitions (Optional) Only count targets of the given coalition(s).
-- @param #boolean OnlyReallyAlive (Optional) If `true`, count only really alive targets (units, groups) but not coordinates or zones.
-- @return #number Number of alive target objects.
function TARGET:CountObjectives(Target, Coalitions, OnlyReallyAlive)

  local N=0

  if Target.Type==TARGET.ObjectType.GROUP then

    local target=Target.Object --Wrapper.Group#GROUP
    
    local units=target:GetUnits()
    
    for _,_unit in pairs(units or {}) do
      local unit=_unit --Wrapper.Unit#UNIT
      if unit and unit:IsAlive()~=nil and unit:GetLife()>1 then
        if Coalitions==nil or UTILS.IsInTable(UTILS.EnsureTable(Coalitions), unit:GetCoalition()) then
          N=N+1
        end
      end
    end

  elseif Target.Type==TARGET.ObjectType.UNIT then
  
    local target=Target.Object --Wrapper.Unit#UNIT        
    
    if target and target:IsAlive()~=nil and target:GetLife()>1 then
      if Coalitions==nil or UTILS.IsInTable(Coalitions, target:GetCoalition()) then    
        N=N+1
      end
    end
    
  elseif Target.Type==TARGET.ObjectType.STATIC then
  
    local target=Target.Object --Wrapper.Static#STATIC
    
    if target and target:IsAlive() then
      if Coalitions==nil or UTILS.IsInTable(Coalitions, target:GetCoalition()) then
        N=N+1
      end
    end

  elseif Target.Type==TARGET.ObjectType.SCENERY then
  
    if Target.Status~=TARGET.ObjectStatus.DEAD then
      N=N+1
    end
    
  elseif Target.Type==TARGET.ObjectType.AIRBASE then
  
    local target=Target.Object --Wrapper.Airbase#AIRBASE
  
    if Target.Status==TARGET.ObjectStatus.ALIVE then
      if Coalitions==nil or UTILS.IsInTable(Coalitions, target:GetCoalition()) then
        N=N+1
      end
    end
    
  elseif Target.Type==TARGET.ObjectType.COORDINATE then
  
    -- No target, where we can check the alive status, so we assume it is alive. Changed this because otherwise target count is 0 if we pass a coordinate.
    -- This is also more consitent with the life and is alive status.
    if not OnlyReallyAlive then
      N=N+1
    end

  elseif Target.Type==TARGET.ObjectType.ZONE then
  
    -- No target, where we can check the alive status, so we assume it is alive. Changed this because otherwise target count is 0 if we pass a coordinate.
    -- This is also more consitent with the life and is alive status.
    if not OnlyReallyAlive then
      N=N+1
    end
        
  elseif Target.Type==TARGET.ObjectType.OPSZONE then
    
    local target=Target.Object --Ops.OpsZone#OPSZONE
    
    if Coalitions==nil or UTILS.IsInTable(Coalitions, target:GetOwner()) then
      N=N+1
    end
    
  else
    self:E(self.lid.."ERROR: Unknown target type! Cannot count targets")
  end

  return N
end

--- Count alive targets.
-- @param #TARGET self
-- @param #table Coalitions (Optional) Only count targets of the given coalition(s). 
-- @param #boolean OnlyReallyAlive (Optional) If `true`, count only really alive targets (units, groups) but not coordinates or zones.
-- @return #number Number of alive target objects.
function TARGET:CountTargets(Coalitions, OnlyReallyAlive)
  
  local N=0
  
  for _,_target in pairs(self.targets) do
    local Target=_target --#TARGET.Object
  
    N=N+self:CountObjectives(Target, Coalitions, OnlyReallyAlive)
    
  end
  
  return N
end

--- Check if something is an element of the TARGET.
-- @param #TARGET self
-- @param #string Name The name of the potential element.
-- @return #boolean If `true`, this name is part of this TARGET.
function TARGET:IsElement(Name)

  if Name==nil then
    return false
  end

  for _,name in pairs(self.elements) do
    if name==Name then
      return true
    end
  end
  
  return false
end

--- Check if something is a a casualty of this TARGET.
-- @param #TARGET self
-- @param #string Name The name of the potential element.
-- @return #boolean If `true`, this name is a casualty of this TARGET.
function TARGET:IsCasualty(Name)

  if Name==nil then
    return false
  end

  for _,name in pairs(self.casualties) do
    if tostring(name)==tostring(Name) then
      return true
    end
  end
  
  return false
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
