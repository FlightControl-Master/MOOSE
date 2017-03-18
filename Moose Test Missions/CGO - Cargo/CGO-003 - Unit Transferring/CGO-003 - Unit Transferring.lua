
CargoEngineer = UNIT:FindByName( "Engineer" )
InfantryCargo = AI_CARGO_UNIT:New( CargoEngineer, "Engineer", "Engineer Sven", "81", 2000, 25 )

CargoCarrierFrom = UNIT:FindByName( "CarrierFrom" )

CargoCarrierTo = UNIT:FindByName( "CarrierTo" )

-- This call will make the Cargo run to the CargoCarrier.
-- Upon arrival at the CargoCarrier, the Cargo will be Loaded into the Carrier.
-- This process is now fully automated.
InfantryCargo:Board( CargoCarrierFrom )

-- Once the Cargo has been loaded into the Carrier, drive to a point and unload the Cargo.
function InfantryCargo:OnEnterLoaded()  
  self:__UnBoard( 1 )
  self.OnEnterLoaded = nil
end

-- Once the Cargo has been unloaded from the Carrier (the Cargo has arrived to the unload gathering point), OnBoard the Cargo in the other Carrier.
function InfantryCargo:OnEnterUnLoaded() 
  self:__Board( 1, CargoCarrierTo )
  self.OnEnterUnLoaded = nil
end

