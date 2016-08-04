
local Mission = MISSION:New( "Pickup Cargo", "High", "Test for Cargo Pickup", coalition.side.RED )

local CargoEngineer = UNIT:FindByName( "Engineer" )
local InfantryCargo = CARGO_UNIT:New( Mission, CargoEngineer, "Engineer", "Engineer Sven", "81", 2000, 300 )

local CargoCarrier = UNIT:FindByName( "CargoCarrier" )
InfantryCargo:OnBoard( CargoCarrier )