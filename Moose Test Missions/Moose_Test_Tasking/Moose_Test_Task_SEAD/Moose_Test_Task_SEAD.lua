
local Mission = MISSION:New( 'SEAD Targets', "Strategic", "SEAD the enemy", coalition.side.RED )
local Scoring = SCORING:New( "SEAD" )

Mission:AddScoring( Scoring )

local SEADSet = SET_GROUP:New():FilterPrefixes( "Test SEAD"):FilterStart()
local TargetSet = SET_UNIT:New():FilterPrefixes( "US Hawk SR" ):FilterOnce()

local TargetZone = ZONE:New( "Target Zone" )

local TaskSEAD = TASK_SEAD
  :New( Mission, SEADSet, "SEAD Radars", TargetSet, TargetZone )
  
TaskSEAD:AddScore( "Success", "Destroyed all target radars", 250 )
TaskSEAD:AddScore( "Failed", "Failed to destroy all target radars", -100 )

local AssignProcess = TaskSEAD:SetProcessTemplate( "ASSIGN", PROCESS_ASSIGN_MENU_ACCEPT:New( "SEAD", "Hello World" ) )
AssignProcess:AddScore( TaskSEAD, "Assign", "You are assigned to the task", 10 )

local AccountProcess = TaskSEAD:SetProcessTemplate( "ACCOUNT", PROCESS_ACCOUNT_DEADS:New( TargetSet, "SEAD" ) )
AccountProcess:AddScore( TaskSEAD, "Account", "destroyed a radar", 25 )
AccountProcess:AddScore( TaskSEAD, "Failed", "failed to destroy a radar", -100 )

--local SmokeProcess = TaskSEAD:SetProcessTemplate( "SMOKE", PROCESS_SMOKE_TARGETS_ZONE:New( TargetSet, TargetZone ) )
--SmokeProcess:SetAttackGroup( GROUP:FindByName( "SmokeGroup" ), "Watchdog" )
--SmokeProcess:AddScore( TaskSEAD, "Account", "destroyed a radar", 25 )
--SmokeProcess:AddScore( TaskSEAD, "Failed", "failed to destroy a radar", -100 )

TaskSEAD:AssignToGroup( SEADSet:Get( "Test SEAD" ) )

