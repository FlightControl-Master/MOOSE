--- CLIENT Classes
-- @classmod CLIENT

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Cargo" )
Include.File( "Message" )

--- Clients are those Groups defined within the Mission Editor that have the skillset defined as "Client" or "Player".
-- These clients are defined within the Mission Orchestration Framework (MOF)

CLIENT = {
	ONBOARDSIDE = {
		NONE = 0,
		LEFT = 1,
		RIGHT = 2,
		BACK = 3,
		FRONT = 4
	},
	ClassName = "CLIENT",
	ClientName = nil,
	ClientAlive = false,
	ClientTransport = false,
	ClientBriefingShown = false,
	_Menus = {},
	_Cargos = {},
	_Tasks = {},
	Messages = { 
	}
}


--- Use this method to register new Clients within the MOF.
-- @tparam string ClientName Name of the Group as defined within the Mission Editor. The Group must have a Unit with the type Client.
-- @tparam string ClientBriefing Text that describes the briefing of the mission when a Player logs into the Client.
-- @treturn CLIENT
-- @usage
-- -- Create new Clients.
--	local Mission = MISSIONSCHEDULER.AddMission( 'Russia Transport Troops SA-6', 'Operational', 'Transport troops from the control center to one of the SA-6 SAM sites to activate their operation.', 'Russia' )
--	Mission:AddGoal( DeploySA6TroopsGoal )
--
--	Mission:AddClient( CLIENT:New( 'RU MI-8MTV2*HOT-Deploy Troops 1' ):Transport() )
--	Mission:AddClient( CLIENT:New( 'RU MI-8MTV2*RAMP-Deploy Troops 3' ):Transport() )
--	Mission:AddClient( CLIENT:New( 'RU MI-8MTV2*HOT-Deploy Troops 2' ):Transport() )
--	Mission:AddClient( CLIENT:New( 'RU MI-8MTV2*RAMP-Deploy Troops 4' ):Transport() )

function CLIENT:New( ClientName, ClientBriefing )
trace.f(self.ClassName)

	-- Arrange meta tables
	local self = BASE:Inherit( self, BASE:New() )
	self.ClientName = ClientName
	self:AddBriefing( ClientBriefing )
	self.MessageSwitch = true
	
	return self
end

--- Resets a CLIENT.
-- @tparam string ClientName Name of the Group as defined within the Mission Editor. The Group must have a Unit with the type Client.
function CLIENT:Reset( ClientName )
trace.f(self.ClassName)
	self._Menus = {}
	self._Cargos = {}
end

--- ClientGroup returns the Group of a Client.
-- @treturn Group
function CLIENT:ClientGroup()
--trace.f(self.ClassName)
	local ReturnGroup = Group.getByName( self.ClientName )
	if ReturnGroup and ReturnGroup:isExist() then
		return ReturnGroup
	else
		return nil
	end
end 

--- Transport defines that the Client is a Transport.
-- @treturn CLIENT
function CLIENT:Transport()
trace.f(self.ClassName)

	self.ClientTransport = true
	return self
end

--- AddBriefing adds a briefing to a Client when a Player joins a Mission.
-- @tparam string ClientBriefing is the text defining the Mission briefing.
-- @treturn CLIENT
function CLIENT:AddBriefing( ClientBriefing )
trace.f(self.ClassName)
	self.ClientBriefing = ClientBriefing
	return self
end

--- IsTransport returns if a Client is a transport.
-- @treturn bool
function CLIENT:IsTransport()
trace.f(self.ClassName)
	return self.ClientTransport
end

--- FindCargo finds loaded Cargo within a CLIENT instance.
-- Cargo is loaded when certain PICK-UP or DEPLOY Tasks are properly executed.
-- @tparam string CargoName is the name of the cargo.
-- @treturn CARGO_TYPE
function CLIENT:FindCargo( CargoName )
trace.f(self.ClassName)
	return self._Cargos[CargoName]
end

--- ShowCargo shows the @{CARGO} within the CLIENT to the Player.
-- The @{CARGO} is shown throught the MESSAGE system of DCS World.
function CLIENT:ShowCargo()
trace.f(self.ClassName)

  local CargoMsg = ""
  
  for CargoName, Cargo in pairs( self._Cargos ) do
    if CargoMsg  ~= "" then
      CargoMsg = CargoMsg .. "\n"
    end
    CargoMsg = CargoMsg .. Cargo.CargoName .. " Type:" ..  Cargo.CargoType.TEXT .. " Weight: " .. Cargo.CargoWeight
  end
  
  if CargoMsg == '' then
	CargoMsg = "empty"
  end
  
  self:Message( CargoMsg, 15, self.ClientName .. "/Cargo", "Co-Pilot: Cargo Status", 30 )

end

--- AddCargo allows to add @{CARGO} on the CLIENT.
-- @tparam string CargoName is the name of the @{CARGO}.
-- @tparam string CargoGroupName is the name of an active Group defined within the Mission Editor or Dynamically Spawned. Note that this is only applicable for Unit @{CARGO} Types.
-- @tparam CARGO_TYPE CargoType is the Type of the @{CARGO}.
-- @tparam number CargoWeight is the weight of the cargo in Kg.
-- @tparam string CargoGroupTemplate is the name of an active Group defined within the Mission Editor with "Late Activation".
-- @treturn CLIENT
function CLIENT:AddCargo( CargoName, CargoGroupName, CargoType, CargoWeight, CargoGroupTemplate )
trace.f(self.ClassName, { CargoName, CargoGroupName, CargoType, CargoWeight, CargoGroupTemplate } )

  local Valid = true
  
  Valid = routines.ValidateString( CargoName, "CargoName", Valid )
  Valid = routines.ValidateEnumeration( CargoType, "CargoType", CARGO_TYPE, Valid )
  Valid = routines.ValidateNumber( CargoWeight, "CargoWeight", Valid )

  if  Valid then
    local Cargo = {}
    Cargo.CargoName = CargoName
    Cargo.CargoGroupName = CargoGroupName
    Cargo.CargoType = CargoType
    Cargo.CargoWeight = CargoWeight
	Cargo.CargoGroupTemplate = CargoGroupTemplate
    self._Cargos[CargoName] = Cargo
    self:ShowCargo()
  end
  
  return self
  
end

--- RemoveCargo removes @{CARGO} from the CLIENT.
-- @tparam string CargoName is the name of the @{CARGO}.
-- @treturn Cargo
function CLIENT:RemoveCargo( CargoName )
trace.f(self.ClassName, { CargoName } )


  local Valid = true
  local Cargo = nil
  
  Valid = routines.ValidateString( CargoName, "CargoName", Valid )

  if  Valid then
    trace.i( "CLIENT", "RemoveCargo: CargoName = " .. CargoName )
    Cargo = routines.utils.deepCopy( self._Cargos[CargoName] )
    self._Cargos[CargoName] = nil
  end
  
  return Cargo
  
end

--- SwitchMessages is a local function called by the DCS World Menu system to switch off messages.
function CLIENT.SwitchMessages( PrmTable )
	PrmTable[1].MessageSwitch = PrmTable[2]
end

--- Message is the key Message driver for the CLIENT class.
-- This function displays various messages to the Player logged into the CLIENT through the DCS World Messaging system.
-- @tparam string Message is the text describing the message.
-- @tparam number MessageDuration is the duration in seconds that the Message should be displayed.
-- @tparam string MessageId is a text identifying the Message in the MessageQueue. The Message system overwrites Messages with the same MessageId
-- @tparam string MessageCategory is the category of the message (the title).
-- @tparam number MessageInterval is the interval in seconds between the display of the Message when the CLIENT is in the air.
function CLIENT:Message( Message, MessageDuration, MessageId, MessageCategory, MessageInterval )
trace.f( self.ClassName, { Message, MessageDuration, MessageId, MessageCategory, MessageInterval } )

	if not self.MenuMessages then
		if self:ClientGroup() and self:ClientGroup():getID() then
			self.MenuMessages = MENU_SUB_GROUP:New( self:ClientGroup():getID(), 'Messages' )
			self.MenuRouteMessageOn = MENU_COMMAND_GROUP:New( self:ClientGroup():getID(), 'Messages On', self.MenuMessages, CLIENT.SwitchMessages, { self, true } )
			self.MenuRouteMessageOff = MENU_COMMAND_GROUP:New( self:ClientGroup():getID(),'Messages Off', self.MenuMessages, CLIENT.SwitchMessages, { self, false } )
		end
	end

	if self.MessageSwitch == true then
		if MessageCategory == nil then
			MessageCategory = "Messages"
		end
		if self.Messages[MessageId] == nil then
			self.Messages[MessageId] = {}
			self.Messages[MessageId].MessageId = MessageId
			self.Messages[MessageId].MessageTime = timer.getTime()
			self.Messages[MessageId].MessageDuration = MessageDuration
			if MessageInterval == nil then
				self.Messages[MessageId].MessageInterval = 300
			else
				self.Messages[MessageId].MessageInterval = MessageInterval
			end
			MESSAGE:New( Message, MessageCategory, MessageDuration, MessageId ):ToClient( self )
		else
			if self:ClientGroup() and self:ClientGroup():getUnits() and self:ClientGroup():getUnits()[1] and not self:ClientGroup():getUnits()[1]:inAir() then
				if timer.getTime() - self.Messages[MessageId].MessageTime  >= self.Messages[MessageId].MessageDuration - 1 then
					MESSAGE:New( Message, MessageCategory, MessageDuration, MessageId ):ToClient( self )
					self.Messages[MessageId].MessageTime = timer.getTime()
				end
			else
				if timer.getTime() - self.Messages[MessageId].MessageTime  >= self.Messages[MessageId].MessageDuration + self.Messages[MessageId].MessageInterval then
					MESSAGE:New( Message, MessageCategory, MessageDuration, MessageId ):ToClient( self )
					self.Messages[MessageId].MessageTime = timer.getTime()
				end
			end
		end
	end
end
