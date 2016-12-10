--- This module contains the TASK_BASE class.
-- 
-- 1) @{#TASK_BASE} class, extends @{Core.Base#BASE}
-- ============================================
-- 1.1) The @{#TASK_BASE} class implements the methods for task orchestration within MOOSE. 
-- ----------------------------------------------------------------------------------------
-- The class provides a couple of methods to:
-- 
--   * @{#TASK_BASE.AssignToGroup}():Assign a task to a group (of players).
--   * @{#TASK_BASE.AddProcess}():Add a @{Process} to a task.
--   * @{#TASK_BASE.RemoveProcesses}():Remove a running @{Process} from a running task.
--   * @{#TASK_BASE.SetStateMachine}():Set a @{Fsm} to a task.
--   * @{#TASK_BASE.RemoveStateMachine}():Remove @{Fsm} from a task.
--   * @{#TASK_BASE.HasStateMachine}():Enquire if the task has a @{Fsm}
--   * @{#TASK_BASE.AssignToUnit}(): Assign a task to a unit. (Needs to be implemented in the derived classes from @{#TASK_BASE}.
--   * @{#TASK_BASE.UnAssignFromUnit}(): Unassign the task from a unit.
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
-- Use the method @{#TASK_BASE.AddScore}() to add scores when a status is reached.
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

--- The TASK_BASE class
-- @type TASK_BASE
-- @field Core.Scheduler#SCHEDULER TaskScheduler
-- @field Tasking.Mission#MISSION Mission
-- @field Core.Set#SET_GROUP SetGroup The Set of Groups assigned to the Task
-- @field Fsm.Fsm#FSM_PROCESS FsmTemplate
-- @extends Fsm.Fsm#FSM_TASK
TASK_BASE = {
  ClassName = "TASK_BASE",
  TaskScheduler = nil,
  ProcessClasses = {}, -- The container of the Process classes that will be used to create and assign new processes for the task to ProcessUnits.
  Processes = {}, -- The container of actual process objects instantiated and assigned to ProcessUnits.
  Players = nil,
  Scores = {},
  Menu = {},
  SetGroup = nil,
  FsmTemplate = nil,
}

--- Instantiates a new TASK_BASE. Should never be used. Interface Class.
-- @param #TASK_BASE self
-- @param Tasking.Mission#MISSION Mission The mission wherein the Task is registered.
-- @param Core.Set#SET_GROUP SetGroupAssign The set of groups for which the Task can be assigned.
-- @param #string TaskName The name of the Task
-- @param #string TaskType The type of the Task
-- @return #TASK_BASE self
function TASK_BASE:New( Mission, SetGroupAssign, TaskName, TaskType )

  local self = BASE:Inherit( self, FSM_TASK:New() ) -- Fsm.Fsm#FSM_TASK

  self:SetStartState( "Planned" )
  self:AddTransition( "Planned", "Assign", "Assigned" )
  self:AddTransition( "Assigned", "AssignUnit", "Assigned" )
  self:AddTransition( "Assigned", "Success", "Success" )
  self:AddTransition( "Assigned", "Fail", "Failed" )
  self:AddTransition( "Assigned", "Abort", "Aborted" )
  self:AddTransition( "Assigned", "Cancel", "Cancelled" )
  self:AddTransition( { "Failed", "Aborted", "Cancelled" }, "Replan", "Planned" )

  self:E( "New TASK " .. TaskName )

  self.Processes = {}
  self.Fsm = {}

  self.Mission = Mission
  
  self.SetGroup = SetGroupAssign

  self:SetType( TaskType )
  self:SetName( TaskName )
  self:SetID( Mission:GetNextTaskID( self ) ) -- The Mission orchestrates the task sequences ..

  self.TaskBriefing = "You are invited for the task: " .. self.TaskName .. "."
  
  self.FsmTemplate = self.FsmTemplate or FSM_PROCESS:New()

  -- Handle the birth of new planes within the assigned set.
  self:EventOnPlayerEnterUnit(
    --- @param #TASK_BASE self
    -- @param Core.Event#EVENTDATA EventData
    function( self, EventData )
      self:E( EventData )
      self:E( { "State", self:GetState() } )
      local TaskUnit = EventData.IniUnit
      local TaskGroup = EventData.IniUnit:GetGroup()
      self:SetMenuForGroup(TaskGroup)
      if self:IsStateAssigned() then
        self:E( self:IsAssignedToGroup( TaskGroup ) )
        if self:IsAssignedToGroup( TaskGroup ) then
          self:AssignToUnit( TaskUnit )
        end
      end
      self:MessageToGroups( TaskUnit:GetPlayerName() .. " joined Task " .. self:GetName() )
    end
  )

  -- Handle when a player leaves a slot and goes back to spectators ... 
  -- The Task is UnAssigned from the Unit.
  -- When there is no Unit left running the Task, the Task goes into Abort...
  self:EventOnPlayerLeaveUnit(
    --- @param #TASK_BASE self
    -- @param Core.Event#EVENTDATA EventData
    function( self, EventData )
      self:E( "In LeaveUnit" )
      self:E( { "State", self:GetState() } )
      if self:IsStateAssigned() then
        local TaskUnit = EventData.IniUnit
        local TaskGroup = EventData.IniUnit:GetGroup()
        self:E( self.SetGroup:IsIncludeObject( TaskGroup ) )
        if self.SetGroup:IsIncludeObject( TaskGroup ) then
          self:UnAssignFromUnit( TaskUnit )
        end
        self:MessageToGroups( TaskUnit:GetPlayerName() .. " aborted Task " .. self:GetName() )
      end
    end
  )

  -- Handle when a player crashes ... 
  -- The Task is UnAssigned from the Unit.
  -- When there is no Unit left running the Task, and all of the Players crashed, the Task goes into Failed ...
  self:EventOnCrash(
    --- @param #TASK_BASE self
    -- @param Core.Event#EVENTDATA EventData
    function( self, EventData )
      self:E( "In LeaveUnit" )
      self:E( { "State", self:GetState() } )
      if self:IsStateAssigned() then
        local TaskUnit = EventData.IniUnit
        local TaskGroup = EventData.IniUnit:GetGroup()
        self:E( self.SetGroup:IsIncludeObject( TaskGroup ) )
        if self.SetGroup:IsIncludeObject( TaskGroup ) then
          self:UnAssignFromUnit( TaskUnit )
        end
        self:MessageToGroups( TaskUnit:GetPlayerName() .. " crashed!, and has aborted Task " .. self:GetName() )
      end
    end
  )
  
  Mission:AddTask( self )
  
  return self
end

--- Get the Task FSM Process Template
-- @param #TASK_BASE self
-- @return Fsm.Fsm#FSM_PROCESS
function TASK_BASE:GetFsmTemplate()

  return self.FsmTemplate
end

--- Sets the Task FSM Process Template
-- @param #TASK_BASE self
-- @param Fsm.Fsm#FSM_PROCESS
function TASK_BASE:SetFsmTemplate( FsmTemplate )

  self.FsmTemplate = FsmTemplate
end

--- Gets the Mission to where the TASK belongs.
-- @param #TASK_BASE self
-- @return Tasking.Mission#MISSION
function TASK_BASE:GetMission()

  return self.Mission
end

--- Gets the SET_GROUP assigned to the TASK.
-- @param #TASK_BASE self
-- @return Core.Set#SET_GROUP
function TASK_BASE:GetGroups()
  return self.SetGroup
end



--- Assign the @{Task}to a @{Group}.
-- @param #TASK_BASE self
-- @param Wrapper.Group#GROUP TaskGroup
-- @return #TASK_BASE
function TASK_BASE:AssignToGroup( TaskGroup )
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
-- @param #TASK_BASE self
-- @param Wrapper.Group#GROUP FindGroup
-- @return #boolean
function TASK_BASE:HasGroup( FindGroup )

  return self:GetGroups():IsIncludeObject( FindGroup )

end

--- Assign the @{Task} to an alive @{Unit}.
-- @param #TASK_BASE self
-- @param Wrapper.Unit#UNIT TaskUnit
-- @return #TASK_BASE self
function TASK_BASE:AssignToUnit( TaskUnit )
  self:F( TaskUnit:GetName() )
  
  local FsmTemplate = self:GetFsmTemplate()
  
  -- Assign a new FsmUnit to TaskUnit.
  local FsmUnit = self:SetStateMachine( TaskUnit, FsmTemplate:Copy( TaskUnit, self ) ) -- Fsm.Fsm#FSM_PROCESS
  self:E({"Address FsmUnit", tostring( FsmUnit ) } )
  
  FsmUnit:SetStartState( "Planned" )
  FsmUnit:Accept() -- Each Task needs to start with an Accept event to start the flow.

  return self
end

--- UnAssign the @{Task} from an alive @{Unit}.
-- @param #TASK_BASE self
-- @param Wrapper.Unit#UNIT TaskUnit
-- @return #TASK_BASE self
function TASK_BASE:UnAssignFromUnit( TaskUnit )
  self:F( TaskUnit )
  
  self:RemoveStateMachine( TaskUnit )

  return self
end

--- Send a message of the @{Task} to the assigned @{Group}s.
-- @param #TASK_BASE self
function TASK_BASE:MessageToGroups( Message )

  local Mission = self:GetMission()
  local CC = Mission:GetCommandCenter()
  
  for TaskGroupName, TaskGroup in pairs( self.SetGroup:GetSet() ) do
    CC:MessageToGroup( Message , 60, TaskGroup )
  end
end

--- Send the briefng message of the @{Task} to the assigned @{Group}s.
-- @param #TASK_BASE self
function TASK_BASE:SendBriefingToAssignedGroups()
  self:F2()
  
  for TaskGroupName, TaskGroup in pairs( self.SetGroup:GetSet() ) do

    if self:IsAssignedToGroup( TaskGroup ) then    
      TaskGroup:Message( self.TaskBriefing, 60 )
    end
  end
end


--- Assign the @{Task} from the @{Group}s.
-- @param #TASK_BASE self
function TASK_BASE:UnAssignFromGroups()
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
-- @param #TASK_BASE self
-- @param Wrapper.Group#GROUP TaskGroup
-- @return #boolean
function TASK_BASE:IsAssignedToGroup( TaskGroup )

  local TaskGroupName = TaskGroup:GetName()
  
  if self:IsStateAssigned() then
    if TaskGroup:GetState( TaskGroup, "Assigned" ) == self then
      return true
    end
  end
  
  return false
end

--- Set the menu options of the @{Task} to all the groups in the SetGroup.
-- @param #TASK_BASE self
function TASK_BASE:SetMenu()

  for TaskGroupID, TaskGroup in pairs( self.SetGroup:GetSet() ) do
    if self:IsStatePlanned() or self:IsStateReplanned() then
      self:SetMenuForGroup( TaskGroup )
    end
  end  
end


--- Remove the menu options of the @{Task} to all the groups in the SetGroup.
-- @param #TASK_BASE self
-- @return #TASK_BASE self
function TASK_BASE:RemoveMenu()

  for TaskGroupID, TaskGroup in pairs( self.SetGroup:GetSet() ) do
    self:RemoveMenuForGroup( TaskGroup )
  end
end


--- Set the Menu for a Group
-- @param #TASK_BASE self
function TASK_BASE:SetMenuForGroup( TaskGroup )

  if not self:IsAssignedToGroup( TaskGroup ) then
    self:SetPlannedMenuForGroup( TaskGroup, self:GetTaskName() )
  else
    self:SetAssignedMenuForGroup( TaskGroup )
  end
end


--- Set the planned menu option of the @{Task}.
-- @param #TASK_BASE self
-- @param Wrapper.Group#GROUP TaskGroup
-- @param #string MenuText The menu text.
-- @return #TASK_BASE self
function TASK_BASE:SetPlannedMenuForGroup( TaskGroup, MenuText )
  self:E( TaskGroup:GetName() )

  local Mission = self:GetMission()
  local MissionMenu = Mission:GetMissionMenu( TaskGroup )

  local TaskType = self:GetType()
  local TaskTypeMenu = MENU_GROUP:New( TaskGroup, TaskType, MissionMenu )
  local TaskMenu = MENU_GROUP_COMMAND:New( TaskGroup, MenuText, TaskTypeMenu, self.MenuAssignToGroup, { self = self, TaskGroup = TaskGroup } )
      
  return self
end

--- Set the assigned menu options of the @{Task}.
-- @param #TASK_BASE self
-- @param Wrapper.Group#GROUP TaskGroup
-- @return #TASK_BASE self
function TASK_BASE:SetAssignedMenuForGroup( TaskGroup )
  self:E( TaskGroup:GetName() )

  local Mission = self:GetMission()
  local MissionMenu = Mission:GetMissionMenu( TaskGroup )

  self:E( { MissionMenu = MissionMenu } )

  local TaskTypeMenu = MENU_GROUP_COMMAND:New( TaskGroup, "Task Status", MissionMenu, self.MenuTaskStatus, { self = self, TaskGroup = TaskGroup } )
  local TaskMenu = MENU_GROUP_COMMAND:New( TaskGroup, "Abort Task", MissionMenu, self.MenuTaskAbort, { self = self, TaskGroup = TaskGroup } )

  return self
end

--- Remove the menu option of the @{Task} for a @{Group}.
-- @param #TASK_BASE self
-- @param Wrapper.Group#GROUP TaskGroup
-- @return #TASK_BASE self
function TASK_BASE:RemoveMenuForGroup( TaskGroup )

  local Mission = self:GetMission()
  local MissionName = Mission:GetName()

  local MissionMenu = Mission:GetMissionMenu( TaskGroup )
  MissionMenu:Remove()
end

function TASK_BASE.MenuAssignToGroup( MenuParam )

  local self = MenuParam.self
  local TaskGroup = MenuParam.TaskGroup
  
  self:E( "Assigned menu selected")
  
  self:AssignToGroup( TaskGroup )
end

function TASK_BASE.MenuTaskStatus( MenuParam )

  local self = MenuParam.self
  local TaskGroup = MenuParam.TaskGroup
  
  --self:AssignToGroup( TaskGroup )
end

function TASK_BASE.MenuTaskAbort( MenuParam )

  local self = MenuParam.self
  local TaskGroup = MenuParam.TaskGroup
  
  --self:AssignToGroup( TaskGroup )
end



--- Returns the @{Task} name.
-- @param #TASK_BASE self
-- @return #string TaskName
function TASK_BASE:GetTaskName()
  return self.TaskName
end




--- Get the default or currently assigned @{Process} template with key ProcessName.
-- @param #TASK_BASE self
-- @param #string ProcessName
-- @return Fsm.Fsm#FSM_PROCESS
function TASK_BASE:GetProcessTemplate( ProcessName )

  local ProcessTemplate = self.ProcessClasses[ProcessName]
  
  return ProcessTemplate
end



-- TODO: Obscolete?
--- Fail processes from @{Task} with key @{Unit}
-- @param #TASK_BASE self
-- @param #string TaskUnitName
-- @return #TASK_BASE self
function TASK_BASE:FailProcesses( TaskUnitName )

  for ProcessID, ProcessData in pairs( self.Processes[TaskUnitName] ) do
    local Process = ProcessData 
    Process.Fsm:Fail()
  end
end

--- Add a FiniteStateMachine to @{Task} with key Task@{Unit}
-- @param #TASK_BASE self
-- @param Wrapper.Unit#UNIT TaskUnit
-- @return #TASK_BASE self
function TASK_BASE:SetStateMachine( TaskUnit, Fsm )
  self:F( { TaskUnit, self.Fsm[TaskUnit] ~= nil } )

  self.Fsm[TaskUnit] = Fsm
    
  return Fsm
end

--- Remove FiniteStateMachines from @{Task} with key Task@{Unit}
-- @param #TASK_BASE self
-- @param Wrapper.Unit#UNIT TaskUnit
-- @return #TASK_BASE self
function TASK_BASE:RemoveStateMachine( TaskUnit )
  self:F( { TaskUnit, self.Fsm[TaskUnit] ~= nil } )

  self.Fsm[TaskUnit] = nil
  collectgarbage()
end

--- Checks if there is a FiniteStateMachine assigned to Task@{Unit} for @{Task}
-- @param #TASK_BASE self
-- @param Wrapper.Unit#UNIT TaskUnit
-- @return #TASK_BASE self
function TASK_BASE:HasStateMachine( TaskUnit )
  self:F( { TaskUnit, self.Fsm[TaskUnit] ~= nil } )

  return ( self.Fsm[TaskUnit] ~= nil )
end





--- Register a potential new assignment for a new spawned @{Unit}.
-- Tasks only get assigned if there are players in it.
-- @param #TASK_BASE self
-- @param Core.Event#EVENTDATA Event
-- @return #TASK_BASE self
function TASK_BASE:_EventAssignUnit( Event )
  if Event.IniUnit then
    self:F( Event )
    local TaskUnit = Event.IniUnit
    if TaskUnit:IsAlive() then
      local TaskPlayerName = TaskUnit:GetPlayerName()
      if TaskPlayerName ~= nil then
        if not self:HasStateMachine( TaskUnit ) then
          -- Check if the task was assigned to the group, if it was assigned to the group, assign to the unit just spawned and initiate the processes.
          local TaskGroup = TaskUnit:GetGroup()
          if self:IsAssignedToGroup( TaskGroup ) then
            self:AssignToUnit( TaskUnit )
          end
        end
      end
    end
  end
  return nil
end

--- Catches the "player leave unit" event for a @{Unit}  ....
-- When a player is an air unit, and leaves the unit:
-- 
--   * and he is not at an airbase runway on the ground, he will fail its task.
--   * and he is on an airbase and on the ground, the process for him will just continue to work, he can switch airplanes, and take-off again.
-- This is important to model the change from plane types for a player during mission assignment.
-- @param #TASK_BASE self
-- @param Core.Event#EVENTDATA Event
-- @return #TASK_BASE self
function TASK_BASE:_EventPlayerLeaveUnit( Event )
  self:F( Event )
  if Event.IniUnit then
    local TaskUnit = Event.IniUnit
    local TaskUnitName = Event.IniUnitName
    
    -- Check if for this unit in the task there is a process ongoing.
    if self:HasStateMachine( TaskUnitName ) then
      if TaskUnit:IsAir() then
        if TaskUnit:IsAboveRunway() then
          -- do nothing
        else
          self:E( "IsNotAboveRunway" )
            -- Player left airplane during an assigned task and was not at an airbase.
            self:FailProcesses( TaskUnitName )
            self:UnAssignFromUnit( TaskUnitName )
          end
        end
      end
    
  end
  return nil
end

--- UnAssigns a @{Unit} that is left by a player, crashed, dead, ....
-- There are only assignments if there are players in it.
-- @param #TASK_BASE self
-- @param Core.Event#EVENTDATA Event
-- @return #TASK_BASE self
function TASK_BASE:_EventDead( Event )
  self:F( Event )
  if Event.IniUnit then
    local TaskUnit = Event.IniUnit
    local TaskUnitName = Event.IniUnitName

    -- Check if for this unit in the task there is a process ongoing.
    if self:HasStateMachine( TaskUnitName ) then
      self:FailProcesses( TaskUnitName )
      self:UnAssignFromUnit( TaskUnitName )
    end
    
    local TaskGroup = Event.IniUnit:GetGroup()
    TaskGroup:SetState( TaskGroup, "Assigned", nil )
  end
  return nil
end

--- Gets the Scoring of the task
-- @param #TASK_BASE self
-- @return Functional.Scoring#SCORING Scoring
function TASK_BASE:GetScoring()
  return self.Mission:GetScoring()
end


--- Gets the Task Index, which is a combination of the Task type, the Task name.
-- @param #TASK_BASE self
-- @return #string The Task ID
function TASK_BASE:GetTaskIndex()

  local TaskType = self:GetType()
  local TaskName = self:GetName()

  return TaskType .. "." .. TaskName
end

--- Sets the Name of the Task
-- @param #TASK_BASE self
-- @param #string TaskName
function TASK_BASE:SetName( TaskName )
  self.TaskName = TaskName
end

--- Gets the Name of the Task
-- @param #TASK_BASE self
-- @return #string The Task Name
function TASK_BASE:GetName()
  return self.TaskName
end

--- Sets the Type of the Task
-- @param #TASK_BASE self
-- @param #string TaskType
function TASK_BASE:SetType( TaskType )
  self.TaskType = TaskType
end

--- Gets the Type of the Task
-- @param #TASK_BASE self
-- @return #string TaskType
function TASK_BASE:GetType()
  return self.TaskType
end

--- Sets the ID of the Task
-- @param #TASK_BASE self
-- @param #string TaskID
function TASK_BASE:SetID( TaskID )
  self.TaskID = TaskID
end

--- Gets the ID of the Task
-- @param #TASK_BASE self
-- @return #string TaskID
function TASK_BASE:GetID()
  return self.TaskID
end


--- Sets a @{Task} to status **Success**.
-- @param #TASK_BASE self
function TASK_BASE:StateSuccess()
  self:SetState( self, "State", "Success" )
  return self
end

--- Is the @{Task} status **Success**.
-- @param #TASK_BASE self
function TASK_BASE:IsStateSuccess()
  return self:Is( "Success" )
end

--- Sets a @{Task} to status **Failed**.
-- @param #TASK_BASE self
function TASK_BASE:StateFailed()
  self:SetState( self, "State", "Failed" )
  return self
end

--- Is the @{Task} status **Failed**.
-- @param #TASK_BASE self
function TASK_BASE:IsStateFailed()
  return self:Is( "Failed" )
end

--- Sets a @{Task} to status **Planned**.
-- @param #TASK_BASE self
function TASK_BASE:StatePlanned()
  self:SetState( self, "State", "Planned" )
  return self
end

--- Is the @{Task} status **Planned**.
-- @param #TASK_BASE self
function TASK_BASE:IsStatePlanned()
  return self:Is( "Planned" )
end

--- Sets a @{Task} to status **Assigned**.
-- @param #TASK_BASE self
function TASK_BASE:StateAssigned()
  self:SetState( self, "State", "Assigned" )
  return self
end

--- Is the @{Task} status **Assigned**.
-- @param #TASK_BASE self
function TASK_BASE:IsStateAssigned()
  return self:Is( "Assigned" )
end

--- Sets a @{Task} to status **Hold**.
-- @param #TASK_BASE self
function TASK_BASE:StateHold()
  self:SetState( self, "State", "Hold" )
  return self
end

--- Is the @{Task} status **Hold**.
-- @param #TASK_BASE self
function TASK_BASE:IsStateHold()
  return self:Is( "Hold" )
end

--- Sets a @{Task} to status **Replanned**.
-- @param #TASK_BASE self
function TASK_BASE:StateReplanned()
  self:SetState( self, "State", "Replanned" )
  return self
end

--- Is the @{Task} status **Replanned**.
-- @param #TASK_BASE self
function TASK_BASE:IsStateReplanned()
  return self:Is( "Replanned" )
end

--- Gets the @{Task} status.
-- @param #TASK_BASE self
function TASK_BASE:GetStateString()
  return self:GetState( self, "State" )
end

--- Sets a @{Task} briefing.
-- @param #TASK_BASE self
-- @param #string TaskBriefing
-- @return #TASK_BASE self
function TASK_BASE:SetBriefing( TaskBriefing )
  self.TaskBriefing = TaskBriefing
  return self
end



--- Adds a score for the TASK to be achieved.
-- @param #FSM_TEMPLATE self
-- @param #string TaskStatus is the status of the TASK when the score needs to be given.
-- @param #string ScoreText is a text describing the score that is given according the status.
-- @param #number Score is a number providing the score of the status.
-- @return #FSM_TEMPLATE self
function TASK_BASE:AddScoreTask( TaskStatus, ScoreText, Score )
  self:F2( { TaskStatus, ScoreText, Score } )

  self.Scores[TaskStatus] = self.Scores[TaskStatus] or {}
  self.Scores[TaskStatus].ScoreText = ScoreText
  self.Scores[TaskStatus].Score = Score
  return self
end


--- StateMachine callback function for a TASK
-- @param #TASK_BASE self
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Core.Event#EVENTDATA Event
function TASK_BASE:onenterAssigned( Event, From, To )

  self:E("Assigned")
  
  
    
end


--- StateMachine callback function for a TASK
-- @param #TASK_BASE self
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Core.Event#EVENTDATA Event
function TASK_BASE:onenterSuccess( Event, From, To )

  self:E("Success")
  
  local Mission = self:GetMission()
  local CC = Mission:GetCommandCenter()
  
  for TaskGroupName, TaskGroup in pairs( self.SetGroup:GetSet() ) do
    CC:GetPositionable():MessageToGroup( "Task " .. self:GetName() .. " is successful! Good job!" , 60, TaskGroup )
  end
  
  self:UnAssignFromGroups()
  
  CC:SetMenu()
  
end

--- StateMachine callback function for a TASK
-- @param #TASK_BASE self
-- @param Wrapper.Unit#UNIT TaskUnit
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Core.Event#EVENTDATA Event
function TASK_BASE:onenterFailed( TaskUnit, Event, From, To )

  self:E( { "Failed for unit ", TaskUnit:GetName(), TaskUnit:GetPlayerName() } )
  
  -- A task cannot be "failed", so a task will always be there waiting for players to join.
  -- When the player leaves its unit, we will need to check whether he was on the ground or not at an airbase.
  -- When the player crashes, we will need to check whether in the group there are other players still active. It not, we reset the task from Assigned to Planned, otherwise, we just leave as Assigned.

  self:UnAssignFromUnit()

end

--- StateMachine callback function for a TASK
-- @param #TASK_BASE self
-- @param Wrapper.Unit#UNIT TaskUnit
-- @param Fsm.Fsm#FSM_TASK Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Core.Event#EVENTDATA Event
function TASK_BASE:onstatechange( Event, From, To )

  if self:IsTrace() then
    MESSAGE:New( "Task " .. self.TaskName .. " : " .. Event .. " changed to state " .. To, 15 ):ToAll()
  end

  if self.Scores[To] then
    local Scoring = self:GetScoring()
    if Scoring then
      self:E( { self.Scores[To].ScoreText, self.Scores[To].Score } )
      Scoring:_AddMissionScore( self.Mission, self.Scores[To].ScoreText, self.Scores[To].Score )
    end
  end

end


--- @param #TASK_BASE self
function TASK_BASE:_Schedule()
  self:F2()

  self.TaskScheduler = SCHEDULER:New( self, _Scheduler, {}, 15, 15 )
  return self
end


--- @param #TASK_BASE self
function TASK_BASE._Scheduler()
  self:F2()

  return true
end




