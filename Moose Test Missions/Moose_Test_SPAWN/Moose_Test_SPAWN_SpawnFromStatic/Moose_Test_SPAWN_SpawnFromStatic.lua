
local Iterations = 10
local Iteration = 1

GroundStatics = { "GroundStatic1", "GroundStatic2", "GroundStatic3" }
AirplaneStatics = { "AirplaneStatic1", "AirplaneStatic2", "AirplaneStatic3" }
HelicopterStatics = { "HelicopterStatic1", "HelicopterStatic2", "HelicopterStatic3" }
ShipStatics = { "ShipStatic1", "ShipStatic2", "ShipStatic3" }

HeightLimit = 500

SpawnGrounds = SPAWN:New("Ground"):InitLimit( 20, 10 ):InitRandomizeUnits( true, 500, 100 )
SpawnAirplanes = SPAWN:New("Airplane"):InitLimit( 20, 10 ):InitRandomizeUnits( true, 500, 100 )
SpawnHelicopters = SPAWN:New("Helicopter"):InitLimit( 20, 10 ):InitRandomizeUnits( true, 500, 100 )
SpawnShips = SPAWN:New("Ship"):InitLimit( 20, 10 ):InitRandomizeUnits( true, 500, 100 )

--- Spawns these groups slowly.
SCHEDULER:New( nil,

  function( Interation, Iterations )
    do
      -- Spawn Ground
      local StaticName = GroundStatics[ math.random( 1, 3 ) ]
      local SpawnStatic = STATIC:FindByName( StaticName )
      SpawnGrounds:SpawnFromUnit( SpawnStatic )  
    end
    
    do
      -- Spawn Airplanes
      local StaticName = AirplaneStatics[ math.random( 1, 3 ) ]
      local SpawnStatic = STATIC:FindByName( StaticName )
      SpawnAirplanes:SpawnFromUnit( SpawnStatic )  
    end
    
    do
      -- Spawn Helicopters
      local StaticName = HelicopterStatics[ math.random( 1, 3 ) ]
      local SpawnStatic = STATIC:FindByName( StaticName )
      SpawnHelicopters:SpawnFromUnit( SpawnStatic )  
    end
    
    do
      -- Spawn Ships
      local StaticName = ShipStatics[ math.random( 1, 3 ) ]
      local SpawnStatic = STATIC:FindByName( StaticName )
      SpawnShips:SpawnFromUnit( SpawnStatic )  
    end
    
  end, {}, 0, 15, 0.5 
)
