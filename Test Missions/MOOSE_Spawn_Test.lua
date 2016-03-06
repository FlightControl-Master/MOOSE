Include.File( "Spawn" )


-- Tests Batumi
---------------
Spawn_Plane_Scheduled = SPAWN:New( "Spawn Plane Scheduled" ):SpawnScheduled( 30, 0.4 )
Spawn_Helicopter_Scheduledd = SPAWN:New( "Spawn Helicopter Scheduled" ):SpawnScheduled( 30, 1 )
Spawn_Ship_Scheduled = SPAWN:New( "Spawn Ship Scheduled" ):SpawnScheduled( 30, 0.5 )
Spawn_Vehicle_Scheduled = SPAWN:New( "Spawn Vehicle Scheduled" ):SpawnScheduled( 30, 0.5 )

-- Tests Tbilisi
----------------
Spawn_Plane_Limited_Repeat = SPAWN:New( "Spawn Plane Limited Repeat" ):Limit( 1, 1 ):Repeat():Spawn()
Spawn_Plane_Limited_RepeatOnLanding = SPAWN:New( "Spawn Plane Limited RepeatOnLanding" ):Limit( 1, 1 ):Repeat():Spawn()
Spawn_Plane_Limited_RepeatOnEngineShutDown = SPAWN:New( "Spawn Plane Limited RepeatOnEngineShutDown" ):Limit( 1, 1 ):Repeat():Spawn()
Spawn_Helicopter_Limited_Repeat = SPAWN:New( "Spawn Helicopter Limited Repeat" ):Limit( 1, 1 ):Repeat():Spawn()
Spawn_Helicopter_Limited_RepeatOnLanding = SPAWN:New( "Spawn Helicopter Limited RepeatOnLanding" ):Limit( 1, 1 ):Repeat():Spawn()
Spawn_Helicopter_Limited_RepeatOnEngineShutDown = SPAWN:New( "Spawn Helicopter Limited RepeatOnEngineShutDown" ):Limit( 1, 1 ):Repeat():Spawn()


-- Tests Soganlug
Spawn_Plane_Limited_Scheduled = SPAWN:New( "Spawn Plane Limited Scheduled" ):Limit( 2, 10 ):SpawnScheduled( 30, 0 )
Spawn_Helicopter_Limited_Scheduled = SPAWN:New( "Spawn Helicopter Limited Scheduled" ):Limit( 2, 10 ):SpawnScheduled( 30, 0 )
Spawn_Ground_Limited_Scheduled = SPAWN:New( "Spawn Vehicle Limited Scheduled" ):Limit( 1, 20 ):SpawnScheduled( 90, 0 )

-- Tests Sukhumi
Spawn_Plane_Limited_Scheduled_RandomizeRoute = SPAWN:New( "Spawn Plane Limited Scheduled RandomizeRoute" ):Limit( 2, 10 ):RandomizeRoute( 1, 1, 4000 ):SpawnScheduled( 30, 0 )
Spawn_Helicopter_Limited_Scheduled_RandomizeRoute = SPAWN:New( "Spawn Helicopter Limited Scheduled RandomizeRoute" ):Limit( 2, 10 ):RandomizeRoute( 1, 1, 4000 ):SpawnScheduled( 30, 0 )
Spawn_Vehicle_Limited_Scheduled_RandomizeRoute = SPAWN:New( "Spawn Vehicle Limited Scheduled RandomizeRoute" ):Limit( 10, 10 ):RandomizeRoute( 1, 1, 1000 ):SpawnScheduled( 1, 0 )


-- Tests Kutaisi
----------------
-- Spawn Helicopters and Ground attack.
-- Observe when helicopters land but are not dead and are out of the danger zone, that they get removed after a while (+/- 180 seconds) and ReSpawn.
Spawn_Helicopter_Scheduled_CleanUp = SPAWN:New( "Spawn Helicopter Scheduled CleanUp" ):Limit( 3, 100 ):RandomizeRoute( 1, 1, 1000 ):CleanUp( 180 ):SpawnScheduled( 10, 0 )
Spawn_Vehicle_Scheduled_CleanUp = SPAWN:New( "Spawn Vehicle Scheduled CleanUp" ):Limit( 3, 100 ):RandomizeRoute( 1, 1, 1000 ):SpawnScheduled( 10, 0 )

-- Test Matrix Visible Setup

SpawnTestVisible = SPAWN:New( "Spawn Vehicle Visible Scheduled" ):Limit( 200, 200 ):SpawnArray( 59, 20, 20, 10 ):SpawnScheduled( 10, 0.2 )

Spawn_Templates_1 = { "Spawn Vehicle Visible Template A",
                      "Spawn Vehicle Visible Template B",
                      "Spawn Vehicle Visible Template C",
                      "Spawn Vehicle Visible Template D",
                      "Spawn Vehicle Visible Template E",
                      "Spawn Vehicle Visible Template F",
                      "Spawn Vehicle Visible Template G",
                      "Spawn Vehicle Visible Template H",
                      "Spawn Vehicle Visible Template I",
                      "Spawn Vehicle Visible Template J"
					}
					
Spawn_Vehicle_Visible_RandomizeTemplate_Scheduled_1 = SPAWN:New( "Spawn Vehicle Visible RandomizeTemplate Scheduled" )
                                                           :Limit( 40, 40 )
													       :RandomizeTemplate( Spawn_Templates_1 )
													       :SpawnArray( 49, 20, 8, 8 )
													       :SpawnScheduled( 10, 0.2 )
														   

														   
-- Tests Maykop
Spawn_Infantry = SPAWN:New( "Spawn Infantry" )
                      :Limit( 10, 10 )

					  
Spawn_Vehicle_Host = SPAWN:New( "Spawn Vehicle Host" )
                          :Limit( 10, 10 )
						  :SpawnArray( 0, 5, 8, 8 )
						  :SpawnScheduled( 10, 0.2 )

									
Spawn_Vehicle_SpawnToZone = SPAWN:New( "Spawn Vehicle SpawnToZone" )
								 :Limit( 10, 10 )
						  
Spawn_Helicopter_SpawnToZone = SPAWN:New( "Spawn Helicopter SpawnToZone" )
                                    :Limit( 10, 10 )
						            :SpawnScheduled( 60, 0.2 )
						  

