--- (SP) (MP) (FSM) Accept or reject process for player (task) assignments.
--
-- ===
--
-- # @{#ACT_ASSIGN} FSM template class, extends @{Core.Fsm#FSM_PROCESS}
--
-- ## ACT_ASSIGN state machine:
--
-- This class is a state machine: it manages a process that is triggered by events causing state transitions to occur.
-- All derived classes from this class will start with the class name, followed by a \_. See the relevant derived class descriptions below.
-- Each derived class follows exactly the same process, using the same events and following the same state transitions,
-- but will have **different implementation behaviour** upon each event or state transition.
--
-- ### ACT_ASSIGN **Events**:
--
-- These are the events defined in this class:
--
--   * **Start**:  Start the tasking acceptance process.
--   * **Assign**:  Assign the task.
--   * **Reject**:  Reject the task..
--
-- ### ACT_ASSIGN **Event methods**:
--
-- Event methods are available (dynamically allocated by the state machine), that accomodate for state transitions occurring in the process.
-- There are two types of event methods, which you can use to influence the normal mechanisms in the state machine:
--
--   * **Immediate**: The event method has exactly the name of the event.
--   * **Delayed**: The event method starts with a __ + the name of the event. The first parameter of the event method is a number value, expressing the delay in seconds when the event will be executed.
--
-- ### ACT_ASSIGN **States**:
--
--   * **UnAssigned**: The player has not accepted the task.
--   * **Assigned (*)**: The player has accepted the task.
--   * **Rejected (*)**: The player has not accepted the task.
--   * **Waiting**: The process is awaiting player feedback.
--   * **Failed (*)**: The process has failed.
--
-- (*) End states of the process.
--
-- ### ACT_ASSIGN state transition methods:
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
-- # 1) @{#ACT_ASSIGN_ACCEPT} class, extends @{Core.Fsm.Assign#ACT_ASSIGN}
--
-- The ACT_ASSIGN_ACCEPT class accepts by default a task for a player. No player intervention is allowed to reject the task.
--
-- ## 1.1) ACT_ASSIGN_ACCEPT constructor:
--
--   * @{#ACT_ASSIGN_ACCEPT.New}(): Creates a new ACT_ASSIGN_ACCEPT object.
--
-- ===
--
-- # 2) @{#ACT_ASSIGN_MENU_ACCEPT} class, extends @{Core.Fsm.Assign#ACT_ASSIGN}
--
-- The ACT_ASSIGN_MENU_ACCEPT class accepts a task when the player accepts the task through an added menu option.
-- This assignment type is useful to conditionally allow the player to choose whether or not he would accept the task.
-- The assignment type also allows to reject the task.
--
-- ## 2.1) ACT_ASSIGN_MENU_ACCEPT constructor:
-- -----------------------------------------
--
--   * @{#ACT_ASSIGN_MENU_ACCEPT.New}(): Creates a new ACT_ASSIGN_MENU_ACCEPT object.
--
-- ===
--
-- @module Actions.Act_Assign
-- @image MOOSE.JPG


do -- ACT_ASSIGN

  --- ACT_ASSIGN class
  -- @type ACT_ASSIGN
  -- @field Tasking.Task#TASK Task
  -- @field Wrapper.Unit#UNIT ProcessUnit
  -- @field Core.Zone#ZONE_BASE TargetZone
  -- @extends Core.Fsm#FSM_PROCESS
  ACT_ASSIGN = {
    ClassName = "ACT_ASSIGN",
  }


  --- Creates a new task assignment state machine. The process will accept the task by default, no player intervention accepted.
  -- @param #ACT_ASSIGN self
  -- @return #ACT_ASSIGN The task acceptance process.
  function ACT_ASSIGN:New()

    -- Inherits from BASE
    local self = BASE:Inherit( self, FSM_PROCESS:New( "ACT_ASSIGN" ) ) -- Core.Fsm#FSM_PROCESS

    self:AddTransition( "UnAssigned", "Start", "Waiting" )
    self:AddTransition( "Waiting",  "Assign", "Assigned" )
    self:AddTransition( "Waiting", "Reject", "Rejected" )
    self:AddTransition( "*", "Fail", "Failed" )

    self:AddEndState( "Assigned" )
    self:AddEndState( "Rejected" )
    self:AddEndState( "Failed" )

    self:SetStartState( "UnAssigned" )

    return self
  end

end -- ACT_ASSIGN



do -- ACT_ASSIGN_ACCEPT

  --- ACT_ASSIGN_ACCEPT class
  -- @type ACT_ASSIGN_ACCEPT
  -- @field Tasking.Task#TASK Task
  -- @field Wrapper.Unit#UNIT ProcessUnit
  -- @field Core.Zone#ZONE_BASE TargetZone
  -- @extends #ACT_ASSIGN
  ACT_ASSIGN_ACCEPT = {
    ClassName = "ACT_ASSIGN_ACCEPT",
  }


  --- Creates a new task assignment state machine. The process will accept the task by default, no player intervention accepted.
  -- @param #ACT_ASSIGN_ACCEPT self
  -- @param #string TaskBriefing
  function ACT_ASSIGN_ACCEPT:New( TaskBriefing )

    local self = BASE:Inherit( self, ACT_ASSIGN:New() ) -- #ACT_ASSIGN_ACCEPT

    self.TaskBriefing = TaskBriefing

    return self
  end

  function ACT_ASSIGN_ACCEPT:Init( FsmAssign )

    self.TaskBriefing = FsmAssign.TaskBriefing
  end

  --- StateMachine callback function
  -- @param #ACT_ASSIGN_ACCEPT self
  -- @param Wrapper.Unit#UNIT ProcessUnit
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  function ACT_ASSIGN_ACCEPT:onafterStart( ProcessUnit, Task, From, Event, To )

    self:__Assign( 1 )
  end

  --- StateMachine callback function
  -- @param #ACT_ASSIGN_ACCEPT self
  -- @param Wrapper.Unit#UNIT ProcessUnit
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  function ACT_ASSIGN_ACCEPT:onenterAssigned( ProcessUnit, Task, From, Event, To, TaskGroup )

    self.Task:Assign( ProcessUnit, ProcessUnit:GetPlayerName() )
  end

end -- ACT_ASSIGN_ACCEPT


do -- ACT_ASSIGN_MENU_ACCEPT

  --- ACT_ASSIGN_MENU_ACCEPT class
  -- @type ACT_ASSIGN_MENU_ACCEPT
  -- @field Tasking.Task#TASK Task
  -- @field Wrapper.Unit#UNIT ProcessUnit
  -- @field Core.Zone#ZONE_BASE TargetZone
  -- @extends #ACT_ASSIGN
  ACT_ASSIGN_MENU_ACCEPT = {
    ClassName = "ACT_ASSIGN_MENU_ACCEPT",
  }

  --- Init.
  -- @param #ACT_ASSIGN_MENU_ACCEPT self
  -- @param #string TaskBriefing
  -- @return #ACT_ASSIGN_MENU_ACCEPT self
  function ACT_ASSIGN_MENU_ACCEPT:New( TaskBriefing )

    -- Inherits from BASE
    local self = BASE:Inherit( self, ACT_ASSIGN:New() ) -- #ACT_ASSIGN_MENU_ACCEPT

    self.TaskBriefing = TaskBriefing

    return self
  end


  --- Creates a new task assignment state machine. The process will request from the menu if it accepts the task, if not, the unit is removed from the simulator.
  -- @param #ACT_ASSIGN_MENU_ACCEPT self
  -- @param #string TaskBriefing
  -- @return #ACT_ASSIGN_MENU_ACCEPT self
  function ACT_ASSIGN_MENU_ACCEPT:Init( TaskBriefing )

    self.TaskBriefing = TaskBriefing

    return self
  end

  --- StateMachine callback function
  -- @param #ACT_ASSIGN_MENU_ACCEPT self
  -- @param Wrapper.Unit#UNIT ProcessUnit
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  function ACT_ASSIGN_MENU_ACCEPT:onafterStart( ProcessUnit, Task, From, Event, To )

    self:GetCommandCenter():MessageToGroup( "Task " .. self.Task:GetName() .. " has been assigned to you and your group!\nRead the briefing and use the Radio Menu (F10) / Task ... CONFIRMATION menu to accept or reject the task.\nYou have 2 minutes to accept, or the task assignment will be cancelled!", ProcessUnit:GetGroup(), 120 )

    local TaskGroup = ProcessUnit:GetGroup()

    self.Menu = MENU_GROUP:New( TaskGroup, "Task " .. self.Task:GetName() .. " CONFIRMATION" )
    self.MenuAcceptTask = MENU_GROUP_COMMAND:New( TaskGroup, "Accept task " .. self.Task:GetName(), self.Menu, self.MenuAssign, self, TaskGroup )
    self.MenuRejectTask = MENU_GROUP_COMMAND:New( TaskGroup, "Reject task " .. self.Task:GetName(), self.Menu, self.MenuReject, self, TaskGroup )

    self:__Reject( 120, TaskGroup )
  end

  --- Menu function.
  -- @param #ACT_ASSIGN_MENU_ACCEPT self
  function ACT_ASSIGN_MENU_ACCEPT:MenuAssign( TaskGroup )

    self:__Assign( -1, TaskGroup )
  end

  --- Menu function.
  -- @param #ACT_ASSIGN_MENU_ACCEPT self
  function ACT_ASSIGN_MENU_ACCEPT:MenuReject( TaskGroup )

    self:__Reject( -1, TaskGroup )
  end

  --- StateMachine callback function
  -- @param #ACT_ASSIGN_MENU_ACCEPT self
  -- @param Wrapper.Unit#UNIT ProcessUnit
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  function ACT_ASSIGN_MENU_ACCEPT:onafterAssign( ProcessUnit, Task, From, Event, To, TaskGroup  )

    self.Menu:Remove()
  end

  --- StateMachine callback function
  -- @param #ACT_ASSIGN_MENU_ACCEPT self
  -- @param Wrapper.Unit#UNIT ProcessUnit
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  function ACT_ASSIGN_MENU_ACCEPT:onafterReject( ProcessUnit, Task, From, Event, To, TaskGroup )
    self:F( { TaskGroup = TaskGroup } )

    self.Menu:Remove()
    --TODO: need to resolve this problem ... it has to do with the events ...
    --self.Task:UnAssignFromUnit( ProcessUnit )needs to become a callback funtion call upon the event
    self.Task:RejectGroup( TaskGroup )
  end

  --- StateMachine callback function
  -- @param #ACT_ASSIGN_ACCEPT self
  -- @param Wrapper.Unit#UNIT ProcessUnit
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  function ACT_ASSIGN_MENU_ACCEPT:onenterAssigned( ProcessUnit, Task, From, Event, To, TaskGroup )

    --self.Task:AssignToGroup( TaskGroup )
    self.Task:Assign( ProcessUnit, ProcessUnit:GetPlayerName() )
  end

end -- ACT_ASSIGN_MENU_ACCEPT
