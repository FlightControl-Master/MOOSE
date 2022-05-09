--- **AI** - Models the intelligent transportation of cargo using airplanes.
--
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ===       
--
-- @module AI.AI_Cargo_Airplane
-- @image AI_Cargo_Dispatching_For_Airplanes.JPG

--- @type AI_CARGO_AIRPLANE
-- @extends Core.Fsm#FSM_CONTROLLABLE


--- Brings a dynamic cargo handling capability for an AI airplane group.
--  
-- Airplane carrier equipment can be mobilized to intelligently transport infantry and other cargo within the simulation between airbases.
-- 
-- The AI_CARGO_AIRPLANE module uses the @{Cargo.Cargo} capabilities within the MOOSE framework.
-- @{Cargo.Cargo} must be declared within the mission to make AI_CARGO_AIRPLANE recognize the cargo.
-- Please consult the @{Cargo.Cargo} module for more information. 
-- 
-- ## Cargo pickup.
--  
-- Using the @{#AI_CARGO_AIRPLANE.Pickup}() method, you are able to direct the helicopters towards a point on the battlefield to board/load the cargo at the specific coordinate. 
-- Ensure that the landing zone is horizontally flat, and that trees cannot be found in the landing vicinity, or the helicopters won't land or will even crash!
-- 
-- ## Cargo deployment.
--  
-- Using the @{#AI_CARGO_AIRPLANE.Deploy}() method, you are able to direct the helicopters towards a point on the battlefield to unboard/unload the cargo at the specific coordinate. 
-- Ensure that the landing zone is horizontally flat, and that trees cannot be found in the landing vicinity, or the helicopters won't land or will even crash!
-- 
-- ## Infantry health.
-- 
-- When infantry is unboarded from the APCs, the infantry is actually respawned into the battlefield. 
-- As a result, the unboarding infantry is very _healthy_ every time it unboards.
-- This is due to the limitation of the DCS simulator, which is not able to specify the health of new spawned units as a parameter.
-- However, infantry that was destroyed when unboarded, won't be respawned again. Destroyed is destroyed.
-- As a result, there is some additional strength that is gained when an unboarding action happens, but in terms of simulation balance this has
-- marginal impact on the overall battlefield simulation. Fortunately, the firing strength of infantry is limited, and thus, respacing healthy infantry every
-- time is not so much of an issue ... 
-- 
-- 
-- @field #AI_CARGO_AIRPLANE
AI_CARGO_AIRPLANE = {
  ClassName = "AI_CARGO_AIRPLANE",
  Coordinate = nil, -- Core.Point#COORDINATE
}

--- Creates a new AI_CARGO_AIRPLANE object.
-- @param #AI_CARGO_AIRPLANE self
-- @param Wrapper.Group#GROUP Airplane Plane used for transportation of cargo.
-- @param Core.Set#SET_CARGO CargoSet Cargo set to be transported.
-- @return #AI_CARGO_AIRPLANE
function AI_CARGO_AIRPLANE:New( Airplane, CargoSet )

  local self = BASE:Inherit( self, AI_CARGO:New( Airplane, CargoSet ) ) -- #AI_CARGO_AIRPLANE

  self:AddTransition( "*", "Landed", "*" )
  self:AddTransition( "*", "Home" ,  "*" ) 
  
  self:AddTransition( "*", "Destroyed", "Destroyed" )

  --- Pickup Handler OnBefore for AI_CARGO_AIRPLANE
  -- @function [parent=#AI_CARGO_AIRPLANE] OnBeforePickup
  -- @param #AI_CARGO_AIRPLANE self
  -- @param Wrapper.Group#GROUP Airplane Cargo transport plane.
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Wrapper.Airbase#AIRBASE Airbase Airbase where troops are picked up.
  -- @param #number Speed in km/h for travelling to pickup base.
  -- @return #boolean
  
  --- Pickup Handler OnAfter for AI_CARGO_AIRPLANE
  -- @function [parent=#AI_CARGO_AIRPLANE] OnAfterPickup
  -- @param #AI_CARGO_AIRPLANE self
  -- @param Wrapper.Group#GROUP Airplane Cargo transport plane.
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Core.Point#COORDINATE Coordinate The coordinate where to pickup stuff.
  -- @param #number Speed Speed in km/h for travelling to pickup base.
  -- @param #number Height Height in meters to move to the pickup coordinate.
  -- @param Core.Zone#ZONE_AIRBASE PickupZone The airbase zone where the cargo will be picked up.
  
  --- Pickup Trigger for AI_CARGO_AIRPLANE
  -- @function [parent=#AI_CARGO_AIRPLANE] Pickup
  -- @param #AI_CARGO_AIRPLANE self
  -- @param Core.Point#COORDINATE Coordinate The coordinate where to pickup stuff.
  -- @param #number Speed Speed in km/h for travelling to pickup base.
  -- @param #number Height Height in meters to move to the pickup coordinate.
  -- @param Core.Zone#ZONE_AIRBASE PickupZone The airbase zone where the cargo will be picked up.
  
  --- Pickup Asynchronous Trigger for AI_CARGO_AIRPLANE
  -- @function [parent=#AI_CARGO_AIRPLANE] __Pickup
  -- @param #AI_CARGO_AIRPLANE self
  -- @param #number Delay Delay in seconds.
  -- @param Core.Point#COORDINATE Coordinate The coordinate where to pickup stuff.
  -- @param #number Speed Speed in km/h for travelling to pickup base.
  -- @param #number Height Height in meters to move to the pickup coordinate.
  -- @param Core.Zone#ZONE_AIRBASE PickupZone The airbase zone where the cargo will be picked up.
  
  --- Deploy Handler OnBefore for AI_CARGO_AIRPLANE
  -- @function [parent=#AI_CARGO_AIRPLANE] OnBeforeDeploy
  -- @param #AI_CARGO_AIRPLANE self
  -- @param Wrapper.Group#GROUP Airplane Cargo plane.
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param Wrapper.Airbase#AIRBASE Airbase Destination airbase where troops are deployed.
  -- @param #number Speed Speed in km/h for travelling to deploy base.
  -- @return #boolean
  
  --- Deploy Handler OnAfter for AI_CARGO_AIRPLANE
  -- @function [parent=#AI_CARGO_AIRPLANE] OnAfterDeploy
  -- @param #AI_CARGO_AIRPLANE self
  -- @param Wrapper.Group#GROUP Airplane Cargo plane.
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Core.Point#COORDINATE Coordinate Coordinate where to deploy stuff.
  -- @param #number Speed Speed in km/h for travelling to the deploy base.
  -- @param #number Height Height in meters to move to the home coordinate.
  -- @param Core.Zone#ZONE_AIRBASE DeployZone The airbase zone where the cargo will be deployed.
  
  --- Deploy Trigger for AI_CARGO_AIRPLANE
  -- @function [parent=#AI_CARGO_AIRPLANE] Deploy
  -- @param #AI_CARGO_AIRPLANE self
  -- @param Core.Point#COORDINATE Coordinate Coordinate where to deploy stuff.
  -- @param #number Speed Speed in km/h for travelling to the deploy base.
  -- @param #number Height Height in meters to move to the home coordinate.
  -- @param Core.Zone#ZONE_AIRBASE DeployZone The airbase zone where the cargo will be deployed. 
  
  --- Deploy Asynchronous Trigger for AI_CARGO_AIRPLANE
  -- @function [parent=#AI_CARGO_AIRPLANE] __Deploy
  -- @param #AI_CARGO_AIRPLANE self
  -- @param #number Delay Delay in seconds.
  -- @param Core.Point#COORDINATE Coordinate Coordinate where to deploy stuff.
  -- @param #number Speed Speed in km/h for travelling to the deploy base.
  -- @param #number Height Height in meters to move to the home coordinate.
  -- @param Core.Zone#ZONE_AIRBASE DeployZone The airbase zone where the cargo will be deployed.

  --- On after Loaded event, i.e. triggered when the cargo is inside the carrier.
  -- @function [parent=#AI_CARGO_AIRPLANE] OnAfterLoaded
  -- @param #AI_CARGO_AIRPLANE self
  -- @param Wrapper.Group#GROUP Airplane Cargo plane.
  -- @param From
  -- @param Event
  -- @param To


  --- On after Deployed event.
  -- @function [parent=#AI_CARGO_AIRPLANE] OnAfterDeployed
  -- @param #AI_CARGO_AIRPLANE self
  -- @param Wrapper.Group#GROUP Airplane Cargo plane.
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Core.Zone#ZONE DeployZone The zone wherein the cargo is deployed.
  
  -- Set carrier. 
  self:SetCarrier( Airplane )
  
  return self
end


--- Set the Carrier (controllable). Also initializes events for carrier and defines the coalition.
-- @param #AI_CARGO_AIRPLANE self
-- @param Wrapper.Group#GROUP Airplane Transport plane.
-- @return #AI_CARGO_AIRPLANE self
function AI_CARGO_AIRPLANE:SetCarrier( Airplane )

  local AICargo = self

  self.Airplane = Airplane -- Wrapper.Group#GROUP
  self.Airplane:SetState( self.Airplane, "AI_CARGO_AIRPLANE", self )

  self.RoutePickup = false
  self.RouteDeploy = false

  Airplane:HandleEvent( EVENTS.Dead )
  Airplane:HandleEvent( EVENTS.Hit )
  Airplane:HandleEvent( EVENTS.EngineShutdown )
  
  function Airplane:OnEventDead( EventData )
    local AICargoTroops = self:GetState( self, "AI_CARGO_AIRPLANE" )
    self:F({AICargoTroops=AICargoTroops})
    if AICargoTroops then
      self:F({})
      if not AICargoTroops:Is( "Loaded" ) then
        -- There are enemies within combat range. Unload the Airplane.
        AICargoTroops:Destroyed()
      end
    end
  end
  
  
  function Airplane:OnEventHit( EventData )
    local AICargoTroops = self:GetState( self, "AI_CARGO_AIRPLANE" )
    if AICargoTroops then
      self:F( { OnHitLoaded = AICargoTroops:Is( "Loaded" ) } )
      if AICargoTroops:Is( "Loaded" ) or AICargoTroops:Is( "Boarding" ) then
        -- There are enemies within combat range. Unload the Airplane.
        AICargoTroops:Unload()
      end
    end
  end
  
  
  function Airplane:OnEventEngineShutdown( EventData )
    AICargo.Relocating = false
    AICargo:Landed( self.Airplane )
  end
  
  self.Coalition = self.Airplane:GetCoalition()
  
  self:SetControllable( Airplane )

  return self
end


--- Find a free Carrier within a range.
-- @param #AI_CARGO_AIRPLANE self
-- @param Wrapper.Airbase#AIRBASE Airbase
-- @param #number Radius
-- @return Wrapper.Group#GROUP NewCarrier
function AI_CARGO_AIRPLANE:FindCarrier( Coordinate, Radius )

  local CoordinateZone = ZONE_RADIUS:New( "Zone" , Coordinate:GetVec2(), Radius )
  CoordinateZone:Scan( { Object.Category.UNIT } )
  for _, DCSUnit in pairs( CoordinateZone:GetScannedUnits() ) do
    local NearUnit = UNIT:Find( DCSUnit )
    self:F({NearUnit=NearUnit})
    if not NearUnit:GetState( NearUnit, "AI_CARGO_AIRPLANE" ) then
      local Attributes = NearUnit:GetDesc()
      self:F({Desc=Attributes})
      if NearUnit:HasAttribute( "Trucks" ) then
        self:SetCarrier( NearUnit )
        break
      end
    end
  end

end

--- On after "Landed" event. Called on engine shutdown and initiates the pickup mission or unloading event.
-- @param #AI_CARGO_AIRPLANE self
-- @param Wrapper.Group#GROUP Airplane Cargo transport plane.
-- @param From
-- @param Event
-- @param To
function AI_CARGO_AIRPLANE:onafterLanded( Airplane, From, Event, To )

  self:F({Airplane, From, Event, To})

  if Airplane and Airplane:IsAlive()~=nil then

    -- Aircraft was sent to this airbase to pickup troops. Initiate loadling.
    if self.RoutePickup == true then
      self:Load( self.PickupZone )
    end
    
    -- Aircraft was send to this airbase to deploy troops. Initiate unloading.
    if self.RouteDeploy == true then
      self:Unload()
      self.RouteDeploy = false
    end
     
  end
  
end


--- On after "Pickup" event. Routes transport to pickup airbase.
-- @param #AI_CARGO_AIRPLANE self
-- @param Wrapper.Group#GROUP Airplane Cargo transport plane.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Point#COORDINATE Coordinate The coordinate where to pickup stuff.
-- @param #number Speed Speed in km/h for travelling to pickup base.
-- @param #number Height Height in meters to move to the pickup coordinate.
-- @param Core.Zone#ZONE_AIRBASE PickupZone The airbase zone where the cargo will be picked up.
function AI_CARGO_AIRPLANE:onafterPickup( Airplane, From, Event, To, Coordinate, Speed, Height, PickupZone )

  if Airplane and Airplane:IsAlive() then
    
    local airbasepickup=Coordinate:GetClosestAirbase()
    
    self.PickupZone = PickupZone or ZONE_AIRBASE:New(airbasepickup:GetName())
  
    -- Get closest airbase of current position.
    local ClosestAirbase, DistToAirbase=Airplane:GetCoordinate():GetClosestAirbase()
  
    -- Two cases. Aircraft spawned in air or at an airbase.
    if Airplane:InAir() then
      self.Airbase=nil  --> route will start in air
    else      
      self.Airbase=ClosestAirbase
    end
    
    -- Set pickup airbase.
    local Airbase = self.PickupZone:GetAirbase()
    
    -- Distance from closest to pickup airbase ==> we need to know if we are already at the pickup airbase. 
    local Dist = Airbase:GetCoordinate():Get2DDistance(ClosestAirbase:GetCoordinate())
    
    if Airplane:InAir() or Dist>500 then
    
      -- Route aircraft to pickup airbase.
      self:Route( Airplane, Airbase, Speed, Height ) 
          
      -- Set airbase as starting point in the next Route() call.
      self.Airbase = Airbase
      
      -- Aircraft is on a pickup mission.
      self.RoutePickup = true
      
    else
    
      -- We are already at the right airbase ==> Landed ==> triggers loading of troops. Is usually called at engine shutdown event.
      self.RoutePickup=true
      self:Landed()
      
    end

    self:GetParent( self, AI_CARGO_AIRPLANE ).onafterPickup( self, Airplane, From, Event, To, Coordinate, Speed, Height, self.PickupZone )
    
  end

  
end

--- On after Depoly event. Routes plane to the airbase where the troops are deployed.
-- @param #AI_CARGO_AIRPLANE self
-- @param Wrapper.Group#GROUP Airplane Cargo transport plane.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Point#COORDINATE Coordinate Coordinate where to deploy stuff.
-- @param #number Speed Speed in km/h for travelling to the deploy base.
-- @param #number Height Height in meters to move to the home coordinate.
-- @param Core.Zone#ZONE_AIRBASE DeployZone The airbase zone where the cargo will be deployed.
function AI_CARGO_AIRPLANE:onafterDeploy( Airplane, From, Event, To, Coordinate, Speed, Height, DeployZone )

  if Airplane and Airplane:IsAlive()~=nil then
    
    local Airbase = Coordinate:GetClosestAirbase()
    
    if DeployZone then
      Airbase=DeployZone:GetAirbase()
    end
    
    -- Activate uncontrolled airplane.
    if Airplane:IsAlive()==false then
      Airplane:SetCommand({id = 'Start', params = {}})
    end
    
    -- Route to destination airbase.
    self:Route( Airplane, Airbase, Speed, Height )
    
    -- Aircraft is on a depoly mission.
    self.RouteDeploy = true
    
    -- Set destination airbase for next :Route() command.
    self.Airbase = Airbase
    
    self:GetParent( self, AI_CARGO_AIRPLANE ).onafterDeploy( self, Airplane, From, Event, To, Coordinate, Speed, Height, DeployZone )
  end
  
end


--- On after Unload event. Cargo is beeing unloaded, i.e. the unboarding process is started.
-- @param #AI_CARGO_AIRPLANE self
-- @param Wrapper.Group#GROUP Airplane Cargo transport plane.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Zone#ZONE_AIRBASE DeployZone The airbase zone where the cargo will be deployed.
function AI_CARGO_AIRPLANE:onafterUnload( Airplane, From, Event, To, DeployZone )

  local UnboardInterval = 10
  local UnboardDelay = 10

  if Airplane and Airplane:IsAlive() then
    for _, AirplaneUnit in pairs( Airplane:GetUnits() ) do
      local Cargos = AirplaneUnit:GetCargo()
      for CargoID, Cargo in pairs( Cargos ) do
      
        local Angle = 180
        local CargoCarrierHeading = Airplane:GetHeading() -- Get Heading of object in degrees.
        local CargoDeployHeading = ( ( CargoCarrierHeading + Angle ) >= 360 ) and ( CargoCarrierHeading + Angle - 360 ) or ( CargoCarrierHeading + Angle )
        self:T( { CargoCarrierHeading, CargoDeployHeading } )
        local CargoDeployCoordinate = Airplane:GetPointVec2():Translate( 150, CargoDeployHeading )
      
         Cargo:__UnBoard( UnboardDelay, CargoDeployCoordinate )
         UnboardDelay = UnboardDelay + UnboardInterval
         Cargo:SetDeployed( true )
         self:__Unboard( UnboardDelay, Cargo, AirplaneUnit, DeployZone ) 
      end
    end
  end
  
end

--- Route the airplane from one airport or it's current position to another airbase.
-- @param #AI_CARGO_AIRPLANE self
-- @param Wrapper.Group#GROUP Airplane Airplane group to be routed.
-- @param Wrapper.Airbase#AIRBASE Airbase Destination airbase.
-- @param #number Speed Speed in km/h. Default is 80% of max possible speed the group can do.
-- @param #number Height Height in meters to move to the Airbase.
-- @param #boolean Uncontrolled If true, spawn group in uncontrolled state.
function AI_CARGO_AIRPLANE:Route( Airplane, Airbase, Speed, Height, Uncontrolled )

  if Airplane and Airplane:IsAlive() then

    -- Set takeoff type.
    local Takeoff = SPAWN.Takeoff.Cold
    
    -- Get template of group.
    local Template = Airplane:GetTemplate()
    
    -- Nil check
    if Template==nil then
      return
    end

    -- Waypoints of the route.
    local Points={}
    
    -- To point.
    local AirbasePointVec2 = Airbase:GetPointVec2()
    local ToWaypoint = AirbasePointVec2:WaypointAir(POINT_VEC3.RoutePointAltType.BARO, "Land", "Landing", Speed or Airplane:GetSpeedMax()*0.8, true, Airbase)
        
    --ToWaypoint["airdromeId"]   = Airbase:GetID()
    --ToWaypoint["speed_locked"] = true
    

    -- If self.Airbase~=nil then group is currently at an airbase, where it should be respawned.        
    if self.Airbase then
    
      -- Second point of the route. First point is done in RespawnAtCurrentAirbase() routine.
      Template.route.points[2] = ToWaypoint
    
      -- Respawn group at the current airbase.
      Airplane:RespawnAtCurrentAirbase(Template, Takeoff, Uncontrolled)
      
    else
  
      -- From point.
      local GroupPoint = Airplane:GetVec2()
      local FromWaypoint = {}
      FromWaypoint.x      = GroupPoint.x
      FromWaypoint.y      = GroupPoint.y
      FromWaypoint.type   = "Turning Point"
      FromWaypoint.action = "Turning Point"
      FromWaypoint.speed  = Airplane:GetSpeedMax()*0.8
 
      -- The two route points. 
      Points[1] = FromWaypoint
      Points[2] = ToWaypoint

      local PointVec3 = Airplane:GetPointVec3()
      Template.x = PointVec3.x
      Template.y = PointVec3.z
 
      Template.route.points = Points
            
      local GroupSpawned = Airplane:Respawn(Template)
    
    end
  end
end

--- On after Home event. Aircraft will be routed to their home base.
-- @param #AI_CARGO_AIRPLANE self
-- @param Wrapper.Group#GROUP Airplane The cargo plane.
-- @param From From state.
-- @param Event Event.
-- @param To To State.
-- @param Core.Point#COORDINATE Coordinate Home place (not used).
-- @param #number Speed Speed in km/h to fly to the home airbase (zone). Default is 80% of max possible speed the unit can go.
-- @param #number Height Height in meters to move to the home coordinate.
-- @param Core.Zone#ZONE_AIRBASE HomeZone The home airbase (zone) where the plane should return to.
function AI_CARGO_AIRPLANE:onafterHome(Airplane, From, Event, To, Coordinate, Speed, Height, HomeZone )
  if Airplane and Airplane:IsAlive() then

    -- We are going home!
    self.RouteHome = true
       
    -- Home Base.
    local HomeBase=HomeZone:GetAirbase()
    self.Airbase=HomeBase
    
    -- Now route the airplane home
   self:Route( Airplane, HomeBase, Speed, Height )
    
  end
  
end
