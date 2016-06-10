local base = _G

Include = {}

Include.Path = function()
   local str = debug.getinfo(2, "S").source
   return str:match("(.*/)"):sub(1,-2):gsub("\\","/")
end

Include.File = function( IncludeFile )
end

Include.Files = {}
