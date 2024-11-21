--- **Wrapper** - CONTROLLABLE is an intermediate class wrapping Group and Unit classes "controllers".
--
-- ===
--
-- ### Author: **FlightControl**
--
-- ### Contributions:
--
-- ===
--
-- @module Wrapper.Controllable
-- @image Wrapper_Controllable.JPG

--- @type CONTROLLABLE
-- @field DCS#Controllable DCSControllable The DCS controllable class.
-- @field #string ControllableName The name of the controllable.
-- @extends Wrapper.Positionable#POSITIONABLE

--- Wrapper class to handle the "DCS Controllable objects", which are Groups and Units:
--
--  * Support all DCS Controllable APIs.
--  * Enhance with Controllable specific APIs not in the DCS Controllable API set.
--  * Handle local Controllable Controller.
--  * Manage the "state" of the DCS Controllable.
--
-- # 1) CONTROLLABLE constructor
--
-- The CONTROLLABLE class provides the following functions to construct a CONTROLLABLE instance:
--
--  * @{#CONTROLLABLE.New}(): Create a CONTROLLABLE instance.
--
-- # 2) CONTROLLABLE Task methods
--
-- Several controllable task methods are available that help you to prepare tasks.
-- These methods return a string consisting of the task description, which can then be given to either a @{#CONTROLLABLE.PushTask}() or @{#CONTROLLABLE.SetTask}() method to assign the task to the CONTROLLABLE.
-- Tasks are specific for the category of the CONTROLLABLE, more specific, for AIR, GROUND or AIR and GROUND.
-- Each task description where applicable indicates for which controllable category the task is valid.
-- There are 2 main subdivisions of tasks: Assigned tasks and EnRoute tasks.
--
-- ## 2.1) Task assignment
--
-- Assigned task methods make the controllable execute the task where the location of the (possible) targets of the task are known before being detected.
-- This is different from the EnRoute tasks, where the targets of the task need to be detected before the task can be executed.
--
-- Find below a list of the **assigned task** methods:
--
--   * @{#CONTROLLABLE.TaskAttackGroup}: (AIR) Attack a Controllable.
--   * @{#CONTROLLABLE.TaskAttackMapObject}: (AIR) Attacking the map object (building, structure, e.t.c).
--   * @{#CONTROLLABLE.TaskAttackUnit}: (AIR) Attack the Unit.
--   * @{#CONTROLLABLE.TaskBombing}: (AIR) Delivering weapon at the point on the ground.
--   * @{#CONTROLLABLE.TaskBombingRunway}: (AIR) Delivering weapon on the runway.
--   * @{#CONTROLLABLE.TaskEmbarking}: (AIR) Move the controllable to a Vec2 Point, wait for a defined duration and embark a controllable.
--   * @{#CONTROLLABLE.TaskEmbarkToTransport}: (GROUND) Embark to a Transport landed at a location.
--   * @{#CONTROLLABLE.TaskEscort}: (AIR) Escort another airborne controllable.
--   * @{#CONTROLLABLE.TaskGroundEscort}: (AIR/HELO) Escort a ground controllable.
--   * @{#CONTROLLABLE.TaskFAC_AttackGroup}: (AIR + GROUND) The task makes the controllable/unit a FAC and orders the FAC to control the target (enemy ground controllable) destruction.
--   * @{#CONTROLLABLE.TaskFireAtPoint}: (GROUND) Fire some or all ammunition at a VEC2 point.
--   * @{#CONTROLLABLE.TaskFollow}: (AIR) Following another airborne controllable.
--   * @{#CONTROLLABLE.TaskHold}: (GROUND) Hold ground controllable from moving.
--   * @{#CONTROLLABLE.TaskHoldPosition}: (AIR) Hold position at the current position of the first unit of the controllable.
--   * @{#CONTROLLABLE.TaskLandAtVec2}: (AIR HELICOPTER) Landing at the ground. For helicopters only.
--   * @{#CONTROLLABLE.TaskLandAtZone}: (AIR) Land the controllable at a @{Core.Zone#ZONE_RADIUS).
--   * @{#CONTROLLABLE.TaskOrbitCircle}: (AIR) Orbit at the current position of the first unit of the controllable at a specified altitude.
--   * @{#CONTROLLABLE.TaskOrbitCircleAtVec2}: (AIR) Orbit at a specified position at a specified altitude during a specified duration with a specified speed.
--   * @{#CONTROLLABLE.TaskStrafing}: (AIR) Strafe a point Vec2 with onboard weapons.
--   * @{#CONTROLLABLE.TaskRefueling}: (AIR) Refueling from the nearest tanker. No parameters.
--   * @{#CONTROLLABLE.TaskRecoveryTanker}: (AIR) Set  group to act as recovery tanker for a naval group.
--   * @{#CONTROLLABLE.TaskRoute}: (AIR + GROUND) Return a Mission task to follow a given route defined by Points.
--   * @{#CONTROLLABLE.TaskRouteToVec2}: (AIR + GROUND) Make the Controllable move to a given point.
--   * @{#CONTROLLABLE.TaskRouteToVec3}: (AIR + GROUND) Make the Controllable move to a given point.
--   * @{#CONTROLLABLE.TaskRouteToZone}: (AIR + GROUND) Route the controllable to a given zone.
--
-- ## 2.2) EnRoute assignment
--
-- EnRoute tasks require the targets of the task need to be detected by the controllable (using its sensors) before the task can be executed:
--
--   * @{#CONTROLLABLE.EnRouteTaskAWACS}: (AIR) Aircraft will act as an AWACS for friendly units (will provide them with information about contacts). No parameters.
--   * @{#CONTROLLABLE.EnRouteTaskEngageControllable}: (AIR) Engaging a controllable. The task does not assign the target controllable to the unit/controllable to attack now; it just allows the unit/controllable to engage the target controllable as well as other assigned targets.
--   * @{#CONTROLLABLE.EnRouteTaskEngageTargets}: (AIR) Engaging targets of defined types.
--   * @{#CONTROLLABLE.EnRouteTaskEngageTargetsInZone}: (AIR) Engaging a targets of defined types at circle-shaped zone.
--   * @{#CONTROLLABLE.EnRouteTaskEWR}: (AIR) Attack the Unit.
--   * @{#CONTROLLABLE.EnRouteTaskFAC}: (AIR + GROUND) The task makes the controllable/unit a FAC and lets the FAC to choose a targets (enemy ground controllable) around as well as other assigned targets.
--   * @{#CONTROLLABLE.EnRouteTaskFAC_EngageControllable}: (AIR + GROUND) The task makes the controllable/unit a FAC and lets the FAC to choose the target (enemy ground controllable) as well as other assigned targets.
--   * @{#CONTROLLABLE.EnRouteTaskTanker}: (AIR) Aircraft will act as a tanker for friendly units. No parameters.
--
-- ## 2.3) Task preparation
--
-- There are certain task methods that allow to tailor the task behavior:
--
--   * @{#CONTROLLABLE.TaskWrappedAction}: Return a WrappedAction Task taking a Command.
--   * @{#CONTROLLABLE.TaskCombo}: Return a Combo Task taking an array of Tasks.
--   * @{#CONTROLLABLE.TaskCondition}: Return a condition section for a controlled task.
--   * @{#CONTROLLABLE.TaskControlled}: Return a Controlled Task taking a Task and a TaskCondition.
--
-- ## 2.4) Call a function as a Task
--
-- A function can be called which is part of a Task. The method @{#CONTROLLABLE.TaskFunction}() prepares
-- a Task that can call a GLOBAL function from within the Controller execution.
-- This method can also be used to **embed a function call when a certain waypoint has been reached**.
-- See below the **Tasks at Waypoints** section.
--
-- Demonstration Mission: [GRP-502 - Route at waypoint to random point](https://github.com/FlightControl-Master/MOOSE_Demos/tree/master/Wrapper/Group/502-Route-at-waypoint-to-random-point)
--
-- ## 2.5) Tasks at Waypoints
--
-- Special Task methods are available to set tasks at certain waypoints.
-- The method @{#CONTROLLABLE.SetTaskWaypoint}() helps preparing a Route, embedding a Task at the Waypoint of the Route.
--
-- This creates a Task element, with an action to call a function as part of a Wrapped Task.
--
-- ## 2.6) Obtain the mission from controllable templates
--
-- Controllable templates contain complete mission descriptions. Sometimes you want to copy a complete mission from a controllable and assign it to another:
--
--   * @{#CONTROLLABLE.TaskMission}: (AIR + GROUND) Return a mission task from a mission template.
--
-- # 3) Command methods
--
-- Controllable **command methods** prepare the execution of commands using the @{#CONTROLLABLE.SetCommand} method:
--
--   * @{#CONTROLLABLE.CommandDoScript}: Do Script command.
--   * @{#CONTROLLABLE.CommandSwitchWayPoint}: Perform a switch waypoint command.
--
-- # 4) Routing of Controllables
--
-- Different routing methods exist to route GROUPs and UNITs to different locations:
--
--   * @{#CONTROLLABLE.Route}(): Make the Controllable to follow a given route.
--   * @{#CONTROLLABLE.RouteGroundTo}(): Make the GROUND Controllable to drive towards a specific coordinate.
--   * @{#CONTROLLABLE.RouteAirTo}(): Make the AIR Controllable to fly towards a specific coordinate.
--   * @{#CONTROLLABLE.RelocateGroundRandomInRadius}(): Relocate the GROUND controllable to a random point in a given radius.
--
-- # 5) Option methods
--
-- Controllable **Option methods** change the behavior of the Controllable while being alive.
--
-- ## 5.1) Rule of Engagement:
--
--   * @{#CONTROLLABLE.OptionROEWeaponFree}
--   * @{#CONTROLLABLE.OptionROEOpenFire}
--   * @{#CONTROLLABLE.OptionROEReturnFire}
--   * @{#CONTROLLABLE.OptionROEEvadeFire}
--
-- To check whether an ROE option is valid for a specific controllable, use:
--
--   * @{#CONTROLLABLE.OptionROEWeaponFreePossible}
--   * @{#CONTROLLABLE.OptionROEOpenFirePossible}
--   * @{#CONTROLLABLE.OptionROEReturnFirePossible}
--   * @{#CONTROLLABLE.OptionROEEvadeFirePossible}
--
-- ## 5.2) Reaction On Thread:
--
--   * @{#CONTROLLABLE.OptionROTNoReaction}
--   * @{#CONTROLLABLE.OptionROTPassiveDefense}
--   * @{#CONTROLLABLE.OptionROTEvadeFire}
--   * @{#CONTROLLABLE.OptionROTVertical}
--
-- To test whether an ROT option is valid for a specific controllable, use:
--
--   * @{#CONTROLLABLE.OptionROTNoReactionPossible}
--   * @{#CONTROLLABLE.OptionROTPassiveDefensePossible}
--   * @{#CONTROLLABLE.OptionROTEvadeFirePossible}
--   * @{#CONTROLLABLE.OptionROTVerticalPossible}
--
-- ## 5.3) Alarm state:
--
--   * @{#CONTROLLABLE.OptionAlarmStateAuto}
--   * @{#CONTROLLABLE.OptionAlarmStateGreen}
--   * @{#CONTROLLABLE.OptionAlarmStateRed}
--
-- ## 5.4) Jettison weapons:
--
--   * @{#CONTROLLABLE.OptionAllowJettisonWeaponsOnThreat}
--   * @{#CONTROLLABLE.OptionKeepWeaponsOnThreat}
--
-- ## 5.5) Air-2-Air missile attack range:
--   * @{#CONTROLLABLE.OptionAAAttackRange}(): Defines the usage of A2A missiles against possible targets.
--   
-- # 6) [GROUND] IR Maker Beacons for GROUPs and UNITs
--  * @{#CONTROLLABLE:NewIRMarker}(): Create a blinking IR Marker on a GROUP or UNIT.
--
-- @field #CONTROLLABLE
CONTROLLABLE = {
  ClassName = "CONTROLLABLE",
  ControllableName = "",
  WayPointFunctions = {},
}

--- Create a new CONTROLLABLE from a DCSControllable
-- @param #CONTROLLABLE self
-- @param #string ControllableName The DCS Controllable name
-- @return #CONTROLLABLE self
function CONTROLLABLE:New( ControllableName )
  local self = BASE:Inherit( self, POSITIONABLE:New( ControllableName ) ) -- #CONTROLLABLE
  -- self:F( ControllableName )
  self.ControllableName = ControllableName

  self.TaskScheduler = SCHEDULER:New( self )
  return self
end

-- DCS Controllable methods support.

--- Get the controller for the CONTROLLABLE.
-- @param #CONTROLLABLE self
-- @return DCS#Controller
function CONTROLLABLE:_GetController()
  local DCSControllable = self:GetDCSObject()

  if DCSControllable then
    local ControllableController = DCSControllable:getController()
    return ControllableController
  end

  return nil
end

-- Get methods

--- Returns the health. Dead controllables have health <= 1.0.
-- @param #CONTROLLABLE self
-- @return #number The controllable health value (unit or group average).
-- @return #nil The controllable is not existing or alive.
function CONTROLLABLE:GetLife()
  self:F2( self.ControllableName )

  local DCSControllable = self:GetDCSObject()

  if DCSControllable then
    local UnitLife = 0
    local Units = self:GetUnits()
    if #Units == 1 then
      local Unit = Units[1] -- Wrapper.Unit#UNIT
      UnitLife = Unit:GetLife()
    else
      local UnitLifeTotal = 0
      for UnitID, Unit in pairs( Units ) do
        local Unit = Unit -- Wrapper.Unit#UNIT
        UnitLifeTotal = UnitLifeTotal + Unit:GetLife()
      end
      UnitLife = UnitLifeTotal / #Units
    end
    return UnitLife
  end

  return nil
end

--- Returns the initial health.
-- @param #CONTROLLABLE self
-- @return #number The controllable health value (unit or group average) or `nil` if the controllable does not exist.
function CONTROLLABLE:GetLife0()
  self:F2( self.ControllableName )

  local DCSControllable = self:GetDCSObject()

  if DCSControllable then
    local UnitLife = 0
    local Units = self:GetUnits()
    if #Units == 1 then
      local Unit = Units[1] -- Wrapper.Unit#UNIT
      UnitLife = Unit:GetLife0()
    else
      local UnitLifeTotal = 0
      for UnitID, Unit in pairs( Units ) do
        local Unit = Unit -- Wrapper.Unit#UNIT
        UnitLifeTotal = UnitLifeTotal + Unit:GetLife0()
      end
      UnitLife = UnitLifeTotal / #Units
    end
    return UnitLife
  end

  return nil
end

--- Returns relative minimum amount of fuel (from 0.0 to 1.0) a unit or group has in its internal tanks.
-- This method returns nil to ensure polymorphic behavior! This method needs to be overridden by GROUP or UNIT.
-- @param #CONTROLLABLE self
-- @return #nil The CONTROLLABLE is not existing or alive.
function CONTROLLABLE:GetFuelMin()
  self:F( self.ControllableName )

  return nil
end

--- Returns relative average amount of fuel (from 0.0 to 1.0) a unit or group has in its internal tanks.
-- This method returns nil to ensure polymorphic behavior! This method needs to be overridden by GROUP or UNIT.
-- @param #CONTROLLABLE self
-- @return #nil The CONTROLLABLE is not existing or alive.
function CONTROLLABLE:GetFuelAve()
  self:F( self.ControllableName )

  return nil
end

--- Returns relative amount of fuel (from 0.0 to 1.0) the unit has in its internal tanks.
-- This method returns nil to ensure polymorphic behavior! This method needs to be overridden by GROUP or UNIT.
-- @param #CONTROLLABLE self
-- @return #nil The CONTROLLABLE is not existing or alive.
function CONTROLLABLE:GetFuel()
  self:F( self.ControllableName )
  return nil
end

-- Tasks

--- Clear all tasks from the controllable.
-- @param #CONTROLLABLE self
-- @return #CONTROLLABLE
function CONTROLLABLE:ClearTasks()

  local DCSControllable = self:GetDCSObject()

  if DCSControllable then
    local Controller = self:_GetController()
    Controller:resetTask()
    return self
  end

  return nil
end

--- Popping current Task from the controllable.
-- @param #CONTROLLABLE self
-- @return #CONTROLLABLE self
function CONTROLLABLE:PopCurrentTask()
  self:F2()

  local DCSControllable = self:GetDCSObject()

  if DCSControllable then
    local Controller = self:_GetController()
    Controller:popTask()
    return self
  end

  return nil
end

--- Pushing Task on the queue from the controllable.
-- @param #CONTROLLABLE self
-- @return #CONTROLLABLE self
function CONTROLLABLE:PushTask( DCSTask, WaitTime )
  self:F2()

  local DCSControllable = self:GetDCSObject()

  if DCSControllable then

    local DCSControllableName = self:GetName()

    -- When a controllable SPAWNs, it takes about a second to get the controllable in the simulator. Setting tasks to unspawned controllables provides unexpected results.
    -- Therefore we schedule the functions to set the mission and options for the Controllable.
    -- Controller:pushTask( DCSTask )

    local function PushTask( Controller, DCSTask )
      if self and self:IsAlive() then
        local Controller = self:_GetController()
        Controller:pushTask( DCSTask )
      else
        BASE:E( { DCSControllableName .. " is not alive anymore.", DCSTask = DCSTask } )
      end
    end

    if not WaitTime or WaitTime == 0 then
      PushTask( self, DCSTask )
    else
      self.TaskScheduler:Schedule( self, PushTask, { DCSTask }, WaitTime )
    end

    return self
  end

  return nil
end

--- Clearing the Task Queue and Setting the Task on the queue from the controllable.
-- @param #CONTROLLABLE self
-- @param DCS#Task DCSTask DCS Task array.
-- @param #number WaitTime Time in seconds, before the task is set.
-- @return #CONTROLLABLE self
function CONTROLLABLE:SetTask( DCSTask, WaitTime )
  self:F( { "SetTask", WaitTime, DCSTask = DCSTask } )

  local DCSControllable = self:GetDCSObject()

  if DCSControllable then

    local DCSControllableName = self:GetName()

    self:T2( "Controllable Name = " .. DCSControllableName )

    -- When a controllable SPAWNs, it takes about a second to get the controllable in the simulator. Setting tasks to unspawned controllables provides unexpected results.
    -- Therefore we schedule the functions to set the mission and options for the Controllable.
    -- Controller.setTask( Controller, DCSTask )

    local function SetTask( Controller, DCSTask )
      if self and self:IsAlive() then
        local Controller = self:_GetController()
        -- self:I( "Before SetTask" )
        Controller:setTask( DCSTask )
        -- AI_FORMATION class (used by RESCUEHELO) calls SetTask twice per second! hence spamming the DCS log file ==> setting this to trace.
        self:T( { ControllableName = self:GetName(), DCSTask = DCSTask } )
      else
        BASE:E( { DCSControllableName .. " is not alive anymore.", DCSTask = DCSTask } )
      end
    end

    if not WaitTime or WaitTime == 0 then
      SetTask( self, DCSTask )
      -- See above.
      self:T( { ControllableName = self:GetName(), DCSTask = DCSTask } )
    else
      self.TaskScheduler:Schedule( self, SetTask, { DCSTask }, WaitTime )
    end

    return self
  end

  return nil
end

--- Checking the Task Queue of the controllable. Returns false if no task is on the queue. true if there is a task.
-- @param #CONTROLLABLE self
-- @return #CONTROLLABLE self
function CONTROLLABLE:HasTask() -- R2.2

  local HasTaskResult = false

  local DCSControllable = self:GetDCSObject()

  if DCSControllable then

    local Controller = self:_GetController()
    HasTaskResult = Controller:hasTask()
  end

  return HasTaskResult
end

--- Return a condition section for a controlled task.
-- @param #CONTROLLABLE self
-- @param DCS#Time time DCS mission time.
-- @param #string userFlag Name of the user flag.
-- @param #boolean userFlagValue User flag value *true* or *false*. Could also be numeric, i.e. either 0=*false* or 1=*true*. Other numeric values don't work!
-- @param #string condition Lua string.
-- @param DCS#Time duration Duration in seconds.
-- @param #number lastWayPoint Last waypoint.
-- return DCS#Task
function CONTROLLABLE:TaskCondition( time, userFlag, userFlagValue, condition, duration, lastWayPoint )

  --[[
 StopCondition = {
   time = Time,
   userFlag = string,
   userFlagValue = boolean,
   condition = string,
   duration = Time,
   lastWaypoint = number,
 }
--]]

  local DCSStopCondition = {}
  DCSStopCondition.time = time
  DCSStopCondition.userFlag = userFlag
  DCSStopCondition.userFlagValue = userFlagValue
  DCSStopCondition.condition = condition
  DCSStopCondition.duration = duration
  DCSStopCondition.lastWayPoint = lastWayPoint

  return DCSStopCondition
end

--- Return a Controlled Task taking a Task and a TaskCondition.
-- @param #CONTROLLABLE self
-- @param DCS#Task DCSTask
-- @param DCS#DCSStopCondition DCSStopCondition
-- @return DCS#Task
function CONTROLLABLE:TaskControlled( DCSTask, DCSStopCondition )

  local DCSTaskControlled = {
    id = 'ControlledTask',
    params = {
      task = DCSTask,
      stopCondition = DCSStopCondition,
    },
  }

  return DCSTaskControlled
end

--- Return a Combo Task taking an array of Tasks.
-- @param #CONTROLLABLE self
-- @param DCS#TaskArray DCSTasks Array of DCSTasking.Task#Task
-- @return DCS#Task
function CONTROLLABLE:TaskCombo( DCSTasks )

  local DCSTaskCombo = {
    id = 'ComboTask',
    params = {
      tasks = DCSTasks,
    },
  }

  return DCSTaskCombo
end

--- Return a WrappedAction Task taking a Command.
-- @param #CONTROLLABLE self
-- @param DCS#Command DCSCommand
-- @return DCS#Task
function CONTROLLABLE:TaskWrappedAction( DCSCommand, Index )

  local DCSTaskWrappedAction = {
    id = "WrappedAction",
    enabled = true,
    number = Index or 1,
    auto = false,
    params = {
      action = DCSCommand,
    },
  }

  return DCSTaskWrappedAction
end

--- Return an Empty Task.
-- @param #CONTROLLABLE self
-- @return DCS#Task
function CONTROLLABLE:TaskEmptyTask()

  local DCSTaskWrappedAction = {
            ["id"] = "WrappedAction",
            ["params"] = {
              ["action"] = {
                ["id"] = "Script",
                ["params"] = {
                  ["command"] = "",
                },
              },
            },
          }

  return DCSTaskWrappedAction
end

--- Set a Task at a Waypoint using a Route list.
-- @param #CONTROLLABLE self
-- @param #table Waypoint The Waypoint!
-- @param DCS#Task Task The Task structure to be executed!
-- @return DCS#Task
function CONTROLLABLE:SetTaskWaypoint( Waypoint, Task )

  Waypoint.task = self:TaskCombo( { Task } )

  self:F( { Waypoint.task } )
  return Waypoint.task
end

--- Executes a command action for the CONTROLLABLE.
-- @param #CONTROLLABLE self
-- @param DCS#Command DCSCommand The command to be executed.
-- @return #CONTROLLABLE self
function CONTROLLABLE:SetCommand( DCSCommand )
  self:F2( DCSCommand )

  local DCSControllable = self:GetDCSObject()

  if DCSControllable then
    local Controller = self:_GetController()
    Controller:setCommand( DCSCommand )
    return self
  end

  return nil
end

--- Perform a switch waypoint command
-- @param #CONTROLLABLE self
-- @param #number FromWayPoint
-- @param #number ToWayPoint
-- @return DCS#Task
-- @usage
--
--   -- This test demonstrates the use(s) of the SwitchWayPoint method of the GROUP class.
--   HeliGroup = GROUP:FindByName( "Helicopter" )
--
--   -- Route the helicopter back to the FARP after 60 seconds.
--   -- We use the SCHEDULER class to do this.
--   SCHEDULER:New( nil,
--     function( HeliGroup )
--       local CommandRTB = HeliGroup:CommandSwitchWayPoint( 2, 8 )
--       HeliGroup:SetCommand( CommandRTB )
--     end, { HeliGroup }, 90
--   )
function CONTROLLABLE:CommandSwitchWayPoint( FromWayPoint, ToWayPoint )
  self:F2( { FromWayPoint, ToWayPoint } )

  local CommandSwitchWayPoint = {
    id = 'SwitchWaypoint',
    params = {
      fromWaypointIndex = FromWayPoint,
      goToWaypointIndex = ToWayPoint,
    },
  }

  self:T3( { CommandSwitchWayPoint } )
  return CommandSwitchWayPoint
end

--- Create a stop route command, which returns a string containing the command.
-- Use the result in the method @{#CONTROLLABLE.SetCommand}().
-- A value of true will make the ground group stop, a value of false will make it continue.
-- Note that this can only work on GROUP level, although individual UNITs can be commanded, the whole GROUP will react.
--
-- Example missions:
--
--   * GRP-310
--
-- @param #CONTROLLABLE self
-- @param #boolean StopRoute true if the ground unit needs to stop, false if it needs to continue to move.
-- @return DCS#Task
function CONTROLLABLE:CommandStopRoute( StopRoute )
  self:F2( { StopRoute } )

  local CommandStopRoute = {
    id = 'StopRoute',
    params = {
      value = StopRoute,
    },
  }

  self:T3( { CommandStopRoute } )
  return CommandStopRoute
end

--- Give an uncontrolled air controllable the start command.
-- @param #CONTROLLABLE self
-- @param #number delay (Optional) Delay before start command in seconds.
-- @return #CONTROLLABLE self
function CONTROLLABLE:StartUncontrolled( delay )
  if delay and delay > 0 then
    SCHEDULER:New( nil, CONTROLLABLE.StartUncontrolled, { self }, delay )
  else
    self:SetCommand( { id = 'Start', params = {} } )
  end
  return self
end

--- Give the CONTROLLABLE the command to activate a beacon. See [DCS_command_activateBeacon](https://wiki.hoggitworld.com/view/DCS_command_activateBeacon) on Hoggit.
-- For specific beacons like TACAN use the more convenient @{#BEACON} class.
-- Note that a controllable can only have one beacon activated at a time with the execption of ICLS.
-- @param #CONTROLLABLE self
-- @param Core.Beacon#BEACON.Type Type Beacon type (VOR, DME, TACAN, RSBN, ILS etc).
-- @param Core.Beacon#BEACON.System System Beacon system (VOR, DME, TACAN, RSBN, ILS etc).
-- @param #number Frequency Frequency in Hz the beacon is running on. Use @{#UTILS.TACANToFrequency} to generate a frequency for TACAN beacons.
-- @param #number UnitID The ID of the unit the beacon is attached to. Useful if more units are in one group.
-- @param #number Channel Channel the beacon is using. For, e.g. TACAN beacons.
-- @param #string ModeChannel The TACAN mode of the beacon, i.e. "X" or "Y".
-- @param #boolean AA If true, create and Air-Air beacon. IF nil, automatically set if CONTROLLABLE depending on whether unit is and aircraft or not.
-- @param #string Callsign Morse code identification callsign.
-- @param #boolean Bearing If true, beacon provides bearing information - if supported by the unit the beacon is attached to.
-- @param #number Delay (Optional) Delay in seconds before the beacon is activated.
-- @return #CONTROLLABLE self
function CONTROLLABLE:CommandActivateBeacon( Type, System, Frequency, UnitID, Channel, ModeChannel, AA, Callsign, Bearing, Delay )

  AA = AA or self:IsAir()
  UnitID = UnitID or self:GetID()

  -- Command
  local CommandActivateBeacon = {
    id = "ActivateBeacon",
    params = {
      ["type"] = Type,
      ["system"] = System,
      ["frequency"] = Frequency,
      ["unitId"] = UnitID,
      ["channel"] = Channel,
      ["modeChannel"] = ModeChannel,
      ["AA"] = AA,
      ["callsign"] = Callsign,
      ["bearing"] = Bearing,
    },
  }

  if Delay and Delay > 0 then
    SCHEDULER:New( nil, self.CommandActivateBeacon, { self, Type, System, Frequency, UnitID, Channel, ModeChannel, AA, Callsign, Bearing }, Delay )
  else
    self:SetCommand( CommandActivateBeacon )
  end

  return self
end

--- Activate ACLS system of the CONTROLLABLE. The controllable should be an aircraft carrier! Also needs Link4 to work.
-- @param #CONTROLLABLE self
-- @param #number UnitID (Optional) The DCS UNIT ID of the unit the ACLS system is attached to. Defaults to the UNIT itself.
-- @param #string Name (Optional) Name of the ACLS Beacon
-- @param #number Delay (Optional) Delay in seconds before the ICLS is activated.
-- @return #CONTROLLABLE self
function CONTROLLABLE:CommandActivateACLS( UnitID, Name, Delay )

  -- Command to activate ACLS system.
  local CommandActivateACLS= {
  id = 'ActivateACLS',
  params = {
    unitId = UnitID or self:GetID(),
    name = Name or "ACL",
  }
}

  self:T({CommandActivateACLS})

  if Delay and Delay > 0 then
    SCHEDULER:New( nil, self.CommandActivateACLS, { self, UnitID, Name }, Delay )
  else
    local controller = self:_GetController()
    controller:setCommand( CommandActivateACLS )
  end

  return self
end

--- Deactivate ACLS system of the CONTROLLABLE. The controllable should be an aircraft carrier!
-- @param #CONTROLLABLE self
-- @param #number Delay (Optional) Delay in seconds before the ICLS is deactivated.
-- @return #CONTROLLABLE self
function CONTROLLABLE:CommandDeactivateACLS( Delay )

  -- Command to activate ACLS system.
  local CommandDeactivateACLS= {
  id = 'DeactivateACLS',
  params = { }
}

  if Delay and Delay > 0 then
    SCHEDULER:New( nil, self.CommandDeactivateACLS, { self }, Delay )
  else
    local controller = self:_GetController()
    controller:setCommand( CommandDeactivateACLS )
  end

  return self
end

--- Activate ICLS system of the CONTROLLABLE. The controllable should be an aircraft carrier!
-- @param #CONTROLLABLE self
-- @param #number Channel ICLS channel.
-- @param #number UnitID The DCS UNIT ID of the unit the ICLS system is attached to. Useful if more units are in one group.
-- @param #string Callsign Morse code identification callsign.
-- @param #number Delay (Optional) Delay in seconds before the ICLS is activated.
-- @return #CONTROLLABLE self
function CONTROLLABLE:CommandActivateICLS( Channel, UnitID, Callsign, Delay )

  -- Command to activate ICLS system.
  local CommandActivateICLS = {
    id = "ActivateICLS",
    params = {
      ["type"] = BEACON.Type.ICLS,
      ["channel"] = Channel,
      ["unitId"] = UnitID or self:GetID(),
      ["callsign"] = Callsign,
    },
  }

  if Delay and Delay > 0 then
    SCHEDULER:New( nil, self.CommandActivateICLS, { self, Channel, UnitID, Callsign }, Delay )
  else
    self:SetCommand( CommandActivateICLS )
  end

  return self
end

--- Activate LINK4 system of the CONTROLLABLE. The controllable should be an aircraft carrier!
-- @param #CONTROLLABLE self
-- @param #number Frequency Link4 Frequency in MHz, e.g. 336 (defaults to 336 MHz)
-- @param #number UnitID (Optional) The DCS UNIT ID of the unit the LINK4 system is attached to. Defaults to the UNIT itself.
-- @param #string Callsign (Optional) Morse code identification callsign.
-- @param #number Delay (Optional) Delay in seconds before the LINK4 is activated.
-- @return #CONTROLLABLE self
function CONTROLLABLE:CommandActivateLink4(Frequency, UnitID, Callsign, Delay)

  local freq = Frequency or 336

  -- Command to activate Link4 system.
  local CommandActivateLink4= {
    id = "ActivateLink4",
    params= {
      ["frequency"] = freq*1000000,
      ["unitId"] = UnitID or self:GetID(),
      ["name"] = Callsign or "LNK",
    }
  }

  self:T({CommandActivateLink4})

  if Delay and Delay>0 then
    SCHEDULER:New(nil, self.CommandActivateLink4, {self, Frequency, UnitID, Callsign}, Delay)
  else
    local controller = self:_GetController()
    controller:setCommand(CommandActivateLink4)
  end

  return self
end

--- Deactivate the active beacon of the CONTROLLABLE.
-- @param #CONTROLLABLE self
-- @param #number Delay (Optional) Delay in seconds before the beacon is deactivated.
-- @return #CONTROLLABLE self
function CONTROLLABLE:CommandDeactivateBeacon( Delay )

  -- Command to deactivate
  local CommandDeactivateBeacon = { id = 'DeactivateBeacon', params = {} }

  local CommandDeactivateBeacon={id='DeactivateBeacon', params={}}

  if Delay and Delay>0 then
    SCHEDULER:New(nil, self.CommandDeactivateBeacon, {self}, Delay)
  else
    self:SetCommand( CommandDeactivateBeacon )
  end

  return self
end

--- Deactivate the active Link4 of the CONTROLLABLE.
-- @param #CONTROLLABLE self
-- @param #number Delay (Optional) Delay in seconds before the Link4 is deactivated.
-- @return #CONTROLLABLE self
function CONTROLLABLE:CommandDeactivateLink4(Delay)

  -- Command to deactivate
  local CommandDeactivateLink4={id='DeactivateLink4', params={}}

  if Delay and Delay>0 then
    SCHEDULER:New(nil, self.CommandDeactivateLink4, {self}, Delay)
  else
    local controller = self:_GetController()
    controller:setCommand(CommandDeactivateLink4)
  end

  return self
end

--- Deactivate the ICLS of the CONTROLLABLE.
-- @param #CONTROLLABLE self
-- @param #number Delay (Optional) Delay in seconds before the ICLS is deactivated.
-- @return #CONTROLLABLE self
function CONTROLLABLE:CommandDeactivateICLS( Delay )

  -- Command to deactivate
  local CommandDeactivateICLS = { id = 'DeactivateICLS', params = {} }

  if Delay and Delay > 0 then
    SCHEDULER:New( nil, self.CommandDeactivateICLS, { self }, Delay )
  else
    self:SetCommand( CommandDeactivateICLS )
  end

  return self
end

--- Set callsign of the CONTROLLABLE. See [DCS command setCallsign](https://wiki.hoggitworld.com/view/DCS_command_setCallsign)
-- @param #CONTROLLABLE self
-- @param DCS#CALLSIGN CallName Number corresponding the the callsign identifier you wish this group to be called.
-- @param #number CallNumber The number value the group will be referred to as. Only valid numbers are 1-9. For example Uzi **5**-1. Default 1.
-- @param #number Delay (Optional) Delay in seconds before the callsign is set. Default is immediately.
-- @return #CONTROLLABLE self
function CONTROLLABLE:CommandSetCallsign( CallName, CallNumber, Delay )

  -- Command to set the callsign.
  local CommandSetCallsign = { id = 'SetCallsign', params = { callname = CallName, number = CallNumber or 1 } }

  if Delay and Delay > 0 then
    SCHEDULER:New( nil, self.CommandSetCallsign, { self, CallName, CallNumber }, Delay )
  else
    self:SetCommand( CommandSetCallsign )
  end

  return self
end

--- Set EPLRS of the CONTROLLABLE on/off. See [DCS command EPLRS](https://wiki.hoggitworld.com/view/DCS_command_eplrs)
-- @param #CONTROLLABLE self
-- @param #boolean SwitchOnOff If true (or nil) switch EPLRS on. If false switch off.
-- @param #number Delay (Optional) Delay in seconds before the callsign is set. Default is immediately.
-- @return #CONTROLLABLE self
function CONTROLLABLE:CommandEPLRS( SwitchOnOff, Delay )

  if SwitchOnOff == nil then
    SwitchOnOff = true
  end

  -- Command to set the callsign.
  local CommandEPLRS = {
    id = 'EPLRS',
    params = {
      value = SwitchOnOff,
      groupId = self:GetID(),
    },
  }
  
  --if self:IsGround() then
   --CommandEPLRS.params.groupId = self:GetID()
  --end
  
  if Delay and Delay > 0 then
    SCHEDULER:New( nil, self.CommandEPLRS, { self, SwitchOnOff }, Delay )
  else
    self:T( string.format( "EPLRS=%s for controllable %s (id=%s)", tostring( SwitchOnOff ), tostring( self:GetName() ), tostring( self:GetID() ) ) )
    self:SetCommand( CommandEPLRS )
  end

  return self
end

--- Set unlimited fuel. See [DCS command Unlimited Fuel](https://wiki.hoggitworld.com/view/DCS_command_setUnlimitedFuel).
-- @param #CONTROLLABLE self
-- @param #boolean OnOff Set unlimited fuel on = true or off = false.
-- @param #number Delay (Optional) Set the option only after x seconds.
-- @return #CONTROLLABLE self
function CONTROLLABLE:CommandSetUnlimitedFuel(OnOff, Delay)

  local CommandSetFuel = {
    id = 'SetUnlimitedFuel',
    params = {
    value = OnOff
  }
}

  if Delay and Delay > 0 then
    SCHEDULER:New( nil, self.CommandSetUnlimitedFuel, { self, OnOff }, Delay )
  else
    self:SetCommand( CommandSetFuel )
  end

  return self
end


--- Set radio frequency. See [DCS command SetFrequency](https://wiki.hoggitworld.com/view/DCS_command_setFrequency)
-- @param #CONTROLLABLE self
-- @param #number Frequency Radio frequency in MHz.
-- @param #number Modulation Radio modulation. Default `radio.modulation.AM`.
-- @param #number Power (Optional) Power of the Radio in Watts. Defaults to 10.
-- @param #number Delay (Optional) Delay in seconds before the frequency is set. Default is immediately.
-- @return #CONTROLLABLE self
function CONTROLLABLE:CommandSetFrequency( Frequency, Modulation, Power, Delay )

  local CommandSetFrequency = {
    id = 'SetFrequency',
    params = {
      frequency = Frequency * 1000000,
      modulation = Modulation or radio.modulation.AM,
      power=Power or 10,
    },
  }

  if Delay and Delay > 0 then
    SCHEDULER:New( nil, self.CommandSetFrequency, { self, Frequency, Modulation, Power },Delay )
  else
    self:SetCommand( CommandSetFrequency )
  end

  return self
end

--- [AIR] Set radio frequency. See [DCS command SetFrequencyForUnit](https://wiki.hoggitworld.com/view/DCS_command_setFrequencyForUnit)
-- @param #CONTROLLABLE self
-- @param #number Frequency Radio frequency in MHz.
-- @param #number Modulation Radio modulation. Default `radio.modulation.AM`.
-- @param #number Power (Optional) Power of the Radio in Watts. Defaults to 10.
-- @param #UnitID UnitID (Optional, if your object is a UNIT) The UNIT ID this is for.
-- @param #number Delay (Optional) Delay in seconds before the frequency is set. Default is immediately.
-- @return #CONTROLLABLE self
function CONTROLLABLE:CommandSetFrequencyForUnit(Frequency,Modulation,Power,UnitID,Delay)
  local CommandSetFrequencyForUnit={
    id='SetFrequencyForUnit',
    params={
        frequency=Frequency*1000000,
        modulation=Modulation or radio.modulation.AM,
        unitId=UnitID or self:GetID(),
        power=Power or 10,
    },
  }
  if Delay and Delay>0 then
    SCHEDULER:New(nil,self.CommandSetFrequencyForUnit,{self,Frequency,Modulation,Power,UnitID},Delay)
  else
    self:SetCommand(CommandSetFrequencyForUnit)
  end
  return self
end

--- Set EPLRS data link on/off.
-- @param #CONTROLLABLE self
-- @param #boolean SwitchOnOff If true (or nil) switch EPLRS on. If false switch off.
-- @param #number idx Task index. Default 1.
-- @return #table Task wrapped action.
function CONTROLLABLE:TaskEPLRS( SwitchOnOff, idx )

  if SwitchOnOff == nil then
    SwitchOnOff = true
  end

  -- Command to set the callsign.
  local CommandEPLRS = {
    id = 'EPLRS',
    params = {
      value = SwitchOnOff,
      groupId = self:GetID(),
    },
  }
  
  --if self:IsGround() then
   --CommandEPLRS.params.groupId = self:GetID()
  --end
  
  return self:TaskWrappedAction( CommandEPLRS, idx or 1 )
end

-- TASKS FOR AIR CONTROLLABLES

--- (AIR + GROUND) Attack a Controllable.
-- @param #CONTROLLABLE self
-- @param Wrapper.Group#GROUP AttackGroup The Group to be attacked.
-- @param #number WeaponType (optional) Bitmask of weapon types those allowed to use. If parameter is not defined that means no limits on weapon usage.
-- @param DCS#AI.Task.WeaponExpend WeaponExpend (optional) Determines how much weapon will be released at each attack. If parameter is not defined the unit / controllable will choose expend on its own discretion.
-- @param #number AttackQty (optional) This parameter limits maximal quantity of attack. The aircraft/controllable will not make more attack than allowed even if the target controllable not destroyed and the aircraft/controllable still have ammo. If not defined the aircraft/controllable will attack target until it will be destroyed or until the aircraft/controllable will run out of ammo.
-- @param DCS#Azimuth Direction (optional) Desired ingress direction from the target to the attacking aircraft. Controllable/aircraft will make its attacks from the direction. Of course if there is no way to attack from the direction due the terrain controllable/aircraft will choose another direction.
-- @param DCS#Distance Altitude (optional) Desired attack start altitude. Controllable/aircraft will make its attacks from the altitude. If the altitude is too low or too high to use weapon aircraft/controllable will choose closest altitude to the desired attack start altitude. If the desired altitude is defined controllable/aircraft will not attack from safe altitude.
-- @param #boolean AttackQtyLimit (optional) The flag determines how to interpret attackQty parameter. If the flag is true then attackQty is a limit on maximal attack quantity for "AttackGroup" and "AttackUnit" tasks. If the flag is false then attackQty is a desired attack quantity for "Bombing" and "BombingRunway" tasks.
-- @param #boolean GroupAttack (Optional) If true, attack as group.
-- @return DCS#Task The DCS task structure.
function CONTROLLABLE:TaskAttackGroup( AttackGroup, WeaponType, WeaponExpend, AttackQty, Direction, Altitude, AttackQtyLimit, GroupAttack )
  -- self:F2( { self.ControllableName, AttackGroup, WeaponType, WeaponExpend, AttackQty, Direction, Altitude, AttackQtyLimit } )

  --  AttackGroup = {
  --   id = 'AttackGroup',
  --   params = {
  --     groupId = Group.ID,
  --     weaponType = number,
  --     expend = enum AI.Task.WeaponExpend,
  --     attackQty = number,
  --     directionEnabled = boolean,
  --     direction = Azimuth,
  --     altitudeEnabled = boolean,
  --     altitude = Distance,
  --     attackQtyLimit = boolean,
  --   }
  -- }


  local DCSTask = { id = 'AttackGroup',
    params = {
      groupId          = AttackGroup:GetID(),
      weaponType       = WeaponType or 1073741822,
      expend           = WeaponExpend or "Auto",
      attackQtyLimit   = AttackQty and true or false,
      attackQty        = AttackQty or 1,
      directionEnabled = Direction and true or false,
      direction        = Direction and math.rad(Direction) or 0,
      altitudeEnabled  = Altitude and true or false,
      altitude         = Altitude,
      groupAttack      = GroupAttack and true or false,
    },
  }

  return DCSTask
end

--- (AIR + GROUND) Attack the Unit.
-- @param #CONTROLLABLE self
-- @param Wrapper.Unit#UNIT AttackUnit The UNIT to be attacked
-- @param #boolean GroupAttack (Optional) If true, all units in the group will attack the Unit when found. Default false.
-- @param DCS#AI.Task.WeaponExpend WeaponExpend (Optional) Determines how many weapons will be released at each attack. If parameter is not defined the unit / controllable will choose expend on its own discretion.
-- @param #number AttackQty (Optional) Limits maximal quantity of attack. The aircraft/controllable will not make more attacks than allowed even if the target controllable not destroyed and the aircraft/controllable still have ammo. If not defined the aircraft/controllable will attack target until it will be destroyed or until the aircraft/controllable will run out of ammo.
-- @param DCS#Azimuth Direction (Optional) Desired ingress direction from the target to the attacking aircraft. Controllable/aircraft will make its attacks from the direction.
-- @param #number Altitude (Optional) The (minimum) altitude in meters from where to attack. Default is altitude of unit to attack but at least 1000 m.
-- @param #number WeaponType (optional) The WeaponType. See [DCS Enumerator Weapon Type](https://wiki.hoggitworld.com/view/DCS_enum_weapon_flag) on Hoggit.
-- @return DCS#Task The DCS task structure.
function CONTROLLABLE:TaskAttackUnit( AttackUnit, GroupAttack, WeaponExpend, AttackQty, Direction, Altitude, WeaponType )

  local DCSTask = {
    id = 'AttackUnit',
    params = {
      unitId           = AttackUnit:GetID(),
      groupAttack      = GroupAttack and GroupAttack or false,
      expend           = WeaponExpend or "Auto",
      directionEnabled = Direction and true or false,
      direction        = Direction and math.rad(Direction) or 0,
      altitudeEnabled  = Altitude and true or false,
      altitude         = Altitude,
      attackQtyLimit   = AttackQty and true or false,
      attackQty        = AttackQty,
      weaponType       = WeaponType or 1073741822,
    },
  }

  return DCSTask
end

--- (AIR) Delivering weapon at the point on the ground.
-- @param #CONTROLLABLE self
-- @param DCS#Vec2 Vec2 2D-coordinates of the point to deliver weapon at.
-- @param #boolean GroupAttack (optional) If true, all units in the group will attack the Unit when found.
-- @param DCS#AI.Task.WeaponExpend WeaponExpend (optional) Determines how much weapon will be released at each attack. If parameter is not defined the unit / controllable will choose expend on its own discretion.
-- @param #number AttackQty (optional) This parameter limits maximal quantity of attack. The aircraft/controllable will not make more attack than allowed even if the target controllable not destroyed and the aircraft/controllable still have ammo. If not defined the aircraft/controllable will attack target until it will be destroyed or until the aircraft/controllable will run out of ammo.
-- @param DCS#Azimuth Direction (optional) Desired ingress direction from the target to the attacking aircraft. Controllable/aircraft will make its attacks from the direction. Of course if there is no way to attack from the direction due the terrain controllable/aircraft will choose another direction.
-- @param #number Altitude (optional) The altitude from where to attack.
-- @param #number WeaponType (optional) The WeaponType.
-- @param #boolean Divebomb (optional) Perform dive bombing. Default false.
-- @return DCS#Task The DCS task structure.
function CONTROLLABLE:TaskBombing( Vec2, GroupAttack, WeaponExpend, AttackQty, Direction, Altitude, WeaponType, Divebomb )

  local DCSTask = {
    id = 'Bombing',
    params = {
      point            = Vec2,
      x                = Vec2.x,
      y                = Vec2.y,
      groupAttack      = GroupAttack and GroupAttack or false,
      expend           = WeaponExpend or "Auto",
      attackQtyLimit   = AttackQty and true or false,
      attackQty        = AttackQty or 1,
      directionEnabled = Direction and true or false,
      direction        = Direction and math.rad(Direction) or 0,
      altitudeEnabled  = Altitude and true or false,
      altitude         = Altitude or 2000,
      weaponType       = WeaponType or 1073741822,
      attackType       = Divebomb and "Dive" or nil,
      },
  }

  return DCSTask
end

--- (AIR) Strafe the point on the ground.
-- @param #CONTROLLABLE self
-- @param DCS#Vec2 Vec2 2D-coordinates of the point to deliver strafing at.
-- @param #number AttackQty (optional) This parameter limits maximal quantity of attack. The aircraft/controllable will not make more attack than allowed even if the target controllable not destroyed and the aircraft/controllable still have ammo. If not defined the aircraft/controllable will attack target until it will be destroyed or until the aircraft/controllable will run out of ammo.
-- @param #number Length (optional) Length of the strafing area.
-- @param #number WeaponType (optional) The WeaponType. WeaponType is a number associated with a [corresponding weapons flags](https://wiki.hoggitworld.com/view/DCS_enum_weapon_flag)
-- @param DCS#AI.Task.WeaponExpend WeaponExpend (optional) Determines how much ammunition will be released at each attack. If parameter is not defined the unit / controllable will choose expend on its own discretion, e.g. AI.Task.WeaponExpend.ALL.
-- @param DCS#Azimuth Direction (optional) Desired ingress direction from the target to the attacking aircraft. Controllable/aircraft will make its attacks from the direction. Of course if there is no way to attack from the direction due the terrain controllable/aircraft will choose another direction.
-- @param #boolean GroupAttack (optional) If true, all units in the group will attack the Unit when found.
-- @return DCS#Task The DCS task structure.
-- @usage
-- local attacker = GROUP:FindByName("Aerial-1")
-- local attackVec2 = ZONE:New("Strafe Attack"):GetVec2()
-- -- Attack with any cannons = 805306368, 4 runs, strafe a field of 200 meters
-- local task = attacker:TaskStrafing(attackVec2,4,200,805306368,AI.Task.WeaponExpend.ALL)
-- attacker:SetTask(task,2)
function CONTROLLABLE:TaskStrafing( Vec2, AttackQty, Length, WeaponType, WeaponExpend, Direction, GroupAttack )

  local DCSTask =  {
    id = 'Strafing',
    params = {
     point = Vec2, -- req
     weaponType = WeaponType or 805337088, -- Default 805337088 corresponds to guns/cannons (805306368) + any rocket (30720). You can set other types but then the AI uses even bombs for a strafing run!
     expend = WeaponExpend or "Auto",
     attackQty = AttackQty or 1,  -- req
     attackQtyLimit = AttackQty~=nil and true or false,
     direction = Direction and math.rad(Direction) or 0,
     directionEnabled = Direction and true or false,
     groupAttack = GroupAttack or false,
     length = Length,
    }
}

  return DCSTask
end

--- (AIR) Attacking the map object (building, structure, etc).
-- @param #CONTROLLABLE self
-- @param DCS#Vec2 Vec2 2D-coordinates of the point to deliver weapon at.
-- @param #boolean GroupAttack (Optional) If true, all units in the group will attack the Unit when found.
-- @param DCS#AI.Task.WeaponExpend WeaponExpend (Optional) Determines how much weapon will be released at each attack. If parameter is not defined the unit will choose expend on its own discretion.
-- @param #number AttackQty (Optional) This parameter limits maximal quantity of attack. The aircraft/controllable will not make more attack than allowed even if the target controllable not destroyed and the aircraft/controllable still have ammo. If not defined the aircraft/controllable will attack target until it will be destroyed or until the aircraft/controllable will run out of ammo.
-- @param DCS#Azimuth Direction (Optional) Desired ingress direction from the target to the attacking aircraft. Controllable/aircraft will make its attacks from the direction. Of course if there is no way to attack from the direction due the terrain controllable/aircraft will choose another direction.
-- @param #number Altitude (Optional) The altitude [meters] from where to attack. Default 30 m.
-- @param #number WeaponType (Optional) The WeaponType. Default Auto=1073741822.
-- @return DCS#Task The DCS task structure.
function CONTROLLABLE:TaskAttackMapObject( Vec2, GroupAttack, WeaponExpend, AttackQty, Direction, Altitude, WeaponType )

  local DCSTask = {
    id = 'AttackMapObject',
    params = {
      point            = Vec2,
      x                = Vec2.x,
      y                = Vec2.y,
      groupAttack      = GroupAttack or false,
      expend           = WeaponExpend or "Auto",
      attackQtyLimit   = AttackQty and true or false,
      directionEnabled = Direction and true or false,
      direction        = Direction and math.rad(Direction) or 0,
      altitudeEnabled  = Altitude and true or false,
      altitude         = Altitude,
      weaponType       = WeaponType or 1073741822,
    },
  }

  return DCSTask
end

--- (AIR) Delivering weapon via CarpetBombing (all bombers in formation release at same time) at the point on the ground.
-- @param #CONTROLLABLE self
-- @param DCS#Vec2 Vec2 2D-coordinates of the point to deliver weapon at.
-- @param #boolean GroupAttack (optional) If true, all units in the group will attack the Unit when found.
-- @param DCS#AI.Task.WeaponExpend WeaponExpend (optional) Determines how much weapon will be released at each attack. If parameter is not defined the unit will choose expend on its own discretion.
-- @param #number AttackQty (optional) This parameter limits maximal quantity of attack. The aircraft/controllable will not make more attack than allowed even if the target controllable not destroyed and the aircraft/controllable still have ammo. If not defined the aircraft/controllable will attack target until it will be destroyed or until the aircraft/controllable will run out of ammo.
-- @param DCS#Azimuth Direction (optional) Desired ingress direction from the target to the attacking aircraft. Controllable/aircraft will make its attacks from the direction. Of course if there is no way to attack from the direction due the terrain controllable/aircraft will choose another direction.
-- @param #number Altitude (optional) The altitude from where to attack.
-- @param #number WeaponType (optional) The WeaponType.
-- @param #number CarpetLength (optional) default to 500 m.
-- @return DCS#Task The DCS task structure.
function CONTROLLABLE:TaskCarpetBombing( Vec2, GroupAttack, WeaponExpend, AttackQty, Direction, Altitude, WeaponType, CarpetLength )

  -- Build Task Structure
  local DCSTask = {
    id = 'CarpetBombing',
    params = {
      attackType       = "Carpet",
      x                = Vec2.x,
      y                = Vec2.y,
      groupAttack      = GroupAttack and GroupAttack or false,
      carpetLength     = CarpetLength or 500,
      weaponType       = WeaponType or ENUMS.WeaponFlag.AnyBomb,
      expend           = WeaponExpend or "All",
      attackQtyLimit   = AttackQty and true or false,
      attackQty        = AttackQty or 1,
      directionEnabled = Direction and true or false,
      direction        = Direction and math.rad(Direction) or 0,
      altitudeEnabled  = Altitude and true or false,
      altitude         = Altitude,
    },
  }

  return DCSTask
end

--- (AIR) Following another airborne controllable.
-- The unit / controllable will follow lead unit of another controllable, wingmens of both controllables will continue following their leaders.
-- Used to support CarpetBombing Task
-- @param #CONTROLLABLE self
-- @param #CONTROLLABLE FollowControllable The controllable to be followed.
-- @param DCS#Vec3 Vec3 Position of the unit / lead unit of the controllable relative lead unit of another controllable in frame reference oriented by course of lead unit of another controllable. If another controllable is on land the unit / controllable will orbit around.
-- @param #number LastWaypointIndex Detach waypoint of another controllable. Once reached the unit / controllable Follow task is finished.
-- @return DCS#Task The DCS task structure.
function CONTROLLABLE:TaskFollowBigFormation( FollowControllable, Vec3, LastWaypointIndex )

  local DCSTask = {
    id = 'FollowBigFormation',
    params = {
      groupId          = FollowControllable:GetID(),
      pos              = Vec3,
      lastWptIndexFlag = LastWaypointIndex and true or false,
      lastWptIndex     = LastWaypointIndex,
    },
  }

  return DCSTask
end

--- (AIR HELICOPTER) Move the controllable to a Vec2 Point, wait for a defined duration and embark infantry groups.
-- @param #CONTROLLABLE self
-- @param Core.Point#COORDINATE Coordinate The point where to pickup the troops.
-- @param Core.Set#SET_GROUP GroupSetForEmbarking Set of groups to embark.
-- @param #number Duration (Optional) The maximum duration in seconds to wait until all groups have embarked.
-- @param #table Distribution (Optional) Distribution used to put the infantry groups into specific carrier units.
-- @return DCS#Task The DCS task structure.
function CONTROLLABLE:TaskEmbarking( Coordinate, GroupSetForEmbarking, Duration, Distribution )

  -- Table of group IDs for embarking.
  local g4e = {}

  if GroupSetForEmbarking then
    for _, _group in pairs( GroupSetForEmbarking:GetSet() ) do
      local group = _group -- Wrapper.Group#GROUP
      table.insert( g4e, group:GetID() )
    end
  else
    self:E( "ERROR: No groups for embarking specified!" )
    return nil
  end

  -- Table of group IDs for embarking.
  -- local Distribution={}

  -- Distribution
  -- local distribution={}
  -- distribution[id]=gids

  local groupID = self and self:GetID()

  local DCSTask = {
    id = 'Embarking',
    params = {
      selectedTransport  = groupID,
      x                  = Coordinate.x,
      y                  = Coordinate.z,
      groupsForEmbarking = g4e,
      durationFlag       = Duration and true or false,
      duration           = Duration,
      distributionFlag   = Distribution and true or false,
      distribution       = Distribution,
    },
  }

  return DCSTask
end

--- Used in conjunction with the embarking task for a transport helicopter group. The Ground units will move to the specified location and wait to be picked up by a helicopter.
-- The helicopter will then fly them to their dropoff point defined by another task for the ground forces; DisembarkFromTransport task.
-- The controllable has to be an infantry group!
-- @param #CONTROLLABLE self
-- @param Core.Point#COORDINATE Coordinate Coordinates where AI is expecting to be picked up.
-- @param #number Radius Radius in meters. Default 200 m.
-- @param #string UnitType The unit type name of the carrier, e.g. "UH-1H". Must not be specified.
-- @return DCS#Task Embark to transport task.
function CONTROLLABLE:TaskEmbarkToTransport( Coordinate, Radius, UnitType )

  local EmbarkToTransport = {
   id = "EmbarkToTransport",
   params={
       x            = Coordinate.x,
       y            = Coordinate.z,
       zoneRadius   = Radius or 200,
       selectedType = UnitType,
     },
   }

  return EmbarkToTransport
end

--- Specifies the location infantry groups that is being transported by helicopters will be unloaded at. Used in conjunction with the EmbarkToTransport task.
-- @param #CONTROLLABLE self
-- @param Core.Point#COORDINATE Coordinate Coordinates where AI is expecting to be picked up.
-- @return DCS#Task Embark to transport task.
function CONTROLLABLE:TaskDisembarking( Coordinate, GroupSetToDisembark )

  -- Table of group IDs for disembarking.
  local g4e = {}

  if GroupSetToDisembark then
    for _, _group in pairs( GroupSetToDisembark:GetSet() ) do
      local group = _group -- Wrapper.Group#GROUP
      table.insert( g4e, group:GetID() )
    end
  else
    self:E( "ERROR: No groups for disembarking specified!" )
    return nil
  end

  local Disembarking = {
    id = "Disembarking",
    params = {
      x = Coordinate.x,
      y = Coordinate.z,
      groupsForEmbarking = g4e, -- This is no bug, the entry is really "groupsForEmbarking" even if we disembark the troops.
    },
  }

  return Disembarking
end

--- (AIR) Orbit at a specified position at a specified altitude during a specified duration with a specified speed.
-- @param #CONTROLLABLE self
-- @param DCS#Vec2 Point The point to hold the position.
-- @param #number Altitude The altitude AGL in meters to hold the position.
-- @param #number Speed The speed [m/s] flying when holding the position.
-- @return #CONTROLLABLE self
function CONTROLLABLE:TaskOrbitCircleAtVec2( Point, Altitude, Speed )
  self:F2( { self.ControllableName, Point, Altitude, Speed } )

  local DCSTask = {
    id = 'Orbit',
    params = {
      pattern  = AI.Task.OrbitPattern.CIRCLE,
      point    = Point,
      speed    = Speed,
      altitude = Altitude + land.getHeight( Point ),
    },
  }

  return DCSTask
end

--- (AIR) Orbit at a position with at a given altitude and speed. Optionally, a race track pattern can be specified.
-- @param #CONTROLLABLE self
-- @param Core.Point#COORDINATE Coord Coordinate at which the CONTROLLABLE orbits. Can also be given as a `DCS#Vec3` or `DCS#Vec2` object.
-- @param #number Altitude Altitude in meters of the orbit pattern. Default y component of Coord.
-- @param #number Speed Speed [m/s] flying the orbit pattern. Default 128 m/s = 250 knots.
-- @param Core.Point#COORDINATE CoordRaceTrack (Optional) If this coordinate is specified, the CONTROLLABLE will fly a race-track pattern using this and the initial coordinate.
-- @return #CONTROLLABLE self
function CONTROLLABLE:TaskOrbit( Coord, Altitude, Speed, CoordRaceTrack )

  local Pattern = AI.Task.OrbitPattern.CIRCLE

  local P1 = {x=Coord.x, y=Coord.z or Coord.y}
  local P2 = nil
  if CoordRaceTrack then
    Pattern = AI.Task.OrbitPattern.RACE_TRACK
    P2 = {x=CoordRaceTrack.x, y=CoordRaceTrack.z or CoordRaceTrack.y}
  end

  local Task = {
    id = 'Orbit',
    params = {
      pattern  = Pattern,
      point    = P1,
      point2   = P2,
      speed    = Speed or UTILS.KnotsToMps(250),
      altitude = Altitude or Coord.y,
    },
  }

  return Task
end

--- (AIR) Orbit at the current position of the first unit of the controllable at a specified altitude.
-- @param #CONTROLLABLE self
-- @param #number Altitude The altitude [m] to hold the position.
-- @param #number Speed The speed [m/s] flying when holding the position.
-- @param Core.Point#COORDINATE Coordinate (Optional) The coordinate where to orbit. If the coordinate is not given, then the current position of the controllable is used.
-- @return #CONTROLLABLE self
function CONTROLLABLE:TaskOrbitCircle( Altitude, Speed, Coordinate )
  self:F2( { self.ControllableName, Altitude, Speed } )

  local DCSControllable = self:GetDCSObject()

  if DCSControllable then
    local OrbitVec2 = Coordinate and Coordinate:GetVec2() or self:GetVec2()
    return self:TaskOrbitCircleAtVec2( OrbitVec2, Altitude, Speed )
  end

  return nil
end

--- (AIR) Hold position at the current position of the first unit of the controllable.
-- @param #CONTROLLABLE self
-- @param #number Duration The maximum duration in seconds to hold the position.
-- @return #CONTROLLABLE self
function CONTROLLABLE:TaskHoldPosition()
  self:F2( { self.ControllableName } )

  return self:TaskOrbitCircle( 30, 10 )
end

--- (AIR) Delivering weapon on the runway. See [hoggit](https://wiki.hoggitworld.com/view/DCS_task_bombingRunway)
--
-- Make sure the aircraft has the following role:
--
-- * CAS
-- * Ground Attack
-- * Runway Attack
-- * Anti-Ship Strike
-- * AFAC
-- * Pinpoint Strike
--
-- @param #CONTROLLABLE self
-- @param Wrapper.Airbase#AIRBASE Airbase Airbase to attack.
-- @param #number WeaponType (optional) Bitmask of weapon types those allowed to use. See [DCS enum weapon flag](https://wiki.hoggitworld.com/view/DCS_enum_weapon_flag). Default 2147485694 = AnyBomb (GuidedBomb + AnyUnguidedBomb).
-- @param DCS#AI.Task.WeaponExpend WeaponExpend Enum AI.Task.WeaponExpend that defines how much munitions the AI will expend per attack run. Default "ALL".
-- @param #number AttackQty Number of times the group will attack if the target. Default 1.
-- @param DCS#Azimuth Direction (optional) Desired ingress direction from the target to the attacking aircraft. Controllable/aircraft will make its attacks from the direction. Of course if there is no way to attack from the direction due the terrain controllable/aircraft will choose another direction.
-- @param #boolean GroupAttack (optional) Flag indicates that the target must be engaged by all aircrafts of the controllable. Has effect only if the task is assigned to a group and not to a single aircraft.
-- @return DCS#Task The DCS task structure.
function CONTROLLABLE:TaskBombingRunway( Airbase, WeaponType, WeaponExpend, AttackQty, Direction, GroupAttack )

  local DCSTask = {
    id = 'BombingRunway',
    params = {
    runwayId    = Airbase:GetID(),
    weaponType  = WeaponType or ENUMS.WeaponFlag.AnyBomb,
    expend      = WeaponExpend or AI.Task.WeaponExpend.ALL,
    attackQty   = AttackQty or 1,
    direction   = Direction and math.rad(Direction) or 0,
    groupAttack = GroupAttack and true or false,
    },
  }

  return DCSTask
end

--- (AIR) Refueling from the nearest tanker. No parameters.
-- @param #CONTROLLABLE self
-- @return DCS#Task The DCS task structure.
function CONTROLLABLE:TaskRefueling()

  local DCSTask = {
    id = 'Refueling',
    params = {},
  }

  return DCSTask
end

--- (AIR) Act as Recovery Tanker for a naval/carrier group.
-- @param #CONTROLLABLE self
-- @param Wrapper.Group#GROUP CarrierGroup
-- @param #number Speed Speed in meters per second
-- @param #number Altitude Altitude the tanker orbits at in meters
-- @param #number LastWptNumber (optional) Waypoint of carrier group that when reached, ends the recovery tanker task
-- @return DCS#Task The DCS task structure.
function CONTROLLABLE:TaskRecoveryTanker(CarrierGroup, Speed, Altitude, LastWptNumber)

  local LastWptFlag = type(LastWptNumber) == "number" and true or false

  local DCSTask = {
   id = "RecoveryTanker",
   params = {
       groupId = CarrierGroup:GetID(),
       speed = Speed,
       altitude = Altitude,
       lastWptIndexFlag = LastWptFlag,
       lastWptIndex = LastWptNumber
      }
    }

  return DCSTask
end

--- (AIR HELICOPTER) Landing at the ground. For helicopters only.
-- @param #CONTROLLABLE self
-- @param DCS#Vec2 Vec2 The point where to land.
-- @param #number Duration The duration in seconds to stay on the ground.
-- @param #boolean CombatLanding (optional) If true, set the Combat Landing option.
-- @param #number DirectionAfterLand (optional) Heading after landing in degrees.
-- @return #CONTROLLABLE self
function CONTROLLABLE:TaskLandAtVec2( Vec2, Duration , CombatLanding, DirectionAfterLand)

  local DCSTask = {
    id = 'Land',
    params = {
      point        = Vec2,
      durationFlag = Duration and true or false,
      duration     = Duration,
      combatLandingFlag = CombatLanding == true and true or false,
    },
  }
  
  if DirectionAfterLand ~= nil and type(DirectionAfterLand) == "number" then
    DCSTask.params.directionEnabled = true
    DCSTask.params.direction = math.rad(DirectionAfterLand) 
  end
  
  return DCSTask
end

--- (AIR) Land the controllable at a @{Core.Zone#ZONE_RADIUS).
-- @param #CONTROLLABLE self
-- @param Core.Zone#ZONE Zone The zone where to land.
-- @param #number Duration The duration in seconds to stay on the ground.
-- @param #boolean RandomPoint (optional) If true,land at a random point inside of the zone. 
-- @param #boolean CombatLanding (optional) If true, set the Combat Landing option.
-- @param #number DirectionAfterLand (optional) Heading after landing in degrees.
-- @return DCS#Task The DCS task structure.
function CONTROLLABLE:TaskLandAtZone( Zone, Duration, RandomPoint, CombatLanding, DirectionAfterLand )

  -- Get landing point
  local Point = RandomPoint and Zone:GetRandomVec2() or Zone:GetVec2()

  local DCSTask = CONTROLLABLE.TaskLandAtVec2( self, Point, Duration, CombatLanding, DirectionAfterLand)

  return DCSTask
end

--- (AIR) Following another airborne controllable.
-- The unit / controllable will follow lead unit of another controllable, wingmens of both controllables will continue following their leaders.
-- If another controllable is on land the unit / controllable will orbit around.
-- @param #CONTROLLABLE self
-- @param #CONTROLLABLE FollowControllable The controllable to be followed.
-- @param DCS#Vec3 Vec3 Position of the unit / lead unit of the controllable relative lead unit of another controllable in frame reference oriented by course of lead unit of another controllable. If another controllable is on land the unit / controllable will orbit around.
-- @param #number LastWaypointIndex Detach waypoint of another controllable. Once reached the unit / controllable Follow task is finished.
-- @return DCS#Task The DCS task structure.
function CONTROLLABLE:TaskFollow( FollowControllable, Vec3, LastWaypointIndex )
  self:F2( { self.ControllableName, FollowControllable, Vec3, LastWaypointIndex } )

  --  Follow = {
  --    id = 'Follow',
  --    params = {
  --      groupId = Group.ID,
  --      pos = Vec3,
  --      lastWptIndexFlag = boolean,
  --      lastWptIndex = number
  --    }
  --  }

  local LastWaypointIndexFlag = false
  local lastWptIndexFlagChangedManually = false
  if LastWaypointIndex then
    LastWaypointIndexFlag = true
    lastWptIndexFlagChangedManually = true
  end

  local DCSTask = {
    id = 'Follow',
    params = {
      groupId                         = FollowControllable:GetID(),
      pos                             = Vec3,
      lastWptIndexFlag                = LastWaypointIndexFlag,
      lastWptIndex                    = LastWaypointIndex,
      lastWptIndexFlagChangedManually = lastWptIndexFlagChangedManually,
    },
  }

  self:T3( { DCSTask } )
  return DCSTask
end

--- (AIR/HELO) Escort a ground controllable.
-- The unit / controllable will follow lead unit of the other controllable, additional units of both controllables will continue following their leaders.
-- The unit / controllable will also protect that controllable from threats of specified types.
-- @param #CONTROLLABLE self
-- @param #CONTROLLABLE FollowControllable The controllable to be escorted.
-- @param #number LastWaypointIndex (optional) Detach waypoint of another controllable. Once reached the unit / controllable Escort task is finished.
-- @param #number OrbitDistance (optional) Maximum distance helo will orbit around the ground unit in meters. Defaults to 2000 meters.
-- @param DCS#AttributeNameArray TargetTypes (optional) Array of AttributeName that is contains threat categories allowed to engage. Default {"Ground vehicles"}. See [https://wiki.hoggit.us/view/DCS_enum_attributes](https://wiki.hoggit.us/view/DCS_enum_attributes)
-- @return DCS#Task The DCS task structure.
function CONTROLLABLE:TaskGroundEscort( FollowControllable, LastWaypointIndex, OrbitDistance, TargetTypes )

  --  Escort = {
  --    id = 'GroundEscort',
  --    params = {
  --      groupId = Group.ID, -- must
  --      engagementDistMax = Distance, -- Must. With his task it does not appear to actually define the range AI are allowed to attack at, rather it defines the size length of the orbit. The helicopters will fly up to this set distance before returning to the escorted group.
  --      lastWptIndexFlag = boolean, -- optional
  --      lastWptIndex = number, -- optional
  --      targetTypes = array of AttributeName, -- must
  --      lastWptIndexFlagChangedManually = boolean, -- must be true
  --    }
  --  }

  local DCSTask = {
    id = 'GroundEscort',
    params = {
    groupId           = FollowControllable and FollowControllable:GetID() or nil,
    engagementDistMax = OrbitDistance or 2000,
    lastWptIndexFlag  = LastWaypointIndex and true or false,
    lastWptIndex      = LastWaypointIndex,
    targetTypes       = TargetTypes or {"Ground vehicles"},
    lastWptIndexFlagChangedManually = true,
    },
  }

  return DCSTask
end

--- (AIR) Escort another airborne controllable.
-- The unit / controllable will follow lead unit of another controllable, wingmens of both controllables will continue following their leaders.
-- The unit / controllable will also protect that controllable from threats of specified types.
-- @param #CONTROLLABLE self
-- @param #CONTROLLABLE FollowControllable The controllable to be escorted.
-- @param DCS#Vec3 Vec3 Position of the unit / lead unit of the controllable relative lead unit of another controllable in frame reference oriented by course of lead unit of another controllable. If another controllable is on land the unit / controllable will orbit around.
-- @param #number LastWaypointIndex Detach waypoint of another controllable. Once reached the unit / controllable Escort task is finished.
-- @param #number EngagementDistance Maximal distance from escorted controllable to threat in meters. If the threat is already engaged by escort escort will disengage if the distance becomes greater than 1.5 * engagementDistMax.
-- @param DCS#AttributeNameArray TargetTypes Array of AttributeName that is contains threat categories allowed to engage. Default {"Air"}. See https://wiki.hoggit.us/view/DCS_enum_attributes
-- @return DCS#Task The DCS task structure.
function CONTROLLABLE:TaskEscort( FollowControllable, Vec3, LastWaypointIndex, EngagementDistance, TargetTypes )

  --  Escort = {
  --    id = 'Escort',
  --    params = {
  --      groupId = Group.ID,
  --      pos = Vec3,
  --      lastWptIndexFlag = boolean,
  --      lastWptIndex = number,
  --      engagementDistMax = Distance,
  --      targetTypes = array of AttributeName,
  --    }
  --  }

  local DCSTask = {
    id = 'Escort',
    params = {
      groupId           = FollowControllable and FollowControllable:GetID() or nil,
      pos               = Vec3,
      lastWptIndexFlag  = LastWaypointIndex and true or false,
      lastWptIndex      = LastWaypointIndex,
      engagementDistMax = EngagementDistance,
      targetTypes       = TargetTypes or {"Air"},
    },
  }

  return DCSTask
end

-- GROUND TASKS

--- (GROUND) Fire at a VEC2 point until ammunition is finished.
-- @param #CONTROLLABLE self
-- @param DCS#Vec2 Vec2 The point to fire at.
-- @param DCS#Distance Radius The radius of the zone to deploy the fire at.
-- @param #number AmmoCount (optional) Quantity of ammunition to expand (omit to fire until ammunition is depleted).
-- @param #number WeaponType (optional) Enum for weapon type ID. This value is only required if you want the group firing to use a specific weapon, for instance using the task on a ship to force it to fire guided missiles at targets within cannon range. See http://wiki.hoggit.us/view/DCS_enum_weapon_flag
-- @param #number Altitude (Optional) Altitude in meters.
-- @param #number ASL Altitude is above mean sea level. Default is above ground level.
-- @return DCS#Task The DCS task structure.
function CONTROLLABLE:TaskFireAtPoint( Vec2, Radius, AmmoCount, WeaponType, Altitude, ASL )

  local DCSTask = {
    id = 'FireAtPoint',
    params = {
      point            = Vec2,
      x                = Vec2.x,
      y                = Vec2.y,
      zoneRadius       = Radius,
      radius           = Radius,
      expendQty        = 1, -- dummy value
      expendQtyEnabled = false,
      alt_type         = ASL and 0 or 1,
    },
  }

  if AmmoCount then
    DCSTask.params.expendQty = AmmoCount
    DCSTask.params.expendQtyEnabled = true
  end

  if Altitude then
    DCSTask.params.altitude = Altitude
  end

  if WeaponType then
    DCSTask.params.weaponType = WeaponType
  end

  --env.info("FF fireatpoint")
  --BASE:I(DCSTask)

  return DCSTask
end

--- (GROUND) Hold ground controllable from moving.
-- @param #CONTROLLABLE self
-- @return DCS#Task The DCS task structure.
function CONTROLLABLE:TaskHold()
  local DCSTask = { id = 'Hold', params = {} }
  return DCSTask
end

-- TASKS FOR AIRBORNE AND GROUND UNITS/CONTROLLABLES

--- (AIR + GROUND) The task makes the controllable/unit a FAC and orders the FAC to control the target (enemy ground controllable) destruction.
-- The killer is player-controlled allied CAS-aircraft that is in contact with the FAC.
-- If the task is assigned to the controllable lead unit will be a FAC.
-- It's important to note that depending on the type of unit that is being assigned the task (AIR or GROUND), you must choose the correct type of callsign enumerator. For airborne controllables use CALLSIGN.Aircraft and for ground based use CALLSIGN.JTAC enumerators.
-- @param #CONTROLLABLE self
-- @param Wrapper.Group#GROUP AttackGroup Target GROUP object.
-- @param #number WeaponType Bitmask of weapon types, which are allowed to use.
-- @param DCS#AI.Task.Designation Designation (Optional) Designation type.
-- @param #boolean Datalink (Optional) Allows to use datalink to send the target information to attack aircraft. Enabled by default.
-- @param #number Frequency Frequency in MHz used to communicate with the FAC. Default 133 MHz.
-- @param #number Modulation Modulation of radio for communication. Default 0=AM.
-- @param #number CallsignName Callsign enumerator name of the FAC. (CALLSIGN.Aircraft.{name} for airborne controllables, CALLSIGN.JTACS.{name} for ground units)
-- @param #number CallsignNumber Callsign number, e.g. Axeman-**1**.
-- @return DCS#Task The DCS task structure.
function CONTROLLABLE:TaskFAC_AttackGroup( AttackGroup, WeaponType, Designation, Datalink, Frequency, Modulation, CallsignName, CallsignNumber )

  local DCSTask = {
    id = 'FAC_AttackGroup',
    params = {
      groupId     = AttackGroup:GetID(),
      weaponType  = WeaponType or ENUMS.WeaponFlag.AutoDCS,
      designation = Designation or "Auto",
      datalink    = Datalink and Datalink or true,
      frequency   = (Frequency or 133)*1000000,
      modulation  = Modulation or radio.modulation.AM,
      callname    = CallsignName,
      number      = CallsignNumber,
    },
  }

  return DCSTask
end

-- EN-ACT_ROUTE TASKS FOR AIRBORNE CONTROLLABLES

--- (AIR) Engaging targets of defined types.
-- @param #CONTROLLABLE self
-- @param DCS#Distance Distance Maximal distance from the target to a route leg. If the target is on a greater distance it will be ignored.
-- @param DCS#AttributeNameArray TargetTypes Array of target categories allowed to engage.
-- @param #number Priority All enroute tasks have the priority parameter. This is a number (less value - higher priority) that determines actions related to what task will be performed first. Default 0.
-- @return DCS#Task The DCS task structure.
function CONTROLLABLE:EnRouteTaskEngageTargets( Distance, TargetTypes, Priority )

  local DCSTask = {
    id = 'EngageTargets',
    params = {
      maxDistEnabled = Distance and true or false,
      maxDist        = Distance,
      targetTypes    = TargetTypes or {"Air"},
      priority       = Priority or 0,
    },
  }

  return DCSTask
end

--- (AIR) Engaging a targets of defined types at circle-shaped zone.
-- @param #CONTROLLABLE self
-- @param DCS#Vec2 Vec2 2D-coordinates of the zone.
-- @param DCS#Distance Radius Radius of the zone.
-- @param DCS#AttributeNameArray TargetTypes (Optional) Array of target categories allowed to engage. Default {"Air"}.
-- @param #number Priority (Optional) All en-route tasks have the priority parameter. This is a number (less value - higher priority) that determines actions related to what task will be performed first. Default 0.
-- @return DCS#Task The DCS task structure.
function CONTROLLABLE:EnRouteTaskEngageTargetsInZone( Vec2, Radius, TargetTypes, Priority )

  local DCSTask = {
    id = 'EngageTargetsInZone',
    params = {
      point       = Vec2,
      zoneRadius  = Radius,
      targetTypes = TargetTypes or {"Air"},
      priority    = Priority or 0
    },
  }

  return DCSTask
end

--- (AIR) Enroute anti-ship task.
-- @param #CONTROLLABLE self
-- @param DCS#AttributeNameArray TargetTypes Array of target categories allowed to engage. Default `{"Ships"}`.
-- @param #number Priority (Optional) All en-route tasks have the priority parameter. This is a number (less value - higher priority) that determines actions related to what task will be performed first. Default 0.
-- @return DCS#Task The DCS task structure.
function CONTROLLABLE:EnRouteTaskAntiShip(TargetTypes, Priority)

  local DCSTask = {
    id      = 'EngageTargets',
    key     = "AntiShip",
    --auto    = false,
    --enabled = true,
    params  = {
      targetTypes = TargetTypes or {"Ships"},
      priority    = Priority or 0
    }
  }

  return DCSTask
end

--- (AIR) Enroute SEAD task.
-- @param #CONTROLLABLE self
-- @param DCS#AttributeNameArray TargetTypes Array of target categories allowed to engage. Default `{"Air Defence"}`.
-- @param #number Priority (Optional) All en-route tasks have the priority parameter. This is a number (less value - higher priority) that determines actions related to what task will be performed first. Default 0.
-- @return DCS#Task The DCS task structure.
function CONTROLLABLE:EnRouteTaskSEAD(TargetTypes, Priority)

  local DCSTask = {
    id      = 'EngageTargets',
    key     = "SEAD",
    --auto    = false,
    --enabled = true,
    params  = {
      targetTypes = TargetTypes or {"Air Defence"},
      priority    = Priority or 0
    }
  }

  return DCSTask
end

--- (AIR) Enroute CAP task.
-- @param #CONTROLLABLE self
-- @param DCS#AttributeNameArray TargetTypes Array of target categories allowed to engage. Default `{"Air"}`.
-- @param #number Priority (Optional) All en-route tasks have the priority parameter. This is a number (less value - higher priority) that determines actions related to what task will be performed first. Default 0.
-- @return DCS#Task The DCS task structure.
function CONTROLLABLE:EnRouteTaskCAP(TargetTypes, Priority)

  local DCSTask = {
    id      = 'EngageTargets',
    key     = "CAP",
    --auto    = true,
    enabled = true,
    params  = {
      targetTypes = TargetTypes or {"Air"},
      priority    = Priority or 0
    }
  }

  return DCSTask
end

--- (AIR) Engaging a controllable. The task does not assign the target controllable to the unit/controllable to attack now;
-- it just allows the unit/controllable to engage the target controllable as well as other assigned targets.
-- See [hoggit](https://wiki.hoggitworld.com/view/DCS_task_engageGroup).
-- @param #CONTROLLABLE self
-- @param #CONTROLLABLE AttackGroup The Controllable to be attacked.
-- @param #number Priority All en-route tasks have the priority parameter. This is a number (less value - higher priority) that determines actions related to what task will be performed first.
-- @param #number WeaponType (optional) Bitmask of weapon types those allowed to use. If parameter is not defined that means no limits on weapon usage.
-- @param DCS#AI.Task.WeaponExpend WeaponExpend (optional) Determines how much weapon will be released at each attack. If parameter is not defined the unit / controllable will choose expend on its own discretion.
-- @param #number AttackQty (optional) This parameter limits maximal quantity of attack. The aircraft/controllable will not make more attack than allowed even if the target controllable not destroyed and the aircraft/controllable still have ammo. If not defined the aircraft/controllable will attack target until it will be destroyed or until the aircraft/controllable will run out of ammo.
-- @param DCS#Azimuth Direction (optional) Desired ingress direction from the target to the attacking aircraft. Controllable/aircraft will make its attacks from the direction. Of course if there is no way to attack from the direction due the terrain controllable/aircraft will choose another direction.
-- @param DCS#Distance Altitude (optional) Desired attack start altitude. Controllable/aircraft will make its attacks from the altitude. If the altitude is too low or too high to use weapon aircraft/controllable will choose closest altitude to the desired attack start altitude. If the desired altitude is defined controllable/aircraft will not attack from safe altitude.
-- @param #boolean AttackQtyLimit (optional) The flag determines how to interpret attackQty parameter. If the flag is true then attackQty is a limit on maximal attack quantity for "AttackGroup" and "AttackUnit" tasks. If the flag is false then attackQty is a desired attack quantity for "Bombing" and "BombingRunway" tasks.
-- @return DCS#Task The DCS task structure.
function CONTROLLABLE:EnRouteTaskEngageGroup( AttackGroup, Priority, WeaponType, WeaponExpend, AttackQty, Direction, Altitude, AttackQtyLimit )

  local DCSTask = {
    id = 'EngageGroup',
    params = {
      groupId          = AttackGroup:GetID(),
      weaponType       = WeaponType,
      expend           = WeaponExpend or "Auto",
      directionEnabled = Direction and true or false,
      direction        = Direction,
      altitudeEnabled  = Altitude and true or false,
      altitude         = Altitude,
      attackQtyLimit   = AttackQty and true or false,
      attackQty        = AttackQty,
      priority         = Priority or 1,
    },
  }

  return DCSTask
end

--- (AIR) Search and attack the Unit.
-- See [hoggit](https://wiki.hoggitworld.com/view/DCS_task_engageUnit).
-- @param #CONTROLLABLE self
-- @param Wrapper.Unit#UNIT EngageUnit The UNIT.
-- @param #number Priority (optional) All en-route tasks have the priority parameter. This is a number (less value - higher priority) that determines actions related to what task will be performed first.
-- @param #boolean GroupAttack (optional) If true, all units in the group will attack the Unit when found.
-- @param DCS#AI.Task.WeaponExpend WeaponExpend (optional) Determines how much weapon will be released at each attack. If parameter is not defined the unit / controllable will choose expend on its own discretion.
-- @param #number AttackQty (optional) This parameter limits maximal quantity of attack. The aircraft/controllable will not make more attack than allowed even if the target controllable not destroyed and the aircraft/controllable still have ammo. If not defined the aircraft/controllable will attack target until it will be destroyed or until the aircraft/controllable will run out of ammo.
-- @param DCS#Azimuth Direction (optional) Desired ingress direction from the target to the attacking aircraft. Controllable/aircraft will make its attacks from the direction. Of course if there is no way to attack from the direction due the terrain controllable/aircraft will choose another direction.
-- @param DCS#Distance Altitude (optional) Desired altitude to perform the unit engagement.
-- @param #boolean Visible (optional) Unit must be visible.
-- @param #boolean ControllableAttack (optional) Flag indicates that the target must be engaged by all aircrafts of the controllable. Has effect only if the task is assigned to a controllable, not to a single aircraft.
-- @return DCS#Task The DCS task structure.
function CONTROLLABLE:EnRouteTaskEngageUnit( EngageUnit, Priority, GroupAttack, WeaponExpend, AttackQty, Direction, Altitude, Visible, ControllableAttack )

  local DCSTask = {
    id = 'EngageUnit',
    params = {
      unitId             = EngageUnit:GetID(),
      priority           = Priority or 1,
      groupAttack        = GroupAttack and GroupAttack or false,
      visible            = Visible and Visible or false,
      expend             = WeaponExpend or "Auto",
      directionEnabled   = Direction and true or false,
      direction          = Direction and math.rad(Direction) or nil,
      altitudeEnabled    = Altitude and true or false,
      altitude           = Altitude,
      attackQtyLimit     = AttackQty and true or false,
      attackQty          = AttackQty,
      controllableAttack = ControllableAttack,
    },
  }

  return DCSTask
end

--- (AIR) Aircraft will act as an AWACS for friendly units (will provide them with information about contacts). No parameters.
-- [hoggit](https://wiki.hoggitworld.com/view/DCS_task_awacs).
-- @param #CONTROLLABLE self
-- @return DCS#Task The DCS task structure.
function CONTROLLABLE:EnRouteTaskAWACS()

  local DCSTask = {
    id = 'AWACS',
    params = {},
  }

  return DCSTask
end

--- (AIR) Aircraft will act as a tanker for friendly units. No parameters.
-- See [hoggit](https://wiki.hoggitworld.com/view/DCS_task_tanker).
-- @param #CONTROLLABLE self
-- @return DCS#Task The DCS task structure.
function CONTROLLABLE:EnRouteTaskTanker()

  local DCSTask = {
    id = 'Tanker',
    params = {},
  }

  return DCSTask
end

-- En-route tasks for ground units/controllables

--- (GROUND) Ground unit (EW-radar) will act as an EWR for friendly units (will provide them with information about contacts). No parameters.
-- See [hoggit](https://wiki.hoggitworld.com/view/DCS_task_ewr).
-- @param #CONTROLLABLE self
-- @return DCS#Task The DCS task structure.
function CONTROLLABLE:EnRouteTaskEWR()

  local DCSTask = {
    id = 'EWR',
    params = {},
  }

  return DCSTask
end

-- En-route tasks for airborne and ground units/controllables

--- (AIR + GROUND) The task makes the controllable/unit a FAC and lets the FAC to choose the target (enemy ground controllable) as well as other assigned targets.
-- The killer is player-controlled allied CAS-aircraft that is in contact with the FAC.
-- If the task is assigned to the controllable lead unit will be a FAC.
-- See [hoggit](https://wiki.hoggitworld.com/view/DCS_task_fac_engageGroup).
-- @param #CONTROLLABLE self
-- @param #CONTROLLABLE AttackGroup Target CONTROLLABLE.
-- @param #number Priority (Optional) All en-route tasks have the priority parameter. This is a number (less value - higher priority) that determines actions related to what task will be performed first. Default is 0.
-- @param #number WeaponType (Optional) Bitmask of weapon types those allowed to use. Default is "Auto".
-- @param DCS#AI.Task.Designation Designation (Optional) Designation type.
-- @param #boolean Datalink (optional) Allows to use datalink to send the target information to attack aircraft. Enabled by default.
-- @param #number CallsignID CallsignID, e.g. `CALLSIGN.JTAC.Anvil` for ground or `CALLSIGN.Aircraft.Ford` for air.
-- @param #number CallsignNumber Callsign first number, e.g. 2 for `Ford-2`.
-- @return DCS#Task The DCS task structure.
function CONTROLLABLE:EnRouteTaskFAC_EngageGroup( AttackGroup, Priority, WeaponType, Designation, Datalink, Frequency, Modulation, CallsignID, CallsignNumber )

  local DCSTask = {
    id = 'FAC_EngageGroup',
    params = {
      groupId     = AttackGroup:GetID(),
      weaponType  = WeaponType or "Auto",
      designation = Designation,
      datalink    = Datalink and Datalink or false,
      frequency   = (Frequency or 133)*1000000,
      modulation  = Modulation or radio.modulation.AM,
      callname    = CallsignID,
      number      = CallsignNumber,
      priority    = Priority or 0,
    },
  }

  return DCSTask
end

--- (AIR + GROUND) The task makes the controllable/unit a FAC and lets the FAC to choose a targets (enemy ground controllable) around as well as other assigned targets.
-- Assigns the controlled group to act as a Forward Air Controller or JTAC. Any detected targets will be assigned as targets to the player via the JTAC radio menu.
-- Target designation is set to auto and is dependent on the circumstances.
-- See [hoggit](https://wiki.hoggitworld.com/view/DCS_task_fac).
-- @param #CONTROLLABLE self
-- @param #number Frequency Frequency in MHz. Default 133 MHz.
-- @param #number Modulation Radio modulation. Default `radio.modulation.AM`.
-- @param #number CallsignID CallsignID, e.g. `CALLSIGN.JTAC.Anvil` for ground or `CALLSIGN.Aircraft.Ford` for air.
-- @param #number CallsignNumber Callsign first number, e.g. 2 for `Ford-2`.
-- @param #number Priority All en-route tasks have the priority parameter. This is a number (less value - higher priority) that determines actions related to what task will be performed first.
-- @return DCS#Task The DCS task structure.
function CONTROLLABLE:EnRouteTaskFAC( Frequency, Modulation, CallsignID, CallsignNumber, Priority )

  local DCSTask = {
    id = 'FAC',
    params = {
      frequency  = (Frequency or 133)*1000000,
      modulation = Modulation or radio.modulation.AM,
      callname   = CallsignID,
      number     = CallsignNumber,
      priority   = Priority or 0
    }
  }

  return DCSTask
end

--- This creates a Task element, with an action to call a function as part of a Wrapped Task.
-- This Task can then be embedded at a Waypoint by calling the method @{#CONTROLLABLE.SetTaskWaypoint}.
-- @param #CONTROLLABLE self
-- @param #string FunctionString The function name embedded as a string that will be called.
-- @param ... The variable arguments passed to the function when called! These arguments can be of any type!
-- @return #CONTROLLABLE
-- @usage
--
--  local ZoneList = {
--    ZONE:New( "ZONE1" ),
--    ZONE:New( "ZONE2" ),
--    ZONE:New( "ZONE3" ),
--    ZONE:New( "ZONE4" ),
--    ZONE:New( "ZONE5" )
--  }
--
--  GroundGroup = GROUP:FindByName( "Vehicle" )
--
--  --- @param Wrapper.Group#GROUP GroundGroup
--  function RouteToZone( Vehicle, ZoneRoute )
--
--    local Route = {}
--
--    Vehicle:E( { ZoneRoute = ZoneRoute } )
--
--    Vehicle:MessageToAll( "Moving to zone " .. ZoneRoute:GetName(), 10 )
--
--    -- Get the current coordinate of the Vehicle
--    local FromCoord = Vehicle:GetCoordinate()
--
--    -- Select a random Zone and get the Coordinate of the new Zone.
--    local RandomZone = ZoneList[ math.random( 1, #ZoneList ) ] -- Core.Zone#ZONE
--    local ToCoord = RandomZone:GetCoordinate()
--
--    -- Create a "ground route point", which is a "point" structure that can be given as a parameter to a Task
--    Route[#Route+1] = FromCoord:WaypointGround( 72 )
--    Route[#Route+1] = ToCoord:WaypointGround( 60, "Vee" )
--
--    local TaskRouteToZone = Vehicle:TaskFunction( "RouteToZone", RandomZone )
--
--    Vehicle:SetTaskWaypoint( Route[#Route], TaskRouteToZone ) -- Set for the given Route at Waypoint 2 the TaskRouteToZone.
--
--    Vehicle:Route( Route, math.random( 10, 20 ) ) -- Move after a random seconds to the Route. See the Route method for details.
--
--  end
--
--    RouteToZone( GroundGroup, ZoneList[1] )
--
function CONTROLLABLE:TaskFunction( FunctionString, ... )

  -- Script
  local DCSScript = {}
  DCSScript[#DCSScript + 1] = "local MissionControllable = GROUP:Find( ... ) "
  if arg and arg.n > 0 then
    local ArgumentKey = '_' .. tostring( arg ):match( "table: (.*)" )
    self:SetState( self, ArgumentKey, arg )
    DCSScript[#DCSScript + 1] = "local Arguments = MissionControllable:GetState( MissionControllable, '" .. ArgumentKey .. "' ) "
    DCSScript[#DCSScript + 1] = FunctionString .. "( MissionControllable, unpack( Arguments ) )"
  else
    DCSScript[#DCSScript + 1] = FunctionString .. "( MissionControllable )"
  end

  -- DCS task.
  local DCSTask = self:TaskWrappedAction( self:CommandDoScript( table.concat( DCSScript ) ) )

  return DCSTask
end

--- (AIR + GROUND) Return a mission task from a mission template.
-- @param #CONTROLLABLE self
-- @param #table TaskMission A table containing the mission task.
-- @return DCS#Task
function CONTROLLABLE:TaskMission( TaskMission )

  local DCSTask = {
    id = 'Mission',
    params = {
      TaskMission,
    },
  }

  return DCSTask
end

do -- Patrol methods

  --- (GROUND) Patrol iteratively using the waypoints of the (parent) group.
  -- @param #CONTROLLABLE self
  -- @return #CONTROLLABLE
  function CONTROLLABLE:PatrolRoute()

    local PatrolGroup = self -- Wrapper.Group#GROUP

    if not self:IsInstanceOf( "GROUP" ) then
      PatrolGroup = self:GetGroup() -- Wrapper.Group#GROUP
    end

    self:F( { PatrolGroup = PatrolGroup:GetName() } )

    if PatrolGroup:IsGround() or PatrolGroup:IsShip() then

      local Waypoints = PatrolGroup:GetTemplateRoutePoints()

      -- Calculate the new Route.
      local FromCoord = PatrolGroup:GetCoordinate()

      -- test for submarine
      local depth = 0
      local IsSub = false
      if PatrolGroup:IsShip() then
        local navalvec3 = FromCoord:GetVec3()
        if navalvec3.y < 0 then
          depth = navalvec3.y
          IsSub = true
        end
      end


      local Waypoint = Waypoints[1]
      local Speed = Waypoint.speed or (20 / 3.6)
       local From = FromCoord:WaypointGround( Speed )

      if IsSub then
         From = FromCoord:WaypointNaval( Speed, Waypoint.alt )
      end

      table.insert( Waypoints, 1, From )

      local TaskRoute = PatrolGroup:TaskFunction( "CONTROLLABLE.PatrolRoute" )

      self:F( { Waypoints = Waypoints } )
      local Waypoint = Waypoints[#Waypoints]
      PatrolGroup:SetTaskWaypoint( Waypoint, TaskRoute ) -- Set for the given Route at Waypoint 2 the TaskRouteToZone.

      PatrolGroup:Route( Waypoints, 2 ) -- Move after a random seconds to the Route. See the Route method for details.
    end
  end

  --- (GROUND) Patrol randomly to the waypoints the for the (parent) group.
  -- A random waypoint will be picked and the group will move towards that point.
  -- @param #CONTROLLABLE self
  -- @param #number Speed Speed in km/h.
  -- @param #string Formation The formation the group uses.
  -- @param Core.Point#COORDINATE ToWaypoint The waypoint where the group should move to.
  -- @return #CONTROLLABLE
  function CONTROLLABLE:PatrolRouteRandom( Speed, Formation, ToWaypoint )

    local PatrolGroup = self -- Wrapper.Group#GROUP

    if not self:IsInstanceOf( "GROUP" ) then
      PatrolGroup = self:GetGroup() -- Wrapper.Group#GROUP
    end

    self:F( { PatrolGroup = PatrolGroup:GetName() } )

    if PatrolGroup:IsGround() or PatrolGroup:IsShip() then

      local Waypoints = PatrolGroup:GetTemplateRoutePoints()

      -- Calculate the new Route.
      local FromCoord = PatrolGroup:GetCoordinate()
      local FromWaypoint = 1
      if ToWaypoint then
        FromWaypoint = ToWaypoint
      end
      -- test for submarine
      local depth = 0
      local IsSub = false
      if PatrolGroup:IsShip() then
        local navalvec3 = FromCoord:GetVec3()
        if navalvec3.y < 0 then
          depth = navalvec3.y
          IsSub = true
        end
      end
      -- Loop until a waypoint has been found that is not the same as the current waypoint.
      -- Otherwise the object won't move, or drive in circles, and the algorithm would not do exactly
      -- what it is supposed to do, which is making groups drive around.
      local ToWaypoint
      repeat
        -- Select a random waypoint and check if it is not the same waypoint as where the object is about.
        ToWaypoint = math.random( 1, #Waypoints )
      until (ToWaypoint ~= FromWaypoint)
      self:F( { FromWaypoint = FromWaypoint, ToWaypoint = ToWaypoint } )

      local Waypoint = Waypoints[ToWaypoint] -- Select random waypoint.
      local ToCoord = COORDINATE:NewFromVec2( { x = Waypoint.x, y = Waypoint.y } )
      -- Create a "ground route point", which is a "point" structure that can be given as a parameter to a Task
      local Route = {}
      if IsSub then
        Route[#Route + 1] = FromCoord:WaypointNaval( Speed, depth )
        Route[#Route + 1] = ToCoord:WaypointNaval( Speed, Waypoint.alt )
      else
        Route[#Route + 1] = FromCoord:WaypointGround( Speed, Formation )
        Route[#Route + 1] = ToCoord:WaypointGround( Speed, Formation )
      end

      local TaskRouteToZone = PatrolGroup:TaskFunction( "CONTROLLABLE.PatrolRouteRandom", Speed, Formation, ToWaypoint )

      PatrolGroup:SetTaskWaypoint( Route[#Route], TaskRouteToZone ) -- Set for the given Route at Waypoint 2 the TaskRouteToZone.

      PatrolGroup:Route( Route, 1 ) -- Move after a random seconds to the Route. See the Route method for details.
    end
  end

  --- (GROUND) Patrol randomly to the waypoints the for the (parent) group.
  -- A random waypoint will be picked and the group will move towards that point.
  -- @param #CONTROLLABLE self
  -- @param #table ZoneList Table of zones.
  -- @param #number Speed Speed in km/h the group moves at.
  -- @param #string Formation (Optional) Formation the group should use.
  -- @param #number DelayMin Delay in seconds before the group progresses to the next route point. Default 1 sec.
  -- @param #number DelayMax Max. delay in seconds. Actual delay is randomly chosen between DelayMin and DelayMax. Default equal to DelayMin.
  -- @return #CONTROLLABLE
  function CONTROLLABLE:PatrolZones( ZoneList, Speed, Formation, DelayMin, DelayMax )

    if type( ZoneList ) ~= "table" then
      ZoneList = { ZoneList }
    end

    local PatrolGroup = self -- Wrapper.Group#GROUP

    if not self:IsInstanceOf( "GROUP" ) then
      PatrolGroup = self:GetGroup() -- Wrapper.Group#GROUP
    end

    DelayMin = DelayMin or 1
    if not DelayMax or DelayMax < DelayMin then
      DelayMax = DelayMin
    end

    local Delay = math.random( DelayMin, DelayMax )

    self:F( { PatrolGroup = PatrolGroup:GetName() } )

    if PatrolGroup:IsGround() or PatrolGroup:IsShip() then

      -- Calculate the new Route.
      local FromCoord = PatrolGroup:GetCoordinate()

      -- test for submarine
      local depth = 0
      local IsSub = false
      if PatrolGroup:IsShip() then
        local navalvec3 = FromCoord:GetVec3()
        if navalvec3.y < 0 then
          depth = navalvec3.y
          IsSub = true
        end
      end

      -- Select a random Zone and get the Coordinate of the new Zone.
      local RandomZone = ZoneList[math.random( 1, #ZoneList )] -- Core.Zone#ZONE
      local ToCoord = RandomZone:GetRandomCoordinate( 10 )

      -- Create a "ground route point", which is a "point" structure that can be given as a parameter to a Task
      local Route = {}
      if IsSub then
        Route[#Route + 1] = FromCoord:WaypointNaval( Speed, depth )
        Route[#Route + 1] = ToCoord:WaypointNaval( Speed, depth )
      else
        Route[#Route + 1] = FromCoord:WaypointGround( Speed, Formation )
        Route[#Route + 1] = ToCoord:WaypointGround( Speed, Formation )
      end

      local TaskRouteToZone = PatrolGroup:TaskFunction( "CONTROLLABLE.PatrolZones", ZoneList, Speed, Formation, DelayMin, DelayMax )

      PatrolGroup:SetTaskWaypoint( Route[#Route], TaskRouteToZone ) -- Set for the given Route at Waypoint 2 the TaskRouteToZone.

      PatrolGroup:Route( Route, Delay ) -- Move after a random seconds to the Route. See the Route method for details.
    end
  end

end


--- Return a "Misson" task to follow a given route defined by Points.
-- @param #CONTROLLABLE self
-- @param #table Points A table of route points.
-- @return DCS#Task DCS mission task. Has entries `.id="Mission"`, `params`, were params has entries `airborne` and `route`, which is a table of `points`.
function CONTROLLABLE:TaskRoute( Points )

  local DCSTask = {
    id = 'Mission',
    params = {
      airborne = self:IsAir(),  -- This is important to make aircraft land without respawning them (which was a long standing DCS issue).
      route = {points = Points},
    },
  }

  return DCSTask
end

do -- Route methods

  --- (AIR + GROUND) Make the Controllable move to fly to a given point.
  -- @param #CONTROLLABLE self
  -- @param DCS#Vec3 Point The destination point in Vec3 format.
  -- @param #number Speed The speed [m/s] to travel.
  -- @return #CONTROLLABLE self
  function CONTROLLABLE:RouteToVec2( Point, Speed )
    self:F2( { Point, Speed } )

    local ControllablePoint = self:GetUnit( 1 ):GetVec2()

    local PointFrom = {}
    PointFrom.x = ControllablePoint.x
    PointFrom.y = ControllablePoint.y
    PointFrom.type = "Turning Point"
    PointFrom.action = "Turning Point"
    PointFrom.speed = Speed
    PointFrom.speed_locked = true
    PointFrom.properties = {
      ["vnav"] = 1,
      ["scale"] = 0,
      ["angle"] = 0,
      ["vangle"] = 0,
      ["steer"] = 2,
    }

    local PointTo = {}
    PointTo.x = Point.x
    PointTo.y = Point.y
    PointTo.type = "Turning Point"
    PointTo.action = "Fly Over Point"
    PointTo.speed = Speed
    PointTo.speed_locked = true
    PointTo.properties = {
      ["vnav"] = 1,
      ["scale"] = 0,
      ["angle"] = 0,
      ["vangle"] = 0,
      ["steer"] = 2,
    }

    local Points = { PointFrom, PointTo }

    self:T3( Points )

    self:Route( Points )

    return self
  end

  --- (AIR + GROUND) Make the Controllable move to a given point.
  -- @param #CONTROLLABLE self
  -- @param DCS#Vec3 Point The destination point in Vec3 format.
  -- @param #number Speed The speed [m/s] to travel.
  -- @return #CONTROLLABLE self
  function CONTROLLABLE:RouteToVec3( Point, Speed )
    self:F2( { Point, Speed } )

    local ControllableVec3 = self:GetUnit( 1 ):GetVec3()

    local PointFrom = {}
    PointFrom.x = ControllableVec3.x
    PointFrom.y = ControllableVec3.z
    PointFrom.alt = ControllableVec3.y
    PointFrom.alt_type = "BARO"
    PointFrom.type = "Turning Point"
    PointFrom.action = "Turning Point"
    PointFrom.speed = Speed
    PointFrom.speed_locked = true
    PointFrom.properties = {
      ["vnav"] = 1,
      ["scale"] = 0,
      ["angle"] = 0,
      ["vangle"] = 0,
      ["steer"] = 2,
    }

    local PointTo = {}
    PointTo.x = Point.x
    PointTo.y = Point.z
    PointTo.alt = Point.y
    PointTo.alt_type = "BARO"
    PointTo.type = "Turning Point"
    PointTo.action = "Fly Over Point"
    PointTo.speed = Speed
    PointTo.speed_locked = true
    PointTo.properties = {
      ["vnav"] = 1,
      ["scale"] = 0,
      ["angle"] = 0,
      ["vangle"] = 0,
      ["steer"] = 2,
    }

    local Points = { PointFrom, PointTo }

    self:T3( Points )

    self:Route( Points )

    return self
  end

  --- Make the controllable to follow a given route.
  -- @param #CONTROLLABLE self
  -- @param #table Route A table of Route Points.
  -- @param #number DelaySeconds (Optional) Wait for the specified seconds before executing the Route. Default is one second.
  -- @return #CONTROLLABLE The CONTROLLABLE.
  function CONTROLLABLE:Route( Route, DelaySeconds )
    self:F2( Route )

    local DCSControllable = self:GetDCSObject()
    if DCSControllable then
      local RouteTask = self:TaskRoute( Route ) -- Create a RouteTask, that will route the CONTROLLABLE to the Route.
      self:SetTask( RouteTask, DelaySeconds or 1 ) -- Execute the RouteTask after the specified seconds (default is 1).
      return self
    end

    return nil
  end

  --- Make the controllable to push follow a given route.
  -- @param #CONTROLLABLE self
  -- @param #table Route A table of Route Points.
  -- @param #number DelaySeconds (Optional) Wait for the specified seconds before executing the Route. Default is one second.
  -- @return #CONTROLLABLE The CONTROLLABLE.
  function CONTROLLABLE:RoutePush( Route, DelaySeconds )
    self:F2( Route )

    local DCSControllable = self:GetDCSObject()
    if DCSControllable then
      local RouteTask = self:TaskRoute( Route ) -- Create a RouteTask, that will route the CONTROLLABLE to the Route.
      self:PushTask( RouteTask, DelaySeconds or 1 ) -- Execute the RouteTask after the specified seconds (default is 1).
      return self
    end

    return nil
  end

  --- Stops the movement of the vehicle on the route.
  -- @param #CONTROLLABLE self
  -- @return #CONTROLLABLE
  function CONTROLLABLE:RouteStop()
    self:F( self:GetName() .. " RouteStop" )

    local CommandStop = self:CommandStopRoute( true )
    self:SetCommand( CommandStop )

  end

  --- Resumes the movement of the vehicle on the route.
  -- @param #CONTROLLABLE self
  -- @return #CONTROLLABLE
  function CONTROLLABLE:RouteResume()
    self:F( self:GetName() .. " RouteResume" )

    local CommandResume = self:CommandStopRoute( false )
    self:SetCommand( CommandResume )

  end

  --- Make the GROUND Controllable to drive towards a specific point.
  -- @param #CONTROLLABLE self
  -- @param Core.Point#COORDINATE ToCoordinate A Coordinate to drive to.
  -- @param #number Speed (optional) Speed in km/h. The default speed is 20 km/h.
  -- @param #string Formation (optional) The route point Formation, which is a text string that specifies exactly the Text in the Type of the route point, like "Vee", "Echelon Right".
  -- @param #number DelaySeconds Wait for the specified seconds before executing the Route.
  -- @param #function WaypointFunction (Optional) Function called when passing a waypoint. First parameters of the function are the @{#CONTROLLABLE} object, the number of the waypoint and the total number of waypoints.
  -- @param #table WaypointFunctionArguments (Optional) List of parameters passed to the *WaypointFunction*.
  -- @return #CONTROLLABLE The CONTROLLABLE.
  function CONTROLLABLE:RouteGroundTo( ToCoordinate, Speed, Formation, DelaySeconds, WaypointFunction, WaypointFunctionArguments )

    local FromCoordinate = self:GetCoordinate()

    local FromWP = FromCoordinate:WaypointGround( Speed, Formation )
    local ToWP = ToCoordinate:WaypointGround( Speed, Formation )

    local route = { FromWP, ToWP }

    -- Add passing waypoint function.
    if WaypointFunction then
      local N = #route
      for n, waypoint in pairs( route ) do
        waypoint.task = {}
        waypoint.task.id = "ComboTask"
        waypoint.task.params = {}
        waypoint.task.params.tasks = { self:TaskFunction( "CONTROLLABLE.___PassingWaypoint", n, N, WaypointFunction, unpack( WaypointFunctionArguments or {} ) ) }
      end
    end

    self:Route( route, DelaySeconds )

    return self
  end

  --- Make the GROUND Controllable to drive towards a specific point using (mostly) roads.
  -- @param #CONTROLLABLE self
  -- @param Core.Point#COORDINATE ToCoordinate A Coordinate to drive to.
  -- @param #number Speed (Optional) Speed in km/h. The default speed is 20 km/h.
  -- @param #number DelaySeconds (Optional) Wait for the specified seconds before executing the Route. Default is one second.
  -- @param #string OffRoadFormation (Optional) The formation at initial and final waypoint. Default is "Off Road".
  -- @param #function WaypointFunction (Optional) Function called when passing a waypoint. First parameters of the function are the @{#CONTROLLABLE} object, the number of the waypoint and the total number of waypoints.
  -- @param #table WaypointFunctionArguments (Optional) List of parameters passed to the *WaypointFunction*.
  -- @return #CONTROLLABLE The CONTROLLABLE.
  function CONTROLLABLE:RouteGroundOnRoad( ToCoordinate, Speed, DelaySeconds, OffRoadFormation, WaypointFunction, WaypointFunctionArguments )

    -- Defaults.
    Speed = Speed or 20
    DelaySeconds = DelaySeconds or 1
    OffRoadFormation = OffRoadFormation or "Off Road"

    -- Get the route task.
    local route = self:TaskGroundOnRoad( ToCoordinate, Speed, OffRoadFormation, nil, nil, WaypointFunction, WaypointFunctionArguments )

    -- Route controllable to destination.
    self:Route( route, DelaySeconds )

    return self
  end

  --- Make the TRAIN Controllable to drive towards a specific point using railroads.
  -- @param #CONTROLLABLE self
  -- @param Core.Point#COORDINATE ToCoordinate A Coordinate to drive to.
  -- @param #number Speed (Optional) Speed in km/h. The default speed is 20 km/h.
  -- @param #number DelaySeconds (Optional) Wait for the specified seconds before executing the Route. Default is one second.
  -- @param #function WaypointFunction (Optional) Function called when passing a waypoint. First parameters of the function are the @{#CONTROLLABLE} object, the number of the waypoint and the total number of waypoints.
  -- @param #table WaypointFunctionArguments (Optional) List of parameters passed to the *WaypointFunction*.
  -- @return #CONTROLLABLE The CONTROLLABLE.
  function CONTROLLABLE:RouteGroundOnRailRoads( ToCoordinate, Speed, DelaySeconds, WaypointFunction, WaypointFunctionArguments )

    -- Defaults.
    Speed = Speed or 20
    DelaySeconds = DelaySeconds or 1

    -- Get the route task.
    local route = self:TaskGroundOnRailRoads( ToCoordinate, Speed, WaypointFunction, WaypointFunctionArguments )

    -- Route controllable to destination.
    self:Route( route, DelaySeconds )

    return self
  end

  --- Make a task for a GROUND Controllable to drive towards a specific point using (mostly) roads.
  -- @param #CONTROLLABLE self
  -- @param Core.Point#COORDINATE ToCoordinate A Coordinate to drive to.
  -- @param #number Speed (Optional) Speed in km/h. The default speed is 20 km/h.
  -- @param #string OffRoadFormation (Optional) The formation at initial and final waypoint. Default is "Off Road".
  -- @param #boolean Shortcut (Optional) If true, controllable will take the direct route if the path on road is 10x longer or path on road is less than 5% of total path.
  -- @param Core.Point#COORDINATE FromCoordinate (Optional) Explicit initial coordinate. Default is the position of the controllable.
  -- @param #function WaypointFunction (Optional) Function called when passing a waypoint. First parameters of the function are the @{#CONTROLLABLE} object, the number of the waypoint and the total number of waypoints.
  -- @param #table WaypointFunctionArguments (Optional) List of parameters passed to the *WaypointFunction*.
  -- @return DCS#Task Task.
  -- @return #boolean If true, path on road is possible. If false, task will route the group directly to its destination.
  function CONTROLLABLE:TaskGroundOnRoad( ToCoordinate, Speed, OffRoadFormation, Shortcut, FromCoordinate, WaypointFunction, WaypointFunctionArguments )
    self:T( { ToCoordinate = ToCoordinate, Speed = Speed, OffRoadFormation = OffRoadFormation, WaypointFunction = WaypointFunction, Args = WaypointFunctionArguments } )

    -- Defaults.
    Speed = Speed or 20
    OffRoadFormation = OffRoadFormation or "Off Road"

    -- Initial (current) coordinate.
    FromCoordinate = FromCoordinate or self:GetCoordinate()

    -- Get path and path length on road including the end points (From and To).
    local PathOnRoad, LengthOnRoad, GotPath = FromCoordinate:GetPathOnRoad( ToCoordinate, true )

    -- Get the length only(!) on the road.
    local _, LengthRoad = FromCoordinate:GetPathOnRoad( ToCoordinate, false )

    -- Off road part of the rout: Total=OffRoad+OnRoad.
    local LengthOffRoad
    local LongRoad

    -- Calculate the direct distance between the initial and final points.
    local LengthDirect = FromCoordinate:Get2DDistance( ToCoordinate )

    if GotPath and LengthRoad then

      -- Off road part of the rout: Total=OffRoad+OnRoad.
      LengthOffRoad = LengthOnRoad - LengthRoad

      -- Length on road is 10 times longer than direct route or path on road is very short (<5% of total path).
      LongRoad = LengthOnRoad and ((LengthOnRoad > LengthDirect * 10) or (LengthRoad / LengthOnRoad * 100 < 5))

      -- Debug info.
      self:T( string.format( "Length on road   = %.3f km", LengthOnRoad / 1000 ) )
      self:T( string.format( "Length directly  = %.3f km", LengthDirect / 1000 ) )
      self:T( string.format( "Length fraction  = %.3f km", LengthOnRoad / LengthDirect ) )
      self:T( string.format( "Length only road = %.3f km", LengthRoad / 1000 ) )
      self:T( string.format( "Length off road  = %.3f km", LengthOffRoad / 1000 ) )
      self:T( string.format( "Percent on road  = %.1f", LengthRoad / LengthOnRoad * 100 ) )

    end

    -- Route, ground waypoints along road.
    local route = {}
    local canroad = false

    -- Check if a valid path on road could be found.
    if GotPath and LengthRoad and LengthDirect > 2000 then -- if the length of the movement is less than 1 km, drive directly.
      -- Check whether the road is very long compared to direct path.
      if LongRoad and Shortcut then

        -- Road is long ==> we take the short cut.

        table.insert( route, FromCoordinate:WaypointGround( Speed, OffRoadFormation ) )
        table.insert( route, ToCoordinate:WaypointGround( Speed, OffRoadFormation ) )

      else

        -- Create waypoints.
        table.insert( route, FromCoordinate:WaypointGround( Speed, OffRoadFormation ) )
        table.insert( route, PathOnRoad[2]:WaypointGround( Speed, "On Road" ) )
        table.insert( route, PathOnRoad[#PathOnRoad - 1]:WaypointGround( Speed, "On Road" ) )

        -- Add the final coordinate because the final might not be on the road.
        local dist = ToCoordinate:Get2DDistance( PathOnRoad[#PathOnRoad - 1] )
        if dist > 10 then
          table.insert( route, ToCoordinate:WaypointGround( Speed, OffRoadFormation ) )
          table.insert( route, ToCoordinate:GetRandomCoordinateInRadius( 10, 5 ):WaypointGround( 5, OffRoadFormation ) )
          table.insert( route, ToCoordinate:GetRandomCoordinateInRadius( 10, 5 ):WaypointGround( 5, OffRoadFormation ) )
        end

      end

      canroad = true
    else

      -- No path on road could be found (can happen!) ==> Route group directly from A to B.
      table.insert( route, FromCoordinate:WaypointGround( Speed, OffRoadFormation ) )
      table.insert( route, ToCoordinate:WaypointGround( Speed, OffRoadFormation ) )

    end

    -- Add passing waypoint function.
    if WaypointFunction then
      local N = #route
      for n, waypoint in pairs( route ) do
        waypoint.task = {}
        waypoint.task.id = "ComboTask"
        waypoint.task.params = {}
        waypoint.task.params.tasks = { self:TaskFunction( "CONTROLLABLE.___PassingWaypoint", n, N, WaypointFunction, unpack( WaypointFunctionArguments or {} ) ) }
      end
    end

    return route, canroad
  end

  --- Make a task for a TRAIN Controllable to drive towards a specific point using railroad.
  -- @param #CONTROLLABLE self
  -- @param Core.Point#COORDINATE ToCoordinate A Coordinate to drive to.
  -- @param #number Speed (Optional) Speed in km/h. The default speed is 20 km/h.
  -- @param #function WaypointFunction (Optional) Function called when passing a waypoint. First parameters of the function are the @{#CONTROLLABLE} object, the number of the waypoint and the total number of waypoints.
  -- @param #table WaypointFunctionArguments (Optional) List of parameters passed to the *WaypointFunction*.
  -- @return Task
  function CONTROLLABLE:TaskGroundOnRailRoads( ToCoordinate, Speed, WaypointFunction, WaypointFunctionArguments )
    self:F2( { ToCoordinate = ToCoordinate, Speed = Speed } )

    -- Defaults.
    Speed = Speed or 20

    -- Current coordinate.
    local FromCoordinate = self:GetCoordinate()

    -- Get path and path length on railroad.
    local PathOnRail, LengthOnRail = FromCoordinate:GetPathOnRoad( ToCoordinate, false, true )

    -- Debug info.
    self:T( string.format( "Length on railroad = %.3f km", LengthOnRail / 1000 ) )

    -- Route, ground waypoints along road.
    local route = {}

    -- Check if a valid path on railroad could be found.
    if PathOnRail then

      table.insert( route, PathOnRail[1]:WaypointGround( Speed, "On Railroad" ) )
      table.insert( route, PathOnRail[2]:WaypointGround( Speed, "On Railroad" ) )

    end

    -- Add passing waypoint function.
    if WaypointFunction then
      local N = #route
      for n, waypoint in pairs( route ) do
        waypoint.task = {}
        waypoint.task.id = "ComboTask"
        waypoint.task.params = {}
        waypoint.task.params.tasks = { self:TaskFunction( "CONTROLLABLE.___PassingWaypoint", n, N, WaypointFunction, unpack( WaypointFunctionArguments or {} ) ) }
      end
    end

    return route
  end

  --- Task function when controllable passes a waypoint.
  -- @param #CONTROLLABLE controllable The controllable object.
  -- @param #number n Current waypoint number passed.
  -- @param #number N Total number of waypoints.
  -- @param #function waypointfunction Function called when a waypoint is passed.
  function CONTROLLABLE.___PassingWaypoint( controllable, n, N, waypointfunction, ... )
    waypointfunction( controllable, n, N, ... )
  end

  --- Make the AIR Controllable fly towards a specific point.
  -- @param #CONTROLLABLE self
  -- @param Core.Point#COORDINATE ToCoordinate A Coordinate to drive to.
  -- @param Core.Point#COORDINATE.RoutePointAltType AltType The altitude type.
  -- @param Core.Point#COORDINATE.RoutePointType Type The route point type.
  -- @param Core.Point#COORDINATE.RoutePointAction Action The route point action.
  -- @param #number Speed (optional) Speed in km/h. The default speed is 500 km/h.
  -- @param #number DelaySeconds Wait for the specified seconds before executing the Route.
  -- @return #CONTROLLABLE The CONTROLLABLE.
  function CONTROLLABLE:RouteAirTo( ToCoordinate, AltType, Type, Action, Speed, DelaySeconds )

    local FromCoordinate = self:GetCoordinate()
    local FromWP = FromCoordinate:WaypointAir()

    local ToWP = ToCoordinate:WaypointAir( AltType, Type, Action, Speed )

    self:Route( { FromWP, ToWP }, DelaySeconds )

    return self
  end

  --- (AIR + GROUND) Route the controllable to a given zone.
  -- The controllable final destination point can be randomized.
  -- A speed can be given in km/h.
  -- A given formation can be given.
  -- @param #CONTROLLABLE self
  -- @param Core.Zone#ZONE Zone The zone where to route to.
  -- @param #boolean Randomize Defines whether to target point gets randomized within the Zone.
  -- @param #number Speed The speed in m/s. Default is 5.555 m/s = 20 km/h.
  -- @param Core.Base#FORMATION Formation The formation string.
  function CONTROLLABLE:TaskRouteToZone( Zone, Randomize, Speed, Formation )
    self:F2( Zone )

    local DCSControllable = self:GetDCSObject()

    if DCSControllable then

      local ControllablePoint = self:GetVec2()

      local PointFrom = {}
      PointFrom.x = ControllablePoint.x
      PointFrom.y = ControllablePoint.y
      PointFrom.type = "Turning Point"
      PointFrom.action = Formation or "Cone"
      PointFrom.speed = 20 / 3.6

      local PointTo = {}
      local ZonePoint

      if Randomize then
        ZonePoint = Zone:GetRandomVec2()
      else
        ZonePoint = Zone:GetVec2()
      end

      PointTo.x = ZonePoint.x
      PointTo.y = ZonePoint.y
      PointTo.type = "Turning Point"

      if Formation then
        PointTo.action = Formation
      else
        PointTo.action = "Cone"
      end

      if Speed then
        PointTo.speed = Speed
      else
        PointTo.speed = 20 / 3.6
      end

      local Points = { PointFrom, PointTo }

      self:T3( Points )

      self:Route( Points )

      return self
    end

    return nil
  end

  --- (GROUND) Route the controllable to a given Vec2.
  -- A speed can be given in km/h.
  -- A given formation can be given.
  -- @param #CONTROLLABLE self
  -- @param DCS#Vec2 Vec2 The Vec2 where to route to.
  -- @param #number Speed The speed in m/s. Default is 5.555 m/s = 20 km/h.
  -- @param Core.Base#FORMATION Formation The formation string.
  function CONTROLLABLE:TaskRouteToVec2( Vec2, Speed, Formation )

    local DCSControllable = self:GetDCSObject()

    if DCSControllable then

      local ControllablePoint = self:GetVec2()

      local PointFrom = {}
      PointFrom.x = ControllablePoint.x
      PointFrom.y = ControllablePoint.y
      PointFrom.type = "Turning Point"
      PointFrom.action = Formation or "Cone"
      PointFrom.speed = 20 / 3.6

      local PointTo = {}

      PointTo.x = Vec2.x
      PointTo.y = Vec2.y
      PointTo.type = "Turning Point"

      if Formation then
        PointTo.action = Formation
      else
        PointTo.action = "Cone"
      end

      if Speed then
        PointTo.speed = Speed
      else
        PointTo.speed = 20 / 3.6
      end

      local Points = { PointFrom, PointTo }

      self:T3( Points )

      self:Route( Points )

      return self
    end

    return nil
  end

end -- Route methods

-- Commands

--- Do Script command
-- @param #CONTROLLABLE self
-- @param #string DoScript
-- @return DCS#DCSCommand
function CONTROLLABLE:CommandDoScript( DoScript )

  local DCSDoScript = {
    id = "Script",
    params = {
      command = DoScript,
    },
  }

  self:T3( DCSDoScript )
  return DCSDoScript
end

--- Return the mission template of the controllable.
-- @param #CONTROLLABLE self
-- @return #table The MissionTemplate
-- TODO: Rework the method how to retrieve a template ...
function CONTROLLABLE:GetTaskMission()
  self:F2( self.ControllableName )

  return UTILS.DeepCopy( _DATABASE.Templates.Controllables[self.ControllableName].Template )
end

--- Return the mission route of the controllable.
-- @param #CONTROLLABLE self
-- @return #table The mission route defined by points.
function CONTROLLABLE:GetTaskRoute()
  self:F2( self.ControllableName )

  return UTILS.DeepCopy( _DATABASE.Templates.Controllables[self.ControllableName].Template.route.points )
end

--- Return the route of a controllable by using the @{Core.Database#DATABASE} class.
-- @param #CONTROLLABLE self
-- @param #number Begin The route point from where the copy will start. The base route point is 0.
-- @param #number End The route point where the copy will end. The End point is the last point - the End point. The last point has base 0.
-- @param #boolean Randomize Randomization of the route, when true.
-- @param #number Radius When randomization is on, the randomization is within the radius.
function CONTROLLABLE:CopyRoute( Begin, End, Randomize, Radius )
  self:F2( { Begin, End } )

  local Points = {}

  -- Could be a Spawned Controllable
  local ControllableName = string.match( self:GetName(), ".*#" )
  if ControllableName then
    ControllableName = ControllableName:sub( 1, -2 )
  else
    ControllableName = self:GetName()
  end

  self:T3( { ControllableName } )

  local Template = _DATABASE.Templates.Controllables[ControllableName].Template

  if Template then
    if not Begin then
      Begin = 0
    end
    if not End then
      End = 0
    end

    for TPointID = Begin + 1, #Template.route.points - End do
      if Template.route.points[TPointID] then
        Points[#Points + 1] = UTILS.DeepCopy( Template.route.points[TPointID] )
        if Randomize then
          if not Radius then
            Radius = 500
          end
          Points[#Points].x = Points[#Points].x + math.random( Radius * -1, Radius )
          Points[#Points].y = Points[#Points].y + math.random( Radius * -1, Radius )
        end
      end
    end
    return Points
  else
    error( "Template not found for Controllable : " .. ControllableName )
  end

  return nil
end

--- Return the detected targets of the controllable.
-- The optional parameters specify the detection methods that can be applied.
-- If no detection method is given, the detection will use all the available methods by default.
-- @param #CONTROLLABLE self
-- @param #boolean DetectVisual (optional)
-- @param #boolean DetectOptical (optional)
-- @param #boolean DetectRadar (optional)
-- @param #boolean DetectIRST (optional)
-- @param #boolean DetectRWR (optional)
-- @param #boolean DetectDLINK (optional)
-- @return #table DetectedTargets
function CONTROLLABLE:GetDetectedTargets( DetectVisual, DetectOptical, DetectRadar, DetectIRST, DetectRWR, DetectDLINK )
  self:F2( self.ControllableName )

  local DCSControllable = self:GetDCSObject()

  if DCSControllable then

    local DetectionVisual = (DetectVisual and DetectVisual == true) and Controller.Detection.VISUAL or nil
    local DetectionOptical = (DetectOptical and DetectOptical == true) and Controller.Detection.OPTIC or nil
    local DetectionRadar = (DetectRadar and DetectRadar == true) and Controller.Detection.RADAR or nil
    local DetectionIRST = (DetectIRST and DetectIRST == true) and Controller.Detection.IRST or nil
    local DetectionRWR = (DetectRWR and DetectRWR == true) and Controller.Detection.RWR or nil
    local DetectionDLINK = (DetectDLINK and DetectDLINK == true) and Controller.Detection.DLINK or nil

    local Params = {}
    if DetectionVisual then
      Params[#Params + 1] = DetectionVisual
    end
    if DetectionOptical then
      Params[#Params + 1] = DetectionOptical
    end
    if DetectionRadar then
      Params[#Params + 1] = DetectionRadar
    end
    if DetectionIRST then
      Params[#Params + 1] = DetectionIRST
    end
    if DetectionRWR then
      Params[#Params + 1] = DetectionRWR
    end
    if DetectionDLINK then
      Params[#Params + 1] = DetectionDLINK
    end

    self:T2( { DetectionVisual, DetectionOptical, DetectionRadar, DetectionIRST, DetectionRWR, DetectionDLINK } )

    return self:_GetController():getDetectedTargets( Params[1], Params[2], Params[3], Params[4], Params[5], Params[6] )
  end

  return nil
end

--- Check if a DCS object (unit or static) is detected by the controllable. 
-- Note that after a target is detected it remains "detected" for a certain amount of time, even if the controllable cannot "see" the target any more with it's sensors.
-- The optional parametes specify the detection methods that can be applied.
-- 
-- If **no** detection method is given, the detection will use **all** the available methods by default.
-- If **at least one** detection method is specified, only the methods set to *true* will be used.
-- @param #CONTROLLABLE self
-- @param DCS#Object DCSObject The DCS object that is checked.
-- @param #boolean DetectVisual (Optional) If *false*, do not include visually detected targets.
-- @param #boolean DetectOptical (Optional) If *false*, do not include optically detected targets.
-- @param #boolean DetectRadar (Optional) If *false*, do not include targets detected by radar.
-- @param #boolean DetectIRST (Optional) If *false*, do not include targets detected by IRST.
-- @param #boolean DetectRWR (Optional) If *false*, do not include targets detected by RWR.
-- @param #boolean DetectDLINK (Optional) If *false*, do not include targets detected by data link.
-- @return #boolean `true` if target is detected.
-- @return #boolean `true` if target is *currently* visible by line of sight. Target must be detected (first parameter returns `true`).
-- @return #boolean `true` if target type is known. Target must be detected (first parameter returns `true`).
-- @return #boolean `true` if distance to target is known. Target must be detected (first parameter returns `true`).
-- @return #number Mission time in seconds when target was last detected. Only present if the target is currently not visible (second parameter returns `false`) otherwise `nil` is returned.
-- @return DCS#Vec3 Last known position vector of the target. Only present if the target is currently not visible (second parameter returns `false`) otherwise `nil` is returned.
-- @return DCS#Vec3 Last known velocity vector of the target. Only present if the target is currently not visible (second parameter returns `false`) otherwise `nil` is returned.
function CONTROLLABLE:IsTargetDetected( DCSObject, DetectVisual, DetectOptical, DetectRadar, DetectIRST, DetectRWR, DetectDLINK )
  self:F2( self.ControllableName )

  local DCSControllable = self:GetDCSObject()

  if DCSControllable then

    local DetectionVisual = (DetectVisual and DetectVisual == true) and Controller.Detection.VISUAL or nil
    local DetectionOptical = (DetectOptical and DetectOptical == true) and Controller.Detection.OPTIC or nil
    local DetectionRadar = (DetectRadar and DetectRadar == true) and Controller.Detection.RADAR or nil
    local DetectionIRST = (DetectIRST and DetectIRST == true) and Controller.Detection.IRST or nil
    local DetectionRWR = (DetectRWR and DetectRWR == true) and Controller.Detection.RWR or nil
    local DetectionDLINK = (DetectDLINK and DetectDLINK == true) and Controller.Detection.DLINK or nil

    local Controller = self:_GetController()

    local TargetIsDetected, TargetIsVisible, TargetKnowType, TargetKnowDistance, TargetLastTime, TargetLastPos, TargetLastVelocity
      = Controller:isTargetDetected( DCSObject, DetectionVisual, DetectionOptical, DetectionRadar, DetectionIRST, DetectionRWR, DetectionDLINK )

    return TargetIsDetected, TargetIsVisible, TargetKnowType, TargetKnowDistance, TargetLastTime, TargetLastPos, TargetLastVelocity
  end

  return nil
end

--- Check if a certain UNIT is detected by the controllable.
-- The optional parametes specify the detection methods that can be applied.
-- 
-- If **no** detection method is given, the detection will use **all** the available methods by default.
-- If **at least one** detection method is specified, only the methods set to *true* will be used.
-- @param #CONTROLLABLE self
-- @param Wrapper.Unit#UNIT Unit The unit that is supposed to be detected.
-- @param #boolean DetectVisual (Optional) If *false*, do not include visually detected targets.
-- @param #boolean DetectOptical (Optional) If *false*, do not include optically detected targets.
-- @param #boolean DetectRadar (Optional) If *false*, do not include targets detected by radar.
-- @param #boolean DetectIRST (Optional) If *false*, do not include targets detected by IRST.
-- @param #boolean DetectRWR (Optional) If *false*, do not include targets detected by RWR.
-- @param #boolean DetectDLINK (Optional) If *false*, do not include targets detected by data link.
-- @return #boolean `true` if target is detected.
-- @return #boolean `true` if target is *currently* visible by line of sight. Target must be detected (first parameter returns `true`).
-- @return #boolean `true` if target type is known. Target must be detected (first parameter returns `true`).
-- @return #boolean `true` if distance to target is known. Target must be detected (first parameter returns `true`).
-- @return #number Mission time in seconds when target was last detected. Only present if the target is currently not visible (second parameter returns `false`) otherwise `nil` is returned.
-- @return DCS#Vec3 Last known position vector of the target. Only present if the target is currently not visible (second parameter returns `false`) otherwise `nil` is returned.
-- @return DCS#Vec3 Last known velocity vector of the target. Only present if the target is currently not visible (second parameter returns `false`) otherwise `nil` is returned.
function CONTROLLABLE:IsUnitDetected( Unit, DetectVisual, DetectOptical, DetectRadar, DetectIRST, DetectRWR, DetectDLINK )
  self:F2( self.ControllableName )

  if Unit and Unit:IsAlive() then
    return self:IsTargetDetected( Unit:GetDCSObject(), DetectVisual, DetectOptical, DetectRadar, DetectIRST, DetectRWR, DetectDLINK )
  end

  return nil
end

--- Check if a certain GROUP is detected by the controllable.
-- The optional parametes specify the detection methods that can be applied.
-- If **no** detection method is given, the detection will use **all** the available methods by default.
-- If **at least one** detection method is specified, only the methods set to *true* will be used.
-- @param #CONTROLLABLE self
-- @param Wrapper.Group#GROUP Group The group that is supposed to be detected.
-- @param #boolean DetectVisual (Optional) If *false*, do not include visually detected targets.
-- @param #boolean DetectOptical (Optional) If *false*, do not include optically detected targets.
-- @param #boolean DetectRadar (Optional) If *false*, do not include targets detected by radar.
-- @param #boolean DetectIRST (Optional) If *false*, do not include targets detected by IRST.
-- @param #boolean DetectRWR (Optional) If *false*, do not include targets detected by RWR.
-- @param #boolean DetectDLINK (Optional) If *false*, do not include targets detected by data link.
-- @return #boolean True if any unit of the group is detected.
function CONTROLLABLE:IsGroupDetected( Group, DetectVisual, DetectOptical, DetectRadar, DetectIRST, DetectRWR, DetectDLINK )
  self:F2( self.ControllableName )

  if Group and Group:IsAlive() then
    for _, _unit in pairs( Group:GetUnits() ) do
      local unit = _unit -- Wrapper.Unit#UNIT
      if unit and unit:IsAlive() then

        local isdetected = self:IsUnitDetected( unit, DetectVisual, DetectOptical, DetectRadar, DetectIRST, DetectRWR, DetectDLINK )

        if isdetected then
          return true
        end
      end
    end
    return false
  end

  return nil
end

--- Return the detected targets of the controllable.
-- The optional parametes specify the detection methods that can be applied.
-- If **no** detection method is given, the detection will use **all** the available methods by default.
-- If **at least one** detection method is specified, only the methods set to *true* will be used.
-- @param #CONTROLLABLE self
-- @param #boolean DetectVisual (Optional) If *false*, do not include visually detected targets.
-- @param #boolean DetectOptical (Optional) If *false*, do not include optically detected targets.
-- @param #boolean DetectRadar (Optional) If *false*, do not include targets detected by radar.
-- @param #boolean DetectIRST (Optional) If *false*, do not include targets detected by IRST.
-- @param #boolean DetectRWR (Optional) If *false*, do not include targets detected by RWR.
-- @param #boolean DetectDLINK (Optional) If *false*, do not include targets detected by data link.
-- @return Core.Set#SET_UNIT Set of detected units.
function CONTROLLABLE:GetDetectedUnitSet( DetectVisual, DetectOptical, DetectRadar, DetectIRST, DetectRWR, DetectDLINK )

  -- Get detected DCS units.
  local detectedtargets = self:GetDetectedTargets( DetectVisual, DetectOptical, DetectRadar, DetectIRST, DetectRWR, DetectDLINK )

  local unitset = SET_UNIT:New()

  for DetectionObjectID, Detection in pairs( detectedtargets or {} ) do
    local DetectedObject = Detection.object -- DCS#Object

    if DetectedObject and DetectedObject:isExist() and DetectedObject.id_ < 50000000 then
      local unit = UNIT:Find( DetectedObject )

      if unit and unit:IsAlive() then

        if not unitset:FindUnit( unit:GetName() ) then
          unitset:AddUnit( unit )
        end

      end
    end
  end

  return unitset
end

--- Return the detected target groups of the controllable as a @{Core.Set#SET_GROUP}.
-- The optional parametes specify the detection methods that can be applied.
-- If no detection method is given, the detection will use all the available methods by default.
-- @param #CONTROLLABLE self
-- @param #boolean DetectVisual (Optional) If *false*, do not include visually detected targets.
-- @param #boolean DetectOptical (Optional) If *false*, do not include optically detected targets.
-- @param #boolean DetectRadar (Optional) If *false*, do not include targets detected by radar.
-- @param #boolean DetectIRST (Optional) If *false*, do not include targets detected by IRST.
-- @param #boolean DetectRWR (Optional) If *false*, do not include targets detected by RWR.
-- @param #boolean DetectDLINK (Optional) If *false*, do not include targets detected by data link.
-- @return Core.Set#SET_GROUP Set of detected groups.
function CONTROLLABLE:GetDetectedGroupSet( DetectVisual, DetectOptical, DetectRadar, DetectIRST, DetectRWR, DetectDLINK )

  -- Get detected DCS units.
  local detectedtargets = self:GetDetectedTargets( DetectVisual, DetectOptical, DetectRadar, DetectIRST, DetectRWR, DetectDLINK )

  local groupset = SET_GROUP:New()

  for DetectionObjectID, Detection in pairs( detectedtargets or {} ) do
    local DetectedObject = Detection.object -- DCS#Object

    if DetectedObject and DetectedObject:isExist() and DetectedObject.id_ < 50000000 then
      local unit = UNIT:Find( DetectedObject )

      if unit and unit:IsAlive() then
        local group = unit:GetGroup()

        if group and not groupset:FindGroup( group:GetName() ) then
          groupset:AddGroup( group )
        end

      end
    end
  end

  return groupset
end

-- Options

--- Set option.
-- @param #CONTROLLABLE self
-- @param #number OptionID ID/Type of the option.
-- @param #number OptionValue Value of the option
-- @return #CONTROLLABLE self
function CONTROLLABLE:SetOption( OptionID, OptionValue )

  local DCSControllable = self:GetDCSObject()
  if DCSControllable then
    local Controller = self:_GetController()

    Controller:setOption( OptionID, OptionValue )

    return self
  end

  return nil
end

--- Set option for Rules of Engagement (ROE).
-- @param #CONTROLLABLE self
-- @param #number ROEvalue ROE value. See ENUMS.ROE.
-- @return #CONTROLLABLE self
function CONTROLLABLE:OptionROE( ROEvalue )

  local DCSControllable = self:GetDCSObject()

  if DCSControllable then

    local Controller = self:_GetController()

    if self:IsAir() then
      Controller:setOption( AI.Option.Air.id.ROE, ROEvalue )
    elseif self:IsGround() then
      Controller:setOption( AI.Option.Ground.id.ROE, ROEvalue )
    elseif self:IsShip() then
      Controller:setOption( AI.Option.Naval.id.ROE, ROEvalue )
    end

    return self
  end

  return nil
end

--- Can the CONTROLLABLE hold their weapons?
-- @param #CONTROLLABLE self
-- @return #boolean
function CONTROLLABLE:OptionROEHoldFirePossible()
  self:F2( { self.ControllableName } )

  local DCSControllable = self:GetDCSObject()
  if DCSControllable then
    if self:IsAir() or self:IsGround() or self:IsShip() then
      return true
    end

    return false
  end

  return nil
end

--- Weapons Hold: AI will hold fire under all circumstances.
-- @param #CONTROLLABLE self
-- @return #CONTROLLABLE self
function CONTROLLABLE:OptionROEHoldFire()
  self:F2( { self.ControllableName } )

  local DCSControllable = self:GetDCSObject()
  if DCSControllable then
    local Controller = self:_GetController()

    if self:IsAir() then
      Controller:setOption( AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.WEAPON_HOLD )
    elseif self:IsGround() then
      Controller:setOption( AI.Option.Ground.id.ROE, AI.Option.Ground.val.ROE.WEAPON_HOLD )
    elseif self:IsShip() then
      Controller:setOption( AI.Option.Naval.id.ROE, AI.Option.Naval.val.ROE.WEAPON_HOLD )
    end

    return self
  end

  return nil
end

--- Can the CONTROLLABLE attack returning on enemy fire?
-- @param #CONTROLLABLE self
-- @return #boolean
function CONTROLLABLE:OptionROEReturnFirePossible()
  self:F2( { self.ControllableName } )

  local DCSControllable = self:GetDCSObject()
  if DCSControllable then
    if self:IsAir() or self:IsGround() or self:IsShip() then
      return true
    end

    return false
  end

  return nil
end

--- Return Fire: AI will only engage threats that shoot first.
-- @param #CONTROLLABLE self
-- @return #CONTROLLABLE self
function CONTROLLABLE:OptionROEReturnFire()
  self:F2( { self.ControllableName } )

  local DCSControllable = self:GetDCSObject()
  if DCSControllable then
    local Controller = self:_GetController()

    if self:IsAir() then
      Controller:setOption( AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.RETURN_FIRE )
    elseif self:IsGround() then
      Controller:setOption( AI.Option.Ground.id.ROE, AI.Option.Ground.val.ROE.RETURN_FIRE )
    elseif self:IsShip() then
      Controller:setOption( AI.Option.Naval.id.ROE, AI.Option.Naval.val.ROE.RETURN_FIRE )
    end

    return self
  end

  return nil
end

--- Can the CONTROLLABLE attack designated targets?
-- @param #CONTROLLABLE self
-- @return #boolean
function CONTROLLABLE:OptionROEOpenFirePossible()
  self:F2( { self.ControllableName } )

  local DCSControllable = self:GetDCSObject()
  if DCSControllable then
    if self:IsAir() or self:IsGround() or self:IsShip() then
      return true
    end

    return false
  end

  return nil
end

--- Open Fire (Only Designated): AI will engage only targets specified in its taskings.
-- @param #CONTROLLABLE self
-- @return #CONTROLLABLE self
function CONTROLLABLE:OptionROEOpenFire()
  self:F2( { self.ControllableName } )

  local DCSControllable = self:GetDCSObject()
  if DCSControllable then
    local Controller = self:_GetController()

    if self:IsAir() then
      Controller:setOption( AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.OPEN_FIRE )
    elseif self:IsGround() then
      Controller:setOption( AI.Option.Ground.id.ROE, AI.Option.Ground.val.ROE.OPEN_FIRE )
    elseif self:IsShip() then
      Controller:setOption( AI.Option.Naval.id.ROE, AI.Option.Naval.val.ROE.OPEN_FIRE )
    end

    return self
  end

  return nil
end

--- Can the CONTROLLABLE attack priority designated targets? Only for AIR!
-- @param #CONTROLLABLE self
-- @return #boolean
function CONTROLLABLE:OptionROEOpenFireWeaponFreePossible()
  self:F2( { self.ControllableName } )

  local DCSControllable = self:GetDCSObject()
  if DCSControllable then
    if self:IsAir() then
      return true
    end

    return false
  end

  return nil
end

--- Open Fire, Weapons Free (Priority Designated): AI will engage any enemy group it detects, but will prioritize targets specified in the groups tasking.
-- **Only for AIR units!**
-- @param #CONTROLLABLE self
-- @return #CONTROLLABLE self
function CONTROLLABLE:OptionROEOpenFireWeaponFree()
  self:F2( { self.ControllableName } )

  local DCSControllable = self:GetDCSObject()
  if DCSControllable then
    local Controller = self:_GetController()

    if self:IsAir() then
      Controller:setOption( AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.OPEN_FIRE_WEAPON_FREE )
    end

    return self
  end

  return nil
end

--- Can the CONTROLLABLE attack targets of opportunity?
-- @param #CONTROLLABLE self
-- @return #boolean
function CONTROLLABLE:OptionROEWeaponFreePossible()
  self:F2( { self.ControllableName } )

  local DCSControllable = self:GetDCSObject()
  if DCSControllable then
    if self:IsAir() then
      return true
    end

    return false
  end

  return nil
end

--- Weapon free.
-- @param #CONTROLLABLE self
-- @return #CONTROLLABLE self
function CONTROLLABLE:OptionROEWeaponFree()
  self:F2( { self.ControllableName } )

  local DCSControllable = self:GetDCSObject()
  if DCSControllable then
    local Controller = self:_GetController()

    if self:IsAir() then
      Controller:setOption( AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.WEAPON_FREE )
    end

    return self
  end

  return nil
end

--- Can the CONTROLLABLE ignore enemy fire?
-- @param #CONTROLLABLE self
-- @return #boolean
function CONTROLLABLE:OptionROTNoReactionPossible()
  self:F2( { self.ControllableName } )

  local DCSControllable = self:GetDCSObject()
  if DCSControllable then
    if self:IsAir() then
      return true
    end

    return false
  end

  return nil
end

--- No evasion on enemy threats.
-- @param #CONTROLLABLE self
-- @return #CONTROLLABLE self
function CONTROLLABLE:OptionROTNoReaction()
  self:F2( { self.ControllableName } )

  local DCSControllable = self:GetDCSObject()
  if DCSControllable then
    local Controller = self:_GetController()

    if self:IsAir() then
      Controller:setOption( AI.Option.Air.id.REACTION_ON_THREAT, AI.Option.Air.val.REACTION_ON_THREAT.NO_REACTION )
    end

    return self
  end

  return nil
end

--- Set Reation On Threat behaviour.
-- @param #CONTROLLABLE self
-- @param #number ROTvalue ROT value. See ENUMS.ROT.
-- @return #CONTROLLABLE self
function CONTROLLABLE:OptionROT( ROTvalue )
  self:F2( { self.ControllableName } )

  local DCSControllable = self:GetDCSObject()
  if DCSControllable then
    local Controller = self:_GetController()

    if self:IsAir() then
      Controller:setOption( AI.Option.Air.id.REACTION_ON_THREAT, ROTvalue )
    end

    return self
  end

  return nil
end

--- Can the CONTROLLABLE evade using passive defenses?
-- @param #CONTROLLABLE self
-- @return #boolean
function CONTROLLABLE:OptionROTPassiveDefensePossible()
  self:F2( { self.ControllableName } )

  local DCSControllable = self:GetDCSObject()
  if DCSControllable then
    if self:IsAir() then
      return true
    end

    return false
  end

  return nil
end

--- Evasion passive defense.
-- @param #CONTROLLABLE self
-- @return #CONTROLLABLE self
function CONTROLLABLE:OptionROTPassiveDefense()
  self:F2( { self.ControllableName } )

  local DCSControllable = self:GetDCSObject()
  if DCSControllable then
    local Controller = self:_GetController()

    if self:IsAir() then
      Controller:setOption( AI.Option.Air.id.REACTION_ON_THREAT, AI.Option.Air.val.REACTION_ON_THREAT.PASSIVE_DEFENCE )
    end

    return self
  end

  return nil
end

--- Can the CONTROLLABLE evade on enemy fire?
-- @param #CONTROLLABLE self
-- @return #boolean
function CONTROLLABLE:OptionROTEvadeFirePossible()
  self:F2( { self.ControllableName } )

  local DCSControllable = self:GetDCSObject()
  if DCSControllable then
    if self:IsAir() then
      return true
    end

    return false
  end

  return nil
end

--- Evade on fire.
-- @param #CONTROLLABLE self
-- @return #CONTROLLABLE self
function CONTROLLABLE:OptionROTEvadeFire()
  self:F2( { self.ControllableName } )

  local DCSControllable = self:GetDCSObject()
  if DCSControllable then
    local Controller = self:_GetController()

    if self:IsAir() then
      Controller:setOption( AI.Option.Air.id.REACTION_ON_THREAT, AI.Option.Air.val.REACTION_ON_THREAT.EVADE_FIRE )
    end

    return self
  end

  return nil
end

--- Can the CONTROLLABLE evade on fire using vertical manoeuvres?
-- @param #CONTROLLABLE self
-- @return #boolean
function CONTROLLABLE:OptionROTVerticalPossible()
  self:F2( { self.ControllableName } )

  local DCSControllable = self:GetDCSObject()
  if DCSControllable then
    if self:IsAir() then
      return true
    end

    return false
  end

  return nil
end

--- Evade on fire using vertical manoeuvres.
-- @param #CONTROLLABLE self
-- @return #CONTROLLABLE self
function CONTROLLABLE:OptionROTVertical()
  self:F2( { self.ControllableName } )

  local DCSControllable = self:GetDCSObject()
  if DCSControllable then
    local Controller = self:_GetController()

    if self:IsAir() then
      Controller:setOption( AI.Option.Air.id.REACTION_ON_THREAT, AI.Option.Air.val.REACTION_ON_THREAT.BYPASS_AND_ESCAPE )
    end

    return self
  end

  return nil
end

--- Alarm state to Auto: AI will automatically switch alarm states based on the presence of threats. The AI kind of cheats in this regard.
-- @param #CONTROLLABLE self
-- @return #CONTROLLABLE self
function CONTROLLABLE:OptionAlarmStateAuto()
  self:F2( { self.ControllableName } )

  local DCSControllable = self:GetDCSObject()
  if DCSControllable then
    local Controller = self:_GetController()

    if self:IsGround() then
      Controller:setOption( AI.Option.Ground.id.ALARM_STATE, AI.Option.Ground.val.ALARM_STATE.AUTO )
    elseif self:IsShip() then
      -- Controller:setOption(AI.Option.Naval.id.ALARM_STATE, AI.Option.Naval.val.ALARM_STATE.AUTO)
      Controller:setOption( 9, 0 )
    end

    return self
  end

  return nil
end

--- Alarm state to Green: Group is not combat ready. Sensors are stowed if possible.
-- @param #CONTROLLABLE self
-- @return #CONTROLLABLE self
function CONTROLLABLE:OptionAlarmStateGreen()
  self:F2( { self.ControllableName } )

  local DCSControllable = self:GetDCSObject()
  if DCSControllable then
    local Controller = self:_GetController()

    if self:IsGround() then
      Controller:setOption( AI.Option.Ground.id.ALARM_STATE, AI.Option.Ground.val.ALARM_STATE.GREEN )
    elseif self:IsShip() then
      -- AI.Option.Naval.id.ALARM_STATE does not seem to exist!
      -- Controller:setOption( AI.Option.Naval.id.ALARM_STATE, AI.Option.Naval.val.ALARM_STATE.GREEN )
      Controller:setOption( 9, 1 )
    end

    return self
  end

  return nil
end

--- Alarm state to Red: Group is combat ready and actively searching for targets.
-- @param #CONTROLLABLE self
-- @return #CONTROLLABLE self
function CONTROLLABLE:OptionAlarmStateRed()
  self:F2( { self.ControllableName } )

  local DCSControllable = self:GetDCSObject()
  if DCSControllable then
    local Controller = self:_GetController()

    if self:IsGround() then
      Controller:setOption( AI.Option.Ground.id.ALARM_STATE, AI.Option.Ground.val.ALARM_STATE.RED )
    elseif self:IsShip() then
      -- Controller:setOption(AI.Option.Naval.id.ALARM_STATE, AI.Option.Naval.val.ALARM_STATE.RED)
      Controller:setOption( 9, 2 )
    end

    return self
  end

  return nil
end

--- Set RTB on bingo fuel.
-- @param #CONTROLLABLE self
-- @param #boolean RTB true if RTB on bingo fuel (default), false if no RTB on bingo fuel.
-- Warning! When you switch this option off, the airborne group will continue to fly until all fuel has been consumed, and will crash.
-- @return #CONTROLLABLE self
function CONTROLLABLE:OptionRTBBingoFuel( RTB ) -- R2.2
  self:F2( { self.ControllableName } )

  -- RTB = RTB or true
  if RTB == nil then
    RTB = true
  end

  local DCSControllable = self:GetDCSObject()
  if DCSControllable then
    local Controller = self:_GetController()

    if self:IsAir() then
      Controller:setOption( AI.Option.Air.id.RTB_ON_BINGO, RTB )
    end

    return self
  end

  return nil
end

--- Set RTB on ammo.
-- @param #CONTROLLABLE self
-- @param #boolean WeaponsFlag Weapons.flag enumerator.
-- @return #CONTROLLABLE self
function CONTROLLABLE:OptionRTBAmmo( WeaponsFlag )
  self:F2( { self.ControllableName } )

  local DCSControllable = self:GetDCSObject()
  if DCSControllable then
    local Controller = self:_GetController()

    if self:IsAir() then
      Controller:setOption( AI.Option.Air.id.RTB_ON_OUT_OF_AMMO, WeaponsFlag )
    end

    return self
  end

  return nil
end

--- Allow to Jettison of weapons upon threat.
-- @param #CONTROLLABLE self
-- @return #CONTROLLABLE self
function CONTROLLABLE:OptionAllowJettisonWeaponsOnThreat()
  self:F2( { self.ControllableName } )

  local DCSControllable = self:GetDCSObject()
  if DCSControllable then
    local Controller = self:_GetController()

    if self:IsAir() then
      Controller:setOption( AI.Option.Air.id.PROHIBIT_JETT, false )
    end

    return self
  end

  return nil
end

--- Keep weapons upon threat.
-- @param #CONTROLLABLE self
-- @return #CONTROLLABLE self
function CONTROLLABLE:OptionKeepWeaponsOnThreat()
  self:F2( { self.ControllableName } )

  local DCSControllable = self:GetDCSObject()
  if DCSControllable then
    local Controller = self:_GetController()

    if self:IsAir() then
      Controller:setOption( AI.Option.Air.id.PROHIBIT_JETT, true )
    end

    return self
  end

  return nil
end

--- Prohibit Afterburner.
-- @param #CONTROLLABLE self
-- @param #boolean Prohibit If true or nil, prohibit. If false, do not prohibit.
-- @return #CONTROLLABLE self
function CONTROLLABLE:OptionProhibitAfterburner( Prohibit )
  self:F2( { self.ControllableName } )

  if Prohibit == nil then
    Prohibit = true
  end

  if self:IsAir() then
    self:SetOption( AI.Option.Air.id.PROHIBIT_AB, Prohibit )
  end

  return self
end

--- [Ground] Allows AI radar units to take defensive actions to avoid anti radiation missiles. Units are allowed to shut radar off and displace. 
-- @param #CONTROLLABLE self
-- @param #number Seconds Can be - nil, 0 or false = switch off this option, any positive number = number of seconds the escape sequency runs.
-- @return #CONTROLLABLE self
function CONTROLLABLE:OptionEvasionOfARM(Seconds)
  self:F2( { self.ControllableName } )

  local DCSControllable = self:GetDCSObject()
  if DCSControllable then
    local Controller = self:_GetController()

    if self:IsGround() then
      if Seconds == nil then Seconds = false end
      Controller:setOption( AI.Option.Ground.id.EVASION_OF_ARM, Seconds)
    end

  end

  return self
end

--- [Ground] Option that defines the vehicle spacing when in an on road and off road formation. 
-- @param #CONTROLLABLE self
-- @param #number meters Can be zero to 100 meters. Defaults to 50 meters.
-- @return #CONTROLLABLE self
function CONTROLLABLE:OptionFormationInterval(meters)
  self:F2( { self.ControllableName } )

  local DCSControllable = self:GetDCSObject()
  if DCSControllable then
    local Controller = self:_GetController()

    if self:IsGround() then
      if meters == nil or meters > 100 or meters < 0 then meters = 50 end
      Controller:setOption( 30, meters)
    end

  end

  return self
end

--- [Air] Defines the usage of Electronic Counter Measures by airborne forces.
-- @param #CONTROLLABLE self
-- @param #number ECMvalue Can be - 0=Never on, 1=if locked by radar, 2=if detected by radar, 3=always on, defaults to 1
-- @return #CONTROLLABLE self
function CONTROLLABLE:OptionECM( ECMvalue )
  self:F2( { self.ControllableName } )

  local DCSControllable = self:GetDCSObject()
  if DCSControllable then
    local Controller = self:_GetController()

    if self:IsAir() then
      Controller:setOption( AI.Option.Air.id.ECM_USING, ECMvalue or 1 )
    end

  end

  return self
end

--- [Air] Defines the usage of Electronic Counter Measures by airborne forces. Disables the ability for AI to use their ECM.
-- @param #CONTROLLABLE self
-- @return #CONTROLLABLE self
function CONTROLLABLE:OptionECM_Never()
  self:F2( { self.ControllableName } )

  self:OptionECM(0)

  return self
end

--- [Air] Defines the usage of Electronic Counter Measures by airborne forces. If the AI is actively being locked by an enemy radar they will enable their ECM jammer.
-- @param #CONTROLLABLE self
-- @return #CONTROLLABLE self
function CONTROLLABLE:OptionECM_OnlyLockByRadar()
  self:F2( { self.ControllableName } )

  self:OptionECM(1)

  return self
end

--- [Air] Defines the usage of Electronic Counter Measures by airborne forces. If the AI is being detected by a radar they will enable their ECM.
-- @param #CONTROLLABLE self
-- @return #CONTROLLABLE self
function CONTROLLABLE:OptionECM_DetectedLockByRadar()
  self:F2( { self.ControllableName } )

  self:OptionECM(2)

  return self
end

--- [Air] Defines the usage of Electronic Counter Measures by airborne forces. AI will leave their ECM on all the time.
-- @param #CONTROLLABLE self
-- @return #CONTROLLABLE self
function CONTROLLABLE:OptionECM_AlwaysOn()
  self:F2( { self.ControllableName } )

  self:OptionECM(3)

  return self
end

--- Retrieve the controllable mission and allow to place function hooks within the mission waypoint plan.
-- Use the method @{#CONTROLLABLE.WayPointFunction}() to define the hook functions for specific waypoints.
-- Use the method @{#CONTROLLABLE.WayPointExecute}() to start the execution of the new mission plan.
-- Note that when WayPointInitialize is called, the Mission of the controllable is RESTARTED!
-- @param #CONTROLLABLE self
-- @param #table WayPoints If WayPoints is given, then use the route.
-- @return #CONTROLLABLE self
-- @usage Intended Workflow is:
-- mygroup:WayPointInitialize()
-- mygroup:WayPointFunction( WayPoint, WayPointIndex, WayPointFunction, ... )
-- mygroup:WayPointExecute()
function CONTROLLABLE:WayPointInitialize( WayPoints )
  self:F( { WayPoints } )

  if WayPoints then
    self.WayPoints = WayPoints
  else
    self.WayPoints = self:GetTaskRoute()
  end

  return self
end

--- Get the current WayPoints set with the WayPoint functions( Note that the WayPoints can be nil, although there ARE waypoints).
-- @param #CONTROLLABLE self
-- @return #table WayPoints If WayPoints is given, then return the WayPoints structure.
function CONTROLLABLE:GetWayPoints()
  self:F()

  if self.WayPoints then
    return self.WayPoints
  end

  return nil
end

--- Registers a waypoint function that will be executed when the controllable moves over the WayPoint.
-- @param #CONTROLLABLE self
-- @param #number WayPoint The waypoint number. Note that the start waypoint on the route is WayPoint 1!
-- @param #number WayPointIndex When defining multiple WayPoint functions for one WayPoint, use WayPointIndex to set the sequence of actions.
-- @param #function WayPointFunction The waypoint function to be called when the controllable moves over the waypoint. The waypoint function takes variable parameters.
-- @return #CONTROLLABLE self
-- @usage Intended Workflow is:
-- mygroup:WayPointInitialize()
-- mygroup:WayPointFunction( WayPoint, WayPointIndex, WayPointFunction, ... )
-- mygroup:WayPointExecute()
function CONTROLLABLE:WayPointFunction( WayPoint, WayPointIndex, WayPointFunction, ... )
  self:F2( { WayPoint, WayPointIndex, WayPointFunction } )
  if not self.WayPoints then
    self:WayPointInitialize()
  end
  table.insert( self.WayPoints[WayPoint].task.params.tasks, WayPointIndex )
  self.WayPoints[WayPoint].task.params.tasks[WayPointIndex] = self:TaskFunction( WayPointFunction, arg )
  return self
end

--- Executes the WayPoint plan.
-- The function gets a WayPoint parameter, that you can use to restart the mission at a specific WayPoint.
-- Note that when the WayPoint parameter is used, the new start mission waypoint of the controllable will be 1!
-- @param #CONTROLLABLE self
-- @param #number WayPoint The WayPoint from where to execute the mission.
-- @param #number WaitTime The amount seconds to wait before initiating the mission.
-- @return #CONTROLLABLE self
-- @usage Intended Workflow is:
-- mygroup:WayPointInitialize()
-- mygroup:WayPointFunction( WayPoint, WayPointIndex, WayPointFunction, ... )
-- mygroup:WayPointExecute()
function CONTROLLABLE:WayPointExecute( WayPoint, WaitTime )
  self:F( { WayPoint, WaitTime } )

  if not WayPoint then
    WayPoint = 1
  end

  -- When starting the mission from a certain point, the TaskPoints need to be deleted before the given WayPoint.
  for TaskPointID = 1, WayPoint - 1 do
    table.remove( self.WayPoints, 1 )
  end

  self:T3( self.WayPoints )

  self:SetTask( self:TaskRoute( self.WayPoints ), WaitTime )

  return self
end

--- Returns if the Controllable contains AirPlanes.
-- @param #CONTROLLABLE self
-- @return #boolean true if Controllable contains AirPlanes.
function CONTROLLABLE:IsAirPlane()
  self:F2()

  local DCSObject = self:GetDCSObject()

  if DCSObject then
    local Category = DCSObject:getDesc().category
    return Category == Unit.Category.AIRPLANE
  end

  return nil
end

--- Returns if the Controllable contains Helicopters.
-- @param #CONTROLLABLE self
-- @return #boolean true if Controllable contains Helicopters.
function CONTROLLABLE:IsHelicopter()
  self:F2()

  local DCSObject = self:GetDCSObject()

  if DCSObject then
    local Category = DCSObject:getDesc().category
    return Category == Unit.Category.HELICOPTER
  end

  return nil
end

--- Sets Controllable Option for Restriction of Afterburner.
-- @param #CONTROLLABLE self
-- @param #boolean RestrictBurner If true, restrict burner. If false or nil, allow (unrestrict) burner.
function CONTROLLABLE:OptionRestrictBurner( RestrictBurner )
  self:F2( { self.ControllableName } )

  local DCSControllable = self:GetDCSObject()

  if DCSControllable then
    local Controller = self:_GetController()

    if Controller then

      -- Issue https://github.com/FlightControl-Master/MOOSE/issues/1216
      if RestrictBurner == true then
        if self:IsAir() then
          Controller:setOption( 16, true )
        end
      else
        if self:IsAir() then
          Controller:setOption( 16, false )
        end
      end

    end
  end

end

--- Sets Controllable Option for A2A attack range for AIR FIGHTER units.
-- @param #CONTROLLABLE self
-- @param #number range Defines the range
-- @return #CONTROLLABLE self
-- @usage Range can be one of MAX_RANGE = 0, NEZ_RANGE = 1, HALF_WAY_RMAX_NEZ = 2, TARGET_THREAT_EST = 3, RANDOM_RANGE = 4. Defaults to 3. See: https://wiki.hoggitworld.com/view/DCS_option_missileAttack
function CONTROLLABLE:OptionAAAttackRange( range )
  self:F2( { self.ControllableName } )
  -- defaults to 3
  local range = range or 3
  if range < 0 or range > 4 then
    range = 3
  end
  local DCSControllable = self:GetDCSObject()
  if DCSControllable then
    local Controller = self:_GetController()
    if Controller then
      if self:IsAir() then
        self:SetOption( AI.Option.Air.id.MISSILE_ATTACK, range )
      end
    end
    return self
  end
  return nil
end

--- Defines the range at which a GROUND unit/group is allowed to use its weapons automatically.
-- @param #CONTROLLABLE self
-- @param #number EngageRange Engage range limit in percent (a number between 0 and 100). Default 100.
-- @return #CONTROLLABLE self
function CONTROLLABLE:OptionEngageRange( EngageRange )
  self:F2( { self.ControllableName } )
  -- Set default if not specified.
  EngageRange = EngageRange or 100
  if EngageRange < 0 or EngageRange > 100 then
    EngageRange = 100
  end
  local DCSControllable = self:GetDCSObject()
  if DCSControllable then
    local Controller = self:_GetController()
    if Controller then
      if self:IsGround() then
        self:SetOption( AI.Option.Ground.id.AC_ENGAGEMENT_RANGE_RESTRICTION, EngageRange )
      end
    end
    return self
  end
  return nil
end

--- [AIR] Set how the AI uses the onboard radar.
-- @param #CONTROLLABLE self
-- @param #number Option Options are: `NEVER = 0, FOR_ATTACK_ONLY = 1,FOR_SEARCH_IF_REQUIRED = 2, FOR_CONTINUOUS_SEARCH = 3`
-- @return #CONTROLLABLE self
function CONTROLLABLE:SetOptionRadarUsing(Option)
 self:F2( { self.ControllableName } )
  if self:IsAir() then
    self:SetOption(AI.Option.Air.id.RADAR_USING,Option)
  end
  return self
end

--- [AIR] Set how the AI uses the onboard radar. Here: never.
-- @param #CONTROLLABLE self
-- @return #CONTROLLABLE self
function CONTROLLABLE:SetOptionRadarUsingNever()
 self:F2( { self.ControllableName } )
  if self:IsAir() then
    self:SetOption(AI.Option.Air.id.RADAR_USING,0)
  end
  return self
end

--- [AIR] Set how the AI uses the onboard radar, here: for attack only.
-- @param #CONTROLLABLE self
-- @return #CONTROLLABLE self
function CONTROLLABLE:SetOptionRadarUsingForAttackOnly()
 self:F2( { self.ControllableName } )
  if self:IsAir() then
    self:SetOption(AI.Option.Air.id.RADAR_USING,1)
  end
  return self
end

--- [AIR] Set how the AI uses the onboard radar, here: when required for searching.
-- @param #CONTROLLABLE self
-- @return #CONTROLLABLE self
function CONTROLLABLE:SetOptionRadarUsingForSearchIfRequired()
 self:F2( { self.ControllableName } )
  if self:IsAir() then
    self:SetOption(AI.Option.Air.id.RADAR_USING,2)
  end
  return self
end

--- [AIR] Set how the AI uses the onboard radar, here: always on.
-- @param #CONTROLLABLE self
-- @return #CONTROLLABLE self
function CONTROLLABLE:SetOptionRadarUsingForContinousSearch()
 self:F2( { self.ControllableName } )
  if self:IsAir() then
    self:SetOption(AI.Option.Air.id.RADAR_USING,3)
  end
  return self
end

--- [AIR] Set if the AI is reporting passing of waypoints
-- @param #CONTROLLABLE self
-- @param #boolean OnOff If true or nil, AI will report passing waypoints, if false, it will not.
-- @return #CONTROLLABLE self
function CONTROLLABLE:SetOptionWaypointPassReport(OnOff)
 self:F2( { self.ControllableName } )
 local onoff = (OnOff == nil or OnOff == true) and false or true
  if self:IsAir() then
    self:SetOption(AI.Option.Air.id.PROHIBIT_WP_PASS_REPORT,onoff)
  end
  return self
end

--- [AIR] Set the AI to not report anything over the radio - radio silence
-- @param #CONTROLLABLE self
-- @param #boolean OnOff If true or nil, radio is set to silence, if false radio silence is lifted.
-- @return #CONTROLLABLE self
function CONTROLLABLE:SetOptionRadioSilence(OnOff)
 local onoff = (OnOff == true or OnOff == nil) and true or false
 self:F2( { self.ControllableName } )
  if self:IsAir() then
    self:SetOption(AI.Option.Air.id.SILENCE,onoff)
  end
  return self
end

--- [AIR] Set the AI to report contact for certain types of objects.
-- @param #CONTROLLABLE self
-- @param #table Objects Table of attribute names for which AI reports contact. Defaults to {"Air"}. See [Hoggit Wiki](https://wiki.hoggitworld.com/view/DCS_enum_attributes)
-- @return #CONTROLLABLE self
function CONTROLLABLE:SetOptionRadioContact(Objects)
 self:F2( { self.ControllableName } )
 if not Objects then Objects = {"Air"} end
 if type(Objects) ~= "table" then Objects = {Objects} end
  if self:IsAir() then
    self:SetOption(AI.Option.Air.id.OPTION_RADIO_USAGE_CONTACT,Objects)
  end
  return self
end

--- [AIR] Set the AI to report engaging certain types of objects.
-- @param #CONTROLLABLE self
-- @param #table Objects Table of attribute names for which AI reports contact. Defaults to {"Air"}, see [Hoggit Wiki](https://wiki.hoggitworld.com/view/DCS_enum_attributes)
-- @return #CONTROLLABLE self
function CONTROLLABLE:SetOptionRadioEngage(Objects)
 self:F2( { self.ControllableName } )
 if not Objects then Objects = {"Air"} end
 if type(Objects) ~= "table" then Objects = {Objects} end
  if self:IsAir() then
    self:SetOption(AI.Option.Air.id.OPTION_RADIO_USAGE_ENGAGE,Objects)
  end
  return self
end

--- [AIR] Set the AI to report killing certain types of objects.
-- @param #CONTROLLABLE self
-- @param #table Objects Table of attribute names for which AI reports contact. Defaults to {"Air"}, see [Hoggit Wiki](https://wiki.hoggitworld.com/view/DCS_enum_attributes)
-- @return #CONTROLLABLE self
function CONTROLLABLE:SetOptionRadioKill(Objects)
 self:F2( { self.ControllableName } )
 if not Objects then Objects = {"Air"} end
 if type(Objects) ~= "table" then Objects = {Objects} end
  if self:IsAir() then
    self:SetOption(AI.Option.Air.id.OPTION_RADIO_USAGE_KILL,Objects)
  end
  return self
end

--- (GROUND) Relocate controllable to a random point within a given radius; use e.g.for evasive actions; Note that not all ground controllables can actually drive, also the alarm state of the controllable might stop it from moving.
-- @param #CONTROLLABLE self
-- @param #number speed Speed of the controllable, default 20
-- @param #number radius Radius of the relocation zone, default 500
-- @param #boolean onroad If true, route on road (less problems with AI way finding), default true
-- @param #boolean shortcut If true and onroad is set, take a shorter route - if available - off road, default false
-- @param #string formation Formation string as in the mission editor, e.g. "Vee", "Diamond", "Line abreast", etc. Defaults to "Off Road"
-- @param #boolean onland (optional) If true, try up to 50 times to get a coordinate on land.SurfaceType.LAND. Note - this descriptor value is not reliably implemented on all maps.
-- @return #CONTROLLABLE self
function CONTROLLABLE:RelocateGroundRandomInRadius( speed, radius, onroad, shortcut, formation, onland )
  self:F2( { self.ControllableName } )

  local _coord = self:GetCoordinate()
  local _radius = radius or 500
  local _speed = speed or 20
  local _tocoord = _coord:GetRandomCoordinateInRadius( _radius, 100 )
  if onland then
    for i=1,50 do
      local island = _tocoord:GetSurfaceType() == land.SurfaceType.LAND and true or false
      if island then break end
      _tocoord = _coord:GetRandomCoordinateInRadius( _radius, 100 )
    end
  end
  local _onroad = onroad or true
  local _grptsk = {}
  local _candoroad = false
  local _shortcut = shortcut or false
  local _formation = formation or "Off Road"

  -- create a DCS Task an push it on the group
  if onroad then
    _grptsk, _candoroad = self:TaskGroundOnRoad( _tocoord, _speed, _formation, _shortcut )
    self:Route( _grptsk, 5 )
  else
    self:TaskRouteToVec2( _tocoord:GetVec2(), _speed, _formation )
  end

  return self
end

--- Defines how long a GROUND unit/group will move to avoid an ongoing attack.
-- @param #CONTROLLABLE self
-- @param #number Seconds Any positive number: AI will disperse, but only for the specified time before continuing their route. 0: AI will not disperse.
-- @return #CONTROLLABLE self
function CONTROLLABLE:OptionDisperseOnAttack( Seconds )
  self:F2( { self.ControllableName } )
  -- Set default if not specified.
  local seconds = Seconds or 0
  local DCSControllable = self:GetDCSObject()
  if DCSControllable then
    local Controller = self:_GetController()
    if Controller then
      if self:IsGround() then
        self:SetOption( AI.Option.Ground.id.DISPERSE_ON_ATTACK, seconds )
      end
    end
    return self
  end
  return nil
end

--- Returns if the unit is a submarine.
-- @param #POSITIONABLE self
-- @return #boolean Submarines attributes result.
function CONTROLLABLE:IsSubmarine()
  self:F2()

  local DCSUnit = self:GetDCSObject()

  if DCSUnit then
    local UnitDescriptor = DCSUnit:getDesc()
    if UnitDescriptor.attributes["Submarines"] == true then
      return true
    else
      return false
    end
  end

  return nil
end


--- Sets the controlled group to go at the specified speed in meters per second.
-- @param #CONTROLLABLE self
-- @param #number Speed Speed in meters per second
-- @param #boolean Keep (Optional) When set to true, will maintain the speed on passing waypoints. If not present or false, the controlled group will return to the speed as defined by their route.
-- @return #CONTROLLABLE self
function CONTROLLABLE:SetSpeed(Speed, Keep)
  self:F2( { self.ControllableName } )
  -- Set default if not specified.
  local speed = Speed or 5
  local DCSControllable = self:GetDCSObject()
  if DCSControllable then
    local Controller = self:_GetController()
    if Controller then
      Controller:setSpeed(speed, Keep)
    end
  end
  return self
end

--- [AIR] Sets the controlled aircraft group to fly at the specified altitude in meters.
-- @param #CONTROLLABLE self
-- @param #number Altitude Altitude in meters.
-- @param #boolean Keep (Optional) When set to true, will maintain the altitude on passing waypoints. If not present or false, the controlled group will return to the altitude as defined by their route.
-- @param #string AltType (Optional) Specifies the altitude type used. If nil, the altitude type of the current waypoint will be used. Accepted values are "BARO" and "RADIO".
-- @return #CONTROLLABLE self
function CONTROLLABLE:SetAltitude(Altitude, Keep, AltType)
  self:F2( { self.ControllableName } )
  -- Set default if not specified.
  local altitude = Altitude or 1000
  local DCSControllable = self:GetDCSObject()
  if DCSControllable then
    local Controller = self:_GetController()
    if Controller then
      if self:IsAir() then
        Controller:setAltitude(altitude, Keep, AltType)
      end
    end
  end
  return self
end

--- Return an empty task shell for Aerobatics.
-- @param #CONTROLLABLE self
-- @return DCS#Task
-- @usage
--        local plane = GROUP:FindByName("Aerial-1")
--        -- get a task shell
--        local aerotask = plane:TaskAerobatics()
--        -- add a series of maneuvers
--        aerotask = plane:TaskAerobaticsHorizontalEight(aerotask,1,5000,850,true,false,1,70)
--        aerotask = plane:TaskAerobaticsWingoverFlight(aerotask,1,0,0,true,true,20)
--        aerotask = plane:TaskAerobaticsLoop(aerotask,1,0,0,false,true)
--        -- set the task
--        plane:SetTask(aerotask)
function CONTROLLABLE:TaskAerobatics()

  local DCSTaskAerobatics = {
    id = "Aerobatics",
    params = {
      ["maneuversSequency"] = {},
    },
    ["enabled"] = true,
    ["auto"] = false,
  }

  return DCSTaskAerobatics
end

--- Add an aerobatics entry of type "CANDLE" to the Aerobatics Task.
-- @param #CONTROLLABLE self
-- @param DCS#Task TaskAerobatics The Aerobatics Task
-- @param #number Repeats (Optional) The number of repeats, defaults to 1.
-- @param #number InitAltitude (Optional) Starting altitude in meters, defaults to 0.
-- @param #number InitSpeed (Optional) Starting speed in KPH, defaults to 0.
-- @param #boolean UseSmoke (Optional)  Using smoke, defaults to false.
-- @param #boolean StartImmediately (Optional) If true, start immediately and ignore  InitAltitude and InitSpeed.
-- @return DCS#Task
function CONTROLLABLE:TaskAerobaticsCandle(TaskAerobatics,Repeats,InitAltitude,InitSpeed,UseSmoke,StartImmediately)

  local maxrepeats = 10

  if Repeats > maxrepeats then maxrepeats = Repeats end

  local usesmoke = UseSmoke and 1 or 0

  local startimmediately = StartImmediately and 1 or 0

  local CandleTask = {
    ["name"] = "CANDLE",
    ["params"] = {
      ["RepeatQty"] = {
        ["max_v"] = maxrepeats,
        ["min_v"] = 1,
        ["order"] = 1,
        ["value"] = Repeats or 1,
      },
      ["InitAltitude"] = {
        ["order"] = 2,
        ["value"] = InitAltitude or 0,
      },
      ["InitSpeed"] = {
        ["order"] = 3,
        ["value"] = InitSpeed or 0,
      },
      ["UseSmoke"] = {
        ["order"] = 4,
        ["value"] = usesmoke,
      },
      ["StartImmediatly"] = {
        ["order"] = 5,
        ["value"] = startimmediately,
      }
    }
  }

  table.insert(TaskAerobatics.params["maneuversSequency"],CandleTask)

  return TaskAerobatics
end

--- Add an aerobatics entry of type "EDGE_FLIGHT" to the Aerobatics Task.
-- @param #CONTROLLABLE self
-- @param DCS#Task TaskAerobatics The Aerobatics Task
-- @param #number Repeats (Optional) The number of repeats, defaults to 1.
-- @param #number InitAltitude (Optional) Starting altitude in meters, defaults to 0.
-- @param #number InitSpeed (Optional) Starting speed in KPH, defaults to 0.
-- @param #boolean UseSmoke (Optional)  Using smoke, defaults to false.
-- @param #boolean StartImmediately (Optional) If true, start immediately and ignore  InitAltitude and InitSpeed.
-- @param #number FlightTime (Optional) Time to fly this manoever in seconds, defaults to 10.
-- @param #number Side (Optional) On which side to fly,  0 == left, 1 == right side, defaults to 0.
-- @return DCS#Task
function CONTROLLABLE:TaskAerobaticsEdgeFlight(TaskAerobatics,Repeats,InitAltitude,InitSpeed,UseSmoke,StartImmediately,FlightTime,Side)

  local maxrepeats = 10
  local maxflight = 200

  if Repeats > maxrepeats then maxrepeats = Repeats end

  local usesmoke = UseSmoke and 1 or 0

  local startimmediately = StartImmediately and 1 or 0

  local flighttime = FlightTime or 10

  if flighttime > 200 then maxflight = flighttime end

  local EdgeTask = {
    ["name"] = "EDGE_FLIGHT",
    ["params"] = {
      ["RepeatQty"] = {
        ["max_v"] = maxrepeats,
        ["min_v"] = 1,
        ["order"] = 1,
        ["value"] = Repeats or 1,
      },
      ["InitAltitude"] = {
        ["order"] = 2,
        ["value"] = InitAltitude or 0,
      },
      ["InitSpeed"] = {
        ["order"] = 3,
        ["value"] = InitSpeed or 0,
      },
      ["UseSmoke"] = {
        ["order"] = 4,
        ["value"] = usesmoke,
      },
      ["StartImmediatly"] = {
        ["order"] = 5,
        ["value"] = startimmediately,
      },
      ["FlightTime"] = {
        ["max_v"] = maxflight,
        ["min_v"] = 1,
        ["order"] = 6,
        ["step"] = 0.1,
        ["value"] = flighttime or 10, -- Secs?
      },
      ["SIDE"] = {
        ["order"] = 7,
        ["value"] = Side or 0, --0 == left, 1 == right side
      },
    }
  }

  table.insert(TaskAerobatics.params["maneuversSequency"],EdgeTask)

  return TaskAerobatics
end

--- Add an aerobatics entry of type "WINGOVER_FLIGHT" to the Aerobatics Task.
-- @param #CONTROLLABLE self
-- @param DCS#Task TaskAerobatics The Aerobatics Task
-- @param #number Repeats (Optional) The number of repeats, defaults to 1.
-- @param #number InitAltitude (Optional) Starting altitude in meters, defaults to 0.
-- @param #number InitSpeed (Optional) Starting speed in KPH, defaults to 0.
-- @param #boolean UseSmoke (Optional)  Using smoke, defaults to false.
-- @param #boolean StartImmediately (Optional) If true, start immediately and ignore  InitAltitude and InitSpeed.
-- @param #number FlightTime (Optional) Time to fly this manoever in seconds, defaults to 10.
-- @return DCS#Task
function CONTROLLABLE:TaskAerobaticsWingoverFlight(TaskAerobatics,Repeats,InitAltitude,InitSpeed,UseSmoke,StartImmediately,FlightTime)

  local maxrepeats = 10
  local maxflight = 200

  if Repeats > maxrepeats then maxrepeats = Repeats end

  local usesmoke = UseSmoke and 1 or 0

  local startimmediately = StartImmediately and 1 or 0

  local flighttime = FlightTime or 10

  if flighttime > 200 then maxflight = flighttime end

  local WingoverTask = {
    ["name"] = "WINGOVER_FLIGHT",
    ["params"] = {
      ["RepeatQty"] = {
        ["max_v"] = maxrepeats,
        ["min_v"] = 1,
        ["order"] = 1,
        ["value"] = Repeats or 1,
      },
      ["InitAltitude"] = {
        ["order"] = 2,
        ["value"] = InitAltitude or 0,
      },
      ["InitSpeed"] = {
        ["order"] = 3,
        ["value"] = InitSpeed or 0,
      },
      ["UseSmoke"] = {
        ["order"] = 4,
        ["value"] = usesmoke,
      },
      ["StartImmediatly"] = {
        ["order"] = 5,
        ["value"] = startimmediately,
      },
      ["FlightTime"] = {
        ["max_v"] = maxflight,
        ["min_v"] = 1,
        ["order"] = 6,
        ["step"] = 0.1,
        ["value"] = flighttime or 10, -- Secs?
      },
    }
  }

  table.insert(TaskAerobatics.params["maneuversSequency"],WingoverTask)

  return TaskAerobatics
end

--- Add an aerobatics entry of type "LOOP" to the Aerobatics Task.
-- @param #CONTROLLABLE self
-- @param DCS#Task TaskAerobatics The Aerobatics Task
-- @param #number Repeats (Optional) The number of repeats, defaults to 1.
-- @param #number InitAltitude (Optional) Starting altitude in meters, defaults to 0.
-- @param #number InitSpeed (Optional) Starting speed in KPH, defaults to 0.
-- @param #boolean UseSmoke (Optional)  Using smoke, defaults to false.
-- @param #boolean StartImmediately (Optional) If true, start immediately and ignore  InitAltitude and InitSpeed.
-- @return DCS#Task
function CONTROLLABLE:TaskAerobaticsLoop(TaskAerobatics,Repeats,InitAltitude,InitSpeed,UseSmoke,StartImmediately)

  local maxrepeats = 10

  if Repeats > maxrepeats then maxrepeats = Repeats end

  local usesmoke = UseSmoke and 1 or 0

  local startimmediately = StartImmediately and 1 or 0

  local LoopTask = {
    ["name"] = "LOOP",
    ["params"] = {
      ["RepeatQty"] = {
        ["max_v"] = maxrepeats,
        ["min_v"] = 1,
        ["order"] = 1,
        ["value"] = Repeats or 1,
      },
      ["InitAltitude"] = {
        ["order"] = 2,
        ["value"] = InitAltitude or 0,
      },
      ["InitSpeed"] = {
        ["order"] = 3,
        ["value"] = InitSpeed or 0,
      },
      ["UseSmoke"] = {
        ["order"] = 4,
        ["value"] = usesmoke,
      },
      ["StartImmediatly"] = {
        ["order"] = 5,
        ["value"] = startimmediately,
      }
    }
  }

  table.insert(TaskAerobatics.params["maneuversSequency"],LoopTask)

  return TaskAerobatics
end

--- Add an aerobatics entry of type "HORIZONTAL_EIGHT" to the Aerobatics Task.
-- @param #CONTROLLABLE self
-- @param DCS#Task TaskAerobatics The Aerobatics Task
-- @param #number Repeats (Optional) The number of repeats, defaults to 1.
-- @param #number InitAltitude (Optional) Starting altitude in meters, defaults to 0.
-- @param #number InitSpeed (Optional) Starting speed in KPH, defaults to 0.
-- @param #boolean UseSmoke (Optional)  Using smoke, defaults to false.
-- @param #boolean StartImmediately (Optional) If true, start immediately and ignore  InitAltitude and InitSpeed.
-- @param #number Side (Optional) On which side to fly,  0 == left, 1 == right side, defaults to 0.
-- @param #number RollDeg (Optional) Roll degrees for Roll 1 and 2, defaults to 60.
-- @return DCS#Task
function CONTROLLABLE:TaskAerobaticsHorizontalEight(TaskAerobatics,Repeats,InitAltitude,InitSpeed,UseSmoke,StartImmediately,Side,RollDeg)

  local maxrepeats = 10

  if Repeats > maxrepeats then maxrepeats = Repeats end

  local usesmoke = UseSmoke and 1 or 0

  local startimmediately = StartImmediately and 1 or 0

  local LoopTask = {
    ["name"] = "HORIZONTAL_EIGHT",
    ["params"] = {
      ["RepeatQty"] = {
        ["max_v"] = maxrepeats,
        ["min_v"] = 1,
        ["order"] = 1,
        ["value"] = Repeats or 1,
      },
      ["InitAltitude"] = {
        ["order"] = 2,
        ["value"] = InitAltitude or 0,
      },
      ["InitSpeed"] = {
        ["order"] = 3,
        ["value"] = InitSpeed or 0,
      },
      ["UseSmoke"] = {
        ["order"] = 4,
        ["value"] = usesmoke,
      },
      ["StartImmediatly"] = {
        ["order"] = 5,
        ["value"] = startimmediately,
      },
      ["SIDE"] = {
        ["order"] = 6,
        ["value"] = Side or 0,
      },
      ["ROLL1"] = {
        ["order"] = 7,
        ["value"] = RollDeg or 60,
      },
      ["ROLL2"] = {
        ["order"] = 8,
        ["value"] = RollDeg or 60,
      },

    }
  }

  table.insert(TaskAerobatics.params["maneuversSequency"],LoopTask)

  return TaskAerobatics
end

--- Add an aerobatics entry of type "HAMMERHEAD" to the Aerobatics Task.
-- @param #CONTROLLABLE self
-- @param DCS#Task TaskAerobatics The Aerobatics Task
-- @param #number Repeats (Optional) The number of repeats, defaults to 1.
-- @param #number InitAltitude (Optional) Starting altitude in meters, defaults to 0.
-- @param #number InitSpeed (Optional) Starting speed in KPH, defaults to 0.
-- @param #boolean UseSmoke (Optional)  Using smoke, defaults to false.
-- @param #boolean StartImmediately (Optional) If true, start immediately and ignore  InitAltitude and InitSpeed.
-- @param #number Side (Optional) On which side to fly,  0 == left, 1 == right side, defaults to 0.
-- @return DCS#Task
function CONTROLLABLE:TaskAerobaticsHammerhead(TaskAerobatics,Repeats,InitAltitude,InitSpeed,UseSmoke,StartImmediately,Side)

  local maxrepeats = 10

  if Repeats > maxrepeats then maxrepeats = Repeats end

  local usesmoke = UseSmoke and 1 or 0

  local startimmediately = StartImmediately and 1 or 0

  local Task = {
    ["name"] = "HUMMERHEAD",
    ["params"] = {
      ["RepeatQty"] = {
        ["max_v"] = maxrepeats,
        ["min_v"] = 1,
        ["order"] = 1,
        ["value"] = Repeats or 1,
      },
      ["InitAltitude"] = {
        ["order"] = 2,
        ["value"] = InitAltitude or 0,
      },
      ["InitSpeed"] = {
        ["order"] = 3,
        ["value"] = InitSpeed or 0,
      },
      ["UseSmoke"] = {
        ["order"] = 4,
        ["value"] = usesmoke,
      },
      ["StartImmediatly"] = {
        ["order"] = 5,
        ["value"] = startimmediately,
      },
      ["SIDE"] = {
        ["order"] = 6,
        ["value"] = Side or 0,
      },
    }
  }

  table.insert(TaskAerobatics.params["maneuversSequency"],Task)

  return TaskAerobatics
end

--- Add an aerobatics entry of type "SKEWED_LOOP" to the Aerobatics Task.
-- @param #CONTROLLABLE self
-- @param DCS#Task TaskAerobatics The Aerobatics Task
-- @param #number Repeats (Optional) The number of repeats, defaults to 1.
-- @param #number InitAltitude (Optional) Starting altitude in meters, defaults to 0.
-- @param #number InitSpeed (Optional) Starting speed in KPH, defaults to 0.
-- @param #boolean UseSmoke (Optional)  Using smoke, defaults to false.
-- @param #boolean StartImmediately (Optional) If true, start immediately and ignore  InitAltitude and InitSpeed.
-- @param #number Side (Optional) On which side to fly,  0 == left, 1 == right side, defaults to 0.
-- @param #number RollDeg (Optional) Roll degrees for Roll 1 and 2, defaults to 60.
-- @return DCS#Task
function CONTROLLABLE:TaskAerobaticsSkewedLoop(TaskAerobatics,Repeats,InitAltitude,InitSpeed,UseSmoke,StartImmediately,Side,RollDeg)

  local maxrepeats = 10

  if Repeats > maxrepeats then maxrepeats = Repeats end

  local usesmoke = UseSmoke and 1 or 0

  local startimmediately = StartImmediately and 1 or 0

  local Task = {
    ["name"] = "SKEWED_LOOP",
    ["params"] = {
      ["RepeatQty"] = {
        ["max_v"] = maxrepeats,
        ["min_v"] = 1,
        ["order"] = 1,
        ["value"] = Repeats or 1,
      },
      ["InitAltitude"] = {
        ["order"] = 2,
        ["value"] = InitAltitude or 0,
      },
      ["InitSpeed"] = {
        ["order"] = 3,
        ["value"] = InitSpeed or 0,
      },
      ["UseSmoke"] = {
        ["order"] = 4,
        ["value"] = usesmoke,
      },
      ["StartImmediatly"] = {
        ["order"] = 5,
        ["value"] = startimmediately,
      },
      ["ROLL"] = {
        ["order"] = 6,
        ["value"] = RollDeg or 60,
      },
      ["SIDE"] = {
        ["order"] = 7,
        ["value"] = Side or 0,
      },
    }
  }

  table.insert(TaskAerobatics.params["maneuversSequency"],Task)

  return TaskAerobatics
end

--- Add an aerobatics entry of type "TURN" to the Aerobatics Task.
-- @param #CONTROLLABLE self
-- @param DCS#Task TaskAerobatics The Aerobatics Task
-- @param #number Repeats (Optional) The number of repeats, defaults to 1.
-- @param #number InitAltitude (Optional) Starting altitude in meters, defaults to 0.
-- @param #number InitSpeed (Optional) Starting speed in KPH, defaults to 0.
-- @param #boolean UseSmoke (Optional)  Using smoke, defaults to false.
-- @param #boolean StartImmediately (Optional) If true, start immediately and ignore  InitAltitude and InitSpeed.
-- @param #number Side (Optional) On which side to fly,  0 == left, 1 == right side, defaults to 0.
-- @param #number RollDeg (Optional) Roll degrees for Roll 1 and 2, defaults to 60.
-- @param #number Pull (Optional) How many Gs to pull in this, defaults to 2.
-- @param #number Angle (Optional) How many degrees to turn, defaults to 180.
-- @return DCS#Task
function CONTROLLABLE:TaskAerobaticsTurn(TaskAerobatics,Repeats,InitAltitude,InitSpeed,UseSmoke,StartImmediately,Side,RollDeg,Pull,Angle)

  local maxrepeats = 10

  if Repeats > maxrepeats then maxrepeats = Repeats end

  local usesmoke = UseSmoke and 1 or 0

  local startimmediately = StartImmediately and 1 or 0

  local Task = {
    ["name"] = "TURN",
    ["params"] = {
      ["RepeatQty"] = {
        ["max_v"] = maxrepeats,
        ["min_v"] = 1,
        ["order"] = 1,
        ["value"] = Repeats or 1,
      },
      ["InitAltitude"] = {
        ["order"] = 2,
        ["value"] = InitAltitude or 0,
      },
      ["InitSpeed"] = {
        ["order"] = 3,
        ["value"] = InitSpeed or 0,
      },
      ["UseSmoke"] = {
        ["order"] = 4,
        ["value"] = usesmoke,
      },
      ["StartImmediatly"] = {
        ["order"] = 5,
        ["value"] = startimmediately,
      },
      ["Ny_req"] = {
        ["order"] = 6,
        ["value"] = Pull or 2, --amount of G to pull
      },
      ["ROLL"] = {
        ["order"] = 7,
        ["value"] = RollDeg or 60,
      },
      ["SECTOR"] = {
        ["order"] = 8,
        ["value"] = Angle or 180,
      },
      ["SIDE"] = {
        ["order"] = 9,
        ["value"] = Side or 0,
      },
    }
  }

  table.insert(TaskAerobatics.params["maneuversSequency"],Task)

  return TaskAerobatics
end

--- Add an aerobatics entry of type "DIVE" to the Aerobatics Task.
-- @param #CONTROLLABLE self
-- @param DCS#Task TaskAerobatics The Aerobatics Task
-- @param #number Repeats (Optional) The number of repeats, defaults to 1.
-- @param #number InitAltitude (Optional) Starting altitude in meters, defaults to 5000.
-- @param #number InitSpeed (Optional) Starting speed in KPH, defaults to 0.
-- @param #boolean UseSmoke (Optional)  Using smoke, defaults to false.
-- @param #boolean StartImmediately (Optional) If true, start immediately and ignore  InitAltitude and InitSpeed.
-- @param #number Angle (Optional) With how many degrees to dive, defaults to 45. Can be 15 to 90 degrees.
-- @param #number FinalAltitude (Optional) Final altitude in meters, defaults to 1000.
-- @return DCS#Task
function CONTROLLABLE:TaskAerobaticsDive(TaskAerobatics,Repeats,InitAltitude,InitSpeed,UseSmoke,StartImmediately,Angle,FinalAltitude)

  local maxrepeats = 10

  local angle = Angle

  if angle < 15 then angle = 15 elseif angle > 90 then angle = 90 end

  if Repeats > maxrepeats then maxrepeats = Repeats end

  local usesmoke = UseSmoke and 1 or 0

  local startimmediately = StartImmediately and 1 or 0

  local Task = {
    ["name"] = "DIVE",
    ["params"] = {
      ["RepeatQty"] = {
        ["max_v"] = maxrepeats,
        ["min_v"] = 1,
        ["order"] = 1,
        ["value"] = Repeats or 1,
      },
      ["InitAltitude"] = {
        ["order"] = 2,
        ["value"] = InitAltitude or 5000,
      },
      ["InitSpeed"] = {
        ["order"] = 3,
        ["value"] = InitSpeed or 0,
      },
      ["UseSmoke"] = {
        ["order"] = 4,
        ["value"] = usesmoke,
      },
      ["StartImmediatly"] = {
        ["order"] = 5,
        ["value"] = startimmediately,
      },
      ["Angle"] = {
        ["max_v"] = 90,
        ["min_v"] = 15,
        ["order"] = 6,
        ["step"] = 5,
        ["value"] = angle or 45,
      },
      ["FinalAltitude"] = {
        ["order"] = 7,
        ["value"] = FinalAltitude or 1000,
      },
    }
  }

  table.insert(TaskAerobatics.params["maneuversSequency"],Task)

  return TaskAerobatics
end

--- Add an aerobatics entry of type "MILITARY_TURN" to the Aerobatics Task.
-- @param #CONTROLLABLE self
-- @param DCS#Task TaskAerobatics The Aerobatics Task
-- @param #number Repeats (Optional) The number of repeats, defaults to 1.
-- @param #number InitAltitude (Optional) Starting altitude in meters, defaults to 0.
-- @param #number InitSpeed (Optional) Starting speed in KPH, defaults to 0.
-- @param #boolean UseSmoke (Optional)  Using smoke, defaults to false.
-- @param #boolean StartImmediately (Optional) If true, start immediately and ignore  InitAltitude and InitSpeed.
-- @return DCS#Task
function CONTROLLABLE:TaskAerobaticsMilitaryTurn(TaskAerobatics,Repeats,InitAltitude,InitSpeed,UseSmoke,StartImmediately)

  local maxrepeats = 10

  if Repeats > maxrepeats then maxrepeats = Repeats end

  local usesmoke = UseSmoke and 1 or 0

  local startimmediately = StartImmediately and 1 or 0

  local Task = {
    ["name"] = "MILITARY_TURN",
    ["params"] = {
      ["RepeatQty"] = {
        ["max_v"] = maxrepeats,
        ["min_v"] = 1,
        ["order"] = 1,
        ["value"] = Repeats or 1,
      },
      ["InitAltitude"] = {
        ["order"] = 2,
        ["value"] = InitAltitude or 0,
      },
      ["InitSpeed"] = {
        ["order"] = 3,
        ["value"] = InitSpeed or 0,
      },
      ["UseSmoke"] = {
        ["order"] = 4,
        ["value"] = usesmoke,
      },
      ["StartImmediatly"] = {
        ["order"] = 5,
        ["value"] = startimmediately,
      }
    }
  }

  table.insert(TaskAerobatics.params["maneuversSequency"],Task)

  return TaskAerobatics
end

--- Add an aerobatics entry of type "IMMELMAN" to the Aerobatics Task.
-- @param #CONTROLLABLE self
-- @param DCS#Task TaskAerobatics The Aerobatics Task
-- @param #number Repeats (Optional) The number of repeats, defaults to 1.
-- @param #number InitAltitude (Optional) Starting altitude in meters, defaults to 0.
-- @param #number InitSpeed (Optional) Starting speed in KPH, defaults to 0.
-- @param #boolean UseSmoke (Optional)  Using smoke, defaults to false.
-- @param #boolean StartImmediately (Optional) If true, start immediately and ignore  InitAltitude and InitSpeed.
-- @return DCS#Task
function CONTROLLABLE:TaskAerobaticsImmelmann(TaskAerobatics,Repeats,InitAltitude,InitSpeed,UseSmoke,StartImmediately)

  local maxrepeats = 10

  if Repeats > maxrepeats then maxrepeats = Repeats end

  local usesmoke = UseSmoke and 1 or 0

  local startimmediately = StartImmediately and 1 or 0

  local Task = {
    ["name"] = "IMMELMAN",
    ["params"] = {
      ["RepeatQty"] = {
        ["max_v"] = maxrepeats,
        ["min_v"] = 1,
        ["order"] = 1,
        ["value"] = Repeats or 1,
      },
      ["InitAltitude"] = {
        ["order"] = 2,
        ["value"] = InitAltitude or 0,
      },
      ["InitSpeed"] = {
        ["order"] = 3,
        ["value"] = InitSpeed or 0,
      },
      ["UseSmoke"] = {
        ["order"] = 4,
        ["value"] = usesmoke,
      },
      ["StartImmediatly"] = {
        ["order"] = 5,
        ["value"] = startimmediately,
      }
    }
  }

  table.insert(TaskAerobatics.params["maneuversSequency"],Task)

  return TaskAerobatics
end

--- Add an aerobatics entry of type "STRAIGHT_FLIGHT" to the Aerobatics Task.
-- @param #CONTROLLABLE self
-- @param DCS#Task TaskAerobatics The Aerobatics Task
-- @param #number Repeats (Optional) The number of repeats, defaults to 1.
-- @param #number InitAltitude (Optional) Starting altitude in meters, defaults to 0.
-- @param #number InitSpeed (Optional) Starting speed in KPH, defaults to 0.
-- @param #boolean UseSmoke (Optional)  Using smoke, defaults to false.
-- @param #boolean StartImmediately (Optional) If true, start immediately and ignore  InitAltitude and InitSpeed.
-- @param #number FlightTime (Optional) Time to fly this manoever in seconds, defaults to 10.
-- @return DCS#Task
function CONTROLLABLE:TaskAerobaticsStraightFlight(TaskAerobatics,Repeats,InitAltitude,InitSpeed,UseSmoke,StartImmediately,FlightTime)

  local maxrepeats = 10

  if Repeats > maxrepeats then maxrepeats = Repeats end

  local maxflight = 200

  if Repeats > maxrepeats then maxrepeats = Repeats end

  local flighttime = FlightTime or 10

  if flighttime > 200 then maxflight = flighttime end

  local usesmoke = UseSmoke and 1 or 0

  local startimmediately = StartImmediately and 1 or 0

  local Task = {
    ["name"] = "STRAIGHT_FLIGHT",
    ["params"] = {
      ["RepeatQty"] = {
        ["max_v"] = maxrepeats,
        ["min_v"] = 1,
        ["order"] = 1,
        ["value"] = Repeats or 1,
      },
      ["InitAltitude"] = {
        ["order"] = 2,
        ["value"] = InitAltitude or 0,
      },
      ["InitSpeed"] = {
        ["order"] = 3,
        ["value"] = InitSpeed or 0,
      },
      ["UseSmoke"] = {
        ["order"] = 4,
        ["value"] = usesmoke,
      },
      ["StartImmediatly"] = {
        ["order"] = 5,
        ["value"] = startimmediately,
      },
      ["FlightTime"] = {
        ["max_v"] = maxflight,
        ["min_v"] = 1,
        ["order"] = 6,
        ["step"] = 0.1,
        ["value"] = flighttime or 10,
      },
    }
  }

  table.insert(TaskAerobatics.params["maneuversSequency"],Task)

  return TaskAerobatics
end

--- Add an aerobatics entry of type "CLIMB" to the Aerobatics Task.
-- @param #CONTROLLABLE self
-- @param DCS#Task TaskAerobatics The Aerobatics Task
-- @param #number Repeats (Optional) The number of repeats, defaults to 1.
-- @param #number InitAltitude (Optional) Starting altitude in meters, defaults to 0.
-- @param #number InitSpeed (Optional) Starting speed in KPH, defaults to 0.
-- @param #boolean UseSmoke (Optional)  Using smoke, defaults to false.
-- @param #boolean StartImmediately (Optional) If true, start immediately and ignore  InitAltitude and InitSpeed.
-- @param #number Angle (Optional) Angle to climb. Can be between 15 and 90 degrees. Defaults to 45 degrees.
-- @param #number FinalAltitude (Optional) Altitude to climb to in meters. Defaults to 5000m.
-- @return DCS#Task
function CONTROLLABLE:TaskAerobaticsClimb(TaskAerobatics,Repeats,InitAltitude,InitSpeed,UseSmoke,StartImmediately,Angle,FinalAltitude)

  local maxrepeats = 10

  if Repeats > maxrepeats then maxrepeats = Repeats end

  local usesmoke = UseSmoke and 1 or 0

  local startimmediately = StartImmediately and 1 or 0

  local Task = {
    ["name"] = "CLIMB",
    ["params"] = {
      ["RepeatQty"] = {
        ["max_v"] = maxrepeats,
        ["min_v"] = 1,
        ["order"] = 1,
        ["value"] = Repeats or 1,
      },
      ["InitAltitude"] = {
        ["order"] = 2,
        ["value"] = InitAltitude or 0,
      },
      ["InitSpeed"] = {
        ["order"] = 3,
        ["value"] = InitSpeed or 0,
      },
      ["UseSmoke"] = {
        ["order"] = 4,
        ["value"] = usesmoke,
      },
      ["StartImmediatly"] = {
        ["order"] = 5,
        ["value"] = startimmediately,
      },
      ["Angle"] = {
        ["max_v"] = 90,
        ["min_v"] = 15,
        ["order"] = 6,
        ["step"] = 5,
        ["value"] = Angle or 45,
      },
      ["FinalAltitude"] = {
        ["order"] = 7,
        ["value"] = FinalAltitude or 5000,
      },
    }
  }

  table.insert(TaskAerobatics.params["maneuversSequency"],Task)

  return TaskAerobatics
end

--- Add an aerobatics entry of type "SPIRAL" to the Aerobatics Task.
-- @param #CONTROLLABLE self
-- @param DCS#Task TaskAerobatics The Aerobatics Task
-- @param #number Repeats (Optional) The number of repeats, defaults to 1.
-- @param #number InitAltitude (Optional) Starting altitude in meters, defaults to 0.
-- @param #number InitSpeed (Optional) Starting speed in KPH, defaults to 0.
-- @param #boolean UseSmoke (Optional)  Using smoke, defaults to false.
-- @param #boolean StartImmediately (Optional) If true, start immediately and ignore  InitAltitude and InitSpeed.
-- @param #number TurnAngle (Optional) Turn angle, defaults to 360 degrees.
-- @param #number Roll (Optional) Roll to take, defaults to 60 degrees.
-- @param #number Side (Optional) On which side to fly,  0 == left, 1 == right side, defaults to 0.
-- @param #number UpDown (Optional) Spiral upwards (1) or downwards (0). Defaults to 0 - downwards.
-- @param #number Angle (Optional) Angle to spiral. Can be between 15 and 90 degrees. Defaults to 45 degrees.
-- @return DCS#Task
function CONTROLLABLE:TaskAerobaticsSpiral(TaskAerobatics,Repeats,InitAltitude,InitSpeed,UseSmoke,StartImmediately,TurnAngle,Roll,Side,UpDown,Angle)

  local maxrepeats = 10

  if Repeats > maxrepeats then maxrepeats = Repeats end

  local usesmoke = UseSmoke and 1 or 0

  local startimmediately = StartImmediately and 1 or 0
  local updown = UpDown and 1 or 0
  local side = Side and 1 or 0

  local Task = {
    ["name"] = "SPIRAL",
    ["params"] = {
      ["RepeatQty"] = {
        ["max_v"] = maxrepeats,
        ["min_v"] = 1,
        ["order"] = 1,
        ["value"] = Repeats or 1,
      },
      ["InitAltitude"] = {
        ["order"] = 2,
        ["value"] = InitAltitude or 0,
      },
      ["InitSpeed"] = {
        ["order"] = 3,
        ["value"] = InitSpeed or 0,
      },
      ["UseSmoke"] = {
        ["order"] = 4,
        ["value"] = usesmoke,
      },
      ["StartImmediatly"] = {
        ["order"] = 5,
        ["value"] = startimmediately,
      },
      ["SECTOR"] = {
        ["order"] = 6,
        ["value"] = TurnAngle or 360,
      },
      ["ROLL"] = {
        ["order"] = 7,
        ["value"] = Roll or 60,
      },
      ["SIDE"] = {
        ["order"] = 8,
        ["value"] = side or 0,
      },
      ["UPDOWN"] = {
        ["order"] = 9,
        ["value"] = updown or 0,
      },
      ["Angle"] = {
        ["max_v"] = 90,
        ["min_v"] = 15,
        ["order"] = 10,
        ["step"] = 5,
        ["value"] = Angle or 45,
      },
    }
  }

  table.insert(TaskAerobatics.params["maneuversSequency"],Task)

  return TaskAerobatics
end

--- Add an aerobatics entry of type "SPLIT_S" to the Aerobatics Task.
-- @param #CONTROLLABLE self
-- @param DCS#Task TaskAerobatics The Aerobatics Task
-- @param #number Repeats (Optional) The number of repeats, defaults to 1.
-- @param #number InitAltitude (Optional) Starting altitude in meters, defaults to 0.
-- @param #number InitSpeed (Optional) Starting speed in KPH, defaults to 0.
-- @param #boolean UseSmoke (Optional)  Using smoke, defaults to false.
-- @param #boolean StartImmediately (Optional) If true, start immediately and ignore  InitAltitude and InitSpeed.
-- @param #number FinalSpeed (Optional) Final speed to reach in KPH. Defaults to 500 kph.
-- @return DCS#Task
function CONTROLLABLE:TaskAerobaticsSplitS(TaskAerobatics,Repeats,InitAltitude,InitSpeed,UseSmoke,StartImmediately,FinalSpeed)

  local maxrepeats = 10

  if Repeats > maxrepeats then maxrepeats = Repeats end

  local maxflight = 200

  if Repeats > maxrepeats then maxrepeats = Repeats end

  local finalspeed = FinalSpeed or 500

  local usesmoke = UseSmoke and 1 or 0

  local startimmediately = StartImmediately and 1 or 0

  local Task = {
    ["name"] = "SPLIT_S",
    ["params"] = {
      ["RepeatQty"] = {
        ["max_v"] = maxrepeats,
        ["min_v"] = 1,
        ["order"] = 1,
        ["value"] = Repeats or 1,
      },
      ["InitAltitude"] = {
        ["order"] = 2,
        ["value"] = InitAltitude or 0,
      },
      ["InitSpeed"] = {
        ["order"] = 3,
        ["value"] = InitSpeed or 0,
      },
      ["UseSmoke"] = {
        ["order"] = 4,
        ["value"] = usesmoke,
      },
      ["StartImmediatly"] = {
        ["order"] = 5,
        ["value"] = startimmediately,
      },
      ["FinalSpeed"] = {
        ["order"] = 6,
        ["value"] = finalspeed,
      },
    }
  }

  table.insert(TaskAerobatics.params["maneuversSequency"],Task)

  return TaskAerobatics
end

--- Add an aerobatics entry of type "AILERON_ROLL" to the Aerobatics Task.
-- @param #CONTROLLABLE self
-- @param DCS#Task TaskAerobatics The Aerobatics Task
-- @param #number Repeats (Optional) The number of repeats, defaults to 1.
-- @param #number InitAltitude (Optional) Starting altitude in meters, defaults to 0.
-- @param #number InitSpeed (Optional) Starting speed in KPH, defaults to 0.
-- @param #boolean UseSmoke (Optional)  Using smoke, defaults to false.
-- @param #boolean StartImmediately (Optional) If true, start immediately and ignore  InitAltitude and InitSpeed.
-- @param #number Side (Optional) On which side to fly,  0 == left, 1 == right side, defaults to 0.
-- @param #number RollRate (Optional) How many degrees to roll per sec(?), can be between 15 and 450, defaults to 90.
-- @param #number TurnAngle (Optional) Angles to turn overall, defaults to 360.
-- @param #number FixAngle (Optional) No idea what this does, can be between 0 and 180 degrees, defaults to 180.
-- @return DCS#Task
function CONTROLLABLE:TaskAerobaticsAileronRoll(TaskAerobatics,Repeats,InitAltitude,InitSpeed,UseSmoke,StartImmediately,Side,RollRate,TurnAngle,FixAngle)

  local maxrepeats = 10

  if Repeats > maxrepeats then maxrepeats = Repeats end

  local maxflight = 200

  if Repeats > maxrepeats then maxrepeats = Repeats end

  local usesmoke = UseSmoke and 1 or 0

  local startimmediately = StartImmediately and 1 or 0

  local Task = {
    ["name"] = "AILERON_ROLL",
    ["params"] = {
      ["RepeatQty"] = {
        ["max_v"] = maxrepeats,
        ["min_v"] = 1,
        ["order"] = 1,
        ["value"] = Repeats or 1,
      },
      ["InitAltitude"] = {
        ["order"] = 2,
        ["value"] = InitAltitude or 0,
      },
      ["InitSpeed"] = {
        ["order"] = 3,
        ["value"] = InitSpeed or 0,
      },
      ["UseSmoke"] = {
        ["order"] = 4,
        ["value"] = usesmoke,
      },
      ["StartImmediatly"] = {
        ["order"] = 5,
        ["value"] = startimmediately,
      },
      ["SIDE"] = {
        ["order"] = 6,
        ["value"] = Side or 0,
      },
      ["RollRate"] = {
        ["max_v"] = 450,
        ["min_v"] = 15,
        ["order"] = 7,
        ["step"] = 5,
        ["value"] = RollRate or 90,
      },
      ["SECTOR"] = {
        ["order"] = 8,
        ["value"] = TurnAngle or 360,
      },
      ["FIXSECTOR"] = {
        ["max_v"] = 180,
        ["min_v"] = 0,
        ["order"] = 9,
        ["step"] = 5,
        ["value"] = FixAngle or 0, -- TODO: Need to find out what this does
      },
    }
  }

  table.insert(TaskAerobatics.params["maneuversSequency"],Task)

  return TaskAerobatics
end

--- Add an aerobatics entry of type "FORCED_TURN" to the Aerobatics Task.
-- @param #CONTROLLABLE self
-- @param DCS#Task TaskAerobatics The Aerobatics Task
-- @param #number Repeats (Optional) The number of repeats, defaults to 1.
-- @param #number InitAltitude (Optional) Starting altitude in meters, defaults to 0.
-- @param #number InitSpeed (Optional) Starting speed in KPH, defaults to 0.
-- @param #boolean UseSmoke (Optional)  Using smoke, defaults to false.
-- @param #boolean StartImmediately (Optional) If true, start immediately and ignore  InitAltitude and InitSpeed.
-- @param #number TurnAngle (Optional) Angles to turn, defaults to 360.
-- @param #number Side (Optional) On which side to fly,  0 == left, 1 == right side, defaults to 0.
-- @param #number FlightTime (Optional) Flight time in seconds for thos maneuver. Defaults to 30.
-- @param #number MinSpeed (Optional) Minimum speed to keep in kph, defaults to 250 kph.
-- @return DCS#Task
function CONTROLLABLE:TaskAerobaticsForcedTurn(TaskAerobatics,Repeats,InitAltitude,InitSpeed,UseSmoke,StartImmediately,TurnAngle,Side,FlightTime,MinSpeed)

  local maxrepeats = 10
  local flighttime = FlightTime or 30
  local maxtime = 200
  if flighttime > 200 then maxtime = flighttime end

  if Repeats > maxrepeats then maxrepeats = Repeats end

  local usesmoke = UseSmoke and 1 or 0

  local startimmediately = StartImmediately and 1 or 0

  local Task = {
    ["name"] = "FORCED_TURN",
    ["params"] = {
      ["RepeatQty"] = {
        ["max_v"] = maxrepeats,
        ["min_v"] = 1,
        ["order"] = 1,
        ["value"] = Repeats or 1,
      },
      ["InitAltitude"] = {
        ["order"] = 2,
        ["value"] = InitAltitude or 0,
      },
      ["InitSpeed"] = {
        ["order"] = 3,
        ["value"] = InitSpeed or 0,
      },
      ["UseSmoke"] = {
        ["order"] = 4,
        ["value"] = usesmoke,
      },
      ["StartImmediatly"] = {
        ["order"] = 5,
        ["value"] = startimmediately,
      },
      ["SECTOR"] = {
        ["order"] = 6,
        ["value"] = TurnAngle or 360,
      },
      ["SIDE"] = {
        ["order"] = 7,
        ["value"] = Side or 0,
      },
      ["FlightTime"] = {
        ["max_v"] = maxtime or 200,
        ["min_v"] = 0,
        ["order"] = 8,
        ["step"] = 0.1,
        ["value"] = flighttime or 30,
      },
      ["MinSpeed"] = {
        ["max_v"] = 3000,
        ["min_v"] = 30,
        ["order"] = 9,
        ["step"] = 10,
        ["value"] = MinSpeed or 250,
      },
    }
  }

  table.insert(TaskAerobatics.params["maneuversSequency"],Task)

  return TaskAerobatics
end

--- Add an aerobatics entry of type "BARREL_ROLL" to the Aerobatics Task.
-- @param #CONTROLLABLE self
-- @param DCS#Task TaskAerobatics The Aerobatics Task
-- @param #number Repeats (Optional) The number of repeats, defaults to 1.
-- @param #number InitAltitude (Optional) Starting altitude in meters, defaults to 0.
-- @param #number InitSpeed (Optional) Starting speed in KPH, defaults to 0.
-- @param #boolean UseSmoke (Optional)  Using smoke, defaults to false.
-- @param #boolean StartImmediately (Optional) If true, start immediately and ignore  InitAltitude and InitSpeed.
-- @param #number Side (Optional) On which side to fly,  0 == left, 1 == right side, defaults to 0.
-- @param #number RollRate (Optional) How many degrees to roll per sec(?), can be between 15 and 450, defaults to 90.
-- @param #number TurnAngle (Optional) Turn angle, defaults to 360 degrees.
-- @return DCS#Task
function CONTROLLABLE:TaskAerobaticsBarrelRoll(TaskAerobatics,Repeats,InitAltitude,InitSpeed,UseSmoke,StartImmediately,Side,RollRate,TurnAngle)

  local maxrepeats = 10

  if Repeats > maxrepeats then maxrepeats = Repeats end

  local usesmoke = UseSmoke and 1 or 0

  local startimmediately = StartImmediately and 1 or 0

  local Task = {
    ["name"] = "BARREL_ROLL",
    ["params"] = {
      ["RepeatQty"] = {
        ["max_v"] = maxrepeats,
        ["min_v"] = 1,
        ["order"] = 1,
        ["value"] = Repeats or 1,
      },
      ["InitAltitude"] = {
        ["order"] = 2,
        ["value"] = InitAltitude or 0,
      },
      ["InitSpeed"] = {
        ["order"] = 3,
        ["value"] = InitSpeed or 0,
      },
      ["UseSmoke"] = {
        ["order"] = 4,
        ["value"] = usesmoke,
      },
      ["StartImmediatly"] = {
        ["order"] = 5,
        ["value"] = startimmediately,
      },
      ["SIDE"] = {
        ["order"] = 6,
        ["value"] = Side or 0,
      },
      ["RollRate"] = {
        ["max_v"] = 450,
        ["min_v"] = 15,
        ["order"] = 7,
        ["step"] = 5,
        ["value"] = RollRate or 90,
      },
      ["SECTOR"] = {
        ["order"] = 8,
        ["value"] = TurnAngle or 360,
      },
    }
  }

  table.insert(TaskAerobatics.params["maneuversSequency"],Task)

  return TaskAerobatics
end


--- [Air] Make an airplane or helicopter patrol between two points in a racetrack - resulting in a much tighter track around the start and end points.
-- @param #CONTROLLABLE self
-- @param Core.Point#COORDINATE Point1 Start point.
-- @param Core.Point#COORDINATE Point2 End point.
-- @param #number Altitude (Optional) Altitude in meters. Defaults to the altitude of the coordinate.
-- @param #number Speed (Optional) Speed in kph. Defaults to 500 kph.
-- @param #number Formation (Optional) Formation to take, e.g. ENUMS.Formation.FixedWing.Trail.Close, also see [Hoggit Wiki](https://wiki.hoggitworld.com/view/DCS_option_formation).
-- @param #boolean AGL (Optional) If true, set altitude to above ground level (AGL), not above sea level (ASL).
-- @param #number Delay  (Optional) Set the task after delay seconds only.
-- @return #CONTROLLABLE self
function CONTROLLABLE:PatrolRaceTrack(Point1, Point2, Altitude, Speed, Formation, AGL, Delay)

  local PatrolGroup = self -- Wrapper.Group#GROUP

  if not self:IsInstanceOf( "GROUP" ) then
    PatrolGroup = self:GetGroup() -- Wrapper.Group#GROUP
  end

  local delay = Delay or 1

  self:F( { PatrolGroup = PatrolGroup:GetName() } )

  if PatrolGroup:IsAir() then
    if Formation then
       PatrolGroup:SetOption(AI.Option.Air.id.FORMATION,Formation) -- https://wiki.hoggitworld.com/view/DCS_option_formation
   end

   local FromCoord = PatrolGroup:GetCoordinate()
   local ToCoord = Point1:GetCoordinate()

   -- Calculate the new Route
   if Altitude then
     local asl = true
     if AGL then asl = false end
     FromCoord:SetAltitude(Altitude, asl)
     ToCoord:SetAltitude(Altitude, asl)
   end

   -- Create a "air waypoint", which is a "point" structure that can be given as a parameter to a Task
   local Route = {}
   Route[#Route + 1] = FromCoord:WaypointAir( AltType, COORDINATE.WaypointType.TurningPoint, COORDINATE.WaypointAction.TurningPoint, Speed, true, nil, DCSTasks, description, timeReFuAr )
   Route[#Route + 1] = ToCoord:WaypointAir( AltType, COORDINATE.WaypointType.TurningPoint, COORDINATE.WaypointAction.TurningPoint, Speed, true, nil, DCSTasks, description, timeReFuAr )

   local TaskRouteToZone = PatrolGroup:TaskFunction( "CONTROLLABLE.PatrolRaceTrack", Point2, Point1, Altitude, Speed, Formation, Delay )
   PatrolGroup:SetTaskWaypoint( Route[#Route], TaskRouteToZone ) -- Set for the given Route at Waypoint 2 the TaskRouteToZone.
   PatrolGroup:Route( Route, Delay ) -- Move after delay seconds to the Route. See the Route method for details.
  end

  return self
end

--- IR Marker courtesy Florian Brinker (fbrinker)

--- [GROUND] Create and enable a new IR Marker for the given controllable UNIT or GROUP.
-- @param #CONTROLLABLE self
-- @param #boolean EnableImmediately (Optionally) If true start up the IR Marker immediately. Else you need to call `myobject:EnableIRMarker()` later on.
-- @param #number Runtime (Optionally) Run this IR Marker for the given number of seconds, then stop. Use in conjunction with EnableImmediately.
-- @return #CONTROLLABLE self
function CONTROLLABLE:NewIRMarker(EnableImmediately, Runtime)
  --sefl:F("NewIRMarker")
    if self.ClassName == "GROUP" then
      self.IRMarkerGroup = true
      self.IRMarkerUnit = false
    elseif self.ClassName == "UNIT" then
      self.IRMarkerGroup = false
      self.IRMarkerUnit = true
    end

    self.spot = nil
    self.timer = nil
    self.stoptimer = nil
    
    if EnableImmediately and EnableImmediately == true then
      self:EnableIRMarker(Runtime)
    end
    
    return self
end

--- [GROUND] Enable the IR marker.
-- @param #CONTROLLABLE self
-- @param #number Runtime (Optionally) Run this IR Marker for the given number of seconds, then stop. Else run until you call `myobject:DisableIRMarker()`.
-- @return #CONTROLLABLE self 
function CONTROLLABLE:EnableIRMarker(Runtime)
  --sefl:F("EnableIRMarker")
    if self.IRMarkerGroup == nil then
      self:NewIRMarker(true,Runtime)
      return
    end
    
    if (self.IRMarkerGroup == true) then
        self:EnableIRMarkerForGroup()
        return
    end

    self.timer = TIMER:New(CONTROLLABLE._MarkerBlink, self)
    self.timer:Start(nil, 1 - math.random(1, 5) / 10 / 2, Runtime) -- start randomized
    
    return self
end

--- [GROUND] Disable the IR marker.
-- @param #CONTROLLABLE self
-- @return #CONTROLLABLE self 
function CONTROLLABLE:DisableIRMarker()
 --sefl:F("DisableIRMarker")
    if (self.IRMarkerGroup == true) then
        self:DisableIRMarkerForGroup()
        return
    end
    
    if self.spot then 
      self.spot:destroy()
      self.spot = nil
      if self.timer and self.timer:IsRunning() then
          self.timer:Stop()
          self.timer = nil
      end
    end
    return self
end

--- [GROUND] Enable the IR markers for a whole group.
-- @param #CONTROLLABLE self
-- @return #CONTROLLABLE self 
function CONTROLLABLE:EnableIRMarkerForGroup()
  --sefl:F("EnableIRMarkerForGroup")
  if self.ClassName == "GROUP" then
    local units = self:GetUnits() or {}
    for _,_unit in pairs(units) do
      _unit:EnableIRMarker()
    end
  end
  return self
end

--- [GROUND] Disable the IR markers for a whole group.
-- @param #CONTROLLABLE self
-- @return #CONTROLLABLE self 
function CONTROLLABLE:DisableIRMarkerForGroup()
  --sefl:F("DisableIRMarkerForGroup")
  if self.ClassName == "GROUP" then
    local units = self:GetUnits() or {}
    for _,_unit in pairs(units) do
      _unit:DisableIRMarker()
    end
  end
  return self
end

--- [Internal] This method is called by the scheduler after enabling the IR marker.
-- @param #CONTROLLABLE self
-- @return #CONTROLLABLE self 
function CONTROLLABLE:_MarkerBlink()
  --sefl:F("_MarkerBlink")
    if self:IsAlive() ~= true then
        self:DisableIRMarker()
        return
    end

    self.timer.dT = 1 - (math.random(1, 2) / 10 / 2) -- randomize the blinking by a small amount

    local _, _, unitBBHeight, _ = self:GetObjectSize()
    local unitPos = self:GetPositionVec3()

    self.spot = Spot.createInfraRed(
        self.DCSUnit,
        { x = 0, y = (unitBBHeight + 1), z = 0 },
        { x = unitPos.x, y = (unitPos.y + unitBBHeight), z = unitPos.z }
    )

    local offTimer = TIMER:New(function() if self.spot then self.spot:destroy() end end)
    offTimer:Start(0.5)
    return self
end
