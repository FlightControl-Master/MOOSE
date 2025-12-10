--- **Ops** - Enhanced Ground Group.
--
-- ## Main Features:
--
--    * Patrol waypoints *ad infinitum*
--    * Easy change of ROE and alarm state, formation and other settings
--    * Dynamically add and remove waypoints
--    * Sophisticated task queueing system  (know when DCS tasks start and end)
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
-- Demo missions can be found on [GitHub](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/develop/Ops/Armygroup).
--
-- ===
--
-- ### Author: **funkyfranky**
--
-- ==
-- @module Ops.ArmyGroup
-- @image OPS_ArmyGroup.png


--- ARMYGROUP class.
-- @type ARMYGROUP
-- @field #boolean adinfinitum Resume route at first waypoint when final waypoint is reached.
-- @field #boolean formationPerma Formation that is used permanently and overrules waypoint formations.
-- @field #boolean isMobile If true, group is mobile.
-- @field #ARMYGROUP.Target engage Engage target.
-- @field Core.Set#SET_ZONE retreatZones Set of retreat zones.
-- @field #boolean suppressOn Bla
-- @field #boolean isSuppressed Bla
-- @field #number TsuppressMin Bla
-- @field #number TsuppressMax Bla
-- @field #number TsuppressAve Bla
-- @extends Ops.OpsGroup#OPSGROUP

--- *Your soul may belong to Jesus, but your ass belongs to the marines.* -- Eugene B Sledge
--
-- ===
--
-- # The ARMYGROUP Concept
--
-- This class enhances ground groups.
--
-- @field #ARMYGROUP
ARMYGROUP = {
  ClassName       = "ARMYGROUP",
  formationPerma  = nil,
  engage          = {},
}

--- Engage Target.
-- @type ARMYGROUP.Target
-- @field Ops.Target#TARGET Target The target.
-- @field Core.Point#COORDINATE Coordinate Last known coordinate of the target.
-- @field Ops.OpsGroup#OPSGROUP.Waypoint Waypoint the waypoint created to go to the target.
-- @field #number Speed Speed in knots.
-- @field #string Formation Formation used in the engagement.
-- @field #number roe ROE backup.
-- @field #number alarmstate Alarm state backup.

--- Army Group version.
-- @field #string version
ARMYGROUP.version="1.0.3"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Suppression of fire.
-- TODO: Check if group is mobile.
-- TODO: F10 menu.
-- DONE: Retreat.
-- DONE: Rearm. Specify a point where to go and wait until ammo is full.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new ARMYGROUP class object.
-- @param #ARMYGROUP self
-- @param Wrapper.Group#GROUP group The GROUP object. Can also be given by its group name as `#string`.
-- @return #ARMYGROUP self
function ARMYGROUP:New(group)

  -- First check if we already have an OPS group for this group.
  local og=_DATABASE:GetOpsGroup(group)
  if og then
    og:I(og.lid..string.format("WARNING: OPS group already exists in data base!"))
    return og
  end

  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, OPSGROUP:New(group)) -- #ARMYGROUP

  -- Set some string id for output to DCS.log file.
  self.lid=string.format("ARMYGROUP %s | ", self.groupname)

  -- Defaults
  self:SetDefaultROE()
  self:SetDefaultAlarmstate()
  self:SetDefaultEPLRS(self.isEPLRS)
  self:SetDefaultEmission()
  self:SetDetection()
  self:SetPatrolAdInfinitum(false)
  self:SetRetreatZones()

  -- Add FSM transitions.
  --                 From State  -->   Event      -->     To State
  self:AddTransition("*",             "FullStop",         "Holding")     -- Hold position.
  self:AddTransition("*",             "Cruise",           "Cruising")    -- Cruise along the given route of waypoints.

  self:AddTransition("*",             "RTZ",              "Returning")   -- Group is returning to (home) zone.
  self:AddTransition("Holding",       "Returned",         "Returned")    -- Group is returned to (home) zone, e.g. when unloaded from carrier.
  self:AddTransition("Returning",     "Returned",         "Returned")    -- Group is returned to (home) zone.

  self:AddTransition("*",             "Detour",           "OnDetour")    -- Make a detour to a coordinate and resume route afterwards.
  self:AddTransition("OnDetour",      "DetourReached",    "Cruising")    -- Group reached the detour coordinate.

  self:AddTransition("*",             "Retreat",          "Retreating")  -- Order a retreat.
  self:AddTransition("Retreating",    "Retreated",        "Retreated")   -- Group retreated.

  self:AddTransition("*",             "Suppressed",       "*")           -- Group is suppressed
  self:AddTransition("*",             "Unsuppressed",     "*")           -- Group is unsuppressed.

  self:AddTransition("Cruising",      "EngageTarget",     "Engaging")    -- Engage a target from Cruising state
  self:AddTransition("Holding",       "EngageTarget",     "Engaging")    -- Engage a target from Holding state
  self:AddTransition("OnDetour",      "EngageTarget",     "Engaging")    -- Engage a target from OnDetour state
  self:AddTransition("Engaging",      "Disengage",        "Cruising")    -- Disengage and back to cruising.

  self:AddTransition("*",             "Rearm",            "Rearm")       -- Group is send to a coordinate and waits until ammo is refilled.
  self:AddTransition("Rearm",         "Rearming",         "Rearming")    -- Group has arrived at the rearming coodinate and is waiting to be fully rearmed.
  self:AddTransition("*",             "Rearmed",          "Cruising")    -- Group was rearmed.

  ------------------------
  --- Pseudo Functions ---
  ------------------------

  --- Triggers the FSM event "Cruise".
  -- @function [parent=#ARMYGROUP] Cruise
  -- @param #ARMYGROUP self
  -- @param #number Speed Speed in knots until next waypoint is reached.
  -- @param #number Formation Formation.

  --- Triggers the FSM event "Cruise" after a delay.
  -- @function [parent=#ARMYGROUP] __Cruise
  -- @param #ARMYGROUP self
  -- @param #number delay Delay in seconds.
  -- @param #number Speed Speed in knots until next waypoint is reached.
  -- @param #number Formation Formation.

  --- On after "Cruise" event.
  -- @function [parent=#ARMYGROUP] OnAfterCruise
  -- @param #ARMYGROUP self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #number Speed Speed in knots until next waypoint is reached.
  -- @param #number Formation Formation.


  --- Triggers the FSM event "FullStop".
  -- @function [parent=#ARMYGROUP] FullStop
  -- @param #ARMYGROUP self

  --- Triggers the FSM event "FullStop" after a delay.
  -- @function [parent=#ARMYGROUP] __FullStop
  -- @param #ARMYGROUP self
  -- @param #number delay Delay in seconds.

  --- On after "FullStop" event.
  -- @function [parent=#ARMYGROUP] OnAfterFullStop
  -- @param #ARMYGROUP self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.


  --- Triggers the FSM event "RTZ".
  -- @function [parent=#ARMYGROUP] RTZ
  -- @param #ARMYGROUP self

  --- Triggers the FSM event "RTZ" after a delay.
  -- @function [parent=#ARMYGROUP] __RTZ
  -- @param #ARMYGROUP self
  -- @param #number delay Delay in seconds.

  --- On after "RTZ" event.
  -- @function [parent=#ARMYGROUP] OnAfterRTZ
  -- @param #ARMYGROUP self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.


  --- Triggers the FSM event "Returned".
  -- @function [parent=#ARMYGROUP] Returned
  -- @param #ARMYGROUP self

  --- Triggers the FSM event "Returned" after a delay.
  -- @function [parent=#ARMYGROUP] __Returned
  -- @param #ARMYGROUP self
  -- @param #number delay Delay in seconds.

  --- On after "Returned" event.
  -- @function [parent=#ARMYGROUP] OnAfterReturned
  -- @param #ARMYGROUP self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.


  --- Triggers the FSM event "Detour".
  -- @function [parent=#ARMYGROUP] Detour
  -- @param #ARMYGROUP self

  --- Triggers the FSM event "Detour" after a delay.
  -- @function [parent=#ARMYGROUP] __Detour
  -- @param #ARMYGROUP self
  -- @param #number delay Delay in seconds.

  --- On after "Detour" event.
  -- @function [parent=#ARMYGROUP] OnAfterDetour
  -- @param #ARMYGROUP self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.


  --- Triggers the FSM event "DetourReached".
  -- @function [parent=#ARMYGROUP] DetourReached
  -- @param #ARMYGROUP self

  --- Triggers the FSM event "DetourReached" after a delay.
  -- @function [parent=#ARMYGROUP] __DetourReached
  -- @param #ARMYGROUP self
  -- @param #number delay Delay in seconds.

  --- On after "DetourReached" event.
  -- @function [parent=#ARMYGROUP] OnAfterDetourReached
  -- @param #ARMYGROUP self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.


  --- Triggers the FSM event "Retreat".
  -- @function [parent=#ARMYGROUP] Retreat
  -- @param #ARMYGROUP self
  -- @param Core.Zone#ZONE_BASE Zone (Optional) Zone where to retreat. Default is the closest retreat zone.
  -- @param #number Formation (Optional) Formation of the group.

  --- Triggers the FSM event "Retreat" after a delay.
  -- @function [parent=#ARMYGROUP] __Retreat
  -- @param #ARMYGROUP self
  -- @param Core.Zone#ZONE_BASE Zone (Optional) Zone where to retreat. Default is the closest retreat zone.
  -- @param #number Formation (Optional) Formation of the group.
  -- @param #number delay Delay in seconds.

  --- On after "Retreat" event.
  -- @function [parent=#ARMYGROUP] OnAfterRetreat
  -- @param #ARMYGROUP self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Core.Zone#ZONE_BASE Zone Zone where to retreat.
  -- @param #number Formation Formation of the group. Can be #nil.

  --- Triggers the FSM event "Retreated".
  -- @function [parent=#ARMYGROUP] Retreated
  -- @param #ARMYGROUP self

  --- Triggers the FSM event "Retreated" after a delay.
  -- @function [parent=#ARMYGROUP] __Retreated
  -- @param #ARMYGROUP self
  -- @param #number delay Delay in seconds.

  --- On after "Retreated" event.
  -- @function [parent=#ARMYGROUP] OnAfterRetreated
  -- @param #ARMYGROUP self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.


  --- Triggers the FSM event "EngageTarget".
  -- @function [parent=#ARMYGROUP] EngageTarget
  -- @param #ARMYGROUP self
  -- @param Ops.Target#TARGET Target The target to be engaged. Can also be a GROUP or UNIT object.
  -- @param #number Speed Speed in knots.
  -- @param #string Formation Formation used in the engagement.

  --- Triggers the FSM event "EngageTarget" after a delay.
  -- @function [parent=#ARMYGROUP] __EngageTarget
  -- @param #ARMYGROUP self
  -- @param #number delay Delay in seconds.
  -- @param Wrapper.Group#GROUP Group the group to be engaged.
  -- @param #number Speed Speed in knots.
  -- @param #string Formation Formation used in the engagement.


  --- On after "EngageTarget" event.
  -- @function [parent=#ARMYGROUP] OnAfterEngageTarget
  -- @param #ARMYGROUP self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Wrapper.Group#GROUP Group the group to be engaged.
  -- @param #number Speed Speed in knots.
  -- @param #string Formation Formation used in the engagement.


  --- Triggers the FSM event "Disengage".
  -- @function [parent=#ARMYGROUP] Disengage
  -- @param #ARMYGROUP self

  --- Triggers the FSM event "Disengage" after a delay.
  -- @function [parent=#ARMYGROUP] __Disengage
  -- @param #ARMYGROUP self
  -- @param #number delay Delay in seconds.

  --- On after "Disengage" event.
  -- @function [parent=#ARMYGROUP] OnAfterDisengage
  -- @param #ARMYGROUP self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.


  --- Triggers the FSM event "Rearm".
  -- @function [parent=#ARMYGROUP] Rearm
  -- @param #ARMYGROUP self
  -- @param Core.Point#COORDINATE Coordinate Coordinate where to rearm.
  -- @param #number Formation Formation of the group.

  --- Triggers the FSM event "Rearm" after a delay.
  -- @function [parent=#ARMYGROUP] __Rearm
  -- @param #ARMYGROUP self
  -- @param #number delay Delay in seconds.
  -- @param Core.Point#COORDINATE Coordinate Coordinate where to rearm.
  -- @param #number Formation Formation of the group.

  --- On after "Rearm" event.
  -- @function [parent=#ARMYGROUP] OnAfterRearm
  -- @param #ARMYGROUP self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Core.Point#COORDINATE Coordinate Coordinate where to rearm.
  -- @param #number Formation Formation of the group.


  --- Triggers the FSM event "Rearming".
  -- @function [parent=#ARMYGROUP] Rearming
  -- @param #ARMYGROUP self

  --- Triggers the FSM event "Rearming" after a delay.
  -- @function [parent=#ARMYGROUP] __Rearming
  -- @param #ARMYGROUP self
  -- @param #number delay Delay in seconds.

  --- On after "Rearming" event.
  -- @function [parent=#ARMYGROUP] OnAfterRearming
  -- @param #ARMYGROUP self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.


  --- Triggers the FSM event "Rearmed".
  -- @function [parent=#ARMYGROUP] Rearmed
  -- @param #ARMYGROUP self

  --- Triggers the FSM event "Rearmed" after a delay.
  -- @function [parent=#ARMYGROUP] __Rearmed
  -- @param #ARMYGROUP self
  -- @param #number delay Delay in seconds.

  --- On after "Rearmed" event.
  -- @function [parent=#ARMYGROUP] OnAfterRearmed
  -- @param #ARMYGROUP self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.


  -- TODO: Add pseudo functions.

  -- Init waypoints.
  self:_InitWaypoints()

  -- Initialize the group.
  self:_InitGroup()

  -- Handle events:
  self:HandleEvent(EVENTS.Birth,      self.OnEventBirth)
  self:HandleEvent(EVENTS.Dead,       self.OnEventDead)
  self:HandleEvent(EVENTS.RemoveUnit, self.OnEventRemoveUnit)
  self:HandleEvent(EVENTS.UnitLost,   self.OnEventRemoveUnit)
  self:HandleEvent(EVENTS.Hit,        self.OnEventHit)

  -- Start the status monitoring.
  self.timerStatus=TIMER:New(self.Status, self):Start(1, 30)

  -- Start queue update timer.
  self.timerQueueUpdate=TIMER:New(self._QueueUpdate, self):Start(2, 5)

  -- Start check zone timer.
  self.timerCheckZone=TIMER:New(self._CheckInZones, self):Start(2, 30)

  -- Add OPSGROUP to _DATABASE.
  _DATABASE:AddOpsGroup(self)

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

--- Get coordinate of the closest road.
-- @param #ARMYGROUP self
-- @return Core.Point#COORDINATE Coordinate of a road closest to the group.
function ARMYGROUP:GetClosestRoad()
  local coord=self:GetCoordinate():GetClosestPointToRoad()
  return coord
end

--- Get 2D distance to the closest road.
-- @param #ARMYGROUP self
-- @return #number Distance in meters to the closest road.
function ARMYGROUP:GetClosestRoadDist()
  local road=self:GetClosestRoad()
  if road then
    local dist=road:Get2DDistance(self:GetCoordinate())
    return dist
  end
  return math.huge
end


--- Add a *scheduled* task to fire at a given coordinate.
-- @param #ARMYGROUP self
-- @param Core.Point#COORDINATE Coordinate Coordinate of the target.
-- @param #string Clock Time when to start the attack.
-- @param #number Radius Radius in meters. Default 100 m.
-- @param #number Nshots Number of shots to fire. Default 3.
-- @param #number WeaponType Type of weapon. Default auto.
-- @param #number Prio Priority of the task.
-- @return Ops.OpsGroup#OPSGROUP.Task The task table.
function ARMYGROUP:AddTaskFireAtPoint(Coordinate, Clock, Radius, Nshots, WeaponType, Prio)

  Coordinate=self:_CoordinateFromObject(Coordinate)

  local DCStask=CONTROLLABLE.TaskFireAtPoint(nil, Coordinate:GetVec2(), Radius, Nshots, WeaponType)

  local task=self:AddTask(DCStask, Clock, nil, Prio)

  return task
end

--- Add a *scheduled* task to fire at a given coordinate.
-- @param #ARMYGROUP self
-- @param #string Clock Time when to start the attack.
-- @param #number Heading Heading min in Degrees.
-- @param #number Alpha Shooting angle in Degrees.
-- @param #number Altitude Altitude in meters.
-- @param #number Radius Radius in meters. Default 100 m.
-- @param #number Nshots Number of shots to fire. Default nil.
-- @param #number WeaponType Type of weapon. Default auto.
-- @param #number Prio Priority of the task.
-- @return Ops.OpsGroup#OPSGROUP.Task The task table.
function ARMYGROUP:AddTaskBarrage(Clock, Heading, Alpha, Altitude, Radius, Nshots, WeaponType, Prio)

  Heading=Heading or 0

  Alpha=Alpha or 60

  Altitude=Altitude or 100

  local distance=Altitude/math.tan(math.rad(Alpha))

  local a=self:GetVec2()

  local vec2=UTILS.Vec2Translate(a, distance, Heading)

  --local coord=COORDINATE:NewFromVec2(vec2):MarkToAll("Fire At Point",ReadOnly,Text)

  local DCStask=CONTROLLABLE.TaskFireAtPoint(nil, vec2, Radius, Nshots, WeaponType, Altitude)

  local task=self:AddTask(DCStask, Clock, nil, Prio)

  return task
end

--- Add a *waypoint* task to fire at a given coordinate.
-- @param #ARMYGROUP self
-- @param Core.Point#COORDINATE Coordinate Coordinate of the target.
-- @param Ops.OpsGroup#OPSGROUP.Waypoint Waypoint Where the task is executed. Default is next waypoint.
-- @param #number Radius Radius in meters. Default 100 m.
-- @param #number Nshots Number of shots to fire. Default 3.
-- @param #number WeaponType Type of weapon. Default auto.
-- @param #number Prio Priority of the task.
-- @return Ops.OpsGroup#OPSGROUP.Task The task table.
function ARMYGROUP:AddTaskWaypointFireAtPoint(Coordinate, Waypoint, Radius, Nshots, WeaponType, Prio)

  Coordinate=self:_CoordinateFromObject(Coordinate)

  Waypoint=Waypoint or self:GetWaypointNext()

  local DCStask=CONTROLLABLE.TaskFireAtPoint(nil, Coordinate:GetVec2(), Radius, Nshots, WeaponType)

  local task=self:AddTaskWaypoint(DCStask, Waypoint, nil, Prio)

  return task
end

--- Add a *scheduled* task.
-- @param #ARMYGROUP self
-- @param Wrapper.Group#GROUP TargetGroup Target group.
-- @param #number WeaponExpend How much weapons does are used.
-- @param #number WeaponType Type of weapon. Default auto.
-- @param #string Clock Time when to start the attack.
-- @param #number Prio Priority of the task.
-- @return Ops.OpsGroup#OPSGROUP.Task The task table.
function ARMYGROUP:AddTaskAttackGroup(TargetGroup, WeaponExpend, WeaponType, Clock, Prio)

  local DCStask=CONTROLLABLE.TaskAttackGroup(nil, TargetGroup, WeaponType, WeaponExpend, AttackQty, Direction, Altitude, AttackQtyLimit, GroupAttack)

  local task=self:AddTask(DCStask, Clock, nil, Prio)

  return task
end

--- Add a *scheduled* task to transport group(s).
-- @param #ARMYGROUP self
-- @param Core.Set#SET_GROUP GroupSet Set of cargo groups. Can also be a singe @{Wrapper.Group#GROUP} object.
-- @param Core.Zone#ZONE PickupZone Zone where the cargo is picked up.
-- @param Core.Zone#ZONE DeployZone Zone where the cargo is delivered to.
-- @param #string Clock Time when to start the attack.
-- @param #number Prio Priority of the task.
-- @return Ops.OpsGroup#OPSGROUP.Task The task table.
function ARMYGROUP:AddTaskCargoGroup(GroupSet, PickupZone, DeployZone, Clock, Prio)

  local DCStask={}
  DCStask.id="CargoTransport"
  DCStask.params={}
  DCStask.params.cargoqueu=1

  local task=self:AddTask(DCStask, Clock, nil, Prio)

  return task
end

--- Define a set of possible retreat zones.
-- @param #ARMYGROUP self
-- @param Core.Set#SET_ZONE RetreatZoneSet The retreat zone set. Default is an empty set.
-- @return #ARMYGROUP self
function ARMYGROUP:SetRetreatZones(RetreatZoneSet)
  self.retreatZones=RetreatZoneSet or SET_ZONE:New()
  return self
end

--- Add a zone to the retreat zone set.
-- @param #ARMYGROUP self
-- @param Core.Zone#ZONE_BASE RetreatZone The retreat zone.
-- @return #ARMYGROUP self
function ARMYGROUP:AddRetreatZone(RetreatZone)
  self.retreatZones:AddZone(RetreatZone)
  return self
end

--- Set suppression on. average, minimum and maximum time a unit is suppressed each time it gets hit.
-- @param #ARMYGROUP self
-- @param #number Tave Average time [seconds] a group will be suppressed. Default is 15 seconds.
-- @param #number Tmin (Optional) Minimum time [seconds] a group will be suppressed. Default is 5 seconds.
-- @param #number Tmax (Optional) Maximum time a group will be suppressed. Default is 25 seconds.
-- @return #ARMYGROUP self
function ARMYGROUP:SetSuppressionOn(Tave, Tmin, Tmax)

  -- Activate suppression.
  self.suppressionOn=true

  -- Minimum suppression time is input or default 5 sec (but at least 1 second).
  self.TsuppressMin=Tmin or 1
  self.TsuppressMin=math.max(self.TsuppressMin, 1)

  -- Maximum suppression time is input or default but at least Tmin.
  self.TsuppressMax=Tmax or 15
  self.TsuppressMax=math.max(self.TsuppressMax, self.TsuppressMin)

  -- Expected suppression time is input or default but at leat Tmin and at most Tmax.
  self.TsuppressAve=Tave or 10
  self.TsuppressAve=math.max(self.TsuppressMin)
  self.TsuppressAve=math.min(self.TsuppressMax)

  -- Debug Info
  self:T(self.lid..string.format("Set ave suppression time to %d seconds.", self.TsuppressAve))
  self:T(self.lid..string.format("Set min suppression time to %d seconds.", self.TsuppressMin))
  self:T(self.lid..string.format("Set max suppression time to %d seconds.", self.TsuppressMax))

  return self
end

--- Set suppression off.
-- @param #ARMYGROUP self
-- @return #ARMYGROUP self
function ARMYGROUP:SetSuppressionOff()
  -- Activate suppression.
  self.suppressionOn=false
end


--- Check if the group is currently holding its positon.
-- @param #ARMYGROUP self
-- @return #boolean If true, group was ordered to hold.
function ARMYGROUP:IsHolding()
  return self:Is("Holding")
end

--- Check if the group is currently cruising.
-- @param #ARMYGROUP self
-- @return #boolean If true, group cruising.
function ARMYGROUP:IsCruising()
  return self:Is("Cruising")
end

--- Check if the group is currently on a detour.
-- @param #ARMYGROUP self
-- @return #boolean If true, group is on a detour.
function ARMYGROUP:IsOnDetour()
  return self:Is("OnDetour")
end

--- Check if the group is ready for combat. I.e. not reaming, retreating, retreated, out of ammo or engaging.
-- @param #ARMYGROUP self
-- @return #boolean If true, group is on a combat ready.
function ARMYGROUP:IsCombatReady()
  local combatready=true

  if self:IsRearming() or self:IsRetreating() or self:IsOutOfAmmo() or self:IsEngaging() or self:IsDead() or self:IsStopped() or self:IsInUtero() then
    combatready=false
  end

  if self:IsPickingup() or self:IsLoading() or self:IsTransporting() or self:IsLoaded() or self:IsCargo() or self:IsCarrier() then
    combatready=false
  end

  return combatready
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Status
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Update status.
-- @param #ARMYGROUP self
function ARMYGROUP:Status()

  -- FSM state.
  local fsmstate=self:GetState()

  -- Is group alive?
  local alive=self:IsAlive()

  -- Check that group EXISTS and is ACTIVE.
  if alive then

    -- Update position etc.
    self:_UpdatePosition()

    -- Check if group has detected any units.
    self:_CheckDetectedUnits()

    -- Check ammo status.
    self:_CheckAmmoStatus()

    -- Check damage of elements and group.
    self:_CheckDamage()

    -- Check if group got stuck.
    self:_CheckStuck()

    -- Update engagement.
    if self:IsEngaging() then
      self:_UpdateEngageTarget()
    end

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

  -- Check that group EXISTS.
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

      -- TODO: GetFormation function.
      local formation=self.option.Formation or "unknown"

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

      -- Info text.
      local text=string.format("%s [%d/%d]: ROE/AS=%d/%d | T/M=%d/%d | Wp=%d[%d]-->%d[%d]/%d [%s] | Life=%.1f | v=%.1f (%d) [%s] | Hdg=%03d | Ammo=%d | Detect=%s | Cargo=%.1f",
      fsmstate, nelem, Nelem, roe, als, nTaskTot, nMissions, wpidxCurr, wpuidCurr, wpidxNext, wpuidNext, wpN, wpF, life, speed, speedEx, formation, hdg, ammo, ndetected, cargo)
      self:I(self.lid..text)

    end

  else

    -- Info text.
    if self.verbose>=1 then
      local text=string.format("State %s: Alive=%s", fsmstate, tostring(self:IsAlive()))
      self:I(self.lid..text)
    end

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
      text=text..string.format("\n[%d] %s: status=%s, life=%.1f/%.1f, guns=%d, cannons=%d, rockets=%d, missiles=%d, cargo=%d/%d kg",
      i, name, status, life, life0, ammo.Guns, ammo.Cannons, ammo.Rockets, ammo.Missiles, element.weightCargo, element.weightMaxCargo)
    end
    if #self.elements==0 then
      text=text.." none!"
    end
    self:T(self.lid..text)
  end

  ---
  -- Engage Detected Targets
  ---
  if self:IsCruising() and self.detectionOn and self.engagedetectedOn then

    local targetgroup, targetdist=self:_GetDetectedTarget()

    -- If we found a group, we engage it.
    if targetgroup then
      self:T(self.lid..string.format("Engaging target group %s at distance %d meters", targetgroup:GetName(), targetdist))
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

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Events
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after "ElementSpawned" event.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.OpsGroup#OPSGROUP.Element Element The group element.
function ARMYGROUP:onafterElementSpawned(From, Event, To, Element)
  self:T(self.lid..string.format("Element spawned %s", Element.name))

  -- Set element status.
  self:_UpdateStatus(Element, OPSGROUP.ElementStatus.SPAWNED)

end

--- On after "Spawned" event.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function ARMYGROUP:onafterSpawned(From, Event, To)
  self:T(self.lid..string.format("Group spawned!"))

  -- Debug info.
  if self.verbose>=1 then
    local text=string.format("Initialized Army Group %s:\n", self.groupname)
    text=text..string.format("Unit type    = %s\n", self.actype)
    text=text..string.format("Speed max    = %.1f Knots\n", UTILS.KmphToKnots(self.speedMax))
    text=text..string.format("Speed cruise = %.1f Knots\n", UTILS.KmphToKnots(self.speedCruise))
    text=text..string.format("Weight       = %.1f kg\n", self:GetWeightTotal())
    text=text..string.format("Cargo bay    = %.1f kg\n", self:GetFreeCargobay())
    text=text..string.format("Has EPLRS    = %s\n", tostring(self.isEPLRS))
    text=text..string.format("Elements     = %d\n", #self.elements)
    text=text..string.format("Waypoints    = %d\n", #self.waypoints)
    text=text..string.format("Radio        = %.1f MHz %s %s\n", self.radio.Freq, UTILS.GetModulationName(self.radio.Modu), tostring(self.radio.On))
    text=text..string.format("Ammo         = %d (G=%d/R=%d/M=%d)\n", self.ammo.Total, self.ammo.Guns, self.ammo.Rockets, self.ammo.Missiles)
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

    -- Set TACAN to default.
    self:_SwitchTACAN()

    -- Turn on the radio.
    if self.radioDefault then
      self:SwitchRadio(self.radioDefault.Freq, self.radioDefault.Modu)
    else
      self:SetDefaultRadio(self.radio.Freq, self.radio.Modu, true)
    end

    -- Formation
    if not self.option.Formation then
      -- Will be set in update route.
      --self.option.Formation=self.optionDefault.Formation
    end

    -- Number of waypoints.
    local Nwp=#self.waypoints

    -- Update route.
    if Nwp>1 and self.isMobile then
      self:T(self.lid..string.format("Got %d waypoints on spawn ==> Cruise in -1.0 sec!", Nwp))
      local wp=self:GetWaypointNext()
      self.option.Formation=wp.action
      --self:__Cruise(-1, nil, self.option.Formation)
      self:__Cruise(-1)
    else
      self:T(self.lid.."No waypoints on spawn ==> Full Stop!")
      self:FullStop()
    end

  end

end

--- On before "UpdateRoute" event.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number n Next waypoint index. Default is the one coming after that one that has been passed last.
-- @param #number N Waypoint  Max waypoint index to be included in the route. Default is the final waypoint.
-- @param #number Speed Speed in knots. Default cruise speed.
-- @param #number Formation Formation of the group.
function ARMYGROUP:onbeforeUpdateRoute(From, Event, To, n, N, Speed, Formation)

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
        -- For relocate
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
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number n Next waypoint index. Default is the one coming after that one that has been passed last.
-- @param #number N Waypoint  Max waypoint index to be included in the route. Default is the final waypoint.
-- @param #number Speed Speed in knots. Default cruise speed.
-- @param #number Formation Formation of the group.
function ARMYGROUP:onafterUpdateRoute(From, Event, To, n, N, Speed, Formation)

  -- Update route from this waypoint number onwards.
  n=n or self:GetWaypointIndexNext(self.adinfinitum)

  -- Max index.
  N=N or #self.waypoints
  N=math.min(N, #self.waypoints)

  -- Debug info.
  local text=string.format("Update route state=%s: n=%s, N=%s, Speed=%s, Formation=%s", self:GetState(), tostring(n), tostring(N), tostring(Speed), tostring(Formation))
  self:T(self.lid..text)

  -- Waypoints including addtional wp onroad.
  local waypoints={}

  -- Next waypoint.
  local wp=self.waypoints[n] --Ops.OpsGroup#OPSGROUP.Waypoint

  -- Current position.
  local coordinate=self:GetCoordinate()

  -- Road coordinate.
  local coordRoad=coordinate:GetClosestPointToRoad()

  -- Road distance.
  local roaddist=coordinate:Get2DDistance(coordRoad)

  -- Formation at the current position.
  local formation0=wp.action
  if formation0==ENUMS.Formation.Vehicle.OnRoad then
    -- Next waypoint is on road. Check if we are already on road.
    if roaddist>10 then
      -- Currently off road ==> we add an on road WP later.
      formation0=ENUMS.Formation.Vehicle.OffRoad
    else
      -- Already on road. We won't add an extra on road WP.
      formation0=ENUMS.Formation.Vehicle.OnRoad
    end
  end

  -- Debug
  --env.info(self.lid.."FF formation0="..tostring(formation0))

  -- Current point.
  local current=coordinate:WaypointGround(UTILS.MpsToKmph(self.speedWp), formation0)
  table.insert(waypoints, 1, current)

  -- Check if route consists of more than one waypoint (otherwise we have no previous waypoint)
  if N-n>0 then

    -- Loop over waypoints.
    for j=n, N do

      -- Index of previous waypoint.
      local i=j-1

      -- If we go to the first waypoint j=1 ==> i=0, so we take the last waypoint passed. E.g. when adinfinitum and passed final waypoint.
      if i==0 then
        i=self.currentwp
      end

      -- Next waypoint. We create a copy because we need to modify it.
      local wp=UTILS.DeepCopy(self.waypoints[j]) --Ops.OpsGroup#OPSGROUP.Waypoint

      -- Previous waypoint. Index is i and not i-1 because we added the current position.
      local wp0=self.waypoints[i] --Ops.OpsGroup#OPSGROUP.Waypoint

      -- Debug
      if false and self.attribute==GROUP.Attribute.GROUND_APC then
        local text=string.format("FF Update: i=%d, wp[i]=%s, wp[i-1]=%s", i, wp.action, wp0.action)
        env.info(text)
      end

      -- Speed.
      if Speed then
        wp.speed=UTILS.KnotsToMps(tonumber(Speed))
      else
        -- Take default waypoint speed. But make sure speed>0 if patrol ad infinitum.
        if wp.speed<0.1 then
          wp.speed=UTILS.KmphToMps(self.speedCruise)
        end
      end

      -- Formation.
      if self.formationPerma then
        wp.action=self.formationPerma
      elseif Formation then
        wp.action=Formation
      end

      -- Add waypoint in between because this waypoint is "On Road" but lies "Off Road".
      if wp.action==ENUMS.Formation.Vehicle.OnRoad and wp0.roaddist>=0 then

        -- Add "On Road" waypoint in between.
        local wproad=wp0.roadcoord:WaypointGround(UTILS.MpsToKmph(wp.speed), ENUMS.Formation.Vehicle.OnRoad) --Ops.OpsGroup#OPSGROUP.Waypoint

        -- Debug
        --wp0.roadcoord:MarkToAll(self.lid.." Added road wp near "..tostring(wproad.action))

        -- Insert road waypoint.
        table.insert(waypoints, wproad)
      end

      -- Add waypoint in between because this waypoint is "On Road" but lies "Off Road".
      if wp.action==ENUMS.Formation.Vehicle.OnRoad and wp.roaddist>=0 then

        -- The real waypoint is actually off road.
        wp.action=ENUMS.Formation.Vehicle.OffRoad

        -- Add "On Road" waypoint in between.
        local wproad=wp.roadcoord:WaypointGround(UTILS.MpsToKmph(wp.speed), ENUMS.Formation.Vehicle.OnRoad) --Ops.OpsGroup#OPSGROUP.Waypoint

        -- Debug
        --wp.roadcoord:MarkToAll(self.lid.." Added road wp far "..tostring(wproad.action))

        -- Insert road waypoint.
        table.insert(waypoints, wproad)
      end

      -- Debug
      --wp.coordinate:MarkToAll(self.lid.." Added wp actual"..tostring(wp.action))

      -- Add waypoint.
      table.insert(waypoints, wp)
    end

  else

    ---
    -- This is the case, where we have only one WP left.
    -- Could be because we had only one WP and did a detour (temp waypoint, which was deleted).
    ---

    -- Next waypoint.
    local wp=UTILS.DeepCopy(self.waypoints[n]) --Ops.OpsGroup#OPSGROUP.Waypoint

    -- Speed.
    if wp.speed<0.1 then
      wp.speed=UTILS.KmphToMps(self.speedCruise)
    end

    -- Formation.
    local formation=wp.action
    if self.formationPerma then
      formation=self.formationPerma
    elseif Formation then
      formation=Formation
    end

    -- Debug
    --env.info(self.lid..string.format("FF Formation %s", formation))

    -- Add road waypoint.
    if formation==ENUMS.Formation.Vehicle.OnRoad then

      if roaddist>10 then

        -- Add "On Road" waypoint in between.
        local wproad=coordRoad:WaypointGround(UTILS.MpsToKmph(wp.speed), ENUMS.Formation.Vehicle.OnRoad) --Ops.OpsGroup#OPSGROUP.Waypoint

        -- Debug
        --coordRoad:MarkToAll(self.lid.." Added road wp near "..tostring(wp.action))

        -- Insert road waypoint.
        table.insert(waypoints, wproad)

      end

      if wp.roaddist>10 then

        -- Add "On Road" waypoint in between.
        local wproad=wp.roadcoord:WaypointGround(UTILS.MpsToKmph(wp.speed), ENUMS.Formation.Vehicle.OnRoad) --Ops.OpsGroup#OPSGROUP.Waypoint

        -- Debug
        --wp.roadcoord:MarkToAll(self.lid.." Added road wp far "..tostring(wp.action))

        -- Insert road waypoint.
        table.insert(waypoints, wproad)

      end

    end

    -- Waypoint set set to on-road but lies off-road. We set it to off-road. the on-road wp has been inserted.
    if wp.action==ENUMS.Formation.Vehicle.OnRoad and wp.roaddist>10 then
      wp.action=ENUMS.Formation.Vehicle.OffRoad
    end

    -- Debug
    --wp.coordinate:MarkToAll(self.lid.." Added coord "..tostring(wp.action))

    -- Add actual waypoint.
    table.insert(waypoints, wp)

  end

  -- First (next wp).
  local wp=waypoints[1] --Ops.OpsGroup#OPSGROUP.Waypoint

  -- Current set formation.
  self.option.Formation=wp.action

  -- Current set speed in m/s.
  self.speedWp=wp.speed
  self:T(self.lid..string.format("Expected/waypoint speed=%.1f m/s", self.speedWp))

  -- Debug output.
  if self.verbose>=10 then --or self.attribute==GROUP.Attribute.GROUND_APC then
    for i,_wp in pairs(waypoints) do
      local wp=_wp --Ops.OpsGroup#OPSGROUP.Waypoint

      local text=string.format("WP #%d UID=%d Formation=%s: Speed=%d m/s, Alt=%d m, Type=%s", i, wp.uid and wp.uid or -1, wp.action, wp.speed, wp.alt, wp.type)

      local coord=COORDINATE:NewFromWaypoint(wp):MarkToAll(text)
      self:I(text)

    end
  end

  if self:IsEngaging() or not self.passedfinalwp then

    -- Debug info.
    self:T(self.lid..string.format("Updateing route: WP %d-->%d (%d/%d), Speed=%.1f knots, Formation=%s",
    self.currentwp, n, #waypoints, #self.waypoints, UTILS.MpsToKnots(self.speedWp), tostring(self.option.Formation)))

    -- Route group to all defined waypoints remaining.
    self:Route(waypoints)

  else

    ---
    -- Passed final WP ==> Full Stop
    ---

    self:T(self.lid..string.format("WARNING: Passed final WP when UpdateRoute() ==> Full Stop!"))
    self:FullStop()

  end

end

--- On after "GotoWaypoint" event. Group will got to the given waypoint and execute its route from there.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number UID The goto waypoint unique ID.
-- @param #number Speed (Optional) Speed to waypoint in knots.
-- @param #number Formation (Optional) Formation to waypoint.
function ARMYGROUP:onafterGotoWaypoint(From, Event, To, UID, Speed, Formation)

  local n=self:GetWaypointIndex(UID)

  if n then

    -- Speed to waypoint.
    Speed=Speed or self:GetSpeedToWaypoint(n)

    -- Update the route.
    self:__UpdateRoute(-0.01, n, nil, Speed, Formation)

  end

end

--- On after "Detour" event.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Point#COORDINATE Coordinate Coordinate where to go.
-- @param #number Speed Speed in knots. Default cruise speed.
-- @param #number Formation Formation of the group.
-- @param #number ResumeRoute If true, resume route after detour point was reached. If false, the group will stop at the detour point and wait for futher commands.
function ARMYGROUP:onafterDetour(From, Event, To, Coordinate, Speed, Formation, ResumeRoute)

  for _,_wp in pairs(self.waypoints) do
    local wp=_wp --Ops.OpsGroup#OPSGROUP.Waypoint
    if wp.detour then
      self:RemoveWaypointByID(wp.uid)
    end
  end

  -- Speed in knots.
  Speed=Speed or self:GetSpeedCruise()

  -- ID of current waypoint.
  local uid=self:GetWaypointCurrentUID()

  -- Add waypoint after current.
  local wp=self:AddWaypoint(Coordinate, Speed, uid, Formation, true)

  -- Set if we want to resume route after reaching the detour waypoint.
  if ResumeRoute then
    wp.detour=1
  else
    wp.detour=0
  end

end

--- On after "OutOfAmmo" event.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function ARMYGROUP:onafterOutOfAmmo(From, Event, To)
  self:T(self.lid..string.format("Group is out of ammo at t=%.3f", timer.getTime()))

  -- Get current task.
  local task=self:GetTaskCurrent()

  if task then
    if task.dcstask.id=="FireAtPoint" or task.dcstask.id==AUFTRAG.SpecialTask.BARRAGE then
      self:T(self.lid..string.format("Cancelling current %s task because out of ammo!", task.dcstask.id))
      self:TaskCancel(task)
    end
  end

  -- Fist, check if we want to rearm once out-of-ammo.
  --TODO: IsMobile() check
  if self.rearmOnOutOfAmmo then
    local truck, dist=self:FindNearestAmmoSupply(30)
    if truck then
      self:T(self.lid..string.format("Found Ammo Truck %s [%s]", truck:GetName(), truck:GetTypeName()))
      local Coordinate=truck:GetCoordinate()
      self:__Rearm(-1, Coordinate)
      return
    end
  end

  -- Second, check if we want to retreat once out of ammo.
  if self.retreatOnOutOfAmmo then
    self:T(self.lid.."Retreat on out of ammo")
    self:__Retreat(-1)
    return
  end

  -- Third, check if we want to RTZ once out of ammo (unless we have a rearming mission in the queue).
  if self.rtzOnOutOfAmmo and not self:IsMissionTypeInQueue(AUFTRAG.Type.REARMING) then
    self:T(self.lid.."RTZ on out of ammo")
    self:__RTZ(-1)
  end

end


--- On before "Rearm" event.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Point#COORDINATE Coordinate Coordinate where to rearm.
-- @param #number Formation Formation of the group.
function ARMYGROUP:onbeforeRearm(From, Event, To, Coordinate, Formation)

  local dt=nil
  local allowed=true

  -- Pause current mission.
  if self:IsOnMission() then
    local mission=self:GetMissionCurrent()
    if mission and mission.type~=AUFTRAG.Type.REARMING then
      self:T(self.lid.."Rearm command but have current mission ==> Pausing mission!")
      self:PauseMission()
      dt=-0.1
      allowed=false
    else
      self:T(self.lid.."Rearm command and current mission is REARMING ==> Transition ALLOWED!")
    end
  end

  -- Disengage.
  if self:IsEngaging() then
    self:T(self.lid.."Rearm command but currently engaging ==> Disengage!")
    self:Disengage()
    dt=-0.1
    allowed=false
  end

  -- Check if coordinate is provided.
  if allowed and not Coordinate then
    local truck=self:FindNearestAmmoSupply()
    if truck and truck:IsAlive() then
      self:__Rearm(-0.1, truck:GetCoordinate(), Formation)
    end
    return false
  end

  -- Try again...
  if dt then
    self:T(self.lid..string.format("Trying Rearm again in %.2f sec", dt))
    self:__Rearm(dt, Coordinate, Formation)
    allowed=false
  end

  return allowed
end

--- On after "Rearm" event.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Point#COORDINATE Coordinate Coordinate where to rearm.
-- @param #number Formation Formation of the group.
function ARMYGROUP:onafterRearm(From, Event, To, Coordinate, Formation)

  -- Debug info.
  self:T(self.lid..string.format("Group send to rearm"))

  -- ID of current waypoint.
  local uid=self:GetWaypointCurrentUID()

  -- Add waypoint after current.
  local wp=self:AddWaypoint(Coordinate, nil, uid, Formation, true)

  -- Set if we want to resume route after reaching the detour waypoint.
  wp.detour=0

end

--- On after "Rearmed" event.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function ARMYGROUP:onafterRearmed(From, Event, To)
  self:T(self.lid.."Group rearmed")

  -- Get Current mission.
  local mission=self:GetMissionCurrent()

  -- Check if this is a rearming mission.
  if mission and mission.type==AUFTRAG.Type.REARMING then

    -- Rearmed ==> Mission Done! This also checks if the group is done.
    self:MissionDone(mission)

  else

    -- Check group done.
    self:_CheckGroupDone(1)

  end

end

--- On before "RTZ" event.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Zone#ZONE Zone The zone to return to.
-- @param #number Formation Formation of the group.
function ARMYGROUP:onbeforeRTZ(From, Event, To, Zone, Formation)
  self:T2(self.lid.."onbeforeRTZ")

  -- Zone.
  local zone=Zone or self.homezone

  if zone then

    if (not self.isMobile) and (not self:IsInZone(zone)) then
      self:Teleport(zone:GetCoordinate(), 0, true)
      self:__RTZ(-1, Zone, Formation)
      return false
    end

  else
    return false
  end

  return true
end

--- On after "RTZ" event.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Zone#ZONE Zone The zone to return to.
-- @param #number Formation Formation of the group.
function ARMYGROUP:onafterRTZ(From, Event, To, Zone, Formation)
  self:T(self.lid.."onafterRTZ")

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
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function ARMYGROUP:onafterReturned(From, Event, To)

  -- Debug info.
  self:T(self.lid..string.format("Group returned"))

  if self.legion then
    -- Debug info.
    self:T(self.lid..string.format("Adding group back to warehouse stock"))

    -- Add asset back in 10 seconds.
    self.legion:__AddAsset(10, self.group, 1)
  end

end

--- On after "Rearming" event.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function ARMYGROUP:onafterRearming(From, Event, To)

  -- Get current position.
  local pos=self:GetCoordinate()

  -- Create a new waypoint.
  local wp=pos:WaypointGround(0)

  -- Create new route consisting of only this position ==> Stop!
  self:Route({wp})

end

--- On before "Retreat" event.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Zone#ZONE_BASE Zone (Optional) Zone where to retreat. Default is the closest retreat zone.
-- @param #number Formation (Optional) Formation of the group.
function ARMYGROUP:onbeforeRetreat(From, Event, To, Zone, Formation)

  if not Zone then

    local a=self:GetVec2()

    local distmin=math.huge
    local zonemin=nil
    for _,_zone in pairs(self.retreatZones:GetSet()) do
      local zone=_zone --Core.Zone#ZONE_BASE

      local b=zone:GetVec2()

      local dist=UTILS.VecDist2D(a, b)

      if dist<distmin then
        distmin=dist
        zonemin=zone
      end

    end

    if zonemin then
      self:__Retreat(0.1, zonemin, Formation)
    end

    return false
  end

  return true
end

--- On after "Retreat" event.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Zone#ZONE_BASE Zone (Optional) Zone where to retreat. Default is the closest retreat zone.
-- @param #number Formation (Optional) Formation of the group.
function ARMYGROUP:onafterRetreat(From, Event, To, Zone, Formation)

  -- ID of current waypoint.
  local uid=self:GetWaypointCurrentUID()

  -- Get random coordinate of the zone.
  local Coordinate=Zone:GetRandomCoordinate()

  -- Debug info.
  self:T(self.lid..string.format("Retreating to zone %s", Zone:GetName()))

  -- Add waypoint after current.
  local wp=self:AddWaypoint(Coordinate, nil, uid, Formation, true)

  -- Set if we want to resume route after reaching the detour waypoint.
  wp.detour=0

  -- Cancel all missions.
  self:CancelAllMissions()

end

--- On after "Retreated" event.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function ARMYGROUP:onafterRetreated(From, Event, To)

  -- Get current position.
  local pos=self:GetCoordinate()

  -- Create a new waypoint.
  local wp=pos:WaypointGround(0)

  -- Create new route consisting of only this position ==> Stop!
  self:Route({wp})

end

--- On after "EngageTarget" event.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Group#GROUP Group the group to be engaged.
-- @param #number Speed Speed in knots.
-- @param #string Formation Formation used in the engagement. Default `ENUMS.Formation.Vehicle.Vee`.
function ARMYGROUP:onbeforeEngageTarget(From, Event, To, Target, Speed, Formation)

  local dt=nil
  local allowed=true

  local ammo=self:GetAmmoTot()

  if ammo.Total==0 then
    self:T(self.lid.."WARNING: Cannot engage TARGET because no ammo left!")
    return false
  end

  -- Get current mission.
  local mission=self:GetMissionCurrent()

  -- Pause current mission unless it uses the EngageTarget command.
  if mission and mission.type~=AUFTRAG.Type.GROUNDATTACK and mission.type~=AUFTRAG.Type.CAPTUREZONE then
    self:T(self.lid.."Engage command but have current mission ==> Pausing mission!")
    self:PauseMission()
    dt=-0.1
    allowed=false
  end

  -- Try again...
  if dt then
    self:T(self.lid..string.format("Trying Engage again in %.2f sec", dt))
    self:__EngageTarget(dt, Target)
    allowed=false
  end

  return allowed
end

--- On after "EngageTarget" event.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.Target#TARGET Target The target to be engaged. Can also be a group or unit.
-- @param #number Speed Attack speed in knots.
-- @param #string Formation Formation used in the engagement. Default `ENUMS.Formation.Vehicle.Vee`.
function ARMYGROUP:onafterEngageTarget(From, Event, To, Target, Speed, Formation)
  self:T(self.lid.."Engaging Target")

  -- Make sure this is a target.
  if Target:IsInstanceOf("TARGET") then
    self.engage.Target=Target
  else
    self.engage.Target=TARGET:New(Target)
  end

  -- Target coordinate.
  self.engage.Coordinate=UTILS.DeepCopy(self.engage.Target:GetCoordinate())

  -- Get a coordinate close to the target.
  local intercoord=self:GetCoordinate():GetIntermediateCoordinate(self.engage.Coordinate, 0.95)

  -- Backup ROE and alarm state.
  self.engage.roe=self:GetROE()
  self.engage.alarmstate=self:GetAlarmstate()

  -- Switch ROE and alarm state.
  self:SwitchAlarmstate(ENUMS.AlarmState.Auto)
  self:SwitchROE(ENUMS.ROE.OpenFire)

  -- ID of current waypoint.
  local uid=self:GetWaypointCurrentUID()

  -- Set formation.
  self.engage.Formation=Formation or ENUMS.Formation.Vehicle.Vee

  -- Set speed.
  self.engage.Speed=Speed

  -- Add waypoint after current.
  self.engage.Waypoint=self:AddWaypoint(intercoord, self.engage.Speed, uid, self.engage.Formation, true)

  -- Set if we want to resume route after reaching the detour waypoint.
  self.engage.Waypoint.detour=1

end

--- Update engage target.
-- @param #ARMYGROUP self
function ARMYGROUP:_UpdateEngageTarget()

  if self.engage.Target and self.engage.Target:IsAlive() then

    -- Get current position vector.
    local vec3=self.engage.Target:GetVec3()

    if vec3 then

      -- Distance to last known position of target.
      local dist=UTILS.VecDist3D(vec3, self.engage.Coordinate:GetVec3())

      -- Check line of sight to target.
      local los=self:HasLoS(vec3)

      -- Check if target moved more than 100 meters or we do not have line of sight.
      if dist>100 or los==false then

        -- Update new position.
        self.engage.Coordinate:UpdateFromVec3(vec3)

        -- ID of current waypoint.
        local uid=self:GetWaypointCurrentUID()

        -- Remove current waypoint
        self:RemoveWaypointByID(self.engage.Waypoint.uid)

        -- Get new coordinate where to go.
        local intercoord=self:GetCoordinate():GetIntermediateCoordinate(self.engage.Coordinate, 0.95)

          -- Add waypoint after current.
        self.engage.Waypoint=self:AddWaypoint(intercoord, self.engage.Speed, uid, self.engage.Formation, true)

        -- Set if we want to resume route after reaching the detour waypoint.
        self.engage.Waypoint.detour=1

      end

    else

      -- Could not get position of target (not alive any more?) ==> Disengage.
      self:T(self.lid.."Could not get position of target ==> Disengage!")
      self:Disengage()

    end

  else

    -- Target not alive any more ==> Disengage.
    self:T(self.lid.."Target not ALIVE ==> Disengage!")
    self:Disengage()

  end

end

--- On after "Disengage" event.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function ARMYGROUP:onafterDisengage(From, Event, To)
  self:T(self.lid.."Disengage Target")

  -- Restore previous ROE and alarm state.
  self:SwitchROE(self.engage.roe)
  self:SwitchAlarmstate(self.engage.alarmstate)

  -- Get current task
  local task=self:GetTaskCurrent()

  -- Get if current task is ground attack.
  if task and task.dcstask.id==AUFTRAG.SpecialTask.GROUNDATTACK then
    self:T(self.lid.."Disengage with current task GROUNDATTACK ==> Task Done!")
    self:TaskDone(task)
  end

  -- Remove current waypoint
  if self.engage.Waypoint then
    self:RemoveWaypointByID(self.engage.Waypoint.uid)
  end

  -- Check group is done
  self:_CheckGroupDone(1)
end

--- On after "DetourReached" event.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function ARMYGROUP:onafterDetourReached(From, Event, To)
  self:T(self.lid.."Group reached detour coordinate")
end


--- On after "FullStop" event.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function ARMYGROUP:onafterFullStop(From, Event, To)

  -- Debug info.
  self:T(self.lid..string.format("Full stop!"))

  -- Get current position.
  local pos=self:GetCoordinate()

  -- Create a new waypoint.
  local wp=pos:WaypointGround(0)

  -- Create new route consisting of only this position ==> Stop!
  self:Route({wp})

end

--- On after "Cruise" event.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number Speed Speed in knots.
-- @param #number Formation Formation.
function ARMYGROUP:onafterCruise(From, Event, To, Speed, Formation)

  -- Not waiting anymore.
  self.Twaiting=nil
  self.dTwait=nil

  -- Debug info.
  self:T(self.lid..string.format("Cruise ==> Update route in 0.01 sec (speed=%s, formation=%s)", tostring(Speed), tostring(Formation)))

  -- Update route.
  self:__UpdateRoute(-0.01, nil, nil, Speed, Formation)

end

--- On after "Hit" event.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Unit#UNIT Enemy Unit that hit the element or `nil`.
function ARMYGROUP:onafterHit(From, Event, To, Enemy)
  self:T(self.lid..string.format("ArmyGroup hit by %s", Enemy and Enemy:GetName() or "unknown"))

  if self.suppressionOn then
    env.info(self.lid.."FF suppress")
    self:_Suppress()
  end
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Routing
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Add an a waypoint to the route.
-- @param #ARMYGROUP self
-- @param Core.Point#COORDINATE Coordinate The coordinate of the waypoint.
-- @param #number Speed Speed in knots. Default is default cruise speed or 70% of max speed.
-- @param #number AfterWaypointWithID Insert waypoint after waypoint given ID. Default is to insert as last waypoint.
-- @param #string Formation Formation the group will use.
-- @param #boolean Updateroute If true or nil, call UpdateRoute. If false, no call.
-- @return Ops.OpsGroup#OPSGROUP.Waypoint Waypoint table.
function ARMYGROUP:AddWaypoint(Coordinate, Speed, AfterWaypointWithID, Formation, Updateroute)

  -- Debug info.
  self:T(self.lid..string.format("AddWaypoint Formation = %s", tostring(Formation)))

  -- Create coordinate.
  local coordinate=self:_CoordinateFromObject(Coordinate)

  -- Set waypoint index.
  local wpnumber=self:GetWaypointIndexAfterID(AfterWaypointWithID)

  -- Speed in knots.
  Speed=Speed or self:GetSpeedCruise()

  -- Formation.
  if not Formation then
    if self.formationPerma then
      Formation = self.formationPerma
    elseif self.optionDefault.Formation then
      Formation = self.optionDefault.Formation
    elseif self.option.Formation then
      Formation = self.option.Formation
    else
      -- Default formation is on road.
      Formation = ENUMS.Formation.Vehicle.OnRoad
    end
    self:T2(self.lid..string.format("Formation set to = %s", tostring(Formation)))
  end

  -- Create a Ground waypoint.
  local wp=coordinate:WaypointGround(UTILS.KnotsToKmph(Speed), Formation)

  -- Create waypoint data table.
  local waypoint=self:_CreateWaypoint(wp)

  -- Add waypoint to table.
  self:_AddWaypoint(waypoint, wpnumber)

  -- Get closest point to road.
  waypoint.roadcoord=coordinate:GetClosestPointToRoad(false)
  if waypoint.roadcoord then
    waypoint.roaddist=coordinate:Get2DDistance(waypoint.roadcoord)
  else
    waypoint.roaddist=1000*1000 --1000 km.
  end

  -- Debug info.
  self:T(self.lid..string.format("Adding waypoint UID=%d (index=%d), Speed=%.1f knots, Dist2Road=%d m, Action=%s", waypoint.uid, wpnumber, Speed, waypoint.roaddist, waypoint.action))

  -- Update route.
  if Updateroute==nil or Updateroute==true then
    self:__UpdateRoute(-0.01)
  end

  return waypoint
end

--- Initialize group parameters. Also initializes waypoints if self.waypoints is nil.
-- @param #ARMYGROUP self
-- @param #table Template Template used to init the group. Default is `self.template`.
-- @param #number Delay Delay in seconds before group is initialized. Default `nil`, *i.e.* instantaneous.
-- @return #ARMYGROUP self
function ARMYGROUP:_InitGroup(Template, Delay)

  if Delay and Delay>0 then
    self:ScheduleOnce(Delay, ARMYGROUP._InitGroup, self, Template, 0)
  else
  
    -- First check if group was already initialized.
    if self.groupinitialized then
      self:T(self.lid.."WARNING: Group was already initialized! Will NOT do it again!")
      return
    end
  
    -- Get template of group.
    local template=Template or self:_GetTemplate()
  
    -- Ground are always AI.
    self.isAI=true
  
    -- Is (template) group late activated.
    self.isLateActivated=template.lateActivation
  
    -- Ground groups cannot be uncontrolled.
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
  
    -- Cruise speed in km/h
    self.speedCruise=self.speedMax*0.7
  
    -- Group ammo.
    self.ammo=self:GetAmmoTot()
  
    -- Radio parameters from template.
    self.radio.On=false  -- Radio is always OFF for ground.
    self.radio.Freq=133
    self.radio.Modu=radio.modulation.AM
  
    -- Set default radio.
    self:SetDefaultRadio(self.radio.Freq, self.radio.Modu, self.radio.On)
  
    -- Get current formation from first waypoint.
    self.option.Formation=template.route.points[1].action
  
    -- Set default formation to "on road".
    self.optionDefault.Formation=ENUMS.Formation.Vehicle.OnRoad

    -- Default TACAN off.
    if not self.tacanDefault then
      self:SetDefaultTACAN(nil, nil, nil, nil, true)
    end
    if not self.tacan then
      self.tacan=UTILS.DeepCopy(self.tacanDefault)
    end

    -- Units of the group.
    local units=self.group:GetUnits()

    -- DCS group.
    local dcsgroup=Group.getByName(self.groupname)
    local size0=dcsgroup:getInitialSize()
    local u=dcsgroup:getUnits()

    -- Quick check.
    if #units~=size0 then
      self:T(self.lid..string.format("ERROR: Got #units=%d but group consists of %d units! u=%d", #units, size0, #u))
    end

    -- Add elemets.
    for _,unit in pairs(units) do
      local unitname=unit:GetName()
      self:_AddElementByName(unitname)
    end

    -- Init done.
    self.groupinitialized=true
  end

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Option Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Switch to a specific formation.
-- @param #ARMYGROUP self
-- @param #number Formation New formation the group will fly in. Default is the setting of `SetDefaultFormation()`.
-- @param #boolean Permanently If true, formation always used from now on.
-- @param #boolean NoRouteUpdate If true, route is not updated.
-- @return #ARMYGROUP self
function ARMYGROUP:SwitchFormation(Formation, Permanently, NoRouteUpdate)

  if self:IsAlive() or self:IsInUtero() then

    Formation=Formation or (self.optionDefault.Formation or "Off road")
    Permanently = Permanently or false

    if Permanently then
      self.formationPerma=Formation
    else
      self.formationPerma=nil
    end

    -- Set current formation.
    self.option.Formation=Formation or "Off road"

    if self:IsInUtero() then
        self:T(self.lid..string.format("Will switch formation to %s (permanently=%s) when group is spawned", tostring(self.option.Formation), tostring(Permanently)))
    else

      -- Update route with the new formation.
      if NoRouteUpdate then
      else
        self:__UpdateRoute(-1, nil, nil, Formation)
      end

      -- Debug info.
      self:T(self.lid..string.format("Switching formation to %s (permanently=%s)", tostring(self.option.Formation), tostring(Permanently)))

    end

  end

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Find the neares ammo supply group within a given radius.
-- @param #ARMYGROUP self
-- @param #number Radius Search radius in NM. Default 30 NM.
-- @return Wrapper.Group#GROUP Closest ammo supplying group or `nil` if no group is in the given radius.
-- @return #number Distance to closest group in meters.
function ARMYGROUP:FindNearestAmmoSupply(Radius)

  -- Radius in meters.
  Radius=UTILS.NMToMeters(Radius or 30)

  -- Current positon.
  local coord=self:GetCoordinate()

  -- Get my coalition.
  local myCoalition=self:GetCoalition()

  -- Scanned units.
  local units=coord:ScanUnits(Radius)

  -- Find closest
  local dmin=math.huge
  local truck=nil --Wrapper.Unit#UNIT
  for _,_unit in pairs(units.Set) do
    local unit=_unit --Wrapper.Unit#UNIT

    -- Check coaliton and if unit can supply ammo.
    if unit:IsAlive() and unit:GetCoalition()==myCoalition and unit:IsAmmoSupply() and unit:GetVelocityKMH()<1 then

      -- Distance.
      local d=coord:Get2DDistance(unit:GetCoord())

      -- Check if distance is smaller.
      if d<dmin then
        dmin=d
        truck=unit
        -- Debug message.
        self:T(self.lid..string.format("Ammo truck %s [%s] at dist=%d meters", unit:GetName(), unit:GetTypeName(), d))
      end

    end
  end

  if truck then
    return truck:GetGroup(), dmin
  end

  return nil, nil
end

--- Suppress fire of the group by setting its ROE to weapon hold.
-- @param #ARMYGROUP self
function ARMYGROUP:_Suppress()

  -- Current time.
  local Tnow=timer.getTime()

  -- Current ROE
  local currROE=self:GetROE()


  -- Get randomized time the unit is suppressed.
  local sigma=(self.TsuppressMax-self.TsuppressMin)/4

  -- Gaussian distribution.
  local Tsuppress=UTILS.RandomGaussian(self.TsuppressAve,sigma,self.TsuppressMin, self.TsuppressMax)

  -- Time at which the suppression is over.
  local renew=true
  if not self.TsuppressionOver then

    -- Group is not suppressed currently.
    self.TsuppressionOver=Tnow+Tsuppress

    -- Group will hold their weapons.
    self:SwitchROE(ENUMS.ROE.WeaponHold)

    -- Backup ROE.
    self.suppressionROE=currROE

  else
    -- Check if suppression is longer than current time.
    if Tsuppress+Tnow > self.TsuppressionOver then
      self.TsuppressionOver=Tnow+Tsuppress
    else
      renew=false
    end
  end

  -- Recovery event will be called in Tsuppress seconds.
  if renew then
    self:__Unsuppressed(self.TsuppressionOver-Tnow)
  end

  -- Debug message.
  self:T(self.lid..string.format("Suppressed for %d sec", Tsuppress))

end

--- Before "Recovered" event. Check if suppression time is over.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @return #boolean
function ARMYGROUP:onbeforeUnsuppressed(From, Event, To)

  -- Current time.
  local Tnow=timer.getTime()

  -- Debug info
  self:T(self.lid..string.format("onbeforeRecovered: Time now: %d  - Time over: %d", Tnow, self.TsuppressionOver))

  -- Recovery is only possible if enough time since the last hit has passed.
  if Tnow >= self.TsuppressionOver then
    return true
  else
    return false
  end

end

--- After "Recovered" event. Group has recovered and its ROE is set back to the "normal" unsuppressed state. Optionally the group is flared green.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function ARMYGROUP:onafterUnsuppressed(From, Event, To)

  -- Debug message.
  local text=string.format("Group %s has recovered!", self:GetName())
  MESSAGE:New(text, 10):ToAll()
  self:T(self.lid..text)

  -- Set ROE back to default.
  self:SwitchROE(self.suppressionROE)

  -- Flare unit green.
  if true then
    self.group:FlareGreen()
  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
