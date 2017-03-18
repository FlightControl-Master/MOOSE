-- Name: AIB-005 - Patrol AI and Randomize Zones
-- Author: FlightControl
-- Date Created: 10 Jan 2016
--
-- # Situation:
--
-- For the red coalition, 2 client slots are foreseen.
-- For those players that have not joined the mission, red AI is spawned.
-- You'll notice a lot of AI is being spawned, as there are a lot of slots...
-- If the SPAWN API :InitCleanUp( secs ) is NOT used, you'll notice that the planes block each other on the runway.
-- After a short period of time, nothing will move anymore...
-- The :InitCleanUp( seconds ) API of the SPAWN class ensure that any AI that is parked longer than the
-- specified amount of seconds, is respawned back at the parking position.
-- This frees up the other planes departing, and the airbase is in this way decluttered...
-- 
-- # Test cases:
-- 
-- 1. Observe the de-cluttering of planes at Krymsk.
-- 2. Play with the InitCleanUp API of the SPAWN class, extende the amount of seconds to find the optimal setting.

-- Define the SET of CLIENTs from the red coalition. This SET is filled during startup.
RU_PlanesClientSet = SET_CLIENT:New():FilterCountries( "RUSSIA" ):FilterCategories( "plane" )

-- Define the SPAWN object for the red AI plane template.
-- We use InitCleanUp to check every 20 seconds, if there are no planes blocked at the airbase, waithing for take-off.
-- If a blocked plane exists, this red plane will be ReSpawned.
RU_PlanesSpawn = SPAWN:New( "AI RU" ):InitCleanUp( 20 )

-- Start the AI_BALANCER, using the SET of red CLIENTs, and the SPAWN object as a parameter.
RU_AI_Balancer = AI_BALANCER:New( RU_PlanesClientSet, RU_PlanesSpawn )

-- Create the first polygon zone ...
PatrolZoneGroup1 = GROUP:FindByName( "PatrolZone1" )
PatrolZone1 = ZONE_POLYGON:New( "PatrolZone1", PatrolZoneGroup1 )

function RU_AI_Balancer:OnAfterSpawned( SetGroup, From, Event, To, AIGroup )

  local Patrol = AI_PATROL_ZONE:New( PatrolZone1, 3000, 6000, 400, 600 )
  Patrol:ManageFuel( 0.2, 60 )
  Patrol:SetControllable( AIGroup )
  Patrol:__Start( 5 )
 
end
