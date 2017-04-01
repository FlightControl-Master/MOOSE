-- This test will create 3 different zones of different types.
-- 100 groups of 1 unit will be spawned.
-- The test is about testing the zone randomization, and the place where the units are created.

local Iterations = 100
local Iteration = 1

-- The PolygonGroup route defines zone 1
ZonePolygonGroup = GROUP:FindByName( "ZonePolygon" )

-- The ZoneUnit defines zone 4.
ZoneUnit = UNIT:FindByName( "ZoneUnit" )

-- The ZoneGroup defines zone 5
ZoneGroup = GROUP:FindByName( "ZoneGroup" )

-- This is the array that models the different zones types.
-- The selection of the zones is done by taking into account the probability of the zone.
-- The zone probabibility is 0 = 0%, 1 = 100%
-- The default value of the probability is 1.
-- Note that the SetZoneProbability is a method, that returns the self object of the zone, 
-- allowing to use the method within the zone array declaration!
local SpawnZones = { 
  ZONE_POLYGON:New( "Zone 1", ZonePolygonGroup ):SetZoneProbability( 0.8 ),
  ZONE_RADIUS:New( "Zone 2", ZONE:New( "GroundZone2" ):GetVec2(), 5000 ):SetZoneProbability( 0.2 ),
  ZONE:New( "GroundZone3" ):SetZoneProbability( 0.2 ), 
  ZONE_UNIT:New( "Zone 4", ZoneUnit, 5000 ):SetZoneProbability( 0.6 ), 
  ZONE_GROUP:New( "Zone 5", ZoneGroup, 5000 ):SetZoneProbability( 0.4 ),
  }

HeightLimit = 500

SpawnGrounds = SPAWN
  :New("Ground")
  :InitLimit( 100, 100 )
  -- This method will randomize the selection of the zones for each spawned Group during initialization,
  -- taking into account the probability factors.
  -- When you explore the code behind this method, you'll see that the GetZoneMaybe() method is used to select "maybe" the zone.
  :InitRandomizeZones( SpawnZones ) 

--- Spawns these groups slowly.
SCHEDULER:New( nil,

  function( Interation, Iterations )
    do
      -- Spawn Ground
      SpawnGrounds:Spawn()
    end
    
  end, {}, 0, 1, 0 
)
