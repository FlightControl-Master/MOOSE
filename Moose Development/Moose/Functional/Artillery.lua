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
  Debug = false,
  targets = {},
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
    self:T(ARTY.id.."ARTY group "..group:GetName())
  else
    self:E(ARTY.id.."ARTY: Requested group does not exist! (Has to be a MOOSE group.)")
    return nil
  end
  
  -- Check that we actually have a GROUND group.
  if group:IsGround()==false and group:IsShip()==false then
    self:E(ARTY.id.."ARTY group "..group:GetName().." has to be a GROUND or SHIP group!")
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
  self:AddTransition("*",           "Dead",      "*")
  
  return self
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
    
  -- Add event handler.
  self:HandleEvent(EVENTS.Shot, self._OnEventShot)
  self:HandleEvent(EVENTS.Dead, self._OnEventDead)

  -- Start scheduler to monitor task queue.
  self.TaskQueueSched=SCHEDULER:New(nil, ARTY._CheckTaskQueue, {self}, 5, 10)

end

--- Assign a group of targets
-- @param #ARTY self
function ARTY:_CheckTaskQueue()
  self:F()
  
  local _counter=0
  for _,target in pairs(self.targets) do
    if target.underfire==false then
      env.info(ARTY.id..string.format("Opening fire on target %s", target.name))
      self:OpenFire(target)
      break
    end
  end
  
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Assign a group of targets
-- @param #ARTY self
-- @param Wrapper.Group#GROUP group Group of targets.
-- @param #number radius (Optional) Radius. Default is 100 m.
-- @param #number nshells (Optional) How many shells are fired on target per unit. Default 5.
function ARTY:AssignTargetGroup(group, radius, nshells)
  self:E({group=group, radius=radius, nshells=nshells})
  
  nshells=nshells or 5
  radius=radius or 100
  
  local coord=group:GetCoordinate()
  local name=group:GetName()
  
  -- Prepare target array.
  local _target={name=name, coord=coord, radius=radius, nshells=nshells, engaged=0, underfire=false}
  
  -- Add to table.
  table.insert(self.targets, _target)
  
  -- Debug info.
  env.info(ARTY.id.."Targets:")
  for _,target in pairs(self.targets) do
    env.info(ARTY.id..string.format("Name: %s", target.name))
  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function ARTY:_OnEventShot(EventData)
  env.info("Event Shot")
  self:F(EventData)
end

function ARTY:_OnEventDead(EventData)
  self:F(EventData)
end

--- Set task for firing at a coordinate.
-- @param #ARTY self
-- @param Core.Point#COORDINATE coord Coordinates to fire upon.
-- @param #number radius Radius around coordinate.
-- @param #number nshells Number of shells to fire per unit.
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
-- @param #SUPPRESSION self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #table target Array holding the target info.
-- @return boolean
function ARTY:onbeforeOpenFire(Controllable, From, Event, To, target)
  self:_EventFromTo("onbeforeOpenFire", Event, From, To)
    
  return true
end

--- After "OpenFire" event.
-- @param #SUPPRESSION self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #table target Array holding the target info. _target={coord=coord, radius=radius, nshells=nshells, engaged=0, underattack=false}
function ARTY:onbeforeOpenFire(Controllable, From, Event, To, target)
  self:_EventFromTo("onafterOpenFire", Event, From, To)
  
  local _coord=target.coord --Core.Point#COORDINATE
  
  --_coord:MarkToAll("Arty Target")

  self:_FireAtCoord(target.coord, target.radius, target.nshells)
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Print event-from-to string to DCS log file. 
-- @param #ARTY self
-- @param #string BA Before/after info.
-- @param #string Event Event.
-- @param #string From From state.
-- @param #string To To state.
function ARTY:_EventFromTo(BA, Event, From, To)
  local text=string.format("\n%s: %s EVENT %s: %s --> %s", BA, self.Controllable:GetName(), Event, From, To)
  self:T(ARTY.id..text)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------