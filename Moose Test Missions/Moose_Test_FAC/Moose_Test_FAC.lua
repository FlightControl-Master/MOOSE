

local FACGroup = GROUP:FindByName( "FAC Group" )

local FACDetection = DETECTION_BASE:New( FACGroup, 1000, 250 )
local FACClientSet = SET_CLIENT:New():FilterCoalitions( "blue" ):FilterStart()

local FACReporting = FAC_BASE:New( FACClientSet, FACDetection )