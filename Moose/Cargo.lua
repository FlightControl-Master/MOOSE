--- CARGO Classes
-- @classmod CARGO

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

function CARGO_ZONE:New( CargoZoneName, CargoHostName )
trace.f( self.ClassName, { CargoZoneName, CargoHostName } )

	local self = BASE:Inherit( self, BASE:New() )

	self.CargoZoneName = CargoZoneName
	self.CargoZone = trigger.misc.getZone( CargoZoneName )

	if CargoHostName then
		self.CargoHostName = CargoHostName
		self.CargoHostSpawn = SPAWN:New( CargoHostName )
	end
	
	return self
end

function CARGO_ZONE:Spawn()
trace.f( self.ClassName, CargoHostSpawn )

	if self.CargoHostSpawn then
		local CargoHostGroup = Group.getByName( self.CargoHostSpawn:SpawnGroupName() )
		if CargoHostGroup then
			if not CargoHostGroup:isExist() then
				self.CargoHostSpawn:ReSpawn()
			end
		else
			self.CargoHostSpawn:ReSpawn()
		end
	end

	return self
end

function CARGO_ZONE:GetHostUnit()

	if self.CargoHostName then
		
		-- A Host has been given, signal the host
		local CargoHostGroup = Group.getByName( self.CargoHostSpawn:SpawnGroupName() )
		local CargoHostUnit
		if CargoHostGroup == nil then
			CargoHostUnit = StaticObject.getByName( self.CargoHostName )
		else
			CargoHostUnit = CargoHostGroup:getUnits()[1]
		end
		
		return CargoHostUnit
	end
	
	return nil
end

function CARGO_ZONE:ReportCargosToClient( Client, CargoType )
trace.f( self.ClassName )

	local SignalUnit = self:GetHostUnit()

	if SignalUnit then
		
		local SignalUnitTypeName = SignalUnit:getTypeName()
		
		local HostMessage = ""

		local IsCargo = false
		for CargoID, Cargo in pairs( Cargos ) do
			if Cargo.CargoType == Task.CargoType then
				HostMessage = HostMessage .. "\n - " .. Cargo.CargoName
				IsCargo = true
			end
		end
		
		if not IsCargo then
			HostMessage = HostMessage .. "No Cargo Available."
		end

		Client:Message( RouteMessage, self.MSG.TIME, Mission.Name .. "/StageHosts." .. SignalUnitTypeName, SignalUnitTypeName .. ": Reporting Cargo", 10 )
	end
end

function CARGO_ZONE:Signal()
trace.f( self.ClassName )

	local Signalled = false

	if self.SignalType then
	
		if self.CargoHostName then
			
			-- A Host has been given, signal the host
			
			local SignalUnit = self:GetHostUnit()
			
			if SignalUnit then
			
				trace.i( self.ClassName, 'Signalling Unit' )
				local SignalVehiclePos = SignalUnit:getPosition().p
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
trace.f( self.ClassName )

	self.SignalType = CARGO_ZONE.SIGNAL.TYPE.SMOKE
	self.SignalColor = CARGO_ZONE.SIGNAL.COLOR.WHITE

	return self
end

function CARGO_ZONE:BlueSmoke()
trace.f( self.ClassName )

	self.SignalType = CARGO_ZONE.SIGNAL.TYPE.SMOKE
	self.SignalColor = CARGO_ZONE.SIGNAL.COLOR.BLUE

	return self
end

function CARGO_ZONE:RedSmoke()
trace.f( self.ClassName )

	self.SignalType = CARGO_ZONE.SIGNAL.TYPE.SMOKE
	self.SignalColor = CARGO_ZONE.SIGNAL.COLOR.RED

	return self
end

function CARGO_ZONE:OrangeSmoke()
trace.f( self.ClassName )

	self.SignalType = CARGO_ZONE.SIGNAL.TYPE.SMOKE
	self.SignalColor = CARGO_ZONE.SIGNAL.COLOR.ORANGE

	return self
end

function CARGO_ZONE:GreenSmoke()
trace.f( self.ClassName )

	self.SignalType = CARGO_ZONE.SIGNAL.TYPE.SMOKE
	self.SignalColor = CARGO_ZONE.SIGNAL.COLOR.GREEN

	return self
end


function CARGO_ZONE:WhiteFlare()
trace.f( self.ClassName )

	self.SignalType = CARGO_ZONE.SIGNAL.TYPE.FLARE
	self.SignalColor = CARGO_ZONE.SIGNAL.COLOR.WHITE

	return self
end

function CARGO_ZONE:RedFlare()
trace.f( self.ClassName )

	self.SignalType = CARGO_ZONE.SIGNAL.TYPE.FLARE
	self.SignalColor = CARGO_ZONE.SIGNAL.COLOR.RED

	return self
end

function CARGO_ZONE:GreenFlare()
trace.f( self.ClassName )

	self.SignalType = CARGO_ZONE.SIGNAL.TYPE.FLARE
	self.SignalColor = CARGO_ZONE.SIGNAL.COLOR.GREEN

	return self
end

function CARGO_ZONE:YellowFlare()
trace.f( self.ClassName )

	self.SignalType = CARGO_ZONE.SIGNAL.TYPE.FLARE
	self.SignalColor = CARGO_ZONE.SIGNAL.COLOR.YELLOW

	return self
end


function CARGO_ZONE:GetCargoHostUnit()
trace.f( self.ClassName )

	local CargoHostUnit = Group.getByName( self.CargoHostSpawn:SpawnGroupName() ):getUnit(1)
	if CargoHostUnit and CargoHostUnit:isExist() then
		return CargoHostUnit
	end

	return nil
end

function CARGO_ZONE:GetCargoZoneName()
trace.f( self.ClassName )

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
function CARGO:New( CargoType, CargoName, CargoWeight )
trace.f( self.ClassName, { CargoType, CargoName, CargoWeight } )

	local self = BASE:Inherit( self, BASE:New() )

	self.CargoType = CargoType
	self.CargoName = CargoName
    self.CargoWeight = CargoWeight

	self:StatusNone()
	
	return self
end

function CARGO:Spawn()
trace.f( self.ClassName )

	return self

end

function CARGO:IsNear( Client, LandingZone )
trace.f( self.ClassName )

	local Near = true
	
	return Near
	
end

function CARGO:IsLoadedInClient()
trace.f( self.ClassName )

	if self:IsStatusLoaded() or self:IsStatusLoading() then
		return self.CargoClient
	end
	
	return nil

end


function CARGO:UnLoad( Client, TargetZoneName )
trace.f( self.ClassName )

	self:StatusUnLoaded()

	return self
end

function CARGO:OnBoard( Client, LandingZone )
trace.f(self.ClassName )
  
	local Valid = true
  
	self.CargoClient = Client
	local ClientUnit = Client:GetClientGroupUnit()

	return Valid
end

function CARGO:OnBoarded( Client, LandingZone )
trace.f(self.ClassName )

	local OnBoarded = true
  
	return OnBoarded
end

function CARGO:Load( Client )
trace.f( self.ClassName )

	self:StatusLoaded( Client )

	return self
end

function CARGO:IsLandingRequired()
trace.f( self.ClassName )
	return true
end

function CARGO:IsSlingLoad()
trace.f( self.ClassName )
	return false
end


function CARGO:StatusNone()
trace.f(self.ClassName )

	self.CargoClient = nil
	self.CargoStatus = CARGO.STATUS.NONE
	
	return self
end

function CARGO:StatusLoading( Client )
trace.f(self.ClassName )

	self.CargoClient = Client
	self.CargoStatus = CARGO.STATUS.LOADING
	
	return self
end

function CARGO:StatusLoaded( Client )
trace.f(self.ClassName )

	self.CargoClient = Client
	self.CargoStatus = CARGO.STATUS.LOADED
	
	return self
end

function CARGO:StatusUnLoaded()
trace.f(self.ClassName )

	self.CargoClient = nil
	self.CargoStatus = CARGO.STATUS.UNLOADED
	
	return self
end


function CARGO:IsStatusNone()
trace.f(self.ClassName )

	return self.CargoStatus == CARGO.STATUS.NONE
end

function CARGO:IsStatusLoading()
trace.f(self.ClassName )

	return self.CargoStatus == CARGO.STATUS.LOADING
end

function CARGO:IsStatusLoaded()
trace.f(self.ClassName )

	return self.CargoStatus == CARGO.STATUS.LOADED
end

function CARGO:IsStatusUnLoaded()
trace.f(self.ClassName )

	return self.CargoStatus == CARGO.STATUS.UNLOADED
end


CARGO_GROUP = {
	ClassName = "CARGO_GROUP"
}


function CARGO_GROUP:New( CargoType, CargoName, CargoWeight, CargoGroupTemplate, CargoZone )
trace.f( self.ClassName, { CargoType, CargoName, CargoWeight, CargoGroupTemplate, CargoZone } )

	-- Arrange meta tables
	local self = BASE:Inherit( self, CARGO:New( CargoType, CargoName, CargoWeight ) )
	
	self.CargoSpawn = SPAWN:New( CargoGroupTemplate )
	self.CargoZone = CargoZone

	CARGOS[self.CargoName] = self

	return self

end

function CARGO_GROUP:Spawn()
trace.f( self.ClassName )

	local SpawnCargo = true
	
	if self:IsStatusNone() then
	
	elseif self:IsStatusLoaded() or self:IsStatusLoading() then
	
		local Client = self:IsLoadedInClient()
		if Client and Client:ClientGroup() then
			SpawnCargo = false
		end
		
	elseif self:IsStatusUnLoaded() then
	
		SpawnCargo = false
		
	end
	
	if SpawnCargo then 
		if self.CargoZone:GetCargoHostUnit() then
			--- ReSpawn the Cargo from the CargoHost
			self.CargoGroupName = self.CargoSpawn:FromHost( self.CargoZone:GetCargoHostUnit(), 60, 30, self.CargoName, false ).name
		else
			--- ReSpawn the Cargo in the CargoZone without a host ...
			self.CargoGroupName = self.CargoSpawn:InZone( self.CargoZone:GetCargoZoneName(), self.CargoName ).name
		end
		self:StatusNone()	
	end
	
	trace.i( self.ClassName, { self.CargoGroupName, CARGOS[self.CargoName].CargoGroupName } )

	return self
end

function CARGO_GROUP:IsNear( Client, LandingZone )
trace.f( self.ClassName )

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
trace.f(self.ClassName )
  
	local Valid = true
  
	local ClientUnit = Client:GetClientGroupUnit()
	
	local CarrierPos = ClientUnit:getPoint()
	local CarrierPosMove = ClientUnit:getPoint()
	local CarrierPosOnBoard = ClientUnit:getPoint()
	
	local CargoGroup = Group.getByName( self.CargoGroupName )

	local CargoUnits = CargoGroup:getUnits()
	local CargoPos = CargoUnits[1]:getPoint()

	
	local Points = {}
	
	trace.i( self.ClassName, 'CargoPos x = ' .. CargoPos.x .. " z = " .. CargoPos.z )
	trace.i( self.ClassName, 'CarrierPosMove x = ' .. CarrierPosMove.x .. " z = " .. CarrierPosMove.z )
	
	Points[#Points+1] = routines.ground.buildWP( CargoPos, "Cone", 10 )

	trace.i( self.ClassName, 'Points[1] x = ' .. Points[1].x .. " y = " .. Points[1].y )
	
	if OnBoardSide == nil then
		OnBoardSide = CLIENT.ONBOARDSIDE.NONE
	end
	
	if OnBoardSide == CLIENT.ONBOARDSIDE.LEFT then
	
		trace.i( self.ClassName, "TransportCargoOnBoard: Onboarding LEFT" )
		CarrierPosMove.z = CarrierPosMove.z - 25
		CarrierPosOnBoard.z = CarrierPosOnBoard.z - 5
		Points[#Points+1] = routines.ground.buildWP( CarrierPosMove, "Cone", 10 )
		Points[#Points+1] = routines.ground.buildWP( CarrierPosOnBoard, "Cone", 10 )
	
	elseif  OnBoardSide == CLIENT.ONBOARDSIDE.RIGHT then
		
		trace.i( self.ClassName, "TransportCargoOnBoard: Onboarding RIGHT" )
		CarrierPosMove.z = CarrierPosMove.z + 25
		CarrierPosOnBoard.z = CarrierPosOnBoard.z + 5
		Points[#Points+1] = routines.ground.buildWP( CarrierPosMove, "Cone", 10 )
		Points[#Points+1] = routines.ground.buildWP( CarrierPosOnBoard, "Cone", 10 )
	
	elseif  OnBoardSide == CLIENT.ONBOARDSIDE.BACK then
		
		trace.i( self.ClassName, "TransportCargoOnBoard: Onboarding BACK" )
		CarrierPosMove.x = CarrierPosMove.x - 25
		CarrierPosOnBoard.x = CarrierPosOnBoard.x - 5
		Points[#Points+1] = routines.ground.buildWP( CarrierPosMove, "Cone", 10 )
		Points[#Points+1] = routines.ground.buildWP( CarrierPosOnBoard, "Cone", 10 )
	
	elseif  OnBoardSide == CLIENT.ONBOARDSIDE.FRONT then
		
		trace.i( self.ClassName, "TransportCargoOnBoard: Onboarding FRONT" )
		CarrierPosMove.x = CarrierPosMove.x + 25
		CarrierPosOnBoard.x = CarrierPosOnBoard.x + 5
		Points[#Points+1] = routines.ground.buildWP( CarrierPosMove, "Cone", 10 )
		Points[#Points+1] = routines.ground.buildWP( CarrierPosOnBoard, "Cone", 10 )
	
	elseif  OnBoardSide == CLIENT.ONBOARDSIDE.NONE then
		
		trace.i( self.ClassName, "TransportCargoOnBoard: Onboarding CENTRAL" )
		Points[#Points+1] = routines.ground.buildWP( CarrierPos, "Cone", 10 )
	
	end
	trace.i( self.ClassName, "TransportCargoOnBoard: Routing " .. self.CargoGroupName )

	routines.scheduleFunction( routines.goRoute, { self.CargoGroupName, Points}, timer.getTime() + 4 )
	
	self:StatusLoading( Client )
     
	return Valid
  
end


function CARGO_GROUP:OnBoarded( Client, LandingZone )
trace.f(self.ClassName )

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
trace.f( self.ClassName )

	trace.i( self.ClassName, 'self.CargoName = ' .. self.CargoName ) 
	trace.i( self.ClassName, 'self.CargoGroupName = ' .. self.CargoGroupName ) 
	
	self.CargoSpawn:FromCarrier( Client:GetClientGroupUnit(), TargetZoneName, self.CargoGroupName )

	self:StatusUnLoaded()

	return self
end


CARGO_PACKAGE = {
	ClassName = "CARGO_PACKAGE"
}


function CARGO_PACKAGE:New( CargoType, CargoName, CargoWeight, CargoClientInitGroupName )
trace.f( self.ClassName, { CargoType, CargoName, CargoWeight, CargoClientInitGroupName } )

	-- Arrange meta tables
	local self = BASE:Inherit( self, CARGO:New( CargoType, CargoName, CargoWeight ) )
	
	self.CargoClientInitGroupName = CargoClientInitGroupName
	
	self.CargoClient = CLIENT:New( self.CargoClientInitGroupName )
	self:StatusLoaded( self.CargoClient )
	
	self.CargoClientInitGroupSpawn = SPAWN:New( self.CargoClientInitGroupName )
	
	CARGOS[self.CargoName] = self

	return self

end

function CARGO_PACKAGE:Spawn()
trace.f( self.ClassName )

	-- this needs to be checked thoroughly

	local SpawnCargo = true
	
	trace.i( self.ClassName, self.CargoClientInitGroupName )

	if self:IsStatusNone() then
	
	elseif self:IsStatusLoading() or self:IsStatusLoaded() then

		local Client = self:IsLoadedInClient()
		if Client and Client:ClientGroup() then
			SpawnCargo = false
		end
	
	elseif self:IsStatusUnLoaded() then
	
		SpawnCargo = false
	
	else

	end

	if SpawnCargo then
		self.CargoClient = CLIENT:New( self.CargoClientInitGroupName )
		self:StatusLoaded( self.CargoClient )
	end
		
	local CargoClientInitGroup = Group.getByName( self.CargoClientInitGroupName )
	if CargoClientInitGroup then
		self.CargoClientInitGroupSpawn:Spawn( self.CargoClientInitGroupName )	
	end
	
	return self
end

function CARGO_PACKAGE:IsNear( Client, LandingZone )
trace.f( self.ClassName )

	local Near = false

	if self.CargoClient and self.CargoClient:ClientGroup() then
		trace.i( self.ClassName, self.CargoClient.ClientName )
		trace.i( self.ClassName, 'Client Exists.' )

		if routines.IsUnitInRadius( self.CargoClient:GetClientGroupUnit(), Client:ClientPosition(), 150 ) then
			Near = true
		end
	end
	
	return Near
	
end

function CARGO_PACKAGE:OnBoard( Client, LandingZone, OnBoardSide )
trace.f(self.ClassName )
  
	local Valid = true
  
	local ClientUnit = Client:GetClientGroupUnit()
	
	local CarrierPos = ClientUnit:getPoint()
	local CarrierPosMove = ClientUnit:getPoint()
	local CarrierPosOnBoard = ClientUnit:getPoint()
	local CarrierPosMoveAway = ClientUnit:getPoint()
	
	local CargoHostGroup = self.CargoClient:ClientGroup()
	local CargoHostName = self.CargoClient:ClientGroup():getName()

	local CargoHostUnits = CargoHostGroup:getUnits()
	local CargoPos = CargoHostUnits[1]:getPoint()

	local Points = {}
	
	trace.i( self.ClassName, 'CargoPos x = ' .. CargoPos.x .. " z = " .. CargoPos.z )
	trace.i( self.ClassName, 'CarrierPosMove x = ' .. CarrierPosMove.x .. " z = " .. CarrierPosMove.z )
	
	Points[#Points+1] = routines.ground.buildWP( CargoPos, "Cone", 10 )

	trace.i( self.ClassName, 'Points[1] x = ' .. Points[1].x .. " y = " .. Points[1].y )
	
	if OnBoardSide == nil then
		OnBoardSide = CLIENT.ONBOARDSIDE.NONE
	end
	
	if OnBoardSide == CLIENT.ONBOARDSIDE.LEFT then
	
		trace.i( self.ClassName, "TransportCargoOnBoard: Onboarding LEFT" )
		CarrierPosMove.z = CarrierPosMove.z - 25
		CarrierPosOnBoard.z = CarrierPosOnBoard.z - 5
		CarrierPosMoveAway.z = CarrierPosMoveAway.z - 20
		Points[#Points+1] = routines.ground.buildWP( CarrierPosMove, "Cone", 10 )
		Points[#Points+1] = routines.ground.buildWP( CarrierPosOnBoard, "Cone", 10 )
		Points[#Points+1] = routines.ground.buildWP( CarrierPosMoveAway, "Cone", 10 )
	
	elseif  OnBoardSide == CLIENT.ONBOARDSIDE.RIGHT then
		
		trace.i( self.ClassName, "TransportCargoOnBoard: Onboarding RIGHT" )
		CarrierPosMove.z = CarrierPosMove.z + 25
		CarrierPosOnBoard.z = CarrierPosOnBoard.z + 5
		CarrierPosMoveAway.z = CarrierPosMoveAway.z + 20
		Points[#Points+1] = routines.ground.buildWP( CarrierPosMove, "Cone", 10 )
		Points[#Points+1] = routines.ground.buildWP( CarrierPosOnBoard, "Cone", 10 )
		Points[#Points+1] = routines.ground.buildWP( CarrierPosMoveAway, "Cone", 10 )	
	
	elseif  OnBoardSide == CLIENT.ONBOARDSIDE.BACK then
		
		trace.i( self.ClassName, "TransportCargoOnBoard: Onboarding BACK" )
		CarrierPosMove.x = CarrierPosMove.x - 25
		CarrierPosOnBoard.x = CarrierPosOnBoard.x - 5
		CarrierPosMoveAway.x = CarrierPosMoveAway.x - 20
		Points[#Points+1] = routines.ground.buildWP( CarrierPosMove, "Cone", 10 )
		Points[#Points+1] = routines.ground.buildWP( CarrierPosOnBoard, "Cone", 10 )
		Points[#Points+1] = routines.ground.buildWP( CarrierPosMoveAway, "Cone", 10 )

	elseif  OnBoardSide == CLIENT.ONBOARDSIDE.FRONT then
		
		trace.i( self.ClassName, "TransportCargoOnBoard: Onboarding FRONT" )
		CarrierPosMove.x = CarrierPosMove.x + 25
		CarrierPosOnBoard.x = CarrierPosOnBoard.x + 5
		CarrierPosMoveAway.x = CarrierPosMoveAway.x + 20
		Points[#Points+1] = routines.ground.buildWP( CarrierPosMove, "Cone", 10 )
		Points[#Points+1] = routines.ground.buildWP( CarrierPosOnBoard, "Cone", 10 )
		Points[#Points+1] = routines.ground.buildWP( CarrierPosMoveAway, "Cone", 10 )

	elseif  OnBoardSide == CLIENT.ONBOARDSIDE.NONE then
		
		trace.i( self.ClassName, "TransportCargoOnBoard: Onboarding FRONT" )
		CarrierPosMove.x = CarrierPosMove.x + 25
		CarrierPosOnBoard.x = CarrierPosOnBoard.x + 5
		CarrierPosMoveAway.x = CarrierPosMoveAway.x + 20
		Points[#Points+1] = routines.ground.buildWP( CarrierPosMove, "Cone", 10 )
		Points[#Points+1] = routines.ground.buildWP( CarrierPosOnBoard, "Cone", 10 )
		Points[#Points+1] = routines.ground.buildWP( CarrierPosMoveAway, "Cone", 10 )
	
	end
	trace.i( self.ClassName, "Routing " .. CargoHostName )

	routines.scheduleFunction( routines.goRoute, { CargoHostName, Points}, timer.getTime() + 4 )
     
	return Valid
  
end


function CARGO_PACKAGE:OnBoarded( Client, LandingZone )
trace.f(self.ClassName )

	local OnBoarded = false
  
	if self.CargoClient and self.CargoClient:ClientGroup() then
		if routines.IsUnitInRadius( self.CargoClient:GetClientGroupUnit(), self.CargoClient:ClientPosition(), 10 ) then
			
			-- Switch Cargo from self.CargoClient to Client ... Each cargo can have only one client. So assigning the new client for the cargo is enough.
			self:StatusLoaded( Client )
			
			-- All done, onboarded the Cargo to the new Client.
			OnBoarded = true
		end
	end

	return OnBoarded
end

function CARGO_PACKAGE:UnLoad( Client, TargetZoneName )
trace.f( self.ClassName )

	trace.i( self.ClassName, 'self.CargoName = ' .. self.CargoName ) 
	--trace.i( self.ClassName, 'self.CargoHostName = ' .. self.CargoHostName ) 
	
	--self.CargoSpawn:FromCarrier( Client:ClientGroup(), TargetZoneName, self.CargoHostName )
	self:StatusUnLoaded()

	return Cargo
end


CARGO_SLINGLOAD = {
	ClassName = "CARGO_SLINGLOAD"
}


function CARGO_SLINGLOAD:New( CargoType, CargoName, CargoWeight, CargoZone, CargoHostName, CargoCountryID )
trace.f( self.ClassName, { CargoType, CargoName, CargoWeight, CargoZone, CargoHostName, CargoCountryID } )

	-- Arrange meta tables
	local self = BASE:Inherit( self, CARGO:New( CargoType, CargoName, CargoWeight ) )

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
trace.f( self.ClassName )
	return false
end

function CARGO_SLINGLOAD:IsSlingLoad()
trace.f( self.ClassName )
	return true
end


function CARGO_SLINGLOAD:Spawn()
trace.f( self.ClassName )

	local Zone = trigger.misc.getZone( self.CargoZone )

	local ZonePos = {}
	ZonePos.x = Zone.point.x + math.random( Zone.radius / 2 * -1, Zone.radius / 2 )
	ZonePos.y = Zone.point.z + math.random( Zone.radius / 2 * -1, Zone.radius / 2 )
	
	trace.i( self.ClassName, "Cargo Location = " .. ZonePos.x .. ", " .. ZonePos.y )

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

function CARGO_SLINGLOAD:IsInLandingZone( Client, LandingZone )
trace.f( self.ClassName )

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
trace.f(self.ClassName )
  
	local Valid = true
  
     
	return Valid
  
end


function CARGO_SLINGLOAD:OnBoarded( Client, LandingZone )
trace.f(self.ClassName )

	local OnBoarded = false
  
	local CargoStaticUnit = StaticObject.getByName( self.CargoName )
	if CargoStaticUnit then 
		if not routines.IsStaticInZones( CargoStaticUnit, LandingZone ) then
			Onboarded = true
		end
	end

	return OnBoarded
end

function CARGO_SLINGLOAD:UnLoad( Client, TargetZoneName )
trace.f( self.ClassName )

	trace.i( self.ClassName, 'self.CargoName = ' .. self.CargoName ) 
	trace.i( self.ClassName, 'self.CargoGroupName = ' .. self.CargoGroupName ) 
	
	self:StatusUnLoaded()

	return Cargo
end

--[[--
	Internal Table to understand the form of the CARGO.
	@table CARGO_TRANSPORT
--]]
CARGO_TRANSPORT = { UNIT = 1, SLING = 2, STATIC = 3, INVISIBLE = 4 }

