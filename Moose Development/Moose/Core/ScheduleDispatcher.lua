--- **Core** -- SCHEDULEDISPATCHER dispatches the different schedules.
-- 
-- ===
-- 
-- Takes care of the creation and dispatching of scheduled functions for SCHEDULER objects.
-- 
-- This class is tricky and needs some thorough explanation.
-- SCHEDULE classes are used to schedule functions for objects, or as persistent objects.
-- The SCHEDULEDISPATCHER class ensures that:
-- 
--   - Scheduled functions are planned according the SCHEDULER object parameters.
--   - Scheduled functions are repeated when requested, according the SCHEDULER object parameters.
--   - Scheduled functions are automatically removed when the schedule is finished, according the SCHEDULER object parameters.
-- 
-- The SCHEDULEDISPATCHER class will manage SCHEDULER object in memory during garbage collection:
-- 
--   - When a SCHEDULER object is not attached to another object (that is, it's first :Schedule() parameter is nil), then the SCHEDULER object is _persistent_ within memory.
--   - When a SCHEDULER object *is* attached to another object, then the SCHEDULER object is _not persistent_ within memory after a garbage collection!
--   
-- The none persistency of SCHEDULERS attached to objects is required to allow SCHEDULER objects to be garbage collectged, when the parent object is also desroyed or nillified and garbage collected.
-- Even when there are pending timer scheduled functions to be executed for the SCHEDULER object,  
-- these will not be executed anymore when the SCHEDULER object has been destroyed.
-- 
-- The SCHEDULEDISPATCHER allows multiple scheduled functions to be planned and executed for one SCHEDULER object.
-- The SCHEDULER object therefore keeps a table of "CallID's", which are returned after each planning of a new scheduled function by the SCHEDULEDISPATCHER.
-- The SCHEDULER object plans new scheduled functions through the @{Core.Scheduler#SCHEDULER.Schedule}() method. 
-- The Schedule() method returns the CallID that is the reference ID for each planned schedule.
-- 
-- ===
-- 
-- ### Contributions: -
-- ### Authors: FlightControl : Design & Programming
-- 
-- @module Core.ScheduleDispatcher
-- @image Core_Schedule_Dispatcher.JPG

--- SCHEDULEDISPATCHER class.
-- @type SCHEDULEDISPATCHER
-- @field #string ClassName Name of the class.
-- @field #number CallID Call ID counter.
-- @field #table PersistentSchedulers Persistant schedulers.
-- @field #table ObjectSchedulers Schedulers that only exist as long as the master object exists.
-- @field #table Schedule Meta table setmetatable( {}, { __mode = "k" } ).
-- @extends Core.Base#BASE

--- The SCHEDULEDISPATCHER structure
-- @type SCHEDULEDISPATCHER
SCHEDULEDISPATCHER = {
  ClassName            = "SCHEDULEDISPATCHER",
  CallID               =   0,
  PersistentSchedulers =  {},
  ObjectSchedulers     =  {},
  Schedule             = nil,
}

--- Player data table holding all important parameters of each player.
-- @type SCHEDULEDISPATCHER.ScheduleData
-- @field #function Function The schedule function to be called.
-- @field #table Arguments Schedule function arguments.
-- @field #number Start Start time in seconds.
-- @field #number Repeat Repeat time intervall in seconds.
-- @field #number Randomize Randomization factor [0,1].
-- @field #number Stop Stop time in seconds.
-- @field #number StartTime Time in seconds when the scheduler is created.
-- @field #number ScheduleID Schedule ID.
-- @field #function CallHandler Function to be passed to the DCS timer.scheduleFunction().
-- @field #boolean ShowTrace If true, show tracing info.

--- Create a new schedule dispatcher object.
-- @param #SCHEDULEDISPATCHER self
-- @return #SCHEDULEDISPATCHER self
function SCHEDULEDISPATCHER:New()
  local self = BASE:Inherit( self, BASE:New() )
  self:F3()
  return self
end

--- Add a Schedule to the ScheduleDispatcher.
-- The development of this method was really tidy.
-- It is constructed as such that a garbage collection is executed on the weak tables, when the Scheduler is nillified.
-- Nothing of this code should be modified without testing it thoroughly.
-- @param #SCHEDULEDISPATCHER self
-- @param Core.Scheduler#SCHEDULER Scheduler Scheduler object.
-- @param #function ScheduleFunction Scheduler function.
-- @param #table ScheduleArguments Table of arguments passed to the ScheduleFunction.
-- @param #number Start Start time in seconds.
-- @param #number Repeat Repeat interval in seconds.
-- @param #number Randomize Radomization factor [0,1].
-- @param #number Stop Stop time in seconds.
-- @param #number TraceLevel Trace level [0,3].
-- @param Core.Fsm#FSM Fsm Finite state model.
-- @return #string Call ID or nil.
function SCHEDULEDISPATCHER:AddSchedule( Scheduler, ScheduleFunction, ScheduleArguments, Start, Repeat, Randomize, Stop, TraceLevel, Fsm )
  self:F2( { Scheduler, ScheduleFunction, ScheduleArguments, Start, Repeat, Randomize, Stop, TraceLevel, Fsm } )

  -- Increase counter.
  self.CallID = self.CallID + 1
  
  -- Create ID.
  local CallID = self.CallID .. "#" .. ( Scheduler.MasterObject and Scheduler.MasterObject.GetClassNameAndID and Scheduler.MasterObject:GetClassNameAndID() or "" ) or ""
  
  self:T2(string.format("Adding schedule #%d CallID=%s", self.CallID, CallID))

  -- Initialize PersistentSchedulers
  self.PersistentSchedulers = self.PersistentSchedulers or {}

  -- Initialize the ObjectSchedulers array, which is a weakly coupled table.
  -- If the object used as the key is nil, then the garbage collector will remove the item from the Functions array.
  self.ObjectSchedulers = self.ObjectSchedulers or setmetatable( {}, { __mode = "v" } ) 
  
  if Scheduler.MasterObject then
    self.ObjectSchedulers[CallID] = Scheduler
    self:F3( { CallID = CallID, ObjectScheduler = tostring(self.ObjectSchedulers[CallID]), MasterObject = tostring(Scheduler.MasterObject) } )
  else
    self.PersistentSchedulers[CallID] = Scheduler
    self:F3( { CallID = CallID, PersistentScheduler = self.PersistentSchedulers[CallID] } )
  end
  
  self.Schedule = self.Schedule or setmetatable( {}, { __mode = "k" } )
  self.Schedule[Scheduler] = self.Schedule[Scheduler] or {}
  self.Schedule[Scheduler][CallID] = {}  --#SCHEDULEDISPATCHER.ScheduleData
  self.Schedule[Scheduler][CallID].Function = ScheduleFunction
  self.Schedule[Scheduler][CallID].Arguments = ScheduleArguments
  self.Schedule[Scheduler][CallID].StartTime = timer.getTime() + ( Start or 0 )
  self.Schedule[Scheduler][CallID].Start = Start + 0.001
  self.Schedule[Scheduler][CallID].Repeat = Repeat or 0
  self.Schedule[Scheduler][CallID].Randomize = Randomize or 0
  self.Schedule[Scheduler][CallID].Stop = Stop
  
  
  -- This section handles the tracing of the scheduled calls.
  -- Because these calls will be executed with a delay, we inspect the place where these scheduled calls are initiated.
  -- The Info structure contains the output of the debug.getinfo() calls, which inspects the call stack for the function name, line number and source name.
  -- The call stack has many levels, and the correct semantical function call depends on where in the code AddSchedule was "used".
  --   - Using SCHEDULER:New()
  --   - Using Schedule:AddSchedule()
  --   - Using Fsm:__Func()
  --   - Using Class:ScheduleOnce()
  --   - Using Class:ScheduleRepeat()
  --   - ...
  -- So for each of these scheduled call variations, AddSchedule is the workhorse which will schedule the call.
  -- But the correct level with the correct semantical function location will differ depending on the above scheduled call invocation forms.
  -- That's where the field TraceLevel contains optionally the level in the call stack where the call information is obtained.
  -- The TraceLevel field indicates the correct level where the semantical scheduled call was invoked within the source, ensuring that function name, line number and source name are correct.
  -- There is one quick ...
  -- The FSM class models scheduled calls using the __Func syntax. However, these functions are "tailed".
  -- There aren't defined anywhere within the source code, but rather implemented as triggers within the FSM logic, 
  -- and using the onbefore, onafter, onenter, onleave prefixes. (See the FSM for details).
  -- Therefore, in the call stack, at the TraceLevel these functions are mentioned as "tail calls", and the Info.name field will be nil as a result.
  -- To obtain the correct function name for FSM object calls, the function is mentioned in the call stack at a higher stack level.
  -- So when function name stored in Info.name is nil, then I inspect the function name within the call stack one level higher.
  -- So this little piece of code does its magic wonderfully, preformance overhead is neglectible, as scheduled calls don't happen that often.

  local Info = {}
  
  if debug then
    TraceLevel = TraceLevel or 2
    Info = debug.getinfo( TraceLevel, "nlS" )
    local name_fsm = debug.getinfo( TraceLevel - 1, "n" ).name -- #string
    if name_fsm then
      Info.name = name_fsm
    end
  end

  self:T3( self.Schedule[Scheduler][CallID] )

  --- Function passed to the DCS timer.scheduleFunction()
  self.Schedule[Scheduler][CallID].CallHandler = function( Params )
    
    local CallID = Params.CallID
    local Info = Params.Info or {}
    local Source = Info.source or "?"
    local Line = Info.currentline or "?"
    local Name = Info.name or "?"

    local ErrorHandler = function( errmsg )
      env.info( "Error in timer function: " .. errmsg )
      if BASE.Debug ~= nil then
        env.info( BASE.Debug.traceback() )
      end
      return errmsg
    end
    
    -- Get object or persistant scheduler object.
    local Scheduler = self.ObjectSchedulers[CallID]  --Core.Scheduler#SCHEDULER
    if not Scheduler then
      Scheduler = self.PersistentSchedulers[CallID]
    end
    
    --self:T3( { Scheduler = Scheduler } )
    
    if Scheduler then

      local MasterObject = tostring(Scheduler.MasterObject)
      
      -- Schedule object.
      local Schedule = self.Schedule[Scheduler][CallID]  --#SCHEDULEDISPATCHER.ScheduleData
      
      --self:T3( { Schedule = Schedule } )

      local SchedulerObject = Scheduler.MasterObject --Scheduler.SchedulerObject Now is this the Maste or Scheduler object?
      local ShowTrace       = Scheduler.ShowTrace
      
      local ScheduleFunction  = Schedule.Function
      local ScheduleArguments = Schedule.Arguments or {}
      local Start             = Schedule.Start
      local Repeat            = Schedule.Repeat or 0
      local Randomize         = Schedule.Randomize or 0
      local Stop              = Schedule.Stop or 0
      local ScheduleID        = Schedule.ScheduleID
      
      
      local Prefix = ( Repeat == 0 ) and "--->" or "+++>"
      
      local Status, Result
      --self:E( { SchedulerObject = SchedulerObject } )
      if SchedulerObject then
        local function Timer()
          if ShowTrace then
            SchedulerObject:T( Prefix .. Name .. ":" .. Line .. " (" .. Source .. ")" )
          end
          return ScheduleFunction( SchedulerObject, unpack( ScheduleArguments ) ) 
        end
        Status, Result = xpcall( Timer, ErrorHandler )
      else
        local function Timer()
          if ShowTrace then
            self:T( Prefix .. Name .. ":" .. Line .. " (" .. Source .. ")" )
          end
          return ScheduleFunction( unpack( ScheduleArguments ) ) 
        end
        Status, Result = xpcall( Timer, ErrorHandler )
      end
      
      local CurrentTime = timer.getTime()
      local StartTime = Schedule.StartTime

      -- Debug info.
      self:F3( { CallID=CallID, ScheduleID=ScheduleID, Master = MasterObject, CurrentTime = CurrentTime, StartTime = StartTime, Start = Start, Repeat = Repeat, Randomize = Randomize, Stop = Stop } )
      
      
      if Status and (( Result == nil ) or ( Result and Result ~= false ) ) then
      
        if Repeat ~= 0 and ( ( Stop == 0 ) or ( Stop ~= 0 and CurrentTime <= StartTime + Stop ) ) then
          local ScheduleTime = CurrentTime + Repeat + math.random(- ( Randomize * Repeat / 2 ), ( Randomize * Repeat  / 2 )) + 0.0001  -- Accuracy
          --self:T3( { Repeat = CallID, CurrentTime, ScheduleTime, ScheduleArguments } )
          return ScheduleTime -- returns the next time the function needs to be called.
        else
          self:Stop( Scheduler, CallID )
        end
        
      else
        self:Stop( Scheduler, CallID )
      end
    else
      self:I( "<<<>" .. Name .. ":" .. Line .. " (" .. Source .. ")" )
    end
    
    return nil
  end
  
  self:Start( Scheduler, CallID, Info )
  
  return CallID
end

--- Remove schedule.
-- @param #SCHEDULEDISPATCHER self
-- @param Core.Scheduler#SCHEDULER Scheduler Scheduler object.
-- @param #table CallID Call ID.
function SCHEDULEDISPATCHER:RemoveSchedule( Scheduler, CallID )
  self:F2( { Remove = CallID, Scheduler = Scheduler } )

  if CallID then
    self:Stop( Scheduler, CallID )
    self.Schedule[Scheduler][CallID] = nil
  end
end

--- Start dispatcher.
-- @param #SCHEDULEDISPATCHER self
-- @param Core.Scheduler#SCHEDULER Scheduler Scheduler object.
-- @param #table CallID (Optional) Call ID.
-- @param #string Info (Optional) Debug info.
function SCHEDULEDISPATCHER:Start( Scheduler, CallID, Info )
  self:F2( { Start = CallID, Scheduler = Scheduler } )
  
  if CallID then
  
    local Schedule = self.Schedule[Scheduler][CallID] --#SCHEDULEDISPATCHER.ScheduleData
    
    -- Only start when there is no ScheduleID defined!
    -- This prevents to "Start" the scheduler twice with the same CallID...
    if not Schedule.ScheduleID then
    
      -- Current time in seconds.
      local Tnow=timer.getTime()
    
      Schedule.StartTime = Tnow  -- Set the StartTime field to indicate when the scheduler started.
            
      -- Start DCS schedule function https://wiki.hoggitworld.com/view/DCS_func_scheduleFunction
      Schedule.ScheduleID = timer.scheduleFunction(Schedule.CallHandler, { CallID = CallID, Info = Info }, Tnow + Schedule.Start)
      
      self:T(string.format("Starting scheduledispatcher Call ID=%s ==> Schedule ID=%s", tostring(CallID), tostring(Schedule.ScheduleID)))
    end
    
  else
  
    -- Recursive.
    for CallID, Schedule in pairs( self.Schedule[Scheduler] or {} ) do
      self:Start( Scheduler, CallID, Info ) -- Recursive
    end
    
  end
end

--- Stop dispatcher.
-- @param #SCHEDULEDISPATCHER self
-- @param Core.Scheduler#SCHEDULER Scheduler Scheduler object.
-- @param #table CallID Call ID.
function SCHEDULEDISPATCHER:Stop( Scheduler, CallID )
  self:F2( { Stop = CallID, Scheduler = Scheduler } )

  if CallID then
  
    local Schedule = self.Schedule[Scheduler][CallID] --#SCHEDULEDISPATCHER.ScheduleData
    
    -- Only stop when there is a ScheduleID defined for the CallID. So, when the scheduler was stopped before, do nothing.
    if Schedule.ScheduleID then
    
      self:T(string.format("scheduledispatcher stopping scheduler CallID=%s, ScheduleID=%s", tostring(CallID), tostring(Schedule.ScheduleID)))
    
      -- Remove schedule function https://wiki.hoggitworld.com/view/DCS_func_removeFunction
      timer.removeFunction(Schedule.ScheduleID)
      
      Schedule.ScheduleID = nil
      
    else
      self:T(string.format("Error no ScheduleID for CallID=%s", tostring(CallID)))
    end
    
  else
  
    for CallID, Schedule in pairs( self.Schedule[Scheduler] or {} ) do
      self:Stop( Scheduler, CallID ) -- Recursive
    end
    
  end
end

--- Clear all schedules by stopping all dispatchers.
-- @param #SCHEDULEDISPATCHER self
-- @param Core.Scheduler#SCHEDULER Scheduler Scheduler object.
function SCHEDULEDISPATCHER:Clear( Scheduler )
  self:F2( { Scheduler = Scheduler } )

  for CallID, Schedule in pairs( self.Schedule[Scheduler] or {} ) do
    self:Stop( Scheduler, CallID ) -- Recursive
  end
end

--- Shopw tracing info.
-- @param #SCHEDULEDISPATCHER self
-- @param Core.Scheduler#SCHEDULER Scheduler Scheduler object.
function SCHEDULEDISPATCHER:ShowTrace( Scheduler )
  self:F2( { Scheduler = Scheduler } )
  Scheduler.ShowTrace = true
end

--- No tracing info.
-- @param #SCHEDULEDISPATCHER self
-- @param Core.Scheduler#SCHEDULER Scheduler Scheduler object.
function SCHEDULEDISPATCHER:NoTrace( Scheduler )
  self:F2( { Scheduler = Scheduler } )
  Scheduler.ShowTrace = false
end

