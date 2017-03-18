-- Name: AIB-005 - Patrol AI and Randomize Zones
-- Author: FlightControl
-- Date Created: 10 Jan 2016
--
-- # Situation:
--
-- For the red coalition, 2 client slots are foreseen.
-- For those players that have not joined the mission, red AI is spawned.
-- The red AI should start patrolling an area until fuel is empty and return to the home base.
-- For each AI being spawned, ensure that they fly to a random zone defined within the mission editor.
-- Right now there are two patrol zones defined, so the AI should start patrolliing in one of these zones.
-- 
-- # Test cases:
-- 
-- 1. If no player is logging into the red slots, 2 red AI planes should be alive.
-- 2. If a player joins one red slot, one red AI plane should return to the nearest home base.
-- 3. If two players join the red slots, no AI plane should be spawned, and all airborne AI planes should return to the nearest home base.
-- 4. Spawned AI should take-off from the airbase, and start patrolling the area around Anapa.
-- 5. When the AI is out-of-fuel, it should report it is returning to the home base, and land at Anapa.
-- 6. Ensure that you see the AI patrol in one of the two zones ...

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

-- Create the second polygon zone ...
PatrolZoneGroup2 = GROUP:FindByName( "PatrolZone2" )
PatrolZone2 = ZONE_POLYGON:New( "PatrolZone2", PatrolZoneGroup2 )

-- Now, create an array of these zones ...
PatrolZoneArray = { PatrolZone1, PatrolZone2 }

function RU_AI_Balancer:OnAfterSpawned( SetGroup, From, Event, To, AIGroup )

  local Patrol = AI_PATROL_ZONE:New( PatrolZoneArray[math.random( 1, 2 )], 3000, 6000, 400, 600 )
  Patrol:ManageFuel( 0.2, 60 )
  Patrol:SetControllable( AIGroup )
  Patrol:Start()
 
end
