-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- **Functional** - Control artillery units.
-- 
-- ![Banner Image](..\Presentations\ARTY\Artillery_Main.png)
-- 
-- ====
-- 
-- The ARTY class can be used to easily assign targets for artillery units. Multiple targets can be assigned. 
-- 
-- 
-- ====
-- 
-- # Demo Missions
--
-- ### [ALL Demo Missions pack of the last release](https://github.com/FlightControl-Master/MOOSE_MISSIONS/releases)
-- 
-- ====
-- 
-- # YouTube Channel
-- 
-- ### [MOOSE YouTube Channel](https://www.youtube.com/playlist?list=PL7ZUrU4zZUl1jirWIo4t4YxqN-HxjqRkL)
-- 
-- ===
-- 
-- ### Author: **[funkyfranky](https://forums.eagle.ru/member.php?u=115026)**
-- 
-- ### Contributions: **Sven van de Velde ([FlightControl](https://forums.eagle.ru/member.php?u=89536))**
-- 
-- ====
-- @module Arty

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- ARTY class
-- @type ARTY
-- @field #string ClassName Name of the class.
-- @field #boolean Debug Write Debug messages to DCS log file and send Debug messages to all players.
-- @field #table targets Targets assigned.
-- @field #table currentTarget Holds the current target, if there is one assigned.
-- @field #number Nammo0 Initial amount total ammunition (shells+rockets+missiles) of the whole group.
-- @field #number Nshells0 Initial amount of shells of the whole group.
-- @field #number Nrockets0 Initial amount of rockets of the whole group.
-- @field #number Nmissiles0 Initial amount of missiles of the whole group.
-- @field Core.Scheduler#SCHEDULER TargetQueueSched Scheduler updating the target queue and calling OpenFire event.
-- @field #number TargetQueueUpdate Interval between updates of the target queue.
-- @field Core.Scheduler#SCHEDULER CheckRearmedSched Scheduler checking whether reaming of the ARTY group is complete.
-- @field #table DCSdesc DCS descriptors of the ARTY group.
-- @field #string Type Type of the ARTY group.
-- @field #number IniGroupStrength Inital number of units in the ARTY group.
-- @field #boolean IsArtillery If true, ARTY group has attribute "Artillery".
-- @field #number Speed Max speed of ARTY group.
-- @field Wrapper.Unit#UNIT RearmingUnit Unit designated to rearm the ARTY group.
-- @field #boolean report Arty group sends messages about their current state or target to its coaliton.
-- @field #table ammoshells Table holding names of the shell types which are included when counting the ammo. Default is {"weapons.shells"} which include most shells.
-- @field #table ammorockets Table holding names of the rocket types which are included when counting the ammo. Default is {"weapons.nurs"} which includes most unguided rockets.
-- @field #table ammomissiles Table holding names of the missile types which are included when counting the ammo. Default is {"weapons.missiles"} which includes some guided missiles.
-- @field #number Nshots Number of shots fired on current target.
-- @field #number WaitForShotTime Max time in seconds to wait until fist shot event occurs after target is assigned. If time is passed without shot, the target is deleted. Default is 300 seconds.
-- @extends Core.Fsm#FSM_CONTROLLABLE
-- 

---# ARTY class, extends @{Core.Fsm#FSM_CONTROLLABLE}
-- Artillery class..
-- 
-- ## Target aquisition...
-- 
-- ![Process](..\Presentations\ARTY\Artillery_Process.png)
-- 
-- The arty process can be described as follows.
-- 
-- ### Submenu
-- 
-- @field #ARTY
ARTY={
  ClassName = "ARTY",
  Debug = true,
  targets = {},
  currentTarget = nil,
  Nammo0=0,
  Nshells0=0,
  Nrockets0=0,
  Nmissiles0=0,
  TargetQueueSched=nil,
  TargetQueueUpdate=5,
  CheckRearmedSched=nil,
  DCSdesc=nil,
  Type=nil,
  IniGroupStrength=0,
  IsArtillery=nil,
  RearmingUnit=nil,
  report=true,
  ammoshells={"weapons.shells"},
  ammorockets={"weapons.nurs"},
  ammomissiles={"weapons.missiles"},
  Nshots=0,
  WaitForShotTime=300,
}

--- Weapong type ID. http://wiki.hoggit.us/view/DCS_enum_weapon_flag
-- @list WeaponType
ARTY.WeaponType={
  Auto=1073741822,
  UnguidedAny=805339120,
  UnguidedCannon=805306368,
  UnguidedRockets=30720,
  GuidedAny=268402702,
  GuidedMissile=268402688,
  CruiseMissile=2097152,
}

--- Some ID to identify who we are in output of the DCS.log file.
-- @field #string id
ARTY.id="ARTY | "

--- Range script version.
-- @field #number version
ARTY.version="0.4.0"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO list:
-- DONE: Delete targets from queue user function.
-- TODO: Delete entire target queue user function.
-- TODO: Add weapon types.
-- DONE: Add user defined rearm weapon types.
-- TODO: Check if target is in range. Maybe this requires a data base with the ranges of all arty units. Pfff...
-- TODO: Make ARTY move to reaming position.
-- TODO: Check that right reaming vehicle is specified. Blue M818, Red Ural-375. Are there more?
-- TODO: Check if ARTY group is still alive.
-- TODO: Handle dead events.
-- DONE: Abort firing task if no shooting event occured with 5(?) minutes. Something went wrong then. Min/max range for example.
-- DONE: Improve assigned time for engagement. Next day?

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Creates a new ARTY object.
-- @param #ARTY self
-- @param Wrapper.Group#GROUP group The GROUP object for which artillery tasks should be assigned.
-- @return #ARTY ARTY object.
-- @return nil If group does not exist or is not a ground group.
function ARTY:New(group)
  BASE:F2(group)

  -- Inherits from FSM_CONTROLLABLE
  local self=BASE:Inherit(self, FSM_CONTROLLABLE:New()) -- #ARTY
  
  -- Check that group is present.
  if group then
    self:T(ARTY.id..string.format("ARTY script version %s. Added group %s.", ARTY.version, group:GetName()))
  else
    self:E(ARTY.id.."ERROR: Requested ARTY group does not exist! (Has to be a MOOSE group.)")
    return nil
  end
  
  -- Check that we actually have a GROUND group.
  if group:IsGround()==false and group:IsShip()==false then
    self:E(ARTY.id..string.format("ERROR: ARTY group %s has to be a GROUND or SHIP group!", group:GetName()))
    return nil
  end  
  
  -- Set the controllable for the FSM.
  self:SetControllable(group)
  
  -- Get DCS descriptors of group.
  local DCSgroup=Group.getByName(group:GetName())
  local DCSunit=DCSgroup:getUnit(1)
  self.DCSdesc=DCSunit:getDesc()
  
  -- DCS descriptors.
  self:T3(ARTY.id.."DCS descriptors for group "..group:GetName())
  for id,desc in pairs(self.DCSdesc) do
    self:T3({id=id, desc=desc})
  end
  
  -- Set speed to maximum in km/h.
  self.Speed=self.DCSdesc.speedMax*3.6
  
  -- Displayed name (similar to type name below)
  self.DisplayName=self.DCSdesc.displayName
  
  -- Is this infantry or not.
  self.IsArtillery=DCSunit:hasAttribute("Artillery")
  
  -- Type of group.
  self.Type=group:GetTypeName()
  
  -- Initial group strength.
  self.IniGroupStrength=#group:GetUnits()
  
  -- Transitions 
  self:AddTransition("*",           "Start",      "CombatReady")
  self:AddTransition("CombatReady", "OpenFire",   "Firing")
  self:AddTransition("Firing",      "OpenFire",   "Firing")  -- Other target assigned
  self:AddTransition("Firing",      "CeaseFire",  "CombatReady")
  self:AddTransition("*",           "Winchester", "OutOfAmmo")
  self:AddTransition("OutOfAmmo",   "Rearm",      "Rearming")
  self:AddTransition("Rearming",    "Rearmed",    "CombatReady")
  --self:AddTransition("*",           "Dead",       "*")
  
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Add a group of target(s) for the ARTY group.
-- @param #ARTY self
-- @param Wrapper.Group#GROUP group Group of targets.
-- @param #number prio (Optional) Priority of target. Number between 1 (high) and 100 (low). Default 50.
-- @param #number radius (Optional) Radius. Default is 100 m.
-- @param #number nshells (Optional) How many shells (or rockets) are fired on target per engagement. Default 5.
-- @param #number maxengage (Optional) How many times a target is engaged. Default 1.
-- @param #string time Day time at which the target should be engaged. Passed as a string in format "08:13:45". Current task will be canceled.
-- @param #number weapontype Type of weapon to be used to attack this target. Default ARTY.WeaponType.Auto.
-- @return #string Name of the target. Can be used for further reference, e.g. deleting the target from the list.
-- @usage ARTY:AssignTargetGroup(GROUP:FindByName("Red Target"), 10, 250, 10, 2, "13:25:45")
function ARTY:AssignTargetGroup(group, prio, radius, nshells, maxengage, time, weapontype)
  self:E({group=group, prio=prio, radius=radius, nshells=nshells, maxengage=maxengage, time=time, weapontype=weapontype})
  
  -- Set default values.
  nshells=nshells or 5
  radius=radius or 100
  maxengage=maxengage or 1
  prio=prio or 50
  prio=math.max(  1, prio)
  prio=math.min(100, prio)
  weapontype=weapontype or ARTY.WeaponType.Auto
  
  -- Coordinate of target.
  local coord=group:GetCoordinate()
  local name=group:GetName()
  
  -- Name of target defined my Lat/long in Degree Minute Second format.
  --local name=coord:ToStringLLDMS()
  
  -- Check if the name has already been used for another target. If so, the function returns a new unique name.
  name=self:_CheckTargetName(name)
  
  -- Time in seconds.
  local _time=self:_ClockToSeconds(time)
  
  -- Prepare target array.
  local _target={name=name, coord=coord, radius=radius, nshells=nshells, engaged=0, underfire=false, prio=prio, maxengage=maxengage, time=_time, weapontype=weapontype}
  
  -- Add to table.
  table.insert(self.targets, _target)
  
  -- Clock.
  local _clock=self:_SecondsToClock(_target.time)
  
  -- Debug info.
  self:T(ARTY.id..string.format("Added target %s, prio=%d, radius=%d, nshells=%d, maxengage=%d, time=%s, weapontype=%d", name, prio, radius, nshells, maxengage, tostring(_clock), weapontype))
end


--- Assign coordinates of a target for the ARTY group.
-- @param #ARTY self
-- @param Wrapper.Point#COORDINATE coord Coordinates of the target.
-- @param #number prio (Optional) Priority of target. Number between 1 (high) and 100 (low). Default 50.
-- @param #number radius (Optional) Radius. Default is 100 m.
-- @param #number nshells (Optional) How many shells are fired on target per engagement. Default 5.
-- @param #number maxengage (Optional) How many times a target is engaged. Default 9999.
-- @return #string targetname Name of the target.
function ARTY:AssignTargetCoord(coord, prio, radius, nshells, maxengage)
  self:E({coord=coord, prio=prio, radius=radius, nshells=nshells, maxengage=maxengage})
  
  -- Set default values.
  nshells=nshells or 5
  radius=radius or 100
  maxengage=maxengage or 9999
  prio=prio or 50
  prio=math.max(  1, prio)
  prio=math.min(100, prio)
  
  -- Coordinate and name.
  local name=coord:ToStringLLDMS() 
  
  -- Prepare target array.
  local _target={name=name, coord=coord, radius=radius, nshells=nshells, engaged=0, underfire=false, prio=prio, maxengage=maxengage}
  
  -- Add to table.
  table.insert(self.targets, _target)
  
  -- Debug info.
  self:T(ARTY.id..string.format("Added target %s, radius=%d, nshells=%d, prio=%d, maxengage=%d.", name, prio, radius, nshells, maxengage))

  return name
end

--- Assign a unit which is responsible for rearming the ARTY group. If the unit is too far away from the ARTY group it will be guided towards the ARTY group.
-- @param #ARTY self
-- @param Wrapper.Unit#UNIT unit Unit that is supposed to rearm the ARTY group.
function ARTY:SetRearmingUnit(unit)
  self:F({unit=unit})
  self.RearmingUnit=unit
end

--- Delete target from target list.
-- @param #ARTY self
-- @param #string name Name of the target.
function ARTY:RemoveTarget(name)
  self:F2(name)
  local id=self:_GetTargetByName(name)
  if id then
    table.remove(self.targets, id)
  end
end

--- Define shell types that are counted to determine the ammo amount the ARTY group has.
-- @param #ARTY self
-- @param #table tableofnames Table of shell type names.
function ARTY:SetShellTypes(tableofnames)
  self:F2(tableofnames)
  self.ammoshells={}
  for _,_type in pairs(tableofnames) do
    table.insert(self.ammoshells, _type)
  end
end

--- Define rocket types that are counted to determine the ammo amount the ARTY group has.
-- @param #ARTY self
-- @param #table tableofnames Table of rocket type names.
function ARTY:SetRocketTypes(tableofnames)
  self:F2(tableofnames)
  self.ammorockets={}
  for _,_type in pairs(tableofnames) do
    table.insert(self.ammorockets, _type)
  end
end

--- Define missile types that are counted to determine the ammo amount the ARTY group has.
-- @param #ARTY self
-- @param #table tableofnames Table of rocket type names.
function ARTY:SetMissileTypes(tableofnames)
  self:F2(tableofnames)
  self.ammomissiles={}
  for _,_type in pairs(tableofnames) do
    table.insert(self.ammomissiles, _type)
  end
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- After "Start" event. Initialized ROE and alarm state. Starts the event handler.
-- @param #ARTY self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function ARTY:onafterStart(Controllable, From, Event, To)
  self:_EventFromTo("onafterStart", Event, From, To)
  
  local text=string.format("Started ARTY for group %s.", Controllable:GetName())
  MESSAGE:New(text, 10):ToAllIf(self.Debug)
  
  -- Set the current ROE and alam state.
  --self:_SetAlarmState(self.DefaultAlarmState)
  --self:_SetROE(self.DefaultROE)
  
  -- Get Ammo.
  self.Nammo0, self.Nshells0, self.Nrockets0, self.Nmissiles0=self:_GetAmmo(self.Controllable)
  
  local text=string.format("\n******************************************************\n")
  text=text..string.format("Arty group          = %s\n", Controllable:GetName())
  text=text..string.format("Artillery attribute = %s\n", tostring(self.IsArtillery))
  text=text..string.format("Type                = %s\n", self.Type)
  text=text..string.format("Number of units     = %d\n", self.IniGroupStrength)
  text=text..string.format("Max Speed [km/h]    = %d\n", self.Speed)
  text=text..string.format("Total ammo count    = %d\n", self.Nammo0)
  text=text..string.format("Number of shells    = %d\n", self.Nshells0)
  text=text..string.format("Number of rockets   = %d\n", self.Nrockets0)
  text=text..string.format("Number of missiles  = %d\n", self.Nmissiles0)
  text=text..string.format("******************************************************\n")
  text=text..string.format("Targets:\n")
  for _, target in pairs(self.targets) do
    local _clock=self:_SecondsToClock(target.time)
    local _weapon=self:_WeaponTypeName(target.weapontype)
    text=text..string.format("- %s, prio=%3d, radius=%5d, nshells=%4d, maxengage=%3d, time=%11s, weapon=%s\n", target.name, target.prio, target.radius, target.nshells, target.maxengage, tostring(_clock), _weapon)
  end
  text=text..string.format("******************************************************\n")
  text=text..string.format("Shell types:\n")
  for _,_type in pairs(self.ammoshells) do
    text=text..string.format("- %s\n", _type)
  end
  text=text..string.format("Rocket types:\n")
  for _,_type in pairs(self.ammorockets) do
    text=text..string.format("- %s\n", _type)
  end
  text=text..string.format("Missile types:\n")
  for _,_type in pairs(self.ammomissiles) do
    text=text..string.format("- %s\n", _type)
  end  
  text=text..string.format("******************************************************")
  self:T(ARTY.id..text)
  
  -- Add event handler.
  self:HandleEvent(EVENTS.Shot, self._OnEventShot)
  self:HandleEvent(EVENTS.Dead, self._OnEventDead)

  -- Start scheduler to monitor task queue.
  self.TargetQueueSched=SCHEDULER:New(nil, ARTY._TargetQueue, {self}, 5, self.TargetQueueUpdate)

  -- Start scheduler to monitor if ARTY group started firing within a certain time.
  self.CheckShootingSched=SCHEDULER:New(nil, ARTY._CheckShootingStarted, {self}, 60, 60)

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Eventhandler for shot event.
-- @param #ARTY self
-- @param Core.Event#EVENTDATA EventData
function ARTY:_OnEventShot(EventData)
  self:F(EventData)
  
    -- Weapon data.
  local _weapon = EventData.Weapon:getTypeName()  -- should be the same as Event.WeaponTypeName
  local _weaponStrArray = self:_split(_weapon,"%.")
  local _weaponName = _weaponStrArray[#_weaponStrArray]
  
  -- Debug info.
  self:T3(ARTY.id.."EVENT SHOT: Ini unit    = "..EventData.IniUnitName)
  self:T3(ARTY.id.."EVENT SHOT: Ini group   = "..EventData.IniGroupName)
  self:T3(ARTY.id.."EVENT SHOT: Weapon type = ".._weapon)
  self:T3(ARTY.id.."EVENT SHOT: Weapon name = ".._weaponName)
  
  local group = EventData.IniGroup --Wrapper.Group#GROUP
  
  if group and group:IsAlive() then
  
    if EventData.IniGroupName == self.Controllable:GetName() then
    
      if self.currentTarget then
      
        -- Increase number of shots fired by this group on this target.
        self.Nshots=self.Nshots+1
        
        -- Debug output.
        local text=string.format("Group %s fired shot %d of %d with weapon %s on target %s.", self.Controllable:GetName(), self.Nshots, self.currentTarget.nshells, _weaponName, self.currentTarget.name)
        self:T(ARTY.id..text)
        MESSAGE:New(text, 5):ToAllIf(self.Debug)
        
        -- Get current ammo.
        local _nammo,_nshells,_nrockets,_nmissiles=self:_GetAmmo(self.Controllable)
        
        if _nammo==0 then
        
          self:E(ARTY.id..string.format("Group %s completely out of ammo.", self.Controllable:GetName()))
          self:Winchester()
          
          -- Current target is deallocated ==> return
          return
        end
        
        -- Weapon type name for current target.
        local _weapontype=self:_WeaponTypeName(self.currentTarget.weapontype)
        self:E(ARTY.id..string.format("nammo=%d, nshells=%d, nrockets=%d, nmissiles=%d", _nammo, _nshells, _nrockets, _nmissiles))
        self:E(ARTY.id..string.format("Weapontype = %s", _weapontype))        
        
        -- Special weapon type requested ==> Check if corresponding ammo is empty.
        if self.currentTarget.weapontype==ARTY.WeaponType.UnguidedCannon and _nshells==0 then
        
          self:T(ARTY.id.."Cannons requested and shells empty.")
          self:CeaseFire(self.currentTarget)
          return
        
        elseif self.currentTarget.weapontype==ARTY.WeaponType.UnguidedRockets and _nrockets==0 then

          self:T(ARTY.id.."Rockets requested and rockets empty.")
          self:CeaseFire(self.currentTarget)
          return
        
        elseif self.currentTarget.weapontype==ARTY.WeaponType.UnguidedAny and _nshells+_nrockets==0 then
        
          self:T(ARTY.id.."Unguided weapon requested and shells+rockets empty.")
          self:CeaseFire(self.currentTarget)
          return
        
        elseif self.currentTarget.weapontype==ARTY.WeaponType.CruiseMissile and _nmissiles==0 then
        
          self:E(ARTY.id.."Cruise missiles requested and missiles empty.")
          self:CeaseFire(self.currentTarget)
          return
        end
       
        -- Check if number of shots reached max.
        if self.Nshots >= self.currentTarget.nshells then
          local text=string.format("Group %s stop firing on target %s.", self.Controllable:GetName(), self.currentTarget.name)
          self:T(ARTY.id..text)
          MESSAGE:New(text, 5):ToAllIf(self.Debug)
          
          -- Cease fire.
          self:CeaseFire(self.currentTarget)
        end
        
      else
        self:E(ARTY.id..string.format("ERROR: No current target?!"))
      end        
    end
  end
end

--- Eventhandler for dead event.
-- @param #ARTY self
-- @param Core.Event#EVENTDATA EventData
function ARTY:_OnEventDead(EventData)
  self:F(EventData)
end

--- Set task for firing at a coordinate.
-- @param #ARTY self
-- @param Core.Point#COORDINATE coord Coordinates to fire upon.
-- @param #number radius Radius around coordinate.
-- @param #number nshells Number of shells to fire.
-- @param #number weapontype Type of weapon to use.
function ARTY:_FireAtCoord(coord, radius, nshells, weapontype)
  self:E({coord=coord, radius=radius, nshells=nshells})

  -- Controllable.
  local group=self.Controllable --Wrapper.Controllable#CONTROLLABLE

  -- Set ROE to weapon free.
  group:OptionROEOpenFire()
  
  -- Get Vec2
  local vec2=coord:GetVec2()
  
  -- Get task.
  local fire=group:TaskFireAtPoint(vec2, radius, nshells, weapontype)
  
  -- Execute task.
  group:SetTask(fire)
  --group:PushTask(fire)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Before "OpenFire" event.
-- @param #ARTY self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #table target Array holding the target info.
-- @return #boolean If true proceed to onafterOpenfire.
function ARTY:onbeforeOpenFire(Controllable, From, Event, To, target)
  self:_EventFromTo("onbeforeOpenFire", Event, From, To)
  
  
  -- If this target has an attack time and it's prio is higher than the current task, we allow the transition.
  if target.time~=nil and self.currentTarget~=nil and self.currentTarget.prio > target.prio then
    -- Debug info.
    self:T(ARTY.id..string.format("Group %s current target %s has lower prio than new target %s with attack time.", self.Controllable:GetName(), self.currentTarget.name, target.name))
    
    -- Reset current task.
    --self.Controllable:ClearTasks()
    
    -- Set number of shots counter to zero.
    self.Nshots=0
    
    -- Stop firing on current target.
    self:CeaseFire(self.currentTarget)
    
    -- Alow transition to onafterOpenfire.
    return true
  end
  
  -- Check that group has no current target already.
  if self.currentTarget then
    -- Debug info.
    self:T(ARTY.id..string.format("Group %s already has a target %s.", self.Controllable:GetName(), self.currentTarget.name))
    
    -- Deny transition.
    return false
  end
    
  return true
end

--- After "OpenFire" event.
-- @param #ARTY self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #table target Array holding the target info. _target={coord=coord, radius=radius, nshells=nshells, engaged=0, underattack=false}
function ARTY:onafterOpenFire(Controllable, From, Event, To, target)
  self:_EventFromTo("onafterOpenFire", Event, From, To)
  
  local _coord=target.coord --Core.Point#COORDINATE
  
  --_coord:MarkToAll("Arty Target")
    
  -- Get target array index.
  local id=self:_GetTargetByName(target.name)
  
  -- Target is now under fire and has been engaged once more.
  if id then
    -- Set under fire flag.
    self.targets[id].underfire=true
    -- Increase engaged counter
    self.targets[id].engaged=self.targets[id].engaged+1
    -- Clear the attack time.
    self.targets[id].time=nil
    -- Set current target.
    self.currentTarget=target
    -- Set time the target was assigned.
    self.currentTarget.Tassigned=timer.getTime()
  end
  
  -- Distance to target
  local range=Controllable:GetCoordinate():Get2DDistance(target.coord)
    
  -- Send message.
  local text=string.format("%s, opening fire on target %s with %s shells. Distance %.1f km.", Controllable:GetName(), target.name, target.nshells, range/1000)
  self:T(ARTY.id..text)
  MESSAGE:New(text, 10):ToCoalitionIf(Controllable:GetCoalition(), self.report)
  
  -- Start firing.
  self:_FireAtCoord(target.coord, target.radius, target.nshells, target.weapontype)
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Before "CeaseFire" event.
-- @param #ARTY self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #table target Array holding the target info.
-- @return #boolean
function ARTY:onbeforeCeaseFire(Controllable, From, Event, To, target)
  self:_EventFromTo("onbeforeCeaseFire", Event, From, To)
    
  return true
end

--- After "CeaseFire" event.
-- @param #ARTY self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #table target Array holding the target info.
function ARTY:onafterCeaseFire(Controllable, From, Event, To, target)
  self:_EventFromTo("onafterCeaseFire", Event, From, To)
    
  -- Send message.
  local text=string.format("%s, ceasing fire on target %s.", Controllable:GetName(), target.name)
  self:T(ARTY.id..text)
  MESSAGE:New(text, 10):ToCoalitionIf(Controllable:GetCoalition(), self.report)
  
  -- Set number of shots to zero.
  self.Nshots=0
    
  -- Get target array index.
  local id=self:_GetTargetByName(target.name)
  
  -- Target is not under fire any more.
  self.targets[id].underfire=false
  
  -- If number of engagements has been reached, the target is removed.
  if target.engaged >= target.maxengage then
    self:RemoveTarget(target.name)
  end
  
  -- ARTY group has no current target any more.
  self.currentTarget=nil
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- After "Winchester" event. Group is out of ammo.
-- @param #ARTY self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function ARTY:onafterWinchester(Controllable, From, Event, To)
  self:_EventFromTo("onafterWinchester", Event, From, To)
  
  -- Send message.
  local text=string.format("%s, winchester.", Controllable:GetName())
  self:T(ARTY.id..text)
  MESSAGE:New(text, 30):ToCoalitionIf(Controllable:GetCoalition(), self.report or self.Debug)
  
  -- Cease fire first.
  self:CeaseFire(self.currentTarget)
    
  -- Init rearming if possible.
  self:Rearm()
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Before "Rearm" event. Check if a unit to rearm the ARTY group has been defined.
-- @param #ARTY self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function ARTY:onbeforeRearm(Controllable, From, Event, To)
  self:_EventFromTo("onbeforeRearm", Event, From, To)
  
  if self.RearmingUnit and self.RearmingUnit:IsAlive() then
    return true
  else
    return false
  end
  
end


--- After "Rearm" event. Send message if reporting is on. Route rearming unit to ARTY group.
-- @param #ARTY self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function ARTY:onafterRearm(Controllable, From, Event, To)
  self:_EventFromTo("onafterRearm", Event, From, To)
  
  -- Send message.
  local text=string.format("%s, %s, request rearming.", Controllable:GetName(), self.RearmingUnit:GetName())
  self:T(ARTY.id..text)
  MESSAGE:New(text, 10):ToCoalitionIf(Controllable:GetCoalition(), self.report or self.Debug)
  
  -- Random point 20-100 m away from unit.
  local coord=self.Controllable:GetCoordinate()
  local vec2=coord:GetRandomVec2InRadius(20, 100)
  local pops=COORDINATE:NewFromVec2(vec2)
  
  -- Route unit to ARTY group.
  self.RearmingUnit:RouteGroundOnRoad(pops, 50, 5)
  
  -- Start scheduler to monitor ammo count until rearming is complete.
  self.CheckRearmedSched=SCHEDULER:New(nil,self._CheckRearmed, {self}, 20, 20)
end


--- Check if ARTY group is reamed.
-- @param #ARTY self
function ARTY:_CheckRearmed()
  self:F2()

  -- Get current ammo.
  local nammo,nshells,nrockets,nmissiles=self:_GetAmmo(self.Controllable)
  
  -- Rearming status in per cent.
  local _rearmpc=nammo/self.Nammo0*100
  
  -- Send message.
  local text=string.format("%s, rearming %d %% complete.", self.Controllable:GetName(), _rearmpc)
  self:T(ARTY.id..text)
  MESSAGE:New(text, 10):ToCoalitionIf(self.Controllable:GetCoalition(), self.report or self.Debug)
    
  -- Rearming --> Rearmed --> CombatReady
  if nammo==self.Nammo0 then
    self:Rearmed()
  end

end

--- After "Rearmed" event. Send message if reporting is on and stop the scheduler.
-- @param #ARTY self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function ARTY:onafterRearmed(Controllable, From, Event, To)
  self:_EventFromTo("onafterRearmed", Event, From, To)
  
  -- Send message.
  local text=string.format("%s, rearming complete.", Controllable:GetName())
  self:T(ARTY.id..text)
  MESSAGE:New(text, 10):ToCoalitionIf(Controllable:GetCoalition(), self.report)
  
  -- Stop scheduler.
  self.CheckRearmedSched:Stop()
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Go through queue of assigned tasks.
-- @param #ARTY self
function ARTY:_TargetQueue()
  self:F2()
    
  -- Debug info
  self:T(ARTY.id..string.format("Group %s, number of targets = %d", self.Controllable:GetName(), #self.targets))
  
  -- No targets assigned at the moment.
  if #self.targets==0 then
    self:T(ARTY.id..string.format("Group %s, no targets assigned at the moment. No need for _TargetQueue.", self.Controllable:GetName()))
    return
  end
  
  -- First check if there is a target with a certain time for attack.
  for i=1,#self.targets do
    local _target=self.targets[i]
    if _target and _target.time then
      if timer.getAbsTime() >= _target.time and _target.underfire==false then
              
        -- Clock time format.
        local _clock=self:_SecondsToClock(_target.time)
        local _Cnow=self:_SecondsToClock(timer.getAbsTime())
      
        -- Debug info.
        self:T(ARTY.id..string.format("Engaging timed target %s. Prio=%d, engaged=%d, time=%s, tnow=%s",_target.name,_target.prio,_target.engaged,_clock,_Cnow))
        
        -- Call OpenFire event.
        self:OpenFire(_target)
        
      end
    end
  end
  
  -- Sort targets w.r.t. prio and number times engaged already.
  self:_SortTargetQueuePrio()
      
  -- Loop over all sorted targets.
  for i=1,#self.targets do
  
    local _target=self.targets[i]
  
    if _target.underfire==false and _target.time==nil and _target.maxengage > _target.engaged then
      
      -- Debug info.
      self:T(ARTY.id..string.format("Engaging target %s. Prio = %d, engaged = %d", _target.name, _target.prio, _target.engaged))

      -- Call OpenFire event.
      self:OpenFire(_target)
            
      break
    end
  end
 
end


--- Sort targets with respect to priority and number of times it was already engaged.
-- @param #ARTY self
function ARTY:_SortTargetQueuePrio()
  self:F2()
  
  -- Sort results table wrt times they have already been engaged.
  local function _sort(a, b)
    return (a.engaged < b.engaged) or (a.engaged==b.engaged and a.prio < b.prio)
  end
  table.sort(self.targets, _sort)
  
  -- Debug output.
  self:T2(ARTY.id.."Sorted targets wrt prio and number of engagements:")
  for i=1,#self.targets do
    self:T2(ARTY.id..string.format("Target %s, prio=%d, engaged=%d", self.targets[i].name, self.targets[i].prio, self.targets[i].engaged))
  end
end

--- Sort targets with respect to engage time.
-- @param #ARTY self
function ARTY:_SortTargetQueueTime()
  self:F2()

  -- Sort targets w.r.t attack time.
  local function _sort(a, b)
    if a.time == nil and b.time == nil then
      return false
    end
    if a.time == nil then
      return false
    end
    if b.time == nil then
      return true
    end
    return a.time < b.time
  end
  table.sort(self.targets, _sort)

  -- Debug output.
  self:T2(ARTY.id.."Sorted targets wrt time:")
  for i=1,#self.targets do
    self:T2(ARTY.id..string.format("Target %s, prio=%d, engaged=%d", self.targets[i].name, self.targets[i].prio, self.targets[i].engaged))
  end

end

--- Get the number of shells a unit or group currently has. For a group the ammo count of all units is summed up.
-- @param #ARTY self
-- @param Wrapper.Controllable#CONTROLLABLE controllable
-- @return Number of ALL shells left from the whole group.
function ARTY:_GetAmmo(controllable)
  self:F2(controllable)
  
  -- Get all units.
  local units=controllable:GetUnits()
  
  -- Init counter.
  local nammo=0
  local nshells=0
  local nrockets=0
  local nmissiles=0
    
  for _,unit in pairs(units) do
  
    if unit and unit:IsAlive() then
  
      local ammotable=unit:GetAmmo()
      self:T({ammotable=ammotable})
      
      local name=unit:GetName()
      
      if ammotable ~= nil then
      
        local weapons=#ammotable
        
        self:T2(ARTY.id..string.format("Number of weapons %d.", weapons))
        self:T2(ammotable)
        
        -- Loop over all weapons.
        for w=1,weapons do
        
          -- Number of current weapon.
          local Nammo=ammotable[w]["count"]
          
          -- Typename of current weapon
          local Tammo=ammotable[w]["desc"]["typeName"]
          
          -- Check for correct shell type.
          local _gotshell=false
          for _,_type in pairs(self.ammoshells) do
            if string.match(Tammo, _type) then
              _gotshell=true
            end
          end

          -- Check for correct rocket type.
          local _gotrocket=false
          for _,_type in pairs(self.ammorockets) do
            if string.match(Tammo, _type) then
              _gotrocket=true
            end
          end

          -- Check for correct missile type.
          local _gotmissile=false
          for _,_type in pairs(self.ammomissiles) do
            if string.match(Tammo,_type) then
              _gotmissile=true
            end
          end
          
                 
          -- We are specifically looking for shells or rockets here.
          if _gotshell then 
          
            -- Add up all shells.
            nshells=nshells+Nammo
          
            -- Debug info.
            local text=string.format("Unit %s has %d shells of type %s", name, Nammo, Tammo)
            self:T2(ARTY.id..text)
            MESSAGE:New(text, 10):ToAllIf(self.Debug and not self.report)
            
          elseif _gotrocket then
          
            -- Add up all rockets.
            nrockets=nrockets+Nammo
            
            -- Debug info.
            local text=string.format("Unit %s has %d rockets of type %s", name, Nammo, Tammo)
            self:T2(ARTY.id..text)
            MESSAGE:New(text, 10):ToAllIf(self.Debug and not self.report)
            
          elseif _gotmissile then
          
            -- Add up all rockets.
            nmissiles=nmissiles+Nammo
            
            -- Debug info.
            local text=string.format("Unit %s has %d missiles of type %s", name, Nammo, Tammo)
            self:T2(ARTY.id..text)
            MESSAGE:New(text, 10):ToAllIf(self.Debug and not self.report)          
                    
          else
          
            -- Debug info.
            local text=string.format("Unit %s has %d ammo of type %s", name, Nammo, Tammo)
            self:T2(ARTY.id..text)
            MESSAGE:New(text, 10):ToAllIf(self.Debug and not self.report)
            
          end
          
        end
      end
    end
  end
      
  -- Total amount of ammunition.
  nammo=nshells+nrockets+nmissiles
  
  return nammo, nshells, nrockets, nmissiles
end


--- Check whether shooting started within a certain time (~5 min). If not, the current target is considered invalid and removed from the target list.
-- @param #ARTY self
function ARTY:_CheckShootingStarted()
  self:F2()
  
  if self.currentTarget then
  
    -- Current time.
    local Tnow=timer.getTime()  
    
    -- Time that passed after current target has been assigned.
    local dt=Tnow-self.currentTarget.Tassigned
    

    if dt > self.WaitForShotTime and self.Nshots==0 then
    
      -- Get name and id of target.
      local name=self.currentTarget.name
         
      -- Debug info.
      self:T(ARTY.id..string.format("%s, no shot event after %d seconds. Removing current target %s from list.", self.Controllable:GetName(), self.WaitForShotTime, name))
    
      -- CeaseFire.
      self:CeaseFire(self.currentTarget)
    
      -- Remove target from list.
      self:RemoveTarget(name)
      
    end
  end
end

--- Get a target by its name.
-- @param #ARTY self
-- @param #string name Name of target.
-- @return #number Arrayindex of target.
function ARTY:_GetTargetByName(name)
  self:F2(name)
  
  for i=1,#self.targets do
    local targetname=self.targets[i].name
    if targetname==name then
      self:T2(ARTY.id..string.format("Found target with name %s. Index = %d", name, i))
      return i
    end
  end
  
  self:E(ARTY.id..string.format("ERROR: Target with name %s could not be found!", name))
  return nil
end


--- Get the weapon type name, which should be used to attack the target.
-- @param #ARTY self
-- @param #string name Desired target name.
-- @return #string Unique name, which is not already given for another target.
function ARTY:_CheckTargetName(name)
  self:F2(name)  

  local newname=name
  local counter=1
  
  repeat
    -- We assume the name is unique.
    local unique=true
    
    -- Loop over all targets already defined.
    for _,_target in pairs(self.targets) do
    
      -- Target name.
      local _targetname=_target.name
      
      if _targetname==newname then
        -- Define new name = "name #01"
        newname=string.format("%s #%02d", name, counter)
        
        -- Increase counter.
        counter=counter+1
        
        -- Name is already used for another target ==> try again with new name.
        unique=false
      end      
    end
    
  until (unique)
  
  -- Debug output and return new name.
  self:T(string.format("Original name %s, new name = %s", name, newname))
  return newname
end

--- Get the weapon type name, which should be used to attack the target.
-- @param #ARTY self
-- @param #number tnumber Number of weapon type ARTY.WeaponType.XXX
-- @return #number tnumber of weapon type.
function ARTY:_WeaponTypeName(tnumber)
  local name="unknown"
  if tnumber==ARTY.WeaponType.Auto then
    name="Auto (Cannon, Rockets, Missiles)"
  elseif tnumber==ARTY.WeaponType.CruiseMissile then
    name="Cruise Missile"
  elseif tnumber==ARTY.WeaponType.GuidedAny then
    name="Any Guided Missile"
  elseif tnumber==ARTY.WeaponType.GuidedMissile then
    name="Guided Missile"
   elseif tnumber==ARTY.WeaponType.UnguidedAny then
    name="Any Unguided Weapon (Cannon or Rockets)"
  elseif tnumber==ARTY.WeaponType.UnguidedCannon then
    name="Unguided Cannon"
  elseif tnumber==ARTY.WeaponType.UnguidedRockets then
    name="Unguided Rockets"
  end
  
  return name
end

--- Print event-from-to string to DCS log file. 
-- @param #ARTY self
-- @param #string BA Before/after info.
-- @param #string Event Event.
-- @param #string From From state.
-- @param #string To To state.
function ARTY:_EventFromTo(BA, Event, From, To)
  local text=string.format("%s: %s EVENT %s: %s --> %s", BA, self.Controllable:GetName(), Event, From, To)
  self:T3(ARTY.id..text)
end


--- Split string. C.f. http://stackoverflow.com/questions/1426954/split-string-in-lua
-- @param #ARTY self
-- @param #string str Sting to split.
-- @param #string sep Speparator for split.
-- @return #table Split text.
function ARTY:_split(str, sep)
  self:F3({str=str, sep=sep})
  
  local result = {}
  local regex = ("([^%s]+)"):format(sep)
  for each in str:gmatch(regex) do
    table.insert(result, each)
  end
  
  return result
end

--- Convert time in seconds to hours, minutes and seconds.
-- @param #ARTY self
-- @param #number seconds Time in seconds.
-- @return #string Time in format Hours:minutes:seconds.
function ARTY:_SecondsToClock(seconds)
  self:F3({seconds=seconds})
  
  if seconds==nil then
    return nil
    --return "00:00:00"
  end
  
  -- Seconds
  local seconds = tonumber(seconds)
  
  -- Seconds of this day.
  local _seconds=seconds%(60*60*24)

  if seconds <= 0 then
    return "00:00:00"
  else
    local hours = string.format("%02.f", math.floor(_seconds/3600))
    local mins  = string.format("%02.f", math.floor(_seconds/60 - (hours*60)))
    local secs  = string.format("%02.f", math.floor(_seconds - hours*3600 - mins *60))
    local days = string.format("%d", seconds/(60*60*24))
    return hours..":"..mins..":"..secs.."+"..days
    --return hours, mins, secs
  end
end

--- Convert clock time from hours, minutes and seconds to seconds.
-- @param #ARTY self
-- @param #string clock String of clock time. E.g., "06:12:35".
function ARTY:_ClockToSeconds(clock)
  self:F3({clock=clock})
  
  if clock==nil then
    return nil
  end
  
  -- Seconds init.
  local seconds=0
  
  -- Split additional days.
  local dsplit=self:_split(clock, "+")
  
  -- Convert days to seconds.
  if #dsplit>1 then
    seconds=seconds+tonumber(dsplit[2])*60*60*24
  end

  -- Split hours, minutes, seconds    
  local tsplit=self:_split(dsplit[1], ":")

  -- Get time in seconds
  local i=1
  for _,time in ipairs(tsplit) do
    if i==1 then
      -- Hours
      seconds=seconds+tonumber(time)*60*60
    elseif i==2 then
      -- Minutes
      seconds=seconds+tonumber(time)*60
    elseif i==3 then
      -- Seconds
      seconds=seconds+tonumber(time)
    end
    i=i+1
  end
  
  self:T3(ARTY.id..string.format("Clock %s = %d seconds", clock, seconds))
  return seconds
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------