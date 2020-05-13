--- **Ops** - Generic group functions.
-- 
-- **Main Features:**
--
--    * Nice stuff.
--     
-- ===
--
-- ### Author: **funkyfranky**
-- @module Ops.OpsGroup
-- @image OPS_OpsGroup.png


--- OPSGROUP class.
-- @type OPSGROUP
-- @field #string ClassName Name of the class.
-- @field #boolean Debug Debug mode. Messages to all about status.
-- @field #string lid Class id string for output to DCS log file.
-- @field #string groupname The name of the group.
-- @field Wrapper.Group#GROUP group The group object.
-- @field #table elements Elements of the group.
-- @field #number currentwp Last waypoint passed.
-- @field #number speedCruise Cruising speed in km/h.
-- @extends Core.Fsm#FSM

--- *Something must be left to chance; nothing is sure in a sea fight above all.* --- Horatio Nelson
--
-- ===
--
-- ![Banner Image](..\Presentations\OPSGROUP\OpsGroup_Main.jpg)
--
-- # The OPSGROUP Concept
-- 
-- The OPSGROUP class contains common functions used by other classes such as FLIGHGROUP and NAVYGROUP.
-- 
-- This class is not meant to be used itself by the end user.
-- 
-- 
-- @field #OPSGROUP
OPSGROUP = {
  ClassName      = "OPSGROUP",
  lid            =   nil,
  groupname      =   nil,
  group          =   nil,
  currentwp      =     1,
  elements       =    {},
  taskqueue      =    {},
}

--- Flight group task status.
-- @type FLIGHTGROUP.TaskStatus
-- @field #string SCHEDULED Task is scheduled.
-- @field #string EXECUTING Task is being executed.
-- @field #string PAUSED Task is paused.
-- @field #string DONE Task is done.
FLIGHTGROUP.TaskStatus={
  SCHEDULED="scheduled",
  EXECUTING="executing",
  PAUSED="paused",
  DONE="done",
}

--- Flight group task status.
-- @type FLIGHTGROUP.TaskType
-- @field #string SCHEDULED Task is scheduled and will be executed at a given time.
-- @field #string WAYPOINT Task is executed at a specific waypoint.
FLIGHTGROUP.TaskType={
  SCHEDULED="scheduled",
  WAYPOINT="waypoint",
}

--- Flight group task structure.
-- @type FLIGHTGROUP.Task
-- @field #string type Type of task: either SCHEDULED or WAYPOINT.
-- @field #number id Task ID. Running number to get the task.
-- @field #number prio Priority.
-- @field #number time Abs. mission time when to execute the task.
-- @field #table dcstask DCS task structure.
-- @field #string description Brief text which describes the task.
-- @field #string status Task status.
-- @field #number duration Duration before task is cancelled in seconds. Default never.
-- @field #number timestamp Abs. mission time, when task was started.
-- @field #number waypoint Waypoint index if task is a waypoint task.
-- @field Core.UserFlag#USERFLAG stopflag If flag is set to 1 (=true), the task is stopped.

--- Enroute task.
-- @type FLIGHTGROUP.EnrouteTask
-- @field DCS#Task DCStask DCS task structure table.
-- @field #number WaypointIndex Waypoint number at which the enroute task is added.


--- NavyGroup version.
-- @field #string version
OPSGROUP.version="0.0.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
-- TODO: Implement common functions.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new OPSGROUP class object.
-- @param #OPSGROUP self
-- @param #string GroupName Name of the group.
-- @return #OPSGROUP self
function OPSGROUP:New(GroupName)

  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, FSM:New()) -- #OPSGROUP
  
  
  self.groupname=GroupName
  
  self.group=GROUP:FindByName(self.groupname)
  
  -- Set some string id for output to DCS.log file.
  self.lid=string.format("OPSGROUP %s |", self.groupname)
  
  self:SetStartState("Stopped")

  -- Add FSM transitions.
  --                 From State  -->   Event      -->     To State
  self:AddTransition("Stopped",       "Start",            "Cruising")    -- Status update.
  self:AddTransition("*",             "Status",           "*")           -- Status update.
  
  self:AddTransition("*",             "PassingWaypoint",  "*")           -- Passing waypoint.
  self:AddTransition("*",             "UpdateRoute",      "*")           -- Passing waypoint.    


  ------------------------
  --- Pseudo Functions ---
  ------------------------

  --- Triggers the FSM event "Start". Starts the OPSGROUP. Initializes parameters and starts event handlers.
  -- @function [parent=#OPSGROUP] Start
  -- @param #OPSGROUP self

  --- Triggers the FSM event "Start" after a delay. Starts the OPSGROUP. Initializes parameters and starts event handlers.
  -- @function [parent=#OPSGROUP] __Start
  -- @param #OPSGROUP self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Stop". Stops the OPSGROUP and all its event handlers.
  -- @param #OPSGROUP self

  --- Triggers the FSM event "Stop" after a delay. Stops the OPSGROUP and all its event handlers.
  -- @function [parent=#OPSGROUP] __Stop
  -- @param #OPSGROUP self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Status".
  -- @function [parent=#OPSGROUP] Status
  -- @param #OPSGROUP self

  --- Triggers the FSM event "Status" after a delay.
  -- @function [parent=#OPSGROUP] __Status
  -- @param #OPSGROUP self
  -- @param #number delay Delay in seconds.  

  -- Debug trace.
  if false then
    self.Debug=true
    BASE:TraceOnOff(true)
    BASE:TraceClass(self.ClassName)
    BASE:TraceLevel(1)
  end
   
  return self  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get coalition.
-- @param #OPSGROUP self
-- @return #number Coalition side of carrier.
function OPSGROUP:GetCoalition()
  return self.group:GetCoalition()
end

--- Get coordinate.
-- @param #OPSGROUP self
-- @return Core.Point#COORDINATE Carrier coordinate.
function OPSGROUP:GetCoordinate()
  return self.group:GetCoordinate()
end

--- Set detection on or off.
-- @param #FLIGHTGROUP self
-- @param #boolean Switch If true, detection is on. If false or nil, detection is off. Default is off.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:SetDetection(Switch)
  self.detectionOn=Switch
  return self
end

--- Define a SET of zones that trigger and event if the group enters or leaves any of the zones.
-- @param #FLIGHTGROUP self
-- @param Core.Set#SET_ZONE CheckZonesSet Set of zones.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:SetCheckZones(CheckZonesSet)
  self.checkzones=CheckZonesSet
  return self
end

--- Add a zone that triggers and event if the group enters or leaves any of the zones.
-- @param #FLIGHTGROUP self
-- @param Core.Zone#ZONE CheckZone Zone to check.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:AddCheckZone(CheckZone)
  if not self.checkzones then
    self.checkzones=SET_ZONE:New()
  end
  self.checkzones:AddZone(CheckZone)
  return self
end

--- Get set of detected units.
-- @param #FLIGHTGROUP self
-- @return Core.Set#SET_UNIT Set of detected units.
function FLIGHTGROUP:GetDetectedUnits()
  return self.detectedunits
end

--- Get MOOSE group object.
-- @param #FLIGHTGROUP self
-- @return Wrapper.Group#GROUP Moose group object.
function FLIGHTGROUP:GetGroup()
  return self.group
end

--- Get flight group name.
-- @param #FLIGHTGROUP self
-- @return #string Group name.
function FLIGHTGROUP:GetName()
  return self.groupname
end

--- Get current coordinate of the group.
-- @param #FLIGHTGROUP self
-- @return Core.Point#COORDINATE The coordinate (of the first unit) of the group.
function FLIGHTGROUP:GetCoordinate()
  if self:IsAlive()~=nil then
    return self.group:GetCoordinate()    
  else
    self:E(self.lid.."WARNING: Group is not alive. Cannot get coordinate!")
  end
  return nil
end

--- Get waypoint.
-- @param #FLIGHTGROUP self
-- @param #number indx Waypoint index.
-- @return #table Waypoint table.
function FLIGHTGROUP:GetWaypoint(indx)
  return self.waypoints[indx]
end

--- Get final waypoint.
-- @param #FLIGHTGROUP self
-- @return #table Waypoint table.
function FLIGHTGROUP:GetWaypointFinal()
  return self.waypoints[#self.waypoints]
end

--- Get next waypoint.
-- @param #FLIGHTGROUP self
-- @return #table Waypoint table.
function FLIGHTGROUP:GetWaypointNext()
  local n=math.min(self.currentwp+1, #self.waypoints)
  return self.waypoints[n]
end

--- Get current waypoint.
-- @param #FLIGHTGROUP self
-- @return #table Waypoint table.
function FLIGHTGROUP:GetWaypointCurrent()
  return self.waypoints[self.currentwp]
end

--- Activate a *late activated* group.
-- @param #FLIGHTGROUP self
-- @param #number delay (Optional) Delay in seconds before the group is activated. Default is immediately.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:Activate(delay)

  if delay and delay>0 then
      self:T2(self.lid..string.format("Activating late activated group in %d seconds", delay))
      self:ScheduleOnce(delay, FLIGHTGROUP.Activate, self)  
  else
  
    if self:IsAlive()==false then
    
      self:T(self.lid.."Activating late activated group")
      self.group:Activate()
      self.isLateActivated=false
      
    elseif self:IsAlive()==true then
      self:E(self.lid.."WARNING: Activating group that is already activated")
    else
      self:E(self.lid.."ERROR: Activating group that is does not exist!")
    end
    
  end

  return self
end

--- Self destruction of group. An explosion is created at the position of each element.
-- @param #FLIGHTGROUP self
-- @param #number Delay Delay in seconds. Default now.
-- @param #number ExplosionPower (Optional) Explosion power in kg TNT. Default 500 kg.
-- @return #number Relative fuel in percent.
function FLIGHTGROUP:SelfDestruction(Delay, ExplosionPower)

  if Delay and Delay>0 then
    self:ScheduleOnce(Delay, FLIGHTGROUP.SelfDestruction, self, 0, ExplosionPower)
  else
  
    -- Loop over all elements.
    for i,_element in pairs(self.elements) do
      local element=_element --#FLIGHTGROUP.Element
      
      local unit=element.unit
      
      if unit and unit:IsAlive() then
        unit:Explode(ExplosionPower)
      end
    end
  end

end

--- Route group along waypoints.
-- @param #FLIGHTGROUP self
-- @param #table waypoints Table of waypoints.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:Route(waypoints)

  if self:IsAlive() then

    -- DCS task combo.
    local Tasks={}

    -- Route (Mission) task.
    local TaskRoute=self.group:TaskRoute(waypoints)
    table.insert(Tasks, TaskRoute)
    
    -- TaskCombo of enroute and mission tasks.
    local TaskCombo=self.group:TaskCombo(Tasks)
        
    -- Set tasks.
    if #Tasks>1 then
      self:SetTask(TaskCombo)
    else
      self:SetTask(TaskRoute)
    end
    
  else
    self:E(self.lid.."ERROR: Group is not alive!")
  end
  
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Task Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set DCS task. Enroute tasks are injected automatically.
-- @param #FLIGHTGROUP self
-- @param #table DCSTask DCS task structure.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:SetTask(DCSTask)

  if self:IsAlive() then
  
    if self.taskcurrent>0 then
    
      -- TODO: Why the hell did I do this? It breaks scheduled tasks. I comment it out for now to see where it fails.
      --local task=self:GetTaskCurrent()
      --self:RemoveTask(task)
      --self.taskcurrent=0
      
    end
  
    -- Inject enroute tasks.
    if self.taskenroute and #self.taskenroute>0 then
      if tostring(DCSTask.id)=="ComboTask" then
        for _,task in pairs(self.taskenroute) do
          table.insert(DCSTask.params.tasks, 1, task)
        end
      else
        local tasks=UTILS.DeepCopy(self.taskenroute)
        table.insert(tasks, DCSTask)
        
        DCSTask=self.group.TaskCombo(self, tasks)
      end
    end
  
    -- Set task.
    self.group:SetTask(DCSTask)
    
    -- Debug info.
    local text=string.format("SETTING Task %s", tostring(DCSTask.id))
    if tostring(DCSTask.id)=="ComboTask" then
      for i,task in pairs(DCSTask.params.tasks) do
        text=text..string.format("\n[%d] %s", i, tostring(task.id))
      end
    end
    self:I(self.lid..text)    
  end
  
  return self
end

--- Push DCS task.
-- @param #FLIGHTGROUP self
-- @param #table DCSTask DCS task structure.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:PushTask(DCSTask)

  if self:IsAlive() then
  
    -- Push task.
    self.group:PushTask(DCSTask)
    
    -- Debug info.
    local text=string.format("PUSHING Task %s", tostring(DCSTask.id))
    if tostring(DCSTask.id)=="ComboTask" then
      for i,task in pairs(DCSTask.params.tasks) do
        text=text..string.format("\n[%d] %s", i, tostring(task.id))
      end
    end
    self:I(self.lid..text)    
  end
  
  return self
end

--- Clear DCS tasks.
-- @param #FLIGHTGROUP self
-- @param #table DCSTask DCS task structure.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:ClearTasks()
  if self:IsAlive() then
    self.group:ClearTasks()
    self:I(self.lid..string.format("CLEARING Tasks"))
  end
  return self
end

--- Add a *scheduled* task.
-- @param #OPSGROUP self
-- @param #table task DCS task table structure.
-- @param #string clock Mission time when task is executed. Default in 5 seconds. If argument passed as #number, it defines a relative delay in seconds.
-- @param #string description Brief text describing the task, e.g. "Attack SAM".
-- @param #number prio Priority of the task.
-- @param #number duration Duration before task is cancelled in seconds counted after task started. Default never.
-- @return #OPSGROUP.Task The task structure.
function OPSGROUP:AddTask(task, clock, description, prio, duration)

  local newtask=self:NewTaskScheduled(task, clock, description, prio, duration)

  -- Add to table.
  table.insert(self.taskqueue, newtask)
  
  -- Info.
  self:I(self.lid..string.format("Adding SCHEDULED task %s starting at %s", newtask.description, UTILS.SecondsToClock(newtask.time, true)))
  self:T3({newtask=newtask})

  return newtask
end

--- Create a *scheduled* task.
-- @param #OPSGROUP self
-- @param #table task DCS task table structure.
-- @param #string clock Mission time when task is executed. Default in 5 seconds. If argument passed as #number, it defines a relative delay in seconds.
-- @param #string description Brief text describing the task, e.g. "Attack SAM".
-- @param #number prio Priority of the task.
-- @param #number duration Duration before task is cancelled in seconds counted after task started. Default never.
-- @return #OPSGROUP.Task The task structure.
function OPSGROUP:NewTaskScheduled(task, clock, description, prio, duration)

  -- Increase counter.
  self.taskcounter=self.taskcounter+1

  -- Set time.
  local time=timer.getAbsTime()+5
  if clock then
    if type(clock)=="string" then
      time=UTILS.ClockToSeconds(clock)
    elseif type(clock)=="number" then
      time=timer.getAbsTime()+clock
    end
  end

  -- Task data structure.
  local newtask={} --#OPSGROUP.Task
  newtask.status=OPSGROUP.TaskStatus.SCHEDULED
  newtask.dcstask=task
  newtask.description=description or task.id  
  newtask.prio=prio or 50
  newtask.time=time
  newtask.id=self.taskcounter
  newtask.duration=duration
  newtask.waypoint=-1
  newtask.type=OPSGROUP.TaskType.SCHEDULED
  newtask.stopflag=USERFLAG:New(string.format("%s StopTaskFlag %d", self.groupname, newtask.id))  
  newtask.stopflag:Set(0)

  return newtask
end

--- Add a *waypoint* task.
-- @param #FLIGHTGROUP self
-- @param #table task DCS task table structure.
-- @param #number waypointindex Number of waypoint. Counting starts at one! Default is the as *next* waypoint.
-- @param #string description Brief text describing the task, e.g. "Attack SAM". 
-- @param #number prio Priority of the task. Number between 1 and 100. Default is 50.
-- @param #number duration Duration before task is cancelled in seconds counted after task started. Default never.
-- @return #FLIGHTGROUP.Task The task structure.
function FLIGHTGROUP:AddTaskWaypoint(task, waypointindex, description, prio, duration)

  -- Increase counter.
  self.taskcounter=self.taskcounter+1

  -- Task data structure.
  local newtask={} --#FLIGHTGROUP.Task
  newtask.description=description
  newtask.status=FLIGHTGROUP.TaskStatus.SCHEDULED
  newtask.dcstask=task
  newtask.prio=prio or 50
  newtask.id=self.taskcounter
  newtask.duration=duration
  newtask.time=0
  newtask.waypoint=waypointindex or (self.currentwp and self.currentwp+1 or 2)
  newtask.type=FLIGHTGROUP.TaskType.WAYPOINT
  newtask.stopflag=USERFLAG:New(string.format("%s StopTaskFlag %d", self.groupname, newtask.id))  
  newtask.stopflag:Set(0)

  -- Add to table.
  table.insert(self.taskqueue, newtask)
  
  -- Info.
  self:I(self.lid..string.format("Adding WAYPOINT task %s at WP %d", newtask.description, newtask.waypoint))
  self:T3({newtask=newtask})
  
  -- Update route.
  --self:_CheckFlightDone(1)
  self:__UpdateRoute(-1)

  return newtask
end

--- Add an *enroute* task.
-- @param #FLIGHTGROUP self
-- @param #table task DCS task table structure.
function FLIGHTGROUP:AddTaskEnroute(task)

  if not self.taskenroute then
    self.taskenroute={}
  end
  
  -- Check not to add the same task twice!
  local gotit=false
  for _,Task in pairs(self.taskenroute) do
    if Task.id==task.id then
      gotit=true
      break
    end
  end
  
  if not gotit then
    table.insert(self.taskenroute, task)
  end
  
end

--- Remove task from task queue.
-- @param #FLIGHTGROUP self
-- @param #FLIGHTGROUP.Task Task The task to be removed from the queue.
-- @return #boolean True if task could be removed.
function FLIGHTGROUP:RemoveTask(Task)

  for i=#self.taskqueue,1,-1 do
    local task=self.taskqueue[i] --#FLIGHTGROUP.Task
  
    if task.id==Task.id then
    
      -- Remove task from queue.
      table.remove(self.taskqueue, i)
      
      -- Update route if this is a waypoint task.
      if task.type==FLIGHTGROUP.TaskType.WAYPOINT and task.status==FLIGHTGROUP.TaskStatus.SCHEDULED then
        self:_CheckFlightDone(1)
        --self:__UpdateRoute(-1)
      end
      
      return true
    end  
  end
  
  return false
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Mission Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Add mission to queue.
-- @param #FLIGHTGROUP self
-- @param Ops.Auftrag#AUFTRAG Mission Mission for this group.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:AddMission(Mission)
  
  -- Add flight group to mission.
  Mission:AddFlightGroup(self)
  
  -- Set flight status to SCHEDULED..
  Mission:SetFlightStatus(self, AUFTRAG.FlightStatus.SCHEDULED)
  
  -- Set mission status to SCHEDULED.
  Mission:Scheduled()

  -- Add mission to queue.
  table.insert(self.missionqueue, Mission)
  
  -- Info text.
  local text=string.format("Added %s mission %s starting at %s, stopping at %s", 
  tostring(Mission.type), tostring(Mission.name), UTILS.SecondsToClock(Mission.Tstart, true), Mission.Tstop and UTILS.SecondsToClock(Mission.Tstop, true) or "INF")
  self:I(self.lid..text)
  
  return self
end

--- Remove mission from queue.
-- @param #FLIGHTGROUP self
-- @param Ops.Auftrag#AUFTRAG Mission Mission to be removed.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:RemoveMission(Mission)

  for i,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG
    
    if mission.auftragsnummer==Mission.auftragsnummer then
    
      -- Remove mission waypoint task.
      local Task=Mission:GetFlightWaypointTask(self)
      
      if Task then
        self:RemoveTask(Task)
      end
      
      -- Remove mission from queue.
      table.remove(self.missionqueue, i)
      
      return self
    end
    
  end

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Events
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after "PassingWaypoint" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number n Waypoint passed.
-- @param #number N Total number of waypoints.
function OPSGROUP:onafterPassingWaypoint(From, Event, To, n, N)
  self:I(self.lid..string.format("Passed waypoint %d of %d", n, N))
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Routing
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set DCS task. Enroute tasks are injected automatically.
-- @param #OPSGROUP self
-- @param #table DCSTask DCS task structure.
-- @return #OPSGROUP self
function OPSGROUP:SetTask(DCSTask)

  if self:IsAlive() then
  
    -- Set task.
    self.group:SetTask(DCSTask)
    
    -- Debug info.
    local text=string.format("SETTING Task %s", tostring(DCSTask.id))
    if tostring(DCSTask.id)=="ComboTask" then
      for i,task in pairs(DCSTask.params.tasks) do
        text=text..string.format("\n[%d] %s", i, tostring(task.id))
      end
    end
    self:I(self.lid..text)    
  end
  
  return self
end

--- Check if flight is alive.
-- @param #OPSGROUP self
-- @return #boolean *true* if group is exists and is activated, *false* if group is exist but is NOT activated. *nil* otherwise, e.g. the GROUP object is *nil* or the group is not spawned yet.
function OPSGROUP:IsAlive()

  if self.group then
    return self.group:IsAlive()
  end

  return nil
end

--- Route group along waypoints. Enroute tasks are also applied.
-- @param #OPSGROUP self
-- @param #table waypoints Table of waypoints.
-- @return #OPSGROUP self
function OPSGROUP:Route(waypoints)

  if self:IsAlive() then

    -- DCS task combo.
    local Tasks={}
    
    -- Route (Mission) task.
    local TaskRoute=self.group:TaskRoute(waypoints)
    table.insert(Tasks, TaskRoute)
    
    -- TaskCombo of enroute and mission tasks.
    local TaskCombo=self.group:TaskCombo(Tasks)
        
    -- Set tasks.
    if #Tasks>1 then
      self:SetTask(TaskCombo)
    else
      self:SetTask(TaskRoute)
    end
    
  else
    self:E(self.lid.."ERROR: Group is not alive!")
  end
  
  return self
end

--- Initialize Mission Editor waypoints.
-- @param #OPSGROUP self
-- @param #table waypoints Table of waypoints. Default is from group template.
-- @return #OPSGROUP self
function OPSGROUP:InitWaypoints(waypoints)

  -- Template waypoints.
  self.waypoints0=self.group:GetTemplateRoutePoints()

  -- Waypoints of group as defined in the ME.
  self.waypoints=waypoints or UTILS.DeepCopy(self.waypoints0)
  
  -- Debug info.
  self:T(self.lid..string.format("Initializing %d waypoints", #self.waypoints))
  
  -- Update route.
  if #self.waypoints>0 then
  
    -- Check if only 1 wp?
    if #self.waypoints==1 then
      self.passedfinalwp=true
    end
    
    -- Update route (when airborne).
    self:__UpdateRoute(-1)
  end

  return self
end

--- Initialize Mission Editor waypoints.
-- @param #OPSGROUP self
function OPSGROUP:_UpdateWaypointTasks()

  local waypoints=self.waypoints
  local nwaypoints=#waypoints

  for i,wp in pairs(waypoints) do
    
    if i>self.currentwp or nwaypoints==1 then
    
      -- Debug info.
      self:T2(self.lid..string.format("Updating waypoint task for waypoint %d/%d. Last waypoint passed %d.", i, nwaypoints, self.currentwp))
  
      -- Tasks of this waypoint
      local taskswp={}
    
      -- At each waypoint report passing.
      local TaskPassingWaypoint=self.group:TaskFunction("OPSGROUP._PassingWaypoint", self, i)      
      table.insert(taskswp, TaskPassingWaypoint)      
          
      -- Waypoint task combo.
      wp.task=self.group:TaskCombo(taskswp)
      
    end
  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Global Task Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Function called when a group is passing a waypoint.
--@param Wrapper.Group#GROUP group Group that passed the waypoint
--@param #OPSGROUP opsgroup Ops group object.
--@param #number i Waypoint number that has been reached.
function OPSGROUP._PassingWaypoint(group, opsgroup, i)

  local final=#opsgroup.waypoints or 1

  -- Debug message.
  local text=string.format("Group passing waypoint %d of %d", i, final)
  opsgroup:T3(opsgroup.lid..text)

  -- Set current waypoint.
  opsgroup.currentwp=i

  -- Trigger PassingWaypoint event.
  opsgroup:PassingWaypoint(i, final)

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
