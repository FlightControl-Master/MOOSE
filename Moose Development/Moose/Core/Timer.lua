--- **Core** - Timer scheduler.
--
-- **Main Features:**
--
--    * Delay function calls
--    * Easy set up and little overhead
--    * Set start, stop and time interval
--    * Define max function calls
--
-- ===
--
-- ### Author: **funkyfranky**
-- @module Core.Timer
-- @image Core_Scheduler.JPG


--- TIMER class.
-- @type TIMER
-- @field #string ClassName Name of the class.
-- @field #string lid Class id string for output to DCS log file.
-- @field #number tid Timer ID returned by the DCS API function.
-- @field #number uid Unique ID of the timer.
-- @field #function func Timer function.
-- @field #table para Parameters passed to the timer function.
-- @field #number Tstart Relative start time in seconds.
-- @field #number Tstop Relative stop time in seconds.
-- @field #number dT Time interval between function calls in seconds.
-- @field #number ncalls Counter of function calls.
-- @field #number ncallsMax Max number of function calls. If reached, timer is stopped.
-- @field #boolean isrunning If `true`, timer is running. Else it was not started yet or was stopped.
-- @extends Core.Base#BASE

--- *Better three hours too soon than a minute too late.* - William Shakespeare
--
-- ===
--
-- ![Banner Image](..\Presentations\Timer\TIMER_Main.jpg)
--
-- # The TIMER Concept
-- 
-- The TIMER class is the little sister of the @{Core.Scheduler#SCHEDULER} class. It does the same thing but is a bit easier to use and has less overhead. It should be sufficient in many cases.
-- 
-- It provides an easy interface to the DCS [timer.scheduleFunction](https://wiki.hoggitworld.com/view/DCS_func_scheduleFunction).
-- 
-- # Construction
-- 
-- A new TIMER is created by the @{#TIMER.New}(*func*, *...*) function
-- 
--     local mytimer=TIMER:New(myfunction, a, b)
--     
-- The first parameter *func* is the function that is called followed by the necessary comma separeted parameters that are passed to that function.
-- 
-- ## Starting the Timer
-- 
-- The timer is started by the @{#TIMER.Start}(*Tstart*, *dT*, *Duration*) function
-- 
--     mytimer:Start(5, 1, 20)
--     
-- where
-- 
-- * *Tstart* is the relative start time in seconds. In the example, the first function call happens after 5 sec.
-- * *dT* is the time interval between function calls in seconds. Above, the function is called once per second.
-- * *Duration* is the duration in seconds after which the timer is stopped. This is relative to the start time. Here, the timer will run for 20 seconds.
--  
-- Note that
-- 
-- * if *Tstart* is not specified (*nil*), the first function call happens immediately, i.e. after one millisecond.
-- * if *dT* is not specified (*nil*), the function is called only once.
-- * if *Duration* is not specified (*nil*), the timer runs forever or until stopped manually or until the max function calls are reached (see below).
--
-- For example,
-- 
--     mytimer:Start(3)            -- Will call the function once after 3 seconds.
--     mytimer:Start(nil, 0.5)     -- Will call right now and then every 0.5 sec until all eternity.
--     mytimer:Start(nil, 2.0, 20) -- Will call right now and then every 2.0 sec for 20 sec.
--     mytimer:Start(1.0, nil, 10) -- Does not make sense as the function is only called once anyway. 
--
-- ## Stopping the Timer
--
-- The timer can be stopped manually by the @{#TIMER.Stop}(*Delay*) function
-- 
--     mytimer:Stop()
--
-- If the optional paramter *Delay* is specified, the timer is stopped after *delay* seconds.
-- 
-- ## Limit Function Calls
-- 
-- The timer can be stopped after a certain amount of function calles with the @{#TIMER.SetMaxFunctionCalls}(*Nmax*) function
-- 
--     mytimer:SetMaxFunctionCalls(20)
--
-- where *Nmax* is the number of calls after which the timer is stopped, here 20.
-- 
-- For example,
-- 
--     mytimer:SetMaxFunctionCalls(66):Start(1.0, 0.1)
--     
-- will start the timer after one second and call the function every 0.1 seconds. Once the function has been called 66 times, the timer is stopped.
-- 
--
-- @field #TIMER
TIMER = {
  ClassName      = "TIMER",
  lid            =   nil,
}

--- Timer ID.
_TIMERID=0

--- Timer data base.
--_TIMERDB={}

--- TIMER class version.
-- @field #string version
TIMER.version="0.1.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: A lot.
-- TODO: Write docs.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new TIMER object.
-- @param #TIMER self
-- @param #function Function The function to call.
-- @param ... Parameters passed to the function if any.
-- @return #TIMER self
function TIMER:New(Function, ...)

  -- Inherit BASE.
  local self=BASE:Inherit(self, BASE:New()) --#TIMER
  
  -- Function to call.
  self.func=Function
  
  -- Function arguments.
  self.para=arg or {}
  
  -- Number of function calls.
  self.ncalls=0
  
  -- Not running yet.
  self.isrunning=false
  
  -- Increase counter
  _TIMERID=_TIMERID+1
  
  -- Set UID.
  self.uid=_TIMERID
  
  -- Log id.
  self.lid=string.format("TIMER UID=%d | ", self.uid)
  
  -- Add to DB.
  --_TIMERDB[self.uid]=self
  
  return self
end

--- Create a new TIMER object.
-- @param #TIMER self
-- @param #number Tstart Relative start time in seconds.
-- @param #number dT Interval between function calls in seconds. If not specified `nil`, the function is called only once.
-- @param #number Duration Time in seconds for how long the timer is running. If not specified `nil`, the timer runs forever or until stopped manually by the `TIMER:Stop()` function.
-- @return #TIMER self
function TIMER:Start(Tstart, dT, Duration)

  -- Current time.
  local Tnow=timer.getTime()

  -- Start time in sec.
  self.Tstart=Tstart and Tnow+Tstart or Tnow+0.001  -- one millisecond delay if Tstart=nil
  
  -- Set time interval.
  self.dT=dT
  
  -- Stop time.
  if Duration then
    self.Tstop=self.Tstart+Duration
  end
  
  -- Call DCS timer function.
  self.tid=timer.scheduleFunction(self._Function, self, self.Tstart)
  
  -- Set log id.
  self.lid=string.format("TIMER UID=%d/%d | ", self.uid, self.tid)
  
  -- Is now running.
  self.isrunning=true
  
  -- Debug info.
  self:T(self.lid..string.format("Starting Timer in %.3f sec, dT=%s, Tstop=%s", self.Tstart-Tnow, tostring(self.dT), tostring(self.Tstop)))

  return self
end

--- Stop the timer by removing the timer function.
-- @param #TIMER self
-- @param #number Delay (Optional) Delay in seconds, before the timer is stopped.
-- @return #TIMER self
function TIMER:Stop(Delay)

  if Delay and Delay>0 then
  
    self.Tstop=timer.getTime()+Delay
    
  else

    if self.tid then
    
      -- Remove timer function.
      self:T(self.lid..string.format("Stopping timer by removing timer function after %d calls!", self.ncalls))
      timer.removeFunction(self.tid)
      
      -- Not running any more.
      self.isrunning=false
      
      -- Remove DB entry.
      --_TIMERDB[self.uid]=nil
      
    end
    
  end

  return self
end

--- Set max number of function calls. When the function has been called this many times, the TIMER is stopped.
-- @param #TIMER self
-- @param #number Nmax Set number of max function calls.
-- @return #TIMER self
function TIMER:SetMaxFunctionCalls(Nmax)
  self.ncallsMax=Nmax
  return self
end

--- Check if the timer has been started and was not stopped.
-- @param #TIMER self
-- @return #boolean If `true`, the timer is running.
function TIMER:IsRunning()
  return self.isrunning
end

--- Call timer function.
-- @param #TIMER self
-- @param #number time DCS model time in seconds.
-- @return #number Time when the function is called again or `nil` if the timer is stopped.
function TIMER:_Function(time)

  -- Call function.
  self.func(unpack(self.para))
  
  -- Increase number of calls.
  self.ncalls=self.ncalls+1
  
  -- Next time.
  local Tnext=self.dT and time+self.dT or nil
  
  -- Check if we stop the timer.
  local stopme=false
  if Tnext==nil then
    -- No next time.
    self:T(self.lid..string.format("No next time as dT=nil ==> Stopping timer after %d function calls", self.ncalls))
    stopme=true
  elseif self.Tstop and Tnext>self.Tstop then
    -- Stop time passed.
    self:T(self.lid..string.format("Stop time passed %.3f > %.3f ==> Stopping timer after %d function calls", Tnext, self.Tstop, self.ncalls))
    stopme=true
  elseif self.ncallsMax and self.ncalls>=self.ncallsMax then
    -- Number of max function calls reached.
    self:T(self.lid..string.format("Max function calls Nmax=%d reached ==> Stopping timer after %d function calls", self.ncallsMax, self.ncalls))
    stopme=true
  end
  
  if stopme then
    -- Remove timer function.
    self:Stop()
    return nil
  else
    -- Call again in Tnext seconds.
    return Tnext
  end
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------