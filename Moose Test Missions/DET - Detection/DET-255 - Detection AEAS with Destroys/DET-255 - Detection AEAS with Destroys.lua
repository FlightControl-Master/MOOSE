---
-- Name: DET-255 - Detection AEAS with Destroys
-- Author: FlightControl
-- Date Created: 06 Mar 2017
--
-- # Situation:
--
-- A small blue vehicle with laser detection methods is detecting targets.
-- Targets are grouped within areas. A detection range and zone range is given to group the detected units.
-- This demo will group red vehicles in areas. One vehicle is diving from one group to the other.
-- After 30 seconds, one vehicle is destroyed in a zone.
-- After 60 seconds, a vehicle is destroyed that is a leader of a zone.
-- After 90 seconds, all vehicles are destroyed in a zone.
-- 
-- # Test cases:
-- 
-- 1. Observe the flaring of the areas formed
-- 2. Observe the smoking of the units detected
-- 3. Observe the areas being flexibly changed very detection run.
-- 4. The truck driving from the one group to the other, will leave the first area, and will join the second.
-- 5. While driving in between the areas, it will have a separate area.
-- 6. Observe the correct removal or relocation of the ZONEs.

FACSetGroup = SET_GROUP:New():FilterPrefixes( "FAC Group" ):FilterStart()

FACDetection = DETECTION_AREAS:New( FACSetGroup, 150, 250 ):BoundDetectedZones():SmokeDetectedUnits()

FACDetection:__Start( 5 )

SCHEDULER:New( nil,function() 
  local Target = UNIT:FindByName( "Target #004")
  Target:Destroy()
  end, {}, 30 
  )
  
SCHEDULER:New( nil,function() 
  local Target = UNIT:FindByName( "Target #006")
  Target:Destroy()
  end, {}, 60 
  )
  
SCHEDULER:New( nil,function() 
  local Target = UNIT:FindByName( "Target #007")
  Target:Destroy()
  end, {}, 90 
  )