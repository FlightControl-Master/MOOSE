---
-- Name: CAP-012 - CAP - Test Abort
-- Author: FlightControl
-- Date Created: 14 Mar 2017
--
-- # Situation:
--
-- The Su-27 airplane will patrol in PatrolZone.
-- It will engage when it detects the airplane and when the A-10C is within the CapEngageZone.
-- It will abort the engagement after 1 minute and return to the patrol zone.
--
-- # Test cases:
-- 
-- 1. Observe the Su-27 patrolling.
-- 2. Observe that, when the A-10C is within the engage zone, it will engage.
-- 3. After engage, observe that the Su-27 returns to the PatrolZone.
-- 4. When it engages, it will abort the engagement after 1 minute.
 

CapPlane = GROUP:FindByName( "Plane" )

PatrolZone = ZONE:New( "Patrol Zone" )

AICapZone = AI_CAP_ZONE:New( PatrolZone, 500, 1000, 500, 600 )

EngageZoneGroup = GROUP:FindByName( "Engage Zone" )

CapEngageZone = ZONE_POLYGON:New( "Engage Zone", EngageZoneGroup )

AICapZone:SetControllable( CapPlane )
AICapZone:SetEngageZone( CapEngageZone ) -- Set the Engage Zone. The AI will only engage when the bogeys are within the CapEngageZone.

AICapZone:__Start( 1 ) -- They should statup, and start patrolling in the PatrolZone.

function AICapZone:OnAfterEngage(Controllable,From,Event,To)
  AICapZone:__Abort( 60 )
end

function AICapZone:OnAfterAbort(Controllable,From,Event,To)
  BASE:E("MISSION ABORTED! Returning to Patrol Zone!")
  MESSAGE:New("MISSION ABORTED! Returning to Patrol Zone!",30,"ALERT!")
end

