
local Iterations = 10
local Iteration = 1

GroundUnits = { "GroundUnit1", "GroundUnit2", "GroundUnit3" }
AirplaneUnits = { "AirplaneUnit1", "AirplaneUnit2", "AirplaneUnit3" }
HelicopterUnits = { "HelicopterUnit1", "HelicopterUnit2", "HelicopterUnit3" }
ShipUnits = { "ShipUnit1", "ShipUnit2", "ShipUnit3" }

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
      local UnitName = GroundUnits[ math.random( 1, 3 ) ]
      local SpawnUnit = UNIT:FindByName( UnitName )
      SpawnGrounds:SpawnFromUnit( SpawnUnit, 10, 3 )  
    end
    
    do
      -- Spawn Airplanes
      local UnitName = AirplaneUnits[ math.random( 1, 3 ) ]
      local SpawnUnit = UNIT:FindByName( UnitName )
      SpawnAirplanes:SpawnFromUnit( SpawnUnit )  
    end
    
    do
      -- Spawn Helicopters
      local UnitName = HelicopterUnits[ math.random( 1, 3 ) ]
      local SpawnUnit = UNIT:FindByName( UnitName )
      SpawnHelicopters:SpawnFromUnit( SpawnUnit )  
    end
    
    do
      -- Spawn Ships
      local UnitName = ShipUnits[ math.random( 1, 3 ) ]
      local SpawnUnit = UNIT:FindByName( UnitName )
      SpawnShips:SpawnFromUnit( SpawnUnit )  
    end
    
  end, {}, 0, 15, 0.5 
)
