--- (SP) (MP) (FSM) Route AI or players through waypoints or to zones.
--
-- ## ACT_ASSIST state machine:
--
-- This class is a state machine: it manages a process that is triggered by events causing state transitions to occur.
-- All derived classes from this class will start with the class name, followed by a \_. See the relevant derived class descriptions below.
-- Each derived class follows exactly the same process, using the same events and following the same state transitions,
-- but will have **different implementation behaviour** upon each event or state transition.
--
-- ### ACT_ASSIST **Events**:
--
-- These are the events defined in this class:
--
--   * **Start**:  The process is started.
--   * **Next**: The process is smoking the targets in the given zone.
--
-- ### ACT_ASSIST **Event methods**:
--
-- Event methods are available (dynamically allocated by the state machine), that accomodate for state transitions occurring in the process.
-- There are two types of event methods, which you can use to influence the normal mechanisms in the state machine:
--
--   * **Immediate**: The event method has exactly the name of the event.
--   * **Delayed**: The event method starts with a __ + the name of the event. The first parameter of the event method is a number value, expressing the delay in seconds when the event will be executed.
--
-- ### ACT_ASSIST **States**:
--
--   * **None**: The controllable did not receive route commands.
--   * **AwaitSmoke (*)**: The process is awaiting to smoke the targets in the zone.
--   * **Smoking (*)**: The process is smoking the targets in the zone.
--   * **Failed (*)**: The process has failed.
--
-- (*) End states of the process.
--
-- ### ACT_ASSIST state transition methods:
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
-- # 1) @{#ACT_ASSIST_SMOKE_TARGETS_ZONE} class, extends @{Core.Fsm.Route#ACT_ASSIST}
--
-- The ACT_ASSIST_SMOKE_TARGETS_ZONE class implements the core functions to smoke targets in a @{Core.Zone}.
-- The targets are smoked within a certain range around each target, simulating a realistic smoking behaviour.
-- At random intervals, a new target is smoked.
--
-- # 1.1) ACT_ASSIST_SMOKE_TARGETS_ZONE constructor:
--
--   * @{#ACT_ASSIST_SMOKE_TARGETS_ZONE.New}(): Creates a new ACT_ASSIST_SMOKE_TARGETS_ZONE object.
--
-- ===
--
-- @module Actions.Act_Assist
-- @image MOOSE.JPG


do -- ACT_ASSIST

  --- ACT_ASSIST class
  -- @type ACT_ASSIST
  -- @extends Core.Fsm#FSM_PROCESS
  ACT_ASSIST = {
    ClassName = "ACT_ASSIST",
  }

  --- Creates a new target smoking state machine. The process will request from the menu if it accepts the task, if not, the unit is removed from the simulator.
  -- @param #ACT_ASSIST self
  -- @return #ACT_ASSIST
  function ACT_ASSIST:New()

    -- Inherits from BASE
    local self = BASE:Inherit( self, FSM_PROCESS:New( "ACT_ASSIST" ) ) -- Core.Fsm#FSM_PROCESS

    self:AddTransition( "None", "Start", "AwaitSmoke" )
    self:AddTransition( "AwaitSmoke", "Next", "Smoking" )
    self:AddTransition( "Smoking", "Next", "AwaitSmoke" )
    self:AddTransition( "*", "Stop", "Success" )
    self:AddTransition( "*", "Fail", "Failed" )

    self:AddEndState( "Failed" )
    self:AddEndState( "Success" )

    self:SetStartState( "None" )

    return self
  end

  --- Task Events

  --- StateMachine callback function
  -- @param #ACT_ASSIST self
  -- @param Wrapper.Controllable#CONTROLLABLE ProcessUnit
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  function ACT_ASSIST:onafterStart( ProcessUnit, From, Event, To )

    local ProcessGroup = ProcessUnit:GetGroup()
    local MissionMenu = self:GetMission():GetMenu( ProcessGroup )

    local function MenuSmoke( MenuParam )
      local self = MenuParam.self
      local SmokeColor = MenuParam.SmokeColor
      self.SmokeColor = SmokeColor
      self:__Next( 1 )
    end

    self.Menu = MENU_GROUP:New( ProcessGroup, "Target acquisition", MissionMenu )
    self.MenuSmokeBlue   = MENU_GROUP_COMMAND:New( ProcessGroup, "Drop blue smoke on targets", self.Menu, MenuSmoke, { self = self, SmokeColor = SMOKECOLOR.Blue } )
    self.MenuSmokeGreen  = MENU_GROUP_COMMAND:New( ProcessGroup, "Drop green smoke on targets", self.Menu, MenuSmoke, { self = self, SmokeColor = SMOKECOLOR.Green } )
    self.MenuSmokeOrange = MENU_GROUP_COMMAND:New( ProcessGroup, "Drop Orange smoke on targets", self.Menu, MenuSmoke, { self = self, SmokeColor = SMOKECOLOR.Orange } )
    self.MenuSmokeRed    = MENU_GROUP_COMMAND:New( ProcessGroup, "Drop Red smoke on targets", self.Menu, MenuSmoke, { self = self, SmokeColor = SMOKECOLOR.Red } )
    self.MenuSmokeWhite  = MENU_GROUP_COMMAND:New( ProcessGroup, "Drop White smoke on targets", self.Menu, MenuSmoke, { self = self, SmokeColor = SMOKECOLOR.White } )
  end

  --- StateMachine callback function
  -- @param #ACT_ASSIST self
  -- @param Wrapper.Controllable#CONTROLLABLE ProcessUnit
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  function ACT_ASSIST:onafterStop( ProcessUnit, From, Event, To )

    self.Menu:Remove() -- When stopped, remove the menus
  end

end

do -- ACT_ASSIST_SMOKE_TARGETS_ZONE

  --- ACT_ASSIST_SMOKE_TARGETS_ZONE class
  -- @type ACT_ASSIST_SMOKE_TARGETS_ZONE
  -- @field Core.Set#SET_UNIT TargetSetUnit
  -- @field Core.Zone#ZONE_BASE TargetZone
  -- @extends #ACT_ASSIST
  ACT_ASSIST_SMOKE_TARGETS_ZONE = {
    ClassName = "ACT_ASSIST_SMOKE_TARGETS_ZONE",
  }

--  function ACT_ASSIST_SMOKE_TARGETS_ZONE:_Destructor()
--    self:E("_Destructor")
--
--    self.Menu:Remove()
--    self:EventRemoveAll()
--  end

  --- Creates a new target smoking state machine. The process will request from the menu if it accepts the task, if not, the unit is removed from the simulator.
  -- @param #ACT_ASSIST_SMOKE_TARGETS_ZONE self
  -- @param Core.Set#SET_UNIT TargetSetUnit
  -- @param Core.Zone#ZONE_BASE TargetZone
  function ACT_ASSIST_SMOKE_TARGETS_ZONE:New( TargetSetUnit, TargetZone )
    local self = BASE:Inherit( self, ACT_ASSIST:New() ) -- #ACT_ASSIST

    self.TargetSetUnit = TargetSetUnit
    self.TargetZone = TargetZone

    return self
  end

  function ACT_ASSIST_SMOKE_TARGETS_ZONE:Init( FsmSmoke )

    self.TargetSetUnit = FsmSmoke.TargetSetUnit
    self.TargetZone = FsmSmoke.TargetZone
  end

  --- Creates a new target smoking state machine. The process will request from the menu if it accepts the task, if not, the unit is removed from the simulator.
  -- @param #ACT_ASSIST_SMOKE_TARGETS_ZONE self
  -- @param Core.Set#SET_UNIT TargetSetUnit
  -- @param Core.Zone#ZONE_BASE TargetZone
  -- @return #ACT_ASSIST_SMOKE_TARGETS_ZONE self
  function ACT_ASSIST_SMOKE_TARGETS_ZONE:Init( TargetSetUnit, TargetZone )

    self.TargetSetUnit = TargetSetUnit
    self.TargetZone = TargetZone

    return self
  end

  --- StateMachine callback function
  -- @param #ACT_ASSIST_SMOKE_TARGETS_ZONE self
  -- @param Wrapper.Controllable#CONTROLLABLE ProcessUnit
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  function ACT_ASSIST_SMOKE_TARGETS_ZONE:onenterSmoking( ProcessUnit, From, Event, To )

    self.TargetSetUnit:ForEachUnit(
      --- @param Wrapper.Unit#UNIT SmokeUnit
      function( SmokeUnit )
        if math.random( 1, ( 100 * self.TargetSetUnit:Count() ) / 4 ) <= 100 then
          SCHEDULER:New( self,
            function()
              if SmokeUnit:IsAlive() then
                SmokeUnit:Smoke( self.SmokeColor, 150 )
              end
            end, {}, math.random( 10, 60 )
          )
        end
      end
    )

  end

end
