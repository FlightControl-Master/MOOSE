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


  --local self = routines.utils.deepCopy( self ) -- Create a new self instance

  --assert(options.events)

  --local MT = {}
  --setmetatable( self, MT )
  --self.__index = self

  self.options = options or {}
  self.options.subs = self.options.subs or {}
  self.current = self.options.initial or 'none'
  self.events = {}
  self.subs = {}
  self.endstates = {}
  
  self.Scores = {}

  FsmT = FsmT or FSM_TEMPLATE:New( "" )

  self:SetStartState( FsmT:GetStartState() )

  for TransitionID, Transition in pairs( FsmT:GetTransitions() ) do
    self:AddTransition( Transition.From, Transition.Event, Transition.To )
  end

  self:CopyCallHandlers( FsmT )
  
  return self
end


function FSM:AddTransition( From, Event, To )

  local event = {}
  event.from = From
  event.name = Event
  event.to = To

  self:E( event )

  self:_eventmap( self.events, event )
end




--- Set the default @{Process} template with key ProcessName providing the ProcessClass and the process object when it is assigned to a @{Controllable} by the task.
-- @return Fsm.Fsm#FSM_PROCESS
function FSM:AddProcess( From, Event, Process, ReturnEvents )

  local sub = {}
  sub.FromParent = From
  sub.EventParent = Event
  sub.fsm = Process
  sub.event = "Start"
  sub.ReturnEvents = ReturnEvents
  
  self:_submap( self.subs, sub, nil )
  
  self:AddTransition( From, Event, From )

  return Process
end

function FSM:AddEndState( State )
  self.endstates[State] = State
end

function FSM:SetStartState( State )
  self.current = State
end

function FSM:GetSubs()

  return self.options.subs
end


function FSM:LoadCallBacks( CallBackTable )

  for name, callback in pairs( CallBackTable or {} ) do
    self[name] = callback
  end

end

function FSM:_eventmap( events, event )

    local name = event.name
    local __name = "__" .. event.name
    self[name] = self[name] or self:_create_transition(name)
    self[__name] = self[__name] or self:_delayed_transition(name)
    self:T( "Added methods: " .. name .. ", " .. __name )
    events[name] = self.events[name] or { map = {} }
    self:_add_to_map( events[name].map, event )

end

function FSM:_submap( subs, sub, name )
  self:F( { sub = sub, name = name } )
  subs[sub.FromParent] = subs[sub.FromParent] or {}
  subs[sub.FromParent][sub.EventParent] = subs[sub.FromParent][sub.EventParent] or {}
  
  -- Make the reference table weak.
  -- setmetatable( subs[sub.FromParent][sub.EventParent], { __mode = "k" } )
  
  subs[sub.FromParent][sub.EventParent][sub] = {}
  subs[sub.FromParent][sub.EventParent][sub].fsm = sub.fsm
  subs[sub.FromParent][sub.EventParent][sub].event = sub.event
  subs[sub.FromParent][sub.EventParent][sub].ReturnEvents = sub.ReturnEvents or {} -- these events need to be given to find the correct continue event ... if none given, the processing will stop.
  subs[sub.FromParent][sub.EventParent][sub].name = name
  subs[sub.FromParent][sub.EventParent][sub].fsmparent = self
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
      self:E( "calling sub event: " .. sub.event )
      sub.fsm.fsmparent = self
      sub.fsm.ReturnEvents = sub.ReturnEvents
      sub.fsm[sub.event]( sub.fsm )
      execute = true
    end

    local fsmparent, event = self:_isendstate( to )
    if fsmparent and event then
      self:F2( { "end state: ", fsmparent, event } )
      self:_call_handler("onenter" .. to, params)
      self:_call_handler("onafter" .. EventName, params)
      self:_call_handler("onstatechange", params)
      fsmparent[event]( fsmparent )
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
    SCHEDULER:New( self, self._handler, { EventName, ... }, DelaySeconds )
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

function FSM:_add_to_map(map, event)
  self:F3( { map, event } )
  if type(event.from) == 'string' then
    map[event.from] = event.to
  else
    for _, from in ipairs(event.from) do
      map[from] = event.to
    end
  end
  self:T3( { map, event } )
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
  local event = self.events[e]
  self:F3( { self.current, event } )
  local to = event and event.map[self.current] or event.map['*']
  return to ~= nil, to
end

function FSM:cannot(e)
  return not self:can(e)
end

function FSM:CopyCallHandlers( FsmT )

  local Parent = BASE:GetParent( FsmT )
  if Parent then
    self:CopyCallHandlers( Parent )
  end
  for ElementID, Element in pairs( FsmT ) do
    self:E( { ElementID = ElementID } )
    if type( Element ) == "function" then
      if ElementID.find( ElementID, "^onbefore" ) or
         ElementID.find( ElementID, "^onafter" ) or
         ElementID.find( ElementID, "^onenter" ) or
         ElementID.find( ElementID, "^onleave" ) or
         ElementID.find( ElementID, "^onfunc" ) then
        self[ ElementID ] = Element
      end
    end
  end
end


function FSM:todot(filename)
  local dotfile = io.open(filename,'w')
  dotfile:write('digraph {\n')
  local transition = function(event,from,to)
    dotfile:write(string.format('%s -> %s [label=%s];\n',from,to,event))
  end
  for _, event in pairs(self.options.events) do
    if type(event.from) == 'table' then
      for _, from in ipairs(event.from) do
        transition(event.name,from,event.to)
      end
    else
      transition(event.name,event.from,event.to)
    end
  end
  dotfile:write('}\n')
  dotfile:close()
end



--- FSM_CONTROLLABLE class
-- @type FSM_CONTROLLABLE
-- @field Wrapper.Controllable#CONTROLLABLE Controllable
-- @extends Fsm.Fsm#FSM
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
  local self = BASE:Inherit( self, FSM:New( FSMT ) ) -- Fsm.Fsm#FSM_CONTROLLABLE

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

--- FSM_PROCESS class
-- @type FSM_PROCESS
-- @field Tasking.Task#TASK_BASE Task
-- @extends Fsm.Fsm#FSM_CONTROLLABLE
FSM_PROCESS = {
  ClassName = "FSM_PROCESS",
}

--- Creates a new FSM_PROCESS object.
-- @param #FSM_PROCESS self
-- @return #FSM_PROCESS
function FSM_PROCESS:New( FsmT, Controllable, Task )

  FsmT = FsmT or FSM_TEMPLATE:New( "" )

  local self = BASE:Inherit( self, FSM_CONTROLLABLE:New( FsmT ) ) -- Fsm.Fsm#FSM_PROCESS

  self:Assign( Controllable, Task )

  
  for ParameterID, Parameter in pairs( FsmT:GetParameters() ) do
    self[ ParameterID ] = Parameter
  end

  for ProcessID, Process in pairs( FsmT:GetProcesses() ) do
    self:E( Process )
    local FsmProcess = self:AddProcess(Process.From, Process.Event, FSM_PROCESS:New( Process.Process, Controllable, Task ), Process.ReturnEvents )
  end

  for EndStateID, EndState in pairs( FsmT:GetEndStates() ) do
    self:E( EndState )
    self:AddEndState( EndState )
  end
  
  -- Copy the score tables
  for ScoreID, Score in pairs( FsmT:GetScores() ) do
    self:E( Score )
    self:AddScore( ScoreID,Score.ScoreText,Score.Score )
  end

  return self
end

--- Sets the task of the process.
-- @param #PROCESS self
-- @param Tasking.Task#TASK_BASE Task
-- @return #PROCESS
function FSM_PROCESS:SetTask( Task )

  self.Task = Task

  return self
end

--- Gets the task of the process.
-- @param #PROCESS self
-- @return Tasking.Task#TASK_BASE
function FSM_PROCESS:GetTask()

  return self.Task
end

--- Gets the mission of the process.
-- @param #PROCESS self
-- @return Tasking.Mission#MISSION
function FSM_PROCESS:GetMission()

  return self.Task.Mission
end


--- Assign the process to a @{Unit} and activate the process.
-- @param #FSM_PROCESS self
-- @param Task.Tasking#TASK_BASE Task
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
    MESSAGE:New( "Process " .. self.ProcessName .. " : " .. Event .. " changed to state " .. To, 15 ):ToAll()
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

--- FSM_TASK class
-- @type FSM_TASK
-- @field Tasking.Task#TASK_BASE Task
-- @extends Fsm.Fsm#FSM
FSM_TASK = {
  ClassName = "FSM_TASK",
}

--- Creates a new FSM_TASK object.
-- @param #FSM_TASK self
-- @param #table FSMT
-- @param Tasking.Task#TASK_BASE Task
-- @param Wrapper.Unit#UNIT TaskUnit
-- @return #FSM_TASK
function FSM_TASK:New( FSMT )

  local self = BASE:Inherit( self, FSM_CONTROLLABLE:New( FSMT ) ) -- Fsm.Fsm#FSM_TASK

  self["onstatechange"] = self.OnStateChange

  return self
end

function FSM_TASK:_call_handler( handler, params )
  if self[handler] then
    self:E( "Calling " .. handler )
    return self[handler]( self, unpack( params ) )
  end
end

do -- FSM_SET

--- FSM_SET class
-- @type FSM_SET
-- @field Core.Set#SET_BASE Set
-- @extends Fsm.Fsm#FSM
FSM_SET = {
  ClassName = "FSM_SET",
}

--- Creates a new FSM_SET object.
-- @param #FSM_SET self
-- @param #table FSMT Finite State Machine Table
-- @param Set_SET_BASE FSMSet (optional) The Set object that the FSM_SET governs.
-- @return #FSM_SET
function FSM_SET:New( FSMT, FSMSet )

  -- Inherits from BASE
  local self = BASE:Inherit( self, FSM:New( FSMT ) ) -- Fsm.Fsm#FSM_SET

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

end

--- FSM_TEMPLATE class
-- @type FSM_TEMPLATE
-- @extends Core.Base#BASE
FSM_TEMPLATE = {
  ClassName = "FSM_TEMPLATE",
}

--- Creates a new FSM_TEMPLATE object.
-- @param #FSM_TEMPLATE self
-- @return #FSM_TEMPLATE
function FSM_TEMPLATE:New( Name )

  -- Inherits from BASE
  local self = BASE:Inherit( self, BASE:New() ) -- #FSM_TEMPLATE
  
  self._StartState = "none"
  self._Transitions = {}
  self._Processes = {}
  self._EndStates = {}
  self._Scores = {}
  
  self._Name = Name or ""

  return self
end

function FSM_TEMPLATE:AddTransition( From, Event, To )

  local Transition = {}
  Transition.From = From
  Transition.Event = Event
  Transition.To = To

  self._Transitions[Transition] = Transition
end

function FSM_TEMPLATE:GetTransitions()

  return self._Transitions or {}
end

--- Set the default @{Process} template with key ProcessName providing the ProcessClass and the process object when it is assigned to a @{Controllable} by the task.
-- @return Fsm.Fsm#FSM_TEMPLATE The FSM Process Template.
function FSM_TEMPLATE:AddProcess( From, Event, ProcessTemplate, ReturnEvents )

  self:E( { ProcessTemplate = ProcessTemplate } )

  local Process = {}
  Process.From = From
  Process.Event = Event
  Process.Process = ProcessTemplate
  Process.Parameters = ProcessTemplate:GetParameters()
  Process.ReturnEvents = ReturnEvents
  
  self:E( { From = Process.From, Event = Process.Event, Process = Process.Process._Name, Parameters = Process.Parameters, ReturnEvents = Process.ReturnEvents } )
  
  -- Make the reference table weak.
  -- setmetatable( self.options.subs, { __mode = "v" } )
  self._Processes[Process] = Process

  return ProcessTemplate
end

function FSM_TEMPLATE:GetProcesses()

  return self._Processes or {}
end

function FSM_TEMPLATE:GetProcess( From, Event )

  for ProcessID, Process in pairs( self:GetProcesses() ) do
    if Process.From == From and Process.Event == Event then
      self:E( Process )
      return Process.Process
    end
  end
  
  error( "Sub-Process from state " .. From .. " with event " .. Event .. " not found!" )
end

function FSM_TEMPLATE:SetParameters( Parameters )
  self._Parameters = Parameters
end

function FSM_TEMPLATE:GetParameters()
  return self._Parameters or {}
end


function FSM_TEMPLATE:AddEndState( State )

  self._EndStates[State] = State
end

function FSM_TEMPLATE:GetEndStates()

  return self._EndStates or {}
end

function FSM_TEMPLATE:SetStartState( State )

  self._StartState = State
end

function FSM_TEMPLATE:GetStartState()

  return self._StartState or {}
end

--- Adds a score for the FSM_PROCESS to be achieved.
-- @param #FSM_TEMPLATE self
-- @param #string State is the state of the process when the score needs to be given. (See the relevant state descriptions of the process).
-- @param #string ScoreText is a text describing the score that is given according the status.
-- @param #number Score is a number providing the score of the status.
-- @return #FSM_TEMPLATE self
function FSM_TEMPLATE:AddScore( State, ScoreText, Score )
  self:F2( { State, ScoreText, Score } )

  self._Scores[State] = self._Scores[State] or {}
  self._Scores[State].ScoreText = ScoreText
  self._Scores[State].Score = Score

  return self
end

--- Adds a score for the FSM_PROCESS to be achieved.
-- @param #FSM_TEMPLATE self
-- @param #string From is the From State of the main process.
-- @param #string Event is the Event of the main process.
-- @param #string State is the state of the process when the score needs to be given. (See the relevant state descriptions of the process).
-- @param #string ScoreText is a text describing the score that is given according the status.
-- @param #number Score is a number providing the score of the status.
-- @return #FSM_TEMPLATE self
function FSM_TEMPLATE:AddScoreProcess( From, Event, State, ScoreText, Score )
  self:F2( { Event, State, ScoreText, Score } )

  local Process = self:GetProcess( From, Event )
  
  self:E( { Process = Process._Name, Scores = Process._Scores, State = State, ScoreText = ScoreText, Score = Score } )
  Process._Scores[State] = Process._Scores[State] or {}
  Process._Scores[State].ScoreText = ScoreText
  Process._Scores[State].Score = Score

  return Process
end

function FSM_TEMPLATE:GetScores()

  return self._Scores or {}
end
