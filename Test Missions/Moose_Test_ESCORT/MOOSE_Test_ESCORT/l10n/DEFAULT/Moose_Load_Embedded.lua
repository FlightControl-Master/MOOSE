
local base = _G
env.info("Loading MOOSE " .. base.timer.getAbsTime() )

Include = {}

Include.Path = function()
   local str = debug.getinfo(2, "S").source
   return str:match("(.*/)"):sub(1,-2):gsub("\\","/")
end

Include.File = function( IncludeFile )
end

Include.ProgramPath = "Scripts/Moose/Moose/"
Include.MissionPath = Include.Path()

env.info( "Include.ProgramPath = " .. Include.ProgramPath)
env.info( "Include.MissionPath = " .. Include.MissionPath)

Include.Files = {}

env.info("Loaded MOOSE Include Engine")
