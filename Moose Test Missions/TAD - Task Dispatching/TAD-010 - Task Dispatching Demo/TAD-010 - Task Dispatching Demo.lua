
local HQ = GROUP:FindByName( "HQ", "Bravo HQ" )

local CommandCenter = COMMANDCENTER:New( HQ, "Lima" )

local Scoring = SCORING:New( "Detect Demo" )

local Mission = MISSION:New( CommandCenter, "Overlord", "High", "Attack Detect Mission Briefing", coalition.side.RED ):AddScoring( Scoring )

local FACSet = SET_GROUP:New():FilterPrefixes( "FAC" ):FilterCoalitions("red"):FilterStart()
local FACDetection = DETECTION_AREAS:New( FACSet, 10000, 3000 )

local AttackGroups = SET_GROUP:New():FilterCoalitions( "red" ):FilterPrefixes( "Attack" ):FilterStart()
local TaskAssign = DETECTION_DISPATCHER:New( Mission, HQ, AttackGroups, FACDetection )

