--- @module Task

--- The TASK_BASE class
-- @type TASK_BASE
-- @field Scheduler#SCHEDULER TaskScheduler
-- @field Mission#MISSION Mission
-- @field StateMachine#STATEMACHINE Fsm
-- @extends Base#BASE
TASK_BASE = {
  ClassName = "TASK_BASE",
  TaskScheduler = nil,
  Processes = {},
  Scores = {},
}

--- Instantiates a new TASK_BASE. Should never be used. Interface Class.
-- @param #TASK_BASE self
-- @return #TASK_BASE self
function TASK_BASE:New()
  local self = BASE:Inherit( self, BASE:New() )
  self:F()

  self.Processes = {}
  self.Fsm = {}

  return self
end

--- Assign the @{Task}to a @{Group}.
-- @param #TASK_BASE self
-- @param Group#GROUP TaskGroup
-- @return #TASK_BASE self
function TASK_BASE:AssignToGroup( TaskGroup )
  self:FZ( TaskGroup:GetName() )
  
  local TaskUnits = TaskGroup:GetUnits()
  for UnitID, UnitData in pairs( TaskUnits ) do
    local TaskUnit = UnitData -- Unit#UNIT
    local PlayerName = TaskUnit:GetPlayerName()
    if PlayerName ~= nil or PlayerName ~= "" then
      self:AssignToUnit( TaskUnit )
    end
  end
  return self
end

--- Add Process to @{Task} with key @{Unit}
-- @param #TASK_BASE self
-- @param Unit#UNIT TaskUnit
-- @return #TASK_BASE self
function TASK_BASE:AddProcess( TaskUnit, Process )
  local TaskUnitName = TaskUnit:GetName()
  self.Processes[TaskUnitName] = self.Processes[TaskUnitName] or {}
  self.Processes[TaskUnitName][#self.Processes[TaskUnitName]+1] = Process
  return Process
end

--- Remove Processes from @{Task} with key @{Unit}
-- @param #TASK_BASE self
-- @return #TASK_BASE self
function TASK_BASE:RemoveProcesses( TaskUnit )
  local TaskUnitName = TaskUnit:GetName()
  for _, Process in pairs( self.Processes[TaskUnitName] ) do
    Process = nil
  end
end

--- Add a FiniteStateMachine to @{Task} with key @{Unit}
-- @param #TASK_BASE self
-- @param Unit#UNIT TaskUnit
-- @return #TASK_BASE self
function TASK_BASE:AddStateMachine( TaskUnit, Fsm )
  local TaskUnitName = TaskUnit:GetName()
  self.Fsm[TaskUnitName] = self.Fsm[TaskUnitName] or {}
  self.Fsm[TaskUnitName][#self.Fsm[TaskUnitName]+1] = Fsm
  return Fsm
end

--- Remove FiniteStateMachines from @{Task} with key @{Unit}
-- @param #TASK_BASE self
-- @return #TASK_BASE self
function TASK_BASE:RemoveStateMachines( TaskUnit )
  local TaskUnitName = TaskUnit:GetName()
  for _, Fsm in pairs( self.Fsm[TaskUnitName] ) do
    Fsm = nil
  end
end




--- Assign the @{Task}to an alive @{Unit}.
-- @param #TASK_BASE self
-- @param Unit#UNIT TaskUnit
-- @return #TASK_BASE self
function TASK_BASE:AssignToUnit( TaskUnit )
  
  return nil
end


--- @param #TASK_BASE self
function TASK_BASE:_Schedule()
  self:F2()

  self.TaskScheduler = SCHEDULER:New( self, _Scheduler, {}, 15, 15 )
  return self
end


--- @param #TASK_BASE self
function TASK_BASE._Scheduler()
  self:F2()

  return true
end




