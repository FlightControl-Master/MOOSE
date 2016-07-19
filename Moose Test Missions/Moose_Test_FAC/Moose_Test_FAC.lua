

local FACGroup = GROUP:FindByName( "FAC Group" )

local FACDetection = DETECTION_AREAS:New( FACGroup, 1000, 250 )
local SeadClientSet = SET_CLIENT:New():FilterCoalitions( "blue" ):FilterStart()
local DestroyClientSet = SET_CLIENT:New():FilterCoalitions( "blue" ):FilterStart()

local FACReporting = FAC_REPORTING:New( FACClientSet, FACDetection )
