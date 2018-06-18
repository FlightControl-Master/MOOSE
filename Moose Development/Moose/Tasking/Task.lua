--- **Tasking** -- This module contains the TASK class, the main engine to run human taskings.
-- 
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ### Contributions: 
-- 
-- ===
-- 
-- @module Tasking.Task
-- @image MOOSE.JPG

--- @type TASK
-- @field Core.Scheduler#SCHEDULER TaskScheduler
-- @field Tasking.Mission#MISSION Mission
-- @field Core.Set#SET_GROUP SetGroup The Set of Groups assigned to the Task
-- @field Core.Fsm#FSM_PROCESS FsmTemplate
-- @field Tasking.Mission#MISSION Mission
-- @field Tasking.CommandCenter#COMMANDCENTER CommandCenter
-- @field Tasking.TaskInfo#TASKINFO TaskInfo
-- @extends Core.Fsm#FSM_TASK

--- 
-- # TASK class, extends @{Core.Base#BASE}
-- 
-- ## The TASK class implements the methods for task orchestration within MOOSE. 
-- 
-- The class provides a couple of methods to:
-- 
--   * @{#TASK.AssignToGroup}():Assign a task to a group (of players).
--   * @{#TASK.AddProcess}():Add a @{Process} to a task.
--   * @{#TASK.RemoveProcesses}():Remove a running @{Process} from a running task.
--   * @{#TASK.SetStateMachine}():Set a @{Core.Fsm} to a task.
--   * @{#TASK.RemoveStateMachine}():Remove @{Core.Fsm} from a task.
--   * @{#TASK.HasStateMachine}():Enquire if the task has a @{Core.Fsm}
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

  local self = BASE:Inherit( self, FSM_TASK:New( TaskName ) ) -- Tasking.Task#TASK

  self:SetStartState( "Planned" )
  self:AddTransition( "Planned", "Assign", "Assigned" )
  self:AddTransition( "Assigned", "AssignUnit", "Assigned" )
  self:AddTransition( "Assigned", "Success", "Success" )
  self:AddTransition( "Assigned", "Hold", "Hold" )
  self:AddTransition( "Assigned", "Fail", "Failed" )
  self:AddTransition( { "Planned", "Assigned" }, "Abort", "Aborted" )
  self:AddTransition( "Assigned", "Cancel", "Cancelled" )
  self:AddTransition( "Assigned", "Goal", "*" )
  
  self.Fsm = {}
  
  local Fsm = self:GetUnitProcess()
  Fsm:SetStartState( "Planned" )
  Fsm:AddProcess   ( "Planned", "Accept", ACT_ASSIGN_ACCEPT:New( self.TaskBriefing ), { Assigned = "Assigned", Rejected = "Reject" }  )
  Fsm:AddTransition( "Assigned", "Assigned", "*" )
  
  --- Goal Handler OnBefore for TASK
  -- @function [parent=#TASK] OnBeforeGoal
  -- @param #TASK self
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param Wrapper.Unit#UNIT PlayerUnit The @{Wrapper.Unit} of the player.
  -- @param #string PlayerName The name of the player.
  -- @return #boolean
  
  --- Goal Handler OnAfter for TASK
  -- @function [parent=#TASK] OnAfterGoal
  -- @param #TASK self
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param Wrapper.Unit#UNIT PlayerUnit The @{Wrapper.Unit} of the player.
  -- @param #string PlayerName The name of the player.
  
  --- Goal Trigger for TASK
  -- @function [parent=#TASK] Goal
  -- @param #TASK self
  -- @param Wrapper.Unit#UNIT PlayerUnit The @{Wrapper.Unit} of the player.
  -- @param #string PlayerName The name of the player.
  
  --- Goal Asynchronous Trigger for TASK
  -- @function [parent=#TASK] __Goal
  -- @param #TASK self
  -- @param #number Delay
  -- @param Wrapper.Unit#UNIT PlayerUnit The @{Wrapper.Unit} of the player.
  -- @param #string PlayerName The name of the player.
  
  
  
  self:AddTransition( "*", "PlayerCrashed", "*" )
  self:AddTransition( "*", "PlayerAborted", "*" )
  self:AddTransition( "*", "PlayerRejected", "*" )
  self:AddTransition( "*", "PlayerDead", "*" )
  self:AddTransition( { "Failed", "Aborted", "Cancelled" }, "Replan", "Planned" )
  self:AddTransition( "*", "TimeOut", "Cancelled" )

  self:F( "New TASK " .. TaskName )

  self.Processes = {}

  self.Mission = Mission
  self.CommandCenter = Mission:GetCommandCenter()
  
  self.SetGroup = SetGroupAssign

  self:SetType( TaskType )
  self:SetName( TaskName )
  self:SetID( Mission:GetNextTaskID( self ) ) -- The Mission orchestrates the task sequences ..

  self:SetBriefing( TaskBriefing )
  
  
  self.TaskInfo = TASKINFO:New( self )
  
  self.TaskProgress = {}
  
  return self
end

--- Get the Task FSM Process Template
-- @param #TASK self
-- @return Core.Fsm#FSM_PROCESS
function TASK:GetUnitProcess( TaskUnit )

  if TaskUnit then
    return self:GetStateMachine( TaskUnit )
  else
    self.FsmTemplate = self.FsmTemplate or FSM_PROCESS:New()
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
      --self:SetMenuForGroup( PlayerGroup )
      --self:MessageToGroups( PlayerUnit:GetPlayerName() .. " is planning to join Task " .. self:GetName() )
    end
    if self:IsStateAssigned() then
      local IsGroupAssigned = self:IsGroupAssigned( PlayerGroup )
      self:F( { IsGroupAssigned = IsGroupAssigned } )
      if IsGroupAssigned then
        self:AssignToUnit( PlayerUnit )
        self:MessageToGroups( PlayerUnit:GetPlayerName() .. " joined Task " .. self:GetName() )
      end
    end
  end
  
  return PlayerUnitAdded
end

--- A group rejecting a planned task.
-- @param #TASK self
-- @param Wrapper.Group#GROUP PlayerGroup The group rejecting the task.
-- @return #TASK
function TASK:RejectGroup( PlayerGroup )
  
  local PlayerGroups = self:GetGroups()

  -- Is the PlayerGroup part of the PlayerGroups?  
  if PlayerGroups:IsIncludeObject( PlayerGroup ) then
  
    -- Check if the PlayerGroup is already assigned or is planned to be assigned to the Task. 
    -- If yes, the PlayerGroup is aborted from the Task.
    -- If the PlayerUnit was the last unit of the PlayerGroup, the menu needs to be removed from the Group.
    if self:IsStatePlanned() then

      local IsGroupAssigned = self:IsGroupAssigned( PlayerGroup )
      if IsGroupAssigned then
        local PlayerName = PlayerGroup:GetUnit(1):GetPlayerName()
        self:GetMission():GetCommandCenter():MessageToGroup( "Task " .. self:GetName() .. " has been rejected! We will select another task.", PlayerGroup )
        self:UnAssignFromGroup( PlayerGroup )

        self:PlayerRejected( PlayerGroup:GetUnit(1) )
      end
      
    end
  end
  
  return self
end


--- A group aborting the task.
-- @param #TASK self
-- @param Wrapper.Group#GROUP PlayerGroup The group aborting the task.
-- @return #TASK
function TASK:AbortGroup( PlayerGroup )
  
  local PlayerGroups = self:GetGroups()

  -- Is the PlayerGroup part of the PlayerGroups?  
  if PlayerGroups:IsIncludeObject( PlayerGroup ) then
  
    -- Check if the PlayerGroup is already assigned or is planned to be assigned to the Task. 
    -- If yes, the PlayerGroup is aborted from the Task.
    -- If the PlayerUnit was the last unit of the PlayerGroup, the menu needs to be removed from the Group.
    if self:IsStateAssigned() then

      local IsGroupAssigned = self:IsGroupAssigned( PlayerGroup )
      if IsGroupAssigned then
        local PlayerName = PlayerGroup:GetUnit(1):GetPlayerName()
        self:UnAssignFromGroup( PlayerGroup )

        -- Now check if the task needs to go to hold...
        -- It will go to hold, if there are no players in the mission...
        PlayerGroups:Flush( self )
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


--- A group crashing and thus aborting from the task.
-- @param #TASK self
-- @param Wrapper.Group#GROUP PlayerGroup The group aborting the task.
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
      self:F( { IsGroupAssigned = IsGroupAssigned } )
      if IsGroupAssigned then
        local PlayerName = PlayerGroup:GetUnit(1):GetPlayerName()
        self:MessageToGroups( PlayerName .. " crashed! " )
        self:UnAssignFromGroup( PlayerGroup )

        -- Now check if the task needs to go to hold...
        -- It will go to hold, if there are no players in the mission...
        
        PlayerGroups:Flush( self )
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


--- Gets the SET_GROUP assigned to the TASK.
-- @param #TASK self
-- @param Core.Set#SET_GROUP GroupSet
-- @return Core.Set#SET_GROUP
function TASK:AddGroups( GroupSet )

  GroupSet = GroupSet or SET_GROUP:New()
 
  self.SetGroup:ForEachGroup(
    --- @param Wrapper.Group#GROUP GroupSet
    function( GroupItem )
      GroupSet:Add( GroupItem:GetName(), GroupItem)
    end
  )
  
  return GroupSet
end

do -- Group Assignment

  --- Returns if the @{Task} is assigned to the Group.
  -- @param #TASK self
  -- @param Wrapper.Group#GROUP TaskGroup
  -- @return #boolean
  function TASK:IsGroupAssigned( TaskGroup )
  
    local TaskGroupName = TaskGroup:GetName()
    
    if self.AssignedGroups[TaskGroupName] then
      --self:T( { "Task is assigned to:", TaskGroup:GetName() } )
      return true
    end
    
    --self:T( { "Task is not assigned to:", TaskGroup:GetName() } )
    return false
  end
  
  
  --- Set @{Wrapper.Group} assigned to the @{Task}.
  -- @param #TASK self
  -- @param Wrapper.Group#GROUP TaskGroup
  -- @return #TASK
  function TASK:SetGroupAssigned( TaskGroup )
  
    local TaskName = self:GetName()
    local TaskGroupName = TaskGroup:GetName()
  
    self.AssignedGroups[TaskGroupName] = TaskGroup
    self:F( string.format( "Task %s is assigned to %s", TaskName, TaskGroupName ) )
    
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
  
  --- Clear the @{Wrapper.Group} assignment from the @{Task}.
  -- @param #TASK self
  -- @param Wrapper.Group#GROUP TaskGroup
  -- @return #TASK
  function TASK:ClearGroupAssignment( TaskGroup )
  
    local TaskName = self:GetName()
    local TaskGroupName = TaskGroup:GetName()
  
    self.AssignedGroups[TaskGroupName] = nil
    --self:F( string.format( "Task %s is unassigned to %s", TaskName, TaskGroupName ) )

    -- Set the group to be assigned at mission level. This allows to decide the menu options on mission level for this group.
    self:GetMission():ClearGroupAssignment( TaskGroup )
    
    local SetAssignedGroups = self:GetGroups()

    SetAssignedGroups:ForEachGroup(
      function( AssignedGroup )
        if self:IsGroupAssigned(AssignedGroup) then
          --self:GetMission():GetCommandCenter():MessageToGroup( string.format( "Task %s is unassigned from group %s.", TaskName, TaskGroupName ), AssignedGroup )
        else
          --self:GetMission():GetCommandCenter():MessageToGroup( string.format( "Task %s is unassigned from your group.", TaskName ), AssignedGroup )
        end
      end
    )
    
    return self
  end
  
end

do -- Group Assignment

  --- @param #TASK self
  -- @param Actions.Act_Assign#ACT_ASSIGN AcceptClass
  function TASK:SetAssignMethod( AcceptClass )
  
    local ProcessTemplate = self:GetUnitProcess()

    ProcessTemplate:SetProcess( "Planned", "Accept", AcceptClass ) -- Actions.Act_Assign#ACT_ASSIGN
  end


  --- Assign the @{Task} to a @{Wrapper.Group}.
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
      self:F(PlayerName)
      if PlayerName ~= nil and PlayerName ~= "" then
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
  
  --- UnAssign the @{Task} from a @{Wrapper.Group}.
  -- @param #TASK self
  -- @param Wrapper.Group#GROUP TaskGroup
  function TASK:UnAssignFromGroup( TaskGroup )
    self:F2( { TaskGroup = TaskGroup:GetName() } )
    
    self:ClearGroupAssignment( TaskGroup )
  
    local TaskUnits = TaskGroup:GetUnits()
    for UnitID, UnitData in pairs( TaskUnits ) do
      local TaskUnit = UnitData -- Wrapper.Unit#UNIT
      local PlayerName = TaskUnit:GetPlayerName()
      if PlayerName ~= nil and PlayerName ~= "" then -- Only remove units that have players!
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
  return SetAttackGroup:FindGroup( FindGroup:GetName() )

end

--- Assign the @{Task} to an alive @{Wrapper.Unit}.
-- @param #TASK self
-- @param Wrapper.Unit#UNIT TaskUnit
-- @return #TASK self
function TASK:AssignToUnit( TaskUnit )
  self:F( TaskUnit:GetName() )
  
  local FsmTemplate = self:GetUnitProcess()
  
  -- Assign a new FsmUnit to TaskUnit.
  local FsmUnit = self:SetStateMachine( TaskUnit, FsmTemplate:Copy( TaskUnit, self ) ) -- Core.Fsm#FSM_PROCESS
  
  FsmUnit:SetStartState( "Planned" )
  
  FsmUnit:Accept() -- Each Task needs to start with an Accept event to start the flow.

  return self
end

--- UnAssign the @{Task} from an alive @{Wrapper.Unit}.
-- @param #TASK self
-- @param Wrapper.Unit#UNIT TaskUnit
-- @return #TASK self
function TASK:UnAssignFromUnit( TaskUnit )
  self:F( TaskUnit:GetName() )
  
  self:RemoveStateMachine( TaskUnit )
  
  -- If a Task Control Menu had been set, then this will be removed.
  self:RemoveTaskControlMenu( TaskUnit )
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

--- Send a message of the @{Task} to the assigned @{Wrapper.Group}s.
-- @param #TASK self
function TASK:MessageToGroups( Message )
  self:F( { Message = Message } )

  local Mission = self:GetMission()
  local CC = Mission:GetCommandCenter()
  
  for TaskGroupName, TaskGroup in pairs( self.SetGroup:GetSet() ) do
    TaskGroup = TaskGroup -- Wrapper.Group#GROUP
    if TaskGroup:IsAlive() == true then
      CC:MessageToGroup( Message, TaskGroup, TaskGroup:GetName() )
    end
  end
end


--- Send the briefng message of the @{Task} to the assigned @{Wrapper.Group}s.
-- @param #TASK self
function TASK:SendBriefingToAssignedGroups()
  self:F2()
  
  for TaskGroupName, TaskGroup in pairs( self.SetGroup:GetSet() ) do
    if TaskGroup:IsAlive() then
      if self:IsGroupAssigned( TaskGroup ) then    
        TaskGroup:Message( self.TaskBriefing, 60 )
      end
    end
  end
end


--- UnAssign the @{Task} from the @{Wrapper.Group}s.
-- @param #TASK self
function TASK:UnAssignFromGroups()
  self:F2()
  
  for TaskGroupName, TaskGroup in pairs( self.SetGroup:GetSet() ) do
    if TaskGroup:IsAlive() == true then
      if self:IsGroupAssigned(TaskGroup) then
        self:UnAssignFromGroup( TaskGroup )
      end
    end
  end
end



--- Returns if the @{Task} has still alive and assigned Units.
-- @param #TASK self
-- @return #boolean
function TASK:HasAliveUnits()
  self:F()
  
  for TaskGroupID, TaskGroup in pairs( self.SetGroup:GetSet() ) do
    if TaskGroup:IsAlive() == true then
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
  --for TaskGroupID, TaskGroupData in pairs( self.SetGroup:GetAliveSet() ) do
  for TaskGroupID, TaskGroupData in pairs( self.SetGroup:GetSet() ) do
    local TaskGroup = TaskGroupData -- Wrapper.Group#GROUP
    if TaskGroup:IsAlive() == true and TaskGroup:GetPlayerNames() then
    
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

  if self:IsStatePlanned() or self:IsStateAssigned() then
    self:SetPlannedMenuForGroup( TaskGroup, MenuTime )
    if self:IsGroupAssigned( TaskGroup ) then
      self:SetAssignedMenuForGroup( TaskGroup, MenuTime )
    end
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
  local MissionMenu = Mission:GetMenu( TaskGroup )

  local TaskType = self:GetType()
  local TaskPlayerCount = self:GetPlayerCount()
  local TaskPlayerString = string.format( " (%dp)", TaskPlayerCount )
  local TaskText = string.format( "%s", self:GetName() )
  local TaskName = string.format( "%s", self:GetName() )

  self.MenuPlanned = self.MenuPlanned or {}
  self.MenuPlanned[TaskGroup] = MENU_GROUP_DELAYED:New( TaskGroup, "Join Planned Task", MissionMenu, Mission.MenuReportTasksPerStatus, Mission, TaskGroup, "Planned" ):SetTime( MenuTime ):SetTag( "Tasking" )
  local TaskTypeMenu = MENU_GROUP_DELAYED:New( TaskGroup, TaskType, self.MenuPlanned[TaskGroup] ):SetTime( MenuTime ):SetTag( "Tasking" )
  local TaskTypeMenu = MENU_GROUP_DELAYED:New( TaskGroup, TaskText, TaskTypeMenu ):SetTime( MenuTime ):SetTag( "Tasking" )
  
  if not Mission:IsGroupAssigned( TaskGroup ) then
    --self:F( { "Replacing Join Task menu" } )
    local JoinTaskMenu = MENU_GROUP_COMMAND_DELAYED:New( TaskGroup, string.format( "Join Task" ), TaskTypeMenu, self.MenuAssignToGroup, self, TaskGroup ):SetTime( MenuTime ):SetTag( "Tasking" )
    local MarkTaskMenu = MENU_GROUP_COMMAND_DELAYED:New( TaskGroup, string.format( "Mark Task Location on Map" ), TaskTypeMenu, self.MenuMarkToGroup, self, TaskGroup ):SetTime( MenuTime ):SetTag( "Tasking" )
  end
  
  local ReportTaskMenu = MENU_GROUP_COMMAND_DELAYED:New( TaskGroup, string.format( "Report Task Details" ), TaskTypeMenu, self.MenuTaskStatus, self, TaskGroup ):SetTime( MenuTime ):SetTag( "Tasking" )
      
  return self
end

--- Set the assigned menu options of the @{Task}.
-- @param #TASK self
-- @param Wrapper.Group#GROUP TaskGroup
-- @param #number MenuTime
-- @return #TASK self
function TASK:SetAssignedMenuForGroup( TaskGroup, MenuTime )
  self:F( { TaskGroup:GetName(), MenuTime } )

  local TaskType = self:GetType()
  local TaskPlayerCount = self:GetPlayerCount()
  local TaskPlayerString = string.format( " (%dp)", TaskPlayerCount )
  local TaskText = string.format( "%s%s", self:GetName(), TaskPlayerString ) --, TaskThreatLevelString )
  local TaskName = string.format( "%s", self:GetName() )

  for UnitName, TaskUnit in pairs( TaskGroup:GetPlayerUnits() ) do
    local TaskUnit = TaskUnit -- Wrapper.Unit#UNIT
    if TaskUnit then
      local MenuControl = self:GetTaskControlMenu( TaskUnit )
      local TaskControl = MENU_GROUP:New( TaskGroup, "Control Task", MenuControl ):SetTime( MenuTime ):SetTag( "Tasking" )
      if self:IsStateAssigned() then
        local TaskMenu = MENU_GROUP_COMMAND:New( TaskGroup, string.format( "Abort Task" ), TaskControl, self.MenuTaskAbort, self, TaskGroup ):SetTime( MenuTime ):SetTag( "Tasking" )
      end
      local MarkMenu = MENU_GROUP_COMMAND:New( TaskGroup, string.format( "Mark Task Location on Map" ), TaskControl, self.MenuMarkToGroup, self, TaskGroup ):SetTime( MenuTime ):SetTag( "Tasking" )
      local TaskTypeMenu = MENU_GROUP_COMMAND:New( TaskGroup, string.format( "Report Task Details" ), TaskControl, self.MenuTaskStatus, self, TaskGroup ):SetTime( MenuTime ):SetTag( "Tasking" )
    end
  end

  return self
end

--- Remove the menu options of the @{Task} to all the groups in the SetGroup.
-- @param #TASK self
-- @param #number MenuTime
-- @return #TASK
function TASK:RemoveMenu( MenuTime )
  self:F( { self:GetName(), MenuTime } )

  for TaskGroupID, TaskGroup in pairs( self.SetGroup:GetSet() ) do
    if TaskGroup:IsAlive() == true then
      local TaskGroup = TaskGroup -- Wrapper.Group#GROUP 
      if TaskGroup:IsAlive() == true and TaskGroup:GetPlayerNames() then
        self:RefreshMenus( TaskGroup, MenuTime )
      end
    end
  end
end


--- Remove the menu option of the @{Task} for a @{Wrapper.Group}.
-- @param #TASK self
-- @param Wrapper.Group#GROUP TaskGroup
-- @param #number MenuTime
-- @return #TASK self
function TASK:RefreshMenus( TaskGroup, MenuTime )
  self:F( { TaskGroup:GetName(), MenuTime } )

  local Mission = self:GetMission()
  local MissionName = Mission:GetName()
  local MissionMenu = Mission:GetMenu( TaskGroup )

  local TaskName = self:GetName()
  self.MenuPlanned = self.MenuPlanned or {}
  local PlannedMenu = self.MenuPlanned[TaskGroup]
  
  self.MenuAssigned = self.MenuAssigned or {}
  local AssignedMenu = self.MenuAssigned[TaskGroup]
  
  if PlannedMenu then
    self.MenuPlanned[TaskGroup] = PlannedMenu:Remove( MenuTime , "Tasking" )
    PlannedMenu:Set()
  end
  
  if AssignedMenu then
    self.MenuAssigned[TaskGroup] = AssignedMenu:Remove( MenuTime, "Tasking" )
    AssignedMenu:Set()
  end
  
end

--- Remove the assigned menu option of the @{Task} for a @{Wrapper.Group}.
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

--- @param #TASK self
-- @param Wrapper.Group#GROUP TaskGroup
function TASK:MenuAssignToGroup( TaskGroup )

  self:F( "Join Task menu selected")
  
  self:AssignToGroup( TaskGroup )
end

--- @param #TASK self
-- @param Wrapper.Group#GROUP TaskGroup
function TASK:MenuMarkToGroup( TaskGroup )
  self:F()

  self:UpdateTaskInfo( self.DetectedItem )
  
  local Report = REPORT:New():SetIndent( 0 )

  self.TaskInfo:Report( Report, "M", TaskGroup )

  local TargetCoordinate = self.TaskInfo:GetData( "Coordinate" ) -- Core.Point#COORDINATE
  local MarkText = Report:Text( ", " ) 
  self:F( { Coordinate = TargetCoordinate, MarkText = MarkText } )
  TargetCoordinate:MarkToGroup( MarkText, TaskGroup )
  --Coordinate:MarkToAll( Briefing )
end

--- Report the task status.
-- @param #TASK self
function TASK:MenuTaskStatus( TaskGroup )

  local ReportText = self:ReportDetails( TaskGroup )
  
  self:T( ReportText )
  self:GetMission():GetCommandCenter():MessageTypeToGroup( ReportText, TaskGroup, MESSAGE.Type.Detailed )

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
--- Fail processes from @{Task} with key @{Wrapper.Unit}
-- @param #TASK self
-- @param #string TaskUnitName
-- @return #TASK self
function TASK:FailProcesses( TaskUnitName )

  for ProcessID, ProcessData in pairs( self.Processes[TaskUnitName] ) do
    local Process = ProcessData 
    Process.Fsm:Fail()
  end
end

--- Add a FiniteStateMachine to @{Task} with key Task@{Wrapper.Unit}
-- @param #TASK self
-- @param Wrapper.Unit#UNIT TaskUnit
-- @param Core.Fsm#FSM_PROCESS Fsm
-- @return #TASK self
function TASK:SetStateMachine( TaskUnit, Fsm )
  self:F2( { TaskUnit, self.Fsm[TaskUnit] ~= nil, Fsm:GetClassNameAndID() } )

  self.Fsm[TaskUnit] = Fsm
    
  return Fsm
end

--- Gets the FiniteStateMachine of @{Task} with key Task@{Wrapper.Unit}
-- @param #TASK self
-- @param Wrapper.Unit#UNIT TaskUnit
-- @return Core.Fsm#FSM_PROCESS
function TASK:GetStateMachine( TaskUnit )
  self:F2( { TaskUnit, self.Fsm[TaskUnit] ~= nil } )

  return self.Fsm[TaskUnit]
end

--- Remove FiniteStateMachines from @{Task} with key Task@{Wrapper.Unit}
-- @param #TASK self
-- @param Wrapper.Unit#UNIT TaskUnit
-- @return #TASK self
function TASK:RemoveStateMachine( TaskUnit )
  self:F( { TaskUnit = TaskUnit:GetName(), HasFsm = ( self.Fsm[TaskUnit] ~= nil ) } )

  --self:F( self.Fsm )
  --for TaskUnitT, Fsm in pairs( self.Fsm ) do
    --local Fsm = Fsm -- Core.Fsm#FSM_PROCESS
    --self:F( TaskUnitT )
    --self.Fsm[TaskUnit] = nil
  --end

  if self.Fsm[TaskUnit] then
    self.Fsm[TaskUnit]:Remove()
    self.Fsm[TaskUnit] = nil
  end
  
  collectgarbage()
  self:F( "Garbage Collected, Processes should be finalized now ...")
end


--- Checks if there is a FiniteStateMachine assigned to Task@{Wrapper.Unit} for @{Task}
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
  self:F(TaskBriefing)
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

  --- This test is required, because the state transition will be fired also when the state does not change in case of an event.  
  if From ~= "Assigned" then

    local PlayerNames = self:GetPlayerNames()
    local PlayerText = REPORT:New()
    for PlayerName, TaskName in pairs( PlayerNames ) do
      PlayerText:Add( PlayerName )
    end

    self:GetMission():GetCommandCenter():MessageToCoalition( "Task " .. self:GetName() .. " is assigned to players " .. PlayerText:Text(",") .. ". Good Luck!" )

    -- Set the total Progress to be achieved.
    self:SetGoalTotal() -- Polymorphic to set the initial goal total!
    
    if self.Dispatcher then
      self:F( "Firing Assign event " )
      self.Dispatcher:Assign( self, PlayerUnit, PlayerName )
    end
    
    self:GetMission():__Start( 1 )
    
    -- When the task is assigned, the task goal needs to be checked of the derived classes.
    self:__Goal( -10, PlayerUnit, PlayerName )  -- Polymorphic
     
    self:SetMenu()

    self:F( { "--> Task Assigned", TaskName = self:GetName(), Mission = self:GetMission():GetName() } )
    self:F( { "--> Task Player Names", PlayerNames = PlayerNames } )

  end
end


--- FSM function for a TASK
-- @param #TASK self
-- @param #string Event
-- @param #string From
-- @param #string To
function TASK:onenterSuccess( From, Event, To )

  self:F( { "<-> Task Replanned", TaskName = self:GetName(), Mission = self:GetMission():GetName() } )
  self:F( { "<-> Task Player Names", PlayerNames = self:GetPlayerNames() } )
  
  self:GetMission():GetCommandCenter():MessageToCoalition( "Task " .. self:GetName() .. " is successful! Good job!" )
  self:UnAssignFromGroups()
  
  self:GetMission():__MissionGoals( 1 )
  
end


--- FSM function for a TASK
-- @param #TASK self
-- @param #string From
-- @param #string Event
-- @param #string To
function TASK:onenterAborted( From, Event, To )

  self:F( { "<-- Task Aborted", TaskName = self:GetName(), Mission = self:GetMission():GetName() } )
  self:F( { "<-- Task Player Names", PlayerNames = self:GetPlayerNames() } )
  
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
function TASK:onenterCancelled( From, Event, To )

  self:F( { "<-- Task Cancelled", TaskName = self:GetName(), Mission = self:GetMission():GetName() } )
  self:F( { "<-- Player Names", PlayerNames = self:GetPlayerNames() } )
  
  if From ~= "Cancelled" then
    self:GetMission():GetCommandCenter():MessageToCoalition( "Task " .. self:GetName() .. " has been cancelled! The tactical situation has changed." )
    self:UnAssignFromGroups()
    self:SetMenu()
  end
  
end

--- FSM function for a TASK
-- @param #TASK self
-- @param #string From
-- @param #string Event
-- @param #string To
function TASK:onafterReplan( From, Event, To )

  self:F( { "Task Replanned", TaskName = self:GetName(), Mission = self:GetMission():GetName() } )
  self:F( { "Task Player Names", PlayerNames = self:GetPlayerNames() } )
  
  self:GetMission():GetCommandCenter():MessageToCoalition( "Replanning Task " .. self:GetName() .. "." )
  
  self:SetMenu()
  
end

--- FSM function for a TASK
-- @param #TASK self
-- @param #string From
-- @param #string Event
-- @param #string To
function TASK:onenterFailed( From, Event, To )

  self:F( { "Task Failed", TaskName = self:GetName(), Mission = self:GetMission():GetName() } )
  self:F( { "Task Player Names", PlayerNames = self:GetPlayerNames() } )

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
      self:F( { self.Scores[To].ScoreText, self.Scores[To].Score } )
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

do -- Links

  --- Set dispatcher of a task
  -- @param #TASK self
  -- @param Tasking.DetectionManager#DETECTION_MANAGER Dispatcher
  -- @return #TASK
  function TASK:SetDispatcher( Dispatcher )
    self.Dispatcher = Dispatcher
  end

  --- Set detection of a task
  -- @param #TASK self
  -- @param Function.Detection#DETECTION_BASE Detection
  -- @param DetectedItem
  -- @return #TASK
  function TASK:SetDetection( Detection, DetectedItem )
    
    self:F( { DetectedItem, Detection } )
    
    self.Detection = Detection
    self.DetectedItem = DetectedItem
  end

end

do -- Reporting

--- Create a summary report of the Task.
-- List the Task Name and Status
-- @param #TASK self
-- @param Wrapper.Group#GROUP ReportGroup
-- @return #string
function TASK:ReportSummary( ReportGroup ) 

  self:UpdateTaskInfo( self.DetectedItem )
  
  local Report = REPORT:New()
  
  -- List the name of the Task.
  Report:Add( "Task " .. self:GetName() )
  
  -- Determine the status of the Task.
  Report:Add( "State: <" .. self:GetState() .. ">" )
  
  self.TaskInfo:Report( Report, "S", ReportGroup )
  
  return Report:Text( ', ' )
end

--- Create an overiew report of the Task.
-- List the Task Name and Status
-- @param #TASK self
-- @return #string
function TASK:ReportOverview( ReportGroup )

  self:UpdateTaskInfo( self.DetectedItem )
  
  -- List the name of the Task.
  local TaskName = self:GetName()
  local Report = REPORT:New()
  
  self.TaskInfo:Report( Report, "O", ReportGroup )
  
  return Report:Text()
end

--- Create a count of the players in the Task.
-- @param #TASK self
-- @return #number The total number of players in the task.
function TASK:GetPlayerCount() --R2.1 Get a count of the players.

  local PlayerCount = 0

  -- Loop each Unit active in the Task, and find Player Names.
  for TaskGroupID, PlayerGroup in pairs( self:GetGroups():GetSet() ) do
    local PlayerGroup = PlayerGroup -- Wrapper.Group#GROUP
    if PlayerGroup:IsAlive() == true then
      if self:IsGroupAssigned( PlayerGroup ) then
        local PlayerNames = PlayerGroup:GetPlayerNames()
          PlayerCount = PlayerCount + #PlayerNames
      end
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
    if PlayerGroup:IsAlive() == true then
      if self:IsGroupAssigned( PlayerGroup ) then
        local PlayerNames = PlayerGroup:GetPlayerNames()
        for PlayerNameID, PlayerName in pairs( PlayerNames ) do
          PlayerNameMap[PlayerName] = PlayerGroup
        end
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
function TASK:ReportDetails( ReportGroup )

  self:UpdateTaskInfo( self.DetectedItem )

  local Report = REPORT:New():SetIndent( 3 )
  
  -- List the name of the Task.
  local Name = self:GetName()
  
  -- Determine the status of the Task.
  local Status = "<" .. self:GetState() .. ">"

  Report:Add( "Task " .. Name .. " - " .. Status .. " - Detailed Report" )

  -- Loop each Unit active in the Task, and find Player Names.
  local PlayerNames = self:GetPlayerNames()
  
  local PlayerReport = REPORT:New()
  for PlayerName, PlayerGroup in pairs( PlayerNames ) do
    PlayerReport:Add( "Players group " .. PlayerGroup:GetCallsign() .. ": " .. PlayerName )
  end
  local Players = PlayerReport:Text()
  
  if Players ~= "" then
    Report:AddIndent( "Players assigned:", "-" )
    Report:AddIndent( Players )
  end
  
  self.TaskInfo:Report( Report, "D", ReportGroup )
  
  return Report:Text()
end


end -- Reporting


do -- Additional Task Scoring and Task Progress

  --- Add Task Progress for a Player Name
  -- @param #TASK self
  -- @param #string PlayerName The name of the player.
  -- @param #string ProgressText The text that explains the Progress achieved.
  -- @param #number ProgressTime The time the progress was achieved.
  -- @oaram #number ProgressPoints The amount of points of magnitude granted. This will determine the shared Mission Success scoring.
  -- @return #TASK
  function TASK:AddProgress( PlayerName, ProgressText, ProgressTime, ProgressPoints )
    self.TaskProgress = self.TaskProgress or {}
    self.TaskProgress[ProgressTime] = self.TaskProgress[ProgressTime] or {}
    self.TaskProgress[ProgressTime].PlayerName = PlayerName
    self.TaskProgress[ProgressTime].ProgressText = ProgressText
    self.TaskProgress[ProgressTime].ProgressPoints = ProgressPoints
    self:GetMission():AddPlayerName( PlayerName )
    return self
  end
  
  function TASK:GetPlayerProgress( PlayerName )
    local ProgressPlayer = 0
    for ProgressTime, ProgressData in pairs( self.TaskProgress ) do
      if PlayerName == ProgressData.PlayerName then
        ProgressPlayer = ProgressPlayer + ProgressData.ProgressPoints
      end
    end
    return ProgressPlayer
  end

  --- Set a score when progress has been made by the player.
  -- @param #TASK self
  -- @param #string PlayerName The name of the player.
  -- @param #number Score The score in points to be granted when task process has been achieved.
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK
  function TASK:SetScoreOnProgress( PlayerName, Score, TaskUnit )
    self:F( { PlayerName, Score, TaskUnit } )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    ProcessUnit:AddScoreProcess( "Engaging", "Account", "AccountPlayer", "Player " .. PlayerName .. " has achieved progress.", Score )
    
    return self
  end

  --- Set a score when all the targets in scope of the A2A attack, have been destroyed.
  -- @param #TASK self
  -- @param #string PlayerName The name of the player.
  -- @param #number Score The score in points.
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK
  function TASK:SetScoreOnSuccess( PlayerName, Score, TaskUnit )
    self:F( { PlayerName, Score, TaskUnit } )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    ProcessUnit:AddScore( "Success", "The task is a success!", Score )
    
    return self
  end

  --- Set a penalty when the A2A attack has failed.
  -- @param #TASK self
  -- @param #string PlayerName The name of the player.
  -- @param #number Penalty The penalty in points, must be a negative value!
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK
  function TASK:SetScoreOnFail( PlayerName, Penalty, TaskUnit )
    self:F( { PlayerName, Penalty, TaskUnit } )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    ProcessUnit:AddScore( "Failed", "The task is a failure!", Penalty )
    
    return self
  end

end

do -- Task Control Menu
  
  -- The Task Control Menu is a menu attached to the task at the main menu to quickly be able to do actions in the task.
  -- The Task Control Menu can only be shown when the task is assigned to the player.
  -- The Task Control Menu is linked to the process executing the task, so no task menu can be set to the main static task definition.
  
  --- Init Task Control Menu
  -- @param #TASK self
  -- @param Wrapper.Unit#UNIT TaskUnit The @{Wrapper.Unit} that contains a player.
  -- @return Task Control Menu Refresh ID
  function TASK:InitTaskControlMenu( TaskUnit )

    self.TaskControlMenuTime = timer.getTime()
    
    return self.TaskControlMenuTime
  end
  
  --- Get Task Control Menu
  -- @param #TASK self
  -- @param Wrapper.Unit#UNIT TaskUnit The @{Wrapper.Unit} that contains a player.
  -- @return Core.Menu#MENU_GROUP TaskControlMenu The Task Control Menu
  function TASK:GetTaskControlMenu( TaskUnit, TaskName )
  
    TaskName = TaskName or ""
    
    local TaskGroup = TaskUnit:GetGroup()
    local TaskPlayerCount = TaskGroup:GetPlayerCount()
    
    if TaskPlayerCount <= 1 then
      self.TaskControlMenu = MENU_GROUP:New( TaskUnit:GetGroup(), "Task " .. self:GetName() .. " control" ):SetTime( self.TaskControlMenuTime )
    else
      self.TaskControlMenu = MENU_GROUP:New( TaskUnit:GetGroup(), "Task " .. self:GetName() .. " control for " .. TaskUnit:GetPlayerName() ):SetTime( self.TaskControlMenuTime )
    end
    
    return self.TaskControlMenu
  end

  --- Remove Task Control Menu
  -- @param #TASK self
  -- @param Wrapper.Unit#UNIT TaskUnit The @{Wrapper.Unit} that contains a player.
  function TASK:RemoveTaskControlMenu( TaskUnit )
  
    if self.TaskControlMenu then
      self.TaskControlMenu:Remove()
      self.TaskControlMenu = nil
    end
  end
  
  --- Refresh Task Control Menu
  -- @param #TASK self
  -- @param Wrapper.Unit#UNIT TaskUnit The @{Wrapper.Unit} that contains a player.
  -- @param MenuTime The refresh time that was used to refresh the Task Control Menu items.
  -- @param MenuTag The tag.
  function TASK:RefreshTaskControlMenu( TaskUnit, MenuTime, MenuTag )
  
    if self.TaskControlMenu then
      self.TaskControlMenu:Remove( MenuTime, MenuTag )
    end
  end
  
end
