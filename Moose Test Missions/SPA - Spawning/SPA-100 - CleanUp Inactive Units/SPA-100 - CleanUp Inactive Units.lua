-- Tests Kutaisi
-- -------------
-- Tests the CleanUp functionality.
-- Limited spawning of groups, scheduled every 10 seconds, who are engaging into combat. Some helicopters may crash land on the ground.
-- Observe when helicopters land but are not dead and are out of the danger zone, that they get removed after a while (+/- 180 seconds) and ReSpawn.
Spawn_Helicopter_Scheduled_CleanUp = SPAWN:New( "Spawn Helicopter Scheduled CleanUp" ):InitLimit( 3, 100 ):InitRandomizeRoute( 1, 1, 1000 ):InitCleanUp( 60 ):SpawnScheduled( 10, 0 )
Spawn_Vehicle_Scheduled_CleanUp = SPAWN:New( "Spawn Vehicle Scheduled CleanUp" ):InitLimit( 3, 100 ):InitRandomizeRoute( 1, 1, 1000 ):SpawnScheduled( 10, 0 )

