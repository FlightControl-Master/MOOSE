
local base = _G

__Moose = {}

__Moose.Include = function( IncludeFile )
	if not __Moose.Includes[ IncludeFile ] then
		__Moose.Includes[IncludeFile] = IncludeFile
		env.info( "Include:" .. IncludeFile .. " from " .. __Moose.ProgramPath )
		local f = assert( base.loadfile( __Moose.ProgramPath .. IncludeFile .. ".lua" ) )
		if f == nil then
			error ("Could not load Moose file " .. IncludeFile .. ".lua" )
		else
			env.info( "Moose:" .. IncludeFile .. " loaded from " .. __Moose.ProgramPath )
			return f()
		end
	end
end

__Moose.ProgramPath = "Scripts/Moose/"

__Moose.Includes = {}
