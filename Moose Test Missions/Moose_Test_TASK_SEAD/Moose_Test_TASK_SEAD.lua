
local Mission = MISSION:New( 'SEAD Targets', "Strategic", "SEAD the enemy", coalition.side.RED )
local Scoring = SCORING:New( "SEAD" )

Mission:AddScoring( Scoring )

local SEADGroup = GROUP:FindByName( "Test SEAD" )
local TargetSet = SET_UNIT:New():FilterPrefixes( "US Hawk SR" ):FilterStart()

local TargetZone = ZONE:New( "Target Zone" )

local TaskSEAD = TASK_SEAD:New( Mission, TargetSet, TargetZone ):SetName( "SEAD Radars" ):AssignToGroup( SEADGroup )




