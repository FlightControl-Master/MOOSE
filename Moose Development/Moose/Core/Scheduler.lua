--- **Core** - SCHEDULER prepares and handles the **execution of functions over scheduled time (intervals)**.
--
-- ![Banner Image](..\Presentations\SCHEDULER\Dia1.JPG)
-- 
-- ===
-- 
-- # 1) @{Scheduler#SCHEDULER} class, extends @{Base#BASE}
-- 
-- The @{Scheduler#SCHEDULER} class creates schedule.
--
-- ## 1.1) SCHEDULER constructor
-- 
-- The SCHEDULER class is quite easy to use, but note that the New constructor has variable parameters:
--
--  * @{Scheduler#SCHEDULER.New}( nil ): Setup a new SCHEDULER object, which is persistently executed after garbage collection.
--  * @{Scheduler#SCHEDULER.New}( Object ): Setup a new SCHEDULER object, which is linked to the Object. When the Object is nillified or destroyed, the SCHEDULER object will also be destroyed and stopped after garbage collection.
--  * @{Scheduler#SCHEDULER.New}( nil, Function, FunctionArguments, Start, ... ): Setup a new persistent SCHEDULER object, and start a new schedule for the Function with the defined FunctionArguments according the Start and sequent parameters.
--  * @{Scheduler#SCHEDULER.New}( Object, Function, FunctionArguments, Start, ... ): Setup a new SCHEDULER object, linked to Object, and start a new schedule for the Function with the defined FunctionArguments according the Start and sequent parameters.
--
-- ## 1.2) SCHEDULER timer stopping and (re-)starting.
--
-- The SCHEDULER can be stopped and restarted with the following methods:
--
--  * @{Scheduler#SCHEDULER.Start}(): (Re-)Start the schedules within the SCHEDULER object. If a CallID is provided to :Start(), only the schedule referenced by CallID will be (re-)started.
--  * @{Scheduler#SCHEDULER.Stop}(): Stop the schedules within the SCHEDULER object. If a CallID is provided to :Stop(), then only the schedule referenced by CallID will be stopped.
--
-- ## 1.3) Create a new schedule
-- 
-- With @{Scheduler#SCHEDULER.Schedule}() a new time event can be scheduled. This function is used by the :New() constructor when a new schedule is planned.
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
-- ### Test Missions:
-- 
--   * SCH - Scheduler
-- 
-- ===
--
-- @module Scheduler


--- The SCHEDULER class
-- @type SCHEDULER
-- @field #number ScheduleID the ID of the scheduler.
-- @extends Core.Base#BASE
SCHEDULER = {
  ClassName = "SCHEDULER",
  Schedules = {},
}

--- SCHEDULER constructor.
-- @param #SCHEDULER self
-- @param #table SchedulerObject Specified for which Moose object the timer is setup. If a value of nil is provided, a scheduler will be setup without an object reference.
-- @param #function SchedulerFunction The event function to be called when a timer event occurs. The event function needs to accept the parameters specified in SchedulerArguments.
-- @param #table SchedulerArguments Optional arguments that can be given as part of scheduler. The arguments need to be given as a table { param1, param 2, ... }.
-- @param #number Start Specifies the amount of seconds that will be waited before the scheduling is started, and the event function is called.
-- @param #number Repeat Specifies the interval in seconds when the scheduler will call the event function.
-- @param #number RandomizeFactor Specifies a randomization factor between 0 and 1 to randomize the Repeat.
-- @param #number Stop Specifies the amount of seconds when the scheduler will be stopped.
-- @return #SCHEDULER self.
-- @return #number The ScheduleID of the planned schedule.
function SCHEDULER:New( SchedulerObject, SchedulerFunction, SchedulerArguments, Start, Repeat, RandomizeFactor, Stop )
  local self = BASE:Inherit( self, BASE:New() )
  self:F2( { Start, Repeat, RandomizeFactor, Stop } )

  local ScheduleID = nil
  
  self.MasterObject = SchedulerObject
  
  if SchedulerFunction then
    ScheduleID = self:Schedule( SchedulerObject, SchedulerFunction, SchedulerArguments, Start, Repeat, RandomizeFactor, Stop )
  end

  return self, ScheduleID
end

--function SCHEDULER:_Destructor()
--  --self:E("_Destructor")
--
--  _SCHEDULEDISPATCHER:RemoveSchedule( self.CallID )
--end

--- Schedule a new time event. Note that the schedule will only take place if the scheduler is *started*. Even for a single schedule event, the scheduler needs to be started also.
-- @param #SCHEDULER self
-- @param #table SchedulerObject Specified for which Moose object the timer is setup. If a value of nil is provided, a scheduler will be setup without an object reference.
-- @param #function SchedulerFunction The event function to be called when a timer event occurs. The event function needs to accept the parameters specified in SchedulerArguments.
-- @param #table SchedulerArguments Optional arguments that can be given as part of scheduler. The arguments need to be given as a table { param1, param 2, ... }.
-- @param #number Start Specifies the amount of seconds that will be waited before the scheduling is started, and the event function is called.
-- @param #number Repeat Specifies the interval in seconds when the scheduler will call the event function.
-- @param #number RandomizeFactor Specifies a randomization factor between 0 and 1 to randomize the Repeat.
-- @param #number Stop Specifies the amount of seconds when the scheduler will be stopped.
-- @return #number The ScheduleID of the planned schedule.
function SCHEDULER:Schedule( SchedulerObject, SchedulerFunction, SchedulerArguments, Start, Repeat, RandomizeFactor, Stop )
  self:F2( { Start, Repeat, RandomizeFactor, Stop } )
  self:T3( { SchedulerArguments } )

  local ObjectName = "-"
  if SchedulerObject and SchedulerObject.ClassName and SchedulerObject.ClassID then 
    ObjectName = SchedulerObject.ClassName .. SchedulerObject.ClassID
  end
  self:F3( { "Schedule :", ObjectName, tostring( SchedulerObject ),  Start, Repeat, RandomizeFactor, Stop } )
  self.SchedulerObject = SchedulerObject
  
  local ScheduleID = _SCHEDULEDISPATCHER:AddSchedule( 
    self, 
    SchedulerFunction,
    SchedulerArguments,
    Start,
    Repeat,
    RandomizeFactor,
    Stop
  )
  
  self.Schedules[#self.Schedules+1] = ScheduleID

  return ScheduleID
end

--- (Re-)Starts the schedules or a specific schedule if a valid ScheduleID is provided.
-- @param #SCHEDULER self
-- @param #number ScheduleID (optional) The ScheduleID of the planned (repeating) schedule.
function SCHEDULER:Start( ScheduleID )
  self:F3( { ScheduleID } )

  _SCHEDULEDISPATCHER:Start( self, ScheduleID )
end

--- Stops the schedules or a specific schedule if a valid ScheduleID is provided.
-- @param #SCHEDULER self
-- @param #number ScheduleID (optional) The ScheduleID of the planned (repeating) schedule.
function SCHEDULER:Stop( ScheduleID )
  self:F3( { ScheduleID } )

  _SCHEDULEDISPATCHER:Stop( self, ScheduleID )
end

--- Removes a specific schedule if a valid ScheduleID is provided.
-- @param #SCHEDULER self
-- @param #number ScheduleID (optional) The ScheduleID of the planned (repeating) schedule.
function SCHEDULER:Remove( ScheduleID )
  self:F3( { ScheduleID } )

  _SCHEDULEDISPATCHER:Remove( self, ScheduleID )
end

--- Clears all pending schedules.
-- @param #SCHEDULER self
function SCHEDULER:Clear()
  self:F3( )

  _SCHEDULEDISPATCHER:Clear( self )
end














