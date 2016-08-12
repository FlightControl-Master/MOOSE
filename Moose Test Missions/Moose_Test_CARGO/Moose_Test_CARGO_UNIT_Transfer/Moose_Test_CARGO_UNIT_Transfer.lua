
local Mission = MISSION:New( "Transfer Cargo", "High", "Test for Cargo", coalition.side.RED )

local CargoEngineer = UNIT:FindByName( "Engineer" )
local InfantryCargo = CARGO_UNIT:New( Mission, CargoEngineer, "Engineer", "Engineer Sven", "81", 2000, 25 )

local CargoCarrierFrom = UNIT:FindByName( "CarrierFrom" )

local CargoCarrierTo = UNIT:FindByName( "CarrierTo" )

-- This call will make the Cargo run to the CargoCarrier.
-- Upon arrival at the CargoCarrier, the Cargo will be Loaded into the Carrier.
-- This process is now fully automated.
InfantryCargo:Board( CargoCarrierFrom )

-- Once the Cargo has been loaded into the Carrier, drive to a point and unload the Cargo.
InfantryCargo:OnLoaded( 
  function( Cargo ) 
    Cargo:UnLoad() 
  end 
)

-- Once the Cargo has been unloaded from the Carrier (the Cargo has arrived to the unload gathering point), OnBoard the Cargo in the other Carrier.
InfantryCargo:OnUnLoaded( 
  function( Cargo ) 
    Cargo:Board( CargoCarrierTo ) 
  end 
)
