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
-- @field #NAVYGROUP.LocalNavigation localNavigation Installed local route, persistent ASTAR and owned cooperative job; independent of mission waypoints.
-- @field #number localNavigationTaskUID Completed local destination whose waypoint tasks must finish before route submission.
-- @field #NAVYGROUP.NavigationCommand navigationCommand Destination shared by native routing, collision checks and both search modes.
-- @field Core.Timer#TIMER timerNavigation Independent timer for local route checks.
-- @field Core.Pathline#PATHLINE.DepthReport LastNavigationCheck Last local depth check; unavailable data is distinct from an obstacle.
-- @field #table pathfindingDiagnostics Optional per-group coarse planning measurements; use GetPathfindingDiagnostics() for a copy.
-- @field #table LastLocalPlanningReport Latest scalar job outcome, owned by this group; read-only. Includes phase, rejection and simulation/worker CPU seconds.
-- @field #table LastPathfindingResult Last expansion report or direct-path/failure status.
-- @field Core.Astar#ASTAR pathfindingDebugSearch Owner of this group's current search-grid overlay.
-- @field Core.Pathline#PATHLINE pathfindingDebugRoute Owner of this group's submitted LOCAL steering-route overlay.
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
-- SetPathfindingMode(NAVYGROUP.PathfindingMode.LOCAL) selects experimental rolling local navigation.
-- Normal route following continues until a detected obstacle enters the speed-based local planning horizon.
-- The 5 km warning remains active before then; selecting LOCAL alone does not search.
-- A cooperative ASTAR request explores a bounded local window and returns ranked alternatives.
-- NAVYGROUP prepares steering geometry in budgeted slices and submits only complete, freshly checked routes.
-- SetPathfindingWorkBudget() controls work/CPU per update and a finite job slice limit.
-- It continues to the next original waypoint, then returns to normal route following until another obstacle is found.
-- The next original waypoint provides a preferred direction; no complete route to it is required.
-- Local navigation may enter a dead end. Failure stops the group without retries or reverse recovery.
-- Actual position controls progress; early DCS callbacks cannot advance the local route.
-- Depth checks remain sampled straight corridors, not a model of the ship's swept turning area.
-- Start canal trials at a modest mission speed and use a single ship per group.
--
--     navy:SetPathfindingMinDepth(20)
--     navy:SetPathfindingMode(NAVYGROUP.PathfindingMode.LOCAL)
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
-- @field #string LOCAL After detecting an obstacle, follow bounded local sections to the next original waypoint.
---@enum NAVYGROUP.PathfindingMode
NAVYGROUP.PathfindingMode={WAYPOINT="waypoint",LOCAL="local"}

--- Native destination shared by both navigation modes.
-- Preserve GotoWaypoint across speed/depth updates, but release it when mission progress or the next route leg changes.
-- @type NAVYGROUP.NavigationCommand
-- @field #number TargetUID Commanded native waypoint UID.
-- @field #number SourceUID Current mission waypoint UID when the command was recorded.
-- @field #number NextUID Next mission waypoint UID at that time; inserting a newer Detour invalidates the old command.

--- Private local-navigation state. Native local points are not inserted into the mission waypoint list.
-- @type NAVYGROUP.LocalNavigation
-- @field #number TargetUID Original destination UID.
-- @field Ops.OpsGroup#OPSGROUP.Waypoint Target Original destination object.
-- @field Core.Vector#VECTOR TargetPosition Snapshot used to detect destination edits.
-- @field #table Path VECTOR positions of the installed local polyline, including its original start.
-- @field #table Distances Cumulative horizontal distances along Path in meters.
-- @field #number Segment Current contiguous path segment.
-- @field #number Progress Monotonic distance travelled along Path in meters.
-- @field #number Length Total path length in meters.
-- @field #number ExtensionAfter Minimum actual progress before requesting another continuation, in meters.
-- @field #number Speed Commanded speed in meters per second.
-- @field #number Alt Native route altitude in meters (negative for submerged travel).
-- @field #boolean GoalReached Whether the installed path ends at the original destination.
-- @field Core.Astar#ASTAR Search Persistent local planner owned by this navigation leg.
-- @field #table SearchSettings Configuration of the persistent planner.
-- @field #number Generation Invalidates unpublished work when navigation inputs change.
-- @field #table Job Cooperative planning job with copied inputs and geometry.
-- @field #table Pending Validated continuation awaiting a stable heading before submission.
-- @field #table ExtensionFailure Last failed continuation/replacement and whether replanning awaits the end of a turn.
-- @field #table SteeringFailures Rejected A* candidates from the latest local planning attempt.
-- @field #table TargetTurnCheck Last check of the turn required to resume ordinary routing.
-- @field #boolean NeedsSubmit Explicit speed/depth or route update awaiting a stable heading.
-- @field #table DeviationNotice Last reported segment/turn state while away from the planned line.
-- @field #table TargetCheckNotices Last logged target-horizon failures, by check stage.

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

  -- One caller timer advances cooperative planning; live hull checks remain two seconds apart
  -- and ordinary waypoint collision checks retain their ten-second cadence.
  self.timerNavigation=TIMER:New(self._CheckNavigation, self):Start(0.1, 0.1)

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

--- Snapshot of an explicitly enabled naval measurement interval.
-- @type NAVYGROUP.PathfindingDiagnostics
-- @field #boolean Enabled Whether the interval is recording; false retains its frozen values.
-- @field #number SearchAttempts Completed local requests or global expansion attempts, including normal no-path results.
-- @field #number ValidityRequests ASTAR validity lookups during recorded searches and steering preparation.
-- @field #number ValidityCacheHits Validity lookups served from cache.
-- @field #number CostRequests ASTAR cost lookups during recorded searches and steering preparation.
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
-- Measures navigation updates, cooperative local slices, waypoint planning and route updates. Nested work contributes
-- once to aggregate CPU/profile counts; per-operation timings are inclusive and must not be summed.
-- User callbacks executed in these scopes are included. These are CPU seconds, never FPS or simulation time.
-- ProfileQueries counts actual ASTAR/PATHLINE depth-profile calls, including failures, without terrain hooks.
-- PeakRetainedCells is the maximum observed sum of distinct grids owned by active planners/debug views plus
-- the search being measured, sampled after searches/scopes; it is not a heap or exact instantaneous peak.
-- RouteSubmissions counts issued Route calls, not observed controller acceptance or ship movement.
-- While enabled, LOCAL logs one compact outcome per submitted, failed or cancelled job; never per slice.
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
-- Interval metrics are logged only by LogPathfindingDiagnostics(); enabled LOCAL job outcomes log separately.
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
  local navigation=self.localNavigation
  if navigation then
    add(navigation.Search)
    local job=navigation.Job or navigation.Pending
    if job then add(job.ActiveSearch) end
  end
  local count=0
  for grid in pairs(grids) do count=count+grid:GetCellCount() end
  diagnostics.PeakRetainedCells=math.max(diagnostics.PeakRetainedCells,count)

end

--- Capture existing search counters before a local slice or global search attempt.
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

--- Enable/disable pathfinding.
-- Uses terrain profiles to check minimum water depth along the center and both edges of the corridor.
-- Failed searches stop the ship until a new movement command is issued; there is no automatic retry.
-- Search grids use GRID.Resolution.FINE with GRID.Width.NORMAL and GRID.Margin.NORMAL; no grid dimensions are required.
-- SetPathfindingMinDepth() configures depth separately. Profiles assume linear terrain between their points;
-- three parallel checks do not cover the entire corridor or simulate the ship's turning arc.
-- SetPathfindingPreferredDepth() optionally makes A* trade extra distance for deeper water in either search mode.
-- @param #NAVYGROUP self
-- @param #boolean Switch If true, enable pathfinding.
-- @param #number CorridorWidth (Optional) Total water corridor width in meters. Default: widest ship plus 10 m on each side; 50 m if dimensions are unavailable. Zero checks only the center line.
-- @return #NAVYGROUP self
function NAVYGROUP:SetPathfinding(Switch, CorridorWidth)

  assert(type(Switch)=="boolean", "NAVYGROUP: pathfinding switch must be a boolean")

  if CorridorWidth~=nil then
    assert(type(CorridorWidth)=="number" and CorridorWidth>=0 and CorridorWidth<math.huge,"NAVYGROUP: corridor width must be finite and non-negative")
  end

  local hadLocalRoute=self.localNavigation~=nil
  if hadLocalRoute then
    self:_ResetLocalNavigation()
  end

  self.pathfindingOn=Switch
  self.pathCorridor=CorridorWidth

  if not Switch then
    self:_ClearPathfindingDrawing()
  end

  if hadLocalRoute and self:_CanNavigate() then
    self:__UpdateRoute(0.01)
  end

  return self
end

--- Select the naval route-search strategy without starting or resuming movement.
-- LOCAL uses a speed-based sparse hex window with 50 m spacing, up to eight ASTAR frontier alternatives,
-- cooperative work limits and the configured cell budget. It does not automatically fall back to global search.
-- SetPathfindingOn() enables the selected strategy. Both modes search only after an obstacle is detected.
-- Changing the strategy invalidates local plans and drawings;
-- the next permitted route update or navigation tick uses the new strategy. Holding remains authoritative.
-- @param #NAVYGROUP self
-- @param #string Mode (Optional) NAVYGROUP.PathfindingMode.WAYPOINT (default) or NAVYGROUP.PathfindingMode.LOCAL.
-- @return #NAVYGROUP self.
function NAVYGROUP:SetPathfindingMode(Mode)

  if Mode==nil then Mode=NAVYGROUP.PathfindingMode.WAYPOINT end
  assert(Mode==NAVYGROUP.PathfindingMode.WAYPOINT or Mode==NAVYGROUP.PathfindingMode.LOCAL,
    "NAVYGROUP: unknown pathfinding mode")

  if self.pathfindingMode==Mode then return self end

  local hadLocalRoute=self.localNavigation~=nil
  self:_ResetLocalNavigation()
  self.pathfindingMode=Mode
  if hadLocalRoute and self:_CanNavigate() then
    self:__UpdateRoute(0.01)
  end
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
-- Invalidates unpublished work. Fresh safety checks use the new depth during turns too; stopped ships remain stopped.
-- @param #NAVYGROUP self
-- @param #number MinDepth (Optional) Positive finite minimum water depth in meters, inclusive; default 20.
-- @return #NAVYGROUP self.
function NAVYGROUP:SetPathfindingMinDepth(MinDepth)

  if MinDepth==nil then
    MinDepth=20
  end

  assert(type(MinDepth)=="number" and MinDepth>0 and MinDepth<math.huge,"NAVYGROUP: minimum depth must be finite and positive")

  if self.pathMinDepth~=MinDepth then
    self:_CancelLocalPlanning("depth_changed")
    if self.localNavigation then self.localNavigation.Search=nil self.localNavigation.SafetyTime=nil end
    self.pathMinDepth=MinDepth
  end

  return self
end

--- Prefer deeper water during path searches, without changing the collision threshold.
-- At PreferredDepth and deeper, A* uses ordinary distance costs. Towards the minimum depth,
-- a quadratic penalty increases the cost up to 1 + Weight times the distance. Shallower water
-- remains blocked by SetPathfindingMinDepth(). A clear target horizon still resumes normal routing
-- using only the minimum depth. New searches use this setting; the installed route remains active.
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

  if self.pathPreferredDepth~=PreferredDepth or self.pathDepthWeight~=Weight then
    self.pathPreferredDepth=PreferredDepth
    self.pathDepthWeight=Weight

    -- Do not replace a route while the ship is turning; only discard plans not yet submitted.
    self:_CancelLocalPlanning("cost_changed")
    if self.localNavigation then self.localNavigation.Search=nil end
  end

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
  self:_CancelLocalPlanning("grid_changed")
  if self.localNavigation then self.localNavigation.Search=nil end
  self.pathMaxCells=config.MaxCells
  self.pathGrowthFactor=config.Expansion.GrowthFactor
  self.pathMaxAttempts=config.Expansion.MaxAttempts
  return self
end



--- Configure cooperative LOCAL planning work. No timer or movement is started.
-- @param #NAVYGROUP self
-- @param #number MaxWork Work items per update (default 512); also bounds work without a CPU clock.
-- @param #number MaxSeconds CPU seconds per update (default 0.005). Individual terrain calls cannot be interrupted.
-- @param #number MaxSlices Maximum updates per planning job (default 2000).
-- @return #NAVYGROUP self
function NAVYGROUP:SetPathfindingWorkBudget(MaxWork, MaxSeconds, MaxSlices)

  if MaxWork==nil then MaxWork=512 end
  if MaxSeconds==nil then MaxSeconds=0.005 end
  if MaxSlices==nil then MaxSlices=2000 end
  assert(type(MaxWork)=="number" and MaxWork>=1 and MaxWork<math.huge and MaxWork==math.floor(MaxWork),
    "NAVYGROUP: MaxWork must be a positive integer")
  assert(type(MaxSeconds)=="number" and MaxSeconds>0 and MaxSeconds<math.huge,
    "NAVYGROUP: MaxSeconds must be finite and positive")
  assert(type(MaxSlices)=="number" and MaxSlices>=1 and MaxSlices<math.huge and MaxSlices==math.floor(MaxSlices),
    "NAVYGROUP: MaxSlices must be a positive integer")
  self.pathWorkItems,self.pathWorkSeconds,self.pathWorkSlices=MaxWork,MaxSeconds,MaxSlices
  self:_CancelLocalPlanning("budget_changed")
  return self

end

--- Cancel unpublished work while retaining the installed route for fresh safety checks.
function NAVYGROUP:_CancelLocalPlanning(Reason)

  local navigation=self.localNavigation
  if not navigation then return end
  navigation.Generation=(navigation.Generation or 0)+1
  local job=navigation.Job or navigation.Pending
  if job then self:_RecordLocalPlanningOutcome(job,Reason) end
  if job and job.ActiveSearch then job.ActiveSearch:CancelSearch() end
  if navigation.Search then navigation.Search:CancelSearch() end
  navigation.Job=nil
  navigation.Pending=nil
  navigation.CancelReason=Reason

end

--- Reserve a fixed speed bound for one job, including small measured-speed fluctuations.
-- Add five percent or 0.5 m/s, whichever is greater. Proposed steering geometry uses this bound;
-- the commanded route speed and the observed-speed stopping checks stay unchanged.
function NAVYGROUP:_GetLocalPlanningSpeed(Speed)

  local speed=math.max(Speed or 0,self:GetVelocity() or 0)
  return speed+math.max(0.5,speed*0.05)

end

--- Retain one scalar outcome before a job is discarded; never retain its coroutine or graph.
-- Opt-in diagnostics log only job outcomes, not every slice. CPU covers worker resumes only.
function NAVYGROUP:_RecordLocalPlanningOutcome(Job, Reason)

  if Job.Outcome then return Job.Outcome end
  local cpuSeconds=Job.CPUSeconds
  if cpuSeconds and self._activeLocalPlanning==Job and Job.ResumeStarted then
    cpuSeconds=cpuSeconds+math.max(0,Job.Clock()-Job.ResumeStarted)
  end
  local report={JobID=Job.ID,Reason=Reason,Phase=Job.Phase,Requests=Job.Requests or 0,
    Slices=Job.Slices or 0,WorkItems=Job.WorkItems or 0,Candidate=Job.Candidate,
    Extension=Job.Extension,LastRejection=Job.LastRejection,
    SearchReason=Job.RequestReport and Job.RequestReport.StopReason,
    SpeedBound=Job.Speed,ActualSpeed=self:GetVelocity(),
    SimulationSeconds=math.max(0,timer.getTime()-Job.Started),CPUSeconds=cpuSeconds}
  Job.Outcome=report
  self.LastLocalPlanningReport=report
  if self.pathfindingDiagnostics and self.pathfindingDiagnostics.Enabled then
    local actualSpeed=report.ActualSpeed and string.format("%.6f",report.ActualSpeed) or "unavailable"
    self:I(self.lid..string.format("Local planning outcome: job=%d, reason=%s, phase=%s, requests=%d, candidate=%s, extension=%s",
      report.JobID,tostring(Reason),tostring(report.Phase),report.Requests,
      tostring(report.Candidate),tostring(report.Extension)))
    self:I(self.lid..string.format("Local planning work: job=%d, slices=%d, work=%d, sim_s=%.3f, cpu_s=%s",
      report.JobID,report.Slices,report.WorkItems,report.SimulationSeconds,tostring(report.CPUSeconds)))
    self:I(self.lid..string.format("Local planning inputs: job=%d, speed_bound=%.6f m/s, actual=%s m/s, search=%s, rejected=%s",
      report.JobID,report.SpeedBound,actualSpeed,tostring(report.SearchReason),tostring(report.LastRejection)))
  end
  return report

end

--- Identify all mutable inputs used by an unpublished naval plan.
function NAVYGROUP:_LocalPlanningSignature(Speed, Alt)

  return table.concat({tostring(self.pathMinDepth),tostring(self:_GetPathfindingCorridorWidth()),
    tostring(self.pathPreferredDepth),tostring(self.pathDepthWeight),tostring(self.pathMaxCells),
    tostring(Speed),tostring(Alt)}, ":")

end

--- Snapshot the installed route and movement authority before calling mission callbacks.
-- Copy target coordinates so in-place waypoint edits cannot validate an obsolete clearance result.
function NAVYGROUP:_LocalNavigationSnapshot()

  local navigation=self.localNavigation
  if not navigation then return nil end
  local target=navigation.TargetPosition
  return {Navigation=navigation,Generation=navigation.Generation,Command=self.navigationCommand,
    Target=navigation.Target,TargetUID=navigation.TargetUID,TargetX=target.x,TargetY=target.y,TargetZ=target.z,
    Path=navigation.Path,RouteID=navigation.RouteID,
    Speed=math.max(navigation.Speed,self:GetVelocity() or 0),
    Signature=self:_LocalPlanningSignature(navigation.Speed,navigation.Alt)}

end

--- Verify that a mission callback retained the route, destination, rules and movement authority.
function NAVYGROUP:_IsLocalNavigationSnapshotCurrent(Snapshot)

  local navigation=self.localNavigation
  if not Snapshot or navigation~=Snapshot.Navigation or not self:_CanNavigate()
    or not self.pathfindingOn or self.pathfindingMode~="local" then return false end
  if navigation.Generation~=Snapshot.Generation or self.navigationCommand~=Snapshot.Command
    or navigation.Target~=Snapshot.Target or navigation.TargetUID~=Snapshot.TargetUID
    or navigation.Path~=Snapshot.Path or navigation.RouteID~=Snapshot.RouteID then return false end

  local target=self:_GetPathfindingTarget()
  local position=navigation.TargetPosition
  return target==Snapshot.Target and target.coordinate.x==Snapshot.TargetX
    and target.coordinate.y==Snapshot.TargetY and target.coordinate.z==Snapshot.TargetZ
    and position.x==Snapshot.TargetX and position.y==Snapshot.TargetY and position.z==Snapshot.TargetZ
    and self.navigationCommand==Snapshot.Command
    and Snapshot.Speed>=math.max(navigation.Speed,self:GetVelocity() or 0)
    and self:_LocalPlanningSignature(navigation.Speed,navigation.Alt)==Snapshot.Signature

end

--- Authority and input checks apply before resumption and again before submission.
function NAVYGROUP:_IsLocalPlanningCurrent(Job)

  local navigation=self.localNavigation
  if not navigation or navigation~=Job.Navigation or navigation.Generation~=Job.Generation
    or not self.pathfindingOn or self.pathfindingMode~="local" or not self:_CanNavigate() then
    return false,"navigation_changed"
  end
  local target=self:_GetPathfindingTarget()
  local current=target==Job.Target and target.coordinate.x==Job.TargetPosition.x
    and target.coordinate.y==Job.TargetPosition.y and target.coordinate.z==Job.TargetPosition.z
    and self.navigationCommand==Job.Command and navigation.Path==Job.Route
    and navigation.RouteID==Job.RouteID
    and self:_LocalPlanningSignature(navigation.Speed,navigation.Alt)==Job.Signature
  if not current then return false,"navigation_changed" end
  if Job.Speed<math.max(navigation.Speed,self:GetVelocity() or 0) then return false,"speed_exceeded" end
  return true

end

--- Yield between bounded geometry operations, outside Lua 5.1 protected-call boundaries.
function NAVYGROUP:_LocalPlanningCheckpoint(Work)

  local job=self._activeLocalPlanning
  if not job or coroutine.running()~=job.Thread then return end
  if not self:_IsLocalPlanningCurrent(job) then coroutine.yield() end
  local clock=job.Clock
  if job.WorkRemaining<=0 or (clock and clock()>=job.Deadline) then coroutine.yield() end
  job.WorkRemaining=job.WorkRemaining-(Work or 1)
  job.WorkItems=job.WorkItems+(Work or 1)

end

--- Spend the remainder of this update on one public ASTAR slice.
function NAVYGROUP:_LocalPlanningSearchSlice(Search)

  self:_LocalPlanningCheckpoint(0)
  local job=assert(self._activeLocalPlanning)
  local work=math.max(1,job.WorkRemaining)
  local seconds=job.Clock and math.max(0.000001,job.Deadline-job.Clock()) or (self.pathWorkSeconds or 0.005)
  local before=self:_PathfindingSearchSnapshot(Search)
  local beforeWork=Search.LastSearchResult and Search.LastSearchResult.WorkItems or 0
  local path,report=Search:StepSearch(work,seconds)
  self:_RecordPathfindingSearch(Search,before,0)
  -- StepSearch owns its detailed count. Reserve the full allowance to prevent another search
  -- or geometry pass from sharing a slice whose callbacks may have exhausted the CPU budget.
  job.WorkRemaining=0
  job.WorkItems=job.WorkItems+math.max(0,(report.WorkItems or beforeWork)-beforeWork)
  if report.Status=="running" then coroutine.yield() end
  return path,report

end

--- Snapshot a retained approach and start work without mutating or submitting installed geometry.
function NAVYGROUP:_StartLocalPlanning(Position, Replacement)

  self:_CancelLocalPlanning("new_job")
  local navigation=self.localNavigation
  local planningSpeed=self:_GetLocalPlanningSpeed(navigation.Speed)
  local prefix={Position:Copy()}
  if navigation.Path and not Replacement then
    for i=navigation.Segment+1,#navigation.Path do prefix[#prefix+1]=navigation.Path[i]:Copy() end
  elseif not navigation.Path and not self:IsTurning() then
    -- While the first search runs, DCS still follows its native approach. Plan from a future
    -- point on that course so a short sideways exit does not fall behind the moving ship.
    -- The entire approach is depth-checked by the worker and again at publication; live
    -- approach checks and the stopping reserve remain authoritative during preparation.
    local speed=math.max(navigation.Speed,self:GetVelocity() or 0)
    local approach=math.min(1000,math.max(400,speed*75))
    local distance=Position:GetDistance(navigation.TargetPosition,true)
    local course=Position:GetHeadingTo(navigation.TargetPosition)
    local turn=math.abs((course-self:GetHeading()+180)%360-180)
    if turn<=5 and distance>2*approach then
      local fraction=approach/distance
      prefix[#prefix+1]=VECTOR:New(Position.x+(navigation.TargetPosition.x-Position.x)*fraction,
        navigation.Alt,Position.z+(navigation.TargetPosition.z-Position.z)*fraction)
    end
  end
  self.localPlanningSequence=(self.localPlanningSequence or 0)+1
  local job={ID=self.localPlanningSequence,Phase="approach",Navigation=navigation,
    Generation=navigation.Generation,Position=Position:Copy(),
    Heading=self:GetHeading(),Speed=planningSpeed,Alt=navigation.Alt,Target=navigation.Target,
    TargetPosition=navigation.TargetPosition:Copy(),Prefix=prefix,Segment=navigation.Segment,
    Route=navigation.Path,RouteID=navigation.RouteID,Command=self.navigationCommand,
    Signature=self:_LocalPlanningSignature(navigation.Speed,navigation.Alt),Replacement=Replacement,
    InitialApproach=not navigation.Path and #prefix>1,
    Slices=0,WorkItems=0,Started=timer.getTime(),CPUSeconds=os and type(os.clock)=="function" and 0 or nil}
  job.Thread=coroutine.create(function() return self:_BuildLocalRoute(job) end)
  navigation.Job=job
  navigation.CancelReason=nil
  return job

end

--- Handle a finished failure while respecting the still-checked installed route.
function NAVYGROUP:_LocalPlanningFailed(Job, Reason)

  local navigation=self.localNavigation
  local outcome=self:_RecordLocalPlanningOutcome(Job,Reason)
  navigation.Job=nil
  navigation.Pending=nil
  navigation.SteeringFailures=Job.SteeringFailures
  self:T(self.lid..string.format("Local planning failed: reason=%s, requests=%d, slices=%d, replacement=%s",
    tostring(Reason),Job.Requests or 0,Job.Slices or 0,tostring(Job.Replacement)))
  for _,failure in ipairs(Job.SteeringFailures or {}) do self:_LogLocalSteeringFailure(failure) end
  if not navigation.Path then
    return self:_FailPathfinding({StopReason=Reason,Mode="local",Request=Job.RequestReport,Slices=Job.Slices,Planning=outcome})
  end
  local position=VECTOR:NewFromVec(self:GetVec3())
  local progress,remaining=self:_LocalRouteProgress(position)
  local speed=math.max(navigation.Speed,self:GetVelocity() or 0)
  local reserve=math.max(400,speed*60)+speed*10
  navigation.ExtensionFailure={Reason=Reason,Remaining=remaining,Reserve=reserve,
    AwaitingStraight=self:IsTurning(),Replacement=Job.Replacement}
  navigation.ExtensionAfter=progress+250
  if remaining<=reserve then
    return self:_FailPathfinding({StopReason="local_route_exhausted",Mode="local",
      Remaining=remaining,Reserve=reserve,ExtensionFailure=navigation.ExtensionFailure})
  end
  -- A failed future anchor may have a usable alternative from the actual ship. Try it once,
  -- when steering is stable; a failed replacement waits for actual movement before another job.
  if not Job.Replacement and not self:IsTurning() then self:_StartLocalPlanning(position,true) end
  return true

end

--- Advance one owned coroutine slice; measurement wraps resume, never a yielding Lua call.
function NAVYGROUP:_AdvanceLocalPlanning()

  local navigation=self.localNavigation
  local job=navigation and navigation.Job
  if not job then return end
  local current,staleReason=self:_IsLocalPlanningCurrent(job)
  if not current then
    self:_CancelLocalPlanning(staleReason)
    return
  end
  if job.Slices>=(self.pathWorkSlices or 2000) then
    if job.ActiveSearch then job.ActiveSearch:CancelSearch() end
    return self:_LocalPlanningFailed(job,"local_slice_limit")
  end
  job.Clock=os and type(os.clock)=="function" and os.clock or nil
  job.Deadline=job.Clock and job.Clock()+(self.pathWorkSeconds or 0.005) or nil
  job.WorkRemaining=self.pathWorkItems or 512
  job.Slices=job.Slices+1
  self._activeLocalPlanning=job
  local started=job.Clock and job.Clock() or nil
  job.ResumeStarted=started
  local ok,points,plan,reason=coroutine.resume(job.Thread)
  self._activeLocalPlanning=nil
  job.ResumeStarted=nil
  if started and job.CPUSeconds then
    job.CPUSeconds=job.CPUSeconds+math.max(0,job.Clock()-started)
  else
    job.CPUSeconds=nil
  end
  if not ok then
    self:_CancelLocalPlanning("planning_error")
    error(points,0)
  end
  current,staleReason=self:_IsLocalPlanningCurrent(job)
  if not current then
    self:_CancelLocalPlanning(staleReason)
    return
  end
  if coroutine.status(job.Thread)~="dead" then return true end
  navigation.Job=nil
  if not points then return self:_LocalPlanningFailed(job,reason or "no_local_path") end
  plan.Slices=job.Slices
  plan.WorkItems=job.WorkItems
  job.Points,job.Plan=points,plan
  job.Phase="ready"
  job.Thread=nil
  navigation.Pending=job
  return true

end

--- Reattach a completed result to actual progress, retaining every unpassed installed corner.
function NAVYGROUP:_CommitLocalPlanning(Position)

  local navigation=self.localNavigation
  local job=navigation and navigation.Pending
  if not job or self:IsTurning() then return false end
  local current,staleReason=self:_IsLocalPlanningCurrent(job)
  if not current then
    self:_CancelLocalPlanning(staleReason)
    return false
  end
  job.Phase="commit"
  -- Submission can follow a long preparation. Resolve the retained installed approach
  -- from this observation before mapping its unpassed points into the proposal.
  if navigation.Path then self:_LocalRouteProgress(Position) end
  local skipped=not job.Replacement and job.Segment and math.max(0,navigation.Segment-job.Segment) or 0
  local first=2+skipped
  if job.Replacement then
    -- An initial or replacement search can finish after the ship passed its first points.
    -- Advance only through consecutive legs whose forward projection remains near the line;
    -- never jump to an arbitrary nearby point farther along a winding proposal.
    local allowance=math.max(150,self:_GetPathfindingCorridorWidth())
    while first<#job.Points do
      local previous,point=job.Points[first-1],job.Points[first]
      local dx,dz=point.x-previous.x,point.z-previous.z
      local square=dx*dx+dz*dz
      local fraction=square>0 and ((Position.x-previous.x)*dx+(Position.z-previous.z)*dz)/square or 0
      local lateral=math.sqrt((Position.x-previous.x-fraction*dx)^2+(Position.z-previous.z-fraction*dz)^2)
      if fraction<1 or lateral>allowance then break end
      first=first+1
    end
  end
  local points={Position:Copy()}
  for i=first,#job.Points do points[#points+1]=job.Points[i]:Copy() end
  if #points<2 then return self:_LocalPlanningFailed(job,"planning_anchor_passed") end
  local outgoing=Position:GetHeadingTo(points[2])
  local angle=math.abs((outgoing-self:GetHeading()+180)%360-180)
  local clear,turnReport=self:_CheckLocalTurn(Position,self:GetHeading(),outgoing,job.Speed)
  current,staleReason=self:_IsLocalPlanningCurrent(job)
  if not current then
    self:_CancelLocalPlanning(staleReason)
    return false
  end
  if angle>75 or not clear then
    navigation.Pending=nil
    return self:_LocalPlanningFailed(job,angle>75 and "submission_turn_angle" or "submission_turn_clearance")
  end
  local length=Position:GetDistance(points[2],true)
  local minLeg=math.max(100,math.min(job.Speed*10,250))
  local shortGoal=job.Plan.GoalReached and #points==2
  local straightApproach=false
  if job.Replacement and #points>2 and angle<=5 then
    local nextHeading=points[2]:GetHeadingTo(points[3])
    straightApproach=math.abs((nextHeading-outgoing+180)%360-180)<=5
  end
  -- A short remainder of a straight approach needs no new manoeuvre. Keep its waypoint
  -- instead of replacing two valid legs with a shortcut longer than the steering limit.
  -- A rounded DCS turn can put the ship beside the original leg and slightly lengthen
  -- this new connector. Allow at most two ordinary legs; never rebuild an unbounded approach.
  local maximumLeg=1000
  if length>2*maximumLeg or (length<minLeg and not shortGoal and not straightApproach) then
    return self:_LocalPlanningFailed(job,"submission_leg_length")
  end
  -- Movement changes the incoming bearing at the first retained corner too. Its outgoing
  -- leg is unchanged, but its angle and swept allowance must be checked again.
  if #points>2 then
    local nextHeading=points[2]:GetHeadingTo(points[3])
    local cornerAngle=math.abs((nextHeading-outgoing+180)%360-180)
    local cornerClear=self:_CheckLocalTurn(points[2],outgoing,nextHeading,job.Speed)
    current,staleReason=self:_IsLocalPlanningCurrent(job)
    if not current then
      self:_CancelLocalPlanning(staleReason)
      return false
    end
    if cornerAngle>90 or not cornerClear then
      return self:_LocalPlanningFailed(job,cornerAngle>90 and "submission_corner_angle" or "submission_corner_clearance")
    end
    if cornerAngle>5 and not job.Plan.GoalReached then
      -- Reattachment can turn a formerly straight waypoint into a new corner. Its exit
      -- needs the same independent reserve as a turn discovered during preparation.
      local afterCorner=0
      for i=3,#points do afterCorner=afterCorner+points[i-1]:GetDistance(points[i],true) end
      local reserve=math.max(400,job.Speed*60)+job.Speed*10
      if afterCorner<=reserve then return self:_LocalPlanningFailed(job,"submission_turn_exit_too_short") end
    end
  end
  -- Check the real retained corner above before inserting a collinear midpoint. Both new
  -- segments are then freshly depth-checked and priced by the normal installation boundary.
  if length>maximumLeg then
    local target=points[2]
    local midpoint=VECTOR:New((Position.x+target.x)/2,job.Alt,(Position.z+target.z)/2)
    table.insert(points,2,midpoint)
  end
  local submitted=self:_InstallLocalRoute(points,job.Plan,Position)
  if submitted then self:_RecordLocalPlanningOutcome(job,"submitted") end
  return submitted

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

  -- A completed local leg may have queued waypoint tasks whose native startup callback is still pending.
  -- Ordinary route updates must not overwrite those tasks while waiting for them to start or finish.
  if self.localNavigationTaskUID then
    if not self:_CanNavigate() or self:CountTasksWaypoint(self.localNavigationTaskUID)>0 then return end
    self.localNavigationTaskUID=nil
  end

  -- Resolve the same destination for native routing, collision checks and both planners.
  -- A newer inserted waypoint invalidates a previous Goto, whereas speed/depth changes retain it.
  if n then self:_SetNavigationWaypoint(self.waypoints[n]) end
  local target=self:_GetNavigationWaypoint()
  n=target and self:GetWaypointIndex(target.uid) or self:GetWaypointIndexNext()

  -- Selecting LOCAL alone leaves the native route intact. Only an active avoidance route owns the local frontier.
  if self.pathfindingOn and self.pathfindingMode=="local" and self.localNavigation then
    self:_CheckLocalNavigation(true,Speed,Depth)
    return
  end

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

--- Release cooperative navigation before the base class stops its timers and event subscriptions.
function NAVYGROUP:onafterStop(From, Event, To)

  self:_ResetLocalNavigation()
  return OPSGROUP.onafterStop(self,From,Event,To)

end


--- On after "FullStop" event.
-- @param #NAVYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function NAVYGROUP:onafterFullStop(From, Event, To)
  self:T(self.lid.."Full stop ==> holding")

  -- This command replaces the native task as well as its route. A cancelled task-start callback
  -- must not keep a later explicit Cruise blocked behind the local startup guard.
  self.localNavigationTaskUID=nil
  self.navigationCommand=nil
  if self.localNavigation then
    self:_ResetLocalNavigation()
  end

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

--- Publish a local navigation result and maintain collision-warning transitions.
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

--- Record a native destination for both route-search modes.
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

--- Advance local planning every tenth of a second, with independent safety and ordinary-route cadences.
-- The short hull/heading check runs during turns too; it never starts a search.
-- The ordinary route check examines at most 5000 meters towards the next waypoint. In LOCAL mode a distant obstruction only
-- warns; planning starts when it reaches the speed-based local horizon. WAYPOINT searches start at once.
-- Failed planning stops the ship without automatic retries.
-- @param #NAVYGROUP self
function NAVYGROUP:_CheckNavigation()

  return self:_MeasurePathfinding("navigation_update",self._RunNavigationCheck)

end

--- Execute the existing navigation operation; measurements are owned by the public entry above.
function NAVYGROUP:_RunNavigationCheck()

  local now=timer.getTime()
  local safetyDue=not self.navigationSafetyTime or now-self.navigationSafetyTime>=2 or now<self.navigationSafetyTime
  if not self:_CanNavigate() then self:_CancelLocalPlanning("movement_authority_lost") end
  if safetyDue then
    self.navigationSafetyTime=now
    self:_CheckTurning()
  end

  -- Immediate clearance follows the actual hull and heading, not a possibly outdated waypoint.
  -- Do this before target release, local extension or the usual turn-related route-check bypass.
  if safetyDue and self.pathfindingOn and self:_CanNavigate() then
    local navigation,command=self.localNavigation,self.navigationCommand
    local snapshot=navigation and self:_LocalNavigationSnapshot() or nil
    local clear,reason,report=self:_CheckNavigationNearfield()
    self.LastNearfieldCheck=report
    report.Time=timer.getTime()

    if not clear then
      self:_UpdateNavigationWarning(report)

      -- A warning callback may hold, disable or replace navigation itself.
      if self.pathfindingOn and self:_CanNavigate() and self.localNavigation==navigation
        and self.navigationCommand==command and (not snapshot or self:_IsLocalNavigationSnapshotCurrent(snapshot)) then
        self:_FailPathfinding({StopReason=report.Status=="blocked" and "nearfield_blocked" or reason,
          DepthCheck=report,Mode=self.pathfindingMode})
      end
      return
    end
  end

  if self.pathfindingOn and self.pathfindingMode=="local" and self.localNavigation then
    local navigation=self.localNavigation
    if safetyDue and navigation.Path and self:_TryResumeWaypointRoute() then return end
    self:_CheckLocalNavigation()
    return
  end

  -- Ordinary collision/waypoint work retains its ten-second cadence.
  if self.navigationCheckTime and now>=self.navigationCheckTime and now-self.navigationCheckTime<10 then return end
  self.navigationCheckTime=now

  -- Once a local destination's tasks finish, resume the ordinary route exactly once. Tasks at later
  -- waypoints can keep OPSGROUP's general completion handler from issuing that route update itself.
  if self.localNavigationTaskUID then
    if not self:_CanNavigate() or self:CountTasksWaypoint(self.localNavigationTaskUID)>0 then return end
    self.localNavigationTaskUID=nil
    self:__UpdateRoute(0.01)
    return
  end

  if not self:_CanNavigate() or self:IsTurning() then
    return
  end

  local waypoint=self:_GetNavigationWaypoint()
  if not waypoint then
    return
  end
  local command=self.navigationCommand
  local mode=self.pathfindingMode
  local targetX,targetZ=waypoint.coordinate.x,waypoint.coordinate.z

  local position=VECTOR:NewFromVec(self:GetVec3())
  local clear,reason,report=self:_CheckNavigationAhead(position,waypoint)
  self:_UpdateNavigationWarning(report)

  -- Warning callbacks may disable pathfinding, stop the ship or change the route.
  if not self.pathfindingOn or not self:_CanNavigate() or self:_GetNavigationWaypoint()~=waypoint
    or self.navigationCommand~=command or self.pathfindingMode~=mode or self.localNavigation
    or waypoint.coordinate.x~=targetX or waypoint.coordinate.z~=targetZ then
    return
  end

  if report.Status=="unavailable" then
    -- Missing terrain data is not an obstacle that a larger grid can resolve.
    self:_FailPathfinding({StopReason=reason,Attempts={},DepthCheck=report})
  elseif not clear then
    if self.pathfindingMode=="local" then
      local searchDistance,ahead=self:_GetLocalNavigationHorizon(self.speedWp or waypoint.speed)
      report.LocalSearchDistance,report.LocalSearchAhead=searchDistance,ahead

      -- Warn early, but do not plan an empty approach while the obstruction is outside the grid.
      -- Recheck its current distance each tick, even when CollisionWarning is already active.
      if report.ClearDistance>searchDistance then return end

      self:T(self.lid..string.format("Local navigation activated: clear distance %.0f m, search trigger %.0f m, window %.0f m ahead",
        report.ClearDistance,searchDistance,ahead))

      -- Keep the submitted speed and depth when handing navigation to the local planner.
      self:_CheckLocalNavigation(true,nil,self.altWp and -self.altWp)
    else
      self:_FindPathToNextWaypoint()
    end
  end
end

--- Match the local search trigger and forward grid extent to the ship's speed.
-- Uses the greater of commanded and actual speed so acceleration or deceleration cannot shrink
-- the allowance prematurely. Add one ten-second check interval to the existing manoeuvring
-- allowance; this remains a planning margin, not a measured DCS turning radius or stopping distance.
-- @param #NAVYGROUP self
-- @param #number Speed (Optional) Commanded speed in m/s; defaults to the current waypoint/cruise speed.
-- @return #number Obstruction distance at which LOCAL activates, capped at the 5000 m warning horizon.
-- @return #number Forward grid extent, at least 3000 m and at least 500 m beyond the trigger.
function NAVYGROUP:_GetLocalNavigationHorizon(Speed)

  local speed=Speed or self.speedWp or 0
  if speed<=0 then speed=UTILS.KnotsToMps(self:GetSpeedCruise()) end
  speed=math.max(speed,self:GetVelocity() or 0)

  local reserve=math.max(400,speed*60)
  local searchDistance=math.min(5000,math.max(2000,reserve+1000)+speed*10)

  -- Grow in 500 m steps, keeping room beyond the first obstruction. Small speed changes should
  -- not constantly rebuild the grid, and even extreme speeds must keep the local search bounded.
  local ahead=math.max(3000,math.ceil((searchDistance+500)/500)*500)
  return searchDistance,ahead

end

--- Check the normal collision horizon towards an original waypoint.
-- Shared by ordinary route monitoring and the decision to leave local avoidance.
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

--- Explain why local navigation cannot yet connect to the original target.
-- Reuse the measured profile; repeated failures with the same cause are logged at most once a minute.
-- @param #NAVYGROUP self
-- @param Core.Pathline#PATHLINE.DepthReport Report Existing target-horizon check with its start and end.
-- @param #string Stage Either target_lookahead or target_turn.
function NAVYGROUP:_LogLocalTargetCheck(Report, Stage)

  local navigation=self.localNavigation
  navigation.TargetCheckNotices=navigation.TargetCheckNotices or {}
  local notices=navigation.TargetCheckNotices

  if Report.Status=="clear" then
    notices[Stage]=nil
    return
  end

  local previous=notices[Stage]
  local now=timer.getTime()
  if previous and now-previous.Time<60 and previous.Report.Status==Report.Status
    and previous.Report.Reason==Report.Reason and previous.Report.Cause==Report.Cause
    and previous.Report.RequiredDepth==Report.RequiredDepth and previous.Report.ProfileOffset==Report.ProfileOffset
    and previous.Report.Location==Report.Location then return end

  Report.NavigationStage=Stage
  Report.TargetUID=navigation.TargetUID
  notices[Stage]={Time=now,Report=Report}
  self:_LogNavigationDepthCheck(Report,"continue_local")
end

--- Leave local avoidance when the normal collision horizon towards the destination is clear.
-- This does not declare arrival or guarantee clearance beyond the horizon. Normal checks remain active.
-- @param #NAVYGROUP self
-- @return #boolean True when this tick was handled; false to continue local route maintenance.
function NAVYGROUP:_TryResumeWaypointRoute()

  if not self:_CanNavigate() or self:IsTurning() then return false end

  local navigation=self.localNavigation
  local target=self:_GetPathfindingTarget()
  local snapshot=self:_LocalNavigationSnapshot()
  if not self:_IsLocalNavigationSnapshotCurrent(snapshot) then return false end

  local position=VECTOR:NewFromVec(self:GetVec3())
  local arrival=math.max(50,math.min(150,navigation.Speed*10))

  -- A local route that has actually reached its goal still owns the normal arrival/task lifecycle.
  if navigation.GoalReached and position:GetDistance(navigation.TargetPosition,true)<=arrival then return false end

  local clear,reason,report,checkedGoal=self:_CheckNavigationAhead(position,target)
  report.NavigationStage="target_lookahead"
  report.TargetUID=navigation.TargetUID
  report.CheckStart,report.CheckGoal=position,checkedGoal
  if not clear and report.Status~="unavailable" then
    self:_LogLocalTargetCheck(report,"target_lookahead")
    return false
  end

  if clear and position:GetDistance(checkedGoal,true)>0.1 then
    -- Releasing the detour creates a new initial turn too. A free straight target profile alone
    -- must not bypass the corner allowance used when choosing local steering points.
    local speed=math.max(navigation.Speed,self:GetVelocity() or 0)
    local turnClear,turnReport=self:_CheckLocalTurn(position,self:GetHeading(),position:GetHeadingTo(checkedGoal),speed)
    navigation.TargetTurnCheck=turnReport
    if not turnClear then
      report=turnReport.DepthCheck
      report.NavigationStage="target_turn"
      report.TargetUID=navigation.TargetUID
      report.CheckStart,report.CheckGoal=position,checkedGoal
      if report.Status~="unavailable" then
        self:_LogLocalTargetCheck(report,"target_turn")
        return false
      end
      reason=report.Reason
    end
  end

  self:_UpdateNavigationWarning(report)

  -- ClearAhead callbacks can stop, retarget or disable navigation. Never overwrite their commands.
  if not self:_IsLocalNavigationSnapshotCurrent(snapshot) then return true end

  if report.Status=="unavailable" then
    self:_FailPathfinding({StopReason=reason,DepthCheck=report,Mode="local"})
    return true
  end

  -- Release the planner, pending continuation and drawing, but retain the original waypoint and tasks.
  -- The next timer tick uses ordinary collision checks and can activate a new detour if needed.
  self:_ResetLocalNavigation()
  self:T(self.lid..string.format("Local navigation finished: target UID %d, %.0f m towards target clear ==> ordinary route",
    target.uid,report.Distance))
  self:UpdateRoute(self:GetWaypointIndex(target.uid),nil,UTILS.MpsToKnots(navigation.Speed),-navigation.Alt)
  return true
end

--- Get the leg-owned ASTAR local planner, or an isolated speculative planner.
-- Probe requests never change the persistent planner's learned continuation costs.
-- @param #number Speed Planned speed in meters per second.
-- @param #boolean Probe (Optional) Create a fresh planner with learning disabled.
-- @return Core.Astar#ASTAR Configured planner with an owned sparse window.
function NAVYGROUP:_GetLocalSearch(Speed, Probe)

  local _,ahead=self:_GetLocalNavigationHorizon(Speed)
  local settings={Ahead=ahead,MinDepth=self.pathMinDepth or 20,CorridorWidth=self:_GetPathfindingCorridorWidth(),
    PreferredDepth=self.pathPreferredDepth,Weight=self.pathDepthWeight or 2,MaxCells=self.pathMaxCells or 5000}
  local navigation=self.localNavigation
  local old=navigation and navigation.SearchSettings
  local same=old and old.Ahead==settings.Ahead and old.MinDepth==settings.MinDepth
    and old.CorridorWidth==settings.CorridorWidth and old.PreferredDepth==settings.PreferredDepth
    and old.Weight==settings.Weight and old.MaxCells==settings.MaxCells

  if not Probe and same and navigation.Search then return navigation.Search end

  local search=ASTAR:New(GRID.Type.HEXAGON)
  search:GetGrid():SetResolution(50):SetMaxCells(settings.MaxCells)
  search:SetValidSurfaceTypes({land.SurfaceType.WATER,land.SurfaceType.SHALLOW_WATER})
  search:SetValidNeighbourDepth(settings.MinDepth,settings.CorridorWidth)
  search:SetCostDepth(settings.PreferredDepth,settings.Weight)
  search:SetLocalWindow(settings.Ahead,2000,1000)
  if Probe then search:SetLocalLearningLimit(0) end

  if navigation and not Probe then
    if navigation.Search then navigation.Search:CancelSearch() end
    navigation.Search, navigation.SearchSettings=search,settings
  end
  return search
end

--- Evaluate one nautical connection through the public ASTAR contract.
-- Checkpoints bound caller-owned geometry work as well as graph exploration.
function NAVYGROUP:_EvaluateLocalConnection(Search, Start, Goal)

  self:_LocalPlanningCheckpoint(1)
  local valid,cost,report=Search:EvaluateConnection(Start,Goal)
  local evidence=report.Depth or report
  evidence.Status,evidence.Reason=report.Status,report.Reason
  return valid,cost,evidence
end



--- Check a local manoeuvring allowance around a proposed corner.
-- DCS rounds waypoint turns. Sample the surrounding water, not only the two straight legs.
-- This is a conservative planning buffer, not a prediction of the ship's turning radius.
-- @param #NAVYGROUP self
-- @param Core.Vector#VECTOR Position Proposed corner or initial planning position.
-- @param #number Incoming Incoming heading in degrees.
-- @param #number Outgoing Outgoing heading in degrees.
-- @param #number Speed Planning speed in meters per second.
-- @param #table Cache (Optional) Results owned by this one planning attempt.
-- @return #boolean True when the sampled corner area meets the minimum depth.
-- @return #table Turn angle, allowance radius and failed DepthCheck, when applicable.
function NAVYGROUP:_CheckLocalTurn(Position, Incoming, Outgoing, Speed, Cache)

  local turn=math.abs((Outgoing-Incoming+180)%360-180)
  if turn<=5 then return true,{Turn=turn,Radius=0} end

  -- Ten seconds of travel gives faster ships more room. Small course corrections need less.
  -- Round upwards for cache reuse; the straight route corridor itself remains unchanged.
  local allowance=math.max(50,math.min(Speed*10,150))*math.min(1,turn/30)
  local radius=math.ceil(allowance/25)*25+self:_GetPathfindingCorridorWidth()/2
  local key=string.format("%.9f:%.9f:%.3f",Position.x,Position.z,radius)
  local result=Cache and Cache[key]

  if not result then
    result={Clear=true,Radius=radius}

    -- Parallel chords at most 25 m apart also sample the interior of the buffer.
    -- A few radial spokes or only the circumference could miss a small island between them.
    local intervals=math.ceil(2*radius/25)
    for i=0,intervals do
      self:_LocalPlanningCheckpoint(1)
      local offset=-radius+2*radius*i/intervals
      local halfLength=math.sqrt(math.max(0,radius*radius-offset*offset))
      local start={x=Position.x-halfLength,z=Position.z+offset}
      local goal={x=Position.x+halfLength,z=Position.z+offset}
      local clear,reason,report=PATHLINE.CheckDepth(start,goal,self.pathMinDepth or 20,0)

      if not clear then
        result.Clear=false
        result.DepthCheck=report
        break
      end
    end

    if Cache then Cache[key]=result end
  end

  return result.Clear,{Turn=turn,Radius=radius,DepthCheck=result.DepthCheck}
end

--- Try moving a planned corner outwards before rejecting its steering route.
-- A grid path often follows the inner bank. Moving its corner along the outward angle bisector
-- gives DCS room to round the turn, without enlarging every grid edge or changing mission speed.
-- @param #NAVYGROUP self
-- @param #table Previous Previous simplifier state with Position, Heading and Index.
-- @param Core.Vector#VECTOR Corner Proposed corner.
-- @param Core.Vector#VECTOR Next Following waypoint.
-- @param #number Speed Planning speed in meters per second.
-- @param #number MinLeg Minimum steering-leg length in meters.
-- @param #boolean ShortGoal Whether the outgoing leg may be shorter at the original destination.
-- @param #table Cache Turn checks owned by this planning attempt.
-- @return #table Adjusted Position, Heading, FirstCost and LastCost, or nil if no tested adjustment works.
function NAVYGROUP:_AdjustLocalTurn(Previous, Corner, Next, Speed, MinLeg, ShortGoal, Cache, Search)

  Search=Search or self:_GetLocalSearch(Speed)
  local incoming=math.rad(Previous.Position:GetHeadingTo(Corner))
  local outgoing=math.rad(Corner:GetHeadingTo(Next))
  local dx,dz=math.cos(incoming)-math.cos(outgoing),math.sin(incoming)-math.sin(outgoing)
  local length=math.sqrt(dx*dx+dz*dz)
  if length<0.001 then return nil end

  -- Six nearby alternatives bound the extra terrain work. All installed route points remain
  -- unchanged until a complete candidate has passed; the actual ship position is never moved.
  local best
  for offset=25,150,25 do
    self:_LocalPlanningCheckpoint(1)
    local point=VECTOR:New(Corner.x+offset*dx/length,Corner.y,Corner.z+offset*dz/length)
    local first=Previous.Position:GetDistance(point,true)
    local last=point:GetDistance(Next,true)
    local heading=Previous.Position:GetHeadingTo(point)
    local course=point:GetHeadingTo(Next)
    local previousTurn=math.abs((heading-Previous.Heading+180)%360-180)
    local turn=math.abs((course-heading+180)%360-180)

    if first>=MinLeg and first<=1000 and last>0.1 and last<=1000 and (last>=MinLeg or ShortGoal)
      and previousTurn<=(Previous.Index==0 and 75 or 90) and turn<=90 then
      local firstClear,firstCost=self:_EvaluateLocalConnection(Search,Previous.Position,point)
      local lastClear,lastCost=self:_EvaluateLocalConnection(Search,point,Next)
      local clear=firstClear and lastClear
      first,last=firstCost,lastCost

      -- Moving a corner changes the outgoing course at its predecessor as well.
      if clear and self:_CheckLocalTurn(Previous.Position,Previous.Heading,heading,Speed,Cache)
        and self:_CheckLocalTurn(point,heading,course,Speed,Cache) then
        -- Required manoeuvring room may cost more than the raw grid path. Price the actual
        -- detour and keep the cheapest safe correction; do not silently discard depth costs.
        if not best or first+last<best.FirstCost+best.LastCost then
          best={Position=point,Heading=heading,FirstCost=first,LastCost=last}
        end
      end
    end
  end

  return best
end

--- Log why an A* candidate could not become a usable waypoint route.
-- Split evidence into short lines so DCS does not truncate the failed constraint or depth sample.
-- Counts describe rejected shortcut attempts, not separate A* searches or obstacles.
-- @param #NAVYGROUP self
-- @param #table Report Simplifier diagnostics with Candidate, Reason, States, Backtracks, Rejections and Examples.
function NAVYGROUP:_LogLocalSteeringFailure(Report)

  self:I(self.lid..string.format("Local steering rejected: candidate=%s, pass=%d, reason=%s, nodes=%d, states=%d, backtracks=%d",
    tostring(Report.Candidate),Report.Pass or 1,Report.Reason,Report.Nodes,Report.States,Report.Backtracks))

  for _,cause in ipairs({"leg_too_short","leg_too_long","short_remainder","turn_angle","depth","depth_cost","turn_clearance"}) do
    local count=Report.Rejections[cause]
    if count then
      local example=Report.Examples[cause]
      self:I(self.lid..string.format("Local steering constraint: candidate=%s, cause=%s, count=%d, nodes=%d->%d, "..
        "from=(%.1f, %.1f), distance=%.1f m, turn=%.1f deg, limit=%s, cost=%s, replaced_cost=%s, radius=%s m",
        tostring(Report.Candidate),cause,count,example.From,example.To,example.Position.x,example.Position.z,
        example.Distance,example.Turn,tostring(example.Limit),tostring(example.Cost),
        tostring(example.ReplacedCost),tostring(example.Radius)))

      local depth=example.DepthCheck
      if depth then
        local point=depth.Point or {}
        self:I(self.lid..string.format("Local steering depth: candidate=%s, cause=%s, status=%s, reason=%s, "..
          "depth_cause=%s, depth=%s m, required=%s m, surface=%s, offset=%s m, point=(%s, %s)",
          tostring(Report.Candidate),cause,tostring(depth.Status),tostring(depth.Reason),tostring(depth.Cause),
          tostring(depth.Depth),tostring(depth.RequiredDepth),tostring(depth.SurfaceType),
          tostring(depth.ProfileOffset),tostring(point.x),tostring(point.z)))
      end
    end
  end
end

--- Simplify a local grid path into depth-checked steering points with room at corners.
-- Try the farthest usable waypoint first, but backtrack if it leaves no safe outgoing turn.
-- Explore at most 128 steering states per pass; failure is not proof that no navigable route exists.
-- Legs are limited to 1 km, the initial turn to 75 degrees and later turns to 90 degrees.
-- First retain depth costs. If cost rejections prevent a usable route, try once more without that
-- cost ceiling. Depth, geometry and turn checks remain mandatory and actual costs are returned.
-- @param #NAVYGROUP self
-- @param Core.Vector#VECTOR Start Actual ship position or future route anchor.
-- @param #number Heading Incoming heading in degrees.
-- @param #table Path Copied positions including the selected endpoint; an initial Start is ignored.
-- @param #boolean GoalReached Whether the endpoint is the original mission waypoint.
-- @param #number Speed Requested speed in meters per second.
-- @param #number Altitude Original waypoint altitude or submarine depth.
-- @param Core.Astar#ASTAR Search (Optional) Planner supplying connection validity and cost rules.
-- @return #table VECTOR steering points excluding start and including the endpoint, or nil.
-- @return #string Failure reason, or nil.
-- @return #number Total cost of the simplified route, on success.
-- @return #table Constraint counts and representative failed checks, also returned on success.
function NAVYGROUP:_SimplifyLocalPath(Start, Heading, Path, GoalReached, Speed, Altitude, Search)

  Search=Search or self:_GetLocalSearch(Speed)
  local positions={}
  for _,point in ipairs(Path) do
    self:_LocalPlanningCheckpoint(1)
    local position=VECTOR:NewFromVec(point)
    if #positions>0 or Start:GetDistance(position,true)>0.1 then
      positions[#positions+1]=position
    end
  end
  Path=positions

  if #Path==0 then
    if GoalReached and self:_EvaluateLocalConnection(Search,Start,Start) then return {},nil,0 end
    return nil,"no_progress"
  end

  local speed=math.max(Speed or 0,self:GetVelocity() or 0)
  local minLeg=math.max(100,math.min((Speed or 0)*10,250))
  local weighted=self.pathPreferredDepth and self.pathPreferredDepth>(self.pathMinDepth or 20)
    and (self.pathDepthWeight or 2)>0
  local originalCost={[0]=0}
  local edges,turns={},{}

  -- Prefix costs compare a shortcut with exactly the raw A* section it replaces.
  if weighted then
    local previous=Start
    for i,point in ipairs(Path) do
      local valid,cost,depth=self:_EvaluateLocalConnection(Search,previous,point)
      if not valid then
        return nil,depth.Status=="unavailable" and "data_unavailable" or "connections_blocked"
      end
      originalCost[i]=originalCost[i-1]+cost
      previous=point
    end
  end

  -- Share terrain results across two independent searches. Exhausted steering states must
  -- be reset: a state rejected by the first pass may become usable with a more expensive leg.
  local firstPass
  for pass=1,(weighted and 2 or 1) do
    local report={Nodes=#Path,States=1,Backtracks=0,Adjustments=0,Rejections={},Examples={},
      Pass=pass,FirstPass=firstPass,OriginalCost=originalCost[#Path]}
    local exhausted={}

    -- Include the predecessor's heading in state keys: adjusting a corner must recheck that
    -- preceding turn too. Edge profiles and corner buffers are cached only for this call.
    local stack={{Index=0,Position=Start,Heading=Heading,Next=#Path,Cost=0,Key="start"}}
    while #stack>0 do
      self:_LocalPlanningCheckpoint(1)
      local state=stack[#stack]
      local index=state.Index

      -- An outward correction belongs to one outgoing alternative. Restore the original corner
      -- after backtracking so subsequent attempts cannot accumulate offsets beyond 150 m.
      if state.Restore then
        state.Position,state.Heading=state.Restore.Position,state.Restore.Heading
        state.Cost,state.Key=state.Restore.Cost,state.Restore.Key
        state.Restore=nil
      end

      if state.Next<=index then
        exhausted[state.Key]=true
        stack[#stack]=nil
        report.Backtracks=report.Backtracks+1
      else
        local nextIndex=state.Next
        state.Next=nextIndex-1
        local point=Path[nextIndex]
        local distance=state.Position:GetDistance(point,true)
        local course=state.Position:GetHeadingTo(point)
        local turn=math.abs((course-state.Heading+180)%360-180)
        local remaining=point:GetDistance(Path[#Path],true)
        local key=string.format("%d:%d:%.9f:%.9f:%.9f",index,nextIndex,state.Position.x,state.Position.z,state.Heading)
        local cause,limit,edge,corner

        if distance<=0.1 or (distance<minLeg and not (GoalReached and nextIndex==#Path)) then
          cause,limit="leg_too_short",minLeg
        elseif distance>1000 then
          cause,limit="leg_too_long",1000
        elseif nextIndex~=#Path and not GoalReached and remaining<minLeg then
          cause,limit="short_remainder",minLeg
        elseif turn>(index==0 and 75 or 90) then
          cause,limit="turn_angle",index==0 and 75 or 90
        elseif not exhausted[key] then
          edge=edges[key]
          if not edge then
            local clear,cost,depth=self:_EvaluateLocalConnection(Search,state.Position,point)
            edge={Cost=cost}
            if not clear then
              edge.Cause,edge.DepthCheck="depth",depth
              if depth.Status=="unavailable" then report.DataIncomplete=true end
            elseif weighted then
              edge.ReplacedCost=originalCost[nextIndex]-originalCost[index]
              if cost>edge.ReplacedCost+1e-6*math.max(1,edge.ReplacedCost) then
                edge.Cause="depth_cost"
              end
            end
            edges[key]=edge
          end

          cause=edge.Cause
          -- A depth preference is not a navigability constraint. On the second pass only
          -- this cost ceiling is relaxed; cached blocked/unknown depths still reject the edge.
          if pass==2 and cause=="depth_cost" then cause=nil end
          if not cause then
            local clear
            clear,corner=self:_CheckLocalTurn(state.Position,state.Heading,course,speed,turns)
            if not clear then
              cause="turn_clearance"
              if #stack>1 then
                local previous=stack[#stack-1]
                local adjusted=self:_AdjustLocalTurn(previous,state.Position,point,speed,minLeg,
                  GoalReached and nextIndex==#Path,turns,Search)
                if adjusted then
                  state.Restore={Position=state.Position,Heading=state.Heading,Cost=state.Cost,Key=state.Key}
                  state.Position=adjusted.Position
                  state.Heading=adjusted.Heading
                  state.Cost=previous.Cost+adjusted.FirstCost
                  state.Key=state.Key..string.format(":%.9f:%.9f",state.Position.x,state.Position.z)
                  course=state.Position:GetHeadingTo(point)
                  key=string.format("%d:%d:%.9f:%.9f:%.9f",index,nextIndex,state.Position.x,state.Position.z,state.Heading)
                  edge={Cost=adjusted.LastCost}
                  cause=nil
                  report.Adjustments=report.Adjustments+1
                end
              end
            end
          end

          if not cause then
            local position=VECTOR:New(point.x,Altitude,point.z)
            if nextIndex==#Path then
              local points={}
              report.CornerAdjustments={}
              for i=2,#stack do
                points[#points+1]=stack[i].Position
                local original=Path[stack[i].Index]
                if original:GetDistance(stack[i].Position,true)>0.1 then
                  report.CornerAdjustments[#report.CornerAdjustments+1]={Original=original,Position=stack[i].Position}
                end
              end
              points[#points+1]=position
              return points,nil,state.Cost+edge.Cost,report
            end

            if report.States>=128 then
              report.Reason="steering_budget_exceeded"
              break
            end
            report.States=report.States+1
            stack[#stack+1]={Index=nextIndex,Position=position,Heading=course,Next=#Path,
              Cost=state.Cost+edge.Cost,Key=key}
          end
        end

        if cause then
          local depth=corner and corner.DepthCheck or edge and edge.DepthCheck
          if depth and depth.Status=="unavailable" then report.DataIncomplete=true end
          report.Rejections[cause]=(report.Rejections[cause] or 0)+1
          if not report.Examples[cause] then
            report.Examples[cause]={From=index,To=nextIndex,Position=state.Position,Distance=distance,Turn=turn,
              Limit=limit,Cost=edge and edge.Cost,ReplacedCost=edge and edge.ReplacedCost,
              Radius=corner and corner.Radius,DepthCheck=corner and corner.DepthCheck or edge and edge.DepthCheck}
          end
        end
      end
    end

    report.Reason=report.Reason or (report.DataIncomplete and "data_unavailable" or "no_steering_path")
    if pass==1 and weighted and report.Rejections.depth_cost then
      firstPass=report
    else
      return nil,report.Reason,nil,report
    end
  end
end

--- Measure steering demand and the minimum length of a local route.
-- Keep the normal extension horizon plus an additional reserve for a large initial turn.
-- This is a planning allowance, not a prediction of a DCS ship's turning radius or stopping distance.
-- @param #NAVYGROUP self
-- @param Core.Vector#VECTOR Start Planning position.
-- @param #number Heading Incoming course in degrees.
-- @param #table Points VECTOR steering points; an initial copy of Start is harmless.
-- @param #number Speed Commanded speed in meters per second.
-- @return #table Length, Turns, InitialTurn, EndHeading and RequiredLength, in meters/degrees.
function NAVYGROUP:_GetLocalRouteMetrics(Start, Heading, Points, Speed)

  local length,turns,initialTurn=0,0,nil
  local position,course=Start,Heading

  for _,point in ipairs(Points) do
    self:_LocalPlanningCheckpoint(1)
    local distance=position:GetDistance(point,true)
    if distance>0.1 then
      local heading=position:GetHeadingTo(point)
      local turn=math.abs((heading-course+180)%360-180)
      initialTurn=initialTurn or turn
      turns=turns+turn
      length=length+distance
      position,course=point,heading
    end
  end

  local reserve=math.max(400,Speed*60)
  local required=math.max(2000,reserve+1000)+reserve*math.min(initialTurn or 0,90)/90
  return {Length=length,Turns=turns,InitialTurn=initialTurn or 0,EndHeading=course,RequiredLength=required}
end

--- Complete one public ASTAR local request through the caller-owned slice scheduler.
-- Copies result geometry and scalar diagnostics; the job never retains old node graphs.
function NAVYGROUP:_RequestLocalPaths(Search, Start, Heading, Job)

  self:_LocalPlanningCheckpoint(1)
  Job.Requests=(Job.Requests or 0)+1
  if Job.Requests>17 then
    Job.LimitReason="local_request_limit"
    Job.RequestReport={Status="complete",StopReason=Job.LimitReason,BudgetLimited=true}
    return nil,Job.LimitReason
  end
  Job.ActiveSearch=Search
  Search:StartLocalSearch(Start,Job.TargetPosition,Heading)
  local report=Search.LastSearchResult
  while report.Status=="running" do
    local path
    path,report=self:_LocalPlanningSearchSlice(Search)
  end
  self:_RecordPathfindingSearch(Search,self:_PathfindingSearchSnapshot(Search),1)

  local summary={}
  for key,value in pairs(report) do
    if type(value)~="table" then summary[key]=value end
  end
  Job.RequestReport=summary
  Job.DataIncomplete=Job.DataIncomplete or report.DataIncomplete
  if report.BudgetLimited then Job.LimitReason=report.StopReason end
  local candidates={}
  for index,candidate in ipairs(report.Candidates or {}) do
    if index>8 then break end
    local copied={Positions={},Cost=candidate.Cost,Score=candidate.Score,
      LearnedPenalty=candidate.LearnedPenalty or 0,RemainingDistance=candidate.RemainingDistance,
      GoalReached=candidate.ReachesGoal,Candidate=index,Report=summary}
    for _,position in ipairs(candidate.Positions) do
      self:_LocalPlanningCheckpoint(1)
      copied.Positions[#copied.Positions+1]=VECTOR:New(position.x,Job.Alt,position.z)
    end
    candidates[#candidates+1]=copied
  end
  -- Show completed request geometry, including exploratory extensions, independently of the installed route.
  if self.verbose>=10 and self:_IsLocalPlanningCurrent(Job) then self:_DrawLocalSearch(Search) end
  Job.ActiveSearch=nil
  if #candidates==0 then return nil,report.StopReason,summary end
  return candidates,nil,summary
end


--- Discard local plans and their debug drawing.
-- Does not issue a movement command or release Holding/Waiting.
-- @param #NAVYGROUP self
-- @return #NAVYGROUP self.
function NAVYGROUP:_ResetLocalNavigation()

  self:_CancelLocalPlanning("navigation_reset")
  self.localNavigation=nil
  self.ispathfinding=false
  self:_ClearPathfindingDrawing()
  return self
end

--- Find the outgoing leg of the next rounded corner on an installed route.
-- Straight subdivisions do not create extra corners. Look through them only inside the
-- same bounded neighbourhood, and never across another change of direction.
-- @param #NAVYGROUP self
-- @param #table Path Installed VECTOR points, including the route start; read-only.
-- @param #number Segment Current incoming segment index.
-- @param Core.Vector#VECTOR Position Observed ship position.
-- @param #number Heading Observed ship heading in degrees.
-- @param #number Speed Commanded speed in meters per second.
-- @return #number Outgoing segment index, or nil without evidence of corner rounding.
-- @return #string Progress reason, or nil.
function NAVYGROUP:_GetLocalRoundedCornerSegment(Path, Segment, Position, Heading, Speed)

  local a,b=Path[Segment],Path[Segment+1]
  local dx,dz=b.x-a.x,b.z-a.z
  local length=math.sqrt(dx*dx+dz*dz)
  if length<=0.1 then return nil end
  local ux,uz=dx/length,dz/length
  local neighbourhood=math.max(500,Speed*30)
  if Position:GetDistance(b,true)>neighbourhood then return nil end

  local cornerIndex=Segment+1
  while cornerIndex<#Path-1 do
    local corner,following=Path[cornerIndex],Path[cornerIndex+1]
    local forward=(following.x-corner.x)*ux+(following.z-corner.z)*uz
    local lateral=math.abs((following.x-a.x)*uz-(following.z-a.z)*ux)
    -- Compare with the original incoming line, so successive small bends cannot
    -- accumulate into a skipped real corner. One meter tolerates coordinate rounding.
    if forward<=0 or lateral>1 or Position:GetDistance(following,true)>neighbourhood then break end
    cornerIndex=cornerIndex+1
  end

  local corner,following=Path[cornerIndex],Path[cornerIndex+1]
  local outgoing=corner:GetHeadingTo(following)
  local cornerTurn=math.abs((outgoing-a:GetHeadingTo(corner)+180)%360-180)
  if cornerTurn<=5 then return nil end
  local nx,nz=following.x-corner.x,following.z-corner.z
  local square=nx*nx+nz*nz
  if square<=0.01 then return nil end
  local fraction=((Position.x-corner.x)*nx+(Position.z-corner.z)*nz)/square
  if fraction>1 then return nil end
  local nextDeviation=math.sqrt((Position.x-corner.x-fraction*nx)^2+(Position.z-corner.z-fraction*nz)^2)

  local incomingLength=(corner.x-a.x)*ux+(corner.z-a.z)*uz
  local along=math.max(0,math.min(incomingLength,(Position.x-a.x)*ux+(Position.z-a.z)*uz))
  local incomingDeviation=math.sqrt((Position.x-a.x-along*ux)^2+(Position.z-a.z-along*uz)^2)
  if fraction>0 and nextDeviation<incomingDeviation then return cornerIndex,"rounded_corner" end

  -- A rounded trajectory can adopt the outgoing course before crossing its endpoint
  -- plane. Require both that course and its next point ahead; the first retained
  -- point must be beside/behind the ship. Projection alone cannot prove this case.
  local aligned=math.abs((Heading-outgoing+180)%360-180)<=20
  local forwardCourse=math.abs((Position:GetHeadingTo(following)-Heading+180)%360-180)<=20
  local retainedTurn=math.abs((Position:GetHeadingTo(b)-Heading+180)%360-180)
  local allowance=math.max(150,Speed*20)
  if aligned and forwardCourse and retainedTurn>=75 and nextDeviation<=allowance then
    return cornerIndex,"outgoing_course"
  end
  return nil

end

--- Measure progress on contiguous segments of the installed local path.
-- Never selects a distant segment just because a hairpin brings it close to the ship.
-- @param #NAVYGROUP self
-- @param Core.Vector#VECTOR Position Actual ship position.
-- @return #number Monotonic progress along the path in meters.
-- @return #number Remaining path length in meters.
-- @return #number Distance from the currently followed segment in meters.
function NAVYGROUP:_LocalRouteProgress(Position)

  local navigation=self.localNavigation
  local path=navigation.Path
  local segment=navigation.Segment or 1
  local previousSegment=segment
  local advanceReason
  local heading=self:GetHeading()
  local deviation,along=0,0

  while segment<#path do
    local a,b=path[segment],path[segment+1]
    local dx,dz=b.x-a.x,b.z-a.z
    local length=math.sqrt(dx*dx+dz*dz)
    local fraction=length>0 and ((Position.x-a.x)*dx+(Position.z-a.z)*dz)/(length*length) or 1
    local t=math.max(0,math.min(1,fraction))
    local x,z=a.x+t*dx,a.z+t*dz
    deviation=math.sqrt((Position.x-x)^2+(Position.z-z)^2)
    along=navigation.Distances[segment]+t*length

    local crossTrack=length>0 and math.abs((Position.x-a.x)*dz-(Position.z-a.z)*dx)/length or 0
    local advance=fraction>=1 and crossTrack<=math.max(150,self:_GetPathfindingCorridorWidth())
    local reason=advance and "endpoint_plane" or nil

    local nextSegment=advance and segment+1 or nil
    if not advance and segment<#path-1 then
      nextSegment,reason=self:_GetLocalRoundedCornerSegment(path,segment,Position,heading,navigation.Speed or 0)
    end

    if nextSegment and nextSegment<#path then
      segment=nextSegment
      advanceReason=reason
    else
      break
    end
  end

  navigation.Segment=segment
  navigation.Progress=math.max(navigation.Progress or 0,along)

  if segment~=previousSegment then
    local nextPoint=path[segment+1]
    self:T(self.lid..string.format("Local route segment: route=%s, %d->%d, reason=%s, ship=(%.1f, %.1f), "..
      "heading=%.1f, next=(%.1f, %.1f), bearing=%.1f, deviation=%.1f m",
      tostring(navigation.RouteID),previousSegment,segment,tostring(advanceReason),Position.x,Position.z,
      heading,nextPoint.x,nextPoint.z,Position:GetHeadingTo(nextPoint),deviation))
  end
  return navigation.Progress,math.max(0,navigation.Length-navigation.Progress),deviation
end

--- Report a substantial departure from the planned line without treating it as an obstacle.
-- DCS follows waypoints with curved turns. Log once per segment/turn state until the ship rejoins
-- the line; actual depth and connection checks determine whether navigation can continue.
-- @param #NAVYGROUP self
-- @param Core.Vector#VECTOR Position Actual ship position.
-- @param #number Deviation Distance to the assigned path segment in meters.
function NAVYGROUP:_ReportLocalRouteDeviation(Position, Deviation)

  local navigation=self.localNavigation
  if Deviation<=math.max(150,self:_GetPathfindingCorridorWidth()) then
    navigation.DeviationNotice=nil
    return
  end

  local segment=navigation.Segment
  local turning=self:IsTurning()
  local previous=navigation.DeviationNotice
  if previous and previous.Segment==segment and previous.Turning==turning then return end

  navigation.DeviationNotice={Segment=segment,Turning=turning}
  local from,to=navigation.Path[segment],navigation.Path[segment+1]
  self:I(self.lid..string.format(
    "Local route deviation: %.1f m, segment=%d, turning=%s, heading=%.1f, "..
    "ship=(%.1f,%.1f), from=(%.1f,%.1f), to=(%.1f,%.1f); depth checks remain authoritative",
    Deviation,segment,tostring(turning),self:GetHeading(),Position.x,Position.z,from.x,from.z,to.x,to.z))
end

--- Complete a local leg through the normal waypoint and mission-task lifecycle.
-- Clear the local route first because waypoint callbacks can issue new movement commands.
-- Completion never overwrites a waypoint task with an extra stop command.
-- @param #NAVYGROUP self
-- @return #boolean True after dispatching the original waypoint event.
function NAVYGROUP:_CompleteLocalLeg()

  local uid=self.localNavigation.TargetUID
  self:_ResetLocalNavigation()
  self.navigationCommand=nil
  self.localNavigationTaskUID=uid
  OPSGROUP._PassingWaypoint(self,uid)

  -- Ordinary tasks become taskcurrent in a later native callback; mission tasks can start immediately.
  -- Keep their route intact in both cases. The timer resumes normal navigation once all tasks release it.
  -- A callback that already updated the route or stopped the ship has cleared this marker itself.
  if self.localNavigationTaskUID==uid and self:CountTasksWaypoint(uid)==0 and self:_CanNavigate() then
    self.localNavigationTaskUID=nil
    self:__UpdateRoute(0.01)
  end
  return true
end

--- Check the actual depth and the next installed local route segments.
-- During a turn, keep checking the stored route instead of inventing a shortcut from the current
-- position to its next corner. This is a sampled corridor check, not a prediction of the turning arc.
-- @param #NAVYGROUP self
-- @param Core.Vector#VECTOR Position Actual ship position.
-- @return #boolean True when the checked route is clear.
-- @return #string Rejection reason, or nil.
-- @return Core.Pathline#PATHLINE.DepthReport Detailed clearance report.
function NAVYGROUP:_CheckLocalRoute(Position)

  local navigation=self.localNavigation
  local clear,reason,report=self:_CheckPathDepth(Position,Position)
  report.NavigationStage="ship_position"
  if not clear then return clear,reason,report end

  local turning=self:IsTurning()
  local from=turning and navigation.Path[navigation.Segment] or Position
  for i=navigation.Segment+1,#navigation.Path do
    clear,reason,report=self:_CheckPathDepth(from,navigation.Path[i])
    report.NavigationStage=(i==navigation.Segment+1 and not turning) and "actual_position_to_next" or "stored_segment"
    report.RouteSegment=i-1
    report.RouteID=navigation.RouteID
    report.CheckStart,report.CheckGoal=from,navigation.Path[i]
    if not clear then return clear,reason,report end
    from=navigation.Path[i]
  end

  return clear,reason,report
end

--- Check useful distance beyond the retained approach and every future turning exit.
-- A long incoming segment cannot conceal an exhausted route after its final corner.
-- These reserves are planning allowances, not a DCS braking or turning model.
function NAVYGROUP:_CheckLocalRoutePreparation(Points, Job, PrefixCount, GoalReached)

  local speed=math.max(Job.Speed,self:GetVelocity() or 0)
  local reserve=math.max(400,speed*60)+speed*10
  local lengths={0}
  local total=0
  for i=2,#Points do
    self:_LocalPlanningCheckpoint(1)
    total=total+Points[i-1]:GetDistance(Points[i],true)
    lengths[i]=total
  end

  local anchor=Points[PrefixCount]
  local heading=PrefixCount>1 and Points[PrefixCount-1]:GetHeadingTo(anchor) or Job.Heading
  local suffix={}
  for i=PrefixCount+1,#Points do
    self:_LocalPlanningCheckpoint(1)
    suffix[#suffix+1]=Points[i]
  end
  local metrics=self:_GetLocalRouteMetrics(anchor,heading,suffix,speed)
  metrics.SuffixLength=metrics.Length
  metrics.Length=total
  metrics.StopReserve=reserve
  if GoalReached then return true,metrics end
  if metrics.SuffixLength<metrics.RequiredLength then return false,metrics,"local_route_too_short" end

  local incoming=Job.Heading
  for i=1,#Points-1 do
    self:_LocalPlanningCheckpoint(1)
    local length=Points[i]:GetDistance(Points[i+1],true)
    if length>0.1 then
      local outgoing=Points[i]:GetHeadingTo(Points[i+1])
      local turn=math.abs((outgoing-incoming+180)%360-180)
      if turn>5 and total-lengths[i]<=reserve then
        metrics.ShortTurnIndex=i
        metrics.TurnRemaining=total-lengths[i]
        return false,metrics,"local_turn_exit_too_short"
      end
      incoming=outgoing
    end
  end
  return true,metrics
end

--- Price the exact proposed route without changing the installed route or ASTAR caches.
function NAVYGROUP:_PriceLocalRoute(Points, Search)

  local cost=0
  for i=2,#Points do
    local clear,value,report=self:_EvaluateLocalConnection(Search,Points[i-1],Points[i])
    if not clear then
      return nil,report.Status=="unavailable" and "data_unavailable" or (report.Reason or "connections_blocked"),report
    end
    cost=cost+value
  end
  return cost
end

--- Build a complete proposed local route inside one caller-owned planning job.
-- Steer and reprice all primary exits, preserving ASTAR's learned ranking among usable routes.
-- Prefer complete primary routes; only extend short exits when no complete primary route succeeds.
-- Accept the first usable route in each ranked group; extended alternatives are not globally compared.
-- Probe planners have no learning. Each candidate gets at most two serial continuation requests.
-- Native routes, mission waypoints and installed geometry remain unchanged until caller submission.
function NAVYGROUP:_BuildLocalRoute(Job)

  local prefix={}
  for _,point in ipairs(Job.Prefix or {Job.Position}) do
    self:_LocalPlanningCheckpoint(1)
    prefix[#prefix+1]=VECTOR:New(point.x,Job.Alt,point.z)
  end
  local anchor=prefix[#prefix]
  local heading=#prefix>1 and prefix[#prefix-1]:GetHeadingTo(anchor) or Job.Heading
  local search=self:_GetLocalSearch(Job.Speed)
  search:UpdateLocalProgress(VECTOR:NewFromVec(self:GetVec3()))
  local prefixCost,prefixReason,prefixReport=self:_PriceLocalRoute(prefix,search)
  if not prefixCost and Job.InitialApproach and #prefix==2 and prefixReport and prefixReport.Status=="blocked" then
    -- A future native-course anchor is optional. A known obstruction must leave the planner
    -- free to find a detour from the actual planning start; unavailable depth still fails.
    prefix[2]=nil
    anchor=prefix[1]
    heading=Job.Heading
    prefixCost=0
  end
  if not prefixCost then return nil,nil,prefixReason end
  Job.Phase="primary_search"
  local candidates,reason,request=self:_RequestLocalPaths(search,anchor,heading,Job)
  if not candidates then return nil,nil,reason end

  -- Useful suffix and turning reserves are eligibility requirements. A complete primary route
  -- avoids speculative graph exploration for a cheaper exit that cannot yet be submitted.
  local ranked,failures={},{}
  for _,candidate in ipairs(candidates) do
    Job.Phase,Job.Candidate="primary_steering",candidate.Candidate
    self:_LocalPlanningCheckpoint(1)
    local steered,failure,steeredCost,steering=self:_SimplifyLocalPath(anchor,heading,candidate.Positions,
      candidate.GoalReached,Job.Speed,Job.Alt,search)
    if steering then steering.Candidate=candidate.Candidate end
    if steered then
      local suffix={anchor}
      for _,point in ipairs(steered) do
        self:_LocalPlanningCheckpoint(1)
        suffix[#suffix+1]=point
      end
      Job.Phase="primary_pricing"
      local cost,pricingReason=self:_PriceLocalRoute(suffix,search)
      if cost then
        local points={}
        for i,point in ipairs(prefix) do
          self:_LocalPlanningCheckpoint(1)
          points[i]=point:Copy()
        end
        for _,point in ipairs(steered) do
          self:_LocalPlanningCheckpoint(1)
          points[#points+1]=point:Copy()
        end
        Job.Phase="primary_reserve"
        local usable,metrics,preparationReason=self:_CheckLocalRoutePreparation(points,Job,#prefix,candidate.GoalReached)
        if not usable then Job.LastRejection=preparationReason end
        ranked[#ranked+1]={Candidate=candidate,Points=points,Steering=steering,
          Usable=usable,Metrics=metrics,PreparationReason=preparationReason,
          Score=prefixCost+cost+(candidate.GoalReached and 0 or candidate.Score-candidate.Cost)}
      else
        reason=pricingReason
        Job.LastRejection=pricingReason
        if pricingReason=="data_unavailable" then Job.DataIncomplete=true end
      end
    else
      if steering then failures[#failures+1]=steering end
      reason=failure
      Job.LastRejection=failure
      if failure=="data_unavailable" then Job.DataIncomplete=true end
    end
  end
  table.sort(ranked,function(first,second)
    if first.Usable~=second.Usable then return first.Usable end
    if first.Score==second.Score then return first.Candidate.Candidate<second.Candidate.Candidate end
    return first.Score<second.Score
  end)

  for _,prepared in ipairs(ranked) do
    Job.Candidate,Job.Extension=prepared.Candidate.Candidate,0
    self:_LocalPlanningCheckpoint(1)
    local candidate=prepared.Candidate
    local points=prepared.Points
    local terminal=candidate
    local goalReached=candidate.GoalReached
    local extensions=0
    local usable,metrics,preparationReason=prepared.Usable,prepared.Metrics,prepared.PreparationReason
    local probe,failure

    while not usable and extensions<2 do
      self:_LocalPlanningCheckpoint(1)
      probe=probe or self:_GetLocalSearch(Job.Speed,true)
      local endpoint=points[#points]
      local incoming=#points>1 and points[#points-1]:GetHeadingTo(endpoint) or heading
      Job.Phase,Job.Extension="extension_search",extensions+1
      local alternatives,extensionReason=self:_RequestLocalPaths(probe,endpoint,incoming,Job)
      extensions=extensions+1
      if not alternatives then
        if Job.LimitReason then return nil,nil,Job.LimitReason end
        failure=extensionReason
        Job.LastRejection=extensionReason
        break
      end

      local chosen,chosenPoints,chosenScore
      for _,alternative in ipairs(alternatives) do
        Job.Phase="extension_steering"
        self:_LocalPlanningCheckpoint(1)
        local nextPoints,nextFailure,nextCost=self:_SimplifyLocalPath(endpoint,incoming,
          alternative.Positions,alternative.GoalReached,Job.Speed,Job.Alt,probe)
        if nextPoints then
          local score=nextCost+(alternative.GoalReached and 0 or alternative.Score-alternative.Cost)
          if alternative.GoalReached or not chosenScore or score<chosenScore then
            chosen,chosenPoints,chosenScore=alternative,nextPoints,score
          end
          if alternative.GoalReached then break end
        else
          failure=nextFailure
          Job.LastRejection=nextFailure
          if nextFailure=="data_unavailable" then Job.DataIncomplete=true end
        end
      end
      if not chosen then break end
      local previousLength=metrics.Length
      for _,point in ipairs(chosenPoints) do
        self:_LocalPlanningCheckpoint(1)
        points[#points+1]=point
      end
      terminal,goalReached=chosen,chosen.GoalReached
      Job.Phase="extension_reserve"
      usable,metrics,preparationReason=self:_CheckLocalRoutePreparation(points,Job,#prefix,goalReached)
      if not usable then Job.LastRejection=preparationReason end
      if metrics.Length<=previousLength+0.1 and not goalReached then failure="no_progress" break end
    end

    if usable then
      -- Fresh final pricing also validates the common approach after a potentially long job.
      Job.Phase="final_pricing"
      local finalCost,pricingReason=self:_PriceLocalRoute(points,search)
      if finalCost then
        local estimate=goalReached and 0 or terminal.Score-terminal.Cost
        if extensions>0 and not goalReached then estimate=estimate+candidate.LearnedPenalty end
        local routePoints={}
        for i=2,#points do
          self:_LocalPlanningCheckpoint(1)
          routePoints[#routePoints+1]=points[i]:Copy()
        end
        local plan={Points=routePoints,GoalReached=goalReached,Cost=finalCost,Score=finalCost+estimate,
          Candidate=candidate.Candidate,PrimaryScore=prepared.Score,
          LearnedPenalty=goalReached and 0 or candidate.LearnedPenalty,
          StopReason="path_found",Outcome=goalReached and "goal_path" or "partial_path",
          Length=metrics.Length,SuffixLength=metrics.SuffixLength,RequiredLength=metrics.RequiredLength,
          StopReserve=metrics.StopReserve,InitialTurn=metrics.InitialTurn,Turns=metrics.Turns,
          PreflightExtensions=extensions,Request=request,RequestID=request.RequestID,
          Steering=prepared.Steering,SteeringFailures=failures,PlanningSpeed=Job.Speed,MinDepth=self.pathMinDepth or 20,
          CorridorWidth=self:_GetPathfindingCorridorWidth(),PreferredDepth=self.pathPreferredDepth,
          DepthWeight=self.pathDepthWeight or 2,Attempts=Job.Requests}
        self:T(self.lid..string.format("Local route prepared: request=%s, candidate=%d, requests=%d, "..
          "length=%.0f m, suffix=%.0f m, cost=%.1f, score=%.1f, goal=%s",
          tostring(plan.RequestID),plan.Candidate,Job.Requests,plan.Length,
          plan.SuffixLength,plan.Cost,plan.Score,tostring(plan.GoalReached)))
        return points,plan
      end
      reason=pricingReason
      Job.LastRejection=pricingReason
      if pricingReason=="data_unavailable" then Job.DataIncomplete=true end
    else
      reason=failure or preparationReason or "local_route_too_short"
    end
  end

  Job.SteeringFailures=failures
  return nil,nil,Job.DataIncomplete and "data_unavailable" or (reason or "no_steering_path")
end


--- Install a validated local polyline and submit only its remaining points.
-- Original waypoints and their task queues are retained. Local points have no mission callbacks.
-- @param #NAVYGROUP self
-- @param #table Points VECTOR positions including the planning start.
-- @param #table Plan Local planner result.
-- @param Core.Vector#VECTOR Position Actual ship position at submission time.
-- @return #boolean True when the local route was submitted.
function NAVYGROUP:_InstallLocalRoute(Points, Plan, Position)

  local navigation=self.localNavigation
  local snapshot=self:_LocalNavigationSnapshot()
  local distances={0}
  local length=0
  for i=2,#Points do
    length=length+Points[i-1]:GetDistance(Points[i],true)
    distances[i]=length
  end
  local speed=math.max(Plan.PlanningSpeed or 0,navigation.Speed,self:GetVelocity() or 0)
  local reserve=math.max(400,speed*60)+speed*10
  if not Plan.GoalReached and length<=reserve then
    local job=navigation.Pending
    if job then return self:_LocalPlanningFailed(job,"local_route_too_short") end
    return self:_FailPathfinding({StopReason="local_route_too_short",Remaining=length,Mode="local"})
  end

  -- Validate and price the proposed geometry without changing what the controller is tracking.
  -- Publication happens only after warning callbacks have retained our movement authority.
  local search=self:_GetLocalSearch(speed)
  local cost,reason,report=self:_PriceLocalRoute(Points,search)
  if not report then
    report={Status="clear",Distance=length,ClearDistance=length,RequiredDepth=self.pathMinDepth or 20}
  end
  self:_UpdateNavigationWarning(report)
  if not self:_IsLocalNavigationSnapshotCurrent(snapshot) then return false end
  if not cost then return self:_FailPathfinding({StopReason=reason,DepthCheck=report,Mode="local"}) end

  local installed={}
  for key,value in pairs(Plan) do installed[key]=value end
  installed.PlannedCost=Plan.Cost
  installed.Cost=cost
  installed.Score=Plan.Score and Plan.Score+(cost-(Plan.Cost or cost)) or cost
  installed.Length=length
  installed.Points={}
  for i=2,#Points do installed.Points[#installed.Points+1]=Points[i]:Copy() end
  navigation.Path=Points
  navigation.Distances=distances
  navigation.Length=length
  navigation.Segment=1
  navigation.Progress=0
  navigation.GoalReached=Plan.GoalReached
  navigation.Pending=nil
  navigation.ExtensionFailure=nil
  navigation.DeviationNotice=nil
  navigation.ExtensionAfter=math.min(250,length*0.1)
  navigation.SafetyTime=timer.getTime()
  self.LastPathfindingResult=installed
  self.ispathfinding=true
  return self:_SubmitLocalRoute(Position,true)
end

--- Submit the validated remainder of the local route to DCS.
-- The original destination is included only when reached by this plan. Its regular waypoint event
-- and queued tasks are dispatched on actual arrival; native local points have no waypoint callbacks.
-- @param #NAVYGROUP self
-- @param Core.Vector#VECTOR Position Actual ship position.
-- @return #boolean True when submitted; false if navigation changed or the connector is invalid.
function NAVYGROUP:_SubmitLocalRoute(Position, Validated)

  local navigation=self.localNavigation
  local snapshot=self:_LocalNavigationSnapshot()
  if not self:_IsLocalNavigationSnapshotCurrent(snapshot) then return false end

  local remaining=navigation.Length-navigation.Progress
  local speed=math.max(navigation.Speed,self:GetVelocity() or 0)
  local reserve=math.max(400,speed*60)+speed*10
  if not navigation.GoalReached and remaining<=reserve then
    return self:_FailPathfinding({StopReason="local_route_too_short",Remaining=remaining,Mode="local"})
  end

  if not Validated then
    local clear,reason,report=self:_CheckLocalRoute(Position)
    self:_UpdateNavigationWarning(report)
    if not self:_IsLocalNavigationSnapshotCurrent(snapshot) then return false end
    if not clear then return self:_FailPathfinding({StopReason=reason,DepthCheck=report}) end
  end

  -- Switching from the waypoint planner may leave its temporary detour in the stored route.
  -- Remove it only after the replacement passed validation; it must not reappear on a later patrol lap.
  for i=#self.waypoints,1,-1 do
    local waypoint=self.waypoints[i]
    if waypoint.astar and waypoint~=navigation.Target then self:RemoveWaypointByID(waypoint.uid,false) end
  end

  -- Removing our previous detour changes the stored next leg; preserve the selected original destination.
  self:_SetNavigationWaypoint(navigation.Target)

  local speed=navigation.Speed*3.6
  local route={UTILS.VecWaypointNaval(Position,speed,navigation.Alt)}

  for i=navigation.Segment+1,#navigation.Path do
    local waypoint=UTILS.VecWaypointNaval(navigation.Path[i],speed,navigation.Alt)
    if i==#navigation.Path and navigation.GoalReached then
      -- The timer dispatches the original waypoint event on actual arrival. DCS must not run it early.
      waypoint.uid=navigation.TargetUID
    end
    route[#route+1]=waypoint
  end

  self.speedWp=navigation.Speed
  self.altWp=navigation.Alt
  navigation.NeedsSubmit=nil
  self.localRouteSequence=(self.localRouteSequence or 0)+1
  navigation.RouteID=self.localRouteSequence

  -- Log the actual submitted waypoints, not just the raw A* drawing. These coordinates let
  -- a test compare DCS's rounded trajectory with our current segment without guessing.
  if self:IsTrace() then
    for i,point in ipairs(route) do
      self:T(self.lid..string.format("Local route point: route=%d, point=%d, x=%.1f, z=%.1f, speed=%.2f m/s",
        navigation.RouteID,i,point.x,point.y,point.speed))
    end
  end
  local plan=self.LastPathfindingResult or {}
  self:T(self.lid..string.format("Local navigation: target UID %d, %d route points, %.0f m validated, goal=%s, "..
    "initial turn %.1f deg, required length %.0f m, preflight extensions %d",
    navigation.TargetUID,#route,navigation.Length-navigation.Progress,tostring(navigation.GoalReached),
    plan.InitialTurn or 0,plan.RequiredLength or 0,plan.PreflightExtensions or 0))
  if self.pathfindingDiagnostics and self.pathfindingDiagnostics.Enabled then
    self.pathfindingDiagnostics.RouteSubmissions=self.pathfindingDiagnostics.RouteSubmissions+1
  end
  local submittedSnapshot=self.verbose>=10 and self:_LocalNavigationSnapshot()
  self:Route(route)
  -- Route callbacks can stop or replace navigation. Do not resurrect a discarded overlay afterwards.
  if submittedSnapshot and self:_IsLocalNavigationSnapshotCurrent(submittedSnapshot) then
    self:_DrawLocalRoute(route)
  end
  return true
end

--- Maintain the bounded local route, independently of early DCS waypoint callbacks.
-- A regular tick observes progress and plans a continuation before the validated route runs out.
-- FullStop, Waiting and movement tasks remain authoritative. Failure never starts an automatic retry.
-- @param #NAVYGROUP self
-- @param #boolean Force (Optional) Explicit route update; resubmit the validated route even without progress.
-- @param #number Speed (Optional) Commanded speed override in knots.
-- @param #number Depth (Optional) Commanded depth override in meters, positive down.
-- @param #number First (Optional) Explicit original waypoint index, including GotoWaypoint and patrol wrap.
-- @return #boolean True when navigation remains usable; false on a hold, failure or completed leg.
function NAVYGROUP:_CheckLocalNavigation(Force, Speed, Depth, First)

  return self:_MeasurePathfinding("local_update",self._RunLocalNavigation,Force, Speed, Depth, First)

end

--- Execute the existing navigation operation; measurements are owned by the public entry above.
function NAVYGROUP:_RunLocalNavigation(Force, Speed, Depth, First)

  if not self.pathfindingOn or self.pathfindingMode~="local" or not self:_CanNavigate() then
    self:_CancelLocalPlanning("movement_authority_lost")
    return false
  end
  if self.localNavigationTaskUID then
    if self:CountTasksWaypoint(self.localNavigationTaskUID)>0 then return false end
    self.localNavigationTaskUID=nil
  end
  if First then self:_SetNavigationWaypoint(self.waypoints[First]) end
  local target=self:_GetPathfindingTarget()
  if not target then return self:_FailPathfinding({StopReason="local_missing_target"}) end
  local navigation=self.localNavigation
  local changed=not navigation or navigation.Target~=target
    or navigation.TargetPosition.x~=target.coordinate.x or navigation.TargetPosition.y~=target.coordinate.y
    or navigation.TargetPosition.z~=target.coordinate.z
  if changed and navigation and navigation.Target then
    self:_ResetLocalNavigation()
    self:__UpdateRoute(0.01,First,nil,Speed,Depth)
    return false
  end
  if changed then
    self:_ResetLocalNavigation()
    navigation={TargetUID=target.uid,Target=target,TargetPosition=VECTOR:NewFromVec(target.coordinate),Generation=0}
    self.localNavigation=navigation
    self:_SetNavigationWaypoint(target)
  end
  navigation.Speed=Speed and UTILS.KnotsToMps(Speed) or navigation.Speed or self.speedWp or target.speed
  if not navigation.Speed or navigation.Speed<=0 then navigation.Speed=UTILS.KnotsToMps(self:GetSpeedCruise()) end
  if Force or navigation.Alt==nil then navigation.Alt=Depth and -Depth or (self.depth and -self.depth) or target.coordinate.y end
  navigation.NeedsSubmit=navigation.NeedsSubmit or Force
  local position=VECTOR:NewFromVec(self:GetVec3())
  local speed=math.max(navigation.Speed,self:GetVelocity() or 0)
  local reserve=math.max(400,speed*60)+speed*10
  local turning=self:IsTurning()
  if navigation.Search then navigation.Search:UpdateLocalProgress(position) end
  local job=navigation.Job or navigation.Pending
  if job then
    local current,staleReason=self:_IsLocalPlanningCurrent(job)
    if not current then self:_CancelLocalPlanning(staleReason) end
  end

  if not navigation.Path and position:GetDistance(navigation.TargetPosition,true)<=50 then
    local snapshot=self:_LocalNavigationSnapshot()
    local clear,reason,report=self:_CheckPathDepth(position,navigation.TargetPosition)
    self:_UpdateNavigationWarning(report)
    if not self:_IsLocalNavigationSnapshotCurrent(snapshot) then return false end
    if not clear then return self:_FailPathfinding({StopReason=reason,DepthCheck=report,Mode="local"}) end
    return self:_CompleteLocalLeg()
  end

  local progress,remaining,deviation=0,nil,0
  if navigation.Path then
    progress,remaining,deviation=self:_LocalRouteProgress(position)
    self:_ReportLocalRouteDeviation(position,deviation)
  end
  local now=timer.getTime()
  if Force or not navigation.SafetyTime or now-navigation.SafetyTime>=2 or now<navigation.SafetyTime then
    navigation.SafetyTime=now
    local snapshot=self:_LocalNavigationSnapshot()
    local clear,reason,report
    if navigation.Path then
      clear,reason,report=self:_CheckLocalRoute(position)
    else
      clear,reason,report=self:_CheckNavigationAhead(position,target)
      -- A new asynchronous search may use only the still-clear native approach. The allowance
      -- is a planning margin, not a claim about measured DCS stopping distance.
      if report.Status=="blocked" and report.ClearDistance>reserve then clear=true end
    end
    self:_UpdateNavigationWarning(report)
    if not self:_IsLocalNavigationSnapshotCurrent(snapshot) then return false end
    if not clear then
      return self:_FailPathfinding({StopReason=not navigation.Path and report.Status=="blocked"
        and "local_planning_reserve" or reason,DepthCheck=report,Mode="local"})
    end
  end

  if navigation.Path then
    local arrival=math.max(50,math.min(150,navigation.Speed*10))
    if navigation.GoalReached and remaining<=arrival and position:GetDistance(navigation.TargetPosition,true)<=arrival then
      return self:_CompleteLocalLeg()
    end
    if not navigation.GoalReached and remaining<=reserve and turning then
      return self:_FailPathfinding({StopReason="local_route_exhausted_in_turn",Remaining=remaining,Reserve=reserve,
        ExtensionFailure=navigation.ExtensionFailure,Mode="local"})
    end
    if navigation.Pending and not turning then return self:_CommitLocalPlanning(position) end
    if not navigation.GoalReached and remaining<=reserve and not navigation.Pending then
      return self:_FailPathfinding({StopReason="local_route_exhausted",Remaining=remaining,Reserve=reserve,
        ExtensionFailure=navigation.ExtensionFailure,Mode="local"})
    end
  elseif navigation.Pending and not turning then
    return self:_CommitLocalPlanning(position)
  end

  if navigation.Job then
    self:_AdvanceLocalPlanning()
    if self.localNavigation~=navigation or not self:_CanNavigate() then return false end
    if navigation.Pending and not turning then return self:_CommitLocalPlanning(position) end
  elseif not navigation.Pending then
    local failure=navigation.ExtensionFailure
    local recover=failure and failure.AwaitingStraight and not turning and not failure.Replacement
    local extend=navigation.Path and not navigation.GoalReached
      and remaining<=math.max(3000,reserve+2000) and progress>=(navigation.ExtensionAfter or 0)
    if not navigation.Path or recover or extend then
      self:_StartLocalPlanning(position,recover or not navigation.Path)
    end
  end
  if navigation.Path and navigation.NeedsSubmit and not turning then return self:_SubmitLocalRoute(position) end
  return true

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
    astar:DrawGridWithPath(path)
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

--- Show the most recently completed LOCAL search window with cell-center depth colors.
-- An empty path requests a fixed grid snapshot without highlighting an unsubmitted A* candidate.
-- Replacing a search window leaves the submitted steering-route line intact.
-- @param #NAVYGROUP self
-- @param Core.Astar#ASTAR Search Completed local request, including a speculative extension.
-- @return #NAVYGROUP self.
function NAVYGROUP:_DrawLocalSearch(Search)

  if self.pathfindingDebugSearch then self.pathfindingDebugSearch:UndrawGrid() end
  self.pathfindingDebugSearch=Search

  local minimumDepth=self.pathMinDepth or 20
  local maximumDepth=math.max(minimumDepth+1,self.pathPreferredDepth or minimumDepth+20)
  Search:DrawGrid({}, {ColorByDepth=true,DepthMin=minimumDepth,DepthMax=maximumDepth})
  return self
end

--- Draw a copy of the exact LOCAL waypoint sequence submitted to DCS in magenta.
-- The line describes the command, not the observed ship trajectory or a swept hull corridor.
-- @param #NAVYGROUP self
-- @param #table Route Submitted DCS naval waypoints; read-only.
-- @return #NAVYGROUP self.
function NAVYGROUP:_DrawLocalRoute(Route)

  if self.pathfindingDebugRoute then self.pathfindingDebugRoute:UnDrawLine() end

  local positions={}
  for _,waypoint in ipairs(Route) do
    positions[#positions+1]={x=waypoint.x,y=waypoint.alt,z=waypoint.y}
  end
  self.pathfindingDebugRoute=PATHLINE:NewFromVec3Array("Local steering route",positions)
  self.pathfindingDebugRoute:DrawLine(-1,{1,0,1,1})
  return self
end

--- Remove this group's previous pathfinding overlays and cancel pending drawing batches.
-- Leaves other groups' drawings and unrelated map marks untouched.
-- @param #NAVYGROUP self
-- @return #NAVYGROUP self.
function NAVYGROUP:_ClearPathfindingDrawing()
  if self.pathfindingDebugSearch then
    self.pathfindingDebugSearch:UndrawGrid()
    self.pathfindingDebugSearch=nil
  end
  if self.pathfindingDebugRoute then
    self.pathfindingDebugRoute:UnDrawLine()
    self.pathfindingDebugRoute=nil
  end
  return self
end

--- Record a failed plan and stop without discarding the original route.
-- Uses an ordinary FullStop. Only a new movement command can resume the ship.
-- @param #NAVYGROUP self
-- @param #table Report Failed pathfinding result or unavailable depth measurement.
-- @return #boolean Always false.
function NAVYGROUP:_FailPathfinding(Report)

  if self.localNavigation then
    Report.SteeringFailures=self.localNavigation.SteeringFailures
    local job=self.localNavigation.Job or self.localNavigation.Pending
    if job then Report.Planning=self:_RecordLocalPlanningOutcome(job,Report.StopReason) end
  end
  self.LastPathfindingResult=Report
  self.ispathfinding=false
  self:_ClearPathfindingDrawing()
  if Report.DepthCheck then self:_LogNavigationDepthCheck(Report.DepthCheck,"stop") end
  self:E(self.lid.."Naval pathfinding failed: "..tostring(Report.StopReason).." ==> FullStop")
  self:FullStop()

  return false
end

--- Log the existing depth-check evidence without additional terrain queries.
-- NavigationStage distinguishes a blocked ship position from a blocked route or submission connector.
-- @param #NAVYGROUP self
-- @param Core.Pathline#PATHLINE.DepthReport Report Failed depth check, optionally with navigation context.
-- @param #string Action Navigation response: replan, stop or continue_local.
function NAVYGROUP:_LogNavigationDepthCheck(Report, Action)

  local point=Report.Point or {}
  local position=Report.Nearfield and Report.Nearfield.Position or self:GetVec3() or {}

  -- Keep each line short: DCS truncates long diagnostics, including the coordinates we need most.
  self:I(self.lid..string.format(
    "Naval depth check: action=%s, stage=%s, segment=%s, status=%s, reason=%s, cause=%s, "..
    "depth=%s m, required_depth=%s m, surface=%s, profile_offset=%s m, location=%s, distance=%s m",
    tostring(Action),tostring(Report.NavigationStage),tostring(Report.RouteSegment),tostring(Report.Status),
    tostring(Report.Reason),tostring(Report.Cause),tostring(Report.Depth),tostring(Report.RequiredDepth),
    tostring(Report.SurfaceType),tostring(Report.ProfileOffset),tostring(Report.Location),tostring(Report.Distance)))
  self:I(self.lid..string.format(
    "Naval depth position: point=(%s,%s,%s), ship=(%s,%s,%s), heading=%s, turning=%s, route_deviation=%s m",
    tostring(point.x),tostring(point.y),tostring(point.z),tostring(position.x),tostring(position.y),tostring(position.z),
    tostring(Report.Nearfield and Report.Nearfield.Heading or self:GetHeading()),tostring(self:IsTurning()),tostring(Report.RouteDeviation)))

  if Report.CheckStart and Report.CheckGoal then
    self:I(self.lid..string.format("Naval depth segment: route=%s, target_uid=%s, check_from=(%.1f, %.1f), check_to=(%.1f, %.1f)",
      tostring(Report.RouteID),tostring(Report.TargetUID),Report.CheckStart.x,Report.CheckStart.z,Report.CheckGoal.x,Report.CheckGoal.z))
  end

  local near=Report.Nearfield
  if near then
    self:I(self.lid..string.format("Naval nearfield: unit=%s, bow=%.1f m, stern=%.1f m, beam=%.1f m, "..
      "speed=%.2f m/s, lookahead=%.1f m, clear_from_bow=%.1f m",
      tostring(near.Unit),near.Bow,near.Stern,near.Beam,near.Speed,near.Lookahead,near.ClearFromBow))
  end
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
