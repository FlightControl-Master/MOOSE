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
-- @field #number TsuppressionStart Time at which the suppression started.
-- @field #number TsuppressionOver Time at which the suppression will be over.
-- @field #number Thit Last time the unit was hit.
-- @field #number Nhit Number of times the unit was hit since it last was in state "CombatReady".
-- @field Core.Zone#ZONE Zone_Retreat Zone into which a group retreats.
-- @field #number LifeThreshold Life of group in percent at which the group will be ordered to retreat.
-- @field #number IniGroupStrength Number of units in a group at start.
-- @field #number GroupStrengthThreshold Threshold of group strength before retreat is ordered.
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
  TsuppressStart = nil,
  TsuppressOver = nil,
  Thit = nil,
  Nhit = 0,
  Zone_Retreat = nil,
  LifeThreshold = 25,
  IniGroupStrength = nil,
  GroupStrengthThreshold=80,
}

--- Some ID to identify who we are in output of the DCS.log file.
-- @field #string id
AI_Suppression.id="SFX | "

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--TODO: Figure out who was shooting and move away from him.
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
    env.info(AI_Suppression.id.."Suppression fire for group "..Group:GetName())
  else
    env.info(AI_Suppression.id.."Suppression fire: Requested group does not exist! (Has to be a MOOSE group.)")
    return nil
  end
  
  -- Check that we actually have a GROUND group.
  if Group:IsGround()==false then
    env.error(AI_Suppression.id.."Suppression fire group "..Group:GetName().." has to be a GROUND group!")
    return nil
  end

  -- Inherits from FSM_CONTROLLABLE
  local self=BASE:Inherit(self, FSM_CONTROLLABLE:New()) -- #AI_Suppression
  
  
  -- Set the controllable for the FSM.
  self:SetControllable(Group)
  
  -- Initial group strength.
  self.IniGroupStrength=#Group:GetUnits()
  
  
  -- Get life of group in %.
  local life_min, life_max, life_ave, groupstrength=self:_GetLife()
  
  -- Group is initially in state CombatReady.
  self:SetStartState("none")
  
  -- Transitions:
  ---------------
  
    -- Transition from anything to "Suppressed" after event "Hit". 
  self:AddTransition("*", "Start", "CombatReady")
  
  -- Transition from anything to "Suppressed" after event "Hit".
  self:AddTransition("*", "Hit", "*")
  
  -- Transition from "Suppressed" back to "CombatReady after the unit had time to recover.
  self:AddTransition("*", "Recovered", "*")
  
    -- Transition from "Suppressed" back to "CombatReady after the unit had time to recover.
  self:AddTransition("*", "Suppress", "Suppressed")
  
  -- Transition from "Suppressed" to "Hiding" after event "Hit".
  self:AddTransition("*", "TakeCover", "Hiding")
  
  -- Transition from anything to "Retreating" after e.g. being severely damaged.
  self:AddTransition("*", "Retreat", "Retreating")
  
  -- Transition from anything to "Dead" after group died.
  self:AddTransition("*", "Died", "Dead")
  
  -- Check status of the group.
  self:AddTransition("*", "Status", "*")
  
  --self:TakeCover()
  
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

--- After "Start" event.
-- @param #AI_Suppression self
function AI_Suppression:onafterStart(Controlable, From, Event, To)
  env.info(AI_Suppression.id..string.format("onafterStart: %s event %s from %s to %s", Controlable:GetName(), Event, From, To))
  
  -- Handle DCS event hit.
  self:HandleEvent(EVENTS.Hit, self._OnHit)
  
  -- Handle DCS event dead.
  self:HandleEvent(EVENTS.Dead, self._OnDead)
  
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

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Before "Hit" event. (Of course, this is not really before the group got hit.)
-- @param #AI_Suppression self
-- @param Wrapper.Controllable#CONTROLLABLE Controlable Controllable of the group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Point#COORDINATE Fallback Fallback coordinates (or nil if no attacker could be found).
function AI_Suppression:OnBeforeHit(Controlable, From, Event, To, Fallback)
  env.info(AI_Suppression.id..string.format("OnBeforeHit: %s event %s from %s to %s", Controlable:GetName(), Event, From, To))
  
  -- Increase Hit counter.
  self.Nhit=self.Nhit+1
  
  -- Info on hit times.
  env.info(AI_Suppression.id..string.format("Group has just been hit %d times.", self.Nhit))
  
end

--- After "Hit" event.
-- @param #AI_Suppression self
function AI_Suppression:OnAfterHit(Controlable, From, Event, To, Fallback)
  env.info(AI_Suppression.id..string.format("OnAfterHit: %s event %s from %s to %s", Controlable:GetName(), Event, From, To))
  
  -- Suppress fire of group.
  self:_Suppress()
  
  -- Get life of group in %.
  local life_min, life_max, life_ave, groupstrength=self:_GetLife()
  
  if self:is("CombatReady") then
    env.info(AI_Suppression.id..string.format("Group %s is currently CombatReady.", Controlable:GetName()))
    self:Suppress()
  elseif self:Is("Suppressed") then
    env.info(AI_Suppression.id..string.format("Group %s is currently Suppressed.", Controlable:GetName()))
  elseif self:Is("Retreating") then
    env.info(AI_Suppression.id..string.format("Group %s is currently Retreating.", Controlable:GetName()))
  elseif self:is("Hiding") then
    env.info(AI_Suppression.id..string.format("Group %s is currently Hiding.", Controlable:GetName()))
  end
  
  -- After three hits fall back a bit.
  local nfallback=3
  if self.Nhit==nfallback then
    env.info(AI_Suppression.id..string.format("Group %s is falling back after %d hits.", Controlable:GetName(), nfallback))
    Fallback:SmokeGreen()
    local FallbackMarkerID=Fallback:MarkToAll("Fall back position for group "..Controlable:GetName():GetName())
    self:_FallBack(Fallback)
  end
  
  -- If life of one unit is below threshold, the group is ordered to retreat (if a zone has been specified).
  if not self:Is("Retreating") then
    if groupstrength<self.GroupStrengthThreshold or (self.IniGroupStrength==1 and life_min < self.LifeThreshold) then
      self.Controllable:ClearTasks()
      self:Retreat()
    end
  end
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Before "Recovered" event.
-- @param #AI_Suppression self
function AI_Suppression:OnBeforeRecovered(Controlable, From, Event, To)
  env.info(AI_Suppression.id..string.format("OnBeforeRecovered: %s event %s from %s to %s", Controlable:GetName(), Event, From, To))
  
  -- Current time.
  local Tnow=timer.getTime()
  
  -- Debug info
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

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Before "Retreat" event.
-- @param #AI_Suppression self
function AI_Suppression:OnBeforeRetreat(Controlable, From, Event, To)
  env.info(AI_Suppression.id..string.format("OnBeforeRetreat: %s event %s from %s to %s", Controlable:GetName(), Event, From, To))
    
  -- Retreat is only possible if a zone has been defined by the user.
  if self.Zone_Retreat==nil then
    env.info(AI_Suppression.id.."Retreat NOT possible! No Zone specified.")
    return false
  elseif self:Is("Retreating") then
    env.info(AI_Suppression.id.."Group is already retreating.")
    return false
  else
    env.info(AI_Suppression.id.."Retreat possible, zone specified.")
    return true
  end
  
end

--- After "Retreat" event.
-- @param #AI_Suppression self
function AI_Suppression:OnAfterRetreat(Controlable, From, Event, To)
  env.info(AI_Suppression.id..string.format("OnAfterRetreat: %s event %s from %s to %s", Controlable:GetName(), Event, From, To))
    
  -- Set the ALARM STATE to GREEN. Then the unit will move even if it is under fire.
  Controlable:OptionAlarmStateGreen()
  
  -- Route the group to a zone.
  MESSAGE:New(string.format("Group %s is retreating!", Controlable:GetName()), 30):ToAll()
  self:_RetreatToZone(self.Zone_Retreat, 50, "Vee")
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Before "TakeCover" event.
-- @param #AI_Suppression self
function AI_Suppression:OnBeforeTakeCover(Controlable, From, Event, To)
  env.info(AI_Suppression.id..string.format("OnBeforeTakeCover: %s event %s from %s to %s", Controlable:GetName(), Event, From, To))
  
  -- We search objects in a zone with radius 100 m around the group.
  -- TODO: Maybe make the zone radius larger for vehicles.
  local Zone = ZONE_GROUP:New("Zone_Hiding", Controlable, 500)

  -- Scan for Scenery objects to run/drive to.
  Zone:Scan(Object.Category.SCENERY)

  local gothideout=false
  for SceneryTypeName, SceneryData in pairs( Zone:GetScannedScenery() ) do
    for SceneryName, SceneryObject in pairs( SceneryData ) do
      local SceneryObject = SceneryObject -- Wrapper.Scenery#SCENERY
      local text=self.Controllable:GetName().. " scenery: " .. SceneryObject:GetTypeName() .. ", Coord LL DMS: " .. SceneryObject:GetCoordinate():ToStringLLDMS()
      MESSAGE:New(text, 10):ToAll()
      env.info(AI_Suppression.id..text)
      -- TODO: Add check if scenery name matches a specific type like tree or building. This might be tricky though!
    end
  end  
  
  -- Only take cover if we found a hideout.
  return gothideout
  
end

--- After "TakeCover" event.
-- @param #AI_Suppression self
function AI_Suppression:OnAfterTakeCover(Controlable, From, Event, To)
  env.info(AI_Suppression.id..string.format("OnAfterTakeCover: %s event %s from %s to %s", Controlable:GetName(), Event, From, To))
  
  local text=string.format("Group %s is taking cover!", Controlable:GetName())
  MESSAGE:New(text, 30):ToAll()
  
  -- Set the ALARM STATE to GREEN. Then the unit will move even if it is under fire.
  Controlable:OptionAlarmStateGreen()
  
  -- Route the group to a zone.
  MESSAGE:New(string.format("Group %s would be(!) hiding now!", Controlable:GetName()), 30):ToAll()
  
  --TODO: Search place to hide. For each unit (disperse) or same for all?
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Entering "CombatReady" state. The group will be able to fight back.
-- @param #AI_Suppression self
function AI_Suppression:OnEnterCombatReady(Controlable, From, Event, To)
  env.info(AI_Suppression.id..string.format("OnEnterCombatReady: %s event %s from %s to %s", Controlable:GetName(), Event, From, To))
  -- Nothing to do yet. Just monitoring the event
end

--- Leaving "CombatReady" state.
-- @param #AI_Suppression self
function AI_Suppression:OnLeaveCombatReady(Controlable, From, Event, To)
  env.info(AI_Suppression.id..string.format("OnLeaveCombatReady: %s event %s from %s to %s", Controlable:GetName(), Event, From, To))
  -- Nothing to do yet. Just monitoring the event
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Entering "Suppressed" state. Group will not fight but hold their weapons.
-- @param #AI_Suppression self
function AI_Suppression:OnEnterSuppressed(Controlable, From, Event, To)
  env.info(AI_Suppression.id..string.format("OnEnterSuppression: %s event %s from %s to %s", Controlable:GetName(), Event, From, To)) 
  -- Nothing to do yet. Just monitoring the event
end

--- Leaving "Suppressed" state.
-- @param #AI_Suppression self
function AI_Suppression:OnLeaveSuppressed(Controlable, From, Event, To)
  env.info(AI_Suppression.id..string.format("OnLeaveSuppression: %s event %s from %s to %s", Controlable:GetName(), Event, From, To))

  -- Group can fight again.
  self.Controllable:OptionROEOpenFire()

  local text=string.format("Suppression of group %s ended at %f and should have ended at %f.", self.Controllable:GetName(), timer.getTime(), self.TsuppressionOver)
  env.info(AI_Suppression.id..text)
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Entering "Retreating" state. Group will be send to a zone.
-- @param #AI_Suppression self
-- @param Wrapper.Controllable#CONTROLLABLE Controlable Controllable of the AI group.
function AI_Suppression:OnEnterRetreating(Controlable, From, Event, To)
  env.info(AI_Suppression.id..string.format("OnEnterRetreating: %s event %s from %s to %s", Controlable:GetName(), Event, From, To))    
end

--- Leaving "Retreating" state.
-- @param #AI_Suppression self
-- @param Wrapper.Controllable#CONTROLLABLE Controlable Controllable of the AI group.
function AI_Suppression:OnLeaveRetreating(Controlable, From, Event, To)
  env.info(AI_Suppression.id..string.format("OnLeveRetreating: %s event %s from %s to %s", Controlable:GetName(), Event, From, To))

  -- Set the ALARM STATE back to AUTO.
  Controlable:OptionAlarmStateAuto()
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Entering "Hiding" state. Group will try to take cover at neargy scenery objects.
-- @param #AI_Suppression self
-- @param Wrapper.Controllable#CONTROLLABLE Controlable Controllable of the AI group.
function AI_Suppression:OnEnterHiding(Controlable, From, Event, To)
  env.info(AI_Suppression.id..string.format("OnEnterHiding: %s event %s from %s to %s", Controlable:GetName(), Event, From, To))    
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
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Handle the DCS event hit.
-- @param #AI_Suppression self
-- @param Core.Event#EVENTDATA EventData
function AI_Suppression:_OnHit(EventData)
  self:E( {AI_Suppression.id.."_OnHit", EventData })
  --env.info(AI_Suppression.id.."Initiator   : "..EventData.IniDCSGroupName)
  --env.info(AI_Suppression.id.."Target      : "..EventData.TgtDCSGroupName)
  --env.info(AI_Suppression.id.."Controllable: "..self.Controllable:GetName())
  
  if EventData.TgtDCSGroup then
  
    local TargetGroup=EventData.TgtGroup --Wrapper.Group#GROUP
    
    if EventData.TgtDCSGroupName==self.Controllable:GetName() then

      -- Figure out who shot.    
      local InitiatorName="unknown"
      local Fallback=nil
      if EventData.IniDCSUnit then
      
        local InitiatorUnit=EventData.IniUnit --Wrapper.Unit#UNIT
        InitiatorName=EventData.IniDCSGroupName
        
        local TC=TargetGroup:GetCoordinate()
        local IC=InitiatorUnit:GetCoordinate()
        
        -- Create a fall back point.
        Fallback=self:_FallBackCoord(TC, IC , 200) -- Core.Point#COORDINATE        
      end
      
      -- Get life of group in %.
      local life_min, life_max, life_ave, groupstrength=self:_GetLife()
      
      -- Debug message.
      local text=string.format("Group %s was hit by %s. Life min=%02d %%, max=%02d %%, average=%02d %%, group=%3.0f", EventData.TgtDCSGroupName, InitiatorName, life_min, life_max, life_ave, groupstrength)
      MESSAGE:New(text, 10):ToAll()
      env.info(AI_Suppression.id..text)
      
      -- Trigger Hit event.
      self:Hit(Fallback)
    end
  end
end

--- Handle the DCS event dead.
-- @param #AI_Suppression self
-- @param Core.Event#EVENTDATA EventData
function AI_Suppression:_OnDead(EventData)
  self:E({AI_Suppression.id.."_OnDead", EventData})
  
  if EventData.IniDCSUnit then
    if EventData.IniDCSGroupName==self.Controllable:GetName() then
    
      -- Number of units left in the group.
      local nunits=#self.Controllable:GetUnits()-1
      
      local text=string.format("A unit from group %s just died! %d units left.", self.Controllable:GetName(), nunits)
      MESSAGE:New(text, 10):ToAll()
      env.info(AI_Suppression.id..text)
      
      -- Go to stop state.
      if nunits==0 then
        self:Stop()
      end
      
    end
  end
    
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Suppress fire of a unit.
-- @param #AI_Suppression self
function AI_Suppression:_Suppress()

  -- Current time.
  local Tnow=timer.getTime()
  
  -- Controllable
  local Controlable=self.Controllable
  
  -- Group will hold their weapons.
  Controlable:OptionROEHoldFire()
  
  -- Get randomized time the unit is suppressed.
  local Tsuppress=math.random(self.Tsuppress_min, self.Tsuppress_max)
  
  -- Time the suppression started
  self.TsuppressionStart=Tnow
  
  -- Time at which the suppression is over.
  local renew=true
  if self.TsuppressionOver~=nil then
    if Tsuppress+Tnow>self.TsuppressionOver then
      self.TsuppressionOver=Tnow+Tsuppress
    else
      renew=false
    end
  else
    self.TsuppressionOver=Tnow+Tsuppress
  end
  
  -- Recovery event will be called in Tsuppress seconds. (We add one second to be sure the time has really passed when recovery is checked.)
  if renew then
    self:__Recovered(self.TsuppressionOver-Tnow)
  end
  
  -- Debug message.
  local text=string.format("Group %s is suppressed for %d seconds.", Controlable:GetName(), Tsuppress)
  MESSAGE:New(text, 30):ToAll()
  env.info(AI_Suppression.id..text)
  text=string.format("Suppression starts at %f and ends at %f.", Tnow, self.TsuppressionOver)
  env.info(AI_Suppression.id..text)

end


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
    local groupstrength=#units/self.IniGroupStrength*100
    for _,unit in pairs(units) do
      local unit=unit -- Wrapper.Unit#UNIT
      if unit and unit:IsActive() then
        n=n+1
        local life=unit:GetLife()/(unit:GetLife0()+1)*100
        if life < life_min then
          life_min=life
        end
        if life > life_max then
          life_max=life
        end
        life_ave=life_ave+life
        local text=string.format("n=%d: Life = %3.1f, Life0 = %3.1f, min=%3.1f, max=%3.1f, ave=%3.1f, group=%3.1f", n, unit:GetLife(), unit:GetLife0(), life_min, life_max, life_ave/n,groupstrength)
        env.info(AI_Suppression.id..text)      
      end
    end
    life_ave=life_ave/n
    
    return life_min, life_max, life_ave, groupstrength
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

  -- 
  env.info(AI_Suppression.id.."Retreat zone : "..zone:GetName())

  -- Get a random point in the retreat zone.
  local ZoneCoord=zone:GetRandomCoordinate() -- Core.Point#COORDINATE
  local ZoneVec2=ZoneCoord:GetVec2()

  -- Debug smoke zone and point.  
  ZoneCoord:SmokeBlue()
  zone:SmokeZone(SMOKECOLOR.Red, 12)
  
  -- Set task to go to zone.
  self.Controllable:TaskRouteToVec2(ZoneVec2, speed, formation)

end

--- Determine the coordinate to which a unit should fall back.
--@param #AI_Suppression self
--@param Core.Point#COORDINATE a Coordinate of the defending group.
--@param Core.Point#COORDINATE b Coordinate of the attacking group.
--@return Core.Point#COORDINATE Fallback coordinates. 
function AI_Suppression:_FallBackCoord(a, b, distance)
  local dx = b.x-a.x
  -- take the right value for y-coordinate (if we have "alt" then "y" if not "z")
  local ay
  if a.alt then
    ay=a.y
  else
    ay=a.z
  end
  local by
  if b.alt then
    by=b.y
  else
    by=b.z
  end
  local dy = by-ay
  local angle = math.deg(math.atan2(dy,dx))
  if angle < 0 then
    angle = 360 + angle
  end
  angle=angle-180
  local fbp=a:Translate(distance, angle)
  return fbp
end


--- Fall back (move away) from enemy who is shooting on the group.
--@param #AI_Suppression self
--@param Core.Point#COORDINATE coord_fbp Coordinate of the fall back point.
function AI_Suppression:_FallBack(coord_fbp)

  local group=self.Controllable -- Wrapper.Controllable#CONTROLLABLE

  local Waypoints = group:GetTemplateRoutePoints()
  
  local coord_grp = group:GetCoordinate()
  local wp1 = coord_grp:WaypointGround(99, "Vee")
  local wp2 = coord_fbp:WaypointGround(99, "Vee")
    
  table.insert(Waypoints, 1, wp1)
  table.insert(Waypoints, 2, wp2)
  
  -- Condition to wait.
  local ConditionWait=group:TaskCondition(nil, nil, nil, nil, 30, nil)
  
  -- Task to hold.
  local TaskHold = group:TaskHold()
  
  local TaskRoute1 = group:TaskFunction("AI_Suppression._Passing_Waypoint", self, 0)
  local TaskCombo2 = {}
  TaskCombo2[#TaskCombo2+1] = group:TaskFunction("AI_Suppression._Passing_Waypoint", self, 1)
  TaskCombo2[#TaskCombo2+1] = group:TaskControlled(TaskHold, ConditionWait)
  local TaskRoute2 = group:TaskCombo(TaskCombo2)
  
  group:SetTaskWaypoint(Waypoints[1], TaskRoute1)
  group:SetTaskWaypoint(Waypoints[2], TaskRoute2)
  
  group:Route(Waypoints)

end


--- Group has reached a waypoint.
--@param #AI_Suppression self
--@param #number i Waypoint number that has been reached.
function AI_Suppression._Passing_Waypoint(group, Fsm, i)
  env.info(AI_Suppression.id.."Passing waypoint")
  BASE:E(group)
  BASE:E(Fsm)
  BASE:E(i)
  
  MESSAGE:New(string.format("Group %s passing waypoint %d", group:GetName(), i),30):ToAll()
  if i==1 then
    MESSAGE:New(string.format("Group %s has reached fallback point.", group:GetName(), i),30):ToAll()
  end
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------