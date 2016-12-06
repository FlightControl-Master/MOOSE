--- This module contains the MESSAGE class.
-- 
-- 1) @{Core.Message#MESSAGE} class, extends @{Core.Base#BASE}
-- =================================================
-- Message System to display Messages to Clients, Coalitions or All.
-- Messages are shown on the display panel for an amount of seconds, and will then disappear.
-- Messages can contain a category which is indicating the category of the message.
-- 
-- 1.1) MESSAGE construction methods
-- ---------------------------------
-- Messages are created with @{Core.Message#MESSAGE.New}. Note that when the MESSAGE object is created, no message is sent yet.
-- To send messages, you need to use the To functions.
-- 
-- 1.2) Send messages with MESSAGE To methods
-- ------------------------------------------
-- Messages are sent to:
--
--   * Clients with @{Core.Message#MESSAGE.ToClient}.
--   * Coalitions with @{Core.Message#MESSAGE.ToCoalition}.
--   * All Players with @{Core.Message#MESSAGE.ToAll}.
--   
-- @module Message
-- @author FlightControl

--- The MESSAGE class
-- @type MESSAGE
-- @extends Core.Base#BASE
MESSAGE = {
	ClassName = "MESSAGE", 
	MessageCategory = 0,
	MessageID = 0,
}


--- Creates a new MESSAGE object. Note that these MESSAGE objects are not yet displayed on the display panel. You must use the functions @{ToClient} or @{ToCoalition} or @{ToAll} to send these Messages to the respective recipients.
-- @param self
-- @param #string MessageText is the text of the Message.
-- @param #number MessageDuration is a number in seconds of how long the MESSAGE should be shown on the display panel.
-- @param #string MessageCategory (optional) is a string expressing the "category" of the Message. The category will be shown as the first text in the message followed by a ": ".
-- @return #MESSAGE
-- @usage
-- -- Create a series of new Messages.
-- -- MessageAll is meant to be sent to all players, for 25 seconds, and is classified as "Score".
-- -- MessageRED is meant to be sent to the RED players only, for 10 seconds, and is classified as "End of Mission", with ID "Win".
-- -- MessageClient1 is meant to be sent to a Client, for 25 seconds, and is classified as "Score", with ID "Score".
-- -- MessageClient1 is meant to be sent to a Client, for 25 seconds, and is classified as "Score", with ID "Score".
-- MessageAll = MESSAGE:New( "To all Players: BLUE has won! Each player of BLUE wins 50 points!",  25, "End of Mission" )
-- MessageRED = MESSAGE:New( "To the RED Players: You receive a penalty because you've killed one of your own units", 25, "Penalty" )
-- MessageClient1 = MESSAGE:New( "Congratulations, you've just hit a target",  25, "Score" )
-- MessageClient2 = MESSAGE:New( "Congratulations, you've just killed a target", 25, "Score")
function MESSAGE:New( MessageText, MessageDuration, MessageCategory )
	local self = BASE:Inherit( self, BASE:New() )
	self:F( { MessageText, MessageDuration, MessageCategory } )

  -- When no MessageCategory is given, we don't show it as a title...	
	if MessageCategory and MessageCategory ~= "" then
	  if MessageCategory:sub(-1) ~= "\n" then
      self.MessageCategory = MessageCategory .. ": "
    else
      self.MessageCategory = MessageCategory:sub( 1, -2 ) .. ":\n" 
    end
  else
    self.MessageCategory = ""
  end

	self.MessageDuration = MessageDuration or 5
	self.MessageTime = timer.getTime()
	self.MessageText = MessageText
	
	self.MessageSent = false
	self.MessageGroup = false
	self.MessageCoalition = false

	return self
end

--- Sends a MESSAGE to a Client Group. Note that the Group needs to be defined within the ME with the skillset "Client" or "Player".
-- @param #MESSAGE self
-- @param Wrapper.Client#CLIENT Client is the Group of the Client.
-- @return #MESSAGE
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
	self:F( Client )

	if Client and Client:GetClientGroupID() then

		local ClientGroupID = Client:GetClientGroupID()
		self:T( self.MessageCategory .. self.MessageText:gsub("\n$",""):gsub("\n$","") .. " / " .. self.MessageDuration )
		trigger.action.outTextForGroup( ClientGroupID, self.MessageCategory .. self.MessageText:gsub("\n$",""):gsub("\n$",""), self.MessageDuration )
	end
	
	return self
end

--- Sends a MESSAGE to a Group. 
-- @param #MESSAGE self
-- @param Wrapper.Group#GROUP Group is the Group.
-- @return #MESSAGE
function MESSAGE:ToGroup( Group )
  self:F( Group.GroupName )

  if Group then

    self:T( self.MessageCategory .. self.MessageText:gsub("\n$",""):gsub("\n$","") .. " / " .. self.MessageDuration )
    trigger.action.outTextForGroup( Group:GetID(), self.MessageCategory .. self.MessageText:gsub("\n$",""):gsub("\n$",""), self.MessageDuration )
  end
  
  return self
end
--- Sends a MESSAGE to the Blue coalition.
-- @param #MESSAGE self 
-- @return #MESSAGE
-- @usage
-- -- Send a message created with the @{New} method to the BLUE coalition.
-- MessageBLUE = MESSAGE:New( "To the BLUE Players: You receive a penalty because you've killed one of your own units", "Penalty", 25, "Score" ):ToBlue()
-- or
-- MESSAGE:New( "To the BLUE Players: You receive a penalty because you've killed one of your own units", "Penalty", 25, "Score" ):ToBlue()
-- or
-- MessageBLUE = MESSAGE:New( "To the BLUE Players: You receive a penalty because you've killed one of your own units", "Penalty", 25, "Score" )
-- MessageBLUE:ToBlue()
function MESSAGE:ToBlue()
	self:F()

	self:ToCoalition( coalition.side.BLUE )
	
	return self
end

--- Sends a MESSAGE to the Red Coalition. 
-- @param #MESSAGE self
-- @return #MESSAGE
-- @usage
-- -- Send a message created with the @{New} method to the RED coalition.
-- MessageRED = MESSAGE:New( "To the RED Players: You receive a penalty because you've killed one of your own units", "Penalty", 25, "Score" ):ToRed()
-- or
-- MESSAGE:New( "To the RED Players: You receive a penalty because you've killed one of your own units", "Penalty", 25, "Score" ):ToRed()
-- or
-- MessageRED = MESSAGE:New( "To the RED Players: You receive a penalty because you've killed one of your own units", "Penalty", 25, "Score" )
-- MessageRED:ToRed()
function MESSAGE:ToRed( )
	self:F()

	self:ToCoalition( coalition.side.RED )
	
	return self
end

--- Sends a MESSAGE to a Coalition. 
-- @param #MESSAGE self
-- @param CoalitionSide needs to be filled out by the defined structure of the standard scripting engine @{coalition.side}. 
-- @return #MESSAGE
-- @usage
-- -- Send a message created with the @{New} method to the RED coalition.
-- MessageRED = MESSAGE:New( "To the RED Players: You receive a penalty because you've killed one of your own units", "Penalty", 25, "Score" ):ToCoalition( coalition.side.RED )
-- or
-- MESSAGE:New( "To the RED Players: You receive a penalty because you've killed one of your own units", "Penalty", 25, "Score" ):ToCoalition( coalition.side.RED )
-- or
-- MessageRED = MESSAGE:New( "To the RED Players: You receive a penalty because you've killed one of your own units", "Penalty", 25, "Score" )
-- MessageRED:ToCoalition( coalition.side.RED )
function MESSAGE:ToCoalition( CoalitionSide )
	self:F( CoalitionSide )

	if CoalitionSide then
		self:T( self.MessageCategory .. self.MessageText:gsub("\n$",""):gsub("\n$","") .. " / " .. self.MessageDuration )
		trigger.action.outTextForCoalition( CoalitionSide, self.MessageCategory .. self.MessageText:gsub("\n$",""):gsub("\n$",""), self.MessageDuration )
	end
	
	return self
end

--- Sends a MESSAGE to all players. 
-- @param #MESSAGE self
-- @return #MESSAGE
-- @usage
-- -- Send a message created to all players.
-- MessageAll = MESSAGE:New( "To all Players: BLUE has won! Each player of BLUE wins 50 points!", "End of Mission", 25, "Win" ):ToAll()
-- or
-- MESSAGE:New( "To all Players: BLUE has won! Each player of BLUE wins 50 points!", "End of Mission", 25, "Win" ):ToAll()
-- or
-- MessageAll = MESSAGE:New( "To all Players: BLUE has won! Each player of BLUE wins 50 points!", "End of Mission", 25, "Win" )
-- MessageAll:ToAll()
function MESSAGE:ToAll()
	self:F()

	self:ToCoalition( coalition.side.RED )
	self:ToCoalition( coalition.side.BLUE )

	return self
end



----- The MESSAGEQUEUE class
---- @type MESSAGEQUEUE
--MESSAGEQUEUE = {
--	ClientGroups = {},
--	CoalitionSides = {}
--}
--
--function MESSAGEQUEUE:New( RefreshInterval )
--	local self = BASE:Inherit( self, BASE:New() )
--	self:F( { RefreshInterval } )
--	
--	self.RefreshInterval = RefreshInterval
--
--	--self.DisplayFunction = routines.scheduleFunction( self._DisplayMessages, { self }, 0, RefreshInterval )
--  self.DisplayFunction = SCHEDULER:New( self, self._DisplayMessages, {}, 0, RefreshInterval )
--
--	return self
--end
--
----- This function is called automatically by the MESSAGEQUEUE scheduler.
--function MESSAGEQUEUE:_DisplayMessages()
--
--	-- First we display all messages that a coalition needs to receive... Also those who are not in a client (CA module clients...).
--	for CoalitionSideID, CoalitionSideData in pairs( self.CoalitionSides ) do
--		for MessageID, MessageData in pairs( CoalitionSideData.Messages ) do
--			if MessageData.MessageSent == false then
--				--trigger.action.outTextForCoalition( CoalitionSideID, MessageData.MessageCategory .. '\n' .. MessageData.MessageText:gsub("\n$",""):gsub("\n$",""), MessageData.MessageDuration )
--				MessageData.MessageSent = true
--			end
--			local MessageTimeLeft = ( MessageData.MessageTime + MessageData.MessageDuration ) - timer.getTime()
--			if MessageTimeLeft <= 0 then
--				MessageData = nil
--			end
--		end
--	end
--
--	-- Then we send the messages for each individual client, but also to be included are those Coalition messages for the Clients who belong to a coalition.
--	-- Because the Client messages will overwrite the Coalition messages (for that Client).
--	for ClientGroupName, ClientGroupData in pairs( self.ClientGroups ) do
--		for MessageID, MessageData in pairs( ClientGroupData.Messages ) do
--			if MessageData.MessageGroup == false then
--				trigger.action.outTextForGroup( Group.getByName(ClientGroupName):getID(), MessageData.MessageCategory .. '\n' .. MessageData.MessageText:gsub("\n$",""):gsub("\n$",""), MessageData.MessageDuration )
--				MessageData.MessageGroup = true
--			end
--			local MessageTimeLeft = ( MessageData.MessageTime + MessageData.MessageDuration ) - timer.getTime()
--			if MessageTimeLeft <= 0 then
--				MessageData = nil
--			end
--		end
--		
--		-- Now check if the Client also has messages that belong to the Coalition of the Client...
--		for CoalitionSideID, CoalitionSideData in pairs( self.CoalitionSides ) do
--			for MessageID, MessageData in pairs( CoalitionSideData.Messages ) do
--				local CoalitionGroup = Group.getByName( ClientGroupName )
--				if CoalitionGroup and CoalitionGroup:getCoalition() == CoalitionSideID then 
--					if MessageData.MessageCoalition == false then
--						trigger.action.outTextForGroup( Group.getByName(ClientGroupName):getID(), MessageData.MessageCategory .. '\n' .. MessageData.MessageText:gsub("\n$",""):gsub("\n$",""), MessageData.MessageDuration )
--						MessageData.MessageCoalition = true
--					end
--				end
--				local MessageTimeLeft = ( MessageData.MessageTime + MessageData.MessageDuration ) - timer.getTime()
--				if MessageTimeLeft <= 0 then
--					MessageData = nil
--				end
--			end
--		end
--	end
--	
--	return true
--end
--
----- The _MessageQueue object is created when the MESSAGE class module is loaded.
----_MessageQueue = MESSAGEQUEUE:New( 0.5 )
--
