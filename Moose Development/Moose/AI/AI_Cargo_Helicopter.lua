--- **AI** -- (R2.3) - Models the intelligent transportation of infantry (cargo).
--
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ===       
--
-- @module AI_Cargo_Helicopter

--- @type AI_CARGO_HELICOPTER
-- @extends Core.Fsm#FSM_CONTROLLABLE


--- # AI\_CARGO\_TROOPS class, extends @{Core.Base@BASE}
-- 
-- ===
-- 
-- @field #AI_CARGO_HELICOPTER
AI_CARGO_HELICOPTER = {
  ClassName = "AI_CARGO_HELICOPTER",
  Coordinate = nil -- Core.Point#COORDINATE,
}

--- Creates a new AI_CARGO_HELICOPTER object.
-- @param #AI_CARGO_HELICOPTER self
-- @param Wrapper.Unit#UNIT CargoCarrier
-- @param Cargo.CargoGroup#CARGO_GROUP CargoGroup
-- @param #number CombatRadius
-- @return #AI_CARGO_HELICOPTER
function AI_CARGO_HELICOPTER:New( CargoCarrier, CargoGroup )

  local self = BASE:Inherit( self, FSM_CONTROLLABLE:New() ) -- #AI_CARGO_HELICOPTER

  self.CargoGroup = CargoGroup -- Cargo.CargoGroup#CARGO_GROUP

  self:SetStartState( "UnLoaded" ) 
  
  self:AddTransition( "*", "Load", "Boarding" )
  self:AddTransition( "Boarding", "Board", "Boarding" )
  self:AddTransition( "Boarding", "Loaded", "Loaded" )
  self:AddTransition( "Loaded", "Unload", "Unboarding" )
  self:AddTransition( "Unboarding", "Unboard", "Unboarding" )
  self:AddTransition( "Unboarding", "Unloaded", "Unloaded" )

  self:AddTransition( "*", "Landed", "*" )
  
  self:AddTransition( "*", "Destroyed", "Destroyed" )

  self:__Monitor( 1 )

  self:SetCarrier( CargoCarrier )
  
  return self
end


--- Set the Carrier.
-- @param #AI_CARGO_HELICOPTER self
-- @param Wrapper.Unit#UNIT CargoCarrier
-- @return #AI_CARGO_HELICOPTER
function AI_CARGO_HELICOPTER:SetCarrier( CargoCarrier )

  self.CargoCarrier = CargoCarrier -- Wrapper.Unit#UNIT
  self.CargoCarrier:SetState( self.CargoCarrier, "AI_CARGO_HELICOPTER", self )

  CargoCarrier:HandleEvent( EVENTS.Dead )
  CargoCarrier:HandleEvent( EVENTS.Hit )
  CargoCarrier:HandleEvent( EVENTS.Land )
  
  function CargoCarrier:OnEventDead( EventData )
    local AICargoTroops = self:GetState( self, "AI_CARGO_HELICOPTER" )
    self:F({AICargoTroops=AICargoTroops})
    if AICargoTroops then
      self:F({})
      if not AICargoTroops:Is( "Loaded" ) then
        -- There are enemies within combat range. Unload the CargoCarrier.
        AICargoTroops:Destroyed()
      end
    end
  end
  
  
  function CargoCarrier:OnEventHit( EventData )
    local AICargoTroops = self:GetState( self, "AI_CARGO_HELICOPTER" )
    if AICargoTroops then
      self:F( { OnHitLoaded = AICargoTroops:Is( "Loaded" ) } )
      if AICargoTroops:Is( "Loaded" ) or AICargoTroops:Is( "Boarding" ) then
        -- There are enemies within combat range. Unload the CargoCarrier.
        AICargoTroops:Unload()
      end
    end
  end
  
  
  function CargoCarrier:OnEventLand( EventData )
    self:Landed()
  end
  
  self.Zone = ZONE_UNIT:New( self.CargoCarrier:GetName() .. "-Zone", self.CargoCarrier, 500 )
  self.Coalition = self.CargoCarrier:GetCoalition()
  
  self:SetControllable( CargoCarrier )

  self:Guard()

  return self
end


--- Find a free Carrier within a range.
-- @param #AI_CARGO_HELICOPTER self
-- @param Core.Point#COORDINATE Coordinate
-- @param #number Radius
-- @return Wrapper.Unit#UNIT NewCarrier
function AI_CARGO_HELICOPTER:FindCarrier( Coordinate, Radius )

  local CoordinateZone = ZONE_RADIUS:New( "Zone" , Coordinate:GetVec2(), Radius )
  CoordinateZone:Scan( { Object.Category.UNIT } )
  for _, DCSUnit in pairs( CoordinateZone:GetScannedUnits() ) do
    local NearUnit = UNIT:Find( DCSUnit )
    self:F({NearUnit=NearUnit})
    if not NearUnit:GetState( NearUnit, "AI_CARGO_HELICOPTER" ) then
      local Attributes = NearUnit:GetDesc()
      self:F({Desc=Attributes})
      if NearUnit:HasAttribute( "Trucks" ) then
        self:SetCarrier( NearUnit )
        break
      end
    end
  end

end


--- @param #AI_CARGO_HELICOPTER self
-- @param Wrapper.Unit#UNIT CargoCarrier
function AI_CARGO_HELICOPTER:onafterLoad( CargoCarrier, From, Event, To )

  if CargoCarrier and CargoCarrier:IsAlive() then
    self:__Board( 10 ) 
    self.CargoGroup:Board( CargoCarrier, 10 )
  end
  
end

--- @param #AI_CARGO_HELICOPTER self
-- @param Wrapper.Unit#UNIT CargoCarrier
function AI_CARGO_HELICOPTER:onafterBoard( CargoCarrier, From, Event, To )

  if CargoCarrier and CargoCarrier:IsAlive() then
    self:F({ IsLoaded = self.CargoGroup:IsLoaded() } )
    if not self.CargoGroup:IsLoaded() then
      self:__Board( 10 )
    else
      self:__Loaded( 1 )
    end
  end
  
end

--- @param #AI_CARGO_HELICOPTER self
-- @param Wrapper.Unit#UNIT CargoCarrier
function AI_CARGO_HELICOPTER:onafterLoaded( CargoCarrier, From, Event, To )

  if CargoCarrier and CargoCarrier:IsAlive() then
    CargoCarrier:RouteResume()
  end
  
end


--- @param #AI_CARGO_HELICOPTER self
-- @param Wrapper.Unit#UNIT CargoCarrier
function AI_CARGO_HELICOPTER:onafterUnload( CargoCarrier, From, Event, To )

  if CargoCarrier and CargoCarrier:IsAlive() then
    CargoCarrier:RouteStop()
    self.CargoGroup:UnBoard( )
    self:__Unboard( 10 ) 
  end
  
end

--- @param #AI_CARGO_HELICOPTER self
-- @param Wrapper.Unit#UNIT CargoCarrier
function AI_CARGO_HELICOPTER:onafterUnboard( CargoCarrier, From, Event, To )

  if CargoCarrier and CargoCarrier:IsAlive() then
    if not self.CargoGroup:IsUnLoaded() then
      self:__Unboard( 10 ) 
    else
      self:__Unloaded( 1 )
    end
  end
  
end

--- @param #AI_CARGO_HELICOPTER self
-- @param Wrapper.Unit#UNIT CargoCarrier
function AI_CARGO_HELICOPTER:onafterUnloaded( CargoCarrier, From, Event, To )

  if CargoCarrier and CargoCarrier:IsAlive() then
    self.CargoCarrier = CargoCarrier
  end
  
end


