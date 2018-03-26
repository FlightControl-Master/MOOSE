--- **AI** -- (R2.3) - Models the intelligent transportation of infantry (cargo).
--
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ===       
--
-- @module AI_Cargo_Troops

--- @type AI_CARGO_TROOPS
-- @extends Core.Fsm#FSM_CONTROLLABLE


--- # AI\_CARGO\_TROOPS class, extends @{Core.Base@BASE}
-- 
-- ===
-- 
-- @field #AI_CARGO_TROOPS
AI_CARGO_TROOPS = {
  ClassName = "AI_CARGO_TROOPS",
  Coordinate = nil -- Core.Point#COORDINATE,
}

--- Creates a new AI_CARGO_TROOPS object
-- @param #AI_CARGO_TROOPS self
-- @return #AI_CARGO_TROOPS
function AI_CARGO_TROOPS:New( CargoCarrier, CargoGroup, CombatRadius )

  local self = BASE:Inherit( self, FSM_CONTROLLABLE:New( ) ) -- #AI_CARGO_TROOPS

  self.CargoCarrier = CargoCarrier -- Wrapper.Unit#UNIT
  self.CargoGroup = CargoGroup -- Core.Cargo#CARGO_GROUP
  self.CombatRadius = CombatRadius
  
  self.Zone = ZONE_UNIT:New( self.CargoCarrier:GetName() .. "-Zone", self.CargoCarrier, CombatRadius )
  self.Coalition = self.CargoCarrier:GetCoalition()
  
  self:SetControllable( self.CargoCarrier )

  self:SetStartState( "UnLoaded" ) 
  
  self:AddTransition( "*", "Load", "Boarding" )
  self:AddTransition( "Boarding", "Boarding", "Boarding" )
  self:AddTransition( "Boarding", "Loaded", "Loaded" )
  self:AddTransition( "Loaded", "Unload", "Unboarding" )
  self:AddTransition( "UnBoarding", "Unloaded", "Unloaded" )
  
  self:AddTransition( "*", "Monitor", "*" )

  self:__Monitor( 1 )
  self:__Load( 1 )
  
  return self
end


--- @param #AI_CARGO_TROOPS self
-- @param Wrapper.Unit#UNIT CargoCarrier
function AI_CARGO_TROOPS:onafterMonitor( CargoCarrier, From, Event, To )
  self:F( { CargoCarrier, From, Event, To } )

  if CargoCarrier and CargoCarrier:IsAlive() then
    if self.Coordinate then
      local Coordinate = CargoCarrier:GetCoordinate()
      if Coordinate:IsAtCoordinate2D( self.Coordinate, 2 ) then
        self.Zone:Scan( { Object.Category.UNIT } )
        if self.Zone:IsAllInZoneOfCoalition( self.Coalition ) then
        else
          if not self:Is( "Unloaded" ) then
            -- There are enemies within combat range. Unload the CargoCarrier.
            self:__Unload( 1 )
            self.CargoCarrier:RouteStop()
          end
        end
      end
    else
      self.Coordinate = CargoCarrier:GetCoordinate()
    end
  end
  
  self:__Monitor( 1 )

end


--- @param #AI_CARGO_TROOPS self
-- @param Wrapper.Unit#UNIT CargoCarrier
function AI_CARGO_TROOPS:onafterLoad( CargoCarrier, From, Event, To )
  self:F( { CargoCarrier, From, Event, To } )

  if CargoCarrier and CargoCarrier:IsAlive() then
    self.CargoGroup:__Board( 1, CargoCarrier, 100 )
    self:__Boarding( 1 ) 
  end
  
end

--- @param #AI_CARGO_TROOPS self
-- @param Wrapper.Unit#UNIT CargoCarrier
function AI_CARGO_TROOPS:onafterBoarding( CargoCarrier, From, Event, To )
  self:F( { CargoCarrier, From, Event, To } )

  if CargoCarrier and CargoCarrier:IsAlive() then
    if self.CargoGroup:IsBoarding() then
      self:__Boarding( 1 ) 
    end
    
    if self.CargoGroup:IsLoaded() then
      self:__Loaded( 1 )
    end
  end
  
end

--- @param #AI_CARGO_TROOPS self
-- @param Wrapper.Unit#UNIT CargoCarrier
function AI_CARGO_TROOPS:onafterLoaded( CargoCarrier, From, Event, To )
  self:F( { CargoCarrier, From, Event, To } )

  if CargoCarrier and CargoCarrier:IsAlive() then
    CargoCarrier:RouteStop()
  end
  
end

