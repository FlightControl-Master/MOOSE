
local base = _G

MOOSE = {}

MOOSE.Include = function( LuaPath, IncludeFile )
	if not MOOSE.Includes[ IncludeFile ] then
		MOOSE.Includes[IncludeFile] = IncludeFile
		local f = assert( base.loadfile( LuaPath .. IncludeFile ) )
		if f == nil then
			error ("MOOSE: Could not load Moose file " .. IncludeFile )
		else
			env.info( "MOOSE: " .. IncludeFile .. " dynamically loaded from " .. LuaPath )
			return f()
		end
	end
end

MOOSE.ProgramPath = "Scripts/Moose/"

MOOSE.Includes = {}
