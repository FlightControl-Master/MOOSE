-- Standalone PATHLINE validation-job regressions; run from the repository root.
-- lua tests/pathline-validation.lua
-- Uses production geometry/jobs and ASTAR connections with controlled terrain/CPU dependencies.
-- Does not validate native DCS profiles, frame timing or ship motion.
local function copy(value)
  if type(value)~="table" then
    return value
  end
  local result={}
  for key,item in pairs(value) do
    result[key]=copy(item)
  end
  return setmetatable(result, getmetatable(value))
end

BASE={}
function BASE:New()
  return setmetatable({}, {__index=self})
end
function BASE:Inherit(child, parent)
  return setmetatable(copy(child), {__index=parent})
end
function BASE:T() end
function BASE:T2() end
function BASE:E() end
UTILS={}
function UTILS.VecDist2D(a, b)
  return math.sqrt((a.x-b.x)^2+(a.y-b.y)^2)
end
math.atan2=math.atan2 or function(y, x)
  return math.atan(y, x)
end

local function forbidden()
  error("Unexpected terrain, timer or controller access")
end
local forbiddenDependency=setmetatable({}, {__index=forbidden})
land,timer,TIMER,trigger,COORDINATE=forbiddenDependency,forbiddenDependency,forbiddenDependency,forbiddenDependency,forbiddenDependency
dofile("Moose Development/Moose/Core/Vector.lua")
dofile("Moose Development/Moose/Core/Pathline.lua")
dofile("Moose Development/Moose/Core/Grid.lua")
dofile("Moose Development/Moose/Core/Astar.lua")

local savedOS=os
local passed,failed=0,0
local function equal(actual, expected)
  assert(actual==expected, "expected "..tostring(expected)..", got "..tostring(actual))
end
local function near(actual, expected)
  assert(math.abs(actual-expected)<1e-8, "expected approximately "..expected..", got "..tostring(actual))
end
local function raises(fn, text)
  local ok,err=pcall(fn)
  assert(not ok, "expected an error")
  if text then
    assert(tostring(err):find(text,1,true), tostring(err))
  end
  return err
end
local function test(name, fn)
  local ok,err=pcall(fn)
  os=savedOS
  land=forbiddenDependency
  if ok then
    passed=passed+1
    print("PASS "..name)
  else
    failed=failed+1
    print("FAIL "..name..": "..tostring(err))
  end
end
local function geometry(count)
  local points={}
  for i=1,(count or 3) do
    points[i]={x=(i-1)*10, y=7, z=0}
  end
  return assert(PATHLINE.CreateGeometry(points))
end
local function clear()
  return {Status="clear"}
end
local function job(callback, options, count, evaluatorOptions)
  return PATHLINE.StartValidation(geometry(count), PATHLINE.CreateConnectionEvaluator(callback or clear, evaluatorOptions), options)
end
local unlimited={MaxWorkUnits=1000, MaxEvaluatorCalls=1000}
local function finish(handle, budget, context)
  for i=1,100 do
    local report=PATHLINE.StepValidation(handle, budget or unlimited, context)
    if report.Status~="running" then
      return report
    end
  end
  error("job did not terminate")
end
local function clock()
  local time={now=0}
  os={clock=function() return time.now end}
  return time
end

test("creation reports and cancellation have no evaluator or mission side effects", function()
  local handle,report=job(forbidden)
  equal(report.Status,"running")
  equal(report.CompletedSegments,0)
  equal(report.CheckedPrefixDistance,0)
  equal(report.Counters.WorkUnits,0)
  equal(PATHLINE.GetValidationReport(handle).Counters.EvaluatorCalls,0)
  equal(PATHLINE.CancelValidation(handle).Reason,"cancelled")
  equal(PATHLINE.StepValidation(handle).Status,"cancelled")
end)

test("resume between evaluation and commit does not repeat the callback", function()
  local calls=0
  local handle=job(function()
    calls=calls+1
    return {Status="clear",Cost=5}
  end,nil,3,{CostUnits="units"})
  local report=PATHLINE.StepValidation(handle,{MaxWorkUnits=1})
  equal(report.Status,"running")
  equal(report.Cursor.Phase,"commit")
  equal(report.CompletedSegments,0)
  equal(report.CompletedCost,0)
  equal(report.LastSlice.YieldReason,"slice_work_limit")
  report=PATHLINE.StepValidation(handle,{MaxWorkUnits=1,MaxEvaluatorCalls=0})
  equal(calls,1)
  equal(report.CompletedSegments,1)
  equal(report.CheckedPrefixDistance,10)
  equal(report.CompletedCost,5)
  report=finish(handle)
  equal(report.Status,"clear")
  equal(report.TotalCost,10)
  equal(report.Counters.WorkUnits,4)
  equal(calls,2)
  equal(report.Cursor,nil)
end)

test("small and large slices produce the same ordered results and costs", function()
  local function run(budget)
    local seen={}
    local handle=job(function(a,b,context)
      seen[#seen+1]=context.SegmentIndex
      return {Status="clear",Cost=(b.x-a.x)^2}
    end,nil,6,{CostUnits="squared meters"})
    return finish(handle,budget),seen
  end
  local a,seenA=run({MaxWorkUnits=1,MaxEvaluatorCalls=1})
  local b,seenB=run(unlimited)
  equal(a.TotalCost,500)
  equal(a.TotalCost,b.TotalCost)
  equal(a.CheckedPrefixDistance,b.CheckedPrefixDistance)
  equal(a.Counters.WorkUnits,b.Counters.WorkUnits)
  equal(table.concat(seenA,","),table.concat(seenB,","))
end)

test("slice budgets preserve zero and independently gate work and callbacks", function()
  local calls=0
  local handle=job(function()
    calls=calls+1
    return clear()
  end)
  equal(PATHLINE.StepValidation(handle,{MaxWorkUnits=0}).LastSlice.YieldReason,"slice_work_limit")
  equal(PATHLINE.StepValidation(handle,{MaxEvaluatorCalls=0}).LastSlice.YieldReason,"slice_evaluator_limit")
  equal(calls,0)
  local report=PATHLINE.StepValidation(handle,{MaxWorkUnits=100,MaxEvaluatorCalls=1})
  equal(calls,1)
  equal(report.CompletedSegments,1)
  equal(report.LastSlice.WorkUnits,2)
  equal(report.LastSlice.EvaluatorCalls,1)
  equal(report.LastSlice.YieldReason,"slice_evaluator_limit")
  equal(report.Counters.PointChecks,nil)
  equal(report.Counters.ProfileQueries,nil)
end)

test("total limits are terminal and cannot be raised by later slices", function()
  for _,case in ipairs({
    {options={MaxWorkUnits=0},reason="work_limit",calls=0},
    {options={MaxEvaluatorCalls=0},reason="evaluator_limit",calls=0},
    {options={MaxWorkUnits=1},reason="work_limit",calls=1},
    {options={MaxEvaluatorCalls=1},reason="evaluator_limit",calls=1},
  }) do
    local handle=job(clear,case.options)
    local report=finish(handle)
    equal(report.Status,"limited")
    equal(report.Reason,case.reason)
    equal(report.Counters.EvaluatorCalls,case.calls)
    equal(PATHLINE.StepValidation(handle,unlimited).Reason,case.reason)
    equal(PATHLINE.CancelValidation(handle).Status,"limited")
  end
end)

test("exact final commit at both count limits remains clear", function()
  local handle=job(clear,{MaxWorkUnits=2,MaxEvaluatorCalls=1},2)
  local report=PATHLINE.StepValidation(handle,{MaxWorkUnits=2,MaxEvaluatorCalls=1})
  equal(report.Status,"clear")
  equal(report.CompletedSegments,1)
  equal(report.Counters.WorkUnits,2)
  equal(report.TotalCost,nil)
end)

test("a total boundary takes precedence over a slice boundary", function()
  local handle=job(clear,{MaxWorkUnits=1})
  local report=PATHLINE.StepValidation(handle,{MaxWorkUnits=1})
  equal(report.Status,"limited")
  equal(report.Reason,"work_limit")
end)

test("CPU slicing measures active work and excludes idle time", function()
  local time=clock()
  local handle=job(function()
    time.now=time.now+0.02
    return clear()
  end)
  local report=PATHLINE.StepValidation(handle,{MaxCPUSeconds=0.01})
  equal(report.Status,"running")
  equal(report.CompletedSegments,0)
  equal(report.Cursor.Phase,"commit")
  equal(report.LastSlice.YieldReason,"slice_cpu_limit")
  near(report.LastSlice.CPUSeconds,0.02)
  near(report.LastSlice.CPUOverrunSeconds,0.01)
  time.now=time.now+500
  report=finish(handle)
  equal(report.Status,"clear")
  near(report.Counters.CPUSeconds,0.04)
end)

test("total CPU includes previous slices and can prevent committing a result", function()
  local time=clock()
  local handle=job(function()
    time.now=time.now+0.02
    return clear()
  end,{MaxCPUSeconds=0.03})
  equal(PATHLINE.StepValidation(handle).CompletedSegments,1)
  time.now=time.now+100
  local report=PATHLINE.StepValidation(handle)
  equal(report.Status,"limited")
  equal(report.Reason,"cpu_limit")
  equal(report.CompletedSegments,1)
  near(report.Counters.CPUSeconds,0.04)
  near(report.LastSlice.CPUOverrunSeconds,0.01)
end)

test("zero CPU budgets admit no work", function()
  clock()
  local handle=job(forbidden)
  equal(PATHLINE.StepValidation(handle,{MaxCPUSeconds=0}).LastSlice.YieldReason,"slice_cpu_limit")
  equal(PATHLINE.GetValidationReport(handle).Counters.WorkUnits,0)
  handle=job(forbidden,{MaxCPUSeconds=0})
  equal(PATHLINE.StepValidation(handle).Reason,"cpu_limit")
end)

test("a terminal callback failure remains terminal after CPU overrun", function()
  local time=clock()
  local handle=job(function()
    time.now=time.now+1
    return {Status="blocked",Reason="obstacle"}
  end,{MaxCPUSeconds=0.1})
  local report=PATHLINE.StepValidation(handle,{MaxCPUSeconds=0.05})
  equal(report.Status,"blocked")
  near(report.LastSlice.CPUOverrunSeconds,0.95)
end)

test("count budgets work without a CPU clock while explicit CPU caps fail", function()
  for _,missing in ipairs({{},false,{clock=false},{clock=function() return 0/0 end}}) do
    os=missing
    local handle=job(clear)
    local report=finish(handle)
    equal(report.Status,"clear")
    equal(report.Counters.CPUSeconds,nil)
    equal(report.LastSlice.CPUSeconds,nil)
    for _,total in ipairs({false,true}) do
      handle=job(forbidden,total and {MaxCPUSeconds=1} or nil)
      report=PATHLINE.StepValidation(handle,total and nil or {MaxCPUSeconds=1})
      equal(report.Status,"limited")
      equal(report.Reason,"cpu_clock_unavailable")
      equal(report.Counters.WorkUnits,0)
    end
  end
end)

test("losing CPU observations cannot create a fabricated cumulative time", function()
  local time=clock()
  local handle=job(clear,nil,4)
  PATHLINE.StepValidation(handle)
  os=nil
  PATHLINE.StepValidation(handle)
  time=clock()
  local report=finish(handle,{MaxCPUSeconds=1,MaxWorkUnits=100,MaxEvaluatorCalls=10})
  equal(report.Status,"clear")
  equal(report.Counters.CPUSeconds,nil)
  equal(report.LastSlice.CPUSeconds,0)
end)

test("backward clock with an active cap stops after the admitted operation", function()
  local time=clock()
  time.now=10
  local handle=job(function()
    time.now=9
    return clear()
  end)
  local report=PATHLINE.StepValidation(handle,{MaxCPUSeconds=1})
  equal(report.Reason,"cpu_clock_unavailable")
  equal(report.Counters.EvaluatorCalls,1)
  equal(report.CompletedSegments,0)
end)

test("context mismatch cancels before calling the evaluator", function()
  for _,context in ipairs({false,"older"}) do
    local handle=job(forbidden,{ContextId="current"})
    local report=PATHLINE.StepValidation(handle,nil,context or nil)
    equal(report.Status,"cancelled")
    equal(report.Reason,"context_changed")
    equal(report.ContextId,"current")
    equal(report.Counters.WorkUnits,0)
  end
end)

test("context zero works and a finished result retains its original context", function()
  local handle=job(clear,{ContextId=0},2)
  equal(finish(handle,nil,0).Status,"clear")
  local report=PATHLINE.StepValidation(handle,nil,1)
  equal(report.Status,"clear")
  equal(report.ContextId,0)
  equal(PATHLINE.CancelValidation(handle,"new_command").Status,"clear")
end)

test("cancel after evaluation discards the pending cost and prefix", function()
  local handle=job(function() return {Status="clear",Cost=8} end,nil,2,{CostUnits="units"})
  PATHLINE.StepValidation(handle,{MaxWorkUnits=1})
  local report=PATHLINE.CancelValidation(handle,"manual_stop")
  equal(report.Status,"cancelled")
  equal(report.CompletedCost,0)
  equal(report.CheckedPrefixDistance,0)
  equal(report.TotalCost,nil)
  equal(PATHLINE.CancelValidation(handle,"replacement").Reason,"manual_stop")
end)

test("cancellation inside a callback discards even a malformed returned value", function()
  local time=clock()
  local handle
  handle=job(function()
    PATHLINE.CancelValidation(handle,"manual_stop")
    time.now=time.now+0.25
    return false
  end)
  local report=PATHLINE.StepValidation(handle)
  equal(report.Status,"cancelled")
  equal(report.Reason,"manual_stop")
  equal(report.Counters.WorkUnits,1)
  equal(report.CompletedSegments,0)
  near(report.Counters.CPUSeconds,0.25)
end)

test("callback exceptions propagate unchanged and cannot replay", function()
  local exception={message="broken callback"}
  local time=clock()
  local handle=job(function()
    time.now=time.now+0.1
    error(exception)
  end)
  equal(raises(function() PATHLINE.StepValidation(handle) end),exception)
  local report=PATHLINE.GetValidationReport(handle)
  equal(report.Status,"error")
  equal(report.Reason,"evaluation_error")
  equal(report.Counters.EvaluatorCalls,1)
  near(report.Counters.CPUSeconds,0.1)
  equal(PATHLINE.StepValidation(handle).Status,"error")
end)

test("cancellation followed by an exception keeps cancellation and still raises", function()
  local handle
  handle=job(function()
    PATHLINE.CancelValidation(handle,"manual_stop")
    error("callback fault")
  end)
  raises(function() PATHLINE.StepValidation(handle) end,"callback fault")
  equal(PATHLINE.GetValidationReport(handle).Status,"cancelled")
end)

test("recursive stepping is rejected before another evaluator call", function()
  local handle
  handle=job(function()
    PATHLINE.StepValidation(handle)
    return clear()
  end)
  raises(function() PATHLINE.StepValidation(handle) end,"already being stepped")
  equal(PATHLINE.GetValidationReport(handle).Status,"error")
  equal(PATHLINE.GetValidationReport(handle).Counters.EvaluatorCalls,1)
end)

test("point-only geometry and duplicate segments retain their original meaning", function()
  local count=0
  local evaluator=PATHLINE.CreateConnectionEvaluator(function(a,b,context)
    count=count+1
    equal(a.x,b.x)
    equal(context.Length,0)
    equal(context.PointIndex,1)
    equal(context.SegmentIndex,nil)
    return {Status="clear",Cost=0}
  end,{CostUnits="units"})
  local handle=PATHLINE.StartValidation(geometry(1),evaluator)
  local report=finish(handle)
  equal(count,1)
  equal(report.CompletedSegments,0)
  equal(report.TotalCost,0)
  local seen={}
  local g=assert(PATHLINE.CreateGeometry({{x=0,y=0,z=0},{x=0,y=0,z=0},{x=1,y=0,z=0}}))
  handle=PATHLINE.StartValidation(g,PATHLINE.CreateConnectionEvaluator(function(a,b,c)
    seen[#seen+1]=c.SegmentIndex
    return clear()
  end))
  equal(finish(handle).CompletedSegments,2)
  equal(table.concat(seen,","),"1,2")
end)

test("a late unavailable connection preserves only the completed prefix and cost", function()
  local evidence={Position={x=15,z=0},Depth=0,SurfaceType=3,Source="direct",Cause="invalid_depth",RouteDistance=15}
  local handle=job(function(a,b,c)
    if c.SegmentIndex==1 then
      return {Status="clear",Cost=3}
    end
    return {Status="unavailable",Reason="depth_unavailable",Evidence=evidence}
  end,nil,3,{CostUnits="units"})
  local report=finish(handle)
  evidence.Position.x=999
  equal(report.Status,"unavailable")
  equal(report.CompletedSegments,1)
  equal(report.CompletedCost,3)
  equal(report.TotalCost,nil)
  equal(report.CheckedPrefixDistance,10)
  equal(report.Failure.SegmentIndex,2)
  equal(report.Failure.Position.x,15)
  equal(report.Failure.Depth,0)
  report.Failure.Position.x=777
  equal(PATHLINE.GetValidationReport(handle).Failure.Position.x,15)
end)

test("options callback arguments and reports are independently owned", function()
  local evaluatorOptions={CostUnits="units"}
  local startOptions={ContextId="A",MaxWorkUnits=8}
  local evaluator=PATHLINE.CreateConnectionEvaluator(function(a,b,c)
    local cost=b.x-a.x
    a.x=999
    b.x=999
    c.SegmentIndex=99
    c.EndDistance=99
    return {Status="clear",Cost=cost}
  end,evaluatorOptions)
  local g=geometry()
  local a,report=PATHLINE.StartValidation(g,evaluator,startOptions)
  local b=PATHLINE.StartValidation(g,evaluator,startOptions)
  evaluatorOptions.CostUnits="changed"
  startOptions.ContextId="B"
  startOptions.MaxWorkUnits=0
  report.Counters.WorkUnits=999
  report.Cursor.Phase="broken"
  report.Coverage.CostUnits="bad"
  equal(PATHLINE.GetValidationReport(a).Counters.WorkUnits,0)
  local result=finish(a,nil,"A")
  equal(result.CostUnits,"units")
  equal(result.TotalCost,20)
  equal(result.CheckedPrefixDistance,20)
  equal(g.Positions[1].x,0)
  equal(PATHLINE.GetValidationReport(b).CompletedSegments,0)
  equal(finish(b,nil,"A").TotalCost,20)
end)

test("cost overflow is limited and never publishes infinity", function()
  local handle=job(function() return {Status="clear",Cost=1e308} end,nil,3,{CostUnits="units"})
  local report=finish(handle)
  equal(report.Status,"limited")
  equal(report.Reason,"numeric_range")
  equal(report.CompletedCost,1e308)
  equal(report.CompletedSegments,1)
  equal(report.TotalCost,nil)
end)

test("malformed callback results become errors without committing the connection", function()
  for _,result in ipairs({false,{}, {Status="other"},{Status="blocked"},
    {Status="unavailable",Reason=false},{Status="clear",Reason="unexpected"},
    {Status="clear",Unknown=1},{Status="clear",Cost=1},
    {Status="blocked",Reason="blocked",Cost=math.huge},
    {Status="blocked",Reason=string.rep("x",129)},
    {Status="blocked",Reason="blocked",Evidence={SegmentIndex=7}},
    {Status="blocked",Reason="blocked",Evidence={Position={x=1,z=0,y=2}}},
    {Status="blocked",Reason="blocked",Evidence={Depth=0/0}},
    {Status="blocked",Reason="blocked",Evidence={Source=string.rep("x",129)}}}) do
    local handle=job(function() return result end)
    raises(function() PATHLINE.StepValidation(handle) end)
    local report=PATHLINE.GetValidationReport(handle)
    equal(report.Status,"error")
    equal(report.CompletedSegments,0)
  end
  for _,value in ipairs({false,-1,math.huge,0/0,"1"}) do
    local handle=job(function() return {Status="clear",Cost=value} end,nil,2,{CostUnits="units"})
    raises(function() PATHLINE.StepValidation(handle) end,"Cost")
  end
  local handle=job(clear,nil,2,{CostUnits="units"})
  raises(function() PATHLINE.StepValidation(handle) end,"Cost")
end)

test("invalid options budgets and handles fail before job mutation", function()
  raises(function() PATHLINE.CreateConnectionEvaluator(false) end,"Callback")
  for _,options in ipairs({false,{Unknown=1},{CostUnits=false},{CostUnits=""},{CostUnits=string.rep("x",129)}}) do
    raises(function() PATHLINE.CreateConnectionEvaluator(clear,options) end)
  end
  for _,options in ipairs({false,{Unknown=1},{ContextId=false},{ContextId=""},{ContextId=0/0},
    {MaxWorkUnits=-1},{MaxWorkUnits=1.5},{MaxEvaluatorCalls=false},{MaxCPUSeconds=math.huge},
    {MaxPointChecks=1},{MaxProfileQueries=1}}) do
    raises(function() job(clear,options) end)
  end
  local handle=job(clear)
  for _,budget in ipairs({false,{Unknown=1},{MaxWorkUnits=-1},{MaxWorkUnits=1.5},{MaxWorkUnits=0/0},
    {MaxEvaluatorCalls=false},{MaxCPUSeconds=-1},{ContextId="A"},{MaxPointChecks=1},{MaxProfileQueries=1}}) do
    raises(function() PATHLINE.StepValidation(handle,budget) end)
    equal(PATHLINE.GetValidationReport(handle).Counters.WorkUnits,0)
  end
  raises(function() PATHLINE.StepValidation(handle,nil,"unexpected") end,"ContextId")
  raises(function() PATHLINE.CancelValidation(handle,"") end,"Reason")
  equal(PATHLINE.GetValidationReport(handle).Status,"running")
  raises(function() PATHLINE.GetValidationReport({}) end,"Job")
  raises(function() PATHLINE.StartValidation({},PATHLINE.CreateConnectionEvaluator(clear)) end,"Geometry")
  raises(function() PATHLINE.StartValidation(geometry(),{}) end,"Evaluator")
  equal(finish(handle).Status,"clear")
end)

test("terminal jobs release geometry and callback captures even while handles remain", function()
  local weak=setmetatable({}, {__mode="v"})
  local function create(cancel)
    local g=geometry()
    local payload={}
    weak[1],weak[2]=g,payload
    local evaluator=PATHLINE.CreateConnectionEvaluator(function()
      assert(payload)
      return clear()
    end)
    local handle=PATHLINE.StartValidation(g,evaluator)
    if cancel then
      PATHLINE.CancelValidation(handle)
    else
      finish(handle)
    end
    return handle
  end
  for _,cancel in ipairs({false,true}) do
    local handle=create(cancel)
    collectgarbage("collect")
    collectgarbage("collect")
    equal(weak[1],nil)
    equal(weak[2],nil)
    assert(PATHLINE.GetValidationReport(handle).Status~="running")
  end
end)

test("abandoned job callback cycles can be collected under Lua 5.1", function()
  local weak=setmetatable({}, {__mode="v"})
  local function abandon()
    local handle
    handle=job(function() return PATHLINE.GetValidationReport(handle) end)
    weak[1]=handle
  end
  abandon()
  collectgarbage("collect")
  collectgarbage("collect")
  equal(weak[1],nil)
end)

test("actual ASTAR adapter preserves clear cost and rejected-rule semantics", function()
  land={SurfaceType={LAND=1,SHALLOW_WATER=2,WATER=3},getSurfaceType=function() return 3 end}
  local astar=ASTAR:New()
  local evaluator=PATHLINE.CreateConnectionEvaluator(function(a,b)
    local valid,cost,result=astar:EvaluateConnection(a,b)
    return {Status=result.Status,Reason=result.Reason,Cost=valid and cost or nil}
  end,{CostUnits="meters"})
  local handle=PATHLINE.StartValidation(geometry(),evaluator)
  local report=finish(handle)
  equal(report.Status,"clear")
  equal(report.TotalCost,20)
  astar:SetValidNeighbourFunction(function() return false end)
  handle=PATHLINE.StartValidation(geometry(),evaluator)
  report=finish(handle)
  equal(report.Status,"blocked")
  equal(report.Reason,"rule_rejected")
  equal(report.CompletedCost,0)
  equal(report.TotalCost,nil)
end)

test("a successful final commit retains clear despite a CPU overrun", function()
  local reads=0
  os={clock=function()
    reads=reads+1
    return (reads-1)*0.01
  end}
  local handle=job(clear,{MaxCPUSeconds=0.015},2)
  local report=PATHLINE.StepValidation(handle,{MaxCPUSeconds=0.015})
  equal(report.Status,"clear")
  assert(report.LastSlice.CPUOverrunSeconds>0)
end)

test("an evaluator exception still records its CPU overrun", function()
  local time=clock()
  local handle=job(function()
    time.now=time.now+0.1
    error("expensive failure")
  end)
  raises(function() PATHLINE.StepValidation(handle,{MaxCPUSeconds=0.01}) end,"expensive failure")
  local report=PATHLINE.GetValidationReport(handle)
  equal(report.Status,"error")
  near(report.LastSlice.CPUOverrunSeconds,0.09)
end)

test("a clock exception at slice cleanup clears yield state and unknown CPU", function()
  local reads=0
  os={clock=function()
    reads=reads+1
    if reads>=3 then
      error("clock failure")
    end
    return 0
  end}
  local handle=job(clear)
  raises(function() PATHLINE.StepValidation(handle,{MaxWorkUnits=1}) end,"clock failure")
  local report=PATHLINE.GetValidationReport(handle)
  equal(report.Status,"error")
  equal(report.LastSlice.YieldReason,nil)
  equal(report.Counters.CPUSeconds,nil)
end)

test("ASTAR weighted corridor adapter retains unavailable and negative profile evidence", function()
  local depth,mode,profiles=10,"normal",0
  land={SurfaceType={LAND=1,SHALLOW_WATER=2,WATER=3}}
  land.getSurfaceType=function() return 3 end
  land.getSurfaceHeightWithSeabed=function() return 0,depth end
  land.profile=function(a,b)
    profiles=profiles+1
    if mode=="unavailable" then
      return nil
    end
    return {{x=a.x,y=mode=="above_surface" and 2 or -depth,z=a.z},{x=b.x,y=-depth,z=b.z}}
  end
  local astar=ASTAR:New():SetValidNeighbourDepth(5,50):SetCostDepth(15,10)
  local evaluator=PATHLINE.CreateConnectionEvaluator(function(a,b)
    local valid,cost,result=astar:EvaluateConnection(a,b)
    local source=result.Depth
    local evidence
    if not valid and source then
      evidence={Depth=source.Depth,SurfaceType=source.SurfaceType,Cause=source.Cause,
        Source=source.Location,ProfileOffset=source.ProfileOffset}
      if source.Point then
        evidence.Position={x=source.Point.x,z=source.Point.z}
        if source.Location=="profile" then
          evidence.ProfileY=source.Point.y
        end
      end
    end
    return {Status=result.Status,Reason=result.Reason,Cost=valid and cost or nil,Evidence=evidence}
  end,{CostUnits="weighted meters"})
  local handle=PATHLINE.StartValidation(geometry(),evaluator)
  local report=PATHLINE.StepValidation(handle,{MaxWorkUnits=1})
  equal(report.CompletedCost,0)
  equal(profiles,3)
  PATHLINE.StepValidation(handle,{MaxWorkUnits=1,MaxEvaluatorCalls=0})
  equal(profiles,3)
  report=finish(handle)
  near(report.TotalCost,70)
  equal(profiles,6)
  equal(report.Counters.ProfileQueries,nil)

  depth=nil
  handle=PATHLINE.StartValidation(geometry(),evaluator)
  report=finish(handle)
  equal(report.Status,"unavailable")
  equal(report.Failure.Cause,"invalid_depth")
  equal(report.Failure.Depth,nil)
  depth=10
  mode="unavailable"
  handle=PATHLINE.StartValidation(geometry(),evaluator)
  report=finish(handle)
  equal(report.Reason,"profile_unavailable")
  equal(report.Failure.Position,nil)
  mode="above_surface"
  handle=PATHLINE.StartValidation(geometry(),evaluator)
  report=finish(handle)
  equal(report.Status,"blocked")
  equal(report.Failure.Cause,"insufficient_depth")
  equal(report.Failure.Depth,-2)
  equal(report.Failure.ProfileY,2)
end)

test("step budgets are copied before a callback can modify the caller's table", function()
  local budget={MaxWorkUnits=4,MaxEvaluatorCalls=2}
  local handle=job(function()
    budget.MaxWorkUnits=0
    budget.MaxEvaluatorCalls=0
    return clear()
  end)
  equal(PATHLINE.StepValidation(handle,budget).Status,"clear")
end)

test("opaque handles reject ordinary edits and forged handles without invoking hooks", function()
  local evaluator=PATHLINE.CreateConnectionEvaluator(clear)
  local handle=PATHLINE.StartValidation(geometry(),evaluator)
  raises(function() handle.Status="clear" end,"read-only")
  raises(function() evaluator.Callback=forbidden end,"read-only")
  local hooks=0
  local fake=setmetatable({}, {__index=function()
    hooks=hooks+1
    return true
  end})
  raises(function() PATHLINE.GetValidationReport(fake) end,"Job")
  equal(hooks,0)
  equal(finish(handle).Status,"clear")
end)

print(string.format("%d passed, %d failed",passed,failed))
if failed>0 then
  savedOS.exit(1)
end
