-- Standalone LOCAL naval navigation regressions; run from the repository root:
-- lua tests/navy-local.lua
-- Imports production methods and actual GRID/ASTAR/PATHLINE; only DCS/FSM effects are stubbed.
-- Compatible with the Lua 5.1 runtime used by DCS and Lua 5.4.
unpack=unpack or table.unpack
local function deepcopy(value)
  if type(value)~="table" then return value end
  local result={}
  for key,item in pairs(value) do result[key]=deepcopy(item) end
  return setmetatable(result,getmetatable(value))
end
BASE={}
function BASE:New() return setmetatable({},{__index=self}) end
function BASE:Inherit(child,parent) return setmetatable(deepcopy(child),{__index=parent}) end
function BASE:T() end
function BASE:T2() end
function BASE:E() end
local timerNow=0
timer={getTime=function() return timerNow end,getAbsTime=function() return timerNow end}
function timer.scheduleFunction() error("LOCAL navigation must not create a retry timer") end
function timer.removeFunction() end
MESSAGE={New=function() return {ToAllIf=function() end} end}
land={SurfaceType={LAND=1,SHALLOW_WATER=2,WATER=3}}
function land.getSurfaceType(point)
  return land.surfaceAt and land.surfaceAt({x=point.x,y=0,z=point.y}) or land.SurfaceType.WATER
end
local function atan2(y,x)
  if x>0 then return math.atan(y/x) end
  if x<0 then return math.atan(y/x)+(y>=0 and math.pi or -math.pi) end
  return y>0 and math.pi/2 or (y<0 and -math.pi/2 or 0)
end
math.atan2=math.atan2 or atan2
COORDINATE={ClassName="COORDINATE"}
function COORDINATE:New(x,y,z) return setmetatable({x=x,y=y,z=z},{__index=self}) end
function COORDINATE:NewFromVec3(value) return self:New(value.x,value.y,value.z) end
function COORDINATE:GetVec3() return {x=self.x,y=self.y,z=self.z} end
function COORDINATE:Get2DDistance(other) return math.sqrt((self.x-other.x)^2+(self.z-other.z)^2) end
function COORDINATE:Get3DDistance(other) return math.sqrt(self:Get2DDistance(other)^2+(self.y-other.y)^2) end
function COORDINATE:HeadingTo(other) return math.deg(atan2(other.z-self.z,other.x-self.x)) end
function COORDINATE:Translate(distance,heading)
  local angle=math.rad(heading)
  return self:New(self.x+distance*math.cos(angle),self.y,self.z+distance*math.sin(angle))
end
function COORDINATE:WaypointNaval(speed,depth)
  return {x=self.x,y=self.z,alt=depth or 0,speed=speed/3.6,type="Turning Point",action="Turning Point"}
end
UTILS={GetOSTime=function() return 0 end,DeepCopy=deepcopy}
function UTILS.VecDist2D(a,b) return math.sqrt((a.x-b.x)^2+(a.y-b.y)^2) end
function UTILS.Rotate2D(v,heading)
  local angle=math.rad(heading)
  return {x=v.x*math.cos(angle)+v.z*math.sin(angle),y=v.y,z=v.z*math.cos(angle)-v.x*math.sin(angle)}
end
function UTILS.VecTranslate(v,distance,heading)
  local angle=math.rad(heading)
  return {x=v.x+distance*math.cos(angle),y=v.y,z=v.z+distance*math.sin(angle)}
end
function UTILS.AdjustHeading360(heading) return heading%360 end
function UTILS.NMToMeters(value) return value*1852 end
function UTILS.MpsToKnots(value) return value*1.9438444924 end
function UTILS.KnotsToMps(value) return value/1.9438444924 end
function UTILS.MpsToKmph(value) return value*3.6 end
function UTILS.KmphToMps(value) return value/3.6 end
local function coord(x,z,y) return COORDINATE:New(x,y or 0,z or 0) end
dofile("Moose Development/Moose/Core/Vector.lua")
dofile("Moose Development/Moose/Core/Pathline.lua")
dofile("Moose Development/Moose/Core/Grid.lua")
dofile("Moose Development/Moose/Core/Astar.lua")
local utilsFile=assert(io.open("Moose Development/Moose/Utilities/Utils.lua","r"))
local utilsSource=utilsFile:read("*a"):gsub("\r\n","\n") utilsFile:close()
assert((loadstring or load)(assert(utilsSource:match("(function UTILS%.VecWaypointNaval%b().-\nend)"))))()

local navyFile=assert(io.open("Moose Development/Moose/Ops/NavyGroup.lua","r"))
local navySource=navyFile:read("*a"):gsub("\r\n","\n") navyFile:close()
NAVYGROUP={}
local enum=navySource:match("NAVYGROUP%.PathfindingMode%s*=%s*%b{}")
assert(enum,"Production NAVYGROUP.PathfindingMode enum is missing")
assert((loadstring or load)(enum))()
-- The files depend on the full DCS environment at top level; extract the actual method bodies.
for definition in navySource:gmatch("function NAVYGROUP[:%.][%w_]+%b().-\nend") do
  assert((loadstring or load)(definition))()
end
local opsFile=assert(io.open("Moose Development/Moose/Ops/OpsGroup.lua","r"))
local opsSource=opsFile:read("*a"):gsub("\r\n","\n") opsFile:close()
OPSGROUP={}
assert((loadstring or load)(assert(opsSource:match("(function OPSGROUP%._PassingWaypoint%b().-\nend)")) ))()
for _,name in ipairs({"TaskStatus","TaskType"}) do
  assert((loadstring or load)(assert(opsSource:match("OPSGROUP%."..name.."%s*=%s*%b{}"))))()
end
for _,name in ipairs({"CountTasksWaypoint","GetTasksWaypoint","_SortTaskQueue","_SetWaypointTasks","onafterPassingWaypoint"}) do
  assert((loadstring or load)(assert(opsSource:match("(function OPSGROUP:"..name.."%b().-\nend)"))))()
end
AUFTRAG={SpecialTask={PATROLZONE="PatrolZone",RECON="Recon",RELOCATECOHORT="RelocateCohort",REARMING="Rearming"}}

local passed,failed=0,0
local function equal(actual,expected)
  assert(actual==expected,"expected "..tostring(expected)..", got "..tostring(actual))
end
local function near(actual,expected,tolerance)
  assert(math.abs(actual-expected)<(tolerance or 1e-7),"expected approximately "..tostring(expected)..", got "..tostring(actual))
end
local function distance(a,b) return math.sqrt((a.x-b.x)^2+(a.z-b.z)^2) end
local function test(name,run)
  land.surfaceAt=nil timerNow=0
  local ok,err=pcall(run)
  if ok then passed=passed+1 print("PASS "..name)
  else failed=failed+1 print("FAIL "..name..": "..tostring(err)) end
end
local function vessel(targetDistance)
  local terrain={depth=40,height=0,queries=0,profiles=0}
  land.getSurfaceHeightWithSeabed=function(point)
    terrain.queries=terrain.queries+1
    return terrain.height,terrain.depthAt and terrain.depthAt(point) or terrain.depth
  end
  land.profile=function(a,b)
    terrain.profiles=terrain.profiles+1
    if terrain.makeProfile then return terrain.makeProfile(a,b) end
    local intervals=math.max(1,math.ceil(distance(a,b)/25))
    local profile={}
    for i=0,intervals do
      local x,z=a.x+(b.x-a.x)*i/intervals,a.z+(b.z-a.z)*i/intervals
      local depth=terrain.depthAt and terrain.depthAt({x=x,y=z}) or terrain.depth
      profile[#profile+1]={x=x,y=terrain.height-depth,z=z}
    end
    return profile
  end
  local ship=setmetatable({lid="LOCAL test ",verbose=0,pathCorridor=50,pathfindingOn=true,
    currentwp=1,state="Cruising",isAI=true,speed=10,speedCruise=36,speedWp=10,altWp=0,
    velocity=10,alive=true,position={x=0,y=0,z=0},heading=0,nextID=3,
    updates=0,stops=0,cruises=0,added=0,warnings=0,clears=0,dispatches={},taskqueue={},terrain=terrain},{__index=NAVYGROUP})
  ship.waypoints={
    {uid=1,coordinate=coord(0),x=0,y=0,speed=10,npassed=0},
    {uid=2,coordinate=coord(targetDistance or 20000),x=targetDistance or 20000,y=0,speed=10,npassed=0,
      task={id="ComboTask",params={tasks={{id="TargetAction"}}}}},
    {uid=3,coordinate=coord((targetDistance or 20000)+10000),x=(targetDistance or 20000)+10000,y=0,speed=15,npassed=0,
      task={id="ComboTask",params={tasks={{id="LaterAction"}}}}}}
  function ship:T() end
  function ship:T2() end
  function ship:T3() end
  function ship:I() end
  function ship:E() end
  function ship:IsTrace() return false end
  function ship:GetState() return self.state end
  function ship:IsAlive() return self.alive end
  function ship:IsWaiting() return self.Twaiting~=nil end
  function ship:IsHolding() return self.state=="Holding" end
  function ship:GetVelocity() return self.velocity end
  function ship:GetMissionCurrent() return self.mission end
  function ship:GetTaskByID(id) for _,task in ipairs(self.taskqueue) do if task.id==id then return task end end end
  function ship:GetTaskCurrent() return self.taskcurrent and self:GetTaskByID(self.taskcurrent) end
  function ship:GetMissionByTaskID() return nil end
  ship.CountTasksWaypoint=OPSGROUP.CountTasksWaypoint
  ship.GetTasksWaypoint=OPSGROUP.GetTasksWaypoint
  ship._SortTaskQueue=OPSGROUP._SortTaskQueue
  ship._SetWaypointTasks=OPSGROUP._SetWaypointTasks
  function ship:HasPassedFinalWaypoint() return self.passedfinalwp end
  function ship:GetVec3() return self.position end
  function ship:GetCoordinate() return coord(self.position.x,self.position.z,self.position.y) end
  function ship:GetHeading() return self.heading end
  function ship:GetSpeedCruise() return UTILS.MpsToKnots(10) end
  function ship:GetWaypointIndexNext()
    return self.adinfinitum and self.currentwp==#self.waypoints and 1 or self.currentwp+1
  end
  function ship:GetWaypointNext() return self.waypoints[self:GetWaypointIndexNext()] end
  function ship:GetWaypointCurrent() return self.waypoints[self.currentwp] end
  function ship:GetWaypointCurrentUID() local waypoint=self:GetWaypointCurrent() return waypoint and waypoint.uid end
  function ship:GetWaypointIndex(uid) for i,wp in ipairs(self.waypoints) do if wp.uid==uid then return i end end end
  function ship:GetWaypointByID(uid) local index=self:GetWaypointIndex(uid) return index and self.waypoints[index] end
  function ship:GetWaypoint(index) return self.waypoints[index] end
  function ship:RemoveWaypointByID(uid)
    local index=assert(self:GetWaypointIndex(uid)) table.remove(self.waypoints,index)
    if index<=self.currentwp then self.currentwp=math.max(1,self.currentwp-1) end
  end
  function ship:AddWaypoint(position,speed,after,depth,update)
    self.added=self.added+1 self.nextID=self.nextID+1
    local wp={uid=self.nextID,coordinate=position,x=position.x,y=position.z,speed=UTILS.KnotsToMps(speed),npassed=0}
    table.insert(self.waypoints,assert(self:GetWaypointIndex(after))+1,wp)
    return wp
  end
  function ship:FullStop()
    local from=self.state self.stops=self.stops+1 self.state="Holding"
    self:onafterFullStop(from,"FullStop",self.state)
    if self.OnAfterFullStop then self:OnAfterFullStop(from,"FullStop",self.state) end
  end
  function ship:Cruise(speed)
    local from=self.state self.cruises=self.cruises+1 self.state="Cruising"
    self:onafterCruise(from,"Cruise",self.state,speed)
  end
  function ship:CollisionWarning(clearDistance)
    self.warnings=self.warnings+1 self:onafterCollisionWarning(self.state,"CollisionWarning",self.state,clearDistance)
    if self.OnAfterCollisionWarning then self:OnAfterCollisionWarning(self.state,"CollisionWarning",self.state,clearDistance) end
  end
  function ship:ClearAhead() self.clears=self.clears+1 self:onafterClearAhead(self.state,"ClearAhead",self.state) end
  function ship:UpdateRoute(first,last,speed,depth)
    self.updates=self.updates+1 self:onafterUpdateRoute(self.state,"UpdateRoute",self.state,first,last,speed,depth)
  end
  function ship:__UpdateRoute(delay,first,last,speed,depth)
    self.updates=self.updates+1 self.pendingUpdate={first=first,last=last,speed=speed,depth=depth}
  end
  function ship:FlushUpdate()
    local update=self.pendingUpdate self.pendingUpdate=nil
    if update then self:onafterUpdateRoute(self.state,"UpdateRoute",self.state,update.first,update.last,update.speed,update.depth) end
  end
  function ship:TurningStarted() self.turning=true end
  function ship:TurningStopped() self.turning=false self:onafterTurningStopped(self.state,"TurningStopped",self.state) end
  function ship:IsTurning() return self.turning==true end
  function ship:IsSteamingIntoWind() return false end
  function ship:IsNavygroup() return true end
  function ship:IsEngaging() return self.state=="Engaging" end
  function ship:_PassedFinalWaypoint(value) self.passedfinalwp=value end
  function ship:PassingWaypoint() self.passingEvents=(self.passingEvents or 0)+1 end
  function ship:_SimpleTaskFunction(name,...)
    return {id="WrappedAction",params={action={id="Script",params={command=name}}},callback=name,args={...}}
  end
  function ship:Route(route) self.dispatched=route self.dispatches[#self.dispatches+1]=route end
  return ship
end

local function localShip(targetDistance)
  return vessel(targetDistance):SetPathfindingMode(NAVYGROUP.PathfindingMode.LOCAL)
end

-- Assertions intentionally compare route output and terrain clearance, not implementation copies.
local function assertClearPath(ship,points,start)
  local previous=start or ship.position
  for _,point in ipairs(points) do
    local clear,reason=ship:_CheckPathDepth(previous,point)
    assert(clear,"Unvalidated connection: "..tostring(reason))
    previous=point
  end
end
local function followPath(ship,path,lastIndex)
  for i=2,lastIndex or #path do
    ship.position=path[i]:GetVec3()
    ship:_LocalRouteProgress(VECTOR:NewFromVec(ship.position))
  end
end
local function queueWaypointTask(ship)
  local task={id=1,description="waypoint task",type=OPSGROUP.TaskType.WAYPOINT,status=OPSGROUP.TaskStatus.SCHEDULED,
    waypoint=2,time=0,prio=1,dcstask={id="AttackGroup"},stopflag={GetName=function() return "test-stop" end}}
  ship.taskqueue={task}
  ship.group={
    TaskFunction=function(_,name) return {id="WrappedAction",name=name} end,
    TaskCondition=function() return {} end,
    TaskControlled=function(_,native,condition) return {id="ControlledTask",params={task=native,condition=condition}} end,
    TaskCombo=function(_,tasks) return {id="ComboTask",params={tasks=tasks}} end}
  function ship:SetTask(native) self.installedTask=native self.taskSubmissions=(self.taskSubmissions or 0)+1 end
  function ship:PassingWaypoint(waypoint)
    self.passingEvents=(self.passingEvents or 0)+1
    OPSGROUP.onafterPassingWaypoint(self,self.state,"PassingWaypoint",self.state,waypoint)
  end
  return task
end

test("LOCAL configuration is opt-in and rejects unknown modes atomically",function()
  local ship=vessel()
  equal(NAVYGROUP.PathfindingMode.WAYPOINT,"waypoint") equal(NAVYGROUP.PathfindingMode.LOCAL,"local")
  ship:onafterUpdateRoute()
  equal(#ship.dispatched,3) equal(ship.dispatched[2].uid,2) equal(ship.dispatched[3].uid,3)
  equal(ship:SetPathfindingMode(NAVYGROUP.PathfindingMode.LOCAL),ship)
  equal(ship.pathfindingMode,"local")
  for _,bad in ipairs({false,true,1,"LOCAL","automatic",{}}) do
    assert(not pcall(ship.SetPathfindingMode,ship,bad)) equal(ship.pathfindingMode,"local")
  end
end)

test("LOCAL window is ship-centered, heading-aligned, fine and bounded",function()
  local ship=localShip()
  local start=VECTOR:New(1234,0,5678)
  local window=assert(ship:_GetLocalNavigationWindow(start,90,ship.waypoints[2]))
  near(window.Origin.x,start.x) near(window.Origin.z,start.z) near(window.Heading,90)
  near(window.Grid:GetResolutionInfo().Spacing,50)
  equal(window.MaxCells,ship.pathMaxCells or 5000)
  assert(window.Grid:GetCellCount()>0 and window.Grid:GetCellCount()<=window.MaxCells)
end)

test("LOCAL caches a nearby window and invalidates movement, heading, target and depth changes",function()
  local ship=localShip()
  local target=ship.waypoints[2]
  local first=assert(ship:_GetLocalNavigationWindow(VECTOR:New(0,0,0),0,target))
  ship.localNavigation={Window=first}
  equal(ship:_GetLocalNavigationWindow(VECTOR:New(100,0,0),10,target),first)
  local moved=assert(ship:_GetLocalNavigationWindow(VECTOR:New(1100,0,0),0,target))
  assert(moved~=first)
  ship.localNavigation={Window=first}
  assert(ship:_GetLocalNavigationWindow(VECTOR:New(0,0,0),45,target)~=first)
  ship.localNavigation={Window=first}
  target.coordinate.x=target.coordinate.x+1
  assert(ship:_GetLocalNavigationWindow(VECTOR:New(0,0,0),0,target)~=first)
  ship.localNavigation={Window=first}
  ship:SetPathfindingMinDepth(25)
  assert(ship:_GetLocalNavigationWindow(VECTOR:New(0,0,0),0,target)~=first)
end)

test("LOCAL distant-goal plans end in the local window with validated, bounded connections",function()
  local ship=localShip(100000)
  local plan,reason=ship:_PlanLocalPath(VECTOR:NewFromVec(ship.position),0,ship.waypoints[2],10)
  assert(plan,reason) equal(plan.GoalReached,false)
  assert(#plan.Points>0) assert(plan.Attempts<=8) assert(plan.CandidateCount<=5000)
  local previous=ship.position
  for _,point in ipairs(plan.Points) do
    assert(point.x>=-1000.001 and point.x<=3000.001 and math.abs(point.z)<=1000.001)
    assert(distance(previous,point)<=1000.001,"a steering connection exceeds the local shortcut limit")
    previous=point
  end
  assert(previous.x>=500,"local plan must make useful progress")
  assertClearPath(ship,plan.Points)
end)

test("LOCAL exact-goal plans validate the goal instead of clamping it to a grid cell",function()
  local ship=localShip(1777)
  ship.waypoints[2].coordinate=coord(1777,123)
  local plan,reason=ship:_PlanLocalPath(VECTOR:NewFromVec(ship.position),0,ship.waypoints[2],10)
  assert(plan,reason) equal(plan.GoalReached,true)
  local last=plan.Points[#plan.Points]
  near(last.x,1777) near(last.z,123)
  assertClearPath(ship,plan.Points)
end)

test("LOCAL detours keep every smoothed connection deep around an island",function()
  local ship=localShip()
  land.surfaceAt=function(p)
    return p.x>=750 and p.x<=1250 and math.abs(p.z)<=300 and land.SurfaceType.LAND or land.SurfaceType.WATER
  end
  local plan,reason=ship:_PlanLocalPath(VECTOR:NewFromVec(ship.position),0,ship.waypoints[2],10)
  assert(plan,reason) equal(plan.GoalReached,false)
  assertClearPath(ship,plan.Points)
  local lateral=false
  for _,point in ipairs(plan.Points) do if math.abs(point.z)>300 then lateral=true end end
  assert(lateral,"planned course did not avoid the island")
end)

test("LOCAL finds a side exit through a narrow bent canal",function()
  local ship=localShip()
  land.surfaceAt=function(point)
    local approach=point.x<=900 and math.abs(point.z)<=140
    local bend=math.abs(point.x-800)<=140 and point.z>=0
    return (approach or bend) and land.SurfaceType.WATER or land.SurfaceType.LAND
  end
  local plan,reason=ship:_PlanLocalPath(VECTOR:NewFromVec(ship.position),0,ship.waypoints[2],10)
  assert(plan,reason) equal(plan.GoalReached,false)
  local exit=plan.Points[#plan.Points]
  assert(exit.z>=850 and math.abs(exit.x-800)<140,"canal route must leave through its lateral opening")
  assertClearPath(ship,plan.Points)
  ship:onafterUpdateRoute()
  local navigation=assert(ship.localNavigation)
  assert(navigation.Length<2000,"fixture should exercise a short local route")
  local path,dispatches=navigation.Path,#ship.dispatches
  for i=1,3 do timerNow=i*10 ship:_CheckNavigation() end
  equal(navigation.Path,path) equal(#ship.dispatches,dispatches)
end)

test("LOCAL dead-end canal stops without extending its bounded search",function()
  local ship=localShip()
  land.surfaceAt=function(point)
    local approach=point.x<=900 and math.abs(point.z)<=140
    local bend=math.abs(point.x-800)<=140 and point.z>=0 and point.z<=600
    return (approach or bend) and land.SurfaceType.WATER or land.SurfaceType.LAND
  end
  ship:onafterUpdateRoute()
  equal(ship.state,"Holding") equal(ship.stops,1)
  equal(ship.LastPathfindingResult.StopReason,"no_local_exit")
  equal(ship.added,0) equal(#ship.waypoints,3)
end)

test("LOCAL grid allocation failure respects the cell budget",function()
  local ship=localShip():SetPathfindingGrid(1)
  local plan,reason=ship:_PlanLocalPath(VECTOR:NewFromVec(ship.position),0,ship.waypoints[2],10)
  equal(plan,nil) equal(reason,"cell_limit")
end)

test("LOCAL smoothing does not strand a short final residual or accept a sharp initial turn",function()
  local ship=localShip()
  local nodes={}
  for _,x in ipairs({500,950,1000,1050}) do nodes[#nodes+1]={vector=VECTOR:New(x,0,0)} end
  local points,reason=ship:_SimplifyLocalPath(VECTOR:New(0,0,0),0,nodes,false,10,0)
  assert(points,reason) equal(#points,2) near(points[1].x,950) near(points[2].x,1050)
  assertClearPath(ship,points)
  local rejected=ship:_SimplifyLocalPath(VECTOR:New(0,0,0),180,nodes,false,10,0)
  equal(rejected,nil)
end)

test("LOCAL behind-target navigation can choose useful local motion away from the target",function()
  local ship=localShip(-20000)
  local plan,reason=ship:_PlanLocalPath(VECTOR:NewFromVec(ship.position),0,ship.waypoints[2],10)
  assert(plan,reason) equal(plan.GoalReached,false)
  local endpoint=plan.Points[#plan.Points]
  assert(endpoint.x>=250 and distance(endpoint,ship.waypoints[2].coordinate)>20000)
  assertClearPath(ship,plan.Points)
end)

test("LOCAL dispatch contains only validated local points and leaves mission waypoints untouched",function()
  local ship=localShip()
  local original={ship.waypoints[1],ship.waypoints[2],ship.waypoints[3]}
  ship:onafterUpdateRoute()
  local navigation=assert(ship.localNavigation)
  equal(navigation.TargetUID,2) equal(navigation.GoalReached,false)
  equal(ship.added,0) equal(#ship.waypoints,3)
  for i,waypoint in ipairs(original) do equal(ship.waypoints[i],waypoint) end
  assert(#ship.dispatched>=2)
  for _,waypoint in ipairs(ship.dispatched) do
    assert(waypoint.uid~=2 and waypoint.uid~=3,"unchecked mission waypoint leaked into the native route")
    assert(waypoint.x<=3000.001 and math.abs(waypoint.y)<=1000.001)
  end
  assertClearPath(ship,navigation.Path)
  near(original[2].speed,10) equal(original[2].task.params.tasks[1].id,"TargetAction")
end)

test("LOCAL replaces legacy detour points only after the replacement route is valid",function()
  for _,fail in ipairs({false,true}) do
    local ship=localShip()
    local original=ship.waypoints[2]
    local temporary={uid=4,coordinate=coord(750,100),x=750,y=100,speed=10,npassed=0,astar=true,astarTargetUID=2}
    table.insert(ship.waypoints,2,temporary)
    if fail then ship:SetPathfindingGrid(1) end
    ship:onafterUpdateRoute()
    equal(ship:GetWaypointByID(2),original)
    if fail then
      equal(ship.state,"Holding") equal(ship.LastPathfindingResult.StopReason,"cell_limit")
      equal(#ship.waypoints,4) equal(ship.waypoints[2],temporary)
    else
      equal(ship.state,"Cruising") equal(ship.localNavigation.TargetUID,2)
      equal(#ship.waypoints,3) equal(ship:GetWaypointByID(4),nil)
      equal(ship.waypoints[2],original) equal(ship.localNavigation.SourceUID,1)
    end
  end
end)

test("LOCAL refuses an initial route shorter than its speed-based stopping reserve",function()
  local ship=localShip()
  ship:onafterUpdateRoute(nil,nil,nil,nil,nil,UTILS.MpsToKnots(100))
  equal(ship.state,"Holding") equal(ship.stops,1)
  equal(ship.LastPathfindingResult.StopReason,"local_route_too_short")
  assert(ship.LastPathfindingResult.Remaining>0 and ship.LastPathfindingResult.Remaining<7000)
  equal(#ship.dispatches,1) equal(#ship.dispatched,1) equal(ship.dispatched[1].speed,0)
  equal(#ship.waypoints,3) equal(ship.waypoints[2].uid,2)
end)

test("LOCAL progress waits for actual movement and renews the window at its reached exit",function()
  local ship=localShip()
  ship:onafterUpdateRoute()
  local navigation=ship.localNavigation
  local originalPath,originalWindow,revision=navigation.Path,navigation.Window,navigation.Revision
  local dispatches=#ship.dispatches
  for i=1,3 do timerNow=i*10 ship:_CheckNavigation() end
  equal(ship.localNavigation,navigation) equal(#ship.dispatches,dispatches)
  near(navigation.Progress or 0,0) equal(ship.currentwp,1)
  local endpoint=navigation.Path[#navigation.Path]
  local previous=navigation.Path[#navigation.Path-1]
  followPath(ship,navigation.Path)
  ship.heading=previous:GetHeadingTo(endpoint)
  ship.turningHeading=ship.heading ship.turningTime=timerNow
  timerNow=timerNow+10 ship:_CheckNavigation()
  assert(ship.localNavigation.Path~=originalPath,"reaching a local endpoint must obtain the next local route")
  assert(ship.localNavigation.Revision>revision)
  assert(#ship.dispatches>dispatches) equal(ship.currentwp,1)
  assert(ship.localNavigation.Window~=originalWindow)
  near(ship.localNavigation.Path[1].x,endpoint.x) near(ship.localNavigation.Path[1].z,endpoint.z)
end)

test("LOCAL endpoint callbacks cannot advance a mission waypoint early or twice",function()
  local ship=localShip(1500)
  ship:onafterUpdateRoute()
  local navigation=ship.localNavigation
  equal(navigation.GoalReached,true)
  equal(ship.dispatched[#ship.dispatched].uid,2)
  local originalTask=ship.waypoints[2].task
  NAVYGROUP._LocalWaypointPassed(ship,navigation.Revision)
  equal(ship.currentwp,1) equal(ship.passingEvents,nil)
  timerNow=10 ship:_CheckNavigation()
  equal(ship.currentwp,1) equal(ship.passingEvents,nil)
  followPath(ship,navigation.Path)
  timerNow=20 ship:_CheckNavigation()
  equal(ship.currentwp,2) equal(ship.passingEvents,1)
  equal(ship.waypoints[2].npassed,1) equal(ship.waypoints[2].task,originalTask)
  NAVYGROUP._LocalWaypointPassed(ship,navigation.Revision)
  timerNow=30 ship:_CheckNavigation()
  equal(ship.currentwp,2) equal(ship.passingEvents,1) equal(ship.waypoints[2].npassed,1)
end)

test("LOCAL preserves queued tasks at intermediate and final mission waypoints",function()
  for _,final in ipairs({false,true}) do
    local ship=localShip(1500)
    if final then table.remove(ship.waypoints,3) end
    local task=queueWaypointTask(ship)
    ship:onafterUpdateRoute()
    local navigation=ship.localNavigation
    local dispatches=#ship.dispatches
    NAVYGROUP._LocalWaypointPassed(ship,navigation.Revision)
    equal(ship.taskSubmissions,nil)
    followPath(ship,navigation.Path)
    timerNow=10 ship:_CheckNavigation()
    equal(ship.currentwp,2) equal(ship.taskSubmissions,1)
    equal(ship.installedTask.params.tasks[2].params.task,task.dcstask)
    equal(ship.pendingUpdate,nil) equal(#ship.dispatches,dispatches)
    equal(ship.localNavigationTaskUID,2)
    timerNow=20 ship:_CheckNavigation()
    equal(#ship.dispatches,dispatches) equal(ship.taskSubmissions,1)
    task.status=OPSGROUP.TaskStatus.EXECUTING ship.taskcurrent=task.id
    timerNow=30 ship:_CheckNavigation()
    equal(#ship.dispatches,dispatches)
    task.status=OPSGROUP.TaskStatus.DONE ship.taskcurrent=nil
    timerNow=40 ship:_CheckNavigation()
    if final then equal(#ship.dispatches,dispatches)
    else assert(#ship.dispatches>dispatches) end
    equal(ship.taskSubmissions,1)
  end
end)

test("LOCAL FullStop cancels the task-startup guard so a later Cruise can proceed",function()
  local ship=localShip(1500)
  local task=queueWaypointTask(ship)
  ship:onafterUpdateRoute()
  followPath(ship,ship.localNavigation.Path)
  timerNow=10 ship:_CheckNavigation()
  equal(ship.taskSubmissions,1) equal(ship.localNavigationTaskUID,2)
  equal(task.status,OPSGROUP.TaskStatus.SCHEDULED) equal(ship.currentwp,2)
  ship:FullStop()
  equal(ship.localNavigationTaskUID,nil) equal(ship.state,"Holding")
  local dispatches=#ship.dispatches
  ship:Cruise(14) ship:FlushUpdate()
  equal(ship.state,"Cruising") equal(ship.localNavigation.TargetUID,3)
  assert(#ship.dispatches>dispatches)
  equal(task.status,OPSGROUP.TaskStatus.SCHEDULED) equal(ship.taskSubmissions,1)
end)

test("LOCAL turning keeps checking depth without repeatedly replacing the route",function()
  local ship=localShip()
  ship:onafterUpdateRoute()
  ship:_CheckNavigation()
  local dispatches,queries=#ship.dispatches,ship.terrain.queries
  ship.heading=10 timerNow=10 ship:_CheckNavigation()
  equal(ship:IsTurning(),true)
  assert(ship.terrain.queries>queries,"turning must not suspend local depth monitoring")
  equal(#ship.dispatches,dispatches)
  ship.heading=20 timerNow=20 ship:_CheckNavigation()
  equal(ship:IsTurning(),true) equal(#ship.dispatches,dispatches)
end)

test("LOCAL projected progress cannot jump to the return leg of a nearby hairpin",function()
  local ship=localShip()
  ship.localNavigation={Path={VECTOR:New(0,0,0),VECTOR:New(1000,0,0),VECTOR:New(1000,0,100),VECTOR:New(0,0,100)},
    Distances={0,1000,1100,2100},Length=2100,Segment=1,Progress=0}
  local progress,remaining,deviation=ship:_LocalRouteProgress(VECTOR:New(0,0,95))
  near(progress,0) near(remaining,2100) near(deviation,95)
  equal(ship.localNavigation.Segment,1)
  progress=ship:_LocalRouteProgress(VECTOR:New(900,0,0)) near(progress,900)
  progress=ship:_LocalRouteProgress(VECTOR:New(200,0,0)) near(progress,900)
end)

test("LOCAL progress follows the adjacent segment when a ship rounds a steering corner",function()
  local ship=localShip()
  ship.localNavigation={Path={VECTOR:New(0,0,0),VECTOR:New(1000,0,0),VECTOR:New(1000,0,1000)},
    Distances={0,1000,2000},Length=2000,Segment=1,Progress=900}
  local progress,remaining,deviation=ship:_LocalRouteProgress(VECTOR:New(980,0,200))
  equal(ship.localNavigation.Segment,2)
  near(progress,1200) near(remaining,800) near(deviation,20)
end)

test("LOCAL prepares a continuation during a turn and preserves its next steering point",function()
  local ship=localShip()
  ship:onafterUpdateRoute()
  local navigation=ship.localNavigation
  local path=navigation.Path
  assert(#path>=4)
  local upcoming=path[3]
  followPath(ship,path,2)
  ship.position={x=path[2].x+(upcoming.x-path[2].x)*0.1,y=0,z=path[2].z+(upcoming.z-path[2].z)*0.1}
  ship.turning=true
  local dispatches=#ship.dispatches
  ship:_CheckLocalNavigation()
  assert(navigation.Pending,"remaining validated route should prepare a continuation")
  equal(#ship.dispatches,dispatches) equal(navigation.Path,path)
  local pending=navigation.Pending
  near(pending.Points[2].x,upcoming.x) near(pending.Points[2].z,upcoming.z)
  ship.position={x=(path[2].x+upcoming.x)/2,y=0,z=(path[2].z+upcoming.z)/2}
  ship.turning=false
  ship:_CheckLocalNavigation()
  equal(navigation.Pending,nil) equal(#ship.dispatches,dispatches+1)
  near(ship.dispatched[2].x,upcoming.x) near(ship.dispatched[2].y,upcoming.z)
end)

test("LOCAL revalidates a prepared continuation after minimum depth increases",function()
  local ship=localShip()
  ship:onafterUpdateRoute()
  local navigation=ship.localNavigation
  local path=navigation.Path
  local oldMaxX=path[#path].x
  ship.terrain.depthAt=function(point) return point.x>oldMaxX+100 and 30 or 50 end
  followPath(ship,path,2)
  ship.position={x=path[2].x+(path[3].x-path[2].x)*0.1,y=0,z=path[2].z+(path[3].z-path[2].z)*0.1}
  ship.turning=true
  ship:_CheckLocalNavigation()
  local pending=assert(navigation.Pending)
  assert(pending.Points[#pending.Points].x>oldMaxX+100)
  local dispatches=#ship.dispatches
  ship:SetPathfindingMinDepth(40)
  ship.turning=false
  ship:_CheckLocalNavigation()
  equal(ship.state,"Holding") equal(ship.stops,1)
  equal(#ship.dispatches,dispatches+1) equal(ship.dispatched[1].speed,0)
  equal(ship.LastPathfindingResult.DepthCheck.Status,"blocked")
end)

test("LOCAL stops before exhausting its validated route while still turning",function()
  local ship=localShip()
  ship:onafterUpdateRoute()
  local navigation=ship.localNavigation
  local endpoint=navigation.Path[#navigation.Path]
  followPath(ship,navigation.Path)
  ship.turning=true
  ship:_CheckLocalNavigation()
  equal(ship.state,"Holding") equal(ship.stops,1)
  equal(ship.LastPathfindingResult.StopReason,"local_route_exhausted_in_turn")
  equal(ship.dispatched[1].speed,0)
end)

test("LOCAL unavailable depth and planning failures stop once without timer-driven recovery",function()
  for _,failure in ipairs({"profile","budget"}) do
    local ship=localShip()
    if failure=="profile" then ship.terrain.makeProfile=function() return nil end
    else ship:SetPathfindingGrid(1) end
    ship:onafterUpdateRoute()
    equal(ship.state,"Holding") equal(ship.stops,1) equal(#ship.dispatched,1)
    equal(ship.dispatched[1].speed,0)
    local report=assert(ship.LastPathfindingResult)
    local queries,dispatches=ship.terrain.queries,#ship.dispatches
    ship.terrain.makeProfile=nil ship:SetPathfindingGrid(5000)
    for i=1,3 do timerNow=i*100 ship:_CheckNavigation() end
    equal(ship.state,"Holding") equal(ship.stops,1) equal(ship.cruises,0)
    equal(ship.LastPathfindingResult,report) equal(ship.terrain.queries,queries) equal(#ship.dispatches,dispatches)
  end
end)

test("LOCAL FullStop remains authoritative over callbacks and later clear water",function()
  local ship=localShip(1500)
  ship:onafterUpdateRoute()
  local navigation=ship.localNavigation
  ship:FullStop()
  local dispatches=#ship.dispatches
  ship.position=ship.waypoints[2].coordinate:GetVec3()
  NAVYGROUP._LocalWaypointPassed(ship,navigation.Revision)
  timerNow=600 ship:_CheckNavigation()
  equal(ship.state,"Holding") equal(ship.stops,1) equal(ship.cruises,0)
  equal(ship.currentwp,1) equal(ship.passingEvents,nil) equal(#ship.dispatches,dispatches)
  ship:Cruise(14) ship:FlushUpdate() ship:FlushUpdate()
  equal(ship.state,"Cruising") assert(#ship.dispatches>dispatches)
end)

test("LOCAL waiting and another task's movement suppress planning and dispatch",function()
  for _,owner in ipairs({"waiting","task","completed"}) do
    local ship=localShip()
    ship:onafterUpdateRoute()
    if owner=="waiting" then ship.Twaiting=0
    elseif owner=="task" then
      ship.taskcurrent=1
      function ship:GetTaskByID() return {dcstask={id="AttackGroup"}} end
    else ship.passedfinalwp=true end
    local dispatches,queries=#ship.dispatches,ship.terrain.queries
    timerNow=20 ship:_CheckNavigation()
    equal(#ship.dispatches,dispatches) equal(ship.terrain.queries,queries)
  end
end)

test("LOCAL explicit waypoint selection persists beyond the route update",function()
  local ship=localShip()
  ship:onafterUpdateRoute(nil,nil,nil,3)
  equal(ship.localNavigation.TargetUID,3) equal(ship.currentwp,1)
  local navigation=ship.localNavigation
  timerNow=10 ship:_CheckNavigation()
  equal(ship.localNavigation.TargetUID,3) equal(ship.localNavigation,navigation)
end)

test("LOCAL retargeting discards the old route, window and stale callback",function()
  local ship=localShip(1500)
  ship:onafterUpdateRoute()
  local previous=ship.localNavigation
  ship.waypoints[2].coordinate=coord(30000,5000)
  ship.waypoints[2].x,ship.waypoints[2].y=30000,5000
  ship:onafterUpdateRoute()
  local navigation=ship.localNavigation
  assert(navigation~=previous) assert(navigation.Window~=previous.Window)
  equal(navigation.TargetUID,2) equal(navigation.GoalReached,false)
  NAVYGROUP._LocalWaypointPassed(ship,previous.Revision)
  equal(ship.currentwp,1) equal(ship.passingEvents,nil)
  assert(not navigation.GoalReported)
end)

test("LOCAL commanded speed and submarine depth survive periodic replanning",function()
  local ship=localShip()
  ship:onafterUpdateRoute(nil,nil,nil,nil,nil,14,40)
  local navigation=ship.localNavigation
  local originalPath=navigation.Path
  for _,waypoint in ipairs(ship.dispatched) do near(waypoint.speed,UTILS.KnotsToMps(14)) near(waypoint.alt,-40) end
  local endpoint=navigation.Path[#navigation.Path]
  followPath(ship,navigation.Path)
  ship.heading=navigation.Path[#navigation.Path-1]:GetHeadingTo(endpoint)
  ship.turningHeading=ship.heading ship.turningTime=0
  timerNow=10 ship:_CheckNavigation()
  assert(ship.localNavigation.Path~=originalPath)
  for _,waypoint in ipairs(ship.dispatched) do near(waypoint.speed,UTILS.KnotsToMps(14)) near(waypoint.alt,-40) end
  near(ship.waypoints[2].speed,10) near(ship.waypoints[2].coordinate.y,0)
end)

test("LOCAL speed and depth commands received during a turn take effect once the heading stabilizes",function()
  local ship=localShip()
  ship:onafterUpdateRoute()
  local dispatches=#ship.dispatches
  ship.turning=true
  ship:onafterDive(nil,nil,nil,40,14) ship:FlushUpdate()
  equal(#ship.dispatches,dispatches)
  assert(ship.localNavigation.NeedsSubmit)
  ship.turning=false ship:_CheckLocalNavigation()
  equal(#ship.dispatches,dispatches+1)
  for _,waypoint in ipairs(ship.dispatched) do near(waypoint.speed,UTILS.KnotsToMps(14)) near(waypoint.alt,-40) end
  ship:Cruise(12) ship:FlushUpdate()
  for _,waypoint in ipairs(ship.dispatched) do near(waypoint.speed,UTILS.KnotsToMps(12)) near(waypoint.alt,0) end
  equal(ship.depth,nil)
end)

test("LOCAL mode and pathfinding switches discard local state and preserve manual holds",function()
  for _,switch in ipairs({"mode","off"}) do
    local ship=localShip()
    ship:onafterUpdateRoute()
    if switch=="mode" then ship:SetPathfindingMode(NAVYGROUP.PathfindingMode.WAYPOINT)
    else ship:SetPathfindingOff() end
    equal(ship.localNavigation,nil)
    assert(ship.pendingUpdate,"leaving LOCAL must restore the mission route while cruising")
    ship:FlushUpdate()
    equal(ship.dispatched[2].uid,2) equal(ship.dispatched[3].uid,3)
    ship:FullStop()
    local dispatches=#ship.dispatches
    ship:SetPathfindingMode(NAVYGROUP.PathfindingMode.LOCAL):SetPathfindingOn()
    timerNow=10 ship:_CheckNavigation()
    equal(ship.state,"Holding") equal(#ship.dispatches,dispatches)
  end
end)

print(string.format("%d passed, %d failed",passed,failed))
if failed>0 then os.exit(1) end
