--- **Ops** - (R2.5) - AI Flight Group for Ops.
--
-- **Main Features:**
--
--    * Monitor flight status of elements or entire group.
--    * Monitor fuel and ammo status.
--    * Sophisticated task queueing system.
--    * Many additional events for each element and the whole group.
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
-- @field #string lid Class id string for output to DCS log file.
-- @field #string groupname Name of flight group.
-- @field Wrapper.Group#GROUP group Flight group object.
-- @field #string type Aircraft type of flight group.
-- @field #table elements Table of elements, i.e. units of the group.
-- @field #table waypoints Table of waypoints.
-- @field #table waypoints0 Table of initial waypoints.
-- @field #table currentwp Current waypoint.
-- @field #table taskqueue Queue of tasks.
-- @field #number taskcounter Running number of task ids.
-- @field #number taskcurrent ID of current task. If 0, there is no current task assigned.
-- @field #table taskenroute Enroute task of the group.
-- @field #boolean istanker If true, group gets enroute task tanker.
-- @field #boolean isawacs if True, group get enroute task AWACS.
-- @field #boolean eplrs If true, group will activate it's datalink.
-- @field Core.Set#SET_UNIT detectedunits Set of detected units.
-- @field Wrapper.Airbase#AIRBASE homebase The home base of the flight group.
-- @field Wrapper.Airbase#AIRBASE destbase The destination base of the flight group.
-- @field Core.Zone#ZONE homezone The home zone of the flight group. Set when spawn happens in air.
-- @field Core.Zone#ZONE destzone The destination zone of the flight group. Set when final waypoint is in air.
-- @field #string attribute Generalized attribute.
-- @field #string actype Type name of the aircraft.
-- @field #number speedmax Max speed in km/h.
-- @field #number range Range of the aircraft in km.
-- @field #number ceiling Max altitude the aircraft can fly at in meters.
-- @field #boolean ai If true, flight is purely AI. If false, flight contains at least one human player.
-- @field #boolean fuellow Fuel low switch.
-- @field #number fuellowthresh Low fuel threshold in percent.
-- @field #boolean fuellowrtb RTB on low fuel switch.
-- @field #boolean fuelcritical Fuel critical switch.
-- @field #number fuelcriticalthresh Critical fuel threshold in percent.
-- @field #boolean fuelcriticalrtb RTB on critical fuel switch. 
-- @field Ops.Squadron#SQUADRON squadron The squadron the flight group belongs to.
-- @field Ops.FlightControl#FLIGHTCONTROL flightcontrol The flightcontrol handling this group.
-- @field Core.UserFlag#USERFLAG flaghold Flag for holding.
-- @field #number Tholding Abs. mission time stamp when the group reached the holding point.
-- @field #number Tparking Abs. mission time stamp when the group was spawned uncontrolled and is parking.
-- @field #table menu F10 radio menu.
-- @field #string livery Livery.
-- @field Core.Set#SET_ZONE checkzones Set of zones.
-- @field Core.Set#SET_ZONE inzones Set of zones in which the group is currently in.
-- @field #boolean groupinitialized If true, group parameters were initialized.
-- @extends Core.Fsm#FSM

--- *To invent an airplane is nothing. To build one is something. To fly is everything.* -- Otto Lilienthal
--
-- ===
--
-- ![Banner Image](..\Presentations\CarrierAirWing\FLIGHTGROUP_Main.jpg)
--
-- # The FLIGHTGROUP Concept
--
-- # Events
-- 
-- This class introduces a lot of additional events that will be handy in many situations.
-- Certain events like landing, takeoff etc. are triggered for each element and also have a corresponding event when the whole group reaches this state.
-- 
-- ## Spawning
-- 
-- ## Parking
-- 
-- ## Taxiing
-- 
-- ## Takeoff
-- 
-- ## Airborne
-- 
-- ## Landed
-- 
-- ## Arrived
-- 
-- ## Dead
-- 
-- ## Fuel
-- 
-- ## Ammo
-- 
-- ## Detected Units
-- 
-- ## Check In Zone
-- 
-- ## Passing Waypoint
-- 
-- 
-- # Tasking
-- 
-- The FLIGHTGROUP class significantly simplifies the monitoring of DCS tasks. Two types of tasks can be set
-- 
--     * **Scheduled Tasks**
--     * **Waypoint Tasks**
-- 
-- ## Scheduled Tasks
-- 
-- ## Waypoint Tasks
-- 
-- 
-- # Examples
-- 
-- Here are some examples to show how things are done.
-- 
-- ## 1. Spawn
-- 
-- ## 2. Attack Group
-- 
-- ## 3. Whatever
-- 
-- ## 4. Simple Tanker
-- 
-- ## 5. Simple AWACS
-- 
-- ## 6. Scheduled Tasks
-- 
-- ## 7. Waypoint Tasks
-- 
--  
--
--
-- @field #FLIGHTGROUP
FLIGHTGROUP = {
  ClassName          = "FLIGHTGROUP",
  Debug              = false,
  lid                =   nil,
  groupname          =   nil,
  group              =   nil,
  grouptemplate      =   nil,
  type               =   nil,
  waypoints          =   nil,
  waypoints0         =   nil,
  currentwp          =  -100,
  elements           =    {},
  taskqueue          =    {},
  taskcounter        =   nil,
  taskcurrent        =   nil,
  taskenroute        =   nil,
  istanker           =   nil,
  isawacs            =   nil,
  eplrs              =   nil,
  detectedunits      =    {},
  homebase           =   nil,
  destination        =   nil,
  attribute          =   nil,
  actype             =   nil,
  speedmax           =   nil,
  range              =   nil,
  ceiling            =   nil,
  fuellow            = false,
  fuellowthresh      =   nil,
  fuellowrtb         =   nil,
  fuelcritical       =   nil,  
  fuelcriticalthresh =   nil,
  fuelcriticalrtb    = false,
  squadron           =   nil,
  flightcontrol      =   nil,
  flaghold           =   nil,
  Tholding           =   nil,
  Tparking           =   nil,
  menu               =   nil,
  livery             =   nil,
  checkzones         =   nil,
  inzones            =   nil,
  groupinitialized   =   nil,
}


--- Status of flight group element.
-- @type FLIGHTGROUP.ElementStatus
-- @field #string INUTERO Element was not spawned yet or its status is unknown so far.
-- @field #string SPAWNED Element was spawned into the world.
-- @field #string PARKING Element is parking after spawned on ramp.
-- @field #string ENGINEON Element started its engines.
-- @field #string TAXIING Element is taxiing after engine startup.
-- @field #string TAKEOFF Element took of after takeoff event.
-- @field #string AIRBORNE Element is airborne. Either after takeoff or after air start.
-- @field #string LANDING Element is landing.
-- @field #string LANDED Element landed and is taxiing to its parking spot.
-- @field #string ARRIVED Element arrived at its parking spot and shut down its engines.
-- @field #string DEAD Element is dead after it crashed, pilot ejected or pilot dead events.
FLIGHTGROUP.ElementStatus={
  INUTERO="inutero",
  SPAWNED="spawned",
  PARKING="parking",
  ENGINEON="engineon",
  TAXIING="taxiing",
  TAKEOFF="takeoff",
  AIRBORNE="airborne",
  LANDING="landing",
  LANDED="landed",
  ARRIVED="arrived",
  DEAD="dead",
}

--- Generalized attribute. See [DCS attributes](https://wiki.hoggitworld.com/view/DCS_enum_attributes) on hoggit.
-- @type FLIGHTGROUP.Attribute
-- @field #string TRANSPORTPLANE Airplane with transport capability. This can be used to transport other assets.
-- @field #string AWACS Airborne Early Warning and Control System.
-- @field #string FIGHTER Fighter, interceptor, ... airplane.
-- @field #string BOMBER Aircraft which can be used for strategic bombing.
-- @field #string TANKER Airplane which can refuel other aircraft.
-- @field #string TRANSPORTHELO Helicopter with transport capability. This can be used to transport other assets.
-- @field #string ATTACKHELO Attack helicopter.
-- @field #string UAV Unpiloted Aerial Vehicle, e.g. drones.
-- @field #string OTHER Other aircraft type.
FLIGHTGROUP.Attribute = {
  TRANSPORTPLANE="TransportPlane",
  AWACS="AWACS",
  FIGHTER="Fighter",
  BOMBER="Bomber",
  TANKER="Tanker",
  TRANSPORTHELO="TransportHelo",
  ATTACKHELO="AttackHelo",
  UAV="UAV",
  OTHER="Other",
}

--- Flight group element.
-- @type FLIGHTGROUP.Element
-- @field #string name Name of the element, i.e. the unit/client.
-- @field Wrapper.Unit#UNIT unit Element unit object.
-- @field Wrapper.Group#GROUP group Group object of the element.
-- @field #string modex Tail number.
-- @field #string skill Skill level.
-- @field #boolean ai If true, element is AI.
-- @field Wrapper.Client#CLIENT client The client if element is occupied by a human player.
-- @field #table pylons Table of pylons.
-- @field #number fuelmass Mass of fuel in kg.
-- @field #number category Aircraft category.
-- @field #string categoryname Aircraft category name.
-- @field #string callsign Call sign, e.g. "Uzi 1-1".
-- @field #string status Status, i.e. born, parking, taxiing. See @{#FLIGHTGROUP.ElementStatus}.
-- @field #number damage Damage of element in percent.
-- @field Wrapper.Airbase#AIRBASE.ParkingSpot parking The parking spot table the element is parking on.


--- Flight group tasks.
-- @type FLIGHTGROUP.Mission
-- @param #string INTERCEPT Intercept task.
-- @param #string CAP Combat Air Patrol task.
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
-- @field #string SCHEDULED Task is scheduled.
-- @field #string EXECUTING Task is being executed.
-- @field #string ACCOMPLISHED Task is accomplished.
FLIGHTGROUP.TaskStatus={
  SCHEDULED="scheduled",
  EXECUTING="executing",
  ACCOMPLISHED="accomplished",
}

--- Flight group task status.
-- @type FLIGHTGROUP.TaskType
-- @field #string SCHEDULED Task is scheduled and will be executed at a given time.
-- @field #string WAYPOINT Task is executed at a specific waypoint.
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
-- @field Core.UserFlag#USERFLAG stopflag If flag is set to 1 (=true), the task is stopped.


--- FLIGHTGROUP class version.
-- @field #string version
FLIGHTGROUP.version="0.2.5"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- DONE: Add tasks.
-- DONE: Waypoints, read, add, insert, detour.

-- DONE: Get ammo.
-- DONE: Get pylons.
-- DONE: Fuel threshhold ==> RTB.
-- TODO: ROE, Afterburner restrict.
-- TODO: Add EPLRS, TACAN.
-- TODO: Respawn? With correct loadout, fuelstate.
-- TODO: Damage?
-- TODO: shot events?
-- TODO: Marks to add waypoints/tasks on-the-fly.
-- TODO: Mark assigned parking spot on F10 map.
-- TODO: Let user request a parking spot via F10 marker :)
-- TODO: Get proper monitoring of parking spots! Try to avoid scan and getParking as much as possible for performance reasons.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new FLIGHTGROUP object and start the FSM.
-- @param #FLIGHTGROUP self
-- @param #string groupname Name of the group.
-- @param #string autostart If *true* or *nil* automatically start the FSM. If *false*, use FLIGHTGROUP:Start() manually.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:New(groupname, autostart)

  -- First check if we already have a flight group for this group.
  local fg=_DATABASE:GetFlightGroup(groupname)
  if fg then
    fg:I(fg.lid..string.format("WARNING: Flight group %s already exists in data base!", groupname))
    return fg
  end

  -- Inherit everything from WAREHOUSE class.
  local self=BASE:Inherit(self, FSM:New()) -- #FLIGHTGROUP

  --self.group=AIGroup
  self.groupname=tostring(groupname)

  -- Set some string id for output to DCS.log file.
  self.lid=string.format("FLIGHTGROUP %s | ", self.groupname)

  -- Start State.
  self:SetStartState("Stopped")

  -- Init set of detected units.
  self.detectedunits=SET_UNIT:New()
  
  -- Init inzone set.
  self.inzones=SET_ZONE:New()
  
  -- Defaults
  self:SetFuelLowThreshold()
  self:SetFuelCriticalThreshold()


  -- Add FSM transitions.
  --                 From State  -->   Event      -->      To State
  self:AddTransition("Stopped",       "Start",             "InUtero")     -- Start FSM.
  self:AddTransition("*",             "Stop",              "Stopped")     -- Stop FSM.

  self:AddTransition("*",             "FlightStatus",      "*")           -- FLIGHTGROUP status update.
  self:AddTransition("*",             "QueueUpdate",       "*")           -- Update task queue.
  
  self:AddTransition("*",             "DetectedUnit",      "*")           -- Add a newly detected unit to the detected units set.
  self:AddTransition("*",             "DetectedUnitNew",   "*")           -- Add a newly detected unit to the detected units set.
  self:AddTransition("*",             "DetectedUnitKnown", "*")           -- Add a newly detected unit to the detected units set.
  self:AddTransition("*",             "DetectedUnitLost",  "*")           -- Group lost a detected target.

  self:AddTransition("*",             "UpdateRoute",       "*")           -- Update route of group. Only if airborne.
  self:AddTransition("*",             "Respawn",           "*")           -- Respawn group.
  
  self:AddTransition("*",             "RTB",               "Returning")   -- Group is returning to base.
  self:AddTransition("*",             "Orbit",             "Orbiting")    -- Group is is orbiting.
  self:AddTransition("*",             "Hold",              "Inbound")     -- Group is inbound to holding pattern.
  self:AddTransition("Inbound",       "Holding",           "Holding")     -- Group is holding position.
  self:AddTransition("*",             "Refuel",            "Going2Refuel")  -- Group is send to refuel at a tanker.
  self:AddTransition("Going2Refuel",  "Refueling",         "Refueling")   -- Group is send to refuel at a tanker.
  self:AddTransition("*",             "LandAt",            "LandingAt")   -- Helo group is ordered to land at a specific point.
  self:AddTransition("LandingAt",     "LandedAt",          "LandedAt")    -- Helo group is landed at a specific point.

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
  self:AddTransition("*",             "ElementParking",   "*")           -- An element is parking.
  self:AddTransition("*",             "ElementEngineOn",  "*")           -- An element spooled up the engines.
  self:AddTransition("*",             "ElementTaxiing",   "*")           -- An element is taxiing to the runway.
  self:AddTransition("*",             "ElementTakeoff",   "*")           -- An element took off.
  self:AddTransition("*",             "ElementAirborne",  "*")           -- An element is airborne.
  self:AddTransition("*",             "ElementLanded",    "*")           -- An element landed.
  self:AddTransition("*",             "ElementArrived",   "*")           -- An element arrived.
  self:AddTransition("*",             "ElementDead",      "*")           -- An element crashed, ejected, or pilot dead.

  self:AddTransition("*",             "ElementOutOfAmmo", "*")           -- An element is completely out of ammo.
  
  self:AddTransition("*",             "CheckZone",        "*")           -- Check if flight enters/leaves a certain zone.
  self:AddTransition("*",             "EnterZone",        "*")           -- Flight entered a certain zone.
  self:AddTransition("*",             "LeaveZone",        "*")           -- Flight leaves a certain zone.

  self:AddTransition("*",             "FlightSpawned",    "Spawned")     -- The whole flight group was spawned.
  self:AddTransition("*",             "FlightParking",    "Parking")     -- The whole flight group is parking.
  self:AddTransition("*",             "FlightTaxiing",    "Taxiing")     -- The whole flight group is taxiing.
  self:AddTransition("*",             "FlightTakeoff",    "Airborne")    -- The whole flight group is airborne.
  self:AddTransition("*",             "FlightAirborne",   "Airborne")    -- The whole flight group is airborne.
  self:AddTransition("*",             "FlightLanding",    "Landing")     -- The whole flight group is landing.
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
    BASE:TraceOnOff(true)
    BASE:TraceClass(self.ClassName)
    BASE:TraceLevel(1)
  end


  -- Init task counter.
  self.taskcurrent=0
  self.taskcounter=0

  -- Holding flag.  
  self.flaghold=USERFLAG:New(string.format("%s_FlagHold", self.groupname))
  self.flaghold:Set(0)
  
  -- Add to data base.
  _DATABASE:AddFlightGroup(self)

  -- Autostart.
  if autostart==true or autostart==nil then
    self:Start()
  end

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Add a *scheduled* task.
-- @param #FLIGHTGROUP self
-- @param #number id Task id.
-- @return #string Name of the stop flag
function FLIGHTGROUP:StopTaskFlagname(id)
  return string.format("StopTaskFlag %d", id)
end

--- Add a *scheduled* task.
-- @param #FLIGHTGROUP self
-- @param #table task DCS task table structure.
-- @param #string clock Mission time when task is executed. Default in 5 seconds. If argument passed as #number, it defines a relative delay in seconds.
-- @param #string description Brief text describing the task, e.g. "Attack SAM".
-- @param #number prio Priority of the task.
-- @param #number duration Duration before task is cancelled in seconds counted after task started. Default never.
-- @return #number Task ID.
function FLIGHTGROUP:AddTask(task, clock, description, prio, duration)

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
  newtask.stopflag=USERFLAG:New(self:StopTaskFlagname(newtask.id))  
  newtask.stopflag:Set(0)
  
  
  -- Info.
  self:I(self.lid..string.format("Adding task %s scheduled at %s", newtask.description, UTILS.SecondsToClock(time, true)))

  -- Debug info.
  self:T2({newtask=newtask})

  -- Add to table.
  table.insert(self.taskqueue, newtask)

  return self.taskcounter
end

--- Add a *waypoint* task.
-- @param #FLIGHTGROUP self
-- @param #table task DCS task table stucture.
-- @param #number waypointindex Number of waypoint. Counting starts at one!
-- @param #string description Brief text describing the task, e.g. "Attack SAM". 
-- @param #number prio Priority of the task. Number between 1 and 100. Default is 50.
-- @param #number duration Duration before task is cancelled in seconds counted after task started. Default never.
-- @return #number Task ID.
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
  newtask.stopflag=USERFLAG:New(self:StopTaskFlagname(newtask.id))  
  newtask.stopflag:Set(0)

  self:T2({newtask=newtask})

  -- Add to table.
  table.insert(self.taskqueue, newtask)
  
  -- Info.
  self:I(self.lid..string.format("Adding WAYPOINT task %s at WP %d", newtask.description, newtask.waypoint))  
  
  -- Update route.
  self:__UpdateRoute(-1)

  return self.taskcounter
end

--- Add an *enroute* task.
-- @param #FLIGHTGROUP self
-- @param #table task DCS task table stucture.
function FLIGHTGROUP:AddTaskEnroute(task)
  if not self.taskenroute then
    self.taskenroute={}
  end
  table.insert(self.taskenroute, task)
end

--- Add an *enroute* task to attack targets in a certain **cicular** zone.
-- @param #FLIGHTGROUP self
-- @param Core.Zone#ZONE_RADIUS ZoneRadius The circular zone, where to engage targets.
-- @param #table TargetTypes (Optional) The target types, passed as a table, i.e. mind the cirly brackets {}. Default {"Air"}.
-- @param #number Priority (Optional) Priority. Default 0.
function FLIGHTGROUP:AddTaskEnrouteEngageTargetsInZone(ZoneRadius, TargetTypes, Priority)
  local Task=self.group:EnRouteTaskEngageTargetsInZone(ZoneRadius:GetVec2(), ZoneRadius:GetRadius(), TargetTypes, Priority)
  self:AddTaskEnroute(Task)
end


--- Remove task.
-- @param #FLIGHTGROUP self
-- @param #number taskid ID of the task to remove.
function FLIGHTGROUP:RemoveTask(taskid)

  for i=#self.taskqueue,1,-1 do
    local task=self.taskqueue[i] --#FLIGHTGROUP.Task
  
    if task.id==taskid then
    
      -- Remove task from queue.
      table.remove(self.taskqueue, i)
      
      -- Update route if this is a waypoint task.
      if task.type==FLIGHTGROUP.TaskType.WAYPOINT and task.status==FLIGHTGROUP.TaskStatus.SCHEDULED then
        self:__UpdateRoute(-1)
      end
      
      break
    end
  
  end

end

--- Set squadron the flight group belongs to.
-- @param #FLIGHTGROUP self
-- @param #boolean If true or nil, group get enroute task tanker. If false, not.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:SetTanker(swtich)
  self.istanker=true
  return self
end

--- Set squadron the flight group belongs to.
-- @param #FLIGHTGROUP self
-- @param Ops.Squadron#SQUADRON squadron The squadron object.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:SetSquadron(squadron)
  self:I(self.lid..string.format("Add flight to SQUADRON %s", squadron.squadronname))
  self.squadron=squadron
  return self
end

--- Get squadron the flight group belongs to.
-- @param #FLIGHTGROUP self
-- @return Ops.Squadron#SQUADRON The squadron object.
function FLIGHTGROUP:GetSquadron()
  return self.squadron
end

--- Define parking spots to be used by the flight group.
-- This is valid only for the specified airbase.
-- @param #FLIGHTGROUP self
-- @param #string airbasename Name of the airbase.
-- @param #table Table of parking spot numbers.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:SetParkingSpots(airbase, spots)
  self.parkingspots[airbase]=spots
  return self
end

--- Set the FLIGHTCONTROL controlling this flight group.
-- @param #FLIGHTGROUP self
-- @param Ops.FlightControl#FLIGHTCONTROL flightcontrol The FLIGHTCONTROL object.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:SetFlightControl(flightcontrol)
  self:I(self.lid..string.format("Setting FLIGHTCONTROL to airbase %s", flightcontrol.airbasename))
  
  -- Remove flight from previous FC.
  if self.flightcontrol and self.flightcontrol.airbasename~=flightcontrol.airbasename then
    self.flightcontrol:_RemoveFlight(self)
  end
  
  -- Set FC.
  self.flightcontrol=flightcontrol
  
  -- Add flight to all flights.
  table.insert(flightcontrol.flights, self)
  
  -- Update flight's F10 menu.
  if self.ai==false then
    self:_UpdateMenu()
  end
  
  return self
end

--- Get the FLIGHTCONTROL controlling this flight group.
-- @param #FLIGHTGROUP self
-- @return Ops.FlightControl#FLIGHTCONTROL The FLIGHTCONTROL object.
function FLIGHTGROUP:GetFlightControl()
  return self.flightcontrol
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
  return self.group
end

--- Get flight group name.
-- @param #FLIGHTGROUP self
-- @return #string Group name.
function FLIGHTGROUP:GetName()
  return self.group:GetName()
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

--- Check if flight is in state in utero.
-- @param #FLIGHTGROUP self
-- @return #boolean If true, flight is not spawned yet.
function FLIGHTGROUP:IsInUtero()
  return self:Is("InUtero")
end

--- Check if flight is in state spawned.
-- @param #FLIGHTGROUP self
-- @return #boolean If true, flight is spawned.
function FLIGHTGROUP:IsSpawned()
  return self:Is("Spawned")
end

--- Check if flight is parking.
-- @param #FLIGHTGROUP self
-- @return #boolean If true, flight is parking after spawned.
function FLIGHTGROUP:IsParking()
  return self:Is("Parking")
end

--- Check if flight is parking.
-- @param #FLIGHTGROUP self
-- @return #boolean If true, flight is taxiing after engine start up.
function FLIGHTGROUP:IsTaxiing()
  return self:Is("Taxiing")
end

--- Check if flight is airborne.
-- @param #FLIGHTGROUP self
-- @return #boolean If true, flight is airborne.
function FLIGHTGROUP:IsAirborne()
  return self:Is("Airborne")
end

--- Check if flight is landing.
-- @param #FLIGHTGROUP self
-- @return #boolean If true, flight is landing, i.e. on final approach.
function FLIGHTGROUP:IsLanding()
  return self:Is("Landing")
end

--- Check if flight has landed and is now taxiing to its parking spot.
-- @param #FLIGHTGROUP self
-- @return #boolean If true, flight has landed
function FLIGHTGROUP:IsLanded()
  return self:Is("Landed")
end

--- Check if flight has arrived at its destination parking spot.
-- @param #FLIGHTGROUP self
-- @return #boolean If true, flight has arrived at its destination and is parking.
function FLIGHTGROUP:IsArrived()
  return self:Is("Arrived")
end

--- Check if flight is inbound and traveling to holding pattern.
-- @param #FLIGHTGROUP self
-- @return #boolean If true, flight is holding.
function FLIGHTGROUP:IsInbound()
  return self:Is("Inbound")
end

--- Check if flight is holding and waiting for landing clearance.
-- @param #FLIGHTGROUP self
-- @return #boolean If true, flight is holding.
function FLIGHTGROUP:IsHolding()
  return self:Is("Holding")
end

--- Check if flight is refueling.
-- @param #FLIGHTGROUP self
-- @return #boolean If true, flight is refueling.
function FLIGHTGROUP:IsRefueling()
  return self:Is("Refueling")
end

--- Check if helo(!) flight is ordered to land at a specific point.
-- @param #FLIGHTGROUP self
-- @return #boolean If true, group has task to land somewhere.
function FLIGHTGROUP:IsLandingAt()
  return self:Is("LandingAt")
end

--- Check if helo(!) flight is currently landed at a specific point.
-- @param #FLIGHTGROUP self
-- @return #boolean If true, group is currently landed at the assigned position and waiting until task is complete.
function FLIGHTGROUP:IsLandedAt()
  return self:Is("LandedAt")
end


--- Check if flight is dead.
-- @param #FLIGHTGROUP self
-- @return #boolean If true, all units/elements of the flight are dead.
function FLIGHTGROUP:IsDead()
  return self:Is("Dead")
end

--- Check if flight is low on fuel.
-- @param #FLIGHTGROUP self
-- @return #boolean If true, flight is low on fuel.
function FLIGHTGROUP:IsFuelLow()
  return self.fuellow
end

--- Check if flight is critical on fuel.
-- @param #FLIGHTGROUP self
-- @return #boolean If true, flight is critical on fuel.
function FLIGHTGROUP:IsFuelCritical()
  return self.fuelcritical
end

--- Check if flight is alive.
-- @param #FLIGHTGROUP self
-- @return #boolean *true* if group is exists and is activated, *false* if group is exist but is NOT activated. *nil* otherwise, e.g. the GROUP object is *nil* or the group is not spawned yet.
function FLIGHTGROUP:IsAlive()

  if self.group then
    return self.group:IsAlive()
  end

  return nil
end

--- Activate a *late activated* group.
-- @param #FLIGHTGROUP self
-- @param #number delay (Optional) Delay in seconds before the group is activated. Default is immediately.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:Activate(delay)

  if self:IsAlive()==false then
    if delay then
      self:ScheduleOnce(delay, FLIGHTGROUP.Activate, self)
    else
      self.group:Activate()
    end
  end

  return self
end

--- Start an *uncontrolled* group.
-- @param #FLIGHTGROUP self
-- @param #number delay (Optional) Delay in seconds before the group is started. Default is immediately.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:StartUncontrolled(delay)

  if self:IsAlive() then
    self.group:StartUncontrolled(delay)
  else
    self:E(self.lid.."ERROR: Could not start uncontrolled group as it is NOT alive (yet)!")
  end

  return self
end

--- Set DCS task.
-- @param #FLIGHTGROUP self
-- @param #table DCSTask DCS task structure.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:SetTask(DCSTask)
  if self:IsAlive() then
    self.group:SetTask(DCSTask, 1)
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
    self.group:PushTask(DCSTask, 1)
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

--- Push DCS task.
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


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Start & Status
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after Start event. Starts the FLIGHTGROUP FSM and event handlers.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterStart(From, Event, To)

  -- Short info.
  local text=string.format("Starting flight group v%s", FLIGHTGROUP.version)
  self:I(self.lid..text)
  
  -- Check if the group is already alive and if so, add its elements.
  local group=GROUP:FindByName(self.groupname)
  
  
  if group then
  
    -- Set group object.
    self.group=group

    -- Get units of group.
    local units=group:GetUnits()

    -- Add elemets.
    for _,unit in pairs(units) do
      local element=self:AddElementByName(unit:GetName())
    end
    
    if not self.groupinitialized then
      self:_InitGroup()
    end
  
    if group:IsAlive() then
      
      -- Debug info.    
      self:I(self.lid..string.format("Found EXISTING and ALIVE group %s at start with %d/%d units/elements", group:GetName(), #units, #self.elements))
                     
      -- Trigger spawned event for all elements.
      for _,element in pairs(self.elements) do
        -- Add a little delay or the OnAfterSpawned function is not even initialized and will not be called.
        self:__ElementSpawned(0.1, element)    
      end
      
    else
      -- Debug info.    
      self:I(self.lid..string.format("Found EXISTING but LATE ACTIVATED group %s at start with %d/%d units/elements", group:GetName(), #units, #self.elements))
    end
    
  end    
  
  -- Handle events:
  self:HandleEvent(EVENTS.Birth,          self.OnEventBirth)
  self:HandleEvent(EVENTS.EngineStartup,  self.OnEventEngineStartup)
  self:HandleEvent(EVENTS.Takeoff,        self.OnEventTakeOff)
  self:HandleEvent(EVENTS.Land,           self.OnEventLanding)
  self:HandleEvent(EVENTS.EngineShutdown, self.OnEventEngineShutdown)
  self:HandleEvent(EVENTS.PilotDead,      self.OnEventPilotDead)
  self:HandleEvent(EVENTS.Ejection,       self.OnEventEjection)
  self:HandleEvent(EVENTS.Crash,          self.OnEventCrash)
  self:HandleEvent(EVENTS.RemoveUnit,     self.OnEventRemoveUnit)

  -- Start the status monitoring.
  self:__CheckZone(-1)
  self:__FlightStatus(-1)
end

--- On after Start event. Starts the FLIGHTGROUP FSM and event handlers.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterStop(From, Event, To)

  -- Handle events:
  self:UnHandleEvent(EVENTS.Birth)
  self:UnHandleEvent(EVENTS.EngineStartup)
  self:UnHandleEvent(EVENTS.Takeoff)
  self:UnHandleEvent(EVENTS.Land)
  self:UnHandleEvent(EVENTS.EngineShutdown)
  self:UnHandleEvent(EVENTS.PilotDead)
  self:UnHandleEvent(EVENTS.Ejection)
  self:UnHandleEvent(EVENTS.Crash)
  self:UnHandleEvent(EVENTS.RemoveUnit)
  
  self.CallScheduler:Clear()
  
  _DATABASE.FLIGHTGROUPS[self.groupname]=nil

  self:I(self.lid.."STOPPED! Unhandled events, cleared scheduler and removed from database.")
end


--- On after "FlightStatus" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterFlightStatus(From, Event, To)

  -- FSM state.
  local fsmstate=self:GetState()
  
  -- Check if group has detected any units.
  self:_CheckDetectedUnits()
  
  -- Check if flight began to taxi (if it was parking).
  if self:IsParking() then
    for _,_element in pairs(self.elements) do
      local element=_element --#FLIGHTGROUP.Element
      if element.parking then
      
        -- Get distance to assigned parking spot.
        local dist=element.unit:GetCoordinate():Get2DDistance(element.parking.Coordinate)
        
        -- If distance >10 meters or velocity of unit is >0, we consider the unit as taxiing.
        -- TODO: Check distance threshold! If element is taxiing, the parking spot is free again.
        --       When the next plane is spawned on this spot, collisions should be avoided!
        if dist>10 then --or element.unit:GetVelocityMPS()>0 then
          if element.status==FLIGHTGROUP.ElementStatus.ENGINEON then
            self:ElementTaxiing(element)
          end
        end
        
      else
        --self:E(self.lid..string.format("Element %s is in PARKING queue but has no parking spot assigned!", element.name))
      end
    end  
  end
  
  local nTaskTot, nTaskSched, nTaskWP=self:CountRemainingTasks()

  -- Short info.
  local text=string.format("Flight status %s [%d/%d]. Tasks=%d (%d,%d) Current=%d. Waypoint=%d/%d. Detected=%d. FC=%s. Destination=%s",
  fsmstate, #self.elements, #self.elements, nTaskTot, nTaskSched, nTaskWP, self.taskcurrent, self.currentwp or 0, self.waypoints and #self.waypoints or 0, 
  self.detectedunits:Count(), self.flightcontrol and self.flightcontrol.airbasename or "none", self.destbase and self.destbase:GetName() or "unknown")
  self:I(self.lid..text)

  -- Element status.
  text="Elements:"
  local fuelmin=999999
  for i,_element in pairs(self.elements) do
    local element=_element --#FLIGHTGROUP.Element
    
    local name=element.name
    local status=element.status
    local unit=element.unit
    local fuel=unit:GetFuel() or 0
    local life=unit:GetLifeRelative() or 0
    local parking="X"
    if element.parking then
      parking=tostring(element.parking.TerminalID)
    end
    
    if fuel*100<fuelmin then
      fuelmin=fuel*100
    end

    -- Check if element is not dead and we missed an event.
    if life<0 and element.status~=FLIGHTGROUP.ElementStatus.DEAD and element.status~=FLIGHTGROUP.ElementStatus.INUTERO then
      self:ElementDead(element)
    end
    
    -- Get ammo.
    local nammo=0; local nshells=0 ; local nrockets=0; local nbombs=0; local nmissiles=0
    if element.status~=FLIGHTGROUP.ElementStatus.DEAD then
      nammo, nshells, nrockets, nbombs, nmissiles=self:GetAmmoElement(element)
    end

    -- Output text for element.
    text=text..string.format("\n[%d] %s: status=%s, fuel=%.1f, life=%.1f, shells=%d, rockets=%d, bombs=%d, missiles=%d, parking=%s", i, name, status, fuel*100, life*100, nshells, nrockets, nbombs, nmissiles, parking)
  end
  if #self.elements==0 then
    text=text.." none!"
  end
  self:I(self.lid..text)
  
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
    if task.type==FLIGHTGROUP.TaskType.SCHEDULED then
      text=text..string.format("\n[%d] %s: %s: status=%s, scheduled=%s (%d sec), started=%s, duration=%d", i, taskid, name, status, clock, eta, started, duration)
    elseif task.type==FLIGHTGROUP.TaskType.WAYPOINT then
      text=text..string.format("\n[%d] %s: %s: status=%s, waypoint=%d, started=%s, duration=%d, stopflag=%d", i, taskid, name, status, task.waypoint, started, duration, task.stopflag:Get())
    end
  end
  if #self.taskqueue>0 then
    self:I(self.lid..text)
  end


  -- Next check in ~30 seconds.
  self:__FlightStatus(-30)
end

--- On after "QueueUpdate" event.
-- @param #FLIGHTGROUP self
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

--- On after "CheckZone" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterCheckZone(From, Event, To)

  if self:IsAlive()==true then
    self:_CheckInZones()
  end

  if not self:IsDead() then
    self:__CheckZone(-1)
  end
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

    -- Set group.
    self.group=self.group or EventData.IniGroup
    
    if not self.groupinitialized then
      self:_InitGroup()
    end
    
    if self.respawning then
    
      local function reset()
        self.respawning=nil
      end
      
      -- Reset switch in 1 sec. This should allow all birth events of n>1 groups to have passed.
      -- TODO: Can I do this more rigorously?
      self:ScheduleOnce(1, reset)
    
    else
    
      -- Set homebase if not already set.
      if EventData.Place then
        self.homebase=self.homebase or EventData.Place
      end
          
      -- Get element.
      local element=self:GetElementByName(unitname)
  
      -- Create element spawned event if not already present.
      if not self:_IsElement(unitname) then
        element=self:AddElementByName(unitname)
      end
        
      -- Set element to spawned state.
      self:I(self.lid..string.format("EVENT: Element %s born ==> spawned", element.name))            
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
    
      if self:IsAirborne() or self:IsInbound() or self:IsHolding() then
        -- TODO: what?
      else
        self:T(self.lid..string.format("EVENT: Element %s started engines ==> taxiing (if AI)", element.name))
        -- TODO: could be that this element is part of a human flight group.
        -- Problem: when player starts hot, the AI does too and starts to taxi immidiately :(
        --          when player starts cold, ?
        if self.ai then
          self:ElementEngineOn(element)
        else
          if element.ai then
            -- AI wingmen will start taxiing even if the player/client is still starting up his engines :(
            self:ElementEngineOn(element)
          end
        end
      end
      
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
      self:T3(self.lid..string.format("EVENT: Element %s took off ==> airborne", element.name))
      self:ElementTakeoff(element, EventData.Place)
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
      self:T3(self.lid..string.format("EVENT: Element %s landed at %s ==> landed", element.name, airbasename))
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
    
        local airbase=element.unit:GetCoordinate():GetClosestAirbase()
        local parking=self:GetParkingSpot(element, 10, airbase)
        
        if airbase and parking then
          self:ElementArrived(element, airbase, parking)
          self:T3(self.lid..string.format("EVENT: Element %s shut down engines ==> arrived", element.name))
        else
          self:T3(self.lid..string.format("EVENT: Element %s shut down engines (in air) ==> dead", element.name))
          self:ElementDead(element)
        end
        
      else
      
        self:T(self.lid..string.format("EVENT: Element %s shut down engines but is NOT alive ==> waiting for crash event (==> dead)", element.name))

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
      self:T3(self.lid..string.format("EVENT: Element %s crashed ==> dead", element.name))
      self:ElementDead(element)
    end

  end

end

--- Flightgroup event function handling the crash of a unit.
-- @param #FLIGHTGROUP self
-- @param Core.Event#EVENTDATA EventData Event data.
function FLIGHTGROUP:OnEventRemoveUnit(EventData)

  -- Check that this is the right group.
  if EventData and EventData.IniGroup and EventData.IniUnit and EventData.IniGroupName and EventData.IniGroupName==self.groupname then
    local unit=EventData.IniUnit
    local group=EventData.IniGroup
    local unitname=EventData.IniUnitName

    -- Get element.
    local element=self:GetElementByName(unitname)

    if element then
      self:T3(self.lid..string.format("EVENT: Element %s removed ==> dead", element.name))
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
  self:I(self.lid..string.format("Element spawned %s", Element.name))

  -- Set element status.
  self:_UpdateStatus(Element, FLIGHTGROUP.ElementStatus.SPAWNED)

  if Element.unit:InAir() then
    -- Trigger ElementAirborne event. Add a little delay because spawn is also delayed!
    self:__ElementAirborne(0.11, Element)
  else
      
    -- Get parking spot.
    local spot=self:GetParkingSpot(Element, 10)
    
    if spot then
    
      -- Set 
      Element.parking=spot
      
      -- Trigger ElementParking event. Add a little delay because spawn is also delayed!
      self:__ElementParking(0.11, Element)
    else
      self:E(self.lid..string.format("Element spawned not in air but not on any parking spot."))
    end
  end
end

--- On after "ElementParking" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #FLIGHTGROUP.Element Element The flight group element.
function FLIGHTGROUP:onafterElementParking(From, Event, To, Element)
  self:I(self.lid..string.format("Element parking %s at spot %s", Element.name, tostring(Element.parking.TerminalID)))
  
  -- Set element status.
  self:_UpdateStatus(Element, FLIGHTGROUP.ElementStatus.PARKING)
  
  if self:IsTakeoffCold() then
    -- Wait for engine startup event.
  elseif self:IsTakeoffHot() then
    self:__ElementEngineOn(0.5, Element)  -- delay a bit to allow all elements
  elseif self:IsTakeoffRunway() then
    self:__ElementEngineOn(0.5, Element)
  end
end

--- On after "ElementEngineOn" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #FLIGHTGROUP.Element Element The flight group element.
function FLIGHTGROUP:onafterElementEngineOn(From, Event, To, Element)

  -- Debug info.
  self:I(self.lid..string.format("Element %s started engines", Element.name))

  -- Set element status.
  self:_UpdateStatus(Element, FLIGHTGROUP.ElementStatus.ENGINEON)
end

--- On after "ElementTaxiing" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #FLIGHTGROUP.Element Element The flight group element.
function FLIGHTGROUP:onafterElementTaxiing(From, Event, To, Element)

  -- Get terminal ID.
  local TerminalID=Element.parking and tostring(Element.parking.TerminalID) or "N/A"
  
  -- Remove marker.
  if self.flightcontrol and Element.parking then
    local parking=self.flightcontrol.parking[Element.parking.TerminalID]  --Wrapper.Airbase#AIRBASE.ParkingSpot
    if parking and parking.MarkerID then
      parking.Coordinate:RemoveMark(parking.MarkerID)
    end
  end

  -- Debug info.
  self:I(self.lid..string.format("Element taxiing %s. Parking spot %s is now free", Element.name, TerminalID))
  
  -- Not parking any more.
  Element.parking=nil

  -- Set element status.
  self:_UpdateStatus(Element, FLIGHTGROUP.ElementStatus.TAXIING)
end

--- On after "ElementTakeoff" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #FLIGHTGROUP.Element Element The flight group element.
-- @param Wrapper.Airbase#AIRBASE airbase The airbase if applicable or nil.
function FLIGHTGROUP:onafterElementTakeoff(From, Event, To, Element, airbase)
  self:T(self.lid..string.format("Element takeoff %s at %s airbase.", Element.name, airbase and airbase:GetName() or "unknown"))

  -- Set element status.
  self:_UpdateStatus(Element, FLIGHTGROUP.ElementStatus.TAKEOFF, airbase)
  
  -- Trigger element airborne event.
  self:__ElementAirborne(10, Element)
end

--- On after "ElementAirborne" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #FLIGHTGROUP.Element Element The flight group element.
function FLIGHTGROUP:onafterElementAirborne(From, Event, To, Element)
  self:T2(self.lid..string.format("Element airborne %s", Element.name))

  -- Set element status.
  self:_UpdateStatus(Element, FLIGHTGROUP.ElementStatus.AIRBORNE)
end

--- On after "ElementLanded" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #FLIGHTGROUP.Element Element The flight group element.
-- @param Wrapper.Airbase#AIRBASE airbase The airbase if applicable or nil.
function FLIGHTGROUP:onafterElementLanded(From, Event, To, Element, airbase)
  self:T2(self.lid..string.format("Element landed %s at %s airbase", Element.name, airbase and airbase:GetName() or "unknown"))

  -- Set element status.
  self:_UpdateStatus(Element, FLIGHTGROUP.ElementStatus.LANDED, airbase)
end

--- On after "ElementArrived" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #FLIGHTGROUP.Element Element The flight group element.
-- @param Wrapper.Airbase#AIRBASE airbase The airbase, where the element arrived.
-- @param Wrapper.Airbase#AIRBASE.ParkingSpot Parking The Parking spot the element has.
function FLIGHTGROUP:onafterElementArrived(From, Event, To, Element, airbase, Parking)
  self:I(self.lid..string.format("Element arrived %s at %s airbase using parking spot %d", Element.name, airbase and airbase:GetName() or "unknown", Parking and Parking.TerminalID or -99))  


  -- Get parking spot  
  --local parking=self:GetParkingSpot(Element, 10, self.flightcontrol and self.flightcontrol.airbase or nil)
  
  -- Element is parking here.
  Element.parking=Parking
  
  if Parking then
    if self.flightcontrol then
      local spot=self.flightcontrol.parking[Parking.TerminalID] --Wrapper.Airbase#AIRBASE.ParkingSpot
      self:I(self.lid..string.format("Element arrived %s at %s on parking spot %s reserved for %s", Element.name, Parking.AirbaseName, Parking.TerminalID, tostring(spot.Reserved)))
      if spot.Reserved then
        if spot.Reserved==Element.name then
          spot.Reserved=nil
        else
          self:E(self.lid..string.format("WARNING: Parking spot was not reserved for this element!"))
        end
      end
    end
  end

  -- Set element status.
  self:_UpdateStatus(Element, FLIGHTGROUP.ElementStatus.ARRIVED)
end

--- On after "ElementDead" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #FLIGHTGROUP.Element Element The flight group element.
function FLIGHTGROUP:onafterElementDead(From, Event, To, Element)
  self:I(self.lid..string.format("Element dead %s.", Element.name))
  
  -- Not parking any more.
  Element.parking=nil

  -- Set element status.
  self:_UpdateStatus(Element, FLIGHTGROUP.ElementStatus.DEAD)
end

--- Initialize group parameters.
-- @param #FLIGHTGROUP self
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:_InitGroup()

  if self.groupinitialized then
    self:E(self.lid.."WARNING: Group was already initialized!")
    return
  end

  -- Get template of group.
  self.template=self.group:GetTemplate()
  
  -- Max speed in km/h.
  self.speedmax=self.group:GetSpeedMax()
  
  local unit=self.group:GetUnit(1)
  
  --local nunits=self.group:GetUnits()
  
  self.descriptors=unit:GetDesc()
  
  self.actype=unit:GetTypeName()
  
  self.ceiling=self.descriptors.Hmax
  
  self.ai=not self:_IsHuman(self.group)
  
  for _,_element in pairs(self.elements) do
    local element=_element --#FLIGHTGROUP.Element
    element.ai=not self:_IsHumanUnit(element.unit)
  end

  -- Init waypoints.
  if not self.waypoints then
    self:InitWaypoints()
  end
  
  -- Debug info.
  local text=string.format("Initialized Flight Group %s:\n", self.groupname)
  text=text..string.format("AC type      = %s\n", self.actype)
  text=text..string.format("Speed max    = %.1f Knots\n", UTILS.KmphToKnots(self.speedmax))
  text=text..string.format("Ceiling      = %.1f feet\n", UTILS.MetersToFeet(self.ceiling))
  text=text..string.format("AI           = %s\n", tostring(self.ai))
  text=text..string.format("Helicopter   = %s\n", tostring(self.group:IsHelicopter()))
  text=text..string.format("Elements     = %d\n", #self.elements)
  text=text..string.format("Waypoints    = %d\n", #self.waypoints)
  text=text..string.format("FSM state    = %s\n", self:GetState())
  text=text..string.format("Is alive     = %s\n", tostring(self.group:IsAlive()))
  text=text..string.format("Late activat = %s\n", tostring(self:IsLateActivated()))
  text=text..string.format("Uncontrolled = %s\n", tostring(self:IsUncontrolled()))
  text=text..string.format("Start Air    = %s\n", tostring(self:IsTakeoffAir()))
  text=text..string.format("Start Cold   = %s\n", tostring(self:IsTakeoffCold()))
  text=text..string.format("Start Hot    = %s\n", tostring(self:IsTakeoffHot()))
  text=text..string.format("Start Rwy    = %s\n", tostring(self:IsTakeoffRunway()))    
  self:I(self.lid..text)
  
  -- Init done.
  self.groupinitialized=true
  
  return self
end


--- On after "FlightSpawned" event. Sets the template, initializes the waypoints.
-- @param #FLIGHTGROUP self
-- @param Wrapper.Group#GROUP Group Flight group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterFlightSpawned(From, Event, To)
  self:I(string.format("FF Flight group %s spawned!", tostring(self.groupname)))

  -- F10 menu.
  if not self.ai then
    self.menu=self.menu or {}
    self.menu.atc=self.menu.atc or {}
    self.menu.atc.root=self.menu.atc.root or MENU_GROUP:New(self.group, "ATC")
    self:_UpdateMenu()
  end  
    
end

--- On after "FlightParking" event. Add flight to flightcontrol of airbase.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterFlightParking(From, Event, To)
  self:T(self.lid..string.format("Flight is parking %s.", self.groupname))

  local airbase=self.group:GetCoordinate():GetClosestAirbase()
  
  local airbasename=airbase:GetName() or "unknown"
  
  -- Parking time stamp.
  self.Tparking=timer.getAbsTime()

  -- Get FC of this airbase.
  local flightcontrol=_DATABASE:GetFlightControl(airbasename)
  
  if flightcontrol then
  
    -- Set FC for this flight
    self:SetFlightControl(flightcontrol)
  
    if self.flightcontrol then
    
      -- Add flight to parking queue, waiting for takeoff cleance.
      self.flightcontrol:_AddFlightToParkingQueue(self)
      
    end
  end  
end


--- On after "FlightTaxiing" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterFlightTaxiing(From, Event, To)
  self:T(self.lid..string.format("Flight is taxiing %s.", self.groupname))
  
  -- Parking over.
  self.Tparking=nil

  -- TODO: need a better check for the airbase.
  local airbase=self.group:GetCoordinate():GetClosestAirbase(nil, self.group:GetCoalition())

  if self.flightcontrol and airbase and self.flightcontrol.airbasename==airbase:GetName() then    
    -- Remove flight from parking queue.
    self.flightcontrol:_RemoveFlightFromQueue(self.flightcontrol.Qparking, self, "parking")

    -- Add AI flight to takeoff queue.
    if self.ai then
      -- AI flights go directly to TAKEOFF as we don't know when they finished taxiing.
      self.flightcontrol:_AddFlightToTakeoffQueue(self)
    else
      -- Human flights go to TAXI OUT queue. They will go to the ready for takeoff queue when they request it.
      self.flightcontrol:_AddFlightToTaxiOutQueue(self)    
    end
    
  end

end

--- On after "FlightTakeoff" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Airbase#AIRBASE airbase The airbase the flight landed.
function FLIGHTGROUP:onafterFlightTakeoff(From, Event, To, airbase)
  self:T(self.lid..string.format("Flight takeoff %s at %s.", self.groupname, airbase and airbase:GetName() or "unknown airbase"))

  -- Remove flight from all FC queues.
  if self.flightcontrol and airbase and self.flightcontrol.airbasename==airbase:GetName() then
    self.flightcontrol:_RemoveFlight(self)
    self.flightcontrol=nil
  end
  
  -- Trigger airborne event.
  self:__FlightAirborne(1, airbase)
  
end

--- On after "FlightAirborne" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Airbase#AIRBASE airbase The airbase the flight landed.
function FLIGHTGROUP:onafterFlightAirborne(From, Event, To, airbase)
  self:T(self.lid..string.format("Flight airborne %s at %s.", self.groupname,airbase and airbase:GetName() or "unknown airbase"))

  local task=nil
  if self.istanker then
    task=self.group:EnRouteTaskTanker()
  end
  if self.isawacs then
    task=self.group:EnRouteTaskAWACS()
  end
  
  if task then
    self:PushTask(task, 0.1)
  end
  
  -- Update queue.
  self:__QueueUpdate(-1)
end

--- On after "FlightLanding" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterFlightLanding(From, Event, To)
  self:T(self.lid..string.format("Flight landing %s", self.groupname))

  self:_SetElementStatusAll(FLIGHTGROUP.ElementStatus.LANDING)
  
end

--- On after "FlightLanded" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Airbase#AIRBASE airbase The airbase the flight landed.
function FLIGHTGROUP:onafterFlightLanded(From, Event, To, airbase)
  self:T(self.lid..string.format("Flight landed %s at %s.", self.groupname, airbase and airbase:GetName() or "unknown airbase"))

  if self:IsLandingAt() then
    self:LandedAt()
  else
    -- Remove flight from landing queue.
    if self.flightcontrol and airbase and self.flightcontrol.airbasename==airbase:GetName() then
      self.flightcontrol:_RemoveFlightFromQueue(self.flightcontrol.Qlanding, self, "LANDING")
      -- Add flight to taxiinb queue.
      self.flightcontrol:_AddFlightToTaxiInboundQueue(self)
    end
  end
end

--- On after "FlightArrived" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterFlightArrived(From, Event, To)
  self:T(self.lid..string.format("Flight arrived %s", self.groupname))

  -- Remove flight from landing queue.
  if self.flightcontrol then
    self.flightcontrol:_RemoveFlightFromQueue(self.flightcontrol.Qtaxiinb, self, "TAXI_INB")
    -- Add flight to arrived queue.
    self.flightcontrol:_AddFlightToArrivedQueue(self)
  end
  
end

--- On after "FlightDead" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterFlightDead(From, Event, To)
  self:T(self.lid..string.format("Flight dead %s", self.groupname))

  -- Delete waypoints so they are re-initialized at the next spawn.
  self.waypoints=nil
  self.groupinitialized=false
  
  -- Remove flight from all FC queues.
  if self.flightcontrol then
    self.flightcontrol:_RemoveFlight(self)
    self.flightcontrol=nil
  end  
  
  -- Stop
  self:Stop()
end


--- On before "UpdateRoute" event. Update route of group, e.g after new waypoints and/or waypoint tasks have been added.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number n Waypoint number.
-- @return #boolean Transision allowed?
function FLIGHTGROUP:onbeforeUpdateRoute(From, Event, To, n)

  -- Is transition allowed? We assume yes until proven otherwise.
  local allowed=true

  if self.group and self.group:IsAlive() and self:IsAirborne() then
    -- Alive & Airborne ==> Update route possible.
    self:T2(self.lid.."Update route possible. Group is ALIVE and AIRBORNE")
  elseif self:IsDead() then
    -- Group is dead! No more updates.
    self:T3(self.lid.."FF update route denied. Group is DEAD!")
    allowed=false
  else
    -- Not airborne yet. Try again in 1 sec.
    self:T3(self.lid.."FF update route denied ==> checking back in 1 sec")
    self:__UpdateRoute(-1, n)
    allowed=false
  end
  
  if n and n<1 then
    self:T3(self.lid.."FF update route denied because n<1")
    self:__UpdateRoute(-1, n)
    allowed=false  
  end
  
  if not self.currentwp then
    self:T3(self.lid.."FF update route denied because self.currentwp=nil")
    self:__UpdateRoute(-1, n)
    allowed=false    
  end
  
  local N=n or self.currentwp+1
  if not N or N<1 then
    self:T3(self.lid.."FF update route denied because N=nil or N<1")
    self:__UpdateRoute(-1, n)
    allowed=false    
  end
  

  return allowed
end

--- On after "UpdateRoute" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number n Waypoint number.
function FLIGHTGROUP:onafterUpdateRoute(From, Event, To, n)

  env.info(string.format("FF Update route n=%s current wp=%s", tostring(n), tostring(self.currentwp)))

  -- TODO: what happens if currentwp=#waypoints
  n=n or self.currentwp+1

  -- Debug info.
  local text=string.format("Updating route n=%d for group %s", n, self.groupname)
  MESSAGE:New(text, 10):ToAll()
  self:I(self.lid..text)
  
  
  -- Update waypoint tasks, i.e. inject WP tasks into waypoint table.
  self:_UpdateWaypointTasks()

  -- Waypoints.
  local wp={}
  
  -- Set current waypoint or we get problem that the _PassingWaypoint function is triggered too early, i.e. right now and not when passing the next WP.
  -- TODO: This, however, leads to the flight to go right over this point when it is on an airport ==> Need to test Waypoint takeoff
  local current=self.group:GetCoordinate():WaypointAir(nil, COORDINATE.WaypointType.TurningPoint, COORDINATE.WaypointAction.TurningPoint, 350, true, nil, {}, "Current")
  table.insert(wp, current)

  -- Set "remaining" waypoits.
  for i=n, #self.waypoints do
    local w=self.waypoints[i]
    if self.Debug then
      --self:GetWaypointCoordinate(w):MarkToAll(string.format("UpdateRoute Waypoint %d", i))
    end
    self:I({i=i, waypoint=w})
    table.insert(wp, w)
  end
  
  
  if self.destbase and #wp>0 and _DATABASE:GetFlightControl(self.destbase:GetName()) then
  
    -- Task to hold.
    local TaskOverhead=self.group:TaskFunction("FLIGHTGROUP._DestinationOverhead", self, self.destbase)
    
    -- Random overhead coordinate at destination.
    local coordoverhead=self.destbase:GetZone():GetRandomCoordinate():SetAltitude(UTILS.FeetToMeters(6000))
  
    -- Add overhead waypoint.
    local wpoverhead=coordoverhead:WaypointAir(nil, COORDINATE.WaypointType.TurningPoint, COORDINATE.WaypointAction.FlyoverPoint, 500, false, nil, {TaskOverhead}, "Destination Overhead")
    
    -- Debug info.
    self:T(self.lid..string.format("Adding overhead waypoint as #%d", #wp))
    
    -- Add overhead to waypoints.
    table.insert(wp, #wp, wpoverhead)
  end

  -- Looks like waypoint tasks are not executed if the final waypoint is in air. Need to add another dummy waypoint to make it work properly.
  local lastwp=wp[#wp]
  if self:IsLandingAir(lastwp) then
    local tasks=self:GetTasksWaypoint(#wp)
    if tasks and #tasks>0 then
      --env.info("FF adding dummy waypoint")
      --table.insert(wp, current)
    end
  end  
  
  -- Debug info.
  local hb=self.homebase and self.homebase:GetName() or "unknown"
  local db=self.destbase and self.destbase:GetName() or "unknown"
  self:I(self.lid..string.format("Updating route for WP>=%d/%d (%d) homebase=%s destination=%s", n, #wp, #self.waypoints, hb, db))



  
  if #wp>0 then

    -- Route group to all defined waypoints remaining.
    self.group:Route(wp, 1)

    if self.taskenroute then
      for _,task in pairs(self.taskenroute) do
        self:I(self.lid..string.format("Pushing enroute task %s", tostring(task.id)))
        self:PushTask(task, 1.1)
        --table.insert(taskswp, task)
      end
    end
    
  else
  
    ---
    -- No waypoints left
    ---
  
    self:E(self.lid.."WARNING: No waypoints left. Dunno what to do!")
  
    -- Get destination or home airbase.
    local airbase=self.destbase or self.homebase
    
    if self:IsAirborne() then
    
      -- TODO: check if no more scheduled tasks.
      
      if airbase then
          -- Route flight to destination/home.
          --self:RTB(airbase)        
      else
        -- Let flight orbit.
        --self:Orbit(self.group:GetCoordinate(), UTILS.FeetToMeters(20000), self.group:GetSpeedMax()*0.4)
      end
      
    end
    
  end

end

--- On after "Respawn" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #table Template The template used to respawn the group.
function FLIGHTGROUP:onafterRespawn(From, Event, To, Template)

  local template=UTILS.DeepCopy(Template or self.template)
  
  if self.group and self.group:InAir() then
    template.lateActivation=false
    self.respawning=true
    self.group=self.group:Respawn(template)
  end

end

--- On after "PassingWaypoint" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number n Waypoint number passed.
-- @param #number N Final waypoint number.
function FLIGHTGROUP:onafterPassingWaypoint(From, Event, To, n, N)
  local text=string.format("Flight %s passed waypoint %d/%d", self.groupname, n, N)
  self:I(self.lid..text)
  MESSAGE:New(text, 30, "DEBUG"):ToAllIf(self.Debug)
  
  local tasks=self:GetTasksWaypoint(n)
  
  local text=string.format("WP %d/%d tasks:", n, N)
  if tasks then
    for i,_task in pairs(tasks) do
      local task=_task --#FLIGHTGROUP.Task
      text=text..string.format("\n[%d] %s", i, task.description)
    end
  else
    text=text.." None"
  end
  self:I(self.lid..text)
  

  -- Tasks at this waypoints.
  local taskswp={}

  -- Enroute tasks
  if self.taskenroute and false then
    for _,taskE in pairs(self.taskenroute) do
      self:I(self.lid..string.format("Adding enroute task %s", tostring(taskE.id)))
      table.insert(taskswp, taskE)
    end
  end
    
  for _,task in pairs(tasks) do
    local Task=task --#FLIGHTGROUP.Task          
    
    -- Task execute.
    table.insert(taskswp, self.group:TaskFunction("FLIGHTGROUP._TaskExecute", self, Task))

    -- Stop condition if userflag is set to 1.    
    local TaskCondition=self.group:TaskCondition(nil, Task.stopflag:GetName(), 1, nil, Task.duration)
    
    -- Controlled task.      
    --table.insert(taskswp, self.group:TaskControlled(Task.dcstask, TaskCondition))
    
     table.insert(taskswp, Task.dcstask)
    
    -- Task done.
    table.insert(taskswp, self.group:TaskFunction("FLIGHTGROUP._TaskDone", self, Task))
    
  end
    
  
  -- At the final AIR waypoint, we set the flight to hold.
  if self.destbase and n>1 and n==N-1 then
    self:__Hold(-1, self.destbase)
  else
    -- Waypoint task combo.
    if #taskswp>0 then
      self:SetTask(self.group:TaskCombo(taskswp))
    end    
  end
  
end

--- On after "FuelLow" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterFuelLow(From, Event, To)

  -- Debug message.
  local text=string.format("Low fuel for flight group %s", self.groupname)
  MESSAGE:New(text, 30, "DEBUG"):ToAllIf(self.Debug)
  self:I(self.lid..text)
  
  -- Set switch to true.
  self.fuellow=true

  -- Route helo back home. It is respawned! But this is the only way to ensure that it actually lands at the airbase.
  local airbase=self.destbase or self.homebase
  
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
  MESSAGE:New(text, 30, "DEBUG"):ToAllIf(self.Debug)
  self:I(self.lid..text)
  
  -- Set switch to true.
  self.fuelcritical=true

  -- Route helo back home. It is respawned! But this is the only way to ensure that it actually lands at the airbase.
  local airbase=self.destbase or self.homebase
  
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
  MESSAGE:New(text, 30, "DEBUG"):ToAllIf(self.Debug)
  self:I(self.lid..text)

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
  MESSAGE:New(text, 30, "DEBUG"):ToAllIf(self.Debug)
  self:I(self.lid..text)
  
  --TODO: set ROE passive. introduce roe event/state/variable.
  
  local TaskOrbit=self.group:TaskOrbit(Coord, Altitude, UTILS.KmphToMps(Speed))

  self:SetTask(TaskOrbit)
end

--- On before "Hold" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Airbase#AIRBASE airbase The airbase to hold at.
-- @param #number SpeedTo Speed used for travelling from current position to holding point in knots.
-- @param #number SpeedHold Holding speed in knots.
function FLIGHTGROUP:onbeforeHold(From, Event, To, airbase, SpeedTo, SpeedHold)

  local allowed=true
  local Tsuspend=nil

  if airbase==nil then
    self:E(self.lid.."ERROR: Airbase is nil in Hold() call!")
    allowed=false
  end

  -- Check that coaliton is okay. We allow same (blue=blue, red=red) or landing on neutral bases.
  if airbase and airbase:GetCoalition()~=self.group:GetCoalition() and airbase:GetCoalition()>0 then
    self:E(self.lid.."ERROR: Wrong airbase coalition in Hold() call! We allow only same as group or neutral airbases.")
    allowed=false
  end

  -- Check if there are remaining tasks.
  local Ntot,Nsched, Nwp=self:CountRemainingTasks()

  if self.taskcurrent>0 then
    self:I(self.lid..string.format("WARNING: Got current task ==> Hold event is suspended for 10 sec."))
    Tsuspend=-10
    allowed=false
  end
  
  if Nsched>0 then
    self:I(self.lid..string.format("WARNING: Still got %d SCHEDULED tasks in the queue ==> Hold event is suspended for 10 sec.", Nsched))
    Tsuspend=-10
    allowed=false
  end

  if Nwp>0 then
    self:I(self.lid..string.format("WARNING: Still got %d WAYPOINT tasks in the queue ==> Hold event is suspended for 10 sec.", Nsched))
    Tsuspend=-10
    allowed=false
  end
  
  if Tsuspend and not allowed then
    self:__Hold(Tsuspend, airbase, SpeedTo, SpeedHold)  
  end
  
  return allowed
end

--- On after "Hold" event. Order flight to hold at an airbase and wait for signal to land.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Airbase#AIRBASE airbase The airbase to hold at.
-- @param #number SpeedTo Speed used for travelling from current position to holding point in knots. Default 350 kts.
-- @param #number SpeedHold Holding speed in knots. Default 250 kts.
-- @param #number SpeedLand Landing speed in knots. Default 170 kts.
function FLIGHTGROUP:onafterHold(From, Event, To, airbase, SpeedTo, SpeedHold, SpeedLand)
  
  -- Defaults:
  SpeedTo=SpeedTo or 350
  SpeedHold=SpeedHold or 250
  local SpeedLand=170

  -- Debug message.
  local text=string.format("Flight group set to hold at airbase %s", airbase:GetName())
  MESSAGE:New(text, 10, "DEBUG"):ToAllIf(self.Debug)
  self:I(self.lid..text)
 
  
  -- Holding points.
  local p0=airbase:GetZone():GetRandomCoordinate():SetAltitude(UTILS.FeetToMeters(6000))
  local p1=nil
  local wpap=nil
  
  -- Do we have a flight control?
  local fc=_DATABASE:GetFlightControl(airbase:GetName())
  if fc then
    -- Get holding point from flight control.
    local HoldingPoint=fc:_GetHoldingpoint(self)
    p0=HoldingPoint.pos0
    p1=HoldingPoint.pos1
    
    -- Debug marks.
    if self.Debug then
      p0:MarkToAll("Holding point P0")
      p1:MarkToAll("Holding point P1")
    end
    
    -- Set flightcontrol for this flight.
    self:SetFlightControl(fc)
    
    -- Add flight to inbound queue.
    self.flightcontrol:_AddFlightToInboundQueue(self)
  end
  
   -- Altitude above ground for a glide slope of 3�.
  local alpha=math.rad(3)
  local x1=UTILS.NMToMeters(10)
  local x2=UTILS.NMToMeters(5)
  local h1=x1*math.tan(alpha)
  local h2=x2*math.tan(alpha)
  local SpeedLand=140
  local SpeedTo=180
  
  local runway=airbase:GetActiveRunway()
  
  -- Clear all tasks.
  self.group:ClearTasks()
  
  -- Set holding flag to 333.
  self.flaghold:Set(333)
  
  -- Task fuction when reached holding point.
  local TaskArrived=self.group:TaskFunction("FLIGHTGROUP._ReachedHolding", self)

  -- Orbit until flaghold=1 (=true)
  local TaskOrbit=self.group:TaskOrbit(p0, nil, UTILS.KnotsToMps(SpeedHold), p1)
  local TaskStop=self.group:TaskCondition(nil, self.flaghold.UserFlagName, 1, nil, 10*60)  
  local TaskControlled=self.group:TaskControlled(TaskOrbit, TaskStop)
  
  -- Waypoints.
  local wp={}
  wp[#wp+1]=self.group:GetCoordinate():WaypointAir(nil, COORDINATE.WaypointType.TurningPoint, COORDINATE.WaypointAction.FlyoverPoint, UTILS.KnotsToKmph(SpeedTo), true , nil, {}, "Current Pos")
  wp[#wp+1]=                        p0:WaypointAir(nil, COORDINATE.WaypointType.TurningPoint, COORDINATE.WaypointAction.FlyoverPoint, UTILS.KnotsToKmph(SpeedTo), true , nil, {TaskArrived, TaskControlled}, "Holding Point")
  
   -- Approach point: 10 NN in direction of runway.
  local papp=airbase:GetCoordinate():Translate(x1, runway.heading-180):SetAltitude(h1)
  wp[#wp+1]=papp:WaypointAirTurningPoint(nil, UTILS.KnotsToKmph(SpeedLand), {}, "Final Approach")  
  
  -- Okay, it looks like it's best to specify the coordinates not at the airbase but a bit away. This causes a more direct landing approach.
  local pland=airbase:GetCoordinate():Translate(x2, runway.heading-180):SetAltitude(h2)  
  wp[#wp+1]=pland:WaypointAirLanding(UTILS.KnotsToKmph(SpeedLand), airbase, {}, "Landing") 
 
  -- Respawn?
  if fc then
  
    -- Just route the group. Respawn will happen when going from holding to final.
    self.group:Route(wp, 1)
 
  else 
  
    -- Get group template.
    local Template=self.group:GetTemplate()
  
    -- Set route points.
    Template.route.points=wp

    --Respawn the group with new waypoints.
    self:Respawn(Template)
        
  end  
    
end

--- On after "Holding" event. Flight arrived at the holding point.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterHolding(From, Event, To)

  -- Set holding flag to 666.
  self.flaghold:Set(666)

  local text=string.format("Flight group %s is HOLDING now", self.groupname)
  MESSAGE:New(text, 10, "DEBUG"):ToAllIf(self.Debug)
  self:I(self.lid..text)
  
  -- Add flight to waiting/holding queue.
  if self.flightcontrol then
    -- Add flight to holding queue.
    self.flightcontrol:_RemoveFlightFromQueue(self.flightcontrol.Qinbound, self, "inbound")
    self.flightcontrol:_AddFlightToHoldingQueue(self)
    if not self.ai then
      self:_UpdateMenu()
    end
  end

end

--- On after "Holding" event. Flight arrived at the holding point.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Point#COORDINATE Coordinate The coordinate where to land.
-- @param #number Duration The duration in seconds to remain on ground. Default 600 sec.
function FLIGHTGROUP:onafterLandAt(From, Event, To, Coordinate, Duration)
  Duration=Duration or 500

  local task=self.group:TaskLandAtVec2(Coordinate:GetVec2(), Duration)

  -- Add task with high priority.
  self:AddTask(task, 1, "Task_Land_At", 0)
  
end

--- Create a DCS task sandwitch.
-- @param #FLIGHTGROUP self
-- @param #FLIGHTGROUP.Task Task The task.
-- @param #table DCS task sandwitch
function FLIGHTGROUP:_GetTaskSandwitch(Task)


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
  self:I(self.lid..text)
  
  -- Cancel current task if there is any.
  if self.taskcurrent>0 then
    --self:TaskCancel()
  end

  -- Set current task.
  self.taskcurrent=Task.id
  
  -- Set time stamp.
  Task.timestamp=timer.getAbsTime()

  -- Task status executing.
  Task.status=FLIGHTGROUP.TaskStatus.EXECUTING

  -- If task is scheduled (not waypoint) set task.
  if Task.type==FLIGHTGROUP.TaskType.SCHEDULED then

    -- Clear all tasks.
    --self.group:ClearTasks()
  
    
    local DCStasks={}
    if Task.dcstask.id=='ComboTask' then
      -- Loop over all combo tasks.
      for TaskID, Task in ipairs(Task.dcstask.params.tasks) do
        table.insert(DCStasks, Task)
      end    
    else
      table.insert(DCStasks, Task.dcstask)
    end
    
    -- Task done.
    local TaskDone=self.group:TaskFunction("FLIGHTGROUP._TaskDone", self, Task)    
    table.insert(DCStasks, TaskDone)
    
    env.info("FF DCS task combo")
    for i,DCStask in pairs(DCStasks) do
      self:I{{DCStask=DCStask}}    
    end

    -- Combo task.
    local TaskCombo=self.group:TaskCombo(DCStasks)


    -- Stop condition!    
    local TaskCondition=self.group:TaskCondition(nil, Task.stopflag:GetName(), 1)
    
    -- Controlled task.      
    local TaskControlled=self.group:TaskControlled(TaskCombo, TaskCondition)
    
      env.info("FF executing controlled Task:")
    self:I({task=TaskControlled})
  
    -- Set task for group.
    self:SetTask(TaskControlled, 1)
    
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
    self.group:ClearTasks()

    -- Task status executing.
    Task.status=1 --FLIGHTGROUP.TaskStatus.PAUSED

  end

end

--- On after "TaskCancel" event. Cancels the current task.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterTaskCancel(From, Event, To)
  
  -- Get current task.
  local task=self:GetTaskCurrent()
  
  if task then
    local text=string.format("Task %s ID=%d cancelled.", task.description, task.id)
    MESSAGE:New(text, 10, "DEBUG"):ToAllIf(self.Debug)    
    self:I(self.lid..text)
    -- Clear tasks.
    --self.group:ClearTasks()
    --self.group:PopCurrentTask()
    task.stopflag:Set(1)
    self:TaskDone(task)  
  else
    local text=string.format("WARNING: No current task to cancel!")
    MESSAGE:New(text, 10, "DEBUG"):ToAllIf(self.Debug)
    self:I(self.lid..text)      
  end
end


--- On after "TaskDone" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #FLIGHTGROUP.Task Task
function FLIGHTGROUP:onafterTaskDone(From, Event, To, Task)

  -- Debug message.
  local text=string.format("Task done: %s ID=%d", Task.description, Task.id)
  MESSAGE:New(text, 10, "DEBUG"):ToAllIf(self.Debug)
  self:I(self.lid..text)

  -- No current task.
  self.taskcurrent=0
  
  -- Task status done.
  Task.status=FLIGHTGROUP.TaskStatus.ACCOMPLISHED
  
  -- Update route.
  -- TODO: Is this really necessary?
  --self:__UpdateRoute(-1)
  
end


--- On after "DetectedUnit" event. Add newly detected unit to detected units set.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Unit#UNIT Unit The detected unit
function FLIGHTGROUP:onafterDetectedUnit(From, Event, To, Unit)
  self:T(self.lid..string.format("Detected unit %s", Unit:GetName()))
  self.detectedunits:AddUnit(Unit)
end

--- On after "DetectedUnitNew" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Unit#UNIT Unit The detected unit
function FLIGHTGROUP:onafterDetectedUnitNew(From, Event, To, Unit)
  self:T(self.lid..string.format("Detected New unit %s", Unit:GetName()))
end


--- On after "EnterZone" event. Sets self.inzones[zonename]=true.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Zone#ZONE Zone The zone that the group entered.
function FLIGHTGROUP:onafterEnterZone(From, Event, To, Zone)
  local zonename=Zone and Zone:GetName() or "unknown"
  self:I(self.lid..string.format("Entered Zone %s", zonename))
  self.inzones:Add(Zone:GetName(), Zone)
end

--- On after "LeaveZone" event. Sets self.inzones[zonename]=false.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Zone#ZONE Zone The zone that the group entered.
function FLIGHTGROUP:onafterLeaveZone(From, Event, To, Zone)
  local zonename=Zone and Zone:GetName() or "unknown"
  self:I(self.lid..string.format("Left Zone %s", zonename))
  self.inzones:Remove(zonename, true)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Task functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get next task in queue. Task needs to be in state SCHEDULED and time must have passed.
-- @param #FLIGHTGROUP self
-- @return #FLIGHTGROUP.Task The next task in line or `nil`.
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

    -- Current time.
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

  -- Tasks table.    
  local tasks={}

  -- Sort results table wrt times they have already been engaged.
  local function _sort(a, b)
    local taskA=a --#FLIGHTGROUP.Task
    local taskB=b --#FLIGHTGROUP.Task
    return (taskA.time<taskB.time) or (taskA.time==taskB.time and taskA.prio<taskB.prio)
  end
  table.sort(self.taskqueue, _sort)

  -- Look for first task that is not accomplished.
  for _,_task in pairs(self.taskqueue) do
    local task=_task --#FLIGHTGROUP.Task
    if task.type==FLIGHTGROUP.TaskType.WAYPOINT and task.status==FLIGHTGROUP.TaskStatus.SCHEDULED and task.waypoint==n then
      table.insert(tasks, task)
    end
  end
  
  return tasks
end

--- Count the number of tasks that still pending in the queue.
-- @param #FLIGHTGROUP self
-- @return #number Total number of tasks remaining.
-- @return #number Number of SCHEDULED tasks remaining.
-- @return #number Number of WAYPOINT tasks remaining.
function FLIGHTGROUP:CountRemainingTasks()

  local Ntot=0
  local Nwp=0
  local Nsched=0

  -- Look for first task that is not accomplished.
  for _,_task in pairs(self.taskqueue) do
    local task=_task --#FLIGHTGROUP.Task
    
    -- Task is still scheduled.
    if task.status==FLIGHTGROUP.TaskStatus.SCHEDULED then
      
      -- Total number of tasks.
      Ntot=Ntot+1
    
      if task.type==FLIGHTGROUP.TaskType.WAYPOINT then
        Nwp=Nwp+1
      elseif task.type==FLIGHTGROUP.TaskType.WAYPOINT then
        Nsched=Nsched+1
      end
      
    end
    
  end

  return Ntot, Nsched, Nwp
end

--- Function called when a task is executed.
--@param Wrapper.Group#GROUP group Group that reached the holding zone.
--@param #FLIGHTGROUP.Mission
--@param #FLIGHTGROUP flightgroup Flight group.
--@param #FLIGHTGROUP.Task task Task.
function FLIGHTGROUP._TaskExecute(group, flightgroup, task)

  -- Debug message.
  local text=string.format("_TaskExecute %s", task.description)
  flightgroup:I(flightgroup.lid..text)

  -- Set current task to nil so that the next in line can be executed.
  if flightgroup then
    flightgroup:TaskExecute(task)
  end
end

--- Function called when a task is done.
--@param Wrapper.Group#GROUP group Group that reached the holding zone.
--@param #FLIGHTGROUP.Mission
--@param #FLIGHTGROUP flightgroup Flight group.
--@param #FLIGHTGROUP.Task task Task.
function FLIGHTGROUP._TaskDone(group, flightgroup, task)

  -- Debug message.
  local text=string.format("_TaskDone %s", task.description)
  flightgroup:I(flightgroup.lid..text)

  -- Set current task to nil so that the next in line can be executed.
  if flightgroup then
    flightgroup:TaskDone(task)
  end
end

--- Function called when a group is passing a waypoint.
--@param Wrapper.Group#GROUP group Group that passed the waypoint
--@param #FLIGHTGROUP flightgroup Flightgroup object.
--@param #number i Waypoint number that has been reached.
function FLIGHTGROUP._PassingWaypoint(group, flightgroup, i)

  local final=#flightgroup.waypoints or 1

  -- Debug message.
  local text=string.format("Group %s passing waypoint %d of %d.", group:GetName(), i, final)
  env.info(text)

  -- Debug smoke and marker.
  if flightgroup.Debug then
    local pos=group:GetCoordinate()
    --pos:SmokeRed()
    --local MarkerID=pos:MarkToAll(string.format("Group %s reached waypoint %d", group:GetName(), i))
  end

  -- Debug message.
  flightgroup:T3(flightgroup.lid..text)

  -- Set current waypoint.
  flightgroup.currentwp=i

  -- Passing Waypoint event.
  flightgroup:PassingWaypoint(i, final)

  -- If final waypoint reached, do route all over again.
  if i==final and final>1 then
    --TODO: final waypoint reached! what next?
  end
end

--- Function called when flight has reached the holding point.
-- @param Wrapper.Group#GROUP group Group object.
-- @param #FLIGHTGROUP flightgroup Flight group object.
function FLIGHTGROUP._ReachedHolding(group, flightgroup)
  flightgroup:T(flightgroup.lid..string.format("Group %s reached holding point", group:GetName()))
  
  if flightgroup.Debug then
    group:GetCoordinate():MarkToAll("Holding Point Reached")
  end
  
  flightgroup:__Holding(-1)
end

--- Update route of group, e.g after new waypoints and/or waypoint tasks have been added.
-- @param Wrapper.Group#GROUP group The Moose group object.
-- @param #FLIGHTGROUP flightgroup The flight group object.
-- @param Wrapper.Airbase#AIRBASE destination Destination airbase
function FLIGHTGROUP._DestinationOverhead(group, flightgroup, destination)

  -- Tell the flight to hold.
  -- WARNING: This needs to be delayed or we get a CTD!
  flightgroup:__Hold(-1, destination)

end


--- Route flight group back to base.
-- @param #FLIGHTGROUP self
-- @param Wrapper.Airbase#AIRBASE RTBAirbase
-- @param #number Speed Speed in km/h. Default is 80% of max possible speed.
-- @param #number Altitude Altitude in meters. Default is current alitude.
-- @param #table TaskOverhead Task to execute when reaching overhead waypoint.
function FLIGHTGROUP:RouteRTB(RTBAirbase, Speed, Altitude, TaskOverhead)

  -- If speed is not given take 80% of max speed.
  Speed=Speed or self.speedmax*0.8

  -- Curent (from) waypoint.
  local coord=self.group:GetCoordinate()

  if Altitude then
    coord:SetAltitude(Altitude)
  end

  -- Current coordinate.
  local PointFrom=coord:WaypointAirTurningPoint(nil, Speed, {}, "Current")

  -- Overhead pass.
  local PointOverhead=RTBAirbase:GetCoordinate():SetAltitude(Altitude or coord.y):WaypointAirTurningPoint(nil, Speed, TaskOverhead, "Overhead Pass")

  -- Landing waypoint.
  local PointLanding=RTBAirbase:GetCoordinate():SetAltitude(20):WaypointAirLanding(Speed, RTBAirbase, {}, "Landing")

  -- Waypoint table.
  local Points={PointFrom, PointOverhead, PointLanding}

  -- Get group template.
  local Template=self.group:GetTemplate()

  -- Set route points.
  Template.route.points=Points

  -- Respawn the group.
  --self.group=self.group:Respawn(Template, true)
  
  local TaskRTB=self.group:TaskRoute(Points)
  
  --[[
  self.taskcounter=self.taskcounter+1
  
  local task={} --#FLIGHTGROUP.Task
  task.dcstask=TaskRTB
  task.description="RTB"
  task.id=self.taskcounter
  task.type=FLIGHTGROUP.TaskType.SCHEDULED
  task.prio=0
  task.time=timer.getAbsTime()
  ]]
  
  self:AddTask("RTB", TaskRTB, 0)
  
  self:TaskCancel()

  -- Route the group or this will not work.
  --self.group:Route(Points, 1)

end


--- Route flight group to orbit.
-- @param #FLIGHTGROUP self
-- @param Core.Point#COORDINATE CoordOrbit Orbit coordinate.
-- @param #number Speed Speed in km/h. Default 60% of max group speed.
-- @param #number Altitude Altitude in meters. Default 10,000 ft.
-- @param Core.Point#COORDINATE CoordRaceTrack (Optional) Race track coordinate.
function FLIGHTGROUP:RouteOrbit(CoordOrbit, Speed, Altitude, CoordRaceTrack)

  -- If speed is not given take 80% of max speed.
  Speed=Speed or self.group:GetSpeedMax()*0.6

  -- Altitude.
  local altitude=Altitude or UTILS.FeetToMeters(10000)

  -- Waypoints.
  local wp={}

  -- Current coordinate.
  wp[1]=self.group:GetCoordinate():SetAltitude(altitude):WaypointAirTurningPoint(nil, Speed, {}, "Current")

  -- Orbit
  wp[2]=CoordOrbit:SetAltitude(altitude):WaypointAirTurningPoint(nil, Speed, {}, "Orbit")


  local TaskOrbit=self.group:TaskOrbit(CoordOrbit, altitude, Speed, CoordRaceTrack)
  local TaskRoute=self.group:TaskRoute(wp)

  --local TaskCondi=self.group:TaskCondition(time,userFlag,userFlagValue,condition,duration,lastWayPoint)

  local TaskCombo=self.group:TaskControlled(TaskRoute, TaskOrbit)

  self:SetTask(TaskCombo, 1)

  -- Route the group or this will not work.
  --self.group:Route(wp, 1)
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
    element.status=FLIGHTGROUP.ElementStatus.INUTERO
    element.group=unit:GetGroup()
    
    element.modex=element.unit:GetTemplate().onboard_num
    element.skill=element.unit:GetTemplate().skill
    element.pylons=element.unit:GetTemplatePylons()
    element.fuelmass=element.unit:GetTemplatePayload().fuel
    element.category=element.unit:GetCategory()
    element.categoryname=element.unit:GetCategoryName()
    element.callsign=element.unit:GetCallsign()
    element.size=element.unit:GetObjectSize()
    
    if element.skill=="Client" or element.skill=="Player" then
      element.ai=false
      element.client=CLIENT:FindByName(unitname)
    else
      element.ai=true
    end
    
    local text=string.format("Adding element %s: status=%s, skill=%s, modex=%s, fuelmass=%.1f, category=%d, categoryname=%s, callsign=%s, ai=%s",
    element.name, element.status, element.skill, element.modex, element.fuelmass, element.category, element.categoryname, element.callsign, tostring(element.ai))
    self:I(self.lid..text)

    -- Add element to table.
    table.insert(self.elements, element)

    return element
  end

  return nil
end

--- Check if a unit is and element of the flightgroup.
-- @param #FLIGHTGROUP self
-- @param #string unitname Name of unit.
-- @return #FLIGHTGROUP.Element The element.
function FLIGHTGROUP:GetElementByName(unitname)

  for _,_element in pairs(self.elements) do
    local element=_element --#FLIGHTGROUP.Element

    if element.name==unitname then
      return element
    end

  end

  return nil
end

--- Check if a unit is and element of the flightgroup.
-- @param #FLIGHTGROUP self
-- @return Wrapper.Airbase#AIRBASE Final destination airbase or #nil.
function FLIGHTGROUP:GetHomebaseFromWaypoints()

  local wp=self:GetWaypoint(1)
  
  if wp then
    
    if wp and wp.action and wp.action==COORDINATE.WaypointAction.FromParkingArea 
                         or wp.action==COORDINATE.WaypointAction.FromParkingAreaHot 
                         or wp.action==COORDINATE.WaypointAction.FromRunway  then
      
      -- Get airbase ID depending on airbase category.
      local airbaseID=wp.airdromeId or wp.helipadId
      
      local airbase=AIRBASE:FindByID(airbaseID)
      
      return airbase    
    end
    
    --TODO: Handle case where e.g. only one WP but that is not landing.
    --TODO: Probably other cases need to be taken care of.
    
  end

  return nil
end

--- Check if a unit is and element of the flightgroup.
-- @param #FLIGHTGROUP self
-- @return Wrapper.Airbase#AIRBASE Final destination airbase or #nil.
function FLIGHTGROUP:GetDestinationFromWaypoints()

  local wp=self:GetWaypointFinal()
  
  if wp then
    
    if wp and wp.action and wp.action==COORDINATE.WaypointAction.Landing then
      
      -- Get airbase ID depending on airbase category.
      local airbaseID=wp.airdromeId or wp.helipadId
      
      local airbase=AIRBASE:FindByID(airbaseID)
      
      return airbase    
    end
    
    --TODO: Handle case where e.g. only one WP but that is not landing.
    --TODO: Probably other cases need to be taken care of.
    
  end

  return nil
end

--- Check if this is a hot start.
-- @param #FLIGHTGROUP self
-- @return #boolean Hot start?
function FLIGHTGROUP:IsTakeoffHot()

  local wp=self:GetWaypoint(1)
  
  if wp then
    
    if wp.action and wp.action==COORDINATE.WaypointAction.FromParkingAreaHot then
      return true
    else
      return false
    end
    
  end

  return nil
end

--- Check if this is a cold start.
-- @param #FLIGHTGROUP self
-- @return #boolean Cold start, i.e. engines off when spawned?
function FLIGHTGROUP:IsTakeoffCold()

  local wp=self:GetWaypoint(1)
  
  if wp then
    
    if wp.action and wp.action==COORDINATE.WaypointAction.FromParkingArea then
      return true
    else
      return false
    end
    
  end

  return nil
end

--- Check if this is a runway start.
-- @param #FLIGHTGROUP self
-- @return #boolean Runway start?
function FLIGHTGROUP:IsTakeoffRunway()

  local wp=self:GetWaypoint(1)
  
  if wp then
    
    if wp.action and wp.action==COORDINATE.WaypointAction.FromRunway then
      return true
    else
      return false
    end
    
  end

  return nil
end

--- Check if this is an air start.
-- @param #FLIGHTGROUP self
-- @return #boolean Air start?
function FLIGHTGROUP:IsTakeoffAir()

  local wp=self:GetWaypoint(1)
  
  if wp then
    
    if wp.action and wp.action==COORDINATE.WaypointAction.TurningPoint or wp.action==COORDINATE.WaypointAction.FlyoverPoint then
      return true
    else
      return false
    end
    
  end

  return nil
end

--- Check if the final waypoint is in the air.
-- @param #FLIGHTGROUP self
-- @param #table wp Waypoint. Default final waypoint.
-- @return #boolean If `true` final waypoint is a turning or flyover but not a landing type waypoint.
function FLIGHTGROUP:IsLandingAir(wp)

  wp=wp or self:GetWaypointFinal()
  
  if wp then
    
    if wp.action and wp.action==COORDINATE.WaypointAction.TurningPoint or wp.action==COORDINATE.WaypointAction.FlyoverPoint then
      return true
    else
      return false
    end
    
  end

  return nil
end

--- Check if the final waypoint is at an airbase.
-- @param #FLIGHTGROUP self
-- @param #table wp Waypoint. Default final waypoint.
-- @return #boolean If `true`, final waypoint is a landing waypoint at an airbase.
function FLIGHTGROUP:IsLandingAirbase(wp)

  wp=wp or self:GetWaypointFinal()
  
  if wp then
    
    if wp.action and wp.action==COORDINATE.WaypointAction.LANDING then
      return true
    else
      return false
    end
    
  end

  return nil
end


--- Check if this group is "late activated" and needs to be "activated" to appear in the mission.
-- @param #FLIGHTGROUP self
-- @return #boolean Hot start?
function FLIGHTGROUP:IsLateActivated()

  local template=_DATABASE:GetGroupTemplate(self.groupname)
  
  if template then
    
    if template.lateActivation==true then
      return true
    else
      return false
    end
    
  end

  return nil
end

--- Check if this group is "uncontrolled" and needs to be "started" to begin its route.
-- @param #FLIGHTGROUP self
-- @return #boolean Hot start?
function FLIGHTGROUP:IsUncontrolled()

  local template=_DATABASE:GetGroupTemplate(self.groupname)
  
  if template then
    
    if template.uncontrolled==true then
      return true
    else
      return false
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

--- Get next waypoint coordinates.
-- @param #FLIGHTGROUP self
-- @param #table wp Waypoint table.
-- @return Core.Point#COORDINATE Coordinate of the next waypoint.
function FLIGHTGROUP:GetWaypointCoordinate(wp)
  -- TODO: move this to COORDINATE class.
  return COORDINATE:New(wp.x, wp.alt, wp.y)
end

--- Initialize Mission Editor waypoints.
-- @param #FLIGHTGROUP self
function FLIGHTGROUP:_UpdateWaypointTasks()

  local waypoints=self.waypoints
  local nwaypoints=#waypoints

  for i,wp in pairs(waypoints) do
    
    if i>self.currentwp or nwaypoints==1 then
    
      self:I(self.lid..string.format("Updating waypoint task for waypoint %d/%d. Last waypoint passed %d.", i, nwaypoints, self.currentwp))
  
      -- Tasks of this waypoint
      local taskswp={}
    
      -- At each waypoint report passing.
      local TaskPassingWaypoint=self.group:TaskFunction("FLIGHTGROUP._PassingWaypoint", self, i)      
      table.insert(taskswp, TaskPassingWaypoint)
      
      
      -- For some reason THIS DOES NOT WORK if executed at the last waypoint if it is an AIR WAYPOINT.
      -- I have moved it to the onafterpassingwaypoint function instead.
      
      --[[
      
      -- Get taks
      local tasks=self:GetTasksWaypoint(i)
      
      for _,task in pairs(tasks) do
        local Task=task --#FLIGHTGROUP.Task          
        
        -- Task execute.
        table.insert(taskswp, self.group:TaskFunction("FLIGHTGROUP._TaskExecute", self, Task))

        -- Stop condition if userflag is set to 1.    
        local TaskCondition=self.group:TaskCondition(nil, Task.stopflag:GetName(), 1, nil, Task.duration)
        
        -- Controlled task.      
        table.insert(taskswp, self.group:TaskControlled(Task.dcstask, TaskCondition))
        
         --table.insert(taskswp, Task.dcstask)
        
        -- Task done.
        table.insert(taskswp, self.group:TaskFunction("FLIGHTGROUP._TaskDone", self, Task))    
        
      end
      
      ]]
          
      -- Waypoint task combo.
      wp.task=self.group:TaskCombo(taskswp)
          
      -- Debug info.
      env.info("FF task waypoint combo:")
      self:I({wptask=taskswp})
      
    end
  end

end

--- Initialize Mission Editor waypoints.
-- @param #FLIGHTGROUP self
-- @param #table waypoints Table of waypoints. Default is from group template.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:InitWaypoints(waypoints)

  -- Template waypoints.
  self.waypoints0=self.group:GetTemplateRoutePoints()

  -- Waypoints of group as defined in the ME.
  self.waypoints=waypoints or UTILS.DeepCopy(self.waypoints0)

  -- Set waypoint table.
  for i,point in ipairs(self.waypoints or {}) do

    -- Debug info.
    if self.Debug then
      --coord:MarkToAll(string.format("Flight %s waypoint %d, Speed=%.1f knots", self.groupname, i, UTILS.MpsToKnots(point.speed)))
    end

  end

  -- Set current waypoint. Counting starts a one.
  self.currentwp=1
  
  -- Get home and destination airbases from waypoints.
  self.homebase=self:GetHomebaseFromWaypoints()
  self.destbase=self:GetDestinationFromWaypoints()
  
  -- Debug info.
  self:I(self.lid..string.format("Initializing %d waypoints. Homebase %s ==> %s Destination", #self.waypoints, self.homebase and self.homebase:GetName() or "unknown", self.destbase and self.destbase:GetName() or "uknown"))
  
  -- Update route.
  if #self.waypoints>0 then
    self:__UpdateRoute(-1)
  end

  return self
end

--- Add a waypoint to the flight plan.
-- @param #FLIGHTGROUP self
-- @param Core.Point#COORDINATE coordinate The coordinate of the waypoint. Use COORDINATE:SetAltitude(altitude) to define the altitude.
-- @param #number wpnumber Waypoint number. Default at the end.
-- @param #number speed Speed in knots. Default 350 kts.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:AddWaypointAir(coordinate, wpnumber, speed)

  -- Waypoint number.
  wpnumber=wpnumber or #self.waypoints+1
  
  -- Speed in knots.
  speed=speed or 350

  -- Speed at waypoint.
  local speedkmh=UTILS.KnotsToKmph(speed)

  -- Create air waypoint.
  local wp=coordinate:WaypointAir(COORDINATE.WaypointAltType.BARO, COORDINATE.WaypointType.TurningPoint, COORDINATE.WaypointAction.TurningPoint, speedkmh, true, nil, {}, string.format("Added Waypoint #%d", wpnumber))
  
  -- Add to table.
  table.insert(self.waypoints, wpnumber, wp)
  
  -- Debug info.
  self:I(self.lid..string.format("Adding AIR waypoint #%d, speed=%.1f knots. Last waypoint passed was #%s. Total waypoints #%d", wpnumber, speed, self.currentwp, #self.waypoints))
  
  -- Shift all waypoint tasks after the inserted waypoint.
  for _,_task in pairs(self.taskqueue) do
    local task=_task --#FLIGHTGROUP.Task
    if task.type==FLIGHTGROUP.TaskType.WAYPOINT and task.status==FLIGHTGROUP.TaskStatus.SCHEDULED and task.waypoint>=wpnumber then
      task.waypoint=task.waypoint+1
    end
  end  
  
  -- Update route.
  self:__UpdateRoute(-1)
  
  return self
end

--- Set the landing waypoint.
-- @param #FLIGHTGROUP self
-- @param Wrapper.Airbase#AIRBASE airbase The destination airbase.
-- @param #number wpnumber Waypoint number. Default at the end.
-- @param #number speed Speed in knots. Default 350 kts.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:RemoveWaypoint(wpindex)

  for i, wp in pairs(self.waypoints) do
    if i==index then
      table.remove(self.waypoints, i)
      break
    end
  end


  --TODO update route?
end


--- Set the landing waypoint.
-- @param #FLIGHTGROUP self
-- @param Wrapper.Airbase#AIRBASE airbase The destination airbase.
-- @param #number wpnumber Waypoint number. Default at the end.
-- @param #number speed Speed in knots. Default 350 kts.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:SetWaypointLanding(airbase)

  local wpnumber=#self.waypoints

  local lastwp=self.waypoints[wpnumber]
  
  if self:IsLandingAirbase(lastwp) then
    table.remove(self.waypoints, wpnumber)
  end
  
  local wp=self.group:GetCoordinate():WaypointAir(COORDINATE.WaypointAltType.BARO, COORDINATE.WaypointType.Land, COORDINATE.WaypointAction.Landing, self.speedmax*0.8, true, nil, {}, string.format("Landing Waypoint #%d", wpnumber))
  
  table.insert(self.waypoints, wp)
  
  self.destbase=airbase
    
  -- Update route.
  self:__UpdateRoute(-1)
  
  return self
end

--- Check if a unit is an element of the flightgroup.
-- @param #FLIGHTGROUP self
-- @param #string unitname Name of unit.
-- @return #boolean If true, unit is element of the flight group or false if otherwise.
function FLIGHTGROUP:_IsElement(unitname)

  for _,_element in pairs(self.elements) do
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

  for _,_element in pairs(self.elements) do
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

  -- Check if all are dead.
  if status==FLIGHTGROUP.ElementStatus.DEAD then
    for _,_element in pairs(self.elements) do
      local element=_element --#FLIGHTGROUP.Element
      if element.status~=FLIGHTGROUP.ElementStatus.DEAD then
        -- At least one is still alive.
        return false
      end
    end
    return true
  end

  for _,_element in pairs(self.elements) do
    local element=_element --#FLIGHTGROUP.Element
    
    self:T2(self.lid..string.format("Status=%s, element %s status=%s", status, element.name, element.status))

    -- Dead units dont count ==> We wont return false for those.
    if element.status~=FLIGHTGROUP.ElementStatus.DEAD then
    
      ----------
      -- ALIVE
      ----------

      if status==FLIGHTGROUP.ElementStatus.SPAWNED then

        -- Element SPAWNED: Check that others are not still IN UTERO
        if element.status~=status and
          element.status==FLIGHTGROUP.ElementStatus.INUTERO  then
          return false
        end

      elseif status==FLIGHTGROUP.ElementStatus.PARKING then

        -- Element PARKING: Check that the other are not still SPAWNED
        if element.status~=status or
         (element.status==FLIGHTGROUP.ElementStatus.INUTERO or
          element.status==FLIGHTGROUP.ElementStatus.SPAWNED) then
          return false
        end

      elseif status==FLIGHTGROUP.ElementStatus.ENGINEON then

        -- Element TAXIING: Check that the other are not still SPAWNED or PARKING
        if element.status~=status and
         (element.status==FLIGHTGROUP.ElementStatus.INUTERO or
          element.status==FLIGHTGROUP.ElementStatus.SPAWNED or
          element.status==FLIGHTGROUP.ElementStatus.PARKING) then
          return false
        end

      elseif status==FLIGHTGROUP.ElementStatus.TAXIING then

        -- Element TAXIING: Check that the other are not still SPAWNED or PARKING
        if element.status~=status and
         (element.status==FLIGHTGROUP.ElementStatus.INUTERO or
          element.status==FLIGHTGROUP.ElementStatus.SPAWNED or
          element.status==FLIGHTGROUP.ElementStatus.PARKING or
          element.status==FLIGHTGROUP.ElementStatus.ENGINEON) then
          return false
        end        

      elseif status==FLIGHTGROUP.ElementStatus.TAKEOFF then

        -- Element TAKEOFF: Check that the other are not still SPAWNED, PARKING or TAXIING
        if element.status~=status and
         (element.status==FLIGHTGROUP.ElementStatus.INUTERO or
          element.status==FLIGHTGROUP.ElementStatus.SPAWNED or
          element.status==FLIGHTGROUP.ElementStatus.PARKING or
          element.status==FLIGHTGROUP.ElementStatus.ENGINEON or
          element.status==FLIGHTGROUP.ElementStatus.TAXIING) then
          self:T3(self.lid..string.format("Status=%s, element %s status=%s ==> returning FALSE", status, element.name, element.status))
          return false
        end

      elseif status==FLIGHTGROUP.ElementStatus.AIRBORNE then

        -- Element AIRBORNE: Check that the other are not still SPAWNED, PARKING, TAXIING or TAKEOFF
        if element.status~=status and
         (element.status==FLIGHTGROUP.ElementStatus.INUTERO or
          element.status==FLIGHTGROUP.ElementStatus.SPAWNED or
          element.status==FLIGHTGROUP.ElementStatus.PARKING or
          element.status==FLIGHTGROUP.ElementStatus.ENGINEON or
          element.status==FLIGHTGROUP.ElementStatus.TAXIING or 
          element.status==FLIGHTGROUP.ElementStatus.TAKEOFF) then
          return false
        end

      elseif status==FLIGHTGROUP.ElementStatus.LANDED then

        -- Element LANDED: check that the others are not still AIRBORNE or LANDING
        if element.status~=status and
         (element.status==FLIGHTGROUP.ElementStatus.AIRBORNE or
          element.status==FLIGHTGROUP.ElementStatus.LANDING) then
          return false
        end

      elseif status==FLIGHTGROUP.ElementStatus.ARRIVED then

        -- Element ARRIVED: check that the others are not still AIRBORNE, LANDING, or LANDED (taxiing).
        if element.status~=status and
         (element.status==FLIGHTGROUP.ElementStatus.AIRBORNE or
          element.status==FLIGHTGROUP.ElementStatus.LANDING  or
          element.status==FLIGHTGROUP.ElementStatus.LANDED)  then
          return false
        end

      end
      
    else
      -- Element is dead. We don't care unless all are dead.
    end --DEAD

  end

  -- Debug info.
  self:I(self.lid..string.format("All %d elements have similar status %s ==> returning TRUE", #self.elements, status))
  
  return true
end

--- Check if all elements of the flight group have the same status or are dead.
-- @param #FLIGHTGROUP self
-- @param #FLIGHTGROUP.Element element Element.
-- @param #string newstatus New status of element
-- @param Wrapper.Airbase#AIRBASE airbase Airbase if applicable.
function FLIGHTGROUP:_UpdateStatus(element, newstatus, airbase)

  -- Old status.
  local oldstatus=element.status

  -- Update status of element.
  element.status=newstatus
  
  env.info(string.format("FF UpdateStatus element=%s: %s --> %s", element.name, oldstatus, newstatus))
  for _,_element in pairs(self.elements) do
    local Element=_element -- #FLIGHTGROUP.Element
    env.info(string.format("Element %s: %s", Element.name, Element.status))
  end

  if newstatus==FLIGHTGROUP.ElementStatus.SPAWNED then
    ---
    -- SPAWNED
    ---

    if self:_AllSimilarStatus(newstatus) then
      self:__FlightSpawned(0.5)
    end
    
  elseif newstatus==FLIGHTGROUP.ElementStatus.PARKING then
    ---
    -- PARKING
    ---

    if self:_AllSimilarStatus(newstatus) then
      self:__FlightParking(0.5)
    end

  elseif newstatus==FLIGHTGROUP.ElementStatus.ENGINEON then
    ---
    -- ENGINEON
    ---

    -- No FLIGHT status. Waiting for taxiing.

  elseif newstatus==FLIGHTGROUP.ElementStatus.TAXIING then
    ---
    -- TAXIING
    ---

    if self:_AllSimilarStatus(newstatus) then
      self:__FlightTaxiing(0.5)
    end
    
  elseif newstatus==FLIGHTGROUP.ElementStatus.TAKEOFF then
    ---
    -- TAKEOFF
    ---

    if self:_AllSimilarStatus(newstatus) then
      -- Trigger takeoff event. Also triggers airborne event.
      self:__FlightTakeoff(0.5, airbase)
    end

  elseif newstatus==FLIGHTGROUP.ElementStatus.AIRBORNE then
    ---
    -- AIRBORNE
    ---

    if self:_AllSimilarStatus(newstatus) then
      self:__FlightAirborne(0.5)      
      --[[
      if self:IsTaxiing() then
        self:FlightAirborne()
      elseif self:IsParking() then
        --self:FlightTaxiing()
        self:FlightAirborne()
      elseif self:IsSpawned() then
        --self:FlightParking()
        --self:FlightTaxiing()
        self:FlightAirborne()
      end
      ]]      
    end

  elseif newstatus==FLIGHTGROUP.ElementStatus.LANDED then
    ---
    -- LANDED
    ---

    if self:_AllSimilarStatus(newstatus) then
      self:FlightLanded(airbase)
    end

  elseif newstatus==FLIGHTGROUP.ElementStatus.ARRIVED then
    ---
    -- ARRIVED
    ---

    if self:_AllSimilarStatus(newstatus) then

      if self:IsLanded() then
        self:FlightArrived()
      elseif self:IsAirborne() then
        self:FlightLanded()
        self:FlightArrived()
      end

    end

  elseif newstatus==FLIGHTGROUP.ElementStatus.DEAD then
    ---
    -- DEAD
    ---

    if self:_AllSimilarStatus(newstatus) then
      self:FlightDead()
    end

  end
end

--- Set status for all elements (except dead ones).
-- @param #FLIGHTGROUP self
-- @param #string status Element status.
function FLIGHTGROUP:_SetElementStatusAll(status)

  for _,_element in pairs(self.elements) do
    local element=_element --#FLIGHTGROUP.Element
    if element.status~=FLIGHTGROUP.ElementStatus.DEAD then
      element.status=status
    end
  end

end

--- Check if flight is in zones.
-- @param #FLIGHTGROUP self
function FLIGHTGROUP:_CheckInZones()

  if self.checkzones then
  
    local Ncheck=self.checkzones:Count()
    local Ninside=self.inzones:Count()
    
    -- Debug info.
    self:T(self.lid..string.format("Check if flight is in %d zones. Currently it is in %d zones.", self.checkzones:Count(), self.inzones:Count()))

    -- Firstly, check if group is still inside zone it was already in. If not, remove zones and trigger LeaveZone() event.
    local leftzones={}
    for inzonename, inzone in pairs(self.inzones:GetSet()) do
        
      -- Check if group is still inside the zone.
      local isstillinzone=self.group:IsPartlyOrCompletelyInZone(inzone)
      
      -- If not, trigger, LeaveZone event.
      if not isstillinzone then
        table.insert(leftzones, inzone)
      end      
    end
    
    -- Trigger leave zone event.
    for _,leftzone in pairs(leftzones) do
      self:LeaveZone(leftzone)
    end
    
    
    -- Now, run of all check zones and see if the group entered a  zone.
    local enterzones={}
    for checkzonename,_checkzone in pairs(self.checkzones:GetSet()) do
      local checkzone=_checkzone --Core.Zone#ZONE
      
      -- Is flight currtently in this check zone?
      local isincheckzone=self.group:IsPartlyOrCompletelyInZone(checkzone)

      if isincheckzone and not self.inzones:_Find(checkzonename) then
        table.insert(enterzones, checkzone)
      end
    end
    
    -- Trigger enter zone event.
    for _,enterzone in pairs(enterzones) do
      self:EnterZone(enterzone)
    end
    
    
  end

end

--- Check detected units.
-- @param #FLIGHTGROUP self
function FLIGHTGROUP:_CheckDetectedUnits()

  if self.group and not self:IsDead() then

    -- Get detected DCS units.
    local detectedtargets=self.group:GetDetectedTargets()

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
    local lost={}
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
        table.insert(lost, unit:GetName())
        self:DetectedUnitLost(unit)
      end

    end
    
    -- Remove lost units from detected set.
    self.detectedunits:RemoveUnitsByName(lost)

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
    self:I(self.lid..text)
  else
    self:T3(self.lid..text)
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

--- Checks if a human player sits in the unit.
-- @param #FLIGHTGROUP self
-- @param Wrapper.Unit#UNIT unit Aircraft unit.
-- @return #boolean If true, human player inside the unit.
function FLIGHTGROUP:_IsHumanUnit(unit)
  
  -- Get player unit or nil if no player unit.
  local playerunit=self:_GetPlayerUnitAndName(unit:GetName())
  
  if playerunit then
    return true
  else
    return false
  end
end

--- Checks if a group has a human player.
-- @param #FLIGHTGROUP self
-- @param Wrapper.Group#GROUP group Aircraft group.
-- @return #boolean If true, human player inside group.
function FLIGHTGROUP:_IsHuman(group)

  -- Get all units of the group.
  local units=group:GetUnits()
  
  -- Loop over all units.
  for _,_unit in pairs(units) do
    -- Check if unit is human.
    local human=self:_IsHumanUnit(_unit)
    if human then
      return true
    end
  end

  return false
end

--- Returns the unit of a player and the player name. If the unit does not belong to a player, nil is returned. 
-- @param #FLIGHTGROUP self
-- @param #string _unitName Name of the player unit.
-- @return Wrapper.Unit#UNIT Unit of player or nil.
-- @return #string Name of the player or nil.
function FLIGHTGROUP:_GetPlayerUnitAndName(_unitName)
  self:F2(_unitName)

  if _unitName ~= nil then
  
    -- Get DCS unit from its name.
    local DCSunit=Unit.getByName(_unitName)
    
    if DCSunit then
    
      local playername=DCSunit:getPlayerName()
      local unit=UNIT:Find(DCSunit)
    
      self:T2({DCSunit=DCSunit, unit=unit, playername=playername})
      if DCSunit and unit and playername then
        return unit, playername
      end
      
    end
    
  end
  
  -- Return nil if we could not find a player.
  return nil,nil
end

--- Returns the coalition side.
-- @param #FLIGHTGROUP self
-- @return #number Coalition side number.
function FLIGHTGROUP:GetCoalition()
  return self.group:GetCoalition()
end

--- Returns the parking spot of the element.
-- @param #FLIGHTGROUP self
-- @param #FLIGHTGROUP.Element element Element of the flight group.
-- @param #number maxdist Distance threshold in meters. Default 5 m.
-- @param Wrapper.Airbase#AIRBASE airbase (Optional) The airbase to check for parking. Default is closest airbase to the element.
-- @return Wrapper.Airbase#AIRBASE.ParkingSpot Parking spot or nil if no spot is within distance threshold.
function FLIGHTGROUP:GetParkingSpot(element, maxdist, airbase)

  local coord=element.unit:GetCoordinate()

  airbase=airbase or coord:GetClosestAirbase(nil, self:GetCoalition())
  
  local spot=nil --Wrapper.Airbase#AIRBASE.ParkingSpot
  local dist=nil
  local distmin=math.huge 
  for _,_parking in pairs(airbase.parking) do
    local parking=_parking --Wrapper.Airbase#AIRBASE.ParkingSpot
    dist=coord:Get2DDistance(parking.Coordinate)
    if dist<distmin then
      distmin=dist
      spot=_parking   
    end
  end

  if distmin<=maxdist and not element.unit:InAir() then
    return spot
  else
    return nil
  end
end

--- Get holding time.
-- @param #FLIGHTGROUP self
-- @return #number Holding time in seconds or -1 if flight is not holding.
function FLIGHTGROUP:GetHoldingTime()
  if self.Tholding then
    return timer.getAbsTime()-self.Tholding
  end
  
  return -1
end

--- Get parking time.
-- @param #FLIGHTGROUP self
-- @return #number Holding time in seconds or -1 if flight is not holding.
function FLIGHTGROUP:GetParkingTime()
  if self.Tparking then
    return timer.getAbsTime()-self.Tparking
  end
  
  return -1
end

--- Get number of elements alive.
-- @param #FLIGHTGROUP self
-- @param #string status (Optional) Only count number, which are in a special status.
-- @return #number Holding time in seconds or -1 if flight is not holding.
function FLIGHTGROUP:GetNelements(status)

  local n=0
  for _,_element in pairs(self.elements) do
    local element=_element --#FLIGHTGROUP.Element
    if element.status~=FLIGHTGROUP.ElementStatus.DEAD then
      if element.unit and element.unit:IsAlive() then
        if status==nil or element.status==status then
          n=n+1
        end
      end
    end
  end

  
  return n
end

--- Search unoccupied parking spots at the airbase for all flight elements.
-- @param #FLIGHTGROUP self
-- @param Wrapper.Airbase#AIRBASE airbase The airbase where we search for parking spots.
-- @return #table Table of coordinates and terminal IDs of free parking spots.
function FLIGHTGROUP:GetParking(airbase)

  -- Init default
  local scanradius=50
  local scanunits=true
  local scanstatics=true
  local scanscenery=false
  local verysafe=true

  -- Function calculating the overlap of two (square) objects.
  local function _overlap(l1,l2,dist)
    local safedist=(l1/2+l2/2)*1.05  -- 5% safety margine added to safe distance!
    local safe = (dist > safedist)
    self:T3(string.format("l1=%.1f l2=%.1f s=%.1f d=%.1f ==> safe=%s", l1,l2,safedist,dist,tostring(safe)))
    return safe
  end

  -- Get client coordinates.  
  local function _clients()
    local clients=_DATABASE.CLIENTS
    local coords={}
    for clientname, client in pairs(clients) do
      local template=_DATABASE:GetGroupTemplateFromUnitName(clientname)
      local units=template.units
      for i,unit in pairs(units) do
        local coord=COORDINATE:New(unit.x, unit.alt, unit.y)
        coords[unit.name]=coord
      end     
    end
    return coords 
  end
  
  -- Get airbase category.
  local airbasecategory=airbase:GetAirbaseCategory()

  -- Get parking spot data table. This contains all free and "non-free" spots.
  local parkingdata=airbase:GetParkingSpotsTable()
  
  -- List of obstacles.
  local obstacles={}

  -- Loop over all parking spots and get the currently present obstacles.
  -- How long does this take on very large airbases, i.e. those with hundereds of parking spots? Seems to be okay!
  -- The alternative would be to perform the scan once but with a much larger radius and store all data.
  for _,_parkingspot in pairs(parkingdata) do
    local parkingspot=_parkingspot --Wrapper.Airbase#AIRBASE.ParkingSpot

    -- Scan a radius of 100 meters around the spot.
    local _,_,_,_units,_statics,_sceneries=parkingspot.Coordinate:ScanObjects(scanradius, scanunits, scanstatics, scanscenery)

    -- Check all units.
    for _,_unit in pairs(_units) do
      local unit=_unit --Wrapper.Unit#UNIT
      local _coord=unit:GetCoordinate()
      local _size=self:_GetObjectSize(unit:GetDCSObject())
      local _name=unit:GetName()
      table.insert(obstacles, {coord=_coord, size=_size, name=_name, type="unit"})
    end
    
    -- Check all clients.
    local clientcoords=_clients()
    for clientname,_coord in pairs(clientcoords) do
      table.insert(obstacles, {coord=_coord, size=15, name=clientname, type="client"})
    end

    -- Check all statics.
    for _,static in pairs(_statics) do
      local _vec3=static:getPoint()
      local _coord=COORDINATE:NewFromVec3(_vec3)
      local _name=static:getName()
      local _size=self:_GetObjectSize(static)
      table.insert(obstacles, {coord=_coord, size=_size, name=_name, type="static"})
    end

    -- Check all scenery.
    for _,scenery in pairs(_sceneries) do
      local _vec3=scenery:getPoint()
      local _coord=COORDINATE:NewFromVec3(_vec3)
      local _name=scenery:getTypeName()
      local _size=self:_GetObjectSize(scenery)
      table.insert(obstacles,{coord=_coord, size=_size, name=_name, type="scenery"})
    end

  end

  -- Parking data for all assets.
  local parking={}

  -- Get terminal type.  
  local terminaltype=self:_GetTerminal(self.attribute, airbase:GetAirbaseCategory())

  -- Loop over all units - each one needs a spot.
  for i,_element in pairs(self.elements) do
    local element=_element --#FLIGHTGROUP.Element

    -- Loop over all parking spots.
    local gotit=false
    for _,_parkingspot in pairs(parkingdata) do
      local parkingspot=_parkingspot --Wrapper.Airbase#AIRBASE.ParkingSpot

      -- Check correct terminal type for asset. We don't want helos in shelters etc.
      if AIRBASE._CheckTerminalType(parkingspot.TerminalType, terminaltype) then

        -- Assume free and no problematic obstacle.
        local free=true
        local problem=nil

        -- Safe parking using TO_AC from DCS result.
        if verysafe and parkingspot.TOAC then
          free=false
          self:I(self.lid..string.format("Parking spot %d is occupied by other aircraft taking off (TOAC).", parkingspot.TerminalID))
        end

        -- Loop over all obstacles.
        for _,obstacle in pairs(obstacles) do

          -- Check if aircraft overlaps with any obstacle.
          local dist=parkingspot.Coordinate:Get2DDistance(obstacle.coord)
          local safe=_overlap(element.size, obstacle.size, dist)

          -- Spot is blocked.
          if not safe then
            free=false
            problem=obstacle
            problem.dist=dist
            break
          end

        end
        
        -- Check flightcontrol data.
        if self.flightcontrol and self.flightcontrol.airbasename==airbase:GetName() then
          local problem=self.flightcontrol:IsParkingReserved(parkingspot)
          if problem then
            free=false
          end
        end

        -- Check if spot is free
        if free then

          -- Add parkingspot for this element.
          table.insert(parking, parkingspot)

          self:I(self.lid..string.format("Parking spot %d is free for element %s!", parkingspot.TerminalID, element.name))

          -- Add the unit as obstacle so that this spot will not be available for the next unit.
          table.insert(obstacles, {coord=parkingspot.Coordinate, size=element.size, name=element.name, type="element"})

          gotit=true
          break

        else

          -- Debug output for occupied spots.
          self:I(self.lid..string.format("Parking spot %d is occupied or not big enough!", parkingspot.TerminalID))
          --if self.Debug then
          --  local coord=problem.coord --Core.Point#COORDINATE
          --  local text=string.format("Obstacle blocking spot #%d is %s type %s with size=%.1f m and distance=%.1f m.", _termid, problem.name, problem.type, problem.size, problem.dist)
          --  coord:MarkToAll(string.format(text))
          --end

        end

      end -- check terminal type
    end -- loop over parking spots

    -- No parking spot for at least one asset :(
    if not gotit then
      self:I(self.lid..string.format("WARNING: No free parking spot for element %s", element.name))
      return nil
    end
    
  end -- loop over asset units

  return parking
end

--- Size of the bounding box of a DCS object derived from the DCS descriptor table. If boundinb box is nil, a size of zero is returned.
-- @param #FLIGHTGROUP self
-- @param DCS#Object DCSobject The DCS object for which the size is needed.
-- @return #number Max size of object in meters (length (x) or width (z) components not including height (y)).
-- @return #number Length (x component) of size.
-- @return #number Height (y component) of size.
-- @return #number Width (z component) of size.
function FLIGHTGROUP:_GetObjectSize(DCSobject)
  local DCSdesc=DCSobject:getDesc()
  if DCSdesc.box then
    local x=DCSdesc.box.max.x+math.abs(DCSdesc.box.min.x)  --length
    local y=DCSdesc.box.max.y+math.abs(DCSdesc.box.min.y)  --height
    local z=DCSdesc.box.max.z+math.abs(DCSdesc.box.min.z)  --width
    return math.max(x,z), x , y, z
  end
  return 0,0,0,0
end

--- Get the generalized attribute of a group.
-- @param #FLIGHTGROUP self
-- @return #string Generalized attribute of the group.
function FLIGHTGROUP:_GetAttribute()

  -- Default
  local attribute=FLIGHTGROUP.Attribute.OTHER
  
  local group=self.group

  if group then

    --- Planes
    local transportplane=group:HasAttribute("Transports") and group:HasAttribute("Planes")
    local awacs=group:HasAttribute("AWACS")
    local fighter=group:HasAttribute("Fighters") or group:HasAttribute("Interceptors") or group:HasAttribute("Multirole fighters") or (group:HasAttribute("Bombers") and not group:HasAttribute("Strategic bombers"))
    local bomber=group:HasAttribute("Strategic bombers")
    local tanker=group:HasAttribute("Tankers")
    local uav=group:HasAttribute("UAVs")
    --- Helicopters
    local transporthelo=group:HasAttribute("Transport helicopters")
    local attackhelicopter=group:HasAttribute("Attack helicopters")
    
    -- Define attribute. Order is important.
    if transportplane then
      attribute=FLIGHTGROUP.Attribute.AIR_TRANSPORTPLANE
    elseif awacs then
      attribute=FLIGHTGROUP.Attribute.AIR_AWACS
    elseif fighter then
      attribute=FLIGHTGROUP.Attribute.AIR_FIGHTER
    elseif bomber then
      attribute=FLIGHTGROUP.Attribute.AIR_BOMBER
    elseif tanker then
      attribute=FLIGHTGROUP.Attribute.AIR_TANKER
    elseif transporthelo then
      attribute=FLIGHTGROUP.Attribute.AIR_TRANSPORTHELO
    elseif attackhelicopter then
      attribute=FLIGHTGROUP.Attribute.AIR_ATTACKHELO
    elseif uav then
      attribute=FLIGHTGROUP.Attribute.AIR_UAV
    end    
    
  end
  
  return attribute
end

--- Get the proper terminal type based on generalized attribute of the group.
--@param #FLIGHTGROUP self
--@param #FLIGHTGROUP.Attribute _attribute Generlized attibute of unit.
--@param #number _category Airbase category.
--@return Wrapper.Airbase#AIRBASE.TerminalType Terminal type for this group.
function FLIGHTGROUP:_GetTerminal(_attribute, _category)

  -- Default terminal is "large".
  local _terminal=AIRBASE.TerminalType.OpenBig

  if _attribute==FLIGHTGROUP.Attribute.AIR_FIGHTER then
    -- Fighter ==> small.
    _terminal=AIRBASE.TerminalType.FighterAircraft
  elseif _attribute==FLIGHTGROUP.Attribute.AIR_BOMBER or _attribute==FLIGHTGROUP.Attribute.AIR_TRANSPORTPLANE or _attribute==FLIGHTGROUP.Attribute.AIR_TANKER or _attribute==FLIGHTGROUP.Attribute.AIR_AWACS then
    -- Bigger aircraft.
    _terminal=AIRBASE.TerminalType.OpenBig
  elseif _attribute==FLIGHTGROUP.Attribute.AIR_TRANSPORTHELO or _attribute==FLIGHTGROUP.Attribute.AIR_ATTACKHELO then
    -- Helicopter.
    _terminal=AIRBASE.TerminalType.HelicopterUsable
  else
    --_terminal=AIRBASE.TerminalType.OpenMedOrBig
  end

  -- For ships, we allow medium spots for all fixed wing aircraft. There are smaller tankers and AWACS aircraft that can use a carrier.
  if _category==Airbase.Category.SHIP then
    if not (_attribute==FLIGHTGROUP.Attribute.AIR_TRANSPORTHELO or _attribute==FLIGHTGROUP.Attribute.AIR_ATTACKHELO) then
      _terminal=AIRBASE.TerminalType.OpenMedOrBig
    end
  end

  return _terminal
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- MENU FUNCTIONS
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get the proper terminal type based on generalized attribute of the group.
--@param #FLIGHTGROUP self
function FLIGHTGROUP:_UpdateMenu()
  self:I(self.lid.."FF updating menu")

  -- Get current position of group.
  local position=self.group:GetCoordinate()

  -- Get all FLIGHTCONTROLS
  local fc={}
  for airbasename,_flightcontrol in pairs(_DATABASE.FLIGHTCONTROLS) do
    
    local airbase=AIRBASE:FindByName(airbasename)
  
    local coord=airbase:GetCoordinate()
    
    local dist=coord:Get2DDistance(position)
    
    local fcitem={airbasename=airbasename, dist=dist}
    
    table.insert(fc, fcitem)  
  end
  
  -- Sort table wrt distance to airbases.
  local function _sort(a,b)
    return a.dist<b.dist
  end
  table.sort(fc, _sort)
    
  -- If there is a designated FC, we put it first.
  local N=8
  if self.flightcontrol then
    self.flightcontrol:_CreatePlayerMenu(self, self.menu.atc)
    N=7
  end
  
  -- Max 8 entries in F10 menu.
  for i=1,math.min(#fc,N) do
    local airbasename=fc[i].airbasename
    local flightcontrol=_DATABASE:GetFlightControl(airbasename)
    flightcontrol:_CreatePlayerMenu(self, self.menu.atc)
  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
