---
-- Name: CAP-010 - CAP and Engage within Range
-- Author: FlightControl
-- Date Created: 16 January 2017
--
-- # Situation:
--
-- The Su-27 airplane will patrol in PatrolZone.
-- It will engage when it detects the airplane and when the A-10C is within the engage range.
-- 
-- # Test cases:
-- 
-- 1. Observe the Su-27 patrolling.
-- 2. Observe that, when the A-10C is within the engage range, it will engage.
-- 3. After engage, observe that the Su-27 returns to the PatrolZone.
-- 4. If you want, you can wait until the Su-27 is out of fuel and will land.

CapPlane = GROUP:FindByName( "Plane" )

PatrolZone = ZONE:New( "Patrol Zone" )

AICapZone = AI_CAP_ZONE:New( PatrolZone, 500, 1000, 500, 600 )

AICapZone:SetControllable( CapPlane )
AICapZone:SetEngageRange( 20000 ) -- Set the Engage Range to 20.000 meters. The AI won't engage when the enemy is beyond 20.000 meters.

AICapZone:__Start( 1 ) -- They should statup, and start patrolling in the PatrolZone.
