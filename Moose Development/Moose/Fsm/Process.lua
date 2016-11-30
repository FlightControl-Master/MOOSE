--- @module Process

--- The PROCESS class
-- @type PROCESS
-- @field Task#TASK_BASE ProcessTask
-- @field Group#GROUP ProcessGroup
-- @field Menu#MENU_GROUP MissionMenu
-- @field #string ProcessName
-- @extends Core.StateMachine#STATEMACHINE_CONTROLLABLE
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
  local self = BASE:Inherit( self, STATEMACHINE_PROCESS:New( FSMT, ProcessUnit ) )
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



