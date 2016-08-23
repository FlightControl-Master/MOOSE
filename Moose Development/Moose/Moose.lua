--- The main include file for the MOOSE system.

--- Core Routines
Include.File( "Routines" )
Include.File( "Utils" )

--- Core Classes
Include.File( "Base" )
Include.File( "Object" )
Include.File( "Identifiable" )
Include.File( "Positionable" )
Include.File( "Controllable" )
Include.File( "Scheduler" )
Include.File( "Event" )
Include.File( "Menu" )
Include.File( "Group" )
Include.File( "Unit" )
Include.File( "Zone" )
Include.File( "Client" )
Include.File( "Static" )
Include.File( "Airbase" )
Include.File( "Database" )
Include.File( "Set" )
Include.File( "Point" )
Include.File( "Scoring" )

--- Functional Classes
Include.File( "Cargo" )
Include.File( "Message" )
Include.File( "Mission" )
Include.File( "CleanUp" )
Include.File( "Spawn" )
Include.File( "Movement" )
Include.File( "Sead" )
Include.File( "Escort" )
Include.File( "MissileTrainer" )
--Include.File( "AIBalancer" )
Include.File( "AirbasePolice" )
Include.File( "Detection" )

--- Task Handling Classes
Include.File( "DetectionManager" )

Include.File( "StateMachine" )

Include.File( "Process" )
Include.File( "Process_Assign" )
Include.File( "Process_Route" )
Include.File( "Process_Smoke" )
Include.File( "Process_Destroy" )
Include.File( "Process_JTAC" )

Include.File( "Task" )
Include.File( "Task_SEAD" )
Include.File( "Task_A2G" )

--- AI Handling Classes
Include.File( "AI_PatrolZone" )

-- The order of the declarations is important here. Don't touch it.

--- Declare the event dispatcher based on the EVENT class
_EVENTDISPATCHER = EVENT:New() -- Event#EVENT

--- Declare the main database object, which is used internally by the MOOSE classes.
_DATABASE = DATABASE:New() -- Database#DATABASE

