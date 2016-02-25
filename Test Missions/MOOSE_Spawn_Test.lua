Include.File( "Spawn" )

SpawnTest = SPAWN:New( 'TEST' ):Schedule( 1, 1, 15, 0.4 ):Repeat()

SpawnTestPlane = SPAWN:New( 'TESTPLANE' ):Schedule( 1, 1, 15, 0.4 ):RepeatOnLanding()

SpawnTestShipPlane = SPAWN:New( 'SHIPPLANE' ):Schedule( 1, 1, 15, 0.4 ):RepeatOnLanding()

SpawnTestShipHeli = SPAWN:New( 'SHIPHELI' ):Schedule( 1, 1, 15, 0.4 ):RepeatOnLanding()

SpawnCH53E = SPAWN:New( 'VEHICLE' )


SpawnTestHelicopterCleanUp = SPAWN:New( "TEST_HELI_CLEANUP" ):Limit( 3, 100 ):Schedule( 10, 0 ):RandomizeRoute( 1, 1, 1000 ):CleanUp( 180 )
SpawnTestVehiclesCleanUp = SPAWN:New( "TEST_AAA_CLEANUP" ):Limit( 3, 100 ):Schedule( 10, 0 ):RandomizeRoute( 1, 1, 1000 )