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
  
  self:SetControllable( CargoCarrier )

  self:SetStartState( "UnLoaded" ) 
  
  self:AddTransition( "*", "Load", "Boarding" )
  self:AddTransition( "Boarding", "Board", "Boarding" )
  self:AddTransition( "Boarding", "Loaded", "Loaded" )
  self:AddTransition( "Loaded", "Unload", "Unboarding" )
  self:AddTransition( "Unboarding", "Unboard", "Unboarding" )
  self:AddTransition( "Unboarding", "Unloaded", "Unloaded" )
  
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
      self.Zone:Scan( { Object.Category.UNIT } )
      if self.Zone:IsAllInZoneOfCoalition( self.Coalition ) then
--        if self:Is( "Unloaded" ) then
--          -- There are no enemies within combat range. Load the CargoCarrier.
--          self:__Load( 1 )
--        end
      else
        if self:Is( "Loaded" ) then
          -- There are enemies within combat range. Unload the CargoCarrier.
          self:__Unload( 1 )
        end
      end
      if self:Is( "Unloaded" ) then
        if not Coordinate:IsAtCoordinate2D( self.Coordinate, 2 ) then
          --self.CargoGroup:RouteTo( Coordinate, 30 )
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
    CargoCarrier:RouteStop()
    self:Board() 
    self.CargoGroup:Board( CargoCarrier, 100 )
  end
  
end

--- @param #AI_CARGO_TROOPS self
-- @param Wrapper.Unit#UNIT CargoCarrier
function AI_CARGO_TROOPS:onafterBoard( CargoCarrier, From, Event, To )
  self:F( { CargoCarrier, From, Event, To } )

  if CargoCarrier and CargoCarrier:IsAlive() then
    self:F({ IsLoaded = self.CargoGroup:IsLoaded() } )
    if not self.CargoGroup:IsLoaded() then
      self:__Board( 1 )
    else
      self:__Loaded( 1 )
    end
  end
  
end

--- @param #AI_CARGO_TROOPS self
-- @param Wrapper.Unit#UNIT CargoCarrier
function AI_CARGO_TROOPS:onafterLoaded( CargoCarrier, From, Event, To )
  self:F( { CargoCarrier, From, Event, To } )

  if CargoCarrier and CargoCarrier:IsAlive() then
    CargoCarrier:RouteResume()
  end
  
end


--- @param #AI_CARGO_TROOPS self
-- @param Wrapper.Unit#UNIT CargoCarrier
function AI_CARGO_TROOPS:onafterUnload( CargoCarrier, From, Event, To )
  self:F( { CargoCarrier, From, Event, To } )

  if CargoCarrier and CargoCarrier:IsAlive() then
    CargoCarrier:RouteStop()
    self.CargoGroup:UnBoard( )
    self:__Unboard( 1 ) 
  end
  
end

--- @param #AI_CARGO_TROOPS self
-- @param Wrapper.Unit#UNIT CargoCarrier
function AI_CARGO_TROOPS:onafterUnboard( CargoCarrier, From, Event, To )
  self:F( { CargoCarrier, From, Event, To } )

  if CargoCarrier and CargoCarrier:IsAlive() then
    if not self.CargoGroup:IsUnLoaded() then
      self:__Unboard( 1 ) 
    else
      self:Unloaded()
    end
  end
  
end

--- @param #AI_CARGO_TROOPS self
-- @param Wrapper.Unit#UNIT CargoCarrier
function AI_CARGO_TROOPS:onafterUnloaded( CargoCarrier, From, Event, To )
  self:F( { CargoCarrier, From, Event, To } )

  if CargoCarrier and CargoCarrier:IsAlive() then
    CargoCarrier:RouteResume()
  end
  
end
