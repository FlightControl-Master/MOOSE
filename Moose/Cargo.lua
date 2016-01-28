--- CARGO Classes
-- @classmod CARGO

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Message" )

--- Clients are those Groups defined within the Mission Editor that have the skillset defined as "Client" or "Player".
-- These clients are defined within the Mission Orchestration Framework (MOF)

trace.names.all = true

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

function CARGO_ZONE:New( CargoZoneName, CargoHostGroupName )
trace.f( self.ClassName, { CargoZoneName, CargoHostGroupName } )

	local self = BASE:Inherit( self, BASE:New() )

	self.CargoZoneName = CargoZoneName
	self.CargoZone = trigger.misc.getZone( CargoZoneName )

	if CargoHostGroupName then
		self.CargoHostGroupName = CargoHostGroupName
		self.CargoHostSpawn = SPAWN:New( CargoHostGroupName )
	end
	
	return self
end

function CARGO_ZONE:Spawn()
trace.f( self.ClassName )

	if self.CargoHostSpawn then
		local CargoHostGroup = Group.getByName( self.CargoHostSpawn:SpawnGroupName() )
		if CargoHostGroup then
			if not CargoHostGroup:isExist() then
				self.CargoHostSpawn:ReSpawn( self.CargoHostSpawn:SpawnGroupName() )
			end
		else
			self.CargoHostSpawn:ReSpawn( self.CargoHostSpawn:SpawnGroupName() )
		end
	end

	return self
end

function CARGO_ZONE:Signal()
trace.f( self.ClassName )

	local Signalled = false

	if self.SignalType then
	
		if self.CargoHostGroupName then
			
			-- A Host has been given, signal the host
			local SignalUnit = Group.getByName( self.CargoHostSpawn:SpawnGroupName() )
			if SignalUnit == nil then
				SignalUnit = StaticObject.getByName( self.CargoHostGroupName )
			else
				SignalUnit = SignalUnit:getUnits()[1]
			end
			
			if SignalUnit ~= nil then
			
				trace.i( self.ClassName, 'Signalling Unit' )
				local SignalVehiclePos = SignalUnit:getPosition().p
				SignalVehiclePos.y = SignalVehiclePos.y + 10

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
			self.CargoZone.point.y = land.getHeight( CurrentPosition ) + 10
	  
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


function CARGO_ZONE:GetCargoHostGroup()
trace.f( self.ClassName )

	local CargoHost = Group.getByName( self.CargoHostSpawn:SpawnGroupName() )
	if CargoHost and CargoHost:isExist() then
		return CargoHost
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
	}
}

--- Add Cargo to the mission... Cargo functionality needs to be reworked a bit, so this is still under construction. I need to make a CARGO Class...
function CARGO:New( CargoType, CargoName, CargoWeight )
trace.f( self.ClassName, { CargoType, CargoName, CargoWeight } )

	local self = BASE:Inherit( self, BASE:New() )

	self.CargoType = CargoType
	self.CargoName = CargoName
    self.CargoWeight = CargoWeight

	self.Status = self:StatusNone()
	
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

	if self:IsStatusLoaded() then
		return self.Client
	end
	
	return nil

end

function CARGO:Load( Client )
trace.f( self.ClassName )

	Client:AddCargo( self )

	self.Client = Client
	self:StatusLoaded()

	return self
end

function CARGO:UnLoad( Client, TargetZoneName )
trace.f( self.ClassName )

	local Cargo = Client:RemoveCargo( self )
	if Cargo then
		env.info( 'STAGEUNLOAD:Executing() Cargo.CargoName = ' .. Cargo.CargoName ) 
		
		Cargo:StatusUnLoaded()
	end

	return Cargo
end

function CARGO:OnBoard( Client, LandingZone )
trace.f(self.ClassName )
  
	local Valid = true
  
	local ClientUnit = Client:ClientUnit()

	return Valid
end

function CARGO:OnBoarded( Client, LandingZone )
trace.f(self.ClassName )

	local OnBoarded = true
  
	return OnBoarded
end

function CARGO:StatusNone()
trace.f(self.ClassName )

	self.Status = CARGO.STATUS.NONE
	
	return self
end

function CARGO:StatusLoaded()
trace.f(self.ClassName )

	self.Status = CARGO.STATUS.LOADED
	
	return self
end

function CARGO:StatusUnLoaded()
trace.f(self.ClassName )

	self.Status = CARGO.STATUS.UNLOADED
	
	return self
end

function CARGO:StatusLoading()
trace.f(self.ClassName )

	self.Status = CARGO.STATUS.LOADING
	
	return self
end

function CARGO:IsStatusNone()
trace.f(self.ClassName )

	return self.Status == CARGO.STATUS.NONE
end

function CARGO:IsStatusLoaded()
trace.f(self.ClassName )

	return self.Status == CARGO.STATUS.LOADED
end

function CARGO:IsStatusUnLoaded()
trace.f(self.ClassName )

	return self.Status == CARGO.STATUS.UNLOADED
end

function CARGO:IsStatusLoading()
trace.f(self.ClassName )

	return self.Status == CARGO.STATUS.LOADING
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
	
	if self.CargoGroupName then
		local Client = self.IsLoadedInClient()
		if Client and Client:ClientGroup() then
			if Client:FindCargo( self.CargoName ) then
				SpawnCargo = false
			end
		end
	end
	
	if SpawnCargo then 
		if self.CargoZone:GetCargoHostGroup() then
			--- ReSpawn the Cargo from the CargoHost
			self.CargoGroupName = self.CargoSpawn:FromCarrier( self.CargoZone:GetCargoHostGroup(), self.CargoZone:GetCargoZoneName(), self.CargoName, false ).name
		else
			--- ReSpawn the Cargo in the CargoZone without a host ...
			self.CargoGroupName = self.CargoSpawn:InZone( self.CargoZone:GetCargoZoneName(), self.CargoName ).name

		end
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
  
	local ClientUnit = Client:ClientUnit()
	
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
     
	return Valid
  
end


function CARGO_GROUP:OnBoarded( Client, LandingZone )
trace.f(self.ClassName )

	local OnBoarded = false
  
	local CargoGroup = Group.getByName( self.CargoGroupName )
	if routines.IsPartOfGroupInRadius( CargoGroup, Client:ClientPosition(), 25 ) then
		CargoGroup:destroy()
		OnBoarded = true
	end

	return OnBoarded
end

function CARGO_GROUP:UnLoad( Client, TargetZoneName )
trace.f( self.ClassName )

	trace.i( self.ClassName, 'self.CargoName = ' .. self.CargoName ) 
	trace.i( self.ClassName, 'self.CargoGroupName = ' .. self.CargoGroupName ) 
	
	self.CargoSpawn:FromCarrier( Client:ClientGroup(), TargetZoneName, self.CargoGroupName )
	self:StatusUnLoaded()
	local Cargo = Client:RemoveCargo( self )


	return Cargo
end


CARGO_PACKAGE = {
	ClassName = "CARGO_PACKAGE"
}


function CARGO_PACKAGE:New( CargoType, CargoName, CargoWeight )
trace.f( self.ClassName, { CargoType, CargoName, CargoWeight } )

	-- Arrange meta tables
	local self = BASE:Inherit( self, CARGO:New( CargoType, CargoName, CargoWeight ) )
	
	CARGOS[self.CargoName] = self

	return self

end

function CARGO_PACKAGE:Spawn()
trace.f( self.ClassName )

	return self
end

function CARGO_PACKAGE:IsNear( Client, LandingZone )
trace.f( self.ClassName )

	local Near = false
	
	local CargoHostGroup = LandingZone:GetCargoHostGroup()
	if routines.IsPartOfGroupInRadius( CargoHostGroup, Client:ClientPosition(), 150 ) then
		Near = true
	end
	
	return Near
	
end

function CARGO_PACKAGE:OnBoard( Client, LandingZone, OnBoardSide )
trace.f(self.ClassName )
  
	local Valid = true
  
	local ClientUnit = Client:ClientUnit()
	
	local CarrierPos = ClientUnit:getPoint()
	local CarrierPosMove = ClientUnit:getPoint()
	local CarrierPosOnBoard = ClientUnit:getPoint()
	local CarrierPosMoveAway = ClientUnit:getPoint()
	
	local CargoHostGroup = LandingZone:GetCargoHostGroup()
	local CargoHostGroupName = LandingZone:GetCargoHostGroup():getName()

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
	trace.i( self.ClassName, "Routing " .. CargoHostGroupName )

	routines.scheduleFunction( routines.goRoute, { CargoHostGroupName, Points}, timer.getTime() + 4 )
     
	return Valid
  
end


function CARGO_PACKAGE:OnBoarded( Client, LandingZone )
trace.f(self.ClassName )

	local OnBoarded = false
  
	local CargoHostGroup = LandingZone:GetCargoHostGroup()
	if routines.IsPartOfGroupInRadius( CargoHostGroup, Client:ClientPosition(), 25 ) then
		--CargoGroup:destroy()
		OnBoarded = true
	end

	return OnBoarded
end

function CARGO_PACKAGE:UnLoad( Client, TargetZoneName )
trace.f( self.ClassName )

	trace.i( self.ClassName, 'self.CargoName = ' .. self.CargoName ) 
	--trace.i( self.ClassName, 'self.CargoHostName = ' .. self.CargoHostName ) 
	
	--self.CargoSpawn:FromCarrier( Client:ClientGroup(), TargetZoneName, self.CargoHostName )
	self:StatusUnLoaded()
	local Cargo = Client:RemoveCargo( self )

	return Cargo
end


--[[--
	Internal Table to understand the form of the CARGO.
	@table CARGO_TRANSPORT
--]]
CARGO_TRANSPORT = { UNIT = 1, SLING = 2, STATIC = 3, INVISIBLE = 4 }

--[[--
	CARGO_TYPE Defines the different types of transports, which has an impact on the menu commands shown in F10.
	@table CARGO_TYPE
	@field TROOPS
	@field GOODS
	@field VEHICLES
	@field INFANTRY
	@field ENGINEERS
	@field PACKAGE
	@field CARGO
--]]
CARGO_TYPE = { 
	TROOPS    = { ID = 1, TEXT = "Troops", TRANSPORT = CARGO_TRANSPORT.UNIT }, 
	GOODS     = { ID = 2, TEXT = "Goods", TRANSPORT = CARGO_TRANSPORT.STATIC }, 
	VEHICLES  = { ID = 3, TEXT = "Vehicles", TRANSPORT = CARGO_TRANSPORT.STATIC },
	INFANTRY  = { ID = 4, TEXT = "Infantry", TRANSPORT = CARGO_TRANSPORT.UNIT },
	ENGINEERS = { ID = 5, TEXT = "Engineers", TRANSPORT = CARGO_TRANSPORT.UNIT },
	PACKAGE   = { ID = 6, TEXT = "Package", TRANSPORT = CARGO_TRANSPORT.INVISIBLE },
	CARGO     = { ID = 7, TEXT = "Cargo", TRANSPORT = CARGO_TRANSPORT.STATIC },
}
