-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- **Functional** - Suppress fire of ground units when they get hit.
-- 
-- ====
-- 
-- When ground units get hit by (suppressive) enemy fire, they will not be able to shoot back for a certain amount of time.
-- 
-- The implementation is based on an idea and script by MBot. See DCS forum threat https://forums.eagle.ru/showthread.php?t=107635 for details.
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
-- @module AI_Suppression

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- AI_Suppression class
-- @type AI_Suppression
-- @field #string ClassName Name of the class.
-- @field #number Tsuppress_min Minimum time in seconds the group gets suppressed.
-- @field #number Tsuppress_max Maximum time in seconds the group gets suppressed.
-- @field #number life Relative life in precent of the group.
-- @field #number Tsuppress Time in seconds the groups is suppressed. Randomly chosen between Tsuppress_min and Tsuppress_max.
-- @field #number Thit Last time the unit was hit.
-- @field #number Nhit Number of times the unit was hit since it last was in state "CombatReady".
-- @field Core.Zone#ZONE Zone_Retreat Zone into which a group retreats.
-- @field #number LifeMin Life of group in percent at which the group will be ordered to retreat.
-- @extends Core.Fsm#FSM_CONTROLLABLE
-- 

---# AI_Suppression class, extends @{Core.Fsm#FSM_CONTROLLABLE}
-- Mimic suppressive fire and make ground units take cover.
-- 
-- ## Some Example...
-- 
-- @field AI_Suppression
AI_Suppression={
  ClassName = "AI_Suppression",
  Tsuppress_min = 5,
  Tsuppress_max = 20,
  Tsuppress = nil,
  Thit = nil,
  Nhit = 0,
  Zone_Retreat = nil,
  LifeMin = 10,
}

--- Some ID to identify who we are in output of the DCS.log file.
-- @field #string id
AI_Suppression.id="SFX | "

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--TODO: Figure out who was shooting and move away from him <== not possible.
--TODO: Move behind a scenery building if there is one nearby.
--TODO: Retreat to a given zone or point.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Creates a new AI_suppression object.
-- @param #AI_Suppression self
-- @param Wrapper.Group#GROUP Group The GROUP object for which suppression should be applied.
-- @return #AI_Suppression
function AI_Suppression:New(Group)
  env.info("Suppression fire for group "..Group:GetName())
  
  -- Check that we actually have a ground group.
  if Group:IsGround()==false then
    env.error("Suppression fire group "..Group:GetName().." has to be a GROUND group!")
    return nil
  end

  -- Inherits from FSM_CONTROLLABLE
  local self=BASE:Inherit(self, FSM_CONTROLLABLE:New()) -- #AI_Suppression
  
  -- Set the controllable for the FSM.
  self:SetControllable(Group)
  
  -- Group is initially in state CombatReady.
  self:SetStartState("CombatReady")
  
  -- Transitions:
  ---------------
  
  -- Transition from anything to "Suppressed" after event "Hit". 
  self:AddTransition("*", "Hit", "Suppressed")
  
  -- Transition from "Suppressed" back to "CombatReady after the unit had time to recover.
  self:AddTransition("Suppressed", "Recovered", "CombatReady")
  
  -- Transition from "Suppressed" to "TakeCover" after event "Hit".
  --self:AddTransition("Suppressed", "Hit", "TakeCover")
  
  -- Transition from anything to "Retreating" after e.g. being severely damaged.
  self:AddTransition("*", "Retreat", "Retreating")
  
  -- Transition from anything to "Dead" after group died.
  self:AddTransition("*", "Died", "Dead")

  
  -- Handle DCS event hit.
  self:HandleEvent(EVENTS.Hit, self.OnEventHit)
  
  -- Handle DCS event dead.
  self:HandleEvent(EVENTS.Dead, self.OnEventDead)
  
  -- return self
  return self

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set minimum and (optionally) maximum time a unit is suppressed each time it gets hit.
-- @param #AI_Suppression self
-- @param #number Tmin Minimum time in seconds.
-- @param #number Tmax (Optional) Maximum suppression time. If no value is given, the is set to Tmin.
function AI_Suppression:SetSuppressionTime(Tmin, Tmax)
  self.Tsuppress_min=Tmin
  self.Tsuppress_max=Tmax or Tmin
  env.info(AI_Suppression.id..string.format("Min suppression time %d seconds.", self.Tsuppress_min))
  env.info(AI_Suppression.id..string.format("Max suppression time %d seconds.", self.Tsuppress_max))
end

--- Set the zone to which a group retreats after being damaged too much.
-- @param #AI_Suppression self
-- @param Core.Zone#ZONE zone MOOSE zone object.
function AI_Suppression:SetRetreatZone(zone)
  self.Zone_Retreat=zone
  env.info(AI_Suppression.id..string.format("Retreat zone for group %s is %s.", self.Controllable:GetName(), self.Zone_Retreat:GetName()))
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Before "Hit" event. (Of course, this is not really before the group got hit.)
-- @param #AI_Suppression self
function AI_Suppression:OnBeforeHit(From, Event, To)
  env.info(AI_Suppression.id..string.format("OnBeforeHit: From %s, Event %s, To %s", From, Event, To))
  -- Increase Hit counter.
  self.Nhit=self.Nhit+1
  env.info(AI_Suppression.id..string.format("Group has just been hit %d times.", self.Nhit))
end

--- After "Hit" event.
-- @param #AI_Suppression self
function AI_Suppression:OnAfterHit(From, Event, To)
  env.info(AI_Suppression.id..string.format("OnAfterHit: From %s, Event %s, To %s", From, Event, To))
  
  -- Nothing to do yet. Just monitoring the event.
  -- This should go into Suppressed state.
end


--- Before "Recovered" event.
-- @param #AI_Suppression self
function AI_Suppression:OnBeforeRecovered(From, Event, To)
  env.info(AI_Suppression.id..string.format("OnBeforeRecovered: From %s, Event %s, To %s", From, Event, To))
  
  -- Current time.
  local Tnow=timer.getTime()
  
  -- Here I need to figure our how to correctly go back to "CombatReady".
  -- Problem is that another "Hit" event might occur while the group is recovering.
  -- If that happens the time to recover should be reset.
  -- Only after a unit has not been hit for X seconds.
  -- We can return false if the recovery should not be executed!
  
  env.info(AI_Suppression.id..string.format("OnBeforeRecover: Time: %d  - Time over: %d", Tnow, self.TsuppressionOver))
  
  -- Recovery is only possible if enough time since the last hit has passed.
  if Tnow > self.TsuppressionOver then
    return true
  else
    return false
  end
  
end

--- After "Recovered" event.
-- @param #AI_Suppression self
function AI_Suppression:OnAfterRecovered(From, Event, To)
  env.info(AI_Suppression.id..string.format("OnAfterRecovered: From %s, Event %s, To %s", From, Event, To))
  MESSAGE:New("Group has recovered.", 30):ToAll()
  -- Nothing to do yet. Just monitoring the event.
end


--- Before "Retreat" event.
-- @param #AI_Suppression self
function AI_Suppression:OnBeforeRetreat(From, Event, To)
  env.info(AI_Suppression.id..string.format("OnBeforeRetreat: From %s, Event %s, To %s", From, Event, To))
  
  -- Retreat is only possible if a zone has been defined by the user.
  if self.Zone_Retreat==nil then
    return false
  else
    return true
  end
  
end

--- After "Retreat" event.
-- @param #AI_Suppression self
function AI_Suppression:OnAfterRetreat(From, Event, To)
  env.info(AI_Suppression.id..string.format("OnAfterHit: From %s, Event %s, To %s", From, Event, To))
  local text=string.format("Group %s is retreating to zone %s.", self.Controllable:GetName(), self.Zone_Retreat:GetName())
  MESSAGE:New(text, 30):ToAll()
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Entering "CombatReady" state. The group will be able to fight back.
-- @param #AI_Suppression self
function AI_Suppression:OnEnterCombatReady(From, Event, To)
  env.info(AI_Suppression.id..string.format("OnEnterCombatReady: From %s, Event %s, To %s", From, Event, To))

  -- Group can fight again.
  self.Controllable:OptionROEOpenFire()
  
end

--- Leaving "CombatReady" state.
-- @param #AI_Suppression self
function AI_Suppression:OnLeaveCombatReady(From, Event, To)
  env.info(AI_Suppression.id..string.format("OnLeaveCombatReady: From %s, Event %s, To %s", From, Event, To))

  -- Nothing to do yet. Just monitoring the event
end


--- Entering "Suppressed" state. Group will not fight but hold their weapons.
-- @param #AI_Suppression self
function AI_Suppression:OnEnterSuppressed(From, Event, To)
  env.info(AI_Suppression.id..string.format("OnEnterSuppressed: From %s, Event %s, To %s", From, Event, To))

  -- Current time.
  local Tnow=timer.getTime()
  
  -- Group will hold their weapons.
  self.Controllable:OptionROEHoldFire()
  
  -- Get randomized time the unit is suppressed.
  self.Tsuppress=math.random(self.Tsuppress_min, self.Tsuppress_max)
  
  -- Time at which the suppression is over.
  self.TsuppressionOver=Tnow+self.Tsuppress
  
  -- Recovery event will be called in Tsuppress seconds. (We add one second to be sure the time has really passed when recovery is checked.)
  self:__Recover(self.Tsuppress+1)
  
  -- Get life of group in %.
  self.life=self:_GetLife(self.Controllable)
  
  -- If life is below threshold, the group is ordered to retreat (if a zone has been specified).
  if self.life < self.LifeMin then
    self:Retreat()
  end
    
end


--- Entering "Retreating" state. Group will be send to a zone.
-- @param #AI_Suppression self
function AI_Suppression:OnEnterRetreating(From, Event, To)
  env.info(AI_Suppression.id..string.format("OnEnterRetreating: From %s, Event %s, To %s", From, Event, To))

  --TODO: Here we need to set the ALARM STATE to GREEN. Then the unit can move even if it is  under fire.
  --self.Controllable:OptionROEOpenFire()
  
  --TODO: Route the group to a zone.
  
end

--- Leaving "Retreating" state.
-- @param #AI_Suppression self
function AI_Suppression:OnLeaveRetreating(From, Event, To)
  env.info(AI_Suppression.id..string.format("OnLeaveRetreating: From %s, Event %s, To %s", From, Event, To))

  -- TODO: Here we need to set the ALARM STATE back to AUTO.
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Handle the DCS event hit.
-- @param #AI_Suppression self
-- @param Core.Event#EVENTDATA EventData
function AI_Suppression:OnEventHit(EventData)
  self:E({"EventHit", EventData })
  env.info("Hitevent")

  if EventData.IniDCSUnit then
  
    -- Call "Hit" event.
    self:Hit()
    
  end  
end

--- Handle the DCS event dead.
-- @param #AI_Suppression self
-- @param Core.Event#EVENTDATA EventData
function AI_Suppression:OnEventDead(EventData)
  self:E({"EventDead", EventData })
  env.info("Deadevent")
  if EventData.IniDCSUnit then
    --self:Died()
  end  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get (relative) life of first unit of a group.
-- @param #AI_Suppression self
-- @param Wrapper.Group#GROUP group Group of unit.
-- @return #number Life of unit in percent.
function AI_Suppression:_GetLife(group)
  local life=0.0
  if group and group:IsAlive() then
    local unit=group:GetUnit(1)
    if unit then
      life=unit:GetLife()/unit:GetLife0()*100
    end
  end
  return life
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------