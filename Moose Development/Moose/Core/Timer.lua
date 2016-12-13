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
function TIMER:AddSchedule( Scheduler, ScheduleFunction, ScheduleArguments, Start, Repeat, Randomize, Stop )
  self:F( { Scheduler, ScheduleFunction, ScheduleArguments, Start, Repeat, Randomize, Stop } )

  self.CallID = self.CallID + 1

  -- Initialize the Functions array, which is a weakly coupled table.
  -- If the object used as the key is nil, then the garbage collector will remove the item from the Functions array.
  self.Calls = self.Calls or setmetatable( {}, { __mode = "v" } )
  self.Calls[self.CallID] = Scheduler
  Scheduler:E( { self.CallID, self.Calls[self.CallID] } )
  
  self.Schedule = self.Schedule or setmetatable( {}, { __mode = "k" } )
  self.Schedule[Scheduler] = {}
  self.Schedule[Scheduler][self.CallID] = {}
  self.Schedule[Scheduler][self.CallID].Function = ScheduleFunction
  self.Schedule[Scheduler][self.CallID].Arguments = ScheduleArguments
  self.Schedule[Scheduler][self.CallID].StartTime = timer.getTime() + ( Start or 0 )
  self.Schedule[Scheduler][self.CallID].Start = Start + .001
  self.Schedule[Scheduler][self.CallID].Repeat = Repeat
  self.Schedule[Scheduler][self.CallID].Randomize = Randomize
  self.Schedule[Scheduler][self.CallID].Stop = Stop

  self:E( self.Schedule[Scheduler][self.CallID] )

  self.Schedule[Scheduler][self.CallID].CallHandler = function( CallID )
    self:E( CallID )

    local ErrorHandler = function( errmsg )
      env.info( "Error in timer function: " .. errmsg )
      if debug ~= nil then
        env.info( debug.traceback() )
      end
      return errmsg
    end
    
    local Scheduler = self.Calls[CallID]

    self:E( { Scheduler = Scheduler } )
    
    if self.Calls[CallID] then

      local Schedule = self.Schedule[Scheduler][CallID]
      
      self:E( { Schedule = Schedule } )

      local ScheduleObject = Scheduler.TimeEventObject
      local ScheduleFunction = Schedule.Function
      local ScheduleArguments = Schedule.Arguments
      local Start = Schedule.Start
      local Repeat = Schedule.Repeat or 0
      local Randomize = Schedule.Randomize or 0
      local Stop = Schedule.Stop or 0
      local ScheduleID = Schedule.ScheduleID
      
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
      
      local CurrentTime = timer.getTime()
      local StartTime = CurrentTime + Start
      
      if Status and (( Result == nil ) or ( Result and Result ~= false ) ) then
        if Repeat ~= 0 and ( Stop == 0 ) or ( Stop ~= 0 and CurrentTime <= StartTime + Stop ) then
          local ScheduleTime =
            CurrentTime +
            Repeat +
            math.random(
              - ( Randomize * Repeat / 2 ),
              ( Randomize * Repeat  / 2 )
            ) +
            0.01
          self:T( { ScheduleArguments, "Repeat:", CurrentTime, ScheduleTime } )
          return ScheduleTime -- returns the next time the function needs to be called.
        else
          timer.removeFunction( ScheduleID )
          ScheduleID = nil
        end
      else
        timer.removeFunction( ScheduleID )
        ScheduleID = nil
      end
    else
      self:E( "Scheduled obscolete call ..." )
    end
    
    return nil
  end
  
  
  self.Schedule[Scheduler][self.CallID].ScheduleID = timer.scheduleFunction( 
    self.Schedule[Scheduler][self.CallID].CallHandler, 
    self.CallID, 
    timer.getTime() + self.Schedule[Scheduler][self.CallID].Start
  )
  
  return self.CallID
end

function TIMER:RemoveSchedule( CallID )
  self:F( CallID )

  local Schedule = self.Calls[CallID]
    
  if Schedule then
    local ScheduleID = Schedule.ScheduleID
    timer.removeFunction( ScheduleID )
    ScheduleID = nil
    Schedule = nil
  end
end




