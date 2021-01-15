--- **Ops** - Target.
--
-- **Main Features:**
--
--    * Manages target, number alive, life points, damage etc.
--    * Events when targets are damaged or destroyed
--    * Various target objects: UNIT, GROUP, STATIC, AIRBASE, COORDINATE, SET_GROUP, SET_UNIT
--
-- ===
--
-- ### Author: **funkyfranky**
-- @module Ops.Target
-- @image OPS_Target.png


--- TARGET class.
-- @type TARGET
-- @field #string ClassName Name of the class.
-- @field #number verbose Verbosity level.
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
-- @extends Core.Fsm#FSM

--- **It is far more important to be able to hit the target than it is to haggle over who makes a weapon or who pulls a trigger** -- Dwight D. Eisenhower
--
-- ===
--
-- ![Banner Image](..\Presentations\OPS\Target\_Main.pngs)
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
  threatlevel0   =     0
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
TARGET.ObjectType={
  GROUP="Group",
  UNIT="Unit",
  STATIC="Static",
  SCENERY="Scenery",
  COORDINATE="Coordinate",
  AIRBASE="Airbase",
  ZONE="Zone",
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
TARGET.ObjectStatus={
  ALIVE="Alive",
  DEAD="Dead",
}
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
TARGET.version="0.3.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: A lot.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new TARGET object and start the FSM.
-- @param #TARGET self
-- @param #table TargetObject Target object.
-- @return #TARGET self
function TARGET:New(TargetObject)

  -- Inherit everything from INTEL class.
  local self=BASE:Inherit(self, FSM:New()) --#TARGET

  -- Increase counter.
  _TARGETID=_TARGETID+1
 
  -- Add object.
  self:AddObject(TargetObject)
  
  -- Get first target.
  local Target=self.targets[1] --#TARGET.Object
  
  if not Target then
    self:E("ERROR: No valid TARGET!")
    return nil
  end
    
  -- Target Name.
  self.name=self:GetTargetName(Target)
  
  -- Target category.
  self.category=self:GetTargetCategory(Target)
  
  -- Log ID.
  self.lid=string.format("TARGET #%03d [%s] | ", _TARGETID, tostring(self.category))

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
  
  self:AddTransition("*",                  "Damaged",             "*")           -- Target was damaged.
  self:AddTransition("*",                  "Destroyed",           "Dead")        -- Target was completely destroyed.
  self:AddTransition("*",                  "Dead",                "Dead")        -- Target was completely destroyed.

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



  -- Start.
  self:__Start(-1)

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create target data from a given object.
-- @param #TARGET self
-- @param Wrapper.Positionable#POSITIONABLE Object The target GROUP, UNIT, STATIC, AIRBASE or COORDINATE.
function TARGET:AddObject(Object)
    
  if Object:IsInstanceOf("SET_GROUP") or Object:IsInstanceOf("SET_UNIT") then

    ---
    -- Sets
    ---

    local set=Object --Core.Set#SET_GROUP
    
    for _,object in pairs(set.Set) do
      self:AddObject(object)
    end

  else
  
    ---
    -- Groups, Units, Statics, Airbases, Coordinates
    ---
  
    self:_AddObject(Object)
    
  end

end

--- Check if TARGET is alive.
-- @param #TARGET self
-- @return #boolean If true, target is alive.
function TARGET:IsAlive()
  return self:Is("Alive")
end

--- Check if TARGET is dead.
-- @param #TARGET self
-- @return #boolean If true, target is dead.
function TARGET:IsDead()
  return self:Is("Dead")
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

  -- Short info.
  local text=string.format("Starting Target")
  self:T(self.lid..text)

  self:HandleEvent(EVENTS.Dead,       self.OnEventUnitDeadOrLost)
  self:HandleEvent(EVENTS.UnitLost,   self.OnEventUnitDeadOrLost)
  self:HandleEvent(EVENTS.RemoveUnit, self.OnEventUnitDeadOrLost)

  self:__Status(-1)
end

--- On after "Status" event.
-- @param #TARGET self
-- @param Wrapper.Group#GROUP Group Flight group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function TARGET:onafterStatus(From, Event, To)

  -- FSM state.
  local fsmstate=self:GetState()
    
  -- Update damage.
  local damaged=false
  for i,_target in pairs(self.targets) do
    local target=_target --#TARGET.Object
    
    local life=target.Life
    
    target.Life=self:GetTargetLife(target)
    
    if target.Life<life then
      self:ObjectDamaged(target)
      damaged=true
    end
    
  end
  
  -- Target was damaged.
  if damaged then
    self:Damaged()
  end
  
  -- Log output verbose=1.
  if self.verbose>=1 then
    local text=string.format("%s: Targets=%d/%d Life=%.1f/%.1f Damage=%.1f", fsmstate, self:CountTargets(), self.N0, self:GetLife(), self:GetLife0(), self:GetDamage())
    if damaged then
      text=text.." Damaged!"
    end
    self:I(self.lid..text)
  end  
  
  -- Log output verbose=2.
  if self.verbose>=2 then
    local text="Target:"
    for i,_target in pairs(self.targets) do
      local target=_target --#TARGET.Object
      local damage=(1-target.Life/target.Life0)*100
      text=text..string.format("\n[%d] %s %s %s: Life=%.1f/%.1f, Damage=%.1f", i, target.Type, target.Name, target.Status, target.Life, target.Life0, damage)
    end
    self:I(self.lid..text)
  end

  -- Update status again in 30 sec.
  if self:IsAlive() then
    self:__Status(-30)
  end
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

  -- Debug info.
  self:T(self.lid..string.format("Object %s damaged", Target.Name))

end

--- On after "ObjectDestroyed" event.
-- @param #TARGET self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #TARGET.Object Target Target object.
function TARGET:onafterObjectDestroyed(From, Event, To, Target)

  -- Debug message.
  self:T(self.lid..string.format("Object %s destroyed", Target.Name))
  
  -- Increase destroyed counter.
  self.Ndestroyed=self.Ndestroyed+1
  
  -- Call object dead event.
  self:ObjectDead(Target)
  
end

--- On after "ObjectDead" event.
-- @param #TARGET self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #TARGET.Object Target Target object.
function TARGET:onafterObjectDead(From, Event, To, Target)

  -- Debug message.
  self:T(self.lid..string.format("Object %s dead", Target.Name))

  -- Set target status.
  Target.Status=TARGET.ObjectStatus.DEAD
  
  -- Increase dead counter.
  self.Ndead=self.Ndead+1
  
  -- Check if anyone is alive?
  local dead=true
  for _,_target in pairs(self.targets) do
    local target=_target --#TARGET.Object
    if target.Status==TARGET.ObjectStatus.ALIVE then
      dead=false
    end
  end
  
  -- All dead ==> Trigger destroyed event.
  if dead then
  
    if self.Ndestroyed==self.Ntargets0 then
  
      self:Destroyed()
      
    else
    
      self:Dead()
    
    end
  end

end

--- On after "Damaged" event.
-- @param #TARGET self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function TARGET:onafterDamaged(From, Event, To)

  self:T(self.lid..string.format("TARGET damaged"))

end

--- On after "Destroyed" event.
-- @param #TARGET self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function TARGET:onafterDestroyed(From, Event, To)

  self:T(self.lid..string.format("TARGET destroyed"))
  
  self:Dead()

end

--- On after "Dead" event.
-- @param #TARGET self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function TARGET:onafterDead(From, Event, To)

  self:T(self.lid..string.format("TARGET dead"))

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
    self:T3(self.lid..string.format("EVENT ID=%d: Unit %s dead or lost!", EventData.id, tostring(Name)))
    
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
    
      if EventData.id==EVENTS.RemoveUnit then
        target.Ndead=target.Ndead+1
      else
        target.Ndestroyed=target.Ndestroyed+1
        target.Ndead=target.Ndead+1
      end
      
      if target.Ndead==target.N0 then
      
        if target.Ndestroyed>=target.N0 then

          -- Debug message.
          self:T2(self.lid..string.format("EVENT ID=%d: target %s dead/lost ==> destroyed", EventData.id, tostring(target.Name)))
    
          -- Trigger object destroyed event.
          self:ObjectDestroyed(target)
        
        else
        
          -- Debug message.
          self:T2(self.lid..string.format("EVENT ID=%d: target %s removed ==> dead", EventData.id, tostring(target.Name)))
    
          -- Trigger object dead event.
          self:ObjectDead(target)
        
        end
      
      end

    end -- Event belongs to this TARGET 
    
  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Adding and Removing Targets
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create target data from a given object.
-- @param #TARGET self
-- @param Wrapper.Positionable#POSITIONABLE Object The target GROUP, UNIT, STATIC, AIRBASE or COORDINATE.
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
    
      target.Life0=1
      target.Life=1      
      target.N0=target.N0+1
      
      table.insert(self.elements, target.Name)
      
    end

  elseif Object:IsInstanceOf("SCENERY") then
  
    local scenery=Object --Wrapper.Scenery#SCENERY
    
    target.Type=TARGET.ObjectType.SCENERY
    target.Name=scenery:GetName()
    
    target.Coordinate=scenery:GetCoordinate()

    target.Life0=1
    target.Life=1
    
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
      
  elseif Object:IsInstanceOf("ZONE_BASE") then
  
    local zone=Object --Core.Zone#ZONE_BASE
    Object=zone --:GetCoordinate()
    
    target.Type=TARGET.ObjectType.ZONE
    target.Name=zone:GetName()
    
    target.Coordinate=zone:GetCoordinate()

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
      return 1
    else
      return 0
    end

  elseif Target.Type==TARGET.ObjectType.SCENERY then
  
    if Target.Status==TARGET.ObjectStatus.ALIVE then
      return 1
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

  elseif Target.Type==TARGET.ObjectType.ZONE then
  
    return 1
    
  else
    self:E("ERROR: unknown target object type in GetTargetLife!")
  end

end

--- Get current life points.
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

--- Get target 3D position vector.
-- @param #TARGET self
-- @param #TARGET.Object Target Target object.
-- @return DCS#Vec3 Vector with x,y,z components
function TARGET:GetTargetVec3(Target)

  if Target.Type==TARGET.ObjectType.GROUP then
  
    local object=Target.Object --Wrapper.Group#GROUP

    if object and object:IsAlive() then
      local vec3=object:GetVec3()
      return vec3
      
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
        
  end

  self:E(self.lid.."ERROR: Unknown TARGET type! Cannot get Vec3")
end


--- Get target coordinate.
-- @param #TARGET self
-- @param #TARGET.Object Target Target object.
-- @return Core.Point#COORDINATE Coordinate of the target.
function TARGET:GetTargetCoordinate(Target)

  if Target.Type==TARGET.ObjectType.COORDINATE then
  
    -- Coordinate is the object itself.
    return Target.Object
    
  else
    
    -- Get updated position vector.
    local vec3=self:GetTargetVec3(Target)
    
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
    
  end

  return "Unknown"
end

--- Get name.
-- @param #TARGET self
-- @return #string Name of the target usually the first object.
function TARGET:GetName()
  return self.name
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

  self:E(self.lid..string.format("ERROR: Cannot get coordinate of target %s", self.name))
  return nil
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

  else
    self:E("ERROR: unknown target category!")
  end

  return category
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
-- @return #TARGET.Object The target objective.
function TARGET:GetObjective()

  for _,_target in pairs(self.targets) do
    local target=_target --#TARGET.Object
    if target.Status==TARGET.ObjectStatus.ALIVE then
      return target
    end
  end

  return nil
end

--- Get the first target object alive.
-- @param #TARGET self
-- @return Wrapper.Positionable#POSITIONABLE The target object or nil.
function TARGET:GetObject()

  local target=self:GetObjective()
  if target then
    return target.Object
  end

  return nil
end

--- Count alive objects.
-- @param #TARGET self
-- @param #TARGET.Object Target Target objective.
-- @return #number Number of alive target objects.
function TARGET:CountObjectives(Target)

  local N=0

  if Target.Type==TARGET.ObjectType.GROUP then

    local target=Target.Object --Wrapper.Group#GROUP
    
    local units=target:GetUnits()
    
    for _,_unit in pairs(units or {}) do
      local unit=_unit --Wrapper.Unit#UNIT
      if unit and unit:IsAlive()~=nil and unit:GetLife()>1 then
        N=N+1
      end
    end

  elseif Target.Type==TARGET.ObjectType.UNIT then
  
    local target=Target.Object --Wrapper.Unit#UNIT        
    
    if target and target:IsAlive()~=nil and target:GetLife()>1 then
      N=N+1
    end
    
  elseif Target.Type==TARGET.ObjectType.STATIC then
  
    local target=Target.Object --Wrapper.Static#STATIC
    
    if target and target:IsAlive() then
      N=N+1
    end

  elseif Target.Type==TARGET.ObjectType.SCENERY then
  
    if Target.Status==TARGET.ObjectStatus.ALIVE then
      N=N+1
    end
    
  elseif Target.Type==TARGET.ObjectType.AIRBASE then
  
    if Target.Status==TARGET.ObjectStatus.ALIVE then
      N=N+1
    end
    
  elseif Target.Type==TARGET.ObjectType.COORDINATE then
  
    -- No target we can check!

  elseif Target.Type==TARGET.ObjectType.ZONE then
  
    -- No target we can check!

  else
    self:E(self.lid.."ERROR: Unknown target type! Cannot count targets")
  end

  return N
end

--- Count alive targets.
-- @param #TARGET self
-- @return #number Number of alive target objects.
function TARGET:CountTargets()
  
  local N=0
  
  for _,_target in pairs(self.targets) do
    local Target=_target --#TARGET.Object
  
    N=N+self:CountObjectives(Target)
    
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
    if name==Name then
      return true
    end
  end
  
  return false
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
