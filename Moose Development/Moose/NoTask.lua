--- A NOTASK is a dummy activity... But it will show a Mission Briefing...
-- @module NOTASK

--- The NOTASK class
-- @type
NOTASK = {
  ClassName = "NOTASK",
}

--- Creates a new NOTASK.
function NOTASK:New()
  local self = BASE:Inherit( self, TASK:New() )
	self:F()
  
  local Valid = true

  if  Valid then
    self.Name = 'Nothing'
    self.TaskBriefing = "Task: Execute your mission."
    self.Stages = { STAGEBRIEF:New(), STAGESTART:New(), STAGEDONE:New() }
	self.SetStage( self, 1 )
  end
  
  return self
end
