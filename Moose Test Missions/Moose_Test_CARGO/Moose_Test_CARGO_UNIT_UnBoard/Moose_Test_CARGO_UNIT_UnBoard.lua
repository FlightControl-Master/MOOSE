
local Mission = MISSION:New( "Transfer Cargo", "High", "Test for Cargo", coalition.side.RED )

local CargoEngineer = UNIT:FindByName( "Engineer" )
local InfantryCargo = CARGO_UNIT:New( Mission, CargoEngineer, "Engineer", "Engineer Sven", "81", 2000, 25 )

local CargoCarrier = UNIT:FindByName( "Carrier" )

-- This will Load immediately the Cargo into the Carrier, regardless where the Cargo is.
InfantryCargo:Load( CargoCarrier )

-- This will Unboard the Cargo from the Carrier.
InfantryCargo:UnBoard()