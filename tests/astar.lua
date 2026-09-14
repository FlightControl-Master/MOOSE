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
function COORDINATE:GetSurfaceType()
  return self.surface or (land.surfaceAt and land.surfaceAt(self)) or land.SurfaceType.WATER
end
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
  land.surfaceAt = nil
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

local function hexgrid(width, margin, spacing)
  local a = ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(4000))
  a:CreateHexGrid({land.SurfaceType.WATER}, width or 4000, margin or 2000, spacing or 1000)
  return a
end
local function count(entries)
  local n = 0 for _ in pairs(entries) do n = n + 1 end return n
end

test("hex geometry has six unique equidistant neighbours", function()
  local a = hexgrid():SetHexNeighboursOnly()
  local center = a.hexIndex[2][0]
  local neighbours = a:_NeighbourNodes(center, a.nodes)
  equal(#neighbours, 6)
  local seen = {}
  for _, node in ipairs(neighbours) do
    assert(not seen[node.id]) seen[node.id] = true
    near(center.coordinate:Get2DDistance(node.coordinate), 1000)
    local dq, dr = node.q-center.q, node.r-center.r
    equal(math.max(math.abs(dq), math.abs(dr), math.abs(dq+dr)), 1)
    assert(a.hexLinks[node.id][center.id])
  end
  equal(count(a.nodes), a.Nnodes)
end)

test("hex defaults, center bounds and markers", function()
  local a = ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(4000))
  a:CreateHexGrid()
  equal(a.hexGrid.spacing, 2000)
  assert(a.hexIndex[-5][0]) assert(a.hexIndex[7][0])
  local marks = 0
  function COORDINATE:MarkToAll(text) assert(text:match("Hex q=")) marks = marks + 1 end
  local b = ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(4300))
  b:CreateHexGrid(nil, 3700, 1700, 1000, true)
  equal(marks, b.Nnodes)
  for _, node in pairs(b.nodes) do
    assert(node.coordinate.x >= -1700-1e-8 and node.coordinate.x <= 6000+1e-8)
    assert(math.abs(node.coordinate.z) <= 1850+1e-8)
    equal(node.coordinate.y, 0)
  end
end)

test("hex geometry rotates with heading and translates with the origin", function()
  for _, heading in ipairs({0, 37, 90, 180, 275}) do
    local origin = coord(123456, -234567)
    local a = ASTAR:New():SetStartCoordinate(origin):SetEndCoordinate(origin:Translate(4000, heading))
    a:CreateHexGrid(nil, 4000, 2000, 1000):SetHexNeighboursOnly(true)
    near(a.hexIndex[0][0].coordinate:Get2DDistance(origin), 0)
    near(a.hexIndex[4][0].coordinate:Get2DDistance(a.endCoord), 0)
    local center = a.hexIndex[2][0]
    equal(#a:_NeighbourNodes(center, a.nodes), 6)
    for _, node in ipairs(a:_NeighbourNodes(center, a.nodes)) do
      near(center.coordinate:Get2DDistance(node.coordinate), 1000)
    end
    equal(#a:GetPath(), 5)
  end
end)

test("hex candidate mode is optional and composes with validity rules", function()
  local a = hexgrid()
  equal(#a:GetPath(), 2)
  a:SetHexNeighboursOnly(true)
  local center = a.hexIndex[2][0]
  local requests = a.nvalid
  equal(#a:_NeighbourNodes(center, a.nodes), 6)
  equal(a.nvalid-requests, 6)
  equal(#a:GetPath(), 5)
  a:SetValidNeighbourFunction(function() return false end)
  equal(a:GetPath(), nil)
  a:SetValidNeighbourFunction(nil)
  a:SetHexNeighboursOnly(false)
  equal(#a:GetPath(), 2)
  a:SetHexNeighboursOnly(true)
  equal(#a:GetPath(), 5)
end)

test("hex surface holes do not create jumps or wraparound edges", function()
  land.surfaceAt = function(c) return math.abs(c.x-2000)<1e-6 and land.SurfaceType.LAND or land.SurfaceType.WATER end
  local a = hexgrid(0, 0):SetHexNeighboursOnly(true)
  equal(a.Nnodes, 4)
  assert(not a.hexIndex[2])
  equal(a:GetPath(), nil)
  equal(#a:_NeighbourNodes(a.hexIndex[1][0], a.nodes), 1)
  a:SetHexNeighboursOnly(false)
  equal(#a:GetPath(), 2)
end)

test("hex search detours around a filtered center", function()
  land.surfaceAt = function(c)
    return math.abs(c.x-2000)<1e-6 and math.abs(c.z)<1e-6 and land.SurfaceType.LAND or land.SurfaceType.WATER
  end
  local a = hexgrid():SetHexNeighboursOnly(true)
  local path = a:GetPath()
  assert(path and #path > 5)
  for i, node in ipairs(path) do
    equal(node.surfacetype, land.SurfaceType.WATER)
    if i > 1 then near(path[i-1].coordinate:Get2DDistance(node.coordinate), 1000) end
  end
end)

test("hex attachments match geometric neighbours across rotations", function()
  for _, heading in ipairs({0, 37, 90, 180, 275}) do
    local origin = coord(-654321, 234567)
    local a = ASTAR:New():SetStartCoordinate(origin):SetEndCoordinate(origin:Translate(4000, heading))
    a:CreateHexGrid(nil, 4000, 2000, 1000):SetHexNeighboursOnly(true)
    local extras = {}
    for _, offset in ipairs({{-300,100}, {1700,350}, {4000,2000}, {9000,0}, {0,0}}) do
      local c = origin:Translate(offset[1], heading):Translate(offset[2], heading+90)
      extras[#extras+1] = a:AddNodeFromCoordinate(c)
    end
    a:_BuildHexLinks()
    for _, extra in ipairs(extras) do
      local expected = 0
      for _, node in pairs(a.nodes) do
        if node.q ~= nil then
          local close = extra.coordinate:Get2DDistance(node.coordinate) <= 1000+1e-6
          equal(not not a.hexLinks[extra.id][node.id], close)
          equal(not not a.hexLinks[node.id][extra.id], close)
          if close then expected = expected+1 end
        else
          equal(a.hexLinks[extra.id][node.id], nil)
        end
      end
      equal(count(a.hexLinks[extra.id]), expected)
    end
    equal(count(a.hexLinks[extras[4].id]), 0)
  end
end)

test("hex mode keeps nearby endpoints exact and reuses them", function()
  local a = hexgrid():SetHexNeighboursOnly(true)
  a:SetStartCoordinate(coord(-300, 100)):SetEndCoordinate(coord(4300, 100))
  local path = a:GetPath()
  assert(path)
  near(path[1].coordinate:Get2DDistance(a.startCoord), 0)
  near(path[#path].coordinate:Get2DDistance(a.endCoord), 0)
  equal(path[1].q, nil) equal(path[#path].q, nil)
  local nodeCount = a.Nnodes
  equal(#a:GetPath(), #path)
  equal(a.Nnodes, nodeCount)
  equal(#a:GetPath(true, true), #path-2)
end)

test("hex endpoint attachments obey LoS and corridor checks", function()
  local a = hexgrid():SetHexNeighboursOnly(true):SetValidNeighbourLoS(500)
  a:SetStartCoordinate(coord(-300, 100))
  local checkedOffset = false
  land.isVisible = function(u, v)
    if math.abs(u.z-100)>1e-6 then checkedOffset = true end
    return true
  end
  assert(a:GetPath()) assert(checkedOffset)
  land.isVisible = function(u, v) return u.x>=0 and v.x>=0 end
  a:SetValidNeighbourLoS(500)
  equal(a:GetPath(), nil)
end)

test("hex endpoints outside attachment range or on rejected surfaces fail", function()
  local a = hexgrid():SetHexNeighboursOnly(true)
  a:SetEndCoordinate(coord(20000))
  equal(a:GetPath(), nil)
  local b = hexgrid():SetHexNeighboursOnly(true)
  local dry = coord(100, 100) dry.surface = land.SurfaceType.LAND
  b:SetStartCoordinate(dry)
  equal(b:GetPath(), nil)
  local empty = ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(4000))
  empty:CreateHexGrid(land.SurfaceType.LAND, 4000, 0, 1000):SetHexNeighboursOnly(true)
  equal(empty.Nnodes, 0) equal(empty:GetPath(), nil)
end)

test("manual nodes added after a search rebuild hex attachments", function()
  local a = hexgrid():SetHexNeighboursOnly(true)
  assert(a:GetPath())
  local oldLinks = a.hexLinks
  local extra = a:AddNodeFromCoordinate(coord(1700, 250))
  equal(a.hexLinks, nil)
  a:SetEndCoordinate(extra.coordinate)
  local path = a:GetPath()
  equal(path[#path], extra)
  assert(a.hexLinks ~= oldLinks)
  assert(count(a.hexLinks[extra.id]) > 0)
  local n = a.Nnodes
  a:AddNode(a.hexIndex[0][0])
  equal(a.Nnodes, n)
  assert(a:GetPath())
end)

test("hex zero-length route and empty exclusions", function()
  local a = ASTAR:New():SetStartCoordinate(coord(10, 20)):SetEndCoordinate(coord(10, 20))
  a:CreateHexGrid(nil, 0, 0, 1000):SetHexNeighboursOnly(true)
  equal(a.Nnodes, 1)
  equal(#a:GetPath(), 1)
  equal(#a:GetPath(true, true), 0)
end)

test("invalid hex setup is rejected before adding nodes", function()
  equal(pcall(function() ASTAR:New():CreateHexGrid() end), false)
  equal(pcall(function() ASTAR:New():SetHexNeighboursOnly(true) end), false)
  ASTAR:New():SetHexNeighboursOnly(false)
  for _, args in ipairs({{4000,0,0}, {4000,0,-1}, {4000,0,math.huge}, {4000,0,0/0}, {-1,0,1000}, {4000,-1,1000}}) do
    local a = ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(4000))
    equal(pcall(function() a:CreateHexGrid(nil, unpack(args)) end), false)
    equal(a.Nnodes, 0) equal(a.hexGrid, nil)
  end
  local a = hexgrid()
  local n = a.Nnodes
  equal(pcall(function() a:CreateHexGrid() end), false)
  equal(pcall(function() a:CreateGrid() end), false)
  equal(a.Nnodes, n)
  local b = pair()
  equal(pcall(function() b:CreateHexGrid() end), false)
  equal(b.Nnodes, 2)
end)

test("hex custom costs match an independent geometric Dijkstra search", function()
  local a = hexgrid():SetHexNeighboursOnly(true)
  a:SetStartCoordinate(coord(100, 300)):SetEndCoordinate(coord(3700, 250))
  local function cost(u, v) return ASTAR.Dist2D(u, v) * (1+(u.id+v.id)%5) end
  a:SetCostFunction(cost)
  local path = a:GetPath()
  assert(path)
  -- Oracle: discover candidates by geometry, without the hex index or cached adjacency.
  local dist, done = {[a.startNode.id]=0}, {}
  while true do
    local current, best = nil, math.huge
    for id, d in pairs(dist) do if not done[id] and d<best then current, best=a.nodes[id], d end end
    assert(current, "Oracle found no route")
    if current == a.endNode then break end
    done[current.id] = true
    for id, node in pairs(a.nodes) do
      local d = ASTAR.Dist2D(current, node)
      local connected = (current.q ~= nil or node.q ~= nil) and d <= 1000+1e-6
      if id ~= current.id and connected and not done[id] then
        local candidate = best+cost(current, node)
        if candidate < (dist[id] or math.huge) then dist[id] = candidate end
      end
    end
  end
  local actual = 0
  for i=2,#path do actual = actual+cost(path[i-1], path[i]) end
  near(actual, dist[a.endNode.id])
end)

test("hex instances do not share grid indices or candidate links", function()
  local a = hexgrid():SetHexNeighboursOnly(true)
  local b = hexgrid():SetHexNeighboursOnly(true)
  assert(a:GetPath()) assert(b:GetPath())
  assert(a.hexGrid ~= b.hexGrid and a.hexIndex ~= b.hexIndex and a.hexLinks ~= b.hexLinks)
  local n = b.Nnodes
  a:AddNodeFromCoordinate(coord(100, 100))
  equal(b.Nnodes, n)
  assert(b:GetPath())
end)

test("potential path rejects separated hex components before any expensive query", function()
  land.surfaceAt = function(c) return c.x==2000 and land.SurfaceType.LAND or land.SurfaceType.WATER end
  local a = hexgrid(0, 0):SetHexNeighboursOnly(true):SetValidNeighbourLoS(500):SetCostRoad()
  land.isVisible = function() error("Disconnected precheck must not query LoS") end
  land.findPathOnRoads = function() error("Disconnected precheck must not query roads") end
  a._LowestFscore = function() error("Disconnected precheck must not start A*") end
  equal(a:HasPotentialPath(), false)
  equal(a:GetPath(), nil)
  equal(a.nvalid, 0) equal(a.ncost, 0)
end)

test("potential path is not a promise that rules or costs permit a route", function()
  local a = hexgrid(0, 0):SetHexNeighboursOnly(true)
  local calls = 0
  a:SetValidNeighbourFunction(function() calls=calls+1 return false end)
  equal(a:HasPotentialPath(), true)
  equal(calls, 0)
  equal(a:GetPath(), nil)
  assert(calls>0)
  a:SetValidNeighbourFunction(nil)
  a:SetCostFunction(function() return math.huge end)
  equal(a:HasPotentialPath(), true)
  equal(a:GetPath(), nil)
end)

test("potential path includes exact endpoint attachments in both directions", function()
  local a = hexgrid():SetHexNeighboursOnly(true)
  a:SetStartCoordinate(coord(-300,100)):SetEndCoordinate(coord(4300,100))
  equal(a:HasPotentialPath(), true)
  near(a.startNode.coordinate:Get2DDistance(a.startCoord), 0)
  near(a.endNode.coordinate:Get2DDistance(a.endCoord), 0)
  local n = a.Nnodes
  local path = a:GetPath()
  assert(path)
  equal(a.Nnodes, n)
  a:SetStartCoordinate(coord(4300,100)):SetEndCoordinate(coord(-300,100))
  equal(a:HasPotentialPath(), true)
  equal(a.Nnodes, n)
  a:SetEndCoordinate(coord(20000))
  equal(a:HasPotentialPath(), false)
end)

test("potential path caches complete components and invalidates after a bridge is added", function()
  land.surfaceAt = function(c) return c.x==2000 and land.SurfaceType.LAND or land.SurfaceType.WATER end
  local a = hexgrid(0, 0):SetHexNeighboursOnly(true)
  equal(a:HasPotentialPath(), false)
  local components = a.hexComponents
  local labelled = count(components)
  equal(labelled, 2)
  a:SetEndCoordinate(a.hexIndex[1][0].coordinate)
  equal(a:HasPotentialPath(), true)
  equal(a.hexComponents, components)
  equal(count(components), labelled)
  a:SetStartCoordinate(a.hexIndex[4][0].coordinate):SetEndCoordinate(a.hexIndex[3][0].coordinate)
  equal(a:HasPotentialPath(), true)
  equal(count(components), 4)
  a:SetStartCoordinate(a.hexIndex[0][0].coordinate):SetEndCoordinate(a.hexIndex[4][0].coordinate)
  equal(a:HasPotentialPath(), false)
  -- An explicitly supplied node can bridge the gap; manual nodes bypass the grid surface filter.
  a:AddNodeFromCoordinate(coord(2000))
  equal(a:HasPotentialPath(), true)
  assert(a.hexComponents ~= components)
  assert(a:GetPath())
end)

test("potential path never rejects all-pairs jumps across disconnected hex cells", function()
  land.surfaceAt = function(c) return c.x==2000 and land.SurfaceType.LAND or land.SurfaceType.WATER end
  local a = hexgrid(0, 0):SetHexNeighboursOnly(true)
  equal(a:HasPotentialPath(), false)
  a:SetHexNeighboursOnly(false)
  equal(a:HasPotentialPath(), true)
  equal(#a:GetPath(), 2)
  a:SetHexNeighboursOnly(true)
  equal(a:HasPotentialPath(), false)
  local b = pair()
  b:SetValidNeighbourFunction(function() error("All-pairs precheck must not evaluate rules") end)
  equal(b:HasPotentialPath(), true)
end)

test("potential path handles missing, rejected and coincident endpoints", function()
  local empty = ASTAR:New()
  equal(empty:HasPotentialPath(), false)
  empty:SetStartCoordinate(coord(0)):SetEndCoordinate(coord(4000))
  equal(empty:HasPotentialPath(), false)
  empty:CreateHexGrid({}, 4000, 1000, 1000):SetHexNeighboursOnly(true)
  equal(empty:HasPotentialPath(), false)
  local a = hexgrid():SetHexNeighboursOnly(true)
  local dry = coord(100,100) dry.surface = land.SurfaceType.LAND
  a:SetStartCoordinate(dry)
  equal(a:HasPotentialPath(), false)
  a:SetStartCoordinate(a.hexIndex[0][0].coordinate):SetEndCoordinate(a.hexIndex[0][0].coordinate)
  equal(a:HasPotentialPath(), true)
  equal(#a:GetPath(), 1)
end)

-- Exercise the real MOOSE polygon/removal wrappers; only the DCS boundary is mocked.
local pointFile = assert(io.open("Moose Development/Moose/Core/Point.lua", "r"))
local pointSource = pointFile:read("*a"):gsub("\r\n", "\n")
pointFile:close()
for _, name in ipairs({"MarkupToAllFreeForm", "RemoveMark"}) do
  local method = assert(pointSource:match("(    function COORDINATE:" .. name .. "%b().-\n    end)"))
  assert((loadstring or load)(method))()
end
UTILS.DeepCopy = deepcopy
local markCounter = 10000
function UTILS.GetMarkID() markCounter = markCounter+1 return markCounter end
local drawings, removals = {}, {}
trigger = {action = {}}
function trigger.action.markupToAll(shape, coalition, id, ...)
  equal(shape, 7)
  local args = {...}
  local n = select("#", ...)
  local vertices = {}
  for i=1,n-5 do vertices[i] = deepcopy(args[i]) end
  drawings[id] = {vertices=vertices, coalition=coalition, color=deepcopy(args[n-4]), fill=deepcopy(args[n-3]),
    lineType=args[n-2], readOnly=args[n-1], text=args[n]}
end
function trigger.action.removeMark(id)
  removals[#removals+1] = id
  drawings[id] = nil
end
local function resetDrawings() drawings, removals = {}, {} end
local function polygonCenter(vertices)
  local x, z = 0, 0
  for _, v in ipairs(vertices) do x=x+v.x z=z+v.z end
  return coord(x/#vertices, z/#vertices)
end
local function polygonArea(vertices)
  -- Shift coordinates to avoid cancellation at large map coordinates.
  local origin = vertices[1]
  local area = 0
  for i, v in ipairs(vertices) do
    local w = vertices[i%#vertices+1]
    area=area+(v.x-origin.x)*(w.z-origin.z)-(w.x-origin.x)*(v.z-origin.z)
  end
  return area/2
end

test("F10 hex polygons match rotated cells and share boundary vertices", function()
  for _, heading in ipairs({0, 37, 90, 180, 275}) do
    resetDrawings()
    local origin = coord(123456, -234567)
    local a = ASTAR:New():SetStartCoordinate(origin):SetEndCoordinate(origin:Translate(4000, heading))
    a:CreateHexGrid(nil, 4000, 2000, 1000)
    local cells = a.Nnodes
    a:AddNodeFromCoordinate(origin:Translate(100, heading))
    equal(a:DrawGrid(), a)
    equal(#a.GridDrawIDs, cells) equal(count(drawings), cells)
    local centerPolygon, adjacentPolygon
    for _, drawing in pairs(drawings) do
      local vertices = drawing.vertices
      equal(#vertices, 6)
      local center = polygonCenter(vertices)
      local closest, d = a:FindClosestNode(center)
      near(d, 0) assert(closest.q ~= nil)
      for i, v in ipairs(vertices) do
        near(center:Get2DDistance(v), 1000/math.sqrt(3))
        near(COORDINATE:New(v.x, v.y, v.z):Get2DDistance(vertices[i%6+1]), 1000/math.sqrt(3))
        equal(v.y, 0)
      end
      near(polygonArea(vertices)/1000^2, math.sqrt(3)/2)
      equal(drawing.coalition, -1) equal(drawing.color[3], 1)
      equal(drawing.color[4], 1) equal(drawing.fill[4], 0)
      equal(drawing.lineType, 1) equal(drawing.readOnly, true)
      if closest == a.hexIndex[0][0] then centerPolygon = vertices end
      if closest == a.hexIndex[1][0] then adjacentPolygon = vertices end
    end
    local shared = 0
    for _, v in ipairs(centerPolygon) do
      for _, w in ipairs(adjacentPolygon) do
        if coord(v.x, v.z):Get2DDistance(w)<1e-6 then shared=shared+1 end
      end
    end
    equal(shared, 2)
  end
end)

test("F10 rectangles retain each grid's orientation and spacing", function()
  resetDrawings()
  local a = ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(4000))
  a:CreateGrid(nil, 2000, 0, 2000, 1000)
  local originalCount = a.Nnodes
  a:SetStartCoordinate(coord(10000)):SetEndCoordinate(coord(10000, 4000))
  a:CreateGrid(nil, 2000, 0, 1000, 2000)
  a:DrawGrid()
  equal(count(drawings), a.Nnodes)
  local firstGridCount = 0
  for _, drawing in pairs(drawings) do
    equal(#drawing.vertices, 4)
    local center = polygonCenter(drawing.vertices)
    local node, d = a:FindClosestNode(center)
    near(d, 0) assert(node.rectGrid)
    if center.x < 5000 then firstGridCount=firstGridCount+1 end
    for _, v in ipairs(drawing.vertices) do
      local dx, dz = v.x-center.x, v.z-center.z
      local along = dx*node.rectGrid.cos+dz*node.rectGrid.sin
      local across = -dx*node.rectGrid.sin+dz*node.rectGrid.cos
      near(math.abs(along), node.rectGrid.along)
      near(math.abs(across), node.rectGrid.across)
    end
    near(polygonArea(drawing.vertices)/(2000*1000), 1)
  end
  equal(firstGridCount, originalCount)
end)

test("F10 redraw replaces only owned polygons and preserves other marks", function()
  resetDrawings()
  local a = hexgrid():SetHexNeighboursOnly(true)
  local path = a:GetPath()
  drawings[42] = {text="unrelated mark"}
  a:DrawGrid()
  local old = deepcopy(a.GridDrawIDs)
  local n = #old
  a:DrawGrid()
  equal(count(drawings), n+1) equal(#removals, n)
  for _, id in ipairs(old) do equal(drawings[id], nil) end
  local after = a:GetPath()
  equal(#after, #path)
  for i, node in ipairs(path) do equal(after[i], node) end
  equal(a:UndrawGrid(), a)
  equal(count(drawings), 1) equal(drawings[42].text, "unrelated mark")
  equal(#a.GridDrawIDs, 0)
  equal(#removals, 2*n)
  a:UndrawGrid()
  equal(#removals, 2*n)
end)

test("F10 styles preserve caller colors and accept zero opacity and neutral coalition", function()
  resetDrawings()
  local a = hexgrid(0, 0)
  local outline, fill = {1,0.5,0}, {0.2,0.3,0.4}
  a:DrawGrid(0, outline, 0, fill, 0, 0, false)
  equal(outline[4], nil) equal(fill[4], nil)
  for _, d in pairs(drawings) do
    equal(d.coalition, 0) equal(d.color[4], 0) equal(d.fill[4], 0)
    equal(d.lineType, 0) equal(d.readOnly, false)
    equal(d.color[1], 1) equal(d.fill[2], 0.3)
  end
  a:DrawGrid(2, outline, 0.8, nil, 0.1, 2)
  for _, d in pairs(drawings) do
    equal(d.coalition, 2) equal(d.color[4], 0.8) equal(d.fill[4], 0.1)
    equal(d.fill[1], outline[1]) equal(d.lineType, 2)
  end
  equal(outline[4], nil)
end)

test("F10 draws only accepted grid nodes, including no cells for a manual-only graph", function()
  resetDrawings()
  local manual = pair()
  manual:UndrawGrid():DrawGrid()
  equal(count(drawings), 0)
  land.surfaceAt = function(c) return c.x==2000 and land.SurfaceType.LAND or land.SurfaceType.WATER end
  local a = hexgrid(0, 0)
  local accepted = a.Nnodes
  equal(accepted, 4)
  a:AddNodeFromCoordinate(coord(2000))
  a:DrawGrid()
  equal(count(drawings), accepted)
  for _, drawing in pairs(drawings) do assert(polygonCenter(drawing.vertices).x ~= 2000) end
  local empty = ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(1000))
  empty:CreateGrid({}, 2000, 0, 1000, 1000):DrawGrid()
  equal(#empty.GridDrawIDs, 0)
end)

test("F10 overlays from different ASTAR instances are independent", function()
  resetDrawings()
  local a, b = hexgrid(0,0), hexgrid(0,0)
  a:DrawGrid() b:DrawGrid()
  local ids = deepcopy(b.GridDrawIDs)
  a:UndrawGrid()
  equal(count(drawings), #ids)
  for _, id in ipairs(ids) do assert(drawings[id]) end
end)

print(string.format("%d passed, %d failed", passed, failed))
if failed > 0 then os.exit(1) end
