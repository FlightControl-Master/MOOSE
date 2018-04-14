--- **AI** -- (R2.3) - Models the intelligent transportation of infantry (cargo).
--
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ===       
--
-- @module AI_Cargo_APC

--- @type AI_CARGO_APC
-- @extends Core.Fsm#FSM_CONTROLLABLE


--- # AI\_CARGO\_TROOPS class, extends @{Core.Base@BASE}
-- 
-- ===
-- 
-- @field #AI_CARGO_APC
AI_CARGO_APC = {
  ClassName = "AI_CARGO_APC",
  Coordinate = nil -- Core.Point#COORDINATE,
}

--- Creates a new AI_CARGO_APC object.
-- @param #AI_CARGO_APC self
-- @param Wrapper.Unit#UNIT CargoCarrier
-- @param Cargo.CargoGroup#CARGO_GROUP CargoGroup
-- @param #number CombatRadius
-- @return #AI_CARGO_APC
function AI_CARGO_APC:New( CargoCarrier, CargoGroup, CombatRadius )

  local self = BASE:Inherit( self, FSM_CONTROLLABLE:New() ) -- #AI_CARGO_APC

  self.CargoGroup = CargoGroup -- Cargo.CargoGroup#CARGO_GROUP
  self.CombatRadius = CombatRadius

  self:SetStartState( "UnLoaded" ) 
  
  self:AddTransition( "*", "Load", "Boarding" )
  self:AddTransition( "Boarding", "Board", "Boarding" )
  self:AddTransition( "Boarding", "Loaded", "Loaded" )
  self:AddTransition( "Loaded", "Unload", "Unboarding" )
  self:AddTransition( "Unboarding", "Unboard", "Unboarding" )
  self:AddTransition( "Unboarding", "Unloaded", "Unloaded" )
  
  self:AddTransition( "*", "Monitor", "*" )
  self:AddTransition( "*", "Follow", "Following" )
  self:AddTransition( "*", "Guard", "Guarding" )
  
  self:AddTransition( "*", "Destroyed", "Destroyed" )

  self:__Monitor( 1 )

  self:SetCarrier( CargoCarrier )
  
  return self
end


--- Set the Carrier.
-- @param #AI_CARGO_APC self
-- @param Wrapper.Unit#UNIT CargoCarrier
-- @return #AI_CARGO_APC
function AI_CARGO_APC:SetCarrier( CargoCarrier )

  self.CargoCarrier = CargoCarrier -- Wrapper.Unit#UNIT
  self.CargoCarrier:SetState( self.CargoCarrier, "AI_CARGO_APC", self )

  CargoCarrier:HandleEvent( EVENTS.Dead )
  CargoCarrier:HandleEvent( EVENTS.Hit )
  
  function CargoCarrier:OnEventDead( EventData )
    self:F({"dead"})
    local AICargoTroops = self:GetState( self, "AI_CARGO_APC" )
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
    self:F({"hit"})
    local AICargoTroops = self:GetState( self, "AI_CARGO_APC" )
    if AICargoTroops then
      self:F( { OnHitLoaded = AICargoTroops:Is( "Loaded" ) } )
      if AICargoTroops:Is( "Loaded" ) or AICargoTroops:Is( "Boarding" ) then
        -- There are enemies within combat range. Unload the CargoCarrier.
        AICargoTroops:Unload()
      end
    end
  end
  
  self.Zone = ZONE_UNIT:New( self.CargoCarrier:GetName() .. "-Zone", self.CargoCarrier, self.CombatRadius )
  self.Coalition = self.CargoCarrier:GetCoalition()
  
  self:SetControllable( CargoCarrier )

  self:Guard()

  return self
end


--- Find a free Carrier within a range.
-- @param #AI_CARGO_APC self
-- @param Core.Point#COORDINATE Coordinate
-- @param #number Radius
-- @return Wrapper.Unit#UNIT NewCarrier
function AI_CARGO_APC:FindCarrier( Coordinate, Radius )

  local CoordinateZone = ZONE_RADIUS:New( "Zone" , Coordinate:GetVec2(), Radius )
  CoordinateZone:Scan( { Object.Category.UNIT } )
  for _, DCSUnit in pairs( CoordinateZone:GetScannedUnits() ) do
    local NearUnit = UNIT:Find( DCSUnit )
    self:F({NearUnit=NearUnit})
    if not NearUnit:GetState( NearUnit, "AI_CARGO_APC" ) then
      local Attributes = NearUnit:GetDesc()
      self:F({Desc=Attributes})
      if NearUnit:HasAttribute( "Trucks" ) then
        self:SetCarrier( NearUnit )
        break
      end
    end
  end

end



--- Follow Infantry to the Carrier.
-- @param #AI_CARGO_APC self
-- @param #AI_CARGO_APC Me
-- @param Wrapper.Unit#UNIT CargoCarrier
-- @param Wrapper.Group#GROUP InfantryGroup
-- @return #AI_CARGO_APC
function AI_CARGO_APC:FollowToCarrier( Me, CargoCarrier, InfantryGroup )

  self:F( { self = self:GetClassNameAndID(), InfantryGroup = InfantryGroup:GetName() } )
  
  --if self:Is( "Following" ) then

  if CargoCarrier:IsAlive() then
    -- We check if the Cargo is near to the CargoCarrier.
    if InfantryGroup:IsPartlyInZone( ZONE_UNIT:New( "Radius", CargoCarrier, 5 ) ) then
  
      -- The Cargo does not need to follow the Carrier.
      Me:Guard()
    
    else
      
      self:F( { InfantryGroup = InfantryGroup:GetName() } )
    
      if InfantryGroup:IsAlive() then
            
        self:F( { InfantryGroup = InfantryGroup:GetName() } )
  
        local Waypoints = {}
        
        -- Calculate the new Route.
        local FromCoord = InfantryGroup:GetCoordinate()
        local FromGround = FromCoord:WaypointGround( 10, "Diamond" )
        self:F({FromGround=FromGround})
        table.insert( Waypoints, FromGround )
  
        local ToCoord = CargoCarrier:GetCoordinate():GetRandomCoordinateInRadius( 10, 5 )
        local ToGround = ToCoord:WaypointGround( 10, "Diamond" )
        self:F({ToGround=ToGround})
        table.insert( Waypoints, ToGround )
        
        local TaskRoute = InfantryGroup:TaskFunction( "AI_CARGO_APC.FollowToCarrier", Me, CargoCarrier, InfantryGroup )
        
        self:F({Waypoints = Waypoints})
        local Waypoint = Waypoints[#Waypoints]
        InfantryGroup:SetTaskWaypoint( Waypoint, TaskRoute ) -- Set for the given Route at Waypoint 2 the TaskRouteToZone.
      
        InfantryGroup:Route( Waypoints, 1 ) -- Move after a random seconds to the Route. See the Route method for details.
      end
    end
  end
end


--- @param #AI_CARGO_APC self
-- @param Wrapper.Unit#UNIT CargoCarrier
function AI_CARGO_APC:onafterMonitor( CargoCarrier, From, Event, To )
  self:F( { CargoCarrier, From, Event, To } )

  if CargoCarrier and CargoCarrier:IsAlive() then
    if self.CarrierCoordinate then
      local Coordinate = CargoCarrier:GetCoordinate()
      self.Zone:Scan( { Object.Category.UNIT } )
      if self.Zone:IsAllInZoneOfCoalition( self.Coalition ) then
        if self:Is( "Unloaded" ) or self:Is( "Guarding" ) or self:Is( "Following" ) then
          -- There are no enemies within combat range. Load the CargoCarrier.
          self:__Load( 1 )
        end
      else
        if self:Is( "Loaded" ) then
          -- There are enemies within combat range. Unload the CargoCarrier.
          self:__Unload( 1 )
        end
      end
      if self:Is( "Guarding" ) then
        if not self.CargoGroup:IsNear( CargoCarrier, 5 ) then
          self:Follow()
        end
      end
      if self:Is( "Following" ) then
        local Distance = Coordinate:Get2DDistance( self.CargoGroup:GetCoordinate() )
        self:F( { Distance = Distance } )
        if Distance > 40 then
          CargoCarrier:RouteStop()
          self.CarrierStopped = true
        else
          if self.CarrierStopped then
            if self.CargoGroup:IsNear( CargoCarrier, 10 ) then
              CargoCarrier:RouteResume()
              self.CarrierStopped = nil
            end
          end
        end
      end
      
    end
    self.CarrierCoordinate = CargoCarrier:GetCoordinate()
  end
  
  self:__Monitor( -5 )

end


--- @param #AI_CARGO_APC self
-- @param Wrapper.Unit#UNIT CargoCarrier
function AI_CARGO_APC:onafterLoad( CargoCarrier, From, Event, To )
  self:F( { CargoCarrier, From, Event, To } )

  if CargoCarrier and CargoCarrier:IsAlive() then
    CargoCarrier:RouteStop()
    self:__Board( 10 ) 
    self.CargoGroup:Board( CargoCarrier, 10 )
  end
  
end

--- @param #AI_CARGO_APC self
-- @param Wrapper.Unit#UNIT CargoCarrier
function AI_CARGO_APC:onafterBoard( CargoCarrier, From, Event, To )
  self:F( { CargoCarrier, From, Event, To } )

  if CargoCarrier and CargoCarrier:IsAlive() then
    self:F({ IsLoaded = self.CargoGroup:IsLoaded() } )
    if not self.CargoGroup:IsLoaded() then
      self:__Board( 10 )
    else
      self:__Loaded( 1 )
    end
  end
  
end

--- @param #AI_CARGO_APC self
-- @param Wrapper.Unit#UNIT CargoCarrier
function AI_CARGO_APC:onafterLoaded( CargoCarrier, From, Event, To )
  self:F( { CargoCarrier, From, Event, To } )

  if CargoCarrier and CargoCarrier:IsAlive() then
    CargoCarrier:RouteResume()
  end
  
end


--- @param #AI_CARGO_APC self
-- @param Wrapper.Unit#UNIT CargoCarrier
function AI_CARGO_APC:onafterUnload( CargoCarrier, From, Event, To )
  self:F( { CargoCarrier, From, Event, To } )

  if CargoCarrier and CargoCarrier:IsAlive() then
    CargoCarrier:RouteStop()
    self.CargoGroup:UnBoard( )
    self:__Unboard( 10 ) 
  end
  
end

--- @param #AI_CARGO_APC self
-- @param Wrapper.Unit#UNIT CargoCarrier
function AI_CARGO_APC:onafterUnboard( CargoCarrier, From, Event, To )
  self:F( { CargoCarrier, From, Event, To } )

  if CargoCarrier and CargoCarrier:IsAlive() then
    if not self.CargoGroup:IsUnLoaded() then
      self:__Unboard( 10 ) 
    else
      self:__Unloaded( 1 )
    end
  end
  
end

--- @param #AI_CARGO_APC self
-- @param Wrapper.Unit#UNIT CargoCarrier
function AI_CARGO_APC:onafterUnloaded( CargoCarrier, From, Event, To )
  self:F( { CargoCarrier, From, Event, To } )

  if CargoCarrier and CargoCarrier:IsAlive() then
    self:Guard()
    self.CargoCarrier = CargoCarrier
    CargoCarrier:RouteResume()
  end
  
end


--- @param #AI_CARGO_APC self
-- @param Wrapper.Unit#UNIT CargoCarrier
function AI_CARGO_APC:onafterFollow( CargoCarrier, From, Event, To )
  self:F( { CargoCarrier, From, Event, To } )

  self:F( "Follow" )
  if CargoCarrier and CargoCarrier:IsAlive() then
    self.CargoGroup.CargoSet:ForEach(
      --- @param Core.Cargo#CARGO Cargo
      function( Cargo )
        self:F( { "Follow", Cargo.CargoObject:GetName() } )
        if Cargo.CargoObject:IsAlive() == true then
          self:F( { "Follow", Cargo.CargoObject:GetID() } )
          self:FollowToCarrier( self, CargoCarrier, Cargo.CargoObject:GetGroup() )
        end
      end
    )
  end
  
end

