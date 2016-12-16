
local CargoEngineer = UNIT:FindByName( "Engineer" )
local InfantryCargo = AI_CARGO_UNIT:New( CargoEngineer, "Engineer", "Engineer Sven", "81", 2000, 25 )

local CargoCarrier = UNIT:FindByName( "Carrier" )

-- This will Load immediately the Cargo into the Carrier, regardless where the Cargo is.
InfantryCargo:Load( CargoCarrier )

-- This will Unboard the Cargo from the Carrier.
InfantryCargo:UnBoard()