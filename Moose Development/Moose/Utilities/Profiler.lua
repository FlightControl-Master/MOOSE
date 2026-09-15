--- **Utils** - Lua function call and CPU-time profiler.
--
-- ### Author: **TAW CougarNL**, *funkyfranky*
-- @module Utilities.Profiler
-- @image Utils_Profiler.jpg

--- PROFILER class. A global service; invoke Start and Stop with a dot.
-- @type PROFILER
-- @field #string ClassName Class name.
-- @field #boolean Active Whether a measurement is running.
-- @field #table Counters Calls indexed by function object.
-- @field #table dInfo Debug metadata indexed by function object.
-- @field #table fTimeTotal Inclusive CPU seconds indexed by function object.
-- @field #table fTimeSelf Exclusive CPU seconds indexed by function object.
-- @field #table eventHandler Mission-end handler, removed on Stop.
-- @field #number TstartGame Simulation time at measurement start.
-- @field #number TstartOS Process CPU time at measurement start.
-- @field #boolean logUnknown Include functions without a debug name; default false.
-- @field #number ThreshCPS Minimum calls per simulation second for both formats; default 0.
-- @field #number ThreshTtot Minimum inclusive CPU seconds for both formats; default 0.005.
-- @field #string fileNamePrefix Output basename, default MooseProfiler.
-- @field #string fileNameSuffix Text extension, default txt; must differ from csv.
-- @field #PROFILER.Report LastReport Completed report, retained after write failures.

--- # The PROFILER Concept
--
-- Records calls and CPU time in the Lua thread where Start executes. Other coroutines are not automatically instrumented.
-- Hook events inherited by other coroutines are ignored; time spent resuming them remains part of the caller's inclusive CPU time.
-- Requires os.clock, io.open, lfs.writedir and the debug hook API in the mission environment.
-- This file does not change DCS sandbox settings. Profiling adds overhead and is intended for dedicated diagnostics.
--
--     PROFILER.Start(0, 30) -- Profile for 30 simulation seconds.
--
-- Alternatively use PROFILER.Start() and PROFILER.Stop(). All delays use simulation seconds.
-- Start while active or already scheduled is rejected. Every measurement starts with fresh counters.
-- Stop is safe before Start and on repeated calls; it also cancels a pending start.
-- Delayed Stop requests require an active measurement; use immediate Stop to cancel a pending start.
-- Old delayed callbacks cannot affect a subsequent measurement. Mission end stops active or pending profiling.
--
-- # Timing
--
-- os.clock measures process CPU time, not wall-clock time. Calls per second use simulation time.
-- Inclusive time includes subcalls; self time excludes them. Percentages use self time divided by measurement CPU time.
-- Inclusive totals can exceed measurement time because nested calls overlap, especially during recursion.
-- The stack handles recursion, Lua 5.1 tail returns and Lua 5.2+ tail calls.
-- Error-unwound frames close at the next hook event; frames open at Stop are clipped to that moment.
-- Hook overhead and process activity outside the measured thread affect times; these are not utilization measurements.
-- Zero-length measurements report zero rates/percentages. Unknown names require logUnknown=true.
-- Different function objects stay separate even when their names match.
--
-- # Hooks and Output
--
-- A previous Lua hook is temporarily replaced and restored with its original mask/count.
-- If another tool replaces our hook during profiling, Stop leaves the replacement alone.
-- A Lua 5.1 main-thread measurement must be stopped on the main thread.
-- Reports go to lfs.writedir().."Logs/" as paired text/CSV files with a shared unused numbered basename.
-- Text includes inclusive time, self time, time-per-call and call-count rankings. CSV uses inclusive-time order.
-- Both formats use the same thresholds; CSV fields are escaped. File errors are logged and returned.
-- LastReport retains data when writing fails; it resets only when a new measurement actually starts.
--
-- @field #PROFILER
PROFILER = {
  ClassName="PROFILER", Active=false,
  Counters={}, dInfo={}, fTimeTotal={}, fTimeSelf={}, eventHandler={},
  logUnknown=false, ThreshCPS=0, ThreshTtot=0.005,
  fileNamePrefix="MooseProfiler", fileNameSuffix="txt", _Generation=0
}

--- One measured function, clipped to the profiling interval.
-- @type PROFILER.Data
-- @field #string func Debug name or unknown placeholder.
-- @field #string src Source file or C marker.
-- @field #number line Definition line, or -1.
-- @field #number count Observed calls.
-- @field #number tm Inclusive CPU seconds.
-- @field #number self Exclusive CPU seconds.
-- @field #number cps Calls per simulation second.
-- @field #number percent Self time percentage of measurement CPU time.
-- @field #number average Inclusive CPU seconds per call.

--- Completed measurement, retained even if output failed.
-- @type PROFILER.Report
-- @field #number RuntimeGame Simulation duration.
-- @field #number RuntimeCPU Process CPU duration.
-- @field #number Calls Observed calls before filtering.
-- @field #number SelfCPU Self CPU seconds before filtering.
-- @field #table Functions Filtered PROFILER.Data rows.
-- @field #table Errors Output error messages.
-- @field #string TextFile Successfully written text file, or nil.
-- @field #string CSVFile Successfully written CSV file, or nil.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Lifecycle
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Validate a duration or threshold.
-- @param #number Value Value to inspect.
-- @return #boolean Whether it is finite and non-negative.
function PROFILER._NonNegative(Value)

  return type(Value)=="number" and Value>=0 and Value<math.huge

end

--- Log and return a recoverable failure.
-- @param #string Message Failure explanation.
-- @return #boolean false.
-- @return #string Message.
function PROFILER._Error(Message)

  env.error("PROFILER: "..tostring(Message))
  return false,Message

end

--- Cancel and clear a scheduled callback.
-- @param #string Field Timer handle field.
-- @return #nil No return value.
function PROFILER._CancelTimer(Field)

  local id=PROFILER[Field]
  PROFILER[Field]=nil
  if id then timer.removeFunction(id) end

end

--- Schedule a callback without discarding an existing timer on scheduler failure.
-- @param #string Field Timer handle field.
-- @param #number Delay Simulation seconds until the callback.
-- @param #function Callback Scheduled function.
-- @return #boolean Whether scheduling succeeded.
-- @return #string Failure explanation, or nil.
function PROFILER._Schedule(Field, Delay, Callback)

  local ok,id=pcall(timer.scheduleFunction,Callback,nil,timer.getTime()+Delay)
  if not ok or type(id)~="number" then return PROFILER._Error("scheduling failed: "..tostring(id)) end
  PROFILER._CancelTimer(Field)
  PROFILER[Field]=id
  return true

end

--- Read the hook on the measurement thread.
-- @return #function Hook, nil, or an external native hook marker.
-- @return #string Event mask.
-- @return #number Instruction count.
function PROFILER._GetHook()

  if PROFILER._Thread then return debug.gethook(PROFILER._Thread) end
  return debug.gethook()

end

--- Set the hook on the measurement thread.
-- @param #function Hook Hook or nil.
-- @param #string Mask Event mask.
-- @param #number Count Instruction count.
-- @return #nil No return value.
function PROFILER._SetHook(Hook, Mask, Count)

  if PROFILER._Thread then debug.sethook(PROFILER._Thread,Hook,Mask or "",Count or 0)
  else debug.sethook(Hook,Mask or "",Count or 0) end

end

--- Remove the mission-end handler when registered.
-- @return #nil No return value.
function PROFILER._RemoveHandler()

  if PROFILER._HandlerAdded then
    PROFILER._HandlerAdded=false
    world.removeEventHandler(PROFILER.eventHandler)
  end

end

--- Start a fresh measurement or schedule its start.
-- @param #number Delay Optional finite non-negative simulation seconds; default zero.
-- @param #number Duration Optional finite non-negative simulation seconds; nil runs until Stop or mission end.
-- @return #boolean Whether starting or scheduling succeeded.
-- @return #string Failure explanation, if unsuccessful.
function PROFILER.Start(Delay, Duration)

  if Delay==nil then Delay=0 end
  if not PROFILER._NonNegative(Delay) or (Duration~=nil and not PROFILER._NonNegative(Duration)) then
    return PROFILER._Error("Delay and Duration must be finite non-negative seconds")
  end
  if PROFILER.Active or PROFILER._StartTimer then return false,"already_running_or_scheduled" end
  if not (os and type(os.clock)=="function" and io and type(io.open)=="function"
    and lfs and type(lfs.writedir)=="function" and debug and type(debug.getinfo)=="function"
    and type(debug.gethook)=="function" and type(debug.sethook)=="function"
    and timer and type(timer.getTime)=="function" and type(timer.scheduleFunction)=="function" and type(timer.removeFunction)=="function"
    and world and type(world.addEventHandler)=="function" and type(world.removeEventHandler)=="function"
    and UTILS and type(UTILS.FileExists)=="function") then
    return PROFILER._Error("CPU clock, file, debug, timer, event and UTILS.FileExists APIs must be available")
  end
  if not PROFILER._NonNegative(PROFILER.ThreshCPS) or not PROFILER._NonNegative(PROFILER.ThreshTtot) then
    return PROFILER._Error("thresholds must be finite non-negative numbers")
  end
  if type(PROFILER.fileNamePrefix)~="string" or PROFILER.fileNamePrefix==""
    or type(PROFILER.fileNameSuffix)~="string" or PROFILER.fileNameSuffix=="" or PROFILER.fileNameSuffix:lower()=="csv" then
    return PROFILER._Error("a basename and a text extension different from csv are required")
  end
  PROFILER._Generation=PROFILER._Generation+1
  local generation=PROFILER._Generation
  if Delay>0 then
    local scheduled,reason=PROFILER._Schedule("_StartTimer",Delay,function()
      if generation==PROFILER._Generation then
        PROFILER._StartTimer=nil
        PROFILER._RemoveHandler()
        PROFILER.Start(0,Duration)
      end
    end)
    if not scheduled then return false,reason end
    local added,message=pcall(world.addEventHandler,PROFILER.eventHandler)
    if not added then PROFILER._CancelTimer("_StartTimer") return PROFILER._Error(tostring(message)) end
    PROFILER._HandlerAdded=true
    return true
  end
  PROFILER._Thread=coroutine.running()
  local hook,mask,count=PROFILER._GetHook()
  if hook~=nil and type(hook)~="function" then return PROFILER._Error("cannot preserve an external native debug hook") end
  PROFILER._PreviousHook={hook=hook,mask=mask,count=count}
  local fields={"Counters","dInfo","fTimeTotal","fTimeSelf","_Stack","LastReport","TstartGame","TstartOS"}
  local saved={}
  for _,field in ipairs(fields) do saved[field]=PROFILER[field] end
  PROFILER.Counters={}
  PROFILER.dInfo={}
  PROFILER.fTimeTotal={}
  PROFILER.fTimeSelf={}
  PROFILER._Stack={}
  PROFILER.LastReport=nil
  PROFILER._OwnFunctions={}
  for _,value in pairs(PROFILER) do
    if type(value)=="function" then PROFILER._OwnFunctions[value]=true end
  end
  local started,message=pcall(function()
    world.addEventHandler(PROFILER.eventHandler)
    PROFILER._HandlerAdded=true
    env.info("PROFILER: started; CPU timing with inclusive and self time")
    PROFILER.TstartGame=timer.getTime()
    PROFILER.TstartOS=os.clock()
    PROFILER.Active=true
    PROFILER._SetHook(PROFILER.hook,"cr",0)
    if Duration~=nil then
      local scheduled,reason=PROFILER.Stop(Duration)
      if not scheduled and PROFILER.Active then error(reason) end
    end
  end)
  if not started then
    PROFILER.Active=false
    PROFILER._Generation=PROFILER._Generation+1
    PROFILER._CancelTimer("_StopTimer")
    PROFILER._RemoveHandler()
    if PROFILER._GetHook()==PROFILER.hook then PROFILER._SetHook(hook,mask,count) end
    for _,field in ipairs(fields) do PROFILER[field]=saved[field] end
    return PROFILER._Error(tostring(message))
  end
  return true

end

--- Stop, schedule a stop, or cancel a pending start.
-- Delayed stops belong to this measurement and cannot stop a later one.
-- @param #number Delay Optional finite non-negative simulation seconds; default zero.
-- @return #boolean Whether stop/cancellation was accepted and, for immediate stops, output succeeded.
-- @return #PROFILER.Report Report, or a string explaining an idle/invalid request.
function PROFILER.Stop(Delay)

  if Delay==nil then Delay=0 end
  if not PROFILER._NonNegative(Delay) then return PROFILER._Error("stop delay must be finite non-negative seconds") end
  if not PROFILER.Active and not PROFILER._StartTimer then return false,"not_running" end
  if Delay>0 then
    if not PROFILER.Active then return false,"not_running" end
    local generation=PROFILER._Generation
    return PROFILER._Schedule("_StopTimer",Delay,function()
      if generation==PROFILER._Generation then
        PROFILER._StopTimer=nil
        PROFILER.Stop()
      end
    end)
  end
  if PROFILER.Active and PROFILER._Thread==nil and coroutine.running()~=nil then
    return PROFILER._Error("stop a Lua 5.1 main-thread measurement on the main thread")
  end
  local active=PROFILER.Active
  PROFILER.Active=false
  local now=active and os.clock() or nil
  local gameNow=active and timer.getTime() or nil
  PROFILER._Generation=PROFILER._Generation+1
  PROFILER._CancelTimer("_StartTimer")
  PROFILER._CancelTimer("_StopTimer")
  PROFILER._RemoveHandler()
  if not active then return true end
  if PROFILER._GetHook()==PROFILER.hook then
    local previous=PROFILER._PreviousHook
    PROFILER._SetHook(previous.hook,previous.mask,previous.count)
  end
  while #PROFILER._Stack>0 do PROFILER._FinishFrame(now) end
  return PROFILER.showInfo(math.max(0,gameNow-PROFILER.TstartGame),math.max(0,now-PROFILER.TstartOS))

end

--- Stop or cancel on mission end.
-- @param #table self Event handler.
-- @param #table Event DCS event.
-- @return #nil No return value.
function PROFILER.eventHandler:onEvent(Event)

  if Event.id==world.event.S_EVENT_MISSION_END then PROFILER.Stop() end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Measurement stack
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Close the top frame and charge its inclusive time to its parent.
-- @param #number Now CPU timestamp.
-- @return #nil No return value.
function PROFILER._FinishFrame(Now)

  local stack=PROFILER._Stack
  local frame=stack[#stack]
  stack[#stack]=nil
  local elapsed=math.max(0,Now-frame.start)
  if not frame.ignored then
    local f=frame.func
    PROFILER.fTimeTotal[f]=PROFILER.fTimeTotal[f]+elapsed
    PROFILER.fTimeSelf[f]=PROFILER.fTimeSelf[f]+math.max(0,elapsed-frame.children)
  end
  local parent=stack[#stack]
  if parent then parent.children=parent.children+elapsed end

end

--- Handle calls, returns, recursion, tail calls and error unwinding.
-- Depth includes Lua 5.1 synthetic tail frames; newer tail calls keep logical parents at the same depth.
-- @param #string Event Debug hook event.
-- @return #nil No return value.
function PROFILER.hook(Event)

  if not PROFILER.Active or coroutine.running()~=PROFILER._Thread then return end
  local now=os.clock()
  local info=debug.getinfo(2,"f")
  if not info then return end
  local depth=1
  while debug.getinfo(depth+2,"f") do depth=depth+1 end
  local stack=PROFILER._Stack
  local returning=Event=="return" or Event=="tail return"
  if Event=="call" or Event=="tail call" or returning then
    while #stack>0 and (stack[#stack].depth>depth
      or (stack[#stack].depth==depth and Event~="tail call")) do
      PROFILER._FinishFrame(now)
    end
    if not returning and info.func then
      local f=info.func
      local ignored=PROFILER._OwnFunctions[f]
      if not ignored then
        PROFILER.Counters[f]=(PROFILER.Counters[f] or 0)+1
        if not PROFILER.dInfo[f] or not PROFILER.dInfo[f].name then
          PROFILER.dInfo[f]=debug.getinfo(2,"nS")
        end
        PROFILER.fTimeTotal[f]=PROFILER.fTimeTotal[f] or 0
        PROFILER.fTimeSelf[f]=PROFILER.fTimeSelf[f] or 0
      end
      stack[#stack+1]={func=f,depth=depth,start=now,children=0,ignored=ignored}
    end
  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Reports
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Read metadata and CPU totals.
-- @param #function Func Measured function.
-- @return #string Debug name or nil.
-- @return #string Source or C marker.
-- @return #number Definition line or -1.
-- @return #number Inclusive CPU seconds.
-- @return #number Self CPU seconds.
function PROFILER.getData(Func)

  local info=PROFILER.dInfo[Func] or {}
  return info.name,info.what=="C" and "[C]" or (info.short_src or "?"),info.linedefined or -1,
    PROFILER.fTimeTotal[Func] or 0,PROFILER.fTimeSelf[Func] or 0

end

--- Build a filtered dataset shared by text and CSV.
-- @param #number GameSeconds Simulation duration.
-- @param #number CPUSeconds CPU duration.
-- @return #PROFILER.Report Measurement snapshot.
function PROFILER._BuildReport(GameSeconds, CPUSeconds)

  local report={RuntimeGame=GameSeconds,RuntimeCPU=CPUSeconds,Calls=0,SelfCPU=0,Functions={},Errors={}}
  for func,count in pairs(PROFILER.Counters) do
    local name,source,line,total,own=PROFILER.getData(func)
    report.Calls=report.Calls+count
    report.SelfCPU=report.SelfCPU+own
    local cps=GameSeconds>0 and count/GameSeconds or 0
    if (name or PROFILER.logUnknown) and cps>=PROFILER.ThreshCPS and total>=PROFILER.ThreshTtot then
      report.Functions[#report.Functions+1]={func=name or "<Unknown>",src=source,line=line,count=count,tm=total,self=own,
        cps=cps,percent=CPUSeconds>0 and own/CPUSeconds*100 or 0,average=count>0 and total/count or 0}
    end
  end
  return report

end

--- Find an unused paired text/CSV basename.
-- @return #string Text path, or nil when all names are occupied.
-- @return #string CSV path, or failure explanation.
function PROFILER._ReportPaths()

  if type(PROFILER.fileNameSuffix)~="string" or PROFILER.fileNameSuffix=="" or PROFILER.fileNameSuffix:lower()=="csv" then
    return nil,"text extension must differ from csv"
  end
  local directory=lfs.writedir().."Logs/"
  for index=0,999 do
    local base=directory..PROFILER.fileNamePrefix..(index==0 and "" or string.format("-%03d",index))
    local text,csv=base.."."..PROFILER.fileNameSuffix,base..".csv"
    if not UTILS.FileExists(text) and not UTILS.FileExists(csv) then return text,csv end
  end
  return nil,"all profiler report names are occupied"

end

--- Accept DCS file operations without return values while preserving explicit error results.
-- @param ... File operation results: no values means success; explicit nil/false means failure.
-- @return #nil No return value; raises an error for an explicit failure result.
function PROFILER._CheckFileResult(...)

  if select("#",...)>0 then
    local result,message=...
    if not result then error(message or "file operation failed") end
  end

end

--- Write a line or propagate a disk error to the protected writer.
-- @param #table File Open file.
-- @param #string Text Line without newline.
-- @return #nil No return value.
function PROFILER._flog(File, Text)

  PROFILER._CheckFileResult(File:write(Text.."\r\n"))

end

--- Open, write and close a report, including cleanup after writer errors.
-- @param #string Path Output path.
-- @param #function Writer Function accepting the handle.
-- @return #boolean Whether writing and closing succeeded.
-- @return #string Failure explanation, or nil.
function PROFILER._WriteFile(Path, Writer)

  local opened,file,message=pcall(io.open,Path,"w")
  if not opened then return false,tostring(file) end
  if not file then return false,tostring(message) end
  local ok,err=pcall(Writer,file)
  local closed,closeError=pcall(function()
    PROFILER._CheckFileResult(file:close())
  end)
  if not ok then return false,tostring(err) end
  if not closed then return false,tostring(closeError) end
  return true

end

--- Escape a CSV field, including quotes, commas and newlines.
-- @param #string Value Field value; numbers are converted.
-- @return #string Quoted field.
function PROFILER._CSVField(Value)

  return '"'..tostring(Value):gsub('"','""')..'"'

end

--- Sort rows with a source/name fallback for equal values.
-- @param #table Data PROFILER.Data rows, sorted in place.
-- @param #string Key Numeric field, descending.
-- @return #nil No return value.
function PROFILER._Sort(Data, Key)

  table.sort(Data,function(a,b)
    if a[Key]~=b[Key] then return a[Key]>b[Key] end
    return a.src..":"..tostring(a.line)..":"..a.func<b.src..":"..tostring(b.line)..":"..b.func
  end)

end

--- Write filtered function statistics.
-- @param #table Data PROFILER.Data rows.
-- @param #table File Open text file.
-- @return #nil No return value.
function PROFILER.showTable(Data, File)

  for _,row in ipairs(Data) do
    PROFILER._flog(File,string.format("%30s: %d calls, %.3f/game sec | inclusive %.6f CPU sec | self %.6f CPU sec (%.3f%% CPU) | %.6f inclusive sec/call | %s line %s",
      row.func,row.count,row.cps,row.tm,row.self,row.percent,row.average,row.src,tostring(row.line)))
  end

end

--- Write the shared filtered dataset as CSV.
-- @param #table Data PROFILER.Data rows.
-- @param #string Path Output path.
-- @return #boolean Whether writing succeeded.
-- @return #string Failure explanation, or nil.
function PROFILER.printCSV(Data, Path)

  return PROFILER._WriteFile(Path,function(file)
    PROFILER._flog(file,"Function,Total Calls,Calls per Game Sec,Inclusive CPU Seconds,Self CPU Seconds,Self CPU Percent,Inclusive Seconds per Call,Source File,Line Number")
    for _,row in ipairs(Data) do
      local fields={row.func,row.count,string.format("%.6f",row.cps),string.format("%.6f",row.tm),
        string.format("%.6f",row.self),string.format("%.6f",row.percent),string.format("%.6f",row.average),row.src,row.line}
      for i,value in ipairs(fields) do fields[i]=PROFILER._CSVField(value) end
      PROFILER._flog(file,table.concat(fields,","))
    end
  end)

end

--- Write both reports while retaining data and collecting output errors.
-- @param #number GameSeconds Simulation duration.
-- @param #number CPUSeconds CPU duration.
-- @return #boolean Whether both files were written.
-- @return #PROFILER.Report Completed report, also saved as LastReport.
function PROFILER.showInfo(GameSeconds, CPUSeconds)

  local report=PROFILER._BuildReport(GameSeconds,CPUSeconds)
  PROFILER.LastReport=report
  local function failure(message)
    report.Errors[#report.Errors+1]=tostring(message)
    PROFILER._Error(tostring(message))
  end
  local ok,text,csv=pcall(PROFILER._ReportPaths)
  if not ok then failure(text) return false,report end
  if not text then failure(csv) return false,report end
  local data=report.Functions
  local written,err=PROFILER._WriteFile(text,function(file)
    PROFILER._flog(file,"---- Profiler Report ----")
    PROFILER._flog(file,string.format("Runtime: %.6f simulation sec, %.6f process CPU sec",GameSeconds,CPUSeconds))
    PROFILER._flog(file,string.format("Observed calls: %d; self CPU: %.6f sec; displayed functions: %d",report.Calls,report.SelfCPU,#data))
    PROFILER._flog(file,"Inclusive times overlap. Self CPU percentages use process CPU duration. Open frames are clipped at stop.")
    PROFILER._flog(file,string.format("Filters: >= %.6f calls/game sec and >= %.6f inclusive CPU sec",PROFILER.ThreshCPS,PROFILER.ThreshTtot))
    for _,section in ipairs({{"tm","Inclusive CPU time"},{"self","Self CPU time"},{"average","Inclusive CPU time per call"},{"count","Call count"}}) do
      PROFILER._Sort(data,section[1])
      PROFILER._flog(file,"\r\n---- "..section[2].." ----")
      PROFILER.showTable(data,file)
    end
  end)
  if written then report.TextFile=text else failure(text..": "..tostring(err)) end
  PROFILER._Sort(data,"tm")
  written,err=PROFILER.printCSV(data,csv)
  if written then report.CSVFile=csv else failure(csv..": "..tostring(err)) end
  env.info(string.format("PROFILER: stopped after %.6f CPU sec / %.6f simulation sec; %d calls, %d displayed functions",CPUSeconds,GameSeconds,report.Calls,#data))
  return #report.Errors==0,report

end
