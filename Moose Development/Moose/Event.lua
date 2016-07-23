--- The EVENT class models an efficient event handling process between other classes and its units, weapons.
-- @module Event
-- @author FlightControl

--- The EVENT structure
-- @type EVENT
-- @field #EVENT.Events Events
EVENT = {
  ClassName = "EVENT",
  ClassID = 0,
}

local _EVENTCODES = {
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

--- The Event structure
-- @type EVENTDATA
-- @field id
-- @field initiator
-- @field target
-- @field weapon
-- @field IniDCSUnit
-- @field IniDCSUnitName
-- @field Unit#UNIT           IniUnit
-- @field #string             IniUnitName
-- @field IniDCSGroup
-- @field IniDCSGroupName
-- @field TgtDCSUnit
-- @field TgtDCSUnitName
-- @field Unit#UNIT           TgtUnit
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

  local EventText = _EVENTCODES[EventID]
  
  return EventText
end


--- Initializes the Events structure for the event
-- @param #EVENT self
-- @param DCSWorld#world.event EventID
-- @param #string EventClass
-- @return #EVENT.Events
function EVENT:Init( EventID, EventClass )
  self:F3( { _EVENTCODES[EventID], EventClass } )
  if not self.Events[EventID] then
    self.Events[EventID] = {}
  end
  if not self.Events[EventID][EventClass] then
     self.Events[EventID][EventClass] = {}
  end
  return self.Events[EventID][EventClass]
end

--- Removes an Events entry
-- @param #EVENT self
-- @param Base#BASE EventSelf The self instance of the class for which the event is.
-- @param DCSWorld#world.event EventID
-- @return #EVENT.Events
function EVENT:Remove( EventSelf, EventID  )
  self:F3( { EventSelf, _EVENTCODES[EventID] } )

  local EventClass = EventSelf:GetClassNameAndID()
  self.Events[EventID][EventClass] = nil
end


--- Create an OnDead event handler for a group
-- @param #EVENT self
-- @param #table EventTemplate
-- @param #function EventFunction The function to be called when the event occurs for the unit.
-- @param EventSelf The self instance of the class for which the event is.
-- @param #function OnEventFunction
-- @return #EVENT
function EVENT:OnEventForTemplate( EventTemplate, EventFunction, EventSelf, OnEventFunction )
  self:F2( EventTemplate.name )

  for EventUnitID, EventUnit in pairs( EventTemplate.units ) do
    OnEventFunction( self, EventUnit.name, EventFunction, EventSelf )
  end
  return self
end

--- Set a new listener for an S_EVENT_X event independent from a unit or a weapon.
-- @param #EVENT self
-- @param #function EventFunction The function to be called when the event occurs for the unit.
-- @param Base#BASE EventSelf The self instance of the class for which the event is.
-- @param EventID
-- @return #EVENT
function EVENT:OnEventGeneric( EventFunction, EventSelf, EventID )
  self:F2( { EventID } )

  local Event = self:Init( EventID, EventSelf:GetClassNameAndID() )
  Event.EventFunction = EventFunction
  Event.EventSelf = EventSelf
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
  self:F2( EventDCSUnitName )

  local Event = self:Init( EventID, EventSelf:GetClassNameAndID() )
  if not Event.IniUnit then
    Event.IniUnit = {}
  end
  Event.IniUnit[EventDCSUnitName] = {}
  Event.IniUnit[EventDCSUnitName].EventFunction = EventFunction
  Event.IniUnit[EventDCSUnitName].EventSelf = EventSelf
  return self
end

do -- OnBirth

  --- Create an OnBirth event handler for a group
  -- @param #EVENT self
  -- @param Group#GROUP EventGroup
  -- @param #function EventFunction The function to be called when the event occurs for the unit.
  -- @param EventSelf The self instance of the class for which the event is.
  -- @return #EVENT
  function EVENT:OnBirthForTemplate( EventTemplate, EventFunction, EventSelf )
    self:F2( EventTemplate.name )
  
    self:OnEventForTemplate( EventTemplate, EventFunction, EventSelf, self.OnBirthForUnit )
    
    return self
  end
  
  --- Set a new listener for an S_EVENT_BIRTH event, and registers the unit born.
  -- @param #EVENT self
  -- @param #function EventFunction The function to be called when the event occurs for the unit.
  -- @param Base#BASE EventSelf
  -- @return #EVENT
  function EVENT:OnBirth( EventFunction, EventSelf )
    self:F2()
    
    self:OnEventGeneric( EventFunction, EventSelf, world.event.S_EVENT_BIRTH )
    
    return self
  end
  
  --- Set a new listener for an S_EVENT_BIRTH event.
  -- @param #EVENT self
  -- @param #string EventDCSUnitName The id of the unit for the event to be handled.
  -- @param #function EventFunction The function to be called when the event occurs for the unit.
  -- @param Base#BASE EventSelf
  -- @return #EVENT
  function EVENT:OnBirthForUnit( EventDCSUnitName, EventFunction, EventSelf )
    self:F2( EventDCSUnitName )
    
    self:OnEventForUnit( EventDCSUnitName, EventFunction, EventSelf, world.event.S_EVENT_BIRTH )
    
    return self
  end

  --- Stop listening to S_EVENT_BIRTH event.
  -- @param #EVENT self
  -- @param Base#BASE EventSelf
  -- @return #EVENT
  function EVENT:OnBirthRemove( EventSelf )
    self:F2()
    
    self:Remove( EventSelf, world.event.S_EVENT_BIRTH )
    
    return self
  end
  

end

do -- OnCrash

  --- Create an OnCrash event handler for a group
  -- @param #EVENT self
  -- @param Group#GROUP EventGroup
  -- @param #function EventFunction The function to be called when the event occurs for the unit.
  -- @param EventSelf The self instance of the class for which the event is.
  -- @return #EVENT
  function EVENT:OnCrashForTemplate( EventTemplate, EventFunction, EventSelf )
    self:F2( EventTemplate.name )
  
    self:OnEventForTemplate( EventTemplate, EventFunction, EventSelf, self.OnCrashForUnit )
  
    return self
  end
  
  --- Set a new listener for an S_EVENT_CRASH event.
  -- @param #EVENT self
  -- @param #function EventFunction The function to be called when the event occurs for the unit.
  -- @param Base#BASE EventSelf
  -- @return #EVENT
  function EVENT:OnCrash( EventFunction, EventSelf )
    self:F2()
    
    self:OnEventGeneric( EventFunction, EventSelf, world.event.S_EVENT_CRASH )
    
    return self 
  end
  
  --- Set a new listener for an S_EVENT_CRASH event.
  -- @param #EVENT self
  -- @param #string EventDCSUnitName
  -- @param #function EventFunction The function to be called when the event occurs for the unit.
  -- @param Base#BASE EventSelf The self instance of the class for which the event is.
  -- @return #EVENT
  function EVENT:OnCrashForUnit( EventDCSUnitName, EventFunction, EventSelf )
    self:F2( EventDCSUnitName )
    
    self:OnEventForUnit( EventDCSUnitName, EventFunction, EventSelf, world.event.S_EVENT_CRASH )
  
    return self
  end

  --- Stop listening to S_EVENT_CRASH event.
  -- @param #EVENT self
  -- @param Base#BASE EventSelf
  -- @return #EVENT
  function EVENT:OnCrashRemove( EventSelf )
    self:F2()
    
    self:Remove( EventSelf, world.event.S_EVENT_CRASH )
    
    return self
  end

end

do -- OnDead
 
  --- Create an OnDead event handler for a group
  -- @param #EVENT self
  -- @param Group#GROUP EventGroup
  -- @param #function EventFunction The function to be called when the event occurs for the unit.
  -- @param EventSelf The self instance of the class for which the event is.
  -- @return #EVENT
  function EVENT:OnDeadForTemplate( EventTemplate, EventFunction, EventSelf )
    self:F2( EventTemplate.name )
    
    self:OnEventForTemplate( EventTemplate, EventFunction, EventSelf, self.OnDeadForUnit )
  
    return self
  end
  
  --- Set a new listener for an S_EVENT_DEAD event.
  -- @param #EVENT self
  -- @param #function EventFunction The function to be called when the event occurs for the unit.
  -- @param Base#BASE EventSelf
  -- @return #EVENT
  function EVENT:OnDead( EventFunction, EventSelf )
    self:F2()
    
    self:OnEventGeneric( EventFunction, EventSelf, world.event.S_EVENT_DEAD )
    
    return self
  end
  
  
  --- Set a new listener for an S_EVENT_DEAD event.
  -- @param #EVENT self
  -- @param #string EventDCSUnitName
  -- @param #function EventFunction The function to be called when the event occurs for the unit.
  -- @param Base#BASE EventSelf The self instance of the class for which the event is.
  -- @return #EVENT
  function EVENT:OnDeadForUnit( EventDCSUnitName, EventFunction, EventSelf )
    self:F2( EventDCSUnitName )
  
    self:OnEventForUnit( EventDCSUnitName, EventFunction, EventSelf, world.event.S_EVENT_DEAD )
    
    return self
  end
  
  --- Stop listening to S_EVENT_DEAD event.
  -- @param #EVENT self
  -- @param Base#BASE EventSelf
  -- @return #EVENT
  function EVENT:OnDeadRemove( EventSelf )
    self:F2()
    
    self:Remove( EventSelf, world.event.S_EVENT_DEAD )
    
    return self
  end
  

end

do -- OnPilotDead

  --- Set a new listener for an S_EVENT_PILOT_DEAD event.
  -- @param #EVENT self
  -- @param #function EventFunction The function to be called when the event occurs for the unit.
  -- @param Base#BASE EventSelf
  -- @return #EVENT
  function EVENT:OnPilotDead( EventFunction, EventSelf )
    self:F2()
    
    self:OnEventGeneric( EventFunction, EventSelf, world.event.S_EVENT_PILOT_DEAD )
    
    return self
  end
  
  --- Set a new listener for an S_EVENT_PILOT_DEAD event.
  -- @param #EVENT self
  -- @param #string EventDCSUnitName
  -- @param #function EventFunction The function to be called when the event occurs for the unit.
  -- @param Base#BASE EventSelf The self instance of the class for which the event is.
  -- @return #EVENT
  function EVENT:OnPilotDeadForUnit( EventDCSUnitName, EventFunction, EventSelf )
    self:F2( EventDCSUnitName )
  
    self:OnEventForUnit( EventDCSUnitName, EventFunction, EventSelf, world.event.S_EVENT_PILOT_DEAD )
  
    return self
  end

  --- Stop listening to S_EVENT_PILOT_DEAD event.
  -- @param #EVENT self
  -- @param Base#BASE EventSelf
  -- @return #EVENT
  function EVENT:OnPilotDeadRemove( EventSelf )
    self:F2()
    
    self:Remove( EventSelf, world.event.S_EVENT_PILOT_DEAD )
    
    return self
  end

end

do -- OnLand
  --- Create an OnLand event handler for a group
  -- @param #EVENT self
  -- @param #table EventTemplate
  -- @param #function EventFunction The function to be called when the event occurs for the unit.
  -- @param EventSelf The self instance of the class for which the event is.
  -- @return #EVENT
  function EVENT:OnLandForTemplate( EventTemplate, EventFunction, EventSelf )
    self:F2( EventTemplate.name )
  
    self:OnEventForTemplate( EventTemplate, EventFunction, EventSelf, self.OnLandForUnit )
    
    return self
  end
  
  --- Set a new listener for an S_EVENT_LAND event.
  -- @param #EVENT self
  -- @param #string EventDCSUnitName
  -- @param #function EventFunction The function to be called when the event occurs for the unit.
  -- @param Base#BASE EventSelf The self instance of the class for which the event is.
  -- @return #EVENT
  function EVENT:OnLandForUnit( EventDCSUnitName, EventFunction, EventSelf )
    self:F2( EventDCSUnitName )
  
    self:OnEventForUnit( EventDCSUnitName, EventFunction, EventSelf, world.event.S_EVENT_LAND )
  
    return self
  end

  --- Stop listening to S_EVENT_LAND event.
  -- @param #EVENT self
  -- @param Base#BASE EventSelf
  -- @return #EVENT
  function EVENT:OnLandRemove( EventSelf )
    self:F2()
    
    self:Remove( EventSelf, world.event.S_EVENT_LAND )
    
    return self
  end


end

do -- OnTakeOff
  --- Create an OnTakeOff event handler for a group
  -- @param #EVENT self
  -- @param #table EventTemplate
  -- @param #function EventFunction The function to be called when the event occurs for the unit.
  -- @param EventSelf The self instance of the class for which the event is.
  -- @return #EVENT
  function EVENT:OnTakeOffForTemplate( EventTemplate, EventFunction, EventSelf )
    self:F2( EventTemplate.name )
  
    self:OnEventForTemplate( EventTemplate, EventFunction, EventSelf, self.OnTakeOffForUnit )
  
    return self
  end
  
  --- Set a new listener for an S_EVENT_TAKEOFF event.
  -- @param #EVENT self
  -- @param #string EventDCSUnitName
  -- @param #function EventFunction The function to be called when the event occurs for the unit.
  -- @param Base#BASE EventSelf The self instance of the class for which the event is.
  -- @return #EVENT
  function EVENT:OnTakeOffForUnit( EventDCSUnitName, EventFunction, EventSelf )
    self:F2( EventDCSUnitName )
  
    self:OnEventForUnit( EventDCSUnitName, EventFunction, EventSelf, world.event.S_EVENT_TAKEOFF )
  
    return self
  end

  --- Stop listening to S_EVENT_TAKEOFF event.
  -- @param #EVENT self
  -- @param Base#BASE EventSelf
  -- @return #EVENT
  function EVENT:OnTakeOffRemove( EventSelf )
    self:F2()
    
    self:Remove( EventSelf, world.event.S_EVENT_TAKEOFF )
    
    return self
  end


end

do -- OnEngineShutDown

  --- Create an OnDead event handler for a group
  -- @param #EVENT self
  -- @param #table EventTemplate
  -- @param #function EventFunction The function to be called when the event occurs for the unit.
  -- @param EventSelf The self instance of the class for which the event is.
  -- @return #EVENT
  function EVENT:OnEngineShutDownForTemplate( EventTemplate, EventFunction, EventSelf )
    self:F2( EventTemplate.name )
  
    self:OnEventForTemplate( EventTemplate, EventFunction, EventSelf, self.OnEngineShutDownForUnit )
    
    return self
  end
  
  --- Set a new listener for an S_EVENT_ENGINE_SHUTDOWN event.
  -- @param #EVENT self
  -- @param #string EventDCSUnitName
  -- @param #function EventFunction The function to be called when the event occurs for the unit.
  -- @param Base#BASE EventSelf The self instance of the class for which the event is.
  -- @return #EVENT
  function EVENT:OnEngineShutDownForUnit( EventDCSUnitName, EventFunction, EventSelf )
    self:F2( EventDCSUnitName )
  
    self:OnEventForUnit( EventDCSUnitName, EventFunction, EventSelf, world.event.S_EVENT_ENGINE_SHUTDOWN )
    
    return self
  end

  --- Stop listening to S_EVENT_ENGINE_SHUTDOWN event.
  -- @param #EVENT self
  -- @param Base#BASE EventSelf
  -- @return #EVENT
  function EVENT:OnEngineShutDownRemove( EventSelf )
    self:F2()
    
    self:Remove( EventSelf, world.event.S_EVENT_ENGINE_SHUTDOWN )
    
    return self
  end

end

do -- OnEngineStartUp

  --- Set a new listener for an S_EVENT_ENGINE_STARTUP event.
  -- @param #EVENT self
  -- @param #string EventDCSUnitName
  -- @param #function EventFunction The function to be called when the event occurs for the unit.
  -- @param Base#BASE EventSelf The self instance of the class for which the event is.
  -- @return #EVENT
  function EVENT:OnEngineStartUpForUnit( EventDCSUnitName, EventFunction, EventSelf )
    self:F2( EventDCSUnitName )
  
    self:OnEventForUnit( EventDCSUnitName, EventFunction, EventSelf, world.event.S_EVENT_ENGINE_STARTUP )
    
    return self
  end

  --- Stop listening to S_EVENT_ENGINE_STARTUP event.
  -- @param #EVENT self
  -- @param Base#BASE EventSelf
  -- @return #EVENT
  function EVENT:OnEngineStartUpRemove( EventSelf )
    self:F2()
    
    self:Remove( EventSelf, world.event.S_EVENT_ENGINE_STARTUP )
    
    return self
  end

end

do -- OnShot
  --- Set a new listener for an S_EVENT_SHOT event.
  -- @param #EVENT self
  -- @param #function EventFunction The function to be called when the event occurs for the unit.
  -- @param Base#BASE EventSelf The self instance of the class for which the event is.
  -- @return #EVENT
  function EVENT:OnShot( EventFunction, EventSelf )
    self:F2()
  
    self:OnEventGeneric( EventFunction, EventSelf, world.event.S_EVENT_SHOT )
    
    return self
  end
  
  --- Set a new listener for an S_EVENT_SHOT event for a unit.
  -- @param #EVENT self
  -- @param #string EventDCSUnitName
  -- @param #function EventFunction The function to be called when the event occurs for the unit.
  -- @param Base#BASE EventSelf The self instance of the class for which the event is.
  -- @return #EVENT
  function EVENT:OnShotForUnit( EventDCSUnitName, EventFunction, EventSelf )
    self:F2( EventDCSUnitName )
  
    self:OnEventForUnit( EventDCSUnitName, EventFunction, EventSelf, world.event.S_EVENT_SHOT )
    
    return self
  end
  
  --- Stop listening to S_EVENT_SHOT event.
  -- @param #EVENT self
  -- @param Base#BASE EventSelf
  -- @return #EVENT
  function EVENT:OnShotRemove( EventSelf )
    self:F2()
    
    self:Remove( EventSelf, world.event.S_EVENT_SHOT )
    
    return self
  end
  

end

do -- OnHit

  --- Set a new listener for an S_EVENT_HIT event.
  -- @param #EVENT self
  -- @param #function EventFunction The function to be called when the event occurs for the unit.
  -- @param Base#BASE EventSelf The self instance of the class for which the event is.
  -- @return #EVENT
  function EVENT:OnHit( EventFunction, EventSelf )
    self:F2()
  
    self:OnEventGeneric( EventFunction, EventSelf, world.event.S_EVENT_HIT )
    
    return self
  end
  
  --- Set a new listener for an S_EVENT_HIT event.
  -- @param #EVENT self
  -- @param #string EventDCSUnitName
  -- @param #function EventFunction The function to be called when the event occurs for the unit.
  -- @param Base#BASE EventSelf The self instance of the class for which the event is.
  -- @return #EVENT
  function EVENT:OnHitForUnit( EventDCSUnitName, EventFunction, EventSelf )
    self:F2( EventDCSUnitName )
  
    self:OnEventForUnit( EventDCSUnitName, EventFunction, EventSelf, world.event.S_EVENT_HIT )
    
    return self
  end

  --- Stop listening to S_EVENT_HIT event.
  -- @param #EVENT self
  -- @param Base#BASE EventSelf
  -- @return #EVENT
  function EVENT:OnHitRemove( EventSelf )
    self:F2()
    
    self:Remove( EventSelf, world.event.S_EVENT_HIT )
    
    return self
  end

end

do -- OnPlayerEnterUnit

  --- Set a new listener for an S_EVENT_PLAYER_ENTER_UNIT event.
  -- @param #EVENT self
  -- @param #function EventFunction The function to be called when the event occurs for the unit.
  -- @param Base#BASE EventSelf The self instance of the class for which the event is.
  -- @return #EVENT
  function EVENT:OnPlayerEnterUnit( EventFunction, EventSelf )
    self:F2()
  
    self:OnEventGeneric( EventFunction, EventSelf, world.event.S_EVENT_PLAYER_ENTER_UNIT )
    
    return self
  end

  --- Stop listening to S_EVENT_PLAYER_ENTER_UNIT event.
  -- @param #EVENT self
  -- @param Base#BASE EventSelf
  -- @return #EVENT
  function EVENT:OnPlayerEnterRemove( EventSelf )
    self:F2()
    
    self:Remove( EventSelf, world.event.S_EVENT_PLAYER_ENTER_UNIT )
    
    return self
  end

end

do -- OnPlayerLeaveUnit
  --- Set a new listener for an S_EVENT_PLAYER_LEAVE_UNIT event.
  -- @param #EVENT self
  -- @param #function EventFunction The function to be called when the event occurs for the unit.
  -- @param Base#BASE EventSelf The self instance of the class for which the event is.
  -- @return #EVENT
  function EVENT:OnPlayerLeaveUnit( EventFunction, EventSelf )
    self:F2()
  
    self:OnEventGeneric( EventFunction, EventSelf, world.event.S_EVENT_PLAYER_LEAVE_UNIT )
    
    return self
  end

  --- Stop listening to S_EVENT_PLAYER_LEAVE_UNIT event.
  -- @param #EVENT self
  -- @param Base#BASE EventSelf
  -- @return #EVENT
  function EVENT:OnPlayerLeaveRemove( EventSelf )
    self:F2()
    
    self:Remove( EventSelf, world.event.S_EVENT_PLAYER_LEAVE_UNIT )
    
    return self
  end

end



--- @param #EVENT self
-- @param #EVENTDATA Event
function EVENT:onEvent( Event )

  if self and self.Events and self.Events[Event.id] then
    if Event.initiator and Event.initiator:getCategory() == Object.Category.UNIT then
      Event.IniDCSUnit = Event.initiator
      Event.IniDCSGroup = Event.IniDCSUnit:getGroup()
      Event.IniDCSUnitName = Event.IniDCSUnit:getName()
      Event.IniUnitName = Event.IniDCSUnitName
      Event.IniUnit = UNIT:FindByName( Event.IniDCSUnitName )
      Event.IniDCSGroupName = ""
      if Event.IniDCSGroup and Event.IniDCSGroup:isExist() then
        Event.IniDCSGroupName = Event.IniDCSGroup:getName()
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
    self:E( { _EVENTCODES[Event.id], Event.initiator, Event.IniDCSUnitName, Event.target, Event.TgtDCSUnitName, Event.weapon, Event.WeaponName } )
    for ClassName, EventData in pairs( self.Events[Event.id] ) do
      if Event.IniDCSUnitName and EventData.IniUnit and EventData.IniUnit[Event.IniDCSUnitName] then 
        self:T( { "Calling event function for class ", ClassName, " unit ", Event.IniUnitName } )
        EventData.IniUnit[Event.IniDCSUnitName].EventFunction( EventData.IniUnit[Event.IniDCSUnitName].EventSelf, Event )
      else
        if Event.IniDCSUnit and not EventData.IniUnit then
          if ClassName == EventData.EventSelf:GetClassNameAndID() then
            self:T( { "Calling event function for class ", ClassName } )
            EventData.EventFunction( EventData.EventSelf, Event )
          end
        end
      end
    end
  else
    self:E( { _EVENTCODES[Event.id], Event } )    
  end
end

