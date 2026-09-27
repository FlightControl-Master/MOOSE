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
-- @field #string pathfindingMode Navigation strategy from NAVYGROUP.PathfindingMode; default WAYPOINT.
-- @field #NAVYGROUP.LocalNavigation localNavigation Private local route and search window; independent of mission waypoints.
-- @field #number localNavigationRevision Monotonic identifier used to reject obsolete local waypoint callbacks.
-- @field #number localNavigationTaskUID Completed local destination whose waypoint tasks must finish before route submission.
-- @field #NAVYGROUP.LocalNavigationCommand localNavigationCommand Explicit native destination while waiting for an obstacle in LOCAL mode.
-- @field Core.Timer#TIMER timerNavigation Independent timer for local route checks.
-- @field Core.Pathline#PATHLINE.DepthReport LastNavigationCheck Last local depth check; unavailable data is distinct from an obstacle.
-- @field #table LastPathfindingResult Last expansion report or direct-path/failure status.
-- @field Core.Astar#ASTAR pathfindingDebugSearch Owner of this group's current pathfinding debug overlay.
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
-- Checks are suspended while the group is turning. Terrain profiles use the configured minimum depth
-- along the center and both edges of the ship's clearance corridor; they do not predict a turning arc.
-- CollisionWarning and ClearAhead report changes in the measured route clearance.
--
-- With SetPathfindingOn(), an obstacle triggers one bounded A* search to the next original waypoint.
-- A successful search replaces the temporary detour and submits the complete route without stopping first.
-- A failed search or unavailable depth data stops the ship with FullStop(). It stays stopped until a new
-- movement command is issued; there are no automatic retries or waypoint-callback searches.
-- Disabling pathfinding keeps collision warnings active but prevents automatic route changes and stops.
--
-- SetPathfindingMode(NAVYGROUP.PathfindingMode.LOCAL) selects experimental rolling local navigation.
-- Normal route following continues until the collision check finds an obstacle; selecting LOCAL alone does not search.
-- The active detour searches a small, fine grid ahead and to either side, and submits only validated local waypoints.
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

--- Explicit native destination retained until the current mission waypoint changes.
-- This command stores no search grid or local plan; it lets collision checks follow GotoWaypoint correctly.
-- @type NAVYGROUP.LocalNavigationCommand
-- @field #number TargetUID Explicitly commanded native waypoint UID.
-- @field #number SourceUID Current waypoint UID when the native route was submitted.

--- Private local-navigation state. Native local points are not inserted into the mission waypoint list.
-- @type NAVYGROUP.LocalNavigation
-- @field #number TargetUID Original destination UID.
-- @field Ops.OpsGroup#OPSGROUP.Waypoint Target Original destination object.
-- @field Core.Vector#VECTOR TargetPosition Snapshot used to detect destination edits.
-- @field #number SourceUID Last passed mission waypoint when this leg began.
-- @field #boolean Commanded Whether an explicit UpdateRoute start index selected this destination.
-- @field #table Path VECTOR positions of the installed local polyline, including its original start.
-- @field #table Distances Cumulative horizontal distances along Path in meters.
-- @field #number Segment Current contiguous path segment.
-- @field #number Progress Monotonic distance travelled along Path in meters.
-- @field #number Length Total path length in meters.
-- @field #number ExtensionAfter Minimum actual progress before requesting another continuation, in meters.
-- @field #number Speed Commanded speed in meters per second.
-- @field #number Alt Native route altitude in meters (negative for submerged travel).
-- @field #number Revision Identifier of the last installed local route.
-- @field #boolean GoalReached Whether the installed path ends at the original destination.
-- @field #boolean GoalReported Whether DCS reported that destination; actual position still decides arrival.
-- @field #table Window Cached local GRID and ASTAR, owned by this navigation leg.
-- @field #table Pending Validated continuation awaiting a stable heading before submission.
-- @field #boolean NeedsSubmit Explicit speed/depth or route update awaiting a stable heading.

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

  -- Sample heading and route clearance independently of the general status update.
  self.timerNavigation=TIMER:New(self._CheckNavigation, self):Start(2, 10)

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
-- Uses terrain profiles to check minimum water depth along the center and both edges of the corridor.
-- Failed searches stop the ship until a new movement command is issued; there is no automatic retry.
-- Search grids use GRID.Resolution.FINE with GRID.Width.NORMAL and GRID.Margin.NORMAL; no grid dimensions are required.
-- SetPathfindingMinDepth() configures depth separately. Profiles assume linear terrain between their points;
-- three parallel checks do not cover the entire corridor or simulate the ship's turning arc.
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
-- LOCAL uses an approximately 4 by 2 km hex window with FINE resolution (50 m spacing), at most eight
-- intermediate goals and the configured cell budget. It does not expand to find a global escape route.
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
  self.localNavigationCommand=nil
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
-- The new depth is used at the next navigation check outside a turn. Stopped ships remain stopped.
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
-- @param #number offset (Optional) Offset angle clock-wise in degrees, *e.g.* to account for an angled runway. Default 0 deg. Use around -9.1° for US carriers.
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

  -- A completed local leg may have queued waypoint tasks whose native startup callback is still pending.
  -- Ordinary route updates must not overwrite those tasks while waiting for them to start or finish.
  if self.localNavigationTaskUID then
    if not self:_CanNavigate() or self:CountTasksWaypoint(self.localNavigationTaskUID)>0 then return end
    self.localNavigationTaskUID=nil
  end

  -- Only an active avoidance route owns the local frontier. Selecting LOCAL alone leaves the native route intact.
  if self.pathfindingOn and self.pathfindingMode=="local" and self.localNavigation then
    self:_CheckLocalNavigation(true,Speed,Depth,n)
    return
  end

  -- GotoWaypoint does not advance currentwp. Retain its explicit destination for later collision checks
  -- and speed/depth updates until a waypoint callback advances the mission route.
  if self.pathfindingMode=="local" then
    if n then
      local target=self.waypoints[n]
      self.localNavigationCommand=target and {TargetUID=target.uid,SourceUID=self:GetWaypointCurrentUID()} or nil
    else
      local target=self:_GetNavigationWaypoint()
      n=target and self:GetWaypointIndex(target.uid)
    end
  end

  -- Update route from this waypoint number onwards.
  n=n or self:GetWaypointIndexNext()
  
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

  -- This command replaces the native task as well as its route. A cancelled task-start callback
  -- must not keep a later explicit Cruise blocked behind the local startup guard.
  self.localNavigationTaskUID=nil
  self.localNavigationCommand=nil
  if self.localNavigation then
    self:_ResetLocalNavigation()
  end

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

--- Resolve the next native destination, including an explicit GotoWaypoint command in LOCAL mode.
-- The override expires when mission progress changes or its waypoint is removed.
-- @param #NAVYGROUP self
-- @return Ops.OpsGroup#OPSGROUP.Waypoint Next native waypoint, or nil.
function NAVYGROUP:_GetNavigationWaypoint()

  local command=self.localNavigationCommand
  if command and command.SourceUID==self:GetWaypointCurrentUID() then
    local waypoint=self:GetWaypointByID(command.TargetUID)
    if waypoint then return waypoint end
  end

  self.localNavigationCommand=nil
  return self:GetWaypointNext()
end

--- Check the upcoming route every ten seconds while the ship is not turning.
-- Examines at most 5000 meters towards the next waypoint. A blocked connection triggers one search
-- when pathfinding is enabled; failed planning stops the ship without automatic retries.
-- @param #NAVYGROUP self
function NAVYGROUP:_CheckNavigation()

  -- Read live headings here; the general status timer only samples every thirty seconds.
  self:_CheckTurning()

  -- Once a local destination's tasks finish, resume the ordinary route exactly once. Tasks at later
  -- waypoints can keep OPSGROUP's general completion handler from issuing that route update itself.
  if self.localNavigationTaskUID then
    if not self:_CanNavigate() or self:CountTasksWaypoint(self.localNavigationTaskUID)>0 then return end
    self.localNavigationTaskUID=nil
    self:__UpdateRoute(0.01)
    return
  end

  if self.pathfindingOn and self.pathfindingMode=="local" and self.localNavigation then
    self:_CheckLocalNavigation()
    return
  end

  if not self:_CanNavigate() or self:IsTurning() then
    return
  end

  local waypoint=self:_GetNavigationWaypoint()
  if not waypoint then
    return
  end
  local command=self.localNavigationCommand
  local mode=self.pathfindingMode
  local targetX,targetZ=waypoint.coordinate.x,waypoint.coordinate.z

  local position=VECTOR:NewFromVec(self:GetVec3())
  local goal=VECTOR:NewFromVec(waypoint.coordinate)
  local distance=position:GetDistance(goal,true)

  if distance>5000 then
    local fraction=5000/distance
    goal=VECTOR:New(position.x+(goal.x-position.x)*fraction,position.y,position.z+(goal.z-position.z)*fraction)
  end

  local clear,reason,report=self:_CheckPathDepth(position,goal)
  self:_UpdateNavigationWarning(report)

  -- Warning callbacks may disable pathfinding, stop the ship or change the route.
  if not self.pathfindingOn or not self:_CanNavigate() or self:_GetNavigationWaypoint()~=waypoint
    or self.localNavigationCommand~=command or self.pathfindingMode~=mode or self.localNavigation
    or waypoint.coordinate.x~=targetX or waypoint.coordinate.z~=targetZ then
    return
  end

  if report.Status=="unavailable" then
    -- Missing terrain data is not an obstacle that a larger grid can resolve.
    self:_FailPathfinding({StopReason=reason,Attempts={},DepthCheck=report})
  elseif not clear then
    if self.pathfindingMode=="local" then
      -- Activation happens only here, after an obstacle was measured on the native route.
      -- Keep the submitted speed and depth when handing navigation to the local planner.
      self:_CheckLocalNavigation(true,nil,self.altWp and -self.altWp,command and self:GetWaypointIndex(waypoint.uid))
    else
      self:_FindPathToNextWaypoint()
    end
  end
end

--- Get or rebuild the fixed grid used by local naval navigation.
-- The heading-aligned window extends 3 km ahead, 1 km behind and 1 km to either side of its origin.
-- Geometry and edge rules stay unchanged while reused. Progress, heading, target or configuration changes rebuild it.
-- @param #NAVYGROUP self
-- @param Core.Vector#VECTOR Start Actual ship position.
-- @param #number Heading Current heading in degrees.
-- @param Ops.OpsGroup#OPSGROUP.Waypoint Target Next original mission waypoint.
-- @return #table Window with Grid, Search, Origin, Heading and fixed navigation settings, or nil.
-- @return #string Grid construction failure reason, or nil.
function NAVYGROUP:_GetLocalNavigationWindow(Start, Heading, Target)

  self.localNavigation=self.localNavigation or {}

  local window=self.localNavigation.Window
  local target=VECTOR:NewFromVec(Target.coordinate)
  local minDepth=self.pathMinDepth or 20
  local corridorWidth=self:_GetPathfindingCorridorWidth()
  local maxCells=self.pathMaxCells or 5000

  if window then
    local dx,dz=Start.x-window.Origin.x,Start.z-window.Origin.z
    local along=dx*window.Cos+dz*window.Sin
    local across=-dx*window.Sin+dz*window.Cos
    local turn=math.abs((Heading-window.Heading+180)%360-180)
    local sameTarget=window.TargetUID==Target.uid and window.Target:GetDistance(target,true)<1

    if sameTarget and window.MinDepth==minDepth and window.CorridorWidth==corridorWidth
      and window.MaxCells==maxCells and Start:GetDistance(window.Origin,true)<1000 and turn<=30
      and along>-800 and along<2800 and math.abs(across)<800 then
      return window
    end
  end

  local grid=GRID:New("NAVYGROUP local",GRID.Type.HEXAGON)
  grid:SetResolution(GRID.Resolution.FINE)
  grid:SetCorridor(2000,0)
  grid:SetMaxCells(maxCells)
  grid:SetValidSurfaceTypes({land.SurfaceType.WATER,land.SurfaceType.SHALLOW_WATER})

  local built,reason=grid:CreateFromBounds(Start:Translate(1000,Heading+180,true),Start:Translate(3000,Heading,true))

  if not built then
    self.localNavigation.Window=nil
    return nil,reason
  end

  local search=ASTAR:New():SetGrid(grid)
  search:SetValidNeighbourDepth(minDepth,corridorWidth)

  window={Grid=grid,Search=search,Origin=Start:Copy(),Heading=Heading,
    Cos=math.cos(math.rad(Heading)),Sin=math.sin(math.rad(Heading)),TargetUID=Target.uid,Target=target,
    MinDepth=minDepth,CorridorWidth=corridorWidth,MaxCells=maxCells,Spacing=grid:GetResolutionInfo().Spacing,
    Ahead=3000,Behind=1000,Width=2000}
  self.localNavigation.Window=window

  return window
end

--- Choose at most eight exact-goal or geometric boundary exits in one local window.
-- The boundary band follows the front and sides of the window, never the shoreline of filtered water cells.
-- The original waypoint biases candidate order but candidates may increase the distance to it.
-- @param #NAVYGROUP self
-- @param #table Window Fixed local navigation window.
-- @param Core.Vector#VECTOR Start Actual ship position.
-- @param #number Heading Current heading in degrees.
-- @param Ops.OpsGroup#OPSGROUP.Waypoint Target Next original mission waypoint.
-- @return #table Candidate records containing Vector and GoalReached.
function NAVYGROUP:_GetLocalNavigationCandidates(Window, Start, Heading, Target)

  local goal=VECTOR:NewFromVec(Target.coordinate)
  local dx,dz=goal.x-Window.Origin.x,goal.z-Window.Origin.z
  local along=dx*Window.Cos+dz*Window.Sin
  local across=-dx*Window.Sin+dz*Window.Cos
  local candidates={}

  if along>=-Window.Behind and along<=Window.Ahead and math.abs(across)<=Window.Width/2 then
    candidates[1]={Vector=goal,GoalReached=true}
  end

  -- Keep this filtered band with the window; its geometry and minimum-depth rule do not change on reuse.
  if not Window.ExitCells then
    Window.ExitCells={}

    for _,cell in ipairs(Window.Grid:GetCells()) do
      local x,z=cell.vector.x-Window.Origin.x,cell.vector.z-Window.Origin.z
      local a=x*Window.Cos+z*Window.Sin
      local c=-x*Window.Sin+z*Window.Cos

      local front=a>=Window.Ahead-3*Window.Spacing

      if a>=250 and (front or math.abs(c)>=Window.Width/2-3*Window.Spacing) then
        -- Point depth alone admits bank-adjacent exits that can only be approached sideways.
        -- Require clearance for a short approach from inside the window towards this boundary.
        local heading=front and Window.Heading or Window.Heading+(c>=0 and 90 or -90)
        local approach=cell.vector:Translate(-2*Window.Spacing,heading,true)

        if self:_CheckPathDepth(approach,cell.vector) then
          Window.ExitCells[#Window.ExitCells+1]={Cell=cell,Along=a,Across=c}
        end
      end
    end
  end

  local anchors={{3000,-750},{3000,-250},{3000,250},{3000,750},{500,-1000},{1800,-1000},{500,1000},{1800,1000}}
  local exits,used={},{}
  local cos,sin=math.cos(math.rad(Heading)),math.sin(math.rad(Heading))

  for _,anchor in ipairs(anchors) do
    local nearest,bestDistance

    for _,entry in ipairs(Window.ExitCells) do
      local point=entry.Cell.vector
      local forward=(point.x-Start.x)*cos+(point.z-Start.z)*sin
      local distance=(entry.Along-anchor[1])^2+(entry.Across-anchor[2])^2

      if not used[entry.Cell.id] and forward>=250 and point:GetDistance(Start,true)>=500
        and (not bestDistance or distance<bestDistance) then
        nearest,bestDistance=entry,distance
      end
    end

    if nearest and bestDistance<=750^2 then
      used[nearest.Cell.id]=true
      local point=VECTOR:New(nearest.Cell.vector.x,goal.y,nearest.Cell.vector.z)
      local forward=(point.x-Start.x)*cos+(point.z-Start.z)*sin
      exits[#exits+1]={Vector=point,GoalReached=false,
        Score=0.35*point:GetDistance(goal,true)-0.25*forward,ID=nearest.Cell.id}
    end
  end

  table.sort(exits,function(a,b)
    if a.Score==b.Score then return a.ID<b.ID end
    return a.Score<b.Score
  end)

  for _,candidate in ipairs(exits) do
    if #candidates==8 then break end
    candidates[#candidates+1]=candidate
  end

  return candidates
end

--- Simplify a local grid path into corridor-checked steering points.
-- Every shortcut is checked again, including the actual ship position. Legs are limited to 1 km.
-- The first leg turns at most 75 degrees; later corners turn at most 90 degrees. This is no turning-radius model.
-- @param #NAVYGROUP self
-- @param Core.Vector#VECTOR Start Actual ship position.
-- @param #number Heading Current heading in degrees.
-- @param #table Path Ordered ASTAR nodes excluding start and including the selected endpoint.
-- @param #boolean GoalReached Whether the endpoint is the original mission waypoint.
-- @param #number Speed Requested speed in meters per second.
-- @param #number Altitude Original waypoint altitude or submarine depth.
-- @return #table VECTOR steering points excluding start and including the endpoint, or nil.
-- @return #string Failure reason, or nil.
function NAVYGROUP:_SimplifyLocalPath(Start, Heading, Path, GoalReached, Speed, Altitude)

  if #Path==0 then
    if GoalReached and self:_CheckPathDepth(Start,Start) then return {} end
    return nil,"no_progress"
  end

  local points={}
  local position,index=Start,0
  local minLeg=math.max(100,math.min((Speed or 0)*10,250))

  while index<#Path do
    local selected,selectedHeading

    for nextIndex=#Path,index+1,-1 do
      local point=Path[nextIndex].vector
      local distance=position:GetDistance(point,true)
      local course=position:GetHeadingTo(point)
      local turn=math.abs((course-Heading+180)%360-180)
      local shortGoal=GoalReached and nextIndex==#Path
      local remaining=point:GetDistance(Path[#Path].vector,true)

      if distance>0.1 and distance<=1000 and (distance>=minLeg or shortGoal)
        and (nextIndex==#Path or GoalReached or remaining>=minLeg)
        and turn<=(index==0 and 75 or 90) and self:_CheckPathDepth(position,point) then
        selected,selectedHeading=nextIndex,course
        break
      end
    end

    if not selected then return nil,"no_steering_path" end

    local point=Path[selected].vector
    position=VECTOR:New(point.x,Altitude,point.z)
    points[#points+1]=position
    index,Heading=selected,selectedHeading
  end

  return points
end

--- Plan one bounded local route without changing the ship's waypoints.
-- Reuses one ASTAR instance and its depth-edge caches for all candidates. It never expands the grid.
-- A candidate can steer away from the original target; no global search or dead-end recovery is attempted.
-- @param #NAVYGROUP self
-- @param Core.Vector#VECTOR Start Actual ship position; also accepts Vec3 or COORDINATE.
-- @param #number Heading Current heading in degrees.
-- @param Ops.OpsGroup#OPSGROUP.Waypoint Target Next original mission waypoint.
-- @param #number Speed Requested speed in meters per second.
-- @return #table Plan with Points, GoalReached, Window, raw Path and diagnostic fields, or nil.
-- @return #string Failure reason, or nil.
function NAVYGROUP:_PlanLocalPath(Start, Heading, Target, Speed)

  Start=VECTOR:NewFromVec(Start)

  local previous=self.localNavigation and self.localNavigation.Window
  local window,reason=self:_GetLocalNavigationWindow(Start,Heading,Target)

  if not window then return nil,reason end

  local candidates=self:_GetLocalNavigationCandidates(window,Start,Heading,Target)
  local search=window.Search
  local best,attempts=nil,0
  local cos,sin=math.cos(math.rad(Heading)),math.sin(math.rad(Heading))

  search:SetStartCoordinate(Start)

  for _,candidate in ipairs(candidates) do
    search:SetEndCoordinate(candidate.Vector)
    attempts=attempts+1

    -- Failed candidate attempts are expected. The internal search avoids public final-failure messages.
    local path,failure=search:_SearchPath(true,false)
    reason=failure or reason

    if path then
      local points,steeringFailure=self:_SimplifyLocalPath(Start,Heading,path,candidate.GoalReached,Speed,Target.coordinate.y)
      reason=steeringFailure or reason

      if points then
        local length,turns,position,course=0,0,Start,Heading

        for _,point in ipairs(points) do
          local heading=position:GetHeadingTo(point)
          length=length+position:GetDistance(point,true)
          turns=turns+math.abs((heading-course+180)%360-180)
          position,course=point,heading
        end

        local distance=Start:GetDistance(position,true)
        local forward=(position.x-Start.x)*cos+(position.z-Start.z)*sin
        local score=length-distance+0.35*position:GetDistance(window.Target,true)-0.25*forward+2*turns

        if candidate.GoalReached or (distance>=500 and forward>=250 and (not best or score<best.Score)) then
          best={Points=points,GoalReached=candidate.GoalReached,Window=window,Path=path,Score=score,
            StopReason="path_found",MinDepth=window.MinDepth,CorridorWidth=window.CorridorWidth,
            Spacing=window.Spacing,CandidateCount=window.Grid:GetCandidateCount(),WindowReused=window==previous}

          if candidate.GoalReached then break end
        end
      end
    end
  end

  if best then
    best.Attempts=attempts
    return best
  end

  return nil,reason or (#candidates==0 and "no_local_exit" or "no_local_path")
end


--- Discard local plans and invalidate callbacks from previously submitted local routes.
-- Does not issue a movement command or release Holding/Waiting.
-- @param #NAVYGROUP self
-- @return #NAVYGROUP self.
function NAVYGROUP:_ResetLocalNavigation()

  self.localNavigationRevision=(self.localNavigationRevision or 0)+1
  self.localNavigation=nil
  self.ispathfinding=false
  self:_ClearPathfindingDrawing()
  return self
end

--- Record a native goal notification without advancing the mission route prematurely.
-- DCS may notify hundreds of meters before arrival. The navigation timer delegates the normal
-- OPSGROUP waypoint event only after the ship actually reaches the original destination.
-- @param #NAVYGROUP Group Executing naval group.
-- @param #number Revision Identifier captured by the submitted local route.
-- @return #nil No return value.
function NAVYGROUP._LocalWaypointPassed(Group, Revision)

  local navigation=Group and Group.localNavigation
  if navigation and navigation.Revision==Revision and navigation.GoalReached
    and Group.pathfindingOn and Group.pathfindingMode=="local" then
    navigation.GoalReported=true
  end
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

    -- DCS rounds corners before crossing the old leg's endpoint plane. Consider only the immediately
    -- following leg, and only near this corner, so nearby return legs of a hairpin cannot steal progress.
    if not advance and segment<#path-1 and Position:GetDistance(b,true)<=math.max(500,(navigation.Speed or 0)*30) then
      local c=path[segment+2]
      local nx,nz=c.x-b.x,c.z-b.z
      local square=nx*nx+nz*nz
      local nextFraction=square>0 and ((Position.x-b.x)*nx+(Position.z-b.z)*nz)/square or 0
      if nextFraction>0 and nextFraction<=1 then
        local nextDeviation=math.sqrt((Position.x-b.x-nextFraction*nx)^2+(Position.z-b.z-nextFraction*nz)^2)
        advance=nextDeviation<deviation
      end
    end

    if segment<#path-1 and advance then
      segment=segment+1
    else
      break
    end
  end

  navigation.Segment=segment
  navigation.Progress=math.max(navigation.Progress or 0,along)
  return navigation.Progress,math.max(0,navigation.Length-navigation.Progress),deviation
end

--- Complete a local leg through the normal waypoint and mission-task lifecycle.
-- Clear the local route first because waypoint callbacks can issue new movement commands.
-- Completion never overwrites a waypoint task with an extra stop command.
-- @param #NAVYGROUP self
-- @return #boolean True after dispatching the original waypoint event.
function NAVYGROUP:_CompleteLocalLeg()

  local uid=self.localNavigation.TargetUID
  self:_ResetLocalNavigation()
  self.localNavigationCommand=nil
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
  if not clear then return clear,reason,report end

  local from=self:IsTurning() and navigation.Path[navigation.Segment] or Position
  for i=navigation.Segment+1,#navigation.Path do
    clear,reason,report=self:_CheckPathDepth(from,navigation.Path[i])
    if not clear then return clear,reason,report end
    from=navigation.Path[i]
  end

  return clear,reason,report
end

--- Build a continuation while preserving roughly one kilometer of the currently installed route.
-- The preserved points give DCS a stable approach to the next turn. Planning starts at that anchor,
-- using its incoming course rather than the bearing to the distant mission waypoint.
-- @param #NAVYGROUP self
-- @param Core.Vector#VECTOR Position Actual ship position.
-- @return #table Proposed VECTOR path including its start, or nil on failure.
-- @return #table Planning report, or nil on failure.
-- @return #string Failure reason, or nil on success.
function NAVYGROUP:_ExtendLocalRoute(Position)

  local navigation=self.localNavigation
  local points={Position}
  local heading=self:GetHeading()
  local distance=0

  if navigation.Path then
    for i=navigation.Segment+1,#navigation.Path do
      local point=navigation.Path[i]
      local previous=points[#points]
      local length=previous:GetDistance(point,true)
      if length>1 then
        distance=distance+length
        points[#points+1]=point
      end
      if distance>=1000 then break end
    end
    if #points>1 then
      heading=points[#points-1]:GetHeadingTo(points[#points])
    end
  end

  local plan,reason=self:_PlanLocalPath(points[#points],heading,navigation.Target,navigation.Speed)
  if not plan then return nil,nil,reason end

  for _,point in ipairs(plan.Points) do
    points[#points+1]=VECTOR:New(point.x,navigation.Alt,point.z)
  end
  return points,plan
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
  navigation.Path=Points
  navigation.Distances={0}
  navigation.Length=0
  navigation.Segment=1
  navigation.Progress=0
  navigation.GoalReached=Plan.GoalReached
  navigation.Pending=nil

  for i=2,#Points do
    navigation.Length=navigation.Length+Points[i-1]:GetDistance(Points[i],true)
    navigation.Distances[i]=navigation.Length
  end
  navigation.ExtensionAfter=math.min(250,navigation.Length*0.1)
  self:_LocalRouteProgress(Position)

  self.LastPathfindingResult=Plan
  self.ispathfinding=true
  local submitted=self:_SubmitLocalRoute(Position)

  if submitted and self.verbose>=10 and Plan.Window then
    self:_ClearPathfindingDrawing()
    self.pathfindingDebugSearch=Plan.Window.Search
    Plan.Window.Search:DrawGridWithPath(Plan.Path)
  end
  return submitted
end

--- Submit the validated remainder of the local route to DCS.
-- The original destination is included only when reached by this plan. Its regular waypoint event
-- and queued tasks are dispatched on actual arrival, not by DCS's early waypoint notification.
-- @param #NAVYGROUP self
-- @param Core.Vector#VECTOR Position Actual ship position.
-- @return #boolean True when submitted; false if navigation changed or the connector is invalid.
function NAVYGROUP:_SubmitLocalRoute(Position)

  local navigation=self.localNavigation
  if not navigation or not self:_CanNavigate() then return false end

  local remaining=navigation.Length-navigation.Progress
  local reserve=math.max(400,navigation.Speed*60)+navigation.Speed*10
  if not navigation.GoalReached and remaining<=reserve then
    return self:_FailPathfinding({StopReason="local_route_too_short",Remaining=remaining,Mode="local"})
  end

  local nextPoint=navigation.Path[navigation.Segment+1]
  local clear,reason,report=self:_CheckPathDepth(Position,nextPoint)
  if clear then
    -- A continuation may have waited through a turn while minimum depth or corridor settings changed.
    -- Revalidate the whole submitted remainder, not only its first connector.
    clear,reason,report=self:_CheckLocalRoute(Position)
  end
  self:_UpdateNavigationWarning(report)
  if self.localNavigation~=navigation or not self:_CanNavigate() then return false end
  if not clear then return self:_FailPathfinding({StopReason=reason,DepthCheck=report}) end

  -- Switching from the waypoint planner may leave its temporary detour in the stored route.
  -- Remove it only after the replacement passed validation; it must not reappear on a later patrol lap.
  for i=#self.waypoints,1,-1 do
    local waypoint=self.waypoints[i]
    if waypoint.astar and waypoint~=navigation.Target then self:RemoveWaypointByID(waypoint.uid,false) end
  end
  navigation.SourceUID=self:GetWaypointCurrentUID()

  self.localNavigationRevision=(self.localNavigationRevision or 0)+1
  navigation.Revision=self.localNavigationRevision
  navigation.GoalReported=false
  local speed=navigation.Speed*3.6
  local route={UTILS.VecWaypointNaval(Position,speed,navigation.Alt)}

  for i=navigation.Segment+1,#navigation.Path do
    local waypoint=UTILS.VecWaypointNaval(navigation.Path[i],speed,navigation.Alt)
    if i==#navigation.Path and navigation.GoalReached then
      -- Only the notification wrapper belongs to the native route. OPSGROUP still owns all waypoint tasks.
      waypoint.uid=navigation.TargetUID
      waypoint.task.params.tasks={self:_SimpleTaskFunction("NAVYGROUP._LocalWaypointPassed",navigation.Revision)}
    end
    route[#route+1]=waypoint
  end

  self.speedWp=navigation.Speed
  self.altWp=navigation.Alt
  navigation.NeedsSubmit=nil
  self:T(self.lid..string.format("Local navigation: target UID %d, %d route points, %.0f m validated, goal=%s",
    navigation.TargetUID,#route,navigation.Length-navigation.Progress,tostring(navigation.GoalReached)))
  self:Route(route)
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

  if not self:_CanNavigate() then return false end

  if self.localNavigationTaskUID then
    if self:CountTasksWaypoint(self.localNavigationTaskUID)>0 then return false end
    self.localNavigationTaskUID=nil
  end

  local navigation=self.localNavigation
  local target
  if First then
    target=self:_GetPathfindingTarget(First)
  elseif navigation and navigation.Commanded and self:GetWaypointCurrentUID()==navigation.SourceUID then
    target=self:GetWaypointByID(navigation.TargetUID)
  else
    target=self:_GetPathfindingTarget()
  end
  if not target then return self:_FailPathfinding({StopReason="local_missing_target"}) end

  local position=VECTOR:NewFromVec(self:GetVec3())
  local changed=not navigation or navigation.Target~=target
    or navigation.TargetPosition.x~=target.coordinate.x or navigation.TargetPosition.z~=target.coordinate.z

  if changed and navigation and navigation.Target then
    -- A new or edited destination is a new native leg. Do not carry avoidance over to it without
    -- first detecting an obstacle there; subsequent timer ticks will examine the replacement route.
    self:_ResetLocalNavigation()
    self:__UpdateRoute(0.01,First,nil,Speed,Depth)
    return false
  end

  if changed then
    self:_ResetLocalNavigation()
    navigation={TargetUID=target.uid,Target=target,TargetPosition=VECTOR:NewFromVec(target.coordinate),
      SourceUID=self:GetWaypointCurrentUID(),Commanded=First~=nil}
    self.localNavigation=navigation
  elseif First then
    navigation.Commanded=true
  end

  navigation.Speed=Speed and UTILS.KnotsToMps(Speed) or navigation.Speed or self.speedWp or target.speed
  if not navigation.Speed or navigation.Speed<=0 then navigation.Speed=UTILS.KnotsToMps(self:GetSpeedCruise()) end
  if Force or not navigation.Alt then
    navigation.Alt=Depth and -Depth or (self.depth and -self.depth) or target.coordinate.y
  end
  navigation.NeedsSubmit=navigation.NeedsSubmit or Force

  if not navigation.Path then
    -- A resumed ship may already be at its destination. Avoid constructing a zero-length native route.
    if position:GetDistance(navigation.TargetPosition,true)<=50 then
      local clear,reason,report=self:_CheckPathDepth(position,navigation.TargetPosition)
      self:_UpdateNavigationWarning(report)
      if self.localNavigation~=navigation or not self:_CanNavigate() then return false end
      if not clear then return self:_FailPathfinding({StopReason=reason,DepthCheck=report,Mode="local"}) end
      return self:_CompleteLocalLeg()
    end

    local points,plan,reason=self:_ExtendLocalRoute(position)
    if self.localNavigation~=navigation or not self:_CanNavigate() then return false end
    if not points then return self:_FailPathfinding({StopReason=reason,Mode="local"}) end
    return self:_InstallLocalRoute(points,plan,position)
  end

  local progress,remaining,deviation=self:_LocalRouteProgress(position)
  local clear,reason,report=self:_CheckLocalRoute(position)
  self:_UpdateNavigationWarning(report)
  if self.localNavigation~=navigation or not self:_CanNavigate() then return false end
  if not clear then return self:_FailPathfinding({StopReason=reason,DepthCheck=report,Mode="local"}) end

  local arrival=math.max(50,math.min(150,navigation.Speed*10))
  if navigation.GoalReached and remaining<=arrival and position:GetDistance(navigation.TargetPosition,true)<=arrival then
    return self:_CompleteLocalLeg()
  end

  if deviation>math.max(150,self:_GetPathfindingCorridorWidth()) then
    return self:_FailPathfinding({StopReason="local_route_deviation",Deviation=deviation,Mode="local"})
  end

  -- Reserve is a conservative prototype margin, not a measured DCS stopping-distance model.
  local reserve=math.max(400,navigation.Speed*60)
  if not navigation.GoalReached and remaining<=reserve and self:IsTurning() then
    return self:_FailPathfinding({StopReason="local_route_exhausted_in_turn",Remaining=remaining,Mode="local"})
  end

  if not navigation.GoalReached and remaining<=math.max(2000,reserve+1000)
    and (navigation.Pending or progress>=navigation.ExtensionAfter) then
    if not navigation.Pending then
      local points,plan,failure=self:_ExtendLocalRoute(position)
      if self.localNavigation~=navigation or not self:_CanNavigate() then return false end
      if not points then return self:_FailPathfinding({StopReason=failure,Mode="local"}) end
      navigation.Pending={Points=points,Plan=plan}
    end
    if not self:IsTurning() then
      return self:_InstallLocalRoute(navigation.Pending.Points,navigation.Pending.Plan,position)
    end
  end

  if navigation.NeedsSubmit and not self:IsTurning() then return self:_SubmitLocalRoute(position) end
  return true
end

--- Find and install a detour to the next original route waypoint.
-- Temporary ASTAR points are replaced only after a complete path has been found. The original target
-- and its waypoint tasks remain in the route. Failure stops the ship until a new movement command.
-- @param #NAVYGROUP self
-- @return #boolean True when a route was installed; false on failure or when navigation is inactive.
function NAVYGROUP:_FindPathToNextWaypoint()

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

  local astar=ASTAR:New()
  astar:SetStartCoordinate(position)
  astar:SetEndCoordinate(goal)
  astar:SetValidSurfaceTypes({land.SurfaceType.WATER,land.SurfaceType.SHALLOW_WATER})
  astar:SetValidNeighbourDepth(minDepth,corridorWidth)

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

  local built,reason=astar:CreateHexGrid()
  local path,report

  if built then
    -- The current position and the original target are already represented by the installed route.
    path,report=astar:GetPathWithExpansion(true,true)
  else
    report={StopReason=reason,Attempts={}}
  end

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
  local uid=current and current.uid
  local speed=self.speedWp or target.speed
  speed=speed and speed>0 and UTILS.MpsToKnots(speed) or self:GetSpeedCruise()

  for _,node in ipairs(path) do
    -- Grid altitude is terrain height. Naval waypoints retain the original route's altitude/depth.
    local point=VECTOR:New(node.vector.x,target.coordinate.y,node.vector.z)
    local waypoint=self:AddWaypoint(point,speed,uid,nil,false)
    waypoint.astar=true
    waypoint.astarTargetUID=target.uid
    uid=waypoint.uid
  end

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
    
    -- Set theta to 90°
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
  self:T(self.lid..string.format("Heading into Wind: vship=%.1f, vwind=%.1f, WindTo=%03.0f°, Theta=%03.0f°, Heading=%03.0f", v, vwind, windto, math.deg(theta), intowind))
  
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
-- @param #number First (Optional) First native waypoint index. Defaults to the next mission waypoint.
-- @return Ops.OpsGroup#OPSGROUP.Waypoint Original target, or nil.
-- @return #table IDs of outstanding detour points before that target.
function NAVYGROUP:_GetPathfindingTarget(First)
  local pending={}
  local index=First or self:GetWaypointIndexNext()
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

--- Remove this group's previous pathfinding overlay and cancel its pending drawing batches.
-- Leaves other groups' drawings and unrelated map marks untouched.
-- @param #NAVYGROUP self
-- @return #NAVYGROUP self.
function NAVYGROUP:_ClearPathfindingDrawing()
  if self.pathfindingDebugSearch then
    self.pathfindingDebugSearch:UndrawGrid()
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
  self:E(self.lid.."Naval pathfinding failed: "..tostring(Report.StopReason).." ==> FullStop")
  self:FullStop()

  return false
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
