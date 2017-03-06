---
-- Name: TAD-100 - A2G Task Dispatching DETECTION_AREAS
-- Author: FlightControl
-- Date Created: 06 Mar 2017
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
local HQ = GROUP:FindByName( "HQ", "Bravo HQ" )

local CommandCenter = COMMANDCENTER:New( HQ, "Lima" )

local Scoring = SCORING:New( "Detect Demo" )

local Mission = MISSION
  :New( CommandCenter, "Overlord", "High", "Attack Detect Mission Briefing", coalition.side.RED )
  :AddScoring( Scoring )

local FACSet = SET_GROUP:New():FilterPrefixes( "FAC" ):FilterCoalitions("red"):FilterStart()
local FACDetection = DETECTION_AREAS:New( FACSet, 500, 3000 )
FACDetection:BoundDetectedZones()

local AttackGroups = SET_GROUP:New():FilterCoalitions( "red" ):FilterPrefixes( "Attack" ):FilterStart()
local TaskDispatcher = DETECTION_DISPATCHER:New( Mission, HQ, AttackGroups, FACDetection )

