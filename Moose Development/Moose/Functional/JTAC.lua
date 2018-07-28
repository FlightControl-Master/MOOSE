--- **Functional** - (R2.4) JTAC
-- 
-- ===
-- 
-- JTAC mimic
-- 
-- ## Features:
-- 
-- * Feature 1
-- * Feature 2
-- 
-- ====
-- 
-- # Demo Missions
--
-- ### [MOOSE - ALL Demo Missions](https://github.com/FlightControl-Master/MOOSE_MISSIONS)
-- 
-- ====
-- 
-- # YouTube Channel
-- 
-- ### [MOOSE YouTube Channel](https://www.youtube.com/channel/UCjrA9j5LQoWsG4SpS8i79Qg)
-- 
-- ===
-- 
-- ### Author: **[funkyfranky](https://forums.eagle.ru/member.php?u=115026)**
-- 
-- ### Contributions: [FlightControl](https://forums.eagle.ru/member.php?u=89536)
-- 
-- ====
-- @module Functional.Jtac
-- @image JTAC.JPG

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- JTAC class
-- @type JTAC
-- @field #string ClassName Name of the class.

--- Easy assignment of JTAC.
-- 
-- A new ARTY object can be created with the @{#ARTY.New}(*group*) contructor.
-- The parameter *group* has to be a MOOSE Group object and defines ARTY group.
-- 
-- The ARTY FSM process can be started by the @{#ARTY.Start}() command.
--
-- ## The ARTY Process
-- 
-- ![Process](..\Presentations\ARTY\ARTY_Process.png)
-- 
-- 
-- 
-- @field #JTAC
JTAC={
  ClassName="JTAC",
  Debug=false,
}

--- Some ID to identify who we are in output of the DCS.log file.
-- @field #string id
JTAC.id="JTAC | "

--- Arty script version.
-- @field #string version
JTAC.version="0.0.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO list:
-- TODO: a lot.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Creates a new JTAC object.
-- @param #JTAC self
-- @param Wrapper.Group#GROUP group The GROUP object for which artillery tasks should be assigned.
-- @param alias (Optional) Alias name the group will be calling itself when sending messages. Default is the group name.
-- @return #JTAC JTAC object or nil if group does not exist or is not a ground or naval group.
function JTAC:New(group, alias)
  BASE:F2(group)

  -- Inherits from FSM_CONTROLLABLE
  local self=BASE:Inherit(self, FSM_CONTROLLABLE:New()) -- #JTAC
  
  -- Check that group is present.
  if group then
    self:T(JTAC.id..string.format("JTAC script version %s. Added group %s.", JTAC.version, group:GetName()))
  else
    self:E(JTAC.id.."ERROR: Requested JTAC group does not exist! (Has to be a MOOSE group.)")
    return nil
  end

  -- Set the controllable for the FSM.
  self:SetControllable(group)

  ---------------  
  -- Transitions:
  ---------------

  -- Entry.
  self:AddTransition("*", "Start", "Ready")
  self:AddTransition("Ready", "LaserOn", "Lasing")
  self:AddTransition("Lasing", "Lasing", "Lasing")
  self:AddTransition("Lasing", "LaserOff", "Ready")

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Start Event
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- After "Start" event.
-- @param #JTAC self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function JTAC:onafterStart(Controllable, From, Event, To)
  --self:_EventFromTo("onafterStart", Event, From, To)
  
  -- Debug output.
  local text=string.format("Started JTAC version %s for group %s.", JTAC.version, Controllable:GetName())
  self:E(JTAC.id..text)
  MESSAGE:New(text, 5):ToAllIf(self.Debug)
  
end

--- After "LaserOn" event.
-- @param #JTAC self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Unit#UNIT Target Target that should be lased.
function JTAC:onafterLaserOn(Controllable, From, Event, To, Target)
  --self:_EventFromTo("onafterStart", Event, From, To)
  
  -- Debug output.
  local text=string.format("JTAC %s lasing target %s.", Controllable:GetName(), Target:GetName())
  self:E(JTAC.id..text)
  MESSAGE:New(text, 5):ToAllIf(self.Debug)
  
  -- Start lasing.
  Controllable:LaseUnit(Target, self.LaserCode, self.Duration)
  
end


--- After "LaserOff" event.
-- @param #JTAC self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function JTAC:onafterLaserOff(Controllable, From, Event, To)
  --self:_EventFromTo("onafterStart", Event, From, To)
  
  -- Debug output.
  local text=string.format("JTAC %s stoped lasing.", Controllable:GetName())
  self:E(JTAC.id..text)
  MESSAGE:New(text, 5):ToAllIf(self.Debug)
  
  -- Turn of laser.
  Controllable:LaseOff()
  
end







