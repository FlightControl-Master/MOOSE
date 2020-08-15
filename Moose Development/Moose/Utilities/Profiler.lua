--- **Utils** - Lua Profiler.
--
--
--
-- ===
--
-- ### Author: **TAW CougarNL**, *funkyfranky*
-- 
-- @module Utilities.PROFILER
-- @image MOOSE.JPG


--- PROFILER class.
-- @type PROFILER
-- @field #string ClassName Name of the class.
-- @field #table Counters Counters.
-- @field #table dInfo Info.
-- @field #table fTime Function time.
-- @field #table fTimeTotal Total function time.
-- @field #table eventhandler Event handler to get mission end event.

--- *The emperor counsels simplicity. First principles. Of each particular thing, ask: What is it in itself, in its own constitution? What is its causal nature? *
--
-- ===
--
-- ![Banner Image](..\Presentations\Utilities\PROFILER_Main.jpg)
--
-- # The PROFILER Concept
-- 
-- Profile your lua code. This tells you, which functions are called very often and which consume most CPU time.
-- With this information you could optimize the perfomance of your code.
-- 
-- # Prerequisites
-- 
-- The modules **os** and **lfs** need to be desanizied.
-- 
-- 
-- # Start
-- 
-- The profiler can simply be started by
-- 
--     PROFILER.Start()
--    
-- The start can be delayed by specifying a the amount of seconds as argument, e.g. PROFILER.Start(60) to start profiling in 60 seconds.
-- 
-- # Stop
-- 
-- The profiler automatically stops when the mission ends. But it can be stopped any time by calling
-- 
--     PROFILER.Stop()
--    
-- The stop call can be delayed by specifying the delay in seconds as optional argument, e.g. PROFILER.Stop(120) to stop it in 120 seconds.
-- 
-- # Output
-- 
-- The profiler output is written to a file in your DCS home folder
-- 
--     X:\User\<Your User Name>\Saved Games\DCS OpenBeta\Logs
-- 
-- ## Sort Output
-- 
-- By default the output is sorted with respect to the total time a function used.
-- 
-- The output can also be sorted with respect to the number of times the function was called by setting
-- 
--     PROFILER.sortBy=1
-- 
-- @field #PROFILER
PROFILER = {
  ClassName      = "PROFILER",
  Counters       = {},
  dInfo          = {},
  fTime          = {},
  fTimeTotal     = {},
  eventHandler   = {},
  startTime      = nil,
  runTime        = nil,
  logUnknown     = false,
  lowCpsThres    = 5,
  fileName       = "",
}

--- Waypoint data.
-- @type PROFILER.Data
-- @field #string func The function name.
-- @field #string src The source file.
-- @field #number line The line number
-- @field #number count Number of function calls.
-- @field #number tm Total time in seconds.

PROFILER.logUnknown=false  -- Log unknown functions
PROFILER.lowCpsThres=5     -- Skip results with less than X calls per second
PROFILER.fileName="_LuaProfiler.txt"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Start/Stop Profiler
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Start profiler.
-- @param #number Delay Delay in seconds before profiler is stated. Default is immediately.
-- @param #number Duration Duration in (game) seconds before the profiler is stopped. Default is when mission ends.
function PROFILER.Start(Delay, Duration)

  if Delay and Delay>0 then
    BASE:ScheduleOnce(Delay, PROFILER.Start, 0, Duration)
  else

    PROFILER.TstartGame=timer.getTime()
    PROFILER.TstartOS=os.clock()
    
    -- Add event handler.
    world.addEventHandler(PROFILER.eventHandler)
    
    -- Message to screen.
    local function showProfilerRunning()
      timer.scheduleFunction(showProfilerRunning, nil, timer.getTime()+600)
      trigger.action.outText("### Profiler running ###", 600)
    end
    
    -- Message.
    showProfilerRunning()
    
    -- Info in log.
    BASE:I('############################   Profiler Started   ############################')
  
    -- Set hook.
    debug.sethook(PROFILER.hook, "cr")
    
    if Duration then
      PROFILER.Stop(Duration)
    end
    
  end
  
end

--- Stop profiler.
-- @param #number Delay Delay before stop in seconds.
function PROFILER.Stop(Delay)

  if Delay and Delay>0 then
    
    BASE:ScheduleOnce(Delay, PROFILER.Stop)
  
  else

    -- Remove hook.
    debug.sethook()
  
    
    -- Run time.
    PROFILER.runTimeGame=timer.getTime()-PROFILER.TstartGame
    PROFILER.runTimeOS=os.clock()-PROFILER.TstartOS
    
    -- Show info.
    PROFILER.showInfo()
    
  end

end

--- Event handler.
function PROFILER.eventHandler:onEvent(event)
  if event.id==world.event.S_EVENT_MISSION_END then
    PROFILER.Stop()
  end
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Hook
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Debug hook.
-- @param #table event Event.
function PROFILER.hook(event)

  local f=debug.getinfo(2, "f").func
  
  if event=='call' then
  
    if PROFILER.Counters[f]==nil then
    
      PROFILER.Counters[f]=1
      PROFILER.dInfo[f]=debug.getinfo(2,"Sn")
      
      if PROFILER.fTimeTotal[f]==nil then
        PROFILER.fTimeTotal[f]=0
      end
      
    else
      PROFILER.Counters[f]=PROFILER.Counters[f]+1
    end
    
    if PROFILER.fTime[f]==nil then
      PROFILER.fTime[f]=os.clock()
    end
    
  elseif (event=='return') then
  
    if PROFILER.fTime[f]~=nil then
      PROFILER.fTimeTotal[f]=PROFILER.fTimeTotal[f]+(os.clock()-PROFILER.fTime[f])
      PROFILER.fTime[f]=nil
    end
    
  end
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Data
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get data.
-- @param #function func Function.
-- @return #string Function name.
-- @return #string Source file name.
-- @return #string Line number.
-- @return #number Function time in seconds.
function PROFILER.getData(func)

  local n=PROFILER.dInfo[func]
  
  if n.what=="C" then
    return n.name, "?", "?", PROFILER.fTimeTotal[func]
  end
  
  return n.name, n.short_src, n.linedefined, PROFILER.fTimeTotal[func]  
end

--- Write text to log file.
-- @param #function f The file.
-- @param #string txt The text.
function PROFILER._flog(f, txt)
  f:write(txt.."\r\n")
end

--- Show table.
-- @param #table data Data table.
-- @param #function f The file.
-- @param #boolean detailed Show detailed info.
function PROFILER.showTable(data, f, detailed)

  -- Loop over data.
  for i=1, #data do  
    local t=data[i] --#PROFILER.Data
  
    -- Calls per second.
    local cps=t.count/PROFILER.runTimeGame
    
    if (cps>=PROFILER.lowCpsThres) then
    
      -- Output
      local text=string.format("%20s: %8d calls %8.1f/sec   -   Time %8.3f sec (%.3f %%)  %s line %s", t.func, t.count, cps, t.tm, t.tm/PROFILER.runTimeGame*100, tostring(t.src), tostring(t.line))
      PROFILER._flog(f, text)
      
    end
  end
    
end

--- Write info to output file.
function PROFILER.showInfo()

  -- Output file.
  local file=lfs.writedir()..[[Logs\]]..PROFILER.fileName  
  local f=io.open(file, 'w')  
  
  -- Gather data.
  local Ttot=0
  local Calls=0
  local t={}
  for func, count in pairs(PROFILER.Counters) do
  
    local s,src,line,tm=PROFILER.getData(func)
    
    if PROFILER.logUnknown==true then
      if s==nil then s="<Unknown>" end
    end
    
    if (s~=nil) then
      t[#t+1]=
      { func=s,
        src=src,
        line=line,
        count=count,
        tm=tm,
      }
      Ttot=Ttot+tm
      Calls=Calls+count
    end
    
  end
  
  env.info("**************************************************************************************************")
  env.info(string.format("Profiler"))
  env.info(string.format("--------"))
  env.info(string.format("* Runtime Game     : %s = %d sec", UTILS.SecondsToClock(PROFILER.runTimeGame, true), PROFILER.runTimeGame))
  env.info(string.format("* Runtime Real     : %s = %d sec", UTILS.SecondsToClock(PROFILER.runTimeOS, true), PROFILER.runTimeOS))
  env.info(string.format("* Function time    : %s = %.1f sec (%.1f percent of runtime game)", UTILS.SecondsToClock(Ttot, true), Ttot, Ttot/PROFILER.runTimeGame*100))
  env.info(string.format("* Total functions  : %d", #t))
  env.info(string.format("* Total func calls : %d", Calls))
  env.info(string.format("* Writing to file  : \"%s\"", file))
  env.info("**************************************************************************************************")  
      
  -- Sort by total time.
  table.sort(t, function(a,b) return a.tm>b.tm end)
  
  -- Write data.
  PROFILER._flog(f,"")
  PROFILER._flog(f,"************************************************************************************************************************")
  PROFILER._flog(f,"************************************************************************************************************************")
  PROFILER._flog(f,"************************************************************************************************************************")
  PROFILER._flog(f,"")
  PROFILER._flog(f,"-------------------------")
  PROFILER._flog(f,"---- Profiler Report ----")
  PROFILER._flog(f,"-------------------------")
  PROFILER._flog(f,"")
  PROFILER._flog(f,string.format("* Runtime Game     : %s = %.1f sec", UTILS.SecondsToClock(PROFILER.runTimeGame, true), PROFILER.runTimeGame))
  PROFILER._flog(f,string.format("* Runtime Real     : %s = %.1f sec", UTILS.SecondsToClock(PROFILER.runTimeOS, true), PROFILER.runTimeOS).."  (can vary significantly compared to the game time)")
  PROFILER._flog(f,string.format("* Function time    : %s = %.1f sec (%.1f %% of runtime game)", UTILS.SecondsToClock(Ttot, true), Ttot, Ttot/PROFILER.runTimeGame*100))
  PROFILER._flog(f,"")
  PROFILER._flog(f,string.format("* Total functions  = %d", #t))
  PROFILER._flog(f,string.format("* Total func calls = %d", Calls))
  PROFILER._flog(f,"")
  PROFILER._flog(f,"************************************************************************************************************************")
  PROFILER._flog(f,"")
  PROFILER.showTable(t, f, true)
  
  -- Sort by number of calls.
  table.sort(t, function(a,b) return a.count>b.count end)
  
  -- Detailed data.
  PROFILER._flog(f,"")
  PROFILER._flog(f,"************************************************************************************************************************")
  PROFILER._flog(f,"")
  PROFILER._flog(f,"------------------------------")
  PROFILER._flog(f,"---- Data Sorted by Calls ----")
  PROFILER._flog(f,"------------------------------")
  PROFILER._flog(f,"")
  PROFILER.showTable(t, f, true)
  
  -- Closing.
  PROFILER._flog(f,"")
  PROFILER._flog(f,"************************************************************************************************************************")
  PROFILER._flog(f,"************************************************************************************************************************")
  PROFILER._flog(f,"************************************************************************************************************************")
  -- Close file.
  f:close()
end

