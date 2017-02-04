

local FACSetGroup = SET_GROUP:New():FilterPrefixes( "FAC Group" ):FilterStart()

local FACDetection = DETECTION_AREAS:New( FACSetGroup, 1000, 250 )
local SeadClientSet = SET_CLIENT:New():FilterCoalitions( "blue" ):FilterStart()
local DestroyClientSet = SET_CLIENT:New():FilterCoalitions( "blue" ):FilterStart()

local FACReporting = FAC_REPORTING:New( FACClientSet, FACDetection )
