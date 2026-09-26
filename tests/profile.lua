-- Standalone profile-helper regressions; run from the repository root with Lua 5.1 or 5.4.
-- lua tests/profile.lua
local function copy(value)
  if type(value)~="table" then return value end
  local result={}
  for key,item in pairs(value) do result[key]=copy(item) end
  return result
end

UTILS={DeepCopy=copy}
BASE={}
function BASE:New() return setmetatable({}, {__index=self}) end
function BASE:Inherit(child,parent) return setmetatable(copy(child), {__index=parent}) end
function BASE:E(message) self.lastError=message end
function UTILS.VecDist2D(a,b) return math.sqrt((a.x-b.x)^2+(a.y-b.y)^2) end
function UTILS.VecDist3D(a,b) return math.sqrt((a.x-b.x)^2+(a.y-b.y)^2+(a.z-b.z)^2) end

local profileResult,profileQuery,terrain
land={SurfaceType={LAND=1,SHALLOW_WATER=2,WATER=3,ROAD=4,RUNWAY=5}}
function land.profile(a,b)
  profileQuery={copy(a),copy(b)}
  return profileResult
end
function land.getSurfaceType(point) return terrain(point).surface end
function land.getHeight(point) return terrain(point).height end
function land.getSurfaceHeightWithSeabed(point)
  local sample=terrain(point)
  return sample.height,sample.depth
end

dofile("Moose Development/Moose/Core/Vector.lua")
dofile("Moose Development/Moose/Core/Pathline.lua")

local passed,failed=0,0
local function equal(actual,expected)
  assert(actual==expected,"expected "..tostring(expected)..", got "..tostring(actual))
end
local function close(actual,expected)
  assert(math.abs(actual-expected)<1e-8,"expected "..tostring(expected)..", got "..tostring(actual))
end
local function position(point,x,y,z)
  close(point.x,x) close(point.y,y) close(point.z,z)
end
local function test(name,fn)
  terrain=function() return {surface=land.SurfaceType.WATER,height=0,depth=30} end
  profileResult,profileQuery=nil,nil
  local ok,err=pcall(fn)
  if ok then passed=passed+1 print("PASS "..name)
  else failed=failed+1 print("FAIL "..name..": "..tostring(err)) end
end
local function route(samples)
  local path=PATHLINE:New("Profile test")
  for _,sample in ipairs(samples) do
    -- Route altitude is deliberately unrelated to the stored terrain depth.
    local x,z,depth,height=sample[1],sample[2],sample[3],sample[4] or 0
    path:AddPointFromVec3({x=x,y=900,z=z})
    local point=path.points[#path.points]
    point.depth=depth
    point.landHeight=height
  end
  return path
end

test("missing and empty native profiles remain unavailable",function()
  local start,goal=VECTOR:New(0,800,0),VECTOR:New(100,900,0)
  for _,empty in ipairs({false,true}) do
    profileResult=empty and {} or nil
    local profile,reason=start:GetProfile(goal)
    equal(profile,nil) equal(reason,"profile_unavailable")
    local path,pathReason=start:GetProfilePath(goal)
    equal(path,nil) equal(pathReason,"profile_unavailable")
  end
end)

test("missing profile endpoints use seabed and terrain height without changing inputs",function()
  terrain=function(point)
    if point.x==100 then return {surface=land.SurfaceType.LAND,height=30,depth=0} end
    return {surface=land.SurfaceType.WATER,height=12,depth=7}
  end
  local start,goal=VECTOR:New(0,800,0),VECTOR:New(100,900,0)
  profileResult={{x=20,y=-4,z=0},{x=80,y=17,z=0}}
  local profile=start:GetProfile(goal)
  equal(#profile,4)
  position(profile[1],0,5,0) position(profile[2],20,-4,0)
  position(profile[3],80,17,0) position(profile[4],100,30,0)
  equal(#profileResult,2)
  position(start,0,800,0) position(goal,100,900,0)
  profile[2].y=999
  equal(profileResult[1].y,-4)
end)

test("native endpoint heights are retained without duplicate endpoints",function()
  profileResult={{x=0,y=-27,z=0},{x=100,y=-19,z=0}}
  local profile=VECTOR:New(0,800,0):GetProfile(VECTOR:New(100,900,0))
  equal(#profile,2)
  position(profile[1],0,-27,0) position(profile[2],100,-19,0)
  profile[1].x=999
  equal(profileResult[1].x,0)
end)

test("profile helpers accept raw Vec3 and Vec2 destinations",function()
  local start=VECTOR:New(0,800,0)
  profileResult={{x=0,y=-30,z=0},{x=100,y=-20,z=40}}
  local goal3={x=100,y=700,z=40}
  local path=start:GetProfilePath(goal3)
  equal(path:GetNumberOfPoints(),2)
  position(path:GetPoint3DFromIndex(2),100,-20,40)
  equal(path:GetPointFromIndex(2).depth,30)
  equal(goal3.y,700)
  local goal2={x=100,y=40}
  local profile=start:GetProfile(goal2)
  equal(#profile,2)
  equal(profileQuery[2].x,100) equal(profileQuery[2].z,40)
  equal(profileQuery[2].y,0)
  equal(goal2.y,40) equal(goal2.z,nil)
end)

test("invalid endpoint terrain cannot become a fabricated profile",function()
  local start,goal=VECTOR:New(0,800,0),VECTOR:New(100,900,0)
  profileResult={{x=20,y=-20,z=0},{x=80,y=-25,z=0}}
  terrain=function() return {surface=land.SurfaceType.WATER,height=12,depth=0/0} end
  local profile,reason=start:GetProfile(goal)
  equal(profile,nil) equal(reason,"invalid_depth")
  terrain=function() return {surface=land.SurfaceType.WATER,height=math.huge,depth=20} end
  profile,reason=start:GetProfile(goal)
  equal(profile,nil) equal(reason,"invalid_surface_height")
end)

test("minimum depth returns an independent point copy",function()
  local path=route({{0,0,40},{100,0,7},{110,0,20}})
  local depth,point,reason=path:GetDepthMin()
  equal(depth,7) equal(reason,nil)
  equal(point.vec3.x,100)
  point.depth=999 point.vec3.x=999 point.vec2.x=999
  equal(path.points[2].depth,7)
  equal(path.points[2].vec3.x,100) equal(path.points[2].vec2.x,100)
end)

test("minimum depth of an empty path is unavailable",function()
  local depth,point,reason=PATHLINE:New():GetDepthMin()
  equal(depth,nil) equal(point,nil) equal(reason,"empty_path")
end)

test("minimum depth rejects incomplete or nonfinite depth data",function()
  for _,value in ipairs({{}, {depth=-1}, {depth=0/0}, {depth=math.huge}, {depth="20"}}) do
    local path=route({{0,0,30},{100,0,40}})
    path.points[2].depth=value.depth
    local depth,point,reason=path:GetDepthMin()
    equal(depth,nil) equal(point,nil) equal(reason,"invalid_depth")
  end
end)

test("first grounding point is always a VECTOR at sampled surface height",function()
  local path=route({{0,0,5,3},{100,0,30,4}})
  local point,reason=path:FindGroundingPoint(10)
  equal(getmetatable(point),VECTOR) equal(reason,nil)
  position(point,0,3,0)
  point.x=999
  position(path.points[1].vec3,0,900,0)
end)

test("grounding interpolation respects irregular spacing and water surface height",function()
  local path=route({{0,0,50,1},{10,0,40,2},{1010,500,0,6}})
  local point,reason=path:FindGroundingPoint(20)
  equal(getmetatable(point),VECTOR) equal(reason,nil)
  position(point,510,4,250)
  position(path.points[2].vec3,10,900,0)
  position(path.points[3].vec3,1010,900,500)
end)

test("draft equality identifies first and later contact",function()
  local first=route({{0,0,10,2},{100,0,30,4}}):FindGroundingPoint(10)
  position(first,0,2,0)
  local later=route({{0,0,30,2},{100,0,10,4}}):FindGroundingPoint(10)
  position(later,100,4,0)
end)

test("clear and empty paths have distinct grounding results",function()
  local point,reason=route({{0,0,30},{100,0,20}}):FindGroundingPoint(10)
  equal(point,nil) equal(reason,nil)
  point,reason=PATHLINE:New():FindGroundingPoint(10)
  equal(point,nil) equal(reason,"empty_path")
end)

test("invalid depths before contact are not reported as clear",function()
  for _,value in ipairs({{}, {depth=-1}, {depth=0/0}, {depth=math.huge}, {depth="20"}}) do
    local path=route({{0,0,30},{100,0,40},{200,0,0}})
    path.points[2].depth=value.depth
    local point,reason=path:FindGroundingPoint(10)
    equal(point,nil) equal(reason,"invalid_depth")
  end
end)

test("invalid surface height cannot produce a grounding vector",function()
  for _,value in ipairs({{}, {height=0/0}, {height=math.huge}}) do
    local path=route({{0,0,30},{100,0,5}})
    path.points[2].landHeight=value.height
    local point,reason=path:FindGroundingPoint(10)
    equal(point,nil) equal(reason,"invalid_surface_height")
  end
end)

test("confirmed first contact does not depend on later missing terrain",function()
  local path=route({{0,0,5,3},{100,0,30}})
  path.points[2].depth=nil
  local point,reason=path:FindGroundingPoint(10)
  equal(reason,nil) position(point,0,3,0)
end)

print(string.format("%d passed, %d failed",passed,failed))
if failed>0 then os.exit(1) end
