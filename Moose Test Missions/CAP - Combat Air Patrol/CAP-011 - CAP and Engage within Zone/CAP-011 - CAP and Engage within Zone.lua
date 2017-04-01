---
-- Name: CAP-011 - CAP and Engage within Zone
-- Author: FlightControl
-- Date Created: 16 January 2017
--
-- # Situation:
--
-- The Su-27 airplane will patrol in PatrolZone.
-- It will engage when it detects the airplane and when the A-10C is within the CapEngageZone.
--
-- # Test cases:
-- 
-- 1. Observe the Su-27 patrolling.
-- 2. Observe that, when the A-10C is within the engage zone, it will engage.
-- 3. After engage, observe that the Su-27 returns to the PatrolZone.
-- 4. If you want, you can wait until the Su-27 is out of fuel and will land.
 

CapPlane = GROUP:FindByName( "Plane" )

PatrolZone = ZONE:New( "Patrol Zone" )

AICapZone = AI_CAP_ZONE:New( PatrolZone, 500, 1000, 500, 600 )

EngageZoneGroup = GROUP:FindByName( "Engage Zone" )

CapEngageZone = ZONE_POLYGON:New( "Engage Zone", EngageZoneGroup )

AICapZone:SetControllable( CapPlane )
AICapZone:SetEngageZone( CapEngageZone ) -- Set the Engage Zone. The AI will only engage when the bogeys are within the CapEngageZone.

AICapZone:__Start( 1 ) -- They should statup, and start patrolling in the PatrolZone.
