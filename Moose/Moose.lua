
local base = _G

env.info("Loading MOOSE " .. base.timer.getAbsTime() )

function script_path()
   local str = debug.getinfo(2, "S").source
   return str:match("(.*/)"):sub(1,-2)
end


Include = {}

Include.MissionPath = script_path() .. "Mission\\"
Include.ProgramPath = "Scripts\\Moose\\Moose\\"

env.info( "Include.MissionPath = " .. Include.MissionPath)
env.info( "Include.ProgramPath = " .. Include.ProgramPath)
Include.Files = {}

Include.File = function( IncludeFile )
	if not Include.Files[ IncludeFile ] then
		Include.Files[IncludeFile] = IncludeFile
		local f = base.loadfile( Include.ProgramPath .. IncludeFile .. ".lua" )
		if f == nil then
			local f = base.loadfile( Include.MissionPath .. IncludeFile .. ".lua" )
			if f == nil then
				error ("Could not load MOOSE file " .. IncludeFile .. ".lua" )
			else
				env.info( "Include:" .. IncludeFile .. " loaded from " .. Include.ProgramPath )
				return f()
			end
		else
			env.info( "Include:" .. IncludeFile .. " loaded from " .. Include.MissionPath )
			return f()
		end
	end
end

Include.File( "Database" )

env.info("Loaded MOOSE Include Engine")