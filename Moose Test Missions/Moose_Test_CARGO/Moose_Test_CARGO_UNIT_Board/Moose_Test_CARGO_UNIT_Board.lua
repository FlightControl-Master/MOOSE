
local Mission = MISSION:New( "Transfer Cargo", "High", "Test for Cargo", coalition.side.RED )

local CargoEngineer = UNIT:FindByName( "Engineer" )
local InfantryCargo = CARGO_UNIT:New( Mission, CargoEngineer, "Engineer", "Engineer Sven", "81", 2000, 25 )

local CargoCarrier = UNIT:FindByName( "Carrier" )

-- This call will make the Cargo run to the CargoCarrier.
-- Upon arrival at the CargoCarrier, the Cargo will be Loaded into the Carrier.
-- This process is now fully automated.
InfantryCargo:Board( CargoCarrier ) 

