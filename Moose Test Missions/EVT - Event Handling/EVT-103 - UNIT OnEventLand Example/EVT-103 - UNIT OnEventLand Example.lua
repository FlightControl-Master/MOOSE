---
-- Name: EVT-103 - UNIT OnEventLand Example
-- Author: FlightControl
-- Date Created: 7 Feb 2017
--
-- # Situation:
--
-- An AI plane is landing on an airfield.
-- When the plane landed, a new plane is spawned.
-- 
-- # Test cases:
-- 
-- 1. Observe the plane landing.
-- 2. When the AI plane lands, observe the new plane being spawned.
-- 3. Check the contents of the fields of the S_EVENT_LAND entry in the dcs.log file.

-- Create a variable PlaneAI that holds a reference to UNIT object (created by moose at the beginning of the mission) with the name "PlaneAI".
PlaneAI = UNIT:FindByName( "PlaneAI" )

-- Create a SPAWN object to spawn a new plane once the hold one lands.
SpawnPlane = SPAWN:New( "SpawnPlaneAI" )

-- Declare a new variable that will hold the new spawned SpawnPlaneAI
local NewPlane


-- Subscribe to the event Land. The Land event occurs when a plane lands at an airfield.
PlaneAI:HandleEvent( EVENTS.Land )

-- Because the PlaneAI object is subscribed to the Land event, the following method will be automatically
-- called when the land event is happening FOR THE PlaneAI UNIT only!
function PlaneAI:OnEventLand( EventData )

  -- Okay, the PlaneAI has landed, now spawn the new plane ( a predator )
  NewPlane = SpawnPlane:Spawn()
end


