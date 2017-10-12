--- **Core** -- Management of CARGO logistics, that can be transported from and to transportation carriers.
--
-- ![Banner Image](..\Presentations\CARGO\Dia1.JPG)
--
-- ===
-- 
-- Cargo can be of various forms, always are composed out of ONE object ( one unit or one static or one slingload crate ):
--
--   * CARGO_UNIT, represented by a @{Unit} in a singleton @{Group}: Cargo can be represented by a Unit in a Group. a CARGO_UNIT is representable...
--   * CARGO_GROUP, represented by a @{Group}. A CARGO_GROUP is reportable...
--   
-- This module is still under construction, but is described above works already, and will keep working ...
-- 
-- ====
-- 
-- # Demo Missions
-- 
-- ### [CARGO Demo Missions source code](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master-release/CGO%20-%20Cargo)
-- 
-- ### [CARGO Demo Missions, only for beta testers](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master/CGO%20-%20Cargo)
--
-- ### [ALL Demo Missions pack of the last release](https://github.com/FlightControl-Master/MOOSE_MISSIONS/releases)
-- 
-- ====
-- 
-- # YouTube Channel
-- 
-- ### [CARGO YouTube Channel](https://www.youtube.com/watch?v=tM00lTlkpYs&list=PL7ZUrU4zZUl2zUTuKrLW5RsO9zLMqUtbf)
-- 
-- ====
-- 
-- ### Author: **Sven Van de Velde (FlightControl)**
-- ### Contributions: 
-- 
-- ====
-- 
-- @module Cargo

-- Events

-- Board

--- Boards the cargo to a Carrier. The event will create a movement (= running or driving) of the cargo to the Carrier.
-- The cargo must be in the **UnLoaded** state.
-- @function [parent=#CARGO] Board
-- @param #CARGO self
-- @param Wrapper.Controllable#CONTROLLABLE ToCarrier The Carrier that will hold the cargo.
-- @param #number NearRadius The radius when the cargo will board the Carrier (to avoid collision).

--- Boards the cargo to a Carrier. The event will create a movement (= running or driving) of the cargo to the Carrier.
-- The cargo must be in the **UnLoaded** state.
-- @function [parent=#CARGO] __Board
-- @param #CARGO self
-- @param #number DelaySeconds The amount of seconds to delay the action.
-- @param Wrapper.Controllable#CONTROLLABLE ToCarrier The Carrier that will hold the cargo.
-- @param #number NearRadius The radius when the cargo will board the Carrier (to avoid collision).


-- UnBoard

--- UnBoards the cargo to a Carrier. The event will create a movement (= running or driving) of the cargo from the Carrier.
-- The cargo must be in the **Loaded** state.
-- @function [parent=#CARGO] UnBoard
-- @param #CARGO self
-- @param Core.Point#POINT_VEC2 ToPointVec2 (optional) @{Point#POINT_VEC2) to where the cargo should run after onboarding. If not provided, the cargo will run to 60 meters behind the Carrier location.

--- UnBoards the cargo to a Carrier. The event will create a movement (= running or driving) of the cargo from the Carrier.
-- The cargo must be in the **Loaded** state.
-- @function [parent=#CARGO] __UnBoard
-- @param #CARGO self
-- @param #number DelaySeconds The amount of seconds to delay the action.
-- @param Core.Point#POINT_VEC2 ToPointVec2 (optional) @{Point#POINT_VEC2) to where the cargo should run after onboarding. If not provided, the cargo will run to 60 meters behind the Carrier location.


-- Load

--- Loads the cargo to a Carrier. The event will load the cargo into the Carrier regardless of its position. There will be no movement simulated of the cargo loading.
-- The cargo must be in the **UnLoaded** state.
-- @function [parent=#CARGO] Load
-- @param #CARGO self
-- @param Wrapper.Controllable#CONTROLLABLE ToCarrier The Carrier that will hold the cargo.

--- Loads the cargo to a Carrier. The event will load the cargo into the Carrier regardless of its position. There will be no movement simulated of the cargo loading.
-- The cargo must be in the **UnLoaded** state.
-- @function [parent=#CARGO] __Load
-- @param #CARGO self
-- @param #number DelaySeconds The amount of seconds to delay the action.
-- @param Wrapper.Controllable#CONTROLLABLE ToCarrier The Carrier that will hold the cargo.


-- UnLoad

--- UnLoads the cargo to a Carrier. The event will unload the cargo from the Carrier. There will be no movement simulated of the cargo loading.
-- The cargo must be in the **Loaded** state.
-- @function [parent=#CARGO] UnLoad
-- @param #CARGO self
-- @param Core.Point#POINT_VEC2 ToPointVec2 (optional) @{Point#POINT_VEC2) to where the cargo will be placed after unloading. If not provided, the cargo will be placed 60 meters behind the Carrier location.

--- UnLoads the cargo to a Carrier. The event will unload the cargo from the Carrier. There will be no movement simulated of the cargo loading.
-- The cargo must be in the **Loaded** state.
-- @function [parent=#CARGO] __UnLoad
-- @param #CARGO self
-- @param #number DelaySeconds The amount of seconds to delay the action.
-- @param Core.Point#POINT_VEC2 ToPointVec2 (optional) @{Point#POINT_VEC2) to where the cargo will be placed after unloading. If not provided, the cargo will be placed 60 meters behind the Carrier location.

-- State Transition Functions

-- UnLoaded

--- @function [parent=#CARGO] OnLeaveUnLoaded
-- @param #CARGO self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable
-- @return #boolean

--- @function [parent=#CARGO] OnEnterUnLoaded
-- @param #CARGO self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable

-- Loaded

--- @function [parent=#CARGO] OnLeaveLoaded
-- @param #CARGO self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable
-- @return #boolean

--- @function [parent=#CARGO] OnEnterLoaded
-- @param #CARGO self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable

-- Boarding

--- @function [parent=#CARGO] OnLeaveBoarding
-- @param #CARGO self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable
-- @return #boolean

--- @function [parent=#CARGO] OnEnterBoarding
-- @param #CARGO self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable
-- @param #number NearRadius The radius when the cargo will board the Carrier (to avoid collision).

-- UnBoarding

--- @function [parent=#CARGO] OnLeaveUnBoarding
-- @param #CARGO self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable
-- @return #boolean

--- @function [parent=#CARGO] OnEnterUnBoarding
-- @param #CARGO self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable


-- TODO: Find all Carrier objects and make the type of the Carriers Wrapper.Unit#UNIT in the documentation.

CARGOS = {}

do -- CARGO

  --- @type CARGO
  -- @extends Core.Fsm#FSM_PROCESS
  -- @field #string Type A string defining the type of the cargo. eg. Engineers, Equipment, Screwdrivers.
  -- @field #string Name A string defining the name of the cargo. The name is the unique identifier of the cargo.
  -- @field #number Weight A number defining the weight of the cargo. The weight is expressed in kg.
  -- @field #number NearRadius (optional) A number defining the radius in meters when the cargo is near to a Carrier, so that it can be loaded.
  -- @field Wrapper.Controllable#CONTROLLABLE CargoObject The alive DCS object representing the cargo. This value can be nil, meaning, that the cargo is not represented anywhere...
  -- @field Wrapper.Client#CLIENT CargoCarrier The alive DCS object carrying the cargo. This value can be nil, meaning, that the cargo is not contained anywhere...
  -- @field #boolean Slingloadable This flag defines if the cargo can be slingloaded.
  -- @field #boolean Moveable This flag defines if the cargo is moveable.
  -- @field #boolean Representable This flag defines if the cargo can be represented by a DCS Unit.
  -- @field #boolean Containable This flag defines if the cargo can be contained within a DCS Unit.
  
  --- # (R2.1) CARGO class, extends @{Fsm#FSM_PROCESS}
  -- 
  -- The CARGO class defines the core functions that defines a cargo object within MOOSE.
  -- A cargo is a logical object defined that is available for transport, and has a life status within a simulation.
  --
  -- The CARGO is a state machine: it manages the different events and states of the cargo.
  -- All derived classes from CARGO follow the same state machine, expose the same cargo event functions, and provide the same cargo states.
  -- 
  -- ## CARGO Events:
  -- 
  --   * @{#CARGO.Board}( ToCarrier ):  Boards the cargo to a carrier.
  --   * @{#CARGO.Load}( ToCarrier ): Loads the cargo into a carrier, regardless of its position.
  --   * @{#CARGO.UnBoard}( ToPointVec2 ): UnBoard the cargo from a carrier. This will trigger a movement of the cargo to the option ToPointVec2.
  --   * @{#CARGO.UnLoad}( ToPointVec2 ): UnLoads the cargo from a carrier.
  --   * @{#CARGO.Dead}( Controllable ): The cargo is dead. The cargo process will be ended.
  -- 
  -- ## CARGO States:
  -- 
  --   * **UnLoaded**: The cargo is unloaded from a carrier.
  --   * **Boarding**: The cargo is currently boarding (= running) into a carrier.
  --   * **Loaded**: The cargo is loaded into a carrier.
  --   * **UnBoarding**: The cargo is currently unboarding (=running) from a carrier.
  --   * **Dead**: The cargo is dead ...
  --   * **End**: The process has come to an end.
  --   
  -- ## CARGO state transition methods:
  -- 
  -- State transition functions can be set **by the mission designer** customizing or improving the behaviour of the state.
  -- There are 2 moments when state transition methods will be called by the state machine:
  -- 
  --   * **Leaving** the state. 
  --     The state transition method needs to start with the name **OnLeave + the name of the state**. 
  --     If the state transition method returns false, then the processing of the state transition will not be done!
  --     If you want to change the behaviour of the AIControllable at this event, return false, 
  --     but then you'll need to specify your own logic using the AIControllable!
  --   
  --   * **Entering** the state. 
  --     The state transition method needs to start with the name **OnEnter + the name of the state**. 
  --     These state transition methods need to provide a return value, which is specified at the function description.
  --
  -- @field #CARGO
  CARGO = {
    ClassName = "CARGO",
    Type = nil,
    Name = nil,
    Weight = nil,
    CargoObject = nil,
    CargoCarrier = nil,
    Representable = false,
    Slingloadable = false,
    Moveable = false,
    Containable = false,
  }

--- @type CARGO.CargoObjects
-- @map < #string, Wrapper.Positionable#POSITIONABLE > The alive POSITIONABLE objects representing the the cargo.


--- CARGO Constructor. This class is an abstract class and should not be instantiated.
-- @param #CARGO self
-- @param #string Type
-- @param #string Name
-- @param #number Weight
-- @param #number NearRadius (optional)
-- @return #CARGO
function CARGO:New( Type, Name, Weight ) --R2.1

  local self = BASE:Inherit( self, FSM:New() ) -- #CARGO
  self:F( { Type, Name, Weight } )
  
  self:SetStartState( "UnLoaded" )
  self:AddTransition( { "UnLoaded", "Boarding" }, "Board", "Boarding" )
  self:AddTransition( "Boarding" , "Boarding", "Boarding" )
  self:AddTransition( "Boarding", "CancelBoarding", "UnLoaded" )
  self:AddTransition( "Boarding", "Load", "Loaded" )
  self:AddTransition( "UnLoaded", "Load", "Loaded" )
  self:AddTransition( "Loaded", "UnBoard", "UnBoarding" )
  self:AddTransition( "UnBoarding", "UnBoarding", "UnBoarding" )
  self:AddTransition( "UnBoarding", "UnLoad", "UnLoaded" )
  self:AddTransition( "Loaded", "UnLoad", "UnLoaded" )
  self:AddTransition( "*", "Damaged", "Damaged" )
  self:AddTransition( "*", "Destroyed", "Destroyed" )
  self:AddTransition( "*", "Respawn", "UnLoaded" )


  self.Type = Type
  self.Name = Name
  self.Weight = Weight
  self.CargoObject = nil
  self.CargoCarrier = nil
  self.Representable = false
  self.Slingloadable = false
  self.Moveable = false
  self.Containable = false
  
  self:SetDeployed( false )

  self.CargoScheduler = SCHEDULER:New()

  CARGOS[self.Name] = self

  
  return self
end

--- Destroy the cargo.
-- @param #CARGO self
function CARGO:Destroy()
  if self.CargoObject then
    self.CargoObject:Destroy()
  end
  self:Destroyed()
end

--- Get the name of the Cargo.
-- @param #CARGO self
-- @return #string The name of the Cargo.
function CARGO:GetName() --R2.1
  return self.Name
end

--- Get the object name of the Cargo.
-- @param #CARGO self
-- @return #string The object name of the Cargo.
function CARGO:GetObjectName() --R2.1
  if self:IsLoaded() then
    return self.CargoCarrier:GetName()
  else
    return self.CargoObject:GetName()
  end 
end

--- Get the type of the Cargo.
-- @param #CARGO self
-- @return #string The type of the Cargo.
function CARGO:GetType()
  return self.Type
end

--- Get the current coordinates of the Cargo.
-- @param #CARGO self
-- @return Core.Point#COORDINATE The coordinates of the Cargo.
function CARGO:GetCoordinate()
  return self.CargoObject:GetCoordinate()
end

--- Check if cargo is destroyed.
-- @param #CARGO self
-- @return #boolean true if destroyed
function CARGO:IsDestroyed()
  return self:Is( "Destroyed" )
end


--- Check if cargo is loaded.
-- @param #CARGO self
-- @return #boolean true if loaded
function CARGO:IsLoaded()
  return self:Is( "Loaded" )
end

--- Check if cargo is unloaded.
-- @param #CARGO self
-- @return #boolean true if unloaded
function CARGO:IsUnLoaded()
  return self:Is( "UnLoaded" )
end

--- Check if cargo is alive.
-- @param #CARGO self
-- @return #boolean true if unloaded
function CARGO:IsAlive()

  if self:IsLoaded() then
    return self.CargoCarrier:IsAlive()
  else
    return self.CargoObject:IsAlive()
  end 
end

--- Set the cargo as deployed
-- @param #CARGO self
function CARGO:SetDeployed( Deployed )
  self.Deployed = Deployed
end

--- Is the cargo deployed
-- @param #CARGO self
-- @return #boolean
function CARGO:IsDeployed()
  return self.Deployed
end




--- Template method to spawn a new representation of the CARGO in the simulator.
-- @param #CARGO self
-- @return #CARGO
function CARGO:Spawn( PointVec2 )
  self:F()

end

--- Signal a flare at the position of the CARGO.
-- @param #CARGO self
-- @param Utilities.Utils#FLARECOLOR FlareColor
function CARGO:Flare( FlareColor )
  if self:IsUnLoaded() then
    trigger.action.signalFlare( self.CargoObject:GetVec3(), FlareColor , 0 )
  end
end

--- Signal a white flare at the position of the CARGO.
-- @param #CARGO self
function CARGO:FlareWhite()
  self:Flare( trigger.flareColor.White )
end

--- Signal a yellow flare at the position of the CARGO.
-- @param #CARGO self
function CARGO:FlareYellow()
  self:Flare( trigger.flareColor.Yellow )
end

--- Signal a green flare at the position of the CARGO.
-- @param #CARGO self
function CARGO:FlareGreen()
  self:Flare( trigger.flareColor.Green )
end

--- Signal a red flare at the position of the CARGO.
-- @param #CARGO self
function CARGO:FlareRed()
  self:Flare( trigger.flareColor.Red )
end

--- Smoke the CARGO.
-- @param #CARGO self
function CARGO:Smoke( SmokeColor, Range )
  self:F2()
  if self:IsUnLoaded() then
    if Range then
      trigger.action.smoke( self.CargoObject:GetRandomVec3( Range ), SmokeColor )
    else
      trigger.action.smoke( self.CargoObject:GetVec3(), SmokeColor )
    end
  end
end

--- Smoke the CARGO Green.
-- @param #CARGO self
function CARGO:SmokeGreen()
  self:Smoke( trigger.smokeColor.Green, Range )
end

--- Smoke the CARGO Red.
-- @param #CARGO self
function CARGO:SmokeRed()
  self:Smoke( trigger.smokeColor.Red, Range )
end

--- Smoke the CARGO White.
-- @param #CARGO self
function CARGO:SmokeWhite()
  self:Smoke( trigger.smokeColor.White, Range )
end

--- Smoke the CARGO Orange.
-- @param #CARGO self
function CARGO:SmokeOrange()
  self:Smoke( trigger.smokeColor.Orange, Range )
end

--- Smoke the CARGO Blue.
-- @param #CARGO self
function CARGO:SmokeBlue()
  self:Smoke( trigger.smokeColor.Blue, Range )
end






--- Check if Cargo is the given @{Zone}.
-- @param #CARGO self
-- @param Core.Zone#ZONE_BASE Zone
-- @return #boolean **true** if cargo is in the Zone, **false** if cargo is not in the Zone.
function CARGO:IsInZone( Zone )
  self:F( { Zone } )

  if self:IsLoaded() then
    return Zone:IsPointVec2InZone( self.CargoCarrier:GetPointVec2() )
  else
    self:F( { Size = self.CargoObject:GetSize(), Units = self.CargoObject:GetUnits() } )
    if self.CargoObject:GetSize() ~= 0 then
      return Zone:IsPointVec2InZone( self.CargoObject:GetPointVec2() )
    else
      return false
    end
  end  
  
  return nil

end


--- Check if CargoCarrier is near the Cargo to be Loaded.
-- @param #CARGO self
-- @param Core.Point#POINT_VEC2 PointVec2
-- @param #number NearRadius The radius when the cargo will board the Carrier (to avoid collision).
-- @return #boolean
function CARGO:IsNear( PointVec2, NearRadius )
  self:F( { PointVec2, NearRadius } )

  --local Distance = PointVec2:DistanceFromPointVec2( self.CargoObject:GetPointVec2() )
  local Distance = PointVec2:Get2DDistance( self.CargoObject:GetPointVec2() )
  self:T( Distance )
  
  if Distance <= NearRadius then
    return true
  else
    return false
  end
end

--- Get the current PointVec2 of the cargo.
-- @param #CARGO self
-- @return Core.Point#POINT_VEC2
function CARGO:GetPointVec2()
  return self.CargoObject:GetPointVec2()
end

--- Get the current Coordinate of the cargo.
-- @param #CARGO self
-- @return Core.Point#COORDINATE
function CARGO:GetCoordinate()
  return self.CargoObject:GetCoordinate()
end

--- Set the weight of the cargo.
-- @param #CARGO self
-- @param #number Weight The weight in kg.
-- @return #CARGO
function CARGO:SetWeight( Weight )
  self.Weight = Weight
  return self
end

end


do -- CARGO_REPRESENTABLE

  --- @type CARGO_REPRESENTABLE
  -- @extends #CARGO
  -- @field test

  --- Models CARGO that is representable by a Unit.
  -- @field #CARGO_REPRESENTABLE CARGO_REPRESENTABLE
  CARGO_REPRESENTABLE = {
    ClassName = "CARGO_REPRESENTABLE"
  }

  --- CARGO_REPRESENTABLE Constructor.
  -- @param #CARGO_REPRESENTABLE self
  -- @param #string Type
  -- @param #string Name
  -- @param #number Weight
  -- @param #number ReportRadius (optional)
  -- @param #number NearRadius (optional)
  -- @return #CARGO_REPRESENTABLE
  function CARGO_REPRESENTABLE:New( CargoObject, Type, Name, Weight, ReportRadius, NearRadius )
    local self = BASE:Inherit( self, CARGO:New( Type, Name, Weight, ReportRadius, NearRadius ) ) -- #CARGO_REPRESENTABLE
    self:F( { Type, Name, Weight, ReportRadius, NearRadius } )
  
    return self
  end

  --- CARGO_REPRESENTABLE Destructor.
  -- @param #CARGO_REPRESENTABLE self
  -- @return #CARGO_REPRESENTABLE
  function CARGO_REPRESENTABLE:Destroy()
  
    -- Cargo objects are deleted from the _DATABASE and SET_CARGO objects.
    self:F( { CargoName = self:GetName() } )
    _EVENTDISPATCHER:CreateEventDeleteCargo( self )
  
    return self
  end
  
  --- Route a cargo unit to a PointVec2.
  -- @param #CARGO_REPRESENTABLE self
  -- @param Core.Point#POINT_VEC2 ToPointVec2
  -- @param #number Speed
  -- @return #CARGO_REPRESENTABLE
  function CARGO_REPRESENTABLE:RouteTo( ToPointVec2, Speed )
    self:F2( ToPointVec2 )
  
    local Points = {}
  
    local PointStartVec2 = self.CargoObject:GetPointVec2()
  
    Points[#Points+1] = PointStartVec2:WaypointGround( Speed )
    Points[#Points+1] = ToPointVec2:WaypointGround( Speed )
  
    local TaskRoute = self.CargoObject:TaskRoute( Points )
    self.CargoObject:SetTask( TaskRoute, 2 )
    return self  
  end
  
  
end -- CARGO_REPRESENTABLE

  do -- CARGO_REPORTABLE
  
    --- @type CARGO_REPORTABLE
    -- @extends #CARGO
    CARGO_REPORTABLE = {
      ClassName = "CARGO_REPORTABLE"
    }
  
  --- CARGO_REPORTABLE Constructor.
  -- @param #CARGO_REPORTABLE self
  -- @param Wrapper.Controllable#Controllable CargoObject
  -- @param #string Type
  -- @param #string Name
  -- @param #number Weight
  -- @param #number ReportRadius (optional)
  -- @param #number NearRadius (optional)
  -- @return #CARGO_REPORTABLE
  function CARGO_REPORTABLE:New( CargoObject, Type, Name, Weight, ReportRadius )
    local self = BASE:Inherit( self, CARGO:New( Type, Name, Weight ) ) -- #CARGO_REPORTABLE
    self:F( { Type, Name, Weight, ReportRadius } )
  
    self.CargoSet = SET_CARGO:New() -- Core.Set#SET_CARGO
  
    self.ReportRadius = ReportRadius or 1000
    self.CargoObject = CargoObject


  
    return self
  end
  
  --- Check if CargoCarrier is in the ReportRadius for the Cargo to be Loaded.
  -- @param #CARGO_REPORTABLE self
  -- @param Core.Point#POINT_VEC2 PointVec2
  -- @return #boolean
  function CARGO_REPORTABLE:IsInRadius( PointVec2 )
    self:F( { PointVec2 } )
  
    local Distance = 0
    if self:IsLoaded() then
      Distance = PointVec2:DistanceFromPointVec2( self.CargoCarrier:GetPointVec2() )
    else
      Distance = PointVec2:DistanceFromPointVec2( self.CargoObject:GetPointVec2() )
    end
    self:T( Distance )
    
    if Distance <= self.ReportRadius then
      return true
    else
      return false
    end
  
  
  end

  --- Send a CC message to a GROUP.
  -- @param #CARGO_REPORTABLE self
  -- @param #string Message
  -- @param Wrapper.Group#GROUP TaskGroup
  -- @param #sring Name (optional) The name of the Group used as a prefix for the message to the Group. If not provided, there will be nothing shown.
  function CARGO_REPORTABLE:MessageToGroup( Message, TaskGroup, Name )
  
    local Prefix = Name and "@ " .. Name .. ": " or "@ " .. TaskGroup:GetCallsign() .. ": "
    Message = Prefix .. Message 
    MESSAGE:New( Message, 20, "Cargo: " .. self:GetName() ):ToGroup( TaskGroup )
  
  end

  --- Get the range till cargo will board.
  -- @param #CARGO_REPORTABLE self
  -- @return #number The range till cargo will board.
  function CARGO_REPORTABLE:GetBoardingRange()
    return self.ReportRadius
  end
  
  --- Respawn the cargo.
  -- @param #CARGO_REPORTABLE self
  function CARGO_REPORTABLE:Respawn()

    self:F({"Respawning"})

    for CargoID, CargoData in pairs( self.CargoSet:GetSet() ) do
      local Cargo = CargoData -- #CARGO
      Cargo:Destroy()
      Cargo:SetStartState( "UnLoaded" )
    end

    local CargoObject = self.CargoObject -- Wrapper.Group#GROUP
    CargoObject:Destroy()
    local Template = CargoObject:GetTemplate()
    CargoObject:Respawn( Template )
  
    self:SetDeployed( false )
  
    local WeightGroup = 0
        
    self:SetStartState( "UnLoaded" )
    
  end

  
end

do -- CARGO_UNIT

  --- Models CARGO in the form of units, which can be boarded, unboarded, loaded, unloaded. 
  -- @type CARGO_UNIT
  -- @extends #CARGO_REPRESENTABLE
  
  --- # CARGO\_UNIT class, extends @{#CARGO_REPRESENTABLE}
  -- 
  -- The CARGO\_UNIT class defines a cargo that is represented by a UNIT object within the simulator, and can be transported by a carrier.
  -- Use the event functions as described above to Load, UnLoad, Board, UnBoard the CARGO\_UNIT objects to and from carriers.
  -- 
  -- ===
  -- 
  -- @field #CARGO_UNIT CARGO_UNIT
  --
  CARGO_UNIT = {
    ClassName = "CARGO_UNIT"
  }

  --- CARGO_UNIT Constructor.
  -- @param #CARGO_UNIT self
  -- @param Wrapper.Unit#UNIT CargoUnit
  -- @param #string Type
  -- @param #string Name
  -- @param #number Weight
  -- @param #number ReportRadius (optional)
  -- @param #number NearRadius (optional)
  -- @return #CARGO_UNIT
  function CARGO_UNIT:New( CargoUnit, Type, Name, Weight, NearRadius )
    local self = BASE:Inherit( self, CARGO_REPRESENTABLE:New( CargoUnit, Type, Name, Weight, NearRadius ) ) -- #CARGO_UNIT
    self:F( { Type, Name, Weight, NearRadius } )
  
    self:T( CargoUnit )
    self.CargoObject = CargoUnit
  
    self:T( self.ClassName )
  
    self:SetEventPriority( 5 )
  
    return self
  end
  
  --- Enter UnBoarding State.
  -- @param #CARGO_UNIT self
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  -- @param Core.Point#POINT_VEC2 ToPointVec2
  function CARGO_UNIT:onenterUnBoarding( From, Event, To, ToPointVec2, NearRadius )
    self:F( { From, Event, To, ToPointVec2, NearRadius } )
  
    NearRadius = NearRadius or 25
  
    local Angle = 180
    local Speed = 60
    local DeployDistance = 9
    local RouteDistance = 60
  
    if From == "Loaded" then
  
      local CargoCarrier = self.CargoCarrier -- Wrapper.Controllable#CONTROLLABLE
  
      local CargoCarrierPointVec2 = CargoCarrier:GetPointVec2()
      local CargoCarrierHeading = self.CargoCarrier:GetHeading() -- Get Heading of object in degrees.
      local CargoDeployHeading = ( ( CargoCarrierHeading + Angle ) >= 360 ) and ( CargoCarrierHeading + Angle - 360 ) or ( CargoCarrierHeading + Angle )
  
  
      local CargoRoutePointVec2 = CargoCarrierPointVec2:Translate( RouteDistance, CargoDeployHeading )
      
      
      -- if there is no ToPointVec2 given, then use the CargoRoutePointVec2
      ToPointVec2 = ToPointVec2 or CargoRoutePointVec2
      local DirectionVec3 = CargoCarrierPointVec2:GetDirectionVec3(ToPointVec2)
      local Angle = CargoCarrierPointVec2:GetAngleDegrees(DirectionVec3)
  
      local CargoDeployPointVec2 = CargoCarrierPointVec2:Translate( DeployDistance, Angle )
      
      local FromPointVec2 = CargoCarrierPointVec2
  
      -- Respawn the group...
      if self.CargoObject then
        self.CargoObject:ReSpawn( CargoDeployPointVec2:GetVec3(), CargoDeployHeading )
        self:F( { "CargoUnits:", self.CargoObject:GetGroup():GetName() } )
        self.CargoCarrier = nil
  
        local Points = {}
        Points[#Points+1] = CargoCarrierPointVec2:WaypointGround( Speed )
        
        Points[#Points+1] = ToPointVec2:WaypointGround( Speed )
    
        local TaskRoute = self.CargoObject:TaskRoute( Points )
        self.CargoObject:SetTask( TaskRoute, 1 )
  
        
        self:__UnBoarding( 1, ToPointVec2, NearRadius )
      end
    end
  
  end
  
  --- Leave UnBoarding State.
  -- @param #CARGO_UNIT self
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  -- @param Core.Point#POINT_VEC2 ToPointVec2
  function CARGO_UNIT:onleaveUnBoarding( From, Event, To, ToPointVec2, NearRadius )
    self:F( { From, Event, To, ToPointVec2, NearRadius } )
  
    NearRadius = NearRadius or 25
  
    local Angle = 180
    local Speed = 10
    local Distance = 5
  
    if From == "UnBoarding" then
      if self:IsNear( ToPointVec2, NearRadius ) then
        return true
      else
        
        self:__UnBoarding( 1, ToPointVec2, NearRadius )
      end
      return false
    end
  
  end
  
  --- UnBoard Event.
  -- @param #CARGO_UNIT self
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  -- @param Core.Point#POINT_VEC2 ToPointVec2
  function CARGO_UNIT:onafterUnBoarding( From, Event, To, ToPointVec2, NearRadius )
    self:F( { From, Event, To, ToPointVec2, NearRadius } )
  
    NearRadius = NearRadius or 25
  
    self.CargoInAir = self.CargoObject:InAir()
  
    self:T( self.CargoInAir )
  
    -- Only unboard the cargo when the carrier is not in the air.
    -- (eg. cargo can be on a oil derrick, moving the cargo on the oil derrick will drop the cargo on the sea).
    if not self.CargoInAir then
  
    end
  
    self:__UnLoad( 1, ToPointVec2, NearRadius )
  
  end
  
  
  
  --- Enter UnLoaded State.
  -- @param #CARGO_UNIT self
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  -- @param Core.Point#POINT_VEC2
  function CARGO_UNIT:onenterUnLoaded( From, Event, To, ToPointVec2 )
    self:F( { ToPointVec2, From, Event, To } )
  
    local Angle = 180
    local Speed = 10
    local Distance = 5
  
    if From == "Loaded" then
      local StartPointVec2 = self.CargoCarrier:GetPointVec2()
      local CargoCarrierHeading = self.CargoCarrier:GetHeading() -- Get Heading of object in degrees.
      local CargoDeployHeading = ( ( CargoCarrierHeading + Angle ) >= 360 ) and ( CargoCarrierHeading + Angle - 360 ) or ( CargoCarrierHeading + Angle )
      local CargoDeployCoord = StartPointVec2:Translate( Distance, CargoDeployHeading )
  
      ToPointVec2 = ToPointVec2 or COORDINATE:New( CargoDeployCoord.x, CargoDeployCoord.z )
  
      -- Respawn the group...
      if self.CargoObject then
        self.CargoObject:ReSpawn( ToPointVec2:GetVec3(), 0 )
        self.CargoCarrier = nil
      end
      
    end
  
    if self.OnUnLoadedCallBack then
      self.OnUnLoadedCallBack( self, unpack( self.OnUnLoadedParameters ) )
      self.OnUnLoadedCallBack = nil
    end
  
  end
  
  --- Board Event.
  -- @param #CARGO_UNIT self
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  function CARGO_UNIT:onafterBoard( From, Event, To, CargoCarrier, NearRadius, ... )
    self:F( { From, Event, To, CargoCarrier, NearRadius } )
  
    local NearRadius = NearRadius or 25
    
    self.CargoInAir = self.CargoObject:InAir()
  
    self:T( self.CargoInAir )
  
    -- Only move the group to the carrier when the cargo is not in the air
    -- (eg. cargo can be on a oil derrick, moving the cargo on the oil derrick will drop the cargo on the sea).
    if not self.CargoInAir then
      if self:IsNear( CargoCarrier:GetPointVec2(), NearRadius ) then
        self:Load( CargoCarrier, NearRadius, ... )
      else
        local Speed = 90
        local Angle = 180
        local Distance = 5
        
        NearRadius = NearRadius or 25
      
        local CargoCarrierPointVec2 = CargoCarrier:GetPointVec2()
        local CargoCarrierHeading = CargoCarrier:GetHeading() -- Get Heading of object in degrees.
        local CargoDeployHeading = ( ( CargoCarrierHeading + Angle ) >= 360 ) and ( CargoCarrierHeading + Angle - 360 ) or ( CargoCarrierHeading + Angle )
        local CargoDeployPointVec2 = CargoCarrierPointVec2:Translate( Distance, CargoDeployHeading )
      
        local Points = {}
      
        local PointStartVec2 = self.CargoObject:GetPointVec2()
      
        Points[#Points+1] = PointStartVec2:WaypointGround( Speed )
        Points[#Points+1] = CargoDeployPointVec2:WaypointGround( Speed )
      
        local TaskRoute = self.CargoObject:TaskRoute( Points )
        self.CargoObject:SetTask( TaskRoute, 2 )
        self:__Boarding( -1, CargoCarrier, NearRadius )
        self.RunCount = 0
      end
    end
    
  end
  
  
  --- Boarding Event.
  -- @param #CARGO_UNIT self
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  -- @param Wrapper.Unit#UNIT CargoCarrier
  -- @param #number NearRadius
  function CARGO_UNIT:onafterBoarding( From, Event, To, CargoCarrier, NearRadius, ... )
    self:F( { From, Event, To, CargoCarrier.UnitName, NearRadius } )
    
    
    if CargoCarrier and CargoCarrier:IsAlive() then 
      if CargoCarrier:InAir() == false then
        if self:IsNear( CargoCarrier:GetPointVec2(), NearRadius ) then
          self:__Load( 1, CargoCarrier, ... )
        else
          self:__Boarding( -1, CargoCarrier, NearRadius, ... )
          self.RunCount = self.RunCount + 1
          if self.RunCount >= 20 then
            self.RunCount = 0
            local Speed = 90
            local Angle = 180
            local Distance = 5
            
            NearRadius = NearRadius or 25
          
            local CargoCarrierPointVec2 = CargoCarrier:GetPointVec2()
            local CargoCarrierHeading = CargoCarrier:GetHeading() -- Get Heading of object in degrees.
            local CargoDeployHeading = ( ( CargoCarrierHeading + Angle ) >= 360 ) and ( CargoCarrierHeading + Angle - 360 ) or ( CargoCarrierHeading + Angle )
            local CargoDeployPointVec2 = CargoCarrierPointVec2:Translate( Distance, CargoDeployHeading )
          
            local Points = {}
          
            local PointStartVec2 = self.CargoObject:GetPointVec2()
          
            Points[#Points+1] = PointStartVec2:WaypointGround( Speed )
            Points[#Points+1] = CargoDeployPointVec2:WaypointGround( Speed )
          
            local TaskRoute = self.CargoObject:TaskRoute( Points )
            self.CargoObject:SetTask( TaskRoute, 0.2 )
          end
        end
      else
        self.CargoObject:MessageToGroup( "Cancelling Boarding... Get back on the ground!", 5, CargoCarrier:GetGroup(), self:GetName() )
        self:CancelBoarding( CargoCarrier, NearRadius, ... )
        self.CargoObject:SetCommand( self.CargoObject:CommandStopRoute( true ) )
      end
    else
      self:E("Something is wrong")
    end
    
  end
  
  
  --- Enter Boarding State.
  -- @param #CARGO_UNIT self
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  -- @param Wrapper.Unit#UNIT CargoCarrier
  function CARGO_UNIT:onenterBoarding( From, Event, To, CargoCarrier, NearRadius, ... )
    self:F( { From, Event, To, CargoCarrier.UnitName, NearRadius } )
    
    local Speed = 90
    local Angle = 180
    local Distance = 5
    
    local NearRadius = NearRadius or 25
  
    if From == "UnLoaded" or From == "Boarding" then
    
    end
    
  end
  
  --- Loaded State.
  -- @param #CARGO_UNIT self
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  -- @param Wrapper.Unit#UNIT CargoCarrier
  function CARGO_UNIT:onenterLoaded( From, Event, To, CargoCarrier )
    self:F( { From, Event, To, CargoCarrier } )
  
    self.CargoCarrier = CargoCarrier
    
    -- Only destroy the CargoObject is if there is a CargoObject (packages don't have CargoObjects).
    if self.CargoObject then
      self:T("Destroying")
      self.CargoObject:Destroy()
    end
  end

end -- CARGO_UNIT


do -- CARGO_CRATE

  --- Models the behaviour of cargo crates, which can be slingloaded and boarded on helicopters using the DCS menus. 
  -- @type CARGO_CRATE
  -- @extends #CARGO_REPRESENTABLE
  
  --- # CARGO\_CRATE class, extends @{#CARGO_REPRESENTABLE}
  -- 
  -- The CARGO\_CRATE class defines a cargo that is represented by a UNIT object within the simulator, and can be transported by a carrier.
  -- Use the event functions as described above to Load, UnLoad, Board, UnBoard the CARGO\_CRATE objects to and from carriers.
  -- 
  -- ===
  -- 
  -- @field #CARGO_CRATE
  CARGO_CRATE = {
    ClassName = "CARGO_CRATE"
  }
  
  --- CARGO_CRATE Constructor.
  -- @param #CARGO_CRATE self
  -- @param #string CrateName
  -- @param #string Type
  -- @param #string Name
  -- @param #number Weight
  -- @param #number ReportRadius (optional)
  -- @param #number NearRadius (optional)
  -- @return #CARGO_CRATE
  function CARGO_CRATE:New( CargoCrateName, Type, Name, NearRadius )
    local self = BASE:Inherit( self, CARGO_REPRESENTABLE:New( CargoCrateName, Type, Name, nil, NearRadius ) ) -- #CARGO_CRATE
    self:F( { Type, Name, NearRadius } )
  
    self:T( CargoCrateName )
    _DATABASE:AddStatic( CargoCrateName )
    
    self.CargoObject = STATIC:FindByName( CargoCrateName )
  
    self:T( self.ClassName )
  
    self:SetEventPriority( 5 )
  
    return self
  end
  
  
  
  --- Enter UnLoaded State.
  -- @param #CARGO_CRATE self
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  -- @param Core.Point#POINT_VEC2
  function CARGO_CRATE:onenterUnLoaded( From, Event, To, ToPointVec2 )
    self:F( { ToPointVec2, From, Event, To } )
  
    local Angle = 180
    local Speed = 10
    local Distance = 10
  
    if From == "Loaded" then
      local StartCoordinate = self.CargoCarrier:GetCoordinate()
      local CargoCarrierHeading = self.CargoCarrier:GetHeading() -- Get Heading of object in degrees.
      local CargoDeployHeading = ( ( CargoCarrierHeading + Angle ) >= 360 ) and ( CargoCarrierHeading + Angle - 360 ) or ( CargoCarrierHeading + Angle )
      local CargoDeployCoord = StartCoordinate:Translate( Distance, CargoDeployHeading )
  
      ToPointVec2 = ToPointVec2 or COORDINATE:NewFromVec2( { x= CargoDeployCoord.x, y = CargoDeployCoord.z } )
  
      -- Respawn the group...
      if self.CargoObject then
        self.CargoObject:ReSpawn( ToPointVec2, 0 )
        self.CargoCarrier = nil
      end
      
    end
  
    if self.OnUnLoadedCallBack then
      self.OnUnLoadedCallBack( self, unpack( self.OnUnLoadedParameters ) )
      self.OnUnLoadedCallBack = nil
    end
  
  end

  
  --- Loaded State.
  -- @param #CARGO_CRATE self
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  -- @param Wrapper.Unit#UNIT CargoCarrier
  function CARGO_CRATE:onenterLoaded( From, Event, To, CargoCarrier )
    self:F( { From, Event, To, CargoCarrier } )
  
    self.CargoCarrier = CargoCarrier
    
    -- Only destroy the CargoObject is if there is a CargoObject (packages don't have CargoObjects).
    if self.CargoObject then
      self:T("Destroying")
      self.CargoObject:Destroy()
    end
  end



end

do -- CARGO_GROUP

  --- @type CARGO_GROUP
  -- @extends #CARGO_REPORTABLE
  
  --- # CARGO\_GROUP class
  --
  -- The CARGO\_GROUP class defines a cargo that is represented by a @{Group} object within the simulator, and can be transported by a carrier.
  -- Use the event functions as described above to Load, UnLoad, Board, UnBoard the CARGO\_GROUP to and from carrier.
  --
  -- @field #CARGO_GROUP CARGO_GROUP
  -- 
  CARGO_GROUP = {
    ClassName = "CARGO_GROUP",
  }

--- CARGO_GROUP constructor.
-- @param #CARGO_GROUP self
-- @param Wrapper.Group#GROUP CargoGroup
-- @param #string Type
-- @param #string Name
-- @param #number ReportRadius (optional)
-- @param #number NearRadius (optional)
-- @return #CARGO_GROUP
function CARGO_GROUP:New( CargoGroup, Type, Name, ReportRadius )
  local self = BASE:Inherit( self, CARGO_REPORTABLE:New( CargoGroup, Type, Name, 0, ReportRadius ) ) -- #CARGO_GROUP
  self:F( { Type, Name, ReportRadius } )

  self.CargoObject = CargoGroup
  self:SetDeployed( false )
  self.CargoGroup = CargoGroup
  
  local WeightGroup = 0
  
  for UnitID, UnitData in pairs( CargoGroup:GetUnits() ) do
    local Unit = UnitData -- Wrapper.Unit#UNIT
    local WeightUnit = Unit:GetDesc().massEmpty
    WeightGroup = WeightGroup + WeightUnit
    local CargoUnit = CARGO_UNIT:New( Unit, Type, Unit:GetName(), WeightUnit )
    self.CargoSet:Add( CargoUnit:GetName(), CargoUnit )
  end

  self:SetWeight( WeightGroup )
  
  self:T( { "Weight Cargo", WeightGroup } )

  -- Cargo objects are added to the _DATABASE and SET_CARGO objects.
  _EVENTDISPATCHER:CreateEventNewCargo( self )
  
  self:HandleEvent( EVENTS.Dead, self.OnEventCargoDead )
  self:HandleEvent( EVENTS.Crash, self.OnEventCargoDead )
  self:HandleEvent( EVENTS.PlayerLeaveUnit, self.OnEventCargoDead )
  
  self:SetEventPriority( 4 )
  
  return self
end

--- @param #CARGO_GROUP self
-- @param Core.Event#EVENTDATA EventData 
function CARGO_GROUP:OnEventCargoDead( EventData )

  local Destroyed = false
  
  if self:IsDestroyed() or self:IsUnLoaded() then
    Destroyed = true
    for CargoID, CargoData in pairs( self.CargoSet:GetSet() ) do
      local Cargo = CargoData -- #CARGO
      if Cargo:IsAlive() then
        Destroyed = false
      else
        Cargo:Destroyed()
      end
    end
  else
    local CarrierName = self.CargoCarrier:GetName()
    if CarrierName == EventData.IniDCSUnitName then
      MESSAGE:New( "Cargo is lost from carrier " .. CarrierName, 15 ):ToAll()
      Destroyed = true
      self.CargoCarrier:ClearCargo()
    end
  end
  
  if Destroyed then
    self:Destroyed()
    self:E( { "Cargo group destroyed" } )
  end

end

--- Enter Boarding State.
-- @param #CARGO_GROUP self
-- @param Wrapper.Unit#UNIT CargoCarrier
-- @param #string Event
-- @param #string From
-- @param #string To
function CARGO_GROUP:onenterBoarding( From, Event, To, CargoCarrier, NearRadius, ... )
  self:F( { CargoCarrier.UnitName, From, Event, To } )
  
  local NearRadius = NearRadius or 25
  
  if From == "UnLoaded" then

    -- For each Cargo object within the CARGO_GROUPED, route each object to the CargoLoadPointVec2
    self.CargoSet:ForEach(
      function( Cargo, ... )
        Cargo:__Board( 1, CargoCarrier, NearRadius, ... )
      end, ...
    )
    
    self:__Boarding( 1, CargoCarrier, NearRadius, ... )
  end
  
end

--- Enter Loaded State.
-- @param #CARGO_GROUP self
-- @param Wrapper.Unit#UNIT CargoCarrier
-- @param #string Event
-- @param #string From
-- @param #string To
function CARGO_GROUP:onenterLoaded( From, Event, To, CargoCarrier, ... )
  self:F( { From, Event, To, CargoCarrier, ...} )
  
  if From == "UnLoaded" then
    -- For each Cargo object within the CARGO_GROUP, load each cargo to the CargoCarrier.
    for CargoID, Cargo in pairs( self.CargoSet:GetSet() ) do
      Cargo:Load( CargoCarrier )
    end
  end
  
  --self.CargoObject:Destroy()
  self.CargoCarrier = CargoCarrier
  
end

--- Leave Boarding State.
-- @param #CARGO_GROUP self
-- @param Wrapper.Unit#UNIT CargoCarrier
-- @param #string Event
-- @param #string From
-- @param #string To
function CARGO_GROUP:onafterBoarding( From, Event, To, CargoCarrier, NearRadius, ... )
  self:F( { CargoCarrier.UnitName, From, Event, To } )

  local NearRadius = NearRadius or 25

  local Boarded = true
  local Cancelled = false
  local Dead = true

  self.CargoSet:Flush()

  -- For each Cargo object within the CARGO_GROUP, route each object to the CargoLoadPointVec2
  for CargoID, Cargo in pairs( self.CargoSet:GetSet() ) do
    self:T( { Cargo:GetName(), Cargo.current } )
    if not Cargo:is( "Loaded" ) then
      Boarded = false
    end
    
    if Cargo:is( "UnLoaded" ) then
      Cancelled = true
    end

    if not Cargo:is( "Destroyed" ) then
      Dead = false
    end
    
  end

  if not Dead then

    if not Cancelled then
      if not Boarded then
        self:__Boarding( 1, CargoCarrier, NearRadius, ... )
      else
        self:__Load( 1, CargoCarrier, ... )
      end
    else
        self:__CancelBoarding( 1, CargoCarrier, NearRadius, ... )
    end
  else
    self:__Destroyed( 1, CargoCarrier, NearRadius, ... )
  end
  
end

--- Get the amount of cargo units in the group.
-- @param #CARGO_GROUP self
-- @return #CARGO_GROUP
function CARGO_GROUP:GetCount()
  return self.CargoSet:Count()
end


--- Enter UnBoarding State.
-- @param #CARGO_GROUP self
-- @param Core.Point#POINT_VEC2 ToPointVec2
-- @param #string Event
-- @param #string From
-- @param #string To
function CARGO_GROUP:onenterUnBoarding( From, Event, To, ToPointVec2, NearRadius, ... )
  self:F( {From, Event, To, ToPointVec2, NearRadius } )

  NearRadius = NearRadius or 25

  local Timer = 1

  if From == "Loaded" then
  
    if self.CargoObject then
      self.CargoObject:Destroy()
    end

    -- For each Cargo object within the CARGO_GROUP, route each object to the CargoLoadPointVec2
    self.CargoSet:ForEach(
      function( Cargo, NearRadius )
        
        Cargo:__UnBoard( Timer, ToPointVec2, NearRadius )
        Timer = Timer + 10
      end, { NearRadius }
    )
    
    
    self:__UnBoarding( 1, ToPointVec2, NearRadius, ... )
  end

end

--- Leave UnBoarding State.
-- @param #CARGO_GROUP self
-- @param Core.Point#POINT_VEC2 ToPointVec2
-- @param #string Event
-- @param #string From
-- @param #string To
function CARGO_GROUP:onleaveUnBoarding( From, Event, To, ToPointVec2, NearRadius, ... )
  self:F( { From, Event, To, ToPointVec2, NearRadius } )

  --local NearRadius = NearRadius or 25

  local Angle = 180
  local Speed = 10
  local Distance = 5

  if From == "UnBoarding" then
    local UnBoarded = true

    -- For each Cargo object within the CARGO_GROUP, route each object to the CargoLoadPointVec2
    for CargoID, Cargo in pairs( self.CargoSet:GetSet() ) do
      self:T( Cargo.current )
      if not Cargo:is( "UnLoaded" ) then
        UnBoarded = false
      end
    end
  
    if UnBoarded then
      return true
    else
      self:__UnBoarding( 1, ToPointVec2, NearRadius, ... )
    end
    
    return false
  end
  
end

--- UnBoard Event.
-- @param #CARGO_GROUP self
-- @param Core.Point#POINT_VEC2 ToPointVec2
-- @param #string Event
-- @param #string From
-- @param #string To
function CARGO_GROUP:onafterUnBoarding( From, Event, To, ToPointVec2, NearRadius, ... )
  self:F( { From, Event, To, ToPointVec2, NearRadius } )

  --local NearRadius = NearRadius or 25

  self:__UnLoad( 1, ToPointVec2, ... )
end



--- Enter UnLoaded State.
-- @param #CARGO_GROUP self
-- @param Core.Point#POINT_VEC2
-- @param #string Event
-- @param #string From
-- @param #string To
function CARGO_GROUP:onenterUnLoaded( From, Event, To, ToPointVec2, ... )
  self:F( { From, Event, To, ToPointVec2 } )

  if From == "Loaded" then
    
    -- For each Cargo object within the CARGO_GROUP, route each object to the CargoLoadPointVec2
    self.CargoSet:ForEach(
      function( Cargo )
        Cargo:UnLoad( ToPointVec2 )
      end
    )

  end
  
end


  --- Respawn the cargo when destroyed
  -- @param #CARGO_GROUP self
  -- @param #boolean RespawnDestroyed
  function CARGO_GROUP:RespawnOnDestroyed( RespawnDestroyed )
    self:F({"In function RespawnOnDestroyed"})
    if RespawnDestroyed then
      self.onenterDestroyed = function( self )
        self:F("IN FUNCTION")
        self:Respawn()
      end
    else
      self.onenterDestroyed = nil
    end
      
  end

end -- CARGO_GROUP

do -- CARGO_PACKAGE

  --- @type CARGO_PACKAGE
  -- @extends #CARGO_REPRESENTABLE
  CARGO_PACKAGE = {
    ClassName = "CARGO_PACKAGE"
  }

--- CARGO_PACKAGE Constructor.
-- @param #CARGO_PACKAGE self
-- @param Wrapper.Unit#UNIT CargoCarrier The UNIT carrying the package.
-- @param #string Type
-- @param #string Name
-- @param #number Weight
-- @param #number ReportRadius (optional)
-- @param #number NearRadius (optional)
-- @return #CARGO_PACKAGE
function CARGO_PACKAGE:New( CargoCarrier, Type, Name, Weight, ReportRadius, NearRadius )
  local self = BASE:Inherit( self, CARGO_REPRESENTABLE:New( CargoCarrier, Type, Name, Weight, ReportRadius, NearRadius ) ) -- #CARGO_PACKAGE
  self:F( { Type, Name, Weight, ReportRadius, NearRadius } )

  self:T( CargoCarrier )
  self.CargoCarrier = CargoCarrier

  return self
end

--- Board Event.
-- @param #CARGO_PACKAGE self
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Wrapper.Unit#UNIT CargoCarrier
-- @param #number Speed
-- @param #number BoardDistance
-- @param #number Angle
function CARGO_PACKAGE:onafterOnBoard( From, Event, To, CargoCarrier, Speed, BoardDistance, LoadDistance, Angle )
  self:F()

  self.CargoInAir = self.CargoCarrier:InAir()

  self:T( self.CargoInAir )

  -- Only move the CargoCarrier to the New CargoCarrier when the New CargoCarrier is not in the air.
  if not self.CargoInAir then

    local Points = {}

    local StartPointVec2 = self.CargoCarrier:GetPointVec2()
    local CargoCarrierHeading = CargoCarrier:GetHeading() -- Get Heading of object in degrees.
    local CargoDeployHeading = ( ( CargoCarrierHeading + Angle ) >= 360 ) and ( CargoCarrierHeading + Angle - 360 ) or ( CargoCarrierHeading + Angle )
    self:T( { CargoCarrierHeading, CargoDeployHeading } )
    local CargoDeployPointVec2 = CargoCarrier:GetPointVec2():Translate( BoardDistance, CargoDeployHeading )

    Points[#Points+1] = StartPointVec2:WaypointGround( Speed )
    Points[#Points+1] = CargoDeployPointVec2:WaypointGround( Speed )

    local TaskRoute = self.CargoCarrier:TaskRoute( Points )
    self.CargoCarrier:SetTask( TaskRoute, 1 )
  end

  self:Boarded( CargoCarrier, Speed, BoardDistance, LoadDistance, Angle )

end

--- Check if CargoCarrier is near the Cargo to be Loaded.
-- @param #CARGO_PACKAGE self
-- @param Wrapper.Unit#UNIT CargoCarrier
-- @return #boolean
function CARGO_PACKAGE:IsNear( CargoCarrier )
  self:F()

  local CargoCarrierPoint = CargoCarrier:GetPointVec2()
  
  local Distance = CargoCarrierPoint:DistanceFromPointVec2( self.CargoCarrier:GetPointVec2() )
  self:T( Distance )
  
  if Distance <= self.NearRadius then
    return true
  else
    return false
  end
end

--- Boarded Event.
-- @param #CARGO_PACKAGE self
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Wrapper.Unit#UNIT CargoCarrier
function CARGO_PACKAGE:onafterOnBoarded( From, Event, To, CargoCarrier, Speed, BoardDistance, LoadDistance, Angle )
  self:F()

  if self:IsNear( CargoCarrier ) then
    self:__Load( 1, CargoCarrier, Speed, LoadDistance, Angle )
  else
    self:__Boarded( 1, CargoCarrier, Speed, BoardDistance, LoadDistance, Angle )
  end
end

--- UnBoard Event.
-- @param #CARGO_PACKAGE self
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param #number Speed
-- @param #number UnLoadDistance
-- @param #number UnBoardDistance
-- @param #number Radius
-- @param #number Angle
function CARGO_PACKAGE:onafterUnBoard( From, Event, To, CargoCarrier, Speed, UnLoadDistance, UnBoardDistance, Radius, Angle )
  self:F()

  self.CargoInAir = self.CargoCarrier:InAir()

  self:T( self.CargoInAir )

  -- Only unboard the cargo when the carrier is not in the air.
  -- (eg. cargo can be on a oil derrick, moving the cargo on the oil derrick will drop the cargo on the sea).
  if not self.CargoInAir then

    self:_Next( self.FsmP.UnLoad, UnLoadDistance, Angle )
  
    local Points = {}

    local StartPointVec2 = CargoCarrier:GetPointVec2()
    local CargoCarrierHeading = self.CargoCarrier:GetHeading() -- Get Heading of object in degrees.
    local CargoDeployHeading = ( ( CargoCarrierHeading + Angle ) >= 360 ) and ( CargoCarrierHeading + Angle - 360 ) or ( CargoCarrierHeading + Angle )
    self:T( { CargoCarrierHeading, CargoDeployHeading } )
    local CargoDeployPointVec2 = StartPointVec2:Translate( UnBoardDistance, CargoDeployHeading )

    Points[#Points+1] = StartPointVec2:WaypointGround( Speed )
    Points[#Points+1] = CargoDeployPointVec2:WaypointGround( Speed )

    local TaskRoute = CargoCarrier:TaskRoute( Points )
    CargoCarrier:SetTask( TaskRoute, 1 )
  end

  self:__UnBoarded( 1 , CargoCarrier, Speed )

end

--- UnBoarded Event.
-- @param #CARGO_PACKAGE self
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Wrapper.Unit#UNIT CargoCarrier
function CARGO_PACKAGE:onafterUnBoarded( From, Event, To, CargoCarrier, Speed )
  self:F()

  if self:IsNear( CargoCarrier ) then
    self:__UnLoad( 1, CargoCarrier, Speed )
  else
    self:__UnBoarded( 1, CargoCarrier, Speed )
  end
end

--- Load Event.
-- @param #CARGO_PACKAGE self
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Wrapper.Unit#UNIT CargoCarrier
-- @param #number Speed
-- @param #number LoadDistance
-- @param #number Angle
function CARGO_PACKAGE:onafterLoad( From, Event, To, CargoCarrier, Speed, LoadDistance, Angle )
  self:F()

  self.CargoCarrier = CargoCarrier

  local StartPointVec2 = self.CargoCarrier:GetPointVec2()
  local CargoCarrierHeading = self.CargoCarrier:GetHeading() -- Get Heading of object in degrees.
  local CargoDeployHeading = ( ( CargoCarrierHeading + Angle ) >= 360 ) and ( CargoCarrierHeading + Angle - 360 ) or ( CargoCarrierHeading + Angle )
  local CargoDeployPointVec2 = StartPointVec2:Translate( LoadDistance, CargoDeployHeading )
  
  local Points = {}
  Points[#Points+1] = StartPointVec2:WaypointGround( Speed )
  Points[#Points+1] = CargoDeployPointVec2:WaypointGround( Speed )

  local TaskRoute = self.CargoCarrier:TaskRoute( Points )
  self.CargoCarrier:SetTask( TaskRoute, 1 )

end

--- UnLoad Event.
-- @param #CARGO_PACKAGE self
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param #number Distance
-- @param #number Angle
function CARGO_PACKAGE:onafterUnLoad( From, Event, To, CargoCarrier, Speed, Distance, Angle )
  self:F()
  
  local StartPointVec2 = self.CargoCarrier:GetPointVec2()
  local CargoCarrierHeading = self.CargoCarrier:GetHeading() -- Get Heading of object in degrees.
  local CargoDeployHeading = ( ( CargoCarrierHeading + Angle ) >= 360 ) and ( CargoCarrierHeading + Angle - 360 ) or ( CargoCarrierHeading + Angle )
  local CargoDeployPointVec2 = StartPointVec2:Translate( Distance, CargoDeployHeading )
  
  self.CargoCarrier = CargoCarrier

  local Points = {}
  Points[#Points+1] = StartPointVec2:WaypointGround( Speed )
  Points[#Points+1] = CargoDeployPointVec2:WaypointGround( Speed )

  local TaskRoute = self.CargoCarrier:TaskRoute( Points )
  self.CargoCarrier:SetTask( TaskRoute, 1 )

end


end
