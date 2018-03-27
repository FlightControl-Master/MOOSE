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
  self:AddTransition( "*", "Follow", "Following" )
  self:AddTransition( "*", "Guard", "Guarding" )

  self:__Monitor( 1 )
  self:__Load( 1 )
  
  return self
end


--- Follow Infantry to the Carrier.
-- @param #AI_CARGO_TROOPS self
-- @return #AI_CARGO_TROOPS
function AI_CARGO_TROOPS:FollowToCarrier( Me )

  self = Me

  self:F( { self = self:GetClassNameAndID(), CargoGroup = self.CargoGroup:GetName() } )
  
  -- We check if the Cargo is near to the CargoCarrier.
  if self.CargoGroup:IsNear( self.CargoCarrier, 5 ) then

    -- The Cargo does not need to follow the Carrier.
    self:Guard()
  
  else
  
    -- The Cargo needs to continue to follow the Carrier.
    if self:Is( "Following" ) then
      
      -- For each Cargo object within the CARGO_GROUPED, route each object to the CargoLoadPointVec2
      self.CargoGroup.CargoSet:ForEach(
        --- @param Core.Cargo#CARGO Cargo
        function( Cargo )
          local CargoUnit = Cargo.CargoObject -- Wrapper.Unit#UNIT
          self:F( { UnitName = CargoUnit:GetName() } )
          
          if CargoUnit:IsAlive() then
            
            local InfantryGroup = CargoUnit:GetGroup()
            self:F( { GroupName = InfantryGroup:GetName() } )
            
            local Waypoints = {}
            
            -- Calculate the new Route.
            local FromCoord = InfantryGroup:GetCoordinate()
            local FromGround = FromCoord:WaypointGround( 10, "Diamond" )
            table.insert( Waypoints, FromGround )

            local ToCoord = self.CargoCarrier:GetCoordinate()
            local ToGround = ToCoord:WaypointGround( 10, "Diamond" )
            table.insert( Waypoints, ToGround )
            
            local TaskRoute = InfantryGroup:TaskFunction( "AI_CARGO_TROOPS.FollowToCarrier", self )
            
            self:F({Waypoints = Waypoints})
            local Waypoint = Waypoints[#Waypoints]
            InfantryGroup:SetTaskWaypoint( Waypoint, TaskRoute ) -- Set for the given Route at Waypoint 2 the TaskRouteToZone.
          
            InfantryGroup:Route( Waypoints ) -- Move after a random seconds to the Route. See the Route method for details.
          end
        end
      )
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
        if self:Is( "Unloaded" ) or self:Is( "Guarding" ) then
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
    self:FollowToCarrier( self )
  end
  
end

