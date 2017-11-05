-- The order of the declarations is important here. Don't touch it.

--- Declare the event dispatcher based on the EVENT class
_EVENTDISPATCHER = EVENT:New() -- Core.Event#EVENT

--- Declare the timer dispatcher based on the SCHEDULEDISPATCHER class
_SCHEDULEDISPATCHER = SCHEDULEDISPATCHER:New() -- Core.Timer#SCHEDULEDISPATCHER

--- Declare the main database object, which is used internally by the MOOSE classes.
_DATABASE = DATABASE:New() -- Core.Database#DATABASE

_SETTINGS = SETTINGS:Set()

local initconnection = require("debugger")
initconnection( "127.0.0.1", 10000, "dcsserver", nil, nil, "C:\Program Files\Eagle Dynamics\DCS World" )

print("hello")
