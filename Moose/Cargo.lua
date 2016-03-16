--- CARGO Classes
-- @module CARGO

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Message" )

--- Clients are those Groups defined within the Mission Editor that have the skillset defined as "Client" or "Player".
-- These clients are defined within the Mission Orchestration Framework (MOF)

CARGOS = {}


CARGO_ZONE = {
	ClassName="CARGO_ZONE",
	CargoZoneName = '',
	CargoHostUnitName = '',
	SIGNAL = {
		TYPE = {
			SMOKE = { ID = 1, TEXT = "smoke" },
			FLARE = { ID = 2, TEXT = "flare" }
		},
		COLOR = {	
			GREEN = { ID = 1, TRIGGERCOLOR = trigger.smokeColor.Green, TEXT = "A green" },
			RED = { ID = 2, TRIGGERCOLOR = trigger.smokeColor.Red, TEXT = "A red" },
			WHITE = { ID = 3, TRIGGERCOLOR = trigger.smokeColor.White, TEXT = "A white" },
			ORANGE = { ID = 4, TRIGGERCOLOR = trigger.smokeColor.Orange, TEXT = "An orange" },
			BLUE = { ID = 5, TRIGGERCOLOR = trigger.smokeColor.Blue, TEXT = "A blue" },
			YELLOW = { ID = 6, TRIGGERCOLOR = trigger.flareColor.Yellow, TEXT = "A yellow" }
		}
	}
}

function CARGO_ZONE:New( CargoZoneName, CargoHostName ) local self = BASE:Inherit( self, BASE:New() )
self:T( { CargoZoneName, CargoHostName } )

	self.CargoZoneName = CargoZoneName
	self.CargoZone = trigger.misc.getZone( CargoZoneName )
	

	if CargoHostName then
		self.CargoHostName = CargoHostName
	end

	self:T( self.CargoZone )
	
	return self
end

function CARGO_ZONE:Spawn()
	self:T( self.CargoHostName )

	if self.CargoHostSpawn then
		local CargoHostGroup = self.CargoHostSpawn:GetGroupFromIndex()
		if CargoHostGroup and CargoHostGroup:IsAlive() then
		else
			self.CargoHostSpawn:ReSpawn( 1 )
		end
	else
		self:T( "Initialize CargoHostSpawn" )
		self.CargoHostSpawn = SPAWN:New( self.CargoHostName ):Limit( 1, 1 )
		self.CargoHostSpawn:ReSpawn( 1 )
	end

	return self
end

function CARGO_ZONE:GetHostUnit()
	self:T( self )

	if self.CargoHostName then
		
		-- A Host has been given, signal the host
		local CargoHostGroup = self.CargoHostSpawn:GetGroupFromIndex()
		local CargoHostUnit
		if CargoHostGroup and CargoHostGroup:IsAlive() then
			CargoHostUnit = CargoHostGroup:GetUnit(1)
		else
			CargoHostUnit = StaticObject.getByName( self.CargoHostName )
		end
		
		return CargoHostUnit
	end
	
	return nil
end

function CARGO_ZONE:ReportCargosToClient( Client, CargoType )
self:T()

	local SignalUnit = self:GetHostUnit()

	if SignalUnit then
		
		local SignalUnitTypeName = SignalUnit:getTypeName()
		
		local HostMessage = ""

		local IsCargo = false
		for CargoID, Cargo in pairs( CARGOS ) do
			if Cargo.CargoType == Task.CargoType then
				if Cargo:IsStatusNone() then
					HostMessage = HostMessage .. " - " .. Cargo.CargoName .. " - " .. Cargo.CargoType .. " (" .. Cargo.Weight .. "kg)" .. "\n"
					IsCargo = true
				end
			end
		end
		
		if not IsCargo then
			HostMessage = "No Cargo Available."
		end

		Client:Message( HostMessage, 20, Mission.Name .. "/StageHosts." .. SignalUnitTypeName, SignalUnitTypeName .. ": Reporting Cargo", 10 )
	end
end

function CARGO_ZONE:Signal()
self:T()

	local Signalled = false

	if self.SignalType then
	
		if self.CargoHostName then
			
			-- A Host has been given, signal the host
			
			local SignalUnit = self:GetHostUnit()
			
			if SignalUnit then
			
				self:T( 'Signalling Unit' )
				local SignalVehiclePos = SignalUnit:GetPositionVec3()
				SignalVehiclePos.y = SignalVehiclePos.y + 2

				if self.SignalType.ID == CARGO_ZONE.SIGNAL.TYPE.SMOKE.ID then

					trigger.action.smoke( SignalVehiclePos, self.SignalColor.TRIGGERCOLOR )
					Signalled = true

				elseif self.SignalType.ID == CARGO_ZONE.SIGNAL.TYPE.FLARE.ID then

					trigger.action.signalFlare( SignalVehiclePos, self.SignalColor.TRIGGERCOLOR , 0 )
					Signalled = false

				end
			end
			
		else
		
			local CurrentPosition = { x = self.CargoZone.point.x, y = self.CargoZone.point.z }
			self.CargoZone.point.y = land.getHeight( CurrentPosition ) + 2
	  
			if self.SignalType.ID == CARGO_ZONE.SIGNAL.TYPE.SMOKE.ID then

				trigger.action.smoke( self.CargoZone.point, self.SignalColor.TRIGGERCOLOR  )
				Signalled = true

			elseif self.SignalType.ID == CARGO_ZONE.SIGNAL.TYPE.FLARE.ID then
				trigger.action.signalFlare( self.CargoZone.point, self.SignalColor.TRIGGERCOLOR, 0 )
				Signalled = false

			end
		end
	end
	
	return Signalled

end

function CARGO_ZONE:WhiteSmoke()
self:T()

	self.SignalType = CARGO_ZONE.SIGNAL.TYPE.SMOKE
	self.SignalColor = CARGO_ZONE.SIGNAL.COLOR.WHITE

	return self
end

function CARGO_ZONE:BlueSmoke()
self:T()

	self.SignalType = CARGO_ZONE.SIGNAL.TYPE.SMOKE
	self.SignalColor = CARGO_ZONE.SIGNAL.COLOR.BLUE

	return self
end

function CARGO_ZONE:RedSmoke()
self:T()

	self.SignalType = CARGO_ZONE.SIGNAL.TYPE.SMOKE
	self.SignalColor = CARGO_ZONE.SIGNAL.COLOR.RED

	return self
end

function CARGO_ZONE:OrangeSmoke()
self:T()

	self.SignalType = CARGO_ZONE.SIGNAL.TYPE.SMOKE
	self.SignalColor = CARGO_ZONE.SIGNAL.COLOR.ORANGE

	return self
end

function CARGO_ZONE:GreenSmoke()
self:T()

	self.SignalType = CARGO_ZONE.SIGNAL.TYPE.SMOKE
	self.SignalColor = CARGO_ZONE.SIGNAL.COLOR.GREEN

	return self
end


function CARGO_ZONE:WhiteFlare()
self:T()

	self.SignalType = CARGO_ZONE.SIGNAL.TYPE.FLARE
	self.SignalColor = CARGO_ZONE.SIGNAL.COLOR.WHITE

	return self
end

function CARGO_ZONE:RedFlare()
self:T()

	self.SignalType = CARGO_ZONE.SIGNAL.TYPE.FLARE
	self.SignalColor = CARGO_ZONE.SIGNAL.COLOR.RED

	return self
end

function CARGO_ZONE:GreenFlare()
self:T()

	self.SignalType = CARGO_ZONE.SIGNAL.TYPE.FLARE
	self.SignalColor = CARGO_ZONE.SIGNAL.COLOR.GREEN

	return self
end

function CARGO_ZONE:YellowFlare()
self:T()

	self.SignalType = CARGO_ZONE.SIGNAL.TYPE.FLARE
	self.SignalColor = CARGO_ZONE.SIGNAL.COLOR.YELLOW

	return self
end


function CARGO_ZONE:GetCargoHostUnit()
	self:T( self )

	if self.CargoHostSpawn then 
		local CargoHostGroup = self.CargoHostSpawn:GetGroupFromIndex(1)
		if CargoHostGroup and CargoHostGroup:IsAlive() then
			local CargoHostUnit = CargoHostGroup:GetUnit(1)
			if CargoHostUnit and CargoHostUnit:IsAlive() then
				return CargoHostUnit
			end
		end
	end

	return nil
end

function CARGO_ZONE:GetCargoZoneName()
self:T()

	return self.CargoZoneName
end

CARGO = {
	ClassName = "CARGO",
	STATUS = {
		NONE = 0,
		LOADED = 1,
		UNLOADED = 2,
		LOADING = 3
	},
	CargoClient = nil
}

--- Add Cargo to the mission... Cargo functionality needs to be reworked a bit, so this is still under construction. I need to make a CARGO Class...
function CARGO:New( CargoType, CargoName, CargoWeight ) local self = BASE:Inherit( self, BASE:New() )
self:T( { CargoType, CargoName, CargoWeight } )


	self.CargoType = CargoType
	self.CargoName = CargoName
    self.CargoWeight = CargoWeight

	self:StatusNone()
	
	return self
end

function CARGO:Spawn( Client )
	self:T()

	return self

end

function CARGO:IsNear( Client, LandingZone )
self:T()

	local Near = true
	
	return Near
	
end


function CARGO:IsLoadingToClient()
self:T()

	if self:IsStatusLoading() then
		return self.CargoClient
	end
	
	return nil

end


function CARGO:IsLoadedInClient()
self:T()

	if self:IsStatusLoaded() then
		return self.CargoClient
	end
	
	return nil

end


function CARGO:UnLoad( Client, TargetZoneName )
self:T()

	self:StatusUnLoaded()

	return self
end

function CARGO:OnBoard( Client, LandingZone )
self:T()
  
	local Valid = true
  
	self.CargoClient = Client
	local ClientUnit = Client:GetClientGroupDCSUnit()

	return Valid
end

function CARGO:OnBoarded( Client, LandingZone )
self:T()

	local OnBoarded = true
  
	return OnBoarded
end

function CARGO:Load( Client )
self:T()

	self:StatusLoaded( Client )

	return self
end

function CARGO:IsLandingRequired()
self:T()
	return true
end

function CARGO:IsSlingLoad()
self:T()
	return false
end


function CARGO:StatusNone()
self:T()

	self.CargoClient = nil
	self.CargoStatus = CARGO.STATUS.NONE
	
	return self
end

function CARGO:StatusLoading( Client )
self:T()

	self.CargoClient = Client
	self.CargoStatus = CARGO.STATUS.LOADING
	self:T( "Cargo " .. self.CargoName .. " loading to Client: " .. self.CargoClient:GetClientGroupName() )
	
	return self
end

function CARGO:StatusLoaded( Client )
self:T()

	self.CargoClient = Client
	self.CargoStatus = CARGO.STATUS.LOADED
	self:T( "Cargo " .. self.CargoName .. " loaded in Client: " .. self.CargoClient:GetClientGroupName() )
	
	return self
end

function CARGO:StatusUnLoaded()
self:T()

	self.CargoClient = nil
	self.CargoStatus = CARGO.STATUS.UNLOADED
	
	return self
end


function CARGO:IsStatusNone()
self:T()

	return self.CargoStatus == CARGO.STATUS.NONE
end

function CARGO:IsStatusLoading()
self:T()

	return self.CargoStatus == CARGO.STATUS.LOADING
end

function CARGO:IsStatusLoaded()
self:T()

	return self.CargoStatus == CARGO.STATUS.LOADED
end

function CARGO:IsStatusUnLoaded()
self:T()

	return self.CargoStatus == CARGO.STATUS.UNLOADED
end


CARGO_GROUP = {
	ClassName = "CARGO_GROUP"
}


function CARGO_GROUP:New( CargoType, CargoName, CargoWeight, CargoGroupTemplate, CargoZone ) 	local self = BASE:Inherit( self, CARGO:New( CargoType, CargoName, CargoWeight ) )
	self:T( { CargoType, CargoName, CargoWeight, CargoGroupTemplate, CargoZone } )

	self.CargoSpawn = SPAWN:NewWithAlias( CargoGroupTemplate, CargoName )
	self.CargoZone = CargoZone

	CARGOS[self.CargoName] = self

	return self

end

function CARGO_GROUP:Spawn( Client )
	self:T( { Client } )

	local SpawnCargo = true
	
	if self:IsStatusNone() then
		local CargoGroup = Group.getByName( self.CargoName )
		if CargoGroup and CargoGroup:isExist() then
			SpawnCargo = false
		end
		
	elseif self:IsStatusLoading() then
	
		local Client = self:IsLoadingToClient()
		if Client and Client:ClientGroup() then
			SpawnCargo = false
		else
			local CargoGroup = Group.getByName( self.CargoName	 )
			if CargoGroup and CargoGroup:isExist() then
				SpawnCargo = false
			end
		end
	
	elseif self:IsStatusLoaded()  then
	
		local ClientLoaded = self:IsLoadedInClient()
		-- Now test if another Client is alive (not this one), and it has the CARGO, then this cargo does not need to be initialized and spawned.
		if ClientLoaded and ClientLoaded ~= Client then
			local ClientGroup = Client:ClientGroup()
			if ClientLoaded:GetClientGroupDCSUnit() and ClientLoaded:GetClientGroupDCSUnit():isExist() then
				SpawnCargo = false
			else
				self:StatusNone()
			end
		else
			-- Same Client, but now in initialize, so set back the status to None.
			self:StatusNone()
		end
		
	elseif self:IsStatusUnLoaded() then
	
		SpawnCargo = false
		
	end
	
	if SpawnCargo then 
		if self.CargoZone:GetCargoHostUnit() then
			--- ReSpawn the Cargo from the CargoHost
			self.CargoGroupName = self.CargoSpawn:SpawnFromUnit( self.CargoZone:GetCargoHostUnit(), 60, 30, 1 ):GetName()
		else
			--- ReSpawn the Cargo in the CargoZone without a host ...
			self.CargoGroupName = self.CargoSpawn:SpawnInZone( self.CargoZone, 1 ):GetName()
		end
		self:StatusNone()	
	end
	
	self:T( { self.CargoGroupName, CARGOS[self.CargoName].CargoGroupName } )

	return self
end

function CARGO_GROUP:IsNear( Client, LandingZone )
self:T()

	local Near = false

	if self.CargoGroupName then 
		local CargoGroup = Group.getByName( self.CargoGroupName )
		if routines.IsPartOfGroupInRadius( CargoGroup, Client:ClientPosition(), 250 ) then
			Near = true
		end
	end
	
	return Near
	
end


function CARGO_GROUP:OnBoard( Client, LandingZone, OnBoardSide )
self:T()
  
	local Valid = true
  
	local ClientUnit = Client:GetClientGroupDCSUnit()
	
	local CarrierPos = ClientUnit:getPoint()
	local CarrierPosMove = ClientUnit:getPoint()
	local CarrierPosOnBoard = ClientUnit:getPoint()
	
	local CargoGroup = Group.getByName( self.CargoGroupName )

	local CargoUnits = CargoGroup:getUnits()
	local CargoPos = CargoUnits[1]:getPoint()

	
	local Points = {}
	
	self:T( 'CargoPos x = ' .. CargoPos.x .. " z = " .. CargoPos.z )
	self:T( 'CarrierPosMove x = ' .. CarrierPosMove.x .. " z = " .. CarrierPosMove.z )
	
	Points[#Points+1] = routines.ground.buildWP( CargoPos, "Cone", 10 )

	self:T( 'Points[1] x = ' .. Points[1].x .. " y = " .. Points[1].y )
	
	if OnBoardSide == nil then
		OnBoardSide = CLIENT.ONBOARDSIDE.NONE
	end
	
	if OnBoardSide == CLIENT.ONBOARDSIDE.LEFT then
	
		self:T( "TransportCargoOnBoard: Onboarding LEFT" )
		CarrierPosMove.z = CarrierPosMove.z - 25
		CarrierPosOnBoard.z = CarrierPosOnBoard.z - 5
		Points[#Points+1] = routines.ground.buildWP( CarrierPosMove, "Cone", 10 )
		Points[#Points+1] = routines.ground.buildWP( CarrierPosOnBoard, "Cone", 10 )
	
	elseif  OnBoardSide == CLIENT.ONBOARDSIDE.RIGHT then
		
		self:T( "TransportCargoOnBoard: Onboarding RIGHT" )
		CarrierPosMove.z = CarrierPosMove.z + 25
		CarrierPosOnBoard.z = CarrierPosOnBoard.z + 5
		Points[#Points+1] = routines.ground.buildWP( CarrierPosMove, "Cone", 10 )
		Points[#Points+1] = routines.ground.buildWP( CarrierPosOnBoard, "Cone", 10 )
	
	elseif  OnBoardSide == CLIENT.ONBOARDSIDE.BACK then
		
		self:T( "TransportCargoOnBoard: Onboarding BACK" )
		CarrierPosMove.x = CarrierPosMove.x - 25
		CarrierPosOnBoard.x = CarrierPosOnBoard.x - 5
		Points[#Points+1] = routines.ground.buildWP( CarrierPosMove, "Cone", 10 )
		Points[#Points+1] = routines.ground.buildWP( CarrierPosOnBoard, "Cone", 10 )
	
	elseif  OnBoardSide == CLIENT.ONBOARDSIDE.FRONT then
		
		self:T( "TransportCargoOnBoard: Onboarding FRONT" )
		CarrierPosMove.x = CarrierPosMove.x + 25
		CarrierPosOnBoard.x = CarrierPosOnBoard.x + 5
		Points[#Points+1] = routines.ground.buildWP( CarrierPosMove, "Cone", 10 )
		Points[#Points+1] = routines.ground.buildWP( CarrierPosOnBoard, "Cone", 10 )
	
	elseif  OnBoardSide == CLIENT.ONBOARDSIDE.NONE then
		
		self:T( "TransportCargoOnBoard: Onboarding CENTRAL" )
		Points[#Points+1] = routines.ground.buildWP( CarrierPos, "Cone", 10 )
	
	end
	self:T( "TransportCargoOnBoard: Routing " .. self.CargoGroupName )

	routines.scheduleFunction( routines.goRoute, { self.CargoGroupName, Points}, timer.getTime() + 4 )
	
	self:StatusLoading( Client )
     
	return Valid
  
end


function CARGO_GROUP:OnBoarded( Client, LandingZone )
self:T()

	local OnBoarded = false
  
	local CargoGroup = Group.getByName( self.CargoGroupName )
	if routines.IsPartOfGroupInRadius( CargoGroup, Client:ClientPosition(), 25 ) then
		CargoGroup:destroy()
		self:StatusLoaded( Client )
		OnBoarded = true
	end

	return OnBoarded
end


function CARGO_GROUP:UnLoad( Client, TargetZoneName )
self:T()

	self:T( 'self.CargoName = ' .. self.CargoName ) 

	local CargoGroup = self.CargoSpawn:SpawnFromUnit( Client:GetClientGroupUnit(), 60, 30 )

	self.CargoGroupName = CargoGroup:GetName()
	self:T( 'self.CargoGroupName = ' .. self.CargoGroupName ) 
	
	CargoGroup:RouteToZone( ZONE:New( TargetZoneName ), true )
	
	self:StatusUnLoaded()

	return self
end


CARGO_PACKAGE = {
	ClassName = "CARGO_PACKAGE"
}


function CARGO_PACKAGE:New( CargoType, CargoName, CargoWeight, CargoClient ) local self = BASE:Inherit( self, CARGO:New( CargoType, CargoName, CargoWeight ) )

	self:T( { CargoType, CargoName, CargoWeight, CargoClient } )

	self.CargoClient = CargoClient
	
	CARGOS[self.CargoName] = self

	return self

end


function CARGO_PACKAGE:Spawn( Client )
	self:T( { self, Client } )

	-- this needs to be checked thoroughly

	local CargoClientGroup = self.CargoClient:ClientGroup()
	if not CargoClientGroup then
		if not self.CargoClientSpawn then
			self.CargoClientSpawn = SPAWN:New( self.CargoClient:GetClientGroupName() ):Limit( 1, 1 )
		end
		self.CargoClientSpawn:ReSpawn( 1 )	
	end

	local SpawnCargo = true
	
	if self:IsStatusNone() then
	
	elseif self:IsStatusLoading() or self:IsStatusLoaded() then

		local CargoClientLoaded = self:IsLoadedInClient()
		if CargoClientLoaded and CargoClientLoaded:ClientGroup() then
			SpawnCargo = false
		end
	
	elseif self:IsStatusUnLoaded() then
	
		SpawnCargo = false
	
	else

	end

	if SpawnCargo then
		self:StatusLoaded( self.CargoClient )
	end

	return self
end


function CARGO_PACKAGE:IsNear( Client, LandingZone )
self:T()

	local Near = false

	if self.CargoClient and self.CargoClient:ClientGroup() then
		self:T( self.CargoClient.ClientName )
		self:T( 'Client Exists.' )

		if routines.IsUnitInRadius( self.CargoClient:GetClientGroupDCSUnit(), Client:ClientPosition(), 150 ) then
			Near = true
		end
	end
	
	return Near
	
end


function CARGO_PACKAGE:OnBoard( Client, LandingZone, OnBoardSide )
self:T()
  
	local Valid = true
  
	local ClientUnit = Client:GetClientGroupDCSUnit()
	
	local CarrierPos = ClientUnit:getPoint()
	local CarrierPosMove = ClientUnit:getPoint()
	local CarrierPosOnBoard = ClientUnit:getPoint()
	local CarrierPosMoveAway = ClientUnit:getPoint()
	
	local CargoHostGroup = self.CargoClient:ClientGroup()
	local CargoHostName = self.CargoClient:ClientGroup():getName()

	local CargoHostUnits = CargoHostGroup:getUnits()
	local CargoPos = CargoHostUnits[1]:getPoint()

	local Points = {}
	
	self:T( 'CargoPos x = ' .. CargoPos.x .. " z = " .. CargoPos.z )
	self:T( 'CarrierPosMove x = ' .. CarrierPosMove.x .. " z = " .. CarrierPosMove.z )
	
	Points[#Points+1] = routines.ground.buildWP( CargoPos, "Cone", 10 )

	self:T( 'Points[1] x = ' .. Points[1].x .. " y = " .. Points[1].y )
	
	if OnBoardSide == nil then
		OnBoardSide = CLIENT.ONBOARDSIDE.NONE
	end
	
	if OnBoardSide == CLIENT.ONBOARDSIDE.LEFT then
	
		self:T( "TransportCargoOnBoard: Onboarding LEFT" )
		CarrierPosMove.z = CarrierPosMove.z - 25
		CarrierPosOnBoard.z = CarrierPosOnBoard.z - 5
		CarrierPosMoveAway.z = CarrierPosMoveAway.z - 20
		Points[#Points+1] = routines.ground.buildWP( CarrierPosMove, "Cone", 10 )
		Points[#Points+1] = routines.ground.buildWP( CarrierPosOnBoard, "Cone", 10 )
		Points[#Points+1] = routines.ground.buildWP( CarrierPosMoveAway, "Cone", 10 )
	
	elseif  OnBoardSide == CLIENT.ONBOARDSIDE.RIGHT then
		
		self:T( "TransportCargoOnBoard: Onboarding RIGHT" )
		CarrierPosMove.z = CarrierPosMove.z + 25
		CarrierPosOnBoard.z = CarrierPosOnBoard.z + 5
		CarrierPosMoveAway.z = CarrierPosMoveAway.z + 20
		Points[#Points+1] = routines.ground.buildWP( CarrierPosMove, "Cone", 10 )
		Points[#Points+1] = routines.ground.buildWP( CarrierPosOnBoard, "Cone", 10 )
		Points[#Points+1] = routines.ground.buildWP( CarrierPosMoveAway, "Cone", 10 )	
	
	elseif  OnBoardSide == CLIENT.ONBOARDSIDE.BACK then
		
		self:T( "TransportCargoOnBoard: Onboarding BACK" )
		CarrierPosMove.x = CarrierPosMove.x - 25
		CarrierPosOnBoard.x = CarrierPosOnBoard.x - 5
		CarrierPosMoveAway.x = CarrierPosMoveAway.x - 20
		Points[#Points+1] = routines.ground.buildWP( CarrierPosMove, "Cone", 10 )
		Points[#Points+1] = routines.ground.buildWP( CarrierPosOnBoard, "Cone", 10 )
		Points[#Points+1] = routines.ground.buildWP( CarrierPosMoveAway, "Cone", 10 )

	elseif  OnBoardSide == CLIENT.ONBOARDSIDE.FRONT then
		
		self:T( "TransportCargoOnBoard: Onboarding FRONT" )
		CarrierPosMove.x = CarrierPosMove.x + 25
		CarrierPosOnBoard.x = CarrierPosOnBoard.x + 5
		CarrierPosMoveAway.x = CarrierPosMoveAway.x + 20
		Points[#Points+1] = routines.ground.buildWP( CarrierPosMove, "Cone", 10 )
		Points[#Points+1] = routines.ground.buildWP( CarrierPosOnBoard, "Cone", 10 )
		Points[#Points+1] = routines.ground.buildWP( CarrierPosMoveAway, "Cone", 10 )

	elseif  OnBoardSide == CLIENT.ONBOARDSIDE.NONE then
		
		self:T( "TransportCargoOnBoard: Onboarding FRONT" )
		CarrierPosMove.x = CarrierPosMove.x + 25
		CarrierPosOnBoard.x = CarrierPosOnBoard.x + 5
		CarrierPosMoveAway.x = CarrierPosMoveAway.x + 20
		Points[#Points+1] = routines.ground.buildWP( CarrierPosMove, "Cone", 10 )
		Points[#Points+1] = routines.ground.buildWP( CarrierPosOnBoard, "Cone", 10 )
		Points[#Points+1] = routines.ground.buildWP( CarrierPosMoveAway, "Cone", 10 )
	
	end
	self:T( "Routing " .. CargoHostName )

	routines.scheduleFunction( routines.goRoute, { CargoHostName, Points}, timer.getTime() + 4 )
     
	return Valid
  
end


function CARGO_PACKAGE:OnBoarded( Client, LandingZone )
self:T()

	local OnBoarded = false
  
	if self.CargoClient and self.CargoClient:ClientGroup() then
		if routines.IsUnitInRadius( self.CargoClient:GetClientGroupDCSUnit(), self.CargoClient:ClientPosition(), 10 ) then
			
			-- Switch Cargo from self.CargoClient to Client ... Each cargo can have only one client. So assigning the new client for the cargo is enough.
			self:StatusLoaded( Client )
			
			-- All done, onboarded the Cargo to the new Client.
			OnBoarded = true
		end
	end

	return OnBoarded
end


function CARGO_PACKAGE:UnLoad( Client, TargetZoneName )
self:T()

	self:T( 'self.CargoName = ' .. self.CargoName ) 
	--self:T( 'self.CargoHostName = ' .. self.CargoHostName ) 
	
	--self.CargoSpawn:FromCarrier( Client:ClientGroup(), TargetZoneName, self.CargoHostName )
	self:StatusUnLoaded()

	return Cargo
end


CARGO_SLINGLOAD = {
	ClassName = "CARGO_SLINGLOAD"
}


function CARGO_SLINGLOAD:New( CargoType, CargoName, CargoWeight, CargoZone, CargoHostName, CargoCountryID )
	local self = BASE:Inherit( self, CARGO:New( CargoType, CargoName, CargoWeight ) )

	self:T( { CargoType, CargoName, CargoWeight, CargoZone, CargoHostName, CargoCountryID } )

	self.CargoHostName = CargoHostName

	-- Cargo will be initialized around the CargoZone position.
	self.CargoZone = CargoZone
	
	self.CargoCount = 0
	self.CargoStaticName = string.format( "%s#%03d", self.CargoName, self.CargoCount )

	-- The country ID needs to be correctly set.
	self.CargoCountryID = CargoCountryID

	CARGOS[self.CargoName] = self

	return self

end


function CARGO_SLINGLOAD:IsLandingRequired()
self:T()
	return false
end


function CARGO_SLINGLOAD:IsSlingLoad()
self:T()
	return true
end


function CARGO_SLINGLOAD:Spawn( Client )
	self:T( { self, Client } )

	local Zone = trigger.misc.getZone( self.CargoZone )

	local ZonePos = {}
	ZonePos.x = Zone.point.x + math.random( Zone.radius / 2 * -1, Zone.radius / 2 )
	ZonePos.y = Zone.point.z + math.random( Zone.radius / 2 * -1, Zone.radius / 2 )
	
	self:T( "Cargo Location = " .. ZonePos.x .. ", " .. ZonePos.y )

	--[[
	-- This does not work in 1.5.2.
	CargoStatic = StaticObject.getByName( self.CargoName )
	if CargoStatic then
		CargoStatic:destroy()
	end
	--]]
	
	CargoStatic = StaticObject.getByName( self.CargoStaticName )

	if CargoStatic and CargoStatic:isExist() then
		CargoStatic:destroy()
	end

	-- I need to make every time a new cargo due to bugs in 1.5.2.
	
		self.CargoCount = self.CargoCount + 1
		self.CargoStaticName = string.format( "%s#%03d", self.CargoName, self.CargoCount )

		local CargoTemplate = {
				["category"] = "Cargo",
				["shape_name"] = "ab-212_cargo",
				["type"] = "Cargo1",
				["x"] = ZonePos.x,
				["y"] = ZonePos.y,
				["mass"] = self.CargoWeight,
				["name"] =  self.CargoStaticName,
				["canCargo"] = true,
				["heading"] = 0,
			}
			
		coalition.addStaticObject( self.CargoCountryID, CargoTemplate )
		
--	end

	return self
end


function CARGO_SLINGLOAD:IsNear( Client, LandingZone )
self:T()

	local Near = false

	return Near
end


function CARGO_SLINGLOAD:IsInLandingZone( Client, LandingZone )
self:T()

	local Near = false

	local CargoStaticUnit = StaticObject.getByName( self.CargoName )
	if CargoStaticUnit then 
		if routines.IsStaticInZones( CargoStaticUnit, LandingZone ) then
			Near = true
		end
	end
	
	return Near
end


function CARGO_SLINGLOAD:OnBoard( Client, LandingZone, OnBoardSide )
self:T()
  
	local Valid = true
  
     
	return Valid
end


function CARGO_SLINGLOAD:OnBoarded( Client, LandingZone )
self:T()

	local OnBoarded = false
  
	local CargoStaticUnit = StaticObject.getByName( self.CargoName )
	if CargoStaticUnit then 
		if not routines.IsStaticInZones( CargoStaticUnit, LandingZone ) then
			OnBoarded = true
		end
	end

	return OnBoarded
end


function CARGO_SLINGLOAD:UnLoad( Client, TargetZoneName )
self:T()

	self:T( 'self.CargoName = ' .. self.CargoName ) 
	self:T( 'self.CargoGroupName = ' .. self.CargoGroupName ) 
	
	self:StatusUnLoaded()

	return Cargo
end
