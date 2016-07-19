
local FACGroup = GROUP:FindByName( "FAC Group" )

local FACDetection = DETECTION_AREAS:New( FACGroup, 1000, 250 ):FlareDetectedZones():FlareDetectedUnits()

