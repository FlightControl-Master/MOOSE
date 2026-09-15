-- Standalone air, ground and naval waypoint regressions; run from the repository root with Lua 5.1 or 5.4.
-- Loads production waypoint methods; DCS/FSM side effects are stubbed.
local function read(path)
  local file=assert(io.open("Moose Development/Moose/"..path,"r"))
  local source=file:read("*a"):gsub("\r\n","\n") file:close()
  return source
end
local function method(source,signature,indent)
  local code=assert(source:match("(function "..signature.."%b().-\n"..(indent or "").."end)"),signature)
  assert((loadstring or load)(code))()
end
BASE={New=function() return {} end,Inherit=function(_,child) return setmetatable({},{__index=child}) end}
COORDINATE={ClassName="COORDINATE"}
function COORDINATE:F2() end
function COORDINATE:T() end
function COORDINATE:IsInstanceOf(name) return name==self.ClassName end
local point=read("Core/Point.lua")
method(point,"COORDINATE:New","  ")
method(point,"COORDINATE:WaypointNaval","  ")
for _,name in ipairs({"NewFromVec2","GetVec2","Get2DDistance","GetClosestPointToRoad","WaypointGround","WaypointAir"}) do
  method(point,"COORDINATE:"..name,"  ")
end
for _,name in ipairs({"WaypointAltType","WaypointType","WaypointAction"}) do
  assert((loadstring or load)(assert(point:match("(COORDINATE%."..name.." = %b{})"))))()
end
local create=COORDINATE.New
local coordinates=0
function COORDINATE:New(...)
  coordinates=coordinates+1
  return create(self,...)
end
UTILS={}
local utils=read("Utilities/Utils.lua")
method(utils,"UTILS.VecWaypointNaval")
method(utils,"UTILS.VecWaypointAir")
method(utils,"UTILS.VecWaypointGround")
for _,name in ipairs({"FeetToMeters","KnotsToKmph","MpsToKnots"}) do
  assert((loadstring or load)(assert(utils:match("(UTILS%."..name.." = function%b().-\nend)"))))()
end
function UTILS.VecDist2D(a,b) return math.sqrt((a.x-b.x)^2+(a.y-b.y)^2) end
function UTILS.DeepCopy(value)
  if type(value)~="table" then return value end
  local result={} for key,item in pairs(value) do result[key]=UTILS.DeepCopy(item) end return result
end
local roadMissing=false
land={getHeight=function(p) return p.x/10+p.y/20 end,
  getClosestPointOnRoads=function(_,x,y) if not roadMissing then return x+30,y+40 end end}
Airbase={Category={AIRDROME=0,HELIPAD=1,SHIP=2}}
ENUMS={Formation={Vehicle={OnRoad="On Road"}}}
dofile("Moose Development/Moose/Core/Vector.lua")
OPSGROUP={}
local ops=read("Ops/OpsGroup.lua")
for _,signature in ipairs({"_CoordinateFromObject","_WaypointPosition","_CreateWaypoint","_AddWaypoint","_InitWaypoints","GetWaypointIndex","GetWaypointIndexAfterID"}) do
  method(ops,"OPSGROUP:"..signature)
end
NAVYGROUP=setmetatable({},{__index=OPSGROUP})
method(read("Ops/NavyGroup.lua"),"NAVYGROUP:AddWaypoint")
FLIGHTGROUP=setmetatable({},{__index=OPSGROUP})
ARMYGROUP=setmetatable({},{__index=OPSGROUP})
method(read("Ops/FlightGroup.lua"),"FLIGHTGROUP:AddWaypoint")
method(read("Ops/FlightGroup.lua"),"FLIGHTGROUP:AddWaypointLanding")
method(read("Ops/ArmyGroup.lua"),"ARMYGROUP:AddWaypoint")
local function group(class)
  class=class or NAVYGROUP
  local g=setmetatable({waypoints={},wpcounter=1,currentwp=1,lid="Test | ",updates=0,option={},optionDefault={}},{__index=class})
  function g:IsFlightgroup() return class==FLIGHTGROUP end
  function g:IsArmygroup() return class==ARMYGROUP end
  function g:IsNavygroup() return class==NAVYGROUP end
  function g:GetSpeedCruise() return 12 end
  function g:T() end
  function g:T2() end
  function g:T3() end
  function g:_PassedFinalWaypoint() end
  function g:__UpdateRoute(delay) self.updates=self.updates+1 self.updateDelay=delay end
  function g:_SimpleTaskFunction(name,uid) return {id=name,uid=uid} end
  function g:GetHomebaseFromWaypoints() end
  function g:GetDestinationFromWaypoints() end
  g.group={TaskCombo=function(_,tasks) return {id="ComboTask",params={tasks=tasks}} end}
  return g
end
local passed,failed=0,0
local function equal(a,b) assert(a==b,"expected "..tostring(b)..", got "..tostring(a)) end
local function near(a,b) assert(math.abs(a-b)<1e-9,"numeric mismatch") end
local function same(a,b)
  equal(type(a),type(b))
  if type(a)~="table" then equal(a,b) return end
  for key,value in pairs(a) do same(value,b[key]) end
  for key in pairs(b) do assert(a[key]~=nil,"Unexpected key "..tostring(key)) end
end
local function test(name,fn)
  roadMissing=false
  local ok,err=pcall(fn)
  if ok then passed=passed+1 print("PASS "..name)
  else failed=failed+1 print("FAIL "..name..": "..tostring(err)) end
end

test("naval route format preserves defaults units axes and task ownership",function()
  local p=COORDINATE:New(100,-12,300)
  local wp=p:WaypointNaval()
  same(wp,{x=100,y=300,alt=-12,alt_type="BARO",type="Turning Point",action="Turning Point",
    formation_template="",ETA=0,ETA_locked=false,speed=20/3.6,speed_locked=true,
    task={id="ComboTask",params={tasks={}}}})
  local tasks={{id="test"}}
  local explicit=p:WaypointNaval(0,0,tasks)
  equal(explicit.alt,0) equal(explicit.speed,0) equal(explicit.task.params.tasks,tasks)
  local another=p:WaypointNaval()
  wp.task.params.tasks[1]={id="Changed"}
  equal(#another.task.params.tasks,0) equal(p.y,-12)
end)

test("VECTOR waypoints create only the stored coordinate and leave input untouched",function()
  local g=group()
  local v=VECTOR:New(100,-15,300)
  function v:GetCoordinate() error("Temporary COORDINATE must not be created") end
  local before=coordinates
  local wp=g:AddWaypoint(v,20)
  equal(coordinates-before,1)
  equal(wp.x,100) equal(wp.y,300) equal(wp.alt,-15) near(wp.speed,20*1852/3600)
  equal(wp.coordinate.x,100) equal(wp.coordinate.y,-15) equal(wp.coordinate.z,300)
  equal(wp.coordinate.ClassName,"COORDINATE") equal(g.waypoints[1],wp)
  equal(g.updates,1) equal(g.updateDelay,-0.01)
  equal(wp.task.params.tasks[1].uid,wp.uid)
  wp.coordinate.x=999 equal(v.x,100)
  v.z=777 equal(wp.y,300) equal(wp.coordinate.z,300)
end)

test("VECTOR and COORDINATE inputs produce identical naval waypoint data",function()
  for _,depth in ipairs({false,0,100,-100}) do
    local a,b=group(),group()
    local coordinate=COORDINATE:New(123,-7,456)
    local v=VECTOR:New(123,-7,456)
    local override=depth~=false and depth or nil
    local before=coordinates
    local wa=a:AddWaypoint(v,nil,nil,override,false)
    local wb=b:AddWaypoint(coordinate,nil,nil,override,false)
    equal(coordinates-before,2) same(wa,wb)
    near(wa.speed,12*1852/3600)
    near(wa.alt,override and override*0.3048 or -7)
    equal(wa.coordinate.y,wa.alt)
    equal(v.y,-7) equal(coordinate.y,-7) equal(a.updates,0) equal(b.updates,0)
  end
end)

test("waypoint insertion UID and route update flags remain intact",function()
  local g=group()
  local first=g:AddWaypoint(VECTOR:New(0,0,0),0,nil,nil,false)
  local last=g:AddWaypoint(VECTOR:New(200,0,200),10,nil,nil,false)
  local middle=g:AddWaypoint(VECTOR:New(100,0,100),20,first.uid,nil,true)
  equal(g.waypoints[1],first) equal(g.waypoints[2],middle) equal(g.waypoints[3],last)
  equal(first.uid,1) equal(last.uid,2) equal(middle.uid,3) equal(first.speed,0)
  equal(g.updates,1)
end)

test("POSITIONABLE and ZONE_BASE inputs keep the existing coordinate resolution",function()
  for _,kind in ipairs({"POSITIONABLE","ZONE_BASE"}) do
    local p=COORDINATE:New(10,-10,20)
    local requests=0
    local object={IsInstanceOf=function(_,name) return name==kind end,
      GetCoordinate=function() requests=requests+1 return p end}
    local before=coordinates
    local wp=group():AddWaypoint(object,15,nil,30,false)
    equal(requests,1) equal(coordinates-before,1)
    equal(wp.x,10) equal(wp.y,20) near(wp.alt,9.144) equal(wp.coordinate.y,wp.alt)
    equal(p.y,-10)
  end
end)

test("31 VECTOR path positions need 31 stored coordinates instead of 62",function()
  local g=group()
  local before=coordinates
  local uid
  for i=1,31 do
    local wp=g:AddWaypoint(VECTOR:New(i*100,0,i*200),20,uid,nil,false)
    uid=wp.uid
  end
  equal(coordinates-before,31) equal(#g.waypoints,31) equal(g.updates,0)
end)

test("air VECTOR and COORDINATE waypoints preserve altitude references and copy final altitude",function()
  for _,helo in ipairs({false,true}) do
    for _,override in ipairs({false,0,100,-100}) do
      local a,b=group(FLIGHTGROUP),group(FLIGHTGROUP)
      a.isHelo=helo b.isHelo=helo
      local v=VECTOR:New(100,37,300)
      local c=COORDINATE:New(100,37,300)
      local alt=override~=false and override or nil
      local before=coordinates
      local wa=a:AddWaypoint(v,20,nil,alt,false)
      local wb=b:AddWaypoint(c,20,nil,alt,false)
      equal(coordinates-before,2) same(wa,wb)
      equal(wa.alt_type,helo and "RADIO" or "BARO")
      near(wa.alt,alt and alt*0.3048 or 37) equal(wa.coordinate.y,wa.alt)
      near(wa.speed,20*1852/3600) equal(wa.type,"Turning Point")
      equal(v.y,37) equal(c.y,37) equal(a.updates,0)
    end
  end
end)

test("ground waypoints use terrain height and retain nearest-road metadata",function()
  local v=VECTOR:New(100,9999,400)
  local c=COORDINATE:New(100,9999,400)
  local before=coordinates
  local a=group(ARMYGROUP):AddWaypoint(v,20,nil,"Vee",false)
  local b=group(ARMYGROUP):AddWaypoint(c,20,nil,"Vee",false)
  same(a,b) equal(coordinates-before,4) -- One stored waypoint coordinate and one stored road coordinate per waypoint.
  equal(a.alt,31) equal(a.coordinate.y,31) equal(a.alt_type,"BARO") equal(a.action,"Vee")
  equal(a.roadcoord.x,130) equal(a.roadcoord.z,440) equal(a.roaddist,50)
  equal(v.y,9999) equal(c.y,9999)
  v.x=999 equal(a.coordinate.x,100) equal(a.x,100)
end)

test("ground formation precedence and missing-road fallback are retained",function()
  local g=group(ARMYGROUP)
  g.formationPerma="Vee" g.optionDefault.Formation="Cone" g.option.Formation="Off Road"
  local v=VECTOR:New(100,0,400)
  equal(g:AddWaypoint(v,0,nil,"Diamond",false).action,"Diamond")
  equal(g:AddWaypoint(v,0,nil,nil,false).action,"Vee")
  g.formationPerma=nil
  equal(g:AddWaypoint(v,0,nil,nil,false).action,"Cone")
  g.optionDefault.Formation=nil
  equal(g:AddWaypoint(v,0,nil,nil,false).action,"Off Road")
  g.option.Formation=nil roadMissing=true
  local before=coordinates
  local wp=g:AddWaypoint(v,0,nil,nil,false)
  equal(wp.action,"On Road") equal(wp.roadcoord,nil) equal(wp.roaddist,1000000)
  equal(wp.speed,0) equal(coordinates-before,1)
end)

test("all group types resolve POSITIONABLE and ZONE inputs and preserve insertion semantics",function()
  for _,class in ipairs({FLIGHTGROUP,ARMYGROUP,NAVYGROUP}) do
    for _,kind in ipairs({"POSITIONABLE","ZONE_BASE"}) do
      local g=group(class)
      local c=COORDINATE:New(100,30,400)
      local requests=0
      local object={IsInstanceOf=function(_,name) return name==kind end,
        GetCoordinate=function() requests=requests+1 return c end}
      local first=g:AddWaypoint(object,nil,nil,nil,false)
      local last=g:AddWaypoint(VECTOR:New(200,30,400),0,nil,nil,false)
      local middle=g:AddWaypoint(object,20,first.uid,nil,true)
      equal(requests,2) equal(g.waypoints[1],first) equal(g.waypoints[2],middle) equal(g.waypoints[3],last)
      near(first.speed,12*1852/3600) equal(last.speed,0) equal(g.updates,1)
      equal(c.x,100) equal(c.y,30) equal(c.z,400)
    end
  end
end)

local function airbase(category)
  local c=COORDINATE:New(100,60,400)
  return {GetID=function() return 123 end,GetAirbaseCategory=function() return category end,
    IsAirdrome=function() return category==Airbase.Category.AIRDROME end,GetCoordinate=function() return c end}
end

test("air route builders preserve airbase links defaults flags and task references",function()
  local c=COORDINATE:New(100,60,400)
  local default=c:WaypointAir()
  equal(default.alt_type,"RADIO") equal(default.alt,60) near(default.speed,500/3.6)
  equal(default.speed_locked,true) equal(default.ETA,0) equal(default.ETA_locked,false)
  for _,category in ipairs({Airbase.Category.AIRDROME,Airbase.Category.SHIP,Airbase.Category.HELIPAD}) do
    local base=airbase(category)
    local tasks={{id="test"}}
    local wp=c:WaypointAir("BARO","LandingReFuAr","LandingReFuAr",0,false,base,tasks,"Refuel",0)
    equal(wp.task.params.tasks,tasks) equal(wp.name,"Refuel") equal(wp.timeReFuAr,0)
    equal(wp.speed,0) equal(wp.speed_locked,false)
    if category==Airbase.Category.AIRDROME then
      equal(wp.airdromeId,123) equal(wp.linkUnit,nil) equal(wp.helipadId,nil)
    else
      equal(wp.linkUnit,123) equal(wp.helipadId,123) equal(wp.airdromeId,nil)
    end
  end
  equal(c:WaypointAir("BARO","LandingReFuAr").timeReFuAr,10)
  local another=c:WaypointAir()
  default.task.params.tasks[1]={id="Changed"} equal(#another.task.params.tasks,0)
end)

test("ground route builder preserves DCS defaults and custom tasks",function()
  local c=COORDINATE:New(100,-500,400)
  local wp=c:WaypointGround()
  same(wp,{x=100,y=400,alt=31,alt_type="BARO",type="Turning Point",action="Off Road",
    formation_template="",ETA=0,ETA_locked=false,speed=20/3.6,speed_locked=true,
    task={id="ComboTask",params={tasks={}}}})
  local tasks={{id="test"}}
  local explicit=c:WaypointGround(0,"Cone",tasks)
  equal(explicit.task.params.tasks,tasks) equal(explicit.action,"Cone") equal(explicit.speed,0)
  equal(c.y,-500)
end)

test("landing waypoints convert knots and feet before storing their coordinate",function()
  local base=airbase(Airbase.Category.AIRDROME)
  for _,speed in ipairs({false,0,100}) do
    for _,altitude in ipairs({false,0,100}) do
      local g=group(FLIGHTGROUP)
      g.speedCruise=12*1.852 -- Internal storage uses km/h; public AddWaypoint arguments use knots.
      local before=coordinates
      local wp=g:AddWaypointLanding(base,speed~=false and speed or nil,nil,altitude~=false and altitude or nil,false)
      equal(coordinates-before,1) equal(wp.coordinate.y,wp.alt)
      near(wp.speed,(speed~=false and speed or 12)*1852/3600)
      near(wp.alt,altitude~=false and altitude*0.3048 or 60)
      equal(wp.airdromeId,123) equal(wp.alt_type,"BARO") equal(wp.type,"Land")
      equal(base:GetCoordinate().y,60) equal(g.updates,0)
    end
  end
  local g=group(FLIGHTGROUP)
  g:AddWaypointLanding(base)
  equal(g.updates,1) equal(g.updateDelay,-1)
end)

test("Mission Editor waypoint import uses vectors and retains tasks without reading global overrides",function()
  local oldAltitude,oldDepth=Altitude,Depth
  Altitude=99999 Depth=99999
  local ok,err=pcall(function()
    for _,class in ipairs({FLIGHTGROUP,ARMYGROUP,NAVYGROUP}) do
      for _,helo in ipairs({false,true}) do
        local g=group(class) g.isHelo=helo g.useMEtasks=true
        local points={{x=100,y=400,alt=60,speed=10,action="Vee",task={params={tasks={{id="FireAtPoint"},{id="WrappedAction"}}}}},
          {x=200,y=600,alt=80,speed=0,action="Cone"}}
        _DATABASE={GetGroupTemplate=function() return {route={points=points}} end}
        local tasks={}
        function g:AddTaskWaypoint(task,wp) tasks[#tasks+1]={task=task,wp=wp} end
        local before=coordinates
        equal(g:_InitWaypoints(),g)
        equal(coordinates-before,class==ARMYGROUP and 4 or 2)
        equal(#g.waypoints,2) equal(g.updates,0) equal(#tasks,1)
        equal(tasks[1].task.id,"FireAtPoint") equal(tasks[1].wp,g.waypoints[1])
        -- UTILS.MpsToKnots uses a rounded conversion constant.
        assert(math.abs(g.waypoints[1].speed-10)<1e-4) equal(g.waypoints[2].speed,0)
        equal(g.waypoints[1].coordinate.y,g.waypoints[1].alt)
        equal(g.waypoints[1].alt,class==ARMYGROUP and 31 or 60)
        if class==ARMYGROUP then equal(g.waypoints[1].action,"Vee") end
        equal(points[1].alt,60) equal(points[1].coordinate,nil) equal(points[1].uid,nil)
      end
    end
  end)
  Altitude,Depth=oldAltitude,oldDepth
  assert(ok,err)
end)

print(string.format("%d passed, %d failed",passed,failed))
if failed>0 then os.exit(1) end
