--- **AI** -- (R2.3) - Models the intelligent transportation of infantry (cargo).
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


--- Implements the transportation of cargo by airplanes.
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

  self.CargoSet = CargoSet -- Cargo.CargoGroup#CARGO_GROUP

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
  -- @param Wrapper.Group#GROUP Airplane Cargo plane.
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param Wrapper.Airbase#AIRBASE Airbase Airbase where troops are picked up.
  -- @param #number Speed in km/h for travelling to pickup base.
  
  --- Pickup Trigger for AI_CARGO_AIRPLANE
  -- @function [parent=#AI_CARGO_AIRPLANE] Pickup
  -- @param #AI_CARGO_AIRPLANE self
  -- @param Wrapper.Airbase#AIRBASE Airbase Airbase where troops are picked up.
  -- @param #number Speed in km/h for travelling to pickup base.
  
  --- Pickup Asynchronous Trigger for AI_CARGO_AIRPLANE
  -- @function [parent=#AI_CARGO_AIRPLANE] __Pickup
  -- @param #AI_CARGO_AIRPLANE self
  -- @param #number Delay Delay in seconds.
  -- @param Wrapper.Airbase#AIRBASE Airbase Airbase where troops are picked up.
  -- @param #number Speed in km/h for travelling to pickup base.
  
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
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param Wrapper.Airbase#AIRBASE Airbase Destination airbase where troops are deployed.
  -- @param #number Speed Speed in km/h for travelling to deploy base.
  
  --- Deploy Trigger for AI_CARGO_AIRPLANE
  -- @function [parent=#AI_CARGO_AIRPLANE] Deploy
  -- @param #AI_CARGO_AIRPLANE self
  -- @param Wrapper.Airbase#AIRBASE Airbase Destination airbase where troops are deployed.
  -- @param #number Speed Speed in km/h for travelling to deploy base.
  
  --- Deploy Asynchronous Trigger for AI_CARGO_AIRPLANE
  -- @function [parent=#AI_CARGO_AIRPLANE] __Deploy
  -- @param #AI_CARGO_AIRPLANE self
  -- @param #number Delay Delay in seconds.
  -- @param Wrapper.Airbase#AIRBASE Airbase Destination airbase where troops are deployed.
  -- @param #number Speed Speed in km/h for travelling to deploy base.

  --- On after Loaded event, i.e. triggered when the cargo is inside the carrier.
  -- @function [parent=#AI_CARGO_AIRPLANE] OnAfterLoaded
  -- @param #AI_CARGO_AIRPLANE self
  -- @param Wrapper.Group#GROUP Airplane Cargo plane.
  -- @param From
  -- @param Event
  -- @param To
  
  -- Set carrier. 
  self:SetCarrier( Airplane )
  
  for _, AirplaneUnit in pairs( Airplane:GetUnits() ) do
    AirplaneUnit:SetCargoBayWeightLimit()
  end
    
  self.Relocating = true
  
  return self
end


function AI_CARGO_AIRPLANE:IsTransporting()

  return self.Transporting == true
end

function AI_CARGO_AIRPLANE:IsRelocating()

  return self.Relocating == true
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
      env.info("FF load airplane "..Airplane:GetName())
      self:Load( self.PickupZone )
      self.RoutePickup = false
      self.Relocating = true
    end
    
    -- Aircraft was send to this airbase to deploy troops. Initiate unloading.
    if self.RouteDeploy == true then
      self:Unload()
      self.RouteDeploy = false
      self.Transporting = false
      self.Relocating = false
    end
     
  end
  
end


--- On after "Pickup" event. Routes transport to pickup airbase.
-- @param #AI_CARGO_AIRPLANE self
-- @param Wrapper.Group#GROUP Airplane Cargo transport plane.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Point#COORDINATE Coordinate
-- @param #number Speed in km/h for travelling to pickup base.
-- @param Core.Zone#ZONE_AIRBASE PickupZone
function AI_CARGO_AIRPLANE:onafterPickup( Airplane, From, Event, To, Coordinate, Speed, PickupZone )

  if Airplane and Airplane:IsAlive()~=nil then
    env.info("FF onafterpick aircraft alive")
    
    self.PickupZone = PickupZone
  
    -- Get closest airbase of current position.
    local ClosestAirbase, DistToAirbase=Airplane:GetCoordinate():GetClosestAirbase()
    
    env.info("FF onafterpickup closest airbase "..ClosestAirbase:GetName())
  
    -- Two cases. Aircraft spawned in air or at an airbase.
    if Airplane:InAir() then
      self.Airbase=nil  --> route will start in air
    else      
      self.Airbase=ClosestAirbase
    end
    
    local Airbase = PickupZone:GetAirbase()
    
    -- Distance from closest to pickup airbase ==> we need to know if we are already at the pickup airbase. 
    local Dist = Airbase:GetCoordinate():Get2DDistance(ClosestAirbase:GetCoordinate())
    env.info("Distance closest to pickup airbase = "..Dist)
    
    if Airplane:InAir() or Dist>500 then
    
      env.info("FF onafterpickup routing to airbase "..ClosestAirbase:GetName())
    
      -- Route aircraft to pickup airbase.
      self:Route( Airplane, Airbase, Speed ) 
          
      -- Set airbase as starting point in the next Route() call.
      self.Airbase = Airbase
      
      -- Aircraft is on a pickup mission.
      self.RoutePickup = true
      
    else
      env.info("FF onafterpick calling landed")
    
      -- We are already at the right airbase ==> Landed ==> triggers loading of troops. Is usually called at engine shutdown event.
      self.RoutePickup=true
      self:Landed()
      
    end

    self.Transporting = false
    self.Relocating = true
  else
    env.info("FF onafterpick aircraft not alive")
  end

  
end

--- On after Depoly event. Routes plane to the airbase where the troops are deployed.
-- @param #AI_CARGO_AIRPLANE self
-- @param Wrapper.Group#GROUP Airplane Cargo transport plane.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Point#COORDINATE Coordinate
-- @param #number Speed in km/h for travelling to pickup base.
-- @param Core.Zone#ZONE_AIRBASE DeployZone
function AI_CARGO_AIRPLANE:onafterDeploy( Airplane, From, Event, To, Coordinate, Speed, DeployZone )

  if Airplane and Airplane:IsAlive()~=nil then
    
    local Airbase = DeployZone:GetAirbase()
    
    -- Activate uncontrolled airplane.
    if Airplane:IsAlive()==false then
      Airplane:SetCommand({id = 'Start', params = {}})
    end
    
    -- Route to destination airbase.
    self:Route( Airplane, Airbase, Speed )
    
    -- Aircraft is on a depoly mission.
    self.RouteDeploy = true
    
    -- Set destination airbase for next :Route() command.
    self.Airbase = Airbase
    
    self.Transporting = true
    self.Relocating = false
  end
  
end



--- On after PickedUp event. All cargo is inside the carrier and ready to be transported.
-- @param #AI_CARGO_AIRPLANE self
-- @param Wrapper.Group#GROUP Airplane Cargo transport plane.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Zone#ZONE PickupZone (optional) The zone where the cargo will be picked up. The PickupZone can be nil, if there wasn't any PickupZoneSet provided.
function AI_CARGO_AIRPLANE:onafterPickedUp( Airplane, From, Event, To, PickupZone )
  self:F( { AirplaneGroup, From, Event, To } )

  if Airplane and Airplane:IsAlive() then
    self.Transporting = true -- This will only be executed when there is no cargo boarded anymore. The dispatcher will then kick-off the deploy cycle!
  end
end


--- On after Unload event. Cargo is beeing unloaded, i.e. the unboarding process is started.
-- @param #AI_CARGO_AIRPLANE self
-- @param Wrapper.Group#GROUP Airplane Cargo transport plane.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
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



--- On after Deployed event.
-- @param #AI_CARGO_AIRPLANE self
-- @param Wrapper.Group#GROUP Airplane Cargo transport plane.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Cargo.Cargo#CARGO Cargo
function AI_CARGO_AIRPLANE:onafterDeployed( Airplane, From, Event, To, DeployZone )

  if Airplane and Airplane:IsAlive() then
    self.Transporting = false -- This will only be executed when there is no cargo onboard anymore. The dispatcher will then kick-off the pickup cycle!
  end
end




--- Route the airplane from one airport or it's current position to another airbase.
-- @param #AI_CARGO_AIRPLANE self
-- @param Wrapper.Group#GROUP Airplane Airplane group to be routed.
-- @param Wrapper.Airbase#AIRBASE Airbase Destination airbase.
-- @param #number Speed Speed in km/h. Default is 80% of max possible speed the group can do.
-- @param #boolean Uncontrolled If true, spawn group in uncontrolled state.
function AI_CARGO_AIRPLANE:Route( Airplane, Airbase, Speed, Uncontrolled )

  if Airplane and Airplane:IsAlive()~=nil then

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
    local ToWaypoint = AirbasePointVec2:WaypointAir(
      POINT_VEC3.RoutePointAltType.BARO,
      "Land",
      "Landing", 
      Speed or Airplane:GetSpeedMax()*0.8
    )    
    ToWaypoint["airdromeId"]   = Airbase:GetID()
    ToWaypoint["speed_locked"] = true
    

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
