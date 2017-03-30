
local base = _G

__Moose = {}

__Moose.Include = function( IncludeFile )
	if not __Moose.Includes[ IncludeFile ] then
		__Moose.Includes[IncludeFile] = IncludeFile
		local f = assert( base.loadfile( __Moose.ProgramPath .. IncludeFile ) )
		if f == nil then
			error ("Moose: Could not load Moose file " .. IncludeFile )
		else
			env.info( "Moose: " .. IncludeFile .. " dynamically loaded from " .. __Moose.ProgramPath )
			return f()
		end
	end
end

__Moose.ProgramPath = "Scripts/Moose/"

__Moose.Includes = {}
