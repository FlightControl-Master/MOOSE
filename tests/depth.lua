-- Standalone detailed depth regressions. Run from the repository root: lua tests/depth.lua
-- Deterministic DCS terrain stubs exercise the shared rule and original-direction distance reports.
dofile("Moose Development/Moose/Core/Vector.lua")
dofile("Moose Development/Moose/Core/Astar.lua")
dofile("Moose Development/Moose/Core/Pathline.lua")

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
  local clear,reason,report=PATHLINE.CheckDepth(a.vector,b.vector,20,100)
  equal(clear,true) equal(reason,nil) equal(report.Status,"clear")
  near(report.Distance,500) near(report.ClearDistance,500) equal(report.RequiredDepth,20)
  equal(#data.calls,3) equal(a.vector.y,100) equal(b.vector.y,100)
end)

test("unordered irregular support points use actual distances in both directions",function()
  local data=terrain()
  data.profile=function()
    return {{x=900,y=-40,z=0},{x=500,y=-10,z=0},{x=100,y=-40,z=0},{x=0,y=-40,z=0}}
  end
  local clear,reason,report=PATHLINE.CheckDepth(node(0).vector,node(1000).vector,20)
  equal(clear,false) equal(reason,"profile_blocked") equal(report.Status,"blocked")
  near(report.ClearDistance,100+400*2/3) equal(report.Point.x,500)
  equal(report.Depth,10) equal(report.SurfaceType,3) equal(report.Cause,"insufficient_depth")
  local _,_,reverse=PATHLINE.CheckDepth(node(1000).vector,node(0).vector,20)
  near(reverse.ClearDistance,100+400*2/3)
  equal(data.calls[1].a.x,data.calls[2].a.x) equal(data.calls[1].b.x,data.calls[2].b.x)
end)

test("asymmetric obstruction reports the original-direction first threshold",function()
  local data=terrain()
  data.profile=function()
    return {{x=0,y=-40,z=0},{x=200,y=-10,z=0},{x=1000,y=-40,z=0}}
  end
  local _,_,forward=PATHLINE.CheckDepth(node(0).vector,node(1000).vector,20)
  local _,_,reverse=PATHLINE.CheckDepth(node(1000).vector,node(0).vector,20)
  near(forward.ClearDistance,200*2/3) near(reverse.ClearDistance,800*2/3)
end)

test("closest corridor obstruction wins and its side follows original travel direction",function()
  local data=terrain()
  data.profile=function(a,b)
    local x=a.z==50 and 300 or (a.z==-50 and 600 or 900)
    return {{x=a.x,y=-40,z=a.z},{x=x,y=-10,z=a.z},{x=b.x,y=-40,z=b.z}}
  end
  local _,_,forward=PATHLINE.CheckDepth(node(0).vector,node(1000).vector,20,100)
  near(forward.ClearDistance,200) equal(forward.ProfileOffset,50) equal(#data.calls,3)
  local _,_,reverse=PATHLINE.CheckDepth(node(1000).vector,node(0).vector,20,100)
  near(reverse.ClearDistance,100*2/3) equal(reverse.ProfileOffset,0) equal(#data.calls,6)

  data.profile=function(a,b)
    return {{x=a.x,y=-40,z=a.z},{x=900,y=a.z==50 and -10 or -40,z=a.z},{x=b.x,y=-40,z=b.z}}
  end
  local _,_,side=PATHLINE.CheckDepth(node(1000).vector,node(0).vector,20,100)
  near(side.ClearDistance,100*2/3) equal(side.ProfileOffset,-50)
end)

test("non-water samples stop the prefix at the preceding valid position",function()
  local data=terrain()
  data.surface=function(p) return p.x==700 and 1 or 3 end
  data.profile=function()
    return {{x=0,y=-40,z=0},{x=250,y=-40,z=0},{x=700,y=-40,z=0},{x=1000,y=-40,z=0}}
  end
  local _,_,report=PATHLINE.CheckDepth(node(0).vector,node(1000).vector,20)
  equal(report.Status,"blocked") equal(report.Cause,"non_water") equal(report.Depth,nil)
  near(report.ClearDistance,250) equal(report.SurfaceType,1) equal(report.Point.x,700)
end)

test("blocked original start reports zero without creating a profile in either direction",function()
  local data=terrain()
  data.depthAt=function(p) return p.x==1000 and 5 or 40 end
  local clear,_,report=PATHLINE.CheckDepth(node(1000).vector,node(0).vector,20)
  equal(clear,false) equal(report.Location,"start") near(report.ClearDistance,0) equal(#data.calls,0)
  data.depthAt=function(p) return p.x==0 and 5 or 40 end
  _,_,report=PATHLINE.CheckDepth(node(0).vector,node(1000).vector,20)
  equal(report.Location,"start") near(report.ClearDistance,0) equal(#data.calls,0)
end)

test("omitted endpoint depth participates in threshold interpolation",function()
  local data=terrain()
  data.profile=function() return {{x=100,y=-40,z=0},{x=800,y=-40,z=0}} end
  data.depthAt=function(p) return p.x==1000 and 10 or 40 end
  local clear,_,report=PATHLINE.CheckDepth(node(0).vector,node(1000).vector,20)
  equal(clear,false) equal(report.Location,"goal") equal(report.Point.x,1000)
  near(report.ClearDistance,800+200*2/3)
end)

test("duplicate profile endpoints keep their shallower depth bound",function()
  local data=terrain()
  data.profile=function()
    return {{x=0,y=-20,z=0},{x=500,y=-10,z=0},{x=1000,y=-40,z=0}}
  end
  local _,_,report=PATHLINE.CheckDepth(node(0).vector,node(1000).vector,20)
  near(report.ClearDistance,0)
end)

test("direct depth remains a bound when the native profile is deeper",function()
  local data=terrain()
  data.depthAt=function(p) return p.x==500 and 5 or 40 end
  data.profile=function() return {{x=0,y=-40,z=0},{x=500,y=-40,z=0},{x=1000,y=-40,z=0}} end
  local _,_,report=PATHLINE.CheckDepth(node(0).vector,node(1000).vector,20)
  near(report.ClearDistance,500*20/35) equal(report.Depth,5)
end)

test("zero-length preflight checks the exact position and reports a known failure",function()
  local data=terrain() data.depth=10
  local a=node(200,300)
  local clear,_,report=PATHLINE.CheckDepth(a.vector,a.vector,20,200)
  equal(clear,false) equal(report.Status,"blocked") equal(report.Location,"start")
  equal(report.Depth,10) near(report.Distance,0) near(report.ClearDistance,0) equal(#data.calls,0)
  data.depth=20
  clear,_,report=PATHLINE.CheckDepth(a.vector,a.vector,20)
  equal(clear,true) equal(report.Status,"clear") equal(report.Depth,20)
end)

test("non-finite connection lengths cannot enter native terrain queries",function()
  local data=terrain()
  local a,b=node(-1e200),node(1e200)
  local fast,fastReason=ASTAR.Depth(a,b,20)
  local clear,reason,report=PATHLINE.CheckDepth(a.vector,b.vector,20)

  equal(fast,false) equal(fastReason,"invalid_distance") equal(clear,false) equal(reason,fastReason)
  equal(report.Status,"unavailable") near(report.ClearDistance,0) equal(#data.calls,0)
end)

test("native profile results without a table are unavailable",function()
  local data=terrain()
  for _,profile in ipairs({function() return nil end,function() return false end,function() return "profile" end}) do
    data.profile=profile
    local fast,fastReason=ASTAR.Depth(node(0),node(1000))
    local clear,reason,report=PATHLINE.CheckDepth(node(0).vector,node(1000).vector)
    equal(fast,false) equal(clear,false) equal(fastReason,"profile_unavailable") equal(reason,fastReason)
    equal(report.Status,"unavailable") near(report.ClearDistance,0)
  end
end)

test("DCS API exceptions propagate from both depth checks",function()
  for _,name in ipairs({"profile","getSurfaceType","getSurfaceHeightWithSeabed"}) do
    terrain()
    land[name]=function() error("DCS failure in "..name) end

    local ok,err=pcall(ASTAR.Depth,node(0),node(1000))
    equal(ok,false) assert(tostring(err):find("DCS failure in "..name,1,true))

    ok,err=pcall(PATHLINE.CheckDepth,node(0).vector,node(1000).vector)
    equal(ok,false) assert(tostring(err):find("DCS failure in "..name,1,true))
  end
end)

test("malformed depth or classification is unavailable rather than confirmed shallows",function()
  for _,bad in ipairs({false,"20",-1,math.huge,0/0}) do
    terrain() land.getSurfaceHeightWithSeabed=function() return 0,bad end
    local clear,_,report=PATHLINE.CheckDepth(node(0).vector,node(1000).vector)
    equal(clear,false) equal(report.Status,"unavailable") near(report.ClearDistance,0)
  end
  for _,bad in ipairs({false,"water",0,99,0/0}) do
    terrain() land.getSurfaceType=function() return bad end
    local clear,_,report=PATHLINE.CheckDepth(node(0).vector,node(1000).vector)
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
    local clear,reason,report=PATHLINE.CheckDepth(a.vector,b.vector,20,100)
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

  local clear,reason,forward=PATHLINE.CheckDepth(a.vector,b.vector,20)
  local _,_,reverse=PATHLINE.CheckDepth(b.vector,a.vector,20)
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
      local clear,reason,report=PATHLINE.CheckDepth(a.vector,b.vector,20)
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
    local clear,_,report=PATHLINE.CheckDepth(node(0).vector,node(1000).vector)
    equal(clear,false) equal(report.Status,"unavailable") near(report.ClearDistance,0)
  end
end)

test("short profiles share bounded direct sampling and a useful obstruction distance",function()
  local data=terrain()
  data.profile=function() return {} end
  data.depthAt=function(p) return p.x==200 and 10 or 40 end
  local clear,reason,report=PATHLINE.CheckDepth(node(0).vector,node(400).vector,20)
  equal(clear,false) equal(reason,"profile_fallback_blocked") equal(report.Location,"profile_fallback")
  near(report.ClearDistance,100+100*2/3) equal(#data.calls,1)
  data.depthAt=nil
  clear,reason,report=PATHLINE.CheckDepth(node(0).vector,node(100001).vector,20)
  equal(clear,false) equal(reason,"profile_fallback_limit") equal(report.Status,"unavailable")
end)

test("fast neighbour checks avoid diagnostics projection and sorting",function()
  local data=terrain()
  local check,report,projection,sort=PATHLINE.CheckDepth,PATHLINE._DepthReport,PATHLINE._GetDepthProfileDistance,table.sort
  local function forbidden() error("Unexpected diagnostic work in ASTAR.Depth") end
  PATHLINE.CheckDepth,PATHLINE._DepthReport,PATHLINE._GetDepthProfileDistance,table.sort=forbidden,forbidden,forbidden,forbidden

  local ok,err=pcall(function()
    equal(ASTAR.Depth(node(0),node(1000),20,100),true)
    equal(#data.calls,3)
    data.depthAt=function(p) return p.x==0 and 10 or 40 end
    equal(ASTAR.Depth(node(0),node(1000),20,100),false)
    equal(#data.calls,3)
  end)

  PATHLINE.CheckDepth,PATHLINE._DepthReport,PATHLINE._GetDepthProfileDistance,table.sort=check,report,projection,sort
  assert(ok,err)
end)

test("fast and detailed checks use the same physical point evaluator",function()
  local data=terrain()
  local original=VECTOR._CheckDepthPoint
  local calls={}
  VECTOR._CheckDepthPoint=function(point,minDepth,useProfile)
    calls[#calls+1]={x=point.x,z=point.z,profile=useProfile}
    return original(point,minDepth,useProfile)
  end

  local ok,err=pcall(function()
    equal(ASTAR.Depth(node(0),node(1000),20,100),true)
    assert(#calls>0)
    local fastCalls=calls
    calls={}
    equal(PATHLINE.CheckDepth(node(0).vector,node(1000).vector,20,100),true)
    equal(#calls,#fastCalls)

    -- Both modes must use the same direct endpoints and profile depth bounds, regardless of evaluation order.
    local function counts(points)
      local result={}
      for _,point in ipairs(points) do
        local key=string.format("%g/%g/%s",point.x,point.z,tostring(point.profile))
        result[key]=(result[key] or 0)+1
      end
      return result
    end
    local fastCounts,detailedCounts=counts(fastCalls),counts(calls)
    for key,count in pairs(fastCounts) do equal(detailedCounts[key],count) end
    for key,count in pairs(detailedCounts) do equal(fastCounts[key],count) end
  end)

  VECTOR._CheckDepthPoint=original
  assert(ok,err)
end)

test("depth thresholds are inclusive and explicit false arguments remain invalid",function()
  local data=terrain() data.depth=20
  data.profile=function(a,b) return {{x=a.x,y=-20,z=a.z},{x=b.x,y=-20,z=b.z}} end
  equal(ASTAR.Depth(node(0),node(1000),20),true)
  equal(PATHLINE.CheckDepth(node(0).vector,node(1000).vector,20),true)
  assert(not pcall(ASTAR.Depth,node(0),node(1000),false))
  assert(not pcall(ASTAR.Depth,node(0),node(1000),20,false))
  assert(not pcall(PATHLINE.CheckDepth,node(0).vector,node(1000).vector,false))
  assert(not pcall(PATHLINE.CheckDepth,node(0).vector,node(1000).vector,20,false))
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
        local clear,_,report=PATHLINE.CheckDepth(a.vector,b.vector,20,width)
        equal(clear,fast)
        assert(report.ClearDistance>=0 and report.ClearDistance<=report.Distance)
        equal(report.Status,clear and "clear" or "blocked")
      end
    end
  end
end)

test("depth costs retain the hard threshold and saturate at the preferred depth",function()
  local data=terrain()
  local a,b=node(0),node(1000)
  for _,sample in ipairs({{20,3000},{21,2620},{25,1500},{28,1080},{30,1000},{100,1000}}) do
    data.depth=sample[1]
    near(ASTAR.CostDepth(a,b,20,0,30,2),sample[2])
    near(ASTAR.CostDepth(b,a,20,0,30,2),sample[2])
  end
  data.depth=19.99 equal(ASTAR.CostDepth(a,b,20,0,30,2),math.huge)
  data.depth=20 near(ASTAR.CostDepth(a,b,20,0,30,0),1000)
  near(ASTAR.CostDepth(a,b,20,0,20,2),1000)
  near(ASTAR.CostDepth(a,b,20,0,10,2),1000)
  near(ASTAR.CostDepth(a,a,20,100,30,2),0)
  data.depth=10 equal(ASTAR.CostDepth(a,a,20,0,30,2),math.huge)
end)

test("depth cost integration uses distances, clips at preferred depth and is subdivision invariant",function()
  local data=terrain()
  data.depthAt=function(p) return 20+p.x/50 end
  data.profile=function(a,b)
    local result={}
    for _,fraction in ipairs({1,0.9,0.07,0.07,0,0.31}) do
      local x=a.x+(b.x-a.x)*fraction
      result[#result+1]={x=x,y=-(20+x/50),z=0}
    end
    return result
  end
  local a,b,c=node(0),node(370),node(1000)
  local whole=ASTAR.CostDepth(a,c,20,0,30,2)
  near(whole,1000+2*500/3)
  near(whole,ASTAR.CostDepth(a,b,20,0,30,2)+ASTAR.CostDepth(b,c,20,0,30,2))
  near(whole,ASTAR.CostDepth(c,a,20,0,30,2))
end)

test("crossing side profiles use the shallower side at every distance",function()
  local data=terrain()
  data.depthAt=function(p)
    if p.y==50 then return 20+p.x/100 end
    if p.y==-50 then return 30-p.x/100 end
    return 40
  end
  data.profile=function(a,b)
    local points={}
    for _,f in ipairs({0,1}) do
      local x=a.x+(b.x-a.x)*f
      points[#points+1]={x=x,z=a.z,y=-data.depthAt({x=x,y=a.z})}
    end
    return points
  end
  local a,b,c=node(0),node(250),node(1000)
  near(ASTAR.CostDepth(a,c,20,0,30,2),1000)
  local whole=ASTAR.CostDepth(a,c,20,100,30,2)
  near(whole,1000+2000*7/12)
  near(whole,ASTAR.CostDepth(a,b,20,100,30,2)+ASTAR.CostDepth(b,c,20,100,30,2))
end)

test("depth costs retain direct/profile conservatism and sparse-profile fallback",function()
  local data=terrain()
  data.depth=40
  data.profile=function(a,b) return {{x=a.x,y=-25,z=a.z},{x=b.x,y=-25,z=b.z}} end
  near(ASTAR.CostDepth(node(0),node(1000),20,0,30,2),1500)
  data.depth=21 near(ASTAR.CostDepth(node(0),node(1000),20,0,30,2),2620)
  data.profile=function() return {} end
  near(ASTAR.CostDepth(node(0),node(1000),20,0,30,2),2620)
  data.depthAt=function(p) return p.x==500 and 10 or 40 end
  equal(ASTAR.CostDepth(node(0),node(1000),20,0,30,2),math.huge)
  data.profile=function() return nil end
  equal(ASTAR.CostDepth(node(0),node(1000),20,0,30,2),math.huge)
end)

-- Reduce every sample at a projected distance before using it for interpolation.
local function eachProfileOrder(points,check)
  local function visit(index)
    if index>#points then
      check(points)
      return
    end
    for i=index,#points do
      points[index],points[i]=points[i],points[index]
      visit(index+1)
      points[index],points[i]=points[i],points[index]
    end
  end
  visit(1)
end

test("coincident clear and blocked profile samples cannot extend the safe prefix",function()
  local data=terrain()
  local points={{x=0,y=-40,z=0},{x=500,y=-40,z=0},{x=500,y=-10,z=0},{x=1000,y=-40,z=0}}
  eachProfileOrder(points,function(profile)
    data.profile=function() return profile end
    for _,reverse in ipairs({false,true}) do
      local start,goal=node(0).vector,node(1000).vector
      if reverse then
        start,goal=goal,start
      end
      local clear,reason,report=PATHLINE.CheckDepth(start,goal,20)
      equal(clear,false)
      equal(reason,"profile_blocked")
      near(report.ClearDistance,1000/3)
      equal(report.Point.x,500)
      equal(report.Depth,10)
      equal(report.Cause,"insufficient_depth")
    end
  end)
end)

test("coincident blocked samples select the shallowest evidence in either direction",function()
  local data=terrain()
  local points={{x=0,y=-40,z=0},{x=500,y=-15,z=0},{x=500,y=-10,z=0},{x=1000,y=-40,z=0}}
  eachProfileOrder(points,function(profile)
    data.profile=function() return profile end
    for _,reverse in ipairs({false,true}) do
      local start,goal=node(0).vector,node(1000).vector
      if reverse then
        start,goal=goal,start
      end
      local _,_,report=PATHLINE.CheckDepth(start,goal,20)
      near(report.ClearDistance,1000/3)
      equal(report.Depth,10)
      equal(report.Point.y,-10)
    end
  end)
end)

test("coincident native goal samples are reduced before endpoint interpolation",function()
  local data=terrain()
  for _,reverse in ipairs({false,true}) do
    local start,goal=node(0).vector,node(1000).vector
    if reverse then
      start,goal=goal,start
    end
    local points={{x=start.x,y=-40,z=0},{x=goal.x,y=-40,z=0},{x=goal.x,y=-10,z=0}}
    eachProfileOrder(points,function(profile)
      data.profile=function() return profile end
      local _,_,report=PATHLINE.CheckDepth(start,goal,20)
      near(report.ClearDistance,2000/3)
      equal(report.Point.x,goal.x)
      equal(report.Depth,10)
    end)
  end
end)

test("unavailable evidence at the same distance takes precedence over a blocked sample",function()
  local data=terrain()
  local points={{x=0,y=-40,z=0},{x=500,y=-10,z=0},{x=500,z=0},{x=1000,y=-40,z=0}}
  eachProfileOrder(points,function(profile)
    data.profile=function() return profile end
    for _,reverse in ipairs({false,true}) do
      local start,goal=node(0).vector,node(1000).vector
      if reverse then
        start,goal=goal,start
      end
      local clear,reason,report=PATHLINE.CheckDepth(start,goal,20)
      equal(clear,false)
      equal(reason,"invalid_profile_height")
      equal(report.Status,"unavailable")
      near(report.ClearDistance,0)
    end
  end)
end)

test("coincident projected land and water samples retain the conservative land boundary",function()
  local data=terrain()
  data.surface=function(p)
    if p.x==500 and p.y==1 then
      return 1
    end
    return 3
  end
  local points={{x=0,y=-40,z=0},{x=500,y=-40,z=0},{x=500,y=1,z=1},{x=1000,y=-40,z=0}}
  eachProfileOrder(points,function(profile)
    data.profile=function() return profile end
    for _,reverse in ipairs({false,true}) do
      local start,goal=node(0).vector,node(1000).vector
      if reverse then
        start,goal=goal,start
      end
      local _,_,report=PATHLINE.CheckDepth(start,goal,20)
      equal(report.Cause,"non_water")
      near(report.ClearDistance,0)
      equal(report.Point.z,1)
    end
  end)
end)

test("equivalent depth evidence has stable coordinates and reports independent copies",function()
  local data=terrain()
  local points={{x=0,y=-40,z=0},{x=500,y=-10,z=1},{x=500,y=-10,z=-1},{x=1000,y=-40,z=0}}
  eachProfileOrder(points,function(profile)
    data.profile=function() return profile end
    for _,reverse in ipairs({false,true}) do
      local start,goal=node(0).vector,node(1000).vector
      if reverse then
        start,goal=goal,start
      end
      local _,_,report=PATHLINE.CheckDepth(start,goal,20)
      near(report.ClearDistance,1000/3)
      equal(report.Point.z,-1)
      equal(report.Point.y,-10)
      report.Point.z=999
      for _,point in ipairs(profile) do
        assert(point.z~=999)
        equal(point.Along,nil)
        equal(point.Priority,nil)
      end
    end
  end)
end)

test("native index zero participates in detailed and fast obstruction checks",function()
  for base=0,1 do
    local data=terrain()
    local native={
      [base]={x=500,y=-10,z=0},
      [base+1]={x=1000,y=-40,z=0},
    }
    data.profile=function() return native end
    equal(ASTAR.Depth(node(0),node(1000),20),false)
    for _,reverse in ipairs({false,true}) do
      local start,goal=node(0).vector,node(1000).vector
      if reverse then
        start,goal=goal,start
      end
      local clear,reason,report=PATHLINE.CheckDepth(start,goal,20)
      equal(clear,false)
      equal(reason,"profile_blocked")
      near(report.ClearDistance,1000/3)
      equal(report.Point.x,500)
      equal(report.Depth,10)
    end
    equal(native[base].x,500)
    equal(native[base].Along,nil)
    equal(native[base+2],nil)
  end
end)

test("a singleton at native index zero remains an obstruction before fallback",function()
  local data=terrain()
  data.profile=function() return {[0]={x=25,y=-10,z=0}} end
  equal(ASTAR.Depth(node(0),node(100),20),false)
  local clear,reason,report=PATHLINE.CheckDepth(node(0).vector,node(100).vector,20)
  equal(clear,false)
  equal(reason,"profile_blocked")
  near(report.ClearDistance,50/3)
  equal(report.Point.x,25)
end)

test("two native points starting at zero do not invoke short-profile fallback",function()
  local data=terrain()
  data.profile=function(a,b)
    return {[0]={x=a.x,y=-40,z=a.z},[1]={x=b.x,y=-40,z=b.z}}
  end
  equal(ASTAR.Depth(node(0),node(100001),20),true)
  equal(PATHLINE.CheckDepth(node(0).vector,node(100001).vector,20),true)
  near(ASTAR.CostDepth(node(0),node(100001),20,0,30,2),100001)
end)

test("synchronous readers reject malformed native index ranges",function()
  local data=terrain()
  local point={x=500,y=-40,z=0}
  local cases={
    {[-1]=point,[0]=point,[1]=point},
    {[0]=point,[2]=point},
    {[1]=point,[3]=point},
    {[0]=point,[0.5]=point,[1]=point},
    {[0]=point,[1]=point,n=2},
    {[math.huge]=point},
    {[9007199254740992]=point},
  }
  for _,native in ipairs(cases) do
    data.profile=function() return native end
    equal(ASTAR.Depth(node(0),node(1000),20),false)
    equal(ASTAR.CostDepth(node(0),node(1000),20,0,30,2),math.huge)
    local clear,reason,report=PATHLINE.CheckDepth(node(0).vector,node(1000).vector,20)
    equal(clear,false)
    equal(reason,"invalid_profile")
    equal(report.Status,"unavailable")
    equal(report.ClearDistance,0)
  end
end)

test("invalid native point zero retains position and height diagnostics",function()
  local data=terrain()
  for _,case in ipairs({
    {false,"invalid_profile_position"},
    {{x=500,y=-40},"invalid_profile_position"},
    {{x=500,y=0/0,z=0},"invalid_profile_height"},
    {{x=500,z=0},"invalid_profile_height"},
  }) do
    data.profile=function()
      return {[0]=case[1],[1]={x=1000,y=-40,z=0}}
    end
    equal(ASTAR.Depth(node(0),node(1000),20),false)
    equal(ASTAR.CostDepth(node(0),node(1000),20,0,30,2),math.huge)
    local clear,reason,report=PATHLINE.CheckDepth(node(0).vector,node(1000).vector,20)
    equal(clear,false)
    equal(reason,case[2])
    equal(report.Status,"unavailable")
    equal(report.ClearDistance,0)
  end
end)

test("depth cost integration includes the native zero support point",function()
  for base=0,1 do
    local data=terrain()
    data.profile=function()
      return {[base]={x=500,y=-20,z=0},[base+1]={x=1000,y=-40,z=0}}
    end
    local a,b=node(0),node(1000)
    near(ASTAR.CostDepth(a,b,20,0,30,2),1000+1000/3)
    near(ASTAR.CostDepth(b,a,20,0,30,2),1000+1000/3)
    data.profile=function()
      return {[base]={x=500,y=-10,z=0},[base+1]={x=1000,y=-40,z=0}}
    end
    equal(ASTAR.CostDepth(a,b,20,0,30,2),math.huge)
  end
end)

print(string.format("%d passed, %d failed",passed,failed))
if failed>0 then os.exit(1) end
