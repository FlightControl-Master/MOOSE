env.info( '*** MOOSE DYNAMIC INCLUDE START *** ' ) 
env.info( 'Moose Generation Timestamp: 20160616_1305' ) 

local base = _G

Include = {}

Include.Path = function()
   local str = debug.getinfo(2, "S").source
   return str:match("(.*/)"):sub(1,-2):gsub("\\","/")
end

Include.File = function( IncludeFile )
	if not Include.Files[ IncludeFile ] then
		Include.Files[IncludeFile] = IncludeFile
		env.info( "Include:" .. IncludeFile .. " from " .. Include.ProgramPath )
		local f = assert( base.loadfile( Include.ProgramPath .. IncludeFile .. ".lua" ) )
		if f == nil then
			env.info( "Include:" .. IncludeFile .. " from " .. Include.MissionPath )
			local f = assert( base.loadfile( Include.MissionPath .. IncludeFile .. ".lua" ) )
			if f == nil then
				error ("Could not load MOOSE file " .. IncludeFile .. ".lua" )
			else
				env.info( "Include:" .. IncludeFile .. " loaded from " .. Include.MissionPath )
				return f()
			end
		else
			env.info( "Include:" .. IncludeFile .. " loaded from " .. Include.ProgramPath )
			return f()
		end
	end
end

Include.ProgramPath = "Scripts/Moose/"
Include.MissionPath = Include.Path()

env.info( "Include.ProgramPath = " .. Include.ProgramPath)
env.info( "Include.MissionPath = " .. Include.MissionPath)

Include.Files = {}

Include.File( "Moose" )

BASE:TraceOnOff( true )
env.info( '*** MOOSE INCLUDE END *** ' ) 
