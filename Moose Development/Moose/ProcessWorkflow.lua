--- @module Task2Workflow

--- The TASK2_WORKFLOW class
-- @type TASK2_WORKFLOW
-- @extends Base#BASE
TASK2_WORKFLOW = {
  ClassName = "TASK2_WORKFLOW",
}

function TASK2_WORKFLOW:New( Client, Task )

  -- Inherits from BASE
  local self = BASE:Inherit( self, BASE:New() )

  Task:Assign( Client )

end
