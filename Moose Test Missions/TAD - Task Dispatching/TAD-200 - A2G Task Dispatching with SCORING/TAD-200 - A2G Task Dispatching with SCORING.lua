---
-- Name: TAD-200 - A2G Task Dispatching with SCORING
-- Author: FlightControl
-- Date Created: 19 Mar 2017
--
-- # Situation:
-- 
-- This mission demonstrates the scoring of dynamic task dispatching for Air to Ground operations.
-- 
-- # Test cases: 
-- 
-- 1. Observe the FAC(A)'s detecting targets and grouping them. 
-- 2. Check that the HQ provides menus to engage on a task set by the FACs.
-- 3. Engage on a task and destroy a target. Check if scoring is given for that target.
-- 4. Engage all targets in the task, and check if mission success is achieved and that a scoring is given.
-- 5. Restart the mission, and crash into the ground, check if you can get penalties.
-- 
local HQ = GROUP:FindByName( "HQ", "Bravo HQ" )

local CommandCenter = COMMANDCENTER:New( HQ, "Lima" )

local Scoring = SCORING:New( "Detect Demo" )

local Mission = MISSION
  :New( CommandCenter, "Overlord", "High", "Attack Detect Mission Briefing", coalition.side.RED )
  :AddScoring( Scoring )

local FACSet = SET_GROUP:New():FilterPrefixes( "FAC" ):FilterCoalitions("red"):FilterStart()

local FACAreas = DETECTION_UNITS:New( FACSet )


local AttackGroups = SET_GROUP:New():FilterCoalitions( "red" ):FilterPrefixes( "Attack" ):FilterStart()

TaskDispatcher = TASK_A2G_DISPATCHER:New( Mission, AttackGroups, FACAreas )

--- @param #TaskDispatcher self
-- @param From 
-- @param Event
-- @param To
-- @param Tasking.Task_A2G#TASK_A2G Task
-- @param Wrapper.Unit#UNIT TaskUnit
-- @param #string PlayerName
function TaskDispatcher:OnAfterAssign( From, Event, To, Task, TaskUnit, PlayerName )
  Task:SetScoreOnDestroy( "Player " .. PlayerName .. " destroyed a target", 20, TaskUnit )
  Task:SetScoreOnSuccess( "The task has been successfully completed!", 200, TaskUnit )
  Task:SetPenaltyOnFailed( "The task has failed completion!", -100, TaskUnit )
end

-- Now this is REALLY neat. I set the goal of the mission to be the destruction of Target #004.
-- This is just an example, but many more examples can follow...

-- Every time a Task becomes Successful, it will trigger the Complete event in the Mission.
-- The mission designer NEED TO OVERRIDE the OnBeforeComplete to prevent the mission from getting into completion 
-- too early!

function Mission:OnBeforeComplete( From, Event, To )
  local Group004 = GROUP:FindByName( "Target #004" )
  if Group004:IsAlive() == false then
    Mission:GetCommandCenter():MessageToCoalition( "Mission Complete!" )
    return true
  end
  return false
end