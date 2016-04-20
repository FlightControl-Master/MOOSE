--- The EVENT class models an efficient event handling process between other classes and its units, weapons.
-- @module Event
-- @author FlightControl

Include.File( "Routines" )
Include.File( "Base" )

--- The EVENT structure
-- @type EVENT
-- @field #EVENT.Events Events
EVENT = {
  ClassName = "EVENT",
  ClassID = 0,
}

local EVENTCODES = {
   "S_EVENT_SHOT",
   "S_EVENT_HIT",
   "S_EVENT_TAKEOFF",
   "S_EVENT_LAND",
   "S_EVENT_CRASH",
   "S_EVENT_EJECTION",
   "S_EVENT_REFUELING",
   "S_EVENT_DEAD",
   "S_EVENT_PILOT_DEAD",
   "S_EVENT_BASE_CAPTURED",
   "S_EVENT_MISSION_START",
   "S_EVENT_MISSION_END",
   "S_EVENT_TOOK_CONTROL",
   "S_EVENT_REFUELING_STOP",
   "S_EVENT_BIRTH",
   "S_EVENT_HUMAN_FAILURE",
   "S_EVENT_ENGINE_STARTUP",
   "S_EVENT_ENGINE_SHUTDOWN",
   "S_EVENT_PLAYER_ENTER_UNIT",
   "S_EVENT_PLAYER_LEAVE_UNIT",
   "S_EVENT_PLAYER_COMMENT",
   "S_EVENT_SHOOTING_START",
   "S_EVENT_SHOOTING_END",
   "S_EVENT_MAX",
}


--- The Events structure
-- @type EVENT.Events
-- @field #number IniUnit

function EVENT:New()
  local self = BASE:Inherit( self, BASE:New() )
  self:F()
  self.EventHandler = world.addEventHandler( self )
  return self
end


--- Initializes the Events structure for the event
-- @param #EVENT self
-- @param DCSWorld#world.event EventID
-- @param #string EventClass
-- @return #EVENT.Events
function EVENT:Init( EventID, EventClass )
  self:F( EventID, EventClass )
  if not self.Events[EventID] then
    self.Events[EventID] = {}
  end
  if not self.Events[EventID][EventClass] then
     self.Events[EventID][EventClass] = {}
  end
  if not self.Events[EventID][EventClass].IniUnit then
    self.Events[EventID][EventClass].IniUnit = {}
  end
  return self.Events[EventID][EventClass]
end


--- Create an OnDead event handler for a group
-- @param #EVENT self
-- @param #table EventTemplate
-- @param #function EventFunction The function to be called when the event occurs for the unit.
-- @param EventSelf The self instance of the class for which the event is.
-- @param #function OnEventFunction
-- @return #EVENT
function EVENT:OnEventForTemplate( EventTemplate, EventFunction, EventSelf, OnEventFunction )
  self:F( EventTemplate )

  for EventUnitID, EventUnit in pairs( EventTemplate.units ) do
    OnEventFunction( self, EventUnit.name, EventFunction, EventSelf )
  end
  return self
end


--- Set a new listener for an S_EVENT_X event
-- @param #EVENT self
-- @param #string EventDCSUnitName
-- @param #function EventFunction The function to be called when the event occurs for the unit.
-- @param Base#BASE EventSelf The self instance of the class for which the event is.
-- @param EventID
-- @return #EVENT
function EVENT:OnEventForUnit( EventDCSUnitName, EventFunction, EventSelf, EventID )
  self:F( EventDCSUnitName )

  local Event = self:Init( EventID, EventSelf:GetClassNameAndID() )
  Event.IniUnit[EventDCSUnitName] = {}
  Event.IniUnit[EventDCSUnitName].EventFunction = EventFunction
  Event.IniUnit[EventDCSUnitName].EventSelf = EventSelf
  return self
end


--- Create an OnBirth event handler for a group
-- @param #EVENT self
-- @param Group#GROUP EventGroup
-- @param #function EventFunction The function to be called when the event occurs for the unit.
-- @param EventSelf The self instance of the class for which the event is.
-- @return #EVENT
function EVENT:OnBirthForTemplate( EventTemplate, EventFunction, EventSelf )
  self:F( { EventTemplate } )

  return self:OnEventForTemplate( EventTemplate, EventFunction, EventSelf, self.OnBirth )
end

--- Set a new listener for an S_EVENT_BIRTH event.
-- @param #EVENT self
-- @param #string EventDCSUnitName The id of the unit for the event to be handled.
-- @param #function EventFunction The function to be called when the event occurs for the unit.
-- @param Base#BASE EventSelf
-- @return #EVENT
function EVENT:OnBirth( EventDCSUnitName, EventFunction, EventSelf )
  self:F( EventDCSUnitName )
  
  return self:OnEventForUnit( EventDCSUnitName, EventFunction, EventSelf, world.event.S_EVENT_BIRTH )
end

--- Create an OnCrash event handler for a group
-- @param #EVENT self
-- @param Group#GROUP EventGroup
-- @param #function EventFunction The function to be called when the event occurs for the unit.
-- @param EventSelf The self instance of the class for which the event is.
-- @return #EVENT
function EVENT:OnCrashForTemplate( EventTemplate, EventFunction, EventSelf )
  self:F( EventTemplate )

  return self:OnEventForTemplate( EventTemplate, EventFunction, EventSelf, self.OnCrash )
end

--- Set a new listener for an S_EVENT_CRASH event.
-- @param #EVENT self
-- @param #string EventDCSUnitName
-- @param #function EventFunction The function to be called when the event occurs for the unit.
-- @param Base#BASE EventSelf The self instance of the class for which the event is.
-- @return #EVENT
function EVENT:OnCrash( EventDCSUnitName, EventFunction, EventSelf )
  self:F( EventDCSUnitName )

  return self:OnEventForUnit( EventDCSUnitName, EventFunction, EventSelf, world.event.S_EVENT_CRASH )
end

--- Create an OnDead event handler for a group
-- @param #EVENT self
-- @param Group#GROUP EventGroup
-- @param #function EventFunction The function to be called when the event occurs for the unit.
-- @param EventSelf The self instance of the class for which the event is.
-- @return #EVENT
function EVENT:OnDeadForTemplate( EventTemplate, EventFunction, EventSelf )
  self:F( EventTemplate )

  return self:OnEventForTemplate( EventTemplate, EventFunction, EventSelf, self.OnDead )
end

--- Set a new listener for an S_EVENT_DEAD event.
-- @param #EVENT self
-- @param #string EventDCSUnitName
-- @param #function EventFunction The function to be called when the event occurs for the unit.
-- @param Base#BASE EventSelf The self instance of the class for which the event is.
-- @return #EVENT
function EVENT:OnDead( EventDCSUnitName, EventFunction, EventSelf )
  self:F( EventDCSUnitName )

  return self:OnEventForUnit( EventDCSUnitName, EventFunction, EventSelf, world.event.S_EVENT_DEAD )
end

--- Create an OnDead event handler for a group
-- @param #EVENT self
-- @param #table EventTemplate
-- @param #function EventFunction The function to be called when the event occurs for the unit.
-- @param EventSelf The self instance of the class for which the event is.
-- @return #EVENT
function EVENT:OnLandForTemplate( EventTemplate, EventFunction, EventSelf )
  self:F( EventTemplate )

  return self:OnEventForTemplate( EventTemplate, EventFunction, EventSelf, self.OnLand )
end

--- Set a new listener for an S_EVENT_LAND event.
-- @param #EVENT self
-- @param #string EventDCSUnitName
-- @param #function EventFunction The function to be called when the event occurs for the unit.
-- @param Base#BASE EventSelf The self instance of the class for which the event is.
-- @return #EVENT
function EVENT:OnLand( EventDCSUnitName, EventFunction, EventSelf )
  self:F( EventDCSUnitName )

  return self:OnEventForUnit( EventDCSUnitName, EventFunction, EventSelf, world.event.S_EVENT_LAND )
end

--- Create an OnDead event handler for a group
-- @param #EVENT self
-- @param #table EventTemplate
-- @param #function EventFunction The function to be called when the event occurs for the unit.
-- @param EventSelf The self instance of the class for which the event is.
-- @return #EVENT
function EVENT:OnTakeOffForTemplate( EventTemplate, EventFunction, EventSelf )
  self:F( EventTemplate )

  return self:OnEventForTemplate( EventTemplate, EventFunction, EventSelf, self.OnTakeOff )
end

--- Set a new listener for an S_EVENT_LAND event.
-- @param #EVENT self
-- @param #string EventDCSUnitName
-- @param #function EventFunction The function to be called when the event occurs for the unit.
-- @param Base#BASE EventSelf The self instance of the class for which the event is.
-- @return #EVENT
function EVENT:OnTakeOff( EventDCSUnitName, EventFunction, EventSelf )
  self:F( EventDCSUnitName )

  return self:OnEventForUnit( EventDCSUnitName, EventFunction, EventSelf, world.event.S_EVENT_TAKEOFF )
end

--- Create an OnDead event handler for a group
-- @param #EVENT self
-- @param #table EventTemplate
-- @param #function EventFunction The function to be called when the event occurs for the unit.
-- @param EventSelf The self instance of the class for which the event is.
-- @return #EVENT
function EVENT:OnEngineShutDownForTemplate( EventTemplate, EventFunction, EventSelf )
  self:F( EventTemplate )

  return self:OnEventForTemplate( EventTemplate, EventFunction, EventSelf, self.OnEngineShutDown )
end

--- Set a new listener for an S_EVENT_LAND event.
-- @param #EVENT self
-- @param #string EventDCSUnitName
-- @param #function EventFunction The function to be called when the event occurs for the unit.
-- @param Base#BASE EventSelf The self instance of the class for which the event is.
-- @return #EVENT
function EVENT:OnEngineShutDown( EventDCSUnitName, EventFunction, EventSelf )
  self:F( EventDCSUnitName )

  return self:OnEventForUnit( EventDCSUnitName, EventFunction, EventSelf, world.event.S_EVENT_ENGINE_SHUTDOWN )
end



function EVENT:onEvent( Event )
  self:F( { EVENTCODES[Event.id], Event } )

  if self and self.Events and self.Events[Event.id] then
    local IniDCSUnit = Event.initiator
    if IniDCSUnit and IniDCSUnit:getCategory() == Object.Category.UNIT then
      Event.IniUnitName = IniDCSUnit:getName()
    end
    local TgtDCSUnit = Event.target
    if TgtDCSUnit and TgtDCSUnit:isExist() and TgtDCSUnit:getCategory() == Object.Category.UNIT then
      Event.TgtUnitName = TgtDCSUnit:getName()
    end
    for ClassName, EventData in pairs( self.Events[Event.id] ) do
      if Event.IniUnitName and EventData.IniUnit and EventData.IniUnit[Event.IniUnitName] then 
        self:T( { "Calling event function for class ", ClassName, " unit ", Event.IniUnitName } )
        EventData.IniUnit[Event.IniUnitName].EventFunction( EventData.IniUnit[Event.IniUnitName].EventSelf, Event )
      end
    end
  end
end



--- Declare the event dispatcher based on the EVENT class
_EventDispatcher = EVENT:New() -- #EVENT

