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

  local EventText = _EVENTCODES[EventID]
  
  return EventText
end


--- Initializes the Events structure for the event
-- @param #EVENT self
-- @param Dcs.DCSWorld#world.event EventID
-- @param Core.Base#BASE EventClass
-- @return #EVENT.Events
function EVENT:Init( EventID, EventClass )
  self:F3( { _EVENTCODES[EventID], EventClass } )

  if not self.Events[EventID] then 
    -- Create a WEAK table to ensure that the garbage collector is cleaning the event links when the object usage is cleaned.
    self.Events[EventID] = setmetatable( {}, { __mode = "k" } )

  end

  if not self.Events[EventID][EventClass] then
     self.Events[EventID][EventClass] = setmetatable( {}, { __mode = "k" } )
  end
  return self.Events[EventID][EventClass]
end

--- Removes an Events entry
-- @param #EVENT self
-- @param Core.Base#BASE EventClass The self instance of the class for which the event is.
-- @param Dcs.DCSWorld#world.event EventID
-- @return #EVENT.Events
function EVENT:Remove( EventClass, EventID  )
  self:F3( { EventClass, _EVENTCODES[EventID] } )

  local EventClass = EventClass
  self.Events[EventID][EventClass] = nil
end

--- Clears all event subscriptions for a @{Core.Base#BASE} derived object.
-- @param #EVENT self
-- @param Core.Base#BASE EventObject
function EVENT:RemoveAll( EventObject  )
  self:F3( { EventObject:GetClassNameAndID() } )

  local EventClass = EventObject:GetClassNameAndID()
  for EventID, EventData in pairs( self.Events ) do
    self.Events[EventID][EventClass] = nil
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
    self:E( { _EVENTCODES[Event.id], Event, Event.IniDCSUnitName, Event.TgtDCSUnitName } )
    
    -- Okay, we got the event from DCS. Now loop the self.Events[] table for the received Event.id, and for each EventData registered, check if a function needs to be called.
    for EventClass, EventData in pairs( self.Events[Event.id] ) do
      -- If the EventData is for a UNIT, the call directly the EventClass EventFunction for that UNIT.
      if Event.IniDCSUnitName and EventData.IniUnit and EventData.IniUnit[Event.IniDCSUnitName] then 
        self:T( { "Calling EventFunction for Class ", EventClass:GetClassNameAndID(), ", Unit ", Event.IniUnitName } )
        local Result, Value = xpcall( function() return EventData.IniUnit[Event.IniDCSUnitName].EventFunction( EventData.IniUnit[Event.IniDCSUnitName].EventClass, Event ) end, ErrorHandler )
        --EventData.IniUnit[Event.IniDCSUnitName].EventFunction( EventData.IniUnit[Event.IniDCSUnitName].EventClass, Event )
      else
        -- If the EventData is not bound to a specific unit, then call the EventClass EventFunction.
        -- Note that here the EventFunction will need to implement and determine the logic for the relevant source- or target unit, or weapon.
        if Event.IniDCSUnit and not EventData.IniUnit then
          if EventClass == EventData.EventClass then
            self:T( { "Calling EventFunction for Class ", EventClass:GetClassNameAndID() } )
            local Result, Value = xpcall( function() return EventData.EventFunction( EventData.EventClass, Event ) end, ErrorHandler )
            --EventData.EventFunction( EventData.EventClass, Event )
          end
        end
      end
    end
  else
    self:E( { _EVENTCODES[Event.id], Event } )    
  end
end

