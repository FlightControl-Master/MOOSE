--- **Core** - Models DCS event dispatching using a publish-subscribe model.
-- 
-- ===
-- 
-- ## Features:
-- 
--   * Capture DCS events and dispatch them to the subscribed objects.
--   * Generate DCS events to the subscribed objects from within the code.
-- 
-- ===
-- 
-- # Event Handling Overview
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
-- ## 1. Event Dispatching
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
-- # 2. Event Handling
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
-- ## 2.1. Subscribe to / Unsubscribe from DCS Events.
-- 
-- At first, the mission designer will need to **Subscribe** to a specific DCS event for the class.
-- So, when the DCS event occurs, the class will be notified of that event.
-- There are two functions which you use to subscribe to or unsubscribe from an event.
-- 
--   * @{Core.Base#BASE.HandleEvent}(): Subscribe to a DCS Event.
--   * @{Core.Base#BASE.UnHandleEvent}(): Unsubscribe from a DCS Event.
--   
-- Note that for a UNIT, the event will be handled **for that UNIT only**!
-- Note that for a GROUP, the event will be handled **for all the UNITs in that GROUP only**!
-- 
-- For all objects of other classes, the subscribed events will be handled for **all UNITs within the Mission**!
-- So if a UNIT within the mission has the subscribed event for that object, 
-- then the object event handler will receive the event for that UNIT!
-- 
-- ## 2.2 Event Handling of DCS Events
-- 
-- Once the class is subscribed to the event, an **Event Handling** method on the object or class needs to be written that will be called
-- when the DCS event occurs. The Event Handling method receives an @{Core.Event#EVENTDATA} structure, which contains a lot of information
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
-- ## 2.3 Event Handling methods that are automatically called upon subscribed DCS events.
-- 
-- ![Objects](..\Presentations\EVENT\Dia10.JPG)
-- 
-- The following list outlines which EVENTS item in the structure corresponds to which Event Handling method.
-- Always ensure that your event handling methods align with the events being subscribed to, or nothing will be executed.
-- 
-- # 3. EVENTS type
-- 
-- The EVENTS structure contains names for all the different DCS events that objects can subscribe to using the 
-- @{Core.Base#BASE.HandleEvent}() method.
-- 
-- # 4. EVENTDATA type
-- 
-- The @{Core.Event#EVENTDATA} structure contains all the fields that are populated with event information before 
-- an Event Handler method is being called by the event dispatcher.
-- The Event Handler received the EVENTDATA object as a parameter, and can be used to investigate further the different events.
-- There are basically 4 main categories of information stored in the EVENTDATA structure:
-- 
--    * Initiator Unit data: Several fields documenting the initiator unit related to the event.
--    * Target Unit data: Several fields documenting the target unit related to the event.
--    * Weapon data: Certain events populate weapon information.
--    * Place data: Certain events populate place information.
-- 
--      --- This function is an Event Handling function that will be called when Tank1 is Dead.
--      -- EventData is an EVENTDATA structure.
--      -- We use the EventData.IniUnit to smoke the tank Green.
--      -- @param Wrapper.Unit#UNIT self 
--      -- @param Core.Event#EVENTDATA EventData
--      function Tank1:OnEventDead( EventData )
--
--        EventData.IniUnit:SmokeGreen()
--      end
-- 
-- 
-- Find below an overview which events populate which information categories:
-- 
-- ![Objects](..\Presentations\EVENT\Dia14.JPG)
-- 
-- **IMPORTANT NOTE:** Some events can involve not just UNIT objects, but also STATIC objects!!! 
-- In that case the initiator or target unit fields will refer to a STATIC object!
-- In case a STATIC object is involved, the documentation indicates which fields will and won't not be populated.
-- The fields **IniObjectCategory** and **TgtObjectCategory** contain the indicator which **kind of object is involved** in the event.
-- You can use the enumerator **Object.Category.UNIT** and **Object.Category.STATIC** to check on IniObjectCategory and TgtObjectCategory.
-- Example code snippet:
--      
--      if Event.IniObjectCategory == Object.Category.UNIT then
--       ...
--      end
--      if Event.IniObjectCategory == Object.Category.STATIC then
--       ...
--      end 
-- 
-- When a static object is involved in the event, the Group and Player fields won't be populated.
-- 
-- ===
-- 
-- ### Author: **FlightControl**
-- ### Contributions: 
-- 
-- ===
--
-- @module Core.Event
-- @image Core_Event.JPG


--- @type EVENT
-- @field #EVENT.Events Events
-- @extends Core.Base#BASE

--- The EVENT class
-- @field #EVENT
EVENT = {
  ClassName = "EVENT",
  ClassID = 0,
  MissionEnd = false,
}

world.event.S_EVENT_NEW_CARGO = world.event.S_EVENT_MAX + 1000
world.event.S_EVENT_DELETE_CARGO = world.event.S_EVENT_MAX + 1001
world.event.S_EVENT_NEW_ZONE = world.event.S_EVENT_MAX + 1002
world.event.S_EVENT_DELETE_ZONE = world.event.S_EVENT_MAX + 1003
world.event.S_EVENT_NEW_ZONE_GOAL = world.event.S_EVENT_MAX + 1004
world.event.S_EVENT_DELETE_ZONE_GOAL = world.event.S_EVENT_MAX + 1005
world.event.S_EVENT_REMOVE_UNIT = world.event.S_EVENT_MAX + 1006
world.event.S_EVENT_PLAYER_ENTER_AIRCRAFT = world.event.S_EVENT_MAX + 1007


--- The different types of events supported by MOOSE.
-- Use this structure to subscribe to events using the @{Core.Base#BASE.HandleEvent}() method.
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
  -- Added with DCS 2.5.1
  MarkAdded =         world.event.S_EVENT_MARK_ADDED,
  MarkChange =        world.event.S_EVENT_MARK_CHANGE,
  MarkRemoved =       world.event.S_EVENT_MARK_REMOVED,
  -- Moose Events
  NewCargo =          world.event.S_EVENT_NEW_CARGO,
  DeleteCargo =       world.event.S_EVENT_DELETE_CARGO,
  NewZone =           world.event.S_EVENT_NEW_ZONE,
  DeleteZone =        world.event.S_EVENT_DELETE_ZONE,
  NewZoneGoal =       world.event.S_EVENT_NEW_ZONE_GOAL,
  DeleteZoneGoal =    world.event.S_EVENT_DELETE_ZONE_GOAL,
  RemoveUnit =        world.event.S_EVENT_REMOVE_UNIT,
  PlayerEnterAircraft = world.event.S_EVENT_PLAYER_ENTER_AIRCRAFT,
  -- Added with DCS 2.5.6
  DetailedFailure =   world.event.S_EVENT_DETAILED_FAILURE or -1,  --We set this to -1 for backward compatibility to DCS 2.5.5 and earlier
  Kill =              world.event.S_EVENT_KILL or -1,
  Score =             world.event.S_EVENT_SCORE or -1,
  UnitLost =          world.event.S_EVENT_UNIT_LOST or -1,
  LandingAfterEjection = world.event.S_EVENT_LANDING_AFTER_EJECTION or -1,
  -- Added with DCS 2.7.0
  ParatrooperLanding        = world.event.S_EVENT_PARATROOPER_LENDING or -1,
  DiscardChairAfterEjection = world.event.S_EVENT_DISCARD_CHAIR_AFTER_EJECTION or -1,
  WeaponAdd                 = world.event.S_EVENT_WEAPON_ADD or -1,
  TriggerZone               = world.event.S_EVENT_TRIGGER_ZONE or -1,
  LandingQualityMark        = world.event.S_EVENT_LANDING_QUALITY_MARK or -1,
  BDA                       = world.event.S_EVENT_BDA or -1,
}

--- The Event structure
-- Note that at the beginning of each field description, there is an indication which field will be populated depending on the object type involved in the Event:
--   
--   * A (Object.Category.)UNIT : A UNIT object type is involved in the Event.
--   * A (Object.Category.)STATIC : A STATIC object type is involved in the Event.
--   
-- @type EVENTDATA
-- @field #number id The identifier of the event.
-- 
-- @field DCS#Unit initiator (UNIT/STATIC/SCENERY) The initiating @{DCS#Unit} or @{DCS#StaticObject}.
-- @field DCS#Object.Category IniObjectCategory (UNIT/STATIC/SCENERY) The initiator object category ( Object.Category.UNIT or Object.Category.STATIC ).
-- @field DCS#Unit IniDCSUnit (UNIT/STATIC) The initiating @{DCS#Unit} or @{DCS#StaticObject}.
-- @field #string IniDCSUnitName (UNIT/STATIC) The initiating Unit name.
-- @field Wrapper.Unit#UNIT IniUnit (UNIT/STATIC) The initiating MOOSE wrapper @{Wrapper.Unit#UNIT} of the initiator Unit object.
-- @field #string IniUnitName (UNIT/STATIC) The initiating UNIT name (same as IniDCSUnitName).
-- @field DCS#Group IniDCSGroup (UNIT) The initiating {DCSGroup#Group}.
-- @field #string IniDCSGroupName (UNIT) The initiating Group name.
-- @field Wrapper.Group#GROUP IniGroup (UNIT) The initiating MOOSE wrapper @{Wrapper.Group#GROUP} of the initiator Group object.
-- @field #string IniGroupName UNIT) The initiating GROUP name (same as IniDCSGroupName).
-- @field #string IniPlayerName (UNIT) The name of the initiating player in case the Unit is a client or player slot.
-- @field DCS#coalition.side IniCoalition (UNIT) The coalition of the initiator.
-- @field DCS#Unit.Category IniCategory (UNIT) The category of the initiator.
-- @field #string IniTypeName (UNIT) The type name of the initiator.
-- 
-- @field DCS#Unit target (UNIT/STATIC) The target @{DCS#Unit} or @{DCS#StaticObject}.
-- @field DCS#Object.Category TgtObjectCategory (UNIT/STATIC) The target object category ( Object.Category.UNIT or Object.Category.STATIC ).
-- @field DCS#Unit TgtDCSUnit (UNIT/STATIC) The target @{DCS#Unit} or @{DCS#StaticObject}.
-- @field #string TgtDCSUnitName (UNIT/STATIC) The target Unit name.
-- @field Wrapper.Unit#UNIT TgtUnit (UNIT/STATIC) The target MOOSE wrapper @{Wrapper.Unit#UNIT} of the target Unit object.
-- @field #string TgtUnitName (UNIT/STATIC) The target UNIT name (same as TgtDCSUnitName).
-- @field DCS#Group TgtDCSGroup (UNIT) The target {DCSGroup#Group}.
-- @field #string TgtDCSGroupName (UNIT) The target Group name.
-- @field Wrapper.Group#GROUP TgtGroup (UNIT) The target MOOSE wrapper @{Wrapper.Group#GROUP} of the target Group object.
-- @field #string TgtGroupName (UNIT) The target GROUP name (same as TgtDCSGroupName).
-- @field #string TgtPlayerName (UNIT) The name of the target player in case the Unit is a client or player slot.
-- @field DCS#coalition.side TgtCoalition (UNIT) The coalition of the target.
-- @field DCS#Unit.Category TgtCategory (UNIT) The category of the target.
-- @field #string TgtTypeName (UNIT) The type name of the target.
-- 
-- @field DCS#Airbase place The @{DCS#Airbase}
-- @field Wrapper.Airbase#AIRBASE Place The MOOSE airbase object.
-- @field #string PlaceName The name of the airbase.
-- 
-- @field #table weapon The weapon used during the event.
-- @field #table Weapon
-- @field #string WeaponName Name of the weapon.
-- @field DCS#Unit WeaponTgtDCSUnit Target DCS unit of the weapon.
-- 
-- @field Cargo.Cargo#CARGO Cargo The cargo object.
-- @field #string CargoName The name of the cargo object.
-- 
-- @field Core.ZONE#ZONE Zone The zone object.
-- @field #string ZoneName The name of the zone.



local _EVENTMETA = {
   [world.event.S_EVENT_SHOT] = {
     Order = 1,
     Side = "I",
     Event = "OnEventShot",
     Text = "S_EVENT_SHOT" 
   },
   [world.event.S_EVENT_HIT] = {
     Order = 1,
     Side = "T",
     Event = "OnEventHit",
     Text = "S_EVENT_HIT" 
   },
   [world.event.S_EVENT_TAKEOFF] = {
     Order = 1,
     Side = "I",
     Event = "OnEventTakeoff",
     Text = "S_EVENT_TAKEOFF" 
   },
   [world.event.S_EVENT_LAND] = {
     Order = 1,
     Side = "I",
     Event = "OnEventLand",
     Text = "S_EVENT_LAND" 
   },
   [world.event.S_EVENT_CRASH] = {
     Order = -1,
     Side = "I",
     Event = "OnEventCrash",
     Text = "S_EVENT_CRASH" 
   },
   [world.event.S_EVENT_EJECTION] = {
     Order = 1,
     Side = "I",
     Event = "OnEventEjection",
     Text = "S_EVENT_EJECTION" 
   },
   [world.event.S_EVENT_REFUELING] = {
     Order = 1,
     Side = "I",
     Event = "OnEventRefueling",
     Text = "S_EVENT_REFUELING" 
   },
   [world.event.S_EVENT_DEAD] = {
     Order = -1,
     Side = "I",
     Event = "OnEventDead",
     Text = "S_EVENT_DEAD" 
   },
   [world.event.S_EVENT_PILOT_DEAD] = {
     Order = 1,
     Side = "I",
     Event = "OnEventPilotDead",
     Text = "S_EVENT_PILOT_DEAD" 
   },
   [world.event.S_EVENT_BASE_CAPTURED] = {
     Order = 1,
     Side = "I",
     Event = "OnEventBaseCaptured",
     Text = "S_EVENT_BASE_CAPTURED" 
   },
   [world.event.S_EVENT_MISSION_START] = {
     Order = 1,
     Side = "N",
     Event = "OnEventMissionStart",
     Text = "S_EVENT_MISSION_START" 
   },
   [world.event.S_EVENT_MISSION_END] = {
     Order = 1,
     Side = "N",
     Event = "OnEventMissionEnd",
     Text = "S_EVENT_MISSION_END" 
   },
   [world.event.S_EVENT_TOOK_CONTROL] = {
     Order = 1,
     Side = "N",
     Event = "OnEventTookControl",
     Text = "S_EVENT_TOOK_CONTROL" 
   },
   [world.event.S_EVENT_REFUELING_STOP] = {
     Order = 1,
     Side = "I",
     Event = "OnEventRefuelingStop",
     Text = "S_EVENT_REFUELING_STOP" 
   },
   [world.event.S_EVENT_BIRTH] = {
     Order = 1,
     Side = "I",
     Event = "OnEventBirth",
     Text = "S_EVENT_BIRTH" 
   },
   [world.event.S_EVENT_HUMAN_FAILURE] = {
     Order = 1,
     Side = "I",
     Event = "OnEventHumanFailure",
     Text = "S_EVENT_HUMAN_FAILURE" 
   },
   [world.event.S_EVENT_ENGINE_STARTUP] = {
     Order = 1,
     Side = "I",
     Event = "OnEventEngineStartup",
     Text = "S_EVENT_ENGINE_STARTUP" 
   },
   [world.event.S_EVENT_ENGINE_SHUTDOWN] = {
     Order = 1,
     Side = "I",
     Event = "OnEventEngineShutdown",
     Text = "S_EVENT_ENGINE_SHUTDOWN" 
   },
   [world.event.S_EVENT_PLAYER_ENTER_UNIT] = {
     Order = 1,
     Side = "I",
     Event = "OnEventPlayerEnterUnit",
     Text = "S_EVENT_PLAYER_ENTER_UNIT" 
   },
   [world.event.S_EVENT_PLAYER_LEAVE_UNIT] = {
     Order = -1,
     Side = "I",
     Event = "OnEventPlayerLeaveUnit",
     Text = "S_EVENT_PLAYER_LEAVE_UNIT" 
   },
   [world.event.S_EVENT_PLAYER_COMMENT] = {
     Order = 1,
     Side = "I",
     Event = "OnEventPlayerComment",
     Text = "S_EVENT_PLAYER_COMMENT" 
   },
   [world.event.S_EVENT_SHOOTING_START] = {
     Order = 1,
     Side = "I",
     Event = "OnEventShootingStart",
     Text = "S_EVENT_SHOOTING_START" 
   },
   [world.event.S_EVENT_SHOOTING_END] = {
     Order = 1,
     Side = "I",
     Event = "OnEventShootingEnd",
     Text = "S_EVENT_SHOOTING_END" 
   },
   [world.event.S_EVENT_MARK_ADDED] = {
     Order = 1,
     Side = "I",
     Event = "OnEventMarkAdded",
     Text = "S_EVENT_MARK_ADDED" 
   },
   [world.event.S_EVENT_MARK_CHANGE] = {
     Order = 1,
     Side = "I",
     Event = "OnEventMarkChange",
     Text = "S_EVENT_MARK_CHANGE" 
   },
   [world.event.S_EVENT_MARK_REMOVED] = {
     Order = 1,
     Side = "I",
     Event = "OnEventMarkRemoved",
     Text = "S_EVENT_MARK_REMOVED" 
   },
   [EVENTS.NewCargo] = {
     Order = 1,
     Event = "OnEventNewCargo",
     Text = "S_EVENT_NEW_CARGO" 
   },
   [EVENTS.DeleteCargo] = {
     Order = 1,
     Event = "OnEventDeleteCargo",
     Text = "S_EVENT_DELETE_CARGO" 
   },
   [EVENTS.NewZone] = {
     Order = 1,
     Event = "OnEventNewZone",
     Text = "S_EVENT_NEW_ZONE" 
   },
   [EVENTS.DeleteZone] = {
     Order = 1,
     Event = "OnEventDeleteZone",
     Text = "S_EVENT_DELETE_ZONE" 
   },
   [EVENTS.NewZoneGoal] = {
     Order = 1,
     Event = "OnEventNewZoneGoal",
     Text = "S_EVENT_NEW_ZONE_GOAL" 
   },
   [EVENTS.DeleteZoneGoal] = {
     Order = 1,
     Event = "OnEventDeleteZoneGoal",
     Text = "S_EVENT_DELETE_ZONE_GOAL" 
   },
   [EVENTS.RemoveUnit] = {
     Order = -1,
     Event = "OnEventRemoveUnit",
     Text = "S_EVENT_REMOVE_UNIT" 
   },
   [EVENTS.PlayerEnterAircraft] = {
     Order = 1,
     Event = "OnEventPlayerEnterAircraft",
     Text = "S_EVENT_PLAYER_ENTER_AIRCRAFT" 
   },   
   -- Added with DCS 2.5.6
   [EVENTS.DetailedFailure] = {
     Order = 1,
     Event = "OnEventDetailedFailure",
     Text = "S_EVENT_DETAILED_FAILURE" 
   },
   [EVENTS.Kill] = {
     Order = 1,
     Event = "OnEventKill",
     Text = "S_EVENT_KILL" 
   },
   [EVENTS.Score] = {
     Order = 1,
     Event = "OnEventScore",
     Text = "S_EVENT_SCORE" 
   },
   [EVENTS.UnitLost] = {
     Order = 1,
     Event = "OnEventUnitLost",
     Text = "S_EVENT_UNIT_LOST" 
   },
   [EVENTS.LandingAfterEjection] = {
     Order = 1,
     Event = "OnEventLandingAfterEjection",
     Text = "S_EVENT_LANDING_AFTER_EJECTION" 
   },
   -- Added with DCS 2.7.0
   [EVENTS.ParatrooperLanding] = {
     Order = 1,
     Event = "OnEventParatrooperLanding",
     Text = "S_EVENT_PARATROOPER_LENDING" 
   },
   [EVENTS.DiscardChairAfterEjection] = {
     Order = 1,
     Event = "OnEventDiscardChairAfterEjection",
     Text = "S_EVENT_DISCARD_CHAIR_AFTER_EJECTION" 
   },
   [EVENTS.WeaponAdd] = {
     Order = 1,
     Event = "OnEventWeaponAdd",
     Text = "S_EVENT_WEAPON_ADD" 
   },
   [EVENTS.TriggerZone] = {
     Order = 1,
     Event = "OnEventTriggerZone",
     Text = "S_EVENT_TRIGGER_ZONE" 
   },
   [EVENTS.LandingQualityMark] = {
     Order = 1,
     Event = "OnEventLandingQualityMark",
     Text = "S_EVENT_LANDING_QUALITYMARK" 
   },
   [EVENTS.BDA] = {
     Order = 1,
     Event = "OnEventBDA",
     Text = "S_EVENT_BDA" 
   },   
}


--- The Events structure
-- @type EVENT.Events
-- @field #number IniUnit

--- Create new event handler.
-- @param #EVENT self
-- @return #EVENT self
function EVENT:New()

  -- Inherit base.
  local self = BASE:Inherit( self, BASE:New() )
  
  -- Add world event handler.
  self.EventHandler = world.addEventHandler(self)
  
  return self
end


--- Initializes the Events structure for the event.
-- @param #EVENT self
-- @param DCS#world.event EventID Event ID.
-- @param Core.Base#BASE EventClass The class object for which events are handled.
-- @return #EVENT.Events
function EVENT:Init( EventID, EventClass )
  self:F3( { _EVENTMETA[EventID].Text, EventClass } )

  if not self.Events[EventID] then 
    -- Create a WEAK table to ensure that the garbage collector is cleaning the event links when the object usage is cleaned.
    self.Events[EventID] = {}
  end
  
  -- Each event has a subtable of EventClasses, ordered by EventPriority.
  local EventPriority = EventClass:GetEventPriority()
  
  if not self.Events[EventID][EventPriority] then
    self.Events[EventID][EventPriority] = setmetatable( {}, { __mode = "k" } )
  end 

  if not self.Events[EventID][EventPriority][EventClass] then
     self.Events[EventID][EventPriority][EventClass] = {}
  end
    
  return self.Events[EventID][EventPriority][EventClass]
end

--- Removes a subscription
-- @param #EVENT self
-- @param Core.Base#BASE EventClass The self instance of the class for which the event is.
-- @param DCS#world.event EventID Event ID.
-- @return #EVENT self
function EVENT:RemoveEvent( EventClass, EventID  )

  -- Debug info.
  self:F2( { "Removing subscription for class: ", EventClass:GetClassNameAndID() } )

  -- Get event prio.
  local EventPriority = EventClass:GetEventPriority()

  -- Events.
  self.Events = self.Events or {}
  self.Events[EventID] = self.Events[EventID] or {}
  self.Events[EventID][EventPriority] = self.Events[EventID][EventPriority] or {}  
    
  -- Remove
  self.Events[EventID][EventPriority][EventClass] = nil
  
  return self
end

--- Resets subscriptions.
-- @param #EVENT self
-- @param Core.Base#BASE EventClass The self instance of the class for which the event is.
-- @param DCS#world.event EventID Event ID.
-- @return #EVENT.Events
function EVENT:Reset( EventObject ) --R2.1

  self:F( { "Resetting subscriptions for class: ", EventObject:GetClassNameAndID() } )

  local EventPriority = EventObject:GetEventPriority()
  
  for EventID, EventData in pairs( self.Events ) do
    if self.EventsDead then
      if self.EventsDead[EventID] then
        if self.EventsDead[EventID][EventPriority] then
          if self.EventsDead[EventID][EventPriority][EventObject] then
            self.Events[EventID][EventPriority][EventObject] = self.EventsDead[EventID][EventPriority][EventObject]
          end
        end
      end
    end
  end
end


--- Clears all event subscriptions for a @{Core.Base#BASE} derived object.
-- @param #EVENT self
-- @param Core.Base#BASE EventClass The self class object for which the events are removed.
-- @return #EVENT self
function EVENT:RemoveAll(EventClass)

  local EventClassName = EventClass:GetClassNameAndID()
  
  -- Get Event prio.
  local EventPriority = EventClass:GetEventPriority()
  
  for EventID, EventData in pairs( self.Events ) do
    self.Events[EventID][EventPriority][EventClass] = nil
  end
  
  return self
end



--- Create an OnDead event handler for a group
-- @param #EVENT self
-- @param #table EventTemplate
-- @param #function EventFunction The function to be called when the event occurs for the unit.
-- @param EventClass The instance of the class for which the event is.
-- @param #function OnEventFunction
-- @return #EVENT self
function EVENT:OnEventForTemplate( EventTemplate, EventFunction, EventClass, EventID )
  self:F2( EventTemplate.name )

  for EventUnitID, EventUnit in pairs( EventTemplate.units ) do
    self:OnEventForUnit( EventUnit.name, EventFunction, EventClass, EventID )
  end
  return self
end

--- Set a new listener for an `S_EVENT_X` event independent from a unit or a weapon.
-- @param #EVENT self
-- @param #function EventFunction The function to be called when the event occurs for the unit.
-- @param Core.Base#BASE EventClass The self instance of the class for which the event is captured. When the event happens, the event process will be called in this class provided.
-- @param EventID
-- @return #EVENT
function EVENT:OnEventGeneric( EventFunction, EventClass, EventID )
  self:F2( { EventID, EventClass, EventFunction } )

  local EventData = self:Init( EventID, EventClass )
  EventData.EventFunction = EventFunction
  
  return self
end


--- Set a new listener for an `S_EVENT_X` event for a UNIT.
-- @param #EVENT self
-- @param #string UnitName The name of the UNIT.
-- @param #function EventFunction The function to be called when the event occurs for the GROUP.
-- @param Core.Base#BASE EventClass The self instance of the class for which the event is.
-- @param EventID
-- @return #EVENT self
function EVENT:OnEventForUnit( UnitName, EventFunction, EventClass, EventID )
  self:F2( UnitName )

  local EventData = self:Init( EventID, EventClass )
  EventData.EventUnit = true
  EventData.EventFunction = EventFunction
  return self
end

--- Set a new listener for an S_EVENT_X event for a GROUP.
-- @param #EVENT self
-- @param #string GroupName The name of the GROUP.
-- @param #function EventFunction The function to be called when the event occurs for the GROUP.
-- @param Core.Base#BASE EventClass The self instance of the class for which the event is.
-- @param #number EventID Event ID.
-- @param ... Optional arguments passed to the event function.
-- @return #EVENT self
function EVENT:OnEventForGroup( GroupName, EventFunction, EventClass, EventID, ... )

  local Event = self:Init( EventID, EventClass )
  Event.EventGroup = true
  Event.EventFunction = EventFunction
  Event.Params = arg
  return self
end

do -- OnBirth

  --- Create an OnBirth event handler for a group
  -- @param #EVENT self
  -- @param Wrapper.Group#GROUP EventGroup
  -- @param #function EventFunction The function to be called when the event occurs for the unit.
  -- @param EventClass The self instance of the class for which the event is.
  -- @return #EVENT self
  function EVENT:OnBirthForTemplate( EventTemplate, EventFunction, EventClass )
    self:F2( EventTemplate.name )
  
    self:OnEventForTemplate( EventTemplate, EventFunction, EventClass, EVENTS.Birth )
    
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
  
    self:OnEventForTemplate( EventTemplate, EventFunction, EventClass, EVENTS.Crash )
  
    return self
  end

end

do -- OnDead
 
  --- Create an OnDead event handler for a group
  -- @param #EVENT self
  -- @param Wrapper.Group#GROUP EventGroup The GROUP object.
  -- @param #function EventFunction The function to be called when the event occurs for the unit.
  -- @param #table EventClass The self instance of the class for which the event is.
  -- @return #EVENT self
  function EVENT:OnDeadForTemplate( EventTemplate, EventFunction, EventClass )
    self:F2( EventTemplate.name )
    
    self:OnEventForTemplate( EventTemplate, EventFunction, EventClass, EVENTS.Dead )
  
    return self
  end
  
end


do -- OnLand

  --- Create an OnLand event handler for a group
  -- @param #EVENT self
  -- @param #table EventTemplate
  -- @param #function EventFunction The function to be called when the event occurs for the unit.
  -- @param #table EventClass The self instance of the class for which the event is.
  -- @return #EVENT self
  function EVENT:OnLandForTemplate( EventTemplate, EventFunction, EventClass )
    self:F2( EventTemplate.name )
  
    self:OnEventForTemplate( EventTemplate, EventFunction, EventClass, EVENTS.Land )
    
    return self
  end
  
end

do -- OnTakeOff

  --- Create an OnTakeOff event handler for a group
  -- @param #EVENT self
  -- @param #table EventTemplate Template table.
  -- @param #function EventFunction The function to be called when the event occurs for the unit.
  -- @param #table EventClass The self instance of the class for which the event is.
  -- @return #EVENT self
  function EVENT:OnTakeOffForTemplate( EventTemplate, EventFunction, EventClass )
    self:F2( EventTemplate.name )
  
    self:OnEventForTemplate( EventTemplate, EventFunction, EventClass, EVENTS.Takeoff )
  
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
  
    self:OnEventForTemplate( EventTemplate, EventFunction, EventClass, EVENTS.EngineShutdown )
    
    return self
  end
  
end

do -- Event Creation

  --- Creation of a New Cargo Event.
  -- @param #EVENT self
  -- @param AI.AI_Cargo#AI_CARGO Cargo The Cargo created.
  function EVENT:CreateEventNewCargo( Cargo )
    self:F( { Cargo } )
  
    local Event = {
      id = EVENTS.NewCargo,
      time = timer.getTime(),
      cargo = Cargo,
      }
  
    world.onEvent( Event )
  end

  --- Creation of a Cargo Deletion Event.
  -- @param #EVENT self
  -- @param AI.AI_Cargo#AI_CARGO Cargo The Cargo created.
  function EVENT:CreateEventDeleteCargo( Cargo )
    self:F( { Cargo } )
  
    local Event = {
      id = EVENTS.DeleteCargo,
      time = timer.getTime(),
      cargo = Cargo,
      }
  
    world.onEvent( Event )
  end

  --- Creation of a New Zone Event.
  -- @param #EVENT self
  -- @param Core.Zone#ZONE_BASE Zone The Zone created.
  function EVENT:CreateEventNewZone( Zone )
    self:F( { Zone } )
  
    local Event = {
      id = EVENTS.NewZone,
      time = timer.getTime(),
      zone = Zone,
      }
  
    world.onEvent( Event )
  end

  --- Creation of a Zone Deletion Event.
  -- @param #EVENT self
  -- @param Core.Zone#ZONE_BASE Zone The Zone created.
  function EVENT:CreateEventDeleteZone( Zone )
    self:F( { Zone } )
  
    local Event = {
      id = EVENTS.DeleteZone,
      time = timer.getTime(),
      zone = Zone,
      }
  
    world.onEvent( Event )
  end

  --- Creation of a New ZoneGoal Event.
  -- @param #EVENT self
  -- @param Core.Functional#ZONE_GOAL ZoneGoal The ZoneGoal created.
  function EVENT:CreateEventNewZoneGoal( ZoneGoal )
    self:F( { ZoneGoal } )
  
    local Event = {
      id = EVENTS.NewZoneGoal,
      time = timer.getTime(),
      ZoneGoal = ZoneGoal,
      }
  
    world.onEvent( Event )
  end


  --- Creation of a ZoneGoal Deletion Event.
  -- @param #EVENT self
  -- @param Core.ZoneGoal#ZONE_GOAL ZoneGoal The ZoneGoal created.
  function EVENT:CreateEventDeleteZoneGoal( ZoneGoal )
    self:F( { ZoneGoal } )
  
    local Event = {
      id = EVENTS.DeleteZoneGoal,
      time = timer.getTime(),
      ZoneGoal = ZoneGoal,
      }
  
    world.onEvent( Event )
  end


  --- Creation of a S_EVENT_PLAYER_ENTER_UNIT Event.
  -- @param #EVENT self
  -- @param Wrapper.Unit#UNIT PlayerUnit.
  function EVENT:CreateEventPlayerEnterUnit( PlayerUnit )
    self:F( { PlayerUnit } )
  
    local Event = {
      id = EVENTS.PlayerEnterUnit,
      time = timer.getTime(),
      initiator = PlayerUnit:GetDCSObject()
      }
  
    world.onEvent( Event )
  end
  
  --- Creation of a S_EVENT_PLAYER_ENTER_AIRCRAFT event.
  -- @param #EVENT self
  -- @param Wrapper.Unit#UNIT PlayerUnit The aircraft unit the player entered.
  function EVENT:CreateEventPlayerEnterAircraft( PlayerUnit )
    self:F( { PlayerUnit } )
  
    local Event = {
      id = EVENTS.PlayerEnterAircraft,
      time = timer.getTime(),
      initiator = PlayerUnit:GetDCSObject()
      }
  
    world.onEvent( Event )
  end  

end

--- Main event function.
-- @param #EVENT self
-- @param #EVENTDATA Event Event data table.
function EVENT:onEvent( Event )

  local ErrorHandler = function( errmsg )

    env.info( "Error in SCHEDULER function:" .. errmsg )
    if BASE.Debug ~= nil then
      env.info( debug.traceback() )
    end
    
    return errmsg
  end


  -- Get event meta data.
  local EventMeta = _EVENTMETA[Event.id]
  
  -- Check if this is a known event?
  if EventMeta then
  
    if self and 
       self.Events and 
       self.Events[Event.id] and
       self.MissionEnd == false and
       ( Event.initiator ~= nil or ( Event.initiator == nil and Event.id ~= EVENTS.PlayerLeaveUnit ) ) then
  
      if Event.id and Event.id == EVENTS.MissionEnd then
        self.MissionEnd = true
      end
      
      if Event.initiator then    
        
        Event.IniObjectCategory = Event.initiator:getCategory()
  
        if Event.IniObjectCategory == Object.Category.UNIT then
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
            --if Event.IniGroup then
              Event.IniGroupName = Event.IniDCSGroupName
            --end
          end
          Event.IniPlayerName = Event.IniDCSUnit:getPlayerName()
          Event.IniCoalition = Event.IniDCSUnit:getCoalition()
          Event.IniTypeName = Event.IniDCSUnit:getTypeName()
          Event.IniCategory = Event.IniDCSUnit:getDesc().category
        end
        
        if Event.IniObjectCategory == Object.Category.STATIC then
          if Event.id==31 then
            --env.info("FF event 31")
            -- Event.initiator is a Static object representing the pilot. But getName() error due to DCS bug.
            Event.IniDCSUnit = Event.initiator
            local ID=Event.initiator.id_
            Event.IniDCSUnitName = string.format("Ejected Pilot ID %s", tostring(ID))
            Event.IniUnitName = Event.IniDCSUnitName
            Event.IniCoalition = 0
            Event.IniCategory  = 0
            Event.IniTypeName = "Ejected Pilot"
         elseif Event.id == 33 then -- ejection seat discarded
            Event.IniDCSUnit = Event.initiator
            local ID=Event.initiator.id_
            Event.IniDCSUnitName = string.format("Ejection Seat ID %s", tostring(ID))
            Event.IniUnitName = Event.IniDCSUnitName
            Event.IniCoalition = 0
            Event.IniCategory  = 0
            Event.IniTypeName = "Ejection Seat"
          else
            Event.IniDCSUnit = Event.initiator
            Event.IniDCSUnitName = Event.IniDCSUnit:getName()
            Event.IniUnitName = Event.IniDCSUnitName
            Event.IniUnit = STATIC:FindByName( Event.IniDCSUnitName, false )
            Event.IniCoalition = Event.IniDCSUnit:getCoalition()
            Event.IniCategory = Event.IniDCSUnit:getDesc().category
            Event.IniTypeName = Event.IniDCSUnit:getTypeName()
          end
        end
  
        if Event.IniObjectCategory == Object.Category.CARGO then
          Event.IniDCSUnit = Event.initiator
          Event.IniDCSUnitName = Event.IniDCSUnit:getName()
          Event.IniUnitName = Event.IniDCSUnitName
          Event.IniUnit = CARGO:FindByName( Event.IniDCSUnitName )
          Event.IniCoalition = Event.IniDCSUnit:getCoalition()
          Event.IniCategory = Event.IniDCSUnit:getDesc().category
          Event.IniTypeName = Event.IniDCSUnit:getTypeName()
        end
  
        if Event.IniObjectCategory == Object.Category.SCENERY then
          Event.IniDCSUnit = Event.initiator
          Event.IniDCSUnitName = Event.IniDCSUnit:getName()
          Event.IniUnitName = Event.IniDCSUnitName
          Event.IniUnit = SCENERY:Register( Event.IniDCSUnitName, Event.initiator )
          Event.IniCategory = Event.IniDCSUnit:getDesc().category
          Event.IniTypeName = Event.initiator:isExist() and Event.IniDCSUnit:getTypeName() or "SCENERY" -- TODO: Bug fix for 2.1!
        end
        
        if Event.IniObjectCategory == Object.Category.BASE then
          Event.IniDCSUnit = Event.initiator
          Event.IniDCSUnitName = Event.IniDCSUnit:getName()
          Event.IniUnitName = Event.IniDCSUnitName
          Event.IniUnit = AIRBASE:FindByName(Event.IniDCSUnitName)
          Event.IniCoalition = Event.IniDCSUnit:getCoalition()
          Event.IniCategory = Event.IniDCSUnit:getDesc().category
          Event.IniTypeName = Event.IniDCSUnit:getTypeName()  
        end
      end
      
      if Event.target then
  
        Event.TgtObjectCategory = Event.target:getCategory()
  
        if Event.TgtObjectCategory == Object.Category.UNIT then 
          Event.TgtDCSUnit = Event.target
          Event.TgtDCSGroup = Event.TgtDCSUnit:getGroup()
          Event.TgtDCSUnitName = Event.TgtDCSUnit:getName()
          Event.TgtUnitName = Event.TgtDCSUnitName
          Event.TgtUnit = UNIT:FindByName( Event.TgtDCSUnitName )
          Event.TgtDCSGroupName = ""
          if Event.TgtDCSGroup and Event.TgtDCSGroup:isExist() then
            Event.TgtDCSGroupName = Event.TgtDCSGroup:getName()
            Event.TgtGroup = GROUP:FindByName( Event.TgtDCSGroupName )
            --if Event.TgtGroup then
              Event.TgtGroupName = Event.TgtDCSGroupName
            --end
          end
          Event.TgtPlayerName = Event.TgtDCSUnit:getPlayerName()
          Event.TgtCoalition = Event.TgtDCSUnit:getCoalition()
          Event.TgtCategory = Event.TgtDCSUnit:getDesc().category
          Event.TgtTypeName = Event.TgtDCSUnit:getTypeName()
        end
        
        if Event.TgtObjectCategory == Object.Category.STATIC then
          BASE:T({StaticTgtEvent = Event.id})
          -- get base data
            Event.TgtDCSUnit = Event.target
            if Event.target:isExist() and Event.id ~= 33 then -- leave out ejected seat object
              Event.TgtDCSUnitName = Event.TgtDCSUnit:getName()
              Event.TgtUnitName = Event.TgtDCSUnitName
              Event.TgtUnit = STATIC:FindByName( Event.TgtDCSUnitName, false )
              Event.TgtCoalition = Event.TgtDCSUnit:getCoalition()
              Event.TgtCategory = Event.TgtDCSUnit:getDesc().category
              Event.TgtTypeName = Event.TgtDCSUnit:getTypeName()
            else
              Event.TgtDCSUnitName = string.format("No target object for Event ID %s", tostring(Event.id))
              Event.TgtUnitName = Event.TgtDCSUnitName
              Event.TgtUnit = nil
              Event.TgtCoalition = 0
              Event.TgtCategory = 0
              if Event.id == 6 then
                Event.TgtTypeName = "Ejected Pilot"
                Event.TgtDCSUnitName = string.format("Ejected Pilot ID %s", tostring(Event.IniDCSUnitName))
                Event.TgtUnitName = Event.TgtDCSUnitName
              elseif Event.id == 33 then
                Event.TgtTypeName = "Ejection Seat"
                Event.TgtDCSUnitName = string.format("Ejection Seat ID %s", tostring(Event.IniDCSUnitName))
                Event.TgtUnitName = Event.TgtDCSUnitName
              else
                Event.TgtTypeName = "Static"
              end
           end
        end
  
        if Event.TgtObjectCategory == Object.Category.SCENERY then
          Event.TgtDCSUnit = Event.target
          Event.TgtDCSUnitName = Event.TgtDCSUnit:getName()
          Event.TgtUnitName = Event.TgtDCSUnitName
          Event.TgtUnit = SCENERY:Register( Event.TgtDCSUnitName, Event.target )
          Event.TgtCategory = Event.TgtDCSUnit:getDesc().category
          Event.TgtTypeName = Event.TgtDCSUnit:getTypeName()
        end
      end
      
      if Event.weapon then
        Event.Weapon = Event.weapon
        Event.WeaponName = Event.Weapon:getTypeName()
        Event.WeaponUNIT = CLIENT:Find( Event.Weapon, '', true ) -- Sometimes, the weapon is a player unit!
        Event.WeaponPlayerName = Event.WeaponUNIT and Event.Weapon:getPlayerName()
        Event.WeaponCoalition = Event.WeaponUNIT and Event.Weapon:getCoalition()
        Event.WeaponCategory = Event.WeaponUNIT and Event.Weapon:getDesc().category
        Event.WeaponTypeName = Event.WeaponUNIT and Event.Weapon:getTypeName()
        --Event.WeaponTgtDCSUnit = Event.Weapon:getTarget()
      end
      
      -- Place should be given for takeoff and landing events as well as base captured. It should be a DCS airbase. 
      if Event.place then   
        if Event.id==EVENTS.LandingAfterEjection then
          -- Place is here the UNIT of which the pilot ejected.
          --local name=Event.place:getName()  -- This returns a DCS error "Airbase doesn't exit" :(
          -- However, this is not a big thing, as the aircraft the pilot ejected from is usually long crashed before the ejected pilot touches the ground.
          --Event.Place=UNIT:Find(Event.place)
        else   
          Event.Place=AIRBASE:Find(Event.place)
          Event.PlaceName=Event.Place:GetName()
        end
      end
  
      --  Mark points.
      if Event.idx then
        Event.MarkID=Event.idx
        Event.MarkVec3=Event.pos
        Event.MarkCoordinate=COORDINATE:NewFromVec3(Event.pos)
        Event.MarkText=Event.text
        Event.MarkCoalition=Event.coalition
        Event.MarkGroupID = Event.groupID
      end
      
      if Event.cargo then
        Event.Cargo = Event.cargo
        Event.CargoName = Event.cargo.Name
      end
  
      if Event.zone then
        Event.Zone = Event.zone
        Event.ZoneName = Event.zone.ZoneName
      end
      
      local PriorityOrder = EventMeta.Order
      local PriorityBegin = PriorityOrder == -1 and 5 or 1
      local PriorityEnd = PriorityOrder == -1 and 1 or 5
  
      if Event.IniObjectCategory ~= Object.Category.STATIC then
        self:F( { EventMeta.Text, Event, Event.IniDCSUnitName, Event.TgtDCSUnitName, PriorityOrder } )
      end
      
      for EventPriority = PriorityBegin, PriorityEnd, PriorityOrder do
      
        if self.Events[Event.id][EventPriority] then
        
          -- Okay, we got the event from DCS. Now loop the SORTED self.EventSorted[] table for the received Event.id, and for each EventData registered, check if a function needs to be called.
          for EventClass, EventData in pairs( self.Events[Event.id][EventPriority] ) do
                    
            --if Event.IniObjectCategory ~= Object.Category.STATIC then
            --  self:E( { "Evaluating: ", EventClass:GetClassNameAndID() } )
            --end
            
            Event.IniGroup = GROUP:FindByName( Event.IniDCSGroupName )
            Event.TgtGroup = GROUP:FindByName( Event.TgtDCSGroupName )
          
            -- If the EventData is for a UNIT, the call directly the EventClass EventFunction for that UNIT.
            if EventData.EventUnit then
  
              -- So now the EventClass must be a UNIT class!!! We check if it is still "Alive".
              if EventClass:IsAlive() or
                 Event.id == EVENTS.PlayerEnterUnit or 
                 Event.id == EVENTS.Crash or 
                 Event.id == EVENTS.Dead or 
                 Event.id == EVENTS.RemoveUnit then
              
                local UnitName = EventClass:GetName()
  
                if ( EventMeta.Side == "I" and UnitName == Event.IniDCSUnitName ) or 
                   ( EventMeta.Side == "T" and UnitName == Event.TgtDCSUnitName ) then
                   
                  -- First test if a EventFunction is Set, otherwise search for the default function
                  if EventData.EventFunction then
                
                    if Event.IniObjectCategory ~= 3 then
                      self:F( { "Calling EventFunction for UNIT ", EventClass:GetClassNameAndID(), ", Unit ", Event.IniUnitName, EventPriority } )
                    end
                                    
                    local Result, Value = xpcall( 
                      function() 
                        return EventData.EventFunction( EventClass, Event ) 
                      end, ErrorHandler )
      
                  else
      
                    -- There is no EventFunction defined, so try to find if a default OnEvent function is defined on the object.
                    local EventFunction = EventClass[ EventMeta.Event ]
                    if EventFunction and type( EventFunction ) == "function" then
                      
                      -- Now call the default event function.
                      if Event.IniObjectCategory ~= 3 then
                        self:F( { "Calling " .. EventMeta.Event .. " for Class ", EventClass:GetClassNameAndID(), EventPriority } )
                      end
                                    
                      local Result, Value = xpcall( 
                        function() 
                          return EventFunction( EventClass, Event ) 
                        end, ErrorHandler )
                    end
                  end
                end
              else
                -- The EventClass is not alive anymore, we remove it from the EventHandlers...
                self:RemoveEvent( EventClass, Event.id )
              end
              
            else
  
              --- If the EventData is for a GROUP, the call directly the EventClass EventFunction for the UNIT in that GROUP.
              if EventData.EventGroup then
  
                -- So now the EventClass must be a GROUP class!!! We check if it is still "Alive".
                if EventClass:IsAlive() or
                   Event.id == EVENTS.PlayerEnterUnit or
                   Event.id == EVENTS.Crash or
                   Event.id == EVENTS.Dead or
                   Event.id == EVENTS.RemoveUnit then
  
                  -- We can get the name of the EventClass, which is now always a GROUP object.
                  local GroupName = EventClass:GetName()
    
                  if ( EventMeta.Side == "I" and GroupName == Event.IniDCSGroupName ) or 
                     ( EventMeta.Side == "T" and GroupName == Event.TgtDCSGroupName ) then
  
                    -- First test if a EventFunction is Set, otherwise search for the default function
                    if EventData.EventFunction then
      
                      if Event.IniObjectCategory ~= 3 then
                        self:F( { "Calling EventFunction for GROUP ", EventClass:GetClassNameAndID(), ", Unit ", Event.IniUnitName, EventPriority } )
                      end
                                        
                      local Result, Value = xpcall( 
                        function() 
                          return EventData.EventFunction( EventClass, Event, unpack( EventData.Params ) ) 
                        end, ErrorHandler )
        
                    else
        
                      -- There is no EventFunction defined, so try to find if a default OnEvent function is defined on the object.
                      local EventFunction = EventClass[ EventMeta.Event ]
                      if EventFunction and type( EventFunction ) == "function" then
                        
                        -- Now call the default event function.
                        if Event.IniObjectCategory ~= 3 then
                          self:F( { "Calling " .. EventMeta.Event .. " for GROUP ", EventClass:GetClassNameAndID(), EventPriority } )
                        end
                                            
                        local Result, Value = xpcall( 
                          function() 
                            return EventFunction( EventClass, Event, unpack( EventData.Params ) ) 
                          end, ErrorHandler )
                      end
                    end
                  end
                else
                  -- The EventClass is not alive anymore, we remove it from the EventHandlers...
                  --self:RemoveEvent( EventClass, Event.id )  
                end
              else
            
                -- If the EventData is not bound to a specific unit, then call the EventClass EventFunction.
                -- Note that here the EventFunction will need to implement and determine the logic for the relevant source- or target unit, or weapon.
                if not EventData.EventUnit then
                
                  -- First test if a EventFunction is Set, otherwise search for the default function
                  if EventData.EventFunction then
                    
                    -- There is an EventFunction defined, so call the EventFunction.
                    if Event.IniObjectCategory ~= 3 then
                      self:F2( { "Calling EventFunction for Class ", EventClass:GetClassNameAndID(), EventPriority } )
                    end                
                    local Result, Value = xpcall( 
                      function() 
                        return EventData.EventFunction( EventClass, Event ) 
                      end, ErrorHandler )
                  else
                    
                    -- There is no EventFunction defined, so try to find if a default OnEvent function is defined on the object.
                    local EventFunction = EventClass[ EventMeta.Event ]
                    if EventFunction and type( EventFunction ) == "function" then
                      
                      -- Now call the default event function.
                      if Event.IniObjectCategory ~= 3 then
                        self:F2( { "Calling " .. EventMeta.Event .. " for Class ", EventClass:GetClassNameAndID(), EventPriority } )
                      end
                                    
                      local Result, Value = xpcall( 
                        function() 
                          local Result, Value = EventFunction( EventClass, Event )
                          return Result, Value 
                        end, ErrorHandler )
                    end
                  end
                
                end
              end
            end
          end
        end
      end
      
      -- When cargo was deleted, it may probably be because of an S_EVENT_DEAD.
      -- However, in the loading logic, an S_EVENT_DEAD is also generated after a Destroy() call.
      -- And this is a problem because it will remove all entries from the SET_CARGOs.
      -- To prevent this from happening, the Cargo object has a flag NoDestroy.
      -- When true, the SET_CARGO won't Remove the Cargo object from the set.
      -- But we need to switch that flag off after the event handlers have been called.
      if Event.id == EVENTS.DeleteCargo then
        Event.Cargo.NoDestroy = nil
      end
    else
      self:T( { EventMeta.Text, Event } )    
    end
  else
    self:E(string.format("WARNING: Could not get EVENTMETA data for event ID=%d! Is this an unknown/new DCS event?", tostring(Event.id)))
  end
  
  Event = nil
end

--- The EVENTHANDLER structure.
-- @type EVENTHANDLER
-- @extends Core.Base#BASE
EVENTHANDLER = {
  ClassName = "EVENTHANDLER",
  ClassID = 0,
}

--- The EVENTHANDLER constructor.
-- @param #EVENTHANDLER self
-- @return #EVENTHANDLER self
function EVENTHANDLER:New()
  self = BASE:Inherit( self, BASE:New() ) -- #EVENTHANDLER
  return self
end
