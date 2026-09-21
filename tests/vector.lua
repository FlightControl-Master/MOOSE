-- Standalone VECTOR regressions; run from the repository root with Lua 5.1 or 5.4:
-- lua tests/vector.lua
-- Only DCS calls are stubbed; geometry and operators use the real VECTOR implementation.
dofile("Moose Development/Moose/Core/Vector.lua")

local passed, failed=0,0
local function test(name, run)
  local ok, err=pcall(run)
  if ok then passed=passed+1 print("PASS "..name)
  else failed=failed+1 print("FAIL "..name..": "..tostring(err)) end
end
local function equal(actual, expected)
  if actual~=expected then error("expected "..tostring(expected)..", got "..tostring(actual)) end
end
local function near(actual, expected)
  assert(type(actual)=="number" and math.abs(actual-expected)<1e-9, "unexpected numeric component")
end
local function vector(v,x,y,z)
  assert(VECTOR._IsVector(v),"expected a VECTOR instance")
  near(v.x,x) near(v.y,y) near(v.z,z)
end

test("component constructors retain DCS 2D and 3D conventions", function()
  vector(VECTOR:New(10,20),10,0,20)
  vector(VECTOR:New(10,20,30),10,20,30)
  vector(VECTOR:NewFromVec({x=10,y=20}),10,0,20)
  vector(VECTOR:NewFromVec({x=10,y=20,z=0}),10,20,0)
end)

test("polar constructors use degrees and return independent vectors", function()
  for _,case in ipairs({{0,10,0},{90,0,10},{180,-10,0},{270,0,-10},{360,10,0},{-90,0,-10}}) do
    vector(VECTOR:NewFromPolar(10,case[1]),case[2],0,case[3])
  end
  vector(VECTOR:NewFromPolar(math.sqrt(2),45),1,0,1)
  vector(VECTOR:NewFromPolar(0,45),0,0,0)
  local a,b=VECTOR:NewFromPolar(5,0),VECTOR:NewFromPolar(5,0)
  assert(not rawequal(a,b)) assert(a.uid~=b.uid)
  a:SetX(99) near(b.x,5)
end)

test("spherical constructors use upward zenith and DCS heading axes", function()
  vector(VECTOR:NewFromSpherical(10,0,45),0,10,0)
  vector(VECTOR:NewFromSpherical(10,180,45),0,-10,0)
  vector(VECTOR:NewFromSpherical(10,90,0),10,0,0)
  vector(VECTOR:NewFromSpherical(10,90,90),0,0,10)
  vector(VECTOR:NewFromSpherical(10,90,180),-10,0,0)
  vector(VECTOR:NewFromSpherical(10,90,270),0,0,-10)
  vector(VECTOR:NewFromSpherical(0,40,50),0,0,0)
end)

test("spherical oblique directions retain radius and agree with horizontal polar vectors", function()
  local a=VECTOR:NewFromSpherical(4,60,45)
  vector(a,math.sqrt(6),2,math.sqrt(6)) near(a:GetLength(),4)
  for _,heading in ipairs({-90,0,30,90,180,270,360}) do
    local p=VECTOR:NewFromPolar(50,heading)
    local q=VECTOR:NewFromSpherical(50,90,heading)
    near(q:GetDistance(p),0)
  end
end)

test("constructors invoked on an instance do not return or mutate that instance", function()
  local original=VECTOR:New(1,2,3)
  vector(original:NewFromPolar(5,90),0,0,5)
  vector(original:NewFromSpherical(5,0,0),0,5,0)
  vector(original,1,2,3)
end)

test("cross product follows the component basis and preserves inputs", function()
  local x,y,z=VECTOR:New(1,0,0),VECTOR:New(0,1,0),VECTOR:New(0,0,1)
  vector(x:Rot(y),0,0,1)
  vector(y:Rot(z),1,0,0)
  vector(z:Rot(x),0,1,0)
  vector(x:Rot(z),0,-1,0)
  vector(x:Rot(x),0,0,0)
  vector(x,1,0,0) vector(y,0,1,0) vector(z,0,0,1)
end)

test("cross products are perpendicular and antisymmetric for arbitrary vectors", function()
  local a,b=VECTOR:New(2,-3,4),VECTOR:New(-5,6,7)
  local cross=a:Rot(b)
  vector(cross,-45,-34,-3)
  near(cross:Dot(a),0) near(cross:Dot(b),0)
  near((cross+b:Rot(a)):GetLength(),0)
  vector(a:Rot(a*3),0,0,0)
end)

test("cross products lift Vec2 arguments into the x-z plane", function()
  vector(VECTOR:New(1,0):Rot({x=0,y=1}),0,-1,0)
  vector(VECTOR:New(1,2,3):Rot({x=4,y=5}),10,7,-8)
  vector(VECTOR:New(1,2,3):Rot({x=4,y=5,z=6}),-3,6,-3)
end)

test("visibility passes named Vec3 fields and propagates the DCS result", function()
  local a=VECTOR:New(1,2,3)
  local b={x=4,y=5,z=6}
  for _,visible in ipairs({true,false}) do
    land={isVisible=function(from,to)
      equal(from.x,1) equal(from.y,2) equal(from.z,3)
      equal(to.x,4) equal(to.y,5) equal(to.z,6)
      equal(to[1],nil) equal(to[2],nil)
      return visible
    end}
    equal(a:IsVisible(b),visible)
    equal(a:IsVisible(VECTOR:NewFromVec(b)),visible)
  end
  equal(b.y,5) equal(b.z,6)
end)

test("wind conversion preserves all components and selects the requested API", function()
  land={getHeight=function(v) equal(v.x,100) equal(v.y,300) return 0 end}
  local a=VECTOR:New(100,200,300)
  local steady,turbulent=0,0
  local wind={x=1.5,y=-2,z=3.5}
  local function position(v) equal(v.x,100) equal(v.y,200) equal(v.z,300) end
  atmosphere={getWind=function(v) position(v) steady=steady+1 return wind end,
    getWindWithTurbulence=function(v) position(v) turbulent=turbulent+1 return {x=-4,y=5,z=0} end}
  local result=a:GetWindVector()
  vector(result,1.5,-2,3.5)
  result:SetX(99) equal(wind.x,1.5)
  vector(a:GetWindVector(false),1.5,-2,3.5)
  vector(a:GetWindVector(true),-4,5,0)
  equal(steady,2) equal(turbulent,1)
end)

test("surface names iterate the DCS enum table and handle unknown ids", function()
  land={SurfaceType={LAND=1,SHALLOW_WATER=2,WATER=3,ROAD=4,RUNWAY=5}}
  local a=VECTOR:New(10,20)
  for name,id in pairs(land.SurfaceType) do
    land.getSurfaceType=function(v) equal(v.x,10) equal(v.y,20) return id end
    equal(a:GetSurfaceTypeName(),name)
  end
  land.getSurfaceType=function() return 99 end
  equal(a:GetSurfaceTypeName(),"unknown")
end)

test("modulo supports scalar and component divisors without mutating operands", function()
  local a,b=VECTOR:New(-7,8,10),VECTOR:New(4,5,6)
  vector(a%3,2,2,1)
  vector(a%b,1,3,4)
  vector(a%-3,-1,-1,-2)
  vector(VECTOR:New(1,2)%2,1,0,0)
  vector(a,-7,8,10) vector(b,4,5,6)
end)

test("modulo rejects unsupported operands and zero divisors", function()
  local a=VECTOR:New(1,2,3)
  for _,run in ipairs({function() return a%0 end, function() return a%VECTOR:New(1,0,1) end,
    function() return 3%a end, function() return a%{} end}) do
    equal(pcall(run),false)
  end
end)

test("existing arithmetic and scalar product retain their meanings", function()
  local a,b=VECTOR:New(1,2,3),VECTOR:New(4,5,6)
  vector(a+b,5,7,9) vector(b-a,3,3,3)
  vector(a*b,4,10,18) vector(a*2,2,4,6) vector(2*a,2,4,6)
  vector(b/2,2,2.5,3) vector(b/a,4,2.5,2)
  near(a:Dot(b),32)
  vector(a,1,2,3) vector(b,4,5,6)
end)

test("large integer component distances remain finite without squared integer overflow", function()
  local a,b=VECTOR:New(0,0,0),VECTOR:New(1000000000000,1000000000000,0)
  near(a:GetDistance(b,true)/1000000000000,1)
  near(a:GetDistance(b)/1000000000000,math.sqrt(2))
end)

print(string.format("%d passed, %d failed",passed,failed))
if failed>0 then os.exit(1) end
