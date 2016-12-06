---
-- Tests Gudauta
-- -------------
-- Limited scheduled spawning of groups...
Spawn_Plane_Limited_Scheduled = SPAWN:New( "Spawn Plane Limited Scheduled" ):InitLimit( 4, 20 ):SpawnScheduled( 30, 0 )
Spawn_Helicopter_Limited_Scheduled = SPAWN:New( "Spawn Helicopter Limited Scheduled" ):InitLimit( 4, 20 ):SpawnScheduled( 30, 0 )
Spawn_Ground_Limited_Scheduled = SPAWN:New( "Spawn Vehicle Limited Scheduled" ):InitLimit( 4, 20 ):SpawnScheduled( 90, 0 )

---
-- Tests Sukhumi
-- -------------
-- Limited scheduled spawning of groups with destruction...
Spawn_Plane_Limited_Scheduled_RandomizeRoute = SPAWN:New( "Spawn Plane Limited Scheduled Destroy" ):InitLimit( 4, 20 ):SpawnScheduled( 10, 0 )
Spawn_Helicopter_Limited_Scheduled_RandomizeRoute = SPAWN:New( "Spawn Helicopter Limited Scheduled Destroy" ):InitLimit( 4, 20 ):SpawnScheduled( 10, 0 )
Spawn_Vehicle_Limited_Scheduled_RandomizeRoute = SPAWN:New( "Spawn Vehicle Limited Scheduled Destroy" ):InitLimit( 4, 20 ):SpawnScheduled( 10, 0 )


