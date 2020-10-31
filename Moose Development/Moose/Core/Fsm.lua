--- **Core** - FSM (Finite State Machine) are objects that model and control long lasting business processes and workflow.
-- 
-- ===
-- 
-- ## Features:
-- 
--   * Provide a base class to model your own state machines.
--   * Trigger events synchronously.
--   * Trigger events asynchronously.
--   * Handle events before or after the event was triggered.
--   * Handle state transitions as a result of event before and after the state change.
--   * For internal moose purposes, further state machines have been designed:
--     - to handle controllables (groups and units).
--     - to handle tasks.
--     - to handle processes.
-- 
-- ===
-- 
-- A Finite State Machine (FSM) models a process flow that transitions between various **States** through triggered **Events**.
-- 
-- A FSM can only be in one of a finite number of states. 
-- The machine is in only one state at a time; the state it is in at any given time is called the **current state**. 
-- It can change from one state to another when initiated by an **__internal__ or __external__ triggering event**, which is called a **transition**. 
-- An **FSM implementation** is defined by **a list of its states**, **its initial state**, and **the triggering events** for **each possible transition**.
-- An FSM implementation is composed out of **two parts**, a set of **state transition rules**, and an implementation set of **state transition handlers**, implementing those transitions.
-- 
-- The FSM class supports a **hierarchical implementation of a Finite State Machine**, 
-- that is, it allows to **embed existing FSM implementations in a master FSM**.
-- FSM hierarchies allow for efficient FSM re-use, **not having to re-invent the wheel every time again** when designing complex processes.
-- 
-- ![Workflow Example](..\Presentations\FSM\Dia2.JPG)
-- 
-- The above diagram shows a graphical representation of a FSM implementation for a **Task**, which guides a Human towards a Zone,
-- orders him to destroy x targets and account the results.
-- Other examples of ready made FSM could be: 
-- 
--   * route a plane to a zone flown by a human
--   * detect targets by an AI and report to humans
--   * account for destroyed targets by human players
--   * handle AI infantry to deploy from or embark to a helicopter or airplane or vehicle 
--   * let an AI patrol a zone
-- 
-- The **MOOSE framework** uses extensively the FSM class and derived FSM\_ classes, 
-- because **the goal of MOOSE is to simplify mission design complexity for mission building**.
-- By efficiently utilizing the FSM class and derived classes, MOOSE allows mission designers to quickly build processes.
-- **Ready made FSM-based implementations classes** exist within the MOOSE framework that **can easily be re-used, 
-- and tailored** by mission designers through **the implementation of Transition Handlers**.
-- Each of these FSM implementation classes start either with:
-- 
--   * an acronym **AI\_**, which indicates an FSM implementation directing **AI controlled** @{GROUP} and/or @{UNIT}. These AI\_ classes derive the @{#FSM_CONTROLLABLE} class.
--   * an acronym **TASK\_**, which indicates an FSM implementation executing a @{TASK} executed by Groups of players. These TASK\_ classes derive the @{#FSM_TASK} class.
--   * an acronym **ACT\_**, which indicates an Sub-FSM implementation, directing **Humans actions** that need to be done in a @{TASK}, seated in a @{CLIENT} (slot) or a @{UNIT} (CA join). These ACT\_ classes derive the @{#FSM_PROCESS} class.
-- 
-- Detailed explanations and API specifics are further below clarified and FSM derived class specifics are described in those class documentation sections.
-- 
-- ##__Dislaimer:__
-- The FSM class development is based on a finite state machine implementation made by Conroy Kyle.
-- The state machine can be found on [github](https://github.com/kyleconroy/lua-state-machine)
-- I've reworked this development (taken the concept), and created a **hierarchical state machine** out of it, embedded within the DCS simulator.
-- Additionally, I've added extendability and created an API that allows seamless FSM implementation.
-- 
-- The following derived classes are available in the MOOSE framework, that implement a specialised form of a FSM:
-- 
--   * @{#FSM_TASK}: Models Finite State Machines for @{Task}s.
--   * @{#FSM_PROCESS}: Models Finite State Machines for @{Task} actions, which control @{Client}s.
--   * @{#FSM_CONTROLLABLE}: Models Finite State Machines for @{Wrapper.Controllable}s, which are @{Wrapper.Group}s, @{Wrapper.Unit}s, @{Client}s.
--   * @{#FSM_SET}: Models Finite State Machines for @{Set}s. Note that these FSMs control multiple objects!!! So State concerns here
--     for multiple objects or the position of the state machine in the process.
-- 
-- ===
-- 
-- 
-- ### Author: **FlightControl**
-- ### Contributions: **funkyfranky**
-- 
-- ===
--
-- @module Core.Fsm
-- @image Core_Finite_State_Machine.JPG

do -- FSM

  --- @type FSM
  -- @field #string ClassName Name of the class.
  -- @field Core.Scheduler#SCHEDULER CallScheduler Call scheduler.
  -- @field #table options Options.
  -- @field #table subs Subs.
  -- @field #table Scores Scores.
  -- @field #string current Current state name.
  -- @extends Core.Base#BASE
  
  
  --- A Finite State Machine (FSM) models a process flow that transitions between various **States** through triggered **Events**.
  -- 
  -- A FSM can only be in one of a finite number of states. 
  -- The machine is in only one state at a time; the state it is in at any given time is called the **current state**. 
  -- It can change from one state to another when initiated by an **__internal__ or __external__ triggering event**, which is called a **transition**. 
  -- An **FSM implementation** is defined by **a list of its states**, **its initial state**, and **the triggering events** for **each possible transition**.
  -- An FSM implementation is composed out of **two parts**, a set of **state transition rules**, and an implementation set of **state transition handlers**, implementing those transitions.
  -- 
  -- The FSM class supports a **hierarchical implementation of a Finite State Machine**, 
  -- that is, it allows to **embed existing FSM implementations in a master FSM**.
  -- FSM hierarchies allow for efficient FSM re-use, **not having to re-invent the wheel every time again** when designing complex processes.
  -- 
  -- ![Workflow Example](..\Presentations\FSM\Dia2.JPG)
  -- 
  -- The above diagram shows a graphical representation of a FSM implementation for a **Task**, which guides a Human towards a Zone,
  -- orders him to destroy x targets and account the results.
  -- Other examples of ready made FSM could be: 
  -- 
  --   * route a plane to a zone flown by a human
  --   * detect targets by an AI and report to humans
  --   * account for destroyed targets by human players
  --   * handle AI infantry to deploy from or embark to a helicopter or airplane or vehicle 
  --   * let an AI patrol a zone
  -- 
  -- The **MOOSE framework** uses extensively the FSM class and derived FSM\_ classes, 
  -- because **the goal of MOOSE is to simplify mission design complexity for mission building**.
  -- By efficiently utilizing the FSM class and derived classes, MOOSE allows mission designers to quickly build processes.
  -- **Ready made FSM-based implementations classes** exist within the MOOSE framework that **can easily be re-used, 
  -- and tailored** by mission designers through **the implementation of Transition Handlers**.
  -- Each of these FSM implementation classes start either with:
  -- 
  --   * an acronym **AI\_**, which indicates an FSM implementation directing **AI controlled** @{GROUP} and/or @{UNIT}. These AI\_ classes derive the @{#FSM_CONTROLLABLE} class.
  --   * an acronym **TASK\_**, which indicates an FSM implementation executing a @{TASK} executed by Groups of players. These TASK\_ classes derive the @{#FSM_TASK} class.
  --   * an acronym **ACT\_**, which indicates an Sub-FSM implementation, directing **Humans actions** that need to be done in a @{TASK}, seated in a @{CLIENT} (slot) or a @{UNIT} (CA join). These ACT\_ classes derive the @{#FSM_PROCESS} class.
  -- 
  -- ![Transition Rules and Transition Handlers and Event Triggers](..\Presentations\FSM\Dia3.JPG)
  -- 
  -- The FSM class is the base class of all FSM\_ derived classes. It implements the main functionality to define and execute Finite State Machines.
  -- The derived FSM\_ classes extend the Finite State Machine functionality to run a workflow process for a specific purpose or component.
  -- 
  -- Finite State Machines have **Transition Rules**, **Transition Handlers** and **Event Triggers**.
  -- 
  -- The **Transition Rules** define the "Process Flow Boundaries", that is, 
  -- the path that can be followed hopping from state to state upon triggered events.
  -- If an event is triggered, and there is no valid path found for that event, 
  -- an error will be raised and the FSM will stop functioning.
  -- 
  -- The **Transition Handlers** are special methods that can be defined by the mission designer, following a defined syntax.
  -- If the FSM object finds a method of such a handler, then the method will be called by the FSM, passing specific parameters.
  -- The method can then define its own custom logic to implement the FSM workflow, and to conduct other actions.
  -- 
  -- The **Event Triggers** are methods that are defined by the FSM, which the mission designer can use to implement the workflow.
  -- Most of the time, these Event Triggers are used within the Transition Handler methods, so that a workflow is created running through the state machine.
  -- 
  -- As explained above, a FSM supports **Linear State Transitions** and **Hierarchical State Transitions**, and both can be mixed to make a comprehensive FSM implementation.
  -- The below documentation has a seperate chapter explaining both transition modes, taking into account the **Transition Rules**, **Transition Handlers** and **Event Triggers**.
  -- 
  -- ## FSM Linear Transitions
  -- 
  -- Linear Transitions are Transition Rules allowing an FSM to transition from one or multiple possible **From** state(s) towards a **To** state upon a Triggered **Event**.
  -- The Lineair transition rule evaluation will always be done from the **current state** of the FSM.
  -- If no valid Transition Rule can be found in the FSM, the FSM will log an error and stop.
  -- 
  -- ### FSM Transition Rules
  -- 
  -- The FSM has transition rules that it follows and validates, as it walks the process. 
  -- These rules define when an FSM can transition from a specific state towards an other specific state upon a triggered event.
  -- 
  -- The method @{#FSM.AddTransition}() specifies a new possible Transition Rule for the FSM. 
  -- 
  -- The initial state can be defined using the method @{#FSM.SetStartState}(). The default start state of an FSM is "None".
  -- 
  -- Find below an example of a Linear Transition Rule definition for an FSM.
  -- 
  --      local Fsm3Switch = FSM:New() -- #FsmDemo
  --      FsmSwitch:SetStartState( "Off" )
  --      FsmSwitch:AddTransition( "Off", "SwitchOn", "On" )
  --      FsmSwitch:AddTransition( "Off", "SwitchMiddle", "Middle" )
  --      FsmSwitch:AddTransition( "On", "SwitchOff", "Off" )
  --      FsmSwitch:AddTransition( "Middle", "SwitchOff", "Off" )
  -- 
  -- The above code snippet models a 3-way switch Linear Transition:
  -- 
  --    * It can be switched **On** by triggering event **SwitchOn**.
  --    * It can be switched to the **Middle** position, by triggering event **SwitchMiddle**.
  --    * It can be switched **Off** by triggering event **SwitchOff**.
  --    * Note that once the Switch is **On** or **Middle**, it can only be switched **Off**.
  -- 
  -- #### Some additional comments:
  -- 
  -- Note that Linear Transition Rules **can be declared in a few variations**:
  -- 
  --    * The From states can be **a table of strings**, indicating that the transition rule will be valid **if the current state** of the FSM will be **one of the given From states**.
  --    * The From state can be a **"*"**, indicating that **the transition rule will always be valid**, regardless of the current state of the FSM.
  --   
  -- The below code snippet shows how the two last lines can be rewritten and consensed.
  -- 
  --      FsmSwitch:AddTransition( { "On",  "Middle" }, "SwitchOff", "Off" )
  -- 
  -- ### Transition Handling
  -- 
  -- ![Transition Handlers](..\Presentations\FSM\Dia4.JPG)
  -- 
  -- An FSM transitions in **4 moments** when an Event is being triggered and processed.  
  -- The mission designer can define for each moment specific logic within methods implementations following a defined API syntax.  
  -- These methods define the flow of the FSM process; because in those methods the FSM Internal Events will be triggered.
  --
  --    * To handle **State** transition moments, create methods starting with OnLeave or OnEnter concatenated with the State name.
  --    * To handle **Event** transition moments, create methods starting with OnBefore or OnAfter concatenated with the Event name.
  -- 
  -- **The OnLeave and OnBefore transition methods may return false, which will cancel the transition!**
  -- 
  -- Transition Handler methods need to follow the above specified naming convention, but are also passed parameters from the FSM.
  -- These parameters are on the correct order: From, Event, To:
  -- 
  --    * From = A string containing the From state.
  --    * Event = A string containing the Event name that was triggered.
  --    * To = A string containing the To state.
  -- 
  -- On top, each of these methods can have a variable amount of parameters passed. See the example in section [1.1.3](#1.1.3\)-event-triggers).
  -- 
  -- ### Event Triggers
  -- 
  -- ![Event Triggers](..\Presentations\FSM\Dia5.JPG)
  -- 
  -- The FSM creates for each Event two **Event Trigger methods**.  
  -- There are two modes how Events can be triggered, which is **synchronous** and **asynchronous**:
  -- 
  --    * The method **FSM:Event()** triggers an Event that will be processed **synchronously** or **immediately**.
  --    * The method **FSM:__Event( __seconds__ )** triggers an Event that will be processed **asynchronously** over time, waiting __x seconds__.
  -- 
  -- The destinction between these 2 Event Trigger methods are important to understand. An asynchronous call will "log" the Event Trigger to be executed at a later time.
  -- Processing will just continue. Synchronous Event Trigger methods are useful to change states of the FSM immediately, but may have a larger processing impact.
  -- 
  -- The following example provides a little demonstration on the difference between synchronous and asynchronous Event Triggering.
  -- 
  --       function FSM:OnAfterEvent( From, Event, To, Amount )
  --         self:T( { Amount = Amount } ) 
  --       end
  --       
  --       local Amount = 1
  --       FSM:__Event( 5, Amount ) 
  --       
  --       Amount = Amount + 1
  --       FSM:Event( Text, Amount )
  --       
  -- In this example, the **:OnAfterEvent**() Transition Handler implementation will get called when **Event** is being triggered.
  -- Before we go into more detail, let's look at the last 4 lines of the example. 
  -- The last line triggers synchronously the **Event**, and passes Amount as a parameter.
  -- The 3rd last line of the example triggers asynchronously **Event**. 
  -- Event will be processed after 5 seconds, and Amount is given as a parameter.
  -- 
  -- The output of this little code fragment will be:
  -- 
  --    * Amount = 2
  --    * Amount = 2
  -- 
  -- Because ... When Event was asynchronously processed after 5 seconds, Amount was set to 2. So be careful when processing and passing values and objects in asynchronous processing!
  -- 
  -- ### Linear Transition Example
  -- 
  -- This example is fully implemented in the MOOSE test mission on GITHUB: [FSM-100 - Transition Explanation](https://github.com/FlightControl-Master/MOOSE/blob/master/Moose%20Test%20Missions/FSM%20-%20Finite%20State%20Machine/FSM-100%20-%20Transition%20Explanation/FSM-100%20-%20Transition%20Explanation.lua)
  -- 
  -- It models a unit standing still near Batumi, and flaring every 5 seconds while switching between a Green flare and a Red flare.
  -- The purpose of this example is not to show how exciting flaring is, but it demonstrates how a Linear Transition FSM can be build.
  -- Have a look at the source code. The source code is also further explained below in this section.
  -- 
  -- The example creates a new FsmDemo object from class FSM.
  -- It will set the start state of FsmDemo to state **Green**.
  -- Two Linear Transition Rules are created, where upon the event **Switch**,
  -- the FsmDemo will transition from state **Green** to **Red** and from **Red** back to **Green**.
  -- 
  -- ![Transition Example](..\Presentations\FSM\Dia6.JPG)
  -- 
  --      local FsmDemo = FSM:New() -- #FsmDemo
  --      FsmDemo:SetStartState( "Green" )
  --      FsmDemo:AddTransition( "Green", "Switch", "Red" )
  --      FsmDemo:AddTransition( "Red", "Switch", "Green" )
  -- 
  -- In the above example, the FsmDemo could flare every 5 seconds a Green or a Red flare into the air.
  -- The next code implements this through the event handling method **OnAfterSwitch**.
  -- 
  -- ![Transition Flow](..\Presentations\FSM\Dia7.JPG)
  -- 
  --      function FsmDemo:OnAfterSwitch( From, Event, To, FsmUnit )
  --        self:T( { From, Event, To, FsmUnit } )
  --        
  --        if From == "Green" then
  --          FsmUnit:Flare(FLARECOLOR.Green)
  --        else
  --          if From == "Red" then
  --            FsmUnit:Flare(FLARECOLOR.Red)
  --          end
  --        end
  --        self:__Switch( 5, FsmUnit ) -- Trigger the next Switch event to happen in 5 seconds.
  --      end
  --      
  --      FsmDemo:__Switch( 5, FsmUnit ) -- Trigger the first Switch event to happen in 5 seconds.
  -- 
  -- The OnAfterSwitch implements a loop. The last line of the code fragment triggers the Switch Event within 5 seconds.
  -- Upon the event execution (after 5 seconds), the OnAfterSwitch method is called of FsmDemo (cfr. the double point notation!!! ":").
  -- The OnAfterSwitch method receives from the FSM the 3 transition parameter details ( From, Event, To ), 
  -- and one additional parameter that was given when the event was triggered, which is in this case the Unit that is used within OnSwitchAfter.
  -- 
  --      function FsmDemo:OnAfterSwitch( From, Event, To, FsmUnit )
  -- 
  -- For debugging reasons the received parameters are traced within the DCS.log.
  -- 
  --         self:T( { From, Event, To, FsmUnit } )
  -- 
  -- The method will check if the From state received is either "Green" or "Red" and will flare the respective color from the FsmUnit.
  -- 
  --        if From == "Green" then
  --          FsmUnit:Flare(FLARECOLOR.Green)
  --        else
  --          if From == "Red" then
  --            FsmUnit:Flare(FLARECOLOR.Red)
  --          end
  --        end
  -- 
  -- It is important that the Switch event is again triggered, otherwise, the FsmDemo would stop working after having the first Event being handled.
  -- 
  --        FsmDemo:__Switch( 5, FsmUnit ) -- Trigger the next Switch event to happen in 5 seconds.
  -- 
  -- The below code fragment extends the FsmDemo, demonstrating multiple **From states declared as a table**, adding a **Linear Transition Rule**.
  -- The new event **Stop** will cancel the Switching process.
  -- The transition for event Stop can be executed if the current state of the FSM is either "Red" or "Green".
  -- 
  --      local FsmDemo = FSM:New() -- #FsmDemo
  --      FsmDemo:SetStartState( "Green" )
  --      FsmDemo:AddTransition( "Green", "Switch", "Red" )
  --      FsmDemo:AddTransition( "Red", "Switch", "Green" )
  --      FsmDemo:AddTransition( { "Red", "Green" }, "Stop", "Stopped" )
  -- 
  -- The transition for event Stop can also be simplified, as any current state of the FSM is valid.
  -- 
  --      FsmDemo:AddTransition( "*", "Stop", "Stopped" )
  --      
  -- So... When FsmDemo:Stop() is being triggered, the state of FsmDemo will transition from Red or Green to Stopped.
  -- And there is no transition handling method defined for that transition, thus, no new event is being triggered causing the FsmDemo process flow to halt.
  -- 
  -- ## FSM Hierarchical Transitions
  -- 
  -- Hierarchical Transitions allow to re-use readily available and implemented FSMs.
  -- This becomes in very useful for mission building, where mission designers build complex processes and workflows, 
  -- combining smaller FSMs to one single FSM.
  -- 
  -- The FSM can embed **Sub-FSMs** that will execute and return **multiple possible Return (End) States**.  
  -- Depending upon **which state is returned**, the main FSM can continue the flow **triggering specific events**.
  -- 
  -- The method @{#FSM.AddProcess}() adds a new Sub-FSM to the FSM.  
  --
  -- ===
  -- 
  -- @field #FSM
  -- 
  FSM = {
    ClassName = "FSM",
  }
  
  --- Creates a new FSM object.
  -- @param #FSM self
  -- @return #FSM
  function FSM:New()
  
    -- Inherits from BASE
    self = BASE:Inherit( self, BASE:New() )
  
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
    self._EventSchedules = {}
    
    self.CallScheduler = SCHEDULER:New( self )
     
    return self
  end
  
  
  --- Sets the start state of the FSM.
  -- @param #FSM self
  -- @param #string State A string defining the start state.
  function FSM:SetStartState( State )
    self._StartState = State
    self.current = State
  end
  
  
  --- Returns the start state of the FSM.
  -- @param #FSM self
  -- @return #string A string containing the start state.
  function FSM:GetStartState()
    return self._StartState or {}
  end
  
  --- Add a new transition rule to the FSM.
  -- A transition rule defines when and if the FSM can transition from a state towards another state upon a triggered event.
  -- @param #FSM self
  -- @param #table From Can contain a string indicating the From state or a table of strings containing multiple From states.
  -- @param #string Event The Event name.
  -- @param #string To The To state.
  function FSM:AddTransition( From, Event, To )
  
    local Transition = {}
    Transition.From = From
    Transition.Event = Event
    Transition.To = To
  
    -- Debug message.
    self:T2( Transition )
    
    self._Transitions[Transition] = Transition
    self:_eventmap( self.Events, Transition )
  end

  
  --- Returns a table of the transition rules defined within the FSM.
  -- @param #FSM self
  -- @return #table Transitions.
  function FSM:GetTransitions()  
    return self._Transitions or {}
  end
  
  --- Set the default @{Process} template with key ProcessName providing the ProcessClass and the process object when it is assigned to a @{Wrapper.Controllable} by the task.
  -- @param #FSM self
  -- @param #table From Can contain a string indicating the From state or a table of strings containing multiple From states.
  -- @param #string Event The Event name.
  -- @param Core.Fsm#FSM_PROCESS Process An sub-process FSM.
  -- @param #table ReturnEvents A table indicating for which returned events of the SubFSM which Event must be triggered in the FSM.
  -- @return Core.Fsm#FSM_PROCESS The SubFSM.
  function FSM:AddProcess( From, Event, Process, ReturnEvents )
    self:T( { From, Event } )
  
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
  
  
  --- Returns a table of the SubFSM rules defined within the FSM.
  -- @param #FSM self
  -- @return #table Sub processes.
  function FSM:GetProcesses()
  
    self:F( { Processes = self._Processes } )
  
    return self._Processes or {}
  end
  
  function FSM:GetProcess( From, Event )
  
    for ProcessID, Process in pairs( self:GetProcesses() ) do
      if Process.From == From and Process.Event == Event then
        return Process.fsm
      end
    end
    
    error( "Sub-Process from state " .. From .. " with event " .. Event .. " not found!" )
  end
  
  function FSM:SetProcess( From, Event, Fsm )
  
    for ProcessID, Process in pairs( self:GetProcesses() ) do
      if Process.From == From and Process.Event == Event then
        Process.fsm = Fsm
        return true
      end
    end
    
    error( "Sub-Process from state " .. From .. " with event " .. Event .. " not found!" )
  end
  
  --- Adds an End state.
  -- @param #FSM self
  -- @param #string State The FSM state.
  function FSM:AddEndState( State )  
    self._EndStates[State] = State
    self.endstates[State] = State
  end
  
  --- Returns the End states.
  -- @param #FSM self
  -- @return #table End states.
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
    self:F( { State, ScoreText, Score } )
  
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
    self:F( { From, Event, State, ScoreText, Score } )
  
    local Process = self:GetProcess( From, Event )
    
    Process._Scores[State] = Process._Scores[State] or {}
    Process._Scores[State].ScoreText = ScoreText
    Process._Scores[State].Score = Score
    
    self:T( Process._Scores )
  
    return Process
  end
  
  --- Returns a table with the scores defined.
  -- @param #FSM self
  -- @param #table Scores.
  function FSM:GetScores()  
    return self._Scores or {}
  end
  
  --- Returns a table with the Subs defined.
  -- @param #FSM self
  -- @return #table Sub processes.
  function FSM:GetSubs()  
    return self.options.subs
  end
  
  --- Load call backs.
  -- @param #FSM self
  -- @param #table CallBackTable Table of call backs.  
  function FSM:LoadCallBacks( CallBackTable )
  
    for name, callback in pairs( CallBackTable or {} ) do
      self[name] = callback
    end
  
  end
 
   --- Event map.
  -- @param #FSM self
  -- @param #table Events Events.
  -- @param #table EventStructure Event structure.
  function FSM:_eventmap( Events, EventStructure )
  
      local Event = EventStructure.Event
      local __Event = "__" .. EventStructure.Event
      
      self[Event] = self[Event] or self:_create_transition(Event)
      self[__Event] = self[__Event] or self:_delayed_transition(Event)
      
      -- Debug message.
      self:T2( "Added methods: " .. Event .. ", " .. __Event )
      
      Events[Event] = self.Events[Event] or { map = {} }
      self:_add_to_map( Events[Event].map, EventStructure )
  
  end

   --- Sub maps.
  -- @param #FSM self
  -- @param #table subs Subs.
  -- @param #table sub Sub.
  -- @param #string name Name.  
  function FSM:_submap( subs, sub, name )
  
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
  
  --- Call handler.
  -- @param #FSM self
  -- @param #string step Step "onafter", "onbefore", "onenter", "onleave".
  -- @param #string trigger Trigger.
  -- @param #table params Parameters.
  -- @param #string EventName Event name.
  -- @return Value.
  function FSM:_call_handler( step, trigger, params, EventName )
    --env.info(string.format("FF T=%.3f _call_handler step=%s, trigger=%s, event=%s", timer.getTime(), step, trigger, EventName))

    local handler = step .. trigger
        
    if self[handler] then
    
      --[[
      if step == "onafter" or step == "OnAfter" then
        self:T( ":::>" .. step .. params[2] .. " : " .. params[1] .. " >> " .. params[2] .. ">" .. step .. params[2] .. "()" .. " >> " .. params[3] )
      elseif step == "onbefore" or step == "OnBefore" then
        self:T( ":::>" .. step .. params[2] .. " : " .. params[1] .. " >> " .. step .. params[2] .. "()" .. ">" .. params[2] .. " >> " .. params[3] )
      elseif step == "onenter" or step == "OnEnter" then
        self:T( ":::>" .. step .. params[3] .. " : " .. params[1] .. " >> " .. params[2] .. " >> "  .. step .. params[3] .. "()" .. ">" .. params[3] )
      elseif step == "onleave" or step == "OnLeave" then
        self:T( ":::>" .. step .. params[1] .. " : " .. params[1] .. ">" .. step .. params[1] .. "()" .. " >> " .. params[2] .. " >> " .. params[3] )
      else
        self:T( ":::>" .. step .. " : " .. params[1] .. " >> " .. params[2] .. " >> " .. params[3] )
      end
      ]]
      
      self._EventSchedules[EventName] = nil

      -- Error handler.
      local ErrorHandler = function( errmsg )
        env.info( "Error in SCHEDULER function:" .. errmsg )
        if BASE.Debug ~= nil then
          env.info( BASE.Debug.traceback() )
        end      
        return errmsg
      end
      
      --return self[handler](self, unpack( params ))
      
      -- Protected call.
      local Result, Value = xpcall( function() return self[handler]( self, unpack( params ) ) end, ErrorHandler )      
      return Value      
    end
    
  end
  
  --- Handler.
  -- @param #FSM self
  -- @param #string EventName Event name.
  -- @param ... Arguments.
  function FSM._handler( self, EventName, ... )
  
    local Can, To = self:can( EventName )
  
    if To == "*" then
      To = self.current
    end
  
    if Can then
    
      -- From state.
      local From = self.current
      
      -- Parameters.
      local Params = { From, EventName, To, ...  }


      if self["onleave".. From] or
         self["OnLeave".. From] or
         self["onbefore".. EventName] or
         self["OnBefore".. EventName] or
         self["onafter".. EventName] or
         self["OnAfter".. EventName] or
         self["onenter".. To] or
         self["OnEnter".. To] then
         
        if self:_call_handler( "onbefore", EventName, Params, EventName ) == false then
          self:T( "*** FSM ***    Cancel" .. " *** " .. self.current .. " --> " .. EventName .. " --> " .. To .. " *** onbefore" .. EventName )
          return false
        else
          if self:_call_handler( "OnBefore", EventName, Params, EventName ) == false then
            self:T( "*** FSM ***    Cancel" .. " *** " .. self.current .. " --> " .. EventName .. " --> " .. To .. " *** OnBefore" .. EventName )
            return false
          else
            if self:_call_handler( "onleave", From, Params, EventName ) == false then  
              self:T( "*** FSM ***    Cancel" .. " *** " .. self.current .. " --> " .. EventName .. " --> " .. To .. " *** onleave" .. From )
              return false
            else
              if self:_call_handler( "OnLeave", From, Params, EventName ) == false then
                self:T( "*** FSM ***    Cancel" .. " *** " .. self.current .. " --> " .. EventName .. " --> " .. To .. " *** OnLeave" .. From )
                return false
              end
            end  
          end
        end
        
      else
      
        local ClassName = self:GetClassName()
        
        if ClassName == "FSM" then
          self:T( "*** FSM ***    Transit *** " .. self.current .. " --> " .. EventName .. " --> " .. To )
        end
  
        if ClassName == "FSM_TASK" then
          self:T( "*** FSM ***    Transit *** " .. self.current .. " --> " .. EventName .. " --> " .. To .. " *** Task: " .. self.TaskName )
        end
  
        if ClassName == "FSM_CONTROLLABLE" then
          self:T( "*** FSM ***    Transit *** " .. self.current .. " --> " .. EventName .. " --> " .. To .. " *** TaskUnit: " .. self.Controllable.ControllableName .. " *** "  )
        end        
    
        if ClassName == "FSM_PROCESS" then
          self:T( "*** FSM ***    Transit *** " .. self.current .. " --> " .. EventName .. " --> " .. To .. " *** Task: " .. self.Task:GetName() .. ", TaskUnit: " .. self.Controllable.ControllableName .. " *** "  )
        end        
      end
  
      -- New current state.
      self.current = To
  
      local execute = true
  
      local subtable = self:_gosub( From, EventName )
      
      for _, sub in pairs( subtable ) do
      
        --if sub.nextevent then
        --  self:F2( "nextevent = " .. sub.nextevent )
        --  self[sub.nextevent]( self )
        --end
        
        self:T( "*** FSM ***    Sub *** " .. sub.StartEvent )
        
        sub.fsm.fsmparent = self
        sub.fsm.ReturnEvents = sub.ReturnEvents
        sub.fsm[sub.StartEvent]( sub.fsm )
        
        execute = false
      end
  
      local fsmparent, Event = self:_isendstate( To )
      
      if fsmparent and Event then
      
        self:T( "*** FSM ***    End *** " .. Event )
        
        self:_call_handler("onenter", To, Params, EventName )
        self:_call_handler("OnEnter", To, Params, EventName )
        self:_call_handler("onafter", EventName, Params, EventName )
        self:_call_handler("OnAfter", EventName, Params, EventName )
        self:_call_handler("onstate", "change", Params, EventName )
        
        fsmparent[Event]( fsmparent )
        
        execute = false
      end
  
      if execute then
      
        self:_call_handler("onafter", EventName, Params, EventName )
        self:_call_handler("OnAfter", EventName, Params, EventName )
    
        self:_call_handler("onenter", To, Params, EventName )
        self:_call_handler("OnEnter", To, Params, EventName )
    
        self:_call_handler("onstate", "change", Params, EventName )
        
      end
    else
      self:T( "*** FSM *** NO Transition *** " .. self.current .. " --> " .. EventName .. " -->  ? " )
    end
  
    return nil
  end

  --- Delayed transition.
  -- @param #FSM self
  -- @param #string EventName Event name.  
  -- @return #function Function.
  function FSM:_delayed_transition( EventName )
  
    return function( self, DelaySeconds, ... )
    
      -- Debug.
      self:T2( "Delayed Event: " .. EventName )
      
      local CallID = 0
      if DelaySeconds ~= nil then
      
        if DelaySeconds < 0 then -- Only call the event ONCE!
        
          DelaySeconds = math.abs( DelaySeconds )
          
          if not self._EventSchedules[EventName] then
          
            -- Call _handler.
            CallID = self.CallScheduler:Schedule( self, self._handler, { EventName, ... }, DelaySeconds or 1, nil, nil, nil, 4, true )
            
            -- Set call ID.
            self._EventSchedules[EventName] = CallID
            
            -- Debug output.
            self:T2(string.format("NEGATIVE Event %s delayed by %.1f sec SCHEDULED with CallID=%s", EventName, DelaySeconds, tostring(CallID)))
          else
            self:T2(string.format("NEGATIVE Event %s delayed by %.1f sec CANCELLED as we already have such an event in the queue.", EventName, DelaySeconds))
            -- reschedule
          end
        else
        
          CallID = self.CallScheduler:Schedule( self, self._handler, { EventName, ... }, DelaySeconds or 1, nil, nil, nil, 4, true )
          
          self:T2(string.format("Event %s delayed by %.1f sec SCHEDULED with CallID=%s", EventName, DelaySeconds, tostring(CallID)))
        end
      else
        error( "FSM: An asynchronous event trigger requires a DelaySeconds parameter!!! This can be positive or negative! Sorry, but will not process this." )
      end
      
      -- Debug.
      self:T2( { CallID = CallID } )
    end
    
  end

  --- Create transition.
  -- @param #FSM self
  -- @param #string EventName Event name.  
  -- @return #function Function.  
  function FSM:_create_transition( EventName )
    return function( self, ... ) return self._handler( self,  EventName , ... ) end
  end
 
  --- Go sub.
  -- @param #FSM self 
  -- @param #string ParentFrom Parent from state.
  -- @param #string ParentEvent Parent event name.
  -- @return #table Subs.
  function FSM:_gosub( ParentFrom, ParentEvent )
    local fsmtable = {}
    if self.subs[ParentFrom] and self.subs[ParentFrom][ParentEvent] then
      self:T( { ParentFrom, ParentEvent, self.subs[ParentFrom], self.subs[ParentFrom][ParentEvent] } )
      return self.subs[ParentFrom][ParentEvent]
    else
      return {}
    end
  end

  --- Is end state.
  -- @param #FSM self
  -- @param #string Current Current state name.
  -- @return #table FSM parent.
  -- @return #string Event name.
  function FSM:_isendstate( Current )
    local FSMParent = self.fsmparent
    
    if FSMParent and self.endstates[Current] then
      --self:T( { state = Current, endstates = self.endstates, endstate = self.endstates[Current] } )
      FSMParent.current = Current
      local ParentFrom = FSMParent.current
      --self:T( { ParentFrom, self.ReturnEvents } )
      local Event = self.ReturnEvents[Current]
      --self:T( { Event } )
      if Event then
        return FSMParent, Event
      else
        --self:T( { "Could not find parent event name for state ", ParentFrom } )
      end
    end
  
    return nil
  end

  --- Add to map.
  -- @param #FSM self
  -- @param #table Map Map.
  -- @param #table Event Event table.
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

  --- Get current state.
  -- @param #FSM self
  -- @return #string Current FSM state.
  function FSM:GetState()
    return self.current
  end

  --- Get current state.
  -- @param #FSM self
  -- @return #string Current FSM state.  
  function FSM:GetCurrentState()
    return self.current
  end
  
  --- Check if FSM is in state.
  -- @param #FSM self
  -- @param #string State State name.
  -- @return #boolean If true, FSM is in this state.
  function FSM:Is( State )
    return self.current == State
  end

  --- Check if FSM is in state.
  -- @param #FSM self
  -- @param #string State State name.
  -- @return #boolean If true, FSM is in this state.  
  function FSM:is(state)
    return self.current == state
  end

  --- Check if can do an event.
  -- @param #FSM self
  -- @param #string e Event name.
  -- @return #boolean If true, FSM can do the event.
  -- @return #string To state.
  function FSM:can(e)
  
    local Event = self.Events[e]
   
    --self:F3( { self.current, Event } )
    
    local To = Event and Event.map[self.current] or Event.map['*']
    
    return To ~= nil, To
  end

  --- Check if cannot do an event.
  -- @param #FSM self
  -- @param #string e Event name.
  -- @return #boolean If true, FSM cannot do the event.
  function FSM:cannot(e)
    return not self:can(e)
  end

end

do -- FSM_CONTROLLABLE

  --- @type FSM_CONTROLLABLE
  -- @field Wrapper.Controllable#CONTROLLABLE Controllable
  -- @extends Core.Fsm#FSM
  
  --- Models Finite State Machines for @{Wrapper.Controllable}s, which are @{Wrapper.Group}s, @{Wrapper.Unit}s, @{Client}s.
  -- 
  -- ===
  -- 
  -- @field #FSM_CONTROLLABLE
  FSM_CONTROLLABLE = {
    ClassName = "FSM_CONTROLLABLE",
  }
  
  --- Creates a new FSM_CONTROLLABLE object.
  -- @param #FSM_CONTROLLABLE self
  -- @param #table FSMT Finite State Machine Table
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable (optional) The CONTROLLABLE object that the FSM_CONTROLLABLE governs.
  -- @return #FSM_CONTROLLABLE
  function FSM_CONTROLLABLE:New( Controllable )
  
    -- Inherits from BASE
    local self = BASE:Inherit( self, FSM:New() ) -- Core.Fsm#FSM_CONTROLLABLE
  
    if Controllable then
      self:SetControllable( Controllable )
    end
  
    self:AddTransition( "*", "Stop", "Stopped" )
  
    --- OnBefore Transition Handler for Event Stop.
    -- @function [parent=#FSM_CONTROLLABLE] OnBeforeStop
    -- @param #FSM_CONTROLLABLE self
    -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.
    -- @return #boolean Return false to cancel Transition.
    
    --- OnAfter Transition Handler for Event Stop.
    -- @function [parent=#FSM_CONTROLLABLE] OnAfterStop
    -- @param #FSM_CONTROLLABLE self
    -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.
    	
    --- Synchronous Event Trigger for Event Stop.
    -- @function [parent=#FSM_CONTROLLABLE] Stop
    -- @param #FSM_CONTROLLABLE self
    
    --- Asynchronous Event Trigger for Event Stop.
    -- @function [parent=#FSM_CONTROLLABLE] __Stop
    -- @param #FSM_CONTROLLABLE self
    -- @param #number Delay The delay in seconds.  
      
    --- OnLeave Transition Handler for State Stopped.
    -- @function [parent=#FSM_CONTROLLABLE] OnLeaveStopped
    -- @param #FSM_CONTROLLABLE self
    -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.
    -- @return #boolean Return false to cancel Transition.
    
    --- OnEnter Transition Handler for State Stopped.
    -- @function [parent=#FSM_CONTROLLABLE] OnEnterStopped
    -- @param #FSM_CONTROLLABLE self
    -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
    -- @param #string From The From State string.
    -- @param #string Event The Event string.
    -- @param #string To The To State string.

    return self
  end

  --- OnAfter Transition Handler for Event Stop.
  -- @function [parent=#FSM_CONTROLLABLE] OnAfterStop
  -- @param #FSM_CONTROLLABLE self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  function FSM_CONTROLLABLE:OnAfterStop(Controllable,From,Event,To)  
    
    -- Clear all pending schedules
    self.CallScheduler:Clear()
  end
  
  --- Sets the CONTROLLABLE object that the FSM_CONTROLLABLE governs.
  -- @param #FSM_CONTROLLABLE self
  -- @param Wrapper.Controllable#CONTROLLABLE FSMControllable
  -- @return #FSM_CONTROLLABLE
  function FSM_CONTROLLABLE:SetControllable( FSMControllable )
    --self:F( FSMControllable:GetName() )
    self.Controllable = FSMControllable
  end
  
  --- Gets the CONTROLLABLE object that the FSM_CONTROLLABLE governs.
  -- @param #FSM_CONTROLLABLE self
  -- @return Wrapper.Controllable#CONTROLLABLE
  function FSM_CONTROLLABLE:GetControllable()
    return self.Controllable
  end
  
  function FSM_CONTROLLABLE:_call_handler( step, trigger, params, EventName )
  
    local handler = step .. trigger
  
    local ErrorHandler = function( errmsg )
  
      env.info( "Error in SCHEDULER function:" .. errmsg )
      if BASE.Debug ~= nil then
        env.info( BASE.Debug.traceback() )
      end
      
      return errmsg
    end
  
    if self[handler] then
      self:T( "*** FSM ***    " .. step .. " *** " .. params[1] .. " --> " .. params[2] .. " --> " .. params[3] .. " *** TaskUnit: " .. self.Controllable:GetName() )
      self._EventSchedules[EventName] = nil
      local Result, Value = xpcall( function() return self[handler]( self, self.Controllable, unpack( params ) ) end, ErrorHandler )
      return Value
      --return self[handler]( self, self.Controllable, unpack( params ) )
    end
  end
  
end

do -- FSM_PROCESS

  --- @type FSM_PROCESS
  -- @field Tasking.Task#TASK Task
  -- @extends Core.Fsm#FSM_CONTROLLABLE
  
  
  --- FSM_PROCESS class models Finite State Machines for @{Task} actions, which control @{Client}s.
  -- 
  -- ===
  -- 
  -- @field #FSM_PROCESS FSM_PROCESS
  -- 
  FSM_PROCESS = {
    ClassName = "FSM_PROCESS",
  }
  
  --- Creates a new FSM_PROCESS object.
  -- @param #FSM_PROCESS self
  -- @return #FSM_PROCESS
  function FSM_PROCESS:New( Controllable, Task )
  
    local self = BASE:Inherit( self, FSM_CONTROLLABLE:New() ) -- Core.Fsm#FSM_PROCESS

    --self:F( Controllable )
    
    self:Assign( Controllable, Task )
    
    return self
  end
  
  function FSM_PROCESS:Init( FsmProcess )
    self:T( "No Initialisation" )
  end  

  function FSM_PROCESS:_call_handler( step, trigger, params, EventName )
  
    local handler = step .. trigger
  
    local ErrorHandler = function( errmsg )
  
      env.info( "Error in FSM_PROCESS call handler:" .. errmsg )
      if BASE.Debug ~= nil then
        env.info( BASE.Debug.traceback() )
      end
      
      return errmsg
    end
  
    if self[handler] then
      if handler ~= "onstatechange" then
        self:T( "*** FSM ***    " .. step .. " *** " .. params[1] .. " --> " .. params[2] .. " --> " .. params[3] .. " *** Task: " .. self.Task:GetName() .. ", TaskUnit: " .. self.Controllable:GetName() )
      end
      self._EventSchedules[EventName] = nil
      local Result, Value
      if self.Controllable and self.Controllable:IsAlive() == true then
        Result, Value = xpcall( function() return self[handler]( self, self.Controllable, self.Task, unpack( params ) ) end, ErrorHandler )
      end
      return Value
      --return self[handler]( self, self.Controllable, unpack( params ) )
    end
  end
  
  --- Creates a new FSM_PROCESS object based on this FSM_PROCESS.
  -- @param #FSM_PROCESS self
  -- @return #FSM_PROCESS
  function FSM_PROCESS:Copy( Controllable, Task )
    self:T( { self:GetClassNameAndID() } )

  
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
      --self:E( { Process:GetName() } )
      local FsmProcess = NewFsm:AddProcess( Process.From, Process.Event, Process.fsm:Copy( Controllable, Task ), Process.ReturnEvents )
    end
  
    -- Copy End States
    for EndStateID, EndState in pairs( self:GetEndStates() ) do
      self:T( EndState )
      NewFsm:AddEndState( EndState )
    end
    
    -- Copy the score tables
    for ScoreID, Score in pairs( self:GetScores() ) do
      self:T( Score )
      NewFsm:AddScore( ScoreID, Score.ScoreText, Score.Score )
    end
  
    return NewFsm
  end

  --- Removes an FSM_PROCESS object.
  -- @param #FSM_PROCESS self
  -- @return #FSM_PROCESS
  function FSM_PROCESS:Remove()
    self:F( { self:GetClassNameAndID() } )

    self:F( "Clearing Schedules" )
    self.CallScheduler:Clear()
    
    -- Copy Processes
    for ProcessID, Process in pairs( self:GetProcesses() ) do
      if Process.fsm then
        Process.fsm:Remove()
        Process.fsm = nil
      end
    end
    
    return self
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
  
-- TODO: Need to check and fix that an FSM_PROCESS is only for a UNIT. Not for a GROUP.  
  
  --- Send a message of the @{Task} to the Group of the Unit.
  -- @param #FSM_PROCESS self
  function FSM_PROCESS:Message( Message )
    self:F( { Message = Message } )
  
    local CC = self:GetCommandCenter()
    local TaskGroup = self.Controllable:GetGroup()
    
    local PlayerName = self.Controllable:GetPlayerName() -- Only for a unit
    PlayerName = PlayerName and " (" .. PlayerName .. ")" or "" -- If PlayerName is nil, then keep it nil, otherwise add brackets.
    local Callsign = self.Controllable:GetCallsign()
    local Prefix = Callsign and " @ " .. Callsign .. PlayerName or ""
    
    Message = Prefix .. ": " .. Message
    CC:MessageToGroup( Message, TaskGroup )
  end

  
  
  
  --- Assign the process to a @{Wrapper.Unit} and activate the process.
  -- @param #FSM_PROCESS self
  -- @param Task.Tasking#TASK Task
  -- @param Wrapper.Unit#UNIT ProcessUnit
  -- @return #FSM_PROCESS self
  function FSM_PROCESS:Assign( ProcessUnit, Task )
    --self:T( { Task:GetName(), ProcessUnit:GetName() } )
  
    self:SetControllable( ProcessUnit )
    self:SetTask( Task )
    
    --self.ProcessGroup = ProcessUnit:GetGroup()
  
    return self
  end
    
--  function FSM_PROCESS:onenterAssigned( ProcessUnit, Task, From, Event, To )
--  
--    if From( "Planned" ) then
--      self:T( "*** FSM ***    Assign *** " .. Task:GetName() .. "/" .. ProcessUnit:GetName() .. " *** " .. From .. " --> " .. Event .. " --> " .. To )
--      self.Task:Assign()
--    end
--  end
  
  function FSM_PROCESS:onenterFailed( ProcessUnit, Task, From, Event, To )
    self:T( "*** FSM ***    Failed *** " .. Task:GetName() .. "/" .. ProcessUnit:GetName() .. " *** " .. From .. " --> " .. Event .. " --> " .. To )
  
    self.Task:Fail()
  end

  
  --- StateMachine callback function for a FSM_PROCESS
  -- @param #FSM_PROCESS self
  -- @param Wrapper.Controllable#CONTROLLABLE ProcessUnit
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  function FSM_PROCESS:onstatechange( ProcessUnit, Task, From, Event, To )
  
    if From ~= To then
      self:T( "*** FSM ***    Change *** " .. Task:GetName() .. "/" .. ProcessUnit:GetName() .. " *** " .. From .. " --> " .. Event .. " --> " .. To )
    end
  
--    if self:IsTrace() then
--      MESSAGE:New( "@ Process " .. self:GetClassNameAndID() .. " : " .. Event .. " changed to state " .. To, 2 ):ToAll()
--      self:F2( { Scores = self._Scores, To = To } )
--    end
  
    -- TODO: This needs to be reworked with a callback functions allocated within Task, and set within the mission script from the Task Objects...
    if self._Scores[To] then
    
      local Task = self.Task  
      local Scoring = Task:GetScoring()
      if Scoring then
        Scoring:_AddMissionTaskScore( Task.Mission, ProcessUnit, self._Scores[To].ScoreText, self._Scores[To].Score )
      end
    end
  end

end

do -- FSM_TASK

  --- FSM_TASK class
  -- @type FSM_TASK
  -- @field Tasking.Task#TASK Task
  -- @extends #FSM
   
  --- Models Finite State Machines for @{Tasking.Task}s.
  -- 
  -- ===
  -- 
  -- @field #FSM_TASK FSM_TASK
  --   
  FSM_TASK = {
    ClassName = "FSM_TASK",
  }
  
  --- Creates a new FSM_TASK object.
  -- @param #FSM_TASK self
  -- @param #string TaskName The name of the task.
  -- @return #FSM_TASK
  function FSM_TASK:New( TaskName )
  
    local self = BASE:Inherit( self, FSM_CONTROLLABLE:New() ) -- Core.Fsm#FSM_TASK
  
    self["onstatechange"] = self.OnStateChange
    self.TaskName = TaskName
  
    return self
  end
  
  function FSM_TASK:_call_handler( step, trigger, params, EventName )
    local handler = step .. trigger
    
    local ErrorHandler = function( errmsg )
  
      env.info( "Error in SCHEDULER function:" .. errmsg )
      if BASE.Debug ~= nil then
        env.info( BASE.Debug.traceback() )
      end
      
      return errmsg
    end

    if self[handler] then
      self:T( "*** FSM ***    " .. step .. " *** " .. params[1] .. " --> " .. params[2] .. " --> " .. params[3] .. " *** Task: " .. self.TaskName )
      self._EventSchedules[EventName] = nil
      --return self[handler]( self, unpack( params ) )
      local Result, Value = xpcall( function() return self[handler]( self, unpack( params ) ) end, ErrorHandler )
      return Value
    end
  end

end -- FSM_TASK

do -- FSM_SET

  --- FSM_SET class
  -- @type FSM_SET
  -- @field Core.Set#SET_BASE Set
  -- @extends Core.Fsm#FSM


  --- FSM_SET class models Finite State Machines for @{Set}s. Note that these FSMs control multiple objects!!! So State concerns here
  -- for multiple objects or the position of the state machine in the process.
  -- 
  -- ===
  -- 
  -- @field #FSM_SET FSM_SET
  -- 
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
    self = BASE:Inherit( self, FSM:New() ) -- Core.Fsm#FSM_SET
  
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
  
  function FSM_SET:_call_handler( step, trigger, params, EventName  )
  local handler = step .. trigger
    if self[handler] then
      self:T( "*** FSM ***    " .. step .. " *** " .. params[1] .. " --> " .. params[2] .. " --> " .. params[3] )
      self._EventSchedules[EventName] = nil
      return self[handler]( self, self.Set, unpack( params ) )
    end
  end

end -- FSM_SET

