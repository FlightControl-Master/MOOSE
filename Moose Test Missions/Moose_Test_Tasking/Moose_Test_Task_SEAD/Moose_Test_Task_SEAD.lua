
local Mission = MISSION:New( 'SEAD Targets', "Strategic", "SEAD the enemy", coalition.side.RED )
local Scoring = SCORING:New( "SEAD" )

Mission:AddScoring( Scoring )

local SEADSet = SET_GROUP:New():FilterPrefixes( "Test SEAD"):FilterStart()
local TargetSet = SET_UNIT:New():FilterPrefixes( "US Hawk SR" ):FilterStart()

local TargetZone = ZONE:New( "Target Zone" )

local TaskSEAD = TASK_SEAD
  :New( Mission, SEADSet, "SEAD Radars", TargetSet, TargetZone )
  
TaskSEAD:AddScore( "Success", "Destroyed all target radars", 250 )
TaskSEAD:AddScore( "Failed", "Failed to destroy all target radars", -100 )

-- ASSIGN_MENU_ACCEPT:New(TaskName,TaskBriefing)
local AssignProcess = TaskSEAD:SetProcessClass( "ASSIGN", ASSIGN_MENU_ACCEPT, "SEAD", "Hello World" )
AssignProcess:AddScore( TaskSEAD, "Assign", "You are assigned to the task", 10 )

-- ACCOUNT_DEADS:New(ProcessUnit,TargetSetUnit,TaskName)
local AccountProcess = TaskSEAD:SetProcessClass( "ACCOUNT", ACCOUNT_DEADS, TargetSet, "SEAD" )
AccountProcess:AddScore( TaskSEAD, "Account", "destroyed a radar", 25 )
AccountProcess:AddScore( TaskSEAD, "Failed", "failed to destroy a radar", -100 )

TaskSEAD:AssignToGroup( SEADSet:Get( "Test SEAD" ) )

