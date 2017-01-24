-- Name: SPA-017 - Ground Ops - Set AI inactive while spawning
-- Author: FlightControl
-- Date Created: 24 Jan 2017
--
-- # Situation:
--
-- At Gudauta spawn multiple ground vehicles, in a scheduled fashion.
-- But set the AI inactive when spawning.
-- 
-- # Test cases:
-- 
-- 1. Observe that the ground vehicles are spawned at the position declared within the mission editor.
-- 2. The vehicles should spawn according the scheduler parameters.
-- 3. There should not be more than 5 groups spawned.
-- 4. Observe that the AI is inactivated, and thus, the vehicles aren't moving.
-- 5. Observe that the position where the units are spawned, is randomized in the zones perimeters.



-- Tests Gudauta
-- -------------
-- Create a zone table of the 2 zones.
ZoneTable = { ZONE:New( "Zone1" ), ZONE:New( "Zone2" ) }

Spawn_Vehicle_1 = SPAWN:New( "Spawn Vehicle 1" )
  :InitLimit( 10, 10 )
  :InitRandomizeRoute( 1, 1, 200 ) 
  :InitRandomizeZones( ZoneTable )
  :InitAIOnOff( false ) -- This will disable the AI. You can also use :InitAIOff(). Set AI On (for those groups with AI Off in the ME), with :InitAIOn().
  :SpawnScheduled( 5, .5 )

