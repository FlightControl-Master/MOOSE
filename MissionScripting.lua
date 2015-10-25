--Initialization script for the Mission lua Environment (SSE)

dofile('Scripts/ScriptingSystem.lua')

Include = {}

Include.LoadPath = 'Scripts/MOOSE'
Include.Files = {}

Include.File = function( IncludeFile )
	if not Include.Files[ IncludeFile ] then
		Include.Files[IncludeFile] = IncludeFile
		dofile( Include.LoadPath .. "/" .. IncludeFile .. ".lua" )
		env.info( "Include:" .. IncludeFile .. " loaded." )
	end
end

Include.File( "Database" )
Include.File( "StatHandler" )

--Sanitize Mission Scripting environment
--This makes unavailable some unsecure functions. 
--Mission downloaded from server to client may contain potentialy harmful lua code that may use these functions.
--You can remove the code below and make availble these functions at your own risk.

local function sanitizeModule(name)
	_G[name] = nil
	package.loaded[name] = nil
end

do
	--sanitizeModule('os')
	--sanitizeModule('io')
	sanitizeModule('lfs')
	require = nil
	loadlib = nil
end