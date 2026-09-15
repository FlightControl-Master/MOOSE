-- Standalone GRID and sharing regressions; run from the repository root:
-- lua tests/grid.lua
-- DCS terrain/road queries are stubs. No simulator or external modules are needed.
local source = "Moose Development/Moose/Core/Astar.lua"
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
land = {SurfaceType = {LAND = 1, WATER = 3}}

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

local passed,failed=0,0
local drawings,labels,removed={},{},{}
local function test(name,run)
  local ok,err=pcall(run)
  land.surfaceAt=nil scheduled={} timerNow=0
  drawings={} labels={} removed={}
  if ok then passed=passed+1 print("PASS "..name)
  else failed=failed+1 print("FAIL "..name..": "..tostring(err)) end
end
local function equal(a,b) assert(a==b,"expected "..tostring(b)..", got "..tostring(a)) end
local function near(a,b) assert(math.abs(a-b)<1e-8,"numeric mismatch") end
local function count(t) local n=0 for _ in pairs(t) do n=n+1 end return n end
local function coord(x,z,y) return COORDINATE:New(x,y or 0,z or 0) end
trigger.action.markupToAll=function(shape,side,id,...)
  local args={...} local n=select("#",...)
  drawings[id]={fill=args[n-3],outline=args[n-4],side=side,vertices=n-5}
end
trigger.action.removeMark=function(id) drawings[id]=nil labels[id]=nil removed[id]=true end
trigger.action.markToAll=function(id,text) labels[id]=text end
UTILS.DeepCopy=deepcopy
local function gridType(kind)
  return kind and kind:find("hexagonal",1,true) and GRID.Type.HEXAGON or GRID.Type.RECTANGLE
end
local function build(g,kind,zone)
  if kind and kind:find("zone",1,true) then return g:CreateFromZone(zone) end
  return g:CreateFromBounds(g.startVector,g.endVector)
end
local function grid(kind,options)
  local g=GRID:New("Test",gridType(kind)):SetBounds(coord(0),coord(4000))
  g:SetOptions(options or {Width=4000,Margin=1000,Spacing=1000})
  assert(build(g,kind))
  return g
end
local function search(g)
  return ASTAR:New():SetGrid(g):SetStartCoordinate(coord(0)):SetEndCoordinate(coord(4000))
end
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


test("standalone builders and overlays require no ASTAR or COORDINATE construction",function()
  local savedASTAR,savedNew=ASTAR,COORDINATE.New
  local ok,err=pcall(function()
    ASTAR=nil COORDINATE.New=function() error("Grid construction must use VECTOR") end
    for _,kind in ipairs({"rectangular","hexagonal"}) do
      local g=GRID:New("Test",gridType(kind)):SetBounds({x=0,y=0},{x=4000,y=0})
      g:SetOptions({Width=4000,Margin=1000,Spacing=1000})
      equal(build(g,kind),g) assert(g:GetCellCount()>0)
      local cells=g:GetCells() assert(#g:GetNeighbours(cells[1])>0)
      for _,cell in ipairs(cells) do equal(cell.valid,nil) equal(cell.cost,nil) equal(cell.cell,nil) end
      g:DrawGrid():MarkGrid() flushTimers()
      equal(count(drawings),g:GetCellCount()) equal(count(labels),g:GetCellCount())
      g:ExpandGrid(6000,2000):UpdateGridDrawing() flushTimers()
      equal(count(drawings),g:GetCellCount())
      g:UndrawGrid():UnmarkGrid() equal(count(drawings),0) equal(count(labels),0)
    end
  end)
  ASTAR=savedASTAR COORDINATE.New=savedNew assert(ok,err)
end)

test("constructor requires name and geometry and common builders retain the selected type",function()
  for _,run in ipairs({
    function() GRID:New() end,
    function() GRID:New("Only name") end,
    function() GRID:New(nil,GRID.Type.RECTANGLE) end,
    function() GRID:New(" ",GRID.Type.RECTANGLE) end,
    function() GRID:New(123,GRID.Type.RECTANGLE) end,
    function() GRID:New("Invalid","triangle") end
  }) do assert(not pcall(run)) end
  for _,kind in ipairs({GRID.Type.RECTANGLE,GRID.Type.HEXAGON}) do
    local g=GRID:New("Selected",kind):SetOptions({Width=0,Margin=0,Spacing=1000,MaxCells=1})
    equal(g:GetType(),kind) equal(g:GetName(),"Selected") equal(g.GridBuilt,nil)
    equal(g.CreateRectangle,nil) equal(g.CreateHexagon,nil)
    equal(g.CreateRectangleFromZone,nil) equal(g.CreateHexagonFromZone,nil)
    local built,reason=g:CreateFromBounds(coord(0),coord(4000))
    equal(built,nil) equal(reason,"cell_limit") equal(g:GetType(),kind)
    local options=g:GetOptions() options.MaxCells=10 g:SetOptions(options)
    equal(g:CreateFromBounds(coord(0),coord(4000)),g) equal(g:GetType(),kind)
    equal(g:GetCellCount(),5)
    assert(not pcall(function() g:CreateFromZone(circleZone(0,0,1000)) end))
    equal(g:GetType(),kind)
  end
  local hex=GRID:New("Hex",GRID.Type.HEXAGON)
  local version=hex:GetVersion()
  assert(not pcall(function() hex:SetOptions({CrossSpacing=500}) end))
  equal(hex:GetVersion(),version) equal(hex:GetOptions().CrossSpacing,nil)
end)

test("ASTAR hex convenience builder preserves configuration without changing the prior grid type",function()
  local a=ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(4000))
  local prior=a:GetGrid()
  a:SetGridOptions({Width=0,Margin=0,Spacing=1000,MaxCells=10,Expansion={MaxAttempts=2}})
  a:SetValidSurfaceTypes({land.SurfaceType.WATER})
  equal(a:CreateHexGrid(),a)
  local current=a:GetGrid()
  assert(current~=prior) equal(current:GetName(),prior:GetName())
  equal(current:GetType(),GRID.Type.HEXAGON) equal(prior:GetType(),GRID.Type.RECTANGLE)
  equal(prior.GridBuilt,nil) equal(current:GetOptions().Spacing,1000)
  equal(current:GetOptions().Expansion.MaxAttempts,2)
  equal(current.ValidSurfaceTypes[1],land.SurfaceType.WATER)
  equal(#a:GetPath(),5)
end)

test("options and bounds are copied and independent across grid instances",function()
  local first,last=coord(0),coord(4000)
  local options={Width=2000,Spacing=1000,Diagonals=false,Expansion={MaxAttempts=3}}
  local g=GRID:New("Own",GRID.Type.RECTANGLE):SetBounds(first,last):SetOptions(options)
  first.x=9000 last.x=10000 options.Expansion.MaxAttempts=99
  local copy=g:GetOptions() copy.Width=100000 copy.Expansion.MaxAttempts=88
  equal(g:GetName(),"Own") equal(g:GetType(),GRID.Type.RECTANGLE) equal(g:GetDimensions(),nil)
  equal(g:GetOptions().Width,2000) equal(g:GetOptions().Expansion.MaxAttempts,3)
  g:CreateFromBounds(g.startVector,g.endVector) equal(g.rectGrid.x,0) equal(g.rectGrid.distance,4000)
  equal(pcall(function() g:SetBounds(coord(0),coord(10)) end),false)
  equal(GRID:New("Test",GRID.Type.RECTANGLE):GetCellCount(),0)
end)

test("cell getters expose stable geometry with independent result containers",function()
  local g=grid("rectangular",{Width=2000,Margin=0,Spacing=1000})
  equal(g:GetType(),"rectangular") equal(g:GetCellCount(),15) equal(g:GetCandidateCount(),15)
  equal(g.CellCount,15) equal(g.nodes,nil) equal(g.Nnodes,nil) equal(g.GetNodeNeighbourCount,nil)
  local c=g:GetCellFromIndex(2,3)
  equal(g:GetCell(c.id),c) near(c.vector.x,2000) near(c.vector.z,0)
  local nearest,d=g:FindClosestCell(coord(2001,0)) equal(nearest,c) near(d,1)
  local result=g:GetCells() result[1]=nil equal(g:GetCellCount(),15)
  local neighbors=g:GetNeighbours(c) equal(#neighbors,8) neighbors[1]=nil equal(g:GetNeighbourCount(c),8)
  local coordinate=g:GetCellCoordinate(c) coordinate.x=10000 near(c.vector.x,2000)
  local dimensions=g:GetDimensions() dimensions.Width=0 equal(g:GetDimensions().Width,2000)
  equal(g:GetCellFromIndex(100,100),nil)
  equal(pcall(function() g:GetNeighbours(grid():GetCells()[1]) end),false)
end)

test("circle rectangle and concave polygon seeds work without search endpoints",function()
  local zones={circleZone(2000,0,2500),
    polygonZone(coord(0),0,{{-500,-1500},{4500,-1500},{4500,1500},{-500,1500}}),
    polygonZone(coord(0),27,{{-500,-1500},{4500,-1500},{4500,1500},{2500,1500},{2500,0},{-500,0}})}
  for _,kind in ipairs({"rectangular-zone","hexagonal-zone"}) do
    for _,zone in ipairs(zones) do
      local g=GRID:New("Test",gridType(kind)):SetOptions({Spacing=500,MaxCells=1000})
      local built,reason=build(g,kind,zone) assert(built,reason) assert(g:GetCellCount()>0)
      for _,cell in ipairs(g:GetCells()) do assert(zone:IsVec2InZone(cell.vector:GetVec2())) end
      local dims=g:GetDimensions() local n=g:GetCellCount() local version=g:GetVersion()
      equal(g:ExpandGrid(dims.Width+1000,dims.Margin+1000),g)
      assert(g:GetCellCount()>n and g:GetVersion()>version)
    end
  end
end)

test("budget rejection and invalid options do not add cells or query terrain",function()
  land.surfaceAt=function() error("Preflight must precede terrain") end
  for _,kind in ipairs({"rectangular","hexagonal","rectangular-zone","hexagonal-zone"}) do
    local g=GRID:New("Test",gridType(kind)):SetBounds(coord(0),coord(4000)):SetOptions({Spacing=1000,MaxCells=1})
    local version=g:GetVersion()
    local result,reason
    if kind:find("zone") then result,reason=build(g,kind,circleZone(0,0,3000))
    else result,reason=build(g,kind) version=version+1 end
    equal(result,nil) equal(reason,"cell_limit") equal(g:GetCellCount(),0) equal(g:GetVersion(),version)
    equal(g:GetType(),gridType(kind)) equal(g.GridBuilt,nil)
    equal(pcall(function() g:SetOptions({Spcing=1000}) end),false) equal(g:GetVersion(),version)
  end
end)

test("filtered empty grids still version their geometry and lock the surface filter",function()
  local g=GRID:New("Test",GRID.Type.RECTANGLE):SetBounds(coord(0),coord(4000)):SetValidSurfaceTypes({})
  g:SetOptions({Width=0,Margin=0,Spacing=1000})
  local version=g:GetVersion() g:CreateFromBounds(g.startVector,g.endVector)
  assert(g:GetVersion()>version) equal(g:GetCellCount(),0) equal(g:GetCandidateCount(),5)
  equal(g:GetType(),"rectangular") equal(pcall(function() g:SetValidSurfaceTypes(nil) end),false)
  local c,d=g:FindClosestCell(coord(0)) equal(c,nil) equal(d,math.huge)
end)

test("shared search caches and custom rules never leak into grid cells or other searches",function()
  for _,kind in ipairs({"rectangular","hexagonal"}) do
    local g=grid(kind)
    local a,b=search(g),search(g)
    a:SetValidNeighbourFunction(function() return true end)
    b:SetValidNeighbourFunction(function() return false end)
    assert(a:GetPath()) equal(b:GetPath(),nil) assert(a:GetPath())
    b:SetValidNeighbourFunction(nil):SetCostFunction(function() return math.huge end)
    equal(b:GetPath(),nil) assert(a:GetPath())
    local c=g:GetCells()[1] local an,bn=a._CellNodes[c.id],b._CellNodes[c.id]
    assert(an~=bn and an~=c and bn~=c and an.valid~=bn.valid and an.cost~=bn.cost)
    equal(an.cell,c) equal(bn.cell,c) equal(c.valid,nil) equal(c.cost,nil)
    equal(a:GetGrid(),g) equal(b:GetGrid(),g)
  end
end)

test("manual endpoints remain per search and cell import does not resample terrain",function()
  local g=grid("hexagonal") local original=g:GetCellCount()
  land.surfaceAt=function(c)
    assert(math.abs(c.x-123)<1e-8 or math.abs(c.x-4123)<1e-8,"Grid cell was resampled on import")
    return land.SurfaceType.WATER
  end
  local a,b=search(g),search(g)
  a:SetStartCoordinate(coord(123,50)):SetEndCoordinate(coord(4123,50))
  local path=a:GetPath() assert(path)
  equal(path[1].cell,nil) equal(path[#path].cell,nil)
  equal(g:GetCellCount(),original) equal(b.Nnodes,original) equal(a.Nnodes,original+2)
  assert(b:GetPath()) equal(b.Nnodes,original)
end)

test("external expansion synchronizes searches while retaining existing pair caches and IDs",function()
  local g=grid("rectangular",{Width=0,Margin=0,Spacing=1000})
  local a,b=search(g),search(g)
  local path=a:GetPath() assert(path)
  b:SetStartCoordinate(coord(123,0)) assert(b:GetPath())
  local oldNode=a.nodes[path[1].id] local oldCache=oldNode.valid
  local oldB=b.startNode local version=g:GetVersion()
  g:ExpandGrid(2000,1000)
  assert(g:GetVersion()>version)
  assert(a:GetPath()) assert(b:GetPath())
  equal(a.Nnodes,g:GetCellCount()) equal(b.Nnodes,g:GetCellCount()+1)
  equal(a.nodes[oldNode.id],oldNode) equal(oldNode.valid,oldCache)
  equal(b.nodes[oldB.id],oldB) equal(b.startNode,oldB)
  for _,cell in ipairs(g:GetCells()) do equal(a._CellNodes[cell.id].cell,cell) equal(b._CellNodes[cell.id].cell,cell) end
end)

test("shared topology updates invalidate components in every attached search",function()
  local g=grid("rectangular",{Width=2000,Margin=0,Spacing=1000})
  local a,b=search(g),search(g)
  for _,x in ipairs({a,b}) do x:SetStartCoordinate(coord(0,-1000)):SetEndCoordinate(coord(4000,1000)) end
  equal(#a:GetPath(),5) equal(#b:GetPath(),5)
  local oldA,oldB=a.gridLinks,b.gridLinks local version=g:GetVersion()
  local options=g:GetOptions() options.Diagonals=false g:SetOptions(options)
  assert(g:GetVersion()>version)
  equal(#a:GetPath(),7) equal(#b:GetPath(),7) assert(a.gridLinks~=oldA and b.gridLinks~=oldB)
  equal(g:GetNeighbourCount(g:GetCellFromIndex(2,3)),4)
  local limits=a:GetGridOptions() limits.MaxCells=1 a:SetGridOptions(limits)
  local path,report=b:GetPathWithExpansion() equal(path,nil) equal(report.StopReason,"cell_limit")
end)

test("search adjacency translates cell IDs after expansion without sharing mutable links",function()
  for _,kind in ipairs({"rectangular","hexagonal"}) do
    for _,diagonals in ipairs({false,true}) do
      local g=grid(kind,{Width=2000,Margin=1000,Spacing=1000,Diagonals=diagonals})
      local a,b=search(g),search(g)
      a:SetStartCoordinate(coord(123,50)):SetEndCoordinate(coord(4123,50))
      assert(a:GetPath()) assert(b:GetPath())
      local originalCount=g:GetCellCount()
      assert(g:ExpandGrid(4000,2000))
      assert(a:GetPath()) assert(b:GetPath())
      local differentIDs=false
      for _,cell in ipairs(g:GetCells()) do
        local an,bn=a._CellNodes[cell.id],b._CellNodes[cell.id]
        if cell.id>originalCount and an.id~=bn.id then differentIDs=true end
        assert(a.gridLinks[an.id]~=b.gridLinks[bn.id] and a.gridLinks[an.id]~=g.gridLinks[cell.id])
        local expected={}
        local neighbors=g:GetNeighbours(cell)
        for i,neighbor in ipairs(neighbors) do
          if i>1 then assert(neighbors[i-1].id<neighbor.id) end
          expected[neighbor.id]=true
          assert(a.gridLinks[an.id][a._CellNodes[neighbor.id].id])
          assert(b.gridLinks[bn.id][b._CellNodes[neighbor.id].id])
        end
        for id in pairs(a.gridLinks[an.id]) do
          local neighbor=a.nodes[id]
          if neighbor.cell then assert(expected[neighbor.cell.id]) end
        end
        equal(count(b.gridLinks[bn.id]),#neighbors)
        neighbors[1]=nil
        equal(g:GetNeighbourCount(cell),count(expected))
      end
      assert(differentIDs,"Manual endpoints must shift imported node IDs after expansion")
      local cell=g:GetCells()[1]
      local an,bn=a._CellNodes[cell.id],b._CellNodes[cell.id]
      local neighbor=g:GetNeighbours(cell)[1]
      assert(neighbor)
      a.gridLinks[an.id][a._CellNodes[neighbor.id].id]=nil
      assert(g.gridLinks[cell.id][neighbor.id])
      assert(b.gridLinks[bn.id][b._CellNodes[neighbor.id].id])
    end
  end
end)

test("automatic expansion on one shared search becomes available to another",function()
  land.surfaceAt=function(c) return c.x==2000 and math.abs(c.z)<500 and land.SurfaceType.LAND or land.SurfaceType.WATER end
  for _,kind in ipairs({"rectangular","hexagonal"}) do
    local g=GRID:New("Test",gridType(kind)):SetBounds(coord(0),coord(4000)):SetValidSurfaceTypes(land.SurfaceType.WATER)
    g:SetOptions({Width=0,Margin=0,Spacing=1000}) assert(build(g,kind))
    local a,b=search(g),search(g)
    equal(a:HasPotentialPath(),false) equal(b:HasPotentialPath(),false)
    local path,report=a:GetPathWithExpansion() assert(path and #report.Attempts>1)
    equal(g:GetDimensions().Width,report.Width)
    assert(b:GetPath()) equal(a.Nnodes,b.Nnodes)
  end
end)

test("grid and search overlays own independent polygons and accept shared path cells",function()
  local g=grid("rectangular",{Width=2000,Margin=0,Spacing=1000})
  local a,b=search(g),search(g) local path=a:GetPath()
  g:DrawGridWithPath(path) a:DrawGridWithPath(path) b:DrawGrid() flushTimers()
  equal(count(drawings),3*g:GetCellCount())
  equal(g.LastGridDrawResult.CellsQueued,g:GetCellCount())
  equal(g.LastGridDrawResult.CellsDrawn,g:GetCellCount()) equal(g.LastGridDrawResult.NodesDrawn,nil)
  equal(count(g.GridDrawCellIDs),g:GetCellCount())
  equal(a.LastGridDrawResult.NodesDrawn,g:GetCellCount()) equal(a.LastGridDrawResult.CellsDrawn,nil)
  local green=0 for _,d in pairs(drawings) do if d.fill[2]==1 and d.fill[1]==0 then green=green+1 end end
  equal(green,2*#path)
  a:UndrawGrid() equal(count(drawings),2*g:GetCellCount())
  g:UndrawGrid() equal(count(drawings),g:GetCellCount())
  b:UndrawGrid() equal(count(drawings),0)
  local foreign=search(grid("rectangular")):GetPath()
  equal(pcall(function() g:DrawGridWithPath(foreign) end),false)
end)

test("shared drawing snapshots stay fixed and pending jobs cancel independently",function()
  local g=grid("rectangular") local a=search(g)
  g:DrawGridWithPath(a:GetPath(),{BatchSize=1}) a:DrawGrid(nil,nil,nil,nil,nil,nil,nil,{BatchSize=1})
  local original=g:GetCellCount() local job=g.GridDrawJob
  g:ExpandGrid(6000,2000)
  a:UndrawGrid() flushTimers()
  equal(job.result.Status,"complete") equal(count(drawings),original)
  g:UpdateGridDrawing() flushTimers() equal(count(drawings),original)
  g:DrawGrid() flushTimers() equal(count(drawings),g:GetCellCount())
  g:UndrawGrid() equal(count(drawings),0)
end)

test("standalone markers count geometric neighbours and validate checked counts before replacement",function()
  local g=grid("rectangular",{Width=2000,Margin=0,Spacing=1000})
  g:MarkGrid() flushTimers() equal(count(labels),g:GetCellCount())
  equal(g.LastGridMarkResult.CellsQueued,g:GetCellCount()) equal(g.LastGridMarkResult.CellsMarked,g:GetCellCount())
  equal(g.LastGridMarkResult.NodesMarked,nil)
  for _,text in pairs(labels) do assert(text:match("^Cell %d+")) end
  local sawEight=false for _,text in pairs(labels) do if text:find("Candidates: 8",1,true) then sawEight=true end end
  assert(sawEight)
  equal(pcall(function() g:MarkGrid({CheckNeighbours=true}) end),false) equal(count(labels),g:GetCellCount())
  local a=search(g):SetValidNeighbourFunction(function() return false end)
  a:MarkGrid({CheckNeighbours=true}) flushTimers() equal(count(labels),2*g:GetCellCount())
  equal(a.LastGridMarkResult.NodesMarked,a.Nnodes) equal(a.LastGridMarkResult.CellsMarked,nil)
  for _,id in ipairs(a.GridMarkIDs) do assert(labels[id]:match("^Node %d+")) end
  g:UnmarkGrid() equal(count(labels),a.Nnodes) a:UnmarkGrid() equal(count(labels),0)
end)

test("ASTAR convenience methods keep manual nodes separate from the owned grid",function()
  local a=ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(4000))
  local manual=a:AddNodeFromCoordinate(coord(9000))
  a:SetGridOptions({Width=2000,Margin=0,Spacing=1000}):CreateGrid()
  equal(a:GetGrid():GetCellCount(),15) equal(a.Nnodes,16) equal(a.nodes[manual.id],manual)
  a:ExpandGrid(4000,1000) equal(a.Nnodes,a:GetGrid():GetCellCount()+1)
  equal(pcall(function() a:SetGrid(grid()) end),false)
  equal(pcall(function() ASTAR:New():SetGrid(GRID:New("Test",GRID.Type.RECTANGLE)) end),false)
end)

test("building through GetGrid synchronizes searches before grid assertions",function()
  local a=ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(4000))
  local hex=GRID:New("Hex",GRID.Type.HEXAGON):SetOptions({Width=0,Margin=0,Spacing=1000})
  hex:CreateFromBounds(coord(0),coord(4000)) a:SetGrid(hex)
  a:SetGridNeighboursOnly() assert(a:GetPathWithExpansion())
  local b=ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(4000))
  b:GetGrid():SetOptions({Width=0,Margin=0,Spacing=1000}):CreateFromBounds(coord(0),coord(4000))
  assert(b:GetPathWithExpansion())
end)

test("grid-owned path snapshots accept exact endpoints without inventing cells",function()
  local g=grid("hexagonal")
  local a=search(g):SetStartCoordinate(coord(123,50)):SetEndCoordinate(coord(4123,50))
  local path=a:GetPath() assert(path)
  equal(path[1].cell,nil) equal(path[#path].cell,nil)
  equal(g:DrawGridWithPath(path),g) flushTimers()
  equal(count(drawings),g:GetCellCount())
  local expected={} for _,node in ipairs(path) do if node.cell then expected[node.cell.id]=true end end
  local green=0 for _,d in pairs(drawings) do if d.fill[2]==1 and d.fill[1]==0 then green=green+1 end end
  equal(green,count(expected))
  local foreign=search(grid("hexagonal")):SetStartCoordinate(coord(123,50)):GetPath()
  equal(pcall(function() g:DrawGridWithPath(foreign) end),false)
end)

test("cell and node ownership reject foreign objects without replacing existing state",function()
  local g,h=grid("rectangular"),grid("rectangular")
  local cell=g:GetCells()[1] local original=g:GetVersion()
  equal(pcall(function() g:_AddCell(h:GetCells()[1]) end),false)
  equal(g:GetVersion(),original) equal(g:GetCell(cell.id),cell)
  local replacement={} for k,v in pairs(cell) do replacement[k]=v end
  equal(pcall(function() g:_AddCell(replacement) end),false)
  equal(g:GetCells()[1],cell) equal(g:_AddCell(cell),g) equal(g:GetVersion(),original)
  local a,b=search(g),search(g)
  local own=a.nodes[1] local foreign=b.nodes[1]
  equal(pcall(function() a:AddNode(foreign) end),false)
  equal(pcall(function() a:GetNodeCoordinate(foreign) end),false)
  equal(a.nodes[1],own) equal(a.Nnodes,g:GetCellCount())
  assert(a:GetPath()) assert(b:GetPath())
end)

test("grid geometry has no search-rule dependency and maps different search node IDs",function()
  local g=grid("rectangular",{Width=2000,Margin=0,Spacing=1000})
  local a=ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(4000))
  a:GetNodeFromCoordinate(coord(9999)) -- Reserve an ID without adding a node.
  a:SetGrid(g)
  local midpoint=g:GetCellFromIndex(2,3)
  equal(g.GridNeighboursOnly,nil) equal(g._IsValidNeighbour,nil)
  equal(g:GetNeighbourCount(midpoint),8)
  local path=a:GetPath() assert(path)
  equal(a.nodes[1],nil)
  for _,node in ipairs(path) do assert(node.id~=node.cell.id) end
  a:SetValidNeighbourFunction(function() return false end)
  equal(a:GetPath(),nil) equal(g:GetNeighbourCount(midpoint),8)
end)

test("public expansion fits budget and rejection leaves geometry unchanged",function()
  local g=grid("hexagonal",{Width=0,Margin=0,Spacing=1000,MaxCells=17})
  local version=g:GetVersion()
  local expanded,reason=g:ExpandGrid(2000,1000)
  equal(expanded,nil) equal(reason,"cell_limit") equal(g:GetVersion(),version)
  local limited
  expanded,reason,limited=g:ExpandGrid(2000,1000,true)
  equal(expanded,g) equal(reason,nil) equal(limited,true)
  assert(g:GetCandidateCount()<=17 and g:GetCandidateCount()>5)
  local dimensions=g:GetDimensions()
  expanded,reason,limited=g:ExpandGrid(dimensions.Width,dimensions.Margin,true)
  equal(expanded,g) equal(limited,false)
end)

test("empty thin zone bounds and unrepresentable lattice indices terminate before sampling",function()
  land.surfaceAt=function() error("No surface queries expected") end
  local zone=polygonZone(coord(0),0,{{0.1,-1e9},{0.2,-1e9},{0.2,1e9},{0.1,1e9}})
  for _,kind in ipairs({"rectangular-zone","hexagonal-zone"}) do
    local g=GRID:New("Test",gridType(kind)):SetBounds(coord(0),coord(1)):SetOptions({Spacing=1,MaxCells=5})
    debug.sethook(function() error("Unbounded empty lattice scan") end,"",200000)
    local ok,built=pcall(function() return build(g,kind,zone) end)
    debug.sethook()
    assert(ok,built) equal(built,g) equal(g:GetCandidateCount(),0) equal(g:GetCellCount(),0)
    equal(#g:GetNearbyCells(coord(1e100,1e100)),0)
  end
  for _,kind in ipairs({"rectangular","hexagonal"}) do
    local g=GRID:New("Test",gridType(kind)):SetBounds(coord(0),coord(1)):SetOptions({Width=1000,Spacing=1e-309,MaxCells=5})
    local built,reason=build(g,kind)
    equal(built,nil) equal(reason,"cell_limit") equal(g:GetCellCount(),0)
  end
end)

test("finite bounds are validated atomically and zone convenience builders need no endpoints",function()
  local g=GRID:New("Test",GRID.Type.RECTANGLE):SetBounds(coord(0),coord(4000))
  local version=g:GetVersion()
  for _,bad in ipairs({math.huge,-math.huge,0/0}) do
    equal(pcall(function() g:SetBounds({x=bad,y=0,z=0},coord(1)) end),false)
    equal(g:GetVersion(),version) equal(g.startVector.x,0)
  end
  for _,kind in ipairs({"CreateGridFromZone","CreateHexGridFromZone"}) do
    local a=ASTAR:New():SetGridOptions({Spacing=1000})
    equal(a[kind](a,circleZone(2000,0,3000)),a)
    a:SetStartCoordinate(coord(0)):SetEndCoordinate(coord(4000)):SetGridNeighboursOnly()
    assert(a:GetPath())
  end
end)

test("invalid custom travel costs cannot corrupt a search",function()
  local a=search(grid("rectangular"))
  for _,value in ipairs({-1,0/0,"invalid"}) do
    a:SetCostFunction(function() return value end)
    local ok,err=pcall(function() return a:GetPath() end)
    equal(ok,false) assert(tostring(err):find("non-negative",1,true))
  end
  a:SetCostFunction(function() return math.huge end) equal(a:GetPath(),nil)
  a:SetCostFunction(function() return 0 end) assert(a:GetPath())
end)

test("convenience builders select local neighbours while explicit all-pairs mode stays available",function()
  for _,kind in ipairs({"CreateGrid","CreateHexGrid"}) do
    local a=ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(4000))
    a:SetGridOptions({Width=0,Margin=0,Spacing=1000}) a[kind](a)
    equal(a.GridNeighboursOnly,true) equal(#a:GetPath(),5)
    a:SetGridNeighboursOnly(false) equal(#a:GetPath(),2)
    local b=ASTAR:New():SetGridNeighboursOnly(false):SetStartCoordinate(coord(0)):SetEndCoordinate(coord(4000))
    b:SetGridOptions({Width=0,Margin=0,Spacing=1000}) b[kind](b)
    equal(b.GridNeighboursOnly,false) equal(#b:GetPath(),2)
  end
end)

test("position lookup round trips rotated anisotropic and hex cells",function()
  for _,kind in ipairs({"rectangular","hexagonal"}) do
    for _,heading in ipairs({0,37,90,217}) do
      local origin=coord(-2300,5700,900)
      local g=GRID:New("Test",gridType(kind)):SetBounds(origin,origin:Translate(4000,heading))
      g:SetOptions({Width=6000,Margin=2000,Spacing=1000,CrossSpacing=kind=="rectangular" and 750 or nil})
      assert(build(g,kind))
      for _,cell in ipairs(g:GetCells()) do
        local a,b=g:PositionToIndex(cell.vector)
        equal(a,cell.q or cell.i) equal(b,cell.r or cell.j)
        local center=g:IndexToPosition(a,b)
        near(center.x,cell.vector.x) near(center.z,cell.vector.z) equal(center.y,0)
        equal(g:GetCellAtPosition(center),cell)
        assert(not rawequal(center,cell.vector))
        center.y=1e6 equal(g:GetCellAtPosition(center),cell)
      end
      local outside=g:IndexToPosition(-30,-20)
      local a,b=g:PositionToIndex(outside)
      equal(a,-30) equal(b,-20) equal(g:GetCellAtPosition(outside),nil)
    end
  end
end)

test("containing cell lookup preserves filtered holes instead of snapping to accepted cells",function()
  for _,kind in ipairs({"rectangular","hexagonal"}) do
    land.surfaceAt=function(v) return math.abs(v.x)<1 and math.abs(v.z)<1 and 1 or 3 end
    local g=GRID:New("Test",gridType(kind)):SetBounds(coord(0),coord(4000)):SetValidSurfaceTypes(3)
    g:SetOptions({Width=4000,Margin=1000,Spacing=1000}) assert(build(g,kind))
    equal(g:GetCellAtPosition(coord(0)),nil)
    assert(g:FindClosestCell(coord(0)))
    equal(#g:GetRing(coord(0),0),0)
    equal(#g:GetCellsInRange(coord(0),0),0)
    land.surfaceAt=nil
  end
end)

test("hex cube rounding corrects slanted coordinates and deterministic edge ties",function()
  local g=grid("hexagonal")
  local a,b=g:PositionToIndex(coord(500,0)) equal(a,1) equal(b,0)
  a,b=g:PositionToIndex(coord(-500,0)) equal(a,0) equal(b,0)
  -- Fractional axial (.49,.49) must not round both axes independently to zero.
  local p=coord(735,math.sqrt(3)/2*490)
  a,b=g:PositionToIndex(p)
  assert((a==0 and b==1) or (a==1 and b==0))
  local best=math.huge
  for q=-2,2 do for r=-2,2 do best=math.min(best,g:IndexToPosition(q,r):GetDistance(p,true)) end end
  near(g:IndexToPosition(a,b):GetDistance(p,true),best)
  local rect=grid()
  local center=rect:IndexToPosition(2,3)
  center.x=center.x+500
  a,b=rect:PositionToIndex(center) equal(a,2) equal(b,4)
end)

test("rings and ranges use lattice metrics with bounded work and no mutation",function()
  for _,kind in ipairs({"rectangular","hexagonal"}) do
    for _,diagonal in ipairs({false,true}) do
      local g=grid(kind,{Width=12000,Margin=6000,Spacing=1000,Diagonals=diagonal})
      local center=g:GetCellAtPosition(coord(0))
      local options=g:GetOptions()
      local version,candidates,cells=g:GetVersion(),g:GetCandidateCount(),g:GetCellCount()
      local isHex=kind=="hexagonal"
      equal(#g:GetRing(center,0),1)
      equal(#g:GetRing(center,2),isHex and 12 or (diagonal and 16 or 8))
      equal(#g:GetCellsInRange(center,2),isHex and 19 or (diagonal and 25 or 13))
      local ring=g:GetRing(center,2)
      for i,c in ipairs(ring) do
        equal(g:GetGridDistance(center,c),2)
        equal(g:GetGridDistance(c,center),2)
        if i>1 then assert(ring[i-1].id<c.id) end
      end
      equal(#g:GetCellsInRange(center,1000000000),cells)
      equal(#g:GetRing(center,1000000000),0)
      equal(g:GetVersion(),version) equal(g:GetCandidateCount(),candidates) equal(g:GetCellCount(),cells)
      equal(g.gridLinks,nil)
      equal(g:GetOptions().Diagonals,options.Diagonals)
      ring[1]=nil equal(#g:GetRing(center,2),isHex and 12 or (diagonal and 16 or 8))
      if not isHex then
        local destination=g:IndexToPosition(center.i+2,center.j+2)
        equal(g:GetGridDistance(center,destination),diagonal and 2 or 4)
        options.Diagonals=not diagonal g:SetOptions(options)
        equal(g:GetGridDistance(center,destination),diagonal and 4 or 2)
      end
    end
  end
end)

test("line supercover includes rectangle corner contacts and follows open segment order",function()
  local g=grid(nil,{Width=10000,Margin=4000,Spacing=1000})
  local a,b=g:IndexToPosition(3,3),g:IndexToPosition(5,5)
  local line=g:GetLineCells(a,b)
  equal(#line,7) equal(line[1],g:GetCellFromIndex(3,3)) equal(line[#line],g:GetCellFromIndex(5,5))
  local seen={}
  for _,c in ipairs(line) do assert(not seen[c.id]) seen[c.id]=true end
  for _,pair in ipairs({{3,4},{4,3},{4,4},{4,5},{5,4}}) do assert(seen[g:GetCellFromIndex(pair[1],pair[2]).id]) end
  local reverse=g:GetLineCells(b,a)
  equal(#reverse,7) equal(reverse[1],line[#line])
  for _,c in ipairs(reverse) do assert(seen[c.id]) end
  equal(#g:GetLineCells(a,a),1)
  local edge=coord(a.x+500,a.z)
  equal(#g:GetLineCells(edge,edge),2)
  local corner=coord(a.x+500,a.z+500)
  equal(#g:GetLineCells(corner,corner),4)
  local horizontal=g:GetLineCells(g:IndexToPosition(3,2),g:IndexToPosition(3,5))
  equal(#horizontal,4)
  for i,c in ipairs(horizontal) do equal(c.i,3) equal(c.j,i+1) end
end)

test("hex and rotated rectangular line intersections match their cell geometry",function()
  for _,kind in ipairs({"rectangular","hexagonal"}) do
    local origin=coord(-4000,7000)
    local g=GRID:New("Test",gridType(kind)):SetBounds(origin,origin:Translate(4000,37))
    g:SetOptions({Width=8000,Margin=4000,Spacing=1000,CrossSpacing=kind=="rectangular" and 600 or nil})
    build(g,kind)
    local hex=kind=="hexagonal"
    local first=g:GetCellAtPosition(origin)
    local a,b=first.q or first.i,first.r or first.j
    local last=g:IndexToPosition(hex and a+3 or a,hex and b or b+3)
    local line=g:GetLineCells(first,last)
    equal(#line,4) equal(line[1],first)
    local adjacent=g:IndexToPosition(hex and a+1 or a,hex and b or b+1)
    local midpoint=coord((first.vector.x+adjacent.x)/2,(first.vector.z+adjacent.z)/2)
    equal(#g:GetLineCells(midpoint,midpoint),2)
    equal(#g:GetLineCells(g:IndexToPosition(-1000000,0),g:IndexToPosition(-999999,0)),0)
  end
end)

test("polygon boundaries close the last edge and deduplicate without filling",function()
  local g=grid(nil,{Width=12000,Margin=6000,Spacing=1000})
  local vertices={g:IndexToPosition(3,3),g:IndexToPosition(3,7),g:IndexToPosition(7,7),g:IndexToPosition(7,3)}
  local boundary=g:GetPolygonBoundaryCells(vertices)
  equal(#boundary,16)
  local seen={}
  for _,c in ipairs(boundary) do assert(not seen[c.id]) seen[c.id]=true end
  assert(seen[g:GetCellFromIndex(5,3).id]) equal(seen[g:GetCellFromIndex(5,5).id],nil)
  vertices[#vertices+1]=vertices[1]
  local closed=g:GetPolygonBoundaryCells(vertices)
  equal(#closed,#boundary) for i,c in ipairs(closed) do equal(c,boundary[i]) end
  equal(#g:GetPolygonBoundaryCells({vertices[1],vertices[1],vertices[1]}),1)
end)

test("hex vertex contacts, clipped lines and filtered gaps remain geometric",function()
  local g=GRID:New("Test",GRID.Type.HEXAGON):SetBounds(coord(0),coord(4000)):SetValidSurfaceTypes(3)
  g:SetOptions({Width=6000,Margin=2000,Spacing=1000})
  land.surfaceAt=function(v) return math.abs(v.x-1000)<1 and math.abs(v.z)<1 and 1 or 3 end
  g:CreateFromBounds(g.startVector,g.endVector)
  equal(g:GetCellFromIndex(1,0),nil)
  local version=g:GetVersion()
  local line=g:GetLineCells(coord(0),coord(3000))
  equal(#line,3) equal(line[1].q,0) equal(line[2].q,2) equal(line[3].q,3)
  equal(g:GetGridDistance(line[1],line[2]),2)
  equal(#g:GetRing(coord(0),1),5)
  local clipped=g:GetLineCells(coord(-1e9),coord(1e9))
  local expected=0 for _,c in ipairs(g:GetCells()) do if c.r==0 then expected=expected+1 end end
  equal(#clipped,expected)
  local vertex=coord(-500,1000/(2*math.sqrt(3)))
  equal(#g:GetLineCells(vertex,vertex),3)
  local vertices={g:IndexToPosition(0,0),g:IndexToPosition(3,0),g:IndexToPosition(0,3)}
  local boundary=g:GetPolygonBoundaryCells(vertices)
  local union={}
  for i=1,3 do for _,c in ipairs(g:GetLineCells(vertices[i],vertices[i%3+1])) do union[c.id]=true end end
  equal(#boundary,count(union)) for _,c in ipairs(boundary) do assert(union[c.id]) end
  equal(g:GetVersion(),version) equal(g.gridLinks,nil)
end)

test("query validation rejects foreign cells and malformed input while empty grids stay queryable",function()
  local g=grid()
  local foreign=grid():GetCells()[1]
  for _,run in ipairs({
    function() g:PositionToIndex(foreign) end,
    function() g:GetGridDistance(foreign,coord(0)) end,
    function() g:GetRing(coord(0),-1) end,
    function() g:GetCellsInRange(coord(0),0.5) end,
    function() g:GetRing(coord(0),math.huge) end,
    function() g:IndexToPosition(0.5,1) end,
    function() g:PositionToIndex(coord(math.huge)) end,
    function() g:PositionToIndex(coord(1e100)) end,
    function() g:GetPolygonBoundaryCells({coord(0),coord(1)}) end,
    function() GRID:New("Test",GRID.Type.HEXAGON):PositionToIndex(coord(0)) end
  }) do assert(not pcall(run)) end
  local empty=GRID:New("Test",GRID.Type.HEXAGON):SetBounds(coord(0),coord(4000)):SetValidSurfaceTypes({})
  empty:CreateFromBounds(empty.startVector,empty.endVector)
  land.getSurfaceType=function() error("Geometry queries must not sample terrain") end
  local ok,err=pcall(function()
    equal(empty:GetCellAtPosition(coord(0)),nil)
    equal(#empty:GetRing(coord(0),1),0) equal(#empty:GetCellsInRange(coord(0),100),0)
    equal(#empty:GetLineCells(coord(0),coord(4000)),0)
    equal(#empty:GetPolygonBoundaryCells({coord(0),coord(4000),coord(0,4000)}),0)
    local a,b=empty:PositionToIndex(coord(0)) equal(a,0) equal(b,0)
    equal(empty:GetGridDistance(coord(0),empty:IndexToPosition(2,-1)),2)
  end)
  land.getSurfaceType=function(v) return (land.surfaceAt and land.surfaceAt({x=v.x,y=0,z=v.y})) or land.SurfaceType.WATER end
  assert(ok,err)
end)

test("resolution presets select center spacing rather than a target cell count",function()
  for _,kind in ipairs({GRID.Type.RECTANGLE,GRID.Type.HEXAGON}) do
    local previous=0
    for _,case in ipairs({{GRID.Resolution.COARSE,400},{GRID.Resolution.NORMAL,200},{GRID.Resolution.FINE,100}}) do
      local g=GRID:New("Resolution",kind):SetOptions({Width=4000,Margin=1000})
      g:SetResolution(case[1])
      local pending=g:GetResolutionInfo()
      equal(pending.Status,"pending") equal(pending.Spacing,nil) equal(pending.MaxCells,5000)
      equal(g:GetOptions().Spacing,nil)
      equal(g:CreateFromBounds(coord(0),coord(6000)),g)
      local info=g:GetResolutionInfo()
      equal(info.Mode,"automatic") equal(info.Resolution,case[1]) equal(info.Spacing,case[2])
      equal(info.ReferenceLength,4000) equal(info.Intervals,4000/case[2]) equal(info.Status,"built")
      equal(info.MaxCells,5000) equal(info.CandidateCount,g:GetCandidateCount())
      equal(info.CrossSpacing,kind==GRID.Type.RECTANGLE and case[2] or nil)
      equal(g:GetDimensions().Spacing,case[2]) assert(g:GetCandidateCount()>previous)
      previous=g:GetCandidateCount()
      info.Spacing=1 equal(g:GetResolutionInfo().Spacing,case[2])
    end
    local narrow=GRID:New("Long",kind):SetOptions({Width=1000,Margin=0,MaxCells=20000,Resolution=GRID.Resolution.NORMAL})
    narrow:CreateFromBounds(coord(0),coord(20000))
    equal(narrow:GetResolutionInfo().Spacing,50)
    assert(narrow:GetCandidateCount()>5000)
  end
end)

test("automatic corridor spacing includes margins and is independent of world heading",function()
  for _,kind in ipairs({GRID.Type.RECTANGLE,GRID.Type.HEXAGON}) do
    for _,heading in ipairs({0,37,90,219}) do
      local origin=coord(15000,-7000,2000)
      local g=GRID:New("Rotated",kind):SetOptions({Width=8000,Margin=1000,Resolution=GRID.Resolution.NORMAL})
      g:CreateFromBounds(origin,origin:Translate(2000,heading))
      near(g:GetResolutionInfo().ReferenceLength,4000)
      near(g:GetDimensions().Spacing,200)
      equal(g:GetOptions().Width,8000) equal(g:GetOptions().Margin,1000)
    end
  end
end)

test("zone resolution uses the projected box extent and ignores corridor dimensions",function()
  local zones={circleZone(0,0,2000),
    polygonZone(coord(0),0,{{-2000,-1000},{2000,-1000},{2000,1000},{-2000,1000}}),
    polygonZone(coord(0),0,{{-2000,-1000},{2000,-1000},{2000,1000},{0,1000},{0,0},{-2000,0}})}
  for _,kind in ipairs({GRID.Type.RECTANGLE,GRID.Type.HEXAGON}) do
    for i,zone in ipairs(zones) do
      local g=GRID:New("Zone",kind):SetOptions({Width=1,Margin=99999,Resolution=GRID.Resolution.NORMAL})
      -- Move the frame far from the zone: distance to origin is not part of the reference extent.
      g:SetBounds(coord(100000,0),coord(104000,0))
      equal(g:CreateFromZone(zone),g)
      equal(g:GetResolutionInfo().ReferenceLength,i==1 and 4000 or 2000)
      equal(g:GetDimensions().Spacing,i==1 and 200 or 100)
      for _,cell in ipairs(g:GetCells()) do assert(zone:IsVec2InZone(cell.vector:GetVec2())) end
    end
    local g=GRID:New("Rotated box",kind):SetResolution(GRID.Resolution.NORMAL)
    g:SetBounds(coord(0),coord(4000,4000))
    g:CreateFromZone(zones[2])
    near(g:GetResolutionInfo().ReferenceLength,6000/math.sqrt(2))
    near(g:GetDimensions().Spacing,300/math.sqrt(2))
  end
end)

test("resolution never raises a cell limit or coarsens spacing after budget rejection",function()
  for _,kind in ipairs({GRID.Type.RECTANGLE,GRID.Type.HEXAGON}) do
    for _,zoneMode in ipairs({false,true}) do
      local g=GRID:New("Budget",kind):SetOptions({Width=4000,Margin=0,MaxCells=100,Resolution=GRID.Resolution.FINE})
      g:SetValidSurfaceTypes({})
      land.surfaceAt=function() error("Resolution preflight must not sample terrain") end
      local built,reason
      if zoneMode then built,reason=g:CreateFromZone(circleZone(0,0,2000))
      else built,reason=g:CreateFromBounds(coord(0),coord(4000)) end
      equal(built,nil) equal(reason,"cell_limit") equal(g.GridBuilt,nil) equal(g:GetCellCount(),0)
      local info=g:GetResolutionInfo()
      equal(info.Status,"cell_limit") equal(info.Spacing,100) equal(info.MaxCells,100) equal(info.CandidateCount,nil)
      land.surfaceAt=nil
      local options=g:GetOptions() options.MaxCells=5000 g:SetOptions(options)
      if zoneMode then built=g:CreateFromZone(circleZone(0,0,2000)) else built=g:CreateFromBounds(coord(0),coord(4000)) end
      equal(built,g) equal(g:GetDimensions().Spacing,100) equal(g:GetCellCount(),0)
      assert(g:GetCandidateCount()>100) equal(g:GetOptions().MaxCells,5000)
    end
  end
end)

test("expansion and option round trips preserve calculated spacing and existing cell identities",function()
  for _,kind in ipairs({GRID.Type.RECTANGLE,GRID.Type.HEXAGON}) do
    local g=GRID:New("Expand",kind):SetOptions({Width=4000,Margin=0,Resolution=GRID.Resolution.NORMAL})
    g:CreateFromBounds(coord(0),coord(4000))
    local prior=g:GetCells() local countBefore=g:GetCandidateCount()
    local options=g:GetOptions() options.MaxCells=10000 options.Diagonals=false g:SetOptions(options)
    equal(g:ExpandGrid(8000,2000),g)
    equal(g:GetResolutionInfo().Spacing,200) equal(g:GetResolutionInfo().ReferenceLength,4000)
    equal(g:GetResolutionInfo().CandidateCount,g:GetCandidateCount()) assert(g:GetCandidateCount()>countBefore)
    for _,cell in ipairs(prior) do equal(g:GetCell(cell.id),cell) equal(g:GetCellAtPosition(cell.vector),cell) end
    local version=g:GetVersion()
    assert(not pcall(function() g:SetResolution(GRID.Resolution.FINE) end))
    assert(not pcall(function() g:SetResolution(nil) end))
    local manual=g:GetOptions() manual.Resolution=nil manual.Spacing=200
    assert(not pcall(function() g:SetOptions(manual) end))
    equal(g:GetVersion(),version) equal(g:GetResolutionInfo().Spacing,200)
    local built,reason=g:ExpandGrid(100000,100000)
    equal(built,nil) assert(reason=="cell_limit" or reason=="size_limit")
    equal(g:GetResolutionInfo().Spacing,200)
  end
end)

test("resolution mode selection validates conflicts atomically and preserves unrelated configuration",function()
  local g=GRID:New("Modes",GRID.Type.RECTANGLE):SetOptions({Width=8000,Spacing=500,CrossSpacing=250,MaxCells=1234,Expansion={MaxAttempts=2}})
  equal(g:SetResolution(GRID.Resolution.NORMAL),g)
  local options=g:GetOptions()
  equal(options.Width,8000) equal(options.MaxCells,1234) equal(options.Expansion.MaxAttempts,2)
  equal(options.Spacing,nil) equal(options.CrossSpacing,nil)
  local version=g:GetVersion()
  for _,run in ipairs({
    function() g:SetResolution("invalid") end,
    function() g:SetResolution(20) end,
    function() g:SetOptions({Resolution=GRID.Resolution.NORMAL,Spacing=2000}) end,
    function() g:SetOptions({Resolution=GRID.Resolution.NORMAL,CrossSpacing=2000}) end
  }) do assert(not pcall(run)) equal(g:GetVersion(),version) end
  g:SetResolution(nil) equal(g:GetOptions().Spacing,2000) equal(g:GetResolutionInfo().Mode,"manual")
  g:SetOptions({Width=0,Margin=0,Spacing=300,CrossSpacing=150})
  equal(g:GetResolutionInfo().Spacing,300) equal(g:GetResolutionInfo().CrossSpacing,150)
  g:CreateFromBounds(coord(0),coord(900)) equal(g:GetDimensions().Spacing,300)
  version=g:GetVersion()
  assert(not pcall(function() g:SetResolution(GRID.Resolution.NORMAL) end)) equal(g:GetVersion(),version)
end)

test("automatic resolution handles line extents and rejects points or underflow without sampling",function()
  for _,kind in ipairs({GRID.Type.RECTANGLE,GRID.Type.HEXAGON}) do
    local g=GRID:New("Line",kind):SetOptions({Width=0,Margin=0,Resolution=GRID.Resolution.NORMAL})
    equal(g:CreateFromBounds(coord(0),coord(4000)),g)
    equal(g:GetCellCount(),21) equal(g:GetDimensions().Spacing,200)
    local cross=GRID:New("Cross line",kind):SetOptions({Width=4000,Margin=0,Resolution=GRID.Resolution.NORMAL})
    equal(cross:CreateFromBounds(coord(0),coord(0)),cross) equal(cross:GetDimensions().Spacing,200)
    local point=GRID:New("Point",kind):SetOptions({Width=0,Margin=0,Resolution=GRID.Resolution.NORMAL})
    land.surfaceAt=function() error("Invalid resolution must not sample terrain") end
    local ok,err=pcall(function() point:CreateFromBounds(coord(0),coord(0)) end)
    equal(ok,false) assert(tostring(err):find("non%-zero extent")) equal(point.GridBuilt,nil)
    local tiny=GRID:New("Tiny",kind):SetOptions({Width=1e-323,Margin=1,Resolution=GRID.Resolution.FINE})
    ok,err=pcall(function() tiny:CreateFromBounds(coord(0),coord(1)) end)
    equal(ok,false) assert(tostring(err):find("numeric range")) equal(tiny.GridBuilt,nil)
    land.surfaceAt=nil
    point:SetOptions({Width=0,Margin=0,Spacing=500})
    equal(point:CreateFromBounds(coord(0),coord(0)),point) equal(point:GetCellCount(),1)
  end
end)

test("ASTAR convenience builders and shared grids use automatic spacing without losing its mode",function()
  for _,kind in ipairs({"CreateGrid","CreateHexGrid","CreateGridFromZone","CreateHexGridFromZone"}) do
    local a=ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(4000))
    a:SetGridOptions({Width=4000,Margin=0,MaxCells=10000})
    a:GetGrid():SetResolution(GRID.Resolution.NORMAL)
    a:SetValidSurfaceTypes(land.SurfaceType.WATER)
    local zone=polygonZone(coord(0),0,{{0,-2000},{4000,-2000},{4000,2000},{0,2000}})
    if kind:find("Zone") then equal(a[kind](a,zone),a) else equal(a[kind](a),a) end
    local g=a:GetGrid()
    equal(g:GetResolutionInfo().Spacing,200) equal(a:GetGridOptions().Resolution,GRID.Resolution.NORMAL)
    local path=a:GetPathWithExpansion() assert(path and #path>1)
    local other=search(g) assert(other:GetPath())
    a:ExpandGrid(8000,2000)
    assert(other:GetPath()) equal(g:GetDimensions().Spacing,200)
  end
end)

test("all corridor presets use per-end margins and total length before width",function()
  for _,kind in ipairs({GRID.Type.RECTANGLE,GRID.Type.HEXAGON}) do
    for _,w in ipairs({{GRID.Width.NARROW,0.25},{GRID.Width.NORMAL,0.5},{GRID.Width.WIDE,1}}) do
      for _,m in ipairs({{GRID.Margin.SMALL,0.1},{GRID.Margin.NORMAL,0.25},{GRID.Margin.LARGE,0.5}}) do
        local g=GRID:New("Presets",kind):SetOptions({Spacing=2000,MaxCells=10000})
        equal(g:SetCorridor(w[1],m[1]),g)
        equal(g:GetDimensions(),nil) equal(g:GetOptions().Width,w[1]) equal(g:GetOptions().Margin,m[1])
        equal(g:CreateFromBounds(coord(0),coord(40000)),g)
        local dims=g:GetDimensions()
        near(dims.Margin,40000*m[2]) near(dims.Width,(40000+2*dims.Margin)*w[2])
        equal(dims.Spacing,2000) equal(g:GetOptions().MaxCells,10000)
        equal(g:GetOptions().Width,w[1]) equal(g:GetOptions().Margin,m[1])
      end
    end
  end
end)

test("corridor orientation follows endpoints while resolution follows the computed width",function()
  for _,kind in ipairs({GRID.Type.RECTANGLE,GRID.Type.HEXAGON}) do
    for _,heading in ipairs({0,37,90,217}) do
      local start=coord(17000,-8000,2000)
      local goal=start:Translate(40000,heading) goal.y=9000
      local g=GRID:New("Oriented",kind):SetCorridor(GRID.Width.NORMAL,GRID.Margin.NORMAL)
      g:SetResolution(GRID.Resolution.NORMAL)
      equal(g:CreateFromBounds(start,goal),g)
      local dims=g:GetDimensions()
      near(dims.Width,30000) near(dims.Margin,10000) near(dims.Spacing,1500)
      near(g:GetResolutionInfo().ReferenceLength,30000)
      local geometry=g.hexGrid or g.rectGrid
      near(geometry.x,start.x) near(geometry.z,start.z)
      near(geometry.cos,math.cos(math.rad(heading))) near(geometry.sin,math.sin(math.rad(heading)))
      local x,z=g:_GridPosition(geometry,40000,0)
      near(x,goal.x) near(z,goal.z)
    end
  end
end)

test("corridor setter preserves other settings and supports independent meter overrides",function()
  local g=GRID:New("Settings",GRID.Type.RECTANGLE)
  g:SetOptions({Spacing=1000,CrossSpacing=500,MaxCells=10000,Diagonals=false,Expansion={MaxAttempts=2}})
  g:SetCorridor(GRID.Width.NARROW,10000)
  local options=g:GetOptions()
  equal(options.Spacing,1000) equal(options.CrossSpacing,500) equal(options.MaxCells,10000)
  equal(options.Diagonals,false) equal(options.Expansion.MaxAttempts,2)
  local version=g:GetVersion()
  for _,run in ipairs({
    function() g:SetCorridor(nil,GRID.Margin.NORMAL) end,
    function() g:SetCorridor(GRID.Width.NORMAL,nil) end,
    function() g:SetCorridor("invalid",GRID.Margin.NORMAL) end,
    function() g:SetCorridor(GRID.Margin.SMALL,GRID.Margin.NORMAL) end,
    function() g:SetCorridor(GRID.Width.NORMAL,GRID.Width.WIDE) end,
    function() g:SetOptions({Width=-1}) end,
    function() g:SetOptions({Margin=math.huge}) end,
    function() g:SetOptions({Width={}}) end
  }) do assert(not pcall(run)) equal(g:GetVersion(),version) end
  equal(g:CreateFromBounds(coord(0),coord(40000)),g)
  equal(g:GetDimensions().Width,15000) equal(g:GetDimensions().Margin,10000)
  local mixed=GRID:New("Mixed",GRID.Type.HEXAGON):SetOptions({Width=12000,Margin=GRID.Margin.LARGE})
  mixed:CreateFromBounds(coord(0),coord(40000))
  equal(mixed:GetDimensions().Width,12000) equal(mixed:GetDimensions().Margin,20000)
  local manual=GRID:New("Manual",GRID.Type.RECTANGLE):SetCorridor(4000,1000)
  manual:CreateFromBounds(coord(0),coord(4000))
  equal(manual:GetDimensions().Width,4000) equal(manual:GetDimensions().Margin,1000)
end)

test("relative corridor rejection does not resize to budget and retries use the new endpoints",function()
  for _,kind in ipairs({GRID.Type.RECTANGLE,GRID.Type.HEXAGON}) do
    local g=GRID:New("Retry",kind):SetOptions({MaxCells=1,Resolution=GRID.Resolution.NORMAL})
    g:SetCorridor(GRID.Width.NORMAL,GRID.Margin.NORMAL)
    land.surfaceAt=function() error("Preflight must precede sampling") end
    local built,reason=g:CreateFromBounds(coord(0),coord(40000))
    equal(built,nil) equal(reason,"cell_limit") equal(g:GetResolutionInfo().Spacing,1500)
    built,reason=g:CreateFromBounds(coord(0),coord(80000))
    equal(built,nil) equal(reason,"cell_limit") equal(g:GetResolutionInfo().Spacing,3000)
    equal(g:GetCellCount(),0) equal(g.GridBuilt,nil) equal(g:GetOptions().MaxCells,1)
    land.surfaceAt=nil
    local options=g:GetOptions() options.MaxCells=5000 g:SetOptions(options)
    equal(g:CreateFromBounds(coord(0),coord(80000)),g)
    equal(g:GetDimensions().Width,60000) equal(g:GetDimensions().Margin,20000)
    equal(g:GetDimensions().Spacing,3000)
  end
end)

test("zone builds ignore corridor presets including coincident optional frame endpoints",function()
  local zones={circleZone(0,0,2000),
    polygonZone(coord(0),0,{{-2000,-1000},{2000,-1000},{2000,1000},{0,1000},{0,0},{-2000,0}})}
  for _,kind in ipairs({GRID.Type.RECTANGLE,GRID.Type.HEXAGON}) do
    for _,zone in ipairs(zones) do
      local relative=GRID:New("Relative zone",kind):SetCorridor(GRID.Width.WIDE,GRID.Margin.LARGE)
      relative:SetResolution(GRID.Resolution.NORMAL):SetBounds(coord(0),coord(0))
      local manual=GRID:New("Manual zone",kind):SetOptions({Width=1,Margin=1,Resolution=GRID.Resolution.NORMAL})
      manual:SetBounds(coord(0),coord(0))
      equal(relative:CreateFromZone(zone),relative) equal(manual:CreateFromZone(zone),manual)
      local a,b=relative:GetDimensions(),manual:GetDimensions()
      equal(a.Width,b.Width) equal(a.Margin,b.Margin) equal(a.Spacing,b.Spacing)
      equal(relative:GetCandidateCount(),manual:GetCandidateCount()) equal(relative:GetCellCount(),manual:GetCellCount())
      local otherCells=manual:GetCells()
      for i,cell in ipairs(relative:GetCells()) do
        local other=otherCells[i]
        near(cell.vector.x,other.vector.x) near(cell.vector.z,other.vector.z)
      end
    end
  end
end)

test("expansion keeps preset configuration but grows numeric geometry without recomputing proportions",function()
  for _,kind in ipairs({GRID.Type.RECTANGLE,GRID.Type.HEXAGON}) do
    local g=GRID:New("Expand presets",kind):SetCorridor(GRID.Width.NORMAL,GRID.Margin.NORMAL)
    g:SetResolution(GRID.Resolution.NORMAL):CreateFromBounds(coord(0),coord(40000))
    local cells=g:GetCells()
    local options=g:GetOptions() options.MaxCells=10000 g:SetOptions(options)
    equal(g:ExpandGrid(45000,15000),g)
    equal(g:GetDimensions().Width,45000) equal(g:GetDimensions().Margin,15000) equal(g:GetDimensions().Spacing,1500)
    equal(g:GetOptions().Width,GRID.Width.NORMAL) equal(g:GetOptions().Margin,GRID.Margin.NORMAL)
    local version=g:GetVersion()
    assert(not pcall(function() g:SetCorridor(GRID.Width.WIDE,GRID.Margin.NORMAL) end))
    assert(not pcall(function() g:SetCorridor(45000,15000) end))
    equal(g:GetVersion(),version)
    for _,cell in ipairs(cells) do equal(g:GetCell(cell.id),cell) end
  end
end)

test("coincident endpoints and overflowing relative dimensions fail before sampling",function()
  for _,kind in ipairs({GRID.Type.RECTANGLE,GRID.Type.HEXAGON}) do
    for _,settings in ipairs({{GRID.Width.NORMAL,GRID.Margin.NORMAL},{1000,GRID.Margin.NORMAL},{GRID.Width.NORMAL,1000}}) do
      local g=GRID:New("Coincident",kind):SetCorridor(settings[1],settings[2])
      land.surfaceAt=function() error("Invalid corridor must not sample terrain") end
      local ok,err=pcall(function() g:CreateFromBounds(coord(0),coord(0)) end)
      equal(ok,false) assert(tostring(err):find("distinct endpoints")) equal(g.GridBuilt,nil) equal(g:GetCellCount(),0)
      land.surfaceAt=nil
      g:SetCorridor(0,0)
      equal(g:CreateFromBounds(coord(0),coord(0)),g) equal(g:GetCellCount(),1)
    end
    local huge=GRID:New("Overflow",kind):SetCorridor(GRID.Width.WIDE,1e308)
    local ok,err=pcall(function() huge:CreateFromBounds(coord(0),coord(1)) end)
    equal(ok,false) assert(tostring(err):find("finite")) equal(huge.GridBuilt,nil)
  end
end)

test("ASTAR preserves relative dimensions without adding implicit expansion limits",function()
  for _,kind in ipairs({"CreateGrid","CreateHexGrid"}) do
    local a=ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(400000))
    a:GetGrid():SetCorridor(GRID.Width.NORMAL,GRID.Margin.NORMAL):SetResolution(GRID.Resolution.COARSE)
    a:SetValidSurfaceTypes(land.SurfaceType.WATER)
    equal(a[kind](a),a)
    local g=a:GetGrid()
    equal(g:GetDimensions().Width,300000) equal(g:GetDimensions().Margin,100000) equal(g:GetDimensions().Spacing,30000)
    equal(a:GetGridOptions().Width,GRID.Width.NORMAL) equal(a:GetGridOptions().Margin,GRID.Margin.NORMAL)
    equal(a:GetGridOptions().Expansion.MaxWidth,nil) equal(a:GetGridOptions().Expansion.MaxMargin,nil)
    local path,report=a:GetPathWithExpansion()
    assert(path and #path>1) equal(report.Width,300000) equal(report.Margin,100000)
    equal(report.MaxWidth,nil) equal(report.MaxMargin,nil)
    local explicit=ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(40000))
    explicit:SetGridOptions({Width=GRID.Width.NORMAL,Margin=GRID.Margin.NORMAL,Resolution=GRID.Resolution.NORMAL,
      Expansion={MaxWidth=35000,MaxMargin=12000}})
    equal(explicit[kind](explicit),explicit)
    equal(explicit:GetGridOptions().Expansion.MaxWidth,35000) equal(explicit:GetGridOptions().Expansion.MaxMargin,12000)
    local expanded,reason=explicit:ExpandGrid(40000,15000)
    equal(expanded,nil) equal(reason,"size_limit")
  end
end)

test("omitted dimension caps stay nil and allow manual expansion past the former defaults",function()
  for _,kind in ipairs({GRID.Type.RECTANGLE,GRID.Type.HEXAGON}) do
    local g=GRID:New("Uncapped",kind):SetOptions({Width=100000,Margin=50000,Spacing=50000,MaxCells=500})
    equal(g:GetOptions().Expansion.MaxWidth,nil) equal(g:GetOptions().Expansion.MaxMargin,nil)
    g:CreateFromBounds(coord(0),coord(100000))
    local options=g:GetOptions() g:SetOptions(options)
    equal(g:ExpandGrid(500000,250000),g)
    equal(g:GetDimensions().Width,500000) equal(g:GetDimensions().Margin,250000)
    equal(g:GetOptions().Expansion.MaxWidth,nil) equal(g:GetOptions().Expansion.MaxMargin,nil)
    options=g:GetOptions() options.MaxCells=g:GetCandidateCount() g:SetOptions(options)
    local built,reason=g:ExpandGrid(1000000,500000)
    equal(built,nil) equal(reason,"cell_limit")
  end
end)

test("individual dimension caps constrain only their own axis and can be removed",function()
  for _,kind in ipairs({GRID.Type.RECTANGLE,GRID.Type.HEXAGON}) do
    for _,axis in ipairs({"MaxWidth","MaxMargin"}) do
      local g=GRID:New("One cap",kind):SetOptions({Width=100000,Margin=50000,Spacing=50000,
        Expansion={[axis]=axis=="MaxWidth" and 100000 or 50000}})
      g:CreateFromBounds(coord(0),coord(100000))
      local width=axis=="MaxWidth" and 100000 or 500000
      local margin=axis=="MaxMargin" and 50000 or 250000
      equal(g:ExpandGrid(width,margin),g)
      local built,reason=g:ExpandGrid(width+50000,margin+50000)
      equal(built,nil) equal(reason,"size_limit")
      local options=g:GetOptions() options.Expansion[axis]=nil g:SetOptions(options)
      equal(g:GetOptions().Expansion.MaxWidth,nil) equal(g:GetOptions().Expansion.MaxMargin,nil)
      equal(g:ExpandGrid(width+50000,margin+50000),g)
    end
  end
end)

test("expanding searches without spatial caps stop on attempts or cells rather than old dimensions",function()
  for _,builder in ipairs({"CreateGrid","CreateHexGrid"}) do
    local a=ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(100000))
    a:SetGridOptions({Width=100000,Margin=50000,Spacing=50000,MaxCells=500,Expansion={MaxAttempts=4}})
    a[builder](a) a:SetValidNeighbourFunction(function() return false end)
    local path,report=a:GetPathWithExpansion()
    equal(path,nil) equal(report.StopReason,"attempt_limit") equal(#report.Attempts,4)
    assert(report.Width>200000 and report.Margin>100000)
    equal(report.MaxWidth,nil) equal(report.MaxMargin,nil)
    local options=a:GetGridOptions() options.MaxCells=a:GetGrid():GetCandidateCount() a:SetGridOptions(options)
    path,report=a:GetPathWithExpansion()
    equal(path,nil) equal(report.StopReason,"cell_limit")
    for _,axis in ipairs({"MaxWidth","MaxMargin"}) do
      local b=ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(100000))
      b:SetGridOptions({Width=100000,Margin=50000,Spacing=50000,MaxCells=500,
        Expansion={MaxAttempts=4,[axis]=axis=="MaxWidth" and 100000 or 50000}})
      b[builder](b) b:SetValidNeighbourFunction(function() return false end)
      path,report=b:GetPathWithExpansion()
      equal(path,nil) equal(report.StopReason,"attempt_limit")
      if axis=="MaxWidth" then
        equal(report.Width,100000) assert(report.Margin>100000) equal(report.MaxMargin,nil)
      else
        equal(report.Margin,50000) assert(report.Width>200000) equal(report.MaxWidth,nil)
      end
    end
  end
end)

test("uncapped numerical growth overflow ends cleanly without mutating the grid",function()
  for _,builder in ipairs({"CreateGrid","CreateHexGrid"}) do
    local a=ASTAR:New():SetStartCoordinate(coord(0)):SetEndCoordinate(coord(4000))
    a:SetGridOptions({Width=4000,Margin=1000,Spacing=1000,Expansion={GrowthFactor=1e308}})
    a[builder](a) a:SetValidNeighbourFunction(function() return false end)
    local version=a:GetGrid():GetVersion()
    local path,report=a:GetPathWithExpansion()
    equal(path,nil) equal(report.StopReason,"size_limit") equal(#report.Attempts,1)
    equal(a:GetGrid():GetVersion(),version) equal(report.MaxWidth,nil) equal(report.MaxMargin,nil)
  end
end)

print(string.format("%d passed, %d failed",passed,failed))
if failed>0 then os.exit(1) end
