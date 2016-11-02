--- (SP) (MP) (FSM) Accept or reject process for player (task) assignments.
-- 
-- ===
-- 
-- # @{#ASSIGN} FSM class, extends @{Process#PROCESS}
-- 
-- ## ASSIGN state machine:
-- 
-- This class is a state machine: it manages a process that is triggered by events causing state transitions to occur.
-- All derived classes from this class will start with the class name, followed by a \_. See the relevant derived class descriptions below.
-- Each derived class follows exactly the same process, using the same events and following the same state transitions, 
-- but will have **different implementation behaviour** upon each event or state transition.
-- 
-- ### ASSIGN **Events**:
-- 
-- These are the events defined in this class:
-- 
--   * **Start**:  Start the tasking acceptance process.
--   * **Assign**:  Assign the task.
--   * **Reject**:  Reject the task..
-- 
-- ### ASSIGN **Event methods**:
-- 
-- Event methods are available (dynamically allocated by the state machine), that accomodate for state transitions occurring in the process.
-- There are two types of event methods, which you can use to influence the normal mechanisms in the state machine:
-- 
--   * **Immediate**: The event method has exactly the name of the event.
--   * **Delayed**: The event method starts with a __ + the name of the event. The first parameter of the event method is a number value, expressing the delay in seconds when the event will be executed. 
-- 
-- ### ASSIGN **States**:
-- 
--   * **UnAssigned**: The player has not accepted the task.
--   * **Assigned (*)**: The player has accepted the task.
--   * **Rejected (*)**: The player has not accepted the task.
--   * **Waiting**: The process is awaiting player feedback.
--   * **Failed (*)**: The process has failed.
--   
-- (*) End states of the process.
--   
-- ### ASSIGN state transition methods:
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
-- # 1) @{#ASSIGN_ACCEPT} class, extends @{Assign#ASSIGN}
-- 
-- The ASSIGN_ACCEPT class accepts by default a task for a player. No player intervention is allowed to reject the task.
-- 
-- ## 1.1) ASSIGN_ACCEPT constructor:
--   
--   * @{#ASSIGN_ACCEPT.New}(): Creates a new ASSIGN_ACCEPT object.
-- 
-- ===
-- 
-- # 2) @{#ASSIGN_MENU_ACCEPT} class, extends @{Assign#ASSIGN}
-- 
-- The ASSIGN_MENU_ACCEPT class accepts a task when the player accepts the task through an added menu option.
-- This assignment type is useful to conditionally allow the player to choose whether or not he would accept the task.
-- The assignment type also allows to reject the task.
-- 
-- ## 2.1) ASSIGN_MENU_ACCEPT constructor:
-- -----------------------------------------
--   
--   * @{#ASSIGN_MENU_ACCEPT.New}(): Creates a new ASSIGN_MENU_ACCEPT object.
-- 
-- ===
-- 
-- @module Assign


do -- ASSIGN

  --- ASSIGN class
  -- @type ASSIGN
  -- @field Task#TASK_BASE Task
  -- @field Unit#UNIT ProcessUnit
  -- @field Zone#ZONE_BASE TargetZone
  -- @extends Process#PROCESS
  ASSIGN = { 
    ClassName = "ASSIGN",
  }
  
  
  --- Creates a new task assignment state machine. The process will accept the task by default, no player intervention accepted.
  -- @param #ASSIGN self
  -- @return #ASSIGN The task acceptance process.
  function ASSIGN:New()

    local FSMT = {
      initial = 'UnAssigned',
      events = {
        { name = 'Start',           from = 'UnAssigned',              to = 'Waiting' },
        { name = 'Assign',          from = 'Waiting',                 to = 'Assigned' },
        { name = 'Reject',          from = 'Waiting',                 to = 'Rejected' },
        { name = 'Fail',            from = '*',                       to = 'Failed' },
      },
      endstates = {
        'Assigned', 'Rejected', 'Failed'
      },
    }
  
    -- Inherits from BASE
    local self = BASE:Inherit( self, PROCESS:New( FSMT, "ASSIGN" ) ) -- #ASSIGN
    
    return self
  end
  
end -- ASSIGN



do -- ASSIGN_ACCEPT

  --- ASSIGN_ACCEPT class
  -- @type ASSIGN_ACCEPT
  -- @field Task#TASK_BASE Task
  -- @field Unit#UNIT ProcessUnit
  -- @field Zone#ZONE_BASE TargetZone
  -- @extends Process#PROCESS
  ASSIGN_ACCEPT = { 
    ClassName = "ASSIGN_ACCEPT",
  }
  
  
  --- Creates a new task assignment state machine. The process will accept the task by default, no player intervention accepted.
  -- @param #ASSIGN_ACCEPT self
  -- @param #string TaskBriefing
  -- @return #ASSIGN_ACCEPT The task acceptance process.
  function ASSIGN_ACCEPT:New( TaskBriefing )

    -- Inherits from BASE
    local self = BASE:Inherit( self, ASSIGN:New() ) -- #ASSIGN_ACCEPT
    
    self.TaskBriefing = TaskBriefing
    
    return self
  end


  --- StateMachine callback function
  -- @param #ASSIGN_ACCEPT self
  -- @param Controllable#CONTROLLABLE ProcessUnit
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  function ASSIGN_ACCEPT:onafterStart( ProcessUnit, Event, From, To )
    self:E( { ProcessUnit, Event, From, To } )
  
    MESSAGE:New( self.TaskBriefing, 30, "Task Assignment" ):ToGroup( ProcessUnit:GetGroup() )

    self:__Assign( 1 )   
  end
  
end -- ASSIGN_ACCEPT


do -- ASSIGN_MENU_ACCEPT

  --- ASSIGN_MENU_ACCEPT class
  -- @type ASSIGN_MENU_ACCEPT
  -- @field Task#TASK_BASE Task
  -- @field Unit#UNIT ProcessUnit
  -- @field Zone#ZONE_BASE TargetZone
  -- @extends Task2#TASK2
  ASSIGN_MENU_ACCEPT = { 
    ClassName = "ASSIGN_MENU_ACCEPT",
  }
  
  
  --- Creates a new task assignment state machine. The process will request from the menu if it accepts the task, if not, the unit is removed from the simulator.
  -- @param #ASSIGN_MENU_ACCEPT self
  -- @param #string TaskName
  -- @param #string TaskBriefing
  -- @return #ASSIGN_MENU_ACCEPT self
  function ASSIGN_MENU_ACCEPT:New( TaskName, TaskBriefing )
  
    -- Inherits from BASE
    local self = BASE:Inherit( self, ASSIGN:New() ) -- #ASSIGN_MENU_ACCEPT
    
    self.TaskBriefing = TaskBriefing
    self.TaskName = TaskName

    return self
  end
  
  --- StateMachine callback function
  -- @param #ASSIGN_MENU_ACCEPT self
  -- @param Controllable#CONTROLLABLE ProcessUnit
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  function ASSIGN_MENU_ACCEPT:onafterStart( ProcessUnit, Event, From, To )
    self:E( { ProcessUnit, Event, From, To } )
  
    MESSAGE:New( self.TaskBriefing .. "\nAccess the radio menu to accept the task. You have 30 seconds or the assignment will be cancelled.", 30, "Task Assignment" ):ToGroup( ProcessUnit:GetGroup() )
   
    local ProcessGroup = ProcessUnit:GetGroup() 
    
    self.Menu = MENU_GROUP:New( ProcessGroup, "Task " .. self.TaskName .. " acceptance" )
    self.MenuAcceptTask = MENU_GROUP_COMMAND:New( ProcessGroup, "Accept task " .. self.TaskName, self.Menu, self.MenuAssign, self )
    self.MenuRejectTask = MENU_GROUP_COMMAND:New( ProcessGroup, "Reject task " .. self.TaskName, self.Menu, self.MenuReject, self )
  end
  
  --- Menu function.
  -- @param #ASSIGN_MENU_ACCEPT self
  function ASSIGN_MENU_ACCEPT:MenuAssign()
    self:E( )
  
    self:__Assign( 1 )
  end
  
  --- Menu function.
  -- @param #ASSIGN_MENU_ACCEPT self
  function ASSIGN_MENU_ACCEPT:MenuReject()
    self:E( )
  
    self:__Reject( 1 )
  end
  
  --- StateMachine callback function
  -- @param #ASSIGN_MENU_ACCEPT self
  -- @param Controllable#CONTROLLABLE ProcessUnit
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  function ASSIGN_MENU_ACCEPT:onafterAssign( ProcessUnit, Event, From, To )
    self:E( { ProcessUnit.UnitNameEvent, From, To } )
  
    self.Menu:Remove()
  end
  
  --- StateMachine callback function
  -- @param #ASSIGN_MENU_ACCEPT self
  -- @param Controllable#CONTROLLABLE ProcessUnit
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  function ASSIGN_MENU_ACCEPT:onafterReject( ProcessUnit, Event, From, To )
    self:E( { ProcessUnit.UnitName, Event, From, To } )
  
    self.Menu:Remove()
    --TODO: need to resolve this problem ... it has to do with the events ...
    --self.Task:UnAssignFromUnit( ProcessUnit )needs to become a callback funtion call upon the event
    ProcessUnit:Destroy()
  end

end -- ASSIGN_MENU_ACCEPT
