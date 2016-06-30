local FACGroup = GROUP:FindByName( "FAC Group" )

local FACDetection = DETECTION_UNITGROUPS:New( FACGroup, 1000, 250 )

local SeadClientSet = SET_CLIENT:New():FilterCoalitions( "blue" ):FilterStart()

local DestroyClientSet = SET_CLIENT:New():FilterCoalitions( "blue" ):FilterStart()

local Targets_SEAD_Set = SET_UNIT:New():FilterCoalitions( "red" ):FilterPrefixes( "RU Patriot" ):FilterStart()
local Targets_SEAD = TARGETS:New( "SEAD", Targets_SEAD_Set )

local TaskAssign = TASK_DISPATCHER:New( CommmandCenter, SeadClientSet, FACDetection, Targets_SEAD )

