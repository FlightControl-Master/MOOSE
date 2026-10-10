-- Standalone PATHLINE regressions; run from the repository root with Lua 5.1 or 5.4.
-- lua tests/pathline.lua
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

print(string.format("%d passed, %d failed",passed,failed))
if failed>0 then os.exit(1) end
