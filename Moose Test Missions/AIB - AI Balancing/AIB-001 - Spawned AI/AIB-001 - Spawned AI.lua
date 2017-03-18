---
-- Name: AIB-001 - Spawned AI
-- Author: FlightControl
-- Date Created: 07 Dec 2016
--
-- # Situation:
--
-- For the red coalition, 2 client slots are foreseen.
-- We test the AI spawning frequency, validating the number of spawned AI, 
-- matching the amount of players that not have joined the mission.
-- When players join, AI should fly to the nearest home base.
-- 
-- # Test cases:
-- 
-- 1. If no player is logging into the red slots, 2 red AI planes should be alive.
-- 2. If a player joins one red slot, one red AI plane should return to the nearest home base.
-- 3. If two players join the red slots, no AI plane should be spawned, and all airborne AI planes should return to the nearest home base.

-- Define the SET of CLIENTs from the red coalition. This SET is filled during startup.
RU_PlanesClientSet = SET_CLIENT:New():FilterCountries( "RUSSIA" ):FilterCategories( "plane" )

-- Define the SPAWN object for the red AI plane template.
-- We use InitCleanUp to check every 20 seconds, if there are no planes blocked at the airbase, waithing for take-off.
-- If a blocked plane exists, this red plane will be ReSpawned.
RU_PlanesSpawn = SPAWN:New( "AI RU" ):InitCleanUp( 20 )

-- Start the AI_BALANCER, using the SET of red CLIENTs, and the SPAWN object as a parameter.
RU_AI_Balancer = AI_BALANCER:New( RU_PlanesClientSet, RU_PlanesSpawn )
