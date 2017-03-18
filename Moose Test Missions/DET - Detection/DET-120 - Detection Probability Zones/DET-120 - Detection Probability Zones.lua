---
-- Name: DET-120 - Detection Probability Zones
-- Author: FlightControl
-- Date Created: 04 Feb 2017
--
-- # Situation:
--
-- Demonstrates the DistanceProbability factor during the detection of units.
-- 
-- Two JTAC are detecting 4 units, which are 10 km away.
-- The first JTAC has no DistanceProbability set.
-- The second JTAC has a DistanceProbability set.
-- 
-- # Test cases:
-- 
-- 1. Observe the reporting of both the first and second JTAC. The second should report slower the detection than the first.
-- 2. Eventually all units should be detected by both JTAC.

RecceSetGroup1 = SET_GROUP:New():FilterPrefixes( "Recce 1" ):FilterStart()
RecceSetGroup2 = SET_GROUP:New():FilterPrefixes( "Recce 2" ):FilterStart()

HQ = GROUP:FindByName( "HQ" )

CC = COMMANDCENTER:New( HQ, "HQ" )

RecceDetection1 = DETECTION_UNITS:New( RecceSetGroup1 )

RecceDetection2 = DETECTION_UNITS:New( RecceSetGroup2 )

ForestZone = ZONE_POLYGON:New( "ForestZone", GROUP:FindByName( "ForestZone" ) )

RecceDetection2:SetZoneProbability( { { ForestZone, 0.1 } } )  -- Set a 10% probability that a vehicle can be detected within the forest.


RecceDetection1:Start()
RecceDetection2:Start()

--- OnAfter Transition Handler for Event Detect.
-- @param Functional.Detection#DETECTION_UNITS self
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function RecceDetection1:OnAfterDetect(From,Event,To)

  local DetectionReport = self:DetectedReportDetailed()

  HQ:MessageToAll( DetectionReport, 15, "Detection 1 - No Zone Probability" )
end

--- OnAfter Transition Handler for Event Detect.
-- @param Functional.Detection#DETECTION_UNITS self
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function RecceDetection2:OnAfterDetect(From,Event,To)

  local DetectionReport = self:DetectedReportDetailed()

  HQ:MessageToAll( DetectionReport, 15, "Detection 2 - Forest Zone Probability" )
end

garbagecollect()
