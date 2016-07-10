
local Mission = MISSION:New( "SEAD Mission", "High", "SEAD Mission Briefing", coalition.side.RED )
local Scoring = SCORING:New( "SEAD Test" )
Mission:AddScoring( Scoring )


local FACGroup = GROUP:FindByName( "FAC" )

local FACDetection = DETECTION_UNITGROUPS:New( FACGroup, 6000, 1000 )

local AttackGroups = SET_GROUP:New():FilterCoalitions( "red" ):FilterPrefixes( "SEAD Attack" ):FilterStart()


local CommandCenter = GROUP:FindByName( "HQ" )

local TaskAssign = TASK_DISPATCHER:New( Mission, CommandCenter, AttackGroups, FACDetection )

