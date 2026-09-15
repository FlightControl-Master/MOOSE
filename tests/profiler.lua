-- Standalone profiler regressions with real Lua hooks and deterministic clocks/files.
-- Run from the repository root with Lua 5.1 or Lua 5.4.
local real={os=os,io=io,debug=debug,timer=timer,world=world,env=env,lfs=lfs,UTILS=UTILS,PROFILER=PROFILER}
local cpu,game,files,handlers,tasks,nextID,errors,closed
local passed,failed=0,0
local function equal(a,b) assert(a==b,"expected "..tostring(b)..", got "..tostring(a)) end
local function near(a,b) assert(math.abs(a-b)<1e-8,"expected "..tostring(b)..", got "..tostring(a)) end
local function count(t) local n=0 for _ in pairs(t) do n=n+1 end return n end
local function fixture()
  cpu,game,files,handlers,tasks,nextID,errors,closed=0,0,{},{},{},0,{},{}
  os={clock=function() return cpu end}
  timer={getTime=function() return game end}
  timer.scheduleFunction=function(fn,arg,at)
    nextID=nextID+1 tasks[nextID]={fn=fn,arg=arg,at=at} return nextID
  end
  timer.removeFunction=function(id) tasks[id]=nil end
  world={event={S_EVENT_MISSION_END=99}}
  world.addEventHandler=function(handler) assert(not handlers[handler],"Duplicate handler") handlers[handler]=true end
  world.removeEventHandler=function(handler) handlers[handler]=nil end
  env={info=function() end,error=function(message) errors[#errors+1]=message end}
  lfs={writedir=function() return "memory/" end}
  UTILS={FileExists=function(path) return files[path]~=nil end}
  io={}
  io.open=function(path,mode)
    assert(mode=="w")
    if io.failOpen then return nil,"open denied" end
    assert(files[path]==nil,"Overwriting existing report")
    files[path]=""
    return {
      write=function(self,text)
        if io.failWrite then return nil,"disk full" end
        files[path]=files[path]..text
        if io.noWriteResult then return end
        return self
      end,
      close=function()
        closed[path]=true
        if io.failClose then return nil,"close failed" end
        if io.noCloseResult then return end
        return true
      end
    }
  end
  dofile("Moose Development/Moose/Utilities/Profiler.lua")
  PROFILER.ThreshTtot=0
  PROFILER.logUnknown=true
end
local function tick(at)
  game=at
  local ready={}
  for id,task in pairs(tasks) do if task.at<=at then ready[#ready+1]={id,task} end end
  table.sort(ready,function(a,b) return a[1]<b[1] end)
  for _,entry in ipairs(ready) do tasks[entry[1]]=nil entry[2].fn(entry[2].arg,at) end
end
local function test(name,run)
  fixture()
  local ok,err=pcall(run)
  PROFILER.Active=false
  real.debug.sethook()
  for key,value in pairs(real) do _G[key]=value end
  -- Globals absent before the suite must not leak into later regression suites.
  for _,key in ipairs({"timer","world","env","lfs","UTILS","PROFILER"}) do _G[key]=real[key] end
  if ok then passed=passed+1 print("PASS "..name)
  else failed=failed+1 print("FAIL "..name..": "..tostring(err)) end
end

test("nested calls separate inclusive and self CPU time",function()
  local function leaf() cpu=cpu+2 end
  local function parent() cpu=cpu+1 leaf() cpu=cpu+3 end
  assert(PROFILER.Start()) parent() game=12
  local ok,report=PROFILER.Stop()
  assert(ok) equal(PROFILER.Counters[parent],1) equal(PROFILER.Counters[leaf],1)
  near(PROFILER.fTimeTotal[parent],6) near(PROFILER.fTimeSelf[parent],4)
  near(PROFILER.fTimeTotal[leaf],2) near(PROFILER.fTimeSelf[leaf],2)
  near(report.RuntimeCPU,6) near(report.RuntimeGame,12) near(report.SelfCPU,6)
  for _,row in ipairs(report.Functions) do
    if row.func=="parent" then near(row.percent,400/6) near(row.cps,1/12) end
  end
  equal(#PROFILER._Stack,0) equal(count(handlers),0)
end)

test("recursive invocations each retain a separate start and child total",function()
  local function recurse(n)
    cpu=cpu+1
    if n>0 then local child=recurse(n-1) assert(child) end
    cpu=cpu+1 return true
  end
  PROFILER.Start() recurse(3) PROFILER.Stop()
  equal(PROFILER.Counters[recurse],4)
  near(PROFILER.fTimeTotal[recurse],20) near(PROFILER.fTimeSelf[recurse],8)
end)

test("tail recursion preserves inclusive logical parents on Lua 5.1 and newer",function()
  local function tail(n)
    cpu=cpu+1
    if n==0 then return true end
    return tail(n-1)
  end
  PROFILER.Start() tail(3) PROFILER.Stop()
  equal(PROFILER.Counters[tail],4)
  near(PROFILER.fTimeTotal[tail],10) near(PROFILER.fTimeSelf[tail],4)
end)

test("mutual tail calls and caught errors do not pollute later frame timing",function()
  local a,b
  a=function(n) cpu=cpu+1 if n==0 then return true end return b(n-1) end
  b=function(n) cpu=cpu+2 if n==0 then return true end return a(n-1) end
  local function bad() cpu=cpu+3 error("expected") end
  local function after() cpu=cpu+5 end
  PROFILER.Start() a(3) pcall(bad) after() PROFILER.Stop()
  equal(PROFILER.Counters[a],2) equal(PROFILER.Counters[b],2)
  near(PROFILER.fTimeTotal[a],9) near(PROFILER.fTimeTotal[b],7)
  near(PROFILER.fTimeSelf[a],2) near(PROFILER.fTimeSelf[b],4)
  near(PROFILER.fTimeTotal[bad],3) near(PROFILER.fTimeTotal[after],5)
  near(PROFILER.LastReport.SelfCPU,14)
end)

test("open frames close at stop and restarted measurements have fresh data",function()
  local function partial()
    cpu=cpu+4 PROFILER.Stop() cpu=cpu+10
  end
  PROFILER.Start() partial()
  near(PROFILER.fTimeTotal[partial],4) equal(PROFILER.Counters[partial],1)
  local old=PROFILER.LastReport
  equal(PROFILER.Stop(),false) equal(PROFILER.LastReport,old)
  PROFILER.Start() equal(PROFILER.Counters[partial],nil) equal(PROFILER.LastReport,nil)
  PROFILER.Stop() assert(PROFILER.LastReport~=old)
end)

test("duplicate starts are rejected and idle stops do not touch unrelated hooks",function()
  local function previous() end
  debug.sethook(previous,"l",13)
  equal(PROFILER.Stop(),false) equal(debug.gethook(),previous)
  assert(PROFILER.Start())
  local counters=PROFILER.Counters local start=PROFILER.TstartOS
  equal(PROFILER.Start(),false) equal(PROFILER.Counters,counters) equal(PROFILER.TstartOS,start)
  equal(count(handlers),1) PROFILER.Stop()
  local hook,mask,instructions=debug.gethook()
  equal(hook,previous) equal(mask,"l") equal(instructions,13)
end)

test("stop preserves a hook installed by another tool during measurement",function()
  PROFILER.Start()
  local function replacement() end
  debug.sethook(replacement,"c",17)
  PROFILER.Stop()
  local hook,mask,instructions=debug.gethook()
  equal(hook,replacement) equal(mask,"c") equal(instructions,17)
end)

test("delayed starts can be cancelled and old callbacks cannot affect a new run",function()
  assert(PROFILER.Start(5,10)) equal(PROFILER.Active,false) equal(count(handlers),1)
  equal(PROFILER.Start(),false)
  local staleStart=tasks[PROFILER._StartTimer]
  assert(PROFILER.Stop()) equal(count(tasks),0) equal(count(handlers),0)
  PROFILER.Start() local counters=PROFILER.Counters
  staleStart.fn() equal(PROFILER.Counters,counters)
  PROFILER.Stop(5) local staleStop=tasks[PROFILER._StopTimer]
  PROFILER.Stop() PROFILER.Start()
  staleStop.fn() equal(PROFILER.Active,true)
  PROFILER.Stop()
end)

test("duration timers and mission-end handlers stop exactly once",function()
  PROFILER.Start(5,10) tick(5) equal(PROFILER.Active,true)
  equal(count(handlers),1) tick(15) equal(PROFILER.Active,false) equal(count(handlers),0)
  equal(count(files),2)
  PROFILER.eventHandler:onEvent({id=99}) equal(count(files),2)
  PROFILER.Start(10) PROFILER.eventHandler:onEvent({id=99})
  equal(count(tasks),0) equal(count(handlers),0) equal(count(files),2)
  PROFILER.Start() PROFILER.eventHandler:onEvent({id=99})
  equal(PROFILER.Active,false) equal(count(handlers),0) equal(count(files),4)
end)

test("zero CPU and simulation duration produces finite rates and percentages",function()
  PROFILER.Start(0,0)
  equal(PROFILER.Active,false)
  local report=PROFILER.LastReport near(report.RuntimeCPU,0) near(report.RuntimeGame,0)
  for _,row in ipairs(report.Functions) do near(row.cps,0) near(row.percent,0) end
  for _,text in pairs(files) do
    assert(not text:lower():find("nan")) assert(not text:lower():find("inf,"))
  end
end)

test("CSV escaping and text filters use the same dataset with correct CPU percentages",function()
  local high,low=function() end,function() end
  PROFILER.Counters={[high]=10,[low]=1}
  PROFILER.dInfo={[high]={name='name,"quoted"\nline',short_src='dir,a"b.lua',linedefined=12},[low]={name="hidden",short_src="b.lua",linedefined=2}}
  PROFILER.fTimeTotal={[high]=2,[low]=0.01} PROFILER.fTimeSelf={[high]=1,[low]=0.01}
  PROFILER.ThreshCPS=2 PROFILER.ThreshTtot=0.5
  local ok,report=PROFILER.showInfo(5,4)
  assert(ok) equal(#report.Functions,1) near(report.Functions[1].percent,25)
  near(report.Functions[1].cps,2) equal(report.Calls,11)
  local csv=files[report.CSVFile]
  assert(csv:find('"name,""quoted""\nline"',1,true))
  assert(csv:find('"dir,a""b.lua"',1,true))
  assert(csv:find("Source File,Line Number",1,true)) assert(not csv:find("hidden",1,true))
  assert(not files[report.TextFile]:find("hidden",1,true))
end)

test("unknown functions are optional and equal names from different functions stay separate",function()
  local a,b,c=function() end,function() end,function() end
  PROFILER.Counters={[a]=1,[b]=1,[c]=1}
  PROFILER.dInfo={[a]={name="_copy",short_src="a.lua"},[b]={name="_copy",short_src="b.lua"},[c]={short_src="c.lua"}}
  PROFILER.logUnknown=false
  local report=PROFILER._BuildReport(1,1) equal(#report.Functions,2)
  PROFILER.logUnknown=true equal(#PROFILER._BuildReport(1,1).Functions,3)
end)

test("report pairs share an unused basename and exhausted names return an error",function()
  files["memory/Logs/MooseProfiler.csv"]="existing"
  files["memory/Logs/MooseProfiler-001.txt"]="existing"
  PROFILER.Start() local ok,report=PROFILER.Stop()
  assert(ok) equal(report.TextFile,"memory/Logs/MooseProfiler-002.txt") equal(report.CSVFile,"memory/Logs/MooseProfiler-002.csv")
  equal(files["memory/Logs/MooseProfiler.csv"],"existing")
  UTILS.FileExists=function() return true end
  PROFILER.Start() ok,report=PROFILER.Stop()
  equal(ok,false) equal(#report.Errors,1) equal(PROFILER.Active,false) equal(count(handlers),0)
end)

test("open write and close failures retain report data and always clean up lifecycle",function()
  for _,failure in ipairs({"failOpen","failWrite","failClose"}) do
    io[failure]=true
    PROFILER.Start() cpu=cpu+1
    local ok,report=PROFILER.Stop()
    equal(ok,false) equal(#report.Errors,2) equal(PROFILER.LastReport,report)
    equal(PROFILER.Active,false) equal(count(handlers),0) equal(debug.gethook(),nil)
    if failure~="failOpen" then equal(count(closed),count(files)) end
    io[failure]=nil
  end
end)

test("invalid configuration and missing APIs reject before changing hooks or handlers",function()
  for _,args in ipairs({{-1},{0,-1},{math.huge},{0,0/0}}) do
    equal(PROFILER.Start(args[1],args[2]),false) equal(count(handlers),0)
  end
  PROFILER.ThreshCPS=-1 equal(PROFILER.Start(),false) PROFILER.ThreshCPS=0
  PROFILER.fileNameSuffix="CSV" equal(PROFILER.Start(),false) PROFILER.fileNameSuffix="txt"
  local saved=debug debug={} equal(PROFILER.Start(),false) debug=saved
  os=nil equal(PROFILER.Start(),false) os={clock=function() return cpu end}
  equal(debug.gethook(),nil) equal(count(handlers),0) equal(count(files),0)
end)

test("scheduler and hook installation failures leave no half-started measurement",function()
  local schedule=timer.scheduleFunction
  timer.scheduleFunction=function() error("scheduler failed") end
  equal(PROFILER.Start(1),false) equal(PROFILER.Active,false) equal(count(handlers),0) equal(count(tasks),0)
  equal(PROFILER.Start(0,1),false) equal(PROFILER.Active,false) equal(debug.gethook(),nil) equal(count(handlers),0)
  timer.scheduleFunction=schedule
  local original=debug
  debug={getinfo=original.getinfo,gethook=original.gethook,sethook=function() error("hook denied") end}
  equal(PROFILER.Start(),false) equal(PROFILER.Active,false) equal(count(handlers),0)
  debug=original
  equal(debug.gethook(),nil)
  assert(PROFILER.Start(0,20))
  local stopID=PROFILER._StopTimer
  timer.scheduleFunction=function() return nil end
  equal(PROFILER.Stop(10),false) equal(PROFILER._StopTimer,stopID) assert(tasks[stopID])
  timer.scheduleFunction=schedule
  PROFILER.Stop()
end)

test("pending runs reject delayed stops and invalid delays preserve existing state",function()
  equal(PROFILER.Start(false),false)
  assert(PROFILER.Start(2))
  local id=PROFILER._StartTimer
  equal(PROFILER.Stop(5),false) equal(PROFILER._StartTimer,id) equal(PROFILER._StopTimer,nil)
  equal(PROFILER.Stop(false),false) equal(PROFILER._StartTimer,id)
  equal(PROFILER.Stop(-1),false) equal(PROFILER._StartTimer,id)
  tick(2) equal(PROFILER.Active,true) PROFILER.Stop()
end)

test("foreign coroutine events cannot change the measured thread's call stack",function()
  local function foreign() cpu=cpu+3 end
  local function owner()
    cpu=cpu+1
    local co=coroutine.create(foreign)
    assert(coroutine.resume(co))
    cpu=cpu+2
  end
  PROFILER.Start() owner() PROFILER.Stop()
  equal(PROFILER.Counters[foreign],nil)
  near(PROFILER.fTimeTotal[owner],6) near(PROFILER.fTimeSelf[owner],3)
end)

test("profiling a coroutine restores that coroutine's hook and leaves the main hook alone",function()
  local function mainHook() end
  local function coHook() end
  debug.sethook(mainHook,"l",11)
  local function work() cpu=cpu+2 end
  local co=coroutine.create(function()
    debug.sethook(coHook,"c",7)
    assert(PROFILER.Start()) work() assert(PROFILER.Stop())
    local hook,mask,instructions=debug.gethook()
    equal(hook,coHook) equal(mask,"c") equal(instructions,7)
  end)
  assert(coroutine.resume(co))
  equal(debug.gethook(),mainHook) near(PROFILER.fTimeTotal[work],2)
end)

test("a failed new start preserves the last completed measurement",function()
  local function work() cpu=cpu+1 end
  PROFILER.Start() work() PROFILER.Stop()
  local report,counters=PROFILER.LastReport,PROFILER.Counters
  local schedule=timer.scheduleFunction
  timer.scheduleFunction=function() error("unavailable") end
  equal(PROFILER.Start(0,1),false)
  equal(PROFILER.LastReport,report) equal(PROFILER.Counters,counters)
  equal(PROFILER.Active,false) equal(count(handlers),0) equal(debug.gethook(),nil)
  timer.scheduleFunction=schedule
end)

test("one failed output does not prevent the other format from being written",function()
  local open=io.open
  io.open=function(path,mode)
    if path:find(".txt",1,true) then return nil,"text denied" end
    return open(path,mode)
  end
  PROFILER.Start() local ok,report=PROFILER.Stop()
  equal(ok,false) equal(#report.Errors,1) equal(report.TextFile,nil)
  assert(report.CSVFile and files[report.CSVFile])
  io.open=open
  PROFILER.Start() PROFILER.fileNameSuffix="csv"
  ok,report=PROFILER.Stop()
  equal(ok,false) equal(#report.Errors,1) equal(count(files),1)
end)

test("DCS file write and close may succeed without returning values",function()
  for _,case in ipairs({{true,false},{false,true},{true,true}}) do
    io.noWriteResult=case[1] io.noCloseResult=case[2]
    local function measured() cpu=cpu+2 end
    PROFILER.Start() measured()
    local ok,report=PROFILER.Stop()
    equal(ok,true) equal(#report.Errors,0)
    assert(files[report.TextFile]:find("---- Call count ----",1,true))
    assert(files[report.CSVFile]:find('"measured"',1,true))
    assert(closed[report.TextFile] and closed[report.CSVFile])
  end
  equal(count(files),6) equal(count(errors),0)
end)

test("explicit nil false and thrown file errors remain failures",function()
  for _,phase in ipairs({"write","close"}) do
    for _,failure in ipairs({function() return nil end,function() return false end,function() error("file exception") end}) do
      local didClose=false
      io.open=function()
        return {
          write=function() if phase=="write" then return failure() end end,
          close=function() didClose=true if phase=="close" then return failure() end end
        }
      end
      local ok,message=PROFILER._WriteFile("unused",function(file) PROFILER._flog(file,"row") end)
      equal(ok,false) assert(type(message)=="string" and #message>0) equal(didClose,true)
    end
  end
end)

print(string.format("%d passed, %d failed",passed,failed))
if failed>0 then os.exit(1) end
