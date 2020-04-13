-- This routine is called from the LDT environment to create the Moose.lua file stub for use in .miz files.


local MoosePath="D:/DCS/Scripts/moose/MOOSE"
local MooseDevelopmentPath = MoosePath.."/Moose Development/Moose"
local MooseSetupPath = MoosePath.."/Moose Setup"
local MooseTargetPath =MoosePath.."/Moose Setup"

local MooseCommitHash = "Static FF Development"

print( "Commit Hash ID            : " .. MooseCommitHash )
print( "Moose development path    : " .. MooseDevelopmentPath )
print( "Moose setup path          : " .. MooseSetupPath )
print( "Moose target path         : " .. MooseTargetPath )

local MooseModulesFilePath=MooseDevelopmentPath.."/Modules.lua"
local LoaderFilePath=MooseTargetPath.."/Moose.lua"

print( "Reading Moose source list : " .. MooseModulesFilePath )

local LoaderFile=io.open(LoaderFilePath, "w")
LoaderFile:write( "env.info( '*** MOOSE DEVELOPMENT version: " .. MooseCommitHash .. " ***' )\n" )

local MooseSourcesFile = io.open( MooseModulesFilePath, "r" )
local MooseSource = MooseSourcesFile:read("*l")

while( MooseSource ) do
  
  if MooseSource ~= "" then
    MooseSource = string.match( MooseSource, "Scripts/Moose/(.+)'" )
    local MooseFilePath = MooseDevelopmentPath .. "/" .. MooseSource
    print( "Load static: " .. MooseFilePath )
    local MooseSourceFile = io.open( MooseFilePath, "r" )
    local MooseSourceFileText = MooseSourceFile:read( "*a" )
    MooseSourceFile:close()
    
    LoaderFile:write( MooseSourceFileText )
  end
  
  MooseSource = MooseSourcesFile:read("*l")
end

LoaderFile:write( "BASE:TraceOnOff( false )\n" )
LoaderFile:write( "env.info( '*** MOOSE INCLUDE END *** ' )\n" )

MooseSourcesFile:close()
LoaderFile:close()
