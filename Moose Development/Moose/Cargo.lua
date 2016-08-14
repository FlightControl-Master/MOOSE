--- This module contains the CARGO classes.
--
-- ===
--
-- 1) @{Cargo#CARGO_BASE} class, extends @{Base#BASE}
-- ==================================================
-- The @{#CARGO_BASE} class defines the core functions that defines a cargo object within MOOSE.
-- A cargo is a logical object defined within a @{Mission}, that is available for transport, and has a life status within a simulation.
--
-- Cargo can be of various forms:
--
--   * CARGO_UNIT, represented by a @{Unit} in a @{Group}: Cargo can be represented by a Unit in a Group. Destruction of the Unit will mean that the cargo is lost.
--   * CARGO_STATIC, represented by a @{Static}: Cargo can be represented by a Static. Destruction of the Static will mean that the cargo is lost.
--   * CARGO_PACKAGE, contained in a @{Unit} of a @{Group}: Cargo can be contained within a Unit of a Group. The cargo can be **delivered** by the @{Unit}. If the Unit is destroyed, the cargo will be destroyed also.
--   * CARGO_PACKAGE, Contained in a @{Static}: Cargo can be contained within a Static. The cargo can be **collected** from the @Static. If the @{Static} is destroyed, the cargo will be destroyed.
--   * CARGO_SLINGLOAD, represented by a @{Cargo} that is transportable: Cargo can be represented by a Cargo object that is transportable. Destruction of the Cargo will mean that the cargo is lost.
--
-- @module Cargo



CARGOS = {}

do -- CARGO

  --- @type CARGO
  -- @extends Base#BASE
  -- @field #string Type A string defining the type of the cargo. eg. Engineers, Equipment, Screwdrivers.
  -- @field #string Name A string defining the name of the cargo. The name is the unique identifier of the cargo.
  -- @field #number Weight A number defining the weight of the cargo. The weight is expressed in kg.
  -- @field #number ReportRadius (optional) A number defining the radius in meters when the cargo is signalling or reporting to a Carrier.
  -- @field #number NearRadius (optional) A number defining the radius in meters when the cargo is near to a Carrier, so that it can be loaded.
  -- @field Controllable#CONTROLLABLE CargoObject The alive DCS object representing the cargo. This value can be nil, meaning, that the cargo is not represented anywhere...
  -- @field Positionable#POSITIONABLE CargoCarrier The alive DCS object carrying the cargo. This value can be nil, meaning, that the cargo is not contained anywhere...
  -- @field #boolean Slingloadable This flag defines if the cargo can be slingloaded.
  -- @field #boolean Moveable This flag defines if the cargo is moveable.
  -- @field #boolean Representable This flag defines if the cargo can be represented by a DCS Unit.
  -- @field #boolean Containable This flag defines if the cargo can be contained within a DCS Unit.
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
-- @map < #string, Positionable#POSITIONABLE > The alive POSITIONABLE objects representing the the cargo.


--- CARGO Constructor.
-- @param #CARGO self
-- @param Mission#MISSION Mission
-- @param #string Type
-- @param #string Name
-- @param #number Weight
-- @param #number ReportRadius (optional)
-- @param #number NearRadius (optional)
-- @return #CARGO
function CARGO:New( Mission, Type, Name, Weight, ReportRadius, NearRadius )
  local self = BASE:Inherit( self, BASE:New() ) -- #CARGO
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


--- Template method to spawn a new representation of the CARGO in the simulator.
-- @param #CARGO self
-- @return #CARGO
function CARGO:Spawn( PointVec2 )
  self:F()

end

--- Load Cargo to a Carrier.
-- @param #CARGO self
-- @param Unit#UNIT CargoCarrier
function CARGO:Load( CargoCarrier )
  self:F()
  
  self:_NextEvent( self.FsmP.Load, CargoCarrier )
end

--- UnLoad Cargo from a Carrier with a UnLoadDistance and an Angle.
-- @param #CARGO self
-- @param #number UnLoadDistance
-- @param #number Angle
function CARGO:UnLoad( CargoCarrier )
  self:F()
  
  self:_NextEvent( self.FsmP.Board, CargoCarrier )
end

--- Board Cargo to a Carrier with a defined Speed.
-- @param #CARGO self
-- @param Unit#UNIT CargoCarrier
function CARGO:Board( CargoCarrier )
  self:F()
  
  self:_NextEvent( self.FsmP.Board, CargoCarrier )
end

--- UnLoad Cargo from a Carrier.
-- @param #CARGO self
function CARGO:UnLoad()
  self:F()
  
  self:_NextEvent( self.FsmP.UnLoad )
end

--- Check if CargoCarrier is near the Cargo to be Loaded.
-- @param #CARGO self
-- @param Point#POINT_VEC2 PointVec2
-- @return #boolean
function CARGO:IsNear( PointVec2 )
  self:F()

  local Distance = PointVec2:DistanceFromPointVec2( self.CargoObject:GetPointVec2() )
  self:T( Distance )
  
  if Distance <= self.NearRadius then
    return true
  else
    return false
  end
end


--- On Loaded callback function.
function CARGO:OnLoaded( CallBackFunction, ... )
  self:F()
  
  self.OnLoadedCallBack = CallBackFunction
  self.OnLoadedParameters = arg
  
end

--- On UnLoaded callback function.
function CARGO:OnUnLoaded( CallBackFunction, ... )
  self:F()

  self.OnUnLoadedCallBack = CallBackFunction
  self.OnUnLoadedParameters = arg
end

--- @param #CARGO self
function CARGO:_NextEvent( NextEvent, ... )
  self:F( self.Name )
  SCHEDULER:New( self.FsmP, NextEvent, arg, 1 ) -- This schedules the next event, but only if scheduling is activated.
end

--- @param #CARGO self
function CARGO:_Next( NextEvent, ... )
  self:F( self.Name )
  self.FsmP.NextEvent( self, unpack(arg) ) -- This calls the next event...
end

end

do -- CARGO_REPRESENTABLE

  --- @type CARGO_REPRESENTABLE
  -- @extends #CARGO
  CARGO_REPRESENTABLE = {
    ClassName = "CARGO_REPRESENTABLE"
  }

--- CARGO_REPRESENTABLE Constructor.
-- @param #CARGO_REPRESENTABLE self
-- @param Mission#MISSION Mission
-- @param Controllable#Controllable CargoObject
-- @param #string Type
-- @param #string Name
-- @param #number Weight
-- @param #number ReportRadius (optional)
-- @param #number NearRadius (optional)
-- @return #CARGO_REPRESENTABLE
function CARGO_REPRESENTABLE:New( Mission, CargoObject, Type, Name, Weight, ReportRadius, NearRadius )
  local self = BASE:Inherit( self, CARGO:New( Mission, Type, Name, Weight, ReportRadius, NearRadius ) ) -- #CARGO
  self:F( { Type, Name, Weight, ReportRadius, NearRadius } )

  
  

  return self
end



end

do -- CARGO_UNIT

  --- @type CARGO_UNIT
  -- @extends #CARGO_REPRESENTABLE
  CARGO_UNIT = {
    ClassName = "CARGO_UNIT"
  }

--- CARGO_UNIT Constructor.
-- @param #CARGO_UNIT self
-- @param Mission#MISSION Mission
-- @param Unit#UNIT CargoUnit
-- @param #string Type
-- @param #string Name
-- @param #number Weight
-- @param #number ReportRadius (optional)
-- @param #number NearRadius (optional)
-- @return #CARGO_UNIT
function CARGO_UNIT:New( Mission, CargoUnit, Type, Name, Weight, ReportRadius, NearRadius )
  local self = BASE:Inherit( self, CARGO_REPRESENTABLE:New( Mission, CargoUnit, Type, Name, Weight, ReportRadius, NearRadius ) ) -- #CARGO
  self:F( { Type, Name, Weight, ReportRadius, NearRadius } )

  self:T( CargoUnit )
  self.CargoObject = CargoUnit

  self.FsmP = STATEMACHINE_PROCESS:New( self, {
    initial = 'UnLoaded',
    events = {
      { name = 'Board',       from = 'UnLoaded',        to = 'Boarding' },
      { name = 'Load',        from = 'Boarding',        to = 'Loaded' },
      { name = 'UnLoad',      from = 'Loaded',          to = 'UnBoarding' },
      { name = 'UnBoard',     from = 'UnBoarding',      to = 'UnLoaded' },
      { name = 'Load',        from = 'UnLoaded',        to = 'Loaded' },
    },
    callbacks = {
      onafterBoard = self.EventBoard,
      onafterLoad = self.EventLoad,
      onafterUnBoard = self.EventUnBoard,
      onafterUnLoad = self.EventUnLoad,
      onenterBoarding = self.EnterStateBoarding,
      onleaveBoarding = self.LeaveStateBoarding,
      onenterLoaded = self.EnterStateLoaded,
      onenterUnBoarding = self.EnterStateUnBoarding,
      onleaveUnBoarding = self.LeaveStateUnBoarding,
      onenterUnLoaded = self.EnterStateUnLoaded,
    },
  } )

  self:T( self.ClassName )

  return self
end

--- Enter UnBoarding State.
-- @param #CARGO_UNIT self
-- @param StateMachine#STATEMACHINE_PROCESS FsmP
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Point#POINT_VEC2 ToPointVec2
function CARGO_UNIT:EnterStateUnBoarding( FsmP, Event, From, To, ToPointVec2 )
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

    if not ToPointVec2 then
      ToPointVec2 = CargoRoutePointVec2
    end
    
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

      self:_NextEvent( FsmP.UnBoard, ToPointVec2 )
    end
  end

end

--- Leave UnBoarding State.
-- @param #CARGO_UNIT self
-- @param StateMachine#STATEMACHINE_PROCESS FsmP
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Point#POINT_VEC2 ToPointVec2
function CARGO_UNIT:LeaveStateUnBoarding( FsmP, Event, From, To, ToPointVec2 )
  self:F()

  local Angle = 180
  local Speed = 10
  local Distance = 5

  if From == "UnBoarding" then
    if self:IsNear( ToPointVec2 ) then
      return true
    else
      self:_NextEvent( FsmP.UnBoard, ToPointVec2 )
    end
    return false
  end

end

--- Enter UnLoaded State.
-- @param #CARGO_UNIT self
-- @param StateMachine#STATEMACHINE_PROCESS FsmP
-- @param #string Event
-- @param #string From
-- @param #string To
function CARGO_UNIT:EnterStateUnLoaded( FsmP, Event, From, To, ToPointVec2 )
  self:F()

  local Angle = 180
  local Speed = 10
  local Distance = 5

  if From == "Loaded" then
    local StartPointVec2 = self.CargoCarrier:GetPointVec2()
    local CargoCarrierHeading = self.CargoCarrier:GetHeading() -- Get Heading of object in degrees.
    local CargoDeployHeading = ( ( CargoCarrierHeading + Angle ) >= 360 ) and ( CargoCarrierHeading + Angle - 360 ) or ( CargoCarrierHeading + Angle )
    local CargoDeployPointVec2 = StartPointVec2:Translate( Distance, CargoDeployHeading )

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
-- @param StateMachine#STATEMACHINE_PROCESS FsmP
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Unit#UNIT CargoCarrier
function CARGO_UNIT:EnterStateBoarding( FsmP, Event, From, To, CargoCarrier )
  self:F()
  
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
-- @param StateMachine#STATEMACHINE_PROCESS FsmP
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Unit#UNIT CargoCarrier
function CARGO_UNIT:LeaveStateBoarding( FsmP, Event, From, To, CargoCarrier )
  self:F()

  if self:IsNear( CargoCarrier:GetPointVec2() ) then
    return true
  else
    self:_NextEvent( FsmP.Load, CargoCarrier )
  end
  return false
end

--- Loaded State.
-- @param #CARGO_UNIT self
-- @param StateMachine#STATEMACHINE_PROCESS FsmP
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Unit#UNIT CargoCarrier
function CARGO_UNIT:EnterStateLoaded( FsmP, Event, From, To, CargoCarrier )
  self:F()

  self.CargoCarrier = CargoCarrier
  
  -- Only destroy the CargoObject is if there is a CargoObject (packages don't have CargoObjects).
  if self.CargoObject then
    self.CargoObject:Destroy()
  end
  
  if self.OnLoadedCallBack then
    self.OnLoadedCallBack( self, unpack( self.OnLoadedParameters ) )
    self.OnLoadedCallBack = nil
  end
  
end


--- Board Event.
-- @param #CARGO_UNIT self
-- @param StateMachine#STATEMACHINE_PROCESS FsmP
-- @param #string Event
-- @param #string From
-- @param #string To
function CARGO_UNIT:EventBoard( FsmP, Event, From, To, CargoCarrier )
  self:F()

  self.CargoInAir = self.CargoObject:InAir()

  self:T( self.CargoInAir )

  -- Only move the group to the carrier when the cargo is not in the air
  -- (eg. cargo can be on a oil derrick, moving the cargo on the oil derrick will drop the cargo on the sea).
  if not self.CargoInAir then
    self:_NextEvent( FsmP.Load, CargoCarrier )
  end


end

--- UnBoard Event.
-- @param #CARGO_UNIT self
-- @param StateMachine#STATEMACHINE_PROCESS FsmP
-- @param #string Event
-- @param #string From
-- @param #string To
function CARGO_UNIT:EventUnBoard( FsmP, Event, From, To )
  self:F()

  self.CargoInAir = self.CargoObject:InAir()

  self:T( self.CargoInAir )

  -- Only unboard the cargo when the carrier is not in the air.
  -- (eg. cargo can be on a oil derrick, moving the cargo on the oil derrick will drop the cargo on the sea).
  if not self.CargoInAir then

  end

  self:_NextEvent( FsmP.UnLoad )

end

--- Load Event.
-- @param #CARGO_UNIT self
-- @param StateMachine#STATEMACHINE_PROCESS FsmP
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Unit#UNIT CargoCarrier
function CARGO_UNIT:EventLoad( FsmP, Event, From, To, CargoCarrier )
  self:F()

  self:T( self.ClassName )

end

--- UnLoad Event.
-- @param #CARGO_UNIT self
-- @param StateMachine#STATEMACHINE_PROCESS FsmP
-- @param #string Event
-- @param #string From
-- @param #string To
function CARGO_UNIT:EventUnLoad( FsmP, Event, From, To )
  self:F()
  
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
-- @param Mission#MISSION Mission
-- @param Unit#UNIT CargoCarrier The UNIT carrying the package.
-- @param #string Type
-- @param #string Name
-- @param #number Weight
-- @param #number ReportRadius (optional)
-- @param #number NearRadius (optional)
-- @return #CARGO_PACKAGE
function CARGO_PACKAGE:New( Mission, CargoCarrier, Type, Name, Weight, ReportRadius, NearRadius )
  local self = BASE:Inherit( self, CARGO_REPRESENTABLE:New( Mission, CargoCarrier, Type, Name, Weight, ReportRadius, NearRadius ) ) -- #CARGO
  self:F( { Type, Name, Weight, ReportRadius, NearRadius } )

  self:T( CargoCarrier )
  self.CargoCarrier = CargoCarrier

  self.FsmP = STATEMACHINE_PROCESS:New( self, {
    initial = 'UnLoaded',
    events = {
      { name = 'Board',       from = 'UnLoaded',        to = 'Boarding' },
      { name = 'Boarded',     from = 'Boarding',        to = 'Boarding' },
      { name = 'Load',        from = 'Boarding',        to = 'Loaded' },
      { name = 'Load',        from = 'UnLoaded',        to = 'Loaded' },
      { name = 'UnBoard',     from = 'Loaded',          to = 'UnBoarding' },
      { name = 'UnBoarded',   from = 'UnBoarding',      to = 'UnBoarding' },
      { name = 'UnLoad',      from = 'UnBoarding',      to = 'UnLoaded' },
      { name = 'UnLoad',      from = 'Loaded',          to = 'UnLoaded' },
    },
    callbacks = {
      onBoard = self.OnBoard,
      onBoarded = self.OnBoarded,
      onLoad = self.OnLoad,
      onUnBoard = self.OnUnBoard,
      onUnBoarded = self.OnUnBoarded,
      onUnLoad = self.OnUnLoad,
      onLoaded = self.OnLoaded,
      onUnLoaded = self.OnUnLoaded,
    },
  } )

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
function CARGO_PACKAGE:OnBoard( FsmP, Event, From, To, CargoCarrier, Speed, BoardDistance, LoadDistance, Angle )
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

  self:_NextEvent( FsmP.Boarded, CargoCarrier, Speed, BoardDistance, LoadDistance, Angle )

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
function CARGO_PACKAGE:OnBoarded( FsmP, Event, From, To, CargoCarrier, Speed, BoardDistance, LoadDistance, Angle )
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
function CARGO_PACKAGE:OnUnBoard( FsmP, Event, From, To, CargoCarrier, Speed, UnLoadDistance, UnBoardDistance, Radius, Angle )
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
function CARGO_PACKAGE:OnUnBoarded( FsmP, Event, From, To, CargoCarrier, Speed )
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
function CARGO_PACKAGE:OnLoad( FsmP, Event, From, To, CargoCarrier, Speed, LoadDistance, Angle )
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
function CARGO_PACKAGE:OnUnLoad( FsmP, Event, From, To, CargoCarrier, Speed, Distance, Angle )
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



CARGO_SLINGLOAD = {
  ClassName = "CARGO_SLINGLOAD"
}


function CARGO_SLINGLOAD:New( CargoType, CargoName, CargoWeight, CargoZone, CargoHostName, CargoCountryID )
  local self = BASE:Inherit( self, CARGO:New( CargoType, CargoName, CargoWeight ) )
  self:F( { CargoType, CargoName, CargoWeight, CargoZone, CargoHostName, CargoCountryID } )

  self.CargoHostName = CargoHostName

  -- Cargo will be initialized around the CargoZone position.
  self.CargoZone = CargoZone

  self.CargoCount = 0
  self.CargoStaticName = string.format( "%s#%03d", self.CargoName, self.CargoCount )

  -- The country ID needs to be correctly set.
  self.CargoCountryID = CargoCountryID

  CARGOS[self.CargoName] = self

  return self

end


function CARGO_SLINGLOAD:IsLandingRequired()
  self:F()
  return false
end


function CARGO_SLINGLOAD:IsSlingLoad()
  self:F()
  return true
end


function CARGO_SLINGLOAD:Spawn( Client )
  self:F( { self, Client } )

  local Zone = trigger.misc.getZone( self.CargoZone )

  local ZonePos = {}
  ZonePos.x = Zone.point.x + math.random( Zone.radius / 2 * -1, Zone.radius / 2 )
  ZonePos.y = Zone.point.z + math.random( Zone.radius / 2 * -1, Zone.radius / 2 )

  self:T( "Cargo Location = " .. ZonePos.x .. ", " .. ZonePos.y )

  --[[







	-- This does not work in 1.5.2.







	CargoStatic = StaticObject.getByName( self.CargoName )







	if CargoStatic then







		CargoStatic:destroy()







	end







	--]]

  CargoStatic = StaticObject.getByName( self.CargoStaticName )

  if CargoStatic and CargoStatic:isExist() then
    CargoStatic:destroy()
  end

  -- I need to make every time a new cargo due to bugs in 1.5.2.

  self.CargoCount = self.CargoCount + 1
  self.CargoStaticName = string.format( "%s#%03d", self.CargoName, self.CargoCount )

  local CargoTemplate = {
    ["category"] = "Cargo",
    ["shape_name"] = "ab-212_cargo",
    ["type"] = "Cargo1",
    ["x"] = ZonePos.x,
    ["y"] = ZonePos.y,
    ["mass"] = self.CargoWeight,
    ["name"] =  self.CargoStaticName,
    ["canCargo"] = true,
    ["heading"] = 0,
  }

  coalition.addStaticObject( self.CargoCountryID, CargoTemplate )

  --	end

  return self
end


function CARGO_SLINGLOAD:IsNear( Client, LandingZone )
  self:F()

  local Near = false

  return Near
end


function CARGO_SLINGLOAD:IsInLandingZone( Client, LandingZone )
  self:F()

  local Near = false

  local CargoStaticUnit = StaticObject.getByName( self.CargoName )
  if CargoStaticUnit then
    if routines.IsStaticInZones( CargoStaticUnit, LandingZone ) then
      Near = true
    end
  end

  return Near
end


function CARGO_SLINGLOAD:OnBoard( Client, LandingZone, OnBoardSide )
  self:F()

  local Valid = true


  return Valid
end


function CARGO_SLINGLOAD:OnBoarded( Client, LandingZone )
  self:F()

  local OnBoarded = false

  local CargoStaticUnit = StaticObject.getByName( self.CargoName )
  if CargoStaticUnit then
    if not routines.IsStaticInZones( CargoStaticUnit, LandingZone ) then
      OnBoarded = true
    end
  end

  return OnBoarded
end


function CARGO_SLINGLOAD:UnLoad( Client, TargetZoneName )
  self:F()

  self:T( 'self.CargoName = ' .. self.CargoName )
  self:T( 'self.CargoGroupName = ' .. self.CargoGroupName )

  self:StatusUnLoaded()

  return Cargo
end

CARGO_ZONE = {
  ClassName="CARGO_ZONE",
  CargoZoneName = '',
  CargoHostUnitName = '',
  SIGNAL = {
    TYPE = {
      SMOKE = { ID = 1, TEXT = "smoke" },
      FLARE = { ID = 2, TEXT = "flare" }
    },
    COLOR = {
      GREEN = { ID = 1, TRIGGERCOLOR = trigger.smokeColor.Green, TEXT = "A green" },
      RED = { ID = 2, TRIGGERCOLOR = trigger.smokeColor.Red, TEXT = "A red" },
      WHITE = { ID = 3, TRIGGERCOLOR = trigger.smokeColor.White, TEXT = "A white" },
      ORANGE = { ID = 4, TRIGGERCOLOR = trigger.smokeColor.Orange, TEXT = "An orange" },
      BLUE = { ID = 5, TRIGGERCOLOR = trigger.smokeColor.Blue, TEXT = "A blue" },
      YELLOW = { ID = 6, TRIGGERCOLOR = trigger.flareColor.Yellow, TEXT = "A yellow" }
    }
  }
}

--- Creates a new zone where cargo can be collected or deployed.
-- The zone functionality is useful to smoke or indicate routes for cargo pickups or deployments.
-- Provide the zone name as declared in the mission file into the CargoZoneName in the :New method.
-- An optional parameter is the CargoHostName, which is a Group declared with Late Activation switched on in the mission file.
-- The CargoHostName is the "host" of the cargo zone:
--
-- * It will smoke the zone position when a client is approaching the zone.
-- * Depending on the cargo type, it will assist in the delivery of the cargo by driving to and from the client.
--
-- @param #CARGO_ZONE self
-- @param #string CargoZoneName The name of the zone as declared within the mission editor.
-- @param #string CargoHostName The name of the Group "hosting" the zone. The Group MUST NOT be a static, and must be a "mobile" unit.
function CARGO_ZONE:New( CargoZoneName, CargoHostName ) local self = BASE:Inherit( self, ZONE:New( CargoZoneName ) )
  self:F( { CargoZoneName, CargoHostName } )

  self.CargoZoneName = CargoZoneName
  self.SignalHeight = 2
  --self.CargoZone = trigger.misc.getZone( CargoZoneName )


  if CargoHostName then
    self.CargoHostName = CargoHostName
  end

  self:T( self.CargoZoneName )

  return self
end

function CARGO_ZONE:Spawn()
  self:F( self.CargoHostName )

  if self.CargoHostName then -- Only spawn a host in the zone when there is one given as a parameter in the New function.
    if self.CargoHostSpawn then
      local CargoHostGroup = self.CargoHostSpawn:GetGroupFromIndex()
      if CargoHostGroup and CargoHostGroup:IsAlive() then
      else
        self.CargoHostSpawn:ReSpawn( 1 )
      end
  else
    self:T( "Initialize CargoHostSpawn" )
    self.CargoHostSpawn = SPAWN:New( self.CargoHostName ):InitLimit( 1, 1 )
    self.CargoHostSpawn:ReSpawn( 1 )
  end
  end

  return self
end

function CARGO_ZONE:GetHostUnit()
  self:F( self )

  if self.CargoHostName then

    -- A Host has been given, signal the host
    local CargoHostGroup = self.CargoHostSpawn:GetGroupFromIndex()
    local CargoHostUnit
    if CargoHostGroup and CargoHostGroup:IsAlive() then
      CargoHostUnit = CargoHostGroup:GetUnit(1)
    else
      CargoHostUnit = StaticObject.getByName( self.CargoHostName )
    end

    return CargoHostUnit
  end

  return nil
end

function CARGO_ZONE:ReportCargosToClient( Client, CargoType )
  self:F()

  local SignalUnit = self:GetHostUnit()

  if SignalUnit then

    local SignalUnitTypeName = SignalUnit:getTypeName()

    local HostMessage = ""

    local IsCargo = false
    for CargoID, Cargo in pairs( CARGOS ) do
      if Cargo.CargoType == Task.CargoType then
        if Cargo:IsStatusNone() then
          HostMessage = HostMessage .. " - " .. Cargo.CargoName .. " - " .. Cargo.CargoType .. " (" .. Cargo.Weight .. "kg)" .. "\n"
          IsCargo = true
        end
      end
    end

    if not IsCargo then
      HostMessage = "No Cargo Available."
    end

    Client:Message( HostMessage, 20, SignalUnitTypeName .. ": Reporting Cargo", 10 )
  end
end


function CARGO_ZONE:Signal()
  self:F()

  local Signalled = false

  if self.SignalType then

    if self.CargoHostName then

      -- A Host has been given, signal the host

      local SignalUnit = self:GetHostUnit()

      if SignalUnit then

        self:T( 'Signalling Unit' )
        local SignalVehicleVec3 = SignalUnit:GetVec3()
        SignalVehicleVec3.y = SignalVehicleVec3.y + 2

        if self.SignalType.ID == CARGO_ZONE.SIGNAL.TYPE.SMOKE.ID then

          trigger.action.smoke( SignalVehicleVec3, self.SignalColor.TRIGGERCOLOR )
          Signalled = true

        elseif self.SignalType.ID == CARGO_ZONE.SIGNAL.TYPE.FLARE.ID then

          trigger.action.signalFlare( SignalVehicleVec3, self.SignalColor.TRIGGERCOLOR , 0 )
          Signalled = false

        end
      end

    else

      local ZoneVec3 = self:GetPointVec3( self.SignalHeight ) -- Get the zone position + the landheight + 2 meters

      if self.SignalType.ID == CARGO_ZONE.SIGNAL.TYPE.SMOKE.ID then

        trigger.action.smoke( ZoneVec3, self.SignalColor.TRIGGERCOLOR  )
        Signalled = true

      elseif self.SignalType.ID == CARGO_ZONE.SIGNAL.TYPE.FLARE.ID then
        trigger.action.signalFlare( ZoneVec3, self.SignalColor.TRIGGERCOLOR, 0 )
        Signalled = false

      end
    end
  end

  return Signalled

end

function CARGO_ZONE:WhiteSmoke( SignalHeight )
  self:F()

  self.SignalType = CARGO_ZONE.SIGNAL.TYPE.SMOKE
  self.SignalColor = CARGO_ZONE.SIGNAL.COLOR.WHITE

  if SignalHeight then
    self.SignalHeight = SignalHeight
  end

  return self
end

function CARGO_ZONE:BlueSmoke( SignalHeight )
  self:F()

  self.SignalType = CARGO_ZONE.SIGNAL.TYPE.SMOKE
  self.SignalColor = CARGO_ZONE.SIGNAL.COLOR.BLUE

  if SignalHeight then
    self.SignalHeight = SignalHeight
  end

  return self
end

function CARGO_ZONE:RedSmoke( SignalHeight )
  self:F()

  self.SignalType = CARGO_ZONE.SIGNAL.TYPE.SMOKE
  self.SignalColor = CARGO_ZONE.SIGNAL.COLOR.RED

  if SignalHeight then
    self.SignalHeight = SignalHeight
  end

  return self
end

function CARGO_ZONE:OrangeSmoke( SignalHeight )
  self:F()

  self.SignalType = CARGO_ZONE.SIGNAL.TYPE.SMOKE
  self.SignalColor = CARGO_ZONE.SIGNAL.COLOR.ORANGE

  if SignalHeight then
    self.SignalHeight = SignalHeight
  end

  return self
end

function CARGO_ZONE:GreenSmoke( SignalHeight )
  self:F()

  self.SignalType = CARGO_ZONE.SIGNAL.TYPE.SMOKE
  self.SignalColor = CARGO_ZONE.SIGNAL.COLOR.GREEN

  if SignalHeight then
    self.SignalHeight = SignalHeight
  end

  return self
end


function CARGO_ZONE:WhiteFlare( SignalHeight )
  self:F()

  self.SignalType = CARGO_ZONE.SIGNAL.TYPE.FLARE
  self.SignalColor = CARGO_ZONE.SIGNAL.COLOR.WHITE

  if SignalHeight then
    self.SignalHeight = SignalHeight
  end

  return self
end

function CARGO_ZONE:RedFlare( SignalHeight )
  self:F()

  self.SignalType = CARGO_ZONE.SIGNAL.TYPE.FLARE
  self.SignalColor = CARGO_ZONE.SIGNAL.COLOR.RED

  if SignalHeight then
    self.SignalHeight = SignalHeight
  end

  return self
end

function CARGO_ZONE:GreenFlare( SignalHeight )
  self:F()

  self.SignalType = CARGO_ZONE.SIGNAL.TYPE.FLARE
  self.SignalColor = CARGO_ZONE.SIGNAL.COLOR.GREEN

  if SignalHeight then
    self.SignalHeight = SignalHeight
  end

  return self
end

function CARGO_ZONE:YellowFlare( SignalHeight )
  self:F()

  self.SignalType = CARGO_ZONE.SIGNAL.TYPE.FLARE
  self.SignalColor = CARGO_ZONE.SIGNAL.COLOR.YELLOW

  if SignalHeight then
    self.SignalHeight = SignalHeight
  end

  return self
end


function CARGO_ZONE:GetCargoHostUnit()
  self:F( self )

  if self.CargoHostSpawn then
    local CargoHostGroup = self.CargoHostSpawn:GetGroupFromIndex(1)
    if CargoHostGroup and CargoHostGroup:IsAlive() then
      local CargoHostUnit = CargoHostGroup:GetUnit(1)
      if CargoHostUnit and CargoHostUnit:IsAlive() then
        return CargoHostUnit
      end
    end
  end

  return nil
end

function CARGO_ZONE:GetCargoZoneName()
  self:F()

  return self.CargoZoneName
end








