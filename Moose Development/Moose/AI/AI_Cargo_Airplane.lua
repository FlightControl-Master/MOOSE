--- **AI** -- (R2.3) - Models the intelligent transportation of infantry (cargo).
--
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ===       
--
-- @module AI_Cargo_Airplane

--- @type AI_CARGO_AIRPLANE
-- @extends Core.Fsm#FSM_CONTROLLABLE


--- # AI\_CARGO\_AIRPLANE class, extends @{Core.Base@BASE}
-- 
-- ===
-- 
-- @field #AI_CARGO_AIRPLANE
AI_CARGO_AIRPLANE = {
  ClassName = "AI_CARGO_AIRPLANE",
  Coordinate = nil -- Core.Point#COORDINATE,
}

--- Creates a new AI_CARGO_AIRPLANE object.
-- @param #AI_CARGO_AIRPLANE self
-- @param Wrapper.Unit#UNIT Airplane
-- @param Core.Set#SET_CARGO CargoSet
-- @param #number CombatRadius
-- @return #AI_CARGO_AIRPLANE
function AI_CARGO_AIRPLANE:New( Airplane, CargoSet )

  local self = BASE:Inherit( self, FSM_CONTROLLABLE:New() ) -- #AI_CARGO_AIRPLANE

  self.CargoSet = CargoSet -- Cargo.CargoGroup#CARGO_GROUP

  self:SetStartState( "Unloaded" ) 
  
  self:AddTransition( "Unloaded", "Pickup", "*" )
  self:AddTransition( "Loaded", "Deploy", "*" )
  
  self:AddTransition( "Unloaded", "Load", "Boarding" )
  self:AddTransition( "Boarding", "Board", "Boarding" )
  self:AddTransition( "Boarding", "Loaded", "Loaded" )
  self:AddTransition( "Loaded", "Unload", "Unboarding" )
  self:AddTransition( "Unboarding", "Unboard", "Unboarding" )
  self:AddTransition( "Unboarding", "Unloaded", "Unloaded" )

  self:AddTransition( "*", "Landed", "*" )
  
  self:AddTransition( "*", "Destroyed", "Destroyed" )

  --- Pickup Handler OnBefore for AI_CARGO_AIRPLANE
  -- @function [parent=#AI_CARGO_AIRPLANE] OnBeforePickup
  -- @param #AI_CARGO_AIRPLANE self
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param Wrapper.Airbase#AIRBASE Airbase
  -- @return #boolean
  
  --- Pickup Handler OnAfter for AI_CARGO_AIRPLANE
  -- @function [parent=#AI_CARGO_AIRPLANE] OnAfterPickup
  -- @param #AI_CARGO_AIRPLANE self
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param Wrapper.Airbase#AIRBASE Airbase
  
  --- Pickup Trigger for AI_CARGO_AIRPLANE
  -- @function [parent=#AI_CARGO_AIRPLANE] Pickup
  -- @param #AI_CARGO_AIRPLANE self
  -- @param Wrapper.Airbase#AIRBASE Airbase
  
  --- Pickup Asynchronous Trigger for AI_CARGO_AIRPLANE
  -- @function [parent=#AI_CARGO_AIRPLANE] __Pickup
  -- @param #AI_CARGO_AIRPLANE self
  -- @param #number Delay
  -- @param Wrapper.Airbase#AIRBASE Airbase
  
  --- Deploy Handler OnBefore for AI_CARGO_AIRPLANE
  -- @function [parent=#AI_CARGO_AIRPLANE] OnBeforeDeploy
  -- @param #AI_CARGO_AIRPLANE self
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param Wrapper.Airbase#AIRBASE Airbase
  -- @return #boolean
  
  --- Deploy Handler OnAfter for AI_CARGO_AIRPLANE
  -- @function [parent=#AI_CARGO_AIRPLANE] OnAfterDeploy
  -- @param #AI_CARGO_AIRPLANE self
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param Wrapper.Airbase#AIRBASE Airbase
  
  --- Deploy Trigger for AI_CARGO_AIRPLANE
  -- @function [parent=#AI_CARGO_AIRPLANE] Deploy
  -- @param #AI_CARGO_AIRPLANE self
  -- @param Wrapper.Airbase#AIRBASE Airbase
  
  --- Deploy Asynchronous Trigger for AI_CARGO_AIRPLANE
  -- @function [parent=#AI_CARGO_AIRPLANE] __Deploy
  -- @param #AI_CARGO_AIRPLANE self
  -- @param Wrapper.Airbase#AIRBASE Airbase
  -- @param #number Delay


  self:SetCarrier( Airplane )
  
  return self
end


--- Set the Carrier.
-- @param #AI_CARGO_AIRPLANE self
-- @param Wrapper.Unit#UNIT Airplane
-- @return #AI_CARGO_AIRPLANE
function AI_CARGO_AIRPLANE:SetCarrier( Airplane )

  local AICargo = self

  self.Airplane = Airplane -- Wrapper.Unit#UNIT
  self.Airplane:SetState( self.Airplane, "AI_CARGO_AIRPLANE", self )

  self.RoutePickup = false
  self.RouteDeploy = false

  Airplane:HandleEvent( EVENTS.Dead )
  Airplane:HandleEvent( EVENTS.Hit )
  Airplane:HandleEvent( EVENTS.EngineShutdown )
  
  function Airplane:OnEventDead( EventData )
    local AICargoTroops = self:GetState( self, "AI_CARGO_AIRPLANE" )
    self:F({AICargoTroops=AICargoTroops})
    if AICargoTroops then
      self:F({})
      if not AICargoTroops:Is( "Loaded" ) then
        -- There are enemies within combat range. Unload the Airplane.
        AICargoTroops:Destroyed()
      end
    end
  end
  
  
  function Airplane:OnEventHit( EventData )
    local AICargoTroops = self:GetState( self, "AI_CARGO_AIRPLANE" )
    if AICargoTroops then
      self:F( { OnHitLoaded = AICargoTroops:Is( "Loaded" ) } )
      if AICargoTroops:Is( "Loaded" ) or AICargoTroops:Is( "Boarding" ) then
        -- There are enemies within combat range. Unload the Airplane.
        AICargoTroops:Unload()
      end
    end
  end
  
  
  function Airplane:OnEventEngineShutdown( EventData )
    AICargo:Landed()
  end
  
  self.Coalition = self.Airplane:GetCoalition()
  
  self:SetControllable( Airplane )

  return self
end


--- Find a free Carrier within a range.
-- @param #AI_CARGO_AIRPLANE self
  -- @param Wrapper.Airbase#AIRBASE Airbase
-- @param #number Radius
-- @return Wrapper.Unit#UNIT NewCarrier
function AI_CARGO_AIRPLANE:FindCarrier( Coordinate, Radius )

  local CoordinateZone = ZONE_RADIUS:New( "Zone" , Coordinate:GetVec2(), Radius )
  CoordinateZone:Scan( { Object.Category.UNIT } )
  for _, DCSUnit in pairs( CoordinateZone:GetScannedUnits() ) do
    local NearUnit = UNIT:Find( DCSUnit )
    self:F({NearUnit=NearUnit})
    if not NearUnit:GetState( NearUnit, "AI_CARGO_AIRPLANE" ) then
      local Attributes = NearUnit:GetDesc()
      self:F({Desc=Attributes})
      if NearUnit:HasAttribute( "Trucks" ) then
        self:SetCarrier( NearUnit )
        break
      end
    end
  end

end

--- @param #AI_CARGO_AIRPLANE self
-- @param Wrapper.Unit#UNIT Airplane
-- @param From
-- @param Event
-- @param To
  -- @param Wrapper.Airbase#AIRBASE Airbase
-- @param #number Speed
function AI_CARGO_AIRPLANE:onafterLanded( Airplane, From, Event, To )

  if Airplane and Airplane:IsAlive() then

    if self.RoutePickup == true then
      self:Load( Airplane:GetPointVec2() )
      self.RoutePickup = false
    end
    
    if self.RouteDeploy == true then
      self:Unload()
      self.RouteDeploy = false
    end
     
  end
  
end



--- @param #AI_CARGO_AIRPLANE self
-- @param Wrapper.Group#GROUP Airplane
-- @param From
-- @param Event
-- @param To
-- @param Wrapper.Airbase#AIRBASE Airbase
-- @param #number Speed
function AI_CARGO_AIRPLANE:onafterPickup( Airplane, From, Event, To, Airbase, Speed )

  if Airplane and Airplane:IsAlive() then

    self.RoutePickup = true
     
    Airplane:RouteRTB( Airbase, Speed)
  end
  
end


--- @param #AI_CARGO_AIRPLANE self
-- @param Wrapper.Unit#UNIT Airplane
-- @param From
-- @param Event
-- @param To
  -- @param Wrapper.Airbase#AIRBASE Airbase
-- @param #number Speed
function AI_CARGO_AIRPLANE:onafterDeploy( Airplane, From, Event, To, Coordinate, Speed )

  if Airplane and Airplane:IsAlive() then

    self.RouteDeploy = true
     
    Airplane:RouteRTB( Airbase, Speed)
  end
  
end


--- @param #AI_CARGO_AIRPLANE self
-- @param Wrapper.Unit#UNIT Airplane
function AI_CARGO_AIRPLANE:onafterLoad( Airplane, From, Event, To, Coordinate )

  if Airplane and Airplane:IsAlive() then
  
    for _, Cargo in pairs( self.CargoSet:GetSet() ) do
      if Cargo:IsInLoadRadius( Coordinate ) then
        self:__Board( 5 )
        Cargo:Board( Airplane, 25 )
        self.Cargo = Cargo
        break
      end
    end
  end
  
end

--- @param #AI_CARGO_AIRPLANE self
-- @param Wrapper.Unit#UNIT Airplane
function AI_CARGO_AIRPLANE:onafterBoard( Airplane, From, Event, To )

  if Airplane and Airplane:IsAlive() then
    self:F({ IsLoaded = self.Cargo:IsLoaded() } )
    if not self.Cargo:IsLoaded() then
      self:__Board( 10 )
    else
      self:__Loaded( 1 )
    end
  end
  
end

--- @param #AI_CARGO_AIRPLANE self
-- @param Wrapper.Unit#UNIT Airplane
function AI_CARGO_AIRPLANE:onafterLoaded( Airplane, From, Event, To )

  if Airplane and Airplane:IsAlive() then
  end
  
end


--- @param #AI_CARGO_AIRPLANE self
-- @param Wrapper.Unit#UNIT Airplane
function AI_CARGO_AIRPLANE:onafterUnload( Airplane, From, Event, To )

  if Airplane and Airplane:IsAlive() then
    self.Cargo:UnBoard()
    self:__Unboard( 10 ) 
  end
  
end

--- @param #AI_CARGO_AIRPLANE self
-- @param Wrapper.Unit#UNIT Airplane
function AI_CARGO_AIRPLANE:onafterUnboard( Airplane, From, Event, To )

  if Airplane and Airplane:IsAlive() then
    if not self.Cargo:IsUnLoaded() then
      self:__Unboard( 10 ) 
    else
      self:__Unloaded( 1 )
    end
  end
  
end

--- @param #AI_CARGO_AIRPLANE self
-- @param Wrapper.Unit#UNIT Airplane
function AI_CARGO_AIRPLANE:onafterUnloaded( Airplane, From, Event, To )

  if Airplane and Airplane:IsAlive() then
    self.Airplane = Airplane
  end
  
end


