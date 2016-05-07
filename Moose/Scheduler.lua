--- Models time events calling event handing functions.
-- @module Scheduler
-- @author FlightControl

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Cargo" )
Include.File( "Message" )


--- The SCHEDULER class
-- @type SCHEDULER
-- @extends Base#BASE
SCHEDULER = {
  ClassName = "SCHEDULER",
}


--- SCHEDULER constructor.
-- @param #SCHEDULER self
-- @param #function TimeEventFunction
-- @param #table TimeEventFunctionArguments
-- @param #number StartSeconds
-- @param #number RepeatSecondsInterval
-- @param #number RandomizationFactor
-- @param #number StopSeconds
-- @return #SCHEDULER
function SCHEDULER:New( TimeEventObject, TimeEventFunction, TimeEventFunctionArguments, StartSeconds, RepeatSecondsInterval, RandomizationFactor, StopSeconds )
  local self = BASE:Inherit( self, BASE:New() )
  self:F( { TimeEventObject, TimeEventFunction, TimeEventFunctionArguments, StartSeconds, RepeatSecondsInterval, RandomizationFactor, StopSeconds } )

  self.TimeEventObject = TimeEventObject
  self.TimeEventFunction = TimeEventFunction
  self.TimeEventFunctionArguments = TimeEventFunctionArguments
  self.StartSeconds = StartSeconds

  if RepeatSecondsInterval then
    self.RepeatSecondsInterval = RepeatSecondsInterval
  else
    self.RepeatSecondsInterval = 0
  end

  if RandomizationFactor then
    self.RandomizationFactor = RandomizationFactor
  else
    self.RandomizationFactor = 0
  end

  if StopSeconds then
    self.StopSeconds = StopSeconds
  end

  self.StartTime = timer.getTime()
  
  self:T("Calling function " .. timer.getTime() + self.StartSeconds )
  
  timer.scheduleFunction( self.Scheduler, self, timer.getTime() + self.StartSeconds + .01 )


  return self
end

function SCHEDULER:Scheduler()
  self:F( self.TimeEventFunctionArguments )
  
  local ErrorHandler = function( errmsg )

    env.info( "Error in SCHEDULER function:" .. errmsg )
    env.info( debug.traceback() )

    return errmsg
  end

  local Status, Result  
  if self.TimeEventObject then
    Status, Result = xpcall( function() return self.TimeEventFunction( self.TimeEventObject, unpack( self.TimeEventFunctionArguments ) ) end, ErrorHandler )
  else
    Status, Result = xpcall( function() return self.TimeEventFunction( unpack( self.TimeEventFunctionArguments ) ) end, ErrorHandler )
  end
  
  self:T( { Status, Result } )
  
  if Status and Status == true and Result and Result == true then
    if not self.StopSeconds or ( self.StopSeconds and timer.getTime() <= self.StartTime + self.StopSeconds ) then
      timer.scheduleFunction(
        self.Scheduler,
        self,
        timer.getTime() + self.RepeatSecondsInterval * math.random( self.RandomizationFactor * self.RepeatSecondsInterval ) + 0.01
      )
    end
  end

end






