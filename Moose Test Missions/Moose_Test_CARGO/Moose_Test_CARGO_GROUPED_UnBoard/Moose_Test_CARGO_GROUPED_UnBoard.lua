
local Mission = MISSION:New( "Transfer Cargo", "High", "Test for Cargo", coalition.side.RED )

local CargoSet = SET_BASE:New()
CargoSet:Add( "Engineer1", CARGO_UNIT:New( Mission, UNIT:FindByName( "Engineer1" ), "Engineers", "Engineer", 81, 2000, 25 ) )
CargoSet:Add( "Engineer2", CARGO_UNIT:New( Mission, UNIT:FindByName( "Engineer2" ), "Engineers", "Engineer", 64, 2000, 25 ) )
CargoSet:Add( "Engineer3", CARGO_UNIT:New( Mission, UNIT:FindByName( "Engineer3" ), "Engineers", "Engineer", 72, 2000, 25 ) )
CargoSet:Add( "Engineer4", CARGO_UNIT:New( Mission, UNIT:FindByName( "Engineer4" ), "Engineers", "Engineer", 69, 2000, 25 ) )

local InfantryCargo = CARGO_GROUPED:New( CargoSet, "Engineers", "Engineers", 2000, 25 )

local CargoCarrier = UNIT:FindByName( "Carrier" )

-- This will Load immediately the Cargo into the Carrier, regardless where the Cargo is.
InfantryCargo:Load( CargoCarrier )

-- This will Unboard the Cargo from the Carrier.
InfantryCargo:UnBoard()