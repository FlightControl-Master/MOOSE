--- **Ops** - Enhanced Ground Group.
-- 
-- **Main Features:**
--
--    * Dynamically add and remove waypoints.
--     
-- ===
--
-- ### Author: **funkyfranky**
-- @module Ops.ArmyGroup
-- @image OPS_ArmyGroup.png


--- ARMYGROUP class.
-- @type ARMYGROUP
-- @field #boolean adinfinitum Resume route at first waypoint when final waypoint is reached.
-- @extends Ops.OpsGroup#OPSGROUP

--- *Something must be left to chance; nothing is sure in a sea fight above all.* -- Horatio Nelson
--
-- ===
--
-- ![Banner Image](..\Presentations\ARMYGROUP\NavyGroup_Main.jpg)
--
-- # The ARMYGROUP Concept
-- 
-- This class enhances naval groups.
-- 
-- @field #ARMYGROUP
ARMYGROUP = {
  ClassName       = "ARMYGROUP",
}

--- Navy group element.
-- @type ARMYGROUP.Element
-- @field #string name Name of the element, i.e. the unit.
-- @field #string typename Type name.

--- NavyGroup version.
-- @field #string version
ARMYGROUP.version="0.0.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
-- TODO: A lot.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new ARMYGROUP class object.
-- @param #ARMYGROUP self
-- @param #string GroupName Name of the group.
-- @return #ARMYGROUP self
function ARMYGROUP:New(GroupName)

  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, OPSGROUP:New(GroupName)) -- #ARMYGROUP
  
  -- Set some string id for output to DCS.log file.
  self.lid=string.format("ARMYGROUP %s | ", self.groupname)
  
  -- Defaults
  self:SetDefaultROE()
  self:SetDetection()
  self:SetPatrolAdInfinitum(true)

  -- Add FSM transitions.
  --                 From State  -->   Event      -->     To State
  self:AddTransition("*",             "FullStop",         "Holding")     -- Hold position.
  
  self:AddTransition("*",             "Detour",           "OnDetour")    -- Make a detour to a coordinate and resume route afterwards.
  self:AddTransition("OnDetour",      "DetourReached",    "Cruising")    -- Group reached the detour coordinate.
  
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

--- Group patrols ad inifintum. If the last waypoint is reached, it will go to waypoint one and repeat its route.
-- @param #ARMYGROUP self
-- @param #number Speed Speed in knots. Default 70% of max speed.
-- @return #ARMYGROUP self
function ARMYGROUP:SetSpeedCruise(Speed)
  
  self.speedCruise=Speed and UTILS.KnotsToKmph(Speed) or self.speedmax*0.7

  return self
end


--- Add a *scheduled* task.
-- @param #ARMYGROUP self
-- @param Core.Point#COORDINATE Coordinate Coordinate of the target.
-- @param #number Radius Radius in meters. Default 100 m.
-- @param #number Nshots Number of shots to fire. Default 3.
-- @param #number WeaponType Type of weapon. Default auto.
-- @param #string Clock Time when to start the attack.
-- @param #number Prio Priority of the task.
function ARMYGROUP:AddTaskFireAtPoint(Coordinate, Radius, Nshots, WeaponType, Clock, Prio)

  local DCStask=CONTROLLABLE.TaskFireAtPoint(nil, Coordinate:GetVec2(), Radius, Nshots, WeaponType)

  self:AddTask(DCStask, Clock, nil, Prio)

end

--- Add a *scheduled* task.
-- @param #ARMYGROUP self
-- @param Wrapper.Group#GROUP TargetGroup Target group.
-- @param #number WeaponExpend How much weapons does are used.
-- @param #number WeaponType Type of weapon. Default auto.
-- @param #string Clock Time when to start the attack.
-- @param #number Prio Priority of the task.
function ARMYGROUP:AddTaskAttackGroup(TargetGroup, WeaponExpend, WeaponType, Clock, Prio)

  local DCStask=CONTROLLABLE.TaskAttackGroup(nil, TargetGroup, WeaponType, WeaponExpend, AttackQty, Direction, Altitude, AttackQtyLimit, GroupAttack)

  self:AddTask(DCStask, Clock, nil, Prio)

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Status
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

---- Update status.
-- @param #ARMYGROUP self
function ARMYGROUP:onbeforeStatus(From, Event, To)

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
-- @param #ARMYGROUP self
function ARMYGROUP:onafterStatus(From, Event, To)

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
    
  
    -- Get number of tasks and missions.
    local nTaskTot, nTaskSched, nTaskWP=self:CountRemainingTasks()
    local nMissions=self:CountRemainingMissison()
  
    -- Info text.
    local text=string.format("State %s: Wp=%d/%d Speed=%.1f Heading=%03d Tasks=%d Missions=%d", 
    fsmstate, self.currentwp, #self.waypoints, speed, hdg, nTaskTot, nMissions)
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
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #ARMYGROUP.Element Element The group element.
function ARMYGROUP:onafterElementSpawned(From, Event, To, Element)
  self:I(self.lid..string.format("Element spawned %s", Element.name))

  -- Set element status.
  self:_UpdateStatus(Element, OPSGROUP.ElementStatus.SPAWNED)

end

--- On after "ElementDead" event.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #ARMYGROUP.Element Element The group element.
function ARMYGROUP:onafterElementDead(From, Event, To, Element)
  self:T(self.lid..string.format("Element dead %s.", Element.name))

  -- Set element status.
  self:_UpdateStatus(Element, OPSGROUP.ElementStatus.DEAD)
end

--- On after "Spawned" event.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function ARMYGROUP:onafterSpawned(From, Event, To)
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
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number n Waypoint number. Default is next waypoint.
-- @param #number Speed Speed in knots. Default cruise speed.
-- @param #number Depth Depth in meters. Default 0 meters.
function ARMYGROUP:onafterUpdateRoute(From, Event, To, n, Speed, Depth)

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
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Point#COORDINATE Coordinate Coordinate where to go.
-- @param #number Speed Speed in knots. Default cruise speed.
-- @param #number Depth Depth in meters. Default 0 meters.
-- @param #number ResumeRoute If true, resume route after detour point was reached.
function ARMYGROUP:onafterDetour(From, Event, To, Coordinate, Speed, Depth, ResumeRoute)

  -- Waypoints.
  local waypoints={}
    
  -- Depth for submarines.
  local depth=Depth or 0

  -- Get current speed in km/h.
  local speed=Speed and UTILS.KnotsToKmph(Speed) or self.group:GetVelocityKMH()
  
  -- Current waypoint.
  local current=self:GetCoordinate():WaypointGround(Speed,Formation,DCSTasks)
  table.insert(waypoints, current)
  
  -- At each waypoint report passing.
  local Task=self.group:TaskFunction("ARMYGROUP._DetourReached", self, ResumeRoute)
  
  local detour=Coordinate:WaypointNaval(speed, depth, {Task})
  table.insert(waypoints, detour)
  
  self:Route(waypoints)

end

--- On after "DetourReached" event.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function ARMYGROUP:onafterDetourReached(From, Event, To)
  self:I(self.lid.."Group reached detour coordinate.")
end

--- Function called when a group is passing a waypoint.
--@param Wrapper.Group#GROUP group Group that passed the waypoint
--@param #ARMYGROUP navygroup Navy group object.
--@param #boolean resume Resume route.
function ARMYGROUP._DetourReached(group, navygroup, resume)

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

--- On after "FullStop" event.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function ARMYGROUP:onafterFullStop(From, Event, To)

  -- Get current position.
  local pos=self:GetCoordinate()
  
  -- Create a new waypoint.
  local wp=pos:WaypointNaval(0)
  
  -- Create new route consisting of only this position ==> Stop!
  self:Route({wp})

end

--- On after "Cruise" event.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number Speed Speed in knots.
function ARMYGROUP:onafterCruise(From, Event, To, Speed)

  self:UpdateRoute(nil, Speed, self.depth)

end



--- On after "Dead" event.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function ARMYGROUP:onafterDead(From, Event, To)
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

--- On after Start event. Starts the ARMYGROUP FSM and event handlers.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function ARMYGROUP:onafterStop(From, Event, To)

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

--- Flightgroup event function handling the crash of a unit.
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
      self:I(self.lid..string.format("EVENT: Element %s dead ==> dead", element.name))
      self:ElementDead(element)
    end
    
  end

end

--- Flightgroup event function handling the crash of a unit.
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
      self:I(self.lid..string.format("EVENT: Element %s removed ==> dead", element.name))
      self:ElementDead(element)
    end

  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Routing
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Add an a waypoint to the route.
-- @param #ARMYGROUP self
-- @param Core.Point#COORDINATE coordinate The coordinate of the waypoint. Use COORDINATE:SetAltitude(altitude) to define the altitude.
-- @param #number speed Speed in knots. Default is default cruise speed or 70% of max speed.
-- @param #number wpnumber Waypoint number. Default at the end.
-- @param #boolean updateroute If true or nil, call UpdateRoute. If false, no call.
-- @return #number Waypoint index.
function ARMYGROUP:AddWaypoint(coordinate, speed, wpnumber, updateroute)

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
  
  
  -- Update route.
  if updateroute==nil or updateroute==true then
    self:_CheckGroupDone(1)
  end
  
  return wpnumber
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
  
  -- Ships are always AI.
  self.ai=true
  
  -- Is (template) group late activated.
  self.isLateActivated=self.template.lateActivation
  
  -- Naval groups cannot be uncontrolled.
  self.isUncontrolled=false
  
  -- Max speed in km/h.
  self.speedmax=self.group:GetSpeedMax()
  
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
    
    local element={} --#ARMYGROUP.Element
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

--- Check if group is done, i.e.
-- 
--  * passed the final waypoint, 
--  * no current task
--  * no current mission
--  * number of remaining tasks is zero
--  * number of remaining missions is zero
--  
-- @param #ARMYGROUP self
-- @param #number delay Delay in seconds.
function ARMYGROUP:_CheckGroupDone(delay)

  if self:IsAlive() and self.ai then

    if delay and delay>0 then
      -- Delayed call.
      self:ScheduleOnce(delay, ARMYGROUP._CheckGroupDone, self)
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


--- Get default cruise speed.
-- @param #ARMYGROUP self
-- @return #number Cruise speed (>0) in knots.
function ARMYGROUP:GetSpeedCruise()
  return UTILS.KmphToKnots(self.speedCruise or self.speedmax*0.7)
end

--- Returns a non-zero speed to the next waypoint (even if the waypoint speed is zero).
-- @param #ARMYGROUP self
-- @param #number indx Waypoint index.
-- @return #number Speed to next waypoint (>0) in knots.
function ARMYGROUP:GetSpeedToWaypoint(indx)

  local speed=self:GetWaypointSpeed(indx)
  
  if speed<=0.1 then
    speed=self:GetSpeedCruise()
  end

  return speed
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
