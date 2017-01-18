-- Name: SPA-015 - Ground Ops - Randomize Route
-- Author: FlightControl
-- Date Created: 10 Jan 2017
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
-- 4. Observe that the route that the vehicles follow is randomized starting from point 1 till point 3.



-- Tests Gudauta
-- -------------
Spawn_Vehicle_1 = SPAWN:New( "Spawn Vehicle 1" )
  :InitLimit( 10, 10 )
  :InitRandomizeRoute( 1, 1, 200 ) -- Randomize route starting from point 1 till point 3, with a radius of 200 meters around each point.
  :SpawnScheduled( 5, .5 )




