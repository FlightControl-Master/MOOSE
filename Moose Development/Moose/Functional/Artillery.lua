-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- **Functional** - Control artillery units.
-- 
-- ![Banner Image](..\Presentations\ARTILLERY\Artillery_Main.png)
-- 
-- ====
-- 
-- Make artillery fire on targets.
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
-- @extends Core.Fsm#FSM_CONTROLLABLE
-- 

---# ARTY class, extends @{Core.Fsm#FSM_CONTROLLABLE}
-- Artillery class..
-- 
-- ## Target aquisition...
-- 
-- ![Process](..\Presentations\ART\Arty_Process.png)
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
  Nshots=0,
}

--- Enumerator of possible rules of engagement.
-- @field #list ROE
ARTY.ROE={
  Hold="Weapon Hold",
  Free="Weapon Free",
  Return="Return Fire",  
}

--- Enumerator of possible alarm states.
-- @field #list AlarmState
ARTY.AlarmState={
  Auto="Auto",
  Green="Green",
  Red="Red",
}

--- Main F10 menu for suppresion, i.e. F10/Artillery.
-- @field #string MenuF10
ARTY.MenuF10=nil

--- Some ID to identify who we are in output of the DCS.log file.
-- @field #string id
ARTY.id="ARTY | "

--- Range script version.
-- @field #number version
ARTY.version="0.1.0"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO list:
-- TODO: don't know yet...

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
    self:E(ARTY.id.."ERROR! Requested ARTY group does not exist! (Has to be a MOOSE group.)")
    return nil
  end
  
  -- Check that we actually have a GROUND group.
  if group:IsGround()==false and group:IsShip()==false then
    self:E(ARTY.id..string.format("ERROR! ARTY group %s has to be a GROUND or SHIP group!",group:GetName()))
    return nil
  end  
  
  -- Set the controllable for the FSM.
  self:SetControllable(group)
  
  -- Get DCS descriptors of group.
  local DCSgroup=Group.getByName(group:GetName())
  local DCSunit=DCSgroup:getUnit(1)
  self.DCSdesc=DCSunit:getDesc()
  
  -- Get max speed the group can do and convert to km/h.
  --self.SpeedMax=self.DCSdesc.speedMaxOffRoad*3.6
  
  -- Set speed to maximum.
  --self.Speed=self.SpeedMax
  
  -- Is this infantry or not.
  self.IsInfantry=DCSunit:hasAttribute("Infantry")
  
  -- Type of group.
  self.Type=group:GetTypeName()
  
  -- Initial group strength.
  self.IniGroupStrength=#group:GetUnits()
  
  -- Set ROE and Alarm State.
  --self:SetDefaultROE("Free")
  --self:SetDefaultAlarmState("Auto")
  
  -- Transitions 
  self:AddTransition("*",           "Start",     "CombatReady")
  self:AddTransition("CombatReady", "OpenFire",  "Firing")
  self:AddTransition("Firing",      "CeaseFire", "CombatReady")
  self:AddTransition("*",           "NoAmmo",    "OutOfAmmo")
  self:AddTransition("*",           "Dead",      "*")
  
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Assign a group of target(s).
-- @param #ARTY self
-- @param Wrapper.Group#GROUP group Group of targets.
-- @param #number radius (Optional) Radius. Default is 100 m.
-- @param #number nshells (Optional) How many shells are fired on target per unit. Default 5.
-- @param #number prio (Optional) Priority of target. Number between 1 (high) and 100 (low). Default 50.
function ARTY:AssignTargetGroup(group, radius, nshells, prio)
  self:E({group=group, radius=radius, nshells=nshells, prio=prio})
  
  -- Set default values.
  nshells=nshells or 5
  radius=radius or 100
  prio=prio or 50
  prio=math.max(  1, prio)
  prio=math.min(100, prio)
  
  -- Coordinate and name.
  local coord=group:GetCoordinate()
  local name=group:GetName()
  
  -- Prepare target array.
  local _target={name=name, coord=coord, radius=radius, nshells=nshells, engaged=0, underfire=false, prio=prio}
  
  -- Add to table.
  table.insert(self.targets, _target)
  
  -- Debug info.
  env.info(ARTY.id..string.format("Added target %s, radius=%d, nshells=%d, prio=%d.", name, radius, nshells, prio))

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
  
  -- Create main F10 menu if it is not there yet.
  if self.MenuON then 
    if not ARTY.MenuF10 then
      ARTY.MenuF10 = MENU_MISSION:New("ARTY")
    end
    self:_CreateMenuGroup()
  end
    
  -- Set the current ROE and alam state.
  --self:_SetAlarmState(self.DefaultAlarmState)
  --self:_SetROE(self.DefaultROE)
  
  local text=string.format("\n******************************************************\n")
  text=text..string.format("Arty group         = %s\n", Controllable:GetName())
  text=text..string.format("Type               = %s\n", self.Type)
  text=text..string.format("******************************************************\n")
  self:T(ARTY.id..text)
  
  -- Get Ammo.
  self:_GetAmmo(self.Controllable)
  
  for _, target in pairs(self.targets) do
    env.info(ARTY.id..string.format("Target %s, radius=%d, nshells=%d, prio=%d.", target.name, target.radius, target.nshells, target.prio))
  end
  
  -- Add event handler.
  self:HandleEvent(EVENTS.Shot, self._OnEventShot)
  self:HandleEvent(EVENTS.Dead, self._OnEventDead)

  -- Start scheduler to monitor task queue.
  self.TaskQueueSched=SCHEDULER:New(nil, ARTY._CheckTaskQueue, {self}, 5, 10)

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
  self:T(ARTY.id.."EVENT SHOT: Ini unit    = "..EventData.IniUnitName)
  self:T(ARTY.id.."EVENT SHOT: Ini group   = "..EventData.IniGroupName)
  self:T(ARTY.id.."EVENT SHOT: Weapon type = ".._weapon)
  self:T(ARTY.id.."EVENT SHOT: Weapon name = ".._weaponName)
  
  local group = EventData.IniGroup --Wrapper.Group#GROUP
  
  if group and group:IsAlive() then
  
    if EventData.IniGroupName == self.Controllable:GetName() then
    
      if self.currentTarget then
      
        -- Increase number of shots fired by this group on this target.
        self.Nshots=self.Nshots+1
        
        -- Debug output.
        self:T(ARTY.id..string.format("Group %s fired shot # %d on target %s.", self.Controllable:GetName(), self.Nshots, self.currentTarget.name))
      
        -- Check if number of shots reached max.
        if self.Nshots >= self.currentTarget.nshells then
          self:CeaseFire(self.currentTarget)
          self.Nshots=0
        end
        
      else
        self:T(ARTY.id..string.format("No current target?!"))
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
function ARTY:_FireAtCoord(coord, radius, nshells)
  self:E({coord=coord, radius=radius, nshells=nshells})

  -- Controllable.
  local group=self.Controllable --Wrapper.Controllable#CONTROLLABLE

  -- Number of units.
  local units=group:GetUnits()
  local nunits=#units
  
  local nshells_tot=nshells*nunits
  
  -- Set ROE to weapon free.
  group:OptionROEWeaponFree()
  
  -- Get Vec2
  local vec2=coord:GetVec2()
  
  -- Get task.
  local fire=group:TaskFireAtPoint(vec2, radius, nshells_tot)
  
  -- Execute task.
  group:SetTask(fire)
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
  
  if self.currentTarget then
    self:T(ARTY.id..string.format("Group %s already has a target %s.", self.Controllable:GetName(), target.name))
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
    self.targets[id].underfire=true
    self.targets[id].engaged=self.targets[id].engaged+1
    self.currentTarget=target
  end
  
  -- Start firing.
  self:_FireAtCoord(target.coord, target.radius, target.nshells)
  
end

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
  
  local name=self.currentTarget.name
  
  local id=self:_GetTargetByName(name)
  
  self.targets[id].underfire=false
  
  self.currentTarget=nil
 
  --Controllable:ClearTasks()
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Go through queue of assigned tasks.
-- @param #ARTY self
function ARTY:_CheckTaskQueue()
  self:F()
  
  -- Sort targets.
  self:_SortTaskQueue()
      
  for i=1,#self.targets do
  
    local _target=self.targets[i]
  
    if _target.underfire==false then
    
      env.info(ARTY.id..string.format("Opening fire on target %s. Prio = %d, engaged = %d", _target.name, _target.prio, _target.engaged))
      
      -- Call OpenFire event.
      self:OpenFire(_target)
      
      break
    end
  end
  
end


--- Sort targets with respect to priority and number of times it was already engaged.
-- @param #ARTY self
function ARTY:_SortTaskQueue()
  self:F()
  
  -- Sort results table wrt times they have already been engaged.
  local function _sort(a, b)
    return (a.engaged < b.engaged) or (a.engaged==b.engaged and a.prio < b.prio)
  end
  table.sort(self.targets, _sort)
  
  -- Debug output.
  env.info(ARTY.id.."Sorted targets:")
  for i=1,#self.targets do
    env.info(ARTY.id..string.format("Target %s. Prio = %d, engaged = %d", self.targets[i].name, self.targets[i].prio, self.targets[i].engaged))
  end
end


--- Get the number of shells a unit or group currently has. For a group the ammo count of all units is summed up.
-- @param #ARTY self
-- @param Wrapper.Controllable#CONTROLLABLE controllable
-- @return Number of shells left
function ARTY:_GetAmmo(controllable)
  self:F2(controllable)
  
  -- Get all units.
  local units=controllable:GetUnits()
  
  -- Init counter.
  local ammo=0
    
  for _,unit in pairs(units) do
  
    local ammotable=unit:GetAmmo()
    self:T2({ammotable=ammotable})
    
    local name=unit:GetName()
    
    if ammotable ~= nil then
    
      local weapons=#ammotable
      self:T2(ARTY.id..string.format("Number of weapons %d.", weapons))
      
      for w=1,weapons do
      
        local Nammo=ammotable[w]["count"]
        local Tammo=ammotable[w]["desc"]["typeName"]
        
        -- We are specifically looking for shells here.
        if string.match(Tammo, "shell") then
        
          -- Add up all shells
          ammo=ammo+Nammo
        
          local text=string.format("Unit %s has %d rounds ammo of type %s (shells)", name, Nammo, Tammo)
          self:T(ARTY.id..text)
          MESSAGE:New(text, 10):ToAllIf(self.Debug)
        else
          local text=string.format("Unit %s has %d ammo of type %s", name, Nammo, Tammo)
          self:T(ARTY.id..text)
          MESSAGE:New(text, 10):ToAllIf(self.Debug)
        end
        
      end
    end
  end
      
  return ammo
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
      self:E(ARTY.id..string.format("Found target with name %s. Index = %d", name, i))
      return i
    end
  end
  
  self:E(ARTY.id..string.format("ERROR: Target with name %s could not be found!", name))
  return nil
end


--- Print event-from-to string to DCS log file. 
-- @param #ARTY self
-- @param #string BA Before/after info.
-- @param #string Event Event.
-- @param #string From From state.
-- @param #string To To state.
function ARTY:_EventFromTo(BA, Event, From, To)
  local text=string.format("%s: %s EVENT %s: %s --> %s", BA, self.Controllable:GetName(), Event, From, To)
  self:T(ARTY.id..text)
end


--- Split string. Cf http://stackoverflow.com/questions/1426954/split-string-in-lua
-- @param #ARTY self
-- @param #string str Sting to split.
-- @param #string sep Speparator for split.
-- @return #table Split text.
function ARTY:_split(str, sep)
  self:F2({str=str, sep=sep})
  
  local result = {}
  local regex = ("([^%s]+)"):format(sep)
  for each in str:gmatch(regex) do
      table.insert(result, each)
  end
  
  return result
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------