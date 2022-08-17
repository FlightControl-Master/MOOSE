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
--
-- @field #SOCKET
SOCKET = {
  ClassName      = "SOCKET",
  verbose        =     0,
  lid            =   nil,
}

--- SOCKET class version.
-- @field #string version
SOCKET.version="0.0.1"

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
-- @param #number Port UDP port. Default `10123`.
-- @param #string Host Host. Default `"127.0.0.1"`.
-- @return #SOCKET self
function SOCKET:New(Port, Host)

  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, FSM:New()) --#SOCKET
  
  package.path  = package.path..";.\\LuaSocket\\?.lua;"
  package.cpath = package.cpath..";.\\LuaSocket\\?.dll;"
  
  self.socket = require("socket")
  
  self.port=Port or 10123
  self.host=Host or "127.0.0.1"
  
  self.json=loadfile("Scripts\\JSON.lua")()
  
  self.UDPSendSocket=self.socket.udp()
  self.UDPSendSocket:settimeout(0)

  return self
end

--- Send a table.
-- @param #SOCKET self
-- @param #table Table Table to send.
-- @param #number Port Port.
-- @return #SOCKET self
function SOCKET:SendTable(Table, Port)

    local tbl_json_txt = self.json:encode(Table)   
    
    Port=Port or self.port
    
    self.socket.try(self.UDPSendSocket:sendto(tbl_json_txt, self.host, Port))

  return self
end

--- Send a text message.
-- @param #SOCKET self
-- @param #string Text Test message.
-- @param #number Port Port.
-- @return #SOCKET self
function SOCKET:SendText(Text, Port)

  local message={}
  
  message.messageType = 1
  message.messageString = Text  

  self:SendTable(message, Port)

  return self
end


