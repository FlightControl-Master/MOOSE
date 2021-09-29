--- **AI** - Models the intelligent transportation of cargo using helicopters.
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


--- Brings a dynamic cargo handling capability for an AI helicopter group.
--  
-- Helicopter carriers can be mobilized to intelligently transport infantry and other cargo within the simulation.
-- 
-- The AI_CARGO_HELICOPTER class uses the @{Cargo.Cargo} capabilities within the MOOSE framework.
-- @{Cargo.Cargo} must be declared within the mission to make the AI_CARGO_HELICOPTER object recognize the cargo.
-- Please consult the @{Cargo.Cargo} module for more information. 
-- 
-- ## Cargo pickup.
--  
-- Using the @{#AI_CARGO_HELICOPTER.Pickup}() method, you are able to direct the helicopters towards a point on the battlefield to board/load the cargo at the specific coordinate. 
-- Ensure that the landing zone is horizontally flat, and that trees cannot be found in the landing vicinity, or the helicopters won't land or will even crash!
-- 
-- ## Cargo deployment.
--  
-- Using the @{#AI_CARGO_HELICOPTER.Deploy}() method, you are able to direct the helicopters towards a point on the battlefield to unboard/unload the cargo at the specific coordinate. 
-- Ensure that the landing zone is horizontally flat, and that trees cannot be found in the landing vicinity, or the helicopters won't land or will even crash!
-- 
-- ## Infantry health.
-- 
-- When infantry is unboarded from the helicopters, the infantry is actually respawned into the battlefield. 
-- As a result, the unboarding infantry is very _healthy_ every time it unboards.
-- This is due to the limitation of the DCS simulator, which is not able to specify the health of new spawned units as a parameter.
-- However, infantry that was destroyed when unboarded, won't be respawned again. Destroyed is destroyed.
-- As a result, there is some additional strength that is gained when an unboarding action happens, but in terms of simulation balance this has
-- marginal impact on the overall battlefield simulation. Fortunately, the firing strength of infantry is limited, and thus, respacing healthy infantry every
-- time is not so much of an issue ... 
-- 
-- 
-- ===
-- 
-- @field #AI_CARGO_HELICOPTER
AI_CARGO_HELICOPTER = {
  ClassName = "AI_CARGO_HELICOPTER",
  Coordinate = nil, -- Core.Point#COORDINATE,
}

AI_CARGO_QUEUE = {}

--- Creates a new AI_CARGO_HELICOPTER object.
-- @param #AI_CARGO_HELICOPTER self
-- @param Wrapper.Group#GROUP Helicopter
-- @param Core.Set#SET_CARGO CargoSet
-- @return #AI_CARGO_HELICOPTER
function AI_CARGO_HELICOPTER:New( Helicopter, CargoSet )

  local self = BASE:Inherit( self, AI_CARGO:New( Helicopter, CargoSet ) ) -- #AI_CARGO_HELICOPTER

  self.Zone = ZONE_GROUP:New( Helicopter:GetName(), Helicopter, 300 )

  self:SetStartState( "Unloaded" ) 
  -- Boarding
  self:AddTransition( "Unloaded",     "Pickup",     "Unloaded" )
  self:AddTransition( "*",            "Landed",     "*" )
  self:AddTransition( "*",            "Load",       "*" )
  self:AddTransition( "*",            "Loaded",     "Loaded" )
  self:AddTransition( "Loaded",       "PickedUp",   "Loaded" )
  
  -- Unboarding
  self:AddTransition( "Loaded",       "Deploy",     "*" )
  self:AddTransition( "*",            "Queue",      "*" )
  self:AddTransition( "*",            "Orbit" ,     "*" )
  self:AddTransition( "*",            "Destroyed",  "*" )
  self:AddTransition( "*",            "Unload",     "*" )    
  self:AddTransition( "*",            "Unloaded",   "Unloaded" )
  self:AddTransition( "Unloaded",     "Deployed",   "Unloaded" )
  
  -- RTB
  self:AddTransition( "*", "Home" , "*" ) 

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
  -- @param #number Speed Speed in km/h to fly to the pickup coordinate. Default is 50% of max possible speed the unit can go.
  
    --- PickedUp Handler OnAfter for AI_CARGO_HELICOPTER - Cargo set has been picked up, ready to deploy
  -- @function [parent=#AI_CARGO_HELICOPTER] OnAfterPickedUp
  -- @param #AI_CARGO_HELICOPTER self
  -- @param Wrapper.Group#GROUP Helicopter The helicopter #GROUP object
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param Wrapper.Unit#UNIT Unit The helicopter #UNIT object

    --- Unloaded Handler OnAfter for AI_CARGO_HELICOPTER - Cargo unloaded, carrier is empty
  -- @function [parent=#AI_CARGO_HELICOPTER] OnAfterUnloaded
  -- @param #AI_CARGO_HELICOPTER self
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param Cargo.CargoGroup#CARGO_GROUP Cargo The #CARGO_GROUP object.
  -- @param Wrapper.Unit#UNIT Unit The helicopter #UNIT object
  
  --- Pickup Trigger for AI_CARGO_HELICOPTER
  -- @function [parent=#AI_CARGO_HELICOPTER] Pickup
  -- @param #AI_CARGO_HELICOPTER self
  -- @param Core.Point#COORDINATE Coordinate
  -- @param #number Speed Speed in km/h to fly to the pickup coordinate. Default is 50% of max possible speed the unit can go.
  
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
  -- @param #number Speed Speed in km/h to fly to the pickup coordinate. Default is 50% of max possible speed the unit can go.
  -- @return #boolean
  
  --- Deploy Handler OnAfter for AI_CARGO_HELICOPTER
  -- @function [parent=#AI_CARGO_HELICOPTER] OnAfterDeploy
  -- @param #AI_CARGO_HELICOPTER self
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param Core.Point#COORDINATE Coordinate
  -- @param #number Speed Speed in km/h to fly to the pickup coordinate. Default is 50% of max possible speed the unit can go.
  
    --- Deployed Handler OnAfter for AI_CARGO_HELICOPTER
  -- @function [parent=#AI_CARGO_HELICOPTER] OnAfterDeployed
  -- @param #AI_CARGO_HELICOPTER self
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  
  --- Deploy Trigger for AI_CARGO_HELICOPTER
  -- @function [parent=#AI_CARGO_HELICOPTER] Deploy
  -- @param #AI_CARGO_HELICOPTER self
  -- @param Core.Point#COORDINATE Coordinate Place at which the cargo is deployed.
  -- @param #number Speed Speed in km/h to fly to the pickup coordinate. Default is 50% of max possible speed the unit can go.
  
  --- Deploy Asynchronous Trigger for AI_CARGO_HELICOPTER
  -- @function [parent=#AI_CARGO_HELICOPTER] __Deploy
  -- @param #number Delay Delay in seconds.
  -- @param #AI_CARGO_HELICOPTER self
  -- @param Core.Point#COORDINATE Coordinate Place at which the cargo is deployed.
  -- @param #number Speed Speed in km/h to fly to the pickup coordinate. Default is 50% of max possible speed the unit can go.
  
  --- Home Trigger for AI_CARGO_HELICOPTER
  -- @function [parent=#AI_CARGO_HELICOPTER] Home
  -- @param #AI_CARGO_HELICOPTER self
  -- @param Core.Point#COORDINATE Coordinate Place to which the helicopter will go.
  -- @param #number Speed (optional) Speed in km/h to fly to the pickup coordinate. Default is 50% of max possible speed the unit can go.
  -- @param #number Height (optional) Height the Helicopter should be flying at.
  
  --- Home Asynchronous Trigger for AI_CARGO_HELICOPTER
  -- @function [parent=#AI_CARGO_HELICOPTER] __Home
  -- @param #number Delay Delay in seconds.
  -- @param #AI_CARGO_HELICOPTER self
  -- @param Core.Point#COORDINATE Coordinate Place to which the helicopter will go.
  -- @param #number Speed (optional) Speed in km/h to fly to the pickup coordinate. Default is 50% of max possible speed the unit can go.
  -- @param #number Height (optional) Height the Helicopter should be flying at. 

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

  self:SetCarrier( Helicopter )
  
  self.landingspeed = 15 -- kph
  self.landingheight = 5.5 -- meter
  
  return self
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

--- Set landingspeed and -height for helicopter landings. Adjust after tracing if your helis get stuck after landing.
-- @param #AI_CARGO_HELICOPTER self
-- @param #number speed Landing speed in kph(!), e.g. 15
-- @param #number height Landing height in meters(!), e.g. 5.5
-- @return #AI_CARGO_HELICOPTER self
-- @usage If your choppers get stuck, add tracing to your script to determine if they hit the right parameters like so:
--    
--        BASE:TraceOn()
--        BASE:TraceClass("AI_CARGO_HELICOPTER")
--        
-- Watch the DCS.log for entries stating `Helicopter:<name>, Height = Helicopter:<number>, Velocity = Helicopter:<number>`
-- Adjust if necessary.
function AI_CARGO_HELICOPTER:SetLandingSpeedAndHeight(speed, height)
  local _speed = speed or 15
  local _height = height or 5.5
  self.landingheight = _height
  self.landingspeed = _speed
  return self
end

--- @param #AI_CARGO_HELICOPTER self
-- @param Wrapper.Group#GROUP Helicopter
-- @param From
-- @param Event
-- @param To
function AI_CARGO_HELICOPTER:onafterLanded( Helicopter, From, Event, To )
  self:F({From, Event, To})
  Helicopter:F( { Name = Helicopter:GetName() } )

  if Helicopter and Helicopter:IsAlive() then

    -- S_EVENT_LAND is directly called in two situations:
    -- 1 - When the helo lands normally on the ground.
    -- 2 - when the helo is hit and goes RTB or even when it is destroyed.
    -- For point 2, this is an issue, the infantry may not unload in this case!
    -- So we check if the helo is on the ground, and velocity< 15.
    -- Only then the infantry can unload (and load too, for consistency)!

    self:T( { Helicopter:GetName(), Height = Helicopter:GetHeight( true ), Velocity = Helicopter:GetVelocityKMH() } )

    if self.RoutePickup == true then
      if Helicopter:GetHeight( true ) <= self.landingheight then --and Helicopter:GetVelocityKMH() < self.landingspeed then
        --self:Load( Helicopter:GetPointVec2() )
        self:Load( self.PickupZone )
        self.RoutePickup = false
      end
    end
    
    if self.RouteDeploy == true then
      if Helicopter:GetHeight( true ) <= self.landingheight then --and Helicopter:GetVelocityKMH() < self.landingspeed then
        self:Unload( self.DeployZone )
        self.RouteDeploy = false
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
  self:F({From, Event, To, Coordinate, Speed, DeployZone})
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
        local CoordinateTo = Coordinate
        
        local landheight = CoordinateTo:GetLandHeight() -- get target height
        CoordinateTo.y = landheight + 50 -- flight height should be 50m above ground
    
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
  self:F({From, Event, To, Coordinate})
  
  if Helicopter and Helicopter:IsAlive() then
    
    local Route = {}
    
    local CoordinateTo = Coordinate
    local landheight = CoordinateTo:GetLandHeight() -- get target height
    CoordinateTo.y = landheight + 50 -- flight height should be 50m above ground
    
    local WaypointTo = CoordinateTo:WaypointAir("RADIO", POINT_VEC3.RoutePointType.TurningPoint, POINT_VEC3.RoutePointAction.TurningPoint, 50, true)
    Route[#Route+1] = WaypointTo
    
    local Tasks = {}
    Tasks[#Tasks+1] = Helicopter:TaskOrbitCircle( math.random( 30, 80 ), 150, CoordinateTo:GetRandomCoordinateInRadius( 800, 500 ) )
    Route[#Route].task = Helicopter:TaskCombo( Tasks )

    Route[#Route+1] = WaypointTo

    -- Now route the helicopter
    Helicopter:Route(Route, 0)
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
  self:F( { From, Event, To, DeployZone = DeployZone } )

  self:Orbit( Helicopter:GetCoordinate(), 50 )

 -- Free the coordinate zone after 30 seconds, so that the original helicopter can fly away first.
  self:ScheduleOnce( 30, 
    function( Helicopter )
      AI_CARGO_QUEUE[Helicopter] = nil
    end, Helicopter
  )
  
  self:GetParent( self, AI_CARGO_HELICOPTER ).onafterDeployed( self, Helicopter, From, Event, To, DeployZone )
  
end

--- On after Pickup event.
-- @param #AI_CARGO_HELICOPTER self
-- @param Wrapper.Group#GROUP Helicopter
-- @param From
-- @param Event
-- @param To
-- @param Core.Point#COORDINATE Coordinate Pickup place.
-- @param #number Speed Speed in km/h to fly to the pickup coordinate. Default is 50% of max possible speed the unit can go.
-- @param #number Height Height in meters to move to the pickup coordinate. This parameter is ignored for APCs.
-- @param Core.Zone#ZONE PickupZone (optional) The zone where the cargo will be picked up. The PickupZone can be nil, if there wasn't any PickupZoneSet provided.
function AI_CARGO_HELICOPTER:onafterPickup( Helicopter, From, Event, To, Coordinate, Speed, Height, PickupZone )
  self:F({Coordinate, Speed, Height, PickupZone })
  
  if Helicopter and Helicopter:IsAlive() ~= nil then

    Helicopter:Activate()

    self.RoutePickup = true
    Coordinate.y = Height
    
    local _speed=Speed or Helicopter:GetSpeedMax()*0.5        
     
    local Route = {}
    
    --- Calculate the target route point.
    local CoordinateFrom = Helicopter:GetCoordinate()

    --- Create a route point of type air.
    local WaypointFrom = CoordinateFrom:WaypointAir("RADIO", POINT_VEC3.RoutePointType.TurningPoint, POINT_VEC3.RoutePointAction.TurningPoint, _speed, true)

    --- Create a route point of type air.
    local CoordinateTo = Coordinate
    local landheight = CoordinateTo:GetLandHeight() -- get target height
    CoordinateTo.y = landheight + 50 -- flight height should be 50m above ground
    
    local WaypointTo = CoordinateTo:WaypointAir("RADIO", POINT_VEC3.RoutePointType.TurningPoint, POINT_VEC3.RoutePointAction.TurningPoint,_speed, true)

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

    self:GetParent( self, AI_CARGO_HELICOPTER ).onafterPickup( self, Helicopter, From, Event, To, Coordinate, Speed, Height, PickupZone )

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
-- @param #number Speed Speed in km/h to fly to the pickup coordinate. Default is 50% of max possible speed the unit can go.
-- @param #number Height Height in meters to move to the deploy coordinate.
function AI_CARGO_HELICOPTER:onafterDeploy( Helicopter, From, Event, To, Coordinate, Speed, Height, DeployZone )
  self:F({From, Event, To, Coordinate, Speed, Height, DeployZone})
  if Helicopter and Helicopter:IsAlive() ~= nil then

    self.RouteDeploy = true

     
    local Route = {}
    
    --- Calculate the target route point.

    Coordinate.y = Height
    
    local _speed=Speed or Helicopter:GetSpeedMax()*0.5      

    --- Create a route point of type air.
    local CoordinateFrom = Helicopter:GetCoordinate()
    local WaypointFrom = CoordinateFrom:WaypointAir("RADIO", POINT_VEC3.RoutePointType.TurningPoint, POINT_VEC3.RoutePointAction.TurningPoint, _speed, true)
    Route[#Route+1] = WaypointFrom
    Route[#Route+1] = WaypointFrom

    --- Create a route point of type air.
    
    local CoordinateTo = Coordinate
    local landheight = CoordinateTo:GetLandHeight() -- get target height
    CoordinateTo.y = landheight + 50 -- flight height should be 50m above ground
    
    local WaypointTo = CoordinateTo:WaypointAir("RADIO", POINT_VEC3.RoutePointType.TurningPoint, POINT_VEC3.RoutePointAction.TurningPoint, _speed, true)

    Route[#Route+1] = WaypointTo
    Route[#Route+1] = WaypointTo
    
    --- Now we're going to do something special, we're going to call a function from a waypoint action at the AIControllable...
    Helicopter:WayPointInitialize( Route )
  
    local Tasks = {}
    
    -- The _Deploy function does not exist.
    Tasks[#Tasks+1] = Helicopter:TaskFunction( "AI_CARGO_HELICOPTER._Deploy", self, Coordinate, DeployZone )
    
    Tasks[#Tasks+1] = Helicopter:TaskOrbitCircle( math.random( 30, 100 ), _speed, CoordinateTo:GetRandomCoordinateInRadius( 800, 500 ) )
    
    --Tasks[#Tasks+1] = Helicopter:TaskLandAtVec2( CoordinateTo:GetVec2() )
    Route[#Route].task = Helicopter:TaskCombo( Tasks )

    Route[#Route+1] = WaypointTo

    -- Now route the helicopter
    Helicopter:Route( Route, 0 )

    self:GetParent( self, AI_CARGO_HELICOPTER ).onafterDeploy( self, Helicopter, From, Event, To, Coordinate, Speed, Height, DeployZone )
  end
  
end


--- On after Home event.
-- @param #AI_CARGO_HELICOPTER self
-- @param Wrapper.Group#GROUP Helicopter
-- @param From
-- @param Event
-- @param To
-- @param Core.Point#COORDINATE Coordinate Home place.
-- @param #number Speed Speed in km/h to fly to the pickup coordinate. Default is 50% of max possible speed the unit can go.
-- @param #number Height Height in meters to move to the home coordinate.
-- @param Core.Zone#ZONE HomeZone The zone wherein the carrier will return when all cargo has been transported. This can be any zone type, like a ZONE, ZONE_GROUP, ZONE_AIRBASE.
function AI_CARGO_HELICOPTER:onafterHome( Helicopter, From, Event, To, Coordinate, Speed, Height, HomeZone )
  self:F({From, Event, To, Coordinate, Speed, Height})
  
  if Helicopter and Helicopter:IsAlive() ~= nil then

    self.RouteHome = true
     
    local Route = {}
    
    --- Calculate the target route point.

    --Coordinate.y = Height
    Height = Height or 50
    
    Speed = Speed or Helicopter:GetSpeedMax()*0.5          

    --- Create a route point of type air.
    local CoordinateFrom = Helicopter:GetCoordinate()
    
    local WaypointFrom = CoordinateFrom:WaypointAir("RADIO", POINT_VEC3.RoutePointType.TurningPoint, POINT_VEC3.RoutePointAction.TurningPoint, Speed, true)
    Route[#Route+1] = WaypointFrom

    --- Create a route point of type air.
    local CoordinateTo = Coordinate
    local landheight = CoordinateTo:GetLandHeight() -- get target height
    CoordinateTo.y = landheight + Height -- flight height should be 50m above ground
    
    local WaypointTo = CoordinateTo:WaypointAir("RADIO", POINT_VEC3.RoutePointType.TurningPoint, POINT_VEC3.RoutePointAction.TurningPoint, Speed, true)

    Route[#Route+1] = WaypointTo
    
    --- Now we're going to do something special, we're going to call a function from a waypoint action at the AIControllable...
    Helicopter:WayPointInitialize( Route )
  
    local Tasks = {}
    
    Tasks[#Tasks+1] = Helicopter:TaskLandAtVec2( CoordinateTo:GetVec2() )
    Route[#Route].task = Helicopter:TaskCombo( Tasks )
 
    Route[#Route+1] = WaypointTo

    -- Now route the helicopter
    Helicopter:Route(Route, 0)
  end
  
end

