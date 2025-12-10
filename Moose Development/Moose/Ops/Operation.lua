--- **Ops** - Operation with multiple phases.
--
-- ## Main Features:
--
--    * Define operation phases
--    * Define conditions when phases are over
--    * Option to have branches in the phase tree
--    * Dedicate resources to operations
--
-- ===
--
-- ## Example Missions:
--
-- Demo missions can be found on [github](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/develop/Ops/Operation).
--
-- ===
--
-- ### Author: **funkyfranky**
--
-- ===
-- @module Ops.Operation
-- @image OPS_Operation.png


--- OPERATION class.
-- @type OPERATION
-- @field #string ClassName Name of the class.
-- @field #number verbose Verbosity level.
-- @field #number uid Unique ID of the operation.
-- @field #string lid Class id string for output to DCS log file.
-- @field #string name Name of the operation.
-- @field #number Tstart Start time in seconds of abs mission time.
-- @field #number Tstop Stop time in seconds of abs mission time.
-- @field #number duration Duration of the operation in seconds.
-- @field Core.Condition#CONDITION conditionStart Start condition.
-- @field Core.Condition#CONDITION conditionOver Over condition.
-- @field #table branches Branches.
-- @field #OPERATION.Branch branchMaster Master branch.
-- @field #OPERATION.Branch branchActive Active branch.
-- @field #number counterPhase Running number counting the phases.
-- @field #number counterBranch Running number counting the branches.
-- @field #OPERATION.Phase phase Currently active phase (if any).
-- @field #OPERATION.Phase phaseLast The phase that was active before the current one.
-- @field #table cohorts Dedicated cohorts.
-- @field #table legions Dedicated legions.
-- @field #table targets Targets.
-- @field #table missions Missions.
-- @extends Core.Fsm#FSM

--- *Before this time tomorrow I shall have gained a peerage, or Westminster Abbey.* -- Horatio Nelson
--
-- ===
--
-- # The OPERATION Concept
--
-- This class allows you to create complex operations, which consist of multiple phases. Conditions can be specified, when a phase is over. If a phase is over, the next phase is started.
-- FSM events can be used to customize code that is executed at each phase. Phases can also switched manually, of course.
-- 
-- In the simplest case, adding phases leads to a linear chain. However, you can also create branches to contruct a more tree like structure of phases. You can switch between branches 
-- manually or add "edges" with conditions when to switch branches. We are diving a bit into graph theory here. So don't feel embarrassed at all, if you stick to linear chains.
-- 
-- # Constructor
-- 
-- A new operation can be created with the @{#OPERATION.New}(*Name*) function, where the parameter `Name` is a free to choose string.
-- 
-- ## Adding Phases
-- 
-- You can add phases with the  @{#OPERATION.AddPhase}(*Name*, *Branch*) function. The first parameter `Name` is the name of the phase. The second parameter `Branch` is the branch to which the phase is
-- added. If this is omitted (nil), the phase is added to the default, *i.e.* "master branch". More about adding branches later.
-- 
-- 
--
--
-- @field #OPERATION
OPERATION = {
  ClassName          = "OPERATION",
  verbose            =     0,
  branches           =    {},
  counterPhase       =     0,
  counterBranch      =     0,
  counterEdge        =     0,
  cohorts            =    {},
  legions            =    {},  
  targets            =    {},
  missions           =    {},
}

--- Global mission counter.
_OPERATIONID=0

--- Operation phase.
-- @type OPERATION.Phase
-- @field #number uid Unique ID of the phase.
-- @field #string name Name of the phase.
-- @field Core.Condition#CONDITION conditionOver Conditions when the phase is over.
-- @field #string status Phase status.
-- @field #number Tstart Abs. mission time when the phase was started.
-- @field #number nActive Number of times the phase was active.
-- @field #number duration Duration in seconds how long the phase should be active after it started.
-- @field #OPERATION.Branch branch The branch this phase belongs to.

--- Operation branch.
-- @type OPERATION.Branch
-- @field #number uid Unique ID of the branch.
-- @field #string name Name of the branch.
-- @field #table phases Phases of this branch.
-- @field #table edges Edges of this branch.

--- Operation edge.
-- @type OPERATION.Edge
-- @field #number uid Unique ID of the edge.
-- @field #OPERATION.Branch branchFrom The from branch.
-- @field #OPERATION.Phase phaseFrom The from phase after which to switch.
-- @field #OPERATION.Branch branchTo The branch to switch to.
-- @field #OPERATION.Phase phaseTo The phase to switch to.
-- @field Core.Condition#CONDITION conditionSwitch Conditions when to switch the branch.

--- Operation phase.
-- @type OPERATION.PhaseStatus
-- @field #string PLANNED Planned.
-- @field #string ACTIVE Active phase.
-- @field #string OVER Phase is over.
OPERATION.PhaseStatus={
  PLANNED="Planned",
  ACTIVE="Active",
  OVER="Over",
}

--- OPERATION class version.
-- @field #string version
OPERATION.version="0.2.0"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: "Over" conditions.
-- TODO: Repeat phases: after over ==> planned (not over)
-- DONE: Branches.
-- DONE: Phases.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new generic OPERATION object.
-- @param #OPERATION self
-- @param #string Name Name of the operation. Be creative! Default "Operation-01" where the last number is a running number.
-- @return #OPERATION self
function OPERATION:New(Name)

  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, FSM:New()) -- #OPERATION

  -- Increase global counter.
  _OPERATIONID=_OPERATIONID+1
  
  -- Unique ID of the operation.
  self.uid=_OPERATIONID
  
  -- Set Name.
  self.name=Name or string.format("Operation-%02d", _OPERATIONID)
  
  -- Set log ID.
  self.lid=string.format("%s | ",self.name)
  
  -- FMS start state is PLANNED.
  self:SetStartState("Planned")
  
  -- Master branch.
  self.branchMaster=self:AddBranch("Master")
  
  self.conditionStart=CONDITION:New("Operation %s start", self.name)
  self.conditionStart:SetNoneResult(false) --If no condition function is specified, the ops will NOT be over.
  self.conditionStart:SetDefaultPersistence(false)
  
  self.conditionOver=CONDITION:New("Operation %s over", self.name)
  self.conditionOver:SetNoneResult(false)
  self.conditionOver:SetDefaultPersistence(false)
  
  
  -- Set master as active branch.
  self.branchActive=self.branchMaster

  -- Add FSM transitions.
  --                  From State     -->        Event            -->        To State
  self:AddTransition("*",                      "Start",                    "Running")
  
  self:AddTransition("*",                      "StatusUpdate",             "*")  
  
  self:AddTransition("Running",                "Pause",                    "Paused")
  self:AddTransition("Paused",                 "Unpause",                  "Running")
  
  self:AddTransition("*",                      "PhaseOver",                "*")
  self:AddTransition("*",                      "PhaseNext",                "*")
  self:AddTransition("*",                      "PhaseChange",              "*")
  
  self:AddTransition("*",                      "BranchSwitch",             "*")
  
  self:AddTransition("*",                      "Over",                     "Over")
  
  self:AddTransition("*",                      "Stop",                     "Stopped")
  

  ------------------------
  --- Pseudo Functions ---
  ------------------------

  --- Triggers the FSM event "Start".
  -- @function [parent=#OPERATION] Start
  -- @param #OPERATION self

  --- Triggers the FSM event "Start" after a delay.
  -- @function [parent=#OPERATION] __Start
  -- @param #OPERATION self
  -- @param #number delay Delay in seconds.

  --- On after "Start" event.
  -- @function [parent=#OPERATION] OnAfterStart
  -- @param #OPERATION self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.

  --- Triggers the FSM event "Stop".
  -- @function [parent=#OPERATION] Stop
  -- @param #OPERATION self

  --- Triggers the FSM event "Stop" after a delay.
  -- @function [parent=#OPERATION] __Stop
  -- @param #OPERATION self
  -- @param #number delay Delay in seconds.


  --- Triggers the FSM event "StatusUpdate".
  -- @function [parent=#OPERATION] StatusUpdate
  -- @param #OPERATION self

  --- Triggers the FSM event "Status" after a delay.
  -- @function [parent=#OPERATION] __StatusUpdate
  -- @param #OPERATION self
  -- @param #number delay Delay in seconds.


  --- Triggers the FSM event "PhaseChange".
  -- @function [parent=#OPERATION] PhaseChange
  -- @param #OPERATION self
  -- @param #OPERATION.Phase Phase The new phase.

  --- Triggers the FSM event "PhaseChange" after a delay.
  -- @function [parent=#OPERATION] __PhaseChange
  -- @param #OPERATION self
  -- @param #number delay Delay in seconds.
  -- @param #OPERATION.Phase Phase The new phase.

  --- On after "PhaseChange" event.
  -- @function [parent=#OPERATION] OnAfterPhaseChange
  -- @param #OPERATION self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #OPERATION.Phase Phase The new phase.


  --- Triggers the FSM event "PhaseNext".
  -- @function [parent=#OPERATION] PhaseNext
  -- @param #OPERATION self

  --- Triggers the FSM event "PhaseNext" after a delay.
  -- @function [parent=#OPERATION] __PhaseNext
  -- @param #OPERATION self
  -- @param #number delay Delay in seconds.

  --- On after "PhaseNext" event.
  -- @function [parent=#OPERATION] OnAfterPhaseNext
  -- @param #OPERATION self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.


  --- Triggers the FSM event "PhaseOver".
  -- @function [parent=#OPERATION] PhaseOver
  -- @param #OPERATION self
  -- @param #OPERATION.Phase Phase The phase that is over.

  --- Triggers the FSM event "PhaseOver" after a delay.
  -- @function [parent=#OPERATION] __PhaseOver
  -- @param #OPERATION self
  -- @param #number delay Delay in seconds.
  -- @param #OPERATION.Phase Phase The phase that is over.

  --- On after "PhaseOver" event.
  -- @function [parent=#OPERATION] OnAfterPhaseOver
  -- @param #OPERATION self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #OPERATION.Phase Phase The phase that is over.


  --- Triggers the FSM event "BranchSwitch".
  -- @function [parent=#OPERATION] BranchSwitch
  -- @param #OPERATION self
  -- @param #OPERATION.Branch Branch The branch that is now active.
  -- @param #OPERATION.Phase Phase The new phase.

  --- Triggers the FSM event "BranchSwitch" after a delay.
  -- @function [parent=#OPERATION] __BranchSwitch
  -- @param #OPERATION self
  -- @param #number delay Delay in seconds.
  -- @param #OPERATION.Branch Branch The branch that is now active.
  -- @param #OPERATION.Phase Phase The new phase.

  --- On after "BranchSwitch" event.
  -- @function [parent=#OPERATION] OnAfterBranchSwitch
  -- @param #OPERATION self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #OPERATION.Branch Branch The branch that is now active.
  -- @param #OPERATION.Phase Phase The new phase.

  --- Triggers the FSM event "Over".
  -- @function [parent=#OPERATION] Over
  -- @param #OPERATION self

  --- Triggers the FSM event "Over" after a delay.
  -- @function [parent=#OPERATION] __Over
  -- @param #OPERATION self
  -- @param #number delay Delay in seconds.

  --- On after "Over" event.
  -- @function [parent=#OPERATION] OnAfterOver
  -- @param #OPERATION self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.

  -- Init status update.
  self:__StatusUpdate(-1)

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User API Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set verbosity level.
-- @param #OPERATION self
-- @param #number VerbosityLevel Level of output (higher=more). Default 0.
-- @return #OPERATION self
function OPERATION:SetVerbosity(VerbosityLevel)
  self.verbose=VerbosityLevel or 0
  return self
end

--- Set start and stop time of the operation.
-- @param #OPERATION self
-- @param #string ClockStart Time the mission is started, e.g. "05:00" for 5 am. If specified as a #number, it will be relative (in seconds) to the current mission time. Default is 5 seconds after mission was added.
-- @param #string ClockStop (Optional) Time the mission is stopped, e.g. "13:00" for 1 pm. If mission could not be started at that time, it will be removed from the queue. If specified as a #number it will be relative (in seconds) to the current mission time.
-- @return #OPERATION self
function OPERATION:SetTime(ClockStart, ClockStop)

  -- Current mission time.
  local Tnow=timer.getAbsTime()

  -- Set start time. Default in 5 sec.
  local Tstart=Tnow+5
  if ClockStart and type(ClockStart)=="number" then
    Tstart=Tnow+ClockStart
  elseif ClockStart and type(ClockStart)=="string" then
    Tstart=UTILS.ClockToSeconds(ClockStart)
  end

  -- Set stop time. Default nil.
  local Tstop=nil
  if ClockStop and type(ClockStop)=="number" then
    Tstop=Tnow+ClockStop
  elseif ClockStop and type(ClockStop)=="string" then
    Tstop=UTILS.ClockToSeconds(ClockStop)
  end

  self.Tstart=Tstart
  self.Tstop=Tstop

  if Tstop then
    self.duration=self.Tstop-self.Tstart
  end

  return self
end

--- Add (all) condition function when the whole operation is over. Must return a `#boolean`.
-- @param #OPERATION self
-- @param #function Function Function that needs to be `true` before the operation is over. 
-- @param ... Condition function arguments if any.
-- @return Core.Condition#CONDITION.Function Condition function table.
function OPERATION:AddConditonOverAll(Function, ...)
  local cf=self.conditionOver:AddFunctionAll(Function, ...)
  return cf  
end

--- Add (any) condition function when the whole operation is over. Must return a `#boolean`.
-- @param #OPERATION self
-- @param #function Function Function that needs to be `true` before the operation is over. 
-- @param ... Condition function arguments if any.
-- @return Core.Condition#CONDITION.Function Condition function table.
function OPERATION:AddConditonOverAny(Phase, Function, ...)
  local cf=self.conditionOver:AddFunctionAny(Function, ...)
  return cf  
end


--- Add a new phase to the operation. This is added add the end of all previously added phases (if any).
-- @param #OPERATION self
-- @param #string Name Name of the phase. Default "Phase-01" where the last number is a running number.
-- @param #OPERATION.Branch Branch The branch to which this phase is added. Default is the master branch.
-- @param #number Duration Duration in seconds how long the phase will last. Default `nil`=forever.
-- @return #OPERATION.Phase Phase table object.
function OPERATION:AddPhase(Name, Branch, Duration)

  -- Branch.
  Branch=Branch or self.branchMaster

  -- Create a new phase.
  local phase=self:_CreatePhase(Name)
  
  -- Branch of phase
  phase.branch=Branch
  
  -- Set duraction of pahse (if any).
  phase.duration=Duration
  
  -- Debug output.
  self:T(self.lid..string.format("Adding phase %s to branch %s", phase.name, Branch.name))
  
  -- Add phase.
  table.insert(Branch.phases, phase)
  
  return phase
end

---Insert a new phase after an already defined phase of the operation.
-- @param #OPERATION self
-- @param #OPERATION.Phase PhaseAfter The phase after which the new phase is inserted.
-- @param #string Name Name of the phase. Default "Phase-01" where the last number is a running number.
-- @return #OPERATION.Phase Phase table object.
function OPERATION:InsertPhaseAfter(PhaseAfter, Name)

  for i=1,#self.phases do
    local phase=self.phases[i] --#OPERATION.Phase
    if PhaseAfter.uid==phase.uid then
    
      -- Create a new phase.
      local phase=self:_CreatePhase(Name)
    
      
    end
  end
  
  return nil
end

--- Get a name of this operation.
-- @param #OPERATION self
-- @return #string Name of this operation or "Unknown".
function OPERATION:GetName()
  return self.name or "Unknown"
end

--- Get a phase by its name.
-- @param #OPERATION self
-- @param #string Name Name of the phase. Default "Phase-01" where the last number is a running number.
-- @return #OPERATION.Phase Phase table object or nil if phase could not be found.
function OPERATION:GetPhaseByName(Name)

  for _,_branch in pairs(self.branches) do
    local branch=_branch --#OPERATION.Branch
    for _,_phase in pairs(branch.phases or {}) do
      local phase=_phase --#OPERATION.Phase
      if phase.name==Name then
        return phase
      end
    end
  end

  return nil
end

--- Set status of a phase.
-- @param #OPERATION self
-- @param #OPERATION.Phase Phase The phase.
-- @param #string Status New status, *e.g.* `OPERATION.PhaseStatus.OVER`.
-- @return #OPERATION self
function OPERATION:SetPhaseStatus(Phase, Status)

  if Phase then
  
    -- Debug message.
    self:T(self.lid..string.format("Phase %s status: %s-->%s", tostring(Phase.name), tostring(Phase.status), tostring(Status)))
    
    -- Set status.
    Phase.status=Status
    
    -- Set time stamp when phase becase active.
    if Phase.status==OPERATION.PhaseStatus.ACTIVE then
      Phase.Tstart=timer.getAbsTime()
      Phase.nActive=Phase.nActive+1
    elseif Phase.status==OPERATION.PhaseStatus.OVER then
      -- Trigger PhaseOver event.
      self:PhaseOver(Phase)
    end
    
  end
  
  return self
end

--- Get status of a phase.
-- @param #OPERATION self
-- @param #OPERATION.Phase Phase The phase.
-- @return #string Phase status, *e.g.* `OPERATION.PhaseStatus.OVER`.
function OPERATION:GetPhaseStatus(Phase)
  return Phase.status
end

--- Set condition when the given phase is over.
-- @param #OPERATION self
-- @param #OPERATION.Phase Phase The phase.
-- @param Core.Condition#CONDITION Condition Condition when the phase is over.
-- @return #OPERATION self
function OPERATION:SetPhaseConditonOver(Phase, Condition)
  if Phase then
    self:T(self.lid..string.format("Setting phase %s conditon over %s", self:GetPhaseName(Phase), Condition and Condition.name or "None"))
    Phase.conditionOver=Condition
  end
  return self
end

--- Add condition function when the given phase is over. Must return a `#boolean`.
-- @param #OPERATION self
-- @param #OPERATION.Phase Phase The phase.
-- @param #function Function Function that needs to be `true` before the phase is over. 
-- @param ... Condition function arguments if any.
-- @return Core.Condition#CONDITION.Function Condition function table.
function OPERATION:AddPhaseConditonOverAll(Phase, Function, ...)
  if Phase then
    local cf=Phase.conditionOver:AddFunctionAll(Function, ...)
    return cf  
  end
  return nil
end

--- Add condition function when the given phase is over. Must return a `#boolean`.
-- @param #OPERATION self
-- @param #OPERATION.Phase Phase The phase.
-- @param #function Function Function that needs to be `true` before the phase is over. 
-- @param ... Condition function arguments if any.
-- @return Core.Condition#CONDITION.Function Condition function table.
function OPERATION:AddPhaseConditonOverAny(Phase, Function, ...)
  if Phase then
    local cf=Phase.conditionOver:AddFunctionAny(Function, ...)
    return cf  
  end
  return nil
end

--- Set persistence of condition function. By default, condition functions are removed after a phase is over.
-- @param #OPERATION self
-- @param Core.Condition#CONDITION.Function ConditionFunction Condition function table.
-- @param #boolean IsPersistent If `true` or `nil`, condition function is persistent.
-- @return #OPERATION self
function OPERATION:SetConditionFunctionPersistence(ConditionFunction, IsPersistent)
  ConditionFunction.persistence=IsPersistent
  return self
end

--- Add condition function when the given phase is to be repeated. The provided function must return a `#boolean`.
-- If the condition evaluation returns `true`, the phase is set to state `Planned` instead of `Over` and can be repeated.
-- @param #OPERATION self
-- @param #OPERATION.Phase Phase The phase.
-- @param #function Function Function that needs to be `true` before the phase is over. 
-- @param ... Condition function arguments if any.
-- @return #OPERATION self
function OPERATION:AddPhaseConditonRepeatAll(Phase, Function, ...)
  if Phase then
    Phase.conditionRepeat:AddFunctionAll(Function, ...)  
  end
  return self
end


--- Get condition when the given phase is over.
-- @param #OPERATION self
-- @param #OPERATION.Phase Phase The phase.
-- @return Core.Condition#CONDITION Condition when the phase is over (if any).
function OPERATION:GetPhaseConditonOver(Phase, Condition)
  return Phase.conditionOver
end

--- Get how many times a phase has been active.
-- @param #OPERATION self
-- @param #OPERATION.Phase Phase The phase.
-- @return #number Number of times the phase has been active.
function OPERATION:GetPhaseNactive(Phase)
  return Phase.nActive
end

--- Get name of a phase.
-- @param #OPERATION self
-- @param #OPERATION.Phase Phase The phase of which the name is returned. Default is the currently active phase.
-- @return #string The name of the phase or "None" if no phase is given or active.
function OPERATION:GetPhaseName(Phase)

  Phase=Phase or self.phase
  
  if Phase then
    return Phase.name
  end
  
  return "None"
end

--- Get currrently active phase.
-- @param #OPERATION self
-- @return #OPERATION.Phase Current phase or `nil` if no current phase is active.
function OPERATION:GetPhaseActive()
  return self.phase
end

--- Get index of phase.
-- @param #OPERATION self
-- @param #OPERATION.Phase Phase The phase.
-- @return #number The index.
-- @return #OPERATION.Branch The branch.
function OPERATION:GetPhaseIndex(Phase)

  local branch=Phase.branch
  
  for i,_phase in pairs(branch.phases) do
    local phase=_phase --#OPERATION.Phase
    if phase.uid==Phase.uid then
      return i, branch
    end
  end
  
  return nil
end

--- Get next phase.
-- @param #OPERATION self
-- @param #OPERATION.Branch Branch (Optional) The branch from which the next phase is retrieved. Default is the currently active branch.
-- @param #string PhaseStatus (Optional) Only return a phase, which is in this status. For example, `OPERATION.PhaseStatus.PLANNED` to make sure, the next phase is planned.
-- @return #OPERATION.Phase Next phase or `nil` if no next phase exists.
function OPERATION:GetPhaseNext(Branch, PhaseStatus)

  -- Branch.
  Branch=Branch or self:GetBranchActive()

  -- The phases of the branch.
  local phases=Branch.phases or {}
  
  local phase=nil
  if self.phase and self.phase.branch.uid==Branch.uid then
    phase=self.phase
  end
  
  -- Number of phases.
  local N=#phases
  
  -- Debug message.
  self:T(self.lid..string.format("Getting next phase! Branch=%s, Phases=%d, Status=%s", Branch.name, N, tostring(PhaseStatus)))
  
  if N>0 then
  
    -- Check if there there is an active phase already.
    if phase==nil and PhaseStatus==nil then
      return phases[1]
    end
    
    local n=1
    
    if phase then
      n=self:GetPhaseIndex(phase)+1
    end
  
    for i=n,N do
      local phase=phases[i] --#OPERATION.Phase
      
      if PhaseStatus==nil or PhaseStatus==phase.status then
        return phase
      end
      
    end
    
  end
  
  return nil
end

--- Count phases.
-- @param #OPERATION self
-- @param #string Status (Optional) Only count phases in a certain status, e.g. `OPERATION.PhaseStatus.PLANNED`.
-- @param #OPERATION.Branch Branch (Optional) Branch.
-- @return #number Number of phases
function OPERATION:CountPhases(Status, Branch)

  Branch=Branch or self.branchActive

  local N=0
  for _,_phase in pairs(Branch.phases) do
    local phase=_phase --#OPERATION.Phase
    if Status==nil or Status==phase.status then
      N=N+1
    end
  end

  return N
end


--- Add a new branch to the operation.
-- @param #OPERATION self
-- @param #string Name
-- @return #OPERATION.Branch Branch table object.
function OPERATION:AddBranch(Name)

  -- Create a new branch.
  local branch=self:_CreateBranch(Name)
  
  -- Add phase.
  table.insert(self.branches, branch)
  
  return branch
end

--- Get the master branch. This is the default branch and should always exist (if it was not explicitly deleted).
-- @param #OPERATION self
-- @return #OPERATION.Branch The master branch.
function OPERATION:GetBranchMaster()
  return self.branchMaster
end

--- Get the currently active branch.
-- @param #OPERATION self
-- @return #OPERATION.Branch The active branch. If no branch is active, the master branch is returned.
function OPERATION:GetBranchActive()
  return self.branchActive or self.branchMaster
end

--- Get name of the branch.
-- @param #OPERATION self
-- @param #OPERATION.Branch Branch The branch of which the name is requested. Default is the currently active or master branch.
-- @return #string Name Name or "None"
function OPERATION:GetBranchName(Branch)
  Branch=Branch or self:GetBranchActive()
  if Branch then
    return Branch.name
  end
  return "None"
end

--- Add an edge between two branches.
-- @param #OPERATION self
-- @param #OPERATION.Phase PhaseFrom The phase of the *from* branch *after* which to switch.
-- @param #OPERATION.Phase PhaseTo The phase of the *to* branch *to* which to switch.
-- @param Core.Condition#CONDITION ConditionSwitch (Optional) Condition(s) when to switch the branches.
-- @return #OPERATION.Edge Edge table object.
function OPERATION:AddEdge(PhaseFrom, PhaseTo, ConditionSwitch)

  local edge={} --#OPERATION.Edge
  
  edge.phaseFrom=PhaseFrom
  edge.phaseTo=PhaseTo

  edge.branchFrom=PhaseFrom.branch
  edge.branchTo=PhaseTo.branch  
  
  if ConditionSwitch then
    edge.conditionSwitch=ConditionSwitch
  else
    edge.conditionSwitch=CONDITION:New("Edge")
    edge.conditionSwitch:SetNoneResult(true)
  end
  
  table.insert(edge.branchFrom.edges, edge)

  return edge
end

--- Add condition function to an edge when branches are switched. The function must return a `#boolean`.
-- If multiple condition functions are added, all of these must return true for the branch switch to occur.
-- @param #OPERATION self
-- @param #OPERATION.Edge Edge The edge connecting the two branches.
-- @param #function Function Function that needs to be `true` for switching between the branches. 
-- @param ... Condition function arguments if any.
-- @return Core.Condition#CONDITION.Function Condition function table.
function OPERATION:AddEdgeConditonSwitchAll(Edge, Function, ...)
  if Edge then
    local cf=Edge.conditionSwitch:AddFunctionAll(Function, ...)
    return cf
  end
  return nil
end

--- Add mission to operation.
-- @param #OPERATION self
-- @param Ops.Auftrag#AUFTRAG Mission The mission to add.
-- @param #OPERATION.Phase Phase (Optional) The phase in which the mission should be executed. If no phase is given, it will be exectuted ASAP.
function OPERATION:AddMission(Mission, Phase)

  Mission.phase=Phase
  Mission.operation=self
  
  table.insert(self.missions, Mission)

  return self
end

--- Add Target to operation.
-- @param #OPERATION self
-- @param Ops.Target#TARGET Target The target to add.
-- @param #OPERATION.Phase Phase (Optional) The phase in which the target should be attacked. If no phase is given, it will be attacked ASAP.
function OPERATION:AddTarget(Target, Phase)

  Target.phase=Phase
  Target.operation=self
  
  table.insert(self.targets, Target)

  return self
end

--- Get targets of operation.
-- @param #OPERATION self
-- @param #OPERATION.Phase Phase (Optional) Only return targets set for this phase. Default is targets of all phases.
-- @return #table Targets Table of #TARGET objects 
function OPERATION:GetTargets(Phase)
  local N = {}
  for _,_target in pairs(self.targets) do
    local target=_target --Ops.Target#TARGET
    if target:IsAlive() and (Phase==nil or target.phase==Phase) then
      table.insert(N,target)
    end
  end
  return N
end

--- Count targets alive.
-- @param #OPERATION self
-- @param #OPERATION.Phase Phase (Optional) Only count targets set for this phase.
-- @return #number Number of phases
function OPERATION:CountTargets(Phase)

  local N=0
  for _,_target in pairs(self.targets) do
    local target=_target --Ops.Target#TARGET
    
    if target:IsAlive() and (Phase==nil or target.phase==Phase) then
      N=N+1
    end
  end

  return N
end

--- Assign cohort to operation.
-- @param #OPERATION self
-- @param Ops.Cohort#COHORT Cohort The cohort
-- @return #OPERATION self
function OPERATION:AssignCohort(Cohort)

  self:T(self.lid..string.format("Assiging Cohort %s to operation", Cohort.name))
  self.cohorts[Cohort.name]=Cohort

end

--- Assign legion to operation. All cohorts of this legion will be assigned and are only available.
-- @param #OPERATION self
-- @param Ops.Legion#LEGION Legion The legion to be assigned.
-- @return #OPERATION self
function OPERATION:AssignLegion(Legion)

  self.legions[Legion.alias]=Legion

end

--- Check if a given legion is assigned to this operation. All cohorts of this legion will be checked.
-- @param #OPERATION self
-- @param Ops.Legion#LEGION Legion The legion to be assigned.
-- @return #boolean If `true`, legion is assigned to this operation.
function OPERATION:IsAssignedLegion(Legion)

  local legion=self.legions[Legion.alias]

  if legion then
    self:T(self.lid..string.format("Legion %s is assigned to this operation", Legion.alias))
    return true
  else
    self:T(self.lid..string.format("Legion %s is NOT assigned to this operation", Legion.alias))
    return false
  end
  
end

--- Check if a given cohort is assigned to this operation.
-- @param #OPERATION self
-- @param Ops.Cohort#COHORT Cohort The Cohort.
-- @return #boolean If `true`, cohort is assigned to this operation.
function OPERATION:IsAssignedCohort(Cohort)

  local cohort=self.cohorts[Cohort.name]

  if cohort then
    self:T(self.lid..string.format("Cohort %s is assigned to this operation", Cohort.name))
    return true
  else
  
    -- Check if legion of this cohort was assigned.
    local Legion=Cohort.legion
    if Legion and self:IsAssignedLegion(Legion) then
      self:T(self.lid..string.format("Legion %s of Cohort %s is assigned to this operation", Legion.alias, Cohort.name))
      return true
    end
  
    self:T(self.lid..string.format("Cohort %s is NOT assigned to this operation", Cohort.name))
    return false
  end
  
  return nil
end

--- Check if a given cohort or legion is assigned to this operation.
-- @param #OPERATION self
-- @param Wrapper.Object#OBJECT Object The cohort or legion object.
-- @return #boolean If `true`, cohort is assigned to this operation.
function OPERATION:IsAssignedCohortOrLegion(Object)

  local isAssigned=nil
  if Object:IsInstanceOf("COHORT") then
    isAssigned=self:IsAssignedCohort(Object)    
  elseif Object:IsInstanceOf("LEGION") then
    isAssigned=self:IsAssignedLegion(Object)
  else
    self:E(self.lid.."ERROR: Unknown Object!")
  end

  return isAssigned
end

--- Check if operation is in FSM state "Planned".
-- @param #OPERATION self
-- @return #boolean If `true`, operation is "Planned".
function OPERATION:IsPlanned()
  local is=self:is("Planned")
  return is
end

--- Check if operation is in FSM state "Running".
-- @param #OPERATION self
-- @return #boolean If `true`, operation is "Running".
function OPERATION:IsRunning()
  local is=self:is("Running")
  return is
end

--- Check if operation is in FSM state "Paused".
-- @param #OPERATION self
-- @return #boolean If `true`, operation is "Paused".
function OPERATION:IsPaused()
  local is=self:is("Paused")
  return is
end

--- Check if operation is in FSM state "Over".
-- @param #OPERATION self
-- @return #boolean If `true`, operation is "Over".
function OPERATION:IsOver()
  local is=self:is("Over")
  return is
end

--- Check if operation is in FSM state "Stopped".
-- @param #OPERATION self
-- @return #boolean If `true`, operation is "Stopped".
function OPERATION:IsStopped()
  local is=self:is("Stopped")
  return is
end

--- Check if operation is **not** "Over" or "Stopped".
-- @param #OPERATION self
-- @return #boolean If `true`, operation is not "Over" or "Stopped".
function OPERATION:IsNotOver()
  local is=not (self:IsOver() or self:IsStopped())
  return is
end

--- Check if phase is in status "Active".
-- @param #OPERATION self
-- @param #OPERATION.Phase Phase The phase.
-- @return #boolean If `true`, phase is active.
function OPERATION:IsPhaseActive(Phase)
  if Phase and Phase.status and Phase.status==OPERATION.PhaseStatus.ACTIVE then
    return true
  end
  return false
end

--- Check if a phase is the currently active one.
-- @param #OPERATION self
-- @param #OPERATION.Phase Phase The phase to check.
-- @return #boolean If `true`, this phase is currently active.
function OPERATION:IsPhaseActive(Phase)
  local phase=self:GetPhaseActive()
  if phase and phase.uid==Phase.uid then
    return true
  else
    return false
  end
  return nil
end

--- Check if phase is in status "Planned".
-- @param #OPERATION self
-- @param #OPERATION.Phase Phase The phase.
-- @return #boolean If `true`, phase is Planned.
function OPERATION:IsPhasePlanned(Phase)
  if Phase and Phase.status and Phase.status==OPERATION.PhaseStatus.PLANNED then
    return true
  end
  return false
end

--- Check if phase is in status "Over".
-- @param #OPERATION self
-- @param #OPERATION.Phase Phase The phase.
-- @return #boolean If `true`, phase is over.
function OPERATION:IsPhaseOver(Phase)
  if Phase and Phase.status and Phase.status==OPERATION.PhaseStatus.OVER then
    return true
  end
  return false
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Status Update
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after "Start" event.
-- @param #OPERATION self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPERATION:onafterStart(From, Event, To)

  -- Debug message.
  self:T(self.lid..string.format("Starting Operation!"))
  return self 
end


--- On after "StatusUpdate" event.
-- @param #OPERATION self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPERATION:onafterStatusUpdate(From, Event, To)

  -- Current abs. mission time.
  local Tnow=timer.getAbsTime()

  -- Current FSM state.
  local fsmstate=self:GetState()
  
  -- Start operation.
  if self:IsPlanned() then
  
    -- Start operation if start time has passed (if any) and start condition(s) are met (if any).
    if (self.Tstart and Tnow>self.Tstart or self.Tstart==nil) and (self.conditionStart==nil or self.conditionStart:Evaluate()) then
      self:Start()
    end
    
  elseif self:IsNotOver() then

    -- Operation is over if stop time has passed (if any) and over condition(s) are met (if any).
    if (self.Tstop and Tnow>self.Tstop or self.Tstop==nil) and (self.conditionOver==nil or self.conditionOver:Evaluate()) then
      self:Over()
    end
    
  end
  
  
  -- Check phases.
  if self:IsRunning() then
    self:_CheckPhases()
  end
  
  
  -- Debug output.
  if self.verbose>=1 then
  
    -- Current phase.
    local phaseName=self:GetPhaseName()
    local branchName=self:GetBranchName()
    local NphaseTot=self:CountPhases()
    local NphaseAct=self:CountPhases(OPERATION.PhaseStatus.ACTIVE)
    local NphasePla=self:CountPhases(OPERATION.PhaseStatus.PLANNED)
    local NphaseOvr=self:CountPhases(OPERATION.PhaseStatus.OVER)
    
    -- General info.
    local text=string.format("State=%s: Phase=%s [%s], Phases=%d [Active=%d, Planned=%d, Over=%d]", fsmstate, phaseName, branchName, NphaseTot, NphaseAct, NphasePla, NphaseOvr)
    self:I(self.lid..text)
    
  end
  
  -- Debug output.
  if self.verbose>=2 then
  
    -- Info on phases.
    local text="Phases:"
    for i,_phase in pairs(self.branchActive.phases) do
      local phase=_phase --#OPERATION.Phase
      text=text..string.format("\n[%d] %s [uid=%d]: status=%s Nact=%d", i, phase.name, phase.uid, tostring(phase.status), phase.nActive)
    end
    if text=="Phases:" then text=text.." None" end
    self:I(self.lid..text)
    
  end

  -- Next status update.
  self:__StatusUpdate(-30)
  
  return self 
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after "PhaseNext" event.
-- @param #OPERATION self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPERATION:onafterPhaseNext(From, Event, To)

  -- Get next phase.
  local Phase=self:GetPhaseNext()
  
  if Phase then
  
    -- Change phase to next one.
    self:PhaseChange(Phase)
          
  else
  
    -- No further phases defined ==> Operation is over.
    self:Over()
    
  end

  return self
end


--- On after "PhaseChange" event.
-- @param #OPERATION self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #OPERATION.Phase Phase The new phase.
function OPERATION:onafterPhaseChange(From, Event, To, Phase)

  -- Previous phase (if any).
  local oldphase="None"
  if self.phase then
    if self.phase.status~=OPERATION.PhaseStatus.OVER then
      self:SetPhaseStatus(self.phase, OPERATION.PhaseStatus.OVER)
    end
    oldphase=self.phase.name
  end

  -- Debug message.
  self:I(self.lid..string.format("Phase change: %s --> %s", oldphase, Phase.name))
  
  -- Set currently active phase.
  self.phase=Phase
  
  -- Phase is active.
  self:SetPhaseStatus(Phase, OPERATION.PhaseStatus.ACTIVE)
  
  return self
end

--- On after "PhaseOver" event.
-- @param #OPERATION self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #OPERATION.Phase Phase The phase that is over.
function OPERATION:onafterPhaseOver(From, Event, To, Phase)
  
  -- Remove all non-persistant condition functions.
  Phase.conditionOver:RemoveNonPersistant()

end

--- On after "BranchSwitch" event.
-- @param #OPERATION self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #OPERATION.Branch Branch The new branch.
-- @param #OPERATION.Phase Phase The phase.
function OPERATION:onafterBranchSwitch(From, Event, To, Branch, Phase)

  -- Debug info.
  self:T(self.lid..string.format("Switching to branch %s", Branch.name))

  -- Set active branch.
  self.branchActive=Branch
  
  -- Change phase.
  self:PhaseChange(Phase)  
  
  return self
end

--- On after "Over" event.
-- @param #OPERATION self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPERATION:onafterOver(From, Event, To)

  -- Debug message.
  self:T(self.lid..string.format("Operation is over!"))
  
  -- No active phase.
  self.phase=nil
  
  -- Set all phases to OVER.
  for _,_branch in pairs(self.branches) do
    local branch=_branch --#OPERATION.Branch
    for _,_phase in pairs(branch.phases) do
      local phase=_phase --#OPERATION.Phase
      if not self:IsPhaseOver(phase) then
        self:SetPhaseStatus(phase, OPERATION.PhaseStatus.OVER)
      end
    end
  end 
  
  return self 
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc (private) Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Check phases.
-- @param #OPERATION self
function OPERATION:_CheckPhases()

  -- Currently active phase.
  local phase=self:GetPhaseActive()
  
  -- Check if active phase is over if conditon over is defined.
  if phase and phase.conditionOver then
  
    -- Evaluate if phase is over.
    local isOver=phase.conditionOver:Evaluate()
    
    local Tnow=timer.getAbsTime()
    
    -- Check if duration of phase if over.
    if phase.duration and phase.Tstart and Tnow-phase.Tstart>phase.duration then
      isOver=true
    end
    
    -- Set phase status to over. This also triggers the PhaseOver() event.
    if isOver then
      self:SetPhaseStatus(phase, OPERATION.PhaseStatus.OVER)
    end
  end
  
  -- If no current phase or current phase is over, get next phase.
  if phase==nil or phase.status==OPERATION.PhaseStatus.OVER then
  
    for _,_edge in pairs(self.branchActive.edges) do
      local edge=_edge --#OPERATION.Edge
      
      if phase then
        --env.info(string.format("phase active uid=%d", phase.uid))
        --env.info(string.format("Phase from   uid=%d", edge.phaseFrom.uid))
      end
      
      if (edge.phaseFrom==nil) or (phase and edge.phaseFrom.uid==phase.uid) then

        -- Evaluate switch condition.      
        local switch=edge.conditionSwitch:Evaluate()
        
        if switch then
        
          -- Get next phase of the branch
          local phaseTo=edge.phaseTo or self:GetPhaseNext(edge.branchTo, nil)
          
          if phaseTo then
          
            -- Switch to new branch.
            self:BranchSwitch(edge.branchTo, phaseTo)
            
          else
          
            -- No next phase ==> Ops is over!
            self:Over()
            
          end
          
          -- Done here!
          return
        end
      end
      
    end
        
    -- Next phase.
    self:PhaseNext()
        
  end

end

--- Create a new phase object.
-- @param #OPERATION self
-- @param #string Name Name of the phase. Default "Phase-01" where the last number is a running number.
-- @return #OPERATION.Phase Phase table object.
function OPERATION:_CreatePhase(Name)

  -- Increase phase counter.
  self.counterPhase=self.counterPhase+1

  local phase={} --#OPERATION.Phase
  phase.uid=self.counterPhase
  phase.name=Name or string.format("Phase-%02d", self.counterPhase)  
  phase.conditionOver=CONDITION:New(Name.." Over")
  phase.conditionOver:SetDefaultPersistence(false)
  phase.status=OPERATION.PhaseStatus.PLANNED
  phase.nActive=0

  return phase
end

--- Create a new branch object.
-- @param #OPERATION self
-- @param #string Name Name of the phase. Default "Phase-01" where the last number is a running number.
-- @return #OPERATION.Branch Branch table object.
function OPERATION:_CreateBranch(Name)

  -- Increase phase counter.
  self.counterBranch=self.counterBranch+1

  local branch={} --#OPERATION.Branch
  branch.uid=self.counterBranch
  branch.name=Name or string.format("Branch-%02d", self.counterBranch)
  branch.phases={}
  branch.edges={}

  return branch
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
