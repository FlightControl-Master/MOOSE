--- **Wrapper** -- CONTROLLABLE is an intermediate class wrapping Group and Unit classes "controllers".
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
-- @extends Wrapper.Positionable#POSITIONABLE
-- @field DCS#Controllable DCSControllable The DCS controllable class.
-- @field #string ControllableName The name of the controllable.



--- Wrapper class to handle the "DCS Controllable objects", which are Groups and Units:
--
--  * Support all DCS Controllable APIs.
--  * Enhance with Controllable specific APIs not in the DCS Controllable API set.
--  * Handle local Controllable Controller.
--  * Manage the "state" of the DCS Controllable.
--
-- ## CONTROLLABLE constructor
-- 
-- The CONTROLLABLE class provides the following functions to construct a CONTROLLABLE instance:
--
--  * @{#CONTROLLABLE.New}(): Create a CONTROLLABLE instance.
--
-- ## CONTROLLABLE Task methods
-- 
-- Several controllable task methods are available that help you to prepare tasks. 
-- These methods return a string consisting of the task description, which can then be given to either a @{Wrapper.Controllable#CONTROLLABLE.PushTask} or @{Wrapper.Controllable#SetTask} method to assign the task to the CONTROLLABLE.
-- Tasks are specific for the category of the CONTROLLABLE, more specific, for AIR, GROUND or AIR and GROUND. 
-- Each task description where applicable indicates for which controllable category the task is valid.
-- There are 2 main subdivisions of tasks: Assigned tasks and EnRoute tasks.
-- 
-- ### Task assignment
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
--   * @{#CONTROLLABLE.TaskFAC_AttackGroup}: (AIR + GROUND) The task makes the controllable/unit a FAC and orders the FAC to control the target (enemy ground controllable) destruction.
--   * @{#CONTROLLABLE.TaskFireAtPoint}: (GROUND) Fire some or all ammunition at a VEC2 point.
--   * @{#CONTROLLABLE.TaskFollow}: (AIR) Following another airborne controllable.
--   * @{#CONTROLLABLE.TaskHold}: (GROUND) Hold ground controllable from moving.
--   * @{#CONTROLLABLE.TaskHoldPosition}: (AIR) Hold position at the current position of the first unit of the controllable.
--   * @{#CONTROLLABLE.TaskLand}: (AIR HELICOPTER) Landing at the ground. For helicopters only.
--   * @{#CONTROLLABLE.TaskLandAtZone}: (AIR) Land the controllable at a @{Core.Zone#ZONE_RADIUS).
--   * @{#CONTROLLABLE.TaskOrbitCircle}: (AIR) Orbit at the current position of the first unit of the controllable at a specified alititude.
--   * @{#CONTROLLABLE.TaskOrbitCircleAtVec2}: (AIR) Orbit at a specified position at a specified alititude during a specified duration with a specified speed.
--   * @{#CONTROLLABLE.TaskRefueling}: (AIR) Refueling from the nearest tanker. No parameters.
--   * @{#CONTROLLABLE.TaskRoute}: (AIR + GROUND) Return a Misson task to follow a given route defined by Points.
--   * @{#CONTROLLABLE.TaskRouteToVec2}: (AIR + GROUND) Make the Controllable move to a given point.
--   * @{#CONTROLLABLE.TaskRouteToVec3}: (AIR + GROUND) Make the Controllable move to a given point.
--   * @{#CONTROLLABLE.TaskRouteToZone}: (AIR + GROUND) Route the controllable to a given zone.
--   * @{#CONTROLLABLE.TaskReturnToBase}: (AIR) Route the controllable to an airbase.
--
-- ### EnRoute assignment
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
-- ### Task preparation
-- 
-- There are certain task methods that allow to tailor the task behaviour:
--
--   * @{#CONTROLLABLE.TaskWrappedAction}: Return a WrappedAction Task taking a Command.
--   * @{#CONTROLLABLE.TaskCombo}: Return a Combo Task taking an array of Tasks.
--   * @{#CONTROLLABLE.TaskCondition}: Return a condition section for a controlled task.
--   * @{#CONTROLLABLE.TaskControlled}: Return a Controlled Task taking a Task and a TaskCondition.
-- 
-- ### Call a function as a Task
-- 
-- A function can be called which is part of a Task. The method @{#CONTROLLABLE.TaskFunction}() prepares
-- a Task that can call a GLOBAL function from within the Controller execution.
-- This method can also be used to **embed a function call when a certain waypoint has been reached**.
-- See below the **Tasks at Waypoints** section.
-- 
-- Demonstration Mission: [GRP-502 - Route at waypoint to random point](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/release-2-2-pre/GRP - Group Commands/GRP-502 - Route at waypoint to random point)
-- 
-- ### Tasks at Waypoints
-- 
-- Special Task methods are available to set tasks at certain waypoints.
-- The method @{#CONTROLLABLE.SetTaskWaypoint}() helps preparing a Route, embedding a Task at the Waypoint of the Route.
-- 
-- This creates a Task element, with an action to call a function as part of a Wrapped Task.
-- 
-- ### Obtain the mission from controllable templates
-- 
-- Controllable templates contain complete mission descriptions. Sometimes you want to copy a complete mission from a controllable and assign it to another:
-- 
--   * @{#CONTROLLABLE.TaskMission}: (AIR + GROUND) Return a mission task from a mission template.
--
-- ## CONTROLLABLE Command methods
-- 
-- Controllable **command methods** prepare the execution of commands using the @{#CONTROLLABLE.SetCommand} method:
-- 
--   * @{#CONTROLLABLE.CommandDoScript}: Do Script command.
--   * @{#CONTROLLABLE.CommandSwitchWayPoint}: Perform a switch waypoint command.
-- 
-- ## Routing of Controllables
-- 
-- Different routing methods exist to route GROUPs and UNITs to different locations:
--   
--   * @{#CONTROLLABLE.Route}(): Make the Controllable to follow a given route.  
--   * @{#CONTROLLABLE.RouteGroundTo}(): Make the GROUND Controllable to drive towards a specific coordinate.
--   * @{#CONTROLLABLE.RouteAirTo}(): Make the AIR Controllable to fly towards a specific coordinate. 
-- 
-- ## Option methods
-- 
-- Controllable **Option methods** change the behaviour of the Controllable while being alive.
-- 
-- ### Rule of Engagement:
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
-- ### Rule on thread:
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
  --self:F( ControllableName )
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
-- @return #number The controllable health value (unit or group average).
-- @return #nil The controllable is not existing or alive.  
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

--- Returns relative amount of fuel (from 0.0 to 1.0) the unit has in its internal tanks.
-- This method returns nil to ensure polymorphic behaviour! This method needs to be overridden by GROUP or UNIT.
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
  self:F2()

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
-- @return Wrapper.Controllable#CONTROLLABLE self
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
-- @return Wrapper.Controllable#CONTROLLABLE self
function CONTROLLABLE:PushTask( DCSTask, WaitTime )
  self:F2()

  local DCSControllable = self:GetDCSObject()

  if DCSControllable then
    local Controller = self:_GetController()

    -- When a controllable SPAWNs, it takes about a second to get the controllable in the simulator. Setting tasks to unspawned controllables provides unexpected results.
    -- Therefore we schedule the functions to set the mission and options for the Controllable.
    -- Controller:pushTask( DCSTask )

    if WaitTime then
      self.TaskScheduler:Schedule( Controller, Controller.pushTask, { DCSTask }, WaitTime )
    else
      Controller:pushTask( DCSTask )
    end

    return self
  end

  return nil
end

--- Clearing the Task Queue and Setting the Task on the queue from the controllable.
-- @param #CONTROLLABLE self
-- @return Wrapper.Controllable#CONTROLLABLE self
function CONTROLLABLE:SetTask( DCSTask, WaitTime )
  self:F2( { DCSTask = DCSTask } )

  local DCSControllable = self:GetDCSObject()

  if DCSControllable then

    local DCSControllableName = self:GetName()

    -- When a controllable SPAWNs, it takes about a second to get the controllable in the simulator. Setting tasks to unspawned controllables provides unexpected results.
    -- Therefore we schedule the functions to set the mission and options for the Controllable.
    -- Controller.setTask( Controller, DCSTask )

    local function SetTask( Controller, DCSTask )
      if self and self:IsAlive() then
        local Controller = self:_GetController()
        --self:I( "Before SetTask" )
        Controller:setTask( DCSTask )
        --self:I( "After SetTask" )
      else
        BASE:E( { DCSControllableName .. " is not alive anymore.", DCSTask = DCSTask } )
      end
    end

    if not WaitTime or WaitTime == 0 then
      SetTask( self, DCSTask )
    else
      self.TaskScheduler:Schedule( self, SetTask, { DCSTask }, WaitTime )
    end

    return self
  end

  return nil
end

--- Checking the Task Queue of the controllable. Returns false if no task is on the queue. true if there is a task.
-- @param #CONTROLLABLE self
-- @return Wrapper.Controllable#CONTROLLABLE self
function CONTROLLABLE:HasTask() --R2.2

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
-- @param DCS#Time time
-- @param #string userFlag
-- @param #boolean userFlagValue
-- @param #string condition
-- @param DCS#Time duration
-- @param #number lastWayPoint
-- return DCS#Task
function CONTROLLABLE:TaskCondition( time, userFlag, userFlagValue, condition, duration, lastWayPoint )
  self:F2( { time, userFlag, userFlagValue, condition, duration, lastWayPoint } )

  local DCSStopCondition = {}
  DCSStopCondition.time = time
  DCSStopCondition.userFlag = userFlag
  DCSStopCondition.userFlagValue = userFlagValue
  DCSStopCondition.condition = condition
  DCSStopCondition.duration = duration
  DCSStopCondition.lastWayPoint = lastWayPoint

  self:T3( { DCSStopCondition } )
  return DCSStopCondition
end

--- Return a Controlled Task taking a Task and a TaskCondition.
-- @param #CONTROLLABLE self
-- @param DCS#Task DCSTask
-- @param DCS#DCSStopCondition DCSStopCondition
-- @return DCS#Task
function CONTROLLABLE:TaskControlled( DCSTask, DCSStopCondition )
  self:F2( { DCSTask, DCSStopCondition } )

  local DCSTaskControlled

  DCSTaskControlled = {
    id = 'ControlledTask',
    params = {
      task = DCSTask,
      stopCondition = DCSStopCondition
    }
  }

  self:T3( { DCSTaskControlled } )
  return DCSTaskControlled
end

--- Return a Combo Task taking an array of Tasks.
-- @param #CONTROLLABLE self
-- @param DCS#TaskArray DCSTasks Array of @{DCSTasking.Task#Task}
-- @return DCS#Task
function CONTROLLABLE:TaskCombo( DCSTasks )
  self:F2( { DCSTasks } )

  local DCSTaskCombo

  DCSTaskCombo = {
    id = 'ComboTask',
    params = {
      tasks = DCSTasks
    }
  }
  
  for TaskID, Task in ipairs( DCSTasks ) do
    self:T( Task )
  end

  self:T3( { DCSTaskCombo } )
  return DCSTaskCombo
end

--- Return a WrappedAction Task taking a Command.
-- @param #CONTROLLABLE self
-- @param DCS#Command DCSCommand
-- @return DCS#Task
function CONTROLLABLE:TaskWrappedAction( DCSCommand, Index )
  self:F2( { DCSCommand } )

  local DCSTaskWrappedAction
  
  DCSTaskWrappedAction = {
    id = "WrappedAction",
    enabled = true,
    number = Index or 1,
    auto = false,
    params = {
      action = DCSCommand,
    },
  }

  self:T3( { DCSTaskWrappedAction } )
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




--- Executes a command action
-- @param #CONTROLLABLE self
-- @param DCS#Command DCSCommand
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
-- --- This test demonstrates the use(s) of the SwitchWayPoint method of the GROUP class.
-- HeliGroup = GROUP:FindByName( "Helicopter" )
-- 
-- --- Route the helicopter back to the FARP after 60 seconds.
-- -- We use the SCHEDULER class to do this.
-- SCHEDULER:New( nil,
--   function( HeliGroup )
--    local CommandRTB = HeliGroup:CommandSwitchWayPoint( 2, 8 )
--    HeliGroup:SetCommand( CommandRTB )
--  end, { HeliGroup }, 90 
-- )
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


-- TASKS FOR AIR CONTROLLABLES


--- (AIR) Attack a Controllable.
-- @param #CONTROLLABLE self
-- @param Wrapper.Controllable#CONTROLLABLE AttackGroup The Controllable to be attacked.
-- @param #number WeaponType (optional) Bitmask of weapon types those allowed to use. If parameter is not defined that means no limits on weapon usage.
-- @param DCS#AI.Task.WeaponExpend WeaponExpend (optional) Determines how much weapon will be released at each attack. If parameter is not defined the unit / controllable will choose expend on its own discretion.
-- @param #number AttackQty (optional) This parameter limits maximal quantity of attack. The aicraft/controllable will not make more attack than allowed even if the target controllable not destroyed and the aicraft/controllable still have ammo. If not defined the aircraft/controllable will attack target until it will be destroyed or until the aircraft/controllable will run out of ammo.
-- @param DCS#Azimuth Direction (optional) Desired ingress direction from the target to the attacking aircraft. Controllable/aircraft will make its attacks from the direction. Of course if there is no way to attack from the direction due the terrain controllable/aircraft will choose another direction.
-- @param DCS#Distance Altitude (optional) Desired attack start altitude. Controllable/aircraft will make its attacks from the altitude. If the altitude is too low or too high to use weapon aircraft/controllable will choose closest altitude to the desired attack start altitude. If the desired altitude is defined controllable/aircraft will not attack from safe altitude.
-- @param #boolean AttackQtyLimit (optional) The flag determines how to interpret attackQty parameter. If the flag is true then attackQty is a limit on maximal attack quantity for "AttackGroup" and "AttackUnit" tasks. If the flag is false then attackQty is a desired attack quantity for "Bombing" and "BombingRunway" tasks.
-- @return DCS#Task The DCS task structure.
function CONTROLLABLE:TaskAttackGroup( AttackGroup, WeaponType, WeaponExpend, AttackQty, Direction, Altitude, AttackQtyLimit )
  self:F2( { self.ControllableName, AttackGroup, WeaponType, WeaponExpend, AttackQty, Direction, Altitude, AttackQtyLimit } )

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

  local DirectionEnabled = nil
  if Direction then
    DirectionEnabled = true
  end

  local AltitudeEnabled = nil
  if Altitude then
    AltitudeEnabled = true
  end

  local DCSTask
  DCSTask = { id = 'AttackGroup',
    params = {
      groupId = AttackGroup:GetID(),
      weaponType = WeaponType,
      expend = WeaponExpend,
      attackQty = AttackQty,
      directionEnabled = DirectionEnabled,
      direction = Direction,
      altitudeEnabled = AltitudeEnabled,
      altitude = Altitude,
      attackQtyLimit = AttackQtyLimit,
    },
  },

  self:T3( { DCSTask } )
  return DCSTask
end

--- (AIR) Attack the Unit.
-- @param #CONTROLLABLE self
-- @param Wrapper.Unit#UNIT AttackUnit The UNIT.
-- @param #boolean GroupAttack (optional) If true, all units in the group will attack the Unit when found.
-- @param DCS#AI.Task.WeaponExpend WeaponExpend (optional) Determines how much weapon will be released at each attack. If parameter is not defined the unit / controllable will choose expend on its own discretion.
-- @param #number AttackQty (optional) This parameter limits maximal quantity of attack. The aicraft/controllable will not make more attack than allowed even if the target controllable not destroyed and the aicraft/controllable still have ammo. If not defined the aircraft/controllable will attack target until it will be destroyed or until the aircraft/controllable will run out of ammo.
-- @param DCS#Azimuth Direction (optional) Desired ingress direction from the target to the attacking aircraft. Controllable/aircraft will make its attacks from the direction. Of course if there is no way to attack from the direction due the terrain controllable/aircraft will choose another direction.
-- @param #number Altitude (optional) The altitude from where to attack.
-- @param #boolean Visible (optional) not a clue.
-- @param #number WeaponType (optional) The WeaponType.
-- @return DCS#Task The DCS task structure.
function CONTROLLABLE:TaskAttackUnit( AttackUnit, GroupAttack, WeaponExpend, AttackQty, Direction, Altitude, Visible, WeaponType )
  self:F2( { self.ControllableName,          AttackUnit, GroupAttack, WeaponExpend, AttackQty, Direction, Altitude, Visible, WeaponType } )

  local DCSTask
  DCSTask = { 
    id = 'AttackUnit',
    params = {
      unitId = AttackUnit:GetID(),
      groupAttack = GroupAttack or false,
      visible = Visible or false,
      expend = WeaponExpend or "Auto",
      directionEnabled = Direction and true or false,
      direction = Direction,
      altitudeEnabled = Altitude and true or false,
      altitude = Altitude or 30,
      attackQtyLimit = AttackQty and true or false,
      attackQty = AttackQty,
      weaponType = WeaponType
    }
  }

  self:T3( DCSTask )
  
  return DCSTask
end


--- (AIR) Delivering weapon at the point on the ground. 
-- @param #CONTROLLABLE self
-- @param DCS#Vec2 Vec2 2D-coordinates of the point to deliver weapon at.
-- @param #boolean GroupAttack (optional) If true, all units in the group will attack the Unit when found.
-- @param DCS#AI.Task.WeaponExpend WeaponExpend (optional) Determines how much weapon will be released at each attack. If parameter is not defined the unit / controllable will choose expend on its own discretion.
-- @param #number AttackQty (optional) This parameter limits maximal quantity of attack. The aicraft/controllable will not make more attack than allowed even if the target controllable not destroyed and the aicraft/controllable still have ammo. If not defined the aircraft/controllable will attack target until it will be destroyed or until the aircraft/controllable will run out of ammo.
-- @param DCS#Azimuth Direction (optional) Desired ingress direction from the target to the attacking aircraft. Controllable/aircraft will make its attacks from the direction. Of course if there is no way to attack from the direction due the terrain controllable/aircraft will choose another direction.
-- @param #number Altitude (optional) The altitude from where to attack.
-- @param #number WeaponType (optional) The WeaponType.
-- @return DCS#Task The DCS task structure.
function CONTROLLABLE:TaskBombing( Vec2, GroupAttack, WeaponExpend, AttackQty, Direction, Altitude, WeaponType )
  self:F2( { self.ControllableName, Vec2, GroupAttack, WeaponExpend, AttackQty, Direction, Altitude, WeaponType } )

  local DCSTask
  DCSTask = { 
    id = 'Bombing',
    params = {
      point = Vec2,
      groupAttack = GroupAttack or false,
      expend = WeaponExpend or "Auto",
      attackQtyLimit = AttackQty and true or false,
      attackQty = AttackQty, 
      directionEnabled = Direction and true or false,
      direction = Direction, 
      altitudeEnabled = Altitude and true or false,
      altitude = Altitude or 30,
      weaponType = WeaponType, 
      },
  },

  self:T3( { DCSTask } )
  return DCSTask
end

--- (AIR) Attacking the map object (building, structure, e.t.c).
-- @param #CONTROLLABLE self
-- @param DCS#Vec2 Vec2 2D-coordinates of the point to deliver weapon at.
-- @param #boolean GroupAttack (optional) If true, all units in the group will attack the Unit when found.
-- @param DCS#AI.Task.WeaponExpend WeaponExpend (optional) Determines how much weapon will be released at each attack. If parameter is not defined the unit / controllable will choose expend on its own discretion.
-- @param #number AttackQty (optional) This parameter limits maximal quantity of attack. The aicraft/controllable will not make more attack than allowed even if the target controllable not destroyed and the aicraft/controllable still have ammo. If not defined the aircraft/controllable will attack target until it will be destroyed or until the aircraft/controllable will run out of ammo.
-- @param DCS#Azimuth Direction (optional) Desired ingress direction from the target to the attacking aircraft. Controllable/aircraft will make its attacks from the direction. Of course if there is no way to attack from the direction due the terrain controllable/aircraft will choose another direction.
-- @param #number Altitude (optional) The altitude from where to attack.
-- @param #number WeaponType (optional) The WeaponType.
-- @return DCS#Task The DCS task structure.
function CONTROLLABLE:TaskAttackMapObject( Vec2, GroupAttack, WeaponExpend, AttackQty, Direction, Altitude, WeaponType )
  self:F2( { self.ControllableName, Vec2, GroupAttack, WeaponExpend, AttackQty, Direction, Altitude, WeaponType } )

  local DCSTask
  DCSTask = { 
    id = 'AttackMapObject',
    params = {
      point = Vec2,
      groupAttack = GroupAttack or false,
      expend = WeaponExpend or "Auto",
      attackQtyLimit = AttackQty and true or false,
      attackQty = AttackQty, 
      directionEnabled = Direction and true or false,
      direction = Direction, 
      altitudeEnabled = Altitude and true or false,
      altitude = Altitude or 30,
      weaponType = WeaponType, 
    },
  },

  self:T3( { DCSTask } )
  return DCSTask
end


--- (AIR) Orbit at a specified position at a specified alititude during a specified duration with a specified speed.
-- @param #CONTROLLABLE self
-- @param DCS#Vec2 Point The point to hold the position.
-- @param #number Altitude The altitude [m] to hold the position.
-- @param #number Speed The speed [m/s] flying when holding the position.
-- @return #CONTROLLABLE self
function CONTROLLABLE:TaskOrbitCircleAtVec2( Point, Altitude, Speed )
  self:F2( { self.ControllableName, Point, Altitude, Speed } )

  --  pattern = enum AI.Task.OribtPattern,
  --    point = Vec2,
  --    point2 = Vec2,
  --    speed = Distance,
  --    altitude = Distance

  local LandHeight = land.getHeight( Point )

  self:T3( { LandHeight } )

  local DCSTask = { id = 'Orbit',
    params = { pattern = AI.Task.OrbitPattern.CIRCLE,
      point = Point,
      speed = Speed,
      altitude = Altitude + LandHeight
    }
  }


  --  local AITask = { id = 'ControlledTask',
  --                   params = { task = { id = 'Orbit',
  --                                       params = { pattern = AI.Task.OrbitPattern.CIRCLE,
  --                                                  point = Point,
  --                                                  speed = Speed,
  --                                                  altitude = Altitude + LandHeight
  --                                                }
  --                                     },
  --                              stopCondition = { duration = Duration
  --                                              }
  --                            }
  --                 }
  --               )

  return DCSTask
end

--- (AIR) Orbit at the current position of the first unit of the controllable at a specified alititude.
-- @param #CONTROLLABLE self
-- @param #number Altitude The altitude [m] to hold the position.
-- @param #number Speed The speed [m/s] flying when holding the position.
-- @param Core.Point#COORDINATE Coordinate The coordinate where to orbit.
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






--- (AIR) Delivering weapon on the runway.
-- @param #CONTROLLABLE self
-- @param Wrapper.Airbase#AIRBASE Airbase Airbase to attack.
-- @param #number WeaponType (optional) Bitmask of weapon types those allowed to use. If parameter is not defined that means no limits on weapon usage.
-- @param DCS#AI.Task.WeaponExpend WeaponExpend (optional) Determines how much weapon will be released at each attack. If parameter is not defined the unit / controllable will choose expend on its own discretion.
-- @param #number AttackQty (optional) This parameter limits maximal quantity of attack. The aicraft/controllable will not make more attack than allowed even if the target controllable not destroyed and the aicraft/controllable still have ammo. If not defined the aircraft/controllable will attack target until it will be destroyed or until the aircraft/controllable will run out of ammo.
-- @param DCS#Azimuth Direction (optional) Desired ingress direction from the target to the attacking aircraft. Controllable/aircraft will make its attacks from the direction. Of course if there is no way to attack from the direction due the terrain controllable/aircraft will choose another direction.
-- @param #boolean ControllableAttack (optional) Flag indicates that the target must be engaged by all aircrafts of the controllable. Has effect only if the task is assigned to a controllable, not to a single aircraft.
-- @return DCS#Task The DCS task structure.
function CONTROLLABLE:TaskBombingRunway( Airbase, WeaponType, WeaponExpend, AttackQty, Direction, ControllableAttack )
  self:F2( { self.ControllableName, Airbase, WeaponType, WeaponExpend, AttackQty, Direction, ControllableAttack } )

--  BombingRunway = { 
--    id = 'BombingRunway', 
--    params = { 
--      runwayId = AirdromeId,
--      weaponType = number, 
--      expend = enum AI.Task.WeaponExpend,
--      attackQty = number, 
--      direction = Azimuth, 
--      controllableAttack = boolean, 
--    } 
--  } 

  local DCSTask
  DCSTask = { id = 'BombingRunway',
    params = {
    point = Airbase:GetID(),
    weaponType = WeaponType, 
    expend = WeaponExpend,
    attackQty = AttackQty, 
    direction = Direction, 
    controllableAttack = ControllableAttack, 
    },
  },

  self:T3( { DCSTask } )
  return DCSTask
end


--- (AIR) Refueling from the nearest tanker. No parameters.
-- @param #CONTROLLABLE self
-- @return DCS#Task The DCS task structure.
function CONTROLLABLE:TaskRefueling()
  self:F2( { self.ControllableName } )

--  Refueling = { 
--    id = 'Refueling', 
--    params = {} 
--  }

  local DCSTask
  DCSTask = { id = 'Refueling',
    params = {
    },
  },

  self:T3( { DCSTask } )
  return DCSTask
end


--- (AIR HELICOPTER) Landing at the ground. For helicopters only.
-- @param #CONTROLLABLE self
-- @param DCS#Vec2 Point The point where to land.
-- @param #number Duration The duration in seconds to stay on the ground.
-- @return #CONTROLLABLE self
function CONTROLLABLE:TaskLandAtVec2( Point, Duration )
  self:F2( { self.ControllableName, Point, Duration } )

--  Land = {
--    id= 'Land',
--    params = {
--      point = Vec2,
--      durationFlag = boolean,
--      duration = Time
--    }
--  }
 
  local DCSTask
  if Duration and Duration > 0 then
    DCSTask = { id = 'Land', 
      params = { 
        point = Point, 
        durationFlag = true, 
        duration = Duration,
      }, 
    }
  else
    DCSTask = { id = 'Land', 
      params = { 
        point = Point, 
        durationFlag = false, 
      }, 
    }
  end

  self:T3( DCSTask )
  return DCSTask
end

--- (AIR) Land the controllable at a @{Core.Zone#ZONE_RADIUS).
-- @param #CONTROLLABLE self
-- @param Core.Zone#ZONE Zone The zone where to land.
-- @param #number Duration The duration in seconds to stay on the ground.
-- @return #CONTROLLABLE self
function CONTROLLABLE:TaskLandAtZone( Zone, Duration, RandomPoint )
  self:F2( { self.ControllableName, Zone, Duration, RandomPoint } )

  local Point
  if RandomPoint then
    Point = Zone:GetRandomVec2()
  else
    Point = Zone:GetVec2()
  end

  local DCSTask = self:TaskLandAtVec2( Point, Duration )

  self:T3( DCSTask )
  return DCSTask
end



--- (AIR) Following another airborne controllable. 
-- The unit / controllable will follow lead unit of another controllable, wingmens of both controllables will continue following their leaders. 
-- If another controllable is on land the unit / controllable will orbit around. 
-- @param #CONTROLLABLE self
-- @param Wrapper.Controllable#CONTROLLABLE FollowControllable The controllable to be followed.
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
  if LastWaypointIndex then
    LastWaypointIndexFlag = true
  end
  
  local DCSTask
  DCSTask = { 
    id = 'Follow',
    params = {
      groupId = FollowControllable:GetID(),
      pos = Vec3,
      lastWptIndexFlag = LastWaypointIndexFlag,
      lastWptIndex = LastWaypointIndex
    }
  }

  self:T3( { DCSTask } )
  return DCSTask
end


--- (AIR) Escort another airborne controllable. 
-- The unit / controllable will follow lead unit of another controllable, wingmens of both controllables will continue following their leaders. 
-- The unit / controllable will also protect that controllable from threats of specified types.
-- @param #CONTROLLABLE self
-- @param Wrapper.Controllable#CONTROLLABLE EscortControllable The controllable to be escorted.
-- @param DCS#Vec3 Vec3 Position of the unit / lead unit of the controllable relative lead unit of another controllable in frame reference oriented by course of lead unit of another controllable. If another controllable is on land the unit / controllable will orbit around.
-- @param #number LastWaypointIndex Detach waypoint of another controllable. Once reached the unit / controllable Follow task is finished.
-- @param #number EngagementDistanceMax Maximal distance from escorted controllable to threat. If the threat is already engaged by escort escort will disengage if the distance becomes greater than 1.5 * engagementDistMax. 
-- @param DCS#AttributeNameArray TargetTypes Array of AttributeName that is contains threat categories allowed to engage. 
-- @return DCS#Task The DCS task structure.
function CONTROLLABLE:TaskEscort( FollowControllable, Vec3, LastWaypointIndex, EngagementDistance, TargetTypes )
  self:F2( { self.ControllableName, FollowControllable, Vec3, LastWaypointIndex, EngagementDistance, TargetTypes } )

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

  local LastWaypointIndexFlag = false
  if LastWaypointIndex then
    LastWaypointIndexFlag = true
  end
  
  local DCSTask
  DCSTask = { id = 'Escort',
    params = {
      groupId = FollowControllable:GetID(),
      pos = Vec3,
      lastWptIndexFlag = LastWaypointIndexFlag,
      lastWptIndex = LastWaypointIndex,
      engagementDistMax = EngagementDistance,
      targetTypes = TargetTypes,
    },
  },

  self:T3( { DCSTask } )
  return DCSTask
end


-- GROUND TASKS

--- (GROUND) Fire at a VEC2 point until ammunition is finished.
-- @param #CONTROLLABLE self
-- @param DCS#Vec2 Vec2 The point to fire at.
-- @param DCS#Distance Radius The radius of the zone to deploy the fire at.
-- @param #number AmmoCount (optional) Quantity of ammunition to expand (omit to fire until ammunition is depleted).
-- @param #number WeaponType (optional) Enum for weapon type ID. This value is only required if you want the group firing to use a specific weapon, for instance using the task on a ship to force it to fire guided missiles at targets within cannon range. See http://wiki.hoggit.us/view/DCS_enum_weapon_flag 
-- @return DCS#Task The DCS task structure.
function CONTROLLABLE:TaskFireAtPoint( Vec2, Radius, AmmoCount, WeaponType )
  self:F2( { self.ControllableName, Vec2, Radius, AmmoCount, WeaponType } )

  -- FireAtPoint = {
  --   id = 'FireAtPoint',
  --   params = {
  --     point = Vec2,
  --     radius = Distance,
  --     expendQty = number,
  --     expendQtyEnabled = boolean, 
  --   }
  -- }

  local DCSTask
  DCSTask = { id = 'FireAtPoint',
    params = {
      point = Vec2,
      radius = Radius,
      expendQty = 100, -- dummy value
      expendQtyEnabled = false,
    }
  }
  
  if AmmoCount then
    DCSTask.params.expendQty = AmmoCount
    DCSTask.params.expendQtyEnabled = true
  end
  
  if WeaponType then
    DCSTask.params.weaponType=WeaponType
  end

  self:T3( { DCSTask } )
  return DCSTask
end

--- (GROUND) Hold ground controllable from moving.
-- @param #CONTROLLABLE self
-- @return DCS#Task The DCS task structure.
function CONTROLLABLE:TaskHold()
  self:F2( { self.ControllableName } )

--  Hold = { 
--    id = 'Hold', 
--    params = { 
--    } 
--  }

  local DCSTask
  DCSTask = { id = 'Hold',
    params = {
    }
  }

  self:T3( { DCSTask } )
  return DCSTask
end


-- TASKS FOR AIRBORNE AND GROUND UNITS/CONTROLLABLES

--- (AIR + GROUND) The task makes the controllable/unit a FAC and orders the FAC to control the target (enemy ground controllable) destruction. 
-- The killer is player-controlled allied CAS-aircraft that is in contact with the FAC.
-- If the task is assigned to the controllable lead unit will be a FAC. 
-- @param #CONTROLLABLE self
-- @param Wrapper.Controllable#CONTROLLABLE AttackGroup Target CONTROLLABLE.
-- @param #number WeaponType Bitmask of weapon types those allowed to use. If parameter is not defined that means no limits on weapon usage. 
-- @param DCS#AI.Task.Designation Designation (optional) Designation type.
-- @param #boolean Datalink (optional) Allows to use datalink to send the target information to attack aircraft. Enabled by default. 
-- @return DCS#Task The DCS task structure.
function CONTROLLABLE:TaskFAC_AttackGroup( AttackGroup, WeaponType, Designation, Datalink )
  self:F2( { self.ControllableName, AttackGroup, WeaponType, Designation, Datalink } )

--  FAC_AttackGroup = { 
--    id = 'FAC_AttackGroup', 
--    params = { 
--      groupId = Group.ID,
--      weaponType = number,
--      designation = enum AI.Task.Designation,
--      datalink = boolean
--    } 
--  }

  local DCSTask
  DCSTask = { id = 'FAC_AttackGroup',
    params = {
      groupId = AttackGroup:GetID(),
      weaponType = WeaponType,
      designation = Designation,
      datalink = Datalink,
    }
  }

  self:T3( { DCSTask } )
  return DCSTask
end

-- EN-ACT_ROUTE TASKS FOR AIRBORNE CONTROLLABLES

--- (AIR) Engaging targets of defined types.
-- @param #CONTROLLABLE self
-- @param DCS#Distance Distance Maximal distance from the target to a route leg. If the target is on a greater distance it will be ignored. 
-- @param DCS#AttributeNameArray TargetTypes Array of target categories allowed to engage. 
-- @param #number Priority All enroute tasks have the priority parameter. This is a number (less value - higher priority) that determines actions related to what task will be performed first. 
-- @return DCS#Task The DCS task structure.
function CONTROLLABLE:EnRouteTaskEngageTargets( Distance, TargetTypes, Priority )
  self:F2( { self.ControllableName, Distance, TargetTypes, Priority } )

--  EngageTargets ={ 
--    id = 'EngageTargets', 
--    params = { 
--      maxDist = Distance, 
--      targetTypes = array of AttributeName, 
--      priority = number 
--    } 
--  }

  local DCSTask
  DCSTask = { id = 'EngageTargets',
    params = {
      maxDist = Distance, 
      targetTypes = TargetTypes, 
      priority = Priority 
    }
  }

  self:T3( { DCSTask } )
  return DCSTask
end



--- (AIR) Engaging a targets of defined types at circle-shaped zone.
-- @param #CONTROLLABLE self
-- @param DCS#Vec2 Vec2 2D-coordinates of the zone. 
-- @param DCS#Distance Radius Radius of the zone. 
-- @param DCS#AttributeNameArray TargetTypes Array of target categories allowed to engage. 
-- @param #number Priority All en-route tasks have the priority parameter. This is a number (less value - higher priority) that determines actions related to what task will be performed first. 
-- @return DCS#Task The DCS task structure.
function CONTROLLABLE:EnRouteTaskEngageTargetsInZone( Vec2, Radius, TargetTypes, Priority )
  self:F2( { self.ControllableName, Vec2, Radius, TargetTypes, Priority } )

--  EngageTargetsInZone = { 
--    id = 'EngageTargetsInZone', 
--    params = { 
--      point = Vec2, 
--      zoneRadius = Distance, 
--      targetTypes = array of AttributeName,  
--      priority = number 
--    }
--  }

  local DCSTask
  DCSTask = { id = 'EngageTargetsInZone',
    params = {
      point = Vec2, 
      zoneRadius = Radius, 
      targetTypes = TargetTypes,  
      priority = Priority 
    }
  }

  self:T3( { DCSTask } )
  return DCSTask
end


--- (AIR) Engaging a controllable. The task does not assign the target controllable to the unit/controllable to attack now; it just allows the unit/controllable to engage the target controllable as well as other assigned targets.
-- @param #CONTROLLABLE self
-- @param Wrapper.Controllable#CONTROLLABLE AttackGroup The Controllable to be attacked.
-- @param #number Priority All en-route tasks have the priority parameter. This is a number (less value - higher priority) that determines actions related to what task will be performed first. 
-- @param #number WeaponType (optional) Bitmask of weapon types those allowed to use. If parameter is not defined that means no limits on weapon usage.
-- @param DCS#AI.Task.WeaponExpend WeaponExpend (optional) Determines how much weapon will be released at each attack. If parameter is not defined the unit / controllable will choose expend on its own discretion.
-- @param #number AttackQty (optional) This parameter limits maximal quantity of attack. The aicraft/controllable will not make more attack than allowed even if the target controllable not destroyed and the aicraft/controllable still have ammo. If not defined the aircraft/controllable will attack target until it will be destroyed or until the aircraft/controllable will run out of ammo.
-- @param DCS#Azimuth Direction (optional) Desired ingress direction from the target to the attacking aircraft. Controllable/aircraft will make its attacks from the direction. Of course if there is no way to attack from the direction due the terrain controllable/aircraft will choose another direction.
-- @param DCS#Distance Altitude (optional) Desired attack start altitude. Controllable/aircraft will make its attacks from the altitude. If the altitude is too low or too high to use weapon aircraft/controllable will choose closest altitude to the desired attack start altitude. If the desired altitude is defined controllable/aircraft will not attack from safe altitude.
-- @param #boolean AttackQtyLimit (optional) The flag determines how to interpret attackQty parameter. If the flag is true then attackQty is a limit on maximal attack quantity for "AttackGroup" and "AttackUnit" tasks. If the flag is false then attackQty is a desired attack quantity for "Bombing" and "BombingRunway" tasks.
-- @return DCS#Task The DCS task structure.
function CONTROLLABLE:EnRouteTaskEngageGroup( AttackGroup, Priority, WeaponType, WeaponExpend, AttackQty, Direction, Altitude, AttackQtyLimit )
  self:F2( { self.ControllableName, AttackGroup, Priority, WeaponType, WeaponExpend, AttackQty, Direction, Altitude, AttackQtyLimit } )

  --  EngageControllable  = {
  --   id = 'EngageControllable ',
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
  --     priority = number,
  --   }
  -- }

  local DirectionEnabled = nil
  if Direction then
    DirectionEnabled = true
  end

  local AltitudeEnabled = nil
  if Altitude then
    AltitudeEnabled = true
  end

  local DCSTask
  DCSTask = { id = 'EngageControllable',
    params = {
      groupId = AttackGroup:GetID(),
      weaponType = WeaponType,
      expend = WeaponExpend,
      attackQty = AttackQty,
      directionEnabled = DirectionEnabled,
      direction = Direction,
      altitudeEnabled = AltitudeEnabled,
      altitude = Altitude,
      attackQtyLimit = AttackQtyLimit,
      priority = Priority,
    },
  },

  self:T3( { DCSTask } )
  return DCSTask
end


--- (AIR) Search and attack the Unit.
-- @param #CONTROLLABLE self
-- @param Wrapper.Unit#UNIT EngageUnit The UNIT.
-- @param #number Priority (optional) All en-route tasks have the priority parameter. This is a number (less value - higher priority) that determines actions related to what task will be performed first. 
-- @param #boolean GroupAttack (optional) If true, all units in the group will attack the Unit when found.
-- @param DCS#AI.Task.WeaponExpend WeaponExpend (optional) Determines how much weapon will be released at each attack. If parameter is not defined the unit / controllable will choose expend on its own discretion.
-- @param #number AttackQty (optional) This parameter limits maximal quantity of attack. The aicraft/controllable will not make more attack than allowed even if the target controllable not destroyed and the aicraft/controllable still have ammo. If not defined the aircraft/controllable will attack target until it will be destroyed or until the aircraft/controllable will run out of ammo.
-- @param DCS#Azimuth Direction (optional) Desired ingress direction from the target to the attacking aircraft. Controllable/aircraft will make its attacks from the direction. Of course if there is no way to attack from the direction due the terrain controllable/aircraft will choose another direction.
-- @param DCS#Distance Altitude (optional) Desired altitude to perform the unit engagement.
-- @param #boolean Visible (optional) Unit must be visible.
-- @param #boolean ControllableAttack (optional) Flag indicates that the target must be engaged by all aircrafts of the controllable. Has effect only if the task is assigned to a controllable, not to a single aircraft.
-- @return DCS#Task The DCS task structure.
function CONTROLLABLE:EnRouteTaskEngageUnit( EngageUnit, Priority, GroupAttack, WeaponExpend, AttackQty, Direction, Altitude, Visible, ControllableAttack )
  self:F2( { self.ControllableName,          EngageUnit, Priority, GroupAttack, WeaponExpend, AttackQty, Direction, Altitude, Visible, ControllableAttack } )

  --  EngageUnit = {
  --    id = 'EngageUnit',
  --    params = {
  --      unitId = Unit.ID,
  --      weaponType = number,
  --      expend = enum AI.Task.WeaponExpend
  --      attackQty = number,
  --      direction = Azimuth,
  --      attackQtyLimit = boolean,
  --      controllableAttack = boolean,
  --      priority = number,
  --    }
  --  }

  local DCSTask
  DCSTask = { id = 'EngageUnit',
    params = {
      unitId = EngageUnit:GetID(),
      priority = Priority or 1,
      groupAttack = GroupAttack or false,
      visible = Visible or false,
      expend = WeaponExpend or "Auto",
      directionEnabled = Direction and true or false,
      direction = Direction,
      altitudeEnabled = Altitude and true or false,
      altitude = Altitude,
      attackQtyLimit = AttackQty and true or false,
      attackQty = AttackQty,
      controllableAttack = ControllableAttack,
    },
  },

  self:T3( { DCSTask } )
  return DCSTask
end



--- (AIR) Aircraft will act as an AWACS for friendly units (will provide them with information about contacts). No parameters.
-- @param #CONTROLLABLE self
-- @return DCS#Task The DCS task structure.
function CONTROLLABLE:EnRouteTaskAWACS( )
  self:F2( { self.ControllableName } )

--  AWACS = { 
--    id = 'AWACS', 
--    params = { 
--    } 
--  }

  local DCSTask
  DCSTask = { id = 'AWACS',
    params = {
    }
  }

  self:T3( { DCSTask } )
  return DCSTask
end


--- (AIR) Aircraft will act as a tanker for friendly units. No parameters.
-- @param #CONTROLLABLE self
-- @return DCS#Task The DCS task structure.
function CONTROLLABLE:EnRouteTaskTanker( )
  self:F2( { self.ControllableName } )

--  Tanker = { 
--    id = 'Tanker', 
--    params = { 
--    } 
--  }

  local DCSTask
  DCSTask = { id = 'Tanker',
    params = {
    }
  }

  self:T3( { DCSTask } )
  return DCSTask
end


-- En-route tasks for ground units/controllables

--- (GROUND) Ground unit (EW-radar) will act as an EWR for friendly units (will provide them with information about contacts). No parameters.
-- @param #CONTROLLABLE self
-- @return DCS#Task The DCS task structure.
function CONTROLLABLE:EnRouteTaskEWR( )
  self:F2( { self.ControllableName } )

--  EWR = { 
--    id = 'EWR', 
--    params = { 
--    } 
--  }

  local DCSTask
  DCSTask = { id = 'EWR',
    params = {
    }
  }

  self:T3( { DCSTask } )
  return DCSTask
end


-- En-route tasks for airborne and ground units/controllables 

--- (AIR + GROUND) The task makes the controllable/unit a FAC and lets the FAC to choose the target (enemy ground controllable) as well as other assigned targets. 
-- The killer is player-controlled allied CAS-aircraft that is in contact with the FAC.
-- If the task is assigned to the controllable lead unit will be a FAC. 
-- @param #CONTROLLABLE self
-- @param Wrapper.Controllable#CONTROLLABLE AttackGroup Target CONTROLLABLE.
-- @param #number Priority All en-route tasks have the priority parameter. This is a number (less value - higher priority) that determines actions related to what task will be performed first. 
-- @param #number WeaponType Bitmask of weapon types those allowed to use. If parameter is not defined that means no limits on weapon usage. 
-- @param DCS#AI.Task.Designation Designation (optional) Designation type.
-- @param #boolean Datalink (optional) Allows to use datalink to send the target information to attack aircraft. Enabled by default. 
-- @return DCS#Task The DCS task structure.
function CONTROLLABLE:EnRouteTaskFAC_EngageGroup( AttackGroup, Priority, WeaponType, Designation, Datalink )
  self:F2( { self.ControllableName, AttackGroup, WeaponType, Priority, Designation, Datalink } )

--  FAC_EngageControllable  = { 
--    id = 'FAC_EngageControllable', 
--    params = { 
--      groupId = Group.ID,
--      weaponType = number,
--      designation = enum AI.Task.Designation,
--      datalink = boolean,
--      priority = number,
--    } 
--  }

  local DCSTask
  DCSTask = { id = 'FAC_EngageControllable',
    params = {
      groupId = AttackGroup:GetID(),
      weaponType = WeaponType,
      designation = Designation,
      datalink = Datalink,
      priority = Priority,
    }
  }

  self:T3( { DCSTask } )
  return DCSTask
end


--- (AIR + GROUND) The task makes the controllable/unit a FAC and lets the FAC to choose a targets (enemy ground controllable) around as well as other assigned targets. 
-- The killer is player-controlled allied CAS-aircraft that is in contact with the FAC.
-- If the task is assigned to the controllable lead unit will be a FAC. 
-- @param #CONTROLLABLE self
-- @param DCS#Distance Radius  The maximal distance from the FAC to a target.
-- @param #number Priority All en-route tasks have the priority parameter. This is a number (less value - higher priority) that determines actions related to what task will be performed first. 
-- @return DCS#Task The DCS task structure.
function CONTROLLABLE:EnRouteTaskFAC( Radius, Priority )
  self:F2( { self.ControllableName, Radius, Priority } )

--  FAC = { 
--    id = 'FAC', 
--    params = { 
--      radius = Distance,
--      priority = number
--    } 
--  }

  local DCSTask
  DCSTask = { id = 'FAC',
    params = {
      radius = Radius,
      priority = Priority
    }
  }

  self:T3( { DCSTask } )
  return DCSTask
end




--- (AIR) Move the controllable to a Vec2 Point, wait for a defined duration and embark a controllable.
-- @param #CONTROLLABLE self
-- @param DCS#Vec2 Point The point where to wait.
-- @param #number Duration The duration in seconds to wait.
-- @param #CONTROLLABLE EmbarkingControllable The controllable to be embarked.
-- @return DCS#Task The DCS task structure
function CONTROLLABLE:TaskEmbarking( Point, Duration, EmbarkingControllable )
  self:F2( { self.ControllableName, Point, Duration, EmbarkingControllable.DCSControllable } )

  local DCSTask
  DCSTask =  { id = 'Embarking',
    params = { x = Point.x,
      y = Point.y,
      duration = Duration,
      controllablesForEmbarking = { EmbarkingControllable.ControllableID },
      durationFlag = true,
      distributionFlag = false,
      distribution = {},
    }
  }

  self:T3( { DCSTask } )
  return DCSTask
end

--- (GROUND) Embark to a Transport landed at a location.

--- Move to a defined Vec2 Point, and embark to a controllable when arrived within a defined Radius.
-- @param #CONTROLLABLE self
-- @param DCS#Vec2 Point The point where to wait.
-- @param #number Radius The radius of the embarking zone around the Point.
-- @return DCS#Task The DCS task structure.
function CONTROLLABLE:TaskEmbarkToTransport( Point, Radius )
  self:F2( { self.ControllableName, Point, Radius } )

  local DCSTask --DCS#Task
  DCSTask = { id = 'EmbarkToTransport',
    params = { x = Point.x,
      y = Point.y,
      zoneRadius = Radius,
    }
  }

  self:T3( { DCSTask } )
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
  self:F2( { FunctionString, arg } )

  local DCSTask

  local DCSScript = {}
  DCSScript[#DCSScript+1] = "local MissionControllable = GROUP:Find( ... ) "

  if arg and arg.n > 0 then
    local ArgumentKey = '_' .. tostring( arg ):match("table: (.*)")
    self:SetState( self, ArgumentKey, arg )
    DCSScript[#DCSScript+1] = "local Arguments = MissionControllable:GetState( MissionControllable, '" .. ArgumentKey .. "' ) "
    --DCSScript[#DCSScript+1] = "MissionControllable:ClearState( MissionControllable, '" .. ArgumentKey .. "' ) "
    DCSScript[#DCSScript+1] = FunctionString .. "( MissionControllable, unpack( Arguments ) )"
  else
    DCSScript[#DCSScript+1] = FunctionString .. "( MissionControllable )"
  end

  DCSTask = self:TaskWrappedAction(
    self:CommandDoScript(
      table.concat( DCSScript )
    )
  )

  self:T( DCSTask )

  return DCSTask

end



--- (AIR + GROUND) Return a mission task from a mission template.
-- @param #CONTROLLABLE self
-- @param #table TaskMission A table containing the mission task.
-- @return DCS#Task
function CONTROLLABLE:TaskMission( TaskMission )
  self:F2( Points )

  local DCSTask
  DCSTask = { id = 'Mission', params = { TaskMission, }, }

  self:T3( { DCSTask } )
  return DCSTask
end


do -- Patrol methods

  --- (GROUND) Patrol iteratively using the waypoints the for the (parent) group.
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
      local From = FromCoord:WaypointGround( 120 )
      
      table.insert( Waypoints, 1, From )

      local TaskRoute = PatrolGroup:TaskFunction( "CONTROLLABLE.PatrolRoute" )
      
      self:F({Waypoints = Waypoints})
      local Waypoint = Waypoints[#Waypoints]
      PatrolGroup:SetTaskWaypoint( Waypoint, TaskRoute ) -- Set for the given Route at Waypoint 2 the TaskRouteToZone.
    
      PatrolGroup:Route( Waypoints ) -- Move after a random seconds to the Route. See the Route method for details.
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
      
      -- Loop until a waypoint has been found that is not the same as the current waypoint.
      -- Otherwise the object zon't move or drive in circles and the algorithm would not do exactly
      -- what it is supposed to do, which is making groups drive around.
      local ToWaypoint
      repeat      
        -- Select a random waypoint and check if it is not the same waypoint as where the object is about.
        ToWaypoint = math.random( 1, #Waypoints )
      until( ToWaypoint ~= FromWaypoint )
      self:F( { FromWaypoint = FromWaypoint, ToWaypoint = ToWaypoint } )

      local  Waypoint = Waypoints[ToWaypoint] -- Select random waypoint.
      local ToCoord = COORDINATE:NewFromVec2( { x = Waypoint.x, y = Waypoint.y } )
      -- Create a "ground route point", which is a "point" structure that can be given as a parameter to a Task
      local Route = {}
      Route[#Route+1] = FromCoord:WaypointGround( 0 )
      Route[#Route+1] = ToCoord:WaypointGround( Speed, Formation )
      
      
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
  -- @return #CONTROLLABLE
  function CONTROLLABLE:PatrolZones( ZoneList, Speed, Formation )
  
    if not type( ZoneList ) == "table" then
      ZoneList = { ZoneList }
    end
  
    local PatrolGroup = self -- Wrapper.Group#GROUP
    
    if not self:IsInstanceOf( "GROUP" ) then
      PatrolGroup = self:GetGroup() -- Wrapper.Group#GROUP
    end

    self:F( { PatrolGroup = PatrolGroup:GetName() } )
    
    if PatrolGroup:IsGround() or PatrolGroup:IsShip() then
    
      local Waypoints = PatrolGroup:GetTemplateRoutePoints()
      local Waypoint = Waypoints[math.random( 1, #Waypoints )] -- Select random waypoint.
      
      -- Calculate the new Route.
      local FromCoord = PatrolGroup:GetCoordinate()
      
      -- Select a random Zone and get the Coordinate of the new Zone.
      local RandomZone = ZoneList[ math.random( 1, #ZoneList ) ] -- Core.Zone#ZONE
      local ToCoord = RandomZone:GetRandomCoordinate( 10 )
      
      -- Create a "ground route point", which is a "point" structure that can be given as a parameter to a Task
      local Route = {}
      Route[#Route+1] = FromCoord:WaypointGround( 20 )
      Route[#Route+1] = ToCoord:WaypointGround( Speed, Formation )
      
      
      local TaskRouteToZone = PatrolGroup:TaskFunction( "CONTROLLABLE.PatrolZones", ZoneList, Speed, Formation )
      
      PatrolGroup:SetTaskWaypoint( Route[#Route], TaskRouteToZone ) -- Set for the given Route at Waypoint 2 the TaskRouteToZone.
    
      PatrolGroup:Route( Route, 1 ) -- Move after a random seconds to the Route. See the Route method for details.
    end
  end

end


--- Return a Misson task to follow a given route defined by Points.
-- @param #CONTROLLABLE self
-- @param #table Points A table of route points.
-- @return DCS#Task
function CONTROLLABLE:TaskRoute( Points )
  self:F2( Points )

  local DCSTask
  DCSTask = { id = 'Mission', params = { route = { points = Points, }, }, }

  self:T3( { DCSTask } )
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
  
  
  --- Stops the movement of the vehicle on the route.
  -- @param #CONTROLLABLE self
  -- @return #CONTROLLABLE
  function CONTROLLABLE:RouteStop()
    self:F("RouteStop")
    
    local CommandStop = self:CommandStopRoute( true )
    self:SetCommand( CommandStop )
  
  end
  
  --- Resumes the movement of the vehicle on the route.
  -- @param #CONTROLLABLE self
  -- @return #CONTROLLABLE
  function CONTROLLABLE:RouteResume()
    self:F("RouteResume")
    
    local CommandResume = self:CommandStopRoute( false )
    self:SetCommand( CommandResume )
  
  end
  
  --- Make the GROUND Controllable to drive towards a specific point.
  -- @param #CONTROLLABLE self
  -- @param Core.Point#COORDINATE ToCoordinate A Coordinate to drive to.
  -- @param #number Speed (optional) Speed in km/h. The default speed is 20 km/h.
  -- @param #string Formation (optional) The route point Formation, which is a text string that specifies exactly the Text in the Type of the route point, like "Vee", "Echelon Right".
  -- @param #number DelaySeconds Wait for the specified seconds before executing the Route.
  -- @return #CONTROLLABLE The CONTROLLABLE.
  function CONTROLLABLE:RouteGroundTo( ToCoordinate, Speed, Formation, DelaySeconds )
  
    local FromCoordinate = self:GetCoordinate()
    
    local FromWP = FromCoordinate:WaypointGround()
    local ToWP = ToCoordinate:WaypointGround( Speed, Formation )
  
    self:Route( { FromWP, ToWP }, DelaySeconds )
  
    return self
  end
  
  --- Make the GROUND Controllable to drive towards a specific point using (mostly) roads.
  -- @param #CONTROLLABLE self
  -- @param Core.Point#COORDINATE ToCoordinate A Coordinate to drive to.
  -- @param #number Speed (Optional) Speed in km/h. The default speed is 20 km/h.
  -- @param #number DelaySeconds (Optional) Wait for the specified seconds before executing the Route. Default is one second.
  -- @param #string OffRoadFormation (Optional) The formation at initial and final waypoint. Default is "Off Road".
  -- @return #CONTROLLABLE The CONTROLLABLE.
  function CONTROLLABLE:RouteGroundOnRoad( ToCoordinate, Speed, DelaySeconds, OffRoadFormation )
  
    -- Defaults.
    Speed=Speed or 20
    DelaySeconds=DelaySeconds or 1
    OffRoadFormation=OffRoadFormation or "Off Road"
  
    -- Get the route task.
    local route=self:TaskGroundOnRoad(ToCoordinate, Speed, OffRoadFormation)
    
    -- Route controllable to destination.
    self:Route( route, DelaySeconds )
  
    return self
  end

  
  --- Make a task for a GROUND Controllable to drive towards a specific point using (mostly) roads.
  -- @param #CONTROLLABLE self
  -- @param Core.Point#COORDINATE ToCoordinate A Coordinate to drive to.
  -- @param #number Speed (Optional) Speed in km/h. The default speed is 20 km/h.
  -- @param #string OffRoadFormation (Optional) The formation at initial and final waypoint. Default is "Off Road".
  -- @return Task
  function CONTROLLABLE:TaskGroundOnRoad( ToCoordinate, Speed, OffRoadFormation )
    self:F2({ToCoordinate=ToCoordinate, Speed=Speed, OffRoadFormation=OffRoadFormation})
    
    -- Defaults.
    Speed=Speed or 20
    OffRoadFormation=OffRoadFormation or "Off Road"
  
    -- Current coordinate.
    local FromCoordinate = self:GetCoordinate()
    
    -- First point on road.
    local FromOnRoad = FromCoordinate:GetClosestPointToRoad()
    
    -- Last Point on road.
    local ToOnRoad = ToCoordinate:GetClosestPointToRoad()
           
    -- Route, ground waypoints along road.
    local route={}
    
    -- Create waypoints.
    table.insert(route, FromCoordinate:WaypointGround(Speed, OffRoadFormation))
    table.insert(route, FromOnRoad:WaypointGround(Speed, "On Road"))
    table.insert(route, ToOnRoad:WaypointGround(Speed, "On Road"))
        
    -- Add the final coordinate because the final might not be on the road.
    local dist=ToCoordinate:Get2DDistance(ToOnRoad)
    if dist>10 then
      table.insert(route, ToCoordinate:WaypointGround(Speed, OffRoadFormation))
    end  
    
    return route 
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
  -- @param Base#FORMATION Formation The formation string.
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
  -- @param Base#FORMATION Formation The formation string.
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

  return routines.utils.deepCopy( _DATABASE.Templates.Controllables[self.ControllableName].Template )
end

--- Return the mission route of the controllable.
-- @param #CONTROLLABLE self
-- @return #table The mission route defined by points.
function CONTROLLABLE:GetTaskRoute()
  self:F2( self.ControllableName )

  return routines.utils.deepCopy( _DATABASE.Templates.Controllables[self.ControllableName].Template.route.points )
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
        Points[#Points+1] = routines.utils.deepCopy( Template.route.points[TPointID] )
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
-- The optional parametes specify the detection methods that can be applied.
-- If no detection method is given, the detection will use all the available methods by default.
-- @param Wrapper.Controllable#CONTROLLABLE self
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
    local DetectionVisual = ( DetectVisual and DetectVisual == true ) and Controller.Detection.VISUAL or nil
    local DetectionOptical = ( DetectOptical and DetectOptical == true ) and Controller.Detection.OPTICAL or nil
    local DetectionRadar = ( DetectRadar and DetectRadar == true ) and Controller.Detection.RADAR or nil
    local DetectionIRST = ( DetectIRST and DetectIRST == true ) and Controller.Detection.IRST or nil
    local DetectionRWR = ( DetectRWR and DetectRWR == true ) and Controller.Detection.RWR or nil
    local DetectionDLINK = ( DetectDLINK and DetectDLINK == true ) and Controller.Detection.DLINK or nil
    
    self:T2( { DetectionVisual, DetectionOptical, DetectionRadar, DetectionIRST, DetectionRWR, DetectionDLINK } )
    
    return self:_GetController():getDetectedTargets( DetectionVisual, DetectionOptical, DetectionRadar, DetectionIRST, DetectionRWR, DetectionDLINK )
  end

  return nil
end

function CONTROLLABLE:IsTargetDetected( DCSObject, DetectVisual, DetectOptical, DetectRadar, DetectIRST, DetectRWR, DetectDLINK )
  self:F2( self.ControllableName )

  local DCSControllable = self:GetDCSObject()
  
  if DCSControllable then

    local DetectionVisual = ( DetectVisual and DetectVisual == true ) and Controller.Detection.VISUAL or nil
    local DetectionOptical = ( DetectOptical and DetectOptical == true ) and Controller.Detection.OPTICAL or nil
    local DetectionRadar = ( DetectRadar and DetectRadar == true ) and Controller.Detection.RADAR or nil
    local DetectionIRST = ( DetectIRST and DetectIRST == true ) and Controller.Detection.IRST or nil
    local DetectionRWR = ( DetectRWR and DetectRWR == true ) and Controller.Detection.RWR or nil
    local DetectionDLINK = ( DetectDLINK and DetectDLINK == true ) and Controller.Detection.DLINK or nil

    local Controller = self:_GetController()

    local TargetIsDetected, TargetIsVisible, TargetLastTime, TargetKnowType, TargetKnowDistance, TargetLastPos, TargetLastVelocity
      = Controller:isTargetDetected( DCSObject, DetectionVisual, DetectionOptical, DetectionRadar, DetectionIRST, DetectionRWR, DetectionDLINK )
      
    return TargetIsDetected, TargetIsVisible, TargetLastTime, TargetKnowType, TargetKnowDistance, TargetLastPos, TargetLastVelocity
  end

  return nil
end

-- Options

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

--- Holding weapons.
-- @param Wrapper.Controllable#CONTROLLABLE self
-- @return Wrapper.Controllable#CONTROLLABLE self
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

--- Return fire.
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

--- Openfire.
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
      Controller:setOption(AI.Option.Ground.id.ALARM_STATE, AI.Option.Ground.val.ALARM_STATE.AUTO)
    elseif self:IsShip() then 
      Controller:setOption(AI.Option.Naval.id.ALARM_STATE, AI.Option.Naval.val.ALARM_STATE.AUTO)
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
      --Controller:setOption( AI.Option.Naval.id.ALARM_STATE, AI.Option.Naval.val.ALARM_STATE.GREEN )
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
      Controller:setOption(AI.Option.Ground.id.ALARM_STATE, AI.Option.Ground.val.ALARM_STATE.RED)
    elseif self:IsShip() then 
      Controller:setOption(AI.Option.Naval.id.ALARM_STATE, AI.Option.Naval.val.ALARM_STATE.RED)
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
function CONTROLLABLE:OptionRTBBingoFuel( RTB ) --R2.2
  self:F2( { self.ControllableName } )

  RTB = RTB or true

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
      Controller:setOption( AI.Option.GROUND.id.RTB_ON_OUT_OF_AMMO, WeaponsFlag )
    end

    return self
  end

  return nil
end





--- Retrieve the controllable mission and allow to place function hooks within the mission waypoint plan.
-- Use the method @{Wrapper.Controllable#CONTROLLABLE:WayPointFunction} to define the hook functions for specific waypoints.
-- Use the method @{Controllable@CONTROLLABLE:WayPointExecute) to start the execution of the new mission plan.
-- Note that when WayPointInitialize is called, the Mission of the controllable is RESTARTED!
-- @param #CONTROLLABLE self
-- @param #table WayPoints If WayPoints is given, then use the route.
-- @return #CONTROLLABLE
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
  self:F( )

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
-- @return #CONTROLLABLE
function CONTROLLABLE:WayPointFunction( WayPoint, WayPointIndex, WayPointFunction, ... )
  self:F2( { WayPoint, WayPointIndex, WayPointFunction } )

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
-- @return #CONTROLLABLE
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



-- Message APIs