--- **AI** -- (R2.3) - Models the intelligent transportation of infantry (cargo).
--
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ===       
--
-- @module AI.AI_Cargo_Helicopter
-- @image AI_Cargo_Dispatching_For_Helicopters.JPG

--- @type AI_CARGO_HELICOPTER
-- @extends Core.Fsm#FSM_CONTROLLABLE


--- # AI\_CARGO\_TROOPS class, extends @{Core.Fsm#FSM_CONTROLLABLE}
-- 
-- ===
-- 
-- @field #AI_CARGO_HELICOPTER
AI_CARGO_HELICOPTER = {
  ClassName = "AI_CARGO_HELICOPTER",
  Coordinate = nil, -- Core.Point#COORDINATE,
  Helicopter_Cargo = {},
}

AI_CARGO_QUEUE = {}

--- Creates a new AI_CARGO_HELICOPTER object.
-- @param #AI_CARGO_HELICOPTER self
-- @param Wrapper.Group#GROUP Helicopter
-- @param Core.Set#SET_CARGO CargoSet
-- @return #AI_CARGO_HELICOPTER
function AI_CARGO_HELICOPTER:New( Helicopter, CargoSet )

  local self = BASE:Inherit( self, FSM_CONTROLLABLE:New() ) -- #AI_CARGO_HELICOPTER

  self.CargoSet = CargoSet -- Cargo.CargoGroup#CARGO_GROUP
  
  self.Zone = ZONE_GROUP:New( Helicopter:GetName(), Helicopter, 300 )

  self:SetStartState( "Unloaded" ) 
  
  self:AddTransition( "Unloaded", "Pickup", "*" )
  self:AddTransition( "Loaded", "Deploy", "*" )
  
  self:AddTransition( { "Unloaded", "Loading" }, "Load", "Boarding" )
  self:AddTransition( "Boarding", "Board", "Boarding" )
  self:AddTransition( "Boarding", "Loaded", "Boarding" )
  self:AddTransition( "Boarding", "PickedUp", "Loaded" )
  self:AddTransition( "Loaded", "Unload", "Unboarding" )
  self:AddTransition( "Unboarding", "Unboard", "Unboarding" )
  self:AddTransition( "Unboarding", "Unloaded", "Unboarding" )
  self:AddTransition( "Unboarding", "Deployed", "Unloaded" )

  self:AddTransition( "*", "Landed", "*" )
  self:AddTransition( "*", "Queue", "*" )
  self:AddTransition( "*", "Orbit" , "*" ) 
  self:AddTransition( "*", "Home" , "*" ) 
  
  self:AddTransition( "*", "Destroyed", "Destroyed" )

  --- Pickup Handler OnBefore for AI_CARGO_HELICOPTER
  -- @function [parent=#AI_CARGO_HELICOPTER] OnBeforePickup
  -- @param #AI_CARGO_HELICOPTER self
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param Core.Point#COORDINATE Coordinate
  -- @return #boolean
  
  --- Pickup Handler OnAfter for AI_CARGO_HELICOPTER
  -- @function [parent=#AI_CARGO_HELICOPTER] OnAfterPickup
  -- @param #AI_CARGO_HELICOPTER self
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param Core.Point#COORDINATE Coordinate
  -- @param #number Speed Speed in km/h to drive to the pickup coordinate. Default is 50% of max possible speed the unit can go.
  
  --- Pickup Trigger for AI_CARGO_HELICOPTER
  -- @function [parent=#AI_CARGO_HELICOPTER] Pickup
  -- @param #AI_CARGO_HELICOPTER self
  -- @param Core.Point#COORDINATE Coordinate
  -- @param #number Speed Speed in km/h to drive to the pickup coordinate. Default is 50% of max possible speed the unit can go.
  
  --- Pickup Asynchronous Trigger for AI_CARGO_HELICOPTER
  -- @function [parent=#AI_CARGO_HELICOPTER] __Pickup
  -- @param #AI_CARGO_HELICOPTER self
  -- @param #number Delay Delay in seconds.
  -- @param Core.Point#COORDINATE Coordinate
  -- @param #number Speed Speed in km/h to go to the pickup coordinate. Default is 50% of max possible speed the unit can go.
  
  --- Deploy Handler OnBefore for AI_CARGO_HELICOPTER
  -- @function [parent=#AI_CARGO_HELICOPTER] OnBeforeDeploy
  -- @param #AI_CARGO_HELICOPTER self
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param Core.Point#COORDINATE Coordinate Place at which cargo is deployed.
  -- @param #number Speed Speed in km/h to drive to the pickup coordinate. Default is 50% of max possible speed the unit can go.
  -- @return #boolean
  
  --- Deploy Handler OnAfter for AI_CARGO_HELICOPTER
  -- @function [parent=#AI_CARGO_HELICOPTER] OnAfterDeploy
  -- @param #AI_CARGO_HELICOPTER self
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param Core.Point#COORDINATE Coordinate
  -- @param #number Speed Speed in km/h to drive to the pickup coordinate. Default is 50% of max possible speed the unit can go.
  
  --- Deploy Trigger for AI_CARGO_HELICOPTER
  -- @function [parent=#AI_CARGO_HELICOPTER] Deploy
  -- @param #AI_CARGO_HELICOPTER self
  -- @param Core.Point#COORDINATE Coordinate Place at which the cargo is deployed.
  -- @param #number Speed Speed in km/h to drive to the pickup coordinate. Default is 50% of max possible speed the unit can go.
  
  --- Deploy Asynchronous Trigger for AI_CARGO_HELICOPTER
  -- @function [parent=#AI_CARGO_HELICOPTER] __Deploy
  -- @param #number Delay Delay in seconds.
  -- @param #AI_CARGO_HELICOPTER self
  -- @param Core.Point#COORDINATE Coordinate Place at which the cargo is deployed.
  -- @param #number Speed Speed in km/h to drive to the pickup coordinate. Default is 50% of max possible speed the unit can go.
  

  -- We need to capture the Crash events for the helicopters.
  -- The helicopter reference is used in the semaphore AI_CARGO_QUEUE.
  -- So, we need to unlock this when the helo is not anymore ...
  Helicopter:HandleEvent( EVENTS.Crash,
    function( Helicopter, EventData )
      AI_CARGO_QUEUE[Helicopter] = nil
    end
  )

  -- We need to capture the Land events for the helicopters.
  -- The helicopter reference is used in the semaphore AI_CARGO_QUEUE.
  -- So, we need to unlock this when the helo has landed, which can be anywhere ...
  -- But only free the landing coordinate after 1 minute, to ensure that all helos have left.
  Helicopter:HandleEvent( EVENTS.Land,
    function( Helicopter, EventData )
      self:ScheduleOnce( 60, 
        function( Helicopter )
          AI_CARGO_QUEUE[Helicopter] = nil
        end, Helicopter
      )
    end
  )

  for _, HelicopterUnit in pairs( Helicopter:GetUnits() ) do
    HelicopterUnit:SetCargoBayWeightLimit()
  end
  
  self.Relocating = false
  self.Transporting = false

  self:SetCarrier( Helicopter )
  
  return self
end

function AI_CARGO_HELICOPTER:IsTransporting()

  return self.Transporting == true
end

function AI_CARGO_HELICOPTER:IsRelocating()

  return self.Relocating == true
end


--- Set the Carrier.
-- @param #AI_CARGO_HELICOPTER self
-- @param Wrapper.Group#GROUP Helicopter
-- @return #AI_CARGO_HELICOPTER
function AI_CARGO_HELICOPTER:SetCarrier( Helicopter )

  local AICargo = self

  self.Helicopter = Helicopter -- Wrapper.Group#GROUP
  self.Helicopter:SetState( self.Helicopter, "AI_CARGO_HELICOPTER", self )

  self.RoutePickup = false
  self.RouteDeploy = false

  Helicopter:HandleEvent( EVENTS.Dead )
  Helicopter:HandleEvent( EVENTS.Hit )
  Helicopter:HandleEvent( EVENTS.Land )
  
  function Helicopter:OnEventDead( EventData )
    local AICargoTroops = self:GetState( self, "AI_CARGO_HELICOPTER" )
    self:F({AICargoTroops=AICargoTroops})
    if AICargoTroops then
      self:F({})
      if not AICargoTroops:Is( "Loaded" ) then
        -- There are enemies within combat range. Unload the Helicopter.
        AICargoTroops:Destroyed()
      end
    end
  end
  
  function Helicopter:OnEventLand( EventData )
    AICargo:Landed()
  end
  
  self.Coalition = self.Helicopter:GetCoalition()
  
  self:SetControllable( Helicopter )

  return self
end


--- @param #AI_CARGO_HELICOPTER self
-- @param Wrapper.Group#GROUP Helicopter
-- @param From
-- @param Event
-- @param To
function AI_CARGO_HELICOPTER:onafterLanded( Helicopter, From, Event, To )

  Helicopter:F( { Name = Helicopter:GetName() } )

  if Helicopter and Helicopter:IsAlive() then

    -- S_EVENT_LAND is directly called in two situations:
    -- 1 - When the helo lands normally on the ground.
    -- 2 - when the helo is hit and goes RTB or even when it is destroyed.
    -- For point 2, this is an issue, the infantry may not unload in this case!
    -- So we check if the helo is on the ground, and velocity< 5.
    -- Only then the infantry can unload (and load too, for consistency)!

    self:F( { Helicopter:GetName(), Height = Helicopter:GetHeight( true ), Velocity = Helicopter:GetVelocityKMH() } )

    if self.RoutePickup == true then
      if Helicopter:GetHeight( true ) <= 5 and Helicopter:GetVelocityKMH() < 10 then
        --self:Load( Helicopter:GetPointVec2() )
        self:Load( self.PickupZone )
        self.RoutePickup = false
        self.Relocating = true
      end
    end
    
    if self.RouteDeploy == true then
      if Helicopter:GetHeight( true ) <= 5 and Helicopter:GetVelocityKMH() < 10 then
        self:Unload( self.DeployZone )
        self.RouteDeploy = false
        self.Transporting = false
        self.Relocating = false
      end
    end
     
  end
  
end

--- @param #AI_CARGO_HELICOPTER self
-- @param Wrapper.Group#GROUP Helicopter
-- @param From
-- @param Event
-- @param To
-- @param Core.Point#COORDINATE Coordinate
-- @param #number Speed
function AI_CARGO_HELICOPTER:onafterQueue( Helicopter, From, Event, To, Coordinate, Speed, DeployZone )

  local HelicopterInZone = false

  if Helicopter and Helicopter:IsAlive() == true then
    
    local Distance = Coordinate:DistanceFromPointVec2( Helicopter:GetCoordinate() )
    
    if Distance > 2000 then
      self:__Queue( -10, Coordinate, Speed, DeployZone )
    else
    
      local ZoneFree = true

      for Helicopter, ZoneQueue in pairs( AI_CARGO_QUEUE ) do
        local ZoneQueue = ZoneQueue -- Core.Zone#ZONE_RADIUS
        if ZoneQueue:IsCoordinateInZone( Coordinate ) then
          ZoneFree = false
        end
      end
      
      self:F({ZoneFree=ZoneFree})
      
      if ZoneFree == true then
     
        local ZoneQueue = ZONE_RADIUS:New( Helicopter:GetName(), Coordinate:GetVec2(), 100 )
     
        AI_CARGO_QUEUE[Helicopter] = ZoneQueue 
      
        local Route = {}
        
--          local CoordinateFrom = Helicopter:GetCoordinate()
--          local WaypointFrom = CoordinateFrom:WaypointAir( 
--            "RADIO", 
--            POINT_VEC3.RoutePointType.TurningPoint, 
--            POINT_VEC3.RoutePointAction.TurningPoint, 
--            Speed, 
--            true 
--          )
--          Route[#Route+1] = WaypointFrom
        local CoordinateTo   = Coordinate
        local WaypointTo = CoordinateTo:WaypointAir( 
          "RADIO", 
          POINT_VEC3.RoutePointType.TurningPoint, 
          POINT_VEC3.RoutePointAction.TurningPoint, 
          50, 
          true 
        )
        Route[#Route+1] = WaypointTo
        
        local Tasks = {}
        Tasks[#Tasks+1] = Helicopter:TaskLandAtVec2( CoordinateTo:GetVec2() )
        Route[#Route].task = Helicopter:TaskCombo( Tasks )
    
        Route[#Route+1] = WaypointTo
    
        -- Now route the helicopter
        Helicopter:Route( Route, 0 )
        
        -- Keep the DeployZone, because when the helo has landed, we want to provide the DeployZone to the mission designer as part of the Unloaded event.
        self.DeployZone = DeployZone
        
      else
        self:__Queue( -10, Coordinate, Speed, DeployZone )
      end
    end
  else
    AI_CARGO_QUEUE[Helicopter] = nil
  end
end


--- @param #AI_CARGO_HELICOPTER self
-- @param Wrapper.Group#GROUP Helicopter
-- @param From
-- @param Event
-- @param To
-- @param Core.Point#COORDINATE Coordinate
-- @param #number Speed
function AI_CARGO_HELICOPTER:onafterOrbit( Helicopter, From, Event, To, Coordinate )

  if Helicopter and Helicopter:IsAlive() then
    
    if not self:IsTransporting() then
      local Route = {}
      
  --          local CoordinateFrom = Helicopter:GetCoordinate()
  --          local WaypointFrom = CoordinateFrom:WaypointAir( 
  --            "RADIO", 
  --            POINT_VEC3.RoutePointType.TurningPoint, 
  --            POINT_VEC3.RoutePointAction.TurningPoint, 
  --            Speed, 
  --            true 
  --          )
  --          Route[#Route+1] = WaypointFrom
      local CoordinateTo   = Coordinate
      local WaypointTo = CoordinateTo:WaypointAir( 
        "RADIO", 
        POINT_VEC3.RoutePointType.TurningPoint, 
        POINT_VEC3.RoutePointAction.TurningPoint, 
        50, 
        true 
      )
      Route[#Route+1] = WaypointTo
      
      local Tasks = {}
      Tasks[#Tasks+1] = Helicopter:TaskOrbitCircle( math.random( 30, 80 ), 150, CoordinateTo:GetRandomCoordinateInRadius( 800, 500 ) )
      Route[#Route].task = Helicopter:TaskCombo( Tasks )
  
      Route[#Route+1] = WaypointTo
  
      -- Now route the helicopter
      Helicopter:Route( Route, 0 )
    end
  end
end


--- On Before event Load.
-- @param #AI_CARGO_HELICOPTER self
-- @param Wrapper.Group#GROUP Helicopter
-- @param #string From From state.
-- @param #string Event Event
-- @param #string To To state.
-- @param Core.Zone#ZONE PickupZone (optional) The zone where the cargo will be picked up. The PickupZone can be nil, if there wasn't any PickupZoneSet provided.
function AI_CARGO_HELICOPTER:onbeforeLoad( Helicopter, From, Event, To, PickupZone )

  local Boarding = false
  
  local LoadInterval = 10
  local LoadDelay = 10

  if Helicopter and Helicopter:IsAlive() then
  
    self.BoardingCount = 0
  
    for _, HelicopterUnit in pairs( Helicopter:GetUnits() ) do
      local HelicopterUnit = HelicopterUnit -- Wrapper.Unit#UNIT
        local CargoBayFreeWeight = HelicopterUnit:GetCargoBayFreeWeight()
        self:F({CargoBayFreeWeight=CargoBayFreeWeight})
 
        for _, Cargo in pairs( self.CargoSet:GetSet() ) do
          local Cargo = Cargo -- Cargo.Cargo#CARGO
        self:F( { IsUnLoaded = Cargo:IsUnLoaded() } )
        if Cargo:IsUnLoaded() and not Cargo:IsDeployed() then
          if Cargo:IsInLoadRadius( HelicopterUnit:GetCoordinate() ) then
            self:F( { "In radius", HelicopterUnit:GetName() } )
            
            local CargoWeight = Cargo:GetWeight()
            
            -- Only when there is space within the bay to load the next cargo item!
            if CargoBayFreeWeight > CargoWeight then --and CargoBayFreeVolume > CargoVolume then
            
              --Cargo:Ungroup()
              Cargo:__Board( LoadDelay, HelicopterUnit, 25 )
              LoadDelay = LoadDelay + LoadInterval
              self:__Board( LoadDelay, Cargo, HelicopterUnit, PickupZone )
              self.Helicopter_Cargo[HelicopterUnit] = Cargo
              Boarding = true
              CargoBayFreeWeight = CargoBayFreeWeight - CargoWeight
            end
          end
        end
      end
    end
  end

  return Boarding
  
end

--- On after Board event.
-- @param #AI_CARGO_HELICOPTER self
-- @param Wrapper.Group#GROUP Helicopter
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Cargo.Cargo#CARGO Cargo Cargo object.
-- @param Wrapper.Unit#UNIT HelicopterUnit
-- @param Core.Zone#ZONE PickupZone (optional) The zone where the cargo will be picked up. The PickupZone can be nil, if there wasn't any PickupZoneSet provided.
function AI_CARGO_HELICOPTER:onafterBoard( Helicopter, From, Event, To, Cargo, HelicopterUnit, PickupZone )
  self:F( { Helicopter, From, Event, To, Cargo, HelicopterUnit } )

  if Helicopter and Helicopter:IsAlive() then
    self:F({ IsLoaded = Cargo:IsLoaded() } )
    if not Cargo:IsLoaded() then
      self:__Board( 10, Cargo, HelicopterUnit, PickupZone )
      return
    end
  end

  self:__Loaded( 10, Cargo, HelicopterUnit, PickupZone ) -- Will only be executed when no more cargo is boarded.
  
end


--- On After Loaded event.
-- @param #AI_CARGO_HELICOPTER self
-- @param Wrapper.Group#GROUP Helicopter
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @return #boolean Cargo loaded.
-- @param Core.Zone#ZONE PickupZone (optional) The zone where the cargo will be picked up. The PickupZone can be nil, if there wasn't any PickupZoneSet provided.
function AI_CARGO_HELICOPTER:onafterLoaded( Helicopter, From, Event, To, Cargo, HelicopterUnit, PickupZone )
  self:F( { Helicopter, From, Event, To } )

  local Loaded = true

  if Helicopter and Helicopter:IsAlive() then
    for HelicopterUnit, Cargo in pairs( self.Helicopter_Cargo ) do
      local Cargo = Cargo -- Cargo.Cargo#CARGO
      self:F( { IsLoaded = Cargo:IsLoaded(), IsDestroyed = Cargo:IsDestroyed(), Cargo:GetName(), Helicopter:GetName() } )
      if not Cargo:IsLoaded() and not Cargo:IsDestroyed() then
        Loaded = false
      end
    end
  end
  
  if Loaded then
    self:PickedUp( PickupZone )
  end
  
end




--- On after PickedUp event, raised when all cargo has been loaded into the CarrierGroup.
-- @param #AI_CARGO_HELICOPTER self
-- @param Wrapper.Group#GROUP Helicopter
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Cargo.Cargo#CARGO Cargo Cargo object.
-- @return #boolean Cargo is loaded.
-- @param Core.Zone#ZONE PickupZone (optional) The zone where the cargo will be picked up. The PickupZone can be nil, if there wasn't any PickupZoneSet provided.
function AI_CARGO_HELICOPTER:onafterPickedUp( Helicopter, From, Event, To, PickupZone )
  self:F( { Helicopter, From, Event, To } )
  
  if Helicopter and Helicopter:IsAlive() then
    self.Transporting = true
  end
end


--- On after Unload event.
-- @param #AI_CARGO_HELICOPTER self
-- @param Wrapper.Group#GROUP Helicopter
-- @param #string From From state.
-- @param #string Event Event.
-- @param #boolean Deployed Cargo is deployed.
function AI_CARGO_HELICOPTER:onafterUnload( Helicopter, From, Event, To, DeployZone )

  local UnboardInterval = 10
  local UnboardDelay = 10

  if Helicopter and Helicopter:IsAlive() then
    for _, HelicopterUnit in pairs( Helicopter:GetUnits() ) do
      local HelicopterUnit = HelicopterUnit -- Wrapper.Unit#UNIT
      for _, Cargo in pairs( HelicopterUnit:GetCargo() ) do
        if Cargo:IsLoaded() then
          Cargo:__UnBoard( UnboardDelay )
          UnboardDelay = UnboardDelay + UnboardInterval
          Cargo:SetDeployed( true )
          self:__Unboard( UnboardDelay, Cargo, HelicopterUnit, DeployZone )
        end
      end 
    end
  end

  
end

--- On after Unboard event.
-- @param #AI_CARGO_HELICOPTER self
-- @param Wrapper.Group#GROUP Helicopter
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Cargo.Cargo#CARGO Cargo Cargo object.
-- @param #boolean Deployed Cargo is deployed.
function AI_CARGO_HELICOPTER:onafterUnboard( Helicopter, From, Event, To, Cargo, HelicopterUnit, DeployZone )

  if Helicopter and Helicopter:IsAlive() then
    if not Cargo:IsUnLoaded() then
      self:__Unboard( 10, Cargo, HelicopterUnit, DeployZone )
      return 
    end
  end

  self:Unloaded( Cargo, HelicopterUnit, DeployZone )
  
end

--- On after Unloaded event.
-- @param #AI_CARGO_HELICOPTER self
-- @param Wrapper.Group#GROUP Helicopter
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Cargo.Cargo#CARGO Cargo Cargo object.
-- @param #boolean Deployed Cargo is deployed.
-- @return #boolean True if all cargo has been unloaded.
function AI_CARGO_HELICOPTER:onafterUnloaded( Helicopter, From, Event, To, Cargo, HelicopterUnit, DeployZone )
  self:F( { Helicopter, From, Event, To, Cargo:GetName(), HelicopterUnit:GetName(), DeployZone = DeployZone } )

  local AllUnloaded = true

  --Cargo:Regroup()

  if Helicopter and Helicopter:IsAlive() then
    for _, HelicopterUnit in pairs( Helicopter:GetUnits() ) do
      local IsEmpty = HelicopterUnit:IsCargoEmpty()
      self:I({ IsEmpty = IsEmpty })
      if not IsEmpty then
          AllUnloaded = false
          break
      end
    end
    
    if AllUnloaded == true then
      if DeployZone then
        self.Helicopter_Cargo = {}
      end
      self.Helicopter = Helicopter
    end
  end
  
  if AllUnloaded == true then
    self:Deployed( DeployZone )
  end
  
end


--- On after Deployed event.
-- @param #AI_CARGO_HELICOPTER self
-- @param Wrapper.Group#GROUP Helicopter
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Cargo.Cargo#CARGO Cargo Cargo object.
-- @param #boolean Deployed Cargo is deployed.
-- @return #boolean True if all cargo has been unloaded.
function AI_CARGO_HELICOPTER:onafterDeployed( Helicopter, From, Event, To, DeployZone )
  self:F( { Helicopter, From, Event, To, DeployZone = DeployZone } )

  self:Orbit( Helicopter:GetCoordinate(), 50 )

 -- Free the coordinate zone after 30 seconds, so that the original helicopter can fly away first.
  self:ScheduleOnce( 30, 
    function( Helicopter )
      AI_CARGO_QUEUE[Helicopter] = nil
    end, Helicopter
  )
  
end

--- On after Pickup event.
-- @param #AI_CARGO_HELICOPTER self
-- @param Wrapper.Group#GROUP Helicopter
-- @param From
-- @param Event
-- @param To
-- @param Core.Point#COORDINATE Coordinate Pickup place.
-- @param #number Speed Speed in km/h to drive to the pickup coordinate. Default is 50% of max possible speed the unit can go.
-- @param Core.Zone#ZONE PickupZone (optional) The zone where the cargo will be picked up. The PickupZone can be nil, if there wasn't any PickupZoneSet provided.
function AI_CARGO_HELICOPTER:onafterPickup( Helicopter, From, Event, To, Coordinate, Speed, PickupZone )

  if Helicopter and Helicopter:IsAlive() ~= nil then

    Helicopter:Activate()

    self.RoutePickup = true
    Coordinate.y = math.random( 50, 500 )
    
    local _speed=Speed or Helicopter:GetSpeedMax()*0.5        
     
    local Route = {}
    
    --- Calculate the target route point.
    local CoordinateFrom = Helicopter:GetCoordinate()
    local CoordinateTo   = Coordinate

    --- Create a route point of type air.
    local WaypointFrom = CoordinateFrom:WaypointAir( 
      "RADIO", 
      POINT_VEC3.RoutePointType.TurningPoint, 
      POINT_VEC3.RoutePointAction.TurningPoint, 
      _speed, 
      true 
    )

    --- Create a route point of type air.
    local WaypointTo = CoordinateTo:WaypointAir( 
      "RADIO", 
      POINT_VEC3.RoutePointType.TurningPoint, 
      POINT_VEC3.RoutePointAction.TurningPoint, 
      _speed, 
      true 
    )

    Route[#Route+1] = WaypointFrom
    Route[#Route+1] = WaypointTo
    
    --- Now we're going to do something special, we're going to call a function from a waypoint action at the AIControllable...
    Helicopter:WayPointInitialize( Route )
  
    local Tasks = {}
    
    Tasks[#Tasks+1] = Helicopter:TaskLandAtVec2( CoordinateTo:GetVec2() )
    Route[#Route].task = Helicopter:TaskCombo( Tasks )

    Route[#Route+1] = WaypointTo

    -- Now route the helicopter
    Helicopter:Route( Route, 1 )
    
    self.PickupZone = PickupZone
    self.Transporting = true
  end
  
end

--- Depoloy function and queue.
-- @param #AI_CARGO_HELICOPTER self
-- @param Wrapper.Group#GROUP AICargoHelicopter
-- @param Core.Point#COORDINATE Coordinate Coordinate
function AI_CARGO_HELICOPTER:_Deploy( AICargoHelicopter, Coordinate, DeployZone )
  AICargoHelicopter:__Queue( -10, Coordinate, 100, DeployZone )
end

--- On after Deploy event.
-- @param #AI_CARGO_HELICOPTER self
-- @param Wrapper.Group#GROUP Helicopter Transport helicopter.
-- @param From
-- @param Event
-- @param To
-- @param Core.Point#COORDINATE Coordinate Place at which the cargo is deployed.
-- @param #number Speed Speed in km/h to drive to the pickup coordinate. Default is 50% of max possible speed the unit can go.
function AI_CARGO_HELICOPTER:onafterDeploy( Helicopter, From, Event, To, Coordinate, Speed, DeployZone )

  if Helicopter and Helicopter:IsAlive() ~= nil then

    self.RouteDeploy = true

     
    local Route = {}
    
    --- Calculate the target route point.

    Coordinate.y = math.random( 50, 500 )
    
    local _speed=Speed or Helicopter:GetSpeedMax()*0.5      

    --- Create a route point of type air.
    local CoordinateFrom = Helicopter:GetCoordinate()
    local WaypointFrom = CoordinateFrom:WaypointAir( 
      "RADIO", 
      POINT_VEC3.RoutePointType.TurningPoint, 
      POINT_VEC3.RoutePointAction.TurningPoint, 
      _speed, 
      true 
    )
    Route[#Route+1] = WaypointFrom
    Route[#Route+1] = WaypointFrom

    --- Create a route point of type air.
    local CoordinateTo   = Coordinate
    local WaypointTo = CoordinateTo:WaypointAir( 
      "RADIO", 
      POINT_VEC3.RoutePointType.TurningPoint, 
      POINT_VEC3.RoutePointAction.TurningPoint, 
      _speed, 
      true 
    )

    Route[#Route+1] = WaypointTo
    Route[#Route+1] = WaypointTo
    
    --- Now we're going to do something special, we're going to call a function from a waypoint action at the AIControllable...
    Helicopter:WayPointInitialize( Route )
  
    local Tasks = {}
    
    Tasks[#Tasks+1] = Helicopter:TaskFunction( "AI_CARGO_HELICOPTER._Deploy", self, Coordinate, DeployZone )
    Tasks[#Tasks+1] = Helicopter:TaskOrbitCircle( math.random( 30, 100 ), _speed, CoordinateTo:GetRandomCoordinateInRadius( 800, 500 ) )
    
    --Tasks[#Tasks+1] = Helicopter:TaskLandAtVec2( CoordinateTo:GetVec2() )
    Route[#Route].task = Helicopter:TaskCombo( Tasks )

    Route[#Route+1] = WaypointTo

    -- Now route the helicopter
    Helicopter:Route( Route, 0 )
    
  end
  
end


--- On after Home event.
-- @param #AI_CARGO_HELICOPTER self
-- @param Wrapper.Group#GROUP Helicopter
-- @param From
-- @param Event
-- @param To
-- @param Core.Point#COORDINATE Coordinate Home place.
-- @param #number Speed Speed in km/h to drive to the pickup coordinate. Default is 50% of max possible speed the unit can go.
function AI_CARGO_HELICOPTER:onafterHome( Helicopter, From, Event, To, Coordinate, Speed )

  if Helicopter and Helicopter:IsAlive() ~= nil then

    self.RouteHome = true
     
    local Route = {}
    
    --- Calculate the target route point.

    Coordinate.y = math.random( 50, 200 )    
    
    local _speed=Speed or Helicopter:GetSpeedMax()*0.5          

    --- Create a route point of type air.
    local CoordinateFrom = Helicopter:GetCoordinate()
    local WaypointFrom = CoordinateFrom:WaypointAir( 
      "RADIO", 
      POINT_VEC3.RoutePointType.TurningPoint, 
      POINT_VEC3.RoutePointAction.TurningPoint, 
      _speed, 
      true 
    )
    Route[#Route+1] = WaypointFrom

    --- Create a route point of type air.
    local CoordinateTo   = Coordinate
    local WaypointTo = CoordinateTo:WaypointAir( 
      "RADIO", 
      POINT_VEC3.RoutePointType.TurningPoint, 
      POINT_VEC3.RoutePointAction.TurningPoint, 
      _speed, 
      true 
    )

    Route[#Route+1] = WaypointTo
    
    --- Now we're going to do something special, we're going to call a function from a waypoint action at the AIControllable...
    Helicopter:WayPointInitialize( Route )
  
    local Tasks = {}
    
    Tasks[#Tasks+1] = Helicopter:TaskLandAtVec2( CoordinateTo:GetVec2() )
    Route[#Route].task = Helicopter:TaskCombo( Tasks )

    Route[#Route+1] = WaypointTo

    -- Now route the helicopter
    Helicopter:Route( Route, 0 )
    
  end
  
end

