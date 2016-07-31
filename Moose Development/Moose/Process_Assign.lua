--- This module contains the PROCESS_ASSIGN classes.
-- 
-- ===
-- 
-- 1) @{Task_Assign#TASK_ASSIGN_ACCEPT} class, extends @{Task#TASK_BASE}
-- =====================================================================
-- The @{Task_Assign#TASK_ASSIGN_ACCEPT} class accepts by default a task for a player. No player intervention is allowed to reject the task.
-- 
-- 2) @{Task_Assign#TASK_ASSIGN_MENU_ACCEPT} class, extends @{Task#TASK_BASE}
-- ==========================================================================
-- The @{Task_Assign#TASK_ASSIGN_MENU_ACCEPT} class accepts a task when the player accepts the task through an added menu option.
-- This assignment type is useful to conditionally allow the player to choose whether or not he would accept the task.
-- The assignment type also allows to reject the task.
-- 
-- 
-- 
-- 
-- 
-- 
-- @module Task_Assign
-- 


do -- PROCESS_ASSIGN_ACCEPT

  --- PROCESS_ASSIGN_ACCEPT class
  -- @type PROCESS_ASSIGN_ACCEPT
  -- @field Task#TASK_BASE Task
  -- @field Unit#UNIT ProcessUnit
  -- @field Zone#ZONE_BASE TargetZone
  -- @extends Task2#TASK2
  PROCESS_ASSIGN_ACCEPT = { 
    ClassName = "PROCESS_ASSIGN_ACCEPT",
  }
  
  
  --- Creates a new task assignment state machine. The process will accept the task by default, no player intervention accepted.
  -- @param #PROCESS_ASSIGN_ACCEPT self
  -- @param Task#TASK Task
  -- @param Unit#UNIT Unit
  -- @return #PROCESS_ASSIGN_ACCEPT self
  function PROCESS_ASSIGN_ACCEPT:New( Task, ProcessUnit, TaskBriefing )
  
    -- Inherits from BASE
    local self = BASE:Inherit( self, PROCESS:New( "ASSIGN_ACCEPT", Task, ProcessUnit ) ) -- #PROCESS_ASSIGN_ACCEPT
    
    self.TaskBriefing = TaskBriefing
    
    self.Fsm = STATEMACHINE_PROCESS:New( self, {
      initial = 'UnAssigned',
      events = {
        { name = 'Start',  from = 'UnAssigned',  to = 'Assigned' },
        { name = 'Fail',   from = 'UnAssigned',  to = 'Failed' },
      },
      callbacks = {
        onAssign = self.OnAssign,
      },
      endstates = {
        'Assigned', 'Failed'
      },
    } )
    
    return self
  end
  
  --- StateMachine callback function for a TASK2
  -- @param #PROCESS_ASSIGN_ACCEPT self
  -- @param StateMachine#STATEMACHINE_PROCESS Fsm
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  function PROCESS_ASSIGN_ACCEPT:OnAssigned( Fsm, Event, From, To )
    self:E( { Event, From, To, self.ProcessUnit.UnitName} )
    
  end

end


do -- PROCESS_ASSIGN_MENU_ACCEPT

  --- PROCESS_ASSIGN_MENU_ACCEPT class
  -- @type PROCESS_ASSIGN_MENU_ACCEPT
  -- @field Task#TASK_BASE Task
  -- @field Unit#UNIT ProcessUnit
  -- @field Zone#ZONE_BASE TargetZone
  -- @extends Task2#TASK2
  PROCESS_ASSIGN_MENU_ACCEPT = { 
    ClassName = "PROCESS_ASSIGN_MENU_ACCEPT",
  }
  
  
  --- Creates a new task assignment state machine. The process will request from the menu if it accepts the task, if not, the unit is removed from the simulator.
  -- @param #PROCESS_ASSIGN_MENU_ACCEPT self
  -- @param Task#TASK Task
  -- @param Unit#UNIT Unit
  -- @return #PROCESS_ASSIGN_MENU_ACCEPT self
  function PROCESS_ASSIGN_MENU_ACCEPT:New( Task, ProcessUnit, TaskBriefing )
  
    -- Inherits from BASE
    local self = BASE:Inherit( self, PROCESS:New( "ASSIGN_MENU_ACCEPT", Task, ProcessUnit ) ) -- #PROCESS_ASSIGN_MENU_ACCEPT
    
    self.TaskBriefing = TaskBriefing
    
    self.Fsm = STATEMACHINE_PROCESS:New( self, {
      initial = 'UnAssigned',
      events = {
        { name = 'Start',  from = 'UnAssigned',  to = 'AwaitAccept' },
        { name = 'Assign',  from = 'AwaitAccept',  to = 'Assigned' },
        { name = 'Reject',  from = 'AwaitAccept',  to = 'Rejected' },
        { name = 'Fail',  from = 'AwaitAccept',  to = 'Rejected' },
      },
      callbacks = {
        onStart = self.OnStart,
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
  -- @param #PROCESS_ASSIGN_MENU_ACCEPT self
  -- @param StateMachine#STATEMACHINE_TASK Fsm
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  function PROCESS_ASSIGN_MENU_ACCEPT:OnStart( Fsm, Event, From, To )
    self:E( { Event, From, To, self.ProcessUnit.UnitName} )
  
    MESSAGE:New( self.TaskBriefing .. "\nAccess the radio menu to accept the task. You have 30 seconds or the assignment will be cancelled.", 30, "Assignment" ):ToGroup( self.ProcessUnit:GetGroup() )
    self.MenuText = self.Task.TaskName
   
    local ProcessGroup = self.ProcessUnit:GetGroup() 
    self.Menu = MENU_GROUP:New( ProcessGroup, "Task " .. self.MenuText .. " acceptance" )
    self.MenuAcceptTask = MENU_GROUP_COMMAND:New( ProcessGroup, "Accept task " .. self.MenuText, self.Menu, self.MenuAssign, self )
    self.MenuRejectTask = MENU_GROUP_COMMAND:New( ProcessGroup, "Reject task " .. self.MenuText, self.Menu, self.MenuReject, self )
  end
  
  --- Menu function.
  -- @param #PROCESS_ASSIGN_MENU_ACCEPT self
  function PROCESS_ASSIGN_MENU_ACCEPT:MenuAssign()
    self:E( )
  
    self:NextEvent( self.Fsm.Assign )
  end
  
  --- Menu function.
  -- @param #PROCESS_ASSIGN_MENU_ACCEPT self
  function PROCESS_ASSIGN_MENU_ACCEPT:MenuReject()
    self:E( )
  
    self:NextEvent( self.Fsm.Reject )
  end
  
  --- StateMachine callback function for a TASK2
  -- @param #PROCESS_ASSIGN_MENU_ACCEPT self
  -- @param StateMachine#STATEMACHINE_PROCESS Fsm
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  function PROCESS_ASSIGN_MENU_ACCEPT:OnAssign( Fsm, Event, From, To )
    self:E( { Event, From, To, self.ProcessUnit.UnitName} )
  
    self.Menu:Remove()
  end
  
  --- StateMachine callback function for a TASK2
  -- @param #PROCESS_ASSIGN_MENU_ACCEPT self
  -- @param StateMachine#STATEMACHINE_PROCESS Fsm
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  function PROCESS_ASSIGN_MENU_ACCEPT:OnReject( Fsm, Event, From, To )
    self:E( { Event, From, To, self.ProcessUnit.UnitName} )
  
    self.Menu:Remove()
    self.Task:UnAssignFromUnit( self.ProcessUnit )
    self.ProcessUnit:Destroy()
  end
end
