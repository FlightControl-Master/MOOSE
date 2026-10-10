-- Lua 5.1 regressions for incremental PATHLINE depth validation.
-- Run from the repository root: lua tests/pathline-depth-validation.lua
-- Production point predicates with controlled native terrain; no DCS physics claims.
math.atan2=math.atan2 or function(y,x)
  return math.atan(y,x)
end
dofile("Moose Development/Moose/Core/Vector.lua")
dofile("Moose Development/Moose/Core/Pathline.lua")
local savedOS,savedSort=os,table.sort
local passed,failed=0,0
local terrain,queries,checks
local function equal(a,b)
  assert(a==b,"expected "..tostring(b)..", got "..tostring(a))
end
local function near(a,b)
  assert(math.abs(a-b)<1e-7,"expected approximately "..tostring(b)..", got "..tostring(a))
end
local function raises(fn)
  assert(not pcall(fn),"expected an argument error")
end
local function vec(x,z,y)
  return {x=x,y=y or 0,z=z or 0}
end
local function reset()
  terrain={depth=30}
  queries,checks={},{}
  land={SurfaceType={LAND=1,SHALLOW_WATER=2,WATER=3}}
  land.profile=function(a,b)
    queries[#queries+1]={a=vec(a.x,a.z,a.y),b=vec(b.x,b.z,b.y)}
    if terrain.profile then
      return terrain.profile(a,b)
    end
    return {vec(a.x,a.z,-30),vec(b.x,b.z,-30)}
  end
  land.getSurfaceType=function(p)
    checks[#checks+1]={x=p.x,z=p.y}
    if terrain.surface then
      return terrain.surface(p)
    end
    return 3
  end
  land.getSurfaceHeightWithSeabed=function(p)
    if terrain.heights then
      return terrain.heights(p)
    end
    return 0,terrain.depth
  end
end
local function test(name,fn)
  reset()
  local ok,err=pcall(fn)
  os,table.sort=savedOS,savedSort
  if ok then
    passed=passed+1
    print("PASS "..name)
  else
    failed=failed+1
    print("FAIL "..name..": "..tostring(err))
  end
end
local function evaluator(options)
  options=options or {}
  if options.MinDepth==nil then
    options.MinDepth=5
  end
  if options.LongitudinalSpacing==nil then
    options.LongitudinalSpacing=25
  end
  return assert(PATHLINE.CreateDepthEvaluator(options))
end
local function job(options,points,limits)
  local handle=PATHLINE.StartValidation(assert(PATHLINE.CreateGeometry(points or {vec(0),vec(100)})),evaluator(options),limits)
  return handle
end
local large={MaxWorkUnits=10000,MaxPointChecks=10000,MaxProfileQueries=1000}
local function finish(handle,budget,context)
  for i=1,10000 do
    local report=PATHLINE.StepValidation(handle,budget or large,context)
    if report.Status~="running" then
      return report
    end
  end
  error("validation did not terminate")
end
local function untilPhase(handle,phase)
  for i=1,10000 do
    local report=PATHLINE.GetValidationReport(handle)
    assert(report.Status=="running",report.Reason)
    if report.Cursor.Phase==phase then
      return report
    end
    PATHLINE.StepValidation(handle,{MaxWorkUnits=1})
  end
  error("phase not reached: "..phase)
end

test("factory start query and cancellation perform no native work",function()
  local handle=job()
  local report=PATHLINE.GetValidationReport(handle)
  equal(report.EvaluatorKind,"depth")
  equal(report.Counters.PointChecks,0)
  equal(report.Counters.EvaluatorCalls,nil)
  equal(report.Coverage.OffsetCount,1)
  PATHLINE.GetValidationReport(handle)
  PATHLINE.CancelValidation(handle)
  equal(PATHLINE.StepValidation(handle).Status,"cancelled")
  equal(#checks,0)
  equal(#queries,0)
end)

test("native points plus uniform direct samples meet the requested maximum gap",function()
  local report=finish(job())
  equal(report.Status,"clear")
  equal(report.Counters.ProfileQueries,1)
  equal(report.Counters.PointChecks,7)
  equal(report.Counters.FallbackProfiles,0)
  equal(report.CheckedPrefixDistance,100)
  equal(report.TotalCost,nil)
  local positions={}
  for _,point in ipairs(checks) do
    positions[point.x]=true
  end
  for _,x in ipairs({0,25,50,75,100}) do
    assert(positions[x])
  end
end)

test("one-unit slices match large slices without repeat queries or hidden sorting",function()
  terrain.profile=function()
    return {vec(80,0,-30),vec(20,0,-30),vec(50,0,-30),vec(20,0,-30)}
  end
  table.sort=function()
    error("unbounded sort")
  end
  local first=finish(job(),{MaxWorkUnits=1,MaxPointChecks=1,MaxProfileQueries=1})
  local firstChecks=#checks
  equal(#queries,1)
  local second=finish(job())
  equal(second.Status,first.Status)
  equal(second.Counters.WorkUnits,first.Counters.WorkUnits)
  equal(second.Counters.PointChecks,first.Counters.PointChecks)
  equal(#checks,firstChecks*2)
  equal(#queries,2)
end)

test("zero and one based profiles retain every sample across work budgets",function()
  local baseline
  for _,base in ipairs({0,1}) do
    local native={}
    local positions={80,20,30,20}
    for i=#positions,1,-1 do
      native[base+i-1]=vec(positions[i],0,-30)
    end
    terrain.profile=function()
      return native
    end
    for _,budget in ipairs({{MaxWorkUnits=1,MaxPointChecks=1,MaxProfileQueries=1},
      {MaxWorkUnits=32,MaxPointChecks=4,MaxProfileQueries=1},
      {MaxWorkUnits=256,MaxPointChecks=32,MaxProfileQueries=4}}) do
      local beforePoints,beforeQueries=#checks,#queries
      local report=finish(job(),budget)
      equal(report.Status,"clear")
      equal(report.CheckedPrefixDistance,100)
      equal(report.Counters.PointChecks,9)
      equal(report.Counters.ProfileQueries,1)
      equal(report.Counters.FallbackProfiles,0)
      equal(#queries-beforeQueries,1)
      local seen={}
      for i=beforePoints+1,#checks do
        seen[checks[i].x]=(seen[checks[i].x] or 0)+1
      end
      equal(seen[80],1)
      equal(seen[20],2)
      equal(seen[30],1)
      if baseline then
        equal(report.Counters.WorkUnits,baseline.Counters.WorkUnits)
        equal(report.CompletedSegments,baseline.CompletedSegments)
      else
        baseline=report
      end
      equal(native[base].x,80)
      equal(native[base].y,-30)
      equal(native[base+4],nil)
    end
  end
end)

test("native sample zero can block a later section with identical failure evidence",function()
  terrain.profile=function(a,b)
    if a.x==0 then
      return {[0]=vec(a.x,a.z,-30),[1]=vec(b.x,b.z,-30)}
    end
    return {[0]=vec(70,0,-1),[1]=vec(b.x,b.z,-30)}
  end
  local baseline
  for _,budget in ipairs({{MaxWorkUnits=1,MaxPointChecks=1,MaxProfileQueries=1},large}) do
    local report=finish(job({MaxSectionLength=50}),budget)
    equal(report.Status,"blocked")
    equal(report.Reason,"insufficient_depth")
    equal(report.CheckedPrefixDistance,50)
    equal(report.CompletedSegments,0)
    equal(report.Failure.SectionIndex,2)
    equal(report.Failure.ProfileOffset,0)
    equal(report.Failure.Source,"profile")
    equal(report.Failure.RouteDistance,70)
    equal(report.Failure.Position.x,70)
    equal(report.Failure.Depth,1)
    equal(report.Failure.ProfileY,-1)
    equal(report.Counters.ProfileQueries,2)
    if baseline then
      equal(report.Counters.WorkUnits,baseline.Counters.WorkUnits)
      equal(report.Counters.PointChecks,baseline.Counters.PointChecks)
    else
      baseline=report
    end
  end
end)

test("a native singleton at index zero remains part of the direct fallback",function()
  local native={[0]=vec(10,0,-30)}
  terrain.profile=function()
    return native
  end
  local report=finish(job({MaxProfilePoints=1}),{MaxWorkUnits=1})
  equal(report.Status,"clear")
  equal(report.Counters.PointChecks,6)
  equal(report.Counters.FallbackProfiles,1)
  native[0].y=-1
  report=finish(job({MaxProfilePoints=1}))
  equal(report.Status,"blocked")
  equal(report.Failure.Source,"profile")
  equal(report.Failure.Position.x,10)
end)

test("zero based profile caps count entries rather than the largest index",function()
  terrain.profile=function()
    return {[0]=vec(0,0,-30),[1]=vec(50,0,-30),[2]=vec(100,0,-30)}
  end
  for _,budget in ipairs({{MaxWorkUnits=1},large}) do
    local report=finish(job({MaxProfilePoints=2}),budget)
    equal(report.Status,"limited")
    equal(report.Reason,"profile_point_limit")
    equal(report.Failure.Limit,2)
    equal(report.Failure.Required,3)
    equal(report.Counters.PointChecks,0)
    report=finish(job({MaxProfilePoints=3}),budget)
    equal(report.Status,"clear")
    equal(report.Counters.PointChecks,8)
  end
end)

test("native index base resets between sections and corridor profiles",function()
  terrain.profile=function(a,b)
    local base=#queries%2
    return {[base]=vec(a.x,a.z,-30),[base+1]=vec(b.x,b.z,-30)}
  end
  local report=finish(job({MaxSectionLength=50,CorridorWidth=20,LateralSpacing=10}),
    {MaxWorkUnits=3,MaxPointChecks=1,MaxProfileQueries=1})
  equal(report.Status,"clear")
  equal(report.CheckedPrefixDistance,100)
  equal(report.Counters.ProfileQueries,6)
  equal(report.Counters.PointChecks,30)
end)

test("interior corridor lanes find an obstacle missed by center and outer edges",function()
  terrain.heights=function(p)
    return 0,p.y==10 and 2 or 30
  end
  local report=finish(job({CorridorWidth=40,LateralSpacing=10}))
  equal(report.Status,"blocked")
  equal(report.Reason,"insufficient_depth")
  equal(report.Failure.ProfileOffset,10)
  equal(report.CheckedPrefixDistance,0)
  equal(report.Coverage.OffsetCount,5)
  equal(#queries,2)
end)

test("offset layout includes exact edges and never silently coarsens",function()
  local report=finish(job({CorridorWidth=50,LateralSpacing=10}))
  equal(report.Status,"clear")
  equal(#queries,7)
  near(report.Coverage.ActualLateralSpacing,25/3)
  for i,offset in ipairs({0,25/3,-25/3,50/3,-50/3,25,-25}) do
    near(queries[i].a.z,offset)
  end
  local result,reason,detail=PATHLINE.CreateDepthEvaluator({MinDepth=5,LongitudinalSpacing=25,CorridorWidth=50,LateralSpacing=10,MaxOffsets=6})
  equal(result,nil)
  equal(reason,"offset_limit")
  equal(detail.Required,7)
end)

test("sections commit only after all offsets and preserve prefix on later unknown data",function()
  terrain.heights=function(p)
    if p.x==100 and p.y==10 then
      return 0,nil
    end
    return 0,30
  end
  local handle=job({MaxSectionLength=50,CorridorWidth=20,LateralSpacing=10})
  untilPhase(handle,"commit_section")
  equal(PATHLINE.GetValidationReport(handle).CheckedPrefixDistance,0)
  PATHLINE.StepValidation(handle,{MaxWorkUnits=1})
  equal(PATHLINE.GetValidationReport(handle).CheckedPrefixDistance,50)
  local report=finish(handle)
  equal(report.Status,"unavailable")
  equal(report.Failure.SectionIndex,2)
  equal(report.CompletedSegments,0)
  equal(report.CheckedPrefixDistance,50)
  equal(report.Failure.Depth,nil)
end)

test("point and profile budgets apply only when that operation is next",function()
  local handle=job()
  local report=PATHLINE.StepValidation(handle,{MaxWorkUnits=100,MaxProfileQueries=0})
  equal(report.LastSlice.YieldReason,"slice_profile_query_limit")
  equal(#queries,0)
  PATHLINE.StepValidation(handle,{MaxWorkUnits=1,MaxProfileQueries=1})
  equal(#queries,1)
  report=PATHLINE.StepValidation(handle,{MaxWorkUnits=10000,MaxProfileQueries=0,MaxPointChecks=0})
  equal(report.LastSlice.YieldReason,"slice_point_limit")
  equal(#checks,0)
  report=finish(handle,{MaxWorkUnits=1000,MaxProfileQueries=0,MaxPointChecks=1})
  equal(report.Status,"clear")
  equal(#queries,1)
end)

test("per-slice counts never exceed any admitted work budget",function()
  local handle=job({CorridorWidth=40,LateralSpacing=10,MaxSectionLength=40})
  for i=1,10000 do
    local beforePoints,beforeProfiles=#checks,#queries
    local report=PATHLINE.StepValidation(handle,{MaxWorkUnits=3,MaxPointChecks=1,MaxProfileQueries=1})
    assert(report.LastSlice.WorkUnits<=3)
    equal(report.LastSlice.PointChecks,#checks-beforePoints)
    equal(report.LastSlice.ProfileQueries,#queries-beforeProfiles)
    assert(report.LastSlice.PointChecks<=1 and report.LastSlice.ProfileQueries<=1)
    if report.Status~="running" then
      equal(report.Status,"clear")
      return
    end
  end
  error("did not complete")
end)

test("total point profile and work limits terminate with retained evidence",function()
  for _,case in ipairs({{MaxPointChecks=0},{MaxProfileQueries=0},{MaxWorkUnits=1}}) do
    local report=finish(job(nil,nil,case))
    equal(report.Status,"limited")
    assert(report.Reason=="point_limit" or report.Reason=="profile_query_limit" or report.Reason=="work_limit")
    equal(report.CheckedPrefixDistance,0)
    equal(report.Failure.SegmentIndex,1)
  end
end)

test("native and direct record caps produce limits before unsafe success",function()
  local report=finish(job({MaxProfilePoints=1}))
  equal(report.Status,"limited")
  equal(report.Reason,"profile_point_limit")
  equal(report.Counters.PointChecks,0)
  report=finish(job({MaxDirectPoints=4}))
  equal(report.Reason,"direct_point_limit")
  equal(report.Counters.ProfileQueries,0)
end)

test("nil profiles are unavailable but empty and single-point arrays explicitly fall back",function()
  terrain.profile=function()
    return nil
  end
  equal(finish(job()).Reason,"profile_unavailable")
  for _,profile in ipairs({{}, {vec(50,0,-30)}}) do
    terrain.profile=function()
      return profile
    end
    local report=finish(job())
    equal(report.Status,"clear")
    equal(report.Counters.FallbackProfiles,1)
    equal(report.Counters.PointChecks,5+#profile)
  end
end)

test("malformed sparse and non-finite native data is never a fallback",function()
  local profiles={{[2]=vec(0)}, {[1]=vec(0),[3]=vec(50)}, {foo=vec(0)}, {false},
    {{x=0,y=0}}, {{x=0,y=0/0,z=0}}, {[-1]=vec(0)}, {[1.5]=vec(0)},
    {[0]=vec(0),[2]=vec(50)}, {[0]=vec(0),[1]=vec(25),[3]=vec(50)},
    {[0]=false}, {[0]={x=0,y=0}}, {[0]=vec(0,0,math.huge)}, {[0]=vec(0),n=1}}
  for _,profile in ipairs(profiles) do
    terrain.profile=function()
      return profile
    end
    local report=finish(job())
    equal(report.Status,"unavailable")
    equal(report.Reason,"invalid_profile")
    equal(report.Counters.FallbackProfiles,0)
  end
  terrain.profile=function()
    return false
  end
  equal(finish(job()).Reason,"profile_unavailable")
end)

test("minimum depth is inclusive and zero depth is a measured obstruction",function()
  terrain.depth=5
  equal(finish(job()).Status,"clear")
  terrain.depth=0
  local report=finish(job())
  equal(report.Status,"blocked")
  equal(report.Failure.Depth,0)
  equal(report.Failure.Cause,"insufficient_depth")
end)

test("unknown heights and surface types stay unavailable without invented depth",function()
  for _,depth in ipairs({false,0/0,math.huge,-1}) do
    terrain.heights=function()
      return 0,depth
    end
    local report=finish(job())
    equal(report.Status,"unavailable")
    equal(report.Failure.Depth,nil)
  end
  terrain.heights=function()
    return nil,30
  end
  equal(finish(job()).Reason,"invalid_depth")
  terrain.surface=function()
    return nil
  end
  equal(finish(job()).Reason,"invalid_surface_type")
end)

test("non-water surface is blocked even below sea level",function()
  terrain.surface=function()
    return 1
  end
  terrain.heights=function()
    error("land does not need a depth query")
  end
  local report=finish(job())
  equal(report.Status,"blocked")
  equal(report.Reason,"non_water")
  equal(report.Failure.Depth,nil)
end)

test("native profile and direct depth use the shallower evidence",function()
  terrain.profile=function()
    return {vec(0,0,-30),vec(50,0,2),vec(100,0,-30)}
  end
  local report=finish(job())
  equal(report.Status,"blocked")
  equal(report.Failure.Depth,-2)
  equal(report.Failure.ProfileY,2)
  equal(report.Failure.Source,"profile")
  equal(report.Failure.RouteDistance,50)
end)

test("equal-distance groups finish across yields and unknown outranks a shallow sample",function()
  terrain.profile=function()
    return {vec(50,0,-1),vec(50,1,-30),vec(0,0,-30)}
  end
  terrain.heights=function(p)
    if p.y==1 then
      return 0,nil
    end
    return 0,30
  end
  local report=finish(job(),{MaxWorkUnits=1,MaxPointChecks=1,MaxProfileQueries=1})
  equal(report.Status,"unavailable")
  equal(report.Failure.Position.z,1)
  equal(report.Failure.Depth,nil)
  equal(report.CheckedPrefixDistance,0)
end)

test("same-distance non-water outranks shallow and shallowest profile wins",function()
  terrain.profile=function()
    return {vec(50,0,-2),vec(50,1,-1)}
  end
  local report=finish(job())
  equal(report.Failure.Depth,1)
  terrain.surface=function(p)
    return p.y==0 and 1 or 3
  end
  report=finish(job())
  equal(report.Reason,"non_water")
end)

test("reversed rotated queries use canonical endpoints and original-direction evidence",function()
  terrain.profile=function(a,b)
    return {vec((a.x+b.x)/2,(a.z+b.z)/2,-1)}
  end
  local points={vec(60,80,900),vec(0,0,700)}
  local report=finish(job(nil,points))
  equal(report.Status,"blocked")
  equal(queries[1].a.x,0)
  equal(queries[1].b.x,60)
  equal(queries[1].a.y,0)
  near(report.Failure.RouteDistance,50)
  near(report.Failure.Position.x,30)
  near(report.Failure.Position.z,40)
end)

test("short sections keep midpoint and exact endpoints at seams",function()
  terrain.profile=function()
    return {}
  end
  local report=finish(job({MaxSectionLength=40,LongitudinalSpacing=1000}))
  equal(report.Status,"clear")
  equal(#queries,3)
  equal(#checks,9)
  equal(queries[1].a.x,0)
  equal(queries[3].b.x,100)
  near(queries[1].b.x,queries[2].a.x)
  near(queries[2].b.x,queries[3].a.x)
end)

test("isolated points and wholly duplicate routes query one position only",function()
  for _,points in ipairs({{vec(0)},{vec(0),vec(0),vec(0)}}) do
    local before=#checks
    local report=finish(job(nil,points))
    equal(report.Status,"clear")
    equal(#checks-before,1)
    equal(report.CompletedSegments,#points-1)
    equal(report.Counters.SkippedDegenerateSegments,#points-1)
    equal(#queries,0)
    report=finish(job({CorridorWidth=20,LateralSpacing=10},points))
    equal(report.Status,"unavailable")
    equal(report.Reason,"corridor_direction_unavailable")
  end
end)

test("duplicate legs retain original indices and endpoint checks",function()
  local report=finish(job(nil,{vec(0),vec(0),vec(100),vec(100)}))
  equal(report.Status,"clear")
  equal(report.CompletedSegments,3)
  equal(report.Counters.SkippedDegenerateSegments,2)
  equal(report.Counters.ProfileQueries,1)
end)

test("cancel and context change during profile processing discard all pending work",function()
  local handle=job(nil,nil,{ContextId="current"})
  PATHLINE.StepValidation(handle,{MaxWorkUnits=10},"current")
  local count=#queries
  local report=PATHLINE.StepValidation(handle,nil,"old")
  equal(report.Status,"cancelled")
  equal(report.Reason,"context_changed")
  equal(PATHLINE.StepValidation(handle).Status,"cancelled")
  equal(#queries,count)
  handle=job()
  untilPhase(handle,"sort")
  PATHLINE.CancelValidation(handle,"manual_stop")
  equal(PATHLINE.StepValidation(handle).Reason,"manual_stop")
end)

test("cancellation inside a native call discards even malformed returned data",function()
  local handle=job()
  terrain.profile=function()
    PATHLINE.CancelValidation(handle)
    return false
  end
  local report=finish(handle)
  equal(report.Status,"cancelled")
  equal(report.Counters.ProfileQueries,1)
  equal(report.Counters.PointChecks,0)
end)

test("native exceptions propagate and do not replay",function()
  local sentinel={}
  terrain.profile=function()
    error(sentinel)
  end
  local handle=job()
  local ok,err=pcall(finish,handle)
  equal(ok,false)
  equal(err,sentinel)
  equal(PATHLINE.GetValidationReport(handle).Status,"error")
  equal(PATHLINE.StepValidation(handle).Status,"error")
  equal(#queries,1)
end)

test("CPU caps observe native overruns and count limits work without a clock",function()
  local now=0
  os={clock=function()
    return now
  end}
  terrain.profile=function()
    now=now+0.2
    return {}
  end
  local handle=job()
  local report=PATHLINE.StepValidation(handle,{MaxCPUSeconds=0.01,MaxWorkUnits=100})
  equal(report.LastSlice.YieldReason,"slice_cpu_limit")
  near(report.LastSlice.CPUOverrunSeconds,0.19)
  equal(report.Counters.ProfileQueries,1)
  os=nil
  equal(finish(handle).Status,"clear")
  equal(finish(job(nil,nil,{MaxCPUSeconds=1})).Reason,"cpu_clock_unavailable")
end)

test("options are copied and mode-specific budgets reject invalid parameters",function()
  local options={MinDepth=5,LongitudinalSpacing=25,CorridorWidth=20,LateralSpacing=10}
  local eval=evaluator(options)
  options.MinDepth=99
  local g=assert(PATHLINE.CreateGeometry({vec(0),vec(100)}))
  local a,report=PATHLINE.StartValidation(g,eval)
  local b=PATHLINE.StartValidation(g,eval)
  report.Coverage.MinDepth=1000
  equal(finish(a).Status,"clear")
  equal(PATHLINE.GetValidationReport(b).Counters.WorkUnits,0)
  equal(finish(b).Status,"clear")
  raises(function()
    PATHLINE.StepValidation(job(),{MaxEvaluatorCalls=1})
  end)
  for _,bad in ipairs({{MinDepth=0},{LongitudinalSpacing=false},{MaxOffsets=0},{MaxProfilePoints=1.5},
    {MaxDirectPoints=0},{CorridorWidth=-1},{MaxSectionLength=math.huge},{LateralSpacing=0},{Weight=1}}) do
    raises(function()
      evaluator(bad)
    end)
  end
  raises(function()
    PATHLINE.CreateDepthEvaluator({MinDepth=5})
  end)
  raises(function()
    evaluator({CorridorWidth=1})
  end)
end)

test("numeric overflow fails explicitly rather than producing a coarser layout",function()
  local result,reason=PATHLINE.CreateDepthEvaluator({MinDepth=5,LongitudinalSpacing=25,CorridorWidth=1e308,LateralSpacing=1e-308})
  equal(result,nil)
  equal(reason,"numeric_range")
  local report=finish(job({MaxSectionLength=1e-308}))
  equal(report.Reason,"numeric_range")
end)

test("completed and cancelled jobs release native arrays while handles remain",function()
  local weak=setmetatable({}, {__mode="v"})
  terrain.profile=function(a,b)
    local profile={vec(a.x,a.z,-30),vec(b.x,b.z,-30)}
    weak[1]=profile
    return profile
  end
  local handle=job()
  untilPhase(handle,"collect")
  assert(weak[1])
  PATHLINE.CancelValidation(handle)
  collectgarbage("collect")
  equal(weak[1],nil)
  handle=job()
  equal(finish(handle).Status,"clear")
  collectgarbage("collect")
  equal(weak[1],nil)
end)

test("unrepresentable lateral displacement is limited instead of checking the center again",function()
  local report=finish(job({CorridorWidth=1,LateralSpacing=0.5},
    {vec(1e16,1e16),vec(1e16+100,1e16)}))
  equal(report.Status,"limited")
  equal(report.Reason,"numeric_range")
  equal(report.CheckedPrefixDistance,0)
end)

test("rotated reversed travel keeps right-hand offsets and original segment indices",function()
  terrain.profile=function()
    return {}
  end
  local report=finish(job({CorridorWidth=20,LateralSpacing=10},
    {vec(60,80),vec(60,80),vec(0,0),vec(0,0)}))
  equal(report.Status,"clear")
  equal(report.CompletedSegments,3)
  near(queries[2].a.x,8)
  near(queries[2].a.z,-6)
  near(queries[3].a.x,-8)
  near(queries[3].a.z,6)
end)

test("direct samples catch a gap that an otherwise valid native profile misses",function()
  terrain.heights=function(p)
    if p.x==25 then
      return 0,nil
    end
    return 0,30
  end
  local report=finish(job())
  equal(report.Status,"unavailable")
  equal(report.Failure.Source,"direct")
  equal(report.Failure.ProfileY,nil)
  equal(report.Failure.RouteDistance,25)
end)

test("native endpoint arguments and copied records cannot mutate pending geometry",function()
  local native={vec(50,0,-30)}
  terrain.profile=function(a,b)
    a.x,b.x=900,1000
    return native
  end
  local handle=job()
  untilPhase(handle,"generate")
  native[1].x,native[1].y=900,1000
  native[2]=false
  local report=finish(handle)
  equal(report.Status,"clear")
  equal(report.Counters.PointChecks,6)
  for _,point in ipairs(checks) do
    assert(point.x<=100)
  end
end)

test("cancellation from a point query discards its result and clears native work",function()
  local handle=job()
  terrain.surface=function()
    PATHLINE.CancelValidation(handle,"manual_stop")
    return 3
  end
  local report=finish(handle)
  equal(report.Status,"cancelled")
  equal(report.Reason,"manual_stop")
  equal(report.Counters.PointChecks,1)
  equal(report.CheckedPrefixDistance,0)
  local count=#checks
  equal(PATHLINE.StepValidation(handle).Status,"cancelled")
  equal(#checks,count)
end)

test("point exceptions and recursive steps release work and preserve the original error",function()
  local sentinel={}
  terrain.heights=function()
    error(sentinel)
  end
  local handle=job()
  local ok,err=pcall(finish,handle)
  equal(ok,false)
  equal(err,sentinel)
  equal(PATHLINE.GetValidationReport(handle).Status,"error")
  terrain.heights=function()
    PATHLINE.StepValidation(handle)
    return 0,30
  end
  handle=job()
  ok,err=pcall(finish,handle)
  equal(ok,false)
  assert(string.find(err,"already being stepped",1,true))
  equal(PATHLINE.GetValidationReport(handle).Counters.PointChecks,1)
end)

test("exact total work point and profile limits still admit the final commit",function()
  local first=finish(job())
  local caps={MaxWorkUnits=first.Counters.WorkUnits,MaxPointChecks=first.Counters.PointChecks,
    MaxProfileQueries=first.Counters.ProfileQueries}
  local report=finish(job(nil,nil,caps))
  equal(report.Status,"clear")
  equal(report.CheckedPrefixDistance,100)
  caps.MaxWorkUnits=caps.MaxWorkUnits-1
  report=finish(job(nil,nil,caps))
  equal(report.Status,"limited")
  equal(report.CheckedPrefixDistance,0)
end)

test("large native arrays yield while copying sorting and checking without requery",function()
  terrain.profile=function()
    local result={}
    for i=1,1000 do
      result[i]=vec((1001-i)/10,0,-30)
    end
    return result
  end
  local handle=job({MaxProfilePoints=1000})
  untilPhase(handle,"collect")
  local report=PATHLINE.StepValidation(handle,{MaxWorkUnits=1})
  equal(report.Cursor.Phase,"collect")
  equal(report.Counters.PointChecks,0)
  untilPhase(handle,"sort")
  report=PATHLINE.StepValidation(handle,{MaxWorkUnits=1})
  equal(report.Cursor.Phase,"sort")
  equal(report.Counters.PointChecks,0)
  report=finish(handle,{MaxWorkUnits=16,MaxPointChecks=2,MaxProfileQueries=0})
  equal(report.Status,"clear")
  equal(report.Counters.PointChecks,1005)
  equal(#queries,1)
  for i=2,#checks do
    assert(checks[i-1].x<=checks[i].x)
  end
end)

print(string.format("%d passed, %d failed",passed,failed))
if failed>0 then
  savedOS.exit(1)
end
