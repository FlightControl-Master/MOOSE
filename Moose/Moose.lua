
local base = _G

env.info("Loading MOOSE " .. base.timer.getAbsTime() )

function script_path()
   local str = debug.getinfo(2, "S").source
   return str:match("(.*/)"):sub(1,-2)
end


Include = {}

Include.LoadPath = script_path() .. "Mission\\"

env.info( "Include.LoadPath = " .. Include.LoadPath )
Include.Files = {}

Include.File = function( IncludeFile )
	if not Include.Files[ IncludeFile ] then
		Include.Files[IncludeFile] = IncludeFile
		base.dofile( Include.LoadPath .. "" .. IncludeFile .. ".lua" )
		--local chunk, errMsg = base.loadfile( IncludeFile .. ".lua" )
		env.info( "Include:" .. IncludeFile .. " loaded " )
	end
end

Include.File( "Database" )

env.info("Loaded MOOSE")