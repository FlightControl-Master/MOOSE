--- A MISSION is the main owner of a Mission orchestration within MOOSE	. The Mission framework orchestrates @{CLIENT}s, @{TASK}s, @{STAGE}s etc.
-- A @{CLIENT} needs to be registered within the @{MISSION} through the function @{AddClient}. A @{TASK} needs to be registered within the @{MISSION} through the function @{AddTask}.
-- @module Mission

--- The MISSION class
-- @type MISSION
-- @field #MISSION.Clients _Clients
-- @field Menu#MENU_COALITION MissionMenu
-- @field #string MissionBriefing
-- @extends Core.StateMachine#STATEMACHINE
MISSION = {
	ClassName = "MISSION",
	Name = "",
	MissionStatus = "PENDING",
	_Clients = {},
  TaskMenus = {},
  TaskCategoryMenus = {},
  TaskTypeMenus = {},
	_ActiveTasks = {},
	GoalFunction = nil,
	MissionReportTrigger = 0,
	MissionProgressTrigger = 0,
	MissionReportShow = false,
	MissionReportFlash = false,
	MissionTimeInterval = 0,
	MissionCoalition = "",
	SUCCESS = 1,
	FAILED = 2,
	REPEAT = 3,
	_GoalTasks = {}
}

--- @type MISSION.Clients
-- @list <Client#CLIENTS>

function MISSION:Meta()

	
	return self
end

--- This is the main MISSION declaration method. Each Mission is like the master or a Mission orchestration between, Clients, Tasks, Stages etc.
-- @param #MISSION self
-- @param Tasking.CommandCenter#COMMANDCENTER CommandCenter
-- @param #string MissionName is the name of the mission. This name will be used to reference the status of each mission by the players.
-- @param #string MissionPriority is a string indicating the "priority" of the Mission. f.e. "Primary", "Secondary" or "First", "Second". It is free format and up to the Mission designer to choose. There are no rules behind this field.
-- @param #string MissionBriefing is a string indicating the mission briefing to be shown when a player joins a @{CLIENT}.
-- @param DCSCoalitionObject#coalition MissionCoalition is a string indicating the coalition or party to which this mission belongs to. It is free format and can be chosen freely by the mission designer. Note that this field is not to be confused with the coalition concept of the ME. Examples of a Mission Coalition could be "NATO", "CCCP", "Intruders", "Terrorists"...
-- @return #MISSION self
function MISSION:New( CommandCenter, MissionName, MissionPriority, MissionBriefing, MissionCoalition )

  local self = BASE:Inherit( self, STATEMACHINE:New() ) -- Core.StateMachine#STATEMACHINE
  
	self:T( { MissionName, MissionPriority, MissionBriefing, MissionCoalition } )
  
  self.CommandCenter = CommandCenter
  CommandCenter:AddMission( self )
  
	self.Name = MissionName
	self.MissionPriority = MissionPriority
	self.MissionBriefing = MissionBriefing
	self.MissionCoalition = MissionCoalition
	
	self.Tasks = {}
	setmetatable( self.Tasks, { __mode = "v" } )

  -- Build the Fsm for the mission.
  
  self:SetInitialState( "Idle" )
  self:AddAction( "Idle", "Start", "Ongoing" )
  self:AddAction( "Ongoing", "Stop", "Idle" )
  self:AddAction( "Ongoing", "Finish", "Finished" )

	return self
end

--- Gets the mission name.
-- @param #MISSION self
-- @return #MISSION self
function MISSION:GetName()
  return self.Name
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
    local Task = Task -- Tasking.Task#TASK_BASE
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
-- @param Core.Menu#MENU_COALITION CommandCenterMenu
function MISSION:SetMenu()
  
  for _, Task in pairs( self.Tasks ) do
    local Task = Task -- Tasking.Task#TASK_BASE
    Task:SetMenu()  
  end
end

function MISSION:GetCommandCenter()
  return self.CommandCenter
end

--- Sets the Assigned Task menu.
-- @param #MISSION self
-- @param Task#TASK_BASE Task
-- @param #string MenuText The menu text.
-- @return #MISSION self
function MISSION:SetAssignedMenu( Task )
  
  for _, Task in pairs( self.Tasks ) do
    local Task = Task -- Task#TASK_BASE
    Task:RemoveMenu()
    Task:SetAssignedMenu()  
  end
  
end

--- Removes a Task menu.
-- @param #MISSION self
-- @param Task#TASK_BASE Task
-- @return #MISSION self
function MISSION:RemoveTaskMenu( Task )
    
  Task:RemoveMenu()  
end


--- Gets the mission menu for the coalition.
-- @param #MISSION self
-- @param Group#GROUP TaskGroup
-- @return Menu#MENU_COALITION self
function MISSION:GetMissionMenu( TaskGroup )

  local CommandCenter = self:GetCommandCenter()
  local CommandCenterMenu = CommandCenter.CommandCenterMenu

  local MissionName = self:GetName()

  local TaskGroupName = TaskGroup:GetName()
  local MissionMenu = MENU_GROUP:New( TaskGroup, MissionName, CommandCenterMenu )
  
  return MissionMenu
end


--- Clears the mission menu for the coalition.
-- @param #MISSION self
-- @return #MISSION self
function MISSION:ClearMissionMenu()
  self.MissionMenu:Remove()
  self.MissionMenu = nil
end

--- Get the TASK identified by the TaskNumber from the Mission. This function is useful in GoalFunctions.
-- @param #string TaskName The Name of the @{Task} within the @{Mission}.
-- @return Task#TASK_BASE The Task
-- @return #nil Returns nil if no task was found.
function MISSION:GetTask( TaskName  )
  self:F( { TaskName } )

  return self.Tasks[TaskName]
end


--- Register a @{Task} to be completed within the @{Mission}. 
-- Note that there can be multiple @{Task}s registered to be completed. 
-- Each Task can be set a certain Goals. The Mission will not be completed until all Goals are reached.
-- @param #MISSION self
-- @param Task#TASK_BASE Task is the @{Task} object.
-- @return Task#TASK_BASE The task added.
function MISSION:AddTask( Task )

  local TaskName = Task:GetTaskName()
  self:F( TaskName )
  self.Tasks[TaskName] = self.Tasks[TaskName] or { n = 0 }
  
  self.Tasks[TaskName] = Task

  return Task
end

--- Removes a @{Task} to be completed within the @{Mission}. 
-- Note that there can be multiple @{Task}s registered to be completed. 
-- Each Task can be set a certain Goals. The Mission will not be completed until all Goals are reached.
-- @param #MISSION self
-- @param Task#TASK_BASE Task is the @{Task} object.
-- @return #nil The cleaned Task reference.
function MISSION:RemoveTask( Task )

  local TaskName = Task:GetTaskName()

  self:F( TaskName )
  self.Tasks[TaskName] = self.Tasks[TaskName] or { n = 0 }

  Task:CleanUp() -- Cleans all events and sets task to nil to get Garbage Collected

  -- Ensure everything gets garbarge collected.
  self.Tasks[TaskName] = nil 
  Task = nil
  
  collectgarbage()
  
  return nil
end

--- Return the next @{Task} ID to be completed within the @{Mission}. 
-- @param #MISSION self
-- @param Task#TASK_BASE Task is the @{Task} object.
-- @return Task#TASK_BASE The task added.
function MISSION:GetNextTaskID( Task )

  local TaskName = Task:GetTaskName()
  self:F( TaskName )
  self.Tasks[TaskName] = self.Tasks[TaskName] or { n = 0 }
  
  self.Tasks[TaskName].n = self.Tasks[TaskName].n + 1

  return self.Tasks[TaskName].n
end



--- old stuff

--- Returns if a Mission has completed.
-- @return bool
function MISSION:IsCompleted()
	self:F()
	return self.MissionStatus == "ACCOMPLISHED"
end

--- Set a Mission to completed.
function MISSION:Completed()
	self:F()
	self.MissionStatus = "ACCOMPLISHED"
	self:StatusToClients()
end

--- Returns if a Mission is ongoing.
-- treturn bool
function MISSION:IsOngoing()
	self:F()
	return self.MissionStatus == "ONGOING"
end

--- Set a Mission to ongoing.
function MISSION:Ongoing()
	self:F()
	self.MissionStatus = "ONGOING"
	--self:StatusToClients()
end

--- Returns if a Mission is pending.
-- treturn bool
function MISSION:IsPending()
	self:F()
	return self.MissionStatus == "PENDING"
end

--- Set a Mission to pending.
function MISSION:Pending()
	self:F()
	self.MissionStatus = "PENDING"
	self:StatusToClients()
end

--- Returns if a Mission has failed.
-- treturn bool
function MISSION:IsFailed() 
	self:F()
	return self.MissionStatus == "FAILED"
end

--- Set a Mission to failed.
function MISSION:Failed()
	self:F()
	self.MissionStatus = "FAILED"
	self:StatusToClients()
end

--- Send the status of the MISSION to all Clients.
function MISSION:StatusToClients()
	self:F()
	if self.MissionReportFlash then
		for ClientID, Client in pairs( self._Clients ) do
			Client:Message( self.MissionCoalition .. ' "' .. self.Name .. '": ' .. self.MissionStatus .. '! ( ' .. self.MissionPriority .. ' mission ) ', 10, "Mission Command: Mission Status")
		end
	end
end

function MISSION:HasGroup( TaskGroup )
  local Has = false
  
  for TaskID, Task in pairs( self:GetTasks() ) do
    local Task = Task -- Tasking.Task#TASK_BASE
    if Task:HasGroup( TaskGroup ) then
      Has = true
      break
    end
  end
  
  return Has
end

--- Create a summary report of the mission (one line).
-- @param #MISSION self
-- @return #string
function MISSION:ReportStatus()

  -- List the name of the mission.
  local Name = self:GetName()
  
  -- Determine the status of the mission.
  local Status = self:GetState()
  
  -- Determine how many tasks are remaining.
  local TasksRemaining = 0
  for TaskID, Task in pairs( self:GetTasks() ) do
    local Task = Task -- Tasking.Task#TASK_BASE
    if Task:IsStateSuccess() or Task:IsStateFailed() then
    else
      TasksRemaining = TasksRemaining + 1
    end
  end

  return "Mission " .. Name .. " - " .. Status .. " - " .. TasksRemaining .. " tasks remaining."
end

--- Report the status of all MISSIONs to all active Clients.
function MISSION:ReportToAll()
	self:F()

	local AlivePlayers = ''
	for ClientID, Client in pairs( self._Clients ) do
		if  Client:GetDCSGroup() then
			if Client:GetClientGroupDCSUnit() then
				if Client:GetClientGroupDCSUnit():getLife() > 0.0 then
					if AlivePlayers == '' then
						AlivePlayers = ' Players: ' .. Client:GetClientGroupDCSUnit():getPlayerName()
					else
						AlivePlayers = AlivePlayers .. ' / ' .. Client:GetClientGroupDCSUnit():getPlayerName()
					end
				end
			end
		end
	end
	local Tasks = self:GetTasks()
	local TaskText = ""
	for TaskID, TaskData in pairs( Tasks ) do
		TaskText = TaskText .. "         - Task " .. TaskID .. ": " .. TaskData.Name .. ": " .. TaskData:GetGoalProgress() .. "\n"
	end
	MESSAGE:New( self.MissionCoalition .. ' "' .. self.Name .. '": ' .. self.MissionStatus .. ' ( ' .. self.MissionPriority .. ' mission )' .. AlivePlayers .. "\n" .. TaskText:gsub("\n$",""), 10, "Mission Command: Mission Report" ):ToAll()
end


--- Add a goal function to a MISSION. Goal functions are called when a @{TASK} within a mission has been completed.
-- @param function GoalFunction is the function defined by the mission designer to evaluate whether a certain goal has been reached after a @{TASK} finishes within the @{MISSION}. A GoalFunction must accept 2 parameters: Mission, Client, which contains the current MISSION object and the current CLIENT object respectively.
-- @usage
--  PatriotActivation = { 
--		{ "US SAM Patriot Zerti", false },
--		{ "US SAM Patriot Zegduleti", false },
--		{ "US SAM Patriot Gvleti", false }
--	}
--
--	function DeployPatriotTroopsGoal( Mission, Client )
--
--
--		-- Check if the cargo is all deployed for mission success.
--		for CargoID, CargoData in pairs( Mission._Cargos ) do
--			if Group.getByName( CargoData.CargoGroupName ) then
--				CargoGroup = Group.getByName( CargoData.CargoGroupName )
--				if CargoGroup then
--					-- Check if the cargo is ready to activate
--					CurrentLandingZoneID = routines.IsUnitInZones( CargoGroup:getUnits()[1], Mission:GetTask( 2 ).LandingZones ) -- The second task is the Deploytask to measure mission success upon
--					if CurrentLandingZoneID then
--						if PatriotActivation[CurrentLandingZoneID][2] == false then
--							-- Now check if this is a new Mission Task to be completed...
--							trigger.action.setGroupAIOn( Group.getByName( PatriotActivation[CurrentLandingZoneID][1] ) )
--							PatriotActivation[CurrentLandingZoneID][2] = true
--							MessageToBlue( "Mission Command: Message to all airborne units! The " .. PatriotActivation[CurrentLandingZoneID][1] .. " is armed. Our air defenses are now stronger.", 60, "BLUE/PatriotDefense" )
--							MessageToRed( "Mission Command: Our satellite systems are detecting additional NATO air defenses. To all airborne units: Take care!!!", 60, "RED/PatriotDefense" )
--							Mission:GetTask( 2 ):AddGoalCompletion( "Patriots activated", PatriotActivation[CurrentLandingZoneID][1], 1 ) -- Register Patriot activation as part of mission goal.
--						end
--					end
--				end
--			end
--		end
--	end
--
--	local Mission = MISSIONSCHEDULER.AddMission( 'NATO Transport Troops', 'Operational', 'Transport 3 groups of air defense engineers from our barracks "Gold" and "Titan" to each patriot battery control center to activate our air defenses.', 'NATO' )
--	Mission:AddGoalFunction( DeployPatriotTroopsGoal )
function MISSION:AddGoalFunction( GoalFunction )
	self:F()
	self.GoalFunction = GoalFunction 
end

--- Register a new @{CLIENT} to participate within the mission.
-- @param CLIENT Client is the @{CLIENT} object. The object must have been instantiated with @{CLIENT:New}.
-- @return CLIENT
-- @usage
-- Add a number of Client objects to the Mission.
-- 	Mission:AddClient( CLIENT:FindByName( 'US UH-1H*HOT-Deploy Troops 1', 'Transport 3 groups of air defense engineers from our barracks "Gold" and "Titan" to each patriot battery control center to activate our air defenses.' ):Transport() )
--	Mission:AddClient( CLIENT:FindByName( 'US UH-1H*RAMP-Deploy Troops 3', 'Transport 3 groups of air defense engineers from our barracks "Gold" and "Titan" to each patriot battery control center to activate our air defenses.' ):Transport() )
--	Mission:AddClient( CLIENT:FindByName( 'US UH-1H*HOT-Deploy Troops 2', 'Transport 3 groups of air defense engineers from our barracks "Gold" and "Titan" to each patriot battery control center to activate our air defenses.' ):Transport() )
--	Mission:AddClient( CLIENT:FindByName( 'US UH-1H*RAMP-Deploy Troops 4', 'Transport 3 groups of air defense engineers from our barracks "Gold" and "Titan" to each patriot battery control center to activate our air defenses.' ):Transport() )
function MISSION:AddClient( Client )
	self:F( { Client } )

	local Valid = true
 
	if Valid then
		self._Clients[Client.ClientName] = Client
	end

	return Client
end

--- Find a @{CLIENT} object within the @{MISSION} by its ClientName.
-- @param CLIENT ClientName is a string defining the Client Group as defined within the ME.
-- @return CLIENT
-- @usage
-- -- Seach for Client "Bomber" within the Mission.
-- local BomberClient = Mission:FindClient( "Bomber" )
function MISSION:FindClient( ClientName )
	self:F( { self._Clients[ClientName] } )
	return self._Clients[ClientName]
end


--- Get all the TASKs from the Mission. This function is useful in GoalFunctions.
-- @return {TASK,...} Structure of TASKS with the @{TASK} number as the key.
-- @usage
-- -- Get Tasks from the Mission.
-- Tasks = Mission:GetTasks()
-- env.info( "Task 2 Completion = " .. Tasks[2]:GetGoalPercentage() .. "%" )
function MISSION:GetTasks()
	self:F()

	return self.Tasks
end
 

--[[
  _TransportExecuteStage: Defines the different stages of Transport unload/load execution. This table is internal and is used to control the validity of Transport load/unload timing.
  
  - _TransportExecuteStage.EXECUTING
  - _TransportExecuteStage.SUCCESS
  - _TransportExecuteStage.FAILED
  
--]]
_TransportExecuteStage = { 
  NONE = 0,
  EXECUTING = 1, 
  SUCCESS = 2, 
  FAILED = 3
}


--- The MISSIONSCHEDULER is an OBJECT and is the main scheduler of ALL active MISSIONs registered within this scheduler. It's workings are considered internal and is automatically created when the Mission.lua file is included.
-- @type MISSIONSCHEDULER
-- @field #MISSIONSCHEDULER.MISSIONS Missions
MISSIONSCHEDULER = {
  Missions = {},
  MissionCount = 0,
  TimeIntervalCount = 0,
  TimeIntervalShow = 150,
  TimeSeconds = 14400,
  TimeShow = 5
}

--- @type MISSIONSCHEDULER.MISSIONS
-- @list <#MISSION> Mission

--- This is the main MISSIONSCHEDULER Scheduler function. It is considered internal and is automatically created when the Mission.lua file is included.
function MISSIONSCHEDULER.Scheduler()
  

	-- loop through the missions in the TransportTasks
	for MissionName, MissionData in pairs( MISSIONSCHEDULER.Missions ) do
	  
	  local Mission = MissionData -- #MISSION
    
		if not Mission:IsCompleted() then
		
			-- This flag will monitor if for this mission, there are clients alive. If this flag is still false at the end of the loop, the mission status will be set to Pending (if not Failed or Completed).
			local ClientsAlive = false
			
			for ClientID, ClientData in pairs( Mission._Clients ) do
			  
			  local Client = ClientData -- Client#CLIENT
			
				if Client:IsAlive() then

					-- There is at least one Client that is alive... So the Mission status is set to Ongoing.
					ClientsAlive = true 
					
					-- If this Client was not registered as Alive before:
					-- 1. We register the Client as Alive.
					-- 2. We initialize the Client Tasks and make a link to the original Mission Task.
					-- 3. We initialize the Cargos.
					-- 4. We flag the Mission as Ongoing.
					if not Client.ClientAlive then
						Client.ClientAlive = true
						Client.ClientBriefingShown = false
						for TaskNumber, Task in pairs( Mission._Tasks ) do
							-- Note that this a deepCopy. Each client must have their own Tasks with own Stages!!!
							Client._Tasks[TaskNumber] = routines.utils.deepCopy( Mission._Tasks[TaskNumber] )
							-- Each MissionTask must point to the original Mission.
							Client._Tasks[TaskNumber].MissionTask = Mission._Tasks[TaskNumber]
							Client._Tasks[TaskNumber].Cargos = Mission._Tasks[TaskNumber].Cargos
							Client._Tasks[TaskNumber].LandingZones = Mission._Tasks[TaskNumber].LandingZones
						end

						Mission:Ongoing()				
					end
					

					-- For each Client, check for each Task the state and evolve the mission.
					-- This flag will indicate if the Task of the Client is Complete.
					local TaskComplete = false

					for TaskNumber, Task in pairs( Client._Tasks ) do

						if not Task.Stage then
							Task:SetStage( 1 )
						end

						
						local TransportTime = timer.getTime()
				
						if not Task:IsDone() then

							if Task:Goal() then
								Task:ShowGoalProgress( Mission, Client )
							end
							
							--env.info( 'Scheduler: Mission = ' .. Mission.Name .. ' / Client = ' .. Client.ClientName .. ' / Task = ' .. Task.Name .. ' / Stage = ' .. Task.ActiveStage .. ' - ' .. Task.Stage.Name .. ' - ' .. Task.Stage.StageType )
							
							-- Action
							if Task:StageExecute() then
								Task.Stage:Execute( Mission, Client, Task )
							end
						  
							-- Wait until execution is finished            
							if  Task.ExecuteStage == _TransportExecuteStage.EXECUTING then
								Task.Stage:Executing( Mission, Client, Task )
							end
						  
							-- Validate completion or reverse to earlier stage
							if Task.Time + Task.Stage.WaitTime <= TransportTime then
								Task:SetStage( Task.Stage:Validate( Mission, Client, Task ) )
							end
							 
							if Task:IsDone() then
								--env.info( 'Scheduler: Mission '.. Mission.Name .. ' Task ' .. Task.Name .. ' Stage ' .. Task.Stage.Name .. ' done. TaskComplete = ' .. string.format ( "%s", TaskComplete and "true" or "false" ) )
								TaskComplete = true -- when a task is not yet completed, a mission cannot be completed
								
							else
								-- break only if this task is not yet done, so that future task are not yet activated.
								TaskComplete = false -- when a task is not yet completed, a mission cannot be completed
								--env.info( 'Scheduler: Mission "'.. Mission.Name .. '" Task "' .. Task.Name .. '" Stage "' .. Task.Stage.Name .. '" break. TaskComplete = ' .. string.format ( "%s", TaskComplete and "true" or "false" ) )
								break
							end

							if TaskComplete then

								if Mission.GoalFunction ~= nil then
									Mission.GoalFunction( Mission, Client )
								end
								if MISSIONSCHEDULER.Scoring then
								  MISSIONSCHEDULER.Scoring:_AddMissionTaskScore( Client:GetClientGroupDCSUnit(), Mission.Name, 25 )
								end

--								if not Mission:IsCompleted() then
--								end
							end
						end
					end
					
					local MissionComplete = true
					for TaskNumber, Task in pairs( Mission._Tasks ) do
						if Task:Goal() then
--							Task:ShowGoalProgress( Mission, Client )
							if Task:IsGoalReached() then
							else
								MissionComplete = false
							end
						else
							MissionComplete = false -- If there is no goal, the mission should never be ended. The goal status will be set somewhere else.
						end
					end

					if MissionComplete then
						Mission:Completed()
						if MISSIONSCHEDULER.Scoring then
						  MISSIONSCHEDULER.Scoring:_AddMissionScore( Mission.Name, 100 )
						end
					else
						if TaskComplete then
							-- Reset for new tasking of active client
							Client.ClientAlive = false -- Reset the client tasks.
						end
					end
					

				else
					if Client.ClientAlive then
						env.info( 'Scheduler: Client "' .. Client.ClientName .. '" is inactive.' )
						Client.ClientAlive = false
						
						-- This is tricky. If we sanitize Client._Tasks before sanitizing Client._Tasks[TaskNumber].MissionTask, then the original MissionTask will be sanitized, and will be lost within the garbage collector.
						-- So first sanitize Client._Tasks[TaskNumber].MissionTask, after that, sanitize only the whole _Tasks structure...
						--Client._Tasks[TaskNumber].MissionTask = nil
						--Client._Tasks = nil
					end
				end
			end

			-- If all Clients of this Mission are not activated, then the Mission status needs to be put back into Pending status.
			-- But only if the Mission was Ongoing. In case the Mission is Completed or Failed, the Mission status may not be changed. In these cases, this will be the last run of this Mission in the Scheduler.
			if ClientsAlive == false then
				if Mission:IsOngoing() then
					-- Mission status back to pending...
					Mission:Pending()
				end
			end
		end
		
		Mission:StatusToClients()
		
		if Mission:ReportTrigger() then
			Mission:ReportToAll()
		end
	end
	
	return true
end

--- Start the MISSIONSCHEDULER.
function MISSIONSCHEDULER.Start()
  if MISSIONSCHEDULER ~= nil then
    --MISSIONSCHEDULER.SchedulerId = routines.scheduleFunction( MISSIONSCHEDULER.Scheduler, { }, 0, 2 )
    MISSIONSCHEDULER.SchedulerId = SCHEDULER:New( nil, MISSIONSCHEDULER.Scheduler, { }, 0, 2 )
  end
end

--- Stop the MISSIONSCHEDULER.
function MISSIONSCHEDULER.Stop()
	if MISSIONSCHEDULER.SchedulerId then
		routines.removeFunction(MISSIONSCHEDULER.SchedulerId)
		MISSIONSCHEDULER.SchedulerId = nil
	end
end

--- This is the main MISSION declaration method. Each Mission is like the master or a Mission orchestration between, Clients, Tasks, Stages etc.
-- @param Mission is the MISSION object instantiated by @{MISSION:New}.
-- @return MISSION
-- @usage 
-- -- Declare a mission.
-- Mission = MISSION:New( 'Russia Transport Troops SA-6', 
--                        'Operational', 
--                        'Transport troops from the control center to one of the SA-6 SAM sites to activate their operation.', 
--                        'Russia' )
-- MISSIONSCHEDULER:AddMission( Mission )
function MISSIONSCHEDULER.AddMission( Mission )
	MISSIONSCHEDULER.Missions[Mission.Name] = Mission
	MISSIONSCHEDULER.MissionCount = MISSIONSCHEDULER.MissionCount + 1
	-- Add an overall AI Client for the AI tasks... This AI Client will facilitate the Events in the background for each Task. 
	--MissionAdd:AddClient( CLIENT:Register( 'AI' ) )
	
	return Mission
end

--- Remove a MISSION from the MISSIONSCHEDULER.
-- @param MissionName is the name of the MISSION given at declaration using @{AddMission}.
-- @usage
-- -- Declare a mission.
-- Mission = MISSION:New( 'Russia Transport Troops SA-6', 
--                        'Operational', 
--                        'Transport troops from the control center to one of the SA-6 SAM sites to activate their operation.', 
--                        'Russia' )
-- MISSIONSCHEDULER:AddMission( Mission )
--
-- -- Now remove the Mission.
-- MISSIONSCHEDULER:RemoveMission( 'Russia Transport Troops SA-6' )
function MISSIONSCHEDULER.RemoveMission( MissionName )
	MISSIONSCHEDULER.Missions[MissionName] = nil
	MISSIONSCHEDULER.MissionCount = MISSIONSCHEDULER.MissionCount - 1
end

--- Find a MISSION within the MISSIONSCHEDULER.
-- @param MissionName is the name of the MISSION given at declaration using @{AddMission}.
-- @return MISSION
-- @usage
-- -- Declare a mission.
-- Mission = MISSION:New( 'Russia Transport Troops SA-6', 
--                        'Operational', 
--                        'Transport troops from the control center to one of the SA-6 SAM sites to activate their operation.', 
--                        'Russia' )
-- MISSIONSCHEDULER:AddMission( Mission )
--
-- -- Now find the Mission.
-- MissionFind = MISSIONSCHEDULER:FindMission( 'Russia Transport Troops SA-6' )
function MISSIONSCHEDULER.FindMission( MissionName )
	return MISSIONSCHEDULER.Missions[MissionName]
end

-- Internal function used by the MISSIONSCHEDULER menu.
function MISSIONSCHEDULER.ReportMissionsShow( )
	for MissionName, Mission in pairs( MISSIONSCHEDULER.Missions ) do
		Mission.MissionReportShow = true
		Mission.MissionReportFlash = false 
	end
end

-- Internal function used by the MISSIONSCHEDULER menu.
function MISSIONSCHEDULER.ReportMissionsFlash( TimeInterval )
	local Count = 0
	for MissionName, Mission in pairs( MISSIONSCHEDULER.Missions ) do
		Mission.MissionReportShow = false 
		Mission.MissionReportFlash = true
		Mission.MissionReportTrigger = timer.getTime() + Count * TimeInterval
		Mission.MissionTimeInterval = MISSIONSCHEDULER.MissionCount * TimeInterval 
		env.info( "TimeInterval = "  .. Mission.MissionTimeInterval )
		Count = Count + 1
	end
end

-- Internal function used by the MISSIONSCHEDULER menu.
function MISSIONSCHEDULER.ReportMissionsHide( Prm )
	for MissionName, Mission in pairs( MISSIONSCHEDULER.Missions ) do
		Mission.MissionReportShow = false
		Mission.MissionReportFlash = false
	end
end

--- Enables a MENU option in the communications menu under F10 to control the status of the active missions.
-- This function should be called only once when starting the MISSIONSCHEDULER.
function MISSIONSCHEDULER.ReportMenu()
	local ReportMenu = SUBMENU:New( 'Status' )
	local ReportMenuShow = COMMANDMENU:New( 'Show Report Missions', ReportMenu, MISSIONSCHEDULER.ReportMissionsShow, 0 )
	local ReportMenuFlash = COMMANDMENU:New('Flash Report Missions', ReportMenu, MISSIONSCHEDULER.ReportMissionsFlash, 120 )
	local ReportMenuHide = COMMANDMENU:New( 'Hide Report Missions', ReportMenu, MISSIONSCHEDULER.ReportMissionsHide, 0 )
end

--- Show the remaining mission time.
function MISSIONSCHEDULER:TimeShow()
	self.TimeIntervalCount = self.TimeIntervalCount + 1
	if self.TimeIntervalCount >= self.TimeTriggerShow then
		local TimeMsg = string.format("%00d", ( self.TimeSeconds / 60 ) - ( timer.getTime() / 60 )) .. ' minutes left until mission reload.'
		MESSAGE:New( TimeMsg, self.TimeShow, "Mission time" ):ToAll()
		self.TimeIntervalCount = 0
	end
end

function MISSIONSCHEDULER:Time( TimeSeconds, TimeIntervalShow, TimeShow )

	self.TimeIntervalCount = 0
	self.TimeSeconds = TimeSeconds
	self.TimeIntervalShow = TimeIntervalShow
	self.TimeShow = TimeShow
end

--- Adds a mission scoring to the game.
function MISSIONSCHEDULER:Scoring( Scoring )

  self.Scoring = Scoring
end

