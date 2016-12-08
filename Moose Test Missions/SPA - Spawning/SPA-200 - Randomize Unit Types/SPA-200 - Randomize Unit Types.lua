--- 
-- Tests Gudauta
-- --------------
-- Limited and scheduled spawning of groups, with RandomizeTemplate ...

Templates = { "Template1", "Template2", "Template3", "Template4" }

Spawn_Ground1 = SPAWN:New( "Spawn Vehicle1" ):InitLimit( 4, 20 ):InitRandomizeTemplate(Templates):SpawnScheduled( 15, 0 )
Spawn_Ground2 = SPAWN:New( "Spawn Vehicle2" ):InitLimit( 4, 20 ):InitRandomizeTemplate(Templates):SpawnScheduled( 15, 0 )


