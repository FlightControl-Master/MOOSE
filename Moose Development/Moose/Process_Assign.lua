--- @module Task_Assign

--- PROCESS_ASSIGN class
-- @type PROCESS_ASSIGN
-- @field Task#TASK_BASE Task
-- @field Unit#UNIT ProcessUnit
-- @field Zone#ZONE_BASE TargetZone
-- @extends Task2#TASK2
PROCESS_ASSIGN = { 
  ClassName = "PROCESS_ASSIGN",
}


--- Creates a new task assignment state machine. The process will request from the menu if it accepts the task, if not, the unit is removed from the simulator.
-- @param #PROCESS_ASSIGN self
-- @param Task#TASK Task
-- @param Unit#UNIT Unit
-- @return #PROCESS_ASSIGN self
function PROCESS_ASSIGN:New( Task, ProcessUnit, TaskBriefing )

  -- Inherits from BASE
  local self = BASE:Inherit( self, PROCESS:New( "ASSIGN", Task, ProcessUnit ) ) -- #PROCESS_ASSIGN
  
  self.TaskBriefing = TaskBriefing
  
  self.Fsm = STATEMACHINE_PROCESS:New( self, {
    initial = 'UnAssigned',
    events = {
      { name = 'Menu',  from = 'UnAssigned',  to = 'AwaitAccept' },
      { name = 'Assign',  from = 'AwaitAccept',  to = 'Assigned' },
      { name = 'Reject',  from = 'AwaitAccept',  to = 'Rejected' },
      { name = 'Fail',  from = 'AwaitAccept',  to = 'Rejected' },
    },
    callbacks = {
      onMenu = self.OnMenu,
      onAssign = self.OnAssign,
      onReject = self.OnReject,
    },
    endstates = {
      'Assigned', 'Rejected'
    },
  } )
  
  return self
end

--- StateMachine callback function for a TASK2
-- @param #PROCESS_ASSIGN self
-- @param StateMachine#STATEMACHINE_TASK Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
function PROCESS_ASSIGN:OnMenu( Fsm, Event, From, To )
  self:E( { Event, From, To, self.ProcessUnit.UnitName} )

  MESSAGE:New( self.TaskBriefing .. "\nAccess the radio menu to accept the task. You have 30 seconds or the assignment will be cancelled.", 30, "Assignment" ):ToGroup( self.ProcessUnit:GetGroup() )
  self.MenuText = self.Task.TaskName
 
  local ProcessGroup = self.ProcessUnit:GetGroup() 
  self.Menu = MENU_GROUP:New( ProcessGroup, "Task " .. self.MenuText .. " acceptance" )
  self.MenuAcceptTask = MENU_GROUP_COMMAND:New( ProcessGroup, "Accept task " .. self.MenuText, self.Menu, self.MenuAssign, self )
  self.MenuRejectTask = MENU_GROUP_COMMAND:New( ProcessGroup, "Reject task " .. self.MenuText, self.Menu, self.MenuReject, self )
end

--- Menu function.
-- @param #PROCESS_ASSIGN self
function PROCESS_ASSIGN:MenuAssign()
  self:E( )

  self:NextEvent( self.Fsm.Assign )
end

--- Menu function.
-- @param #PROCESS_ASSIGN self
function PROCESS_ASSIGN:MenuReject()
  self:E( )

  self:NextEvent( self.Fsm.Reject )
end

--- StateMachine callback function for a TASK2
-- @param #PROCESS_ASSIGN self
-- @param StateMachine#STATEMACHINE_PROCESS Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
function PROCESS_ASSIGN:OnAssign( Fsm, Event, From, To )
  self:E( { Event, From, To, self.ProcessUnit.UnitName} )

  self.Menu:Remove()
end

--- StateMachine callback function for a TASK2
-- @param #PROCESS_ASSIGN self
-- @param StateMachine#STATEMACHINE_PROCESS Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
function PROCESS_ASSIGN:OnReject( Fsm, Event, From, To )
  self:E( { Event, From, To, self.ProcessUnit.UnitName} )

  self.Menu:Remove()
  self.Task:UnAssignFromUnit( self.ProcessUnit )
  self.ProcessUnit:Destroy()
end
