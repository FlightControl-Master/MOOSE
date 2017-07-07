--- **Actions** - ACT_ACCOUNT_ classes **account for** (detect, count & report) various DCS events occuring on @{Unit}s.
-- 
-- ![Banner Image](..\Presentations\ACT_ACCOUNT\Dia1.JPG)
-- 
-- === 
-- 
-- @module Account


do -- ACT_ACCOUNT
  
  --- # @{#ACT_ACCOUNT} FSM class, extends @{Fsm#FSM_PROCESS}
  -- 
  -- ## ACT_ACCOUNT state machine:  
  -- 
  -- This class is a state machine: it manages a process that is triggered by events causing state transitions to occur.
  -- All derived classes from this class will start with the class name, followed by a \_. See the relevant derived class descriptions below.
  -- Each derived class follows exactly the same process, using the same events and following the same state transitions, 
  -- but will have **different implementation behaviour** upon each event or state transition.
  -- 
  -- ### ACT_ACCOUNT States  
  -- 
  --   * **Asigned**: The player is assigned.
  --   * **Waiting**: Waiting for an event.
  --   * **Report**: Reporting.
  --   * **Account**: Account for an event.
  --   * **Accounted**: All events have been accounted for, end of the process.
  --   * **Failed**: Failed the process.
  -- 
  -- ### ACT_ACCOUNT Events  
  -- 
  --   * **Start**: Start the process.
  --   * **Wait**: Wait for an event.
  --   * **Report**: Report the status of the accounting.
  --   * **Event**: An event happened, process the event.
  --   * **More**: More targets.
  --   * **NoMore (*)**: No more targets.
  --   * **Fail (*)**: The action process has failed.
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
  
    self:AddTransition( "Assigned", "Start", "Waiting" )
    self:AddTransition( "*", "Wait", "Waiting" )
    self:AddTransition( "*", "Report", "Report" )
    self:AddTransition( "*", "Event", "Account" )
    self:AddTransition( "Account", "Player", "AccountForPlayer" )
    self:AddTransition( "Account", "Other", "AccountForOther" )
    self:AddTransition( { "Account", "AccountForPlayer", "AccountForOther" }, "More", "Wait" )
    self:AddTransition( { "Account", "AccountForPlayer", "AccountForOther" }, "NoMore", "Accounted" )
    self:AddTransition( "*", "Fail", "Failed" )
    
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
  function ACT_ACCOUNT:onafterStart( ProcessUnit, From, Event, To )

    self:HandleEvent( EVENTS.Dead, self.onfuncEventDead )
    self:HandleEvent( EVENTS.Crash, self.onfuncEventCrash )
    self:HandleEvent( EVENTS.Hit )

    self:__Wait( 1 )
  end

  
    --- StateMachine callback function
    -- @param #ACT_ACCOUNT self
    -- @param Wrapper.Controllable#CONTROLLABLE ProcessUnit
    -- @param #string Event
    -- @param #string From
    -- @param #string To
  function ACT_ACCOUNT:onenterWaiting( ProcessUnit, From, Event, To )
  
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
  function ACT_ACCOUNT:onafterEvent( ProcessUnit, From, Event, To, Event )
  
    self:__NoMore( 1 )
  end
  
end -- ACT_ACCOUNT

do -- ACT_ACCOUNT_DEADS

  --- # @{#ACT_ACCOUNT_DEADS} FSM class, extends @{Fsm.Account#ACT_ACCOUNT}
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

  --- Process Events
  
  --- StateMachine callback function
  -- @param #ACT_ACCOUNT_DEADS self
  -- @param Wrapper.Controllable#CONTROLLABLE ProcessUnit
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  function ACT_ACCOUNT_DEADS:onenterReport( ProcessUnit, Task, From, Event, To )
    self:E( { ProcessUnit, From, Event, To } )
  
    self:Message( "Your group with assigned " .. self.TaskName .. " task has " .. self.TargetSetUnit:GetUnitTypesText() .. " targets left to be destroyed." )
  end
  
  
  --- StateMachine callback function
  -- @param #ACT_ACCOUNT_DEADS self
  -- @param Wrapper.Client#CLIENT ProcessClient
  -- @param Tasking.Task#TASK Task
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param Core.Event#EVENTDATA EventData
  function ACT_ACCOUNT_DEADS:onafterEvent( ProcessClient, Task, From, Event, To, EventData  )
    self:T( { ProcessClient:GetName(), Task:GetName(), From, Event, To, EventData } )
    
    if self.TargetSetUnit:FindUnit( EventData.IniUnitName ) then
      local PlayerName = ProcessClient:GetPlayerName()
      local PlayerHit = self.PlayerHits and self.PlayerHits[EventData.IniUnitName]
      if PlayerHit == PlayerName then
        self:Player( EventData )
      else
        self:Other( EventData )
      end
    end
  end

  --- StateMachine callback function
  -- @param #ACT_ACCOUNT_DEADS self
  -- @param Wrapper.Client#CLIENT ProcessClient
  -- @param Tasking.Task#TASK Task
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param Core.Event#EVENTDATA EventData
  function ACT_ACCOUNT_DEADS:onenterAccountForPlayer( ProcessClient, Task, From, Event, To, EventData  )
    self:T( { ProcessClient:GetName(), Task:GetName(), From, Event, To, EventData } )
    
    local TaskGroup = ProcessClient:GetGroup()

    self.TargetSetUnit:Remove( EventData.IniUnitName )
    self:Message( "You have destroyed a target. Your group assigned with task " .. self.TaskName .. " has " .. self.TargetSetUnit:Count() .. " targets ( " .. self.TargetSetUnit:GetUnitTypesText() .. " ) left to be destroyed." )

    local PlayerName = ProcessClient:GetPlayerName()
    Task:AddProgress( PlayerName, "Destroyed " .. EventData.IniTypeName, timer.getTime(), 1 )

    if self.TargetSetUnit:Count() > 0 then
      self:__More( 1 )
    else
      self:__NoMore( 1 )
    end
  end

  --- StateMachine callback function
  -- @param #ACT_ACCOUNT_DEADS self
  -- @param Wrapper.Client#CLIENT ProcessClient
  -- @param Tasking.Task#TASK Task
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param Core.Event#EVENTDATA EventData
  function ACT_ACCOUNT_DEADS:onenterAccountForOther( ProcessClient, Task, From, Event, To, EventData  )
    self:T( { ProcessClient:GetName(), Task:GetName(), From, Event, To, EventData } )
    
    local TaskGroup = ProcessClient:GetGroup()
    self.TargetSetUnit:Remove( EventData.IniUnitName )
    self:Message( "One of the task targets has been destroyed. Your group assigned with task " .. self.TaskName .. " has " .. self.TargetSetUnit:Count() .. " targets ( " .. self.TargetSetUnit:GetUnitTypesText() .. " ) left to be destroyed." )

    if self.TargetSetUnit:Count() > 0 then
      self:__More( 1 )
    else
      self:__NoMore( 1 )
    end
  end

  
  --- DCS Events
  
  --- @param #ACT_ACCOUNT_DEADS self
  -- @param Core.Event#EVENTDATA EventData
  function ACT_ACCOUNT_DEADS:OnEventHit( EventData )
    self:T( { "EventDead", EventData } )

    if EventData.IniPlayerName and EventData.TgtDCSUnitName then
      self.PlayerHits = self.PlayerHits or {}
      self.PlayerHits[EventData.TgtDCSUnitName] = EventData.IniPlayerName
    end
  end  
  
  --- @param #ACT_ACCOUNT_DEADS self
  -- @param Event#EVENTDATA EventData
  function ACT_ACCOUNT_DEADS:onfuncEventDead( EventData )
    self:T( { "EventDead", EventData } )

    if EventData.IniDCSUnit then
      self:Event( EventData )
    end
  end

  --- DCS Events
  
  --- @param #ACT_ACCOUNT_DEADS self
  -- @param Event#EVENTDATA EventData
  function ACT_ACCOUNT_DEADS:onfuncEventCrash( EventData )
    self:T( { "EventDead", EventData } )

    if EventData.IniDCSUnit then
      self:Event( EventData )
    end
  end

end -- ACT_ACCOUNT DEADS
