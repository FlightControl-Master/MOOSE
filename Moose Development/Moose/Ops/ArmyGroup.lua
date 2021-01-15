--- **Ops** - Enhanced Ground Group.
-- 
-- ## Main Features:
--
--    * Patrol waypoints *ad infinitum*
--    * Easy change of ROE and alarm state, formation and other settings
--    * Dynamically add and remove waypoints
--    * Sophisticated task queueing system  (know when DCS tasks start and end)
--    * Convenient checks when the group enters or leaves a zone
--    * Detection events for new, known and lost units
--    * Simple LASER and IR-pointer setup
--    * Compatible with AUFTRAG class
--    * Many additional events that the mission designer can hook into
--
-- ===
--
-- ## Example Missions:
-- 
-- Demo missions can be found on [github](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/develop/OPS%20-%20Armygroup).
--    
-- ===
--
-- ### Author: **funkyfranky**
-- 
-- ==
-- 
-- @module Ops.ArmyGroup
-- @image OPS_ArmyGroup.png


--- ARMYGROUP class.
-- @type ARMYGROUP
-- @field #boolean adinfinitum Resume route at first waypoint when final waypoint is reached.
-- @field #boolean formationPerma Formation that is used permanently and overrules waypoint formations.
-- @field #boolean isMobile If true, group is mobile.
-- @field #ARMYGROUP.Target engage Engage target.
-- @field #boolean retreatOnOutOfAmmo If true, the group will automatically retreat when out of ammo. Needs a retreat zone!
-- @field Core.Set#SET_ZONE retreatZones Set of retreat zones.
-- @extends Ops.OpsGroup#OPSGROUP

--- *Your soul may belong to Jesus, but your ass belongs to the marines.* -- Eugene B. Sledge
--
-- ===
--
-- ![Banner Image](..\Presentations\OPS\ArmyGroup\_Main.png)
--
-- # The ARMYGROUP Concept
-- 
-- This class enhances naval groups.
-- 
-- @field #ARMYGROUP
ARMYGROUP = {
  ClassName       = "ARMYGROUP",
  formationPerma  = nil,
  engage          = {},
}

--- Army group element.
-- @type ARMYGROUP.Element
-- @field #string name Name of the element, i.e. the unit.
-- @field Wrapper.Unit#UNIT unit The UNIT object.
-- @field #string status The element status.
-- @field #string typename Type name.
-- @field #number length Length of element in meters.
-- @field #number width Width of element in meters.
-- @field #number height Height of element in meters.

--- Target
-- @type ARMYGROUP.Target
-- @field Ops.Target#TARGET Target The target.
-- @field Core.Point#COORDINATE Coordinate Last known coordinate of the target.

--- Army Group version.
-- @field #string version
ARMYGROUP.version="0.4.0"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Retreat.
-- TODO: Suppression of fire. 
-- TODO: Check if group is mobile.
-- TODO: F10 menu.
-- DONE: Rearm. Specify a point where to go and wait until ammo is full.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new ARMYGROUP class object.
-- @param #ARMYGROUP self
-- @param Wrapper.Group#GROUP Group The group object. Can also be given by its group name as `#string`.
-- @return #ARMYGROUP self
function ARMYGROUP:New(Group)

  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, OPSGROUP:New(Group)) -- #ARMYGROUP
  
  -- Set some string id for output to DCS.log file.
  self.lid=string.format("ARMYGROUP %s | ", self.groupname)
  
  -- Defaults
  self.isArmygroup=true
  self:SetDefaultROE()
  self:SetDefaultAlarmstate()
  self:SetDetection()
  self:SetPatrolAdInfinitum(false)
  self:SetRetreatZones()

  -- Add FSM transitions.
  --                 From State  -->   Event      -->     To State
  self:AddTransition("*",             "FullStop",         "Holding")     -- Hold position.
  self:AddTransition("*",             "Cruise",           "Cruising")    -- Cruise along the given route of waypoints.
    
  self:AddTransition("*",             "Detour",           "OnDetour")    -- Make a detour to a coordinate and resume route afterwards.
  self:AddTransition("OnDetour",      "DetourReached",    "Cruising")    -- Group reached the detour coordinate.
  
  self:AddTransition("*",             "Retreat",          "Retreating")  --
  self:AddTransition("Retreating",    "Retreated",        "Retreated")   --
  
  self:AddTransition("Cruising",      "EngageTarget",     "Engaging")    -- Engage a target
  self:AddTransition("Holding",       "EngageTarget",     "Engaging")    -- Engage a target
  self:AddTransition("OnDetour",      "EngageTarget",     "Engaging")    -- Engage a target
  self:AddTransition("Engaging",      "Disengage",        "Cruising")    -- Engage a target

  self:AddTransition("*",             "Rearm",            "Rearm")       -- Group is send to a coordinate and waits until ammo is refilled.
  self:AddTransition("Rearm",         "Rearming",         "Rearming")    -- Group has arrived at the rearming coodinate and is waiting to be fully rearmed.
  self:AddTransition("Rearming",      "Rearmed",          "Cruising")    -- Group was rearmed.
  
  ------------------------
  --- Pseudo Functions ---
  ------------------------

  --- Triggers the FSM event "Stop". Stops the ARMYGROUP and all its event handlers.
  -- @param #ARMYGROUP self

  --- Triggers the FSM event "Stop" after a delay. Stops the ARMYGROUP and all its event handlers.
  -- @function [parent=#ARMYGROUP] __Stop
  -- @param #ARMYGROUP self
  -- @param #number delay Delay in seconds.
  
  -- TODO: Add pseudo functions.


  -- Init waypoints.
  self:InitWaypoints()
  
  -- Initialize the group.
  self:_InitGroup()
  
  -- Handle events:
  self:HandleEvent(EVENTS.Birth,      self.OnEventBirth)
  self:HandleEvent(EVENTS.Dead,       self.OnEventDead)
  self:HandleEvent(EVENTS.RemoveUnit, self.OnEventRemoveUnit)
  
  --self:HandleEvent(EVENTS.Hit,        self.OnEventHit)
  
  -- Start the status monitoring.
  self:__Status(-1)
  
  -- Start queue update timer.
  self.timerQueueUpdate=TIMER:New(self._QueueUpdate, self):Start(2, 5)  
  
  -- Start check zone timer.
  self.timerCheckZone=TIMER:New(self._CheckInZones, self):Start(2, 30)
   
  return self  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Group patrols ad inifintum. If the last waypoint is reached, it will go to waypoint one and repeat its route.
-- @param #ARMYGROUP self
-- @param #boolean switch If true or nil, patrol until the end of time. If false, go along the waypoints once and stop.
-- @return #ARMYGROUP self
function ARMYGROUP:SetPatrolAdInfinitum(switch)
  if switch==false then
    self.adinfinitum=false
  else
    self.adinfinitum=true
  end
  return self
end

--- Get coordinate of the closest road.
-- @param #ARMYGROUP self
-- @return Core.Point#COORDINATE Coordinate of a road closest to the group.
function ARMYGROUP:GetClosestRoad()
  return self:GetCoordinate():GetClosestPointToRoad()
end

--- Get 2D distance to the closest road.
-- @param #ARMYGROUP self
-- @return #number Distance in meters to the closest road.
function ARMYGROUP:GetClosestRoadDist()
  local road=self:GetClosestRoad()
  if road then
    local dist=road:Get2DDistance(self:GetCoordinate())
    return dist
  end
  return math.huge
end


--- Add a *scheduled* task to fire at a given coordinate.
-- @param #ARMYGROUP self
-- @param Core.Point#COORDINATE Coordinate Coordinate of the target.
-- @param #string Clock Time when to start the attack.
-- @param #number Radius Radius in meters. Default 100 m.
-- @param #number Nshots Number of shots to fire. Default 3.
-- @param #number WeaponType Type of weapon. Default auto.
-- @param #number Prio Priority of the task.
-- @return Ops.OpsGroup#OPSGROUP.Task The task table.
function ARMYGROUP:AddTaskFireAtPoint(Coordinate, Clock, Radius, Nshots, WeaponType, Prio)

  Coordinate=self:_CoordinateFromObject(Coordinate)

  local DCStask=CONTROLLABLE.TaskFireAtPoint(nil, Coordinate:GetVec2(), Radius, Nshots, WeaponType)

  local task=self:AddTask(DCStask, Clock, nil, Prio)

  return task
end

--- Add a *waypoint* task to fire at a given coordinate.
-- @param #ARMYGROUP self
-- @param Core.Point#COORDINATE Coordinate Coordinate of the target.
-- @param Ops.OpsGroup#OPSGROUP.Waypoint Waypoint Where the task is executed. Default is next waypoint.
-- @param #number Radius Radius in meters. Default 100 m.
-- @param #number Nshots Number of shots to fire. Default 3.
-- @param #number WeaponType Type of weapon. Default auto.
-- @param #number Prio Priority of the task.
-- @return Ops.OpsGroup#OPSGROUP.Task The task table.
function ARMYGROUP:AddTaskWaypointFireAtPoint(Coordinate, Waypoint, Radius, Nshots, WeaponType, Prio)

  Coordinate=self:_CoordinateFromObject(Coordinate)

  Waypoint=Waypoint or self:GetWaypointNext()

  local DCStask=CONTROLLABLE.TaskFireAtPoint(nil, Coordinate:GetVec2(), Radius, Nshots, WeaponType)

  local task=self:AddTaskWaypoint(DCStask, Waypoint, nil, Prio)

  return task
end

--- Add a *scheduled* task.
-- @param #ARMYGROUP self
-- @param Wrapper.Group#GROUP TargetGroup Target group.
-- @param #number WeaponExpend How much weapons does are used.
-- @param #number WeaponType Type of weapon. Default auto.
-- @param #string Clock Time when to start the attack.
-- @param #number Prio Priority of the task.
-- @return Ops.OpsGroup#OPSGROUP.Task The task table.
function ARMYGROUP:AddTaskAttackGroup(TargetGroup, WeaponExpend, WeaponType, Clock, Prio)

  local DCStask=CONTROLLABLE.TaskAttackGroup(nil, TargetGroup, WeaponType, WeaponExpend, AttackQty, Direction, Altitude, AttackQtyLimit, GroupAttack)

  local task=self:AddTask(DCStask, Clock, nil, Prio)

  return task
end

--- Define a set of possible retreat zones.
-- @param #ARMYGROUP self
-- @param Core.Set#SET_ZONE RetreatZoneSet The retreat zone set. Default is an empty set.
-- @return #ARMYGROUP self
function ARMYGROUP:SetRetreatZones(RetreatZoneSet)
  self.retreatZones=RetreatZoneSet or SET_ZONE:New()
  return self
end

--- Add a zone to the retreat zone set.
-- @param #ARMYGROUP self
-- @param Core.Zone#ZONE_BASE RetreatZone The retreat zone.
-- @return #ARMYGROUP self
function ARMYGROUP:AddRetreatZone(RetreatZone)
  self.retreatZones:AddZone(RetreatZone)
  return self
end

--- Check if the group is currently holding its positon.
-- @param #ARMYGROUP self
-- @return #boolean If true, group was ordered to hold.
function ARMYGROUP:IsHolding()
  return self:Is("Holding")
end

--- Check if the group is currently cruising.
-- @param #ARMYGROUP self
-- @return #boolean If true, group cruising.
function ARMYGROUP:IsCruising()
  return self:Is("Cruising")
end

--- Check if the group is currently on a detour.
-- @param #ARMYGROUP self
-- @return #boolean If true, group is on a detour.
function ARMYGROUP:IsOnDetour()
  return self:Is("OnDetour")
end

--- Check if the group is ready for combat. I.e. not reaming, retreating, retreated, out of ammo or engaging.
-- @param #ARMYGROUP self
-- @return #boolean If true, group is on a combat ready.
function ARMYGROUP:IsCombatReady()
  local combatready=true
  
  if self:IsRearming() or self:IsRetreating() or self.outofAmmo or self:IsEngaging() or self:is("Retreated") or self:IsDead() or self:IsStopped() or self:IsInUtero() then
    combatready=false
  end
  
  return combatready
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Status
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

---- Update status.
-- @param #ARMYGROUP self
function ARMYGROUP:onbeforeStatus(From, Event, To)

  if self:IsDead() then  
    self:T(self.lid..string.format("Onbefore Status DEAD ==> false"))
    return false   
  elseif self:IsStopped() then
    self:T(self.lid..string.format("Onbefore Status STOPPED ==> false"))
    return false
  end

  return true
end

--- Update status.
-- @param #ARMYGROUP self
function ARMYGROUP:onafterStatus(From, Event, To)

  -- FSM state.
  local fsmstate=self:GetState()
  
  if self:IsAlive() then

    ---
    -- Detection
    ---
    
    -- Check if group has detected any units.
    if self.detectionOn then
      self:_CheckDetectedUnits()
    end
    
    -- Check ammo status.
    self:_CheckAmmoStatus()

    -- Update position etc.    
    self:_UpdatePosition()
      
    -- Check if group got stuck.
    self:_CheckStuck()
    
    -- Check damage of elements and group.
    self:_CheckDamage()
    
    -- Update engagement.
    if self:IsEngaging() then
      self:_UpdateEngageTarget()
    end
    
    if self.verbose>=1 then
  
      -- Get number of tasks and missions.
      local nTaskTot, nTaskSched, nTaskWP=self:CountRemainingTasks()
      local nMissions=self:CountRemainingMissison()
      
      local roe=self:GetROE()
      local alarm=self:GetAlarmstate()
      local speed=UTILS.MpsToKnots(self.velocity)
      local speedEx=UTILS.MpsToKnots(self:GetExpectedSpeed())
      local formation=self.option.Formation or "unknown"      
      local ammo=self:GetAmmoTot()
    
      -- Info text.
      local text=string.format("%s [ROE-AS=%d-%d T/M=%d/%d]: Wp=%d/%d-->%d (final %s), Life=%.1f, Speed=%.1f (%d), Heading=%03d, Ammo=%d", 
      fsmstate, roe, alarm, nTaskTot, nMissions, self.currentwp, #self.waypoints, self:GetWaypointIndexNext(), tostring(self.passedfinalwp), self.life or 0, speed, speedEx, self.heading, ammo.Total)
      self:I(self.lid..text)
      
    end
    
  else

    -- Info text.
    local text=string.format("State %s: Alive=%s", fsmstate, tostring(self:IsAlive()))
    self:T2(self.lid..text)
  
  end


  ---
  -- Tasks & Missions
  ---

  self:_PrintTaskAndMissionStatus()


  -- Next status update.
  self:__Status(-30)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Events
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after "ElementSpawned" event.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #ARMYGROUP.Element Element The group element.
function ARMYGROUP:onafterElementSpawned(From, Event, To, Element)
  self:T(self.lid..string.format("Element spawned %s", Element.name))

  -- Set element status.
  self:_UpdateStatus(Element, OPSGROUP.ElementStatus.SPAWNED)

end

--- On after "Spawned" event.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function ARMYGROUP:onafterSpawned(From, Event, To)
  self:T(self.lid..string.format("Group spawned!"))

  -- Update position.
  self:_UpdatePosition()

  if self.isAI then
  
    -- Set default ROE.
    self:SwitchROE(self.option.ROE)
    
    -- Set default Alarm State.
    self:SwitchAlarmstate(self.option.Alarm)
    
    -- Set TACAN to default.
    self:_SwitchTACAN()
    
    -- Turn on the radio.
    if self.radioDefault then
      self:SwitchRadio(self.radioDefault.Freq, self.radioDefault.Modu)
    else
      self:SetDefaultRadio(self.radio.Freq, self.radio.Modu, true)
    end
    
    -- Formation
    if not self.option.Formation then
      self.option.Formation=self.optionDefault.Formation
    end
    
  end
  
  -- Update route.
  if #self.waypoints>1 then
    self:Cruise(nil, self.option.Formation or self.optionDefault.Formation)
  else
    self:FullStop()
  end
  
end

--- On after "UpdateRoute" event.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number n Waypoint number. Default is next waypoint.
-- @param #number Speed Speed in knots. Default cruise speed.
-- @param #number Formation Formation of the group.
function ARMYGROUP:onafterUpdateRoute(From, Event, To, n, Speed, Formation)

  -- Debug info.
  local text=string.format("Update route n=%s, Speed=%s, Formation=%s", tostring(n), tostring(Speed), tostring(Formation))
  self:T(self.lid..text)

  -- Update route from this waypoint number onwards.
  n=n or self:GetWaypointIndexNext(self.adinfinitum)
  
  -- Update waypoint tasks, i.e. inject WP tasks into waypoint table.
  self:_UpdateWaypointTasks(n)

  -- Waypoints.
  local waypoints={}
  
  -- Next waypoint.
  local wp=UTILS.DeepCopy(self.waypoints[n]) --Ops.OpsGroup#OPSGROUP.Waypoint
  
  -- Do we want to drive on road to the next wp?
  local onroad=wp.action==ENUMS.Formation.Vehicle.OnRoad
        
  -- Speed.
  if Speed then
    wp.speed=UTILS.KnotsToMps(Speed)
  else
    -- Take default waypoint speed. But make sure speed>0 if patrol ad infinitum.
    if self.adinfinitum and wp.speed<0.1 then
      wp.speed=UTILS.KmphToMps(self.speedCruise)
    end
  end
  
  -- Formation.
  if self.formationPerma then
    wp.action=self.formationPerma
  elseif Formation then 
    wp.action=Formation
  end
  
  -- Current set formation.
  self.option.Formation=wp.action
  
  -- Current set speed in m/s.
  self.speedWp=wp.speed

  -- Add waypoint in between because this waypoint is "On Road" but lies "Off Road".
  if onroad then
  
    -- The real waypoint is actually off road.
    wp.action=ENUMS.Formation.Vehicle.OffRoad

    -- Add "On Road" waypoint in between.
    local wproad=wp.roadcoord:WaypointGround(wp.speed, ENUMS.Formation.Vehicle.OnRoad) --Ops.OpsGroup#OPSGROUP.Waypoint
    
    -- Insert road waypoint.
    table.insert(waypoints, wproad)
  end    
        
  -- Add waypoint.
  table.insert(waypoints, wp)
  
  -- Apply formation at the current position or it will only be changed when reaching the next waypoint.
  local formation=ENUMS.Formation.Vehicle.OffRoad
  if wp.action~=ENUMS.Formation.Vehicle.OnRoad then
    formation=wp.action
  end

  -- Current point.
  local current=self:GetCoordinate():WaypointGround(UTILS.MpsToKmph(self.speedWp), formation)
  table.insert(waypoints, 1, current)

  -- Insert a point on road.
  if onroad then
    local current=self:GetClosestRoad():WaypointGround(UTILS.MpsToKmph(self.speedWp), ENUMS.Formation.Vehicle.OnRoad)
    table.insert(waypoints, 2, current)
  end
  
  -- Debug output.
  if false then
    for i,_wp in pairs(waypoints) do
      local wp=_wp
      local text=string.format("WP #%d UID=%d type=%s: Speed=%d m/s, alt=%d m, Action=%s", i, wp.uid and wp.uid or 0, wp.type, wp.speed, wp.alt, wp.action)
      self:T(text)
    end
  end

  if self:IsEngaging() or not self.passedfinalwp then
  
    -- Debug info.
    self:T(self.lid..string.format("Updateing route: WP %d-->%d (%d/%d), Speed=%.1f knots, Formation=%s", 
    self.currentwp, n, #waypoints, #self.waypoints, UTILS.MpsToKnots(self.speedWp), tostring(self.option.Formation)))
  
    -- Route group to all defined waypoints remaining.
    self:Route(waypoints)
    
  else

    ---
    -- Passed final WP ==> Full Stop
    ---
  
    self:E(self.lid..string.format("WARNING: Passed final WP ==> Full Stop!"))
    self:FullStop()  
  
  end

end

--- On after "GotoWaypoint" event. Group will got to the given waypoint and execute its route from there.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number UID The goto waypoint unique ID.
-- @param #number Speed (Optional) Speed to waypoint in knots.
-- @param #number Formation (Optional) Formation to waypoint.
function ARMYGROUP:onafterGotoWaypoint(From, Event, To, UID, Speed, Formation)

  local n=self:GetWaypointIndex(UID)
  
  --env.info(string.format("FF AG Goto waypoint UID=%s Index=%s, Speed=%s, Formation=%s", tostring(UID), tostring(n), tostring(Speed), tostring(Formation)))
  
  if n then
  
    -- TODO: switch to re-enable waypoint tasks.
    if false then
      local tasks=self:GetTasksWaypoint(n)
      
      for _,_task in pairs(tasks) do
        local task=_task --Ops.OpsGroup#OPSGROUP.Task
        task.status=OPSGROUP.TaskStatus.SCHEDULED
      end
      
    end
    
    -- Speed to waypoint.
    Speed=Speed or self:GetSpeedToWaypoint(n)
        
    -- Update the route.
    self:UpdateRoute(n, Speed, Formation)
    
  end
  
end

--- On after "Detour" event.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Point#COORDINATE Coordinate Coordinate where to go.
-- @param #number Speed Speed in knots. Default cruise speed.
-- @param #number Formation Formation of the group.
-- @param #number ResumeRoute If true, resume route after detour point was reached. If false, the group will stop at the detour point and wait for futher commands.
function ARMYGROUP:onafterDetour(From, Event, To, Coordinate, Speed, Formation, ResumeRoute)

  for _,_wp in pairs(self.waypoints) do
    local wp=_wp --Ops.OpsGroup#OPSGROUP.Waypoint
    if wp.detour then
      self:RemoveWaypointByID(wp.uid)
    end
  end 

  -- Speed in knots.
  Speed=Speed or self:GetSpeedCruise()
  
  -- ID of current waypoint.
  local uid=self:GetWaypointCurrent().uid
  
  -- Add waypoint after current.
  local wp=self:AddWaypoint(Coordinate, Speed, uid, Formation, true)
  
  -- Set if we want to resume route after reaching the detour waypoint.
  if ResumeRoute then
    wp.detour=1
  else
    wp.detour=0
  end

end

--- On after "Rearm" event.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Point#COORDINATE Coordinate Coordinate where to rearm.
-- @param #number Formation Formation of the group.
function ARMYGROUP:onafterRearm(From, Event, To, Coordinate, Formation)

  -- ID of current waypoint.
  local uid=self:GetWaypointCurrent().uid
  
  -- Add waypoint after current.
  local wp=self:AddWaypoint(Coordinate, nil, uid, Formation, true)
  
  -- Set if we want to resume route after reaching the detour waypoint.
  wp.detour=0

end

--- On after "Rearming" event.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function ARMYGROUP:onafterRearming(From, Event, To)

  -- Get current position.
  local pos=self:GetCoordinate()
  
  -- Create a new waypoint.
  local wp=pos:WaypointGround(0)
  
  -- Create new route consisting of only this position ==> Stop!
  self:Route({wp})
  
end

--- On before "Retreat" event.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Zone#ZONE_BASE Zone (Optional) Zone where to retreat. Default is the closest retreat zone.
-- @param #number Formation (Optional) Formation of the group.
function ARMYGROUP:onbeforeRetreat(From, Event, To, Zone, Formation)

  if not Zone then
  
    local a=self:GetVec2()
  
    local distmin=math.huge
    local zonemin=nil  
    for _,_zone in pairs(self.retreatZones:GetSet()) do
      local zone=_zone --Core.Zone#ZONE_BASE
      
      local b=zone:GetVec2()
      
      local dist=UTILS.VecDist2D(a, b)
      
      if dist<distmin then
        distmin=dist
        zonemin=zone
      end
    
    end
  
    if zonemin then
      self:__Retreat(0.1, zonemin, Formation)
    end
    
    return false
  end

  return true
end

--- On after "Retreat" event.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Zone#ZONE_BASE Zone (Optional) Zone where to retreat. Default is the closest retreat zone.
-- @param #number Formation (Optional) Formation of the group.
function ARMYGROUP:onafterRetreat(From, Event, To, Zone, Formation)

  -- ID of current waypoint.
  local uid=self:GetWaypointCurrent().uid
  
  local Coordinate=Zone:GetRandomCoordinate()
  
  -- Add waypoint after current.
  local wp=self:AddWaypoint(Coordinate, nil, uid, Formation, true)
  
  -- Set if we want to resume route after reaching the detour waypoint.
  wp.detour=0

end

--- On after "Retreated" event.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function ARMYGROUP:onafterRetreated(From, Event, To)

  -- Get current position.
  local pos=self:GetCoordinate()
  
  -- Create a new waypoint.
  local wp=pos:WaypointGround(0)
  
  -- Create new route consisting of only this position ==> Stop!
  self:Route({wp})
  
end

--- On after "EngageTarget" event.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Group#GROUP Group the group to be engaged.
function ARMYGROUP:onbeforeEngageTarget(From, Event, To, Target)

  local ammo=self:GetAmmoTot()
  
  if ammo.Total==0 then
    self:E(self.lid.."WARNING: Cannot engage TARGET because no ammo left!")
    return false
  end

  return true
end

--- On after "EngageTarget" event.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Group#GROUP Group the group to be engaged.
function ARMYGROUP:onafterEngageTarget(From, Event, To, Target)

  if Target:IsInstanceOf("TARGET") then
    self.engage.Target=Target
  else
    self.engage.Target=TARGET:New(Target)
  end

  -- Target coordinate.
  self.engage.Coordinate=UTILS.DeepCopy(self.engage.Target:GetCoordinate())
  
  -- TODO: Backup current ROE and alarm state and reset after disengage.
  
  -- Switch ROE and alarm state.
  self:SwitchAlarmstate(ENUMS.AlarmState.Auto)
  self:SwitchROE(ENUMS.ROE.WeaponFree)

  -- ID of current waypoint.
  local uid=self:GetWaypointCurrent().uid
  
  -- Add waypoint after current.
  self.engage.Waypoint=self:AddWaypoint(self.engage.Coordinate, nil, uid, Formation, true)
  
  -- Set if we want to resume route after reaching the detour waypoint.
  self.engage.Waypoint.detour=1

end

--- Update engage target.
-- @param #ARMYGROUP self
function ARMYGROUP:_UpdateEngageTarget()

  if self.engage.Target and self.engage.Target:IsAlive() then
  
    --env.info("FF Update Engage Target "..self.engage.Target:GetName())

    local vec3=self.engage.Target:GetCoordinate():GetVec3()
  
    local dist=UTILS.VecDist2D(vec3, self.engage.Coordinate:GetVec3())
    
    if dist>100 then
    
      --env.info("FF Update Engage Target Moved "..self.engage.Target:GetName())
    
      self.engage.Coordinate:UpdateFromVec3(vec3)

      -- ID of current waypoint.
      local uid=self:GetWaypointCurrent().uid
    
      -- Remove current waypoint
      self:RemoveWaypointByID(self.engage.Waypoint.uid)
  
        -- Add waypoint after current.
      self.engage.Waypoint=self:AddWaypoint(self.engage.Coordinate, nil, uid, Formation, true)
    
      -- Set if we want to resume route after reaching the detour waypoint.
      self.engage.Waypoint.detour=0      
    
    end
    
  else
    self:Disengage()
  end

end

--- On after "Disengage" event.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function ARMYGROUP:onafterDisengage(From, Event, To)
  -- TODO: Reset ROE and alarm state.
  self:_CheckGroupDone(1)    
end

--- On after "Rearmed" event.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function ARMYGROUP:onafterRearmed(From, Event, To)

  self:_CheckGroupDone(1)
    
end

--- On after "DetourReached" event.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function ARMYGROUP:onafterDetourReached(From, Event, To)
  self:I(self.lid.."Group reached detour coordinate.")
end


--- On after "FullStop" event.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function ARMYGROUP:onafterFullStop(From, Event, To)

  -- Get current position.
  local pos=self:GetCoordinate()
  
  -- Create a new waypoint.
  local wp=pos:WaypointGround(0)
  
  -- Create new route consisting of only this position ==> Stop!
  self:Route({wp})

end

--- On after "Cruise" event.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number Speed Speed in knots.
-- @param #number Formation Formation.
function ARMYGROUP:onafterCruise(From, Event, To, Speed, Formation)

  self:__UpdateRoute(-1, nil, Speed, Formation)

end

--- On after "Stop" event.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function ARMYGROUP:onafterStop(From, Event, To)

  -- Handle events:
  self:UnHandleEvent(EVENTS.Birth)
  self:UnHandleEvent(EVENTS.Dead)
  self:UnHandleEvent(EVENTS.RemoveUnit)
  
  -- Call OPSGROUP function.
  self:GetParent(self).onafterStop(self, From, Event, To)  
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Events DCS
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Event function handling the birth of a unit.
-- @param #ARMYGROUP self
-- @param Core.Event#EVENTDATA EventData Event data.
function ARMYGROUP:OnEventBirth(EventData)

  -- Check that this is the right group.
  if EventData and EventData.IniGroup and EventData.IniUnit and EventData.IniGroupName and EventData.IniGroupName==self.groupname then
    local unit=EventData.IniUnit
    local group=EventData.IniGroup
    local unitname=EventData.IniUnitName
    
    if self.respawning then
    
      local function reset()
        self.respawning=nil
      end
      
      -- Reset switch in 1 sec. This should allow all birth events of n>1 groups to have passed.
      -- TODO: Can I do this more rigorously?
      self:ScheduleOnce(1, reset)
    
    else
          
      -- Get element.
      local element=self:GetElementByName(unitname)

      -- Set element to spawned state.
      self:T3(self.lid..string.format("EVENT: Element %s born ==> spawned", element.name))            
      self:ElementSpawned(element)
      
    end    
    
  end

end

--- Event function handling the crash of a unit.
-- @param #ARMYGROUP self
-- @param Core.Event#EVENTDATA EventData Event data.
function ARMYGROUP:OnEventDead(EventData)

  -- Check that this is the right group.
  if EventData and EventData.IniGroup and EventData.IniUnit and EventData.IniGroupName and EventData.IniGroupName==self.groupname then
    self:T(self.lid..string.format("EVENT: Unit %s dead!", EventData.IniUnitName))
    
    local unit=EventData.IniUnit
    local group=EventData.IniGroup
    local unitname=EventData.IniUnitName

    -- Get element.
    local element=self:GetElementByName(unitname)

    if element then
      self:T(self.lid..string.format("EVENT: Element %s dead ==> destroyed", element.name))
      self:ElementDestroyed(element)
    end
    
  end

end

--- Event function handling when a unit is removed from the game.
-- @param #ARMYGROUP self
-- @param Core.Event#EVENTDATA EventData Event data.
function ARMYGROUP:OnEventRemoveUnit(EventData)

  -- Check that this is the right group.
  if EventData and EventData.IniGroup and EventData.IniUnit and EventData.IniGroupName and EventData.IniGroupName==self.groupname then
    local unit=EventData.IniUnit
    local group=EventData.IniGroup
    local unitname=EventData.IniUnitName

    -- Get element.
    local element=self:GetElementByName(unitname)

    if element then
      self:T(self.lid..string.format("EVENT: Element %s removed ==> dead", element.name))
      self:ElementDead(element)
    end

  end

end

--- Event function handling when a unit is hit.
-- @param #ARMYGROUP self
-- @param Core.Event#EVENTDATA EventData Event data.
function ARMYGROUP:OnEventHit(EventData)

  -- Check that this is the right group.
  if EventData and EventData.IniGroup and EventData.IniUnit and EventData.IniGroupName and EventData.IniGroupName==self.groupname then
    local unit=EventData.IniUnit
    local group=EventData.IniGroup
    local unitname=EventData.IniUnitName
    
    -- TODO: suppression

  end
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Routing
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Add an a waypoint to the route.
-- @param #ARMYGROUP self
-- @param Core.Point#COORDINATE Coordinate The coordinate of the waypoint.
-- @param #number Speed Speed in knots. Default is default cruise speed or 70% of max speed.
-- @param #number AfterWaypointWithID Insert waypoint after waypoint given ID. Default is to insert as last waypoint.
-- @param #number Formation Formation the group will use.
-- @param #boolean Updateroute If true or nil, call UpdateRoute. If false, no call.
-- @return Ops.OpsGroup#OPSGROUP.Waypoint Waypoint table.
function ARMYGROUP:AddWaypoint(Coordinate, Speed, AfterWaypointWithID, Formation, Updateroute)

  local coordinate=self:_CoordinateFromObject(Coordinate)

  -- Set waypoint index.
  local wpnumber=self:GetWaypointIndexAfterID(AfterWaypointWithID)

  -- Check if final waypoint is still passed.  
  if wpnumber>self.currentwp then
    self.passedfinalwp=false
  end
  
  -- Speed in knots.
  Speed=Speed or self:GetSpeedCruise()

  -- Create a Naval waypoint.
  local wp=coordinate:WaypointGround(UTILS.KnotsToKmph(Speed), Formation)
  
  -- Create waypoint data table.
  local waypoint=self:_CreateWaypoint(wp)
  
  -- Add waypoint to table.
  self:_AddWaypoint(waypoint, wpnumber)
  
  -- Get closest point to road.
  waypoint.roadcoord=coordinate:GetClosestPointToRoad(false)
  if waypoint.roadcoord then
    waypoint.roaddist=coordinate:Get2DDistance(waypoint.roadcoord)
  else
    waypoint.roaddist=1000*1000 --1000 km.
  end
  
  -- Debug info.
  self:T(self.lid..string.format("Adding waypoint UID=%d (index=%d), Speed=%.1f knots, Dist2Road=%d m, Action=%s", waypoint.uid, wpnumber, Speed, waypoint.roaddist, waypoint.action))
  
  -- Update route.
  if Updateroute==nil or Updateroute==true then
    self:_CheckGroupDone(1)
  end
  
  return waypoint
end

--- Initialize group parameters. Also initializes waypoints if self.waypoints is nil.
-- @param #ARMYGROUP self
-- @return #ARMYGROUP self
function ARMYGROUP:_InitGroup()

  -- First check if group was already initialized.
  if self.groupinitialized then
    self:E(self.lid.."WARNING: Group was already initialized!")
    return
  end

  -- Get template of group.
  self.template=self.group:GetTemplate()

  -- Define category.
  self.isAircraft=false
  self.isNaval=false
  self.isGround=true
  
  -- Ground are always AI.
  self.isAI=true
  
  -- Is (template) group late activated.
  self.isLateActivated=self.template.lateActivation
  
  -- Ground groups cannot be uncontrolled.
  self.isUncontrolled=false
  
  -- Max speed in km/h.
  self.speedMax=self.group:GetSpeedMax()
  
  -- Cruise speed in km/h
  self.speedCruise=self.speedMax*0.7
  
  -- Group ammo.
  self.ammo=self:GetAmmoTot()
  
  -- Radio parameters from template.
  self.radio.On=false  -- Radio is always OFF for ground.
  self.radio.Freq=133
  self.radio.Modu=radio.modulation.AM
  
  -- Set default radio.
  self:SetDefaultRadio(self.radio.Freq, self.radio.Modu, self.radio.On)
  
  -- Set default formation from first waypoint.
  self.optionDefault.Formation=self:GetWaypoint(1).action

  -- Default TACAN off.
  self:SetDefaultTACAN(nil, nil, nil, nil, true)
  self.tacan=UTILS.DeepCopy(self.tacanDefault)
  
  -- Units of the group.
  local units=self.group:GetUnits()
  
  for _,_unit in pairs(units) do
    local unit=_unit --Wrapper.Unit#UNIT

    -- TODO: this is wrong when grouping is used!
    local unittemplate=unit:GetTemplate()
    
    local element={} --#ARMYGROUP.Element
    element.name=unit:GetName()
    element.unit=unit    
    element.status=OPSGROUP.ElementStatus.INUTERO
    element.typename=unit:GetTypeName()
    element.skill=unittemplate.skill or "Unknown"
    element.ai=true
    element.category=element.unit:GetUnitCategory()
    element.categoryname=element.unit:GetCategoryName()
    element.size, element.length, element.height, element.width=unit:GetObjectSize()
    element.ammo0=self:GetAmmoUnit(unit, false)
    element.life0=unit:GetLife0()
    element.life=element.life0

    -- Debug text.
    if self.verbose>=2 then
      local text=string.format("Adding element %s: status=%s, skill=%s, life=%.3f category=%s (%d), size: %.1f (L=%.1f H=%.1f W=%.1f)",
      element.name, element.status, element.skill, element.life, element.categoryname, element.category, element.size, element.length, element.height, element.width)
      self:I(self.lid..text)
    end
  
    -- Add element to table.
    table.insert(self.elements, element)
    
    -- Get Descriptors.
    self.descriptors=self.descriptors or unit:GetDesc()
    
    -- Set type name.
    self.actype=self.actype or unit:GetTypeName()
    
    if unit:IsAlive() then    
      -- Trigger spawned event.
      self:ElementSpawned(element)
    end
    
  end

  -- Debug info.
  if self.verbose>=1 then
    local text=string.format("Initialized Army Group %s:\n", self.groupname)
    text=text..string.format("Unit type    = %s\n", self.actype)
    text=text..string.format("Speed max    = %.1f Knots\n", UTILS.KmphToKnots(self.speedMax))
    text=text..string.format("Speed cruise = %.1f Knots\n", UTILS.KmphToKnots(self.speedCruise))
    text=text..string.format("Elements     = %d\n", #self.elements)
    text=text..string.format("Waypoints    = %d\n", #self.waypoints)
    text=text..string.format("Radio        = %.1f MHz %s %s\n", self.radio.Freq, UTILS.GetModulationName(self.radio.Modu), tostring(self.radio.On))
    text=text..string.format("Ammo         = %d (G=%d/R=%d/M=%d)\n", self.ammo.Total, self.ammo.Guns, self.ammo.Rockets, self.ammo.Missiles)
    text=text..string.format("FSM state    = %s\n", self:GetState())
    text=text..string.format("Is alive     = %s\n", tostring(self:IsAlive()))
    text=text..string.format("LateActivate = %s\n", tostring(self:IsLateActivated()))
    self:I(self.lid..text)
  end
    
  -- Init done.
  self.groupinitialized=true
  
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Option Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Switch to a specific formation.
-- @param #ARMYGROUP self
-- @param #number Formation New formation the group will fly in. Default is the setting of `SetDefaultFormation()`.
-- @param #boolean Permanently If true, formation always used from now on.
-- @param #boolean NoRouteUpdate If true, route is not updated.
-- @return #ARMYGROUP self
function ARMYGROUP:SwitchFormation(Formation, Permanently, NoRouteUpdate)

  if self:IsAlive() or self:IsInUtero() then
  
    Formation=Formation or self.optionDefault.Formation

    if Permanently then
      self.formationPerma=Formation
    else
      self.formationPerma=nil
    end    
    
    -- Set current formation.
    self.option.Formation=Formation
    
    if self:IsInUtero() then
        self:T(self.lid..string.format("Will switch formation to %s (permanently=%s) when group is spawned", self.option.Formation, tostring(Permanently)))
    else
    
      -- Update route with the new formation.
      if NoRouteUpdate then
      else
        self:__UpdateRoute(-1, nil, nil, Formation)
      end
      
      -- Debug info.
      self:T(self.lid..string.format("Switching formation to %s (permanently=%s)", self.option.Formation, tostring(Permanently)))
      
    end

  end

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
