-- This test will create 3 different zones of different types.
-- 100 groups of 1 unit will be spawned.
-- The test is about testing the zone randomization, and the place where the units are created.


local Iterations = 100
local Iteration = 1


local ZoneUnit = UNIT:FindByName( "ZoneUnit" )
local ZonePolygonGroup = GROUP:FindByName( "ZonePolygon" )

local SpawnZones = { 
  ZONE:New( "GroundZone1" ):SetZoneProbability( 0.2 ), 
  ZONE_UNIT:New( "GroundZone2", ZoneUnit, 1000 ):SetZoneProbability( 0.6 ), 
  ZONE_POLYGON:New( "GroundZone3", ZonePolygonGroup ):SetZoneProbability( 0.8 ) 
  }

HeightLimit = 500

SpawnGrounds = SPAWN:New("Ground"):InitLimit( 100, 100 ):InitRandomizeZones( SpawnZones )

--- Spawns these groups slowly.
SCHEDULER:New( nil,

  function( Interation, Iterations )
    do
      -- Spawn Ground
      SpawnGrounds:Spawn()
    end
    
  end, {}, 0, 1, 0 
)
