--- This module contains the TASK class.
-- 
-- 1) @{#TASK} class, extends @{Base#BASE}
-- ============================================
-- 1.1) The @{#TASK} class implements the methods for task orchestration within MOOSE. 
-- ----------------------------------------------------------------------------------------
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
--   
-- 1.2) Set and enquire task status (beyond the task state machine processing).
-- ----------------------------------------------------------------------------
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
-- 1.3) Add scoring when reaching a certain task status:
-- -----------------------------------------------------
-- Upon reaching a certain task status in a task, additional scoring can be given. If the Mission has a scoring system attached, the scores will be added to the mission scoring.
-- Use the method @{#TASK.AddScore}() to add scores when a status is reached.
-- 
-- 1.4) Task briefing:
-- -------------------
-- A task briefing can be given that is shown to the player when he is assigned to the task.
-- 
-- ===
-- 
-- ### Authors: FlightControl - Design and Programming
-- 
-- @module Task

--- The TASK class
-- @type TASK
-- @field Core.Scheduler#SCHEDULER TaskScheduler
-- @field Tasking.Mission#MISSION Mission
-- @field Core.Set#SET_GROUP SetGroup The Set of Groups assigned to the Task
-- @field Core.Fsm#FSM_PROCESS FsmTemplate
-- @field Tasking.Mission#MISSION Mission
-- @field Tasking.CommandCenter#COMMANDCENTER CommandCenter
-- @extends Core.Fsm#FSM_TASK
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
function TASK:New( Mission, SetGroupAssign, TaskName, TaskType )

  local self = BASE:Inherit( self, FSM_TASK:New() ) -- Core.Fsm#FSM_TASK

  self:SetStartState( "Planned" )
  self:AddTransition( "Planned", "Assign", "Assigned" )
  self:AddTransition( "Assigned", "AssignUnit", "Assigned" )
  self:AddTransition( "Assigned", "Success", "Success" )
  self:AddTransition( "Assigned", "Fail", "Failed" )
  self:AddTransition( "Assigned", "Abort", "Aborted" )
  self:AddTransition( "Assigned", "Cancel", "Cancelled" )
  self:AddTransition( "*", "PlayerCrashed", "*" )
  self:AddTransition( "*", "PlayerAborted", "*" )
  self:AddTransition( "*", "PlayerDead", "*" )
  self:AddTransition( { "Failed", "Aborted", "Cancelled" }, "Replan", "Planned" )

  self:E( "New TASK " .. TaskName )

  self.Processes = {}
  self.Fsm = {}

  self.Mission = Mission
  self.CommandCenter = Mission:GetCommandCenter()
  
  self.SetGroup = SetGroupAssign

  self:SetType( TaskType )
  self:SetName( TaskName )
  self:SetID( Mission:GetNextTaskID( self ) ) -- The Mission orchestrates the task sequences ..

  self.TaskBriefing = "You are invited for the task: " .. self.TaskName .. "."
  
  self.FsmTemplate = self.FsmTemplate or FSM_PROCESS:New()
  
  Mission:AddTask( self )
  
  return self
end

--- Get the Task FSM Process Template
-- @param #TASK self
-- @return Core.Fsm#FSM_PROCESS
function TASK:GetUnitProcess()

  return self.FsmTemplate
end

--- Sets the Task FSM Process Template
-- @param #TASK self
-- @param Core.Fsm#FSM_PROCESS
function TASK:SetUnitProcess( FsmTemplate )

  self.FsmTemplate = FsmTemplate
end

--- Add a PlayerUnit to join the Task.
-- For each Group within the Task, the Unit is check if it can join the Task.
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
      self:MessageToGroups( PlayerUnit:GetPlayerName() .. " is planning to join Task " .. self:GetName() )
    end
    if self:IsStateAssigned() then
      local IsAssignedToGroup = self:IsAssignedToGroup( PlayerGroup )
      self:E( { IsAssignedToGroup = IsAssignedToGroup } )
      if IsAssignedToGroup then
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
-- @return #boolean true if Unit is part of the Task.
function TASK:AbortUnit( PlayerUnit )
  self:F( { PlayerUnit = PlayerUnit } )
  
  local PlayerUnitAborted = false
  
  local PlayerGroups = self:GetGroups()
  local PlayerGroup = PlayerUnit:GetGroup()

  -- Is the PlayerGroup part of the PlayerGroups?  
  if PlayerGroups:IsIncludeObject( PlayerGroup ) then
  
    -- Check if the PlayerGroup is already assigned to the Task. If yes, the PlayerGroup is aborted from the Task.
    -- If the PlayerUnit was the last unit of the PlayerGroup, the menu needs to be removed from the Group.
    if self:IsStateAssigned() then
      local IsAssignedToGroup = self:IsAssignedToGroup( PlayerGroup )
      self:E( { IsAssignedToGroup = IsAssignedToGroup } )
      if IsAssignedToGroup then
        self:UnAssignFromUnit( PlayerUnit )
        self:MessageToGroups( PlayerUnit:GetPlayerName() .. " aborted Task " .. self:GetName() )
        self:E( { TaskGroup = PlayerGroup:GetName(), GetUnits = PlayerGroup:GetUnits() } )
        if #PlayerGroup:GetUnits() == 1 then
          PlayerGroup:SetState( PlayerGroup, "Assigned", nil )
          self:RemoveMenuForGroup( PlayerGroup )
        end
        self:PlayerAborted( PlayerUnit )
      end
    end
  end
  
  return PlayerUnitAborted
end

--- A PlayerUnit crashed in a Task. Abort the Player.
-- If the Unit was not part of the Task, false is returned.
-- If the Unit is part of the Task, true is returned.
-- @param #TASK self
-- @param Wrapper.Unit#UNIT PlayerUnit The CLIENT or UNIT of the Player aborting the Task.
-- @return #boolean true if Unit is part of the Task.
function TASK:CrashUnit( PlayerUnit )
  self:F( { PlayerUnit = PlayerUnit } )
  
  local PlayerUnitCrashed = false
  
  local PlayerGroups = self:GetGroups()
  local PlayerGroup = PlayerUnit:GetGroup()

  -- Is the PlayerGroup part of the PlayerGroups?  
  if PlayerGroups:IsIncludeObject( PlayerGroup ) then
  
    -- Check if the PlayerGroup is already assigned to the Task. If yes, the PlayerGroup is aborted from the Task.
    -- If the PlayerUnit was the last unit of the PlayerGroup, the menu needs to be removed from the Group.
    if self:IsStateAssigned() then
      local IsAssignedToGroup = self:IsAssignedToGroup( PlayerGroup )
      self:E( { IsAssignedToGroup = IsAssignedToGroup } )
      if IsAssignedToGroup then
        self:UnAssignFromUnit( PlayerUnit )
        self:MessageToGroups( PlayerUnit:GetPlayerName() .. " crashed in Task " .. self:GetName() )
        self:E( { TaskGroup = PlayerGroup:GetName(), GetUnits = PlayerGroup:GetUnits() } )
        if #PlayerGroup:GetUnits() == 1 then
          PlayerGroup:SetState( PlayerGroup, "Assigned", nil )
          self:RemoveMenuForGroup( PlayerGroup )
        end
        self:PlayerCrashed( PlayerUnit )
      end
    end
  end
  
  return PlayerUnitCrashed
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



--- Assign the @{Task}to a @{Group}.
-- @param #TASK self
-- @param Wrapper.Group#GROUP TaskGroup
-- @return #TASK
function TASK:AssignToGroup( TaskGroup )
  self:F2( TaskGroup:GetName() )
  
  local TaskGroupName = TaskGroup:GetName()
  
  TaskGroup:SetState( TaskGroup, "Assigned", self )
  
  self:RemoveMenuForGroup( TaskGroup )
  self:SetAssignedMenuForGroup( TaskGroup )
  
  local TaskUnits = TaskGroup:GetUnits()
  for UnitID, UnitData in pairs( TaskUnits ) do
    local TaskUnit = UnitData -- Wrapper.Unit#UNIT
    local PlayerName = TaskUnit:GetPlayerName()
    self:E(PlayerName)
    if PlayerName ~= nil or PlayerName ~= "" then
      self:AssignToUnit( TaskUnit )
    end
  end
  
  return self
end

---
-- @param #TASK self
-- @param Wrapper.Group#GROUP FindGroup
-- @return #boolean
function TASK:HasGroup( FindGroup )

  return self:GetGroups():IsIncludeObject( FindGroup )

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
  self:F( TaskUnit )
  
  self:RemoveStateMachine( TaskUnit )

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

    if self:IsAssignedToGroup( TaskGroup ) then    
      TaskGroup:Message( self.TaskBriefing, 60 )
    end
  end
end


--- Assign the @{Task} from the @{Group}s.
-- @param #TASK self
function TASK:UnAssignFromGroups()
  self:F2()
  
  for TaskGroupName, TaskGroup in pairs( self.SetGroup:GetSet() ) do

    TaskGroup:SetState( TaskGroup, "Assigned", nil )

    self:RemoveMenuForGroup( TaskGroup )

    local TaskUnits = TaskGroup:GetUnits()
    for UnitID, UnitData in pairs( TaskUnits ) do
      local TaskUnit = UnitData -- Wrapper.Unit#UNIT
      local PlayerName = TaskUnit:GetPlayerName()
      if PlayerName ~= nil or PlayerName ~= "" then
        self:UnAssignFromUnit( TaskUnit )
      end
    end
  end
end

--- Returns if the @{Task} is assigned to the Group.
-- @param #TASK self
-- @param Wrapper.Group#GROUP TaskGroup
-- @return #boolean
function TASK:IsAssignedToGroup( TaskGroup )

  local TaskGroupName = TaskGroup:GetName()
  
  if self:IsStateAssigned() then
    if TaskGroup:GetState( TaskGroup, "Assigned" ) == self then
      return true
    end
  end
  
  return false
end

--- Returns if the @{Task} has still alive and assigned Units.
-- @param #TASK self
-- @return #boolean
function TASK:HasAliveUnits()
  self:F()
  
  for TaskGroupID, TaskGroup in pairs( self.SetGroup:GetSet() ) do
    if self:IsStateAssigned() then
      if self:IsAssignedToGroup( TaskGroup ) then
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
function TASK:SetMenu()
  self:F()

  self.SetGroup:Flush()
  for TaskGroupID, TaskGroup in pairs( self.SetGroup:GetSet() ) do
    if self:IsStatePlanned() or self:IsStateReplanned() then
      self:SetMenuForGroup( TaskGroup )
    end
  end  
end


--- Remove the menu options of the @{Task} to all the groups in the SetGroup.
-- @param #TASK self
-- @return #TASK self
function TASK:RemoveMenu()

  for TaskGroupID, TaskGroup in pairs( self.SetGroup:GetSet() ) do
    self:RemoveMenuForGroup( TaskGroup )
  end
end


--- Set the Menu for a Group
-- @param #TASK self
function TASK:SetMenuForGroup( TaskGroup )

  if not self:IsAssignedToGroup( TaskGroup ) then
    self:SetPlannedMenuForGroup( TaskGroup, self:GetTaskName() )
  else
    self:SetAssignedMenuForGroup( TaskGroup )
  end
end


--- Set the planned menu option of the @{Task}.
-- @param #TASK self
-- @param Wrapper.Group#GROUP TaskGroup
-- @param #string MenuText The menu text.
-- @return #TASK self
function TASK:SetPlannedMenuForGroup( TaskGroup, MenuText )
  self:E( TaskGroup:GetName() )

  local Mission = self:GetMission()
  local MissionMenu = Mission:GetMissionMenu( TaskGroup )

  local TaskType = self:GetType()
  local TaskTypeMenu = MENU_GROUP:New( TaskGroup, TaskType, MissionMenu )
  local TaskMenu = MENU_GROUP_COMMAND:New( TaskGroup, MenuText, TaskTypeMenu, self.MenuAssignToGroup, { self = self, TaskGroup = TaskGroup } )
      
  return self
end

--- Set the assigned menu options of the @{Task}.
-- @param #TASK self
-- @param Wrapper.Group#GROUP TaskGroup
-- @return #TASK self
function TASK:SetAssignedMenuForGroup( TaskGroup )
  self:E( TaskGroup:GetName() )

  local Mission = self:GetMission()
  local MissionMenu = Mission:GetMissionMenu( TaskGroup )

  self:E( { MissionMenu = MissionMenu } )

  local TaskTypeMenu = MENU_GROUP_COMMAND:New( TaskGroup, "Task Status", MissionMenu, self.MenuTaskStatus, { self = self, TaskGroup = TaskGroup } )
  local TaskMenu = MENU_GROUP_COMMAND:New( TaskGroup, "Abort Task", MissionMenu, self.MenuTaskAbort, { self = self, TaskGroup = TaskGroup } )

  return self
end

--- Remove the menu option of the @{Task} for a @{Group}.
-- @param #TASK self
-- @param Wrapper.Group#GROUP TaskGroup
-- @return #TASK self
function TASK:RemoveMenuForGroup( TaskGroup )

  local Mission = self:GetMission()
  local MissionName = Mission:GetName()

  local MissionMenu = Mission:GetMissionMenu( TaskGroup )
  MissionMenu:Remove()
end

function TASK.MenuAssignToGroup( MenuParam )

  local self = MenuParam.self
  local TaskGroup = MenuParam.TaskGroup
  
  self:E( "Assigned menu selected")
  
  self:AssignToGroup( TaskGroup )
end

function TASK.MenuTaskStatus( MenuParam )

  local self = MenuParam.self
  local TaskGroup = MenuParam.TaskGroup
  
  --self:AssignToGroup( TaskGroup )
end

function TASK.MenuTaskAbort( MenuParam )

  local self = MenuParam.self
  local TaskGroup = MenuParam.TaskGroup
  
  self:Abort()
end



--- Returns the @{Task} name.
-- @param #TASK self
-- @return #string TaskName
function TASK:GetTaskName()
  return self.TaskName
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
-- @return #TASK self
function TASK:SetStateMachine( TaskUnit, Fsm )
  self:F( { TaskUnit, self.Fsm[TaskUnit] ~= nil } )

  self.Fsm[TaskUnit] = Fsm
    
  return Fsm
end

--- Remove FiniteStateMachines from @{Task} with key Task@{Unit}
-- @param #TASK self
-- @param Wrapper.Unit#UNIT TaskUnit
-- @return #TASK self
function TASK:RemoveStateMachine( TaskUnit )
  self:F( { TaskUnit, self.Fsm[TaskUnit] ~= nil } )

  self.Fsm[TaskUnit] = nil
  collectgarbage()
  self:T( "Garbage Collected, Processes should be finalized now ...")
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
  self.TaskBriefing = TaskBriefing
  return self
end




--- FSM function for a TASK
-- @param #TASK self
-- @param #string Event
-- @param #string From
-- @param #string To
function TASK:onenterAssigned( From, Event, To )

  self:E("Task Assigned")
  
  self:MessageToGroups( "Task " .. self:GetName() .. " has been assigned to your group." )
  self:GetMission():__Start( 1 )
end


--- FSM function for a TASK
-- @param #TASK self
-- @param #string Event
-- @param #string From
-- @param #string To
function TASK:onenterSuccess( From, Event, To )

  self:E( "Task Success" )
  
  self:MessageToGroups( "Task " .. self:GetName() .. " is successful! Good job!" )
  self:UnAssignFromGroups()
  
  self:GetMission():__Complete( 1 )
  
end


--- FSM function for a TASK
-- @param #TASK self
-- @param #string From
-- @param #string Event
-- @param #string To
function TASK:onenterAborted( From, Event, To )

  self:E( "Task Aborted" )

  self:GetMission():GetCommandCenter():MessageToCoalition( "Task " .. self:GetName() .. " has been aborted! Task may be replanned." )
  
  self:UnAssignFromGroups()
  
  self:__Replan( 5 )
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
    MESSAGE:New( "@ Task " .. self.TaskName .. " : " .. Event .. " changed to state " .. To, 2 ):ToAll()
  end

  if self.Scores[To] then
    local Scoring = self:GetScoring()
    if Scoring then
      self:E( { self.Scores[To].ScoreText, self.Scores[To].Score } )
      Scoring:_AddMissionScore( self.Mission, self.Scores[To].ScoreText, self.Scores[To].Score )
    end
  end

end

do -- Reporting

--- Create a summary report of the Task.
-- List the Task Name and Status
-- @param #TASK self
-- @return #string
function TASK:ReportSummary()

  local Report = REPORT:New()
  
  -- List the name of the Task.
  local Name = self:GetName()
  
  -- Determine the status of the Task.
  local State = self:GetState()
  
  Report:Add( "Task " .. Name .. " - State '" .. State )

  return Report:Text()
end


--- Create a detailed report of the Task.
-- List the Task Status, and the Players assigned to the Task.
-- @param #TASK self
-- @return #string
function TASK:ReportDetails()

  local Report = REPORT:New()
  
  -- List the name of the Task.
  local Name = self:GetName()
  
  -- Determine the status of the Task.
  local State = self:GetState()
  
  
  -- Loop each Unit active in the Task, and find Player Names.
  local PlayerNames = {}
  for PlayerGroupID, PlayerGroup in pairs( self:GetGroups():GetSet() ) do
    local Player = PlayerGroup -- Wrapper.Group#GROUP
    for PlayerUnitID, PlayerUnit in pairs( PlayerGroup:GetUnits() ) do
      local PlayerUnit = PlayerUnit -- Wrapper.Unit#UNIT
      if PlayerUnit and PlayerUnit:IsAlive() then
        local PlayerName = PlayerUnit:GetPlayerName()
        PlayerNames[#PlayerNames+1] = PlayerName
      end
    end
    local PlayerNameText = table.concat( PlayerNames, ", " )
    Report:Add( "Task " .. Name .. " - State '" .. State .. "' - Players " .. PlayerNameText )
  end
  
  -- Loop each Process in the Task, and find Reporting Details.

  return Report:Text()
end


end -- Reporting
