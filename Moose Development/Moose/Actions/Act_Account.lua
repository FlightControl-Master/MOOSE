--- (SP) (MP) (FSM) Account for (Detect, count and report) DCS events occuring on DCS objects (units).
-- 
-- ===
-- 
-- # @{#ACT_ACCOUNT} FSM class, extends @{Core.Fsm#FSM_PROCESS}
-- 
-- ## ACT_ACCOUNT state machine:
-- 
-- This class is a state machine: it manages a process that is triggered by events causing state transitions to occur.
-- All derived classes from this class will start with the class name, followed by a \_. See the relevant derived class descriptions below.
-- Each derived class follows exactly the same process, using the same events and following the same state transitions, 
-- but will have **different implementation behaviour** upon each event or state transition.
-- 
-- ### ACT_ACCOUNT **Events**:
-- 
-- These are the events defined in this class:
-- 
--   * **Start**:  The process is started. The process will go into the Report state.
--   * **Event**:  A relevant event has occured that needs to be accounted for. The process will go into the Account state.
--   * **Report**: The process is reporting to the player the accounting status of the DCS events.
--   * **More**:  There are more DCS events that need to be accounted for. The process will go back into the Report state.
--   * **NoMore**:  There are no more DCS events that need to be accounted for. The process will go into the Success state.
-- 
-- ### ACT_ACCOUNT **Event methods**:
-- 
-- Event methods are available (dynamically allocated by the state machine), that accomodate for state transitions occurring in the process.
-- There are two types of event methods, which you can use to influence the normal mechanisms in the state machine:
-- 
--   * **Immediate**: The event method has exactly the name of the event.
--   * **Delayed**: The event method starts with a __ + the name of the event. The first parameter of the event method is a number value, expressing the delay in seconds when the event will be executed. 
-- 
-- ### ACT_ACCOUNT **States**:
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
-- ### ACT_ACCOUNT state transition methods:
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
-- # 1) @{#ACT_ACCOUNT_DEADS} FSM class, extends @{Fsm.Account#ACT_ACCOUNT}
-- 
-- The ACT_ACCOUNT_DEADS class accounts (detects, counts and reports) successful kills of DCS units.
-- The process is given a @{Set} of units that will be tracked upon successful destruction.
-- The process will end after each target has been successfully destroyed.
-- Each successful dead will trigger an Account state transition that can be scored, modified or administered.
-- 
-- 
-- ## ACT_ACCOUNT_DEADS constructor:
-- 
--   * @{#ACT_ACCOUNT_DEADS.New}(): Creates a new ACT_ACCOUNT_DEADS object.
-- 
-- === 
-- 
-- @module Account


do -- ACT_ACCOUNT
  
  --- ACT_ACCOUNT class
  -- @type ACT_ACCOUNT
  -- @field Set#SET_UNIT TargetSetUnit
  -- @extends Core.Fsm#FSM_PROCESS
  ACT_ACCOUNT = { 
    ClassName = "ACT_ACCOUNT",
    TargetSetUnit = nil,
  }
  
  --- Creates a new DESTROY process.
  -- @param #ACT_ACCOUNT self
  -- @return #ACT_ACCOUNT
  function ACT_ACCOUNT:New()

    -- Inherits from BASE
    local self = BASE:Inherit( self, FSM_PROCESS:New() ) -- Core.Fsm#FSM_PROCESS
  
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
  -- @param #ACT_ACCOUNT self
  -- @param Wrapper.Controllable#CONTROLLABLE ProcessUnit
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  function ACT_ACCOUNT:onafterStart( ProcessUnit, Event, From, To )

    self:EventOnDead( self.onfuncEventDead )

    self:__Wait( 1 )
  end

  
    --- StateMachine callback function
    -- @param #ACT_ACCOUNT self
    -- @param Wrapper.Controllable#CONTROLLABLE ProcessUnit
    -- @param #string Event
    -- @param #string From
    -- @param #string To
  function ACT_ACCOUNT:onenterWaiting( ProcessUnit, Event, From, To )
  
    if self.DisplayCount >= self.DisplayInterval then
      self:Report()
      self.DisplayCount = 1
    else
      self.DisplayCount = self.DisplayCount + 1
    end
    
    return true -- Process always the event.
  end
  
  --- StateMachine callback function
  -- @param #ACT_ACCOUNT self
  -- @param Wrapper.Controllable#CONTROLLABLE ProcessUnit
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  function ACT_ACCOUNT:onafterEvent( ProcessUnit, Event, From, To, Event )
  
    self:__NoMore( 1 )
  end
  
end -- ACT_ACCOUNT

do -- ACT_ACCOUNT_DEADS

  --- ACT_ACCOUNT_DEADS class
  -- @type ACT_ACCOUNT_DEADS
  -- @field Set#SET_UNIT TargetSetUnit
  -- @extends #ACT_ACCOUNT
  ACT_ACCOUNT_DEADS = { 
    ClassName = "ACT_ACCOUNT_DEADS",
    TargetSetUnit = nil,
  }


  --- Creates a new DESTROY process.
  -- @param #ACT_ACCOUNT_DEADS self
  -- @param Set#SET_UNIT TargetSetUnit
  -- @param #string TaskName
  function ACT_ACCOUNT_DEADS:New( TargetSetUnit, TaskName )
    -- Inherits from BASE
    local self = BASE:Inherit( self, ACT_ACCOUNT:New() ) -- #ACT_ACCOUNT_DEADS
    
    self.TargetSetUnit = TargetSetUnit 
    self.TaskName = TaskName
      
    self.DisplayInterval = 30
    self.DisplayCount = 30
    self.DisplayMessage = true
    self.DisplayTime = 10 -- 10 seconds is the default
    self.DisplayCategory = "HQ" -- Targets is the default display category
      
    return self
  end
  
  function ACT_ACCOUNT_DEADS:Init( FsmAccount )
  
    self.TargetSetUnit = FsmAccount.TargetSetUnit 
    self.TaskName = FsmAccount.TaskName
  end


  
  function ACT_ACCOUNT_DEADS:_Destructor()
    self:E("_Destructor")
  
    self:EventRemoveAll()
  
  end
  
  --- Process Events
  
  --- StateMachine callback function
  -- @param #ACT_ACCOUNT_DEADS self
  -- @param Wrapper.Controllable#CONTROLLABLE ProcessUnit
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  function ACT_ACCOUNT_DEADS:onenterReport( ProcessUnit, Event, From, To )
    self:E( { ProcessUnit, Event, From, To } )
  
    self:Message( "Your group with assigned " .. self.TaskName .. " task has " .. self.TargetSetUnit:GetUnitTypesText() .. " targets left to be destroyed." )
  end
  
  
  --- StateMachine callback function
  -- @param #ACT_ACCOUNT_DEADS self
  -- @param Wrapper.Controllable#CONTROLLABLE ProcessUnit
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  function ACT_ACCOUNT_DEADS:onenterAccount( ProcessUnit, Event, From, To, EventData  )
    self:T( { ProcessUnit, EventData, Event, From, To } )
    
    self:T({self.Controllable})
  
    self.TargetSetUnit:Flush()
    
    if self.TargetSetUnit:FindUnit( EventData.IniUnitName ) then
      local TaskGroup = ProcessUnit:GetGroup()
      self.TargetSetUnit:RemoveUnitsByName( EventData.IniUnitName )
      self:Message( "You hit a target. Your group with assigned " .. self.TaskName .. " task has " .. self.TargetSetUnit:Count() .. " targets ( " .. self.TargetSetUnit:GetUnitTypesText() .. " ) left to be destroyed." )
    end
  end
  
  --- StateMachine callback function
  -- @param #ACT_ACCOUNT_DEADS self
  -- @param Wrapper.Controllable#CONTROLLABLE ProcessUnit
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  function ACT_ACCOUNT_DEADS:onafterEvent( ProcessUnit, Event, From, To, EventData )
  
    if self.TargetSetUnit:Count() > 0 then
      self:__More( 1 )
    else
      self:__NoMore( 1 )
    end
  end
  
  --- DCS Events
  
  --- @param #ACT_ACCOUNT_DEADS self
  -- @param Event#EVENTDATA EventData
  function ACT_ACCOUNT_DEADS:onfuncEventDead( EventData )
    self:T( { "EventDead", EventData } )

    if EventData.IniDCSUnit then
      self:__Event( 1, EventData )
    end
  end

end -- ACT_ACCOUNT DEADS
