--- (SP) (MP) (FSM) Account for (Detect, count and report) DCS events occuring on DCS objects (units).
-- 
-- ===
-- 
-- # @{#PROCESS_ACCOUNT} FSM class, extends @{Process#PROCESS}
-- 
-- ## PROCESS_ACCOUNT state machine:
-- 
-- This class is a state machine: it manages a process that is triggered by events causing state transitions to occur.
-- All derived classes from this class will start with the class name, followed by a \_. See the relevant derived class descriptions below.
-- Each derived class follows exactly the same process, using the same events and following the same state transitions, 
-- but will have **different implementation behaviour** upon each event or state transition.
-- 
-- ### PROCESS_ACCOUNT **Events**:
-- 
-- These are the events defined in this class:
-- 
--   * **Start**:  The process is started. The process will go into the Report state.
--   * **Event**:  A relevant event has occured that needs to be accounted for. The process will go into the Account state.
--   * **Report**: The process is reporting to the player the accounting status of the DCS events.
--   * **More**:  There are more DCS events that need to be accounted for. The process will go back into the Report state.
--   * **NoMore**:  There are no more DCS events that need to be accounted for. The process will go into the Success state.
-- 
-- ### PROCESS_ACCOUNT **Event methods**:
-- 
-- Event methods are available (dynamically allocated by the state machine), that accomodate for state transitions occurring in the process.
-- There are two types of event methods, which you can use to influence the normal mechanisms in the state machine:
-- 
--   * **Immediate**: The event method has exactly the name of the event.
--   * **Delayed**: The event method starts with a __ + the name of the event. The first parameter of the event method is a number value, expressing the delay in seconds when the event will be executed. 
-- 
-- ### PROCESS_ACCOUNT **States**:
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
-- ### PROCESS_ACCOUNT state transition methods:
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
-- # 1) @{#PROCESS_ACCOUNT_DEADS} FSM class, extends @{Account#PROCESS_ACCOUNT}
-- 
-- The PROCESS_ACCOUNT_DEADS class accounts (detects, counts and reports) successful kills of DCS units.
-- The process is given a @{Set} of units that will be tracked upon successful destruction.
-- The process will end after each target has been successfully destroyed.
-- Each successful dead will trigger an Account state transition that can be scored, modified or administered.
-- 
-- 
-- ## PROCESS_ACCOUNT_DEADS constructor:
-- 
--   * @{#PROCESS_ACCOUNT_DEADS.New}(): Creates a new PROCESS_ACCOUNT_DEADS object.
-- 
-- === 
-- 
-- @module Account


do -- PROCESS_ACCOUNT
  
  --- PROCESS_ACCOUNT class
  -- @type PROCESS_ACCOUNT
  -- @field Set#SET_UNIT TargetSetUnit
  -- @extends Core.StateMachine#STATEMACHINE_TEMPLATE
  PROCESS_ACCOUNT = { 
    ClassName = "PROCESS_ACCOUNT",
    TargetSetUnit = nil,
  }
  
  --- Creates a new DESTROY process.
  -- @param #PROCESS_ACCOUNT self
  -- @return #PROCESS_ACCOUNT
  function PROCESS_ACCOUNT:New()

    -- Inherits from BASE
    local self = BASE:Inherit( self, STATEMACHINE_TEMPLATE:New( "PROCESS_ACCOUNT" ) ) -- Core.StateMachine#STATEMACHINE_TEMPLATE
  
    self:AddTransition( "Assigned", "Start", "Waiting")
    self:AddTransition( "*", "Wait", "Waiting")
    self:AddTransition( "*", "Report", "Report")
    self:AddTransition( "*", "Event", "Account")
    self:AddTransition( "Account", "More", "Wait")
    self:AddTransition( "Account", "NoMore", "Accounted")
    self:AddTransition( "*", "Fail", "Failed")
    
    self:AddEndState( "Accounted" )
    self:AddEndState( "Failed" )
    
    self:SetStartState( "Assigned" ) 
        
    return self
  end

  --- Process Events
  
  --- StateMachine callback function
  -- @param #PROCESS_ACCOUNT self
  -- @param Controllable#CONTROLLABLE ProcessUnit
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  function PROCESS_ACCOUNT:onafterStart( ProcessUnit, Event, From, To )

    self:EventOnDead( self.onfuncEventDead )

    self:__Wait( 1 )
  end

  
    --- StateMachine callback function
    -- @param #PROCESS_ACCOUNT self
    -- @param Controllable#CONTROLLABLE ProcessUnit
    -- @param #string Event
    -- @param #string From
    -- @param #string To
  function PROCESS_ACCOUNT:onenterWaiting( ProcessUnit, Event, From, To )
  
    if self.DisplayCount >= self.DisplayInterval then
      self:Report()
      self.DisplayCount = 1
    else
      self.DisplayCount = self.DisplayCount + 1
    end
    
    return true -- Process always the event.
  end
  
  --- StateMachine callback function
  -- @param #PROCESS_ACCOUNT self
  -- @param Controllable#CONTROLLABLE ProcessUnit
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  function PROCESS_ACCOUNT:onafterEvent( ProcessUnit, Event, From, To, Event )
  
    self:__NoMore( 1 )
  end
  
end -- PROCESS_ACCOUNT

do -- PROCESS_ACCOUNT_DEADS

  --- PROCESS_ACCOUNT_DEADS class
  -- @type PROCESS_ACCOUNT_DEADS
  -- @field Set#SET_UNIT TargetSetUnit
  -- @extends #PROCESS_ACCOUNT
  PROCESS_ACCOUNT_DEADS = { 
    ClassName = "PROCESS_ACCOUNT_DEADS",
    TargetSetUnit = nil,
  }


  --- Creates a new DESTROY process.
  -- @param #PROCESS_ACCOUNT_DEADS self
  -- @param Set#SET_UNIT TargetSetUnit
  -- @param #string TaskName
  function PROCESS_ACCOUNT_DEADS:New( TargetSetUnit, TaskName )
    -- Inherits from BASE
    local self = BASE:Inherit( self, PROCESS_ACCOUNT:New() ) -- #PROCESS_ACCOUNT_DEADS
    
    self:SetParameters( { 
      TargetSetUnit = TargetSetUnit, 
      TaskName = TaskName,
      DisplayInterval = 30,
      DisplayCount = 30,
      DisplayMessage = true,
      DisplayTime = 10, -- 10 seconds is the default
      DisplayCategory = "HQ", -- Targets is the default display category
    } )
    
    return self
  end

  
  function PROCESS_ACCOUNT_DEADS:_Destructor()
    self:E("_Destructor")
  
    self:EventRemoveAll()
  
  end
  
  --- Process Events
  
  --- StateMachine callback function
  -- @param #PROCESS_ASSIGN_MENU_ACCEPT self
  -- @param Controllable#CONTROLLABLE ProcessUnit
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  function PROCESS_ACCOUNT_DEADS:onenterReport( ProcessUnit, Event, From, To )
    self:E( { ProcessUnit, Event, From, To } )
  
    local TaskGroup = ProcessUnit:GetGroup()
    MESSAGE:New( "Your group with assigned " .. self.TaskName .. " task has " .. self.TargetSetUnit:GetUnitTypesText() .. " targets left to be destroyed.", 5, "HQ" ):ToGroup( TaskGroup )
  end
  
  
  --- StateMachine callback function
  -- @param #PROCESS_ASSIGN_MENU_ACCEPT self
  -- @param Controllable#CONTROLLABLE ProcessUnit
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  function PROCESS_ACCOUNT_DEADS:onenterAccount( ProcessUnit, Event, From, To, EventData  )
    self:T( { ProcessUnit, EventData, Event, From, To } )
    
    self:T({self.Controllable})
  
    self.TargetSetUnit:Flush()
    
    if self.TargetSetUnit:FindUnit( EventData.IniUnitName ) then
      local TaskGroup = ProcessUnit:GetGroup()
      self.TargetSetUnit:RemoveUnitsByName( EventData.IniUnitName )
      MESSAGE:New( "You hit a target. Your group with assigned " .. self.TaskName .. " task has " .. self.TargetSetUnit:Count() .. " targets ( " .. self.TargetSetUnit:GetUnitTypesText() .. " ) left to be destroyed.", 15, "HQ" ):ToGroup( TaskGroup )
    end
  end
  
  --- StateMachine callback function
  -- @param #PROCESS_ASSIGN_MENU_ACCEPT self
  -- @param Controllable#CONTROLLABLE ProcessUnit
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  function PROCESS_ACCOUNT_DEADS:onafterEvent( ProcessUnit, Event, From, To, EventData )
  
    if self.TargetSetUnit:Count() > 0 then
      self:__More( 1 )
    else
      self:__NoMore( 1 )
    end
  end
  
  --- DCS Events
  
  --- @param #PROCESS_ACCOUNT_DEADS self
  -- @param Event#EVENTDATA EventData
  function PROCESS_ACCOUNT_DEADS:onfuncEventDead( EventData )
    self:T( { "EventDead", EventData } )

    if EventData.IniDCSUnit then
      self:__Event( 1, EventData )
    end
  end

end -- PROCESS_ACCOUNT DEADS
