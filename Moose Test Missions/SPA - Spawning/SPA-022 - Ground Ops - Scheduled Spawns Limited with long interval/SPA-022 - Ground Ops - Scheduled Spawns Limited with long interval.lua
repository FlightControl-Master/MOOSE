-- Name: SPA-022 - Ground Ops - Scheduled Spawns Limited with long interval
-- Author: FlightControl
-- Date Created: 18 Mar 2017
--
-- # Situation:
--
-- At Gudauta spawn multiple ground vehicles, in a scheduled fashion.
-- The vehicle should respawn when killed.
-- 
-- # Test cases:
-- 
-- 1. Observe that the ground vehicles are spawned at the position declared within the mission editor.
-- 2. The vehicles should spawn according the scheduler parameters.



-- Tests Gudauta
-- -------------
Spawn_Vehicle_1 = SPAWN:New( "Spawn Vehicle 1" ):InitLimit( 1, 0 ):SpawnScheduled( 30, .5 )




