--- Stages within a @{TASK} within a @{MISSION}. All of the STAGE functionality is considered internally administered and not to be used by any Mission designer.
-- @module STAGE
-- @author Flightcontrol

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Mission" )
Include.File( "Client" )
Include.File( "Task" )

--- The STAGE class
-- @type
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
	local self = BASE:Inherit( self, BASE:New() )
	self:F()
	return self
end

function STAGE:Execute( Mission, Client, Task )

	local Valid = true

	return Valid
end

function STAGE:Executing( Mission, Client, Task )

end

function STAGE:Validate( Mission, Client, Task )
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
	local self = BASE:Inherit( self, STAGE:New() )
	self:F()
	self.StageType = 'CLIENT'
	return self
end

function STAGEBRIEF:Execute( Mission, Client, Task )
	local Valid = BASE:Inherited(self):Execute( Mission, Client, Task )
	self:F()
	Client:ShowBriefing()
	self.StageBriefingTime = timer.getTime()
	return Valid 
end

function STAGEBRIEF:Validate( Mission, Client, Task )
	local Valid = STAGE:Validate( Mission, Client, Task )
	self:T()

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
	local self = BASE:Inherit( self, STAGE:New() )
	self:F()
	self.StageType = 'CLIENT'
	return self
end

function STAGESTART:Execute( Mission, Client, Task )
	self:F()
	local Valid = BASE:Inherited(self):Execute( Mission, Client, Task )
	if Task.TaskBriefing then
		Client:Message( Task.TaskBriefing, 30,  Mission.Name .. "/Stage", "Command" )
	else
		Client:Message( 'Task ' .. Task.TaskNumber .. '.', 30, Mission.Name .. "/Stage", "Command" )
	end
	self.StageStartTime = timer.getTime()
	return Valid 
end

function STAGESTART:Validate( Mission, Client, Task )
	self:F()
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
	local self = BASE:Inherit( self, STAGE:New() )
	self:F()
	self.StageType = 'CLIENT'
	return self
end

function STAGE_CARGO_LOAD:Execute( Mission, Client, Task )
	self:F()
	local Valid = BASE:Inherited(self):Execute( Mission, Client, Task )

	for LoadCargoID, LoadCargo in pairs( Task.Cargos.LoadCargos ) do
		LoadCargo:Load( Client )
	end

	if Mission.MissionReportFlash and Client:IsTransport() then
		Client:ShowCargo()
	end

	return Valid
end

function STAGE_CARGO_LOAD:Validate( Mission, Client, Task )
	self:F()
	local Valid = STAGE:Validate( Mission, Client, Task )

	return 1
end


STAGE_CARGO_INIT = {
  ClassName = "STAGE_CARGO_INIT"
}

function STAGE_CARGO_INIT:New()
	local self = BASE:Inherit( self, STAGE:New() )
	self:F()
	self.StageType = 'CLIENT'
	return self
end

function STAGE_CARGO_INIT:Execute( Mission, Client, Task )
	self:F()
	local Valid = BASE:Inherited(self):Execute( Mission, Client, Task )

	for InitLandingZoneID, InitLandingZone in pairs( Task.LandingZones.LandingZones ) do
		self:T( InitLandingZone )
		InitLandingZone:Spawn()
	end
	

	self:T( Task.Cargos.InitCargos )
	for InitCargoID, InitCargoData in pairs( Task.Cargos.InitCargos ) do
		self:T( { InitCargoData } )
		InitCargoData:Spawn( Client )
	end
	
	return Valid
end


function STAGE_CARGO_INIT:Validate( Mission, Client, Task )
	self:F()
	local Valid = STAGE:Validate( Mission, Client, Task )

	return 1
end



STAGEROUTE = {
  ClassName = "STAGEROUTE",
  MSG = { ID = "Route", TIME = 5 },
  Frequency = STAGE.FREQUENCY.REPEAT,
  Name = "Route"
}

function STAGEROUTE:New()
	local self = BASE:Inherit( self, STAGE:New() )
	self:F()
	self.StageType = 'CLIENT'
	self.MessageSwitch = true
	return self
end


--- Execute the routing.
-- @param #STAGEROUTE self
-- @param Mission#MISSION Mission
-- @param Client#CLIENT Client
-- @param Task#TASK Task
function STAGEROUTE:Execute( Mission, Client, Task )
	self:F()
	local Valid = BASE:Inherited(self):Execute( Mission, Client, Task )

	local RouteMessage = "Fly to: "
	self:T( Task.LandingZones )
	for LandingZoneID, LandingZoneName in pairs( Task.LandingZones.LandingZoneNames ) do
		RouteMessage = RouteMessage .. "\n     " .. LandingZoneName .. ' at ' .. routines.getBRStringZone( { zone = LandingZoneName, ref = Client:GetClientGroupDCSUnit():getPoint(), true, true } ) .. ' km.'
	end
	
	if Client:IsMultiSeated() then
    Client:Message( RouteMessage, self.MSG.TIME, Mission.Name .. "/StageRoute", "Co-Pilot", 20 )
	else
    Client:Message( RouteMessage, self.MSG.TIME, Mission.Name .. "/StageRoute", "Command", 20 )
  end	
	

	if Mission.MissionReportFlash and Client:IsTransport() then
		Client:ShowCargo()
	end

	return Valid
end

function STAGEROUTE:Validate( Mission, Client, Task )
	self:F()
	local Valid = STAGE:Validate( Mission, Client, Task )
	
	-- check if the Client is in the landing zone
	self:T( Task.LandingZones.LandingZoneNames )
	Task.CurrentLandingZoneName = routines.IsUnitNearZonesRadius( Client:GetClientGroupDCSUnit(), Task.LandingZones.LandingZoneNames, 500 )
	
	if  Task.CurrentLandingZoneName then

		Task.CurrentLandingZone = Task.LandingZones.LandingZones[Task.CurrentLandingZoneName].CargoZone
		Task.CurrentCargoZone = Task.LandingZones.LandingZones[Task.CurrentLandingZoneName]

		if Task.CurrentCargoZone then 
			if not Task.Signalled then
				Task.Signalled = Task.CurrentCargoZone:Signal() 
			end
		end

    self:T( 1 )
		return 1
	end
  
  self:T( 0 )
	return 0
end



STAGELANDING = {
  ClassName = "STAGELANDING",
  MSG = { ID = "Landing", TIME = 10 },
  Name = "Landing",
  Signalled = false
}

function STAGELANDING:New()
	local self = BASE:Inherit( self, STAGE:New() )
	self:F()
	self.StageType = 'CLIENT'
	return self
end

--- Execute the landing coordination.
-- @param #STAGELANDING self
-- @param Mission#MISSION Mission
-- @param Client#CLIENT Client
-- @param Task#TASK Task
function STAGELANDING:Execute( Mission, Client, Task )
	self:F()
 
  if Client:IsMultiSeated() then
  	Client:Message( "We have arrived at the landing zone.", self.MSG.TIME, Mission.Name .. "/StageArrived", "Co-Pilot", 10 )
  else
    Client:Message( "You have arrived at the landing zone.", self.MSG.TIME, Mission.Name .. "/StageArrived", "Command", 10 )
  end

 	Task.HostUnit = Task.CurrentCargoZone:GetHostUnit()
	
	self:T( { Task.HostUnit } )

	if Task.HostUnit then
	
		Task.HostUnitName = Task.HostUnit:GetPrefix()
		Task.HostUnitTypeName = Task.HostUnit:GetTypeName()
		
		local HostMessage = ""
		Task.CargoNames = ""

		local IsFirst = true
		
		for CargoID, Cargo in pairs( CARGOS ) do
			if Cargo.CargoType == Task.CargoType then

				if Cargo:IsLandingRequired() then
					self:T( "Task for cargo " .. Cargo.CargoType .. " requires landing.")
					Task.IsLandingRequired = true
				end
				
				if Cargo:IsSlingLoad() then
					self:T( "Task for cargo " .. Cargo.CargoType .. " is a slingload.")
					Task.IsSlingLoad = true
				end

				if IsFirst then
					IsFirst = false
					Task.CargoNames = Task.CargoNames  .. Cargo.CargoName .. "( " .. Cargo.CargoWeight .. " )"
				else
					Task.CargoNames = Task.CargoNames  .. "; " .. Cargo.CargoName .. "( " .. Cargo.CargoWeight .. " )"
				end
			end
		end
		
		if Task.IsLandingRequired then
			HostMessage = "Land the helicopter to " .. Task.TEXT[1] .. " " .. Task.CargoNames .. "."
		else
			HostMessage = "Use the Radio menu and F6 to find the cargo, then fly or land near the cargo and " .. Task.TEXT[1] .. " " .. Task.CargoNames .. "."
		end

    local Host = "Command"
    if Task.HostUnitName then
      Host = Task.HostUnitName .. " (" .. Task.HostUnitTypeName .. ")"
    else
      if Client:IsMultiSeated() then
        Host = "Co-Pilot"
      end
    end
		
		Client:Message( HostMessage, self.MSG.TIME, Mission.Name .. "/STAGELANDING.EXEC." .. Host, Host, 10 )
		
	end
end

function STAGELANDING:Validate( Mission, Client, Task )
	self:F()
  
	Task.CurrentLandingZoneName = routines.IsUnitNearZonesRadius( Client:GetClientGroupDCSUnit(), Task.LandingZones.LandingZoneNames, 500 )
	if Task.CurrentLandingZoneName then
	
		-- Client is in de landing zone.
		self:T( Task.CurrentLandingZoneName )
		
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
		Task.Signalled = false 
		Task:RemoveCargoMenus( Client )
    self:T( -1 )
		return -1
	end
  
	
	local DCSUnitVelocityVec3 = Client:GetClientGroupDCSUnit():getVelocity()
	local DCSUnitVelocity = ( DCSUnitVelocityVec3.x ^2 + DCSUnitVelocityVec3.y ^2 + DCSUnitVelocityVec3.z ^2 ) ^ 0.5
	
	local DCSUnitPointVec3 = Client:GetClientGroupDCSUnit():getPoint()
	local LandHeight = land.getHeight( { x = DCSUnitPointVec3.x, y = DCSUnitPointVec3.z } ) 
  local DCSUnitHeight = DCSUnitPointVec3.y - LandHeight
	
  self:T( { Task.IsLandingRequired, Client:GetClientGroupDCSUnit():inAir() } )
  if Task.IsLandingRequired and not Client:GetClientGroupDCSUnit():inAir() then
    self:T( 1 )
    Task.IsInAirTestRequired = true
    return 1
  end
  
	self:T( { DCSUnitVelocity, DCSUnitHeight, LandHeight, Task.CurrentCargoZone.SignalHeight } )
	if Task.IsLandingRequired and DCSUnitVelocity <= 0.05 and DCSUnitHeight <= Task.CurrentCargoZone.SignalHeight then
    self:T( 1 )
    Task.IsInAirTestRequired = false
    return 1
	end

  self:T( 0 )
	return 0
end

STAGELANDED = {
  ClassName = "STAGELANDED",
  MSG = { ID = "Land", TIME = 10 },
  Name = "Landed",
  MenusAdded = false
}

function STAGELANDED:New()
	local self = BASE:Inherit( self, STAGE:New() )
	self:F()
	self.StageType = 'CLIENT'
	return self
end

function STAGELANDED:Execute( Mission, Client, Task )
	self:F()

	if Task.IsLandingRequired then

	  local Host = "Command"
	  if Task.HostUnitName then
	    Host = Task.HostUnitName .. " (" .. Task.HostUnitTypeName .. ")"
  	else
      if Client:IsMultiSeated() then
        Host = "Co-Pilot"
      end
    end

    Client:Message( 'You have landed within the landing zone. Use the radio menu (F10) to ' .. Task.TEXT[1]  .. ' the ' .. Task.CargoType .. '.', 
                    self.MSG.TIME,  Mission.Name .. "/STAGELANDED.EXEC" .. Host, Host )

  	if not self.MenusAdded then
			Task.Cargo = nil
			Task:RemoveCargoMenus( Client )
			Task:AddCargoMenus( Client, CARGOS, 250 )
		end
	end
end



function STAGELANDED:Validate( Mission, Client, Task )
	self:F()

	if not routines.IsUnitNearZonesRadius( Client:GetClientGroupDCSUnit(), Task.CurrentLandingZoneName, 500 ) then
	    self:T( "Client is not anymore in the landing zone, go back to stage Route, and remove cargo menus." )
		Task.Signalled = false 
		Task:RemoveCargoMenus( Client )
    self:T( -2 )
		return -2
	end

  local DCSUnitVelocityVec3 = Client:GetClientGroupDCSUnit():getVelocity()
  local DCSUnitVelocity = ( DCSUnitVelocityVec3.x ^2 + DCSUnitVelocityVec3.y ^2 + DCSUnitVelocityVec3.z ^2 ) ^ 0.5
  
  local DCSUnitPointVec3 = Client:GetClientGroupDCSUnit():getPoint()
  local LandHeight = land.getHeight( { x = DCSUnitPointVec3.x, y = DCSUnitPointVec3.z } ) 
  local DCSUnitHeight = DCSUnitPointVec3.y - LandHeight
  
  self:T( { Task.IsLandingRequired, Client:GetClientGroupDCSUnit():inAir() } )
  if Task.IsLandingRequired and Task.IsInAirTestRequired == true and Client:GetClientGroupDCSUnit():inAir() then
    self:T( "Client went back in the air. Go back to stage Landing." )
    self:T( -1 )
    return -1
  end
  
  self:T( { DCSUnitVelocity, DCSUnitHeight, LandHeight, Task.CurrentCargoZone.SignalHeight } )
  if Task.IsLandingRequired and Task.IsInAirTestRequired == false and DCSUnitVelocity >= 2 and DCSUnitHeight >= Task.CurrentCargoZone.SignalHeight then
    self:T( "It seems the Client went back in the air and over the boundary limits. Go back to stage Landing." )
    self:T( -1 )
    return -1
  end
  
    -- Wait until cargo is selected from the menu.
	if Task.IsLandingRequired then 
		if not Task.Cargo then
		  self:T( 0 )
			return 0
		end
	end

  self:T( 1 )
	return 1
end

STAGEUNLOAD = {
  ClassName = "STAGEUNLOAD",
  MSG = { ID = "Unload", TIME = 10 },
  Name = "Unload"
}

function STAGEUNLOAD:New()
	local self = BASE:Inherit( self, STAGE:New() )
	self:F()
	self.StageType = 'CLIENT'
	return self
end

--- Coordinate UnLoading
-- @param #STAGEUNLOAD self
-- @param Mission#MISSION Mission
-- @param Client#CLIENT Client
-- @param Task#TASK Task
function STAGEUNLOAD:Execute( Mission, Client, Task )
	self:F()
	
	if Client:IsMultiSeated() then
  	Client:Message( 'The ' .. Task.CargoType .. ' are being ' .. Task.TEXT[2] .. ' within the landing zone. Wait until the helicopter is ' .. Task.TEXT[3] .. '.', 
                    self.MSG.TIME,  Mission.Name .. "/StageUnLoad", "Co-Pilot" )
  else
    Client:Message( 'You are unloading the ' .. Task.CargoType .. ' ' .. Task.TEXT[2] .. ' within the landing zone. Wait until the helicopter is ' .. Task.TEXT[3] .. '.', 
                    self.MSG.TIME,  Mission.Name .. "/StageUnLoad", "Command" )
  end
	Task:RemoveCargoMenus( Client )
end

function STAGEUNLOAD:Executing( Mission, Client, Task )
	self:F()
	env.info( 'STAGEUNLOAD:Executing() Task.Cargo.CargoName = ' .. Task.Cargo.CargoName )
	
	local TargetZoneName
	
	if Task.TargetZoneName then
		TargetZoneName = Task.TargetZoneName
	else
		TargetZoneName = Task.CurrentLandingZoneName
	end
	
	if Task.Cargo:UnLoad( Client, TargetZoneName ) then
		Task.ExecuteStage = _TransportExecuteStage.SUCCESS
		if Mission.MissionReportFlash then
			Client:ShowCargo()
		end
	end
end

--- Validate UnLoading
-- @param #STAGEUNLOAD self
-- @param Mission#MISSION Mission
-- @param Client#CLIENT Client
-- @param Task#TASK Task
function STAGEUNLOAD:Validate( Mission, Client, Task )
	self:F()
	env.info( 'STAGEUNLOAD:Validate()' )
  
  if routines.IsUnitNearZonesRadius( Client:GetClientGroupDCSUnit(), Task.CurrentLandingZoneName, 500 ) then
  else
    Task.ExecuteStage = _TransportExecuteStage.FAILED
    Task:RemoveCargoMenus( Client )
    if Client:IsMultiSeated() then
      Client:Message( 'The ' .. Task.CargoType .. " haven't been successfully " .. Task.TEXT[3] .. '  within the landing zone. Task and mission has failed.', 
  	                _TransportStageMsgTime.DONE,  Mission.Name .. "/StageFailure", "Co-Pilot" )
  	else
      Client:Message( 'The ' .. Task.CargoType .. " haven't been successfully " .. Task.TEXT[3] .. '  within the landing zone. Task and mission has failed.', 
                    _TransportStageMsgTime.DONE,  Mission.Name .. "/StageFailure", "Command" )
  	end
    return 1
  end
  
  if not Client:GetClientGroupDCSUnit():inAir() then
  else
    Task.ExecuteStage = _TransportExecuteStage.FAILED
    Task:RemoveCargoMenus( Client )
    if Client:IsMultiSeated() then
      Client:Message( 'The ' .. Task.CargoType .. " haven't been successfully " .. Task.TEXT[3] .. '  within the landing zone. Task and mission has failed.', 
  	                _TransportStageMsgTime.DONE,  Mission.Name .. "/StageFailure", "Co-Pilot" )
	  else
      Client:Message( 'The ' .. Task.CargoType .. " haven't been successfully " .. Task.TEXT[3] .. '  within the landing zone. Task and mission has failed.', 
                    _TransportStageMsgTime.DONE,  Mission.Name .. "/StageFailure", "Command" )
	  end
    return 1
  end
  
  if  Task.ExecuteStage == _TransportExecuteStage.SUCCESS then
    if Client:IsMultiSeated() then
      Client:Message( 'The ' .. Task.CargoType .. ' have been sucessfully ' .. Task.TEXT[3] .. '  within the landing zone.', _TransportStageMsgTime.DONE,  Mission.Name .. "/Stage", "Co-Pilot" )
    else
      Client:Message( 'The ' .. Task.CargoType .. ' have been sucessfully ' .. Task.TEXT[3] .. '  within the landing zone.', _TransportStageMsgTime.DONE,  Mission.Name .. "/Stage", "Command" )
    end
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
	local self = BASE:Inherit( self, STAGE:New() )
	self:F()
	self.StageType = 'CLIENT'
	return self
end

function STAGELOAD:Execute( Mission, Client, Task )
	self:F()
	
	if not Task.IsSlingLoad then
 
    local Host = "Command"
    if Task.HostUnitName then
      Host = Task.HostUnitName .. " (" .. Task.HostUnitTypeName .. ")"
    else
      if Client:IsMultiSeated() then
        Host = "Co-Pilot"
      end
    end

		Client:Message( 'The ' .. Task.CargoType .. ' are being ' .. Task.TEXT[2] .. ' within the landing zone. Wait until the helicopter is ' .. Task.TEXT[3] .. '.', 
						_TransportStageMsgTime.EXECUTING,  Mission.Name .. "/STAGELOAD.EXEC." .. Host, Host )

		-- Route the cargo to the Carrier
		
		Task.Cargo:OnBoard( Client, Task.CurrentCargoZone, Task.OnBoardSide )
		Task.ExecuteStage = _TransportExecuteStage.EXECUTING
	else
		Task.ExecuteStage = _TransportExecuteStage.EXECUTING
	end
end

function STAGELOAD:Executing( Mission, Client, Task )
	self:F()

	-- If the Cargo is ready to be loaded, load it into the Client.

  local Host = "Command"
  if Task.HostUnitName then
    Host = Task.HostUnitName .. " (" .. Task.HostUnitTypeName .. ")"
  else
    if Client:IsMultiSeated() then
      Host = "Co-Pilot"
    end
  end
		
	if not Task.IsSlingLoad then
		self:T( Task.Cargo.CargoName)
		
		if Task.Cargo:OnBoarded( Client, Task.CurrentCargoZone ) then

			-- Load the Cargo onto the Client
			Task.Cargo:Load( Client )
		
			-- Message to the pilot that cargo has been loaded.
			Client:Message( "The cargo " .. Task.Cargo.CargoName .. " has been loaded in our helicopter.", 
							20, Mission.Name .. "/STAGELANDING.LOADING1."  .. Host, Host )
			Task.ExecuteStage = _TransportExecuteStage.SUCCESS
			
			Client:ShowCargo()
		end
	else
		Client:Message( "Hook the " .. Task.CargoNames .. " onto the helicopter " .. Task.TEXT[3] .. " within the landing zone.", 
						_TransportStageMsgTime.EXECUTING,  Mission.Name .. "/STAGELOAD.LOADING.1."  .. Host, Host , 10 )
		for CargoID, Cargo in pairs( CARGOS ) do
			self:T( "Cargo.CargoName = " .. Cargo.CargoName )
			
			if Cargo:IsSlingLoad() then
				local CargoStatic = StaticObject.getByName( Cargo.CargoStaticName )
				if CargoStatic then
					self:T( "Cargo is found in the DCS simulator.")
					local CargoStaticPosition = CargoStatic:getPosition().p
					self:T( "Cargo Position x = " .. CargoStaticPosition.x .. ", y = " ..  CargoStaticPosition.y .. ", z = " ..  CargoStaticPosition.z )
					local CargoStaticHeight = routines.GetUnitHeight( CargoStatic )
					if CargoStaticHeight > 5 then
						self:T( "Cargo is airborne.")
						Cargo:StatusLoaded()
						Task.Cargo = Cargo
						Client:Message( 'The Cargo has been successfully hooked onto the helicopter and is now being sling loaded. Fly outside the landing zone.', 
										self.MSG.TIME,  Mission.Name .. "/STAGELANDING.LOADING.2."  .. Host, Host  )
						Task.ExecuteStage = _TransportExecuteStage.SUCCESS
						break
					end
				else
					self:T( "Cargo not found in the DCS simulator." )
				end
			end
		end
	end
  
end

function STAGELOAD:Validate( Mission, Client, Task )
	self:F()

	self:T( "Task.CurrentLandingZoneName = " .. Task.CurrentLandingZoneName )

  local Host = "Command"
  if Task.HostUnitName then
    Host = Task.HostUnitName .. " (" .. Task.HostUnitTypeName .. ")"
  else
    if Client:IsMultiSeated() then
      Host = "Co-Pilot"
    end
  end

 	if not Task.IsSlingLoad then
		if not routines.IsUnitNearZonesRadius( Client:GetClientGroupDCSUnit(), Task.CurrentLandingZoneName, 500 ) then
			Task:RemoveCargoMenus( Client )
			Task.ExecuteStage = _TransportExecuteStage.FAILED
			Task.CargoName = nil 
			Client:Message( "The " .. Task.CargoType .. " loading has been aborted. You flew outside the pick-up zone while loading. ", 
							self.MSG.TIME,  Mission.Name .. "/STAGELANDING.VALIDATE.1." .. Host, Host )
      self:T( -1 )
			return -1
		end

    local DCSUnitVelocityVec3 = Client:GetClientGroupDCSUnit():getVelocity()
    local DCSUnitVelocity = ( DCSUnitVelocityVec3.x ^2 + DCSUnitVelocityVec3.y ^2 + DCSUnitVelocityVec3.z ^2 ) ^ 0.5
    
    local DCSUnitPointVec3 = Client:GetClientGroupDCSUnit():getPoint()
    local LandHeight = land.getHeight( { x = DCSUnitPointVec3.x, y = DCSUnitPointVec3.z } ) 
    local DCSUnitHeight = DCSUnitPointVec3.y - LandHeight
    
    self:T( { Task.IsLandingRequired, Client:GetClientGroupDCSUnit():inAir() } )
    if Task.IsLandingRequired and Task.IsInAirTestRequired == true and Client:GetClientGroupDCSUnit():inAir() then
      Task:RemoveCargoMenus( Client )
      Task.ExecuteStage = _TransportExecuteStage.FAILED
      Task.CargoName = nil 
      Client:Message( "The " .. Task.CargoType .. " loading has been aborted. Re-start the " .. Task.TEXT[3] .. " process. Don't fly outside the pick-up zone.", 
              self.MSG.TIME,  Mission.Name .. "/STAGELANDING.VALIDATE.1." .. Host, Host )
      self:T( -1 )
      return -1
    end
    
    self:T( { DCSUnitVelocity, DCSUnitHeight, LandHeight, Task.CurrentCargoZone.SignalHeight } )
    if Task.IsLandingRequired and Task.IsInAirTestRequired == false and DCSUnitVelocity >= 2 and DCSUnitHeight >= Task.CurrentCargoZone.SignalHeight then
      Task:RemoveCargoMenus( Client )
      Task.ExecuteStage = _TransportExecuteStage.FAILED
      Task.CargoName = nil 
      Client:Message( "The " .. Task.CargoType .. " loading has been aborted. Re-start the " .. Task.TEXT[3] .. " process. Don't fly outside the pick-up zone.", 
              self.MSG.TIME,  Mission.Name .. "/STAGELANDING.VALIDATE.1." .. Host, Host )
      self:T( -1 )
      return -1
    end

		if Task.ExecuteStage == _TransportExecuteStage.SUCCESS then
			Task:RemoveCargoMenus( Client )
			Client:Message( "Good Job. The " .. Task.CargoType .. " has been sucessfully " .. Task.TEXT[3] .. " within the landing zone.", 
							self.MSG.TIME,  Mission.Name .. "/STAGELANDING.VALIDATE.3." .. Host, Host )
			Task.MissionTask:AddGoalCompletion( Task.MissionTask.GoalVerb, Task.CargoName, 1 )
      self:T( 1 )
			return 1
		end

	else
		if Task.ExecuteStage == _TransportExecuteStage.SUCCESS then
			CargoStatic = StaticObject.getByName( Task.Cargo.CargoStaticName )
			if CargoStatic and not routines.IsStaticInZones( CargoStatic, Task.CurrentLandingZoneName ) then
				Client:Message( "Good Job. The " .. Task.CargoType .. " has been sucessfully " .. Task.TEXT[3] .. " and flown outside of the landing zone.", 
								self.MSG.TIME,  Mission.Name .. "/STAGELANDING.VALIDATE.4." .. Host, Host )
				Task.MissionTask:AddGoalCompletion( Task.MissionTask.GoalVerb, Task.Cargo.CargoName, 1 )
        self:T( 1 )
				return 1
			end
		end
	
	end
  
 
  self:T( 0 )
	return 0
end


STAGEDONE = {
  ClassName = "STAGEDONE",
  MSG = { ID = "Done", TIME = 10 },
  Name = "Done"
}

function STAGEDONE:New()
	local self = BASE:Inherit( self, STAGE:New() )
	self:F()
	self.StageType = 'AI'
	return self
end

function STAGEDONE:Execute( Mission, Client, Task )
	self:F()

end

function STAGEDONE:Validate( Mission, Client, Task )
	self:F()

	Task:Done()
  
	return 0
end

STAGEARRIVE = {
  ClassName = "STAGEARRIVE",
  MSG = { ID = "Arrive", TIME = 10 },
  Name = "Arrive"
}

function STAGEARRIVE:New()
	local self = BASE:Inherit( self, STAGE:New() )
	self:F()
	self.StageType = 'CLIENT'
	return self
end


--- Execute Arrival
-- @param #STAGEARRIVE self
-- @param Mission#MISSION Mission
-- @param Client#CLIENT Client
-- @param Task#TASK Task
function STAGEARRIVE:Execute( Mission, Client, Task )
	self:F()
 
  if Client:IsMultiSeated() then
    Client:Message( 'We have arrived at ' .. Task.CurrentLandingZoneName .. ".", self.MSG.TIME,  Mission.Name .. "/Stage", "Co-Pilot" )
  else
    Client:Message( 'We have arrived at ' .. Task.CurrentLandingZoneName .. ".", self.MSG.TIME,  Mission.Name .. "/Stage", "Command" )
  end  

end

function STAGEARRIVE:Validate( Mission, Client, Task )
	self:F()
  
  Task.CurrentLandingZoneID  = routines.IsUnitInZones( Client:GetClientGroupDCSUnit(), Task.LandingZones )
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
	local self = BASE:Inherit( self, STAGE:New() )
	self:F()
	self.StageType = 'AI'
	return self
end

--function STAGEGROUPSDESTROYED:Execute( Mission, Client, Task )
-- 
--	Client:Message( 'Task: Still ' .. DestroyGroupSize .. " of " .. Task.DestroyGroupCount .. " " .. Task.DestroyGroupType .. " to be destroyed!", self.MSG.TIME,  Mission.Name .. "/Stage" )
--
--end

function STAGEGROUPSDESTROYED:Validate( Mission, Client, Task )
	self:F()
 
	if Task.MissionTask:IsGoalReached() then
		return 1
	else
		return 0
	end
end

function STAGEGROUPSDESTROYED:Execute( Mission, Client, Task )
	self:F()
	self:T( { Task.ClassName, Task.Destroyed } )
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
