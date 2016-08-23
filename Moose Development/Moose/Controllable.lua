--- This module contains the CONTROLLABLE class.
-- 
-- 1) @{Controllable#CONTROLLABLE} class, extends @{Positionable#POSITIONABLE}
-- ===========================================================
-- The @{Controllable#CONTROLLABLE} class is a wrapper class to handle the DCS Controllable objects:
--
--  * Support all DCS Controllable APIs.
--  * Enhance with Controllable specific APIs not in the DCS Controllable API set.
--  * Handle local Controllable Controller.
--  * Manage the "state" of the DCS Controllable.
--
-- 1.1) CONTROLLABLE constructor
-- -----------------------------
-- The CONTROLLABLE class provides the following functions to construct a CONTROLLABLE instance:
--
--  * @{#CONTROLLABLE.New}(): Create a CONTROLLABLE instance.
--
-- 1.2) CONTROLLABLE task methods
-- ------------------------------
-- Several controllable task methods are available that help you to prepare tasks. 
-- These methods return a string consisting of the task description, which can then be given to either a @{Controllable#CONTROLLABLE.PushTask} or @{Controllable#SetTask} method to assign the task to the CONTROLLABLE.
-- Tasks are specific for the category of the CONTROLLABLE, more specific, for AIR, GROUND or AIR and GROUND. 
-- Each task description where applicable indicates for which controllable category the task is valid.
-- There are 2 main subdivisions of tasks: Assigned tasks and EnRoute tasks.
-- 
-- ### 1.2.1) Assigned task methods
-- 
-- Assigned task methods make the controllable execute the task where the location of the (possible) targets of the task are known before being detected.
-- This is different from the EnRoute tasks, where the targets of the task need to be detected before the task can be executed.
-- 
-- Find below a list of the **assigned task** methods:
-- 
--   * @{#CONTROLLABLE.TaskAttackControllable}: (AIR) Attack a Controllable.
--   * @{#CONTROLLABLE.TaskAttackMapObject}: (AIR) Attacking the map object (building, structure, e.t.c).
--   * @{#CONTROLLABLE.TaskAttackUnit}: (AIR) Attack the Unit.
--   * @{#CONTROLLABLE.TaskBombing}: (AIR) Delivering weapon at the point on the ground.
--   * @{#CONTROLLABLE.TaskBombingRunway}: (AIR) Delivering weapon on the runway.
--   * @{#CONTROLLABLE.TaskEmbarking}: (AIR) Move the controllable to a Vec2 Point, wait for a defined duration and embark a controllable.
--   * @{#CONTROLLABLE.TaskEmbarkToTransport}: (GROUND) Embark to a Transport landed at a location.
--   * @{#CONTROLLABLE.TaskEscort}: (AIR) Escort another airborne controllable. 
--   * @{#CONTROLLABLE.TaskFAC_AttackControllable}: (AIR + GROUND) The task makes the controllable/unit a FAC and orders the FAC to control the target (enemy ground controllable) destruction.
--   * @{#CONTROLLABLE.TaskFireAtPoint}: (GROUND) Fire at a VEC2 point until ammunition is finished.
--   * @{#CONTROLLABLE.TaskFollow}: (AIR) Following another airborne controllable.
--   * @{#CONTROLLABLE.TaskHold}: (GROUND) Hold ground controllable from moving.
--   * @{#CONTROLLABLE.TaskHoldPosition}: (AIR) Hold position at the current position of the first unit of the controllable.
--   * @{#CONTROLLABLE.TaskLand}: (AIR HELICOPTER) Landing at the ground. For helicopters only.
--   * @{#CONTROLLABLE.TaskLandAtZone}: (AIR) Land the controllable at a @{Zone#ZONE_RADIUS).
--   * @{#CONTROLLABLE.TaskOrbitCircle}: (AIR) Orbit at the current position of the first unit of the controllable at a specified alititude.
--   * @{#CONTROLLABLE.TaskOrbitCircleAtVec2}: (AIR) Orbit at a specified position at a specified alititude during a specified duration with a specified speed.
--   * @{#CONTROLLABLE.TaskRefueling}: (AIR) Refueling from the nearest tanker. No parameters.
--   * @{#CONTROLLABLE.TaskRoute}: (AIR + GROUND) Return a Misson task to follow a given route defined by Points.
--   * @{#CONTROLLABLE.TaskRouteToVec2}: (AIR + GROUND) Make the Controllable move to a given point.
--   * @{#CONTROLLABLE.TaskRouteToVec3}: (AIR + GROUND) Make the Controllable move to a given point.
--   * @{#CONTROLLABLE.TaskRouteToZone}: (AIR + GROUND) Route the controllable to a given zone.
--   * @{#CONTROLLABLE.TaskReturnToBase}: (AIR) Route the controllable to an airbase.
--
-- ### 1.2.2) EnRoute task methods
-- 
-- EnRoute tasks require the targets of the task need to be detected by the controllable (using its sensors) before the task can be executed:
-- 
--   * @{#CONTROLLABLE.EnRouteTaskAWACS}: (AIR) Aircraft will act as an AWACS for friendly units (will provide them with information about contacts). No parameters.
--   * @{#CONTROLLABLE.EnRouteTaskEngageControllable}: (AIR) Engaging a controllable. The task does not assign the target controllable to the unit/controllable to attack now; it just allows the unit/controllable to engage the target controllable as well as other assigned targets.
--   * @{#CONTROLLABLE.EnRouteTaskEngageTargets}: (AIR) Engaging targets of defined types.
--   * @{#CONTROLLABLE.EnRouteTaskEWR}: (AIR) Attack the Unit.
--   * @{#CONTROLLABLE.EnRouteTaskFAC}: (AIR + GROUND) The task makes the controllable/unit a FAC and lets the FAC to choose a targets (enemy ground controllable) around as well as other assigned targets.
--   * @{#CONTROLLABLE.EnRouteTaskFAC_EngageControllable}: (AIR + GROUND) The task makes the controllable/unit a FAC and lets the FAC to choose the target (enemy ground controllable) as well as other assigned targets.
--   * @{#CONTROLLABLE.EnRouteTaskTanker}: (AIR) Aircraft will act as a tanker for friendly units. No parameters.
-- 
-- ### 1.2.3) Preparation task methods
-- 
-- There are certain task methods that allow to tailor the task behaviour:
--
--   * @{#CONTROLLABLE.TaskWrappedAction}: Return a WrappedAction Task taking a Command.
--   * @{#CONTROLLABLE.TaskCombo}: Return a Combo Task taking an array of Tasks.
--   * @{#CONTROLLABLE.TaskCondition}: Return a condition section for a controlled task.
--   * @{#CONTROLLABLE.TaskControlled}: Return a Controlled Task taking a Task and a TaskCondition.
-- 
-- ### 1.2.4) Obtain the mission from controllable templates
-- 
-- Controllable templates contain complete mission descriptions. Sometimes you want to copy a complete mission from a controllable and assign it to another:
-- 
--   * @{#CONTROLLABLE.TaskMission}: (AIR + GROUND) Return a mission task from a mission template.
--
-- 1.3) CONTROLLABLE Command methods
-- --------------------------
-- Controllable **command methods** prepare the execution of commands using the @{#CONTROLLABLE.SetCommand} method:
-- 
--   * @{#CONTROLLABLE.CommandDoScript}: Do Script command.
--   * @{#CONTROLLABLE.CommandSwitchWayPoint}: Perform a switch waypoint command.
-- 
-- 1.4) CONTROLLABLE Option methods
-- -------------------------
-- Controllable **Option methods** change the behaviour of the Controllable while being alive.
-- 
-- ### 1.4.1) Rule of Engagement:
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
-- ### 1.4.2) Rule on thread:
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
-- ===
-- 
-- @module Controllable
-- @author FlightControl

--- The CONTROLLABLE class
-- @type CONTROLLABLE
-- @extends Positionable#POSITIONABLE
-- @field DCSControllable#Controllable DCSControllable The DCS controllable class.
-- @field #string ControllableName The name of the controllable.
CONTROLLABLE = {
  ClassName = "CONTROLLABLE",
  ControllableName = "",
  WayPointFunctions = {},
}

--- Create a new CONTROLLABLE from a DCSControllable
-- @param #CONTROLLABLE self
-- @param DCSControllable#Controllable ControllableName The DCS Controllable name
-- @return #CONTROLLABLE self
function CONTROLLABLE:New( ControllableName )
  local self = BASE:Inherit( self, POSITIONABLE:New( ControllableName ) )
  self:F2( ControllableName )
  self.ControllableName = ControllableName
  return self
end

-- DCS Controllable methods support.

--- Get the controller for the CONTROLLABLE.
-- @param #CONTROLLABLE self
-- @return DCSController#Controller
function CONTROLLABLE:_GetController()
  self:F2( { self.ControllableName } )
  local DCSControllable = self:GetDCSObject()

  if DCSControllable then
    local ControllableController = DCSControllable:getController()
    self:T3( ControllableController )
    return ControllableController
  end

  return nil
end



-- Tasks

--- Popping current Task from the controllable.
-- @param #CONTROLLABLE self
-- @return Controllable#CONTROLLABLE self
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
-- @return Controllable#CONTROLLABLE self
function CONTROLLABLE:PushTask( DCSTask, WaitTime )
  self:F2()

  local DCSControllable = self:GetDCSObject()

  if DCSControllable then
    local Controller = self:_GetController()

    -- When a controllable SPAWNs, it takes about a second to get the controllable in the simulator. Setting tasks to unspawned controllables provides unexpected results.
    -- Therefore we schedule the functions to set the mission and options for the Controllable.
    -- Controller:pushTask( DCSTask )

    if WaitTime then
      SCHEDULER:New( Controller, Controller.pushTask, { DCSTask }, WaitTime )
    else
      Controller:pushTask( DCSTask )
    end

    return self
  end

  return nil
end

--- Clearing the Task Queue and Setting the Task on the queue from the controllable.
-- @param #CONTROLLABLE self
-- @return Controllable#CONTROLLABLE self
function CONTROLLABLE:SetTask( DCSTask, WaitTime )
  self:F2( { DCSTask } )

  local DCSControllable = self:GetDCSObject()

  if DCSControllable then

    local Controller = self:_GetController()

    -- When a controllable SPAWNs, it takes about a second to get the controllable in the simulator. Setting tasks to unspawned controllables provides unexpected results.
    -- Therefore we schedule the functions to set the mission and options for the Controllable.
    -- Controller.setTask( Controller, DCSTask )

    if not WaitTime then
      Controller:setTask( DCSTask )
    else
      SCHEDULER:New( Controller, Controller.setTask, { DCSTask }, WaitTime )
    end

    return self
  end

  return nil
end


--- Return a condition section for a controlled task.
-- @param #CONTROLLABLE self
-- @param DCSTime#Time time
-- @param #string userFlag
-- @param #boolean userFlagValue
-- @param #string condition
-- @param DCSTime#Time duration
-- @param #number lastWayPoint
-- return DCSTask#Task
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
-- @param DCSTask#Task DCSTask
-- @param #DCSStopCondition DCSStopCondition
-- @return DCSTask#Task
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
-- @param DCSTask#TaskArray DCSTasks Array of @{DCSTask#Task}
-- @return DCSTask#Task
function CONTROLLABLE:TaskCombo( DCSTasks )
  self:F2( { DCSTasks } )

  local DCSTaskCombo

  DCSTaskCombo = {
    id = 'ComboTask',
    params = {
      tasks = DCSTasks
    }
  }

  self:T3( { DCSTaskCombo } )
  return DCSTaskCombo
end

--- Return a WrappedAction Task taking a Command.
-- @param #CONTROLLABLE self
-- @param DCSCommand#Command DCSCommand
-- @return DCSTask#Task
function CONTROLLABLE:TaskWrappedAction( DCSCommand, Index )
  self:F2( { DCSCommand } )

  local DCSTaskWrappedAction

  DCSTaskWrappedAction = {
    id = "WrappedAction",
    enabled = true,
    number = Index,
    auto = false,
    params = {
      action = DCSCommand,
    },
  }

  self:T3( { DCSTaskWrappedAction } )
  return DCSTaskWrappedAction
end

--- Executes a command action
-- @param #CONTROLLABLE self
-- @param DCSCommand#Command DCSCommand
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
-- @return DCSTask#Task
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

--- Perform stop route command
-- @param #CONTROLLABLE self
-- @param #boolean StopRoute
-- @return DCSTask#Task
function CONTROLLABLE:CommandStopRoute( StopRoute, Index )
  self:F2( { StopRoute, Index } )

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
-- @param Controllable#CONTROLLABLE AttackGroup The Controllable to be attacked.
-- @param #number WeaponType (optional) Bitmask of weapon types those allowed to use. If parameter is not defined that means no limits on weapon usage.
-- @param DCSTypes#AI.Task.WeaponExpend WeaponExpend (optional) Determines how much weapon will be released at each attack. If parameter is not defined the unit / controllable will choose expend on its own discretion.
-- @param #number AttackQty (optional) This parameter limits maximal quantity of attack. The aicraft/controllable will not make more attack than allowed even if the target controllable not destroyed and the aicraft/controllable still have ammo. If not defined the aircraft/controllable will attack target until it will be destroyed or until the aircraft/controllable will run out of ammo.
-- @param DCSTypes#Azimuth Direction (optional) Desired ingress direction from the target to the attacking aircraft. Controllable/aircraft will make its attacks from the direction. Of course if there is no way to attack from the direction due the terrain controllable/aircraft will choose another direction.
-- @param DCSTypes#Distance Altitude (optional) Desired attack start altitude. Controllable/aircraft will make its attacks from the altitude. If the altitude is too low or too high to use weapon aircraft/controllable will choose closest altitude to the desired attack start altitude. If the desired altitude is defined controllable/aircraft will not attack from safe altitude.
-- @param #boolean AttackQtyLimit (optional) The flag determines how to interpret attackQty parameter. If the flag is true then attackQty is a limit on maximal attack quantity for "AttackControllable" and "AttackUnit" tasks. If the flag is false then attackQty is a desired attack quantity for "Bombing" and "BombingRunway" tasks.
-- @return DCSTask#Task The DCS task structure.
function CONTROLLABLE:TaskAttackGroup( AttackGroup, WeaponType, WeaponExpend, AttackQty, Direction, Altitude, AttackQtyLimit )
  self:F2( { self.ControllableName, AttackGroup, WeaponType, WeaponExpend, AttackQty, Direction, Altitude, AttackQtyLimit } )

  --  AttackControllable = {
  --   id = 'AttackControllable',
  --   params = {
  --     controllableId = Controllable.ID,
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
  DCSTask = { id = 'AttackControllable',
    params = {
      controllableId = AttackGroup:GetID(),
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
-- @param Unit#UNIT AttackUnit The unit.
-- @param #number WeaponType (optional) Bitmask of weapon types those allowed to use. If parameter is not defined that means no limits on weapon usage.
-- @param DCSTypes#AI.Task.WeaponExpend WeaponExpend (optional) Determines how much weapon will be released at each attack. If parameter is not defined the unit / controllable will choose expend on its own discretion.
-- @param #number AttackQty (optional) This parameter limits maximal quantity of attack. The aicraft/controllable will not make more attack than allowed even if the target controllable not destroyed and the aicraft/controllable still have ammo. If not defined the aircraft/controllable will attack target until it will be destroyed or until the aircraft/controllable will run out of ammo.
-- @param DCSTypes#Azimuth Direction (optional) Desired ingress direction from the target to the attacking aircraft. Controllable/aircraft will make its attacks from the direction. Of course if there is no way to attack from the direction due the terrain controllable/aircraft will choose another direction.
-- @param #boolean AttackQtyLimit (optional) The flag determines how to interpret attackQty parameter. If the flag is true then attackQty is a limit on maximal attack quantity for "AttackControllable" and "AttackUnit" tasks. If the flag is false then attackQty is a desired attack quantity for "Bombing" and "BombingRunway" tasks.
-- @param #boolean ControllableAttack (optional) Flag indicates that the target must be engaged by all aircrafts of the controllable. Has effect only if the task is assigned to a controllable, not to a single aircraft.
-- @return DCSTask#Task The DCS task structure.
function CONTROLLABLE:TaskAttackUnit( AttackUnit, WeaponType, WeaponExpend, AttackQty, Direction, AttackQtyLimit, ControllableAttack )
  self:F2( { self.ControllableName, AttackUnit, WeaponType, WeaponExpend, AttackQty, Direction, AttackQtyLimit, ControllableAttack } )

  --  AttackUnit = {
  --    id = 'AttackUnit',
  --    params = {
  --      unitId = Unit.ID,
  --      weaponType = number,
  --      expend = enum AI.Task.WeaponExpend
  --      attackQty = number,
  --      direction = Azimuth,
  --      attackQtyLimit = boolean,
  --      controllableAttack = boolean,
  --    }
  --  }

  local DCSTask
  DCSTask = { id = 'AttackUnit',
    params = {
      unitId = AttackUnit:GetID(),
      weaponType = WeaponType,
      expend = WeaponExpend,
      attackQty = AttackQty,
      direction = Direction,
      attackQtyLimit = AttackQtyLimit,
      controllableAttack = ControllableAttack,
    },
  },

  self:T3( { DCSTask } )
  return DCSTask
end


--- (AIR) Delivering weapon at the point on the ground. 
-- @param #CONTROLLABLE self
-- @param DCSTypes#Vec2 Vec2 2D-coordinates of the point to deliver weapon at.
-- @param #number WeaponType (optional) Bitmask of weapon types those allowed to use. If parameter is not defined that means no limits on weapon usage.
-- @param DCSTypes#AI.Task.WeaponExpend WeaponExpend (optional) Determines how much weapon will be released at each attack. If parameter is not defined the unit / controllable will choose expend on its own discretion.
-- @param #number AttackQty (optional) Desired quantity of passes. The parameter is not the same in AttackControllable and AttackUnit tasks. 
-- @param DCSTypes#Azimuth Direction (optional) Desired ingress direction from the target to the attacking aircraft. Controllable/aircraft will make its attacks from the direction. Of course if there is no way to attack from the direction due the terrain controllable/aircraft will choose another direction.
-- @param #boolean ControllableAttack (optional) Flag indicates that the target must be engaged by all aircrafts of the controllable. Has effect only if the task is assigned to a controllable, not to a single aircraft.
-- @return DCSTask#Task The DCS task structure.
function CONTROLLABLE:TaskBombing( Vec2, WeaponType, WeaponExpend, AttackQty, Direction, ControllableAttack )
  self:F2( { self.ControllableName, Vec2, WeaponType, WeaponExpend, AttackQty, Direction, ControllableAttack } )

--  Bombing = { 
--    id = 'Bombing', 
--    params = { 
--      point = Vec2,
--      weaponType = number, 
--      expend = enum AI.Task.WeaponExpend,
--      attackQty = number, 
--      direction = Azimuth, 
--      controllableAttack = boolean, 
--    } 
--  } 

  local DCSTask
  DCSTask = { id = 'Bombing',
    params = {
    point = Vec2,
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

--- (AIR) Orbit at a specified position at a specified alititude during a specified duration with a specified speed.
-- @param #CONTROLLABLE self
-- @param DCSTypes#Vec2 Point The point to hold the position.
-- @param #number Altitude The altitude to hold the position.
-- @param #number Speed The speed flying when holding the position.
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
-- @param #number Altitude The altitude to hold the position.
-- @param #number Speed The speed flying when holding the position.
-- @return #CONTROLLABLE self
function CONTROLLABLE:TaskOrbitCircle( Altitude, Speed )
  self:F2( { self.ControllableName, Altitude, Speed } )

  local DCSControllable = self:GetDCSObject()

  if DCSControllable then
    local ControllablePoint = self:GetVec2()
    return self:TaskOrbitCircleAtVec2( ControllablePoint, Altitude, Speed )
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




--- (AIR) Attacking the map object (building, structure, e.t.c).
-- @param #CONTROLLABLE self
-- @param DCSTypes#Vec2 Vec2 2D-coordinates of the point the map object is closest to. The distance between the point and the map object must not be greater than 2000 meters. Object id is not used here because Mission Editor doesn't support map object identificators.
-- @param #number WeaponType (optional) Bitmask of weapon types those allowed to use. If parameter is not defined that means no limits on weapon usage.
-- @param DCSTypes#AI.Task.WeaponExpend WeaponExpend (optional) Determines how much weapon will be released at each attack. If parameter is not defined the unit / controllable will choose expend on its own discretion.
-- @param #number AttackQty (optional) This parameter limits maximal quantity of attack. The aicraft/controllable will not make more attack than allowed even if the target controllable not destroyed and the aicraft/controllable still have ammo. If not defined the aircraft/controllable will attack target until it will be destroyed or until the aircraft/controllable will run out of ammo.
-- @param DCSTypes#Azimuth Direction (optional) Desired ingress direction from the target to the attacking aircraft. Controllable/aircraft will make its attacks from the direction. Of course if there is no way to attack from the direction due the terrain controllable/aircraft will choose another direction.
-- @param #boolean ControllableAttack (optional) Flag indicates that the target must be engaged by all aircrafts of the controllable. Has effect only if the task is assigned to a controllable, not to a single aircraft.
-- @return DCSTask#Task The DCS task structure.
function CONTROLLABLE:TaskAttackMapObject( Vec2, WeaponType, WeaponExpend, AttackQty, Direction, ControllableAttack )
  self:F2( { self.ControllableName, Vec2, WeaponType, WeaponExpend, AttackQty, Direction, ControllableAttack } )

--  AttackMapObject = { 
--    id = 'AttackMapObject', 
--    params = { 
--      point = Vec2,
--      weaponType = number, 
--      expend = enum AI.Task.WeaponExpend,
--      attackQty = number, 
--      direction = Azimuth, 
--      controllableAttack = boolean, 
--    } 
--  } 

  local DCSTask
  DCSTask = { id = 'AttackMapObject',
    params = {
    point = Vec2,
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


--- (AIR) Delivering weapon on the runway.
-- @param #CONTROLLABLE self
-- @param Airbase#AIRBASE Airbase Airbase to attack.
-- @param #number WeaponType (optional) Bitmask of weapon types those allowed to use. If parameter is not defined that means no limits on weapon usage.
-- @param DCSTypes#AI.Task.WeaponExpend WeaponExpend (optional) Determines how much weapon will be released at each attack. If parameter is not defined the unit / controllable will choose expend on its own discretion.
-- @param #number AttackQty (optional) This parameter limits maximal quantity of attack. The aicraft/controllable will not make more attack than allowed even if the target controllable not destroyed and the aicraft/controllable still have ammo. If not defined the aircraft/controllable will attack target until it will be destroyed or until the aircraft/controllable will run out of ammo.
-- @param DCSTypes#Azimuth Direction (optional) Desired ingress direction from the target to the attacking aircraft. Controllable/aircraft will make its attacks from the direction. Of course if there is no way to attack from the direction due the terrain controllable/aircraft will choose another direction.
-- @param #boolean ControllableAttack (optional) Flag indicates that the target must be engaged by all aircrafts of the controllable. Has effect only if the task is assigned to a controllable, not to a single aircraft.
-- @return DCSTask#Task The DCS task structure.
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
-- @return DCSTask#Task The DCS task structure.
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
-- @param DCSTypes#Vec2 Point The point where to land.
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

--- (AIR) Land the controllable at a @{Zone#ZONE_RADIUS).
-- @param #CONTROLLABLE self
-- @param Zone#ZONE Zone The zone where to land.
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
-- @param Controllable#CONTROLLABLE FollowControllable The controllable to be followed.
-- @param DCSTypes#Vec3 Vec3 Position of the unit / lead unit of the controllable relative lead unit of another controllable in frame reference oriented by course of lead unit of another controllable. If another controllable is on land the unit / controllable will orbit around.
-- @param #number LastWaypointIndex Detach waypoint of another controllable. Once reached the unit / controllable Follow task is finished.
-- @return DCSTask#Task The DCS task structure.
function CONTROLLABLE:TaskFollow( FollowControllable, Vec3, LastWaypointIndex )
  self:F2( { self.ControllableName, FollowControllable, Vec3, LastWaypointIndex } )

--  Follow = {
--    id = 'Follow',
--    params = {
--      controllableId = Controllable.ID,
--      pos = Vec3,
--      lastWptIndexFlag = boolean,
--      lastWptIndex = number
--    }    
--  }

  local LastWaypointIndexFlag = nil
  if LastWaypointIndex then
    LastWaypointIndexFlag = true
  end
  
  local DCSTask
  DCSTask = { id = 'Follow',
    params = {
      controllableId = FollowControllable:GetID(),
      pos = Vec3,
      lastWptIndexFlag = LastWaypointIndexFlag,
      lastWptIndex = LastWaypointIndex,
    },
  },

  self:T3( { DCSTask } )
  return DCSTask
end


--- (AIR) Escort another airborne controllable. 
-- The unit / controllable will follow lead unit of another controllable, wingmens of both controllables will continue following their leaders. 
-- The unit / controllable will also protect that controllable from threats of specified types.
-- @param #CONTROLLABLE self
-- @param Controllable#CONTROLLABLE EscortControllable The controllable to be escorted.
-- @param DCSTypes#Vec3 Vec3 Position of the unit / lead unit of the controllable relative lead unit of another controllable in frame reference oriented by course of lead unit of another controllable. If another controllable is on land the unit / controllable will orbit around.
-- @param #number LastWaypointIndex Detach waypoint of another controllable. Once reached the unit / controllable Follow task is finished.
-- @param #number EngagementDistanceMax Maximal distance from escorted controllable to threat. If the threat is already engaged by escort escort will disengage if the distance becomes greater than 1.5 * engagementDistMax. 
-- @param DCSTypes#AttributeNameArray TargetTypes Array of AttributeName that is contains threat categories allowed to engage. 
-- @return DCSTask#Task The DCS task structure.
function CONTROLLABLE:TaskEscort( FollowControllable, Vec3, LastWaypointIndex, EngagementDistance, TargetTypes )
  self:F2( { self.ControllableName, FollowControllable, Vec3, LastWaypointIndex, EngagementDistance, TargetTypes } )

--  Escort = {
--    id = 'Escort',
--    params = {
--      controllableId = Controllable.ID,
--      pos = Vec3,
--      lastWptIndexFlag = boolean,
--      lastWptIndex = number,
--      engagementDistMax = Distance,
--      targetTypes = array of AttributeName,
--    }    
--  }

  local LastWaypointIndexFlag = nil
  if LastWaypointIndex then
    LastWaypointIndexFlag = true
  end
  
  local DCSTask
  DCSTask = { id = 'Follow',
    params = {
      controllableId = FollowControllable:GetID(),
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
-- @param DCSTypes#Vec2 Vec2 The point to fire at.
-- @param DCSTypes#Distance Radius The radius of the zone to deploy the fire at.
-- @return DCSTask#Task The DCS task structure.
function CONTROLLABLE:TaskFireAtPoint( Vec2, Radius )
  self:F2( { self.ControllableName, Vec2, Radius } )

  -- FireAtPoint = {
  --   id = 'FireAtPoint',
  --   params = {
  --     point = Vec2,
  --     radius = Distance,
  --   }
  -- }

  local DCSTask
  DCSTask = { id = 'FireAtPoint',
    params = {
      point = Vec2,
      radius = Radius,
    }
  }

  self:T3( { DCSTask } )
  return DCSTask
end

--- (GROUND) Hold ground controllable from moving.
-- @param #CONTROLLABLE self
-- @return DCSTask#Task The DCS task structure.
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
-- @param Controllable#CONTROLLABLE AttackGroup Target CONTROLLABLE.
-- @param #number WeaponType Bitmask of weapon types those allowed to use. If parameter is not defined that means no limits on weapon usage. 
-- @param DCSTypes#AI.Task.Designation Designation (optional) Designation type.
-- @param #boolean Datalink (optional) Allows to use datalink to send the target information to attack aircraft. Enabled by default. 
-- @return DCSTask#Task The DCS task structure.
function CONTROLLABLE:TaskFAC_AttackGroup( AttackGroup, WeaponType, Designation, Datalink )
  self:F2( { self.ControllableName, AttackGroup, WeaponType, Designation, Datalink } )

--  FAC_AttackControllable = { 
--    id = 'FAC_AttackControllable', 
--    params = { 
--      controllableId = Controllable.ID,
--      weaponType = number,
--      designation = enum AI.Task.Designation,
--      datalink = boolean
--    } 
--  }

  local DCSTask
  DCSTask = { id = 'FAC_AttackControllable',
    params = {
      controllableId = AttackGroup:GetID(),
      weaponType = WeaponType,
      designation = Designation,
      datalink = Datalink,
    }
  }

  self:T3( { DCSTask } )
  return DCSTask
end

-- EN-ROUTE TASKS FOR AIRBORNE CONTROLLABLES

--- (AIR) Engaging targets of defined types.
-- @param #CONTROLLABLE self
-- @param DCSTypes#Distance Distance Maximal distance from the target to a route leg. If the target is on a greater distance it will be ignored. 
-- @param DCSTypes#AttributeNameArray TargetTypes Array of target categories allowed to engage. 
-- @param #number Priority All enroute tasks have the priority parameter. This is a number (less value - higher priority) that determines actions related to what task will be performed first. 
-- @return DCSTask#Task The DCS task structure.
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
-- @param DCSTypes#Vec2 Vec2 2D-coordinates of the zone. 
-- @param DCSTypes#Distance Radius Radius of the zone. 
-- @param DCSTypes#AttributeNameArray TargetTypes Array of target categories allowed to engage. 
-- @param #number Priority All en-route tasks have the priority parameter. This is a number (less value - higher priority) that determines actions related to what task will be performed first. 
-- @return DCSTask#Task The DCS task structure.
function CONTROLLABLE:EnRouteTaskEngageTargets( Vec2, Radius, TargetTypes, Priority )
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
-- @param Controllable#CONTROLLABLE AttackGroup The Controllable to be attacked.
-- @param #number Priority All en-route tasks have the priority parameter. This is a number (less value - higher priority) that determines actions related to what task will be performed first. 
-- @param #number WeaponType (optional) Bitmask of weapon types those allowed to use. If parameter is not defined that means no limits on weapon usage.
-- @param DCSTypes#AI.Task.WeaponExpend WeaponExpend (optional) Determines how much weapon will be released at each attack. If parameter is not defined the unit / controllable will choose expend on its own discretion.
-- @param #number AttackQty (optional) This parameter limits maximal quantity of attack. The aicraft/controllable will not make more attack than allowed even if the target controllable not destroyed and the aicraft/controllable still have ammo. If not defined the aircraft/controllable will attack target until it will be destroyed or until the aircraft/controllable will run out of ammo.
-- @param DCSTypes#Azimuth Direction (optional) Desired ingress direction from the target to the attacking aircraft. Controllable/aircraft will make its attacks from the direction. Of course if there is no way to attack from the direction due the terrain controllable/aircraft will choose another direction.
-- @param DCSTypes#Distance Altitude (optional) Desired attack start altitude. Controllable/aircraft will make its attacks from the altitude. If the altitude is too low or too high to use weapon aircraft/controllable will choose closest altitude to the desired attack start altitude. If the desired altitude is defined controllable/aircraft will not attack from safe altitude.
-- @param #boolean AttackQtyLimit (optional) The flag determines how to interpret attackQty parameter. If the flag is true then attackQty is a limit on maximal attack quantity for "AttackControllable" and "AttackUnit" tasks. If the flag is false then attackQty is a desired attack quantity for "Bombing" and "BombingRunway" tasks.
-- @return DCSTask#Task The DCS task structure.
function CONTROLLABLE:EnRouteTaskEngageGroup( AttackGroup, Priority, WeaponType, WeaponExpend, AttackQty, Direction, Altitude, AttackQtyLimit )
  self:F2( { self.ControllableName, AttackGroup, Priority, WeaponType, WeaponExpend, AttackQty, Direction, Altitude, AttackQtyLimit } )

  --  EngageControllable  = {
  --   id = 'EngageControllable ',
  --   params = {
  --     controllableId = Controllable.ID,
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
      controllableId = AttackGroup:GetID(),
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


--- (AIR) Attack the Unit.
-- @param #CONTROLLABLE self
-- @param Unit#UNIT AttackUnit The UNIT.
-- @param #number Priority All en-route tasks have the priority parameter. This is a number (less value - higher priority) that determines actions related to what task will be performed first. 
-- @param #number WeaponType (optional) Bitmask of weapon types those allowed to use. If parameter is not defined that means no limits on weapon usage.
-- @param DCSTypes#AI.Task.WeaponExpend WeaponExpend (optional) Determines how much weapon will be released at each attack. If parameter is not defined the unit / controllable will choose expend on its own discretion.
-- @param #number AttackQty (optional) This parameter limits maximal quantity of attack. The aicraft/controllable will not make more attack than allowed even if the target controllable not destroyed and the aicraft/controllable still have ammo. If not defined the aircraft/controllable will attack target until it will be destroyed or until the aircraft/controllable will run out of ammo.
-- @param DCSTypes#Azimuth Direction (optional) Desired ingress direction from the target to the attacking aircraft. Controllable/aircraft will make its attacks from the direction. Of course if there is no way to attack from the direction due the terrain controllable/aircraft will choose another direction.
-- @param #boolean AttackQtyLimit (optional) The flag determines how to interpret attackQty parameter. If the flag is true then attackQty is a limit on maximal attack quantity for "AttackControllable" and "AttackUnit" tasks. If the flag is false then attackQty is a desired attack quantity for "Bombing" and "BombingRunway" tasks.
-- @param #boolean ControllableAttack (optional) Flag indicates that the target must be engaged by all aircrafts of the controllable. Has effect only if the task is assigned to a controllable, not to a single aircraft.
-- @return DCSTask#Task The DCS task structure.
function CONTROLLABLE:EnRouteTaskEngageUnit( AttackUnit, Priority, WeaponType, WeaponExpend, AttackQty, Direction, AttackQtyLimit, ControllableAttack )
  self:F2( { self.ControllableName, AttackUnit, Priority, WeaponType, WeaponExpend, AttackQty, Direction, AttackQtyLimit, ControllableAttack } )

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
      unitId = AttackUnit:GetID(),
      weaponType = WeaponType,
      expend = WeaponExpend,
      attackQty = AttackQty,
      direction = Direction,
      attackQtyLimit = AttackQtyLimit,
      controllableAttack = ControllableAttack,
      priority = Priority,
    },
  },

  self:T3( { DCSTask } )
  return DCSTask
end



--- (AIR) Aircraft will act as an AWACS for friendly units (will provide them with information about contacts). No parameters.
-- @param #CONTROLLABLE self
-- @return DCSTask#Task The DCS task structure.
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
-- @return DCSTask#Task The DCS task structure.
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
-- @return DCSTask#Task The DCS task structure.
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
-- @param Controllable#CONTROLLABLE AttackGroup Target CONTROLLABLE.
-- @param #number Priority All en-route tasks have the priority parameter. This is a number (less value - higher priority) that determines actions related to what task will be performed first. 
-- @param #number WeaponType Bitmask of weapon types those allowed to use. If parameter is not defined that means no limits on weapon usage. 
-- @param DCSTypes#AI.Task.Designation Designation (optional) Designation type.
-- @param #boolean Datalink (optional) Allows to use datalink to send the target information to attack aircraft. Enabled by default. 
-- @return DCSTask#Task The DCS task structure.
function CONTROLLABLE:EnRouteTaskFAC_EngageGroup( AttackGroup, Priority, WeaponType, Designation, Datalink )
  self:F2( { self.ControllableName, AttackGroup, WeaponType, Priority, Designation, Datalink } )

--  FAC_EngageControllable  = { 
--    id = 'FAC_EngageControllable', 
--    params = { 
--      controllableId = Controllable.ID,
--      weaponType = number,
--      designation = enum AI.Task.Designation,
--      datalink = boolean,
--      priority = number,
--    } 
--  }

  local DCSTask
  DCSTask = { id = 'FAC_EngageControllable',
    params = {
      controllableId = AttackGroup:GetID(),
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
-- @param DCSTypes#Distance Radius  The maximal distance from the FAC to a target.
-- @param #number Priority All en-route tasks have the priority parameter. This is a number (less value - higher priority) that determines actions related to what task will be performed first. 
-- @return DCSTask#Task The DCS task structure.
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
-- @param DCSTypes#Vec2 Point The point where to wait.
-- @param #number Duration The duration in seconds to wait.
-- @param #CONTROLLABLE EmbarkingControllable The controllable to be embarked.
-- @return DCSTask#Task The DCS task structure
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
-- @param DCSTypes#Vec2 Point The point where to wait.
-- @param #number Radius The radius of the embarking zone around the Point.
-- @return DCSTask#Task The DCS task structure.
function CONTROLLABLE:TaskEmbarkToTransport( Point, Radius )
  self:F2( { self.ControllableName, Point, Radius } )

  local DCSTask --DCSTask#Task
  DCSTask = { id = 'EmbarkToTransport',
    params = { x = Point.x,
      y = Point.y,
      zoneRadius = Radius,
    }
  }

  self:T3( { DCSTask } )
  return DCSTask
end



--- (AIR + GROUND) Return a mission task from a mission template.
-- @param #CONTROLLABLE self
-- @param #table TaskMission A table containing the mission task.
-- @return DCSTask#Task
function CONTROLLABLE:TaskMission( TaskMission )
  self:F2( Points )

  local DCSTask
  DCSTask = { id = 'Mission', params = { TaskMission, }, }

  self:T3( { DCSTask } )
  return DCSTask
end

--- Return a Misson task to follow a given route defined by Points.
-- @param #CONTROLLABLE self
-- @param #table Points A table of route points.
-- @return DCSTask#Task
function CONTROLLABLE:TaskRoute( Points )
  self:F2( Points )

  local DCSTask
  DCSTask = { id = 'Mission', params = { route = { points = Points, }, }, }

  self:T3( { DCSTask } )
  return DCSTask
end

--- (AIR + GROUND) Make the Controllable move to fly to a given point.
-- @param #CONTROLLABLE self
-- @param DCSTypes#Vec3 Point The destination point in Vec3 format.
-- @param #number Speed The speed to travel.
-- @return #CONTROLLABLE self
function CONTROLLABLE:TaskRouteToVec2( Point, Speed )
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
-- @param DCSTypes#Vec3 Point The destination point in Vec3 format.
-- @param #number Speed The speed to travel.
-- @return #CONTROLLABLE self
function CONTROLLABLE:TaskRouteToVec3( Point, Speed )
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
-- @param #table GoPoints A table of Route Points.
-- @return #CONTROLLABLE self
function CONTROLLABLE:Route( GoPoints )
  self:F2( GoPoints )

  local DCSControllable = self:GetDCSObject()

  if DCSControllable then
    local Points = routines.utils.deepCopy( GoPoints )
    local MissionTask = { id = 'Mission', params = { route = { points = Points, }, }, }
    local Controller = self:_GetController()
    --Controller.setTask( Controller, MissionTask )
    SCHEDULER:New( Controller, Controller.setTask, { MissionTask }, 1 )
    return self
  end

  return nil
end



--- (AIR + GROUND) Route the controllable to a given zone.
-- The controllable final destination point can be randomized.
-- A speed can be given in km/h.
-- A given formation can be given.
-- @param #CONTROLLABLE self
-- @param Zone#ZONE Zone The zone where to route to.
-- @param #boolean Randomize Defines whether to target point gets randomized within the Zone.
-- @param #number Speed The speed.
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
    PointFrom.action = "Cone"
    PointFrom.speed = 20 / 1.6


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
      PointTo.speed = 20 / 1.6
    end

    local Points = { PointFrom, PointTo }

    self:T3( Points )

    self:Route( Points )

    return self
  end

  return nil
end

--- (AIR) Return the Controllable to an @{Airbase#AIRBASE}
-- A speed can be given in km/h.
-- A given formation can be given.
-- @param #CONTROLLABLE self
-- @param Airbase#AIRBASE ReturnAirbase The @{Airbase#AIRBASE} to return to.
-- @param #number Speed (optional) The speed.
-- @return #string The route
function CONTROLLABLE:RouteReturnToAirbase( ReturnAirbase, Speed )
  self:F2( { ReturnAirbase, Speed } )

-- Example
--   [4] = 
--    {
--        ["alt"] = 45,
--        ["type"] = "Land",
--        ["action"] = "Landing",
--        ["alt_type"] = "BARO",
--        ["formation_template"] = "",
--        ["properties"] = 
--        {
--            ["vnav"] = 1,
--            ["scale"] = 0,
--            ["angle"] = 0,
--            ["vangle"] = 0,
--            ["steer"] = 2,
--        }, -- end of ["properties"]
--        ["ETA"] = 527.81058817743,
--        ["airdromeId"] = 12,
--        ["y"] = 243127.2973737,
--        ["x"] = -5406.2803440839,
--        ["name"] = "DictKey_WptName_53",
--        ["speed"] = 138.88888888889,
--        ["ETA_locked"] = false,
--        ["task"] = 
--        {
--            ["id"] = "ComboTask",
--            ["params"] = 
--            {
--                ["tasks"] = 
--                {
--                }, -- end of ["tasks"]
--            }, -- end of ["params"]
--        }, -- end of ["task"]
--        ["speed_locked"] = true,
--    }, -- end of [4]
 

  local DCSControllable = self:GetDCSObject()

  if DCSControllable then

    local ControllablePoint = self:GetVec2()
    local ControllableVelocity = self:GetMaxVelocity()

    local PointFrom = {}
    PointFrom.x = ControllablePoint.x
    PointFrom.y = ControllablePoint.y
    PointFrom.type = "Turning Point"
    PointFrom.action = "Turning Point"
    PointFrom.speed = ControllableVelocity


    local PointTo = {}
    local AirbasePoint = ReturnAirbase:GetVec2()

    PointTo.x = AirbasePoint.x
    PointTo.y = AirbasePoint.y
    PointTo.type = "Land"
    PointTo.action = "Landing"
    PointTo.airdromeId = ReturnAirbase:GetID()-- Airdrome ID
    self:T(PointTo.airdromeId)
    --PointTo.alt = 0

    local Points = { PointFrom, PointTo }

    self:T3( Points )

    local Route = { points = Points, }

    return Route
  end

  return nil
end

-- Commands

--- Do Script command
-- @param #CONTROLLABLE self
-- @param #string DoScript
-- @return #DCSCommand
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

--- Return the route of a controllable by using the @{Database#DATABASE} class.
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
-- @param Controllable#CONTROLLABLE self
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
    
    
    return self:_GetController():getDetectedTargets( DetectionVisual, DetectionOptical, DetectionRadar, DetectionIRST, DetectionRWR, DetectionDLINK )
  end

  return nil
end

function CONTROLLABLE:IsTargetDetected( DCSObject )
  self:F2( self.ControllableName )

  local DCSControllable = self:GetDCSObject()
  if DCSControllable then

    local TargetIsDetected, TargetIsVisible, TargetLastTime, TargetKnowType, TargetKnowDistance, TargetLastPos, TargetLastVelocity
      = self:_GetController().isTargetDetected( self:_GetController(), DCSObject,
        Controller.Detection.VISUAL,
        Controller.Detection.OPTIC,
        Controller.Detection.RADAR,
        Controller.Detection.IRST,
        Controller.Detection.RWR,
        Controller.Detection.DLINK
      )
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
-- @param Controllable#CONTROLLABLE self
-- @return Controllable#CONTROLLABLE self
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

--- Retrieve the controllable mission and allow to place function hooks within the mission waypoint plan.
-- Use the method @{Controllable#CONTROLLABLE:WayPointFunction} to define the hook functions for specific waypoints.
-- Use the method @{Controllable@CONTROLLABLE:WayPointExecute) to start the execution of the new mission plan.
-- Note that when WayPointInitialize is called, the Mission of the controllable is RESTARTED!
-- @param #CONTROLLABLE self
-- @param #table WayPoints If WayPoints is given, then use the route.
-- @return #CONTROLLABLE
function CONTROLLABLE:WayPointInitialize( WayPoints )
  self:F( { WayPoint, WayPointIndex, WayPointFunction } )

  if WayPoints then
    self.WayPoints = WayPoints
  else
    self.WayPoints = self:GetTaskRoute()
  end

  return self
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
  self.WayPoints[WayPoint].task.params.tasks[WayPointIndex] = self:TaskFunction( WayPoint, WayPointIndex, WayPointFunction, arg )
  return self
end


function CONTROLLABLE:TaskFunction( WayPoint, WayPointIndex, FunctionString, FunctionArguments )
  self:F2( { WayPoint, WayPointIndex, FunctionString, FunctionArguments } )

  local DCSTask

  local DCSScript = {}
  DCSScript[#DCSScript+1] = "local MissionControllable = GROUP:Find( ... ) "

  if FunctionArguments and #FunctionArguments > 0 then
    DCSScript[#DCSScript+1] = FunctionString .. "( MissionControllable, " .. table.concat( FunctionArguments, "," ) .. ")"
  else
    DCSScript[#DCSScript+1] = FunctionString .. "( MissionControllable )"
  end

  DCSTask = self:TaskWrappedAction(
    self:CommandDoScript(
      table.concat( DCSScript )
    ), WayPointIndex
  )

  self:T3( DCSTask )

  return DCSTask

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

-- Message APIs

--- Returns a message with the callsign embedded (if there is one).
-- @param #CONTROLLABLE self
-- @param #string Message The message text
-- @param DCSTypes#Duration Duration The duration of the message.
-- @return Message#MESSAGE
function CONTROLLABLE:GetMessage( Message, Duration )

  local DCSObject = self:GetDCSObject()
  if DCSObject then
    return MESSAGE:New( Message, Duration, self:GetCallsign() .. " (" .. self:GetTypeName() .. ")" )
  end

  return nil
end

--- Send a message to all coalitions.
-- The message will appear in the message area. The message will begin with the callsign of the group and the type of the first unit sending the message.
-- @param #CONTROLLABLE self
-- @param #string Message The message text
-- @param DCSTypes#Duration Duration The duration of the message.
function CONTROLLABLE:MessageToAll( Message, Duration )
  self:F2( { Message, Duration } )

  local DCSObject = self:GetDCSObject()
  if DCSObject then
    self:GetMessage( Message, Duration ):ToAll()
  end

  return nil
end

--- Send a message to the red coalition.
-- The message will appear in the message area. The message will begin with the callsign of the group and the type of the first unit sending the message.
-- @param #CONTROLLABLE self
-- @param #string Message The message text
-- @param DCSTYpes#Duration Duration The duration of the message.
function CONTROLLABLE:MessageToRed( Message, Duration )
  self:F2( { Message, Duration } )

  local DCSObject = self:GetDCSObject()
  if DCSObject then
    self:GetMessage( Message, Duration ):ToRed()
  end

  return nil
end

--- Send a message to the blue coalition.
-- The message will appear in the message area. The message will begin with the callsign of the group and the type of the first unit sending the message.
-- @param #CONTROLLABLE self
-- @param #string Message The message text
-- @param DCSTypes#Duration Duration The duration of the message.
function CONTROLLABLE:MessageToBlue( Message, Duration )
  self:F2( { Message, Duration } )

  local DCSObject = self:GetDCSObject()
  if DCSObject then
    self:GetMessage( Message, Duration ):ToBlue()
  end

  return nil
end

--- Send a message to a client.
-- The message will appear in the message area. The message will begin with the callsign of the group and the type of the first unit sending the message.
-- @param #CONTROLLABLE self
-- @param #string Message The message text
-- @param DCSTypes#Duration Duration The duration of the message.
-- @param Client#CLIENT Client The client object receiving the message.
function CONTROLLABLE:MessageToClient( Message, Duration, Client )
  self:F2( { Message, Duration } )

  local DCSObject = self:GetDCSObject()
  if DCSObject then
    self:GetMessage( Message, Duration ):ToClient( Client )
  end

  return nil
end

--- Send a message to a @{Group}.
-- The message will appear in the message area. The message will begin with the callsign of the group and the type of the first unit sending the message.
-- @param #CONTROLLABLE self
-- @param #string Message The message text
-- @param DCSTypes#Duration Duration The duration of the message.
-- @param Group#GROUP MessageGroup The GROUP object receiving the message.
function CONTROLLABLE:MessageToGroup( Message, Duration, MessageGroup )
  self:F2( { Message, Duration } )

  local DCSObject = self:GetDCSObject()
  if DCSObject then
    if DCSObject:isExist() then
      self:GetMessage( Message, Duration ):ToGroup( MessageGroup )
    end
  end

  return nil
end

--- Send a message to the players in the @{Group}.
-- The message will appear in the message area. The message will begin with the callsign of the group and the type of the first unit sending the message.
-- @param #CONTROLLABLE self
-- @param #string Message The message text
-- @param DCSTypes#Duration Duration The duration of the message.
function CONTROLLABLE:Message( Message, Duration )
  self:F2( { Message, Duration } )

  local DCSObject = self:GetDCSObject()
  if DCSObject then
    self:GetMessage( Message, Duration ):ToGroup( self )
  end

  return nil
end

