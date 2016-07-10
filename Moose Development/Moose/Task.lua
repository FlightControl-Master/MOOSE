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
  Players = nil,
  Scores = {},
}


--- Instantiates a new TASK_BASE. Should never be used. Interface Class.
-- @param #TASK_BASE self
-- @return #TASK_BASE self
function TASK_BASE:New( Mission, TaskName, TaskType, TaskCategory )
  local self = BASE:Inherit( self, BASE:New() )
  self:F()

  self.Processes = {}
  self.Fsm = {}
  self.Mission = Mission
  self.TaskName = TaskName
  self.TaskType = TaskType
  self.TaskCategory = TaskCategory
  self.TaskID = 0
  self.TaskBriefing = "You are assigned to the task: " .. self.TaskName .. "."

  return self
end

--- Assign the @{Task}to a @{Group}.
-- @param #TASK_BASE self
-- @param Group#GROUP TaskGroup
-- @return #TASK_BASE self
function TASK_BASE:AssignToGroup( TaskGroup )
  self:F2( TaskGroup:GetName() )
  
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
function TASK_BASE:RemoveProcesses( TaskUnit, FailProcesses )
  local TaskUnitName = TaskUnit:GetName()
  for _, ProcessData in pairs( self.Processes[TaskUnitName] ) do
    local Process = ProcessData -- Process#PROCESS
    if FailProcesses then
      Process.Fsm:Fail()
    end
    Process:StopEvents()
    Process = nil
    self.Processes[TaskUnitName][_] = nil
    self:E( self.Processes[TaskUnitName][_] )
  end
  self.Processes[TaskUnitName] = nil
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
    self.Fsm[TaskUnitName][_] = nil
    self:E( self.Fsm[TaskUnitName][_] )
  end
  self.Fsm[TaskUnitName] = nil
end

--- Checks if there is a FiniteStateMachine assigned to @{Unit} for @{Task}
-- @param #TASK_BASE self
-- @param Unit#UNIT TaskUnit
-- @return #TASK_BASE self
function TASK_BASE:HasStateMachine( TaskUnit )
  local TaskUnitName = TaskUnit:GetName()
  self:F( { TaskUnitName, self.Fsm[TaskUnitName] ~= nil } )
  return ( self.Fsm[TaskUnitName] ~= nil )
end




--- Assign the @{Task}to an alive @{Unit}.
-- @param #TASK_BASE self
-- @param Unit#UNIT TaskUnit
-- @return #TASK_BASE self
function TASK_BASE:AssignToUnit( TaskUnit )
  self:F( TaskUnit:GetName() )
  
  return nil
end

--- UnAssign the @{Task} from an alive @{Unit}.
-- @param #TASK_BASE self
-- @param Unit#UNIT TaskUnit
-- @return #TASK_BASE self
function TASK_BASE:UnAssignFromUnit( TaskUnit, FailProcesses )
  self:F( TaskUnit:GetName() )
  
  if self:HasStateMachine( TaskUnit ) == true then
    self:RemoveStateMachines( TaskUnit )
    self:RemoveProcesses( TaskUnit, FailProcesses )
  end

  return self
end

--- Register a potential new assignment for a new spawned @{Unit}.
-- Tasks only get assigned if there are players in it.
-- @param #TASK_BASE self
-- @param Event#EVENTDATA Event
-- @return #TASK_BASE self
function TASK_BASE:_EventAssignUnit( Event )
  if Event.IniUnit then
    self:F( Event )
    local TaskUnit = Event.IniUnit
    if TaskUnit:IsAlive() then
      local TaskPlayerName = TaskUnit:GetPlayerName()
      if TaskPlayerName ~= nil then
        if not self:HasStateMachine( TaskUnit ) then
          self:AssignToUnit( TaskUnit )
        end
      end
    end
  end
  return nil
end

--- UnAssigns a @{Unit} that is left by a player, crashed, dead, ....
-- There are only assignments if there are players in it.
-- @param #TASK_BASE self
-- @param Event#EVENTDATA Event
-- @return #TASK_BASE self
function TASK_BASE:_EventUnAssignUnit( Event )
  self:F( Event )
  if Event.IniUnit then
    local TaskUnit = Event.IniUnit
    self:F( TaskUnit:GetName() )
    self:UnAssignFromUnit( TaskUnit, true )
  end
  return nil
end

--- Gets the Scoring of the task
-- @param #TASK_BASE self
-- @return Scoring#SCORING Scoring
function TASK_BASE:GetScoring()
  return self.Mission:GetScoring()
end

--- Sets the Name of the Task
-- @param #TASK_BASE self
-- @param #string TaskName
function TASK_BASE:SetName( TaskName )
  self.TaskName = TaskName
end

--- Gets the Name of the Task
-- @param #TASK_BASE self
-- @return #string The Task Name
function TASK_BASE:GetName()
  return self.TaskName
end

--- Sets the Type of the Task
-- @param #TASK_BASE self
-- @param #string TaskType
function TASK_BASE:SetType( TaskType )
  self.TaskType = TaskType
end

--- Gets the Type of the Task
-- @param #TASK_BASE self
-- @return #string TaskType
function TASK_BASE:GetType()
  return self.TaskType
end

--- Sets the Category of the Task
-- @param #TASK_BASE self
-- @param #string TaskCategory
function TASK_BASE:SetCategory( TaskCategory )
  self.TaskCategory = TaskCategory
end

--- Gets the Category of the Task
-- @param #TASK_BASE self
-- @return #string TaskCategory
function TASK_BASE:GetCategory()
  return self.TaskCategory
end

--- Sets the ID of the Task
-- @param #TASK_BASE self
-- @param #string TaskID
function TASK_BASE:SetID( TaskID )
  self.TaskID = TaskID
end

--- Gets the ID of the Task
-- @param #TASK_BASE self
-- @return #string TaskID
function TASK_BASE:GetID()
  return self.TaskID
end


--- Sets a @{Task} to status **Success**.
-- @param #TASK_BASE self
function TASK_BASE:StateSuccess()
  self:SetState( self, "State", "Success" )
end

--- Is the @{Task} status **Success**.
-- @param #TASK_BASE self
function TASK_BASE:IsStateSuccess()
  return self:GetStateString() == "Success"
end

--- Sets a @{Task} to status **Failed**.
-- @param #TASK_BASE self
function TASK_BASE:StateFailed()
  self:SetState( self, "State", "Failed" )
end

--- Is the @{Task} status **Failed**.
-- @param #TASK_BASE self
function TASK_BASE:IsStateFailed()
  return self:GetStateString() == "Failed"
end

--- Sets a @{Task} to status **Planned**.
-- @param #TASK_BASE self
function TASK_BASE:StatePlanned()
  self:SetState( self, "State", "Planned" )
end

--- Is the @{Task} status **Planned**.
-- @param #TASK_BASE self
function TASK_BASE:IsStatePlanned()
  return self:GetStateString() == "Planned"
end

--- Sets a @{Task} to status **Assigned**.
-- @param #TASK_BASE self
function TASK_BASE:StateAssigned()
  self:SetState( self, "State", "Assigned" )
end

--- Is the @{Task} status **Assigned**.
-- @param #TASK_BASE self
function TASK_BASE:IsStateAssigned()
  return self:GetStateString() == "Assigned"
end

--- Sets a @{Task} to status **Hold**.
-- @param #TASK_BASE self
function TASK_BASE:StateHold()
  self:SetState( self, "State", "Hold" )
end

--- Is the @{Task} status **Hold**.
-- @param #TASK_BASE self
function TASK_BASE:IsStateHold()
  return self:GetStateString() == "Hold"
end

--- Sets a @{Task} to status **Replanned**.
-- @param #TASK_BASE self
function TASK_BASE:StateReplanned()
  self:SetState( self, "State", "Replanned" )
end

--- Is the @{Task} status **Replanned**.
-- @param #TASK_BASE self
function TASK_BASE:IsStateReplanned()
  return self:GetStateString() == "Replanned"
end

--- Gets the @{Task} status.
-- @param #TASK_BASE self
function TASK_BASE:GetStateString()
  return self:GetState( self, "State" )
end

--- Sets a @{Task} briefing.
-- @param #TASK_BASE self
-- @param #string TaskBriefing
-- @return self
function TASK_BASE:SetBriefing( TaskBriefing )
  self.TaskBriefing = TaskBriefing
  return self
end

--- StateMachine callback function for a TASK
-- @param #TASK_BASE self
-- @param StateMachine#STATEMACHINE_TASK Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Event#EVENTDATA Event
function TASK_BASE:OnStateChange( Fsm, Event, From, To )

  MESSAGE:New( "Task " .. self.TaskName .. " : " .. Event .. " changed to state " .. To, 15 ):ToAll()
  self:SetState( self, "State", To )

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




