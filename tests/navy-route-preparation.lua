-- Fixed-pose production NAVYGROUP route preparation, Lua 5.1.
-- Run from the repository root: lua tests/navy-route-preparation.lua
-- Actual ASTAR/PATHLINE/NAVYGROUP methods; analytic terrain and forbidden DCS effects.
-- Assumed test footprints exercise the adapter/checks, not vessel physics or calibrated turn radii.
local Fixtures=dofile("tests/support/local-pathfinding-fixtures.lua")
local environment=Fixtures.Install()
dofile(arg and arg[1] or "Moose Development/Moose/Ops/NavyGroup.lua")
local savedOS=os
local savedClock=os.clock
local passed,failed=0,0

local function copy(value)
  if type(value)~="table" then
    return value
  end
  local result={}
  for key,item in pairs(value) do
    result[key]=copy(item)
  end
  return result
end

local function point(x,z,y)
  return {x=x,y=y or 0,z=z or 0}
end

local function equal(actual,expected)
  assert(actual==expected,"expected "..tostring(expected)..", got "..tostring(actual))
end

local function near(actual,expected)
  assert(type(actual)=="number" and math.abs(actual-expected)<1e-7,
    "expected approximately "..tostring(expected)..", got "..tostring(actual))
end

local function raises(callback,fragment)
  local ok,err=pcall(callback)
  assert(not ok,"expected an error")
  if fragment then
    assert(type(err)=="string" and err:find(fragment,1,true),tostring(err))
  end
  return err
end

local function terrain(regions,depth)
  environment.ActiveTerrain=Fixtures.Terrain({Id="r1b",Revision="test-1",Depth=depth or 30,Regions=regions or {}})
  return environment.ActiveTerrain
end

local function candidate(points,reaches,score)
  local length=0
  for index=2,#points do
    local first,last=points[index-1],points[index]
    length=length+math.sqrt((last.x-first.x)^2+(last.z-first.z)^2)
  end
  return {Positions=copy(points),Cost=length,Score=score or length,Length=length,
    ReachesGoal=reaches~=false,RemainingDistance=reaches==false and 100 or 0,
    BaseScore=score or length,LearnedPenalty=0}
end

local function input(points)
  points=points or {point(0),point(100,40),point(200)}
  return {Start=copy(points[1]),Goal=copy(points[#points]),Candidates={candidate(points)},
    Pose={Position=copy(points[1]),HeadingDeg=0,ActualSpeedMps=0,RequestedSpeedMps=2,
      Hull={Forward=2,Aft=2,Left=1,Right=1}}}
end

local function settings(extra)
  local result={Simplify=false,Depth={MinDepth=3.5,CorridorWidth=0,LongitudinalSpacing=10,
    LateralSpacing=1,MaxSectionLength=1000,MaxOffsets=65,MaxProfilePoints=4096,MaxDirectPoints=4097}}
  for key,value in pairs(extra or {}) do
    result[key]=copy(value)
  end
  return result
end

local function search(weight,width)
  local instance=ASTAR:New(GRID.Type.HEXAGON)
  instance:SetValidNeighbourDepth(3.5,width or 0)
  instance:SetCostDepth(15,weight or 1)
  return instance
end

local model={Id="analytic-event-strips",Revision="1",Calibration="assumed",
  Parameters={HalfLength=2,Width=2,PhysicsValidated=false}}

local function modeled(event,pose,parameters)
  local heading=event.OutgoingHeading or event.IncomingHeading or pose.HeadingDeg
  local radians=math.rad(heading)
  local dx=parameters.Parameters.HalfLength*math.cos(radians)
  local dz=parameters.Parameters.HalfLength*math.sin(radians)
  local position=event.Position
  return {Status="modeled",Strips={{CorridorWidth=parameters.Parameters.Width,
    Positions={point(position.x-dx,position.z-dz,position.y),point(position.x+dx,position.z+dz,position.y)}}}}
end

local function evaluators(callback,instance)
  return {Connection=NAVYGROUP.CreateRouteConnectionEvaluator(instance or search(),"depth_weighted_meters"),
    Maneuver=callback or modeled,Model=copy(model)}
end

local large={MaxWorkUnits=10000,MaxEvaluatorCalls=10000,MaxManeuverCalls=100,
  MaxPointChecks=10000,MaxProfileQueries=1000}

local function finish(job,budget,context)
  for index=1,30000 do
    local report=NAVYGROUP.StepRoutePreparation(job,budget or large,context)
    if report.Status~="running" then
      return report,index
    end
  end
  error("preparation did not terminate")
end

local function run(value,options,rules,budget)
  local job=NAVYGROUP.StartRoutePreparation(value or input(),rules or evaluators(),options or settings())
  return finish(job,budget,options and options.ContextId),job
end

local function calls()
  local counts=environment.ActiveTerrain.Calls
  return counts.Surface+counts.Depth+counts.Profile
end

local function test(name,callback)
  os=savedOS
  os.clock=savedClock
  terrain()
  environment.ForbiddenCalls,environment.DrawingCalls=0,0
  local ok,err=pcall(callback)
  os=savedOS
  os.clock=savedClock
  if ok then
    equal(environment.ForbiddenCalls,0)
    equal(environment.DrawingCalls,0)
    passed=passed+1
    print("PASS "..name)
  else
    failed=failed+1
    print("FAIL "..name..": "..tostring(err))
  end
end

test("actual production API is available and creation/report/cancel do no terrain work",function()
  assert(type(NAVYGROUP.StartRoutePreparation)=="function")
  local rules=evaluators()
  local job,initial=NAVYGROUP.StartRoutePreparation(input(),rules,settings({ContextId=0}))
  equal(initial.Status,"running")
  equal(initial.Counters.WorkUnits,0)
  equal(initial.ExecutionValidated,false)
  equal(initial.CostUnits,"depth_weighted_meters")
  equal(NAVYGROUP.GetRoutePreparationReport(job).Status,"running")
  equal(NAVYGROUP.CancelRoutePreparation(job).Status,"cancelled")
  equal(calls(),0)
  raises(function() job.changed=true end,"read-only")
end)

test("open raw route produces a traced proposal with explicit model and no execution claim",function()
  local report=run()
  equal(report.Status,"ready_under_model")
  equal(report.Proposal.CandidateIndex,1)
  equal(report.Proposal.VariantIndex,1)
  equal(report.Candidates[1].Selected,true)
  equal(report.Candidates[1].Variants[1].Connection.Status,"clear")
  equal(report.Candidates[1].Variants[1].Depth.Status,"clear")
  equal(report.Candidates[1].Variants[1].Maneuver.Status,"ready_under_model")
  equal(report.Model.Calibration,"assumed")
  equal(report.Proposal.ExecutionValidated,false)
  equal(report.ExecutionValidated,false)
  assert(report.Counters.PointChecks>0 and report.Counters.ProfileQueries>0)
end)

test("fresh connection adapter preserves original search state and evidence",function()
  terrain({{XMin=40,XMax=60,ZMin=-1,ZMax=1,Land=true}})
  local instance=search()
  local nodes=instance.nodes
  local before=instance.LastSearchResult
  local report=run(input({point(0),point(100)}),settings(),evaluators(nil,instance))
  equal(instance.nodes,nodes)
  equal(instance.LastSearchResult,before)
  equal(report.Status,"rejected")
  local native=report.Candidates[1].Variants[1].Connection.Native
  equal(native.Status,"blocked")
  equal(native.TotalCost,nil)
  equal(native.Failure.Source,"ASTAR.EvaluateConnection")
  assert(native.Failure.Position and native.Failure.SurfaceType)
end)

test("checked cheaper shortcuts preserve exact endpoints and raw mapping",function()
  local value=input()
  value.Candidates[1].Score=value.Candidates[1].Cost+37
  local report=run(value,settings({Simplify=true}))
  equal(report.Status,"ready_under_model")
  equal(report.Proposal.VariantIndex,2)
  equal(#report.Proposal.Positions,2)
  equal(report.Proposal.Positions[1].x,value.Start.x)
  equal(report.Proposal.Positions[2].x,value.Goal.x)
  equal(report.Proposal.PointMap[2],3)
  near(report.Proposal.Score,report.Proposal.Cost+37)
  equal(report.Candidates[1].Simplification.Accepted,1)
  equal(#report.Candidates[1].Variants[1].Positions,3)
end)

test("shortcut cannot cut an island and retains the feasible reference detour",function()
  terrain({{XMin=80,XMax=120,ZMin=-20,ZMax=60,Land=true}})
  local points={point(0),point(0,100),point(200,100),point(200)}
  local report=run(input(points),settings({Simplify=true}))
  equal(report.Status,"ready_under_model")
  equal(report.Proposal.VariantIndex,1)
  equal(#report.Proposal.Positions,4)
  equal(report.Candidates[1].Simplification.Accepted,0)
  assert(report.Candidates[1].Simplification.Failures>0)
  equal(report.Candidates[1].Simplification.FirstFailure.Connection.Status,"blocked")
end)

test("depth preference may decline a shortcut without rejecting the raw passage",function()
  terrain({{XMin=40,XMax=160,ZMin=-20,ZMax=20,Depth=5}})
  local value=input({point(0),point(0,100),point(200,100),point(200)})
  local report=run(value,settings({Simplify=true}),evaluators(nil,search(10)))
  equal(report.Status,"ready_under_model")
  assert(report.Candidates[1].Simplification.Reasons.cost_increase>0)
  equal(report.Candidates[1].Variants[1].Status,"ready_under_model")
end)

test("weight ten permits an only-shallow route above the hard minimum",function()
  terrain(nil,5)
  local report=run(input({point(0),point(100)}),settings(),evaluators(nil,search(10)))
  equal(report.Status,"ready_under_model")
  assert(report.Proposal.Cost>report.Proposal.Length)
  equal(report.Candidates[1].Variants[1].Depth.Status,"clear")
end)

test("dense interior corridor catches a shoal missed by ASTAR center and edges",function()
  terrain({{XMin=25,XMax=75,ZMin=12,ZMax=18,Depth=1}})
  local options=settings()
  options.Depth.CorridorWidth=50
  options.Depth.LateralSpacing=10
  local report=run(input({point(0),point(100)}),options,evaluators(nil,search(1,50)))
  equal(report.Status,"rejected")
  local variant=report.Candidates[1].Variants[1]
  equal(variant.Connection.Status,"clear")
  equal(variant.Depth.Status,"blocked")
  assert(variant.Depth.Native.Failure.ProfileOffset~=0)
  equal(variant.Maneuver.Status,"not_run")
end)

test("missing raw depth is unavailable and does not become a rejected obstacle",function()
  terrain({{XMin=40,XMax=60,ZMin=-5,ZMax=5,Missing=true}})
  local report=run(input({point(0),point(100)}))
  equal(report.Status,"unavailable")
  equal(report.Candidates[1].Variants[1].Connection.Status,"unavailable")
  equal(report.Proposal,nil)
end)

test("entry and terminal footprints are separately checked beyond the commanded polyline",function()
  terrain({{XMin=60,XMax=80,ZMin=-4,ZMax=4,Land=true}})
  local seen={}
  local function callback(event,pose,parameters)
    seen[#seen+1]=event.Kind
    if event.Kind=="terminal" then
      return {Status="modeled",Strips={{Positions={point(50),point(90)},CorridorWidth=2}}}
    end
    return modeled(event,pose,parameters)
  end
  local report=run(input({point(0),point(50)}),settings(),evaluators(callback))
  equal(report.Status,"rejected")
  equal(table.concat(seen,","),"entry,terminal")
  local variant=report.Candidates[1].Variants[1]
  equal(variant.Connection.Status,"clear")
  equal(variant.Depth.Status,"clear")
  equal(variant.Maneuver.FirstFailure.Kind,"terminal")
  equal(variant.Maneuver.FirstFailure.Native.Status,"blocked")
end)

test("maneuver strips preserve missing-data and effective width evidence",function()
  terrain({{XMin=110,XMax=140,ZMin=-5,ZMax=5,Missing=true}})
  local report=run(input({point(0),point(100)}),settings(),evaluators(function(event,pose,parameters)
    if event.Kind=="terminal" then
      return {Status="modeled",Strips={{Positions={point(100),point(150)},CorridorWidth=6}}}
    end
    return modeled(event,pose,parameters)
  end))
  equal(report.Status,"unavailable")
  local terminal=report.Candidates[1].Variants[1].Maneuver.Events[2]
  equal(terminal.Strips[1].Depth.Native.Coverage.CorridorWidth,6)
  equal(terminal.Strips[1].Depth.Status,"unavailable")
end)

test("model failure for simplified entry falls back to checked raw variant",function()
  local report=run(input(),settings({Simplify=true}),evaluators(function(event,pose,parameters)
    if event.VariantIndex==2 then
      return {Status="rejected",Reason="test_entry_not_supported"}
    end
    return modeled(event,pose,parameters)
  end))
  equal(report.Status,"ready_under_model")
  equal(report.Proposal.VariantIndex,1)
  equal(report.Candidates[1].Variants[2].Status,"rejected")
  equal(report.Candidates[1].Variants[2].Reason,"test_entry_not_supported")
end)

test("entry angles wrap around north without a turn-angle rejection cutoff",function()
  for _,example in ipairs({{350,10,20},{10,350,-20},{0,180,180}}) do
    local radians=math.rad(example[2])
    local value=input({point(0),point(100*math.cos(radians),100*math.sin(radians))})
    value.Pose.HeadingDeg=example[1]
    local report=run(value)
    equal(report.Status,"ready_under_model")
    near(report.Candidates[1].Variants[1].Maneuver.Events[1].SignedAngle,example[3])
  end
end)

test("duplicate and collinear points generate only distinct directional turns",function()
  local report=run(input({point(0),point(50),point(50),point(100),point(100,100)}))
  equal(report.Status,"ready_under_model")
  local events=report.Candidates[1].Variants[1].Maneuver.Events
  equal(#events,3)
  equal(events[2].Kind,"turn")
  equal(events[2].PointIndex,4)
  equal(events[2].IncomingSegment,3)
  equal(events[2].OutgoingSegment,4)
  equal(events[2].SignedAngle,90)
end)

test("point-only route is checked and does not fabricate a travel heading",function()
  local report=run(input({point(0)}))
  equal(report.Status,"ready_under_model")
  equal(report.Proposal.Length,0)
  local events=report.Candidates[1].Variants[1].Maneuver.Events
  equal(#events,2)
  equal(events[1].OutgoingHeading,nil)
  equal(events[2].IncomingHeading,nil)
end)

test("absent model keeps route checks and angles but cannot select a proposal",function()
  local rules={Connection=NAVYGROUP.CreateRouteConnectionEvaluator(search(),"depth_weighted_meters")}
  local report=run(input(),settings(),rules)
  equal(report.Status,"unverified")
  equal(report.Reason,"maneuver_model_missing")
  equal(report.Proposal,nil)
  equal(report.Counters.ManeuverCalls,0)
  local variant=report.Candidates[1].Variants[1]
  equal(variant.Connection.Status,"clear")
  equal(variant.Depth.Status,"clear")
  assert(variant.Maneuver.Events[1].SignedAngle~=nil)
end)

test("incomplete pose is unverified while explicit speed zero remains valid",function()
  local value=input()
  value.Pose.Hull=nil
  local report=run(value,settings(),evaluators(function() error("Incomplete pose must not call model") end))
  equal(report.Status,"unverified")
  equal(report.Reason,"maneuver_pose_incomplete")
  value.Pose.Hull=copy(input().Pose.Hull)
  value.Pose.RequestedSpeedMps=0
  equal(run(value).Status,"ready_under_model")
end)

test("exact-goal priority precedes score and stable raw/candidate tie keys",function()
  local value=input({point(0),point(200)})
  value.Candidates={candidate({point(0),point(20)},false),candidate({point(0),point(200)},true,999)}
  local report=run(value)
  equal(report.Proposal.CandidateIndex,2)
  value.Candidates={candidate({point(0),point(200)}),candidate({point(0),point(200)})}
  equal(run(value).Proposal.CandidateIndex,1)
  value=input({point(0),point(100),point(200)})
  report=run(value,settings({Simplify=true}))
  equal(#report.Candidates[1].Variants,2)
  equal(report.Proposal.VariantIndex,1)
end)

test("selection uses repriced cost plus learned/heuristic score residual",function()
  local value=input({point(0),point(100)})
  value.Candidates={candidate({point(0),point(100)},true,200),candidate({point(0),point(100)},true,110)}
  local report=run(value)
  equal(report.Proposal.CandidateIndex,2)
  near(report.Proposal.ScoreTerms.RawScore,110)
  near(report.Proposal.Score,report.Proposal.Cost+10)
end)

test("pose and candidate endpoint mismatches are distinguished without moving start reconnection",function()
  local value=input()
  value.Pose.Position.y=1
  local job,initial=NAVYGROUP.StartRoutePreparation(value,evaluators(),settings())
  equal(initial.Status,"rejected")
  equal(initial.Reason,"input_mismatch")
  equal(calls(),0)
  equal(NAVYGROUP.StepRoutePreparation(job).Status,"rejected")
  value=input()
  value.Candidates[1].Positions[#value.Candidates[1].Positions].x=201
  local report=run(value)
  equal(report.Status,"rejected")
  equal(report.Reason,"endpoint_mismatch")
  equal(calls(),0)
end)

test("caller mutations, callback mutations and exported report mutations cannot alter a job",function()
  local value=input()
  local options=settings()
  local rules=evaluators(function(event,pose,parameters)
    local result=modeled(event,pose,parameters)
    event.Position.x=9999
    pose.Position.x=9999
    parameters.Parameters.Width=9999
    return result
  end)
  local job,initial=NAVYGROUP.StartRoutePreparation(value,rules,options)
  value.Candidates[1].Positions[2].x=9999
  value.Pose.Position.x=9999
  rules.Model.Parameters.Width=9999
  options.Depth.MinDepth=9999
  initial.Pose.Position.x=9999
  local report=finish(job)
  equal(report.Status,"ready_under_model")
  equal(report.Pose.Position.x,0)
  equal(report.Model.Parameters.Width,2)
  report.Proposal.Positions[1].x=9999
  report.Candidates[1].Variants[1].Maneuver.Events[1].Strips[1].Positions[1].x=9999
  equal(NAVYGROUP.GetRoutePreparationReport(job).Proposal.Positions[1].x,0)
end)

test("one-unit slices preserve results and never repeat terrain or model queries",function()
  local first=run(input({point(0),point(40,10),point(80)}))
  local firstCalls=copy(environment.ActiveTerrain.Calls)
  terrain()
  local second=run(input({point(0),point(40,10),point(80)}),settings(),nil,
    {MaxWorkUnits=1,MaxEvaluatorCalls=1,MaxManeuverCalls=1,MaxPointChecks=1,MaxProfileQueries=1})
  equal(second.Status,first.Status)
  near(second.Proposal.Cost,first.Proposal.Cost)
  equal(second.Counters.WorkUnits,first.Counters.WorkUnits)
  equal(second.Counters.ManeuverCalls,first.Counters.ManeuverCalls)
  for field,count in pairs(firstCalls) do
    equal(environment.ActiveTerrain.Calls[field],count)
  end
end)

test("zero slice work admits nothing and a pending callback commit needs zero callback budget",function()
  local job=NAVYGROUP.StartRoutePreparation(input({point(0),point(20)}),evaluators(),settings())
  local zero=NAVYGROUP.StepRoutePreparation(job,{MaxWorkUnits=0})
  equal(zero.Counters.WorkUnits,0)
  equal(calls(),0)
  NAVYGROUP.StepRoutePreparation(job,{MaxWorkUnits=1})
  local evaluated=NAVYGROUP.StepRoutePreparation(job,{MaxWorkUnits=1,MaxEvaluatorCalls=1})
  equal(evaluated.Counters.EvaluatorCalls,1)
  local nativeBefore=calls()
  local committed=NAVYGROUP.StepRoutePreparation(job,{MaxWorkUnits=1,MaxEvaluatorCalls=0})
  equal(committed.Candidates[1].Variants[1].Connection.Status,"clear")
  equal(calls(),nativeBefore)
  equal(committed.LastSlice.EvaluatorCalls,0)
  equal(finish(job).Status,"ready_under_model")
end)

test("shared connection limit stops subsequent stages/candidates without claiming no route",function()
  local value=input()
  value.Candidates[2]=copy(value.Candidates[1])
  local report=run(value,settings({MaxEvaluatorCalls=1}))
  equal(report.Status,"limited")
  equal(report.Reason,"evaluator_limit")
  equal(report.Counters.EvaluatorCalls,1)
  equal(report.Candidates[2].Status,"not_run")
  equal(report.Candidates[2].Reason,"evaluator_limit")
  equal(report.Proposal,nil)
end)

test("shared zero work/point/profile/model caps prevent the denied operation",function()
  for _,field in ipairs({"MaxWorkUnits","MaxPointChecks","MaxProfileQueries","MaxManeuverCalls"}) do
    terrain()
    local report=run(input({point(0),point(20)}),settings({[field]=0}))
    equal(report.Status,"limited")
    local counter=field:sub(4)
    equal(report.Counters[counter],0)
    equal(report.Proposal,nil)
  end
end)

test("optional shortcut attempt cap preserves raw and structural footprint caps stay limited",function()
  local report=run(input(),settings({Simplify=true,MaxShortcutAttempts=0}))
  equal(report.Status,"ready_under_model")
  equal(report.Candidates[1].Simplification.StopReason,"shortcut_attempt_limit")
  equal(report.Proposal.VariantIndex,1)
  report=run(input(),settings({MaxFootprintPoints=1}))
  equal(report.Status,"limited")
  equal(report.Reason,"footprint_point_limit")
  report=run(input(),settings({MaxManeuverEvents=1}))
  equal(report.Status,"limited")
  equal(report.Reason,"maneuver_event_limit")
end)

test("structural input/layout caps stop before terrain and do not coarsen settings",function()
  local job,report=NAVYGROUP.StartRoutePreparation(input(),evaluators(),settings({MaxPoints=2}))
  equal(report.Status,"limited")
  equal(report.Reason,"point_limit")
  equal(calls(),0)
  equal(NAVYGROUP.StepRoutePreparation(job).Status,"limited")
  local options=settings()
  options.Depth.CorridorWidth=50
  options.Depth.MaxOffsets=1
  job,report=NAVYGROUP.StartRoutePreparation(input(),evaluators(),options)
  equal(report.Status,"limited")
  equal(report.Reason,"offset_limit")
  equal(calls(),0)
  local value=input()
  value.Candidates[2]=copy(value.Candidates[1])
  job,report=NAVYGROUP.StartRoutePreparation(value,evaluators(),settings({MaxCandidates=1}))
  equal(report.Status,"limited")
  equal(report.InputFailure.Required,2)
  equal(calls(),0)
end)

test("stale context and manual cancellation are terminal and never schedule continuation",function()
  local job=NAVYGROUP.StartRoutePreparation(input(),evaluators(),settings({ContextId="command-1"}))
  local report=NAVYGROUP.StepRoutePreparation(job,nil,"command-2")
  equal(report.Status,"cancelled")
  equal(report.Reason,"context_changed")
  equal(calls(),0)
  equal(NAVYGROUP.StepRoutePreparation(job,nil,"command-1").Status,"cancelled")
  local nextJob=NAVYGROUP.StartRoutePreparation(input(),evaluators(),settings())
  NAVYGROUP.StepRoutePreparation(nextJob,{MaxWorkUnits=2})
  local previous=calls()
  equal(NAVYGROUP.CancelRoutePreparation(nextJob,"manual_stop").Reason,"manual_stop")
  equal(NAVYGROUP.StepRoutePreparation(nextJob).Status,"cancelled")
  equal(calls(),previous)
end)

test("callback cancellation discards its result and retains admitted work",function()
  local job
  local rules=evaluators()
  rules.Connection=PATHLINE.CreateConnectionEvaluator(function()
    NAVYGROUP.CancelRoutePreparation(job,"callback_stop")
    return {Status="clear",Cost=0}
  end,{CostUnits="test"})
  job=NAVYGROUP.StartRoutePreparation(input(),rules,settings())
  local report=finish(job)
  equal(report.Status,"cancelled")
  equal(report.Counters.EvaluatorCalls,1)
  equal(report.Candidates[1].Variants[1].Connection.Status,"cancelled")
  equal(report.Proposal,nil)
  rules=evaluators(function()
    NAVYGROUP.CancelRoutePreparation(job,"model_stop")
    return false
  end)
  job=NAVYGROUP.StartRoutePreparation(input(),rules,settings())
  report=finish(job)
  equal(report.Status,"cancelled")
  equal(report.Counters.ManeuverCalls,1)
  equal(report.Candidates[1].Variants[1].Maneuver.Events[1].Status,"cancelled")
end)

test("original exceptions including false propagate and release active jobs",function()
  for _,failure in ipairs({"native_error",false,{Original=true}}) do
    local rules=evaluators(function() error(failure,0) end)
    local job=NAVYGROUP.StartRoutePreparation(input(),rules,settings())
    local ok,err=pcall(finish,job)
    equal(ok,false)
    equal(err,failure)
    equal(NAVYGROUP.GetRoutePreparationReport(job).Status,"error")
    equal(NAVYGROUP.StepRoutePreparation(job).Status,"error")
  end
end)

test("reentrant step and malformed model results remain programming errors",function()
  local job
  local rules=evaluators(function() NAVYGROUP.StepRoutePreparation(job) end)
  job=NAVYGROUP.StartRoutePreparation(input(),rules,settings())
  raises(function() finish(job) end,"already being stepped")
  equal(NAVYGROUP.GetRoutePreparationReport(job).Status,"error")
  for _,result in ipairs({{Status="modeled",Strips={}}, {Status="modeled",Reason="bad",Strips={}},
    {Status="clear"},{Status="unavailable"},{Status="modeled",Strips={{Positions={point(0)},CorridorWidth=false}}}}) do
    job=NAVYGROUP.StartRoutePreparation(input(),evaluators(function() return result end),settings())
    raises(function() finish(job) end)
    equal(NAVYGROUP.GetRoutePreparationReport(job).Status,"error")
  end
end)

test("malformed arguments are rejected before terrain and invalid budgets preserve running state",function()
  local variants={function(v) v.Pose.ActualSpeedMps=false end,
    function(v) v.Candidates[1].Positions={[1]=point(0),[3]=point(20)} end,
    function(v) v.Candidates[1].Positions[2].x=0/0 end,
    function(v) v.Candidates[1].Score=-1 end,
    function(v) v.Candidates[1].ReachesGoal=nil end,
    function(v) v.Extra=true end}
  for _,change in ipairs(variants) do
    local value=input()
    change(value)
    raises(function() NAVYGROUP.StartRoutePreparation(value,evaluators(),settings()) end)
  end
  equal(calls(),0)
  local rules=evaluators()
  rules.Model.Parameters.Nested={}
  raises(function() NAVYGROUP.StartRoutePreparation(input(),rules,settings()) end,"invalid Model parameter")
  local job=NAVYGROUP.StartRoutePreparation(input(),evaluators(),settings())
  raises(function() NAVYGROUP.StepRoutePreparation(job,{MaxWorkUnits=false}) end)
  raises(function() NAVYGROUP.StepRoutePreparation(job,{Bogus=1}) end,"unknown Budget")
  equal(NAVYGROUP.GetRoutePreparationReport(job).Counters.WorkUnits,0)
  equal(calls(),0)
end)

test("CPU is inclusive active time and excludes long idle simulation intervals",function()
  local now=0
  os={clock=function() return now end}
  local rules=evaluators(function(event,pose,parameters)
    now=now+0.25
    return modeled(event,pose,parameters)
  end)
  local job=NAVYGROUP.StartRoutePreparation(input({point(0),point(20)}),rules,settings())
  NAVYGROUP.StepRoutePreparation(job,{MaxWorkUnits=1})
  now=now+1000
  local report=finish(job)
  near(report.Counters.CPUSeconds,0.5)
  equal(report.Counters.ManeuverCalls,2)
end)

test("CPU overrun yields cooperatively and an unavailable requested clock prevents work",function()
  local now=0
  os={clock=function() return now end}
  local job=NAVYGROUP.StartRoutePreparation(input(),evaluators(function(event,pose,parameters)
    now=now+2
    return modeled(event,pose,parameters)
  end),settings({MaxCPUSeconds=1}))
  local report=finish(job)
  equal(report.Status,"limited")
  equal(report.Reason,"cpu_limit")
  near(report.LastSlice.CPUOverrunSeconds,1)
  os={}
  job=NAVYGROUP.StartRoutePreparation(input(),evaluators(),settings({MaxCPUSeconds=0.01}))
  local before=calls()
  report=NAVYGROUP.StepRoutePreparation(job)
  equal(report.Status,"limited")
  equal(report.Reason,"cpu_clock_unavailable")
  equal(calls(),before)
  job=NAVYGROUP.StartRoutePreparation(input(),evaluators(),settings())
  report=finish(job)
  equal(report.Status,"ready_under_model")
  equal(report.Counters.CPUSeconds,nil)
end)

test("callback cancellation then error retains cancellation and the original exception",function()
  local job
  local original={Failure="model"}
  job=NAVYGROUP.StartRoutePreparation(input(),evaluators(function()
    NAVYGROUP.CancelRoutePreparation(job,"new_order")
    error(original,0)
  end),settings())
  equal(raises(function() finish(job) end),original)
  equal(NAVYGROUP.GetRoutePreparationReport(job).Status,"cancelled")
  equal(NAVYGROUP.GetRoutePreparationReport(job).Reason,"new_order")
end)

test("terminal completion/cancellation cannot rewrite a completed proposal",function()
  local report,job=run()
  equal(report.Status,"ready_under_model")
  local before=calls()
  equal(NAVYGROUP.CancelRoutePreparation(job,"late").Status,"ready_under_model")
  equal(NAVYGROUP.StepRoutePreparation(job,{MaxWorkUnits=0}).Status,"ready_under_model")
  equal(calls(),before)
  local empty=input()
  empty.Candidates={}
  equal(run(empty).Reason,"no_candidates")
end)

test("actual local ASTAR candidates feed preparation without changing their search",function()
  local instance=search()
  instance:GetGrid():SetResolution(50)
  instance:GetGrid():SetMaxCells(1000)
  instance:GetGrid():SetValidSurfaceTypes({land.SurfaceType.WATER,land.SurfaceType.SHALLOW_WATER})
  instance:SetLocalWindow(300,200,50)
  instance:StartLocalSearch(point(0),point(200),0)
  local native
  for index=1,2000 do
    local ignored
    ignored,native=instance:StepSearch(32,0.01)
    if native.Status~="running" then
      break
    end
  end
  equal(native.Status,"complete")
  equal(native.StopReason,"path_found")
  local value=input({point(0),point(200)})
  value.Candidates=native.Candidates
  local rawCount=#native.Candidates[1].Positions
  local rawCost=native.Candidates[1].Cost
  local report=run(value,settings({Simplify=true}),evaluators(nil,instance))
  equal(report.Status,"ready_under_model")
  equal(report.Proposal.ReachesGoal,true)
  equal(instance.LastSearchResult,native)
  equal(#native.Candidates[1].Positions,rawCount)
  equal(native.Candidates[1].Cost,rawCost)
  equal(report.Candidates[1].Raw.Path,nil)
end)

test("pose heading variants leave actual raw search unchanged but change entry evidence",function()
  local value=input({point(0),point(100)})
  local first=run(value)
  value.Pose.HeadingDeg=90
  local second=run(value)
  near(first.Proposal.Cost,second.Proposal.Cost)
  equal(first.Candidates[1].Raw.Positions[2].x,second.Candidates[1].Raw.Positions[2].x)
  equal(first.Candidates[1].Variants[1].Maneuver.Events[1].SignedAngle,0)
  equal(second.Candidates[1].Variants[1].Maneuver.Events[1].SignedAngle,-90)
end)

test("model widths cannot silently narrow the configured route clearance",function()
  local options=settings()
  options.Depth.CorridorWidth=10
  local report=run(input({point(0),point(100)}),options,evaluators(nil,search(1,10)))
  equal(report.Status,"ready_under_model")
  for _,event in ipairs(report.Candidates[1].Variants[1].Maneuver.Events) do
    for _,strip in ipairs(event.Strips) do
      equal(strip.CorridorWidth,10)
      equal(strip.Depth.Native.Coverage.CorridorWidth,10)
      equal(strip.Depth.Native.Coverage.MinDepth,3.5)
    end
  end
end)

test("unsupported vertical model footprint is unavailable rather than a resource limit",function()
  local report=run(input({point(0),point(100)}),settings(),evaluators(function(event)
    return {Status="modeled",Strips={{Positions={copy(event.Position),
      point(event.Position.x,event.Position.z,event.Position.y+1)},CorridorWidth=0}}}
  end))
  equal(report.Status,"unavailable")
  equal(report.Reason,"vertical_segment")
  equal(report.Proposal,nil)
end)

test("unverified maneuver result cannot be promoted to modeled success",function()
  local report=run(input(),settings(),evaluators(function()
    return {Status="unverified",Reason="calibration_missing"}
  end))
  equal(report.Status,"unverified")
  equal(report.Reason,"calibration_missing")
  equal(report.Proposal,nil)
end)

test("later blocked candidate does not replace an earlier checked candidate",function()
  terrain({{XMin=40,XMax=60,ZMin=40,ZMax=60,Land=true}})
  local value=input({point(0),point(100)})
  value.Candidates[2]=candidate({point(0),point(50,50),point(100)})
  local report=run(value)
  equal(report.Status,"ready_under_model")
  equal(report.Proposal.CandidateIndex,1)
  equal(report.Candidates[2].Status,"rejected")
end)

test("global limit after one ready candidate prevents publishing a partially evaluated winner",function()
  local value=input({point(0),point(20)})
  local first=run(value)
  value.Candidates[2]=copy(value.Candidates[1])
  local report=run(value,settings({MaxWorkUnits=first.Counters.WorkUnits-1}))
  equal(report.Status,"limited")
  equal(report.Candidates[1].Status,"ready_under_model")
  equal(report.Candidates[2].Status,"not_run")
  equal(report.Candidates[1].Selected,false)
  equal(report.Proposal,nil)
end)

test("completed final unit retains completion when work allowance is exactly consumed",function()
  local value=input({point(0),point(20)})
  local first=run(value)
  local second=run(value,settings({MaxWorkUnits=first.Counters.WorkUnits}))
  equal(second.Status,"ready_under_model")
  equal(second.Counters.WorkUnits,first.Counters.WorkUnits)
end)

test("native connection error counts one callback and retains its original exception",function()
  local original={Native=true}
  local rules=evaluators()
  rules.Connection=PATHLINE.CreateConnectionEvaluator(function() error(original,0) end,{CostUnits="test"})
  local job=NAVYGROUP.StartRoutePreparation(input(),rules,settings())
  equal(raises(function() finish(job) end),original)
  local report=NAVYGROUP.GetRoutePreparationReport(job)
  equal(report.Status,"error")
  equal(report.Counters.EvaluatorCalls,1)
  equal(report.Candidates[1].Variants[1].Connection.Native.Status,"error")
end)

test("backward and invalid CPU clocks leave uncapped counts usable and capped work unavailable",function()
  for _,reading in ipairs({-1,0/0,math.huge}) do
    local callsToClock=0
    os={clock=function()
      callsToClock=callsToClock+1
      return callsToClock==1 and 0 or reading
    end}
    local job=NAVYGROUP.StartRoutePreparation(input({point(0),point(20)}),evaluators(),settings())
    local report=finish(job)
    equal(report.Status,"ready_under_model")
    equal(report.Counters.CPUSeconds,nil)
    os={clock=function() return reading end}
    job=NAVYGROUP.StartRoutePreparation(input(),evaluators(),settings({MaxCPUSeconds=1}))
    local before=calls()
    report=finish(job)
    equal(report.Status,"limited")
    equal(report.Reason,"cpu_clock_unavailable")
    equal(calls(),before)
  end
end)

test("model exception remains primary when the final CPU reading also raises",function()
  local broken=false
  os={clock=function()
    if broken then
      error("secondary_clock_error",0)
    end
    return 0
  end}
  local job=NAVYGROUP.StartRoutePreparation(input(),evaluators(function()
    broken=true
    error(false,0)
  end),settings())
  local ok,err=pcall(finish,job)
  equal(ok,false)
  equal(err,false)
  equal(NAVYGROUP.GetRoutePreparationReport(job).Status,"error")
end)

test("repricing preserves a small prepared cost beside a very large raw score",function()
  local value=input({point(0),point(20)})
  value.Candidates[1].Cost,value.Candidates[1].Score=1e100,1e100
  local rules=evaluators()
  rules.Connection=PATHLINE.CreateConnectionEvaluator(function()
    return {Status="clear",Cost=0.5}
  end,{CostUnits="analytic-cost"})
  local report=run(value,settings(),rules)
  equal(report.Status,"ready_under_model")
  equal(report.Proposal.Cost,0.5)
  equal(report.Proposal.Score,0.5)
end)

print(string.format("%d passed, %d failed",passed,failed))
if failed>0 then
  os.exit(1)
end
