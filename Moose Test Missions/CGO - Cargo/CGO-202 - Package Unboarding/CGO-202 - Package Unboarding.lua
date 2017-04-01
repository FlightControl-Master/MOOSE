
CargoEngineer = UNIT:FindByName( "Engineer" )
InfantryCargo = AI_CARGO_UNIT:New( CargoEngineer, "Engineer", "Engineer Sven", "81", 2000, 25 )

CargoCarrier = UNIT:FindByName( "Carrier" )

-- This will Load the Cargo into the Carrier, regardless where the Cargo is.
InfantryCargo:Load( CargoCarrier )

-- This will Unboard the Cargo from the Carrier.
-- The Cargo will run from the Carrier to a point in the NearRadius around the Carrier.
-- Unboard the Cargo with a speed of 10 km/h, go to 200 meters 180 degrees from the Carrier, iin a zone of 25 meters (NearRadius).
InfantryCargo:UnBoard( 10, 2, 20, 10, 180 )