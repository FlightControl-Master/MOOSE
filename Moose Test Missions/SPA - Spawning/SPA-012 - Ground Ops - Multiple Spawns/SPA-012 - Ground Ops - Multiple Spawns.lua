-- Name: SPA-012 - Ground Ops - Multiple Spawns
-- Author: FlightControl
-- Date Created: 10 Jan 2017
--
-- # Situation:
--
-- At Gudauta spawn multiple ground vehicles.
-- 
-- # Test cases:
-- 
-- 1. Observe that the ground vehicles are spawned at the position declared within the mission editor.



-- Tests Gudauta
-- -------------
-- Spawn a gound vehicle...
Spawn_Vehicle_1 = SPAWN:New( "Spawn Vehicle 1" )
Spawn_Group_1 = Spawn_Vehicle_1:Spawn()
Spawn_Group_2 = Spawn_Vehicle_1:Spawn()
Spawn_Group_3 = Spawn_Vehicle_1:Spawn()
Spawn_Group_4 = Spawn_Vehicle_1:Spawn()
Spawn_Group_5 = Spawn_Vehicle_1:Spawn()



