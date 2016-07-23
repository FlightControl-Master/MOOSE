
local Iterations = 10
local Iteration = 1

GroundZones = { "GroundZone1", "GroundZone2", "GroundZone3" }
AirplaneZones = { "AirplaneZone1", "AirplaneZone2", "AirplaneZone3" }
HelicopterZones = { "HelicopterZone1", "HelicopterZone2", "HelicopterZone3" }
ShipZones = { "ShipZone1", "ShipZone2", "ShipZone3" }

HeightLimit = 500

SpawnGrounds = SPAWN:New("Ground"):Limit( 20, 10 )
SpawnAirplanes = SPAWN:New("Airplane"):Limit( 20, 10 )
SpawnHelicopters = SPAWN:New("Helicopter"):Limit( 20, 10 )
SpawnShips = SPAWN:New("Ship"):Limit( 20, 10 )

--- Spawns these groups slowly.
SCHEDULER:New( nil,

  function( Interation, Iterations )
    do
      -- Spawn Ground
      local ZoneName = GroundZones[ math.random( 1, 3 ) ]
      local SpawnVec3 = POINT_VEC3:NewFromVec3( ZONE:New( ZoneName ):GetPointVec3() )
      SpawnGrounds:SpawnFromVec3( SpawnVec3:GetVec3(), 500, 100 )  
    end
    
    do
      -- Spawn Airplanes
      local ZoneName = AirplaneZones[ math.random( 1, 3 ) ]
      local SpawnVec3 = POINT_VEC3:NewFromVec3( ZONE:New( ZoneName ):GetPointVec3() )
      SpawnAirplanes:SpawnFromVec3( SpawnVec3:GetVec3(), 500, 100 )  
    end
    
    do
      -- Spawn Helicopters
      local ZoneName = HelicopterZones[ math.random( 1, 3 ) ]
      local SpawnVec3 = POINT_VEC3:NewFromVec3( ZONE:New( ZoneName ):GetPointVec3() )
      SpawnHelicopters:SpawnFromVec3( SpawnVec3:GetVec3(), 500, 100 )  
    end
    
    do
      -- Spawn Ships
      local ZoneName = ShipZones[ math.random( 1, 3 ) ]
      local SpawnVec3 = POINT_VEC3:NewFromVec3( ZONE:New( ZoneName ):GetPointVec3() )
      SpawnShips:SpawnFromVec3( SpawnVec3:GetVec3(), 500, 100 )  
    end
    
  end, {}, 0, 15, 0.5 
)
