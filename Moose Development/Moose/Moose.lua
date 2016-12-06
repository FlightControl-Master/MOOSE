--- The main include file for the MOOSE system.

--- Core Routines
Include.File( "Utilities/Routines" )
Include.File( "Utilities/Utils" )

--- Core Classes
Include.File( "Core/Base" )
Include.File( "Core/Scheduler" )
Include.File( "Core/Event" )
Include.File( "Core/Menu" )
Include.File( "Core/Zone" )
Include.File( "Core/Database" )
Include.File( "Core/Set" )
Include.File( "Core/Point" )
Include.File( "Core/Message" )

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
Include.File( "Functional/AIBalancer" )

--- Fsm Classes
Include.File( "Fsm/Fsm" )
Include.File( "Fsm/Process" )
Include.File( "Fsm/Process_JTAC" )
Include.File( "Fsm/Patrol" )
Include.File( "Fsm/Cargo" )

--- Process Classes
Include.File( "Process/Assign" )
Include.File( "Process/Route" )
Include.File( "Process/Account" )
Include.File( "Process/Smoke" )

--- Task Handling Classes
Include.File( "Tasking/CommandCenter" )
Include.File( "Tasking/Mission" )
Include.File( "Tasking/Task" )
Include.File( "Tasking/DetectionManager" )
Include.File( "Tasking/Task_SEAD" )
Include.File( "Tasking/Task_A2G" )


-- The order of the declarations is important here. Don't touch it.

--- Declare the event dispatcher based on the EVENT class
_EVENTDISPATCHER = EVENT:New() -- Core.Event#EVENT

--- Declare the main database object, which is used internally by the MOOSE classes.
_DATABASE = DATABASE:New() -- Database#DATABASE

