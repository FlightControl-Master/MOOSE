--- **AI** -- (R2.4) - Models the intelligent transportation of infantry and other cargo.
--
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ===       
--
-- @module AI.AI_Cargo_APC
-- @image AI_Cargo_Dispatching_For_APC.JPG

--- @type AI_CARGO_APC
-- @extends AI.AI_Cargo#AI_CARGO


--- Brings a dynamic cargo handling capability for an AI vehicle group.
-- 
-- Armoured Personnel Carriers (APC), Trucks, Jeeps and other ground based carrier equipment can be mobilized to intelligently transport infantry and other cargo within the simulation.
-- 
-- The AI_CARGO_APC class uses the @{Cargo.Cargo} capabilities within the MOOSE framework.
-- @{Cargo.Cargo} must be declared within the mission to make the AI_CARGO_APC object recognize the cargo.
-- Please consult the @{Cargo.Cargo} module for more information. 
-- 
-- ## Cargo loading.
-- 
-- The module will load automatically cargo when the APCs are within boarding or loading range.
-- The boarding or loading range is specified when the cargo is created in the simulation, and therefore, this range depends on the type of cargo
-- and the specified boarding range.
-- 
-- ## Enemies nearby.
--  
-- When the APCs are approaching enemy units, something special is happening. 
-- The APCs will stop moving, and the loaded infantry will unboard and follow the APCs and will help to defend the group.
-- The carrier will hold the route once the unboarded infantry is further than 50 meters from the APCs, 
-- to ensure that the APCs are not too far away from the following running infantry.
-- Once all enemies are cleared, the infantry will board again automatically into the APCs. Once boarded, the APCs will follow its pre-defined route.
-- 
-- A combat range needs to be specified in meters at the @{#AI_CARGO_APC.New}() method. 
-- This combat range will trigger the unboarding of troops when enemies are within the combat range around the APCs.
-- During my tests, I've noticed that there is a balance between ensuring that the infantry is within sufficient hit range (effectiveness) versus
-- vulnerability of the infantry. It all depends on the kind of enemies that are expected to be encountered. 
-- A combat range of 350 meters to 500 meters has been proven to be the most effective and efficient.
-- 
-- ## Infantry health.
-- 
-- When infantry is unboarded from the APCs, the infantry is actually respawned into the battlefield. 
-- As a result, the unboarding infantry is very _healthy_ every time it unboards.
-- This is due to the limitation of the DCS simulator, which is not able to specify the health of new spawned units as a parameter.
-- However, infantry that was destroyed when unboarded and following the APCs, won't be respawned again. Destroyed is destroyed.
-- As a result, there is some additional strength that is gained when an unboarding action happens, but in terms of simulation balance this has
-- marginal impact on the overall battlefield simulation. Fortunately, the firing strength of infantry is limited, and thus, respacing healthy infantry every
-- time is not so much of an issue ... 
-- 
-- ## Control the APCs on the map.
-- 
-- It is possible also as a human ground commander to influence the path of the APCs, by pointing a new path using the DCS user interface on the map.
-- In this case, the APCs will change the direction towards its new indicated route. However, there is a catch!
-- Once the APCs are near the enemy, and infantry is unboarded, the APCs won't be able to hold the route until the infantry could catch up.
-- The APCs will simply drive on and won't stop! This is a limitation in ED that prevents user actions being controlled by the scripting engine.
-- No workaround is possible on this.
-- 
-- ## Cargo deployment.
--  
-- Using the @{#AI_CARGO_APC.Deploy}() method, you are able to direct the APCs towards a point on the battlefield to unboard/unload the cargo at the specific coordinate. 
-- The APCs will follow nearby roads as much as possible, to ensure fast and clean cargo transportation between the objects and villages in the simulation environment.
-- 
-- ## Cargo pickup.
--  
-- Using the @{#AI_CARGO_APC.Pickup}() method, you are able to direct the APCs towards a point on the battlefield to board/load the cargo at the specific coordinate. 
-- The APCs will follow nearby roads as much as possible, to ensure fast and clean cargo transportation between the objects and villages in the simulation environment.
-- 
-- 
-- 
-- @field #AI_CARGO_APC
AI_CARGO_APC = {
  ClassName = "AI_CARGO_APC",
  Coordinate = nil, -- Core.Point#COORDINATE,
}

--- Creates a new AI_CARGO_APC object.
-- @param #AI_CARGO_APC self
-- @param Wrapper.Group#GROUP APC
-- @param Core.Set#SET_CARGO CargoSet
-- @param #number CombatRadius
-- @return #AI_CARGO_APC
function AI_CARGO_APC:New( APC, CargoSet, CombatRadius )

  local self = BASE:Inherit( self, AI_CARGO:New( APC, CargoSet ) ) -- #AI_CARGO_APC

  self.CombatRadius = CombatRadius

  self:AddTransition( "*", "Monitor", "*" )
  self:AddTransition( "*", "Follow", "Following" )
  self:AddTransition( "*", "Guard", "Unloaded" )
  self:AddTransition( "*", "Home", "*" )
  
  self:AddTransition( "*", "Destroyed", "Destroyed" )

  self:__Monitor( 1 )

  self:SetCarrier( APC )
  
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
        AICargoTroops:Unload( false )
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
-- @param Wrapper.Unit#UNIT APCUnit
-- @param Cargo.CargoGroup#CARGO_GROUP Cargo
-- @return #AI_CARGO_APC
function AI_CARGO_APC:FollowToCarrier( Me, APCUnit, CargoGroup )

  local InfantryGroup = CargoGroup:GetGroup()

  self:F( { self = self:GetClassNameAndID(), InfantryGroup = InfantryGroup:GetName() } )
  
  --if self:Is( "Following" ) then

  if APCUnit:IsAlive() then
    -- We check if the Cargo is near to the CargoCarrier.
    if InfantryGroup:IsPartlyInZone( ZONE_UNIT:New( "Radius", APCUnit, 25 ) ) then
  
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
  
        local ToCoord = APCUnit:GetCoordinate():GetRandomCoordinateInRadius( 10, 5 )
        local ToGround = ToCoord:WaypointGround( 10, "Diamond" )
        self:F({ToGround=ToGround})
        table.insert( Waypoints, ToGround )
        
        local TaskRoute = InfantryGroup:TaskFunction( "AI_CARGO_APC.FollowToCarrier", Me, APCUnit, CargoGroup )
        
        self:F({Waypoints = Waypoints})
        local Waypoint = Waypoints[#Waypoints]
        InfantryGroup:SetTaskWaypoint( Waypoint, TaskRoute ) -- Set for the given Route at Waypoint 2 the TaskRouteToZone.
      
        InfantryGroup:Route( Waypoints, 1 ) -- Move after a random seconds to the Route. See the Route method for details.
      end
    end
  end
end


--- On after Monitor event.
-- @param #AI_CARGO_APC self
-- @param Wrapper.Group#GROUP APC
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AI_CARGO_APC:onafterMonitor( APC, From, Event, To )
  self:F( { APC, From, Event, To } )

  if APC and APC:IsAlive() then
    if self.CarrierCoordinate then
      if self:IsTransporting() == true then
        local Coordinate = APC:GetCoordinate()
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
              self:Follow()
            end
            self:F( "I am here" .. self:GetCurrentState() )
            if self:Is( "Following" ) then
              for Cargo, APCUnit in pairs( self.Carrier_Cargo ) do
                local Cargo = Cargo -- Cargo.Cargo#CARGO
                local APCUnit = APCUnit -- Wrapper.Unit#UNIT
                if Cargo:IsAlive() then
                  if not Cargo:IsNear( APCUnit, 40 ) then
                    APCUnit:RouteStop()
                    self.CarrierStopped = true
                  else
                    if self.CarrierStopped then
                      if Cargo:IsNear( APCUnit, 25 ) then
                        APCUnit:RouteResume()
                        self.CarrierStopped = nil
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
      
    end
    self.CarrierCoordinate = APC:GetCoordinate()
  end
  
  self:__Monitor( -5 )

end


--- On after Follow event.
-- @param #AI_CARGO_APC self
-- @param Wrapper.Group#GROUP APC
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AI_CARGO_APC:onafterFollow( APC, From, Event, To )
  self:F( { APC, From, Event, To } )

  self:F( "Follow" )
  if APC and APC:IsAlive() then
    for Cargo, APCUnit in pairs( self.Carrier_Cargo ) do
      local Cargo = Cargo -- Cargo.Cargo#CARGO
      if Cargo:IsUnLoaded() then
        self:FollowToCarrier( self, APCUnit, Cargo )
        APCUnit:RouteResume()
      end
    end
  end
  
end


--- @param #AI_CARGO_APC 
-- @param Wrapper.Group#GROUP APC
function AI_CARGO_APC._Pickup( APC, self, PickupZone )

  APC:F( { "AI_CARGO_APC._Pickup:", APC:GetName() } )

  if APC:IsAlive() then
    self:Load( PickupZone)
    self.Relocating = false
    self.Transporting = true
  end
end


function AI_CARGO_APC._Deploy( APC, self, Coordinate, DeployZone )

  APC:F( { "AI_CARGO_APC._Deploy:", APC } )

  if APC:IsAlive() then
    self:Unload( DeployZone )
    self.Transporting = false
    self.Relocating = false
  end
end



--- On after Pickup event.
-- @param #AI_CARGO_APC self
-- @param Wrapper.Group#GROUP APC
-- @param From
-- @param Event
-- @param To
-- @param Core.Point#COORDINATE Coordinate of the pickup point.
-- @param #number Speed Speed in km/h to drive to the pickup coordinate. Default is 50% of max possible speed the unit can go.
-- @param Core.Zone#ZONE PickupZone (optional) The zone where the cargo will be picked up. The PickupZone can be nil, if there wasn't any PickupZoneSet provided.
function AI_CARGO_APC:onafterPickup( APC, From, Event, To, Coordinate, Speed, PickupZone )

  if APC and APC:IsAlive() then

    if Coordinate then
      self.RoutePickup = true
      
      local _speed=Speed or APC:GetSpeedMax()*0.5
      
      local Waypoints = APC:TaskGroundOnRoad( Coordinate, _speed, "Line abreast", true )
  
      local TaskFunction = APC:TaskFunction( "AI_CARGO_APC._Pickup", self, PickupZone )
      
      self:F({Waypoints = Waypoints})
      local Waypoint = Waypoints[#Waypoints]
      APC:SetTaskWaypoint( Waypoint, TaskFunction ) -- Set for the given Route at Waypoint 2 the TaskRouteToZone.
    
      APC:Route( Waypoints, 1 ) -- Move after a random seconds to the Route. See the Route method for details.
    else
      AI_CARGO_APC._Pickup( APC, self, PickupZone )
    end

    self.Relocating = true
    self.Transporting = false
  end
  
end


--- On after Deploy event.
-- @param #AI_CARGO_APC self
-- @param Wrapper.Group#GROUP APC
-- @param From
-- @param Event
-- @param To
-- @param Core.Point#COORDINATE Coordinate Deploy place.
-- @param #number Speed Speed in km/h to drive to the depoly coordinate. Default is 50% of max possible speed the unit can go.
function AI_CARGO_APC:onafterDeploy( APC, From, Event, To, Coordinate, Speed, DeployZone )

  if APC and APC:IsAlive() then

    self.RouteDeploy = true
    
    local _speed=Speed or APC:GetSpeedMax()*0.5
     
    local Waypoints = APC:TaskGroundOnRoad( Coordinate, _speed, "Line abreast", true )

    local TaskFunction = APC:TaskFunction( "AI_CARGO_APC._Deploy", self, Coordinate, DeployZone )
    
    self:F({Waypoints = Waypoints})
    local Waypoint = Waypoints[#Waypoints]
    APC:SetTaskWaypoint( Waypoint, TaskFunction ) -- Set for the given Route at Waypoint 2 the TaskRouteToZone.
  
    APC:Route( Waypoints, 1 ) -- Move after a random seconds to the Route. See the Route method for details.

    self.Relocating = false
    self.Transporting = true
  end
  
end


--- On after Home event.
-- @param #AI_CARGO_APC self
-- @param Wrapper.Group#GROUP APC
-- @param From
-- @param Event
-- @param To
-- @param Core.Point#COORDINATE Coordinate Home place.
-- @param #number Speed Speed in km/h to drive to the pickup coordinate. Default is 50% of max possible speed the unit can go.
function AI_CARGO_APC:onafterHome( APC, From, Event, To, Coordinate, Speed, HomeZone )

  if APC and APC:IsAlive() ~= nil then

    self.RouteHome = true
    
    Speed = Speed or APC:GetSpeedMax()*0.5
    
    local Waypoints = APC:TaskGroundOnRoad( Coordinate, Speed, "Line abreast", true )

    self:F({Waypoints = Waypoints})
    local Waypoint = Waypoints[#Waypoints]
  
    APC:Route( Waypoints, 1 ) -- Move after a random seconds to the Route. See the Route method for details.
    
  end
  
end
