-- Name: CAP-001 - Combat Air Patrol
-- Author: FlightControl
-- Date Created: 16 January 2017
--
-- # Situation:
--
-- # Test cases:
-- 

local CapPlane = GROUP:FindByName( "Plane" )

local PatrolZone = ZONE:New( "Patrol Zone" )

local AICapZone = AI_CAP_ZONE:New( PatrolZone, 500, 1000, 500, 600 )

AICapZone:SetControllable( CapPlane )

AICapZone:__Start( 1 ) -- They should statup, and start patrolling in the PatrolZone.
