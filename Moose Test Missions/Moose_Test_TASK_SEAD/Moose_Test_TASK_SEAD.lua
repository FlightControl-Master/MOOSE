
local Mission = MISSION:New( 'SEAD Targets', "Strategic", "SEAD the enemy", "RUSSIA" )
local Scoring = SCORING:New( "SEAD" )

Mission:AddScoring( Scoring )

local Client = CLIENT:FindByName( "Test SEAD" )
local TargetSet = SET_UNIT:New():FilterPrefixes( "US Hawk SR" ):FilterStart()

local TargetZone = ZONE:New( "Target Zone" )

local Task_SEAD = TASK_SEAD:New( TargetSet, TargetZone )



