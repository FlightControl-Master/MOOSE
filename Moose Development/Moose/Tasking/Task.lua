--- **Tasking** -- This module contains the TASK class.
-- 
-- ===
-- 
-- 
-- ===
-- 
-- ### Authors: FlightControl - Design and Programming
-- 
-- @module Task

--- @type TASK
-- @field Core.Scheduler#SCHEDULER TaskScheduler
-- @field Tasking.Mission#MISSION Mission
-- @field Core.Set#SET_GROUP SetGroup The Set of Groups assigned to the Task
-- @field Core.Fsm#FSM_PROCESS FsmTemplate
-- @field Tasking.Mission#MISSION Mission
-- @field Tasking.CommandCenter#COMMANDCENTER CommandCenter
-- @extends Core.Fsm#FSM_TASK

--- 
-- # TASK class, extends @{Base#BASE}
-- 
-- ## The TASK class implements the methods for task orchestration within MOOSE. 
-- 
-- The class provides a couple of methods to:
-- 
--   * @{#TASK.AssignToGroup}():Assign a task to a group (of players).
--   * @{#TASK.AddProcess}():Add a @{Process} to a task.
--   * @{#TASK.RemoveProcesses}():Remove a running @{Process} from a running task.
--   * @{#TASK.SetStateMachine}():Set a @{Fsm} to a task.
--   * @{#TASK.RemoveStateMachine}():Remove @{Fsm} from a task.
--   * @{#TASK.HasStateMachine}():Enquire if the task has a @{Fsm}
--   * @{#TASK.AssignToUnit}(): Assign a task to a unit. (Needs to be implemented in the derived classes from @{#TASK}.
--   * @{#TASK.UnAssignFromUnit}(): Unassign the task from a unit.
--   * @{#TASK.SetTimeOut}(): Set timer in seconds before task gets cancelled if not assigned.
--   
-- ## 1.2) Set and enquire task status (beyond the task state machine processing).
-- 
-- A task needs to implement as a minimum the following task states:
-- 
--   * **Success**: Expresses the successful execution and finalization of the task.
--   * **Failed**: Expresses the failure of a task.
--   * **Planned**: Expresses that the task is created, but not yet in execution and is not assigned yet.
--   * **Assigned**: Expresses that the task is assigned to a Group of players, and that the task is in execution mode.
-- 
-- A task may also implement the following task states:
--
--   * **Rejected**: Expresses that the task is rejected by a player, who was requested to accept the task.
--   * **Cancelled**: Expresses that the task is cancelled by HQ or through a logical situation where a cancellation of the task is required.
--
-- A task can implement more statusses than the ones outlined above. Please consult the documentation of the specific tasks to understand the different status modelled.
--
-- The status of tasks can be set by the methods **State** followed by the task status. An example is `StateAssigned()`.
-- The status of tasks can be enquired by the methods **IsState** followed by the task status name. An example is `if IsStateAssigned() then`.
-- 
-- ## 1.3) Add scoring when reaching a certain task status:
-- 
-- Upon reaching a certain task status in a task, additional scoring can be given. If the Mission has a scoring system attached, the scores will be added to the mission scoring.
-- Use the method @{#TASK.AddScore}() to add scores when a status is reached.
-- 
-- ## 1.4) Task briefing:
-- 
-- A task briefing can be given that is shown to the player when he is assigned to the task.
-- 
-- @field #TASK TASK
-- 
TASK = {
  ClassName = "TASK",
  TaskScheduler = nil,
  ProcessClasses = {}, -- The container of the Process classes that will be used to create and assign new processes for the task to ProcessUnits.
  Processes = {}, -- The container of actual process objects instantiated and assigned to ProcessUnits.
  Players = nil,
  Scores = {},
  Menu = {},
  SetGroup = nil,
  FsmTemplate = nil,
  Mission = nil,
  CommandCenter = nil,
  TimeOut = 0,
  AssignedGroups = {},
}

--- FSM PlayerAborted event handler prototype for TASK.
-- @function [parent=#TASK] OnAfterPlayerAborted
-- @param #TASK self
-- @param Wrapper.Unit#UNIT PlayerUnit The Unit of the Player when he went back to spectators or left the mission.
-- @param #string PlayerName The name of the Player.

--- FSM PlayerCrashed event handler prototype for TASK.
-- @function [parent=#TASK] OnAfterPlayerCrashed
-- @param #TASK self
-- @param Wrapper.Unit#UNIT PlayerUnit The Unit of the Player when he crashed in the mission.
-- @param #string PlayerName The name of the Player.

--- FSM PlayerDead event handler prototype for TASK.
-- @function [parent=#TASK] OnAfterPlayerDead
-- @param #TASK self
-- @param Wrapper.Unit#UNIT PlayerUnit The Unit of the Player when he died in the mission.
-- @param #string PlayerName The name of the Player.

--- FSM Fail synchronous event function for TASK.
-- Use this event to Fail the Task.
-- @function [parent=#TASK] Fail
-- @param #TASK self

--- FSM Fail asynchronous event function for TASK.
-- Use this event to Fail the Task.
-- @function [parent=#TASK] __Fail
-- @param #TASK self

--- FSM Abort synchronous event function for TASK.
-- Use this event to Abort the Task.
-- @function [parent=#TASK] Abort
-- @param #TASK self

--- FSM Abort asynchronous event function for TASK.
-- Use this event to Abort the Task.
-- @function [parent=#TASK] __Abort
-- @param #TASK self

--- FSM Success synchronous event function for TASK.
-- Use this event to make the Task a Success.
-- @function [parent=#TASK] Success
-- @param #TASK self

--- FSM Success asynchronous event function for TASK.
-- Use this event to make the Task a Success.
-- @function [parent=#TASK] __Success
-- @param #TASK self

--- FSM Cancel synchronous event function for TASK.
-- Use this event to Cancel the Task.
-- @function [parent=#TASK] Cancel
-- @param #TASK self

--- FSM Cancel asynchronous event function for TASK.
-- Use this event to Cancel the Task.
-- @function [parent=#TASK] __Cancel
-- @param #TASK self

--- FSM Replan synchronous event function for TASK.
-- Use this event to Replan the Task.
-- @function [parent=#TASK] Replan
-- @param #TASK self

--- FSM Replan asynchronous event function for TASK.
-- Use this event to Replan the Task.
-- @function [parent=#TASK] __Replan
-- @param #TASK self


--- Instantiates a new TASK. Should never be used. Interface Class.
-- @param #TASK self
-- @param Tasking.Mission#MISSION Mission The mission wherein the Task is registered.
-- @param Core.Set#SET_GROUP SetGroupAssign The set of groups for which the Task can be assigned.
-- @param #string TaskName The name of the Task
-- @param #string TaskType The type of the Task
-- @return #TASK self
function TASK:New( Mission, SetGroupAssign, TaskName, TaskType, TaskBriefing )

  local self = BASE:Inherit( self, FSM_TASK:New() ) -- Tasking.Task#TASK

  self:SetStartState( "Planned" )
  self:AddTransition( "Planned", "Assign", "Assigned" )
  self:AddTransition( "Assigned", "AssignUnit", "Assigned" )
  self:AddTransition( "Assigned", "Success", "Success" )
  self:AddTransition( "Assigned", "Hold", "Hold" )
  self:AddTransition( "Assigned", "Fail", "Failed" )
  self:AddTransition( "Assigned", "Abort", "Aborted" )
  self:AddTransition( "Assigned", "Cancel", "Cancelled" )
  self:AddTransition( "*", "PlayerCrashed", "*" )
  self:AddTransition( "*", "PlayerAborted", "*" )
  self:AddTransition( "*", "PlayerDead", "*" )
  self:AddTransition( { "Failed", "Aborted", "Cancelled" }, "Replan", "Planned" )
  self:AddTransition( "*", "TimeOut", "Cancelled" )

  self:E( "New TASK " .. TaskName )

  self.Processes = {}
  self.Fsm = {}

  self.Mission = Mission
  self.CommandCenter = Mission:GetCommandCenter()
  
  self.SetGroup = SetGroupAssign

  self:SetType( TaskType )
  self:SetName( TaskName )
  self:SetID( Mission:GetNextTaskID( self ) ) -- The Mission orchestrates the task sequences ..

  self:SetBriefing( TaskBriefing )
  
  self.FsmTemplate = self.FsmTemplate or FSM_PROCESS:New()
  
  self.TaskInfo = {}
  
  return self
end

--- Get the Task FSM Process Template
-- @param #TASK self
-- @return Core.Fsm#FSM_PROCESS
function TASK:GetUnitProcess( TaskUnit )

  if TaskUnit then
    return self:GetStateMachine( TaskUnit )
  else
    return self.FsmTemplate
  end
end

--- Sets the Task FSM Process Template
-- @param #TASK self
-- @param Core.Fsm#FSM_PROCESS
function TASK:SetUnitProcess( FsmTemplate )

  self.FsmTemplate = FsmTemplate
end

--- Add a PlayerUnit to join the Task.
-- For each Group within the Task, the Unit is checked if it can join the Task.
-- If the Unit was not part of the Task, false is returned.
-- If the Unit is part of the Task, true is returned.
-- @param #TASK self
-- @param Wrapper.Unit#UNIT PlayerUnit The CLIENT or UNIT of the Player joining the Mission.
-- @param Wrapper.Group#GROUP PlayerGroup The GROUP of the player joining the Mission.
-- @return #boolean true if Unit is part of the Task.
function TASK:JoinUnit( PlayerUnit, PlayerGroup )
  self:F( { PlayerUnit = PlayerUnit, PlayerGroup = PlayerGroup } )
  
  local PlayerUnitAdded = false
  
  local PlayerGroups = self:GetGroups()

  -- Is the PlayerGroup part of the PlayerGroups?  
  if PlayerGroups:IsIncludeObject( PlayerGroup ) then
  
    -- Check if the PlayerGroup is already assigned to the Task. If yes, the PlayerGroup is added to the Task.
    -- If the PlayerGroup is not assigned to the Task, the menu needs to be set. In that case, the PlayerUnit will become the GroupPlayer leader.
    if self:IsStatePlanned() or self:IsStateReplanned() then
      self:SetMenuForGroup( PlayerGroup )
      --self:MessageToGroups( PlayerUnit:GetPlayerName() .. " is planning to join Task " .. self:GetName() )
    end
    if self:IsStateAssigned() then
      local IsGroupAssigned = self:IsGroupAssigned( PlayerGroup )
      self:E( { IsGroupAssigned = IsGroupAssigned } )
      if IsGroupAssigned then
        self:AssignToUnit( PlayerUnit )
        self:MessageToGroups( PlayerUnit:GetPlayerName() .. " joined Task " .. self:GetName() )
      end
    end
  end
  
  return PlayerUnitAdded
end

--- Abort a PlayerUnit from a Task.
-- If the Unit was not part of the Task, false is returned.
-- If the Unit is part of the Task, true is returned.
-- @param #TASK self
-- @param Wrapper.Unit#UNIT PlayerUnit The CLIENT or UNIT of the Player aborting the Task.
-- @return #TASK
function TASK:AbortGroup( PlayerGroup )
  self:F( { PlayerGroup = PlayerGroup } )
  
  local PlayerGroups = self:GetGroups()

  -- Is the PlayerGroup part of the PlayerGroups?  
  if PlayerGroups:IsIncludeObject( PlayerGroup ) then
  
    -- Check if the PlayerGroup is already assigned to the Task. If yes, the PlayerGroup is aborted from the Task.
    -- If the PlayerUnit was the last unit of the PlayerGroup, the menu needs to be removed from the Group.
    if self:IsStateAssigned() then
      local IsGroupAssigned = self:IsGroupAssigned( PlayerGroup )
      self:E( { IsGroupAssigned = IsGroupAssigned } )
      if IsGroupAssigned then
        local PlayerName = PlayerGroup:GetUnit(1):GetPlayerName()
        self:MessageToGroups( PlayerName .. " aborted Task " .. self:GetName() )
        self:UnAssignFromGroup( PlayerGroup )
        --self:Abort()

        -- Now check if the task needs to go to hold...
        -- It will go to hold, if there are no players in the mission...
        
        PlayerGroups:Flush()
        local IsRemaining = false
        for GroupName, AssignedGroup in pairs( PlayerGroups:GetSet() or {} ) do
          if self:IsGroupAssigned( AssignedGroup ) == true then
            IsRemaining = true
            self:F( { Task = self:GetName(), IsRemaining = IsRemaining } )
           break
          end
        end

        self:F( { Task = self:GetName(), IsRemaining = IsRemaining } )
        if IsRemaining == false then
          self:Abort()
        end
        
        self:PlayerAborted( PlayerGroup:GetUnit(1) )
      end
      
    end
  end
  
  return self
end

--- A PlayerUnit crashed in a Task. Abort the Player.
-- If the Unit was not part of the Task, false is returned.
-- If the Unit is part of the Task, true is returned.
-- @param #TASK self
-- @param Wrapper.Unit#UNIT PlayerUnit The CLIENT or UNIT of the Player aborting the Task.
-- @return #TASK
function TASK:CrashGroup( PlayerGroup )
  self:F( { PlayerGroup = PlayerGroup } )
  
  local PlayerGroups = self:GetGroups()

  -- Is the PlayerGroup part of the PlayerGroups?  
  if PlayerGroups:IsIncludeObject( PlayerGroup ) then
  
    -- Check if the PlayerGroup is already assigned to the Task. If yes, the PlayerGroup is aborted from the Task.
    -- If the PlayerUnit was the last unit of the PlayerGroup, the menu needs to be removed from the Group.
    if self:IsStateAssigned() then
      local IsGroupAssigned = self:IsGroupAssigned( PlayerGroup )
      self:E( { IsGroupAssigned = IsGroupAssigned } )
      if IsGroupAssigned then
        local PlayerName = PlayerGroup:GetUnit(1):GetPlayerName()
        self:MessageToGroups( PlayerName .. " crashed! " )
        self:UnAssignFromGroup( PlayerGroup )

        -- Now check if the task needs to go to hold...
        -- It will go to hold, if there are no players in the mission...
        
        PlayerGroups:Flush()
        local IsRemaining = false
        for GroupName, AssignedGroup in pairs( PlayerGroups:GetSet() or {} ) do
          if self:IsGroupAssigned( AssignedGroup ) == true then
            IsRemaining = true
            self:F( { Task = self:GetName(), IsRemaining = IsRemaining } )
           break
          end
        end

        self:F( { Task = self:GetName(), IsRemaining = IsRemaining } )
        if IsRemaining == false then
          self:Abort()
        end
        
        self:PlayerCrashed( PlayerGroup:GetUnit(1) )
      end
      
    end
  end
  
  return self
end



--- Gets the Mission to where the TASK belongs.
-- @param #TASK self
-- @return Tasking.Mission#MISSION
function TASK:GetMission()

  return self.Mission
end


--- Gets the SET_GROUP assigned to the TASK.
-- @param #TASK self
-- @return Core.Set#SET_GROUP
function TASK:GetGroups()
  return self.SetGroup
end

do -- Group Assignment

  --- Returns if the @{Task} is assigned to the Group.
  -- @param #TASK self
  -- @param Wrapper.Group#GROUP TaskGroup
  -- @return #boolean
  function TASK:IsGroupAssigned( TaskGroup )
  
    local TaskGroupName = TaskGroup:GetName()
    
    if self.AssignedGroups[TaskGroupName] then
      self:T( { "Task is assigned to:", TaskGroup:GetName() } )
      return true
    end
    
    self:T( { "Task is not assigned to:", TaskGroup:GetName() } )
    return false
  end
  
  
  --- Set @{Group} assigned to the @{Task}.
  -- @param #TASK self
  -- @param Wrapper.Group#GROUP TaskGroup
  -- @return #TASK
  function TASK:SetGroupAssigned( TaskGroup )
  
    local TaskName = self:GetName()
    local TaskGroupName = TaskGroup:GetName()
  
    self.AssignedGroups[TaskGroupName] = TaskGroup
    self:E( string.format( "Task %s is assigned to %s", TaskName, TaskGroupName ) )
    
    -- Set the group to be assigned at mission level. This allows to decide the menu options on mission level for this group.
    self:GetMission():SetGroupAssigned( TaskGroup )
    
    local SetAssignedGroups = self:GetGroups()
    
--    SetAssignedGroups:ForEachGroup(
--      function( AssignedGroup )
--        if self:IsGroupAssigned(AssignedGroup) then
--          self:GetMission():GetCommandCenter():MessageToGroup( string.format( "Task %s is assigned to group %s.", TaskName, TaskGroupName ), AssignedGroup )
--        else
--          self:GetMission():GetCommandCenter():MessageToGroup( string.format( "Task %s is assigned to your group.", TaskName ), AssignedGroup )
--        end
--      end
--    )
    
    return self
  end
  
  --- Clear the @{Group} assignment from the @{Task}.
  -- @param #TASK self
  -- @param Wrapper.Group#GROUP TaskGroup
  -- @return #TASK
  function TASK:ClearGroupAssignment( TaskGroup )
  
    local TaskName = self:GetName()
    local TaskGroupName = TaskGroup:GetName()
  
    self.AssignedGroups[TaskGroupName] = nil
    self:E( string.format( "Task %s is unassigned to %s", TaskName, TaskGroupName ) )

    -- Set the group to be assigned at mission level. This allows to decide the menu options on mission level for this group.
    self:GetMission():ClearGroupAssignment( TaskGroup )
    
    local SetAssignedGroups = self:GetGroups()

    SetAssignedGroups:ForEachGroup(
      function( AssignedGroup )
        if self:IsGroupAssigned(AssignedGroup) then
          self:GetMission():GetCommandCenter():MessageToGroup( string.format( "Task %s is unassigned from group %s.", TaskName, TaskGroupName ), AssignedGroup )
        else
          self:GetMission():GetCommandCenter():MessageToGroup( string.format( "Task %s is unassigned from your group.", TaskName ), AssignedGroup )
        end
      end
    )
    
    return self
  end
  
end

do -- Group Assignment

  --- Assign the @{Task} to a @{Group}.
  -- @param #TASK self
  -- @param Wrapper.Group#GROUP TaskGroup
  -- @return #TASK
  function TASK:AssignToGroup( TaskGroup )
    self:F( TaskGroup:GetName() )
    
    local TaskGroupName = TaskGroup:GetName()
    local Mission = self:GetMission()
    local CommandCenter = Mission:GetCommandCenter()
    
    self:SetGroupAssigned( TaskGroup )
    
    local TaskUnits = TaskGroup:GetUnits()
    for UnitID, UnitData in pairs( TaskUnits ) do
      local TaskUnit = UnitData -- Wrapper.Unit#UNIT
      local PlayerName = TaskUnit:GetPlayerName()
      self:E(PlayerName)
      if PlayerName ~= nil or PlayerName ~= "" then
        self:AssignToUnit( TaskUnit )
        CommandCenter:MessageToGroup( 
          string.format( 'Task "%s": Briefing for player (%s):\n%s', 
            self:GetName(), 
            PlayerName, 
            self:GetBriefing()
          ), TaskGroup 
        )
      end
    end

    CommandCenter:SetMenu()
    
    return self
  end
  
  --- UnAssign the @{Task} from a @{Group}.
  -- @param #TASK self
  function TASK:UnAssignFromGroup( TaskGroup )
    self:F2( { TaskGroup } )
    
    self:ClearGroupAssignment( TaskGroup )
  
    local TaskUnits = TaskGroup:GetUnits()
    for UnitID, UnitData in pairs( TaskUnits ) do
      local TaskUnit = UnitData -- Wrapper.Unit#UNIT
      local PlayerName = TaskUnit:GetPlayerName()
      if PlayerName ~= nil or PlayerName ~= "" then
        self:UnAssignFromUnit( TaskUnit )
      end
    end

    local Mission = self:GetMission()
    local CommandCenter = Mission:GetCommandCenter()
    CommandCenter:SetMenu()
  end
end


---
-- @param #TASK self
-- @param Wrapper.Group#GROUP FindGroup
-- @return #boolean
function TASK:HasGroup( FindGroup )

  local SetAttackGroup = self:GetGroups()
  return SetAttackGroup:FindGroup(FindGroup)

end

--- Assign the @{Task} to an alive @{Unit}.
-- @param #TASK self
-- @param Wrapper.Unit#UNIT TaskUnit
-- @return #TASK self
function TASK:AssignToUnit( TaskUnit )
  self:F( TaskUnit:GetName() )
  
  local FsmTemplate = self:GetUnitProcess()
  
  -- Assign a new FsmUnit to TaskUnit.
  local FsmUnit = self:SetStateMachine( TaskUnit, FsmTemplate:Copy( TaskUnit, self ) ) -- Core.Fsm#FSM_PROCESS
  self:E({"Address FsmUnit", tostring( FsmUnit ) } )
  
  FsmUnit:SetStartState( "Planned" )
  
  FsmUnit:Accept() -- Each Task needs to start with an Accept event to start the flow.

  return self
end

--- UnAssign the @{Task} from an alive @{Unit}.
-- @param #TASK self
-- @param Wrapper.Unit#UNIT TaskUnit
-- @return #TASK self
function TASK:UnAssignFromUnit( TaskUnit )
  self:F( TaskUnit:GetName() )
  
  self:RemoveStateMachine( TaskUnit )

  return self
end

--- Sets the TimeOut for the @{Task}. If @{Task} stayed planned for longer than TimeOut, it gets into Cancelled status.
-- @param #TASK self
-- @param #integer Timer in seconds
-- @return #TASK self
function TASK:SetTimeOut ( Timer )
  self:F( Timer )
  self.TimeOut = Timer
  self:__TimeOut( self.TimeOut )
  return self
end

--- Send a message of the @{Task} to the assigned @{Group}s.
-- @param #TASK self
function TASK:MessageToGroups( Message )
  self:F( { Message = Message } )

  local Mission = self:GetMission()
  local CC = Mission:GetCommandCenter()
  
  for TaskGroupName, TaskGroup in pairs( self.SetGroup:GetSet() ) do
    local TaskGroup = TaskGroup -- Wrapper.Group#GROUP
    CC:MessageToGroup( Message, TaskGroup, TaskGroup:GetName() )
  end
end


--- Send the briefng message of the @{Task} to the assigned @{Group}s.
-- @param #TASK self
function TASK:SendBriefingToAssignedGroups()
  self:F2()
  
  for TaskGroupName, TaskGroup in pairs( self.SetGroup:GetSet() ) do

    if self:IsGroupAssigned( TaskGroup ) then    
      TaskGroup:Message( self.TaskBriefing, 60 )
    end
  end
end


--- UnAssign the @{Task} from the @{Group}s.
-- @param #TASK self
function TASK:UnAssignFromGroups()
  self:F2()
  
  for TaskGroupName, TaskGroup in pairs( self.SetGroup:GetSet() ) do
    if self:IsGroupAssigned(TaskGroup) then
      self:UnAssignFromGroup( TaskGroup )
    end
  end
end



--- Returns if the @{Task} has still alive and assigned Units.
-- @param #TASK self
-- @return #boolean
function TASK:HasAliveUnits()
  self:F()
  
  for TaskGroupID, TaskGroup in pairs( self.SetGroup:GetSet() ) do
    if self:IsStateAssigned() then
      if self:IsGroupAssigned( TaskGroup ) then
        for TaskUnitID, TaskUnit in pairs( TaskGroup:GetUnits() ) do
          if TaskUnit:IsAlive() then
            self:T( { HasAliveUnits = true } )
            return true
          end
        end
      end
    end
  end
  
  self:T( { HasAliveUnits = false } )
  return false
end

--- Set the menu options of the @{Task} to all the groups in the SetGroup.
-- @param #TASK self
-- @param #number MenuTime
-- @return #TASK
function TASK:SetMenu( MenuTime ) --R2.1 Mission Reports and Task Reports added. Fixes issue #424.
  self:F( { self:GetName(), MenuTime } )

  --self.SetGroup:Flush()
  for TaskGroupID, TaskGroupData in pairs( self.SetGroup:GetSet() ) do
    local TaskGroup = TaskGroupData -- Wrapper.Group#GROUP
    if TaskGroup:IsAlive() and TaskGroup:GetPlayerNames() then
    
      -- Set Mission Menus
      
      local Mission = self:GetMission()
      local MissionMenu = Mission:GetMenu( TaskGroup )
      if MissionMenu then
        self:SetMenuForGroup( TaskGroup, MenuTime )
      end
    end
  end  
end



--- Set the Menu for a Group
-- @param #TASK self
-- @param #number MenuTime
-- @return #TASK
function TASK:SetMenuForGroup( TaskGroup, MenuTime )

  self:SetPlannedMenuForGroup( TaskGroup, MenuTime )
  if self:IsGroupAssigned( TaskGroup ) then
    self:SetAssignedMenuForGroup( TaskGroup, MenuTime )
  end
end


--- Set the planned menu option of the @{Task}.
-- @param #TASK self
-- @param Wrapper.Group#GROUP TaskGroup
-- @param #string MenuText The menu text.
-- @param #number MenuTime
-- @return #TASK self
function TASK:SetPlannedMenuForGroup( TaskGroup, MenuTime )
  self:F( TaskGroup:GetName() )

  local Mission = self:GetMission()
  local MissionName = Mission:GetName()
  local CommandCenter = Mission:GetCommandCenter()
  local CommandCenterMenu = CommandCenter:GetMenu()

  local TaskType = self:GetType()
--  local TaskThreatLevel = self.TaskInfo["ThreatLevel"]
--  local TaskThreatLevelString = TaskThreatLevel and " [" .. string.rep( "■", TaskThreatLevel ) .. "]" or " []" 
  local TaskPlayerCount = self:GetPlayerCount()
  local TaskPlayerString = string.format( " (%dp)", TaskPlayerCount )
  local TaskText = string.format( "%s%s", self:GetName(), TaskPlayerString ) --, TaskThreatLevelString )
  local TaskName = string.format( "%s", self:GetName() )

  local MissionMenu = Mission:GetMenu( TaskGroup )
  --local MissionMenu = MENU_GROUP:New( TaskGroup, MissionName, CommandCenterMenu ):SetTime( MenuTime )
  
  --local MissionMenu = Mission:GetMenu( TaskGroup )

  local TaskPlannedMenu = MENU_GROUP:New( TaskGroup, "Planned Tasks", MissionMenu ):SetTime( MenuTime )
  local TaskTypeMenu = MENU_GROUP:New( TaskGroup, TaskType, TaskPlannedMenu ):SetTime( MenuTime ):SetRemoveParent( true )
  local TaskTypeMenu = MENU_GROUP:New( TaskGroup, TaskText, TaskTypeMenu ):SetTime( MenuTime ):SetRemoveParent( true )
  local ReportTaskMenu = MENU_GROUP_COMMAND:New( TaskGroup, string.format( "Report Task Status" ), TaskTypeMenu, self.MenuTaskStatus, self, TaskGroup ):SetTime( MenuTime ):SetRemoveParent( true )
  
  if not Mission:IsGroupAssigned( TaskGroup ) then
    local JoinTaskMenu = MENU_GROUP_COMMAND:New( TaskGroup, string.format( "Join Task" ), TaskTypeMenu, self.MenuAssignToGroup, { self = self, TaskGroup = TaskGroup } ):SetTime( MenuTime ):SetRemoveParent( true )
  end
      
  return self
end

--- Set the assigned menu options of the @{Task}.
-- @param #TASK self
-- @param Wrapper.Group#GROUP TaskGroup
-- @param #number MenuTime
-- @return #TASK self
function TASK:SetAssignedMenuForGroup( TaskGroup, MenuTime )
  self:F( { TaskGroup:GetName(), MenuTime } )

  local Mission = self:GetMission()
  local MissionName = Mission:GetName()
  local CommandCenter = Mission:GetCommandCenter()
  local CommandCenterMenu = CommandCenter:GetMenu()

  local TaskType = self:GetType()
--  local TaskThreatLevel = self.TaskInfo["ThreatLevel"]
--  local TaskThreatLevelString = TaskThreatLevel and " [" .. string.rep( "■", TaskThreatLevel ) .. "]" or " []" 
  local TaskPlayerCount = self:GetPlayerCount()
  local TaskPlayerString = string.format( " (%dp)", TaskPlayerCount )
  local TaskText = string.format( "%s%s", self:GetName(), TaskPlayerString ) --, TaskThreatLevelString )
  local TaskName = string.format( "%s", self:GetName() )

  local MissionMenu = Mission:GetMenu( TaskGroup )
--  local MissionMenu = MENU_GROUP:New( TaskGroup, MissionName, CommandCenterMenu ):SetTime( MenuTime )
--  local MissionMenu = Mission:GetMenu( TaskGroup )

  local TaskAssignedMenu = MENU_GROUP:New( TaskGroup, string.format( "Assigned Task %s", TaskName ), MissionMenu ):SetTime( MenuTime )
  local TaskTypeMenu = MENU_GROUP_COMMAND:New( TaskGroup, string.format( "Report Task Status" ), TaskAssignedMenu, self.MenuTaskStatus, self, TaskGroup ):SetTime( MenuTime ):SetRemoveParent( true )
  local TaskMenu = MENU_GROUP_COMMAND:New( TaskGroup, string.format( "Abort Group from Task" ), TaskAssignedMenu, self.MenuTaskAbort, self, TaskGroup ):SetTime( MenuTime ):SetRemoveParent( true )

  return self
end

--- Remove the menu options of the @{Task} to all the groups in the SetGroup.
-- @param #TASK self
-- @param #number MenuTime
-- @return #TASK
function TASK:RemoveMenu( MenuTime )
  self:F( { self:GetName(), MenuTime } )

  for TaskGroupID, TaskGroup in pairs( self.SetGroup:GetSet() ) do
    local TaskGroup = TaskGroup -- Wrapper.Group#GROUP 
    if TaskGroup:IsAlive() and TaskGroup:GetPlayerNames() then
      self:RefreshMenus( TaskGroup, MenuTime )
    end
  end
end


--- Remove the menu option of the @{Task} for a @{Group}.
-- @param #TASK self
-- @param Wrapper.Group#GROUP TaskGroup
-- @param #number MenuTime
-- @return #TASK self
function TASK:RefreshMenus( TaskGroup, MenuTime )
  self:F( { TaskGroup:GetName(), MenuTime } )

  local Mission = self:GetMission()
  local MissionName = Mission:GetName()
  local CommandCenter = Mission:GetCommandCenter()
  local CommandCenterMenu = CommandCenter:GetMenu()

  local MissionMenu = Mission:GetMenu( TaskGroup )

  local TaskName = self:GetName()
  local PlannedMenu = MissionMenu:GetMenu( "Planned Tasks" )
  local AssignedMenu = MissionMenu:GetMenu( string.format( "Assigned Task %s", TaskName ) )
  
  if PlannedMenu then
    PlannedMenu:Remove( MenuTime )
  end
  
  if AssignedMenu then
    AssignedMenu:Remove( MenuTime )
  end
  
end

--- Remove the assigned menu option of the @{Task} for a @{Group}.
-- @param #TASK self
-- @param Wrapper.Group#GROUP TaskGroup
-- @param #number MenuTime
-- @return #TASK self
function TASK:RemoveAssignedMenuForGroup( TaskGroup )
  self:F()

  local Mission = self:GetMission()
  local MissionName = Mission:GetName()
  
  local MissionMenu = Mission:GetMenu( TaskGroup )
  
  if MissionMenu then
    MissionMenu:RemoveSubMenus()
  end
  
end

function TASK.MenuAssignToGroup( MenuParam )

  local self = MenuParam.self
  local TaskGroup = MenuParam.TaskGroup
  
  self:E( "Assigned menu selected")
  
  self:AssignToGroup( TaskGroup )
end

--- Report the task status.
-- @param #TASK self
function TASK:MenuTaskStatus( TaskGroup )

  local ReportText = self:ReportDetails( TaskGroup )
  
  self:T( ReportText )
  self:GetMission():GetCommandCenter():MessageToGroup( ReportText, TaskGroup )

end

--- Report the task status.
-- @param #TASK self
function TASK:MenuTaskAbort( TaskGroup )

  self:AbortGroup( TaskGroup )
end



--- Returns the @{Task} name.
-- @param #TASK self
-- @return #string TaskName
function TASK:GetTaskName()
  return self.TaskName
end

--- Returns the @{Task} briefing.
-- @param #TASK self
-- @return #string Task briefing.
function TASK:GetTaskBriefing()
  return self.TaskBriefing
end




--- Get the default or currently assigned @{Process} template with key ProcessName.
-- @param #TASK self
-- @param #string ProcessName
-- @return Core.Fsm#FSM_PROCESS
function TASK:GetProcessTemplate( ProcessName )

  local ProcessTemplate = self.ProcessClasses[ProcessName]
  
  return ProcessTemplate
end



-- TODO: Obscolete?
--- Fail processes from @{Task} with key @{Unit}
-- @param #TASK self
-- @param #string TaskUnitName
-- @return #TASK self
function TASK:FailProcesses( TaskUnitName )

  for ProcessID, ProcessData in pairs( self.Processes[TaskUnitName] ) do
    local Process = ProcessData 
    Process.Fsm:Fail()
  end
end

--- Add a FiniteStateMachine to @{Task} with key Task@{Unit}
-- @param #TASK self
-- @param Wrapper.Unit#UNIT TaskUnit
-- @param Core.Fsm#FSM_PROCESS Fsm
-- @return #TASK self
function TASK:SetStateMachine( TaskUnit, Fsm )
  self:F2( { TaskUnit, self.Fsm[TaskUnit] ~= nil, Fsm:GetClassNameAndID() } )

  self.Fsm[TaskUnit] = Fsm
    
  return Fsm
end

--- Gets the FiniteStateMachine of @{Task} with key Task@{Unit}
-- @param #TASK self
-- @param Wrapper.Unit#UNIT TaskUnit
-- @return Core.Fsm#FSM_PROCESS
function TASK:GetStateMachine( TaskUnit )
  self:F2( { TaskUnit, self.Fsm[TaskUnit] ~= nil } )

  return self.Fsm[TaskUnit]
end

--- Remove FiniteStateMachines from @{Task} with key Task@{Unit}
-- @param #TASK self
-- @param Wrapper.Unit#UNIT TaskUnit
-- @return #TASK self
function TASK:RemoveStateMachine( TaskUnit )
  self:F( { TaskUnit, self.Fsm[TaskUnit] ~= nil } )

  --self:E( self.Fsm )
  --for TaskUnitT, Fsm in pairs( self.Fsm ) do
    --local Fsm = Fsm -- Core.Fsm#FSM_PROCESS
    --self:E( TaskUnitT )
    --self.Fsm[TaskUnit] = nil
  --end

  self.Fsm[TaskUnit]:Remove()
  self.Fsm[TaskUnit] = nil
  
  collectgarbage()
  self:E( "Garbage Collected, Processes should be finalized now ...")
end

--- Checks if there is a FiniteStateMachine assigned to Task@{Unit} for @{Task}
-- @param #TASK self
-- @param Wrapper.Unit#UNIT TaskUnit
-- @return #TASK self
function TASK:HasStateMachine( TaskUnit )
  self:F( { TaskUnit, self.Fsm[TaskUnit] ~= nil } )

  return ( self.Fsm[TaskUnit] ~= nil )
end


--- Gets the Scoring of the task
-- @param #TASK self
-- @return Functional.Scoring#SCORING Scoring
function TASK:GetScoring()
  return self.Mission:GetScoring()
end


--- Gets the Task Index, which is a combination of the Task type, the Task name.
-- @param #TASK self
-- @return #string The Task ID
function TASK:GetTaskIndex()

  local TaskType = self:GetType()
  local TaskName = self:GetName()

  return TaskType .. "." .. TaskName
end

--- Sets the Name of the Task
-- @param #TASK self
-- @param #string TaskName
function TASK:SetName( TaskName )
  self.TaskName = TaskName
end

--- Gets the Name of the Task
-- @param #TASK self
-- @return #string The Task Name
function TASK:GetName()
  return self.TaskName
end

--- Sets the Type of the Task
-- @param #TASK self
-- @param #string TaskType
function TASK:SetType( TaskType )
  self.TaskType = TaskType
end

--- Sets the Information on the Task
-- @param #TASK self
-- @param #string TaskInfo
function TASK:SetInfo( TaskInfo, TaskInfoText )

  self.TaskInfo[TaskInfo] = TaskInfoText
end

--- Gets the Type of the Task
-- @param #TASK self
-- @return #string TaskType
function TASK:GetType()
  return self.TaskType
end

--- Sets the ID of the Task
-- @param #TASK self
-- @param #string TaskID
function TASK:SetID( TaskID )
  self.TaskID = TaskID
end

--- Gets the ID of the Task
-- @param #TASK self
-- @return #string TaskID
function TASK:GetID()
  return self.TaskID
end


--- Sets a @{Task} to status **Success**.
-- @param #TASK self
function TASK:StateSuccess()
  self:SetState( self, "State", "Success" )
  return self
end

--- Is the @{Task} status **Success**.
-- @param #TASK self
function TASK:IsStateSuccess()
  return self:Is( "Success" )
end

--- Sets a @{Task} to status **Failed**.
-- @param #TASK self
function TASK:StateFailed()
  self:SetState( self, "State", "Failed" )
  return self
end

--- Is the @{Task} status **Failed**.
-- @param #TASK self
function TASK:IsStateFailed()
  return self:Is( "Failed" )
end

--- Sets a @{Task} to status **Planned**.
-- @param #TASK self
function TASK:StatePlanned()
  self:SetState( self, "State", "Planned" )
  return self
end

--- Is the @{Task} status **Planned**.
-- @param #TASK self
function TASK:IsStatePlanned()
  return self:Is( "Planned" )
end

--- Sets a @{Task} to status **Aborted**.
-- @param #TASK self
function TASK:StateAborted()
  self:SetState( self, "State", "Aborted" )
  return self
end

--- Is the @{Task} status **Aborted**.
-- @param #TASK self
function TASK:IsStateAborted()
  return self:Is( "Aborted" )
end

--- Sets a @{Task} to status **Cancelled**.
-- @param #TASK self
function TASK:StateCancelled()
  self:SetState( self, "State", "Cancelled" )
  return self
end

--- Is the @{Task} status **Cancelled**.
-- @param #TASK self
function TASK:IsStateCancelled()
  return self:Is( "Cancelled" )
end

--- Sets a @{Task} to status **Assigned**.
-- @param #TASK self
function TASK:StateAssigned()
  self:SetState( self, "State", "Assigned" )
  return self
end

--- Is the @{Task} status **Assigned**.
-- @param #TASK self
function TASK:IsStateAssigned()
  return self:Is( "Assigned" )
end

--- Sets a @{Task} to status **Hold**.
-- @param #TASK self
function TASK:StateHold()
  self:SetState( self, "State", "Hold" )
  return self
end

--- Is the @{Task} status **Hold**.
-- @param #TASK self
function TASK:IsStateHold()
  return self:Is( "Hold" )
end

--- Sets a @{Task} to status **Replanned**.
-- @param #TASK self
function TASK:StateReplanned()
  self:SetState( self, "State", "Replanned" )
  return self
end

--- Is the @{Task} status **Replanned**.
-- @param #TASK self
function TASK:IsStateReplanned()
  return self:Is( "Replanned" )
end

--- Gets the @{Task} status.
-- @param #TASK self
function TASK:GetStateString()
  return self:GetState( self, "State" )
end

--- Sets a @{Task} briefing.
-- @param #TASK self
-- @param #string TaskBriefing
-- @return #TASK self
function TASK:SetBriefing( TaskBriefing )
  self:E(TaskBriefing)
  self.TaskBriefing = TaskBriefing
  return self
end

--- Gets the @{Task} briefing.
-- @param #TASK self
-- @return #string The briefing text.
function TASK:GetBriefing()
  return self.TaskBriefing
end




--- FSM function for a TASK
-- @param #TASK self
-- @param #string Event
-- @param #string From
-- @param #string To
function TASK:onenterAssigned( From, Event, To, PlayerUnit, PlayerName )

  self:E( { "Task Assigned", self.Dispatcher } )
  
  if From ~= "Assigned" then
    self:GetMission():GetCommandCenter():MessageToCoalition( "Task " .. self:GetName() .. " is assigned." )
    if self.Dispatcher then
      self:E( "Firing Assign event " )
      self.Dispatcher:Assign( self, PlayerUnit, PlayerName )
    end
    
    self:GetMission():__Start( 1 )
    
    self:SetMenu()
  end
end


--- FSM function for a TASK
-- @param #TASK self
-- @param #string Event
-- @param #string From
-- @param #string To
function TASK:onenterSuccess( From, Event, To )

  self:E( "Task Success" )
  
  self:GetMission():GetCommandCenter():MessageToCoalition( "Task " .. self:GetName() .. " is successful! Good job!" )
  self:UnAssignFromGroups()
  
  --self:GetMission():__Complete( 1 )
  
end


--- FSM function for a TASK
-- @param #TASK self
-- @param #string From
-- @param #string Event
-- @param #string To
function TASK:onenterAborted( From, Event, To )

  self:E( "Task Aborted" )
  
  if From ~= "Aborted" then
    self:GetMission():GetCommandCenter():MessageToCoalition( "Task " .. self:GetName() .. " has been aborted! Task may be replanned." )
    self:__Replan( 5 )
    self:SetMenu()
  end
  
end

--- FSM function for a TASK
-- @param #TASK self
-- @param #string From
-- @param #string Event
-- @param #string To
function TASK:onafterReplan( From, Event, To )

  self:E( "Task Replanned" )
  
  self:GetMission():GetCommandCenter():MessageToCoalition( "Replanning Task " .. self:GetName() .. "." )
  
  self:SetMenu()
  
end

--- FSM function for a TASK
-- @param #TASK self
-- @param #string From
-- @param #string Event
-- @param #string To
function TASK:onenterFailed( From, Event, To )

  self:E( "Task Failed" )

  self:GetMission():GetCommandCenter():MessageToCoalition( "Task " .. self:GetName() .. " has failed!" )
  
  self:UnAssignFromGroups()
end

--- FSM function for a TASK
-- @param #TASK self
-- @param #string Event
-- @param #string From
-- @param #string To
function TASK:onstatechange( From, Event, To )

  if self:IsTrace() then
    --MESSAGE:New( "@ Task " .. self.TaskName .. " : " .. From .. " changed to " .. To .. " by " .. Event, 2 ):ToAll()
  end

  if self.Scores[To] then
    local Scoring = self:GetScoring()
    if Scoring then
      self:E( { self.Scores[To].ScoreText, self.Scores[To].Score } )
      Scoring:_AddMissionScore( self.Mission, self.Scores[To].ScoreText, self.Scores[To].Score )
    end
  end

end

--- FSM function for a TASK
-- @param #TASK self
-- @param #string Event
-- @param #string From
-- @param #string To
function TASK:onenterPlanned( From, Event, To)
  if not self.TimeOut == 0 then 
    self.__TimeOut( self.TimeOut )
  end
end

--- FSM function for a TASK
-- @param #TASK self
-- @param #string Event
-- @param #string From
-- @param #string To
function TASK:onbeforeTimeOut( From, Event, To )
  if From == "Planned" then
    self:RemoveMenu()
    return true
  end
  return false
end

do -- Dispatcher

  --- Set dispatcher of a task
  -- @param #TASK self
  -- @param Tasking.DetectionManager#DETECTION_MANAGER Dispatcher
  -- @return #TASK
  function TASK:SetDispatcher( Dispatcher )
    self.Dispatcher = Dispatcher
  end

end

do -- Reporting

--- Create a summary report of the Task.
-- List the Task Name and Status
-- @param #TASK self
-- @return #string
function TASK:ReportSummary() --R2.1 fixed report. Now nicely formatted and contains the info required.

  local Report = REPORT:New()
  
  -- List the name of the Task.
  local Name = self:GetName()
  
  -- Determine the status of the Task.
  local State = self:GetState()
  
  Report:Add( "Task " .. Name .. " - State '" .. State )

  return Report:Text()
end

--- Create an overiew report of the Task.
-- List the Task Name and Status
-- @param #TASK self
-- @return #string
function TASK:ReportOverview( ReportGroup ) --R2.1 fixed report. Now nicely formatted and contains the info required.

  
  -- List the name of the Task.
  local Name = self:GetName()
  local Report = REPORT:New( "Task " .. Name )
  
  -- Determine the status of the Task.
  local State = self:GetState()
  
  for TaskInfoID, TaskInfo in pairs( self.TaskInfo ) do

    local TaskInfoIDText = string.format( " - %s: ", TaskInfoID )
  
    if type(TaskInfo) == "string" then
      Report:Add( TaskInfoIDText .. TaskInfo )
    elseif type(TaskInfo) == "table" then
      if TaskInfoID == "Coordinates" then
        local FromCoordinate = ReportGroup:GetUnit(1):GetCoordinate()
        local ToCoordinate = TaskInfo -- Core.Point#COORDINATE
        Report:Add( TaskInfoIDText )
        Report:AddIndent( ToCoordinate:ToStringBRA( FromCoordinate ) .. ", " .. TaskInfo:ToStringAspect( FromCoordinate ) )
        --Report:AddIndent( ToCoordinate:ToStringBULLS( ReportGroup:GetCoalition() ) )
      else
      end
    end
  end
  
  return Report:Text( ", ")
end

--- Create a count of the players in the Task.
-- @param #TASK self
-- @return #number The total number of players in the task.
function TASK:GetPlayerCount() --R2.1 Get a count of the players.

  local PlayerCount = 0

  -- Loop each Unit active in the Task, and find Player Names.
  for TaskGroupID, PlayerGroup in pairs( self:GetGroups():GetSet() ) do
    local PlayerGroup = PlayerGroup -- Wrapper.Group#GROUP
    if self:IsGroupAssigned( PlayerGroup ) then
      local PlayerNames = PlayerGroup:GetPlayerNames()
        PlayerCount = PlayerCount + #PlayerNames
    end
  end

  return PlayerCount
end


--- Create a list of the players in the Task.
-- @param #TASK self
-- @return #map<#string,Wrapper.Group#GROUP> A map of the players
function TASK:GetPlayerNames() --R2.1 Get a map of the players.

  local PlayerNameMap = {}

  -- Loop each Unit active in the Task, and find Player Names.
  for TaskGroupID, PlayerGroup in pairs( self:GetGroups():GetSet() ) do
    local PlayerGroup = PlayerGroup -- Wrapper.Group#GROUP
    if self:IsGroupAssigned( PlayerGroup ) then
      local PlayerNames = PlayerGroup:GetPlayerNames()
      for PlayerNameID, PlayerName in pairs( PlayerNames ) do
        PlayerNameMap[PlayerName] = PlayerGroup
      end
    end
  end

  return PlayerNameMap
end


--- Create a detailed report of the Task.
-- List the Task Status, and the Players assigned to the Task.
-- @param #TASK self
-- @param Wrapper.Group#GROUP TaskGroup
-- @return #string
function TASK:ReportDetails( TaskGroup ) --R2.1 fixed report. Now nicely formatted and contains the info required.

  local Report = REPORT:New():SetIndent( 3 )
  
  -- List the name of the Task.
  local Name = self:GetName()
  
  -- Determine the status of the Task.
  local State = self:GetState()

  -- Loop each Unit active in the Task, and find Player Names.
  local PlayerNames = self:GetPlayerNames()
  
  local PlayerReport = REPORT:New()
  for PlayerName, PlayerGroup in pairs( PlayerNames ) do
    PlayerReport:Add( "Group " .. PlayerGroup:GetCallsign() .. ": " .. PlayerName )
  end
  local Players = PlayerReport:Text()

  Report:Add( "Task: " .. Name .. " - " .. State .. " - Detailed Report" )
  Report:Add( " - Players:" )
  Report:AddIndent( Players )
  
  for TaskInfoID, TaskInfo in pairs( self.TaskInfo ) do
    
    local TaskInfoIDText = string.format( " - %s: ", TaskInfoID )

    if type(TaskInfo) == "string" then
      Report:Add( TaskInfoIDText .. TaskInfo )
    elseif type(TaskInfo) == "table" then
      if TaskInfoID == "Coordinates" then
        local FromCoordinate = TaskGroup:GetUnit(1):GetCoordinate()
        local ToCoordinate = TaskInfo -- Core.Point#COORDINATE
        Report:Add( TaskInfoIDText )
        Report:AddIndent( ToCoordinate:ToStringBRA( FromCoordinate ) .. ", " .. TaskInfo:ToStringAspect( FromCoordinate ) )
        Report:AddIndent( ToCoordinate:ToStringBULLS( TaskGroup:GetCoalition() ) )
      else
      end
    end
    
  end
  
  return Report:Text()
end


end -- Reporting
