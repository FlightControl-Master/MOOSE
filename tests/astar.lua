-- Standalone ASTAR regressions; run from the repository root:
-- lua tests/astar.lua
-- DCS terrain/road queries are stubs. No simulator or external modules are needed.
-- An optional first argument selects another Astar.lua for regression comparison.
local source = arg and arg[1] or "Moose Development/Moose/Core/Astar.lua"
unpack = unpack or table.unpack

local function deepcopy(value)
  if type(value) ~= "table" then return value end
  local result = {}
  for key, item in pairs(value) do result[key] = deepcopy(item) end
  return setmetatable(result, getmetatable(value))
end

BASE = {}
function BASE:New() return setmetatable({}, {__index = self}) end
function BASE:Inherit(child, parent) return setmetatable(deepcopy(child), {__index = parent}) end
function BASE:T() end
function BASE:T2() end
function BASE:E() end
timer = {getAbsTime = function() return 0 end}
MESSAGE = {New = function() return {ToAllIf = function() end} end}
land = {SurfaceType = {LAND = 1, WATER = 3}}

COORDINATE = {ClassName = "COORDINATE"}
function COORDINATE:New(x, y, z)
  return setmetatable({x = x, y = y, z = z}, {__index = self})
end
function COORDINATE:GetSurfaceType() return self.surface or land.SurfaceType.WATER end
function COORDINATE:GetVec3() return {x = self.x, y = self.y, z = self.z} end
function COORDINATE:Get2DDistance(other)
  return math.sqrt((self.x - other.x)^2 + (self.z - other.z)^2)
end
function COORDINATE:Get3DDistance(other)
  return math.sqrt(self:Get2DDistance(other)^2 + (self.y - other.y)^2)
end
local function atan2(y, x)
  if x > 0 then return math.atan(y / x) end
  if x < 0 then return math.atan(y / x) + (y >= 0 and math.pi or -math.pi) end
  return y > 0 and math.pi / 2 or (y < 0 and -math.pi / 2 or 0)
end
function COORDINATE:HeadingTo(other) return math.deg(atan2(other.z - self.z, other.x - self.x)) end
function COORDINATE:Translate(distance, heading)
  local angle = math.rad(heading)
  return COORDINATE:New(self.x + distance * math.cos(angle), self.y, self.z + distance * math.sin(angle))
end
UTILS = {GetOSTime = function() return 0 end}
function UTILS.VecDist2D(a, b) return math.sqrt((a.x-b.x)^2 + (a.y-b.y)^2) end
function UTILS.Rotate2D(v, heading)
  local angle = math.rad(heading)
  return {x = v.x * math.cos(angle) + v.z * math.sin(angle), y = v.y,
    z = v.z * math.cos(angle) - v.x * math.sin(angle)}
end
function UTILS.VecTranslate(v, distance, heading)
  return COORDINATE:New(v.x, v.y, v.z):Translate(distance, heading):GetVec3()
end

dofile(source)

local passed, failed = 0, 0
local function test(name, run)
  local ok, err = pcall(run)
  if ok then
    passed = passed + 1
    print("PASS " .. name)
  else
    failed = failed + 1
    print("FAIL " .. name .. ": " .. tostring(err))
  end
end
local function equal(actual, expected)
  assert(actual == expected, "expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local function near(actual, expected) assert(math.abs(actual - expected) < 1e-8) end
local function coord(x, z, y) return COORDINATE:New(x, y or 0, z or 0) end
local function pair()
  local a = ASTAR:New()
  local s = a:AddNodeFromCoordinate(coord(0))
  local g = a:AddNodeFromCoordinate(coord(10))
  a:SetStartCoordinate(s.coordinate):SetEndCoordinate(g.coordinate)
  return a, s, g
end
local function alternatives()
  local a, s, g = pair()
  local high = a:AddNodeFromCoordinate(coord(5, 0, 1000))
  local detour = a:AddNodeFromCoordinate(coord(5, 10))
  a:SetValidNeighbourFunction(function(u, v)
    return not ((u == s and v == g) or (u == g and v == s))
  end)
  return a, s, g, high, detour
end

test("default and explicit 2D distance", function()
  local a, s, g = pair()
  equal(#a:GetPath(), 2)
  a:SetCostDist2D()
  equal(ASTAR.Dist2D(s, g), 10)
  equal(#a:GetPath(), 2)
end)

test("empty and fully filtered grids return nil", function()
  local a = ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(2000))
  equal(a:GetPath(), nil)
  a:CreateGrid({land.SurfaceType.LAND}, 2000, 0, 1000, 1000)
  equal(a.Nnodes, 0)
  equal(a:GetPath(), nil)
end)

test("missing endpoint coordinates return nil", function()
  local a = ASTAR:New()
  equal(a:GetPath(), nil)
  a:SetStartCoordinate(coord(0))
  equal(a:GetPath(), nil)
end)

test("changing neighbour rules invalidates both cached directions", function()
  local a, s, g = pair()
  equal(#a:GetPath(), 2)
  a:SetValidNeighbourFunction(function() return false end)
  equal(a:GetPath(), nil)
  a:SetStartCoordinate(g.coordinate):SetEndCoordinate(s.coordinate)
  equal(a:GetPath(), nil)
  a:SetValidNeighbourFunction(nil)
  equal(#a:GetPath(), 2)
end)

test("distance setter updates arguments and clears cached results", function()
  local a = pair()
  a:SetValidNeighbourDistance(10)
  equal(#a:GetPath(), 2)
  a:SetValidNeighbourDistance(9)
  equal(a:GetPath(), nil)
end)

test("callback arguments preserve embedded and trailing nils", function()
  local a = pair()
  local function check(u, v, ...)
    equal(select("#", ...), 3)
    local first, second, third = ...
    equal(first, nil) equal(second, 7) equal(third, nil)
  end
  a:SetValidNeighbourFunction(function(u, v, ...) check(u, v, ...) return true end, nil, 7, nil)
  a:SetCostFunction(function(u, v, ...) check(u, v, ...) return 1 end, nil, 7, nil)
  equal(#a:GetPath(), 2)
end)

test("3D mode minimizes 3D travel cost", function()
  local a, s, g, high, detour = alternatives()
  equal(a:GetPath()[2], high)
  a:SetCostDist3D()
  local path = a:GetPath()
  equal(path[2], detour)
  near(ASTAR.Dist3D(s, detour) + ASTAR.Dist3D(detour, g), math.sqrt(125) * 2)
  a:SetCostDist2D()
  equal(a:GetPath()[2], high)
end)

test("custom costs determine route and invalidate cached costs", function()
  local a, s, g, high, detour = alternatives()
  a:SetCostFunction(function(u, v) return (u == high or v == high) and 100 or 1 end)
  equal(a:GetPath()[2], detour)
  a:SetCostFunction(function(u, v) return (u == detour or v == detour) and 100 or 1 end)
  equal(a:GetPath()[2], high)
  a:SetStartCoordinate(g.coordinate):SetEndCoordinate(s.coordinate)
  equal(a:GetPath()[2], high)
  a:SetCostFunction(nil)
  equal(a:GetPath()[2], high)
end)

test("infinite edge costs return nil without a crash", function()
  local a = pair()
  a:SetCostFunction(function() return math.huge end)
  equal(a:GetPath(), nil)
end)

test("finite detour remains reachable beside an infinite edge", function()
  local a, s, g = pair()
  local middle = a:AddNodeFromCoordinate(coord(5))
  a:SetCostFunction(function(u, v)
    if (u == s and v == g) or (u == g and v == s) then return math.huge end
    return 1
  end)
  equal(a:GetPath()[2], middle)
end)

test("no finite open score returns nil", function()
  local a = pair()
  a._HeuristicCost = function() return math.huge end
  equal(a:GetPath(), nil)
end)

test("road costs use actual road length", function()
  local a, s, g, high, detour = alternatives()
  land.findPathOnRoads = function(kind, x1, z1, x2, z2)
    equal(kind, "roads")
    local length = (z1 == 10 or z2 == 10) and 12 or 100
    local dx, dz = x2-x1, z2-z1
    local direct = math.sqrt(dx*dx + dz*dz)
    local offset = math.sqrt((length / 2)^2 - (direct / 2)^2)
    return {{x=x1, y=z1}, {x=(x1+x2)/2-dz/direct*offset, y=(z1+z2)/2+dx/direct*offset}, {x=x2, y=z2}}
  end
  a:SetCostRoad()
  near(ASTAR.DistRoad(s, detour), 12)
  equal(a:GetPath()[2], detour)
end)

test("missing roads are impassable", function()
  local a = pair()
  land.findPathOnRoads = function() return nil end
  a:SetCostRoad()
  equal(a:GetPath(), nil)
end)

test("road distance limit includes boundary and avoids unnecessary road queries", function()
  local a, s, g = pair()
  local calls = 0
  land.findPathOnRoads = function() calls = calls + 1 return {{x=0,y=0},{x=10,y=0}} end
  a:SetValidNeighbourRoad(9)
  equal(a:GetPath(), nil)
  equal(calls, 0)
  a:SetValidNeighbourRoad(10)
  equal(#a:GetPath(), 2)
  equal(calls, 1)
  local far = a:GetNodeFromCoordinate(coord(3000))
  equal(ASTAR.Road(s, far), false)
  equal(calls, 1)
end)

test("distant endpoints are added once and obey neighbour rules", function()
  local a = ASTAR:New()
  local middle = a:AddNodeFromCoordinate(coord(0))
  a:SetStartCoordinate(coord(-5000)):SetEndCoordinate(coord(5000))
  a:SetValidNeighbourDistance(6000)
  local path = a:GetPath()
  equal(#path, 3)
  equal(path[1].coordinate.x, -5000)
  equal(path[2], middle)
  equal(path[3].coordinate.x, 5000)
  equal(a.Nnodes, 3)
  equal(#a:GetPath(), 3)
  equal(a.Nnodes, 3)
  a:SetValidNeighbourDistance(4000)
  equal(a:GetPath(), nil)
end)

test("nearby endpoints retain existing grid snapping", function()
  local a, s, g = pair()
  a:SetStartCoordinate(coord(-1000)):SetEndCoordinate(coord(1010))
  local path = a:GetPath()
  equal(path[1], s) equal(path[#path], g) equal(a.Nnodes, 2)
end)

test("distant endpoints respect the grid surface filter", function()
  local a = ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(2000))
  a:CreateGrid({land.SurfaceType.WATER}, 2000, 0, 1000, 1000)
  local count = a.Nnodes
  local dry = coord(-5000)
  dry.surface = land.SurfaceType.LAND
  a:SetStartCoordinate(dry)
  equal(a:GetPath(), nil)
  equal(a.Nnodes, count)
  a:SetStartCoordinate(coord(0)):SetEndCoordinate(dry)
  equal(a:GetPath(), nil)
  equal(a.Nnodes, count)
end)

test("adding an existing node does not inflate node count", function()
  local a, s = pair()
  a:AddNode(s)
  equal(a.Nnodes, 2)
end)

test("endpoint exclusion including NAVYGROUP usage", function()
  local a, s, g, high = alternatives()
  local path = a:GetPath(true, true)
  equal(#path, 1) equal(path[1], high)
  path = a:GetPath(true, false)
  equal(#path, 2) equal(path[2], g)
  path = a:GetPath(false, true)
  equal(#path, 2) equal(path[1], s)
  a:SetEndCoordinate(s.coordinate)
  equal(#a:GetPath(), 1)
  equal(#a:GetPath(true, true), 0)
end)

test("LoS corridor arguments reach DCS visibility queries", function()
  local a = pair()
  local points = {}
  land.isVisible = function(u, v) points[#points+1] = {u, v} return true end
  a:SetValidNeighbourLoS(500)
  equal(#a:GetPath(), 2)
  equal(#points, 3)
  near(points[2][1].z, 250)
  near(points[3][1].z, -250)
end)

test("ASTAR instances have independent nodes and caches", function()
  local a = pair()
  local b = ASTAR:New()
  equal(b.Nnodes, 0)
  equal(next(b.nodes), nil)
  equal(#a:GetPath(), 2)
end)

print(string.format("%d passed, %d failed", passed, failed))
if failed > 0 then os.exit(1) end
