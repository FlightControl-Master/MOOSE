--- **Tasking** -- A MISSION is the main owner of a Mission orchestration within MOOSE.
-- 
-- ====
-- 
-- ### Author: **Sven Van de Velde (FlightControl)**
-- 
-- ### Contributions: 
-- 
-- ===
-- 
-- @module Mission

--- The MISSION class
-- @type MISSION
-- @field #MISSION.Clients _Clients
-- @field Core.Menu#MENU_COALITION MissionMenu
-- @field #string MissionBriefing
-- @extends Core.Fsm#FSM
MISSION = {
	ClassName = "MISSION",
	Name = "",
	MissionStatus = "PENDING",
	AssignedGroups = {},
}

--- This is the main MISSION declaration method. Each Mission is like the master or a Mission orchestration between, Clients, Tasks, Stages etc.
-- @param #MISSION self
-- @param Tasking.CommandCenter#COMMANDCENTER CommandCenter
-- @param #string MissionName is the name of the mission. This name will be used to reference the status of each mission by the players.
-- @param #string MissionPriority is a string indicating the "priority" of the Mission. f.e. "Primary", "Secondary" or "First", "Second". It is free format and up to the Mission designer to choose. There are no rules behind this field.
-- @param #string MissionBriefing is a string indicating the mission briefing to be shown when a player joins a @{CLIENT}.
-- @param Dcs.DCSCoalitionWrapper.Object#coalition MissionCoalition is a string indicating the coalition or party to which this mission belongs to. It is free format and can be chosen freely by the mission designer. Note that this field is not to be confused with the coalition concept of the ME. Examples of a Mission Coalition could be "NATO", "CCCP", "Intruders", "Terrorists"...
-- @return #MISSION self
function MISSION:New( CommandCenter, MissionName, MissionPriority, MissionBriefing, MissionCoalition )

  local self = BASE:Inherit( self, FSM:New() ) -- Core.Fsm#FSM

  self:T( { MissionName, MissionPriority, MissionBriefing, MissionCoalition } )
  
  self.CommandCenter = CommandCenter
  CommandCenter:AddMission( self )
  
  self.Name = MissionName
  self.MissionPriority = MissionPriority
  self.MissionBriefing = MissionBriefing
  self.MissionCoalition = MissionCoalition
  
  self.Tasks = {}
  self.PlayerNames = {} -- These are the players that achieved progress in the mission.

  self:SetStartState( "IDLE" )
  
  self:AddTransition( "IDLE", "Start", "ENGAGED" )
  
  --- OnLeave Transition Handler for State IDLE.
  -- @function [parent=#MISSION] OnLeaveIDLE
  -- @param #MISSION self
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnEnter Transition Handler for State IDLE.
  -- @function [parent=#MISSION] OnEnterIDLE
  -- @param #MISSION self
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  
  --- OnLeave Transition Handler for State ENGAGED.
  -- @function [parent=#MISSION] OnLeaveENGAGED
  -- @param #MISSION self
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnEnter Transition Handler for State ENGAGED.
  -- @function [parent=#MISSION] OnEnterENGAGED
  -- @param #MISSION self
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  
  --- OnBefore Transition Handler for Event Start.
  -- @function [parent=#MISSION] OnBeforeStart
  -- @param #MISSION self
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Start.
  -- @function [parent=#MISSION] OnAfterStart
  -- @param #MISSION self
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  	
  --- Synchronous Event Trigger for Event Start.
  -- @function [parent=#MISSION] Start
  -- @param #MISSION self
  
  --- Asynchronous Event Trigger for Event Start.
  -- @function [parent=#MISSION] __Start
  -- @param #MISSION self
  -- @param #number Delay The delay in seconds.
  
  self:AddTransition( "ENGAGED", "Stop", "IDLE" )
  
  --- OnLeave Transition Handler for State IDLE.
  -- @function [parent=#MISSION] OnLeaveIDLE
  -- @param #MISSION self
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnEnter Transition Handler for State IDLE.
  -- @function [parent=#MISSION] OnEnterIDLE
  -- @param #MISSION self
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  
  --- OnBefore Transition Handler for Event Stop.
  -- @function [parent=#MISSION] OnBeforeStop
  -- @param #MISSION self
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Stop.
  -- @function [parent=#MISSION] OnAfterStop
  -- @param #MISSION self
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  	
  --- Synchronous Event Trigger for Event Stop.
  -- @function [parent=#MISSION] Stop
  -- @param #MISSION self
  
  --- Asynchronous Event Trigger for Event Stop.
  -- @function [parent=#MISSION] __Stop
  -- @param #MISSION self
  -- @param #number Delay The delay in seconds.
  
  self:AddTransition( "ENGAGED", "Complete", "COMPLETED" )
  
  --- OnLeave Transition Handler for State COMPLETED.
  -- @function [parent=#MISSION] OnLeaveCOMPLETED
  -- @param #MISSION self
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnEnter Transition Handler for State COMPLETED.
  -- @function [parent=#MISSION] OnEnterCOMPLETED
  -- @param #MISSION self
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  
  --- OnBefore Transition Handler for Event Complete.
  -- @function [parent=#MISSION] OnBeforeComplete
  -- @param #MISSION self
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Complete.
  -- @function [parent=#MISSION] OnAfterComplete
  -- @param #MISSION self
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  	
  --- Synchronous Event Trigger for Event Complete.
  -- @function [parent=#MISSION] Complete
  -- @param #MISSION self
  
  --- Asynchronous Event Trigger for Event Complete.
  -- @function [parent=#MISSION] __Complete
  -- @param #MISSION self
  -- @param #number Delay The delay in seconds.
  
  self:AddTransition( "*", "Fail", "FAILED" )
  
  --- OnLeave Transition Handler for State FAILED.
  -- @function [parent=#MISSION] OnLeaveFAILED
  -- @param #MISSION self
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnEnter Transition Handler for State FAILED.
  -- @function [parent=#MISSION] OnEnterFAILED
  -- @param #MISSION self
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  
  --- OnBefore Transition Handler for Event Fail.
  -- @function [parent=#MISSION] OnBeforeFail
  -- @param #MISSION self
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  -- @return #boolean Return false to cancel Transition.
  
  --- OnAfter Transition Handler for Event Fail.
  -- @function [parent=#MISSION] OnAfterFail
  -- @param #MISSION self
  -- @param #string From The From State string.
  -- @param #string Event The Event string.
  -- @param #string To The To State string.
  	
  --- Synchronous Event Trigger for Event Fail.
  -- @function [parent=#MISSION] Fail
  -- @param #MISSION self
  
  --- Asynchronous Event Trigger for Event Fail.
  -- @function [parent=#MISSION] __Fail
  -- @param #MISSION self
  -- @param #number Delay The delay in seconds.
  
  
  self:AddTransition( "*", "MissionGoals", "*" )
  
  --- MissionGoals Handler OnBefore for MISSION
  -- @function [parent=#MISSION] OnBeforeMissionGoals
  -- @param #MISSION self
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @return #boolean
  
  --- MissionGoals Handler OnAfter for MISSION
  -- @function [parent=#MISSION] OnAfterMissionGoals
  -- @param #MISSION self
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  
  --- MissionGoals Trigger for MISSION
  -- @function [parent=#MISSION] MissionGoals
  -- @param #MISSION self
  
  --- MissionGoals Asynchronous Trigger for MISSION
  -- @function [parent=#MISSION] __MissionGoals
  -- @param #MISSION self
  -- @param #number Delay
  
	-- Private  implementations
	
	CommandCenter:SetMenu()

	return self
end


--- FSM function for a MISSION
-- @param #MISSION self
-- @param #string From
-- @param #string Event
-- @param #string To
function MISSION:onenterCOMPLETED( From, Event, To )

  self:GetCommandCenter():MessageTypeToCoalition( self:GetName() .. " has been completed! Good job guys!", MESSAGE.Type.Information )
end

--- Gets the mission name.
-- @param #MISSION self
-- @return #MISSION self
function MISSION:GetName()
  return string.format( 'Mission "%s (%s)"', self.Name, self.MissionPriority )
end

--- Add a Unit to join the Mission.
-- For each Task within the Mission, the Unit is joined with the Task.
-- If the Unit was not part of a Task in the Mission, false is returned.
-- If the Unit is part of a Task in the Mission, true is returned.
-- @param #MISSION self
-- @param Wrapper.Unit#UNIT PlayerUnit The CLIENT or UNIT of the Player joining the Mission.
-- @param Wrapper.Group#GROUP PlayerGroup The GROUP of the player joining the Mission.
-- @return #boolean true if Unit is part of a Task in the Mission.
function MISSION:JoinUnit( PlayerUnit, PlayerGroup )
  self:F( { PlayerUnit = PlayerUnit, PlayerGroup = PlayerGroup } )
  
  local PlayerUnitAdded = false
  
  for TaskID, Task in pairs( self:GetTasks() ) do
    local Task = Task -- Tasking.Task#TASK
    if Task:JoinUnit( PlayerUnit, PlayerGroup ) then
      PlayerUnitAdded = true
    end
  end
  
  return PlayerUnitAdded
end

--- Aborts a PlayerUnit from the Mission.
-- For each Task within the Mission, the PlayerUnit is removed from Task where it is assigned.
-- If the Unit was not part of a Task in the Mission, false is returned.
-- If the Unit is part of a Task in the Mission, true is returned.
-- @param #MISSION self
-- @param Wrapper.Unit#UNIT PlayerUnit The CLIENT or UNIT of the Player joining the Mission.
-- @return #MISSION
function MISSION:AbortUnit( PlayerUnit )
  self:F( { PlayerUnit = PlayerUnit } )
  
  for TaskID, Task in pairs( self:GetTasks() ) do
    local Task = Task -- Tasking.Task#TASK
    local PlayerGroup = PlayerUnit:GetGroup()
    Task:AbortGroup( PlayerGroup )
  end
  
  return self
end

--- Handles a crash of a PlayerUnit from the Mission.
-- For each Task within the Mission, the PlayerUnit is removed from Task where it is assigned.
-- If the Unit was not part of a Task in the Mission, false is returned.
-- If the Unit is part of a Task in the Mission, true is returned.
-- @param #MISSION self
-- @param Wrapper.Unit#UNIT PlayerUnit The CLIENT or UNIT of the Player crashing.
-- @return #MISSION
function MISSION:CrashUnit( PlayerUnit )
  self:F( { PlayerUnit = PlayerUnit } )
  
  for TaskID, Task in pairs( self:GetTasks() ) do
    local Task = Task -- Tasking.Task#TASK
    local PlayerGroup = PlayerUnit:GetGroup()
    Task:CrashGroup( PlayerGroup )
  end
  
  return self
end

--- Add a scoring to the mission.
-- @param #MISSION self
-- @return #MISSION self
function MISSION:AddScoring( Scoring )
  self.Scoring = Scoring
  return self
end

--- Get the scoring object of a mission.
-- @param #MISSION self
-- @return #SCORING Scoring
function MISSION:GetScoring()
  return self.Scoring
end

--- Get the groups for which TASKS are given in the mission
-- @param #MISSION self
-- @return Core.Set#SET_GROUP
function MISSION:GetGroups()
  
  local SetGroup = SET_GROUP:New()
  
  for TaskID, Task in pairs( self:GetTasks() ) do
    local Task = Task -- Tasking.Task#TASK
    local GroupSet = Task:GetGroups()
    GroupSet:ForEachGroup(
      function( TaskGroup )
        SetGroup:Add( TaskGroup, TaskGroup )
      end
    )
  end
  
  return SetGroup
  
end


--- Sets the Planned Task menu.
-- @param #MISSION self
-- @param #number MenuTime
function MISSION:SetMenu( MenuTime )
  self:F( { self:GetName(), MenuTime } )
  
  for _, TaskData in pairs( self:GetTasks() ) do
    local Task = TaskData -- Tasking.Task#TASK
    Task:SetMenu( MenuTime )  
  end
end

--- Removes the Planned Task menu.
-- @param #MISSION self
-- @param #number MenuTime
function MISSION:RemoveMenu( MenuTime )
  self:F( { self:GetName(), MenuTime } )
  
  for _, Task in pairs( self:GetTasks() ) do
    local Task = Task -- Tasking.Task#TASK
    Task:RemoveMenu( MenuTime )
  end
end



do -- Group Assignment

  --- Returns if the @{Mission} is assigned to the Group.
  -- @param #MISSION self
  -- @param Wrapper.Group#GROUP MissionGroup
  -- @return #boolean
  function MISSION:IsGroupAssigned( MissionGroup )
  
    local MissionGroupName = MissionGroup:GetName()
    
    if self.AssignedGroups[MissionGroupName] == MissionGroup then
      self:T( { "Mission is assigned to:", MissionGroup:GetName() } )
      return true
    end
    
    self:T( { "Mission is not assigned to:", MissionGroup:GetName() } )
    return false
  end
  
  
  --- Set @{Group} assigned to the @{Mission}.
  -- @param #MISSION self
  -- @param Wrapper.Group#GROUP MissionGroup
  -- @return #MISSION
  function MISSION:SetGroupAssigned( MissionGroup )
  
    local MissionName = self:GetName()
    local MissionGroupName = MissionGroup:GetName()
  
    self.AssignedGroups[MissionGroupName] = MissionGroup
    self:E( string.format( "Mission %s is assigned to %s", MissionName, MissionGroupName ) )
    
    return self
  end
  
  --- Clear the @{Group} assignment from the @{Mission}.
  -- @param #MISSION self
  -- @param Wrapper.Group#GROUP MissionGroup
  -- @return #MISSION
  function MISSION:ClearGroupAssignment( MissionGroup )
  
    local MissionName = self:GetName()
    local MissionGroupName = MissionGroup:GetName()
  
    self.AssignedGroups[MissionGroupName] = nil
    --self:E( string.format( "Mission %s is unassigned to %s", MissionName, MissionGroupName ) )
    
    return self
  end
  
end

--- Gets the COMMANDCENTER.
-- @param #MISSION self
-- @return Tasking.CommandCenter#COMMANDCENTER
function MISSION:GetCommandCenter()
  return self.CommandCenter
end


--- Removes a Task menu.
-- @param #MISSION self
-- @param Tasking.Task#TASK Task
-- @return #MISSION self
function MISSION:RemoveTaskMenu( Task )
    
  Task:RemoveMenu()  
end


--- Gets the root mission menu for the TaskGroup.
-- @param #MISSION self
-- @return Core.Menu#MENU_COALITION self
function MISSION:GetRootMenu( TaskGroup ) -- R2.2

  local CommandCenter = self:GetCommandCenter()
  local CommandCenterMenu = CommandCenter:GetMenu()

  local MissionName = self:GetName()
  --local MissionMenu = CommandCenterMenu:GetMenu( MissionName )
  
  self.MissionMenu = self.MissionMenu or MENU_COALITION:New( self.MissionCoalition, self:GetName(), CommandCenterMenu )

  return self.MissionMenu
end

--- Gets the mission menu for the TaskGroup.
-- @param #MISSION self
-- @return Core.Menu#MENU_COALITION self
function MISSION:GetMenu( TaskGroup ) -- R2.1 -- Changed Menu Structure

  local CommandCenter = self:GetCommandCenter()
  local CommandCenterMenu = CommandCenter:GetMenu()

  local MissionName = self:GetName()
  --local MissionMenu = CommandCenterMenu:GetMenu( MissionName )
  
  self.MissionGroupMenu = self.MissionGroupMenu or {}
  self.MissionGroupMenu[TaskGroup] = self.MissionGroupMenu[TaskGroup] or {}
  
  local GroupMenu = self.MissionGroupMenu[TaskGroup]
  
  self.MissionMenu = self.MissionMenu or MENU_COALITION:New( self.MissionCoalition, self:GetName(), CommandCenterMenu )
  
  GroupMenu.BriefingMenu = GroupMenu.BriefingMenu or MENU_GROUP_COMMAND:New( TaskGroup, "Mission Briefing", self.MissionMenu, self.MenuReportBriefing, self, TaskGroup )

  GroupMenu.MarkTasks = GroupMenu.MarkTasks or                                  MENU_GROUP_COMMAND:New( TaskGroup, "Mark Task Locations on Map", self.MissionMenu, self.MarkTargetLocations, self, TaskGroup )
  GroupMenu.TaskReportsMenu = GroupMenu.TaskReportsMenu or                      MENU_GROUP:New( TaskGroup, "Task Reports", self.MissionMenu )
  GroupMenu.ReportTasksMenu = GroupMenu.ReportTasksMenu or                      MENU_GROUP_COMMAND:New( TaskGroup, "Report Tasks", GroupMenu.TaskReportsMenu, self.MenuReportTasksSummary, self, TaskGroup )
  GroupMenu.ReportPlannedTasksMenu = GroupMenu.ReportPlannedTasksMenu or        MENU_GROUP_COMMAND:New( TaskGroup, "Report Planned Tasks", GroupMenu.TaskReportsMenu, self.MenuReportTasksPerStatus, self, TaskGroup, "Planned" )
  GroupMenu.ReportAssignedTasksMenu = GroupMenu.ReportAssignedTasksMenu or      MENU_GROUP_COMMAND:New( TaskGroup, "Report Assigned Tasks", GroupMenu.TaskReportsMenu, self.MenuReportTasksPerStatus, self, TaskGroup, "Assigned" )
  GroupMenu.ReportSuccessTasksMenu = GroupMenu.ReportSuccessTasksMenu or        MENU_GROUP_COMMAND:New( TaskGroup, "Report Successful Tasks", GroupMenu.TaskReportsMenu, self.MenuReportTasksPerStatus, self, TaskGroup, "Success" )
  GroupMenu.ReportFailedTasksMenu = GroupMenu.ReportFailedTasksMenu or          MENU_GROUP_COMMAND:New( TaskGroup, "Report Failed Tasks", GroupMenu.TaskReportsMenu, self.MenuReportTasksPerStatus, self, TaskGroup, "Failed" )
  GroupMenu.ReportHeldTasksMenu = GroupMenu.ReportHeldTasksMenu or              MENU_GROUP_COMMAND:New( TaskGroup, "Report Held Tasks", GroupMenu.TaskReportsMenu, self.MenuReportTasksPerStatus, self, TaskGroup, "Hold" )
  
  GroupMenu.PlayerReportsMenu = GroupMenu.PlayerReportsMenu or                  MENU_GROUP:New( TaskGroup, "Statistics Reports", self.MissionMenu )
  GroupMenu.ReportMissionHistory = GroupMenu.ReportPlayersHistory or            MENU_GROUP_COMMAND:New( TaskGroup, "Report Mission Progress", GroupMenu.PlayerReportsMenu, self.MenuReportPlayersProgress, self, TaskGroup )
  GroupMenu.ReportPlayersPerTaskMenu = GroupMenu.ReportPlayersPerTaskMenu or    MENU_GROUP_COMMAND:New( TaskGroup, "Report Players per Task", GroupMenu.PlayerReportsMenu, self.MenuReportPlayersPerTask, self, TaskGroup )
  
  return self.MissionMenu
end




--- Get the TASK identified by the TaskNumber from the Mission. This function is useful in GoalFunctions.
-- @param #string TaskName The Name of the @{Task} within the @{Mission}.
-- @return Tasking.Task#TASK The Task
-- @return #nil Returns nil if no task was found.
function MISSION:GetTask( TaskName  )
  self:F( { TaskName } )

  return self.Tasks[TaskName]
end


--- Register a @{Task} to be completed within the @{Mission}. 
-- Note that there can be multiple @{Task}s registered to be completed. 
-- Each Task can be set a certain Goals. The Mission will not be completed until all Goals are reached.
-- @param #MISSION self
-- @param Tasking.Task#TASK Task is the @{Task} object.
-- @return Tasking.Task#TASK The task added.
function MISSION:AddTask( Task )

  local TaskName = Task:GetTaskName()
  self:F( TaskName )

  self.Tasks[TaskName] = self.Tasks[TaskName] or { n = 0 }

  self.Tasks[TaskName] = Task
  
  self:GetCommandCenter():SetMenu()

  return Task
end

--- Removes a @{Task} to be completed within the @{Mission}. 
-- Note that there can be multiple @{Task}s registered to be completed. 
-- Each Task can be set a certain Goals. The Mission will not be completed until all Goals are reached.
-- @param #MISSION self
-- @param Tasking.Task#TASK Task is the @{Task} object.
-- @return #nil The cleaned Task reference.
function MISSION:RemoveTask( Task )

  local TaskName = Task:GetTaskName()

  self:F( TaskName )
  self.Tasks[TaskName] = self.Tasks[TaskName] or { n = 0 }

  -- Ensure everything gets garbarge collected.
  self.Tasks[TaskName] = nil 
  Task = nil
  
  collectgarbage()

  self:GetCommandCenter():SetMenu()
  
  return nil
end

--- Return the next @{Task} ID to be completed within the @{Mission}. 
-- @param #MISSION self
-- @param Tasking.Task#TASK Task is the @{Task} object.
-- @return Tasking.Task#TASK The task added.
function MISSION:GetNextTaskID( Task )

  local TaskName = Task:GetTaskName()
  self:F( TaskName )
  self.Tasks[TaskName] = self.Tasks[TaskName] or { n = 0 }
  
  self.Tasks[TaskName].n = self.Tasks[TaskName].n + 1

  return self.Tasks[TaskName].n
end

--- Is the @{Mission} **COMPLETED**.
-- @param #MISSION self
-- @return #boolean
function MISSION:IsCOMPLETED()
  return self:Is( "COMPLETED" )
end

--- Is the @{Mission} **IDLE**.
-- @param #MISSION self
-- @return #boolean
function MISSION:IsIDLE()
  return self:Is( "IDLE" )
end

--- Is the @{Mission} **ENGAGED**.
-- @param #MISSION self
-- @return #boolean
function MISSION:IsENGAGED()
  return self:Is( "ENGAGED" )
end

--- Is the @{Mission} **FAILED**.
-- @param #MISSION self
-- @return #boolean
function MISSION:IsFAILED()
  return self:Is( "FAILED" )
end

--- Is the @{Mission} **HOLD**.
-- @param #MISSION self
-- @return #boolean
function MISSION:IsHOLD()
  return self:Is( "HOLD" )
end

--- Validates if the Mission has a Group
-- @param #MISSION
-- @return #boolean true if the Mission has a Group.
function MISSION:HasGroup( TaskGroup )
  local Has = false
  
  for TaskID, Task in pairs( self:GetTasks() ) do
    local Task = Task -- Tasking.Task#TASK
    if Task:HasGroup( TaskGroup ) then
      Has = true
      break
    end
  end
  
  return Has
end

--- @param #MISSION self
-- @return #number
function MISSION:GetTasksRemaining()
  -- Determine how many tasks are remaining.
  local TasksRemaining = 0
  for TaskID, Task in pairs( self:GetTasks() ) do
    local Task = Task -- Tasking.Task#TASK
    if Task:IsStateSuccess() or Task:IsStateFailed() then
    else
      TasksRemaining = TasksRemaining + 1
    end
  end
  return TasksRemaining
end

--- @param #MISSION self
-- @return #number
function MISSION:GetTaskTypes()
  -- Determine how many tasks are remaining.
  local TaskTypeList = {}
  local TasksRemaining = 0
  for TaskID, Task in pairs( self:GetTasks() ) do
    local Task = Task -- Tasking.Task#TASK
    local TaskType = Task:GetType()
    TaskTypeList[TaskType] = TaskType
  end
  return TaskTypeList
end


function MISSION:AddPlayerName( PlayerName )
  self.PlayerNames = self.PlayerNames or {}
  self.PlayerNames[PlayerName] = PlayerName
  return self
end

function MISSION:GetPlayerNames()
  return self.PlayerNames
end


--- Create a briefing report of the Mission.
-- @param #MISSION self
-- @return #string
function MISSION:ReportBriefing()

  local Report = REPORT:New()

  -- List the name of the mission.
  local Name = self:GetName()
  
  -- Determine the status of the mission.
  local Status = "<" .. self:GetState() .. ">"
  
  Report:Add( string.format( '%s - %s - Mission Briefing Report', Name, Status ) )

  Report:Add( self.MissionBriefing )
  
  return Report:Text()
end


--- Create a status report of the Mission.
-- This reports provides a one liner of the mission status. It indicates how many players and how many Tasks.
-- 
--     Mission "<MissionName>" - Status "<MissionStatus>"
--      - Task Types: <TaskType>, <TaskType>
--      - <xx> Planned Tasks (xp)
--      - <xx> Assigned Tasks(xp)
--      - <xx> Success Tasks (xp)
--      - <xx> Hold Tasks (xp)
--      - <xx> Cancelled Tasks (xp)
--      - <xx> Aborted Tasks (xp)
--      - <xx> Failed Tasks (xp)
-- 
-- @param #MISSION self
-- @return #string
function MISSION:ReportStatus()

  local Report = REPORT:New()

  -- List the name of the mission.
  local Name = self:GetName()
  
  -- Determine the status of the mission.
  local Status = "<" .. self:GetState() .. ">"

  Report:Add( string.format( '%s - Status "%s"', Name, Status ) )
  
  local TaskTypes = self:GetTaskTypes()
  
  Report:Add( string.format( " - Task Types: %s", table.concat(TaskTypes, ", " ) ) )
  
  local TaskStatusList = { "Planned", "Assigned", "Success", "Hold", "Cancelled", "Aborted", "Failed" }
  
  for TaskStatusID, TaskStatus in pairs( TaskStatusList ) do
    local TaskCount = 0
    local TaskPlayerCount = 0 
    -- Determine how many tasks are remaining.
    for TaskID, Task in pairs( self:GetTasks() ) do
      local Task = Task -- Tasking.Task#TASK
      if Task:Is( TaskStatus ) then
        TaskCount = TaskCount + 1
        TaskPlayerCount = TaskPlayerCount + Task:GetPlayerCount()
      end
    end
    if TaskCount > 0 then
      Report:Add( string.format( " - %02d %s Tasks (%dp)", TaskCount, TaskStatus, TaskPlayerCount ) )
    end
  end

  return Report:Text()
end


--- Create an active player report of the Mission.
-- This reports provides a one liner of the mission status. It indicates how many players and how many Tasks.
-- 
--     Mission "<MissionName>" - <MissionStatus> - Active Players Report
--      - Player "<PlayerName>: Task <TaskName> <TaskStatus>, Task <TaskName> <TaskStatus>
--      - Player <PlayerName>: Task <TaskName> <TaskStatus>, Task <TaskName> <TaskStatus>
--      - ..
-- 
-- @param #MISSION self
-- @return #string
function MISSION:ReportPlayersPerTask( ReportGroup )

  local Report = REPORT:New()

  -- List the name of the mission.
  local Name = self:GetName()
  
  -- Determine the status of the mission.
  local Status = "<" .. self:GetState() .. ">"

  Report:Add( string.format( '%s - %s - Players per Task Report', Name, Status ) )
  
  local PlayerList = {}
  
  -- Determine how many tasks are remaining.
  for TaskID, Task in pairs( self:GetTasks() ) do
    local Task = Task -- Tasking.Task#TASK
    local PlayerNames = Task:GetPlayerNames()
    for PlayerName, PlayerGroup in pairs( PlayerNames ) do
      PlayerList[PlayerName] = Task:GetName()
    end
    
  end

  for PlayerName, TaskName in pairs( PlayerList ) do
    Report:Add( string.format( ' - Player (%s): Task "%s"', PlayerName, TaskName ) )
  end
  
  return Report:Text()
end

--- Create an Mission Progress report of the Mission.
-- This reports provides a one liner per player of the mission achievements per task.
-- 
--     Mission "<MissionName>" - <MissionStatus> - Active Players Report
--      - Player <PlayerName>: Task <TaskName> <TaskStatus>: <Progress>
--      - Player <PlayerName>: Task <TaskName> <TaskStatus>: <Progress>
--      - ..
-- 
-- @param #MISSION self
-- @return #string
function MISSION:ReportPlayersProgress( ReportGroup )

  local Report = REPORT:New()

  -- List the name of the mission.
  local Name = self:GetName()
  
  -- Determine the status of the mission.
  local Status = "<" .. self:GetState() .. ">"

  Report:Add( string.format( '%s - %s - Players per Task Progress Report', Name, Status ) )
  
  local PlayerList = {}
  
  -- Determine how many tasks are remaining.
  for TaskID, Task in pairs( self:GetTasks() ) do
    local Task = Task -- Tasking.Task#TASK
    local TaskGoalTotal = Task:GetGoalTotal() or 0
    local TaskName = Task:GetName()
    PlayerList[TaskName] = PlayerList[TaskName] or {}
    if TaskGoalTotal ~= 0 then
      local PlayerNames = self:GetPlayerNames()
      for PlayerName, PlayerData in pairs( PlayerNames ) do
        PlayerList[TaskName][PlayerName] = string.format( 'Player (%s): Task "%s": %d%%', PlayerName, TaskName, Task:GetPlayerProgress( PlayerName ) * 100 / TaskGoalTotal )
      end
    else
      PlayerList[TaskName]["_"] = string.format( 'Player (---): Task "%s": %d%%', TaskName, 0 )
    end
    
  end

  for TaskName, TaskData in pairs( PlayerList ) do
    for PlayerName, TaskText in pairs( TaskData ) do
      Report:Add( string.format( ' - %s', TaskText ) )
    end
  end
  
  return Report:Text()
end


--- Mark all the target locations on the Map.
-- @param #MISSION self
-- @param Wrapper.Group#GROUP ReportGroup
-- @return #string
function MISSION:MarkTargetLocations( ReportGroup )

  local Report = REPORT:New()

  -- List the name of the mission.
  local Name = self:GetName()
  
  -- Determine the status of the mission.
  local Status = "<" .. self:GetState() .. ">"
  
  Report:Add( string.format( '%s - %s - All Tasks are marked on the map. Select a Task from the Mission Menu and Join the Task!!!', Name, Status ) )

  -- Determine how many tasks are remaining.
  for TaskID, Task in UTILS.spairs( self:GetTasks(), function( t, a, b ) return t[a]:ReportOrder( ReportGroup ) <  t[b]:ReportOrder( ReportGroup ) end  ) do
    local Task = Task -- Tasking.Task#TASK
    Task:MenuMarkToGroup( ReportGroup )
  end
  
  return Report:Text()
end


--- Create a summary report of the Mission (one line).
-- @param #MISSION self
-- @param Wrapper.Group#GROUP ReportGroup
-- @return #string
function MISSION:ReportSummary( ReportGroup )

  local Report = REPORT:New()

  -- List the name of the mission.
  local Name = self:GetName()
  
  -- Determine the status of the mission.
  local Status = "<" .. self:GetState() .. ">"
  
  Report:Add( string.format( '%s - %s - Task Overview Report', Name, Status ) )

  -- Determine how many tasks are remaining.
  for TaskID, Task in UTILS.spairs( self:GetTasks(), function( t, a, b ) return t[a]:ReportOrder( ReportGroup ) <  t[b]:ReportOrder( ReportGroup ) end  ) do
    local Task = Task -- Tasking.Task#TASK
    Report:Add( "- " .. Task:ReportSummary( ReportGroup ) )
  end
  
  return Report:Text()
end

--- Create a overview report of the Mission (multiple lines).
-- @param #MISSION self
-- @return #string
function MISSION:ReportOverview( ReportGroup, TaskStatus )

  self:F( { TaskStatus = TaskStatus } )

  local Report = REPORT:New()

  -- List the name of the mission.
  local Name = self:GetName()
  
  -- Determine the status of the mission.
  local Status = "<" .. self:GetState() .. ">"

  Report:Add( string.format( '%s - %s - %s Tasks Report', Name, Status, TaskStatus ) )
  
  -- Determine how many tasks are remaining.
  local Tasks = 0
  for TaskID, Task in UTILS.spairs( self:GetTasks(), function( t, a, b ) return t[a]:ReportOrder( ReportGroup ) <  t[b]:ReportOrder( ReportGroup ) end  ) do
    local Task = Task -- Tasking.Task#TASK
    if Task:Is( TaskStatus ) then
      Report:Add( string.rep( "-", 140 ) )
      Report:Add( " - " .. Task:ReportOverview( ReportGroup ) )
    end
    Tasks = Tasks + 1
    if Tasks >= 8 then
      break
    end
  end

  return Report:Text()
end

--- Create a detailed report of the Mission, listing all the details of the Task.
-- @param #MISSION self
-- @return #string
function MISSION:ReportDetails( ReportGroup )

  local Report = REPORT:New()
  
  -- List the name of the mission.
  local Name = self:GetName()
  
  -- Determine the status of the mission.
  local Status = "<" .. self:GetState() .. ">"
  
  Report:Add( string.format( '%s - %s - Task Detailed Report', Name, Status ) )
  
  -- Determine how many tasks are remaining.
  local TasksRemaining = 0
  for TaskID, Task in pairs( self:GetTasks() ) do
    local Task = Task -- Tasking.Task#TASK
    Report:Add( Task:ReportDetails( ReportGroup ) )
  end

  return Report:Text()
end

--- Get all the TASKs from the Mission. This function is useful in GoalFunctions.
-- @return {TASK,...} Structure of TASKS with the @{TASK} number as the key.
-- @usage
-- -- Get Tasks from the Mission.
-- Tasks = Mission:GetTasks()
-- env.info( "Task 2 Completion = " .. Tasks[2]:GetGoalPercentage() .. "%" )
function MISSION:GetTasks()

	return self.Tasks
end

--- Reports the briefing.
-- @param #MISSION self
-- @param Wrapper.Group#GROUP ReportGroup The group to which the report needs to be sent.
function MISSION:MenuReportBriefing( ReportGroup )

  local Report = self:ReportBriefing()
  
  self:GetCommandCenter():MessageTypeToGroup( Report, ReportGroup, MESSAGE.Type.Briefing )
end


--- Mark all the targets of the Mission on the Map.
-- @param #MISSION self
-- @param Wrapper.Group#GROUP ReportGroup
function MISSION:MenuMarkTargetLocations( ReportGroup )

  local Report = self:MarkTargetLocations( ReportGroup )
  
  self:GetCommandCenter():MessageTypeToGroup( Report, ReportGroup, MESSAGE.Type.Overview )
end



--- Report the task summary.
-- @param #MISSION self
-- @param Wrapper.Group#GROUP ReportGroup
function MISSION:MenuReportTasksSummary( ReportGroup )

  local Report = self:ReportSummary( ReportGroup )
  
  self:GetCommandCenter():MessageTypeToGroup( Report, ReportGroup, MESSAGE.Type.Overview )
end




--- @param #MISSION self
-- @param #string TaskStatus The status
-- @param Wrapper.Group#GROUP ReportGroup
function MISSION:MenuReportTasksPerStatus( ReportGroup, TaskStatus )

  local Report = self:ReportOverview( ReportGroup, TaskStatus )
  
  self:GetCommandCenter():MessageTypeToGroup( Report, ReportGroup, MESSAGE.Type.Overview )
end


--- @param #MISSION self
-- @param Wrapper.Group#GROUP ReportGroup
function MISSION:MenuReportPlayersPerTask( ReportGroup )

  local Report = self:ReportPlayersPerTask()
  
  self:GetCommandCenter():MessageTypeToGroup( Report, ReportGroup, MESSAGE.Type.Overview )
end

--- @param #MISSION self
-- @param Wrapper.Group#GROUP ReportGroup
function MISSION:MenuReportPlayersProgress( ReportGroup )

  local Report = self:ReportPlayersProgress()
  
  self:GetCommandCenter():MessageTypeToGroup( Report, ReportGroup, MESSAGE.Type.Overview )
end





