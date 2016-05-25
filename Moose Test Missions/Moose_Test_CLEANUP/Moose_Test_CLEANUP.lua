Include.File( 'Cleanup' )
Include.File( 'Spawn' )
Include.File( 'Event')

Clean = CLEANUP:New( 'CLEAN_BATUMI', 180 )

SpawnRU = SPAWN:New( 'RU Attack Heli Batumi'):Limit( 2, 20 ):SpawnScheduled( 2, 0.2 )

SpawnUS = SPAWN:New( 'US Attack Heli Batumi'):Limit( 2, 20 ):SpawnScheduled( 2, 0.2 )

