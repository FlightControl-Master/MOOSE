
CargoSet = SET_BASE:New()
CargoSet:Add( "Engineer1", AI_CARGO_UNIT:New( UNIT:FindByName( "Engineer1" ), "Engineers", "Engineer", 81, 2000, 25 ) )
CargoSet:Add( "Engineer2", AI_CARGO_UNIT:New( UNIT:FindByName( "Engineer2" ), "Engineers", "Engineer", 64, 2000, 25 ) )
CargoSet:Add( "Engineer3", AI_CARGO_UNIT:New( UNIT:FindByName( "Engineer3" ), "Engineers", "Engineer", 72, 2000, 25 ) )
CargoSet:Add( "Engineer4", AI_CARGO_UNIT:New( UNIT:FindByName( "Engineer4" ), "Engineers", "Engineer", 69, 2000, 25 ) )

InfantryCargo = AI_CARGO_GROUPED:New( CargoSet, "Engineers", "Engineers", 2000, 25 )

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
