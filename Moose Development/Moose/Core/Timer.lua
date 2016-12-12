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
  self:F3( { Scheduler } )

  -- Initialize the Functions array, which is a weakly coupled table.
  -- If the object used as the key is nil, then the garbage collector will remove the item from the Functions array.
  self.Schedulers = self.Schedulers or setmetatable( {}, { __mode = "v" } )

  self.CallID = self.CallID + 1
  self.Schedulers[self.CallID] = Scheduler
  
  Scheduler:E( { self.CallID, self.Schedulers[self.CallID] } )

  self.Schedule = self.Schedule or setmetatable( {}, { __mode = "v" } )
  self.Schedule[self.CallID] = {}
  self.Schedule[self.CallID].ScheduleStart = Scheduler.StartSeconds + .001
  self.Schedule[self.CallID].ScheduleStart = Scheduler.StartSeconds + .001

  self:E( self.Schedule[self.CallID] )

  self.Schedule[self.CallID].ScheduleCallHandler = function( CallID )
    self:E( CallID )

    local ErrorHandler = function( errmsg )
      env.info( "Error in timer function: " .. errmsg )
      if debug ~= nil then
        env.info( debug.traceback() )
      end
      return errmsg
    end

    local ScheduleFunction = self.Schedulers[CallID].TimeEventFunction
    local ScheduleArguments = self.Schedulers[CallID].TimeEventFunctionArguments
    local ScheduleObject = self.Schedulers[CallID].TimeEventObject
    
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
    self.Schedule[self.CallID].ScheduleCallHandler, 
    self.CallID, 
    timer.getTime() + 1
  )
  --[[
  
  
  self:T( Schedule.FunctionID )
  --]]

  return self.CallID
end

function TIMER:RemoveSchedule( CallID )

  self:F( CallID )
  self.Schedulers[CallID] = nil
end




