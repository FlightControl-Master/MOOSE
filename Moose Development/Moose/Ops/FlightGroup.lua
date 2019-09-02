--- **Ops** - (R2.5) - AI Flight Group for Ops.
--
-- **Main Features:**
--
--    * Monitor flight status of elements or entire group.
--    * Monitor fuel and ammo status.
--    * Sophisicated task queueing system.
--
--
-- ===
--
-- ### Author: **funkyfranky**
-- @module Ops.FlightGroup
-- @image OPS_FlightGroup.png


--- FLIGHTGROUP class.
-- @type FLIGHTGROUP
-- @field #string ClassName Name of the class.
-- @field #boolean Debug Debug mode. Messages to all about status.
-- @field #string sid Class id string for output to DCS log file.
-- @field #string groupname Name of flight group.
-- @field Wrapper.Group#GROUP flightgroup Flight group object.
-- @field #string type Aircraft type of flight group.
-- @field #table element Table of elements, i.e. units of the group.
-- @field #table waypoints Table of waypoints.
-- @field #table coordinates Table of waypoint coordinates.
-- @field #table taskqueue Queue of tasks.
-- @field #number taskcounter Running number of task ids.
-- @field #number taskcurrent ID of current task. If 0, there is no current task assigned.
-- @field Core.Set#SET_UNIT detectedunits Set of detected units.
-- @field Wrapper.Airbase#AIRBASE homebase The home base of the flight group.
-- @field Wrapper.Airbase#AIRBASE destination The destination base of the flight group.
-- @field #boolean fuellow Fuel low switch.
-- @field #number fuellowthresh Low fuel threshold in percent.
-- @field #boolean fuellowrtb RTB on low fuel switch.
-- @field #boolean fuelcritical Fuel critical switch.
-- @field #number fuelcriticalthresh Critical fuel threshold in percent.
-- @field #boolean fuelcriticalrtb RTB on critical fuel switch. 
-- @extends Core.Fsm#FSM

--- Be surprised!
--
-- ===
--
-- ![Banner Image](..\Presentations\CarrierAirWing\FLIGHTGROUP_Main.jpg)
--
-- # The FLIGHTGROUP Concept
--
--
--
-- @field #FLIGHTGROUP
FLIGHTGROUP = {
  ClassName      = "FLIGHTGROUP",
  Debug              =   nil,
  sid                =   nil,
  groupname          =   nil,
  flightgroup        =   nil,
  grouptemplate      =   nil,
  type               =   nil,
  waypoints          =    {},
  coordinates        =    {},
  element            =    {},
  taskqueue          =    {},
  taskcounter        =   nil,
  taskcurrent        =   nil,
  detectedunits      =    {},
  homebase           =   nil,
  destination        =   nil,
  speedmax           =   nil,
  range              =   nil,
  altmax             =   nil,
  fuellow            = false,
  fuellowthresh      =   nil,
  fuellowrtb         =   nil,
  fuelcritical       =   nil,  
  fuelcriticalthresh =   nil,
  fuelcriticalrtb    = false,
}


--- Status of flight group element.
-- @type FLIGHTGROUP.ElementStatus
-- @field #string SPAWNED Element was spawned into the world.
-- @field #string PARKING Element is parking after spawned on ramp.
-- @field #string TAXIING Element is taxiing after engine startup.
-- @field #string AIRBORNE Element is airborne after take off.
-- @field #string LANDED Element landed and is taxiing to its parking spot.
-- @field #string ARRIVED Element arrived at its parking spot and shut down its engines.
-- @field #string DEAD Element is dead after it crashed, pilot ejected or pilot dead events.
FLIGHTGROUP.ElementStatus={
  SPAWNED="spawned",
  PARKING="parking",
  TAXIING="taxiing",
  AIRBORNE="airborne",
  LANDED="landed",
  ARRIVED="arrived",
  DEAD="dead",
}


--- Flight group element.
-- @type FLIGHTGROUP.Element
-- @field #string name Name of the element.
-- @field #number modex Tail number.
-- @field #boolean ai If true, element is AI.
-- @field #string skill Skill level.
-- @field Wrapper.Unit#UNIT unit Element unit object.
-- @field Wrapper.Group#GROUP group Group object of the element.
-- @field #string status Status, i.e. born, parking, taxiing. See @{#FLIGHTGROUP.ElementStatus}.

--- Flight group tasks.
-- @type FLIGHTGROUP.Mission
-- @param #string INTERCEPT Intercept task.
-- @param #string CAP Combat Air Patrol task.s
-- @param #string BAI Battlefield Air Interdiction task.
-- @param #string SEAD Suppression/destruction of enemy air defences.
-- @param #string STRIKE Strike task.
-- @param #string AWACS AWACS task.
-- @param #string TANKER Tanker task.
FLIGHTGROUP.Mission={
  INTERCEPT="Intercept",
  CAP="CAP",
  BAI="BAI",
  SEAD="SEAD",
  STRIKE="Strike",
  CAS="CAS",
  AWACS="AWACS",
  TANKER="Tanker",
}

--- Flight group task status.
-- @type FLIGHTGROUP.TaskStatus
-- @field #string SCHEDULED Task is sheduled.
-- @field #string EXECUTING Task is being executed.
-- @field #string ACCOMPLISHED Task is accomplished.
-- @field #string WAYPOINT Task is executed at a waypoint.
FLIGHTGROUP.TaskStatus={
  SCHEDULED="scheduled",
  EXECUTING="executing",
  ACCOMPLISHED="accomplished",
}

--- Flight group task status.
-- @type FLIGHTGROUP.TaskType
-- @field #string SCHEDULED Task is sheduled.
-- @field #string EXECUTING Task is being executed.
FLIGHTGROUP.TaskType={
  SCHEDULED="scheduled",
  WAYPOINT="waypoint",
}


--- Flight group tasks.
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


--- FLIGHTGROUP class version.
-- @field #string version
FLIGHTGROUP.version="0.0.8"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Add tasks.
-- TODO: Add EPLRS, TACAN.
-- TODO: Get ammo.
-- TODO: Get pylons.
-- TODO: Fuel threshhold ==> RTB.
-- TODO: ROE, Afterburner restrict
-- TODO: Respawn? With correct loadout, fuelstate.
-- TODO: Waypoints, read, add, insert, detour.
-- TODO: Damage?
-- TODO: shot events?
-- TODO:

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new FLIGHTGROUP object and start the FSM.
-- @param #FLIGHTGROUP self
-- @param #string groupname Name of the group.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:New(groupname)

  -- Inherit everything from WAREHOUSE class.
  local self=BASE:Inherit(self, FSM:New()) -- #FLIGHTGROUP

  --self.flightgroup=AIGroup
  self.groupname=tostring(groupname)

  -- Set some string id for output to DCS.log file.
  self.sid=string.format("FLIGHTGROUP %s | ", self.groupname)

  -- Start State.
  self:SetStartState("Stopped")

  -- Init set of detected units.
  self.detectedunits=SET_UNIT:New()
  
  -- Defaults
  self:SetFuelLowThreshold()
  self:SetFuelCriticalThreshold()


  -- Add FSM transitions.
  --                 From State  -->   Event      -->     To State
  self:AddTransition("Stopped",       "Start",            "Running")     -- Start FSM.

  self:AddTransition("*",             "FlightStatus",     "*")           -- FLIGHTGROUP status update.
  self:AddTransition("*",             "QueueUpdate",      "*")           -- Update task queue.
  
  
  self:AddTransition("*",             "DetectedUnit",      "*")           -- Add a newly detected unit to the detected units set.
  self:AddTransition("*",             "DetectedUnitNew",   "*")           -- Add a newly detected unit to the detected units set.
  self:AddTransition("*",             "DetectedUnitKnown", "*")           -- Add a newly detected unit to the detected units set.
  self:AddTransition("*",             "DetectedUnitLost",  "*")           -- Group lost a detected target.

  self:AddTransition("*",             "RTB",               "Returning")   -- Group is returning to base.
  self:AddTransition("*",             "Orbit",             "Orbiting")    -- Group is holding position.

  self:AddTransition("*",             "PassingWaypoint",   "*")           -- Group passed a waypoint.
  
  self:AddTransition("*",             "FuelLow",           "*")          -- Fuel state of group is low. Default ~25%.
  self:AddTransition("*",             "FuelCritical",      "*")          -- Fuel state of group is critical. Default ~10%.
  
  self:AddTransition("*",             "OutOfAmmo",         "*")          -- Group is completely out of ammo.
  self:AddTransition("*",             "OutOfGuns",         "*")          -- Group is out of gun shells.
  self:AddTransition("*",             "OutOfRockets",      "*")          -- Group is out of rockets.
  self:AddTransition("*",             "OutOfBombs",        "*")          -- Group is out of bombs.
  self:AddTransition("*",             "OutOfMissiles",     "*")          -- Group is out of missiles.

  self:AddTransition("*",             "TaskExecute",      "*")           -- Group will execute a task.
  self:AddTransition("*",             "TaskDone",         "*")           -- Group finished a task.
  self:AddTransition("*",             "TaskCancel",       "*")           -- Cancel current task.
  self:AddTransition("*",             "TaskPause",        "*")           -- Pause current task.

  self:AddTransition("*",             "ElementSpawned",   "*")           -- An element was spawned.
  self:AddTransition("*",             "ElementParking",   "*")           -- An element was spawned.
  self:AddTransition("*",             "ElementTaxiing",   "*")           -- An element spooled up the engines.
  self:AddTransition("*",             "ElementAirborne",  "*")           -- An element took off.
  self:AddTransition("*",             "ElementLanded",    "*")           -- An element landed.
  self:AddTransition("*",             "ElementArrived",   "*")           -- An element arrived.
  self:AddTransition("*",             "ElementDead",      "*")           -- An element crashed, ejected, or pilot dead.

  self:AddTransition("*",             "ElementOutOfAmmo", "*")           -- An element is completely out of ammo.

  self:AddTransition("*",             "FlightSpawned",    "Spawned")     -- The whole flight group was spawned.
  self:AddTransition("*",             "FlightParking",    "Parking")     -- The whole flight group is parking.
  self:AddTransition("*",             "FlightTaxiing",    "Taxiing")     -- The whole flight group is taxiing.
  self:AddTransition("*",             "FlightAirborne",   "Airborne")    -- The whole flight group is airborne.
  self:AddTransition("*",             "FlightLanded",     "Landed")      -- The whole flight group has landed.
  self:AddTransition("*",             "FlightArrived",    "Arrived")     -- The whole flight group has arrived.
  self:AddTransition("*",             "FlightDead",       "Dead")        -- The whole flight group is dead.

  ------------------------
  --- Pseudo Functions ---
  ------------------------

  --- Triggers the FSM event "Start". Starts the FLIGHTGROUP. Initializes parameters and starts event handlers.
  -- @function [parent=#FLIGHTGROUP] Start
  -- @param #FLIGHTGROUP self

  --- Triggers the FSM event "Start" after a delay. Starts the FLIGHTGROUP. Initializes parameters and starts event handlers.
  -- @function [parent=#FLIGHTGROUP] __Start
  -- @param #FLIGHTGROUP self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Stop". Stops the FLIGHTGROUP and all its event handlers.
  -- @param #FLIGHTGROUP self

  --- Triggers the FSM event "Stop" after a delay. Stops the FLIGHTGROUP and all its event handlers.
  -- @function [parent=#FLIGHTGROUP] __Stop
  -- @param #FLIGHTGROUP self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "FlightStatus".
  -- @function [parent=#FLIGHTGROUP] FlightStatus
  -- @param #FLIGHTGROUP self

  --- Triggers the FSM event "SkipperStatus" after a delay.
  -- @function [parent=#FLIGHTGROUP] __FlightStatus
  -- @param #FLIGHTGROUP self
  -- @param #number delay Delay in seconds.


  -- Debug trace.
  if false then
    self.Debug=true
    BASE:TraceOnOff(true)
    BASE:TraceClass(self.ClassName)
    BASE:TraceLevel(1)
  end

  -- Check if the group is already alive and if so, add its elements.
  -- TODO: move this to start?
  local group=GROUP:FindByName(groupname)
  if group and group:IsAlive() then
    self.flightgroup=group
    local units=group:GetUnits()
    for _,_unit in pairs(units) do
      local unit=_unit --Wrapper.Unit#UNIT
      local element=self:AddElementByName(unit:GetName())

      -- Trigger Spawned event. Delay a bit to start
      self:__ElementSpawned(0.1, element)

    end
  end

  self.taskcurrent=0
  self.taskcounter=0

  -- Autostart.
  self:Start()

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--- Add scheduled task.
-- @param #FLIGHTGROUP self
-- @param #string description Brief text describing the task, e.g. "Attack SAM".
-- @param #table task DCS task table stucture.
-- @param #number prio Priority of the task.
-- @param #string clock Mission time when task is executed. Default in 5 seconds. If argument passed as #number, it defines a relative delay in seconds.
-- @param #number duration Duration before task is cancelled in seconds counted after task started. Default never.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:AddTask(description, task, prio, clock, duration)

  -- Increase coutner.
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
  local newtask={} --#FLIGHTGROUP.Task
  newtask.description=description
  newtask.status=FLIGHTGROUP.TaskStatus.SCHEDULED
  newtask.dcstask=task
  newtask.prio=prio or 50
  newtask.time=time
  newtask.id=self.taskcounter
  newtask.duration=duration
  newtask.waypoint=-1
  newtask.type=FLIGHTGROUP.TaskType.SCHEDULED

  self:T2({newtask=newtask})

  -- Add to table.
  table.insert(self.taskqueue, newtask)

  return self
end

--- Add waypoint task.
-- @param #FLIGHTGROUP self
-- @param #string description Brief text describing the task, e.g. "Attack SAM".
-- @param #table task DCS task table stucture.
-- @param #number waypointindex Number of waypoint. Counting starts at one! 
-- @param #number prio Priority of the task.
-- @param #number duration Duration before task is cancelled in seconds counted after task started. Default never.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:AddTaskWaypoint(description, task, waypointindex, prio, duration)

  -- Increase coutner.
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
  newtask.waypoint=waypointindex
  newtask.type=FLIGHTGROUP.TaskType.WAYPOINT

  self:T2({newtask=newtask})

  -- Add to table.
  table.insert(self.taskqueue, newtask)

  return self
end

--- Set low fuel threshold. Triggers event "FuelLow" and calls event function "OnAfterFuelLow".
-- @param #FLIGHTGROUP self
-- @param #number threshold Fuel threshold in percent. Default 25 %.
-- @param #boolean rtb If true, RTB on fuel low event.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:SetFuelLowThreshold(threshold, rtb)
  self.fuellow=false
  self.fuellowthresh=threshold or 25
  self.fuellowrtb=rtb
  return self
end

--- Set fuel critical threshold. Triggers event "FuelCritical" and event function "OnAfterFuelCritical".
-- @param #FLIGHTGROUP self
-- @param #number threshold Fuel threshold in percent. Default 10 %.
-- @param #boolean rtb If true, RTB on fuel critical event.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:SetFuelCriticalThreshold(threshold, rtb)
  self.fuelcritical=false
  self.fuelcriticalthresh=threshold or 10
  self.fuelcriticalrtb=rtb
  return self
end

--- Get set of decteded units.
-- @param #FLIGHTGROUP self
-- @return Core.Set#SET_UNIT Set of detected units.
function FLIGHTGROUP:GetDetectedUnits()
  return self.detectedunits
end

--- Get MOOSE group object.
-- @param #FLIGHTGROUP self
-- @return Wrapper.Group#GROUP Moose group object.
function FLIGHTGROUP:GetGroup()
  return self.flightgroup
end

--- Check if flight is airborne.
-- @param #FLIGHTGROUP self
-- @return #boolean
function FLIGHTGROUP:IsSpawned()
  return self:Is("Spawned")
end

--- Check if flight is parking.
-- @param #FLIGHTGROUP self
-- @return #boolean
function FLIGHTGROUP:IsParking()
  return self:Is("Parking")
end

--- Check if flight is parking.
-- @param #FLIGHTGROUP self
-- @return #boolean
function FLIGHTGROUP:IsTaxiing()
  return self:Is("Taxiing")
end

--- Check if flight is airborne.
-- @param #FLIGHTGROUP self
-- @return #boolean
function FLIGHTGROUP:IsAirborne()
  return self:Is("Airborne")
end

--- Check if flight is airborne.
-- @param #FLIGHTGROUP self
-- @return #boolean
function FLIGHTGROUP:IsLanded()
  return self:Is("Landed")
end

--- Check if flight is arrived.
-- @param #FLIGHTGROUP self
-- @return #boolean
function FLIGHTGROUP:IsArrived()
  return self:Is("Arrived")
end

--- Check if flight is dead.
-- @param #FLIGHTGROUP self
-- @return #boolean
function FLIGHTGROUP:IsDead()
  return self:Is("Dead")
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Start & Status
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--- On after Start event. Starts the FLIGHTGROUP FSM and event handlers.
-- @param #FLIGHTGROUP self
-- @param Wrapper.Group#GROUP Group Flight group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterStart(From, Event, To)

  -- Short info.
  local text=string.format("Starting flight group %s.", self.groupname)
  self:I(self.sid..text)

  -- Handle events:
  self:HandleEvent(EVENTS.Birth,          self.OnEventBirth)
  self:HandleEvent(EVENTS.EngineStartup,  self.OnEventEngineStartup)
  self:HandleEvent(EVENTS.Takeoff,        self.OnEventTakeOff)
  self:HandleEvent(EVENTS.Land,           self.OnEventLanding)
  self:HandleEvent(EVENTS.EngineShutdown, self.OnEventEngineShutdown)
  self:HandleEvent(EVENTS.PilotDead,      self.OnEventPilotDead)
  self:HandleEvent(EVENTS.Ejection,       self.OnEventEjection)
  self:HandleEvent(EVENTS.Crash,          self.OnEventCrash)

  self.taskcounter=0

  -- Start the status monitoring.
  self:__FlightStatus(-1)
end

--- On after "FlightSpawned" event. Sets the template, initializes the waypoints.
-- @param #FLIGHTGROUP self
-- @param Wrapper.Group#GROUP Group Flight group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Group#GROUP Group The group object.
function FLIGHTGROUP:onafterFlightSpawned(From, Event, To, Group)

  -- Get template of group.
  self.template=self.flightgroup:GetTemplate()

  -- Init waypoints.
  self:_InitWaypoints()
  
  -- Route flight group but now with passing waypoint tasks.
  self.flightgroup:Route(self.waypoints)
end

--- On after "FlightAirborne" event.
-- @param #FLIGHTGROUP self
-- @param Wrapper.Group#GROUP Group Flight group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Group#GROUP Group The group object.
function FLIGHTGROUP:onafterFlightAirborne(From, Event, To, Group)

  -- Update
  self:__QueueUpdate(-1)

end

--- On after "FlightStatus" event.
-- @param #FLIGHTGROUP self
-- @param Wrapper.Group#GROUP Group Flight group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterFlightStatus(From, Event, To)

  -- FSM state.
  local fsmstate=self:GetState()
  
  -- Check if group has detected any units.
  self:_CheckDetectedUnits()

  -- Short info.
  local text=string.format("Flight status %s [%d/%d]. Task=%d/%d. Waypoint=%d/%d. Detected=%d", fsmstate, #self.element, #self.element, self.taskcurrent, #self.taskqueue, self.currentwp or 0, #self.waypoints or 0, self.detectedunits:Count())
  self:I(self.sid..text)

  -- Element status.
  text="Elements:"
  local fuelmin=999999
  for i,_element in pairs(self.element) do
    local element=_element --#FLIGHTGROUP.Element
    local name=element.name
    local status=element.status
    local unit=element.unit
    local fuel=unit:GetFuel() or 0
    local life=unit:GetLifeRelative() or 0
    
    if fuel*100<fuelmin then
      fuelmin=fuel*100
    end

    -- Check if element is not dead and we missed an event.
    if life<0 and element.status~=FLIGHTGROUP.ElementStatus.DEAD then
      self:ElementDead(element)
    end
    
    local nammo=0
    local nshells=0
    local nrockets=0
    local nbombs=0
    local nmissiles=0
    if element.status~=FLIGHTGROUP.ElementStatus.DEAD then
      nammo, nshells, nrockets, nbombs, nmissiles=self:GetAmmoElement(element)
    end

    -- Output text for element.
    text=text..string.format("\n[%d] %s: status=%s, fuel=%.1f, life=%.1f, shells=%d, rockets=%d, bombs=%d, missiles=%d", i, name, status, fuel*100, life*100, nshells, nrockets, nbombs, nmissiles)
  end
  if #self.element==0 then
    text=text.." none!"
  end
  self:I(self.sid..text)
  
  -- Low fuel?
  if fuelmin<self.fuellowthresh and not self.fuellow then
    self:FuelLow()
  end
  
  -- Critical fuel?
  if fuelmin<self.fuelcriticalthresh and not self.fuelcritical then
    self:FuelCritical()
  end  

  -- Task queue.
  text=string.format("Tasks #%d", #self.taskqueue)
  for i,_task in pairs(self.taskqueue) do
    local task=_task --#FLIGHTGROUP.Task
    local name=task.description
    local status=task.status
    local clock=UTILS.SecondsToClock(task.time)
    local eta=task.time-timer.getAbsTime()
    local started=UTILS.SecondsToClock(task.timestamp or 0)
    local duration=-1
    if task.duration then
      duration=task.duration
      if task.timestamp then
        duration=task.duration-(timer.getAbsTime()-task.timestamp)
      else
        duration=task.duration
      end
    end
    -- Output text for element.
    text=text..string.format("\n[%d] %s: status=%s, scheduled=%s (%d sec), started=%s, duration=%d", i, name, status, clock, eta, started, duration)
  end
  self:I(self.sid..text)


  -- Next check in ~30 seconds.
  self:__FlightStatus(-30)
end

--- On after "FlightStatus" event.
-- @param #FLIGHTGROUP self
-- @param Wrapper.Group#GROUP Group Flight group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterQueueUpdate(From, Event, To)

  -- Check no current task.
  if self.taskcurrent<=0 then

    -- Get task from queue.
    local task=self:GetTask()

    -- Execute task if any.
    if task then
      self:TaskExecute(task)
    end
    
  else
  
    -- Get current task.
    local task=self:GetTaskCurrent()
    
    -- Check if task has a defined duration.
    if task and task.duration and task.timestamp then
          
      -- Check if max task duration is over.
      local cancel=timer.getAbsTime()>task.timestamp+task.duration
      
      --self:E(string.format("FF timestap=%d , duration=%d, time=%d, stamp+duration=%s < time = %s", task.timestamp, task.duration, timer.getAbsTime(), task.timestamp+task.duration, tostring(cancel)))
      
      -- Cancel task if task is running longer than duration.
      if cancel then
        self:TaskCancel()
      end
    end

  end

  -- Update queue every ~5 sec.
  self:__QueueUpdate(-5)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Events
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Flightgroup event function, handling the birth of a unit.
-- @param #FLIGHTGROUP self
-- @param Core.Event#EVENTDATA EventData Event data.
function FLIGHTGROUP:OnEventBirth(EventData)

  -- Check that this is the right group.
  if EventData and EventData.IniGroup and EventData.IniUnit and EventData.IniGroupName and EventData.IniGroupName==self.groupname then
    local unit=EventData.IniUnit
    local group=EventData.IniGroup
    local unitname=EventData.IniUnitName

    self.flightgroup=self.flightgroup or EventData.IniGroup

    if not self:_IsElement(unitname) then
      local element=self:AddElementByName(unitname)
      self:ElementSpawned(element)
    end

  end

end

--- Flightgroup event function handling the crash of a unit.
-- @param #FLIGHTGROUP self
-- @param Core.Event#EVENTDATA EventData Event data.
function FLIGHTGROUP:OnEventEngineStartup(EventData)

  -- Check that this is the right group.
  if EventData and EventData.IniGroup and EventData.IniUnit and EventData.IniGroupName and EventData.IniGroupName==self.groupname then
    local unit=EventData.IniUnit
    local group=EventData.IniGroup
    local unitname=EventData.IniUnitName

    -- Get element.
    local element=self:GetElementByName(unitname)

    if element then
      self:I(self.sid..string.format("Element %s started engines ==> taxiing", element.name))
      self:ElementTaxiing(element)
    end

  end

end

--- Flightgroup event function handling the crash of a unit.
-- @param #FLIGHTGROUP self
-- @param Core.Event#EVENTDATA EventData Event data.
function FLIGHTGROUP:OnEventTakeOff(EventData)

  -- Check that this is the right group.
  if EventData and EventData.IniGroup and EventData.IniUnit and EventData.IniGroupName and EventData.IniGroupName==self.groupname then
    local unit=EventData.IniUnit
    local group=EventData.IniGroup
    local unitname=EventData.IniUnitName

    -- Get element.
    local element=self:GetElementByName(unitname)

    if element then
      self:I(self.sid..string.format("EVENT: Element %s took off ==> airborne", element.name))
      self:ElementAirborne(element)
    end

  end

end

--- Flightgroup event function handling the crash of a unit.
-- @param #FLIGHTGROUP self
-- @param Core.Event#EVENTDATA EventData Event data.
function FLIGHTGROUP:OnEventLanding(EventData)

  -- Check that this is the right group.
  if EventData and EventData.IniGroup and EventData.IniUnit and EventData.IniGroupName and EventData.IniGroupName==self.groupname then
    local unit=EventData.IniUnit
    local group=EventData.IniGroup
    local unitname=EventData.IniUnitName

    -- Get element.
    local element=self:GetElementByName(unitname)

    local airbase=EventData.Place

    local airbasename="unknown"
    if airbase then
      airbasename=tostring(airbase:GetName())
    end

    if element then
      self:I(self.sid..string.format("EVENT: Element %s landed at %s ==> landed", element.name, airbasename))
      self:ElementLanded(element, airbase)
    end

  end

end

--- Flightgroup event function handling the crash of a unit.
-- @param #FLIGHTGROUP self
-- @param Core.Event#EVENTDATA EventData Event data.
function FLIGHTGROUP:OnEventEngineShutdown(EventData)

  -- Check that this is the right group.
  if EventData and EventData.IniGroup and EventData.IniUnit and EventData.IniGroupName and EventData.IniGroupName==self.groupname then
    local unit=EventData.IniUnit
    local group=EventData.IniGroup
    local unitname=EventData.IniUnitName

    -- Get element.
    local element=self:GetElementByName(unitname)

    if element then
    
      if element.unit and element.unit:IsAlive() then
    
        local coord=unit:GetCoordinate()
        
        local airbase=coord:GetClosestAirbase()
        
        local _,_,dist,parking=coord:GetClosestParkingSpot(airbase)
        
        if dist and dist<10 and unit:InAir()==false then
          self:ElementArrived(element, airbase, parking)
          self:I(self.sid..string.format("Element %s shut down engines ==> arrived", element.name))
        else
          self:I(self.sid..string.format("Element %s shut down engines (in air) ==> dead", element.name))
          self:ElementDead(element)
        end
        
      else
      
        self:I(self.sid..string.format("Element %s shut down engines (bug is not alive) ==> dead", element.name))
        self:ElementDead(element)    
          
      end
      
    else
    end

  end

end


--- Flightgroup event function handling the crash of a unit.
-- @param #FLIGHTGROUP self
-- @param Core.Event#EVENTDATA EventData Event data.
function FLIGHTGROUP:OnEventCrash(EventData)

  -- Check that this is the right group.
  if EventData and EventData.IniGroup and EventData.IniUnit and EventData.IniGroupName and EventData.IniGroupName==self.groupname then
    local unit=EventData.IniUnit
    local group=EventData.IniGroup
    local unitname=EventData.IniUnitName

    -- Get element.
    local element=self:GetElementByName(unitname)

    if element then
      self:I(self.sid..string.format("Element %s crashed ==> dead", element.name))
      self:ElementDead(element)
    end

  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after "ElementSpawned" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #FLIGHTGROUP.Element Element The flight group element.
function FLIGHTGROUP:onafterElementSpawned(From, Event, To, Element)
  self:I(self.sid..string.format("Element spawned %s.", Element.name))

  -- Set element status.
  self:_UpdateStatus(Element, FLIGHTGROUP.ElementStatus.SPAWNED)

  if Element.unit:InAir() then
    self:ElementAirborne(Element)
  else
    self:ElementParking(Element)
  end
end

--- On after "ElementParking" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #FLIGHTGROUP.Element Element The flight group element.
function FLIGHTGROUP:onafterElementParking(From, Event, To, Element)
  self:I(self.sid..string.format("Element parking %s.", Element.name))

  -- Set element status.
  self:_UpdateStatus(Element, FLIGHTGROUP.ElementStatus.PARKING)
end

--- On after "ElementTaxiing" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #FLIGHTGROUP.Element Element The flight group element.
function FLIGHTGROUP:onafterElementTaxiing(From, Event, To, Element)
  self:I(self.sid..string.format("Element taxiing %s.", Element.name))

  -- Set element status.
  self:_UpdateStatus(Element, FLIGHTGROUP.ElementStatus.TAXIING)
end

--- On after "ElementAirborne" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #FLIGHTGROUP.Element Element The flight group element.
function FLIGHTGROUP:onafterElementAirborne(From, Event, To, Element)
  self:I(self.sid..string.format("Element airborne %s.", Element.name))

  -- Set element status.
  self:_UpdateStatus(Element, FLIGHTGROUP.ElementStatus.AIRBORNE)
end

--- On after "ElementLanded" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #FLIGHTGROUP.Element Element The flight group element.
function FLIGHTGROUP:onafterElementLanded(From, Event, To, Element)
  self:I(self.sid..string.format("Element landed %s.", Element.name))

  -- Set element status.
  self:_UpdateStatus(Element, FLIGHTGROUP.ElementStatus.LANDED)
end

--- On after "ElementArrived" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #FLIGHTGROUP.Element Element The flight group element.
function FLIGHTGROUP:onafterElementArrived(From, Event, To, Element)
  self:I(self.sid..string.format("Element arrived %s.", Element.name))

  -- Set element status.
  self:_UpdateStatus(Element, FLIGHTGROUP.ElementStatus.ARRIVED)
end


--- On after "PassingWaypoint" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number n Waypoint number passed.
-- @param #number N Final waypoint number.
function FLIGHTGROUP:onafterPassingWaypoint(From, Event, To, n, N)
  local text=string.format("Group %s passed waypoint %d/%d", self.groupname, n, N)
  self:I(self.sid..text)
  MESSAGE:New(text, 30, "DEBUG"):ToAllIf(self.Debug)
  
end

--- On after "FuelLow" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterFuelLow(From, Event, To)

  -- Debug message.
  local text=string.format("Low fuel for flight group %s", self.groupname)
  MESSAGE:New(text, 10, "DEBUG"):ToAllIf(self.Debug)
  self:I(self.sid..text)
  
  -- Set switch to true.
  self.fuellow=true

  -- Route helo back home. It is respawned! But this is the only way to ensure that it actually lands at the airbase.
  local airbase=self.destination or self.homebase
  
  if airbase and self.fuellowrtb then
    self:RTB(airbase)
  end
end

--- On after "FuelCritical" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterFuelCritical(From, Event, To)

  -- Debug message.
  local text=string.format("Critical fuel for flight group %s", self.groupname)
  MESSAGE:New(text, 10, "DEBUG"):ToAllIf(self.Debug)
  self:I(self.sid..text)
  
  -- Set switch to true.
  self.fuelcritical=true

  -- Route helo back home. It is respawned! But this is the only way to ensure that it actually lands at the airbase.
  local airbase=self.destination or self.homebase
  
  if airbase and self.fuelcriticalrtb then
    self:RTB(airbase)
  end
end


--- On after "RTB" event. Send flightgroup back to base.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Airbase#AIRBASE airbase The base to return to.
function FLIGHTGROUP:onafterRTB(From, Event, To, airbase)

  -- Debug message.
  local text=string.format("Flight group returning to airbase %s.", airbase:GetName())
  MESSAGE:New(text, 10, "DEBUG"):ToAllIf(self.Debug)
  self:I(self.sid..text)

  -- Route helo back home. It is respawned! But this is the only way to ensure that it actually lands at the airbase.
  self:RouteRTB(airbase)
end

--- On after "Orbit" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Point#COORDINATE Coord Coordinate where to orbit.
-- @param #number Altitude Altitude in meters.
-- @param #number Speed Speed in km/h.
function FLIGHTGROUP:onafterOrbit(From, Event, To, Coord, Altitude, Speed)

  -- Debug message.
  local text=string.format("Flight group set to orbit at altitude %d m and speed %.1f km/h", Altitude, Speed)
  MESSAGE:New(text, 10, "DEBUG"):ToAllIf(self.Debug)
  self:I(self.sid..text)
  
  local TaskOrbit=self.flightgroup:TaskOrbit(Coord, Altitude, UTILS.KmphToMps(Speed))

  self.flightgroup:SetTask(TaskOrbit)
end

--- On after TaskExecute event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #FLIGHTGROUP.Task Task The task.
function FLIGHTGROUP:onafterTaskExecute(From, Event, To, Task)

  -- Debug message.
  local text=string.format("Task %s ID=%d execute.", Task.description, Task.id)
  MESSAGE:New(text, 10, "DEBUG"):ToAllIf(self.Debug)
  self:I(self.sid..text)

  -- Set current task.
  self.taskcurrent=Task.id
  
  -- Set time stamp.
  Task.timestamp=timer.getAbsTime()

  -- Task status executing.
  Task.status=FLIGHTGROUP.TaskStatus.EXECUTING

  -- If task is scheduled (not waypoint) set task.
  if Task.type==FLIGHTGROUP.TaskType.SCHEDULED then

    -- Clear all tasks.
    self.flightgroup:ClearTasks()
  
    -- Task done.
    local TaskDone=self.flightgroup:TaskFunction("FLIGHTGROUP._TaskDone", self, Task)
  
    -- Combo task.
    local TaskCombo=self.flightgroup:TaskCombo({Task.dcstask, TaskDone})
  
    -- Set task for group.
    self.flightgroup:SetTask(TaskCombo)
    
  end
  
end


--- On after TaskPause event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #FLIGHTGROUP.Task Task The task.
function FLIGHTGROUP:onafterTaskPause(From, Event, To, Task)

  if self.taskcurrent>0 then

    -- Clear all tasks.
    self.flightgroup:ClearTasks()

    -- Task status executing.
    Task.status=1 --FLIGHTGROUP.TaskStatus.PAUSED

  end

end

--- On after "TaskCancel" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #FLIGHTGROUP.Task Task
function FLIGHTGROUP:onafterTaskCancel(From, Event, To)
  
  -- Get current task.
  local task=self:GetTaskCurrent()
  
  if task then
    local text=string.format("Task %s ID=%d cancelled.", task.description, task.id)
    MESSAGE:New(text, 10, "DEBUG"):ToAllIf(self.Debug)    
    self:I(self.sid..text)
    -- Clear tasks.
    self.flightgroup:ClearTasks()
    self:TaskDone(task)  
  else
    local text=string.format("WARNING: No current task to cancel!")
    MESSAGE:New(text, 10, "DEBUG"):ToAllIf(self.Debug)
    self:I(self.sid..text)      
  end
end


--- On after TaskDone event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #FLIGHTGROUP.Task Task
function FLIGHTGROUP:onafterTaskDone(From, Event, To, Task)

  -- Debug message.
  local text=string.format("Task done: %s ID=%d", Task.description, Task.id)
  MESSAGE:New(text, 10, "DEBUG"):ToAllIf(self.Debug)
  self:I(self.sid..text)

  -- No current task.
  self.taskcurrent=0
  
  -- Task status done.
  Task.status=FLIGHTGROUP.TaskStatus.ACCOMPLISHED
  
  -- Update route.
  self:_UpdateRoute()
  
end


--- On after "DetectedUnit" event. Add newly detected unit to detected units set.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Unit#UNIT Unit The detected unit
-- @parma #string assignment The (optional) assignment for the asset.
function FLIGHTGROUP:onafterDetectedUnit(From, Event, To, Unit)
  self:I(self.sid..string.format("Detected unit %s.", Unit:GetName()))
  self.detectedunits:AddUnit(Unit)
end


--- On after "ElementDead" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #FLIGHTGROUP.Element Element The flight group element.
function FLIGHTGROUP:onafterElementDead(From, Event, To, Element)
  self:I(self.sid..string.format("Element dead %s.", Element.name))

  -- Set element status.
  self:_UpdateStatus(Element, FLIGHTGROUP.ElementStatus.DEAD)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Task functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get next task in queue. Task needs to be in state SCHEDULED and time must have passed.
-- @param #FLIGHTGROUP self
function FLIGHTGROUP:GetTask()

  if #self.taskqueue==0 then
    return nil
  else

    -- Sort results table wrt times they have already been engaged.
    local function _sort(a, b)
      local taskA=a --#FLIGHTGROUP.Task
      local taskB=b --#FLIGHTGROUP.Task
      return (taskA.time<taskB.time) or (taskA.time==taskB.time and taskA.prio<taskB.prio)
    end

    table.sort(self.taskqueue, _sort)

    local time=timer.getAbsTime()

    -- Look for first task that is not accomplished.
    for _,_task in pairs(self.taskqueue) do
      local task=_task --#FLIGHTGROUP.Task
      if task.type==FLIGHTGROUP.TaskType.SCHEDULED and task.status==FLIGHTGROUP.TaskStatus.SCHEDULED and time>=task.time then
        return task
      end
    end

  end

  return nil
end


--- Get the unfinished waypoint tasks
-- @param #FLIGHTGROUP self
-- @param #number n Waypoint index. Counting starts at one.
-- @return #table Table of tasks. Table could also be empty {}.
function FLIGHTGROUP:GetTasksWaypoint(n)

  if #self.taskqueue==0 then
    return {}
  else

    -- Sort results table wrt times they have already been engaged.
    local function _sort(a, b)
      local taskA=a --#FLIGHTGROUP.Task
      local taskB=b --#FLIGHTGROUP.Task
      return (taskA.time<taskB.time) or (taskA.time==taskB.time and taskA.prio<taskB.prio)
    end

    table.sort(self.taskqueue, _sort)


    -- Tasks table.    
    local tasks={}

    -- Look for first task that is not accomplished.
    for _,_task in pairs(self.taskqueue) do
      local task=_task --#FLIGHTGROUP.Task
      if task.type==FLIGHTGROUP.TaskType.WAYPOINT and task.status==FLIGHTGROUP.TaskStatus.SCHEDULED and task.waypoint==n then
        table.insert(tasks, task)
      end
    end

    return tasks
  end

  return nil
end


--- Function called when a group has reached the holding zone.
--@param Wrapper.Group#GROUP group Group that reached the holding zone.
--@param #FLIGHTGROUP.Mission
--@param #FLIGHTGROUP flightgroup Flight group.
--@param #FLIGHTGROUP.Task task Task.
function FLIGHTGROUP._TaskExecute(group, flightgroup, task)

  -- Debug message.
  local text=string.format("Task Execute %s", task.description)
  flightgroup:T2(flightgroup.sid..text)

  -- Set current task to nil so that the next in line can be executed.
  if flightgroup then
    flightgroup:TaskExecute(task)
  end
end

--- Function called when a group has reached the holding zone.
--@param Wrapper.Group#GROUP group Group that reached the holding zone.
--@param #FLIGHTGROUP.Mission
--@param #FLIGHTGROUP flightgroup Flight group.
--@param #FLIGHTGROUP.Task task Task.
function FLIGHTGROUP._TaskDone(group, flightgroup, task)

  -- Debug message.
  local text=string.format("Task Done %s", task.description)
  flightgroup:T2(flightgroup.sid..text)

  -- Set current task to nil so that the next in line can be executed.
  if flightgroup then
    flightgroup:TaskDone(task)
  end
end

--- Route flight group back to base.
-- @param #FLIGHTGROUP self
-- @param Wrapper.Airbase#AIRBASE RTBAirbase
-- @param #number Speed Speed in km/h.
-- @param #number Altitude Altitude in meters.
function FLIGHTGROUP:RouteRTB(RTBAirbase, Speed, Altitude)

  -- If speed is not given take 80% of max speed.
  local Speed=Speed or self.flightgroup:GetSpeedMax()*0.8

  -- Curent (from) waypoint.
  local coord=self.flightgroup:GetCoordinate()

  if Altitude then
    coord:SetAltitude(Altitude)
  end

  -- Current coordinate.
  local PointFrom=coord:WaypointAirTurningPoint(nil, Speed, {}, "Current")

  -- Overhead pass.
  local PointOverhead=RTBAirbase:GetCoordinate():SetAltitude(Altitude or coord.y):WaypointAirTurningPoint(nil, Speed, {}, "Overhead Pass")

  -- Landing waypoint.
  local PointLanding=RTBAirbase:GetCoordinate():SetAltitude(20):WaypointAirLanding(Speed, RTBAirbase, {}, "Landing")

  -- Waypoint table.
  local Points={PointFrom, PointOverhead, PointLanding}

  -- Get group template.
  local Template=self.flightgroup:GetTemplate()

  -- Set route points.
  Template.route.points=Points

  -- Set modex for respawn.
  --self.flightgroup:InitModex(self.modex)

  -- Respawn the group.
  self.flightgroup=self.flightgroup:Respawn(Template, true)

  -- Route the group or this will not work.
  self.flightgroup:Route(Points, 1)

end


--- Route flight group to orbit.
-- @param #FLIGHTGROUP self
-- @param Core.Point#COORDINATE CoordOrbit Orbit coordinate.
-- @param #number Speed Speed in km/h. Default 60% of max group speed.
-- @param #number Altitude Altitude in meters. Default 10,000 ft.
-- @param Core.Point#COORDINATE CoordRaceTrack (Optional) Race track coordinate.
function FLIGHTGROUP:RouteOrbit(CoordOrbit, Speed, Altitude, CoordRaceTrack)

  -- If speed is not given take 80% of max speed.
  local Speed=Speed or self.flightgroup:GetSpeedMax()*0.6

  -- Altitude.
  local altitude=Altitude or UTILS.FeetToMeters(10000)

  -- Waypoints.
  local wp={}

  -- Current coordinate.
  wp[1]=self.flightgroup:GetCoordinate():SetAltitude(altitude):WaypointAirTurningPoint(nil, Speed, {}, "Current")

  -- Orbit
  wp[2]=CoordOrbit:SetAltitude(altitude):WaypointAirTurningPoint(nil, Speed, {}, "Orbit")


  local TaskOrbit=self.flightgroup:TaskOrbit(CoordOrbit, altitude, Speed, CoordRaceTrack)
  local TaskRoute=self.flightgroup:TaskRoute(wp)

  --local TaskCondi=self.flightgroup:TaskCondition(time,userFlag,userFlagValue,condition,duration,lastWayPoint)

  local TaskCombo=self.flightgroup:TaskControlled(TaskRoute, TaskOrbit)

  self.flightgroup:SetTask(TaskCombo, 1)

  -- Route the group or this will not work.
  --self.flightgroup:Route(wp, 1)
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Add an element to the flight group.
-- @param #FLIGHTGROUP self
-- @param #string unitname Name of unit.
-- @return #FLIGHTGROUP.Element The element or nil.
function FLIGHTGROUP:AddElementByName(unitname)

  local unit=UNIT:FindByName(unitname)

  if unit then

    local element={} --#FLIGHTGROUP.Element

    element.name=unitname
    element.unit=unit
    element.status="unknown"
    element.group=unit:GetGroup()

    table.insert(self.element, element)

    return element
  end

  return nil
end

--- Check if a unit is and element of the flightgroup.
-- @param #FLIGHTGROUP self
-- @param #string unitname Name of unit.
-- @return #FLIGHTGROUP.Element The element.
function FLIGHTGROUP:GetElementByName(unitname)

  for _,_element in pairs(self.element) do
    local element=_element --#FLIGHTGROUP.Element

    if element.name==unitname then
      return element
    end

  end

  return nil
end


--- Check if task description is unique.
-- @param #FLIGHTGROUP self
-- @param #string description Task destription
-- @return #boolean If true, no other task has the same description.
function FLIGHTGROUP:CheckTaskDescriptionUnique(description)

  -- Loop over tasks in queue
  for _,_task in pairs(self.taskqueue) do
    local task=_task --#FLIGHTGROUP.Task
    if task.description==description then
      return false
    end    
  end
  
  return true
end

--- Get the currently executed task if there is any.
-- @param #FLIGHTGROUP self
-- @return #FLIGHTGROUP.Task Current task or nil.
function FLIGHTGROUP:GetTaskCurrent()
  return self:GetTaskByID(self.taskcurrent, FLIGHTGROUP.TaskStatus.EXECUTING)
end

--- Get task by its id.
-- @param #FLIGHTGROUP self
-- @param #number id Task id.
-- @param #string status (Optional) Only return tasks with this status, e.g. FLIGHTGROUP.TaskStatus.SCHEDULED.
-- @return #FLIGHTGROUP.Task The task or nil.
function FLIGHTGROUP:GetTaskByID(id, status)

  for _,_task in pairs(self.taskqueue) do
    local task=_task --#FLIGHTGROUP.Task

    if task.id==id then
      if status==nil or status==task.status then
        return task
      end
    end

  end

  return nil
end


--- Get next waypoint of the flight group.
-- @param #FLIGHTGROUP self
-- @return Core.Point#COORDINATE Coordinate of the next waypoint.
-- @return #number Number of waypoint.
function FLIGHTGROUP:GetNextWaypoint()

  -- Next waypoint.
  local Nextwp=nil
  if self.currentwp==#self.waypoints then
    Nextwp=1
  else
    Nextwp=self.currentwp+1
  end

  -- Debug output
  local text=string.format("Current WP=%d/%d, next WP=%d", self.currentwp, #self.waypoints, Nextwp)
  self:T2(self.lid..text)

  -- Next waypoint.
  local nextwp=self.waypoints[Nextwp] --Core.Point#COORDINATE

  return nextwp,Nextwp
end


--- Update route of group, e.g after new waypoints and/or waypoint tasks have been added.
-- @param #FLIGHTGROUP self
-- @param #number n Number of next waypoint. Default self.currentwp+1.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:_UpdateRoute(n)

  -- TODO: what happens if currentwp=#waypoints
  n=n or self.currentwp+1

  local wp={}

  -- Set "remaining" waypoits.
  for i=n, #self.waypoints do
    table.insert(wp, self.waypoints[i])
  end
  
  if #wp>0 then

    -- Route group to all defined waypoints remaining.
    self.flightgroup:Route(wp, 1)
    
  else
  
    -- Get destination or home airbase.
    local airbase=self.destination or self.homebase
    
    if airbase then
      -- Route flight home.
      self:RTB(airbase)
    else
      -- Let flight orbit.
      --self:Orbit(self.flightgroup:GetCoordinate(), UTILS.FeetToMeters(20000), self.flightgroup:GetSpeedMax()*0.4)
    end
    
  end
  
  return self
end

--- Initialize Mission Editor waypoints.
-- @param #FLIGHTGROUP self
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:_UpdateWaypointTasks()

  for i,wp in pairs(self.waypoints) do
  
    -- Tasks of this waypoint
    local taskswp={}
  
    -- At each waypoint report passing.
    local TaskPassingWaypoint=self.flightgroup:TaskFunction("FLIGHTGROUP._PassingWaypoint", self, i)
    
    table.insert(taskswp, TaskPassingWaypoint)
    
    -- Get taks
    local tasks=self:GetTasksWaypoint(i)
    
    if #tasks>0 then
      for _,task in pairs(tasks) do
        local Task=task --#FLIGHTGROUP.Task
        
        -- Add task execute.
        table.insert(taskswp, self.flightgroup:TaskFunction("FLIGHTGROUP._TaskExecute", self, Task))

        -- Add task itself.
        table.insert(taskswp, Task.dcstask)
        
        -- Add task done.
        table.insert(taskswp, self.flightgroup:TaskFunction("FLIGHTGROUP._TaskDone", self, Task))
      end
    end
        
    -- Waypoint task combo.
    wp.task=self.flightgroup:TaskCombo(taskswp)
        
    -- Debug info.
    self:T3({wptask=taskswp})
  end

end

--- Initialize Mission Editor waypoints.
-- @param #FLIGHTGROUP self
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:_InitWaypoints()

  -- Waypoints of group as defined in the ME.
  self.waypoints=self.flightgroup:GetTemplateRoutePoints()
  
  -- Update waypoint tasks.
  self:_UpdateWaypointTasks()

  -- Init array.
  self.coordinates={}

  -- Set waypoint table.
  for i,point in ipairs(self.waypoints or {}) do

    -- Coordinate of the waypoint
    local coord=COORDINATE:New(point.x, point.alt, point.y)

    -- Set velocity of the coordinate.
    coord:SetVelocity(point.speed)

    -- Add to table.
    table.insert(self.coordinates, coord)

    -- Debug info.
    if self.Debug then
      coord:MarkToAll(string.format("Flight %s waypoint %d, Speed=%.1f knots", self.groupname, i, UTILS.MpsToKnots(point.speed)))
    end

  end

  -- Set current waypoint. Counting starts a one.
  self.currentwp=1

  return self
end

--- Function called when a group is passing a waypoint.
--@param Wrapper.Group#GROUP group Group that passed the waypoint
--@param #FLIGHTGROUP flightgroup Flightgroup object.
--@param #number i Waypoint number that has been reached.
function FLIGHTGROUP._PassingWaypoint(group, flightgroup, i)

  local final=#flightgroup.waypoints or 1

  -- Debug message.
  local text=string.format("Group %s passing waypoint %d of %d.", group:GetName(), i, final)

  -- Debug smoke and marker.
  if flightgroup.Debug then
    local pos=group:GetCoordinate()
    pos:SmokeRed()
    local MarkerID=pos:MarkToAll(string.format("Group %s reached waypoint %d", group:GetName(), i))
  end

  -- Debug message.
  MESSAGE:New(text,10):ToAllIf(flightgroup.Debug)
  flightgroup:I(flightgroup.sid..text)

  -- Set current waypoint.
  flightgroup.currentwp=i

  -- Passing Waypoint event.
  flightgroup:PassingWaypoint(i, final)

  -- If final waypoint reached, do route all over again.
  if i==final and final>1 then
    --TODO: final waypoint reached! what next?
  end
end




--- Check if a unit is and element of the flightgroup.
-- @param #FLIGHTGROUP self
-- @param #string unitname Name of unit.
-- @return #boolean If true, unit is element of the flight group or false if otherwise.
function FLIGHTGROUP:_IsElement(unitname)

  for _,_element in pairs(self.element) do
    local element=_element --#FLIGHTGROUP.Element

    if element.name==unitname then
      return true
    end

  end

  return false
end

--- Check if all elements of the flight group have the same status (or are dead).
-- @param #FLIGHTGROUP self
-- @param #string unitname Name of unit.
function FLIGHTGROUP:_AllSameStatus(status)

  for _,_element in pairs(self.element) do
    local element=_element --#FLIGHTGROUP.Element

    if element.status==FLIGHTGROUP.ElementStatus.DEAD then
      -- Do nothing. Element is already dead and does not count.
    elseif element.status~=status then
      -- At least this element has a different status.
      return false
    end

  end

  return true
end

--- Check if all elements of the flight group have the same status (or are dead).
-- @param #FLIGHTGROUP self
-- @param #string status Status to check.
-- @return #boolean If true, all elements have a similar status.
function FLIGHTGROUP:_AllSimilarStatus(status)

  local similar=true

  for _,_element in pairs(self.element) do
    local element=_element --#FLIGHTGROUP.Element

    -- Dead units dont count.
    if element.status~=FLIGHTGROUP.ElementStatus.DEAD then

      if status==FLIGHTGROUP.ElementStatus.SPAWNED then

        -- Element SPAWNED: Nothing to check.
        if element.status~=status then

        end

      elseif status==FLIGHTGROUP.ElementStatus.PARKING then

        -- Element PARKING: Check that the other are not stil SPAWNED
        if element.status~=status and
          element.status==FLIGHTGROUP.ElementStatus.SPAWNED  then
          return false
        end

      elseif status==FLIGHTGROUP.ElementStatus.TAXIING then

        -- Element TAXIING: Check that the other are not stil SPAWNED or PARKING
        if element.status~=status and
          element.status==FLIGHTGROUP.ElementStatus.SPAWNED or
          element.status==FLIGHTGROUP.ElementStatus.PARKING then
          return false
        end

      elseif status==FLIGHTGROUP.ElementStatus.AIRBORNE then

        -- Element AIRBORNE: Check that the other are not stil SPAWNED, PARKING or TAXIING
        if element.status~=status and
          element.status==FLIGHTGROUP.ElementStatus.SPAWNED or
          element.status==FLIGHTGROUP.ElementStatus.PARKING or
          element.status==FLIGHTGROUP.ElementStatus.TAXIING then
          return false
        end

      elseif status==FLIGHTGROUP.ElementStatus.LANDED then

        -- Element LANDED: check that the others are not stil AIRBORNE
        if element.status~=status and
          element.status==FLIGHTGROUP.ElementStatus.AIRBORNE then
          return false
        end

      elseif status==FLIGHTGROUP.ElementStatus.ARRIVED then

        -- Element ARRIVED: check that the others are not stil AIRBORNE or TAXIING
        if element.status~=status and
          element.status==FLIGHTGROUP.ElementStatus.AIRBORNE or
          element.status==FLIGHTGROUP.ElementStatus.TAXIING  then
          return false
        end

      end

      if element.status==FLIGHTGROUP.ElementStatus.DEAD then
        -- Do nothing. Element is already dead and does not count.
      elseif element.status~=status then
        -- At least this element has a different status.
        return false
      end

    end --DEAD

  end

  return true
end

--- Check if all elements of the flight group have the same status or are dead.
-- @param #FLIGHTGROUP self
-- @param #FLIGHTGROUP.Element element Element.
-- @param #string newstatus New status of element
function FLIGHTGROUP:_UpdateStatus(element, newstatus)

  -- Old status.
  local oldstatus=element.status

  -- Update status of element.
  element.status=newstatus

  local group=element.group

  if newstatus==FLIGHTGROUP.ElementStatus.SPAWNED then
    ---
    -- SPAWNED
    ---

    if self:_AllSimilarStatus(newstatus) then
      self:FlightSpawned(group)
    end

    --[[
    if element.unit:InAir() then
      self:ElementAirborne(element)
    else
      self:ElementParking(element)
    end
    ]]

  elseif newstatus==FLIGHTGROUP.ElementStatus.PARKING then
    ---
    -- PARKING
    ---

    if self:_AllSimilarStatus(newstatus) then
      self:FlightParking(group)
    end

  elseif newstatus==FLIGHTGROUP.ElementStatus.TAXIING then
    ---
    -- TAXIING
    ---

    if self:_AllSimilarStatus(newstatus) then
      self:FlightTaxiing(group)
    end

  elseif newstatus==FLIGHTGROUP.ElementStatus.AIRBORNE then
    ---
    -- AIRBORNE
    ---

    if self:_AllSimilarStatus(newstatus) then

      if self:IsTaxiing() then
        self:FlightAirborne(group)
      elseif self:IsParking() then
        --self:FlightTaxiing(group)
        self:FlightAirborne(group)
      elseif self:IsSpawned() then
        --self:FlightParking(group)
        --self:FlightTaxiing(group)
        self:FlightAirborne(group)
      end

    end

  elseif newstatus==FLIGHTGROUP.ElementStatus.LANDED then
    ---
    -- LANDED
    ---

    if self:_AllSimilarStatus(newstatus) then
      self:FlightLanded(group)
    end

  elseif newstatus==FLIGHTGROUP.ElementStatus.ARRIVED then
    ---
    -- ARRIVED
    ---

    if self:_AllSimilarStatus(newstatus) then

      if self:IsLanded() then
        self:FlightArrived(group)
      elseif self:IsAirborne() then
        self:FlightLanded(group)
        self:FlightArrived(group)
      end

    end

  elseif newstatus==FLIGHTGROUP.ElementStatus.DEAD then
    ---
    -- DEAD
    ---

    if self:_AllSimilarStatus(newstatus) then
      self:FlightDead(group)
    end

  end
end

--- Check detected units.
-- @param #FLIGHTGROUP self
function FLIGHTGROUP:_CheckDetectedUnits()

  if self.flightgroup and not self:IsDead() then

    -- Get detected DCS units.
    local detectedtargets=self.flightgroup:GetDetectedTargets()

    local detected={}
    for DetectionObjectID, Detection in pairs(detectedtargets or {}) do
      local DetectedObject=Detection.object -- DCS#Object

      if DetectedObject and DetectedObject:isExist() and DetectedObject.id_<50000000 then
        local unit=UNIT:Find(DetectedObject)
        
        if unit and unit:IsAlive() then
          -- Name of detected unit
          local unitname=unit:GetName()

          -- Add unit to detected table of this run.        
          table.insert(detected, unit)
          
          -- Trigger detected unit event.
          self:DetectedUnit(unit)
          
          if self.detectedunits:FindUnit(unitname) then
            -- Unit is already in the detected unit set ==> Trigger "DetectedUnitKnown" event.
            self:DetectedUnitKnown(unit)
          else
            -- Unit is was not detected ==> Trigger "DetectedUnitNew" event.
            self:DetectedUnitNew(unit)
          end
          
        end
      end
    end

    -- Loop over units in detected set.
    for _,_unit in pairs(self.detectedunits:GetSet()) do
      local unit=_unit --Wrapper.Unit#UNIT

      -- Loop over detected units
      local gotit=false
      for _,_du in pairs(detected) do
        local du=_du --Wrapper.Unit#UNIT
        if unit:GetName()==du:GetName() then
          gotit=true
        end
      end

      if not gotit then
        self:DetectedUnitLost(unit)
      end

    end

  end


end

--- Get onboard number.
-- @param #FLIGHTGROUP self
-- @param #string unitname Name of the unit.
-- @return #string Modex.
function FLIGHTGROUP:_GetOnboardNumber(unitname)

  local group=UNIT:FindByName(unitname):GetGroup()

  -- Units of template group.
  local units=group:GetTemplate().units

  -- Get numbers.
  local numbers={}
  for _,unit in pairs(units) do

    if unitname==unit.name then
      return tostring(unit.onboard_num)
    end

  end

  return nil
end

--- Get the number of shells a unit or group currently has. For a group the ammo count of all units is summed up.
-- @param #FLIGHTGROUP self
-- @param #FLIGHTGROUP.Element element The element.
-- @param #boolean display Display ammo table as message to all. Default false.
-- @return #number Total amount of ammo the whole group has left.
-- @return #number Number of shells left.
-- @return #number Number of rockets left.
-- @return #number Number of bombs left.
-- @return #number Number of missiles left.
function FLIGHTGROUP:GetAmmoElement(element, display)

  -- Default is display false.
  if display==nil then
    display=false
  end

  -- Init counter.
  local nammo=0
  local nshells=0
  local nrockets=0
  local nmissiles=0
  local nbombs=0

  local unit=element.unit


  -- Output.
  local text=string.format("FLIGHTGROUP group %s - unit %s:\n", self.groupname, unit:GetName())

  -- Get ammo table.
  local ammotable=unit:GetAmmo()

  if ammotable then

    local weapons=#ammotable

    -- Display ammo table
    if display then
      self:E(FLIGHTGROUP.id..string.format("Number of weapons %d.", weapons))
      self:E({ammotable=ammotable})
      self:E(FLIGHTGROUP.id.."Ammotable:")
      for id,bla in pairs(ammotable) do
        self:E({id=id, ammo=bla})
      end
    end

    -- Loop over all weapons.
    for w=1,weapons do

      -- Number of current weapon.
      local Nammo=ammotable[w]["count"]

      -- Type name of current weapon.
      local Tammo=ammotable[w]["desc"]["typeName"]

      local _weaponString = UTILS.Split(Tammo,"%.")
      local _weaponName   = _weaponString[#_weaponString]

      -- Get the weapon category: shell=0, missile=1, rocket=2, bomb=3
      local Category=ammotable[w].desc.category

      -- Get missile category: Weapon.MissileCategory AAM=1, SAM=2, BM=3, ANTI_SHIP=4, CRUISE=5, OTHER=6
      local MissileCategory=nil
      if Category==Weapon.Category.MISSILE then
        MissileCategory=ammotable[w].desc.missileCategory
      end

      -- We are specifically looking for shells or rockets here.
      if Category==Weapon.Category.SHELL then

        -- Add up all shells.
        nshells=nshells+Nammo

        -- Debug info.
        text=text..string.format("- %d shells of type %s\n", Nammo, _weaponName)

      elseif Category==Weapon.Category.ROCKET then

        -- Add up all rockets.
        nrockets=nrockets+Nammo

        -- Debug info.
        text=text..string.format("- %d rockets of type %s\n", Nammo, _weaponName)

      elseif Category==Weapon.Category.BOMB then

        -- Add up all rockets.
        nbombs=nbombs+Nammo

        -- Debug info.
        text=text..string.format("- %d bombs of type %s\n", Nammo, _weaponName)

      elseif Category==Weapon.Category.MISSILE then

        -- Add up all cruise missiles (category 5)
        if MissileCategory==Weapon.MissileCategory.AAM then
          nmissiles=nmissiles+Nammo
        elseif MissileCategory==Weapon.MissileCategory.ANTI_SHIP then
          nmissiles=nmissiles+Nammo
        elseif MissileCategory==Weapon.MissileCategory.BM then
          nmissiles=nmissiles+Nammo
        elseif MissileCategory==Weapon.MissileCategory.OTHER then
          nmissiles=nmissiles+Nammo
        end

        -- Debug info.
        text=text..string.format("- %d %s missiles of type %s\n", Nammo, self:_MissileCategoryName(MissileCategory), _weaponName)

      else

        -- Debug info.
        text=text..string.format("- %d unknown ammo of type %s (category=%d, missile category=%s)\n", Nammo, Tammo, Category, tostring(MissileCategory))

      end

    end
  end

  -- Debug text and send message.
  if display then
    self:I(self.sid..text)
  else
    self:T3(self.sid..text)
  end
  MESSAGE:New(text, 10):ToAllIf(display)

  -- Total amount of ammunition.
  nammo=nshells+nrockets+nmissiles+nbombs

  return nammo, nshells, nrockets, nbombs, nmissiles
end


--- Returns a name of a missile category.
-- @param #FLIGHTGROUP self
-- @param #number categorynumber Number of missile category from weapon missile category enumerator. See https://wiki.hoggitworld.com/view/DCS_Class_Weapon
-- @return #string Missile category name.
function FLIGHTGROUP:_MissileCategoryName(categorynumber)
  local cat="unknown"
  if categorynumber==Weapon.MissileCategory.AAM then
    cat="air-to-air"
  elseif categorynumber==Weapon.MissileCategory.SAM then
    cat="surface-to-air"
  elseif categorynumber==Weapon.MissileCategory.BM then
    cat="ballistic"
  elseif categorynumber==Weapon.MissileCategory.ANTI_SHIP then
    cat="anti-ship"
  elseif categorynumber==Weapon.MissileCategory.CRUISE then
    cat="cruise"
  elseif categorynumber==Weapon.MissileCategory.OTHER then
    cat="other"
  end
  return cat
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
