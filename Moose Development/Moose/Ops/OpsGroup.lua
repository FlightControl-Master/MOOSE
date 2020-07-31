--- **Ops** - Generic group enhancement functions.
-- 
-- This class is **not** meant to be used itself by the end user.
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
-- @field #number verbose Verbosity level. 0=silent.
-- @field #string lid Class id string for output to DCS log file.
-- @field #string groupname Name of the group.
-- @field Wrapper.Group#GROUP group Group object.
-- @field #table template Template of the group.
-- @field #boolean isLateActivated Is the group late activated.
-- @field #boolean isUncontrolled Is the group uncontrolled.
-- @field #table elements Table of elements, i.e. units of the group.
-- @field #boolean ai If true, group is purely AI.
-- @field #boolean isAircraft If true, group is airplane or helicopter.
-- @field #boolean isNaval If true, group is ships or submarine.
-- @field #boolean isGround If true, group is some ground unit.
-- @field #table waypoints Table of waypoints.
-- @field #table waypoints0 Table of initial waypoints.
-- @field #number currentwp Current waypoint index. This is the index of the last passed waypoint.
-- @field #boolean adinfinitum Resume route at first waypoint when final waypoint is reached.
-- @field #table taskqueue Queue of tasks.
-- @field #number taskcounter Running number of task ids.
-- @field #number taskcurrent ID of current task. If 0, there is no current task assigned.
-- @field #table taskenroute Enroute task of the group.
-- @field #table taskpaused Paused tasks.
-- @field #table missionqueue Queue of missions.
-- @field #number currentmission The ID (auftragsnummer) of the currently assigned AUFTRAG.
-- @field Core.Set#SET_UNIT detectedunits Set of detected units.
-- @field #string attribute Generalized attribute.
-- @field #number speedmax Max speed in km/h.
-- @field #number speedCruise Cruising speed in km/h.
-- @field #boolean passedfinalwp Group has passed the final waypoint.
-- @field #number wpcounter Running number counting waypoints.
-- @field #boolean respawning Group is being respawned.
-- @field Core.Set#SET_ZONE checkzones Set of zones.
-- @field Core.Set#SET_ZONE inzones Set of zones in which the group is currently in.
-- @field #boolean groupinitialized If true, group parameters were initialized.
-- @field #boolean detectionOn If true, detected units of the group are analyzed.
-- @field Ops.Auftrag#AUFTRAG missionpaused Paused mission.
-- 
-- @field Core.Point#COORDINATE position Position of the group at last status check.
-- @field #number traveldist Distance traveled in meters. This is a lower bound!
-- @field #number traveltime Time.
-- @field #boolean ispathfinding If true, group is on pathfinding route.
-- 
-- 
-- @field #OPSGROUP.Radio radio Current radio settings.
-- @field #OPSGROUP.Radio radioDefault Default radio settings.
-- @field #boolean radioOn If true, radio is currently turned on.
-- @field Core.RadioQueue#RADIOQUEUE radioQueue Radio queue.
-- 
-- @field #OPSGROUP.Beacon tacan Current TACAN settings.
-- @field #OPSGROUP.Beacon tacanDefault Default TACAN settings.
-- @field #boolean tacanOn If true, TACAN is currently active.
-- 
-- @field #OPSGROUP.Beacon icls Current ICLS settings.
-- @field #OPSGROUP.Beacon iclsDefault Default ICLS settings.
-- @field #boolean iclsOn If true, ICLS is currently active.
-- 
-- @field #OPSGROUP.Option option Current optional settings.
-- @field #OPSGROUP.Option optionDefault Default option settings. 
-- 
-- @field Core.Astar#ASTAR Astar path finding.
-- 
-- @extends Core.Fsm#FSM

--- *A small group of determined and like-minded people can change the course of history.* --- Mahatma Gandhi
--
-- ===
--
-- ![Banner Image](..\Presentations\OPSGROUP\OpsGroup_Main.jpg)
--
-- # The OPSGROUP Concept
-- 
-- The OPSGROUP class contains common functions used by other classes such as FLIGHGROUP, NAVYGROUP and ARMYGROUP.
-- Those classes inherit everything of this class and extend it with features specific to their unit category.  
-- 
-- This class is **NOT** meant to be used by the end user itself.
-- 
-- 
-- @field #OPSGROUP
OPSGROUP = {
  ClassName          = "OPSGROUP",
  Debug              = false,
  verbose            =     0,
  lid                =   nil,
  groupname          =   nil,
  group              =   nil,
  template           =   nil,
  isLateActivated    =   nil,
  waypoints          =   nil,
  waypoints0         =   nil,
  currentwp          =     1,
  elements           =    {},
  taskqueue          =    {},
  taskcounter        =   nil,
  taskcurrent        =   nil,
  taskenroute        =   nil,
  taskpaused         =    {},
  missionqueue       =    {},
  currentmission     =   nil,  
  detectedunits      =    {},
  attribute          =   nil,
  checkzones         =   nil,
  inzones            =   nil,
  groupinitialized   =   nil,
  respawning         =   nil,
  wpcounter          =     1,
  radio              =    {},
  radioDefault       =    {},
  option             =    {},
  optionDefault      =    {},
  tacan              =    {},
  tacanDefault       =    {},
  icls               =    {},
  iclsDefault        =    {},
  callsign           =    {},
  callsignDefault    =    {},
  
}

--- Status of group element.
-- @type OPSGROUP.ElementStatus
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
OPSGROUP.ElementStatus={
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

--- Ops group task status.
-- @type OPSGROUP.TaskStatus
-- @field #string SCHEDULED Task is scheduled.
-- @field #string EXECUTING Task is being executed.
-- @field #string PAUSED Task is paused.
-- @field #string DONE Task is done.
OPSGROUP.TaskStatus={
  SCHEDULED="scheduled",
  EXECUTING="executing",
  PAUSED="paused",
  DONE="done",
}

--- Ops group task status.
-- @type OPSGROUP.TaskType
-- @field #string SCHEDULED Task is scheduled and will be executed at a given time.
-- @field #string WAYPOINT Task is executed at a specific waypoint.
OPSGROUP.TaskType={
  SCHEDULED="scheduled",
  WAYPOINT="waypoint",
}

--- Task structure.
-- @type OPSGROUP.Task
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
-- @type OPSGROUP.EnrouteTask
-- @field DCS#Task DCStask DCS task structure table.
-- @field #number WaypointIndex Waypoint number at which the enroute task is added.

--- Beacon data.
-- @type OPSGROUP.Beacon
-- @field #number Channel Channel.
-- @field #number Morse Morse Code.
-- @field #string Band Band "X" or "Y" for TACAN beacon.
-- @field #string UnitName Name of the unit acting as beacon.

--- Radio data.
-- @type OPSGROUP.Radio
-- @field #number Freq Frequency
-- @field #number Modu Modulation.

--- Callsign data
-- @type OPSGROUP.Callsign
-- @field #number Name
-- @field #number Number1 Number 1
-- @field #number Number2 Number 2

--- Option data.
-- @type OPSGROUP.Option
-- @field #number ROE Rule of engagement.
-- @field #number ROT Reaction on threat.
-- @field #number Alarm Alarm state.
-- @field #number Formation Formation.
-- @field #boolean EPLRS data link.
-- @field #boolean Disperse Disperse under fire. 

--- Ammo data.
-- @type OPSGROUP.Ammo
-- @field #number Total Total amount of ammo.
-- @field #number Guns Amount of gun shells.
-- @field #number Bombs Amount of bombs.
-- @field #number Rockets Amount of rockets.
-- @field #number Torpedos Amount of torpedos.
-- @field #number Missiles Amount of missiles.
-- @field #number MissilesAA Amount of air-to-air missiles.
-- @field #number MissilesAG Amount of air-to-ground missiles.
-- @field #number MissilesAS Amount of anti-ship missiles.
-- @field #number MissilesCR Amount of cruise missiles.
-- @field #number MissilesBM Amount of ballistic missiles.

--- Waypoint data.
-- @type OPSGROUP.Waypoint
-- @field #number uid Waypoint's unit id, which is a running number.
-- @field #number speed Speed in m/s.
-- @field #number alt Altitude in meters. For submaries use negative sign for depth.
-- @field #string action Waypoint action (turning point, etc.). Ground groups have the formation here.
-- @field #table task Waypoint task combo.
-- @field #string type Waypoint type.
-- @field #number x Waypoint x-coordinate.
-- @field #number y Waypoint y-coordinate.
-- @field #boolean detour If true, this waypoint is not part of the normal route.
-- @field #boolean intowind If true, this waypoint is a turn into wind route point.
-- @field #boolean astar If true, this waypint was found by A* pathfinding algorithm.
-- @field Core.Point#COORDINATE coordinate Waypoint coordinate.

--- NavyGroup version.
-- @field #string version
OPSGROUP.version="0.2.0"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
-- TODO: Implement common functions.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new OPSGROUP class object.
-- @param #OPSGROUP self
-- @param Wrapper.Group#GROUP Group The group object. Can also be given by its group name as #string.
-- @return #OPSGROUP self
function OPSGROUP:New(Group)

  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, FSM:New()) -- #OPSGROUP
  
  -- Get group and group name.
  if type(Group)=="string" then
    self.groupname=Group
    self.group=GROUP:FindByName(self.groupname)
  else
    self.group=Group
    self.groupname=Group:GetName()
  end
    
  -- Set some string id for output to DCS.log file.
  self.lid=string.format("OPSGROUP %s |", self.groupname)
  
  -- Init set of detected units.
  self.detectedunits=SET_UNIT:New()
  
  -- Init inzone set.
  self.inzones=SET_ZONE:New()
  
  -- Init task counter.
  self.taskcurrent=0
  self.taskcounter=0
  
  -- Start state.
  self:SetStartState("InUtero")

  -- Add FSM transitions.
  --                 From State  -->   Event      -->     To State
  self:AddTransition("InUtero",       "Spawned",          "Spawned")     -- The whole group was spawned.
  self:AddTransition("*",             "Dead",             "Dead")        -- The whole group is dead. 
  self:AddTransition("*",             "Stop",             "Stopped")     -- Stop FSM.

  self:AddTransition("*",             "Status",           "*")           -- Status update.
  self:AddTransition("*",             "QueueUpdate",      "*")           -- Update task and mission queues.  

  self:AddTransition("*",             "UpdateRoute",      "*")           -- Update route of group. Only if airborne.
  self:AddTransition("*",             "Respawn",          "*")           -- Respawn group.
  self:AddTransition("*",             "PassingWaypoint",  "*")           -- Passing waypoint.
 
  self:AddTransition("*",             "DetectedUnit",      "*")           -- Add a newly detected unit to the detected units set.
  self:AddTransition("*",             "DetectedUnitNew",   "*")           -- Add a newly detected unit to the detected units set.
  self:AddTransition("*",             "DetectedUnitKnown", "*")           -- Add a newly detected unit to the detected units set.
  self:AddTransition("*",             "DetectedUnitLost",  "*")           -- Group lost a detected target.

  self:AddTransition("*",             "PassingWaypoint",   "*")           -- Group passed a waypoint.
  self:AddTransition("*",             "GotoWaypoint",      "*")           -- Group switches to a specific waypoint.

  self:AddTransition("*",             "OutOfAmmo",         "*")          -- Group is completely out of ammo.
  self:AddTransition("*",             "OutOfGuns",         "*")          -- Group is out of gun shells.
  self:AddTransition("*",             "OutOfRockets",      "*")          -- Group is out of rockets.
  self:AddTransition("*",             "OutOfBombs",        "*")          -- Group is out of bombs.
  self:AddTransition("*",             "OutOfMissiles",     "*")          -- Group is out of missiles.

  self:AddTransition("*",             "CheckZone",        "*")           -- Check if group enters/leaves a certain zone.
  self:AddTransition("*",             "EnterZone",        "*")           -- Group entered a certain zone.
  self:AddTransition("*",             "LeaveZone",        "*")           -- Group leaves a certain zone.

  self:AddTransition("*",             "TaskExecute",      "*")           -- Group will execute a task.
  self:AddTransition("*",             "TaskPause",        "*")           -- Pause current task. Not implemented yet!
  self:AddTransition("*",             "TaskCancel",       "*")           -- Cancel current task.
  self:AddTransition("*",             "TaskDone",         "*")           -- Task is over.
  
  self:AddTransition("*",             "MissionStart",     "*")           -- Mission is started.
  self:AddTransition("*",             "MissionExecute",   "*")           -- Mission execution began.
  self:AddTransition("*",             "MissionCancel",     "*")          -- Cancel current mission.
  self:AddTransition("*",             "PauseMission",     "*")           -- Pause the current mission.
  self:AddTransition("*",             "UnpauseMission",   "*")           -- Unpause the the paused mission.
  self:AddTransition("*",             "MissionDone",      "*")           -- Mission is over.

  self:AddTransition("*",             "ElementSpawned",   "*")           -- An element was spawned.
  self:AddTransition("*",             "ElementDead",      "*")           -- An element is dead.

  ------------------------
  --- Pseudo Functions ---
  ------------------------

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

  -- TODO: Add pseudo functions.

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

--- Returns the absolute (average) life points of the group.
-- @param #OPSGROUP self
-- @return #number Life points. If group contains more than one element, the average is given.
-- @return #number Initial life points.
function OPSGROUP:GetLifePoints()
  if self.group then
    return self.group:GetLife(), self.group:GetLife0()
  end
end

--- Set detection on or off.
-- @param #OPSGROUP self
-- @param #boolean Switch If true, detection is on. If false or nil, detection is off. Default is off.
-- @return #OPSGROUP self
function OPSGROUP:SetDetection(Switch)
  self.detectionOn=Switch
  return self
end

--- Define a SET of zones that trigger and event if the group enters or leaves any of the zones.
-- @param #OPSGROUP self
-- @param Core.Set#SET_ZONE CheckZonesSet Set of zones.
-- @return #OPSGROUP self
function OPSGROUP:SetCheckZones(CheckZonesSet)
  self.checkzones=CheckZonesSet
  return self
end

--- Add a zone that triggers and event if the group enters or leaves any of the zones.
-- @param #OPSGROUP self
-- @param Core.Zone#ZONE CheckZone Zone to check.
-- @return #OPSGROUP self
function OPSGROUP:AddCheckZone(CheckZone)
  if not self.checkzones then
    self.checkzones=SET_ZONE:New()
  end
  self.checkzones:AddZone(CheckZone)
  return self
end

--- Get set of detected units.
-- @param #OPSGROUP self
-- @return Core.Set#SET_UNIT Set of detected units.
function OPSGROUP:GetDetectedUnits()
  return self.detectedunits
end

--- Get MOOSE GROUP object.
-- @param #OPSGROUP self
-- @return Wrapper.Group#GROUP Moose group object.
function OPSGROUP:GetGroup()
  return self.group
end

--- Get the group name.
-- @param #OPSGROUP self
-- @return #string Group name.
function OPSGROUP:GetName()
  return self.groupname
end

--- Get current coordinate of the group.
-- @param #OPSGROUP self
-- @return Core.Point#COORDINATE The coordinate (of the first unit) of the group.
function OPSGROUP:GetCoordinate()
  if self:IsAlive()~=nil then
    return self.group:GetCoordinate()    
  else
    self:E(self.lid.."WARNING: Group is not alive. Cannot get coordinate!")
  end
  return nil
end

--- Get current velocity of the group.
-- @param #OPSGROUP self
-- @return #number Velocity in m/s.
function OPSGROUP:GetVelocity()
  if self:IsAlive()~=nil then
    return self.group:GetVelocityMPS()
  else
    self:E(self.lid.."WARNING: Group is not alive. Cannot get velocity!")
  end
  return nil
end

--- Get current heading of the group.
-- @param #OPSGROUP self
-- @return #number Current heading of the group in degrees.
function OPSGROUP:GetHeading()
  if self:IsAlive()~=nil then
    return self.group:GetHeading()
  else
    self:E(self.lid.."WARNING: Group is not alive. Cannot get heading!")
  end
  return nil
end



--- Check if task description is unique.
-- @param #OPSGROUP self
-- @param #string description Task destription
-- @return #boolean If true, no other task has the same description.
function OPSGROUP:CheckTaskDescriptionUnique(description)

  -- Loop over tasks in queue
  for _,_task in pairs(self.taskqueue) do
    local task=_task --#OPSGROUP.Task
    if task.description==description then
      return false
    end
  end

  return true
end


--- Activate a *late activated* group.
-- @param #OPSGROUP self
-- @param #number delay (Optional) Delay in seconds before the group is activated. Default is immediately.
-- @return #OPSGROUP self
function OPSGROUP:Activate(delay)

  if delay and delay>0 then
      self:T2(self.lid..string.format("Activating late activated group in %d seconds", delay))
      self:ScheduleOnce(delay, OPSGROUP.Activate, self)  
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
-- @param #OPSGROUP self
-- @param #number Delay Delay in seconds. Default now.
-- @param #number ExplosionPower (Optional) Explosion power in kg TNT. Default 500 kg.
-- @return #number Relative fuel in percent.
function OPSGROUP:SelfDestruction(Delay, ExplosionPower)

  if Delay and Delay>0 then
    self:ScheduleOnce(Delay, OPSGROUP.SelfDestruction, self, 0, ExplosionPower)
  else
  
    -- Loop over all elements.
    for i,_element in pairs(self.elements) do
      local element=_element --#OPSGROUP.Element
      
      local unit=element.unit
      
      if unit and unit:IsAlive() then
        unit:Explode(ExplosionPower)
      end
    end
  end

end

--- Check if group is alive.
-- @param #OPSGROUP self
-- @return #boolean *true* if group is exists and is activated, *false* if group is exist but is NOT activated. *nil* otherwise, e.g. the GROUP object is *nil* or the group is not spawned yet.
function OPSGROUP:IsAlive()

  if self.group then
    return self.group:IsAlive()
  end

  return nil
end

--- Check if this group is currently "late activated" and needs to be "activated" to appear in the mission.
-- @param #OPSGROUP self
-- @return #boolean Is this the group late activated?
function OPSGROUP:IsLateActivated()
  return self.isLateActivated
end

--- Check if group is in state in utero.
-- @param #OPSGROUP self
-- @return #boolean If true, group is not spawned yet.
function OPSGROUP:IsInUtero()
  return self:Is("InUtero")
end

--- Check if group is in state spawned.
-- @param #OPSGROUP self
-- @return #boolean If true, group is spawned.
function OPSGROUP:IsSpawned()
  return self:Is("Spawned")
end

--- Check if group is dead.
-- @param #OPSGROUP self
-- @return #boolean If true, all units/elements of the group are dead.
function OPSGROUP:IsDead()
  return self:Is("Dead")
end

--- Check if FSM is stopped.
-- @param #OPSGROUP self
-- @return #boolean If true, FSM state is stopped.
function OPSGROUP:IsStopped()
  return self:Is("Stopped")
end

--- Check if this group is currently "uncontrolled" and needs to be "started" to begin its route.
-- @param #OPSGROUP self
-- @return #boolean If this group uncontrolled.
function OPSGROUP:IsUncontrolled()
  return self.isUncontrolled
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Waypoint Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get the waypoint from its unique ID.
-- @param #OPSGROUP self
-- @param #number uid Waypoint unique ID.
-- @return #OPSGROUP.Waypoint Waypoint data.
function OPSGROUP:GetWaypointByID(uid)

  for _,_waypoint in pairs(self.waypoints) do
    local waypoint=_waypoint --#OPSGROUP.Waypoint
    if waypoint.uid==uid then
      return waypoint
    end
  end

  return nil
end

--- Get the waypoint from its index.
-- @param #OPSGROUP self
-- @param #number index Waypoint index.
-- @return #OPSGROUP.Waypoint Waypoint data.
function OPSGROUP:GetWaypointByIndex(index)

  for i,_waypoint in pairs(self.waypoints) do
    local waypoint=_waypoint --#OPSGROUP.Waypoint
    if i==index then
      return waypoint
    end
  end

  return nil
end

--- Get the waypoint index (its position in the current waypoints table).
-- @param #OPSGROUP self
-- @param #number uid Waypoint unique ID.
-- @return #OPSGROUP.Waypoint Waypoint data.
function OPSGROUP:GetWaypointIndex(uid)

  for i,_waypoint in pairs(self.waypoints) do
    local waypoint=_waypoint --#OPSGROUP.Waypoint
    if waypoint.uid==uid then
      return i
    end
  end

  return nil
end

--- Get next waypoint index.
-- @param #OPSGROUP self
-- @param #boolean cyclic If true, return first waypoint if last waypoint was reached. Default is patrol ad infinitum value set.
-- @return #number Next waypoint index.
function OPSGROUP:GetWaypointIndexNext(cyclic)

  if cyclic==nil then
    cyclic=self.adinfinitum
  end
  
  --env.info("FF cyclic = "..tostring(cyclic))
  
  local N=#self.waypoints

  local n=math.min(self.currentwp+1, N)
  
  --env.info("FF n = "..tostring(n))
  
  if cyclic and self.currentwp==N then
    n=1
    --env.info("FF cyclic n = "..tostring(n))
  end
  
  return n
end

--- Get current waypoint index. This is the index of the last passed waypoint.
-- @param #OPSGROUP self
-- @return #number Current waypoint index.
function OPSGROUP:GetWaypointIndexCurrent()  
  return self.currentwp or 1
end

--- Get waypoint.
-- @param #OPSGROUP self
-- @param #number indx Waypoint index.
-- @return #OPSGROUP.Waypoint Waypoint table.
function OPSGROUP:GetWaypoint(indx)
  return self.waypoints[indx]
end

--- Get final waypoint.
-- @param #OPSGROUP self
-- @return #OPSGROUP.Waypoint Final waypoint table.
function OPSGROUP:GetWaypointFinal()
  return self.waypoints[#self.waypoints]
end

--- Get next waypoint.
-- @param #OPSGROUP self
-- @param #boolean cyclic If true, return first waypoint if last waypoint was reached.
-- @return #OPSGROUP.Waypoint Next waypoint table.
function OPSGROUP:GetWaypointNext(cyclic)

  local n=self:GetWaypointIndexNext(cyclic)
  
  return self.waypoints[n]
end

--- Get current waypoint.
-- @param #OPSGROUP self
-- @return #OPSGROUP.Waypoint Current waypoint table.
function OPSGROUP:GetWaypointCurrent()
  return self.waypoints[self.currentwp]
end

--- Get coordinate of next waypoint of the group.
-- @param #OPSGROUP self
-- @param #boolean cyclic If true, return first waypoint if last waypoint was reached.
-- @return Core.Point#COORDINATE Coordinate of the next waypoint.
function OPSGROUP:GetNextWaypointCoordinate(cyclic)

  -- Get next waypoint  
  local waypoint=self:GetWaypointNext(cyclic)

  return waypoint.coordinate
end

--- Get waypoint coordinates.
-- @param #OPSGROUP self
-- @param #number index Waypoint index.
-- @return Core.Point#COORDINATE Coordinate of the next waypoint.
function OPSGROUP:GetWaypointCoordinate(index)
  local waypoint=self:GetWaypoint(index)
  if waypoint then
    return waypoint.coordinate
  end
  return nil
end

--- Get waypoint speed.
-- @param #OPSGROUP self
-- @param #number indx Waypoint index.
-- @return #number Speed set at waypoint in knots.
function OPSGROUP:GetWaypointSpeed(indx)

  local waypoint=self:GetWaypoint(indx)
  
  if waypoint then
    return UTILS.MpsToKnots(waypoint.speed)
  end

  return nil
end

--- Get unique ID of waypoint.
-- @param #OPSGROUP self
-- @param #number indx Waypoint index.
-- @return #number Unique ID.
function OPSGROUP:GetWaypointID(indx)

  local waypoint=self:GetWaypoint(indx)
  
  if waypoint then
    return waypoint.uid
  end

  return nil

end

--- Returns a non-zero speed to the next waypoint (even if the waypoint speed is zero).
-- @param #OPSGROUP self
-- @param #number indx Waypoint index.
-- @return #number Speed to next waypoint (>0) in knots.
function OPSGROUP:GetSpeedToWaypoint(indx)

  local speed=self:GetWaypointSpeed(indx)
  
  if speed<=0.1 then
    speed=self:GetSpeedCruise()
  end

  return speed
end

--- Get distance to waypoint.
-- @param #OPSGROUP self
-- @param #number indx Waypoint index. Default is the next waypoint.
-- @return #number Distance in meters.
function OPSGROUP:GetDistanceToWaypoint(indx)
  local dist=0
  
  if #self.waypoints>0 then

    indx=indx or self:GetWaypointIndexNext()
  
    local wp=self:GetWaypoint(indx)
  
    if wp then
    
      local coord=self:GetCoordinate()
      
      dist=coord:Get2DDistance(wp.coordinate)
    end
    
  end
  
  return dist
end

--- Get time to waypoint based on current velocity.
-- @param #OPSGROUP self
-- @param #number indx Waypoint index. Default is the next waypoint.
-- @return #number Time in seconds. If velocity is 0
function OPSGROUP:GetTimeToWaypoint(indx)
  
  local s=self:GetDistanceToWaypoint(indx)
  
  local v=self:GetVelocity()
  
  local t=s/v
  
  if t==math.inf then
    return 365*24*60*60
  elseif t==math.nan then
    return 0
  else  
    return t
  end
  
end

--- Returns the currently expected speed.
-- @param #OPSGROUP self
-- @return #number Expected speed in m/s.
function OPSGROUP:GetExpectedSpeed()

  if self:IsHolding() then
    return 0
  else
    return self.speed or 0
  end
  
end

--- Remove a waypoint with a ceratin UID.
-- @param #OPSGROUP self
-- @param #number uid Waypoint UID.
-- @return #OPSGROUP self
function OPSGROUP:RemoveWaypointByID(uid)

  local index=self:GetWaypointIndex(uid)
  
  if index then
    self:RemoveWaypoint(index)    
  end

  return self
end

--- Remove a waypoint.
-- @param #OPSGROUP self
-- @param #number wpindex Waypoint number.
-- @return #OPSGROUP self
function OPSGROUP:RemoveWaypoint(wpindex)

  if self.waypoints then
  
    -- Number of waypoints before delete.
    local N=#self.waypoints

    -- Remove waypoint.
    table.remove(self.waypoints, wpindex)
    
    -- Number of waypoints after delete.
    local n=#self.waypoints
    
    -- Debug info.
    self:I(self.lid..string.format("Removing waypoint index %d, current wp index %d. N %d-->%d", wpindex, self.currentwp, N, n))
  
    -- Waypoint was not reached yet.
    if wpindex > self.currentwp then
    
      ---
      -- Removed a FUTURE waypoint
      ---
      
      -- TODO: patrol adinfinitum.
      
      if self.currentwp>=n then
        self.passedfinalwp=true
      end
      
      env.info("FF passed final waypoint after remove! current wp = "..self.currentwp)

      self:_CheckGroupDone(1)

    else
    
      ---
      -- Removed a waypoint ALREADY PASSED
      ---
    
      -- If an already passed waypoint was deleted, we do not need to update the route.
      
      -- If current wp = 1 it stays 1. Otherwise decrease current wp.
      
      if self.currentwp==1 then
      
        if self.adinfinitum then
          self.currentwp=#self.waypoints
        else
          self.currentwp=1
        end
        
      else
        self.currentwp=self.currentwp-1
      end
      
      --self.currentwp=math.max(1, self.currentwp-1)
      env.info("FF current waypoint after remove "..self.currentwp)
    
    end
        
  end

  return self
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Task Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set DCS task. Enroute tasks are injected automatically.
-- @param #OPSGROUP self
-- @param #table DCSTask DCS task structure.
-- @return #OPSGROUP self
function OPSGROUP:SetTask(DCSTask)

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
-- @param #OPSGROUP self
-- @param #table DCSTask DCS task structure.
-- @return #OPSGROUP self
function OPSGROUP:PushTask(DCSTask)

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
-- @param #OPSGROUP self
-- @param #table DCSTask DCS task structure.
-- @return #OPSGROUP self
function OPSGROUP:ClearTasks()
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
-- @param #OPSGROUP self
-- @param #table task DCS task table structure.
-- @param #OPSGROUP.Waypoint Waypoint where the task is executed. Default is the at *next* waypoint.
-- @param #string description Brief text describing the task, e.g. "Attack SAM". 
-- @param #number prio Priority of the task. Number between 1 and 100. Default is 50.
-- @param #number duration Duration before task is cancelled in seconds counted after task started. Default never.
-- @return #OPSGROUP.Task The task structure.
function OPSGROUP:AddTaskWaypoint(task, Waypoint, description, prio, duration)
  
  -- Waypoint of task.
  Waypoint=Waypoint or self:GetWaypointNext()
    
  if Waypoint then

    -- Increase counter.
    self.taskcounter=self.taskcounter+1

    -- Task data structure.
    local newtask={} --#OPSGROUP.Task
    newtask.description=description
    newtask.status=OPSGROUP.TaskStatus.SCHEDULED
    newtask.dcstask=task
    newtask.prio=prio or 50
    newtask.id=self.taskcounter
    newtask.duration=duration
    newtask.time=0
    newtask.waypoint=Waypoint.uid
    newtask.type=OPSGROUP.TaskType.WAYPOINT
    newtask.stopflag=USERFLAG:New(string.format("%s StopTaskFlag %d", self.groupname, newtask.id))  
    newtask.stopflag:Set(0)
  
    -- Add to table.
    table.insert(self.taskqueue, newtask)
    
    -- Info.
    self:I(self.lid..string.format("Adding WAYPOINT task %s at WP %d", newtask.description, newtask.waypoint))
    self:T3({newtask=newtask})
    
    -- Update route.
    self:__UpdateRoute(-1)
  
    return newtask  
  end
  
  return nil
end

--- Add an *enroute* task.
-- @param #OPSGROUP self
-- @param #table task DCS task table structure.
function OPSGROUP:AddTaskEnroute(task)

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

--- Get the unfinished waypoint tasks
-- @param #OPSGROUP self
-- @param #number id Unique waypoint ID.
-- @return #table Table of tasks. Table could also be empty {}.
function OPSGROUP:GetTasksWaypoint(id)

  -- Tasks table.    
  local tasks={}

  -- Sort queue.
  self:_SortTaskQueue()

  -- Look for first task that SCHEDULED.
  for _,_task in pairs(self.taskqueue) do
    local task=_task --#OPSGROUP.Task
    if task.type==OPSGROUP.TaskType.WAYPOINT and task.status==OPSGROUP.TaskStatus.SCHEDULED and task.waypoint==id then
      table.insert(tasks, task)
    end
  end
  
  return tasks
end

--- Sort task queue.
-- @param #OPSGROUP self
function OPSGROUP:_SortTaskQueue()

  -- Sort results table wrt prio and then start time.
  local function _sort(a, b)
    local taskA=a --#OPSGROUP.Task
    local taskB=b --#OPSGROUP.Task
    return (taskA.prio<taskB.prio) or (taskA.prio==taskB.prio and taskA.time<taskB.time)
  end
  
  --TODO: only needs to be sorted if a task was added, is done, or was removed.
  table.sort(self.taskqueue, _sort)

end


--- Count the number of tasks that still pending in the queue.
-- @param #OPSGROUP self
-- @return #number Total number of tasks remaining.
-- @return #number Number of SCHEDULED tasks remaining.
-- @return #number Number of WAYPOINT tasks remaining.
function OPSGROUP:CountRemainingTasks()

  local Ntot=0
  local Nwp=0
  local Nsched=0

  -- Loop over tasks queue.
  for _,_task in pairs(self.taskqueue) do
    local task=_task --#OPSGROUP.Task
    
    -- Task is still scheduled.
    if task.status==OPSGROUP.TaskStatus.SCHEDULED then
      
      -- Total number of tasks.
      Ntot=Ntot+1
    
      if task.type==OPSGROUP.TaskType.WAYPOINT then
        --TODO: maybe check that waypoint was not already passed?
        Nwp=Nwp+1
      elseif task.type==OPSGROUP.TaskType.SCHEDULED then
        Nsched=Nsched+1
      end
      
    end
    
  end

  return Ntot, Nsched, Nwp
end

--- Remove task from task queue.
-- @param #OPSGROUP self
-- @param #OPSGROUP.Task Task The task to be removed from the queue.
-- @return #boolean True if task could be removed.
function OPSGROUP:RemoveTask(Task)

  for i=#self.taskqueue,1,-1 do
    local task=self.taskqueue[i] --#OPSGROUP.Task
  
    if task.id==Task.id then
    
      -- Remove task from queue.
      table.remove(self.taskqueue, i)
      
      -- Update route if this is a waypoint task.
      if task.type==OPSGROUP.TaskType.WAYPOINT and task.status==OPSGROUP.TaskStatus.SCHEDULED then
        self:_CheckGroupDone(1)
        --self:__UpdateRoute(-1)
      end
      
      return true
    end  
  end
  
  return false
end

--- Get next task in queue. Task needs to be in state SCHEDULED and time must have passed.
-- @param #OPSGROUP self
-- @return #OPSGROUP.Task The next task in line or `nil`.
function OPSGROUP:_GetNextTask()

  if self.taskpaused then
    --return self.taskpaused
  end

  if #self.taskqueue==0 then
    return nil
  end

  -- Sort queue wrt prio and start time.
  self:_SortTaskQueue()

  -- Current time.
  local time=timer.getAbsTime()

  -- Look for first task that is SCHEDULED.
  for _,_task in pairs(self.taskqueue) do
    local task=_task --#OPSGROUP.Task
    if task.type==OPSGROUP.TaskType.SCHEDULED and task.status==OPSGROUP.TaskStatus.SCHEDULED and time>=task.time then
      return task
    end
  end
  
  return nil
end

--- Get the currently executed task if there is any.
-- @param #OPSGROUP self
-- @return #OPSGROUP.Task Current task or nil.
function OPSGROUP:GetTaskCurrent()
  return self:GetTaskByID(self.taskcurrent, OPSGROUP.TaskStatus.EXECUTING)
end

--- Get task by its id.
-- @param #OPSGROUP self
-- @param #number id Task id.
-- @param #string status (Optional) Only return tasks with this status, e.g. OPSGROUP.TaskStatus.SCHEDULED.
-- @return #OPSGROUP.Task The task or nil.
function OPSGROUP:GetTaskByID(id, status)

  for _,_task in pairs(self.taskqueue) do
    local task=_task --#OPSGROUP.Task

    if task.id==id then
      if status==nil or status==task.status then
        return task
      end
    end

  end

  return nil
end

--- On after TaskExecute event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.OpsGroup#OPSGROUP.Task Task The task.
function OPSGROUP:onafterTaskExecute(From, Event, To, Task)

  -- Debug message.
  local text=string.format("Task %s ID=%d execute.", tostring(Task.description), Task.id)
  MESSAGE:New(text, 10, "DEBUG"):ToAllIf(self.Debug)
  self:I(self.lid..text)
  
  -- Cancel current task if there is any.
  if self.taskcurrent>0 then
    self:TaskCancel()
  end

  -- Set current task.
  self.taskcurrent=Task.id
  
  -- Set time stamp.
  Task.timestamp=timer.getAbsTime()

  -- Task status executing.
  Task.status=OPSGROUP.TaskStatus.EXECUTING
  
  if Task.dcstask.id=="Formation" then

    -- Set of group(s) to follow Mother.
    local followSet=SET_GROUP:New():AddGroup(self.group)
    
    local param=Task.dcstask.params
    
    local followUnit=UNIT:FindByName(param.unitname)
    
    -- Define AI Formation object.
    Task.formation=AI_FORMATION:New(followUnit, followSet, "Formation", "Follow X at given parameters.")
    
    -- Formation parameters.
    Task.formation:FormationCenterWing(-param.offsetX, 50, math.abs(param.altitude), 50, param.offsetZ, 50)
    
    -- Set follow time interval.
    Task.formation:SetFollowTimeInterval(param.dtFollow)
    
    -- Formation mode.
    Task.formation:SetFlightModeFormation(self.group)
    
    -- Start formation FSM.
    Task.formation:Start()  
  
  else

    -- If task is scheduled (not waypoint) set task.
    if Task.type==OPSGROUP.TaskType.SCHEDULED then
      
      local DCStasks={}
      if Task.dcstask.id=='ComboTask' then
        -- Loop over all combo tasks.
        for TaskID, Task in ipairs(Task.dcstask.params.tasks) do
          table.insert(DCStasks, Task)
        end    
      else
        table.insert(DCStasks, Task.dcstask)
      end
  
      -- Combo task.
      local TaskCombo=self.group:TaskCombo(DCStasks)
  
      -- Stop condition!    
      local TaskCondition=self.group:TaskCondition(nil, Task.stopflag:GetName(), 1, nil, Task.duration)
      
      -- Controlled task.      
      local TaskControlled=self.group:TaskControlled(TaskCombo, TaskCondition)
      
      -- Task done.
      local TaskDone=self.group:TaskFunction("OPSGROUP._TaskDone", self, Task)
      
      -- Final task.
      local TaskFinal=self.group:TaskCombo({TaskControlled, TaskDone})
        
      -- Set task for group.
      self:SetTask(TaskFinal, 1)
          
    end
    
  end

  -- Get mission of this task (if any).
  local Mission=self:GetMissionByTaskID(self.taskcurrent)
  if Mission then
    -- Set AUFTRAG status.
    self:MissionExecute(Mission)
  end
  
end

--- On after "TaskCancel" event. Cancels the current task or simply sets the status to DONE if the task is not the current one.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #OPSGROUP.Task Task The task to cancel. Default is the current task (if any).
function OPSGROUP:onafterTaskCancel(From, Event, To, Task)
  
  -- Get current task.
  local currenttask=self:GetTaskCurrent()
  
  -- If no task, we take the current task. But this could also be *nil*!
  Task=Task or currenttask
  
  if Task then
  
    -- Check if the task is the current task?
    if currenttask and Task.id==currenttask.id then
    
      -- Current stop flag value. I noticed cases, where setting the flag to 1 would not cancel the task, e.g. when firing HARMS on a dead ship.
      local stopflag=Task.stopflag:Get()
    
      -- Debug info.
      local text=string.format("Current task %s ID=%d cancelled (flag %s=%d)", Task.description, Task.id, Task.stopflag:GetName(), stopflag)
      MESSAGE:New(text, 10, "DEBUG"):ToAllIf(self.Debug)    
      self:I(self.lid..text)
      
      -- Set stop flag. When the flag is true, the _TaskDone function is executed and calls :TaskDone()
      Task.stopflag:Set(1)
      
      if Task.dcstask.id=="Formation" then
        Task.formation:Stop()
        self:TaskDone(Task)
      elseif stopflag==1 then
        -- Manual call TaskDone if setting flag to one was not successful.
        self:TaskDone(Task)
      end
  
    else
            
      -- Debug info.
      self:I(self.lid..string.format("TaskCancel: Setting task %s ID=%d to DONE", Task.description, Task.id))
      
      -- Call task done function.      
      self:TaskDone(Task)

    end
    
  else
  
    local text=string.format("WARNING: No (current) task to cancel!")
    MESSAGE:New(text, 10, "DEBUG"):ToAllIf(self.Debug)
    self:E(self.lid..text)
    
  end
  
end

--- On before "TaskDone" event. Deny transition if task status is PAUSED.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #OPSGROUP.Task Task
function OPSGROUP:onbeforeTaskDone(From, Event, To, Task)

  local allowed=true

  if Task.status==OPSGROUP.TaskStatus.PAUSED then
    allowed=false
  end

  return allowed
end

--- On after "TaskDone" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #OPSGROUP.Task Task
function OPSGROUP:onafterTaskDone(From, Event, To, Task)

  -- Debug message.
  local text=string.format("Task done: %s ID=%d", Task.description, Task.id)
  MESSAGE:New(text, 10, "DEBUG"):ToAllIf(self.Debug)
  self:I(self.lid..text)

  -- No current task.
  if Task.id==self.taskcurrent then
    self.taskcurrent=0
  end
  
  -- Task status done.
  Task.status=OPSGROUP.TaskStatus.DONE
  
  -- Check if this task was the task of the current mission ==> Mission Done!
  local Mission=self:GetMissionByTaskID(Task.id)
  
  if Mission and Mission:IsNotOver() then
  
    local status=Mission:GetGroupStatus(self)  
  
    if status~=AUFTRAG.GroupStatus.PAUSED then
      self:T(self.lid.."Task Done ==> Mission Done!")
      self:MissionDone(Mission)
    else
      --Mission paused. Do nothing!
    end
  else
    self:T(self.lid.."Task Done but NO mission found ==> _CheckGroupDone in 1 sec")
    self:_CheckGroupDone(1)
  end
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Mission Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Add mission to queue.
-- @param #OPSGROUP self
-- @param Ops.Auftrag#AUFTRAG Mission Mission for this group.
-- @return #OPSGROUP self
function OPSGROUP:AddMission(Mission)
  
  -- Add group to mission.
  Mission:AddOpsGroup(self)
  
  -- Set group status to SCHEDULED..
  Mission:SetGroupStatus(self, AUFTRAG.GroupStatus.SCHEDULED)
  
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
-- @param #OPSGROUP self
-- @param Ops.Auftrag#AUFTRAG Mission Mission to be removed.
-- @return #OPSGROUP self
function OPSGROUP:RemoveMission(Mission)

  for i,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG
    
    if mission.auftragsnummer==Mission.auftragsnummer then
    
      -- Remove mission waypoint task.
      local Task=Mission:GetGroupWaypointTask(self)
      
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

--- Count remaining missons.
-- @param #OPSGROUP self
-- @return #number Number of missions to be done.
function OPSGROUP:CountRemainingMissison()

  local N=0

  -- Loop over mission queue.
  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG
    
    if mission and mission:IsNotOver() then
    
      -- Get group status.
      local status=mission:GetGroupStatus(self)
      
      if status~=AUFTRAG.GroupStatus.DONE and status~=AUFTRAG.GroupStatus.CANCELLED then
        N=N+1
      end
      
    end
  end
  
  return N
end

--- Get next mission.
-- @param #OPSGROUP self
-- @return Ops.Auftrag#AUFTRAG Next mission or *nil*.
function OPSGROUP:_GetNextMission()

  -- Number of missions.
  local Nmissions=#self.missionqueue

  -- Treat special cases.
  if Nmissions==0 then
    return nil
  end

  -- Sort results table wrt times they have already been engaged.
  local function _sort(a, b)
    local taskA=a --Ops.Auftrag#AUFTRAG
    local taskB=b --Ops.Auftrag#AUFTRAG
    return (taskA.prio<taskB.prio) or (taskA.prio==taskB.prio and taskA.Tstart<taskB.Tstart)
  end
  table.sort(self.missionqueue, _sort)
  
  -- Current time.
  local time=timer.getAbsTime()

  -- Look for first mission that is SCHEDULED.
  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG
    
    if mission:GetGroupStatus(self)==AUFTRAG.Status.SCHEDULED and (mission:IsReadyToGo() or self.airwing) then
      return mission
    end
  end

  return nil
end

--- Get mission by its id (auftragsnummer).
-- @param #OPSGROUP self
-- @param #number id Mission id (auftragsnummer).
-- @return Ops.Auftrag#AUFTRAG The mission.
function OPSGROUP:GetMissionByID(id)

  if not id then
    return nil
  end

  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG

    if mission.auftragsnummer==id then      
      return mission
    end

  end

  return nil
end

--- Get mission by its task id.
-- @param #OPSGROUP self
-- @param #number taskid The id of the (waypoint) task of the mission.
-- @return Ops.Auftrag#AUFTRAG The mission.
function OPSGROUP:GetMissionByTaskID(taskid)

  if taskid then
    for _,_mission in pairs(self.missionqueue) do
      local mission=_mission --Ops.Auftrag#AUFTRAG
  
      local task=mission:GetGroupWaypointTask(self)
  
      if task and task.id and task.id==taskid then      
        return mission
      end
  
    end
  end
  
  return nil
end

--- Get current mission.
-- @param #OPSGROUP self
-- @return Ops.Auftrag#AUFTRAG The current mission or *nil*.
function OPSGROUP:GetMissionCurrent()
  return self:GetMissionByID(self.currentmission)
end

--- On before "MissionStart" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.Auftrag#AUFTRAG Mission The mission table.
function OPSGROUP:onbeforeMissionStart(From, Event, To, Mission)

  -- Debug info.
  self:I(self.lid..string.format("Starting mission %s, FSM=%s, LateActivated=%s, UnControlled=%s", tostring(Mission.name), self:GetState(), tostring(self:IsLateActivated()), tostring(self:IsUncontrolled())))

  -- Delay for route to mission. Group needs to be activated and controlled.
  local delay=0

  -- Check if group is spawned.
  if self:IsInUtero() then

    -- Activate group if it is late activated.
    if self:IsLateActivated() then
      self:Activate(delay)
      --delay=delay+1
    end
  
  end
  
  -- Startup group if it is uncontrolled.
  if self.isAircraft and self:IsParking() and self:IsUncontrolled() then
    self:StartUncontrolled(delay)
  end  

  return true
end

--- On after "MissionStart" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.Auftrag#AUFTRAG Mission The mission table.
function OPSGROUP:onafterMissionStart(From, Event, To, Mission)

  -- Debug output.
  local text=string.format("Starting %s Mission %s, target %s", Mission.type, tostring(Mission.name), Mission:GetTargetName())
  self:T(self.lid..text)
  MESSAGE:New(text, 30, self.groupname):ToAllIf(self.Debug)

  -- Set current mission.
  self.currentmission=Mission.auftragsnummer
    
  -- Set group mission status to STARTED.
  Mission:SetGroupStatus(self, AUFTRAG.GroupStatus.STARTED)
  
  -- Set mission status to STARTED.
  Mission:__Started(3)

  -- Route group to mission zone.
  self:RouteToMission(Mission, 3)
  
end

--- On after "MissionExecute" event. Mission execution began.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.Auftrag#AUFTRAG Mission The mission table.
function OPSGROUP:onafterMissionExecute(From, Event, To, Mission)

  local text=string.format("Executing %s Mission %s, target %s", Mission.type, tostring(Mission.name), Mission:GetTargetName())
  self:T(self.lid..text)
  MESSAGE:New(text, 30, self.groupname):ToAllIf(self.Debug)
  
  -- Set group mission status to EXECUTING.
  Mission:SetGroupStatus(self, AUFTRAG.GroupStatus.EXECUTING)
  
  -- Set mission status to EXECUTING.
  Mission:Executing()
  
  -- Formation
  if Mission.optionFormation then
    self:SwitchFormation(Mission.optionFormation)
  end  
  
end

--- On after "PauseMission" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPSGROUP:onafterPauseMission(From, Event, To)

  local Mission=self:GetMissionCurrent()
  
  if Mission then

    -- Set group mission status to PAUSED.
    Mission:SetGroupStatus(self, AUFTRAG.GroupStatus.PAUSED)
  
    -- Get mission waypoint task.
    local Task=Mission:GetGroupWaypointTask(self)
    
    -- Debug message.
    self:I(self.lid..string.format("Pausing current mission %s. Task=%s", tostring(Mission.name), tostring(Task and Task.description or "WTF")))
  
    -- Cancelling the mission is actually cancelling the current task.
    self:TaskCancel(Task)
    
    -- Set mission to pause so we can unpause it later.
    self.missionpaused=Mission
    
  end

end

--- On after "UnpauseMission" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPSGROUP:onafterUnpauseMission(From, Event, To)

  self:I(self.lid..string.format("Unpausing mission"))
  
  if self.missionpaused then
  
    local mission=self:GetMissionByID(self.missionpaused.auftragsnummer)
    
    self:MissionStart(mission)
    
    self.missionpaused=nil
  else
    self:E(self.lid.."ERROR: No mission to unpause!")
  end
  
end


--- On after "MissionCancel" event. Cancels the mission.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.Auftrag#AUFTRAG Mission The mission to be cancelled.
function OPSGROUP:onafterMissionCancel(From, Event, To, Mission)

  if self.currentmission and Mission.auftragsnummer==self.currentmission then
    
    -- Get mission waypoint task.
    local Task=Mission:GetGroupWaypointTask(self)
    
    -- Debug info.
    self:I(self.lid..string.format("Cancel current mission %s. Task=%s", tostring(Mission.name), tostring(Task and Task.description or "WTF")))

    -- Cancelling the mission is actually cancelling the current task.
    -- Note that two things can happen.
    -- 1.) Group is still on the way to the waypoint (status should be STARTED). In this case there would not be a current task!
    -- 2.) Group already passed the mission waypoint (status should be EXECUTING).
    
    self:TaskCancel(Task)
        
  else
  
    -- Not the current mission.
    -- TODO: remove mission from queue?
 
    -- Set mission group status.
    Mission:SetGroupStatus(self, AUFTRAG.GroupStatus.CANCELLED) 
    
    -- Send group RTB or WAIT if nothing left to do.
    self:_CheckGroupDone(1)
    
  end
  
end

--- On after "MissionDone" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.Auftrag#AUFTRAG Mission
function OPSGROUP:onafterMissionDone(From, Event, To, Mission)

  -- Debug info.
  local text=string.format("Mission %s DONE!", Mission.name)
  self:I(self.lid..text)
  MESSAGE:New(text, 30, self.groupname):ToAllIf(self.Debug)
  
  -- Set group status.
  Mission:SetGroupStatus(self, AUFTRAG.GroupStatus.DONE)
  
  -- Set current mission to nil.
  if self.currentmission and Mission.auftragsnummer==self.currentmission then
    self.currentmission=nil
  end
  
  -- Remove mission waypoint.
  local wpidx=Mission:GetGroupWaypointIndex(self)
  if wpidx then
    self:RemoveWaypoint(wpidx)
  end
  
  -- Decrease patrol data.
  if Mission.patroldata then
    Mission.patroldata.noccupied=Mission.patroldata.noccupied-1
    AIRWING.UpdatePatrolPointMarker(Mission.patroldata)
  end

  -- TODO: reset mission specific parameters like radio, ROE etc.  
  
  -- Check if group is done.
  self:_CheckGroupDone(1)

end

--- Route group to mission.
-- @param #OPSGROUP self
-- @param Ops.Auftrag#AUFTRAG mission The mission table.
-- @param #number delay Delay in seconds.
function OPSGROUP:RouteToMission(mission, delay)

  if delay and delay>0 then
    -- Delayed call.
    self:ScheduleOnce(delay, OPSGROUP.RouteToMission, self, mission)
  else
        
    -- ID of current waypoint.
    local uid=self:GetWaypointCurrent().uid    
    
    -- Get coordinate where the mission is executed.    
    local waypointcoord=mission:GetMissionWaypointCoord(self.group)
    
    -- Add enroute tasks.
    for _,task in pairs(mission.enrouteTasks) do
      self:AddTaskEnroute(task)
    end
    
    -- Speed to mission waypoint.
    local SpeedToMission=UTILS.KmphToKnots(self.speedCruise)
  
    -- Add waypoint.
    local waypoint=self:AddWaypoint(waypointcoord, SpeedToMission, nil, false)
    
    -- Special for Troop transport.
    if mission.type==AUFTRAG.Type.TROOPTRANSPORT then
    
      -- Refresh DCS task with the known controllable.  
      mission.DCStask=mission:GetDCSMissionTask(self.group)
            
      -- Add task to embark for the troops.
      for _,_group in pairs(mission.transportGroupSet.Set) do
        local group=_group --Wrapper.Group#GROUP
        
        if group and group:IsAlive() then
          local DCSTask=group:TaskEmbarkToTransport(mission.transportPickup, 500)
          group:SetTask(DCSTask, 5)
        end
      
      end
    
    end
    
    -- Add waypoint task. UpdateRoute is called inside.
    local waypointtask=self:AddTaskWaypoint(mission.DCStask, waypoint, mission.name, mission.prio, mission.duration)
    
    -- Set waypoint task.
    mission:SetGroupWaypointTask(self, waypointtask)
    
    -- Set waypoint index.
    mission:SetGroupWaypointIndex(self, waypoint.uid)
    
    ---
    -- Mission Specific Settings
    ---
    
    -- ROE
    if mission.optionROE then
      self:SetOptionROE(mission.optionROE)
    end
    -- ROT
    if mission.optionROT then
      self:SetOptionROT(mission.optionROT)
    end
    -- Radio
    if mission.radioFreq then
      self:SwitchRadioOn(mission.radioFreq, mission.radioModu)
    end
    -- TACAN
    if mission.tacanChannel then
      self:SwitchTACANOn(mission.tacanChannel, mission.tacanMorse)
    end
    -- Formation
    if mission.optionFormation then
      self:SwitchFormation(mission.optionFormation)
    end
    
  end
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Queue Update: Missions & Tasks
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after "QueueUpdate" event. 
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPSGROUP:onafterQueueUpdate(From, Event, To)

  ---
  -- Mission
  ---

   -- First check if group is alive? Late activated groups are activated and uncontrolled units are started automatically.
  if self:IsAlive()~=nil then
  
    local mission=self:_GetNextMission()
    
    if mission then
    
      local currentmission=self:GetMissionCurrent()
      
      if currentmission then
      
        -- Current mission but new mission is urgent with higher prio.
        if mission.urgent and mission.prio<currentmission.prio then
          self:MissionCancel(currentmission)
          self:__MissionStart(1, mission)
        end
        
      else
        -- No current mission.
        self:MissionStart(mission)        
      end
    end
  end

  ---
  -- Tasks
  ---

  local ready=true
  
  -- For aircraft check airborne.
  if self.isAircraft then
    ready=self:IsAirborne()
  end

  -- Check no current task.
  if ready and self.taskcurrent<=0 then

    -- Get task from queue.
    local task=self:_GetNextTask()

    -- Execute task if any.
    if task then
      self:TaskExecute(task)
    end
    
  end

  -- Update queue every ~5 sec.
  if not self:IsStopped() then
    self:__QueueUpdate(-5)
  end
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Events
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after "PassingWaypoint" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #OPSGROUP.Waypoint Waypoint Waypoint data passed.
function OPSGROUP:onafterPassingWaypoint(From, Event, To, Waypoint)
  
  -- Apply tasks of this waypoint.
  local ntasks=self:_SetWaypointTasks(Waypoint)
  
  -- Get waypoint index.
  local wpindex=self:GetWaypointIndex(Waypoint.uid)

  -- Final waypoint reached?
  if wpindex==nil or wpindex==#self.waypoints then

    -- Set switch to true.    
    self.passedfinalwp=true
    
    -- Check if all tasks/mission are done? If so, RTB or WAIT.
    -- Note, we delay it for a second to let the OnAfterPassingwaypoint function to be executed in case someone wants to add another waypoint there.
    if ntasks==0 then
      self:_CheckGroupDone(1)
    end

  end

  -- Debug info.
  local text=string.format("Group passed waypoint %s/%d ID=%d: final=%s detour=%s astar=%s", 
  tostring(wpindex), #self.waypoints, Waypoint.uid, tostring(self.passedfinalwp), tostring(Waypoint.detour), tostring(Waypoint.astar))
  self:I(self.lid..text)
  MESSAGE:New(text, 30, "DEBUG"):ToAllIf(self.Debug)  
  
end

--- On after "GotoWaypoint" event. Group will got to the given waypoint and execute its route from there.
-- @param #OPSGROUP self
-- @param #OPSGROUP.Waypoint Waypoint The waypoint.
-- @return #number Number of tasks.
function OPSGROUP:_SetWaypointTasks(Waypoint)

  -- Get all waypoint tasks.
  local tasks=self:GetTasksWaypoint(Waypoint.uid)

  -- Debug info.
  local text=string.format("WP uid=%d tasks:", Waypoint.uid)
  if #tasks>0 then
    for i,_task in pairs(tasks) do
      local task=_task --#OPSGROUP.Task
      text=text..string.format("\n[%d] %s", i, task.description)
    end
  else
    text=text.." None"
  end
  self:T(self.lid..text)
  

  -- Tasks at this waypoints.
  local taskswp={}
  
  -- TODO: maybe set waypoint enroute tasks?
    
  for _,task in pairs(tasks) do
    local Task=task --Ops.OpsGroup#OPSGROUP.Task          
    
    -- Task execute.
    table.insert(taskswp, self.group:TaskFunction("OPSGROUP._TaskExecute", self, Task))

    -- Stop condition if userflag is set to 1 or task duration over.
    local TaskCondition=self.group:TaskCondition(nil, Task.stopflag:GetName(), 1, nil, Task.duration)
    
    -- Controlled task.      
    table.insert(taskswp, self.group:TaskControlled(Task.dcstask, TaskCondition))
   
    -- Task done.
    table.insert(taskswp, self.group:TaskFunction("OPSGROUP._TaskDone", self, Task))
    
  end

  -- Execute waypoint tasks.
  if #taskswp>0 then
    self:SetTask(self.group:TaskCombo(taskswp))
  end

  return #taskswp
end

--- On after "GotoWaypoint" event. Group will got to the given waypoint and execute its route from there.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number n The goto waypoint number.
function OPSGROUP:onafterGotoWaypoint(From, Event, To, n)

  -- The last waypoint passed was n-1
  self.currentwp=n-1
  
  -- TODO: switch to re-enable waypoint tasks.
  if false then
    local tasks=self:GetTasksWaypoint(n)
    
    for _,_task in pairs(tasks) do
      local task=_task --#OPSGROUP.Task
      task.status=OPSGROUP.TaskStatus.SCHEDULED
    end
    
  end
  
  -- Update the route.
  self:UpdateRoute()
  
end

--- On after "DetectedUnit" event. Add newly detected unit to detected units set.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Unit#UNIT Unit The detected unit.
function OPSGROUP:onafterDetectedUnit(From, Event, To, Unit)
  self:T2(self.lid..string.format("Detected unit %s", Unit:GetName()))
  self.detectedunits:AddUnit(Unit)
end

--- On after "DetectedUnitNew" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Unit#UNIT Unit The detected unit.
function OPSGROUP:onafterDetectedUnitNew(From, Event, To, Unit)
  self:T(self.lid..string.format("Detected New unit %s", Unit:GetName()))
end

--- On after "EnterZone" event. Sets self.inzones[zonename]=true.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Zone#ZONE Zone The zone that the group entered.
function OPSGROUP:onafterEnterZone(From, Event, To, Zone)
  local zonename=Zone and Zone:GetName() or "unknown"
  self:T2(self.lid..string.format("Entered Zone %s", zonename))
  self.inzones:Add(Zone:GetName(), Zone)
end

--- On after "LeaveZone" event. Sets self.inzones[zonename]=false.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Zone#ZONE Zone The zone that the group entered.
function OPSGROUP:onafterLeaveZone(From, Event, To, Zone)
  local zonename=Zone and Zone:GetName() or "unknown"
  self:T2(self.lid..string.format("Left Zone %s", zonename))
  self.inzones:Remove(zonename, true)
end

--- On after "CheckZone" event.
-- @param #OPSGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPSGROUP:onafterCheckZone(From, Event, To)

  if self:IsAlive()==true then
    self:_CheckInZones()
  end

  if not self:IsStopped() then
    self:__CheckZone(-1)
  end
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Internal Check Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Check if group is in zones.
-- @param #OPSGROUP self
function OPSGROUP:_CheckInZones()

  if self.checkzones then
  
    local Ncheck=self.checkzones:Count()
    local Ninside=self.inzones:Count()
    
    -- Debug info.
    self:T(self.lid..string.format("Check if group is in %d zones. Currently it is in %d zones.", self.checkzones:Count(), self.inzones:Count()))

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
      
      -- Is group currtently in this check zone?
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
-- @param #OPSGROUP self
function OPSGROUP:_CheckDetectedUnits()

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

--- Check if passed the final waypoint and, if necessary, update route.
-- @param #OPSGROUP self
-- @param #number delay Delay in seconds.
function OPSGROUP:_CheckGroupDone(delay)

  if self:IsAlive() and self.ai then

    if delay and delay>0 then
      -- Delayed call.
      self:ScheduleOnce(delay, self._CheckGroupDone, self)
    else
    
      if self.passedfinalwp then
      
        ---
        -- Passed FINAL waypoint
        ---
      
        if #self.waypoints>1 then
        
          if self.adinfinitum then
          
            -- Get positive speed to first waypoint.
            local speed=self:GetSpeedToWaypoint(1)
          
            -- Start route at first waypoint.
            self:__UpdateRoute(-1, 1, speed)
            
            self:I(self.lid..string.format("Passed final WP, #WP>1, adinfinitum=TRUE ==> Goto WP 1 at speed>0"))
                        
            self.passedfinalwp=false
            
          else
            -- No further waypoints. Command a full stop.
            self:__FullStop(-1)
            
            self:I(self.lid..string.format("Passed final WP, #WP>1, adinfinitum=FALSE ==> Full Stop"))
          end
          
        elseif #self.waypoints==1 then
        
          --- Only one WP left
        
          -- The last waypoint.
          local waypoint=self.waypoints[1] --Ops.OpsGroup#OPSGROUP.Waypoint
          
          local dist=self:GetCoordinate():Get2DDistance(waypoint.coordinate)          
          
          
          if self.adinfinitum and dist>1000 then  -- Note that dist>100 caused the same wp to be passed a lot of times.
          
            self:I(self.lid..string.format("Passed final WP, #WP=1, adinfinitum=TRUE dist>1000 ==> Goto WP 1 at speed>0"))

            -- Get positive speed to first waypoint.
            local speed=self:GetSpeedToWaypoint(1)
          
            -- Start route at first waypoint.
            self:__UpdateRoute(-1, 1, speed)
            
            self.passedfinalwp=false
            
          else
          
            self:I(self.lid..string.format("Passed final WP, #WP=1, adinfinitum=FALSE or dist<1000 ==> Full Stop"))
          
            self:__FullStop(-1)
            
          end
          
        else
        
          --- No waypoints left

          -- No further waypoints. Command a full stop.
          self:__FullStop(-1)
          
        end
    
      else
      
        ---
        -- Final waypoint NOT passed yet
        ---
      
        if #self.waypoints>0 then
          self:I(self.lid..string.format("NOT Passed final WP, #WP>0 ==> Update Route"))
          self:__UpdateRoute(-1)
        else
          self:E(self.lid..string.format("WARNING: No waypoints left! Commanding a Full Stop"))
          self:__FullStop(-1)
        end
        
      end
    
    end
    
  end
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Waypoints & Routing
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Initialize Mission Editor waypoints.
-- @param #OPSGROUP self
-- @param #OPSGROUP.Waypoint waypoint DCS waypoint data table.
-- @return #OPSGROUP.Waypoint Waypoint data.
function OPSGROUP:_CreateWaypoint(waypoint, formation, detour)
  
  waypoint.uid=self.wpcounter  
  waypoint.coordinate=COORDINATE:New(waypoint.x, waypoint.alt, waypoint.y)
  waypoint.detour=detour and detour or false
  if formation then
    waypoint.action=formation
  end
  waypoint.npassed=0
  waypoint.patrol=false

  self.wpcounter=self.wpcounter+1
  
  return waypoint
end

--- Initialize Mission Editor waypoints.
-- @param #OPSGROUP self
-- @param #OPSGROUP.Waypoint waypoint Waypoint data.
-- @param #number wpnumber Waypoint index/number. Default is as last waypoint.
function OPSGROUP:_AddWaypoint(waypoint, wpnumber)

  wpnumber=wpnumber or #self.waypoints+1
  
  self:I(self.lid..string.format("Adding waypoint at index=%d id=%d", wpnumber, waypoint.uid))

  -- Add waypoint to table.
  table.insert(self.waypoints, wpnumber, waypoint)

end

--- Initialize Mission Editor waypoints.
-- @param #OPSGROUP self
-- @return #OPSGROUP self
function OPSGROUP:InitWaypoints()

  -- Template waypoints.
  self.waypoints0=self.group:GetTemplateRoutePoints()

  -- Waypoints  
  self.waypoints={}
  
  for index,wp in pairs(self.waypoints0) do
  
    local waypoint=self:_CreateWaypoint(wp)
    
    self:_AddWaypoint(waypoint)
     
  end
  
  -- Debug info.
  self:I(self.lid..string.format("Initializing %d waypoints", #self.waypoints))
  
  -- Update route.
  if #self.waypoints>0 then
  
    -- Check if only 1 wp?
    if #self.waypoints==1 then
      self.passedfinalwp=true
    end
    
  end

  return self
end

--- Route group along waypoints.
-- @param #OPSGROUP self
-- @param #table waypoints Table of waypoints.
-- @param #number delay Delay in seconds.
-- @return #OPSGROUP self
function OPSGROUP:Route(waypoints, delay)

  if delay and delay>0 then
    self:ScheduleOnce(delay, OPSGROUP.Route, self, waypoints)
  else

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
      self:E(self.lid.."ERROR: Group is not alive! Cannot route group.")
    end
  end
  
  return self
end



--- Initialize Mission Editor waypoints.
-- @param #OPSGROUP self
-- @param #number n Waypoint
function OPSGROUP:_UpdateWaypointTasks(n)

  local waypoints=self.waypoints
  local nwaypoints=#waypoints

  for i,_wp in pairs(waypoints) do
    local wp=_wp --Ops.OpsGroup#OPSGROUP.Waypoint 
    
    if i>=n or nwaypoints==1 then
    
      -- Debug info.
      self:I(self.lid..string.format("Updating waypoint task for waypoint %d/%d ID=%d. Last waypoint passed %d", i, nwaypoints, wp.uid, self.currentwp))
  
      -- Tasks of this waypoint
      local taskswp={}
    
      -- At each waypoint report passing.
      local TaskPassingWaypoint=self.group:TaskFunction("OPSGROUP._PassingWaypoint", self, wp.uid)
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
--@param Wrapper.Group#GROUP group Group that passed the waypoint.
--@param #OPSGROUP opsgroup Ops group object.
--@param #number uid Waypoint UID.
function OPSGROUP._PassingWaypoint(group, opsgroup, uid)
  
  -- Get waypoint data.
  local waypoint=opsgroup:GetWaypointByID(uid)
  
  if waypoint then
  
    -- Get the current waypoint index.
    opsgroup.currentwp=opsgroup:GetWaypointIndex(uid)
    
    -- Increase passing counter.
    waypoint.npassed=waypoint.npassed+1
    
    -- Set expected speed and formation from the next WP.
    local wpnext=opsgroup:GetWaypointNext()  
    if wpnext then
      
      -- Set formation.
      if opsgroup.isGround then
        opsgroup.formation=wpnext.action
      end
      
      -- Set speed.
      opsgroup.speed=wpnext.speed
      
    end
    
    -- Check if the group is still pathfinding.
    if opsgroup.ispathfinding and not waypoint.astar then
      opsgroup.ispathfinding=false
    end  
    
    -- Check special waypoints.
    if waypoint.astar then
    
      env.info("FF removing Astar waypoint "..uid)
      opsgroup:RemoveWaypointByID(uid)
      
    elseif waypoint.detour then
    
      env.info("FF removing Detour waypoint "..uid)
      opsgroup:RemoveWaypointByID(uid)
      
      -- Trigger event.
      opsgroup:DetourReached()
      
      if waypoint.detour==0 then
        opsgroup:FullStop()
      elseif waypoint.detour==1 then
        opsgroup:Cruise()
      else
        opsgroup:E("ERROR: waypoint.detour should be 0 or 1")
      end
      
    end
  
    -- Debug message.
    local text=string.format("Group passing waypoint uid=%d", uid)
    opsgroup:I(opsgroup.lid..text)
  
    -- Trigger PassingWaypoint event.
    if not (waypoint.astar or waypoint.detour) then
      opsgroup:PassingWaypoint(waypoint)
    end
    
  end

end

--- Function called when a task is executed.
--@param Wrapper.Group#GROUP group Group which should execute the task.
--@param #OPSGROUP opsgroup Ops group.
--@param #OPSGROUP.Task task Task.
function OPSGROUP._TaskExecute(group, opsgroup, task)

  -- Debug message.
  local text=string.format("_TaskExecute %s", task.description)
  opsgroup:T3(opsgroup.lid..text)

  -- Set current task to nil so that the next in line can be executed.
  if opsgroup then
    opsgroup:TaskExecute(task)
  end
end

--- Function called when a task is done.
--@param Wrapper.Group#GROUP group Group for which the task is done.
--@param #OPSGROUP opsgroup Ops group.
--@param #OPSGROUP.Task task Task.
function OPSGROUP._TaskDone(group, opsgroup, task)

  -- Debug message.
  local text=string.format("_TaskDone %s", task.description)
  opsgroup:T3(opsgroup.lid..text)

  -- Set current task to nil so that the next in line can be executed.
  if opsgroup then
    opsgroup:TaskDone(task)
  end
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- OPTION FUNCTIONS
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set the default ROE for the group. This is the ROE state gets when the group is spawned or to which it defaults back after a mission.
-- @param #OPSGROUP self
-- @param #number roe ROE of group. Default is `ENUMS.ROE.ReturnFire`.
-- @return #OPSGROUP self
function OPSGROUP:SetDefaultROE(roe)
  self.optionDefault.ROE=roe or ENUMS.ROE.ReturnFire
  return self
end

--- Set current ROE for the group.
-- @param #OPSGROUP self
-- @param #string roe ROE of group. Default is the value defined by :SetDefaultROE().
-- @return #OPSGROUP self
function OPSGROUP:SwitchROE(roe)

  self.option.ROE=roe or self.optionDefault.ROE
  
  if self:IsAlive() then
  
    self.group:OptionROE(self.option.ROE)
    
    self:I(self.lid..string.format("Setting current ROE=%d (0=WeaponFree, 1=OpenFireWeaponFree, 2=OpenFire, 3=ReturnFire, 4=WeaponHold)", self.roe))
  else
    -- TODO WARNING
  end
  
  return self
end

--- Get current ROE of the group.
-- @param #OPSGROUP self
-- @return #number Current ROE.
function OPSGROUP:GetROE()
  return self.option.ROE
end

--- Set the default ROT for the group. This is the ROT state gets when the group is spawned or to which it defaults back after a mission.
-- @param #OPSGROUP self
-- @param #number rot ROT of group. Default is ENUMS.ROT.PassiveDefense.
-- @return #OPSGROUP self
function OPSGROUP:SetDefaultROT(rot)
  self.optionDefault.ROT=rot or ENUMS.ROT.PassiveDefense
  return self
end

--- Set ROT for the group.
-- @param #OPSGROUP self
-- @param #string rot ROT of group. Default is the value defined by :SetDefaultROT().
-- @return #OPSGROUP self
function OPSGROUP:SwitchROT(rot)

  self.option.ROT=rot or self.optionDefault.ROT
  
  if self:IsAlive() then
  
    self.group:OptionROT(self.option.ROT)
    
    self:T2(self.lid..string.format("Setting current ROT=%d (0=NoReaction, 1=Passive, 2=Evade, 3=ByPass, 4=AllowAbort)", self.rot))
  else
    -- TODO WARNING
  end
  
  return self
end

--- Get current ROT of the group.
-- @param #OPSGROUP self
-- @return #number Current ROT.
function OPSGROUP:GetROT()
  return self.option.ROT
end


--- Set the default Alarm State for the group. This is the state gets when the group is spawned or to which it defaults back after a mission.
-- @param #OPSGROUP self
-- @param #number alarmstate Alarm state of group. Default is `AI.Option.Ground.val.ALARM_STATE.AUTO` (0).
-- @return #OPSGROUP self
function OPSGROUP:SetDefaultAlarmstate(alarmstate)
  self.optionDefault.Alarm=alarmstate or 0
  return self
end

--- Set current Alarm State of the group.
-- @param #OPSGROUP self
-- @param #string alarmstate Alarm state of group. Default is the value defined by :SetDefaultAlarmstate().
-- @return #OPSGROUP self
function OPSGROUP:SwitchAlarmstate(alarmstate)

  self.option.Alarm=alarmstate or self.optionDefault.Alarm
  
  if self:IsAlive() then
  
    if self.option.Alarm==0 then
      self.group:OptionAlarmStateAuto()
    elseif self.option.Alarm==1 then
      self.group:OptionAlarmStateGreen()
    elseif self.option.Alarm==2 then
      self.group:OptionAlarmStateRed()
    else
      self:E("ERROR: Unknown Alarm State! Setting to AUTO.")
      self.group:OptionAlarmStateAuto()
    end
    
    self:I(self.lid..string.format("Setting current Alarm State=%d (0=Auto, 1=Green, 2=Red)", self.option.Alarm))
  else
    -- TODO WARNING
  end
  
  return self
end

--- Get current Alarm State of the group.
-- @param #OPSGROUP self
-- @return #number Current Alarm State.
function OPSGROUP:GetAlarmstate()
  return self.option.Alarm
end

--- Set default TACAN parameters. AA TACANs are always on "Y" band.
-- @param #OPSGROUP self
-- @param #number Channel TACAN channel.
-- @param #string Morse Morse code. Default "XXX".
-- @return #OPSGROUP self
function OPSGROUP:SetDefaultTACAN(Channel, Morse)

  self.tacanChannelDefault=Channel
  self.tacanMorseDefault=Morse or "XXX"
  
  self.tacan.Channel=Channel
  self.tacan.Band=Band
  self.tacan.Morse=Morse or "XXX"
  self.tacan.UnitName=UnitName

  return self
end

--- Activate TACAN beacon.
-- @param #OPSGROUP self
-- @param #number TACANChannel TACAN Channel.
-- @param #string TACANMorse TACAN morse code.
-- @return #OPSGROUP self
function OPSGROUP:SwitchTACAN(TACANChannel, TACANMorse)

  if self:IsAlive() then

    local unit=self.group:GetUnit(1)  --Wrapper.Unit#UNIT

    if unit and unit:IsAlive() then

      local Type=4
      local System=5
      local UnitID=unit:GetID()
      local TACANMode="Y"
      local Frequency=UTILS.TACANToFrequency(TACANChannel, TACANMode)

      unit:CommandActivateBeacon(Type, System, Frequency, UnitID, TACANChannel, TACANMode, true, TACANMorse, true)

      self.tacanBeacon=unit
      self.tacanChannel=TACANChannel
      self.tacanMorse=TACANMorse

      self.tacanOn=true

      self:I(self.lid..string.format("Switching TACAN to Channel %dY Morse %s", self.tacanChannel, tostring(self.tacanMorse)))

    end

  end

  return self
end

--- Deactivate TACAN beacon.
-- @param #OPSGROUP self
-- @return #OPSGROUP self
function OPSGROUP:SwitchTACANOff()

  if self.tacanBeacon and self.tacanBeacon:IsAlive() then
    self.tacanBeacon:CommandDeactivateBeacon()
  end

  self:I(self.lid..string.format("Switching TACAN OFF"))

  self.tacanOn=false

end

--- Set default Radio frequency and modulation.
-- @param #OPSGROUP self
-- @param #number Frequency Radio frequency in MHz. Default 251 MHz.
-- @param #number Modulation Radio modulation. Default `radio.Modulation.AM`.
-- @return #OPSGROUP self
function OPSGROUP:SetDefaultRadio(Frequency, Modulation)
  
  self.radioDefault.Freq=Frequency or 251
  self.radioDefault.Modu=Modulation or radio.modulation.AM
  
  return self
end

--- Get current Radio frequency and modulation.
-- @param #OPSGROUP self
-- @return #number Radio frequency in MHz or nil.
-- @return #number Radio modulation or nil.
function OPSGROUP:GetRadio()
  return self.radio.Freq, self.radio.Modu
end

--- Turn radio on.
-- @param #OPSGROUP self
-- @param #number Frequency Radio frequency in MHz.
-- @param #number Modulation Radio modulation. Default `radio.Modulation.AM`.
-- @return #OPSGROUP self
function OPSGROUP:SwitchRadio(Frequency, Modulation)

  if self:IsAlive() and Frequency then

    Modulation=Modulation or radio.Modulation.AM

    local group=self.group --Wrapper.Group#GROUP

    if not self.radioOn then
      group:SetOption(AI.Option.Air.id.SILENCE, false)
    end

    group:CommandSetFrequency(Frequency, Modulation)
    
    self.radio.Freq=Frequency
    self.radio.Modu=Modulation
    
    -- Radio is on.
    self.radioOn=true

    self:I(self.lid..string.format("Switching radio to frequency %.3f MHz %s", self.radioFreq, UTILS.GetModulationName(self.radioModu)))

  end

  return self
end

--- Turn radio off.
-- @param #OPSGROUP self
-- @return #OPSGROUP self
function OPSGROUP:TurnRadioOff()

  if self:IsAlive() then

    self.group:SetOption(AI.Option.Air.id.SILENCE, true)

    --self.radioFreq=nil
    --self.radioModu=nil
    
    -- Radio is off.
    self.radioOn=false

    self:I(self.lid..string.format("Switching radio OFF"))

  end

  return self
end

--- Set default formation.
-- @param #OPSGROUP self
-- @param #number Formation The formation the groups flies in.
-- @return #OPSGROUP self
function OPSGROUP:SetDefaultFormation(Formation)

  self.formationDefault=Formation

  return self
end

--- Switch to a specific formation.
-- @param #OPSGROUP self
-- @param #number Formation New formation the group will fly in.
-- @return #OPSGROUP self
function OPSGROUP:SwitchFormation(Formation)

  if self:IsAlive() and Formation then

    self.group:SetOption(AI.Option.Air.id.FORMATION, Formation)
    
    self.formation=Formation

    self:I(self.lid..string.format("Switching formation to %d", self.formation))

  end

  return self
end

--- Set default formation.
-- @param #OPSGROUP self
-- @param #number CallsignName Callsign name.
-- @param #number CallsignNumber Callsign number.
-- @return #OPSGROUP self
function OPSGROUP:SetDefaultCallsign(CallsignName, CallsignNumber)

  self.callsignNameDefault=CallsignName
  self.callsignNumberDefault=CallsignNumber or 1

  return self
end

--- Switch to a specific callsign.
-- @param #OPSGROUP self
-- @param #number CallsignName Callsign name.
-- @param #number CallsignNumber Callsign number.
-- @return #OPSGROUP self
function OPSGROUP:SwitchCallsign(CallsignName, CallsignNumber)

  if self:IsAlive() and CallsignName then

    self.callsignName=CallsignName
    self.callsignNumber=CallsignNumber or 1

    self:I(self.lid..string.format("Switching callsign to %d-%d", self.callsignName, self.callsignNumber))
    
    local group=self.group --Wrapper.Group#GROUP
    
    group:CommandSetCallsign(self.callsignName, self.callsignNumber)

  end

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Element and Group Status Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Check if all elements of the group have the same status (or are dead).
-- @param #OPSGROUP self
-- @param #string unitname Name of unit.
function OPSGROUP:_AllSameStatus(status)

  for _,_element in pairs(self.elements) do
    local element=_element --#OPSGROUP.Element

    if element.status==OPSGROUP.ElementStatus.DEAD then
      -- Do nothing. Element is already dead and does not count.
    elseif element.status~=status then
      -- At least this element has a different status.
      return false
    end

  end

  return true
end

--- Check if all elements of the group have the same status (or are dead).
-- @param #OPSGROUP self
-- @param #string status Status to check.
-- @return #boolean If true, all elements have a similar status.
function OPSGROUP:_AllSimilarStatus(status)

  -- Check if all are dead.
  if status==OPSGROUP.ElementStatus.DEAD then
    for _,_element in pairs(self.elements) do
      local element=_element --#OPSGROUP.Element
      if element.status~=OPSGROUP.ElementStatus.DEAD then
        -- At least one is still alive.
        return false
      end
    end
    return true
  end

  for _,_element in pairs(self.elements) do
    local element=_element --#OPSGROUP.Element
    
    self:T2(self.lid..string.format("Status=%s, element %s status=%s", status, element.name, element.status))

    -- Dead units dont count ==> We wont return false for those.
    if element.status~=OPSGROUP.ElementStatus.DEAD then
    
      ----------
      -- ALIVE
      ----------

      if status==OPSGROUP.ElementStatus.SPAWNED then

        -- Element SPAWNED: Check that others are not still IN UTERO
        if element.status~=status and
          element.status==OPSGROUP.ElementStatus.INUTERO  then
          return false
        end

      elseif status==OPSGROUP.ElementStatus.PARKING then

        -- Element PARKING: Check that the other are not still SPAWNED
        if element.status~=status or
         (element.status==OPSGROUP.ElementStatus.INUTERO or
          element.status==OPSGROUP.ElementStatus.SPAWNED) then
          return false
        end

      elseif status==OPSGROUP.ElementStatus.ENGINEON then

        -- Element TAXIING: Check that the other are not still SPAWNED or PARKING
        if element.status~=status and
         (element.status==OPSGROUP.ElementStatus.INUTERO or
          element.status==OPSGROUP.ElementStatus.SPAWNED or
          element.status==OPSGROUP.ElementStatus.PARKING) then
          return false
        end

      elseif status==OPSGROUP.ElementStatus.TAXIING then

        -- Element TAXIING: Check that the other are not still SPAWNED or PARKING
        if element.status~=status and
         (element.status==OPSGROUP.ElementStatus.INUTERO or
          element.status==OPSGROUP.ElementStatus.SPAWNED or
          element.status==OPSGROUP.ElementStatus.PARKING or
          element.status==OPSGROUP.ElementStatus.ENGINEON) then
          return false
        end        

      elseif status==OPSGROUP.ElementStatus.TAKEOFF then

        -- Element TAKEOFF: Check that the other are not still SPAWNED, PARKING or TAXIING
        if element.status~=status and
         (element.status==OPSGROUP.ElementStatus.INUTERO or
          element.status==OPSGROUP.ElementStatus.SPAWNED or
          element.status==OPSGROUP.ElementStatus.PARKING or
          element.status==OPSGROUP.ElementStatus.ENGINEON or
          element.status==OPSGROUP.ElementStatus.TAXIING) then
          return false
        end

      elseif status==OPSGROUP.ElementStatus.AIRBORNE then

        -- Element AIRBORNE: Check that the other are not still SPAWNED, PARKING, TAXIING or TAKEOFF
        if element.status~=status and
         (element.status==OPSGROUP.ElementStatus.INUTERO or
          element.status==OPSGROUP.ElementStatus.SPAWNED or
          element.status==OPSGROUP.ElementStatus.PARKING or
          element.status==OPSGROUP.ElementStatus.ENGINEON or
          element.status==OPSGROUP.ElementStatus.TAXIING or 
          element.status==OPSGROUP.ElementStatus.TAKEOFF) then
          return false
        end

      elseif status==OPSGROUP.ElementStatus.LANDED then

        -- Element LANDED: check that the others are not still AIRBORNE or LANDING
        if element.status~=status and
         (element.status==OPSGROUP.ElementStatus.AIRBORNE or
          element.status==OPSGROUP.ElementStatus.LANDING) then
          return false
        end

      elseif status==OPSGROUP.ElementStatus.ARRIVED then

        -- Element ARRIVED: check that the others are not still AIRBORNE, LANDING, or LANDED (taxiing).
        if element.status~=status and
         (element.status==OPSGROUP.ElementStatus.AIRBORNE or
          element.status==OPSGROUP.ElementStatus.LANDING  or
          element.status==OPSGROUP.ElementStatus.LANDED)  then
          return false
        end

      end
      
    else
      -- Element is dead. We don't care unless all are dead.
    end --DEAD

  end

  -- Debug info.
  self:T2(self.lid..string.format("All %d elements have similar status %s ==> returning TRUE", #self.elements, status))
  
  return true
end

--- Check if all elements of the group have the same status or are dead.
-- @param #OPSGROUP self
-- @param #OPSGROUP.Element element Element.
-- @param #string newstatus New status of element
-- @param Wrapper.Airbase#AIRBASE airbase Airbase if applicable.
function OPSGROUP:_UpdateStatus(element, newstatus, airbase)

  -- Old status.
  local oldstatus=element.status

  -- Update status of element.
  element.status=newstatus
  
  -- Debug
  self:T3(self.lid..string.format("UpdateStatus element=%s: %s --> %s", element.name, oldstatus, newstatus))  
  for _,_element in pairs(self.elements) do
    local Element=_element -- #OPSGROUP.Element
    self:T3(self.lid..string.format("Element %s: %s", Element.name, Element.status))
  end

  if newstatus==OPSGROUP.ElementStatus.SPAWNED then
    ---
    -- SPAWNED
    ---

    if self:_AllSimilarStatus(newstatus) then
      self:__Spawned(-0.5)
    end
    
  elseif newstatus==OPSGROUP.ElementStatus.PARKING then
    ---
    -- PARKING
    ---

    if self:_AllSimilarStatus(newstatus) then
      self:__Parking(-0.5)
    end

  elseif newstatus==OPSGROUP.ElementStatus.ENGINEON then
    ---
    -- ENGINEON
    ---

    -- No FLIGHT status. Waiting for taxiing.

  elseif newstatus==OPSGROUP.ElementStatus.TAXIING then
    ---
    -- TAXIING
    ---

    if self:_AllSimilarStatus(newstatus) then
      self:__Taxiing(-0.5)
    end
    
  elseif newstatus==OPSGROUP.ElementStatus.TAKEOFF then
    ---
    -- TAKEOFF
    ---

    if self:_AllSimilarStatus(newstatus) then
      -- Trigger takeoff event. Also triggers airborne event.
      self:__Takeoff(-0.5, airbase)
    end

  elseif newstatus==OPSGROUP.ElementStatus.AIRBORNE then
    ---
    -- AIRBORNE
    ---

    if self:_AllSimilarStatus(newstatus) then
      self:__Airborne(-0.5)
    end

  elseif newstatus==OPSGROUP.ElementStatus.LANDED then
    ---
    -- LANDED
    ---

    if self:_AllSimilarStatus(newstatus) then
      self:Landed(airbase)
    end

  elseif newstatus==OPSGROUP.ElementStatus.ARRIVED then
    ---
    -- ARRIVED
    ---

    if self:_AllSimilarStatus(newstatus) then

      if self:IsLanded() then
        self:Arrived()
      elseif self:IsAirborne() then
        self:Landed()
        self:Arrived()
      end

    end

  elseif newstatus==OPSGROUP.ElementStatus.DEAD then
    ---
    -- DEAD
    ---

    if self:_AllSimilarStatus(newstatus) then
      self:Dead()
    end

  end
end

--- Set status for all elements (except dead ones).
-- @param #OPSGROUP self
-- @param #string status Element status.
function OPSGROUP:_SetElementStatusAll(status)

  for _,_element in pairs(self.elements) do
    local element=_element --#OPSGROUP.Element
    if element.status~=OPSGROUP.ElementStatus.DEAD then
      element.status=status
    end
  end

end

--- Get the element of a group.
-- @param #OPSGROUP self
-- @param #string unitname Name of unit.
-- @return #OPSGROUP.Element The element.
function OPSGROUP:GetElementByName(unitname)

  for _,_element in pairs(self.elements) do
    local element=_element --#OPSGROUP.Element

    if element.name==unitname then
      return element
    end

  end

  return nil
end

--- Get number of elements alive.
-- @param #OPSGROUP self
-- @param #string status (Optional) Only count number, which are in a special status.
-- @return #number Number of elements.
function OPSGROUP:GetNelements(status)

  local n=0
  for _,_element in pairs(self.elements) do
    local element=_element --#OPSGROUP.Element
    if element.status~=OPSGROUP.ElementStatus.DEAD then
      if element.unit and element.unit:IsAlive() then
        if status==nil or element.status==status then
          n=n+1
        end
      end
    end
  end

  
  return n
end

--- Get the number of shells a unit or group currently has. For a group the ammo count of all units is summed up.
-- @param #OPSGROUP self
-- @param #OPSGROUP.Element element The element.
-- @return #OPSGROUP.Ammo Ammo data.
function OPSGROUP:GetAmmoElement(element)
  return self:GetAmmoUnit(element.unit)
end

--- Get total amount of ammunition of the whole group.
-- @param #OPSGROUP self
-- @return #OPSGROUP.Ammo Ammo data.
function OPSGROUP:GetAmmoTot()

  local units=self.group:GetUnits()
  
  local Ammo={} --#OPSGROUP.Ammo
  Ammo.Total=0
  Ammo.Guns=0
  Ammo.Rockets=0
  Ammo.Bombs=0
  Ammo.Missiles=0
  Ammo.MissilesAA=0
  Ammo.MissilesAG=0
  Ammo.MissilesAS=0
  
  for _,_unit in pairs(units) do
    local unit=_unit --Wrapper.Unit#UNIT
    
    if unit and unit:IsAlive()~=nil then
      
      -- Get ammo of the unit.
      local ammo=self:GetAmmoUnit(unit)
      
      -- Add up total.
      Ammo.Total=Ammo.Total+ammo.Total
      Ammo.Guns=Ammo.Guns+ammo.Guns
      Ammo.Rockets=Ammo.Rockets+ammo.Rockets
      Ammo.Bombs=Ammo.Bombs+ammo.Bombs
      Ammo.Missiles=Ammo.Missiles+ammo.Missiles
      Ammo.MissilesAA=Ammo.MissilesAA+ammo.MissilesAA
      Ammo.MissilesAG=Ammo.MissilesAG+ammo.MissilesAG
      Ammo.MissilesAS=Ammo.MissilesAS+ammo.MissilesAS
    
    end
    
  end

  return Ammo
end

--- Get the number of shells a unit or group currently has. For a group the ammo count of all units is summed up.
-- @param #OPSGROUP self
-- @param Wrapper.Unit#UNIT unit The unit object.
-- @param #boolean display Display ammo table as message to all. Default false.
-- @return #OPSGROUP.Ammo Ammo data.
function OPSGROUP:GetAmmoUnit(unit, display)

  -- Default is display false.
  if display==nil then
    display=false
  end

  -- Init counter.
  local nammo=0
  local nshells=0
  local nrockets=0
  local nmissiles=0
  local nmissilesAA=0
  local nmissilesAG=0
  local nmissilesAS=0
  local nmissilesSA=0
  local nmissilesBM=0
  local nmissilesCR=0
  local ntorps=0
  local nbombs=0

  -- Output.
  local text=string.format("OPSGROUP group %s - unit %s:\n", self.groupname, unit:GetName())

  -- Get ammo table.
  local ammotable=unit:GetAmmo()

  if ammotable then

    local weapons=#ammotable

    -- Loop over all weapons.
    for w=1,weapons do

      -- Number of current weapon.
      local Nammo=ammotable[w]["count"]

      -- Type name of current weapon.
      local Tammo=ammotable[w]["desc"]["typeName"]

      local _weaponString = UTILS.Split(Tammo,"%.")
      local _weaponName   = _weaponString[#_weaponString]

      -- Get the weapon category: shell=0, missile=1, rocket=2, bomb=3, torpedo=4
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
          nmissilesAA=nmissilesAA+Nammo
        elseif MissileCategory==Weapon.MissileCategory.SAM then
          nmissiles=nmissiles+Nammo
          nmissilesSA=nmissilesSA+Nammo          
        elseif MissileCategory==Weapon.MissileCategory.ANTI_SHIP then
          nmissiles=nmissiles+Nammo
          nmissilesAS=nmissilesAS+Nammo
        elseif MissileCategory==Weapon.MissileCategory.BM then
          nmissiles=nmissiles+Nammo
          nmissilesAG=nmissilesAG+Nammo
        elseif MissileCategory==Weapon.MissileCategory.CRUISE then
          nmissiles=nmissiles+Nammo
          nmissilesCR=nmissilesCR+Nammo        
        elseif MissileCategory==Weapon.MissileCategory.OTHER then
          nmissiles=nmissiles+Nammo
          nmissilesAG=nmissilesAG+Nammo
        end

        -- Debug info.
        text=text..string.format("- %d %s missiles of type %s\n", Nammo, self:_MissileCategoryName(MissileCategory), _weaponName)
        
      elseif Category==Weapon.Category.TORPEDO then
      
        -- Add up all rockets.
        ntorps=ntorps+Nammo      

        -- Debug info.
        text=text..string.format("- %d torpedos of type %s\n", Nammo, _weaponName)

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
  nammo=nshells+nrockets+nmissiles+nbombs+ntorps

  local ammo={} --#OPSGROUP.Ammo
  ammo.Total=nammo
  ammo.Guns=nshells
  ammo.Rockets=nrockets
  ammo.Bombs=nbombs
  ammo.Torpedos=ntorps
  ammo.Missiles=nmissiles
  ammo.MissilesAA=nmissilesAA
  ammo.MissilesAG=nmissilesAG
  ammo.MissilesAS=nmissilesAS
  ammo.MissilesCR=nmissilesCR
  ammo.MissilesBM=nmissilesBM
  ammo.MissilesSA=nmissilesSA

  return ammo
end

--- Returns a name of a missile category.
-- @param #OPSGROUP self
-- @param #number categorynumber Number of missile category from weapon missile category enumerator. See https://wiki.hoggitworld.com/view/DCS_Class_Weapon
-- @return #string Missile category name.
function OPSGROUP:_MissileCategoryName(categorynumber)
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
