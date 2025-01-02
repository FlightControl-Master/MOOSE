--- GLOBALS: The order of the declarations is important here. Don't touch it.

--- Declare the event dispatcher based on the EVENT class
_EVENTDISPATCHER = EVENT:New() -- Core.Event#EVENT

--- Declare the timer dispatcher based on the SCHEDULEDISPATCHER class
_SCHEDULEDISPATCHER = SCHEDULEDISPATCHER:New() -- Core.ScheduleDispatcher#SCHEDULEDISPATCHER

--- Declare the main database object, which is used internally by the MOOSE classes.
_DATABASE = DATABASE:New() -- Core.Database#DATABASE

--- Settings
_SETTINGS = SETTINGS:Set() -- Core.Settings#SETTINGS
_SETTINGS:SetPlayerMenuOn()

--- Register cargos.
_DATABASE:_RegisterCargos()

--- Register zones.
_DATABASE:_RegisterZones()
_DATABASE:_RegisterAirbases()

--- Check if os etc is available.
BASE:I("Checking de-sanitization of os, io and lfs:")
local __na = false
if os then
  BASE:I("- os available")
else
  BASE:I("- os NOT available! Some functions may not work.")
  __na = true
end
if io then
  BASE:I("- io available")
else
  BASE:I("- io NOT available! Some functions may not work.")
  __na = true
end
if lfs then
  BASE:I("- lfs available")
else
  BASE:I("- lfs NOT available! Some functions may not work.")
  __na = true
end
if __na then
  BASE:I("Check <DCS install folder>/Scripts/MissionScripting.lua and comment out the lines with sanitizeModule(''). Use at your own risk!)")
end
BASE.ServerName = "Unknown"
if lfs and loadfile then
  local serverfile = lfs.writedir() .. 'Config/serverSettings.lua'
  if UTILS.FileExists(serverfile) then
    loadfile(serverfile)()
    if cfg and cfg.name then
      BASE.ServerName = cfg.name
    end
  end
  BASE.ServerName = BASE.ServerName or "Unknown"
  BASE:I("Server Name: " .. tostring(BASE.ServerName))
end
