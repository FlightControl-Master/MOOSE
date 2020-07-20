--- **Ops** - Enhanced Naval Group.
-- 
-- **Main Features:**
--
--    * Dynamically add and remove waypoints.
--    * Let the group steam into the wind.
--    * Command a full stop.
--    * Let a submarine dive and surface.
--     
-- ===
--
-- ### Author: **funkyfranky**
-- @module Ops.NavyGroup
-- @image OPS_NavyGroup.png


--- NAVYGROUP class.
-- @type NAVYGROUP
-- @field #boolean turning If true, group is currently turning.
-- @field #NAVYGROUP.IntoWind intowind Into wind info.
-- @field #table Qintowind Queue of "into wind" turns.
-- @field #boolean adinfinitum Resume route at first waypoint when final waypoint is reached.
-- @field #number depth Ordered depth in meters.
-- @extends Ops.OpsGroup#OPSGROUP

--- *Something must be left to chance; nothing is sure in a sea fight above all.* -- Horatio Nelson
--
-- ===
--
-- ![Banner Image](..\Presentations\NAVYGROUP\NavyGroup_Main.jpg)
--
-- # The NAVYGROUP Concept
-- 
-- This class enhances naval groups.
-- 
-- @field #NAVYGROUP
NAVYGROUP = {
  ClassName       = "NAVYGROUP",
  turning         = false,
  intowind        = nil,
  intowindcounter = 0,
  Qintowind       = {},
}

--- Navy group element.
-- @type NAVYGROUP.Element
-- @field #string name Name of the element, i.e. the unit.
-- @field #string typename Type name.

--- Navy group element.
-- @type NAVYGROUP.IntoWind
-- @field #number Tstart Time to start.
-- @field #number Tstop Time to stop.
-- @field #boolean Uturn U-turn.
-- @field #number Speed Speed in knots.
-- @field #number Offset Offset angle in degrees.
-- @field #number Id Unique ID of the turn.
-- @field Core.Point#COORDINATE Coordinate Coordinate where we left the route.
-- @field #number Heading Heading the boat will take in degrees.
-- @field #boolean Open Currently active.
-- @field #boolean Over This turn is over.


--- NavyGroup version.
-- @field #string version
NAVYGROUP.version="0.1.0"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
-- DONE: Detour, add temporary waypoint and resume route.
-- DONE: Stop and resume route.
-- DONE: Add waypoints.
-- DONE: Add tasks.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new NAVYGROUP class object.
-- @param #NAVYGROUP self
-- @param #string GroupName Name of the group.
-- @return #NAVYGROUP self
function NAVYGROUP:New(GroupName)

  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, OPSGROUP:New(GroupName)) -- #NAVYGROUP
  
  -- Set some string id for output to DCS.log file.
  self.lid=string.format("NAVYGROUP %s | ", self.groupname)
  
  -- Defaults
  self:SetDefaultROE()
  self:SetDetection()
  self:SetPatrolAdInfinitum(true)

  -- Add FSM transitions.
  --                 From State  -->   Event      -->     To State
  self:AddTransition("*",             "FullStop",         "Holding")     -- Hold position.
  self:AddTransition("*",             "Cruise",           "Cruising")    -- Hold position.
  
  self:AddTransition("*",             "TurnIntoWind",     "*")           -- Command the group to turn into the wind.
  self:AddTransition("*",             "TurnIntoWindOver", "*")           -- Turn into wind is over.
  
  self:AddTransition("*",             "TurningStarted",   "*")           -- Group started turning.
  self:AddTransition("*",             "TurningStopped",   "*")           -- Group stopped turning.
  
  self:AddTransition("*",             "Detour",           "OnDetour")    -- Make a detour to a coordinate and resume route afterwards.
  self:AddTransition("OnDetour",      "DetourReached",    "Cruising")    -- Group reached the detour coordinate.
  
  self:AddTransition("*",             "Dive",             "Diving")      -- Command a submarine to dive.
  self:AddTransition("Diving",        "Surface",          "Cruising")    -- Command a submarine to go to the surface.
  
  ------------------------
  --- Pseudo Functions ---
  ------------------------

  --- Triggers the FSM event "Stop". Stops the NAVYGROUP and all its event handlers.
  -- @param #NAVYGROUP self

  --- Triggers the FSM event "Stop" after a delay. Stops the NAVYGROUP and all its event handlers.
  -- @function [parent=#NAVYGROUP] __Stop
  -- @param #NAVYGROUP self
  -- @param #number delay Delay in seconds.
  
  -- TODO: Add pseudo functions.


  -- Init waypoints.
  self:InitWaypoints()
  
  -- Initialize the group.
  self:_InitGroup()

  -- Debug trace.
  if false then
    self.Debug=true
    BASE:TraceOnOff(true)
    BASE:TraceClass(self.ClassName)
    BASE:TraceLevel(1)
  end
  
  -- Handle events:
  self:HandleEvent(EVENTS.Birth,      self.OnEventBirth)
  self:HandleEvent(EVENTS.Dead,       self.OnEventDead)
  self:HandleEvent(EVENTS.RemoveUnit, self.OnEventRemoveUnit)  
  
  -- Start the status monitoring.
  self:__CheckZone(-1)
  self:__Status(-2)
  self:__QueueUpdate(-3)
   
  return self  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Group patrols ad inifintum. If the last waypoint is reached, it will go to waypoint one and repeat its route.
-- @param #NAVYGROUP self
-- @param #boolean switch If true or nil, patrol until the end of time. If false, go along the waypoints once and stop.
-- @return #NAVYGROUP self
function NAVYGROUP:SetPatrolAdInfinitum(switch)
  if switch==false then
    self.adinfinitum=false
  else
    self.adinfinitum=true
  end
  return self
end

--- Group patrols ad inifintum. If the last waypoint is reached, it will go to waypoint one and repeat its route.
-- @param #NAVYGROUP self
-- @param #number Speed Speed in knots. Default 70% of max speed.
-- @return #NAVYGROUP self
function NAVYGROUP:SetSpeedCruise(Speed)
  
  self.speedCruise=Speed and UTILS.KnotsToKmph(Speed) or self.speedmax*0.7

  return self
end


--- Add a *scheduled* task.
-- @param #NAVYGROUP self
-- @param Core.Point#COORDINATE Coordinate Coordinate of the target.
-- @param #number Radius Radius in meters. Default 100 m.
-- @param #number Nshots Number of shots to fire. Default 3.
-- @param #number WeaponType Type of weapon. Default auto.
-- @param #string Clock Time when to start the attack.
-- @param #number Prio Priority of the task.
function NAVYGROUP:AddTaskFireAtPoint(Coordinate, Radius, Nshots, WeaponType, Clock, Prio)

  local DCStask=CONTROLLABLE.TaskFireAtPoint(nil, Coordinate:GetVec2(), Radius, Nshots, WeaponType)

  self:AddTask(DCStask, Clock, nil, Prio)

end

--- Add a *scheduled* task.
-- @param #NAVYGROUP self
-- @param Wrapper.Group#GROUP TargetGroup Target group.
-- @param #number WeaponExpend How much weapons does are used.
-- @param #number WeaponType Type of weapon. Default auto.
-- @param #string Clock Time when to start the attack.
-- @param #number Prio Priority of the task.
function NAVYGROUP:AddTaskAttackGroup(TargetGroup, WeaponExpend, WeaponType, Clock, Prio)

  local DCStask=CONTROLLABLE.TaskAttackGroup(nil, TargetGroup, WeaponType, WeaponExpend, AttackQty, Direction, Altitude, AttackQtyLimit, GroupAttack)

  self:AddTask(DCStask, Clock, nil, Prio)

end

--- Add aircraft recovery time window and recovery case.
-- @param #NAVYGROUP self
-- @param #string starttime Start time, e.g. "8:00" for eight o'clock. Default now.
-- @param #string stoptime Stop time, e.g. "9:00" for nine o'clock. Default 90 minutes after start time.
-- @param #number speed Speed in knots during turn into wind leg.
-- @param #boolean uturn If true (or nil), carrier wil perform a U-turn and go back to where it came from before resuming its route to the next waypoint. If false, it will go directly to the next waypoint.
-- @param #number offset Offset angle in degrees, e.g. to account for an angled runway. Default 0 deg.
-- @return #NAVYGROUP.IntoWind Recovery window.
function NAVYGROUP:CreateTurnIntoWind(starttime, stoptime, speed, uturn, offset)

  -- Absolute mission time in seconds.
  local Tnow=timer.getAbsTime()

  if starttime and type(starttime)=="number" then
    starttime=UTILS.SecondsToClock(Tnow+starttime)
  end

  if stoptime and type(stoptime)=="number" then
    stoptime=UTILS.SecondsToClock(Tnow+stoptime)
  end

  -- Input or now.
  starttime=starttime or UTILS.SecondsToClock(Tnow)

  -- Set start time.
  local Tstart=UTILS.ClockToSeconds(starttime)

  -- Set stop time.
  local Tstop=stoptime and UTILS.ClockToSeconds(stoptime) or Tstart+90*60

  -- Consistancy check for timing.
  if Tstart>Tstop then
    self:E(string.format("ERROR:Into wind stop time %s lies before start time %s. Input rejected!", UTILS.SecondsToClock(Tstart), UTILS.SecondsToClock(Tstop)))
    return self
  end
  if Tstop<=Tnow then
    self:I(string.format("WARNING: Into wind stop time %s already over. Tnow=%s! Input rejected.", UTILS.SecondsToClock(Tstop), UTILS.SecondsToClock(Tnow)))
    return self
  end

  -- Increase counter.
  self.intowindcounter=self.intowindcounter+1

  -- Recovery window.
  local recovery={} --#NAVYGROUP.IntoWind
  recovery.Tstart=Tstart
  recovery.Tstop=Tstop
  recovery.Open=false
  recovery.Over=false
  recovery.Speed=speed or 20
  recovery.Uturn=uturn and uturn or false
  recovery.Offset=offset or 0
  recovery.Id=self.intowindcounter

  return recovery
end

--- Add aircraft recovery time window and recovery case.
-- @param #NAVYGROUP self
-- @param #string starttime Start time, e.g. "8:00" for eight o'clock. Default now.
-- @param #string stoptime Stop time, e.g. "9:00" for nine o'clock. Default 90 minutes after start time.
-- @param #number speed Speed in knots during turn into wind leg.
-- @param #boolean uturn If true (or nil), carrier wil perform a U-turn and go back to where it came from before resuming its route to the next waypoint. If false, it will go directly to the next waypoint.
-- @param #number offset Offset angle in degrees, e.g. to account for an angled runway. Default 0 deg.
-- @return #NAVYGROUP.IntoWind Recovery window.
function NAVYGROUP:AddTurnIntoWind(starttime, stoptime, speed, uturn, offset)

  local recovery=self:CreateTurnIntoWind(starttime, stoptime, speed, uturn, offset)
  
  --TODO: check if window is overlapping with an other and if extend the window.
  
  -- Add to table
  table.insert(self.Qintowind, recovery)

  return recovery
end

--- Check if the group is currently turning.
-- @param #NAVYGROUP self
-- @return #boolean If true, group is currently turning.
function NAVYGROUP:IsTurning()
  return self.turning
end

--- Check if the group is currently steaming into the wind.
-- @param #NAVYGROUP self
-- @return #boolean If true, group is currently steaming into the wind.
function NAVYGROUP:IsSteamingIntoWind()
  if self.intowind then
    return true
  else
    return false    
  end
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Status
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

---- Update status.
-- @param #NAVYGROUP self
function NAVYGROUP:onbeforeStatus(From, Event, To)

  if self:IsDead() then  
    self:I(self.lid..string.format("Onbefore Status DEAD ==> false"))
    return false   
  elseif self:IsStopped() then
    self:I(self.lid..string.format("Onbefore Status STOPPED ==> false"))
    return false
  end

  return true
end

--- Update status.
-- @param #NAVYGROUP self
function NAVYGROUP:onafterStatus(From, Event, To)

  -- FSM state.
  local fsmstate=self:GetState()

  ---
  -- Detection
  ---
  
  -- Check if group has detected any units.
  if self.detectionOn then
    self:_CheckDetectedUnits()
  end
  
  if self:IsAlive() and not self:IsDead() then

    -- Current heading and position of the carrier.
    local hdg=self:GetHeading()
    local pos=self:GetCoordinate()
    local speed=self.group:GetVelocityKNOTS()
    
    -- Check if group started or stopped turning.
    self:_CheckTurning()
    
    -- Check water is ahead.
    local collision=self:_CheckCollisionCoord(pos:Translate(self.collisiondist or 5000, hdg))
    
    self:_CheckTurnsIntoWind()
  
    if self.intowind then
    
      if timer.getAbsTime()>=self.intowind.Tstop then
      
        self:TurnIntoWindOver()
        
      end
    
    end
  
    -- Get number of tasks and missions.
    local nTaskTot, nTaskSched, nTaskWP=self:CountRemainingTasks()
    local nMissions=self:CountRemainingMissison()
  
    -- Info text.
    local text=string.format("State %s: Wp=%d/%d Speed=%.1f Heading=%03d intowind=%s turning=%s collision=%s Tasks=%d Missions=%d", 
    fsmstate, self.currentwp, #self.waypoints, speed, hdg, tostring(self:IsSteamingIntoWind()), tostring(self:IsTurning()), tostring(collision), nTaskTot, nMissions)
    self:I(self.lid..text)
    
  else

    -- Info text.
    local text=string.format("State %s: Alive=%s", fsmstate, tostring(self:IsAlive()))
    self:I(self.lid..text)
  
  end


  ---
  -- Tasks
  ---
  
  -- Task queue.
  if #self.taskqueue>0 and self.verbose>1 then  
    local text=string.format("Tasks #%d", #self.taskqueue)
    for i,_task in pairs(self.taskqueue) do
      local task=_task --Ops.OpsGroup#OPSGROUP.Task
      local name=task.description
      local taskid=task.dcstask.id or "unknown"
      local status=task.status
      local clock=UTILS.SecondsToClock(task.time, true)
      local eta=task.time-timer.getAbsTime()
      local started=task.timestamp and UTILS.SecondsToClock(task.timestamp, true) or "N/A"
      local duration=-1
      if task.duration then
        duration=task.duration
        if task.timestamp then
          -- Time the task is running.
          duration=task.duration-(timer.getAbsTime()-task.timestamp)
        else
          -- Time the task is supposed to run.
          duration=task.duration
        end
      end
      -- Output text for element.
      if task.type==OPSGROUP.TaskType.SCHEDULED then
        text=text..string.format("\n[%d] %s (%s): status=%s, scheduled=%s (%d sec), started=%s, duration=%d", i, taskid, name, status, clock, eta, started, duration)
      elseif task.type==OPSGROUP.TaskType.WAYPOINT then
        text=text..string.format("\n[%d] %s (%s): status=%s, waypoint=%d, started=%s, duration=%d, stopflag=%d", i, taskid, name, status, task.waypoint, started, duration, task.stopflag:Get())
      end
    end
    self:I(self.lid..text)
  end
  
  ---
  -- Missions
  ---
  
  -- Current mission name.
  if self.verbose>0 then  
    local Mission=self:GetMissionByID(self.currentmission)
    
    -- Current status.
    local text=string.format("Missions %d, Current: %s", self:CountRemainingMissison(), Mission and Mission.name or "none")
    for i,_mission in pairs(self.missionqueue) do
      local mission=_mission --Ops.Auftrag#AUFTRAG
      local Cstart= UTILS.SecondsToClock(mission.Tstart, true)
      local Cstop = mission.Tstop and UTILS.SecondsToClock(mission.Tstop, true) or "INF"
      text=text..string.format("\n[%d] %s (%s) status=%s (%s), Time=%s-%s, prio=%d wp=%s targets=%d", 
      i, tostring(mission.name), mission.type, mission:GetGroupStatus(self), tostring(mission.status), Cstart, Cstop, mission.prio, tostring(mission:GetGroupWaypointIndex(self)), mission:CountMissionTargets())
    end
    self:I(self.lid..text)
  end



  self:__Status(-10)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Events
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after "ElementSpawned" event.
-- @param #NAVYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #NAVYGROUP.Element Element The group element.
function NAVYGROUP:onafterElementSpawned(From, Event, To, Element)
  self:I(self.lid..string.format("Element spawned %s", Element.name))

  -- Set element status.
  self:_UpdateStatus(Element, OPSGROUP.ElementStatus.SPAWNED)

end

--- On after "ElementDead" event.
-- @param #NAVYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #NAVYGROUP.Element Element The group element.
function NAVYGROUP:onafterElementDead(From, Event, To, Element)
  self:T(self.lid..string.format("Element dead %s.", Element.name))

  -- Set element status.
  self:_UpdateStatus(Element, OPSGROUP.ElementStatus.DEAD)
end

--- On after "Spawned" event.
-- @param #NAVYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function NAVYGROUP:onafterSpawned(From, Event, To)
  self:I(self.lid..string.format("Group spawned!"))

  if self.ai then
  
    -- Set default ROE and ROT options.
    self:SetOptionROE(self.roe)
    
  end
  
  -- Get orientation.
  self.Corientlast=self.group:GetUnit(1):GetOrientationX()
  
  self.depth=self.group:GetHeight()
  
  -- Update route.
  self:Cruise()
  
end

--- On after "UpdateRoute" event.
-- @param #NAVYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number n Waypoint number. Default is next waypoint.
-- @param #number Speed Speed in knots. Default cruise speed.
-- @param #number Depth Depth in meters. Default 0 meters.
function NAVYGROUP:onafterUpdateRoute(From, Event, To, n, Speed, Depth)

  -- Update route from this waypoint number onwards.
  n=n or self:GetWaypointIndexNext(self.adinfinitum)
  
  -- Debug info.
  self:T(self.lid..string.format("FF Update route n=%d", n))
  
  -- Update waypoint tasks, i.e. inject WP tasks into waypoint table.
  self:_UpdateWaypointTasks(n)

  -- Waypoints.
  local waypoints={}
  
  -- Depth for submarines.
  local depth=Depth or 0

  -- Get current speed in km/h.
  local speed=Speed and UTILS.KnotsToKmph(Speed) or self.group:GetVelocityKMH()
  
  -- Current waypoint.
  local current=self:GetCoordinate():WaypointNaval(speed, depth)
  table.insert(waypoints, current)
  
  -- Add remaining waypoints to route.
  for i=n, #self.waypoints do
    local wp=self.waypoints[i]
    
    -- Set speed.
    if i==n then
    
      if Speed then
        wp.speed=UTILS.KnotsToMps(Speed)
      elseif self.speedCruise then
        wp.speed=UTILS.KmphToMps(self.speedCruise)
      else
        -- Take default waypoint speed.
      end
    
    else
    
      if self.speedCruise then
        wp.speed=UTILS.KmphToMps(self.speedCruise)
      else
        -- Take default waypoint speed.
      end
      
    end
    
    -- Set depth.
    wp.alt=-depth --Depth and -Depth or wp.alt
    
    -- Add waypoint.
    table.insert(waypoints, wp)
  end

  
  if #waypoints>1 then
  
    self:I(self.lid..string.format("Updateing route: WP=%d, Speed=%.1f knots, depth=%d meters", #self.waypoints-n+1, UTILS.KmphToKnots(speed), depth))

    -- Route group to all defined waypoints remaining.
    self:Route(waypoints)
    
  else
  
    ---
    -- No waypoints left
    ---
  
    self:I(self.lid..string.format("No waypoints left"))
    
    if #self.waypoints>1 then
      self:I(self.lid..string.format("Resuming route at first waypoint"))
      self:__UpdateRoute(-1, 1, nil, self.depth)
    end
          
  end

end

--- On after "Detour" event.
-- @param #NAVYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Point#COORDINATE Coordinate Coordinate where to go.
-- @param #number Speed Speed in knots. Default cruise speed.
-- @param #number Depth Depth in meters. Default 0 meters.
-- @param #number ResumeRoute If true, resume route after detour point was reached.
function NAVYGROUP:onafterDetour(From, Event, To, Coordinate, Speed, Depth, ResumeRoute)

  -- Waypoints.
  local waypoints={}
    
  -- Depth for submarines.
  local depth=Depth or 0

  -- Get current speed in km/h.
  local speed=Speed and UTILS.KnotsToKmph(Speed) or self.group:GetVelocityKMH()
  
  -- Current waypoint.
  local current=self:GetCoordinate():WaypointNaval(speed, depth)
  table.insert(waypoints, current)
  
  -- At each waypoint report passing.
  local Task=self.group:TaskFunction("NAVYGROUP._DetourReached", self, ResumeRoute)
  
  local detour=Coordinate:WaypointNaval(speed, depth, {Task})
  table.insert(waypoints, detour)
  
  self:Route(waypoints)

end

--- On after "DetourReached" event.
-- @param #NAVYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function NAVYGROUP:onafterDetourReached(From, Event, To)
  self:I(self.lid.."Group reached detour coordinate.")
end

--- Function called when a group is passing a waypoint.
--@param Wrapper.Group#GROUP group Group that passed the waypoint
--@param #NAVYGROUP navygroup Navy group object.
--@param #boolean resume Resume route.
function NAVYGROUP._DetourReached(group, navygroup, resume)

  -- Debug message.
  local text=string.format("Group reached detour coordinate")
  navygroup:I(navygroup.lid..text)

  if resume then
    local indx=navygroup:GetWaypointIndexNext(true)
    local speed=navygroup:GetSpeedToWaypoint(indx)
    navygroup:UpdateRoute(indx, speed, navygroup.depth)
  end
  
  navygroup:DetourReached()

end

--- On after "TurnIntoWind" event.
-- @param #NAVYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #NAVYGROUP.IntoWind Into wind parameters.
-- @param #number Duration Duration in seconds.
-- @param #number Speed Speed in knots.
-- @param #boolean Uturn Return to the place we came from.
function NAVYGROUP:onafterTurnIntoWind(From, Event, To, IntoWind)

  IntoWind.Heading=self:GetHeadingIntoWind(IntoWind.Offset)
  
  IntoWind.Open=true
  
  IntoWind.Coordinate=self:GetCoordinate()

  self.intowind=IntoWind
  
  -- Wind speed in m/s.
  local _,vwind=self:GetWind()
  
  -- Convert to knots.
  vwind=UTILS.MpsToKnots(vwind)

  -- Speed of carrier in m/s but at least 2 knots.
  local speed=math.max(IntoWind.Speed-vwind, 2)

  -- Debug info.
  self:I(self.lid..string.format("Steaming into wind: Heading=%03d Speed=%.1f Vwind=%.1f Vtot=%.1f knots, Tstart=%d Tstop=%d", IntoWind.Heading, speed, vwind, speed+vwind, IntoWind.Tstart, IntoWind.Tstop))
  
  local distance=UTILS.NMToMeters(1000)
  
  local wp={}
  
  local coord=self:GetCoordinate()
  local Coord=coord:Translate(distance, IntoWind.Heading)
  
  wp[1]=coord:WaypointNaval(UTILS.KnotsToKmph(speed))
  wp[2]=Coord:WaypointNaval(UTILS.KnotsToKmph(speed))

  self:Route(wp)
  
end

--- On after "TurnIntoWindOver" event.
-- @param #NAVYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number Duration Duration in seconds.
-- @param #number Speed Speed in knots.
-- @param #boolean Uturn Return to the place we came from.
function NAVYGROUP:onafterTurnIntoWindOver(From, Event, To)

  self.intowind.Over=true
  self.intowind.Open=false    

  if self.intowind.Uturn then
    self:Detour(self.intowind.Coordinate, self:GetSpeedCruise(), 0, true)
  else
    local indx=self:GetWaypointIndexNext(self.adinfinitum)
    local speed=self:GetWaypointSpeed(indx)
    self:UpdateRoute(indx, speed, self.depth)
  end
  
  self.intowind=nil

end

--- On after "FullStop" event.
-- @param #NAVYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function NAVYGROUP:onafterFullStop(From, Event, To)

  -- Get current position.
  local pos=self:GetCoordinate()
  
  -- Create a new waypoint.
  local wp=pos:WaypointNaval(0)
  
  -- Create new route consisting of only this position ==> Stop!
  self:Route({wp})

end

--- On after "Cruise" event.
-- @param #NAVYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number Speed Speed in knots.
function NAVYGROUP:onafterCruise(From, Event, To, Speed)

  self:UpdateRoute(nil, Speed, self.depth)

end

--- On after "Dive" event.
-- @param #NAVYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number Depth Dive depth in meters. Default 50 meters.
function NAVYGROUP:onafterDive(From, Event, To, Depth)

  Depth=Depth or 50

  self:I(self.lid..string.format("Diving to %d meters", Depth))
  
  self.depth=Depth
  
  self:UpdateRoute(nil, nil, self.depth)

end

--- On after "Surface" event.
-- @param #NAVYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function NAVYGROUP:onafterSurface(From, Event, To)

  self.depth=0

  self:UpdateRoute(nil, nil, self.depth)

end

--- On after "Dead" event.
-- @param #NAVYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function NAVYGROUP:onafterDead(From, Event, To)
  self:I(self.lid..string.format("Group dead!"))

  -- Delete waypoints so they are re-initialized at the next spawn.
  self.waypoints=nil
  self.groupinitialized=false

  -- Cancel all mission.
  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG

    self:MissionCancel(mission)
    mission:GroupDead(self)

  end

  -- Stop
  self:Stop()
end

--- On after Start event. Starts the NAVYGROUP FSM and event handlers.
-- @param #NAVYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function NAVYGROUP:onafterStop(From, Event, To)

  -- Check if group is still alive.
  if self:IsAlive() then
    -- Destroy group. No event is generated.
    self.group:Destroy(false)
  end

  -- Handle events:
  self:UnHandleEvent(EVENTS.Birth)
  self:UnHandleEvent(EVENTS.Dead)
  self:UnHandleEvent(EVENTS.RemoveUnit)

  self.CallScheduler:Clear()

  self:I(self.lid.."STOPPED! Unhandled events, cleared scheduler and removed from database.")
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Events DCS
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Event function handling the birth of a unit.
-- @param #NAVYGROUP self
-- @param Core.Event#EVENTDATA EventData Event data.
function NAVYGROUP:OnEventBirth(EventData)

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

--- Flightgroup event function handling the crash of a unit.
-- @param #NAVYGROUP self
-- @param Core.Event#EVENTDATA EventData Event data.
function NAVYGROUP:OnEventDead(EventData)

  -- Check that this is the right group.
  if EventData and EventData.IniGroup and EventData.IniUnit and EventData.IniGroupName and EventData.IniGroupName==self.groupname then
    self:T(self.lid..string.format("EVENT: Unit %s dead!", EventData.IniUnitName))
    
    local unit=EventData.IniUnit
    local group=EventData.IniGroup
    local unitname=EventData.IniUnitName

    -- Get element.
    local element=self:GetElementByName(unitname)

    if element then
      self:I(self.lid..string.format("EVENT: Element %s dead ==> dead", element.name))
      self:ElementDead(element)
    end
    
  end

end

--- Flightgroup event function handling the crash of a unit.
-- @param #NAVYGROUP self
-- @param Core.Event#EVENTDATA EventData Event data.
function NAVYGROUP:OnEventRemoveUnit(EventData)

  -- Check that this is the right group.
  if EventData and EventData.IniGroup and EventData.IniUnit and EventData.IniGroupName and EventData.IniGroupName==self.groupname then
    local unit=EventData.IniUnit
    local group=EventData.IniGroup
    local unitname=EventData.IniUnitName

    -- Get element.
    local element=self:GetElementByName(unitname)

    if element then
      self:I(self.lid..string.format("EVENT: Element %s removed ==> dead", element.name))
      self:ElementDead(element)
    end

  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Routing
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Add an a waypoint to the route.
-- @param #NAVYGROUP self
-- @param Core.Point#COORDINATE coordinate The coordinate of the waypoint. Use COORDINATE:SetAltitude(altitude) to define the altitude.
-- @param #number speed Speed in knots. Default is default cruise speed or 70% of max speed.
-- @param #number wpnumber Waypoint number. Default at the end.
-- @param #boolean updateroute If true or nil, call UpdateRoute. If false, no call.
-- @return #number Waypoint index.
function NAVYGROUP:AddWaypoint(coordinate, speed, wpnumber, updateroute)

  -- Waypoint number. Default is at the end.
  wpnumber=wpnumber or #self.waypoints+1
  
  if wpnumber>self.currentwp then
    self.passedfinalwp=false
  end
  
  -- Speed in knots.
  speed=speed or self:GetSpeedCruise()

  -- Speed at waypoint.
  local speedkmh=UTILS.KnotsToKmph(speed)

  -- Create a Naval waypoint.
  local wp=coordinate:WaypointNaval(speedkmh)
  
  -- Add to table.
  table.insert(self.waypoints, wpnumber, wp)
  
  -- Debug info.
  self:T(self.lid..string.format("Adding NAVAL waypoint #%d, speed=%.1f knots. Last waypoint passed was #%s. Total waypoints #%d", wpnumber, speed, self.currentwp, #self.waypoints))
  
  -- Shift all waypoint tasks after the inserted waypoint.
  for _,_task in pairs(self.taskqueue) do
    local task=_task --Ops.OpsGroup#OPSGROUP.Task
    if task.type==OPSGROUP.TaskType.WAYPOINT and task.waypoint and task.waypoint>=wpnumber then
      task.waypoint=task.waypoint+1
    end
  end  

  -- Shift all mission waypoints after the inserted waypoint.
  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG

    -- Get mission waypoint index.
    local wpidx=mission:GetGroupWaypointIndex(self)
    
    -- Increase number if this waypoint lies in the future.
    if wpidx and wpidx>=wpnumber then
      mission:SetGroupWaypointIndex(self, wpidx+1)
    end    
    
  end
  
  -- Update route.
  if updateroute==nil or updateroute==true then
    self:_CheckGroupDone(1)
  end
  
  return wpnumber
end

--- Initialize group parameters. Also initializes waypoints if self.waypoints is nil.
-- @param #NAVYGROUP self
-- @return #NAVYGROUP self
function NAVYGROUP:_InitGroup()

  -- First check if group was already initialized.
  if self.groupinitialized then
    self:E(self.lid.."WARNING: Group was already initialized!")
    return
  end

  -- Get template of group.
  self.template=self.group:GetTemplate()

  -- Define category.
  self.isAircraft=false
  self.isNaval=true
  self.isGround=false


  -- Helo group.
  --self.isSubmarine=self.group:IsSubmarine()
  
  -- Ships are always AI.
  self.ai=true
  
  -- Is (template) group late activated.
  self.isLateActivated=self.template.lateActivation
  
  -- Naval groups cannot be uncontrolled.
  self.isUncontrolled=false
  
  -- Max speed in km/h.
  self.speedmax=self.group:GetSpeedMax()
  
  -- Cruise speed: 70% of max speed but within limit.
  --self.speedCruise=self.speedmax*0.7
  
  -- Group ammo.
  --self.ammo=self:GetAmmoTot()
  
  self.traveldist=0
  self.traveltime=timer.getAbsTime()
  self.position=self:GetCoordinate()
  
  -- Radio parameters from template.
  self.radioOn=true  -- Radio is always on for ships.
  self.radioFreq=tonumber(self.template.units[1].frequency)/1000000
  self.radioModu=tonumber(self.template.units[1].modulation)/1000000
  
  -- If not set by the use explicitly yet, we take the template values as defaults.
  if not self.radioFreqDefault then
    self.radioFreqDefault=self.radioFreq
    self.radioModuDefault=self.radioModu
  end
  
  -- Set default formation.
  if not self.formationDefault then
    if self.ishelo then
      self.formationDefault=ENUMS.Formation.RotaryWing.EchelonLeft.D300
    else
      self.formationDefault=ENUMS.Formation.FixedWing.EchelonLeft.Group
    end
  end
  
  local units=self.group:GetUnits()
  
  for _,_unit in pairs(units) do
    local unit=_unit --Wrapper.Unit#UNIT
    
    local element={} --#NAVYGROUP.Element
    element.name=unit:GetName()
    element.typename=unit:GetTypeName()
    element.status=OPSGROUP.ElementStatus.INUTERO
    element.unit=unit
    table.insert(self.elements, element)
    
    self:GetAmmoUnit(unit, false)
    
    if unit:IsAlive() then      
      self:ElementSpawned(element)
    end
    
  end

  -- Get first unit. This is used to extract other parameters.
  local unit=self.group:GetUnit(1)
  
  if unit then
    
    self.descriptors=unit:GetDesc()
    
    self.actype=unit:GetTypeName()
    
    -- Debug info.
    local text=string.format("Initialized Navy Group %s:\n", self.groupname)
    text=text..string.format("AC type      = %s\n", self.actype)
    text=text..string.format("Speed max    = %.1f Knots\n", UTILS.KmphToKnots(self.speedmax))
    --text=text..string.format("Speed cruise = %.1f Knots\n", UTILS.KmphToKnots(self.speedCruise))
    text=text..string.format("Elements     = %d\n", #self.elements)
    text=text..string.format("Waypoints    = %d\n", #self.waypoints)
    text=text..string.format("Radio        = %.1f MHz %s %s\n", self.radioFreq, UTILS.GetModulationName(self.radioModu), tostring(self.radioOn))
    --text=text..string.format("Ammo         = %d (G=%d/R=%d/B=%d/M=%d)\n", self.ammo.Total, self.ammo.Guns, self.ammo.Rockets, self.ammo.Bombs, self.ammo.Missiles)
    text=text..string.format("FSM state    = %s\n", self:GetState())
    text=text..string.format("Is alive     = %s\n", tostring(self.group:IsAlive()))
    text=text..string.format("LateActivate = %s\n", tostring(self:IsLateActivated()))
    self:I(self.lid..text)
    
    -- Init done.
    self.groupinitialized=true
    
  end
  
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Check for possible collisions between two coordinates.
-- @param #NAVYGROUP self
-- @param Core.Point#COORDINATE coordto Coordinate to which the collision is check.
-- @param Core.Point#COORDINATE coordfrom Coordinate from which the collision is check.
-- @return #boolean If true, surface type ahead is not deep water.
-- @return #number Max free distance in meters.
function NAVYGROUP:_CheckCollisionCoord(coordto, coordfrom)

  -- Increment in meters.
  local dx=100

  -- From coordinate. Default 500 in front of the carrier.
  local d=0
  if coordfrom then
    d=0
  else
    d=250
    coordfrom=self:GetCoordinate():Translate(d, self:GetHeading())
  end

  -- Distance between the two coordinates.
  local dmax=coordfrom:Get2DDistance(coordto)

  -- Direction.
  local direction=coordfrom:HeadingTo(coordto)

  -- Scan path between the two coordinates.
  local clear=true
  while d<=dmax do

    -- Check point.
    local cp=coordfrom:Translate(d, direction)

    -- Check if surface type is water.
    if not cp:IsSurfaceTypeWater() then

      -- Debug mark points.
      if self.Debug or true then
        local st=cp:GetSurfaceType()
        cp:MarkToAll(string.format("Collision check surface type %d", st))
      end

      -- Collision WARNING!
      clear=false
      break
    end

    -- Increase distance.
    d=d+dx
  end

  local text=""
  if clear then
    text=string.format("Path into direction %03d° is clear for the next %.1f NM.", direction, UTILS.MetersToNM(d))
  else
    text=string.format("Detected obstacle at distance %.1f NM into direction %03d°.", UTILS.MetersToNM(d), direction)
  end
  self:T(self.lid..text)

  return not clear, d
end

--- Check if group is turning.
-- @param #NAVYGROUP self
function NAVYGROUP:_CheckTurning()

  local unit=self.group:GetUnit(1)
  
  if unit and unit:IsAlive() then

    -- Current orientation of carrier.
    local vNew=unit:GetOrientationX()
  
    -- Last orientation from 30 seconds ago.
    local vLast=self.Corientlast or vNew
  
    -- We only need the X-Z plane.
    vNew.y=0 ; vLast.y=0
  
    -- Angle between current heading and last time we checked ~30 seconds ago.
    local deltaLast=math.deg(math.acos(UTILS.VecDot(vNew,vLast)/UTILS.VecNorm(vNew)/UTILS.VecNorm(vLast)))
  
    -- Last orientation becomes new orientation
    self.Corientlast=vNew
  
    -- Carrier is turning when its heading changed by at least two degrees since last check.
    local turning=math.abs(deltaLast)>=2
  
    -- Check if turning stopped.
    if self.turning and not turning then
  
      -- Carrier was turning but is not any more.
      self:TurningStopped()
      
    elseif turning and not self.turning then
  
      -- Carrier was not turning but is now.
      self:TurningStarted()    
  
    end
  
    -- Update turning.
    self.turning=turning
    
  end
  
end

--- Check if group is done, i.e.
-- 
--  * passed the final waypoint, 
--  * no current task
--  * no current mission
--  * number of remaining tasks is zero
--  * number of remaining missions is zero
--  
-- @param #NAVYGROUP self
-- @param #number delay Delay in seconds.
function NAVYGROUP:_CheckGroupDone(delay)

  if self:IsAlive() and self.ai then

    if delay and delay>0 then
      -- Delayed call.
      self:ScheduleOnce(delay, NAVYGROUP._CheckGroupDone, self)
    else
    
      if self.passedfinalwp then
      
        if #self.waypoints>1 and self.adinfinitum then
          
          local speed=self:GetSpeedToWaypoint(1)
        
          -- Start route at first waypoint.
          self:__UpdateRoute(-1, 1, speed, self.depth)
          
        end
    
      else
      
        self:UpdateRoute(nil, nil, self.depth)
        
      end
    
    end
    
  end
  
end

--- Check queued turns into wind.
-- @param #NAVYGROUP self
function NAVYGROUP:_CheckTurnsIntoWind()

  -- Get current abs time.
  local time=timer.getAbsTime()
  local Cnow=UTILS.SecondsToClock(time)

  -- Debug output:
  local text=string.format(self.lid.."Recovery time windows:")

  -- Handle case with no recoveries.
  if #self.Qintowind==0 then
    text=text.." none!"
  end

  -- Sort windows wrt to start time.
  table.sort(self.Qintowind, function(a, b) return a.Tstart<b.Tstart end)

  -- Loop over all slots.
  for _,_recovery in pairs(self.Qintowind) do
    local recovery=_recovery --#NAVYGROUP.IntoWind

    -- Get start/stop clock strings.
    local Cstart=UTILS.SecondsToClock(recovery.Tstart)
    local Cstop=UTILS.SecondsToClock(recovery.Tstop)

    -- Debug text.
    text=text..string.format("\n- Start=%s Stop=%s Open=%s Closed=%s", Cstart, Cstop, tostring(recovery.Open), tostring(recovery.Over))
  end

  -- Debug output.
  self:T(self.lid..text)


  -- Loop over all slots.
  for _,_recovery in pairs(self.Qintowind) do
    local recovery=_recovery --#NAVYGROUP.IntoWind

    if time>=recovery.Tstart and time<recovery.Tstop and not recovery.Open then
      self:TurnIntoWind(recovery)
      break
    end
    
  end
end

--- Get default cruise speed.
-- @param #NAVYGROUP self
-- @return #number Cruise speed (>0) in knots.
function NAVYGROUP:GetSpeedCruise()
  return UTILS.KmphToKnots(self.speedCruise or self.speedmax*0.7)
end

--- Returns a non-zero speed to the next waypoint (even if the waypoint speed is zero).
-- @param #NAVYGROUP self
-- @param #number indx Waypoint index.
-- @return #number Speed to next waypoint (>0) in knots.
function NAVYGROUP:GetSpeedToWaypoint(indx)

  local speed=self:GetWaypointSpeed(indx)
  
  if speed<=0.1 then
    speed=self:GetSpeedCruise()
  end

  return speed
end

--- Check queued turns into wind.
-- @param #NAVYGROUP self
-- @return #NAVYGROUP.IntoWind Next into wind data.
function NAVYGROUP:GetNextTurnIntoWind()

  -- Loop over all windows.
  for _,_recovery in pairs(self.Qintowind) do
    local recovery=_recovery --#NAVYGROUP.IntoWind
    
  end

end

--- Get wind direction and speed at current position.
-- @param #NAVYGROUP self
-- @return #number Direction the wind is blowing **from** in degrees.
-- @return #number Wind speed in m/s.
function NAVYGROUP:GetWind()

  -- Current position of the carrier or input.
  local coord=self:GetCoordinate()

  -- Wind direction and speed. By default at 50 meters ASL.
  local Wdir, Wspeed=coord:GetWind(50)

  return Wdir, Wspeed
end

--- Get heading of group into the wind.
-- @param #NAVYGROUP self
-- @param #number Offset Offset angle in degrees, e.g. to account for an angled runway.
-- @return #number Carrier heading in degrees.
function NAVYGROUP:GetHeadingIntoWind(Offset)

  Offset=Offset or 0

  -- Get direction the wind is blowing from. This is where we want to go.
  local windfrom, vwind=self:GetWind()

  -- Actually, we want the runway in the wind.
  local intowind=windfrom-Offset

  -- If no wind, take current heading.
  if vwind<0.1 then
    intowind=self:GetHeading()
  end

  -- Adjust negative values.
  if intowind<0 then
    intowind=intowind+360
  end

  return intowind
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
