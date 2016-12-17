
local CargoEngineer = UNIT:FindByName( "Engineer" )
local InfantryCargo = AI_CARGO_UNIT:New( CargoEngineer, "Engineer", "Engineer Sven", "81", 2000, 25 )

local CargoCarrier = UNIT:FindByName( "Carrier" )

-- This call will make the Cargo run to the CargoCarrier.
-- Upon arrival at the CargoCarrier, the Cargo will be Loaded into the Carrier.
-- This process is now fully automated.
InfantryCargo:Board( CargoCarrier ) 

