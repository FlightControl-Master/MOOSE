--- **Core** - Prepares and handles the execution of functions over scheduled time (intervals).
--
-- ===
-- 
-- ## Features:
-- 
--   * Schedule functions over time,
--   * optionally in an optional specified time interval, 
--   * optionally **repeating** with a specified time repeat interval, 
--   * optionally **randomizing** with a specified time interval randomization factor, 
--   * optionally **stop** the repeating after a specified time interval. 
--
-- ===
-- 
-- # Demo Missions
-- 
-- ### [SCHEDULER Demo Missions source code](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master-release/SCH%20-%20Scheduler)
-- 
-- ### [SCHEDULER Demo Missions, only for beta testers](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master/SCH%20-%20Scheduler)
--
-- ### [ALL Demo Missions pack of the last release](https://github.com/FlightControl-Master/MOOSE_MISSIONS/releases)
-- 
-- ===
-- 
-- # YouTube Channel
-- 
-- ### [SCHEDULER YouTube Channel (none)]()
-- 
-- ===
--
-- ### Contributions: 
-- 
--   * FlightControl : Concept & Testing
-- 
-- ### Authors: 
-- 
--   * FlightControl : Design & Programming
-- 
-- ===
--
-- @module Core.Scheduler
-- @image Core_Scheduler.JPG

--- The SCHEDULER class
-- @type SCHEDULER
-- @field #table Schedules Table of schedules.
-- @field #table MasterObject Master object.
-- @field #boolean ShowTrace Trace info if true.
-- @extends Core.Base#BASE


--- Creates and handles schedules over time, which allow to execute code at specific time intervals with randomization.
-- 
-- A SCHEDULER can manage **multiple** (repeating) schedules. Each planned or executing schedule has a unique **ScheduleID**.
-- The ScheduleID is returned when the method @{#SCHEDULER.Schedule}() is called.
-- It is recommended to store the ScheduleID in a variable, as it is used in the methods @{SCHEDULER.Start}() and @{SCHEDULER.Stop}(),
-- which can start and stop specific repeating schedules respectively within a SCHEDULER object.
--
-- ## SCHEDULER constructor
-- 
-- The SCHEDULER class is quite easy to use, but note that the New constructor has variable parameters:
-- 
-- The @{#SCHEDULER.New}() method returns 2 variables:
--   
--  1. The SCHEDULER object reference.
--  2. The first schedule planned in the SCHEDULER object.
-- 
-- To clarify the different appliances, lets have a look at the following examples: 
--  
-- ### Construct a SCHEDULER object without a persistent schedule.
-- 
--   * @{#SCHEDULER.New}( nil ): Setup a new SCHEDULER object, which is persistently executed after garbage collection.
-- 
--     MasterObject = SCHEDULER:New()
--     SchedulerID = MasterObject:Schedule( nil, ScheduleFunction, {} )
-- 
-- The above example creates a new MasterObject, but does not schedule anything.
-- A separate schedule is created by using the MasterObject using the method :Schedule..., which returns a ScheduleID
-- 
-- ### Construct a SCHEDULER object without a volatile schedule, but volatile to the Object existence...
-- 
--   * @{#SCHEDULER.New}( Object ): Setup a new SCHEDULER object, which is linked to the Object. When the Object is nillified or destroyed, the SCHEDULER object will also be destroyed and stopped after garbage collection.
-- 
--     ZoneObject = ZONE:New( "ZoneName" )
--     MasterObject = SCHEDULER:New( ZoneObject )
--     SchedulerID = MasterObject:Schedule( ZoneObject, ScheduleFunction, {} )
--     ...
--     ZoneObject = nil
--     garbagecollect()
-- 
-- The above example creates a new MasterObject, but does not schedule anything, and is bound to the existence of ZoneObject, which is a ZONE.
-- A separate schedule is created by using the MasterObject using the method :Schedule()..., which returns a ScheduleID
-- Later in the logic, the ZoneObject is put to nil, and garbage is collected.
-- As a result, the MasterObject will cancel any planned schedule.
--      
-- ### Construct a SCHEDULER object with a persistent schedule.
-- 
--   * @{#SCHEDULER.New}( nil, Function, FunctionArguments, Start, ... ): Setup a new persistent SCHEDULER object, and start a new schedule for the Function with the defined FunctionArguments according the Start and sequent parameters.
--   
--     MasterObject, SchedulerID = SCHEDULER:New( nil, ScheduleFunction, {} )
--     
-- The above example creates a new MasterObject, and does schedule the first schedule as part of the call.
-- Note that 2 variables are returned here: MasterObject, ScheduleID...
--   
-- ### Construct a SCHEDULER object without a schedule, but volatile to the Object existence...
-- 
--   * @{#SCHEDULER.New}( Object, Function, FunctionArguments, Start, ... ): Setup a new SCHEDULER object, linked to Object, and start a new schedule for the Function with the defined FunctionArguments according the Start and sequent parameters.
--
--     ZoneObject = ZONE:New( "ZoneName" )
--     MasterObject, SchedulerID = SCHEDULER:New( ZoneObject, ScheduleFunction, {} )
--     SchedulerID = MasterObject:Schedule( ZoneObject, ScheduleFunction, {} )
--     ...
--     ZoneObject = nil
--     garbagecollect()
--     
-- The above example creates a new MasterObject, and schedules a method call (ScheduleFunction), 
-- and is bound to the existence of ZoneObject, which is a ZONE object (ZoneObject).
-- Both a MasterObject and a SchedulerID variable are returned.
-- Later in the logic, the ZoneObject is put to nil, and garbage is collected.
-- As a result, the MasterObject will cancel the planned schedule.
--  
-- ## SCHEDULER timer stopping and (re-)starting.
--
-- The SCHEDULER can be stopped and restarted with the following methods:
--
--  * @{#SCHEDULER.Start}(): (Re-)Start the schedules within the SCHEDULER object. If a CallID is provided to :Start(), only the schedule referenced by CallID will be (re-)started.
--  * @{#SCHEDULER.Stop}(): Stop the schedules within the SCHEDULER object. If a CallID is provided to :Stop(), then only the schedule referenced by CallID will be stopped.
--
--     ZoneObject = ZONE:New( "ZoneName" )
--     MasterObject, SchedulerID = SCHEDULER:New( ZoneObject, ScheduleFunction, {} )
--     SchedulerID = MasterObject:Schedule( ZoneObject, ScheduleFunction, {}, 10, 10 )
--     ...
--     MasterObject:Stop( SchedulerID )
--     ...
--     MasterObject:Start( SchedulerID )
--     
-- The above example creates a new MasterObject, and does schedule the first schedule as part of the call.
-- Note that 2 variables are returned here: MasterObject, ScheduleID...  
-- Later in the logic, the repeating schedule with SchedulerID is stopped.  
-- A bit later, the repeating schedule with SchedulerId is (re)-started.  
-- 
-- ## Create a new schedule
-- 
-- With the method @{#SCHEDULER.Schedule}() a new time event can be scheduled. 
-- This method is used by the :New() constructor when a new schedule is planned.
-- 
-- Consider the following code fragment of the SCHEDULER object creation.
-- 
--     ZoneObject = ZONE:New( "ZoneName" )
--     MasterObject = SCHEDULER:New( ZoneObject )
-- 
-- Several parameters can be specified that influence the behaviour of a Schedule.
-- 
-- ### A single schedule, immediately executed
-- 
--     SchedulerID = MasterObject:Schedule( ZoneObject, ScheduleFunction, {} )
-- 
-- The above example schedules a new ScheduleFunction call to be executed asynchronously, within milleseconds ...
-- 
-- ### A single schedule, planned over time
-- 
--     SchedulerID = MasterObject:Schedule( ZoneObject, ScheduleFunction, {}, 10 )
--     
-- The above example schedules a new ScheduleFunction call to be executed asynchronously, within 10 seconds ...
-- 
-- ### A schedule with a repeating time interval, planned over time
-- 
--     SchedulerID = MasterObject:Schedule( ZoneObject, ScheduleFunction, {}, 10, 60 )
--     
-- The above example schedules a new ScheduleFunction call to be executed asynchronously, within 10 seconds, 
-- and repeating 60 every seconds ...
-- 
-- ### A schedule with a repeating time interval, planned over time, with time interval randomization
-- 
--     SchedulerID = MasterObject:Schedule( ZoneObject, ScheduleFunction, {}, 10, 60, 0.5 )
--     
-- The above example schedules a new ScheduleFunction call to be executed asynchronously, within 10 seconds, 
-- and repeating 60 seconds, with a 50% time interval randomization ...
-- So the repeating time interval will be randomized using the **0.5**,  
-- and will calculate between **60 - ( 60 * 0.5 )** and **60 + ( 60 * 0.5 )** for each repeat, 
-- which is in this example between **30** and **90** seconds.
-- 
-- ### A schedule with a repeating time interval, planned over time, with time interval randomization, and stop after a time interval
-- 
--     SchedulerID = MasterObject:Schedule( ZoneObject, ScheduleFunction, {}, 10, 60, 0.5, 300 )
--     
-- The above example schedules a new ScheduleFunction call to be executed asynchronously, within 10 seconds, 
-- The schedule will repeat every 60 seconds.
-- So the repeating time interval will be randomized using the **0.5**,  
-- and will calculate between **60 - ( 60 * 0.5 )** and **60 + ( 60 * 0.5 )** for each repeat, 
-- which is in this example between **30** and **90** seconds.
-- The schedule will stop after **300** seconds.
-- 
-- @field #SCHEDULER
SCHEDULER = {
  ClassName       = "SCHEDULER",
  Schedules       = {},
  MasterObject    = nil,
  ShowTrace       = nil,
}

--- SCHEDULER constructor.
-- @param #SCHEDULER self
-- @param #table MasterObject Specified for which Moose object the timer is setup. If a value of nil is provided, a scheduler will be setup without an object reference.
-- @param #function SchedulerFunction The event function to be called when a timer event occurs. The event function needs to accept the parameters specified in SchedulerArguments.
-- @param #table SchedulerArguments Optional arguments that can be given as part of scheduler. The arguments need to be given as a table { param1, param 2, ... }.
-- @param #number Start Specifies the amount of seconds that will be waited before the scheduling is started, and the event function is called.
-- @param #number Repeat Specifies the interval in seconds when the scheduler will call the event function.
-- @param #number RandomizeFactor Specifies a randomization factor between 0 and 1 to randomize the Repeat.
-- @param #number Stop Specifies the amount of seconds when the scheduler will be stopped.
-- @return #SCHEDULER self.
-- @return #table The ScheduleID of the planned schedule.
function SCHEDULER:New( MasterObject, SchedulerFunction, SchedulerArguments, Start, Repeat, RandomizeFactor, Stop )
  
  local self = BASE:Inherit( self, BASE:New() ) -- #SCHEDULER
  self:F2( { Start, Repeat, RandomizeFactor, Stop } )

  local ScheduleID = nil
  
  self.MasterObject = MasterObject
  self.ShowTrace = false
  
  if SchedulerFunction then
    ScheduleID = self:Schedule( MasterObject, SchedulerFunction, SchedulerArguments, Start, Repeat, RandomizeFactor, Stop, 3 )
  end

  return self, ScheduleID
end

--- Schedule a new time event. Note that the schedule will only take place if the scheduler is *started*. Even for a single schedule event, the scheduler needs to be started also.
-- @param #SCHEDULER self
-- @param #table MasterObject Specified for which Moose object the timer is setup. If a value of nil is provided, a scheduler will be setup without an object reference.
-- @param #function SchedulerFunction The event function to be called when a timer event occurs. The event function needs to accept the parameters specified in SchedulerArguments.
-- @param #table SchedulerArguments Optional arguments that can be given as part of scheduler. The arguments need to be given as a table { param1, param 2, ... }.
-- @param #number Start Specifies the amount of seconds that will be waited before the scheduling is started, and the event function is called.
-- @param #number Repeat Specifies the time interval in seconds when the scheduler will call the event function.
-- @param #number RandomizeFactor Specifies a randomization factor between 0 and 1 to randomize the Repeat.
-- @param #number Stop Time interval in seconds after which the scheduler will be stoppe.
-- @param #number TraceLevel Trace level [0,3]. Default 3.
-- @param Core.Fsm#FSM Fsm Finite state model.
-- @return #table The ScheduleID of the planned schedule.
function SCHEDULER:Schedule( MasterObject, SchedulerFunction, SchedulerArguments, Start, Repeat, RandomizeFactor, Stop, TraceLevel, Fsm )
  self:F2( { Start, Repeat, RandomizeFactor, Stop } )
  self:T3( { SchedulerArguments } )

  -- Debug info.
  local ObjectName = "-"
  if MasterObject and MasterObject.ClassName and MasterObject.ClassID then 
    ObjectName = MasterObject.ClassName .. MasterObject.ClassID
  end
  self:F3( { "Schedule :", ObjectName, tostring( MasterObject ),  Start, Repeat, RandomizeFactor, Stop } )
  
  -- Set master object.
  self.MasterObject = MasterObject
  
  -- Add schedule.
  local ScheduleID = _SCHEDULEDISPATCHER:AddSchedule( 
    self, 
    SchedulerFunction,
    SchedulerArguments,
    Start,
    Repeat,
    RandomizeFactor,
    Stop,
    TraceLevel or 3,
    Fsm
  )
  
  self.Schedules[#self.Schedules+1] = ScheduleID

  return ScheduleID
end

--- (Re-)Starts the schedules or a specific schedule if a valid ScheduleID is provided.
-- @param #SCHEDULER self
-- @param #string ScheduleID (Optional) The ScheduleID of the planned (repeating) schedule.
function SCHEDULER:Start( ScheduleID )
  self:F3( { ScheduleID } )
  self:T(string.format("Starting scheduler ID=%s", tostring(ScheduleID)))
  _SCHEDULEDISPATCHER:Start( self, ScheduleID )
end

--- Stops the schedules or a specific schedule if a valid ScheduleID is provided.
-- @param #SCHEDULER self
-- @param #string ScheduleID (Optional) The ScheduleID of the planned (repeating) schedule.
function SCHEDULER:Stop( ScheduleID )
  self:F3( { ScheduleID } )
  self:T(string.format("Stopping scheduler ID=%s", tostring(ScheduleID)))
  _SCHEDULEDISPATCHER:Stop( self, ScheduleID )
end

--- Removes a specific schedule if a valid ScheduleID is provided.
-- @param #SCHEDULER self
-- @param #string ScheduleID (optional) The ScheduleID of the planned (repeating) schedule.
function SCHEDULER:Remove( ScheduleID )
  self:F3( { ScheduleID } )
  self:T(string.format("Removing scheduler ID=%s", tostring(ScheduleID)))
  _SCHEDULEDISPATCHER:RemoveSchedule( self, ScheduleID )
end

--- Clears all pending schedules.
-- @param #SCHEDULER self
function SCHEDULER:Clear()
  self:F3( )
  self:T(string.format("Clearing scheduler"))
  _SCHEDULEDISPATCHER:Clear( self )
end

--- Show tracing for this scheduler.
-- @param #SCHEDULER self
function SCHEDULER:ShowTrace()
  _SCHEDULEDISPATCHER:ShowTrace( self )
end

--- No tracing for this scheduler.
-- @param #SCHEDULER self
function SCHEDULER:NoTrace()
  _SCHEDULEDISPATCHER:NoTrace( self )
end
