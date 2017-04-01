
DeliveryUnit = UNIT:FindByName( "Delivery" )
Letter = AI_CARGO_PACKAGE:New( DeliveryUnit, "Letter", "Secret Orders", "0.3", 2000, 25 )

CargoCarrier = UNIT:FindByName( "Carrier" )

-- This call will make the Cargo run to the CargoCarrier.
-- Upon arrival at the CargoCarrier, the Cargo will be Loaded into the Carrier.
-- This process is now fully automated.
Letter:Board( CargoCarrier, 40, 3, 25, 90 ) 

