---
-- Name: DET-500 - Handle Detected Event - Govern Artillery Demo
-- Author: FlightControl
-- Date Created: 13 Feb 2017
--
-- # Situation:
--
-- Demonstrates the detection of units.
-- 
-- A Set of Recces are detecting a large group of units, which are 5 km away.
-- Once the Recces detect the enemy, the artilley units are controlled and will fire a missile to the target.
-- 
-- # Test cases:
-- 
-- 1. Observe the detected reporting of the recces.
-- 2. When one Recce group detects a target, it will select an artillery unit and fire a missile.
-- 3. This will run until all Recces have eliminated the targets.

RecceSetGroup = SET_GROUP:New():FilterCoalitions( "blue" ):FilterPrefixes( "Recce" ):FilterStart()
ArtillerySetGroup = SET_GROUP:New():FilterCoalitions( "blue" ):FilterPrefixes( "Artillery" ):FilterStart()

HQ = GROUP:FindByName( "HQ" )

CC = COMMANDCENTER:New( HQ, "HQ" )

RecceDetection = DETECTION_UNITS:New( RecceSetGroup )
RecceDetection:SetDetectionInterval( 5 )

RecceDetection:Start()

--- OnAfter Transition Handler for Event Detect.
-- @param Functional.Detection#DETECTION_UNITS self
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function RecceDetection:OnAfterDetect(From,Event,To)

  local DetectionReport = RecceDetection:DetectedReportDetailed()

  CC:GetPositionable():MessageToAll( DetectionReport, 15, "" )
end

local ArtilleryTime = {}
local ArtilleryAim = 180

--- OnAfter Transition Handler for Event Detect.
-- @param Functional.Detection#DETECTION_UNITS self
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @param Wrapper.Unit#UNIT DetectedUnits
function RecceDetection:OnAfterDetected( From, Event, To, DetectedUnits )
  self:E( { From, Event, To, DetectedUnits } )

  for DetectedUnitID, DetectedUnit in pairs( DetectedUnits ) do
    local DetectedUnit = DetectedUnit -- Wrapper.Unit#UNIT
    local Artillery = ArtillerySetGroup:GetRandom() -- Wrapper.Group#GROUP
    
    if ArtilleryTime[Artillery] and ArtilleryTime[Artillery] <= timer.getTime() - ArtilleryAim then
      ArtilleryTime[Artillery] = nil
    end

    if not ArtilleryTime[Artillery] then
      local Task = Artillery:TaskFireAtPoint( DetectedUnit:GetVec2(), 500, 4 ) -- Fire 2 rockets to the target point.
      Artillery:SetTask( Task, 0.5 )
      ArtilleryTime[Artillery] = timer.getTime()
    end
    
  end
end