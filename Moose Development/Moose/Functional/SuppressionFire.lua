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
-- @module ai_suppression

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
-- @field #AI_Suppression
AI_Suppression={
  ClassName = "AI_Suppression",
  Tsuppress_min = 5,
  Tsuppress_max = 20,
  Tsuppress = nil,
  Thit = nil,
  Nhit = 0,
  Zone_Retreat = nil,
  LifeMin = 25,
}

--- Some ID to identify who we are in output of the DCS.log file.
-- @field #string id
AI_Suppression.id="SFX | "

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--TODO: Figure out who was shooting and move away from him <== Not possible!
--TODO: Move behind a scenery building if there is one nearby.
--TODO: Retreat to a given zone or point.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Creates a new AI_suppression object.
-- @param #AI_Suppression self
-- @param Wrapper.Group#GROUP Group The GROUP object for which suppression should be applied.
-- @return #AI_Suppression
function AI_Suppression:New(Group)

  -- Check that group is present.
  if Group then
    env.info("Suppression fire for group "..Group:GetName())
  else
    env.info("Suppression fire: Group does not exist!")
    return nil
  end
  
  -- Check that we actually have a GROUND group.
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
  
  -- Transition from "Suppressed" to "Hiding" after event "Hit".
  self:AddTransition("Suppressed", "TakeCover", "Hiding")
  
  -- Transition from anything to "Retreating" after e.g. being severely damaged.
  self:AddTransition("*", "Retreat", "Retreating")
  
  -- Transition from anything to "Dead" after group died.
  self:AddTransition("*", "Died", "Dead")
  
  -- Check status of the group.
  self:AddTransition("*", "Status", "*")
  
  
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
  self.Tsuppress_min=Tmin or 1
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

--- Before "Status" event.
-- @param #AI_Suppression self
function AI_Suppression:OnBeforeStatus(Controlable, From, Event, To)
  env.info(AI_Suppression.id..string.format("OnBeforeStatus: %s event %s from %s to %s", Controlable:GetName(), Event, From, To))
  local text=string.format("Group %s is in state %s.", Controlable:GetName(), self:GetState())
  MESSAGE:New(text, 10):ToAll()
end

--- After "Status" event.
-- @param #AI_Suppression self
function AI_Suppression:OnAfterStatus(Controlable, From, Event, To)
  env.info(AI_Suppression.id..string.format("OnAfterStatus: %s event %s from %s to %s", Controlable:GetName(), Event, From, To))
  -- Get new status in 30 sec.
  self:__Status(30)
end


--- Before "Hit" event. (Of course, this is not really before the group got hit.)
-- @param #AI_Suppression self
function AI_Suppression:OnBeforeHit(Controlable, From, Event, To)
  env.info(AI_Suppression.id..string.format("OnBeforeHit: %s event %s from %s to %s", Controlable:GetName(), Event, From, To))
  
  -- Increase Hit counter.
  self.Nhit=self.Nhit+1
  
  -- Info on hit times.
  env.info(AI_Suppression.id..string.format("Group has just been hit %d times.", self.Nhit))
end

--- After "Hit" event.
-- @param #AI_Suppression self
function AI_Suppression:OnAfterHit(Controlable, From, Event, To)
  env.info(AI_Suppression.id..string.format("OnAfterHit: %s event %s from %s to %s", Controlable:GetName(), Event, From, To))
    
  -- Nothing to do yet. Just monitoring the event.
end


--- Before "Recovered" event.
-- @param #AI_Suppression self
function AI_Suppression:OnBeforeRecovered(Controlable, From, Event, To)
  env.info(AI_Suppression.id..string.format("OnBeforeRecovered: %s event %s from %s to %s", Controlable:GetName(), Event, From, To))
  
  -- Current time.
  local Tnow=timer.getTime()
  
  -- Here I need to figure our how to correctly go back to "CombatReady".
  -- Problem is that another "Hit" event might occur while the group is recovering.
  -- If that happens the time to recover should be reset.
  -- Only after a unit has not been hit for X seconds.
  -- We can return false if the recovery should not be executed!
  
  env.info(AI_Suppression.id..string.format("OnBeforeRecovered: Time: %d  - Time over: %d", Tnow, self.TsuppressionOver))
  
  -- Recovery is only possible if enough time since the last hit has passed.
  if Tnow > self.TsuppressionOver then
    return true
  else
    return false
  end
  
end

--- After "Recovered" event.
-- @param #AI_Suppression self
function AI_Suppression:OnAfterRecovered(Controlable, From, Event, To)
  env.info(AI_Suppression.id..string.format("OnAfterRecovered: %s event %s from %s to %s", Controlable:GetName(), Event, From, To))
  
  -- Send message.
  MESSAGE:New(string.format("Group %s has recovered.", Controlable:GetName()), 30):ToAll()
  
  -- Nothing to do yet. Just monitoring the event.
end


--- Before "Retreat" event.
-- @param #AI_Suppression self
function AI_Suppression:OnBeforeRetreat(Controlable, From, Event, To)
  env.info(AI_Suppression.id..string.format("OnBeforeRetreat: %s event %s from %s to %s", Controlable:GetName(), Event, From, To))
    
  -- Retreat is only possible if a zone has been defined by the user.
  if self.Zone_Retreat==nil then
    env.info("SFX: Retreat NOT possible! No Zone specified.")
    return false
  else
    env.info("SFX: Retreat possible, zone specified.")
    return true
  end
  
end

--- After "Retreat" event.
-- @param #AI_Suppression self
function AI_Suppression:OnAfterRetreat(Controlable, From, Event, To)
  env.info(AI_Suppression.id..string.format("OnAfterRetreat: %s event %s from %s to %s", Controlable:GetName(), Event, From, To))
  
  -- Message.
  local text=string.format("Group %s is retreating to zone %s.", Controlable:GetName(), self.Zone_Retreat:GetName())
  MESSAGE:New(text, 30):ToAll()
end

--- Before "TakeCover" event.
-- @param #AI_Suppression self
function AI_Suppression:OnBeforeTakeCover(Controlable, From, Event, To)
  env.info(AI_Suppression.id..string.format("OnBeforeTakeCover: %s event %s from %s to %s", Controlable:GetName(), Event, From, To))
  
  -- We search objects in a zone with radius 100 m around the group.
  -- TODO: Maybe make the zone radius larger for vehicles.
  local Zone = ZONE_GROUP:New("Zone_Hiding", Controlable, 100)

  -- Scan for Scenery objects to run/drive to.
  Zone:Scan( Object.Category.SCENERY )

  local gothideout=false
  for SceneryTypeName, SceneryData in pairs( Zone:GetScannedScenery() ) do
    for SceneryName, SceneryObject in pairs( SceneryData ) do
      local SceneryObject = SceneryObject -- Wrapper.Scenery#SCENERY
      MESSAGE:NewType( "Scenery: " .. SceneryObject:GetTypeName() .. ", Coord LL DMS: " .. SceneryObject:GetCoordinate():ToStringLLDMS(), MESSAGE.Type.Information ):ToAll()
      -- TODO: Add check if scenery name matches a specific type like tree or building. This might be tricky though!
    end
  end  
  
  -- Only take cover if we found a hideout.
  return gothideout
  
end

--- After "TakeCover" event.
-- @param #AI_Suppression self
function AI_Suppression:OnBeforeTakeCover(Controlable, From, Event, To)
  env.info(AI_Suppression.id..string.format("OnAfterTakeCover: %s event %s from %s to %s", Controlable:GetName(), Event, From, To))
  local text=string.format("Group %s is taking cover!", Controlable:GetName())
  MESSAGE:New(text, 30):ToAll()
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Entering "CombatReady" state. The group will be able to fight back.
-- @param #AI_Suppression self
function AI_Suppression:OnEnterCombatReady(Controlable, From, Event, To)
  env.info(AI_Suppression.id..string.format("OnEnterCombatReady: %s event %s from %s to %s", Controlable:GetName(), Event, From, To))

  -- Group can fight again.
  self.Controllable:OptionROEOpenFire()
  
end

--- Leaving "CombatReady" state.
-- @param #AI_Suppression self
function AI_Suppression:OnLeaveCombatReady(Controlable, From, Event, To)
  env.info(AI_Suppression.id..string.format("OnLeaveCombatReady: %s event %s from %s to %s", Controlable:GetName(), Event, From, To))

  -- Nothing to do yet. Just monitoring the event
end


--- Entering "Suppressed" state. Group will not fight but hold their weapons.
-- @param #AI_Suppression self
function AI_Suppression:OnEnterSuppressed(Controlable, From, Event, To)
  env.info(AI_Suppression.id..string.format("OnEnterSuppression: %s event %s from %s to %s", Controlable:GetName(), Event, From, To))

  -- Current time.
  local Tnow=timer.getTime()
  
  -- Group will hold their weapons.
  Controlable:OptionROEHoldFire()
  
  -- Get randomized time the unit is suppressed.
  self.Tsuppress=math.random(self.Tsuppress_min, self.Tsuppress_max)
  
  -- Time at which the suppression is over.
  self.TsuppressionOver=Tnow+self.Tsuppress
  
  -- Recovery event will be called in Tsuppress seconds. (We add one second to be sure the time has really passed when recovery is checked.)
  self:__Recovered(self.Tsuppress+1)
  
  -- Get life of group in %.
  local life_min, life_max, life_ave=self:_GetLife()
  
  -- If life of one unit is below threshold, the group is ordered to retreat (if a zone has been specified).
  if life_min < self.LifeMin then
    self:Retreat()
  end
    
end


--- Entering "Retreating" state. Group will be send to a zone.
-- @param #AI_Suppression self
-- @param Wrapper.Controllable#CONTROLLABLE Controlable Controllable of the AI group.
function AI_Suppression:OnEnterRetreating(Controlable, From, Event, To)
  env.info(AI_Suppression.id..string.format("OnEnterRetreating: %s event %s from %s to %s", Controlable:GetName(), Event, From, To))

  -- Set the ALARM STATE to GREEN. Then the unit will move even if it is under fire.
  Controlable:OptionAlarmStateGreen()
  
  -- Route the group to a zone.
  MESSAGE:New(string.format("Group %s is retreating!", Controlable:GetName()), 30):ToAll()
  self:_RetreatToZone(self.Zone_Retreat, 50, "Vee")
    
end

--- Leaving "Retreating" state.
-- @param #AI_Suppression self
-- @param Wrapper.Controllable#CONTROLLABLE Controlable Controllable of the AI group.
function AI_Suppression:OnLeaveRetreating(Controlable, From, Event, To)
  env.info(AI_Suppression.id..string.format("OnLeveRetreating: %s event %s from %s to %s", Controlable:GetName(), Event, From, To))

  -- Set the ALARM STATE back to AUTO.
  Controlable:OptionAlarmStateAuto()
end


--- Entering "Hiding" state. Group will try to take cover at neargy scenery objects.
-- @param #AI_Suppression self
-- @param Wrapper.Controllable#CONTROLLABLE Controlable Controllable of the AI group.
function AI_Suppression:OnEnterHiding(Controlable, From, Event, To)
  env.info(AI_Suppression.id..string.format("OnEnterHiding: %s event %s from %s to %s", Controlable:GetName(), Event, From, To))

  -- Set the ALARM STATE to GREEN. Then the unit will move even if it is under fire.
  Controlable:OptionAlarmStateGreen()
  
  -- Route the group to a zone.
  MESSAGE:New(string.format("Group %s would be(!) hiding now!", Controlable:GetName()), 30):ToAll()
  
  --TODO: Search place to hide. For each unit (disperse) or same for all?
    
end

--- Leaving "Hiding" state.
-- @param #AI_Suppression self
-- @param Wrapper.Controllable#CONTROLLABLE Controlable Controllable of the AI group.
function AI_Suppression:OnLeaveHiding(Controlable, From, Event, To)
  env.info(AI_Suppression.id..string.format("OnLeveHiding: %s event %s from %s to %s", Controlable:GetName(), Event, From, To))

  -- Set the ALARM STATE back to AUTO.
  Controlable:OptionAlarmStateAuto()
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

--- Get (relative) life in percent of a group. Function returns the value of the units with the smallest and largest life. Also the average value of all groups is returned.
-- @param #AI_Suppression self
-- @param Wrapper.Group#GROUP group Group of unit.
-- @return #number Smallest life value of all units.
-- @return #number Largest life value of all units.
-- @return #number Average life value.
function AI_Suppression:_GetLife()
  local group=self.Controllable
  if group and group:IsAlive() then
    local life_min=100
    local life_max=0
    local life_ave=0
    local n=0
    local units=group:GetUnits()
    for _,unit in pairs(units) do
      if unit then
        n=n+1
        local life=unit:GetLife()/unit:GetLife0()*100
        if life < life_min then
          life_min=life
        end
        if life > life_max then
          life_max=life
        end
        life_ave=life_ave+life
      end
    end
    life_ave=life_ave/n
    return life_min, life_max, life_ave
  else
    return 0, 0, 0
  end
end


--- Retreat to a random point within a zone.
-- @param #AI_Suppression self
-- @param Core.Zone#ZONE zone Zone to which the group retreats.
-- @param #number speed Speed of the group. Default max speed the specific group can do.
-- @param #string formation Formation of the Group. Default "Vee".
function AI_Suppression:_RetreatToZone(zone, speed, formation)

  -- Set zone, speed and formation if they are not given
  zone=zone or self.Zone_Retreat
  speed = speed or 999
  formation = formation or "Vee"

  -- Get a random point in the retreat zone.
  local ZonePoint=zone:GetRandomPointVec2()
  
  -- Set task to go to zone.
  self.Controllable:TaskRouteToVec2(ZonePoint, speed, formation)

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------