-- Standalone naval pathfinding regressions; run from the repository root:
-- lua tests/navy-pathfinding.lua
-- Imports production methods and actual GRID/ASTAR/PATHLINE; only DCS/FSM effects are stubbed.
-- Compatible with the Lua 5.1 runtime used by DCS and Lua 5.4.
-- Optional NAVY_TEST_FILTER selects Lua name patterns separated by |.
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
function timer.scheduleFunction() error("Navigation checks must not create a retry timer") end
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
  local ship=setmetatable({lid="Naval test ",pathfindingMode="waypoint",verbose=0,pathCorridor=50,pathfindingOn=true,
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

local function checkNavigation(ship)
  return ship:_CheckNavigation()
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
-- Model dimensions and live wrapper data used by the production hull check.
local function hullElement(ship,name,position,heading,speed,box)
  local unit={alive=true}
  function unit:IsAlive() return self.alive end
  function unit:GetVec3() return position or ship.position end
  function unit:GetHeading() return heading or ship.heading end
  function unit:GetVelocityMPS() return speed or ship.velocity end
  return {name=name,unit=unit,descriptors=box and {box=box}}
end

local function sameValues(first,last)
  equal(type(first),type(last))
  if type(first)~="table" then equal(first,last) return end
  for key,value in pairs(first) do sameValues(value,last[key]) end
  for key in pairs(last) do assert(first[key]~=nil,"Unexpected route field: "..tostring(key)) end
end

test("LOCAL selection reports removal without changing the active route or movement state",function()
  for _,state in ipairs({"Cruising","Holding","Waiting"}) do
    local ship=vessel():SetPathfindingMode(NAVYGROUP.PathfindingMode.WAYPOINT)
    ship:onafterUpdateRoute(nil,nil,nil,3,nil,14,40)
    ship.state=state=="Waiting" and "Cruising" or state
    if state=="Waiting" then ship.Twaiting=0 end
    local route=ship.dispatched
    local command=ship.navigationCommand
    local updates=ship.updates
    local cleared=0
    ship.pathfindingDebugSearch={ClearDrawing=function(_,kind)
      equal(kind,GRID.Drawing.POLYGONS)
      cleared=cleared+1
    end}

    local ok,message=pcall(ship.SetPathfindingMode,ship,NAVYGROUP.PathfindingMode.LOCAL)

    equal(ok,false)
    assert(tostring(message):find("LOCAL pathfinding mode has been removed",1,true),tostring(message))
    equal(ship.pathfindingMode,NAVYGROUP.PathfindingMode.WAYPOINT)
    equal(ship.dispatched,route)
    equal(ship.navigationCommand,command)
    equal(ship.updates,updates)
    equal(ship.stops,0)
    equal(ship.pathfindingOn,true)
    equal(ship.state,state=="Waiting" and "Cruising" or state)
    equal(ship.Twaiting,state=="Waiting" and 0 or nil)
    equal(cleared,0)
    assertNoSearch()
  end
end)

test("WAYPOINT defaults and unknown mode validation leave routing unchanged",function()
  local ship=vessel()
  equal(NAVYGROUP.PathfindingMode.LOCAL,"local")
  equal(ship:SetPathfindingMode(),ship)
  equal(ship:SetPathfindingMode(NAVYGROUP.PathfindingMode.WAYPOINT),ship)
  for _,mode in ipairs({false,true,1,"LOCAL","automatic",{}}) do
    local ok,message=pcall(ship.SetPathfindingMode,ship,mode)
    equal(ok,false)
    assert(tostring(message):find("unknown pathfinding mode",1,true))
    equal(ship.pathfindingMode,NAVYGROUP.PathfindingMode.WAYPOINT)
  end
  equal(ship.updates,0)
  equal(#ship.dispatches,0)
  assertNoSearch()
end)

test("diagnostics count a measured search and its retained display once",function()
  local ship=vessel():SetPathfindingDiagnostics()
  local search=ASTAR:New(GRID.Type.RECTANGLE):SetEndpoints(coord(0),coord(1000))
  search:GetGrid():SetResolution(100):SetCorridor(400,100)
  assert(search:CreateGrid())
  local count=search:GetGrid():GetCellCount()
  ship.pathfindingDebugSearch=search
  ship:_ObservePathfindingCells(search)
  equal(ship:GetPathfindingDiagnostics().PeakRetainedCells,count)
  local nextSearch=ASTAR:New(GRID.Type.RECTANGLE):SetEndpoints(coord(0),coord(2000))
  nextSearch:GetGrid():SetResolution(100):SetCorridor(400,100)
  assert(nextSearch:CreateGrid())
  ship:_ObservePathfindingCells(nextSearch)
  equal(ship:GetPathfindingDiagnostics().PeakRetainedCells,count+nextSearch:GetGrid():GetCellCount())
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

test("a newly inserted immediate target supersedes an old Goto",function()
  local ship=vessel():SetPathfindingMode(NAVYGROUP.PathfindingMode.WAYPOINT)
  ship.waypoints[3].coordinate=coord(0,30000)
  ship.waypoints[3].x,ship.waypoints[3].y=0,30000
  ship:onafterUpdateRoute(nil,nil,nil,3)
  local inserted=ship:AddWaypoint(coord(1000,2000),14,1,nil,false)
  ship:onafterUpdateRoute()
  equal(ship.dispatched[2].uid,inserted.uid)
  equal(ship.dispatched[3].uid,2) equal(ship.dispatched[4].uid,3)
  equal(ship:_GetNavigationWaypoint(),inserted)
  equal(ship.currentwp,1) assertNoSearch()
end)

test("removing the explicitly commanded waypoint restores the actual remaining route",function()
  local ship=vessel():SetPathfindingMode(NAVYGROUP.PathfindingMode.WAYPOINT)
  ship:onafterUpdateRoute(nil,nil,nil,3)
  ship:RemoveWaypointByID(3)
  ship:onafterUpdateRoute()
  equal(ship.dispatched[2].uid,2) equal(#ship.dispatched,2)
  equal(ship:_GetNavigationWaypoint().uid,2) equal(ship.currentwp,1)
  assertNoSearch()
end)

test("collision warning callbacks that insert a new target cancel the stale search",function()
  local ship=vessel():SetPathfindingMode(NAVYGROUP.PathfindingMode.WAYPOINT)
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
  equal(ship.warnings,1) equal(ship.stops,0)
  equal(ship.dispatched[2].uid,replacement.uid) equal(ship:_GetNavigationWaypoint(),replacement)
  assertNoSearch()
  timerNow=10 checkNavigation(ship)
  equal(ship.stops,0) assertNoSearch()
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

test("nearfield uses the asymmetric live hull and rotated bow while the center remains clear",function()
  local ship=vessel()
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
  local ship=vessel()
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
  local ship=vessel()
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
  local ship=vessel()
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
  timerNow=0
  local ship=vessel():SetPathfindingMode(NAVYGROUP.PathfindingMode.WAYPOINT)
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
end)

test("nearfield safety samples do not multiply route searches or clear an existing distant warning",function()
  local ship=vessel()
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
  local ship=vessel()
  ship.terrain.makeProfile=function() return nil end
  checkNavigation(ship)
  equal(ship.stops,1) assertNoSearch()
  equal(ship.LastPathfindingResult.DepthCheck.Status,"unavailable")
  equal(ship.LastPathfindingResult.StopReason,"profile_unavailable")
  timerNow=2 checkNavigation(ship) equal(ship.stops,1)
end)

test("nearfield respects disabled pathfinding holds movement tasks and warning callbacks",function()
  for _,state in ipairs({"off","Holding","Waiting","Dead","task"}) do
    local ship=vessel()
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
    local ship=vessel()
    ship.terrain.depth=1
    function ship:OnAfterCollisionWarning()
      if action=="hold" then self:FullStop() else self:SetPathfindingOff() end
    end
    checkNavigation(ship)
    equal(ship.stops,action=="hold" and 1 or 0) assertNoSearch()
  end
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
  local ship=vessel(2000):SetPathfindingDiagnostics()
  assert(ship:_FindPathToNextWaypoint())
  local first=ship:GetPathfindingDiagnostics()
  equal(ship:SetPathfindingDiagnostics(true),ship)
  local repeated=ship:GetPathfindingDiagnostics()
  equal(repeated.Enabled,true) equal(repeated.Scopes,first.Scopes)
  local updateCalls=first.Operations.waypoint_plan.Calls
  first.Operations.waypoint_plan.Calls=999 first.ProfileQueries=-1
  equal(ship:GetPathfindingDiagnostics().Operations.waypoint_plan.Calls,updateCalls)
  ship:SetPathfindingDiagnostics(false)
  local frozen=ship:GetPathfindingDiagnostics()
  ship:onafterUpdateRoute()
  sameValues(ship:GetPathfindingDiagnostics(),frozen)
  ship:SetPathfindingDiagnostics(true)
  local fresh=ship:GetPathfindingDiagnostics()
  equal(fresh.Scopes,0) equal(fresh.ProfileQueries,0) equal(next(fresh.Operations),nil)
  equal(vessel():GetPathfindingDiagnostics().Enabled,false)
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

print(string.format("%d passed, %d failed",passed,failed))
if failed>0 then os.exit(1) end
