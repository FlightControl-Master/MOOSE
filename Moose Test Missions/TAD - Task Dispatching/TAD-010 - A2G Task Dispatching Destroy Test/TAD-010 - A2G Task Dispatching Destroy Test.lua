---
-- Name: TAD-010 - A2G Task Dispatching Destroy Test
-- Author: FlightControl
-- Date Created: 17 Mar 2017
--
-- # Situation:
-- 
-- This tests if an accepted task successful completion does finish the processes correctly.
-- 
-- # Test cases: 
-- 
-- 
HQ = GROUP:FindByName( "HQ", "Bravo HQ" )

CommandCenter = COMMANDCENTER:New( HQ, "Lima" )

Scoring = SCORING:New( "Detect Demo" )

Mission = MISSION
  :New( CommandCenter, "Overlord", "High", "Attack Detect Mission Briefing", coalition.side.RED )
  :AddScoring( Scoring )

FACSet = SET_GROUP:New():FilterPrefixes( "FAC" ):FilterCoalitions("red"):FilterStart()

FACAreas = DETECTION_UNITS:New( FACSet )


AttackGroups = SET_GROUP:New():FilterCoalitions( "red" ):FilterPrefixes( "Attack" ):FilterStart()

TaskDispatcher = TASK_A2G_DISPATCHER:New( Mission, AttackGroups, FACAreas )

-- Now this is REALLY neat. I set the goal of the mission to be the destruction of Target #004.
-- This is just an example, but many more examples can follow...

-- Every time a Task becomes Successful, it will trigger the Complete event in the Mission.
-- The mission designer NEED TO OVERRIDE the OnBeforeComplete to prevent the mission from getting into completion 
-- too early!

function Mission:OnBeforeComplete( From, Event, To )
  local Group004 = GROUP:FindByName( "Target #004" )
  if Group004 and Group004:IsAlive() == false then
    Mission:GetCommandCenter():MessageToCoalition( "Mission Complete!" )
    return true
  end
  return false
end
