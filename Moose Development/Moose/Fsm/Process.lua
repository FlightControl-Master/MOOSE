--- @module Process

--- The PROCESS class
-- @type PROCESS
-- @field Tasking.Task#TASK_BASE ProcessTask
-- @field Wrapper.Group#GROUP ProcessGroup
-- @field Core.Menu#MENU_GROUP MissionMenu
-- @field #string ProcessName
-- @extends Fsm.Fsm#STATEMACHINE_CONTROLLABLE
PROCESS = {
  ClassName = "PROCESS",
  NextEvent = nil,
  Scores = {},
}

--- Instantiates a new TASK Base. Should never be used. Interface Class.
-- @param #PROCESS self
-- @param #string ProcessName
-- @param Wrapper.Unit#UNIT ProcessUnit (Optional) If provided, it defines the UNIT for which the process is running.
-- @return #PROCESS
function PROCESS:New( FSMT, ProcessName, ProcessUnit )
  local self = BASE:Inherit( self, FSM_PROCESS:New( FSMT, ProcessUnit ) )
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
-- @return Wrapper.Group#GROUP
function PROCESS:GetGroup()

  return self.ProcessGroup
end



