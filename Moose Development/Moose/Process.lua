--- @module Process

--- The PROCESS class
-- @type PROCESS
-- @field Scheduler#SCHEDULER ProcessScheduler
-- @field Unit#UNIT ProcessUnit
-- @field Task#TASK Task
-- @field StateMachine#STATEMACHINE_TASK Fsm
-- @field #string ProcessName
-- @extends Base#BASE
PROCESS = {
  ClassName = "TASK",
  ProcessScheduler = nil,
  NextEvent = nil,
  Scores = {},
}

--- Instantiates a new TASK Base. Should never be used. Interface Class.
-- @param #PROCESS self
-- @param #string ProcessName
-- @param Task#TASK_BASE Task
-- @param Unit#UNIT ProcessUnit
-- @return #PROCESS self
function PROCESS:New( ProcessName, Task, ProcessUnit )
  local self = BASE:Inherit( self, BASE:New() )
  self:F()

  self.ProcessUnit = ProcessUnit
  self.Task = Task
  self.ProcessName = ProcessName
  
  self.AllowEvents = true
  
  return self
end

--- @param #PROCESS self
function PROCESS:NextEvent( NextEvent, ... )
  self:F2( arg )
  if self.AllowEvents == true then
    self.ProcessScheduler = SCHEDULER:New( self.Fsm, NextEvent, { self, self.ProcessUnit, unpack( arg ) }, 1 )
  end
end

--- @param #PROCESS self
function PROCESS:StopEvents( )
  self:F2()
  if self.ProcessScheduler then
    self:E( "Stop" )
    self.ProcessScheduler:Stop()
    self.ProcessScheduler = nil
    self.AllowEvents = false
  end
end

--- Adds a score for the PROCESS to be achieved.
-- @param #PROCESS self
-- @param #string ProcessStatus is the status of the PROCESS when the score needs to be given.
-- @param #string ScoreText is a text describing the score that is given according the status.
-- @param #number Score is a number providing the score of the status.
-- @return #PROCESS self
function PROCESS:AddScore( ProcessStatus, ScoreText, Score )
  self:F2( { ProcessStatus, ScoreText, Score } )

  self.Scores[ProcessStatus] = self.Scores[ProcessStatus] or {}
  self.Scores[ProcessStatus].ScoreText = ScoreText
  self.Scores[ProcessStatus].Score = Score
  return self
end

--- StateMachine callback function for a PROCESS
-- @param #PROCESS self
-- @param StateMachine#STATEMACHINE_PROCESS Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
function PROCESS:OnStateChange( Fsm, Event, From, To )
  self:E( { Event, From, To, self.ProcessUnit.UnitName } )

  MESSAGE:New( "Process " .. self.ProcessName .. " : " .. Event .. " changed to state " .. To, 15 ):ToAll()

  if self.Scores[To] then
    
    local Scoring = self.Task:GetScoring()
    if Scoring then
      Scoring:_AddMissionTaskScore( self.Task.Mission, self.ProcessUnit, self.Scores[To].ScoreText, self.Scores[To].Score )
    end
  end
end


