---
-- Name: SPA-019 - Ground Ops - Randomize Templates with Waypoints
-- Author: FlightControl
-- Date Created: 24 Feb 2017
--
-- # Situation:
--
-- At Gudauta spawn multiple ground vehicles, in a scheduled fashion.
-- 
-- # Test cases:
-- 
-- 1. Observe that the ground vehicles are spawned with randomized templates.
-- 2. Observe that the ground vehicles are spread around the spawning area and are not stacked upon each other.


-- Tests Gudauta
-- -------------
-- Create a zone table of the 2 zones.
ZoneTable = { ZONE:New( "Zone1" ), ZONE:New( "Zone2" ) }

TemplateTable = { "A", "B", "C" }

Spawn_Vehicle_1 = SPAWN:New( "Spawn Vehicle 1" )
  :InitLimit( 10, 10 )
  :InitRandomizeTemplate( TemplateTable ) 
  :SpawnScheduled( 5, .5 )

