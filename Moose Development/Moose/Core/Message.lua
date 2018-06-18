--- **Core** -- MESSAGE class takes are of the **real-time notifications** and **messages to players** during a simulation.
-- 
-- ===
-- 
-- @module Core.Message
-- @image Core_Message.JPG

--- The MESSAGE class
-- @type MESSAGE
-- @extends Core.Base#BASE

--- Message System to display Messages to Clients, Coalitions or All.
-- Messages are shown on the display panel for an amount of seconds, and will then disappear.
-- Messages can contain a category which is indicating the category of the message.
-- 
-- ## MESSAGE construction
-- 
-- Messages are created with @{#MESSAGE.New}. Note that when the MESSAGE object is created, no message is sent yet.
-- To send messages, you need to use the To functions.
-- 
-- ## Send messages to an audience
-- 
-- Messages are sent:
--
--   * To a @{Client} using @{#MESSAGE.ToClient}().
--   * To a @{Wrapper.Group} using @{#MESSAGE.ToGroup}()
--   * To a coalition using @{#MESSAGE.ToCoalition}().
--   * To the red coalition using @{#MESSAGE.ToRed}().
--   * To the blue coalition using @{#MESSAGE.ToBlue}().
--   * To all Players using @{#MESSAGE.ToAll}().
-- 
-- ## Send conditionally to an audience
-- 
-- Messages can be sent conditionally to an audience (when a condition is true):
--   
--   * To all players using @{#MESSAGE.ToAllIf}().
--   * To a coalition using @{#MESSAGE.ToCoalitionIf}().
-- 
-- ===
--  
-- ### Author: **FlightControl**
-- ### Contributions: 
-- 
-- ===
-- 
-- @field #MESSAGE
MESSAGE = {
	ClassName = "MESSAGE", 
	MessageCategory = 0,
	MessageID = 0,
}

--- Message Types
-- @type MESSAGE.Type
MESSAGE.Type = {
  Update = "Update",
  Information = "Information",
  Briefing = "Briefing Report",
  Overview = "Overview Report",
  Detailed = "Detailed Report"
}


--- Creates a new MESSAGE object. Note that these MESSAGE objects are not yet displayed on the display panel. You must use the functions @{ToClient} or @{ToCoalition} or @{ToAll} to send these Messages to the respective recipients.
-- @param self
-- @param #string MessageText is the text of the Message.
-- @param #number MessageDuration is a number in seconds of how long the MESSAGE should be shown on the display panel.
-- @param #string MessageCategory (optional) is a string expressing the "category" of the Message. The category will be shown as the first text in the message followed by a ": ".
-- @param #boolean ClearScreen (optional) Clear all previous messages if true.
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
function MESSAGE:New( MessageText, MessageDuration, MessageCategory, ClearScreen )
	local self = BASE:Inherit( self, BASE:New() )
	self:F( { MessageText, MessageDuration, MessageCategory } )


  self.MessageType = nil
  
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
  
  self.ClearScreen=false
  if ClearScreen~=nil then
    self.ClearScreen=ClearScreen
  end

	self.MessageDuration = MessageDuration or 5
	self.MessageTime = timer.getTime()
	self.MessageText = MessageText:gsub("^\n","",1):gsub("\n$","",1)
	
	self.MessageSent = false
	self.MessageGroup = false
	self.MessageCoalition = false

	return self
end


--- Creates a new MESSAGE object of a certain type. 
-- Note that these MESSAGE objects are not yet displayed on the display panel. 
-- You must use the functions @{ToClient} or @{ToCoalition} or @{ToAll} to send these Messages to the respective recipients.
-- The message display times are automatically defined based on the timing settings in the @{Settings} menu.
-- @param self
-- @param #string MessageText is the text of the Message.
-- @param #MESSAGE.Type MessageType The type of the message.
-- @param #boolean ClearScreen (optional) Clear all previous messages.
-- @return #MESSAGE
-- @usage
--   MessageAll = MESSAGE:NewType( "To all Players: BLUE has won! Each player of BLUE wins 50 points!", MESSAGE.Type.Information )
--   MessageRED = MESSAGE:NewType( "To the RED Players: You receive a penalty because you've killed one of your own units", MESSAGE.Type.Information )
--   MessageClient1 = MESSAGE:NewType( "Congratulations, you've just hit a target", MESSAGE.Type.Update )
--   MessageClient2 = MESSAGE:NewType( "Congratulations, you've just killed a target", MESSAGE.Type.Update )
function MESSAGE:NewType( MessageText, MessageType, ClearScreen )

  local self = BASE:Inherit( self, BASE:New() )
  self:F( { MessageText } )
  
  self.MessageType = MessageType
  
  self.ClearScreen=false
  if ClearScreen~=nil then
    self.ClearScreen=ClearScreen
  end

  self.MessageTime = timer.getTime()
  self.MessageText = MessageText:gsub("^\n","",1):gsub("\n$","",1)
  
  return self
end



--- Clears all previous messages from the screen before the new message is displayed. Not that this must come before all functions starting with ToX(), e.g. ToAll(), ToGroup() etc. 
-- @param #MESSAGE self
-- @return #MESSAGE
function MESSAGE:Clear()
  self:F()
  self.ClearScreen=true
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
function MESSAGE:ToClient( Client, Settings )
	self:F( Client )

	if Client and Client:GetClientGroupID() then

    if self.MessageType then
      local Settings = Settings or ( Client and _DATABASE:GetPlayerSettings( Client:GetPlayerName() ) ) or _SETTINGS -- Core.Settings#SETTINGS
      self.MessageDuration = Settings:GetMessageTime( self.MessageType )
      self.MessageCategory = "" -- self.MessageType .. ": "
    end

    if self.MessageDuration ~= 0 then
  		local ClientGroupID = Client:GetClientGroupID()
  		self:T( self.MessageCategory .. self.MessageText:gsub("\n$",""):gsub("\n$","") .. " / " .. self.MessageDuration )
  		trigger.action.outTextForGroup( ClientGroupID, self.MessageCategory .. self.MessageText:gsub("\n$",""):gsub("\n$",""), self.MessageDuration , self.ClearScreen)
		end
	end
	
	return self
end

--- Sends a MESSAGE to a Group. 
-- @param #MESSAGE self
-- @param Wrapper.Group#GROUP Group is the Group.
-- @return #MESSAGE
function MESSAGE:ToGroup( Group, Settings )
  self:F( Group.GroupName )

  if Group then
    
    if self.MessageType then
      local Settings = Settings or ( Group and _DATABASE:GetPlayerSettings( Group:GetPlayerName() ) ) or _SETTINGS -- Core.Settings#SETTINGS
      self.MessageDuration = Settings:GetMessageTime( self.MessageType )
      self.MessageCategory = "" -- self.MessageType .. ": "
    end

    if self.MessageDuration ~= 0 then
      self:T( self.MessageCategory .. self.MessageText:gsub("\n$",""):gsub("\n$","") .. " / " .. self.MessageDuration )
      trigger.action.outTextForGroup( Group:GetID(), self.MessageCategory .. self.MessageText:gsub("\n$",""):gsub("\n$",""), self.MessageDuration, self.ClearScreen )
    end
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
function MESSAGE:ToCoalition( CoalitionSide, Settings )
	self:F( CoalitionSide )

  if self.MessageType then
    local Settings = Settings or _SETTINGS -- Core.Settings#SETTINGS
    self.MessageDuration = Settings:GetMessageTime( self.MessageType )
    self.MessageCategory = "" -- self.MessageType .. ": "
  end

	if CoalitionSide then
    if self.MessageDuration ~= 0 then
  		self:T( self.MessageCategory .. self.MessageText:gsub("\n$",""):gsub("\n$","") .. " / " .. self.MessageDuration )
  		trigger.action.outTextForCoalition( CoalitionSide, self.MessageText:gsub("\n$",""):gsub("\n$",""), self.MessageDuration, self.ClearScreen )
    end
	end
	
	return self
end

--- Sends a MESSAGE to a Coalition if the given Condition is true. 
-- @param #MESSAGE self
-- @param CoalitionSide needs to be filled out by the defined structure of the standard scripting engine @{coalition.side}. 
-- @return #MESSAGE
function MESSAGE:ToCoalitionIf( CoalitionSide, Condition )
  self:F( CoalitionSide )

  if Condition and Condition == true then
    self:ToCoalition( CoalitionSide )
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

  if self.MessageType then
    local Settings = Settings or _SETTINGS -- Core.Settings#SETTINGS
    self.MessageDuration = Settings:GetMessageTime( self.MessageType )
    self.MessageCategory = "" -- self.MessageType .. ": "
  end

  if self.MessageDuration ~= 0 then
    self:T( self.MessageCategory .. self.MessageText:gsub("\n$",""):gsub("\n$","") .. " / " .. self.MessageDuration )
    trigger.action.outText( self.MessageCategory .. self.MessageText:gsub("\n$",""):gsub("\n$",""), self.MessageDuration, self.ClearScreen )
  end

  return self
end


--- Sends a MESSAGE to all players if the given Condition is true.
-- @param #MESSAGE self
-- @return #MESSAGE
function MESSAGE:ToAllIf( Condition )

  if Condition and Condition == true then
    self:ToAll()
  end

	return self
end
