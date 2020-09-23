--- **AI** -- (R2.5.1) - Models the intelligent transportation of infantry and other cargo.

-- @field #AI_CARGO_SHIP
AI_CARGO_SHIP = {
    ClassName = "AI_CARGO_SHIP",
    Coordinate = nil -- Core.Point#COORDINATE
}

--- Creates a new AI_CARGO_SHIP object.
function AI_CARGO_SHIP:New( Ship, CargoSet, CombatRadius, ShippingLane )

    local self = BASE:Inherit( self, AI_CARGO:New( Ship, CargoSet ) ) -- #AI_CARGO_SHIP

    self:AddTransition( "*", "Monitor", "*" )

    self:AddTransition( "*", "Destroyed", "Destroyed" )
    self:AddTransition( "*", "Home", "*" )

    self:SetCombatRadius( CombatRadius )
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
    BASE:T("DEBUGGING*** AI_CARGO_SHIP:FollowToCarrier")
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


function AI_CARGO_SHIP._Pickup( Ship, self, Coordinate, Speed, PickupZone )
    Ship:F( { "AI_CARGO_Ship._Pickup:", Ship:GetName() } )

    if Ship:IsAlive() then
        self:Load( PickupZone )
    end
end


function AI_CARGO_SHIP._Deploy( Ship, self, Coordinate, DeployZone )

    Ship:F( { "AI_CARGO_Ship._Deploy:", Ship } )

    if Ship:IsAlive() then
        self:Unload( DeployZone )
    end
end

function AI_CARGO_SHIP:onafterPickup( Ship, From, Event, To, Coordinate, Speed, Height, PickupZone )
    
    if Ship and Ship:IsAlive() then
        AI_CARGO_SHIP._Pickup( Ship, self, Coordinate, Speed, PickupZone )
        self:GetParent( self, AI_CARGO_SHIP ).onafterPickup( self, Ship, From, Event, To, Coordinate, Speed, Height, PickupZone )
    end
end

function AI_CARGO_SHIP:onafterPickedUp( Ship, From, Event, To, Coordinate, Speed, Height, PickupZone )

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

            local Waypoint = Waypoints[#Waypoints]
            Ship:Route(Waypoints, 1)
        
        else
            BASE:T("ERROR: No shipping lane defined for Naval Transport!")
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

        for i=1, #lane do
            local coord = lane[i]
            local Waypoint = coord:WaypointGround(_speed)
            table.insert(Waypoints, Waypoint)
        end

        local Waypoint = Waypoints[#Waypoints]

        Ship:Route(Waypoints, 1)
        
        else
            BASE:T("ERROR: No shipping lane defined for Naval Transport!")
        end
    end
end
