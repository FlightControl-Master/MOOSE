env.info( '*** MOOSE DYNAMIC INCLUDE START *** ' )

local base = _G

__Moose = {}

__Moose.Include = function( IncludeFile )
	if not __Moose.Includes[ IncludeFile ] then
		__Moose.Includes[IncludeFile] = IncludeFile
		local f = assert( base.loadfile( IncludeFile ) )
		if f == nil then
			error ("Moose: Could not load Moose file " .. IncludeFile )
		else
			env.info( "Moose: " .. IncludeFile .. " dynamically loaded." )
			return f()
		end
	end
end

__Moose.Includes = {}

__Moose.Include( 'Scripts/Moose/Modules.lua' )
