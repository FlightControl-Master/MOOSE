
local Mission = MISSION:New( "Attack Detect Mission", "High", "Attack Detect Mission Briefing", coalition.side.RED )
local Scoring = SCORING:New( "Detect Demo" )
Mission:AddScoring( Scoring )


local FACSet = SET_GROUP:New():FilterPrefixes( "FAC" ):FilterCoalitions("red"):FilterStart()

local FACDetection = DETECTION_AREAS:New( FACSet, 10000, 3000 )

local AttackGroups = SET_GROUP:New():FilterCoalitions( "red" ):FilterPrefixes( "Attack" ):FilterStart()


local CommandCenter = GROUP:FindByName( "HQ" )

local TaskAssign = DETECTION_DISPATCHER:New( Mission, CommandCenter, AttackGroups, FACDetection )

