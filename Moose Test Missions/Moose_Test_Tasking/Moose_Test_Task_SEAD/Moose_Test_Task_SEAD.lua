
env.info( "Lua Version = " .. _VERSION )

local Mission = MISSION:New( 'SEAD Targets', "Strategic", "SEAD the enemy", coalition.side.RED )
local Scoring = SCORING:New( "SEAD" )

Mission:AddScoring( Scoring )

local SEADSet = SET_GROUP:New():FilterPrefixes( "Test SEAD"):FilterStart()
local TargetSet = SET_UNIT:New():FilterPrefixes( "US Hawk SR" ):FilterOnce()

local TargetZone = ZONE:New( "Target Zone" )

local TaskSEAD = TASK_BASE:New( Mission, SEADSet, "SEAD Radars", "A2G", "SEAD" ) -- Tasking.Task#TASK_BASE
  --:New( Mission, SEADSet, "SEAD Radars", TargetSet, TargetZone )
  
local FsmSEAD = TaskSEAD:GetFsmTemplate()

FsmSEAD:AddProcess( "Planned",    "Accept",   PROCESS_ASSIGN_ACCEPT:New( "SEAD the Area" ), { Assigned = "Route", Rejected = "Eject" } )
FsmSEAD:AddProcess( "Assigned",   "Route",    PROCESS_ROUTE_ZONE:New( TargetZone, 3000 ), { Arrived = "Update" } )
FsmSEAD:AddAction ( "Rejected",   "Eject",    "Planned" )
FsmSEAD:AddAction ( "Arrived",    "Update",   "Updated" ) 
FsmSEAD:AddProcess( "Updated",    "Account",  PROCESS_ACCOUNT_DEADS:New( TargetSet, "SEAD" ), { Accounted = "Success" } )
FsmSEAD:AddProcess( "Updated",    "Smoke",    PROCESS_SMOKE_TARGETS_ZONE:New( TargetSet, TargetZone ) )
FsmSEAD:AddAction ( "Accounted",  "Success",  "Success" )
FsmSEAD:AddAction ( "Failed",     "Fail",     "Failed" )

TaskSEAD:AddScoreTask( "Success", "Destroyed all target radars", 250 )
TaskSEAD:AddScoreTask( "Failed", "Failed to destroy all target radars", -100 )
TaskSEAD:AddScoreProcess( "Account", "Account", "destroyed a radar", 25 )
TaskSEAD:AddScoreProcess( "Account", "Fail", "failed to destroy a radar", -100 )

function FsmSEAD:onenterUpdated( TaskUnit )
  self:E( { self } )
  self:Account()
  self:Smoke()
end

-- Needs to be checked, should not be necessary ...
TaskSEAD:AssignToGroup( SEADSet:Get( "Test SEAD" ) )

Mission:AddTask( TaskSEAD )
