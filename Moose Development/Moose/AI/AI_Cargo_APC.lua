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
-- @param Wrapper.Group#GROUP CargoCarrier
-- @param Core.Set#SET_CARGO CargoSet
-- @param #number CombatRadius
-- @return #AI_CARGO_APC
function AI_CARGO_APC:New( CargoCarrier, CargoSet, CombatRadius )

  local self = BASE:Inherit( self, FSM_CONTROLLABLE:New() ) -- #AI_CARGO_APC

  self.CargoSet = CargoSet -- Core.Set#SET_CARGO
  self.CombatRadius = CombatRadius

  self:SetStartState( "Unloaded" ) 
  
  self:AddTransition( "Unloaded", "Pickup", "*" )
  self:AddTransition( "Loaded", "Deploy", "*" )
  
  self:AddTransition( "*", "Load", "Boarding" )
  self:AddTransition( "Boarding", "Board", "Boarding" )
  self:AddTransition( "Boarding", "Loaded", "Loaded" )
  self:AddTransition( "Loaded", "Unload", "Unboarding" )
  self:AddTransition( "Unboarding", "Unboard", "Unboarding" )
  self:AddTransition( "Unboarding", "Unloaded", "Unloaded" )
  
  self:AddTransition( "*", "Monitor", "*" )
  self:AddTransition( "*", "Follow", "Following" )
  self:AddTransition( "*", "Guard", "Unloaded" )
  
  self:AddTransition( "*", "Destroyed", "Destroyed" )


  --- Pickup Handler OnBefore for AI_CARGO_APC
  -- @function [parent=#AI_CARGO_APC] OnBeforePickup
  -- @param #AI_CARGO_APC self
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param Core.Point#COORDINATE Coordinate
  -- @return #boolean
  
  --- Pickup Handler OnAfter for AI_CARGO_APC
  -- @function [parent=#AI_CARGO_APC] OnAfterPickup
  -- @param #AI_CARGO_APC self
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param Core.Point#COORDINATE Coordinate
  
  --- Pickup Trigger for AI_CARGO_APC
  -- @function [parent=#AI_CARGO_APC] Pickup
  -- @param #AI_CARGO_APC self
  -- @param Core.Point#COORDINATE Coordinate
  
  --- Pickup Asynchronous Trigger for AI_CARGO_APC
  -- @function [parent=#AI_CARGO_APC] __Pickup
  -- @param #AI_CARGO_APC self
  -- @param #number Delay
  -- @param Core.Point#COORDINATE Coordinate
  
  --- Deploy Handler OnBefore for AI_CARGO_APC
  -- @function [parent=#AI_CARGO_APC] OnBeforeDeploy
  -- @param #AI_CARGO_APC self
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param Core.Point#COORDINATE Coordinate
  -- @return #boolean
  
  --- Deploy Handler OnAfter for AI_CARGO_APC
  -- @function [parent=#AI_CARGO_APC] OnAfterDeploy
  -- @param #AI_CARGO_APC self
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param Core.Point#COORDINATE Coordinate
  
  --- Deploy Trigger for AI_CARGO_APC
  -- @function [parent=#AI_CARGO_APC] Deploy
  -- @param #AI_CARGO_APC self
  -- @param Core.Point#COORDINATE Coordinate
  
  --- Deploy Asynchronous Trigger for AI_CARGO_APC
  -- @function [parent=#AI_CARGO_APC] __Deploy
  -- @param #AI_CARGO_APC self
  -- @param Core.Point#COORDINATE Coordinate
  -- @param #number Delay

  
  --- Loaded Handler OnAfter for AI_CARGO_APC
  -- @function [parent=#AI_CARGO_APC] OnAfterLoaded
  -- @param #AI_CARGO_APC self
  -- @param Wrapper.Group#GROUP APC
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  
  --- Unloaded Handler OnAfter for AI_CARGO_APC
  -- @function [parent=#AI_CARGO_APC] OnAfterUnloaded
  -- @param #AI_CARGO_APC self
  -- @param Wrapper.Group#GROUP APC
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  

  self:__Monitor( 1 )

  self:SetCarrier( CargoCarrier )
  
  return self
end


--- Set the Carrier.
-- @param #AI_CARGO_APC self
-- @param Wrapper.Group#GROUP CargoCarrier
-- @return #AI_CARGO_APC
function AI_CARGO_APC:SetCarrier( CargoCarrier )

  self.CargoCarrier = CargoCarrier -- Wrapper.Group#GROUP
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
-- @return Wrapper.Group#GROUP NewCarrier
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
        return NearUnit:GetGroup()
      end
    end
  end
  
  return nil

end



--- Follow Infantry to the Carrier.
-- @param #AI_CARGO_APC self
-- @param #AI_CARGO_APC Me
-- @param Wrapper.Group#GROUP CargoCarrier
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
-- @param Wrapper.Group#GROUP CargoCarrier
function AI_CARGO_APC:onafterMonitor( CargoCarrier, From, Event, To )
  self:F( { CargoCarrier, From, Event, To } )

  if CargoCarrier and CargoCarrier:IsAlive() then
    if self.CarrierCoordinate then
      local Coordinate = CargoCarrier:GetCoordinate()
      self.Zone:Scan( { Object.Category.UNIT } )
      if self.Zone:IsAllInZoneOfCoalition( self.Coalition ) then
        if self:Is( "Unloaded" ) or self:Is( "Following" ) then
          -- There are no enemies within combat range. Load the CargoCarrier.
          self:Load()
        end
      else
        if self:Is( "Loaded" ) then
          -- There are enemies within combat range. Unload the CargoCarrier.
          self:__Unload( 1 )
        else
          if self:Is( "Unloaded" ) then
            if not self.Cargo:IsNear( CargoCarrier, 5 ) then
              self:Follow()
            end
          end
          if self:Is( "Following" ) then
            local Distance = Coordinate:Get2DDistance( self.Cargo:GetCoordinate() )
            self:F( { Distance = Distance } )
            if Distance > 40 then
              CargoCarrier:RouteStop()
              self.CarrierStopped = true
            else
              if self.CarrierStopped then
                if self.Cargo:IsNear( CargoCarrier, 10 ) then
                  CargoCarrier:RouteResume()
                  self.CarrierStopped = nil
                end
              end
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
-- @param Wrapper.Group#GROUP Carrier
function AI_CARGO_APC:onbeforeLoad( Carrier, From, Event, To )
  self:F( { Carrier, From, Event, To } )

  if Carrier and Carrier:IsAlive() then
    for _, Cargo in pairs( self.CargoSet:GetSet() ) do
      local Cargo = Cargo -- Cargo.Cargo#CARGO
      self:F( Cargo )
      if Cargo:IsInLoadRadius( Carrier:GetCoordinate() ) then
        self:F( "In radius" )
        Carrier:RouteStop()
        self:__Board( 1, Cargo )
        Cargo:Board( Carrier:GetUnit(1), 25 )
        return true
      end
    end
  end
  
  return false
  
end

--- @param #AI_CARGO_APC self
-- @param Wrapper.Group#GROUP Carrier
function AI_CARGO_APC:onafterBoard( Carrier, From, Event, To, Cargo )
  self:F( { Carrier, From, Event, To, Cargo } )

  if Carrier and Carrier:IsAlive() then
    self:F({ IsLoaded = Cargo:IsLoaded() } )
    if not Cargo:IsLoaded() then
      self:__Board( 10, Cargo )
    else
      self:__Loaded( 1, Cargo )
    end
  end
  
end

--- @param #AI_CARGO_APC self
-- @param Wrapper.Group#GROUP CargoCarrier
function AI_CARGO_APC:onafterLoaded( CargoCarrier, From, Event, To, Cargo )
  self:F( { CargoCarrier, From, Event, To, Cargo } )

  if CargoCarrier and CargoCarrier:IsAlive() then
    CargoCarrier:RouteResume()
    self.Cargo = Cargo
  end
  
end


--- @param #AI_CARGO_APC self
-- @param Wrapper.Group#GROUP CargoCarrier
function AI_CARGO_APC:onafterUnload( CargoCarrier, From, Event, To )
  self:F( { CargoCarrier, From, Event, To } )

  if CargoCarrier and CargoCarrier:IsAlive() then
    CargoCarrier:RouteStop()
    self.Cargo:UnBoard()
    self:__Unboard( 10 ) 
  end
  
end

--- @param #AI_CARGO_APC self
-- @param Wrapper.Group#GROUP CargoCarrier
function AI_CARGO_APC:onafterUnboard( CargoCarrier, From, Event, To )
  self:F( { CargoCarrier, From, Event, To } )

  if CargoCarrier and CargoCarrier:IsAlive() then
    if not self.Cargo:IsUnLoaded() then
      self:__Unboard( 10 ) 
    else
      self:__Unloaded( 1 )
    end
  end
  
end

--- @param #AI_CARGO_APC self
-- @param Wrapper.Group#GROUP CargoCarrier
function AI_CARGO_APC:onafterUnloaded( CargoCarrier, From, Event, To )
  self:F( { CargoCarrier, From, Event, To } )

  if CargoCarrier and CargoCarrier:IsAlive() then
    self:Guard()
    self.CargoCarrier = CargoCarrier
    CargoCarrier:RouteResume()
  end
  
end


--- @param #AI_CARGO_APC self
-- @param Wrapper.Group#GROUP CargoCarrier
function AI_CARGO_APC:onafterFollow( CargoCarrier, From, Event, To )
  self:F( { CargoCarrier, From, Event, To } )

  self:F( "Follow" )
  if CargoCarrier and CargoCarrier:IsAlive() then
    self.Cargo.CargoSet:ForEach(
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


--- @param #AI_CARGO_APC 
-- @param Wrapper.Group#GROUP Carrier
function AI_CARGO_APC._Pickup( Carrier )

  Carrier:F( { "AI_CARGO_APC._Pickup:", Carrier:GetName() } )

  if Carrier:IsAlive() then
    Carrier:__Load( 1 )
  end
end


--- @param #AI_CARGO_APC 
-- @param Wrapper.Group#GROUP Carrier
function AI_CARGO_APC._Deploy( Carrier )

  Carrier:F( { "AI_CARGO_APC._Deploy:", Carrier:GetName() } )

  if Carrier:IsAlive() then
    Carrier:__Unload( 1 )
  end
end



--- @param #AI_CARGO_APC self
-- @param Wrapper.Group#GROUP Carrier
-- @param From
-- @param Event
-- @param To
-- @param Core.Point#COORDINATE Coordinate
-- @param #number Speed
function AI_CARGO_APC:onafterPickup( Carrier, From, Event, To, Coordinate, Speed )

  if Carrier and Carrier:IsAlive() then

    self.RoutePickup = true
    
    Carrier:RouteGroundOnRoad( Coordinate, Speed, 1 )
  end
  
end


--- @param #AI_CARGO_APC self
-- @param Wrapper.Group#GROUP Carrier
-- @param From
-- @param Event
-- @param To
-- @param Core.Point#COORDINATE Coordinate
-- @param #number Speed
function AI_CARGO_APC:onafterDeploy( Carrier, From, Event, To, Coordinate, Speed )

  if Carrier and Carrier:IsAlive() then

    self.RouteDeploy = true
     
    Carrier:RouteGroundOnRoad( Coordinate, Speed, 1 )
  end
  
end

