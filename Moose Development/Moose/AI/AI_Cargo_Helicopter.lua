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
-- @param Wrapper.Group#GROUP Helicopter
-- @param Core.Set#SET_CARGO CargoSet
-- @param #number CombatRadius
-- @return #AI_CARGO_HELICOPTER
function AI_CARGO_HELICOPTER:New( Helicopter, CargoSet )

  local self = BASE:Inherit( self, FSM_CONTROLLABLE:New() ) -- #AI_CARGO_HELICOPTER

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

  --- Pickup Handler OnBefore for AI_CARGO_HELICOPTER
  -- @function [parent=#AI_CARGO_HELICOPTER] OnBeforePickup
  -- @param #AI_CARGO_HELICOPTER self
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param Core.Point#COORDINATE Coordinate
  -- @return #boolean
  
  --- Pickup Handler OnAfter for AI_CARGO_HELICOPTER
  -- @function [parent=#AI_CARGO_HELICOPTER] OnAfterPickup
  -- @param #AI_CARGO_HELICOPTER self
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param Core.Point#COORDINATE Coordinate
  
  --- Pickup Trigger for AI_CARGO_HELICOPTER
  -- @function [parent=#AI_CARGO_HELICOPTER] Pickup
  -- @param #AI_CARGO_HELICOPTER self
  -- @param Core.Point#COORDINATE Coordinate
  
  --- Pickup Asynchronous Trigger for AI_CARGO_HELICOPTER
  -- @function [parent=#AI_CARGO_HELICOPTER] __Pickup
  -- @param #AI_CARGO_HELICOPTER self
  -- @param #number Delay
  -- @param Core.Point#COORDINATE Coordinate
  
  --- Deploy Handler OnBefore for AI_CARGO_HELICOPTER
  -- @function [parent=#AI_CARGO_HELICOPTER] OnBeforeDeploy
  -- @param #AI_CARGO_HELICOPTER self
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param Core.Point#COORDINATE Coordinate
  -- @return #boolean
  
  --- Deploy Handler OnAfter for AI_CARGO_HELICOPTER
  -- @function [parent=#AI_CARGO_HELICOPTER] OnAfterDeploy
  -- @param #AI_CARGO_HELICOPTER self
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param Core.Point#COORDINATE Coordinate
  
  --- Deploy Trigger for AI_CARGO_HELICOPTER
  -- @function [parent=#AI_CARGO_HELICOPTER] Deploy
  -- @param #AI_CARGO_HELICOPTER self
  -- @param Core.Point#COORDINATE Coordinate
  
  --- Deploy Asynchronous Trigger for AI_CARGO_HELICOPTER
  -- @function [parent=#AI_CARGO_HELICOPTER] __Deploy
  -- @param #AI_CARGO_HELICOPTER self
  -- @param Core.Point#COORDINATE Coordinate
  -- @param #number Delay



  self:SetCarrier( Helicopter )
  
  return self
end


--- Set the Carrier.
-- @param #AI_CARGO_HELICOPTER self
-- @param Wrapper.Group#GROUP Helicopter
-- @return #AI_CARGO_HELICOPTER
function AI_CARGO_HELICOPTER:SetCarrier( Helicopter )

  local AICargo = self

  self.Helicopter = Helicopter -- Wrapper.Group#GROUP
  self.Helicopter:SetState( self.Helicopter, "AI_CARGO_HELICOPTER", self )

  self.RoutePickup = false
  self.RouteDeploy = false

  Helicopter:HandleEvent( EVENTS.Dead )
  Helicopter:HandleEvent( EVENTS.Hit )
  Helicopter:HandleEvent( EVENTS.Land )
  
  function Helicopter:OnEventDead( EventData )
    local AICargoTroops = self:GetState( self, "AI_CARGO_HELICOPTER" )
    self:F({AICargoTroops=AICargoTroops})
    if AICargoTroops then
      self:F({})
      if not AICargoTroops:Is( "Loaded" ) then
        -- There are enemies within combat range. Unload the Helicopter.
        AICargoTroops:Destroyed()
      end
    end
  end
  
  
  function Helicopter:OnEventHit( EventData )
    local AICargoTroops = self:GetState( self, "AI_CARGO_HELICOPTER" )
    if AICargoTroops then
      self:F( { OnHitLoaded = AICargoTroops:Is( "Loaded" ) } )
      if AICargoTroops:Is( "Loaded" ) or AICargoTroops:Is( "Boarding" ) then
        -- There are enemies within combat range. Unload the Helicopter.
        AICargoTroops:Unload()
      end
    end
  end
  
  
  function Helicopter:OnEventLand( EventData )
    AICargo:Landed()
  end
  
  self.Coalition = self.Helicopter:GetCoalition()
  
  self:SetControllable( Helicopter )

  return self
end


--- Find a free Carrier within a range.
-- @param #AI_CARGO_HELICOPTER self
-- @param Core.Point#COORDINATE Coordinate
-- @param #number Radius
-- @return Wrapper.Group#GROUP NewCarrier
function AI_CARGO_HELICOPTER:FindCarrier( Coordinate, Radius )

  local CoordinateZone = ZONE_RADIUS:New( "Zone" , Coordinate:GetVec2(), Radius )
  CoordinateZone:Scan( { Object.Category.UNIT } )
  for _, DCSUnit in pairs( CoordinateZone:GetScannedUnits() ) do
    local NearUnit = UNIT:Find( DCSUnit )
    self:F({NearUnit=NearUnit})
    if not NearUnit:GetState( NearUnit, "AI_CARGO_HELICOPTER" ) then
      local Attributes = NearUnit:GetDesc()
      self:F({Attributes=Attributes})
      if NearUnit:HasAttribute( "Trucks" ) then
        return NearUnit:GetGroup()
      end
    end
  end
  
  return nil

end

--- @param #AI_CARGO_HELICOPTER self
-- @param Wrapper.Group#GROUP Helicopter
-- @param From
-- @param Event
-- @param To
-- @param Core.Point#COORDINATE Coordinate
-- @param #number Speed
function AI_CARGO_HELICOPTER:onafterLanded( Helicopter, From, Event, To )

  if Helicopter and Helicopter:IsAlive() then

    if self.RoutePickup == true then
      self:Load( Helicopter:GetPointVec2() )
      self.RoutePickup = false
    end
    
    if self.RouteDeploy == true then
      self:Unload()
      self.RouteDeploy = false
    end
     
  end
  
end



--- @param #AI_CARGO_HELICOPTER self
-- @param Wrapper.Group#GROUP Helicopter
-- @param From
-- @param Event
-- @param To
-- @param Core.Point#COORDINATE Coordinate
-- @param #number Speed
function AI_CARGO_HELICOPTER:onafterPickup( Helicopter, From, Event, To, Coordinate, Speed )

  if Helicopter and Helicopter:IsAlive() then

    self.RoutePickup = true
     
    local Route = {}
    
    --- Calculate the target route point.
    local CoordinateFrom = Helicopter:GetCoordinate()
    local CoordinateTo   = Coordinate

    --- Create a route point of type air.
    local WaypointFrom = CoordinateFrom:WaypointAir( 
      "RADIO", 
      POINT_VEC3.RoutePointType.TurningPoint, 
      POINT_VEC3.RoutePointAction.TurningPoint, 
      Speed, 
      true 
    )

    --- Create a route point of type air.
    local WaypointTo = CoordinateTo:WaypointAir( 
      "RADIO", 
      POINT_VEC3.RoutePointType.TurningPoint, 
      POINT_VEC3.RoutePointAction.TurningPoint, 
      Speed, 
      true 
    )

    Route[#Route+1] = WaypointFrom
    Route[#Route+1] = WaypointTo
    
    --- Now we're going to do something special, we're going to call a function from a waypoint action at the AIControllable...
    Helicopter:WayPointInitialize( Route )
  
    local Tasks = {}
    
    Tasks[#Tasks+1] = Helicopter:TaskLandAtVec2( CoordinateTo:GetVec2() )
    Route[#Route].task = Helicopter:TaskCombo( Tasks )

    -- Now route the helicopter
    Helicopter:Route( Route, 0.5 )
  end
  
end


--- @param #AI_CARGO_HELICOPTER self
-- @param Wrapper.Group#GROUP Helicopter
-- @param From
-- @param Event
-- @param To
-- @param Core.Point#COORDINATE Coordinate
-- @param #number Speed
function AI_CARGO_HELICOPTER:onafterDeploy( Helicopter, From, Event, To, Coordinate, Speed )

  if Helicopter and Helicopter:IsAlive() then

    self.RouteDeploy = true
     
    local Route = {}
    
    --- Calculate the target route point.
    local CoordinateFrom = Helicopter:GetCoordinate()
    local CoordinateTo   = Coordinate

    --- Create a route point of type air.
    local WaypointFrom = CoordinateFrom:WaypointAir( 
      "RADIO", 
      POINT_VEC3.RoutePointType.TurningPoint, 
      POINT_VEC3.RoutePointAction.TurningPoint, 
      Speed, 
      true 
    )

    --- Create a route point of type air.
    local WaypointTo = CoordinateTo:WaypointAir( 
      "RADIO", 
      POINT_VEC3.RoutePointType.TurningPoint, 
      POINT_VEC3.RoutePointAction.TurningPoint, 
      Speed, 
      true 
    )

    Route[#Route+1] = WaypointFrom
    Route[#Route+1] = WaypointTo
    
    --- Now we're going to do something special, we're going to call a function from a waypoint action at the AIControllable...
    Helicopter:WayPointInitialize( Route )
  
    local Tasks = {}
    
    Tasks[#Tasks+1] = Helicopter:TaskLandAtVec2( CoordinateTo:GetVec2() )
    Route[#Route].task = Helicopter:TaskCombo( Tasks )

    -- Now route the helicopter
    Helicopter:Route( Route, 0.5 )
  end
  
end


--- @param #AI_CARGO_HELICOPTER self
-- @param Wrapper.Group#GROUP Helicopter
function AI_CARGO_HELICOPTER:onafterLoad( Helicopter, From, Event, To, Coordinate )

  if Helicopter and Helicopter:IsAlive() then
  
    for _, Cargo in pairs( self.CargoSet:GetSet() ) do
      if Cargo:IsInLoadRadius( Coordinate ) then
        self:__Board( 5 )
        Cargo:Board( Helicopter:GetUnit(1), 25 )
        self.Cargo = Cargo
        break
      end
    end
  end
  
end

--- @param #AI_CARGO_HELICOPTER self
-- @param Wrapper.Group#GROUP Helicopter
function AI_CARGO_HELICOPTER:onafterBoard( Helicopter, From, Event, To )

  if Helicopter and Helicopter:IsAlive() then
    self:F({ IsLoaded = self.Cargo:IsLoaded() } )
    if not self.Cargo:IsLoaded() then
      self:__Board( 10 )
    else
      self:__Loaded( 1 )
    end
  end
  
end

--- @param #AI_CARGO_HELICOPTER self
-- @param Wrapper.Group#GROUP Helicopter
function AI_CARGO_HELICOPTER:onafterLoaded( Helicopter, From, Event, To )

  if Helicopter and Helicopter:IsAlive() then
  end
  
end


--- @param #AI_CARGO_HELICOPTER self
-- @param Wrapper.Group#GROUP Helicopter
function AI_CARGO_HELICOPTER:onafterUnload( Helicopter, From, Event, To )

  if Helicopter and Helicopter:IsAlive() then
    self.Cargo:UnBoard()
    self:__Unboard( 10 ) 
  end
  
end

--- @param #AI_CARGO_HELICOPTER self
-- @param Wrapper.Group#GROUP Helicopter
function AI_CARGO_HELICOPTER:onafterUnboard( Helicopter, From, Event, To )

  if Helicopter and Helicopter:IsAlive() then
    if not self.Cargo:IsUnLoaded() then
      self:__Unboard( 10 ) 
    else
      self:__Unloaded( 1 )
    end
  end
  
end

--- @param #AI_CARGO_HELICOPTER self
-- @param Wrapper.Group#GROUP Helicopter
function AI_CARGO_HELICOPTER:onafterUnloaded( Helicopter, From, Event, To )

  if Helicopter and Helicopter:IsAlive() then
    self.Helicopter = Helicopter
  end
  
end


