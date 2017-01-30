-- Name: TSK-010 - Task Modelling - SEAD
-- Author: FlightControl
-- Date Created: 15 Dec 2016
--
-- # Situation
-- 
-- This test mission is a test bed for the TASKING framework.
-- It creates an head quarters (HQ), which contains one mission with one task to be accomplished.
-- When the pilot joins the plane, it will need to accept the task using the HQ menu.
-- Once the task is accepted, the group of the pilot will be assigned to the task.
-- The pilot will need to fly to the attack zone and elimitate all targets reported.
-- A smoking system is available that the pilot can use the acquire targets.
-- Once all targets are elimitated, the task is finished, and the mission is set to complete.
-- If the pilot crashes during flying, the task will fail, and the mission is set to failed.
-- 
-- Uses the Tracing functions from BASE within the DCS.log file. Check the DCS.log file for the results.
-- Create a new SCHEDULER object.
-- Check the DCS.log.
-- 
-- # Test cases:
-- 
-- There should only be one Task listed under Others Menu -> HQ -> SEAD Targets -> SEAD. This is the TaskSEAD2, that is copied from TaskSEAD.  
-- TaskSEAD is removed from the mission once TaskSEAD2 is created.
-- 
-- ## Run this mission in DCS Single Player: 
--     
--   * Once started, a slot.
--   * When in the plane, join the SEAD task through the Others Menu -> HQ -> SEAD Targets -> SEAD -> SEAD Radars Vector 2.
--   * When flying, watch the messages appear. It should say that you've been assigned to the task, and that you need to route your plane to a coordinate.
--   * Exit your plane by pressing ESC, and go back to the spectators. When in single player mode, just click on Back, and then click Spectators.
--   * Immediately rejoin a Slot, select an other plane.
--   * When in the plane, you should now not be able to join the Task. No menu options are given. That is because the Task is "Aborted".
--   * However, the aborted task is replanned within 30 seconds. As such, go back to spectators, and after 30 seconds, rejoin a slot in a plane.
--   * When in the plane, you should not be able to join the Task through the Others Menu -> HQ -> SEAD Targets -> SEAD -> SEAD Radars Vector 2.
--   * Once accepted, watch the messages appear. Route to the attach zone, following the coordinates.
--   * Once at the attack zone, you'll see a message how many targets are left to be destroyed. Attack the radar emitting SAM with a kh-25.
--   * When you HIT the SAM, you'll see a scoring message appear. One point is granted.
--   * Maybe you've fired two missiles, so, you'll see another HIT maybe on the SAM, again granting a point.
--   * When the SAM is DEAD (it may take a while), you'll see a scoring message that 10 points have been granted.
--   * You'll see a scoring message appear that grants 25 points because you've hit a target of the Task. (This was programmed below).
--   * You'll see a scoring message appear that grants 250 points because all Task targets have been elimitated. (This was also programmed below).
--   * You'll see a message appear that you have Task success. The Task will be flagged as 'Success', and cannot be joined anymore.
--   * You'll see a message appear that the Mission "SEAD Targets" has been "Completed".
--   
-- ## Run this mission in DCS Multiple Player, with one player:  
-- 
--   * Retry the above scenario, but now running this scenario on a multi player server, while connecting with one player to the mission. Watch the consistency of the messages.
--   
-- ## Run this mission in DCS Multiple Player, with two to three players simultaneously:  
-- 
--   * Retry the above scenario running this scenario on a multi player server, while connecting with two or three players to the mission. Watch the consistency of the messages.
--   * When the first player has accepted the Task, the 2nd and 3rd player joining the Task, will be automatically assigned to the Task.
-- 
-- ## Others things to watch out for:
-- 
--   * When flying to the attack zone, a message should appear every 30 seconds with the coordinates.
--   * When in the attack zone, a message should appear every 30 seconds how many targes are left within the task.
--   * When a player aborts the task, a message is displayed of the player aborting, but only to the group assigned to execute the task.
--   * When a player joins the task, a message is displayed of the player joining, but only to the group assigned to execute the task.
--   * When a player crashes into the ground, a message is displayed of that event.
--   * In multi player, when the Task was assigned to the group, but all players in that group aborted the Task, the Task should become Aborted. It will be replanned in 30 seconds.

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
SEADSet:Flush()

-- Define the set of units that are the targets.
-- Note that I use FilterOnce, which means that the set will be defined only once,
-- and will not be continuously updated!
local TargetSet = SET_UNIT:New():FilterPrefixes( "US Hawk SR" ):FilterOnce()

-- Define the zone to where the pilot needs to navigate.
local TargetZone = ZONE:New( "Target Zone" )

-- MOOSE contains a TASK class. Use the TASK class to define a new Task object and attach it to a Mission object.
-- Here we define a new TaskSEAD object, and attach it to the Mission object.
-- ( The TASK class is the base class for ALL derived Task templates.
--   Task templates are TASK classes that quickly setup a Task scenario with given parameters. )
-- 
-- The TASK class is thus the primary task, and a task scenario will need to be provided to the TaskSEAD of the states and events that form the task.
-- TASK gets a couple of parameters:
-- 1. The Mission for which the Task needs to be achieved.
-- 2. The set of groups of planes that pilots can join.
-- 3. The name of the Task... This can be any name, and will be provided when the Pilot joins the task.
-- 4. A type of the Task. When Tasks are in state Planned, then a menu can be provided that group the task based on this given type.
local SEADTask = TASK:New( 
  Mission, 
  SEADSet, 
  "SEAD Radars Vector 1", 
  "SEAD" ) -- Tasking.Task#TASK

-- This is now an important part of the Task process definition.
-- Each TASK contains a "Process Template".
-- You need to define this process Template by added Actions and Processes, otherwise, the task won't do anything.
-- This call retrieves the Finite State Machine template of the Task. 
-- This template WILL NEVER DIRECTLY BE EXECUTED.
-- But, when a Pilot joins a UNIT as defined within the SEADSet, the TaskSEAD will COPY the FsmSEAD to a NEW INTERNAL OBJECT and assign the COPIED FsmSEAD to the UNIT of the player.
-- There can be many copied FsmSEAD objects internally active within TaskSEAD, for each pilot that joined the Task one is instantiated.
-- The reason why this is done, is that each unit as a role within the Task, and can have different status.
-- Therefore, the FsmSEAD is a TEMPLATE PROCESS of the TASK, and must be designed as a UNIT with a player is executing that PROCESS. 

local SEADProcess = SEADTask:GetUnitProcess() -- #SEADProcess

-- Adding a new sub-process to the Task Template.
-- At first, the task needs to be accepted by a pilot.
-- We use for this the SUB-PROCESS ACT_ASSIGN_ACCEPT.
-- The method on the FsmSEAD AddProcess accepts the following parameters:
-- 1. State From "Planned". When the Fsm is in state "Planned", allow the event "Accept".
-- 2. Event "Accept". This event can be triggered through FsmSEAD:Accept() or FsmSEAD:__Accept( 1 ). See documentation on state machines.
-- 3. The PROCESS derived class. In this case, we use the ACT_ASSIGN_ACCEPT to accept the task and provide a briefing. So, when the event "Accept" is fired, this process is executed.
-- 4. A table with the "return" states of the ACT_ASSIGN_ACCEPT process. This table indicates that for a certain return state, a further event needs to be called.
--   4.1 When the return state is Assigned, fire the event in the Task FsmSEAD:Route()
--   4.2 When the return state is Rejected, fire the event in the Task FsmSEAD:Eject()
-- All other AddProcess calls are working in a similar manner.

SEADProcess:AddProcess( "Planned", "Accept", ACT_ASSIGN_ACCEPT:New( "SEAD the Area" ), { Assigned = "Route", Rejected = "Eject" } ) -- FSM SUB for type SEADProcess.
	
SEADProcess:AddProcess( "Assigned", "Route", ACT_ROUTE_ZONE:New( TargetZone ), { Arrived = "Update" } ) -- FSM SUB for type SEADProcess.

-- Adding a new Action... 
-- Actions define also the flow of the Task, but the actions will need to be programmed within your script.
-- See the state machine explanation for further details.
-- The AddTransition received a couple of parameters:
-- 1. State From "Rejected". When the FsmSEAD is in state "Rejected", the event "Eject" can be fired.
-- 2. Event "Eject". This event can be triggered synchronously through FsmSEAD:Eject() or asynchronously through FsmSEAD:__Eject(secs).
-- 3. State To "Planned". After the event has been fired, the FsmSEAD will transition to Planned.

SEADProcess:AddTransition( "Rejected", "Eject", "Planned" )

SEADProcess:AddTransition( "Arrived", "Update", "Updated" )

SEADProcess:AddProcess( "Updated", "Account", ACT_ACCOUNT_DEADS:New( TargetSet, "SEAD" ), { Accounted = "Success" } )

SEADProcess:AddProcess( "Updated", "Smoke", ACT_ASSIST_SMOKE_TARGETS_ZONE:New( TargetSet, TargetZone ) )

SEADProcess:AddTransition( "Accounted", "Success", "Success" )

SEADProcess:AddTransition( "*", "Fail", "Failed" )

SEADProcess:AddScoreProcess( "Updated", "Account", "Account", "destroyed a radar", 25 )
SEADProcess:AddScoreProcess( "Updated", "Account", "Failed", "failed to destroy a radar", -10 )

-- Now we will set the SCORING. Scoring is set using the TaskSEAD object.
-- Scores can be set on the status of the Task, and on Process level.
SEADProcess:AddScore( "Success", "Destroyed all target radars", 250 )
SEADProcess:AddScore( "Failed", "Failed to destroy all target radars", -100 )

function SEADProcess:OnEnterUpdated( Controllable, From, Event, To )
  self:E( { self } )
  self:Account()
  self:Smoke()
end

-- Here we handle the PlayerAborted event, which is fired when a Player leaves the unit while being assigned to the Task.
-- Within the event handler, which is passed the PlayerUnit and PlayerName parameter,
-- we check if the SEADTask has still AlivePlayers assigned to the Task.
-- If not, the Task will Abort.
-- And it will be Replanned within 30 seconds.
function SEADTask:OnEnterPlayerCrashed( PlayerUnit, PlayerName )
  if not SEADTask:HasAliveUnits() then
    SEADTask:__Abort()
  end 
end


local TaskSEAD2 = TASK:New( Mission, SEADSet, "SEAD Radars Vector 2", "SEAD" ) -- Tasking.Task#TASK
TaskSEAD2:SetUnitProcess( SEADTask:GetUnitProcess():Copy() )
Mission:AddTask( TaskSEAD2 )

Mission:RemoveTask( SEADTask )

SEADTask = nil
SEADProcess = nil


collectgarbage()
