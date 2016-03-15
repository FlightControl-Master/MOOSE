rem Generate Moose_Embedded.lua

copy /b ..\Moose\Trace.lua ^
	+ ..\Moose\Routines.lua ^
    	+ ..\Moose\Base.lua ^
	+ ..\Moose\Menu.lua ^
	+ ..\Moose\Group.lua ^
	+ ..\Moose\Unit.lua ^
	+ ..\Moose\Zone.lua ^
	+ ..\Moose\Database.lua ^
	+ ..\Moose\Cargo.lua ^
	+ ..\Moose\Client.lua ^
	+ ..\Moose\Message.lua ^
	+ ..\Moose\Stage.lua ^
	+ ..\Moose\Task.lua ^
	+ ..\Moose\GoHomeTask.lua ^
	+ ..\Moose\DestroyBaseTask.lua ^
	+ ..\Moose\DestroyGroupsTask.lua ^
	+ ..\Moose\DestroyRadarsTask.lua ^
	+ ..\Moose\DestroyUnitTypesTask.lua ^
	+ ..\Moose\PickupTask.lua ^
	+ ..\Moose\DeployTask.lua ^
	+ ..\Moose\NoTask.lua ^
	+ ..\Moose\RouteTask.lua ^
	+ ..\Moose\Mission.lua ^
	+ ..\Moose\CleanUp.lua ^
	+ ..\Moose\Spawn.lua ^
	+ ..\Moose\Movement.lua ^
	+ ..\Moose\Sead.lua ^
	Moose_Embedded.lua /y
	