local FACGroup = GROUP:FindByName( "FAC" )

local FACDetection = DETECTION_UNITGROUPS:New( FACGroup, 1000, 250 )

local SEAD_Attack = SET_GROUP:New():FilterCoalitions( "red" ):FilterPrefixes( "SEAD Attack" ):FilterStart()

local Mission = MISSION:New( "SEAD Mission", "High", "SEAD Mission Briefing", coalition.side.RED )
local CommandCenter = GROUP:FindByName( "HQ" )

local TaskAssign = TASK_DISPATCHER:New( Mission, CommandCenter, SEAD_Attack, FACDetection )

