-- Name: AIB-002 - Patrol AI.lua
-- Author: FlightControl
-- Date Created: 7 December 2016
--
-- # Situation:
--
-- For the red coalition, 2 client slots are foreseen.
-- For those players that have not joined the mission, red AI is spawned.
-- The red AI should start patrolling an area until fuel is empty and return to the home base.
-- 
-- # Test cases:
-- 
-- 1. If no player is logging into the red slots, 2 red AI planes should be alive.
-- 2. If a player joins one red slot, one red AI plane should return to the nearest home base.
-- 3. If two players join the red slots, no AI plane should be spawned, and all airborne AI planes should return to the nearest home base.
-- 4. Spawned AI should take-off from the airbase, and start patrolling the area around Anapa.
-- 5. When the AI is out-of-fuel, it should report it is returning to the home base, and land at Anapa.

-- Define the SET of CLIENTs from the red coalition. This SET is filled during startup.
RU_PlanesClientSet = SET_CLIENT:New():FilterCountries( "RUSSIA" ):FilterCategories( "plane" )

-- Define the SPAWN object for the red AI plane template.
-- We use InitCleanUp to check every 20 seconds, if there are no planes blocked at the airbase, waithing for take-off.
-- If a blocked plane exists, this red plane will be ReSpawned.
RU_PlanesSpawn = SPAWN:New( "AI RU" ):InitCleanUp( 20 )

-- Start the AI_BALANCER, using the SET of red CLIENTs, and the SPAWN object as a parameter.
RU_AI_Balancer = AI_BALANCER:New( RU_PlanesClientSet, RU_PlanesSpawn )

local PatrolZones = {}

function RU_AI_Balancer:OnAfterSpawned( SetGroup, From, Event, To, AIGroup )

  local PatrolZoneGroup = GROUP:FindByName( "PatrolZone" )
  local PatrolZone = ZONE_POLYGON:New( "PatrolZone", PatrolZoneGroup )


  PatrolZones[AIGroup] = AI_PATROL_ZONE:New( PatrolZone, 3000, 6000, 400, 600 )
  PatrolZones[AIGroup]:ManageFuel( 0.2, 60 )
  PatrolZones[AIGroup]:SetControllable( AIGroup )
  PatrolZones[AIGroup]:__Start( 5 )
 
end
