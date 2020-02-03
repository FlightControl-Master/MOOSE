-- The order of the declarations is important here. Don't touch it.


--- Declare the event dispatcher based on the EVENT class
_EVENTDISPATCHER = EVENT:New() -- Core.Event#EVENT

--- Declare the timer dispatcher based on the SCHEDULEDISPATCHER class
_SCHEDULEDISPATCHER = SCHEDULEDISPATCHER:New() -- Core.ScheduleDispatcher#SCHEDULEDISPATCHER

--- Declare the main database object, which is used internally by the MOOSE classes.
_DATABASE = DATABASE:New() -- Core.Database#DATABASE

_SETTINGS = SETTINGS:Set()
_SETTINGS:SetPlayerMenuOn()

_DATABASE:_RegisterCargos()
_DATABASE:_RegisterZones()
_DATABASE:_RegisterAirbases()

