-- Standalone LOCAL naval navigation regressions; run from the repository root:
-- lua tests/navy-local.lua
-- Imports production methods and actual GRID/ASTAR/PATHLINE; only DCS/FSM effects are stubbed.
-- Compatible with the Lua 5.1 runtime used by DCS and Lua 5.4.
-- Optional NAVY_TEST_FILTER selects Lua name patterns separated by |.
-- Cooperative ticks advance mission time; positions change only when a case supplies movement.
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

local navyFile=assert(io.open(arg and arg[1] or "Moose Development/Moose/Ops/NavyGroup.lua","r"))
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
local function equal(actual,expected,context)
  assert(actual==expected,"expected "..tostring(expected)..", got "..tostring(actual)..(context and ": "..context or ""))
end
local function near(actual,expected,tolerance)
  assert(math.abs(actual-expected)<(tolerance or 1e-7),"expected approximately "..tostring(expected)..", got "..tostring(actual))
end
local function distance(a,b) return math.sqrt((a.x-b.x)^2+(a.z-b.z)^2) end
local testFilter=os and os.getenv and os.getenv("NAVY_TEST_FILTER")
local function test(name,run)
  if testFilter then
    local matches=false
    for pattern in string.gmatch(testFilter,"[^|]+") do
      if string.find(name,pattern) then matches=true break end
    end
    if not matches then return end
  end
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

-- Behavior cases wait explicitly for cooperative work. One-tick budget/lifecycle cases
-- below call the production handler directly so pending work remains observable.
local function finishPlanning(ship,result)
  local slices=0
  while ship.localNavigation and ship.localNavigation.Job do
    slices=slices+1
    assert(slices<=2500,"naval planning did not finish within its configured slice limit")
    timerNow=timerNow+0.1
    result=ship:_CheckLocalNavigation()
  end
  return result
end
local function checkLocal(ship,...)
  return finishPlanning(ship,ship:_CheckLocalNavigation(...))
end
local function checkNavigation(ship)
  ship:_CheckNavigation()
  return finishPlanning(ship,true)
end
local function activateLocal(ship,speed,depth,first)
  return checkLocal(ship,true,speed,depth,first)
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
local function connectionCost(ship,a,b)
  local search=ASTAR:New():SetValidNeighbourDepth(ship.pathMinDepth or 20,ship:_GetPathfindingCorridorWidth())
  search:SetCostDepth(ship.pathPreferredDepth,ship.pathDepthWeight or 2)
  local valid,cost=search:EvaluateConnection(a,b)
  return valid and cost or math.huge
end
local function connectionRules(ship,rule)
  local search={}
  function search:EvaluateConnection(a,b)
    local valid,cost=rule(a,b)
    local report={Status=valid and "clear" or "blocked",Reason=valid and "clear" or "insufficient_depth"}
    return valid,cost or (valid and a:GetDistance(b,true) or math.huge),report
  end
  function ship:_GetLocalSearch() return search end
  return search
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
  for i=1,3 do timerNow=i*10 checkNavigation(ship) end
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
  timerNow=10 checkNavigation(ship)
  equal(ship.localNavigation,nil) equal(#ship.dispatches,dispatches) assertNoSearch()
  ship:SetPathfindingOff()
  timerNow=20 checkNavigation(ship)
  ship:SetPathfindingOn()
  timerNow=30 checkNavigation(ship)
  equal(ship.localNavigation,nil) equal(#ship.dispatches,dispatches) assertNoSearch()
  ship:SetPathfindingMode(NAVYGROUP.PathfindingMode.WAYPOINT)
  ship:SetPathfindingMode(NAVYGROUP.PathfindingMode.LOCAL)
  timerNow=40 checkNavigation(ship)
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
  checkNavigation(ship)
  near(checked[1],5000)
  equal(ship.warnings,1) equal(ship.localNavigation,nil) assertNoSearch()
  near(ship.LastNavigationCheck.LocalSearchDistance,2100)
  near(ship.LastNavigationCheck.LocalSearchAhead,3000)
  local dispatched,dispatches=ship.dispatched,#ship.dispatches

  -- A warning stays active without changing the native route or allocating a grid.
  for i=1,3 do
    timerNow=i*10 checkNavigation(ship)
    equal(ship.dispatched,dispatched) equal(#ship.dispatches,dispatches) equal(ship.warnings,1)
    equal(ship.localNavigation,nil) equal(ship.stops,0) assertNoSearch()
  end

  ship.position={x=2500,y=0,z=0}
  timerNow=40 checkNavigation(ship)
  local navigation=assert(ship.localNavigation)
  equal(navigation.TargetUID,2) equal(navigation.GoalReached,false)
  assert(searches.grids>0 and searches.astar>0,"approaching an already warned obstacle must start LOCAL")
  equal(ship.added,0) equal(#ship.waypoints,3) equal(ship.state,"Cruising")
  for _,waypoint in ipairs(ship.dispatched) do
    assert(waypoint.uid~=2 and waypoint.uid~=3,"activation leaked distant mission points into the local route")
    assert(waypoint.x<=6250.001 and math.abs(waypoint.y)<=1000.001)
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
  checkNavigation(ship)
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
  checkNavigation(ship)
  assert(ship.localNavigation)
  local grids,astar=searches.grids,searches.astar
  local inserted=ship:AddWaypoint(coord(0,10000),14,1,nil,false)
  ship:onafterUpdateRoute()
  ship:FlushUpdate()
  equal(ship.localNavigation,nil) equal(ship.dispatched[2].uid,inserted.uid) equal(ship.dispatched[3].uid,2)
  timerNow=10 checkNavigation(ship)
  equal(ship.localNavigation,nil) equal(ship.currentwp,1) equal(ship.passingEvents,nil)
  equal(searches.grids,grids) equal(searches.astar,astar)
end)

test("LOCAL ignores obstacles beyond its normal collision lookahead until they enter the checked route",function()
  local ship=localShip()
  forbidGlobalPlanner(ship)
  ship.terrain.depthAt=function(point) return point.x>=5450 and point.x<=5550 and math.abs(point.y)<=200 and 5 or 40 end
  ship:onafterUpdateRoute()
  checkNavigation(ship)
  equal(ship.localNavigation,nil) equal(ship.warnings,0) assertNoSearch()
  ship.position={x=1000,y=0,z=0}
  timerNow=10 checkNavigation(ship)
  equal(ship.localNavigation,nil) equal(ship.warnings,1) assertNoSearch()
  ship.position={x=3500,y=0,z=0}
  timerNow=20 checkNavigation(ship)
  equal(assert(ship.localNavigation).TargetUID,2)
  assert(searches.grids>0 and searches.astar>0)
end)

test("LOCAL leaves avoidance when the target horizon clears and reactivates for another obstacle",function()
  local ship=localShip(8000)
  forbidGlobalPlanner(ship)
  ship.terrain.depthAt=function(point) return point.x>=1450 and point.x<=1550 and math.abs(point.y)<=200 and 5 or 40 end
  ship:onafterUpdateRoute()
  checkNavigation(ship)
  local navigation=assert(ship.localNavigation)
  assert(ship:_CheckPathDepth(ship.position,navigation.Path[2]),"the first short steering leg must be clear")
  local dispatches=#ship.dispatches
  local original=ship.waypoints[2]
  local task=original.task
  -- A clear first steering leg alone is not enough while the original target direction is blocked.
  timerNow=10 checkNavigation(ship)
  equal(ship.localNavigation,navigation) equal(#ship.dispatches,dispatches)
  ship.terrain.depthAt=nil
  timerNow=20 checkNavigation(ship)
  equal(ship.localNavigation,nil)
  equal(#ship.dispatches,dispatches+1) equal(ship.dispatched[2].uid,2)
  equal(ship.waypoints[2],original) equal(original.task,task)
  equal(ship.currentwp,1) equal(original.npassed,0) equal(ship.passingEvents,nil)
  local grids,astar=searches.grids,searches.astar
  timerNow=30 checkNavigation(ship)
  equal(ship.localNavigation,nil) equal(searches.grids,grids) equal(searches.astar,astar)
  equal(#ship.dispatches,dispatches+1)

  ship.terrain.depthAt=function(point) return point.x>=1450 and point.x<=1550 and math.abs(point.y)<=200 and 5 or 40 end
  timerNow=40 checkNavigation(ship)
  assert(ship.localNavigation and ship.localNavigation~=navigation)
  equal(ship.localNavigation.TargetUID,2) assert(searches.grids>grids)
end)

test("LOCAL unavailable collision depth stops before any search and does not retry",function()
  local ship=localShip()
  forbidGlobalPlanner(ship)
  ship:onafterUpdateRoute()
  ship.terrain.makeProfile=function() return nil end
  checkNavigation(ship)
  equal(ship.state,"Holding") equal(ship.stops,1) equal(ship.localNavigation,nil)
  equal(ship.LastPathfindingResult.DepthCheck.Status,"unavailable")
  equal(#ship.dispatched,1) equal(ship.dispatched[1].speed,0) assertNoSearch()
  local queries,dispatches=ship.terrain.queries,#ship.dispatches
  ship.terrain.makeProfile=nil
  for i=1,3 do timerNow=i*10 checkNavigation(ship) end
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
    timerNow=10 checkNavigation(ship)
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
    checkNavigation(ship)
    equal(ship.warnings,1) equal(ship.localNavigation,nil) equal(ship.stops,0) assertNoSearch()
    if action=="disable" then equal(ship.pathfindingOn,false)
    elseif action=="retarget" then equal(#ship.dispatched,2) equal(ship.dispatched[2].uid,3)
    else equal(ship.dispatched[2].uid,2) near(ship.dispatched[2].x,0) near(ship.dispatched[2].y,20000) end
    timerNow=10 checkNavigation(ship)
    equal(ship.localNavigation,nil) assertNoSearch()
  end
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
  checkNavigation(ship)
  equal(attempts,0) equal(ship.warnings,1) assertNoSearch()
  clearance=2100 timerNow=10 checkNavigation(ship)
  equal(attempts,1) equal(ship.warnings,1) equal(ship.stops,0)
end)

test("LOCAL distant warning clears without ever changing the native route",function()
  local ship=localShip()
  ship.terrain.depthAt=function(point) return point.x>=4450 and point.x<=4550 and 5 or 40 end
  ship:onafterUpdateRoute()
  local route=ship.dispatched
  checkNavigation(ship)
  equal(ship.warnings,1) equal(ship.collisionwarning,true) assertNoSearch()
  ship.terrain.depthAt=nil
  timerNow=10 checkNavigation(ship)
  equal(ship.collisionwarning,false) equal(ship.clears,1)
  equal(ship.dispatched,route) equal(#ship.dispatches,1) equal(ship.localNavigation,nil)
  equal(ship.stops,0) assertNoSearch()
end)

test("LOCAL a faster ship starts before a slow ship would and plans beyond the obstruction",function()
  local ship=localShip()
  ship.velocity=30 -- Still moving faster than the commanded 10 m/s.
  ship.terrain.depthAt=function(point)
    return point.x>=2800 and point.x<=2900 and math.abs(point.y)<=200 and 5 or 40
  end
  ship:onafterUpdateRoute()
  checkNavigation(ship)
  local navigation=assert(ship.localNavigation)
  equal(navigation.Search.LastSearchResult.Window.Ahead,4000)
  assert(searches.astar>0) equal(ship.stops,0)
  assertClearPath(ship,navigation.Path)
end)

test("WAYPOINT mode still searches immediately for a distant obstacle inside the warning horizon",function()
  local ship=vessel():SetPathfindingMode(NAVYGROUP.PathfindingMode.WAYPOINT)
  ship.terrain.depthAt=function(point) return point.x>=4450 and point.x<=4550 and 5 or 40 end
  local attempts=0
  function ship:_FindPathToNextWaypoint() attempts=attempts+1 return true end
  ship:onafterUpdateRoute()
  checkNavigation(ship)
  equal(attempts,1) equal(ship.warnings,1) equal(ship.stops,0)
  assert(ship.LastNavigationCheck.ClearDistance>4000)
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
  equal(ship.LastPathfindingResult.StopReason,"no_steering_path")
  equal(ship.added,0) equal(#ship.waypoints,3)
end)


test("LOCAL smoothing does not strand a short final residual or accept a sharp initial turn",function()
  local ship=localShip()
  local nodes={}
  for _,x in ipairs({500,950,1000,1050}) do nodes[#nodes+1]=VECTOR:New(x,0,0) end
  local points,reason=ship:_SimplifyLocalPath(VECTOR:New(0,0,0),0,nodes,false,10,0)
  assert(points,reason) equal(#points,2) near(points[1].x,950) near(points[2].x,1050)
  assertClearPath(ship,points)
  local rejected=ship:_SimplifyLocalPath(VECTOR:New(0,0,0),180,nodes,false,10,0)
  equal(rejected,nil)
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
    assert(waypoint.x<=3750.001 and math.abs(waypoint.y)<=1000.001)
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
  equal(ship.LastPathfindingResult.StopReason,"no_steering_path")
  equal(#ship.dispatches,1) equal(#ship.dispatched,1) equal(ship.dispatched[1].speed,0)
  equal(#ship.waypoints,3) equal(ship.waypoints[2].uid,2)
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
  timerNow=10 checkLocal(ship)
  equal(ship.currentwp,1) equal(ship.passingEvents,nil)
  followPath(ship,navigation.Path)
  timerNow=20 checkNavigation(ship)
  equal(ship.currentwp,2) equal(ship.passingEvents,1)
  equal(ship.waypoints[2].npassed,1) equal(ship.waypoints[2].task,originalTask)
  timerNow=30 checkNavigation(ship)
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
    timerNow=10 checkNavigation(ship)
    equal(ship.currentwp,2) equal(ship.taskSubmissions,1)
    equal(ship.installedTask.params.tasks[2].params.task,task.dcstask)
    equal(ship.pendingUpdate,nil) equal(#ship.dispatches,dispatches)
    equal(ship.localNavigationTaskUID,2)
    timerNow=20 checkNavigation(ship)
    equal(#ship.dispatches,dispatches) equal(ship.taskSubmissions,1)
    task.status=OPSGROUP.TaskStatus.EXECUTING ship.taskcurrent=task.id
    timerNow=30 checkNavigation(ship)
    equal(#ship.dispatches,dispatches)
    task.status=OPSGROUP.TaskStatus.DONE ship.taskcurrent=nil
    timerNow=40 checkNavigation(ship)
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
  timerNow=10 checkNavigation(ship)
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
  timerNow=10 checkNavigation(ship)
  equal(ship.currentwp,2) equal(ship.taskcurrent,1) equal(ship.localNavigation,nil)
  equal(ship.localNavigationTaskUID,2) equal(ship.pendingUpdate,nil) equal(#ship.dispatches,dispatches)
  timerNow=20 checkNavigation(ship)
  equal(ship.localNavigationTaskUID,2) equal(ship.pendingUpdate,nil) equal(#ship.dispatches,dispatches)
  task.status=OPSGROUP.TaskStatus.DONE ship.taskcurrent=0
  timerNow=30 checkNavigation(ship)
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
  ship.heading=10 timerNow=10 checkNavigation(ship)
  equal(ship:IsTurning(),true)
  assert(ship.terrain.queries>queries,"turning must not suspend local depth monitoring")
  equal(#ship.dispatches,dispatches)
  ship.heading=20 timerNow=20 checkNavigation(ship)
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

test("LOCAL stops before exhausting its validated route while still turning",function()
  local ship=localShip()
  activateLocal(ship)
  local navigation=ship.localNavigation
  local endpoint=navigation.Path[#navigation.Path]
  followPath(ship,navigation.Path)
  ship.turning=true
  checkLocal(ship)
  equal(ship.state,"Holding") equal(ship.stops,1)
  equal(ship.LastPathfindingResult.StopReason,"local_route_exhausted_in_turn")
  equal(ship.dispatched[1].speed,0)
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
    for i=1,3 do timerNow=i*100 checkNavigation(ship) end
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
  timerNow=600 checkNavigation(ship)
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
    timerNow=20 checkNavigation(ship)
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
  timerNow=10 checkNavigation(ship)
  equal(ship.localNavigation,nil) assertNoSearch()
  ship.terrain.depthAt=function(point) return point.y>=1450 and point.y<=1550 and math.abs(point.x)<=200 and 5 or 40 end
  timerNow=20 checkNavigation(ship)
  local navigation=assert(ship.localNavigation)
  equal(navigation.TargetUID,3) equal(ship.currentwp,1)
  for _,waypoint in ipairs(ship.dispatched) do
    near(waypoint.speed,UTILS.KnotsToMps(14)) near(waypoint.alt,-40)
    assert(waypoint.uid~=2 and waypoint.uid~=3)
  end
  timerNow=30 checkNavigation(ship)
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
  timerNow=10 checkNavigation(ship)
  near(checked[1].x,0) near(checked[1].z,5000)
  ship:onafterUpdateRoute(nil,nil,nil,nil,nil,14,40)
  equal(ship.dispatched[2].uid,3) equal(#ship.dispatched,2)
  near(ship.dispatched[2].speed,UTILS.KnotsToMps(14)) near(ship.dispatched[2].alt,-40)
  timerNow=20 checkNavigation(ship)
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
    timerNow=10 checkNavigation(ship)
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
    checkNavigation(ship)
    equal(ship.warnings,1) equal(ship.stops,0) equal(ship.localNavigation,nil)
    equal(ship.dispatched[2].uid,replacement.uid) equal(ship:_GetNavigationWaypoint(),replacement)
    assertNoSearch()
    timerNow=10 checkNavigation(ship)
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
  checkNavigation(ship)
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
  checkNavigation(ship)
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
  checkNavigation(ship)
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
  checkNavigation(ship)
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
  timerNow=10 checkNavigation(ship)
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
  timerNow=10 checkNavigation(ship)
  equal(ship.localNavigation,nil) equal(searches.grids,grids) equal(searches.astar,astar)
  equal(ship.currentwp,1)
end)

test("LOCAL commanded speed and submarine depth survive periodic replanning",function()
  local ship=localShip()
  activateLocal(ship,14,40)
  local navigation=ship.localNavigation
  local originalPath=navigation.Path
  for _,waypoint in ipairs(ship.dispatched) do near(waypoint.speed,UTILS.KnotsToMps(14)) near(waypoint.alt,-40) end
  followPath(ship,navigation.Path,2)
  ship.heading=navigation.Path[1]:GetHeadingTo(navigation.Path[2])
  ship.turningHeading=ship.heading ship.turningTime=timerNow
  timerNow=timerNow+2 checkLocal(ship)
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
  ship.turning=false checkLocal(ship)
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
    timerNow=10 checkNavigation(ship)
    equal(ship.state,"Holding") equal(#ship.dispatches,dispatches)
  end
end)


test("LOCAL shallow ship position stops with diagnostic evidence and no new search",function()
  local ship=localShip()
  assert(activateLocal(ship))
  local grids=searches.grids
  local logs={}
  function ship:I(message) logs[#logs+1]=message end
  ship.terrain.depth=9
  -- Step past the two-second boundary: decimal tick accumulation can round below it.
  timerNow=timerNow+2.1

  equal(checkLocal(ship),false)

  equal(ship.stops,1) equal(searches.grids,grids)
  local report=ship.LastPathfindingResult.DepthCheck
  equal(report.NavigationStage,"ship_position") equal(report.Depth,9)
  equal(report.Reason,"start_blocked") equal(report.Cause,"insufficient_depth")
  near(report.Point.x,ship.position.x) near(report.Point.z,ship.position.z)
  assert(logs[1]:find("action=stop",1,true))
  assert(logs[1]:find("depth=9 m",1,true))
  checkLocal(ship) equal(ship.stops,1)
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

  checkNavigation(ship)

  equal(ship.localNavigation,nil) near(checked.goal.x,5000) near(checked.goal.z,0)
  equal(ship.dispatched[2].uid,2) equal(ship.currentwp,1)
  ship._CheckLocalRoute=nil
  ship.position={x=1600,y=0,z=0} ship.heading=0 ship.turningHeading=0
  local searchesBefore=searches.astar
  timerNow=10 checkNavigation(ship)
  equal(ship.localNavigation,nil) equal(searches.astar,searchesBefore) equal(ship.collisionwarning,true)
  ship.position={x=4000,y=0,z=0}
  timerNow=20 checkNavigation(ship)
  assert(ship.localNavigation) equal(ship.localNavigation.TargetUID,2)
end)

test("LOCAL exit retains the commanded target speed depth and queued waypoint tasks",function()
  local ship=localShip()
  activateLocal(ship,14,40,3)
  local target=ship.waypoints[3]
  local task={id=7,waypoint=3,type=OPSGROUP.TaskType.WAYPOINT,status=OPSGROUP.TaskStatus.SCHEDULED}
  ship.taskqueue={task}

  checkNavigation(ship)

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
  timerNow=10 checkNavigation(ship)
  equal(ship.localNavigation,navigation)
  local checked
  local check=ship._CheckPathDepth
  function ship:_CheckPathDepth(start,goal)
    checked=goal
    return check(self,start,goal)
  end
  timerNow=20 checkNavigation(ship)
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
  checkNavigation(ship)
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

    checkNavigation(ship)

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


test("LOCAL wide turn still stops when the actual ship position is too shallow",function()
  local ship=localShip()
  assert(activateLocal(ship))
  ship.position={x=50,y=0,z=350} ship.turning=true
  ship.terrain.depthAt=function(point) return point.y>300 and 5 or 40 end
  local _,_,deviation=ship:_LocalRouteProgress(VECTOR:NewFromVec(ship.position))
  assert(deviation>150)
  timerNow=timerNow+2.1
  equal(checkLocal(ship),false)
  equal(ship.stops,1) equal(ship.LastPathfindingResult.StopReason,"start_blocked")
  equal(ship.LastPathfindingResult.DepthCheck.NavigationStage,"ship_position")
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

  timerNow=timerNow+10 equal(ship:_TryResumeWaypointRoute(),false) equal(#logs,3)
  timerNow=timerNow+60 equal(ship:_TryResumeWaypointRoute(),false) equal(#logs,6)
  ship:SetPathfindingMinDepth(25)
  timerNow=timerNow+1 equal(ship:_TryResumeWaypointRoute(),false) equal(#logs,9)
  equal(ship.stops,0)
end)

test("LOCAL target release still requires only minimum depth",function()
  local ship=localShip(12000):SetPathfindingPreferredDepth(30,2)
  assert(activateLocal(ship))
  ship.terrain.depth=21
  function ship:_GetLocalSearch() error("Direct target release must not start a search") end
  local astar=searches.astar
  assert(ship:_TryResumeWaypointRoute())
  equal(ship.localNavigation,nil) equal(ship.stops,0) equal(searches.astar,astar)
  equal(ship.dispatched[2].uid,2) equal(ship.currentwp,1)
  timerNow=10 checkNavigation(ship)
  equal(ship.localNavigation,nil) equal(searches.astar,astar) equal(ship.stops,0)
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
  local nodes={corner,goal}

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
    local path={point}
    if case=="depth_cost" then
      ship:SetPathfindingPreferredDepth(30,2)
      ship.terrain.depth=21
      path={VECTOR:New(50,0,50),point}
      search={EvaluateConnection=function(_,a,b)
        local cost=a:GetDistance(b,true)
        if a.x==0 and b.x==500 then cost=cost+1000 end
        return true,cost,{Status="clear"}
      end}
    end
    local points,reason,cost,report=ship:_SimplifyLocalPath(start,heading,path,false,10,0,search)
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


test("LOCAL backtracks from a greedy short-leg trap instead of losing a usable path",function()
  local ship=localShip()
  local nodes={}
  for _,point in ipairs({{800,0},{990,50},{1100,100},{1750,100}}) do
    nodes[#nodes+1]=VECTOR:New(point[1],0,point[2])
  end
  -- Only the earlier bend can connect to the endpoint; depth failure isolates this steering case.
  connectionRules(ship,function(a,b)
    return not (a.x==990 and b.x>=1100) and not (a.x==800 and b.x==1100)
  end)
  local points,reason,cost,report=ship:_SimplifyLocalPath(VECTOR:New(0,0,0),0,nodes,false,10,0)
  assert(points,reason)
  assert(report.Backtracks>0)
  near(points[1].x,800)
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
  for i=1,35 do nodes[i]=VECTOR:New(i*100,0,0) end
  connectionRules(ship,function(a,b) return b.x~=3500 end)
  local points,reason,cost,report=ship:_SimplifyLocalPath(VECTOR:New(0,0,0),0,nodes,false,10,0)
  equal(points,nil) equal(reason,"steering_budget_exceeded")
  equal(report.States,128) assert(report.Backtracks>0)
  equal(ship.stops,0) equal(#ship.dispatches,0)
end)

test("LOCAL depth-weighted corner correction prices the safe detour even when it adds length",function()
  local ship=localShip():SetPathfindingPreferredDepth(30,2)
  local start,corner,goal=VECTOR:New(0,0,0),VECTOR:New(500,0,0),VECTOR:New(900,0,600)
  ship.terrain.depthAt=function(p) return (p.x-480)^2+(p.y-60)^2<20^2 and 2 or 40 end
  local original=connectionCost(ship,start,corner)+connectionCost(ship,corner,goal)
  local points,reason,cost,report=ship:_SimplifyLocalPath(start,0,{corner,goal},true,10,0)
  assert(points,reason) assert(#report.CornerAdjustments>0)
  assert(cost>original,"this required outward correction should add length")
  local total,position=0,start
  for _,point in ipairs(points) do
    total=total+connectionCost(ship,position,point)
    position=point
  end
  near(cost,total)
end)

test("LOCAL backtracking restores an adjusted corner before trying another outgoing leg",function()
  local ship=localShip()
  local nodes={}
  for _,point in ipairs({{500,0},{800,500},{850,600},{1000,1000},{1500,1000}}) do
    nodes[#nodes+1]=VECTOR:New(point[1],0,point[2])
  end
  connectionRules(ship,function(a,b)
    return not (a.x==0 and b.x>=700) and a.x~=850
  end)
  function ship:_CheckLocalTurn(position)
    return position.x~=500,{Radius=125}
  end
  local tried={}
  function ship:_AdjustLocalTurn(previous,corner,following,speed,minLeg,shortGoal,cache,search)
    tried[#tried+1]=corner
    return NAVYGROUP._AdjustLocalTurn(self,previous,corner,following,speed,minLeg,shortGoal,cache,search)
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

test("LOCAL candidate comparison does not reward an arbitrary free target approach length",function()
  local ship=localShip()
  assert(activateLocal(ship))
  local plan=ship.LastPathfindingResult
  -- In uniformly deep water a short side exit plus a free 5 km approach must not win
  -- merely through that added progress over the straightforward front exit.
  equal(plan.PreflightExtensions,0) equal(plan.TargetApproachDistance,nil)
  assert(plan.SuffixLength>=plan.RequiredLength and plan.SuffixLength<3200)
  assert(math.abs(plan.Points[#plan.Points].z)<500)
end)

-- The first raw bend is too close to emit as a ship waypoint. Skipping it crosses
-- permitted but shallower water, so a usable steering route needs a cost increase.
local function steeringFallbackShip()
  local ship=localShip():SetPathfindingMinDepth(3.5):SetPathfindingPreferredDepth(15,100)
  ship.terrain.depthAt=function(p) return p.x>=100 and p.x<=400 and math.abs(p.y)<25 and 5 or 40 end
  local start=VECTOR:New(0,0,0)
  local nodes={VECTOR:New(50,0,50),VECTOR:New(500,0,50),VECTOR:New(1000,0,0)}
  return ship,start,nodes
end

test("LOCAL steering fallback allows necessary depth cost increase and reuses edge profiles",function()
  local ship,start,nodes=steeringFallbackShip()
  local calls=0
  local getSearch=ship._GetLocalSearch
  function ship:_GetLocalSearch(speed)
    local search=getSearch(self,speed)
    local evaluate=search.EvaluateConnection
    function search:EvaluateConnection(a,b)
      if a.x==0 and b.x==1000 then calls=calls+1 end
      return evaluate(self,a,b)
    end
    return search
  end

  local points,reason,cost,report=ship:_SimplifyLocalPath(start,0,nodes,false,10,0)

  assert(points,reason) equal(report.Pass,2) equal(report.FirstPass.Reason,"no_steering_path")
  assert(report.FirstPass.Rejections.depth_cost)
  assert(report.FirstPass.Rejections.leg_too_short)
  assert(cost>report.OriginalCost) equal(calls,1)
  equal(#points,1) near(points[1].x,1000)
  near(cost,connectionCost(ship,start,points[1]))
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

    equal(points,nil) equal(reason,unknown and "data_unavailable" or "no_steering_path") equal(report.Pass,2)
    assert(report.FirstPass.Rejections.depth_cost)
    local depth=assert(report.Examples.turn_clearance.DepthCheck)
    equal(depth.Status,unknown and "unavailable" or "blocked")
    if not unknown then near(depth.Depth,2) end
    equal(report.Rejections.depth_cost,nil) equal(ship.stops,0)
  end
end)

test("LOCAL steering revalidates raw path depth before considering shortcuts",function()
  local ship,start,nodes=steeringFallbackShip()
  nodes[3]=VECTOR:New(1100,0,0)
  local originalDepth=ship.terrain.depthAt
  ship.terrain.depthAt=function(p) return p.x>750 and p.x<850 and 2 or originalDepth(p) end
  local points,reason=ship:_SimplifyLocalPath(start,0,nodes,false,10,0)
  equal(points,nil) equal(reason,"connections_blocked")
  equal(#ship.dispatches,0)
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
    checkNavigation(ship)
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
    timerNow=2 checkNavigation(ship)
    equal(ship:IsTurning(),true) equal(routeChecks,1) equal(ship.stops,1) assertNoSearch()
    equal(ship.LastPathfindingResult.StopReason,"nearfield_blocked")
    equal(ship.LastPathfindingResult.DepthCheck.NavigationStage,"ship_lookahead")
    equal(ship.state,"Holding") equal(ship.currentwp,1)
    equal(ship.dispatched[1].speed,0)
    local profiles=ship.terrain.profiles
    timerNow=4 checkNavigation(ship)
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
  checkNavigation(ship)
  ship.collisionwarning=true
  local profiles=ship.terrain.profiles
  for t=2,8,2 do timerNow=t checkNavigation(ship) end
  assert(ship.terrain.profiles>profiles) equal(checks,1) equal(ship.collisionwarning,true)
  timerNow=10 checkNavigation(ship)
  equal(checks,2) equal(ship.collisionwarning,false) assertNoSearch() equal(#ship.dispatches,0)
end)

test("nearfield unavailable data stops once without starting a search",function()
  local ship=localShip()
  ship.terrain.makeProfile=function() return nil end
  checkNavigation(ship)
  equal(ship.stops,1) assertNoSearch()
  equal(ship.LastPathfindingResult.DepthCheck.Status,"unavailable")
  equal(ship.LastPathfindingResult.StopReason,"profile_unavailable")
  timerNow=2 checkNavigation(ship) equal(ship.stops,1)
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
    checkNavigation(ship)
    equal(ship.terrain.queries,0) equal(ship.stops,0) assertNoSearch()
  end
  for _,action in ipairs({"hold","disable"}) do
    local ship=localShip()
    ship.terrain.depth=1
    function ship:OnAfterCollisionWarning()
      if action=="hold" then self:FullStop() else self:SetPathfindingOff() end
    end
    checkNavigation(ship)
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


local function sameValues(first,last)
  equal(type(first),type(last))
  if type(first)~="table" then equal(first,last) return end
  for key,value in pairs(first) do sameValues(value,last[key]) end
  for key in pairs(last) do assert(first[key]~=nil,"Unexpected route field: "..tostring(key)) end
end

test("diagnostics leave LOCAL routes and terrain work unchanged",function()
  local function run(enabled)
    timerNow=0 -- Compare the same simulation-time safety-check phase.
    local ship=localShip():SetPathfindingMinDepth(3.5):SetPathfindingPreferredDepth(15,10)
    ship:SetPathfindingWorkBudget(512,1000,2000) -- Keep slice boundaries independent of diagnostic CPU overhead.
    ship.terrain.depth=10
    if enabled then ship:SetPathfindingDiagnostics(true) end
    assert(activateLocal(ship))
    return ship,ship:GetPathfindingDiagnostics()
  end
  local plain,disabled=run(false)
  local measured,metrics=run(true)
  sameValues(plain.dispatches,measured.dispatches)
  equal(plain.terrain.profiles,measured.terrain.profiles)
  equal(plain.terrain.queries,measured.terrain.queries)
  equal(disabled.Enabled,false) equal(disabled.SearchAttempts,0)
  equal(metrics.ProfileQueries,measured.terrain.profiles)
  equal(metrics.RouteSubmissions,#measured.dispatches)
  equal(metrics.SearchAttempts,measured.LastPathfindingResult.Attempts)
  assert(metrics.ValidityRequests>0 and metrics.ValidityCacheHits>0)
  assert(metrics.CostRequests>0 and metrics.CostCacheHits>0)
  assert(metrics.PeakRetainedCells>0 and metrics.Scopes>=1 and metrics.Errors==0)
  assert(metrics.Operations.local_update.Calls>=1)
  print(string.format("BASELINE LOCAL: searches=%d profiles=%d seabed=%d routes=%d cells=%d validity=%d/%d cost=%d/%d cpu_s=%.6f",
    metrics.SearchAttempts,metrics.ProfileQueries,measured.terrain.queries,metrics.RouteSubmissions,metrics.PeakRetainedCells,
    metrics.ValidityCacheHits,metrics.ValidityRequests,metrics.CostCacheHits,metrics.CostRequests,metrics.CPUSeconds))
end)

test("diagnostics also measure waypoint expansion and explicit route submissions",function()
  local ship=vessel(2000):SetPathfindingDiagnostics(true)
  ship:_FindPathToNextWaypoint()
  local metrics=ship:GetPathfindingDiagnostics()
  assert(metrics.SearchAttempts>0 and metrics.ValidityRequests>0)
  equal(metrics.SearchAttempts,#ship.LastPathfindingResult.Attempts)
  equal(metrics.ProfileQueries,ship.terrain.profiles)
  ship:onafterUpdateRoute()
  ship:onafterFullStop()
  metrics=ship:GetPathfindingDiagnostics()
  equal(metrics.RouteSubmissions,#ship.dispatches) assert(metrics.RouteSubmissions>=2)
  assert(metrics.Operations.waypoint_plan and metrics.Operations.route_update)
end)

test("diagnostics intervals and caller snapshots are independent",function()
  local ship=localShip():SetPathfindingDiagnostics()
  assert(activateLocal(ship))
  local first=ship:GetPathfindingDiagnostics()
  equal(ship:SetPathfindingDiagnostics(true),ship)
  local repeated=ship:GetPathfindingDiagnostics()
  equal(repeated.Enabled,true) equal(repeated.Scopes,first.Scopes)
  local updateCalls=first.Operations.local_update.Calls
  first.Operations.local_update.Calls=999 first.ProfileQueries=-1
  equal(ship:GetPathfindingDiagnostics().Operations.local_update.Calls,updateCalls)
  ship:SetPathfindingDiagnostics(false)
  local frozen=ship:GetPathfindingDiagnostics()
  ship:onafterUpdateRoute()
  sameValues(ship:GetPathfindingDiagnostics(),frozen)
  ship:SetPathfindingDiagnostics(true)
  local fresh=ship:GetPathfindingDiagnostics()
  equal(fresh.Scopes,0) equal(fresh.ProfileQueries,0) equal(next(fresh.Operations),nil)
  equal(localShip():GetPathfindingDiagnostics().Enabled,false)
  assert(frozen.ProfileQueries>0)
end)

test("nested measurements preserve trailing nil and do not double count CPU or profiles",function()
  local savedClock=os.clock
  local now=0
  os.clock=function() return now end
  local ok,err=pcall(function()
    local ship=vessel():SetPathfindingDiagnostics()
    local function inner(self,...)
      equal(select("#",...),3) equal(select(2,...),false)
      now=now+2
      assert(PATHLINE.CheckDepth({x=0,y=0,z=0},{x=100,y=0,z=0},3.5,0))
      return nil,7,nil
    end
    local function outer(self)
      now=now+1
      local function results(...)
        equal(select("#",...),3) equal(select(1,...),nil) equal(select(2,...),7) equal(select(3,...),nil)
      end
      results(self:_MeasurePathfinding("inner",inner,1,false,nil))
      now=now+3
      return nil,9,nil
    end
    local function results(...)
      equal(select("#",...),3) equal(select(2,...),9) equal(select(3,...),nil)
    end
    results(ship:_MeasurePathfinding("outer",outer))
    local metrics=ship:GetPathfindingDiagnostics()
    equal(metrics.Scopes,1) equal(metrics.CPUSeconds,6) equal(metrics.MaxScopeCPUSeconds,6)
    equal(metrics.Operations.outer.CPUSeconds,6) equal(metrics.Operations.inner.CPUSeconds,2)
    equal(metrics.ProfileQueries,ship.terrain.profiles) equal(metrics.ProfileQueries,1)
  end)
  os.clock=savedClock
  assert(ok,err)
end)

test("diagnostics preserve callback errors and release the measurement scope",function()
  local ship=vessel():SetPathfindingDiagnostics()
  local sentinel={cause="native profile failure"}
  land.profile=function() error(sentinel) end
  local ok,err=pcall(function()
    ship:_MeasurePathfinding("outer",function(self)
      self:_MeasurePathfinding("inner",function()
        PATHLINE.CheckDepth({x=0,y=0,z=0},{x=100,y=0,z=0},3.5,0)
      end)
    end)
  end)
  equal(ok,false) equal(err,sentinel)
  local metrics=ship:GetPathfindingDiagnostics()
  equal(metrics.Errors,1) equal(metrics.Operations.inner.Errors,1) equal(metrics.Operations.outer.Errors,1)
  equal(metrics.ProfileQueries,1)
  equal(ship:SetPathfindingDiagnostics(false),ship)
  ship:SetPathfindingDiagnostics()
  equal(ship:GetPathfindingDiagnostics().Errors,0)
end)

test("sanitized clocks leave CPU unavailable while counters remain usable",function()
  local savedOS=os
  local ok,err=pcall(function()
    local ship=vessel()
    os=nil
    ship:SetPathfindingDiagnostics()
    ship:_MeasurePathfinding("probe",function()
      assert(PATHLINE.CheckDepth({x=0,y=0,z=0},{x=100,y=0,z=0},3.5,0))
    end)
    local metrics=ship:GetPathfindingDiagnostics()
    equal(metrics.CPUSeconds,nil) equal(metrics.MaxScopeCPUSeconds,nil)
    equal(metrics.Operations.probe.CPUSeconds,nil) equal(metrics.ProfileQueries,1)
    local lines={}
    function ship:I(line) lines[#lines+1]=line end
    ship:LogPathfindingDiagnostics()
    equal(#lines,3)
    for _,line in ipairs(lines) do assert(#line<400) end
  end)
  os=savedOS
  assert(ok,err)
end)

test("observed retained cells deduplicate the leg planner and include a live probe",function()
  local ship=vessel():SetPathfindingDiagnostics()
  local search=ASTAR:New(GRID.Type.RECTANGLE):SetEndpoints(coord(0),coord(1000))
  search:GetGrid():SetResolution(100):SetCorridor(400,100)
  assert(search:CreateGrid())
  local current=search:GetGrid()
  local count=current:GetCellCount()
  ship.localNavigation={Search=search}
  ship.pathfindingDebugSearch=search
  ship:_ObservePathfindingCells(search)
  equal(ship:GetPathfindingDiagnostics().PeakRetainedCells,count)
  local other=GRID:New("measurement",GRID.Type.RECTANGLE):SetResolution(100):SetCorridor(400,100)
  assert(other:CreateFromBounds(coord(0),coord(1000)))
  ship.localNavigation.Job={ActiveSearch={GetGrid=function() return other end}}
  ship:_ObservePathfindingCells(search)
  equal(ship:GetPathfindingDiagnostics().PeakRetainedCells,count+other:GetCellCount())
end)

-- Cooperative integration tests intentionally observe pending jobs before pumping them.
test("LOCAL starts a bounded job without submitting provisional movement",function()
  local ship=localShip():SetPathfindingWorkBudget(1,0.005,2000)
  assert(ship:_CheckLocalNavigation(true))
  local navigation=assert(ship.localNavigation)
  assert(navigation.Job)
  equal(navigation.Path,nil) equal(#ship.dispatches,0)
  ship:_AdvanceLocalPlanning()
  assert(navigation.Job,"one work item must not finish a distant search")
  equal(navigation.Path,nil) equal(#ship.dispatches,0)
  ship:FullStop()
  equal(ship.localNavigation,nil) equal(ship.stops,1)
end)

test("LOCAL suspended jobs cannot dispatch after hold disable retarget or destruction",function()
  for _,action in ipairs({"hold","disable","retarget","destroy"}) do
    local ship=localShip():SetPathfindingWorkBudget(1,0.005,2000)
    assert(ship:_CheckLocalNavigation(true))
    ship:_AdvanceLocalPlanning()
    assert(ship.localNavigation.Job)
    if action=="hold" then
      ship:FullStop()
    elseif action=="disable" then
      ship:SetPathfindingOff()
    elseif action=="retarget" then
      ship:onafterUpdateRoute(nil,nil,nil,3)
    else
      ship.alive=false
    end
    local dispatched=#ship.dispatches
    for _=1,3 do
      timerNow=timerNow+0.1
      ship:_CheckLocalNavigation()
    end
    equal(#ship.dispatches,dispatched,"a retired generation issued a route")
    if action=="hold" then equal(ship.state,"Holding") end
    if action=="retarget" then equal(ship:_GetNavigationWaypoint().uid,3) end
  end
end)

test("LOCAL small velocity fluctuations retain work and publish a moving route",function()
  local ship=localShip():SetPathfindingWorkBudget(512,1000,2000)
  ship.speedWp=13.375
  ship.velocity=13.375
  ship.terrain.depth=10
  -- Controlled shallow obstruction at the observed activation distance, not a DCS terrain replay.
  ship.terrain.depthAt=function(point)
    return point.x>=2087 and point.x<=2300 and math.abs(point.y)<=100 and 2.43 or 10
  end
  ship:SetPathfindingMinDepth(3.5):SetPathfindingPreferredDepth(15,10)
  local starts=0
  local startPlanning=NAVYGROUP._StartLocalPlanning
  function ship:_StartLocalPlanning(...)
    starts=starts+1
    return startPlanning(self,...)
  end
  assert(ship:_CheckLocalNavigation(true))
  local job=assert(ship.localNavigation.Job)
  for tick=1,800 do
    ship.velocity=13.375+0.05*(1-1/(tick+1))
    ship.position.x=ship.position.x+ship.velocity*0.1
    timerNow=timerNow+0.1
    ship:_CheckLocalNavigation()
    if ship.localNavigation and ship.localNavigation.Path then break end
  end
  equal(starts,1,"small measured-speed changes must not repeatedly discard useful work")
  local navigation=assert(ship.localNavigation)
  assert(navigation.Path,"moving ship received no route within 80 simulation seconds")
  equal(ship.stops,0) equal(#ship.dispatches,1)
  assertClearPath(ship,navigation.Path)
  assert(ship.position.x<2087-(math.max(400,ship.velocity*60)+ship.velocity*10),
    "route publication must precede exhaustion of the checked approach reserve")
  near(ship.dispatched[2].speed,13.375)
  assert(job.Speed>=13.425,"steering must cover the whole admitted speed range")
  print(string.format("MOVING SPEED FLUCTUATION: jobs=%d slices=%d sim_s=%.1f clear_m=%.1f speed_bound=%.3f",
    starts,job.Slices,timerNow,2087-ship.position.x,job.Speed))
end)

test("LOCAL speed envelope rejects a larger increase before stale work is submitted",function()
  for _,stage in ipairs({"running","ready"}) do
    local ship=localShip():SetPathfindingWorkBudget(512,1000,2000)
    assert(ship:_CheckLocalNavigation(true))
    local job=assert(ship.localNavigation.Job)
    ship:_AdvanceLocalPlanning()
    if stage=="ready" then
      for _=1,2000 do
        if ship.localNavigation.Pending then break end
        ship:_AdvanceLocalPlanning()
      end
      assert(ship.localNavigation.Pending)
    end
    ship.velocity=job.Speed+0.01
    if stage=="running" then ship:_AdvanceLocalPlanning()
    else ship:_CommitLocalPlanning(VECTOR:NewFromVec(ship.position)) end
    equal(ship.localNavigation.Job,nil) equal(ship.localNavigation.Pending,nil)
    equal(#ship.dispatches,0)
    equal(ship.localNavigation.CancelReason,"speed_exceeded")
  end
end)

test("LOCAL reserve stops retain one bounded job diagnosis before discarding its coroutine",function()
  local savedOS=os
  local ok,err=pcall(function()
    for _,mode in ipairs({"enabled","disabled","no_clock"}) do
      os=savedOS
      if mode=="no_clock" then os=nil end
      local ship=localShip():SetPathfindingWorkBudget(1,0.005,2000)
      if mode~="disabled" then ship:SetPathfindingDiagnostics(true) end
      local logs={}
      function ship:I(line) logs[#logs+1]=line end
      function ship:_BuildLocalRoute(job)
        job.Phase="extension_steering"
        job.Requests,job.Candidate,job.Extension=2,3,1
        job.LastRejection="local_turn_exit_too_short"
        for _=1,10 do self:_LocalPlanningCheckpoint(1) end
      end
      assert(ship:_CheckLocalNavigation(true))
      ship:_AdvanceLocalPlanning()
      local job=assert(ship.localNavigation.Job)
      equal(#logs,0,"working slices must not emit repeated status logs")
      function ship:_CheckNavigationAhead()
        return false,"profile_blocked",{Status="blocked",Reason="profile_blocked",ClearDistance=700,
          Distance=5000,RequiredDepth=20,Depth=5}
      end
      if mode=="no_clock" then
        function ship:GetVelocity() return nil end
      end
      timerNow=job.Started+12.5
      ship:_CheckLocalNavigation()
      equal(ship.state,"Holding") equal(ship.localNavigation,nil)
      local report=assert(ship.LastPathfindingResult.Planning)
      equal(report.Reason,"local_planning_reserve") equal(report.Phase,"extension_steering")
      equal(report.Requests,2) equal(report.Candidate,3) equal(report.Extension,1)
      equal(report.LastRejection,"local_turn_exit_too_short") equal(report.Slices,1)
      near(report.SimulationSeconds,12.5)
      equal(report.SpeedBound,job.Speed)
      if mode=="no_clock" then equal(report.ActualSpeed,nil) else equal(report.ActualSpeed,10) end
      equal(report.Thread,nil) equal(report.ActiveSearch,nil)
      if mode=="no_clock" then equal(report.CPUSeconds,nil)
      else assert(type(report.CPUSeconds)=="number" and report.CPUSeconds>=0) end
      local outcomes=0
      for _,line in ipairs(logs) do
        if line:find("Local planning ",1,true) then outcomes=outcomes+1 end
      end
      equal(outcomes,mode=="disabled" and 0 or 3,"FullStop cleanup must not duplicate the outcome")
      if mode=="no_clock" then
        assert(table.concat(logs,"\n"):find("actual=unavailable",1,true),"missing velocity must not be reported as zero")
      end
    end
  end)
  os=savedOS
  assert(ok,err)
end)

test("LOCAL cancellation inside a worker includes its active CPU slice exactly once",function()
  local savedOS=os
  local cpu=0
  local ok,err=pcall(function()
    os={clock=function() return cpu end}
    local ship=localShip():SetPathfindingWorkBudget(512,100,2000)
    function ship:_BuildLocalRoute(job)
      cpu=cpu+0.25
      self:FullStop()
      self:_LocalPlanningCheckpoint(1)
    end
    assert(ship:_CheckLocalNavigation(true))
    ship:_AdvanceLocalPlanning()
    local report=assert(ship.LastLocalPlanningReport)
    near(report.CPUSeconds,0.25)
    near(report.SimulationSeconds,0)
    equal(ship.stops,1) equal(ship.localNavigation,nil)
  end)
  os=savedOS
  assert(ok,err)
end)

test("LOCAL work settings validate positive finite budgets",function()
  local ship=localShip()
  equal(ship:SetPathfindingWorkBudget(100,0.01,400),ship)
  for _,args in ipairs({{0,0.01,400},{1.5,0.01,400},{100,0,400},{100,math.huge,400},{100,0.01,0},{100,0.01,1.5}}) do
    equal(pcall(function() ship:SetPathfindingWorkBudget(unpack(args)) end),false)
  end
end)

test("LOCAL slice limits stop bounded work without a CPU clock or provisional route",function()
  local savedOS=os
  local ok,err=pcall(function()
    os=nil
    local ship=localShip():SetPathfindingWorkBudget(1,0.005,2)
    activateLocal(ship)
    equal(ship.state,"Holding") equal(ship.stops,1)
    equal(#ship.dispatches,1) equal(ship.dispatched[1].speed,0)
    assert(ship.LastPathfindingResult.StopReason:find("limit",1,true))
  end)
  os=savedOS
  assert(ok,err)
end)

test("LOCAL public requests retain exact goal coordinates and cannot announce early arrival",function()
  local ship=localShip(1777)
  ship.waypoints[2].coordinate=coord(1777,123)
  assert(activateLocal(ship))
  local navigation=assert(ship.localNavigation)
  assert(navigation.GoalReached)
  local last=navigation.Path[#navigation.Path]
  near(last.x,1777) near(last.z,123)
  assertClearPath(ship,navigation.Path)
  equal(ship.currentwp,1) equal(ship.passingEvents,nil)
  equal(navigation.Search.LastSearchResult.Outcome,"goal_path")
end)

test("LOCAL public search detours around an island with freshly checked steering connections",function()
  local ship=localShip()
  land.surfaceAt=function(p)
    return p.x>=750 and p.x<=1250 and math.abs(p.z)<=300 and land.SurfaceType.LAND or land.SurfaceType.WATER
  end
  ship.terrain.depthAt=function(p) return p.x>=750 and p.x<=1250 and math.abs(p.y)<=300 and 0 or 40 end
  assert(activateLocal(ship))
  local navigation=assert(ship.localNavigation)
  assertClearPath(ship,navigation.Path)
  local lateral=false
  for _,point in ipairs(navigation.Path) do if math.abs(point.z)>300 then lateral=true end end
  assert(lateral,"the submitted route did not avoid the island")
  equal(ship.stops,0) equal(navigation.GoalReached,false)
end)

test("LOCAL keeps route vectors independent of public candidate positions and later requests",function()
  local ship=localShip()
  assert(activateLocal(ship))
  local navigation=assert(ship.localNavigation)
  local report=navigation.Search.LastSearchResult
  equal(report.Status,"complete") assert(#report.Candidates>0)
  local retained={}
  for index,point in ipairs(navigation.Path) do retained[index]=point:GetVec3() end
  for _,candidate in ipairs(report.Candidates) do
    for _,position in ipairs(candidate.Positions) do
      for _,point in ipairs(navigation.Path) do assert(point~=position) end
    end
  end
  navigation.Search:StartLocalSearch(VECTOR:New(500,0,0),ship.waypoints[2].coordinate,0)
  for index,point in ipairs(navigation.Path) do
    near(point.x,retained[index].x) near(point.z,retained[index].z)
  end
  equal(report.Status,"complete") equal(#ship.dispatches,1)
  ship:FullStop()
end)

test("LOCAL route preparation rejects the observed short turning suffix behind a long approach",function()
  local ship=localShip()
  local points={VECTOR:New(78649.1,0,-59869.6),VECTOR:New(79264.6,0,-59246.5),
    VECTOR:New(79048.3,0,-58787.4),VECTOR:New(78137.0,0,-58885.3)}
  local job={Speed=13.37,Heading=points[1]:GetHeadingTo(points[2])}
  local usable,metrics,reason=ship:_CheckLocalRoutePreparation(points,job,3,false)
  equal(usable,false) equal(reason,"local_route_too_short")
  assert(metrics.Length>2000 and metrics.SuffixLength<metrics.StopReserve)
  near(metrics.StopReserve,935.9,0.01)
  local incoming=points[3]:GetHeadingTo(points[4])
  for _=1,3 do points[#points+1]=points[#points]:Translate(1000,incoming,true) end
  usable,metrics,reason=ship:_CheckLocalRoutePreparation(points,job,3,false)
  assert(usable,reason) assert(metrics.SuffixLength>=metrics.RequiredLength)
  equal(#ship.dispatches,0)
end)

test("LOCAL preparation checks every turning exit even when the total new suffix is long",function()
  local ship=localShip()
  local points={VECTOR:New(0,0,0),VECTOR:New(2500,0,0),VECTOR:New(2900,0,400)}
  local job={Speed=10,Heading=0}
  local usable,metrics,reason=ship:_CheckLocalRoutePreparation(points,job,1,false)
  equal(usable,false) equal(reason,"local_turn_exit_too_short")
  equal(metrics.ShortTurnIndex,2)
  assert(metrics.SuffixLength>=metrics.RequiredLength)
  assert(metrics.TurnRemaining<metrics.StopReserve)
  assert(ship:_CheckLocalRoutePreparation(points,job,1,true),"a checked exact goal needs no onward continuation")
  ship.velocity=20
  local _,faster=ship:_CheckLocalRoutePreparation(points,job,1,false)
  near(faster.StopReserve,1400)
end)

test("LOCAL prices submitted geometry while preserving public learned candidate rankings",function()
  for _,penalty in ipairs({0,10000}) do
    local ship=localShip()
    local evaluator=ASTAR:New():SetValidNeighbourDepth(20,50)
    local first,second={},{}
    for index=0,3 do first[#first+1]={x=index*1000,y=0,z=0} end
    for index=0,4 do second[#second+1]={x=index*900,y=0,z=index*400} end
    local secondCost=4*math.sqrt(900*900+400*400)
    local report={Status="complete",StopReason="path_found",RequestID=1,Candidates={
      {Positions=first,Cost=3000,Score=20000+penalty,LearnedPenalty=penalty,ReachesGoal=false},
      {Positions=second,Cost=secondCost,Score=secondCost+17000,LearnedPenalty=0,ReachesGoal=false}}}
    local search={}
    function search:StartLocalSearch() self.LastSearchResult=report end
    function search:UpdateLocalProgress() return self end
    function search:EvaluateConnection(a,b) return evaluator:EvaluateConnection(a,b) end
    function ship:_GetLocalSearch() return search end
    local start=VECTOR:New(0,0,0)
    local job={Position=start,Heading=0,Speed=10,Alt=0,TargetPosition=VECTOR:New(20000,0,0),Prefix={start}}
    local points,plan,reason=ship:_BuildLocalRoute(job)
    assert(points,reason)
    equal(plan.Candidate,penalty==0 and 1 or 2)
    local candidate=report.Candidates[plan.Candidate]
    near(plan.Score,plan.Cost+candidate.Score-candidate.Cost)
    assertClearPath(ship,points)
    near(first[4].x,3000) near(second[5].z,1600)
    for _,point in ipairs(points) do
      for _,original in ipairs(candidate.Positions) do assert(point~=original) end
    end
    equal(#ship.dispatches,0)
  end
end)

test("LOCAL fully prepared primary alternatives precede cheaper unprepared short exits",function()
  local ship=localShip()
  local evaluator=ASTAR:New():SetValidNeighbourDepth(20,50)
  local report={Status="complete",StopReason="path_found",RequestID=1,Candidates={
    {Positions={{x=0,y=0,z=0},{x=600,y=0,z=0}},Cost=600,Score=1000,LearnedPenalty=0,ReachesGoal=false},
    {Positions={{x=0,y=0,z=0},{x=1000,y=0,z=0},{x=2000,y=0,z=0},{x=3000,y=0,z=0}},
      Cost=3000,Score=20000,LearnedPenalty=0,ReachesGoal=false}}}
  local search={Requests=0}
  function search:StartLocalSearch() self.Requests=self.Requests+1 self.LastSearchResult=report end
  function search:UpdateLocalProgress() return self end
  function search:EvaluateConnection(a,b) return evaluator:EvaluateConnection(a,b) end
  function ship:_GetLocalSearch(speed,probe)
    assert(not probe,"an already prepared primary alternative must not wait for speculative short exits")
    return search
  end
  local start=VECTOR:New(0,0,0)
  local job={Position=start,Heading=0,Speed=10,Alt=0,TargetPosition=VECTOR:New(20000,0,0),Prefix={start}}

  local points,plan,reason=ship:_BuildLocalRoute(job)

  assert(points,reason) equal(plan.Candidate,2) equal(search.Requests,1)
  equal(plan.PreflightExtensions,0) assertClearPath(ship,points)
end)

test("LOCAL future-anchor probes cannot replace the persistent learning or actual observations",function()
  local ship=localShip()
  ship.localNavigation={}
  local search=ship:_GetLocalSearch(10)
  search:UpdateLocalProgress(VECTOR:New(50,0,0))
  local probe=ship:_GetLocalSearch(10,true)
  assert(probe~=search) equal(ship.localNavigation.Search,search)
  equal(probe.LocalLearningLimit,0)
  probe:StartLocalSearch(VECTOR:New(2000,0,0),VECTOR:New(20000,0,0),0)
  equal(probe.LastSearchResult.Progress.Status,"unobserved")
  search:StartLocalSearch(VECTOR:New(1000,0,0),VECTOR:New(20000,0,0),0)
  local progress=search.LastSearchResult.Progress
  near(progress.Position.x,50) equal(progress.HistoryCount,1) near(progress.Distance,0)
  search:CancelSearch() probe:CancelSearch()
end)

local function installedFixture(points)
  local ship=localShip()
  ship:_CheckLocalNavigation(true)
  ship:_CancelLocalPlanning("controlled_route_fixture")
  assert(ship:_InstallLocalRoute(points,{GoalReached=false,Cost=3000},points[1]))
  return ship
end

-- DCS drawing endpoints and timer dispatch only; GRID/ASTAR/PATHLINE remain production code.
-- Other regressions retain their strict ban on unexpected navigation retry timers.
local function withDrawing(run)
  local oldTrigger,oldSchedule,oldRemove=trigger,timer.scheduleFunction,timer.removeFunction
  local oldMarkID,oldRemoveMark=UTILS.GetMarkID,UTILS.RemoveMark
  local view={marks={},scheduled={},callbacks={},nextID=0,nextTimerID=0,maxBatch=0}
  function UTILS.GetMarkID()
    view.nextID=view.nextID+1
    return view.nextID
  end
  trigger={action={}}
  function trigger.action.markupToAll(shape,side,id,...)
    local args={...}
    local count=select("#",...)
    view.marks[id]={kind="grid",fill=deepcopy(args[count-3]),side=side,shape=shape}
  end
  function trigger.action.lineToAll(side,id,a,b,color,lineType)
    view.marks[id]={kind="route",a=deepcopy(a),b=deepcopy(b),color=deepcopy(color),side=side,lineType=lineType}
  end
  function trigger.action.removeMark(id) view.marks[id]=nil end
  function UTILS.RemoveMark(id) trigger.action.removeMark(id) end
  function timer.scheduleFunction(fn,args,at)
    view.nextTimerID=view.nextTimerID+1
    local task={fn=fn,args=args,at=at}
    view.scheduled[view.nextTimerID]=task
    view.callbacks[#view.callbacks+1]=task
    return view.nextTimerID
  end
  function timer.removeFunction(id) view.scheduled[id]=nil end
  function view:collect(kind)
    local ids={}
    for id,mark in pairs(self.marks) do
      if mark.kind==kind then ids[#ids+1]=id end
    end
    table.sort(ids)
    return ids
  end
  function view:step()
    local id,task
    for candidate,entry in pairs(self.scheduled) do
      if not task or entry.at<task.at then id,task=candidate,entry end
    end
    if not task then return false end
    timerNow=math.max(timerNow,task.at)
    local before=self.nextID
    local nextTime=task.fn(task.args,timerNow)
    self.maxBatch=math.max(self.maxBatch,self.nextID-before)
    if self.scheduled[id]==task and nextTime then task.at=nextTime else self.scheduled[id]=nil end
    return true
  end
  function view:flush()
    local steps=0
    while self:step() do
      steps=steps+1
      assert(steps<10000,"grid display did not finish")
    end
  end
  local ok,err=pcall(run,view)
  trigger,timer.scheduleFunction,timer.removeFunction=oldTrigger,oldSchedule,oldRemove
  UTILS.GetMarkID,UTILS.RemoveMark=oldMarkID,oldRemoveMark
  if not ok then error(err,0) end
end

local function assertDrawnRoute(view,route)
  local ids=view:collect("route")
  equal(#ids,#route-1,"exact submitted segment count")
  for i,id in ipairs(ids) do
    local mark=view.marks[id]
    for _,endpoint in ipairs({{mark.a,route[i]},{mark.b,route[i+1]}}) do
      near(endpoint[1].x,endpoint[2].x)
      near(endpoint[1].y,endpoint[2].alt)
      near(endpoint[1].z,endpoint[2].y)
    end
    equal(mark.side,-1)
    equal(mark.color[1],1) equal(mark.color[2],0) equal(mark.color[3],1) equal(mark.color[4],1)
  end
  return ids
end

test("LOCAL display publishes a depth grid and exact route without changing planning",function()
  withDrawing(function(view)
    local function configured()
      local ship=localShip(1500):SetPathfindingMinDepth(3.5):SetPathfindingPreferredDepth(15,10)
      ship.terrain.depthAt=function(point) return point.x<300 and 5 or 40 end
      return ship
    end
    local quiet=configured()
    assert(activateLocal(quiet))
    equal(next(view.marks),nil) equal(next(view.scheduled),nil)
    local visible=configured()
    visible.verbose=10
    assert(activateLocal(visible))
    equal(#visible.dispatches,#quiet.dispatches)
    equal(#visible.dispatched,#quiet.dispatched)
    for i,point in ipairs(visible.dispatched) do
      near(point.x,quiet.dispatched[i].x) near(point.y,quiet.dispatched[i].y)
      near(point.speed,quiet.dispatched[i].speed)
    end
    assertDrawnRoute(view,visible.dispatched)
    assert(next(view.scheduled),"nontrivial grid is queued for bounded drawing")
    local queriesBefore=visible.terrain.queries
    view:flush()
    assert(visible.terrain.queries>queriesBefore,"depth colors query cell centers in drawing batches")
    local gridIDs=view:collect("grid")
    assert(#gridIDs>25,"completed local window has visible cells")
    assert(view.maxBatch<=25,"drawing remains bounded per timer callback")
    local blue,shallow=false,false
    for _,id in ipairs(gridIDs) do
      local mark=view.marks[id]
      equal(mark.shape,7) equal(mark.side,-1)
      blue=blue or (mark.fill[1]==0 and math.abs(mark.fill[2]-0.15)<1e-7 and math.abs(mark.fill[3]-0.8)<1e-7)
      shallow=shallow or mark.fill[1]>0
    end
    assert(blue and shallow,"grid shows both preferred-depth and shallow cells")
    equal(visible.pathfindingDebugSearch.LastGridDrawResult.Status,"complete")
    equal(visible.pathDepthWeight,10)
    equal(visible.stops,0)
    visible:SetPathfindingOff()
    equal(next(view.marks),nil) equal(next(view.scheduled),nil)
  end)
end)

test("LOCAL display replaces submitted geometry and ignores callbacks that stop navigation",function()
  withDrawing(function(view)
    local points={VECTOR:New(0,0,0),VECTOR:New(1200,0,0),VECTOR:New(2400,0,600),VECTOR:New(3600,0,600)}
    local ship=installedFixture(points)
    ship.verbose=10
    assert(ship:_SubmitLocalRoute(points[1]))
    local oldIDs=assertDrawnRoute(view,ship.dispatched)
    ship.position={x=1250,y=0,z=25}
    ship.heading=points[2]:GetHeadingTo(points[3])
    ship:_LocalRouteProgress(VECTOR:NewFromVec(ship.position))
    assert(ship:_SubmitLocalRoute(VECTOR:NewFromVec(ship.position)))
    for _,id in ipairs(oldIDs) do equal(view.marks[id],nil,"old route removed") end
    assertDrawnRoute(view,ship.dispatched)
    near(ship.dispatched[1].x,1250) near(ship.dispatched[1].y,25)
    local originalRoute=ship.Route
    function ship:Route(route)
      self.Route=originalRoute
      originalRoute(self,route)
      self:FullStop()
    end
    assert(ship:_SubmitLocalRoute(VECTOR:NewFromVec(ship.position)))
    equal(next(view.marks),nil,"stop callback must not resurrect the old route")
    equal(next(view.scheduled),nil)
  end)
end)

test("LOCAL display keeps route and group ownership across probe replacement and cancellation",function()
  withDrawing(function(view)
    local first=localShip(1500):SetPathfindingMinDepth(3.5):SetPathfindingPreferredDepth(15,10)
    first.verbose=10
    assert(activateLocal(first))
    view:flush()
    local firstGrid=view:collect("grid")
    local firstRoute=assertDrawnRoute(view,first.dispatched)
    -- A speculative search uses a different ASTAR owner, but must leave the installed command visible.
    local probe=first:_GetLocalSearch(10,true)
    probe:StartLocalSearch(VECTOR:New(500,0,0),VECTOR:New(20000,0,0),0)
    while probe.LastSearchResult.Status=="running" do probe:StepSearch(512,1) end
    first:_DrawLocalSearch(probe)
    for _,id in ipairs(firstGrid) do equal(view.marks[id],nil) end
    for _,id in ipairs(firstRoute) do assert(view.marks[id],"grid replacement removed an installed route") end
    assert(view:step())
    local pending=view.callbacks[#view.callbacks]
    local owned={}
    for id in pairs(view.marks) do owned[#owned+1]=id end

    local second=localShip(1500):SetPathfindingMinDepth(3.5):SetPathfindingPreferredDepth(15,10)
    second.verbose=10
    assert(activateLocal(second))
    local secondRoute={}
    for id,mark in pairs(view.marks) do
      if mark.kind=="route" and id>firstRoute[#firstRoute] then secondRoute[#secondRoute+1]=id end
    end
    assert(#secondRoute>0)
    view.marks[999999]={kind="unrelated"}
    first:FullStop()
    for _,id in ipairs(owned) do equal(view.marks[id],nil) end
    for _,id in ipairs(secondRoute) do assert(view.marks[id],"another group's route was removed") end
    assert(view.marks[999999])
    equal(pending.fn(pending.args,timerNow),nil,"cancelled callback cannot redraw")
    view:flush()
    for _,id in ipairs(owned) do equal(view.marks[id],nil) end
    assert(#view:collect("grid")>0,"another group's pending grid still completes")
    second:SetPathfindingMode(NAVYGROUP.PathfindingMode.WAYPOINT)
    equal(#view:collect("route"),0) equal(#view:collect("grid"),0)
    equal(next(view.scheduled),nil)
    assert(view.marks[999999])
  end)
end)

test("LOCAL display cancellation cannot abort a new planning coroutine on an invalid timer handle",function()
  withDrawing(function(view)
    timer.removeFunction=function() error("Parameter #1 (function reference number) is invalid") end
    local ship=localShip():SetPathfindingMinDepth(3.5):SetPathfindingPreferredDepth(15,10)
    ship.verbose=10
    assert(activateLocal(ship))
    local firstRoute=ship.localNavigation.RouteID
    assert(firstRoute and firstRoute>0)
    -- Leave the first window pending while a different planning coroutine replaces it.
    ship:_StartLocalPlanning(VECTOR:NewFromVec(ship.position),false)
    assert(finishPlanning(ship,true))
    assert(ship.localNavigation.RouteID>firstRoute)
    equal(ship.LastLocalPlanningReport.Reason,"submitted")
    equal(ship.stops,0)
    ship:FullStop()
    local afterStop=view.nextID
    view:flush()
    equal(view.nextID,afterStop,"cancelled drawing callbacks cannot create new marks")
    equal(next(view.marks),nil) equal(next(view.scheduled),nil)
  end)
end)

local function longConnectorFixture(rotation,mirror)
  local path={}
  local angle=math.rad(rotation or 0)
  for _,point in ipairs({{64639.2,-82415.1},{64846.5,-81963.2},{64296.8,-81188.4},
    {64181.1,-81025.3},{64598.1,-80116.4},{64660.6,-79980.1},{64082.0,-79164.5},{63995.2,-79042.1}}) do
    local x,z=point[1],point[2]*(mirror or 1)
    path[#path+1]=VECTOR:New(x*math.cos(angle)-z*math.sin(angle),0,x*math.sin(angle)+z*math.cos(angle))
  end
  local ship=installedFixture(path)
  local navigation=ship.localNavigation
  navigation.Speed=13.375
  navigation.Segment=2
  local x,z=64375.1,-81120.7*(mirror or 1)
  ship.position={x=x*math.cos(angle)-z*math.sin(angle),y=0,z=x*math.sin(angle)+z*math.cos(angle)}
  ship.heading=(77.7*(mirror or 1)+(rotation or 0))%360
  local job=ship:_StartLocalPlanning(path[2],false)
  job.Points={}
  for _,point in ipairs(job.Prefix) do job.Points[#job.Points+1]=point:Copy() end
  job.Points[#job.Points+1]=path[#path]:Copy():Translate(900,path[7]:GetHeadingTo(path[8]))
  job.Plan={GoalReached=false,Cost=5000,PlanningSpeed=job.Speed}
  navigation.Job=nil navigation.Pending=job
  return ship,path,job
end

test("LOCAL connector subdivision publishes the logged 1029 meter reattachment without skipping corners",function()
  for _,variant in ipairs({{0,1},{60,1},{180,1},{90,-1}}) do
    local ship,path,job=longConnectorFixture(variant[1],variant[2])
    local jobCount=#job.Points
    local position=VECTOR:NewFromVec(ship.position)
    local length=position:GetDistance(path[5],true)
    assert(length>1028 and length<1030)
    assert(ship:_CommitLocalPlanning(position))
    equal(job.Outcome.Reason,"submitted") equal(ship.stops,0)
    equal(#job.Points,jobCount,"subdivision must not mutate the pending proposal")
    local route=ship.localNavigation.Path
    near(route[2].x,(position.x+path[5].x)/2)
    near(route[2].z,(position.z+path[5].z)/2)
    for i=5,#path do
      near(route[i-2].x,path[i].x) near(route[i-2].z,path[i].z)
    end
    for i=2,#route do assert(route[i-1]:GetDistance(route[i],true)<=1000.001) end
    assertClearPath(ship,route)
    near(ship.dispatched[2].speed,13.375)
    equal(ship.currentwp,1) equal(ship.passingEvents,nil)
  end
end)

test("LOCAL connector subdivision still rejects shallow water on the new connection",function()
  local ship,path=longConnectorFixture()
  ship.terrain.depthAt=function(point)
    if point.x>64450 and point.x<64485 and point.y>-80775 and point.y<-80700 then return 1 end
    return 40
  end
  assert(ship:_CheckPathDepth(path[4],path[5]),"the original installed leg remains clear")
  local dispatches=#ship.dispatches
  ship:_CommitLocalPlanning(VECTOR:NewFromVec(ship.position))
  equal(ship.stops,1)
  equal(#ship.dispatches,dispatches+1) equal(ship.dispatched[1].speed,0)
  equal(ship.LastPathfindingResult.DepthCheck.Cause,"insufficient_depth")
end)

test("LOCAL connector subdivision checks the original corner before inserting a straight point",function()
  local ship,path,job=longConnectorFixture()
  local rejectedCorner=false
  local original=ship._CheckLocalTurn
  function ship:_CheckLocalTurn(position,...)
    if position:GetDistance(path[5],true)<0.01 then
      rejectedCorner=true
      return false,{Reason="controlled_corner_obstruction"}
    end
    return original(self,position,...)
  end
  local dispatches=#ship.dispatches
  ship:_CommitLocalPlanning(VECTOR:NewFromVec(ship.position))
  assert(rejectedCorner,"the real retained corner must be checked, not just a straight midpoint")
  equal(job.Outcome.Reason,"submission_corner_clearance")
  equal(#ship.dispatches,dispatches)
end)

test("LOCAL connector subdivision stays bounded and rejects an excessively distant anchor",function()
  local points={VECTOR:New(0,0,0),VECTOR:New(1000,0,0),VECTOR:New(2000,0,0),VECTOR:New(3000,0,0)}
  local ship=installedFixture(points)
  local job=ship:_StartLocalPlanning(points[1],false)
  job.Points=job.Prefix
  job.Plan={GoalReached=false,Cost=3000}
  ship.localNavigation.Job=nil ship.localNavigation.Pending=job
  ship.position={x=-1100,y=0,z=0}
  local count=#ship.dispatches
  ship:_CommitLocalPlanning(VECTOR:NewFromVec(ship.position))
  equal(job.Outcome.Reason,"submission_leg_length")
  equal(#ship.dispatches,count)
  equal(ship.localNavigation.Path,points)
end)

-- Logged DCS steering points, rounded to 0.1 m; terrain is deliberately controlled.
local function roundedSubdivisionFixture()
  local path={}
  for _,point in ipairs({{64631.0,-82432.9},{64848.3,-81959.2},{64269.7,-81143.6},
    {64182.9,-81021.3},{64579.1,-80157.8},{64662.5,-79976.0},{64112.8,-79201.2},{63997.0,-79038.1}}) do
    path[#path+1]=VECTOR:New(point[1],0,point[2])
  end
  local ship=installedFixture(path)
  ship.localNavigation.Speed=13.375
  ship.localNavigation.Segment=2
  ship.velocity=13.375
  ship.heading=78.255556883149
  ship.position={x=64376.740831542,y=0,z=-81114.9902282}
  return ship,path
end

test("LOCAL rounded subdivisions recognise the logged outgoing course before its endpoint plane",function()
  local ship,path=roundedSubdivisionFixture()
  local navigation=ship.localNavigation
  local dispatches=#ship.dispatches
  local position=VECTOR:NewFromVec(ship.position)
  local progress,remaining=ship:_LocalRouteProgress(position)
  equal(navigation.Segment,4)
  near(progress,navigation.Distances[4])
  near(remaining,navigation.Length-progress)
  for _=1,3 do
    near(ship:_LocalRouteProgress(position),progress)
    equal(navigation.Segment,4)
  end
  equal(#ship.dispatches,dispatches)
  equal(ship.currentwp,1) equal(ship.passingEvents,nil)
end)

test("LOCAL rounded subdivisions publish a forward continuation from the logged pose",function()
  local ship,path=roundedSubdivisionFixture()
  local navigation=ship.localNavigation
  local job=ship:_StartLocalPlanning(path[2],false)
  job.Points={}
  for _,point in ipairs(job.Prefix) do job.Points[#job.Points+1]=point:Copy() end
  job.Points[#job.Points+1]=path[#path]:Copy():Translate(1000,path[7]:GetHeadingTo(path[8]))
  job.Plan={GoalReached=false,Cost=5000,PlanningSpeed=job.Speed}
  navigation.Job=nil navigation.Pending=job
  local dispatches=#ship.dispatches
  assert(ship:_CommitLocalPlanning(VECTOR:NewFromVec(ship.position)))
  equal(#ship.dispatches,dispatches+1) equal(ship.stops,0)
  equal(job.Outcome.Reason,"submitted")
  near(ship.dispatched[2].x,path[5].x) near(ship.dispatched[2].y,path[5].z)
  near(ship.dispatched[2].speed,13.375)
  equal(ship.currentwp,1) equal(ship.passingEvents,nil)
  assertClearPath(ship,navigation.Path)
  -- Every remaining corner survives; none is replaced with a distant shortcut.
  for i=5,#path do
    near(navigation.Path[i-3].x,path[i].x) near(navigation.Path[i-3].z,path[i].z)
  end
end)

test("LOCAL rounded subdivisions follow observed motion independently of point density and orientation",function()
  for _,mirror in ipairs({-1,1}) do
    for _,rotation in ipairs({0,math.rad(137),math.rad(280)}) do
      for _,extraPoints in ipairs({0,3}) do
        local sourceShip,source=roundedSubdivisionFixture()
        local origin=source[2]
        local function transform(point)
          local x,z=point.x-origin.x,mirror*(point.z-origin.z)
          return VECTOR:New(x*math.cos(rotation)-z*math.sin(rotation),0,x*math.sin(rotation)+z*math.cos(rotation))
        end
        local path={transform(source[2]),transform(source[3])}
        for i=1,extraPoints do
          local fraction=i/(extraPoints+1)
          path[#path+1]=transform(VECTOR:New(source[3].x+(source[4].x-source[3].x)*fraction,0,
            source[3].z+(source[4].z-source[3].z)*fraction))
        end
        for i=4,#source do path[#path+1]=transform(source[i]) end
        local ship=installedFixture(path)
        ship.localNavigation.Speed=13.375
        local course=math.rad(sourceShip.heading)
        ship.heading=(mirror*sourceShip.heading+math.deg(rotation))%360
        local previous=0
        -- Include earlier/later observations around the rejected commit, not just its exact pose.
        for _,distance in ipairs({-30,0,30,60}) do
          local position=transform(VECTOR:New(sourceShip.position.x+distance*math.cos(course),0,
            sourceShip.position.z+distance*math.sin(course)))
          local progress=ship:_LocalRouteProgress(position)
          equal(ship.localNavigation.Segment,3+extraPoints)
          assert(progress>=previous)
          previous=progress
          near(ship:_LocalRouteProgress(position),progress)
        end
      end
    end
  end
end)

test("LOCAL rounded subdivisions cannot bypass a real corner or a nearby return leg",function()
  for _,case in ipairs({"wrong_heading","before_corner","too_far","real_corner","hairpin","straight"}) do
    local points={VECTOR:New(0,0,0),VECTOR:New(850,0,0),VECTOR:New(1000,0,0),VECTOR:New(1700,0,700),VECTOR:New(2400,0,1400)}
    local position,heading={x=800,y=0,z=180},45
    if case=="wrong_heading" then heading=0 end
    if case=="before_corner" then position={x=700,y=0,z=20} end
    if case=="too_far" then position={x=400,y=0,z=500} end
    if case=="real_corner" then points[3]=VECTOR:New(850,0,-150) end
    if case=="straight" then
      points[3]=VECTOR:New(1850,0,0)
      points[4]=VECTOR:New(2850,0,0)
      heading=0
    end
    if case=="hairpin" then
      points[3]=VECTOR:New(850,0,100)
      points[4]=VECTOR:New(0,0,100)
      position={x=0,y=0,z=95}
      heading=180
    end
    local ship=installedFixture(points)
    ship.localNavigation.Speed=13.375
    ship.position,ship.heading=position,heading
    ship:_LocalRouteProgress(VECTOR:NewFromVec(ship.position))
    equal(ship.localNavigation.Segment,1,case)
  end
end)

test("LOCAL rounded subdivisions still reject a shallow live connector",function()
  local ship,path=roundedSubdivisionFixture()
  local navigation=ship.localNavigation
  local job=ship:_StartLocalPlanning(path[2],false)
  job.Points=job.Prefix
  job.Plan={GoalReached=false,Cost=4000,PlanningSpeed=job.Speed}
  navigation.Job=nil navigation.Pending=job
  -- The retained outgoing line clears this shoal, but the actual-position connector crosses it.
  ship.terrain.depthAt=function(point)
    if point.x>64460 and point.x<64490 and point.y>-80665 and point.y<-80610 then return 1 end
    return 40
  end
  assert(ship:_CheckPathDepth(path[4],path[5]))
  local dispatches=#ship.dispatches
  ship:_CommitLocalPlanning(VECTOR:NewFromVec(ship.position))
  equal(ship.stops,1)
  equal(#ship.dispatches,dispatches+1)
  equal(ship.dispatched[1].speed,0)
  equal(ship.LastPathfindingResult.DepthCheck.Cause,"insufficient_depth")
end)

test("LOCAL failed continuation keeps checked movement retries after progress and stops at reserve",function()
  local points={VECTOR:New(0,0,0),VECTOR:New(1000,0,0),VECTOR:New(2000,0,0),VECTOR:New(3000,0,0)}
  local ship=installedFixture(points)
  local navigation=ship.localNavigation
  local builds,logs=0,{}
  function ship:_BuildLocalRoute()
    builds=builds+1
    return nil,nil,"no_steering_path"
  end
  function ship:T(message) logs[#logs+1]=message end
  local dispatches=#ship.dispatches
  ship:_StartLocalPlanning(points[1],false)
  ship:_AdvanceLocalPlanning()
  assert(navigation.Job and navigation.Job.Replacement,"a failed future anchor gets one actual-position attempt")
  ship:_AdvanceLocalPlanning()
  equal(builds,2) equal(navigation.Job,nil)
  equal(navigation.Path,points) equal(#ship.dispatches,dispatches) equal(ship.stops,0)
  equal(navigation.ExtensionFailure.Reason,"no_steering_path")

  -- Failure does not create a timer-driven retry loop while actual progress stays unchanged.
  for _=1,3 do timerNow=timerNow+0.1 ship:_CheckLocalNavigation() end
  equal(builds,2) equal(navigation.Job,nil)
  ship.position={x=300,y=0,z=0}
  ship:_CheckLocalNavigation()
  assert(navigation.Job,"observed progress should permit another bounded continuation")
  equal(#ship.dispatches,dispatches)

  ship.position={x=2400,y=0,z=0}
  ship:_CheckLocalNavigation()
  equal(ship.stops,1) equal(ship.LastPathfindingResult.StopReason,"local_route_exhausted")
  equal(ship.LastPathfindingResult.Remaining,600) equal(ship.LastPathfindingResult.Reserve,700)
  equal(#ship.dispatches,dispatches+1) equal(ship.dispatched[1].speed,0)
  local failures=0
  for _,line in ipairs(logs) do
    if line:find("Local planning failed:",1,true) then failures=failures+1 assert(#line<500) end
  end
  equal(failures,2)
end)

test("LOCAL moved connector rechecks the first retained corner before publication",function()
  local original={VECTOR:New(0,0,0),VECTOR:New(1000,0,0),VECTOR:New(1500,0,866),VECTOR:New(2000,0,1732)}
  local ship=installedFixture(original)
  local navigation=ship.localNavigation
  local job=ship:_StartLocalPlanning(original[1],true)
  job.Points=original job.Plan={GoalReached=false,Cost=3000}
  navigation.Job=nil navigation.Pending=job
  local dispatches=#ship.dispatches
  ship.position={x=500,y=0,z=400}
  ship.heading=VECTOR:NewFromVec(ship.position):GetHeadingTo(original[2])
  ship:_CommitLocalPlanning(VECTOR:NewFromVec(ship.position))
  equal(#ship.dispatches,dispatches) equal(navigation.Path,original)
  equal(navigation.ExtensionFailure.Reason,"submission_corner_angle")
end)

test("LOCAL a clearance callback changing rules cannot replace the tracked installed route",function()
  local original={VECTOR:New(0,0,0),VECTOR:New(1000,0,0),VECTOR:New(2000,0,0),VECTOR:New(3000,0,0)}
  local ship=installedFixture(original)
  local navigation=ship.localNavigation
  local job=ship:_StartLocalPlanning(original[1],true)
  job.Points={original[1]:Copy(),original[2]:Copy(),original[3]:Copy(),original[4]:Copy(),VECTOR:New(4000,0,0)}
  job.Plan={GoalReached=false,Cost=4000}
  navigation.Job=nil navigation.Pending=job
  ship.collisionwarning=true
  function ship:OnAfterClearAhead() self:SetPathfindingMinDepth(21) end
  local dispatches=#ship.dispatches
  equal(ship:_CommitLocalPlanning(original[1]),false)
  equal(ship.localNavigation,navigation) equal(navigation.Path,original)
  equal(#ship.dispatches,dispatches) equal(ship.pathMinDepth,21)
  equal(navigation.Pending,nil)
end)

test("LOCAL final worker callbacks cannot publish an obsolete completed generation",function()
  for _,action in ipairs({"hold","rules","retarget","accelerate"}) do
    local ship=localShip()
    local before
    function ship:_BuildLocalRoute(job)
      if action=="hold" then self:FullStop()
      elseif action=="rules" then self:SetPathfindingMinDepth(21)
      elseif action=="retarget" then self:_SetNavigationWaypoint(self.waypoints[3])
      else self.velocity=20 end
      before=#self.dispatches
      return {job.Position,VECTOR:New(1000,0,0),VECTOR:New(2000,0,0),VECTOR:New(3000,0,0)},
        {GoalReached=false,Cost=3000}
    end
    assert(ship:_CheckLocalNavigation(true))
    ship:_AdvanceLocalPlanning()
    equal(#ship.dispatches,before)
    assert(not ship.localNavigation or not ship.localNavigation.Job)
    assert(not ship.localNavigation or not ship.localNavigation.Pending)
    if action=="hold" then equal(ship.state,"Holding") end
  end
end)

test("LOCAL completed continuation waits through a turn and preserves every unpassed corner",function()
  local original={VECTOR:New(0,0,0),VECTOR:New(1000,0,0),VECTOR:New(1800,0,400),VECTOR:New(2600,0,800)}
  local ship=installedFixture(original)
  local navigation=ship.localNavigation
  local job=ship:_StartLocalPlanning(original[1],false)
  job.Points={original[1]:Copy(),original[2]:Copy(),original[3]:Copy(),original[4]:Copy(),VECTOR:New(3400,0,1200)}
  job.Plan={GoalReached=false,Cost=4000}
  navigation.Job=nil navigation.Pending=job
  ship.turning=true
  local dispatches=#ship.dispatches
  equal(ship:_CommitLocalPlanning(original[1]),false)
  equal(navigation.Path,original) equal(navigation.Pending,job) equal(#ship.dispatches,dispatches)
  ship.turning=false
  assert(ship:_CommitLocalPlanning(original[1]))
  equal(#ship.dispatches,dispatches+1) equal(navigation.Pending,nil)
  for index=2,#original do
    near(navigation.Path[index].x,original[index].x) near(navigation.Path[index].z,original[index].z)
  end
end)

test("LOCAL cell limits remain distinct from cooperative slice limits",function()
  local ship=localShip():SetPathfindingGrid(1)
  activateLocal(ship)
  equal(ship.state,"Holding") equal(ship.stops,1)
  equal(ship.LastPathfindingResult.StopReason,"cell_limit")
  equal(#ship.dispatches,1) equal(ship.dispatched[1].speed,0)
end)

test("LOCAL building from an older anchor cannot manufacture backward observed movement",function()
  local ship=localShip()
  ship.localNavigation={}
  local search=ship:_GetLocalSearch(10)
  search:UpdateLocalProgress(VECTOR:New(0,0,0))
  ship.position={x=100,y=0,z=0}
  search:UpdateLocalProgress(VECTOR:NewFromVec(ship.position))
  local start=search.StartLocalSearch
  function search:StartLocalSearch(...)
    start(self,...)
    self:CancelSearch() -- No geometry is needed to inspect the new request's observation snapshot.
    return self
  end
  local job={Position=VECTOR:New(0,0,0),Heading=0,Speed=10,Alt=0,
    TargetPosition=VECTOR:New(20000,0,0),Prefix={VECTOR:New(1000,0,0)}}
  ship:_BuildLocalRoute(job)
  local progress=search.LastSearchResult.Progress
  near(progress.Position.x,100) near(progress.Distance,100) equal(progress.HistoryCount,2)
end)

test("LOCAL ordinary release cannot bypass depth rules changed by its clearance callback",function()
  local original={VECTOR:New(0,0,0),VECTOR:New(1000,0,0),VECTOR:New(2000,0,0),VECTOR:New(3000,0,0)}
  local ship=installedFixture(original)
  local navigation=ship.localNavigation
  ship.collisionwarning=true
  function ship:OnAfterClearAhead() self:SetPathfindingMinDepth(41) end
  local dispatches,updates=#ship.dispatches,ship.updates

  assert(ship:_TryResumeWaypointRoute())

  equal(ship.pathMinDepth,41) equal(ship.localNavigation,navigation)
  equal(navigation.Path,original) equal(#ship.dispatches,dispatches)
  equal(ship.updates,updates) equal(ship.stops,0)
end)

test("LOCAL clearance callbacks cannot complete an obsolete arrival target",function()
  local ship=localShip()
  assert(ship:_CheckLocalNavigation(true))
  ship:_CancelLocalPlanning("controlled_arrival_fixture")
  ship.position={x=20000,y=0,z=0}
  ship.collisionwarning=true
  function ship:OnAfterClearAhead() self:_SetNavigationWaypoint(self.waypoints[3]) end
  ship:_CheckLocalNavigation()
  equal(ship.currentwp,1) equal(ship.passingEvents,nil)
  equal(ship:_GetNavigationWaypoint().uid,3)
end)

test("LOCAL clearance callbacks changing target coordinates prevent stale route publication",function()
  for _,stage in ipairs({"install_altitude","resubmit_horizontal"}) do
    local original={VECTOR:New(0,0,0),VECTOR:New(1000,0,0),VECTOR:New(2000,0,0),VECTOR:New(3000,0,0)}
    local ship=installedFixture(original)
    local navigation=ship.localNavigation
    ship.collisionwarning=true
    function ship:OnAfterClearAhead()
      local coordinate=self.waypoints[2].coordinate
      if stage=="install_altitude" then coordinate.y=-20 else coordinate.x=coordinate.x+100 end
    end
    local dispatches=#ship.dispatches
    if stage=="install_altitude" then
      local job=ship:_StartLocalPlanning(original[1],true)
      job.Points={original[1]:Copy(),original[2]:Copy(),original[3]:Copy(),original[4]:Copy(),VECTOR:New(4000,0,0)}
      job.Plan={GoalReached=false,Cost=4000}
      navigation.Job=nil navigation.Pending=job
      equal(ship:_CommitLocalPlanning(original[1]),false)
    else
      equal(ship:_SubmitLocalRoute(original[1]),false)
    end
    equal(navigation.Path,original) equal(#ship.dispatches,dispatches)
    equal(ship.currentwp,1)
  end
end)

test("LOCAL initial moving-ship results retain only the contiguous checked remainder",function()
  for _,x in ipairs({950,1050}) do
    local ship=localShip()
    assert(ship:_CheckLocalNavigation(true))
    local navigation=ship.localNavigation
    local job=navigation.Job
    job.Points={VECTOR:New(0,0,0),VECTOR:New(1000,0,0),VECTOR:New(2000,0,0),VECTOR:New(3000,0,0)}
    job.Plan={GoalReached=false,Cost=3000}
    navigation.Job=nil navigation.Pending=job
    ship.position={x=x,y=0,z=0}
    assert(ship:_CommitLocalPlanning(VECTOR:NewFromVec(ship.position)))
    equal(ship.stops,0) equal(#ship.dispatches,1)
    near(ship.dispatched[1].x,x)
    near(ship.dispatched[2].x,x<1000 and 1000 or 2000)
    for index=2,#ship.dispatched do
      local a,b=ship.dispatched[index-1],ship.dispatched[index]
      assert(math.sqrt((a.x-b.x)^2+(a.y-b.y)^2)<=1000.001)
    end
  end
end)

test("LOCAL a moved connector cannot create a turn with too little checked water afterwards",function()
  local ship=localShip()
  assert(ship:_CheckLocalNavigation(true))
  local navigation=ship.localNavigation
  local job=navigation.Job
  job.Points={VECTOR:New(0,0,0),VECTOR:New(1000,0,0),VECTOR:New(2000,0,0),VECTOR:New(2600,0,0)}
  job.Plan={GoalReached=false,Cost=2600}
  navigation.Job=nil navigation.Pending=job
  ship.position={x=1800,y=0,z=100}
  ship.heading=0

  ship:_CommitLocalPlanning(VECTOR:NewFromVec(ship.position))

  equal(ship.stops,1) equal(ship.state,"Holding")
  equal(ship.LastPathfindingResult.StopReason,"submission_turn_exit_too_short")
  equal(#ship.dispatches,1) equal(ship.dispatched[1].speed,0)
end)

test("LOCAL initial moving-ship reattachment still rejects shallow or off-corridor motion",function()
  for _,case in ipairs({"shallow","off_corridor"}) do
    local ship=localShip()
    assert(ship:_CheckLocalNavigation(true))
    local navigation=ship.localNavigation
    local job=navigation.Job
    job.Points={VECTOR:New(0,0,0),VECTOR:New(1000,0,0),VECTOR:New(2000,0,0),VECTOR:New(3000,0,0)}
    job.Plan={GoalReached=false,Cost=3000}
    navigation.Job=nil navigation.Pending=job
    ship.position={x=1050,y=0,z=case=="off_corridor" and 400 or 0}
    if case=="shallow" then ship.terrain.depthAt=function(p) return p.x>1450 and p.x<1550 and 5 or 40 end end
    ship:_CommitLocalPlanning(VECTOR:NewFromVec(ship.position))
    equal(ship.stops,1) equal(ship.state,"Holding")
    equal(#ship.dispatches,1) equal(ship.dispatched[1].speed,0)
  end
end)

test("LOCAL default work budget prepares and extends a route while the ship keeps moving",function()
  local ship=localShip():SetPathfindingMinDepth(3.5):SetPathfindingPreferredDepth(15,10)
  ship.terrain.depth=10
  local commit=ship._CommitLocalPlanning
  local connector=""
  function ship:_CommitLocalPlanning(position)
    local pending=self.localNavigation and self.localNavigation.Pending
    local nextPoint=pending and pending.Points[2]
    if nextPoint then
      connector=string.format(" pending_first=(%.1f,%.1f) bearing=%.1f",nextPoint.x,nextPoint.z,
        position:GetHeadingTo(nextPoint))
    end
    return commit(self,position)
  end
  local startedCPU=os.clock()
  local function describe(label,plan,job)
    local remaining=ship.localNavigation and ship.localNavigation.Length
      and ship.localNavigation.Length-ship.localNavigation.Progress or 0
    print(string.format("MOVING %s: time=%.1f x=%.1f requests=%s work=%s slices=%s length=%s remaining=%.1f cpu_s=%.3f profiles=%d seabed=%d candidate=%s stage=%s",
      label,timerNow,ship.position.x,tostring(job and job.Requests or plan and plan.Attempts),
      tostring(job and job.WorkItems or plan and plan.WorkItems),tostring(job and job.Slices or plan and plan.Slices),
      tostring(plan and plan.Length),remaining,os.clock()-startedCPU,ship.terrain.profiles,ship.terrain.queries,
      tostring(plan and plan.Candidate),tostring(job and job.ActiveSearch and job.ActiveSearch.LastSearchResult.Stage)))
  end
  local stepSeconds=0.1
  assert(ship:_CheckLocalNavigation(true))
  local updates=0
  while ship.localNavigation and ship.localNavigation.Job do
    updates=updates+1
    assert(updates<=2000,"initial moving-ship planning exceeded its default update limit")
    timerNow=timerNow+stepSeconds
    ship.position.x=ship.position.x+ship.velocity*stepSeconds
    ship:_CheckLocalNavigation()
    equal(ship.stops,0,"initial search at "..timerNow.." s x="..ship.position.x..": "..tostring(ship.LastPathfindingResult and ship.LastPathfindingResult.StopReason)..connector)
  end
  local navigation=assert(ship.localNavigation)
  assert(navigation.Path and #ship.dispatches==1)
  describe("initial",ship.LastPathfindingResult)
  local firstRoute=navigation.RouteID
  local firstSlices=ship.LastPathfindingResult.Slices
  local initialTime=timerNow
  near(ship.dispatched[1].x,ship.position.x)
  local followUpdates=0
  while ship.localNavigation and ship.localNavigation.RouteID==firstRoute do
    followUpdates=followUpdates+1
    assert(followUpdates<=2500,"moving-ship continuation did not publish within its usable route")
    navigation=ship.localNavigation
    local target=navigation.Path[navigation.Segment+1]
    local position=VECTOR:NewFromVec(ship.position)
    local remaining=position:GetDistance(target,true)
    if remaining>0 then
      ship.heading=position:GetHeadingTo(target)
      local moved=position:Translate(math.min(ship.velocity*stepSeconds,remaining),ship.heading,true)
      ship.position=moved:GetVec3()
    end
    timerNow=timerNow+stepSeconds
    local running=navigation.Job
    ship:_CheckLocalNavigation()
    if ship.stops>0 then describe("continuation_failed",ship.LastPathfindingResult,running) end
    equal(ship.stops,0,"continuation at "..timerNow.." s x="..ship.position.x..": "..tostring(ship.LastPathfindingResult and ship.LastPathfindingResult.StopReason))
  end
  navigation=assert(ship.localNavigation)
  describe("continuation",ship.LastPathfindingResult)
  assert(navigation.RouteID>firstRoute) assert(#ship.dispatches>=2)
  assertClearPath(ship,navigation.Path)
  print(string.format("MOVING LOCAL: initial_slices=%d initial_sim_s=%.1f continuation_sim_s=%.1f routes=%d",
    firstSlices,initialTime,timerNow-initialTime,#ship.dispatches))
end)

print(string.format("%d passed, %d failed",passed,failed))
if failed>0 then os.exit(1) end
