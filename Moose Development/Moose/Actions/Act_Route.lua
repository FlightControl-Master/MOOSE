--- (SP) (MP) (FSM) Route AI or players through waypoints or to zones.
--
-- ===
--
-- # @{#ACT_ROUTE} FSM class, extends @{Core.Fsm#FSM_PROCESS}
--
-- ## ACT_ROUTE state machine:
--
-- This class is a state machine: it manages a process that is triggered by events causing state transitions to occur.
-- All derived classes from this class will start with the class name, followed by a \_. See the relevant derived class descriptions below.
-- Each derived class follows exactly the same process, using the same events and following the same state transitions,
-- but will have **different implementation behaviour** upon each event or state transition.
--
-- ### ACT_ROUTE **Events**:
--
-- These are the events defined in this class:
--
--   * **Start**:  The process is started. The process will go into the Report state.
--   * **Report**: The process is reporting to the player the route to be followed.
--   * **Route**: The process is routing the controllable.
--   * **Pause**: The process is pausing the route of the controllable.
--   * **Arrive**: The controllable has arrived at a route point.
--   * **More**:  There are more route points that need to be followed. The process will go back into the Report state.
--   * **NoMore**:  There are no more route points that need to be followed. The process will go into the Success state.
--
-- ### ACT_ROUTE **Event methods**:
--
-- Event methods are available (dynamically allocated by the state machine), that accomodate for state transitions occurring in the process.
-- There are two types of event methods, which you can use to influence the normal mechanisms in the state machine:
--
--   * **Immediate**: The event method has exactly the name of the event.
--   * **Delayed**: The event method starts with a __ + the name of the event. The first parameter of the event method is a number value, expressing the delay in seconds when the event will be executed.
--
-- ### ACT_ROUTE **States**:
--
--   * **None**: The controllable did not receive route commands.
--   * **Arrived (*)**: The controllable has arrived at a route point.
--   * **Aborted (*)**: The controllable has aborted the route path.
--   * **Routing**: The controllable is understay to the route point.
--   * **Pausing**: The process is pausing the routing. AI air will go into hover, AI ground will stop moving. Players can fly around.
--   * **Success (*)**: All route points were reached.
--   * **Failed (*)**: The process has failed.
--
-- (*) End states of the process.
--
-- ### ACT_ROUTE state transition methods:
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
-- ===
--
-- # 1) @{#ACT_ROUTE_ZONE} class, extends @{Core.Fsm.Route#ACT_ROUTE}
--
-- The ACT_ROUTE_ZONE class implements the core functions to route an AIR @{Wrapper.Controllable} player @{Wrapper.Unit} to a @{Core.Zone}.
-- The player receives on perioding times messages with the coordinates of the route to follow.
-- Upon arrival at the zone, a confirmation of arrival is sent, and the process will be ended.
--
-- # 1.1) ACT_ROUTE_ZONE constructor:
--
--   * @{#ACT_ROUTE_ZONE.New}(): Creates a new ACT_ROUTE_ZONE object.
--
-- ===
--
-- @module Actions.Act_Route
-- @image MOOSE.JPG


do -- ACT_ROUTE

  --- ACT_ROUTE class
  -- @type ACT_ROUTE
  -- @field Tasking.Task#TASK TASK
  -- @field Wrapper.Unit#UNIT ProcessUnit
  -- @field Core.Zone#ZONE_BASE Zone
  -- @field Core.Point#COORDINATE Coordinate
  -- @extends Core.Fsm#FSM_PROCESS
  ACT_ROUTE = {
    ClassName = "ACT_ROUTE",
  }


  --- Creates a new routing state machine. The process will route a CLIENT to a ZONE until the CLIENT is within that ZONE.
  -- @param #ACT_ROUTE self
  -- @return #ACT_ROUTE self
  function ACT_ROUTE:New()

    -- Inherits from BASE
    local self = BASE:Inherit( self, FSM_PROCESS:New( "ACT_ROUTE" ) ) -- Core.Fsm#FSM_PROCESS

    self:AddTransition( "*", "Reset", "None" )
    self:AddTransition( "None", "Start", "Routing" )
    self:AddTransition( "*", "Report", "*" )
    self:AddTransition( "Routing", "Route", "Routing" )
    self:AddTransition( "Routing", "Pause", "Pausing" )
    self:AddTransition( "Routing", "Arrive", "Arrived" )
    self:AddTransition( "*", "Cancel", "Cancelled" )
    self:AddTransition( "Arrived", "Success", "Success" )
    self:AddTransition( "*", "Fail", "Failed" )
    self:AddTransition( "", "", "" )
    self:AddTransition( "", "", "" )

    self:AddEndState( "Arrived" )
    self:AddEndState( "Failed" )
    self:AddEndState( "Cancelled" )

    self:SetStartState( "None" )

    self:SetRouteMode( "C" )

    return self
  end

  --- Set a Cancel Menu item.
  -- @param #ACT_ROUTE self
  -- @return #ACT_ROUTE
  function ACT_ROUTE:SetMenuCancel( MenuGroup, MenuText, ParentMenu, MenuTime, MenuTag )

    self.CancelMenuGroupCommand = MENU_GROUP_COMMAND:New(
      MenuGroup,
      MenuText,
      ParentMenu,
      self.MenuCancel,
      self
    ):SetTime( MenuTime ):SetTag( MenuTag )

    ParentMenu:SetTime( MenuTime )

    ParentMenu:Remove( MenuTime, MenuTag )

    return self
  end

  --- Set the route mode.
  -- There are 2 route modes supported:
  --
  --   * SetRouteMode( "B" ): Route mode is Bearing and Range.
  --   * SetRouteMode( "C" ): Route mode is LL or MGRS according coordinate system setup.
  --
  -- @param #ACT_ROUTE self
  -- @return #ACT_ROUTE
  function ACT_ROUTE:SetRouteMode( RouteMode )

    self.RouteMode = RouteMode

    return self
  end

  --- Get the routing text to be displayed.
  -- The route mode determines the text displayed.
  -- @param #ACT_ROUTE self
  -- @param Wrapper.Unit#UNIT Controllable
  -- @return #string
  function ACT_ROUTE:GetRouteText( Controllable )

    local RouteText = ""

    local Coordinate = nil -- Core.Point#COORDINATE

    if self.Coordinate then
      Coordinate = self.Coordinate
    end

    if self.Zone then
      Coordinate = self.Zone:GetPointVec3( self.Altitude )
      Coordinate:SetHeading( self.Heading )
    end


    local Task = self:GetTask() -- This is to dermine that the coordinates are for a specific task mode (A2A or A2G).
    local CC = self:GetTask():GetMission():GetCommandCenter()
    if CC then
      if CC:IsModeWWII() then
        -- Find closest reference point to the target.
        local ShortestDistance = 0
        local ShortestReferencePoint = nil
        local ShortestReferenceName = ""
        self:F( { CC.ReferencePoints } )
        for ZoneName, Zone in pairs( CC.ReferencePoints ) do
          self:F( { ZoneName = ZoneName } )
          local Zone = Zone -- Core.Zone#ZONE
          local ZoneCoord = Zone:GetCoordinate()
          local ZoneDistance = ZoneCoord:Get2DDistance( Coordinate )
          self:F( { ShortestDistance, ShortestReferenceName } )
          if ShortestDistance == 0 or ZoneDistance < ShortestDistance then
            ShortestDistance = ZoneDistance
            ShortestReferencePoint = ZoneCoord
            ShortestReferenceName = CC.ReferenceNames[ZoneName]
          end
        end
        if ShortestReferencePoint then
          RouteText = Coordinate:ToStringFromRP( ShortestReferencePoint, ShortestReferenceName, Controllable )
        end
      else
        RouteText = Coordinate:ToString( Controllable, nil, Task )
      end
    end

    return RouteText
  end


  function ACT_ROUTE:MenuCancel()
    self:F("Cancelled")
    self.CancelMenuGroupCommand:Remove()
    self:__Cancel( 1 )
  end

  --- Task Events

  --- StateMachine callback function
  -- @param #ACT_ROUTE self
  -- @param Wrapper.Unit#UNIT ProcessUnit
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  function ACT_ROUTE:onafterStart( ProcessUnit, From, Event, To )


    self:__Route( 1 )
  end

  --- Check if the controllable has arrived.
  -- @param #ACT_ROUTE self
  -- @param Wrapper.Unit#UNIT ProcessUnit
  -- @return #boolean
  function ACT_ROUTE:onfuncHasArrived( ProcessUnit )
    return false
  end

  --- StateMachine callback function
  -- @param #ACT_ROUTE self
  -- @param Wrapper.Unit#UNIT ProcessUnit
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  function ACT_ROUTE:onbeforeRoute( ProcessUnit, From, Event, To )

    if ProcessUnit:IsAlive() then
      local HasArrived = self:onfuncHasArrived( ProcessUnit ) -- Polymorphic
      if self.DisplayCount >= self.DisplayInterval then
        self:T( { HasArrived = HasArrived } )
        if not HasArrived then
          self:Report()
        end
        self.DisplayCount = 1
      else
        self.DisplayCount = self.DisplayCount + 1
      end

      if HasArrived then
        self:__Arrive( 1 )
      else
        self:__Route( 1 )
      end

      return HasArrived -- if false, then the event will not be executed...
    end

    return false

  end

end -- ACT_ROUTE


do -- ACT_ROUTE_POINT

  --- ACT_ROUTE_POINT class
  -- @type ACT_ROUTE_POINT
  -- @field Tasking.Task#TASK TASK
  -- @extends #ACT_ROUTE
  ACT_ROUTE_POINT = {
    ClassName = "ACT_ROUTE_POINT",
  }


  --- Creates a new routing state machine.
  -- The task will route a controllable to a Coordinate until the controllable is within the Range.
  -- @param #ACT_ROUTE_POINT self
  -- @param Core.Point#COORDINATE The Coordinate to Target.
  -- @param #number Range The Distance to Target.
  -- @param Core.Zone#ZONE_BASE Zone
  function ACT_ROUTE_POINT:New( Coordinate, Range )
    local self = BASE:Inherit( self, ACT_ROUTE:New() ) -- #ACT_ROUTE_POINT

    self.Coordinate = Coordinate
    self.Range = Range or 0

    self.DisplayInterval = 30
    self.DisplayCount = 30
    self.DisplayMessage = true
    self.DisplayTime = 10 -- 10 seconds is the default

    return self
  end

  --- Creates a new routing state machine.
  -- The task will route a controllable to a Coordinate until the controllable is within the Range.
  -- @param #ACT_ROUTE_POINT self
  function ACT_ROUTE_POINT:Init( FsmRoute )

    self.Coordinate = FsmRoute.Coordinate
    self.Range = FsmRoute.Range or 0

    self.DisplayInterval = 30
    self.DisplayCount = 30
    self.DisplayMessage = true
    self.DisplayTime = 10 -- 10 seconds is the default
    self:SetStartState("None")
  end

  --- Set Coordinate
  -- @param #ACT_ROUTE_POINT self
  -- @param Core.Point#COORDINATE Coordinate The Coordinate to route to.
  function ACT_ROUTE_POINT:SetCoordinate( Coordinate )
    self:F2( { Coordinate } )
    self.Coordinate = Coordinate
  end

  --- Get Coordinate
  -- @param #ACT_ROUTE_POINT self
  -- @return Core.Point#COORDINATE Coordinate The Coordinate to route to.
  function ACT_ROUTE_POINT:GetCoordinate()
    self:F2( { self.Coordinate } )
    return self.Coordinate
  end

  --- Set Range around Coordinate
  -- @param #ACT_ROUTE_POINT self
  -- @param #number Range The Range to consider the arrival. Default is 10000 meters.
  function ACT_ROUTE_POINT:SetRange( Range )
    self:F2( { Range } )
    self.Range = Range or 10000
  end

  --- Get Range around Coordinate
  -- @param #ACT_ROUTE_POINT self
  -- @return #number The Range to consider the arrival. Default is 10000 meters.
  function ACT_ROUTE_POINT:GetRange()
    self:F2( { self.Range } )
    return self.Range
  end

  --- Method override to check if the controllable has arrived.
  -- @param #ACT_ROUTE_POINT self
  -- @param Wrapper.Unit#UNIT ProcessUnit
  -- @return #boolean
  function ACT_ROUTE_POINT:onfuncHasArrived( ProcessUnit )

    if ProcessUnit:IsAlive() then
      local Distance = self.Coordinate:Get2DDistance( ProcessUnit:GetCoordinate() )

      if Distance <= self.Range then
        local RouteText = "Task \"" .. self:GetTask():GetName() .. "\", you have arrived."
        self:GetCommandCenter():MessageTypeToGroup( RouteText, ProcessUnit:GetGroup(), MESSAGE.Type.Information )
        return true
      end
    end

    return false
  end

  --- Task Events

  --- StateMachine callback function
  -- @param #ACT_ROUTE_POINT self
  -- @param Wrapper.Unit#UNIT ProcessUnit
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  function ACT_ROUTE_POINT:onafterReport( ProcessUnit, From, Event, To )

    local RouteText = "Task \"" .. self:GetTask():GetName() .. "\", " .. self:GetRouteText( ProcessUnit )

    self:GetCommandCenter():MessageTypeToGroup( RouteText, ProcessUnit:GetGroup(), MESSAGE.Type.Update )
  end

end -- ACT_ROUTE_POINT


do -- ACT_ROUTE_ZONE

  --- ACT_ROUTE_ZONE class
  -- @type ACT_ROUTE_ZONE
  -- @field Tasking.Task#TASK TASK
  -- @field Wrapper.Unit#UNIT ProcessUnit
  -- @field Core.Zone#ZONE_BASE Zone
  -- @extends #ACT_ROUTE
  ACT_ROUTE_ZONE = {
    ClassName = "ACT_ROUTE_ZONE",
  }


  --- Creates a new routing state machine. The task will route a controllable to a ZONE until the controllable is within that ZONE.
  -- @param #ACT_ROUTE_ZONE self
  -- @param Core.Zone#ZONE_BASE Zone
  function ACT_ROUTE_ZONE:New( Zone )
    local self = BASE:Inherit( self, ACT_ROUTE:New() ) -- #ACT_ROUTE_ZONE

    self.Zone = Zone

    self.DisplayInterval = 30
    self.DisplayCount = 30
    self.DisplayMessage = true
    self.DisplayTime = 10 -- 10 seconds is the default

    return self
  end

  function ACT_ROUTE_ZONE:Init( FsmRoute )

    self.Zone = FsmRoute.Zone

    self.DisplayInterval = 30
    self.DisplayCount = 30
    self.DisplayMessage = true
    self.DisplayTime = 10 -- 10 seconds is the default
  end

  --- Set Zone
  -- @param #ACT_ROUTE_ZONE self
  -- @param Core.Zone#ZONE_BASE Zone The Zone object where to route to.
  -- @param #number Altitude
  -- @param #number Heading
  function ACT_ROUTE_ZONE:SetZone( Zone, Altitude, Heading ) -- R2.2 Added altitude and heading
    self.Zone = Zone
    self.Altitude = Altitude
    self.Heading = Heading
  end

  --- Get Zone
  -- @param #ACT_ROUTE_ZONE self
  -- @return Core.Zone#ZONE_BASE Zone The Zone object where to route to.
  function ACT_ROUTE_ZONE:GetZone()
    return self.Zone
  end

  --- Method override to check if the controllable has arrived.
  -- @param #ACT_ROUTE self
  -- @param Wrapper.Unit#UNIT ProcessUnit
  -- @return #boolean
  function ACT_ROUTE_ZONE:onfuncHasArrived( ProcessUnit )

    if ProcessUnit:IsInZone( self.Zone ) then
      local RouteText = "Task \"" .. self:GetTask():GetName() .. "\", you have arrived within the zone."
      self:GetCommandCenter():MessageTypeToGroup( RouteText, ProcessUnit:GetGroup(), MESSAGE.Type.Information )
    end

    return ProcessUnit:IsInZone( self.Zone )
  end

  --- Task Events

  --- StateMachine callback function
  -- @param #ACT_ROUTE_ZONE self
  -- @param Wrapper.Unit#UNIT ProcessUnit
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  function ACT_ROUTE_ZONE:onafterReport( ProcessUnit, From, Event, To )
    self:F( { ProcessUnit = ProcessUnit } )

    local RouteText = "Task \"" .. self:GetTask():GetName() .. "\", " .. self:GetRouteText( ProcessUnit )
    self:GetCommandCenter():MessageTypeToGroup( RouteText, ProcessUnit:GetGroup(), MESSAGE.Type.Update )
  end

end -- ACT_ROUTE_ZONE
