---
-- @module AI_Suppression

--- @type AI_Suppression
-- @extends Core.Fsm#FSM_CONTROLLABLE
-- 

--TODO: Figure out who was shooting and move away from him.
--TODO: Move behind a scenery building if there is one nearby.
--TODO: Retreat to a given zone or point.
--TODO: 

-- @field AI_Suppression
AI_Suppression={}

--- Creates a new AI_suppression object
-- @param #AI_Suppression self
-- @param Wrapper.Group#GROUP Group The GROUP object for which suppression should be applied.
-- @return #AI_Suppression
function AI_Suppression:New(Group)
  env.info("Suppression Fire for group "..Group:GetName())

  -- Inherits from FSM_CONTROLLABLE
  local self=BASE:Inherit(self, FSM_CONTROLLABLE:New()) -- #AI_Suppression
  
  self:SetControllable(Group)
  
  self.life=self.Controllable:GetLife()
  
  self.Tsuppressed=0
  
  -- Time the group is suppressed after being hit.
  self.Tsuppress=40
  
  self:SetStartState("CombatReady")
  
  self:AddTransition("*", "Status", "*")
  
  self:AddTransition("*", "Hit", "Suppressed")
  
  self:AddTransition("Suppressed", "Recovered", "CombatReady")
  
  self:AddTransition("*", "Hit", "TakeCover")
  
  -- Handle the event hit.
  self:HandleEvent(EVENTS.Hit, self.OnEventHit)
  
    -- Handle the event dead.
  self:HandleEvent(EVENTS.Dead, self.OnEventDead)
  
  --self:AddTransition("Suppressed", "Status", "CombatReady")
  
end


--- Before status event.
-- @param #AI_Suppression self
function AI_Suppression:OnBeforeStatus()
  return self.CheckStatus
end

--- After status event.
-- @param #AI_Suppression self
function AI_Suppression:OnBeforeStatus()
  self:__Status(10)
end

--- After hit event.
-- @param #AI_Suppression self
function AI_Suppression:OnAfterHit(From, Event, To)

end

--- After hit event.
-- @param #AI_Suppression self
function AI_Suppression:OnAfterRecover(From, Event, To)
  local Tnow=timer.getTime()
  if Tnow-self.Tsuppressed > self.Tsuppress then
    self:CombatReady()
  end
end

--- After hit event.
-- @param #AI_Suppression self
function AI_Suppression:OnEnterCombatReady(From, Event, To)
  -- Group can fight again.
  self.Controllable:OptionROEOpenFire()
end

--- Entering suppressed state.
-- @param #AI_Suppression self
function AI_Suppression:OnEnterSuppressed(From, Event, To)

  local Tnow=timer.getTime()
  
  -- Group will hold their weapons.
  self.Controllable:OptionROEHoldFire()
  
  
  -- Recovery will be in Tsuppress seconds.
  self:__Recover(self.Tsuppress)
  

  if From=="CombatReady" then
  
    
  elseif From=="Suppressed" then
  
  else
  
  end
  
end



--- @param #AI_Suppression self
-- @param Core.Event#EVENTDATA EventData
function AI_Suppression:OnEventHit(EventData)
  self:E({"EventHit", EventData })
  env.info("Hitevent")

  if EventData.IniDCSUnit then
  
    --self:Hit()
    
  end  
end

--- @param #AI_Suppression self
-- @param Core.Event#EVENTDATA EventData
function AI_Suppression:OnEventDead(EventData)
  self:E({"EventHit", EventData })
  env.info("Deadevent")
  if EventData.IniDCSUnit then
    --blabla
  end  
end

