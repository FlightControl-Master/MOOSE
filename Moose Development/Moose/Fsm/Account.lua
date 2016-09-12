--- (SP) (MP) (FSM) Account for (Detect, count and report) DCS events occuring on DCS objects (units).
-- 
-- ===
-- 
-- # @{#ACCOUNT} FSM class, extends @{Process#PROCESS}
-- 
-- ## ACCOUNT state machine:
-- 
-- This class is a state machine: it manages a process that is triggered by events causing state transitions to occur.
-- All derived classes from this class will start with the class name, followed by a \_. See the relevant derived class descriptions below.
-- Each derived class follows exactly the same process, using the same events and following the same state transitions, 
-- but will have **different implementation behaviour** upon each event or state transition.
-- 
-- ### ACCOUNT **Events**:
-- 
-- These are the events defined in this class:
-- 
--   * **Start**:  The process is started. The process will go into the Report state.
--   * **Event**:  A relevant event has occured that needs to be accounted for. The process will go into the Account state.
--   * **Report**: The process is reporting to the player the accounting status of the DCS events.
--   * **More**:  There are more DCS events that need to be accounted for. The process will go back into the Report state.
--   * **NoMore**:  There are no more DCS events that need to be accounted for. The process will go into the Success state.
-- 
-- ### ACCOUNT **Event methods**:
-- 
-- Event methods are available (dynamically allocated by the state machine), that accomodate for state transitions occurring in the process.
-- There are two types of event methods, which you can use to influence the normal mechanisms in the state machine:
-- 
--   * **Immediate**: The event method has exactly the name of the event.
--   * **Delayed**: The event method starts with a __ + the name of the event. The first parameter of the event method is a number value, expressing the delay in seconds when the event will be executed. 
-- 
-- ### ACCOUNT **States**:
-- 
--   * **Assigned**: The player is assigned to the task. This is the initialization state for the process.
--   * **Waiting**: the process is waiting for a DCS event to occur within the simulator. This state is set automatically.
--   * **Report**: The process is Reporting to the players in the group of the unit. This state is set automatically every 30 seconds.
--   * **Account**: The relevant DCS event has occurred, and is accounted for.
--   * **Success (*)**: All DCS events were accounted for. 
--   * **Failed (*)**: The process has failed.
--   
-- (*) End states of the process.
--   
-- ### ACCOUNT state transition methods:
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
-- # 1) @{#ACCOUNT_DEADS} FSM class, extends @{Account#ACCOUNT}
-- 
-- The ACCOUNT_DEADS class accounts (detects, counts and reports) successful kills of DCS units.
-- The process is given a @{Set} of units that will be tracked upon successful destruction.
-- The process will end after each target has been successfully destroyed.
-- Each successful dead will trigger an Account state transition that can be scored, modified or administered.
-- 
-- 
-- ## ACCOUNT_DEADS constructor:
-- 
--   * @{#ACCOUNT_DEADS.New}(): Creates a new ACCOUNT_DEADS object.
-- 
-- === 
-- 
-- @module Account


do -- ACCOUNT
  
  --- ACCOUNT class
  -- @type ACCOUNT
  -- @field Set#SET_UNIT TargetSetUnit
  -- @extends Process#PROCESS
  ACCOUNT = { 
    ClassName = "ACCOUNT",
    TargetSetUnit = nil,
  }
  
  --- Creates a new DESTROY process.
  -- @param #ACCOUNT self
  -- @return #ACCOUNT
  function ACCOUNT:New()
  
    local FSMT = {
      initial = 'Assigned',
      events = {
        { name = 'Start',         from = 'Assigned',        to = 'Waiting'  },
        { name = 'Wait',          from = '*',               to = 'Waiting'  },
        { name = 'Report',        from = '*',               to = 'Report'  },
        { name = 'Event',         from = '*',               to = 'Account' },
        { name = 'More',          from = 'Account',         to = 'Wait'  },
        { name = 'NoMore',        from = 'Account',         to = 'Success' },      
        { name = 'Fail',          from = '*',               to = 'Failed' },
      },
      endstates = { 'Success', 'Failed' }
    }
  
    -- Inherits from BASE
    local self = BASE:Inherit( self, PROCESS:New( FSMT, "ACCOUNT" ) ) -- #ACCOUNT
    
    self.DisplayInterval = 30
    self.DisplayCount = 30
    self.DisplayMessage = true
    self.DisplayTime = 10 -- 10 seconds is the default
    self.DisplayCategory = "HQ" -- Targets is the default display category
  
    return self
  end

  --- Process Events
  
  --- StateMachine callback function
  -- @param #ACCOUNT self
  -- @param Controllable#CONTROLLABLE ProcessUnit
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  function ACCOUNT:onafterStart( ProcessUnit, Event, From, To )
  
    self:__Wait( 1 )
  end
  
    --- StateMachine callback function
    -- @param #ACCOUNT self
    -- @param Controllable#CONTROLLABLE ProcessUnit
    -- @param #string Event
    -- @param #string From
    -- @param #string To
  function ACCOUNT:onenterWaiting( ProcessUnit, Event, From, To )
  
    if self.DisplayCount >= self.DisplayInterval then
      self:Report()
      self.DisplayCount = 1
    else
      self.DisplayCount = self.DisplayCount + 1
    end
    
    return true -- Process always the event.
  end
  
  --- StateMachine callback function
  -- @param #ACCOUNT self
  -- @param Controllable#CONTROLLABLE ProcessUnit
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  function ACCOUNT:onafterEvent( ProcessUnit, Event, From, To, Event )
  
    self:__NoMore( 1 )
  end
  
end -- ACCOUNT

do -- ACCOUNT_DEADS

  --- ACCOUNT_DEADS class
  -- @type ACCOUNT_DEADS
  -- @field Set#SET_UNIT TargetSetUnit
  -- @extends Process#PROCESS
  ACCOUNT_DEADS = { 
    ClassName = "ACCOUNT_DEADS",
    TargetSetUnit = nil,
  }
  
  
  --- Creates a new DESTROY process.
  -- @param #ACCOUNT_DEADS self
  -- @param Set#SET_UNIT TargetSetUnit
  -- @param #string TaskName
  -- @return #ACCOUNT_DEADS self
  function ACCOUNT_DEADS:New( TargetSetUnit, TaskName )
  
    -- Inherits from BASE
    local self = BASE:Inherit( self, ACCOUNT:New() ) -- #ACCOUNT_DEADS
    
    self.TargetSetUnit = TargetSetUnit
    self.TaskName = TaskName
  
    _EVENTDISPATCHER:OnDead( self.EventDead, self )
    
    return self
  end
  
  --- Process Events
  
  --- StateMachine callback function
  -- @param #ASSIGN_MENU_ACCEPT self
  -- @param Controllable#CONTROLLABLE ProcessUnit
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  function ACCOUNT_DEADS:onenterReport( ProcessUnit, Event, From, To )
  
    local TaskGroup = ProcessUnit:GetGroup()
    MESSAGE:New( "Your group with assigned " .. self.TaskName .. " task has " .. self.TargetSetUnit:GetUnitTypesText() .. " targets left to be destroyed.", 5, "HQ" ):ToGroup( TaskGroup )
  end
  
  
  --- StateMachine callback function
  -- @param #ASSIGN_MENU_ACCEPT self
  -- @param Controllable#CONTROLLABLE ProcessUnit
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  function ACCOUNT_DEADS:onenterAccount( ProcessUnit, Event, From, To, Event )
  
    self.TargetSetUnit:Flush()
    
    if self.TargetSetUnit:FindUnit( Event.IniUnitName ) then
      self.TargetSetUnit:RemoveUnitsByName( Event.IniUnitName )
      local TaskGroup = ProcessUnit:GetGroup()
      MESSAGE:New( "You hit a target. Your group with assigned " .. self.TaskName .. " task has " .. self.TargetSetUnit:Count() .. " targets ( " .. self.TargetSetUnit:GetUnitTypesText() .. " ) left to be destroyed.", 15, "HQ" ):ToGroup( TaskGroup )
    end
  end
  
  --- StateMachine callback function
  -- @param #ASSIGN_MENU_ACCEPT self
  -- @param Controllable#CONTROLLABLE ProcessUnit
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  function ACCOUNT_DEADS:onafterEvent( ProcessUnit, Event, From, To, Event )
  
    if self.TargetSetUnit:Count() > 0 then
      self:__More( 1 )
    else
      self:__NoMore( 1 )
    end
  end
  
  --- DCS Events
  
  --- @param #ACCOUNT_DEADS self
  -- @param Event#EVENTDATA Event
  function ACCOUNT_DEADS:EventDead( Event )
  
    if Event.IniDCSUnit then
      self:__Event( 1 )
    end
  end

end -- ACCOUNT DEADS