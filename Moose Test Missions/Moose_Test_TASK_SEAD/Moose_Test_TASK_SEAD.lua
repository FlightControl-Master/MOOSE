
local Client = CLIENT:FindByName( "Test SEAD" )
local TargetSet = SET_UNIT:New():FilterPrefixes( "US Hawk SR" ):FilterStart()

local Task_SEAD = TASK2_SEAD:New( Client, TargetSet )
