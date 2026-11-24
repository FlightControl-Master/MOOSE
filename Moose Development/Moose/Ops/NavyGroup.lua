--- **Ops** - Enhanced Naval Group.
-- 
-- ## Main Features:
--
--    * Let the group steam into the wind
--    * Command a full stop
--    * Patrol waypoints *ad infinitum*
--    * Collision warning, if group is heading towards a land mass or another obstacle
--    * Automatic pathfinding, e.g. around islands
--    * Let a submarine dive and surface
--    * Manage TACAN and ICLS beacons
--    * Dynamically add and remove waypoints
--    * Sophisticated task queueing system (know when DCS tasks start and end)
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
-- Demo missions can be found on [GitHub](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/develop/Ops/Navygroup)
--
-- ===
--
-- ### Author: **funkyfranky**
-- 
-- ===
-- @module Ops.NavyGroup
-- @image OPS_NavyGroup.png


--- NAVYGROUP class.
-- @type NAVYGROUP
-- @field #boolean turning If true, group is currently turning.
-- @field #number turningHeading Previous live heading used by the navigation timer.
-- @field #number turningTime Time of the previous live heading sample.
-- @field #NAVYGROUP.IntoWind intowind Into wind info.
-- @field #table Qintowind Queue of "into wind" turns.
-- @field #number intowindcounter Counter of into wind IDs.
-- @field #number depth Ordered depth in meters.
-- @field #boolean collisionwarning If true, collition warning.
-- @field #boolean pathfindingOn If true, enable pathfining.
-- @field #number pathCorridor Explicit total width of the checked naval corridor in meters; nil derives it from ship dimensions.
-- @field #boolean ispathfinding If true, group is following an ASTAR detour.
-- @field #number pathMinDepth Minimum water depth for planning and collision checks in meters; default 20.
-- @field #number pathPreferredDepth Optional preferred water depth for A* costs; nil disables the preference.
-- @field #number pathDepthWeight Strength of the optional shallow-water cost penalty; default 2.
-- @field #string pathfindingMode Navigation strategy from NAVYGROUP.PathfindingMode; default WAYPOINT.
-- @field #NAVYGROUP.NavigationCommand navigationCommand Destination shared by native routing, collision checks and full-waypoint searches.
-- @field Core.Timer#TIMER timerNavigation Timer for hull, heading and waypoint clearance checks.
-- @field Core.Pathline#PATHLINE.DepthReport LastNavigationCheck Last navigation depth check; unavailable data is distinct from an obstacle.
-- @field #table pathfindingDiagnostics Optional per-group coarse planning measurements; use GetPathfindingDiagnostics() for a copy.
-- @field #table LastPathfindingResult Last expansion report or direct-path/failure status.
-- @field Core.Astar#ASTAR pathfindingDebugSearch Owner of this group's current search-grid overlay.
-- @field #NAVYGROUP.Target engage Engage target.
-- @field #boolean intowindold Use old calculation to determine heading into wind.
-- @extends Ops.OpsGroup#OPSGROUP

--- *Something must be left to chance; nothing is sure in a sea fight above all.* -- Horatio Nelson
--
-- ===
-- 
-- # The NAVYGROUP Concept
-- 
-- This class enhances naval groups.
--
-- Navigation checks the next 5000 meters of the route every ten seconds, capped at the next waypoint.
-- These long route checks pause during turns. With pathfinding enabled, an independent short hull/heading
-- check runs every two seconds, including turns, and stops on immediate danger or unavailable depth data.
-- Terrain profiles use the configured minimum depth; neither check predicts the actual DCS turning arc.
-- CollisionWarning and ClearAhead report changes in the measured route clearance.
--
-- With SetPathfindingOn(), an obstacle triggers one bounded A* search to the next original waypoint.
-- A successful search replaces the temporary detour and submits the complete route without stopping first.
-- A failed search or unavailable depth data stops the ship with FullStop(). It stays stopped until a new
-- movement command is issued; there are no automatic retries or waypoint-callback searches.
-- Disabling pathfinding keeps collision warnings active but prevents automatic route changes and stops.
--
-- Only full-waypoint pathfinding is currently available. Selecting PathfindingMode.LOCAL raises
-- an error because the experimental local integration has been removed for a staged rebuild.
-- Standalone local searches in ASTAR and GRID remain available. Caller-stepped StartRoutePreparation()
-- prepares copied candidates from a fixed pose and explicit maneuver model without movement authority.
--
--     navy:SetPathfindingMinDepth(20)
--     navy:SetPathfindingMode(NAVYGROUP.PathfindingMode.WAYPOINT)
--     navy:SetPathfindingOn()
--
-- @field #NAVYGROUP
NAVYGROUP = {
  ClassName       = "NAVYGROUP",
  turning         = false,
  intowind        = nil,
  intowindcounter = 0,
  Qintowind       = {},
  pathCorridor    = nil,
  pathMinDepth    = 20,
  pathfindingMode = "waypoint",
  engage          = {},  
}

--- Naval pathfinding strategies. Selecting a mode does not enable pathfinding or release a hold.
-- @type NAVYGROUP.PathfindingMode
-- @field #string WAYPOINT Search all the way to the next original waypoint after detecting an obstacle (default).
-- @field #string LOCAL Removed mode. SetPathfindingMode raises an error when this value is selected.
---@enum NAVYGROUP.PathfindingMode
NAVYGROUP.PathfindingMode={WAYPOINT="waypoint",LOCAL="local"}

--- Native destination used by routing and pathfinding.
-- Preserve GotoWaypoint across speed/depth updates, but release it when mission progress or the next route leg changes.
-- @type NAVYGROUP.NavigationCommand
-- @field #number TargetUID Commanded native waypoint UID.
-- @field #number SourceUID Current mission waypoint UID when the command was recorded.
-- @field #number NextUID Next mission waypoint UID at that time; inserting a newer Detour invalidates the old command.

--- Turn into wind parameters.
-- @type NAVYGROUP.IntoWind
-- @field #number Tstart Time to start.
-- @field #number Tstop Time to stop.
-- @field #boolean Uturn U-turn.
-- @field #number Speed Speed in knots.
-- @field #number Offset Offset angle in degrees.
-- @field #number Id Unique ID of the turn.
-- @field Ops.OpsGroup#OPSGROUP.Waypoint waypoint Turn into wind waypoint.
-- @field Core.Point#COORDINATE Coordinate Coordinate where we left the route.
-- @field #number Heading Heading the boat will take in degrees.
-- @field #boolean Open Currently active.
-- @field #boolean Over This turn is over.
-- @field #boolean Recovery If `true` this is a recovery window. If `false`, this is a launch window. If `nil` this is just a turn into the wind.

--- Engage Target.
-- @type NAVYGROUP.Target
-- @field Ops.Target#TARGET Target The target.
-- @field Core.Point#COORDINATE Coordinate Last known coordinate of the target.
-- @field Ops.OpsGroup#OPSGROUP.Waypoint Waypoint the waypoint created to go to the target.
-- @field #number Speed Speed in knots.
-- @field #number Depth Depth of the engagement (submarines).
-- @field #number roe ROE backup.
-- @field #number alarmstate Alarm state backup.

--- NavyGroup version.
-- @field #string version
NAVYGROUP.version="1.0.4"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Add Retreat.
-- TODO: Submaries.
-- TODO: Extend, shorten turn into wind windows.
-- TODO: Skipper menu.
-- DONE: Add EngageTarget.
-- DONE: Add RTZ.
-- DONE: Collision warning.
-- DONE: Detour, add temporary waypoint and resume route.
-- DONE: Stop and resume route.
-- DONE: Add waypoints.
-- DONE: Add tasks.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new NAVYGROUP class object.
-- @param #NAVYGROUP self
-- @param Wrapper.Group#GROUP group The group object. Can also be given by its group name as `#string`.
-- @return #NAVYGROUP self
function NAVYGROUP:New(group)

  -- First check if we already have an OPS group for this group.
  local og=_DATABASE:GetOpsGroup(group)
  if og then
    og:I(og.lid..string.format("WARNING: OPS group already exists in data base!"))
    return og
  end

  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, OPSGROUP:New(group)) -- #NAVYGROUP
  
  -- Set some string id for output to DCS.log file.
  self.lid=string.format("NAVYGROUP %s | ", self.groupname)
  
  -- Defaults
  self:SetDefaultROE()
  self:SetDefaultAlarmstate()
  self:SetDefaultEPLRS(self.isEPLRS)
  self:SetDefaultEmission()
  self:SetDetection()  
  self:SetPatrolAdInfinitum(true)
  self:SetPathfinding(false)

  -- Add FSM transitions.
  --                 From State  -->   Event      -->     To State
  self:AddTransition("*",             "FullStop",         "Holding")     -- Hold position.
  self:AddTransition("*",             "Cruise",           "Cruising")    -- Hold position.

  self:AddTransition("*",             "RTZ",              "Returning")   -- Group is returning to (home) zone.
  self:AddTransition("Returning",     "Returned",         "Returned")    -- Group is returned to (home) zone.

  self:AddTransition("*",             "Detour",           "Cruising")    -- Make a detour to a coordinate and resume route afterwards.
  self:AddTransition("*",             "DetourReached",    "*")           -- Group reached the detour coordinate.

  self:AddTransition("*",             "Retreat",          "Retreating")  -- Order a retreat.
  self:AddTransition("Retreating",    "Retreated",        "Retreated")   -- Group retreated.

  self:AddTransition("Cruising",      "EngageTarget",     "Engaging")    -- Engage a target from Cruising state
  self:AddTransition("Holding",       "EngageTarget",     "Engaging")    -- Engage a target from Holding state
  self:AddTransition("OnDetour",      "EngageTarget",     "Engaging")    -- Engage a target from OnDetour state
  self:AddTransition("Engaging",      "Disengage",        "Cruising")    -- Disengage and back to cruising.
  
  self:AddTransition("*",             "TurnIntoWind",     "Cruising")    -- Command the group to turn into the wind.
  self:AddTransition("*",             "TurnedIntoWind",   "*")           -- Group turned into wind.
  self:AddTransition("*",             "TurnIntoWindStop", "*")           -- Stop a turn into wind.  
  self:AddTransition("*",             "TurnIntoWindOver", "*")           -- Turn into wind is over.
  
  self:AddTransition("*",             "TurningStarted",   "*")           -- Group started turning.
  self:AddTransition("*",             "TurningStopped",   "*")           -- Group stopped turning.
  
  self:AddTransition("*",             "CollisionWarning", "*")           -- Collision warning.
  self:AddTransition("*",             "ClearAhead",       "*")           -- Clear ahead.
  
  self:AddTransition("Cruising",      "Dive",             "Cruising")    -- Command a submarine to dive.
  self:AddTransition("Engaging",      "Dive",             "Engaging")    -- Command a submarine to dive.
  self:AddTransition("Cruising",      "Surface",          "Cruising")    -- Command a submarine to go to the surface.
  self:AddTransition("Engaging",      "Surface",          "Engaging")    -- Command a submarine to go to the surface.
  
  ------------------------
  --- Pseudo Functions ---
  ------------------------

  --- Triggers the FSM event "Cruise".
  -- @function [parent=#NAVYGROUP] Cruise
  -- @param #NAVYGROUP self
  -- @param #number Speed Speed in knots until next waypoint is reached.

  --- Triggers the FSM event "Cruise" after a delay.
  -- @function [parent=#NAVYGROUP] __Cruise
  -- @param #NAVYGROUP self
  -- @param #number delay Delay in seconds.
  -- @param #number Speed Speed in knots until next waypoint is reached.

  --- On after "Cruise" event.
  -- @function [parent=#NAVYGROUP] OnAfterCruise
  -- @param #NAVYGROUP self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #number Speed Speed in knots until next waypoint is reached.


  --- Triggers the FSM event "FullStop".
  -- @function [parent=#NAVYGROUP] FullStop
  -- @param #NAVYGROUP self

  --- Triggers the FSM event "FullStop" after a delay.
  -- @function [parent=#NAVYGROUP] FullStop
  -- @param #NAVYGROUP self
  -- @param #number delay Delay in seconds.

  --- On after "FullStop" event.
  -- @function [parent=#NAVYGROUP] OnAfterFullStop
  -- @param #NAVYGROUP self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.


  --- Triggers the FSM event "TurnIntoWind".
  -- @function [parent=#NAVYGROUP] TurnIntoWind
  -- @param #NAVYGROUP self
  -- @param #NAVYGROUP.IntoWind Into wind parameters.

  --- Triggers the FSM event "TurnIntoWind" after a delay.
  -- @function [parent=#NAVYGROUP] __TurnIntoWind
  -- @param #NAVYGROUP self
  -- @param #number delay Delay in seconds.
  -- @param #NAVYGROUP.IntoWind Into wind parameters.

  --- On after "TurnIntoWind" event.
  -- @function [parent=#NAVYGROUP] OnAfterTurnIntoWind
  -- @param #NAVYGROUP self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #NAVYGROUP.IntoWind Into wind parameters.


  --- Triggers the FSM event "TurnedIntoWind".
  -- @function [parent=#NAVYGROUP] TurnedIntoWind
  -- @param #NAVYGROUP self

  --- Triggers the FSM event "TurnedIntoWind" after a delay.
  -- @function [parent=#NAVYGROUP] __TurnedIntoWind
  -- @param #NAVYGROUP self
  -- @param #number delay Delay in seconds.

  --- On after "TurnedIntoWind" event.
  -- @function [parent=#NAVYGROUP] OnAfterTurnedIntoWind
  -- @param #NAVYGROUP self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.


  --- Triggers the FSM event "TurnIntoWindStop".
  -- @function [parent=#NAVYGROUP] TurnIntoWindStop
  -- @param #NAVYGROUP self

  --- Triggers the FSM event "TurnIntoWindStop" after a delay.
  -- @function [parent=#NAVYGROUP] __TurnIntoWindStop
  -- @param #NAVYGROUP self
  -- @param #number delay Delay in seconds.

  --- On after "TurnIntoWindStop" event.
  -- @function [parent=#NAVYGROUP] OnAfterTurnIntoWindStop
  -- @param #NAVYGROUP self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.


  --- Triggers the FSM event "TurnIntoWindOver".
  -- @function [parent=#NAVYGROUP] TurnIntoWindOver
  -- @param #NAVYGROUP self
  -- @param #NAVYGROUP.IntoWind IntoWindData Data table.

  --- Triggers the FSM event "TurnIntoWindOver" after a delay.
  -- @function [parent=#NAVYGROUP] __TurnIntoWindOver
  -- @param #NAVYGROUP self
  -- @param #number delay Delay in seconds.
  -- @param #NAVYGROUP.IntoWind IntoWindData Data table.

  --- On after "TurnIntoWindOver" event.
  -- @function [parent=#NAVYGROUP] OnAfterTurnIntoWindOver
  -- @param #NAVYGROUP self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #NAVYGROUP.IntoWind IntoWindData Data table.


  --- Triggers the FSM event "TurningStarted".
  -- @function [parent=#NAVYGROUP] TurningStarted
  -- @param #NAVYGROUP self

  --- Triggers the FSM event "TurningStarted" after a delay.
  -- @function [parent=#NAVYGROUP] __TurningStarted
  -- @param #NAVYGROUP self
  -- @param #number delay Delay in seconds.

  --- On after "TurningStarted" event.
  -- @function [parent=#NAVYGROUP] OnAfterTurningStarted
  -- @param #NAVYGROUP self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.


  --- Triggers the FSM event "TurningStopped".
  -- @function [parent=#NAVYGROUP] TurningStopped
  -- @param #NAVYGROUP self

  --- Triggers the FSM event "TurningStopped" after a delay.
  -- @function [parent=#NAVYGROUP] __TurningStopped
  -- @param #NAVYGROUP self
  -- @param #number delay Delay in seconds.

  --- On after "TurningStopped" event.
  -- @function [parent=#NAVYGROUP] OnAfterTurningStopped
  -- @param #NAVYGROUP self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.


  --- Triggers the FSM event "CollisionWarning".
  -- @function [parent=#NAVYGROUP] CollisionWarning
  -- @param #NAVYGROUP self

  --- Triggers the FSM event "CollisionWarning" after a delay.
  -- @function [parent=#NAVYGROUP] __CollisionWarning
  -- @param #NAVYGROUP self
  -- @param #number delay Delay in seconds.

  --- On after "CollisionWarning" event.
  -- @function [parent=#NAVYGROUP] OnAfterCollisionWarning
  -- @param #NAVYGROUP self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.


  --- Triggers the FSM event "ClearAhead".
  -- @function [parent=#NAVYGROUP] ClearAhead
  -- @param #NAVYGROUP self

  --- Triggers the FSM event "ClearAhead" after a delay.
  -- @function [parent=#NAVYGROUP] __ClearAhead
  -- @param #NAVYGROUP self
  -- @param #number delay Delay in seconds.

  --- On after "ClearAhead" event.
  -- @function [parent=#NAVYGROUP] OnAfterClearAhead
  -- @param #NAVYGROUP self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.


  --- Triggers the FSM event "Dive".
  -- @function [parent=#NAVYGROUP] Dive
  -- @param #NAVYGROUP self
  -- @param #number Depth Dive depth in meters. Default 50 meters.
  -- @param #number Speed Speed in knots until next waypoint is reached.

  --- Triggers the FSM event "Dive" after a delay.
  -- @function [parent=#NAVYGROUP] __Dive
  -- @param #NAVYGROUP self
  -- @param #number delay Delay in seconds.
  -- @param #number Depth Dive depth in meters. Default 50 meters.
  -- @param #number Speed Speed in knots until next waypoint is reached.

  --- On after "Dive" event.
  -- @function [parent=#NAVYGROUP] OnAfterDive
  -- @param #NAVYGROUP self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #number Depth Dive depth in meters. Default 50 meters.
  -- @param #number Speed Speed in knots until next waypoint is reached.


  --- Triggers the FSM event "Surface".
  -- @function [parent=#NAVYGROUP] Surface
  -- @param #NAVYGROUP self
  -- @param #number Speed Speed in knots until next waypoint is reached.

  --- Triggers the FSM event "Surface" after a delay.
  -- @function [parent=#NAVYGROUP] __Surface
  -- @param #NAVYGROUP self
  -- @param #number delay Delay in seconds.
  -- @param #number Speed Speed in knots until next waypoint is reached.

  --- On after "Surface" event.
  -- @function [parent=#NAVYGROUP] OnAfterSurface
  -- @param #NAVYGROUP self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #number Speed Speed in knots until next waypoint is reached.


  -- Init waypoints.
  self:_InitWaypoints()
  
  -- Initialize the group.
  self:_InitGroup()

  -- Handle events:
  self:HandleEvent(EVENTS.Birth,      self.OnEventBirth)
  self:HandleEvent(EVENTS.Dead,       self.OnEventDead)
  self:HandleEvent(EVENTS.RemoveUnit, self.OnEventRemoveUnit)
  self:HandleEvent(EVENTS.UnitLost,   self.OnEventRemoveUnit)  
  
  -- Start the status monitoring.
  self.timerStatus=TIMER:New(self.Status, self):Start(1, 30)

  -- Hull and heading checks run every two seconds; waypoint checks retain their ten-second cadence.
  self.timerNavigation=TIMER:New(self._CheckNavigation, self):Start(2, 2)

  -- Start queue update timer.
  self.timerQueueUpdate=TIMER:New(self._QueueUpdate, self):Start(2, 5)
  
  -- Start check zone timer.
  self.timerCheckZone=TIMER:New(self._CheckInZones, self):Start(2, 60)

  -- Add OPSGROUP to _DATABASE.
  _DATABASE:AddOpsGroup(self)
     
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

--- Set if old into wind calculation is used when carrier turns into the wind for a recovery.
-- @param #NAVYGROUP self
-- @param #boolean SwitchOn If `true` or `nil`, use old into wind calculation.
-- @return #NAVYGROUP self
function NAVYGROUP:SetIntoWindLegacy( SwitchOn )
  if SwitchOn==nil then
    SwitchOn=true
  end
  self.intowindold=SwitchOn
  return self
end


--- Add a *scheduled* task.
-- @param #NAVYGROUP self
-- @param Core.Point#COORDINATE Coordinate Coordinate of the target.
-- @param #string Clock Time when to start the attack.
-- @param #number Radius (Optional) Radius in meters. Default 100 m.
-- @param #number Nshots (Optional) Number of shots to fire. Default 3.
-- @param #number WeaponType (Optional) Type of weapon. Default auto.
-- @param #number Prio Priority of the task.
-- @return Ops.OpsGroup#OPSGROUP.Task The task data.
function NAVYGROUP:AddTaskFireAtPoint(Coordinate, Clock, Radius, Nshots, WeaponType, Prio)

  local DCStask=CONTROLLABLE.TaskFireAtPoint(nil, Coordinate:GetVec2(), Radius, Nshots, WeaponType)

  local task=self:AddTask(DCStask, Clock, nil, Prio)

  return task
end

--- Add a *waypoint* task.
-- @param #NAVYGROUP self
-- @param Core.Point#COORDINATE Coordinate Coordinate of the target.
-- @param Ops.OpsGroup#OPSGROUP.Waypoint (Optional) Waypoint Where the task is executed. Default is next waypoint.
-- @param #number Radius (Optional) Radius in meters. Default 100 m.
-- @param #number Nshots (Optional) Number of shots to fire. Default 3.
-- @param #number WeaponType (Optional) Type of weapon. Default auto.
-- @param #number Prio (Optional) Priority of the task. Defaults to 50.
-- @param #number Duration (Optional) Duration in seconds after which the task is cancelled. Default *never*.
-- @return Ops.OpsGroup#OPSGROUP.Task The task table.
function NAVYGROUP:AddTaskWaypointFireAtPoint(Coordinate, Waypoint, Radius, Nshots, WeaponType, Prio, Duration)

  Waypoint=Waypoint or self:GetWaypointNext()

  local DCStask=CONTROLLABLE.TaskFireAtPoint(nil, Coordinate:GetVec2(), Radius, Nshots, WeaponType)

  local task=self:AddTaskWaypoint(DCStask, Waypoint, nil, Prio, Duration)

  return task
end


--- Add a *scheduled* task.
-- @param #NAVYGROUP self
-- @param Wrapper.Group#GROUP TargetGroup Target group.
-- @param #number WeaponExpend (Optional) How much weapons does are used.
-- @param #number WeaponType (Optional) Type of weapon. Default auto.
-- @param #string Clock (Optional) Time when to start the attack.
-- @param #number Prio (Optional) Priority of the task. Defaults to 50.
-- @return Ops.OpsGroup#OPSGROUP.Task The task data.
function NAVYGROUP:AddTaskAttackGroup(TargetGroup, WeaponExpend, WeaponType, Clock, Prio)

  -- Leave optional DCS attack settings to TaskAttackGroup's defaults.
  local DCStask=CONTROLLABLE.TaskAttackGroup(nil, TargetGroup, WeaponType, WeaponExpend)

  local task=self:AddTask(DCStask, Clock, nil, Prio)
  
  return task
end

--- Create a turn into wind window. Note that this is not executed as it not added to the queue.
-- @param #NAVYGROUP self
-- @param #string starttime (Optional) Start time, e.g. "8:00" for eight o'clock. Default now.
-- @param #string stoptime (Optional) Stop time, e.g. "9:00" for nine o'clock. Default 90 minutes after start time.
-- @param #number speed (Optional) Speed in knots during turn into wind leg. Defaults to 20.
-- @param #boolean uturn (Optional) If true (or nil), carrier wil perform a U-turn and go back to where it came from before resuming its route to the next waypoint. If false, it will go directly to the next waypoint.
-- @param #number offset (Optional) Offset angle in degrees, e.g. to account for an angled runway. Default 0 deg.
-- @return #NAVYGROUP.IntoWind Recovery window, or nil when its timing is invalid.
function NAVYGROUP:_CreateTurnIntoWind(starttime, stoptime, speed, uturn, offset)

  -- Absolute mission time in seconds.
  local Tnow=timer.getAbsTime()

  -- Convert number to Clock.
  if starttime and type(starttime)=="number" then
    starttime=UTILS.SecondsToClock(Tnow+starttime)
  end

  -- Input or now.
  starttime=starttime or UTILS.SecondsToClock(Tnow)

  -- Set start time.
  local Tstart=UTILS.ClockToSeconds(starttime)
  
  if uturn==nil then
    uturn=true
  end

  -- Set stop time.
  local Tstop=Tstart+90*60

  if stoptime==nil then
    Tstop=Tstart+90*60
  elseif type(stoptime)=="number" then
    Tstop=Tstart+stoptime
  else
    Tstop=UTILS.ClockToSeconds(stoptime)
  end


  -- Consistancy check for timing.
  if Tstart>Tstop then
    self:E(string.format("ERROR:Into wind stop time %s lies before start time %s. Input rejected!", UTILS.SecondsToClock(Tstart), UTILS.SecondsToClock(Tstop)))
    return nil
  end
  if Tstop<=Tnow then
    self:E(string.format("WARNING: Into wind stop time %s already over. Tnow=%s! Input rejected.", UTILS.SecondsToClock(Tstop), UTILS.SecondsToClock(Tnow)))
    return nil
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

--- Add a time window, where the groups steams into the wind.
-- @param #NAVYGROUP self
-- @param #string starttime (Optional) Start time, e.g. "8:00" for eight o'clock. Default now.
-- @param #string stoptime (Optional) Stop time, e.g. "9:00" for nine o'clock. Default 90 minutes after start time.
-- @param #number speed (Optional) Wind speed on deck in knots during turn into wind leg. Default 20 knots.
-- @param #boolean uturn (Optional) If `true` (or `nil`), carrier wil perform a U-turn and go back to where it came from before resuming its route to the next waypoint. If false, it will go directly to the next waypoint.
-- @param #number offset (Optional) Offset angle clock-wise in degrees, *e.g.* to account for an angled runway. Default 0 deg. Use around -9.1ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â° for US carriers.
-- @return #NAVYGROUP.IntoWind Turn into window data table, or nil when its timing is invalid.
function NAVYGROUP:AddTurnIntoWind(starttime, stoptime, speed, uturn, offset)

  local recovery=self:_CreateTurnIntoWind(starttime, stoptime, speed, uturn, offset)

  -- Rejected windows must not enter the queue: sorting and execution require valid timestamps.
  if not recovery then
    return nil
  end
  
  --TODO: check if window is overlapping with an other and if extend the window.
  
  -- Add to table
  table.insert(self.Qintowind, recovery)

  return recovery
end

--- Get "Turn Into Wind" data. You can specify a certain ID.
-- @param #NAVYGROUP self
-- @param #number TID (Optional) Turn Into wind ID. If not given, the currently open "Turn into Wind" data is return (if there is any).
-- @return #NAVYGROUP.IntoWind Turn into window data table.
function NAVYGROUP:GetTurnIntoWind(TID)

  if TID then
  
    -- Look for a specific ID.
    for _,_turn in pairs(self.Qintowind) do
      local turn=_turn --#NAVYGROUP.IntoWind      
      if turn.Id==TID then
        return turn
      end    
    end
  
  else

    -- Return currently open window.
    return self.intowind
  
  end

  return nil
end

--- Extend duration of turn into wind.
-- @param #NAVYGROUP self
-- @param #number Duration (Optional) Duration in seconds. Default 300 sec.
-- @param #NAVYGROUP.IntoWind TurnIntoWind (Optional) Turn into window data table. If not given, the currently open one is used (if there is any).
-- @return #NAVYGROUP self
function NAVYGROUP:ExtendTurnIntoWind(Duration, TurnIntoWind)

  Duration=Duration or 300

  -- ID of turn or nil
  local TID=TurnIntoWind and TurnIntoWind.Id or nil
  
  -- Get turn data.
  local turn=self:GetTurnIntoWind(TID)
  
  if turn then
    turn.Tstop=turn.Tstop+Duration
    self:T(self.lid..string.format("Extending turn into wind by %d seconds. New stop time is %s", Duration, UTILS.SecondsToClock(turn.Tstop)))
  else
    self:E(self.lid.."Could not get turn into wind to extend!")
  end

  return self
end


--- Remove steam into wind window from queue. If the window is currently active, it is stopped first.
-- @param #NAVYGROUP self
-- @param #NAVYGROUP.IntoWind IntoWindData Turn into window data table.
-- @return #NAVYGROUP self
function NAVYGROUP:RemoveTurnIntoWind(IntoWindData)

  -- Check if this is a window currently open.
  if self.intowind and self.intowind.Id==IntoWindData.Id then
    self:TurnIntoWindStop()
    return self
  end  

  for i,_tiw in pairs(self.Qintowind) do
    local tiw=_tiw --#NAVYGROUP.IntoWind
    if tiw.Id==IntoWindData.Id then
      --env.info("FF removing window "..tiw.Id)
      table.remove(self.Qintowind, i)
      break
    end
  end
  
  return self
end


--- Check if the group is currently holding its positon.
-- @param #NAVYGROUP self
-- @return #boolean If true, group was ordered to hold.
function NAVYGROUP:IsHolding()
  return self:Is("Holding")
end

--- Check if the group is currently cruising.
-- @param #NAVYGROUP self
-- @return #boolean If true, group cruising.
function NAVYGROUP:IsCruising()
  return self:Is("Cruising")
end

--- Check if the group is currently on a detour.
-- @param #NAVYGROUP self
-- @return #boolean If true, group is on a detour
function NAVYGROUP:IsOnDetour()
  return self:Is("OnDetour")
end


--- Check if the group is currently diving.
-- @param #NAVYGROUP self
-- @return #boolean If true, group is currently diving.
function NAVYGROUP:IsDiving()
  return self:Is("Diving")
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

--- Check if the group is currently recovering aircraft.
-- @param #NAVYGROUP self
-- @return #boolean If true, group is currently recovering.
function NAVYGROUP:IsRecovering()
  if self.intowind then
    if self.intowind.Recovery==true then
      return true
    else
      return false
    end
  else
    return false    
  end
end

--- Check if the group is currently launching aircraft.
-- @param #NAVYGROUP self
-- @return #boolean If true, group is currently launching.
function NAVYGROUP:IsLaunching()
  if self.intowind then
    if self.intowind.Recovery==false then
      return true
    else
      return false
    end
  else
    return false    
  end
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Status
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Update status.
-- @param #NAVYGROUP self
function NAVYGROUP:Status()

  -- FSM state.
  local fsmstate=self:GetState()

  -- Is group alive?
  local alive=self:IsAlive()
  
  -- Report the last actual navigation measurement, or -1 when no measurement is available.
  local freepath=self.LastNavigationCheck and self.LastNavigationCheck.ClearDistance or -1
  
  -- Check if group is exists and is active.
  if alive then

    -- Update last known position, orientation, velocity.
    self:_UpdatePosition()
  
    -- Check if group has detected any units.
    self:_CheckDetectedUnits()
    
    -- Check into wind queue.
    self:_CheckTurnsIntoWind()

    -- Check ammo status.
    self:_CheckAmmoStatus()
          
    -- Check damage of elements and group.
    self:_CheckDamage()
    
    -- Check if group got stuck.
    self:_CheckStuck()
    
    -- Check if group is waiting.
    if self:IsWaiting() then
      if self.Twaiting and self.dTwait then
        if timer.getAbsTime()>self.Twaiting+self.dTwait then
          self.Twaiting=nil
          self.dTwait=nil
          if self:_CountPausedMissions()>0 then
            self:UnpauseMission()
          else          
            self:Cruise()
          end
        end
      end
    end


    -- Get current mission (if any).
    local mission=self:GetMissionCurrent()
    
    -- If mission, check if DCS task needs to be updated.
    if mission and mission.updateDCSTask  then
    
      if mission.type==AUFTRAG.Type.CAPTUREZONE then
       
        -- Get task.
        local Task=mission:GetGroupWaypointTask(self)
        
        -- Update task: Engage or get new zone.
        if mission:GetGroupStatus(self)==AUFTRAG.GroupStatus.EXECUTING or  mission:GetGroupStatus(self)==AUFTRAG.GroupStatus.STARTED then
          self:_UpdateTask(Task, mission)
        end
                  
      end
          
    end    

    
  else
    -- Check damage of elements and group.
    self:_CheckDamage()    
  end

  -- Group exists but can also be inactive.  
  if alive~=nil then

    if self.verbose>=1 then

      -- Number of elements.
      local nelem=self:CountElements()
      local Nelem=#self.elements
  
      -- Get number of tasks and missions.
      local nTaskTot, nTaskSched, nTaskWP=self:CountRemainingTasks()
      local nMissions=self:CountRemainingMissison()
      
      -- ROE and Alarm State.
      local roe=self:GetROE() or -1
      local als=self:GetAlarmstate() or -1

      -- Waypoint stuff.
      local wpidxCurr=self.currentwp
      local wpuidCurr=self:GetWaypointUIDFromIndex(wpidxCurr) or 0
      local wpidxNext=self:GetWaypointIndexNext() or 0
      local wpuidNext=self:GetWaypointUIDFromIndex(wpidxNext) or 0
      local wpN=#self.waypoints or 0
      local wpF=tostring(self.passedfinalwp)
      
      -- Speed.
      local speed=UTILS.MpsToKnots(self.velocity or 0)
      local speedEx=UTILS.MpsToKnots(self:GetExpectedSpeed())
      
      -- Altitude.
      local alt=self.position and self.position.y or 0
      
      -- Heading in degrees.
      local hdg=self.heading or 0      
      
      -- Life points.
      local life=self.life or 0
      
      -- Total ammo.            
      local ammo=self:GetAmmoTot().Total
      
      -- Detected units.
      local ndetected=self.detectionOn and tostring(self.detectedunits:Count()) or "Off"      
      
      -- Get cargo weight.
      local cargo=0
      for _,_element in pairs(self.elements) do
        local element=_element --Ops.OpsGroup#OPSGROUP.Element
        cargo=cargo+element.weightCargo
      end
      
      -- Into wind and turning status.
      local intowind=self:IsSteamingIntoWind() and UTILS.SecondsToClock(self.intowind.Tstop-timer.getAbsTime(), true) or "N/A"
      local turning=tostring(self:IsTurning())      

      -- Info text.
      local text=string.format("%s [%d/%d]: ROE/AS=%d/%d | T/M=%d/%d | Wp=%d[%d]-->%d[%d]/%d [%s] | Life=%.1f | v=%.1f (%d) | Hdg=%03d | Ammo=%d | Detect=%s | Cargo=%.1f | Turn=%s Collision=%.0f IntoWind=%s",
      fsmstate, nelem, Nelem, roe, als, nTaskTot, nMissions, wpidxCurr, wpuidCurr, wpidxNext, wpuidNext, wpN, wpF, life, speed, speedEx, hdg, ammo, ndetected, cargo, turning, freepath, intowind)
      self:I(self.lid..text)
            
    end
    
  else

    -- Info text.
    local text=string.format("State %s: Alive=%s", fsmstate, tostring(self:IsAlive()))
    self:T(self.lid..text)
  
  end

  ---
  -- Recovery Windows
  ---

  if alive and self.verbose>=2 and #self.Qintowind>0 then
  
    -- Debug output:
    local text=string.format(self.lid.."Turn into wind time windows:")
  
    -- Handle case with no recoveries.
    if #self.Qintowind==0 then
      text=text.." none!"
    end  
  
    -- Loop over all slots.
    for i,_recovery in pairs(self.Qintowind) do
      local recovery=_recovery --#NAVYGROUP.IntoWind
  
      -- Get start/stop clock strings.
      local Cstart=UTILS.SecondsToClock(recovery.Tstart)
      local Cstop=UTILS.SecondsToClock(recovery.Tstop)
  
      -- Debug text.
      text=text..string.format("\n[%d] ID=%d Start=%s Stop=%s Open=%s Over=%s", i, recovery.Id, Cstart, Cstop, tostring(recovery.Open), tostring(recovery.Over))
    end
  
    -- Debug output.
    self:I(self.lid..text)
  
  end

  ---
  -- Elements
  ---

  if self.verbose>=2 then
    local text="Elements:"
    for i,_element in pairs(self.elements) do
      local element=_element --Ops.OpsGroup#OPSGROUP.Element

      local name=element.name
      local status=element.status
      local unit=element.unit
      local life,life0=self:GetLifePoints(element)

      local life0=element.life0

      -- Get ammo.
      local ammo=self:GetAmmoElement(element)

      -- Output text for element.
      text=text..string.format("\n[%d] %s: status=%s, life=%.1f/%.1f, guns=%d, rockets=%d, bombs=%d, missiles=%d, cargo=%d/%d kg",
      i, name, status, life, life0, ammo.Guns, ammo.Rockets, ammo.Bombs, ammo.Missiles, element.weightCargo, element.weightMaxCargo)
    end
    if #self.elements==0 then
      text=text.." none!"
    end
    self:I(self.lid..text)
  end

  ---
  -- Engage Detected Targets
  ---
  if self:IsCruising() and self.detectionOn and self.engagedetectedOn then

    local targetgroup, targetdist=self:_GetDetectedTarget()

    -- If we found a group, we engage it.
    if targetgroup then
      self:I(self.lid..string.format("Engaging target group %s at distance %d meters", targetgroup:GetName(), targetdist))
      self:EngageTarget(targetgroup)
    end

  end

  ---
  -- Cargo
  ---
  
  self:_CheckCargoTransport()

  ---
  -- Tasks & Missions
  ---

  self:_PrintTaskAndMissionStatus()

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- DCS Events ==> See OPSGROUP
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- See OPSGROUP!

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Events
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after "ElementSpawned" event.
-- @param #NAVYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.OpsGroup#OPSGROUP.Element Element The group element.
function NAVYGROUP:onafterElementSpawned(From, Event, To, Element)
  self:T(self.lid..string.format("Element spawned %s", Element.name))

  -- Set element status.
  self:_UpdateStatus(Element, OPSGROUP.ElementStatus.SPAWNED)

end

--- On after "Spawned" event.
-- @param #NAVYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function NAVYGROUP:onafterSpawned(From, Event, To)
  self:T(self.lid..string.format("Group spawned!"))

  -- Debug info.
  if self.verbose>=1 then
    local text=string.format("Initialized Navy Group %s [GID=%d]:\n", self.groupname, self.group:GetID())
    text=text..string.format("Unit type     = %s\n", self.actype)
    text=text..string.format("Speed max    = %.1f Knots\n", UTILS.KmphToKnots(self.speedMax))
    text=text..string.format("Speed cruise = %.1f Knots\n", UTILS.KmphToKnots(self.speedCruise))
    text=text..string.format("Weight       = %.1f kg\n", self:GetWeightTotal())
    text=text..string.format("Cargo bay    = %.1f kg\n", self:GetFreeCargobay())
    text=text..string.format("Has EPLRS    = %s\n", tostring(self.isEPLRS))    
    text=text..string.format("Is Submarine = %s\n", tostring(self.isSubmarine))    
    text=text..string.format("Elements     = %d\n", #self.elements)
    text=text..string.format("Waypoints    = %d\n", #self.waypoints)
    text=text..string.format("Radio        = %.1f MHz %s %s\n", self.radio.Freq, UTILS.GetModulationName(self.radio.Modu), tostring(self.radio.On))
    text=text..string.format("Ammo         = %d (G=%d/C=%d/R=%d/M=%d/T=%d)\n", self.ammo.Total, self.ammo.Guns, self.ammo.Cannons, self.ammo.Rockets, self.ammo.Missiles, self.ammo.Torpedos)
    text=text..string.format("FSM state    = %s\n", self:GetState())
    text=text..string.format("Is alive     = %s\n", tostring(self:IsAlive()))
    text=text..string.format("LateActivate = %s\n", tostring(self:IsLateActivated()))
    self:I(self.lid..text)
  end

  -- Update position.
  self:_UpdatePosition()
  
  -- Not dead or destroyed yet.
  self.isDead=false
  self.isDestroyed=false  

  if self.isAI then
 
    -- Set default ROE.
    self:SwitchROE(self.option.ROE)
    
    -- Set default Alarm State.
    self:SwitchAlarmstate(self.option.Alarm)
    
    -- Set emission.
    self:SwitchEmission(self.option.Emission)    
    
    -- Set default EPLRS.
    self:SwitchEPLRS(self.option.EPLRS)
    
    -- Set default Invisible.
    self:SwitchInvisible(self.option.Invisible)    

    -- Set default Immortal.
    self:SwitchImmortal(self.option.Immortal)    
    
    -- Set TACAN beacon.
    self:_SwitchTACAN()
    
    -- Turn ICLS on.
    self:_SwitchICLS()    

    -- Set radio.
    if self.radioDefault then
      -- CAREFUL: This makes DCS crash for some ships like speed boats or Higgins boats! (On a respawn for example). Looks like the command SetFrequency is causing this.
      --self:SwitchRadio()
    else
      self:SetDefaultRadio(self.radio.Freq, self.radio.Modu, false)
    end

    -- Update route.
    if #self.waypoints>1 then  
      self:__Cruise(-0.1)
    else
      self:FullStop()
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
-- @param #number ResumeRoute If true, resume route after detour point was reached. If false, the group will stop at the detour point and wait for futher commands.
function NAVYGROUP:onafterDetour(From, Event, To, Coordinate, Speed, Depth, ResumeRoute)
    
  -- Depth for submarines.
  Depth=Depth or 0

  -- Speed in knots.
  Speed=Speed or self:GetSpeedCruise()
  
  -- ID of current waypoint.
  local uid=self:GetWaypointCurrent().uid
  
  -- Event depths are meters; AddWaypoint accepts feet and converts them for the stored route.
  local wp=self:AddWaypoint(Coordinate, Speed, uid, UTILS.MetersToFeet(Depth), true)
  
  -- Set if we want to resume route after reaching the detour waypoint.
  if ResumeRoute then
    wp.detour=1
  else
    wp.detour=0
  end

end

--- On after "DetourReached" event.
-- @param #NAVYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function NAVYGROUP:onafterDetourReached(From, Event, To)
  self:T(self.lid.."Group reached detour coordinate.")
end

--- On after "TurnIntoWind" event.
-- @param #NAVYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #NAVYGROUP.IntoWind Into wind parameters.
function NAVYGROUP:onafterTurnIntoWind(From, Event, To, IntoWind)

  -- Calculate heading and speed of ship.
  local heading, speed=self:GetHeadingIntoWind(IntoWind.Offset, IntoWind.Speed)
  
  IntoWind.Heading=heading
  IntoWind.Open=true
  
  -- Get coordinate.
  IntoWind.Coordinate=self:GetCoordinate(true)
  
  -- Set current into wind parameters.
  self.intowind=IntoWind

  -- Debug info.
  self:T(self.lid..string.format("Steaming into wind: Heading=%03d Speed=%.1f, Tstart=%d Tstop=%d", IntoWind.Heading, speed, IntoWind.Tstart, IntoWind.Tstop))
  
  local distance=UTILS.NMToMeters(1000)
  
  local coord=self:GetCoordinate()
  local Coord=coord:Translate(distance, IntoWind.Heading)

  -- ID of current waypoint.
  local uid=self:GetWaypointCurrent().uid
  
  local wptiw=self:AddWaypoint(Coord, speed, uid)
  wptiw.intowind=true
  
  IntoWind.waypoint=wptiw
  
  if IntoWind.Uturn and false then
    IntoWind.Coordinate:MarkToAll("Return coord")
  end
  
end

--- On before "TurnIntoWindStop" event.
-- @param #NAVYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function NAVYGROUP:onbeforeTurnIntoWindStop(From, Event, To)

  if self.intowind then
    return true
  else
    return false
  end

end

--- On after "TurnIntoWindStop" event.
-- @param #NAVYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function NAVYGROUP:onafterTurnIntoWindStop(From, Event, To)
  self:TurnIntoWindOver(self.intowind)
end

--- On after "TurnIntoWindOver" event.
-- @param #NAVYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #NAVYGROUP.IntoWind IntoWindData Data table.
function NAVYGROUP:onafterTurnIntoWindOver(From, Event, To, IntoWindData)

  if IntoWindData and self.intowind and IntoWindData.Id==self.intowind.Id then

    -- Debug message.
    self:T2(self.lid.."Turn Into Wind Over!")
  
    -- Window over and not open anymore.
    self.intowind.Over=true
    self.intowind.Open=false
    
    -- Remove outstanding detours for this window before restoring the normal route.
    for i=#self.waypoints,1,-1 do
      local wp=self.waypoints[i]
      if wp.astar and wp.astarTargetUID==self.intowind.waypoint.uid then
        self:RemoveWaypointByID(wp.uid, false)
      end
    end
    self.ispathfinding=false
    self:_ClearPathfindingDrawing()
    -- Remove additional waypoint.
    self:RemoveWaypointByID(self.intowind.waypoint.uid, false)
  
    if self.intowind.Uturn then

      ---
      -- U-turn ==> Go to coordinate where we left the route.
      ---
    
      -- Detour to where we left the route.
      self:T(self.lid.."FF Turn Into Wind Over ==> Uturn!")

      -- ID of current waypoint.
      local uid=self:GetWaypointCurrent().uid
  
      -- Add temp waypoint.
      local wp=self:AddWaypoint(self.intowind.Coordinate, self:GetSpeedCruise(), uid) ; wp.temp=true

    else
    
      ---
      -- Go directly to next waypoint.
      ---
    
      -- Next waypoint index and speed.
      local indx=self:GetWaypointIndexNext()
      local speed=self:GetSpeedToWaypoint(indx)
      
      -- Update route.
      self:T(self.lid..string.format("FF Turn Into Wind Over ==> Next WP Index=%d at %.1f knots via update route!", indx, speed))
      self:__UpdateRoute(-1, indx, nil, speed)
      
    end
    
    -- Set current window to nil.
    self.intowind=nil
    
    -- Remove window from queue.
    self:RemoveTurnIntoWind(IntoWindData)

  end

end

--- On after "FullStop" event.
-- @param #NAVYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function NAVYGROUP:onafterFullStop(From, Event, To)
  self:T(self.lid.."Full stop ==> holding")

  -- A later movement command resolves a fresh native destination.
  self.navigationCommand=nil

  -- Get current position.
  local pos=self:GetCoordinate()
  
  -- Create a new waypoint.
  local wp=pos:WaypointNaval(0)
  
  -- Create new route consisting of only this position ==> Stop!
  if self.pathfindingDiagnostics and self.pathfindingDiagnostics.Enabled then
    self.pathfindingDiagnostics.RouteSubmissions=self.pathfindingDiagnostics.RouteSubmissions+1
  end
  self:Route({wp})

end

--- On after "Cruise" event.
-- @param #NAVYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number Speed Speed in knots until next waypoint is reached. Default is speed set for waypoint.
function NAVYGROUP:onafterCruise(From, Event, To, Speed)

  -- Not waiting anymore.
  self.Twaiting=nil
  self.dTwait=nil

  -- No set depth.
  self.depth=nil

  self:__UpdateRoute(-0.1, nil, nil, Speed)

end

--- On after "Dive" event.
-- @param #NAVYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number Depth Dive depth in meters. Default 50 meters.
-- @param #number Speed Speed in knots until next waypoint is reached.
function NAVYGROUP:onafterDive(From, Event, To, Depth, Speed)

  Depth=Depth or 50

  self:I(self.lid..string.format("Diving to %d meters", Depth))
  
  self.depth=Depth
  
  self:__UpdateRoute(-1, nil, nil, Speed)

end

--- On after "Surface" event.
-- @param #NAVYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number Speed Speed in knots until next waypoint is reached.
function NAVYGROUP:onafterSurface(From, Event, To, Speed)

  self.depth=0

  self:__UpdateRoute(-1, nil, nil, Speed)

end

--- On after "EngageTarget" event.
-- @param #NAVYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.Target#TARGET Target The target to be engaged. Can also be a GROUP or UNIT object.
-- @param #number Speed Attack speed in knots.
-- @param #number Depth The depth in meters. Only for submarins.
function NAVYGROUP:onafterEngageTarget(From, Event, To, Target, Speed, Depth)
  self:T(self.lid.."Engaging Target")

  if Target:IsInstanceOf("TARGET") then
    self.engage.Target=Target
  else
    self.engage.Target=TARGET:New(Target)
  end
 
  -- Target coordinate.
  self.engage.Coordinate=UTILS.DeepCopy(self.engage.Target:GetCoordinate()) 
 
  -- Get a coordinate close to the target.
  local intercoord=self:GetCoordinate():GetIntermediateCoordinate(self.engage.Coordinate, 0.8)

  -- Backup ROE and alarm state.
  self.engage.roe=self:GetROE()
  self.engage.alarmstate=self:GetAlarmstate()
  
  -- Switch ROE and alarm state.
  self:SwitchAlarmstate(ENUMS.AlarmState.Auto)
  self:SwitchROE(ENUMS.ROE.OpenFire)

  -- ID of current waypoint.
  local uid=self:GetWaypointCurrentUID()

  -- Set formation.
  self.engage.Depth=Depth or 0

  -- Set speed.
  self.engage.Speed=Speed  
  
  -- Add waypoint after current.
  self.engage.Waypoint=self:AddWaypoint(intercoord, Speed, uid, Depth and UTILS.MetersToFeet(Depth), true)
    
  -- Set if we want to resume route after reaching the detour waypoint.
  self.engage.Waypoint.detour=1

end

--- Update engage target.
-- @param #NAVYGROUP self
function NAVYGROUP:_UpdateEngageTarget()

  if self.engage.Target and self.engage.Target:IsAlive() then

    -- Get current position vector.
    local vec3=self.engage.Target:GetVec3()
    
    if vec3 then
  
      -- Distance to last known position of target.
      local dist=UTILS.VecDist3D(vec3, self.engage.Coordinate:GetVec3())
      
      -- Check if target moved more than 100 meters.
      if dist>100 then
      
        -- Update new position.
        self.engage.Coordinate:UpdateFromVec3(vec3)
  
        -- ID of current waypoint.
        local uid=self:GetWaypointCurrentUID()
      
        -- Remove current waypoint
        self:RemoveWaypointByID(self.engage.Waypoint.uid, false)
        
        local intercoord=self:GetCoordinate():GetIntermediateCoordinate(self.engage.Coordinate, 0.8)
    
        -- Event depths are meters; AddWaypoint takes feet and converts them for DCS.
        self.engage.Waypoint=self:AddWaypoint(intercoord, self.engage.Speed, uid, UTILS.MetersToFeet(self.engage.Depth), true)
      
        -- Set if we want to resume route after reaching the detour waypoint.
        self.engage.Waypoint.detour=1
      
      end
      
    else

      -- Could not get position of target (not alive any more?) ==> Disengage.
      self:Disengage()
    
    end
    
  else
  
    -- Target not alive any more ==> Disengage.
    self:Disengage()
    
  end

end

--- On after "Disengage" event.
-- @param #NAVYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function NAVYGROUP:onafterDisengage(From, Event, To)
  self:T(self.lid.."Disengage Target")

  -- Restore previous ROE and alarm state.
  self:SwitchROE(self.engage.roe)
  self:SwitchAlarmstate(self.engage.alarmstate)

  -- Get current task
  local task=self:GetTaskCurrent()

  -- Get if current task is ground attack.
  if task and (task.dcstask.id==AUFTRAG.SpecialTask.GROUNDATTACK or task.dcstask.id==AUFTRAG.SpecialTask.NAVALENGAGEMENT) then
    self:T(self.lid.."Disengage with current task GROUNDATTACK/NAVALENGAGEMENT ==> Task Done!")
    self:TaskDone(task)
  end    
  
  -- Remove current waypoint
  if self.engage.Waypoint then
    self:RemoveWaypointByID(self.engage.Waypoint.uid, false)
  end

  -- Check group is done
  self:_CheckGroupDone(1)
end

--- On after "OutOfAmmo" event.
-- @param #NAVYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function NAVYGROUP:onafterOutOfAmmo(From, Event, To)
  self:T(self.lid..string.format("Group is out of ammo at t=%.3f", timer.getTime()))
  
  -- Check if we want to retreat once out of ammo.
  if self.retreatOnOutOfAmmo then
    self:__Retreat(-1)
    return
  end
  
  -- Third, check if we want to RTZ once out of ammo.
  if self.rtzOnOutOfAmmo then
    self:__RTZ(-1)
  end

  -- Get current task.
  local task=self:GetTaskCurrent()
  
  if task then
    if task.dcstask.id=="FireAtPoint" or task.dcstask.id==AUFTRAG.SpecialTask.BARRAGE then
      self:T(self.lid..string.format("Cancelling current %s task because out of ammo!", task.dcstask.id))
      self:TaskCancel(task)
    end
  end
    
end

--- On after "RTZ" event.
-- @param #NAVYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Zone#ZONE Zone The zone to return to.
-- @param #number Formation Unused for naval groups; retained as part of the shared RTZ event.
function NAVYGROUP:onafterRTZ(From, Event, To, Zone, Formation)
  
  -- Zone.
  local zone=Zone or self.homezone
  
  -- Cancel all missions in the queue.
  self:CancelAllMissions()
  
  if zone then
  
    if self:IsInZone(zone) then
      self:Returned()
    else
  
      -- Debug info.
      self:T(self.lid..string.format("RTZ to Zone %s", zone:GetName()))  
      
      local Coordinate=zone:GetRandomCoordinate()

      -- ID of current waypoint.
      local uid=self:GetWaypointCurrentUID()
      
      -- Add waypoint after current.
      -- The shared RTZ formation argument is not a submarine depth.
      local wp=self:AddWaypoint(Coordinate, nil, uid, nil, true)
      
      -- Set if we want to resume route after reaching the detour waypoint.
      wp.detour=0
      
    end
        
  else
    self:T(self.lid.."ERROR: No RTZ zone given!")
  end

end


--- On after "Returned" event.
-- @param #NAVYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function NAVYGROUP:onafterReturned(From, Event, To)

  -- Debug info.
  self:T(self.lid..string.format("Group returned"))
  
  if self.legion then
    -- Debug info.
    self:T(self.lid..string.format("Adding group back to warehouse stock"))
    
    -- Add asset back in 10 seconds.
    self.legion:__AddAsset(10, self.group, 1)
  end

end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Routing
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Add a waypoint to the route.
-- VECTOR positions are read directly; only the coordinate stored on the resulting waypoint is created.
-- @param #NAVYGROUP self
-- @param Core.Point#COORDINATE Coordinate Waypoint position. Also accepts Core.Vector#VECTOR, POSITIONABLE or ZONE_BASE objects.
-- Without Depth, uses the position's altitude in meters. VECTOR and COORDINATE inputs are not modified.
-- @param #number Speed (Optional) Speed in knots. Default is default cruise speed or 70% of max speed.
-- @param #number AfterWaypointWithID (Optional) Insert waypoint after waypoint given ID. Default is to insert as last waypoint.
-- @param #number Depth (Optional) Depth at waypoint in feet. Only for submarines. Converted to meters before storing the waypoint and its coordinate.
-- @param #boolean Updateroute (Optional) If true or nil, call UpdateRoute. If false, no call.
-- @return Ops.OpsGroup#OPSGROUP.Waypoint Waypoint table.
function NAVYGROUP:AddWaypoint(Coordinate, Speed, AfterWaypointWithID, Depth, Updateroute)

  -- Resolve existing object inputs without converting VECTOR positions.
  local position=self:_WaypointPosition(Coordinate)
  
  -- Set waypoint index.
  local wpnumber=self:GetWaypointIndexAfterID(AfterWaypointWithID)

  -- Speed in knots.
  Speed=Speed or self:GetSpeedCruise()

  -- Create a Naval waypoint.
  local depth=Depth and UTILS.FeetToMeters(Depth)
  local wp=UTILS.VecWaypointNaval(position, UTILS.KnotsToKmph(Speed), depth)

  -- Create waypoint data table.
  local waypoint=self:_CreateWaypoint(wp)

  -- Add waypoint to table.
  self:_AddWaypoint(waypoint, wpnumber)
  
  -- Debug info.
  self:T(self.lid..string.format("Adding NAVAL waypoint index=%d uid=%d, speed=%.1f knots. Last waypoint passed was #%d. Total waypoints #%d", wpnumber, waypoint.uid, Speed, self.currentwp, #self.waypoints))

  -- Update route.
  if Updateroute==nil or Updateroute==true then
    self:__UpdateRoute(-0.01)
  end
  
  return waypoint
end

--- Initialize group parameters. Also initializes waypoints if self.waypoints is nil.
-- @param #NAVYGROUP self
-- @param #table Template (Optional) Template used to init the group. Default is `self.template`.
-- @param #number Delay (Optional) Delay in seconds before group is initialized. Default `nil`, *i.e.* instantaneous. 
-- @return #NAVYGROUP self
function NAVYGROUP:_InitGroup(Template, Delay)

  if Delay and Delay>0 then
    -- Delayed call
    self:ScheduleOnce(Delay, NAVYGROUP._InitGroup, self, Template, 0)
  else
  
    -- First check if group was already initialized.
    if self.groupinitialized then
      self:T(self.lid.."WARNING: Group was already initialized! Will NOT do it again!")
      return
    end
  
    -- Get template of group.
    local template=Template or self:_GetTemplate()
  
    -- Ships are always AI.
    self.isAI=true
    
    -- Is (template) group late activated.
    self.isLateActivated=template.lateActivation
    
    -- Naval groups cannot be uncontrolled.
    self.isUncontrolled=false
    
    -- Max speed in km/h.
    self.speedMax=self.group:GetSpeedMax()
    
    -- Is group mobile?
    if self.speedMax and self.speedMax>3.6 then
      self.isMobile=true
    else
      self.isMobile=false
      self.speedMax = 0
    end  
    
    -- Cruise speed: 70% of max speed.
    self.speedCruise=self.speedMax*0.7
    
    -- Group ammo.
    self.ammo=self:GetAmmoTot()
    
    -- Radio parameters from template. Default is set on spawn if not modified by the user.
    self.radio.On=true  -- Radio is always on for ships.
    self.radio.Freq=tonumber(template.units[1].frequency)/1000000
    self.radio.Modu=tonumber(template.units[1].modulation)
    
    -- Set default formation. No really applicable for ships.
    self.optionDefault.Formation="Off Road"
    self.option.Formation=self.optionDefault.Formation
  
    -- Default TACAN off (we check if something is set already to keep those values in case of respawn)
    if not self.tacanDefault then
      self:SetDefaultTACAN(nil, nil, nil, nil, true)
    end
    if not self.tacan then
      self.tacan=UTILS.DeepCopy(self.tacanDefault)
    end
    
    -- Default ICLS off.
    if not self.iclsDefault then
      self:SetDefaultICLS(nil, nil, nil, true)
    end
    if not self.icls then
      self.icls=UTILS.DeepCopy(self.iclsDefault)
    end
    
    -- Get all units of the group.
    local units=self.group:GetUnits()
  
    -- DCS group.
    local dcsgroup=Group.getByName(self.groupname)
    local size0=dcsgroup:getInitialSize()
    
    -- Quick check.
    if #units~=size0 then
      self:E(self.lid..string.format("ERROR: Got #units=%d but group consists of %d units!", #units, size0))
    end
    
    -- Add elemets.
    for _,unit in pairs(units) do
      self:_AddElementByName(unit:GetName())
    end
    
    -- Init done.
    self.groupinitialized=true
  end
  
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Option Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Caller-stepped fixed-pose route preparation. This does not enable LOCAL or command a vessel.
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Frozen naval preparation input. Positions are copied finite DCS Vec3 values; x/z are horizontal meters.
-- ASTAR Path/node fields are ignored. No live group is read; altitude does not supply depth evidence.
-- @type NAVYGROUP.RoutePreparationInput
-- @field DCS#Vec3 Start Exact planning start, equal to Pose.Position.
-- @field DCS#Vec3 Goal Original exact target, retained even for partial candidates.
-- @field #NAVYGROUP.PreparationPose Pose Copied position, heading, speeds and optional hull assumptions.
-- @field #table Candidates Dense ordered ASTAR candidate array: Positions, Cost, Score, ReachesGoal; optional diagnostic scalars.

--- Explicit pose and hull data; no ship dimensions, cruise speed, radius or braking distance is inferred.
-- @type NAVYGROUP.PreparationPose
-- @field DCS#Vec3 Position Frozen reference position in meters.
-- @field #number HeadingDeg Optional finite clockwise heading from +x towards +z; normalized to [0,360).
-- @field #number ActualSpeedMps Optional finite non-negative observed/configured speed in meters per second; zero is preserved.
-- @field #number RequestedSpeedMps Optional finite non-negative requested speed in meters per second.
-- @field #table Hull Optional non-negative Forward, Aft, Left, Right extents in meters from the same reference point.

--- Injected stable preparation rules. Changing external configuration requires a new context or cancellation.
-- @type NAVYGROUP.RoutePreparationEvaluators
-- @field Core.Pathline#PATHLINE.ConnectionEvaluator Connection Required descriptor with CostUnits, usually CreateRouteConnectionEvaluator().
-- @field #function Maneuver Optional atomic callback(Event, Pose, Model); input copies may be mutated/retained by the callback.
-- @field #table Model Required with Maneuver: Id, Revision, Calibration (assumed/measured), flat Parameters and optional Evidence, all copied.

--- One entry, distinct corner, or terminal/stopping maneuver at the frozen pose/commanded polyline.
-- Courses and signed angles are degrees, horizontal lengths/distances meters. Positive angle is right, wrapped to (-180,180].
-- Point-only geometry has no invented travel direction. Incident indices refer to the prepared variant; PointMap links it to raw.
-- @type NAVYGROUP.PreparationManeuverEvent
-- @field #string Kind entry, turn or terminal.
-- @field #number CandidateIndex Original candidate order.
-- @field #number VariantIndex 1 for raw, 2 for simplified.
-- @field #number PointIndex Point in this variant, including the terminal endpoint.
-- @field #table Position Independent Vec3 event anchor.
-- @field #number IncomingHeading Incoming course, or pose heading at entry when supplied.
-- @field #number OutgoingHeading Outgoing course, absent at terminal/point-only entry.
-- @field #number SignedAngle Wrapped change between courses where both exist.
-- @field #number IncomingSegment Incoming positive segment index, where present.
-- @field #number OutgoingSegment Outgoing positive segment index, where present.
-- @field #table IncomingStart Copied incoming segment start, where present.
-- @field #table OutgoingGoal Copied outgoing segment end, where present.
-- @field #number IncomingLength Incoming horizontal segment length, where present.
-- @field #number OutgoingLength Outgoing horizontal segment length, where present.
-- @field #number DistanceFromStart Horizontal route distance at the event.
-- @field #boolean ReachesGoal Whether this candidate reaches the exact original target.
-- @field #string ContextId Optional job context; alternatively a finite integer.

--- Maneuver result. The model must cover the complete event's swept hull under its stated assumptions.
-- NAVYGROUP checks supplied sampled strips, not whether those assumptions reproduce DCS motion.
-- @type NAVYGROUP.PreparationManeuverResult
-- @field #string Status modeled, rejected, unavailable or unverified.
-- @field #string Reason Required short failure reason; absent for modeled.
-- @field #table Strips Required non-empty dense array for modeled: {Positions=dense Vec3 array, CorridorWidth=non-negative meters}.
-- Each strip uses at least the configured route width and the same hard minimum depth; missing data cannot pass.

--- Immutable limits/settings. Structural caps are positive integers; work/call/attempt caps preserve zero.
-- Atomic geometry construction, input/report copies, callbacks and native calls are not preemptible.
-- @type NAVYGROUP.RoutePreparationOptions
-- @field #string ContextId Optional non-empty string or finite integer; every step must match it.
-- @field Core.Pathline#PATHLINE.DepthEvaluatorOptions Depth Required explicit dense-depth settings, copied/resolved through PATHLINE.
-- @field #boolean Simplify Optional, default true. A shortcut must be clear and no more expensive than the checked fallback.
-- @field #number MaxCandidates Default 8; never truncates the candidate set.
-- @field #number MaxPoints Default 4096, per route/strip geometry.
-- @field #number MaxShortcutAttempts Default 32 per candidate; reaching this optional optimization cap preserves the checked route.
-- @field #number MaxFootprintPaths Default 8 per event.
-- @field #number MaxFootprintPoints Default 4096 total supplied strip points per event.
-- @field #number MaxManeuverEvents Default 4096 per variant.
-- @field #number MaxWorkUnits Default 400000 across preparation and subordinate PATHLINE work.
-- @field #number MaxEvaluatorCalls Default 4096 whole-connection callbacks across all stages; internal callback work is opaque.
-- @field #number MaxManeuverCalls Default 8192 atomic model callbacks across all variants.
-- @field #number MaxPointChecks Default 50000 dense point checks across route/footprint stages.
-- @field #number MaxProfileQueries Default 4096 dense native profile calls across all stages.
-- @field #number MaxCPUSeconds Optional total active inclusive os.clock seconds; never simulation time or a hard deadline.

--- Per-step cooperative work limits; non-negative counts preserve zero and may change between steps.
-- @type NAVYGROUP.RoutePreparationBudget
-- @field #number MaxWorkUnits Default 64, includes subordinate work and bounded preparation advances.
-- @field #number MaxEvaluatorCalls Default 1; a pending commit needs no new callback.
-- @field #number MaxManeuverCalls Default 1.
-- @field #number MaxPointChecks Default 8.
-- @field #number MaxProfileQueries Default 1; processing a returned profile needs no new query.
-- @field #number MaxCPUSeconds Optional active inclusive slice seconds; atomic work may overrun.

--- Opaque read-only job; no timer, scheduler, controller or mutable global job registry.
-- @type NAVYGROUP.RoutePreparationJob

--- Detached bounded preparation report. Every candidate retains its raw data and individual variant results.
-- Geometry, connection, dense and maneuver reports stay distinct. No sampled result certifies vessel execution.
-- @type NAVYGROUP.RoutePreparationReport
-- @field #string Status running, ready_under_model, rejected, unavailable, limited, cancelled, error or unverified.
-- @field #string Reason Failure/limitation reason; absent when ready_under_model.
-- @field #string ContextId Original optional context; alternatively an integer.
-- @field #table Pose Frozen copied pose and hull.
-- @field #table Model Copied explicit model identity, calibration and parameters, if supplied.
-- @field #string CostUnits Configured connection cost units; not necessarily physical meters.
-- @field #table Limits Effective copied job limits and simplification settings, including explicit zero values.
-- @field #table DepthCoverage Effective baseline sampling configuration/layout; maneuver strips report their own width.
-- @field #table Candidates Ordered raw/variant results, costs, mappings, maneuver events/strips and first failures.
-- @field #table Proposal Only when ready_under_model: selected copied geometry, costs, pose/model and candidate/variant check references.
-- @field #boolean ExecutionValidated Always false; no simulator/controller validation occurs here.
-- @field #table Counters Shared WorkUnits, EvaluatorCalls, ManeuverCalls, PointChecks, ProfileQueries, and optional inclusive CPUSeconds.
-- @field #table LastSlice Same slice counters, optional YieldReason and measured CPUOverrunSeconds.
-- @field #table Cursor Diagnostic candidate/variant/phase, absent when terminal; never a continuation token.

local preparationStateKey={}
local preparationHandles=setmetatable({}, {__mode="k"})
local preparationCountNames={"WorkUnits", "EvaluatorCalls", "ManeuverCalls", "PointChecks", "ProfileQueries"}
local preparationDefaultTotals={MaxWorkUnits=400000, MaxEvaluatorCalls=4096, MaxManeuverCalls=8192,
  MaxPointChecks=50000, MaxProfileQueries=4096}
local preparationDefaultSlice={MaxWorkUnits=64, MaxEvaluatorCalls=1, MaxManeuverCalls=1,
  MaxPointChecks=8, MaxProfileQueries=1}
local preparationStructuralDefaults={MaxCandidates=8, MaxPoints=4096, MaxFootprintPaths=8,
  MaxFootprintPoints=4096, MaxManeuverEvents=4096}

local function preparationFinite(Value)
  return type(Value)=="number" and Value==Value and Value>-math.huge and Value<math.huge
end

local function preparationFields(Value, Names, Name)
  assert(type(Value)=="table", "NAVYGROUP: "..Name.." must be a table")
  local allowed={}
  for field in Names:gmatch("%S+") do
    allowed[field]=true
  end
  for field in next,Value do
    assert(allowed[field], "NAVYGROUP: unknown "..Name.." field: "..tostring(field))
  end
end

local function preparationText(Value, Name)
  assert(type(Value)=="string" and #Value>0 and #Value<=128,
    "NAVYGROUP: "..Name.." must be a non-empty string of at most 128 bytes")
  return Value
end

local function preparationCount(Value, Name, Positive)
  assert(preparationFinite(Value) and Value%1==0 and Value>=(Positive and 1 or 0) and Value<=9007199254740991,
    "NAVYGROUP: "..Name.." must be a "..(Positive and "positive" or "non-negative").." exact integer")
  return Value
end

local function preparationArray(Value, Name)
  assert(type(Value)=="table", "NAVYGROUP: "..Name.." must be a dense array")
  local count,maximum=0,0
  for key in next,Value do
    preparationCount(key, Name.." index", true)
    count=count+1
    maximum=math.max(maximum,key)
  end
  assert(count==maximum, "NAVYGROUP: "..Name.." must be a dense array")
  return count
end

local function preparationPosition(Value, Name)
  assert(type(Value)=="table", "NAVYGROUP: "..Name.." must be a Vec3 table")
  local point={x=rawget(Value,"x"), y=rawget(Value,"y"), z=rawget(Value,"z")}
  assert(preparationFinite(point.x) and preparationFinite(point.y) and preparationFinite(point.z),
    "NAVYGROUP: "..Name.." must contain finite x/y/z")
  return point
end

local function preparationCopy(Value)
  if type(Value)~="table" then
    return Value
  end
  -- Only owned fixed-schema records reach this copier, never arbitrary callback graphs or ASTAR nodes.
  local result={}
  for key,value in next,Value do
    result[key]=preparationCopy(value)
  end
  return result
end

local function preparationContext(Value)
  assert(Value==nil or (type(Value)=="string" and #Value>0 and #Value<=128)
    or (preparationFinite(Value) and Value%1==0),
    "NAVYGROUP: ContextId must be a short non-empty string or finite integer")
end

local function preparationSettings(Options, Total)
  if Options==nil then
    Options={}
  end
  local names="MaxWorkUnits MaxEvaluatorCalls MaxManeuverCalls MaxPointChecks MaxProfileQueries MaxCPUSeconds"
  if Total then
    names=names.." ContextId Depth Simplify MaxCandidates MaxPoints MaxShortcutAttempts MaxFootprintPaths MaxFootprintPoints MaxManeuverEvents"
  end
  preparationFields(Options, names, Total and "Options" or "Budget")
  local settings={}
  local defaults=Total and preparationDefaultTotals or preparationDefaultSlice
  for _,name in ipairs(preparationCountNames) do
    local field="Max"..name
    local value=rawget(Options,field)
    if value==nil then
      value=defaults[field]
    end
    settings[field]=preparationCount(value,field)
  end
  settings.MaxCPUSeconds=rawget(Options,"MaxCPUSeconds")
  assert(settings.MaxCPUSeconds==nil or (preparationFinite(settings.MaxCPUSeconds) and settings.MaxCPUSeconds>=0),
    "NAVYGROUP: MaxCPUSeconds must be finite and non-negative")
  if Total then
    settings.ContextId=rawget(Options,"ContextId")
    preparationContext(settings.ContextId)
    for field,default in next,preparationStructuralDefaults do
      local value=rawget(Options,field)
      if value==nil then
        value=default
      end
      settings[field]=preparationCount(value,field,true)
    end
    settings.MaxShortcutAttempts=rawget(Options,"MaxShortcutAttempts")
    if settings.MaxShortcutAttempts==nil then
      settings.MaxShortcutAttempts=32
    end
    preparationCount(settings.MaxShortcutAttempts,"MaxShortcutAttempts")
    settings.Simplify=rawget(Options,"Simplify")
    if settings.Simplify==nil then
      settings.Simplify=true
    end
    assert(type(settings.Simplify)=="boolean", "NAVYGROUP: Simplify must be a boolean")
  end
  return settings
end

local function preparationPose(Pose)
  preparationFields(Pose,"Position HeadingDeg ActualSpeedMps RequestedSpeedMps Hull","Pose")
  local result={Position=preparationPosition(rawget(Pose,"Position"),"Pose.Position")}
  for _,name in ipairs({"HeadingDeg", "ActualSpeedMps", "RequestedSpeedMps"}) do
    local value=rawget(Pose,name)
    if value~=nil then
      assert(preparationFinite(value) and (name=="HeadingDeg" or value>=0),
        "NAVYGROUP: invalid Pose."..name)
      result[name]=name=="HeadingDeg" and value%360 or value
    end
  end
  local hull=rawget(Pose,"Hull")
  if hull~=nil then
    preparationFields(hull,"Forward Aft Left Right","Pose.Hull")
    result.Hull={}
    for _,name in ipairs({"Forward", "Aft", "Left", "Right"}) do
      local value=rawget(hull,name)
      assert(preparationFinite(value) and value>=0, "NAVYGROUP: invalid Pose.Hull."..name)
      result.Hull[name]=value
    end
  end
  return result
end

local function preparationModel(Model)
  preparationFields(Model,"Id Revision Calibration Parameters Evidence","Model")
  local result={Id=preparationText(rawget(Model,"Id"),"Model.Id"),
    Revision=preparationText(rawget(Model,"Revision"),"Model.Revision"), Calibration=rawget(Model,"Calibration"), Parameters={}}
  assert(result.Calibration=="assumed" or result.Calibration=="measured", "NAVYGROUP: invalid Model.Calibration")
  local parameters=rawget(Model,"Parameters")
  assert(type(parameters)=="table", "NAVYGROUP: Model.Parameters must be a flat table")
  local count=0
  for key,value in next,parameters do
    preparationText(key,"Model parameter name")
    assert(type(value)=="boolean" or preparationFinite(value) or (type(value)=="string" and #value<=128),
      "NAVYGROUP: invalid Model parameter: "..key)
    count=count+1
    assert(count<=32, "NAVYGROUP: Model.Parameters exceeds 32 fields")
    result.Parameters[key]=value
  end
  if rawget(Model,"Evidence")~=nil then
    result.Evidence=preparationText(rawget(Model,"Evidence"),"Model.Evidence")
  end
  return result
end

local function preparationPoints(Positions, Name, Maximum)
  local count=preparationArray(Positions,Name)
  if count>Maximum then
    return nil,"point_limit",{Required=count,Limit=Maximum}
  end
  local points={}
  for index=1,count do
    points[index]=preparationPosition(Positions[index],Name.."["..index.."]")
  end
  return points
end

local function preparationCandidate(Candidate, Index, Maximum)
  assert(type(Candidate)=="table", "NAVYGROUP: invalid candidate "..Index)
  local result={}
  for _,name in ipairs({"Cost", "Score"}) do
    local value=rawget(Candidate,name)
    assert(preparationFinite(value) and value>=0, "NAVYGROUP: invalid candidate "..name)
    result[name]=value
  end
  assert(result.Score>=result.Cost, "NAVYGROUP: candidate Score must include Cost")
  result.ReachesGoal=rawget(Candidate,"ReachesGoal")
  assert(type(result.ReachesGoal)=="boolean", "NAVYGROUP: candidate ReachesGoal must be a boolean")
  for _,name in ipairs({"BaseScore", "LearnedPenalty", "Length", "RemainingDistance", "Sector"}) do
    local value=rawget(Candidate,name)
    if value~=nil then
      assert(preparationFinite(value) and value>=0, "NAVYGROUP: invalid candidate "..name)
      result[name]=value
    end
  end
  for _,name in ipairs({"CandidateId", "GeometryId"}) do
    local value=rawget(Candidate,name)
    if value~=nil then
      result[name]=preparationText(value,"candidate "..name)
    end
  end
  local reason,detail
  result.Positions,reason,detail=preparationPoints(rawget(Candidate,"Positions"),"Candidate.Positions",Maximum)
  return result,reason,detail
end

local function preparationState(Job)
  assert(type(Job)=="table" and preparationHandles[Job], "NAVYGROUP: invalid route preparation job")
  return Job[preparationStateKey]
end

local function preparationHandle(State)
  local handle=setmetatable({}, {
    __index=function(_,Key)
      if Key==preparationStateKey then
        return State
      end
    end,
    __newindex=function()
      error("NAVYGROUP route preparation job is read-only",2)
    end,
    __metatable="NAVYGROUP.RoutePreparationJob",
  })
  preparationHandles[handle]=true
  return handle
end

local function preparationCounters()
  return {WorkUnits=0, EvaluatorCalls=0, ManeuverCalls=0, PointChecks=0, ProfileQueries=0}
end

local function preparationFinish(State, Status, Reason)
  local report=State.Report
  if report.Status~="running" then
    return
  end
  report.Status,report.Reason,report.Cursor=Status,Reason,nil
  if report.LastSlice then
    report.LastSlice.YieldReason=nil
  end
  if State.Active then
    local active=State.Active
    active.Record.Native=PATHLINE.CancelValidation(active.Job,Reason or "preparation_ended")
    active.Record.Status,active.Record.Reason=active.Record.Native.Status,active.Record.Native.Reason
  end
  local candidate=report.Candidates[State.CandidateIndex]
  if candidate and candidate.Status=="running" then
    candidate.Status,candidate.Reason=Status,Reason
    for _,variant in ipairs(candidate.Variants) do
      if variant.Status=="running" then
        variant.Status,variant.Reason=Status,Reason
        if variant.Maneuver.Status=="running" then
          variant.Maneuver.Status,variant.Maneuver.Reason=Status,Reason
        end
      end
    end
  end
  for _,pending in ipairs(report.Candidates) do
    if pending.Status=="not_run" then
      pending.Reason=Reason or "preparation_ended"
    end
  end
  -- A terminal handle keeps bounded evidence, not callback captures or active sampling buffers.
  State.Active,State.Connection,State.Maneuver,State.DepthEvaluator=nil,nil,nil,nil
  State.Geometries,State.CheckedGeometry,State.TrialGeometry,State.Trial=nil,nil,nil,nil
  if State.Event and State.Event.Status=="running" then
    State.Event.Status,State.Event.Reason=Status,Reason
  end
  State.Event,State.Footprints,State.Variant=nil,nil,nil
end

local function preparationCountWork(State, Name, Count)
  State.Report.Counters[Name]=State.Report.Counters[Name]+Count
  State.Report.LastSlice[Name]=State.Report.LastSlice[Name]+Count
end

local function preparationMeasure(State, Timing)
  if not Timing.Read then
    return
  end
  local value=Timing.Read()
  if not preparationFinite(value) or (Timing.Last and value<Timing.Last) then
    Timing.Read=nil
    State.CPUComplete=false
    State.Report.Counters.CPUSeconds=nil
    State.Report.LastSlice.CPUSeconds=nil
    return
  end
  Timing.First=Timing.First or value
  Timing.Last=value
  local elapsed=value-Timing.First
  if not preparationFinite(elapsed) or not preparationFinite(Timing.Base+elapsed) then
    Timing.Read=nil
    State.CPUComplete=false
    State.Report.Counters.CPUSeconds=nil
    State.Report.LastSlice.CPUSeconds=nil
    return
  end
  State.Report.LastSlice.CPUSeconds=elapsed
  if State.CPUComplete then
    State.Report.Counters.CPUSeconds=Timing.Base+elapsed
  end
end

local function preparationCPUAdmission(State, Budget)
  local report=State.Report
  local totalCPU,sliceCPU=report.Counters.CPUSeconds,report.LastSlice.CPUSeconds
  if (State.Limits.MaxCPUSeconds~=nil and totalCPU==nil) or (Budget.MaxCPUSeconds~=nil and sliceCPU==nil) then
    preparationFinish(State,"limited","cpu_clock_unavailable")
    return false
  end
  if State.Limits.MaxCPUSeconds~=nil and totalCPU>=State.Limits.MaxCPUSeconds then
    preparationFinish(State,"limited","cpu_limit")
    return false
  end
  if Budget.MaxCPUSeconds~=nil and sliceCPU>=Budget.MaxCPUSeconds then
    report.LastSlice.YieldReason="slice_cpu_limit"
    return false
  end
  return true
end

local function preparationAdmission(State, Budget, Specific)
  local report=State.Report
  if not preparationCPUAdmission(State,Budget) then
    return false
  end
  local names={"WorkUnits"}
  if Specific then
    names[2]=Specific
  end
  for _,name in ipairs(names) do
    if report.Counters[name]>=State.Limits["Max"..name] then
      preparationFinish(State,"limited",name=="WorkUnits" and "work_limit" or "maneuver_limit")
      return false
    end
  end
  for _,name in ipairs(names) do
    if report.LastSlice[name]>=Budget["Max"..name] then
      report.LastSlice.YieldReason=name=="WorkUnits" and "slice_work_limit" or "slice_maneuver_limit"
      return false
    end
  end
  preparationCountWork(State,"WorkUnits",1)
  if Specific then
    preparationCountWork(State,Specific,1)
  end
  return true
end

local function preparationStartValidation(State, Geometry, Evaluator, Record, After)
  local options={ContextId=State.Report.ContextId,
    MaxWorkUnits=State.Limits.MaxWorkUnits-State.Report.Counters.WorkUnits}
  local kind=Record.Kind
  if kind=="connection" then
    options.MaxEvaluatorCalls=State.Limits.MaxEvaluatorCalls-State.Report.Counters.EvaluatorCalls
  else
    options.MaxPointChecks=State.Limits.MaxPointChecks-State.Report.Counters.PointChecks
    options.MaxProfileQueries=State.Limits.MaxProfileQueries-State.Report.Counters.ProfileQueries
  end
  local job,report=PATHLINE.StartValidation(Geometry,Evaluator,options)
  Record.Status,Record.Native="running",report
  State.Active={Job=job, Kind=kind, Record=Record, After=After, Counters=report.Counters}
end

local function preparationValidationStep(State, Budget)
  local active=State.Active
  local counters,slice=State.Report.Counters,State.Report.LastSlice
  local admitted={MaxWorkUnits=math.min(Budget.MaxWorkUnits-slice.WorkUnits,State.Limits.MaxWorkUnits-counters.WorkUnits)}
  if active.Kind=="connection" then
    admitted.MaxEvaluatorCalls=math.min(Budget.MaxEvaluatorCalls-slice.EvaluatorCalls,
      State.Limits.MaxEvaluatorCalls-counters.EvaluatorCalls)
  else
    admitted.MaxPointChecks=math.min(Budget.MaxPointChecks-slice.PointChecks,
      State.Limits.MaxPointChecks-counters.PointChecks)
    admitted.MaxProfileQueries=math.min(Budget.MaxProfileQueries-slice.ProfileQueries,
      State.Limits.MaxProfileQueries-counters.ProfileQueries)
  end
  if Budget.MaxCPUSeconds~=nil then
    admitted.MaxCPUSeconds=math.max(0,Budget.MaxCPUSeconds-slice.CPUSeconds)
  end
  if State.Limits.MaxCPUSeconds~=nil then
    local remaining=math.max(0,State.Limits.MaxCPUSeconds-counters.CPUSeconds)
    admitted.MaxCPUSeconds=admitted.MaxCPUSeconds and math.min(admitted.MaxCPUSeconds,remaining) or remaining
  end
  -- Account native work even when a callback cancels this job or raises an original exception.
  local ok,result=pcall(PATHLINE.StepValidation,active.Job,admitted,State.Report.ContextId)
  local report=ok and result or PATHLINE.GetValidationReport(active.Job)
  for _,name in ipairs(preparationCountNames) do
    local count=report.Counters[name] or 0
    local before=active.Counters[name] or 0
    preparationCountWork(State,name,count-before)
  end
  active.Counters=report.Counters
  active.Record.Native=report
  active.Record.Status,active.Record.Reason=report.Status,report.Reason
  if not ok then
    error(result,0)
  end
  if State.Report.Status~="running" then
    return false
  end
  if report.Status=="running" then
    State.Report.LastSlice.YieldReason=report.LastSlice and report.LastSlice.YieldReason
    return false
  end
  State.Active=nil
  -- These are the shared admission caps, not evidence that a route is blocked.
  if report.Status=="limited" and (report.Reason=="work_limit" or report.Reason=="evaluator_limit"
    or report.Reason=="point_limit" or report.Reason=="profile_query_limit") then
    preparationFinish(State,"limited",report.Reason)
    return false
  end
  active.After(report)
  return true
end

local function preparationSamePosition(First, Last)
  return First.x==Last.x and First.y==Last.y and First.z==Last.z
end

local function preparationVariant(Positions, PointMap, Kind)
  return {Kind=Kind, Positions=preparationCopy(Positions), PointMap=preparationCopy(PointMap),
    Status="running", Selected=false, ExecutionValidated=false,
    Geometry={Status="not_run"}, Connection={Kind="connection",Status="not_run"},
    Depth={Kind="depth",Status="not_run"}, Maneuver={Status="not_run",Events={},CompletedEvents=0,CheckedStrips=0}}
end

local function preparationScore(State, Variant, Cost)
  local raw=State.Report.Candidates[State.CandidateIndex].Raw
  local adjustment=Cost-raw.Cost
  -- Preserve small prepared costs when the original cost and score are much larger.
  local residual=raw.Score-raw.Cost
  local score=Cost+residual
  if not preparationFinite(adjustment) or not preparationFinite(residual) or not preparationFinite(score) then
    Variant.Status,Variant.Reason="limited","numeric_range"
    return false
  end
  Variant.Cost,Variant.Score=Cost,score
  Variant.ScoreTerms={RawScore=raw.Score,RawCost=raw.Cost,PreparedCost=Cost,Adjustment=adjustment,Residual=residual}
  return true
end

local function preparationReject(Variant, Report)
  local status=Report.Status=="blocked" and "rejected" or Report.Status
  Variant.Status,Variant.Reason=status,Report.Reason
end

local function preparationBefore(First, Second)
  if not Second then
    return true
  end
  if First.ReachesGoal~=Second.ReachesGoal then
    return First.ReachesGoal
  end
  if First.Score~=Second.Score then
    return First.Score<Second.Score
  end
  if First.CandidateIndex~=Second.CandidateIndex then
    return First.CandidateIndex<Second.CandidateIndex
  end
  return First.VariantIndex<Second.VariantIndex
end

local function preparationFailureStatus(Results)
  for _,status in ipairs({"limited", "unavailable", "unverified", "rejected"}) do
    for _,result in ipairs(Results) do
      if result.Status==status then
        return status,result.Reason
      end
    end
  end
  return "rejected","no_candidates"
end

local function preparationCompleteCandidate(State)
  local candidate=State.Report.Candidates[State.CandidateIndex]
  local best
  for index,variant in ipairs(candidate.Variants) do
    if variant.Status=="ready_under_model" then
      local choice={CandidateIndex=State.CandidateIndex,VariantIndex=index,
        Score=variant.Score,ReachesGoal=candidate.Raw.ReachesGoal}
      if preparationBefore(choice,best) then
        best=choice
      end
    end
  end
  if best then
    candidate.Status,candidate.ReadyVariant="ready_under_model",best.VariantIndex
    if preparationBefore(best,State.Best) then
      State.Best=best
    end
  else
    candidate.Status,candidate.Reason=preparationFailureStatus(candidate.Variants)
  end
  State.CandidateIndex=State.CandidateIndex+1
  State.Geometries,State.CheckedGeometry,State.TrialGeometry,State.Trial=nil,nil,nil,nil
  State.Event,State.Footprints,State.Variant=nil,nil,nil
  State.VariantIndex,State.ScanIndex,State.PreviousSegment=nil,nil,nil
  State.Phase="candidate"
end

local function preparationPublish(State)
  local report=State.Report
  if State.Best then
    local choice=State.Best
    local candidate=report.Candidates[choice.CandidateIndex]
    local variant=candidate.Variants[choice.VariantIndex]
    candidate.Selected,variant.Selected=true,true
    report.Proposal={Status="ready_under_model", ContextId=report.ContextId,
      CandidateIndex=choice.CandidateIndex,VariantIndex=choice.VariantIndex,
      Positions=preparationCopy(variant.Positions),PointMap=preparationCopy(variant.PointMap),
      Cost=variant.Cost,Score=variant.Score,ScoreTerms=preparationCopy(variant.ScoreTerms),CostUnits=report.CostUnits,
      Length=variant.Geometry.Length,ReachesGoal=candidate.Raw.ReachesGoal,
      RemainingDistance=candidate.Raw.RemainingDistance,
      Pose=preparationCopy(report.Pose),Model=preparationCopy(report.Model),ExecutionValidated=false,
      Checks={CandidateIndex=choice.CandidateIndex,VariantIndex=choice.VariantIndex}}
    preparationFinish(State,"ready_under_model")
  else
    local status,reason=preparationFailureStatus(report.Candidates)
    preparationFinish(State,status,reason or "no_ready_candidate")
  end
end

local function preparationShortcutFailure(State, Status, Reason, Native)
  local summary=State.Report.Candidates[State.CandidateIndex].Simplification
  summary.Failures=summary.Failures+1
  summary.Reasons[Reason]=(summary.Reasons[Reason] or 0)+1
  if not summary.FirstFailure then
    summary.FirstFailure={Status=Status,Reason=Reason,RemovedRawPoint=State.Trial.PointMapRemoved,
      Connection=preparationCopy(State.Trial.Connection),Depth=preparationCopy(State.Trial.Depth),
      Detail=preparationCopy(Native)}
  end
  State.ShortcutIndex=State.ShortcutIndex+1
  State.Trial,State.TrialGeometry=nil,nil
  State.Phase="shortcut"
end

local function preparationBeginManeuvers(State)
  State.VariantIndex=1
  State.Variant=State.Report.Candidates[State.CandidateIndex].Variants[1]
  State.ScanIndex,State.PreviousSegment=1,nil
  State.Phase="entry_scan"
  State.Variant.Maneuver.Status="running"
end

local function preparationFinishVariant(State, Status, Reason)
  local variant=State.Variant
  variant.Maneuver.Status,variant.Maneuver.Reason=Status,Reason
  variant.Status,variant.Reason=Status,Reason
  State.VariantIndex=State.VariantIndex+1
  State.Variant=State.Report.Candidates[State.CandidateIndex].Variants[State.VariantIndex]
  State.Event,State.Footprints=nil,nil
  if State.Variant then
    State.ScanIndex,State.PreviousSegment=1,nil
    State.Variant.Maneuver.Status="running"
    State.Phase="entry_scan"
  else
    preparationCompleteCandidate(State)
  end
end

local function preparationManeuverFailure(State, Status, Reason, StripIndex, Native)
  local event=State.Event
  event.Status,event.Reason=Status,Reason
  State.Variant.Maneuver.FirstFailure={EventIndex=#State.Variant.Maneuver.Events,Kind=event.Kind,
    PointIndex=event.PointIndex,Status=Status,Reason=Reason,StripIndex=StripIndex,Native=preparationCopy(Native)}
  preparationFinishVariant(State,Status,Reason)
end

local function preparationEvent(State, Kind, PointIndex, Incoming, Outgoing)
  local variant=State.Variant
  if #variant.Maneuver.Events>=State.Limits.MaxManeuverEvents then
    preparationFinishVariant(State,"limited","maneuver_event_limit")
    return
  end
  local geometry=State.Geometries[State.VariantIndex]
  local event={Kind=Kind, CandidateIndex=State.CandidateIndex, VariantIndex=State.VariantIndex,
    PointIndex=PointIndex,Position=preparationCopy(geometry.Positions[PointIndex]),
    DistanceFromStart=geometry.Distances[PointIndex],ContextId=State.Report.ContextId,
    ReachesGoal=State.Report.Candidates[State.CandidateIndex].Raw.ReachesGoal,Status="running",Strips={}}
  if Incoming then
    event.IncomingSegment,event.IncomingHeading,event.IncomingLength=Incoming.Index,Incoming.Heading,Incoming.Length
    event.IncomingStart=preparationCopy(geometry.Positions[Incoming.Index])
  elseif Kind=="entry" then
    event.IncomingHeading=State.Report.Pose.HeadingDeg
  end
  if Outgoing then
    event.OutgoingSegment,event.OutgoingHeading,event.OutgoingLength=Outgoing.Index,Outgoing.Heading,Outgoing.Length
    event.OutgoingGoal=preparationCopy(geometry.Positions[Outgoing.Index+1])
  end
  if event.IncomingHeading~=nil and event.OutgoingHeading~=nil then
    local angle=(event.OutgoingHeading-event.IncomingHeading)%360
    event.SignedAngle=angle>180 and angle-360 or angle
  end
  variant.Maneuver.Events[#variant.Maneuver.Events+1]=event
  State.Event=event
  State.Phase="model"
end

local function preparationEventComplete(State)
  local event=State.Event
  local variant=State.Variant
  variant.Maneuver.CompletedEvents=variant.Maneuver.CompletedEvents+1
  State.Event,State.Footprints=nil,nil
  if event.Kind=="terminal" then
    if State.UnverifiedReason then
      preparationFinishVariant(State,"unverified",State.UnverifiedReason)
    else
      preparationFinishVariant(State,"ready_under_model")
    end
  else
    State.Phase="turn_scan"
  end
end

local function preparationModelResult(State, Result)
  preparationFields(Result,"Status Reason Strips","Maneuver result")
  local status,reason=rawget(Result,"Status"),rawget(Result,"Reason")
  assert(status=="modeled" or status=="rejected" or status=="unavailable" or status=="unverified",
    "NAVYGROUP: invalid maneuver Status")
  if status~="modeled" then
    preparationText(reason,"Maneuver Reason")
    assert(rawget(Result,"Strips")==nil, "NAVYGROUP: failed maneuver Strips must be nil")
    preparationManeuverFailure(State,status,reason)
    return
  end
  assert(reason==nil, "NAVYGROUP: modeled maneuver Reason must be nil")
  local strips=rawget(Result,"Strips")
  local count=preparationArray(strips,"Maneuver.Strips")
  assert(count>0, "NAVYGROUP: modeled maneuver requires non-empty Strips")
  if count>State.Limits.MaxFootprintPaths then
    preparationManeuverFailure(State,"limited","footprint_path_limit")
    return
  end
  local total=0
  for index=1,count do
    local strip=strips[index]
    preparationFields(strip,"Positions CorridorWidth","Maneuver strip")
    local width=rawget(strip,"CorridorWidth")
    assert(preparationFinite(width) and width>=0, "NAVYGROUP: strip CorridorWidth must be finite and non-negative")
    local points=preparationArray(rawget(strip,"Positions"),"Strip.Positions")
    assert(points>0, "NAVYGROUP: strip Positions must not be empty")
    total=total+points
    if points>State.Limits.MaxPoints or total>State.Limits.MaxFootprintPoints then
      preparationManeuverFailure(State,"limited","footprint_point_limit")
      return
    end
  end
  local footprints={}
  for index=1,count do
    local strip=strips[index]
    footprints[index]={Positions=preparationPoints(strip.Positions,"Strip.Positions",State.Limits.MaxPoints),
      CorridorWidth=math.max(strip.CorridorWidth,State.DepthOptions.CorridorWidth),
      Geometry={Status="not_run"},Depth={Kind="depth",Status="not_run"}}
  end
  State.Event.Strips=footprints
  State.Footprints,State.FootprintIndex=footprints,1
  State.Phase="footprint"
end

local function preparationAdvance(State)
  local report=State.Report
  local candidate=report.Candidates[State.CandidateIndex]
  if State.Phase=="candidate" then
    if not candidate then
      preparationPublish(State)
      return
    end
    candidate.Status="running"
    local raw=candidate.Raw
    local geometry,reason,detail=PATHLINE.CreateGeometry(raw.Positions,{MaxPoints=State.Limits.MaxPoints})
    local pointMap={}
    for index=1,#raw.Positions do
      pointMap[index]=index
    end
    local variant=preparationVariant(raw.Positions,pointMap,"raw")
    candidate.Variants[1]=variant
    if not geometry then
      local status=(reason=="numeric_range" or reason=="point_limit") and "limited" or "rejected"
      variant.Geometry={Status=status,Reason=reason,Detail=detail}
      variant.Status,variant.Reason=status,reason
      preparationCompleteCandidate(State)
      return
    end
    if not preparationSamePosition(geometry.Positions[1],report.Start)
      or (raw.ReachesGoal and not preparationSamePosition(geometry.Positions[geometry.PointCount],report.Goal)) then
      variant.Geometry={Status="rejected",Reason="endpoint_mismatch"}
      variant.Status,variant.Reason="rejected","endpoint_mismatch"
      preparationCompleteCandidate(State)
      return
    end
    variant.Geometry={Status="clear",Length=geometry.TotalLength,PointCount=geometry.PointCount}
    State.Geometries={geometry}
    State.CheckedGeometry=geometry
    preparationStartValidation(State,geometry,State.Connection,variant.Connection,function(connection)
      if connection.Status~="clear" then
        preparationReject(variant,connection)
        preparationCompleteCandidate(State)
      elseif preparationScore(State,variant,connection.TotalCost) then
        State.Phase="raw_depth"
      else
        preparationCompleteCandidate(State)
      end
    end)
  elseif State.Phase=="raw_depth" then
    local variant=candidate.Variants[1]
    preparationStartValidation(State,State.CheckedGeometry,State.DepthEvaluator,variant.Depth,function(depth)
      if depth.Status~="clear" then
        preparationReject(variant,depth)
        preparationCompleteCandidate(State)
      else
        State.ShortcutIndex=2
        State.Phase="shortcut"
      end
    end)
  elseif State.Phase=="shortcut" then
    local summary=candidate.Simplification
    local current=candidate.Variants[2] or candidate.Variants[1]
    if not State.Limits.Simplify or State.ShortcutIndex>=#current.Positions then
      summary.StopReason=State.Limits.Simplify and "complete" or "disabled"
      preparationBeginManeuvers(State)
    elseif summary.Attempts>=State.Limits.MaxShortcutAttempts then
      summary.StopReason="shortcut_attempt_limit"
      preparationBeginManeuvers(State)
    else
      summary.Attempts=summary.Attempts+1
      local points,mapping={},{}
      for index=1,#current.Positions do
        if index~=State.ShortcutIndex then
          points[#points+1]=current.Positions[index]
          mapping[#mapping+1]=current.PointMap[index]
        end
      end
      local trial=preparationVariant(points,mapping,"simplified")
      trial.PointMapRemoved=current.PointMap[State.ShortcutIndex]
      local geometry,reason,detail=PATHLINE.CreateGeometry(trial.Positions,{MaxPoints=State.Limits.MaxPoints})
      State.Trial,State.TrialGeometry=trial,geometry
      if not geometry then
        preparationShortcutFailure(State,"limited",reason,detail)
        return
      end
      trial.Geometry={Status="clear",Length=geometry.TotalLength,PointCount=geometry.PointCount}
      preparationStartValidation(State,geometry,State.Connection,trial.Connection,function(connection)
        if connection.Status~="clear" then
          preparationShortcutFailure(State,connection.Status,connection.Reason)
        elseif connection.TotalCost>current.Cost then
          preparationShortcutFailure(State,"not_preferred","cost_increase",{PreviousCost=current.Cost,Cost=connection.TotalCost})
        elseif preparationScore(State,trial,connection.TotalCost) then
          State.Phase="trial_depth"
        else
          preparationShortcutFailure(State,"limited",trial.Reason)
        end
      end)
    end
  elseif State.Phase=="trial_depth" then
    local trial=State.Trial
    preparationStartValidation(State,State.TrialGeometry,State.DepthEvaluator,trial.Depth,function(depth)
      if depth.Status~="clear" then
        preparationShortcutFailure(State,depth.Status,depth.Reason)
      else
        candidate.Simplification.Accepted=candidate.Simplification.Accepted+1
        trial.PointMapRemoved=nil
        candidate.Variants[2]=trial
        State.CheckedGeometry=State.TrialGeometry
        State.Geometries[2]=State.CheckedGeometry
        State.Trial,State.TrialGeometry=nil,nil
        State.Phase="shortcut"
      end
    end)
  elseif State.Phase=="entry_scan" then
    local geometry=State.Geometries[State.VariantIndex]
    local segment=geometry.Segments[State.ScanIndex]
    State.ScanIndex=State.ScanIndex+1
    if not segment then
      preparationEvent(State,"entry",1)
    elseif segment.Length>0 then
      State.PreviousSegment=segment
      preparationEvent(State,"entry",1,nil,segment)
    end
  elseif State.Phase=="turn_scan" then
    local geometry=State.Geometries[State.VariantIndex]
    local segment=geometry.Segments[State.ScanIndex]
    State.ScanIndex=State.ScanIndex+1
    if not segment then
      preparationEvent(State,"terminal",geometry.PointCount,State.PreviousSegment)
    elseif segment.Length>0 then
      local previous=State.PreviousSegment
      State.PreviousSegment=segment
      -- Collinear junctions need no separate turn hypothesis; duplicate legs were skipped above.
      if previous.Heading~=segment.Heading then
        preparationEvent(State,"turn",segment.Index,previous,segment)
      end
    end
  elseif State.Phase=="model" then
    if State.UnverifiedReason then
      State.Event.Status,State.Event.Reason="unverified",State.UnverifiedReason
      preparationEventComplete(State)
    else
      local event=preparationCopy(State.Event)
      event.Status,event.Reason,event.Strips=nil,nil,nil
      local callback=State.Maneuver
      local result=callback(event,preparationCopy(report.Pose),preparationCopy(report.Model))
      if report.Status=="running" then
        preparationModelResult(State,result)
      end
    end
  elseif State.Phase=="footprint" then
    local footprint=State.Footprints[State.FootprintIndex]
    if not footprint then
      State.Event.Status="clear_under_model"
      preparationEventComplete(State)
      return
    end
    local geometry,reason,detail=PATHLINE.CreateGeometry(footprint.Positions,{MaxPoints=State.Limits.MaxPoints})
    if not geometry then
      -- Unsupported geometry is missing model evidence, not an exhausted work allowance.
      local status=(reason=="point_limit" or reason=="numeric_range") and "limited" or "unavailable"
      footprint.Geometry={Status=status,Reason=reason,Detail=detail}
      preparationManeuverFailure(State,status,reason,State.FootprintIndex)
      return
    end
    footprint.Geometry={Status="clear",Length=geometry.TotalLength,PointCount=geometry.PointCount}
    local options=preparationCopy(State.DepthOptions)
    options.CorridorWidth=footprint.CorridorWidth
    local evaluator
    evaluator,reason,detail=PATHLINE.CreateDepthEvaluator(options)
    if not evaluator then
      footprint.Depth.Status,footprint.Depth.Reason,footprint.Depth.Detail="limited",reason,detail
      preparationManeuverFailure(State,"limited",reason,State.FootprintIndex)
      return
    end
    preparationStartValidation(State,geometry,evaluator,footprint.Depth,function(depth)
      if depth.Status~="clear" then
        preparationManeuverFailure(State,depth.Status=="blocked" and "rejected" or depth.Status,
          depth.Reason,State.FootprintIndex,depth)
      else
        State.Variant.Maneuver.CheckedStrips=State.Variant.Maneuver.CheckedStrips+1
        State.FootprintIndex=State.FootprintIndex+1
        State.Phase="footprint"
      end
    end)
  else
    error("NAVYGROUP: invalid route preparation phase")
  end
end

--- Adapt fresh ASTAR rule/cost checks to PATHLINE validation without changing a search or its pending request.
-- CostUnits is explicit. Failed math.huge costs are omitted; bounded depth evidence is mapped to PATHLINE.
-- The owner must cancel/change preparation context after rule/cost/terrain changes between calls.
-- @param Core.Astar#ASTAR Search Stable configured search; no nodes or live NAVYGROUP object are retained by reports.
-- @param #string CostUnits Non-empty cost-unit name, e.g. depth_weighted_meters; not a claim of physical route length.
-- @return Core.Pathline#PATHLINE.ConnectionEvaluator Opaque descriptor, no terrain queries on creation.
function NAVYGROUP.CreateRouteConnectionEvaluator(Search, CostUnits)
  assert(type(Search)=="table" and type(Search.EvaluateConnection)=="function", "NAVYGROUP: Search must provide EvaluateConnection")
  preparationText(CostUnits,"CostUnits")
  return PATHLINE.CreateConnectionEvaluator(function(Start,Goal)
    local valid,cost,report=Search:EvaluateConnection(Start,Goal)
    local result={Status=report.Status,Reason=report.Reason,Cost=valid and cost or nil}
    if report.Depth then
      local depth=report.Depth
      result.Evidence={Depth=depth.Depth,SurfaceType=depth.SurfaceType,Cause=depth.Cause,Source="ASTAR.EvaluateConnection",
        ProfileOffset=depth.ProfileOffset}
      local point=depth.Point
      if point and preparationFinite(point.x) and preparationFinite(point.z) then
        result.Evidence.Position={x=point.x,z=point.z}
      end
    end
    return result
  end,{CostUnits=CostUnits})
end

--- Start fixed-pose naval route preparation without work, registration or movement authority.
-- Copies finite input/settings and retains only stable evaluator callbacks. All output tables are detached copies.
-- Every candidate keeps its original order and raw reference; oversized inputs finish limited without truncation.
-- Invalid arguments raise before terrain access. Missing model/pose data prevents selection, not geometry/depth diagnostics.
-- LOCAL remains unavailable; this API never modifies mission waypoints, timers, FSM or controllers.
-- @param #NAVYGROUP.RoutePreparationInput Input Frozen start/goal/pose and dense ordered ASTAR candidates.
-- @param #NAVYGROUP.RoutePreparationEvaluators Evaluators Stable injected connection and optional explicit maneuver model.
-- @param #NAVYGROUP.RoutePreparationOptions Options Required Depth configuration and optional copied limits/context.
-- @return #NAVYGROUP.RoutePreparationJob Opaque caller-stepped job.
-- @return #NAVYGROUP.RoutePreparationReport Independent initial report.
function NAVYGROUP.StartRoutePreparation(Input, Evaluators, Options)
  preparationFields(Input,"Start Goal Pose Candidates","Input")
  preparationFields(Evaluators,"Connection Maneuver Model","Evaluators")
  local limits=preparationSettings(Options,true)
  local report={Status="running",ContextId=limits.ContextId,Start=preparationPosition(rawget(Input,"Start"),"Start"),
    Goal=preparationPosition(rawget(Input,"Goal"),"Goal"),Pose=preparationPose(rawget(Input,"Pose")),
    Candidates={},ExecutionValidated=false,Counters=preparationCounters(),Limits=preparationCopy(limits)}
  local count=preparationArray(rawget(Input,"Candidates"),"Candidates")
  local maneuver=rawget(Evaluators,"Maneuver")
  assert(maneuver==nil or type(maneuver)=="function", "NAVYGROUP: Maneuver must be a function")
  assert(maneuver~=nil or rawget(Evaluators,"Model")==nil, "NAVYGROUP: Model requires a Maneuver callback")
  if maneuver then
    report.Model=preparationModel(rawget(Evaluators,"Model"))
  end
  local connection=rawget(Evaluators,"Connection")
  local probe=assert(PATHLINE.CreateGeometry({report.Start}))
  local inspection,connectionReport=PATHLINE.StartValidation(probe,connection)
  PATHLINE.CancelValidation(inspection,"descriptor_inspection")
  assert(connectionReport.EvaluatorKind=="connection" and connectionReport.CostUnits~=nil,
    "NAVYGROUP: Connection must be a connection evaluator with CostUnits")
  report.CostUnits=connectionReport.CostUnits
  local depthOptions=type(Options)=="table" and rawget(Options,"Depth") or nil
  local depthEvaluator,depthReason,depthDetail=PATHLINE.CreateDepthEvaluator(depthOptions)
  if depthEvaluator then
    local depthInspection,depthReport=PATHLINE.StartValidation(probe,depthEvaluator)
    PATHLINE.CancelValidation(depthInspection,"descriptor_inspection")
    report.DepthCoverage=preparationCopy(depthReport.Coverage)
    depthOptions=preparationCopy(depthReport.Coverage)
    depthOptions.EvaluatorKind,depthOptions.OffsetCount,depthOptions.ActualLateralSpacing=nil,nil,nil
  end
  local state={Report=report,Limits=limits,Connection=connection,Maneuver=maneuver,DepthEvaluator=depthEvaluator,
    DepthOptions=depthOptions,CPUComplete=true,CandidateIndex=1,Phase="candidate"}
  local handle=preparationHandle(state)
  if count>limits.MaxCandidates then
    report.InputFailure={Required=count,Limit=limits.MaxCandidates}
    preparationFinish(state,"limited","candidate_limit")
    return handle,preparationCopy(report)
  end
  local oversized
  for index=1,count do
    local raw,reason,detail=preparationCandidate(Input.Candidates[index],index,limits.MaxPoints)
    report.Candidates[index]={CandidateIndex=index,Raw=raw,Status="not_run",Variants={},Selected=false,
      ExecutionValidated=false,Simplification={Attempts=0,Accepted=0,Failures=0,Reasons={}}}
    if reason and not oversized then
      oversized={CandidateIndex=index,Reason=reason,Detail=detail}
    end
  end
  if oversized then
    report.InputFailure=oversized
    preparationFinish(state,"limited",oversized.Reason)
  elseif not preparationSamePosition(report.Start,report.Pose.Position) then
    preparationFinish(state,"rejected","input_mismatch")
  elseif not depthEvaluator then
    report.InputFailure=depthDetail
    preparationFinish(state,"limited",depthReason)
  end
  if not maneuver then
    state.UnverifiedReason="maneuver_model_missing"
  elseif report.Pose.HeadingDeg==nil or report.Pose.ActualSpeedMps==nil
    or report.Pose.RequestedSpeedMps==nil or report.Pose.Hull==nil then
    state.UnverifiedReason="maneuver_pose_incomplete"
  end
  return handle,preparationCopy(report)
end

--- Query a detached report without work or clock/terrain access.
-- @param #NAVYGROUP.RoutePreparationJob Job Valid running or terminal handle.
-- @return #NAVYGROUP.RoutePreparationReport Independent report including nested candidate/variant evidence.
function NAVYGROUP.GetRoutePreparationReport(Job)
  return preparationCopy(preparationState(Job).Report)
end

--- Cancel pending preparation and subordinate validation. Terminal results retain their first outcome.
-- May be called from a callback: already admitted work is counted, but its result cannot publish a proposal.
-- No movement command, stop, automatic retry or continuation is issued.
-- @param #NAVYGROUP.RoutePreparationJob Job Valid handle.
-- @param #string Reason Optional non-empty short reason, default cancelled.
-- @return #NAVYGROUP.RoutePreparationReport Independent terminal report.
function NAVYGROUP.CancelRoutePreparation(Job, Reason)
  local state=preparationState(Job)
  if state.Report.Status=="running" then
    if Reason==nil then
      Reason="cancelled"
    end
    preparationText(Reason,"Reason")
    preparationFinish(state,"cancelled",Reason)
  end
  return preparationCopy(state.Report)
end

local function preparationRunSlice(State, Budget, Timing)
  if type(os)=="table" and type(os.clock)=="function" then
    Timing.Read=os.clock
    preparationMeasure(State,Timing)
  else
    State.CPUComplete=false
    State.Report.Counters.CPUSeconds=nil
  end
  while State.Report.Status=="running" do
    State.Report.Cursor={CandidateIndex=State.CandidateIndex,VariantIndex=State.VariantIndex,Phase=State.Phase}
    if not preparationCPUAdmission(State,Budget) then
      return
    end
    if State.Active then
      if not preparationValidationStep(State,Budget) then
        return
      end
    else
      local specific=State.Phase=="model" and not State.UnverifiedReason and "ManeuverCalls" or nil
      if not preparationAdmission(State,Budget,specific) then
        return
      end
      preparationAdvance(State)
    end
    preparationMeasure(State,Timing)
  end
end

--- Advance preparation within shared slice/job limits; no scheduler or controller access.
-- Raw geometry survives failed optional shortcuts and maneuver trials. Exact-goal priority precedes repriced score,
-- with stable original-candidate/raw-variant tie keys. Only ready_under_model variants can publish a proposal;
-- every result retains explicit model/calibration and ExecutionValidated=false. Missing depth remains unavailable.
-- Context mismatch cancels before work; recheck identity before using a terminal proposal. Jobs never restart.
-- CPU is inclusive active os.clock time, excluding idle time; nested validation CPU must not be added to it.
-- Count/CPU caps bound cooperative admission, not atomic callbacks/native call duration or simulator physics.
-- Invalid arguments leave running state unchanged. Reentrant stepping is an error. Evaluation errors release work
-- and propagate the original exception unchanged, including when a callback cancels then raises.
-- @param #NAVYGROUP.RoutePreparationJob Job Running or terminal handle.
-- @param #NAVYGROUP.RoutePreparationBudget Budget Optional copied per-step settings, zero preserved.
-- @param #string CurrentContextId Optional original context, or integer; required to match if configured at start.
-- @return #NAVYGROUP.RoutePreparationReport Independent report; only running is resumable.
function NAVYGROUP.StepRoutePreparation(Job, Budget, CurrentContextId)
  local state=preparationState(Job)
  assert(not state.Busy, "NAVYGROUP: route preparation job is already being stepped")
  local report=state.Report
  if report.Status~="running" then
    return preparationCopy(report)
  end
  local limits=preparationSettings(Budget,false)
  preparationContext(CurrentContextId)
  assert(report.ContextId~=nil or CurrentContextId==nil, "NAVYGROUP: CurrentContextId requires a configured ContextId")
  report.LastSlice=preparationCounters()
  if report.ContextId~=CurrentContextId then
    preparationFinish(state,"cancelled","context_changed")
    return preparationCopy(report)
  end
  state.Busy=true
  local timing={Base=report.Counters.CPUSeconds or 0}
  -- Protect only active evaluation/measurement so cleanup never conceals a native or programming error.
  local ok,err=pcall(preparationRunSlice,state,limits,timing)
  local measured,measurementError=pcall(preparationMeasure,state,timing)
  state.Busy=false
  if not measured then
    state.CPUComplete=false
    report.Counters.CPUSeconds,report.LastSlice.CPUSeconds=nil,nil
  end
  local slice=report.LastSlice
  if slice.CPUSeconds~=nil and (limits.MaxCPUSeconds~=nil or state.Limits.MaxCPUSeconds~=nil) then
    local overrun=0
    if limits.MaxCPUSeconds~=nil then
      overrun=math.max(overrun,slice.CPUSeconds-limits.MaxCPUSeconds)
    end
    if state.Limits.MaxCPUSeconds~=nil and report.Counters.CPUSeconds~=nil then
      overrun=math.max(overrun,report.Counters.CPUSeconds-state.Limits.MaxCPUSeconds)
    end
    slice.CPUOverrunSeconds=overrun
  end
  if not ok or not measured then
    preparationFinish(state,"error","evaluation_error")
    if not ok then
      error(err,0)
    end
    error(measurementError,0)
  end
  return preparationCopy(report)
end


--- Enable/disable pathfinding.
-- Uses terrain profiles to check minimum water depth along the center and both edges of the corridor.
-- Failed searches stop the ship until a new movement command is issued; there is no automatic retry.
-- Search grids use GRID.Resolution.FINE with GRID.Width.NORMAL and GRID.Margin.NORMAL; no grid dimensions are required.
-- SetPathfindingMinDepth() configures depth separately. Profiles assume linear terrain between their points;
-- three parallel checks do not cover the entire corridor or simulate the ship's turning arc.
-- SetPathfindingPreferredDepth() optionally makes A* trade extra distance for deeper water during waypoint searches.
-- @param #NAVYGROUP self
-- @param #boolean Switch If true, enable pathfinding.
-- @param #number CorridorWidth (Optional) Total water corridor width in meters. Default: widest ship plus 10 m on each side; 50 m if dimensions are unavailable. Zero checks only the center line.
-- @return #NAVYGROUP self
function NAVYGROUP:SetPathfinding(Switch, CorridorWidth)

  assert(type(Switch)=="boolean", "NAVYGROUP: pathfinding switch must be a boolean")

  if CorridorWidth~=nil then
    assert(type(CorridorWidth)=="number" and CorridorWidth>=0 and CorridorWidth<math.huge,"NAVYGROUP: corridor width must be finite and non-negative")
  end

  self.pathfindingOn=Switch
  self.pathCorridor=CorridorWidth

  if not Switch then
    self:_ClearPathfindingDrawing()
  end

  return self
end

--- Select the naval route-search strategy without starting or resuming movement.
-- Only WAYPOINT is available. LOCAL raises an error before changing any navigation state;
-- the experimental local implementation was removed for a staged rebuild.
-- @param #NAVYGROUP self
-- @param #string Mode (Optional) NAVYGROUP.PathfindingMode.WAYPOINT (default).
-- NAVYGROUP.PathfindingMode.LOCAL remains a recognized value but always raises a removal error.
-- @return #NAVYGROUP self.
function NAVYGROUP:SetPathfindingMode(Mode)

  if Mode==nil then
    Mode=NAVYGROUP.PathfindingMode.WAYPOINT
  end

  if Mode==NAVYGROUP.PathfindingMode.LOCAL then
    error("NAVYGROUP: LOCAL pathfinding mode has been removed; local navigation is unavailable pending a rebuild",2)
  end
  assert(Mode==NAVYGROUP.PathfindingMode.WAYPOINT,"NAVYGROUP: unknown pathfinding mode")

  self.pathfindingMode=Mode
  return self
end

--- Enable pathfinding.
-- Uses the configured minimum depth, or 20 meters by default.
-- @param #NAVYGROUP self
-- @param #number CorridorWidth (Optional) Total water corridor width in meters. Default: widest ship plus 10 m on each side; 50 m if dimensions are unavailable. Zero checks only the center line.
-- @return #NAVYGROUP self
function NAVYGROUP:SetPathfindingOn(CorridorWidth)

  self:SetPathfinding(true, CorridorWidth)

  return self
end

--- Disable pathfinding.
-- @param #NAVYGROUP self
-- @return #NAVYGROUP self
function NAVYGROUP:SetPathfindingOff()

  self:SetPathfinding(false, self.pathCorridor)

  return self
end

--- Set the minimum water depth used by pathfinding and collision checks.
-- New searches and safety checks use the new depth, including during turns; stopped ships remain stopped.
-- @param #NAVYGROUP self
-- @param #number MinDepth (Optional) Positive finite minimum water depth in meters, inclusive; default 20.
-- @return #NAVYGROUP self.
function NAVYGROUP:SetPathfindingMinDepth(MinDepth)

  if MinDepth==nil then
    MinDepth=20
  end

  assert(type(MinDepth)=="number" and MinDepth>0 and MinDepth<math.huge,"NAVYGROUP: minimum depth must be finite and positive")

  self.pathMinDepth=MinDepth

  return self
end

--- Prefer deeper water during path searches, without changing the collision threshold.
-- At PreferredDepth and deeper, A* uses ordinary distance costs. Towards the minimum depth,
-- a quadratic penalty increases the cost up to 1 + Weight times the distance. Shallower water
-- remains blocked by SetPathfindingMinDepth(). Collision checks use only the minimum depth.
-- New searches use this setting; the installed route remains active.
-- @param #NAVYGROUP self
-- @param #number PreferredDepth (Optional) Positive finite depth in meters; nil disables the preference. At/below the minimum adds no penalty.
-- @param #number Weight (Optional) Finite non-negative penalty strength; default 2. Zero adds no penalty.
-- @return #NAVYGROUP self.
---@param PreferredDepth? number
---@param Weight? number
---@return NAVYGROUP
function NAVYGROUP:SetPathfindingPreferredDepth(PreferredDepth, Weight)

  if Weight==nil then Weight=2 end
  assert(PreferredDepth==nil or (PreferredDepth>0 and PreferredDepth<math.huge),
    "NAVYGROUP: preferred depth must be finite and positive")
  assert(Weight>=0 and Weight<math.huge,"NAVYGROUP: depth weight must be finite and non-negative")

  self.pathPreferredDepth=PreferredDepth
  self.pathDepthWeight=Weight

  return self
end

--- Configure the bounded grid used for automatic naval detours.
-- Uses GRID.Resolution.FINE with GRID.Width.NORMAL and GRID.Margin.NORMAL automatically.
-- Short connections retain a minimum search width of twice the safety corridor (at least 2000 meters)
-- and a margin of one safety corridor (at least 1000 meters), so approaching a waypoint does not collapse the grid.
-- Spacing follows the initial corridor dimensions and remains unchanged during expansion.
-- Calling this method is optional; only resource and expansion limits need explicit configuration.
-- @param #NAVYGROUP self
-- @param #number MaxCells (Optional) Positive integer candidate-cell budget; default 5000.
-- @param #number GrowthFactor (Optional) Expansion multiplier greater than 1; default 1.5.
-- @param #number MaxAttempts (Optional) Positive integer attempt limit including the initial search; default 5.
-- @return #NAVYGROUP self.
function NAVYGROUP:SetPathfindingGrid(MaxCells, GrowthFactor, MaxAttempts)
  local config=GRID:New("Naval configuration",GRID.Type.HEXAGON):SetMaxCells(MaxCells):SetExpansion(GrowthFactor,MaxAttempts):GetOptions()
  self.pathMaxCells=config.MaxCells
  self.pathGrowthFactor=config.Expansion.GrowthFactor
  self.pathMaxAttempts=config.Expansion.MaxAttempts
  return self
end



--- Snapshot of an explicitly enabled naval measurement interval.
-- @type NAVYGROUP.PathfindingDiagnostics
-- @field #boolean Enabled Whether the interval is recording; false retains its frozen values.
-- @field #number SearchAttempts Completed waypoint expansion attempts, including normal no-path results.
-- @field #number ValidityRequests ASTAR validity lookups during recorded searches.
-- @field #number ValidityCacheHits Validity lookups served from cache.
-- @field #number CostRequests ASTAR cost lookups during recorded searches.
-- @field #number CostCacheHits Cost lookups served from cache. Combined depth evaluation may populate these during validity checks.
-- @field #number ProfileQueries Native ASTAR/PATHLINE depth-profile calls within measured scopes, including unavailable results/errors.
-- @field #number RouteSubmissions Issued route commands, including explicit full stops while recording.
-- @field #number PeakRetainedCells Maximum sampled sum of distinct retained/measured grids' accepted cells.
-- @field #number Scopes Completed outer measurement scopes, including exceptions.
-- @field #number Errors Outer scopes which raised an exception; normal navigation failures are not exceptions.
-- @field #number CPUSeconds Aggregate CPU seconds; nil when the interval or an outer scope had no usable clock.
-- @field #number MaxScopeCPUSeconds Largest outer-scope CPU duration, or nil when aggregate timing is unavailable.
-- @field #table Operations Per-operation Calls, Errors, inclusive CPUSeconds and MaxCPUSeconds. Do not sum nested timings.

--- Create an independent measurement interval. No ship/search objects are retained.
function NAVYGROUP._NewPathfindingDiagnostics(Enabled)

  local timed=os and type(os.clock)=="function"
  return {Enabled=Enabled,SearchAttempts=0,ValidityRequests=0,ValidityCacheHits=0,
    CostRequests=0,CostCacheHits=0,ProfileQueries=0,RouteSubmissions=0,
    PeakRetainedCells=0,Scopes=0,Errors=0,ScopeDepth=0,Operations={},
    CPUSeconds=timed and 0 or nil,MaxScopeCPUSeconds=timed and 0 or nil}

end

--- Enable coarse naval planning measurements; disabled by default.
-- Enabling a stopped interval starts fresh. Repeated true retains the current interval; false freezes it.
-- Measures navigation updates, waypoint planning and route updates. Nested work contributes
-- once to aggregate CPU/profile counts; per-operation timings are inclusive and must not be summed.
-- User callbacks executed in these scopes are included. These are CPU seconds, never FPS or simulation time.
-- ProfileQueries counts actual ASTAR/PATHLINE depth-profile calls, including failures, without terrain hooks.
-- PeakRetainedCells is the maximum observed sum of distinct grids owned by active planners/debug views plus
-- the search being measured, sampled after searches/scopes; it is not a heap or exact instantaneous peak.
-- RouteSubmissions counts issued Route calls, not observed controller acceptance or ship movement.
-- @param #NAVYGROUP self
-- @param #boolean Enabled (Optional) Default true.
-- @return #NAVYGROUP self
function NAVYGROUP:SetPathfindingDiagnostics(Enabled)

  if Enabled==nil then Enabled=true end
  assert(type(Enabled)=="boolean","NAVYGROUP: diagnostics switch must be a boolean")
  local diagnostics=self.pathfindingDiagnostics
  assert(not diagnostics or diagnostics.ScopeDepth==0,"NAVYGROUP: change diagnostics between updates")
  if Enabled and (not diagnostics or not diagnostics.Enabled) then
    self.pathfindingDiagnostics=NAVYGROUP._NewPathfindingDiagnostics(true)
  elseif not Enabled and diagnostics then
    diagnostics.Enabled=false
  end
  return self

end

--- Get a caller-owned snapshot of the current/frozen measurement interval.
-- Untimed scopes have nil CPU fields; aggregate timing also requires a clock when enabling the interval.
-- Interval metrics are logged only by LogPathfindingDiagnostics().
-- @param #NAVYGROUP self
-- @return #NAVYGROUP.PathfindingDiagnostics Independent counts and timings.
function NAVYGROUP:GetPathfindingDiagnostics()

  local diagnostics=self.pathfindingDiagnostics or NAVYGROUP._NewPathfindingDiagnostics(false)
  local result={Operations={}}
  for key,value in pairs(diagnostics) do
    if key~="Operations" and key~="ScopeDepth" then result[key]=value end
  end
  for name,operation in pairs(diagnostics.Operations) do
    local copy={}
    for key,value in pairs(operation) do copy[key]=value end
    result.Operations[name]=copy
  end
  return result

end

--- Log one compact snapshot on explicit request, independent of trace settings.
-- @param #NAVYGROUP self
-- @return #NAVYGROUP self
function NAVYGROUP:LogPathfindingDiagnostics()

  local d=self:GetPathfindingDiagnostics()
  self:I(self.lid..string.format("Pathfinding metrics: searches=%d, depth_profiles=%d, routes=%d, peak_observed_cells=%d",
    d.SearchAttempts,d.ProfileQueries,d.RouteSubmissions,d.PeakRetainedCells))
  self:I(self.lid..string.format("Pathfinding cache: validity=%d/%d hits, cost=%d/%d hits",
    d.ValidityCacheHits,d.ValidityRequests,d.CostCacheHits,d.CostRequests))
  self:I(self.lid..string.format("Pathfinding CPU: scopes=%d, total_s=%s, max_scope_s=%s, errors=%d",
    d.Scopes,tostring(d.CPUSeconds),tostring(d.MaxScopeCPUSeconds),d.Errors))
  return self

end

--- Sample distinct retained grids without keeping measurement references alive.
function NAVYGROUP:_ObservePathfindingCells(Search)

  local diagnostics=self.pathfindingDiagnostics
  if not diagnostics or not diagnostics.Enabled then return end
  local grids={}
  local function add(search)
    if search then grids[search:GetGrid()]=true end
  end
  add(Search)
  add(self.pathfindingDebugSearch)
  local count=0
  for grid in pairs(grids) do count=count+grid:GetCellCount() end
  diagnostics.PeakRetainedCells=math.max(diagnostics.PeakRetainedCells,count)

end

--- Capture existing search counters before a waypoint search attempt.
function NAVYGROUP:_PathfindingSearchSnapshot(Search)

  local diagnostics=self.pathfindingDiagnostics
  if diagnostics and diagnostics.Enabled then
    return {Diagnostics=diagnostics,Valid=Search.nvalid,ValidHits=Search.nvalidcache,
      Cost=Search.ncost,CostHits=Search.ncostcache}
  end

end

--- Aggregate deltas without resetting an ASTAR's caches/counters or retaining it.
function NAVYGROUP:_RecordPathfindingSearch(Search, Before, Attempts)

  if not Before or Before.Diagnostics~=self.pathfindingDiagnostics then return end
  local d=Before.Diagnostics
  d.SearchAttempts=d.SearchAttempts+Attempts
  d.ValidityRequests=d.ValidityRequests+Search.nvalid-Before.Valid
  d.ValidityCacheHits=d.ValidityCacheHits+Search.nvalidcache-Before.ValidHits
  d.CostRequests=d.CostRequests+Search.ncost-Before.Cost
  d.CostCacheHits=d.CostCacheHits+Search.ncostcache-Before.CostHits
  self:_ObservePathfindingCells(Search)

end

--- Measure an existing operation while preserving all returns and propagating errors after cleanup.
function NAVYGROUP:_MeasurePathfinding(Name, Callback, ...)

  local d=self.pathfindingDiagnostics
  if not d or not d.Enabled then return Callback(self,...) end
  local clock=os and type(os.clock)=="function" and os.clock or nil
  local started=clock and clock() or nil
  local outer=d.ScopeDepth==0
  local profiles=outer and PATHLINE._GetDepthProfileCount() or nil
  local operation=d.Operations[Name]
  if not operation then
    operation={Calls=0,Errors=0,CPUSeconds=clock and 0 or nil,MaxCPUSeconds=clock and 0 or nil}
    d.Operations[Name]=operation
  end
  operation.Calls=operation.Calls+1
  d.ScopeDepth=d.ScopeDepth+1
  local function pack(...) return {n=select("#",...),...} end
  local values=pack(pcall(Callback,self,...))
  d.ScopeDepth=d.ScopeDepth-1
  local seconds=clock and math.max(0,clock()-started) or nil
  if seconds and operation.CPUSeconds then
    operation.CPUSeconds=operation.CPUSeconds+seconds
    operation.MaxCPUSeconds=math.max(operation.MaxCPUSeconds,seconds)
  else
    operation.CPUSeconds,operation.MaxCPUSeconds=nil,nil
  end
  if not values[1] then operation.Errors=operation.Errors+1 end
  if outer then
    d.Scopes=d.Scopes+1
    d.ProfileQueries=d.ProfileQueries+PATHLINE._GetDepthProfileCount()-profiles
    if seconds and d.CPUSeconds then
      d.CPUSeconds=d.CPUSeconds+seconds
      d.MaxScopeCPUSeconds=math.max(d.MaxScopeCPUSeconds,seconds)
    else
      d.CPUSeconds,d.MaxScopeCPUSeconds=nil,nil
    end
    if not values[1] then d.Errors=d.Errors+1 end
  end
  self:_ObservePathfindingCells()
  if not values[1] then error(values[2],0) end
  return unpack(values,2,values.n)

end

--- On before "UpdateRoute" event.
-- @param #NAVYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number n Next waypoint index. Default is the one coming after that one that has been passed last.
-- @param #number N Waypoint  Max waypoint index to be included in the route. Default is the final waypoint.
-- @param #number Speed Speed in knots to the next waypoint.
-- @param #number Depth Depth in meters to the next waypoint.
function NAVYGROUP:onbeforeUpdateRoute(From, Event, To, n, N, Speed, Depth)

  -- Is transition allowed? We assume yes until proven otherwise.
  local allowed=true
  local trepeat=nil

  if self:IsWaiting() then
    self:T(self.lid.."Update route denied. Group is WAITING!")
    return false
  elseif self:IsInUtero() then
    self:T(self.lid.."Update route denied. Group is INUTERO!")
    return false
  elseif self:IsDead() then
    self:T(self.lid.."Update route denied. Group is DEAD!")
    return false
  elseif self:IsStopped() then
    self:T(self.lid.."Update route denied. Group is STOPPED!")
    return false
  elseif self:IsHolding() then
    self:T(self.lid.."Update route denied. Group is holding position!")
    return false
  elseif self:IsEngaging() then
    self:T(self.lid.."Update route allowed. Group is engaging!")
    return true      
  end
  
  -- Check for a current task.
  if self.taskcurrent>0 then

    -- Get the current task. Must not be executing already.
    local task=self:GetTaskByID(self.taskcurrent)

    if task then
      if task.dcstask.id==AUFTRAG.SpecialTask.PATROLZONE then
        -- For patrol zone, we need to allow the update as we insert new waypoints.
        self:T2(self.lid.."Allowing update route for Task: PatrolZone")
      elseif task.dcstask.id==AUFTRAG.SpecialTask.RECON then
        -- For recon missions, we need to allow the update as we insert new waypoints.
        self:T2(self.lid.."Allowing update route for Task: ReconMission")
      elseif task.dcstask.id==AUFTRAG.SpecialTask.RELOCATECOHORT then
        -- For relocate
        self:T2(self.lid.."Allowing update route for Task: Relocate Cohort")
      elseif task.dcstask.id==AUFTRAG.SpecialTask.REARMING then
        -- For rearming
        self:T2(self.lid.."Allowing update route for Task: Rearming")                
      else
        local taskname=task and task.description or "No description"
        self:T(self.lid..string.format("WARNING: Update route denied because taskcurrent=%d>0! Task description = %s", self.taskcurrent, tostring(taskname)))
        allowed=false
      end
    else
      -- Now this can happen, if we directly use TaskExecute as the task is not in the task queue and cannot be removed. Therefore, also directly executed tasks should be added to the queue!
      self:T(self.lid..string.format("WARNING: before update route taskcurrent=%d (>0!) but no task?!", self.taskcurrent))
      -- Anyhow, a task is running so we do not allow to update the route!
      allowed=false
    end
  end

  -- Not good, because mission will never start. Better only check if there is a current task!
  --if self.currentmission then
  --end

  -- Only AI flights.
  if not self.isAI then
    allowed=false
  end

  -- Debug info.
  self:T2(self.lid..string.format("Onbefore Updateroute in state %s: allowed=%s (repeat in %s)", self:GetState(), tostring(allowed), tostring(trepeat)))

  -- Try again?
  if trepeat then
    self:__UpdateRoute(trepeat, n, N, Speed, Depth)
  end  
  
  return allowed
end

--- On after "UpdateRoute" event.
-- @param #NAVYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number n Next waypoint index. Default is the one coming after that one that has been passed last.
-- @param #number N Waypoint  Max waypoint index to be included in the route. Default is the final waypoint.
-- @param #number Speed Speed in knots to the next waypoint.
-- @param #number Depth Depth in meters to the next waypoint.
function NAVYGROUP:onafterUpdateRoute(From, Event, To, n, N, Speed, Depth)

  return self:_MeasurePathfinding("route_update",self._RunNavigationRouteUpdate,From, Event, To, n, N, Speed, Depth)

end

--- Execute the existing navigation operation; measurements are owned by the public entry above.
function NAVYGROUP:_RunNavigationRouteUpdate(From, Event, To, n, N, Speed, Depth)

  -- Resolve the same destination for native routing, collision checks and waypoint search.
  -- A newer inserted waypoint invalidates a previous Goto, whereas speed/depth changes retain it.
  if n then self:_SetNavigationWaypoint(self.waypoints[n]) end
  local target=self:_GetNavigationWaypoint()
  n=target and self:GetWaypointIndex(target.uid) or self:GetWaypointIndexNext()

  -- Max index.
  N=N or #self.waypoints  
  N=math.min(N, #self.waypoints)

  -- A patrol detour after the last waypoint leads back to an earlier original waypoint.
  -- Include that target in this same DCS route; temporary waypoint callbacks do not restart navigation.
  local last=self.waypoints[N]
  local targetIndex=last and last.astarTargetUID and self:GetWaypointIndex(last.astarTargetUID)
  if self.adinfinitum and N==#self.waypoints and targetIndex and targetIndex<n then
    N=N+targetIndex
  end

  -- Waypoints.
  local waypoints={}
  local detourTarget,detourSpeed
  
  for i=n, N do
  
    -- Waypoint.
    local index=(i-1)%#self.waypoints+1
    local wp=UTILS.DeepCopy(self.waypoints[index])  --Ops.OpsGroup#OPSGROUP.Waypoint
    
    --env.info(string.format("FF i=%d UID=%d   n=%d, N=%d", i, wp.uid, n, N))
      
    -- Speed.
    if Speed then
      -- Take speed specified.
      wp.speed=UTILS.KnotsToMps(Speed)
    else
      -- Take default waypoint speed. But make sure speed>0 if patrol ad infinitum.
      if wp.speed<0.1 then --self.adinfinitum and 
        wp.speed=UTILS.KmphToMps(self.speedCruise)
      end
    end

    -- Preserve the detour's commanded speed through its original target without changing stored waypoint data.
    if wp.astar then
      detourTarget,detourSpeed=wp.astarTargetUID,wp.speed
    elseif wp.uid==detourTarget then
      wp.speed=detourSpeed
      detourTarget,detourSpeed=nil,nil
    end
    
    -- Depth.
    if Depth then
      wp.alt=-Depth
    elseif self.depth then
      wp.alt=-self.depth
    else
      -- Take default waypoint alt.
      wp.alt=wp.alt or 0
    end
    
    -- Current set speed in m/s.
    if i==n then
      self.speedWp=wp.speed
      self.altWp=wp.alt
    end
  
    -- Add waypoint.
    table.insert(waypoints, wp)
  
  end
  
  -- Current waypoint.
  local current=self:GetCoordinate():WaypointNaval(UTILS.MpsToKmph(self.speedWp), self.altWp)
  table.insert(waypoints, 1, current)  

  
  if self:IsEngaging() or not self.passedfinalwp then
  
    if self.verbose>=10 then
      for i=1,#waypoints do
        local wp=waypoints[i] --Ops.OpsGroup#OPSGROUP.Waypoint
        local text=string.format("%s Waypoint [%d] UID=%d speed=%d m/s", self.groupname, i-1, wp.uid or -1, wp.speed)
        self:I(self.lid..text)
        COORDINATE:NewFromWaypoint(wp):MarkToAll(text)            
      end
    end

    -- Debug info.
    self:T(self.lid..string.format("Updateing route: WP %d-->%d (%d/%d), Speed=%.1f knots, Depth=%d m", self.currentwp, n, #waypoints, #self.waypoints, UTILS.MpsToKnots(self.speedWp), self.altWp))

    -- Route group to all defined waypoints remaining.
    if self.pathfindingDiagnostics and self.pathfindingDiagnostics.Enabled then
      self.pathfindingDiagnostics.RouteSubmissions=self.pathfindingDiagnostics.RouteSubmissions+1
    end
    self:Route(waypoints)
    
  else
  
    ---
    -- Passed final WP ==> Full Stop
    ---
  
    self:E(self.lid..string.format("WARNING: Passed final WP ==> Full Stop!"))
    self:FullStop()
    
  end

end

--- Check whether navigation may inspect and manage the current route.
-- Manual stops, waiting, completed routes and tasks with their own movement remain authoritative.
-- @param #NAVYGROUP self
-- @return #boolean True when route checks are allowed.
function NAVYGROUP:_CanNavigate()

  local state=self:GetState()

  if not self:IsAlive() or state=="Dead" or state=="Stopped" or state=="InUtero" then
    self.LastNavigationCheck=nil
    self.collisionwarning=false
    self.ispathfinding=false
    self:_ClearPathfindingDrawing()
    return false
  end

  if self:IsWaiting() or not self.isAI or (self.passedfinalwp and not self.adinfinitum and state~="Engaging") then
    return false
  end

  if state~="Cruising" and state~="Engaging" and state~="Returning" and state~="Retreating" and state~="OnDetour" then
    return false
  end

  -- Match UpdateRoute's task rules. Navigation must not replace an unrelated active DCS task.
  if state~="Engaging" and (self.taskcurrent or 0)>0 then
    local task=self:GetTaskByID(self.taskcurrent)
    local id=task and task.dcstask and task.dcstask.id
    local special=AUFTRAG.SpecialTask

    if not id or (id~=special.PATROLZONE and id~=special.RECON and id~=special.RELOCATECOHORT and id~=special.REARMING) then
      return false
    end
  end

  return true
end

--- Publish a navigation result and maintain collision-warning transitions.
-- Unknown terrain data neither fabricates an obstacle nor clears a previous warning.
-- @param #NAVYGROUP self
-- @param Core.Pathline#PATHLINE.DepthReport Report Detailed depth-check result.
function NAVYGROUP:_UpdateNavigationWarning(Report)

  local previous=self.LastNavigationCheck
  Report.Time=timer.getTime()
  self.LastNavigationCheck=Report

  if Report.Status=="blocked" and not self.collisionwarning then
    self:CollisionWarning(Report.ClearDistance)
  elseif Report.Status=="clear" and self.collisionwarning then
    self:ClearAhead()
  elseif Report.Status=="unavailable" and (not previous or previous.Status~="unavailable" or previous.Reason~=Report.Reason) then
    self:T(self.lid.."Navigation depth data unavailable: "..tostring(Report.Reason))
  end
end

--- Record the native destination for routing and waypoint searches.
-- Snapshot the next mission waypoint so a later Detour or inserted movement task can replace this command.
-- @param #NAVYGROUP self
-- @param Ops.OpsGroup#OPSGROUP.Waypoint Waypoint Destination, or nil to clear the command.
-- @return #NAVYGROUP self.
function NAVYGROUP:_SetNavigationWaypoint(Waypoint)

  local nextWaypoint=self:GetWaypointNext()
  self.navigationCommand=Waypoint and {TargetUID=Waypoint.uid,SourceUID=self:GetWaypointCurrentUID(),
    NextUID=nextWaypoint and nextWaypoint.uid} or nil
  return self
end

--- Resolve the next native destination, including an explicit GotoWaypoint command.
-- Expire the override when progress changes, its target disappears or a newer waypoint replaces the next leg.
-- @param #NAVYGROUP self
-- @return Ops.OpsGroup#OPSGROUP.Waypoint Next native waypoint, or nil.
function NAVYGROUP:_GetNavigationWaypoint()

  local nextWaypoint=self:GetWaypointNext()
  local nextUID=nextWaypoint and nextWaypoint.uid
  local command=self.navigationCommand

  if command and command.SourceUID==self:GetWaypointCurrentUID() and command.NextUID==nextUID then
    local waypoint=self:GetWaypointByID(command.TargetUID)
    if waypoint then return waypoint end
  end

  self.navigationCommand=nil
  return nextWaypoint
end

--- Check hull/heading clearance every two seconds and ordinary-route clearance every ten seconds.
-- The short hull check runs during turns too; it never starts a search.
-- The ordinary route check examines at most 5000 meters towards the next waypoint.
-- An obstruction triggers full-waypoint planning; failure stops the ship without automatic retries.
-- @param #NAVYGROUP self
function NAVYGROUP:_CheckNavigation()

  return self:_MeasurePathfinding("navigation_update",self._RunNavigationCheck)

end

--- Execute the existing navigation operation; measurements are owned by the public entry above.
function NAVYGROUP:_RunNavigationCheck()

  local now=timer.getTime()
  local safetyDue=not self.navigationSafetyTime or now-self.navigationSafetyTime>=2 or now<self.navigationSafetyTime
  if safetyDue then
    self.navigationSafetyTime=now
    self:_CheckTurning()
  end

  -- Immediate clearance follows the actual hull and heading, not a possibly outdated waypoint.
  -- Do this before ordinary planning or the usual turn-related route-check bypass.
  if safetyDue and self.pathfindingOn and self:_CanNavigate() then
    local command=self.navigationCommand
    local clear,reason,report=self:_CheckNavigationNearfield()
    self.LastNearfieldCheck=report
    report.Time=timer.getTime()

    if not clear then
      self:_UpdateNavigationWarning(report)

      -- A warning callback may hold, disable or replace navigation itself.
      if self.pathfindingOn and self:_CanNavigate() and self.navigationCommand==command then
        self:_FailPathfinding({StopReason=report.Status=="blocked" and "nearfield_blocked" or reason,
          DepthCheck=report,Mode=self.pathfindingMode})
      end
      return
    end
  end

  -- Ordinary collision/waypoint work retains its ten-second cadence.
  if self.navigationCheckTime and now>=self.navigationCheckTime and now-self.navigationCheckTime<10 then return end
  self.navigationCheckTime=now

  if not self:_CanNavigate() or self:IsTurning() then
    return
  end

  local waypoint=self:_GetNavigationWaypoint()
  if not waypoint then
    return
  end
  local command=self.navigationCommand
  local targetX,targetZ=waypoint.coordinate.x,waypoint.coordinate.z

  local position=VECTOR:NewFromVec(self:GetVec3())
  local clear,reason,report=self:_CheckNavigationAhead(position,waypoint)
  self:_UpdateNavigationWarning(report)

  -- Warning callbacks may disable pathfinding, stop the ship or change the route.
  if not self.pathfindingOn or not self:_CanNavigate() or self:_GetNavigationWaypoint()~=waypoint
    or self.navigationCommand~=command
    or waypoint.coordinate.x~=targetX or waypoint.coordinate.z~=targetZ then
    return
  end

  if report.Status=="unavailable" then
    -- Missing terrain data is not an obstacle that a larger grid can resolve.
    self:_FailPathfinding({StopReason=reason,Attempts={},DepthCheck=report})
  elseif not clear then
    self:_FindPathToNextWaypoint()
  end
end

--- Check the normal collision horizon towards an original waypoint.
-- Uses the configured minimum depth and corridor width.
-- @param #NAVYGROUP self
-- @param Core.Vector#VECTOR Position Current ship position.
-- @param Ops.OpsGroup#OPSGROUP.Waypoint Waypoint Original destination.
-- @return #boolean True when the checked corridor is clear.
-- @return #string Failure reason, or nil.
-- @return Core.Pathline#PATHLINE.DepthReport Clearance report for at most 5000 meters.
-- @return Core.Vector#VECTOR End of the checked horizon.
function NAVYGROUP:_CheckNavigationAhead(Position, Waypoint)

  local goal=VECTOR:NewFromVec(Waypoint.coordinate)
  local distance=Position:GetDistance(goal,true)

  if distance>5000 then
    local fraction=5000/distance
    goal=VECTOR:New(Position.x+(goal.x-Position.x)*fraction,Position.y,Position.z+(goal.z-Position.z)*fraction)
  end

  local clear,reason,report=self:_CheckPathDepth(Position,goal)
  return clear,reason,report,goal
end

--- Find and install a detour to the next original route waypoint.
-- Temporary ASTAR points are replaced only after a complete path has been found. The original target
-- and its waypoint tasks remain in the route. Failure stops the ship until a new movement command.
-- @param #NAVYGROUP self
-- @return #boolean True when a route was installed; false on failure or when navigation is inactive.
function NAVYGROUP:_FindPathToNextWaypoint()

  return self:_MeasurePathfinding("waypoint_plan",self._RunWaypointPathPlanning)

end

--- Execute the existing navigation operation; measurements are owned by the public entry above.
function NAVYGROUP:_RunWaypointPathPlanning()

  if not self.pathfindingOn or not self:_CanNavigate() or self:IsTurning() then
    return false
  end

  local target,pending=self:_GetPathfindingTarget()
  if not target then
    return false
  end

  local position=VECTOR:NewFromVec(self:GetVec3())
  local goal=VECTOR:NewFromVec(target.coordinate)
  local minDepth=self.pathMinDepth or 20
  local corridorWidth=self:_GetPathfindingCorridorWidth()

  self:_ClearPathfindingDrawing()

  -- Select geometry before retaining the grid for configuration and planning diagnostics.
  local astar=ASTAR:New(GRID.Type.HEXAGON)
  astar:SetStartCoordinate(position)
  astar:SetEndCoordinate(goal)
  astar:SetValidSurfaceTypes({land.SurfaceType.WATER,land.SurfaceType.SHALLOW_WATER})
  astar:SetValidNeighbourDepth(minDepth,corridorWidth)
  astar:SetCostDepth(self.pathPreferredDepth,self.pathDepthWeight)

  local grid=astar:GetGrid()
  grid:SetResolution(GRID.Resolution.FINE)
  grid:SetCorridor(GRID.Width.NORMAL,GRID.Margin.NORMAL)
  grid:SetMaxCells(self.pathMaxCells or 5000)
  grid:SetExpansion(self.pathGrowthFactor or 1.5,self.pathMaxAttempts or 5)

  -- Relative dimensions must still leave room to pass an obstacle near the target.
  -- NORMAL width is half the padded length: 0.75 times the endpoint distance with NORMAL margins.
  local minimumExtent=math.max(corridorWidth,1000)
  if position:GetDistance(goal,true)*0.75<2*minimumExtent then
    grid:SetCorridor(2*minimumExtent,minimumExtent)
  end

  local measurement=self:_PathfindingSearchSnapshot(astar)
  local built,reason=astar:CreateHexGrid()
  local path,report

  if built then
    -- The current position and the original target are already represented by the installed route.
    path,report=astar:GetPathWithExpansion(true,true)
  else
    report={StopReason=reason,Attempts={}}
  end

  self:_RecordPathfindingSearch(astar,measurement,#(report.Attempts or {}))

  report.MinDepth=minDepth
  report.CorridorWidth=corridorWidth
  report.Spacing=grid:GetResolutionInfo().Spacing

  if not path then
    return self:_FailPathfinding(report)
  end

  -- Keep the old route untouched until planning succeeds, then replace only the outstanding detour.
  for _,uid in ipairs(pending) do
    self:RemoveWaypointByID(uid,false)
  end

  local current=self:GetWaypointCurrent()
  local targetIndex=self:GetWaypointIndex(target.uid)
  local wrap=self.adinfinitum and self.currentwp==#self.waypoints and targetIndex==1
  local preceding=wrap and current or self.waypoints[targetIndex-1]
  local uid=preceding and preceding.uid
  local first
  local speed=self.speedWp or target.speed
  speed=speed and speed>0 and UTILS.MpsToKnots(speed) or self:GetSpeedCruise()

  for _,node in ipairs(path) do
    -- Grid altitude is terrain height. Naval waypoints retain the original route's altitude/depth.
    local point=VECTOR:New(node.vector.x,target.coordinate.y,node.vector.z)
    local waypoint=self:AddWaypoint(point,speed,uid,nil,false)
    waypoint.astar=true
    waypoint.astarTargetUID=target.uid

    -- A skipped mission waypoint must not reappear between this detour and its commanded destination.
    -- Insert just before the target; a patrol wrap retains the existing end-of-route detour layout.
    if not wrap and targetIndex==1 and not first then
      table.remove(self.waypoints)
      table.insert(self.waypoints,1,waypoint)
    end
    self.currentwp=self:GetWaypointIndex(current.uid)
    first=first or waypoint
    uid=waypoint.uid
  end

  self:_SetNavigationWaypoint(first or target)
  self.LastPathfindingResult=report
  self.ispathfinding=#path>0

  -- An empty path is a successful direct connection; submit the route even when no points were added.
  self:__UpdateRoute(-0.01)

  if self.verbose>=10 then
    self.pathfindingDebugSearch=astar
    astar:DrawGrid(path)
  end

  return true
end

--- Check each live ship's hull and a short distance along its current heading.
-- Independent of waypoint geometry and active during turns. This is a sampled emergency check,
-- not a prediction of the next turning arc or a calibrated DCS braking model.
-- @param #NAVYGROUP self
-- @return #boolean True when the sampled hull and lookahead meet the minimum depth.
-- @return #string Failure reason, or nil.
-- @return Core.Pathline#PATHLINE.DepthReport Failed sample with hull/heading context, or a clear report.
function NAVYGROUP:_CheckNavigationNearfield()

  local function checkShip(position, heading, speed, element)
    local box=element and element.descriptors and element.descriptors.box
    local stern,bow,left,right

    if box then
      -- The DCS object origin need not be the center of its hull. Retain asymmetric extents.
      stern,bow,left,right=box.min.x,box.max.x,box.min.z,box.max.z
    else
      -- Late activation or missing model dimensions: use cached sizes, then modest fallbacks.
      local length=element and element.length or 0
      local width=element and element.width or 0
      if length<=0 then length=100 end
      if width<=0 then width=30 end
      stern,bow,left,right=-length/2,length/2,-width/2,width/2
    end

    speed=math.max(0,speed)
    local ahead=math.max(50,speed*10)
    local angle=math.rad(heading)
    local ux,uz=math.cos(angle),math.sin(angle)
    local first,last=stern-10,bow+ahead
    local low,high=left-10,right+10
    local intervals=math.max(2,2*math.ceil((high-low)/20))
    local blocked

    -- Parallel profiles at most 10 m apart cover the interior as well as the hull edges.
    -- This physical footprint is independent of an explicitly narrower A* corridor.
    for i=0,intervals do
      local offset=low+(high-low)*i/intervals
      local start={x=position.x+ux*first-uz*offset,z=position.z+uz*first+ux*offset}
      local goal={x=position.x+ux*last-uz*offset,z=position.z+uz*last+ux*offset}
      local clear,reason,report=PATHLINE.CheckDepth(start,goal,self.pathMinDepth or 20,0)

      if not clear then
        report.ProfileOffset=offset
        report.NavigationStage=report.Status=="unavailable" and "nearfield"
          or (report.ClearDistance+first<=bow and "ship_hull" or "ship_lookahead")
        report.CheckStart,report.CheckGoal=start,goal
        report.Nearfield={Unit=element and element.name or self.groupname,Position=position,Heading=heading,
          Speed=speed,Bow=bow,Stern=stern,Beam=right-left,Lookahead=ahead,
          ClearFromBow=math.max(0,report.ClearDistance+first-bow)}

        -- Unknown depth cannot establish a safe footprint. Otherwise report the closest threat.
        if report.Status=="unavailable" then return false,reason,report end
        if not blocked or report.ClearDistance<blocked.ClearDistance then blocked=report end
      end
    end

    if blocked then return false,blocked.Reason,blocked end
    return true
  end

  -- Formation members have their own position, heading and dimensions; the leader alone is insufficient.
  local checked=false
  for _,element in ipairs(self.elements or {}) do
    local unit=element.unit
    if unit and unit:IsAlive() then
      checked=true
      local clear,reason,report=checkShip(unit:GetVec3(),unit:GetHeading(),unit:GetVelocityMPS(),element)
      if not clear then return clear,reason,report end
    end
  end

  if not checked then
    local clear,reason,report=checkShip(self:GetVec3(),self:GetHeading(),self:GetVelocity(),nil)
    if not clear then return clear,reason,report end
  end

  return true,nil,{Status="clear",NavigationStage="nearfield",RequiredDepth=self.pathMinDepth or 20}
end

--- Resolve the total width used by all naval depth checks.
-- Uses cached element dimensions, including the widest ship in a group. Formation offsets are not included.
-- @param #NAVYGROUP self
-- @return #number Explicit corridor width, or ship width plus 10 meters of clearance on each side, in meters.
function NAVYGROUP:_GetPathfindingCorridorWidth()

  if self.pathCorridor~=nil then
    return self.pathCorridor
  end

  -- Resolve lazily: late-activated ships may not have dimensions when pathfinding is configured.
  -- Unknown dimensions use a 30-meter beam, giving a 50-meter corridor with the reserve.
  local beam=0

  for _,element in pairs(self.elements or {}) do
    local width=element.width

    if type(width)~="number" or not (width>0 and width<math.huge) then
      width=30
    end

    beam=math.max(beam,width)
  end

  if beam==0 then
    beam=30
  end

  return beam+20
end

--- Check a connection using the same terrain-profile depth rule as naval ASTAR.
-- Includes direct checks at the actual endpoints. No COORDINATE objects or geometric grid cells are constructed.
-- Checks the center and both corridor edges; areas between these profiles and turning arcs are not covered.
-- @param #NAVYGROUP self
-- @param Core.Vector#VECTOR Start Start position; also accepts Vec3 or COORDINATE.
-- @param Core.Vector#VECTOR Goal Goal position; also accepts Vec3 or COORDINATE.
-- @return #boolean True when the connection satisfies the configured minimum depth.
-- @return #string Failure reason, or nil when clear.
-- @return Core.Pathline#PATHLINE.DepthReport Detailed result with the first blocked distance.
function NAVYGROUP:_CheckPathDepth(Start, Goal)

  return PATHLINE.CheckDepth(Start,Goal,self.pathMinDepth or 20,self:_GetPathfindingCorridorWidth())
end

--- Update turning status from live headings sampled by the navigation timer.
-- Uses the existing sensitivity of two degrees per thirty seconds, scaled to the sample interval.
-- Does not modify the position/orientation history maintained by the general status update.
-- @param #NAVYGROUP self
function NAVYGROUP:_CheckTurning()

  if not self:IsAlive() then
    self.turningHeading=nil
    self.turningTime=nil
    self.turning=false
    return
  end

  local heading=self:GetHeading()
  if not heading then
    return
  end

  local now=timer.getTime()
  local previous=self.turningHeading
  local elapsed=self.turningTime and now-self.turningTime or 0
  self.turningHeading=heading
  self.turningTime=now

  if previous==nil or elapsed<=0 then
    return
  end

  -- The signed difference wraps at north, so 359 -> 1 degrees is a two-degree turn.
  local delta=math.abs((heading-previous+180)%360-180)
  local turning=delta>=2*elapsed/30

  if self.turning and not turning then
    self:TurningStopped()
  elseif turning and not self.turning then
    self:TurningStarted()
  end

  self.turning=turning
end

--- On after "TurningStarted" event.
-- @param #NAVYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function NAVYGROUP:onafterTurningStarted(From, Event, To)
  self.turning=true
end

--- On after "TurningStarted" event.
-- @param #NAVYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function NAVYGROUP:onafterTurningStopped(From, Event, To)
  self.turning=false
  
  if self:IsSteamingIntoWind() then
    self:TurnedIntoWind()
  end
  
end

--- On after "CollisionWarning" event.
-- @param #NAVYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number Distance Estimated clear prefix in meters before the detected obstacle.
function NAVYGROUP:onafterCollisionWarning(From, Event, To, Distance)
  self:T(self.lid..string.format("Navigation obstacle ahead; checked clear distance %.0f meters", Distance or -1))
  self.collisionwarning=true
end

--- Clear a previous warning after a verified clear navigation check.
-- @param #NAVYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function NAVYGROUP:onafterClearAhead(From, Event, To)
  self.collisionwarning=false
end

--- Remove owned pathfinding drawings before the base class stops timers and event subscriptions.
function NAVYGROUP:onafterStop(From, Event, To)

  self:_ClearPathfindingDrawing()
  return OPSGROUP.onafterStop(self,From,Event,To)

end


--- Find the original route target beyond outstanding ASTAR detour points.
-- @param #NAVYGROUP self
-- @param #number First (Optional) First native waypoint index. Defaults to the currently commanded native destination.
-- @return Ops.OpsGroup#OPSGROUP.Waypoint Original target, or nil.
-- @return #table IDs of outstanding detour points before that target.
function NAVYGROUP:_GetPathfindingTarget(First)
  local pending={}
  local waypoint=not First and self:_GetNavigationWaypoint() or nil
  local index=First or (waypoint and self:GetWaypointIndex(waypoint.uid))
  for _=1,#self.waypoints do
    if not index then break end
    if index>#self.waypoints then
      if self.adinfinitum then index=1 else break end
    end
    local waypoint=self.waypoints[index]
    if not waypoint then break end
    if not waypoint.astar then return waypoint,pending end
    pending[#pending+1]=waypoint.uid
    index=index+1
  end
  return nil,pending
end

--- Remove this group's previous pathfinding overlays and cancel pending drawing batches.
-- Leaves other groups' drawings and unrelated map marks untouched.
-- @param #NAVYGROUP self
-- @return #NAVYGROUP self.
function NAVYGROUP:_ClearPathfindingDrawing()
  if self.pathfindingDebugSearch then
    self.pathfindingDebugSearch:ClearDrawing(GRID.Drawing.POLYGONS)
    self.pathfindingDebugSearch=nil
  end
  return self
end

--- Record a failed plan and stop without discarding the original route.
-- Uses an ordinary FullStop. Only a new movement command can resume the ship.
-- @param #NAVYGROUP self
-- @param #table Report Failed pathfinding result or unavailable depth measurement.
-- @return #boolean Always false.
function NAVYGROUP:_FailPathfinding(Report)

  self.LastPathfindingResult=Report
  self.ispathfinding=false
  self:_ClearPathfindingDrawing()
  if Report.DepthCheck then self:_LogNavigationDepthCheck(Report.DepthCheck,"stop") end
  self:E(self.lid.."Naval pathfinding failed: "..tostring(Report.StopReason).." ==> FullStop")
  self:FullStop()

  return false
end

--- Log the existing depth-check evidence without additional terrain queries.
-- NavigationStage identifies hull and heading checks when supplied.
-- @param #NAVYGROUP self
-- @param Core.Pathline#PATHLINE.DepthReport Report Failed depth check, optionally with navigation context.
-- @param #string Action Navigation response, such as stop.
function NAVYGROUP:_LogNavigationDepthCheck(Report, Action)

  local point=Report.Point or {}
  local position=Report.Nearfield and Report.Nearfield.Position or self:GetVec3() or {}

  -- Keep each line short: DCS truncates long diagnostics, including the coordinates we need most.
  self:I(self.lid..string.format(
    "Naval depth check: action=%s, stage=%s, status=%s, reason=%s, cause=%s, "..
    "depth=%s m, required_depth=%s m, surface=%s, profile_offset=%s m, location=%s, distance=%s m",
    tostring(Action),tostring(Report.NavigationStage),tostring(Report.Status),
    tostring(Report.Reason),tostring(Report.Cause),tostring(Report.Depth),tostring(Report.RequiredDepth),
    tostring(Report.SurfaceType),tostring(Report.ProfileOffset),tostring(Report.Location),tostring(Report.Distance)))
  self:I(self.lid..string.format(
    "Naval depth position: point=(%s,%s,%s), ship=(%s,%s,%s), heading=%s, turning=%s",
    tostring(point.x),tostring(point.y),tostring(point.z),tostring(position.x),tostring(position.y),tostring(position.z),
    tostring(Report.Nearfield and Report.Nearfield.Heading or self:GetHeading()),tostring(self:IsTurning())))

  if Report.CheckStart and Report.CheckGoal then
    self:I(self.lid..string.format("Naval depth segment: check_from=(%.1f, %.1f), check_to=(%.1f, %.1f)",
      Report.CheckStart.x,Report.CheckStart.z,Report.CheckGoal.x,Report.CheckGoal.z))
  end

  local near=Report.Nearfield
  if near then
    self:I(self.lid..string.format("Naval nearfield: unit=%s, bow=%.1f m, stern=%.1f m, beam=%.1f m, "..
      "speed=%.2f m/s, lookahead=%.1f m, clear_from_bow=%.1f m",
      tostring(near.Unit),near.Bow,near.Stern,near.Beam,near.Speed,near.Lookahead,near.ClearFromBow))
  end
end

--- Check queued turns into wind.
-- @param #NAVYGROUP self
function NAVYGROUP:_CheckTurnsIntoWind()

  -- Get current abs time.
  local time=timer.getAbsTime()

  if self.intowind then

    -- Check if time is over.
    if time>=self.intowind.Tstop then    
      self:TurnIntoWindOver(self.intowind)
    end
  
  else
  
    -- Get next window.
    local IntoWind=self:GetTurnIntoWindNext()

    -- Start turn into wind.
    if IntoWind then
      self:TurnIntoWind(IntoWind)
    end
    
  end
  
end

--- Get the next turn into wind window, which is not yet running.
-- @param #NAVYGROUP self
-- @return #NAVYGROUP.IntoWind Next into wind data. Could be `nil` if there is not next window.
function NAVYGROUP:GetTurnIntoWindNext()

  if #self.Qintowind>0 then

    -- Get current abs time.
    local time=timer.getAbsTime()
  
    -- Sort windows wrt to start time.
    table.sort(self.Qintowind, function(a, b) return a.Tstart<b.Tstart end)
  
    -- Loop over all slots.
    for _,_recovery in ipairs(self.Qintowind) do
      local recovery=_recovery --#NAVYGROUP.IntoWind
  
      if time>=recovery.Tstart and time<recovery.Tstop and not (recovery.Open or recovery.Over) then
        return recovery
      end
      
    end    
  end

  return nil
end

--- Get the turn into wind window, which is currently open. 
-- @param #NAVYGROUP self
-- @return #NAVYGROUP.IntoWind Current into wind data. Could be `nil` if there is no window currenly open.
function NAVYGROUP:GetTurnIntoWindCurrent()
  return self.intowind
end

--- Get wind direction and speed at current position.
-- @param #NAVYGROUP self
-- @param #number Altitude (Optional) Altitude in meters above main sea level at which the wind is calculated. Default 18 meters.
-- @return #number Direction the wind is blowing **from** in degrees.
-- @return #number Wind speed in m/s.
function NAVYGROUP:GetWind(Altitude)

  -- Current position of the carrier or input.
  local coord=self:GetCoordinate()

  -- Wind direction and speed. By default at 18 meters ASL.
  local Wdir, Wspeed=coord:GetWind(Altitude or 18)

  return Wdir, Wspeed
end

--- Get heading of group into the wind.
-- @param #NAVYGROUP self
-- @param #number Offset Offset angle in degrees, e.g. to account for an angled runway.
-- @param #number vdeck Desired wind speed on deck in Knots.
-- @return #number Carrier heading in degrees.
-- @return #number Carrier speed in knots.
function NAVYGROUP:GetHeadingIntoWind_old(Offset, vdeck)

  local function adjustDegreesForWindSpeed(windSpeed)
    local degreesAdjustment = 0
    -- the windspeeds are in m/s    
    -- +0 degrees at 15m/s = 37kts
    -- +0 degrees at 14m/s = 35kts
    -- +0 degrees at 13m/s = 33kts
    -- +4 degrees at 12m/s = 31kts
    -- +4 degrees at 11m/s = 29kts
    -- +4 degrees at 10m/s = 27kts
    -- +4 degrees at 9m/s = 27kts
    -- +4 degrees at 8m/s = 27kts
    -- +8 degrees at 7m/s = 27kts
    -- +8 degrees at 6m/s = 27kts
    -- +8 degrees at 5m/s = 26kts
    -- +20 degrees at 4m/s = 26kts
    -- +20 degrees at 3m/s = 26kts
    -- +30 degrees at 2m/s = 26kts 1s
  
    if windSpeed > 0 and windSpeed < 3 then
      degreesAdjustment = 30
    elseif windSpeed >= 3 and windSpeed < 5 then
      degreesAdjustment = 20
    elseif windSpeed >= 5 and windSpeed < 8 then
      degreesAdjustment = 8
    elseif windSpeed >= 8 and windSpeed < 13 then
      degreesAdjustment = 4
    elseif windSpeed >= 13 then
      degreesAdjustment = 0
    end
  
    return degreesAdjustment
  end

  Offset=Offset or 0

  -- Get direction the wind is blowing from. This is where we want to go.
  local windfrom, vwind=self:GetWind()

  -- Actually, we want the runway in the wind.
  local intowind = windfrom - Offset + adjustDegreesForWindSpeed(vwind)

  -- If no wind, take current heading.
  if vwind<0.1 then
    intowind=self:GetHeading()
  end
  
  -- Adjust negative values.
  if intowind<0 then
    intowind=intowind+360
  end

  -- Speed of carrier in m/s but at least 4 knots.
  local vtot = math.max(vdeck-UTILS.MpsToKnots(vwind), 4)
  
  return intowind, vtot
end


--- Get heading of group into the wind. This minimizes the cross wind for an angled runway.
-- Implementation based on [Mags & Bami](https://magwo.github.io/carrier-cruise/) work.
-- @param #NAVYGROUP self
-- @param #number Offset Offset angle in degrees, e.g. to account for an angled runway.
-- @param #number vdeck Desired wind speed on deck in Knots.
-- @return #number Carrier heading in degrees.
-- @return #number Carrier speed in knots.
function NAVYGROUP:GetHeadingIntoWind_new(Offset, vdeck)

  -- Default offset angle.
  Offset=Offset or 0

  -- Get direction the wind is blowing from.
  local windfrom, vwind=self:GetWind(18)
  
  -- Convert wind speed to knots.
  vwind=UTILS.MpsToKnots(vwind)
  
  -- Wind to in knots.
  local windto=(windfrom+180)%360
  
  -- Offset angle in rad. We also define the rotation to be clock-wise, which requires a minus sign.
  local alpha=math.rad(-Offset)
  
  -- Ships min/max speed.
  local Vmin=4
  local Vmax=UTILS.KmphToKnots(self.speedMax)

  -- With no wind its direction is undefined. Keep the current heading and avoid division by zero.
  if vwind<1e-6 then
    return self:GetHeading()%360, math.max(Vmin,math.min(Vmax,vdeck))
  end

  -- An unangled deck requires no crosswind correction; the general formula is singular at zero offset.
  if math.abs(math.sin(alpha))<1e-12 and math.cos(alpha)>0 then
    return windfrom%360, math.max(Vmin,math.min(Vmax,vdeck-vwind))
  end
  
  -- In very light wind the requested crosswind correction can be unattainable.
  -- Saturate at the limiting angle instead of producing NaN from asin outside its domain.
  local function correction(value)
    return math.asin(math.max(-1,math.min(1,value)))
  end
  local sine=math.sin(alpha)
  local direction=sine<0 and -1 or 1
  local inverseC=math.abs(sine)
  

  -- Upper limit of desired speed due to max boat speed.
  local vdeckMax=vwind + math.cos(alpha) * Vmax
  
  -- Lower limit of desired speed due to min boat speed.
  local vdeckMin=vwind + math.cos(alpha) * Vmin
  
  
  -- Speed of ship so it matches the desired speed.
  local v=0
  
  -- Angle wrt. to wind TO-direction 
  local theta=0

  if vdeck>vdeckMax then
    -- Boat cannot go fast enough
    
    -- Set max speed.
    v=Vmax
    
    -- Calculate theta.
    theta = direction*(correction(v*inverseC/vwind)+correction(inverseC))
  
  elseif vdeck<vdeckMin then
    -- Boat cannot go slow enought
  
    -- Set min speed.
    v=Vmin
    
    -- Calculatge theta.
    theta = direction*(correction(v*inverseC/vwind)+correction(inverseC))
  
  elseif math.abs(vdeck*sine)>vwind then
    -- Too little wind
    
    -- Set theta to 90ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â°
    theta=direction*math.pi/2
    
    -- Set speed.
    v = math.sqrt(vdeck^2 - vwind^2)
  
  else
    -- Normal case
    theta = correction(vdeck * sine / vwind)
    v = vdeck * math.cos(alpha) - vwind * math.cos(theta)
  end
  
  
  -- Ship heading so cross wind is min for the given wind.
  local intowind = (540 + (windto + math.deg(theta) )) % 360
  
  -- Debug info.
  self:T(self.lid..string.format("Heading into Wind: vship=%.1f, vwind=%.1f, WindTo=%03.0fÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â°, Theta=%03.0fÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â°, Heading=%03.0f", v, vwind, windto, math.deg(theta), intowind))
  
  return intowind, v
end

--- Get heading of group into the wind. This minimizes the cross wind for an angled runway.
-- Implementation based on [Mags & Bami](https://magwo.github.io/carrier-cruise/) work.
-- @param #NAVYGROUP self
-- @param #number Offset Offset angle in degrees, e.g. to account for an angled runway.
-- @param #number vdeck Desired wind speed on deck in Knots.
-- @return #number Carrier heading in degrees.
-- @return #number Carrier speed in knots.
function NAVYGROUP:GetHeadingIntoWind(Offset, vdeck)

  if self.intowindold then
    --env.info("FF use OLD into wind")
    return self:GetHeadingIntoWind_old(Offset, vdeck)
  else
    --env.info("FF use NEW into wind")
    return self:GetHeadingIntoWind_new(Offset, vdeck)
  end

end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
