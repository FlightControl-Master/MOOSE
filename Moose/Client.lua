--- CLIENT Classes
-- @module Client
-- @author FlightControl

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Cargo" )
Include.File( "Message" )

--- Clients are those Groups defined within the Mission Editor that have the skillset defined as "Client" or "Player".
-- These clients are defined within the Mission Orchestration Framework (MOF)

--- The CLIENT class
-- @type CLIENT
-- @extends Base#BASE
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
	_Tasks = {},
	Messages = { 
	}
}


--- Use this method to register new Clients within the MOF.
-- @param string ClientName Name of the Group as defined within the Mission Editor. The Group must have a Unit with the type Client.
-- @param string ClientBriefing Text that describes the briefing of the mission when a Player logs into the Client.
-- @return CLIENT
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
	local self = BASE:Inherit( self, BASE:New() )
	self:F( ClientName, ClientBriefing )

	self.ClientName = ClientName
	self:AddBriefing( ClientBriefing )
	self.MessageSwitch = true
	
	return self
end

--- Resets a CLIENT.
-- @param string ClientName Name of the Group as defined within the Mission Editor. The Group must have a Unit with the type Client.
function CLIENT:Reset( ClientName )
	self:F()
	self._Menus = {}
end

--- Return the DCSGroup of a Client.
-- This function is modified to deal with a couple of bugs in DCS 1.5.3
-- @return Group#Group
function CLIENT:GetDCSGroup()
  self:F3()

--  local ClientData = Group.getByName( self.ClientName )
--	if ClientData and ClientData:isExist() then
--		self:T( self.ClientName .. " : group found!" )
--		return ClientData
--	else
--		return nil
--	end

	local CoalitionsData = { AlivePlayersRed = coalition.getPlayers( coalition.side.RED ), AlivePlayersBlue = coalition.getPlayers( coalition.side.BLUE ) }
	for CoalitionId, CoalitionData in pairs( CoalitionsData ) do
		self:T3( { "CoalitionData:", CoalitionData } )
		for UnitId, UnitData in pairs( CoalitionData ) do
			self:T3( { "UnitData:", UnitData } )
			if UnitData and UnitData:isExist() then

				local ClientGroup = Group.getByName( self.ClientName )
				if ClientGroup then
					self:T3( "ClientGroup = " .. self.ClientName )
					if ClientGroup:isExist() then 
						if ClientGroup:getID() == UnitData:getGroup():getID() then
							self:T3( "Normal logic" )
							self:T3( self.ClientName .. " : group found!" )
							return ClientGroup
						end
					else
						-- Now we need to resolve the bugs in DCS 1.5 ...
						-- Consult the database for the units of the Client Group. (ClientGroup:getUnits() returns nil)
						self:T3( "Bug 1.5 logic" )
						local ClientUnits = _Database.Groups[self.ClientName].Units
						self:T3( { ClientUnits[1].name, env.getValueDictByKey(ClientUnits[1].name) } )
						for ClientUnitID, ClientUnitData in pairs( ClientUnits ) do
							self:T3( { tonumber(UnitData:getID()), ClientUnitData.unitId } )
							if tonumber(UnitData:getID()) == ClientUnitData.unitId then
								local ClientGroupTemplate = _Database.Groups[self.ClientName].Template
								self.ClientID = ClientGroupTemplate.groupId
								self.ClientGroupUnit = UnitData
								self:T3( self.ClientName .. " : group found in bug 1.5 resolvement logic!" )
								return ClientGroup
							end
						end
					end
--				else
--					error( "Client " .. self.ClientName .. " not found!" )
				end
			end
		end
	end

	-- For non player clients
	local ClientGroup = Group.getByName( self.ClientName )
	if ClientGroup then
		self:T3( "ClientGroup = " .. self.ClientName )
		if ClientGroup:isExist() then 
			self:T3( "Normal logic" )
			self:T3( self.ClientName .. " : group found!" )
			return ClientGroup
		end
	end
	
	self.ClientGroupID = nil
	self.ClientGroupUnit = nil
	
	return nil
end 


function CLIENT:GetClientGroupID()

  
  if not self.ClientGroupID then
    local ClientGroup = self:GetDCSGroup()
    if ClientGroup and ClientGroup:isExist() then
      self.ClientGroupID = ClientGroup:getID()
    else
      self.ClientGroupID = self.ClientID
    end
  end

  self:T( self.ClientGroupID )
	return self.ClientGroupID
end


function CLIENT:GetClientGroupName()

  if not self.ClientGroupName then
    local ClientGroup = self:GetDCSGroup()
    if ClientGroup and ClientGroup:isExist() then
      self.ClientGroupName = ClientGroup:getName()
    else
      self.ClientGroupName = self.ClientName
    end
  end

  self:T( self.ClientGroupName )
	return self.ClientGroupName
end

--- Returns the Unit of the @{CLIENT}.
-- @return Unit
function CLIENT:GetClientGroupUnit()
	self:F()

	local ClientGroup = self:GetDCSGroup()
	
	if ClientGroup and ClientGroup:isExist() then
		return UNIT:New( ClientGroup:getUnit(1) )
	else
		return UNIT:New( self.ClientGroupUnit )
	end
end

--- Returns the DCSUnit of the @{CLIENT}.
-- @return DCSUnit
function CLIENT:GetClientGroupDCSUnit()
	self:F2()

  local ClientGroup = self:GetDCSGroup()
  
  if ClientGroup and ClientGroup:isExist() then
    return ClientGroup:getUnit(1)
  else
    return self.ClientGroupUnit
  end
end

function CLIENT:GetUnit()
	self:F()
	
	return UNIT:New( self:GetClientGroupDCSUnit() )
end

--- Returns the Point of the @{CLIENT}.
-- @return DCSTypes#Vec2
function CLIENT:GetPointVec2()
	self:F()

  ClientGroupUnit = self:GetClientGroupDCSUnit()
  
  if ClientGroupUnit then
    if ClientGroupUnit:isExist() then
      local PointVec3 = ClientGroupUnit:getPoint() --DCSTypes#Vec3
      local PointVec2 = {} --DCSTypes#Vec2
      PointVec2.x = PointVec3.x
      PointVec2.y = PointVec3.z
      self:T( { PointVec2 } )
      return PointVec2
    end
  end
  
  return nil
end 


--- Returns the Position of the @{CLIENT}.
-- @return DCSTypes#Position
function CLIENT:ClientPosition()
	self:F()

	ClientGroupUnit = self:GetClientGroupDCSUnit()
	
	if ClientGroupUnit then
		if ClientGroupUnit:isExist() then
			return ClientGroupUnit:getPosition()
		end
	end
	
	return nil
end 

--- Returns the altitude of the @{CLIENT}.
-- @return DCSTypes#Distance
function CLIENT:GetAltitude()
	self:F()

  ClientGroupUnit = self:GetClientGroupDCSUnit()
  
  if ClientGroupUnit then
    if ClientGroupUnit:isExist() then
      local PointVec3 = ClientGroupUnit:getPoint() --DCSTypes#Vec3
      return PointVec3.y
    end
  end
  
  return nil
end 


--- Transport defines that the Client is a Transport.
-- @return CLIENT
function CLIENT:Transport()
	self:F()

	self.ClientTransport = true
	return self
end

--- AddBriefing adds a briefing to a Client when a Player joins a Mission.
-- @param string ClientBriefing is the text defining the Mission briefing.
-- @return CLIENT
function CLIENT:AddBriefing( ClientBriefing )
	self:F()
	self.ClientBriefing = ClientBriefing
	return self
end

--- IsTransport returns if a Client is a transport.
-- @return bool
function CLIENT:IsTransport()
	self:F()
	return self.ClientTransport
end

--- ShowCargo shows the @{CARGO} within the CLIENT to the Player.
-- The @{CARGO} is shown throught the MESSAGE system of DCS World.
function CLIENT:ShowCargo()
	self:F()

	local CargoMsg = ""
  
	for CargoName, Cargo in pairs( CARGOS ) do
		if self == Cargo:IsLoadedInClient() then
			CargoMsg = CargoMsg .. Cargo.CargoName .. " Type:" ..  Cargo.CargoType .. " Weight: " .. Cargo.CargoWeight .. "\n"
		end
	end
  
	if CargoMsg == "" then
		CargoMsg = "empty"
	end
  
	self:Message( CargoMsg, 15, self.ClientName .. "/Cargo", "Co-Pilot: Cargo Status", 30 )

end

--- SwitchMessages is a local function called by the DCS World Menu system to switch off messages.
function CLIENT.SwitchMessages( PrmTable )
	PrmTable[1].MessageSwitch = PrmTable[2]
end

--- Message is the key Message driver for the CLIENT class.
-- This function displays various messages to the Player logged into the CLIENT through the DCS World Messaging system.
-- @param string Message is the text describing the message.
-- @param number MessageDuration is the duration in seconds that the Message should be displayed.
-- @param string MessageId is a text identifying the Message in the MessageQueue. The Message system overwrites Messages with the same MessageId
-- @param string MessageCategory is the category of the message (the title).
-- @param number MessageInterval is the interval in seconds between the display of the Message when the CLIENT is in the air.
function CLIENT:Message( Message, MessageDuration, MessageId, MessageCategory, MessageInterval )
	self:F()

	if not self.MenuMessages then
		if self:GetClientGroupID() then
			self.MenuMessages = MENU_CLIENT:New( self, 'Messages' )
			self.MenuRouteMessageOn = MENU_CLIENT_COMMAND:New( self, 'Messages On', self.MenuMessages, CLIENT.SwitchMessages, { self, true } )
			self.MenuRouteMessageOff = MENU_CLIENT_COMMAND:New( self,'Messages Off', self.MenuMessages, CLIENT.SwitchMessages, { self, false } )
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
				self.Messages[MessageId].MessageInterval = 600
			else
				self.Messages[MessageId].MessageInterval = MessageInterval
			end
			MESSAGE:New( Message, MessageCategory, MessageDuration, MessageId ):ToClient( self )
		else
			if self:GetClientGroupDCSUnit() and not self:GetClientGroupDCSUnit():inAir() then
				if timer.getTime() - self.Messages[MessageId].MessageTime >= self.Messages[MessageId].MessageDuration + 10 then
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
