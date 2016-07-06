--- @module Process

--- The PROCESS class
-- @type PROCESS
-- @field Scheduler#SCHEDULER ProcessScheduler
-- @field Unit#UNIT ProcessUnit
-- @field Task#MISSION Task
-- @field StateMachine#STATEMACHINE_TASK Fsm
-- @extends Base#BASE
PROCESS = {
  ClassName = "TASK",
  ProcessScheduler = nil,
  NextEvent = nil,
  Scores = {},
}

--- Instantiates a new TASK Base. Should never be used. Interface Class.
-- @param #PROCESS self
-- @param Unit#UNIT ProcessUnit
-- @return #PROCESS self
function PROCESS:New( Task, ProcessUnit )
  local self = BASE:Inherit( self, BASE:New() )
  self:F()

  self.ProcessUnit = ProcessUnit
  self.Task = Task
  
  return self
end

--- @param #PROCESS self
function PROCESS:NextEvent( NextEvent, ... )
  self:E( NextEvent )

  self.ProcessScheduler = SCHEDULER:New( self.Fsm, NextEvent, { self, self.ProcessUnit, unpack( arg ) }, 1 )
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
-- @param StateMachine#STATEMACHINE_TASK Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
function PROCESS:OnStateChange( Fsm, Event, From, To )
  self:E( { Event, From, To, self.ProcessUnit.UnitName } )

  if self.Scores[To] then
    self.Unit:Message( "Score:" .. self.Scores[To].ScoreText .. " " .. To , 15 )
    local Scoring = self.Task:GetScoring()
    if Scoring then
      Scoring:_AddTaskProcessScore( self.ProcessUnit, self.Task:GetName(), self.Scores[To].Score )
    end
  end
end


