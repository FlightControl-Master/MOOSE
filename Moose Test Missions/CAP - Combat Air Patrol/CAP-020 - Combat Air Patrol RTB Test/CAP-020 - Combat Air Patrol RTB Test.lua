---
-- Name: CAP-020 - Combat Air Patrol RTB Test
-- Author: FlightControl
-- Date Created: 14 February 2017
--
-- # Situation:
-- The Su-27 airplane will patrol in PatrolZone.
-- It will return to base when out of fuel.
-- 
-- # Test cases:
-- 
-- 1. Observe the Su-27 patrolling.
-- 2. It should return to base when out of fuel.
-- 

local CapSpawn = SPAWN:New( "Plane" ):InitLimit(1,2):InitRepeatOnLanding()

local CapGroup = CapSpawn:Spawn()

local PatrolZone = ZONE:New( "Patrol Zone" )

local AICapZone = AI_CAP_ZONE:New( PatrolZone, 500, 1000, 500, 600 )

AICapZone:SetControllable( CapGroup )

AICapZone:__Start( 1 ) -- They should statup, and start patrolling in the PatrolZone.

