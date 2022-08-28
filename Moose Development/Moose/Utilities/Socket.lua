--- **Utilities** - Socket.
--
-- **Main Features:**
--
--    * Sockets
--    * Send messages to Discord
--
-- ===
--
-- ### Author: **funkyfranky**
-- @module Utilities.Socket
-- @image Utilities_Socket.png


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

--- **It is far more important to be able to hit the target than it is to haggle over who makes a weapon or who pulls a trigger** -- Dwight D Eisenhower
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

--- Data type.
-- @field #string TEXT Plain text.
-- @field #string BOMB Range bombing.
-- @field #string STRAFE Range strafeing result.
-- @field #string LSOGRADE Airboss LSO grade.
-- @field #string TRAPSHEET Airboss trap sheet.
SOCKET.DataType={
  TEXT="Text",
  RANGEBOMB="Bomb Result",
  RANGESTRAFE="Strafe Run",
  LSOGRADE="LSO Grade",
  TRAPSHEET="Trapsheet",
}


--- SOCKET class version.
-- @field #string version
SOCKET.version="0.1.0"

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
-- @param #string Text Test message.
-- @return #SOCKET self
function SOCKET:SendText(Text)

  local message={}
  
  message.dataType = "Text Message"
  message.text = Text  

  self:SendTable(message)

  return self
end


