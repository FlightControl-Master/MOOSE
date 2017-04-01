 ---
-- Name: TAD-105 - A2G Task Dispatching DETECTION_AREAS
-- Author: FlightControl
-- Date Created: 12 Mar 2017
--
-- # Situation:
-- 
-- This mission demonstrates the dynamic task dispatching for Air to Ground operations.
-- FACA's and FAC's are patrolling around the battle zone, while detecting targets.
-- The detection method used is the DETECTION_AREAS method, which groups detected targets into zones.
-- 
-- # Test cases: 
-- 
-- 1. Observe the FAC(A)'s detecting targets and grouping them. 
--    For test, each zone will have a circle of tyres, that are visible on the map too.
-- 2. Check that the HQ provides menus to engage on a task set by the FACs.
-- 
HQ = GROUP:FindByName( "HQ", "Bravo HQ" )

CommandCenter = COMMANDCENTER:New( HQ, "Lima" )

Scoring = SCORING:New( "Detect Demo" )

Mission = MISSION
  :New( CommandCenter, "Overlord", "High", "Attack Detect Mission Briefing", coalition.side.RED )
  :AddScoring( Scoring )

FACSet = SET_GROUP:New():FilterPrefixes( "FAC" ):FilterCoalitions("red"):FilterStart()

FACAreas = DETECTION_AREAS:New( FACSet, 500 )
FACAreas:BoundDetectedZones()

AttackGroups = SET_GROUP:New():FilterCoalitions( "red" ):FilterPrefixes( "Attack" ):FilterStart()
TaskDispatcher = TASK_A2G_DISPATCHER:New( Mission, HQ, AttackGroups, FACAreas )

