--- **AI** -- (R2.3) - Models the intelligent transportation of infantry and other cargo.
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


--- # AI\_CARGO\_APC class, extends @{Core.Base#BASE}
-- 
-- ===
-- 
-- AI\_CARGO\APC brings a dynamic cargo handling capability for AI groups.
-- 
-- Armoured Personnel Carriers (APC), Trucks, Jeeps and other ground based carrier equipment can be mobilized to intelligently transport infantry and other cargo within the simulation.
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
  APC_Cargo = {},
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
  self:AddTransition( { "Unboarding", "Unloaded" }, "Unloaded", "Unloaded" )
  
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
  self.Transporting = false
  
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


function AI_CARGO_APC:IsTransporting()

  return self.Transporting == true
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


--- @param #AI_CARGO_APC self
-- @param Wrapper.Group#GROUP APC
function AI_CARGO_APC:onafterMonitor( APC, From, Event, To )
  self:F( { APC, From, Event, To } )

  if APC and APC:IsAlive() then
    if self.CarrierCoordinate then
      if self:IsTransporting() then
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
            if self:Is( "Following" ) then
              for APCUnit, Cargo in pairs( self.APC_Cargo ) do
                local Cargo = Cargo -- Cargo.Cargo#CARGO
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


--- @param #AI_CARGO_APC self
-- @param Wrapper.Group#GROUP APC
function AI_CARGO_APC:onbeforeLoad( APC, From, Event, To )
  self:F( { APC, From, Event, To } )

  local Boarding = false
  self.BoardingCount = 0

  if APC and APC:IsAlive() then
    self.APC_Cargo = {}
    for _, APCUnit in pairs( APC:GetUnits() ) do
      local APCUnit = APCUnit -- Wrapper.Unit#UNIT
      for _, Cargo in pairs( self.CargoSet:GetSet() ) do
        local Cargo = Cargo -- Cargo.Cargo#CARGO
        self:F( { IsUnLoaded = Cargo:IsUnLoaded(), Cargo:GetName(), APC:GetName() } )
        if Cargo:IsUnLoaded() then
          if Cargo:IsInLoadRadius( APCUnit:GetCoordinate() ) then
            self:F( { "In radius", APCUnit:GetName() } )
            APC:RouteStop()
            --Cargo:Ungroup()
            Cargo:Board( APCUnit, 25 )
            self:__Board( 1, Cargo )
            Boarding = true
            
            -- So now this APCUnit has Cargo that is being loaded.
            -- This will be used further in the logic to follow and to check cargo status.
            self.APC_Cargo[APCUnit] = Cargo
            break
          end
        end
      end
    end
  end

  return Boarding
  
end

--- @param #AI_CARGO_APC self
-- @param Wrapper.Group#GROUP APC
function AI_CARGO_APC:onafterBoard( APC, From, Event, To, Cargo )
  self:F( { APC, From, Event, To, Cargo } )

  if APC and APC:IsAlive() then
    self:F({ IsLoaded = Cargo:IsLoaded(), Cargo:GetName(), APC:GetName() } )
    if not Cargo:IsLoaded() then
      self:__Board( 10, Cargo )
    else
      self:__Loaded( 1 )
    end
  end
  
end

--- @param #AI_CARGO_APC self
-- @param Wrapper.Group#GROUP APC
function AI_CARGO_APC:onbeforeLoaded( APC, From, Event, To )
  self:F( { APC, From, Event, To } )

  local Loaded = true

  if APC and APC:IsAlive() then
    for APCUnit, Cargo in pairs( self.APC_Cargo ) do
      local Cargo = Cargo -- Cargo.Cargo#CARGO
      self:F( { IsLoaded = Cargo:IsLoaded(), IsDestroyed = Cargo:IsDestroyed(), Cargo:GetName(), APC:GetName() } )
      if not Cargo:IsLoaded() and not Cargo:IsDestroyed() then
        Loaded = false
      end
    end
    
  end
  
  if Loaded == true then
    APC:RouteResume()
  end
  
  return Loaded
  
end


--- @param #AI_CARGO_APC self
-- @param Wrapper.Group#GROUP APC
function AI_CARGO_APC:onafterUnload( APC, From, Event, To )
  self:F( { APC, From, Event, To } )

  if APC and APC:IsAlive() then
    for _, APCUnit in pairs( APC:GetUnits() ) do
      local APCUnit = APCUnit -- Wrapper.Unit#UNIT
      APC:RouteStop()
      for _, Cargo in pairs( APCUnit:GetCargo() ) do
        Cargo:UnBoard()
        self:__Unboard( 10, Cargo )
      end 
    end
  end
  
end

--- @param #AI_CARGO_APC self
-- @param Wrapper.Group#GROUP APC
function AI_CARGO_APC:onafterUnboard( APC, From, Event, To, Cargo )
  self:F( { APC, From, Event, To, Cargo:GetName() } )

  if APC and APC:IsAlive() then
    if not Cargo:IsUnLoaded() then
      self:__Unboard( 10, Cargo ) 
    else
      self:__Unloaded( 1, Cargo )
    end
  end
  
end

--- @param #AI_CARGO_APC self
-- @param Wrapper.Group#GROUP APC
function AI_CARGO_APC:onbeforeUnloaded( APC, From, Event, To, Cargo )
  self:F( { APC, From, Event, To, Cargo:GetName() } )

  local AllUnloaded = true

  --Cargo:Regroup()

  if APC and APC:IsAlive() then
    for _, APCUnit in pairs( APC:GetUnits() ) do
      local APCUnit = APCUnit -- Wrapper.Unit#UNIT
      local CargoCheck = self.APC_Cargo[APCUnit]
      self:F( { CargoCheck:GetName(), IsUnLoaded = CargoCheck:IsUnLoaded() } )
      if CargoCheck:IsUnLoaded() == false then
        AllUnloaded = false
        break
      end
    end
    
    if AllUnloaded == true then
      self:Guard()
      self.CargoCarrier = APC
      self.APC_Cargo = {}
    end
  end
  
  self:F( { AllUnloaded = AllUnloaded } )
  return AllUnloaded
  
end


--- @param #AI_CARGO_APC self
-- @param Wrapper.Group#GROUP APC
function AI_CARGO_APC:onafterFollow( APC, From, Event, To )
  self:F( { APC, From, Event, To } )

  self:F( "Follow" )
  if APC and APC:IsAlive() then
    for APCUnit, Cargo in pairs( self.APC_Cargo ) do
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
function AI_CARGO_APC._Pickup( APC, self )

  APC:F( { "AI_CARGO_APC._Pickup:", APC:GetName() } )

  if APC:IsAlive() then
    self:Load()
    self.Transporting = true
  end
end


--- @param #AI_CARGO_APC 
-- @param Wrapper.Group#GROUP APC
function AI_CARGO_APC._Deploy( APC, self )

  APC:F( { "AI_CARGO_APC._Deploy:", APC } )

  if APC:IsAlive() then
    self:Unload()
    self.Transporting = false
  end
end



--- @param #AI_CARGO_APC self
-- @param Wrapper.Group#GROUP APC
-- @param From
-- @param Event
-- @param To
-- @param Core.Point#COORDINATE Coordinate
-- @param #number Speed
-- @param #string EndPointFormation The formation at the end point of the action.
function AI_CARGO_APC:onafterPickup( APC, From, Event, To, Coordinate, Speed, EndPointFormation )

  if APC and APC:IsAlive() then

    if Coordinate then
      self.RoutePickup = true
      
      local Waypoints = APC:TaskGroundOnRoad( Coordinate, Speed, EndPointFormation )
  
      local TaskFunction = APC:TaskFunction( "AI_CARGO_APC._Pickup", self )
      
      self:F({Waypoints = Waypoints})
      local Waypoint = Waypoints[#Waypoints]
      APC:SetTaskWaypoint( Waypoint, TaskFunction ) -- Set for the given Route at Waypoint 2 the TaskRouteToZone.
    
      APC:Route( Waypoints, 1 ) -- Move after a random seconds to the Route. See the Route method for details.
    else
      AI_CARGO_APC._Pickup( APC, self )
    end
  end
  
end


--- @param #AI_CARGO_APC self
-- @param Wrapper.Group#GROUP APC
-- @param From
-- @param Event
-- @param To
-- @param Core.Point#COORDINATE Coordinate
-- @param #number Speed
-- @param #string EndPointFormation The formation at the end point of the action.
function AI_CARGO_APC:onafterDeploy( APC, From, Event, To, Coordinate, Speed, EndPointFormation )

  if APC and APC:IsAlive() then

    self.RouteDeploy = true
     
    local Waypoints = APC:TaskGroundOnRoad( Coordinate, Speed, EndPointFormation )

    local TaskFunction = APC:TaskFunction( "AI_CARGO_APC._Deploy", self )
    
    self:F({Waypoints = Waypoints})
    local Waypoint = Waypoints[#Waypoints]
    APC:SetTaskWaypoint( Waypoint, TaskFunction ) -- Set for the given Route at Waypoint 2 the TaskRouteToZone.
  
    APC:Route( Waypoints, 1 ) -- Move after a random seconds to the Route. See the Route method for details.
  end
  
end

