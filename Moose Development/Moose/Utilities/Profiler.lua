--- **Utils** - Lua Profiler.
--
-- Find out how many times functions are called and how much real time it costs.
--
-- ===
--
-- ### Author: **TAW CougarNL**, *funkyfranky*
--
-- @module Utilities.Profiler
-- @image Utils_Profiler.jpg

--- PROFILER class.
-- @type PROFILER
-- @field #string ClassName Name of the class.
-- @field #table Counters Function counters.
-- @field #table dInfo Info.
-- @field #table fTime Function time.
-- @field #table fTimeTotal Total function time.
-- @field #table eventhandler Event handler to get mission end event.
-- @field #number TstartGame Game start time timer.getTime().
-- @field #number TstartOS OS real start time os.clock.
-- @field #boolean logUnknown Log unknown functions. Default is off.
-- @field #number ThreshCPS Low calls per second threshold. Only write output if function has more calls per second than this value.
-- @field #number ThreshTtot Total time threshold. Only write output if total function CPU time is more than this value.
-- @field #string fileNamePrefix Output file name prefix, e.g. "MooseProfiler".
-- @field #string fileNameSuffix Output file name prefix, e.g. "txt"

--- *The emperor counsels simplicity.* *First principles. Of each particular thing, ask: What is it in itself, in its own constitution? What is its causal nature?*
--
-- ===
--
-- ![Banner Image](..\Presentations\Utilities\PROFILER_Main.jpg)
--
-- # The PROFILER Concept
--
-- Profile your lua code. This tells you, which functions are called very often and which consume most real time.
-- With this information you can optimize the performance of your code.
--
-- # Prerequisites
--
-- The modules **os**, **io** and **lfs** need to be de-sanitized. Comment out the lines
--
--     --sanitizeModule('os')
--     --sanitizeModule('io')
--     --sanitizeModule('lfs')
--
-- in your *"DCS World OpenBeta/Scripts/MissionScripting.lua"* file.
--
-- But be aware that these changes can make you system vulnerable to attacks.
--
-- # Disclaimer
--
-- **Profiling itself is CPU expensive!** Don't use this when you want to fly or host a mission.
--
--
-- # Start
--
-- The profiler can simply be started with the @{#PROFILER.Start}(*Delay, Duration*) function
--
--     PROFILER.Start()
--
-- The optional parameter *Delay* can be used to delay the start by a certain amount of seconds and the optional parameter *Duration* can be used to
-- stop the profiler after a certain amount of seconds.
--
-- # Stop
--
-- The profiler automatically stops when the mission ends. But it can be stopped any time with the @{#PROFILER.Stop}(*Delay*) function
--
--     PROFILER.Stop()
--
-- The optional parameter *Delay* can be used to specify a delay after which the profiler is stopped.
--
-- When the profiler is stopped, the output is written to a file.
--
-- # Output
--
-- The profiler output is written to a file in your DCS home folder
--
--     X:\User\<Your User Name>\Saved Games\DCS OpenBeta\Logs
--
-- The default file name is "MooseProfiler.txt". If that file exists, the file name is "MooseProfiler-001.txt" etc.
--
-- ## Data
--
-- The data in the output file provides information on the functions that were called in the mission.
--
-- It will tell you how many times a function was called in total, how many times per second, how much time in total and the percentage of time.
--
-- If you only want output for functions that are called more than *X* times per second, you can set
--
--     PROFILER.ThreshCPS=1.5
--
-- With this setting, only functions which are called more than 1.5 times per second are displayed. The default setting is PROFILER.ThreshCPS=0.0 (no threshold).
--
-- Furthermore, you can limit the output for functions that consumed a certain amount of CPU time in total by
--
--     PROFILER.ThreshTtot=0.005
--
-- With this setting, which is also the default, only functions which in total used more than 5 milliseconds CPU time.
--
-- @field #PROFILER
PROFILER = {
  ClassName      = "PROFILER",
  Counters       = {},
  dInfo          = {},
  fTime          = {},
  fTimeTotal     = {},
  eventHandler   = {},
  logUnknown     = false,
  ThreshCPS      = 0.0,
  ThreshTtot     = 0.005,
  fileNamePrefix = "MooseProfiler",
  fileNameSuffix = "txt"
}

--- Waypoint data.
-- @type PROFILER.Data
-- @field #string func The function name.
-- @field #string src The source file.
-- @field #number line The line number
-- @field #number count Number of function calls.
-- @field #number tm Total time in seconds.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Start/Stop Profiler
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Start profiler.
-- @param #number Delay Delay in seconds before profiler is stated. Default is immediately.
-- @param #number Duration Duration in (game) seconds before the profiler is stopped. Default is when mission ends.
function PROFILER.Start( Delay, Duration )

  -- Check if os, io and lfs are available.
  local go = true
  if not os then
    env.error( "ERROR: Profiler needs os to be de-sanitized!" )
    go = false
  end
  if not io then
    env.error("ERROR: Profiler needs io to be desanitized!")
    go=false
  end
  if not lfs then
    env.error("ERROR: Profiler needs lfs to be desanitized!")
    go=false
  end
  if not go then
    return
  end

  if Delay and Delay > 0 then
    BASE:ScheduleOnce( Delay, PROFILER.Start, 0, Duration )
  else

    -- Set start time.
    PROFILER.TstartGame=timer.getTime()
    PROFILER.TstartOS=os.clock()

    -- Add event handler.
    world.addEventHandler(PROFILER.eventHandler)

    -- Info in log.
    env.info( '############################   Profiler Started   ############################' )
    if Duration then
      env.info( string.format( "- Will be running for %d seconds", Duration ) )
    else
      env.info( string.format( "- Will be stopped when mission ends" ) )
    end
    env.info(string.format("- Calls per second threshold %.3f/sec", PROFILER.ThreshCPS))
    env.info(string.format("- Total function time threshold %.3f sec", PROFILER.ThreshTtot))
    env.info(string.format("- Output file \"%s\" in your DCS log file folder", PROFILER.getfilename(PROFILER.fileNameSuffix)))
    env.info(string.format("- Output file \"%s\" in CSV format", PROFILER.getfilename("csv")))
    env.info('###############################################################################')


    -- Message on screen
    local duration=Duration or 600
    trigger.action.outText("### Profiler running ###", duration)

    -- Set hook.
    debug.sethook(PROFILER.hook, "cr")

    -- Auto stop profiler.
    if Duration then
      PROFILER.Stop( Duration )
    end

  end

end

--- Stop profiler.
-- @param #number Delay Delay before stop in seconds.
function PROFILER.Stop( Delay )

  if Delay and Delay > 0 then

    BASE:ScheduleOnce( Delay, PROFILER.Stop )
  end
end

function PROFILER.Stop(Delay)

  if Delay and Delay>0 then

    BASE:ScheduleOnce(Delay, PROFILER.Stop)

  else

    -- Remove hook.
    debug.sethook()


    -- Run time game.
    local runTimeGame=timer.getTime()-PROFILER.TstartGame

    -- Run time real OS.
    local runTimeOS=os.clock()-PROFILER.TstartOS

    -- Show info.
    PROFILER.showInfo(runTimeGame, runTimeOS)

  end

end

--- Event handler.
function PROFILER.eventHandler:onEvent( event )
  if event.id == world.event.S_EVENT_MISSION_END then
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
      PROFILER.Counters[f] = PROFILER.Counters[f] + 1
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
function PROFILER.getData( func )

  local n=PROFILER.dInfo[func]

  if n.what=="C" then
    return n.name, "?", "?", PROFILER.fTimeTotal[func]
  end

  return n.name, n.short_src, n.linedefined, PROFILER.fTimeTotal[func]
end

--- Write text to log file.
-- @param #function f The file.
-- @param #string txt The text.
function PROFILER._flog( f, txt )
  f:write( txt .. "\r\n" )
end

--- Show table.
-- @param #table data Data table.
-- @param #function f The file.
-- @param #number runTimeGame Game run time in seconds.
function PROFILER.showTable( data, f, runTimeGame )

  -- Loop over data.
  for i=1, #data do
    local t=data[i] --#PROFILER.Data

    -- Calls per second.
    local cps=t.count/runTimeGame

    local threshCPS=cps>=PROFILER.ThreshCPS
    local threshTot=t.tm>=PROFILER.ThreshTtot

    if threshCPS and threshTot then

      -- Output
      local text=string.format("%30s: %8d calls %8.1f/sec - Time Total %8.3f sec (%.3f %%) %5.3f sec/call  %s line %s", t.func, t.count, cps, t.tm, t.tm/runTimeGame*100, t.tm/t.count, tostring(t.src), tostring(t.line))
      PROFILER._flog(f, text)

    end
  end

end

--- Print csv file.
-- @param #table data Data table.
-- @param #number runTimeGame Game run time in seconds.
function PROFILER.printCSV( data, runTimeGame )

  -- Output file.
  local file = PROFILER.getfilename( "csv" )
  local g = io.open( file, 'w' )

  -- Header.
  local text="Function,Total Calls,Calls per Sec,Total Time,Total in %,Sec per Call,Source File;Line Number,"
  g:write(text.."\r\n")

  -- Loop over data.
  for i=1, #data do
    local t=data[i] --#PROFILER.Data

    -- Calls per second.
    local cps = t.count / runTimeGame

    -- Output
    local txt=string.format("%s,%d,%.1f,%.3f,%.3f,%.3f,%s,%s,", t.func, t.count, cps, t.tm, t.tm/runTimeGame*100, t.tm/t.count, tostring(t.src), tostring(t.line))
    g:write(txt.."\r\n")

  end

  -- Close file.
  g:close()
end

--- Write info to output file.
-- @param #string ext Extension.
-- @return #string File name.
function PROFILER.getfilename(ext)

  local dir=lfs.writedir()..[[Logs\]]

  ext=ext or PROFILER.fileNameSuffix

  local file=dir..PROFILER.fileNamePrefix.."."..ext

  if not UTILS.FileExists(file) then
    return file
  end

  for i = 1, 999 do

    local file = string.format( "%s%s-%03d.%s", dir, PROFILER.fileNamePrefix, i, ext )

    if not UTILS.FileExists( file ) then
      return file
    end

  end

end

--- Write info to output file.
-- @param #number runTimeGame Game time in seconds.
-- @param #number runTimeOS OS time in seconds.
function PROFILER.showInfo( runTimeGame, runTimeOS )

  -- Output file.
  local file=PROFILER.getfilename(PROFILER.fileNameSuffix)
  local f=io.open(file, 'w')

  -- Gather data.
  local Ttot=0
  local Calls=0

  local t={}

  local tcopy=nil --#PROFILER.Data
  local tserialize=nil --#PROFILER.Data
  local tforgen=nil --#PROFILER.Data
  local tpairs=nil --#PROFILER.Data


  for func, count in pairs(PROFILER.Counters) do

    local s,src,line,tm=PROFILER.getData(func)

    if PROFILER.logUnknown==true then
      if s==nil then s="<Unknown>" end
    end

    if s~=nil then

      -- Profile data.
      local T=
      { func=s,
        src=src,
        line=line,
        count=count,
        tm=tm,
      } --#PROFILER.Data

      -- Collect special cases. Somehow, e.g. "_copy" appears multiple times so we try to gather all data.
      if s == "_copy" then
        if tcopy == nil then
          tcopy = T
        else
          tcopy.count = tcopy.count + T.count
          tcopy.tm = tcopy.tm + T.tm
        end
      elseif s == "_Serialize" then
        if tserialize == nil then
          tserialize = T
        else
          tserialize.count=tserialize.count+T.count
          tserialize.tm=tserialize.tm+T.tm
        end
      elseif s=="(for generator)" then
        if tforgen==nil then
          tforgen=T
        else
          tforgen.count=tforgen.count+T.count
          tforgen.tm=tforgen.tm+T.tm
        end
      elseif s=="pairs" then
        if tpairs==nil then
          tpairs=T
        else
          tpairs.count=tpairs.count+T.count
          tpairs.tm=tpairs.tm+T.tm
        end
      else
        table.insert( t, T )
      end

      -- Total function time.
      Ttot=Ttot+tm

      -- Total number of calls.
      Calls=Calls+count

    end

  end

  -- Add special cases.
  if tcopy then
    table.insert( t, tcopy )
  end
  if tserialize then
    table.insert(t, tserialize)
  end
  if tforgen then
    table.insert( t, tforgen )
  end
  if tpairs then
    table.insert(t, tpairs)
  end

  env.info('############################   Profiler Stopped   ############################')
  env.info(string.format("* Runtime Game     : %s = %d sec", UTILS.SecondsToClock(runTimeGame, true), runTimeGame))
  env.info(string.format("* Runtime Real     : %s = %d sec", UTILS.SecondsToClock(runTimeOS, true), runTimeOS))
  env.info(string.format("* Function time    : %s = %.1f sec (%.1f percent of runtime game)", UTILS.SecondsToClock(Ttot, true), Ttot, Ttot/runTimeGame*100))
  env.info(string.format("* Total functions  : %d", #t))
  env.info(string.format("* Total func calls : %d", Calls))
  env.info(string.format("* Writing to file  : \"%s\"", file))
  env.info(string.format("* Writing to file  : \"%s\"", PROFILER.getfilename("csv")))
  env.info("##############################################################################")

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
  PROFILER._flog(f,string.format("* Runtime Game     : %s = %.1f sec", UTILS.SecondsToClock(runTimeGame, true), runTimeGame))
  PROFILER._flog(f,string.format("* Runtime Real     : %s = %.1f sec", UTILS.SecondsToClock(runTimeOS, true), runTimeOS))
  PROFILER._flog(f,string.format("* Function time    : %s = %.1f sec (%.1f %% of runtime game)", UTILS.SecondsToClock(Ttot, true), Ttot, Ttot/runTimeGame*100))
  PROFILER._flog(f,"")
  PROFILER._flog(f,string.format("* Total functions  = %d", #t))
  PROFILER._flog(f,string.format("* Total func calls = %d", Calls))
  PROFILER._flog(f,"")
  PROFILER._flog(f,string.format("* Calls per second threshold = %.3f/sec", PROFILER.ThreshCPS))
  PROFILER._flog(f,string.format("* Total func time threshold  = %.3f sec", PROFILER.ThreshTtot))
  PROFILER._flog(f,"")
  PROFILER._flog(f,"************************************************************************************************************************")
  PROFILER._flog(f,"")
  PROFILER.showTable(t, f, runTimeGame)

  -- Sort by number of calls.
  table.sort(t, function(a,b) return a.tm/a.count>b.tm/b.count end)

  -- Detailed data.
  PROFILER._flog(f,"")
  PROFILER._flog(f,"************************************************************************************************************************")
  PROFILER._flog(f,"")
  PROFILER._flog(f,"--------------------------------------")
  PROFILER._flog(f,"---- Data Sorted by Time per Call ----")
  PROFILER._flog(f,"--------------------------------------")
  PROFILER._flog(f,"")
  PROFILER.showTable(t, f, runTimeGame)

  -- Sort by number of calls.
  table.sort(t, function(a,b) return a.count>b.count end)

  -- Detailed data.
  PROFILER._flog(f,"")
  PROFILER._flog(f,"************************************************************************************************************************")
  PROFILER._flog(f,"")
  PROFILER._flog(f,"------------------------------------")
  PROFILER._flog(f,"---- Data Sorted by Total Calls ----")
  PROFILER._flog(f,"------------------------------------")
  PROFILER._flog(f,"")
  PROFILER.showTable(t, f, runTimeGame)

  -- Closing.
  PROFILER._flog( f, "" )
  PROFILER._flog( f, "************************************************************************************************************************" )
  PROFILER._flog( f, "************************************************************************************************************************" )
  PROFILER._flog( f, "************************************************************************************************************************" )
  -- Close file.
  f:close()

  -- Print csv file.
  PROFILER.printCSV( t, runTimeGame )
end
