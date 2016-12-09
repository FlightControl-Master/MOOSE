-- This test mission is a test bed for the TASKING framework.
-- It creates an head quarters (HQ), which contains one mission with one task to be accomplished.
-- When the pilot joins the plane, it will need to accept the task using the HQ menu.
-- Once the task is accepted, the group of the pilot will be assigned to the task.
-- The pilot will need to fly to the attack zone and elimitate all targets reported.
-- A smoking system is available that the pilot can use the acquire targets.
-- Once all targets are elimitated, the task is finished, and the mission is set to complete.
-- If the pilot crashes during flying, the task will fail, and the mission is set to failed.

-- Create the HQ object.
local HQ = COMMANDCENTER:New( GROUP:FindByName( "HQ" ) )

-- MOOSE contains a MISSION class. Use the MISSION class to setup missions, containing tasks to be executed.
-- Create the Mission object, and attach the Mission to the HQ object.
-- The Mission accepts 4 parameters:
-- 1. The HQ object
-- 2. The name of the Mission
-- 3. The type of Mission, this can be any word like "Strategic", "Tactical", "Urgent", "Optional", "Secondary"...
-- 4. The briefing of the Mission. This briefing is shown when the pilot joins a Task within the Mission.
local Mission = MISSION:New( HQ, 'SEAD Targets', "Strategic", "SEAD the enemy" )


-- MOOSE contains a SCORING class. Use the SCORING class to account the scores of achievements made by the pilots.
-- The scoring system is a standalone object, so here the Scoring object is created.
local Scoring = SCORING:New( "SEAD" )

-- The Scoring object is attached to the Mission object.
-- By doing this, now the Mission can set at defined states in tasks ( and in processes within the tasks ) scoring values, and a text. See later.
Mission:AddScoring( Scoring )

-- Define the set of group of planes that can be assigned to the Mission object.
local SEADSet = SET_GROUP:New():FilterPrefixes( "Test SEAD"):FilterStart()

-- Define the set of units that are the targets.
-- Note that I use FilterOnce, which means that the set will be defined only once,
-- and will not be continuously updated!
local TargetSet = SET_UNIT:New():FilterPrefixes( "US Hawk SR" ):FilterOnce()

-- Define the zone to where the pilot needs to navigate.
local TargetZone = ZONE:New( "Target Zone" )

-- MOOSE contains a TASK_BASE class. Use the TASK class to define a new Task object and attach it to a Mission object.
-- Here we define a new TaskSEAD object, and attach it to the Mission object.
-- ( The TASK_BASE class is the base class for ALL derived Task templates.
--   Task templates are TASK classes that quickly setup a Task scenario with given parameters. )
-- 
-- The TASK_BASE class is thus the primary task, and a task scenario will need to be provided to the TaskSEAD of the states and events that form the task.
-- TASK_BASE gets a couple of parameters:
-- 1. The Mission for which the Task needs to be achieved.
-- 2. The set of groups of planes that pilots can join.
-- 3. The name of the Task... This can be any name, and will be provided when the Pilot joins the task.
-- 4. A type of the Task. When Tasks are in state Planned, then a menu can be provided that group the task based on this given type.
local TaskSEAD = TASK_BASE:New( Mission, SEADSet, "SEAD Radars", "SEAD" ) -- Tasking.Task#TASK_BASE

-- This is now an important part of the Task process definition.
-- Each TASK contains a "Process Template".
-- You need to define this process Template by added Actions and Processes, otherwise, the task won't do anything.
-- This call retrieves the Finite State Machine template of the Task. 
-- This template WILL NEVER DIRECTLY BE EXECUTED.
-- But, when a Pilot joins a UNIT as defined within the SEADSet, the TaskSEAD will COPY the FsmSEAD to a NEW INTERNAL OBJECT and assign the COPIED FsmSEAD to the UNIT of the player.
-- There can be many copied FsmSEAD objects internally active within TaskSEAD, for each pilot that joined the Task one is instantiated.
-- The reason why this is done, is that each unit as a role within the Task, and can have different status.
-- Therefore, the FsmSEAD is a TEMPLATE PROCESS of the TASK, and must be designed as a UNIT with a player is executing that PROCESS. 

local FsmSEADTemplate = TaskSEAD:GetFsmTemplate()

-- Adding a new sub-process to the Task Template.
-- At first, the task needs to be accepted by a pilot.
-- We use for this the SUB-PROCESS FSM_ASSIGN_ACCEPT.
-- The method on the FsmSEAD AddProcess accepts the following parameters:
-- 1. State From "Planned". When the Fsm is in state "Planned", allow the event "Accept".
-- 2. Event "Accept". This event can be triggered through FsmSEAD:Accept() or FsmSEAD:__Accept( 1 ). See documentation on state machines.
-- 3. The PROCESS derived class. In this case, we use the FSM_ASSIGN_ACCEPT to accept the task and provide a briefing. So, when the event "Accept" is fired, this process is executed.
-- 4. A table with the "return" states of the FSM_ASSIGN_ACCEPT process. This table indicates that for a certain return state, a further event needs to be called.
--   4.1 When the return state is Assigned, fire the event in the Task FsmSEAD:Route()
--   4.2 When the return state is Rejected, fire the event in the Task FsmSEAD:Eject()
-- All other AddProcess calls are working in a similar manner.
FsmSEADTemplate:AddProcess    ( "Planned",    "Accept",   FSM_ASSIGN_ACCEPT:New( "SEAD the Area" ), { Assigned = "Route", Rejected = "Eject" } )

-- Same, adding a process.
FsmSEADTemplate:AddProcess    ( "Assigned",   "Route",    FSM_ROUTE_ZONE:New( TargetZone ), { Arrived = "Update" } )

-- Adding a new Action... 
-- Actions define also the flow of the Task, but the actions will need to be programmed within your script.
-- See the state machine explanation for further details.
-- The AddTransition received a couple of parameters:
-- 1. State From "Rejected". When the FsmSEAD is in state "Rejected", the event "Eject" can be fired.
-- 2. Event "Eject". This event can be triggered synchronously through FsmSEAD:Eject() or asynchronously through FsmSEAD:__Eject(secs).
-- 3. State To "Planned". After the event has been fired, the FsmSEAD will transition to Planned.
FsmSEADTemplate:AddTransition ( "Rejected",   "Eject",    "Planned" )
FsmSEADTemplate:AddTransition ( "Arrived",    "Update",   "Updated" ) 
FsmSEADTemplate:AddProcess    ( "Updated",    "Account",  FSM_ACCOUNT_DEADS:New( TargetSet, "SEAD" ), { Accounted = "Success" } )
FsmSEADTemplate:AddProcess    ( "Updated",    "Smoke",    FSM_SMOKE_TARGETS_ZONE:New( TargetSet, TargetZone ) )
FsmSEADTemplate:AddTransition ( "Accounted",  "Success",  "Success" )
FsmSEADTemplate:AddTransition ( "*",          "Fail",     "Failed" )

FsmSEADTemplate:AddScoreProcess( "Updated", "Account", "Account", "destroyed a radar", 25 )
FsmSEADTemplate:AddScoreProcess( "Updated", "Account", "Failed", "failed to destroy a radar", -10 )

-- Now we will set the SCORING. Scoring is set using the TaskSEAD object.
-- Scores can be set on the status of the Task, and on Process level.
FsmSEADTemplate:AddScore( "Success", "Destroyed all target radars", 250 )
FsmSEADTemplate:AddScore( "Failed", "Failed to destroy all target radars", -100 )




function FsmSEADTemplate:onenterUpdated( TaskUnit )
  self:E( { self } )
  self:Account()
  self:Smoke()
end

Mission:AddTask( TaskSEAD )

HQ:SetMenu()
