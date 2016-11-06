--- Management of logical cargo objects, that can be transported from and to transportation carriers.
--
-- ===
-- 
-- Cargo can be of various forms, always are composed out of ONE object ( one unit or one static or one slingload crate ):
--
--   * CARGO_UNIT, represented by a @{Unit} in a @{Group}: Cargo can be represented by a Unit in a Group. Destruction of the Unit will mean that the cargo is lost.
--   * CARGO_STATIC, represented by a @{Static}: Cargo can be represented by a Static. Destruction of the Static will mean that the cargo is lost.
--   * CARGO_PACKAGE, contained in a @{Unit} of a @{Group}: Cargo can be contained within a Unit of a Group. The cargo can be **delivered** by the @{Unit}. If the Unit is destroyed, the cargo will be destroyed also.
--   * CARGO_PACKAGE, Contained in a @{Static}: Cargo can be contained within a Static. The cargo can be **collected** from the @Static. If the @{Static} is destroyed, the cargo will be destroyed.
--   * CARGO_SLINGLOAD, represented by a @{Cargo} that is transportable: Cargo can be represented by a Cargo object that is transportable. Destruction of the Cargo will mean that the cargo is lost.
--   
--   * CARGO_GROUPED, represented by a Group of CARGO_UNITs.
-- 
-- 1) @{Cargo#CARGO_BASE} class, extends @{StateMachine#STATEMACHINE_PROCESS}
-- ==========================================================================
-- The @{#CARGO_BASE} class defines the core functions that defines a cargo object within MOOSE.
-- A cargo is a logical object defined that is available for transport, and has a life status within a simulation.
--
-- The CARGO_BASE is a state machine: it manages the different events and states of the cargo.
-- All derived classes from CARGO_BASE follow the same state machine, expose the same cargo event functions, and provide the same cargo states.
-- 
-- ## 1.2.1) CARGO_BASE Events:
-- 
--   * @{#CARGO_BASE.Board}( ToCarrier ):  Boards the cargo to a carrier.
--   * @{#CARGO_BASE.Load}( ToCarrier ): Loads the cargo into a carrier, regardless of its position.
--   * @{#CARGO_BASE.UnBoard}( ToPointVec2 ): UnBoard the cargo from a carrier. This will trigger a movement of the cargo to the option ToPointVec2.
--   * @{#CARGO_BASE.UnLoad}( ToPointVec2 ): UnLoads the cargo from a carrier.
--   * @{#CARGO_BASE.Dead}( Controllable ): The cargo is dead. The cargo process will be ended.
-- 
-- ## 1.2.2) CARGO_BASE States:
-- 
--   * **UnLoaded**: The cargo is unloaded from a carrier.
--   * **Boarding**: The cargo is currently boarding (= running) into a carrier.
--   * **Loaded**: The cargo is loaded into a carrier.
--   * **UnBoarding**: The cargo is currently unboarding (=running) from a carrier.
--   * **Dead**: The cargo is dead ...
--   * **End**: The process has come to an end.
--   
-- ## 1.2.3) CARGO_BASE state transition methods:
-- 
-- State transition functions can be set **by the mission designer** customizing or improving the behaviour of the state.
-- There are 2 moments when state transition methods will be called by the state machine:
-- 
--   * **Before** the state transition. 
--     The state transition method needs to start with the name **OnBefore + the name of the state**. 
--     If the state transition method returns false, then the processing of the state transition will not be done!
--     If you want to change the behaviour of the AIControllable at this event, return false, 
--     but then you'll need to specify your own logic using the AIControllable!
--   
--   * **After** the state transition. 
--     The state transition method needs to start with the name **OnAfter + the name of the state**. 
--     These state transition methods need to provide a return value, which is specified at the function description.
-- 
-- 2) #CARGO_UNIT class
-- ====================
-- The CARGO_UNIT class defines a cargo that is represented by a UNIT object within the simulator, and can be transported by a carrier.
-- Use the event functions as described above to Load, UnLoad, Board, UnBoard the CARGO_UNIT objects to and from carriers.
-- 
-- 5) #CARGO_GROUPED class
-- =======================
-- The CARGO_GROUPED class defines a cargo that is represented by a group of UNIT objects within the simulator, and can be transported by a carrier.
-- Use the event functions as described above to Load, UnLoad, Board, UnBoard the CARGO_UNIT objects to and from carriers.
-- 
-- This module is still under construction, but is described above works already, and will keep working ...
-- 
-- @module Cargo

-- Events

-- Board

--- Boards the cargo to a Carrier. The event will create a movement (= running or driving) of the cargo to the Carrier.
-- The cargo must be in the **UnLoaded** state.
-- @function [parent=#CARGO_BASE] Board
-- @param #CARGO_BASE self
-- @param Controllable#CONTROLLABLE ToCarrier The Carrier that will hold the cargo.

--- Boards the cargo to a Carrier. The event will create a movement (= running or driving) of the cargo to the Carrier.
-- The cargo must be in the **UnLoaded** state.
-- @function [parent=#CARGO_BASE] __Board
-- @param #CARGO_BASE self
-- @param #number DelaySeconds The amount of seconds to delay the action.
-- @param Controllable#CONTROLLABLE ToCarrier The Carrier that will hold the cargo.


-- UnBoard

--- UnBoards the cargo to a Carrier. The event will create a movement (= running or driving) of the cargo from the Carrier.
-- The cargo must be in the **Loaded** state.
-- @function [parent=#CARGO_BASE] UnBoard
-- @param #CARGO_BASE self
-- @param Point#POINT_VEC2 ToPointVec2 (optional) @{Point#POINT_VEC2) to where the cargo should run after onboarding. If not provided, the cargo will run to 60 meters behind the Carrier location.

--- UnBoards the cargo to a Carrier. The event will create a movement (= running or driving) of the cargo from the Carrier.
-- The cargo must be in the **Loaded** state.
-- @function [parent=#CARGO_BASE] __UnBoard
-- @param #CARGO_BASE self
-- @param #number DelaySeconds The amount of seconds to delay the action.
-- @param Point#POINT_VEC2 ToPointVec2 (optional) @{Point#POINT_VEC2) to where the cargo should run after onboarding. If not provided, the cargo will run to 60 meters behind the Carrier location.


-- Load

--- Loads the cargo to a Carrier. The event will load the cargo into the Carrier regardless of its position. There will be no movement simulated of the cargo loading.
-- The cargo must be in the **UnLoaded** state.
-- @function [parent=#CARGO_BASE] Load
-- @param #CARGO_BASE self
-- @param Controllable#CONTROLLABLE ToCarrier The Carrier that will hold the cargo.

--- Loads the cargo to a Carrier. The event will load the cargo into the Carrier regardless of its position. There will be no movement simulated of the cargo loading.
-- The cargo must be in the **UnLoaded** state.
-- @function [parent=#CARGO_BASE] __Load
-- @param #CARGO_BASE self
-- @param #number DelaySeconds The amount of seconds to delay the action.
-- @param Controllable#CONTROLLABLE ToCarrier The Carrier that will hold the cargo.


-- UnLoad

--- UnLoads the cargo to a Carrier. The event will unload the cargo from the Carrier. There will be no movement simulated of the cargo loading.
-- The cargo must be in the **Loaded** state.
-- @function [parent=#CARGO_BASE] UnLoad
-- @param #CARGO_BASE self
-- @param Point#POINT_VEC2 ToPointVec2 (optional) @{Point#POINT_VEC2) to where the cargo will be placed after unloading. If not provided, the cargo will be placed 60 meters behind the Carrier location.

--- UnLoads the cargo to a Carrier. The event will unload the cargo from the Carrier. There will be no movement simulated of the cargo loading.
-- The cargo must be in the **Loaded** state.
-- @function [parent=#CARGO_BASE] __UnLoad
-- @param #CARGO_BASE self
-- @param #number DelaySeconds The amount of seconds to delay the action.
-- @param Point#POINT_VEC2 ToPointVec2 (optional) @{Point#POINT_VEC2) to where the cargo will be placed after unloading. If not provided, the cargo will be placed 60 meters behind the Carrier location.

-- State Transition Functions

-- UnLoaded

--- @function [parent=#CARGO_BASE] OnBeforeUnLoaded
-- @param #CARGO_BASE self
-- @param Controllable#CONTROLLABLE Controllable
-- @return #boolean

--- @function [parent=#CARGO_BASE] OnAfterUnLoaded
-- @param #CARGO_BASE self
-- @param Controllable#CONTROLLABLE Controllable

-- Loaded

--- @function [parent=#CARGO_BASE] OnBeforeLoaded
-- @param #CARGO_BASE self
-- @param Controllable#CONTROLLABLE Controllable
-- @return #boolean

--- @function [parent=#CARGO_BASE] OnAfterLoaded
-- @param #CARGO_BASE self
-- @param Controllable#CONTROLLABLE Controllable

-- Boarding

--- @function [parent=#CARGO_BASE] OnBeforeBoarding
-- @param #CARGO_BASE self
-- @param Controllable#CONTROLLABLE Controllable
-- @return #boolean

--- @function [parent=#CARGO_BASE] OnAfterBoarding
-- @param #CARGO_BASE self
-- @param Controllable#CONTROLLABLE Controllable

-- UnBoarding

--- @function [parent=#CARGO_BASE] OnBeforeUnBoarding
-- @param #CARGO_BASE self
-- @param Controllable#CONTROLLABLE Controllable
-- @return #boolean

--- @function [parent=#CARGO_BASE] OnAfterUnBoarding
-- @param #CARGO_BASE self
-- @param Controllable#CONTROLLABLE Controllable


-- TODO: Find all Carrier objects and make the type of the Carriers Unit#UNIT in the documentation.

CARGOS = {}

do -- CARGO_BASE

  --- @type CARGO_BASE
  -- @extends StateMachine#STATEMACHINE_PROCESS
  -- @field #string Type A string defining the type of the cargo. eg. Engineers, Equipment, Screwdrivers.
  -- @field #string Name A string defining the name of the cargo. The name is the unique identifier of the cargo.
  -- @field #number Weight A number defining the weight of the cargo. The weight is expressed in kg.
  -- @field #number ReportRadius (optional) A number defining the radius in meters when the cargo is signalling or reporting to a Carrier.
  -- @field #number NearRadius (optional) A number defining the radius in meters when the cargo is near to a Carrier, so that it can be loaded.
  -- @field Controllable#CONTROLLABLE CargoObject The alive DCS object representing the cargo. This value can be nil, meaning, that the cargo is not represented anywhere...
  -- @field Controllable#CONTROLLABLE CargoCarrier The alive DCS object carrying the cargo. This value can be nil, meaning, that the cargo is not contained anywhere...
  -- @field #boolean Slingloadable This flag defines if the cargo can be slingloaded.
  -- @field #boolean Moveable This flag defines if the cargo is moveable.
  -- @field #boolean Representable This flag defines if the cargo can be represented by a DCS Unit.
  -- @field #boolean Containable This flag defines if the cargo can be contained within a DCS Unit.
  CARGO_BASE = {
    ClassName = "CARGO_BASE",
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

--- @type CARGO_BASE.CargoObjects
-- @map < #string, Positionable#POSITIONABLE > The alive POSITIONABLE objects representing the the cargo.


--- CARGO_BASE Constructor. This class is an abstract class and should not be instantiated.
-- @param #CARGO_BASE self
-- @param #string Type
-- @param #string Name
-- @param #number Weight
-- @param #number ReportRadius (optional)
-- @param #number NearRadius (optional)
-- @return #CARGO_BASE
function CARGO_BASE:New( Type, Name, Weight, ReportRadius, NearRadius )

  FSMT = {
    initial = 'UnLoaded',
    events = {
      { name = 'Board',       from = 'UnLoaded',        to = 'Boarding' },
      { name = 'Boarding',    from = 'Boarding',        to = 'Boarding' },
      { name = 'Load',        from = 'Boarding',        to = 'Loaded' },
      { name = 'Load',        from = 'UnLoaded',        to = 'Loaded' },
      { name = 'UnBoard',     from = 'Loaded',          to = 'UnBoarding' },
      { name = 'UnBoarding',  from = 'UnBoarding',      to = 'UnBoarding' },
      { name = 'UnLoad',      from = 'UnBoarding',      to = 'UnLoaded' },
      { name = 'UnLoad',      from = 'Loaded',          to = 'UnLoaded' },
    },
  }

  local self = BASE:Inherit( self, STATEMACHINE_PROCESS:New( FSMT ) ) -- #CARGO_BASE
  self:F( { Type, Name, Weight, ReportRadius, NearRadius } )


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


--- Template method to spawn a new representation of the CARGO_BASE in the simulator.
-- @param #CARGO_BASE self
-- @return #CARGO_BASE
function CARGO_BASE:Spawn( PointVec2 )
  self:F()

end


--- Check if CargoCarrier is near the Cargo to be Loaded.
-- @param #CARGO_BASE self
-- @param Point#POINT_VEC2 PointVec2
-- @return #boolean
function CARGO_BASE:IsNear( PointVec2 )
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

do -- CARGO_REPRESENTABLE

  --- @type CARGO_REPRESENTABLE
  -- @extends #CARGO_BASE
  CARGO_REPRESENTABLE = {
    ClassName = "CARGO_REPRESENTABLE"
  }

--- CARGO_REPRESENTABLE Constructor.
-- @param #CARGO_REPRESENTABLE self
-- @param Controllable#Controllable CargoObject
-- @param #string Type
-- @param #string Name
-- @param #number Weight
-- @param #number ReportRadius (optional)
-- @param #number NearRadius (optional)
-- @return #CARGO_REPRESENTABLE
function CARGO_REPRESENTABLE:New( CargoObject, Type, Name, Weight, ReportRadius, NearRadius )
  local self = BASE:Inherit( self, CARGO_BASE:New( Type, Name, Weight, ReportRadius, NearRadius ) ) -- #CARGO_BASE
  self:F( { Type, Name, Weight, ReportRadius, NearRadius } )

  
  

  return self
end

--- Route a cargo unit to a PointVec2.
-- @param #CARGO_REPRESENTABLE self
-- @param Point#POINT_VEC2 ToPointVec2
-- @param #number Speed
-- @return #CARGO_REPRESENTABLE
function CARGO_REPRESENTABLE:RouteTo( ToPointVec2, Speed )
  self:F2( ToPointVec2 )

  local Points = {}

  local PointStartVec2 = self.CargoObject:GetPointVec2()

  Points[#Points+1] = PointStartVec2:RoutePointGround( Speed )
  Points[#Points+1] = ToPointVec2:RoutePointGround( Speed )

  local TaskRoute = self.CargoObject:TaskRoute( Points )
  self.CargoObject:SetTask( TaskRoute, 2 )
  return self  
end

end -- CARGO_BASE

do -- CARGO_UNIT

  --- @type CARGO_UNIT
  -- @extends #CARGO_REPRESENTABLE
  CARGO_UNIT = {
    ClassName = "CARGO_UNIT"
  }

--- CARGO_UNIT Constructor.
-- @param #CARGO_UNIT self
-- @param Unit#UNIT CargoUnit
-- @param #string Type
-- @param #string Name
-- @param #number Weight
-- @param #number ReportRadius (optional)
-- @param #number NearRadius (optional)
-- @return #CARGO_UNIT
function CARGO_UNIT:New( CargoUnit, Type, Name, Weight, ReportRadius, NearRadius )
  local self = BASE:Inherit( self, CARGO_REPRESENTABLE:New( CargoUnit, Type, Name, Weight, ReportRadius, NearRadius ) ) -- #CARGO_UNIT
  self:F( { Type, Name, Weight, ReportRadius, NearRadius } )

  self:T( CargoUnit )
  self.CargoObject = CargoUnit

  self:T( self.ClassName )

  return self
end

--- Enter UnBoarding State.
-- @param #CARGO_UNIT self
-- @param Point#POINT_VEC2 ToPointVec2
-- @param #string Event
-- @param #string From
-- @param #string To
function CARGO_UNIT:onenterUnBoarding( ToPointVec2, Event, From, To )
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
-- @param #CARGO_UNIT self
-- @param Point#POINT_VEC2 ToPointVec2
-- @param #string Event
-- @param #string From
-- @param #string To
function CARGO_UNIT:onleaveUnBoarding( ToPointVec2, Event, From, To )
  self:F( { ToPointVec2, Event, From, To } )

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
-- @param #CARGO_UNIT self
-- @param Point#POINT_VEC2 ToPointVec2
-- @param #string Event
-- @param #string From
-- @param #string To
function CARGO_UNIT:onafterUnBoarding( ToPointVec2, Event, From, To )
  self:F( { ToPointVec2, Event, From, To } )

  self.CargoInAir = self.CargoObject:InAir()

  self:T( self.CargoInAir )

  -- Only unboard the cargo when the carrier is not in the air.
  -- (eg. cargo can be on a oil derrick, moving the cargo on the oil derrick will drop the cargo on the sea).
  if not self.CargoInAir then

  end

  self:__UnLoad( 1, ToPointVec2 )

end



--- Enter UnLoaded State.
-- @param #CARGO_UNIT self
-- @param Point#POINT_VEC2
-- @param #string Event
-- @param #string From
-- @param #string To
function CARGO_UNIT:onenterUnLoaded( ToPointVec2, Event, From, To )
  self:F( { ToPointVec2, Event, From, To } )

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
-- @param #CARGO_UNIT self
-- @param Unit#UNIT CargoCarrier
-- @param #string Event
-- @param #string From
-- @param #string To
function CARGO_UNIT:onenterBoarding( CargoCarrier, Event, From, To )
  self:F( { CargoCarrier.UnitName, Event, From, To } )
  
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
-- @param #CARGO_UNIT self
-- @param Unit#UNIT CargoCarrier
-- @param #string Event
-- @param #string From
-- @param #string To
function CARGO_UNIT:onleaveBoarding( CargoCarrier, Event, From, To )
  self:F( { CargoCarrier.UnitName, Event, From, To } )

  if self:IsNear( CargoCarrier:GetPointVec2() ) then
    self:__Load( 1, CargoCarrier )
    return true
  else
    self:__Boarding( 1, CargoCarrier )
  end
  return false
end

--- Loaded State.
-- @param #CARGO_UNIT self
-- @param Unit#UNIT CargoCarrier
-- @param #string Event
-- @param #string From
-- @param #string To
function CARGO_UNIT:onenterLoaded( CargoCarrier, Event, From, To )
  self:F()

  self.CargoCarrier = CargoCarrier
  
  -- Only destroy the CargoObject is if there is a CargoObject (packages don't have CargoObjects).
  if self.CargoObject then
    self:T("Destroying")
    self.CargoObject:Destroy()
  end
end


--- Board Event.
-- @param #CARGO_UNIT self
-- @param #string Event
-- @param #string From
-- @param #string To
function CARGO_UNIT:onafterBoard( CargoCarrier, Event, From, To)
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

do -- CARGO_PACKAGE

  --- @type CARGO_PACKAGE
  -- @extends #CARGO_REPRESENTABLE
  CARGO_PACKAGE = {
    ClassName = "CARGO_PACKAGE"
  }

--- CARGO_PACKAGE Constructor.
-- @param #CARGO_PACKAGE self
-- @param Unit#UNIT CargoCarrier The UNIT carrying the package.
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
-- @param StateMachine#STATEMACHINE_PROCESS FsmP
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Unit#UNIT CargoCarrier
-- @param #number Speed
-- @param #number BoardDistance
-- @param #number Angle
function CARGO_PACKAGE:onafterOnBoard( FsmP, Event, From, To, CargoCarrier, Speed, BoardDistance, LoadDistance, Angle )
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
-- @param #CARGO_PACKAGE self
-- @param Unit#UNIT CargoCarrier
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
-- @param StateMachine#STATEMACHINE_PROCESS FsmP
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Unit#UNIT CargoCarrier
function CARGO_PACKAGE:onafterOnBoarded( FsmP, Event, From, To, CargoCarrier, Speed, BoardDistance, LoadDistance, Angle )
  self:F()

  if self:IsNear( CargoCarrier ) then
    self:_NextEvent( FsmP.Load, CargoCarrier, Speed, LoadDistance, Angle )
  else
    self:_NextEvent( FsmP.Boarded, CargoCarrier, Speed, BoardDistance, LoadDistance, Angle )
  end
end

--- UnBoard Event.
-- @param #CARGO_PACKAGE self
-- @param StateMachine#STATEMACHINE_PROCESS FsmP
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param #number Speed
-- @param #number UnLoadDistance
-- @param #number UnBoardDistance
-- @param #number Radius
-- @param #number Angle
function CARGO_PACKAGE:onafterUnBoard( FsmP, Event, From, To, CargoCarrier, Speed, UnLoadDistance, UnBoardDistance, Radius, Angle )
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

  self:_NextEvent( FsmP.UnBoarded, CargoCarrier, Speed )

end

--- UnBoarded Event.
-- @param #CARGO_PACKAGE self
-- @param StateMachine#STATEMACHINE_PROCESS FsmP
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Unit#UNIT CargoCarrier
function CARGO_PACKAGE:onafterUnBoarded( FsmP, Event, From, To, CargoCarrier, Speed )
  self:F()

  if self:IsNear( CargoCarrier ) then
    self:_NextEvent( FsmP.UnLoad, CargoCarrier, Speed )
  else
    self:_NextEvent( FsmP.UnBoarded, CargoCarrier, Speed )
  end
end

--- Load Event.
-- @param #CARGO_PACKAGE self
-- @param StateMachine#STATEMACHINE_PROCESS FsmP
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Unit#UNIT CargoCarrier
-- @param #number Speed
-- @param #number LoadDistance
-- @param #number Angle
function CARGO_PACKAGE:onafterLoad( FsmP, Event, From, To, CargoCarrier, Speed, LoadDistance, Angle )
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
-- @param #CARGO_PACKAGE self
-- @param StateMachine#STATEMACHINE_PROCESS FsmP
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param #number Distance
-- @param #number Angle
function CARGO_PACKAGE:onafterUnLoad( FsmP, Event, From, To, CargoCarrier, Speed, Distance, Angle )
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

do -- CARGO_GROUP

  --- @type CARGO_GROUP
  -- @extends Cargo#CARGO_BASE
  -- @field Set#SET_BASE CargoSet A set of cargo objects.
  -- @field #string Name A string defining the name of the cargo group. The name is the unique identifier of the cargo.
  CARGO_GROUP = {
    ClassName = "CARGO_GROUP",
  }

--- CARGO_GROUP constructor.
-- @param #CARGO_GROUP self
-- @param Set#Set_BASE CargoSet
-- @param #string Type
-- @param #string Name
-- @param #number Weight
-- @param #number ReportRadius (optional)
-- @param #number NearRadius (optional)
-- @return #CARGO_GROUP
function CARGO_GROUP:New( CargoSet, Type, Name, ReportRadius, NearRadius )
  local self = BASE:Inherit( self, CARGO_BASE:New( Type, Name, 0, ReportRadius, NearRadius ) ) -- #CARGO_GROUP
  self:F( { Type, Name, ReportRadius, NearRadius } )

  self.CargoSet = CargoSet


  return self
end

end -- CARGO_GROUP

do -- CARGO_GROUPED

  --- @type CARGO_GROUPED
  -- @extends Cargo#CARGO_GROUP
  CARGO_GROUPED = {
    ClassName = "CARGO_GROUPED",
  }

--- CARGO_GROUPED constructor.
-- @param #CARGO_GROUPED self
-- @param Set#Set_BASE CargoSet
-- @param #string Type
-- @param #string Name
-- @param #number Weight
-- @param #number ReportRadius (optional)
-- @param #number NearRadius (optional)
-- @return #CARGO_GROUPED
function CARGO_GROUPED:New( CargoSet, Type, Name, ReportRadius, NearRadius )
  local self = BASE:Inherit( self, CARGO_GROUP:New( CargoSet, Type, Name, ReportRadius, NearRadius ) ) -- #CARGO_GROUPED
  self:F( { Type, Name, ReportRadius, NearRadius } )

  return self
end

--- Enter Boarding State.
-- @param #CARGO_GROUPED self
-- @param Unit#UNIT CargoCarrier
-- @param #string Event
-- @param #string From
-- @param #string To
function CARGO_GROUPED:onenterBoarding( CargoCarrier, Event, From, To )
  self:F( { CargoCarrier.UnitName, Event, From, To } )
  
  if From == "UnLoaded" then

    -- For each Cargo object within the CARGO_GROUPED, route each object to the CargoLoadPointVec2
    self.CargoSet:ForEach(
      function( Cargo )
        Cargo:__Board( 1, CargoCarrier )
      end
    )
    
    self:__Boarding( 1, CargoCarrier )
  end
  
end

--- Enter Loaded State.
-- @param #CARGO_GROUPED self
-- @param Unit#UNIT CargoCarrier
-- @param #string Event
-- @param #string From
-- @param #string To
function CARGO_GROUPED:onenterLoaded( CargoCarrier, Event, From, To )
  self:F( { CargoCarrier.UnitName, Event, From, To } )
  
  if From == "UnLoaded" then
    -- For each Cargo object within the CARGO_GROUPED, load each cargo to the CargoCarrier.
    for CargoID, Cargo in pairs( self.CargoSet:GetSet() ) do
      Cargo:Load( CargoCarrier )
    end
  end
end

--- Leave Boarding State.
-- @param #CARGO_GROUPED self
-- @param Unit#UNIT CargoCarrier
-- @param #string Event
-- @param #string From
-- @param #string To
function CARGO_GROUPED:onleaveBoarding( CargoCarrier, Event, From, To )
  self:F( { CargoCarrier.UnitName, Event, From, To } )

  local Boarded = true

  -- For each Cargo object within the CARGO_GROUPED, route each object to the CargoLoadPointVec2
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
-- @param #CARGO_GROUPED self
-- @param Point#POINT_VEC2 ToPointVec2
-- @param #string Event
-- @param #string From
-- @param #string To
function CARGO_GROUPED:onenterUnBoarding( ToPointVec2, Event, From, To )
  self:F()

  local Timer = 1

  if From == "Loaded" then

    -- For each Cargo object within the CARGO_GROUPED, route each object to the CargoLoadPointVec2
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
-- @param #CARGO_GROUPED self
-- @param Point#POINT_VEC2 ToPointVec2
-- @param #string Event
-- @param #string From
-- @param #string To
function CARGO_GROUPED:onleaveUnBoarding( ToPointVec2, Event, From, To )
  self:F( { ToPointVec2, Event, From, To } )

  local Angle = 180
  local Speed = 10
  local Distance = 5

  if From == "UnBoarding" then
    local UnBoarded = true

    -- For each Cargo object within the CARGO_GROUPED, route each object to the CargoLoadPointVec2
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
-- @param #CARGO_GROUPED self
-- @param Point#POINT_VEC2 ToPointVec2
-- @param #string Event
-- @param #string From
-- @param #string To
function CARGO_GROUPED:onafterUnBoarding( ToPointVec2, Event, From, To )
  self:F( { ToPointVec2, Event, From, To } )

  self:__UnLoad( 1, ToPointVec2 )
end



--- Enter UnLoaded State.
-- @param #CARGO_GROUPED self
-- @param Point#POINT_VEC2
-- @param #string Event
-- @param #string From
-- @param #string To
function CARGO_GROUPED:onenterUnLoaded( ToPointVec2, Event, From, To )
  self:F( { ToPointVec2, Event, From, To } )

  if From == "Loaded" then
    
    -- For each Cargo object within the CARGO_GROUPED, route each object to the CargoLoadPointVec2
    self.CargoSet:ForEach(
      function( Cargo )
        Cargo:UnLoad( ToPointVec2 )
      end
    )

  end

end

end -- CARGO_GROUPED



