env.info( '*** MOOSE DYNAMIC INCLUDE START *** ' ) 
env.info( 'Moose Generation Timestamp: 20170116_2116' ) 

local base = _G

Include = {}

Include.File = function( IncludeFile )
	if not Include.Files[ IncludeFile ] then
		Include.Files[IncludeFile] = IncludeFile
		env.info( "Include:" .. IncludeFile .. " from " .. Include.ProgramPath )
		local f = assert( base.loadfile( Include.ProgramPath .. IncludeFile .. ".lua" ) )
		if f == nil then
			error ("Could not load MOOSE file " .. IncludeFile .. ".lua" )
		else
			env.info( "Include:" .. IncludeFile .. " loaded from " .. Include.ProgramPath )
			return f()
		end
	end
end

Include.ProgramPath = "Scripts/Moose/"

env.info( "Include.ProgramPath = " .. Include.ProgramPath)

Include.Files = {}

Include.File( "Moose" )

BASE:TraceOnOff( true )
env.info( '*** MOOSE INCLUDE END *** ' ) 
