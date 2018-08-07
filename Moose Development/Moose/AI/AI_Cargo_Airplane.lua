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
  Coordinate = nil -- Core.Point#COORDINATE,
}

--- Creates a new AI_CARGO_AIRPLANE object.
-- @param #AI_CARGO_AIRPLANE self
-- @param Wrapper.Group#GROUP Airplane Plane used for transportation of cargo.
-- @param Core.Set#SET_CARGO CargoSet Cargo set to be transported.
-- @return #AI_CARGO_AIRPLANE
function AI_CARGO_AIRPLANE:New( Airplane, CargoSet )

  local self = BASE:Inherit( self, FSM_CONTROLLABLE:New() ) -- #AI_CARGO_AIRPLANE

  self.CargoSet = CargoSet -- Cargo.CargoGroup#CARGO_GROUP

  self:SetStartState( "Unloaded" ) 
  
  self:AddTransition( "Unloaded", "Pickup", "*" )
  self:AddTransition( "Loaded", "Deploy", "*" )
  
  self:AddTransition( "Unloaded", "Load", "Boarding" )
  self:AddTransition( "Boarding", "Board", "Boarding" )
  self:AddTransition( "Boarding", "Loaded", "Loaded" )
  self:AddTransition( "Loaded", "Unload", "Unboarding" )
  self:AddTransition( "Unboarding", "Unboard", "Unboarding" )
  self:AddTransition( "Unboarding", "Unloaded", "Unloaded" )

  self:AddTransition( "*", "Landed", "*" )
  
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
    self:F("Calling")
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
  self:F({IsAlive=Airplane:IsAlive()})
  self:F({RoutePickup=self.RoutePickup})

  if Airplane and Airplane:IsAlive()~=nil then

    -- Aircraft was sent to this airbase to pickup troops. Initiate loadling.
    if self.RoutePickup == true then
      env.info("FF load airplane "..Airplane:GetName())
      self:Load( Airplane:GetCoordinate() )
      self.RoutePickup = false
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
-- @param Wrapper.Airbase#AIRBASE Airbase Airbase where the troops as picked up.
-- @param #number Speed in km/h for travelling to pickup base.
function AI_CARGO_AIRPLANE:onafterPickup( Airplane, From, Event, To, Airbase, Speed )

  if Airplane and Airplane:IsAlive()~=nil then
    env.info("FF onafterpick aircraft alive")
  
    -- Get closest airbase of current position.
    local ClosestAirbase, DistToAirbase=Airplane:GetCoordinate():GetClosestAirbase()
    
    env.info("FF onafterpickup closest airbase "..ClosestAirbase:GetName())
  
    -- Two cases. Aircraft spawned in air or at an airbase.
    if Airplane:InAir() then
      self.Airbase=nil  --> route will start in air
    else      
      self.Airbase=ClosestAirbase
    end
    
    -- Distance from closest to pickup airbase ==> we need to know if we are already at the pickup airbase. 
    local Dist=Airbase:GetCoordinate():Get2DDistance(ClosestAirbase:GetCoordinate())
    env.info("Distance closest to pickup airbase = "..Dist)
    
    if Airplane:InAir() or Dist>500 then
    
      env.info("FF onafterpickup routing to airbase "..ClosestAirbase:GetName())
    
      -- Route aircraft to pickup airbase.
      self:Route( Airplane, Airbase, Speed ) 
          
      -- Set airbase as starting point in the next Route() call.
      self.Airbase = Airbase
      
      -- Aircraft is on a pickup mission.
      self.RoutePickup = true
      
      -- Unclear!?
      self.Transporting = true
      self.Relocating = false
    else
      env.info("FF onafterpick calling landed")
    
      -- We are already at the right airbase ==> Landed ==> triggers loading of troops. Is usually called at engine shutdown event.
      self.RoutePickup=true
      self:Landed()
      
    end
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
-- @param Wrapper.Airbase#AIRBASE Airbase Airbase where troups should be deployed.
-- @param #number Speed Speed in km/h for travelling to deploy base.
function AI_CARGO_AIRPLANE:onafterDeploy( Airplane, From, Event, To, Airbase, Speed )

  if Airplane and Airplane:IsAlive()~=nil then
    
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
    
    -- Unclear?!
    self.Transporting = false
    self.Relocating = false
  end
  
end


--- On after Load event. Checks if cargo is inside the load radius and if so starts the boarding process.
-- @param #AI_CARGO_AIRPLANE self
-- @param Wrapper.Group#GROUP Airplane Transport plane.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Point#COORDINATE Coordinate Place where the cargo is guided to if it is inside the load radius.
function AI_CARGO_AIRPLANE:onafterLoad( Airplane, From, Event, To, Coordinate )

  if Airplane and Airplane:IsAlive()~=nil then
  
    for _,_Cargo in pairs( self.CargoSet:GetSet() ) do
      self:F({_Cargo:GetName()})
      local Cargo=_Cargo --Cargo.Cargo#CARGO
      local InRadius = Cargo:IsInLoadRadius( Coordinate )
      if InRadius then
        self:__Board( 5 )
        Cargo:Board( Airplane, 25 )
        self.Cargo = Cargo
        break
      end
      
    end
  end
  
end

--- On after Board event. Cargo is inside the load radius and boarding is performed.
-- @param #AI_CARGO_AIRPLANE self
-- @param Wrapper.Group#GROUP Airplane Cargo transport plane.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AI_CARGO_AIRPLANE:onafterBoard( Airplane, From, Event, To )

  if Airplane and Airplane:IsAlive() then
    self:F({ IsLoaded = self.Cargo:IsLoaded() } )
    if not self.Cargo:IsLoaded() then
      self:__Board( 10 )
    else
      self:__Loaded( 1 )
    end
  end
  
end

--- On after Loaded event. Cargo is inside the carrier and ready to be transported.
-- @param #AI_CARGO_AIRPLANE self
-- @param Wrapper.Group#GROUP Airplane Cargo transport plane.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AI_CARGO_AIRPLANE:onafterLoaded( Airplane, From, Event, To )

  env.info("FF troops loaded into cargo plane")
  
  if Airplane and Airplane:IsAlive() then
  end
  
end


--- On after Unload event. Cargo is beeing unloaded, i.e. the unboarding process is started.
-- @param #AI_CARGO_AIRPLANE self
-- @param Wrapper.Group#GROUP Airplane Cargo transport plane.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AI_CARGO_AIRPLANE:onafterUnload( Airplane, From, Event, To )

  if Airplane and Airplane:IsAlive() then
    self.Cargo:UnBoard()
    self:__Unboard( 10 ) 
  end
  
end

--- On after Unboard event. Checks if unboarding process is finished.
-- @param #AI_CARGO_AIRPLANE self
-- @param Wrapper.Group#GROUP Airplane Cargo transport plane.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AI_CARGO_AIRPLANE:onafterUnboard( Airplane, From, Event, To )

  if Airplane and Airplane:IsAlive() then
    if not self.Cargo:IsUnLoaded() then
      self:__Unboard( 10 ) 
    else
      self:__Unloaded( 1 )
    end
  end
  
end

--- On after Unloaded event. Cargo has been unloaded, i.e. the unboarding process is finished.
-- @param #AI_CARGO_AIRPLANE self
-- @param Wrapper.Group#GROUP Airplane Cargo transport plane.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AI_CARGO_AIRPLANE:onafterUnloaded( Airplane, From, Event, To )

  if Airplane and Airplane:IsAlive() then
    self.Airplane = Airplane
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

