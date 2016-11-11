--- @module Process

--- The PROCESS class
-- @type PROCESS
-- @field Task#TASK_BASE ProcessTask
-- @field Group#GROUP ProcessGroup
-- @field Menu#MENU_GROUP MissionMenu
-- @field #string ProcessName
-- @extends StateMachine#STATEMACHINE_CONTROLLABLE
PROCESS = {
  ClassName = "PROCESS",
  NextEvent = nil,
  Scores = {},
}

--- Instantiates a new TASK Base. Should never be used. Interface Class.
-- @param #PROCESS self
-- @param #string ProcessName
-- @param Unit#UNIT ProcessUnit (Optional) If provided, it defines the UNIT for which the process is running.
-- @return #PROCESS
function PROCESS:New( FSMT, ProcessName, ProcessUnit )
  local self = BASE:Inherit( self, STATEMACHINE_CONTROLLABLE:New( FSMT, ProcessUnit ) )
  self:F()

  if ProcessUnit then
    self.ProcessGroup = ProcessUnit:GetGroup()
  end
  
  --self.MissionMenu = Task.Mission:GetMissionMenu( self.ProcessGroup )
  self.ProcessName = ProcessName
  
  return self
end

--- Gets the Group of the process.
-- @param #PROCESS self
-- @return Group#GROUP
function PROCESS:GetGroup()

  return self.ProcessGroup
end

--- Sets the task of the process.
-- @param #PROCESS self
-- @param Tasking.Task#TASK_BASE ProcessTask
-- @return #PROCESS
function PROCESS:SetTask( ProcessTask )

  self.ProcessTask = ProcessTask

  return self
end

--- Gets the task of the process.
-- @param #PROCESS self
-- @return Task#TASK_BASE
function PROCESS:GetTask()

  return self.ProcessTask
end

--- Gets the mission of the process.
-- @param #PROCESS self
-- @return Mission#MISSION
function PROCESS:GetMission()

  return self.ProcessTask.Mission
end

function PROCESS:ProcessStart()

end

function PROCESS:ProcessStop()
  self:E("ProcessStop Base Class")

  self:EventRemoveAll()
end

--- Assign the process to a @{Unit} and activate the process.
-- @param #PROCESS self
-- @param Unit#UNIT ProcessUnit
-- @return #PROCESS self
function PROCESS:Assign( ProcessTask, ProcessUnit )

  self:SetControllable( ProcessUnit )
  self:SetTask( ProcessTask )
  
  self:ProcessStart()
  
  self.ProcessGroup = ProcessUnit:GetGroup()
  --self:Activate()

  return self
end

--- Adds a score for the PROCESS to be achieved.
-- @param #PROCESS self
-- @param Task#TASK_BASE Task The task for which the process needs to account score.
-- @param #string ProcessStatus is the state of the process when the score needs to be given. (See the relevant state descriptions of the process).
-- @param #string ScoreText is a text describing the score that is given according the status.
-- @param #number Score is a number providing the score of the status.
-- @return #PROCESS self
function PROCESS:AddScore( Task, ProcessStatus, ScoreText, Score )
  self:F2( { ProcessStatus, ScoreText, Score } )

  self.Scores[ProcessStatus] = self.Scores[ProcessStatus] or {}
  self.Scores[ProcessStatus].ScoreText = ScoreText
  self.Scores[ProcessStatus].Score = Score
  self.Scores[ProcessStatus].Task = Task
  
  return self
end

--- StateMachine callback function for a PROCESS
-- @param #PROCESS self
-- @param Controllable#CONTROLLABLE ProcessUnit
-- @param #string Event
-- @param #string From
-- @param #string To
function PROCESS:OnStateChange( ProcessUnit, Event, From, To )
  self:E( { self.ProcessName, Event, From, To, ProcessUnit.UnitName } )

  if self:IsTrace() then
    MESSAGE:New( "Process " .. self.ProcessName .. " : " .. Event .. " changed to state " .. To, 15 ):ToAll()
  end

  -- TODO: This needs to be reworked with a callback functions allocated within Task, and set within the mission script from the Task Objects...
  if self.Scores[To] then
  
    local Task = self.Scores[To].Task  
    local Scoring = Task:GetScoring()
    if Scoring then
      Scoring:_AddMissionTaskScore( Task.Mission, ProcessUnit, self.Scores[To].ScoreText, self.Scores[To].Score )
    end
  end
end


