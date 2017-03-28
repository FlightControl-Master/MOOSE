---
-- Name: DET-200 - Detection UNITS
-- Author: FlightControl
-- Date Created: 13 Feb 2017
--
-- # Situation:
--
-- Demonstrates the detection of units.
-- 
-- A Set of Recce are detecting a large group of units, which are 5 km away.
-- Select one of the blue Recce, and press F7. Watch the reporting of the detection evolve.
-- The enemy is approaching.
-- 
-- # Test cases:
-- 
-- 1. Observe the detection reporting of both the Recce.
-- 2. Eventually all units should be detected by both Recce.

RecceSetGroup = SET_GROUP:New():FilterPrefixes( "Recce" ):FilterStart()

HQ = GROUP:FindByName( "HQ" )

CC = COMMANDCENTER:New( HQ, "HQ" )

RecceDetection = DETECTION_UNITS:New( RecceSetGroup )

RecceDetection:Start()

--- OnAfter Transition Handler for Event Detect.
-- @param Functional.Detection#DETECTION_UNITS self
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function RecceDetection:OnAfterDetect(From,Event,To)

  self:E("Detect")

  local DetectionReport = RecceDetection:DetectedReportDetailed()

  CC:MessageToAll( DetectionReport, 15, "" )
end

