rem Generate Moose_Embedded.lua

copy /b Trace.lua ^
	+ Routines.lua ^
    + Base.lua ^
	+ Menu.lua ^
	+ Group.lua ^
	+ Unit.lua ^
	+ Zone.lua ^
	+ Database.lua ^
	+ Cargo.lua ^
	+ Client.lua ^
	+ Message.lua ^
	+ Stage.lua ^
	+ Task.lua ^
	+ GoHomeTask.lua ^
	+ DestroyBaseTask.lua ^
	+ DestroyGroupsTask.lua ^
	+ DestroyRadarsTask.lua ^
	+ DestroyUnitTypesTask.lua ^
	+ PickupTask.lua ^
	+ DeployTask.lua ^
	+ NoTask.lua ^
	+ RouteTask.lua ^
	+ Mission.lua ^
	+ CleanUp.lua ^
	+ Spawn.lua ^
	+ Movement.lua ^
	+ Sead.lua ^
	Moose_Embedded.lua /y
	