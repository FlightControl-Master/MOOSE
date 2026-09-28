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
local searches={grids=0,astar=0}
local newGrid,newAstar=GRID.New,ASTAR.New
function GRID:New(...)
  searches.grids=searches.grids+1
  return newGrid(self,...)
end
function ASTAR:New(...)
  searches.astar=searches.astar+1
  local search=newAstar(self,...)
  searches.lastAstar=search
  return search
end
local function equal(actual,expected)
  assert(actual==expected,"expected "..tostring(expected)..", got "..tostring(actual))
end
local function near(actual,expected,tolerance)
  assert(math.abs(actual-expected)<(tolerance or 1e-7),"expected approximately "..tostring(expected)..", got "..tostring(actual))
end
local function distance(a,b) return math.sqrt((a.x-b.x)^2+(a.z-b.z)^2) end
local function test(name,run)
  land.surfaceAt=nil timerNow=0
  searches.grids=0 searches.astar=0 searches.lastAstar=nil
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
    local index=after and assert(self:GetWaypointIndex(after))+1 or #self.waypoints+1
    table.insert(self.waypoints,index,wp)
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
  function ship:ClearAhead()
    self.clears=self.clears+1 self:onafterClearAhead(self.state,"ClearAhead",self.state)
    if self.OnAfterClearAhead then self:OnAfterClearAhead(self.state,"ClearAhead",self.state) end
  end
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

-- Planner/lifecycle regressions enter the private handler after collision detection.
-- Separate public route/timer tests below verify that clear water never activates LOCAL.
local function activateLocal(ship,speed,depth,first)
  return ship:_CheckLocalNavigation(true,speed,depth,first)
end

local function forbidGlobalPlanner(ship)
  function ship:_FindPathToNextWaypoint()
    error("LOCAL collision must not invoke the full waypoint planner")
  end
end

local function assertNoSearch()
  equal(searches.grids,0) equal(searches.astar,0)
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

test("LOCAL selection preserves the ordinary native route in clear water without allocating a search",function()
  local ship=localShip()
  forbidGlobalPlanner(ship)
  local original={ship.waypoints[1],ship.waypoints[2],ship.waypoints[3]}
  ship:onafterUpdateRoute()
  equal(#ship.dispatched,3) equal(ship.dispatched[2].uid,2) equal(ship.dispatched[3].uid,3)
  equal(ship.dispatched[2].task.params.tasks[1].id,"TargetAction")
  equal(ship.dispatched[3].task.params.tasks[1].id,"LaterAction")
  local dispatches=#ship.dispatches
  for i=1,3 do timerNow=i*10 ship:_CheckNavigation() end
  equal(ship.localNavigation,nil) equal(#ship.dispatches,dispatches)
  equal(ship.stops,0) equal(ship.warnings,0) equal(ship.added,0)
  for i,waypoint in ipairs(original) do equal(ship.waypoints[i],waypoint) end
  assert(ship.terrain.profiles>0,"inactive LOCAL must still inspect the ordinary upcoming route")
  assertNoSearch()
end)

test("LOCAL mode and enable switches stay inactive in clear water at runtime",function()
  local ship=vessel()
  forbidGlobalPlanner(ship)
  ship:onafterUpdateRoute()
  local dispatches=#ship.dispatches
  ship:SetPathfindingMode(NAVYGROUP.PathfindingMode.LOCAL)
  timerNow=10 ship:_CheckNavigation()
  equal(ship.localNavigation,nil) equal(#ship.dispatches,dispatches) assertNoSearch()
  ship:SetPathfindingOff()
  timerNow=20 ship:_CheckNavigation()
  ship:SetPathfindingOn()
  timerNow=30 ship:_CheckNavigation()
  equal(ship.localNavigation,nil) equal(#ship.dispatches,dispatches) assertNoSearch()
  ship:SetPathfindingMode(NAVYGROUP.PathfindingMode.WAYPOINT)
  ship:SetPathfindingMode(NAVYGROUP.PathfindingMode.LOCAL)
  timerNow=40 ship:_CheckNavigation()
  equal(ship.localNavigation,nil) equal(#ship.dispatches,dispatches) assertNoSearch()
  equal(ship.dispatched[2].uid,2) equal(ship.dispatched[3].uid,3)
end)

test("LOCAL warns at 5 km but starts planning only when the obstruction enters its horizon",function()
  local ship=localShip(20000)
  forbidGlobalPlanner(ship)
  ship.terrain.depthAt=function(point) return point.x>=4450 and point.x<=4550 and math.abs(point.y)<=200 and 5 or 40 end
  local checked={}
  function ship:_CheckPathDepth(start,goal)
    checked[#checked+1]=distance(start,goal)
    return NAVYGROUP._CheckPathDepth(self,start,goal)
  end
  ship:onafterUpdateRoute()
  assertNoSearch() equal(ship.localNavigation,nil)
  ship:_CheckNavigation()
  near(checked[1],5000)
  equal(ship.warnings,1) equal(ship.localNavigation,nil) assertNoSearch()
  near(ship.LastNavigationCheck.LocalSearchDistance,2100)
  near(ship.LastNavigationCheck.LocalSearchAhead,3000)
  local dispatched,dispatches=ship.dispatched,#ship.dispatches

  -- A warning stays active without changing the native route or allocating a grid.
  for i=1,3 do
    timerNow=i*10 ship:_CheckNavigation()
    equal(ship.dispatched,dispatched) equal(#ship.dispatches,dispatches) equal(ship.warnings,1)
    equal(ship.localNavigation,nil) equal(ship.stops,0) assertNoSearch()
  end

  ship.position={x=2500,y=0,z=0}
  timerNow=40 ship:_CheckNavigation()
  local navigation=assert(ship.localNavigation)
  equal(navigation.TargetUID,2) equal(navigation.GoalReached,false)
  assert(searches.grids>0 and searches.astar>0,"approaching an already warned obstacle must start LOCAL")
  equal(ship.added,0) equal(#ship.waypoints,3) equal(ship.state,"Cruising")
  for _,waypoint in ipairs(ship.dispatched) do
    assert(waypoint.uid~=2 and waypoint.uid~=3,"activation leaked distant mission points into the local route")
    assert(waypoint.x<=5500.001 and math.abs(waypoint.y)<=1000.001)
  end
  assertClearPath(ship,navigation.Path)
end)

test("LOCAL collision activation replaces legacy detour points while retaining the original target",function()
  local ship=localShip()
  forbidGlobalPlanner(ship)
  local original=ship.waypoints[2]
  local temporary={uid=4,coordinate=coord(10000),x=10000,y=0,speed=10,npassed=0,astar=true,astarTargetUID=2}
  table.insert(ship.waypoints,2,temporary)
  ship.terrain.depthAt=function(point) return point.x>=1450 and point.x<=1550 and math.abs(point.y)<=200 and 5 or 40 end
  ship:onafterUpdateRoute()
  equal(ship.dispatched[2].uid,4) assertNoSearch()
  ship:_CheckNavigation()
  equal(assert(ship.localNavigation).TargetUID,2)
  equal(ship:GetWaypointByID(4),nil) equal(ship:GetWaypointByID(2),original) equal(#ship.waypoints,3)
  equal(ship.added,0)
  assertClearPath(ship,ship.localNavigation.Path)
end)

test("LOCAL ordinary activation honors a newly inserted next waypoint when the route changes",function()
  local ship=localShip()
  forbidGlobalPlanner(ship)
  ship.terrain.depthAt=function(point) return point.x>=1450 and point.x<=1550 and math.abs(point.y)<=200 and 5 or 40 end
  ship:onafterUpdateRoute()
  ship:_CheckNavigation()
  assert(ship.localNavigation)
  local grids,astar=searches.grids,searches.astar
  local inserted=ship:AddWaypoint(coord(0,10000),14,1,nil,false)
  ship:onafterUpdateRoute()
  ship:FlushUpdate()
  equal(ship.localNavigation,nil) equal(ship.dispatched[2].uid,inserted.uid) equal(ship.dispatched[3].uid,2)
  timerNow=10 ship:_CheckNavigation()
  equal(ship.localNavigation,nil) equal(ship.currentwp,1) equal(ship.passingEvents,nil)
  equal(searches.grids,grids) equal(searches.astar,astar)
end)

test("LOCAL ignores obstacles beyond its normal collision lookahead until they enter the checked route",function()
  local ship=localShip()
  forbidGlobalPlanner(ship)
  ship.terrain.depthAt=function(point) return point.x>=5450 and point.x<=5550 and math.abs(point.y)<=200 and 5 or 40 end
  ship:onafterUpdateRoute()
  ship:_CheckNavigation()
  equal(ship.localNavigation,nil) equal(ship.warnings,0) assertNoSearch()
  ship.position={x=1000,y=0,z=0}
  timerNow=10 ship:_CheckNavigation()
  equal(ship.localNavigation,nil) equal(ship.warnings,1) assertNoSearch()
  ship.position={x=3500,y=0,z=0}
  timerNow=20 ship:_CheckNavigation()
  equal(assert(ship.localNavigation).TargetUID,2)
  assert(searches.grids>0 and searches.astar>0)
end)

test("LOCAL leaves avoidance when the target horizon clears and reactivates for another obstacle",function()
  local ship=localShip(8000)
  forbidGlobalPlanner(ship)
  ship.terrain.depthAt=function(point) return point.x>=1450 and point.x<=1550 and math.abs(point.y)<=200 and 5 or 40 end
  ship:onafterUpdateRoute()
  ship:_CheckNavigation()
  local navigation=assert(ship.localNavigation)
  assert(ship:_CheckPathDepth(ship.position,navigation.Path[2]),"the first short steering leg must be clear")
  local dispatches=#ship.dispatches
  local original=ship.waypoints[2]
  local task=original.task
  -- A clear first steering leg alone is not enough while the original target direction is blocked.
  timerNow=10 ship:_CheckNavigation()
  equal(ship.localNavigation,navigation) equal(#ship.dispatches,dispatches)
  ship.terrain.depthAt=nil
  timerNow=20 ship:_CheckNavigation()
  equal(ship.localNavigation,nil)
  equal(#ship.dispatches,dispatches+1) equal(ship.dispatched[2].uid,2)
  equal(ship.waypoints[2],original) equal(original.task,task)
  equal(ship.currentwp,1) equal(original.npassed,0) equal(ship.passingEvents,nil)
  local grids,astar=searches.grids,searches.astar
  timerNow=30 ship:_CheckNavigation()
  equal(ship.localNavigation,nil) equal(searches.grids,grids) equal(searches.astar,astar)
  equal(#ship.dispatches,dispatches+1)

  ship.terrain.depthAt=function(point) return point.x>=1450 and point.x<=1550 and math.abs(point.y)<=200 and 5 or 40 end
  timerNow=40 ship:_CheckNavigation()
  assert(ship.localNavigation and ship.localNavigation~=navigation)
  equal(ship.localNavigation.TargetUID,2) assert(searches.grids>grids)
end)

test("LOCAL unavailable collision depth stops before any search and does not retry",function()
  local ship=localShip()
  forbidGlobalPlanner(ship)
  ship:onafterUpdateRoute()
  ship.terrain.makeProfile=function() return nil end
  ship:_CheckNavigation()
  equal(ship.state,"Holding") equal(ship.stops,1) equal(ship.localNavigation,nil)
  equal(ship.LastPathfindingResult.DepthCheck.Status,"unavailable")
  equal(#ship.dispatched,1) equal(ship.dispatched[1].speed,0) assertNoSearch()
  local queries,dispatches=ship.terrain.queries,#ship.dispatches
  ship.terrain.makeProfile=nil
  for i=1,3 do timerNow=i*10 ship:_CheckNavigation() end
  equal(ship.stops,1) equal(ship.terrain.queries,queries) equal(#ship.dispatches,dispatches) assertNoSearch()
end)

test("LOCAL selection during turns and manual holds cannot start an inactive search",function()
  for _,reason in ipairs({"turning","holding"}) do
    local ship=localShip()
    forbidGlobalPlanner(ship)
    ship.terrain.depthAt=function(point) return point.x>=1450 and point.x<=1550 and math.abs(point.y)<=200 and 5 or 40 end
    if reason=="turning" then
      ship.turning=true ship.heading=20 ship.turningHeading=0 ship.turningTime=0
    else ship:FullStop() end
    local dispatches,queries=#ship.dispatches,ship.terrain.queries
    timerNow=10 ship:_CheckNavigation()
    equal(ship.localNavigation,nil) equal(#ship.dispatches,dispatches)
    if reason=="turning" then assert(ship.terrain.queries>queries)
    else equal(ship.terrain.queries,queries) end
    assertNoSearch()
  end
end)

test("LOCAL collision-warning callbacks can disable or retarget navigation before search starts",function()
  for _,action in ipairs({"disable","retarget","edit"}) do
    local ship=localShip()
    forbidGlobalPlanner(ship)
    ship.waypoints[3].coordinate=coord(0,30000)
    ship.waypoints[3].x,ship.waypoints[3].y=0,30000
    ship.terrain.depthAt=function(point) return point.x>=1450 and point.x<=1550 and math.abs(point.y)<=200 and 5 or 40 end
    function ship:OnAfterCollisionWarning()
      if action=="disable" then self:SetPathfindingOff()
      elseif action=="retarget" then self:onafterUpdateRoute(nil,nil,nil,3)
      else
        self.waypoints[2].coordinate=coord(0,20000)
        self.waypoints[2].x,self.waypoints[2].y=0,20000
        self:onafterUpdateRoute()
      end
    end
    ship:onafterUpdateRoute()
    ship:_CheckNavigation()
    equal(ship.warnings,1) equal(ship.localNavigation,nil) equal(ship.stops,0) assertNoSearch()
    if action=="disable" then equal(ship.pathfindingOn,false)
    elseif action=="retarget" then equal(#ship.dispatched,2) equal(ship.dispatched[2].uid,3)
    else equal(ship.dispatched[2].uid,2) near(ship.dispatched[2].x,0) near(ship.dispatched[2].y,20000) end
    timerNow=10 ship:_CheckNavigation()
    equal(ship.localNavigation,nil) assertNoSearch()
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

test("LOCAL trigger includes the faster of commanded and actual speed and remains bounded",function()
  local ship=localShip()
  local trigger,ahead=ship:_GetLocalNavigationHorizon(10)
  near(trigger,2100) near(ahead,3000)
  trigger,ahead=ship:_GetLocalNavigationHorizon(20)
  near(trigger,2400) near(ahead,3000)
  trigger,ahead=ship:_GetLocalNavigationHorizon(30)
  near(trigger,3100) near(ahead,4000)
  ship.velocity=30
  trigger,ahead=ship:_GetLocalNavigationHorizon(10)
  near(trigger,3100) near(ahead,4000)
  ship.velocity=0 ship.speedWp=0
  trigger,ahead=ship:_GetLocalNavigationHorizon()
  near(trigger,2100) near(ahead,3000)
  trigger,ahead=ship:_GetLocalNavigationHorizon(1000)
  near(trigger,5000) near(ahead,5500)
end)

test("LOCAL activates at the distance boundary without needing a new warning event",function()
  local ship=localShip()
  local clearance=2101
  local attempts=0
  function ship:_CheckNavigationAhead()
    return false,"profile_blocked",{Status="blocked",ClearDistance=clearance,Distance=5000,Reason="profile_blocked"}
  end
  function ship:_CheckLocalNavigation() attempts=attempts+1 return true end
  ship:_CheckNavigation()
  equal(attempts,0) equal(ship.warnings,1) assertNoSearch()
  clearance=2100 timerNow=10 ship:_CheckNavigation()
  equal(attempts,1) equal(ship.warnings,1) equal(ship.stops,0)
end)

test("LOCAL distant warning clears without ever changing the native route",function()
  local ship=localShip()
  ship.terrain.depthAt=function(point) return point.x>=4450 and point.x<=4550 and 5 or 40 end
  ship:onafterUpdateRoute()
  local route=ship.dispatched
  ship:_CheckNavigation()
  equal(ship.warnings,1) equal(ship.collisionwarning,true) assertNoSearch()
  ship.terrain.depthAt=nil
  timerNow=10 ship:_CheckNavigation()
  equal(ship.collisionwarning,false) equal(ship.clears,1)
  equal(ship.dispatched,route) equal(#ship.dispatches,1) equal(ship.localNavigation,nil)
  equal(ship.stops,0) assertNoSearch()
end)

test("LOCAL faster windows cover the trigger and move their candidate exits to the grown front",function()
  local ship=localShip()
  local start=VECTOR:New(0,0,0)
  local normal=assert(ship:_GetLocalNavigationWindow(start,90,ship.waypoints[2],10))
  equal(normal.Ahead,3000)
  ship.velocity=30
  local fast=assert(ship:_GetLocalNavigationWindow(start,90,ship.waypoints[2],10))
  assert(fast~=normal) equal(fast.Ahead,4000)
  assert(fast.Ahead>=ship:_GetLocalNavigationHorizon(10)+500)
  near(fast.Grid:GetResolutionInfo().Spacing,50)
  assert(fast.Grid:GetCellCount()<=fast.MaxCells)
  for _,cell in ipairs(fast.Grid:GetCells()) do
    assert(cell.vector.z>=-1000.001 and cell.vector.z<=4000.001 and math.abs(cell.vector.x)<=1000.001)
  end
  local front=false
  for _,candidate in ipairs(ship:_GetLocalNavigationCandidates(fast,start,90,ship.waypoints[2])) do
    if candidate.Vector.z>=3850 then front=true end
  end
  assert(front,"candidate exits still follow the old 3 km boundary")
  ship.velocity=31
  equal(ship:_GetLocalNavigationWindow(start,90,ship.waypoints[2],10),fast)
  ship.velocity=10
  equal(ship:_GetLocalNavigationWindow(start,90,ship.waypoints[2],10),fast)
end)

test("LOCAL planned acceleration grows the window before the ship reaches its commanded speed",function()
  local ship=localShip()
  ship.velocity=10
  local window=assert(ship:_GetLocalNavigationWindow(VECTOR:New(0,0,0),0,ship.waypoints[2],30))
  equal(window.Ahead,4000)
end)

test("LOCAL a faster ship starts before a slow ship would and plans beyond the obstruction",function()
  local ship=localShip()
  ship.velocity=30 -- Still moving faster than the commanded 10 m/s.
  ship.terrain.depthAt=function(point)
    return point.x>=2800 and point.x<=2900 and math.abs(point.y)<=200 and 5 or 40
  end
  ship:onafterUpdateRoute()
  ship:_CheckNavigation()
  local navigation=assert(ship.localNavigation)
  equal(navigation.Window.Ahead,4000)
  assert(searches.astar>0) equal(ship.stops,0)
  assertClearPath(ship,navigation.Path)
end)

test("WAYPOINT mode still searches immediately for a distant obstacle inside the warning horizon",function()
  local ship=vessel():SetPathfindingMode(NAVYGROUP.PathfindingMode.WAYPOINT)
  ship.terrain.depthAt=function(point) return point.x>=4450 and point.x<=4550 and 5 or 40 end
  local attempts=0
  function ship:_FindPathToNextWaypoint() attempts=attempts+1 return true end
  ship:onafterUpdateRoute()
  ship:_CheckNavigation()
  equal(attempts,1) equal(ship.warnings,1) equal(ship.stops,0)
  assert(ship.LastNavigationCheck.ClearDistance>4000)
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
  activateLocal(ship)
  local navigation=assert(ship.localNavigation)
  assert(plan.Length<plan.RequiredLength,"fixture should exercise a short side exit")
  assert(ship.LastPathfindingResult.PreflightExtensions>0,"short canal exit must be extended before departure")
  assert(navigation.Length>=ship.LastPathfindingResult.RequiredLength)
  assertClearPath(ship,navigation.Path)
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
  activateLocal(ship)
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
  activateLocal(ship)
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
    activateLocal(ship)
    equal(ship:GetWaypointByID(2),original)
    if fail then
      equal(ship.state,"Holding") equal(ship.LastPathfindingResult.StopReason,"cell_limit")
      equal(#ship.waypoints,4) equal(ship.waypoints[2],temporary)
    else
      equal(ship.state,"Cruising") equal(ship.localNavigation.TargetUID,2)
      equal(#ship.waypoints,3) equal(ship:GetWaypointByID(4),nil)
      equal(ship.waypoints[2],original) equal(ship:_GetNavigationWaypoint(),original)
    end
  end
end)

test("LOCAL refuses an initial route shorter than its speed-based stopping reserve",function()
  -- Deliberately extreme speed: even two windows plus checked target approaches must stay bounded.
  local ship=localShip(100000):SetPathfindingGrid(8000)
  activateLocal(ship,UTILS.MpsToKnots(500))
  equal(ship.state,"Holding") equal(ship.stops,1)
  equal(ship.LastPathfindingResult.StopReason,"local_route_too_short")
  equal(#ship.dispatches,1) equal(#ship.dispatched,1) equal(ship.dispatched[1].speed,0)
  equal(#ship.waypoints,3) equal(ship.waypoints[2].uid,2)
end)

test("LOCAL progress waits for movement and appends a clear target approach without another search",function()
  local ship=localShip()
  activateLocal(ship)
  local navigation=ship.localNavigation
  local originalPath,originalWindow=navigation.Path,navigation.Window
  local dispatches=#ship.dispatches
  for i=1,3 do timerNow=i*10 ship:_CheckLocalNavigation() end
  equal(ship.localNavigation,navigation) equal(#ship.dispatches,dispatches)
  near(navigation.Progress or 0,0) equal(ship.currentwp,1)
  local endpoint=navigation.Path[#navigation.Path]
  local previous=navigation.Path[#navigation.Path-1]
  local astar=searches.astar
  followPath(ship,navigation.Path)
  ship.heading=previous:GetHeadingTo(endpoint)
  ship.turningHeading=ship.heading ship.turningTime=timerNow
  timerNow=timerNow+10 ship:_CheckLocalNavigation()
  assert(ship.localNavigation.Path~=originalPath,"the checked target approach must extend the route")
  assert(#ship.dispatches>dispatches) equal(ship.currentwp,1)
  equal(ship.localNavigation.Window,originalWindow) equal(searches.astar,astar)
  near(ship.LastPathfindingResult.TargetApproachDistance,5000)
  near(ship.localNavigation.Path[1].x,endpoint.x) near(ship.localNavigation.Path[1].z,endpoint.z)
end)

test("LOCAL exact-goal routes have no waypoint callback and advance only on actual arrival",function()
  local ship=localShip(1500)
  activateLocal(ship)
  local navigation=ship.localNavigation
  equal(navigation.GoalReached,true)
  equal(ship.dispatched[#ship.dispatched].uid,2)
  local originalTask=ship.waypoints[2].task
  for _,waypoint in ipairs(ship.dispatched) do
    equal(#waypoint.task.params.tasks,0)
  end
  equal(ship.currentwp,1) equal(ship.passingEvents,nil)
  timerNow=10 ship:_CheckLocalNavigation()
  equal(ship.currentwp,1) equal(ship.passingEvents,nil)
  followPath(ship,navigation.Path)
  timerNow=20 ship:_CheckNavigation()
  equal(ship.currentwp,2) equal(ship.passingEvents,1)
  equal(ship.waypoints[2].npassed,1) equal(ship.waypoints[2].task,originalTask)
  timerNow=30 ship:_CheckNavigation()
  equal(ship.currentwp,2) equal(ship.passingEvents,1) equal(ship.waypoints[2].npassed,1)
end)

test("LOCAL preserves queued tasks at intermediate and final mission waypoints",function()
  for _,final in ipairs({false,true}) do
    local ship=localShip(1500)
    if final then table.remove(ship.waypoints,3) end
    local task=queueWaypointTask(ship)
    local future
    if not final then
      future=deepcopy(task) future.id=2 future.waypoint=3
      ship.taskqueue[#ship.taskqueue+1]=future
    end
    activateLocal(ship)
    local navigation=ship.localNavigation
    local dispatches=#ship.dispatches
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
    ship:FlushUpdate()
    if final then equal(#ship.dispatches,dispatches)
    else
      assert(#ship.dispatches>dispatches) equal(ship.localNavigation,nil)
      equal(ship.dispatched[2].uid,3) equal(future.status,OPSGROUP.TaskStatus.SCHEDULED)
    end
    equal(ship.taskSubmissions,1)
  end
end)

test("LOCAL FullStop cancels the task-startup guard so a later Cruise can proceed",function()
  local ship=localShip(1500)
  local task=queueWaypointTask(ship)
  activateLocal(ship)
  followPath(ship,ship.localNavigation.Path)
  timerNow=10 ship:_CheckNavigation()
  equal(ship.taskSubmissions,1) equal(ship.localNavigationTaskUID,2)
  equal(task.status,OPSGROUP.TaskStatus.SCHEDULED) equal(ship.currentwp,2)
  ship:FullStop()
  equal(ship.localNavigationTaskUID,nil) equal(ship.state,"Holding")
  local dispatches=#ship.dispatches
  ship:Cruise(14) ship:FlushUpdate()
  equal(ship.state,"Cruising") equal(ship.localNavigation,nil) equal(ship.dispatched[2].uid,3)
  assert(#ship.dispatches>dispatches)
  equal(task.status,OPSGROUP.TaskStatus.SCHEDULED) equal(ship.taskSubmissions,1)
end)

test("LOCAL resumes the ordinary route after a waypoint synchronously starts a mission task",function()
  local ship=localShip(1500)
  local task=queueWaypointTask(ship)
  task.ismission=true
  function ship:TaskExecute(value)
    self.taskcurrent=value.id value.status=OPSGROUP.TaskStatus.EXECUTING
  end
  activateLocal(ship)
  local dispatches=#ship.dispatches
  followPath(ship,ship.localNavigation.Path)
  timerNow=10 ship:_CheckNavigation()
  equal(ship.currentwp,2) equal(ship.taskcurrent,1) equal(ship.localNavigation,nil)
  equal(ship.localNavigationTaskUID,2) equal(ship.pendingUpdate,nil) equal(#ship.dispatches,dispatches)
  timerNow=20 ship:_CheckNavigation()
  equal(ship.localNavigationTaskUID,2) equal(ship.pendingUpdate,nil) equal(#ship.dispatches,dispatches)
  task.status=OPSGROUP.TaskStatus.DONE ship.taskcurrent=0
  timerNow=30 ship:_CheckNavigation()
  assert(ship.pendingUpdate,"finishing a synchronous waypoint mission task must resume the route")
  ship:FlushUpdate()
  equal(ship.localNavigationTaskUID,nil) equal(ship.localNavigation,nil)
  equal(ship.dispatched[2].uid,3) equal(#ship.dispatches,dispatches+1)
end)

test("LOCAL turning keeps checking depth without repeatedly replacing the route",function()
  local ship=localShip()
  activateLocal(ship)
  ship.turningHeading=ship.heading ship.turningTime=0
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
  activateLocal(ship)
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
  activateLocal(ship)
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
  activateLocal(ship)
  local navigation=ship.localNavigation
  local endpoint=navigation.Path[#navigation.Path]
  followPath(ship,navigation.Path)
  ship.turning=true
  ship:_CheckLocalNavigation()
  equal(ship.state,"Holding") equal(ship.stops,1)
  equal(ship.LastPathfindingResult.StopReason,"local_route_exhausted_in_turn")
  equal(ship.dispatched[1].speed,0)
end)

-- Begin recovery tests with a known installed 3 km route. Search outcomes can then be varied
-- independently of progress, while production depth checks, preparation and submission stay active.
local function extensionShip()
  local ship=localShip()
  function ship:_PlanLocalPath()
    return {Points={VECTOR:New(1000,0,0),VECTOR:New(2000,0,0),VECTOR:New(3000,0,0)},GoalReached=false}
  end
  assert(activateLocal(ship))
  ship._PlanLocalPath=nil
  ship.position={x=1200,y=0,z=0}
  return ship
end

test("LOCAL failed anchor extension recovers with a real search from the ship and a fresh window",function()
  local ship=extensionShip()
  local navigation=ship.localNavigation
  local oldPath=navigation.Path
  local dispatches=#ship.dispatches
  local attempts=0
  function ship:_ExtendLocalRoute()
    attempts=attempts+1
    navigation.Window={failedAnchor=true}
    return nil,nil,"connections_blocked"
  end
  local logs={}
  function ship:I(message) logs[#logs+1]=message end

  assert(ship:_CheckLocalNavigation())

  equal(attempts,1) equal(ship.stops,0) equal(#ship.dispatches,dispatches+1)
  assert(searches.astar>0) assert(navigation.Path~=oldPath)
  near(navigation.Window.Origin.x,1200) near(navigation.Window.Origin.z,0)
  near(navigation.Path[1].x,1200) near(navigation.Path[1].z,0)
  equal(navigation.ExtensionFailure,nil) equal(navigation.TargetUID,2)
  equal(ship.currentwp,1) equal(ship.waypoints[2].npassed,0)
  local failure=ship.LastPathfindingResult.ExtensionFailure
  equal(failure.Reason,"connections_blocked") near(failure.Remaining,1800) near(failure.Reserve,700)
  equal(failure.ReplacementReason,nil)
  assertClearPath(ship,navigation.Path)
  assert(logs[1]:find("replan from ship",1,true))
end)

test("LOCAL failed continuation keeps the checked route, retries after movement and stops at reserve",function()
  local ship=extensionShip()
  local navigation=ship.localNavigation
  local path,route=navigation.Path,ship.dispatched
  local extensions,replacements=0,0
  function ship:_ExtendLocalRoute() extensions=extensions+1 return nil,nil,"connections_blocked" end
  function ship:_PlanLocalPath(start,heading)
    replacements=replacements+1
    near(start.x,self.position.x) near(start.z,self.position.z) near(heading,self.heading)
    return nil,"no_local_exit"
  end

  assert(ship:_CheckLocalNavigation())
  equal(extensions,1) equal(replacements,1) equal(ship.stops,0)
  equal(navigation.Path,path) equal(ship.dispatched,route)
  near(navigation.ExtensionFailure.Remaining,1800)
  equal(navigation.ExtensionFailure.ReplacementReason,"no_local_exit")
  local queries=ship.terrain.queries
  for i=1,4 do timerNow=timerNow+10 assert(ship:_CheckLocalNavigation()) end
  equal(extensions,1) equal(replacements,1) assert(ship.terrain.queries>queries)

  ship.position.x=1449
  assert(ship:_CheckLocalNavigation()) equal(extensions,1)
  ship.position.x=1450
  assert(ship:_CheckLocalNavigation()) equal(extensions,2) equal(replacements,2)
  equal(ship.dispatched,route) equal(navigation.Path,path)

  -- A failed attempt just above the reserve must not delay the final decision by another 250 m.
  ship.position.x=2290
  assert(ship:_CheckLocalNavigation()) equal(extensions,3) equal(ship.stops,0)
  ship.position.x=2300
  equal(ship:_CheckLocalNavigation(),false)
  equal(extensions,4) equal(replacements,4) equal(ship.stops,1)
  equal(ship.LastPathfindingResult.StopReason,"local_route_exhausted")
  near(ship.LastPathfindingResult.Remaining,700) near(ship.LastPathfindingResult.Reserve,700)
  equal(ship.LastPathfindingResult.ExtensionFailure.ReplacementReason,"no_local_exit")
  equal(ship.dispatched[1].speed,0)
  for i=1,3 do ship:_CheckLocalNavigation() end
  equal(extensions,4) equal(replacements,4) equal(ship.stops,1)
end)

test("LOCAL failed extension during a turn waits, then replans without requiring more progress",function()
  local ship=extensionShip()
  local navigation=ship.localNavigation
  local path,route=navigation.Path,ship.dispatched
  local extensions=0
  function ship:_ExtendLocalRoute() extensions=extensions+1 return nil,nil,"connections_blocked" end
  local planner=ship._PlanLocalPath
  function ship:_PlanLocalPath(start,heading,target,speed)
    assert(not self:IsTurning(),"actual-position replanning must wait for a stable course")
    return planner(self,start,heading,target,speed)
  end
  ship.turning=true

  assert(ship:_CheckLocalNavigation())
  equal(ship.stops,0) equal(ship.dispatched,route) equal(navigation.Path,path)
  equal(searches.astar,0) equal(navigation.ExtensionFailure.AwaitingStraight,true)
  assert(ship:_CheckLocalNavigation()) equal(extensions,1)

  ship.turning=false
  assert(ship:_CheckLocalNavigation())
  equal(extensions,1) assert(searches.astar>0)
  equal(ship.stops,0) assert(ship.dispatched~=route) equal(navigation.ExtensionFailure,nil)
end)

test("LOCAL deferred extension cannot use its reserve while still turning",function()
  local ship=extensionShip()
  function ship:_ExtendLocalRoute() return nil,nil,"connections_blocked" end
  function ship:_PlanLocalPath() error("do not replace a turning route") end
  ship.turning=true
  assert(ship:_CheckLocalNavigation()) equal(ship.stops,0)
  ship.position.x=2300
  equal(ship:_CheckLocalNavigation(),false)
  equal(ship.stops,1) equal(ship.LastPathfindingResult.StopReason,"local_route_exhausted_in_turn")
  near(ship.LastPathfindingResult.Reserve,700)
  equal(ship.LastPathfindingResult.ExtensionFailure.Reason,"connections_blocked")
end)

test("LOCAL deferred failure still stops immediately on shallow position or missing route data",function()
  for _,failure in ipairs({"shallow","unavailable"}) do
    local ship=extensionShip()
    function ship:_ExtendLocalRoute() return nil,nil,"connections_blocked" end
    function ship:_PlanLocalPath() return nil,"no_local_exit" end
    assert(ship:_CheckLocalNavigation()) equal(ship.stops,0)
    function ship:_PlanLocalPath() error("depth failure must stop before another search") end
    if failure=="shallow" then ship.terrain.depth=5
    else ship.terrain.makeProfile=function() return nil end end
    equal(ship:_CheckLocalNavigation(),false)
    equal(ship.stops,1)
    equal(ship.LastPathfindingResult.DepthCheck.Status,failure=="shallow" and "blocked" or "unavailable")
  end
end)

test("LOCAL reserve after deferred failure includes actual speed above the commanded speed",function()
  local ship=extensionShip()
  function ship:_ExtendLocalRoute() return nil,nil,"connections_blocked" end
  function ship:_PlanLocalPath() return nil,"no_local_exit" end
  assert(ship:_CheckLocalNavigation())
  ship.velocity=20
  ship.position.x=1600
  equal(ship:_CheckLocalNavigation(),false)
  equal(ship.stops,1) near(ship.LastPathfindingResult.Remaining,1400)
  near(ship.LastPathfindingResult.Reserve,1400)
end)

test("LOCAL incomplete replacement preserves the existing route without submitting partial points",function()
  local ship=extensionShip()
  local route=ship.dispatched
  local path=ship.localNavigation.Path
  ship.terrain.depthAt=function(point) return point.x>=3500 and point.x<=3600 and 5 or 40 end
  function ship:_ExtendLocalRoute() return nil,nil,"connections_blocked" end
  local calls=0
  function ship:_PlanLocalPath(start)
    calls=calls+1
    if calls==1 then return {Points={VECTOR:New(start.x+500,0,0)},GoalReached=false} end
    return nil,"no_local_exit"
  end

  assert(ship:_CheckLocalNavigation())

  equal(calls,2) equal(ship.stops,0) equal(ship.dispatched,route) equal(ship.localNavigation.Path,path)
  equal(ship.localNavigation.ExtensionFailure.ReplacementReason,"no_local_exit")
end)

test("LOCAL extension recovery respects a hold or target change during planning",function()
  for _,change in ipairs({"hold","target"}) do
    local ship=extensionShip()
    local route=ship.dispatched
    function ship:_ExtendLocalRoute() return nil,nil,"connections_blocked" end
    function ship:_PlanLocalPath()
      if change=="hold" then self:FullStop()
      else self:_ResetLocalNavigation() self:_SetNavigationWaypoint(self.waypoints[3]) end
      return nil,"no_local_exit"
    end
    equal(ship:_CheckLocalNavigation(),false)
    equal(ship.localNavigation,nil)
    if change=="hold" then equal(ship.stops,1) equal(ship.dispatched[1].speed,0)
    else equal(ship.stops,0) equal(ship.dispatched,route) equal(ship:_GetNavigationWaypoint().uid,3) end
  end
end)

test("LOCAL unavailable depth and planning failures stop once without timer-driven recovery",function()
  for _,failure in ipairs({"profile","budget"}) do
    local ship=localShip()
    if failure=="profile" then ship.terrain.makeProfile=function() return nil end
    else ship:SetPathfindingGrid(1) end
    activateLocal(ship)
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

test("LOCAL FullStop remains authoritative over actual arrival and later clear water",function()
  local ship=localShip(1500)
  activateLocal(ship)
  ship:FullStop()
  local dispatches=#ship.dispatches
  ship.position=ship.waypoints[2].coordinate:GetVec3()
  timerNow=600 ship:_CheckNavigation()
  equal(ship.state,"Holding") equal(ship.stops,1) equal(ship.cruises,0)
  equal(ship.currentwp,1) equal(ship.passingEvents,nil) equal(#ship.dispatches,dispatches)
  ship:Cruise(14) ship:FlushUpdate() ship:FlushUpdate()
  equal(ship.state,"Cruising") assert(#ship.dispatches>dispatches)
end)

test("LOCAL waiting and another task's movement suppress planning and dispatch",function()
  for _,owner in ipairs({"waiting","task","completed"}) do
    local ship=localShip()
    activateLocal(ship)
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

test("LOCAL explicit waypoint selection and movement commands persist until collision activates that target",function()
  local ship=localShip()
  forbidGlobalPlanner(ship)
  ship.waypoints[3].coordinate=coord(0,30000)
  ship.waypoints[3].x,ship.waypoints[3].y=0,30000
  ship.heading=90
  ship:onafterUpdateRoute(nil,nil,nil,3,nil,14,40)
  equal(ship.localNavigation,nil) equal(ship.currentwp,1)
  equal(#ship.dispatched,2) equal(ship.dispatched[2].uid,3)
  timerNow=10 ship:_CheckNavigation()
  equal(ship.localNavigation,nil) assertNoSearch()
  ship.terrain.depthAt=function(point) return point.y>=1450 and point.y<=1550 and math.abs(point.x)<=200 and 5 or 40 end
  timerNow=20 ship:_CheckNavigation()
  local navigation=assert(ship.localNavigation)
  equal(navigation.TargetUID,3) equal(ship.currentwp,1)
  for _,waypoint in ipairs(ship.dispatched) do
    near(waypoint.speed,UTILS.KnotsToMps(14)) near(waypoint.alt,-40)
    assert(waypoint.uid~=2 and waypoint.uid~=3)
  end
  timerNow=30 ship:_CheckNavigation()
  equal(ship.localNavigation,navigation) equal(navigation.TargetUID,3)
end)

test("WAYPOINT collision checks follow an explicit target across subsequent speed and depth updates",function()
  local ship=vessel()
  ship.waypoints[3].coordinate=coord(0,30000)
  ship.waypoints[3].x,ship.waypoints[3].y=0,30000
  local checked={}
  function ship:_CheckPathDepth(start,goal)
    checked[#checked+1]={x=goal.x,z=goal.z}
    return NAVYGROUP._CheckPathDepth(self,start,goal)
  end
  ship:onafterUpdateRoute(nil,nil,nil,3)
  equal(ship.dispatched[2].uid,3) equal(#ship.dispatched,2)
  timerNow=10 ship:_CheckNavigation()
  near(checked[1].x,0) near(checked[1].z,5000)
  ship:onafterUpdateRoute(nil,nil,nil,nil,nil,14,40)
  equal(ship.dispatched[2].uid,3) equal(#ship.dispatched,2)
  near(ship.dispatched[2].speed,UTILS.KnotsToMps(14)) near(ship.dispatched[2].alt,-40)
  timerNow=20 ship:_CheckNavigation()
  near(checked[#checked].x,0) near(checked[#checked].z,5000)
  equal(ship.currentwp,1) assertNoSearch()
end)

test("switching either search mode preserves the commanded native target and collision direction",function()
  for _,initial in ipairs({NAVYGROUP.PathfindingMode.WAYPOINT,NAVYGROUP.PathfindingMode.LOCAL}) do
    local ship=vessel():SetPathfindingMode(initial)
    ship.waypoints[3].coordinate=coord(0,30000)
    ship.waypoints[3].x,ship.waypoints[3].y=0,30000
    local checked
    function ship:_CheckPathDepth(start,goal)
      checked={x=goal.x,z=goal.z}
      return NAVYGROUP._CheckPathDepth(self,start,goal)
    end
    ship:onafterUpdateRoute(nil,nil,nil,3)
    ship:SetPathfindingMode(initial==NAVYGROUP.PathfindingMode.LOCAL and NAVYGROUP.PathfindingMode.WAYPOINT or NAVYGROUP.PathfindingMode.LOCAL)
    ship:FlushUpdate()
    timerNow=10 ship:_CheckNavigation()
    near(checked.x,0) near(checked.z,5000)
    ship:onafterUpdateRoute(nil,nil,nil,nil,nil,14)
    equal(ship.dispatched[2].uid,3) equal(#ship.dispatched,2)
    equal(ship.currentwp,1) equal(ship.localNavigation,nil) assertNoSearch()
  end
end)

test("a newly inserted immediate target supersedes an old Goto in either search mode",function()
  for _,mode in ipairs({NAVYGROUP.PathfindingMode.WAYPOINT,NAVYGROUP.PathfindingMode.LOCAL}) do
    local ship=vessel():SetPathfindingMode(mode)
    ship.waypoints[3].coordinate=coord(0,30000)
    ship.waypoints[3].x,ship.waypoints[3].y=0,30000
    ship:onafterUpdateRoute(nil,nil,nil,3)
    local inserted=ship:AddWaypoint(coord(1000,2000),14,1,nil,false)
    ship:onafterUpdateRoute()
    equal(ship.dispatched[2].uid,inserted.uid)
    equal(ship.dispatched[3].uid,2) equal(ship.dispatched[4].uid,3)
    equal(ship:_GetNavigationWaypoint(),inserted)
    equal(ship.currentwp,1) equal(ship.localNavigation,nil) assertNoSearch()
  end
end)

test("an inserted immediate target retires an active LOCAL detour commanded toward a later waypoint",function()
  local ship=localShip()
  ship.waypoints[3].coordinate=coord(0,30000)
  ship.waypoints[3].x,ship.waypoints[3].y=0,30000
  ship.heading=90
  ship:onafterUpdateRoute(nil,nil,nil,3)
  activateLocal(ship,nil,nil,3)
  equal(assert(ship.localNavigation).TargetUID,3)
  local grids,astar=searches.grids,searches.astar
  local inserted=ship:AddWaypoint(coord(1000,2000),14,1,nil,false)
  ship:onafterUpdateRoute()
  ship:FlushUpdate()
  equal(ship.localNavigation,nil) equal(ship.dispatched[2].uid,inserted.uid)
  equal(ship.dispatched[3].uid,2) equal(ship.dispatched[4].uid,3)
  equal(ship:_GetNavigationWaypoint(),inserted) equal(ship.currentwp,1)
  equal(searches.grids,grids) equal(searches.astar,astar)
end)

test("leaving an active LOCAL detour preserves its explicitly commanded original target",function()
  local ship=localShip()
  ship.waypoints[3].coordinate=coord(0,30000)
  ship.waypoints[3].x,ship.waypoints[3].y=0,30000
  ship.heading=90
  ship:onafterUpdateRoute(nil,nil,nil,3)
  activateLocal(ship,nil,nil,3)
  equal(assert(ship.localNavigation).TargetUID,3)
  ship:SetPathfindingMode(NAVYGROUP.PathfindingMode.WAYPOINT)
  equal(ship.localNavigation,nil)
  ship:FlushUpdate()
  equal(ship.dispatched[2].uid,3) equal(#ship.dispatched,2)
  equal(ship:_GetNavigationWaypoint().uid,3) equal(ship.currentwp,1)
end)

test("removing the explicitly commanded waypoint restores the actual remaining route",function()
  for _,mode in ipairs({NAVYGROUP.PathfindingMode.WAYPOINT,NAVYGROUP.PathfindingMode.LOCAL}) do
    local ship=vessel():SetPathfindingMode(mode)
    ship:onafterUpdateRoute(nil,nil,nil,3)
    ship:RemoveWaypointByID(3)
    ship:onafterUpdateRoute()
    equal(ship.dispatched[2].uid,2) equal(#ship.dispatched,2)
    equal(ship:_GetNavigationWaypoint().uid,2) equal(ship.currentwp,1)
    assertNoSearch()
  end
end)

test("collision warning callbacks that insert a new target cancel the stale search in either mode",function()
  for _,mode in ipairs({NAVYGROUP.PathfindingMode.WAYPOINT,NAVYGROUP.PathfindingMode.LOCAL}) do
    local ship=vessel():SetPathfindingMode(mode)
    ship.waypoints[3].coordinate=coord(0,30000)
    ship.waypoints[3].x,ship.waypoints[3].y=0,30000
    ship.heading=90
    ship.terrain.depthAt=function(point) return point.y>=4450 and point.y<=4550 and 5 or 40 end
    local replacement
    function ship:OnAfterCollisionWarning()
      replacement=self:AddWaypoint(coord(10000,0),14,1,nil,false)
      self:onafterUpdateRoute()
    end
    ship:onafterUpdateRoute(nil,nil,nil,3)
    ship:_CheckNavigation()
    equal(ship.warnings,1) equal(ship.stops,0) equal(ship.localNavigation,nil)
    equal(ship.dispatched[2].uid,replacement.uid) equal(ship:_GetNavigationWaypoint(),replacement)
    assertNoSearch()
    timerNow=10 ship:_CheckNavigation()
    equal(ship.localNavigation,nil) equal(ship.stops,0) assertNoSearch()
  end
end)

test("the real WAYPOINT planner searches and installs the commanded target without restoring skipped points",function()
  local ship=vessel()
  ship.waypoints[3].coordinate=coord(0,15000)
  ship.waypoints[3].x,ship.waypoints[3].y=0,15000
  ship.heading=90
  ship.terrain.depthAt=function(point)
    return point.y>=2450 and point.y<=2550 and math.abs(point.x)<=350 and 5 or 40
  end
  ship:onafterUpdateRoute(nil,nil,nil,3,nil,14)
  ship:_CheckNavigation()
  assert(searches.astar>0,"obstruction must invoke the production full-route planner")
  near(searches.lastAstar.endVector.x,0) near(searches.lastAstar.endVector.z,15000)
  equal(ship.LastPathfindingResult.StopReason,"path_found") equal(ship.stops,0)
  assert(ship.pendingUpdate,"a successful search must submit its detour")
  ship:FlushUpdate()
  local nodes,points=0,{}
  for i,waypoint in ipairs(ship.dispatched) do
    assert(waypoint.uid~=2,"the route reintroduced an original waypoint explicitly skipped by Goto")
    if waypoint.astar then nodes=nodes+1 equal(waypoint.astarTargetUID,3) end
    if i>1 then points[#points+1]={x=waypoint.x,y=waypoint.alt or 0,z=waypoint.y} end
  end
  assert(nodes>0,"fixture must create intermediate avoidance waypoints")
  equal(ship.dispatched[#ship.dispatched].uid,3)
  equal(ship:GetWaypointByID(2).uid,2)
  equal(ship:_GetNavigationWaypoint().uid,ship.dispatched[2].uid)
  near(ship.dispatched[#ship.dispatched].speed,UTILS.KnotsToMps(14))
  assertClearPath(ship,points)

  -- Native callbacks remove each temporary point. Collision checks and later speed commands
  -- must still follow the installed detour, without returning to the skipped original UID 2.
  local route=ship.dispatched
  for i=2,#route-1 do
    local waypoint=route[i]
    ship.position={x=waypoint.x,y=waypoint.alt or 0,z=waypoint.y}
    OPSGROUP._PassingWaypoint(ship,waypoint.uid)
    equal(ship:_GetNavigationWaypoint().uid,route[i+1].uid)
    ship:onafterUpdateRoute(nil,nil,nil,nil,nil,12)
    equal(ship.dispatched[2].uid,route[i+1].uid)
    for _,remaining in ipairs(ship.dispatched) do
      assert(remaining.uid~=2,"a temporary callback restored the skipped original UID 2")
    end
  end
  equal(ship:_GetNavigationWaypoint().uid,3)
  equal(ship:GetWaypointByID(2).npassed,0)
end)

test("a finite Goto to the first waypoint plans before that target and preserves callback progression",function()
  local ship=vessel()
  ship.currentwp=2
  ship.position={x=15000,y=0,z=0}
  ship.heading=180
  ship.terrain.depthAt=function(point)
    return point.x>=12450 and point.x<=12550 and math.abs(point.y)<=350 and 5 or 40
  end
  ship:onafterUpdateRoute(nil,nil,nil,1)
  equal(ship.dispatched[2].uid,1)
  ship:_CheckNavigation()
  equal(ship.stops,0) equal(ship.LastPathfindingResult.StopReason,"path_found")
  near(searches.lastAstar.endVector.x,0) near(searches.lastAstar.endVector.z,0)
  equal(ship:GetWaypointCurrentUID(),2)
  ship:FlushUpdate()
  local route=ship.dispatched
  assert(route[2].astar,"fixture must install a temporary point before the original first waypoint")
  equal(ship.waypoints[1].uid,route[2].uid)
  local targetIndex
  for i,waypoint in ipairs(route) do
    if waypoint.uid==1 then targetIndex=i break end
  end
  assert(targetIndex and targetIndex>2)
  for i=2,targetIndex-1 do
    local waypoint=route[i]
    ship.position={x=waypoint.x,y=waypoint.alt or 0,z=waypoint.y}
    OPSGROUP._PassingWaypoint(ship,waypoint.uid)
    equal(ship:_GetNavigationWaypoint().uid,route[i+1].uid)
    ship:onafterUpdateRoute()
    equal(ship.dispatched[2].uid,route[i+1].uid)
  end
  equal(ship:_GetNavigationWaypoint().uid,1)
  equal(ship:GetWaypointByID(1).npassed,0)
  ship.position=ship:GetWaypointByID(1).coordinate:GetVec3()
  OPSGROUP._PassingWaypoint(ship,1)
  equal(ship:GetWaypointByID(1).npassed,1)
  equal(ship:_GetNavigationWaypoint().uid,2)
  ship:onafterUpdateRoute()
  equal(ship.dispatched[2].uid,2)
end)

test("a patrolling ship can explicitly return to the first waypoint before reaching the final one",function()
  local ship=vessel()
  ship.currentwp=2 ship.adinfinitum=true
  ship.position={x=15000,y=0,z=0} ship.heading=180
  ship.terrain.depthAt=function(point)
    return point.x>=12450 and point.x<=12550 and math.abs(point.y)<=350 and 5 or 40
  end
  ship:onafterUpdateRoute(nil,nil,nil,1)
  ship:_CheckNavigation()
  equal(ship.stops,0) equal(ship.LastPathfindingResult.StopReason,"path_found")
  ship:FlushUpdate()
  local route=ship.dispatched
  assert(route[2].astar)
  local targetIndex
  for i=2,#route do
    local waypoint=route[i]
    if waypoint.uid==1 then targetIndex=i break end
    assert(waypoint.astar,"a future original waypoint interrupted the commanded detour back to UID 1")
  end
  assert(targetIndex,"the submitted detour must include its explicitly commanded UID 1")
  for i=2,targetIndex-1 do
    local waypoint=route[i]
    ship.position={x=waypoint.x,y=waypoint.alt or 0,z=waypoint.y}
    OPSGROUP._PassingWaypoint(ship,waypoint.uid)
    equal(ship:_GetNavigationWaypoint().uid,route[i+1].uid)
  end
  equal(ship:_GetNavigationWaypoint().uid,1)
  ship.position=ship:GetWaypointByID(1).coordinate:GetVec3()
  OPSGROUP._PassingWaypoint(ship,1)
  equal(ship:GetWaypointByID(1).npassed,1)
  equal(ship:_GetNavigationWaypoint().uid,2)
  ship:onafterUpdateRoute()
  equal(ship.dispatched[2].uid,2)
end)

test("a patrol Goto from the final waypoint to UID 2 does not insert an unplanned wrap through UID 1",function()
  local ship=vessel()
  ship.currentwp=3 ship.adinfinitum=true
  ship.position={x=30000,y=0,z=0} ship.heading=180
  ship.terrain.depthAt=function(point)
    return point.x>=27450 and point.x<=27550 and math.abs(point.y)<=350 and 5 or 40
  end
  ship:onafterUpdateRoute(nil,nil,nil,2)
  ship:_CheckNavigation()
  equal(ship.stops,0) equal(ship.LastPathfindingResult.StopReason,"path_found")
  near(searches.lastAstar.endVector.x,20000) near(searches.lastAstar.endVector.z,0)
  equal(ship:GetWaypointCurrentUID(),3)
  ship:FlushUpdate()
  local route=ship.dispatched
  assert(route[2].astar)
  local targetIndex,points=nil,{}
  for i=2,#route do
    local waypoint=route[i]
    assert(waypoint.uid~=1,"the native route inserted an unplanned patrol wrap through UID 1")
    if not targetIndex then
      points[#points+1]={x=waypoint.x,y=waypoint.alt or 0,z=waypoint.y}
      if not waypoint.astar then
        equal(waypoint.uid,2)
        targetIndex=i
      end
    end
  end
  assert(targetIndex,"the commanded original UID 2 must occur after its temporary detour")
  assertClearPath(ship,points)
  for i=2,targetIndex-1 do
    local waypoint=route[i]
    ship.position={x=waypoint.x,y=waypoint.alt or 0,z=waypoint.y}
    OPSGROUP._PassingWaypoint(ship,waypoint.uid)
    equal(ship:_GetNavigationWaypoint().uid,route[i+1].uid)
  end
  equal(ship:_GetNavigationWaypoint().uid,2)
  ship.position=ship:GetWaypointByID(2).coordinate:GetVec3()
  OPSGROUP._PassingWaypoint(ship,2)
  equal(ship:_GetNavigationWaypoint().uid,3)
end)

test("LOCAL retargeting discards the old route and window without advancing mission progress",function()
  local ship=localShip(1500)
  activateLocal(ship)
  ship.waypoints[2].coordinate=coord(30000,5000)
  ship.waypoints[2].x,ship.waypoints[2].y=30000,5000
  ship:onafterUpdateRoute()
  ship:FlushUpdate()
  equal(ship.localNavigation,nil)
  equal(ship.dispatched[2].uid,2) near(ship.dispatched[2].x,30000) near(ship.dispatched[2].y,5000)
  equal(ship.currentwp,1) equal(ship.passingEvents,nil)
  timerNow=10 ship:_CheckNavigation()
  equal(ship.localNavigation,nil)
end)

test("LOCAL explicit selection of another target retires the active detour until a fresh obstacle",function()
  local ship=localShip()
  forbidGlobalPlanner(ship)
  activateLocal(ship)
  local grids,astar=searches.grids,searches.astar
  ship.waypoints[3].coordinate=coord(0,30000)
  ship.waypoints[3].x,ship.waypoints[3].y=0,30000
  ship:onafterUpdateRoute(nil,nil,nil,3)
  ship:FlushUpdate()
  equal(ship.localNavigation,nil) equal(#ship.dispatched,2) equal(ship.dispatched[2].uid,3)
  equal(ship.currentwp,1) equal(ship.passingEvents,nil)
  timerNow=10 ship:_CheckNavigation()
  equal(ship.localNavigation,nil) equal(searches.grids,grids) equal(searches.astar,astar)
  equal(ship.currentwp,1)
end)

test("LOCAL commanded speed and submarine depth survive periodic replanning",function()
  local ship=localShip()
  activateLocal(ship,14,40)
  local navigation=ship.localNavigation
  local originalPath=navigation.Path
  for _,waypoint in ipairs(ship.dispatched) do near(waypoint.speed,UTILS.KnotsToMps(14)) near(waypoint.alt,-40) end
  local endpoint=navigation.Path[#navigation.Path]
  followPath(ship,navigation.Path)
  ship.heading=navigation.Path[#navigation.Path-1]:GetHeadingTo(endpoint)
  ship.turningHeading=ship.heading ship.turningTime=0
  timerNow=10 ship:_CheckLocalNavigation()
  assert(ship.localNavigation.Path~=originalPath)
  for _,waypoint in ipairs(ship.dispatched) do near(waypoint.speed,UTILS.KnotsToMps(14)) near(waypoint.alt,-40) end
  near(ship.waypoints[2].speed,10) near(ship.waypoints[2].coordinate.y,0)
end)

test("LOCAL speed and depth commands received during a turn take effect once the heading stabilizes",function()
  local ship=localShip()
  activateLocal(ship)
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
    activateLocal(ship)
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

test("LOCAL replaces a blocked remainder from the ship instead of preserving the blocked approach",function()
  local ship=localShip()
  assert(activateLocal(ship))
  local navigation=ship.localNavigation
  local window=navigation.Window
  local dispatches=#ship.dispatches
  navigation.Pending={Points=navigation.Path,Plan={}}
  ship.terrain.depthAt=function(point)
    return point.x>=700 and point.x<=1200 and math.abs(point.y)<200 and 5 or 40
  end
  local logs={}
  function ship:I(message) logs[#logs+1]=message end

  assert(ship:_CheckLocalNavigation())

  equal(ship.stops,0) equal(#ship.dispatches,dispatches+1)
  equal(ship.localNavigation,navigation) equal(navigation.TargetUID,2)
  equal(navigation.Pending,nil) assert(navigation.Window~=window)
  near(navigation.Path[1].x,ship.position.x) near(navigation.Path[1].z,ship.position.z)
  assert(ship:_CheckLocalRoute(VECTOR:NewFromVec(ship.position)))
  local report=assert(ship.LastPathfindingResult.ReplanDepthCheck)
  equal(report.NavigationStage,"actual_position_to_next") equal(report.RouteSegment,1)
  equal(report.Cause,"insufficient_depth") equal(report.RequiredDepth,20)
  assert(logs[1]:find("action=replan",1,true))
  assert(logs[1]:find("required_depth=20",1,true))
end)

test("LOCAL shallow ship position stops with diagnostic evidence and no new search",function()
  local ship=localShip()
  assert(activateLocal(ship))
  local grids=searches.grids
  local logs={}
  function ship:I(message) logs[#logs+1]=message end
  ship.terrain.depth=9

  equal(ship:_CheckLocalNavigation(),false)

  equal(ship.stops,1) equal(searches.grids,grids)
  local report=ship.LastPathfindingResult.DepthCheck
  equal(report.NavigationStage,"ship_position") equal(report.Depth,9)
  equal(report.Reason,"start_blocked") equal(report.Cause,"insufficient_depth")
  near(report.Point.x,ship.position.x) near(report.Point.z,ship.position.z)
  assert(logs[1]:find("action=stop",1,true))
  assert(logs[1]:find("depth=9 m",1,true))
  ship:_CheckLocalNavigation() equal(ship.stops,1)
end)

test("LOCAL side-profile start is a blocked connector rather than a blocked ship position",function()
  local ship=localShip()
  assert(activateLocal(ship))
  ship.terrain.depthAt=function(point)
    return math.abs(point.x)<1 and math.abs(point.y-25)<1 and 5 or 40
  end
  local clear,reason,report=ship:_CheckLocalRoute(VECTOR:NewFromVec(ship.position))
  equal(clear,false) equal(reason,"start_blocked")
  equal(report.NavigationStage,"actual_position_to_next") near(math.abs(report.ProfileOffset),25)
  local attempted=false
  function ship:_PlanLocalPath(start)
    attempted=true near(start.x,self.position.x) near(start.z,self.position.z)
    return nil,"no_local_path"
  end
  equal(ship:_CheckLocalNavigation(),false)
  assert(attempted) equal(ship.stops,1)
  equal(ship.LastPathfindingResult.StopReason,"no_local_path")
  equal(ship.LastPathfindingResult.DepthCheck.Reason,"start_blocked")
end)

test("LOCAL unavailable remainder data and blocked turns stop without replanning",function()
  for _,failure in ipairs({"unavailable","turning"}) do
    local ship=localShip()
    assert(activateLocal(ship))
    if failure=="unavailable" then
      ship.terrain.makeProfile=function() return nil end
    else
      ship.turning=true
      ship.terrain.depthAt=function(point) return point.x>500 and 5 or 40 end
    end
    function ship:_PlanLocalPath() error("must not replan with unavailable data or during a turn") end

    equal(ship:_CheckLocalNavigation(),false)

    equal(ship.stops,1)
    local report=ship.LastPathfindingResult.DepthCheck
    equal(report.Status,failure=="unavailable" and "unavailable" or "blocked")
    equal(report.NavigationStage,failure=="unavailable" and "actual_position_to_next" or "stored_segment")
  end
end)

test("LOCAL replacement rejected at submission stops once without recursive planning",function()
  local ship=localShip()
  assert(activateLocal(ship))
  ship.terrain.depthAt=function(point) return point.x>500 and 5 or 40 end
  local attempts=0
  function ship:_PlanLocalPath()
    attempts=attempts+1
    return {Points={VECTOR:New(2500,0,0)},GoalReached=false}
  end

  equal(ship:_CheckLocalNavigation(),false)

  equal(attempts,1) equal(ship.stops,1)
  equal(ship.LastPathfindingResult.DepthCheck.NavigationStage,"submission_connector")
  ship:_CheckLocalNavigation() equal(attempts,1) equal(ship.stops,1)
end)

test("LOCAL collision callback can hold the ship before a replacement search starts",function()
  local ship=localShip()
  assert(activateLocal(ship))
  ship.terrain.depthAt=function(point) return point.x>500 and 5 or 40 end
  function ship:OnAfterCollisionWarning() self:FullStop() end
  function ship:_PlanLocalPath() error("manual stop must retain control") end

  equal(ship:_CheckLocalNavigation(),false)
  equal(ship.stops,1) equal(ship.state,"Holding")
end)

test("LOCAL exit checks only the ordinary horizon towards the goal and can detect a later island",function()
  local ship=localShip(10000)
  activateLocal(ship)
  ship.heading=90 -- The target check follows the goal direction, not the current heading.
  ship.terrain.depthAt=function(point) return point.x>=6000 and point.x<=6100 and math.abs(point.y)<=200 and 5 or 40 end
  local checked
  local check=ship._CheckPathDepth
  function ship:_CheckPathDepth(start,goal)
    checked={start=start,goal=goal}
    return check(self,start,goal)
  end
  function ship:_CheckLocalRoute() error("a clear target horizon must bypass further local checks") end

  ship:_CheckNavigation()

  equal(ship.localNavigation,nil) near(checked.goal.x,5000) near(checked.goal.z,0)
  equal(ship.dispatched[2].uid,2) equal(ship.currentwp,1)
  ship._CheckLocalRoute=nil
  ship.position={x=1600,y=0,z=0} ship.heading=0 ship.turningHeading=0
  local searchesBefore=searches.astar
  timerNow=10 ship:_CheckNavigation()
  equal(ship.localNavigation,nil) equal(searches.astar,searchesBefore) equal(ship.collisionwarning,true)
  ship.position={x=4000,y=0,z=0}
  timerNow=20 ship:_CheckNavigation()
  assert(ship.localNavigation) equal(ship.localNavigation.TargetUID,2)
end)

test("LOCAL exit retains the commanded target speed depth and queued waypoint tasks",function()
  local ship=localShip()
  activateLocal(ship,14,40,3)
  local target=ship.waypoints[3]
  local task={id=7,waypoint=3,type=OPSGROUP.TaskType.WAYPOINT,status=OPSGROUP.TaskStatus.SCHEDULED}
  ship.taskqueue={task}
  ship.localNavigation.Pending={Points={},Plan={}}

  ship:_CheckNavigation()

  equal(ship.localNavigation,nil) equal(ship.ispathfinding,false)
  equal(ship:_GetNavigationWaypoint(),target) equal(ship.dispatched[2].uid,3)
  equal(ship.currentwp,1) equal(ship.passingEvents,nil) equal(ship.taskqueue[1],task)
  for _,point in ipairs(ship.dispatched) do
    near(point.speed,UTILS.KnotsToMps(14)) near(point.alt,-40)
  end
  equal(target.speed,15) near(target.coordinate.y,0)
end)

test("LOCAL exit checks a nearby destination exactly and waits until a turn finishes",function()
  local ship=localShip(1500)
  activateLocal(ship)
  local navigation=ship.localNavigation
  ship.turning=true ship.turningHeading=0 ship.turningTime=0 ship.heading=10
  timerNow=10 ship:_CheckNavigation()
  equal(ship.localNavigation,navigation)
  local checked
  local check=ship._CheckPathDepth
  function ship:_CheckPathDepth(start,goal)
    checked=goal
    return check(self,start,goal)
  end
  timerNow=20 ship:_CheckNavigation()
  equal(ship:IsTurning(),false) equal(ship.localNavigation,nil)
  near(checked.x,1500) near(checked.z,0)
  equal(ship.currentwp,1) equal(ship.passingEvents,nil)
end)

test("LOCAL target horizon with unavailable depth stops instead of releasing avoidance",function()
  local ship=localShip()
  activateLocal(ship)
  ship.terrain.makeProfile=function(a,b)
    if distance(a,b)>1000 then return nil end
    return {{x=a.x,y=-40,z=a.z},{x=b.x,y=-40,z=b.z}}
  end
  ship:_CheckNavigation()
  equal(ship.stops,1) equal(ship.state,"Holding")
  equal(ship.LastPathfindingResult.DepthCheck.Status,"unavailable")
  equal(ship.LastPathfindingResult.DepthCheck.NavigationStage,"target_lookahead")
end)

test("LOCAL ClearAhead callbacks can stop or retarget before ordinary routing resumes",function()
  for _,action in ipairs({"stop","retarget"}) do
    local ship=localShip()
    activateLocal(ship)
    ship.collisionwarning=true
    function ship:OnAfterClearAhead()
      if action=="stop" then self:FullStop()
      else self:onafterUpdateRoute(nil,nil,nil,3) end
    end
    local dispatches=#ship.dispatches

    ship:_CheckNavigation()

    equal(ship.localNavigation,nil)
    if action=="stop" then
      equal(ship.stops,1) equal(ship.state,"Holding") equal(#ship.dispatches,dispatches+1)
      equal(ship.dispatched[1].speed,0)
    else
      equal(#ship.dispatches,dispatches) equal(ship:_GetNavigationWaypoint().uid,3)
      ship:FlushUpdate() equal(ship.dispatched[2].uid,3)
    end
  end
end)

test("LOCAL accepts a wide turning arc and then checks the real connector without stopping or resubmitting",function()
  local ship=localShip()
  assert(activateLocal(ship))
  local navigation=ship.localNavigation
  local dispatches=#ship.dispatches
  ship.position={x=50,y=0,z=350}
  ship.turning=true
  local logs,connections={},{}
  function ship:I(message) logs[#logs+1]=message end
  local check=ship._CheckPathDepth
  function ship:_CheckPathDepth(start,goal)
    connections[#connections+1]={start=start,goal=goal}
    return check(self,start,goal)
  end
  function ship:_PlanLocalPath() error("line deviation alone must not trigger replanning") end

  assert(ship:_CheckLocalNavigation())
  equal(ship.stops,0) equal(#ship.dispatches,dispatches)
  near(connections[1].start.z,350) near(connections[1].goal.z,350)
  equal(connections[2].start,navigation.Path[1])
  assert(logs[1]:find("segment=1, turning=true",1,true))
  local notices=#logs
  assert(ship:_CheckLocalNavigation()) equal(#logs,notices)

  ship.turning=false
  connections={}
  assert(ship:_CheckLocalNavigation())
  near(connections[2].start.x,50) near(connections[2].start.z,350)
  equal(connections[2].goal,navigation.Path[2])
  equal(ship.stops,0) equal(#ship.dispatches,dispatches)
  equal(#logs,notices+1) assert(logs[#logs]:find("turning=false",1,true))
  assert(ship.LastNavigationCheck.RouteDeviation>150)
end)

test("LOCAL wide turn still stops when the actual ship position is too shallow",function()
  local ship=localShip()
  assert(activateLocal(ship))
  ship.position={x=50,y=0,z=350} ship.turning=true
  ship.terrain.depthAt=function(point) return point.y>300 and 5 or 40 end
  equal(ship:_CheckLocalNavigation(),false)
  equal(ship.stops,1) equal(ship.LastPathfindingResult.StopReason,"start_blocked")
  equal(ship.LastPathfindingResult.DepthCheck.NavigationStage,"ship_position")
  assert(ship.LastPathfindingResult.DepthCheck.RouteDeviation>150)
end)

test("LOCAL replans a blocked actual connector after a wide turn",function()
  local ship=localShip()
  assert(activateLocal(ship))
  local navigation=ship.localNavigation
  ship.position={x=50,y=0,z=350} ship.turning=true
  -- The old line and ship position are deep, but the direct return towards the next point is not.
  ship.terrain.depthAt=function(point) return point.y>80 and point.y<270 and 5 or 40 end
  local attempts=0
  function ship:_PlanLocalPath(start,heading,target,speed)
    attempts=attempts+1
    near(start.x,50) near(start.z,350) equal(target,navigation.Target)
    return {Points={VECTOR:New(1000,0,350),VECTOR:New(2500,0,350)},GoalReached=false}
  end
  assert(ship:_CheckLocalNavigation()) equal(attempts,0)
  ship.turning=false
  assert(ship:_CheckLocalNavigation())
  equal(attempts,1) equal(ship.stops,0)
  local report=assert(ship.LastPathfindingResult.ReplanDepthCheck)
  equal(report.NavigationStage,"actual_position_to_next")
  equal(report.Cause,"insufficient_depth") assert(report.RouteDeviation>150)
  assert(ship:_CheckLocalRoute(VECTOR:NewFromVec(ship.position)))
end)

test("LOCAL candidate selection prefers usable length over a short exit closer to the goal",function()
  local ship=localShip()
  local short=VECTOR:New(500,0,866)
  local long=VECTOR:New(2600,0,0)
  local search={}
  function search:SetStartCoordinate(start) self.start=start end
  function search:SetEndCoordinate(goal) self.goal=goal end
  function search:_SearchPath()
    local nodes={}
    local count=math.ceil(self.start:GetDistance(self.goal,true)/100)
    for i=1,count do
      nodes[i]={vector=VECTOR:New(self.goal.x*i/count,0,self.goal.z*i/count)}
    end
    return nodes
  end
  local window={Search=search,Target=VECTOR:New(500,0,1500),Spacing=50,
    Grid={GetCandidateCount=function() return 100 end}}
  function ship:_GetLocalNavigationWindow() return window end
  function ship:_GetLocalNavigationCandidates()
    return {{Vector=short,GoalReached=false},{Vector=long,GoalReached=false}}
  end

  local plan=assert(ship:_PlanLocalPath(VECTOR:New(0,0,0),0,ship.waypoints[2],10))

  near(plan.Points[#plan.Points].x,long.x) near(plan.Points[#plan.Points].z,long.z)
  assert(plan.Length>=plan.RequiredLength) near(plan.InitialTurn,0)
  assertClearPath(ship,plan.Points)
end)

test("LOCAL prepares a target approach before submitting the observed short 63 degree turn at 27 knots",function()
  local ship=localShip()
  ship.heading=317.8
  local origin=VECTOR:NewFromVec(ship.position)
  local corner=origin:Translate(926,20.5,true)
  local exit=origin:Translate(1106,20.5,true)
  local calls=0
  function ship:_PlanLocalPath(start,heading,target,speed)
    calls=calls+1
    equal(#self.dispatches,0) -- The short route must never be sent on its own.
    if calls==1 then return {Points={corner,exit},GoalReached=false,Attempts=1} end
    near(start.x,exit.x) near(start.z,exit.z) near(heading,20.5)
    return NAVYGROUP._PlanLocalPath(self,start,heading,target,speed)
  end

  assert(activateLocal(ship,27))

  local navigation=ship.localNavigation
  equal(calls,1) equal(#ship.dispatches,1) equal(ship.stops,0)
  equal(ship.LastPathfindingResult.PreflightExtensions,0)
  near(ship.LastPathfindingResult.TargetApproachDistance,5000)
  near(ship.LastPathfindingResult.InitialTurn,62.7,0.01)
  assert(navigation.Length>=ship.LastPathfindingResult.RequiredLength)
  near(navigation.Path[2].x,corner.x) near(navigation.Path[2].z,corner.z)
  near(navigation.Path[3].x,exit.x) near(navigation.Path[3].z,exit.z)
  assertClearPath(ship,navigation.Path)

  -- Previously this much projected progress left less than the 60-second reserve.
  ship.position=origin:Translate(400,20.5,true):GetVec3()
  ship.turning=true
  assert(ship:_CheckLocalNavigation())
  equal(ship.stops,0) equal(#ship.dispatches,1)
end)

test("LOCAL bounded preflight stops rather than submitting a short route without a usable continuation",function()
  for _,failure in ipairs({"blocked","too_short","no_progress"}) do
    local ship=localShip()
    -- No target approach can bypass the bounded-continuation behavior under test.
    ship.terrain.depthAt=function(point) return point.x>=3500 and point.x<=3600 and 5 or 40 end
    local calls=0
    function ship:_PlanLocalPath(start,heading)
      calls=calls+1
      equal(#self.dispatches,0)
      if calls>1 and failure=="blocked" then return nil,"no_local_exit" end
      local step=(calls>1 and failure=="no_progress") and 0 or 500
      return {Points={start:Translate(step,heading,true)},GoalReached=false}
    end

    equal(activateLocal(ship),false)

    equal(calls,failure=="too_short" and 3 or 2)
    equal(ship.stops,1) equal(ship.state,"Holding") equal(#ship.dispatches,1)
    equal(ship.dispatched[1].speed,0)
    local expected=failure=="blocked" and "no_local_exit" or (failure=="too_short" and "local_route_too_short" or "no_progress")
    equal(ship.LastPathfindingResult.StopReason,expected)
  end
end)

test("LOCAL preflight may end at the true goal with less than the non-goal reserve",function()
  local ship=localShip(1000)
  local calls=0
  function ship:_PlanLocalPath(start)
    calls=calls+1
    if calls==1 then return {Points={VECTOR:New(500,0,0)},GoalReached=false} end
    near(start.x,500)
    return {Points={VECTOR:New(1000,0,0)},GoalReached=true}
  end

  assert(activateLocal(ship))

  equal(calls,1) equal(ship.localNavigation.GoalReached,true)
  near(ship.LastPathfindingResult.TargetApproachDistance,500)
  equal(ship.dispatched[#ship.dispatched].uid,2) equal(ship.currentwp,1)
  equal(ship.stops,0) equal(ship.passingEvents,nil)
end)

test("LOCAL revalidates appended preflight connections before issuing a route",function()
  local ship=localShip()
  ship.terrain.depthAt=function(point) return point.x>=3500 and point.x<=3600 and 5 or 40 end
  local calls=0
  function ship:_PlanLocalPath(start,heading)
    calls=calls+1
    if calls==1 then return {Points={VECTOR:New(1000,0,0)},GoalReached=false} end
    near(start.x,1000) near(heading,0)
    self.terrain.depthAt=function(point) return point.x>=1500 and point.x<=1700 and 5 or 40 end
    return {Points={VECTOR:New(2000,0,0),VECTOR:New(3000,0,0)},GoalReached=false}
  end

  equal(activateLocal(ship),false)

  equal(calls,2) equal(ship.stops,1) equal(#ship.dispatches,1)
  equal(ship.dispatched[1].speed,0)
  equal(ship.LastPathfindingResult.DepthCheck.Status,"blocked")
end)

test("LOCAL keeps the entire island detour when only its endpoint has a clear target horizon",function()
  local ship=localShip(20000)
  ship.terrain.depthAt=function(point)
    return point.x>=700 and point.x<=1200 and math.abs(point.y)<=600 and 5 or 40
  end
  local corners={VECTOR:New(400,0,800),VECTOR:New(1400,0,800),VECTOR:New(2000,0,800)}
  local searches=0
  function ship:_PlanLocalPath()
    searches=searches+1
    equal(searches,1,"the free endpoint must avoid another A* search")
    return {Points=corners,GoalReached=false}
  end
  assert(activateLocal(ship))
  local originalPath=ship.localNavigation.Path
  ship.position={x=240,y=0,z=480}
  ship.heading=VECTOR:New(0,0,0):GetHeadingTo(corners[1])
  assert(not ship:_CheckNavigationAhead(VECTOR:NewFromVec(ship.position),ship.waypoints[2]))
  assert(ship:_CheckNavigationAhead(corners[3],ship.waypoints[2]))

  ship:_CheckNavigation()

  local navigation=assert(ship.localNavigation)
  equal(searches,1) equal(#ship.dispatches,2) equal(ship.stops,0)
  equal(ship.currentwp,1) equal(ship.passingEvents,nil)
  for i,corner in ipairs(corners) do
    equal(navigation.Path[i+1],corner,"a planned corner was cut off")
  end
  near(ship.LastPathfindingResult.TargetApproachDistance,5000)
  equal(ship.LastPathfindingResult.RejoinPoint,corners[3])
  equal(navigation.GoalReached,false)
  assertClearPath(ship,navigation.Path)
  for _,point in ipairs(ship.dispatched) do assert(point.uid~=2 and point.uid~=3) end

  timerNow=10 ship:_CheckNavigation()
  equal(searches,1) equal(#ship.dispatches,2)

  -- Only after following the retained detour may the ordinary goal route take over.
  followPath(ship,navigation.Path,4)
  ship.heading=0 ship.turningHeading=0 ship.turningTime=timerNow
  timerNow=20 ship:_CheckNavigation()
  equal(ship.localNavigation,nil) equal(ship.dispatched[2].uid,2)
  equal(ship.currentwp,1) equal(ship.passingEvents,nil) equal(searches,1)
  assert(originalPath~=navigation.Path)
end)

test("LOCAL target approach prepared during a turn waits and preserves all remaining corners",function()
  local ship=localShip()
  assert(activateLocal(ship))
  local navigation=ship.localNavigation
  local original=navigation.Path
  local astar=searches.astar
  followPath(ship,original,2)
  ship.position={x=original[2].x+(original[3].x-original[2].x)*0.25,y=0,
    z=original[2].z+(original[3].z-original[2].z)*0.25}
  ship.heading=original[1]:GetHeadingTo(original[2])
  ship.turning=true
  local dispatches=#ship.dispatches

  assert(ship:_CheckLocalNavigation())

  local pending=assert(navigation.Pending)
  assert(pending.Plan.TargetApproachDistance)
  equal(navigation.Path,original) equal(#ship.dispatches,dispatches) equal(searches.astar,astar)
  for i=3,#original do equal(pending.Points[i-1],original[i]) end
  ship.turning=false
  assert(ship:_CheckLocalNavigation())
  equal(navigation.Pending,nil) equal(#ship.dispatches,dispatches+1) equal(searches.astar,astar)
  assertClearPath(ship,navigation.Path)
end)

test("LOCAL target approaches reject shallow or unavailable water and a reversal without modifying the route",function()
  for _,failure in ipairs({"shallow","missing","reversal"}) do
    local ship=localShip(failure=="reversal" and -20000 or 20000)
    assert(activateLocal(ship))
    if failure=="shallow" then
      ship.terrain.depthAt=function(point) return point.x>=4000 and point.x<=4100 and 19 or 40 end
    elseif failure=="missing" then
      ship.terrain.makeProfile=function() return nil end
    end
    local points={VECTOR:New(0,0,0),VECTOR:New(2000,0,0)}
    local plan={GoalReached=false}

    equal(ship:_AppendLocalTargetApproach(points,plan,0),false)

    equal(#points,2) equal(plan.RejoinPoint,nil) equal(plan.GoalReached,false)
    equal(ship.stops,0)
  end
end)

test("LOCAL rechecks the full target approach before movement when its depth has changed",function()
  local ship=localShip()
  function ship:_PlanLocalPath()
    return {Points={VECTOR:New(1000,0,0)},GoalReached=false}
  end
  function ship:_SubmitLocalRoute(position)
    self.terrain.depthAt=function(point) return point.x>=3500 and point.x<=3600 and 19 or 40 end
    return NAVYGROUP._SubmitLocalRoute(self,position)
  end

  equal(activateLocal(ship),false)

  equal(ship.stops,1) equal(#ship.dispatches,1) equal(ship.dispatched[1].speed,0)
  equal(ship.LastPathfindingResult.DepthCheck.NavigationStage,"stored_segment")
  equal(ship.LastPathfindingResult.DepthCheck.RequiredDepth,20)
end)

test("LOCAL blocked target checks log measured evidence and throttle unchanged causes",function()
  local ship=localShip()
  assert(activateLocal(ship))
  ship.terrain.depthAt=function(point) return point.x>=4500 and point.x<=4600 and 19 or 40 end
  local logs={}
  function ship:I(message) logs[#logs+1]=message end
  local profiles=ship.terrain.profiles

  equal(ship:_TryResumeWaypointRoute(),false)
  equal(#logs,3)
  assert(logs[1]:find("action=continue_local",1,true))
  assert(logs[1]:find("stage=target_lookahead",1,true))
  assert(logs[1]:find("depth=19",1,true))
  assert(logs[1]:find("required_depth=20",1,true))
  assert(logs[3]:find("target_uid=2",1,true))
  assert(logs[3]:find("check_from=(0.0, 0.0), check_to=(5000.0, 0.0)",1,true))
  equal(ship.terrain.profiles-profiles,3,"diagnostics must not repeat the center and side profiles")

  timerNow=10 equal(ship:_TryResumeWaypointRoute(),false) equal(#logs,3)
  timerNow=60 equal(ship:_TryResumeWaypointRoute(),false) equal(#logs,6)
  ship:SetPathfindingMinDepth(25)
  timerNow=61 equal(ship:_TryResumeWaypointRoute(),false) equal(#logs,9)
  local points={VECTOR:New(0,0,0),VECTOR:New(2000,0,0)}
  equal(ship:_AppendLocalTargetApproach(points,{},0),false) equal(#logs,12)
  assert(logs[10]:find("stage=route_end_lookahead",1,true))
  assert(logs[12]:find("check_from=(2000.0, 0.0)",1,true))
  equal(ship.stops,0)
end)

test("LOCAL uses a clear endpoint after the last allowed preflight window without a third search",function()
  local ship=localShip()
  ship.terrain.depthAt=function(point)
    return point.x>=800 and point.x<=1000 and math.abs(point.y)<=900 and 5 or 40
  end
  local exits={VECTOR:New(300,0,400),VECTOR:New(300,0,900),VECTOR:New(1250,0,1000)}
  local calls=0
  function ship:_PlanLocalPath()
    calls=calls+1
    assert(calls<=3,"only the initial search and two continuations are allowed")
    return {Points={exits[calls]},GoalReached=false}
  end

  assert(activateLocal(ship))

  equal(calls,3) equal(ship.LastPathfindingResult.PreflightExtensions,2)
  near(ship.LastPathfindingResult.TargetApproachDistance,5000)
  equal(ship.LastPathfindingResult.RejoinPoint,exits[3])
  equal(ship.stops,0) equal(#ship.dispatches,1)
  assertClearPath(ship,ship.localNavigation.Path)
end)

test("LOCAL depth preference is optional and invalidates only unused plans",function()
  local ship=localShip()
  local start=VECTOR:New(0,0,0)
  local first=assert(ship:_GetLocalNavigationWindow(start,0,ship.waypoints[2]))
  equal(first.Search.CostFunc,ASTAR.Dist2D)
  local path={start,VECTOR:New(2000,0,0)}
  ship.localNavigation.Path=path
  ship.localNavigation.Pending={Points={}}
  ship:SetPathfindingPreferredDepth(30,2)
  equal(ship.localNavigation.Path,path) equal(ship.localNavigation.Pending,nil)
  local second=assert(ship:_GetLocalNavigationWindow(start,0,ship.waypoints[2]))
  assert(second~=first) equal(second.Search.CostFunc,ASTAR.CostDepth)
  equal(second.Search.CostArg[1],20) equal(second.Search.CostArg[3],30) equal(second.Search.CostArg[4],2)
  equal(ship:_GetLocalNavigationWindow(start,0,ship.waypoints[2]),second)
  ship:SetPathfindingPreferredDepth()
  local third=assert(ship:_GetLocalNavigationWindow(start,0,ship.waypoints[2]))
  equal(third.Search.CostFunc,ASTAR.Dist2D)
  equal(ship.stops,0) equal(#ship.dispatches,0)
end)

test("LOCAL depth-weighted search and smoothing retain a deeper route around a permitted shoal",function()
  local ship=localShip(2000)
  ship.terrain.depthAt=function(p)
    return p.x>=500 and p.x<=1500 and math.abs(p.y)<=200 and 21 or 40
  end
  local start=VECTOR:New(0,0,0)
  local ordinary=assert(ship:_PlanLocalPath(start,0,ship.waypoints[2],10))
  for _,point in ipairs(ordinary.Points) do assert(math.abs(point.z)<100) end

  ship:SetPathfindingPreferredDepth(30,2)
  local plan,reason=ship:_PlanLocalPath(start,0,ship.waypoints[2],10)
  assert(plan,reason) assert(plan.GoalReached)
  assert(plan.Cost<ship:_GetPathfindingDepthCost(start,ship.waypoints[2].coordinate))
  local offshore=false
  for _,point in ipairs(plan.Points) do if math.abs(point.z)>200 then offshore=true end end
  assert(offshore,"smoothing erased the depth-weighted detour")
  near(plan.Points[#plan.Points].x,2000) near(plan.Points[#plan.Points].z,0)
  assertClearPath(ship,plan.Points)
end)

test("LOCAL candidate ranking retains depth costs after smoothing",function()
  local ship=localShip(20000)
  ship.terrain.depthAt=function(p) return p.x>200 and math.abs(p.y)<150 and 21 or 40 end
  local shallow,deep=VECTOR:New(2600,0,0),VECTOR:New(2400,0,1000)
  local search=ASTAR:New():SetValidNeighbourDepth(20,50)
  function search:SetStartCoordinate(start) self.startNode=self:AddNodeFromCoordinate(start) end
  function search:SetEndCoordinate(goal) self.goal=goal end
  -- Isolate exit selection: supply two feasible paths, retaining real depth costs and smoothing.
  function search:_SearchPath()
    local nodes={}
    for i=1,26 do nodes[i]=self:AddNodeFromCoordinate(VECTOR:New(self.goal.x*i/26,0,self.goal.z*i/26)) end
    return nodes
  end
  local window={Search=search,Target=VECTOR:New(20000,0,0),Spacing=50,Grid={GetCandidateCount=function() return 100 end}}
  function ship:_GetLocalNavigationWindow() return window end
  function ship:_GetLocalNavigationCandidates()
    return {{Vector=shallow,GoalReached=false},{Vector=deep,GoalReached=false}}
  end
  local start=VECTOR:New(0,0,0)
  local ordinary=assert(ship:_PlanLocalPath(start,0,ship.waypoints[2],10))
  near(ordinary.Points[#ordinary.Points].z,0)

  ship:SetPathfindingPreferredDepth(30,2)
  search:SetCostDepth(30,2)
  local weighted=assert(ship:_PlanLocalPath(start,0,ship.waypoints[2],10))
  near(weighted.Points[#weighted.Points].z,1000)
end)

test("LOCAL target release and target approach still require only minimum depth",function()
  local ship=localShip(12000):SetPathfindingPreferredDepth(30,2)
  assert(activateLocal(ship))
  ship.terrain.depth=21
  function ship:_GetPathfindingDepthCost() error("Direct target release must not consider preferred depth") end
  local navigation=ship.localNavigation
  local points={VECTOR:New(0,0,0),VECTOR:New(2000,0,0)}
  local report={}
  assert(ship:_AppendLocalTargetApproach(points,report,0))
  near(report.TargetApproachDistance,5000)
  local astar=searches.astar
  assert(ship:_TryResumeWaypointRoute())
  equal(ship.localNavigation,nil) equal(ship.stops,0) equal(searches.astar,astar)
  equal(ship.dispatched[2].uid,2) equal(ship.currentwp,1)
  timerNow=10 ship:_CheckNavigation()
  equal(ship.localNavigation,nil) equal(searches.astar,astar) equal(ship.stops,0)
  assert(navigation.TargetUID==2)
end)

test("LOCAL turn allowance finds an islet between two clear straight legs",function()
  local ship=localShip()
  local before,corner,after=VECTOR:New(0,0,0),VECTOR:New(500,0,0),VECTOR:New(900,0,600)
  ship.terrain.depthAt=function(p) return (p.x-480)^2+(p.y-60)^2<20^2 and 2 or 40 end
  assert(ship:_CheckPathDepth(before,corner))
  assert(ship:_CheckPathDepth(corner,after))

  local clear,report=ship:_CheckLocalTurn(corner,0,corner:GetHeadingTo(after),10)

  equal(clear,false) equal(report.DepthCheck.Cause,"insufficient_depth")
  equal(report.DepthCheck.Depth,2) equal(report.DepthCheck.RequiredDepth,20)
  equal(ship.pathCorridor,50) equal(ship.stops,0)
end)

test("LOCAL smoothing moves an exposed corner outward and rechecks the resulting route",function()
  local ship=localShip()
  local start,corner,goal=VECTOR:New(0,0,0),VECTOR:New(500,0,0),VECTOR:New(900,0,600)
  ship.terrain.depthAt=function(p) return (p.x-480)^2+(p.y-60)^2<20^2 and 2 or 40 end
  local nodes={{vector=corner},{vector=goal}}

  local points,reason,cost,report=ship:_SimplifyLocalPath(start,0,nodes,true,10,-15)

  assert(points,reason) equal(#points,2) assert(#report.CornerAdjustments>0)
  assert(points[1].x>corner.x and points[1].z<corner.z,"corner must move away from the inner shoal")
  equal(points[1].y,-15) equal(points[2].y,-15)
  near(corner.x,500) near(corner.z,0) -- Raw A* nodes are not modified.
  local position,heading,total=start,0,0
  for _,point in ipairs(points) do
    assert(ship:_CheckPathDepth(position,point))
    local course=position:GetHeadingTo(point)
    assert(ship:_CheckLocalTurn(position,heading,course,10))
    total=total+position:GetDistance(point,true)
    position,heading=point,course
  end
  near(cost,total)
  equal(ship.pathCorridor,50) equal(#ship.dispatches,0)
end)

test("LOCAL turn sampling is bounded, cached and skipped for straight motion",function()
  local ship=localShip()
  local point=VECTOR:New(1000,0,0)
  local profiles=ship.terrain.profiles
  assert(ship:_CheckLocalTurn(point,359,1,10))
  equal(ship.terrain.profiles,profiles)
  local cache={}
  local clear,slow=ship:_CheckLocalTurn(point,0,90,5,cache)
  assert(clear)
  local used=ship.terrain.profiles
  assert(used>profiles)
  assert(ship:_CheckLocalTurn(point,0,-90,5,cache))
  equal(ship.terrain.profiles,used)
  local fastClear,fast=ship:_CheckLocalTurn(point,0,90,30,cache)
  assert(fastClear) assert(fast.Radius>slow.Radius)
  assert(ship.terrain.profiles-used<=15)
  near(fast.Radius,175)
end)

test("LOCAL unavailable turn data fails closed with its depth evidence",function()
  local ship=localShip()
  ship.terrain.makeProfile=function() return nil end
  local clear,report=ship:_CheckLocalTurn(VECTOR:New(500,0,0),0,60,10)
  equal(clear,false) equal(report.DepthCheck.Status,"unavailable")
end)

test("LOCAL steering diagnostics distinguish angle length depth and weighted cost rejection",function()
  local start=VECTOR:New(0,0,0)
  for _,case in ipairs({"turn_angle","leg_too_short","depth","depth_cost","turn_clearance"}) do
    local ship=localShip()
    local point=VECTOR:New(case=="leg_too_short" and 50 or 500,0,0)
    local heading=case=="turn_angle" and 180 or 0
    if case=="depth" then ship.terrain.depth=10 end
    if case=="turn_clearance" then
      heading=45
      ship.terrain.depthAt=function(p) return (p.x+50)^2+(p.y-50)^2<20^2 and 10 or 40 end
    end
    local search
    if case=="depth_cost" then
      ship:SetPathfindingPreferredDepth(30,2)
      ship.terrain.depth=21
      search={startNode={vector=start},_TravelCost=function() return 500 end}
    end
    local points,reason,cost,report=ship:_SimplifyLocalPath(start,heading,{{vector=point}},false,10,0,search)
    if case=="depth_cost" then
      assert(points) equal(reason,nil) equal(report.Pass,2)
      report=report.FirstPass -- The rejected first pass still explains why fallback was necessary.
      assert(report.Examples[case].Cost>report.Examples[case].ReplacedCost)
    else
      equal(points,nil) equal(reason,"no_steering_path") equal(report.Pass,1)
    end
    assert(report.Rejections[case],case)
    if case=="depth" or case=="turn_clearance" then assert(report.Examples[case].DepthCheck) end
    local logs={}
    function ship:I(message) logs[#logs+1]=message end
    report.Candidate=1
    ship:_LogLocalSteeringFailure(report)
    assert(#logs>=2)
    for _,line in ipairs(logs) do assert(#line<500,line) end
  end
end)

test("LOCAL failed steering details survive a final stop without trace",function()
  local ship=localShip()
  local search={SetStartCoordinate=function() end,SetEndCoordinate=function() end}
  function search:_SearchPath() return {{vector=VECTOR:New(-500,0,0)}} end
  function ship:_GetLocalNavigationWindow() self.localNavigation={} return {Search=search} end
  function ship:_GetLocalNavigationCandidates() return {{Vector=VECTOR:New(-500,0,0),GoalReached=false}} end
  local logs={}
  function ship:I(message) logs[#logs+1]=message end

  local plan,reason=ship:_PlanLocalPath(VECTOR:New(0,0,0),0,ship.waypoints[2],10)
  equal(plan,nil) equal(reason,"no_steering_path")
  assert(#logs>0)
  ship:_FailPathfinding({StopReason=reason})
  equal(ship.stops,1)
  local report=ship.LastPathfindingResult.SteeringFailures[1]
  equal(report.Reason,"no_steering_path") equal(report.Candidate,1)
  assert(report.Rejections.turn_angle)
end)

test("LOCAL backtracks from a greedy short-leg trap instead of losing a usable path",function()
  local ship=localShip()
  local nodes={}
  for _,point in ipairs({{800,0},{990,50},{1100,100},{1750,100}}) do
    nodes[#nodes+1]={vector=VECTOR:New(point[1],0,point[2])}
  end
  -- Only the earlier bend can connect to the endpoint; depth failure isolates this steering case.
  function ship:_CheckPathDepth(a,b)
    return not (a.x==990 and b.x>=1100) and not (a.x==800 and b.x==1100)
  end
  local points,reason,cost,report=ship:_SimplifyLocalPath(VECTOR:New(0,0,0),0,nodes,false,10,0)
  assert(points,reason)
  assert(report.Backtracks>0)
  near(points[1].x,800)
end)

test("LOCAL target approach cannot bypass a blocked turn buffer",function()
  local ship=localShip(12000)
  assert(activateLocal(ship))
  ship.terrain.depthAt=function(p) return (p.x-2000)^2+(p.y-75)^2<20^2 and 10 or 40 end
  local points={VECTOR:New(1500,0,-500),VECTOR:New(2000,0,0)}
  local plan={}
  assert(ship:_CheckNavigationAhead(points[2],ship.waypoints[2]))
  equal(ship:_AppendLocalTargetApproach(points,plan,45),false)
  equal(#points,2) equal(plan.RejoinPoint,nil)
  equal(plan.TargetTurnCheck.DepthCheck.Depth,10)
end)

test("LOCAL ordinary target release waits for a minimum-depth turn buffer",function()
  local ship=localShip(12000):SetPathfindingPreferredDepth(30,2)
  assert(activateLocal(ship))
  local navigation=ship.localNavigation
  ship.heading=45
  ship.terrain.depthAt=function(p) return (p.x+50)^2+(p.y-50)^2<20^2 and 10 or 40 end
  assert(ship:_CheckNavigationAhead(VECTOR:NewFromVec(ship.position),ship.waypoints[2]))
  equal(ship:_TryResumeWaypointRoute(),false)
  equal(ship.localNavigation,navigation) equal(ship.stops,0)
  equal(navigation.TargetTurnCheck.DepthCheck.Depth,10)
  -- Preferred depth must not prevent release once only the hard minimum is met.
  ship.terrain.depthAt=nil ship.terrain.depth=21
  assert(ship:_TryResumeWaypointRoute())
  equal(ship.localNavigation,nil) equal(ship.stops,0)
end)

test("LOCAL steering alternatives stop at the search budget instead of exhaustive retries",function()
  local ship=localShip()
  local nodes={}
  for i=1,35 do nodes[i]={vector=VECTOR:New(i*100,0,0)} end
  function ship:_CheckPathDepth(a,b) return b.x~=3500 end
  local points,reason,cost,report=ship:_SimplifyLocalPath(VECTOR:New(0,0,0),0,nodes,false,10,0)
  equal(points,nil) equal(reason,"steering_budget_exceeded")
  equal(report.States,128) assert(report.Backtracks>0)
  equal(ship.stops,0) equal(#ship.dispatches,0)
end)

test("LOCAL depth-weighted corner correction prices the safe detour even when it adds length",function()
  local ship=localShip():SetPathfindingPreferredDepth(30,2)
  local start,corner,goal=VECTOR:New(0,0,0),VECTOR:New(500,0,0),VECTOR:New(900,0,600)
  ship.terrain.depthAt=function(p) return (p.x-480)^2+(p.y-60)^2<20^2 and 2 or 40 end
  local original=ship:_GetPathfindingDepthCost(start,corner)+ship:_GetPathfindingDepthCost(corner,goal)
  local points,reason,cost,report=ship:_SimplifyLocalPath(start,0,{{vector=corner},{vector=goal}},true,10,0)
  assert(points,reason) assert(#report.CornerAdjustments>0)
  assert(cost>original,"this required outward correction should add length")
  local total,position=0,start
  for _,point in ipairs(points) do
    total=total+ship:_GetPathfindingDepthCost(position,point)
    position=point
  end
  near(cost,total)
end)

test("LOCAL backtracking restores an adjusted corner before trying another outgoing leg",function()
  local ship=localShip()
  local nodes={}
  for _,point in ipairs({{500,0},{800,500},{850,600},{1000,1000},{1500,1000}}) do
    nodes[#nodes+1]={vector=VECTOR:New(point[1],0,point[2])}
  end
  function ship:_CheckPathDepth(a,b)
    return not (a.x==0 and b.x>=700) and a.x~=850
  end
  function ship:_CheckLocalTurn(position)
    return position.x~=500,{Radius=125}
  end
  local tried={}
  function ship:_AdjustLocalTurn(previous,corner,following,speed,minLeg,shortGoal,weighted,cache)
    tried[#tried+1]=corner
    return NAVYGROUP._AdjustLocalTurn(self,previous,corner,following,speed,minLeg,shortGoal,weighted,cache)
  end

  local points,reason,cost,report=ship:_SimplifyLocalPath(VECTOR:New(0,0,0),0,nodes,true,10,0)

  assert(points,reason) assert(report.Backtracks>0) assert(#tried>=2)
  for _,corner in ipairs(tried) do near(corner.x,500) near(corner.z,0) end
  for _,adjustment in ipairs(report.CornerAdjustments) do
    assert(adjustment.Original:GetDistance(adjustment.Position,true)<=150.001)
  end
  local total,previous=0,VECTOR:New(0,0,0)
  for _,point in ipairs(points) do total=total+previous:GetDistance(point,true) previous=point end
  near(cost,total)
end)


-- Reproduce the depth/length conflict with two supplied A* paths. All costs, simplification,
-- preparation, candidate comparison and native route submission use production methods.
local function depthCandidateShip()
  local ship=localShip(20000):SetPathfindingMinDepth(3.5):SetPathfindingPreferredDepth(10,100)
  ship.terrain.depthAt=function(p) return p.x>500 and math.abs(p.y)<150 and 5 or 40 end
  local shallow,deep=VECTOR:New(2600,0,0),VECTOR:New(1500,0,1000)
  local search=ASTAR:New():SetValidNeighbourDepth(3.5,50):SetCostDepth(10,100)
  function search:SetStartCoordinate(start) self.startNode=self:AddNodeFromCoordinate(start) end
  function search:SetEndCoordinate(goal) self.goal=goal end
  function search:_SearchPath()
    local nodes={}
    local start=self.startNode.vector
    for i=1,26 do
      nodes[i]=self:AddNodeFromCoordinate(VECTOR:New(start.x+(self.goal.x-start.x)*i/26,0,
        start.z+(self.goal.z-start.z)*i/26))
    end
    return nodes
  end
  local window={Search=search,Target=VECTOR:New(20000,0,0),Spacing=50,PreferredDepth=10,DepthWeight=100,
    MinDepth=3.5,CorridorWidth=50,Grid={GetCandidateCount=function() return 100 end}}
  function ship:_GetLocalNavigationWindow() return window end
  function ship:_GetLocalNavigationCandidates()
    return {{Vector=shallow,GoalReached=false},{Vector=deep,GoalReached=false}}
  end
  return ship,window
end

test("LOCAL short deep candidate receives a checked target approach before final comparison",function()
  local ship,window=depthCandidateShip()
  local logs={}
  function ship:T(message) logs[#logs+1]=message end
  local start=VECTOR:New(0,0,0)
  local provisional=assert(ship:_PlanLocalPath(start,0,ship.waypoints[2],10))
  equal(provisional.Candidate,2)
  assert(provisional.Length<provisional.RequiredLength)
  assert(provisional.Candidates[1].Cost>provisional.Cost*60)

  assert(activateLocal(ship))

  local plan=ship.LastPathfindingResult
  equal(plan.Candidate,2) equal(plan.PreflightExtensions,0)
  near(plan.RejoinPoint.x,1500) near(plan.RejoinPoint.z,1000)
  near(plan.TargetApproachDistance,5000)
  assert(plan.Length>=plan.RequiredLength)
  near(plan.Cost,plan.Length) equal(plan.Candidates,nil)
  equal(ship.localNavigation.Window,window) equal(ship.stops,0) equal(#ship.dispatches,1)
  assertClearPath(ship,ship.localNavigation.Path)
  local prepared,selected=0,0
  for _,line in ipairs(logs) do
    if line:find("Local candidate prepared:",1,true) then
      prepared=prepared+1 assert(line:find("cost=",1,true)) assert(line:find("score=",1,true))
    elseif line:find("Local candidate selected:",1,true) then
      selected=selected+1 assert(line:find("candidate=2",1,true)) assert(line:find("weight=100",1,true))
    end
    assert(#line<500,line)
  end
  equal(prepared,2) equal(selected,1)
end)

test("LOCAL compares complete depth costs and keeps a usable alternative when extension fails",function()
  for _,outcome in ipairs({"deep","blocked","expensive","short"}) do
    local ship,window=depthCandidateShip()
    local future={tag=outcome}
    local extensions=0
    local logs={}
    function ship:T(message) logs[#logs+1]=message end
    function ship:_AppendLocalTargetApproach() return false end
    function ship:_PlanLocalPath(start,heading,target,speed)
      equal(#self.dispatches,0) -- No trial may command partial motion.
      if start.x==0 then return NAVYGROUP._PlanLocalPath(self,start,heading,target,speed) end
      extensions=extensions+1
      self.localNavigation.Window=future
      if outcome=="blocked" then return nil,"connections_blocked" end
      local length=outcome=="short" and 100 or (outcome=="expensive" and 2000 or 1000)
      local points={}
      for i=1,math.ceil(length/1000) do points[i]=start:Translate(math.min(i*1000,length),heading,true) end
      return {Points=points,GoalReached=false,Window=future,Attempts=1}
    end
    if outcome=="expensive" then
      ship.terrain.depthAt=function(p)
        if p.x>1600 and p.y>1000 then return 3.5 end
        return p.x>500 and math.abs(p.y)<150 and 5 or 40
      end
    end

    assert(activateLocal(ship))

    local plan=ship.LastPathfindingResult
    equal(plan.Candidate,outcome=="deep" and 2 or 1)
    equal(ship.localNavigation.Window,outcome=="deep" and future or window)
    equal(extensions,outcome=="short" and 2 or 1)
    equal(plan.PreflightExtensions,outcome=="deep" and 1 or 0)
    assert(plan.Length>=plan.RequiredLength) equal(ship.stops,0) equal(#ship.dispatches,1)
    local cost,previous=0,VECTOR:New(0,0,0)
    for _,point in ipairs(plan.Points) do
      cost=cost+ship:_GetPathfindingDepthCost(previous,point) previous=point
    end
    near(plan.Cost,cost,1e-5) assertClearPath(ship,ship.localNavigation.Path)
    if outcome=="blocked" or outcome=="short" then
      local found=false
      for _,line in ipairs(logs) do
        if line:find("candidate=2, stage=preparation",1,true) then found=true end
      end
      assert(found,"missing diagnostic for the rejected short candidate")
    end
  end
end)

test("LOCAL candidate trials preserve the common approach and restore the winning window",function()
  local ship,window=depthCandidateShip()
  assert(activateLocal(ship))
  local navigation=ship.localNavigation
  local installed,dispatches=navigation.Path,#ship.dispatches
  local position=VECTOR:New(0,0,0)
  local anchor=VECTOR:New(400,0,0)
  local plan=assert(ship:_PlanLocalPath(anchor,0,ship.waypoints[2],10))
  local points={position,anchor}
  for _,point in ipairs(plan.Points) do points[#points+1]=point end

  local prepared,selected,reason=ship:_PrepareLocalRoute(points,plan,position)

  assert(prepared,reason) equal(selected.Candidate,2)
  equal(prepared[1],position) equal(prepared[2],anchor)
  equal(navigation.Path,installed) equal(#ship.dispatches,dispatches)
  equal(navigation.Window,selected.Window) equal(selected.Window,window)
  assert(selected.Length>=selected.RequiredLength)
end)

test("LOCAL failed candidate preparation retains the installed route and its window",function()
  local ship,window=depthCandidateShip()
  assert(activateLocal(ship))
  local navigation=ship.localNavigation
  local installed,dispatches=navigation.Path,#ship.dispatches
  local previousWindow={tag="installed"}
  local start=VECTOR:New(0,0,0)
  local plan=assert(ship:_PlanLocalPath(start,0,ship.waypoints[2],10))
  navigation.Speed=60 -- Both candidates now require bounded continuation.
  navigation.Window=previousWindow
  function ship:_AppendLocalTargetApproach() return false end
  local calls=0
  function ship:_PlanLocalPath()
    calls=calls+1 self.localNavigation.Window={tag="rejected"}
    return nil,"connections_blocked"
  end
  local points={start}
  for _,point in ipairs(plan.Points) do points[#points+1]=point end

  local prepared,selected,reason=ship:_PrepareLocalRoute(points,plan,start)

  equal(prepared,nil) equal(selected,nil) equal(reason,"connections_blocked") equal(calls,2)
  equal(navigation.Path,installed) equal(navigation.Window,previousWindow)
  equal(#ship.dispatches,dispatches) equal(ship.stops,0)
end)

test("LOCAL candidate comparison does not reward an arbitrary free target approach length",function()
  local ship=localShip()
  assert(activateLocal(ship))
  local plan=ship.LastPathfindingResult
  -- In uniformly deep water a short side exit plus a free 5 km approach must not win
  -- merely through that added progress over the straightforward front exit.
  equal(plan.PreflightExtensions,0) equal(plan.TargetApproachDistance,nil)
  assert(plan.Length>=plan.RequiredLength and plan.Length<3200)
  assert(math.abs(plan.Points[#plan.Points].z)<500)
end)


test("LOCAL prepared target approach remains minimum-depth-only during weighted comparison",function()
  local ship=depthCandidateShip()
  ship.terrain.depthAt=function(p)
    if p.x>2000 and p.y>600 then return 4 end
    return p.x>500 and math.abs(p.y)<150 and 5 or 40
  end
  local notices=0
  function ship:T(message)
    if message:find("Local route target approach:",1,true) then notices=notices+1 end
  end

  assert(activateLocal(ship))

  local plan=ship.LastPathfindingResult
  equal(plan.Candidate,2) near(plan.RejoinPoint.x,1500)
  near(plan.TargetApproachDistance,5000) near(plan.Cost,plan.Length)
  local last=plan.Points[#plan.Points]
  near(ship.terrain.depthAt({x=last.x,y=last.z}),4)
  equal(notices,1) equal(ship.stops,0) assertClearPath(ship,ship.localNavigation.Path)
end)


-- The first raw bend is too close to emit as a ship waypoint. Skipping it crosses
-- permitted but shallower water, so a usable steering route needs a cost increase.
local function steeringFallbackShip()
  local ship=localShip():SetPathfindingMinDepth(3.5):SetPathfindingPreferredDepth(15,100)
  ship.terrain.depthAt=function(p) return p.x>=100 and p.x<=400 and math.abs(p.y)<25 and 5 or 40 end
  local start=VECTOR:New(0,0,0)
  local nodes={{vector=VECTOR:New(50,0,50)},{vector=VECTOR:New(500,0,50)},{vector=VECTOR:New(1000,0,0)}}
  return ship,start,nodes
end

test("LOCAL steering fallback allows necessary depth cost increase and reuses edge profiles",function()
  local ship,start,nodes=steeringFallbackShip()
  local calls=0
  function ship:_GetPathfindingDepthCost(a,b)
    if a.x==0 and b.x==1000 then calls=calls+1 end
    return NAVYGROUP._GetPathfindingDepthCost(self,a,b)
  end

  local points,reason,cost,report=ship:_SimplifyLocalPath(start,0,nodes,false,10,0)

  assert(points,reason) equal(report.Pass,2) equal(report.FirstPass.Reason,"no_steering_path")
  assert(report.FirstPass.Rejections.depth_cost)
  assert(report.FirstPass.Rejections.leg_too_short)
  assert(cost>report.OriginalCost) equal(calls,1)
  equal(#points,1) near(points[1].x,1000)
  near(cost,ship:_GetPathfindingDepthCost(start,points[1]))
  equal(report.Rejections.depth_cost,nil) assert(report.States+report.FirstPass.States<=256)
  equal(ship.stops,0) equal(#ship.dispatches,0) assertClearPath(ship,points)
end)

test("LOCAL steering fallback never bypasses a blocked or unknown turn allowance",function()
  for _,unknown in ipairs({false,true}) do
    local ship,start,nodes=steeringFallbackShip()
    local originalDepth=ship.terrain.depthAt
    local function inTurn(p) return (p.x+50)^2+(p.y-50)^2<20^2 end
    if unknown then
      local sample=land.getSurfaceHeightWithSeabed
      land.getSurfaceHeightWithSeabed=function(p)
        if inTurn(p) then return nil,nil end
        return sample(p)
      end
    else
      ship.terrain.depthAt=function(p) return inTurn(p) and 2 or originalDepth(p) end
    end

    local points,reason,cost,report=ship:_SimplifyLocalPath(start,30,nodes,false,10,0)

    equal(points,nil) equal(reason,"no_steering_path") equal(report.Pass,2)
    assert(report.FirstPass.Rejections.depth_cost)
    local depth=assert(report.Examples.turn_clearance.DepthCheck)
    equal(depth.Status,unknown and "unavailable" or "blocked")
    if not unknown then near(depth.Depth,2) end
    equal(report.Rejections.depth_cost,nil) equal(ship.stops,0)
  end
end)

test("LOCAL steering fallback still rejects a connection below minimum depth",function()
  local ship,start,nodes=steeringFallbackShip()
  nodes[3].vector=VECTOR:New(1100,0,0)
  local originalDepth=ship.terrain.depthAt
  ship.terrain.depthAt=function(p) return p.x>750 and p.x<850 and 2 or originalDepth(p) end
  -- Cached search costs describe the earlier raw path, not permission to skip live hard checks.
  local search={startNode={vector=start}}
  function search:_TravelCost(a,b) return a.vector:GetDistance(b.vector,true) end

  local points,reason,cost,report=ship:_SimplifyLocalPath(start,0,nodes,false,10,0,search)

  equal(points,nil) equal(reason,"no_steering_path") equal(report.Pass,2)
  assert(report.FirstPass.Rejections.depth_cost) assert(report.Rejections.depth)
  equal(report.Examples.depth.DepthCheck.Status,"blocked")
  near(report.Examples.depth.DepthCheck.Depth,2)
end)

test("LOCAL successful strict steering and hard-only failures do not trigger fallback",function()
  for _,case in ipairs({"clear","unweighted","angle","spacing"}) do
    local ship,start,nodes=steeringFallbackShip()
    if case=="clear" then ship.terrain.depthAt=nil end
    if case=="unweighted" then ship:SetPathfindingPreferredDepth(15,0) end
    if case=="spacing" then nodes={nodes[1]} end
    local heading=case=="angle" and 180 or 0

    local points,reason,cost,report=ship:_SimplifyLocalPath(start,heading,nodes,false,10,0)

    equal(report.Pass,1) equal(report.FirstPass,nil)
    if case=="angle" or case=="spacing" then
      equal(points,nil) equal(reason,"no_steering_path")
      assert(report.Rejections[case=="angle" and "turn_angle" or "leg_too_short"])
    else
      assert(points,reason)
    end
  end
end)

test("LOCAL relaxed steering remains bounded after resetting exhausted strict states",function()
  local ship=localShip():SetPathfindingPreferredDepth(30,2)
  local start=VECTOR:New(0,0,0)
  local nodes={}
  for i=1,35 do nodes[i]={vector=VECTOR:New(i*100,0,0)} end
  local search={startNode={vector=start}}
  function search:_TravelCost(a,b) return a.vector:GetDistance(b.vector,true) end
  function ship:_GetPathfindingDepthCost(a,b)
    return b.x==3500 and math.huge or 2*a:GetDistance(b,true)
  end
  function ship:_CheckPathDepth(a,b) return b.x~=3500 end

  local points,reason,cost,report=ship:_SimplifyLocalPath(start,0,nodes,false,10,0,search)

  equal(points,nil) equal(reason,"steering_budget_exceeded") equal(report.Pass,2)
  equal(report.FirstPass.States,1) equal(report.States,128)
  assert(report.FirstPass.Rejections.depth_cost) assert(report.Backtracks>0)
  equal(report.Rejections.depth_cost,nil) equal(#ship.dispatches,0)
end)

test("LOCAL candidates retain the real cost of fallback steering in their comparison",function()
  local ship,start,raw=steeringFallbackShip()
  local shallow,deep=raw[#raw].vector,VECTOR:New(1500,0,800)
  local search=ASTAR:New():SetValidNeighbourDepth(3.5,50):SetCostDepth(15,100)
  function search:SetStartCoordinate(point) self.startNode=self:AddNodeFromCoordinate(point) end
  function search:SetEndCoordinate(point) self.goal=point end
  function search:_SearchPath()
    local nodes={}
    if self.goal==shallow then
      for i,node in ipairs(raw) do nodes[i]=self:AddNodeFromCoordinate(node.vector) end
    else
      for i=1,26 do nodes[i]=self:AddNodeFromCoordinate(VECTOR:New(deep.x*i/26,0,deep.z*i/26)) end
    end
    return nodes
  end
  local window={Search=search,Target=VECTOR:New(20000,0,0),Spacing=50,Grid={GetCandidateCount=function() return 100 end}}
  function ship:_GetLocalNavigationWindow() return window end
  function ship:_GetLocalNavigationCandidates()
    return {{Vector=shallow,GoalReached=false},{Vector=deep,GoalReached=false}}
  end
  local notices=0
  function ship:T(message)
    if message:find("Local steering fallback:",1,true) then
      notices=notices+1
      assert(message:find("candidate=1",1,true)) assert(message:find("result=path_found",1,true))
      assert(message:find("raw_cost=",1,true)) assert(#message<500)
    end
  end

  local plan=assert(ship:_PlanLocalPath(start,0,ship.waypoints[2],10))

  equal(plan.Candidate,2) equal(plan.Steering.Pass,1) equal(notices,1)
  local fallback=plan.Candidates[1]
  equal(fallback.Steering.Pass,2)
  near(fallback.Cost,ship:_GetPathfindingDepthCost(start,shallow))
  assert(fallback.Cost>fallback.Steering.OriginalCost and fallback.Cost>plan.Cost)
  assert(fallback.Score>plan.Score)
end)

-- Model dimensions and live wrapper data used by the production hull check.
local function hullElement(ship,name,position,heading,speed,box)
  local unit={alive=true}
  function unit:IsAlive() return self.alive end
  function unit:GetVec3() return position or ship.position end
  function unit:GetHeading() return heading or ship.heading end
  function unit:GetVelocityMPS() return speed or ship.velocity end
  return {name=name,unit=unit,descriptors=box and {box=box}}
end

test("nearfield uses the asymmetric live hull and rotated bow while the center remains clear",function()
  local ship=localShip()
  ship.position={x=100,y=0,z=200} ship.heading=90
  ship.elements={hullElement(ship,"long bow",nil,nil,nil,
    {min={x=-20,z=-8},max={x=120,z=12}})}
  ship.terrain.depthAt=function(p) return p.y>=290 and p.y<=325 and math.abs(p.x-100)<=8 and 2 or 40 end
  assert(ship:_CheckPathDepth(ship.position,ship.position))
  local clear,reason,report=ship:_CheckNavigationNearfield()
  equal(clear,false) equal(report.NavigationStage,"ship_hull") equal(report.Depth,2)
  equal(report.Nearfield.Bow,120) equal(report.Nearfield.Stern,-20) equal(report.Nearfield.Beam,20)
  equal(report.Nearfield.Heading,90) equal(report.Nearfield.Unit,"long bow")
  equal(report.Nearfield.ClearFromBow,0) equal(ship.stops,0)
end)

test("nearfield catches an interior islet missed by the three ordinary corridor lines",function()
  local ship=localShip()
  ship.pathCorridor=60
  ship.elements={hullElement(ship,"beam",nil,nil,nil,{min={x=-10,z=-20},max={x=10,z=20}})}
  ship.terrain.depthAt=function(p) return p.x>=60 and p.x<=95 and p.y>=7 and p.y<=13 and 2 or 40 end
  assert(ship:_CheckPathDepth(VECTOR:New(0,0,0),VECTOR:New(120,0,0)))
  local clear,reason,report=ship:_CheckNavigationNearfield()
  equal(clear,false) equal(report.NavigationStage,"ship_lookahead") equal(report.ProfileOffset,10)
  assert(report.Nearfield.ClearFromBow>0 and report.Nearfield.ClearFromBow<100)
  ship.pathCorridor=0 -- A point-only A* rule cannot shrink the physical hull check.
  equal(ship:_CheckNavigationNearfield(),false)
end)

test("nearfield checks formation members at their own positions and ignores dead elements",function()
  local ship=localShip()
  local dead=hullElement(ship,"dead",{x=500,y=0,z=500},0,10)
  dead.unit.alive=false
  function dead.unit:GetVec3() error("dead ship must not be queried") end
  ship.elements={dead,hullElement(ship,"leader"),hullElement(ship,"follower",{x=2000,y=0,z=300},90,20)}
  ship.terrain.depthAt=function(p) return p.x>=1990 and p.x<=2010 and p.y>=450 and p.y<=500 and 2 or 40 end
  local clear,reason,report=ship:_CheckNavigationNearfield()
  equal(clear,false) equal(report.Nearfield.Unit,"follower") equal(report.Nearfield.Heading,90)
  equal(report.Nearfield.Position.x,2000) equal(report.Nearfield.Speed,20) equal(report.Nearfield.Lookahead,200)
end)

test("nearfield uses cached dimensions or fallbacks without querying model descriptors",function()
  local ship=localShip()
  local element=hullElement(ship,"cached")
  element.length,element.width=80,20 ship.elements={element}
  ship.terrain.depthAt=function(p) return p.x>=35 and p.x<=60 and math.abs(p.y)<4 and 2 or 40 end
  local clear,reason,report=ship:_CheckNavigationNearfield()
  equal(clear,false) equal(report.Nearfield.Bow,40) equal(report.Nearfield.Beam,20)
  element.length,element.width=0,0
  clear,reason,report=ship:_CheckNavigationNearfield()
  equal(clear,false) equal(report.Nearfield.Bow,50) equal(report.Nearfield.Beam,30)
end)

test("nearfield detects a new hazard during a turn before the next regular route tick",function()
  for _,mode in ipairs({NAVYGROUP.PathfindingMode.LOCAL,NAVYGROUP.PathfindingMode.WAYPOINT}) do
    timerNow=0
    local ship=vessel():SetPathfindingMode(mode)
    local routeChecks=0
    function ship:_CheckNavigationAhead(position,waypoint)
      routeChecks=routeChecks+1
      return true,nil,{Status="clear",ClearDistance=5000,Distance=5000}
    end
    ship:_CheckNavigation()
    equal(routeChecks,1) equal(ship.stops,0)
    ship.heading=26
    local c,s=math.cos(math.rad(26)),math.sin(math.rad(26))
    ship.terrain.depthAt=function(p)
      local along,across=p.x*c+p.y*s,-p.x*s+p.y*c
      return along>=120 and along<=175 and math.abs(across)<30 and 2 or 40
    end
    assert(ship:_CheckPathDepth(ship.position,ship.position))
    local logs={}
    function ship:I(message) logs[#logs+1]=message end
    timerNow=2 ship:_CheckNavigation()
    equal(ship:IsTurning(),true) equal(routeChecks,1) equal(ship.stops,1) assertNoSearch()
    equal(ship.LastPathfindingResult.StopReason,"nearfield_blocked")
    equal(ship.LastPathfindingResult.DepthCheck.NavigationStage,"ship_lookahead")
    equal(ship.state,"Holding") equal(ship.currentwp,1)
    equal(ship.dispatched[1].speed,0)
    local profiles=ship.terrain.profiles
    timerNow=4 ship:_CheckNavigation()
    equal(ship.stops,1) equal(ship.terrain.profiles,profiles)
    equal(#logs,4)
    for _,line in ipairs(logs) do assert(#line<500) end
    assert(logs[4]:find("Naval nearfield:",1,true))
  end
end)

test("nearfield safety samples do not multiply route searches or clear an existing distant warning",function()
  local ship=localShip()
  local checks=0
  function ship:_CheckNavigationAhead()
    checks=checks+1
    return true,nil,{Status="clear",Distance=5000,ClearDistance=5000}
  end
  ship:_CheckNavigation()
  ship.collisionwarning=true
  local profiles=ship.terrain.profiles
  for t=2,8,2 do timerNow=t ship:_CheckNavigation() end
  assert(ship.terrain.profiles>profiles) equal(checks,1) equal(ship.collisionwarning,true)
  timerNow=10 ship:_CheckNavigation()
  equal(checks,2) equal(ship.collisionwarning,false) assertNoSearch() equal(#ship.dispatches,0)
end)

test("nearfield unavailable data stops once without starting a search",function()
  local ship=localShip()
  ship.terrain.makeProfile=function() return nil end
  ship:_CheckNavigation()
  equal(ship.stops,1) assertNoSearch()
  equal(ship.LastPathfindingResult.DepthCheck.Status,"unavailable")
  equal(ship.LastPathfindingResult.StopReason,"profile_unavailable")
  timerNow=2 ship:_CheckNavigation() equal(ship.stops,1)
end)

test("nearfield respects disabled pathfinding holds movement tasks and warning callbacks",function()
  for _,state in ipairs({"off","Holding","Waiting","Dead","task"}) do
    local ship=localShip()
    ship.navigationCheckTime=0 timerNow=2
    ship.terrain.depth=1
    if state=="off" then ship.pathfindingOn=false
    elseif state=="Waiting" then ship.Twaiting=0
    elseif state=="task" then ship.taskcurrent=1 ship.taskqueue={{id=1,dcstask={id="AttackGroup"}}}
    else ship.state=state end
    ship:_CheckNavigation()
    equal(ship.terrain.queries,0) equal(ship.stops,0) assertNoSearch()
  end
  for _,action in ipairs({"hold","disable"}) do
    local ship=localShip()
    ship.terrain.depth=1
    function ship:OnAfterCollisionWarning()
      if action=="hold" then self:FullStop() else self:SetPathfindingOff() end
    end
    ship:_CheckNavigation()
    equal(ship.stops,action=="hold" and 1 or 0) assertNoSearch()
  end
end)

test("LOCAL progress follows outgoing motion even while the previous line is slightly closer",function()
  local ship=localShip()
  ship.heading=45
  ship.localNavigation={Path={VECTOR:New(0,0,0),VECTOR:New(1000,0,0),VECTOR:New(1700,0,700)},
    Distances={0,1000,1000+math.sqrt(980000)},Length=1000+math.sqrt(980000),Segment=1,Progress=800,Speed=10}
  local point=VECTOR:New(920,0,150)
  local progress,remaining,deviation=ship:_LocalRouteProgress(point)
  equal(ship.localNavigation.Segment,2)
  assert(progress>1000) near(deviation,230/math.sqrt(2))
  -- Repeating an observation cannot advance the original mission waypoint or submit a route.
  near(ship:_LocalRouteProgress(point),progress)
  equal(ship.currentwp,1) equal(ship.passingEvents,nil) equal(#ship.dispatches,0)
end)

test("LOCAL outgoing-course progress cannot skip an unentered corner or a distant return leg",function()
  for _,case in ipairs({"wrong_heading","before_corner","too_far","hairpin"}) do
    local ship=localShip()
    ship.heading=case=="wrong_heading" and 0 or 45
    local third=case=="hairpin" and VECTOR:New(0,0,100) or VECTOR:New(1700,0,700)
    ship.localNavigation={Path={VECTOR:New(0,0,0),VECTOR:New(1000,0,0),third,VECTOR:New(0,0,200)},
      Distances={0,1000,2000,4000},Length=4000,Segment=1,Progress=0,Speed=10}
    local point=case=="before_corner" and VECTOR:New(800,0,50)
      or case=="too_far" and VECTOR:New(600,0,550) or VECTOR:New(920,0,150)
    if case=="hairpin" then point=VECTOR:New(0,0,95) end
    ship:_LocalRouteProgress(point)
    equal(ship.localNavigation.Segment,1)
  end
end)

test("LOCAL route trace records submitted steering coordinates and connector diagnostics",function()
  local ship=localShip()
  function ship:IsTrace() return true end
  local traces={}
  function ship:T(message) traces[#traces+1]=message end
  activateLocal(ship)
  local route=ship.dispatched
  local count=0
  for _,line in ipairs(traces) do
    if line:find("Local route point:",1,true) then
      count=count+1
      local point=route[count]
      assert(line:find(string.format("x=%.1f, z=%.1f",point.x,point.y),1,true))
      assert(#line<500)
    end
  end
  equal(count,#route) equal(ship.localNavigation.RouteID,1)
  local clear,reason,report=ship:_CheckLocalRoute(VECTOR:NewFromVec(ship.position))
  assert(clear) equal(report.RouteID,1) assert(report.CheckStart and report.CheckGoal)
end)

print(string.format("%d passed, %d failed",passed,failed))
if failed>0 then os.exit(1) end
