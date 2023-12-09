-- This routine is called from the LDT environment to create the Moose.lua file stub for use in .miz files.

local MooseDynamicStatic = arg[1]
local MooseCommitHash = arg[2]
local MooseDevelopmentPath = arg[3]
local MooseSetupPath = arg[4]
local MooseTargetPath = arg[5]
local isWindows = arg[6]

if not isWindows then
  isWindows = 0
end
print( "Moose (D)ynamic (S)tatic  : " .. MooseDynamicStatic )
print( "Commit Hash ID            : " .. MooseCommitHash )
print( "Moose development path    : " .. MooseDevelopmentPath )
print( "Moose setup path          : " .. MooseSetupPath )
print( "Moose target path         : " .. MooseTargetPath )
print( "isWindows                  : " .. isWindows)

  
function PathConvert(splatnixPath)
  if isWindows == 0 then
    return splatnixPath
  end
  return splatnixPath:gsub("/", "\\")
end
    
local MooseModulesFilePath =  MooseDevelopmentPath .. "/Modules.lua"
local LoaderFilePath = MooseTargetPath .. "/Moose.lua"

print( "Reading Moose source list : " .. MooseModulesFilePath )
print("Opening Loaderfile " .. PathConvert(LoaderFilePath))
local LoaderFile = assert(io.open( PathConvert(LoaderFilePath), "w+" ))

if MooseDynamicStatic == "S" then
  LoaderFile:write( "env.info( '*** MOOSE GITHUB Commit Hash ID: " .. MooseCommitHash .. " ***' )\n" )
end  

local MooseLoaderPath
if MooseDynamicStatic == "D" then
  MooseLoaderPath = MooseSetupPath .. "/Moose Templates/Moose_Dynamic_Loader.lua"
end
if MooseDynamicStatic == "S" then
  MooseLoaderPath = MooseSetupPath .. "/Moose Templates/Moose_Static_Loader.lua"
end


local MooseLoader = assert(io.open( PathConvert(MooseLoaderPath), "r" ))
local MooseLoaderText = MooseLoader:read( "*a" )
MooseLoader:close()

LoaderFile:write( MooseLoaderText )

local MooseSourcesFile = assert(io.open( PathConvert(MooseModulesFilePath), "r" ))
local MooseSource = MooseSourcesFile:read("*l")

while( MooseSource ) do
  -- Remove Windows line endings. Can occur when using act
  MooseSource = string.gsub(MooseSource, "\r", "")
  
  if MooseSource ~= "" then
    MooseSource = string.match( MooseSource, "Scripts/Moose/(.+)'" )
    local MooseFilePath = MooseDevelopmentPath .. "/" .. MooseSource
    if MooseDynamicStatic == "D" then
      print( "Load dynamic: " .. MooseFilePath )
    end
    if MooseDynamicStatic == "S" then
      print( "Load static: " .. MooseFilePath )
      local MooseSourceFile = assert(io.open( PathConvert(MooseFilePath), "r" ))
      local MooseSourceFileText = MooseSourceFile:read( "*a" )
      MooseSourceFile:close()
      
      LoaderFile:write( MooseSourceFileText )
    end
  end
  
  MooseSource = MooseSourcesFile:read("*l")
end

if MooseDynamicStatic == "D" then
  LoaderFile:write( "BASE:TraceOnOff( true )\n" )
end
if MooseDynamicStatic == "S" then
  LoaderFile:write( "BASE:TraceOnOff( false )\n" )
end

LoaderFile:write( "env.info( '*** MOOSE INCLUDE END *** ' )\n" )

MooseSourcesFile:close()
LoaderFile:close()

print("Moose include generation complete.")
if MooseDynamicStatic == "D" then
  print("To enable dynamic moose loading, add a soft or hard link from \"<YOUR_DCS_INSTALL_DIRECTORY>\\Scripts\\Moose\" to the \"Moose Development\\Moose\" subdirectory of the Moose_Framework repository.")
end
