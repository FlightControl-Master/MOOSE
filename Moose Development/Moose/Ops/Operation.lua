--- **Ops** - Operation with multiple phases.
--
-- ## Main Features:
--
--    * Define operation phases
--    * Define conditions when phases are over
--    * Dedicate resources to operations
--
-- ===
--
-- ## Example Missions:
--
-- Demo missions can be found on [github](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/develop/OPS%20-%20Operation).
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
-- @field #string lid Class id string for output to DCS log file.
-- @field #string name Name of the operation.
-- @field #table cohorts Dedicated cohorts.
-- @field #table legions Dedicated legions.
-- @field #table phases Phases.
-- @field #number counterPhase Running number counting the phases.
-- @field #OPERATION.Phase phase Currently active phase (if any).
-- @field #table targets Targets.
--
-- @extends Core.Fsm#FSM

--- *A warrior's mission is to foster the success of others.* -- Morihei Ueshiba
--
-- ===
--
-- # The OPERATION Concept
--
--
--
-- @field #OPERATION
OPERATION = {
  ClassName          = "OPERATION",
  verbose            =     0,
  lid                =   nil,
  cohorts            =    {},
  legions            =    {},
  phases             =    {},
  counterPhase       =     0,
  targets            =    {},
}

--- Global mission counter.
_OPERATIONID=0

--- Operation phase.
-- @type OPERATION.Phase
-- @field #number uid Unique ID of the phase.
-- @field #string name Name of the phase.
-- @field Core.Condition#CONDITION conditionOver Conditions when the phase is over.
-- @field #string status Phase status.

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
OPERATION.version="0.0.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: A lot

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

  -- Add FSM transitions.
  --                  From State     -->        Event            -->        To State
  self:AddTransition("*",                      "Start",                    "Running")
  
  self:AddTransition("*",                      "StatusUpdate",             "*")  
  
  self:AddTransition("Running",                "Pause",                    "Paused")
  self:AddTransition("Paused",                 "Unpause",                  "Running")
  
  self:AddTransition("*",                      "PhaseOver",                "*")
  self:AddTransition("*",                      "PhaseChange",              "*")
  
  self:AddTransition("*",                      "Over",                     "Over")
  
  self:AddTransition("*",                      "Stop",                     "Stopped")
  

  ------------------------
  --- Pseudo Functions ---
  ------------------------

  --- Triggers the FSM event "StatusUpdate".
  -- @function [parent=#OPERATION] StatusUpdate
  -- @param #OPERATION self

  --- Triggers the FSM event "Status" after a delay.
  -- @function [parent=#OPERATION] __StatusUpdate
  -- @param #OPERATION self
  -- @param #number delay Delay in seconds.


  --- Triggers the FSM event "Stop".
  -- @function [parent=#OPERATION] Stop
  -- @param #OPERATION self

  --- Triggers the FSM event "Stop" after a delay.
  -- @function [parent=#OPERATION] __Stop
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

--- Create a new generic OPERATION object.
-- @param #OPERATION self
-- @param #string Name Name of the phase. Default "Phase-01" where the last number is a running number.
-- @return #OPERATION.Phase Phase table object.
function OPERATION:AddPhase(Name)

  -- Increase phase counter.
  self.counterPhase=self.counterPhase+1

  local phase={} --#OPERATION.Phase
  phase.uid=self.counterPhase
  phase.name=Name or string.format("Phase-%02d", self.counterPhase)  
  phase.conditionOver=CONDITION:New(Name.." Over")
  phase.status=OPERATION.PhaseStatus.PLANNED
  
  -- Add phase.
  table.insert(self.phases, phase)
  
  return phase
end

--- Get a phase by its name.
-- @param #OPERATION self
-- @param #string Name Name of the phase. Default "Phase-01" where the last number is a running number.
-- @return #OPERATION.Phase Phase table object or nil if phase could not be found.
function OPERATION:GetPhaseByName(Name)

  for _,_phase in pairs(self.phases or {}) do
    local phase=_phase --#OPERATION.Phase
    if phase.name==Name then
      return phase
    end
  end

  return nil
end

--- Assign cohort to operation.
-- @param #OPERATION self
-- @param Ops.Cohort#COHORT Cohort The cohort
-- @return #OPERATION self
function OPERATION:AssignCohort(Cohort)

  self:T(self.lid..string.format("Assiging Cohort %s to operation", Cohort.name))
  self.cohorts[Cohort.name]=Cohort

end

--- Assign legion to operation. All cohorts of this legion will be assigned and are only available
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

--- Set status of a phase.
-- @param #OPERATION self
-- @param #OPERATION.Phase Phase The phase.
-- @param #string Status New status, *e.g.* `OPERATION.PhaseStatus.OVER`.
-- @return #OPERATION self
function OPERATION:SetPhaseStatus(Phase, Status)
  if Phase then
    self:T(self.lid..string.format("Phase %s status: %s-->%s"), Phase.status, Status)
    Phase.status=Status
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

--- Set codition when the given phase is over.
-- @param #OPERATION self
-- @param #OPERATION.Phase Phase The phase.
-- @param Core.Condition#CONDITION Condition Condition when the phase is over.
-- @return #OPERATION self
function OPERATION:SetPhaseConditonOver(Phase, Condition)
  if Phase then
    self:T(self.lid..string.format("Setting phase %s conditon over %s"), Phase.name, Condition and Condition.name or "None")
    Phase.conditionOver=Condition
  end
  return self
end

--- Add codition function when the given phase is over. Must return a `#boolean`.
-- @param #OPERATION self
-- @param #OPERATION.Phase Phase The phase.
-- @param #function Function Function that needs to be `true`before the phase is over. 
-- @param ... Condition function arguments if any.
-- @return #OPERATION self
function OPERATION:AddPhaseConditonOverAll(Phase, Function, ...)
  if Phase then
    Phase.conditionOver:AddFunctionAll(Function, ...)  
  end
  return self
end

--- Add codition function when the given phase is over. Must return a `#boolean`.
-- @param #OPERATION self
-- @param #OPERATION.Phase Phase The phase.
-- @param #function Function Function that needs to be `true`before the phase is over. 
-- @param ... Condition function arguments if any.
-- @return #OPERATION self
function OPERATION:AddPhaseConditonOverAny(Phase, Function, ...)
  if Phase then
    Phase.conditionOver:AddFunctionAny(Function, ...)  
  end
  return self
end


--- Get codition when the given phase is over.
-- @param #OPERATION self
-- @param #OPERATION.Phase Phase The phase.
-- @return Core.Condition#CONDITION Condition when the phase is over (if any).
function OPERATION:GetPhaseConditonOver(Phase, Condition)
  return Phase.conditionOver
end

--- Get currrently active phase.
-- @param #OPERATION self
-- @param #OPERATION.Phase Phase The phase.
-- @param #string Status New status, e.g. `OPERATION.PhaseStatus.OVER`.
-- @return #OPERATION self
function OPERATION:SetPhaseStatus(Phase, Status)
  if Phase then
    self:T(self.lid..string.format("Phase \"%s\" status: %s-->%s", Phase.name, Phase.status, Status))
    Phase.status=Status
  end
  return self
end

--- Get currrently active phase.
-- @param #OPERATION self
-- @return #OPERATION.Phase Current phase or `nil` if no current phase is active.
function OPERATION:GetPhaseActive()
  return self.phase
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

--- Get next phase.
-- @param #OPERATION self
-- @return #OPERATION.Phase Next phase or `nil` if no next phase exists.
function OPERATION:GetPhaseNext()
  
  for _,_phase in pairs(self.phases or {}) do
    local phase=_phase --#OPERATION.Phase
    
    if phase.status==OPERATION.PhaseStatus.PLANNED then
      -- Return first phase that is not over.
      return phase
    end
    
  end
  
  return nil
end

--- Count phases.
-- @param #OPERATION self
-- @param #string Status (Optional) Only count phases in a certain status, e.g. `OPERATION.PhaseStatus.PLANNED`.
-- @return #number Number of phases
function OPERATION:CountPhases(Status)

  local N=0
  for _,_phase in pairs(self.phases) do
    local phase=_phase --#OPERATION.Phase
    if Status==nil or Status==phase.status then
      N=N+1
    end
  end

  return N
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

--- Check if operation is in FSM state "Stopped".
-- @param #OPERATION self
-- @return #boolean If `true`, operation is "Stopped".
function OPERATION:IsStopped()
  local is=self:is("Stopped")
  return is
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
  
  -- Check phases.
  if self:IsRunning() then
    self:_CheckPhases()
  end
  
  -- Current phase.
  local currphase=self:GetPhaseActive()
  local phaseName="None"
  if currphase then
    phaseName=currphase.name
  end
  local NphaseTot=self:CountPhases()
  local NphaseAct=self:CountPhases(OPERATION.PhaseStatus.ACTIVE)
  local NphasePla=self:CountPhases(OPERATION.PhaseStatus.PLANNED)
  local NphaseOvr=self:CountPhases(OPERATION.PhaseStatus.OVER)
  
  -- General info.
  local text=string.format("State=%s: Phase=%s, Phases=%d [Active=%d, Planned=%d, Over=%d]", fsmstate, phaseName, NphaseTot, NphaseAct, NphasePla, NphaseOvr)
  self:I(self.lid..text)
  
  -- Info on phases.
  local text="Phases:"
  for i,_phase in pairs(self.phases) do
    local phase=_phase --#OPERATION.Phase
    text=text..string.format("\n[%d] %s: status=%s", i, phase.name, tostring(phase.status))
  end
  if text=="Phases:" then text=text.." None" end
  self:I(self.lid..text)

  -- Next status update.
  self:__StatusUpdate(-30)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
    self:SetPhaseStatus(self.phase, OPERATION.PhaseStatus.OVER)
    oldphase=self.phase.name
  end

  -- Debug message.
  self:T(self.lid..string.format("Phase change: %s --> %s", oldphase, Phase.name))
  
  -- Set currently active phase.
  self.phase=Phase
  
  -- Phase is active.
  self:SetPhaseStatus(Phase, OPERATION.PhaseStatus.ACTIVE)
  
end

--- On after "Over" event.
-- @param #OPERATION self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #OPERATION.Phase Phase The new phase.
function OPERATION:onafterOver(From, Event, To)

  -- Debug message.
  self:T(self.lid..string.format("Operation is over!"))
  
  -- No active phase.
  self.phase=nil
  
  -- Set all phases to OVER.
  for _,_phase in pairs(self.phases) do
    local phase=_phase --#OPERATION.Phase
    self:SetPhaseStatus(phase, OPERATION.PhaseStatus.OVER)
  end
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Check phases.
-- @param #OPERATION self
function OPERATION:_CheckPhases()

  -- Currently active phase.
  local phase=self:GetPhaseActive()
  
  -- Check if active phase is over if conditon over is defined.
  if phase and phase.conditionOver then
    local isOver=phase.conditionOver:Evaluate()
    if isOver then
      self:SetPhaseStatus(phase, OPERATION.PhaseStatus.OVER)
    end
  end
  
  -- If no current phase or current phase is over, get next phase.
  if phase==nil or phase.status==OPERATION.PhaseStatus.OVER then
  
    -- Get next phase.
    local Phase=self:GetPhaseNext()
    
    if Phase then
    
      -- Change phase to next one.
      self:PhaseChange(Phase)
            
    else
    
      -- No further phases defined ==> Operation is over.
      self:Over()
      
    end
    
  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
