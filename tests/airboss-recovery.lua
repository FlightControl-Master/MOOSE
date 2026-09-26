-- Standalone AIRBOSS recovery regressions. Run from the repository root:
-- lua54/lua54.exe tests/airboss-recovery.lua
-- Loads production AIRBOSS methods. NAVYGROUP is a service mock; its physical
-- maneuver and timed-adapter behavior are covered by the NAVYGROUP test suite.
local file=assert(io.open("Moose Development/Moose/Ops/Airboss.lua","rb"))
local source=file:read("*a"):gsub("\r\n","\n") file:close()
AIRBOSS={
  PatternStep={COMMENCING="Commencing",INITIAL="Initial",PLATFORM="Platform"},
  Difficulty={HARD="Hard",EASY="Easy"},
}
setmetatable(AIRBOSS,{__index=function(class,name)
  local first=source:find("function AIRBOSS:"..name.."(",1,true)
  if not first then return nil end
  local last=assert(source:find("\nend",first,true),name)
  assert((loadstring or load)(source:sub(first,last+3),"@Airboss.lua:"..name))()
  return rawget(class,name)
end})

local now=0
local noop=function() end
local unpack=table.unpack or unpack
timer={getAbsTime=function() return now end,getTime=function() return now end}
UTILS={SecondsToClock=tostring,ClockToSeconds=tonumber,MpsToKnots=function(v) return v*1.94384449244 end}
MESSAGE={New=function() return {ToAllIf=noop} end}
EVENTS={Birth=1,RunwayTouch=2,EngineShutdown=3,Takeoff=4,Crash=5,Ejection=6,PlayerLeaveUnit=7,MissionEnd=8,RemoveUnit=9}
local passed,failed=0,0
local function test(name,run)
  local ok,err=xpcall(run,debug.traceback)
  if ok then passed=passed+1 print("PASS "..name)
  else failed=failed+1 print("FAIL "..name..": "..tostring(err)) end
end
local function equal(actual,expected,label)
  assert(actual==expected,(label or "value")..": expected "..tostring(expected)..", got "..tostring(actual))
end
local function remove(queue,flight)
  for i,item in ipairs(queue) do
    if item==flight then table.remove(queue,i) return true end
  end
  return false
end

local function setup()
  now=0
  local n={begins=0,updates=0,ends=0,aborts=0,timedAdds=0,timedRemoves=0,plans={},ended={},running=true}
  function n:BeginIntoWind(options)
    if self.current or self.busy then return nil,"busy" end
    self.begins=self.begins+1
    local m={Id=self.begins,State="Active",Ready=false}
    for key,value in pairs(options) do m[key]=value end
    self.current=m
    return m
  end
  function n:GetIntoWindManeuver() return self.current end
  function n:UpdateIntoWind(m,options)
    if self.current~=m or m.State~="Active" then return nil,"not active" end
    self.updates=self.updates+1
    for key,value in pairs(options) do m[key]=value end
    return m
  end
  local function finish(self,m,options,abort)
    if m.State=="Ended" then return true,"already ended" end
    if self.current~=m then return false,"not owner" end
    if self.vetoEnd and not abort then return false,"veto" end
    self.current=nil m.State="Ended" m.Ready=false
    self.ended[#self.ended+1]={maneuver=m,options=options or {},abort=abort}
    if m.OnEnded then m.OnEnded(m,(options and options.Reason) or "ended") end
    return true
  end
  function n:EndIntoWind(m,options)
    self.ends=self.ends+1
    return finish(self,m,options,false)
  end
  function n:AbortIntoWind(m,options)
    self.aborts=self.aborts+1
    return finish(self,m,options,true)
  end
  function n:AddTurnIntoWind(start,duration,speed,uturn,angle,options)
    self.timedAdds=self.timedAdds+1
    local w={Id=self.timedAdds,Tstart=now+start,Tstop=now+duration,Speed=speed,Uturn=uturn,Offset=angle,Options=options or {}}
    self.plans[#self.plans+1]=w
    return w
  end
  function n:RemoveTurnIntoWind(w,abort,options)
    if self.vetoEnd and not abort then return self,false,"veto" end
    local completion={Uturn=w.Uturn,Resume=false}
    for name,value in pairs(options or {}) do completion[name]=value end
    if w.Maneuver then
      local success,reason
      if abort then success,reason=self:AbortIntoWind(w.Maneuver,completion)
      else success,reason=self:EndIntoWind(w.Maneuver,completion) end
      if not success then return self,false,reason end
    end
    self.timedRemoves=self.timedRemoves+1
    remove(self.plans,w) w.Over=true w.Open=false
    if self.airboss then self.airboss:_OnNavyIntoWindOver(w) end
    return self,true
  end
  function n:GetTurnIntoWindCurrent() return self.timedCurrent end
  function n:GetTurnIntoWind(id)
    for _,w in ipairs(self.plans) do if w.Id==id then return w end end
  end
  function n:ExtendTurnIntoWind() error("AIRBOSS recovery must not extend a NAVYGROUP deadline") end
  function n:IsTurning() return self.turning==true end
  function n:IsAlive() return self.alive~=false end
  function n:IsStopped() return self.running==false end
  function n:IsHolding() return self.holding==true end
  function n:IsWaiting() return self.waiting==true end
  function n:Cruise() self.cruises=(self.cruises or 0)+1 end
  function n:Detour(coord) self.detour=coord end
  function n:Stop() error("AIRBOSS must not stop NAVYGROUP") end

  local a=setmetatable({
    state="Idle",navygroup=n,recoverytimes={},windowcount=0,defaultcase=1,defaultoffset=0,
    case=1,holdingoffset=0,dTturn=300,carrierparam={rwyangle=-9.1},lid="",alias="CVN",Debug=false,
    Qpattern={},Qmarshal={},Qwaiting={},Qspinning={},flights={},players={},Nmaxpattern=10,
    carrier={GetName=function() return "Carrier" end,IsAlive=function() return true end},
    scheduled={},scheduledDelays={},pauseAnnouncements={},messages={},clearances={},landings={},restacked={},startAttempts=0,stopAttempts=0,
    T=noop,T2=noop,I=noop,F=noop,_PrintQueue=noop,UnHandleEvent=noop,_RemoveF10Commands=noop,
    _MarshalCallRecoveryStart=noop,_MarshalCallRecoveryStopped=noop,
    _MarshalCallResumeRecovery=noop,MessageToPattern=noop,
    CallScheduler={Clear=noop},StatusTimer={Stop=noop},radiotimer={Clear=noop},Scheduler={Clear=noop},
  },{__index=AIRBOSS})
  n.airboss=a
  function a:E(message) self.messages[#self.messages+1]=message end
  function a:is(s) return self.state==s end
  a.Is=a.is
  function a:GetState() return self.state end
  function a:SetStartState(state) self.state=state end
  function a:IsIdle() return self:is("Idle") end
  function a:IsRecovering() return self:is("Recovering") end
  function a:IsPaused() return self:is("Paused") end
  function a:_GetQueueInfo(q) return #q,q==self.Qpattern and (self.pattern or #q) or #q end
  function a:_ResolveRecoveryCase(c) return c or self.defaultcase end
  function a:RecoveryCase(c,o)
    if self:onbeforeRecoveryCase(self.state,"RecoveryCase",self.state,c,o)==false then return false end
    self:onafterRecoveryCase(self.state,"RecoveryCase",self.state,c,o)
    return true
  end
  function a:RecoveryStart(c,o,w)
    self.startAttempts=self.startAttempts+1
    if self.state~="Idle" or self.vetoStart then return false end
    if self.beforeStart and self:beforeStart(c,o,w)==false then return false end
    self.state="Recovering"
    self:onafterRecoveryStart("Idle","RecoveryStart","Recovering",c,o,w)
    return true
  end
  function a:RecoveryStop(w)
    self.stopAttempts=self.stopAttempts+1
    if not (self:IsRecovering() or self:IsPaused()) or self.vetoStop then return false end
    if self.beforeStop and self:beforeStop(w)==false then return false end
    local from=self.state self.state="Idle"
    self:onafterRecoveryStop(from,"RecoveryStop","Idle",w)
    return true
  end
  function a:RecoveryUnpause()
    self.state="Recovering" self:onafterRecoveryUnpause("Paused","RecoveryUnpause","Recovering")
  end
  function a:Idle()
    local from=self.state self.state="Idle"
    self:onafterIdle(from,"Idle","Idle")
  end
  function a:ScheduleOnce(delay,fn,...)
    local args={...}
    self.scheduled[#self.scheduled+1]=function() fn(unpack(args)) end
    self.scheduledDelays[#self.scheduledDelays+1]=delay
  end
  function a:_MarshalCallRecoveryPausedResumedAt(clock)
    self.pauseAnnouncements[#self.pauseAnnouncements+1]={clock=clock}
  end
  function a:_MarshalCallRecoveryPausedUntilFurtherNotice()
    self.pauseAnnouncements[#self.pauseAnnouncements+1]={notice=true}
  end
  function a:_InQueue(q,g)
    for _,f in ipairs(q) do if f.group==g then return true end end
    return false
  end
  function a:_RemoveFlightFromQueue(q,f) return remove(q,f) end
  function a:_GetFreeStack() return #self.Qmarshal+1 end
  function a:_MarshalAI(f,stack)
    f.case=self.case f.flag=stack f.time=now
    self.restacked[#self.restacked+1]=f
    if not self:_InQueue(self.Qmarshal,f.group) then self.Qmarshal[#self.Qmarshal+1]=f end
  end
  a._MarshalPlayer=a._MarshalAI
  function a:_RemoveFlightFromMarshalQueue(f)
    remove(self.Qmarshal,f)
    if not self:_InQueue(self.Qpattern,f.group) then self.Qpattern[#self.Qpattern+1]=f end
  end
  function a:_LandAI(f) self.landings[#self.landings+1]=f end
  function a:_MarshalCallClearedForRecovery(onboard,c) self.clearances[#self.clearances+1]={onboard=onboard,case=c} end
  function a:_SetPlayerStep(f,step) f.step=step end
  function a:_InitPlayer(f) f.initializations=(f.initializations or 0)+1 end
  function a:MessageToPlayer(f,message) self.messages[#self.messages+1]=message end
  function a:_GetZoneCommence() return {} end
  function a:_AddFlightToPatternQueue(f) self.Qpattern[#self.Qpattern+1]=f end
  return a,n
end

local function window(a,start,stop,options)
  options=options or {}
  return a:AddRecoveryWindow(tostring(start),tostring(stop),options.case or 1,0,
    options.wind~=false,options.speed or 25,options.uturn)
end
local function at(t,a) now=t a:_CheckRecoveryTimes() end
local function pause(a,duration)
  a.state="Paused" a:onafterRecoveryPause("Recovering","RecoveryPause","Paused",duration)
end
local function flight(a,ai,c)
  local f={name="Pilot",seclead="Pilot",unitname="Hornet",group={},groupname="Hornet",onboard="012",
    ai=ai,case=c or 1,flag=1,time=now-600,holding=true,section={},difficulty=AIRBOSS.Difficulty.HARD,
    unit={IsInZone=function() return true end,InAir=function() return true end}}
  a.flights[#a.flights+1]=f a.Qmarshal[#a.Qmarshal+1]=f
  if not ai then
    a.players[f.name]=f
    function a:_GetPlayerUnitAndName() return f.unit,f.name end
  end
  return f
end

test("recovery extension changes only AIRBOSS's deadline",function()
  local a,n=setup() local w=window(a,10,20)
  at(0,a) local m=n.current
  assert(m and m.ReferenceUnit==a.carrier)
  equal(n.timedAdds,0) equal(m.Tstop,nil)
  at(10,a) equal(a.activeRecoveryWindow,w) assert(w.OPEN)
  a.pattern=1 at(20,a)
  equal(w.STOP,320) equal(n.current,m) equal(n.updates,0)
  a.pattern=0 at(320,a)
  assert(a:IsIdle() and w.OVER and not n.current)
  equal(n.ends,1) equal(n.ended[1].options.Uturn,true)
end)

test("paused window retains its deadline and closes with an empty pattern",function()
  local a,n=setup() local w=window(a,10,20)
  at(0,a) at(10,a) pause(a,100)
  at(20,a)
  assert(a:IsIdle() and w.OVER and not n.current)
  a.scheduled[1]() assert(a:IsIdle(),"old unpause must not reopen an ended window")
end)

test("paused window with traffic extends without ending the wind maneuver",function()
  local a,n=setup() local w=window(a,10,20)
  at(0,a) at(10,a) local m=n.current pause(a)
  a.pattern=2 at(20,a)
  assert(a:IsPaused()) equal(w.STOP,620) equal(n.current,m) equal(n.ends,0)
end)

test("a timed pause announces and resumes before the active window end",function()
  local a=setup()
  local w=window(a,10,20)
  at(10,a)

  pause(a,5)

  equal(#a.pauseAnnouncements,1)
  equal(a.pauseAnnouncements[1].clock,"15")
  equal(a.pauseAnnouncements[1].notice,nil)
  equal(a.scheduledDelays[1],5)
  equal(w.STOP,20)

  now=15
  a.scheduled[1]()
  assert(a:IsRecovering())
  equal(a.activeRecoveryWindow,w)
end)

test("a pause at or beyond the active window end announces further notice",function()
  for _,duration in ipairs({10,100}) do
    local a=setup()
    local w=window(a,10,20)
    at(10,a)

    pause(a,duration)

    equal(#a.pauseAnnouncements,1)
    equal(a.pauseAnnouncements[1].notice,true)
    equal(a.pauseAnnouncements[1].clock,nil)
    equal(a.scheduledDelays[1],duration)
    equal(w.STOP,20)

    -- The original timer still reconciles expiry instead of reopening recovery.
    now=10+duration
    a.scheduled[1]()
    assert(a:IsIdle() and w.OVER)
    equal(a.activeRecoveryWindow,nil)
  end
end)

test("an indefinite pause announces further notice without a resume timer",function()
  local a=setup()
  local w=window(a,10,20)
  at(10,a)

  pause(a)

  equal(#a.pauseAnnouncements,1)
  equal(a.pauseAnnouncements[1].notice,true)
  equal(a.pauseAnnouncements[1].clock,nil)
  equal(#a.scheduled,0)
  equal(w.STOP,20)
  assert(a:IsPaused())
end)

test("manual recovery announces its resume time without an active window",function()
  for _,hasFutureWindow in ipairs({false,true}) do
    local a=setup()
    local future
    if hasFutureWindow then
      future=window(a,100,200,{wind=false})
      at(0,a)
    end

    a:RecoveryStart()
    equal(a.activeRecoveryWindow,nil)
    equal(a.recoverywindow,future)
    pause(a,300)

    -- An unrelated upcoming window must not limit a manually started recovery.
    equal(#a.pauseAnnouncements,1)
    equal(a.pauseAnnouncements[1].clock,"300")
    equal(a.pauseAnnouncements[1].notice,nil)
    equal(a.scheduledDelays[1],300)

    now=300
    a.scheduled[1]()
    assert(a:IsRecovering())
  end
end)

test("a pause announcement uses an extension already applied to the deadline",function()
  local a=setup()
  local w=window(a,10,20)
  at(10,a)
  a.pattern=1
  at(20,a)
  equal(w.SCHEDULEDSTOP,20)
  equal(w.STOP,320)

  pause(a,50)

  equal(a.pauseAnnouncements[1].clock,"70")
  equal(a.pauseAnnouncements[1].notice,nil)
  equal(w.STOP,320)

  now=70
  a.scheduled[1]()
  assert(a:IsRecovering())
  equal(a.activeRecoveryWindow,w)
end)

test("a pause cannot announce resumption at an extended deadline",function()
  local a=setup()
  local w=window(a,10,20)
  at(10,a)
  a.pattern=1
  at(20,a)

  pause(a,300)

  equal(w.STOP,320)
  equal(a.pauseAnnouncements[1].notice,true)
  equal(a.pauseAnnouncements[1].clock,nil)

  a.pattern=0
  now=320
  a.scheduled[1]()
  assert(a:IsIdle() and w.OVER)
end)

test("further notice preserves timed resumption after a later traffic extension",function()
  local a=setup()
  local w=window(a,10,20)
  at(10,a)
  a.pattern=1

  pause(a,20)

  equal(a.pauseAnnouncements[1].notice,true)
  equal(a.pauseAnnouncements[1].clock,nil)
  equal(w.STOP,20)
  equal(a.scheduledDelays[1],20)

  -- Traffic can extend the window later, but is not a guaranteed future deadline.
  now=30
  a.scheduled[1]()
  assert(a:IsRecovering())
  equal(w.STOP,330)
  equal(w.SCHEDULEDSTOP,20)
  equal(a.activeRecoveryWindow,w)
end)

test("public Idle during recovery cannot leave its maneuver alive past expiry",function()
  local a,n=setup() local w=window(a,10,20)
  at(0,a) at(10,a) a:Idle()
  at(30,a)
  assert(a:IsIdle() and w.OVER and not w.OPEN)
  equal(a.activeRecoveryWindow,nil) equal(a.recoveryManeuver,nil) equal(n.current,nil)
end)

test("adjacent windows share one maneuver and only final Uturn applies",function()
  local a,n=setup() local w1=window(a,10,20,{uturn=true})
  local w2=window(a,20,40,{speed=30,uturn=false,case=3})
  at(0,a) local m=n.current at(10,a) at(20,a)
  equal(n.current,m) equal(a.activeRecoveryWindow,w2) assert(w1.OVER)
  equal(m.DeckWind,30) equal(n.begins,1) equal(n.ends,0)
  at(40,a) equal(n.ended[1].options.Uturn,false) assert(w2.OVER)
end)

test("extension still hands off at the original adjacent boundary",function()
  local a,n=setup() local w1=window(a,10,20)
  local w2=window(a,20,700,{speed=30,uturn=false})
  at(0,a) local m=n.current at(10,a)
  a.pattern=1 at(20,a) equal(a.activeRecoveryWindow,w1)
  a.pattern=0 at(320,a)
  equal(a.activeRecoveryWindow,w2) equal(n.current,m) equal(n.ends,0)
end)

test("an entirely skipped short window cannot leave its preparation running",function()
  local a,n=setup() local w=window(a,10,20)
  at(0,a) assert(n.current) at(31,a)
  assert(a:IsIdle() and w.OVER and not n.current)
  equal(a.recoveryManeuver,nil) equal(a.recoveryManeuverWindow,nil)
end)

test("a newly inserted earlier window replaces prepared later settings",function()
  local a,n=setup() local later=window(a,200,400,{speed=20})
  at(0,a) equal(a.recoveryManeuverWindow,later)
  local earlier=window(a,10,100,{speed=30}) at(10,a)
  equal(a.activeRecoveryWindow,earlier) equal(a.recoveryManeuverWindow,earlier)
  equal(n.current.DeckWind,30)
end)

test("a vetoed recovery start is bounded and its preparation expires",function()
  local a,n=setup() local w=window(a,10,20) a.vetoStart=true
  at(0,a) at(10,a) equal(a.startAttempts,1)
  at(21,a) at(1000,a)
  assert(a:IsIdle() and w.OVER and not n.current)
end)

test("a vetoed recovery stop retains the active window and owned maneuver",function()
  local a,n=setup() local w=window(a,10,20)
  at(0,a) at(10,a) local m=n.current a.vetoStop=true
  at(20,a)
  equal(a.activeRecoveryWindow,w) equal(a.recoveryManeuver,m) equal(n.current,m)
  assert(a:IsRecovering() and not w.OVER)
  a.vetoStop=false at(21,a) assert(w.OVER and not n.current)
end)

test("a vetoed NAVY end keeps ownership until cleanup can finish",function()
  local a,n=setup() window(a,10,20)
  at(0,a) at(10,a) local m=n.current n.vetoEnd=true
  a:_StopNavyIntoWind()
  equal(a.recoveryManeuver,m) equal(n.current,m)
  n.vetoEnd=false a:_StopNavyIntoWind()
  equal(n.current,nil) equal(a.recoveryManeuver,nil)
end)

test("automatic recovery completion preserves navigation holds",function()
  local a,n=setup() window(a,10,20)
  at(0,a) at(10,a) n.holding=true
  at(20,a)
  equal(n.current,nil)
  equal(n.ended[1].options.Resume,false)
  equal(n.holding,true)
end)

test("recovery cleanup does not modify shared completion options",function()
  local a,n=setup() window(a,10,20)
  at(0,a)
  local destination={x=500,y=0,z=100}
  local options={Uturn=true,ReturnCoordinate=destination,Reason="test-ended"}
  assert(a:_StopRecoveryIntoWind(false,options))
  equal(options.Resume,nil)
  equal(n.ended[1].options.Resume,false)
  equal(n.ended[1].options.ReturnCoordinate,destination)
  equal(n.ended[1].options.Reason,"test-ended")
end)

test("late completion of an old maneuver cannot clear a new one",function()
  local a,n=setup() window(a,10,20)
  at(0,a) local old=n.current at(10,a) at(20,a)
  local w2=window(a,30,40) at(21,a) local current=n.current
  assert(current and current~=old)
  old.OnEnded(old,"late duplicate")
  equal(a.recoveryManeuver,current) equal(a.recoveryManeuverWindow,w2)
end)

test("windless recovery does not acquire or stop an unrelated NAVY maneuver",function()
  local a,n=setup() local foreign=n:BeginIntoWind({DeckWind=15})
  local w=window(a,10,20,{wind=false})
  at(10,a) equal(a.activeRecoveryWindow,w) equal(a.recoveryManeuver,nil)
  at(20,a) equal(n.current,foreign) equal(n.ends,0) assert(w.OVER)
end)

test("busy NAVY cannot silently enqueue a recovery maneuver past its deadline",function()
  local a,n=setup() local foreign=n:BeginIntoWind({DeckWind=15})
  local w=window(a,10,20)
  at(0,a) at(10,a)
  equal(a.recoveryManeuver,nil) equal(n.timedAdds,0)
  assert(not a:_CanClearForRecovery(false))
  at(21,a) equal(n.current,foreign) equal(n.timedAdds,0) assert(w.OVER)
end)

test("AIRBOSS Stop forces only its own cleanup and preserves future windows",function()
  local a,n=setup() local active=window(a,10,20)
  local future=window(a,100,200)
  at(0,a) at(10,a) n.vetoEnd=true
  a.state="Stopped" a:onafterStop("Recovering","Stop","Stopped")
  equal(n.current,nil) assert(n.aborts>0 and n.running)
  equal(n.ended[1].options.Resume,false)
  assert(active.OVER and not future.OVER) equal(a.recoveryManeuver,nil)
  equal(a.recoveryManeuverWindow,nil) equal(n.airboss,nil)
end)

test("CarrierResumeRoute suppresses automatic restart for the same recovery",function()
  local a,n=setup() local w=window(a,10,20)
  at(0,a) at(10,a) a:CarrierResumeRoute()
  equal(n.current,nil) equal(a.activeRecoveryWindow,w)
  equal(n.ended[1].options.Resume,true)
  at(11,a) equal(n.current,nil) equal(n.begins,1)
  at(20,a) assert(w.OVER)
end)

test("manual timed wrapper retains duration, units and independent completion",function()
  local a,n=setup()
  a:CarrierTurnIntoWind(120,10,true)
  equal(n.timedAdds,1) equal(n.begins,0)
  local w=a.manualWindWindow
  assert(w and math.abs(w.Speed-19.4384449244)<1e-9)
  equal(w.Tstop,120) equal(w.Uturn,true)
  n:RemoveTurnIntoWind(w) equal(a.manualWindWindow,nil)
end)

test("explicit route resume forwards options through the timed stop veto",function()
  local a,n=setup()
  a:CarrierTurnIntoWind(120,10,true)
  local w=a.manualWindWindow
  w.Maneuver=n:BeginIntoWind({DeckWind=20})
  n.timedCurrent=w
  n.vetoEnd=true
  local destination={x=1000,y=0,z=1000}

  a:CarrierResumeRoute(destination)
  equal(a.manualWindWindow,w)
  equal(n.current,w.Maneuver)
  equal(#n.ended,0)

  n.vetoEnd=false
  a:CarrierResumeRoute(destination)
  equal(a.manualWindWindow,nil)
  equal(n.current,nil)
  equal(n.ended[1].options.Resume,true)
  equal(n.ended[1].options.ReturnCoordinate,destination)
end)

test("Stop cancels its own manual timed window but preserves foreign schedules",function()
  local a,n=setup()
  local foreign=n:AddTurnIntoWind(500,100,15,true,0)
  a:CarrierTurnIntoWind(120,10,true) local owned=a.manualWindWindow n.vetoEnd=true
  owned.Maneuver=n:BeginIntoWind({DeckWind=20})
  n.timedCurrent=owned
  a.state="Stopped" a:onafterStop("Idle","Stop","Stopped")
  assert(owned.Over) equal(a.manualWindWindow,nil)
  equal(n.ended[1].options.Resume,false)
  equal(n.plans[1],foreign) equal(#n.plans,1) assert(n.running)
end)

test("deleting a prepared future window ends its maneuver before selecting another",function()
  local a,n=setup() local w=window(a,100,200)
  at(0,a) assert(n.current)
  a:DeleteRecoveryWindow(w)
  assert(w.OVER and not n.current) equal(#a.recoverytimes,0)
end)

test("deleting an active recovery respects a RecoveryStop veto",function()
  local a,n=setup() local w=window(a,10,20)
  at(0,a) at(10,a) local m=n.current a.vetoStop=true
  a:DeleteRecoveryWindow(w)
  equal(a.activeRecoveryWindow,w) equal(n.current,m) assert(not w.OVER)
end)

test("schedule edits inside a veto callback do not repeat the same start attempt",function()
  local a,n=setup() local w=window(a,10,20)
  at(0,a)
  a.beforeStart=function(self)
    window(self,100,200)
    self:_CheckRecoveryTimes()
    return false
  end
  at(10,a)
  equal(a.startAttempts,1) equal(#a.recoverytimes,2)
  assert(not w.OPEN and a:IsIdle())
end)

test("a recovery deleted by its start callback cannot become active afterward",function()
  local a,n=setup() local w=window(a,10,20)
  at(0,a)
  a.beforeStart=function(self,case,offset,recovery)
    self:DeleteRecoveryWindow(recovery)
    return true
  end
  at(10,a)
  assert(w.OVER and not w.OPEN,"deleted window was reopened")
  equal(a.activeRecoveryWindow,nil) equal(n.current,nil)
  assert(a:IsIdle())
end)

test("Stop during NAVY acceptance aborts the just-created maneuver",function()
  local a,n=setup() window(a,10,20)
  local begin=n.BeginIntoWind
  n.BeginIntoWind=function(self,options)
    local m,reason=begin(self,options)
    a.state="Stopped" a:onafterStop("Idle","Stop","Stopped")
    return m,reason
  end
  at(0,a)
  equal(n.current,nil) equal(a.recoveryManeuver,nil) assert(a:is("Stopped"))
  equal(n.ended[1].options.Resume,false)
end)

test("Stop inside a recovery-start callback cannot be overwritten by the FSM",function()
  local a,n=setup() window(a,10,20)
  at(0,a)
  a.beforeStart=function(self)
    self.state="Stopped" self:onafterStop("Idle","Stop","Stopped")
    return true
  end
  at(10,a)
  assert(a:is("Stopped")) equal(n.current,nil) equal(a.activeRecoveryWindow,nil)
end)

test("Stop inside a recovery-stop callback cannot open the next recovery",function()
  local a,n=setup() window(a,10,20) local nextwindow=window(a,20,40)
  at(0,a) at(10,a)
  a.beforeStop=function(self)
    self.state="Stopped" self:onafterStop("Recovering","Stop","Stopped")
    return true
  end
  at(20,a)
  assert(a:is("Stopped")) equal(n.current,nil)
  assert(not nextwindow.OPEN) equal(a.activeRecoveryWindow,nil)
end)

test("a previous pause timer cannot resume a more recent pause",function()
  local a=setup() window(a,10,1000)
  at(10,a) pause(a,20) local first=a.scheduled[1]
  a:RecoveryUnpause() pause(a,50)
  first() assert(a:IsPaused())
  a.scheduled[2]() assert(a:IsRecovering())
end)

test("a normal course change blocks windless recovery admissions",function()
  local a,n=setup() window(a,10,1000,{wind=false})
  at(10,a) local f=flight(a,true) n.turning=true
  a:_ClearForLanding(f) equal(#a.landings,0)
  n.turning=false a:_ClearForLanding(f) equal(a.landings[1],f)
end)

test("windless recovery still rejects stopped, held or blocked navigation",function()
  local cases={
    {name="stopped",set=function(n) n.running=false end},
    {name="holding",set=function(n) n.holding=true end},
    {name="waiting",set=function(n) n.waiting=true end},
    {name="collision warning",set=function(n) n.collisionwarning=true end},
  }
  for _,case in ipairs(cases) do
    local a,n=setup() window(a,10,1000,{wind=false}) at(10,a)
    local f=flight(a,true) case.set(n)
    assert(not a:_CanClearForRecovery(false),case.name.." accepted as ready")
    a:_ClearForLanding(f)
    equal(#a.landings,0,case.name) equal(a.Qmarshal[1],f,case.name)
  end
end)

test("windless recovery rejects a lost carrier even while its escorts survive",function()
  local a,n=setup() window(a,10,1000,{wind=false}) at(10,a)
  local f=flight(a,true)
  a.carrier.IsAlive=function() return false end
  assert(n:IsAlive()) assert(not a:_CanClearForRecovery(false))
  a:_ClearForLanding(f) equal(#a.landings,0) equal(a.Qmarshal[1],f)
  a.carrier.IsAlive=function() return true end n.alive=false
  assert(not a:_CanClearForRecovery(false))
end)

test("nice mode still permits ordinary idle player recovery when navigation is clear",function()
  local a=setup() local f=flight(a,false) a.airbossnice=true
  a:_RequestCommence(f.unitname) equal(f.initializations,1)
end)

test("AI admission waits for NAVY readiness and stops again on a course change",function()
  local a,n=setup() window(a,10,1000)
  at(0,a) at(10,a) local f=flight(a,true)
  a:_CheckQueue() equal(#a.landings,0)
  n.current.Ready=true a:_CheckQueue() equal(a.landings[1],f)
  equal(a.clearances[1].case,1)
  local second=flight(a,true) n.current.Ready=false
  a:_ClearForLanding(second) equal(#a.landings,1)
end)

test("automatic player commence obeys readiness even after an earlier clearance",function()
  local a,n=setup() window(a,10,1000)
  at(0,a) at(10,a) local f=flight(a,false)
  f.step=AIRBOSS.PatternStep.COMMENCING
  a:_Commencing(f,true) equal(f.initializations,nil)
  n.current.Ready=true a:_Commencing(f,true)
  equal(f.initializations,1) equal(f.step,AIRBOSS.PatternStep.INITIAL)
end)

test("F10 commence and nice mode cannot bypass paused or unready navigation",function()
  local a,n=setup() window(a,10,1000)
  at(0,a) at(10,a) local f=flight(a,false) a.airbossnice=true
  a:_RequestCommence(f.unitname) equal(f.initializations,nil)
  n.current.Ready=true pause(a)
  a:_RequestCommence(f.unitname) equal(f.initializations,nil)
  a:RecoveryUnpause() a:_RequestCommence(f.unitname)
  equal(f.initializations,1)
end)

test("stopped and paused AIRBOSS reject direct commence without moving queue entries",function()
  for _,state in ipairs({"Stopped","Paused"}) do
    local a=setup() local f=flight(a,false) a.state=state a.airbossnice=true
    a:_Commencing(f,false)
    equal(f.initializations,nil) equal(a.Qmarshal[1],f) equal(#a.Qpattern,0)
  end
end)

test("CASE I to III synchronizes waiting flights but preserves an active pattern",function()
  local a=setup() a.state="Recovering"
  local queued=flight(a,true,1)
  local pattern=flight(a,true,1) remove(a.Qmarshal,pattern) a.Qpattern[1]=pattern
  a:RecoveryCase(3,20)
  a:_CheckQueue()
  equal(queued.case,3) equal(pattern.case,1)
  assert(#a.restacked>0)
end)

test("CASE II to III updates approach case without rebuilding an unchanged stack",function()
  local a=setup() a.state="Recovering" a.case=2
  local f=flight(a,true,2) local stack,time=f.flag,f.time
  a:RecoveryCase(3,0)
  a:_CheckQueue()
  equal(f.case,3) equal(f.flag,stack) equal(f.time,time)
  equal(#a.restacked,0) equal(a.clearances[1].case,3)
end)

print(string.format("AIRBOSS recovery: %d passed, %d failed",passed,failed))
if failed>0 then os.exit(1) end
