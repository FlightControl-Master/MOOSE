-- Standalone detailed depth regressions. Run from the repository root: lua tests/depth.lua
-- Deterministic DCS terrain stubs exercise the shared rule and original-direction distance reports.
dofile("Moose Development/Moose/Core/Astar.lua")

local passed,failed=0,0
local function equal(actual,expected)
  assert(actual==expected,"expected "..tostring(expected)..", got "..tostring(actual))
end
local function near(actual,expected)
  assert(math.abs(actual-expected)<1e-7,"expected "..tostring(expected)..", got "..tostring(actual))
end
local function node(x,z)
  return {vector={x=x,y=100,z=z or 0}}
end
local function terrain()
  local data={calls={},depth=40}
  land={SurfaceType={LAND=1,SHALLOW_WATER=2,WATER=3,ROAD=4,RUNWAY=5}}
  land.getSurfaceType=function(p) return data.surface and data.surface(p) or 3 end
  land.getSurfaceHeightWithSeabed=function(p) return 0,data.depthAt and data.depthAt(p) or data.depth end
  land.profile=function(a,b)
    data.calls[#data.calls+1]={a=a,b=b}
    if data.profile then return data.profile(a,b) end
    return {{x=a.x,y=-40,z=a.z},{x=b.x,y=-40,z=b.z}}
  end
  return data
end
local function test(name,run)
  local ok,err=pcall(run)
  if ok then
    passed=passed+1
    print("PASS "..name)
  else
    failed=failed+1
    print("FAIL "..name..": "..tostring(err))
  end
end

test("clear report measures horizontal length without mutating node altitude",function()
  local data=terrain()
  local a,b=node(0),node(300,400)
  local clear,reason,report=ASTAR.CheckDepth(a,b,20,100)
  equal(clear,true) equal(reason,nil) equal(report.Status,"clear")
  near(report.Distance,500) near(report.ClearDistance,500) equal(report.RequiredDepth,20)
  equal(#data.calls,3) equal(a.vector.y,100) equal(b.vector.y,100)
end)

test("unordered irregular support points use actual distances in both directions",function()
  local data=terrain()
  data.profile=function()
    return {{x=900,y=-40,z=0},{x=500,y=-10,z=0},{x=100,y=-40,z=0},{x=0,y=-40,z=0}}
  end
  local clear,reason,report=ASTAR.CheckDepth(node(0),node(1000),20)
  equal(clear,false) equal(reason,"profile_blocked") equal(report.Status,"blocked")
  near(report.ClearDistance,100+400*2/3) equal(report.Point.x,500)
  equal(report.Depth,10) equal(report.SurfaceType,3) equal(report.Cause,"insufficient_depth")
  local _,_,reverse=ASTAR.CheckDepth(node(1000),node(0),20)
  near(reverse.ClearDistance,100+400*2/3)
  equal(data.calls[1].a.x,data.calls[2].a.x) equal(data.calls[1].b.x,data.calls[2].b.x)
end)

test("asymmetric obstruction reports the original-direction first threshold",function()
  local data=terrain()
  data.profile=function()
    return {{x=0,y=-40,z=0},{x=200,y=-10,z=0},{x=1000,y=-40,z=0}}
  end
  local _,_,forward=ASTAR.CheckDepth(node(0),node(1000),20)
  local _,_,reverse=ASTAR.CheckDepth(node(1000),node(0),20)
  near(forward.ClearDistance,200*2/3) near(reverse.ClearDistance,800*2/3)
end)

test("closest corridor obstruction wins and its side follows original travel direction",function()
  local data=terrain()
  data.profile=function(a,b)
    local x=a.z==50 and 300 or (a.z==-50 and 600 or 900)
    return {{x=a.x,y=-40,z=a.z},{x=x,y=-10,z=a.z},{x=b.x,y=-40,z=b.z}}
  end
  local _,_,forward=ASTAR.CheckDepth(node(0),node(1000),20,100)
  near(forward.ClearDistance,200) equal(forward.ProfileOffset,50) equal(#data.calls,3)
  local _,_,reverse=ASTAR.CheckDepth(node(1000),node(0),20,100)
  near(reverse.ClearDistance,100*2/3) equal(reverse.ProfileOffset,0) equal(#data.calls,6)

  data.profile=function(a,b)
    return {{x=a.x,y=-40,z=a.z},{x=900,y=a.z==50 and -10 or -40,z=a.z},{x=b.x,y=-40,z=b.z}}
  end
  local _,_,side=ASTAR.CheckDepth(node(1000),node(0),20,100)
  near(side.ClearDistance,100*2/3) equal(side.ProfileOffset,-50)
end)

test("non-water samples stop the prefix at the preceding valid position",function()
  local data=terrain()
  data.surface=function(p) return p.x==700 and 1 or 3 end
  data.profile=function()
    return {{x=0,y=-40,z=0},{x=250,y=-40,z=0},{x=700,y=-40,z=0},{x=1000,y=-40,z=0}}
  end
  local _,_,report=ASTAR.CheckDepth(node(0),node(1000),20)
  equal(report.Status,"blocked") equal(report.Cause,"non_water") equal(report.Depth,nil)
  near(report.ClearDistance,250) equal(report.SurfaceType,1) equal(report.Point.x,700)
end)

test("blocked original start reports zero without creating a profile in either direction",function()
  local data=terrain()
  data.depthAt=function(p) return p.x==1000 and 5 or 40 end
  local clear,_,report=ASTAR.CheckDepth(node(1000),node(0),20)
  equal(clear,false) equal(report.Location,"start") near(report.ClearDistance,0) equal(#data.calls,0)
  data.depthAt=function(p) return p.x==0 and 5 or 40 end
  _,_,report=ASTAR.CheckDepth(node(0),node(1000),20)
  equal(report.Location,"start") near(report.ClearDistance,0) equal(#data.calls,0)
end)

test("omitted endpoint depth participates in threshold interpolation",function()
  local data=terrain()
  data.profile=function() return {{x=100,y=-40,z=0},{x=800,y=-40,z=0}} end
  data.depthAt=function(p) return p.x==1000 and 10 or 40 end
  local clear,_,report=ASTAR.CheckDepth(node(0),node(1000),20)
  equal(clear,false) equal(report.Location,"goal") equal(report.Point.x,1000)
  near(report.ClearDistance,800+200*2/3)
end)

test("duplicate profile endpoints keep their shallower depth bound",function()
  local data=terrain()
  data.profile=function()
    return {{x=0,y=-20,z=0},{x=500,y=-10,z=0},{x=1000,y=-40,z=0}}
  end
  local _,_,report=ASTAR.CheckDepth(node(0),node(1000),20)
  near(report.ClearDistance,0)
end)

test("direct depth remains a bound when the native profile is deeper",function()
  local data=terrain()
  data.depthAt=function(p) return p.x==500 and 5 or 40 end
  data.profile=function() return {{x=0,y=-40,z=0},{x=500,y=-40,z=0},{x=1000,y=-40,z=0}} end
  local _,_,report=ASTAR.CheckDepth(node(0),node(1000),20)
  near(report.ClearDistance,500*20/35) equal(report.Depth,5)
end)

test("zero-length preflight checks the exact position and reports a known failure",function()
  local data=terrain() data.depth=10
  local a=node(200,300)
  local clear,_,report=ASTAR.CheckDepth(a,a,20,200)
  equal(clear,false) equal(report.Status,"blocked") equal(report.Location,"start")
  equal(report.Depth,10) near(report.Distance,0) near(report.ClearDistance,0) equal(#data.calls,0)
  data.depth=20
  clear,_,report=ASTAR.CheckDepth(a,a,20)
  equal(clear,true) equal(report.Status,"clear") equal(report.Depth,20)
end)

test("native profile failure is unavailable and does not escape the check",function()
  local data=terrain()
  for _,fail in ipairs({function() error("DCS failure") end,function() return nil end}) do
    data.profile=fail
    equal(ASTAR.Depth(node(0),node(1000)),false)
    local clear,_,report=ASTAR.CheckDepth(node(0),node(1000))
    equal(clear,false) equal(report.Status,"unavailable") near(report.ClearDistance,0)
  end
end)

test("missing native functions and failed surface or seabed queries are unavailable",function()
  for _,name in ipairs({"profile","getSurfaceType","getSurfaceHeightWithSeabed"}) do
    terrain() land[name]=nil
    local clear,reason,report=ASTAR.CheckDepth(node(0),node(1000))
    equal(clear,false) equal(reason,"depth_api_unavailable") equal(report.Status,"unavailable")
    near(report.Distance,1000) near(report.ClearDistance,0)
    terrain() land[name]=function() error("DCS failure") end
    clear,reason,report=ASTAR.CheckDepth(node(0),node(1000))
    equal(clear,false) equal(report.Status,"unavailable") near(report.ClearDistance,0)
  end
end)

test("malformed depth or classification is unavailable rather than confirmed shallows",function()
  for _,bad in ipairs({false,"20",-1,math.huge,0/0}) do
    terrain() land.getSurfaceHeightWithSeabed=function() return 0,bad end
    local clear,_,report=ASTAR.CheckDepth(node(0),node(1000))
    equal(clear,false) equal(report.Status,"unavailable") near(report.ClearDistance,0)
  end
  for _,bad in ipairs({false,"water",0,99,0/0}) do
    terrain() land.getSurfaceType=function() return bad end
    local clear,_,report=ASTAR.CheckDepth(node(0),node(1000))
    equal(clear,false) equal(report.Status,"unavailable") near(report.ClearDistance,0)
  end
end)

test("native profile positions may be offset from the line and its endpoints",function()
  local data=terrain()
  data.profile=function(a,b)
    local dx,dz=b.x-a.x,b.z-a.z
    local distance=math.sqrt(dx*dx+dz*dz)
    local points={}

    -- Model native support points one meter off the requested line, including endpoint overshoot.
    for _,fraction in ipairs({-0.001,0.3,1.001}) do
      points[#points+1]={x=a.x+dx*fraction-dz/distance,z=a.z+dz*fraction+dx/distance,y=-40}
    end

    return points
  end

  for _,reverse in ipairs({false,true}) do
    local a,b=node(0),node(300,400)
    if reverse then a,b=b,a end

    equal(ASTAR.Depth(a,b,20,100),true)
    local clear,reason,report=ASTAR.CheckDepth(a,b,20,100)
    equal(clear,true) equal(reason,nil) equal(report.Status,"clear")
    near(report.Distance,500) near(report.ClearDistance,500)
  end
end)

test("offset support points preserve projected obstruction distances in both directions",function()
  local data=terrain()
  data.profile=function(a,b)
    return {
      {x=a.x,y=-40,z=a.z},
      {x=219.4,y=-10,z=360.45},
      {x=b.x,y=-40,z=b.z},
    }
  end

  -- The shallow sample is 200 meters along this 1000-meter segment and 0.75 meters to its side.
  local a,b=node(100,200),node(700,1000)
  equal(ASTAR.Depth(a,b,20),false) equal(ASTAR.Depth(b,a,20),false)

  local clear,reason,forward=ASTAR.CheckDepth(a,b,20)
  local _,_,reverse=ASTAR.CheckDepth(b,a,20)
  equal(clear,false) equal(reason,"profile_blocked") equal(forward.Cause,"insufficient_depth")
  near(forward.ClearDistance,200*2/3) near(reverse.ClearDistance,800*2/3)
  near(forward.Point.x,219.4) near(forward.Point.z,360.45)
  equal(forward.Depth,10) equal(reverse.Depth,10)
end)

test("endpoint overshoot is clamped but shallow water and land are still rejected",function()
  for _,reverse in ipairs({false,true}) do
    for _,cause in ipairs({"insufficient_depth","non_water"}) do
      local data=terrain()
      local points={{x=-0.5,y=-40,z=0.25},{x=500,y=-40,z=0.25},{x=1000.5,y=-40,z=0.25}}
      local rejected=points[reverse and 3 or 1]

      if cause=="insufficient_depth" then
        rejected.y=-10
      else
        data.surface=function(p) return p.x==rejected.x and 1 or 3 end
      end

      data.profile=function() return points end
      local a,b=node(0),node(1000)
      if reverse then a,b=b,a end

      local fast,fastReason=ASTAR.Depth(a,b,20)
      local clear,reason,report=ASTAR.CheckDepth(a,b,20)
      equal(fast,false) equal(fastReason,"profile_blocked") equal(clear,false) equal(reason,"profile_blocked")
      equal(report.Status,"blocked") equal(report.Cause,cause)
      near(report.ClearDistance,0) equal(report.Point.x,rejected.x)
    end
  end
end)

test("malformed profile coordinates and heights remain unavailable",function()
  for _,point in ipairs({false,{x=500,y=-40},{x="500",y=-40,z=0},{x=0/0,y=-40,z=0},
    {x=500,y=-40,z=math.huge},{x=500,y=0/0,z=0}}) do
    local data=terrain()
    data.profile=function() return {{x=0,y=-40,z=0},point,{x=1000,y=-40,z=0}} end
    equal(ASTAR.Depth(node(0),node(1000)),false)
    local clear,_,report=ASTAR.CheckDepth(node(0),node(1000))
    equal(clear,false) equal(report.Status,"unavailable") near(report.ClearDistance,0)
  end
end)

test("short profiles share bounded direct sampling and a useful obstruction distance",function()
  local data=terrain()
  data.profile=function() return {} end
  data.depthAt=function(p) return p.x==200 and 10 or 40 end
  local clear,reason,report=ASTAR.CheckDepth(node(0),node(400),20)
  equal(clear,false) equal(reason,"profile_fallback_blocked") equal(report.Location,"profile_fallback")
  near(report.ClearDistance,100+100*2/3) equal(#data.calls,1)
  data.depthAt=nil
  clear,reason,report=ASTAR.CheckDepth(node(0),node(100001),20)
  equal(clear,false) equal(reason,"profile_fallback_limit") equal(report.Status,"unavailable")
end)

test("fast neighbour checks allocate no diagnostic reports and short-circuit bad endpoints",function()
  local data=terrain()
  local original=ASTAR._DepthReport
  ASTAR._DepthReport=function() error("Unexpected diagnostic allocation") end
  local ok,err=pcall(function()
    equal(ASTAR.Depth(node(0),node(1000),20,100),true)
    equal(#data.calls,3)
    data.depthAt=function(p) return p.x==0 and 10 or 40 end
    equal(ASTAR.Depth(node(0),node(1000),20,100),false)
    equal(#data.calls,3)
  end)
  ASTAR._DepthReport=original
  assert(ok,err)
end)

test("depth thresholds are inclusive and explicit false arguments remain invalid",function()
  local data=terrain() data.depth=20
  data.profile=function(a,b) return {{x=a.x,y=-20,z=a.z},{x=b.x,y=-20,z=b.z}} end
  equal(ASTAR.Depth(node(0),node(1000),20),true)
  equal(ASTAR.CheckDepth(node(0),node(1000),20),true)
  assert(not pcall(ASTAR.CheckDepth,node(0),node(1000),false))
  assert(not pcall(ASTAR.CheckDepth,node(0),node(1000),20,false))
end)

test("detailed and fast validity agree across deterministic profiles and reversed queries",function()
  local data=terrain()
  for case=1,120 do
    data.profile=function(a,b)
      local points={}
      for i=0,5 do
        local fraction=(i/5)^2
        local depth=(case*17+i*13+math.floor(a.z))%45+1
        points[#points+1]={x=a.x+(b.x-a.x)*fraction,z=a.z+(b.z-a.z)*fraction,y=-depth}
      end
      return points
    end
    for _,width in ipairs({0,100}) do
      for _,reverse in ipairs({false,true}) do
        local a,b=node(0),node(1000)
        if reverse then a,b=b,a end
        local fast=ASTAR.Depth(a,b,20,width)
        local clear,_,report=ASTAR.CheckDepth(a,b,20,width)
        equal(clear,fast)
        assert(report.ClearDistance>=0 and report.ClearDistance<=report.Distance)
        equal(report.Status,clear and "clear" or "blocked")
      end
    end
  end
end)

print(string.format("%d passed, %d failed",passed,failed))
if failed>0 then os.exit(1) end
