--- @module Task2

--- The TASK2 class
-- @type TASK2
-- @field Scheduler#SCHEDULER TaskScheduler
-- @field Unit#UNIT TaskUnit
-- @field Mission#MISSION Mission
-- @field StateMachine#STATEMACHINE_TASK Fsm
-- @extends Base#BASE
TASK2 = {
  ClassName = "TASK",
  TaskScheduler = nil,
  NextEvent = nil,
  Scores = {},
}

--- Instantiates a new TASK Base. Should never be used. Interface Class.
-- @param #TASK2 self
-- @param Unit#UNIT TaskUnit
-- @return #TASK2 self
function TASK2:New( Mission, TaskUnit )
  local self = BASE:Inherit( self, BASE:New() )
  self:F()

  self.TaskUnit = TaskUnit
  self.Mission = Mission
  
  return self
end

--- @param #TASK2 self
function TASK2:NextEvent( NextEvent, ... )
  self:E( NextEvent )

  self.TaskScheduler = SCHEDULER:New( self.Fsm, NextEvent, { self, self.TaskUnit, unpack( arg ) }, 1 )
end

--- Adds a score for the TASK2 to be achieved.
-- @param #TASK2 self
-- @param #string TaskStatus is the status of the TASK2 when the score needs to be given.
-- @param #string ScoreText is a text describing the score that is given according the status.
-- @param #number Score is a number providing the score of the status.
-- @return #TASK2 self
function TASK2:AddScore( TaskStatus, ScoreText, Score )
  self:F2( { TaskStatus, ScoreText, Score } )

  self.Scores[TaskStatus] = self.Scores[TaskStatus] or {}
  self.Scores[TaskStatus].ScoreText = ScoreText
  self.Scores[TaskStatus].Score = Score
  return self
end

--- StateMachine callback function for a TASK2
-- @param #TASK2 self
-- @param StateMachine#STATEMACHINE_TASK Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
function TASK2:OnStateChange( Fsm, Event, From, To )
  self:E( { Event, From, To, self.TaskUnit.UnitName } )

  if self.Scores[To] then
    self.Unit:Message( "Score:" .. self.Scores[To].ScoreText .. " " .. To , 15 )
    local Scoring = self.Mission:GetScoring()
    if Scoring then
      Scoring:_AddMissionTaskScore( self.TaskUnit, self.Mission:GetName(), self.Scores[To].Score )
    end
  end
end


