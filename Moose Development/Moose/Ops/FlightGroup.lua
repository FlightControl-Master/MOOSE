--- **Ops** - (R2.5) - AI Flight Group for Ops.
--
-- **Main Features:**
--
--    * Nice stuff.
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
-- @field #table taskqueue Queue of tasks.
-- @field Core.Set#SET_UNIT detectedunits Set of detected units.
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
  Debug          =   nil,
  sid            =   nil,
  groupname      =   nil,
  flightgroup    =   nil,
  type           =   nil,
  element        =    {},
  taskqueue      =    {},
  detectedunits  =    {},
  homebase       =   nil,
  destination    =   nil,
  speedmax       =   nil,
  range          =   nil,
  altmax         =   nil,
  taskcounter    =   nil,
  taskcurrent    =   nil,
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
-- @field #string status Status, i.e. born, parking, taxiing.

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

--- Flight group tasks.
-- @type FLIGHTGROUP.TaskStatus
-- @param #string SCHEDULED Task is sheduled.
-- @param #string EXECUTING Task is being executed.
-- @param #string ACCOMPLISHED Task is accomplished.
FLIGHTGROUP.TaskStatus={
  SCHEDULED="scheduled",
  EXECUTING="executing",
  ACCOMPLISHED="accomplished",
}

--- Flight group tasks.
-- @type FLIGHTGROUP.Task
-- @field #number id Task ID. Running number to get the task.
-- @field #number prio Priority.
-- @field #number time Abs. mission time when to execute the task.
-- @field #table dcstask DCS task structure.
-- @field #string description Brief text which describes the task.
-- @field #string status Task status.


--- FLIGHTGROUP class version.
-- @field #string version
FLIGHTGROUP.version="0.0.3"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: A lot!
-- TODO: Add tasks: 
-- TODO: Add EPLRS, TACAN.

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


  -- Add FSM transitions.
  --                 From State  -->   Event      -->     To State
  self:AddTransition("Stopped",       "Start",            "Running")     -- Start FSM.
  
  self:AddTransition("*",             "FlightStatus",     "*")           -- FLIGHTGROUP status update.
  self:AddTransition("*",             "AddDetectedUnit",  "*")           -- Add a newly detected unit to the detected units set.
  self:AddTransition("*",             "LostDetectedUnit", "*")           -- Group lost a detected target.
  
  self:AddTransition("*",             "RTB",              "Returning")   -- Group is returning to base.
  self:AddTransition("*",             "Orbit",            "Orbiting")    -- Group is holding position.
  
  self:AddTransition("*",             "TaskExecute",      "Airborne")    -- Group will execute a task.
  self:AddTransition("*",             "TaskDone",         "Airborne")    -- Group finished a task.
  self:AddTransition("*",             "TaskCancel",       "Airborne")    -- Cancel current task.
    
  self:AddTransition("*",             "ElementSpawned",   "*")           -- An element was spawned.
  self:AddTransition("*",             "ElementParking",   "*")           -- An element was spawned.
  self:AddTransition("*",             "ElementTaxiing",   "*")           -- An element spooled up the engines.
  self:AddTransition("*",             "ElementAirborne",  "*")           -- An element took off.
  self:AddTransition("*",             "ElementLanded",    "*")           -- An element landed.
  self:AddTransition("*",             "ElementArrived",   "*")           -- An element arrived.
  self:AddTransition("*",             "ElementDead",      "*")           -- An element crashed, ejected, or pilot dead.
  
  self:AddTransition("*",             "FlightSpawned",    "Spawned")     -- The whole flight group is airborne.
  self:AddTransition("*",             "FlightParking",    "Parking")     -- The whole flight group is airborne.
  self:AddTransition("*",             "FlightTaxiing",    "Taxiing")     -- The whole flight group is airborne.
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
  self.Debug=true
  
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
  
  self.taskcounter=0
  
  -- Autostart.
  self:Start()

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


--- Get set of decteded units.
-- @param #FLIGHTGROUP self
-- @param #string description Brief text describing the task, e.g. "Attack SAM".
-- @param #table task DCS task table stucture.
-- @param #number prio Priority of the task.
-- @param #string clock Mission time when task is executed.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:AddTask(description, task, prio, clock)

  -- Increase coutner.
  self.taskcounter=self.taskcounter+1

  local newtask={} --#FLIGHTGROUP.Task
  
  newtask.description=description
  newtask.status=FLIGHTGROUP.TaskStatus.SCHEDULED
  newtask.dcstask=task
  newtask.prio=prio or 50
  newtask.time=clock and UTILS.ClockToSeconds(clock) or timer.getAbsTime()+60
  newtask.id=self.taskcounter
  
  self:T2({newtask=newtask})
  
  table.insert(self.taskqueue, newtask)

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

--- On after "FlightStatus" event.
-- @param #FLIGHTGROUP self
-- @param Wrapper.Group#GROUP Group Flight group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterFlightStatus(From, Event, To)

  -- FSM state.
  local fsmstate=self:GetState()

  -- Short info.
  local text=string.format("Flight group status %s.", fsmstate)
  self:I(self.sid..text)
  
  -- Element status.
  text="Elements:"
  for i,_element in pairs(self.element) do
    local element=_element --#FLIGHTGROUP.Element
    local name=element.name
    local status=element.status
    local unit=element.unit
    local fuel=unit:GetFuel() or 0
    local life=unit:GetLifeRelative() or 0
    
    -- Check if element is not dead and we missed an event.
    if life<0 and element.status~=FLIGHTGROUP.ElementStatus.DEAD then
      self:ElementDead(element)
    end
    
    -- Output text for element.
    text=text..string.format("\n[%d] %s: status=%s, fuel=%.1f, life=%.1f", i, name, status, fuel*100, life*100)
  end
  if #self.element==0 then
    text=text.." none!"
  end
  self:I(text)
  
  -- Check no current task.
  if not self.taskcurrent then
  
    -- Get task from queue.
    local task=self:GetTask()
    
    -- Execute task if any.
    if task then
      self:TaskExecute(task)
    end
          
  end

  -- Task queue.
  text="Tasks:"
  for i,_task in pairs(self.taskqueue) do
    local task=_task --#FLIGHTGROUP.Task
    local name=task.description
    local status=task.status
    local clock=UTILS.SecondsToClock(task.time)
    local eta=task.time-timer.getAbsTime()
    -- Output text for element.
    text=text..string.format("\n[%d] %s: status=%s, scheduled at %s (ETA %d seconds)", i, name, status, clock, eta)
  end
  if #self.taskqueue==0 then
    text=text.." none!"
  end
  self:I(text)
  
  
  -- Next check in ~30 seconds.
  self:__FlightStatus(-30)
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
-- @param Wrapper.Airbase#AIRBASE airbase The base to return to.
function FLIGHTGROUP:onafterOrbit(From, Event, To, Coord)

  -- Debug message.
  local text=string.format("Flight group returning to airbase %s.", airbase:GetName())
  MESSAGE:New(text, 10, "DEBUG"):ToAllIf(self.Debug)
  self:I(self.sid..text)
      
  -- Route helo back home. It is respawned! But this is the only way to ensure that it actually lands at the airbase.
  self:RouteRTB(airbase)
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
  self.taskcurrent=Task

  -- Clear all tasks.
  self.flightgroup:ClearTasks()
    
  -- Task done.
  local TaskDone=self.flightgroup:TaskFunction("FLIGHTGROUP._TaskDone", self, self.taskcurrent)
    
  -- Combo task.        
  local TaskCombo=self.flightgroup:TaskCombo({self.taskcurrent.dcstask, TaskDone})
    
  -- Set task for group.
  self.flightgroup:SetTask(TaskCombo, 1)
    
  -- Task status executing.
  self.taskcurrent.status=FLIGHTGROUP.TaskStatus.EXECUTING
  
end


--- On after TaskPause event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #FLIGHTGROUP.Task Task The task.
function FLIGHTGROUP:onafterTaskPause(From, Event, To)

  if self.taskcurrent then

    -- Clear all tasks.
    self.flightgroup:ClearTasks()
        
    -- Task status executing.
    self.taskcurrent.status=FLIGHTGROUP.TaskStatus.PAUSED
    
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
  local text=string.format("Task %s ID=%d done.", Task.description, Task.id)
  MESSAGE:New(text, 10, "DEBUG"):ToAllIf(self.Debug)
  self:I(self.sid..text)

  Task.status=FLIGHTGROUP.TaskStatus.ACCOMPLISHED
end


--- On after "DetectedUnit" event. Add newly detected unit to detected units set.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Unit#UNIT Unit The detected unit
-- @parma #string assignment The (optional) assignment for the asset.
function FLIGHTGROUP:onafterAddDetectedUnit(From, Event, To, Unit)
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

--- Sort task queue.
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
      if task.status~=FLIGHTGROUP.TaskStatus.ACCOMPLISHED and task.time>=time then
        return task
      end
    end
    
  end
  
  return nil  
end


--- Function called when a group has reached the holding zone.
--@param Wrapper.Group#GROUP group Group that reached the holding zone.
--@param #FLIGHTGROUP.Mission
--@param #FLIGHTGROUP flightgroup Flight group.
--@param #table task Task.
function FLIGHTGROUP._TaskDone(group, flightgroup, task)

  -- Debug message.
  local text=string.format("Task Done")
  flightgroup:I(flightgroup.sid..text)

  -- Set current task to nil so that the next in line can be executed.
  if flightgroup then
    flightgroup.taskcurrent=nil
  end
end


--- Launch a flight group to intercept an intruder.
-- @param #FLIGHTGROUP self
-- @param Wrapper.Group#GROUP bandits Bandit group.
function FLIGHTGROUP:TaskIntercept(bandit)

  -- Task orbit.
  local tasks={}
  
  for _,unit in pairs(bandit:GetUnits()) do
    tasks[#tasks+1]=self.flightgroup:TaskAttackUnit(unit)
  end
  
  -- Passing waypoint task function.
  tasks[#tasks+1]=self.flightgroup:TaskFunction("FLIGHTGROUP._TaskDone", self)  
  
  local speed=self.flightgroup:GetSpeedMax()
  local altitude=bandit:GetAltitude()
  
  -- Create waypoints.
  local wp={}
  wp[1]=self:GetCoordinate():WaypointAirTakeOffParking()
  wp[2]=self:GetCoordinate():SetAltitude(altitude):WaypointAirTurningPoint(COORDINATE.WaypointAltType.BARO, speed, {tasks}, "Intercept")
  
  -- Start uncontrolled group.
  self.flightgroup:StartUncontrolled()
  
  --airboss:SetExcludeAI()
  
  -- Route group
  self.flightgroup:Route(wp)
  
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
-- @param #string unitname Name of the unit.
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
          table.insert(detected, unit)
          local unitname=unit:GetName()
          if self.detectedunits:FindUnit(unitname) then
            -- Unit is already in the detected unit set.
            self:T(self.sid..string.format("Detected unit %s is already known.", unitname))
          else
            self:AddDetectedUnit(unit)
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
        self:LostDetectedUnit(unit)
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


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
