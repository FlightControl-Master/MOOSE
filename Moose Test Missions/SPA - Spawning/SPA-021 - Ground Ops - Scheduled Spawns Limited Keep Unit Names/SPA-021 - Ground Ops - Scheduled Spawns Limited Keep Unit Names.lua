---
-- Name: SPA-021 - Ground Ops - Scheduled Spawns Limited Keep Unit Names
-- Author: FlightControl
-- Date Created: 14 Mar 2017
--
-- # Situation:
--
-- At Gudauta spawn multiple ground vehicles, in a scheduled fashion.
-- 
-- # Test cases:
-- 
-- 1. Observe that the ground vehicles are spawned at the position declared within the mission editor.
-- 2. The vehicles should spawn according the scheduler parameters.
-- 3. There should not be more than 5 groups spawned.
-- 4. Observe the unit names, they should have the name as defined within the ME.



-- Tests Gudauta
-- -------------
Spawn_Vehicle_1 = SPAWN
  :New( "Spawn Vehicle 1" )
  :InitKeepUnitNames()
  :InitLimit( 5, 10 )
  :SpawnScheduled( 5, .5 )


