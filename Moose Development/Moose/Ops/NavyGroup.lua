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
-- @field #NAVYGROUP.IntoWind intowind Into wind info.
-- @field #table Qintowind Queue of "into wind" turns.
-- @field #number intowindcounter Counter of into wind IDs.
-- @field #number depth Ordered depth in meters.
-- @field #boolean collisionwarning If true, collition warning.
-- @field #boolean pathfindingOn If true, enable pathfining.
-- @field #number pathCorridor Path corrdidor width in meters.
-- @field #boolean ispathfinding If true, group is currently path finding.
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
-- @field #NAVYGROUP
NAVYGROUP = {
  ClassName       = "NAVYGROUP",
  turning         = false,
  intowind        = nil,
  intowindcounter = 0,
  Qintowind       = {},
  pathCorridor    = 400,
  engage          = {},  
}

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

--- Enable/disable pathfinding.
-- @param #NAVYGROUP self
-- @param #boolean Switch If true, enable pathfinding.
-- @param #number CorridorWidth Corridor with in meters. Default 400 m.
-- @return #NAVYGROUP self
function NAVYGROUP:SetPathfinding(Switch, CorridorWidth)
  self.pathfindingOn=Switch
  self.pathCorridor=CorridorWidth or 400
  return self
end

--- Enable pathfinding.
-- @param #NAVYGROUP self
-- @param #number CorridorWidth Corridor with in meters. Default 400 m.
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
-- @param #number Radius Radius in meters. Default 100 m.
-- @param #number Nshots Number of shots to fire. Default 3.
-- @param #number WeaponType Type of weapon. Default auto.
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
-- @param Ops.OpsGroup#OPSGROUP.Waypoint Waypoint Where the task is executed. Default is next waypoint.
-- @param #number Radius Radius in meters. Default 100 m.
-- @param #number Nshots Number of shots to fire. Default 3.
-- @param #number WeaponType Type of weapon. Default auto.
-- @param #number Prio Priority of the task.
-- @param #number Duration Duration in seconds after which the task is cancelled. Default *never*.
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
-- @param #number WeaponExpend How much weapons does are used.
-- @param #number WeaponType Type of weapon. Default auto.
-- @param #string Clock Time when to start the attack.
-- @param #number Prio Priority of the task.
-- @return Ops.OpsGroup#OPSGROUP.Task The task data.
function NAVYGROUP:AddTaskAttackGroup(TargetGroup, WeaponExpend, WeaponType, Clock, Prio)

  local DCStask=CONTROLLABLE.TaskAttackGroup(nil, TargetGroup, WeaponType, WeaponExpend, AttackQty, Direction, Altitude, AttackQtyLimit, GroupAttack)

  local task=self:AddTask(DCStask, Clock, nil, Prio)
  
  return task
end

--- Create a turn into wind window. Note that this is not executed as it not added to the queue.
-- @param #NAVYGROUP self
-- @param #string starttime Start time, e.g. "8:00" for eight o'clock. Default now.
-- @param #string stoptime Stop time, e.g. "9:00" for nine o'clock. Default 90 minutes after start time.
-- @param #number speed Speed in knots during turn into wind leg.
-- @param #boolean uturn If true (or nil), carrier wil perform a U-turn and go back to where it came from before resuming its route to the next waypoint. If false, it will go directly to the next waypoint.
-- @param #number offset Offset angle in degrees, e.g. to account for an angled runway. Default 0 deg.
-- @return #NAVYGROUP.IntoWind Recovery window.
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
    return self
  end
  if Tstop<=Tnow then
    self:E(string.format("WARNING: Into wind stop time %s already over. Tnow=%s! Input rejected.", UTILS.SecondsToClock(Tstop), UTILS.SecondsToClock(Tnow)))
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

--- Add a time window, where the groups steams into the wind.
-- @param #NAVYGROUP self
-- @param #string starttime Start time, e.g. "8:00" for eight o'clock. Default now.
-- @param #string stoptime Stop time, e.g. "9:00" for nine o'clock. Default 90 minutes after start time.
-- @param #number speed Wind speed on deck in knots during turn into wind leg. Default 20 knots.
-- @param #boolean uturn If `true` (or `nil`), carrier wil perform a U-turn and go back to where it came from before resuming its route to the next waypoint. If false, it will go directly to the next waypoint.
-- @param #number offset Offset angle clock-wise in degrees, *e.g.* to account for an angled runway. Default 0 deg. Use around -9.1° for US carriers.
-- @return #NAVYGROUP.IntoWind Turn into window data table.
function NAVYGROUP:AddTurnIntoWind(starttime, stoptime, speed, uturn, offset)

  local recovery=self:_CreateTurnIntoWind(starttime, stoptime, speed, uturn, offset)
  
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
-- @param #number Duration Duration in seconds. Default 300 sec.
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
    return
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
  
  -- Free path.
  local freepath=0
  
  -- Check if group is exists and is active.
  if alive then

    -- Update last known position, orientation, velocity.
    self:_UpdatePosition()
  
    -- Check if group has detected any units.
    self:_CheckDetectedUnits()
    
    -- Check if group started or stopped turning.
    self:_CheckTurning()
  
    -- Distance to next Waypoint.  
    local disttoWP=math.min(self:GetDistanceToWaypoint(), UTILS.NMToMeters(10))
    freepath=disttoWP
    
    -- Only check if not currently turning.
    if not self:IsTurning() then
    
      -- Check free path ahead.
      freepath=self:_CheckFreePath(freepath, 100)
      
      if disttoWP>1 and freepath<disttoWP then
      
        if not self.collisionwarning then
          -- Issue a collision warning event.
          self:CollisionWarning(freepath)
        end
    
        if self.pathfindingOn and not self.ispathfinding then
          self.ispathfinding=self:_FindPathToNextWaypoint()
        end
        
      end
      
    end
    
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
      local text=string.format("%s [%d/%d]: ROE/AS=%d/%d | T/M=%d/%d | Wp=%d[%d]-->%d[%d]/%d [%s] | Life=%.1f | v=%.1f (%d) | Hdg=%03d | Ammo=%d | Detect=%s | Cargo=%.1f | Turn=%s Collision=%d IntoWind=%s",
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

--- On before "UpdateRoute" event.
-- @param #NAVYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number n Next waypoint index. Default is the one coming after that one that has been passed last.
-- @param #number N Waypoint  Max waypoint index to be included in the route. Default is the final waypoint.
-- @param #number Speed Speed in knots to the next waypoint.
-- @param #number Depth Depth in meters to the next waypoint.
function NAVYGROUP:onbeforeUpdateRoute(From, Event, To, n, Speed, Depth)

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
    self:__UpdateRoute(trepeat, n)
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

  -- Update route from this waypoint number onwards.
  n=n or self:GetWaypointIndexNext()
  
  -- Max index.
  N=N or #self.waypoints  
  N=math.min(N, #self.waypoints)
  

  -- Waypoints.
  local waypoints={}
  
  for i=n, N do
  
    -- Waypoint.
    local wp=UTILS.DeepCopy(self.waypoints[i])  --Ops.OpsGroup#OPSGROUP.Waypoint
    
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
    self:Route(waypoints)
    
  else
  
    ---
    -- Passed final WP ==> Full Stop
    ---
  
    self:E(self.lid..string.format("WARNING: Passed final WP ==> Full Stop!"))
    self:FullStop()
    
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
  
  -- Add waypoint after current.
  local wp=self:AddWaypoint(Coordinate, Speed, uid, Depth, true)
  
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
    
    -- Remove additional waypoint.
    self:RemoveWaypointByID(self.intowind.waypoint.uid)
  
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
  self.collisionwarning=false
  
  if self:IsSteamingIntoWind() then
    self:TurnedIntoWind()
  end
  
end

--- On after "CollisionWarning" event.
-- @param #NAVYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number Distance Distance in meters where obstacle was detected.
function NAVYGROUP:onafterCollisionWarning(From, Event, To, Distance)
  self:T(self.lid..string.format("Iceberg ahead in %d meters!", Distance or -1))
  self.collisionwarning=true
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
  self.engage.Waypoint=self:AddWaypoint(intercoord, Speed, uid, Depth, true)
    
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
        self:RemoveWaypointByID(self.engage.Waypoint.uid)
        
        local intercoord=self:GetCoordinate():GetIntermediateCoordinate(self.engage.Coordinate, 0.8)
    
          -- Add waypoint after current.
        self.engage.Waypoint=self:AddWaypoint(intercoord, self.engage.Speed, uid, self.engage.Depth, true)
      
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
    self:RemoveWaypointByID(self.engage.Waypoint.uid)
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
-- @param #number Formation Formation of the group.
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
      local wp=self:AddWaypoint(Coordinate, nil, uid, Formation, true)
      
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

--- Add an a waypoint to the route.
-- @param #NAVYGROUP self
-- @param Core.Point#COORDINATE Coordinate The coordinate of the waypoint. Use `COORDINATE:SetAltitude()` to define the altitude.
-- @param #number Speed Speed in knots. Default is default cruise speed or 70% of max speed.
-- @param #number AfterWaypointWithID Insert waypoint after waypoint given ID. Default is to insert as last waypoint.
-- @param #number Depth Depth at waypoint in feet. Only for submarines.
-- @param #boolean Updateroute If true or nil, call UpdateRoute. If false, no call.
-- @return Ops.OpsGroup#OPSGROUP.Waypoint Waypoint table.
function NAVYGROUP:AddWaypoint(Coordinate, Speed, AfterWaypointWithID, Depth, Updateroute)

  -- Create coordinate.
  local coordinate=self:_CoordinateFromObject(Coordinate)  
  
  -- Set waypoint index.
  local wpnumber=self:GetWaypointIndexAfterID(AfterWaypointWithID)

  -- Speed in knots.
  Speed=Speed or self:GetSpeedCruise()

  -- Create a Naval waypoint.
  local wp=coordinate:WaypointNaval(UTILS.KnotsToKmph(Speed), Depth)

  -- Create waypoint data table.
  local waypoint=self:_CreateWaypoint(wp)

  -- Set altitude.
  if Depth then
    waypoint.alt=UTILS.FeetToMeters(Depth)
  end

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
-- @param #table Template Template used to init the group. Default is `self.template`.
-- @param #number Delay Delay in seconds before group is initialized. Default `nil`, *i.e.* instantaneous. 
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

--- Check for possible collisions between two coordinates.
-- @param #NAVYGROUP self
-- @param #number DistanceMax Max distance in meters ahead to check. Default 5000.
-- @param #number dx
-- @return #number Free distance in meters.
function NAVYGROUP:_CheckFreePath(DistanceMax, dx)

  local distance=DistanceMax or 5000
  local dx=dx or 100

  -- If the group is turning, we cannot really tell anything about a possible collision.
  if self:IsTurning() then
    return distance
  end
  
  -- Offset above sea level.
  local offsetY=0.1
  
  -- Current bug on Caucasus. LoS returns false.
  if UTILS.GetDCSMap()==DCSMAP.Caucasus then
    offsetY=5.01
  end
  
  local vec3=self:GetVec3()
  vec3.y=offsetY
  
  -- Current heading.
  local heading=self:GetHeading()
  
  local function LoS(dist)
    local checkvec3=UTILS.VecTranslate(vec3, dist, heading)
    local los=land.isVisible(vec3, checkvec3)
    return los
  end

  -- First check if everything is clear.
  if LoS(DistanceMax) then
    return DistanceMax
  end
  
  local function check()
  
    local xmin=0
    local xmax=DistanceMax
    
    local Nmax=100
    local eps=100

    local N=1
    while N<=Nmax do
    
      local d=xmax-xmin
      local x=xmin+d/2
      
      local los=LoS(x)
      
      -- Debug message.
      self:T(self.lid..string.format("N=%d: xmin=%.1f xmax=%.1f x=%.1f d=%.3f los=%s", N, xmin, xmax, x, d, tostring(los)))
      
      if los and d<=eps then
        return x
      end
      
      if los then
        xmin=x
      else
        xmax=x
      end
    
      N=N+1
    end
  
    return 0
  end

  local _check=check()

  return _check
end

--- Check if group is turning.
-- @param #NAVYGROUP self
function NAVYGROUP:_CheckTurning()

  local unit=self.group:GetUnit(1)
  
  if unit and unit:IsAlive() then

    -- Current orientation of carrier.
    local vNew=self.orientX --unit:GetOrientationX()
  
    -- Last orientation from 30 seconds ago.
    local vLast=self.orientXLast
  
    -- We only need the X-Z plane.
    vNew.y=0 ; vLast.y=0
  
    -- Angle between current heading and last time we checked ~30 seconds ago.
    local deltaLast=math.deg(math.acos(UTILS.VecDot(vNew,vLast)/UTILS.VecNorm(vNew)/UTILS.VecNorm(vLast)))
  
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
    for _,_recovery in pairs(self.Qintowind) do
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
-- @param #number Altitude Altitude in meters above main sea level at which the wind is calculated. Default 18 meters.
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
  
  -- Constant.
  local C = math.sqrt(math.cos(alpha)^2 / math.sin(alpha)^2 + 1)
  

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
    theta = math.asin(v/(vwind*C)) - math.asin(-1/C)
  
  elseif vdeck<vdeckMin then
    -- Boat cannot go slow enought
  
    -- Set min speed.
    v=Vmin
    
    -- Calculatge theta.
    theta = math.asin(v/(vwind*C)) - math.asin(-1/C)
  
  elseif vdeck*math.sin(alpha)>vwind then
    -- Too little wind
    
    -- Set theta to 90°
    theta=math.pi/2
    
    -- Set speed.
    v = math.sqrt(vdeck^2 - vwind^2)
  
  else
    -- Normal case
    theta = math.asin(vdeck * math.sin(alpha) / vwind)
    v = vdeck * math.cos(alpha) - vwind * math.cos(theta)
  end
  
  
  -- Ship heading so cross wind is min for the given wind.
  local intowind = (540 + (windto + math.deg(theta) )) % 360
  
  -- Debug info.
  self:T(self.lid..string.format("Heading into Wind: vship=%.1f, vwind=%.1f, WindTo=%03d°, Theta=%03d°, Heading=%03d", v, vwind, windto, theta, intowind))
  
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


--- Find free path to next waypoint.
-- @param #NAVYGROUP self
-- @return #boolean If true, a path was found.
function NAVYGROUP:_FindPathToNextWaypoint()
  self:T3(self.lid.."Path finding")
  
  --TODO: Do not create a new ASTAR object each time this function is called but make it self.astar and reuse. Should be better for performance.

  -- Pathfinding A*
  local astar=ASTAR:New()
  
  -- Current positon of the group.
  local position=self:GetCoordinate()
  
  -- Next waypoint.
  local wpnext=self:GetWaypointNext()
  
  -- No next waypoint.
  if wpnext==nil then
    return
  end
  
  -- Next waypoint coordinate.
  local nextwp=wpnext.coordinate
  
  -- If we are currently turning into the wind...
  if wpnext.intowind then
    local hdg=self:GetHeading()
    nextwp=position:Translate(UTILS.NMToMeters(20), hdg, true)
  end
  
  local speed=UTILS.MpsToKnots(wpnext.speed)

  -- Set start coordinate.    
  astar:SetStartCoordinate(position)
  
  -- Set end coordinate.
  astar:SetEndCoordinate(nextwp)

  -- Distance to next waypoint.
  local dist=position:Get2DDistance(nextwp)
  
  -- Check distance >= 5 meters.
  if dist<5 then
    return
  end
  
  local boxwidth=dist*2
  local spacex=dist*0.1
  local delta=dist/10
  
  -- Create a grid of nodes. We only want nodes of surface type water.
  astar:CreateGrid({land.SurfaceType.WATER}, boxwidth, spacex, delta, delta, self.verbose>10)
  
  -- Valid neighbour nodes need to have line of sight.
  astar:SetValidNeighbourLoS(self.pathCorridor)
  
  --- Function to find a path and add waypoints to the group.
  local function findpath()
  
    -- Calculate path from start to end node.
    local path=astar:GetPath(true, true)
    
    if path then

      -- Loop over nodes in found path.
      local uid=self:GetWaypointCurrent().uid -- ID of current waypoint.
      
      for i,_node in ipairs(path) do
        local node=_node --Core.Astar#ASTAR.Node
          
        -- Add waypoints along detour path to next waypoint.
        local wp=self:AddWaypoint(node.coordinate, speed, uid)
        wp.astar=true
        
        -- Update id so the next wp is added after this one.
        uid=wp.uid

        -- Debug: smoke and mark path.
        if self.verbose>=10 then
          node.coordinate:MarkToAll(string.format("Path node #%d", i))
        end
        
      end
      
      return #path>0 
    else
      return false
    end
    
  end

  -- Return if path was found.
  return findpath()
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
