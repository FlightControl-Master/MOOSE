-------------------------------------------------------------------------------
-- @module DCStimer

--- @type timer


--- Returns model time in seconds.
-- @function [parent=#timer] getTime
-- @return #Time   

--- Returns mission time in seconds.
-- @function [parent=#timer] getAbsTime
-- @return #Time

--- Returns mission start time in seconds.
-- @function [parent=#timer] getTime0
-- @return #Time

--- Schedules function to call at desired model time.
--  Time function FunctionToCall(any argument, Time time)
--  
--  ...
--  
--  return ...
--  
--  end
--  
--  Must return model time of next call or nil. Note that the DCS scheduler calls the function in protected mode and any Lua errors in the called function will be trapped and not reported. If the function triggers a Lua error then it will be terminated and not scheduled to run again. 
-- @function [parent=#timer] scheduleFunction
-- @param #FunctionToCall functionToCall Lua-function to call. Must have prototype of FunctionToCall. 
-- @param functionArgument Function argument of any type to pass to functionToCall.
-- @param #Time time Model time of the function call.
-- @return functionId

--- Re-schedules function to call at another model time.
-- @function [parent=#timer] setFunctionTime 
-- @param functionId Lua-function to call. Must have prototype of FunctionToCall. 
-- @param #Time time Model time of the function call. 


--- Removes the function from schedule.
-- @function [parent=#timer] removeFunction
-- @param functionId Function identifier to remove from schedule 

timer = {} --#timer
