


-- Tests Anapa: Spawn Basics
-- -------------------------
-- Spawning groups using Spawn function.
Spawn_Plane = SPAWN:New( "Spawn Plane" )
Group_Plane = Spawn_Plane:Spawn()

Spawn_Helicopter = SPAWN:New( "Spawn Helicopter" ):InitRandomizeRoute( 1, 1, 1000 )
Group_Helicopter = Spawn_Helicopter:Spawn()
Group_Helicopter2 = Spawn_Helicopter:Spawn()

Spawn_Ship = SPAWN:New( "Spawn Ship" ):InitRandomizeRoute( 0, 0, 2000 )
Group_Ship1 = Spawn_Ship:Spawn()
Group_Ship2 = Spawn_Ship:Spawn()

Spawn_Vehicle = SPAWN:New( "Spawn Vehicle" ):InitRandomizeRoute( 1, 0, 50 )
Group_Vehicle1 = Spawn_Vehicle:Spawn()
Group_Vehicle2 = Spawn_Vehicle:Spawn()
Group_Vehicle3 = Spawn_Vehicle:Spawn()
Group_Vehicle4 = Spawn_Vehicle:Spawn()
Group_Vehicle5 = Spawn_Vehicle:Spawn()
Group_Vehicle6 = Spawn_Vehicle:Spawn()

Group_Vehicle1:TaskRouteToZone( ZONE:New( "Landing Zone" ), true, 40, "Cone" )

-- Now land the spawned plane on to the Vinson, by copying the route of another object.
Route_Plane = GROUP:FindByName( "Spawn Helicopter Route Copy" ):CopyRoute( 1, 0 )

Group_Plane:Route( Route_Plane )

--Route_Helicopter[#Route_Helicopter].linkUnit = Group_Ship1:GetDCSUnit(1)
--Route_Helicopter[#Route_Helicopter].helipadId = Group_Ship1:GetDCSUnit(1)
--Route_Helicopter[#Route_Helicopter].x = Group_Ship1:GetUnit(1):GetPointVec2().x
--Route_Helicopter[#Route_Helicopter].y = Group_Ship1:GetUnit(1):GetPointVec2().y
--env.info( Route_Helicopter[#Route_Helicopter].type .. " on " .. Group_Ship1:GetUnit(1):GetID() )
--Group_Helicopter:Route( Route_Helicopter )


-- Tests Batumi: Scheduled Spawning
-- --------------------------------
-- Unlimited spawning of groups, scheduled every 30 seconds ...
Spawn_Plane_Scheduled = SPAWN:New( "Spawn Plane Scheduled" ):SpawnScheduled( 30, 0.4 )
Spawn_Helicopter_Scheduled = SPAWN:New( "Spawn Helicopter Scheduled" ):SpawnScheduled( 30, 1 )
Spawn_Ship_Scheduled = SPAWN:New( "Spawn Ship Scheduled" ):SpawnScheduled( 30, 0.5 )
Spawn_Vehicle_Scheduled = SPAWN:New( "Spawn Vehicle Scheduled" ):SpawnScheduled( 30, 0.5 )

-- Tests Tbilisi: Limited Spawning and repeat
-- ------------------------------------------
-- Spawing one group, and respawning the same group when it lands ...
Spawn_Plane_Limited_Repeat = SPAWN:New( "Spawn Plane Limited Repeat" ):InitLimit( 1, 1 ):InitRepeat():Spawn()
Spawn_Plane_Limited_RepeatOnLanding = SPAWN:New( "Spawn Plane Limited RepeatOnLanding" ):InitLimit( 1, 1 ):InitRepeatOnLanding():Spawn()
Spawn_Plane_Limited_RepeatOnEngineShutDown = SPAWN:New( "Spawn Plane Limited RepeatOnEngineShutDown" ):InitLimit( 1, 1 ):InitRepeatOnEngineShutDown():Spawn()
Spawn_Helicopter_Limited_Repeat = SPAWN:New( "Spawn Helicopter Limited Repeat" ):InitLimit( 1, 1 ):InitRepeat():Spawn()
Spawn_Helicopter_Limited_RepeatOnLanding = SPAWN:New( "Spawn Helicopter Limited RepeatOnLanding" ):InitLimit( 1, 1 ):InitRepeatOnLanding():Spawn()
Spawn_Helicopter_Limited_RepeatOnEngineShutDown = SPAWN:New( "Spawn Helicopter Limited RepeatOnEngineShutDown" ):InitLimit( 1, 1 ):InitRepeatOnEngineShutDown():Spawn()


-- Tests Soganlug
-- --------------
-- Limited spawning of groups, scheduled every 30 seconds ...
Spawn_Plane_Limited_Scheduled = SPAWN:New( "Spawn Plane Limited Scheduled" ):InitLimit( 2, 10 ):SpawnScheduled( 30, 0 )
Spawn_Helicopter_Limited_Scheduled = SPAWN:New( "Spawn Helicopter Limited Scheduled" ):InitLimit( 2, 10 ):SpawnScheduled( 30, 0 )
Spawn_Ground_Limited_Scheduled = SPAWN:New( "Spawn Vehicle Limited Scheduled" ):InitLimit( 1, 20 ):SpawnScheduled( 90, 0 )

-- Tests Sukhumi
-- -------------
-- Limited spawning of groups, scheduled every seconds with route randomization.
Spawn_Plane_Limited_Scheduled_RandomizeRoute = SPAWN:New( "Spawn Plane Limited Scheduled RandomizeRoute" ):InitLimit( 5, 10 ):InitRandomizeRoute( 1, 1, 4000 ):SpawnScheduled( 2, 0 )
Spawn_Helicopter_Limited_Scheduled_RandomizeRoute = SPAWN:New( "Spawn Helicopter Limited Scheduled RandomizeRoute" ):InitLimit( 5, 10 ):InitRandomizeRoute( 1, 1, 4000 ):SpawnScheduled( 2, 0 )
Spawn_Vehicle_Limited_Scheduled_RandomizeRoute = SPAWN:New( "Spawn Vehicle Limited Scheduled RandomizeRoute" ):InitLimit( 10, 10 ):InitRandomizeRoute( 1, 1, 1000 ):SpawnScheduled( 1, 0 )


-- Tests Kutaisi
-- -------------
-- Tests the CleanUp functionality.
-- Limited spawning of groups, scheduled every 10 seconds, who are engaging into combat. Some helicopters may crash land on the ground.
-- Observe when helicopters land but are not dead and are out of the danger zone, that they get removed after a while (+/- 180 seconds) and ReSpawn.
Spawn_Helicopter_Scheduled_CleanUp = SPAWN:New( "Spawn Helicopter Scheduled CleanUp" ):InitLimit( 3, 100 ):InitRandomizeRoute( 1, 1, 1000 ):CleanUp( 60 ):SpawnScheduled( 10, 0 )
Spawn_Vehicle_Scheduled_CleanUp = SPAWN:New( "Spawn Vehicle Scheduled CleanUp" ):InitLimit( 3, 100 ):InitRandomizeRoute( 1, 1, 1000 ):SpawnScheduled( 10, 0 )

-- Maykop
-- ------
-- Creates arrays of groups ready to be spawned and dynamic spawning of groups from another group.

-- SpawnTestVisible creates an array of 200 groups, every 20 groups with 20 meters space in between, and will activate a group of the array every 10 seconds with a 0.2 time randomization.
SpawnTestVisible = SPAWN:New( "Spawn Vehicle Visible Scheduled" ):InitLimit( 200, 200 ):InitArray( 59, 20, 30, 30 ):SpawnScheduled( 10, 0.2 )

-- Spawn_Templates_Visible contains different templates...
Spawn_Templates_Visible = { "Spawn Vehicle Visible Template A",
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

-- Spawn_Vehicle_Visible_RandomizeTemplate_Scheduled creates an array of 40 vehicle groups, spread out by 20 groups each, with an 8 meter distance, 
--   and chooses for each group from the templates specified in Spawn_Templates_Visible.
					
Spawn_Vehicle_Visible_RandomizeTemplate_Scheduled = SPAWN:New( "Spawn Vehicle Visible RandomizeTemplate Scheduled" )
                                                         :InitLimit( 80, 80 )
													                               :InitRandomizeTemplate( Spawn_Templates_Visible )
													                               :InitRandomizeRoute( 1, 1, 300 )
													                               :InitArray( 49, 20, 8, 8 )
													                               :SpawnScheduled( 1, 0.2 )

-- Spawn_Infantry allows to spawn 10 Infantry groups.														   
Spawn_Infantry = SPAWN:New( "Spawn Infantry" )
                      :InitLimit( 10, 10 )

-- Spawn_Vehicle_Host reserves 10 vehicle groups, shown within an array arranged by 5 vehicles in a row with a distance of 8 meters, and schedules a vehicle each 10 seconds with a 20% variation.					  
Spawn_Vehicle_Host = SPAWN:New( "Spawn Vehicle Host" )
                          :InitLimit( 10, 10 )
						              :InitArray( 0, 5, 8, 8 )
						              :SpawnScheduled( 10, 0.2 )

-- Spawn_Vehicle_SpawnToZone allows to spawn 10 vehicle groups.
-- The vehicles will drive to waypoint 1, where it will spawn infantry that will walk to a certain point.
-- ---------------------------------------------------------------------------------------------
--      local InfantryGroup = Spawn_Infantry:SpawnFromUnit( GROUP:Find(...):GetUnit(1), 100, 5 )
--      local InfantryRoute = InfantryGroup:CopyRoute( 1, 0, true, 1000 )
--      InfantryGroup:Route( InfantryRoute )
-- ---------------------------------------------------------------------------------------------									
Spawn_Vehicle_SpawnToZone = SPAWN:New( "Spawn Vehicle SpawnToZone" )
								                 :InitLimit( 10, 10 )

-- Spawn_Helicopter_SpawnToZone will fly to a location, hover, and spawn one vehicle on the ground, the helicopter will land
-- and the vehicle will drive to a random location within the defined zone.
-- For this, the following code is activated within the mission on waypoint 3:
-- ------------------------------------------------------------------------------------------------------
--      local InfantryDropGroup = Spawn_Vehicle_SpawnToZone:SpawnFromUnit( GROUP:Find( ... ):GetUnit(1) )
--      local InfantryDropRoute = InfantryDropGroup:CopyRoute( 1, 0 )
--      InfantryDropGroup:TaskRouteToZone( ZONE:New( "Target Zone" ), true, 80 )
-- ------------------------------------------------------------------------------------------------------
Spawn_Helicopter_SpawnToZone = SPAWN:New( "Spawn Helicopter SpawnToZone" )
                                    :InitLimit( 10, 10 )
						                        :SpawnScheduled( 60, 0.2 )
						  

