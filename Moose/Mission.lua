--- A MISSION is the main owner of a Mission orchestration within MOOSE	. The Mission framework orchestrates @{CLIENT}s, @{TASK}s, @{STAGE}s etc.
-- A @{CLIENT} needs to be registered within the @{MISSION} through the function @{AddClient}. A @{TASK} needs to be registered within the @{MISSION} through the function @{AddTask}.
-- @module MISSION

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Client" )
Include.File( "Task" )

--- The MISSION class
-- @type
MISSION = {
	ClassName = "MISSION",
	Name = "",
	MissionStatus = "PENDING",
	_Clients = {},
	_Tasks = {},
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


function MISSION:Meta()

	local self = BASE:Inherit( self, BASE:New() )
	self:T()
	
	return self
end

--- This is the main MISSION declaration method. Each Mission is like the master or a Mission orchestration between, Clients, Tasks, Stages etc.
-- @param string MissionName is the name of the mission. This name will be used to reference the status of each mission by the players.
-- @param string MissionPriority is a string indicating the "priority" of the Mission. f.e. "Primary", "Secondary" or "First", "Second". It is free format and up to the Mission designer to choose. There are no rules behind this field.
-- @param string MissionBriefing is a string indicating the mission briefing to be shown when a player joins a @{CLIENT}.
-- @param string MissionCoalition is a string indicating the coalition or party to which this mission belongs to. It is free format and can be chosen freely by the mission designer. Note that this field is not to be confused with the coalition concept of the ME. Examples of a Mission Coalition could be "NATO", "CCCP", "Intruders", "Terrorists"...
-- @return MISSION
-- @usage 
-- -- Declare a few missions.
-- local Mission = MISSIONSCHEDULER.AddMission( 'Russia Transport Troops SA-6', 'Operational', 'Transport troops from the control center to one of the SA-6 SAM sites to activate their operation.', 'Russia' )
-- local Mission = MISSIONSCHEDULER.AddMission( 'Patriots', 'Primary', 'Our intelligence reports that 3 Patriot SAM defense batteries are located near Ruisi, Kvarhiti and Gori.', 'Russia'  )
-- local Mission = MISSIONSCHEDULER.AddMission( 'Package Delivery', 'Operational', 'In order to be in full control of the situation, we need you to deliver a very important package at a secret location. Fly undetected through the NATO defenses and deliver the secret package. The secret agent is located at waypoint 4.', 'Russia'  )
-- local Mission = MISSIONSCHEDULER.AddMission( 'Rescue General', 'Tactical', 'Our intelligence has received a remote signal behind Gori. We believe it is a very important Russian General that was captured by Georgia. Go out there and rescue him! Ensure you stay out of the battle zone, keep south. Waypoint 4 is the location of our Russian General.', 'Russia'  )
-- local Mission = MISSIONSCHEDULER.AddMission( 'NATO Transport Troops', 'Operational', 'Transport 3 groups of air defense engineers from our barracks "Gold" and "Titan" to each patriot battery control center to activate our air defenses.', 'NATO' )
-- local Mission = MISSIONSCHEDULER.AddMission( 'SA-6 SAMs', 'Primary', 'Our intelligence reports that 3 SA-6 SAM defense batteries are located near Didmukha, Khetagurov and Berula. Eliminate the Russian SAMs.', 'NATO'  )
-- local Mission = MISSIONSCHEDULER.AddMission( 'NATO Sling Load', 'Operational', 'Fly to the cargo pickup zone at Dzegvi or Kaspi, and sling the cargo to Soganlug airbase.', 'NATO' )
-- local Mission = MISSIONSCHEDULER.AddMission( 'Rescue secret agent', 'Tactical', 'In order to be in full control of the situation, we need you to rescue a secret agent from the woods behind enemy lines. Avoid the Russian defenses and rescue the agent. Keep south until Khasuri, and keep your eyes open for any SAM presence. The agent is located at waypoint 4 on your kneeboard.', 'NATO'  )
function MISSION:New( MissionName, MissionPriority, MissionBriefing, MissionCoalition )

	self = MISSION:Meta()
	self:T({ MissionName, MissionPriority, MissionBriefing, MissionCoalition })
  
	local Valid = true
  
	Valid = routines.ValidateString( MissionName, "MissionName", Valid )
	Valid = routines.ValidateString( MissionPriority, "MissionPriority", Valid )
	Valid = routines.ValidateString( MissionBriefing, "MissionBriefing", Valid )
	Valid = routines.ValidateString( MissionCoalition, "MissionCoalition", Valid )
  
	if Valid then
		self.Name = MissionName
		self.MissionPriority = MissionPriority
		self.MissionBriefing = MissionBriefing
		self.MissionCoalition = MissionCoalition
	end

	return self
end

--- Returns if a Mission has completed.
-- @return bool
function MISSION:IsCompleted()
	self:T()
	return self.MissionStatus == "ACCOMPLISHED"
end

--- Set a Mission to completed.
function MISSION:Completed()
	self:T()
	self.MissionStatus = "ACCOMPLISHED"
	self:StatusToClients()
end

--- Returns if a Mission is ongoing.
-- treturn bool
function MISSION:IsOngoing()
	self:T()
	return self.MissionStatus == "ONGOING"
end

--- Set a Mission to ongoing.
function MISSION:Ongoing()
	self:T()
	self.MissionStatus = "ONGOING"
	--self:StatusToClients()
end

--- Returns if a Mission is pending.
-- treturn bool
function MISSION:IsPending()
	self:T()
	return self.MissionStatus == "PENDING"
end

--- Set a Mission to pending.
function MISSION:Pending()
	self:T()
	self.MissionStatus = "PENDING"
	self:StatusToClients()
end

--- Returns if a Mission has failed.
-- treturn bool
function MISSION:IsFailed() 
	self:T()
	return self.MissionStatus == "FAILED"
end

--- Set a Mission to failed.
function MISSION:Failed()
	self:T()
	self.MissionStatus = "FAILED"
	self:StatusToClients()
end

--- Send the status of the MISSION to all Clients.
function MISSION:StatusToClients()
	self:T()
	if self.MissionReportFlash then
		for ClientID, Client in pairs( self._Clients ) do
			Client:Message( self.MissionCoalition .. ' "' .. self.Name .. '": ' .. self.MissionStatus .. '! ( ' .. self.MissionPriority .. ' mission ) ', 10,  self.Name .. '/Status', "Mission Command: Mission Status")
		end
	end
end

--- Handles the reporting. After certain time intervals, a MISSION report MESSAGE will be shown to All Players.
function MISSION:ReportTrigger()
	self:T()

	if self.MissionReportShow == true then
		self.MissionReportShow = false
trace.r( "MISSION", "1", { true } )
		return true
	else
		if self.MissionReportFlash == true then
			if timer.getTime() >= self.MissionReportTrigger then
				self.MissionReportTrigger = timer.getTime() + self.MissionTimeInterval
trace.r( "MISSION", "2", { true } )
				return true
			else
trace.r( "MISSION", "3", { false } )
				return false
			end
		else
trace.r( "MISSION", "4", { false } )
			return false 
		end
	end
trace.e()
end

--- Report the status of all MISSIONs to all active Clients.
function MISSION:ReportToAll()
	self:T()

	local AlivePlayers = ''
	for ClientID, Client in pairs( self._Clients ) do
		if  Client:ClientGroup() then
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
	MESSAGE:New( self.MissionCoalition .. ' "' .. self.Name .. '": ' .. self.MissionStatus .. ' ( ' .. self.MissionPriority .. ' mission )' .. AlivePlayers .. "\n" .. TaskText:gsub("\n$",""), "Mission Command: Mission Report", 10,  self.Name .. '/Status'):ToAll()
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
	self:T()
	self.GoalFunction = GoalFunction 
end

--- Show the briefing of the MISSION to the CLIENT.
-- @param CLIENT Client to show briefing to.
-- @return CLIENT
function MISSION:ShowBriefing( Client )
	self:T( { Client.ClientName } )

	if not Client.ClientBriefingShown then
		Client.ClientBriefingShown = true
		local Briefing = self.MissionBriefing 
		if Client.ClientBriefing then
			Briefing = Briefing .. "\n" .. Client.ClientBriefing
		end
		Briefing = Briefing .. "\n (Press [LEFT ALT]+[B] to view the graphical documentation.)"
		Client:Message( Briefing, 30,  self.Name .. '/MissionBriefing', "Command: Mission Briefing" )
	end

	return Client
end

--- Register a new @{CLIENT} to participate within the mission.
-- @param CLIENT Client is the @{CLIENT} object. The object must have been instantiated with @{CLIENT:New}.
-- @return CLIENT
-- @usage
-- Add a number of Client objects to the Mission.
-- 	Mission:AddClient( CLIENT:New( 'US UH-1H*HOT-Deploy Troops 1', 'Transport 3 groups of air defense engineers from our barracks "Gold" and "Titan" to each patriot battery control center to activate our air defenses.' ):Transport() )
--	Mission:AddClient( CLIENT:New( 'US UH-1H*RAMP-Deploy Troops 3', 'Transport 3 groups of air defense engineers from our barracks "Gold" and "Titan" to each patriot battery control center to activate our air defenses.' ):Transport() )
--	Mission:AddClient( CLIENT:New( 'US UH-1H*HOT-Deploy Troops 2', 'Transport 3 groups of air defense engineers from our barracks "Gold" and "Titan" to each patriot battery control center to activate our air defenses.' ):Transport() )
--	Mission:AddClient( CLIENT:New( 'US UH-1H*RAMP-Deploy Troops 4', 'Transport 3 groups of air defense engineers from our barracks "Gold" and "Titan" to each patriot battery control center to activate our air defenses.' ):Transport() )
function MISSION:AddClient( Client )
	self:T( { Client } )

	local Valid = true
 
	if Valid then
		self._Clients[Client.ClientName] = Client
	end

trace.r( self.ClassName, "" )
	return Client
end

--- Find a @{CLIENT} object within the @{MISSION} by its ClientName.
-- @param CLIENT ClientName is a string defining the Client Group as defined within the ME.
-- @return CLIENT
-- @usage
-- -- Seach for Client "Bomber" within the Mission.
-- local BomberClient = Mission:FindClient( "Bomber" )
function MISSION:FindClient( ClientName )
	self:T( { self._Clients[ClientName] } )
	return self._Clients[ClientName]
end


--- Register a @{TASK} to be completed within the @{MISSION}. Note that there can be multiple @{TASK}s registered to be completed. Each TASK can be set a certain Goal. The MISSION will not be completed until all Goals are reached.
-- @param TASK Task is the @{TASK} object. The object must have been instantiated with @{TASK:New} or any of its inherited @{TASK}s.
-- @param number TaskNumber is the sequence number of the TASK within the MISSION. This number does have to be chronological.
-- @return TASK
-- @usage
-- -- Define a few tasks for the Mission.
--	PickupZones = { "NATO Gold Pickup Zone", "NATO Titan Pickup Zone" }
--	PickupSignalUnits = { "NATO Gold Coordination Center", "NATO Titan Coordination Center" }
--
--	-- Assign the Pickup Task
--	local PickupTask = PICKUPTASK:New( PickupZones, CARGO_TYPE.ENGINEERS, CLIENT.ONBOARDSIDE.LEFT )
--	PickupTask:AddSmokeBlue( PickupSignalUnits  )
--	PickupTask:SetGoalTotal( 3 )
--	Mission:AddTask( PickupTask, 1 )
--
--	-- Assign the Deploy Task
--	local PatriotActivationZones = { "US Patriot Battery 1 Activation", "US Patriot Battery 2 Activation", "US Patriot Battery 3 Activation" }
--	local PatriotActivationZonesSmokeUnits = { "US SAM Patriot - Battery 1 Control", "US SAM Patriot - Battery 2 Control", "US SAM Patriot - Battery 3 Control" }
--	local DeployTask = DEPLOYTASK:New( PatriotActivationZones, CARGO_TYPE.ENGINEERS )
--	--DeployTask:SetCargoTargetZoneName( 'US Troops Attack ' .. math.random(2) )
--	DeployTask:AddSmokeBlue( PatriotActivationZonesSmokeUnits )
--	DeployTask:SetGoalTotal( 3 )
--	DeployTask:SetGoalTotal( 3, "Patriots activated" )
--	Mission:AddTask( DeployTask, 2 )
	
function MISSION:AddTask( Task, TaskNumber )
	self:T()

	self._Tasks[TaskNumber] = Task
	self._Tasks[TaskNumber]:EnableEvents()
	self._Tasks[TaskNumber].ID = TaskNumber

	return Task
 end

--- Get the TASK idenified by the TaskNumber from the Mission. This function is useful in GoalFunctions.
-- @param number TaskNumber is the number of the @{TASK} within the @{MISSION}.
-- @return TASK
-- @usage
-- -- Get Task 2 from the Mission.
-- Task2 = Mission:GetTask( 2 )

function MISSION:GetTask( TaskNumber )
	self:T()

	local Valid = true

	local Task = nil

	if type(TaskNumber) ~= "number" then
		Valid = false
	end

	if Valid then
		Task = self._Tasks[TaskNumber]
	end

	return Task
end

--- Get all the TASKs from the Mission. This function is useful in GoalFunctions.
-- @return {TASK,...} Structure of TASKS with the @{TASK} number as the key.
-- @usage
-- -- Get Tasks from the Mission.
-- Tasks = Mission:GetTasks()
-- env.info( "Task 2 Completion = " .. Tasks[2]:GetGoalPercentage() .. "%" )
function MISSION:GetTasks()
	self:T()

	return self._Tasks
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
MISSIONSCHEDULER = {
  Missions = {},
  MissionCount = 0,
  TimeIntervalCount = 0,
  TimeIntervalShow = 150,
  TimeSeconds = 14400,
  TimeShow = 5
}

--- This is the main MISSIONSCHEDULER Scheduler function. It is considered internal and is automatically created when the Mission.lua file is included.
function MISSIONSCHEDULER.Scheduler()
trace.scheduled("MISSIONSCHEDULER","Scheduler")

	-- loop through the missions in the TransportTasks
	for MissionName, Mission in pairs( MISSIONSCHEDULER.Missions ) do
	
		trace.i( "MISSIONSCHEDULER", MissionName )
		
		if not Mission:IsCompleted() then
		
			-- This flag will monitor if for this mission, there are clients alive. If this flag is still false at the end of the loop, the mission status will be set to Pending (if not Failed or Completed).
			local ClientsAlive = false
			
			for ClientID, Client in pairs( Mission._Clients ) do
			
				trace.i( "MISSIONSCHEDULER", "Client: " .. Client.ClientName )

				if Client:ClientGroup() then

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
					TaskComplete = false

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
								trace.i( "MISSIONSCHEDULER", "Task " .. Task.Name .. " is Done." )
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
								_Database:_AddMissionTaskScore( Client:GetClientGroupDCSUnit(), Mission.Name, 25 )

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
						_Database:_AddMissionScore( Mission.Name, 100 ) 
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

trace.e()
end

--- Start the MISSIONSCHEDULER.
function MISSIONSCHEDULER.Start()
trace.f("MISSIONSCHEDULER")
  if MISSIONSCHEDULER ~= nil then
    MISSIONSCHEDULER.SchedulerId = routines.scheduleFunction( MISSIONSCHEDULER.Scheduler, { }, 0, 2 )
  end
trace.e()
end

--- Stop the MISSIONSCHEDULER.
function MISSIONSCHEDULER.Stop()
trace.f("MISSIONSCHEDULER")
	if MISSIONSCHEDULER.SchedulerId then
		routines.removeFunction(MISSIONSCHEDULER.SchedulerId)
		MISSIONSCHEDULER.SchedulerId = nil
	end
trace.e()
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
trace.f("MISSIONSCHEDULER")
	MISSIONSCHEDULER.Missions[Mission.Name] = Mission
	MISSIONSCHEDULER.MissionCount = MISSIONSCHEDULER.MissionCount + 1
	-- Add an overall AI Client for the AI tasks... This AI Client will facilitate the Events in the background for each Task. 
	--MissionAdd:AddClient( CLIENT:New( 'AI' ) )
	
trace.r( "MISSIONSCHEDULER", "" )
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
trace.f("MISSIONSCHEDULER")
	MISSIONSCHEDULER.Missions[MissionName] = nil
	MISSIONSCHEDULER.MissionCount = MISSIONSCHEDULER.MissionCount - 1
trace.e()
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
trace.f("MISSIONSCHEDULER")
trace.r( "MISSIONSCHEDULER", "" )
	return MISSIONSCHEDULER.Missions[MissionName]
end

-- Internal function used by the MISSIONSCHEDULER menu.
function MISSIONSCHEDULER.ReportMissionsShow( )
trace.menu("MISSIONSCHEDULER","ReportMissionsShow")
	for MissionName, Mission in pairs( MISSIONSCHEDULER.Missions ) do
		Mission.MissionReportShow = true
		Mission.MissionReportFlash = false 
	end
trace.e()
end

-- Internal function used by the MISSIONSCHEDULER menu.
function MISSIONSCHEDULER.ReportMissionsFlash( TimeInterval )
trace.menu("MISSIONSCHEDULER","ReportMissionsFlash")
	local Count = 0
	for MissionName, Mission in pairs( MISSIONSCHEDULER.Missions ) do
		Mission.MissionReportShow = false 
		Mission.MissionReportFlash = true
		Mission.MissionReportTrigger = timer.getTime() + Count * TimeInterval
		Mission.MissionTimeInterval = MISSIONSCHEDULER.MissionCount * TimeInterval 
		env.info( "TimeInterval = "  .. Mission.MissionTimeInterval )
		Count = Count + 1
	end
trace.e()
end

-- Internal function used by the MISSIONSCHEDULER menu.
function MISSIONSCHEDULER.ReportMissionsHide( Prm )
trace.menu("MISSIONSCHEDULER","ReportMissionsHide")
	for MissionName, Mission in pairs( MISSIONSCHEDULER.Missions ) do
		Mission.MissionReportShow = false
		Mission.MissionReportFlash = false
	end
trace.e()
end

--- Enables a MENU option in the communications menu under F10 to control the status of the active missions.
-- This function should be called only once when starting the MISSIONSCHEDULER.
function MISSIONSCHEDULER.ReportMenu()
trace.f("MISSIONSCHEDULER")
	local ReportMenu = SUBMENU:New( 'Status' )
	local ReportMenuShow = COMMANDMENU:New( 'Show Report Missions', ReportMenu, MISSIONSCHEDULER.ReportMissionsShow, 0 )
	local ReportMenuFlash = COMMANDMENU:New('Flash Report Missions', ReportMenu, MISSIONSCHEDULER.ReportMissionsFlash, 120 )
	local ReportMenuHide = COMMANDMENU:New( 'Hide Report Missions', ReportMenu, MISSIONSCHEDULER.ReportMissionsHide, 0 )
trace.e()
end

--- Show the remaining mission time.
function MISSIONSCHEDULER:TimeShow()
trace.f("MISSIONSCHEDULER")
	self.TimeIntervalCount = self.TimeIntervalCount + 1
	if self.TimeIntervalCount >= self.TimeTriggerShow then
		local TimeMsg = string.format("%00d", ( self.TimeSeconds / 60 ) - ( timer.getTime() / 60 )) .. ' minutes left until mission reload.'
		MESSAGE:New( TimeMsg, "Mission time", self.TimeShow, '/TimeMsg' ):ToAll()
		self.TimeIntervalCount = 0
	end
trace.e()
end

function MISSIONSCHEDULER:Time( TimeSeconds, TimeIntervalShow, TimeShow )
trace.f("MISSIONSCHEDULER")

	self.TimeIntervalCount = 0
	self.TimeSeconds = TimeSeconds
	self.TimeIntervalShow = TimeIntervalShow
	self.TimeShow = TimeShow
trace.e()
end

