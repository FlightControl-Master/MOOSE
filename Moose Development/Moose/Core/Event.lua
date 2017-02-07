--- This module contains the **EVENT** class, which models the dispatching of DCS Events to subscribed MOOSE classes,
-- following a given priority.
-- 
-- ## 
-- 
-- ![Banner Image](..\Presentations\FSM\Dia1.JPG)
-- 
-- ===
-- 
--- This module contains the EVENT class.
-- 
-- ===
-- 
-- Takes care of EVENT dispatching between DCS events and event handling functions defined in MOOSE classes.
-- 
-- ===
-- 
-- The above menus classes **are derived** from 2 main **abstract** classes defined within the MOOSE framework (so don't use these):
-- 
-- ===
-- 
-- ### Contributions: -
-- ### Authors: FlightControl : Design & Programming
-- 
-- @module Event

--- The EVENT structure
-- @type EVENT
-- @field #EVENT.Events Events
-- @extends Core.Base#BASE
EVENT = {
  ClassName = "EVENT",
  ClassID = 0,
}

EVENTS = {
  Shot =              world.event.S_EVENT_SHOT,
  Hit =               world.event.S_EVENT_HIT,
  Takeoff =           world.event.S_EVENT_TAKEOFF,
  Land =              world.event.S_EVENT_LAND,
  Crash =             world.event.S_EVENT_CRASH,
  Ejection =          world.event.S_EVENT_EJECTION,
  Refueling =         world.event.S_EVENT_REFUELING,
  Dead =              world.event.S_EVENT_DEAD,
  PilotDead =         world.event.S_EVENT_PILOT_DEAD,
  BaseCaptured =      world.event.S_EVENT_BASE_CAPTURED,
  MissionStart =      world.event.S_EVENT_MISSION_START,
  MissionEnd =        world.event.S_EVENT_MISSION_END,
  TookControl =       world.event.S_EVENT_TOOK_CONTROL,
  RefuelingStop =     world.event.S_EVENT_REFUELING_STOP,
  Birth =             world.event.S_EVENT_BIRTH,
  HumanFailure =      world.event.S_EVENT_HUMAN_FAILURE,
  EngineStartup =     world.event.S_EVENT_ENGINE_STARTUP,
  EngineShutdown =    world.event.S_EVENT_ENGINE_SHUTDOWN,
  PlayerEnterUnit =   world.event.S_EVENT_PLAYER_ENTER_UNIT,
  PlayerLeaveUnit =   world.event.S_EVENT_PLAYER_LEAVE_UNIT,
  PlayerComment =     world.event.S_EVENT_PLAYER_COMMENT,
  ShootingStart =     world.event.S_EVENT_SHOOTING_START,
  ShootingEnd =       world.event.S_EVENT_SHOOTING_END,
}


local _EVENTMETA = {
   [world.event.S_EVENT_SHOT] = {
     Order = 1,
     Event = "OnEventShot",
     Text = "S_EVENT_SHOT" 
   },
   [world.event.S_EVENT_HIT] = {
     Order = 1,
     Event = "OnEventHit",
     Text = "S_EVENT_HIT" 
   },
   [world.event.S_EVENT_TAKEOFF] = {
     Order = 1,
     Event = "OnEventTakeOff",
     Text = "S_EVENT_TAKEOFF" 
   },
   [world.event.S_EVENT_LAND] = {
     Order = 1,
     Event = "OnEventLand",
     Text = "S_EVENT_LAND" 
   },
   [world.event.S_EVENT_CRASH] = {
     Order = -1,
     Event = "OnEventCrash",
     Text = "S_EVENT_CRASH" 
   },
   [world.event.S_EVENT_EJECTION] = {
     Order = 1,
     Event = "OnEventEjection",
     Text = "S_EVENT_EJECTION" 
   },
   [world.event.S_EVENT_REFUELING] = {
     Order = 1,
     Event = "OnEventRefueling",
     Text = "S_EVENT_REFUELING" 
   },
   [world.event.S_EVENT_DEAD] = {
     Order = -1,
     Event = "OnEventDead",
     Text = "S_EVENT_DEAD" 
   },
   [world.event.S_EVENT_PILOT_DEAD] = {
     Order = 1,
     Event = "OnEventPilotDead",
     Text = "S_EVENT_PILOT_DEAD" 
   },
   [world.event.S_EVENT_BASE_CAPTURED] = {
     Order = 1,
     Event = "OnEventBaseCaptured",
     Text = "S_EVENT_BASE_CAPTURED" 
   },
   [world.event.S_EVENT_MISSION_START] = {
     Order = 1,
     Event = "OnEventMissionStart",
     Text = "S_EVENT_MISSION_START" 
   },
   [world.event.S_EVENT_MISSION_END] = {
     Order = 1,
     Event = "OnEventMissionEnd",
     Text = "S_EVENT_MISSION_END" 
   },
   [world.event.S_EVENT_TOOK_CONTROL] = {
     Order = 1,
     Event = "OnEventTookControl",
     Text = "S_EVENT_TOOK_CONTROL" 
   },
   [world.event.S_EVENT_REFUELING_STOP] = {
     Order = 1,
     Event = "OnEventRefuelingStop",
     Text = "S_EVENT_REFUELING_STOP" 
   },
   [world.event.S_EVENT_BIRTH] = {
     Order = 1,
     Event = "OnEventBirth",
     Text = "S_EVENT_BIRTH" 
   },
   [world.event.S_EVENT_HUMAN_FAILURE] = {
     Order = 1,
     Event = "OnEventHumanFailure",
     Text = "S_EVENT_HUMAN_FAILURE" 
   },
   [world.event.S_EVENT_ENGINE_STARTUP] = {
     Order = 1,
     Event = "OnEventEngineStartup",
     Text = "S_EVENT_ENGINE_STARTUP" 
   },
   [world.event.S_EVENT_ENGINE_SHUTDOWN] = {
     Order = 1,
     Event = "OnEventEngineShutdown",
     Text = "S_EVENT_ENGINE_SHUTDOWN" 
   },
   [world.event.S_EVENT_PLAYER_ENTER_UNIT] = {
     Order = 1,
     Event = "OnEventPlayerEnterUnit",
     Text = "S_EVENT_PLAYER_ENTER_UNIT" 
   },
   [world.event.S_EVENT_PLAYER_LEAVE_UNIT] = {
     Order = 1,
     Event = "OnEventPlayerLeaveUnit",
     Text = "S_EVENT_PLAYER_LEAVE_UNIT" 
   },
   [world.event.S_EVENT_PLAYER_COMMENT] = {
     Order = 1,
     Event = "OnEventPlayerComment",
     Text = "S_EVENT_PLAYER_COMMENT" 
   },
   [world.event.S_EVENT_SHOOTING_START] = {
     Order = 1,
     Event = "OnEventShootingStart",
     Text = "S_EVENT_SHOOTING_START" 
   },
   [world.event.S_EVENT_SHOOTING_END] = {
     Order = 1,
     Event = "OnEventShootingEnd",
     Text = "S_EVENT_SHOOTING_END" 
   },
}

--- The Event structure
-- @type EVENTDATA
-- @field id
-- @field initiator
-- @field target
-- @field weapon
-- @field IniDCSUnit
-- @field IniDCSUnitName
-- @field Wrapper.Unit#UNIT           IniUnit
-- @field #string             IniUnitName
-- @field IniDCSGroup
-- @field IniDCSGroupName
-- @field TgtDCSUnit
-- @field TgtDCSUnitName
-- @field Wrapper.Unit#UNIT           TgtUnit
-- @field #string             TgtUnitName
-- @field TgtDCSGroup
-- @field TgtDCSGroupName
-- @field Weapon
-- @field WeaponName
-- @field WeaponTgtDCSUnit

--- The Events structure
-- @type EVENT.Events
-- @field #number IniUnit

function EVENT:New()
  local self = BASE:Inherit( self, BASE:New() )
  self:F2()
  self.EventHandler = world.addEventHandler( self )
  return self
end

function EVENT:EventText( EventID )

  local EventText = _EVENTMETA[EventID].Text
  
  return EventText
end


--- Initializes the Events structure for the event
-- @param #EVENT self
-- @param Dcs.DCSWorld#world.event EventID
-- @param Core.Base#BASE EventClass
-- @return #EVENT.Events
function EVENT:Init( EventID, EventClass )
  self:F3( { _EVENTMETA[EventID].Text, EventClass } )

  if not self.Events[EventID] then 
    -- Create a WEAK table to ensure that the garbage collector is cleaning the event links when the object usage is cleaned.
    self.Events[EventID] = setmetatable( {}, { __mode = "k" } )
  end
  
  -- Each event has a subtable of EventClasses, ordered by EventPriority.
  local EventPriority = EventClass:GetEventPriority()
  if not self.Events[EventID][EventPriority] then
    self.Events[EventID][EventPriority] = {}
  end 

  if not self.Events[EventID][EventPriority][EventClass] then
     self.Events[EventID][EventPriority][EventClass] = setmetatable( {}, { __mode = "k" } )
  end
  return self.Events[EventID][EventPriority][EventClass]
end

--- Removes an Events entry
-- @param #EVENT self
-- @param Core.Base#BASE EventClass The self instance of the class for which the event is.
-- @param Dcs.DCSWorld#world.event EventID
-- @return #EVENT.Events
function EVENT:Remove( EventClass, EventID  )
  self:F3( { EventClass, _EVENTMETA[EventID].Text } )

  local EventClass = EventClass
  local EventPriority = EventClass:GetEventPriority()
  self.Events[EventID][EventPriority][EventClass] = nil
end

--- Removes an Events entry for a Unit
-- @param #EVENT self
-- @param Core.Base#BASE EventClass The self instance of the class for which the event is.
-- @param Dcs.DCSWorld#world.event EventID
-- @return #EVENT.Events
function EVENT:RemoveForUnit( UnitName, EventClass, EventID  )
  self:F3( { EventClass, _EVENTMETA[EventID].Text } )

  local EventClass = EventClass
  local EventPriority = EventClass:GetEventPriority()
  local Event = self.Events[EventID][EventPriority][EventClass]
  Event.IniUnit[UnitName] = nil
end

--- Clears all event subscriptions for a @{Base#BASE} derived object.
-- @param #EVENT self
-- @param Core.Base#BASE EventObject
function EVENT:RemoveAll( EventObject  )
  self:F3( { EventObject:GetClassNameAndID() } )

  local EventClass = EventObject:GetClassNameAndID()
  local EventPriority = EventClass:GetEventPriority()
  for EventID, EventData in pairs( self.Events ) do
    self.Events[EventID][EventPriority][EventClass] = nil
  end
end



--- Create an OnDead event handler for a group
-- @param #EVENT self
-- @param #table EventTemplate
-- @param #function EventFunction The function to be called when the event occurs for the unit.
-- @param EventClass The instance of the class for which the event is.
-- @param #function OnEventFunction
-- @return #EVENT
function EVENT:OnEventForTemplate( EventTemplate, EventFunction, EventClass, OnEventFunction )
  self:F2( EventTemplate.name )

  for EventUnitID, EventUnit in pairs( EventTemplate.units ) do
    OnEventFunction( self, EventUnit.name, EventFunction, EventClass )
  end
  return self
end

--- Set a new listener for an S_EVENT_X event independent from a unit or a weapon.
-- @param #EVENT self
-- @param #function EventFunction The function to be called when the event occurs for the unit.
-- @param Core.Base#BASE EventClass The self instance of the class for which the event is captured. When the event happens, the event process will be called in this class provided.
-- @param EventID
-- @return #EVENT
function EVENT:OnEventGeneric( EventFunction, EventClass, EventID )
  self:F2( { EventID } )

  local Event = self:Init( EventID, EventClass )
  Event.EventFunction = EventFunction
  Event.EventClass = EventClass
  
  return self
end


--- Set a new listener for an S_EVENT_X event
-- @param #EVENT self
-- @param #string EventDCSUnitName
-- @param #function EventFunction The function to be called when the event occurs for the unit.
-- @param Core.Base#BASE EventClass The self instance of the class for which the event is.
-- @param EventID
-- @return #EVENT
function EVENT:OnEventForUnit( EventDCSUnitName, EventFunction, EventClass, EventID )
  self:F2( EventDCSUnitName )

  local Event = self:Init( EventID, EventClass )
  if not Event.IniUnit then
    Event.IniUnit = {}
  end
  Event.IniUnit[EventDCSUnitName] = {}
  Event.IniUnit[EventDCSUnitName].EventFunction = EventFunction
  Event.IniUnit[EventDCSUnitName].EventClass = EventClass
  return self
end

do -- OnBirth

  --- Create an OnBirth event handler for a group
  -- @param #EVENT self
  -- @param Wrapper.Group#GROUP EventGroup
  -- @param #function EventFunction The function to be called when the event occurs for the unit.
  -- @param EventClass The self instance of the class for which the event is.
  -- @return #EVENT
  function EVENT:OnBirthForTemplate( EventTemplate, EventFunction, EventClass )
    self:F2( EventTemplate.name )
  
    self:OnEventForTemplate( EventTemplate, EventFunction, EventClass, self.OnBirthForUnit )
    
    return self
  end
  
  --- Set a new listener for an S_EVENT_BIRTH event, and registers the unit born.
  -- @param #EVENT self
  -- @param #function EventFunction The function to be called when the event occurs for the unit.
  -- @param Base#BASE EventClass
  -- @return #EVENT
  function EVENT:OnBirth( EventFunction, EventClass )
    self:F2()
    
    self:OnEventGeneric( EventFunction, EventClass, world.event.S_EVENT_BIRTH )
    
    return self
  end
  
  --- Set a new listener for an S_EVENT_BIRTH event.
  -- @param #EVENT self
  -- @param #string EventDCSUnitName The id of the unit for the event to be handled.
  -- @param #function EventFunction The function to be called when the event occurs for the unit.
  -- @param Base#BASE EventClass
  -- @return #EVENT
  function EVENT:OnBirthForUnit( EventDCSUnitName, EventFunction, EventClass )
    self:F2( EventDCSUnitName )
    
    self:OnEventForUnit( EventDCSUnitName, EventFunction, EventClass, world.event.S_EVENT_BIRTH )
    
    return self
  end

  --- Stop listening to S_EVENT_BIRTH event.
  -- @param #EVENT self
  -- @param Base#BASE EventClass
  -- @return #EVENT
  function EVENT:OnBirthRemove( EventClass )
    self:F2()
    
    self:Remove( EventClass, world.event.S_EVENT_BIRTH )
    
    return self
  end
  

end

do -- OnCrash

  --- Create an OnCrash event handler for a group
  -- @param #EVENT self
  -- @param Wrapper.Group#GROUP EventGroup
  -- @param #function EventFunction The function to be called when the event occurs for the unit.
  -- @param EventClass The self instance of the class for which the event is.
  -- @return #EVENT
  function EVENT:OnCrashForTemplate( EventTemplate, EventFunction, EventClass )
    self:F2( EventTemplate.name )
  
    self:OnEventForTemplate( EventTemplate, EventFunction, EventClass, self.OnCrashForUnit )
  
    return self
  end
  
  --- Set a new listener for an S_EVENT_CRASH event.
  -- @param #EVENT self
  -- @param #function EventFunction The function to be called when the event occurs for the unit.
  -- @param Base#BASE EventClass
  -- @return #EVENT
  function EVENT:OnCrash( EventFunction, EventClass )
    self:F2()
    
    self:OnEventGeneric( EventFunction, EventClass, world.event.S_EVENT_CRASH )
    
    return self 
  end
  
  --- Set a new listener for an S_EVENT_CRASH event.
  -- @param #EVENT self
  -- @param #string EventDCSUnitName
  -- @param #function EventFunction The function to be called when the event occurs for the unit.
  -- @param Base#BASE EventClass The self instance of the class for which the event is.
  -- @return #EVENT
  function EVENT:OnCrashForUnit( EventDCSUnitName, EventFunction, EventClass )
    self:F2( EventDCSUnitName )
    
    self:OnEventForUnit( EventDCSUnitName, EventFunction, EventClass, world.event.S_EVENT_CRASH )
  
    return self
  end

  --- Stop listening to S_EVENT_CRASH event.
  -- @param #EVENT self
  -- @param Base#BASE EventClass
  -- @return #EVENT
  function EVENT:OnCrashRemove( EventClass )
    self:F2()
    
    self:Remove( EventClass, world.event.S_EVENT_CRASH )
    
    return self
  end

end

do -- OnDead
 
  --- Create an OnDead event handler for a group
  -- @param #EVENT self
  -- @param Wrapper.Group#GROUP EventGroup
  -- @param #function EventFunction The function to be called when the event occurs for the unit.
  -- @param EventClass The self instance of the class for which the event is.
  -- @return #EVENT
  function EVENT:OnDeadForTemplate( EventTemplate, EventFunction, EventClass )
    self:F2( EventTemplate.name )
    
    self:OnEventForTemplate( EventTemplate, EventFunction, EventClass, self.OnDeadForUnit )
  
    return self
  end
  
  --- Set a new listener for an S_EVENT_DEAD event.
  -- @param #EVENT self
  -- @param #function EventFunction The function to be called when the event occurs for the unit.
  -- @param Base#BASE EventClass
  -- @return #EVENT
  function EVENT:OnDead( EventFunction, EventClass )
    self:F2()
    
    self:OnEventGeneric( EventFunction, EventClass, world.event.S_EVENT_DEAD )
    
    return self
  end
  
  
  --- Set a new listener for an S_EVENT_DEAD event.
  -- @param #EVENT self
  -- @param #string EventDCSUnitName
  -- @param #function EventFunction The function to be called when the event occurs for the unit.
  -- @param Base#BASE EventClass The self instance of the class for which the event is.
  -- @return #EVENT
  function EVENT:OnDeadForUnit( EventDCSUnitName, EventFunction, EventClass )
    self:F2( EventDCSUnitName )
  
    self:OnEventForUnit( EventDCSUnitName, EventFunction, EventClass, world.event.S_EVENT_DEAD )
    
    return self
  end
  
  --- Stop listening to S_EVENT_DEAD event.
  -- @param #EVENT self
  -- @param Base#BASE EventClass
  -- @return #EVENT
  function EVENT:OnDeadRemove( EventClass )
    self:F2()
    
    self:Remove( EventClass, world.event.S_EVENT_DEAD )
    
    return self
  end
  

end

do -- OnPilotDead

  --- Set a new listener for an S_EVENT_PILOT_DEAD event.
  -- @param #EVENT self
  -- @param #function EventFunction The function to be called when the event occurs for the unit.
  -- @param Base#BASE EventClass
  -- @return #EVENT
  function EVENT:OnPilotDead( EventFunction, EventClass )
    self:F2()
    
    self:OnEventGeneric( EventFunction, EventClass, world.event.S_EVENT_PILOT_DEAD )
    
    return self
  end
  
  --- Set a new listener for an S_EVENT_PILOT_DEAD event.
  -- @param #EVENT self
  -- @param #string EventDCSUnitName
  -- @param #function EventFunction The function to be called when the event occurs for the unit.
  -- @param Base#BASE EventClass The self instance of the class for which the event is.
  -- @return #EVENT
  function EVENT:OnPilotDeadForUnit( EventDCSUnitName, EventFunction, EventClass )
    self:F2( EventDCSUnitName )
  
    self:OnEventForUnit( EventDCSUnitName, EventFunction, EventClass, world.event.S_EVENT_PILOT_DEAD )
  
    return self
  end

  --- Stop listening to S_EVENT_PILOT_DEAD event.
  -- @param #EVENT self
  -- @param Base#BASE EventClass
  -- @return #EVENT
  function EVENT:OnPilotDeadRemove( EventClass )
    self:F2()
    
    self:Remove( EventClass, world.event.S_EVENT_PILOT_DEAD )
    
    return self
  end

end

do -- OnLand
  --- Create an OnLand event handler for a group
  -- @param #EVENT self
  -- @param #table EventTemplate
  -- @param #function EventFunction The function to be called when the event occurs for the unit.
  -- @param EventClass The self instance of the class for which the event is.
  -- @return #EVENT
  function EVENT:OnLandForTemplate( EventTemplate, EventFunction, EventClass )
    self:F2( EventTemplate.name )
  
    self:OnEventForTemplate( EventTemplate, EventFunction, EventClass, self.OnLandForUnit )
    
    return self
  end
  
  --- Set a new listener for an S_EVENT_LAND event.
  -- @param #EVENT self
  -- @param #string EventDCSUnitName
  -- @param #function EventFunction The function to be called when the event occurs for the unit.
  -- @param Base#BASE EventClass The self instance of the class for which the event is.
  -- @return #EVENT
  function EVENT:OnLandForUnit( EventDCSUnitName, EventFunction, EventClass )
    self:F2( EventDCSUnitName )
  
    self:OnEventForUnit( EventDCSUnitName, EventFunction, EventClass, world.event.S_EVENT_LAND )
  
    return self
  end

  --- Stop listening to S_EVENT_LAND event.
  -- @param #EVENT self
  -- @param Base#BASE EventClass
  -- @return #EVENT
  function EVENT:OnLandRemove( EventClass )
    self:F2()
    
    self:Remove( EventClass, world.event.S_EVENT_LAND )
    
    return self
  end


end

do -- OnTakeOff
  --- Create an OnTakeOff event handler for a group
  -- @param #EVENT self
  -- @param #table EventTemplate
  -- @param #function EventFunction The function to be called when the event occurs for the unit.
  -- @param EventClass The self instance of the class for which the event is.
  -- @return #EVENT
  function EVENT:OnTakeOffForTemplate( EventTemplate, EventFunction, EventClass )
    self:F2( EventTemplate.name )
  
    self:OnEventForTemplate( EventTemplate, EventFunction, EventClass, self.OnTakeOffForUnit )
  
    return self
  end
  
  --- Set a new listener for an S_EVENT_TAKEOFF event.
  -- @param #EVENT self
  -- @param #string EventDCSUnitName
  -- @param #function EventFunction The function to be called when the event occurs for the unit.
  -- @param Base#BASE EventClass The self instance of the class for which the event is.
  -- @return #EVENT
  function EVENT:OnTakeOffForUnit( EventDCSUnitName, EventFunction, EventClass )
    self:F2( EventDCSUnitName )
  
    self:OnEventForUnit( EventDCSUnitName, EventFunction, EventClass, world.event.S_EVENT_TAKEOFF )
  
    return self
  end

  --- Stop listening to S_EVENT_TAKEOFF event.
  -- @param #EVENT self
  -- @param Base#BASE EventClass
  -- @return #EVENT
  function EVENT:OnTakeOffRemove( EventClass )
    self:F2()
    
    self:Remove( EventClass, world.event.S_EVENT_TAKEOFF )
    
    return self
  end


end

do -- OnEngineShutDown

  --- Create an OnDead event handler for a group
  -- @param #EVENT self
  -- @param #table EventTemplate
  -- @param #function EventFunction The function to be called when the event occurs for the unit.
  -- @param EventClass The self instance of the class for which the event is.
  -- @return #EVENT
  function EVENT:OnEngineShutDownForTemplate( EventTemplate, EventFunction, EventClass )
    self:F2( EventTemplate.name )
  
    self:OnEventForTemplate( EventTemplate, EventFunction, EventClass, self.OnEngineShutDownForUnit )
    
    return self
  end
  
  --- Set a new listener for an S_EVENT_ENGINE_SHUTDOWN event.
  -- @param #EVENT self
  -- @param #string EventDCSUnitName
  -- @param #function EventFunction The function to be called when the event occurs for the unit.
  -- @param Base#BASE EventClass The self instance of the class for which the event is.
  -- @return #EVENT
  function EVENT:OnEngineShutDownForUnit( EventDCSUnitName, EventFunction, EventClass )
    self:F2( EventDCSUnitName )
  
    self:OnEventForUnit( EventDCSUnitName, EventFunction, EventClass, world.event.S_EVENT_ENGINE_SHUTDOWN )
    
    return self
  end

  --- Stop listening to S_EVENT_ENGINE_SHUTDOWN event.
  -- @param #EVENT self
  -- @param Base#BASE EventClass
  -- @return #EVENT
  function EVENT:OnEngineShutDownRemove( EventClass )
    self:F2()
    
    self:Remove( EventClass, world.event.S_EVENT_ENGINE_SHUTDOWN )
    
    return self
  end

end

do -- OnEngineStartUp

  --- Set a new listener for an S_EVENT_ENGINE_STARTUP event.
  -- @param #EVENT self
  -- @param #string EventDCSUnitName
  -- @param #function EventFunction The function to be called when the event occurs for the unit.
  -- @param Base#BASE EventClass The self instance of the class for which the event is.
  -- @return #EVENT
  function EVENT:OnEngineStartUpForUnit( EventDCSUnitName, EventFunction, EventClass )
    self:F2( EventDCSUnitName )
  
    self:OnEventForUnit( EventDCSUnitName, EventFunction, EventClass, world.event.S_EVENT_ENGINE_STARTUP )
    
    return self
  end

  --- Stop listening to S_EVENT_ENGINE_STARTUP event.
  -- @param #EVENT self
  -- @param Base#BASE EventClass
  -- @return #EVENT
  function EVENT:OnEngineStartUpRemove( EventClass )
    self:F2()
    
    self:Remove( EventClass, world.event.S_EVENT_ENGINE_STARTUP )
    
    return self
  end

end

do -- OnShot
  --- Set a new listener for an S_EVENT_SHOT event.
  -- @param #EVENT self
  -- @param #function EventFunction The function to be called when the event occurs for the unit.
  -- @param Base#BASE EventClass The self instance of the class for which the event is.
  -- @return #EVENT
  function EVENT:OnShot( EventFunction, EventClass )
    self:F2()
  
    self:OnEventGeneric( EventFunction, EventClass, world.event.S_EVENT_SHOT )
    
    return self
  end
  
  --- Set a new listener for an S_EVENT_SHOT event for a unit.
  -- @param #EVENT self
  -- @param #string EventDCSUnitName
  -- @param #function EventFunction The function to be called when the event occurs for the unit.
  -- @param Base#BASE EventClass The self instance of the class for which the event is.
  -- @return #EVENT
  function EVENT:OnShotForUnit( EventDCSUnitName, EventFunction, EventClass )
    self:F2( EventDCSUnitName )
  
    self:OnEventForUnit( EventDCSUnitName, EventFunction, EventClass, world.event.S_EVENT_SHOT )
    
    return self
  end
  
  --- Stop listening to S_EVENT_SHOT event.
  -- @param #EVENT self
  -- @param Base#BASE EventClass
  -- @return #EVENT
  function EVENT:OnShotRemove( EventClass )
    self:F2()
    
    self:Remove( EventClass, world.event.S_EVENT_SHOT )
    
    return self
  end
  

end

do -- OnHit

  --- Set a new listener for an S_EVENT_HIT event.
  -- @param #EVENT self
  -- @param #function EventFunction The function to be called when the event occurs for the unit.
  -- @param Base#BASE EventClass The self instance of the class for which the event is.
  -- @return #EVENT
  function EVENT:OnHit( EventFunction, EventClass )
    self:F2()
  
    self:OnEventGeneric( EventFunction, EventClass, world.event.S_EVENT_HIT )
    
    return self
  end
  
  --- Set a new listener for an S_EVENT_HIT event.
  -- @param #EVENT self
  -- @param #string EventDCSUnitName
  -- @param #function EventFunction The function to be called when the event occurs for the unit.
  -- @param Base#BASE EventClass The self instance of the class for which the event is.
  -- @return #EVENT
  function EVENT:OnHitForUnit( EventDCSUnitName, EventFunction, EventClass )
    self:F2( EventDCSUnitName )
  
    self:OnEventForUnit( EventDCSUnitName, EventFunction, EventClass, world.event.S_EVENT_HIT )
    
    return self
  end

  --- Stop listening to S_EVENT_HIT event.
  -- @param #EVENT self
  -- @param Base#BASE EventClass
  -- @return #EVENT
  function EVENT:OnHitRemove( EventClass )
    self:F2()
    
    self:Remove( EventClass, world.event.S_EVENT_HIT )
    
    return self
  end 

end

do -- OnPlayerEnterUnit

  --- Set a new listener for an S_EVENT_PLAYER_ENTER_UNIT event.
  -- @param #EVENT self
  -- @param #function EventFunction The function to be called when the event occurs for the unit.
  -- @param Base#BASE EventClass The self instance of the class for which the event is.
  -- @return #EVENT
  function EVENT:OnPlayerEnterUnit( EventFunction, EventClass )
    self:F2()
  
    self:OnEventGeneric( EventFunction, EventClass, world.event.S_EVENT_PLAYER_ENTER_UNIT )
    
    return self
  end

  --- Stop listening to S_EVENT_PLAYER_ENTER_UNIT event.
  -- @param #EVENT self
  -- @param Base#BASE EventClass
  -- @return #EVENT
  function EVENT:OnPlayerEnterRemove( EventClass )
    self:F2()
    
    self:Remove( EventClass, world.event.S_EVENT_PLAYER_ENTER_UNIT )
    
    return self
  end

end

do -- OnPlayerLeaveUnit
  --- Set a new listener for an S_EVENT_PLAYER_LEAVE_UNIT event.
  -- @param #EVENT self
  -- @param #function EventFunction The function to be called when the event occurs for the unit.
  -- @param Base#BASE EventClass The self instance of the class for which the event is.
  -- @return #EVENT
  function EVENT:OnPlayerLeaveUnit( EventFunction, EventClass )
    self:F2()
  
    self:OnEventGeneric( EventFunction, EventClass, world.event.S_EVENT_PLAYER_LEAVE_UNIT )
    
    return self
  end

  --- Stop listening to S_EVENT_PLAYER_LEAVE_UNIT event.
  -- @param #EVENT self
  -- @param Base#BASE EventClass
  -- @return #EVENT
  function EVENT:OnPlayerLeaveRemove( EventClass )
    self:F2()
    
    self:Remove( EventClass, world.event.S_EVENT_PLAYER_LEAVE_UNIT )
    
    return self
  end

end



--- @param #EVENT self
-- @param #EVENTDATA Event
function EVENT:onEvent( Event )

  local ErrorHandler = function( errmsg )

    env.info( "Error in SCHEDULER function:" .. errmsg )
    if debug ~= nil then
      env.info( debug.traceback() )
    end
    
    return errmsg
  end

  if self and self.Events and self.Events[Event.id] then
    if Event.initiator and Event.initiator:getCategory() == Object.Category.UNIT then
      Event.IniDCSUnit = Event.initiator
      Event.IniDCSGroup = Event.IniDCSUnit:getGroup()
      Event.IniDCSUnitName = Event.IniDCSUnit:getName()
      Event.IniUnitName = Event.IniDCSUnitName
      Event.IniUnit = UNIT:FindByName( Event.IniDCSUnitName )
      if not Event.IniUnit then
        -- Unit can be a CLIENT. Most likely this will be the case ...
        Event.IniUnit = CLIENT:FindByName( Event.IniDCSUnitName, '', true )
      end
      Event.IniDCSGroupName = ""
      if Event.IniDCSGroup and Event.IniDCSGroup:isExist() then
        Event.IniDCSGroupName = Event.IniDCSGroup:getName()
        Event.IniGroup = GROUP:FindByName( Event.IniDCSGroupName )
        self:E( { IniGroup = Event.IniGroup } )
      end
    end
    if Event.target then
      if Event.target and Event.target:getCategory() == Object.Category.UNIT then
        Event.TgtDCSUnit = Event.target
        Event.TgtDCSGroup = Event.TgtDCSUnit:getGroup()
        Event.TgtDCSUnitName = Event.TgtDCSUnit:getName()
        Event.TgtUnitName = Event.TgtDCSUnitName
        Event.TgtUnit = UNIT:FindByName( Event.TgtDCSUnitName )
        Event.TgtDCSGroupName = ""
        if Event.TgtDCSGroup and Event.TgtDCSGroup:isExist() then
          Event.TgtDCSGroupName = Event.TgtDCSGroup:getName()
        end
      end
    end
    if Event.weapon then
      Event.Weapon = Event.weapon
      Event.WeaponName = Event.Weapon:getTypeName()
      --Event.WeaponTgtDCSUnit = Event.Weapon:getTarget()
    end
    
    local PriorityOrder = _EVENTMETA[Event.id].Order
    local PriorityBegin = PriorityOrder == -1 and 5 or 1
    local PriorityEnd = PriorityOrder == -1 and 1 or 5

    self:E( { _EVENTMETA[Event.id].Text, Event, Event.IniDCSUnitName, Event.TgtDCSUnitName, PriorityOrder } )
    
    for EventPriority = PriorityBegin, PriorityEnd, PriorityOrder do
    
      if self.Events[Event.id][EventPriority] then
      
        -- Okay, we got the event from DCS. Now loop the SORTED self.EventSorted[] table for the received Event.id, and for each EventData registered, check if a function needs to be called.
        for EventClass, EventData in pairs( self.Events[Event.id][EventPriority] ) do
        
          -- If the EventData is for a UNIT, the call directly the EventClass EventFunction for that UNIT.
          if Event.IniDCSUnitName and EventData.IniUnit and EventData.IniUnit[Event.IniDCSUnitName] then 

            -- First test if a EventFunction is Set, otherwise search for the default function
            if EventData.IniUnit[Event.IniDCSUnitName].EventFunction then
          
              self:E( { "Calling EventFunction for Class ", EventClass:GetClassNameAndID(), ", Unit ", Event.IniUnitName, EventPriority } )
              Event.IniGroup = GROUP:FindByName( Event.IniDCSGroupName )
              
              local Result, Value = xpcall( 
                function() 
                  return EventData.IniUnit[Event.IniDCSUnitName].EventFunction( EventClass, Event ) 
                end, ErrorHandler )

            else

              -- There is no EventFunction defined, so try to find if a default OnEvent function is defined on the object.
              local EventFunction = EventClass[ _EVENTMETA[Event.id].Event ]
              if EventFunction and type( EventFunction ) == "function" then
                
                -- Now call the default event function.
                self:E( { "Calling " .. _EVENTMETA[Event.id].Event .. " for Class ", EventClass:GetClassNameAndID(), EventPriority } )
                Event.IniGroup = GROUP:FindByName( Event.IniDCSGroupName )
                
                local Result, Value = xpcall( 
                  function() 
                    return EventFunction( EventClass, Event ) 
                  end, ErrorHandler )
              end
              
            end
          
          else
          
            -- If the EventData is not bound to a specific unit, then call the EventClass EventFunction.
            -- Note that here the EventFunction will need to implement and determine the logic for the relevant source- or target unit, or weapon.
            if Event.IniDCSUnit and not EventData.IniUnit then
            
              if EventClass == EventData.EventClass then
                
                -- First test if a EventFunction is Set, otherwise search for the default function
                if EventData.EventFunction then
                  
                  -- There is an EventFunction defined, so call the EventFunction.
                  self:E( { "Calling EventFunction for Class ", EventClass:GetClassNameAndID(), EventPriority } )
                  Event.IniGroup = GROUP:FindByName( Event.IniDCSGroupName )
              
                  local Result, Value = xpcall( 
                    function() 
                      return EventData.EventFunction( EventClass, Event ) 
                    end, ErrorHandler )
                else
                  
                  -- There is no EventFunction defined, so try to find if a default OnEvent function is defined on the object.
                  local EventFunction = EventClass[ _EVENTMETA[Event.id].Event ]
                  if EventFunction and type( EventFunction ) == "function" then
                    
                    -- Now call the default event function.
                    self:E( { "Calling " .. _EVENTMETA[Event.id].Event .. " for Class ", EventClass:GetClassNameAndID(), EventPriority } )
                    Event.IniGroup = GROUP:FindByName( Event.IniDCSGroupName )
                    
                    local Result, Value = xpcall( 
                      function() 
                        return EventFunction( EventClass, Event ) 
                      end, ErrorHandler )
                  end
                end
              end
            end
          end
        end
      end
    end
  else
    self:E( { _EVENTMETA[Event.id].Text, Event } )    
  end
end

