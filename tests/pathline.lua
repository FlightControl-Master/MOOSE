-- Standalone PATHLINE regressions; run from the repository root with Lua 5.1 or 5.4.
-- lua tests/pathline.lua
-- Production uses Lua 5.1 atan2; newer Lua versions expose its two-argument form as atan.
if not math.atan2 then
  math.atan2=function(y, x)
    return math.atan(y, x)
  end
end
local function copy(value)
  if type(value)~="table" then return value end
  local result={}
  for key,item in pairs(value) do result[key]=copy(item) end
  return result
end
UTILS={DeepCopy=copy}
BASE={}
function BASE:New() return setmetatable({}, {__index=self}) end
function BASE:Inherit(child,parent) return setmetatable(copy(child),{__index=parent}) end
function BASE:E(message) self.lastError=message end
local calls,live,removals,pending,counter={},{},{},{},0
function UTILS.GetMarkID() counter=counter+1 return counter end
trigger={action={}}
function trigger.action.removeMark(id)
  removals[#removals+1]=id live[id]=nil
end
TIMER={}
function TIMER:New(fn,id)
  return {Start=function(_,delay) pending[#pending+1]={fn=fn,id=id,delay=delay} end}
end
-- Exercise the actual removal helper, including its delayed-ID capture.
local source=assert(io.open("Moose Development/Moose/Utilities/Utils.lua","r"))
local utils=source:read("*a"):gsub("\r\n","\n") source:close()
assert((loadstring or load)(assert(utils:match("(function UTILS.RemoveMark%b().-\nend)"))))()
function trigger.action.lineToAll(recipient,id,a,b,color,lineType,readOnly,text)
  local record={kind="line",id=id,recipient=recipient,a=copy(a),b=copy(b),color=copy(color),lineType=lineType}
  calls[#calls+1]=record live[id]=record
end
function trigger.action.markToAll(id,text,vec,readOnly)
  assert(type(readOnly)=="boolean","DCS marker ReadOnly must be boolean")
  local record={kind="point",id=id,text=text,vec=copy(vec)}
  calls[#calls+1]=record live[id]=record
end
land={getHeight=function(v) return v.x+v.y end,
  getSurfaceType=function() return 3 end,
  getSurfaceHeightWithSeabed=function() return 0,25 end}
function UTILS.VecDist2D(a,b) return math.sqrt((a.x-b.x)^2+(a.y-b.y)^2) end
function UTILS.VecDist3D(a,b) return math.sqrt((a.x-b.x)^2+(a.y-b.y)^2+(a.z-b.z)^2) end
COORDINATE={NewFromVec3=function(_,v) return copy(v) end}
dofile("Moose Development/Moose/Core/Pathline.lua")
local defaultLand=copy(land)
local passed,failed=0,0
local function equal(a,b) assert(a==b,"expected "..tostring(b)..", got "..tostring(a)) end
local function count(t) local n=0 for _ in pairs(t) do n=n+1 end return n end
local function test(name,fn)
  calls,live,removals,pending={},{},{},{}
  land=copy(defaultLand)
  local ok,err=pcall(fn)
  if ok then passed=passed+1 print("PASS "..name)
  else failed=failed+1 print("FAIL "..name..": "..tostring(err)) end
end
local function route()
  return PATHLINE:NewFromVec3Array("Route",{{x=0,y=0,z=0},{x=3,y=0,z=4},{x=3,y=12,z=4}})
end

test("default name and empty constructors are consistent",function()
  local a=PATHLINE:New()
  equal(a:GetName(),"Unknown Path") equal(a.lid,"PATHLINE Unknown Path | ")
  equal(a:GetNumberOfPoints(),0) equal(a:GetLength(),0)
  equal(a:DrawLine(),a) equal(a:UnDrawLine(),a) equal(a:MarkPoints(),a) equal(count(live),0)
end)

test("construction from an existing instance starts a separate empty path",function()
  local a=route():DrawLine()
  local b=a:New("Second")
  equal(b:GetNumberOfPoints(),0) equal(a:GetNumberOfPoints(),3)
  b:UnDrawLine() equal(count(live),2)
  b:AddPointFromVec2({x=20,y=10}) equal(a:GetNumberOfPoints(),3)
end)

test("input positions are copied and DCS 2D and 3D axes are preserved",function()
  local input={{x=10,y=20},{x=30,y=40}}
  local a=PATHLINE:NewFromVec2Array("2D",input)
  input[1].x=999
  local p=a:GetPointFromIndex()
  equal(p.vec2.x,10) equal(p.vec3.x,10) equal(p.vec3.y,30) equal(p.vec3.z,20)
  equal(p.surfaceType,3) equal(p.landHeight,0) equal(p.depth,25)
  local v={x=1,y=99,z=0}
  a:AddPointFromVec3(v) v.y=999
  equal(a:GetPoint3DFromIndex(3).y,99) equal(a:GetPoint2DFromIndex(3).y,0)
  equal(a:AddPointFromVec2(nil),a) equal(a:AddPointFromVec3(nil),a) equal(a:GetNumberOfPoints(),3)
end)

test("all point getters return independent nested data",function()
  local a=route()
  local all=a:GetPoints() all[1].vec3.x=77 all[1].vec2.y=88 all[1].surfaceType=99
  table.remove(all,2)
  local p=a:GetPointFromIndex(1) p.vec3.x=66 p.vec2.y=66 p.landHeight=66 p.lineID=123
  a:GetPoints3D()[1].x=55 a:GetPoints2D()[1].y=55
  a:GetPoint3DFromIndex(1).x=44 a:GetPoint2DFromIndex(1).y=44
  a:GetCoordinates()[1].x=33
  equal(a:GetNumberOfPoints(),3)
  p=a:GetPointFromIndex(1)
  equal(p.vec3.x,0) equal(p.vec2.y,0) equal(p.surfaceType,3) equal(p.landHeight,0) equal(p.lineID,nil)
  equal(a:GetLength(true),5) equal(a:GetLength(),17)
end)

test("exports retain route order even when pairs traverses arrays in reverse",function()
  local a=route()
  local savedPairs=pairs
  pairs=function(t)
    if t~=a.points then return savedPairs(t) end
    local i=#t+1
    return function() i=i-1 if i>0 then return i,t[i] end end
  end
  local ok,err=pcall(function()
    for _,getter in ipairs({"GetPoints3D","GetCoordinates"}) do
      local v=a[getter](a)
      equal(v[1].x,0) equal(v[2].y,0) equal(v[3].y,12)
    end
    local v=a:GetPoints2D() equal(v[1].y,0) equal(v[2].y,4) equal(v[3].y,4)
    a:MarkPoints()
    assert(calls[1].text:find("Point #1",1,true))
  end)
  pairs=savedPairs assert(ok,err)
end)

test("invalid point indices return nil and log instead of raising type errors",function()
  local a=route()
  for _,index in ipairs({0,-1,4,1.5,"1",false,math.huge,0/0}) do
    equal(a:GetPointFromIndex(index),nil)
    equal(a:GetPoint2DFromIndex(index),nil) equal(a:GetPoint3DFromIndex(index),nil)
    assert(a.lastError)
  end
  equal(a:GetPointFromIndex().vec3.x,0)
end)

test("redrawing replaces only the route's old segments and updates styles",function()
  local a,b=route(),route()
  a:DrawLine() b:DrawLine()
  local old={a.points[1].lineID,a.points[2].lineID}
  local other={b.points[1].lineID,b.points[2].lineID}
  a:DrawLine(0,{0,1,0,0.5},2)
  equal(count(live),4)
  for _,id in ipairs(old) do equal(live[id],nil) end
  for _,id in ipairs(other) do assert(live[id]) end
  local drawing=live[a.points[1].lineID]
  equal(drawing.recipient,0) equal(drawing.lineType,2) equal(drawing.color[2],1)
  equal(drawing.a.x,0) equal(drawing.b.z,4)
  a:UnDrawLine() equal(count(live),2)
  equal(a.points[1].lineID,nil) equal(a.points[2].lineID,nil)
  local removed=#removals a:UnDrawLine() equal(#removals,removed)
end)

test("redrawing after appending a point leaves one segment per adjacent pair",function()
  local a=route():DrawLine()
  a:AddPointFromVec3({x=10,y=12,z=4}):DrawLine()
  equal(count(live),3) equal(#removals,2)
  a:UnDrawLine() equal(count(live),0)
  local one=PATHLINE:NewFromVec2Array("One",{{x=0,y=0}})
  one:DrawLine():UnDrawLine() equal(count(live),0)
end)

test("delayed removal captures old IDs and cannot delete a subsequent drawing",function()
  local a=route():DrawLine()
  local old={a.points[1].lineID,a.points[2].lineID}
  a:UnDrawLine(5)
  equal(#pending,2) equal(a.points[1].lineID,nil)
  a:UnDrawLine(5) equal(#pending,2)
  a:DrawLine()
  local fresh={a.points[1].lineID,a.points[2].lineID}
  for _,job in ipairs(pending) do equal(job.delay,5) job.fn(job.id) end
  for _,id in ipairs(old) do equal(live[id],nil) end
  for _,id in ipairs(fresh) do assert(live[id]) end
  a:UnDrawLine() equal(count(live),0)
end)

test("point markers redraw cleanly and remain independent of line segments",function()
  local a=route():DrawLine():MarkPoints()
  equal(count(live),5)
  local old={a.points[1].markerID,a.points[2].markerID,a.points[3].markerID}
  a:MarkPoints(true) equal(count(live),5)
  for _,id in ipairs(old) do equal(live[id],nil) end
  a:MarkPoints(false) equal(count(live),2)
  for _,p in ipairs(a.points) do equal(p.markerID,nil) end
  local removed=#removals a:MarkPoints(false) equal(#removals,removed)
  a:MarkPoints():UnDrawLine() equal(count(live),3)
end)

test("database lookup returns the registered instance or nil",function()
  local a=route()
  _DATABASE={FindPathline=function(_,name) if name=="Route" then return a end end}
  equal(PATHLINE:FindByName("Route"),a) equal(PATHLINE:FindByName("Missing"),nil)
end)

-- Updates must retain ownership until a complete replacement is ready.
local updateCases={
  {method="UpdateFromVec2Array",points={{x=300,y=0},{x=400,y=0}}},
  {method="UpdateFromVec3Array",points={{x=300,y=8,z=0},{x=400,y=8,z=0}}},
}

for _,case in ipairs(updateCases) do
  test(case.method.." removes only the replaced route's drawings",function()
    local path=route():DrawLine():MarkPoints()
    local other=route():DrawLine():MarkPoints()
    local old=path.points
    local input=copy(case.points)

    equal(path[case.method](path,"Ignored name",input),path)
    equal(count(live),5)
    equal(#removals,5)
    equal(path:GetNumberOfPoints(),2)
    equal(path:GetName(),"Route")
    equal(path.lid,"PATHLINE Route | ")
    for _,point in ipairs(old) do
      equal(point.markerID,nil)
      equal(point.lineID,nil)
    end
    for _,point in ipairs(other.points) do
      assert(live[point.markerID])
    end

    input[1].x=999
    equal(path:GetPoint3DFromIndex(1).x,300)
    path:DrawLine():MarkPoints()
    equal(count(live),8)
    path[case.method](path,nil,{})
    equal(path:GetNumberOfPoints(),0)
    equal(count(live),5)
    path:UnDrawLine():MarkPoints(false)
    equal(count(live),5)
  end)

  test(case.method.." preserves the original path and drawings on a terrain error",function()
    local path=route():DrawLine():MarkPoints()
    local original=path.points
    land.getSurfaceType=function(point)
      if point.x==400 then
        error("controlled terrain failure")
      end
      return 3
    end

    local ok,err=pcall(path[case.method],path,"Ignored name",case.points)
    equal(ok,false)
    assert(tostring(err):find("controlled terrain failure",1,true))
    equal(path.points,original)
    equal(path:GetNumberOfPoints(),3)
    equal(path:GetPoint3DFromIndex(1).x,0)
    equal(count(live),5)
    equal(#removals,0)
  end)

  test(case.method.." preserves the original route when a later input is malformed",function()
    local path=route():DrawLine():MarkPoints()
    local original=path.points
    local input=copy(case.points)
    input[2].x=false

    equal(pcall(path[case.method],path,nil,input),false)
    equal(path.points,original)
    equal(count(live),5)
    equal(#removals,0)
  end)
end

test("delayed removal from a replaced route cannot remove new or unrelated drawings",function()
  local path=route():DrawLine():MarkPoints()
  local oldLines={path.points[1].lineID,path.points[2].lineID}
  path:UnDrawLine(5)
  equal(#pending,2)

  local other=route():DrawLine()
  path:UpdateFromVec3Array(nil,updateCases[2].points):DrawLine():MarkPoints()
  local freshLine=path.points[1].lineID
  local freshMarker=path.points[1].markerID
  for _,job in ipairs(pending) do
    job.fn(job.id)
  end

  equal(count(live),5)
  for _,id in ipairs(oldLines) do
    equal(live[id],nil)
  end
  assert(live[freshLine])
  assert(live[freshMarker])
  assert(live[other.points[1].lineID])
end)

test("point marking reports unavailable terrain values and retains zero measurements",function()
  local cases={
    {field="surfaceType",label="Surface Type",values={{}, {value=false}, {value="water"}, {value=0}, {value=1.5}, {value=6}, {value=math.huge}, {value=0/0}}},
    {field="landHeight",label="Height",values={{}, {value=false}, {value="0"}, {value=math.huge}, {value=0/0}}},
    {field="depth",label="Depth",values={{}, {value=false}, {value="25"}, {value=-1}, {value=math.huge}, {value=0/0}}},
  }
  for _,case in ipairs(cases) do
    for _,bad in ipairs(case.values) do
      land.getSurfaceType=function()
        if case.field=="surfaceType" then
          return bad.value
        end
        return 3
      end
      land.getSurfaceHeightWithSeabed=function()
        local height,depth=0,25
        if case.field=="landHeight" then
          height=bad.value
        elseif case.field=="depth" then
          depth=bad.value
        end
        return height,depth
      end
      local path=route():DrawLine():MarkPoints()
      local oldMarker=path.points[1].markerID
      assert(live[oldMarker].text:find(case.label.."=unavailable",1,true))
      equal(path:MarkPoints(),path)
      equal(live[oldMarker],nil)
      equal(count(live),5)
      path:MarkPoints(false):UnDrawLine()
      equal(count(live),0)
    end
  end

  land.getSurfaceType=function() return 3 end
  land.getSurfaceHeightWithSeabed=function() return 0,0 end
  local path=route():MarkPoints()
  local text=live[path.points[1].markerID].text
  assert(text:find("Height=0.0 m",1,true))
  assert(text:find("Depth=0.0 m",1,true))
end)

test("malformed raw positions fail before terrain access or path mutation",function()
  local path=route()
  local original=path.points
  local queries=0
  land.getHeight=function() queries=queries+1 return 0 end
  land.getSurfaceType=function() queries=queries+1 return 3 end
  land.getSurfaceHeightWithSeabed=function() queries=queries+1 return 0,25 end
  local badPositions={false,"position",7,{}, {y=9,z=1}, {x=7,z=1},
    {x=7,y=9,z=false}, {x=7,y=false,z=1}, {x="7",y=9,z=1},
    {x=0/0,y=9,z=1}, {x=7,y=math.huge,z=1}, {x=7,y=9,z=-math.huge}}

  for _,method in ipairs({"AddPointFromVec2","AddPointFromVec3"}) do
    for _,position in ipairs(badPositions) do
      local ok=pcall(path[method],path,position)
      equal(ok,false)
      equal(queries,0)
      equal(path.points,original)
      equal(path:GetNumberOfPoints(),3)
    end
    equal(path[method](path,nil),path)
    equal(queries,0)
  end
end)

test("invalid terrain altitude cannot create a fabricated Vec2 route position",function()
  for _,bad in ipairs({{}, {value=false}, {value="0"}, {value=math.huge}, {value=0/0}}) do
    local path=route():DrawLine():MarkPoints()
    local original=path.points
    land.getHeight=function() return bad.value end
    equal(pcall(path.UpdateFromVec2Array,path,nil,{{x=1,y=2}}),false)
    equal(path.points,original)
    equal(count(live),5)
    path:MarkPoints(false):UnDrawLine()
  end
end)

-- Pure geometry uses production functions without terrain or controller dependencies.
local function near(actual, expected, tolerance)
  assert(type(actual)=="number" and math.abs(actual-expected)<=(tolerance or 1e-9),
    "expected approximately "..tostring(expected)..", got "..tostring(actual))
end

local function vec(x, z, y)
  return {x=x, y=y or 0, z=z}
end

local function samePosition(actual, expected)
  equal(actual.x, expected.x)
  equal(actual.y, expected.y)
  equal(actual.z, expected.z)
end

local function argumentError(fn, fragment)
  local ok, message=pcall(fn)
  equal(ok, false)
  assert(tostring(message):find(fragment, 1, true), tostring(message))
end

local function geometry(points, options)
  local result, reason=PATHLINE.CreateGeometry(points, options)
  assert(result, reason)
  return result
end

test("geometry retains horizontal lengths and interpolates supplied altitude", function()
  local g=geometry({vec(0,0,2), vec(3,4,8), vec(3,10,20)})
  equal(g.PointCount, 3)
  equal(g.SegmentCount, 2)
  equal(g.TotalLength, 11)
  equal(g.Distances[2], 5)
  equal(g.Segments[2].Index, 2)
  equal(g.Segments[2].StartDistance, 5)
  equal(g.Segments[2].EndDistance, 11)
  local location=PATHLINE.GetPositionAtDistance(g, 2.5)
  samePosition(location.Position, vec(1.5,2,5))
  equal(location.DistanceFromStart, 2.5)
  equal(location.Fraction, 0.5)
  equal(location.SegmentIndex, 1)
  near(location.Heading, 53.130102354156)
  equal(location.PointIndex, nil)
end)

test("geometry headings cover cardinal and rotated directions", function()
  for _,case in ipairs({{1,0,0}, {0,1,90}, {-1,0,180}, {0,-1,270}, {1,1,45}, {-1,-1,225}}) do
    local g=geometry({vec(0,0), vec(case[1],case[2])})
    near(g.Segments[1].Heading, case[3])
    near(g.TotalLength, math.sqrt(case[1]^2+case[2]^2))
  end
end)

test("geometry duplicates retain indices and incoming courses at corners", function()
  local g=geometry({vec(0,0), vec(0,0), vec(10,0), vec(10,0), vec(10,0), vec(10,20), vec(10,20)})
  equal(g.SegmentCount, 6)
  equal(g.Segments[1].Length, 0)
  equal(g.Segments[1].Heading, nil)
  equal(g.Segments[4].Length, 0)
  local start=PATHLINE.GetPositionAtDistance(g, 0)
  equal(start.SegmentIndex, 2)
  equal(start.Fraction, 0)
  local corner=PATHLINE.GetPositionAtDistance(g, 10)
  equal(corner.SegmentIndex, 2)
  equal(corner.Fraction, 1)
  equal(corner.Heading, 0)
  local last=PATHLINE.GetPositionAtDistance(g, 30)
  equal(last.SegmentIndex, 5)
  equal(last.Fraction, 1)
  samePosition(last.Position, g.Positions[7])
  for index=3,5 do
    local turn=PATHLINE.GetTurnAtPoint(g, index)
    equal(turn.PointIndex, index)
    equal(turn.IncomingSegment, 2)
    equal(turn.OutgoingSegment, 5)
    equal(turn.SignedAngle, 90)
  end
end)

test("geometry empty and point-only routes have explicit outcomes", function()
  local result, reason, detail=PATHLINE.CreateGeometry({})
  equal(result, nil)
  equal(reason, "empty_path")
  equal(detail.PointCount, 0)
  for _,points in ipairs({{vec(7,9,3)}, {vec(7,9,3),vec(7,9,3),vec(7,9,3)}}) do
    local g=geometry(points)
    equal(g.TotalLength, 0)
    local location=PATHLINE.GetPositionAtDistance(g, 0)
    equal(location.PointIndex, 1)
    equal(location.SegmentIndex, nil)
    equal(location.Heading, nil)
    equal(location.Fraction, nil)
    local projected=PATHLINE.ProjectPosition(g, vec(10,13,900))
    samePosition(projected.Position, vec(7,9,3))
    equal(projected.DistanceToPath, 5)
    equal(projected.SignedLateralDistance, nil)
    equal(projected.Ambiguous, false)
    local turn, turnReason, missing=PATHLINE.GetTurnAtPoint(g, 1)
    equal(turn, nil)
    equal(turnReason, "no_turn")
    equal(missing.MissingIncoming, true)
    equal(missing.MissingOutgoing, true)
  end
end)

test("geometry rejects altitude-only legs with the original index", function()
  local result, reason, detail=PATHLINE.CreateGeometry({vec(0,0),vec(0,0),vec(0,0,1)})
  equal(result, nil)
  equal(reason, "vertical_segment")
  equal(detail.SegmentIndex, 2)
end)

test("geometry keeps tiny distinct legs without squared-length underflow", function()
  local g=geometry({vec(0,0),vec(1e-200,0)})
  equal(g.TotalLength, 1e-200)
  equal(g.Segments[1].Heading, 0)
  equal(PATHLINE.GetPositionAtDistance(g, 5e-201).Fraction, 0.5)
  equal(PATHLINE.ProjectPosition(g, vec(5e-201,0)).Fraction, 0.5)
end)

test("geometry rejects overflow and lost cumulative increments", function()
  for _,points in ipairs({
    {vec(-1e308,0),vec(1e308,0)},
    {vec(0,0),vec(1.3e308,1.3e308)},
    {vec(0,0),vec(1e308,0),vec(0,0)},
    {vec(0,0),vec(1e16,0),vec(1e16,1)},
  }) do
    local result, reason, detail=PATHLINE.CreateGeometry(points)
    equal(result, nil)
    equal(reason, "numeric_range")
    assert(detail.SegmentIndex)
  end
end)

test("geometry interpolates extreme finite altitudes without subtracting them", function()
  local g=geometry({vec(0,0,-1e308), vec(10,0,1e308)})
  equal(PATHLINE.GetPositionAtDistance(g, 5).Position.y, 0)
  samePosition(PATHLINE.GetPositionAtDistance(g, 0).Position, g.Positions[1])
  samePosition(PATHLINE.GetPositionAtDistance(g, 10).Position, g.Positions[2])
end)

test("geometry distance bounds fail explicitly without clamping", function()
  local g=geometry({vec(0,0),vec(10,0)})
  for _,distance in ipairs({-1, 11}) do
    local result, reason, detail=PATHLINE.GetPositionAtDistance(g, distance)
    equal(result, nil)
    equal(reason, "distance_out_of_range")
    equal(detail.Distance, distance)
    equal(detail.TotalLength, 10)
  end
  samePosition(PATHLINE.GetPositionAtDistance(g, 0).Position, g.Positions[1])
  samePosition(PATHLINE.GetPositionAtDistance(g, 10).Position, g.Positions[2])
end)

test("projection distinguishes lateral distance from endpoint distance", function()
  local g=geometry({vec(0,0,2),vec(10,0,6)})
  for _,side in ipairs({-3,3}) do
    local p=PATHLINE.ProjectPosition(g, vec(5,side,999))
    equal(p.DistanceFromStart, 5)
    equal(p.DistanceToPath, 3)
    equal(p.SignedLateralDistance, side)
    samePosition(p.Position, vec(5,0,4))
  end
  local p=PATHLINE.ProjectPosition(g, vec(15,0))
  equal(p.Fraction, 1)
  equal(p.DistanceToPath, 5)
  equal(p.SignedLateralDistance, 0)
  p=PATHLINE.ProjectPosition(g, vec(-4,3))
  equal(p.Fraction, 0)
  equal(p.DistanceToPath, 5)
  equal(p.SignedLateralDistance, 3)
end)

test("projection clips each segment to the supplied distance interval", function()
  local g=geometry({vec(0,0),vec(100,0)})
  local p=PATHLINE.ProjectPosition(g, vec(80,3), {MinDistanceFromStart=20,MaxDistanceFromStart=40})
  equal(p.DistanceFromStart, 40)
  near(p.DistanceToPath, math.sqrt(1609))
  equal(p.SignedLateralDistance, 3)
  p=PATHLINE.ProjectPosition(g, vec(0,0), {MinDistanceFromStart=20})
  equal(p.DistanceFromStart, 20)
  p=PATHLINE.ProjectPosition(g, vec(100,0), {MaxDistanceFromStart=40})
  equal(p.DistanceFromStart, 40)
  p=PATHLINE.ProjectPosition(g, vec(80,0), {MinDistanceFromStart=30,MaxDistanceFromStart=30})
  equal(p.DistanceFromStart, 30)
end)

test("projection segment and distance windows intersect before searching", function()
  local g=geometry({vec(0,0),vec(10,0),vec(10,10),vec(20,10)})
  local p=PATHLINE.ProjectPosition(g, vec(0,0), {FirstSegment=2})
  equal(p.SegmentIndex, 2)
  equal(p.DistanceFromStart, 10)
  p=PATHLINE.ProjectPosition(g, vec(20,10), {LastSegment=1})
  equal(p.SegmentIndex, 1)
  equal(p.DistanceFromStart, 10)
  local result, reason, detail=PATHLINE.ProjectPosition(g, vec(0,0), {
    FirstSegment=3,LastSegment=3,MinDistanceFromStart=0,MaxDistanceFromStart=5,
  })
  equal(result, nil)
  equal(reason, "empty_search_range")
  equal(detail.FirstSegment, 3)
  equal(detail.MaxDistanceFromStart, 5)
end)

test("projection of duplicate-only ranges retains their station", function()
  local g=geometry({vec(0,0),vec(10,0),vec(10,0),vec(10,0),vec(20,0)})
  local p=PATHLINE.ProjectPosition(g, vec(10,4), {FirstSegment=2,LastSegment=3})
  equal(p.PointIndex, 2)
  equal(p.SegmentIndex, nil)
  equal(p.Heading, nil)
  equal(p.DistanceFromStart, 10)
  equal(p.DistanceToPath, 4)
  equal(p.Ambiguous, false)
  p=PATHLINE.ProjectPosition(g, vec(10,4))
  equal(p.SegmentIndex, 1)
  equal(p.PointIndex, nil)
end)

test("hairpin projection cannot skip a restricted earlier leg", function()
  local g=geometry({vec(0,0),vec(100,0),vec(100,10),vec(0,10)})
  local query=vec(20,9)
  equal(PATHLINE.ProjectPosition(g, query).SegmentIndex, 3)
  local p=PATHLINE.ProjectPosition(g, query, {FirstSegment=1,LastSegment=1,MaxDistanceFromStart=50})
  equal(p.SegmentIndex, 1)
  equal(p.DistanceFromStart, 20)
  equal(p.DistanceToPath, 9)
  equal(p.Ambiguous, false)
end)

test("self-crossing projection returns independent tied route locations", function()
  local g=geometry({vec(-10,-10),vec(10,10),vec(-10,10),vec(10,-10)})
  local p=PATHLINE.ProjectPosition(g, vec(0,0))
  equal(p.SegmentIndex, 1)
  equal(p.Ambiguous, true)
  equal(p.Alternative.SegmentIndex, 3)
  assert(p.Alternative.DistanceFromStart>p.DistanceFromStart)
  p.Alternative.Position.x=999
  near(p.Position.x, 0)
  near(PATHLINE.ProjectPosition(g, vec(0,0)).Alternative.Position.x, 0)
  p=PATHLINE.ProjectPosition(g, vec(0,0), {FirstSegment=3})
  equal(p.SegmentIndex, 3)
  equal(p.Ambiguous, false)
end)

test("overlap and closed-route endpoints expose ambiguity", function()
  local g=geometry({vec(0,0),vec(10,0),vec(0,0)})
  local p=PATHLINE.ProjectPosition(g, vec(5,0))
  equal(p.DistanceFromStart, 5)
  equal(p.Alternative.DistanceFromStart, 15)
  equal(p.Ambiguous, true)
  p=PATHLINE.ProjectPosition(g, vec(0,0))
  equal(p.DistanceFromStart, 0)
  equal(p.Alternative.DistanceFromStart, 20)
  equal(p.Ambiguous, true)
  p=PATHLINE.ProjectPosition(g, vec(10,0))
  equal(p.Ambiguous, false)
  equal(p.Alternative, nil)
end)

test("shared vertices prefer allowed incoming legs without false ambiguity", function()
  local g=geometry({vec(0,0),vec(3,4),vec(3,10)})
  local p=PATHLINE.ProjectPosition(g, vec(3,4))
  equal(p.SegmentIndex, 1)
  equal(p.Fraction, 1)
  equal(p.Ambiguous, false)
  p=PATHLINE.ProjectPosition(g, vec(3,4), {FirstSegment=2})
  equal(p.SegmentIndex, 2)
  equal(p.Fraction, 0)
  equal(p.Ambiguous, false)
end)

test("projection ties use the true minimum rather than chained tolerances", function()
  -- Three horizontal legs approach the query in steps smaller than the tie tolerance.
  local g=geometry({vec(0,1.0000015),vec(10,1.0000015),vec(10,1.00000075),
    vec(0,1.00000075),vec(0,1),vec(10,1)})
  local p=PATHLINE.ProjectPosition(g, vec(5,0))
  equal(p.SegmentIndex, 3)
  equal(p.Alternative.SegmentIndex, 5)
  equal(p.Ambiguous, true)
  -- Reverse geometry reverses the order in which distances are encountered.
  local reverse={}
  for i=g.PointCount,1,-1 do
    reverse[#reverse+1]=g.Positions[i]
  end
  p=PATHLINE.ProjectPosition(geometry(reverse), vec(5,0))
  equal(p.SegmentIndex, 1)
  equal(p.Alternative.SegmentIndex, 3)
  equal(p.Ambiguous, true)
end)

test("turn geometry wraps signed courses and represents reversals deterministically", function()
  for _,case in ipairs({{350,10,20},{10,350,-20},{45,45,0},{0,180,180},{180,0,180}}) do
    local a,b=math.rad(case[1]),math.rad(case[2])
    local g=geometry({vec(-10*math.cos(a),-10*math.sin(a)),vec(0,0),
      vec(10*math.cos(b),10*math.sin(b))})
    local turn=PATHLINE.GetTurnAtPoint(g, 2)
    near(turn.IncomingHeading, case[1])
    near(turn.OutgoingHeading, case[2])
    near(turn.SignedAngle, case[3])
    equal(turn.IncomingSegment, 1)
    equal(turn.OutgoingSegment, 2)
  end
end)

test("turn endpoints report missing directions and never skip real corners", function()
  local g=geometry({vec(0,0),vec(10,0),vec(10,10),vec(20,10)})
  equal(PATHLINE.GetTurnAtPoint(g, 2).SignedAngle, 90)
  equal(PATHLINE.GetTurnAtPoint(g, 3).SignedAngle, -90)
  for _,index in ipairs({1,4}) do
    local result, reason, detail=PATHLINE.GetTurnAtPoint(g, index)
    equal(result, nil)
    equal(reason, "no_turn")
    equal(detail.MissingIncoming, index==1)
    equal(detail.MissingOutgoing, index==4)
  end
end)

test("geometry inputs and exported results have independent ownership", function()
  local points={vec(0,0),vec(10,0),vec(10,10)}
  points[1].metadata={value=1}
  local g=geometry(points)
  points[1].x=99
  points[2]=vec(99,99)
  equal(g.Positions[1].metadata, nil)
  local exported=PATHLINE.GetGeometryPositions(g)
  exported[1].x=88
  exported[2]=vec(88,88)
  local location=PATHLINE.GetPositionAtDistance(g, 10)
  location.Position.x=77
  local turn=PATHLINE.GetTurnAtPoint(g, 2)
  turn.Position.x=66
  local projection=PATHLINE.ProjectPosition(g, vec(5,0))
  projection.Position.x=55
  samePosition(g.Positions[1], vec(0,0))
  samePosition(g.Positions[2], vec(10,0))
  equal(PATHLINE.GetPositionAtDistance(g, 10).Position.x, 10)
  equal(PATHLINE.GetTurnAtPoint(g, 2).Position.x, 10)
  equal(PATHLINE.ProjectPosition(g, vec(5,0)).Position.x, 5)
end)

test("geometry rejects malformed arrays and raw components without conversions", function()
  local origin=vec(0,0)
  for _,input in ipairs({false,7,"positions",{[2]=origin},{[1]=origin,[3]=origin},
    {[1]=origin,label="route"},{[0]=origin},{[1.5]=origin}}) do
    argumentError(function() PATHLINE.CreateGeometry(input) end, "Positions")
  end
  for _,point in ipairs({false,{}, {x=1,y=2}, {x=1,y=2,z=false}, {x=1,y="2",z=3},
    {x=0/0,y=0,z=0}, {x=1,y=math.huge,z=0}}) do
    argumentError(function() PATHLINE.CreateGeometry({point}) end, "Positions[1]")
  end
  local calls=0
  local point=setmetatable({}, {__index=function() calls=calls+1 return 0 end})
  argumentError(function() PATHLINE.CreateGeometry({point}) end, "Positions[1]")
  equal(calls, 0)
  argumentError(function() PATHLINE.CreateGeometry(nil) end, "Positions")
end)

test("geometry point budget is configurable and never truncates input", function()
  local points={vec(0,0),vec(10,0)}
  local result, reason, detail=PATHLINE.CreateGeometry(points, {MaxPoints=1})
  equal(result, nil)
  equal(reason, "point_limit")
  equal(detail.MaxPoints, 1)
  equal(geometry(points, {MaxPoints=2}).PointCount, 2)
  local many={}
  for i=1,4097 do
    many[i]=vec(i,0)
  end
  result, reason=PATHLINE.CreateGeometry(many)
  equal(result, nil)
  equal(reason, "point_limit")
  equal(geometry(many, {MaxPoints=4097}).PointCount, 4097)
  for _,limit in ipairs({false,0,-1,1.5,math.huge,0/0,"2"}) do
    argumentError(function() PATHLINE.CreateGeometry(points, {MaxPoints=limit}) end, "MaxPoints")
  end
  argumentError(function() PATHLINE.CreateGeometry(points, {Unknown=1}) end, "Unknown")
  argumentError(function() PATHLINE.CreateGeometry(points, false) end, "Options")
end)

test("geometry query arguments reject invalid indices ranges and options", function()
  local g=geometry({vec(0,0),vec(10,0),vec(10,10)})
  for _,value in ipairs({false,"1",0/0,math.huge}) do
    argumentError(function() PATHLINE.GetPositionAtDistance(g,value) end, "Distance")
  end
  for _,index in ipairs({false,"1",0,4,1.5,0/0,math.huge}) do
    argumentError(function() PATHLINE.GetTurnAtPoint(g,index) end, "PointIndex")
  end
  for _,options in ipairs({{FirstSegment=0},{LastSegment=3},{FirstSegment=2,LastSegment=1},
    {FirstSegment=false},{LastSegment=1.5},{MinDistanceFromStart=-1},{MaxDistanceFromStart=21},
    {MinDistanceFromStart=10,MaxDistanceFromStart=5},{MaxDistanceFromStart=false},
    {MinDistanceFromStart=0/0},{Unknown=1}}) do
    argumentError(function() PATHLINE.ProjectPosition(g,vec(0,0),options) end, "Options")
  end
  argumentError(function() PATHLINE.ProjectPosition(g,{},nil) end, "Position")
  argumentError(function() PATHLINE.ProjectPosition(g,vec(0,0),false) end, "Options")
  local point=geometry({vec(0,0)})
  argumentError(function() PATHLINE.ProjectPosition(point,vec(0,0),{FirstSegment=1}) end, "FirstSegment")
  for _,query in ipairs({
    function() PATHLINE.GetGeometryPositions({}) end,
    function() PATHLINE.GetPositionAtDistance({},0) end,
    function() PATHLINE.ProjectPosition({},vec(0,0)) end,
    function() PATHLINE.GetTurnAtPoint({},1) end,
  }) do
    argumentError(query, "Geometry")
  end
end)

test("projection reports numeric failure instead of non-finite successful fields", function()
  local point=geometry({vec(-1e308,0)})
  local result, reason, detail=PATHLINE.ProjectPosition(point,vec(1e308,0))
  equal(result, nil)
  equal(reason, "numeric_range")
  equal(detail.PointIndex, 1)
  local g=geometry({vec(0,0),vec(1,1)})
  result, reason, detail=PATHLINE.ProjectPosition(g,vec(1.3e308,1.3e308))
  equal(result, nil)
  equal(reason, "numeric_range")
  equal(detail.SegmentIndex, 1)
end)

test("all geometry operations avoid terrain wrappers and mission side effects", function()
  local saved={land=land,COORDINATE=COORDINATE,BASE=BASE,TIMER=TIMER,trigger=trigger,UTILS=UTILS}
  local function forbidden()
    error("pure geometry accessed an external dependency")
  end
  local blocker=setmetatable({}, {__index=forbidden,__newindex=forbidden})
  land,COORDINATE,BASE,TIMER,trigger,UTILS=blocker,blocker,blocker,blocker,blocker,blocker
  local ok, message=pcall(function()
    local g=geometry({vec(0,0),vec(10,0),vec(10,10)})
    equal(PATHLINE.GetGeometryPositions(g)[2].x,10)
    equal(PATHLINE.GetPositionAtDistance(g,5).Position.x,5)
    equal(PATHLINE.ProjectPosition(g,vec(5,2)).DistanceToPath,2)
    equal(PATHLINE.GetTurnAtPoint(g,2).SignedAngle,90)
  end)
  land,COORDINATE,BASE,TIMER,trigger,UTILS=saved.land,saved.COORDINATE,saved.BASE,saved.TIMER,saved.trigger,saved.UTILS
  assert(ok, message)
end)

print(string.format("%d passed, %d failed",passed,failed))
if failed>0 then os.exit(1) end
