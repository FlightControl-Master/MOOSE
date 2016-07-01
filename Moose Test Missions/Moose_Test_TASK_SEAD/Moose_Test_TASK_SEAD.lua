
local Mission = MISSION:New( 'SEAD Targets', "Strategic", "SEAD the enemy", "RUSSIA" )
local Scoring = SCORING:New( "SEAD" )

Mission:AddScoring( Scoring )

local Client = CLIENT:FindByName( "Test SEAD" )
local TargetSet = SET_UNIT:New():FilterPrefixes( "US Hawk SR" ):FilterStart()

local Task_SEAD = TASK2_SEAD:New( Client, Mission, TargetSet )

Task_SEAD:AddScore( "Destroy", "Destroyed RADAR", 25 )
Task_SEAD:AddScore( "Success", "Destroyed all radars!!!", 100 )


