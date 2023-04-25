--- **Utilities** - Socket.
--
-- **Main Features:**
--
--    * Creates UDP Sockets
--    * Send messages to Discord
--    * Compatible with [FunkMan](https://github.com/funkyfranky/FunkMan)
--    * Compatible with [DCSServerBot](https://github.com/Special-K-s-Flightsim-Bots/DCSServerBot)
--
-- ===
--
-- ### Author: **funkyfranky**
-- @module Utilities.Socket
-- @image MOOSE.JPG


--- SOCKET class.
-- @type SOCKET
-- @field #string ClassName Name of the class.
-- @field #number verbose Verbosity level.
-- @field #string lid Class id string for output to DCS log file.
-- @field #table socket The socket.
-- @field #number port The port.
-- @field #string host The host.
-- @field #table json JSON.
-- @extends Core.Fsm#FSM

--- **At times I feel like a socket that remembers its tooth.** -- Saul Bellow
--
-- ===
--
-- # The SOCKET Concept
-- 
-- Create a UDP socket server. It enables you to send messages to discord servers via discord bots.
-- 
-- **Note** that you have to **de-sanitize** `require` and `package` in your `MissionScripting.lua` file, which is in your `DCS/Scripts` folder.
--
--
-- @field #SOCKET
SOCKET = {
  ClassName      = "SOCKET",
  verbose        =     0,
  lid            =   nil,
}

--- Data type. This is the keyword the socket listener uses.
-- @type SOCKET.DataType
-- @field #string TEXT Plain text.
-- @field #string BOMBRESULT Range bombing.
-- @field #string STRAFERESULT Range strafeing result.
-- @field #string LSOGRADE Airboss LSO grade.
-- @field #string TTS Text-To-Speech.
SOCKET.DataType={
  TEXT="moose_text",
  BOMBRESULT="moose_bomb_result",
  STRAFERESULT="moose_strafe_result",
  LSOGRADE="moose_lso_grade",
  TTS="moose_text2speech"
}


--- SOCKET class version.
-- @field #string version
SOCKET.version="0.3.0"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: A lot!
-- TODO: Messages as spoiler.
-- TODO: Send images?

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new SOCKET object.
-- @param #SOCKET self
-- @param #number Port UDP port. Default `10042`.
-- @param #string Host Host. Default `"127.0.0.1"`.
-- @return #SOCKET self
function SOCKET:New(Port, Host)

  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, FSM:New()) --#SOCKET
  
  package.path  = package.path..";.\\LuaSocket\\?.lua;"
  package.cpath = package.cpath..";.\\LuaSocket\\?.dll;"
  
  self.socket = require("socket")
  
  self.port=Port or 10042
  self.host=Host or "127.0.0.1"
  
  self.json=loadfile("Scripts\\JSON.lua")()
  
  self.UDPSendSocket=self.socket.udp()
  self.UDPSendSocket:settimeout(0)

  return self
end

--- Set port.
-- @param #SOCKET self
-- @param #number Port Port. Default 10042.
-- @return #SOCKET self
function SOCKET:SetPort(Port)
  self.port=Port or 10042
end

--- Set host.
-- @param #SOCKET self
-- @param #string Host Host. Default `"127.0.0.1"`.
-- @return #SOCKET self
function SOCKET:SetHost(Host)
  self.host=Host or "127.0.0.1"
end


--- Send a table.
-- @param #SOCKET self
-- @param #table Table Table to send.
-- @return #SOCKET self
function SOCKET:SendTable(Table)

  -- Add server name for DCS
  Table.server_name=BASE.ServerName or "Unknown"

  -- Encode json table.
  local json= self.json:encode(Table)
  
  -- Debug info.
  self:T("Json table:")
  self:T(json)
  
  -- Send data.
  self.socket.try(self.UDPSendSocket:sendto(json, self.host, self.port))

  return self
end

--- Send a text message.
-- @param #SOCKET self
-- @param #string Text Text message.
-- @return #SOCKET self
function SOCKET:SendText(Text)

  local message={}
  
  message.command = SOCKET.DataType.TEXT
  message.text = Text  

  self:SendTable(message)

  return self
end

--- Send a text-to-speech message.
-- @param #SOCKET self
-- @param #string Text The text message to speek.
-- @param #number Provider The TTS provider: 0=Microsoft (default), 1=Google.
-- @param #string Voice The specific voice to use, e.g. `"Microsoft David Desktop"` or "`en-US-Standard-A`". If not set, the service will choose a voice based on the other parameters such as culture and gender.
-- @param #string Culture The Culture or language code, *e.g.* `"en-US"`.
-- @param #string Gender The Gender, *i.e.* "male", "female". Default "female".
-- @param #number Volume The volume. Microsoft: [0,100] default 50, Google: [-96, 10] default 0.
-- @return #SOCKET self
function SOCKET:SendTextToSpeech(Text, Provider, Voice, Culture, Gender, Volume)

  Text=Text or "Hello World!"

  local message={}
  
  message.command = SOCKET.DataType.TTS
  message.text = Text
  message.provider=Provider
  message.voice = Voice
  message.culture = Culture
  message.gender = Gender
  message.volume = Volume

  self:SendTable(message)

  return self
end


