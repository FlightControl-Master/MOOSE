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
--   * @{#TASK_BASE.AddStateMachine}():Add a @{StateMachine} to a task.
--   * @{#TASK_BASE.RemoveStateMachines}():Remove @{StateMachine}s from a task.
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
-- @extends Base#BASE
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
-- @param Mission#MISSION The mission wherein the Task is registered.
-- @param Set#SET_GROUP SetGroup The set of groups for which the Task can be assigned.
-- @param #string TaskName The name of the Task
-- @param #string TaskType The type of the Task
-- @param #string TaskCategory The category of the Task (A2G, A2A, Transport, ... )
-- @return #TASK_BASE self
function TASK_BASE:New( Mission, SetGroup, TaskName, TaskType, TaskCategory )

  local self = BASE:Inherit( self, BASE:New() )
  self:E( "New TASK " .. TaskName )

  self.Processes = {}
  self.Fsm = {}

  self.Mission = Mission
  self.SetGroup = SetGroup

  self:SetCategory( TaskCategory )
  self:SetType( TaskType )
  self:SetName( TaskName )
  self:SetID( Mission:GetNextTaskID( self ) ) -- The Mission orchestrates the task sequences ..

  self.TaskBriefing = "You are assigned to the task: " .. self.TaskName .. "."
  
  return self
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
    if PlayerName ~= nil or PlayerName ~= "" then
      self:AssignToUnit( TaskUnit )
    end
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
      local TaskUnit = UnitData -- Unit#UNIT
      local PlayerName = TaskUnit:GetPlayerName()
      if PlayerName ~= nil or PlayerName ~= "" then
        self:UnAssignFromUnit( TaskUnit )
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

--- Assign the @{Task}to an alive @{Unit}.
-- @param #TASK_BASE self
-- @param Unit#UNIT TaskUnit
-- @return #TASK_BASE self
function TASK_BASE:AssignToUnit( TaskUnit )
  self:F( TaskUnit:GetName() )
  
  return nil
end

--- UnAssign the @{Task} from an alive @{Unit}.
-- @param #TASK_BASE self
-- @param Unit#UNIT TaskUnit
-- @return #TASK_BASE self
function TASK_BASE:UnAssignFromUnit( TaskUnitName )
  self:F( TaskUnitName )
  
  if self:HasStateMachine( TaskUnitName ) == true then
    self:RemoveStateMachines( TaskUnitName )
    self:RemoveProcesses( TaskUnitName )
  end

  return self
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


--- This is the key worker function for the class. Instantiate a new Process based on the ProcessName to @{Task} and assign it to the ProcessUnit.
-- @param #TASK_BASE self
-- @param Unit#UNIT ProcessUnit The unit to which the process should be assigned.
-- @param #string ProcessName The name of the Process.
-- @return Process#PROCESS The Process that was added.
function TASK_BASE:AssignProcess( ProcessUnit, ProcessName )
  self:F( { ProcessName } )
  local ProcessUnitName = ProcessUnit:GetName()
  
  -- Create the Process instance base on the ProcessClasses collection assigned to the Task
  local ProcessClass, ProcessArguments 
  ProcessClass, ProcessArguments = self:GetProcessClass( ProcessName )
  
  local Process = ProcessClass:New( unpack( ProcessArguments ) ) -- Process#PROCESS
  Process:SetControllable( ProcessUnit )
  
  self.Processes = self.Processes or {}
  self.Processes[ProcessUnitName] = self.Processes[ProcessUnitName] or {}
    
  self.Processes[ProcessUnitName][ProcessName] = Process
  
  return Process
end


--- Get the default or currently assigned @{Process} class with key ProcessName.
-- @param #TASK_BASE self
-- @param #string ProcessName
-- @return Process#PROCESS
-- @return #table
function TASK_BASE:GetProcessClass( ProcessName )

  local ProcessClass = self.ProcessClasses[ProcessName].Class
  local ProcessArguments = self.ProcessClasses[ProcessName].Arguments
  
  return ProcessClass, ProcessArguments
end


--- Set the Process default class with key ProcessName providing the ProcessClass and the constructor initialization parameters when it is assigned to a Unit by the task.
-- @param #TASK_BASE self
-- @param #string ProcessName
-- @param Process#PROCESS ProcessClass
-- @param #table ... The parameters for the New() constructor of the ProcessClass, when the Task is assigning a new Process to the Unit.
-- @return Process#PROCESS
function TASK_BASE:SetProcessClass( ProcessName, ProcessClass, ... )

  self.ProcessClasses[ProcessName] = self.ProcessClasses[ProcessName] or {}
  self.ProcessClasses[ProcessName].Class = ProcessClass
  self.ProcessClasses[ProcessName].Arguments = ...
  
  return ProcessClass
end


--- Remove Processes from @{Task} with key @{Unit}
-- @param #TASK_BASE self
-- @param #string TaskUnitName
-- @return #TASK_BASE self
function TASK_BASE:RemoveProcesses( TaskUnitName )

  for ProcessID, ProcessData in pairs( self.Processes[TaskUnitName] ) do
    local Process = ProcessData -- Process#PROCESS
    Process:StopEvents()
    Process = nil
    self.Processes[TaskUnitName][ProcessID] = nil
    self:E( self.Processes[TaskUnitName][ProcessID] )
  end
  self.Processes[TaskUnitName] = nil
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
function TASK_BASE:AddStateMachine( TaskUnit, Fsm )
  local TaskUnitName = TaskUnit:GetName()
  self.Fsm[TaskUnitName] = self.Fsm[TaskUnitName] or {}
  self.Fsm[TaskUnitName][#self.Fsm[TaskUnitName]+1] = Fsm
  return Fsm
end

--- Remove FiniteStateMachines from @{Task} with key @{Unit}
-- @param #TASK_BASE self
-- @param #string TaskUnitName
-- @return #TASK_BASE self
function TASK_BASE:RemoveStateMachines( TaskUnitName )

  for _, Fsm in pairs( self.Fsm[TaskUnitName] ) do
    Fsm = nil
    self.Fsm[TaskUnitName][_] = nil
    self:E( self.Fsm[TaskUnitName][_] )
  end
  self.Fsm[TaskUnitName] = nil
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
-- @return Scoring#SCORING Scoring
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
  return self:GetStateString() == "Success"
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
  return self:GetStateString() == "Failed"
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
  return self:GetStateString() == "Planned"
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
  return self:GetStateString() == "Assigned"
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
  return self:GetStateString() == "Hold"
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
  return self:GetStateString() == "Replanned"
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
function TASK_BASE:AddScore( TaskStatus, ScoreText, Score )
  self:F2( { TaskStatus, ScoreText, Score } )

  self.Scores[TaskStatus] = self.Scores[TaskStatus] or {}
  self.Scores[TaskStatus].ScoreText = ScoreText
  self.Scores[TaskStatus].Score = Score
  return self
end


--- StateMachine callback function for a TASK
-- @param #TASK_BASE self
-- @param Unit#UNIT TaskUnit
-- @param StateMachine#STATEMACHINE_TASK Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Event#EVENTDATA Event
function TASK_BASE:OnAssigned( TaskUnit, Fsm, Event, From, To )

  self:E("Assigned")
  
  local TaskGroup = TaskUnit:GetGroup()
  
  TaskGroup:Message( self.TaskBriefing, 20 )
  
  self:RemoveMenuForGroup( TaskGroup )
  self:SetAssignedMenuForGroup( TaskGroup )

end


--- StateMachine callback function for a TASK
-- @param #TASK_BASE self
-- @param Unit#UNIT TaskUnit
-- @param StateMachine#STATEMACHINE_TASK Fsm
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Event#EVENTDATA Event
function TASK_BASE:OnSuccess( TaskUnit, Fsm, Event, From, To )

  self:E("Success")
  
  self:UnAssignFromGroups()

  local TaskGroup = TaskUnit:GetGroup()
  self.Mission:SetPlannedMenu()

  self:StateSuccess()
  
  -- The task has become successful, the event catchers can be cleaned.
  self:CleanUp()
  
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
function TASK_BASE:OnStateChange( TaskUnit, Fsm, Event, From, To )

  if self:IsTrace() then
    MESSAGE:New( "Task " .. self.TaskName .. " : " .. Event .. " changed to state " .. To, 15 ):ToAll()
  end
  
  self:E( { Event, From, To } )
  self:SetState( self, "State", To )

  if self.Scores[To] then
    local Scoring = self:GetScoring()
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




