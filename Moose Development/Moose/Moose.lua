--- The main include file for the MOOSE system.

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Database" )
Include.File( "Event" )

-- The order of the declarations is important here. Don't touch it.

--- Declare the event dispatcher based on the EVENT class
_EVENTDISPATCHER = EVENT:New() -- #EVENT

--- Declare the main database object, which is used internally by the MOOSE classes.
_DATABASE = DATABASE:New() -- Database#DATABASE

