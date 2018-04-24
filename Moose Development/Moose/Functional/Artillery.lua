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

end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Assign a group of targets
-- @param #ARTY self
-- @param Wrapper.Group#GROUP group Group of targets.
-- @param #number range Range.
function ARTY:AssignTargetGroup(group, range)
  self:E({group=group, range=range})
  
  local _target={coord=group:GetCoordinate(), range=range}
  
  table.insert(self.targets, _target)
  --table.insert(self.strafeTargets, {name=_name, polygon=_polygon, coordinate= Ccenter, goodPass=goodpass, targets=_targets, foulline=foulline, smokepoints=p, heading=heading})
  
  local vec2=group:GetVec2()
  --local zone=ZONE:New("target", vec2, range)
  local zone=ZONE_RADIUS:New("target", vec2, range)
  self:_FireAtZone(zone, 10)
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

function ARTY:_OnEventShot(EventData)
  self:F(EventData)
end

function ARTY:_OnEventDead(EventData)
  self:F(EventData)
end

--- Set task for firing at a zone
-- @param #ARTY self
-- @param Wrapper.Zone#ZONE zone Zone to fire upon.
-- @param #number nshells Number of shells to fire.
function ARTY:_FireAtZone(zone, nshells)
  self:E({zone=zone, nshells=nshells})

  local group=self.Controllable --Wrapper.Controllable#CONTROLLABLE

  local units=group:GetUnits()
  local nunits=#units
  
  local nshells_tot=nshells*nunits
  
  -- set ROE to weapon free
  group:OptionROEWeaponFree()
  
  -- assign task
  local q=zone:GetVec2()
  local r=zone:GetRadius()
  local fire=group:TaskFireAtPoint(q, r, nshells_tot)
  
  -- Execute task
  group:SetTask(fire)
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