--- **AI** -- (R2.3) - Models the intelligent transportation of infantry (cargo).
--
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ===       
--
-- @module AI_Cargo_Helicopter

--- @type AI_CARGO_HELICOPTER
-- @extends Core.Fsm#FSM_CONTROLLABLE


--- # AI\_CARGO\_TROOPS class, extends @{Core.Base@BASE}
-- 
-- ===
-- 
-- @field #AI_CARGO_HELICOPTER
AI_CARGO_HELICOPTER = {
  ClassName = "AI_CARGO_HELICOPTER",
  Coordinate = nil -- Core.Point#COORDINATE,
}

AI_CARGO_QUEUE = {}

--- Creates a new AI_CARGO_HELICOPTER object.
-- @param #AI_CARGO_HELICOPTER self
-- @param Wrapper.Group#GROUP Helicopter
-- @param Core.Set#SET_CARGO CargoSet
-- @param #number CombatRadius
-- @return #AI_CARGO_HELICOPTER
function AI_CARGO_HELICOPTER:New( Helicopter, CargoSet )

  local self = BASE:Inherit( self, FSM_CONTROLLABLE:New() ) -- #AI_CARGO_HELICOPTER

  self.CargoSet = CargoSet -- Cargo.CargoGroup#CARGO_GROUP
  
  self.Zone = ZONE_GROUP:New( Helicopter:GetName(), Helicopter, 300 )

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
  
  --- Pickup Trigger for AI_CARGO_HELICOPTER
  -- @function [parent=#AI_CARGO_HELICOPTER] Pickup
  -- @param #AI_CARGO_HELICOPTER self
  -- @param Core.Point#COORDINATE Coordinate
  
  --- Pickup Asynchronous Trigger for AI_CARGO_HELICOPTER
  -- @function [parent=#AI_CARGO_HELICOPTER] __Pickup
  -- @param #AI_CARGO_HELICOPTER self
  -- @param #number Delay
  -- @param Core.Point#COORDINATE Coordinate
  
  --- Deploy Handler OnBefore for AI_CARGO_HELICOPTER
  -- @function [parent=#AI_CARGO_HELICOPTER] OnBeforeDeploy
  -- @param #AI_CARGO_HELICOPTER self
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param Core.Point#COORDINATE Coordinate
  -- @return #boolean
  
  --- Deploy Handler OnAfter for AI_CARGO_HELICOPTER
  -- @function [parent=#AI_CARGO_HELICOPTER] OnAfterDeploy
  -- @param #AI_CARGO_HELICOPTER self
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param Core.Point#COORDINATE Coordinate
  
  --- Deploy Trigger for AI_CARGO_HELICOPTER
  -- @function [parent=#AI_CARGO_HELICOPTER] Deploy
  -- @param #AI_CARGO_HELICOPTER self
  -- @param Core.Point#COORDINATE Coordinate
  
  --- Deploy Asynchronous Trigger for AI_CARGO_HELICOPTER
  -- @function [parent=#AI_CARGO_HELICOPTER] __Deploy
  -- @param #AI_CARGO_HELICOPTER self
  -- @param Core.Point#COORDINATE Coordinate
  -- @param #number Delay



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
  
  
  function Helicopter:OnEventHit( EventData )
    local AICargoTroops = self:GetState( self, "AI_CARGO_HELICOPTER" )
    if AICargoTroops then
      self:F( { OnHitLoaded = AICargoTroops:Is( "Loaded" ) } )
      if AICargoTroops:Is( "Loaded" ) or AICargoTroops:Is( "Boarding" ) then
        -- There are enemies within combat range. Unload the Helicopter.
        AICargoTroops:Unload()
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
-- @param Core.Point#COORDINATE Coordinate
-- @param #number Speed
function AI_CARGO_HELICOPTER:onafterLanded( Helicopter, From, Event, To )

  if Helicopter and Helicopter:IsAlive() then

    if self.RoutePickup == true then
      self:Load( Helicopter:GetPointVec2() )
      self.RoutePickup = false
      self.Relocating = true
    end
    
    if self.RouteDeploy == true then
      self:Unload( true )
      self.RouteDeploy = false
      self.Transporting = false
      self.Relocating = false
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
function AI_CARGO_HELICOPTER:onafterQueue( Helicopter, From, Event, To, Coordinate )

  local HelicopterInZone = false

  if Helicopter and Helicopter:IsAlive() then
    
    local Distance = Coordinate:DistanceFromPointVec2( Helicopter:GetCoordinate() )
    
    if Distance > 500 then
      self:__Queue( -10, Coordinate )
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
      else
        self:__Queue( -10, Coordinate )
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
      Tasks[#Tasks+1] = Helicopter:TaskOrbitCircle( math.random( 30, 80 ), 0, CoordinateTo:GetRandomCoordinateInRadius( 800, 500 ) )
      Route[#Route].task = Helicopter:TaskCombo( Tasks )
  
      Route[#Route+1] = WaypointTo
  
      -- Now route the helicopter
      Helicopter:Route( Route, 0 )
    end
  end
end



--- @param #AI_CARGO_HELICOPTER self
-- @param Wrapper.Group#GROUP Helicopter
function AI_CARGO_HELICOPTER:onbeforeLoad( Helicopter, From, Event, To, Coordinate )

  local Boarding = false

  if Helicopter and Helicopter:IsAlive() then
  
    self.BoardingCount = 0
  
    if Helicopter and Helicopter:IsAlive() then
      self.Helicopter_Cargo = {}
      for _, HelicopterUnit in pairs( Helicopter:GetUnits() ) do
        local HelicopterUnit = HelicopterUnit -- Wrapper.Unit#UNIT
        for _, Cargo in pairs( self.CargoSet:GetSet() ) do
          local Cargo = Cargo -- Cargo.Cargo#CARGO
          self:F( { IsUnLoaded = Cargo:IsUnLoaded() } )
          if Cargo:IsUnLoaded() then
            if Cargo:IsInLoadRadius( HelicopterUnit:GetCoordinate() ) then
              self:F( { "In radius", HelicopterUnit:GetName() } )
              --Cargo:Ungroup()
              Cargo:Board( HelicopterUnit, 25 )
              self:__Board( 1, Cargo )
              Boarding = true
              
              -- So now this APCUnit has Cargo that is being loaded.
              -- This will be used further in the logic to follow and to check cargo status.
              self.Helicopter_Cargo[HelicopterUnit] = Cargo
              break
            end
          end
        end
      end
    end
  end

  return Boarding
  
end

--- @param #AI_CARGO_HELICOPTER self
-- @param Wrapper.Group#GROUP Helicopter
function AI_CARGO_HELICOPTER:onafterBoard( Helicopter, From, Event, To, Cargo )
  self:F( { APC, From, Event, To, Cargo } )

  if Helicopter and Helicopter:IsAlive() then
    self:F({ IsLoaded = Cargo:IsLoaded() } )
    if not Cargo:IsLoaded() then
      self:__Board( 10, Cargo )
    else
      self:__Loaded( 1, Cargo )
    end
  end
  
end

--- @param #AI_CARGO_HELICOPTER self
-- @param Wrapper.Group#GROUP Helicopter
function AI_CARGO_HELICOPTER:onbeforeLoaded( Helicopter, From, Event, To, Cargo )
  self:F( { APC, From, Event, To } )
  
  local Loaded = true

  if Helicopter and Helicopter:IsAlive() then
    for HelicopterUnit, Cargo in pairs( self.Helicopter_Cargo ) do
      local Cargo = Cargo -- Cargo.Cargo#CARGO
      self:F( { IsLoaded = Cargo:IsLoaded(), IsDestroyed = Cargo:IsDestroyed() } )
      if not Cargo:IsLoaded() and not Cargo:IsDestroyed() then
        Loaded = false
      end
    end
    
  end
  
  return Loaded

end


--- @param #AI_CARGO_HELICOPTER self
-- @param Wrapper.Group#GROUP Helicopter
function AI_CARGO_HELICOPTER:onafterUnload( Helicopter, From, Event, To, Deployed )

  if Helicopter and Helicopter:IsAlive() then
    for _, HelicopterUnit in pairs( Helicopter:GetUnits() ) do
      local HelicopterUnit = HelicopterUnit -- Wrapper.Unit#UNIT
      for _, Cargo in pairs( HelicopterUnit:GetCargo() ) do
        Cargo:UnBoard()
        Cargo:SetDeployed( true )
        self:__Unboard( 10, Cargo, Deployed )
      end 
    end
  end

  
end

--- @param #AI_CARGO_HELICOPTER self
-- @param Wrapper.Group#GROUP Helicopter
function AI_CARGO_HELICOPTER:onafterUnboard( Helicopter, From, Event, To, Cargo, Deployed )

  if Helicopter and Helicopter:IsAlive() then
    if not Cargo:IsUnLoaded() then
      self:__Unboard( 10, Cargo, Deployed ) 
    else
      self:__Unloaded( 1, Cargo, Deployed )
    end
  end
  
end

--- @param #AI_CARGO_HELICOPTER self
-- @param Wrapper.Group#GROUP Helicopter
function AI_CARGO_HELICOPTER:onbeforeUnloaded( Helicopter, From, Event, To, Cargo, Deployed )
  self:F( { APC, From, Event, To, Cargo:GetName(), Deployed = Deployed } )

  local AllUnloaded = true

  --Cargo:Regroup()

  if Helicopter and Helicopter:IsAlive() then
    for _, HelicopterUnit in pairs( Helicopter:GetUnits() ) do
      local CargoCheck = self.Helicopter_Cargo[HelicopterUnit] -- Cargo.Cargo#CARGO
      if CargoCheck then
        self:F( { CargoCheck:GetName(), IsUnLoaded = CargoCheck:IsUnLoaded() } )
        if CargoCheck:IsUnLoaded() == false then
          AllUnloaded = false
          break
        end
      end
    end
    
    if AllUnloaded == true then
      if Deployed == true then
        for HelicopterUnit, Cargo in pairs( self.Helicopter_Cargo ) do
          local Cargo = Cargo -- Cargo.Cargo#CARGO
        end
        self.Helicopter_Cargo = {}
      end
      self.Helicopter = Helicopter
    end
  end
  
  self:F( { AllUnloaded = AllUnloaded } )
  return AllUnloaded
  
end

--- @param #AI_CARGO_HELICOPTER self
-- @param Wrapper.Group#GROUP Helicopter
function AI_CARGO_HELICOPTER:onafterUnloaded( Helicopter, From, Event, To, Cargo, Deployed )

  self:Orbit( Helicopter:GetCoordinate(), 50 )

  AI_CARGO_QUEUE[Helicopter] = nil

end

--- @param #AI_CARGO_HELICOPTER self
-- @param Wrapper.Group#GROUP Helicopter
-- @param From
-- @param Event
-- @param To
-- @param Core.Point#COORDINATE Coordinate
-- @param #number Speed
function AI_CARGO_HELICOPTER:onafterPickup( Helicopter, From, Event, To, Coordinate )

  if Helicopter and Helicopter:IsAlive() ~= nil then

    Helicopter:Activate()

    self.RoutePickup = true
    Coordinate.y = math.random( 50, 200 )        
     
    local Route = {}
    
    --- Calculate the target route point.
    local CoordinateFrom = Helicopter:GetCoordinate()
    local CoordinateTo   = Coordinate

    --- Create a route point of type air.
    local WaypointFrom = CoordinateFrom:WaypointAir( 
      "RADIO", 
      POINT_VEC3.RoutePointType.TurningPoint, 
      POINT_VEC3.RoutePointAction.TurningPoint, 
      150, 
      true 
    )

    --- Create a route point of type air.
    local WaypointTo = CoordinateTo:WaypointAir( 
      "RADIO", 
      POINT_VEC3.RoutePointType.TurningPoint, 
      POINT_VEC3.RoutePointAction.TurningPoint, 
      150, 
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

    self.Transporting = true
  end
  
end


function AI_CARGO_HELICOPTER:_Deploy( AICargoHelicopter, Coordinate )
  AICargoHelicopter:__Queue( -10, Coordinate, 100 )
end

--- @param #AI_CARGO_HELICOPTER self
-- @param Wrapper.Group#GROUP Helicopter
-- @param From
-- @param Event
-- @param To
-- @param Core.Point#COORDINATE Coordinate
-- @param #number Speed
function AI_CARGO_HELICOPTER:onafterDeploy( Helicopter, From, Event, To, Coordinate )

  if Helicopter and Helicopter:IsAlive() ~= nil then

    self.RouteDeploy = true

     
    local Route = {}
    
    --- Calculate the target route point.

    Coordinate.y = math.random( 50, 200 )        

    --- Create a route point of type air.
    local CoordinateFrom = Helicopter:GetCoordinate()
    local WaypointFrom = CoordinateFrom:WaypointAir( 
      "RADIO", 
      POINT_VEC3.RoutePointType.TurningPoint, 
      POINT_VEC3.RoutePointAction.TurningPoint, 
      150, 
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
      150, 
      true 
    )

    Route[#Route+1] = WaypointTo
    Route[#Route+1] = WaypointTo
    
    --- Now we're going to do something special, we're going to call a function from a waypoint action at the AIControllable...
    Helicopter:WayPointInitialize( Route )
  
    local Tasks = {}
    
    Tasks[#Tasks+1] = Helicopter:TaskFunction( "AI_CARGO_HELICOPTER._Deploy", self, Coordinate )
    Tasks[#Tasks+1] = Helicopter:TaskOrbitCircle( math.random( 30, 100 ), 0, CoordinateTo:GetRandomCoordinateInRadius( 800, 500 ) )
    
    --Tasks[#Tasks+1] = Helicopter:TaskLandAtVec2( CoordinateTo:GetVec2() )
    Route[#Route].task = Helicopter:TaskCombo( Tasks )

    Route[#Route+1] = WaypointTo

    -- Now route the helicopter
    Helicopter:Route( Route, 1 )
    
  end
  
end


--- @param #AI_CARGO_HELICOPTER self
-- @param Wrapper.Group#GROUP Helicopter
-- @param From
-- @param Event
-- @param To
-- @param Core.Point#COORDINATE Coordinate
-- @param #number Speed
function AI_CARGO_HELICOPTER:onafterHome( Helicopter, From, Event, To, Coordinate )

  if Helicopter and Helicopter:IsAlive() ~= nil then

    self.RouteHome = true
     
    local Route = {}
    
    --- Calculate the target route point.

    Coordinate.y = math.random( 50, 200 )        

    --- Create a route point of type air.
    local CoordinateFrom = Helicopter:GetCoordinate()
    local WaypointFrom = CoordinateFrom:WaypointAir( 
      "RADIO", 
      POINT_VEC3.RoutePointType.TurningPoint, 
      POINT_VEC3.RoutePointAction.TurningPoint, 
      150, 
      true 
    )
    Route[#Route+1] = WaypointFrom

    --- Create a route point of type air.
    local CoordinateTo   = Coordinate
    local WaypointTo = CoordinateTo:WaypointAir( 
      "RADIO", 
      POINT_VEC3.RoutePointType.TurningPoint, 
      POINT_VEC3.RoutePointAction.TurningPoint, 
      150, 
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

