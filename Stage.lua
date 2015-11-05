--- Stages within a @{TASK} within a @{MISSION}. All of the STAGE functionality is considered internally administered and not to be used by any Mission designer.
-- @classmod STAGE
-- @author Flightcontrol

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Mission" )
Include.File( "Client" )
Include.File( "Task" )


STAGE = {
  ClassName = "STAGE",
  MSG = { ID = "None", TIME = 10 },
  FREQUENCY = { NONE = 0, ONCE = 1, REPEAT = -1 },
  
  Name = "NoStage",
  StageType = '',
  WaitTime = 1,
  Frequency = 1,
  MessageCount = 0,
  MessageInterval = 15,
  MessageShown = {},
  MessageShow = false,
  MessageFlash = false
}


function STAGE:New()
trace.f(self.ClassName)
	local self = BASE:Inherit( self, BASE:New() )
	return self
end

function STAGE:Execute( Mission, Client, Task )
trace.f(self.ClassName)

	local Valid = true
  
	return Valid
end

function STAGE:Executing( Mission, Client, Task )
trace.f(self.ClassName)

end

function STAGE:Validate( Mission, Client, Task )
trace.f(self.ClassName)

  local Valid = true

  return Valid
end


STAGEBRIEF = {
	ClassName = "BRIEF",
	MSG = { ID = "Brief", TIME = 30 },
	Name = "Brief",
	StageBriefingTime = 0,
	StageBriefingDuration = 30
}

function STAGEBRIEF:New()
trace.f(self.ClassName)
	-- Arrange meta tables
	local Child = BASE:Inherit( self, STAGE:New() )
	Child.StageType = 'CLIENT'
	return Child
end

function STAGEBRIEF:Execute( Mission, Client, Task )
trace.f(self.ClassName)
	local Valid = BASE:Inherited(self):Execute( Mission, Client, Task )
	Mission:ShowBriefing( Client )
	self.StageBriefingTime = timer.getTime()
	return Valid 
end

function STAGEBRIEF:Validate( Mission, Client, Task )
trace.f(self.ClassName)
	local Valid = STAGE:Validate( Mission, Client, Task )

	if timer.getTime() - self.StageBriefingTime <= self.StageBriefingDuration then
		return 0
	else
		self.StageBriefingTime = timer.getTime()
		return 1
	end
  
end


STAGESTART = {
  ClassName = "START",
  MSG = { ID = "Start", TIME = 30 },
  Name = "Start",
  StageStartTime = 0,
  StageStartDuration = 30
}

function STAGESTART:New()
trace.f(self.ClassName)
	-- Arrange meta tables
	local Child = BASE:Inherit( self, STAGE:New() )
	Child.StageType = 'CLIENT'
	return Child
end

function STAGESTART:Execute( Mission, Client, Task )
trace.f(self.ClassName)
	local Valid = BASE:Inherited(self):Execute( Mission, Client, Task )
	if Task.TaskBriefing then
		Client:Message( Task.TaskBriefing, self.StageStartDuration,  Mission.Name .. "/Stage", "Mission Command: Tasking" )
	else
		Client:Message( 'Task ' .. Task.TaskNumber .. '.', self.StageStartDuration, Mission.Name .. "/Stage", "Mission Command: Tasking" )
	end
	self.StageStartTime = timer.getTime()
	return Valid 
end

function STAGESTART:Validate( Mission, Client, Task )
trace.f(self.ClassName)
	local Valid = STAGE:Validate( Mission, Client, Task )

	if timer.getTime() - self.StageStartTime <= self.StageStartDuration then
		return 0
	else
		self.StageStartTime = timer.getTime()
		return 1
	end
  
	return 1
  
end

STAGEROUTE = {
  ClassName = "STAGEROUTE",
  MSG = { ID = "Route", TIME = 1 },
  Frequency = STAGE.FREQUENCY.REPEAT,
  Name = "Route"
}

function STAGEROUTE:New()
trace.f(self.ClassName)
	-- Arrange meta tables
	local self = BASE:Inherit( self, STAGE:New() )
	self.StageType = 'CLIENT'
	self.MessageSwitch = true
	return self
end


function STAGEROUTE:Execute( Mission, Client, Task )
trace.f(self.ClassName)
	local Valid = BASE:Inherited(self):Execute( Mission, Client, Task )

	if type( Task.LandingZones) == "table" then
		local RouteMessage = "Fly to "
		for LandingZoneID, LandingZoneName in pairs( Task.LandingZones ) do
			RouteMessage = RouteMessage .. LandingZoneName .. ' at ' .. routines.getBRStringZone( { zone = LandingZoneName, ref = Client:ClientGroup():getUnit(1):getPoint(), true, true } ) .. ' km. '
		end
		Client:Message( RouteMessage, self.MSG.TIME, Mission.Name .. "/StageRoute", "Co-Pilot: Route", 10 )
	else
		Client:Message( "Fly to " .. Task.LandingZones .. ' at ' .. routines.getBRStringZone( { zone = Task.LandingZones, ref = Client:ClientGroup():getUnit(1):getPoint(), true, true } ) .. ' km. ', self.MSG.TIME, Mission.Name .. "/StageRoute", "Co-Pilot: Route", 1 )
	end
	if Client:IsTransport() then
		Client:ShowCargo()
	end

	return Valid
end

function STAGEROUTE:Validate( Mission, Client, Task )
trace.f(self.ClassName)
  local Valid = STAGE:Validate( Mission, Client, Task )

  -- check if this carrier is in the landing zone
  Task.CurrentLandingZoneID = routines.IsUnitInZones( Client:ClientGroup():getUnits()[1], Task.LandingZones )
  if  (  Task.CurrentLandingZoneID ) then
    if not Task.Signalled then
	  
		if Task.LandingZoneSignalType then
			env.info( 'TransportSchedule: Task.LandingZoneSignalType = ' .. Task.LandingZoneSignalType.TEXT )
			if Task.LandingZoneSignalUnitNames then
				local LandingZoneSignalUnit = Task.LandingZoneSignalUnitNames[Task.CurrentLandingZoneID]
				trace.i( self.ClassName, 'LandingZoneSignalUnit = ' .. LandingZoneSignalUnit )
		  
				local SignalUnit = Unit.getByName(LandingZoneSignalUnit)
				if SignalUnit == nil then
					SignalUnit = StaticObject.getByName( LandingZoneSignalUnit )
				end
				if SignalUnit ~= nil then
					trace.i( self.ClassName, 'Signalling Unit' )
					local SignalVehiclePos = SignalUnit:getPosition().p
					SignalVehiclePos.y = SignalVehiclePos.y + Task.LandingZoneSignalHeight
					if  	Task.LandingZoneSignalType.ID == Task.SIGNAL.TYPE.SMOKE.ID then
						trigger.action.smoke( SignalVehiclePos, Task.LandingZoneSignalColor.COLOR )
					elseif  Task.LandingZoneSignalType.ID == Task.SIGNAL.TYPE.FLARE.ID then
						trigger.action.signalFlare( SignalVehiclePos, Task.LandingZoneSignalColor.COLOR, 0 )
					end
				end
			else
				env.info( 'TransportSchedule: Signaling landing zone ' )
		  
				local LandingZone = trigger.misc.getZone( Task.LandingZones [ Task.CurrentLandingZoneID ] )
				local CurrentPosition = { x = LandingZone.point.x, y = LandingZone.point.z }
				LandingZone.point.y = land.getHeight( CurrentPosition ) + 10
		  
				if    Task.LandingZoneSignalType.ID == Task.SIGNAL.TYPE.SMOKE.ID then
					env.info( 'TransportSchedule: Smoking zone x = ' .. LandingZone.point.x .. ' y = ' .. LandingZone.point.y .. ' z = ' .. LandingZone.point.z )
					trigger.action.smoke( LandingZone.point, Task.LandingZoneSignalColor.COLOR )
				elseif  Task.LandingZoneSignalType.ID == Task.SIGNAL.TYPE.SMOKE.FLARE.ID then
					env.info( 'TransportSchedule: Flaring zone x = ' .. LandingZone.point.x .. ' y = ' .. LandingZone.point.y .. ' z = ' .. LandingZone.point.z )
					trigger.action.signalFlare( LandingZone.point, Task.LandingZoneSignalColor.COLOR, 0 )
				end
			end
		end
		self.Signalled = true 
	end
    return 1
  end
  
  return 0
  
end

STAGELANDING = {
  ClassName = "STAGELANDING",
  MSG = { ID = "Landing", TIME = 10 },
  Name = "Landing",
  Signalled = false
}

function STAGELANDING:New()
trace.f(self.ClassName)
	-- Arrange meta tables
	local Child = BASE:Inherit( self, STAGE:New() )
	Child.StageType = 'CLIENT'
	return Child
end

function STAGELANDING:Execute( Mission, Client, Task )
trace.f(self.ClassName)
 
	Client:Message( 'We have arrived at ' .. Task.LandingZones[Task.CurrentLandingZoneID] .. '. Land the helicopter to ' .. Task.TEXT[1] .. ' the ' .. Task.CargoType.TEXT .. '.', 
	                self.MSG.TIME,  Mission.Name .. "/Stage", "Co-Pilot: Landing" )
  
end

function STAGELANDING:Validate( Mission, Client, Task )
trace.f(self.ClassName)
  
  if  routines.IsUnitInZones( Client:ClientGroup():getUnits()[1], Task.LandingZones[Task.CurrentLandingZoneID] ) then
  else
	Task.Signalled = false 
	Task:RemoveCargoMenus( Client )
    return -1
  end
  
  if not Client:ClientGroup():getUnits()[1]:inAir() then
  else
    return 0
  end
  
  return 1
end

STAGELANDED = {
  ClassName = "STAGELANDED",
  MSG = { ID = "Land", TIME = 10 },
  Name = "Landed",
  MenusAdded = false
}

function STAGELANDED:New()
trace.f(self.ClassName)
  -- Arrange meta tables
	local Child = BASE:Inherit( self, STAGE:New() )
	Child.StageType = 'CLIENT'
	return Child
end

function STAGELANDED:Execute( Mission, Client, Task )
trace.f(self.ClassName)
	Client:Message( 'We have landed within the landing zone. Use the radio menu (F10) to ' .. Task.TEXT[1]  .. ' the ' .. Task.CargoType.TEXT .. '.', self.MSG.TIME,  Mission.Name .. "/Stage", "Co-Pilot: Landed" )
	if not self.MenusAdded then
		Task:RemoveCargoMenus( Client )
		Task:AddCargoMenus( Client, Mission._Cargos, 250 )
	end
end



function STAGELANDED:Validate( Mission, Client, Task )
trace.f(self.ClassName)

  if  routines.IsUnitInZones( Client:ClientGroup():getUnits()[1], Task.LandingZones[Task.CurrentLandingZoneID] ) then
  else
	Task.Signalled = false 
	Task:RemoveCargoMenus( Client )
	return -2
  end
  
  if not Client:ClientGroup():getUnits()[1]:inAir() then
  else
	Task.Signalled = false 
    return -1
  end
  
  if  Task.ExecuteStage == _TransportExecuteStage.EXECUTING then
  else
    return 0
  end
  
  return 1
end

STAGEUNLOAD = {
  ClassName = "STAGEUNLOAD",
  MSG = { ID = "Unload", TIME = 10 },
  Name = "Unload"
}

function STAGEUNLOAD:New()
trace.f(self.ClassName)
	-- Arrange meta tables
	local Child = BASE:Inherit( self, STAGE:New() )
	Child.StageType = 'CLIENT'
	return Child
end

function STAGEUNLOAD:Execute( Mission, Client, Task )
trace.f(self.ClassName)
  Client:Message( 'The ' .. Task.CargoType.TEXT .. ' are being ' .. Task.TEXT[2] .. ' within the landing zone. Wait until the helicopter is ' .. Task.TEXT[3] .. '.', 
                  self.MSG.TIME,  Mission.Name .. "/Stage", "Co-Pilot: Unload" )
  Task:RemoveCargoMenus( Client )
end

function STAGEUNLOAD:Executing( Mission, Client, Task )
trace.f(self.ClassName)
	env.info( 'STAGEUNLOAD:Executing() Task.CargoName = ' .. Task.CargoName ) 
	local Cargo = Client:RemoveCargo( Task.CargoName )
	if Cargo then
		env.info( 'STAGEUNLOAD:Executing() Cargo.CargoName = ' .. Cargo.CargoName ) 
		env.info( 'STAGEUNLOAD:Executing() Cargo.CargoGroupName = ' .. Cargo.CargoGroupName ) 
		env.info( 'STAGEUNLOAD:Executing() Mission._Cargos[Cargo.CargoName].CargoGroupTemplate = ' .. Mission._Cargos[Cargo.CargoName].CargoGroupTemplate ) 
		
		if Cargo.CargoType.TRANSPORT == CARGO_TRANSPORT.UNIT then
			if Cargo.CargoName then
				if Task.TargetZoneName then
					SPAWN:New( Mission._Cargos[Cargo.CargoName].CargoGroupTemplate ):FromCarrier ( Client:ClientGroup(), 
						Task.TargetZoneName,  
						Mission._Cargos[Cargo.CargoName].CargoGroupName )
				else
					SPAWN:New( Mission._Cargos[Cargo.CargoName].CargoGroupTemplate ):FromCarrier ( Client:ClientGroup(), 
						Task.LandingZones[Task.CurrentLandingZoneID],
						Mission._Cargos[Cargo.CargoName].CargoGroupName )
				end
			end
		end
		Task.ExecuteStage = _TransportExecuteStage.SUCCESS
		Client:ShowCargo()
	end
end

function STAGEUNLOAD:Validate( Mission, Client, Task )
trace.f(self.ClassName)
	env.info( 'STAGEUNLOAD:Validate()' )
  
  if  routines.IsUnitInZones( Client:ClientGroup():getUnits()[1], Task.LandingZones[Task.CurrentLandingZoneID] ) then
  else
    Task.ExecuteStage = _TransportExecuteStage.FAILED
	Task:RemoveCargoMenus( Client )
    Client:Message( 'The ' .. Task.CargoType.TEXT .. " haven't been successfully " .. Task.TEXT[3] .. '  within the landing zone. Task and mission has failed.', 
	                _TransportStageMsgTime.DONE,  Mission.Name .. "/StageFailure", "Co-Pilot: Unload" )
    return 1
  end
  
  if not Client:ClientGroup():getUnits()[1]:inAir() then
  else
    Task.ExecuteStage = _TransportExecuteStage.FAILED
	Task:RemoveCargoMenus( Client )
    Client:Message( 'The ' .. Task.CargoType.TEXT .. " haven't been successfully " .. Task.TEXT[3] .. '  within the landing zone. Task and mission has failed.', 
	                _TransportStageMsgTime.DONE,  Mission.Name .. "/StageFailure", "Co-Pilot: Unload" )
    return 1
  end
  
  if  Task.ExecuteStage == _TransportExecuteStage.SUCCESS then
    Client:Message( 'The ' .. Task.CargoType.TEXT .. ' have been sucessfully ' .. Task.TEXT[3] .. '  within the landing zone.', _TransportStageMsgTime.DONE,  Mission.Name .. "/Stage", "Co-Pilot: Unload" )
	Mission._Cargos[Task.CargoName].Status = CARGOSTATUS.UNLOADED
	Task:RemoveCargoMenus( Client )
	Task.MissionTask:AddGoalCompletion( Task.MissionTask.GoalVerb, Task.CargoName, 1 ) -- We set the cargo as one more goal completed in the mission.
    return 1
  end
  
  return 1
end

STAGELOAD = {
  ClassName = "STAGELOAD",
  MSG = { ID = "Load", TIME = 10 },
  Name = "Load"
}

function STAGELOAD:New()
trace.f(self.ClassName)
	-- Arrange meta tables
	local Child = BASE:Inherit( self, STAGE:New() )
	Child.StageType = 'CLIENT'
	return Child
end

function STAGELOAD:Execute( Mission, Client, Task )
trace.f(self.ClassName)
	Client:Message( 'The ' .. Task.CargoType.TEXT .. ' are being ' .. Task.TEXT[2] .. ' within the landing zone. Wait until the helicopter is ' .. Task.TEXT[3] .. '.', 
	                _TransportStageMsgTime.EXECUTING,  Mission.Name .. "/Stage", "Co-Pilot: Load" )

	-- Route the cargo to the Carrier
	if Mission._Cargos[Task.CargoName].CargoType.TRANSPORT == CARGO_TRANSPORT.UNIT then
		Task:OnBoardCargo( Client:ClientGroup(), Mission._Cargos )
		Task.ExecuteStage = _TransportExecuteStage.EXECUTING
	else
	   -- Add the group to the internal cargo;
		Client:AddCargo( Task.CargoName, Mission._Cargos[Task.CargoName].CargoGroupName, Mission._Cargos[Task.CargoName].CargoType, Mission._Cargos[Task.CargoName].CargoWeight, Mission._Cargos[Task.CargoName].CargoGroupTemplate )
		Task.ExecuteStage = _TransportExecuteStage.SUCCESS
	end
end

function STAGELOAD:Executing( Mission, Client, Task )
trace.f(self.ClassName)

  -- Remove the loaded object from the battle zone.
  
  if routines.IsPartOfGroupInRadius( Group.getByName(Mission._Cargos[Task.CargoName].CargoGroupName), Client:ClientGroup(), 75 ) then
    routines.DestroyGroupInRadiusFromGroup( Group.getByName(Mission._Cargos[Task.CargoName].CargoGroupName), Client:ClientGroup(), 75 )
	env.info('trying to remove cargo')

    -- Add the group to the internal cargo;
    Client:AddCargo( Task.CargoName, Mission._Cargos[Task.CargoName].CargoGroupName, Mission._Cargos[Task.CargoName].CargoType, Mission._Cargos[Task.CargoName].CargoWeight, Mission._Cargos[Task.CargoName].CargoGroupTemplate )
	
    -- Message to the pilot that cargo has been loaded.
    Client:Message( "The cargo " .. Task.CargoName .. " has been loaded in our helicopter.", 20, Mission.Name .. "/Stage", "Co-Pilot: Load" )
    Task.ExecuteStage = _TransportExecuteStage.SUCCESS
    Client:ShowCargo()
  end
  
end

function STAGELOAD:Validate( Mission, Client, Task )
trace.f(self.ClassName)
	if  routines.IsUnitInZones( Client:ClientGroup():getUnits()[1], Task.LandingZones[Task.CurrentLandingZoneID] ) then
	else
		Task:RemoveCargoMenus( Client )
		Task.ExecuteStage = _TransportExecuteStage.FAILED
		Task.CargoName = nil 
		Client:Message( "The " .. Task.CargoType.TEXT .. " loading has been aborted. You flew outside the pick-up zone while loading. ", 
		                _TransportStageMsgTime.DONE,  Mission.Name .. "/StageSuccess", "Co-Pilot: Load" )
		return 1
	end
  
	if not Client:ClientGroup():getUnits()[1]:inAir() then
	else
		-- The carrier is back in the air, undo the loading process.
		Task:RemoveCargoMenus( Client )
		Task.ExecuteStage = _TransportExecuteStage.NONE
		Task.CargoName = nil 
		Client:Message( "The " .. Task.CargoType.TEXT .. " loading has been aborted. Land the helicopter and load the cargo. Don't fly outside the pick-up zone. ", 
		                _TransportStageMsgTime.DONE,  Mission.Name .. "/StageSuccess", "Co-Pilot: Load" )
		return -1
	end
  
	if Task.ExecuteStage == _TransportExecuteStage.SUCCESS then
		Mission._Cargos[Task.CargoName].Status = CARGOSTATUS.LOADED
		Task:RemoveCargoMenus( Client )
		Client:Message( 'Co-Pilot: The ' .. Task.CargoType.TEXT .. ' have been sucessfully ' .. Task.TEXT[3] .. '  within the landing zone.', 
		                _TransportStageMsgTime.DONE,  Mission.Name .. "/Stage", "Co-Pilot: Load" )
		Task.MissionTask:AddGoalCompletion( Task.MissionTask.GoalVerb, Task.CargoName, 1 )
		return 1
	end
  
	return 0
end

STAGE_SLINGLOAD_HOOK = {
  ClassName = "STAGE_SLINGLOAD_HOOK",
  MSG = { ID = "SlingLoadHook", TIME = 10 },
  Name = "SlingLoadHook"
}

function STAGE_SLINGLOAD_HOOK:New()
trace.f(self.ClassName)
	-- Arrange meta tables
	local self = BASE:Inherit( self, STAGE:New() )
	self.StageType = 'CLIENT'
	return self
end

function STAGE_SLINGLOAD_HOOK:Execute( Mission, Client, Task )
trace.f(self.ClassName)
	Client:Message( 'Hook the Cargo onto the helicopter, and fly out the pick-up zone. Due to a bug in DCS world it cannot be chacked (for the moment) ' ..
	                'if the cargo is in our out of the zone and attached to your helicopter...', self.MSG.TIME,  Mission.Name .. "/Stage", "Co-Pilot: Hook" )
end

function STAGE_SLINGLOAD_HOOK:Validate( Mission, Client, Task )
trace.f(self.ClassName)


	for CargoID, CargoName in pairs( Task.CargoPrefixes ) do
		env.info( CargoName )
		if StaticObject.getByName( CargoName ):inAir() then
			Task.CargoName = CargoName
			Task.CargoID = CargoID
			Client:Message( 'Co-Pilot: The Cargo has been successfully hooked onto the helicopter within the landing zone.', self.MSG.TIME,  Mission.Name .. "/StageSuccess" )
			break
		end
	end
	
	if Task.CargoName then
		if  routines.IsStaticInZones( StaticObject.getByName( Task.CargoName ), Task.LandingZones[Task.CurrentLandingZoneID] ) then
		else
			Mission._Cargos[Task.CargoName].Status = CARGOSTATUS.LOADED
			return 1
		end
	end
  
	return 1
end

STAGE_SLINGLOAD_UNHOOK = {
  ClassName = "STAGE_SLINGLOAD_UNHOOK",
  MSG = { ID = "SlingLoadUnHook", TIME = 10 },
  Name = "SlingLoadUnHook"
}

function STAGE_SLINGLOAD_UNHOOK:New()
trace.f(self.ClassName)
	-- Arrange meta tables
	local self = BASE:Inherit( self, STAGE:New() )
	self.StageType = 'CLIENT'
	return self
end

function STAGE_SLINGLOAD_UNHOOK:Execute( Mission, Client, Task )
trace.f(self.ClassName)
	Client:Message( 'Deploy the Cargo in the Landing Zone and unhook the cargo, and fly out of the drop zone.', self.MSG.TIME,  Mission.Name .. "/StageUnhook", "Co-Pilot: Unhook" )
end

function STAGE_SLINGLOAD_UNHOOK:Validate( Mission, Client, Task )
trace.f(self.ClassName)
	
	for CargoID, CargoName in pairs( Task.CargoPrefixes ) do
		if StaticObject.getByName( CargoName ):inAir() then
			Task.CargoName = CargoName
			Task.CargoID = CargoID
			Client:Message( 'Co-Pilot: Drop the cargo within the landing zone and unhook.', self.MSG.TIME,  Mission.Name .. "/Stage" )
			break
		end
	end

	if Task.CargoName then
		if not StaticObject.getByName( Task.CargoName ):inAir() then
			if routines.IsUnitInZones( Client:ClientGroup():getUnits()[1], Task.LandingZones[Task.CurrentLandingZoneID] ) then
			else
				Client:Message( 'Co-Pilot: The Cargo is Dropped in the Landing Zone, and You have flown outside of the landing zone.', self.MSG.TIME,  Mission.Name .. "/Stage" )
				return 1
			end
		end
	end
  
	return 1
end

STAGEDONE = {
  ClassName = "STAGEDONE",
  MSG = { ID = "Done", TIME = 10 },
  Name = "Done"
}

function STAGEDONE:New()
trace.f(self.ClassName)
	-- Arrange meta tables
	local Child = BASE:Inherit( self, STAGE:New() )
	Child.StageType = 'AI'
	return Child
end

function STAGEDONE:Execute( Mission, Client, Task )
trace.f(self.ClassName)

end

function STAGEDONE:Validate( Mission, Client, Task )
trace.f(self.ClassName)

	Task:Done()
  
	return 0
end

STAGEARRIVE = {
  ClassName = "STAGEARRIVE",
  MSG = { ID = "Arrive", TIME = 10 },
  Name = "Arrive"
}

function STAGEARRIVE:New()
trace.f(self.ClassName)
  -- Arrange meta tables
	local Child = BASE:Inherit( self, STAGE:New() )
	Child.StageType = 'CLIENT'
	return Child
end

function STAGEARRIVE:Execute( Mission, Client, Task )
trace.f(self.ClassName)
 
  Client:Message( 'We have arrived at ' .. Task.LandingZones[Task.CurrentLandingZoneID] .. ".", self.MSG.TIME,  Mission.Name .. "/Stage", "Co-Pilot: Arrived" )

  end

function STAGEARRIVE:Validate( Mission, Client, Task )
trace.f(self.ClassName)
  
  Task.CurrentLandingZoneID  = routines.IsUnitInZones( Client:ClientGroup():getUnits()[1], Task.LandingZones )
  if  ( Task.CurrentLandingZoneID ) then
  else
    return -1
  end
  
  return 1
end

STAGEGROUPSDESTROYED = {
  ClassName = "STAGEGROUPSDESTROYED",
  DestroyGroupSize = -1,
  Frequency = STAGE.FREQUENCY.REPEAT,
  MSG = { ID = "DestroyGroup", TIME = 10 },
  Name = "GroupsDestroyed"
}

function STAGEGROUPSDESTROYED:New()
trace.f(self.ClassName)
	-- Arrange meta tables
	local Child = BASE:Inherit( self, STAGE:New() )
	Child.StageType = 'AI'
	return Child
end

--function STAGEGROUPSDESTROYED:Execute( Mission, Client, Task )
-- 
--	Client:Message( 'Task: Still ' .. DestroyGroupSize .. " of " .. Task.DestroyGroupCount .. " " .. Task.DestroyGroupType .. " to be destroyed!", self.MSG.TIME,  Mission.Name .. "/Stage" )
--
--end

function STAGEGROUPSDESTROYED:Validate( Mission, Client, Task )
trace.f(self.ClassName)
 
	if Task.MissionTask:IsGoalReached() then
		return 1
	else
		return 0
	end
end

function STAGEGROUPSDESTROYED:Execute( Mission, Client, Task )
trace.f(self.ClassName)
	trace.i( self.ClassName, { Task.ClassName, Task.Destroyed } )
	--env.info( 'Event Table Task = ' .. tostring(Task) )

end













--[[
  _TransportStage: Defines the different stages of which of transport missions can be in. This table is internal and is used to control the sequence of messages, actions and flow.
  
  - _TransportStage.START
  - _TransportStage.ROUTE
  - _TransportStage.LAND
  - _TransportStage.EXECUTE
  - _TransportStage.DONE
  - _TransportStage.REMOVE
--]]
_TransportStage = { 
  HOLD = "HOLD",
  START = "START", 
  ROUTE = "ROUTE", 
  LANDING = "LANDING",
  LANDED = "LANDED",
  EXECUTING = "EXECUTING",
  LOAD = "LOAD",
  UNLOAD = "UNLOAD",
  DONE = "DONE", 
  NEXT = "NEXT"
}

_TransportStageMsgTime = { 
  HOLD = 10,
  START = 60, 
  ROUTE = 5, 
  LANDING = 10,
  LANDED = 30,
  EXECUTING = 30,
  LOAD = 30,
  UNLOAD = 30,
  DONE = 30, 
  NEXT = 0
}

_TransportStageTime = { 
  HOLD = 10,
  START = 5, 
  ROUTE = 5, 
  LANDING = 1,
  LANDED = 1,
  EXECUTING = 5,
  LOAD = 5,
  UNLOAD = 5,
  DONE = 1, 
  NEXT = 0
}

_TransportStageAction = { 
  REPEAT = -1,
  NONE = 0,
  ONCE = 1
}
