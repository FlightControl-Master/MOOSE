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
local scheduled, timerNow, nextTimerID = {}, 0, 0
timer = {getAbsTime = function() return timerNow end, getTime = function() return timerNow end}
function timer.scheduleFunction(fn, args, at)
  nextTimerID=nextTimerID+1
  scheduled[nextTimerID]={fn=fn, args=args, at=at}
  return nextTimerID
end
function timer.removeFunction(id) scheduled[id]=nil end
local function stepTimer()
  local id, entry
  for candidate, task in pairs(scheduled) do
    if not entry or task.at<entry.at then id,entry=candidate,task end
  end
  if not entry then return false end
  timerNow=entry.at
  local nextTime=entry.fn(entry.args,timerNow)
  if scheduled[id]==entry and nextTime then entry.at=nextTime else scheduled[id]=nil end
  return true
end
local function flushTimers()
  local steps=0
  while stepTimer() do
    steps=steps+1
    assert(steps<10000,"Drawing timer did not terminate")
  end
end
MESSAGE = {New = function() return {ToAllIf = function() end} end}
land = {SurfaceType = {LAND = 1, SHALLOW_WATER = 2, WATER = 3}}

COORDINATE = {ClassName = "COORDINATE"}
function COORDINATE:New(x, y, z)
  return setmetatable({x = x, y = y, z = z}, {__index = self})
end
function land.getSurfaceType(v)
  return (land.surfaceAt and land.surfaceAt({x=v.x,y=0,z=v.y})) or land.SurfaceType.WATER
end
function COORDINATE:NewFromVec3(v) return self:New(v.x,v.y,v.z) end
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
  local angle=math.rad(heading)
  return {x=v.x+distance*math.cos(angle),y=v.y,z=v.z+distance*math.sin(angle)}
end
math.atan2=math.atan2 or atan2
function UTILS.AdjustHeading360(heading) return heading%360 end
local textMarkID=0
function UTILS.GetMarkID() textMarkID=textMarkID+1 return textMarkID end
trigger={action={markToAll=function() end}}
dofile("Moose Development/Moose/Core/Vector.lua")

dofile("Moose Development/Moose/Core/Grid.lua")
dofile(source)

local passed, failed = 0, 0
local originalProfile,originalSeabed=land.profile,land.getSurfaceHeightWithSeabed
local function test(name, run)
  local ok, err = pcall(run)
  land.surfaceAt = nil
  land.profile,land.getSurfaceHeightWithSeabed=originalProfile,originalSeabed
  scheduled={} timerNow=0
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
  a:SetStartCoordinate(s.vector):SetEndCoordinate(g.vector)
  return a, s, g
end

-- Deterministic seabed/profile queries for the naval neighbour rule.
local function depthTerrain()
  local terrain={depth=30,height=0,profiles=0,queries=0}
  land.getSurfaceHeightWithSeabed=function(p)
    terrain.queries=terrain.queries+1
    return terrain.height,terrain.depthAt and terrain.depthAt(p) or terrain.depth
  end
  land.profile=function(a,b)
    terrain.profiles=terrain.profiles+1
    if terrain.makeProfile then return terrain.makeProfile(a,b) end
    local points={}
    for _,f in ipairs({0,0.5,1}) do
      points[#points+1]={x=a.x+(b.x-a.x)*f,y=terrain.height-terrain.depth,z=a.z+(b.z-a.z)*f}
    end
    return points
  end
  return terrain
end

test("depth neighbours work with manual nodes, include the threshold and clear cached validity",function()
  local terrain=depthTerrain()
  local a,s,g=pair()
  equal(a:SetValidNeighbourDepth(),a)
  assert(a:GetPath()) equal(terrain.profiles,1)
  assert(a:_IsValidNeighbour(g,s)) equal(terrain.profiles,1)
  a:SetValidNeighbourDepth(30) assert(a:GetPath()) equal(terrain.profiles,2)
  a:SetValidNeighbourDepth(31) equal(a:GetPath(),nil)
  a:SetValidNeighbourDepth(20) assert(a:GetPath())
  equal(a:GetGrid().GridBuilt,nil)
end)

test("depth neighbours reject shallow profile points even when direct depth is sufficient",function()
  local terrain=depthTerrain()
  terrain.makeProfile=function(a,b)
    return {{x=a.x,y=-30,z=a.z},{x=(a.x+b.x)/2,y=-10,z=(a.z+b.z)/2},{x=b.x,y=-30,z=b.z}}
  end
  local a=pair()
  a:SetValidNeighbourDepth(20) equal(a:GetPath(),nil)
end)

test("depth neighbours reject shallow actual endpoints omitted by the returned profile",function()
  local terrain=depthTerrain()
  terrain.makeProfile=function() return {{x=2,y=-30,z=0},{x=8,y=-30,z=0}} end
  local a,s,g=pair()
  terrain.depthAt=function(p) return p.x==0 and 10 or 30 end
  equal(ASTAR.Depth(s,g,20),false) equal(terrain.profiles,0)
  terrain.depthAt=function(p) return p.x==10 and 10 or 30 end
  equal(ASTAR.Depth(g,s,20),false) equal(terrain.profiles,0)
  terrain.depthAt=nil assert(ASTAR.Depth(s,g,20))
end)

test("depth neighbours reject land and shallower direct values at profile support points",function()
  local terrain=depthTerrain()
  local a,s,g=pair()
  land.surfaceAt=function(p) return p.x==5 and land.SurfaceType.LAND or land.SurfaceType.WATER end
  equal(ASTAR.Depth(s,g),false)
  land.surfaceAt=nil
  terrain.depthAt=function(p) return p.x==5 and 10 or 30 end
  equal(ASTAR.Depth(s,g),false)
  terrain.depthAt=nil
  land.surfaceAt=function() return 2 end
  assert(ASTAR.Depth(s,g))
end)

test("depth corridors check both edges with symmetric queries and without changing node altitude",function()
  local terrain=depthTerrain()
  local a,s,g=pair() s.vector.y=120 g.vector.y=-50
  local calls={}
  terrain.makeProfile=function(first,last)
    calls[#calls+1]={first.x,first.z,last.x,last.z}
    return {{x=first.x,y=-30,z=first.z},{x=last.x,y=-30,z=last.z}}
  end
  assert(ASTAR.Depth(s,g,20,1000)) equal(#calls,3)
  equal(calls[1][2],0) equal(calls[2][2],500) equal(calls[3][2],-500)
  assert(ASTAR.Depth(g,s,20,1000))
  for i=1,3 do for j=1,4 do equal(calls[i][j],calls[i+3][j]) end end
  equal(s.vector.y,120) equal(g.vector.y,-50)
  for _,side in ipairs({-500,500}) do
    terrain.depthAt=function(p) return p.y==side and 5 or 30 end
    assert(ASTAR.Depth(s,g,20,0)) equal(ASTAR.Depth(s,g,20,1000),false)
  end
end)

test("depth checks use local water level and check coincident positions without asking for a profile",function()
  local terrain=depthTerrain() terrain.height=100
  local a,s,g=pair()
  assert(ASTAR.Depth(s,g,30))
  g.vector.x=s.vector.x
  local before=terrain.profiles
  assert(ASTAR.Depth(s,g,30)) equal(terrain.profiles,before)
  terrain.depth=29 equal(ASTAR.Depth(s,g,30),false)
end)

test("depth settings reject invalid numbers atomically",function()
  depthTerrain()
  local a=pair() a:SetValidNeighbourDepth(20,100)
  local rule,args=a.ValidNeighbourFunc,a.ValidNeighbourArg
  for _,bad in ipairs({false,"20",0,-1,math.huge,0/0}) do
    assert(not pcall(function() a:SetValidNeighbourDepth(bad) end))
    equal(a.ValidNeighbourFunc,rule) equal(a.ValidNeighbourArg,args)
  end
  for _,bad in ipairs({false,"100",-1,math.huge,0/0}) do
    assert(not pcall(function() a:SetValidNeighbourDepth(20,bad) end))
    equal(a.ValidNeighbourArg,args)
  end
end)

test("depth rules reject missing or malformed terrain data",function()
  local terrain=depthTerrain()
  local a,s,g=pair()
  for _,profile in ipairs({{{x=0,y=-30,z=0},{x=10,z=0}},{{x=0,y=-30,z=0},{x=10,y=0/0,z=0}}}) do
    terrain.makeProfile=function() return profile end
    equal(ASTAR.Depth(s,g),false)
  end
  terrain.makeProfile=function() return nil end
  equal(ASTAR.Depth(s,g),false)
  terrain.makeProfile=nil
  land.getSurfaceHeightWithSeabed=function() return 0,nil end
  equal(ASTAR.Depth(s,g),false)
  land.getSurfaceHeightWithSeabed=nil equal(ASTAR.Depth(s,g),false)
  depthTerrain() land.profile=nil equal(ASTAR.Depth(s,g),false)
end)

test("short depth profiles use direct intermediate samples instead of blocking clear connections",function()
  local terrain=depthTerrain()
  local a,s,g=pair()
  for _,singleton in ipairs({false,true}) do
    terrain.makeProfile=function(start,goal)
      return singleton and {{x=(start.x+goal.x)/2,y=-30,z=(start.z+goal.z)/2}} or {}
    end
    terrain.depthAt=nil
    assert(ASTAR.Depth(s,g,20,1000))
    terrain.depthAt=function(p) return p.x==5 and 5 or 30 end
    equal(ASTAR.Depth(s,g,20,1000),false)
  end
  terrain.depthAt=nil
  terrain.makeProfile=function() return {{x=5,y=-5,z=0}} end
  equal(ASTAR.Depth(s,g),false)
  terrain.makeProfile=function() return {} end
  g.vector.x=100001
  local ok,reason=ASTAR.Depth(s,g)
  equal(ok,false) equal(reason,"profile_fallback_limit")
end)

test("depth neighbour search takes a detour around an underwater shoal",function()
  local terrain=depthTerrain()
  terrain.makeProfile=function(a,b)
    local middle={x=(a.x+b.x)/2,z=(a.z+b.z)/2,y=-30}
    if math.abs(middle.x-1000)<100 and math.abs(middle.z)<100 then middle.y=-5 end
    return {{x=a.x,y=-30,z=a.z},middle,{x=b.x,y=-30,z=b.z}}
  end
  local a=ASTAR:New():SetValidNeighbourDepth(20)
  local s=a:AddNodeFromCoordinate(coord(0))
  local via=a:AddNodeFromCoordinate(coord(1000,1000))
  local g=a:AddNodeFromCoordinate(coord(2000))
  a:SetStartCoordinate(s.vector):SetEndCoordinate(g.vector)
  local path=assert(a:GetPath()) equal(#path,3) equal(path[2],via)
end)

test("depth neighbours work on rectangular and hexagonal grids without changing grid options",function()
  depthTerrain()
  for _,hex in ipairs({false,true}) do
    local a=ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(2000))
    a:SetGridOptions({Width=2000,Margin=1000,Spacing=1000})
    if hex then a:CreateHexGrid() else a:CreateGrid() end
    a:SetValidNeighbourDepth(20,500)
    assert(a:GetPath()) equal(a:GetGridOptions().Spacing,1000)
    a:SetValidNeighbourDepth(31,500) equal(a:GetPath(),nil)
  end
end)
local function configureExpansion(a, settings)
  local options=a:GetGridOptions()
  for key,value in pairs(settings) do
    if key=="MaxCells" then options.MaxCells=value
    else options.Expansion[key]=value end
  end
  return a:SetGridOptions(options)
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
  a:SetGridOptions({Width=2000,Margin=0,Spacing=1000,CrossSpacing=1000}):SetValidSurfaceTypes({land.SurfaceType.LAND}):CreateGrid()
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
  a:SetStartCoordinate(g.vector):SetEndCoordinate(s.vector)
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
  a:SetStartCoordinate(g.vector):SetEndCoordinate(s.vector)
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
  equal(path[1].vector.x, -5000)
  equal(path[2], middle)
  equal(path[3].vector.x, 5000)
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
  a:SetGridOptions({Width=2000,Margin=0,Spacing=1000,CrossSpacing=1000}):SetValidSurfaceTypes({land.SurfaceType.WATER}):CreateGrid()
  local count = a.Nnodes
  local dry = coord(-5000)
  land.surfaceAt=function(c) return c.x==dry.x and c.z==dry.z and land.SurfaceType.LAND or land.SurfaceType.WATER end
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
  a:SetEndCoordinate(s.vector)
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

local function nodeAtIndex(search, first, second)
  local cell=search:GetGrid():GetCellFromIndex(first,second)
  return cell and search._CellNodes[cell.id]
end

local function hexgrid(width, margin, spacing)
  local a = ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(4000))
  a:SetGridOptions({Width=width or 4000,Margin=margin or 2000,Spacing=spacing or 1000}):SetValidSurfaceTypes({land.SurfaceType.WATER}):CreateHexGrid()
  return a
end
local function count(entries)
  local n = 0 for _ in pairs(entries) do n = n + 1 end return n
end

test("hex geometry has six unique equidistant neighbours", function()
  local a = hexgrid():SetGridNeighboursOnly()
  local center = nodeAtIndex(a,2,0)
  local neighbours = a:_NeighbourNodes(center, a.nodes)
  equal(#neighbours, 6)
  local seen = {}
  for _, node in ipairs(neighbours) do
    assert(not seen[node.id]) seen[node.id] = true
    near(center.vector:GetDistance(node.vector, true), 1000)
    local dq, dr = node.q-center.q, node.r-center.r
    equal(math.max(math.abs(dq), math.abs(dr), math.abs(dq+dr)), 1)
    assert(a.gridLinks[node.id][center.id])
  end
  equal(count(a.nodes), a.Nnodes)
end)

test("hex defaults, center bounds and markers", function()
  local a = ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(4000))
  a:CreateHexGrid()
  equal(a.hexGrid.spacing, 2000)
  assert(nodeAtIndex(a,-5,0)) assert(nodeAtIndex(a,7,0))
  local marks = 0
  trigger.action.markToAll=function(_,text) assert(text:match("Hex: q=")) marks = marks + 1 end
  local b = ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(4300))
  b:SetGridOptions({Width=3700,Margin=1700,Spacing=1000}):SetValidSurfaceTypes(nil):CreateHexGrid()
  b:MarkGrid() flushTimers()
  equal(marks, b.Nnodes)
  for _, node in pairs(b.nodes) do
    assert(node.vector.x >= -1700-1e-8 and node.vector.x <= 6000+1e-8)
    assert(math.abs(node.vector.z) <= 1850+1e-8)
    equal(node.vector.y, 0)
  end
end)

test("hex geometry rotates with heading and translates with the origin", function()
  for _, heading in ipairs({0, 37, 90, 180, 275}) do
    local origin = coord(123456, -234567)
    local a = ASTAR:New():SetStartCoordinate(origin):SetEndCoordinate(origin:Translate(4000, heading))
    a:SetGridOptions({Width=4000,Margin=2000,Spacing=1000}):SetValidSurfaceTypes(nil):CreateHexGrid():SetGridNeighboursOnly(true)
    near(nodeAtIndex(a,0,0).vector:GetDistance(origin, true), 0)
    near(nodeAtIndex(a,4,0).vector:GetDistance(a.endVector, true), 0)
    local center = nodeAtIndex(a,2,0)
    equal(#a:_NeighbourNodes(center, a.nodes), 6)
    for _, node in ipairs(a:_NeighbourNodes(center, a.nodes)) do
      near(center.vector:GetDistance(node.vector, true), 1000)
    end
    equal(#a:GetPath(), 5)
  end
end)

test("hex candidate mode is optional and composes with validity rules", function()
  local a = hexgrid():SetGridNeighboursOnly(false)
  equal(#a:GetPath(), 2)
  a:SetGridNeighboursOnly(true)
  local center = nodeAtIndex(a,2,0)
  local requests = a.nvalid
  equal(#a:_NeighbourNodes(center, a.nodes), 6)
  equal(a.nvalid-requests, 6)
  equal(#a:GetPath(), 5)
  a:SetValidNeighbourFunction(function() return false end)
  equal(a:GetPath(), nil)
  a:SetValidNeighbourFunction(nil)
  a:SetGridNeighboursOnly(false)
  equal(#a:GetPath(), 2)
  a:SetGridNeighboursOnly(true)
  equal(#a:GetPath(), 5)
end)

test("hex surface holes do not create jumps or wraparound edges", function()
  land.surfaceAt = function(c) return math.abs(c.x-2000)<1e-6 and land.SurfaceType.LAND or land.SurfaceType.WATER end
  local a = hexgrid(0, 0):SetGridNeighboursOnly(true)
  equal(a.Nnodes, 4)
  assert(not a:GetGrid().hexIndex[2])
  equal(a:GetPath(), nil)
  equal(#a:_NeighbourNodes(nodeAtIndex(a,1,0), a.nodes), 1)
  a:SetGridNeighboursOnly(false)
  equal(#a:GetPath(), 2)
end)

test("hex search detours around a filtered center", function()
  land.surfaceAt = function(c)
    return math.abs(c.x-2000)<1e-6 and math.abs(c.z)<1e-6 and land.SurfaceType.LAND or land.SurfaceType.WATER
  end
  local a = hexgrid():SetGridNeighboursOnly(true)
  local path = a:GetPath()
  assert(path and #path > 5)
  for i, node in ipairs(path) do
    equal(node.surfacetype, land.SurfaceType.WATER)
    if i > 1 then near(path[i-1].vector:GetDistance(node.vector, true), 1000) end
  end
end)

test("hex attachments match geometric neighbours across rotations", function()
  for _, heading in ipairs({0, 37, 90, 180, 275}) do
    local origin = coord(-654321, 234567)
    local a = ASTAR:New():SetStartCoordinate(origin):SetEndCoordinate(origin:Translate(4000, heading))
    a:SetGridOptions({Width=4000,Margin=2000,Spacing=1000}):SetValidSurfaceTypes(nil):CreateHexGrid():SetGridNeighboursOnly(true)
    local extras = {}
    for _, offset in ipairs({{-300,100}, {1700,350}, {4000,2000}, {9000,0}, {0,0}}) do
      local c = origin:Translate(offset[1], heading):Translate(offset[2], heading+90)
      extras[#extras+1] = a:AddNodeFromCoordinate(c)
    end
    a:_BuildGridLinks()
    for _, extra in ipairs(extras) do
      local expected = 0
      for _, node in pairs(a.nodes) do
        if node.q ~= nil then
          local close = extra.vector:GetDistance(node.vector, true) <= 1000+1e-6
          equal(not not a.gridLinks[extra.id][node.id], close)
          equal(not not a.gridLinks[node.id][extra.id], close)
          if close then expected = expected+1 end
        else
          equal(a.gridLinks[extra.id][node.id], nil)
        end
      end
      equal(count(a.gridLinks[extra.id]), expected)
    end
    equal(count(a.gridLinks[extras[4].id]), 0)
  end
end)

test("hex mode keeps nearby endpoints exact and reuses them", function()
  local a = hexgrid():SetGridNeighboursOnly(true)
  a:SetStartCoordinate(coord(-300, 100)):SetEndCoordinate(coord(4300, 100))
  local path = a:GetPath()
  assert(path)
  near(path[1].vector:GetDistance(a.startVector, true), 0)
  near(path[#path].vector:GetDistance(a.endVector, true), 0)
  equal(path[1].q, nil) equal(path[#path].q, nil)
  local nodeCount = a.Nnodes
  equal(#a:GetPath(), #path)
  equal(a.Nnodes, nodeCount)
  equal(#a:GetPath(true, true), #path-2)
end)

test("hex endpoint attachments obey LoS and corridor checks", function()
  local a = hexgrid():SetGridNeighboursOnly(true):SetValidNeighbourLoS(500)
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
  local a = hexgrid():SetGridNeighboursOnly(true)
  a:SetEndCoordinate(coord(20000))
  equal(a:GetPath(), nil)
  local b = hexgrid():SetGridNeighboursOnly(true)
  local dry = coord(100, 100) land.surfaceAt=function(c) return c.x==dry.x and c.z==dry.z and land.SurfaceType.LAND or land.SurfaceType.WATER end
  b:SetStartCoordinate(dry)
  equal(b:GetPath(), nil)
  local empty = ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(4000))
  empty:SetGridOptions({Width=4000,Margin=0,Spacing=1000}):SetValidSurfaceTypes(land.SurfaceType.LAND):CreateHexGrid():SetGridNeighboursOnly(true)
  equal(empty.Nnodes, 0) equal(empty:GetPath(), nil)
end)

test("manual nodes added after a search rebuild hex attachments", function()
  local a = hexgrid():SetGridNeighboursOnly(true)
  assert(a:GetPath())
  local oldLinks = a.gridLinks
  local extra = a:AddNodeFromCoordinate(coord(1700, 250))
  equal(a.gridLinks, nil)
  a:SetEndCoordinate(extra.vector)
  local path = a:GetPath()
  equal(path[#path], extra)
  assert(a.gridLinks ~= oldLinks)
  assert(count(a.gridLinks[extra.id]) > 0)
  local n = a.Nnodes
  a:AddNode(nodeAtIndex(a,0,0))
  equal(a.Nnodes, n)
  assert(a:GetPath())
end)

test("hex zero-length route and empty exclusions", function()
  local a = ASTAR:New():SetStartCoordinate(coord(10, 20)):SetEndCoordinate(coord(10, 20))
  a:SetGridOptions({Width=0,Margin=0,Spacing=1000}):SetValidSurfaceTypes(nil):CreateHexGrid():SetGridNeighboursOnly(true)
  equal(a.Nnodes, 1)
  equal(#a:GetPath(), 1)
  equal(#a:GetPath(true, true), 0)
end)

test("invalid hex setup is rejected before adding nodes", function()
  equal(pcall(function() ASTAR:New():CreateHexGrid() end), false)
  equal(pcall(function() ASTAR:New():SetGridNeighboursOnly(true) end), false)
  ASTAR:New():SetGridNeighboursOnly(false)
  for _, args in ipairs({{4000,0,0}, {4000,0,-1}, {4000,0,math.huge}, {4000,0,0/0}, {-1,0,1000}, {4000,-1,1000}}) do
    local a = ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(4000))
    equal(pcall(function() a:SetGridOptions({Width=args[1],Margin=args[2],Spacing=args[3]}):CreateHexGrid() end), false)
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
  local a = hexgrid():SetGridNeighboursOnly(true)
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
  local a = hexgrid():SetGridNeighboursOnly(true)
  local b = hexgrid():SetGridNeighboursOnly(true)
  assert(a:GetPath()) assert(b:GetPath())
  assert(a.hexGrid ~= b.hexGrid and a._CellNodes ~= b._CellNodes and a.gridLinks ~= b.gridLinks)
  local n = b.Nnodes
  a:AddNodeFromCoordinate(coord(100, 100))
  equal(b.Nnodes, n)
  assert(b:GetPath())
end)

test("potential path rejects separated hex components before any expensive query", function()
  land.surfaceAt = function(c) return c.x==2000 and land.SurfaceType.LAND or land.SurfaceType.WATER end
  local a = hexgrid(0, 0):SetGridNeighboursOnly(true):SetValidNeighbourLoS(500):SetCostRoad()
  land.isVisible = function() error("Disconnected precheck must not query LoS") end
  land.findPathOnRoads = function() error("Disconnected precheck must not query roads") end
  a._LowestFscore = function() error("Disconnected precheck must not start A*") end
  equal(a:HasPotentialPath(), false)
  equal(a:GetPath(), nil)
  equal(a.nvalid, 0) equal(a.ncost, 0)
end)

test("potential path is not a promise that rules or costs permit a route", function()
  local a = hexgrid(0, 0):SetGridNeighboursOnly(true)
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
  local a = hexgrid():SetGridNeighboursOnly(true)
  a:SetStartCoordinate(coord(-300,100)):SetEndCoordinate(coord(4300,100))
  equal(a:HasPotentialPath(), true)
  near(a.startNode.vector:GetDistance(a.startVector, true), 0)
  near(a.endNode.vector:GetDistance(a.endVector, true), 0)
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
  local a = hexgrid(0, 0):SetGridNeighboursOnly(true)
  equal(a:HasPotentialPath(), false)
  local components = a.gridComponents
  local labelled = count(components)
  equal(labelled, 2)
  a:SetEndCoordinate(nodeAtIndex(a,1,0).vector)
  equal(a:HasPotentialPath(), true)
  equal(a.gridComponents, components)
  equal(count(components), labelled)
  a:SetStartCoordinate(nodeAtIndex(a,4,0).vector):SetEndCoordinate(nodeAtIndex(a,3,0).vector)
  equal(a:HasPotentialPath(), true)
  equal(count(components), 4)
  a:SetStartCoordinate(nodeAtIndex(a,0,0).vector):SetEndCoordinate(nodeAtIndex(a,4,0).vector)
  equal(a:HasPotentialPath(), false)
  -- An explicitly supplied node can bridge the gap; manual nodes bypass the grid surface filter.
  a:AddNodeFromCoordinate(coord(2000))
  equal(a:HasPotentialPath(), true)
  assert(a.gridComponents ~= components)
  assert(a:GetPath())
end)

test("potential path never rejects all-pairs jumps across disconnected hex cells", function()
  land.surfaceAt = function(c) return c.x==2000 and land.SurfaceType.LAND or land.SurfaceType.WATER end
  local a = hexgrid(0, 0):SetGridNeighboursOnly(true)
  equal(a:HasPotentialPath(), false)
  a:SetGridNeighboursOnly(false)
  equal(a:HasPotentialPath(), true)
  equal(#a:GetPath(), 2)
  a:SetGridNeighboursOnly(true)
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
  empty:SetGridOptions({Width=4000,Margin=1000,Spacing=1000}):SetValidSurfaceTypes({}):CreateHexGrid():SetGridNeighboursOnly(true)
  equal(empty:HasPotentialPath(), false)
  local a = hexgrid():SetGridNeighboursOnly(true)
  local dry = coord(100,100) land.surfaceAt=function(c) return c.x==dry.x and c.z==dry.z and land.SurfaceType.LAND or land.SurfaceType.WATER end
  a:SetStartCoordinate(dry)
  equal(a:HasPotentialPath(), false)
  a:SetStartCoordinate(nodeAtIndex(a,0,0).vector):SetEndCoordinate(nodeAtIndex(a,0,0).vector)
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
    a:SetGridOptions({Width=4000,Margin=2000,Spacing=1000}):SetValidSurfaceTypes(nil):CreateHexGrid()
    local cells = a.Nnodes
    a:AddNodeFromCoordinate(origin:Translate(100, heading))
    equal(a:DrawGrid(), a)
  flushTimers()
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
      if closest == nodeAtIndex(a,0,0) then centerPolygon = vertices end
      if closest == nodeAtIndex(a,1,0) then adjacentPolygon = vertices end
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
  a:SetGridOptions({Width=2000,Margin=0,Spacing=2000,CrossSpacing=1000}):SetValidSurfaceTypes(nil):CreateGrid()
  local originalCount = a.Nnodes
  local b=ASTAR:New():SetStartCoordinate(coord(10000)):SetEndCoordinate(coord(10000,4000))
  b:SetGridOptions({Width=2000,Margin=0,Spacing=1000,CrossSpacing=2000}):CreateGrid()
  b:DrawGrid()
  a:DrawGrid()
  flushTimers()
  equal(count(drawings), a.Nnodes+b.Nnodes)
  local firstGridCount = 0
  for _, drawing in pairs(drawings) do
    equal(#drawing.vertices, 4)
    local center = polygonCenter(drawing.vertices)
    local owner=center.x<5000 and a or b
    local node, d = owner:FindClosestNode(center)
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
  local a = hexgrid():SetGridNeighboursOnly(true)
  local path = a:GetPath()
  drawings[42] = {text="unrelated mark"}
  a:DrawGrid()
  flushTimers()
  local old = deepcopy(a.GridDrawIDs)
  local n = #old
  a:DrawGrid()
  flushTimers()
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
  flushTimers()
  equal(outline[4], nil) equal(fill[4], nil)
  for _, d in pairs(drawings) do
    equal(d.coalition, 0) equal(d.color[4], 0) equal(d.fill[4], 0)
    equal(d.lineType, 0) equal(d.readOnly, false)
    equal(d.color[1], 1) equal(d.fill[2], 0.3)
  end
  a:DrawGrid(2, outline, 0.8, nil, 0.1, 2)
  flushTimers()
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
  flushTimers()
  equal(count(drawings), 0)
  land.surfaceAt = function(c) return c.x==2000 and land.SurfaceType.LAND or land.SurfaceType.WATER end
  local a = hexgrid(0, 0)
  local accepted = a.Nnodes
  equal(accepted, 4)
  a:AddNodeFromCoordinate(coord(2000))
  a:DrawGrid()
  flushTimers()
  equal(count(drawings), accepted)
  for _, drawing in pairs(drawings) do assert(polygonCenter(drawing.vertices).x ~= 2000) end
  local empty = ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(1000))
  empty:SetGridOptions({Width=2000,Margin=0,Spacing=1000,CrossSpacing=1000}):SetValidSurfaceTypes({}):CreateGrid():DrawGrid()
  flushTimers()
  equal(#empty.GridDrawIDs, 0)
end)

test("F10 overlays from different ASTAR instances are independent", function()
  resetDrawings()
  local a, b = hexgrid(0,0), hexgrid(0,0)
  a:DrawGrid() b:DrawGrid()
  flushTimers()
  local ids = deepcopy(b.GridDrawIDs)
  a:UndrawGrid()
  equal(count(drawings), #ids)
  for _, id in ipairs(ids) do assert(drawings[id]) end
end)

test("expanding search finds a detour around land and preserves existing nodes", function()
  land.surfaceAt = function(c)
    return c.x>=1500 and c.x<=2500 and math.abs(c.z)<1200 and land.SurfaceType.LAND or land.SurfaceType.WATER
  end
  local a = hexgrid(0,0):SetGridNeighboursOnly(true)
  equal(a:HasPotentialPath(), false)
  local original = {}
  for id, node in pairs(a.nodes) do original[id]=node end
  local path, report = a:GetPathWithExpansion()
  assert(path and #report.Attempts>1)
  equal(report.Attempts[1].Failure, "disconnected_grid")
  equal(report.StopReason, "path_found") equal(report, a.LastExpansionResult)
  equal(a.hexGrid.spacing, 1000) equal(a.LastPathFailure, nil)
  for id, node in pairs(original) do equal(a.nodes[id], node) end
  local detour = false
  for _, node in ipairs(path) do
    equal(node.surfacetype, land.SurfaceType.WATER)
    if math.abs(node.vector.z)>=1200 then detour=true end
  end
  assert(detour)
end)

test("expanding search continues when LoS blocks an otherwise connected grid", function()
  local a = hexgrid(0,0):SetGridNeighboursOnly(true):SetValidNeighbourLoS()
  land.isVisible = function(u,v)
    if u.x==v.x then return true end
    local t=(2000-u.x)/(v.x-u.x)
    if t>=0 and t<=1 then return math.abs(u.z+t*(v.z-u.z))>=1200 end
    return true
  end
  equal(a:HasPotentialPath(), true)
  local path, report = configureExpansion(a,{GrowthFactor=2, MaxAttempts=5}):GetPathWithExpansion()
  assert(path)
  equal(report.Attempts[1].Failure, "connections_blocked")
  assert(#report.Attempts>1)
  for i=2,#path do assert(land.isVisible(path[i-1].vector, path[i].vector)) end
end)

test("expanding search preserves custom callback references and arguments", function()
  local a = hexgrid(0,0):SetGridNeighboursOnly(true)
  local original = nodeAtIndex(a,0,0)
  local evaluated = false
  local function cost(u,v,scale)
    equal(scale, 7)
    if u==original or v==original then evaluated=true end
    if math.abs(u.vector.z)<1200 and math.abs(v.vector.z)<1200 then return math.huge end
    return ASTAR.Dist2D(u,v)*scale
  end
  -- Let the first/last sections reach the outer rows; block only the central crossing.
  local function constrainedCost(u,v,scale)
    if (u.vector.x<=2000 and v.vector.x>=2000) or (v.vector.x<=2000 and u.vector.x>=2000) then
      return cost(u,v,scale)
    end
    if u==original or v==original then evaluated=true end
    equal(scale,7)
    return ASTAR.Dist2D(u,v)*scale
  end
  a:SetCostFunction(constrainedCost, 7)
  local path, report = a:GetPathWithExpansion()
  assert(path and evaluated)
  equal(report.Attempts[1].Failure, "connections_blocked")
  equal(a.CostFunc, constrainedCost) equal(nodeAtIndex(a,0,0), original)
end)

test("expansion attaches endpoints outside the initial search area", function()
  local a = hexgrid(0,0):SetGridNeighboursOnly(true)
  a:SetStartCoordinate(coord(-2500)):SetEndCoordinate(coord(6500))
  local potential, reason = a:HasPotentialPath()
  equal(potential, false) equal(reason, "start_unattached")
  local path, report = a:GetPathWithExpansion()
  assert(path and #report.Attempts>1)
  near(path[1].vector:GetDistance(a.startVector, true),0)
  near(path[#path].vector:GetDistance(a.endVector, true),0)
  equal(a.hexGrid.x,0) equal(a.hexGrid.distance,4000)
end)

test("expansion honours attempt and dimension limits", function()
  for _, limits in ipairs({
    {options={MaxAttempts=1}, reason="attempt_limit"},
    {options={MaxWidth=0,MaxMargin=0}, reason="size_limit"}
  }) do
    local a = hexgrid(0,0):SetGridNeighboursOnly(true):SetValidNeighbourFunction(function() return false end)
    local path, report = configureExpansion(a,limits.options):GetPathWithExpansion()
    equal(path,nil) equal(report.StopReason, limits.reason) equal(#report.Attempts,1)
    equal(a.hexGrid.width,0) equal(a.hexGrid.margin,0)
  end
end)

test("expansion checks candidate cell budget before sampling or modifying nodes", function()
  local a = hexgrid(0,0):SetGridNeighboursOnly(true):SetValidNeighbourFunction(function() return false end)
  local n, counter = a.Nnodes, a.counter
  land.surfaceAt = function() error("Budget check must precede new surface sampling") end
  local path, report = configureExpansion(a,{MaxCells=5}):GetPathWithExpansion()
  equal(path,nil) equal(report.StopReason,"cell_limit") equal(#report.Attempts,1)
  equal(a.Nnodes,n) equal(a.counter,counter)
  equal(a.hexGrid.width,0) equal(a.hexGrid.margin,0)
  path, report = configureExpansion(a,{MaxCells=1}):GetPathWithExpansion()
  equal(path,nil) equal(report.StopReason,"cell_limit") equal(#report.Attempts,0)
end)

test("hex enlargement never resamples old filtered cells or duplicates nodes", function()
  local sampled = {}
  land.surfaceAt = function(c)
    local key=string.format("%.4f %.4f",c.x,c.z)
    assert(not sampled[key],"Cell sampled twice") sampled[key]=true
    return c.x==2000 and land.SurfaceType.LAND or land.SurfaceType.WATER
  end
  local a = hexgrid(0,0)
  configureExpansion(a,{MaxCells=5000}):ExpandGrid(4000,2000)
  local candidates, n, counter = a.hexGrid.candidateCount, a.Nnodes, a.counter
  equal(count(sampled),candidates)
  configureExpansion(a,{MaxCells=5000}):ExpandGrid(4000,2000)
  equal(a.Nnodes,n) equal(a.counter,counter)
  configureExpansion(a,{MaxCells=5000}):ExpandGrid(6000,3000)
  equal(count(sampled),a.hexGrid.candidateCount)
  equal(count(a.nodes),a.Nnodes)
end)

test("rotated enlargement matches a newly built larger lattice", function()
  local origin=coord(123456,-234567)
  local goal=origin:Translate(4000,37)
  local a=ASTAR:New():SetStartCoordinate(origin):SetEndCoordinate(goal)
  a:SetGridOptions({Width=1000,Margin=0,Spacing=1000}):SetValidSurfaceTypes(nil):CreateHexGrid():ExpandGrid(6000,3000)
  local b=ASTAR:New():SetStartCoordinate(origin):SetEndCoordinate(goal)
  b:SetGridOptions({Width=6000,Margin=3000,Spacing=1000}):SetValidSurfaceTypes(nil):CreateHexGrid()
  equal(a.Nnodes,b.Nnodes)
  for _, node in pairs(a.nodes) do
    near(node.vector:GetDistance(nodeAtIndex(b,node.q,node.r).vector, true),0)
  end
end)

test("expansion adds missing F10 cells without replacing existing marks or style", function()
  resetDrawings()
  local a=hexgrid(0,0):SetGridNeighboursOnly(true):SetValidNeighbourFunction(function() return false end)
  a:DrawGrid(2,{0,0.5,1},0.8,nil,0.1,2,false)
  flushTimers()
  local oldIDs=deepcopy(a.GridDrawIDs)
  local path, report=configureExpansion(a,{MaxAttempts=3}):GetPathWithExpansion()
  equal(path,nil) equal(report.StopReason,"attempt_limit")
  equal(#removals,0)
  a:UpdateGridDrawing()
  flushTimers()
  for _,id in ipairs(oldIDs) do assert(drawings[id]) end
  equal(count(drawings),a.Nnodes)
  for _, drawing in pairs(drawings) do
    equal(drawing.coalition,2) equal(drawing.color[4],0.8) equal(drawing.fill[4],0.1)
    equal(drawing.lineType,2) equal(drawing.readOnly,false)
  end
  local n=#a.GridDrawIDs
  configureExpansion(a,{MaxAttempts=2}):GetPathWithExpansion()
  equal(#a.GridDrawIDs,n) equal(#removals,0)
end)

test("successful empty paths stop expansion immediately", function()
  local a=hexgrid(0,0):SetGridNeighboursOnly(true)
  a:SetEndCoordinate(a.startVector)
  local path, report=a:GetPathWithExpansion(true,true)
  equal(#path,0) equal(report.StopReason,"path_found") equal(#report.Attempts,1)
  equal(a.hexGrid.width,0)
end)

test("expansion rejects invalid limits and handles missing coordinates", function()
  equal(pcall(function() ASTAR:New():GetPathWithExpansion() end),false)
  for _, options in ipairs({{GrowthFactor=1},{MaxAttempts=0},{MaxCells=0},{MaxWidth=-1},{MaxMargin=math.huge}}) do
    local a=hexgrid(0,0):SetGridNeighboursOnly(true)
    equal(pcall(function() configureExpansion(a,options):GetPathWithExpansion() end),false)
    equal(a.hexGrid.width,0) equal(a.hexGrid.margin,0)
  end
  local a=hexgrid(0,0):SetGridNeighboursOnly(true)
  a:SetStartCoordinate(nil)
  local path, report=a:GetPathWithExpansion()
  equal(path,nil) equal(report.StopReason,"missing_coordinates") equal(#report.Attempts,1)
  equal(a.hexGrid.width,0)
end)


test("initial grid budgets reject before sampling or changing object state", function()
  for _, builder in ipairs({
    function(a, limit) return a:SetGridOptions({Width=0,Margin=0,Spacing=1000,CrossSpacing=1000,MaxCells=limit}):SetValidSurfaceTypes({}):CreateGrid() end,
    function(a, limit) return a:SetGridOptions({Width=0,Margin=0,Spacing=1000,MaxCells=limit}):SetValidSurfaceTypes({}):CreateHexGrid() end
  }) do
    local a=ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(4000))
    a:SetValidSurfaceTypes(land.SurfaceType.WATER)
    local nodes, counter=a.nodes, a.counter
    land.surfaceAt=function() error("Rejected creation must not sample terrain") end
    local result, reason=builder(a,4)
    equal(result,nil) equal(reason,"cell_limit")
    equal(a.nodes,nodes) equal(a.Nnodes,0) equal(a.counter,counter)
    equal(#a:GetGrid().ValidSurfaceTypes,0)
    equal(a.hexGrid,nil) equal(a:GetGrid().hexIndex,nil)
    -- A rejected hex build must leave the object reusable, even for a different grid type.
    land.surfaceAt=nil
    equal(a:SetGridOptions({Width=0,Margin=0,Spacing=1000,CrossSpacing=1000,MaxCells=5}):SetValidSurfaceTypes(nil):CreateGrid(),a)
    equal(a.Nnodes,5)
  end
end)

test("initial budgets reject enormous grids without integer overflow or terrain queries", function()
  local a=ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(4000000000))
  land.surfaceAt=function() error("Oversized grid must be rejected before sampling") end
  local result, reason=a:SetGridOptions({Width=4000000000,Margin=0,Spacing=1,CrossSpacing=1,MaxCells=5}):SetValidSurfaceTypes(nil):CreateGrid()
  equal(result,nil) equal(reason,"cell_limit") equal(a.Nnodes,0)
  a:GetGrid():SetSpacing(1)
  result, reason=a:SetGridOptions({Width=0,Margin=9e18,Spacing=1,MaxCells=5}):SetValidSurfaceTypes(nil):CreateHexGrid()
  equal(result,nil) equal(reason,"cell_limit") equal(a.hexGrid,nil) equal(a.Nnodes,0)
end)

test("initial grid budgets count filtered cells and allow the exact limit", function()
  for _, builder in ipairs({
    function(a, limit) return a:SetGridOptions({Width=0,Margin=0,Spacing=1000,CrossSpacing=1000,MaxCells=limit}):SetValidSurfaceTypes({}):CreateGrid() end,
    function(a, limit) return a:SetGridOptions({Width=0,Margin=0,Spacing=1000,MaxCells=limit}):SetValidSurfaceTypes({}):CreateHexGrid() end
  }) do
    local a=ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(4000))
    local calls=0
    land.surfaceAt=function() calls=calls+1 return land.SurfaceType.WATER end
    equal(builder(a,4),nil) equal(calls,0)
    equal(builder(a,5),a) equal(calls,5) equal(a.Nnodes,0)
    if a.hexGrid then equal(a.hexGrid.candidateCount,5) end
  end
end)

test("rectangular budgets exclude manual nodes and an existing grid cannot be rebuilt", function()
  local a=ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(4000))
  local manual=a:AddNodeFromCoordinate(coord(-5000))
  equal(a:SetGridOptions({Width=0,Margin=0,Spacing=1000,CrossSpacing=1000,MaxCells=5}):SetValidSurfaceTypes(nil):CreateGrid(),a)
  equal(a.Nnodes,6) equal(a.nodes[manual.id],manual)
  local counter=a.counter
  equal(pcall(function() a:CreateGrid() end),false)
  equal(pcall(function() a:SetValidSurfaceTypes({}) end),false)
  equal(a.Nnodes,6) equal(a.counter,counter) equal(a:GetGrid().ValidSurfaceTypes,nil)
end)

test("rectangular fractional dimensions preserve rotated lattice coordinates and order", function()
  for _, heading in ipairs({0,37,90,180,275}) do
    local origin=coord(123456,-234567)
    local a=ASTAR:New():SetStartCoordinate(origin):SetEndCoordinate(origin:Translate(2500,heading))
    equal(a:SetGridOptions({Width=2500,Margin=100,Spacing=1000,CrossSpacing=1000,MaxCells=9}):SetValidSurfaceTypes(nil):CreateGrid(),a)
    equal(a.Nnodes,9)
    local nodes={}
    for _, node in pairs(a.nodes) do nodes[#nodes+1]=node end
    table.sort(nodes,function(u,v) return u.id<v.id end)
    for i=1,3 do
      for j=1,3 do
        local expected=origin:Translate(-100+1000*(j-1),heading):Translate(-1250+1000*(i-1),heading+90)
        near(nodes[(i-1)*3+j].vector:GetDistance(expected, true),0)
      end
    end
  end
end)

test("grid creation validates dimensions and budgets before mutation", function()
  local a=ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(4000))
  local counter=a.counter
  for _, limit in ipairs({0,-1,1.5,math.huge,"5",false}) do
    equal(pcall(function() a:SetGridOptions({Width=0,Margin=0,Spacing=1000,CrossSpacing=1000,MaxCells=limit}):SetValidSurfaceTypes(nil):CreateGrid() end),false)
    equal(pcall(function() a:SetGridOptions({Width=0,Margin=0,Spacing=1000,MaxCells=limit}):SetValidSurfaceTypes(nil):CreateHexGrid() end),false)
  end
  for _, args in ipairs({{-1,0,1000,1000},{0,-1,1000,1000},{0,0,0,1000},{0,0,1000,0},{0,0,math.huge,1000}}) do
    equal(pcall(function() a:SetGridOptions({Width=args[1],Margin=args[2],Spacing=args[3],CrossSpacing=args[4]}):CreateGrid() end),false)
  end
  equal(a.Nnodes,0) equal(a.counter,counter) equal(a.hexGrid,nil)
end)

-- Capture player messages as well as error logs, restoring the shared stub even if a search throws.
local function captureSearchReports(a, run)
  local errors, messages={},{}
  function a:E(text) errors[#errors+1]=text end
  a.Debug=true
  local original=MESSAGE.New
  MESSAGE.New=function(_,text)
    return {ToAllIf=function(_,enabled) if enabled then messages[#messages+1]=text end end}
  end
  local ok, path, report=pcall(run)
  MESSAGE.New=original
  assert(ok,path)
  return path, report, errors, messages
end

test("successful expansion reports retries without errors or player failure messages", function()
  land.surfaceAt=function(c)
    return c.x>=1500 and c.x<=2500 and math.abs(c.z)<1200 and land.SurfaceType.LAND or land.SurfaceType.WATER
  end
  local a=hexgrid(0,0):SetGridNeighboursOnly(true)
  local path, report, errors, messages=captureSearchReports(a,function() return a:GetPathWithExpansion() end)
  assert(path and #report.Attempts>1)
  equal(report.Attempts[1].Failure,"disconnected_grid")
  equal(report.StopReason,"path_found") equal(a.LastPathFailure,nil)
  equal(#errors,0) equal(#messages,0)
end)

test("exhausted expansion announces only the final failure and preserves attempt reasons", function()
  local a=hexgrid(0,0):SetGridNeighboursOnly(true):SetValidNeighbourFunction(function() return false end)
  local path, report, errors, messages=captureSearchReports(a,function() return configureExpansion(a,{MaxAttempts=3}):GetPathWithExpansion() end)
  equal(path,nil) equal(report.StopReason,"attempt_limit") equal(#report.Attempts,3)
  for _, attempt in ipairs(report.Attempts) do equal(attempt.Failure,"connections_blocked") end
  equal(a.LastPathFailure,"connections_blocked") equal(#errors,1) equal(#messages,1)
  assert(errors[1]:find("connections_blocked",1,true)) assert(errors[1]:find("attempt_limit",1,true))
  -- Rejecting a later request before searching must not reuse the previous failure reason.
  path, report, errors, messages=captureSearchReports(a,function() return configureExpansion(a,{MaxCells=1}):GetPathWithExpansion() end)
  equal(path,nil) equal(#report.Attempts,0) equal(report.StopReason,"cell_limit")
  equal(a.LastPathFailure,nil) equal(#errors,1) equal(#messages,1)
  assert(not errors[1]:find("connections_blocked",1,true))
end)

test("ordinary search still announces failure and resets it after success", function()
  local a=pair()
  a:SetValidNeighbourFunction(function() return false end)
  local path, _, errors, messages=captureSearchReports(a,function() return a:GetPath() end)
  equal(path,nil) equal(a.LastPathFailure,"connections_blocked") equal(#errors,1) equal(#messages,1)
  a:SetValidNeighbourFunction(nil)
  path, _, errors, messages=captureSearchReports(a,function() return a:GetPath() end)
  equal(#path,2) equal(a.LastPathFailure,nil) equal(#errors,0) equal(#messages,0)
end)

test("long predecessor paths preserve ordering, suffix and table identity", function()
  local a=ASTAR:New()
  local nodes, predecessors={},{}
  for i=1,12000 do
    nodes[i]={id=i}
    predecessors[nodes[i]]=nodes[i-1]
  end
  local suffix={id="suffix"}
  local output={nodes[#nodes],suffix}
  equal(a:_UnwindPath(output,predecessors,nodes[#nodes]),output)
  equal(#output,#nodes+1)
  for i,node in ipairs(nodes) do equal(output[i],node) end
  equal(output[#output],suffix)
  local empty={}
  equal(a:_UnwindPath(empty,predecessors,nodes[1]),empty) equal(#empty,0)
end)


test("large overlays return before drawing and respect batch sizes and intervals", function()
  resetDrawings()
  local a=hexgrid()
  equal(a:DrawGrid(nil,nil,nil,nil,nil,nil,nil,{BatchSize=3,Interval=0.2}),a)
  equal(count(drawings),0) equal(a.LastGridDrawResult.Status,"queued")
  equal(a.LastGridDrawResult.NodesQueued,a.Nnodes)
  local n=0
  while stepTimer() do
    local current=count(drawings)
    assert(current-n<=3 and current>n)
    n=current
  end
  equal(n,a.Nnodes) equal(a.GridDrawJob,nil)
  equal(a.LastGridDrawResult.Status,"complete")
  near(a.LastGridDrawResult.ElapsedSimulationSeconds,math.ceil(a.Nnodes/3)*0.2)
end)

test("updates extend pending drawings exactly once and preserve already drawn polygons", function()
  resetDrawings()
  local a=hexgrid():DrawGrid(nil,nil,nil,nil,nil,nil,nil,{BatchSize=2})
  stepTimer()
  local original=deepcopy(a.GridDrawIDs)
  local result=a.LastGridDrawResult
  a:ExpandGrid(6000,3000)
  a:UpdateGridDrawing():UpdateGridDrawing()
  equal(a.LastGridDrawResult,result) equal(result.NodesQueued,a.Nnodes)
  flushTimers()
  equal(count(drawings),a.Nnodes) equal(count(a.GridDrawCellIDs),a.Nnodes)
  equal(#removals,0)
  for _,id in ipairs(original) do assert(drawings[id]) end
  a:UpdateGridDrawing()
  equal(count(drawings),a.Nnodes) equal(a.LastGridDrawResult.NodesDrawn,0)
end)

test("undrawing cancels pending callbacks without resurrecting removed polygons", function()
  resetDrawings()
  local a=hexgrid():DrawGrid(nil,nil,nil,nil,nil,nil,nil,{BatchSize=2})
  local job=a.GridDrawJob
  local callback=scheduled[job.timerID]
  stepTimer()
  equal(count(drawings),2)
  a:UndrawGrid()
  equal(job.result.Status,"cancelled") equal(count(drawings),0) equal(next(scheduled),nil)
  equal(a.GridDrawOptions,nil) equal(a.GridDrawJob,nil)
  equal(callback.fn(callback.args,timerNow),nil)
  a:UpdateGridDrawing():UndrawGrid()
  equal(count(drawings),0) equal(#removals,2)
end)

test("redrawing mid-job cancels the old style and isolates other instances", function()
  resetDrawings()
  local a=hexgrid():DrawGrid(1,nil,nil,nil,nil,nil,nil,{BatchSize=2})
  local b=hexgrid(0,0):DrawGrid(2)
  local bIDs=deepcopy(b.GridDrawIDs)
  local old=a.GridDrawJob
  local callback=scheduled[old.timerID]
  stepTimer()
  a:DrawGrid(0,{0.1,0.2,0.3},0.7,nil,0.2,2,false,{BatchSize=3})
  equal(old.result.Status,"cancelled")
  equal(callback.fn(callback.args,timerNow),nil)
  flushTimers()
  for _,id in ipairs(a.GridDrawIDs) do
    local d=drawings[id]
    equal(d.coalition,0) equal(d.color[1],0.1) equal(d.color[4],0.7) equal(d.readOnly,false)
  end
  for _,id in ipairs(bIDs) do equal(drawings[id].coalition,2) end
  equal(count(drawings),a.Nnodes+b.Nnodes)
end)

test("expansion returns its path while an initial overlay is still queued", function()
  resetDrawings()
  land.surfaceAt=function(c)
    return c.x>=1500 and c.x<=2500 and math.abs(c.z)<1200 and land.SurfaceType.LAND or land.SurfaceType.WATER
  end
  local a=hexgrid(0,0):SetGridNeighboursOnly(true)
  a:DrawGrid(nil,nil,nil,nil,nil,nil,nil,{BatchSize=1})
  equal(#a.GridDrawIDs,0)
  local path, report=a:GetPathWithExpansion()
  assert(path and #report.Attempts>1)
  equal(#a.GridDrawIDs,0) equal(report.Drawing,nil)
  a:UpdateGridDrawing()
  equal(a.LastGridDrawResult.Status,"queued")
  flushTimers()
  equal(a.LastGridDrawResult.Status,"complete") equal(count(drawings),a.Nnodes)
  equal(#removals,0)
end)

test("expanding search leaves a pending initial overlay at its original size", function()
  resetDrawings()
  local a=hexgrid(0,0):SetGridNeighboursOnly(true):SetValidNeighbourFunction(function() return false end)
  local original=a.Nnodes
  a:DrawGrid(nil,nil,nil,nil,nil,nil,nil,{BatchSize=1})
  local _, report=configureExpansion(a,{MaxAttempts=2}):GetPathWithExpansion()
  equal(report.Drawing,nil)
  flushTimers()
  equal(count(drawings),original) assert(a.Nnodes>original)
end)

test("drawing errors terminate the job and allow missing cells to be retried", function()
  resetDrawings()
  local a=hexgrid():DrawGrid(nil,nil,nil,nil,nil,nil,nil,{BatchSize=3})
  local original=a._DrawGridCell
  local calls=0
  function a:_DrawGridCell(node,style)
    calls=calls+1
    if calls==2 then error("Injected drawing error") end
    return original(self,node,style)
  end
  flushTimers()
  equal(a.LastGridDrawResult.Status,"error") equal(a.LastGridDrawResult.NodesDrawn,1)
  assert(a.LastGridDrawResult.Error:find("Injected drawing error",1,true))
  equal(a.GridDrawJob,nil) equal(count(drawings),1)
  a._DrawGridCell=original
  a:UpdateGridDrawing()
  flushTimers()
  equal(a.LastGridDrawResult.Status,"complete") equal(count(drawings),a.Nnodes) equal(#removals,0)
end)

test("drawing options are validated before cancelling an existing overlay", function()
  resetDrawings()
  local a=hexgrid():DrawGrid()
  local job=a.GridDrawJob
  for _,options in ipairs({{BatchSize=0},{BatchSize=1.5},{Interval=0},{Interval=math.huge},{MaxBatchSeconds=0},{MaxBatchSeconds=math.huge},"invalid"}) do
    equal(pcall(function() a:DrawGrid(nil,nil,nil,nil,nil,nil,nil,options) end),false)
    equal(a.GridDrawJob,job) equal(job.result.Status,"queued")
  end
  flushTimers()
  equal(count(drawings),a.Nnodes)
end)

test("search and drawing CPU timings are separate from simulation waits", function()
  resetDrawings()
  local originalClock=os.clock
  local cpu=100
  os.clock=function() return cpu end
  local ok, err=pcall(function()
    local a=hexgrid(0,0):SetGridNeighboursOnly(true)
    a:SetStartCoordinate(coord(-2500)):SetEndCoordinate(coord(6500))
    a:SetValidNeighbourFunction(function() cpu=cpu+0.002 return true end)
    local original=a._DrawGridCell
    function a:_DrawGridCell(node,style) cpu=cpu+0.01 return original(self,node,style) end
    a:DrawGrid(nil,nil,nil,nil,nil,nil,nil,{BatchSize=2,Interval=0.1})
    local path, report=a:GetPathWithExpansion()
    assert(path and #report.Attempts>1)
    local search=cpu-100
    assert(search>0) near(report.SearchCPUSeconds,search)
    local attempts=0
    for _,attempt in ipairs(report.Attempts) do attempts=attempts+attempt.CPUSeconds end
    near(attempts,search)
    equal(report.Drawing,nil)
    a:UpdateGridDrawing()
    local drawing=a.LastGridDrawResult
    equal(drawing.NodesDrawn,0)
    flushTimers()
    near(report.SearchCPUSeconds,search)
    near(drawing.CPUSeconds,drawing.NodesDrawn*0.01)
    near(drawing.ElapsedSimulationSeconds,drawing.Batches*0.1)
    assert(a.LastSearchTiming.CPUSeconds>0)
  end)
  os.clock=originalClock
  assert(ok,err)
end)

test("sanitized os does not prevent drawing or claim a zero CPU duration", function()
  resetDrawings()
  local originalOS=os
  os=nil
  local ok, err=pcall(function()
    local a=hexgrid():SetGridNeighboursOnly(true)
    local traces={}
    function a:T(text) traces[#traces+1]=text end
    a:DrawGrid()
    local path, report=a:GetPathWithExpansion()
    assert(path) equal(report.SearchCPUSeconds,nil) equal(a.LastSearchTiming.CPUSeconds,nil)
    flushTimers()
    equal(a.LastGridDrawResult.Status,"complete") equal(a.LastGridDrawResult.CPUSeconds,nil)
    assert(table.concat(traces,"\n"):find("CPU time unavailable",1,true))
  end)
  os=originalOS
  assert(ok,err)
end)


test("CPU budget limits batches before the configured cell count is reached", function()
  resetDrawings()
  local a=hexgrid()
  local originalClock=os.clock
  local cpu=0
  os.clock=function() return cpu end
  local ok, err=pcall(function()
    local original=a._DrawGridCell
    function a:_DrawGridCell(node,style) cpu=cpu+0.003 return original(self,node,style) end
    a:DrawGrid(nil,nil,nil,nil,nil,nil,nil,{BatchSize=25,MaxBatchSeconds=0.005})
    local countBefore=0
    while stepTimer() do
      local n=count(drawings)
      assert(n-countBefore>=1 and n-countBefore<=2)
      countBefore=n
    end
    equal(countBefore,a.Nnodes)
    equal(a.LastGridDrawResult.Batches,math.ceil(a.Nnodes/2))
    near(a.LastGridDrawResult.MaxBatchCPUSeconds,0.006)
    near(a.LastGridDrawResult.CPUSeconds,a.Nnodes*0.003)
  end)
  os.clock=originalClock
  assert(ok,err)
end)

test("a small job that exceeds the time budget schedules its remaining cells", function()
  resetDrawings()
  local a=hexgrid(0,0)
  local originalClock=os.clock
  local cpu=0
  os.clock=function() return cpu end
  local ok, err=pcall(function()
    local original=a._DrawGridCell
    function a:_DrawGridCell(node,style) cpu=cpu+0.012 return original(self,node,style) end
    a:DrawGrid()
    equal(count(drawings),1) assert(a.GridDrawJob and a.GridDrawJob.timerID)
    flushTimers()
    equal(count(drawings),a.Nnodes) equal(a.LastGridDrawResult.Status,"complete")
    equal(a.LastGridDrawResult.Batches,a.Nnodes)
    near(a.LastGridDrawResult.MaxBatchCPUSeconds,0.012)
  end)
  os.clock=originalClock
  assert(ok,err)
end)

test("drawing uses one cell per scheduled batch when the CPU clock is sanitized", function()
  resetDrawings()
  local a=hexgrid()
  local originalOS=os
  os=nil
  local ok, err=pcall(function()
    a:DrawGrid()
    local n=0
    while stepTimer() do
      equal(count(drawings),n+1)
      n=n+1
    end
    equal(n,a.Nnodes) equal(a.LastGridDrawResult.MaxBatchCPUSeconds,nil)
    equal(a.LastGridDrawResult.CPUSeconds,nil) equal(a.LastGridDrawResult.Batches,n)
  end)
  os=originalOS
  assert(ok,err)
end)

test("grid rendering never constructs MOOSE coordinate objects for vertices", function()
  resetDrawings()
  local a=hexgrid()
  local original=COORDINATE.New
  COORDINATE.New=function() error("Polygon vertices must be plain Vec3 tables") end
  local ok, err=pcall(function()
    a:DrawGrid()
    flushTimers()
    equal(a.LastGridDrawResult.Status,"complete") equal(count(drawings),a.Nnodes)
  end)
  COORDINATE.New=original
  assert(ok,err)
end)

test("direct polygon calls match the existing MOOSE freeform API and global mark ids", function()
  resetDrawings()
  local rect=ASTAR:New():SetStartCoordinate(coord(1000,2000)):SetEndCoordinate(coord(2000,3000))
  rect:SetGridOptions({Width=2000,Margin=0,Spacing=1000,CrossSpacing=1000}):SetValidSurfaceTypes(nil):CreateGrid()
  for _,a in ipairs({rect,hexgrid()}) do
    local _,node=next(a.nodes)
    local style={Coalition=0,Color={0.2,0.3,0.4},Alpha=0,FillColor={0.5,0.6,0.7},FillAlpha=0.3,LineType=5,ReadOnly=false}
    local id=a:_DrawGridCell(node,style)
    local drawn=drawings[id]
    local coords={}
    for _,v in ipairs(drawn.vertices) do coords[#coords+1]=coord(v.x,v.z,v.y) end
    local first=table.remove(coords,1)
    local referenceID=first:MarkupToAllFreeForm(coords,style.Coalition,deepcopy(style.Color),style.Alpha,
      deepcopy(style.FillColor),style.FillAlpha,style.LineType,style.ReadOnly)
    equal(referenceID,id+1)
    local reference=drawings[referenceID]
    for _,key in ipairs({"coalition","lineType","readOnly","text"}) do equal(drawn[key],reference[key]) end
    for i=1,4 do equal(drawn.color[i],reference.color[i]) equal(drawn.fill[i],reference.fill[i]) end
    for i,v in ipairs(drawn.vertices) do
      near(v.x,reference.vertices[i].x) near(v.y,reference.vertices[i].y) near(v.z,reference.vertices[i].z)
    end
    equal(#style.Color,3) equal(#style.FillColor,3)
  end
end)


test("debug snapshot highlights actual hex and rectangular path cells without searching again", function()
  local rect=ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(4000))
  rect:SetGridOptions({Width=2000,Margin=0,Spacing=1000,CrossSpacing=1000}):SetValidSurfaceTypes(nil):CreateGrid():SetValidNeighbourDistance(1100)
  local hex=hexgrid(2000,0):SetGridNeighboursOnly(true)
  hex:SetStartCoordinate(coord(100)) -- Exact endpoint has no cell polygon.
  for _,a in ipairs({rect,hex}) do
    resetDrawings()
    local path=a:GetPath()
    assert(path)
    local expected={}
    for _,node in ipairs(path) do expected[node.id]=true end
    local valid, costs, nodes=a.nvalid,a.ncost,a.Nnodes
    equal(a:DrawGridWithPath(path,{BatchSize=2}),a)
    flushTimers()
    equal(a.nvalid,valid) equal(a.ncost,costs) equal(a.Nnodes,nodes)
    local green, cells=0,0
    for id,node in pairs(a.nodes) do
      if node.rectGrid or node.q~=nil then
        cells=cells+1
        local drawing=drawings[a.GridDrawCellIDs[id]]
        assert(drawing)
        equal(#drawing.vertices,a.hexGrid and 6 or 4)
        equal(drawing.color[1],0)
        equal(drawing.color[2],expected[id] and 1 or 0)
        equal(drawing.color[3],expected[id] and 0 or 1)
        equal(drawing.fill[4],expected[id] and 0.35 or 0)
        if expected[id] then green=green+1 end
      else equal(a.GridDrawCellIDs[id],nil) end
    end
    assert(green>0 and green<cells)
    equal(count(drawings),cells) equal(next(scheduled),nil)
  end
end)

test("debug snapshots do not grow during pending or subsequent grid expansions", function()
  resetDrawings()
  local a=hexgrid(0,0):SetGridNeighboursOnly(true)
  local path=a:GetPath()
  local original=a.Nnodes
  a:DrawGridWithPath(path,{BatchSize=1})
  a:ExpandGrid(4000,2000):UpdateGridDrawing()
  equal(a.LastGridDrawResult.NodesQueued,original)
  flushTimers()
  equal(count(drawings),original)
  local marks=deepcopy(a.GridDrawIDs)
  a:SetValidNeighbourFunction(function() return false end)
  local _,report=configureExpansion(a,{MaxAttempts=2}):GetPathWithExpansion()
  equal(report.Drawing,nil) equal(count(drawings),original) equal(next(scheduled),nil)
  for _,id in ipairs(marks) do assert(drawings[id]) end
  -- Explicitly requesting a regular grid restores incremental drawing.
  a:DrawGrid()
  flushTimers()
  equal(count(drawings),a.Nnodes) equal(a.GridDrawOptions.Snapshot,nil)
end)

test("debug snapshots copy path selection and options before deferred drawing", function()
  resetDrawings()
  local a=hexgrid():SetGridNeighboursOnly(true)
  local path=a:GetPath()
  local expected={}
  for _,node in ipairs(path) do expected[node.id]=true end
  local options={Coalition=0,GridColor={0.1,0.2,0.3},PathColor={0.4,0.5,0.6},PathFillAlpha=0,BatchSize=1}
  a:DrawGridWithPath(path,options)
  for i=#path,1,-1 do path[i]=nil end
  options.PathColor[1]=1 options.GridColor[1]=1 options.PathFillAlpha=1 options.Coalition=2
  flushTimers()
  for id,markID in pairs(a.GridDrawCellIDs) do
    local drawing=drawings[markID]
    equal(drawing.coalition,0) equal(drawing.color[1],expected[id] and 0.4 or 0.1)
    equal(drawing.fill[4],0)
  end
end)

test("debug redraw and undraw cancel pending snapshots without duplicating polygons", function()
  resetDrawings()
  local a=hexgrid():SetGridNeighboursOnly(true)
  local path=a:GetPath()
  a:DrawGridWithPath(path,{BatchSize=1})
  local old=a.GridDrawJob
  local callback=scheduled[old.timerID]
  stepTimer()
  a:DrawGridWithPath({},{BatchSize=2})
  equal(old.result.Status,"cancelled") equal(callback.fn(callback.args,timerNow),nil)
  flushTimers()
  equal(count(drawings),a.Nnodes)
  for _,drawing in pairs(drawings) do equal(drawing.color[2],0) equal(drawing.fill[4],0) end
  a:DrawGridWithPath(path,{BatchSize=1})
  local pending=a.GridDrawJob
  a:UndrawGrid()
  equal(pending.result.Status,"cancelled") equal(count(drawings),0) equal(next(scheduled),nil)
end)

test("invalid debug paths and options leave the existing overlay intact", function()
  resetDrawings()
  local a=hexgrid():SetGridNeighboursOnly(true)
  local path=a:GetPath()
  a:DrawGrid()
  local old=a.GridDrawJob
  local foreign=hexgrid()
  local _,foreignNode=next(foreign.nodes)
  equal(pcall(function() a:DrawGridWithPath(nil) end),false)
  equal(pcall(function() a:DrawGridWithPath({foreignNode}) end),false)
  for _,options in ipairs({{PathFillAlpha=-1},{PathFillAlpha=2},{BatchSize=0},{MaxBatchSeconds=0},"invalid"}) do
    equal(pcall(function() a:DrawGridWithPath(path,options) end),false)
  end
  equal(a.GridDrawJob,old) equal(old.result.Status,"queued")
  flushTimers()
  equal(count(drawings),a.Nnodes)
end)


-- Use the actual MOOSE circle/polygon membership and bounds methods, including polygon edge conventions.
ZONE_BASE={}
ZONE_RADIUS=setmetatable({}, {__index=ZONE_BASE})
ZONE_POLYGON_BASE={}
local zoneFile=assert(io.open("Moose Development/Moose/Core/Zone.lua","r"))
local zoneSource=zoneFile:read("*a"):gsub("\r\n","\n") zoneFile:close()
for _,signature in ipairs({"ZONE_BASE:GetBoundingSquare", "ZONE_RADIUS:GetVec2", "ZONE_RADIUS:GetRadius",
  "ZONE_RADIUS:IsVec2InZone", "ZONE_POLYGON_BASE:GetBoundingSquare", "ZONE_POLYGON_BASE:IsVec2InZone"}) do
  local method=assert(zoneSource:match("(function "..signature.."%b().-\nend)"))
  assert((loadstring or load)(method))()
end
local function circleZone(x,z,radius)
  return setmetatable({Vec2={x=x,y=z},Radius=radius},{__index=ZONE_RADIUS})
end
local function polygonZone(origin,heading,points)
  local vertices={}
  for _,p in ipairs(points) do
    local c=origin:Translate(p[1],heading):Translate(p[2],heading+90)
    vertices[#vertices+1]={x=c.x,y=c.z}
  end
  return setmetatable({_={Polygon=vertices}},{__index=ZONE_POLYGON_BASE})
end

test("zone hex grids match circle, square and concave polygon membership across rotations", function()
  for _,heading in ipairs({0,37,90,205}) do
    local origin=coord(123456,-234567)
    local goal=origin:Translate(4000,heading)
    local center=origin:Translate(2000,heading)
    local zones={circleZone(center.x,center.z,2500),
      polygonZone(origin,heading+23,{{-499,-1499},{4501,-1499},{4501,3501},{-499,3501}}),
      polygonZone(origin,heading,{{-501,-2001},{4501,-2001},{4501,2001},{2501,2001},{2501,501},{-501,501}})}
    for _,zone in ipairs(zones) do
      local a=ASTAR:New():SetStartCoordinate(origin):SetEndCoordinate(goal)
      land.surfaceAt=function(c) assert(zone:IsVec2InZone({x=c.x,y=c.z})) return land.SurfaceType.WATER end
      a:SetGridOptions({Spacing=1000,MaxCells=5000}):SetValidSurfaceTypes(nil):CreateHexGridFromZone(zone)
      land.surfaceAt=nil
      local reference=ASTAR:New():SetStartCoordinate(origin):SetEndCoordinate(goal)
      reference:SetGridOptions({Width=20000,Margin=10000,Spacing=1000}):SetValidSurfaceTypes(nil):CreateHexGrid()
      local expected=0
      for _,node in pairs(reference.nodes) do
        if zone:IsVec2InZone({x=node.vector.x,y=node.vector.z}) then
          expected=expected+1
          local actual=nodeAtIndex(a,node.q,node.r)
          assert(actual) near(actual.vector:GetDistance(node.vector, true),0)
        end
      end
      equal(a.Nnodes,expected) assert(expected>0)
    end
  end
end)

test("rectangular zone grids include exactly the eligible centers and keep cell dimensions", function()
  local origin=coord(-12000,24000)
  for _,heading in ipairs({0,37,90}) do
    local zones={circleZone(origin.x,origin.z,3100),
      polygonZone(origin,heading,{{-1201,-1201},{3201,-1201},{3201,3201},{-1201,3201}}),
      polygonZone(origin,heading,{{-1201,-1201},{4201,-1201},{4201,2001},{1801,2001},{1801,201},{-1201,201}})}
    for _,zone in ipairs(zones) do
      local a=ASTAR:New():SetStartCoordinate(origin):SetEndCoordinate(origin:Translate(4000,heading))
      local manual=a:AddNodeFromCoordinate(origin:Translate(10000,heading))
      land.surfaceAt=function(c) assert(zone:IsVec2InZone({x=c.x,y=c.z})) return land.SurfaceType.WATER end
      a:SetGridOptions({Spacing=1000,CrossSpacing=1500,MaxCells=5000}):SetValidSurfaceTypes(nil):CreateGridFromZone(zone)
      land.surfaceAt=nil
      local expected=0
      for i=-10,10 do for j=-10,10 do
        local c=origin:Translate(j*1000,heading):Translate(i*1500,heading+90)
        if zone:IsVec2InZone({x=c.x,y=c.z}) then
          expected=expected+1
          local node,d=a:FindClosestNode(c)
          near(d,0) equal(node.rectGrid.along,500) equal(node.rectGrid.across,750)
        end
      end end
      equal(a.Nnodes,expected+1) equal(a.nodes[manual.id],manual)
    end
  end
end)

test("zone creation budgets reject before membership, terrain sampling or mutation", function()
  for _,hex in ipairs({false,true}) do
    local zone=circleZone(2000,0,3000)
    function zone:IsVec2InZone() error("Budget must precede membership tests") end
    local a=ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(4000))
    local counter=a.counter
    a:SetValidSurfaceTypes(land.SurfaceType.LAND)
    land.surfaceAt=function() error("Budget must precede terrain sampling") end
    local result,reason
    if hex then result,reason=a:SetGridOptions({Spacing=1000,MaxCells=1}):SetValidSurfaceTypes(nil):CreateHexGridFromZone(zone)
    else result,reason=a:SetGridOptions({Spacing=1000,CrossSpacing=1000,MaxCells=1}):SetValidSurfaceTypes(nil):CreateGridFromZone(zone) end
    equal(result,nil) equal(reason,"cell_limit") equal(a.Nnodes,0) equal(a.counter,counter)
    equal(a.hexGrid,nil) equal(a:GetGrid().hexIndex,nil) equal(a:GetGrid().ValidSurfaceTypes,nil)
  end
end)

test("zone expansion fills unsampled holes while preserving accepted and rejected terrain samples", function()
  local zone=circleZone(2000,0,2100)
  local sampled={}
  local function surface(c) return math.abs(c.x-2000)<1 and math.abs(c.z)<1 and land.SurfaceType.LAND or land.SurfaceType.WATER end
  land.surfaceAt=function(c)
    local key=string.format("%.4f %.4f",c.x,c.z)
    assert(not sampled[key],"Terrain was sampled twice") sampled[key]=true
    return surface(c)
  end
  local a=ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(4000))
  a:SetGridOptions({Spacing=1000}):SetValidSurfaceTypes(land.SurfaceType.WATER):CreateHexGridFromZone(zone)
  local grid=a.hexGrid
  local initial=grid.initialSamples
  local oldNodes={}
  for id,node in pairs(a.nodes) do oldNodes[id]=node end
  equal(nodeAtIndex(a,2,0),nil)
  a:ExpandGrid(grid.width,grid.margin)
  equal(grid.initialSamples,initial)
  local width,margin=grid.width+2000,grid.margin+1000
  local result,reason=configureExpansion(a,{MaxCells=grid.candidateCount}):ExpandGrid(width,margin)
  equal(result,nil) equal(reason,"cell_limit") equal(grid.initialSamples,initial)
  function zone:IsVec2InZone() error("Enlargement must not consult the initial zone again") end
  configureExpansion(a,{MaxCells=5000}):ExpandGrid(width,margin)
  equal(grid.initialSamples,nil) equal(nodeAtIndex(a,2,0),nil)
  assert(nodeAtIndex(a,-1,2)) -- (0, sqrt(3)*1000): inside old bounds, outside the initial circle.
  for id,node in pairs(oldNodes) do equal(a.nodes[id],node) end
  configureExpansion(a,{MaxCells=5000}):ExpandGrid(width+2000,margin+1000)
  land.surfaceAt=surface
  local reference=ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(4000))
  reference:SetGridOptions({Width=grid.width,Margin=grid.margin,Spacing=1000}):SetValidSurfaceTypes(land.SurfaceType.WATER):CreateHexGrid()
  equal(a.Nnodes,reference.Nnodes)
  for _,node in pairs(reference.nodes) do assert(nodeAtIndex(a,node.q,node.r)) end
end)

test("automatic expansion finds paths beyond a zone seed including an empty seed", function()
  for _,zone in ipairs({circleZone(0,0,100),circleZone(500,500,10)}) do
    local a=ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(4000))
    a:SetGridOptions({Spacing=1000}):SetValidSurfaceTypes(nil):CreateHexGridFromZone(zone):SetGridNeighboursOnly(true)
    assert(a.Nnodes<=1)
    local path,report=a:GetPathWithExpansion()
    assert(path and #report.Attempts>1)
    equal(report.StopReason,"path_found")
    local outside=false
    for _,node in ipairs(path) do if not zone:IsVec2InZone({x=node.vector.x,y=node.vector.z}) then outside=true end end
    assert(outside)
  end
end)

test("zone setup rejects invalid geometry and preserves objects", function()
  local a=ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(4000))
  for _,zone in ipairs({{},circleZone(0,0,-1),{IsVec2InZone=function() return true end,
    GetBoundingSquare=function() return {x1=0,x2=math.huge,y1=0,y2=1} end}}) do
    equal(pcall(function() a:CreateHexGridFromZone(zone) end),false)
    equal(pcall(function() a:CreateGridFromZone(zone) end),false)
  end
  equal(pcall(function() a:CreateHexGridFromZone(nil) end),false)
  equal(a.Nnodes,0) equal(a.hexGrid,nil)
end)


test("zone creation limits count bounding cells including centers outside a circle", function()
  local zone=circleZone(0,0,1100)
  local a=ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(4000))
  local queries=0
  land.surfaceAt=function(c)
    assert(zone:IsVec2InZone({x=c.x,y=c.z})) queries=queries+1 return land.SurfaceType.WATER
  end
  equal(a:SetGridOptions({Spacing=1000,CrossSpacing=1000,MaxCells=8}):SetValidSurfaceTypes(nil):CreateGridFromZone(zone),nil) equal(queries,0)
  equal(a:SetGridOptions({Spacing=1000,CrossSpacing=1000,MaxCells=9}):SetValidSurfaceTypes(nil):CreateGridFromZone(zone),a) equal(queries,5) equal(a.Nnodes,5)
  local b=ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(4000))
  equal(b:SetGridOptions({Spacing=1000,MaxCells=6}):SetValidSurfaceTypes(nil):CreateHexGridFromZone(zone),nil) equal(queries,5)
  equal(b:SetGridOptions({Spacing=1000,MaxCells=7}):SetValidSurfaceTypes(nil):CreateHexGridFromZone(zone),b) equal(b.hexGrid.candidateCount,7) equal(queries,12)
end)

test("node vectors accept all position inputs and coordinate conversion is explicit and independent", function()
  local a=ASTAR:New()
  local inputs={coord(100,300,200),VECTOR:New(100,200,300),{x=100,y=200,z=300},{x=100,y=300}}
  for i,input in ipairs(inputs) do
    local node=a:AddNodeFromCoordinate(input)
    assert(VECTOR._IsVector(node.vector))
    equal(rawget(node,"coordinate"),nil)
    near(node.vector.x,100) near(node.vector.y,i==4 and 0 or 200) near(node.vector.z,300)
    if VECTOR._IsVector(input) then assert(rawequal(node.vector,input))
    else assert(not rawequal(node.vector,input)) end
    local first,second=a:GetNodeCoordinate(node),a:GetNodeCoordinate(node)
    equal(first.ClassName,"COORDINATE") equal(second.ClassName,"COORDINATE")
    assert(not rawequal(first,second))
    near(first.x,node.vector.x) near(first.y,node.vector.y) near(first.z,node.vector.z)
    first.x=-999 first.y=-999
    near(second.x,100) near(second.y,node.vector.y) near(node.vector.x,100)
    equal(rawget(node,"coordinate"),nil)
  end
  inputs[1].x=-1000
  near(a.nodes[1].vector.x,100)
end)

test("3D endpoint selection distinguishes vertically separated nodes", function()
  local a=ASTAR:New():SetCostDist3D()
  local first=a:AddNodeFromCoordinate(coord(0,0,0))
  local last=a:AddNodeFromCoordinate(coord(0,0,1000))
  a:SetStartCoordinate(first.vector):SetEndCoordinate(last.vector)
  a:SetValidNeighbourFunction(function() return false end)
  equal(a:GetPath(),nil)
  equal(a.startNode,first) equal(a.endNode,last)
  equal(a:FindClosestNode(last.vector),last)
  a:SetValidNeighbourFunction(nil)
  local path=a:GetPath()
  equal(#path,2) equal(path[1],first) equal(path[2],last)
  equal(a:_TravelCost(first,last),1000)
end)

test("old automatic endpoints cannot bridge later grid searches", function()
  local a=ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(1000,1000))
  land.surfaceAt=function(p)
    if (p.x==0 and p.z==0) or (p.x==1000 and p.z==1000) or (p.x==500 and p.z==500) then
      return land.SurfaceType.WATER
    end
    return land.SurfaceType.LAND
  end
  a:SetValidSurfaceTypes(land.SurfaceType.WATER)
  a:GetGrid():SetCorridor(2000,0):SetSpacing(1000):SetDiagonals(false)
  -- Build along the x axis to retain the intended two diagonal cells.
  a:SetEndCoordinate(coord(1000)):CreateGrid()
  a:SetEndCoordinate(coord(1000,1000))
  equal(a.Nnodes,2) equal(a:GetPath(),nil)
  a:SetEndCoordinate(coord(500,500))
  local path=a:GetPath()
  assert(path) equal(a.Nnodes,3)
  local endpoint=a.endNode
  local unchanged=a:GetPath()
  equal(a.endNode,endpoint) equal(#unchanged,#path)
  assert(a.nodes[path[1].id].valid[endpoint.id])
  a:SetEndCoordinate(coord(1000,1000))
  equal(a:GetPath(),nil) equal(a.Nnodes,2)
  for _,node in pairs(a.nodes) do
    equal(node.valid[endpoint.id],nil) equal(node.cost[endpoint.id],nil)
  end
  -- Caller-owned path values remain usable for coordinate conversion and debug snapshots.
  equal(a:GetNodeCoordinate(endpoint).x,500)
  a:DrawGridWithPath(path) flushTimers()
  equal(a.LastGridDrawResult.Status,"complete")
  -- The same bridging position remains valid when explicitly added by the caller.
  local manual=a:AddNodeFromCoordinate(coord(500,500))
  assert(a:GetPath()) equal(a.nodes[manual.id],manual)
end)

test("invalid ASTAR positions cannot replace endpoints or reach terrain queries", function()
  local a=ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(1000))
  local first,last,counter=a.startVector,a.endVector,a.counter
  land.surfaceAt=function() error("Invalid coordinates reached terrain sampling") end
  for _,value in ipairs({math.huge,-math.huge,0/0}) do
    for _,axis in ipairs({"x","y","z"}) do
      local position=VECTOR:New(0,0,0)
      position[axis]=value
      for _,method in ipairs({"SetStartCoordinate","SetEndCoordinate","AddNodeFromCoordinate","FindClosestNode"}) do
        local ok,reason=pcall(a[method],a,position)
        assert(not ok and tostring(reason):find("finite"), method.." must reject non-finite positions before terrain access")
        equal(a.startVector,first) equal(a.endVector,last)
        equal(a.counter,counter) equal(a.Nnodes,0)
      end
    end
  end
end)

test("endpoint setters snapshot coordinate and vector inputs and can clear them", function()
  local a=ASTAR:New()
  local start,goal=coord(10,30,20),VECTOR:New(40,50,60)
  a:SetStartCoordinate(start):SetEndCoordinate(goal)
  assert(VECTOR._IsVector(a.startVector) and VECTOR._IsVector(a.endVector))
  start.x=-10 goal:SetX(-40)
  near(a.startVector.x,10) near(a.endVector.x,40)
  near(a.startVector.y,20) near(a.endVector.y,50)
  a:SetStartCoordinate(nil):SetEndCoordinate(nil)
  equal(a:GetPath(),nil) equal(a.LastPathFailure,"missing_coordinates")
end)

test("grid creation expansion search and debug overlays require no COORDINATE allocations", function()
  local original=COORDINATE.New
  COORDINATE.New=function() error("Only GetNodeCoordinate should allocate a COORDINATE") end
  local ok,err=pcall(function()
    trigger.action.markToAll=function() end
    land.isVisible=function() return true end
    local a=ASTAR:New():SetStartCoordinate({x=0,y=0,z=0}):SetEndCoordinate({x=4000,y=0,z=0})
    a:SetGridOptions({Width=2000,Margin=1000,Spacing=1000}):SetValidSurfaceTypes(nil):CreateHexGrid():SetGridNeighboursOnly(true):SetValidNeighbourLoS(100)
    a:ExpandGrid(4000,2000)
    local path=assert(a:GetPath())
    a:DrawGridWithPath(path,{BatchSize=100})
    flushTimers()
    a:UndrawGrid()
    local b=ASTAR:New():SetStartCoordinate({x=0,y=0}):SetEndCoordinate({x=2000,y=0})
    b:SetGridOptions({Width=1000,Margin=0,Spacing=1000,CrossSpacing=1000}):SetValidSurfaceTypes(nil):CreateGrid()
    assert(b:GetPath())
    b:DrawGridWithPath(b:GetPath(),{BatchSize=100})
    flushTimers()
    b:UndrawGrid()
    local zone=circleZone(0,0,1500)
    for _,hex in ipairs({false,true}) do
      local c=ASTAR:New():SetStartCoordinate({x=0,y=0}):SetEndCoordinate({x=1000,y=0})
      if hex then c:SetGridOptions({Spacing=1000}):SetValidSurfaceTypes(nil):CreateHexGridFromZone(zone)
      else c:SetGridOptions({Spacing=1000,CrossSpacing=1000}):SetValidSurfaceTypes(nil):CreateGridFromZone(zone) end
      assert(c:GetPath())
      for _,node in pairs(c.nodes) do
        assert(VECTOR._IsVector(node.vector)) equal(rawget(node,"coordinate"),nil)
      end
    end
  end)
  COORDINATE.New=original
  assert(ok,err)
end)

-- Exercise the production naval planner with actual GRID/ASTAR and stubbed route/FSM side effects.
local navyFile=assert(io.open("Moose Development/Moose/Ops/NavyGroup.lua","r"))
local navySource=navyFile:read("*a"):gsub("\r\n","\n") navyFile:close()
NAVYGROUP={}
for _,name in ipairs({"_GetPathfindingTarget","_FindPathToNextWaypoint","_ContinuePathfinding","_TracePathfindingReplan","_ClearPathfindingDrawing","_GetPathfindingCorridorWidth","_CheckPathDepth","_CheckFreePath",
  "_CanNavigate","_GetPathfindingContext","_StopForNavigation","_FailPathfinding","_OnBeforeNavigationResume","_OnAfterNavigationResume","_UpdateNavigationWarning","_CheckNavigation",
  "onafterFullStop","onafterCruise","onafterCollisionWarning","onafterClearAhead","onafterTurningStopped",
  "SetPathfinding","SetPathfindingOn","SetPathfindingOff","SetPathfindingMinDepth","SetPathfindingGrid","SetPathfindingRetry","onafterUpdateRoute","onafterTurnIntoWindOver",
  "_CreateTurnIntoWind","AddTurnIntoWind","RemoveTurnIntoWind","AddTaskAttackGroup","_CheckTurning",
  "GetHeadingIntoWind_new","onafterRTZ","onafterEngageTarget","_UpdateEngageTarget"}) do
  assert((loadstring or load)(assert(navySource:match("(function NAVYGROUP:"..name.."%b().-\nend)"))))()
end
local opsFile=assert(io.open("Moose Development/Moose/Ops/OpsGroup.lua","r"))
local opsSource=opsFile:read("*a"):gsub("\r\n","\n") opsFile:close()
OPSGROUP={}
assert((loadstring or load)(assert(opsSource:match("(function OPSGROUP%._PassingWaypoint%b().-\nend)"))))()
for _,name in ipairs({"RemoveWaypointByID","RemoveWaypoint","onafterWait","onafterStop"}) do
  assert((loadstring or load)(assert(opsSource:match("(function OPSGROUP:"..name.."%b().-\nend)"))))()
end
UTILS.NMToMeters=function(n) return n*1852 end
UTILS.MpsToKnots=function(n) return n*1.9438444924 end
UTILS.MpsToKmph=function(n) return n*3.6 end
local function vessel(distance)
  local terrain=depthTerrain()
  -- DCS supplies terrain support points. This fixture samples its artificial terrain densely enough to expose the test islands.
  terrain.makeProfile=function(a,b)
    local length=math.sqrt((b.x-a.x)^2+(b.z-a.z)^2)
    local intervals=math.max(1,math.ceil(length/50))
    local points={}
    for i=0,intervals do
      local x,z=a.x+(b.x-a.x)*i/intervals,a.z+(b.z-a.z)*i/intervals
      local depth=terrain.depthAt and terrain.depthAt({x=x,y=z}) or terrain.depth
      points[#points+1]={x=x,y=terrain.height-depth,z=z}
    end
    return points
  end
  local ship=setmetatable({lid="test",verbose=0,pathCorridor=100,pathfindingOn=true,currentwp=1,
    state="Cruising",isAI=true,speed=10,velocity=10,alive=true,
    position={x=0,y=0,z=0},nextID=2,updates=0,stops=0,cruises=0,resumes=0,added=0,warnings=0,clears=0},{__index=NAVYGROUP})
  ship.waypoints={{uid=1,coordinate=coord(0),speed=10,npassed=0},{uid=2,coordinate=coord(distance or 5000),speed=10,npassed=0}}
  ship.depthTerrain=terrain
  function ship:T() end
  function ship:T3() end
  function ship:IsTrace() return false end
  function ship:GetState() return self.state end
  function ship:IsAlive() return self.alive end
  function ship:IsWaiting() return self.Twaiting~=nil end
  function ship:IsHolding() return self.state=="Holding" end
  function ship:GetVelocity() return self.velocity end
  function ship:GetMissionCurrent() return self.mission end
  function ship:GetVec3() return self.position end
  function ship:GetWaypointIndexNext() return self.currentwp+1 end
  function ship:GetWaypointNext() return self.waypoints[self.currentwp+1] end
  function ship:GetWaypointCurrent() return self.waypoints[self.currentwp] end
  function ship:GetWaypointIndex(uid) for i,w in ipairs(self.waypoints) do if w.uid==uid then return i end end end
  function ship:GetWaypointByID(uid) local i=self:GetWaypointIndex(uid) return i and self.waypoints[i] end
  function ship:RemoveWaypointByID(uid)
    local i=assert(self:GetWaypointIndex(uid)) table.remove(self.waypoints,i)
    if i<=self.currentwp then self.currentwp=math.max(1,self.currentwp-1) end
  end
  function ship:AddWaypoint(position,speed,after,depth,update)
    assert(VECTOR._IsVector(position)) equal(update,false)
    self.added=self.added+1 self.nextID=self.nextID+1
    local wp={uid=self.nextID,coordinate=position,speed=speed/1.9438444924,npassed=0}
    table.insert(self.waypoints,assert(self:GetWaypointIndex(after))+1,wp)
    return wp
  end
  -- Execute production handlers after the transition, matching the ordering used by the FSM.
  -- Public callbacks can issue another command and must retain ownership of the resulting hold.
  function ship:FullStop(owner)
    local from=self.state
    self.stops=self.stops+1
    self.state="Holding"
    self:onafterFullStop(from,"FullStop",self.state,owner)
    if self.OnAfterFullStop then self:OnAfterFullStop(from,"FullStop",self.state,owner) end
  end
  function ship:Cruise(speed)
    local from=self.state
    self.cruises=self.cruises+1
    self.state="Cruising"
    self:onafterCruise(from,"Cruise",self.state,speed)
  end
  function ship:Wait(duration) OPSGROUP.onafterWait(self,self.state,"Wait",self.state,duration) end
  function ship:CollisionWarning(distance)
    self.warnings=self.warnings+1
    self:onafterCollisionWarning(self.state,"CollisionWarning",self.state,distance)
    if self.OnAfterCollisionWarning then self:OnAfterCollisionWarning(self.state,"CollisionWarning",self.state,distance) end
  end
  function ship:ClearAhead()
    self.clears=self.clears+1
    self:onafterClearAhead(self.state,"ClearAhead",self.state)
  end
  for _,state in ipairs({"Cruising","Engaging","Returning","Retreating","OnDetour"}) do
    local destination=state
    local event="ResumeNavigation"..state
    ship[event]=function(self,owner)
      local from=self.state
      if not self:_OnBeforeNavigationResume(from,event,destination,owner) then return false end
      self.state=destination
      self.resumes=self.resumes+1
      self:_OnAfterNavigationResume(from,event,destination,owner)
      return true
    end
  end
  function ship:__UpdateRoute(delay,first,last,speed)
    self.updates=self.updates+1
    self.updatedSpeed=speed
  end
  function ship:IsTurning() return self.turning==true end
  function ship:IsSteamingIntoWind() return false end
  function ship:GetHeading() return 0 end
  function ship:IsNavygroup() return true end
  function ship:IsEngaging() return self.state=="Engaging" end
  function ship:_PassedFinalWaypoint(value) self.passedfinalwp=value end
  function ship:GetCoordinate()
    return {WaypointNaval=function() return {x=self.position.x,y=self.position.z,speed=10} end}
  end
  function ship:Route(route) self.dispatched=route end
  return ship
end
local function island(p)
  if p.x>=1800 and p.x<=3200 and math.abs(p.z)<=1200 then return land.SurfaceType.LAND end
  return land.SurfaceType.WATER
end

test("NAVYGROUP manual FullStop and Wait supersede a navigation-owned stop",function()
  for _,command in ipairs({"FullStop","Wait"}) do
    local ship=vessel()
    ship.depthTerrain.depth=5
    equal(ship:_FindPathToNextWaypoint(),false)
    equal(ship:GetState(),"Holding")
    assert(ship.navigationHold)

    -- FullStop must revoke automatic resumption even when the group was already holding.
    ship[command](ship)
    equal(ship.navigationHold,nil)
    equal(ship.pathfindingStopped,nil)
    ship.depthTerrain.depth=30
    timerNow=120
    ship:_CheckNavigation()
    equal(ship:_FindPathToNextWaypoint(true),false)
    equal(ship:_ContinuePathfinding(),false)
    equal(ship:GetState(),"Holding")
    equal(ship.resumes,0)
    equal(ship.cruises,0)
    equal(ship.updates,0)
  end
end)

test("NAVYGROUP respects a manual stop issued inside its FullStop callback",function()
  local ship=vessel()
  function ship:OnAfterFullStop(from,event,to,owner)
    if owner then self:FullStop() end
  end
  equal(ship:_StopForNavigation(),false)
  equal(ship.stops,2)
  equal(ship.navigationHold,nil)
  ship:_CheckNavigation()
  equal(ship.resumes,0)
  equal(ship:GetState(),"Holding")
end)

test("NAVYGROUP warning callbacks can stop navigation before planning changes the route",function()
  for _,command in ipairs({"FullStop","Wait"}) do
    local ship=vessel()
    ship.depthTerrain.depthAt=function(point) return point.x>=500 and point.x<=600 and 5 or 30 end
    function ship:OnAfterCollisionWarning() self[command](self) end
    function ship:_FindPathToNextWaypoint() error("A manual warning callback owns the stop") end

    ship:_CheckNavigation()
    equal(ship.warnings,1)
    equal(ship:GetState(),"Holding")
    equal(ship.navigationHold,nil)
    equal(ship.updates,0)
  end
end)

test("NAVYGROUP rearms warnings only after a verified clear check",function()
  local ship=vessel():SetPathfindingOff()
  ship.depthTerrain.depthAt=function(point) return point.x>=500 and point.x<=600 and 5 or 30 end
  ship:_CheckNavigation()
  equal(ship.warnings,1)
  assert(ship.collisionwarning)
  ship:_CheckNavigation()
  equal(ship.warnings,1)

  ship.turning=true
  ship:onafterTurningStopped("Cruising","TurningStopped","Cruising")
  assert(ship.collisionwarning)
  equal(ship.clears,0)

  local profile=land.profile
  land.profile=nil
  ship:_CheckNavigation()
  equal(ship.LastNavigationCheck.Status,"unavailable")
  assert(ship.collisionwarning)
  equal(ship.clears,0)

  land.profile=profile
  ship.depthTerrain.depthAt=nil
  ship:_CheckNavigation()
  equal(ship.LastNavigationCheck.Status,"clear")
  equal(ship.collisionwarning,false)
  equal(ship.clears,1)

  ship.depthTerrain.depth=5
  ship:_CheckNavigation()
  equal(ship.warnings,2)
  equal(ship.stops,0)
  equal(ship.updates,0)
end)

test("NAVYGROUP unavailable terrain stops automatic navigation without fabricating an obstacle",function()
  local ship=vessel()
  land.profile=nil
  ship:_CheckNavigation()
  equal(ship.LastNavigationCheck.Status,"unavailable")
  equal(ship.warnings,0)
  equal(ship.stops,1)
  assert(ship.navigationHold)
  equal(ship.updates,0)
end)

test("NAVYGROUP navigation monitoring adapts to speed and checks turns without a status update",function()
  local ship=vessel(5000):SetPathfindingOff()
  ship.timerNavigation={SetTimeInterval=function(self,value) self.interval=value end}
  ship.elements={{length=200,width=20}}
  function ship:Status() error("Navigation must not invoke the status workload") end
  function ship:_UpdatePosition() error("Navigation reads the actual position directly") end

  ship.velocity=5
  ship:_CheckNavigation()
  equal(ship.timerNavigation.interval,10)
  near(ship.LastNavigationCheck.Distance,1000)

  ship.velocity=20
  ship:_CheckNavigation()
  equal(ship.timerNavigation.interval,2.5)
  near(ship.LastNavigationCheck.Distance,2400)

  ship.turning=true
  ship.depthTerrain.depthAt=function(point) return point.x>=750 and point.x<=900 and 5 or 30 end
  ship:_CheckNavigation()
  equal(ship.LastNavigationCheck.Status,"blocked")
  equal(ship.warnings,1)
  equal(ship.timerNavigation.interval,2)
end)

test("NAVYGROUP holds completed routes and user-owned states without querying terrain",function()
  for _,mode in ipairs({"manual","waiting","completed","dead","player"}) do
    local ship=vessel()
    if mode=="manual" then ship:FullStop()
    elseif mode=="waiting" then ship:Wait()
    elseif mode=="completed" then ship.passedfinalwp=true
    elseif mode=="dead" then ship.alive=false
    else ship.isAI=false end

    local calls=ship.depthTerrain.queries
    ship:_CheckNavigation()
    equal(ship.depthTerrain.queries,calls)
    equal(ship.LastNavigationCheck,nil)
    equal(ship.updates,0)
  end
end)

test("NAVYGROUP local detection stops a blocked ordinary route when bounded planning fails",function()
  local ship=vessel():SetPathfindingGrid(1)
  ship.depthTerrain.depthAt=function(point) return point.x>=500 and point.x<=600 and 5 or 30 end
  equal(ship.ispathfinding,nil)

  ship:_CheckNavigation()
  equal(ship.LastNavigationCheck.Status,"blocked")
  equal(ship.LastPathfindingResult.StopReason,"cell_limit")
  equal(ship.warnings,1)
  equal(ship:GetState(),"Holding")
  equal(ship.navigationHold.State,"Cruising")
  equal(ship.stops,1)
  equal(ship.updates,0)
end)

test("NAVYGROUP monitoring releases dead-group state and joins shared timer cleanup",function()
  local ship=vessel()
  assert(ship:_StopForNavigation())
  local drawingRemoved=false
  ship.pathfindingDebugSearch={UndrawGrid=function() drawingRemoved=true end}
  ship.LastNavigationCheck={Status="blocked"}
  ship:CollisionWarning(200)
  ship.ispathfinding=true
  ship.pathfindingContext="previous route"
  ship.pathfindingTargetUID=2
  ship.alive=false
  ship.state="Dead"
  ship:_CheckNavigation()
  assert(drawingRemoved)
  equal(ship.navigationHold,nil)
  equal(ship.pathfindingStopped,nil)
  equal(ship.LastNavigationCheck,nil)
  equal(ship.collisionwarning,false)
  equal(ship.ispathfinding,false)
  equal(ship.pathfindingContext,nil)
  equal(ship.pathfindingTargetUID,nil)
  equal(ship.clears,0)

  -- Reusing the group after respawn must not inherit a warning latch from its previous life.
  ship.alive=true
  ship.state="Cruising"
  ship:SetPathfindingOff()
  ship.depthTerrain.depth=5
  ship:_CheckNavigation()
  equal(ship.warnings,2)
  assert(ship.collisionwarning)
  equal(ship.clears,0)
  ship.alive=false
  ship.state="Dead"

  local function stoppable()
    return {Stop=function(self) self.stopped=true end}
  end
  ship.timerNavigation=stoppable()
  ship.timerStatus=stoppable()
  ship.timerQueueUpdate=stoppable()
  ship.timerCheckZone=stoppable()
  ship.CallScheduler={Clear=function(self) self.cleared=true end}
  ship.missionqueue={}
  ship.groupname="test vessel"
  function ship:UnHandleEvent() end

  local originalEvents,originalDatabase=EVENTS,_DATABASE
  EVENTS={Birth=1,Dead=2,RemoveUnit=3}
  _DATABASE={FLIGHTGROUPS={[ship.groupname]=ship}}
  local ok,err=pcall(OPSGROUP.onafterStop,ship,"Dead","Stop","Stopped")
  EVENTS,_DATABASE=originalEvents,originalDatabase
  assert(ok,err)
  assert(ship.timerNavigation.stopped)
  assert(ship.timerStatus.stopped)
  assert(ship.timerQueueUpdate.stopped)
  assert(ship.timerCheckZone.stopped)
  assert(ship.CallScheduler.cleared)
end)

test("NAVYGROUP automatic resumption preserves the interrupted operation and commanded depth",function()
  for _,state in ipairs({"Cruising","Engaging","Returning","Retreating","OnDetour"}) do
    local ship=vessel()
    ship.state=state
    ship.depth=40
    ship.speed=7
    ship.depthTerrain.depth=5
    equal(ship:_FindPathToNextWaypoint(),false)
    equal(ship:GetState(),"Holding")
    equal(ship.navigationHold.State,state)

    ship.depthTerrain.depth=100
    timerNow=timerNow+61
    assert(ship:_FindPathToNextWaypoint())
    equal(ship:GetState(),state)
    equal(ship.depth,40)
    near(ship.updatedSpeed,UTILS.MpsToKnots(7))
    equal(ship.resumes,1)
    equal(ship.cruises,0)
    equal(ship.updates,1)
    equal(ship.navigationHold,nil)
  end
end)

test("NAVYGROUP navigation resumes the active waypoint speed override instead of the route default",function()
  local ship=vessel()
  ship.speed=12
  ship.speedWp=4
  ship.depth=40
  ship.depthTerrain.depth=100

  assert(ship:_StopForNavigation())
  near(ship.navigationHold.Speed,UTILS.MpsToKnots(4))
  assert(ship:_FindPathToNextWaypoint())
  near(ship.updatedSpeed,UTILS.MpsToKnots(4))
  equal(ship.depth,40)
  equal(ship.resumes,1)
  equal(ship.cruises,0)
end)

test("NAVYGROUP retry context notices changed coordinates and settings on the same target UID",function()
  for _,change in ipairs({"coordinate","depth","corridor","grid","mission"}) do
    local ship=vessel():SetPathfindingGrid(1)
    land.surfaceAt=island
    equal(ship:_FindPathToNextWaypoint(),false)
    local target=ship.waypoints[2]
    local report=ship.LastPathfindingResult
    timerNow=timerNow+1
    equal(ship:_FindPathToNextWaypoint(),false)
    equal(ship.LastPathfindingResult,report)

    if change=="coordinate" then target.coordinate.x=6000
    elseif change=="depth" then ship:SetPathfindingMinDepth(21)
    elseif change=="corridor" then ship:SetPathfindingOn(120)
    elseif change=="grid" then ship:SetPathfindingGrid(2)
    else ship.mission={} end
    equal(ship:_FindPathToNextWaypoint(),false)
    assert(ship.LastPathfindingResult~=report)
    equal(ship.waypoints[2].uid,2)
    equal(ship.stops,1)
  end
end)

test("NAVYGROUP rejects impossible endpoints and unavailable APIs before allocating ASTAR",function()
  local original=ASTAR.New
  ASTAR.New=function() error("Grid expansion cannot repair the endpoint or terrain API") end
  local ok,err=pcall(function()
    for _,failure in ipairs({"start","goal","api"}) do
      local ship=vessel()
      if failure=="api" then
        land.profile=nil
      else
        ship.depthTerrain.depthAt=function(point)
          if (failure=="start" and point.x==0) or (failure=="goal" and point.x==5000) then return 5 end
          return 30
        end
      end

      equal(ship:_FindPathToNextWaypoint(),false)
      equal(#ship.LastPathfindingResult.Attempts,0)
      equal(ship.LastPathfindingResult.StopReason,failure=="api" and "depth_api_unavailable" or failure.."_blocked")
      equal(ship.LastPathfindingResult.DepthCheck.Status,failure=="api" and "unavailable" or "blocked")
      equal(ship.stops,1)
      equal(ship.updates,0)
    end
  end)
  ASTAR.New=original
  assert(ok,err)
end)

test("NAVYGROUP rejects invalid recovery windows without polluting the queue",function()
  local ship=vessel()
  ship.Qintowind={} ship.intowindcounter=0
  function ship:E() end
  local oldToClock,oldToSeconds=UTILS.SecondsToClock,UTILS.ClockToSeconds
  UTILS.SecondsToClock=tostring
  UTILS.ClockToSeconds=tonumber
  equal(ship:AddTurnIntoWind(100,-1),nil)
  equal(ship:AddTurnIntoWind(-100,50),nil)
  equal(#ship.Qintowind,0) equal(ship.intowindcounter,0)
  local window=ship:AddTurnIntoWind(100,200)
  equal(#ship.Qintowind,1) equal(window.Tstop-window.Tstart,200)
  UTILS.SecondsToClock,UTILS.ClockToSeconds=oldToClock,oldToSeconds
  ship.intowind=window
  function ship:TurnIntoWindStop() self.stoppedWindow=true end
  equal(ship:RemoveTurnIntoWind(window),ship) assert(ship.stoppedWindow)
end)

test("NAVYGROUP attack task does not read unrelated mission globals",function()
  local ship=vessel()
  local oldControllable,oldQty=CONTROLLABLE,AttackQty
  AttackQty=999
  local target={}
  CONTROLLABLE={TaskAttackGroup=function(_,group,weapon,expend,...)
    equal(group,target) equal(weapon,2) equal(expend,3) equal(select("#",...),0)
    return {id="AttackGroup"}
  end}
  function ship:AddTask(task,clock,duration,prio)
    equal(clock,"12:00") equal(prio,4) return task
  end
  equal(ship:AddTaskAttackGroup(target,3,2,"12:00",4).id,"AttackGroup")
  CONTROLLABLE,AttackQty=oldControllable,oldQty
end)

test("NAVYGROUP turning checks do not alter shared orientation and tolerate missing history",function()
  local ship=vessel()
  ship.group={GetUnit=function() return {IsAlive=function() return true end} end}
  ship.orientX={x=1,y=0.2,z=0} ship.orientXLast={x=0,y=0.3,z=1}
  function ship:TurningStarted() self.turnStarts=(self.turnStarts or 0)+1 end
  function ship:TurningStopped() self.turnStops=(self.turnStops or 0)+1 end
  ship:_CheckTurning()
  equal(ship.turnStarts,1) equal(ship.orientX.y,0.2) equal(ship.orientXLast.y,0.3)
  ship.orientXLast=ship.orientX
  ship:_CheckTurning() equal(ship.turnStops,1)
  ship.orientXLast=nil ship:_CheckTurning()
  ship.orientXLast={x=0,y=1,z=0} ship:_CheckTurning()
end)

test("NAVYGROUP replanning suppresses intermediate completion checks while replacing route points",function()
  local ship=vessel()
  ship.RemoveWaypointByID=OPSGROUP.RemoveWaypointByID
  ship.RemoveWaypoint=OPSGROUP.RemoveWaypoint
  function ship:GetWaypoint(index) return self.waypoints[index] end
  function ship:_CheckGroupDone() self.doneChecks=(self.doneChecks or 0)+1 end
  -- Use the actual shared removal implementation so scheduled completion checks cannot hide behind the fixture.
  local pending={uid=3,coordinate=coord(1000),speed=10,astar=true}
  table.insert(ship.waypoints,2,pending) ship.nextID=3
  land.surfaceAt=island
  assert(ship:_FindPathToNextWaypoint(true))
  equal(ship.doneChecks,nil) equal(ship.updates,1)
  equal(ship:GetWaypointByID(3),nil)
  equal(ship:RemoveWaypoint(999),ship)
  ship:RemoveWaypoint(2)
  equal(ship.doneChecks,1)
end)

test("ASTAR rejects invalid rules and limits without replacing configured callbacks",function()
  local a=ASTAR:New():SetValidNeighbourDistance(10):SetCostDist3D()
  local rule,cost=a.ValidNeighbourFunc,a.CostFunc
  for _,bad in ipairs({false,1,"function",{}}) do
    assert(not pcall(a.SetValidNeighbourFunction,a,bad)) equal(a.ValidNeighbourFunc,rule)
    assert(not pcall(a.SetCostFunction,a,bad)) equal(a.CostFunc,cost)
  end
  for _,name in ipairs({"SetValidNeighbourDistance","SetValidNeighbourRoad","SetValidNeighbourLoS"}) do
    for _,bad in ipairs({false,-1,math.huge,0/0}) do
      assert(not pcall(a[name],a,bad)) equal(a.ValidNeighbourFunc,rule)
    end
  end
  assert(not pcall(a.GetPath,a,{})) assert(not pcall(a.GetPath,a,false,0))
  local ship=vessel()
  assert(not pcall(ship.SetPathfinding,ship,"false")) equal(ship.pathfindingOn,true)
end)

test("NAVYGROUP wind heading remains finite for calm weather and unangled decks",function()
  local ship=vessel()
  ship.speedMax=60
  local oldConversion=UTILS.KmphToKnots
  UTILS.KmphToKnots=function(value) return value/1.852 end
  function ship:GetHeading() return 123 end
  function ship:GetWind() return 270,0 end
  for _,offset in ipairs({0,-9,9}) do
    local heading,speed=ship:GetHeadingIntoWind_new(offset,20)
    equal(heading,123) equal(speed,20)
  end
  function ship:GetWind() return 270,10/1.9438444924 end
  local heading,speed=ship:GetHeadingIntoWind_new(0,20)
  equal(heading,270) near(speed,10)
  -- Both deck-angle signs must remain usable when the ship reaches its speed limits in light wind.
  for _,wind in ipairs({0.1,1,10,30}) do
    function ship:GetWind() return 270,wind/1.9438444924 end
    for _,requested in ipairs({1,20,50}) do
      local left,leftSpeed=ship:GetHeadingIntoWind_new(-9,requested)
      local right,rightSpeed=ship:GetHeadingIntoWind_new(9,requested)
      assert(left>=0 and left<360 and right>=0 and right<360)
      assert(leftSpeed>=0 and leftSpeed<math.huge)
      near(leftSpeed,rightSpeed)
      near((left+right)%360,180)
    end
  end
  UTILS.KmphToKnots=oldConversion
end)

test("NAVYGROUP RTZ formation is never passed as waypoint depth",function()
  local ship=vessel()
  function ship:CancelAllMissions() end
  function ship:IsInZone() return false end
  function ship:GetWaypointCurrentUID() return 1 end
  function ship:AddWaypoint(position,speed,uid,depth,update)
    equal(depth,nil) equal(update,true) return {}
  end
  local zone={GetName=function() return "home" end,GetRandomCoordinate=function() return coord(1000) end}
  ship:onafterRTZ(nil,nil,nil,zone,"Off Road")
end)

test("NAVYGROUP engagement preserves meter depths through the feet-based waypoint API",function()
  local ship=vessel()
  local oldEnums,oldFeet,oldCopy,oldDist=ENUMS,UTILS.MetersToFeet,UTILS.DeepCopy,UTILS.VecDist3D
  ENUMS={AlarmState={Auto=1},ROE={OpenFire=2}}
  UTILS.MetersToFeet=function(value) return value/0.3048 end
  UTILS.DeepCopy=function(value) return value end
  UTILS.VecDist3D=function() return 200 end
  ship.engage={}
  local position={GetVec3=function() return {} end,UpdateFromVec3=function() end}
  local target={IsInstanceOf=function() return true end,GetCoordinate=function() return position end,
    IsAlive=function() return true end,GetVec3=function() return {} end}
  function ship:GetCoordinate() return {GetIntermediateCoordinate=function() return coord(500) end} end
  function ship:GetROE() return 1 end
  function ship:GetAlarmstate() return 1 end
  function ship:SwitchROE() end
  function ship:SwitchAlarmstate() end
  function ship:GetWaypointCurrentUID() return 1 end
  function ship:AddWaypoint(position,speed,uid,depth,update)
    near(depth*0.3048,30) return {uid=4}
  end
  function ship:RemoveWaypointByID(uid,checkDone) equal(checkDone,false) end
  ship:onafterEngageTarget(nil,nil,nil,target,20,30)
  ship:_UpdateEngageTarget()
  ENUMS,UTILS.MetersToFeet,UTILS.DeepCopy,UTILS.VecDist3D=oldEnums,oldFeet,oldCopy,oldDist
end)

test("NAVYGROUP expands around land and hands smoothed vectors over with one route update",function()
  local ship=vessel()
  land.surfaceAt=function(p)
    if p.x>=1800 and p.x<=3200 and math.abs(p.z)<=1800 then return land.SurfaceType.LAND end
    return land.SurfaceType.WATER
  end
  local original=COORDINATE.New
  COORDINATE.New=function() error("Path handoff must not create temporary coordinates") end
  local ok,result=pcall(ship._FindPathToNextWaypoint,ship)
  COORDINATE.New=original
  assert(ok,result) equal(result,true)
  equal(ship.LastPathfindingResult.Spacing,75)
  assert(#ship.LastPathfindingResult.Attempts>1)
  assert(ship.added>0 and ship.added<10) equal(ship.updates,1) equal(ship.stops,0)
  local previous=ship.position
  for i=2,#ship.waypoints do
    assert(ship:_CheckPathDepth(previous,ship.waypoints[i].coordinate))
    previous=ship.waypoints[i].coordinate
  end
  equal(ship.waypoints[#ship.waypoints].uid,2)
end)

test("NAVYGROUP retries bounded failures while stopped and resumes only after a checked plan",function()
  local ship=vessel():SetPathfindingGrid(1):SetPathfindingRetry(60)
  land.surfaceAt=island
  equal(ship:_FindPathToNextWaypoint(),false)
  equal(ship.LastPathfindingResult.StopReason,"cell_limit") equal(ship.stops,1) equal(ship.updates,0)
  local report=ship.LastPathfindingResult
  timerNow=30 equal(ship:_FindPathToNextWaypoint(),false) equal(ship.LastPathfindingResult,report) equal(ship.stops,1)
  timerNow=61 equal(ship:_FindPathToNextWaypoint(),false) assert(ship.LastPathfindingResult~=report) equal(ship.stops,1)
  ship:SetPathfindingGrid()
  timerNow=122 assert(ship:_FindPathToNextWaypoint()) equal(ship.resumes,1) equal(ship.cruises,0) equal(ship.updates,1) equal(ship.pathfindingStopped,nil)
end)

test("NAVYGROUP replans active detours to the original target without accumulating stale points",function()
  local ship=vessel()
  land.surfaceAt=island assert(ship:_FindPathToNextWaypoint())
  local old={} for i=2,#ship.waypoints-1 do old[ship.waypoints[i].uid]=true end
  local target=ship.waypoints[#ship.waypoints]
  -- A newly blocked actual route leg, rather than the old direct line to the final target, requires a new plan.
  local nextPoint=ship.waypoints[2].coordinate
  local x,z=nextPoint.x/2,nextPoint.z/2
  land.surfaceAt=function(p)
    if (p.x-x)^2+(p.z-z)^2<250^2 then return land.SurfaceType.LAND end
    return island(p)
  end
  equal(ship:_CheckPathDepth(ship.position,nextPoint),false)
  timerNow=61 assert(ship:_FindPathToNextWaypoint())
  equal(ship.waypoints[#ship.waypoints],target) equal(ship.updates,2)
  for _,wp in ipairs(ship.waypoints) do assert(not old[wp.uid]) end
end)

test("NAVYGROUP checks both sides of the ahead corridor with terrain profiles",function()
  local ship=vessel():SetPathfindingOn(400)
  land.surfaceAt=function(p) if p.x>=500 and p.x<=600 and p.z>=150 and p.z<=250 then return land.SurfaceType.LAND end return land.SurfaceType.WATER end
  local free=ship:_CheckFreePath()
  assert(free>=0 and free<500)
  ship:SetPathfindingOn(0) equal(ship:_CheckFreePath(),5000)
  ship:SetPathfindingOn(400)
  function ship:IsTurning() return true end
  assert(ship:_CheckFreePath(1000)<500)
end)

test("NAVYGROUP resolves beam clearance lazily and preserves explicit corridor overrides",function()
  local ship=vessel():SetPathfindingOn()
  equal(ship.pathCorridor,nil)
  equal(ship:_GetPathfindingCorridorWidth(),50)
  ship.elements={{width=20},{width=15}}
  equal(ship:_GetPathfindingCorridorWidth(),40)
  ship.elements[2].width=40
  equal(ship:_GetPathfindingCorridorWidth(),60)
  ship:SetPathfindingOff()
  equal(ship:_GetPathfindingCorridorWidth(),60)
  ship:SetPathfindingOn(12):SetPathfindingOff()
  equal(ship:_GetPathfindingCorridorWidth(),12)
  ship:SetPathfindingOn(0)
  equal(ship:_GetPathfindingCorridorWidth(),0)
  ship:SetPathfindingOn()
  equal(ship:_GetPathfindingCorridorWidth(),60)
  for _,bad in ipairs({0,-1,math.huge,0/0,false}) do
    ship.elements={{width=20},{width=bad}}
    equal(ship:_GetPathfindingCorridorWidth(),50)
  end
  ship.elements={{width=20},{}}
  equal(ship:_GetPathfindingCorridorWidth(),50)
end)

test("NAVYGROUP defaults check lateral clearance and actual stationary positions",function()
  local ship=vessel():SetPathfindingOn()
  ship.elements={{width=20}}
  equal(ship:_GetPathfindingCorridorWidth(),40)
  local start,goal=coord(0),coord(1000)
  land.surfaceAt=function(p)
    if p.x>=400 and p.x<=600 and p.z>=19 and p.z<=21 then return land.SurfaceType.LAND end
    return land.SurfaceType.WATER
  end
  assert(ASTAR.Depth({vector=start},{vector=goal},20,0))
  equal(ship:_CheckPathDepth(start,goal),false)
  equal(ship:_CheckPathDepth(goal,start),false)
  -- A shoal 500 meters beside a 20-meter ship must not block its otherwise clear route.
  land.surfaceAt=function(p)
    if p.x>=400 and p.x<=600 and p.z>=450 and p.z<=550 then return land.SurfaceType.LAND end
    return land.SurfaceType.WATER
  end
  assert(ship:_CheckPathDepth(start,goal))
  land.surfaceAt=nil
  assert(ship:_CheckPathDepth(start,goal))
  assert(ship:_CheckPathDepth(goal,goal))
  ship.depthTerrain.depth=5
  equal(ship:_CheckPathDepth(goal,goal),false)
end)

test("NAVYGROUP default coastal route keeps its clearance through smoothing and waypoint callbacks",function()
  local ship=vessel():SetPathfindingOn()
  land.surfaceAt=island
  assert(ship:_FindPathToNextWaypoint())
  local report=ship.LastPathfindingResult
  local updates=ship.updates
  assert(ship.added>0)
  while ship:GetWaypointNext().astar do
    local waypoint=ship:GetWaypointNext()
    assert(ship:_CheckPathDepth(ship.position,waypoint.coordinate))
    ship.position=waypoint.coordinate
    OPSGROUP._PassingWaypoint(ship,waypoint.uid)
    equal(ship.updates,updates) equal(ship.cruises,0) equal(ship.stops,0)
    equal(ship.LastPathfindingResult,report)
  end
  assert(ship:_CheckPathDepth(ship.position,ship:GetWaypointNext().coordinate))
end)

test("NAVYGROUP uses the ASTAR depth rule and preserves shoal avoidance through route simplification",function()
  local ship=vessel():SetPathfindingOn()
  ship.verbose=10
  ship.depthTerrain.depthAt=function(p)
    if p.x>=1800 and p.x<=3200 and math.abs(p.y)<=1200 then return 7 end
    return 30
  end

  -- Every point is classified as WATER; only the new depth rule can reject the direct connection.
  equal(ship:_CheckPathDepth(ship.position,ship.waypoints[2].coordinate),false)
  assert(ship:_FindPathToNextWaypoint())
  assert(ship.added>0)
  equal(ship.pathfindingDebugSearch.ValidNeighbourFunc,ASTAR.Depth)
  equal(ship.LastPathfindingResult.MinDepth,20)
  equal(ship.LastPathfindingResult.CorridorWidth,50)

  local previous=ship.position
  for i=2,#ship.waypoints do
    assert(ship:_CheckPathDepth(previous,ship.waypoints[i].coordinate))
    previous=ship.waypoints[i].coordinate
  end
  equal(ship.updates,1) equal(ship.stops,0)
end)

test("NAVYGROUP reaches the original waypoint and plans the second island when short profiles have no support points",function()
  local ship=vessel():SetPathfindingOn()
  ship.waypoints[3]={uid=3,coordinate=coord(10000),speed=10,npassed=0}
  ship.nextID=3
  function ship:PassingWaypoint() end

  local normalProfile=ship.depthTerrain.makeProfile
  ship.depthTerrain.makeProfile=function(a,b)
    if math.sqrt((b.x-a.x)^2+(b.z-a.z)^2)<600 then return {} end
    return normalProfile(a,b)
  end
  ship.depthTerrain.depthAt=function(p)
    if ((p.x>=1800 and p.x<=3200) or (p.x>=6800 and p.x<=8200)) and math.abs(p.y)<=1200 then return 7 end
    return 30
  end

  assert(ship:_FindPathToNextWaypoint())
  while ship:GetWaypointNext().astar do
    local waypoint=ship:GetWaypointNext()
    ship.position=waypoint.coordinate
    OPSGROUP._PassingWaypoint(ship,waypoint.uid)
  end

  -- Reproduce the 160 m final approach from the trace. It must not create a tiny replacement grid or stop the ship.
  local report,updates=ship.LastPathfindingResult,ship.updates
  ship.position={x=4840,y=0,z=0}
  assert(ship:_ContinuePathfinding())
  equal(ship.LastPathfindingResult,report) equal(ship.updates,updates) equal(ship.stops,0)

  local originalWaypoint=ship:GetWaypointNext()
  equal(originalWaypoint.uid,2)
  ship.position=originalWaypoint.coordinate
  OPSGROUP._PassingWaypoint(ship,originalWaypoint.uid)
  equal(ship:GetWaypointNext().uid,3)

  assert(ship:_CheckFreePath(5000)<5000)
  assert(ship:_FindPathToNextWaypoint())
  equal(ship.pathfindingTargetUID,3)
  assert(ship:GetWaypointNext().astar)
  local previous=ship.position
  for i=ship:GetWaypointIndexNext(),#ship.waypoints do
    assert(ship:_CheckPathDepth(previous,ship.waypoints[i].coordinate))
    previous=ship.waypoints[i].coordinate
  end
  equal(ship.stops,0)
end)

test("NAVYGROUP retains a useful FINE search area for genuinely blocked short connections",function()
  local ship=vessel(160):SetPathfindingOn(0)
  ship.depthTerrain.depthAt=function(p)
    if p.x>=70 and p.x<=90 and math.abs(p.y)<150 then return 7 end
    return 30
  end
  assert(ship:_FindPathToNextWaypoint())
  assert(ship.LastPathfindingResult.Width>=2000)
  equal(ship.LastPathfindingResult.Spacing,50)
  assert(ship.added>0) equal(ship.stops,0)
end)

test("NAVYGROUP collision checks find shallow water before a deep lookahead endpoint",function()
  local ship=vessel():SetPathfindingOn(0)
  ship.depthTerrain.depthAt=function(p)
    if p.x>=750 and p.x<=900 then return 8 end
    return 30
  end
  local free=ship:_CheckFreePath(5000)
  assert(free>=700 and free<750,tostring(free))
  assert(ship:_CheckPathDepth(ship.position,coord(free)))
  assert(ship.depthTerrain.profiles<=14)
  equal(ship:_CheckFreePath(0),0)

  -- The depth setting is shared by collision checks; it remains in effect when automatic detours are disabled.
  ship:SetPathfindingMinDepth(5)
  equal(ship:_CheckFreePath(5000),5000)
  ship:SetPathfindingMinDepth(20):SetPathfindingOff()
  assert(ship:_CheckFreePath(5000)<750)
end)

test("NAVYGROUP depth collisions check the corridor edges and reject missing depth data",function()
  local ship=vessel():SetPathfindingOn()
  ship.depthTerrain.depthAt=function(p)
    if p.x>=750 and p.x<=900 and p.y==25 then return 8 end
    return 30
  end
  assert(ship:_CheckFreePath(5000)<750)
  ship:SetPathfindingOn(0)
  equal(ship:_CheckFreePath(5000),5000)
  land.profile=nil
  equal(ship:_CheckFreePath(5000),0)
  equal(ship:_FindPathToNextWaypoint(),false)
  equal(ship.stops,1) equal(ship.updates,0)
end)

test("NAVYGROUP minimum depth validates atomically and rechecks active detours after a change",function()
  local ship=vessel():SetPathfindingMinDepth(15):SetPathfindingOn()
  equal(ship.pathMinDepth,15)
  ship:SetPathfindingOff():SetPathfindingOn()
  equal(ship.pathMinDepth,15)
  for _,bad in ipairs({false,"20",0,-1,math.huge,0/0}) do
    assert(not pcall(function() ship:SetPathfindingMinDepth(bad) end))
    equal(ship.pathMinDepth,15)
  end
  ship:SetPathfindingMinDepth() equal(ship.pathMinDepth,20)
  land.surfaceAt=island
  assert(ship:_FindPathToNextWaypoint())

  ship:SetPathfindingMinDepth(40)
  equal(ship:_ContinuePathfinding(),false)
  equal(ship.stops,1) equal(ship.pathfindingStopped,true)
  equal(ship.LastPathfindingResult.MinDepth,40)
end)

test("NAVYGROUP stops a blocked actual detour leg while turning without waiting for retry timeout",function()
  local ship=vessel():SetPathfindingOn()
  land.surfaceAt=island assert(ship:_FindPathToNextWaypoint())
  local report=ship.LastPathfindingResult
  function ship:IsTurning() return true end
  assert(ship:_ContinuePathfinding()) equal(ship.LastPathfindingResult,report)
  -- No further safe route exists. The periodic route check must stop immediately, even within cooldown.
  land.surfaceAt=function() return land.SurfaceType.LAND end
  equal(ship:_ContinuePathfinding(),false)
  equal(ship.stops,1) equal(ship.cruises,0) equal(ship.updates,1)
  equal(ship.pathfindingStopped,true) assert(ship.LastPathfindingResult~=report)
end)

test("NAVYGROUP waypoint callback replaces a blocked leg without an intermediate stop",function()
  local ship=vessel():SetPathfindingOn()
  land.surfaceAt=island
  assert(ship:_FindPathToNextWaypoint())

  local report,updates=ship.LastPathfindingResult,ship.updates
  local waypoint,nextWaypoint=ship.waypoints[2],ship.waypoints[3]
  ship.position=waypoint.coordinate

  -- Block the installed next leg while leaving room for a different detour.
  -- The actual waypoint callback must replace it without issuing a zero-speed mission first.
  local x=(waypoint.coordinate.x+nextWaypoint.coordinate.x)/2
  local z=(waypoint.coordinate.z+nextWaypoint.coordinate.z)/2
  local radius=math.min(100,waypoint.coordinate:GetDistance(nextWaypoint.coordinate,true)/4)
  land.surfaceAt=function(p)
    if (p.x-x)^2+(p.z-z)^2<radius^2 then return land.SurfaceType.LAND end
    return island(p)
  end
  equal(ship:_CheckPathDepth(ship.position,nextWaypoint.coordinate),false)

  OPSGROUP._PassingWaypoint(ship,waypoint.uid)

  assert(ship.LastPathfindingResult~=report)
  equal(ship.stops,0)
  equal(ship.resumes,0)
  equal(ship.cruises,0)
  equal(ship.updates,updates+1)
  equal(ship:GetState(),"Cruising")
  equal(ship.navigationHold,nil)
  equal(ship.pathfindingStopped,nil)
  equal(ship.waypoints[#ship.waypoints].uid,2)

  local previous=ship.position
  for i=ship:GetWaypointIndexNext(),#ship.waypoints do
    assert(ship:_CheckPathDepth(previous,ship.waypoints[i].coordinate))
    previous=ship.waypoints[i].coordinate
  end
end)

test("NAVYGROUP waypoint callback stops when synchronous replanning fails",function()
  local ship=vessel():SetPathfindingOn()
  land.surfaceAt=island assert(ship:_FindPathToNextWaypoint())
  local previousReport=ship.LastPathfindingResult
  local reportAtStop
  function ship:OnAfterFullStop()
    reportAtStop=self.LastPathfindingResult
  end

  local waypoint=ship:GetWaypointNext()
  ship.position=waypoint.coordinate
  land.surfaceAt=function() return land.SurfaceType.LAND end
  OPSGROUP._PassingWaypoint(ship,waypoint.uid)

  -- A failed plan must still stop immediately, but only after its failure has been established.
  assert(reportAtStop~=previousReport)
  equal(reportAtStop,ship.LastPathfindingResult)
  equal(ship.stops,1) equal(ship.cruises,0) equal(ship.updates,1)
  equal(ship.pathfindingStopped,true)
end)

test("NAVYGROUP replan diagnostics distinguish an early callback chord from the original clear leg",function()
  local ship=vessel(3000):SetPathfindingOn()
  ship.pathCorridor=20
  ship.position={x=600,y=0,z=-100}
  local passed={uid=4,coordinate=coord(1000),speed=10,npassed=0,astar=true}
  local nextWaypoint={uid=5,coordinate=coord(2000),speed=10,npassed=0,astar=true}
  table.insert(ship.waypoints,2,passed)
  table.insert(ship.waypoints,3,nextWaypoint)

  -- The callback fires before the stored waypoint. Only the direct chord from the
  -- actual ship position crosses this shoal; the original waypoint-to-waypoint leg is clear.
  ship.depthTerrain.depthAt=function(p)
    return p.x>=1100 and p.x<=1300 and p.y<=-40 and 10 or 30
  end
  local checks,logs,positionReads,plans={},{},0,0
  function ship:IsTrace() return true end
  function ship:T(message) logs[#logs+1]=message end
  function ship:GetVec3() positionReads=positionReads+1 return self.position end
  function ship:_CheckPathDepth(a,b,detailed)
    local clear,reason,report=NAVYGROUP._CheckPathDepth(self,a,b,detailed)
    checks[#checks+1]={start=a,goal=b,clear=clear,report=report}
    return clear,reason,report
  end
  function ship:_FindPathToNextWaypoint(force)
    equal(force,true) plans=plans+1 return true
  end

  OPSGROUP._PassingWaypoint(ship,passed.uid)

  equal(positionReads,1) equal(#checks,2) equal(plans,1) equal(ship.stops,0)
  equal(checks[1].start,ship.position) equal(checks[1].goal,nextWaypoint.coordinate)
  equal(checks[1].clear,false) equal(checks[1].report.Cause,"insufficient_depth")
  equal(checks[2].start,passed.coordinate) equal(checks[2].goal,nextWaypoint.coordinate)
  equal(checks[2].clear,true)

  -- The diagnostic comparison must not replace the actual obstacle report or
  -- clear a navigation warning merely because the original planned leg is safe.
  equal(ship.LastNavigationCheck,checks[1].report)
  equal(ship.warnings,1) equal(ship.clears,0)
  local output=table.concat(logs,"\n")
  for _,expected in ipairs({"passed UID=4, next UID=5", "heading=0 deg, speed=10 m/s, corridor=20.0 m",
    "ship=(x=600.000, z=-100.000)", "distance_to_passed=412.3 m",
    "actual_position_to_next: status=blocked", "cause=insufficient_depth",
    "depth=10 m, required_depth=20 m", "surface=WATER (3)", "location=profile",
    "offset="..tostring(checks[1].report.ProfileOffset).." m",
    "actual_position_to_next rejected sample: x="..tostring(checks[1].report.Point.x),
    "passed_waypoint_to_next: status=clear"}) do
    assert(output:find(expected,1,true),"Missing diagnostic: "..expected.."\n"..output)
  end
end)

test("NAVYGROUP diagnostics add no terrain queries when tracing is disabled or the actual leg is clear",function()
  for _,trace in ipairs({false,true}) do
    local ship=vessel():SetPathfindingOn()
    local checks,plans=0,0
    local passed={uid=4,coordinate=coord(1000),astar=true}
    local report={Status=trace and "clear" or "blocked",Reason="profile_blocked",
      Cause="insufficient_depth",Distance=1000,ClearDistance=400,RequiredDepth=20}
    function ship:IsTrace() return trace end
    function ship:_CheckPathDepth()
      checks=checks+1 return trace,report.Reason,report
    end
    function ship:_FindPathToNextWaypoint() plans=plans+1 return true end

    assert(ship:_ContinuePathfinding(passed))

    equal(checks,1) equal(plans,trace and 0 or 1) equal(ship.stops,0)
    equal(ship.LastNavigationCheck,report)
  end
end)

test("NAVYGROUP replan diagnostics tolerate unavailable depth data without a passed waypoint",function()
  local ship=vessel():SetPathfindingOn()
  local checks,plans,logs=0,0,{}
  local report={Status="unavailable",Reason="profile_query_failed",Cause="profile_query_failed",
    Distance=5000,ClearDistance=0,RequiredDepth=20}
  function ship:IsTrace() return true end
  function ship:T(message) logs[#logs+1]=message end
  function ship:_CheckPathDepth() checks=checks+1 return false,report.Reason,report end
  function ship:_FindPathToNextWaypoint(force) equal(force,true) plans=plans+1 return true end

  assert(ship:_ContinuePathfinding())

  equal(checks,1) equal(plans,1) equal(ship.stops,0)
  equal(ship.LastNavigationCheck,report)
  local output=table.concat(logs,"\n")
  assert(output:find("actual_position_to_next: status=unavailable",1,true),output)
  assert(output:find("cause=profile_query_failed",1,true),output)
  assert(output:find("surface=n/a (nil), profile=n/a",1,true),output)
end)

test("NAVYGROUP warning callbacks can cancel a replan before diagnostic terrain comparisons",function()
  local ship=vessel():SetPathfindingOn()
  local checks=0
  local passed={uid=4,coordinate=coord(1000),astar=true}
  function ship:IsTrace() return true end
  function ship:_CheckPathDepth()
    checks=checks+1
    return false,"profile_blocked",{Status="blocked",Reason="profile_blocked",ClearDistance=100}
  end
  function ship:OnAfterCollisionWarning() self:FullStop() end
  function ship:_FindPathToNextWaypoint() error("A manual stop must retain control") end

  equal(ship:_ContinuePathfinding(passed),false)

  equal(checks,1) equal(ship.stops,1) equal(ship:GetState(),"Holding")
end)

test("NAVYGROUP retains a clear detour across retry intervals despite heading-based warnings",function()
  resetDrawings()
  local ship=vessel() ship.verbose=10
  land.surfaceAt=island assert(ship:_FindPathToNextWaypoint())
  local report,owner=ship.LastPathfindingResult,ship.pathfindingDebugSearch
  local added,updates=ship.added,ship.updates
  local nextPoint=ship.waypoints[2].coordinate
  local ids={} for i,wp in ipairs(ship.waypoints) do ids[i]=wp.uid end
  local original=ASTAR.New
  ASTAR.New=function() error("A clear active route must not create another ASTAR/grid") end
  local ok,err=pcall(function()
    for i=1,3 do
      timerNow=i*61
      ship.position={x=nextPoint.x*i/10,y=0,z=nextPoint.z*i/10}
      assert(ship:_CheckFreePath(5000)<5000)
      assert(ship:_FindPathToNextWaypoint())
      equal(ship.LastPathfindingResult,report) equal(ship.pathfindingDebugSearch,owner)
      equal(ship.added,added) equal(ship.updates,updates)
      for j,wp in ipairs(ship.waypoints) do equal(wp.uid,ids[j]) end
    end
  end)
  ASTAR.New=original
  assert(ok,err)
end)

test("NAVYGROUP replaces only its own debug overlay and cancels pending old batches",function()
  resetDrawings()
  local a,b=vessel(),vessel() a.verbose=10 b.verbose=10
  land.surfaceAt=island assert(a:_FindPathToNextWaypoint()) assert(b:_FindPathToNextWaypoint())
  local previous=a.pathfindingDebugSearch
  local options=previous:GetGrid():GetOptions()
  equal(options.Resolution,GRID.Resolution.FINE) equal(options.Spacing,nil)
  equal(options.Width,GRID.Width.NORMAL) equal(options.Margin,GRID.Margin.SMALL)
  equal(options.MaxCells,5000)
  assert(previous:GetGrid():GetCandidateCount()<=options.MaxCells)
  local oldIDs=deepcopy(previous.GridDrawIDs)
  local other=b.pathfindingDebugSearch
  local otherIDs=deepcopy(other.GridDrawIDs)
  local oldJob=assert(previous.GridDrawJob)
  assert(a:_FindPathToNextWaypoint(true))
  assert(a.pathfindingDebugSearch~=previous)
  equal(previous.GridDrawJob,nil) equal(scheduled[oldJob.timerID],nil)
  for _,id in ipairs(oldIDs) do equal(drawings[id],nil) end
  for _,id in ipairs(otherIDs) do assert(drawings[id]) end
  flushTimers()
  for _,id in ipairs(oldIDs) do equal(drawings[id],nil) end
  equal(count(drawings),#a.pathfindingDebugSearch.GridDrawIDs+#other.GridDrawIDs)
  a:SetPathfindingOff()
  equal(a.pathfindingDebugSearch,nil) equal(count(drawings),#other.GridDrawIDs)
end)

test("NAVYGROUP removes an old debug overlay when a forced replan fails",function()
  resetDrawings()
  local ship=vessel() ship.verbose=10
  land.surfaceAt=island assert(ship:_FindPathToNextWaypoint())
  local previous=ship.pathfindingDebugSearch
  ship:SetPathfindingGrid(1)
  equal(ship:_FindPathToNextWaypoint(true),false)
  equal(ship.pathfindingDebugSearch,nil) equal(previous.GridDrawJob,nil)
  flushTimers() equal(count(drawings),0) equal(ship.stops,1)
end)

test("NAVYGROUP dispatches only a checked into-wind segment and replans through the waypoint callback",function()
  local ship=vessel(UTILS.NMToMeters(1000))
  ship.waypoints[2].intowind=true
  assert(ship:_FindPathToNextWaypoint())
  equal(ship.added,1) equal(ship.waypoints[3].uid,2)
  local endpoint=ship.waypoints[2]
  assert(endpoint.astarReplan) near(endpoint.coordinate.x,UTILS.NMToMeters(20))
  ship:onafterUpdateRoute()
  equal(#ship.dispatched,2) equal(ship.dispatched[2].uid,endpoint.uid)
  ship.position=endpoint.coordinate
  OPSGROUP._PassingWaypoint(ship,endpoint.uid)
  equal(ship:GetWaypointByID(endpoint.uid),nil)
  assert(ship.waypoints[2].astarReplan) near(ship.waypoints[2].coordinate.x,UTILS.NMToMeters(40))
  equal(ship.waypoints[3].uid,2) equal(ship.updates,2)
end)

test("NAVYGROUP late detour callbacks cannot release manual holds after pathfinding is disabled",function()
  for _,command in ipairs({"FullStop","Wait"}) do
    for _,rolling in ipairs({false,true}) do
      local ship=vessel()
      local waypoint=ship:AddWaypoint(VECTOR:New(1000,0,0),20,1,nil,false)
      waypoint.astar=true
      waypoint.astarReplan=rolling
      ship.depth=40
      ship:SetPathfindingOff()
      ship[command](ship)

      -- DCS can deliver the old waypoint callback after the user's stop command.
      ship.position=waypoint.coordinate
      OPSGROUP._PassingWaypoint(ship,waypoint.uid)
      equal(ship:GetState(),"Holding")
      equal(ship:IsWaiting(),command=="Wait")
      equal(ship.depth,40)
      equal(ship.cruises,0)
      equal(ship.resumes,0)
      equal(ship.updates,0)
    end
  end
end)

test("NAVYGROUP disabled pathfinding continues installed legs and releases only rolling remainders",function()
  for _,rolling in ipairs({false,true}) do
    local ship=vessel()
    local waypoint=ship:AddWaypoint(VECTOR:New(1000,0,0),20,1,nil,false)
    waypoint.astar=true
    waypoint.astarReplan=rolling
    ship.depth=40
    ship:SetPathfindingOff()

    ship.position=waypoint.coordinate
    OPSGROUP._PassingWaypoint(ship,waypoint.uid)
    equal(ship:GetState(),"Cruising")
    equal(ship.depth,40)
    equal(ship.cruises,0)
    equal(ship.resumes,0)
    equal(ship.updates,rolling and 1 or 0)
    equal(ship:GetWaypointNext().uid,2)
  end
end)

test("NAVYGROUP into-wind continuation failure stops before dispatching the unchecked remainder",function()
  local ship=vessel(UTILS.NMToMeters(1000)):SetPathfindingGrid(1)
  ship.waypoints[2].intowind=true assert(ship:_FindPathToNextWaypoint())
  local endpoint=ship.waypoints[2] ship.position=endpoint.coordinate
  land.surfaceAt=function(p) if p.x>UTILS.NMToMeters(21) then return land.SurfaceType.LAND end return land.SurfaceType.WATER end
  OPSGROUP._PassingWaypoint(ship,endpoint.uid)
  equal(ship.stops,1) equal(ship.updates,1) equal(ship.cruises,0) equal(ship.pathfindingStopped,true)
end)

test("NAVYGROUP direct routes bypass grid construction and preserve original route data",function()
  local ship=vessel():SetPathfindingGrid(1)
  local target=ship.waypoints[2]
  assert(ship:_FindPathToNextWaypoint())
  equal(ship.LastPathfindingResult.StopReason,"direct_path") equal(ship.added,0) equal(ship.updates,1)
  equal(ship.waypoints[2],target)
end)

test("NAVYGROUP closes an into-wind window without retaining its pending detour points",function()
  local ship=vessel(UTILS.NMToMeters(1000))
  local target=ship.waypoints[2] target.intowind=true
  ship.waypoints[3]={uid=99,coordinate=coord(7000),speed=10}
  ship.intowind={Id=7,waypoint=target,Uturn=false}
  function ship:T2() end
  function ship:GetSpeedToWaypoint() return 20 end
  function ship:RemoveTurnIntoWind() end
  assert(ship:_FindPathToNextWaypoint())
  ship:onafterTurnIntoWindOver(nil,nil,nil,ship.intowind)
  equal(#ship.waypoints,2) equal(ship.waypoints[2].uid,99)
  equal(ship.intowind,nil) equal(ship.ispathfinding,false)
end)

test("surface neighbour rules reject land between manually added water nodes and invalidate changed filters",function()
  local a=ASTAR:New():SetValidSurfaceTypes(land.SurfaceType.WATER):SetValidNeighbourSurface(100)
  local first=a:AddNodeFromCoordinate(coord(0)) local last=a:AddNodeFromCoordinate(coord(1000))
  a:SetStartCoordinate(first.vector):SetEndCoordinate(last.vector)
  land.surfaceAt=function(p) return p.x==500 and land.SurfaceType.LAND or land.SurfaceType.WATER end
  equal(a:GetPath(),nil) equal(a:GetGrid().GridBuilt,nil)
  equal(a:_IsValidNeighbour(last,first),false)
  a:GetGrid():SetValidSurfaceTypes(nil)
  assert(a:GetPath())
  a:SetValidSurfaceTypes(land.SurfaceType.WATER)
  equal(a:GetPath(),nil)
end)

test("surface corridor samples endpoints center and edges symmetrically without modifying input positions",function()
  local g=GRID:New("Check",GRID.Type.RECTANGLE):SetValidSurfaceTypes(land.SurfaceType.WATER)
  local first,last={x=0,y=50,z=0},{x=1000,y=75,z=0}
  land.surfaceAt=function(p) return p.x==500 and p.z==100 and land.SurfaceType.LAND or land.SurfaceType.WATER end
  assert(g:CheckSurfacePath(first,last,100,0))
  local clear,free=g:CheckSurfacePath(first,last,100,200)
  equal(clear,false) equal(free,400)
  equal(g:CheckSurfacePath(last,first,100,200),false)
  equal(first.y,50) equal(last.y,75)
  land.surfaceAt=function(p) return p.x==1000 and land.SurfaceType.LAND or land.SurfaceType.WATER end
  equal(g:CheckSurfacePath(first,last,100),false)
  equal(g:CheckSurfacePath(last,last,100),false)
  land.surfaceAt=nil
  clear,free=g:CheckSurfacePath(first,last,125,200) equal(clear,true) equal(free,1000)
end)

test("building through GRID after a filter change invalidates earlier manual surface-rule results",function()
  local a=ASTAR:New():SetValidNeighbourSurface(100)
  a:AddNodeFromCoordinate(coord(0)) a:AddNodeFromCoordinate(coord(1000))
  a:SetStartCoordinate(coord(0)):SetEndCoordinate(coord(1000))
  land.surfaceAt=function(p) return p.x==500 and land.SurfaceType.LAND or land.SurfaceType.WATER end
  assert(a:GetPath())
  a:GetGrid():SetOptions({Width=0,Margin=0,Spacing=1000}):SetValidSurfaceTypes(land.SurfaceType.WATER):CreateFromBounds(coord(0),coord(1000))
  equal(a:GetPath(),nil)
end)

test("NAVYGROUP uses FINE corridor resolution on long legs and validates limits atomically",function()
  local ship=vessel(50000):SetPathfindingGrid(1):SetPathfindingOn(200)
  land.surfaceAt=island equal(ship:_FindPathToNextWaypoint(),false)
  equal(ship.LastPathfindingResult.Spacing,750) equal(ship.LastPathfindingResult.StopReason,"cell_limit")
  assert(not pcall(function() ship:SetPathfindingGrid(0,5) end)) equal(ship.pathMaxCells,1)
  assert(not pcall(function() ship:SetPathfindingGrid(5000,1) end)) equal(ship.pathMaxCells,1)
  ship:SetPathfindingGrid(8000,2,3)
  equal(ship.pathMaxCells,8000) equal(ship.pathGrowthFactor,2) equal(ship.pathMaxAttempts,3)
  assert(not pcall(function() ship:SetPathfindingOn(false) end)) equal(ship.pathCorridor,200)
  assert(not pcall(function() ship:SetPathfindingRetry(false) end))
end)

test("surface sampling rejects invalid settings and bounds excessive sampling before terrain queries",function()
  local g=GRID:New("Limits",GRID.Type.RECTANGLE):SetValidSurfaceTypes(land.SurfaceType.WATER)
  for _,step in ipairs({false,0,-1,math.huge}) do
    assert(not pcall(function() g:CheckSurfacePath(coord(0),coord(1000),step) end))
    assert(not pcall(function() ASTAR:New():SetValidNeighbourSurface(step) end))
  end
  for _,width in ipairs({false,-1,math.huge}) do
    assert(not pcall(function() g:CheckSurfacePath(coord(0),coord(1000),100,width) end))
  end
  land.surfaceAt=function() error("Sample limit must be checked before sampling") end
  local clear,free,reason=g:CheckSurfacePath(coord(0),coord(1000),1e-309,100)
  equal(clear,false) equal(free,0) equal(reason,"sample_limit")
end)

test("NAVYGROUP debug drawing uses the existing search result without another search",function()
  local ship=vessel() ship.verbose=10
  land.surfaceAt=island
  local original=ASTAR._SearchPath local calls=0
  ASTAR._SearchPath=function(self,...) calls=calls+1 return original(self,...) end
  local ok,result=pcall(ship._FindPathToNextWaypoint,ship)
  ASTAR._SearchPath=original
  assert(ok,result) assert(result) equal(calls,#ship.LastPathfindingResult.Attempts)
  equal(ship.updates,1)
end)

test("NAVYGROUP preserves target depth on generated detour waypoints",function()
  local ship=vessel() ship.waypoints[2].coordinate.y=-20
  land.surfaceAt=island assert(ship:_FindPathToNextWaypoint())
  for i=2,#ship.waypoints do equal(ship.waypoints[i].coordinate.y,-20) end
end)

test("grid configuration copies nested settings resets and stays independent", function()
  local settings={Width=6000,Margin=1000,Spacing=500,MaxCells=1000,Expansion={GrowthFactor=2,MaxAttempts=3}}
  local a,b=ASTAR:New(),ASTAR:New()
  equal(a:SetGridOptions(settings),a)
  settings.Expansion.MaxAttempts=99 settings.Width=999
  local effective=a:GetGridOptions()
  equal(effective.Width,6000) equal(effective.Expansion.MaxAttempts,3)
  effective.Expansion.GrowthFactor=7
  equal(a:GetGridOptions().Expansion.GrowthFactor,2)
  equal(b:GetGridOptions().Width,40000) equal(b:GetGridOptions().MaxCells,5000)
  a:SetGridOptions({Spacing=1500})
  equal(a:GetGridOptions().Width,6000) equal(a:GetGridOptions().Expansion.MaxAttempts,3)
  a:SetGridOptions() equal(a:GetGridOptions().Spacing,1500)
  a:GetGrid():ResetOptions()
  equal(a:GetGridOptions().Width,40000) equal(a:GetGridOptions().Spacing,2000) equal(a:GetGridOptions().Expansion.MaxAttempts,5)
end)

test("surface configuration validates copies and locks even for empty filtered grids", function()
  local surfaces={land.SurfaceType.WATER}
  local a=ASTAR:New():SetValidSurfaceTypes(surfaces)
  surfaces[1]=land.SurfaceType.LAND
  equal(a:GetGrid().ValidSurfaceTypes[1],land.SurfaceType.WATER)
  for _,bad in ipairs({false,"water",0,6,1.5,{0},{foo=3},{[2]=3},{[1]=3,[3]=1}}) do
    equal(pcall(function() a:SetValidSurfaceTypes(bad) end),false)
    equal(a:GetGrid().ValidSurfaceTypes[1],land.SurfaceType.WATER)
  end
  a:SetValidSurfaceTypes():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(4000))
  equal(a:GetGrid().ValidSurfaceTypes,nil)
  a:SetValidSurfaceTypes({}):SetGridOptions({Width=0,Margin=0,Spacing=1000}):CreateHexGrid()
  equal(a.Nnodes,0) equal(a:GetGrid().GridBuilt,true)
  equal(pcall(function() a:SetValidSurfaceTypes(land.SurfaceType.WATER) end),false)
  equal(pcall(function() a:CreateHexGrid() end),false)
end)

test("configuration rejects unknown keys and bad limits without changing previous settings", function()
  local a=ASTAR:New():SetGridOptions({Spacing=1500})
  for _,bad in ipairs({false,"invalid",{Width=-1},{Width=0/0},{Margin=math.huge},{Spacing=0},{CrossSpacing=false},
    {MaxCells=0},{MaxCells=1.5},{MaxCells=math.huge},{Spcing=1000},{Expansion=false},
    {Expansion={GrowthFactor=1}},{Expansion={MaxAttempts=0}},{Expansion={MaxWidth=-1}},
    {Expansion={MaxMargin=math.huge}},{Expansion={MaxCells=5}},{Expansion={Redraw=false}}}) do
    equal(pcall(function() a:SetGridOptions(bad) end),false)
    equal(a:GetGridOptions().Spacing,1500)
  end
end)

test("built geometry is locked while shared search limits can be changed", function()
  local a=hexgrid(0,0):SetGridNeighboursOnly(true)
  local options=a:GetGridOptions()
  options.Spacing=500
  equal(pcall(function() a:SetGridOptions(options) end),false)
  options=a:GetGridOptions() options.MaxCells=1 options.Expansion.MaxAttempts=2
  a:SetGridOptions(options)
  local path,report=a:GetPathWithExpansion()
  equal(path,nil) equal(report.StopReason,"cell_limit") equal(#report.Attempts,0)
  options.MaxCells=5000 a:SetGridOptions(options)
  assert(a:GetPathWithExpansion())
  equal(pcall(function() a:GetPathWithExpansion({}) end),false)
  equal(pcall(function() a:GetPathWithExpansion(nil,{}) end),false)
end)

test("hex builders reject CrossSpacing before mutation and defaults protect initial work", function()
  for _,zone in ipairs({false,true}) do
    local a=ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(4000))
    a:SetGridOptions({CrossSpacing=2000})
    local circle=circleZone(0,0,1000)
    equal(pcall(function()
      if zone then a:CreateHexGridFromZone(circle) else a:CreateHexGrid() end
    end),false)
    equal(a.Nnodes,0) equal(a:GetGrid().GridBuilt,nil)
  end
  local a=ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(100000000))
  land.surfaceAt=function() error("Default budget must precede terrain sampling") end
  local grid,reason=a:CreateHexGrid()
  equal(grid,nil) equal(reason,"cell_limit") equal(a:GetGridOptions().MaxCells,5000)
end)

test("budget fitted growth finds a path that the full growth step cannot fit", function()
  local seen={}
  land.surfaceAt=function(c)
    local key=string.format("%.4f:%.4f",c.x,c.z)
    assert(not seen[key],"A cell was sampled twice") seen[key]=true
    return math.abs(c.x-2000)<1 and math.abs(c.z)<500 and land.SurfaceType.LAND or land.SurfaceType.WATER
  end
  local a=ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(4000))
  a:SetValidSurfaceTypes(land.SurfaceType.WATER):SetGridOptions({Width=0,Margin=0,Spacing=1000,MaxCells=15})
  a:CreateHexGrid():SetGridNeighboursOnly(true)
  local path,report=a:GetPathWithExpansion()
  assert(path) equal(report.StopReason,"path_found") equal(#report.Attempts,2)
  equal(report.BudgetLimited,true)
  assert(report.CandidateCells<=15 and report.CandidateCells>5)
  assert(report.Width<=2000 and report.Margin<=1000)
  equal(count(seen),report.CandidateCells)
end)

test("budget fitting uses spare margin cells when another row does not fit", function()
  local a=hexgrid(0,0):SetGridNeighboursOnly(true):SetValidNeighbourFunction(function() return false end)
  configureExpansion(a,{MaxCells=7})
  local _,report=a:GetPathWithExpansion()
  equal(report.StopReason,"cell_limit") equal(report.CandidateCells,7)
  equal(report.BudgetLimited,true) equal(#report.Attempts,2)
  near(report.Margin,1000)
end)

test("a full budget stops without resampling or repeating a graph search", function()
  local a=hexgrid(0,0):SetGridNeighboursOnly(true):SetValidNeighbourFunction(function() return false end)
  configureExpansion(a,{MaxCells=5})
  land.surfaceAt=function() error("Budget fitting must not query terrain") end
  local _,report=a:GetPathWithExpansion()
  equal(report.StopReason,"cell_limit") equal(report.CandidateCells,5) equal(#report.Attempts,1)
  equal(report.BudgetLimited,false) equal(report.Width,0) equal(report.Margin,0)
end)

test("manual enlargement obeys the same spatial and cell caps as expanding search", function()
  local a=hexgrid(0,0)
  configureExpansion(a,{MaxWidth=1000,MaxMargin=1000,MaxCells=7})
  local result,reason=a:ExpandGrid(2000,0)
  equal(result,nil) equal(reason,"size_limit") equal(a:GetGrid():GetCandidateCount(),5)
  result,reason=a:ExpandGrid(1000,2000)
  equal(result,nil) equal(reason,"size_limit")
  equal(a:ExpandGrid(1000,1000),a) equal(a:GetGrid():GetCandidateCount(),7)
end)

test("text markers are batched include indices and do not evaluate rules by default", function()
  resetDrawings()
  local labels={}
  trigger.action.markToAll=function(id,text,point,readOnly) labels[id]={text=text,point=point} equal(readOnly,true) end
  local a=hexgrid():SetGridNeighboursOnly(true):SetValidNeighbourFunction(function() error("Counts must be candidates only") end)
  a:DrawGrid() flushTimers()
  local polygons=count(drawings)
  a:MarkGrid({BatchSize=3})
  equal(count(labels),0) equal(a.LastGridMarkResult.Status,"queued")
  stepTimer() assert(count(labels)>0 and count(labels)<=3)
  flushTimers()
  equal(count(labels),a.Nnodes) equal(a.LastGridMarkResult.NodesMarked,a.Nnodes)
  equal(a.LastGridMarkResult.Status,"complete")
  for _,label in pairs(labels) do
    assert(label.text:match("Node %d+") and label.text:match("Hex: q=") and label.text:match("Candidates: %d+"))
    assert(not label.text:match("Valid connections:"))
  end
  a:UnmarkGrid() equal(#a.GridMarkIDs,0) equal(count(drawings),polygons)
  a:UndrawGrid() equal(count(drawings),0)
end)

test("text markers count checked neighbours and include rectangular indices and manual endpoints", function()
  local labels={}
  trigger.action.markToAll=function(id,text) labels[id]=text end
  local a=ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(2000))
  a:SetGridOptions({Width=0,Margin=0,Spacing=1000}):CreateGrid():SetGridNeighboursOnly(false):SetValidNeighbourDistance(1100)
  local manual=a:AddNodeFromCoordinate(coord(9000))
  equal(a:GetNodeNeighbourCount(manual),3) equal(a:GetNodeNeighbourCount(manual,true),0)
  a:MarkGrid({CheckNeighbours=true}) flushTimers()
  equal(count(labels),4)
  local regular,endpoint=0,0
  for _,text in pairs(labels) do
    assert(text:match("Candidates: 3") and text:match("Valid connections:"))
    if text:match("Grid: i=") then regular=regular+1 end
    if text:match("Manual / endpoint") then endpoint=endpoint+1 assert(text:match("Valid connections: 0")) end
  end
  equal(regular,3) equal(endpoint,1)
end)

test("marker replacement cancellation and errors retain independent ownership", function()
  local emitted={}
  trigger.action.markToAll=function(id,text) emitted[id]=text end
  local a,b=hexgrid(),hexgrid()
  a:MarkGrid({BatchSize=1}) stepTimer()
  local old=a.GridMarkJob local ids=deepcopy(a.GridMarkIDs)
  local stale=scheduled[old.timerID].fn
  b:MarkGrid()
  a:MarkGrid({BatchSize=1})
  equal(old.result.Status,"cancelled")
  equal(stale(),nil)
  for _,id in ipairs(ids) do
    local removed=false
    for _,value in ipairs(removals) do if value==id then removed=true end end
    assert(removed)
  end
  local pending=a.GridMarkJob
  equal(pcall(function() a:MarkGrid({BatchSize=0}) end),false) equal(a.GridMarkJob,pending)
  a:UnmarkGrid() equal(pending.result.Status,"cancelled")
  flushTimers()
  for _,id in ipairs(b.GridMarkIDs) do
    assert(emitted[id])
    for _,value in ipairs(removals) do assert(value~=id) end
  end
  trigger.action.markToAll=function() error("DCS marking failed") end
  a:MarkGrid() flushTimers()
  equal(a.LastGridMarkResult.Status,"error") equal(a.GridMarkJob,nil)
  trigger.action.markToAll=function(id,text) emitted[id]=text end
  a:MarkGrid() flushTimers() equal(a.LastGridMarkResult.Status,"complete")
end)

test("marking without a CPU clock processes one label per batch", function()
  local savedOS=os
  local marked=0
  trigger.action.markToAll=function() marked=marked+1 end
  local ok,err=pcall(function()
    os=nil
    local a=hexgrid():MarkGrid({BatchSize=100})
    stepTimer() equal(marked,1)
    flushTimers() equal(marked,a.Nnodes) equal(a.LastGridMarkResult.Batches,a.Nnodes)
    equal(a.LastGridMarkResult.CPUSeconds,nil)
  end)
  os=savedOS assert(ok,err)
end)

test("text marking respects CPU budget and does not allocate COORDINATE objects", function()
  local savedClock,savedNew=os.clock,COORDINATE.New
  local cpu,marked=0,0
  local ok,err=pcall(function()
    os.clock=function() return cpu end
    local a=hexgrid()
    COORDINATE.New=function() error("Labels must use VECTOR") end
    trigger.action.markToAll=function() cpu=cpu+0.004 marked=marked+1 end
    a:MarkGrid({BatchSize=100,MaxBatchSeconds=0.005})
    stepTimer() equal(marked,2)
    flushTimers()
    equal(marked,a.Nnodes) near(a.LastGridMarkResult.CPUSeconds,marked*0.004)
    near(a.LastGridMarkResult.MaxBatchCPUSeconds,0.008)
  end)
  os.clock=savedClock COORDINATE.New=savedNew assert(ok,err)
end)

test("marking routes labels to a coalition without changing polygons", function()
  coalition={side={NEUTRAL=0,RED=1,BLUE=2}}
  local marked=0
  trigger.action.markToCoalition=function(id,text,point,side,readOnly)
    equal(side,2) equal(readOnly,false) marked=marked+1
  end
  local a=hexgrid():MarkGrid({Coalition=2,ReadOnly=false})
  flushTimers() equal(marked,a.Nnodes)
  equal(pcall(function() a:MarkGrid({Coalition=5}) end),false)
  equal(pcall(function() a:MarkGrid({CheckNeighbours=1}) end),false)
end)

-- Rectangular growth shares the search policy with hex grids but preserves its original lattice.
test("rectangular expanding search finds a land detour and retains nodes and caches", function()
  local seen={}
  land.surfaceAt=function(c)
    local key=string.format("%.4f:%.4f",c.x,c.z)
    assert(not seen[key],"Rectangular cell sampled twice") seen[key]=true
    return c.x==2000 and math.abs(c.z)<500 and land.SurfaceType.LAND or land.SurfaceType.WATER
  end
  local a=ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(4000))
  a:SetGridOptions({Width=0,Margin=0,Spacing=1000}):SetValidSurfaceTypes(land.SurfaceType.WATER)
  a:CreateGrid():SetGridNeighboursOnly(false):SetValidNeighbourDistance(1100)
  local original={}
  for id,node in pairs(a.nodes) do original[id]=node end
  local path,report=a:GetPathWithExpansion()
  assert(path) equal(report.StopReason,"path_found") equal(#report.Attempts,2)
  equal(report.Attempts[1].Failure,"connections_blocked")
  equal(report.Width,2000) equal(report.Margin,1000) equal(report.CandidateCells,21)
  equal(a.Nnodes,20) assert(a.nvalidcache>0 and a.ncostcache>0)
  for id,node in pairs(original) do equal(a.nodes[id],node) end
  for i,node in ipairs(path) do
    equal(node.rectGrid,a.rectGrid)
    if i>1 then assert(node.vector:GetDistance(path[i-1].vector,true)<=1100) end
  end
end)

test("rectangular enlargement retains rotated fractional anisotropic lattice and manual nodes", function()
  for _,heading in ipairs({0,37,90,205}) do
    local origin=coord(123456,-234567)
    local a=ASTAR:New():SetStartCoordinate(origin):SetEndCoordinate(origin:Translate(4000,heading))
    local manual=a:AddNodeFromCoordinate(origin:Translate(17000,heading))
    a:SetGridOptions({Width=2500,Margin=125,Spacing=1000,CrossSpacing=750}):CreateGrid()
    local initial={}
    for id,node in pairs(a.nodes) do initial[id]={node,node.vector.x,node.vector.z,node.i,node.j} end
    local seen={}
    land.surfaceAt=function(c)
      local key=string.format("%.4f:%.4f",c.x,c.z)
      assert(not seen[key],"Duplicate enlargement sample") seen[key]=true
      for _,old in pairs(initial) do assert(math.abs(c.x-old[2])+math.abs(c.z-old[3])>0.001) end
      return land.SurfaceType.WATER
    end
    equal(a:ExpandGrid(4700,1375),a)
    equal(a:ExpandGrid(6700,2125),a)
    for id,old in pairs(initial) do
      equal(a.nodes[id],old[1]) equal(old[1].vector.x,old[2]) equal(old[1].vector.z,old[3])
      equal(old[1].i,old[4]) equal(old[1].j,old[5])
    end
    equal(a.nodes[manual.id],manual)
    local g=a.rectGrid local indices={}
    for _,node in pairs(a.nodes) do
      if node.rectGrid then
        local key=node.i..":"..node.j assert(not indices[key]) indices[key]=true
        local dx,dz=node.vector.x-origin.x,node.vector.z-origin.z
        near(dx*g.cos+dz*g.sin,-1125+node.j*1000)
        near(-dx*g.sin+dz*g.cos,-2000+node.i*750)
      end
    end
    equal(count(indices),g.candidateCount)
    land.surfaceAt=nil
  end
end)

test("rectangular expansion fits candidate budget before sampling", function()
  local queries=0
  land.surfaceAt=function(c)
    queries=queries+1 assert(queries<=17)
    return c.x==2000 and math.abs(c.z)<500 and land.SurfaceType.LAND or land.SurfaceType.WATER
  end
  local a=ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(4000))
  a:SetGridOptions({Width=0,Margin=0,Spacing=1000,MaxCells=17}):SetValidSurfaceTypes(land.SurfaceType.WATER)
  a:CreateGrid():SetValidNeighbourDistance(1100)
  local path,report=a:GetPathWithExpansion()
  assert(path) equal(report.StopReason,"path_found") equal(report.BudgetLimited,true)
  equal(#report.Attempts,2) equal(report.CandidateCells,15) equal(queries,15)
end)

test("rectangular expansion reports exhausted limits without repeating work", function()
  for _,case in ipairs({{MaxCells=5,reason="cell_limit"},
    {Expansion={MaxWidth=0,MaxMargin=0},reason="size_limit"},
    {Expansion={MaxAttempts=1},reason="attempt_limit"}}) do
    local a=ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(4000))
    a:SetGridOptions({Width=0,Margin=0,Spacing=1000,MaxCells=case.MaxCells,Expansion=case.Expansion})
    a:CreateGrid():SetValidNeighbourFunction(function() return false end)
    land.surfaceAt=function() error("No additional sampling allowed") end
    local path,report=a:GetPathWithExpansion()
    equal(path,nil) equal(report.StopReason,case.reason) equal(#report.Attempts,1) equal(a.Nnodes,5)
    land.surfaceAt=nil
  end
end)

test("rectangular zone expansion fills holes without resampling rejected terrain", function()
  local zones={circleZone(2000,0,1100),
    polygonZone(coord(0),0,{{999,-1001},{3001,-1001},{3001,1001},{2001,1001},{2001,1},{999,1}})}
  for _,zone in ipairs(zones) do
    local seen={}
    land.surfaceAt=function(c)
      local key=string.format("%.4f:%.4f",c.x,c.z)
      assert(not seen[key],"Zone cell sampled twice") seen[key]=true
      return c.x==2000 and c.z==0 and land.SurfaceType.LAND or land.SurfaceType.WATER
    end
    local a=ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(4000))
    a:SetGridOptions({Spacing=1000}):SetValidSurfaceTypes(land.SurfaceType.WATER):CreateGridFromZone(zone)
    local old=a.Nnodes local g=a.rectGrid
    equal(a:ExpandGrid(g.width,g.margin),a) equal(a.Nnodes,old)
    equal(a:ExpandGrid(5000,1000),a)
    equal(a:ExpandGrid(6000,2000),a)
    equal(count(seen),a:GetGrid():GetCandidateCount()) equal(a.Nnodes,a:GetGrid():GetCandidateCount()-1)
    equal(g.initialSamples,nil)
    assert(a:FindClosestNode(coord(0)).rectGrid)
    land.surfaceAt=nil
  end
end)

test("rectangular expanding search can leave small or empty zone seeds", function()
  for _,zone in ipairs({circleZone(0,0,100),circleZone(500,500,10)}) do
    local a=ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(4000))
    a:SetGridOptions({Spacing=1000,CrossSpacing=500}):CreateGridFromZone(zone):SetValidNeighbourDistance(1100)
    assert(a.Nnodes<=1)
    local path,report=a:GetPathWithExpansion()
    assert(path) equal(report.StopReason,"path_found") assert(#report.Attempts>1)
    near(report.Attempts[2].Width-report.Attempts[1].Width,1000)
  end
end)

test("manual rectangular expansion rejects over-budget and shrinking dimensions before mutation", function()
  local a=ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(4000))
  a:SetGridOptions({Width=0,Margin=0,Spacing=1000,MaxCells=20,Expansion={MaxWidth=2000,MaxMargin=1000}}):CreateGrid()
  land.surfaceAt=function() error("Rejected requests must not sample") end
  local result,reason=a:ExpandGrid(2000,1000) equal(result,nil) equal(reason,"cell_limit")
  result,reason=a:ExpandGrid(3000,0) equal(result,nil) equal(reason,"size_limit")
  equal(pcall(function() a:ExpandGrid(2000,0) end),false)
  equal(a.Nnodes,5) equal(a.rectGrid.width,0) equal(a:ExpandGrid(0,0),a)
  land.surfaceAt=nil
  equal(a:ExpandGrid(2000,0),a)
  equal(pcall(function() a:ExpandGrid(1000,0) end),false)
  local b=ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(0))
  b:SetGridOptions({Width=300000,Margin=150000,Spacing=100000}):CreateGrid()
  equal(b:GetGridOptions().Expansion.MaxWidth,nil) equal(b:GetGridOptions().Expansion.MaxMargin,nil)
end)

test("rectangular expansion leaves debug snapshots fixed and explicit redraw highlights the path", function()
  resetDrawings()
  local a=ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(4000))
  a:SetGridOptions({Width=0,Margin=0,Spacing=1000}):CreateGrid():SetValidNeighbourDistance(1100)
  local path=a:GetPathWithExpansion()
  a:DrawGridWithPath(path) flushTimers()
  local old=count(drawings) equal(old,5)
  a:ExpandGrid(2000,1000) flushTimers() equal(count(drawings),old)
  path=a:GetPathWithExpansion()
  a:DrawGridWithPath(path) flushTimers()
  equal(count(drawings),a.Nnodes)
  local green=0
  for _,drawing in pairs(drawings) do
    equal(#drawing.vertices,4)
    if drawing.fill[2]==1 and drawing.fill[1]==0 and drawing.fill[3]==0 then green=green+1 end
  end
  equal(green,#path)
end)

local function localRect(diagonals,heading,crossSpacing)
  local origin=coord(123456,-234567)
  local a=ASTAR:New():SetStartCoordinate(origin):SetEndCoordinate(origin:Translate(4000,heading or 0))
  a:SetGridOptions({Width=4000,Margin=1000,Spacing=1000,CrossSpacing=crossSpacing or 1000,Diagonals=diagonals})
  a:CreateGrid():SetGridNeighboursOnly()
  return a
end

test("common grid mode uses six hex neighbours and retains the hex alias", function()
  local a=hexgrid():SetGridNeighboursOnly()
  equal(a:GetNodeNeighbourCount(nodeAtIndex(a,2,0)),6)
  a:SetGridNeighboursOnly(false) equal(a:GetNodeNeighbourCount(nodeAtIndex(a,2,0)),a.Nnodes-1)
  a:SetGridNeighboursOnly() equal(a:GetNodeNeighbourCount(nodeAtIndex(a,2,0)),6)
  local b=ASTAR:New()
  equal(b:SetGridNeighboursOnly(false),b)
  equal(pcall(function() b:SetGridNeighboursOnly() end),false)
  equal(pcall(function() a:SetGridNeighboursOnly(1) end),false)
  equal(pcall(function() a:SetGridOptions({Diagonals=1}) end),false)
  equal(a.GridNeighboursOnly,true)
end)

test("rectangular local indices give four or eight neighbours across rotations and unequal spacings", function()
  for _,heading in ipairs({0,37,90,205}) do
    for _,diagonals in ipairs({false,true}) do
      local a=localRect(diagonals,heading,500)
      local middle=nodeAtIndex(a,5,4)
      equal(a:GetNodeNeighbourCount(middle),diagonals and 8 or 4)
      equal(a:GetNodeNeighbourCount(nodeAtIndex(a,1,1)),diagonals and 3 or 2)
      local links=a.gridLinks
      for id,neighbors in pairs(links) do
        local n=a.nodes[id]
        for other in pairs(neighbors) do
          local m=a.nodes[other]
          local di,dj=math.abs(n.i-m.i),math.abs(n.j-m.j)
          assert(di<=1 and dj<=1 and di+dj>0)
          if not diagonals then equal(di+dj,1) end
          near(n.vector:GetDistance(m.vector,true),math.sqrt((di*500)^2+(dj*1000)^2))
          assert(links[other][id])
        end
      end
    end
  end
end)

test("diagonal configuration changes path geometry and invalidates candidate components", function()
  local a=ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(4000))
  a:SetGridOptions({Width=2000,Margin=0,Spacing=1000}):CreateGrid():SetGridNeighboursOnly()
  a:SetStartCoordinate(coord(0,-1000)):SetEndCoordinate(coord(4000,1000))
  local path=a:GetPath() equal(#path,5)
  local length=0
  for i=2,#path do length=length+path[i].vector:GetDistance(path[i-1].vector,true) end
  near(length,2000+2000*math.sqrt(2))
  local old=a.gridLinks local nodes=a.Nnodes
  local options=a:GetGridOptions() options.Diagonals=false a:SetGridOptions(options)
  equal(a.gridLinks,nil) equal(a.gridComponents,nil)
  path=a:GetPath() equal(#path,7) equal(a.Nnodes,nodes) assert(a.gridLinks~=old)
  a:SetGridNeighboursOnly(false) equal(#a:GetPath(),2)
  a:SetGridNeighboursOnly() equal(#a:GetPath(),7)
  local b=localRect() equal(b:GetGridOptions().Diagonals,true)
end)

test("diagonals cannot cut corners between missing surface cells", function()
  land.surfaceAt=function(c)
    return ((c.x==1000 and c.z==0) or (c.x==0 and c.z==1000)) and land.SurfaceType.LAND or land.SurfaceType.WATER
  end
  local a=ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(1000))
  a:SetGridOptions({Width=2000,Margin=0,Spacing=1000}):SetValidSurfaceTypes(land.SurfaceType.WATER):CreateGrid():SetGridNeighboursOnly()
  a:SetEndCoordinate(coord(1000,1000))
  a:SetValidNeighbourFunction(function() error("Precheck must precede expensive rules") end)
  local connected,reason=a:HasPotentialPath() equal(connected,false) equal(reason,"disconnected_grid")
  equal(a:GetPath(),nil) equal(a.nvalid,0)
end)

test("local rectangular attachments keep endpoints exact symmetric and bounded", function()
  for _,diagonals in ipairs({false,true}) do
    local a=localRect(diagonals,37,500)
    local start=a.startVector:GetCoordinate():Translate(123,37):Translate(75,127)
    local goal=a.endVector:GetCoordinate():Translate(234,37):Translate(100,127)
    a:SetStartCoordinate(start):SetEndCoordinate(goal)
    local path=a:GetPath() assert(path)
    near(path[1].vector:GetDistance(a.startVector,true),0)
    near(path[#path].vector:GetDistance(a.endVector,true),0)
    for _,node in ipairs({path[1],path[#path]}) do
      equal(node.i,nil)
      for id in pairs(a.gridLinks[node.id]) do
        local neighbor=a.nodes[id]
        assert(neighbor.rectGrid==a.rectGrid and a.gridLinks[id][node.id])
        local dx,dz=neighbor.vector.x-node.vector.x,neighbor.vector.z-node.vector.z
        local g=a.rectGrid
        local along,across=math.abs(dx*g.cos+dz*g.sin)/1000,math.abs(-dx*g.sin+dz*g.cos)/500
        assert(along<=1+1e-8 and across<=1+1e-8)
        if not diagonals then assert(along+across<=1+1e-8) end
      end
    end
    local countBefore=a.Nnodes assert(a:GetPath()) equal(a.Nnodes,countBefore)
    a:SetEndCoordinate(coord(900000,900000))
    local connected,reason=a:HasPotentialPath() equal(connected,false) equal(reason,"goal_unattached")
  end
end)

test("rectangular expansion rebuilds local topology and avoids all-pairs rule calls", function()
  for _,diagonals in ipairs({false,true}) do
    land.surfaceAt=function(c) return c.x==2000 and math.abs(c.z)<500 and land.SurfaceType.LAND or land.SurfaceType.WATER end
    local a=ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(4000))
    a:SetGridOptions({Width=0,Margin=0,Spacing=1000,Diagonals=diagonals}):SetValidSurfaceTypes(land.SurfaceType.WATER)
    a:CreateGrid():SetGridNeighboursOnly()
    local calls=0
    a:SetValidNeighbourFunction(function(n,m)
      calls=calls+1 assert(n.vector:GetDistance(m.vector,true)<=math.sqrt(2)*1000+1e-8)
      return true
    end)
    local path,report=a:GetPathWithExpansion()
    assert(path and #path>4) equal(report.StopReason,"path_found") equal(#report.Attempts,2)
    equal(report.Attempts[1].Failure,"disconnected_grid")
    assert(a.nvalid<=8*a.Nnodes and calls<=4*a.Nnodes)
    local original=nodeAtIndex(a,1,1) local old=a.gridLinks
    a:ExpandGrid(4000,2000)
    equal(a.gridLinks,nil) equal(nodeAtIndex(a,1,1),original)
    assert(a:GetPath()) assert(a.gridLinks~=old)
  end
end)

test("rectangular local mode preserves corridor checks and custom costs", function()
  local a=localRect(true)
  local calls=0
  land.isVisible=function(n,m)
    calls=calls+1 equal(n.y,1) equal(m.y,1)
    assert((n.x-m.x)^2+(n.z-m.z)^2<=2000000+1e-5)
    return true
  end
  a:SetValidNeighbourLoS(100)
  local path=a:GetPath() assert(path) assert(calls>0 and calls%3==0)
  a:SetCostFunction(function() return math.huge end) equal(a:GetPath(),nil)
  a:SetValidNeighbourFunction(function() return false end) equal(a:GetPath(),nil)
end)

test("local rectangular zone seed can expand from empty and preserves four neighbour mode", function()
  local a=ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(4000))
  a:SetGridOptions({Spacing=1000,Diagonals=false}):CreateGridFromZone(circleZone(500,500,10)):SetGridNeighboursOnly()
  equal(a.Nnodes,0)
  local path,report=a:GetPathWithExpansion() assert(path) equal(report.StopReason,"path_found")
  for i=2,#path do
    local n,m=path[i-1],path[i]
    if n.i and m.i then equal(math.abs(n.i-m.i)+math.abs(n.j-m.j),1) end
  end
end)

print(string.format("%d passed, %d failed", passed, failed))
if failed > 0 then os.exit(1) end
