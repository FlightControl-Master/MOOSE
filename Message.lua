--- Message System to display Messages for Clients and Coalitions or All.
-- Messages are grouped on the display panel per Category to improve readability for the players.
-- Messages are shown on the display panel for an amount of seconds, and will then disappear.
-- Messages are identified by an ID. The messages with the same ID belonging to the same category will be overwritten if they were still being displayed on the display panel.
-- Messages are created with MESSAGE:@{New}().
-- Messages are sent to Clients with MESSAGE:@{ToClient}().
-- Messages are sent to Coalitions with MESSAGE:@{ToCoalition}().
-- Messages are sent to All Players with MESSAGE:@{ToAll}().
-- @classmod MESSAGE

Include.File( "Trace" )
Include.File( "Base" )


MESSAGE = {
	ClassName = "MESSAGE", 
	MessageCategory = 0,
	MessageID = 0,
}


--- Creates a new MESSAGE object. Note that these MESSAGE objects are not yet displayed on the display panel. You must use the functions @{ToClient} or @{ToCoalition} or @{ToAll} to send these Messages to the respective recipients.
-- @tparam string MessageText is the text of the Message.
-- @tparam string MessageCategory is a string expressing the Category of the Message. Messages are grouped on the display panel per Category to improve readability.
-- @tparam number MessageDuration is a number in seconds of how long the MESSAGE should be shown on the display panel.
-- @tparam string MessageID is a string expressing the ID of the Message.
-- @treturn MESSAGE
-- @usage
-- -- Create a series of new Messages.
-- -- MessageAll is meant to be sent to all players, for 25 seconds, and is classified as "Score".
-- -- MessageRED is meant to be sent to the RED players only, for 10 seconds, and is classified as "End of Mission", with ID "Win".
-- -- MessageClient1 is meant to be sent to a Client, for 25 seconds, and is classified as "Score", with ID "Score".
-- -- MessageClient1 is meant to be sent to a Client, for 25 seconds, and is classified as "Score", with ID "Score".
-- MessageAll = MESSAGE:New( "To all Players: BLUE has won! Each player of BLUE wins 50 points!", "End of Mission", 25, "Win" )
-- MessageRED = MESSAGE:New( "To the RED Players: You receive a penalty because you've killed one of your own units", "Penalty", 25, "Score" )
-- MessageClient1 = MESSAGE:New( "Congratulations, you've just hit a target", "Score", 25, "Score" )
-- MessageClient2 = MESSAGE:New( "Congratulations, you've just killed a target", "Score", 25, "Score" )
function MESSAGE:New( MessageText, MessageCategory, MessageDuration, MessageID )
trace.f(self.ClassName, { MessageText, MessageCategory, MessageDuration, MessageID } )

	local self = BASE:Inherit( self, BASE:New() )
	
	self.MessageCategory = MessageCategory
	self.MessageDuration = MessageDuration
	self.MessageID = MessageID
	self.MessageTime = timer.getTime()
	self.MessageText = MessageText
	
	self.MessageSent = false
	self.MessageGroup = false
	self.MessageCoalition = false

	return self
end

--- Sends a MESSAGE to a Client Group. Note that the Group needs to be defined within the ME with the skillset "Client" or "Player".
-- @tparam CLIENT Client is the Group of the Client.
-- @treturn MESSAGE
-- @usage
-- -- Send the 2 messages created with the @{New} method to the Client Group.
-- -- Note that the Message of MessageClient2 is overwriting the Message of MessageClient1.
-- ClientGroup = Group.getByName( "ClientGroup" )
--
-- MessageClient1 = MESSAGE:New( "Congratulations, you've just hit a target", "Score", 25, "Score" ):ToClient( ClientGroup )
-- MessageClient2 = MESSAGE:New( "Congratulations, you've just killed a target", "Score", 25, "Score" ):ToClient( ClientGroup )
-- or
-- MESSAGE:New( "Congratulations, you've just hit a target", "Score", 25, "Score" ):ToClient( ClientGroup )
-- MESSAGE:New( "Congratulations, you've just killed a target", "Score", 25, "Score" ):ToClient( ClientGroup )
-- or
-- MessageClient1 = MESSAGE:New( "Congratulations, you've just hit a target", "Score", 25, "Score" )
-- MessageClient2 = MESSAGE:New( "Congratulations, you've just killed a target", "Score", 25, "Score" )
-- MessageClient1:ToClient( ClientGroup )
-- MessageClient2:ToClient( ClientGroup )
function MESSAGE:ToClient( Client )
trace.f(self.ClassName )

	if Client and Client:ClientGroup() then
		local ClientGroupName = Client:ClientGroup():getName()

		if not _MessageQueue.ClientGroups[ClientGroupName] then
			_MessageQueue.ClientGroups[ClientGroupName] = {}
			_MessageQueue.ClientGroups[ClientGroupName].Messages = {}
		end
		
		_MessageQueue.ClientGroups[ClientGroupName].Messages[self.MessageID] = self
	end
	
	return self
end

--- Sends a MESSAGE to a Coalition. 
-- @param CoalitionSide needs to be filled out by the defined structure of the standard scripting engine @{coalition.side}. 
-- @treturn MESSAGE
-- @usage
-- -- Send a message created with the @{New} method to the RED coalition.
-- MessageRED = MESSAGE:New( "To the RED Players: You receive a penalty because you've killed one of your own units", "Penalty", 25, "Score" ):ToCoalition( coalition.side.RED )
-- or
-- MESSAGE:New( "To the RED Players: You receive a penalty because you've killed one of your own units", "Penalty", 25, "Score" ):ToCoalition( coalition.side.RED )
-- or
-- MessageRED = MESSAGE:New( "To the RED Players: You receive a penalty because you've killed one of your own units", "Penalty", 25, "Score" )
-- MessageRED:ToCoalition( coalition.side.RED )
function MESSAGE:ToCoalition( CoalitionSide )
trace.f(self.ClassName )

	if CoalitionSide then
		if not _MessageQueue.CoalitionSides[CoalitionSide] then
			_MessageQueue.CoalitionSides[CoalitionSide] = {}
			_MessageQueue.CoalitionSides[CoalitionSide].Messages = {}
		end
		
		_MessageQueue.CoalitionSides[CoalitionSide].Messages[self.MessageID] = self
	end
	
	return self
end

--- Sends a MESSAGE to all players. 
-- @treturn MESSAGE
-- @usage
-- -- Send a message created to all players.
-- MessageAll = MESSAGE:New( "To all Players: BLUE has won! Each player of BLUE wins 50 points!", "End of Mission", 25, "Win" ):ToAll()
-- or
-- MESSAGE:New( "To all Players: BLUE has won! Each player of BLUE wins 50 points!", "End of Mission", 25, "Win" ):ToAll()
-- or
-- MessageAll = MESSAGE:New( "To all Players: BLUE has won! Each player of BLUE wins 50 points!", "End of Mission", 25, "Win" )
-- MessageAll:ToAll()
function MESSAGE:ToAll()
trace.f(self.ClassName )

	self:ToCoalition( coalition.side.RED )
	self:ToCoalition( coalition.side.BLUE )

	return self
end



--- MESSAGEQUEUE
-- @type MESSAGEQUEUE

MESSAGEQUEUE = {
	ClientGroups = {},
	CoalitionSides = {}
}

function MESSAGEQUEUE:New( RefreshInterval )
trace.f( self.ClassName, { RefreshInterval } )

	local self = BASE:Inherit( self, BASE:New() )
	
	self.RefreshInterval = RefreshInterval

	self.DisplayFunction = routines.scheduleFunction( self._DisplayMessages, { self }, 0, RefreshInterval )

	return self
end

--- This function is called automatically by the MESSAGEQUEUE scheduler.
function MESSAGEQUEUE:_DisplayMessages()

	-- First we display all messages that a coalition needs to receive... Also those who are not in a client (CA module clients...).
	for CoalitionSideID, CoalitionSideData in pairs( self.CoalitionSides ) do
		for MessageID, MessageData in pairs( CoalitionSideData.Messages ) do
			if MessageData.MessageSent == false then
				trigger.action.outTextForCoalition( CoalitionSideID, MessageData.MessageCategory .. '\n' .. MessageData.MessageText:gsub("\n$",""):gsub("\n$",""), MessageData.MessageDuration )
				MessageData.MessageSent = true
			end
			local MessageTimeLeft = ( MessageData.MessageTime + MessageData.MessageDuration ) - timer.getTime()
			if MessageTimeLeft <= 0 then
				MessageData = nil
			end
		end
	end

	-- Then we send the messages for each individual client, but also to be included are those Coalition messages for the Clients who belong to a coalition.
	-- Because the Client messages will overwrite the Coalition messages (for that Client).
	for ClientGroupName, ClientGroupData in pairs( self.ClientGroups ) do
		for MessageID, MessageData in pairs( ClientGroupData.Messages ) do
			if MessageData.MessageGroup == false then
				trigger.action.outTextForGroup( Group.getByName(ClientGroupName):getID(), MessageData.MessageCategory .. '\n' .. MessageData.MessageText:gsub("\n$",""):gsub("\n$",""), MessageData.MessageDuration )
				MessageData.MessageGroup = true
			end
			local MessageTimeLeft = ( MessageData.MessageTime + MessageData.MessageDuration ) - timer.getTime()
			if MessageTimeLeft <= 0 then
				MessageData = nil
			end
		end
		
		-- Now check if the Client also has messages that belong to the Coalition of the Client...
		for CoalitionSideID, CoalitionSideData in pairs( self.CoalitionSides ) do
			for MessageID, MessageData in pairs( CoalitionSideData.Messages ) do
				local CoalitionGroup = Group.getByName( ClientGroupName )
				if CoalitionGroup and CoalitionGroup:getCoalition() == CoalitionSideID then 
					if MessageData.MessageCoalition == false then
						trigger.action.outTextForGroup( Group.getByName(ClientGroupName):getID(), MessageData.MessageCategory .. '\n' .. MessageData.MessageText:gsub("\n$",""):gsub("\n$",""), MessageData.MessageDuration )
						MessageData.MessageCoalition = true
					end
				end
				local MessageTimeLeft = ( MessageData.MessageTime + MessageData.MessageDuration ) - timer.getTime()
				if MessageTimeLeft <= 0 then
					MessageData = nil
				end
			end
		end
	end
end

--- The _MessageQueue object is created when the MESSAGE class module is loaded.
_MessageQueue = MESSAGEQUEUE:New( 0.5 )

