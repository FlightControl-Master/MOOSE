--- **AI** -- (R2.5.1) - Models the intelligent transportation of infantry and other cargo.
--
-- ===
--
-- ### Author: **acrojason** (derived from AI_Cargo_APC by FlightControl)
--
-- ===
--
-- @module AI.AI_Cargo_Ship
-- @image AI_Cargo_Dispatching_For_Ship.JPG

--- @type AI_CARGO_SHIP
-- @extends AI.AI_Cargo#AI_CARGO

--- Brings a dynamic cargo handling capability for an AI naval group.
--
-- Naval ships can be utilized to transport cargo around the map following naval shipping lanes.
-- The AI_CARGO_SHIP class uses the @{Cargo.Cargo} capabilities within the MOOSE framework. 
-- @{Cargo.Cargo} must be declared within the mission or warehouse to make the AI_CARGO_SHIP recognize the cargo.
-- Please consult the @{Cargo.Cargo} module for more information.
--
-- ## Cargo loading.
-- 
-- The module will automatically load cargo when the Ship is within boarding or loading radius. 
-- The boarding or loading radius is specified when the cargo is created in the simulation and depends on the type of 
-- cargo and the specified boarding radius.
--
-- ## Defending the Ship when enemies are nearby
-- This is not supported for naval cargo because most tanks don't float. Protect your transports...
--
-- ## Infantry or cargo **health**.
-- When cargo is unboarded from the Ship, the cargo is actually respawned into the battlefield.
-- As a result, the unboarding cargo is very _healthy_ every time it unboards.
-- This is due to the limitation of the DCS simulator, which is not able to specify the health of newly spawned units as a parameter.
-- However, cargo that was destroyed when unboarded and following the Ship won't be respawned again (this is likely not a thing for
-- naval cargo due to the lack of support for defending the Ship mentioned above). Destroyed is destroyed.
-- As a result, there is some additional strength that is gained when an unboarding action happens, but in terms of simulation balance
-- this has marginal impact on the overall battlefield simulation. Given the relatively short duration of DCS missions and the somewhat
-- lengthy naval transport times, most units entering the Ship as cargo will be freshly en route to an amphibious landing or transporting 
-- between warehouses.
--
-- ## Control the Ships on the map.
-- 
-- Currently, naval transports can only be controlled via scripts due to their reliance upon predefined Shipping Lanes created in the Mission
-- Editor. An interesting future enhancement could leverage new pathfinding functionality for ships in the Ops module.
--
-- ## Cargo deployment.
--
-- Using the @{AI_CARGO_SHIP.Deploy}() method, you are able to direct the Ship towards a Deploy zone to unboard/unload the cargo at the
-- specified coordinate. The Ship will follow the Shipping Lane to ensure consistent cargo transportation within the simulation environment.
--
-- ## Cargo pickup.
--
-- Using the @{AI_CARGO_SHIP.Pickup}() method, you are able to direct the Ship towards a Pickup zone to board/load the cargo at the specified
-- coordinate. The Ship will follow the Shipping Lane to ensure consistent cargo transportation within the simulation environment.
--
--
-- @field #AI_CARGO_SHIP
AI_CARGO_SHIP = {
    ClassName = "AI_CARGO_SHIP",
    Coordinate = nil -- Core.Point#COORDINATE
}

--- Creates a new AI_CARGO_SHIP object.
-- @param #AI_CARGO_SHIP self
-- @param Wrapper.Group#GROUP Ship  The carrier Ship group
-- @param Core.Set#SET_CARGO CargoSet  The set of cargo to be transported
-- @param #number CombatRadius  Provide the combat radius to defend the carrier by unboarding the cargo when enemies are nearby. When CombatRadius is 0, no defense will occur.
-- @param #table ShippingLane  Table containing list of Shipping Lanes to be used
-- @return #AI_CARGO_SHIP
function AI_CARGO_SHIP:New( Ship, CargoSet, CombatRadius, ShippingLane )

    local self = BASE:Inherit( self, AI_CARGO:New( Ship, CargoSet ) ) -- #AI_CARGO_SHIP

    self:AddTransition( "*", "Monitor", "*" )
    self:AddTransition( "*", "Destroyed", "Destroyed" )
    self:AddTransition( "*", "Home", "*" )

    self:SetCombatRadius( 0 )  -- Don't want to deploy cargo in middle of water to defend Ship, so set CombatRadius to 0
    self:SetShippingLane ( ShippingLane )

    self:SetCarrier( Ship )

    return self
end

--- Set the Carrier
-- @param #AI_CARGO_SHIP self
-- @param Wrapper.Group#GROUP CargoCarrier
-- @return #AI_CARGO_SHIP
function AI_CARGO_SHIP:SetCarrier( CargoCarrier )
    self.CargoCarrier = CargoCarrier -- Wrapper.Group#GROUIP
    self.CargoCarrier:SetState( self.CargoCarrier, "AI_CARGO_SHIP", self )

    CargoCarrier:HandleEvent( EVENTS.Dead )

    function CargoCarrier:OnEventDead( EventData )
        self:F({"dead"})
        local AICargoTroops = self:GetState( self, "AI_CARGO_SHIP" )
        self:F({AICargoTroops=AICargoTroops})
        if AICargoTroops then
            self:F({})
            if not AICargoTroops:Is( "Loaded" ) then
                -- Better hope they can swim!
                AICargoTroops:Destroyed()
            end
        end
    end

    self.Zone = ZONE_UNIT:New( self.CargoCarrier:GetName() .. "-Zone", self.CargoCarrier, self.CombatRadius )
    self.Coalition = self.CargoCarrier:GetCoalition()

    self:SetControllable( CargoCarrier )

    return self
end


--- FInd a free Carrier within a radius
-- @param #AI_CARGO_SHIP self
-- @param Core.Point#COORDINATE Coordinate
-- @param #number Radius
-- @return Wrapper.Group#GROUP NewCarrier
function AI_CARGO_SHIP:FindCarrier( Coordinate, Radius )

    local CoordinateZone = ZONE_RADIUS:New( "Zone", Coordinate:GetVec2(), Radius )
    CoordinateZone:Scan( { Object.Category.UNIT } )
    for _, DCSUnit in pairs( CoordinateZone:GetScannedUnits() ) do
        local NearUnit = UNIT:Find( DCSUnit )
        self:F({NearUnit=NearUnit})
        if not NearUnit:GetState( NearUnit, "AI_CARGO_SHIP" ) then
            local Attributes = NearUnit:GetDesc()
            self:F({Desc=Attributes})
            if NearUnit:HasAttributes( "Trucks" ) then
                return NearUnit:GetGroup()
            end
        end
    end

    return nil
end

function AI_CARGO_SHIP:SetShippingLane( ShippingLane )
    self.ShippingLane = ShippingLane

    return self
end

function AI_CARGO_SHIP:SetCombatRadius( CombatRadius )
    self.CombatRadius = CombatRadius or 0

    return self
end


--- Follow Infantry to the Carrier
-- @param #AI_CARGO_SHIP self
-- @param #AI_CARGO_SHIP Me
-- @param Wrapper.Unit#UNIT ShipUnit
-- @param Cargo.CargoGroup#CARGO_GROUP Cargo
-- @return #AI_CARGO_SHIP
function AI_CARGO_SHIP:FollowToCarrier( Me, ShipUnit, CargoGroup )

    local InfantryGroup = CargoGroup:GetGroup()

    self:F( { self=self:GetClassNameAndID(), InfantryGroup = InfantryGroup:GetName() } )

    if ShipUnit:IsAlive() then
        -- Check if the Cargo is near the CargoCarrier
        if InfantryGroup:IsPartlyInZone( ZONE_UNIT:New( "Radius", ShipUnit, 1000 ) ) then

            -- Cargo does not need to navigate to Carrier
            Me:Guard()
        else

            self:F( { InfantryGroup = InfantryGroup:GetName() } )
            if InfantryGroup:IsAlive() then

                self:F( { InfantryGroup = InfantryGroup:GetName() } )
                local Waypoints = {}

                -- Calculate new route
                local FromCoord = InfantryGroup:GetCoordinate()
                local FromGround = FromCoord:WaypointGround( 10, "Diamond" )
                self:F({FromGround=FromGround})
                table.insert( Waypoints, FromGround )

                local ToCoord = ShipUnit:GetCoordinate():GetRandomCoordinateInRadius( 10, 5 )
                local ToGround = ToCoord:WaypointGround( 10, "Diamond" )
                self:F({ToGround=ToGround})
                table.insert( Waypoints, ToGround )

                local TaskRoute = InfantryGroup:TaskFunction( "AI_CARGO_SHIP.FollowToCarrier", Me, ShipUnit, CargoGroup )

                self:F({Waypoints=Waypoints})
                local Waypoint = Waypoints[#Waypoints]
                InfantryGroup:SetTaskWaypoint( Waypoint, TaskRoute ) -- Set for the given Route at Waypoint 2 the TaskRouteToZone

                InfantryGroup:Route( Waypoints, 1 ) -- Move after a random number of seconds to the Route.  See Route method for details
            end
        end
    end
end


function AI_CARGO_SHIP:onafterMonitor( Ship, From, Event, To )
    self:F( { Ship, From, Event, To, IsTransporting = self:IsTransporting() } )

    if self.CombatRadius > 0 then
        -- We really shouldn't find ourselves in here for Ships since the CombatRadius should always be 0.
        -- This is to avoid Unloading the Ship in the middle of the sea.
        if Ship and Ship:IsAlive() then
            if self.CarrierCoordinate then
                if self:IsTransporting() == true then
                    local Coordinate = Ship:GetCoordinate()
                        if self:Is( "Unloaded" ) or self:Is( "Loaded" ) then
                            self.Zone:Scan( { Object.Category.UNIT } )
                            if self.Zone:IsAllInZoneOfCoalition( self.Coalition ) then
                                if self:Is( "Unloaded" ) then
                                    -- There are no enemies within combat radius. Reload the CargoCarrier.
                                    self:Reload()
                                end
                            else
                                if self:Is( "Loaded" ) then
                                    -- There are enemies within combat radius. Unload the CargoCarrier.
                                    self:__Unload( 1, nil, true ) -- The 2nd parameter is true, which means that the unload is for defending the carrier, not to deploy!
                                else
                                    if self:Is( "Unloaded" ) then
                                    --self:Follow()
                                    end
                                    self:F( "I am here" .. self:GetCurrentState() )
                                    if self:Is( "Following" ) then
                                        for Cargo, ShipUnit in pairs( self.Carrier_Cargo ) do
                                            local Cargo = Cargo -- Cargo.Cargo#CARGO
                                            local ShipUnit = ShipUnit -- Wrapper.Unit#UNIT
                                            if Cargo:IsAlive() then
                                                if not Cargo:IsNear( ShipUnit, 40 ) then
                                                    ShipUnit:RouteStop()
                                                    self.CarrierStopped = true
                                                else
                                                    if self.CarrierStopped then
                                                        if Cargo:IsNear( ShipUnit, 25 ) then
                                                            ShipUnit:RouteResume()
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
                end
            self.CarrierCoordinate = Ship:GetCoordinate()
        end
        self:__Monitor( -5 )
    end
end

--- Check if cargo ship is alive and trigger Load event
-- @param Wrapper.Group#Group Ship
-- @param #AI_CARGO_SHIP self
function AI_CARGO_SHIP._Pickup( Ship, self, Coordinate, Speed, PickupZone )
    
    Ship:F( { "AI_CARGO_Ship._Pickup:", Ship:GetName() } )

    if Ship:IsAlive() then
        self:Load( PickupZone )
    end
end

--- Check if cargo ship is alive and trigger Unload event. Good time to remind people that Lua is case sensitive and Unload != UnLoad
-- @param Wrapper.Group#GROUP Ship
-- @param #AI_CARGO_SHIP self
function AI_CARGO_SHIP._Deploy( Ship, self, Coordinate, DeployZone )
    Ship:F( { "AI_CARGO_Ship._Deploy:", Ship } )

    if Ship:IsAlive() then
        self:Unload( DeployZone )
    end
end

--- on after Pickup event.
-- @param AI_CARGO_SHIP Ship
-- @param From
-- @param Event
-- @param To
-- @param Core.Point#COORDINATE  Coordinate of the pickup point
-- @param #number Speed  Speed in km/h to sail to the pickup coordinate. Default is 50% of max speed for the unit
-- @param #number Height  Altitude in meters to move to the pickup coordinate. This parameter is ignored for Ships
-- @param Core.Zone#ZONE PickupZone (optional)  The zone where the cargo will be picked up. The PickupZone can be nil if there was no PickupZoneSet provided
function AI_CARGO_SHIP:onafterPickup( Ship, From, Event, To, Coordinate, Speed, Height, PickupZone )
    
    if Ship and Ship:IsAlive() then
        AI_CARGO_SHIP._Pickup( Ship, self, Coordinate, Speed, PickupZone )
        self:GetParent( self, AI_CARGO_SHIP ).onafterPickup( self, Ship, From, Event, To, Coordinate, Speed, Height, PickupZone )
    end
end

--- On after Deploy event.
-- @param #AI_CARGO_SHIP self
-- @param Wrapper.Group#GROUP SHIP
-- @param From
-- @param Event
-- @param To
-- @param Core.Point#COORDINATE Coordinate  Coordinate of the deploy point
-- @param #number Speed  Speed in km/h to sail to the deploy coordinate. Default is 50% of max speed for the unit
-- @param #number Height  Altitude in meters to move to the deploy coordinate. This parameter is ignored for Ships
-- @param Core.Zone#ZONE  DeployZone The zone where the cargo will be deployed.
function AI_CARGO_SHIP:onafterDeploy( Ship, From, Event, To, Coordinate, Speed, Height, DeployZone )

  if Ship and Ship:IsAlive() then
    
    Speed = Speed or Ship:GetSpeedMax()*0.8
    local lane = self.ShippingLane

    if lane then
      local Waypoints = {}

      for i=1, #lane do
        local coord = lane[i]
        local Waypoint = coord:WaypointGround(_speed)
        table.insert(Waypoints, Waypoint)
      end

      local TaskFunction = Ship:TaskFunction( "AI_CARGO_SHIP._Deploy", self, Coordinate, DeployZone )
      local Waypoint = Waypoints[#Waypoints]
      Ship:SetTaskWaypoint( Waypoint, TaskFunction )
      Ship:Route(Waypoints, 1)  
      self:GetParent( self, AI_CARGO_SHIP ).onafterDeploy( self, Ship, From, Event, To, Coordinate, Speed, Height, DeployZone )
    else
      self:E(self.lid.."ERROR: No shipping lane defined for Naval Transport!")
    end
  end
end

--- On after Unload event.
-- @param #AI_CARGO_SHIP self
-- @param Wrapper.Group#GROUP Ship
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Zone#ZONE DeployZone The zone wherein the cargo is deployed. This can be any zone type, like a ZONE, ZONE_GROUP, ZONE_AIRBASE.
function AI_CARGO_SHIP:onafterUnload( Ship, From, Event, To, DeployZone, Defend )
    self:F( { Ship, From, Event, To, DeployZone, Defend = Defend } )
  
    local UnboardInterval = 5
    local UnboardDelay = 5
  
    if Ship and Ship:IsAlive() then
      for _, ShipUnit in pairs( Ship:GetUnits() ) do
        local ShipUnit = ShipUnit -- Wrapper.Unit#UNIT
        Ship:RouteStop()
        for _, Cargo in pairs( ShipUnit:GetCargo() ) do
          self:F( { Cargo = Cargo:GetName(), Isloaded = Cargo:IsLoaded() } )
          if Cargo:IsLoaded() then
            local unboardCoord = DeployZone:GetRandomPointVec2()
            Cargo:__UnBoard( UnboardDelay, unboardCoord, 1000)
            UnboardDelay = UnboardDelay + Cargo:GetCount() * UnboardInterval
            self:__Unboard( UnboardDelay, Cargo, ShipUnit, DeployZone, Defend )
            if not Defend == true then
              Cargo:SetDeployed( true )
            end
          end 
        end
      end
    end
end

function AI_CARGO_SHIP:onafterHome( Ship, From, Event, To, Coordinate, Speed, Height, HomeZone )
    if Ship and Ship:IsAlive() then
        
        self.RouteHome = true
        Speed = Speed or Ship:GetSpeedMax()*0.8
        local lane = self.ShippingLane
 
        if lane then
            local Waypoints = {}

            -- Need to find a more generalized way to do this instead of reversing the shipping lane.
            -- This only works if the Source/Dest route waypoints are numbered 1..n and not n..1
            for i=#lane, 1, -1 do
                local coord = lane[i]
                local Waypoint = coord:WaypointGround(_speed)
                table.insert(Waypoints, Waypoint)
            end

            local Waypoint = Waypoints[#Waypoints]
            Ship:Route(Waypoints, 1)
        
        else
            self:E(self.lid.."ERROR: No shipping lane defined for Naval Transport!")
        end
    end
end
