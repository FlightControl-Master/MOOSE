--- This module contains the FSM class.
-- This development is based on a state machine implementation made by Conroy Kyle.
-- The state machine can be found here: https://github.com/kyleconroy/lua-state-machine
--
-- I've taken the development and enhanced it to make the state machine hierarchical...
-- It is a fantastic development, this module.
--
-- ===
--
-- 1) @{Workflow#FSM} class, extends @{Core.Base#BASE}
-- ==============================================
--
-- 1.1) Add or remove objects from the FSM
-- --------------------------------------------
-- @module Fsm
-- @author FlightControl

do -- FSM

  --- FSM class
  -- @type FSM
  -- @extends Core.Base#BASE
  FSM = {
    ClassName = "FSM",
  }
  
  --- Creates a new FSM object.
  -- @param #FSM self
  -- @return #FSM
  function FSM:New( FsmT )
  
    -- Inherits from BASE
    local self = BASE:Inherit( self, BASE:New() )
  
    self.options = options or {}
    self.options.subs = self.options.subs or {}
    self.current = self.options.initial or 'none'
    self.Events = {}
    self.subs = {}
    self.endstates = {}
    
    self.Scores = {}
    
    self._StartState = "none"
    self._Transitions = {}
    self._Processes = {}
    self._EndStates = {}
    self._Scores = {}
    
    self.CallScheduler = SCHEDULER:New( self )
    
  
    return self
  end
  
  
  function FSM:SetStartState( State )
  
    self._StartState = State
    self.current = State
  end
  
  
  function FSM:GetStartState()
  
    return self._StartState or {}
  end
  
  function FSM:AddTransition( From, Event, To )
  
    local Transition = {}
    Transition.From = From
    Transition.Event = Event
    Transition.To = To
  
    self:E( Transition )
    
    self._Transitions[Transition] = Transition
    self:_eventmap( self.Events, Transition )
  end
  
  function FSM:GetTransitions()
  
    return self._Transitions or {}
  end
  
  --- Set the default @{Process} template with key ProcessName providing the ProcessClass and the process object when it is assigned to a @{Controllable} by the task.
  -- @return Core.Fsm#FSM_PROCESS
  function FSM:AddProcess( From, Event, Process, ReturnEvents )
    self:E( { From, Event, Process, ReturnEvents } )
  
    local Sub = {}
    Sub.From = From
    Sub.Event = Event
    Sub.fsm = Process
    Sub.StartEvent = "Start"
    Sub.ReturnEvents = ReturnEvents
    
    self._Processes[Sub] = Sub
    
    self:_submap( self.subs, Sub, nil )
    
    self:AddTransition( From, Event, From )
  
    return Process
  end
  
  function FSM:GetProcesses()
  
    return self._Processes or {}
  end
  
  function FSM:GetProcess( From, Event )
  
    for ProcessID, Process in pairs( self:GetProcesses() ) do
      if Process.From == From and Process.Event == Event then
        self:E( Process )
        return Process.fsm
      end
    end
    
    error( "Sub-Process from state " .. From .. " with event " .. Event .. " not found!" )
  end
  
  function FSM:AddEndState( State )
  
    self._EndStates[State] = State
    self.endstates[State] = State
  end
  
  function FSM:GetEndStates()
  
    return self._EndStates or {}
  end
  
  
  --- Adds a score for the FSM to be achieved.
  -- @param #FSM self
  -- @param #string State is the state of the process when the score needs to be given. (See the relevant state descriptions of the process).
  -- @param #string ScoreText is a text describing the score that is given according the status.
  -- @param #number Score is a number providing the score of the status.
  -- @return #FSM self
  function FSM:AddScore( State, ScoreText, Score )
    self:F2( { State, ScoreText, Score } )
  
    self._Scores[State] = self._Scores[State] or {}
    self._Scores[State].ScoreText = ScoreText
    self._Scores[State].Score = Score
  
    return self
  end
  
  --- Adds a score for the FSM_PROCESS to be achieved.
  -- @param #FSM self
  -- @param #string From is the From State of the main process.
  -- @param #string Event is the Event of the main process.
  -- @param #string State is the state of the process when the score needs to be given. (See the relevant state descriptions of the process).
  -- @param #string ScoreText is a text describing the score that is given according the status.
  -- @param #number Score is a number providing the score of the status.
  -- @return #FSM self
  function FSM:AddScoreProcess( From, Event, State, ScoreText, Score )
    self:F2( { Event, State, ScoreText, Score } )
  
    local Process = self:GetProcess( From, Event )
    
    self:E( { Process = Process._Name, Scores = Process._Scores, State = State, ScoreText = ScoreText, Score = Score } )
    Process._Scores[State] = Process._Scores[State] or {}
    Process._Scores[State].ScoreText = ScoreText
    Process._Scores[State].Score = Score
  
    return Process
  end
  
  function FSM:GetScores()
  
    return self._Scores or {}
  end
  
  
  function FSM:GetSubs()
  
    return self.options.subs
  end
  
  
  function FSM:LoadCallBacks( CallBackTable )
  
    for name, callback in pairs( CallBackTable or {} ) do
      self[name] = callback
    end
  
  end
  
  function FSM:_eventmap( Events, EventStructure )
  
      local Event = EventStructure.Event
      local __Event = "__" .. EventStructure.Event
      self[Event] = self[Event] or self:_create_transition(Event)
      self[__Event] = self[__Event] or self:_delayed_transition(Event)
      self:T( "Added methods: " .. Event .. ", " .. __Event )
      Events[Event] = self.Events[Event] or { map = {} }
      self:_add_to_map( Events[Event].map, EventStructure )
  
  end
  
  function FSM:_submap( subs, sub, name )
    self:F( { sub = sub, name = name } )
    subs[sub.From] = subs[sub.From] or {}
    subs[sub.From][sub.Event] = subs[sub.From][sub.Event] or {}
    
    -- Make the reference table weak.
    -- setmetatable( subs[sub.From][sub.Event], { __mode = "k" } )
    
    subs[sub.From][sub.Event][sub] = {}
    subs[sub.From][sub.Event][sub].fsm = sub.fsm
    subs[sub.From][sub.Event][sub].StartEvent = sub.StartEvent
    subs[sub.From][sub.Event][sub].ReturnEvents = sub.ReturnEvents or {} -- these events need to be given to find the correct continue event ... if none given, the processing will stop.
    subs[sub.From][sub.Event][sub].name = name
    subs[sub.From][sub.Event][sub].fsmparent = self
  end
  
  
  function FSM:_call_handler(handler, params)
    if self[handler] then
      self:E( "Calling " .. handler )
      return self[handler]( self, unpack(params) )
    end
  end
  
  function FSM._handler( self, EventName, ... )
  
    self:E( { EventName, ... } )
  
    local can, to = self:can( EventName )
    self:E( { EventName, self.current, can, to } )
  
    local ReturnValues = nil
  
    if can then
      local from = self.current
      local params = { EventName, from, to, ...  }
  
      if self:_call_handler("onbefore" .. EventName, params) == false
        or self:_call_handler("onleave" .. from, params) == false then
        return false
      end
  
      self.current = to
  
      local execute = true
  
      local subtable = self:_gosub( from, EventName )
      for _, sub in pairs( subtable ) do
        --if sub.nextevent then
        --  self:F2( "nextevent = " .. sub.nextevent )
        --  self[sub.nextevent]( self )
        --end
        self:E( "calling sub start event: " .. sub.StartEvent )
        sub.fsm.fsmparent = self
        sub.fsm.ReturnEvents = sub.ReturnEvents
        sub.fsm[sub.StartEvent]( sub.fsm )
        execute = true
      end
  
      local fsmparent, Event = self:_isendstate( to )
      if fsmparent and Event then
        self:F2( { "end state: ", fsmparent, Event } )
        self:_call_handler("onenter" .. to, params)
        self:_call_handler("onafter" .. EventName, params)
        self:_call_handler("onstatechange", params)
        fsmparent[Event]( fsmparent )
        execute = false
      end
  
      if execute then
        -- only execute the call if the From state is not equal to the To state! Otherwise this function should never execute!
        if from ~= to then
          self:T3( { onenter = "onenter" .. to, callback = self["onenter" .. to] }  )
          self:_call_handler("onenter" .. to, params)
        end
  
        self:T3( { On = "OnBefore" .. to, callback = self["OnBefore" .. to] }  )
        if ( self:_call_handler("OnBefore" .. to, params ) ~= false ) then
  
          self:T3( { onafter = "onafter" .. EventName, callback = self["onafter" .. EventName] }  )
          self:_call_handler("onafter" .. EventName, params)
  
          self:T3( { On = "OnAfter" .. to, callback = self["OnAfter" .. to] }  )
          ReturnValues = self:_call_handler("OnAfter" .. to, params )
        end
  
        self:_call_handler("onstatechange", params)
      end
  
      return ReturnValues
    end
  
    return nil
  end
  
  function FSM:_delayed_transition( EventName )
    self:E( { EventName = EventName } )
    return function( self, DelaySeconds, ... )
      self:T( "Delayed Event: " .. EventName )
      local CallID = self.CallScheduler:Schedule( self, self._handler, { EventName, ... }, DelaySeconds or 1 )
      self:T( { CallID = CallID } )
    end
  end
  
  function FSM:_create_transition( EventName )
    self:E( { Event =  EventName  } )
    return function( self, ... ) return self._handler( self,  EventName , ... ) end
  end
  
  function FSM:_gosub( ParentFrom, ParentEvent )
    local fsmtable = {}
    if self.subs[ParentFrom] and self.subs[ParentFrom][ParentEvent] then
      self:E( { ParentFrom, ParentEvent, self.subs[ParentFrom], self.subs[ParentFrom][ParentEvent] } )
      return self.subs[ParentFrom][ParentEvent]
    else
      return {}
    end
  end
  
  function FSM:_isendstate( Current )
    local FSMParent = self.fsmparent
    if FSMParent and self.endstates[Current] then
      self:E( { state = Current, endstates = self.endstates, endstate = self.endstates[Current] } )
      FSMParent.current = Current
      local ParentFrom = FSMParent.current
      self:E( ParentFrom )
      self:E( self.ReturnEvents )
      local Event = self.ReturnEvents[Current]
      self:E( { ParentFrom, Event, self.ReturnEvents } )
      if Event then
        return FSMParent, Event
      else
        self:E( { "Could not find parent event name for state ", ParentFrom } )
      end
    end
  
    return nil
  end
  
  function FSM:_add_to_map( Map, Event )
    self:F3( {  Map, Event } )
    if type(Event.From) == 'string' then
       Map[Event.From] = Event.To
    else
      for _, From in ipairs(Event.From) do
         Map[From] = Event.To
      end
    end
    self:T3( {  Map, Event } )
  end
  
  function FSM:GetState()
    return self.current
  end
  
  
  function FSM:Is( State )
    return self.current == State
  end
  
  function FSM:is(state)
    return self.current == state
  end
  
  function FSM:can(e)
    self:E( { e, self.Events, self.Events[e] } )
    local Event = self.Events[e]
    self:F3( { self.current, Event } )
    local To = Event and Event.map[self.current] or Event.map['*']
    return To ~= nil, To
  end
  
  function FSM:cannot(e)
    return not self:can(e)
  end

end

do -- FSM_CONTROLLABLE

  --- FSM_CONTROLLABLE class
  -- @type FSM_CONTROLLABLE
  -- @field Wrapper.Controllable#CONTROLLABLE Controllable
  -- @extends Core.Fsm#FSM
  FSM_CONTROLLABLE = {
    ClassName = "FSM_CONTROLLABLE",
  }
  
  --- Creates a new FSM_CONTROLLABLE object.
  -- @param #FSM_CONTROLLABLE self
  -- @param #table FSMT Finite State Machine Table
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable (optional) The CONTROLLABLE object that the FSM_CONTROLLABLE governs.
  -- @return #FSM_CONTROLLABLE
  function FSM_CONTROLLABLE:New( FSMT, Controllable )
  
    -- Inherits from BASE
    local self = BASE:Inherit( self, FSM:New( FSMT ) ) -- Core.Fsm#FSM_CONTROLLABLE
  
    if Controllable then
      self:SetControllable( Controllable )
    end
  
    return self
  end
  
  --- Sets the CONTROLLABLE object that the FSM_CONTROLLABLE governs.
  -- @param #FSM_CONTROLLABLE self
  -- @param Wrapper.Controllable#CONTROLLABLE FSMControllable
  -- @return #FSM_CONTROLLABLE
  function FSM_CONTROLLABLE:SetControllable( FSMControllable )
    self:F( FSMControllable )
    self.Controllable = FSMControllable
  end
  
  --- Gets the CONTROLLABLE object that the FSM_CONTROLLABLE governs.
  -- @param #FSM_CONTROLLABLE self
  -- @return Wrapper.Controllable#CONTROLLABLE
  function FSM_CONTROLLABLE:GetControllable()
    return self.Controllable
  end
  
  function FSM_CONTROLLABLE:_call_handler( handler, params )
  
    local ErrorHandler = function( errmsg )
  
      env.info( "Error in SCHEDULER function:" .. errmsg )
      if debug ~= nil then
        env.info( debug.traceback() )
      end
      
      return errmsg
    end
  
    if self[handler] then
      self:E( "Calling " .. handler )
      return xpcall( function() return self[handler]( self, self.Controllable, unpack( params ) ) end, ErrorHandler )
      --return self[handler]( self, self.Controllable, unpack( params ) )
    end
  end
  
end

do -- FSM_PROCESS

  --- FSM_PROCESS class
  -- @type FSM_PROCESS
  -- @field Tasking.Task#TASK Task
  -- @extends Core.Fsm#FSM_CONTROLLABLE
  FSM_PROCESS = {
    ClassName = "FSM_PROCESS",
  }
  
  --- Creates a new FSM_PROCESS object.
  -- @param #FSM_PROCESS self
  -- @return #FSM_PROCESS
  function FSM_PROCESS:New( Controllable, Task )
  
    local self = BASE:Inherit( self, FSM_CONTROLLABLE:New() ) -- Core.Fsm#FSM_PROCESS

    self:F( Controllable, Task )
  
    self:Assign( Controllable, Task )
  
    return self
  end
  
  function FSM_PROCESS:Init( FsmProcess )
    self:E( "No Initialisation" )
  end  
  
  --- Creates a new FSM_PROCESS object based on this FSM_PROCESS.
  -- @param #FSM_PROCESS self
  -- @return #FSM_PROCESS
  function FSM_PROCESS:Copy( Controllable, Task )
    self:E( { self:GetClassNameAndID() } )
  
    local NewFsm = self:New( Controllable, Task ) -- Core.Fsm#FSM_PROCESS
  
    NewFsm:Assign( Controllable, Task )
  
    -- Polymorphic call to initialize the new FSM_PROCESS based on self FSM_PROCESS
    NewFsm:Init( self )
    
    -- Set Start State
    NewFsm:SetStartState( self:GetStartState() )
  
    -- Copy Transitions
    for TransitionID, Transition in pairs( self:GetTransitions() ) do
      NewFsm:AddTransition( Transition.From, Transition.Event, Transition.To )
    end
  
    -- Copy Processes
    for ProcessID, Process in pairs( self:GetProcesses() ) do
      self:E( { Process} )
      local FsmProcess = NewFsm:AddProcess( Process.From, Process.Event, Process.fsm:Copy( Controllable, Task ), Process.ReturnEvents )
    end
  
    -- Copy End States
    for EndStateID, EndState in pairs( self:GetEndStates() ) do
      self:E( EndState )
      NewFsm:AddEndState( EndState )
    end
    
    -- Copy the score tables
    for ScoreID, Score in pairs( self:GetScores() ) do
      self:E( Score )
      NewFsm:AddScore( ScoreID, Score.ScoreText, Score.Score )
    end
  
    return NewFsm
  end
  
  --- Sets the task of the process.
  -- @param #FSM_PROCESS self
  -- @param Tasking.Task#TASK Task
  -- @return #FSM_PROCESS
  function FSM_PROCESS:SetTask( Task )
  
    self.Task = Task
  
    return self
  end
  
  --- Gets the task of the process.
  -- @param #FSM_PROCESS self
  -- @return Tasking.Task#TASK
  function FSM_PROCESS:GetTask()
  
    return self.Task
  end
  
  --- Gets the mission of the process.
  -- @param #FSM_PROCESS self
  -- @return Tasking.Mission#MISSION
  function FSM_PROCESS:GetMission()
  
    return self.Task.Mission
  end
  
  --- Gets the mission of the process.
  -- @param #FSM_PROCESS self
  -- @return Tasking.CommandCenter#COMMANDCENTER
  function FSM_PROCESS:GetCommandCenter()
  
    return self:GetTask():GetMission():GetCommandCenter()
  end
  
  --- Send a message of the @{Task} to the Group of the Unit.
-- @param #FSM_PROCESS self
function FSM_PROCESS:Message( Message )
  self:F( { Message = Message } )

  local CC = self:GetCommandCenter()
  local TaskGroup = self.Controllable:GetGroup()
  
  CC:MessageToGroup( Message, TaskGroup )
end

  
  
  
  --- Assign the process to a @{Unit} and activate the process.
  -- @param #FSM_PROCESS self
  -- @param Task.Tasking#TASK Task
  -- @param Wrapper.Unit#UNIT ProcessUnit
  -- @return #FSM_PROCESS self
  function FSM_PROCESS:Assign( ProcessUnit, Task )
    self:E( { Task, ProcessUnit } )
  
    self:SetControllable( ProcessUnit )
    self:SetTask( Task )
    
    --self.ProcessGroup = ProcessUnit:GetGroup()
  
    return self
  end
  
  --- Adds a score for the FSM_PROCESS to be achieved.
  -- @param #FSM_PROCESS self
  -- @param #string State is the state of the process when the score needs to be given. (See the relevant state descriptions of the process).
  -- @param #string ScoreText is a text describing the score that is given according the status.
  -- @param #number Score is a number providing the score of the status.
  -- @return #FSM_PROCESS self
  function FSM_PROCESS:AddScore( State, ScoreText, Score )
    self:F2( { State, ScoreText, Score } )
  
    self.Scores[State] = self.Scores[State] or {}
    self.Scores[State].ScoreText = ScoreText
    self.Scores[State].Score = Score
  
    return self
  end
  
  function FSM_PROCESS:onenterAssigned( ProcessUnit )
    self:E( "Assign" )
  
    self.Task:Assign()
  end
  
  function FSM_PROCESS:onenterFailed( ProcessUnit )
    self:E( "Failed" )
  
    self.Task:Fail()
  end
  
  function FSM_PROCESS:onenterSuccess( ProcessUnit )
    self:E( "Success" )
  
    self.Task:Success()
  end
  
  --- StateMachine callback function for a FSM_PROCESS
  -- @param #FSM_PROCESS self
  -- @param Wrapper.Controllable#CONTROLLABLE ProcessUnit
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  function FSM_PROCESS:onstatechange( ProcessUnit, Event, From, To, Dummy )
    self:E( { ProcessUnit, Event, From, To, Dummy, self:IsTrace() } )
  
    if self:IsTrace() then
      MESSAGE:New( "@ Process " .. self:GetClassNameAndID() .. " : " .. Event .. " changed to state " .. To, 2 ):ToAll()
    end
  
    self:E( self.Scores[To] )
    -- TODO: This needs to be reworked with a callback functions allocated within Task, and set within the mission script from the Task Objects...
    if self.Scores[To] then
    
      local Task = self.Task  
      local Scoring = Task:GetScoring()
      if Scoring then
        Scoring:_AddMissionTaskScore( Task.Mission, ProcessUnit, self.Scores[To].ScoreText, self.Scores[To].Score )
      end
    end
  end

end

do -- FSM_TASK

  --- FSM_TASK class
  -- @type FSM_TASK
  -- @field Tasking.Task#TASK Task
  -- @extends Core.Fsm#FSM
  FSM_TASK = {
    ClassName = "FSM_TASK",
  }
  
  --- Creates a new FSM_TASK object.
  -- @param #FSM_TASK self
  -- @param #table FSMT
  -- @param Tasking.Task#TASK Task
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #FSM_TASK
  function FSM_TASK:New( FSMT )
  
    local self = BASE:Inherit( self, FSM_CONTROLLABLE:New( FSMT ) ) -- Core.Fsm#FSM_TASK
  
    self["onstatechange"] = self.OnStateChange
  
    return self
  end
  
  function FSM_TASK:_call_handler( handler, params )
    if self[handler] then
      self:E( "Calling " .. handler )
      return self[handler]( self, unpack( params ) )
    end
  end

end -- FSM_TASK

do -- FSM_SET

  --- FSM_SET class
  -- @type FSM_SET
  -- @field Core.Set#SET_BASE Set
  -- @extends Core.Fsm#FSM
  FSM_SET = {
    ClassName = "FSM_SET",
  }
  
  --- Creates a new FSM_SET object.
  -- @param #FSM_SET self
  -- @param #table FSMT Finite State Machine Table
  -- @param Set_SET_BASE FSMSet (optional) The Set object that the FSM_SET governs.
  -- @return #FSM_SET
  function FSM_SET:New( FSMSet )
  
    -- Inherits from BASE
    local self = BASE:Inherit( self, FSM:New() ) -- Core.Fsm#FSM_SET
  
    if FSMSet then
      self:Set( FSMSet )
    end
  
    return self
  end
  
  --- Sets the SET_BASE object that the FSM_SET governs.
  -- @param #FSM_SET self
  -- @param Core.Set#SET_BASE FSMSet
  -- @return #FSM_SET
  function FSM_SET:Set( FSMSet )
    self:F( FSMSet )
    self.Set = FSMSet
  end
  
  --- Gets the SET_BASE object that the FSM_SET governs.
  -- @param #FSM_SET self
  -- @return Core.Set#SET_BASE
  function FSM_SET:Get()
    return self.Controllable
  end
  
  function FSM_SET:_call_handler( handler, params )
    if self[handler] then
      self:E( "Calling " .. handler )
      return self[handler]( self, self.Set, unpack( params ) )
    end
  end

end -- FSM_SET

