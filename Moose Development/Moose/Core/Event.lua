--- This core module models the dispatching of DCS Events to subscribed MOOSE classes,
-- following a given priority.
-- 
-- ![Banner Image](..\Presentations\EVENT\Dia1.JPG)
-- 
-- ===
-- 
-- # 1) Event Handling Overview
-- 
-- ![Objects](..\Presentations\EVENT\Dia2.JPG)
-- 
-- Within a running mission, various DCS events occur. Units are dynamically created, crash, die, shoot stuff, get hit etc.
-- This module provides a mechanism to dispatch those events occuring within your running mission, to the different objects orchestrating your mission.
-- 
-- ![Objects](..\Presentations\EVENT\Dia3.JPG)
-- 
-- Objects can subscribe to different events. The Event dispatcher will publish the received DCS events to the subscribed MOOSE objects, in a specified order.
-- In this way, the subscribed MOOSE objects are kept in sync with your evolving running mission.
-- 
-- ## 1.1) Event Dispatching
-- 
-- ![Objects](..\Presentations\EVENT\Dia4.JPG)
-- 
-- The _EVENTDISPATCHER object is automatically created within MOOSE, 
-- and handles the dispatching of DCS Events occurring 
-- in the simulator to the subscribed objects 
-- in the correct processing order.
--
-- ![Objects](..\Presentations\EVENT\Dia5.JPG)
-- 
-- There are 5 levels of kind of objects that the _EVENTDISPATCHER services:
-- 
--  * _DATABASE object: The core of the MOOSE objects. Any object that is created, deleted or updated, is done in this database.
--  * SET_ derived classes: Subsets of the _DATABASE object. These subsets are updated by the _EVENTDISPATCHER as the second priority.
--  * UNIT objects: UNIT objects can subscribe to DCS events. Each DCS event will be directly published to teh subscribed UNIT object.
--  * GROUP objects: GROUP objects can subscribe to DCS events. Each DCS event will be directly published to the subscribed GROUP object.
--  * Any other object: Various other objects can subscribe to DCS events. Each DCS event triggered will be published to each subscribed object.
-- 
-- ![Objects](..\Presentations\EVENT\Dia6.JPG)
-- 
-- For most DCS events, the above order of updating will be followed.
-- 
-- ![Objects](..\Presentations\EVENT\Dia7.JPG)
-- 
-- But for some DCS events, the publishing order is reversed. This is due to the fact that objects need to be **erased** instead of added.
-- 
-- ## 1.2) Event Handling
-- 
-- ![Objects](..\Presentations\EVENT\Dia8.JPG)
-- 
-- The actual event subscribing and handling is not facilitated through the _EVENTDISPATCHER, but it is done through the @{BASE} class, @{UNIT} class and @{GROUP} class.
-- The _EVENTDISPATCHER is a component that is quietly working in the background of MOOSE.
-- 
-- ![Objects](..\Presentations\EVENT\Dia9.JPG)
-- 
-- The BASE class provides methods to catch DCS Events. These are events that are triggered from within the DCS simulator, 
-- and handled through lua scripting. MOOSE provides an encapsulation to handle these events more efficiently.
-- 
-- ### 1.2.1 Subscribe / Unsubscribe to DCS Events
-- 
-- At first, the mission designer will need to **Subscribe** to a specific DCS event for the class.
-- So, when the DCS event occurs, the class will be notified of that event.
-- There are two functions which you use to subscribe to or unsubscribe from an event.
-- 
--   * @{Base#BASE.HandleEvent}(): Subscribe to a DCS Event.
--   * @{Base#BASE.UnHandleEvent}(): Unsubscribe from a DCS Event.
-- 
-- ### 1.3.2 Event Handling of DCS Events
-- 
-- Once the class is subscribed to the event, an **Event Handling** method on the object or class needs to be written that will be called
-- when the DCS event occurs. The Event Handling method receives an @{Event#EVENTDATA} structure, which contains a lot of information
-- about the event that occurred.
-- 
-- Find below an example of the prototype how to write an event handling function for two units: 
--
--      local Tank1 = UNIT:FindByName( "Tank A" )
--      local Tank2 = UNIT:FindByName( "Tank B" )
--      
--      -- Here we subscribe to the Dead events. So, if one of these tanks dies, the Tank1 or Tank2 objects will be notified.
--      Tank1:HandleEvent( EVENTS.Dead )
--      Tank2:HandleEvent( EVENTS.Dead )
--      
--      --- This function is an Event Handling function that will be called when Tank1 is Dead.
--      -- @param Wrapper.Unit#UNIT self 
--      -- @param Core.Event#EVENTDATA EventData
--      function Tank1:OnEventDead( EventData )
--
--        self:SmokeGreen()
--      end
--
--      --- This function is an Event Handling function that will be called when Tank2 is Dead.
--      -- @param Wrapper.Unit#UNIT self 
--      -- @param Core.Event#EVENTDATA EventData
--      function Tank2:OnEventDead( EventData )
--
--        self:SmokeBlue()
--      end
-- 
-- ### 1.3.3 Event Handling methods that are automatically called upon subscribed DCS events
-- 
-- ![Objects](..\Presentations\EVENT\Dia10.JPG)
-- 
-- The following list outlines which EVENTS item in the structure corresponds to which Event Handling method.
-- Always ensure that your event handling methods align with the events being subscribed to, or nothing will be executed.
-- 
-- # 2) EVENTS type
-- 
-- The EVENTS structure contains names for all the different DCS events that objects can subscribe to using the 
-- @{Base#BASE.HandleEvent}() method.
-- 
-- # 3) EVENTDATA type
-- 
-- The EVENTDATA contains all the fields that are populated with event information before 
-- an Event Handler method is being called by the event dispatcher.
-- The Event Handler received the EVENTDATA object as a parameter, and can be used to investigate further the different events.
-- There are basically 4 main categories of information stored in the EVENTDATA structure:
-- 
--    * Initiator Unit data: Several fields documenting the initiator unit related to the event.
--    * Target Unit data: Several fields documenting the target unit related to the event.
--    * Weapon data: Certain events populate weapon information.
--    * Place data: Certain events populate place information.
-- 
-- Find below an overview which events populate which information categories:
-- 
-- ![Objects](..\Presentations\EVENT\Dia14.JPG)
-- 
-- **IMPORTANT NOTE:** Some events can involve not just UNIT objects, but also STATIC objects!!! 
-- In that case the initiator or target unit fields will refer to a STATIC object!
-- In case a STATIC object is involved, the documentation indicates which fields will and won't not be populated.
-- The fields **IniCategory** and **TgtCategory** contain the indicator which **kind of object is involved** in the event.
-- You can use the enumerator **Object.Category.UNIT** and **Object.Category.STATIC** to check on IniCategory and TgtCategory.
-- Example code snippet:
--      
--      if Event.IniCategory == Object.Category.UNIT then
--       ...
--      end
--      if Event.IniCategory == Object.Category.STATIC then
--       ...
--      end 
-- 
-- When a static object is involved in the event, the Group and Player fields won't be populated.
-- 
-- ====
-- 
-- # **API CHANGE HISTORY**
-- 
-- The underlying change log documents the API changes. Please read this carefully. The following notation is used:
-- 
--   * **Added** parts are expressed in bold type face.
--   * _Removed_ parts are expressed in italic type face.
-- 
-- YYYY-MM-DD: CLASS:**NewFunction**( Params ) replaces CLASS:_OldFunction_( Params )
-- YYYY-MM-DD: CLASS:**NewFunction( Params )** added
-- 
-- Hereby the change log:
-- 
--   * 2016-02-07: Did a complete revision of the Event Handing API and underlying mechanisms.
-- 
-- ===
-- 
-- # **AUTHORS and CONTRIBUTIONS**
-- 
-- ### Contributions: 
-- 
-- ### Authors: 
-- 
--   * [**FlightControl**](https://forums.eagle.ru/member.php?u=89536): Design & Programming & documentation.
--
-- @module Event

-- TODO: Need to update the EVENTDATA documentation with IniPlayerName and TgtPlayerName
-- TODO: Need to update the EVENTDATA documentation with IniCategory and TgtCategory



--- The EVENT structure
-- @type EVENT
-- @field #EVENT.Events Events
-- @extends Core.Base#BASE
EVENT = {
  ClassName = "EVENT",
  ClassID = 0,
}

--- The different types of events supported by MOOSE.
-- Use this structure to subscribe to events using the @{Base#BASE.HandleEvent}() method.
-- @type EVENTS
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

--- The Event structure
-- Note that at the beginning of each field description, there is an indication which field will be populated depending on the object type involved in the Event:
--   
--   * A (Object.Category.)UNIT : A UNIT object type is involved in the Event.
--   * A (Object.Category.)STATIC : A STATIC object type is involved in the Event.µ
--   
-- @type EVENTDATA
-- @field #number id The identifier of the event.
-- 
-- @field Dcs.DCSUnit#Unit                  initiator         (UNIT/STATIC) The initiating @{Dcs.DCSUnit#Unit} or @{Dcs.DCSStaticObject#StaticObject}.
-- @field Dcs.DCSObject#Object.Category     IniCategory       (UNIT/STATIC) The initiator object category ( Object.Category.UNIT or Object.Category.STATIC ).
-- @field Dcs.DCSUnit#Unit                  IniDCSUnit        (UNIT/STATIC) The initiating @{Dcs.DCSUnit#Unit} or @{Dcs.DCSStaticObject#StaticObject}.
-- @field #string                           IniDCSUnitName    (UNIT/STATIC) The initiating Unit name.
-- @field Wrapper.Unit#UNIT                 IniUnit           (UNIT/STATIC) The initiating MOOSE wrapper @{Wrapper.Unit#UNIT} of the initiator Unit object.
-- @field #string                           IniUnitName       (UNIT/STATIC) The initiating UNIT name (same as IniDCSUnitName).
-- @field Dcs.DCSGroup#Group                IniDCSGroup       (UNIT) The initiating {Dcs.DCSGroup#Group}.
-- @field #string                           IniDCSGroupName   (UNIT) The initiating Group name.
-- @field Wrapper.Group#GROUP               IniGroup          (UNIT) The initiating MOOSE wrapper @{Wrapper.Group#GROUP} of the initiator Group object.
-- @field #string                           IniGroupName      (UNIT) The initiating GROUP name (same as IniDCSGroupName).
-- @field #string                           IniPlayerName     (UNIT) The name of the initiating player in case the Unit is a client or player slot.
-- 
-- @field Dcs.DCSUnit#Unit                  target            (UNIT/STATIC) The target @{Dcs.DCSUnit#Unit} or @{Dcs.DCSStaticObject#StaticObject}.
-- @field Dcs.DCSObject#Object.Category     TgtCategory       (UNIT/STATIC) The target object category ( Object.Category.UNIT or Object.Category.STATIC ).
-- @field Dcs.DCSUnit#Unit                  TgtDCSUnit        (UNIT/STATIC) The target @{Dcs.DCSUnit#Unit} or @{Dcs.DCSStaticObject#StaticObject}.
-- @field #string                           TgtDCSUnitName    (UNIT/STATIC) The target Unit name.
-- @field Wrapper.Unit#UNIT                 TgtUnit           (UNIT/STATIC) The target MOOSE wrapper @{Wrapper.Unit#UNIT} of the target Unit object.
-- @field #string                           TgtUnitName       (UNIT/STATIC) The target UNIT name (same as TgtDCSUnitName).
-- @field Dcs.DCSGroup#Group                TgtDCSGroup       (UNIT) The target {Dcs.DCSGroup#Group}.
-- @field #string                           TgtDCSGroupName   (UNIT) The target Group name.
-- @field Wrapper.Group#GROUP               TgtGroup          (UNIT) The target MOOSE wrapper @{Wrapper.Group#GROUP} of the target Group object.
-- @field #string                           TgtGroupName      (UNIT) The target GROUP name (same as TgtDCSGroupName).
-- @field #string                           TgtPlayerName     (UNIT) The name of the target player in case the Unit is a client or player slot.
-- 
-- @field weapon The weapon used during the event.
-- @field Weapon
-- @field WeaponName
-- @field WeaponTgtDCSUnit


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
     Order = -1,
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
  

    if Event.initiator then    
      Event.IniCategory = Event.initiator:getCategory()
      if Event.IniCategory == Object.Category.UNIT then
        Event.IniDCSUnit = Event.initiator
        Event.IniDCSUnitName = Event.IniDCSUnit:getName()
        Event.IniUnitName = Event.IniDCSUnitName
        Event.IniDCSGroup = Event.IniDCSUnit:getGroup()
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
        Event.IniPlayerName = Event.IniDCSUnit:getPlayerName()
      end
      
      if Event.IniCategory == Object.Category.STATIC then
        Event.IniDCSUnit = Event.initiator
        Event.IniDCSUnitName = Event.IniDCSUnit:getName()
        Event.IniUnitName = Event.IniDCSUnitName
        Event.IniUnit = STATIC:FindByName( Event.IniDCSUnitName )
      end
    end
    
    if Event.target then
      Event.TgtCategory = Event.target:getCategory()
      if Event.TgtCategory == Object.Category.UNIT then 
        Event.TgtDCSUnit = Event.target
        Event.TgtDCSGroup = Event.TgtDCSUnit:getGroup()
        Event.TgtDCSUnitName = Event.TgtDCSUnit:getName()
        Event.TgtUnitName = Event.TgtDCSUnitName
        Event.TgtUnit = UNIT:FindByName( Event.TgtDCSUnitName )
        Event.TgtDCSGroupName = ""
        if Event.TgtDCSGroup and Event.TgtDCSGroup:isExist() then
          Event.TgtDCSGroupName = Event.TgtDCSGroup:getName()
        end
        Event.TgtPlayerName = Event.TgtDCSUnit:getPlayerName()
      end
      
      if Event.TgtCategory == Object.Category.STATIC then
        Event.TgtDCSUnit = Event.target
        Event.TgtDCSUnitName = Event.TgtDCSUnit:getName()
        Event.TgtUnitName = Event.TgtDCSUnitName
        Event.TgtUnit = STATIC:FindByName( Event.TgtDCSUnitName )
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

--- The EVENTHANDLER structure
-- @type EVENTHANDLER
-- @extends Core.Base#BASE
EVENTHANDLER = {
  ClassName = "EVENTHANDLER",
  ClassID = 0,
}

--- The EVENTHANDLER constructor
-- @param #EVENTHANDLER self
-- @return #EVENTHANDLER
function EVENTHANDLER:New()
  self = BASE:Inherit( self, BASE:New() ) -- #EVENTHANDLER
  return self
end
