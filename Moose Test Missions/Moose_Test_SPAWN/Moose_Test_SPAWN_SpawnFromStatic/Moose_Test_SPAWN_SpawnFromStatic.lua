
local Iterations = 10
local Iteration = 1

GroundStatics = { "GroundStatic1", "GroundStatic2", "GroundStatic3" }
AirplaneStatics = { "AirplaneStatic1", "AirplaneStatic2", "AirplaneStatic3" }
HelicopterStatics = { "HelicopterStatic1", "HelicopterStatic2", "HelicopterStatic3" }
ShipStatics = { "ShipStatic1", "ShipStatic2", "ShipStatic3" }

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
      local StaticName = GroundStatics[ math.random( 1, 3 ) ]
      local SpawnStatic = STATIC:FindByName( StaticName )
      SpawnGrounds:SpawnFromUnit( SpawnStatic, 500, 100 )  
    end
    
    do
      -- Spawn Airplanes
      local StaticName = AirplaneStatics[ math.random( 1, 3 ) ]
      local SpawnStatic = STATIC:FindByName( StaticName )
      SpawnAirplanes:SpawnFromUnit( SpawnStatic, 500, 100 )  
    end
    
    do
      -- Spawn Helicopters
      local StaticName = HelicopterStatics[ math.random( 1, 3 ) ]
      local SpawnStatic = STATIC:FindByName( StaticName )
      SpawnHelicopters:SpawnFromUnit( SpawnStatic, 500, 100 )  
    end
    
    do
      -- Spawn Ships
      local StaticName = ShipStatics[ math.random( 1, 3 ) ]
      local SpawnStatic = STATIC:FindByName( StaticName )
      SpawnShips:SpawnFromUnit( SpawnStatic, 500, 100 )  
    end
    
  end, {}, 0, 15, 0.5 
)
