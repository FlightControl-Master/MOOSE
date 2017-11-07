
local base = _G

__Moose = {}

__Moose.Include = function( LuaPath, IncludeFile )
	if not __Moose.Includes[ IncludeFile ] then
		__Moose.Includes[IncludeFile] = IncludeFile
		local f = assert( base.loadfile( LuaPath .. IncludeFile ) )
		if f == nil then
			error ("Moose: Could not load Moose file " .. IncludeFile )
		else
			env.info( "Moose: " .. IncludeFile .. " dynamically loaded from " .. LuaPath )
			return f()
		end
	end
end

__Moose.ProgramPath = "Scripts/Moose/"

__Moose.Includes = {}
