--- A NOTASK is a dummy activity... But it will show a Mission Briefing...
-- @classmod NOTASK

Include.File("Task")

--- Modeling a sequence of STAGEs to do nothing, but wait for the mission goal.
NOTASK = {
  ClassName = "NOTASK",
}

--- Creates a new NOTASK.
function NOTASK:New()
trace.f(self.ClassName)

  -- Child holds the inherited instance of the PICKUPTASK Class to the BASE class.
  local Child = BASE:Inherit( self, TASK:New() )

  local Valid = true

  if  Valid then
    Child.Name = 'Nothing'
    Child.TaskBriefing = "Task: Execute your mission."
    Child.Stages = { STAGEBRIEF:New(), STAGESTART:New(), STAGEDONE:New() }
	Child.SetStage( Child, 1 )
  end
  
  return Child
end
