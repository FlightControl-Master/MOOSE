--- The main include file for the MOOSE system.

Include.File( "Routines" )
Include.File( "Database" )
Include.File( "Base" )
Include.File( "Event" )


--- Declare the main database object, which is used internally by the MOOSE classes.
_DATABASE = DATABASE:New():ScanEnvironment() -- Database#DATABASE

--- Declare the event dispatcher based on the EVENT class
_EVENTDISPATCHER = EVENT:New() -- #EVENT