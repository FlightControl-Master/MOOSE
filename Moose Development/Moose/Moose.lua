--- The main include file for the MOOSE system.

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Scheduler" )
Include.File( "Event" )
Include.File( "Menu" )
Include.File( "Group" )
Include.File( "Unit" )
Include.File( "Zone" )
Include.File( "Client" )
Include.File( "Static" )
Include.File( "Database" )
Include.File( "Set" )
Include.File( "Point" )
Include.File( "Moose" )
Include.File( "Scoring" )
Include.File( "Cargo" )
Include.File( "Message" )
Include.File( "Stage" )
Include.File( "Task" )
Include.File( "GoHomeTask" )
Include.File( "DestroyBaseTask" )
Include.File( "DestroyGroupsTask" )
Include.File( "DestroyRadarsTask" )
Include.File( "DestroyUnitTypesTask" )
Include.File( "PickupTask" )
Include.File( "DeployTask" )
Include.File( "NoTask" )
Include.File( "RouteTask" )
Include.File( "Mission" )
Include.File( "CleanUp" )
Include.File( "Spawn" )
Include.File( "Movement" )
Include.File( "Sead" )
Include.File( "Escort" )
Include.File( "MissileTrainer" )
Include.File( "AIBalancer" )



































-- The order of the declarations is important here. Don't touch it.

--- Declare the event dispatcher based on the EVENT class
_EVENTDISPATCHER = EVENT:New() -- #EVENT

--- Declare the main database object, which is used internally by the MOOSE classes.
_DATABASE = DATABASE:New() -- Database#DATABASE

