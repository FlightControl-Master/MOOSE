-- Name: AIB-004 - Respawn Test when Destroyed.lua
-- Author: FlightControl
-- Date Created: 7 January 2017
--
-- # Situation:
--
-- For the red coalition, 2 client slots are foreseen.
-- For those players that have not joined the mission, red AI is spawned.
-- The red AI should start patrolling an area.
--
-- The blue side has SAMs nearby.
-- Once the red AI takes off, the red AI is attacked by the blue SAMs.
-- Red AI should be killed and once that happens, a Respawn of the group should happen!
-- The Respawn happens through the InitCleanUp() API of SPAWN.
-- 
-- # Test cases:
-- 
-- 1. If no player is logging into the red slots, 2 red AI planes should be alive.
-- 2. If a player joins one red slot, one red AI plane should return to the nearest home base.
-- 3. If two players join the red slots, no AI plane should be spawned, and all airborne AI planes should return to the nearest home base.
-- 4. Monitor that once a red AI is destroyed, that it ReSpawns...


-- Define the SET of CLIENTs from the red coalition. This SET is filled during startup.
RU_PlanesClientSet = SET_CLIENT:New():FilterCountries( "RUSSIA" ):FilterCategories( "plane" )

-- Define the SPAWN object for the red AI plane template.
-- We use InitCleanUp to check every 20 seconds, if there are no planes blocked at the airbase, waithing for take-off.
-- If a blocked plane exists, this red plane will be ReSpawned.
RU_PlanesSpawn = SPAWN:New( "AI RU" ):InitCleanUp( 20 )

-- Start the AI_BALANCER, using the SET of red CLIENTs, and the SPAWN object as a parameter.
RU_AI_Balancer = AI_BALANCER:New( RU_PlanesClientSet, RU_PlanesSpawn )

function RU_AI_Balancer:OnAfterSpawned( SetGroup, From, Event, To, AIGroup )

  local PatrolZoneGroup = GROUP:FindByName( "PatrolZone" )
  local PatrolZone = ZONE_POLYGON:New( "PatrolZone", PatrolZoneGroup )


  local Patrol = AI_PATROL_ZONE:New( PatrolZone, 3000, 6000, 400, 600 )
  Patrol:ManageFuel( 0.2, 60 )
  Patrol:SetControllable( AIGroup )
  Patrol:__Start( 5 )
 
end

