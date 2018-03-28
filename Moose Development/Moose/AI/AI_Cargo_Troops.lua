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

--- Creates a new AI_CARGO_TROOPS object.
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
  self:AddTransition( "*", "Follow", "Following" )
  self:AddTransition( "*", "Guard", "Guarding" )

  self:__Monitor( 1 )
  self:__Load( 1 )
  
  return self
end


--- Follow Infantry to the Carrier.
-- @param #AI_CARGO_TROOPS self
-- @param #AI_CARGO_TROOPS Me
-- @param Wrapper.Unit#UNIT CargoCarrier
-- @param Wrapper.Group#GROUP InfantryGroup
-- @return #AI_CARGO_TROOPS
function AI_CARGO_TROOPS:FollowToCarrier( Me, CargoCarrier, InfantryGroup )

  self:F( { self = self:GetClassNameAndID(), InfantryGroup = InfantryGroup:GetName() } )
  
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

      local ToCoord = CargoCarrier:GetCoordinate()
      local ToGround = ToCoord:WaypointGround( 10, "Diamond" )
      self:F({ToGround=ToGround})
      table.insert( Waypoints, ToGround )
      
      local TaskRoute = InfantryGroup:TaskFunction( "AI_CARGO_TROOPS.FollowToCarrier", Me, CargoCarrier, InfantryGroup )
      
      self:F({Waypoints = Waypoints})
      local Waypoint = Waypoints[#Waypoints]
      InfantryGroup:SetTaskWaypoint( Waypoint, TaskRoute ) -- Set for the given Route at Waypoint 2 the TaskRouteToZone.
    
      InfantryGroup:Route( Waypoints, 1 ) -- Move after a random seconds to the Route. See the Route method for details.
    end
  end
end


--- @param #AI_CARGO_TROOPS self
-- @param Wrapper.Unit#UNIT CargoCarrier
function AI_CARGO_TROOPS:onafterMonitor( CargoCarrier, From, Event, To )
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
    end
    self.CarrierCoordinate = CargoCarrier:GetCoordinate()
  end
  
  self:__Monitor( -5 )

end


--- @param #AI_CARGO_TROOPS self
-- @param Wrapper.Unit#UNIT CargoCarrier
function AI_CARGO_TROOPS:onafterLoad( CargoCarrier, From, Event, To )
  self:F( { CargoCarrier, From, Event, To } )

  if CargoCarrier and CargoCarrier:IsAlive() then
    CargoCarrier:RouteStop()
    self:__Board( 10 ) 
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
      self:__Board( 10 )
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
    self:__Unboard( 10 ) 
  end
  
end

--- @param #AI_CARGO_TROOPS self
-- @param Wrapper.Unit#UNIT CargoCarrier
function AI_CARGO_TROOPS:onafterUnboard( CargoCarrier, From, Event, To )
  self:F( { CargoCarrier, From, Event, To } )

  if CargoCarrier and CargoCarrier:IsAlive() then
    if not self.CargoGroup:IsUnLoaded() then
      self:__Unboard( 10 ) 
    else
      self:__Unloaded( 1 )
    end
  end
  
end

--- @param #AI_CARGO_TROOPS self
-- @param Wrapper.Unit#UNIT CargoCarrier
function AI_CARGO_TROOPS:onafterUnloaded( CargoCarrier, From, Event, To )
  self:F( { CargoCarrier, From, Event, To } )

  if CargoCarrier and CargoCarrier:IsAlive() then
    self:Guard()
    self.CargoCarrier = CargoCarrier
    CargoCarrier:RouteResume()
  end
  
end


--- @param #AI_CARGO_TROOPS self
-- @param Wrapper.Unit#UNIT CargoCarrier
function AI_CARGO_TROOPS:onafterFollow( CargoCarrier, From, Event, To )
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

