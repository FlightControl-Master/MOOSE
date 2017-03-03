---
-- Name: SPA-018 - Ground Ops - Randomize Templates
-- Author: FlightControl
-- Date Created: 10 Jan 2017
--
-- # Situation:
--
-- At Gudauta spawn multiple ground vehicles, in a scheduled fashion.
-- 
-- # Test cases:
-- 
-- 1. Observe that the ground vehicles are spawned with randomized templates.


-- Tests Gudauta
-- -------------
-- Create a zone table of the 2 zones.
ZoneTable = { ZONE:New( "Zone1" ), ZONE:New( "Zone2" ) }

TemplateTable = { "A", "B", "C" }

Spawn_Vehicle_1 = SPAWN:New( "Spawn Vehicle 1" )
  :InitLimit( 10, 10 )
  :InitRandomizeRoute( 1, 1, 200 )
  :InitRandomizeTemplate( TemplateTable ) 
  --:InitRandomizeZones( ZoneTable )
  :SpawnScheduled( 5, .5 )

