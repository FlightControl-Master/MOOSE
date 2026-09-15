-- Standalone COORDINATE altitude regressions; run from the repository root with Lua 5.1 or 5.4.
-- Production methods are loaded directly; only inheritance and DCS terrain queries are stubbed.
local file=assert(io.open("Moose Development/Moose/Core/Point.lua","r"))
local source=file:read("*a"):gsub("\r\n","\n") file:close()
BASE={New=function() return {} end,Inherit=function(_,child) return setmetatable({},{__index=child}) end}
COORDINATE={ClassName="COORDINATE"}
function COORDINATE:F2() end
coord={LLtoLO=function(lat,lon) return {x=lat*10,y=999,z=lon*20} end}
for _,name in ipairs({"New","NewFromVec3","NewFromLLDD","GetAlt","SetAlt","AddAlt","GetLandHeight","SetAltitude","SetAtLandheight",
  "GetVec2","GetSurfaceType","IsSurfaceTypeLand"}) do
  local code=assert(source:match("(function COORDINATE:"..name.."%b().-\n  end)"),name)
  assert((loadstring or load)(code))()
end
local queries,surface=0,1
land={SurfaceType={LAND=1,WATER=3},getHeight=function(p)
  queries=queries+1
  return p.x/10+p.y/20
end,getSurfaceType=function() return surface end}
local function equal(a,b) assert(a==b,"expected "..tostring(b)..", got "..tostring(a)) end
local passed,failed=0,0
local function test(name,fn)
  queries=0 surface=land.SurfaceType.LAND
  local ok,err=pcall(fn)
  if ok then passed=passed+1 print("PASS "..name)
  else failed=failed+1 print("FAIL "..name..": "..tostring(err)) end
end

test("altitude reads return numeric positive zero and negative ASL values without terrain queries",function()
  for _,alt in ipairs({150,0,-30,0.125}) do
    local c=COORDINATE:New(100,alt,400)
    equal(c:GetAlt(),alt) equal(type(c:GetAlt()),"number")
    equal(c.y,alt) equal(queries,0)
  end
end)

test("altitude setters distinguish explicit ASL values from terrain defaults",function()
  local c=COORDINATE:New(100,900,400)
  for _,alt in ipairs({0,-20,100}) do
    equal(c:SetAlt(alt),c) equal(c:GetAlt(),alt) equal(queries,0)
  end
  equal(c:SetAlt(),c) equal(c:GetAlt(),30) equal(queries,1)
  equal(c.x,100) equal(c.z,400)
end)

test("ground-relative altitude offsets handle omitted zero positive and negative values",function()
  local c=COORDINATE:New(100,900,400)
  equal(c:AddAlt(),c) equal(c:GetAlt(),30)
  equal(c:AddAlt(0),c) equal(c:GetAlt(),30)
  equal(c:AddAlt(12),c) equal(c:GetAlt(),42)
  equal(c:AddAlt(-45),c) equal(c:GetAlt(),-15)
  equal(queries,4) equal(c.x,100) equal(c.z,400)
end)

test("ground-relative updates sample the current location and agree with SetAltitude",function()
  local c=COORDINATE:New(100,-50,400)
  c:AddAlt(15) equal(c:GetAlt(),45)
  c.x=200 c.z=800
  c:AddAlt(15) equal(c:GetAlt(),75)
  c:SetAltitude(15) equal(c:GetAlt(),75)
  c:SetAltitude(0,true) equal(c:GetAlt(),0)
  equal(c:GetLandHeight(),60) equal(c:GetAlt(),0)
  equal(c:SetAtLandheight(),c) equal(c:GetAlt(),60)
end)

test("geographic construction uses terrain at the newly converted position",function()
  local c=COORDINATE:NewFromLLDD(10,20)
  equal(c.x,100) equal(c.z,400) equal(c:GetAlt(),30) equal(queries,1)
  local origin=COORDINATE:New(-100,-500,-200)
  local other=origin:NewFromLLDD(20,30)
  equal(other.x,200) equal(other.z,600) equal(other:GetAlt(),50)
  equal(origin.x,-100) equal(origin.y,-500) equal(origin.z,-200) equal(queries,2)
end)

test("geographic construction preserves explicit ASL altitude without querying terrain",function()
  for _,alt in ipairs({0,-30,150}) do
    local c=COORDINATE:NewFromLLDD(10,20,alt)
    equal(c:GetAlt(),alt) equal(c.x,100) equal(c.z,400)
  end
  equal(queries,0)
end)

test("land surface predicate distinguishes land from water",function()
  local c=COORDINATE:New(100,0,400)
  equal(c:IsSurfaceTypeLand(),true)
  surface=land.SurfaceType.WATER
  equal(c:IsSurfaceTypeLand(),false)
end)

print(string.format("%d passed, %d failed",passed,failed))
if failed>0 then os.exit(1) end
