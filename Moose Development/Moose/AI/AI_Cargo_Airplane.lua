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
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param Wrapper.Airbase#AIRBASE Airbase Airbase where troops are picked up.
  -- @return #boolean
  
  --- Pickup Handler OnAfter for AI_CARGO_AIRPLANE
  -- @function [parent=#AI_CARGO_AIRPLANE] OnAfterPickup
  -- @param #AI_CARGO_AIRPLANE self
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param Wrapper.Airbase#AIRBASE Airbase Airbase where troops are picked up.
  
  --- Pickup Trigger for AI_CARGO_AIRPLANE
  -- @function [parent=#AI_CARGO_AIRPLANE] Pickup
  -- @param #AI_CARGO_AIRPLANE self
  -- @param Wrapper.Airbase#AIRBASE Airbase Airbase where troops are picked up.
  
  --- Pickup Asynchronous Trigger for AI_CARGO_AIRPLANE
  -- @function [parent=#AI_CARGO_AIRPLANE] __Pickup
  -- @param #AI_CARGO_AIRPLANE self
  -- @param #number Delay Delay in seconds.
  -- @param Wrapper.Airbase#AIRBASE Airbase Airbase where troops are picked up.
  
  --- Deploy Handler OnBefore for AI_CARGO_AIRPLANE
  -- @function [parent=#AI_CARGO_AIRPLANE] OnBeforeDeploy
  -- @param #AI_CARGO_AIRPLANE self
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param Wrapper.Airbase#AIRBASE Airbase Destination airbase where troops are deployed.
  -- @param #number Speed Speed in km/h for travelling to deploy base.
  -- @return #boolean
  
  --- Deploy Handler OnAfter for AI_CARGO_AIRPLANE
  -- @function [parent=#AI_CARGO_AIRPLANE] OnAfterDeploy
  -- @param #AI_CARGO_AIRPLANE self
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
  
  self:SetCarrier( Airplane )
  
  return self
end


--- Set the Carrier.
-- @param #AI_CARGO_AIRPLANE self
-- @param Wrapper.Group#GROUP Airplane
-- @return #AI_CARGO_AIRPLANE
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
    AICargo:Landed()
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

--- On after "Landed" event. Called on engine shutdown.
-- @param #AI_CARGO_AIRPLANE self
-- @param Wrapper.Group#GROUP Airplane Transport plane.
-- @param From
-- @param Event
-- @param To
function AI_CARGO_AIRPLANE:onafterLanded( Airplane, From, Event, To )

  if Airplane and Airplane:IsAlive() then

    if self.RoutePickup == true then
      self:Load( Airplane:GetPointVec2() )
      self.RoutePickup = false
    end
    
    if self.RouteDeploy == true then
      self:Unload()
      self.RouteDeploy = false
    end
     
  end
  
end


--- On after "Pickup" event. Routes transport to pickup airbase.
-- @param #AI_CARGO_AIRPLANE self
-- @param Wrapper.Group#GROUP Airplane
-- @param From
-- @param Event
-- @param To
-- @param Wrapper.Airbase#AIRBASE Airbase
-- @param #number Speed
function AI_CARGO_AIRPLANE:onafterPickup( Airplane, From, Event, To, Airbase, Speed )

  if Airplane and Airplane:IsAlive() then
  
    -- Aircraft might be on the ground of the pickup airbase already.
    if Airplane:InAir() then
      self:Route( Airplane, Airbase, Speed )
    end
    -- TODO: Improve :Route() so that the aircraft can be routed from another airbase to the pickup airbase. 
    
    self.RoutePickup = true
    
    -- Set airbase as starting point in the next Route() call.
    self.Airbase = Airbase
  end
  
end

--- On after Depoly event. Routes plane to deploy airbase.
-- @param #AI_CARGO_AIRPLANE self
-- @param Wrapper.Group#GROUP Airplane
-- @param From
-- @param Event
-- @param To
-- @param Wrapper.Airbase#AIRBASE Airbase Airbase where troups should be deployed.
-- @param #number Speed Speed in km/h for travelling to deploy base.
function AI_CARGO_AIRPLANE:onafterDeploy( Airplane, From, Event, To, Airbase, Speed )

  if Airplane and Airplane:IsAlive() then
  
    -- Route to 
    self:Route( Airplane, Airbase, Speed )
    self.RouteDeploy = true
    self.Airbase = Airbase
  end
  
end


--- On after Load event.
-- @param #AI_CARGO_AIRPLANE self
-- @param Wrapper.Group#GROUP Airplane Transport plane.
-- @param From
-- @param Event
-- @param To
-- @param Wrapper.Point#COORDINATE Coordinate 
function AI_CARGO_AIRPLANE:onafterLoad( Airplane, From, Event, To, Coordinate )

  if Airplane and Airplane:IsAlive() then
  
    for _, Cargo in pairs( self.CargoSet:GetSet() ) do
      local Cargo=Cargo --Cargo.Cargo#CARGO
      if Cargo:IsInLoadRadius( Coordinate ) then
        self:__Board( 5 )
        Cargo:Board( Airplane, 25 )
        self.Cargo = Cargo
        break
      end
      
    end
  end
  
end

--- On after Board event.
-- @param #AI_CARGO_AIRPLANE self
-- @param Wrapper.Group#GROUP Airplane Cargo plane.
-- @param From
-- @param Event
-- @param To
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

--- On after Loaded event.
-- @param #AI_CARGO_AIRPLANE self
-- @param Wrapper.Group#GROUP Airplane Cargo plane.
-- @param From
-- @param Event
-- @param To
function AI_CARGO_AIRPLANE:onafterLoaded( Airplane, From, Event, To )

  if Airplane and Airplane:IsAlive() then
  end
  
end


--- On after Unload event.
-- @param #AI_CARGO_AIRPLANE self
-- @param Wrapper.Group#GROUP Airplane Cargo plane.
-- @param From
-- @param Event
-- @param To
function AI_CARGO_AIRPLANE:onafterUnload( Airplane, From, Event, To )

  if Airplane and Airplane:IsAlive() then
    self.Cargo:UnBoard()
    self:__Unboard( 10 ) 
  end
  
end

--- On after Unboard event.
-- @param #AI_CARGO_AIRPLANE self
-- @param Wrapper.Group#GROUP Airplane Cargo plane.
-- @param From
-- @param Event
-- @param To
function AI_CARGO_AIRPLANE:onafterUnboard( Airplane, From, Event, To )

  if Airplane and Airplane:IsAlive() then
    if not self.Cargo:IsUnLoaded() then
      self:__Unboard( 10 ) 
    else
      self:__Unloaded( 1 )
    end
  end
  
end

--- On after Unloaded event.
-- @param #AI_CARGO_AIRPLANE self
-- @param Wrapper.Group#GROUP Airplane Cargo plane.
-- @param From
-- @param Event
-- @param To
function AI_CARGO_AIRPLANE:onafterUnloaded( Airplane, From, Event, To )

  if Airplane and Airplane:IsAlive() then
    self.Airplane = Airplane
  end
  
end


--- @param #AI_CARGO_AIRPLANE self
-- @param Wrapper.Group#GROUP Airplane
-- @param Wrapper.Airbase#AIRBASE Airbase
-- @param #number Speed
function AI_CARGO_AIRPLANE:Route( Airplane, Airbase, Speed )

  if Airplane and Airplane:IsAlive() then

    local PointVec3 = Airplane:GetPointVec3()
  
    local Takeoff = SPAWN.Takeoff.Hot
    
    local Template = Airplane:GetTemplate()
  
    if Template then

      local Points = {}
      
      if self.Airbase then
  
        local FromWaypoint = Template.route.points[1] 
    
        -- These are only for ships.
        FromWaypoint.linkUnit = nil
        FromWaypoint.helipadId = nil
        FromWaypoint.airdromeId = nil
    
        local AirbaseID = self.Airbase:GetID()
        local AirbaseCategory = self.Airbase:GetDesc().category
        
        FromWaypoint.airdromeId = AirbaseID
    
        FromWaypoint.alt = 0
                
        FromWaypoint.type = GROUPTEMPLATE.Takeoff[Takeoff][1] -- type
        FromWaypoint.action = GROUPTEMPLATE.Takeoff[Takeoff][2] -- action
        
    
        -- Translate the position of the Group Template to the Vec3.
        for UnitID = 1, #Template.units do
          self:T( 'Before Translation SpawnTemplate.units['..UnitID..'].x = ' .. Template.units[UnitID].x .. ', SpawnTemplate.units['..UnitID..'].y = ' .. Template.units[UnitID].y )
    
          -- These cause a lot of confusion.
          local UnitTemplate = Template.units[UnitID]
    
          UnitTemplate.parking = 15
          UnitTemplate.parking_id = "1"
          UnitTemplate.alt = 0
    
          local SX = UnitTemplate.x
          local SY = UnitTemplate.y 
          local BX = FromWaypoint.x
          local BY = FromWaypoint.y
          local TX = PointVec3.x + ( SX - BX )
          local TY = PointVec3.z + ( SY - BY )
          
          UnitTemplate.x = TX
          UnitTemplate.y = TY
          
          self:T( 'After Translation SpawnTemplate.units['..UnitID..'].x = ' .. UnitTemplate.x .. ', SpawnTemplate.units['..UnitID..'].y = ' .. UnitTemplate.y )
        end
        
        FromWaypoint.x = PointVec3.x
        FromWaypoint.y = PointVec3.z

        Points[#Points+1] = FromWaypoint
      else
        
        local GroupPoint = Airplane:GetVec2()
        local GroupVelocity = Airplane:GetUnit(1):GetDesc().speedMax
    
        local FromWaypoint = {}
        FromWaypoint.x = GroupPoint.x
        FromWaypoint.y = GroupPoint.y
        FromWaypoint.type = "Turning Point"
        FromWaypoint.action = "Turning Point"
        FromWaypoint.speed = GroupVelocity

        Points[#Points+1] = FromWaypoint
      end
      
      local AirbasePointVec2 = Airbase:GetPointVec2()
      local ToWaypoint = AirbasePointVec2:WaypointAir(
        POINT_VEC3.RoutePointAltType.BARO,
        "Land",
        "Landing", 
        Speed or Airplane:GetUnit(1):GetDesc().speedMax
      )
      
      ToWaypoint["airdromeId"] = Airbase:GetID()
      ToWaypoint["speed_locked"] = true,
  
      self:F( ToWaypoint )
      
      Points[#Points+1] = ToWaypoint
  
      Template.x = PointVec3.x
      Template.y = PointVec3.z
      
      self:T3( Points )
      Template.route.points = Points

      --self:Respawn( Template )

      local GroupSpawned = Airplane:Respawn( Template )
      
      return GroupSpawned
    end

  end
  
end
