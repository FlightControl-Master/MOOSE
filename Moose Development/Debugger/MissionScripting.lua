--Initialization script for the Mission lua Environment (SSE)

dofile('Scripts/ScriptingSystem.lua')

-- Add LuaSocket to the LUAPATH, so that it can be found.
package.path  = package.path..";.\\LuaSocket\\?.lua;"

-- Connect to the debugger, first require it.
local initconnection = require("debugger")

-- Now make the connection..
-- "127.0.0.1" is the localhost.
-- 10000 is the port. If you wanna use another port in LDT, change this number too!
-- "dcsserver" is the name of the server. If you wanna use another name, change the name here too!
-- nil (is for transport protocol, but not using this)
-- "win" don't touch. But is important to indicate that we are in a windows environment to the debugger script. 
initconnection( "127.0.0.1", 10000, "dcsserver", nil, "win", "" )


--Sanitize Mission Scripting environment
--This makes unavailable some unsecure functions. 
--Mission downloaded from server to client may contain potentialy harmful lua code that may use these functions.
--You can remove the code below and make availble these functions at your own risk.

local function sanitizeModule(name)
	_G[name] = nil
	package.loaded[name] = nil
end


do
	sanitizeModule('os')
	--sanitizeModule('io')
	sanitizeModule('lfs')
	require = nil
	loadlib = nil
end