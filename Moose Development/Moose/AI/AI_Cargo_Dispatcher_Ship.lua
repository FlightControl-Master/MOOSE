--- **AI** -- (2.5.1) - Models the intelligent transportation of infantry and other cargo using Ships

-- @field #AI_CARGO_DISPATCHER_SHIP
AI_CARGO_DISPATCHER_SHIP = {
    ClassName = "AI_CARGO_DISPATCHER_SHIP"
  }
  
  function AI_CARGO_DISPATCHER_SHIP:New( ShipSet, CargoSet, PickupZoneSet, DeployZoneSet, ShippingLane )
  
    local self = BASE:Inherit( self, AI_CARGO_DISPATCHER:New( ShipSet, CargoSet, PickupZoneSet, DeployZoneSet ) )
  
    self:SetPickupSpeed( 60, 10 )
    self:SetDeploySpeed( 60, 10 )
  
    self:SetPickupRadius( 500, 3000 )
    self:SetDeployRadius( 500, 3000 )
  
    self:SetPickupHeight( 0, 0 )
    self:SetDeployHeight( 0, 0 )
  
    self:SetShippingLane( ShippingLane )
  
    self:SetMonitorTimeInterval( 600 )
  
    return self
  end
  
  function AI_CARGO_DISPATCHER_SHIP:SetShippingLane( ShippingLane )
    self.ShippingLane = ShippingLane
  
    return self
  
  end
  
  function AI_CARGO_DISPATCHER_SHIP:AICargo( Ship, CargoSet )
  
    return AI_CARGO_SHIP:New( Ship, CargoSet, 0, self.ShippingLane )
  end