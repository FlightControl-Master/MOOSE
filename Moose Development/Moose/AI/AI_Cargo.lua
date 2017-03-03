---Single-Player:**Yes** / Multi-Player:**Yes** / AI:**Yes** / Human:**No** / Types:**Ground** --  
-- **Management of logical cargo objects, that can be transported from and to transportation carriers.**
--
-- ![Banner Image](..\Presentations\AI_CARGO\CARGO.JPG)
--
-- ===
-- 
-- Cargo can be of various forms, always are composed out of ONE object ( one unit or one static or one slingload crate ):
--
--   * AI_CARGO_UNIT, represented by a @{Unit} in a @{Group}: Cargo can be represented by a Unit in a Group. Destruction of the Unit will mean that the cargo is lost.
--   * CARGO_STATIC, represented by a @{Static}: Cargo can be represented by a Static. Destruction of the Static will mean that the cargo is lost.
--   * AI_CARGO_PACKAGE, contained in a @{Unit} of a @{Group}: Cargo can be contained within a Unit of a Group. The cargo can be **delivered** by the @{Unit}. If the Unit is destroyed, the cargo will be destroyed also.
--   * AI_CARGO_PACKAGE, Contained in a @{Static}: Cargo can be contained within a Static. The cargo can be **collected** from the @Static. If the @{Static} is destroyed, the cargo will be destroyed.
--   * CARGO_SLINGLOAD, represented by a @{Cargo} that is transportable: Cargo can be represented by a Cargo object that is transportable. Destruction of the Cargo will mean that the cargo is lost.
--   
--   * AI_CARGO_GROUPED, represented by a Group of CARGO_UNITs.
-- 
-- # 1) @{#AI_CARGO} class, extends @{Fsm#FSM_PROCESS}
-- 
-- The @{#AI_CARGO} class defines the core functions that defines a cargo object within MOOSE.
-- A cargo is a logical object defined that is available for transport, and has a life status within a simulation.
--
-- The AI_CARGO is a state machine: it manages the different events and states of the cargo.
-- All derived classes from AI_CARGO follow the same state machine, expose the same cargo event functions, and provide the same cargo states.
-- 
-- ## 1.2.1) AI_CARGO Events:
-- 
--   * @{#AI_CARGO.Board}( ToCarrier ):  Boards the cargo to a carrier.
--   * @{#AI_CARGO.Load}( ToCarrier ): Loads the cargo into a carrier, regardless of its position.
--   * @{#AI_CARGO.UnBoard}( ToPointVec2 ): UnBoard the cargo from a carrier. This will trigger a movement of the cargo to the option ToPointVec2.
--   * @{#AI_CARGO.UnLoad}( ToPointVec2 ): UnLoads the cargo from a carrier.
--   * @{#AI_CARGO.Dead}( Controllable ): The cargo is dead. The cargo process will be ended.
-- 
-- ## 1.2.2) AI_CARGO States:
-- 
--   * **UnLoaded**: The cargo is unloaded from a carrier.
--   * **Boarding**: The cargo is currently boarding (= running) into a carrier.
--   * **Loaded**: The cargo is loaded into a carrier.
--   * **UnBoarding**: The cargo is currently unboarding (=running) from a carrier.
--   * **Dead**: The cargo is dead ...
--   * **End**: The process has come to an end.
--   
-- ## 1.2.3) AI_CARGO state transition methods:
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
-- # 2) #AI_CARGO_UNIT class
-- 
-- The AI_CARGO_UNIT class defines a cargo that is represented by a UNIT object within the simulator, and can be transported by a carrier.
-- Use the event functions as described above to Load, UnLoad, Board, UnBoard the AI_CARGO_UNIT objects to and from carriers.
-- 
-- # 5) #AI_CARGO_GROUPED class
--
-- The AI_CARGO_GROUPED class defines a cargo that is represented by a group of UNIT objects within the simulator, and can be transported by a carrier.
-- Use the event functions as described above to Load, UnLoad, Board, UnBoard the AI_CARGO_UNIT objects to and from carriers.
-- 
-- This module is still under construction, but is described above works already, and will keep working ...
-- 
-- @module Cargo

-- Events

-- Board

--- Boards the cargo to a Carrier. The event will create a movement (= running or driving) of the cargo to the Carrier.
-- The cargo must be in the **UnLoaded** state.
-- @function [parent=#AI_CARGO] Board
-- @param #AI_CARGO self
-- @param Wrapper.Controllable#CONTROLLABLE ToCarrier The Carrier that will hold the cargo.

--- Boards the cargo to a Carrier. The event will create a movement (= running or driving) of the cargo to the Carrier.
-- The cargo must be in the **UnLoaded** state.
-- @function [parent=#AI_CARGO] __Board
-- @param #AI_CARGO self
-- @param #number DelaySeconds The amount of seconds to delay the action.
-- @param Wrapper.Controllable#CONTROLLABLE ToCarrier The Carrier that will hold the cargo.


-- UnBoard

--- UnBoards the cargo to a Carrier. The event will create a movement (= running or driving) of the cargo from the Carrier.
-- The cargo must be in the **Loaded** state.
-- @function [parent=#AI_CARGO] UnBoard
-- @param #AI_CARGO self
-- @param Core.Point#POINT_VEC2 ToPointVec2 (optional) @{Point#POINT_VEC2) to where the cargo should run after onboarding. If not provided, the cargo will run to 60 meters behind the Carrier location.

--- UnBoards the cargo to a Carrier. The event will create a movement (= running or driving) of the cargo from the Carrier.
-- The cargo must be in the **Loaded** state.
-- @function [parent=#AI_CARGO] __UnBoard
-- @param #AI_CARGO self
-- @param #number DelaySeconds The amount of seconds to delay the action.
-- @param Core.Point#POINT_VEC2 ToPointVec2 (optional) @{Point#POINT_VEC2) to where the cargo should run after onboarding. If not provided, the cargo will run to 60 meters behind the Carrier location.


-- Load

--- Loads the cargo to a Carrier. The event will load the cargo into the Carrier regardless of its position. There will be no movement simulated of the cargo loading.
-- The cargo must be in the **UnLoaded** state.
-- @function [parent=#AI_CARGO] Load
-- @param #AI_CARGO self
-- @param Wrapper.Controllable#CONTROLLABLE ToCarrier The Carrier that will hold the cargo.

--- Loads the cargo to a Carrier. The event will load the cargo into the Carrier regardless of its position. There will be no movement simulated of the cargo loading.
-- The cargo must be in the **UnLoaded** state.
-- @function [parent=#AI_CARGO] __Load
-- @param #AI_CARGO self
-- @param #number DelaySeconds The amount of seconds to delay the action.
-- @param Wrapper.Controllable#CONTROLLABLE ToCarrier The Carrier that will hold the cargo.


-- UnLoad

--- UnLoads the cargo to a Carrier. The event will unload the cargo from the Carrier. There will be no movement simulated of the cargo loading.
-- The cargo must be in the **Loaded** state.
-- @function [parent=#AI_CARGO] UnLoad
-- @param #AI_CARGO self
-- @param Core.Point#POINT_VEC2 ToPointVec2 (optional) @{Point#POINT_VEC2) to where the cargo will be placed after unloading. If not provided, the cargo will be placed 60 meters behind the Carrier location.

--- UnLoads the cargo to a Carrier. The event will unload the cargo from the Carrier. There will be no movement simulated of the cargo loading.
-- The cargo must be in the **Loaded** state.
-- @function [parent=#AI_CARGO] __UnLoad
-- @param #AI_CARGO self
-- @param #number DelaySeconds The amount of seconds to delay the action.
-- @param Core.Point#POINT_VEC2 ToPointVec2 (optional) @{Point#POINT_VEC2) to where the cargo will be placed after unloading. If not provided, the cargo will be placed 60 meters behind the Carrier location.

-- State Transition Functions

-- UnLoaded

--- @function [parent=#AI_CARGO] OnLeaveUnLoaded
-- @param #AI_CARGO self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable
-- @return #boolean

--- @function [parent=#AI_CARGO] OnEnterUnLoaded
-- @param #AI_CARGO self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable

-- Loaded

--- @function [parent=#AI_CARGO] OnLeaveLoaded
-- @param #AI_CARGO self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable
-- @return #boolean

--- @function [parent=#AI_CARGO] OnEnterLoaded
-- @param #AI_CARGO self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable

-- Boarding

--- @function [parent=#AI_CARGO] OnLeaveBoarding
-- @param #AI_CARGO self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable
-- @return #boolean

--- @function [parent=#AI_CARGO] OnEnterBoarding
-- @param #AI_CARGO self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable

-- UnBoarding

--- @function [parent=#AI_CARGO] OnLeaveUnBoarding
-- @param #AI_CARGO self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable
-- @return #boolean

--- @function [parent=#AI_CARGO] OnEnterUnBoarding
-- @param #AI_CARGO self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable


-- TODO: Find all Carrier objects and make the type of the Carriers Wrapper.Unit#UNIT in the documentation.

CARGOS = {}

do -- AI_CARGO

  --- @type AI_CARGO
  -- @extends Core.Fsm#FSM_PROCESS
  -- @field #string Type A string defining the type of the cargo. eg. Engineers, Equipment, Screwdrivers.
  -- @field #string Name A string defining the name of the cargo. The name is the unique identifier of the cargo.
  -- @field #number Weight A number defining the weight of the cargo. The weight is expressed in kg.
  -- @field #number ReportRadius (optional) A number defining the radius in meters when the cargo is signalling or reporting to a Carrier.
  -- @field #number NearRadius (optional) A number defining the radius in meters when the cargo is near to a Carrier, so that it can be loaded.
  -- @field Wrapper.Controllable#CONTROLLABLE CargoObject The alive DCS object representing the cargo. This value can be nil, meaning, that the cargo is not represented anywhere...
  -- @field Wrapper.Controllable#CONTROLLABLE CargoCarrier The alive DCS object carrying the cargo. This value can be nil, meaning, that the cargo is not contained anywhere...
  -- @field #boolean Slingloadable This flag defines if the cargo can be slingloaded.
  -- @field #boolean Moveable This flag defines if the cargo is moveable.
  -- @field #boolean Representable This flag defines if the cargo can be represented by a DCS Unit.
  -- @field #boolean Containable This flag defines if the cargo can be contained within a DCS Unit.
  AI_CARGO = {
    ClassName = "AI_CARGO",
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

--- @type AI_CARGO.CargoObjects
-- @map < #string, Wrapper.Positionable#POSITIONABLE > The alive POSITIONABLE objects representing the the cargo.


--- AI_CARGO Constructor. This class is an abstract class and should not be instantiated.
-- @param #AI_CARGO self
-- @param #string Type
-- @param #string Name
-- @param #number Weight
-- @param #number ReportRadius (optional)
-- @param #number NearRadius (optional)
-- @return #AI_CARGO
function AI_CARGO:New( Type, Name, Weight, ReportRadius, NearRadius )

  local self = BASE:Inherit( self, FSM:New() ) -- Core.Fsm#FSM_CONTROLLABLE
  self:F( { Type, Name, Weight, ReportRadius, NearRadius } )
  
  self:SetStartState( "UnLoaded" )
  self:AddTransition( "UnLoaded", "Board", "Boarding" )
  self:AddTransition( "Boarding", "Boarding", "Boarding" )
  self:AddTransition( "Boarding", "Load", "Loaded" )
  self:AddTransition( "UnLoaded", "Load", "Loaded" )
  self:AddTransition( "Loaded", "UnBoard", "UnBoarding" )
  self:AddTransition( "UnBoarding", "UnBoarding", "UnBoarding" )
  self:AddTransition( "UnBoarding", "UnLoad", "UnLoaded" )
  self:AddTransition( "Loaded", "UnLoad", "UnLoaded" )


  self.Type = Type
  self.Name = Name
  self.Weight = Weight
  self.ReportRadius = ReportRadius
  self.NearRadius = NearRadius
  self.CargoObject = nil
  self.CargoCarrier = nil
  self.Representable = false
  self.Slingloadable = false
  self.Moveable = false
  self.Containable = false


  self.CargoScheduler = SCHEDULER:New()

  CARGOS[self.Name] = self

  return self
end


--- Template method to spawn a new representation of the AI_CARGO in the simulator.
-- @param #AI_CARGO self
-- @return #AI_CARGO
function AI_CARGO:Spawn( PointVec2 )
  self:F()

end


--- Check if CargoCarrier is near the Cargo to be Loaded.
-- @param #AI_CARGO self
-- @param Core.Point#POINT_VEC2 PointVec2
-- @return #boolean
function AI_CARGO:IsNear( PointVec2 )
  self:F( { PointVec2 } )

  local Distance = PointVec2:DistanceFromPointVec2( self.CargoObject:GetPointVec2() )
  self:T( Distance )
  
  if Distance <= self.NearRadius then
    return true
  else
    return false
  end
end

end

do -- AI_CARGO_REPRESENTABLE

  --- @type AI_CARGO_REPRESENTABLE
  -- @extends #AI_CARGO
  AI_CARGO_REPRESENTABLE = {
    ClassName = "AI_CARGO_REPRESENTABLE"
  }

--- AI_CARGO_REPRESENTABLE Constructor.
-- @param #AI_CARGO_REPRESENTABLE self
-- @param Wrapper.Controllable#Controllable CargoObject
-- @param #string Type
-- @param #string Name
-- @param #number Weight
-- @param #number ReportRadius (optional)
-- @param #number NearRadius (optional)
-- @return #AI_CARGO_REPRESENTABLE
function AI_CARGO_REPRESENTABLE:New( CargoObject, Type, Name, Weight, ReportRadius, NearRadius )
  local self = BASE:Inherit( self, AI_CARGO:New( Type, Name, Weight, ReportRadius, NearRadius ) ) -- #AI_CARGO
  self:F( { Type, Name, Weight, ReportRadius, NearRadius } )

  return self
end

--- Route a cargo unit to a PointVec2.
-- @param #AI_CARGO_REPRESENTABLE self
-- @param Core.Point#POINT_VEC2 ToPointVec2
-- @param #number Speed
-- @return #AI_CARGO_REPRESENTABLE
function AI_CARGO_REPRESENTABLE:RouteTo( ToPointVec2, Speed )
  self:F2( ToPointVec2 )

  local Points = {}

  local PointStartVec2 = self.CargoObject:GetPointVec2()

  Points[#Points+1] = PointStartVec2:RoutePointGround( Speed )
  Points[#Points+1] = ToPointVec2:RoutePointGround( Speed )

  local TaskRoute = self.CargoObject:TaskRoute( Points )
  self.CargoObject:SetTask( TaskRoute, 2 )
  return self  
end

end -- AI_CARGO

do -- AI_CARGO_UNIT

  --- @type AI_CARGO_UNIT
  -- @extends #AI_CARGO_REPRESENTABLE
  AI_CARGO_UNIT = {
    ClassName = "AI_CARGO_UNIT"
  }

--- AI_CARGO_UNIT Constructor.
-- @param #AI_CARGO_UNIT self
-- @param Wrapper.Unit#UNIT CargoUnit
-- @param #string Type
-- @param #string Name
-- @param #number Weight
-- @param #number ReportRadius (optional)
-- @param #number NearRadius (optional)
-- @return #AI_CARGO_UNIT
function AI_CARGO_UNIT:New( CargoUnit, Type, Name, Weight, ReportRadius, NearRadius )
  local self = BASE:Inherit( self, AI_CARGO_REPRESENTABLE:New( CargoUnit, Type, Name, Weight, ReportRadius, NearRadius ) ) -- #AI_CARGO_UNIT
  self:F( { Type, Name, Weight, ReportRadius, NearRadius } )

  self:T( CargoUnit )
  self.CargoObject = CargoUnit

  self:T( self.ClassName )

  return self
end

--- Enter UnBoarding State.
-- @param #AI_CARGO_UNIT self
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Core.Point#POINT_VEC2 ToPointVec2
function AI_CARGO_UNIT:onenterUnBoarding( From, Event, To, ToPointVec2 )
  self:F()

  local Angle = 180
  local Speed = 10
  local DeployDistance = 5
  local RouteDistance = 60

  if From == "Loaded" then

    local CargoCarrierPointVec2 = self.CargoCarrier:GetPointVec2()
    local CargoCarrierHeading = self.CargoCarrier:GetHeading() -- Get Heading of object in degrees.
    local CargoDeployHeading = ( ( CargoCarrierHeading + Angle ) >= 360 ) and ( CargoCarrierHeading + Angle - 360 ) or ( CargoCarrierHeading + Angle )
    local CargoDeployPointVec2 = CargoCarrierPointVec2:Translate( DeployDistance, CargoDeployHeading )
    local CargoRoutePointVec2 = CargoCarrierPointVec2:Translate( RouteDistance, CargoDeployHeading )

    -- if there is no ToPointVec2 given, then use the CargoRoutePointVec2
    ToPointVec2 = ToPointVec2 or CargoRoutePointVec2
    
    local FromPointVec2 = CargoCarrierPointVec2

    -- Respawn the group...
    if self.CargoObject then
      self.CargoObject:ReSpawn( CargoDeployPointVec2:GetVec3(), CargoDeployHeading )
      self.CargoCarrier = nil

      local Points = {}
      Points[#Points+1] = FromPointVec2:RoutePointGround( Speed )
      Points[#Points+1] = ToPointVec2:RoutePointGround( Speed  )
  
      local TaskRoute = self.CargoObject:TaskRoute( Points )
      self.CargoObject:SetTask( TaskRoute, 1 )

      self:__UnBoarding( 1, ToPointVec2 )
    end
  end

end

--- Leave UnBoarding State.
-- @param #AI_CARGO_UNIT self
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Core.Point#POINT_VEC2 ToPointVec2
function AI_CARGO_UNIT:onleaveUnBoarding( From, Event, To, ToPointVec2 )
  self:F( { ToPointVec2, From, Event, To } )

  local Angle = 180
  local Speed = 10
  local Distance = 5

  if From == "UnBoarding" then
    if self:IsNear( ToPointVec2 ) then
      return true
    else
      self:__UnBoarding( 1, ToPointVec2 )
    end
    return false
  end

end

--- UnBoard Event.
-- @param #AI_CARGO_UNIT self
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Core.Point#POINT_VEC2 ToPointVec2
function AI_CARGO_UNIT:onafterUnBoarding( From, Event, To, ToPointVec2 )
  self:F( { ToPointVec2, From, Event, To } )

  self.CargoInAir = self.CargoObject:InAir()

  self:T( self.CargoInAir )

  -- Only unboard the cargo when the carrier is not in the air.
  -- (eg. cargo can be on a oil derrick, moving the cargo on the oil derrick will drop the cargo on the sea).
  if not self.CargoInAir then

  end

  self:__UnLoad( 1, ToPointVec2 )

end



--- Enter UnLoaded State.
-- @param #AI_CARGO_UNIT self
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Core.Point#POINT_VEC2
function AI_CARGO_UNIT:onenterUnLoaded( From, Event, To, ToPointVec2  )
  self:F( { ToPointVec2, From, Event, To } )

  local Angle = 180
  local Speed = 10
  local Distance = 5

  if From == "Loaded" then
    local StartPointVec2 = self.CargoCarrier:GetPointVec2()
    local CargoCarrierHeading = self.CargoCarrier:GetHeading() -- Get Heading of object in degrees.
    local CargoDeployHeading = ( ( CargoCarrierHeading + Angle ) >= 360 ) and ( CargoCarrierHeading + Angle - 360 ) or ( CargoCarrierHeading + Angle )
    local CargoDeployPointVec2 = StartPointVec2:Translate( Distance, CargoDeployHeading )

    ToPointVec2 = ToPointVec2 or POINT_VEC2:New( CargoDeployPointVec2:GetX(), CargoDeployPointVec2:GetY() )

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



--- Enter Boarding State.
-- @param #AI_CARGO_UNIT self
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Wrapper.Unit#UNIT CargoCarrier
function AI_CARGO_UNIT:onenterBoarding( From, Event, To, CargoCarrier )
  self:F( { CargoCarrier.UnitName, From, Event, To } )
  
  local Speed = 10
  local Angle = 180
  local Distance = 5

  if From == "UnLoaded" then
    local CargoCarrierPointVec2 = CargoCarrier:GetPointVec2()
    local CargoCarrierHeading = CargoCarrier:GetHeading() -- Get Heading of object in degrees.
    local CargoDeployHeading = ( ( CargoCarrierHeading + Angle ) >= 360 ) and ( CargoCarrierHeading + Angle - 360 ) or ( CargoCarrierHeading + Angle )
    local CargoDeployPointVec2 = CargoCarrierPointVec2:Translate( Distance, CargoDeployHeading )

    local Points = {}

    local PointStartVec2 = self.CargoObject:GetPointVec2()

    Points[#Points+1] = PointStartVec2:RoutePointGround( Speed )
    Points[#Points+1] = CargoDeployPointVec2:RoutePointGround( Speed )

    local TaskRoute = self.CargoObject:TaskRoute( Points )
    self.CargoObject:SetTask( TaskRoute, 2 )
  end
  
end

--- Leave Boarding State.
-- @param #AI_CARGO_UNIT self
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Wrapper.Unit#UNIT CargoCarrier
function AI_CARGO_UNIT:onleaveBoarding( From, Event, To, CargoCarrier )
  self:F( { CargoCarrier.UnitName, From, Event, To } )

  if self:IsNear( CargoCarrier:GetPointVec2() ) then
    self:__Load( 1, CargoCarrier )
    return true
  else
    self:__Boarding( 1, CargoCarrier )
  end
  return false
end

--- Loaded State.
-- @param #AI_CARGO_UNIT self
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Wrapper.Unit#UNIT CargoCarrier
function AI_CARGO_UNIT:onenterLoaded( From, Event, To, CargoCarrier )
  self:F()

  self.CargoCarrier = CargoCarrier
  
  -- Only destroy the CargoObject is if there is a CargoObject (packages don't have CargoObjects).
  if self.CargoObject then
    self:T("Destroying")
    self.CargoObject:Destroy()
  end
end


--- Board Event.
-- @param #AI_CARGO_UNIT self
-- @param #string Event
-- @param #string From
-- @param #string To
function AI_CARGO_UNIT:onafterBoard( From, Event, To, CargoCarrier )
  self:F()

  self.CargoInAir = self.CargoObject:InAir()

  self:T( self.CargoInAir )

  -- Only move the group to the carrier when the cargo is not in the air
  -- (eg. cargo can be on a oil derrick, moving the cargo on the oil derrick will drop the cargo on the sea).
  if not self.CargoInAir then
    self:Load( CargoCarrier )
  end

end

end

do -- AI_CARGO_PACKAGE

  --- @type AI_CARGO_PACKAGE
  -- @extends #AI_CARGO_REPRESENTABLE
  AI_CARGO_PACKAGE = {
    ClassName = "AI_CARGO_PACKAGE"
  }

--- AI_CARGO_PACKAGE Constructor.
-- @param #AI_CARGO_PACKAGE self
-- @param Wrapper.Unit#UNIT CargoCarrier The UNIT carrying the package.
-- @param #string Type
-- @param #string Name
-- @param #number Weight
-- @param #number ReportRadius (optional)
-- @param #number NearRadius (optional)
-- @return #AI_CARGO_PACKAGE
function AI_CARGO_PACKAGE:New( CargoCarrier, Type, Name, Weight, ReportRadius, NearRadius )
  local self = BASE:Inherit( self, AI_CARGO_REPRESENTABLE:New( CargoCarrier, Type, Name, Weight, ReportRadius, NearRadius ) ) -- #AI_CARGO_PACKAGE
  self:F( { Type, Name, Weight, ReportRadius, NearRadius } )

  self:T( CargoCarrier )
  self.CargoCarrier = CargoCarrier

  return self
end

--- Board Event.
-- @param #AI_CARGO_PACKAGE self
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Wrapper.Unit#UNIT CargoCarrier
-- @param #number Speed
-- @param #number BoardDistance
-- @param #number Angle
function AI_CARGO_PACKAGE:onafterOnBoard( From, Event, To, CargoCarrier, Speed, BoardDistance, LoadDistance, Angle )
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

    Points[#Points+1] = StartPointVec2:RoutePointGround( Speed )
    Points[#Points+1] = CargoDeployPointVec2:RoutePointGround( Speed )

    local TaskRoute = self.CargoCarrier:TaskRoute( Points )
    self.CargoCarrier:SetTask( TaskRoute, 1 )
  end

  self:Boarded( CargoCarrier, Speed, BoardDistance, LoadDistance, Angle )

end

--- Check if CargoCarrier is near the Cargo to be Loaded.
-- @param #AI_CARGO_PACKAGE self
-- @param Wrapper.Unit#UNIT CargoCarrier
-- @return #boolean
function AI_CARGO_PACKAGE:IsNear( CargoCarrier )
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
-- @param #AI_CARGO_PACKAGE self
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Wrapper.Unit#UNIT CargoCarrier
function AI_CARGO_PACKAGE:onafterOnBoarded( From, Event, To, CargoCarrier, Speed, BoardDistance, LoadDistance, Angle )
  self:F()

  if self:IsNear( CargoCarrier ) then
    self:__Load( 1, CargoCarrier, Speed, LoadDistance, Angle )
  else
    self:__Boarded( 1, CargoCarrier, Speed, BoardDistance, LoadDistance, Angle )
  end
end

--- UnBoard Event.
-- @param #AI_CARGO_PACKAGE self
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param #number Speed
-- @param #number UnLoadDistance
-- @param #number UnBoardDistance
-- @param #number Radius
-- @param #number Angle
function AI_CARGO_PACKAGE:onafterUnBoard( From, Event, To, CargoCarrier, Speed, UnLoadDistance, UnBoardDistance, Radius, Angle )
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

    Points[#Points+1] = StartPointVec2:RoutePointGround( Speed )
    Points[#Points+1] = CargoDeployPointVec2:RoutePointGround( Speed )

    local TaskRoute = CargoCarrier:TaskRoute( Points )
    CargoCarrier:SetTask( TaskRoute, 1 )
  end

  self:__UnBoarded( 1 , CargoCarrier, Speed )

end

--- UnBoarded Event.
-- @param #AI_CARGO_PACKAGE self
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Wrapper.Unit#UNIT CargoCarrier
function AI_CARGO_PACKAGE:onafterUnBoarded( From, Event, To, CargoCarrier, Speed )
  self:F()

  if self:IsNear( CargoCarrier ) then
    self:__UnLoad( 1, CargoCarrier, Speed )
  else
    self:__UnBoarded( 1, CargoCarrier, Speed )
  end
end

--- Load Event.
-- @param #AI_CARGO_PACKAGE self
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Wrapper.Unit#UNIT CargoCarrier
-- @param #number Speed
-- @param #number LoadDistance
-- @param #number Angle
function AI_CARGO_PACKAGE:onafterLoad( From, Event, To, CargoCarrier, Speed, LoadDistance, Angle )
  self:F()

  self.CargoCarrier = CargoCarrier

  local StartPointVec2 = self.CargoCarrier:GetPointVec2()
  local CargoCarrierHeading = self.CargoCarrier:GetHeading() -- Get Heading of object in degrees.
  local CargoDeployHeading = ( ( CargoCarrierHeading + Angle ) >= 360 ) and ( CargoCarrierHeading + Angle - 360 ) or ( CargoCarrierHeading + Angle )
  local CargoDeployPointVec2 = StartPointVec2:Translate( LoadDistance, CargoDeployHeading )
  
  local Points = {}
  Points[#Points+1] = StartPointVec2:RoutePointGround( Speed )
  Points[#Points+1] = CargoDeployPointVec2:RoutePointGround( Speed )

  local TaskRoute = self.CargoCarrier:TaskRoute( Points )
  self.CargoCarrier:SetTask( TaskRoute, 1 )

end

--- UnLoad Event.
-- @param #AI_CARGO_PACKAGE self
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param #number Distance
-- @param #number Angle
function AI_CARGO_PACKAGE:onafterUnLoad( From, Event, To, CargoCarrier, Speed, Distance, Angle )
  self:F()
  
  local StartPointVec2 = self.CargoCarrier:GetPointVec2()
  local CargoCarrierHeading = self.CargoCarrier:GetHeading() -- Get Heading of object in degrees.
  local CargoDeployHeading = ( ( CargoCarrierHeading + Angle ) >= 360 ) and ( CargoCarrierHeading + Angle - 360 ) or ( CargoCarrierHeading + Angle )
  local CargoDeployPointVec2 = StartPointVec2:Translate( Distance, CargoDeployHeading )
  
  self.CargoCarrier = CargoCarrier

  local Points = {}
  Points[#Points+1] = StartPointVec2:RoutePointGround( Speed )
  Points[#Points+1] = CargoDeployPointVec2:RoutePointGround( Speed )

  local TaskRoute = self.CargoCarrier:TaskRoute( Points )
  self.CargoCarrier:SetTask( TaskRoute, 1 )

end


end

do -- AI_CARGO_GROUP

  --- @type AI_CARGO_GROUP
  -- @extends AI.AI_Cargo#AI_CARGO
  -- @field Set#SET_BASE CargoSet A set of cargo objects.
  -- @field #string Name A string defining the name of the cargo group. The name is the unique identifier of the cargo.
  AI_CARGO_GROUP = {
    ClassName = "AI_CARGO_GROUP",
  }

--- AI_CARGO_GROUP constructor.
-- @param #AI_CARGO_GROUP self
-- @param Core.Set#Set_BASE CargoSet
-- @param #string Type
-- @param #string Name
-- @param #number Weight
-- @param #number ReportRadius (optional)
-- @param #number NearRadius (optional)
-- @return #AI_CARGO_GROUP
function AI_CARGO_GROUP:New( CargoSet, Type, Name, ReportRadius, NearRadius )
  local self = BASE:Inherit( self, AI_CARGO:New( Type, Name, 0, ReportRadius, NearRadius ) ) -- #AI_CARGO_GROUP
  self:F( { Type, Name, ReportRadius, NearRadius } )

  self.CargoSet = CargoSet


  return self
end

end -- AI_CARGO_GROUP

do -- AI_CARGO_GROUPED

  --- @type AI_CARGO_GROUPED
  -- @extends AI.AI_Cargo#AI_CARGO_GROUP
  AI_CARGO_GROUPED = {
    ClassName = "AI_CARGO_GROUPED",
  }

--- AI_CARGO_GROUPED constructor.
-- @param #AI_CARGO_GROUPED self
-- @param Core.Set#Set_BASE CargoSet
-- @param #string Type
-- @param #string Name
-- @param #number Weight
-- @param #number ReportRadius (optional)
-- @param #number NearRadius (optional)
-- @return #AI_CARGO_GROUPED
function AI_CARGO_GROUPED:New( CargoSet, Type, Name, ReportRadius, NearRadius )
  local self = BASE:Inherit( self, AI_CARGO_GROUP:New( CargoSet, Type, Name, ReportRadius, NearRadius ) ) -- #AI_CARGO_GROUPED
  self:F( { Type, Name, ReportRadius, NearRadius } )

  return self
end

--- Enter Boarding State.
-- @param #AI_CARGO_GROUPED self
-- @param Wrapper.Unit#UNIT CargoCarrier
-- @param #string Event
-- @param #string From
-- @param #string To
function AI_CARGO_GROUPED:onenterBoarding( From, Event, To, CargoCarrier )
  self:F( { CargoCarrier.UnitName, From, Event, To } )
  
  if From == "UnLoaded" then

    -- For each Cargo object within the AI_CARGO_GROUPED, route each object to the CargoLoadPointVec2
    self.CargoSet:ForEach(
      function( Cargo )
        Cargo:__Board( 1, CargoCarrier )
      end
    )
    
    self:__Boarding( 1, CargoCarrier )
  end
  
end

--- Enter Loaded State.
-- @param #AI_CARGO_GROUPED self
-- @param Wrapper.Unit#UNIT CargoCarrier
-- @param #string Event
-- @param #string From
-- @param #string To
function AI_CARGO_GROUPED:onenterLoaded( From, Event, To, CargoCarrier )
  self:F( { CargoCarrier.UnitName, From, Event, To } )
  
  if From == "UnLoaded" then
    -- For each Cargo object within the AI_CARGO_GROUPED, load each cargo to the CargoCarrier.
    for CargoID, Cargo in pairs( self.CargoSet:GetSet() ) do
      Cargo:Load( CargoCarrier )
    end
  end
end

--- Leave Boarding State.
-- @param #AI_CARGO_GROUPED self
-- @param Wrapper.Unit#UNIT CargoCarrier
-- @param #string Event
-- @param #string From
-- @param #string To
function AI_CARGO_GROUPED:onleaveBoarding( From, Event, To, CargoCarrier )
  self:F( { CargoCarrier.UnitName, From, Event, To } )

  local Boarded = true

  -- For each Cargo object within the AI_CARGO_GROUPED, route each object to the CargoLoadPointVec2
  for CargoID, Cargo in pairs( self.CargoSet:GetSet() ) do
    self:T( Cargo.current )
    if not Cargo:is( "Loaded" ) then
      Boarded = false
    end
  end

  if not Boarded then
    self:__Boarding( 1, CargoCarrier )
  else
    self:__Load( 1, CargoCarrier )
  end
  return Boarded
end

--- Enter UnBoarding State.
-- @param #AI_CARGO_GROUPED self
-- @param Core.Point#POINT_VEC2 ToPointVec2
-- @param #string Event
-- @param #string From
-- @param #string To
function AI_CARGO_GROUPED:onenterUnBoarding( From, Event, To, ToPointVec2 )
  self:F()

  local Timer = 1

  if From == "Loaded" then

    -- For each Cargo object within the AI_CARGO_GROUPED, route each object to the CargoLoadPointVec2
    self.CargoSet:ForEach(
      function( Cargo )
        Cargo:__UnBoard( Timer, ToPointVec2 )
        Timer = Timer + 10
      end
    )
    
    self:__UnBoarding( 1, ToPointVec2 )
  end

end

--- Leave UnBoarding State.
-- @param #AI_CARGO_GROUPED self
-- @param Core.Point#POINT_VEC2 ToPointVec2
-- @param #string Event
-- @param #string From
-- @param #string To
function AI_CARGO_GROUPED:onleaveUnBoarding( From, Event, To, ToPointVec2 )
  self:F( { ToPointVec2, From, Event, To } )

  local Angle = 180
  local Speed = 10
  local Distance = 5

  if From == "UnBoarding" then
    local UnBoarded = true

    -- For each Cargo object within the AI_CARGO_GROUPED, route each object to the CargoLoadPointVec2
    for CargoID, Cargo in pairs( self.CargoSet:GetSet() ) do
      self:T( Cargo.current )
      if not Cargo:is( "UnLoaded" ) then
        UnBoarded = false
      end
    end
  
    if UnBoarded then
      return true
    else
      self:__UnBoarding( 1, ToPointVec2 )
    end
    
    return false
  end
  
end

--- UnBoard Event.
-- @param #AI_CARGO_GROUPED self
-- @param Core.Point#POINT_VEC2 ToPointVec2
-- @param #string Event
-- @param #string From
-- @param #string To
function AI_CARGO_GROUPED:onafterUnBoarding( From, Event, To, ToPointVec2 )
  self:F( { ToPointVec2, From, Event, To } )

  self:__UnLoad( 1, ToPointVec2 )
end



--- Enter UnLoaded State.
-- @param #AI_CARGO_GROUPED self
-- @param Core.Point#POINT_VEC2
-- @param #string Event
-- @param #string From
-- @param #string To
function AI_CARGO_GROUPED:onenterUnLoaded( From, Event, To, ToPointVec2 )
  self:F( { ToPointVec2, From, Event, To } )

  if From == "Loaded" then
    
    -- For each Cargo object within the AI_CARGO_GROUPED, route each object to the CargoLoadPointVec2
    self.CargoSet:ForEach(
      function( Cargo )
        Cargo:UnLoad( ToPointVec2 )
      end
    )

  end

end

end -- AI_CARGO_GROUPED



