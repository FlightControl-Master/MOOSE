--- The main include file for the MOOSE system.
-- Test of permissions

--- Core Routines
Include.File( "Utilities/Routines" )
Include.File( "Utilities/Utils" )

--- Core Classes
Include.File( "Core/Base" )
Include.File( "Core/Scheduler" )
Include.File( "Core/ScheduleDispatcher")
Include.File( "Core/Event" )
Include.File( "Core/Menu" )
Include.File( "Core/Zone" )
Include.File( "Core/Database" )
Include.File( "Core/Set" )
Include.File( "Core/Point" )
Include.File( "Core/Message" )
Include.File( "Core/Fsm" )
Include.File( "Core/Radio" )

--- Wrapper Classes
Include.File( "Wrapper/Object" )
Include.File( "Wrapper/Identifiable" )
Include.File( "Wrapper/Positionable" )
Include.File( "Wrapper/Controllable" )
Include.File( "Wrapper/Group" )
Include.File( "Wrapper/Unit" )
Include.File( "Wrapper/Client" )
Include.File( "Wrapper/Static" )
Include.File( "Wrapper/Airbase" )
Include.File( "Wrapper/Scenery" )

--- Functional Classes
Include.File( "Functional/Scoring" )
Include.File( "Functional/CleanUp" )
Include.File( "Functional/Spawn" )
Include.File( "Functional/Movement" )
Include.File( "Functional/Sead" )
Include.File( "Functional/Escort" )
Include.File( "Functional/MissileTrainer" )
Include.File( "Functional/AirbasePolice" )
Include.File( "Functional/Detection" )

--- AI Classes
Include.File( "AI/AI_Balancer" )
Include.File( "AI/AI_Patrol" )
Include.File( "AI/AI_Cap" )
Include.File( "AI/AI_Cas" )
Include.File( "AI/AI_Cargo" )

--- Actions
Include.File( "Actions/Act_Assign" )
Include.File( "Actions/Act_Route" )
Include.File( "Actions/Act_Account" )
Include.File( "Actions/Act_Assist" )

--- Task Handling Classes
Include.File( "Tasking/CommandCenter" )
Include.File( "Tasking/Mission" )
Include.File( "Tasking/Task" )
Include.File( "Tasking/DetectionManager" )
Include.File( "Tasking/Task_A2G_Dispatcher")
Include.File( "Tasking/Task_A2G" )


-- The order of the declarations is important here. Don't touch it.

--- Declare the event dispatcher based on the EVENT class
_EVENTDISPATCHER = EVENT:New() -- Core.Event#EVENT

--- Declare the timer dispatcher based on the SCHEDULEDISPATCHER class
_SCHEDULEDISPATCHER = SCHEDULEDISPATCHER:New() -- Core.Timer#SCHEDULEDISPATCHER

--- Declare the main database object, which is used internally by the MOOSE classes.
_DATABASE = DATABASE:New() -- Database#DATABASE



