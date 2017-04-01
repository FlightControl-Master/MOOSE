---
-- Name: SCO-500 - Scoring Multi Player Demo Mission 1
-- Author: Pikey and FlightControl
-- Date Created: 1 Mar 2017
--
-- # Situation:
-- 
-- A demo mission for the scoring. Read the briefing and have fun.
-- 
-- # Test cases:
-- 
-- 1. Observe the scoring granted to your flight when you hit and kill targets.

-- Define the patrol zones
BlueCapZone = ZONE_POLYGON:New( "BlueCapZone", GROUP:FindByName( "Blue CAP Zone Patrol" ) )
RedCapZone = ZONE_POLYGON:New( "RedCapZone", GROUP:FindByName( "Red CAP Zone Patrol" ) )

-- Define the engage zones
BlueEngageZone = ZONE_POLYGON:New( "BlueEngageZone", GROUP:FindByName( "Blue CAP Zone Engage" ) )
RedEngageZone = ZONE_POLYGON:New( "RedEngageZone", GROUP:FindByName( "Red CAP Zone Engage" ) )

-- Define the Spawn zones for ground vehicles
BlueSpawnGroundZone = ZONE_POLYGON:New( "BlueSpawnGroundZone", GROUP:FindByName( "Blue Spawn Zone" ) )
--RedSpawnGroundZone = ZONE_POLYGON:New( "RedSpawnGroundZone", GROUP:FindByName( "Red Spawn Zone" ) )

RedSpawnGroundZone = ZONE:New( "Red Spawn Zone" )

-- Define the Scoring zones that define the shelters
BlueShelterZone = ZONE_POLYGON:New( "Blue Shelters", GROUP:FindByName( "Blue Shelters" ) )
RedShelterZone = ZONE_POLYGON:New( "Red Shelters", GROUP:FindByName( "Red Shelters" ) )

-- Define the Set of Clients that are used for the AI Balancers
BluePlanesClientSet = SET_CLIENT:New():FilterCoalitions( "blue" ):FilterCategories( "plane" ):FilterPrefixes( "Blue Player")
RedPlanesClientSet = SET_CLIENT:New():FilterCoalitions( "red" ):FilterCategories( "plane" ):FilterPrefixes( "Red Player")

-- Define the Spawn objects for the AI planes
BluePlanesSpawn = SPAWN:New( "BlueAICAP" ):InitCleanUp( 120 ):InitLimit( 5, 0 )
RedPlanesSpawn = SPAWN:New( "RedAICAP" ):InitCleanUp( 120 ):InitLimit( 5, 0 )

-- Define the AI Balancers for the planes
BlueAIB = AI_BALANCER:New( BluePlanesClientSet, BluePlanesSpawn ):InitSpawnInterval( 60, 1200 )
RedAIB = AI_BALANCER:New( RedPlanesClientSet, RedPlanesSpawn ):InitSpawnInterval( 60, 1200 )

-- Define the Spawn objects for the airbase defenses
BlueAirbaseDefense1Spawn = SPAWN:New( "Blue Airbase Defense 1" ):InitLimit( 10, 10 ):SpawnScheduled( 60, 0 )
BlueAirbaseDefense2Spawn = SPAWN:New( "Blue Airbase Defense 2" ):InitLimit( 2, 10 ):SpawnScheduled( 60, 0 )
RedAirbaseDefense1Spawn = SPAWN:New( "Red Airbase Defense 1" ):InitLimit( 10, 10 ):SpawnScheduled( 60, 0 )
RedAirbaseDefense2Spawn = SPAWN:New( "Red Airbase Defense 2" ):InitLimit( 2, 10 ):SpawnScheduled( 60, 0 )

-- Define the ground forces spawning engines...

-- First define the template arrays.
BlueGroundTemplates = { "Blue Ground Forces 1", "Blue Ground Forces 2", "Blue Ground Forces 3" }
RedGroundTemplates = { "Red Ground Forces 2", "Red Ground Forces 2", "Red Ground Forces 3" }

-- New we are using these templates to define the spawn objects for the ground forces.
-- We spawn them at random places into the define zone.
BlueGroundSpawn = SPAWN
  :New( "Blue Ground Forces" )
  :InitLimit( 12, 30 )
  :InitRandomizeZones( { BlueSpawnGroundZone } )
  :InitRandomizeTemplate( BlueGroundTemplates )
  :SpawnScheduled( 60, 0.2 )

RedGroundSpawn = SPAWN
  :New( "Red Ground Forces" )
  :InitLimit( 12, 30 )
  :InitRandomizeTemplate( RedGroundTemplates )
  :InitRandomizeZones( { RedSpawnGroundZone } )
  :SpawnScheduled( 60, 0.2 )



BlueCap = {}
RedCap = {}

-- Define the OnAfterSpawned events of the AI balancer Spawn Groups
function BlueAIB:OnAfterSpawned( SetGroup, From, Event, To, AIGroup )
  if AIGroup then
    BlueCap[AIGroup] = BlueCap[AIGroup] or AI_CAP_ZONE:New( BlueCapZone, 500, 3000, 450, 1200 ) 
    local Cap = BlueCap[AIGroup] -- AI.AI_CAP#AI_CAP_ZONE
  
    Cap:ManageFuel( 0.4, 180 )
    Cap:SetEngageZone( BlueEngageZone )
    Cap:SetControllable( AIGroup )
    Cap:Start()
  end
end

function RedAIB:OnAfterSpawned( SetGroup, From, Event, To, AIGroup )

  if AIGroup then
    RedCap[AIGroup] = RedCap[AIGroup] or AI_CAP_ZONE:New( RedCapZone, 500, 3000, 450, 1200 )
    local Cap = RedCap[AIGroup] -- AI.AI_CAP#AI_CAP_ZONE
  
    Cap:ManageFuel( 0.4, 180 )
    Cap:SetEngageZone( BlueEngageZone )
    Cap:SetControllable( AIGroup )
    Cap:Start()
  end
end




-- Okay, now that we defined all this stuff, now make the SCORING setup ...

-- First define a Scoring object
local Scoring = SCORING:New( "SCO-500 - Scoring Demonstration Mission" )

-- Define within the scoring the shelter designated targets.
Scoring:AddZoneScore( BlueShelterZone, 50 ) -- Per shelter destroyed, 50 extra points are granted.
Scoring:AddZoneScore( RedShelterZone, 50 ) -- Per shelter destroyed, 50 extra points are granted.

-- Define the static objects that give extra scores
Scoring:AddStaticScore( STATIC:FindByName( "Red Factory 1"), 100 )
Scoring:AddStaticScore( STATIC:FindByName( "Red Factory 2"), 100 )
Scoring:AddStaticScore( STATIC:FindByName( "Red Factory 3"), 100 )
Scoring:AddStaticScore( STATIC:FindByName( "Red Factory 4"), 100 )

Scoring:AddStaticScore( STATIC:FindByName( "Red Truck #001"), 80 )
Scoring:AddStaticScore( STATIC:FindByName( "Red Truck #002"), 80 )
Scoring:AddStaticScore( STATIC:FindByName( "Red Truck #003"), 80 )
Scoring:AddStaticScore( STATIC:FindByName( "Red Truck #004"), 80 )

Scoring:AddStaticScore( STATIC:FindByName( "Blue Factory 1" ), 100 )
Scoring:AddStaticScore( STATIC:FindByName( "Blue Factory 2" ), 100 )
Scoring:AddStaticScore( STATIC:FindByName( "Blue Factory 3" ), 100 )
Scoring:AddStaticScore( STATIC:FindByName( "Blue Factory 4" ), 100 )

Scoring:AddStaticScore( STATIC:FindByName( "Blue Truck #001" ), 80 )
Scoring:AddStaticScore( STATIC:FindByName( "Blue Truck #002" ), 80 )
Scoring:AddStaticScore( STATIC:FindByName( "Blue Truck #003" ), 80 )
Scoring:AddStaticScore( STATIC:FindByName( "Blue Truck #004" ), 80 )

-- Scale the scoring rewarded.
Scoring:SetScaleDestroyScore( 30 )
Scoring:SetScaleDestroyPenalty( 90 ) -- Penalties are punished more than normal destroys.

