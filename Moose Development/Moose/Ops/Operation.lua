--- **Ops** - Operation with multiple phases.
--
-- ## Main Features:
--
--    * Define operation phases
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
}

--- Global mission counter.
_OPERATIONID=0

--- Operation phase.
-- @type OPERATION.Phase
-- @field #number uid Unique ID of the phase.
-- @field #string name Name of the phase.
-- @field Core.Condition#CONDITION conditionOver Conditions when the phase is over.
-- @field #boolean isOver If `true`, phase is over.

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
  
  self:AddTransition("*",                      "ChangePhase",              "*")
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
-- @param Core.Condition#CONDITION ConditionOver Condition when the phase is over.
-- @return #OPERATION.Phase Phase table object.
function OPERATION:AddPhase(Name, ConditionOver)

  -- Increase phase counter.
  self.counterPhase=self.counterPhase+1

  local phase={} --#OPERATION.Phase
  phase.uid=self.counterPhase
  phase.name=Name or string.format("Phase-%02d", self.counterPhase)  
  phase.conditionOver=ConditionOver or CONDITION:New(Name)
  phase.isOver=false
  
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

  self.cohorts[Cohort.name]=Cohort

end

--- Assign legion to operation. All cohorts of this legion will be assigned and are only available
-- @param #OPERATION self
-- @param Ops.Legion#LEGION Legion The legion to be assigned.
-- @return #OPERATION self
function OPERATION:AssignLegion(Legion)

  self.legions[Legion.alias]=Legion

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

--- Get currrently active phase.
-- @param #OPERATION self
-- @return #OPERATION.Phase Current phase or `nil` if no current phase is active.
function OPERATION:GetPhaseActive()
  return self.phase
end

--- Get next phase.
-- @param #OPERATION self
-- @return #OPERATION.Phase Next phase or `nil` if no next phase exists.
function OPERATION:GetPhaseNext()
  
  for _,_phase in pairs(self.phases or {}) do
    local phase=_phase --#OPERATION.Phase
    
    if not phase.isOver then
      -- Return first phase that is not over.
      return phase
    end
    
  end
  
  return nil
end

--- Count phases.
-- @param #OPERATION self
-- @return #number Number of phases
function OPERATION:CountPhases()

  local N=0
  for phasename, phase in pairs(self.phases) do
    N=N+1
  end

  return N
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

  -- Get 
  local Phase=self:GetPhaseNext()
  
  if Phase then
    self:PhaseChange(Phase)
  end

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
  
  -- Current phase.
  local currphase=self:GetPhaseActive()
  local phasename=currphase and currphase.name or "None"
  local Nphase=self:CountPhases()
  
  -- General info.
  local text=string.format("State=%s: Phase=%s, Phases=%d", fsmstate, phasename, Nphase)
  self:I(self.lid..text)
  
  -- Info on phases.
  local text="Phases:"
  for i,_phase in pairs(self.phases) do
    local phase=_phase --#OPERATION.Phase
    text=text..string.format("\n[%d] %s", i, phase.name)
  end
  if text=="Phases:" then text=text.." None" end

  -- Next status update.
  self:__StatusUpdate(-30)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after "ChangePhase" event.
-- @param #OPERATION self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #OPERATION.Phase Phase The new phase.
function OPERATION:onafterChangePhase(From, Event, To, Phase)

  -- Debug message.
  self:T(self.lid..string.format("Changed to phase: %s", Phase.name))
  
  -- Set currently active phase.
  self.phase=Phase
  
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
    
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Check phases.
-- @param #OPERATION self
function OPERATION:_CheckPhases()

  -- Currently active phase.
  local phase=self:GetPhaseActive()
  
  -- Check if active phase is over.
  if phase then
    phase.isOver=phase.conditionOver:Evaluate()
  end
  
  -- If no current phase or current phase is over, get next phase.
  if phase==nil or (phase and phase.isOver) then
  
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
