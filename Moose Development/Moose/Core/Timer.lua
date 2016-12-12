--- This module contains the TIMER class.
-- 
-- ===
-- 
-- Takes care of scheduled function dispatching for defined in MOOSE classes.
-- 
-- ===
-- 
-- ===
-- 
-- ### Contributions: -
-- ### Authors: FlightControl : Design & Programming
-- 
-- @module Timer

--- The TIMER structure
-- @type TIMER
TIMER = {
  ClassName = "TIMER",
  CallID = 0,
}

function TIMER:New()
  local self = BASE:Inherit( self, BASE:New() )
  self:F3()
  return self
end

--- Add a Schedule to the ScheduleDispatcher.
-- The development of this method was really tidy.
-- It is constructed as such that a garbage collection is executed on the weak tables, when the Scheduler is nillified.
-- Nothing of this code should be modified without testing it thoroughly.
-- @param #TIMER self
-- @param Core.Scheduler#SCHEDULER Scheduler
function TIMER:AddSchedule( Scheduler )
  self:F3( { Scheduler = Scheduler } )

  -- Initialize the Functions array, which is a weakly coupled table.
  -- If the object used as the key is nil, then the garbage collector will remove the item from the Functions array.
  self.Schedulers = self.Schedulers or setmetatable( {}, { __mode = "k" } )

  self.CallID = self.CallID + 1
  self.Schedulers[Scheduler] = self.CallID
  
  self:E(self.Schedulers)

  self.Schedule = self.Schedule or setmetatable( {}, { __mode = "v" } )
  

  self.Schedule[self.CallID] = {}
  
  self.Schedule[self.CallID].ScheduleFunction = Scheduler.TimeEventFunction
  self.Schedule[self.CallID].ScheduleArguments = Scheduler.TimeEventFunctionArguments
  self.Schedule[self.CallID].ScheduleObject = Scheduler.TimeEventObject
  self.Schedule[self.CallID].ScheduleStart = Scheduler.StartSeconds + .001

  self:E( self.Schedule[self.CallID] )

  local function ScheduleCallHandler( CallID )

    local ErrorHandler = function( errmsg )
      env.info( "Error in timer function: " .. errmsg )
      if debug ~= nil then
        env.info( debug.traceback() )
      end
      return errmsg
    end

    BASE:E( { self } )

    local ScheduleFunction = self.Schedule[CallID].ScheduleFunction
    local ScheduleArguments = self.Schedule[CallID].ScheduleArguments
    local ScheduleObject = self.Schedule[CallID].ScheduleObject
    
    local Status, Result
    if ScheduleObject then
      local function Timer()
        return ScheduleFunction( ScheduleObject, unpack( ScheduleArguments ) ) 
      end
      Status, Result = xpcall( Timer, ErrorHandler )
    else
      local function Timer()
        return ScheduleFunction( unpack( ScheduleArguments ) ) 
      end
      Status, Result = xpcall( Timer, ErrorHandler )
    end
  end
  
  timer.scheduleFunction( 
    ScheduleCallHandler, 
    self.CallID, 
    timer.getTime() + 1
  )
  --[[
  
  
  self:T( Schedule.FunctionID )
  --]]

  return self.CallID
end



