
local CargoSet = SET_BASE:New()
CargoSet:Add( "Engineer1", AI_CARGO_UNIT:New( UNIT:FindByName( "Engineer1" ), "Engineers", "Engineer", 81, 2000, 25 ) )
CargoSet:Add( "Engineer2", AI_CARGO_UNIT:New( UNIT:FindByName( "Engineer2" ), "Engineers", "Engineer", 64, 2000, 25 ) )
CargoSet:Add( "Engineer3", AI_CARGO_UNIT:New( UNIT:FindByName( "Engineer3" ), "Engineers", "Engineer", 72, 2000, 25 ) )
CargoSet:Add( "Engineer4", AI_CARGO_UNIT:New( UNIT:FindByName( "Engineer4" ), "Engineers", "Engineer", 69, 2000, 25 ) )

local InfantryCargo = AI_CARGO_GROUPED:New( CargoSet, "Engineers", "Engineers", 2000, 25 )

local CargoCarrier = UNIT:FindByName( "Carrier" )

-- This call will make the Cargo run to the CargoCarrier.
-- Upon arrival at the CargoCarrier, the Cargo will be Loaded into the Carrier.
-- This process is now fully automated.
InfantryCargo:Board( CargoCarrier ) 

