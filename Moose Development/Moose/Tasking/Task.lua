--- This module contains the TASK_BASE class.
-- 
-- 1) @{#TASK_BASE} class, extends @{Base#BASE}
-- ============================================
-- 1.1) The @{#TASK_BASE} class implements the methods for task orchestration within MOOSE. 
-- ----------------------------------------------------------------------------------------
-- The class provides a couple of methods to:
-- 
--   * @{#TASK_BASE.AssignToGroup}():Assign a task to a group (of players).
--   * @{#TASK_BASE.AddProcess}():Add a @{Process} to a task.
--   * @{#TASK_BASE.RemoveProcesses}():Remove a running @{Process} from a running task.
--   * @{#TASK_BASE.SetStateMachine}():Set a @{StateMachine} to a task.
--   * @{#TASK_BASE.RemoveStateMachine}():Remove @{StateMachine} from a task.
--   * @{#TASK_BASE.HasStateMachine}():Enquire if the task has a @{StateMachine}
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
-- @field Scheduler#SCHEDULER TaskScheduler
-- @field Mission#MISSION Mission
-- @field StateMachine#STATEMACHINE Fsm
-- @field Set#SET_GROUP SetGroup The Set of Groups assigned to the Task
-- @extends Core.StateMachine#STATEMACHINE_TASK
TASK_BASE = {
  ClassName = "TASK_BASE",
  TaskScheduler = nil,
  ProcessClasses = {}, -- The container of the Process classes that will be used to create and assign new processes for the task to ProcessUnits.
  Processes = {}, -- The container of actual process objects instantiated and assigned to ProcessUnits.
  Players = nil,
  Scores = {},
  Menu = {},
  SetGroup = nil,
}

--- Instantiates a new TASK_BASE. Should never be used. Interface Class.
-- @param #TASK_BASE self
-- @param Mission#MISSION Mission The mission wherein the Task is registered.
-- @param Set#SET_GROUP SetGroupAssign The set of groups for which the Task can be assigned.
-- @param #string TaskName The name of the Task
-- @param #string TaskType The type of the Task
-- @param #string TaskCategory The category of the Task (A2G, A2A, Transport, ... )
-- @return #TASK_BASE self
function TASK_BASE:New( Mission, SetGroupAssign, TaskName, TaskType, TaskCategory )


  local self = BASE:Inherit( self, STATEMACHINE_TASK:New( {} ) )

  self:SetInitialState( "Planned" )
  self:AddAction( "Planned", "Assign", "Assigned" )
  self:AddAction( "Assigned", "Success", "Success" )
  self:AddAction( "*", "Fail", "Failed" )

  self:E( "New TASK " .. TaskName )

  self.Processes = {}
  self.Fsm = {}

  self.Mission = Mission
  self.SetGroup = SetGroupAssign

  self:SetCategory( TaskCategory )
  self:SetType( TaskType )
  self:SetName( TaskName )
  self:SetID( Mission:GetNextTaskID( self ) ) -- The Mission orchestrates the task sequences ..

  self.TaskBriefing = "You are invited for the task: " .. self.TaskName .. "."

  self.FsmTemplate = self.FsmTemplate or STATEMACHINE_PROCESS:New( {} )
  self.FsmTemplate:SetTask( self )
  
  return self
end

--- Gets the SET_GROUP assigned to the TASK.
-- @param #TASK_BASE self
-- @return Core.Set#SET_GROUP
function TASK_BASE:GetGroups()
  return self.SetGroup
end

--- Cleans all references of a TASK_BASE.
-- @param #TASK_BASE self
-- @return #nil
function TASK_BASE:CleanUp()

  _EVENTDISPATCHER:OnPlayerLeaveRemove( self )
  _EVENTDISPATCHER:OnDeadRemove( self )
  _EVENTDISPATCHER:OnCrashRemove( self )
  _EVENTDISPATCHER:OnPilotDeadRemove( self )
  
  return nil
end

function TASK_BASE:GetFsmTemplate()

  return self.FsmTemplate
end

--- Assign the @{Task}to a @{Group}.
-- @param #TASK_BASE self
-- @param Group#GROUP TaskGroup
-- @return #TASK_BASE
function TASK_BASE:AssignToGroup( TaskGroup )
  self:F2( TaskGroup:GetName() )
  
  local TaskGroupName = TaskGroup:GetName()
  
  TaskGroup:SetState( TaskGroup, "Assigned", self )
  
  self:RemoveMenuForGroup( TaskGroup )
  self:SetAssignedMenuForGroup( TaskGroup )
  
  local TaskUnits = TaskGroup:GetUnits()
  for UnitID, UnitData in pairs( TaskUnits ) do
    local TaskUnit = UnitData -- Unit#UNIT
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
-- @param Unit#UNIT TaskUnit
-- @return #TASK_BASE self
function TASK_BASE:AssignToUnit( TaskUnit )
  self:F( TaskUnit:GetName() )
  
  -- Copy the FsmTemplate, which is not assigned to a Unit.
  -- Assign the FsmTemplate to the TaskUnit.
  local FsmTemplate = self:GetFsmTemplate()
  local FsmUnit = UTILS.DeepCopy( FsmTemplate )
  FsmUnit:Assign( self, TaskUnit )
  
  -- Assign each FsmSub in FsmUnit to the TaskUnit.
  -- (This is not done during the copy).
  self:E(FsmUnit:GetSubs())
  for FsmSubID, FsmSub in pairs( FsmUnit:GetSubs() ) do
    self:E( { "Sub ID", FsmSub.fsm:GetClassNameAndID(), FsmSubID } )
    FsmSub.fsm:Assign( self, TaskUnit )
    --FsmSub.fsm:_SetDestructor()
    
    
    --FsmSub.fsm = nil
    --collectgarbage()
  end
  
  
--  for TransitionID, TransitionTemplate in ipairs( self.TransitionTemplates ) do
--    self:E( TransitionTemplate )
--    FSM:AddTransition( TransitionTemplate.From, TransitionTemplate.Event, TransitionTemplate.To )
--  end
  
  -- Copy each ProcessTemplate for the TaskUnit that is alive, as set as a template at the Parent.
  -- Each Process will start From a state, upon a fired Event.
  -- Upon finalization of the Process, the ReturnEvents contain for which Return state which Event of the Parent needs to be fired.
  -- The Return state of the Process is transferred to the Parent.
--  for ProcessID, ProcessTemplate in ipairs( self.ProcessTemplates ) do
--    FSM:AddProcess( ProcessTemplate.From, ProcessTemplate.Event, Process, ProcessTemplate.ReturnEvents )
--    self:E( { "Process ID", Process:GetClassNameAndID() } )
--    Process:Assign( self, TaskUnit )
--  end

  FsmUnit:SetInitialState( "Planned" )
  FsmUnit:Accept() -- Each Task needs to start with an Accept event to start the flow.
  
  

  return self
end

--- UnAssign the @{Task} from an alive @{Unit}.
-- @param #TASK_BASE self
-- @param Unit#UNIT TaskUnit
-- @return #TASK_BASE self
function TASK_BASE:UnAssignFromUnit( TaskUnitName )
  self:F( TaskUnitName )
  
  if self:HasStateMachine( TaskUnitName ) == true then
    self:E("RemoveStateMachines")
    self:RemoveStateMachine( TaskUnitName )
  end

  return self
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
    local TaskUnits = TaskGroup:GetUnits()
    for UnitID, UnitData in pairs( TaskUnits ) do
      local TaskUnit = UnitData -- Wrapper.Unit#UNIT
      local PlayerName = TaskUnit:GetPlayerName()
      if PlayerName ~= nil or PlayerName ~= "" then
        self:UnAssignFromUnit( TaskUnit:GetName() )
      end
    end
  end
end

--- Returns if the @{Task} is assigned to the Group.
-- @param #TASK_BASE self
-- @param Group#GROUP TaskGroup
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
-- @return #TASK_BASE self
function TASK_BASE:SetPlannedMenu()

  local MenuText = self:GetPlannedMenuText()
  for TaskGroupID, TaskGroup in pairs( self.SetGroup:GetSet() ) do
    if not self:IsAssignedToGroup( TaskGroup ) then
      self:SetPlannedMenuForGroup( TaskGroup, MenuText )
    end
  end  
end

--- Set the menu options of the @{Task} to all the groups in the SetGroup.
-- @param #TASK_BASE self
-- @return #TASK_BASE self
function TASK_BASE:SetAssignedMenu()

  for TaskGroupID, TaskGroup in pairs( self.SetGroup:GetSet() ) do
    if self:IsAssignedToGroup( TaskGroup ) then
      self:SetAssignedMenuForGroup( TaskGroup )
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

--- Set the planned menu option of the @{Task}.
-- @param #TASK_BASE self
-- @param Group#GROUP TaskGroup
-- @param #string MenuText The menu text.
-- @return #TASK_BASE self
function TASK_BASE:SetPlannedMenuForGroup( TaskGroup, MenuText )
  self:E( TaskGroup:GetName() )

  local TaskMission = self.Mission:GetName()
  local TaskCategory = self:GetCategory()
  local TaskType = self:GetType()
  
  local Mission = self.Mission
  
  Mission.MenuMission = Mission.MenuMission or {}
  local MenuMission = Mission.MenuMission

  Mission.MenuCategory = Mission.MenuCategory or {}
  local MenuCategory = Mission.MenuCategory
  
  Mission.MenuType = Mission.MenuType or {} 
  local MenuType = Mission.MenuType
  
  self.Menu = self.Menu or {}
  local Menu = self.Menu
  
  local TaskGroupName = TaskGroup:GetName()
  MenuMission[TaskGroupName] = MenuMission[TaskGroupName] or MENU_GROUP:New( TaskGroup, TaskMission, nil )
  
  MenuCategory[TaskGroupName] = MenuCategory[TaskGroupName] or {}
  MenuCategory[TaskGroupName][TaskCategory] = MenuCategory[TaskGroupName][TaskCategory] or MENU_GROUP:New( TaskGroup, TaskCategory, MenuMission[TaskGroupName] )
  
  MenuType[TaskGroupName] = MenuType[TaskGroupName] or {}
  MenuType[TaskGroupName][TaskType] = MenuType[TaskGroupName][TaskType] or MENU_GROUP:New( TaskGroup, TaskType, MenuCategory[TaskGroupName][TaskCategory] )
  
  if Menu[TaskGroupName] then
    Menu[TaskGroupName]:Remove()
  end
  Menu[TaskGroupName] = MENU_GROUP_COMMAND:New( TaskGroup, MenuText, MenuType[TaskGroupName][TaskType], self.MenuAssignToGroup, { self = self, TaskGroup = TaskGroup } )

  return self
end

--- Set the assigned menu options of the @{Task}.
-- @param #TASK_BASE self
-- @param Group#GROUP TaskGroup
-- @return #TASK_BASE self
function TASK_BASE:SetAssignedMenuForGroup( TaskGroup )
  self:E( TaskGroup:GetName() )

  local TaskMission = self.Mission:GetName()
  
  local Mission = self.Mission

  Mission.MenuMission = Mission.MenuMission or {}
  local MenuMission = Mission.MenuMission

  self.MenuStatus = self.MenuStatus or {}
  local MenuStatus = self.MenuStatus

  
  self.MenuAbort = self.MenuAbort or {}
  local MenuAbort = self.MenuAbort

  local TaskGroupName = TaskGroup:GetName()
  MenuMission[TaskGroupName] = MenuMission[TaskGroupName] or MENU_GROUP:New( TaskGroup, TaskMission, nil )
  MenuStatus[TaskGroupName] = MENU_GROUP_COMMAND:New( TaskGroup, "Task Status", MenuMission[TaskGroupName], self.MenuTaskStatus, { self = self, TaskGroup = TaskGroup } )
  MenuAbort[TaskGroupName] = MENU_GROUP_COMMAND:New( TaskGroup, "Abort Task", MenuMission[TaskGroupName], self.MenuTaskAbort, { self = self, TaskGroup = TaskGroup } )

  return self
end

--- Remove the menu option of the @{Task} for a @{Group}.
-- @param #TASK_BASE self
-- @param Group#GROUP TaskGroup
-- @return #TASK_BASE self
function TASK_BASE:RemoveMenuForGroup( TaskGroup )

  local TaskGroupName = TaskGroup:GetName()
  
  local Mission = self.Mission
  local MenuMission = Mission.MenuMission
  local MenuCategory = Mission.MenuCategory
  local MenuType = Mission.MenuType
  local MenuStatus = self.MenuStatus
  local MenuAbort = self.MenuAbort
  local Menu = self.Menu

  Menu = Menu or {}
  if Menu[TaskGroupName] then
    Menu[TaskGroupName]:Remove()
    Menu[TaskGroupName] = nil
  end

  MenuType = MenuType or {}
  if MenuType[TaskGroupName] then
    for _, Menu in pairs( MenuType[TaskGroupName] ) do
      Menu:Remove()
    end
    MenuType[TaskGroupName] = nil
  end

  MenuCategory = MenuCategory or {}
  if MenuCategory[TaskGroupName] then
    for _, Menu in pairs( MenuCategory[TaskGroupName] ) do
      Menu:Remove()
    end
    MenuCategory[TaskGroupName] = nil
  end
  
  MenuStatus = MenuStatus or {}
  if MenuStatus[TaskGroupName] then
    MenuStatus[TaskGroupName]:Remove()
    MenuStatus[TaskGroupName] = nil
  end
  
  MenuAbort = MenuAbort or {}
  if MenuAbort[TaskGroupName] then
    MenuAbort[TaskGroupName]:Remove()
    MenuAbort[TaskGroupName] = nil
  end

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
-- @return Process#PROCESS
function TASK_BASE:GetProcessTemplate( ProcessName )

  local ProcessTemplate = self.ProcessClasses[ProcessName]
  
  return ProcessTemplate
end



--- Fail processes from @{Task} with key @{Unit}
-- @param #TASK_BASE self
-- @param #string TaskUnitName
-- @return #TASK_BASE self
function TASK_BASE:FailProcesses( TaskUnitName )

  for ProcessID, ProcessData in pairs( self.Processes[TaskUnitName] ) do
    local Process = ProcessData -- Process#PROCESS
    Process.Fsm:Fail()
  end
end

--- Add a FiniteStateMachine to @{Task} with key @{Unit}
-- @param #TASK_BASE self
-- @param Unit#UNIT TaskUnit
-- @return #TASK_BASE self
function TASK_BASE:SetStateMachine( TaskUnit, Fsm )
  local TaskUnitName = TaskUnit:GetName()
  self.Fsm[TaskUnitName] = Fsm
    
  return Fsm
end

--- Remove FiniteStateMachines from @{Task} with key @{Unit}
-- @param #TASK_BASE self
-- @param #string TaskUnitName
-- @return #TASK_BASE self
function TASK_BASE:RemoveStateMachine( TaskUnitName )

  self.Fsm[TaskUnitName] = nil
  collectgarbage()
end

--- Checks if there is a FiniteStateMachine assigned to @{Unit} for @{Task}
-- @param #TASK_BASE self
-- @param #string TaskUnitName
-- @return #TASK_BASE self
function TASK_BASE:HasStateMachine( TaskUnitName )

  self:F( { TaskUnitName, self.Fsm[TaskUnitName] ~= nil } )
  return ( self.Fsm[TaskUnitName] ~= nil )
end





--- Register a potential new assignment for a new spawned @{Unit}.
-- Tasks only get assigned if there are players in it.
-- @param #TASK_BASE self
-- @param Event#EVENTDATA Event
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
-- @param Event#EVENTDATA Event
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
-- @param Event#EVENTDATA Event
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


--- Gets the Task Index, which is a combination of the Task category, the Task type, the Task name.
-- @param #TASK_BASE self
-- @return #string The Task ID
function TASK_BASE:GetTaskIndex()

  local TaskCategory = self:GetCategory()
  local TaskType = self:GetType()
  local TaskName = self:GetName()

  return TaskCategory .. "." ..TaskType .. "." .. TaskName
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

--- Sets the Category of the Task
-- @param #TASK_BASE self
-- @param #string TaskCategory
function TASK_BASE:SetCategory( TaskCategory )
  self.TaskCategory = TaskCategory
end

--- Gets the Category of the Task
-- @param #TASK_BASE self
-- @return #string TaskCategory
function TASK_BASE:GetCategory()
  return self.TaskCategory
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
-- @param #TASK_BASE self
-- @param #string TaskStatus is the status of the TASK when the score needs to be given.
-- @param #string ScoreText is a text describing the score that is given according the status.
-- @param #number Score is a number providing the score of the status.
-- @return #TASK_BASE self
function TASK_BASE:AddScoreTask( TaskStatus, ScoreText, Score )
  self:F2( { TaskStatus, ScoreText, Score } )

  self.Scores[TaskStatus] = self.Scores[TaskStatus] or {}
  self.Scores[TaskStatus].ScoreText = ScoreText
  self.Scores[TaskStatus].Score = Score
  return self
end

--- Adds a score for the TASK to be achieved.
-- @param #TASK_BASE self
-- @param #string TaskStatus is the status of the TASK when the score needs to be given.
-- @param #string ScoreText is a text describing the score that is given according the status.
-- @param #number Score is a number providing the score of the status.
-- @return #TASK_BASE self
function TASK_BASE:AddScoreProcess( Event, State, ScoreText, Score )
  self:F2( { State, ScoreText, Score } )


  self:E( self:GetFsmTemplate():GetSubs()[Event].fsm )
  local Process = self:GetFsmTemplate():GetSubs()[Event].fsm
  
  Process:AddScore( State, ScoreText, Score )

  return self
end


--- StateMachine callback function for a TASK
-- @param #TASK_BASE self
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Event#EVENTDATA Event
function TASK_BASE:onenterAssigned( Event, From, To )

  self:E("Assigned")
    
end


--- StateMachine callback function for a TASK
-- @param #TASK_BASE self
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Event#EVENTDATA Event
function TASK_BASE:onenterSuccess( Event, From, To )

  self:E("Success")
  
end

--- StateMachine callback function for a TASK
-- @param #TASK_BASE self
-- @param Unit#UNIT TaskUnit
-- @param StateMachine#STATEMACHINE_TASK Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Event#EVENTDATA Event
function TASK_BASE:OnFailed( TaskUnit, Fsm, Event, From, To )

  self:E( { "Failed for unit ", TaskUnit:GetName(), TaskUnit:GetPlayerName() } )
  
  -- A task cannot be "failed", so a task will always be there waiting for players to join.
  -- When the player leaves its unit, we will need to check whether he was on the ground or not at an airbase.
  -- When the player crashes, we will need to check whether in the group there are other players still active. It not, we reset the task from Assigned to Planned, otherwise, we just leave as Assigned.

  self:UnAssignFromGroups()
  self:StatePlanned()

end

--- StateMachine callback function for a TASK
-- @param #TASK_BASE self
-- @param Unit#UNIT TaskUnit
-- @param StateMachine#STATEMACHINE_TASK Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Event#EVENTDATA Event
function TASK_BASE:onstatechange( Event, From, To )

  if self:IsTrace() then
    MESSAGE:New( "Task " .. self.TaskName .. " : " .. Event .. " changed to state " .. To, 15 ):ToAll()
  end
  
  self:E( { Event, From, To, self:IsTrace() } )
  self:E( self.Scores )

  if self.Scores[To] then
    local Scoring = self:GetScoring()
    self:E( Scoring )
    if Scoring then
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




