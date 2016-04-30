-------------------------------------------------------------------------------
-- @module DCSController

--- Controller is an object that performs A.I.-routines. Other words controller is an instance of A.I.. Controller stores current main task, active enroute tasks and behavior options. Controller performs commands. Please, read DCS A-10C GUI Manual EN.pdf chapter "Task Planning for Unit Groups", page 91 to understand A.I. system of DCS:A-10C. 
-- 
-- This class has 2 types of functions:
-- 
-- * Tasks
-- * Commands: Commands are instant actions those required zero time to perform. Commands may be used both for control unit/group behavior and control game mechanics. 
-- @type Controller
-- @field #Controller.Detection Detection Enum contains identifiers of surface types. 

--- Enables and disables the controller.
-- Note: Now it works only for ground / naval groups!
-- @function [parent=#Controller] setOnOff
-- @param self
-- @param #boolean value Enable / Disable.

-- Tasks

--- Resets current task and then sets the task to the controller. Task is a table that contains task identifier and task parameters.
-- @function [parent=#Controller] setTask
-- @param self
-- @param #Task task

--- Resets current task of the controller.
-- @function [parent=#Controller] resetTask 
-- @param self

--- Pushes the task to the front of the queue and makes the task active. Further call of function Controller.setTask() function will stop current task, clear the queue and set the new task active. If the task queue is empty the function will work like function Controller.setTask() function.
-- @function [parent=#Controller] pushTask
-- @param self
-- @param #Task task

--- Pops current (front) task from the queue and makes active next task in the queue (if exists). If no more tasks in the queue the function works like function Controller.resetTask() function. Does nothing if the queue is empty.
-- @function [parent=#Controller] popTask
-- @param self

--- Returns true if the controller has a task. 
-- @function [parent=#Controller] hasTask
-- @param self
-- @return #boolean

-- Commands

--TODO: describe #Command structure
--- Sets the command to perform by controller.
-- @function [parent=#Controller] setCommand
-- @param self
-- @param #Command command Table that contains command identifier and command parameters. 


-- Behaviours

--- Sets the option to the controller.
-- Option is a pair of identifier and value. Behavior options are global parameters those affect controller behavior in all tasks it performs.
-- Option identifiers and values are stored in table AI.Option in subtables Air, Ground and Naval.
-- 
-- OptionId = @{#AI.Option.Air.id} or @{#AI.Option.Ground.id} or @{#AI.Option.Naval.id}
-- OptionValue = AI.Option.Air.val[optionName] or AI.Option.Ground.val[optionName] or AI.Option.Naval.val[optionName]
-- 
-- @function [parent=#Controller] setOption
-- @param self
-- @param #OptionId optionId Option identifier. 
-- @param #OptionValue optionValue Value of the option.


-- Detection

--- Enum contains identifiers of surface types. 
-- @type Controller.Detection
-- @field VISUAL
-- @field OPTIC
-- @field RADAR
-- @field IRST
-- @field RWR
-- @field DLINK

--- Detected target. 
-- @type DetectedTarget
-- @field Object#Object object The target
-- @field #boolean visible The target is visible
-- @field #boolean type The target type is known
-- @field #boolean distance Distance to the target is known


--- Checks if the target is detected or not. If one or more detection method is specified the function will return true if the target is detected by at least one of these methods. If no detection methods are specified the function will return true if the target is detected by any method. 
-- @function [parent=#Controller] isTargetDetected
-- @param self
-- @param Object#Object target Target to check
-- @param #Controller.Detection detection Controller.Detection detection1, Controller.Detection detection2, ... Controller.Detection detectionN 
-- @return #boolean detected True if the target is detected. 
-- @return #boolean visible Has effect only if detected is true. True if the target is visible now. 
-- @return #ModelTime lastTime Has effect only if visible is false. Last time when target was seen. 
-- @return #boolean type Has effect only if detected is true. True if the target type is known. 
-- @return #boolean distance Has effect only if detected is true. True if the distance to the target is known. 
-- @return #Vec3 lastPos Has effect only if visible is false. Last position of the target when it was seen. 
-- @return #Vec3 lastVel Has effect only if visible is false. Last velocity of the target when it was seen. 


--- Returns list of detected targets. If one or more detection method is specified the function will return targets which were detected by at least one of these methods. If no detection methods are specified the function will return targets which were detected by any method.
-- @function [parent=#Controller] getDetectedTargets
-- @param self
-- @param #Controller.Detection detection Controller.Detection detection1, Controller.Detection detection2, ... Controller.Detection detectionN 
-- @return #list<#DetectedTarget> array of DetectedTarget

--- Know a target.
-- @function [parent=#Controller] knowTarget
-- @param self
-- @param Object#Object object The target.
-- @param #boolean type Target type is known.
-- @param #boolean distance Distance to target is known.


Controller = {} --#Controller