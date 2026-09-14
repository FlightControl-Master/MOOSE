--- **Core** - A* Pathfinding.
--
-- **Main Features:**
--
--    * Find path from A to B.
--    * Pre-defined as well as custom valid neighbour functions.
--    * Pre-defined as well as custom cost functions.
--    * Rectangular or hexagonal grids, with optional local four/eight- or six-neighbour search.
--
-- ===
--
-- ### Author: **funkyfranky**
-- 
-- ===
-- @module Core.Astar
-- @image CORE_Astar.png


--- ASTAR class.
-- @type ASTAR
-- @field #string ClassName Name of the class.
-- @field #boolean Debug Enable the no-path search message to all players. Disabled by default.
-- @field #string lid Class id string for output to DCS log file.
-- @field #table nodes Table of nodes.
-- @field #number counter Node counter.
-- @field #number Nnodes Number of nodes.
-- @field #number nvalid Number of neighbour validity requests, including cache hits, accumulated across searches.
-- @field #number nvalidcache Number of neighbour validity cache hits.
-- @field #number ncost Number of travel cost requests, including cache hits, accumulated across searches.
-- @field #number ncostcache Number of travel cost cache hits.
-- @field #ASTAR.Node startNode Start node.
-- @field #ASTAR.Node endNode End node.
-- @field Core.Vector#VECTOR startVector Snapshot of the requested start position.
-- @field Core.Vector#VECTOR endVector Snapshot of the requested goal position.
-- @field #function ValidNeighbourFunc Symmetric function to check whether a connection between two nodes is valid.
-- @field #table ValidNeighbourArg Optional arguments passed to the valid neighbour function.
-- @field #function CostFunc Function to calculate the travel cost from one node to another.
-- @field #table CostArg Optional arguments passed to the cost function. 
-- @field #table ValidSurfaceTypes Surface filter used by the grid builder and automatically added endpoints; may also be a single numeric surface type.
-- @field #boolean GridNeighboursOnly Restrict candidates to direct grid edges and local endpoint attachments. Disabled by default.
-- @field #table hexGrid Hex geometry: origin x/z, heading cos/sin, spacing, rowSpacing, original distance, boxHY, spaceX, candidateCount and temporary initialSamples for zone seeds.
-- @field #table hexIndex Hex nodes indexed by axial q, then r.
-- @field #table rectIndex Rectangular nodes indexed by i, then j.
-- @field #table gridLinks Cached candidate adjacency, indexed by node id, then neighbour id. Does not cache rule results.
-- @field #table gridComponents Connected-component labels for grid candidates. Rebuilt when candidate adjacency changes.
-- @field #table GridDrawIDs F10 polygon ids owned by DrawGrid(), removed by UndrawGrid().
-- @field #table GridDrawOptions Last DrawGrid() style and batch settings, retained for incremental updates.
-- @field #table GridDrawNodeIDs Drawn polygon ids indexed by grid node id.
-- @field #table GridDrawJob Pending drawing queue, or nil once completed or cancelled.
-- @field #table LastGridDrawResult Last drawing job: Status, NodesQueued, NodesDrawn, Batches, CPUSeconds, MaxBatchCPUSeconds, ElapsedSimulationSeconds and optional Error.
-- @field #table LastSearchTiming Last search attempt: CPUSeconds, Failure and Nodes. CPUSeconds is nil when os.clock is unavailable.
-- @field #string LastPathFailure Reason the last search attempt failed; nil on success or when no attempt was made.
-- @field #table LastExpansionResult Attempt history and stop reason from GetPathWithExpansion().
-- @field #ASTAR.GridOptions GridOptions Saved configuration, set with SetGridOptions().
-- @field #boolean GridBuilt Whether an initial grid was successfully created, even if it contains no accepted nodes.
-- @field #number GridCandidateCount Initial or expanded candidate count before filtering.
-- @field #table GridMarkIDs Text-marker ids owned by MarkGrid().
-- @field #table GridMarkJob Pending text-marker job.
-- @field #table LastGridMarkResult Text-marker status, counts and timing.
-- @extends Core.Base#BASE

--- *When nothing goes right... Go left!*
--
-- ===
--
-- # Configure, Build, Search, Inspect
--
-- ASTAR finds paths through VECTOR-based nodes. It does not move units; convert selected path nodes with GetNodeCoordinate(node)
-- when another MOOSE API requires COORDINATE objects. All dimensions and distances below are in meters.
--
--     local astar = ASTAR:New()
--     astar:SetStartCoordinate(ZONE:FindByName("Astar Start"):GetCoordinate())
--     astar:SetEndCoordinate(ZONE:FindByName("Astar Goal"):GetCoordinate())
--     astar:SetValidSurfaceTypes({land.SurfaceType.WATER, land.SurfaceType.SHALLOW_WATER})
--     astar:SetGridOptions({
--       Width = 40000, Margin = 10000, Spacing = 2000, MaxNodes = 5000,
--       Expansion = {GrowthFactor = 1.5, MaxAttempts = 5, MaxWidth = 200000, MaxMargin = 100000}
--     })
--     local grid, reason = astar:CreateHexGrid()
--     if not grid then
--       env.info("ASTAR: initial grid rejected: " .. reason)
--       return
--     end
--     astar:SetGridNeighboursOnly(true)
--     astar:SetValidNeighbourLoS(500)
--     local path, report = astar:GetPathWithExpansion()
--     if path then
--       astar:DrawGridWithPath(path)
--       -- Optional text labels, separate from polygons:
--       -- astar:MarkGrid({ShowID=true, ShowGridIndex=true, ShowNeighbourCount=true})
--       -- navyGroup:AddWaypoint(astar:GetNodeCoordinate(path[1]), speed)
--     else
--       env.info("ASTAR: " .. report.StopReason)
--     end
--
-- # Grid Configuration
--
-- @{#ASTAR.SetValidSurfaceTypes} accepts a single DCS surface type or a list. Nil accepts all surfaces; an empty list accepts none.
-- @{#ASTAR.SetGridOptions} sets geometry, the shared candidate-cell budget and a nested Expansion table. Both setters copy their inputs.
-- SetGridOptions replaces the entire configuration. Omitted fields use defaults; an empty table or nil resets defaults.
-- @{#ASTAR.GetGridOptions} returns an independent configuration copy. Unknown keys and invalid values are rejected before changing settings.
--
-- * Width: total width across the start-to-goal axis; default 40000.
-- * Margin: extra distance before start and beyond goal, at each end; default 10000.
-- * Spacing: rectangular longitudinal spacing or distance between adjacent hex centers; default 2000.
-- * CrossSpacing: optional rectangular transverse spacing, defaulting to Spacing. Hex builders reject this setting.
-- * Diagonals: true by default. In local rectangular mode, true allows eight neighbours, false allows four. Ignored by hex grids.
-- * MaxNodes: positive integer budget shared by initial creation and later enlargement; default 5000. There is no unlimited default.
--
-- After a successful build the geometry and surface filter are locked, even if every cell was filtered out. Use a new ASTAR for another lattice.
-- Diagonals, limits and Expansion settings can still change: get the current options, edit the desired limits, then call SetGridOptions(options).
-- Lowering MaxNodes below the existing candidate count does not remove nodes; expanding search returns node_limit before searching.
--
-- @{#ASTAR.CreateGrid} and @{#ASTAR.CreateHexGrid} take no arguments. Configure first; passing old positional arguments is an error.
-- All builders return self on success or nil, "node_limit" when the initial budget is exceeded. Rejection occurs before terrain sampling.
-- A successful build allows no second Create call on the same object. Manual nodes may precede rectangular creation; hex creation requires no nodes.
--
-- # Geometry and Zones
--
-- Hex grids use axial q/r indices with the third cube coordinate equal to -q-r. Their origin and orientation follow the original start-to-goal line.
-- Neighbor centers are one Spacing apart; drawn hexagons have circumradius Spacing/sqrt(3). Rectangular cells use Spacing and CrossSpacing as side lengths.
-- Grid centers have altitude zero; the surface filter samples their 2D position. Cell outlines are visual aids, not traversability guarantees.
--
-- @{#ASTAR.CreateGridFromZone}(zone) and @{#ASTAR.CreateHexGridFromZone}(zone) use circular, rectangular or polygonal MOOSE zones.
-- The zone determines the initial area; configured Width and Margin are not used to crop it. Spacing and MaxNodes still apply.
-- Center membership is checked with zone:IsVec2InZone() before querying terrain. MaxNodes counts candidate centers in the projected bounding rectangle,
-- including centers rejected by either the zone or surface filter. This bounds preparation work, not only accepted nodes.
-- A zone constrains initial grid creation only. Exact endpoints and subsequent enlargement of either grid type may lie outside it.
-- For example, replace CreateHexGrid() above with astar:CreateHexGridFromZone(ZONE:FindByName("Search Area")).
--
-- # Nodes and Endpoints
--
-- SetStartCoordinate and SetEndCoordinate accept COORDINATE, VECTOR, Vec2 or Vec3; each setter stores an independent VECTOR snapshot.
-- Nodes contain id, vector, surfacetype and connection caches. Generated nodes also contain q/r or i/j indices. There is no node.coordinate field.
-- GetNodeFromCoordinate creates a node without adding it; AddNodeFromCoordinate creates and adds one. A supplied VECTOR is retained by reference;
-- other position types are copied. Do not mutate positions, indices or ids of added nodes: adjacency and costs are cached.
-- GetNodeCoordinate(node) creates a fresh COORDINATE with the node's exact altitude. It does not cache the result.
--
-- In unrestricted mode endpoints snap to the closest node within 1000 m; otherwise a surface-valid node is added at the requested position.
-- Local grid mode keeps non-coincident endpoint positions exact and attaches them to nearby grid centers; it never links manual nodes directly.
-- GetPath and GetPathWithExpansion accept ExcludeStartNode, ExcludeEndNode booleans. An empty table can be a successful path; nil means failure.
--
-- # Neighbours and Costs
--
-- SetGridNeighboursOnly(true) restricts regular nodes to indexed neighbors plus locally attached manual/endpoint nodes. Call it after building the grid.
-- Hex grids have six neighbors. Rectangles use four or eight according to Diagonals in SetGridOptions().
-- A diagonal requires both flanking cells to exist, preventing shortcuts between surface-filtered cells. The edge still undergoes the configured rule.
-- For example: astar:SetGridOptions({Spacing=2000, Diagonals=false}):CreateGrid():SetGridNeighboursOnly(true).
-- To change Diagonals later, edit the copy from GetGridOptions() and pass it to SetGridOptions(); the candidate graph is rebuilt on demand.
-- SetHexNeighboursOnly remains a compatibility alias for hex grids. In unrestricted mode every other node is a candidate, including on rectangular grids.
-- SetValidNeighbourDistance(maxDistance), SetValidNeighbourLoS(corridorWidth), SetValidNeighbourRoad(maxDistance), or
-- SetValidNeighbourFunction(function(nodeA,nodeB,...) ... end, ...) select the connection rule. Setting a rule replaces the previous rule.
-- Rules must be symmetric. Changing them clears validity caches. The LoS rule checks altitude 1 m above sea level, not the nodes' altitude;
-- its optional corridor tests the center line and two parallel offset lines. It is not a ship-depth or complete swept-area test.
--
-- Costs default to 2D distance. SetCostDist3D and SetCostRoad select alternatives. SetCostFunction accepts symmetric, non-negative costs;
-- math.huge makes a connection impassable. Custom and road costs use a zero heuristic; built-in 2D/3D distances use their matching heuristic.
-- Changing cost functions clears cost caches. Costs and rule results are retained between searches, so recreate/reconfigure if their external data changes.
-- GetNodeNeighbourCount(node) counts candidates; GetNodeNeighbourCount(node,true) evaluates the neighbour rule but does not check travel costs.
--
-- # Expansion and Limits
--
-- GetPath() searches the existing graph. GetPathWithExpansion() additionally enlarges a rectangular or hex-only grid and retries after failure.
-- Both are synchronous. HasPotentialPath() is an optional cheap candidate-connectivity precheck; true does not guarantee a valid route.
-- Expanding search performs that check internally; do not abort first just because the initial grid is disconnected.
--
-- Expansion.GrowthFactor defaults to 1.5; Expansion.MaxAttempts defaults to 5 and includes the initial attempt.
-- Expansion.MaxWidth defaults to max(current width,200000); Expansion.MaxMargin defaults to max(current margin,100000).
-- Explicit dimension caps must be at least the existing dimensions when searching. They and MaxNodes are independent: whichever prevents growth stops it.
-- Width grows by at least two transverse spacings (CrossSpacing for rectangles, Spacing for hex grids); margin grows by at least one Spacing.
-- Dimension caps apply to both increments. Zero initial dimensions can therefore grow.
-- If the requested step exceeds MaxNodes, the search finds a smaller step without terrain sampling, then uses remaining room on either axis.
-- The discrete lattice may leave some budget unused. No cell is sampled beyond MaxNodes. A fitted step consumes one normal search attempt.
-- Previously accepted and rejected cells are retained without resampling; the first real enlargement of a zone seed fills unsampled holes as well.
-- Manual ExpandGrid(width,margin) supports both geometries and uses the same budget and dimension caps, but rejects oversized requests instead of fitting them.
-- ExpandHexGrid(width,margin) remains available specifically for hex grids. Rectangular enlargement preserves original i/j indices, spacing and orientation.
-- Enable SetGridNeighboursOnly(true) for efficient rectangular searches; hex expanding searches require this local mode.
--
-- GetPathWithExpansion returns path, report and stores the report in LastExpansionResult:
-- * Attempts: ordered entries with Width, Margin, Nodes, Failure and CPUSeconds.
-- * StopReason: path_found, attempt_limit, size_limit, node_limit or missing_coordinates.
-- * Width, Margin, Nodes, CandidateNodes: final dimensions, accepted node count and budgeted candidate-cell count.
-- * MaxNodes, MaxWidth, MaxMargin: effective limits for this search.
-- * BudgetLimited: true if a smaller growth step was fitted to the cell budget.
-- * SearchCPUSeconds: total search and enlargement CPU time, if a CPU clock is available.
-- Manual nodes and exact endpoints do not consume MaxNodes, so accepted Nodes can exceed CandidateNodes.
-- LastPathFailure contains missing_coordinates, no_start_node, no_goal_node, start_unattached, goal_unattached, disconnected_grid or connections_blocked.
-- Intermediate failures are trace-logged; final failure is announced once. Debug=true additionally enables player failure messages.
--
-- # Visual Debug
--
-- Building, searching and expanding never draw or update an overlay automatically.
-- DrawGrid() draws cell outlines; UpdateGridDrawing() explicitly appends missing cells after enlargement.
-- DrawGridWithPath(path) creates a one-time snapshot with green path cells; later searches and updates do not change it.
-- Both polygon functions support timed batches and a CPU budget. One DCS call cannot be interrupted, so the budget is a soft limit.
-- UndrawGrid() cancels queued polygon work and removes only this object's polygons.
--
-- MarkGrid() creates separate text labels with ids, grid indices and candidate-neighbor counts. CheckNeighbours=true additionally evaluates valid connections.
-- Counts are evaluated when a batch runs. Keep the graph and rule unchanged while marking for a consistent snapshot.
-- Labels include manual endpoints, and use the same batching defaults as drawing: BatchSize=25, Interval=0.1, MaxBatchSeconds=0.005.
-- Without a CPU clock, both drawing and marking process one node per batch. LastGridDrawResult and LastGridMarkResult report progress and errors.
-- UnmarkGrid() cancels queued text work and removes text labels without touching polygons. A new MarkGrid() replaces previous labels.
--
-- @field #ASTAR
ASTAR = {
  ClassName      = "ASTAR",
  Debug          =   nil,
  lid            =   nil,
  nodes          =    {},
  counter        =     1,
  Nnodes         =     0,
  ncost          =     0,
  ncostcache     =     0,
  nvalid         =     0,
  nvalidcache    =     0,
}

--- Node data.
-- @type ASTAR.Node
-- @field #number id Node id.
-- @field Core.Vector#VECTOR vector Position of the node. Do not mutate after adding it to ASTAR.
-- @field #number surfacetype DCS surface type sampled at node creation.
-- @field #table valid Cached connection validity, indexed by the other node's id.
-- @field #table cost Cached travel cost, indexed by the other node's id.
-- @field #number q Axial column for a node created by CreateHexGrid(); nil for manual nodes.
-- @field #number r Axial row for a node created by CreateHexGrid(); the third cube coordinate is -q-r.
-- @field #number i Rectangular row index.
-- @field #number j Rectangular column index.
-- @field #table rectGrid Shared rectangular geometry for nodes created by CreateGrid() or CreateGridFromZone(), including drawing dimensions.

--- ASTAR infinity.
-- @field #number INF
ASTAR.INF=1/0

--- Grid geometry and resource limits. All fields are optional; distances are meters.
-- @type ASTAR.GridOptions
-- @field #number Width Total search width, default 40000. Ignored by zone builders.
-- @field #number Margin Margin before start and after goal, default 10000. Ignored by zone builders.
-- @field #number Spacing Center spacing, default 2000.
-- @field #number CrossSpacing Rectangular transverse spacing; omitted means Spacing. Rejected for hex grids.
-- @field #boolean Diagonals Allow diagonal neighbours in local rectangular mode, default true. Ignored by hex grids. Can change after creation.
-- @field #number MaxNodes Shared candidate-cell limit before filtering, default 5000. Excludes manual nodes and endpoints.
-- @field #ASTAR.ExpansionOptions Expansion Expansion configuration.

--- Grid search expansion settings.
-- @type ASTAR.ExpansionOptions
-- @field #number GrowthFactor Finite multiplier greater than 1, default 1.5.
-- @field #number MaxAttempts Positive integer search limit including the first attempt, default 5.
-- @field #number MaxWidth Maximum width, default max(current width,200000).
-- @field #number MaxMargin Maximum margin at each end, default max(current margin,100000).

--- Node text-marker configuration.
-- @type ASTAR.MarkGridOptions
-- @field #boolean ShowID Include node id, default true.
-- @field #boolean ShowGridIndex Include q/r or i/j, default true.
-- @field #boolean ShowNeighbourCount Include candidate-neighbor count, default true.
-- @field #boolean CheckNeighbours Also evaluate and display valid connections, default false.
-- @field #number Coalition -1 for all, 0 neutral, 1 red, 2 blue. Default -1.
-- @field #boolean ReadOnly Prevent manual removal, default true.
-- @field #number BatchSize Maximum nodes per batch, default 25.
-- @field #number Interval Simulation seconds between batches, default 0.1.
-- @field #number MaxBatchSeconds Soft CPU-time budget per batch, default 0.005.

--- ASTAR class version.
-- @field #string version
ASTAR.version="1.2.0"

-- Six axial offsets; adjacent centers are one spacing apart.
local hexDirections={{1,0}, {0,1}, {-1,1}, {-1,0}, {0,-1}, {1,-1}}

-- DCS may sanitize os. Do not substitute simulation time for sub-second CPU measurements.
local function startCPUClock()
  if os and type(os.clock)=="function" then return {read=os.clock, start=os.clock()} end
end

local function elapsedCPU(clock)
  if clock then return math.max(0, clock.read()-clock.start) end
end

local function cpuTimeText(seconds)
  return seconds and string.format("CPU time %.6f sec", seconds) or "CPU time unavailable"
end

-- Geometry helpers shared by grid creation, enlargement and drawing.
local function checkGridDimensions(width, margin)
  assert(type(width)=="number" and width>=0 and width<math.huge, "ASTAR: Width must be finite and non-negative")
  assert(type(margin)=="number" and margin>=0 and margin<math.huge, "ASTAR: Margin must be finite and non-negative")
end

-- Configuration is copied, including nested expansion settings; unknown keys catch misspellings.
local function copyGridOptions(options)
  if options==nil then return {} end
  assert(type(options)=="table", "ASTAR: grid options must be a table")
  local copy={}
  for key,value in pairs(options) do
    if key=="Expansion" then
      assert(type(value)=="table", "ASTAR: Expansion must be a table")
      copy.Expansion={}
      for name,setting in pairs(value) do
        if name=="GrowthFactor" then
          assert(type(setting)=="number" and setting>1 and setting<math.huge, "ASTAR: GrowthFactor must be finite and greater than one")
        elseif name=="MaxAttempts" then
          assert(type(setting)=="number" and setting>=1 and setting<math.huge and setting==math.floor(setting), "ASTAR: MaxAttempts must be a positive integer")
        elseif name=="MaxWidth" or name=="MaxMargin" then
          assert(type(setting)=="number" and setting>=0 and setting<math.huge, "ASTAR: "..name.." must be finite and non-negative")
        else error("ASTAR: unknown expansion option '"..tostring(name).."'") end
        copy.Expansion[name]=setting
      end
    elseif key=="Diagonals" then
      assert(type(value)=="boolean", "ASTAR: Diagonals must be a boolean")
      copy[key]=value
    elseif key=="Width" or key=="Margin" then
      assert(type(value)=="number" and value>=0 and value<math.huge, "ASTAR: "..key.." must be finite and non-negative")
      copy[key]=value
    elseif key=="Spacing" or key=="CrossSpacing" then
      assert(type(value)=="number" and value>0 and value<math.huge, "ASTAR: "..key.." must be finite and positive")
      copy[key]=value
    elseif key=="MaxNodes" then
      assert(type(value)=="number" and value>=1 and value<math.huge and value==math.floor(value), "ASTAR: MaxNodes must be a positive integer")
      copy[key]=value
    else error("ASTAR: unknown grid option '"..tostring(key).."'") end
  end
  return copy
end

local function gridOptions(options, grid)
  local saved=copyGridOptions(options)
  local expansion=saved.Expansion or {}
  local result={Width=saved.Width or 40000, Margin=saved.Margin or 10000,
    Spacing=saved.Spacing or 2000, CrossSpacing=saved.CrossSpacing, Diagonals=saved.Diagonals~=false, MaxNodes=saved.MaxNodes or 5000}
  result.Expansion={GrowthFactor=expansion.GrowthFactor or 1.5, MaxAttempts=expansion.MaxAttempts or 5,
    MaxWidth=expansion.MaxWidth or math.max(grid and grid.boxHY or result.Width,200000),
    MaxMargin=expansion.MaxMargin or math.max(grid and grid.spaceX or result.Margin,100000)}
  return result
end

local function gridPosition(grid, along, across, origin)
  origin=origin or grid
  return origin.x+along*grid.cos-across*grid.sin, origin.z+along*grid.sin+across*grid.cos
end

local function gridVector(grid, along, across, origin)
  local x,z=gridPosition(grid, along, across, origin)
  return VECTOR:New(x, 0, z)
end

local function hexRowBounds(grid, width)
  -- Include centers on a boundary despite floating-point rounding in axial coordinates.
  return math.ceil(-width/2/grid.rowSpacing-1e-9), math.floor(width/2/grid.rowSpacing+1e-9)
end

local function hexColumnBounds(grid, margin, r, area)
  local first=area and area.alongMin or -margin
  local last=area and area.alongMax or grid.distance+margin
  return math.ceil(first/grid.spacing-r/2-1e-9), math.floor(last/grid.spacing-r/2+1e-9)
end

-- Prepare each row once and count all centers, including surface-filtered cells, before mutating the grid.
local function hexBounds(grid, width, margin, limit, area)
  local rmin, rmax
  if area then
    rmin=math.ceil(area.acrossMin/grid.rowSpacing-1e-9)
    rmax=math.floor(area.acrossMax/grid.rowSpacing+1e-9)
  else rmin, rmax=hexRowBounds(grid, width) end
  local bounds={rmin=rmin, rmax=rmax, count=0}
  for r=rmin,rmax do
    local qmin, qmax=hexColumnBounds(grid, margin, r, area)
    -- Count as floating point to avoid integer overflow in Lua 5.4 before checking a small limit.
    bounds.count=bounds.count+math.max(0, qmax*1.0-qmin+1)
    if limit and bounds.count>limit then return nil end
    bounds[r]={qmin=qmin, qmax=qmax}
  end
  return bounds
end

-- Rectangular indices stay anchored to the initial lattice, including fractional initial margins.
local function rectBounds(grid, width, margin, limit, area)
  local acrossMin=area and area.acrossMin or -width/2
  local acrossMax=area and area.acrossMax or width/2
  local alongMin=area and area.alongMin or -margin
  local alongMax=area and area.alongMax or grid.distance+margin
  local bounds={
    imin=math.ceil((acrossMin-grid.acrossOffset)/grid.crossSpacing-1e-9),
    imax=math.floor((acrossMax-grid.acrossOffset)/grid.crossSpacing+1e-9),
    jmin=math.ceil((alongMin-grid.alongOffset)/grid.spacing-1e-9),
    jmax=math.floor((alongMax-grid.alongOffset)/grid.spacing+1e-9)}
  local nx=math.max(0,bounds.imax*1.0-bounds.imin+1)
  local nz=math.max(0,bounds.jmax*1.0-bounds.jmin+1)
  if limit and nz>0 and nx>limit/nz then return nil end
  bounds.count=nx*nz
  return bounds
end

local function expansionBounds(self, width, margin, limit)
  if self.hexGrid then return hexBounds(self.hexGrid,width,margin,limit) end
  return rectBounds(self.rectGrid,width,margin,limit)
end

-- Read MOOSE's polygon bounding box, or construct the missing radius-zone bounding box.
-- Zone membership itself is delegated to IsVec2InZone, including its boundary conventions.
local function zoneGridArea(self, zone)
  assert(self.startVector and self.endVector, "ASTAR: start and end coordinates are required for a zone grid")
  assert(type(zone)=="table" and type(zone.IsVec2InZone)=="function", "ASTAR: a MOOSE zone with IsVec2InZone is required")
  local box=type(zone.GetBoundingSquare)=="function" and zone:GetBoundingSquare() or nil
  if not box and type(zone.GetRadius)=="function" and type(zone.GetVec2)=="function" then
    local center, radius=zone:GetVec2(), zone:GetRadius()
    assert(type(center)=="table" and type(center.x)=="number" and type(center.y)=="number"
      and type(radius)=="number" and radius>=0 and radius<math.huge, "ASTAR: invalid radius zone geometry")
    box={x1=center.x-radius, y1=center.y-radius, x2=center.x+radius, y2=center.y+radius}
  end
  assert(type(box)=="table", "ASTAR: zone must provide polygon bounds or a center and radius")
  for _,key in ipairs({"x1","y1","x2","y2"}) do
    local value=box[key]
    assert(type(value)=="number" and value>-math.huge and value<math.huge, "ASTAR: invalid zone bounding box")
  end
  assert(box.x1<=box.x2 and box.y1<=box.y2, "ASTAR: invalid zone bounding box order")
  local distance=self.startVector:GetDistance(self.endVector, true)
  local angle=distance>0 and math.rad(self.startVector:GetHeadingTo(self.endVector)) or 0
  local grid={x=self.startVector.x, z=self.startVector.z, cos=math.cos(angle), sin=math.sin(angle), distance=distance}
  local area={alongMin=math.huge, alongMax=-math.huge, acrossMin=math.huge, acrossMax=-math.huge}
  for _,point in ipairs({{box.x1,box.y1},{box.x1,box.y2},{box.x2,box.y1},{box.x2,box.y2}}) do
    local dx,dz=point[1]-grid.x,point[2]-grid.z
    local along,across=dx*grid.cos+dz*grid.sin,-dx*grid.sin+dz*grid.cos
    area.alongMin=math.min(area.alongMin,along) area.alongMax=math.max(area.alongMax,along)
    area.acrossMin=math.min(area.acrossMin,across) area.acrossMax=math.max(area.acrossMax,across)
  end
  return grid,area
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Add more valid neighbour functions.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new ASTAR object with an empty node set, unrestricted neighbours, and 2D distance costs.
-- @param #ASTAR self
-- @return #ASTAR self
function ASTAR:New()

  -- Inherit from BASE.
  local self=BASE:Inherit(self, BASE:New()) --#ASTAR

  self.lid="ASTAR | "

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set the requested start coordinate. Does not create a node or rebuild the grid.
-- @param #ASTAR self
-- @param Core.Point#COORDINATE Coordinate Start position; also accepts VECTOR, DCS Vec2 or Vec3. Nil clears it.
-- @return #ASTAR self
function ASTAR:SetStartCoordinate(Coordinate)

  self.startVector=Coordinate and VECTOR:NewFromVec(Coordinate) or nil
  
  return self
end

--- Set the requested goal coordinate. Does not create a node or rebuild the grid.
-- @param #ASTAR self
-- @param Core.Point#COORDINATE Coordinate Goal position; also accepts VECTOR, DCS Vec2 or Vec3. Nil clears it.
-- @return #ASTAR self
function ASTAR:SetEndCoordinate(Coordinate)

  self.endVector=Coordinate and VECTOR:NewFromVec(Coordinate) or nil
  
  return self
end

--- Configure accepted DCS surface types before building a grid. Nil accepts all surfaces; an empty list accepts none.
-- Takes a single surface type or a list, copied on input. A successful grid build locks the filter, even if no nodes passed it.
-- @param #ASTAR self
-- @param #table SurfaceTypes (Optional) DCS surface types; also accepts a single number.
-- @return #ASTAR self
function ASTAR:SetValidSurfaceTypes(SurfaceTypes)
  assert(not self.GridBuilt, "ASTAR: surface types cannot change after grid creation; use a new ASTAR object")
  local function check(value)
    assert(type(value)=="number" and value>=1 and value<=5 and value==math.floor(value), "ASTAR: invalid DCS surface type")
  end
  local copy
  if type(SurfaceTypes)=="number" then check(SurfaceTypes) copy=SurfaceTypes
  elseif SurfaceTypes~=nil then
    assert(type(SurfaceTypes)=="table", "ASTAR: surface types must be a number or list")
    copy={}
    local count=0
    for key,value in pairs(SurfaceTypes) do
      assert(type(key)=="number" and key>=1 and key==math.floor(key), "ASTAR: surface types must be a sequential list")
      check(value) copy[key]=value count=count+1
    end
    for i=1,count do assert(copy[i]~=nil, "ASTAR: surface types must be a sequential list") end
  end
  self.ValidSurfaceTypes=copy
  return self
end

--- Configure grid geometry, the shared cell budget and optional expansion settings. Does not build or draw anything.
-- Replaces the complete configuration with a copy; omitted fields use defaults. Nil resets to defaults.
-- After grid creation Width, Margin, Spacing and CrossSpacing are locked; Diagonals and limits may still change.
-- Lowering MaxNodes below the existing grid size makes an expanding search return node_limit without searching.
-- @param #ASTAR self
-- @param #ASTAR.GridOptions Options (Optional) Grid settings, including the nested Expansion table.
-- @return #ASTAR self
function ASTAR:SetGridOptions(Options)
  local saved=copyGridOptions(Options)
  local proposed=gridOptions(saved,self.hexGrid or self.rectGrid)
  if self.GridBuilt then
    local current=self:GetGridOptions()
    for _,key in ipairs({"Width","Margin","Spacing","CrossSpacing"}) do
      assert(proposed[key]==current[key], "ASTAR: "..key.." cannot change after grid creation; use a new ASTAR object")
    end
    assert(not self.hexGrid or saved.CrossSpacing==nil, "ASTAR: CrossSpacing is only supported by rectangular grids")
  end
  if self.rectGrid and proposed.Diagonals~=self:GetGridOptions().Diagonals then
    self.gridLinks=nil self.gridComponents=nil
  end
  self.GridOptions=saved
  return self
end

--- Return an independent copy of effective grid settings, including expansion defaults.
-- CrossSpacing is nil unless explicitly configured; rectangular builders then use Spacing.
-- @param #ASTAR self
-- @return #ASTAR.GridOptions Configuration copy.
function ASTAR:GetGridOptions()
  return gridOptions(self.GridOptions,self.hexGrid or self.rectGrid)
end

--- Create a node from a coordinate without adding it to the search node set.
-- Stores a VECTOR and samples its current surface type. A supplied VECTOR is retained by reference;
-- other position types are copied into a new VECTOR. Do not mutate a retained VECTOR after adding the node.
-- @param #ASTAR self
-- @param Core.Point#COORDINATE Coordinate Node position; also accepts VECTOR, DCS Vec2 or Vec3.
-- @return #ASTAR.Node The node.
function ASTAR:GetNodeFromCoordinate(Coordinate)

  local node={} --#ASTAR.Node
  
  node.vector=VECTOR._IsVector(Coordinate) and Coordinate or VECTOR:NewFromVec(Coordinate)
  node.surfacetype=node.vector:GetSurfaceType()
  node.id=self.counter
  
  node.valid={}
  node.cost={}
  
  self.counter=self.counter+1
  
  return node
end


--- Create a COORDINATE from a node's VECTOR position.
-- Each call returns an independent object with the node's exact x, y and z values, including altitude.
-- The result is not cached. Changing it does not change the node or its search caches.
-- @param #ASTAR self
-- @param #ASTAR.Node Node The node to convert.
-- @return Core.Point#COORDINATE A new coordinate at the node position.
function ASTAR:GetNodeCoordinate(Node)
  return Node.vector:GetCoordinate()
end

--- Add a node created by this ASTAR instance to the search node set.
-- Does not apply the grid surface filter. Adding the same node again does not increase the node count.
-- Invalidates grid candidate adjacency. Do not modify node ids, grid indices or coordinates after adding a node.
-- @param #ASTAR self
-- @param #ASTAR.Node Node The node to be added.
-- @return #ASTAR self
function ASTAR:AddNode(Node)

  if self.hexGrid then
    -- Keep the spatial index and candidate graph in sync when nodes are added or replaced.
    if Node.q~=nil and Node.r~=nil then
      local column=self.hexIndex[Node.q]
      local existing=column and column[Node.r]
      assert(not existing or existing.id==Node.id, "ASTAR: hex cell already contains a node")
    end
    local previous=self.nodes[Node.id]
    if previous and previous.q~=nil and previous.r~=nil then
      self.hexIndex[previous.q][previous.r]=nil
    end
    if Node.q~=nil and Node.r~=nil then
      self.hexIndex[Node.q]=self.hexIndex[Node.q] or {}
      self.hexIndex[Node.q][Node.r]=Node
    end
  elseif self.rectGrid then
    local function indexed(node) return node and node.rectGrid==self.rectGrid and node.i~=nil and node.j~=nil end
    if indexed(Node) then
      local row=self.rectIndex[Node.i]
      local existing=row and row[Node.j]
      assert(not existing or existing.id==Node.id, "ASTAR: rectangular cell already contains a node")
    end
    local previous=self.nodes[Node.id]
    if indexed(previous) then self.rectIndex[previous.i][previous.j]=nil end
    if indexed(Node) then
      self.rectIndex[Node.i]=self.rectIndex[Node.i] or {}
      self.rectIndex[Node.i][Node.j]=Node
    end
  end
  self.gridLinks=nil self.gridComponents=nil

  if not self.nodes[Node.id] then
    self.Nnodes=self.Nnodes+1
  end
  self.nodes[Node.id]=Node
    
  return self
end

--- Add a node to the table of grid nodes specifying its coordinate.
-- Does not apply the grid surface filter. Returns the new node, not the ASTAR object.
-- @param #ASTAR self
-- @param Core.Point#COORDINATE Coordinate Node position; also accepts VECTOR, DCS Vec2 or Vec3.
-- @return #ASTAR.Node The node.
function ASTAR:AddNodeFromCoordinate(Coordinate)

  local node=self:GetNodeFromCoordinate(Coordinate)
  
  self:AddNode(node)
    
  return node
end

--- Check the surface type stored in a node against the allowed surface types.
-- @param #ASTAR self
-- @param #ASTAR.Node Node The node to check.
-- @param #table SurfaceTypes Allowed surface types, for example `{land.SurfaceType.WATER}`; a single numeric type is also accepted. Nil accepts all types.
-- @return #boolean If true, surface type of node is valid.
function ASTAR:CheckValidSurfaceType(Node, SurfaceTypes)

  if SurfaceTypes then
  
    if type(SurfaceTypes)~="table" then
      SurfaceTypes={SurfaceTypes}
    end
    
    for _,surface in pairs(SurfaceTypes) do
      if surface==Node.surfacetype then
        return true
      end
    end
  
    return false
    
  else
    return true
  end

end

--- Replace the neighbour rule and clear cached validity results on all existing nodes.
-- The function receives nodeA, nodeB, then the optional arguments. It must be symmetric because results are cached in both directions.
-- @param #ASTAR self
-- @param #function NeighbourFunction Function returning true for an allowed connection, false otherwise. Nil allows all pairs.
-- @param ... Additional callback arguments, if any.
-- @return #ASTAR self
function ASTAR:SetValidNeighbourFunction(NeighbourFunction, ...)

  self.ValidNeighbourFunc=NeighbourFunction
  
  self.ValidNeighbourArg={...}
  self.ValidNeighbourArg.n=select("#", ...)
  for _,node in pairs(self.nodes) do
    node.valid={}
  end
  
  return self
end


--- Limit candidates to direct grid neighbours and local attachments for manual nodes and endpoints.
-- Call a grid builder first. Hex grids have six neighbours. Rectangles have eight, or four with SetGridOptions({Diagonals=false}).
-- Diagonals require both flanking rectangular cells to exist; every edge still uses the configured LoS, road, distance or custom rule.
-- Endpoints retain their exact positions. Rectangular attachments use normalized cell distances: a diamond for four neighbours,
-- a square for eight. Hex attachments use a circle of radius Spacing. Manual nodes never attach directly to each other.
-- @param #ASTAR self
-- @param #boolean Enabled (Optional) Default true. False restores all-pairs candidate selection.
-- @return #ASTAR self
function ASTAR:SetGridNeighboursOnly(Enabled)
  if Enabled==nil then Enabled=true end
  assert(type(Enabled)=="boolean", "ASTAR: Enabled must be a boolean")
  assert(not Enabled or self.hexGrid or self.rectGrid, "ASTAR: create a grid before enabling grid neighbours")
  self.GridNeighboursOnly=Enabled
  return self
end

--- Compatibility alias for enabling local neighbours on a hex grid. Prefer SetGridNeighboursOnly().
-- @param #ASTAR self
-- @param #boolean Enabled (Optional) Default true.
-- @return #ASTAR self
function ASTAR:SetHexNeighboursOnly(Enabled)
  assert(Enabled==false or self.hexGrid, "ASTAR: call CreateHexGrid before enabling hex neighbours")
  return self:SetGridNeighboursOnly(Enabled)
end

--- Replace the neighbour rule with a visibility check at 1 meter above sea level.
-- Intended for water routes. A corridor adds two parallel visibility checks, not a continuous clearance test.
-- @param #ASTAR self
-- @param #number CorridorWidth (Optional) Total corridor width in meters; checks are offset by half this width on each side. Nil checks only the center line.
-- @return #ASTAR self
function ASTAR:SetValidNeighbourLoS(CorridorWidth)

  self:SetValidNeighbourFunction(ASTAR.LoS, CorridorWidth)

  return self
end

--- Replace the neighbour rule with a maximum 2D distance check, without checking terrain.
-- @param #ASTAR self
-- @param #number MaxDistance (Optional) Max distance between nodes in meters. Default is 2000 m.
-- @return #ASTAR self
function ASTAR:SetValidNeighbourDistance(MaxDistance)

  MaxDistance = MaxDistance or 2000

  self:SetValidNeighbourFunction(ASTAR.DistMax, MaxDistance)

  return self
end

--- Set valid neighbours to have a road connection within a maximum 2D distance.
-- Replaces the previous neighbour rule. Does not change the travel cost function; use SetCostRoad() separately for road costs.
-- @param #ASTAR self
-- @param #number MaxDistance (Optional) Maximum straight-line 2D distance between nodes in meters, inclusive. Default is 2000 m.
-- @return #ASTAR self
function ASTAR:SetValidNeighbourRoad(MaxDistance)

  MaxDistance = MaxDistance or 2000

  self:SetValidNeighbourFunction(ASTAR.Road, MaxDistance)

  return self
end

--- Set the function which calculates the "cost" to go from one to another node.
-- The first two arguments of this function are always the two nodes under consideration. But you can add optional arguments.
-- Very often the distance between nodes is a good measure for the cost.
-- Costs are used for traversed connections, must be non-negative and symmetric, and may be math.huge for an impassable connection.
-- Custom functions use a zero heuristic to preserve optimality. Calling this setter also clears previously cached costs.
-- @param #ASTAR self
-- @param #function CostFunction Function that returns the travel cost. Use nil to restore the default 2D distance.
-- @param ... Condition function arguments if any.
-- @return #ASTAR self
function ASTAR:SetCostFunction(CostFunction, ...)

  self.CostFunc=CostFunction
  
  self.CostArg={...}
  self.CostArg.n=select("#", ...)
  for _,node in pairs(self.nodes) do
    node.cost={}
  end
  
  return self
end

--- Set travel cost and heuristic to the 2D distance between nodes.
-- @param #ASTAR self
-- @return #ASTAR self
function ASTAR:SetCostDist2D()

  self:SetCostFunction(ASTAR.Dist2D)

  return self
end

--- Set travel cost and heuristic to the 3D distance between nodes.
-- @param #ASTAR self
-- @return #ASTAR self
function ASTAR:SetCostDist3D()

  self:SetCostFunction(ASTAR.Dist3D)

  return self
end

--- Set travel cost to the road distance between nodes, using a zero heuristic.
-- @param #ASTAR self
-- @return #ASTAR self
function ASTAR:SetCostRoad()

  self:SetCostFunction(ASTAR.DistRoad)

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Grid functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Build a rectangular grid using SetGridOptions() and SetValidSurfaceTypes().
-- Requires both endpoints and no prior grid. Retains manually added nodes. Generated centers have altitude zero.
-- No markers are created; call DrawGrid() or MarkGrid() explicitly.
-- @param #ASTAR self
-- @return #ASTAR self, or nil if MaxNodes would be exceeded before surface filtering.
-- @return #string node_limit on budget rejection; no nodes are added on rejection.
function ASTAR:CreateGrid(...)
  assert(select("#",...)==0, "ASTAR: configure SetGridOptions and SetValidSurfaceTypes before CreateGrid()")
  assert(not self.GridBuilt, "ASTAR: a grid already exists; use a new ASTAR object")
  assert(self.startVector and self.endVector, "ASTAR: start and end coordinates are required for a grid")
  local options=self:GetGridOptions()
  local Width,Margin,Spacing,CrossSpacing=options.Width,options.Margin,options.Spacing,options.CrossSpacing or options.Spacing
  local MaxNodes=options.MaxNodes
  local distance=self.startVector:GetDistance(self.endVector, true)
  -- Match the original numeric-for loop counts even when dimensions are not spacing multiples.
  local nx=math.floor(Width/CrossSpacing+1)
  local nz=math.floor((distance+2*Margin)/Spacing+1)
  if nx>MaxNodes/nz then return nil, "node_limit" end

  local angle=math.rad(self.startVector:GetHeadingTo(self.endVector))
  self.rectGrid={x=self.startVector.x, z=self.startVector.z, cos=math.cos(angle), sin=math.sin(angle),
    along=Spacing/2, across=CrossSpacing/2, spacing=Spacing, crossSpacing=CrossSpacing, distance=distance,
    alongOffset=-Margin-Spacing, acrossOffset=-Width/2-CrossSpacing}
  self.rectIndex={}
  self:_PopulateRectGrid({imin=1,imax=nx,jmin=1,jmax=nz,count=nx*nz},Width,Margin)
  self:T(self.lid..string.format("Built rectangular grid with %d total nodes",self.Nnodes))
  return self
end

--- Build an initial hex grid using SetGridOptions() and SetValidSurfaceTypes().
-- Requires both endpoints and an empty node set. CrossSpacing is not supported. Centers have altitude zero.
-- Call SetGridNeighboursOnly(true) for six-neighbor topology. No drawing is performed.
-- @param #ASTAR self
-- @return #ASTAR self, or nil if MaxNodes would be exceeded before surface filtering.
-- @return #string node_limit on budget rejection; no nodes are added on rejection.
function ASTAR:CreateHexGrid(...)
  assert(select("#",...)==0, "ASTAR: configure SetGridOptions and SetValidSurfaceTypes before CreateHexGrid()")
  assert(not self.GridBuilt and next(self.nodes)==nil, "ASTAR: create a hex grid on an empty ASTAR object")
  assert(self.startVector and self.endVector, "ASTAR: start and end coordinates are required for a hex grid")
  local options=self:GetGridOptions()
  assert(options.CrossSpacing==nil, "ASTAR: CrossSpacing is only supported by rectangular grids")
  local Width,Margin,Spacing,MaxNodes=options.Width,options.Margin,options.Spacing,options.MaxNodes

  local distance=self.startVector:GetDistance(self.endVector, true)
  local angle=distance>0 and math.rad(self.startVector:GetHeadingTo(self.endVector)) or 0
  local grid={x=self.startVector.x, z=self.startVector.z, cos=math.cos(angle), sin=math.sin(angle), spacing=Spacing,
    rowSpacing=Spacing*math.sqrt(3)/2, distance=distance}
  local bounds=hexBounds(grid, Width, Margin, MaxNodes)
  if not bounds then return nil, "node_limit" end

  self.hexGrid=grid
  self.hexIndex={}
  self:_PopulateHexGrid(bounds, Width, Margin)
  self:T(self.lid..string.format("Built hex grid with %d nodes, spacing %.1f m", self.Nnodes, Spacing))
  return self
end

--- Build initial hex centers inside a MOOSE circle, rectangle or polygon zone.
-- Requires endpoints and an empty node set. Uses configured Spacing, MaxNodes and surface types; ignores Width and Margin.
-- Checks the zone before terrain sampling. Expansion can subsequently leave the zone. CrossSpacing is rejected.
-- @param #ASTAR self
-- @param Core.Zone#ZONE_BASE Zone Initial zone.
-- @return #ASTAR self, or nil if the projected bounding-box candidates exceed MaxNodes before either filter.
-- @return #string node_limit on budget rejection.
function ASTAR:CreateHexGridFromZone(Zone,...)
  assert(select("#",...)==0, "ASTAR: zone is the only argument; configure SetGridOptions and SetValidSurfaceTypes first")
  assert(not self.GridBuilt and next(self.nodes)==nil, "ASTAR: create a hex grid on an empty ASTAR object")
  local options=self:GetGridOptions()
  assert(options.CrossSpacing==nil, "ASTAR: CrossSpacing is only supported by rectangular grids")
  local Spacing,MaxNodes=options.Spacing,options.MaxNodes
  local grid,area=zoneGridArea(self,Zone)
  grid.spacing=Spacing grid.rowSpacing=Spacing*math.sqrt(3)/2
  local width=2*math.max(math.abs(area.acrossMin),math.abs(area.acrossMax))
  local margin=math.max(0,-area.alongMin,area.alongMax-grid.distance)
  checkGridDimensions(width,margin)
  local bounds=hexBounds(grid,width,margin,MaxNodes,area)
  if not bounds then return nil,"node_limit" end
  self.hexGrid=grid
  self.hexIndex={}
  self:_PopulateHexGrid(bounds,width,margin,Zone)
  self:T(self.lid..string.format("Built zone hex grid with %d nodes, spacing %.1f m",self.Nnodes,Spacing))
  return self
end

--- Build rectangular centers inside a MOOSE circle, rectangle or polygon zone.
-- Requires endpoints and no prior grid. Retains manual nodes. Uses configured spacing, MaxNodes and surface types; ignores Width and Margin.
-- Checks the zone before terrain sampling. Expansion can subsequently leave the zone. No drawing is performed.
-- @param #ASTAR self
-- @param Core.Zone#ZONE_BASE Zone Initial zone.
-- @return #ASTAR self, or nil if the projected bounding-box candidates exceed MaxNodes before either filter.
-- @return #string node_limit on budget rejection.
function ASTAR:CreateGridFromZone(Zone,...)
  assert(select("#",...)==0, "ASTAR: zone is the only argument; configure SetGridOptions and SetValidSurfaceTypes first")
  assert(not self.GridBuilt, "ASTAR: a grid already exists; use a new ASTAR object")
  local options=self:GetGridOptions()
  local Spacing,CrossSpacing,MaxNodes=options.Spacing,options.CrossSpacing or options.Spacing,options.MaxNodes
  local grid,area=zoneGridArea(self,Zone)
  grid.along=Spacing/2 grid.across=CrossSpacing/2
  grid.spacing=Spacing grid.crossSpacing=CrossSpacing
  grid.alongOffset=0 grid.acrossOffset=0
  local width=2*math.max(math.abs(area.acrossMin),math.abs(area.acrossMax))
  local margin=math.max(0,-area.alongMin,area.alongMax-grid.distance)
  checkGridDimensions(width,margin)
  local bounds=rectBounds(grid,width,margin,MaxNodes,area)
  if not bounds then return nil,"node_limit" end
  self.rectGrid=grid
  self.rectIndex={}
  self:_PopulateRectGrid(bounds,width,margin,Zone)
  self:T(self.lid..string.format("Built zone rectangular grid with %d total nodes",self.Nnodes))
  return self
end

--- Enlarge a rectangular or hex grid without replacing nodes, caches, spacing, origin or orientation.
-- Uses configured MaxNodes, Expansion.MaxWidth and Expansion.MaxMargin. Does not fit oversized requests or draw anything.
-- Previously sampled cells are retained; the first actual enlargement of a zone seed fills unsampled holes.
-- @param #ASTAR self
-- @param #number Width New total width, at least the current width.
-- @param #number Margin New margin at each end, at least the current margin.
-- @return #ASTAR self, or nil if a configured limit would be exceeded.
-- @return #string node_limit or size_limit on rejection.
function ASTAR:ExpandGrid(Width, Margin, ...)
  assert(select("#",...)==0, "ASTAR: configure MaxNodes in SetGridOptions")
  local options=self:GetGridOptions()
  local MaxNodes=options.MaxNodes

  local grid=self.hexGrid or self.rectGrid
  assert(grid, "ASTAR: create a rectangular or hex grid before expanding")
  checkGridDimensions(Width, Margin)
  assert(Width>=grid.boxHY and Margin>=grid.spaceX, "ASTAR: grid width and margin cannot shrink")
  if Width>options.Expansion.MaxWidth or Margin>options.Expansion.MaxMargin then return nil,"size_limit" end
  if Width==grid.boxHY and Margin==grid.spaceX then
    if MaxNodes and grid.candidateCount>MaxNodes then return nil,"node_limit" end
    return self
  end
  local bounds=expansionBounds(self, Width, Margin, MaxNodes)
  if not bounds then return nil, "node_limit" end
  return self:_PopulateGrid(bounds, Width, Margin)
end

--- Enlarge a hex grid. See ExpandGrid() for limits and behavior.
-- @param #ASTAR self
-- @param #number Width New total width.
-- @param #number Margin New margin at each end.
-- @return #ASTAR self, or nil on rejection.
-- @return #string node_limit or size_limit on rejection.
function ASTAR:ExpandHexGrid(Width, Margin, ...)
  assert(self.hexGrid, "ASTAR: call CreateHexGrid before expanding a hex grid")
  return self:ExpandGrid(Width,Margin,...)
end

-- Dispatch population only after the candidate budget has been checked.
function ASTAR:_PopulateGrid(Bounds, Width, Margin)
  if self.hexGrid then return self:_PopulateHexGrid(Bounds,Width,Margin) end
  return self:_PopulateRectGrid(Bounds,Width,Margin)
end

--- Add preflighted rectangular cells, retaining previously accepted and rejected samples.
-- @param #ASTAR self
-- @param #table Bounds Rectangular index ranges and candidate count.
-- @param #number Width New total width.
-- @param #number Margin New margin.
-- @param Core.Zone#ZONE_BASE Zone Optional initial zone filter.
-- @return #ASTAR self
function ASTAR:_PopulateRectGrid(Bounds, Width, Margin, Zone)
  local grid=self.rectGrid
  local old=grid.bounds
  local sampled=Zone and {} or nil
  for i=Bounds.imin,Bounds.imax do
    for j=Bounds.jmin,Bounds.jmax do
      local existingCell=old and i>=old.imin and i<=old.imax and j>=old.jmin and j<=old.jmax
      if grid.initialSamples then existingCell=grid.initialSamples[i] and grid.initialSamples[i][j] end
      if not existingCell then
        local x,z=gridPosition(grid,grid.alongOffset+j*grid.spacing,grid.acrossOffset+i*grid.crossSpacing)
        if not Zone or Zone:IsVec2InZone({x=x,y=z}) then
          if sampled then sampled[i]=sampled[i] or {} sampled[i][j]=true end
          local node=self:GetNodeFromCoordinate(VECTOR:New(x,0,z))
          if self:CheckValidSurfaceType(node,self.ValidSurfaceTypes) then
            node.rectGrid=grid
            node.i=i node.j=j
            self:AddNode(node)
          end
        end
      end
    end
  end
  grid.initialSamples=sampled
  grid.bounds=Bounds
  grid.boxHY=Width grid.spaceX=Margin grid.candidateCount=Bounds.count
  self.GridCandidateCount=Bounds.count
  self.GridBuilt=true
  return self
end

--- Find the largest budget-compatible fraction of a requested growth step without terrain queries.
-- First fits balanced growth, then spends remaining room on either axis. Discrete cell boundaries can leave unused budget.
-- Returns nil when no new candidate cells (or zone-seed holes) can be reached within the budget.
-- @param #ASTAR self
-- @param #number Width Requested width.
-- @param #number Margin Requested margin.
-- @param #number MaxNodes Candidate-cell budget.
function ASTAR:_FitGridExpansion(Width, Margin, MaxNodes)
  local grid=self.hexGrid or self.rectGrid
  local function fit(fromWidth,fromMargin,toWidth,toMargin)
    local full=expansionBounds(self,toWidth,toMargin,MaxNodes)
    if full then return toWidth,toMargin,full end
    local low,high=0,1
    local bestWidth,bestMargin,best
    for i=1,52 do
      local fraction=(low+high)/2
      local width=fromWidth+(toWidth-fromWidth)*fraction
      local margin=fromMargin+(toMargin-fromMargin)*fraction
      local bounds=expansionBounds(self,width,margin,MaxNodes)
      if bounds then
        low=fraction bestWidth=width bestMargin=margin best=bounds
      else high=fraction end
    end
    return bestWidth,bestMargin,best
  end
  local width,margin,bounds=fit(grid.boxHY,grid.spaceX,Width,Margin)
  if not bounds then return nil end
  -- Lattice counts jump at row boundaries. Use remaining room on either axis if balanced growth cannot reach it.
  local w1,m1,b1=fit(width,margin,Width,margin)
  if b1 then w1,m1,b1=fit(w1,m1,w1,Margin) end
  local w2,m2,b2=fit(width,margin,width,Margin)
  if b2 then w2,m2,b2=fit(w2,m2,Width,m2) end
  -- Also try each axis from the original bounds: the balanced prefix may have spent too much margin to fit a whole row.
  local w3,m3,b3=fit(grid.boxHY,grid.spaceX,Width,grid.spaceX)
  if b3 then w3,m3,b3=fit(w3,m3,w3,Margin) end
  local w4,m4,b4=fit(grid.boxHY,grid.spaceX,grid.boxHY,Margin)
  if b4 then w4,m4,b4=fit(w4,m4,Width,m4) end
  for _,candidate in ipairs({{w1,m1,b1},{w2,m2,b2},{w3,m3,b3},{w4,m4,b4}}) do
    local w,m,b=candidate[1],candidate[2],candidate[3]
    if b and (b.count>bounds.count or (b.count==bounds.count and w*(grid.distance+2*m)>width*(grid.distance+2*margin))) then
      width,margin,bounds=w,m,b
    end
  end
  if bounds.count>grid.candidateCount or (grid.initialSamples and (width>grid.boxHY or margin>grid.spaceX)) then
    return width,margin,bounds
  end
end

--- Add the new cells from preflighted hex bounds. Used by creation and enlargement.
-- @param #ASTAR self
-- @param #table Bounds Axial row ranges and candidate count.
-- @param #number Width New total width.
-- @param #number Margin New margin.
-- @param Core.Zone#ZONE_BASE Zone Optional zone filter for the initial build only.
-- @return #ASTAR self
function ASTAR:_PopulateHexGrid(Bounds, Width, Margin, Zone)

  local grid=self.hexGrid
  local sampled=Zone and {} or nil
  local oldRmin, oldRmax
  if grid.boxHY then oldRmin, oldRmax=hexRowBounds(grid, grid.boxHY) end
  for r=Bounds.rmin,Bounds.rmax do
    local row=Bounds[r]
    local oldQmin, oldQmax
    if grid.spaceX then oldQmin, oldQmax=hexColumnBounds(grid, grid.spaceX, r) end
    for q=row.qmin,row.qmax do
      local existingCell=oldRmin and r>=oldRmin and r<=oldRmax and q>=oldQmin and q<=oldQmax
      -- A zone seed has unsampled holes inside its bounding rectangle. Fill them on the first real enlargement.
      if grid.initialSamples then existingCell=grid.initialSamples[r] and grid.initialSamples[r][q] end
      if not existingCell then
        local x,z=gridPosition(grid, grid.spacing*(q+r/2), grid.rowSpacing*r)
        if not Zone or Zone:IsVec2InZone({x=x,y=z}) then
          if sampled then sampled[r]=sampled[r] or {} sampled[r][q]=true end
          local vector=VECTOR:New(x,0,z)
          local node=self:GetNodeFromCoordinate(vector)
          if self:CheckValidSurfaceType(node, self.ValidSurfaceTypes) then
            node.q=q
            node.r=r
            self:AddNode(node)

          end
        end
      end
    end
  end
  grid.initialSamples=sampled
  grid.boxHY=Width
  grid.spaceX=Margin
  grid.candidateCount=Bounds.count
  self.GridCandidateCount=Bounds.count
  self.GridBuilt=true
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Grid drawing
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Count neighbours under the current graph mode.
-- Candidate counts do not evaluate user rules. Valid counts evaluate the neighbour rule, including its caches;
-- they do not check travel costs. In unrestricted mode all other nodes are candidates, including on rectangular grids.
-- @param #ASTAR self
-- @param #ASTAR.Node Node Node owned by this object.
-- @param #boolean CheckValid (Optional) Apply the current neighbour rule. Default false.
-- @return #number Neighbour count.
function ASTAR:GetNodeNeighbourCount(Node, CheckValid)
  assert(Node and self.nodes[Node.id]==Node, "ASTAR: node must belong to this object")
  local count=0
  if self.GridNeighboursOnly then
    if not self.gridLinks then self:_BuildGridLinks() end
    for id in pairs(self.gridLinks[Node.id] or {}) do
      if not CheckValid or self:_IsValidNeighbour(Node,self.nodes[id]) then count=count+1 end
    end
  elseif not CheckValid then return math.max(0,self.Nnodes-1)
  else
    for id,other in pairs(self.nodes) do
      if id~=Node.id and self:_IsValidNeighbour(Node,other) then count=count+1 end
    end
  end
  return count
end

--- Mark current nodes with separate F10 text labels. Replaces previous text labels only; does not draw polygons.
-- Snapshot of the current node list. Counts are evaluated when each batch runs; later additions are not marked automatically.
-- Candidate counts are cheap. CheckNeighbours evaluates the neighbour rule and can be expensive, especially without local grid mode.
-- Work is batched; one node's connection checks cannot be interrupted. Without a CPU clock only one marker is processed per batch.
-- @param #ASTAR self
-- @param #ASTAR.MarkGridOptions Options (Optional) Label fields, recipient and batch settings.
-- @return #ASTAR self. LastGridMarkResult contains Status, NodesQueued, NodesMarked, Batches and timing.
function ASTAR:MarkGrid(Options)
  if Options==nil then Options={} end
  assert(type(Options)=="table", "ASTAR: marker options must be a table")
  local style={ShowID=true,ShowGridIndex=true,ShowNeighbourCount=true,CheckNeighbours=false,
    Coalition=-1,ReadOnly=true,BatchSize=25,Interval=0.1,MaxBatchSeconds=0.005}
  for key,value in pairs(Options) do
    assert(style[key]~=nil, "ASTAR: unknown marker option '"..tostring(key).."'")
    if type(style[key])=="boolean" then assert(type(value)=="boolean", "ASTAR: "..key.." must be a boolean")
    elseif key=="Coalition" then
      assert(type(value)=="number" and value>=-1 and value<=2 and value==math.floor(value), "ASTAR: Coalition must be -1, 0, 1 or 2")
    else
      assert(type(value)=="number" and value>0 and value<math.huge, "ASTAR: "..key.." must be finite and positive")
      if key=="BatchSize" then assert(value==math.floor(value), "ASTAR: BatchSize must be an integer") end
    end
    style[key]=value
  end
  assert(style.ShowID or style.ShowGridIndex or style.ShowNeighbourCount, "ASTAR: select at least one marker field")
  self:UnmarkGrid()
  local nodes={}
  for id in pairs(self.nodes) do nodes[#nodes+1]=id end
  table.sort(nodes)
  local clock=startCPUClock()
  local job={nodes=nodes,index=1,style=style,started=timer.getTime(),
    result={Status="queued",NodesQueued=#nodes,NodesMarked=0,Batches=0,
      CPUSeconds=clock and 0 or nil,MaxBatchCPUSeconds=clock and 0 or nil}}
  self.GridMarkJob=job self.LastGridMarkResult=job.result
  -- Always defer non-empty jobs; this keeps optional neighbour checks out of the caller's frame.
  if #nodes==0 then self:_FinishGridMarking(job,"complete")
  else
    job.timerID=timer.scheduleFunction(function()
      if self.GridMarkJob~=job then return nil end
      if self:_ProcessGridMarkJob(job) then return timer.getTime()+style.Interval end
    end,nil,timer.getTime()+style.Interval)
  end
  return self
end

--- Cancel pending node labels and remove this object's text markers. Leaves grid polygons intact.
-- @param #ASTAR self
-- @return #ASTAR self
function ASTAR:UnmarkGrid()
  local job=self.GridMarkJob
  if job then
    if job.timerID then timer.removeFunction(job.timerID) end
    self:_FinishGridMarking(job,"cancelled")
  end
  for _,id in ipairs(self.GridMarkIDs or {}) do trigger.action.removeMark(id) end
  self.GridMarkIDs={}
  return self
end

--- Process one batch of node text labels.
-- @param #ASTAR self
-- @param #table Job Marker job.
function ASTAR:_ProcessGridMarkJob(Job)
  if self.GridMarkJob~=Job then return false end
  Job.result.Status="running"
  local clock=startCPUClock()
  local ok,err=pcall(function()
    local last=math.min(#Job.nodes,Job.index+(clock and Job.style.BatchSize or 1)-1)
    while Job.index<=last do
      local node=self.nodes[Job.nodes[Job.index]]
      if node then
        local text={}
        local style=Job.style
        if style.ShowID then text[#text+1]="Node "..node.id end
        if style.ShowGridIndex then
          if node.q~=nil then text[#text+1]=string.format("Hex: q=%d r=%d",node.q,node.r)
          elseif node.i~=nil then text[#text+1]=string.format("Grid: i=%d j=%d",node.i,node.j)
          else text[#text+1]="Manual / endpoint" end
        end
        if style.ShowNeighbourCount then
          text[#text+1]="Candidates: "..self:GetNodeNeighbourCount(node)
          if style.CheckNeighbours then text[#text+1]="Valid connections: "..self:GetNodeNeighbourCount(node,true) end
        end
        local id=node.vector:Mark(table.concat(text,"\n"),style.Coalition,style.ReadOnly)
        if id then self.GridMarkIDs[#self.GridMarkIDs+1]=id Job.result.NodesMarked=Job.result.NodesMarked+1 end
      end
      Job.index=Job.index+1
      if clock and elapsedCPU(clock)>=Job.style.MaxBatchSeconds then break end
    end
  end)
  local duration=elapsedCPU(clock)
  Job.result.Batches=Job.result.Batches+1
  if duration and Job.result.CPUSeconds then
    Job.result.CPUSeconds=Job.result.CPUSeconds+duration
    Job.result.MaxBatchCPUSeconds=math.max(Job.result.MaxBatchCPUSeconds,duration)
  else Job.result.CPUSeconds=nil Job.result.MaxBatchCPUSeconds=nil end
  if not ok then self:_FinishGridMarking(Job,"error",tostring(err))
  elseif Job.index>#Job.nodes then self:_FinishGridMarking(Job,"complete")
  else return true end
  return false
end

--- Finish, fail or cancel a marker job.
-- @param #ASTAR self
-- @param #table Job Marker job.
-- @param #string Status Completion status.
-- @param #string Error Optional error detail.
function ASTAR:_FinishGridMarking(Job, Status, Error)
  Job.result.Status=Status Job.result.Error=Error
  Job.result.ElapsedSimulationSeconds=math.max(0,timer.getTime()-Job.started)
  self.GridMarkJob=nil Job.timerID=nil
  if Error then self:E(self.lid.."Grid marking failed: "..Error) end
end

--- Draw accepted grid cells on the F10 map, replacing the previous DrawGrid() overlay.
-- Draws one polygon per generated node, with the original grid orientation. Manual nodes and extra endpoints are skipped.
-- Hex vertex radius is Spacing / sqrt(3); rectangular half-sizes are Spacing/2 and CrossSpacing/2.
-- Cells may extend beyond the search area or cover terrain rejected at other node positions. The overlay does not show connectivity.
-- Does not change pathfinding. Large jobs are scheduled in batches; existing polygon removal and each batch run synchronously.
-- @param #ASTAR self
-- @param #number Coalition (Optional) All=-1, Neutral=0, Red=1, Blue=2. Default -1.
-- @param #table Color (Optional) Outline RGB values in [0,1], default {0,0,1} (blue).
-- @param #number Alpha (Optional) Outline opacity in [0,1], default 1.
-- @param #table FillColor (Optional) Fill RGB values, default the outline color.
-- @param #number FillAlpha (Optional) Fill opacity in [0,1], default 0 (transparent).
-- @param #number LineType (Optional) 0=none, 1=solid, 2=dashed, 3=dotted, 4=dot dash, 5=long dash, 6=two dash. Default 1.
-- @param #boolean ReadOnly (Optional) Prevent users from removing polygons manually. Default true.
-- @param #table DrawOptions (Optional) BatchSize=25 cells, Interval=0.1 simulation seconds, MaxBatchSeconds=0.005 CPU seconds. No CPU clock means one cell per batch.
-- @return #ASTAR self; large overlays may still be queued. Inspect LastGridDrawResult for progress.
function ASTAR:DrawGrid(Coalition, Color, Alpha, FillColor, FillAlpha, LineType, ReadOnly, DrawOptions)
  Color=Color or {0,0,1}
  FillColor=FillColor or Color
  if ReadOnly==nil then ReadOnly=true end
  local style={Coalition=Coalition or -1, Color={Color[1],Color[2],Color[3]}, Alpha=Alpha or 1,
    FillColor={FillColor[1],FillColor[2],FillColor[3]}, FillAlpha=FillAlpha or 0, LineType=LineType or 1, ReadOnly=ReadOnly}
  return self:_StartGridDrawing(style, DrawOptions)
end

--- Draw a one-time debug snapshot of the current grid, highlighting the supplied path's grid cells in green.
-- Uses a previously returned path; does not run a search or enable automatic drawing. Replaces this object's previous overlay.
-- Manual nodes and exact endpoints without grid cells are skipped. An empty successful path draws the grid without highlights.
-- Later searches, grid additions and UpdateGridDrawing() do not update this snapshot. Call this method again to replace it.
-- Drawing is batched; UndrawGrid() cancels pending batches and removes the snapshot.
-- @param #ASTAR self
-- @param #table Path Ordered node list from a successful search on this ASTAR object. Nil or foreign nodes are rejected before replacing an overlay.
-- @param #table Options (Optional) Coalition=-1, GridColor={0,0,1}, PathColor={0,1,0}, PathFillAlpha=0.35.
-- Also accepts BatchSize=25, Interval=0.1 and MaxBatchSeconds=0.005. Colors and the path selection are copied at call time.
-- @return #ASTAR self; inspect LastGridDrawResult for drawing progress.
function ASTAR:DrawGridWithPath(Path, Options)
  assert(type(Path)=="table", "ASTAR: DrawGridWithPath requires a successful path table")
  Options=Options or {}
  assert(type(Options)=="table", "ASTAR: path drawing options must be a table")
  local pathNodes={}
  for _,node in ipairs(Path) do
    assert(type(node)=="table" and self.nodes[node.id]==node, "ASTAR: path nodes must belong to this ASTAR object")
    pathNodes[node.id]=true
  end
  local color=Options.GridColor or {0,0,1}
  local pathColor=Options.PathColor or {0,1,0}
  local fillAlpha=Options.PathFillAlpha or 0.35
  assert(type(fillAlpha)=="number" and fillAlpha>=0 and fillAlpha<=1, "ASTAR: PathFillAlpha must be between zero and one")
  local style={Coalition=Options.Coalition or -1, Color={color[1],color[2],color[3]}, Alpha=1,
    FillColor={color[1],color[2],color[3]}, FillAlpha=0, LineType=1, ReadOnly=true,
    Snapshot=true, PathNodeIDs=pathNodes, PathColor={pathColor[1],pathColor[2],pathColor[3]}, PathFillAlpha=fillAlpha}
  return self:_StartGridDrawing(style, Options)
end

--- Validate batch settings and replace the overlay before starting a regular drawing or debug snapshot.
-- @param #ASTAR self
-- @param #table Style Owned style table.
-- @param #table DrawOptions Optional batch settings.
-- @return #ASTAR self
function ASTAR:_StartGridDrawing(Style, DrawOptions)
  DrawOptions=DrawOptions or {}
  assert(type(DrawOptions)=="table", "ASTAR: drawing options must be a table")
  local batchSize=DrawOptions.BatchSize or 25
  local interval=DrawOptions.Interval or 0.1
  local maxBatchSeconds=DrawOptions.MaxBatchSeconds or 0.005
  assert(type(batchSize)=="number" and batchSize>=1 and batchSize<math.huge and batchSize==math.floor(batchSize), "ASTAR: drawing BatchSize must be a positive integer")
  assert(type(interval)=="number" and interval>0 and interval<math.huge, "ASTAR: drawing Interval must be finite and positive")
  assert(type(maxBatchSeconds)=="number" and maxBatchSeconds>0 and maxBatchSeconds<math.huge,"ASTAR: drawing MaxBatchSeconds must be finite and positive")
  self:UndrawGrid()
  Style.BatchSize=batchSize
  Style.Interval=interval
  Style.MaxBatchSeconds=maxBatchSeconds
  self.GridDrawOptions=Style
  return self:UpdateGridDrawing()
end

--- Add missing cell polygons to the current overlay, retaining its style and existing marks.
-- Also extends a pending drawing job without duplicating queued cells. Does nothing before DrawGrid() or for an already queued debug snapshot.
-- @param #ASTAR self
-- @return #ASTAR self
function ASTAR:UpdateGridDrawing()
  local style=self.GridDrawOptions
  if not style or (style.Snapshot and style.SnapshotQueued) then return self end
  if style.Snapshot then style.SnapshotQueued=true end
  local job=self.GridDrawJob
  if not job then
    local cpuAvailable=os and type(os.clock)=="function"
    job={nodes={}, queued={}, index=1, style=style, started=timer.getTime(),
      result={Status="queued", NodesQueued=0, NodesDrawn=0, Batches=0,
        CPUSeconds=cpuAvailable and 0 or nil, MaxBatchCPUSeconds=cpuAvailable and 0 or nil}}
  end
  for id,node in pairs(self.nodes) do
    if (node.rectGrid or (self.hexGrid and node.q~=nil and node.r~=nil))
      and not self.GridDrawNodeIDs[id] and not job.queued[id] then
      job.nodes[#job.nodes+1]=id
      job.queued[id]=true
    end
  end
  job.result.NodesQueued=#job.nodes
  -- An active job will process appended nodes on subsequent ticks.
  if self.GridDrawJob then return self end
  self.GridDrawJob=job
  self.LastGridDrawResult=job.result
  local pending=true
  if #job.nodes<=style.BatchSize then pending=self:_ProcessGridDrawJob(job) end
  if pending then
    self:T(self.lid..string.format("Grid drawing queued: %d remaining cells, up to %d per batch, %.3f sec CPU budget (one cell without CPU clock)",
      #job.nodes-job.index+1, style.BatchSize, style.MaxBatchSeconds))
    job.timerID=timer.scheduleFunction(function(_, time)
      -- Identity check also protects against an already-dispatched callback after cancellation or replacement.
      if self.GridDrawJob~=job then return nil end
      if self:_ProcessGridDrawJob(job) then return timer.getTime()+style.Interval end
    end, nil, timer.getTime()+style.Interval)
  end
  return self
end

--- Draw one batch, bounded by cell count and a CPU budget checked after each cell. Without a CPU clock draw at most one cell.
-- @param #ASTAR self
-- @param #table Job Current drawing job.
-- @return #boolean Whether the job needs another batch.
function ASTAR:_ProcessGridDrawJob(Job)
  if self.GridDrawJob~=Job then return false end
  Job.result.Status="running"
  local clock=startCPUClock()
  local ok, err=pcall(function()
    -- Count remains an upper limit; with no CPU clock use a conservative one-cell fallback.
    local batchSize=clock and Job.style.BatchSize or 1
    local last=math.min(#Job.nodes, Job.index+batchSize-1)
    while Job.index<=last do
      local id=Job.nodes[Job.index]
      local node=self.nodes[id]
      if node and not self.GridDrawNodeIDs[id] then
        local markID=self:_DrawGridNode(node, Job.style)
        if markID then
          self.GridDrawIDs[#self.GridDrawIDs+1]=markID
          self.GridDrawNodeIDs[id]=markID
          Job.result.NodesDrawn=Job.result.NodesDrawn+1
        end
      end
      Job.queued[id]=nil
      Job.index=Job.index+1
      -- A DCS call cannot be interrupted; yield before starting the next cell once the budget is exhausted.
      if clock and elapsedCPU(clock)>=Job.style.MaxBatchSeconds then break end
    end
  end)
  local duration=elapsedCPU(clock)
  Job.result.Batches=Job.result.Batches+1
  if duration and Job.result.CPUSeconds then
    Job.result.CPUSeconds=Job.result.CPUSeconds+duration
    Job.result.MaxBatchCPUSeconds=math.max(Job.result.MaxBatchCPUSeconds, duration)
  else
    Job.result.CPUSeconds=nil
    Job.result.MaxBatchCPUSeconds=nil
  end
  if not ok then
    self:_FinishGridDrawing(Job, "error", tostring(err))
  elseif Job.index>#Job.nodes then
    self:_FinishGridDrawing(Job, "complete")
  else
    return true
  end
  return false
end

--- Complete or cancel a drawing job, retaining its result for callers.
-- @param #ASTAR self
-- @param #table Job Current drawing job.
-- @param #string Status complete, cancelled or error.
-- @param #string Error Optional error message.
function ASTAR:_FinishGridDrawing(Job, Status, Error)
  Job.result.Status=Status
  Job.result.Error=Error
  Job.result.ElapsedSimulationSeconds=math.max(0, timer.getTime()-Job.started)
  self.GridDrawJob=nil
  Job.timerID=nil
  local text=string.format("Grid drawing %s: %d/%d new cells, %d batches, %s, max batch %s, simulation elapsed %.3f sec",
    Status, Job.result.NodesDrawn, Job.result.NodesQueued, Job.result.Batches, cpuTimeText(Job.result.CPUSeconds),
    cpuTimeText(Job.result.MaxBatchCPUSeconds), Job.result.ElapsedSimulationSeconds)
  if Error then self:E(self.lid..text..": "..Error) else self:T(self.lid..text) end
end

--- Draw one generated grid cell using the saved style; manual endpoints have no polygon.
-- @param #ASTAR self
-- @param #ASTAR.Node Node Grid node.
-- @param #table Style Drawing options.
-- @return #number Mark id, or nil for a node without a cell.
function ASTAR:_DrawGridNode(Node, Style)
  local corners={}
  local grid=Node.rectGrid
  local function corner(along, across)
    local x,z=gridPosition(grid, along, across, Node.vector)
    corners[#corners+1]={x=x, y=0, z=z}
  end
  if self.hexGrid and Node.q~=nil and Node.r~=nil then
    grid=self.hexGrid
    local radius=grid.spacing/math.sqrt(3)
    for i=0,5 do
      local angle=math.rad(30+60*i)
      corner(radius*math.cos(angle), radius*math.sin(angle))
    end
  elseif grid then
    corner(grid.along, grid.across)
    corner(-grid.along, grid.across)
    corner(-grid.along, -grid.across)
    corner(grid.along, -grid.across)
  end
  if #corners==0 then return nil end
  -- Match COORDINATE:MarkupToAllFreeForm's DCS call without constructing full MOOSE objects for polygon vertices.
  local markID=UTILS.GetMarkID()
  local onPath=Style.PathNodeIDs and Style.PathNodeIDs[Node.id]
  local color=onPath and Style.PathColor or Style.Color
  local fillColor=onPath and Style.PathColor or Style.FillColor
  local fillAlpha=onPath and Style.PathFillAlpha or Style.FillAlpha
  local outline={color[1],color[2],color[3],Style.Alpha}
  local fill={fillColor[1],fillColor[2],fillColor[3],fillAlpha}
  if #corners==6 then
    trigger.action.markupToAll(7, Style.Coalition, markID, corners[1], corners[2], corners[3], corners[4], corners[5], corners[6],
      outline, fill, Style.LineType, Style.ReadOnly, "")
  else
    trigger.action.markupToAll(7, Style.Coalition, markID, corners[1], corners[2], corners[3], corners[4],
      outline, fill, Style.LineType, Style.ReadOnly, "")
  end
  return markID
end

--- Cancel pending drawing and remove polygons created by DrawGrid() without changing the grid or deleting other F10 marks.
-- Removal is synchronous. Safe to call repeatedly or before drawing. Does not remove MarkGrid text markers.
-- @param #ASTAR self
-- @return #ASTAR self
function ASTAR:UndrawGrid()
  local job=self.GridDrawJob
  if job then
    if job.timerID then timer.removeFunction(job.timerID) end
    self:_FinishGridDrawing(job, "cancelled")
  end
  for _,markID in ipairs(self.GridDrawIDs or {}) do trigger.action.removeMark(markID) end
  self.GridDrawIDs={}
  self.GridDrawNodeIDs={}
  self.GridDrawOptions=nil
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Valid neighbour functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Check visibility between two node positions at a fixed altitude of 1 meter above sea level.
-- Uses land.isVisible; the nodes' own altitudes are ignored. A corridor checks the center line and two parallel offset lines.
-- @param #ASTAR.Node nodeA First node.
-- @param #ASTAR.Node nodeB Other node.
-- @param #number corridor (Optional) Total corridor width in meters. Nil checks only the center line.
-- @return #boolean If true, two nodes have LoS.
function ASTAR.LoS(nodeA, nodeB, corridor)

  local offset=1
  
  local dx=corridor and corridor/2 or nil
  local dy=dx
  
  local cA=nodeA.vector:GetVec3()
  local cB=nodeB.vector:GetVec3()
  cA.y=offset
  cB.y=offset

  local los=land.isVisible(cA, cB)
  
  if los and corridor then
  
    -- Heading from A to B.
    local heading=nodeA.vector:GetHeadingTo(nodeB.vector)
    
    local Ap=UTILS.VecTranslate(cA, dx, heading+90)
    local Bp=UTILS.VecTranslate(cB, dx, heading+90)

    los=land.isVisible(Ap, Bp)
    
    if los then

      local Am=UTILS.VecTranslate(cA, dx, heading-90)
      local Bm=UTILS.VecTranslate(cB, dx, heading-90)
    
      los=land.isVisible(Am, Bm)
    end
    
  end

  return los
end

--- Check for a DCS road connection between nodes within the maximum straight-line 2D distance.
-- @param #ASTAR.Node nodeA First node.
-- @param #ASTAR.Node nodeB Other node.
-- @param #number distmax (Optional) Maximum 2D distance in meters. Default is 2000 m.
-- @return #boolean If true, two nodes are connected via a road.
function ASTAR.Road(nodeA, nodeB, distmax)

  if not ASTAR.DistMax(nodeA, nodeB, distmax) then
    return false
  end

  local path=land.findPathOnRoads("roads", nodeA.vector.x, nodeA.vector.z, nodeB.vector.x, nodeB.vector.z)
  
  if path then
    return true    
  else
    return false
  end

end

--- Check whether the 2D distance between two nodes is at most a threshold.
-- @param #ASTAR.Node nodeA First node.
-- @param #ASTAR.Node nodeB Other node.
-- @param #number distmax (Optional) Max distance in meters. Default is 2000 m.
-- @return #boolean True if the distance is less than or equal to the threshold.
function ASTAR.DistMax(nodeA, nodeB, distmax)

  distmax=distmax or 2000

  local dist=nodeA.vector:GetDistance(nodeB.vector, true)
  
  return dist<=distmax
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Distance and travel cost functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Return the straight-line 2D distance between two nodes.
-- @param #ASTAR.Node nodeA First node.
-- @param #ASTAR.Node nodeB Other node.
-- @return #number Distance between the two nodes.
function ASTAR.Dist2D(nodeA, nodeB)
  local dist=nodeA.vector:GetDistance(nodeB.vector, true)
  return dist
end

--- Return the straight-line 3D distance between two nodes, including their altitudes.
-- @param #ASTAR.Node nodeA First node.
-- @param #ASTAR.Node nodeB Other node.
-- @return #number Distance between the two nodes.
function ASTAR.Dist3D(nodeA, nodeB)
  local dist=nodeA.vector:GetDistance(nodeB.vector)
  return dist
end

--- Return the length of the road path from land.findPathOnRoads between two nodes.
-- @param #ASTAR.Node nodeA First node.
-- @param #ASTAR.Node nodeB Other node.
-- @return #number Road path length in meters, or math.huge if DCS returns no path.
function ASTAR.DistRoad(nodeA, nodeB)

  -- Get the path.
  local path=land.findPathOnRoads("roads", nodeA.vector.x, nodeA.vector.z, nodeB.vector.x, nodeB.vector.z)
  
  if path then
  
    local dist=0
    
    for i=2,#path do
      local b=path[i] --DCS#Vec2
      local a=path[i-1] --DCS#Vec2
      
      dist=dist+UTILS.VecDist2D(a,b)
      
    end

    return dist
  end
  

  return math.huge
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Find the closest node from a given coordinate.
-- @param #ASTAR self
-- @param Core.Point#COORDINATE Coordinate Reference position; also accepts VECTOR, DCS Vec2 or Vec3.
-- @return #ASTAR.Node Closest node by 2D distance, or nil if the node set is empty.
-- @return #number Distance to the closest node in meters, or math.huge if the node set is empty.
function ASTAR:FindClosestNode(Coordinate)

  local distMin=math.huge
  local closeNode=nil
  
  for _,_node in pairs(self.nodes) do
    local node=_node --#ASTAR.Node
    
    local dist=node.vector:GetDistance(Coordinate, true)
    
    if dist<distMin then
      distMin=dist
      closeNode=node
    end
    
  end
    
  return closeNode, distMin
end

--- Select the closest start node, or add an exact start node if the closest is more than 1000 meters away.
-- In local grid mode, any 2D displacement greater than 0.000001 meters creates an exact endpoint instead of snapping.
-- Sets startNode to nil if the node set is empty or an added endpoint fails the surface filter.
-- @param #ASTAR self
-- @return #ASTAR self
function ASTAR:FindStartNode()
  self.startNode=self:_FindEndpoint(self.startVector, "start")
  return self
end

--- Select the closest goal node, or add an exact goal node if the closest is more than 1000 meters away.
-- In local grid mode, any 2D displacement greater than 0.000001 meters creates an exact endpoint instead of snapping.
-- Sets endNode to nil if the node set is empty or an added endpoint fails the surface filter.
-- @param #ASTAR self
-- @return #ASTAR self
function ASTAR:FindEndNode()
  self.endNode=self:_FindEndpoint(self.endVector, "end")
  return self
end

--- Resolve one endpoint using the current snapping threshold and surface filter.
-- @param #ASTAR self
-- @param Core.Vector#VECTOR Coordinate Requested endpoint.
-- @param #string Label Endpoint name for trace output.
-- @return #ASTAR.Node Selected or added node, or nil.
function ASTAR:_FindEndpoint(Coordinate, Label)
  if not Coordinate then return nil end
  local node, distance=self:FindClosestNode(Coordinate)
  local threshold=self.GridNeighboursOnly and 1e-6 or 1000
  if node and distance>threshold then
    self:T(self.lid.."Adding "..Label.." node to node grid!")
    node=self:GetNodeFromCoordinate(Coordinate)
    if not self:CheckValidSurfaceType(node, self.ValidSurfaceTypes) then return nil end
    self:AddNode(node)
  end
  return node
end

--- Resolve both endpoints for candidate checks and full searches.
-- @param #ASTAR self
-- @return #ASTAR.Node Start node, or nil.
-- @return #ASTAR.Node Goal node, or nil.
-- @return #string Failure reason, or nil.
function ASTAR:_ResolveEndpoints()
  if not self.startVector or not self.endVector then return nil, nil, "missing_coordinates" end
  self:FindStartNode()
  self:FindEndNode()
  local reason
  if not self.startNode then reason="no_start_node"
  elseif not self.endNode then reason="no_goal_node" end
  return self.startNode, self.endNode, reason
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Main A* pathfinding function
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Check whether the candidate graph can connect the requested endpoints, ignoring validity rules and costs.
-- Resolves endpoints as GetPath() does, including adding exact endpoint nodes when required. Missing coordinates or nodes return false.
-- In local grid mode, floods candidate adjacency (including non-grid attachments) and caches complete connected components.
-- False rules out a path in the current graph. True is only a necessary condition: LoS, road rules or infinite costs may still block the route.
-- Outside local grid mode, all node pairs are candidates, so valid endpoint nodes return true without a graph traversal.
-- Does not call neighbour/cost callbacks or DCS visibility/road queries; newly added endpoints still sample their surface types.
-- @param #ASTAR self
-- @return #boolean Whether a path is possible before applying neighbour rules and travel costs.
-- @return #string Failure reason: missing_coordinates, no_start_node, no_goal_node, start_unattached, goal_unattached or disconnected_grid; nil on success.
function ASTAR:HasPotentialPath()
  local start, goal, reason=self:_ResolveEndpoints()
  if reason then return false, reason end
  return self:_HasPotentialPath(start, goal)
end

--- Search a rectangular or hex-only grid and expand it as needed using SetGridOptions().Expansion and the shared MaxNodes budget.
-- Stops at the first actual path or a configured limit. Fits a smaller growth step if the full step exceeds the budget.
-- Runs synchronously and never draws. Call DrawGridWithPath(path) or UpdateGridDrawing() explicitly afterwards.
-- @param #ASTAR self
-- @param #boolean ExcludeStartNode (Optional) Exclude the selected start node from the returned path.
-- @param #boolean ExcludeEndNode (Optional) Exclude the selected goal node from the returned path.
-- @return #table Ordered path nodes, or nil on failure. An empty table is a successful path.
-- @return #table Report with Attempts, StopReason, Width, Margin, Nodes, CandidateNodes, MaxNodes, MaxWidth, MaxMargin, BudgetLimited and SearchCPUSeconds.
-- Attempts contain Width, Margin, Nodes, Failure and CPUSeconds. StopReason is path_found, attempt_limit, size_limit, node_limit or missing_coordinates.
function ASTAR:GetPathWithExpansion(ExcludeStartNode, ExcludeEndNode, ...)
  assert(select("#",...)==0, "ASTAR: GetPathWithExpansion accepts only two endpoint exclusion flags")
  assert(ExcludeStartNode==nil or type(ExcludeStartNode)=="boolean", "ASTAR: configure Expansion in SetGridOptions; search arguments are endpoint exclusion flags")
  assert(ExcludeEndNode==nil or type(ExcludeEndNode)=="boolean", "ASTAR: endpoint exclusion flags must be booleans")
  assert(self.hexGrid or self.rectGrid, "ASTAR: create a rectangular or hex grid before expanding search")
  assert(not self.hexGrid or self.GridNeighboursOnly, "ASTAR: call SetGridNeighboursOnly(true) before expanding a hex grid")
  local options=self:GetGridOptions()
  local grid=self.hexGrid or self.rectGrid
  local factor=options.Expansion.GrowthFactor
  local maxAttempts=options.Expansion.MaxAttempts
  local maxNodes=options.MaxNodes
  local maxWidth=options.Expansion.MaxWidth
  local maxMargin=options.Expansion.MaxMargin
  assert(maxWidth>=grid.boxHY, "ASTAR: MaxWidth must be at least the current width")
  assert(maxMargin>=grid.spaceX, "ASTAR: MaxMargin must be at least the current margin")

  self.LastPathFailure=nil
  local searchClock=startCPUClock()
  local report={Attempts={},BudgetLimited=false}
  local function finish(path, reason)
    report.StopReason=reason
    report.Width=grid.boxHY
    report.Margin=grid.spaceX
    report.Nodes=self.Nnodes
    report.CandidateNodes=grid.candidateCount
    report.MaxNodes=maxNodes
    report.MaxWidth=maxWidth
    report.MaxMargin=maxMargin
    report.SearchCPUSeconds=elapsedCPU(searchClock)
    self.LastExpansionResult=report
    self:T(self.lid..string.format("Expanding search finished: %s after %d attempts, width %.0f m, margin %.0f m, %d nodes, search %s",
      reason, #report.Attempts, grid.boxHY, grid.spaceX, self.Nnodes, cpuTimeText(report.SearchCPUSeconds)))
    if not path then self:_ReportPathFailure(self.LastPathFailure or reason, reason) end
    return path, report
  end

  if grid.candidateCount>maxNodes then return finish(nil, "node_limit") end
  for attempt=1,maxAttempts do
    self:T(self.lid..string.format("Expanding search attempt %d/%d: width %.0f m, margin %.0f m, %d nodes",
      attempt, maxAttempts, grid.boxHY, grid.spaceX, self.Nnodes))
    self.LastPathFailure=nil
    local path, failure=self:_SearchPath(ExcludeStartNode, ExcludeEndNode)
    self.LastPathFailure=failure
    if failure then self:T(self.lid.."Search attempt failed: "..failure) end
    report.Attempts[#report.Attempts+1]={Width=grid.boxHY, Margin=grid.spaceX, Nodes=self.Nnodes, Failure=self.LastPathFailure, CPUSeconds=self.LastSearchTiming.CPUSeconds}
    if path then return finish(path, "path_found") end
    if self.LastPathFailure=="missing_coordinates" then return finish(nil, "missing_coordinates") end
    if attempt==maxAttempts then return finish(nil, "attempt_limit") end

    local width=math.min(maxWidth, math.max(grid.boxHY*factor, grid.boxHY+2*(grid.crossSpacing or grid.spacing)))
    local margin=math.min(maxMargin, math.max(grid.spaceX*factor, grid.spaceX+grid.spacing))
    if width==grid.boxHY and margin==grid.spaceX then return finish(nil, "size_limit") end
    local bounds=expansionBounds(self,width,margin,maxNodes)
    local limited=false
    if not bounds then
      width,margin,bounds=self:_FitGridExpansion(width,margin,maxNodes)
      if not bounds then return finish(nil,"node_limit") end
      limited=true
    end
    if limited then
      self:T(self.lid..string.format("Fitted expansion to MaxNodes=%d: width %.1f m, margin %.1f m, %d candidate cells",maxNodes,width,margin,bounds.count))
    end
    self:_PopulateGrid(bounds,width,margin)
    report.BudgetLimited=report.BudgetLimited or limited
  end
end

--- Search synchronously for a least-cost path between the selected start and goal nodes.
-- Returns nodes in travel order; use GetNodeCoordinate(node) to obtain COORDINATE objects for waypoints.
-- Does not assign a route to a unit or group.
-- Endpoint exclusions can produce an empty table for a successful search. Nil indicates failure.
-- In local grid mode, rejects disconnected candidate components before evaluating any neighbour rule or cost.
-- @param #ASTAR self
-- @param #boolean ExcludeStartNode If *true*, do not include start node in found path. Default is to include it.
-- @param #boolean ExcludeEndNode If *true*, do not include end node in found path. Default is to include it.
-- @return #table Ordered list of ASTAR.Node entries (possibly empty), or nil for missing coordinates, missing endpoint nodes, or an unreachable goal.
function ASTAR:GetPath(ExcludeStartNode, ExcludeEndNode)
  self.LastPathFailure=nil
  local path, reason=self:_SearchPath(ExcludeStartNode, ExcludeEndNode)
  self.LastPathFailure=reason
  if not path then self:_ReportPathFailure(reason) end
  return path
end

--- Run one search without announcing failure; the caller decides whether to retry.
-- @param #ASTAR self
-- @param #boolean ExcludeStartNode Exclude the first node.
-- @param #boolean ExcludeEndNode Exclude the goal node.
-- @return #table Path, including an empty successful path, or nil.
-- @return #string Failure reason, or nil on success.
function ASTAR:_SearchPath(ExcludeStartNode, ExcludeEndNode)
  local clock=startCPUClock()
  local function finish(path, reason)
    local seconds=elapsedCPU(clock)
    self.LastSearchTiming={CPUSeconds=seconds, Failure=reason, Nodes=self.Nnodes}
    local text=path and string.format("Found path with %d nodes (%d total)", #path, self.Nnodes)
      or ("Search attempt ended: "..reason)
    text=text..", "..cpuTimeText(seconds)
    text=text..string.format(", Nvalid=%d [%d cached], Ncost=%d [%d cached]", self.nvalid, self.nvalidcache, self.ncost, self.ncostcache)
    self:T(self.lid..text)
    return path, reason
  end
  local start, goal, reason=self:_ResolveEndpoints()
  if reason then return finish(nil, reason) end
  local potential, failure=self:_HasPotentialPath(start, goal)
  if not potential then return finish(nil, failure) end
  local nodes=self.nodes

  -- Sets.
  local openset   = {}
  local closedset = {}
  local came_from = {}
  local g_score   = {}
  local f_score   = {}
  
  openset[start.id]=true
  local Nopen=1
  
  -- Initial scores.
  g_score[start.id]=0
  f_score[start.id]=g_score[start.id]+self:_HeuristicCost(start, goal)
  
  -- Debug message.
  local text=string.format("Starting A* pathfinding with %d Nodes", self.Nnodes)
  self:T(self.lid..text)
  

  -- Loop while we still have an open set.
  while Nopen > 0 do
  
    -- Get current node.
    local current=self:_LowestFscore(openset, f_score)

    -- No finite score remains: all remaining connections are unreachable.
    if not current then
      break
    end
    
    -- Check if we are at the end node.
    if current.id==goal.id then
    
      local path=self:_UnwindPath({}, came_from, goal)
      
      if not ExcludeEndNode then
        table.insert(path, goal)
      end
      
      if ExcludeStartNode and #path>0 then
        table.remove(path, 1)
      end
      
      return finish(path)
    end

    -- Move Node from open to closed set.
    openset[current.id]=nil
    Nopen=Nopen-1
    closedset[current.id]=true
    
    -- Get neighbour nodes.
    local neighbors=self:_NeighbourNodes(current, nodes)
    
    -- Loop over neighbours.
    for _,neighbor in pairs(neighbors) do
    
      if self:_NotIn(closedset, neighbor.id) then
      
        local tentative_g_score=g_score[current.id]+self:_TravelCost(current, neighbor)
         
        if tentative_g_score < (g_score[neighbor.id] or ASTAR.INF) then
        
          came_from[neighbor]=current
          
          g_score[neighbor.id]=tentative_g_score
          f_score[neighbor.id]=g_score[neighbor.id]+self:_HeuristicCost(neighbor, goal)
          
          if self:_NotIn(openset, neighbor.id) then
            -- Add to open set.
            openset[neighbor.id]=true
            Nopen=Nopen+1
          end
          
        end
      end
    end
  end

  return finish(nil, "connections_blocked")
end

--- Announce a final search failure, optionally with an expansion stop reason.
-- @param #ASTAR self
-- @param #string Reason Search failure or expansion limit.
-- @param #string StopReason Optional expansion stop reason.
function ASTAR:_ReportPathFailure(Reason, StopReason)
  local explanations={missing_coordinates="start and end coordinates are required",
    no_start_node="could not find a valid start node", no_goal_node="could not find a valid goal node",
    start_unattached="start has no hex attachment within one grid spacing",
    goal_unattached="goal has no hex attachment within one grid spacing",
    disconnected_grid="start and goal belong to disconnected grid components",
    connections_blocked="no route satisfies the connection rules and travel costs",
    node_limit="the grid exceeds the candidate-cell limit"}
  local text="Could NOT find valid path: "..(explanations[Reason] or Reason).." ["..Reason.."]"
  if StopReason then text=text.." (expansion stopped: "..StopReason..")" end
  self:E(self.lid..text)
  MESSAGE:New(text, 60, "ASTAR"):ToAllIf(self.Debug)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- A* pathfinding helper functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Check connectivity of already resolved nodes, without evaluating validity rules or costs.
-- A component is fully labelled once so subsequent endpoint checks can reuse it without another flood fill.
-- @param #ASTAR self
-- @param #ASTAR.Node start Start node, or nil.
-- @param #ASTAR.Node goal Goal node, or nil.
-- @return #boolean Whether the candidate graph connects the nodes.
function ASTAR:_HasPotentialPath(start, goal)

  if not start then return false, "no_start_node" end
  if not goal then return false, "no_goal_node" end
  if not self.GridNeighboursOnly or start.id==goal.id then return true end
  if not self.gridLinks then self:_BuildGridLinks() end

  if not (start.q~=nil or start.rectGrid==self.rectGrid and start.i~=nil) and next(self.gridLinks[start.id] or {})==nil then return false, "start_unattached" end
  if not (goal.q~=nil or goal.rectGrid==self.rectGrid and goal.i~=nil) and next(self.gridLinks[goal.id] or {})==nil then return false, "goal_unattached" end

  local components=self.gridComponents
  local component=components[start.id]
  if not component then
    component=start.id
    local queue={start.id}
    local head=1
    components[start.id]=component
    while head<=#queue do
      local nid=queue[head]
      head=head+1
      for neighborID in pairs(self.gridLinks[nid] or {}) do
        if not components[neighborID] then
          components[neighborID]=component
          queue[#queue+1]=neighborID
        end
      end
    end
  end

  if components[goal.id]==component then return true end
  return false, "disconnected_grid"
end

--- Lower bound on the remaining travel cost. Custom and road costs use zero.
-- @param #ASTAR self
-- @param #ASTAR.Node nodeA Node A.
-- @param #ASTAR.Node nodeB Node B.
-- @return #number Estimated remaining cost.
function ASTAR:_HeuristicCost(nodeA, nodeB)

  if not self.CostFunc or self.CostFunc==ASTAR.Dist2D then
    return ASTAR.Dist2D(nodeA, nodeB)
  elseif self.CostFunc==ASTAR.Dist3D then
    return ASTAR.Dist3D(nodeA, nodeB)
  end

  return 0
end

--- Cached travel cost from node A to node B. Defaults to their 2D distance.
-- @param #ASTAR self
-- @param #ASTAR.Node nodeA Node A.
-- @param #ASTAR.Node nodeB Node B.
-- @return #number Travel cost.
function ASTAR:_TravelCost(nodeA, nodeB)
  
  -- Counter.
  self.ncost=self.ncost+1

  -- Get chached cost if available.
  local cost=nodeA.cost[nodeB.id]
  if cost~=nil then
    self.ncostcache=self.ncostcache+1
    return cost
  end

  local cost=nil
  if self.CostFunc then
    cost=self.CostFunc(nodeA, nodeB, unpack(self.CostArg, 1, self.CostArg.n))
  else
    cost=self:_DistNodes(nodeA, nodeB)
  end
  
  nodeA.cost[nodeB.id]=cost
  nodeB.cost[nodeA.id]=cost  -- Symmetric problem. 
  
  return cost
end

--- Check if going from a node to a neighbour is possible.
-- @param #ASTAR self
-- @param #ASTAR.Node node A node.
-- @param #ASTAR.Node neighbor Neighbour node.
-- @return #boolean If true, transition between nodes is possible.
function ASTAR:_IsValidNeighbour(node, neighbor)

  -- Counter.
  self.nvalid=self.nvalid+1
  
  local valid=node.valid[neighbor.id]
  if valid~=nil then
    --env.info(string.format("Node %d has valid=%s neighbour %d", node.id, tostring(valid), neighbor.id))
    self.nvalidcache=self.nvalidcache+1
    return valid
  end

  local valid=nil
  if self.ValidNeighbourFunc then
    valid=self.ValidNeighbourFunc(node, neighbor, unpack(self.ValidNeighbourArg, 1, self.ValidNeighbourArg.n))
  else
    valid=true
  end

  node.valid[neighbor.id]=valid
  neighbor.valid[node.id]=valid  -- Symmetric problem. 

  return valid
end

--- Calculate 2D distance between two nodes.
-- @param #ASTAR self
-- @param #ASTAR.Node nodeA Node A.
-- @param #ASTAR.Node nodeB Node B.
-- @return #number Distance between nodes in meters.
function ASTAR:_DistNodes(nodeA, nodeB)
  return nodeA.vector:GetDistance(nodeB.vector, true)
end

--- Function that calculates the lowest F score.
-- @param #ASTAR self
-- @param #table set The set of nodes IDs.
-- @param #table f_score Scores indexed by node id.
-- @return #ASTAR.Node Node with the lowest finite score, or nil if none exists.
function ASTAR:_LowestFscore(set, f_score)

  local lowest, bestNode = ASTAR.INF, nil
  
  for nid,node in pairs(set) do
  
    local score=f_score[nid]
    
    if score<lowest then
      lowest, bestNode = score, nid
    end
  end
  
  return self.nodes[bestNode]
end

--- Function to get valid neighbours of a node.
-- @param #ASTAR self
-- @param #ASTAR.Node theNode The node whose neighbours are requested.
-- @param #table nodes Possible neighbours.
-- @return #table List of valid neighbour nodes, excluding the input node.
function ASTAR:_NeighbourNodes(theNode, nodes)

  local neighbors = {}

  if self.GridNeighboursOnly then
    if not self.gridLinks then self:_BuildGridLinks() end
    for nid in pairs(self.gridLinks[theNode.id] or {}) do
      local node=nodes[nid]
      if node and self:_IsValidNeighbour(theNode, node) then
        table.insert(neighbors, node)
      end
    end
    return neighbors
  end
  
  for _,node in pairs(nodes) do
  
    if theNode.id~=node.id then
    
      local isvalid=self:_IsValidNeighbour(theNode, node)
    
      if isvalid then
        table.insert(neighbors, node)
      end
      
    end
    
  end
  
  return neighbors
end

-- Build geometry-specific candidate adjacency. Rule and cost caches remain independent of topology.
function ASTAR:_BuildGridLinks()
  if self.hexGrid then return self:_BuildHexLinks() end
  return self:_BuildRectLinks()
end

--- Build sparse rectangular adjacency using stable i/j indices, including local endpoint attachments.
-- @param #ASTAR self
-- @return #ASTAR self
function ASTAR:_BuildRectLinks()
  local grid=self.rectGrid
  local diagonal=self:GetGridOptions().Diagonals
  local links={}
  for id in pairs(self.nodes) do links[id]={} end
  local function cell(i,j)
    local row=self.rectIndex[i]
    return row and row[j]
  end
  for id,node in pairs(self.nodes) do
    if node.rectGrid==grid and node.i~=nil and node.j~=nil then
      for di=-1,1 do
        for dj=-1,1 do
          local cardinal=math.abs(di)+math.abs(dj)==1
          local corner=di~=0 and dj~=0
          if cardinal or (corner and diagonal and cell(node.i+di,node.j) and cell(node.i,node.j+dj)) then
            local neighbor=cell(node.i+di,node.j+dj)
            if neighbor then links[id][neighbor.id]=true end
          end
        end
      end
    else
      local dx,dz=node.vector.x-grid.x,node.vector.z-grid.z
      local along=(dx*grid.cos+dz*grid.sin-grid.alongOffset)/grid.spacing
      local across=(-dx*grid.sin+dz*grid.cos-grid.acrossOffset)/grid.crossSpacing
      local epsilon=1e-9
      for i=math.ceil(across-1-epsilon),math.floor(across+1+epsilon) do
        for j=math.ceil(along-1-epsilon),math.floor(along+1+epsilon) do
          local neighbor=cell(i,j)
          local di,dj=math.abs(i-across),math.abs(j-along)
          if neighbor and (diagonal or di+dj<=1+epsilon) then
            links[id][neighbor.id]=true
            links[neighbor.id][id]=true
          end
        end
      end
    end
  end
  self.gridLinks=links self.gridComponents={}
  return self
end

--- Build sparse hex candidate adjacency, without evaluating neighbour rules or travel costs.
-- Grid nodes connect to their six indexed adjacent cells. Other nodes attach to nearby grid centers within one spacing.
-- Inverse axial bounds keep each attachment lookup local, including outside the grid or beside filtered cells.
-- @param #ASTAR self
-- @return #ASTAR self
function ASTAR:_BuildHexLinks()

  local links={}
  for nid in pairs(self.nodes) do links[nid]={} end
  local grid=self.hexGrid
  local epsilon=1e-9

  for nid,node in pairs(self.nodes) do
    if node.q~=nil and node.r~=nil then
      for _,direction in ipairs(hexDirections) do
        local column=self.hexIndex[node.q+direction[1]]
        local neighbor=column and column[node.r+direction[2]]
        if neighbor then links[nid][neighbor.id]=true end
      end
    else
      local dx=node.vector.x-grid.x
      local dz=node.vector.z-grid.z
      local along=(dx*grid.cos+dz*grid.sin)/grid.spacing
      local across=(-dx*grid.sin+dz*grid.cos)/grid.spacing
      local rowScale=math.sqrt(3)/2
      for r=math.ceil((across-1)/rowScale-epsilon),math.floor((across+1)/rowScale+epsilon) do
        for q=math.ceil(along-1-r/2-epsilon),math.floor(along+1-r/2+epsilon) do
          local column=self.hexIndex[q]
          local neighbor=column and column[r]
          local dl=q+r/2-along
          local dt=r*rowScale-across
          if neighbor and dl*dl+dt*dt<=1+epsilon then
            links[nid][neighbor.id]=true
            links[neighbor.id][nid]=true
          end
        end
      end
    end
  end

  self.gridLinks=links
  self.gridComponents={}
  return self
end

--- Function to check if a node is not in a set.
-- @param #ASTAR self
-- @param #table set Set of nodes.
-- @param #number theNode Node id to check.
-- @return #boolean If true, the node is not in the set.
function ASTAR:_NotIn(set, theNode)
  return set[theNode]==nil
end

--- Reconstruct the predecessor chain in linear time, excluding the current node itself.
-- Prepends the ordered predecessors to flat_path, retaining its existing entries and table identity.
-- @param #ASTAR self
-- @param #table flat_path Flat path.
-- @param #table map Map.
-- @param #ASTAR.Node current_node The current node.
-- @return #table Ordered predecessor nodes.
function ASTAR:_UnwindPath(flat_path, map, current_node)
  local reverse={}
  local previous=map[current_node]
  while previous do
    reverse[#reverse+1]=previous
    previous=map[previous]
  end
  -- Preserve the existing suffix and table identity without repeatedly inserting at the front.
  local count=#reverse
  for i=#flat_path,1,-1 do flat_path[i+count]=flat_path[i] end
  for i=1,count do flat_path[i]=reverse[count-i+1] end
  return flat_path
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
