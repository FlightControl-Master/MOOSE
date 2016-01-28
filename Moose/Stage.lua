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
	MSG = { ID = "Brief", TIME = 1 },
	Name = "Brief",
	StageBriefingTime = 0,
	StageBriefingDuration = 1
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
  MSG = { ID = "Start", TIME = 1 },
  Name = "Start",
  StageStartTime = 0,
  StageStartDuration = 1
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

STAGE_CARGO_LOAD = {
  ClassName = "STAGE_CARGO_LOAD"
}

function STAGE_CARGO_LOAD:New()
trace.f(self.ClassName)
	-- Arrange meta tables
	local self = BASE:Inherit( self, STAGE:New() )
	self.StageType = 'CLIENT'
	return self
end

function STAGE_CARGO_LOAD:Execute( Mission, Client, Task )
trace.f(self.ClassName)
	local Valid = BASE:Inherited(self):Execute( Mission, Client, Task )

	for LoadCargoID, LoadCargo in pairs( Task.Cargos.LoadCargos ) do
		LoadCargo:Load( Client )
	end

	if Client:IsTransport() then
		Client:ShowCargo()
	end

	return Valid
end

function STAGE_CARGO_LOAD:Validate( Mission, Client, Task )
trace.f(self.ClassName)
	local Valid = STAGE:Validate( Mission, Client, Task )

	return 1
end


STAGE_CARGO_INIT = {
  ClassName = "STAGE_CARGO_INIT"
}

function STAGE_CARGO_INIT:New()
trace.f(self.ClassName)
	-- Arrange meta tables
	local self = BASE:Inherit( self, STAGE:New() )
	self.StageType = 'CLIENT'
	return self
end

function STAGE_CARGO_INIT:Execute( Mission, Client, Task )
trace.f(self.ClassName)
	local Valid = BASE:Inherited(self):Execute( Mission, Client, Task )

	for InitLandingZoneID, InitLandingZone in pairs( Task.LandingZones.LandingZones ) do
		trace.i( self.ClassName, InitLandingZone )
		InitLandingZone:Spawn()
	end
	
	
	for InitCargoID, InitCargo in pairs( Task.Cargos.InitCargos ) do
		trace.i( self.ClassName )
		InitCargo:Spawn()
	end
	
	return Valid
end


function STAGE_CARGO_INIT:Validate( Mission, Client, Task )
trace.f(self.ClassName)
	local Valid = STAGE:Validate( Mission, Client, Task )

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

	local RouteMessage = "Fly to "
	for LandingZoneID, LandingZoneName in pairs( Task.LandingZones.LandingZoneNames ) do
		RouteMessage = RouteMessage .. LandingZoneName .. ' at ' .. routines.getBRStringZone( { zone = LandingZoneName, ref = Client:ClientGroup():getUnit(1):getPoint(), true, true } ) .. ' km. '
	end
	Client:Message( RouteMessage, self.MSG.TIME, Mission.Name .. "/StageRoute", "Co-Pilot: Route", 10 )

	if Client:IsTransport() then
		Client:ShowCargo()
	end

	return Valid
end

function STAGEROUTE:Validate( Mission, Client, Task )
trace.f(self.ClassName)
	local Valid = STAGE:Validate( Mission, Client, Task )
	
	-- check if the Client is in the landing zone
	trace.i( self.ClassName, Task.LandingZones.LandingZoneNames )
	Task.CurrentLandingZoneName = routines.IsUnitInZones( Client:ClientUnit(), Task.LandingZones.LandingZoneNames )
	
	if  Task.CurrentLandingZoneName then

		Task.CurrentLandingZone = Task.LandingZones.LandingZones[Task.CurrentLandingZoneName].CargoZone
		Task.CurrentCargoZone = Task.LandingZones.LandingZones[Task.CurrentLandingZoneName]

		if Task.CurrentCargoZone then 
			if not Task.Signalled then
				Task.Signalled = Task.CurrentCargoZone:Signal() 
			end
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
 
	Client:Message( 'We have arrived at ' .. Task.CurrentLandingZoneName .. '. Land the helicopter to ' .. Task.TEXT[1] .. ' the ' .. Task.CargoType .. '.', 
	                self.MSG.TIME,  Mission.Name .. "/StageLanding", "Co-Pilot: Landing", 10 )
  
end

function STAGELANDING:Validate( Mission, Client, Task )
trace.f(self.ClassName)
  
	if routines.IsUnitInZones( Client:ClientUnit(), Task.CurrentLandingZoneName ) then
		-- check if the Client is in the landing zone
		trace.i( self.ClassName, Task.LandingZones.LandingZoneNames )
		Task.CurrentLandingZoneName = routines.IsUnitInZones( Client:ClientUnit(), Task.LandingZones.LandingZoneNames )
		
		if  Task.CurrentLandingZoneName then

			Task.CurrentLandingZone = Task.LandingZones.LandingZones[Task.CurrentLandingZoneName].CargoZone
			Task.CurrentCargoZone = Task.LandingZones.LandingZones[Task.CurrentLandingZoneName]

			if Task.CurrentCargoZone then 
				if not Task.Signalled then
					Task.Signalled = Task.CurrentCargoZone:Signal() 
				end
			end
		else
			if Task.CurrentLandingZone then
				Task.CurrentLandingZone = nil
			end
			if Task.CurrentCargoZone then
				Task.CurrentCargoZone = nil
			end
		end
	else
		Task.Signalled = false 
		Task:RemoveCargoMenus( Client )
		return -1
	end
  
	if not Client:ClientUnit():inAir() then
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
	Client:Message( 'We have landed within the landing zone. Use the radio menu (F10) to ' .. Task.TEXT[1]  .. ' the ' .. Task.CargoType .. '.', self.MSG.TIME,  Mission.Name .. "/StageLanded", "Co-Pilot: Landed" )
	if not self.MenusAdded then
		Task:RemoveCargoMenus( Client )
		Task:AddCargoMenus( Client, CARGOS, 250 )
	end
end



function STAGELANDED:Validate( Mission, Client, Task )
trace.f(self.ClassName)

  if  routines.IsUnitInZones( Client:ClientUnit(), Task.CurrentLandingZoneName ) then
  else
	Task.Signalled = false 
	Task:RemoveCargoMenus( Client )
	return -2
  end
  
  if not Client:ClientUnit():inAir() then
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
	Client:Message( 'The ' .. Task.CargoType .. ' are being ' .. Task.TEXT[2] .. ' within the landing zone. Wait until the helicopter is ' .. Task.TEXT[3] .. '.', 
                    self.MSG.TIME,  Mission.Name .. "/StageUnLoad", "Co-Pilot: Unload" )
	Task:RemoveCargoMenus( Client )
end

function STAGEUNLOAD:Executing( Mission, Client, Task )
trace.f(self.ClassName)
	env.info( 'STAGEUNLOAD:Executing() Task.Cargo.CargoName = ' .. Task.Cargo.CargoName )
	
	local TargetZoneName
	
	if Task.TargetZoneName then
		TargetZoneName = Task.TargetZoneName
	else
		TargetZoneName = Task.CurrentLandingZoneName
	end
	
	if Task.Cargo:UnLoad( Client, TargetZoneName ) then
		Task.ExecuteStage = _TransportExecuteStage.SUCCESS
		Client:ShowCargo()
	end
end

function STAGEUNLOAD:Validate( Mission, Client, Task )
trace.f(self.ClassName)
	env.info( 'STAGEUNLOAD:Validate()' )
  
  if routines.IsUnitInZones( Client:ClientUnit(), Task.CurrentLandingZoneName ) then
  else
    Task.ExecuteStage = _TransportExecuteStage.FAILED
	Task:RemoveCargoMenus( Client )
    Client:Message( 'The ' .. Task.CargoType .. " haven't been successfully " .. Task.TEXT[3] .. '  within the landing zone. Task and mission has failed.', 
	                _TransportStageMsgTime.DONE,  Mission.Name .. "/StageFailure", "Co-Pilot: Unload" )
    return 1
  end
  
  if not Client:ClientUnit():inAir() then
  else
    Task.ExecuteStage = _TransportExecuteStage.FAILED
	Task:RemoveCargoMenus( Client )
    Client:Message( 'The ' .. Task.CargoType .. " haven't been successfully " .. Task.TEXT[3] .. '  within the landing zone. Task and mission has failed.', 
	                _TransportStageMsgTime.DONE,  Mission.Name .. "/StageFailure", "Co-Pilot: Unload" )
    return 1
  end
  
  if  Task.ExecuteStage == _TransportExecuteStage.SUCCESS then
    Client:Message( 'The ' .. Task.CargoType .. ' have been sucessfully ' .. Task.TEXT[3] .. '  within the landing zone.', _TransportStageMsgTime.DONE,  Mission.Name .. "/Stage", "Co-Pilot: Unload" )
	Task.Cargo:StatusUnLoaded()
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
	Client:Message( 'The ' .. Task.CargoType .. ' are being ' .. Task.TEXT[2] .. ' within the landing zone. Wait until the helicopter is ' .. Task.TEXT[3] .. '.', 
	                _TransportStageMsgTime.EXECUTING,  Mission.Name .. "/StageLoad", "Co-Pilot: Load" )

	-- Route the cargo to the Carrier
	Task.Cargo:OnBoard( Client, Task.CurrentCargoZone, Task.OnBoardSide )
	Task.ExecuteStage = _TransportExecuteStage.EXECUTING
end

function STAGELOAD:Executing( Mission, Client, Task )
trace.f(self.ClassName)

  -- If the Cargo is ready to be loaded, load it into the Client.
  
	trace.i(self.ClassName, Task.Cargo)
	
	if Task.Cargo:OnBoarded( Client, Task.CurrentCargoZone ) then

		-- Load the Cargo onto the Client
		Task.Cargo:Load( Client )
	
		-- Message to the pilot that cargo has been loaded.
		Client:Message( "The cargo " .. Task.Cargo.CargoName .. " has been loaded in our helicopter.", 20, Mission.Name .. "/StageLoad", "Co-Pilot: Load" )
		Task.ExecuteStage = _TransportExecuteStage.SUCCESS
		
		Client:ShowCargo()
	end
  
end

function STAGELOAD:Validate( Mission, Client, Task )
trace.f(self.ClassName)
	if  routines.IsUnitInZones( Client:ClientUnit(), Task.CurrentLandingZoneName ) then
	else
		Task:RemoveCargoMenus( Client )
		Task.ExecuteStage = _TransportExecuteStage.FAILED
		Task.CargoName = nil 
		Client:Message( "The " .. Task.CargoType .. " loading has been aborted. You flew outside the pick-up zone while loading. ", 
		                _TransportStageMsgTime.DONE,  Mission.Name .. "/StageSuccess", "Co-Pilot: Load" )
		return 1
	end
  
	if not Client:ClientUnit():inAir() then
	else
		-- The carrier is back in the air, undo the loading process.
		Task:RemoveCargoMenus( Client )
		Task.ExecuteStage = _TransportExecuteStage.NONE
		Task.CargoName = nil 
		Client:Message( "The " .. Task.CargoType .. " loading has been aborted. Land the helicopter and load the cargo. Don't fly outside the pick-up zone. ", 
		                _TransportStageMsgTime.DONE,  Mission.Name .. "/StageSuccess", "Co-Pilot: Load" )
		return -1
	end
  
	if Task.ExecuteStage == _TransportExecuteStage.SUCCESS then
		Task.Cargo:StatusLoaded()
		Task:RemoveCargoMenus( Client )
		Client:Message( 'Co-Pilot: The ' .. Task.CargoType .. ' have been sucessfully ' .. Task.TEXT[3] .. '  within the landing zone.', 
		                _TransportStageMsgTime.DONE,  Mission.Name .. "/StageLoaded", "Co-Pilot: Load" )
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
		if  routines.IsStaticInZones( StaticObject.getByName( Task.CargoName ), Task.CurrentLandingZoneName ) then
		else
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
			if routines.IsUnitInZones( Client:ClientUnit(), Task.CurrentLandingZoneName ) then
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
 
  Client:Message( 'We have arrived at ' .. Task.CurrentLandingZoneName .. ".", self.MSG.TIME,  Mission.Name .. "/Stage", "Co-Pilot: Arrived" )

  end

function STAGEARRIVE:Validate( Mission, Client, Task )
trace.f(self.ClassName)
  
  Task.CurrentLandingZoneID  = routines.IsUnitInZones( Client:ClientUnit(), Task.LandingZones )
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
