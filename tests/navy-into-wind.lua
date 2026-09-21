-- Standalone NAVYGROUP maneuver/schedule regressions. Run from the repository root with Lua 5.1 or 5.4.
-- Loads the production class with DCS telemetry, route execution and terrain doubles.
-- Scheduling regressions additionally use production FSM delay registration and callback dispatch.
local now=0
timer={getAbsTime=function() return now end,getTime=function() return now end}
env={info=function() end,error=function() end}
unpack=unpack or table.unpack
UTILS={}
function UTILS.KnotsToMps(n) return n*1852/3600 end
function UTILS.MpsToKnots(n) return n*3600/1852 end
function UTILS.KnotsToKmph(n) return n*1.852 end
function UTILS.KmphToKnots(n) return n/1.852 end
function UTILS.KmphToMps(n) return n/3.6 end
function UTILS.MpsToKmph(n) return n*3.6 end
function UTILS.NMToMeters(n) return n*1852 end
function UTILS.FeetToMeters(n) return n*0.3048 end
function UTILS.VecNorm(v) return math.sqrt(v.x*v.x+v.y*v.y+v.z*v.z) end
function UTILS.VecHdg(v)
  local radians=math.atan2 and math.atan2(v.z,v.x) or math.atan(v.z,v.x)
  return math.deg(radians)%360
end
function UTILS.SecondsToClock(n) return tostring(n) end
function UTILS.ClockToSeconds(n) return tonumber(n) end
function UTILS.DeepCopy(v)
  if type(v)~="table" then return v end
  local copy={} for k,item in pairs(v) do copy[k]=UTILS.DeepCopy(item) end
  return setmetatable(copy,getmetatable(v))
end
COORDINATE={}
function COORDINATE:New(x,y,z) return setmetatable({x=x or 0,y=y or 0,z=z or 0},{__index=self}) end
function COORDINATE:NewFromCoordinate(p) return self:New(p.x,p.y,p.z) end
function COORDINATE:NewFromVec3(p) return self:New(p.x,p.y,p.z) end
function COORDINATE:GetVec3() return {x=self.x,y=self.y,z=self.z} end
function COORDINATE:Translate(d,h) return self:New(self.x+d*math.cos(math.rad(h)),self.y,self.z+d*math.sin(math.rad(h))) end
function COORDINATE:GetWind() return self.windFrom or 90,self.windSpeed or UTILS.KnotsToMps(10) end
function COORDINATE:Get2DDistance(p) return math.sqrt((self.x-p.x)^2+(self.z-p.z)^2) end
function COORDINATE:GetDistance(p) return self:Get2DDistance(p) end
function COORDINATE:IsInstanceOf(name) return name=="COORDINATE" end
function COORDINATE:WaypointNaval(speed,depth) return {x=self.x,y=self.z,alt=depth or 0,speed=(speed or 0)/3.6} end
land={getHeight=function() return 0 end}
atmosphere={getWind=function() return {x=0,y=0,z=-UTILS.KnotsToMps(10)} end}
dofile("Moose Development/Moose/Core/Vector.lua")
dofile("Moose Development/Moose/Ops/NavyGroup.lua")

local function unit(heading,speed,x)
  local u={heading=heading or 0,speed=speed or 0,alive=true,position=COORDINATE:New(x or 0,0,0)}
  function u:IsAlive() return self.alive end
  function u:IsInstanceOf(name) return name=="UNIT" end
  function u:GetHeading() return self.heading end
  function u:GetVelocityKNOTS() return self.speed end
  function u:GetVelocityMPS() return UTILS.KnotsToMps(self.speed) end
  function u:GetVelocity() return UTILS.KnotsToMps(self.speed) end
  function u:GetCoordinate() return self.position end
  function u:GetVector() return VECTOR:New(self.position.x,self.position.y,self.position.z) end
  function u:GetGroup() return self.group end
  function u:GetName() return "Reference carrier" end
  return u
end
local function navy()
  local n=setmetatable({lid="Test | ",Qintowind={},intowindcounter=0,intoWindCounter=0,
    currentwp=1,waypoints={},speedMax=UTILS.KnotsToKmph(30),state="Cruising",taskcurrent=0,isAI=true,
    position=COORDINATE:New(0,0,0),heading=0,velocity=0,turning=false,pathfindingOn=false,
    updates=0,checks=0,queued={},logs={},waypointCounter=2,verbose=0,speedCruise=22.224},{__index=NAVYGROUP})
  n.reference=unit(0,0)
  n.group={}
  n.reference.group=n.group
  function n.group:IsAlive() return true end
  function n.group:GetUnit() return n.reference end
  function n.group:GetName() return "Carrier Group" end
  function n.group:GetVelocityKNOTS() return n.reference.speed end
  function n:Is(s) return self.state==s end
  n.is=n.Is
  function n:GetState() return self.state end
  function n:IsAlive() return not self.dead end
  function n:IsDead() return self.dead==true end
  function n:IsStopped() return self.state=="Stopped" end
  function n:IsWaiting() return self.state=="Waiting" end
  function n:IsInUtero() return false end
  function n:IsEngaging() return self.engaging==true end
  function n:GetHeading() return self.heading end
  function n:GetVelocity() return self.velocity end
  function n:GetSpeedCruise() return 12 end
  function n:GetCoordinate() return COORDINATE:NewFromCoordinate(self.position) end
  function n:T() end
  n.T2=n.T n.T3=n.T
  function n:E(message) self.logs[#self.logs+1]=message end
  function n:GetWaypointCurrent() return self.waypoints[self.currentwp] end
  function n:GetWaypointIndexNext() return math.min(self.currentwp+1,#self.waypoints) end
  function n:GetWaypointNext() return self.waypoints[self:GetWaypointIndexNext()] end
  function n:GetSpeedToWaypoint() return 12 end
  function n:GetWaypointIndex(id)
    for i,wp in ipairs(self.waypoints) do if wp.uid==id then return i end end
  end
  function n:AddWaypoint(p,speed,after,depth,update)
    self.waypointCounter=self.waypointCounter+1
    local wp={uid=self.waypointCounter,coordinate=COORDINATE:NewFromCoordinate(p),speed=UTILS.KnotsToMps(speed or 12)}
    local i=after and self:GetWaypointIndex(after) or #self.waypoints
    table.insert(self.waypoints,(i or #self.waypoints)+1,wp)
    if update~=false then self:__UpdateRoute(-0.01) end
    return wp
  end
  function n:RemoveWaypointByID(id)
    local i=self:GetWaypointIndex(id)
    if i then table.remove(self.waypoints,i); if i<self.currentwp then self.currentwp=self.currentwp-1 end end
  end
  function n:_ClearPathfindingDrawing() end
  function n:_FindPathToNextWaypoint()
    self.checks=self.checks+1
    self.checkedBeforeUpdate=self.updates
    if self.pathBlocked then self.pathfindingStopped=true; self:FullStop(); return false end
    self.pathfindingStopped=nil
    if self.intoWindManeuver then self.intoWindManeuver.PathValidated=true end
    self:__UpdateRoute(-0.01)
    return true
  end
  function n:Route(route)
    self.updates=self.updates+1
    self.lastRoute=route
  end
  function n:UpdateRoute(...)
    if self.blockRoute then return false end
    if self:onbeforeUpdateRoute(self.state,"UpdateRoute",self.state,...)==false then return false end
    self:onafterUpdateRoute(self.state,"UpdateRoute",self.state,...)
    return true
  end
  function n:__UpdateRoute(delay,...) return self:UpdateRoute(...) end
  function n:Cruise() self.state="Cruising"; self:__UpdateRoute(-0.01) end
  function n:FullStop() self.state="Holding" end
  function n:ScheduleOnce(delay,fn,...)
    local args={...}; local task={at=now+delay,run=function() fn(unpack(args)) end}
    self.queued[#self.queued+1]=task
    return #self.queued
  end
  function n:Flush()
    local queued=self.queued; self.queued={}
    for _,task in ipairs(queued) do now=math.max(now,task.at); task.run() end
  end
  -- FSM transition side effects only. Production event handlers perform all schedule/maneuver work.
  for _,event in ipairs({"TurnIntoWind","TurnIntoWindStop","TurnIntoWindOver","TurnedIntoWind"}) do
    n[event]=function(self,...)
      local from=self.state
      for _,prefix in ipairs({"onbefore","OnBefore"}) do
        local callback=self[prefix..event]
        if callback and callback(self,from,event,event=="TurnIntoWind" and "Cruising" or from,...)==false then return false end
      end
      if event=="TurnIntoWind" then self.state="Cruising" end
      for _,prefix in ipairs({"onafter","OnAfter"}) do
        local callback=self[prefix..event]
        if callback then callback(self,from,event,self.state,...) end
      end
    end
  end
  n.waypoints={{uid=1,coordinate=COORDINATE:New(0,0,0),speed=UTILS.KnotsToMps(12)},
    {uid=2,coordinate=COORDINATE:New(50000,0,0),speed=UTILS.KnotsToMps(12)}}
  return n
end

local passed,failed=0,0
local function equal(a,b) assert(a==b,"expected "..tostring(b)..", got "..tostring(a)) end
local function near(a,b) assert(math.abs(a-b)<1e-6,"expected "..tostring(b)..", got "..tostring(a)) end
local function test(name,fn)
  now=0
  local ok,reason=pcall(fn)
  if ok then passed=passed+1; print("PASS "..name)
  else failed=failed+1; print("FAIL "..name..": "..tostring(reason)) end
end
local function begin(n,options)
  options=options or {DeckWind=27,DeckAngle=-9.1,ReferenceUnit=n.reference}
  local m,reason=n:BeginIntoWind(options)
  assert(m,reason)
  n:Flush()
  return m
end

test("direct maneuver has no duplicate schedule or deadline",function()
  local n=navy(); local m=begin(n)
  equal(#n.Qintowind,0); equal(n:GetTurnIntoWindCurrent(),nil)
  equal(n:GetIntoWindManeuver(),m); equal(m.Tstop,nil); equal(m.Tstart,nil)
  now=100000; n:_CheckTurnsIntoWind(); equal(n:GetIntoWindManeuver(),m)
end)

test("busy and foreign handles cannot replace or stop a live maneuver",function()
  local a,b=navy(),navy(); local ma,mb=begin(a),begin(b)
  local another,reason=a:BeginIntoWind({DeckWind=25})
  equal(another,nil); equal(reason,"busy")
  equal(a:EndIntoWind(mb),false); equal(a:UpdateIntoWind(mb,{DeckWind=20}),nil)
  equal(a:GetIntoWindManeuver(),ma); equal(b:GetIntoWindManeuver(),mb)
end)

test("completion is idempotent and cannot clear a callback-created successor",function()
  local n=navy(); local calls=0; local successor
  local m=begin(n,{DeckWind=27,DeckAngle=-9.1,OnEnded=function(ended,reason)
    calls=calls+1; equal(ended.State,"Ended"); equal(n:GetIntoWindManeuver(),nil)
    successor=assert(n:BeginIntoWind({DeckWind=20,DeckAngle=0}))
  end})
  equal(n:EndIntoWind(m,{Uturn=false}),true)
  equal(calls,1); equal(n:GetIntoWindManeuver(),successor)
  equal(n:EndIntoWind(m),true); equal(n:AbortIntoWind(m),true)
  n:Flush(); equal(calls,1); equal(n:GetIntoWindManeuver(),successor)
end)

test("final return choice keeps the first significant departure point",function()
  local n=navy(); local m=begin(n)
  local departure=COORDINATE:NewFromCoordinate(m.DepartureCoordinate)
  n.position=COORDINATE:New(10000,0,5000)
  equal(n:UpdateIntoWind(m,{DeckWind=30}),m)
  near(m.DepartureCoordinate.x,departure.x); near(m.DepartureCoordinate.z,departure.z)
  equal(n:EndIntoWind(m,{Uturn=true}),true)
  local returned=false
  for _,wp in ipairs(n.waypoints) do
    if wp.uid>2 and wp.coordinate:Get2DDistance(departure)<1 then returned=true end
  end
  assert(returned,"No return waypoint to the original departure")
end)

test("disabled final U-turn leaves only the regular route",function()
  local n=navy(); local m=begin(n)
  equal(n:EndIntoWind(m,{Uturn=false}),true)
  equal(#n.waypoints,2); equal(n:GetIntoWindManeuver(),nil)
end)

test("explicit return coordinate is honored even without a significant turn",function()
  local n=navy(); n.heading=90; n.reference.heading=90
  local m=begin(n,{DeckWind=20,DeckAngle=0,ReferenceUnit=n.reference})
  local destination=COORDINATE:New(800,0,900)
  equal(n:EndIntoWind(m,{ReturnCoordinate=destination}),true)
  local found=false
  for _,wp in ipairs(n.waypoints) do if wp.uid>2 and wp.coordinate:Get2DDistance(destination)<1 then found=true end end
  assert(found,"Explicit return coordinate ignored")
end)

test("pathfinding validates a wind route before route submission",function()
  local n=navy(); n.pathfindingOn=true; local m=begin(n)
  assert(n.checks>0,"No path validation before initial maneuver")
  equal(n.checkedBeforeUpdate,0)
  local checks=n.checks
  equal(n:UpdateIntoWind(m,{DeckWind=29}),m)
  n:Flush(); assert(n.checks>checks,"Updated wind route bypassed planning")
end)

test("blocked path cannot be reported ready and abort removes its waypoint",function()
  local n=navy(); n.pathfindingOn=true; n.pathBlocked=true; local m=begin(n)
  equal(m.Ready,false); equal(n.updates,0)
  equal(n:AbortIntoWind(m,{Uturn=false,Reason="owner_stopped"}),true)
  equal(n:GetIntoWindManeuver(),nil); equal(#n.waypoints,2)
end)

test("readiness uses selected carrier telemetry, not the lead escort",function()
  local n=navy(); local m=begin(n)
  n.heading=m.Heading; n.velocity=UTILS.KnotsToMps(m.ShipSpeed)
  equal(n:GetIntoWindManeuver().Ready,false)
  n.reference.heading=m.Heading; n.reference.speed=m.ShipSpeed
  now=30; n:GetIntoWindManeuver(); now=60
  equal(n:GetIntoWindManeuver().Ready,true)
  n.reference.heading=(m.Heading+20)%360
  equal(n:GetIntoWindManeuver().Ready,false)
end)

test("scheduled facade keeps record identity and only extends its own deadline",function()
  local n=navy(); local w=assert(n:AddTurnIntoWind(10,20,27,true,-9.1))
  equal(w.Tstart,10); equal(w.Tstop,30); equal(n:GetIntoWindManeuver(),nil)
  now=10; n:_CheckTurnsIntoWind(); n:Flush()
  local m=n:GetIntoWindManeuver(); assert(m)
  equal(n:GetTurnIntoWindCurrent(),w); equal(w.Maneuver,m)
  n:ExtendTurnIntoWind(10,w); equal(w.Tstop,40); equal(m.Tstop,nil)
  now=35; n:_CheckTurnsIntoWind(); equal(n:GetIntoWindManeuver(),m)
  now=40; n:_CheckTurnsIntoWind(); equal(n:GetIntoWindManeuver(),nil); equal(#n.Qintowind,0)
end)

test("waiting timed request expires without stealing a direct maneuver",function()
  local n=navy(); local m=begin(n); local w=n:AddTurnIntoWind(0,10,20)
  n:_CheckTurnsIntoWind(); equal(n:GetIntoWindManeuver(),m); equal(w.Open,false)
  now=20; n:_CheckTurnsIntoWind(); equal(n:GetIntoWindManeuver(),m); equal(#n.Qintowind,0)
end)

test("legacy stop veto keeps ownership and forced removal still cleans up",function()
  local n=navy(); local w=n:AddTurnIntoWind(0,20,25)
  n:_CheckTurnsIntoWind(); n:Flush(); local m=n:GetIntoWindManeuver()
  function n:OnBeforeTurnIntoWindStop() return false end
  n:RemoveTurnIntoWind(w); equal(n:GetIntoWindManeuver(),m); equal(n:GetTurnIntoWindCurrent(),w)
  n:RemoveTurnIntoWind(w,true); equal(n:GetIntoWindManeuver(),nil); equal(#n.Qintowind,0)
end)

test("removing a future window cannot stop someone else's active maneuver",function()
  local n=navy(); local m=begin(n); local w=n:AddTurnIntoWind(100,20,25)
  n:RemoveTurnIntoWind(w,true); equal(#n.Qintowind,0); equal(n:GetIntoWindManeuver(),m)
end)

test("rejected options leave no route or ownership behind",function()
  local n=navy()
  for _,value in ipairs({-1,math.huge,"27"}) do
    local m,reason=n:BeginIntoWind({DeckWind=value})
    equal(m,nil); equal(reason,"invalid_options"); equal(n:GetIntoWindManeuver(),nil)
    equal(#n.waypoints,2); equal(n.updates,0)
  end
  local m=begin(n); local waypoint=m.waypoint
  equal(n:UpdateIntoWind(m,{DeckAngle=math.huge}),nil)
  equal(m.waypoint,waypoint); equal(n:GetIntoWindManeuver(),m)
end)

test("delayed route revision cannot override a newer maneuver",function()
  local n=navy(); local m=begin(n); local old=m.RouteRevision
  n:EndIntoWind(m)
  local successor=begin(n); local updates=n.updates
  equal(n:UpdateRoute(nil,nil,1,nil,old),false)
  equal(n.updates,updates); equal(n:GetIntoWindManeuver(),successor)
end)

test("route rejected before submission is not ready despite aligned telemetry",function()
  local n=navy(); n.blockRoute=true; local m=begin(n)
  n.reference.heading=m.Heading; n.reference.speed=m.ShipSpeed
  equal(n:GetIntoWindManeuver().Ready,false); equal(m.BlockedReason,"route_pending")
  n.blockRoute=false; n:UpdateRoute(nil,nil,nil,nil,m.RouteRevision)
  equal(n:GetIntoWindManeuver().Ready,true)
end)

test("actual path planner validates and submits a rolling straight wind leg",function()
  local n=navy(); n.pathfindingOn=true
  n._FindPathToNextWaypoint=NAVYGROUP._FindPathToNextWaypoint
  function n:GetVec3() return self.position:GetVec3() end
  function n:_CheckPathDepth() return true end
  function n:_GetPathfindingCorridorWidth() return 200 end
  local m=begin(n)
  equal(m.PathValidated,true); equal(m.RouteSubmitted,true)
  local nextWaypoint=n:GetWaypointNext()
  equal(nextWaypoint.astarReplan,true); equal(nextWaypoint.astarTargetUID,m.waypoint.uid)
  near(nextWaypoint.coordinate:Get2DDistance(n.position),UTILS.NMToMeters(20))
  n.reference.heading=m.Heading; n.reference.speed=m.ShipSpeed
  equal(n:GetIntoWindManeuver().Ready,true)
  n.LastPathfindingResult.StopReason="detour"
  equal(n:GetIntoWindManeuver().Ready,false); equal(m.BlockedReason,"route_diversion")
  n:EndIntoWind(m); equal(#n.waypoints,2)
end)

test("legacy speed above ship capability is limited and can become ready",function()
  local n=navy(); n.intowindold=true
  local m=begin(n,{DeckWind=70,DeckAngle=-9.1,ReferenceUnit=n.reference})
  near(m.ShipSpeed,30); equal(m.SpeedLimited,true)
  n.reference.heading=m.Heading; n.reference.speed=30
  equal(n:GetIntoWindManeuver().Ready,true)
end)

test("dead selected carrier never becomes ready through surviving escorts",function()
  local n=navy(); local m=begin(n)
  n.reference.heading=m.Heading; n.reference.speed=m.ShipSpeed
  equal(n:GetIntoWindManeuver().Ready,true)
  n.reference.alive=false
  equal(n:GetIntoWindManeuver().Ready,false); equal(m.BlockedReason,"reference_unavailable")
  equal(n:AbortIntoWind(m),true); equal(n:GetIntoWindManeuver(),nil)
end)

test("removal in timed start callback cannot reopen the expired request",function()
  local n=navy(); local w=n:AddTurnIntoWind(0,20,25)
  function n:OnBeforeTurnIntoWind(from,event,to,window) self:RemoveTurnIntoWind(window,true) end
  n:_CheckTurnsIntoWind()
  equal(n:GetIntoWindManeuver(),nil); equal(w.Open,false); equal(w.Over,true)
end)

test("competing engagement or task rejects acquisition without changing its route",function()
  local n=navy(); n.engaging=true
  local m,reason=n:BeginIntoWind({DeckWind=20})
  equal(m,nil); equal(reason,"busy"); equal(n.updates,0); equal(#n.waypoints,2)
  n.engaging=false; n.taskcurrent=7
  m,reason=n:BeginIntoWind({DeckWind=20})
  equal(m,nil); equal(reason,"busy"); equal(n.updates,0)
  n.taskcurrent=0; m=begin(n); n.engaging=true
  local updates=n.updates; local oldWaypoint=m.waypoint
  local updated,blocked=n:UpdateIntoWind(m,{DeckWind=29})
  equal(updated,nil); equal(blocked,"busy"); equal(m.waypoint,oldWaypoint)
  equal(n:GetIntoWindManeuver().Ready,false); equal(m.BlockedReason,"task_override")
  equal(n:AbortIntoWind(m),true); equal(n.updates,updates)
end)

-- Exercise real FSM delay coalescing and before/after callbacks. Immediate dispatch doubles
-- cannot expose a new revision being suppressed behind an older pending UpdateRoute event.
dofile("Moose Development/Moose/Core/Fsm.lua")

local function scheduledNavy(pathfinding)

  local n=navy()
  local errors={}

  n.pathfindingOn=pathfinding==true
  n.current=n.state
  n._EventSchedules={}
  n._handler=FSM._handler
  n._call_handler=FSM._call_handler
  n.UpdateRoute=FSM._create_transition(n,"UpdateRoute")
  n.__UpdateRoute=FSM._delayed_transition(n,"UpdateRoute")

  -- This fixture only dispatches the state-preserving UpdateRoute event through FSM.
  function n:can() return true,self.current end
  function n:_gosub() return {} end
  function n:_isendstate() return nil end

  BASE={Debug=debug}
  env.info=function(message)
    if message:find("Error in SCHEDULER function:",1,true) then
      errors[#errors+1]=message
    end
  end

  -- Model the DCS clock while retaining production FSM event registration and arguments.
  n.CallScheduler={tasks={},nextID=0}

  function n.CallScheduler:Schedule(owner,callback,args,delay)
    self.nextID=self.nextID+1
    self.tasks[self.nextID]={owner=owner,callback=callback,args=args,at=now+delay}
    return self.nextID
  end

  function n.CallScheduler:Remove(id)
    self.tasks[id]=nil
  end

  function n.CallScheduler:Clear()
    self.tasks={}
  end

  function n:Flush()
    local executed=0

    while next(self.CallScheduler.tasks) do
      local selected
      local task

      for id,candidate in pairs(self.CallScheduler.tasks) do
        if not task or candidate.at<task.at or (candidate.at==task.at and id<selected) then
          selected=id
          task=candidate
        end
      end

      self.CallScheduler:Remove(selected)
      now=math.max(now,task.at)
      task.callback(task.owner,unpack(task.args))

      executed=executed+1
      assert(executed<100,"Unexpected route scheduling loop")
      assert(#errors==0,table.concat(errors,"\n"))
    end
  end

  function n:Cruise(Speed)
    local from=self.state
    self.state="Cruising"
    self.current=self.state
    self:onafterCruise(from,"Cruise",self.state,Speed)
  end

  -- Use the actual rolling planner with a clear-water terrain result.
  n._FindPathToNextWaypoint=NAVYGROUP._FindPathToNextWaypoint
  function n:GetVec3() return self.position:GetVec3() end
  function n:_CheckPathDepth() return true end
  function n:_GetPathfindingCorridorWidth() return 200 end

  return n
end

test("real FSM preserves latest rolling route across rapid wind updates",function()
  local n=scheduledNavy(true)
  local m=assert(n:BeginIntoWind({DeckWind=27,DeckAngle=-9.1,ReferenceUnit=n.reference}))

  assert(n:UpdateIntoWind(m,{DeckWind=29}))
  assert(n:UpdateIntoWind(m,{DeckWind=30}))
  equal(n.updates,0)
  equal(m.RouteSubmitted,false)

  n:Flush()

  equal(n.updates,1)
  equal(m.RouteSubmitted,true)
  near(n.lastRoute[#n.lastRoute].speed,UTILS.KnotsToMps(m.ShipSpeed))
  equal(n.lastRoute[#n.lastRoute].astarTargetUID,m.waypoint.uid)

  n.reference.heading=m.Heading
  n.reference.speed=m.ShipSpeed
  equal(n:GetIntoWindManeuver().Ready,true)
end)

test("real FSM preserves latest cruise when wind restarts from holding",function()
  local n=scheduledNavy(false)
  n.state="Holding"
  n.current=n.state
  local m=assert(n:BeginIntoWind({DeckWind=27,DeckAngle=-9.1}))

  n:FullStop()
  assert(n:UpdateIntoWind(m,{DeckWind=30}))
  equal(n.updates,0)

  n:Flush()

  equal(n.updates,1)
  equal(m.RouteSubmitted,true)
  equal(n.lastRoute[2].uid,m.waypoint.uid)
  near(n.lastRoute[2].speed,UTILS.KnotsToMps(m.ShipSpeed))
end)

test("real FSM rejects an old cruise speed after a wind maneuver begins",function()
  local n=scheduledNavy(true)
  n:Cruise(5)
  local m=assert(n:BeginIntoWind({DeckWind=27,DeckAngle=-9.1}))

  n:Flush()

  equal(n.updates,1)
  equal(m.RouteSubmitted,true)
  near(n.lastRoute[#n.lastRoute].speed,UTILS.KnotsToMps(m.ShipSpeed))
end)

test("real FSM submits regular route when wind ends before pending update",function()
  local n=scheduledNavy(true)
  local m=assert(n:BeginIntoWind({DeckWind=27,DeckAngle=-9.1}))
  assert(n:EndIntoWind(m,{Uturn=false}))

  n:Flush()

  equal(n.updates,1)
  equal(n:GetIntoWindManeuver(),nil)
  equal(#n.waypoints,2)
  equal(n.lastRoute[#n.lastRoute].uid,2)
  near(n.lastRoute[#n.lastRoute].speed,UTILS.KnotsToMps(12))
end)

test("real FSM rechecks a revision changed by a user callback",function()
  local n=scheduledNavy(true)
  local m=assert(n:BeginIntoWind({DeckWind=27,DeckAngle=-9.1}))
  local replaced=false

  function n:OnBeforeUpdateRoute()
    if not replaced then
      replaced=true
      assert(self:UpdateIntoWind(m,{DeckWind=30}))
    end
  end

  n:Flush()

  equal(replaced,true)
  equal(n.updates,1)
  equal(m.RouteSubmitted,true)
  near(n.lastRoute[#n.lastRoute].speed,UTILS.KnotsToMps(m.ShipSpeed))
end)

test("scheduled wind route respects holding and scheduler shutdown",function()
  local n=scheduledNavy(true)
  assert(n:BeginIntoWind({DeckWind=27,DeckAngle=-9.1}))
  n:FullStop()
  n:Flush()
  equal(n.updates,0)

  n=scheduledNavy(true)
  assert(n:BeginIntoWind({DeckWind=27,DeckAngle=-9.1}))

  -- OPSGROUP Stop clears this same scheduler for both positive and negative delayed events.
  n.CallScheduler:Clear()
  n:Flush()
  equal(n.updates,0)
end)

print(string.format("%d passed, %d failed",passed,failed))
if failed>0 then os.exit(1) end
