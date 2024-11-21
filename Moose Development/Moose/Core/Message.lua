--- **Core** - Informs the players using messages during a simulation.
--
-- ===
--
-- ## Features:
--
--   * A more advanced messaging system using the DCS message system.
--   * Time messages.
--   * Send messages based on a message type, which has a pre-defined duration that can be tweaked in SETTINGS.
--   * Send message to all players.
--   * Send messages to a coalition.
--   * Send messages to a specific group.
--   * Send messages to a specific unit or client.
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
--   * To a @{Wrapper.Client} using @{#MESSAGE.ToClient}().
--   * To a @{Wrapper.Group} using @{#MESSAGE.ToGroup}()
--   * To a @{Wrapper.Unit} using @{#MESSAGE.ToUnit}()
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
-- ### Contributions: **Applevangelist**
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
  Detailed = "Detailed Report",
}

--- Creates a new MESSAGE object. Note that these MESSAGE objects are not yet displayed on the display panel. You must use the functions @{#MESSAGE.ToClient} or @{#MESSAGE.ToCoalition} or @{#MESSAGE.ToAll} to send these Messages to the respective recipients.
-- @param self
-- @param #string Text is the text of the Message.
-- @param #number Duration Duration in seconds how long the message text is shown.
-- @param #string Category (Optional) String expressing the "category" of the Message. The category will be shown as the first text in the message followed by a ": ".
-- @param #boolean ClearScreen (optional) Clear all previous messages if true.
-- @return #MESSAGE self
-- @usage
--
--   -- Create a series of new Messages.
--   -- MessageAll is meant to be sent to all players, for 25 seconds, and is classified as "Score".
--   -- MessageRED is meant to be sent to the RED players only, for 10 seconds, and is classified as "End of Mission", with ID "Win".
--   -- MessageClient1 is meant to be sent to a Client, for 25 seconds, and is classified as "Score", with ID "Score".
--   -- MessageClient1 is meant to be sent to a Client, for 25 seconds, and is classified as "Score", with ID "Score".
--   MessageAll = MESSAGE:New( "To all Players: BLUE has won! Each player of BLUE wins 50 points!",  25, "End of Mission" )
--   MessageRED = MESSAGE:New( "To the RED Players: You receive a penalty because you've killed one of your own units", 25, "Penalty" )
--   MessageClient1 = MESSAGE:New( "Congratulations, you've just hit a target",  25, "Score" )
--   MessageClient2 = MESSAGE:New( "Congratulations, you've just killed a target", 25, "Score")
--
function MESSAGE:New( Text, Duration, Category, ClearScreen )

  local self = BASE:Inherit( self, BASE:New() )
  
  self:F( { Text, Duration, Category } )

  self.MessageType = nil

  -- When no MessageCategory is given, we don't show it as a title... 
  if Category and Category ~= "" then
    if Category:sub( -1 ) ~= "\n" then
      self.MessageCategory = Category .. ": "
    else
      self.MessageCategory = Category:sub( 1, -2 ) .. ":\n"
    end
  else
    self.MessageCategory = ""
  end

  self.ClearScreen = false
  if ClearScreen ~= nil then
    self.ClearScreen = ClearScreen
  end

  self.MessageDuration = Duration or 5
  self.MessageTime = timer.getTime()
  self.MessageText = Text:gsub( "^\n", "", 1 ):gsub( "\n$", "", 1 )

  self.MessageSent = false
  self.MessageGroup = false
  self.MessageCoalition = false

  return self
end

--- Creates a new MESSAGE object of a certain type.
-- Note that these MESSAGE objects are not yet displayed on the display panel.
-- You must use the functions @{Core.Message#ToClient} or @{Core.Message#ToCoalition} or @{Core.Message#ToAll} to send these Messages to the respective recipients.
-- The message display times are automatically defined based on the timing settings in the @{Core.Settings} menu.
-- @param self
-- @param #string MessageText is the text of the Message.
-- @param #MESSAGE.Type MessageType The type of the message.
-- @param #boolean ClearScreen (optional) Clear all previous messages.
-- @return #MESSAGE
-- @usage
--
--   MessageAll = MESSAGE:NewType( "To all Players: BLUE has won! Each player of BLUE wins 50 points!", MESSAGE.Type.Information )
--   MessageRED = MESSAGE:NewType( "To the RED Players: You receive a penalty because you've killed one of your own units", MESSAGE.Type.Information )
--   MessageClient1 = MESSAGE:NewType( "Congratulations, you've just hit a target", MESSAGE.Type.Update )
--   MessageClient2 = MESSAGE:NewType( "Congratulations, you've just killed a target", MESSAGE.Type.Update )
--
function MESSAGE:NewType( MessageText, MessageType, ClearScreen )

  local self = BASE:Inherit( self, BASE:New() )
  self:F( { MessageText } )

  self.MessageType = MessageType

  self.ClearScreen = false
  if ClearScreen ~= nil then
    self.ClearScreen = ClearScreen
  end

  self.MessageTime = timer.getTime()
  self.MessageText = MessageText:gsub( "^\n", "", 1 ):gsub( "\n$", "", 1 )

  return self
end

--- Clears all previous messages from the screen before the new message is displayed. Not that this must come before all functions starting with ToX(), e.g. ToAll(), ToGroup() etc.
-- @param #MESSAGE self
-- @return #MESSAGE
function MESSAGE:Clear()
  self:F()
  self.ClearScreen = true
  return self
end

--- Sends a MESSAGE to a Client Group. Note that the Group needs to be defined within the ME with the skillset "Client" or "Player".
-- @param #MESSAGE self
-- @param Wrapper.Client#CLIENT Client is the Group of the Client.
-- @param Core.Settings#SETTINGS Settings used to display the message.
-- @return #MESSAGE
-- @usage
--
--   -- Send the 2 messages created with the @{New} method to the Client Group.
--   -- Note that the Message of MessageClient2 is overwriting the Message of MessageClient1.
--   Client = CLIENT:FindByName("NameOfClientUnit")
--
--   MessageClient1 = MESSAGE:New( "Congratulations, you've just hit a target", 25, "Score" ):ToClient( Client )
--   MessageClient2 = MESSAGE:New( "Congratulations, you've just killed a target", 25, "Score" ):ToClient( Client )
--   or
--   MESSAGE:New( "Congratulations, you've just hit a target", 25, "Score"):ToClient( Client )
--   MESSAGE:New( "Congratulations, you've just killed a target", 25, "Score"):ToClient( Client )
--   or
--   MessageClient1 = MESSAGE:New( "Congratulations, you've just hit a target", 25, "Score")
--   MessageClient2 = MESSAGE:New( "Congratulations, you've just killed a target", 25, "Score")
--   MessageClient1:ToClient( Client )
--   MessageClient2:ToClient( Client )
--
function MESSAGE:ToClient( Client, Settings )
  self:F( Client )
  self:ToUnit(Client,Settings)
  return self
end

--- Sends a MESSAGE to a Group.
-- @param #MESSAGE self
-- @param Wrapper.Group#GROUP Group to which the message is displayed.
-- @param Core.Settings#Settings Settings (Optional) Settings for message display.
-- @return #MESSAGE Message object.
function MESSAGE:ToGroup( Group, Settings )
  self:F( Group.GroupName )

  if Group then

    if self.MessageType then
      local Settings = Settings or (Group and _DATABASE:GetPlayerSettings( Group:GetPlayerName() )) or _SETTINGS -- Core.Settings#SETTINGS
      self.MessageDuration = Settings:GetMessageTime( self.MessageType )
      self.MessageCategory = "" -- self.MessageType .. ": "
    end

    if self.MessageDuration ~= 0 then
      self:T( self.MessageCategory .. self.MessageText:gsub( "\n$", "" ):gsub( "\n$", "" ) .. " / " .. self.MessageDuration )
      trigger.action.outTextForGroup( Group:GetID(), self.MessageCategory .. self.MessageText:gsub( "\n$", "" ):gsub( "\n$", "" ), self.MessageDuration, self.ClearScreen )
    end
  end

  return self
end

--- Sends a MESSAGE to a Unit. 
-- @param #MESSAGE self
-- @param Wrapper.Unit#UNIT Unit to which the message is displayed.
-- @param Core.Settings#Settings Settings (Optional) Settings for message display.
-- @return #MESSAGE Message object.
function MESSAGE:ToUnit( Unit, Settings )
  self:F( Unit.IdentifiableName )

  if Unit then
    
    if self.MessageType then
      local Settings = Settings or ( Unit and _DATABASE:GetPlayerSettings( Unit:GetPlayerName() ) ) or _SETTINGS -- Core.Settings#SETTINGS
      self.MessageDuration = Settings:GetMessageTime( self.MessageType )
      self.MessageCategory = "" -- self.MessageType .. ": "
    end

    if self.MessageDuration ~= 0 then
      self:T( self.MessageCategory .. self.MessageText:gsub("\n$",""):gsub("\n$","") .. " / " .. self.MessageDuration )
      local ID = Unit:GetID()
      trigger.action.outTextForUnit( Unit:GetID(), self.MessageCategory .. self.MessageText:gsub("\n$",""):gsub("\n$",""), self.MessageDuration, self.ClearScreen )
    end
  end
  
  return self
end

--- Sends a MESSAGE to a Country. 
-- @param #MESSAGE self
-- @param #number Country to which the message is displayed, e.g. country.id.GERMANY. For all country numbers see here: [Hoggit Wiki](https://wiki.hoggitworld.com/view/DCS_enum_country)
-- @param Core.Settings#Settings Settings (Optional) Settings for message display.
-- @return #MESSAGE Message object.
function MESSAGE:ToCountry( Country, Settings )
  self:F(Country )
  if Country then   
    if self.MessageType then
      local Settings = Settings or _SETTINGS -- Core.Settings#SETTINGS
      self.MessageDuration = Settings:GetMessageTime( self.MessageType )
      self.MessageCategory = "" -- self.MessageType .. ": "
    end
    if self.MessageDuration ~= 0 then
      self:T( self.MessageCategory .. self.MessageText:gsub("\n$",""):gsub("\n$","") .. " / " .. self.MessageDuration )
      trigger.action.outTextForCountry( Country, self.MessageCategory .. self.MessageText:gsub("\n$",""):gsub("\n$",""), self.MessageDuration, self.ClearScreen )
    end
  end  
  return self
end

--- Sends a MESSAGE to a Country. 
-- @param #MESSAGE self
-- @param #number Country to which the message is displayed, , e.g. country.id.GERMANY. For all country numbers see here: [Hoggit Wiki](https://wiki.hoggitworld.com/view/DCS_enum_country)
-- @param #boolean Condition Sends the message only if the condition is true.
-- @param Core.Settings#Settings Settings (Optional) Settings for message display.
-- @return #MESSAGE Message object.
function MESSAGE:ToCountryIf( Country, Condition, Settings )
  self:F(Country )
  if Country and Condition == true then
    self:ToCountry( Country, Settings )
  end
  return self
end

--- Sends a MESSAGE to the Blue coalition.
-- @param #MESSAGE self
-- @return #MESSAGE
-- @usage
--
--   -- Send a message created with the @{New} method to the BLUE coalition.
--   MessageBLUE = MESSAGE:New( "To the BLUE Players: You receive a penalty because you've killed one of your own units", 25, "Penalty"):ToBlue()
--   or
--   MESSAGE:New( "To the BLUE Players: You receive a penalty because you've killed one of your own units", 25, "Penalty"):ToBlue()
--   or
--   MessageBLUE = MESSAGE:New( "To the BLUE Players: You receive a penalty because you've killed one of your own units", 25, "Penalty")
--   MessageBLUE:ToBlue()
--
function MESSAGE:ToBlue()
  self:F()

  self:ToCoalition( coalition.side.BLUE )

  return self
end

--- Sends a MESSAGE to the Red Coalition.
-- @param #MESSAGE self
-- @return #MESSAGE
-- @usage
--
--   -- Send a message created with the @{New} method to the RED coalition.
--   MessageRED = MESSAGE:New( "To the RED Players: You receive a penalty because you've killed one of your own units", 25, "Penalty"):ToRed()
--   or
--   MESSAGE:New( "To the RED Players: You receive a penalty because you've killed one of your own units", 25, "Penalty"):ToRed()
--   or
--   MessageRED = MESSAGE:New( "To the RED Players: You receive a penalty because you've killed one of your own units", 25, "Penalty")
--   MessageRED:ToRed()
--
function MESSAGE:ToRed()
  self:F()

  self:ToCoalition( coalition.side.RED )

  return self
end

--- Sends a MESSAGE to a Coalition.
-- @param #MESSAGE self
-- @param DCS#coalition.side CoalitionSide @{#DCS.coalition.side} to which the message is displayed.
-- @param Core.Settings#SETTINGS Settings (Optional) Settings for message display.
-- @return #MESSAGE Message object.
-- @usage
--
--   -- Send a message created with the @{New} method to the RED coalition.
--   MessageRED = MESSAGE:New( "To the RED Players: You receive a penalty because you've killed one of your own units", 25, "Penalty"):ToCoalition( coalition.side.RED )
--   or
--   MESSAGE:New( "To the RED Players: You receive a penalty because you've killed one of your own units", 25, "Penalty"):ToCoalition( coalition.side.RED )
--   or
--   MessageRED = MESSAGE:New( "To the RED Players: You receive a penalty because you've killed one of your own units", 25, "Penalty")
--   MessageRED:ToCoalition( coalition.side.RED )
--
function MESSAGE:ToCoalition( CoalitionSide, Settings )
  self:F( CoalitionSide )

  if self.MessageType then
    local Settings = Settings or _SETTINGS -- Core.Settings#SETTINGS
    self.MessageDuration = Settings:GetMessageTime( self.MessageType )
    self.MessageCategory = "" -- self.MessageType .. ": "
  end

  if CoalitionSide then
    if self.MessageDuration ~= 0 then
      self:T( self.MessageCategory .. self.MessageText:gsub( "\n$", "" ):gsub( "\n$", "" ) .. " / " .. self.MessageDuration )
      trigger.action.outTextForCoalition( CoalitionSide, self.MessageCategory .. self.MessageText:gsub( "\n$", "" ):gsub( "\n$", "" ), self.MessageDuration, self.ClearScreen )
    end
  end
  
  self.CoalitionSide = CoalitionSide
  
  return self
end

--- Sends a MESSAGE to a Coalition if the given Condition is true.
-- @param #MESSAGE self
-- @param CoalitionSide needs to be filled out by the defined structure of the standard scripting engine @{#DCS.coalition.side}.
-- @param #boolean Condition Sends the message only if the condition is true.
-- @return #MESSAGE self
function MESSAGE:ToCoalitionIf( CoalitionSide, Condition )
  self:F( CoalitionSide )

  if Condition and Condition == true then
    self:ToCoalition( CoalitionSide )
  end

  return self
end

--- Sends a MESSAGE to all players. 
-- @param #MESSAGE self
-- @param Core.Settings#Settings Settings (Optional) Settings for message display.
-- @param #number Delay (Optional) Delay in seconds before the message is send. Default instantly (`nil`).
-- @return #MESSAGE self
-- @usage
--
--   -- Send a message created to all players.
--   MessageAll = MESSAGE:New( "To all Players: BLUE has won! Each player of BLUE wins 50 points!", 25, "End of Mission"):ToAll()
--   or
--   MESSAGE:New( "To all Players: BLUE has won! Each player of BLUE wins 50 points!", 25, "End of Mission"):ToAll()
--   or
--   MessageAll = MESSAGE:New( "To all Players: BLUE has won! Each player of BLUE wins 50 points!", 25, "End of Mission")
--   MessageAll:ToAll()
--
function MESSAGE:ToAll( Settings, Delay )
  self:F()

  if Delay and Delay>0 then
    self:ScheduleOnce(Delay, MESSAGE.ToAll, self, Settings, 0)
  else

    if self.MessageType then
      local Settings = Settings or _SETTINGS -- Core.Settings#SETTINGS
      self.MessageDuration = Settings:GetMessageTime( self.MessageType )
      self.MessageCategory = "" -- self.MessageType .. ": "
    end
  
    if self.MessageDuration ~= 0 then
      self:T( self.MessageCategory .. self.MessageText:gsub( "\n$", "" ):gsub( "\n$", "" ) .. " / " .. self.MessageDuration )
      trigger.action.outText( self.MessageCategory .. self.MessageText:gsub( "\n$", "" ):gsub( "\n$", "" ), self.MessageDuration, self.ClearScreen )
    end
    
  end

  return self
end

--- Sends a MESSAGE to all players if the given Condition is true.
-- @param #MESSAGE self
-- @param #boolean Condition
-- @return #MESSAGE
function MESSAGE:ToAllIf( Condition )

  if Condition and Condition == true then
    self:ToAll()
  end

  return self
end

--- Sends a MESSAGE to DCS log file.
-- @param #MESSAGE self
-- @return #MESSAGE self
function MESSAGE:ToLog()

  env.info(self.MessageCategory .. self.MessageText:gsub( "\n$", "" ):gsub( "\n$", "" ))

  return self
end

--- Sends a MESSAGE to DCS log file if the given Condition is true.
-- @param #MESSAGE self
-- @return #MESSAGE self
function MESSAGE:ToLogIf( Condition )
  
  if Condition and Condition == true then
    env.info(self.MessageCategory .. self.MessageText:gsub( "\n$", "" ):gsub( "\n$", "" ))
  end
  return self
end

_MESSAGESRS = {}

--- Set up MESSAGE generally to allow Text-To-Speech via SRS and TTS functions. `SetMSRS()` will try to use as many attributes configured with @{Sound.SRS#MSRS.LoadConfigFile}() as possible.
-- @param #string PathToSRS (optional) Path to SRS Folder, defaults to "C:\\\\Program Files\\\\DCS-SimpleRadio-Standalone" or your configuration file setting.
-- @param #number Port Port (optional) number of SRS, defaults to 5002 or your configuration file setting.
-- @param #string PathToCredentials (optional) Path to credentials file for Google.
-- @param #number Frequency Frequency in MHz. Can also be given as a #table of frequencies.
-- @param #number Modulation Modulation, i.e. radio.modulation.AM  or radio.modulation.FM. Can also be given as a #table of modulations.
-- @param #string Gender (optional) Gender, i.e. "male" or "female", defaults to "female" or your configuration file setting.
-- @param #string Culture (optional) Culture, e.g. "en-US", defaults to "en-GB" or your configuration file setting.
-- @param #string Voice (optional) Voice. Will override gender and culture settings, e.g. MSRS.Voices.Microsoft.Hazel or MSRS.Voices.Google.Standard.de_DE_Standard_D. Hint on Microsoft voices - working voices are limited to Hedda, Hazel, David, Zira and Hortense. **Must** be installed on your Desktop or Server!
-- @param #number Coalition (optional) Coalition, can be coalition.side.RED, coalition.side.BLUE or coalition.side.NEUTRAL. Defaults to coalition.side.NEUTRAL.
-- @param #number Volume (optional) Volume, can be between 0.0 and 1.0 (loudest).
-- @param #string Label (optional) Label, defaults to "MESSAGE" or the Message Category set.
-- @param Core.Point#COORDINATE Coordinate (optional) Coordinate this messages originates from.
-- @usage
--          -- Mind the dot here, not using the colon this time around!
--          -- Needed once only
--          MESSAGE.SetMSRS("D:\\Program Files\\DCS-SimpleRadio-Standalone",5012,nil,127,radio.modulation.FM,"female","en-US",nil,coalition.side.BLUE)
--          -- later on in your code
--          MESSAGE:New("Test message!",15,"SPAWN"):ToSRS()
--          
function MESSAGE.SetMSRS(PathToSRS,Port,PathToCredentials,Frequency,Modulation,Gender,Culture,Voice,Coalition,Volume,Label,Coordinate)
  
  _MESSAGESRS.PathToSRS = PathToSRS or MSRS.path or "C:\\Program Files\\DCS-SimpleRadio-Standalone"
  
  _MESSAGESRS.frequency = Frequency or MSRS.frequencies or 243
  _MESSAGESRS.modulation = Modulation or MSRS.modulations or radio.modulation.AM
  
  _MESSAGESRS.MSRS = MSRS:New(_MESSAGESRS.PathToSRS,_MESSAGESRS.frequency, _MESSAGESRS.modulation)

  _MESSAGESRS.coalition = Coalition or MSRS.coalition or coalition.side.NEUTRAL    
  _MESSAGESRS.MSRS:SetCoalition(_MESSAGESRS.coalition)

  _MESSAGESRS.coordinate = Coordinate
  
  if Coordinate then
    _MESSAGESRS.MSRS:SetCoordinate(Coordinate)
  end
  
  _MESSAGESRS.Culture = Culture or MSRS.culture or "en-GB"
  _MESSAGESRS.MSRS:SetCulture(Culture)

  _MESSAGESRS.Gender = Gender or MSRS.gender or "female"
  _MESSAGESRS.MSRS:SetGender(Gender)

  if PathToCredentials then
    _MESSAGESRS.MSRS:SetProviderOptionsGoogle(PathToCredentials)
    _MESSAGESRS.MSRS:SetProvider(MSRS.Provider.GOOGLE)
  end
  
  _MESSAGESRS.label = Label or MSRS.Label or "MESSAGE"
  _MESSAGESRS.MSRS:SetLabel(_MESSAGESRS.label)

  _MESSAGESRS.port = Port or MSRS.port or 5002
  _MESSAGESRS.MSRS:SetPort(_MESSAGESRS.port)

  _MESSAGESRS.volume = Volume or MSRS.volume or 1
  _MESSAGESRS.MSRS:SetVolume(_MESSAGESRS.volume)
  
  if Voice then _MESSAGESRS.MSRS:SetVoice(Voice) end
  
  _MESSAGESRS.voice = Voice or MSRS.voice --or MSRS.Voices.Microsoft.Hedda
  
  _MESSAGESRS.SRSQ = MSRSQUEUE:New(_MESSAGESRS.label)
end

--- Sends a message via SRS. `ToSRS()` will try to use as many attributes configured with @{Core.Message#MESSAGE.SetMSRS}() and @{Sound.SRS#MSRS.LoadConfigFile}() as possible.
-- @param #MESSAGE self
-- @param #number frequency (optional) Frequency in MHz. Can also be given as a #table of frequencies. Only needed if you want to override defaults set with `MESSAGE.SetMSRS()` for this one setting.
-- @param #number modulation (optional) Modulation, i.e. radio.modulation.AM  or radio.modulation.FM. Can also be given as a #table of modulations. Only needed if you want to override defaults set with `MESSAGE.SetMSRS()` for this one setting.
-- @param #string gender (optional) Gender, i.e. "male" or "female". Only needed if you want to change defaults set with `MESSAGE.SetMSRS()`.
-- @param #string culture (optional) Culture, e.g. "en-US". Only needed if you want to change defaults set with `MESSAGE.SetMSRS()`.
-- @param #string voice (optional) Voice. Will override gender and culture settings. Only needed if you want to change defaults set with `MESSAGE.SetMSRS()`.
-- @param #number coalition (optional) Coalition, can be coalition.side.RED, coalition.side.BLUE or coalition.side.NEUTRAL. Only needed if you want to change defaults set with `MESSAGE.SetMSRS()`.
-- @param #number volume (optional) Volume, can be between 0.0 and 1.0 (loudest). Only needed if you want to change defaults set with `MESSAGE.SetMSRS()`.
-- @param Core.Point#COORDINATE coordinate (optional) Coordinate this messages originates from. Only needed if you want to change defaults set with `MESSAGE.SetMSRS()`.
-- @return #MESSAGE self
-- @usage
--          -- Mind the dot here, not using the colon this time around!
--          -- Needed once only
--          MESSAGE.SetMSRS("D:\\Program Files\\DCS-SimpleRadio-Standalone",5012,nil,127,radio.modulation.FM,"female","en-US",nil,coalition.side.BLUE)
--          -- later on in your code
--          MESSAGE:New("Test message!",15,"SPAWN"):ToSRS()
--          
function MESSAGE:ToSRS(frequency,modulation,gender,culture,voice,coalition,volume,coordinate)
  local tgender = gender or _MESSAGESRS.Gender
  if _MESSAGESRS.SRSQ then
      if voice then
        _MESSAGESRS.MSRS:SetVoice(voice or _MESSAGESRS.voice)
      end
      if coordinate then
        _MESSAGESRS.MSRS:SetCoordinate(coordinate)  
      end
      local category = string.gsub(self.MessageCategory,":","")
      _MESSAGESRS.SRSQ:NewTransmission(self.MessageText,nil,_MESSAGESRS.MSRS,0.5,1,nil,nil,nil,frequency or _MESSAGESRS.frequency,modulation or _MESSAGESRS.modulation, gender or _MESSAGESRS.Gender,culture or _MESSAGESRS.Culture,nil,volume or _MESSAGESRS.volume,category,coordinate or _MESSAGESRS.coordinate)
  end
  return self
end

--- Sends a message via SRS on the blue coalition side.
-- @param #MESSAGE self
-- @param #number frequency (optional) Frequency in MHz. Can also be given as a #table of frequencies. Only needed if you want to override defaults set with `MESSAGE.SetMSRS()` for this one setting.
-- @param #number modulation (optional) Modulation, i.e. radio.modulation.AM  or radio.modulation.FM. Can also be given as a #table of modulations. Only needed if you want to override defaults set with `MESSAGE.SetMSRS()` for this one setting.
-- @param #string gender (optional) Gender, i.e. "male" or "female". Only needed if you want to change defaults set with `MESSAGE.SetMSRS()`.
-- @param #string culture (optional) Culture, e.g. "en-US. Only needed if you want to change defaults set with `MESSAGE.SetMSRS()`.
-- @param #string voice (optional) Voice. Will override gender and culture settings. Only needed if you want to change defaults set with `MESSAGE.SetMSRS()`.
-- @param #number volume (optional) Volume, can be between 0.0 and 1.0 (loudest). Only needed if you want to change defaults set with `MESSAGE.SetMSRS()`.
-- @param Core.Point#COORDINATE coordinate (optional) Coordinate this messages originates from. Only needed if you want to change defaults set with `MESSAGE.SetMSRS()`.
-- @return #MESSAGE self
-- @usage
--          -- Mind the dot here, not using the colon this time around!
--          -- Needed once only
--          MESSAGE.SetMSRS("D:\\Program Files\\DCS-SimpleRadio-Standalone",5012,nil,127,radio.modulation.FM,"female","en-US",nil,coalition.side.BLUE)
--          -- later on in your code
--          MESSAGE:New("Test message!",15,"SPAWN"):ToSRSBlue()
--          
function MESSAGE:ToSRSBlue(frequency,modulation,gender,culture,voice,volume,coordinate)
  self:ToSRS(frequency,modulation,gender,culture,voice,coalition.side.BLUE,volume,coordinate)
  return self
end

--- Sends a message via SRS on the red coalition side.
-- @param #MESSAGE self
-- @param #number frequency (optional) Frequency in MHz. Can also be given as a #table of frequencies. Only needed if you want to override defaults set with `MESSAGE.SetMSRS()` for this one setting.
-- @param #number modulation (optional) Modulation, i.e. radio.modulation.AM  or radio.modulation.FM. Can also be given as a #table of modulations. Only needed if you want to override defaults set with `MESSAGE.SetMSRS()` for this one setting.
-- @param #string gender (optional) Gender, i.e. "male" or "female". Only needed if you want to change defaults set with `MESSAGE.SetMSRS()`.
-- @param #string culture (optional) Culture, e.g. "en-US. Only needed if you want to change defaults set with `MESSAGE.SetMSRS()`.
-- @param #string voice (optional) Voice. Will override gender and culture settings. Only needed if you want to change defaults set with `MESSAGE.SetMSRS()`.
-- @param #number volume (optional) Volume, can be between 0.0 and 1.0 (loudest). Only needed if you want to change defaults set with `MESSAGE.SetMSRS()`.
-- @param Core.Point#COORDINATE coordinate (optional) Coordinate this messages originates from. Only needed if you want to change defaults set with `MESSAGE.SetMSRS()`.
-- @return #MESSAGE self
-- @usage
--          -- Mind the dot here, not using the colon this time around!
--          -- Needed once only
--          MESSAGE.SetMSRS("D:\\Program Files\\DCS-SimpleRadio-Standalone",5012,nil,127,radio.modulation.FM,"female","en-US",nil,coalition.side.RED)
--          -- later on in your code
--          MESSAGE:New("Test message!",15,"SPAWN"):ToSRSRed()
--          
function MESSAGE:ToSRSRed(frequency,modulation,gender,culture,voice,volume,coordinate)
  self:ToSRS(frequency,modulation,gender,culture,voice,coalition.side.RED,volume,coordinate)
  return self
end

--- Sends a message via SRS to all - via the neutral coalition side.
-- @param #MESSAGE self
-- @param #number frequency (optional) Frequency in MHz. Can also be given as a #table of frequencies. Only needed if you want to override defaults set with `MESSAGE.SetMSRS()` for this one setting.
-- @param #number modulation (optional) Modulation, i.e. radio.modulation.AM  or radio.modulation.FM. Can also be given as a #table of modulations. Only needed if you want to override defaults set with `MESSAGE.SetMSRS()` for this one setting.
-- @param #string gender (optional) Gender, i.e. "male" or "female". Only needed if you want to change defaults set with `MESSAGE.SetMSRS()`.
-- @param #string culture (optional) Culture, e.g. "en-US. Only needed if you want to change defaults set with `MESSAGE.SetMSRS()`.
-- @param #string voice (optional) Voice. Will override gender and culture settings. Only needed if you want to change defaults set with `MESSAGE.SetMSRS()`.
-- @param #number volume (optional) Volume, can be between 0.0 and 1.0 (loudest). Only needed if you want to change defaults set with `MESSAGE.SetMSRS()`.
-- @param Core.Point#COORDINATE coordinate (optional) Coordinate this messages originates from. Only needed if you want to change defaults set with `MESSAGE.SetMSRS()`.
-- @return #MESSAGE self
-- @usage
--          -- Mind the dot here, not using the colon this time around!
--          -- Needed once only
--          MESSAGE.SetMSRS("D:\\Program Files\\DCS-SimpleRadio-Standalone",5012,nil,127,radio.modulation.FM,"female","en-US",nil,coalition.side.NEUTRAL)
--          -- later on in your code
--          MESSAGE:New("Test message!",15,"SPAWN"):ToSRSAll()
--          
function MESSAGE:ToSRSAll(frequency,modulation,gender,culture,voice,volume,coordinate)
  self:ToSRS(frequency,modulation,gender,culture,voice,coalition.side.NEUTRAL,volume,coordinate)
  return self
end
