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
-- @field #table nodes Per-search nodes, including independent connection and cost caches.
-- @field Core.Grid#GRID Grid Owned or shared spatial grid.
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
-- @field #boolean GridNeighboursOnly Restrict candidates to direct grid edges and local endpoint attachments. Enabled automatically when a grid is built or attached.
-- @field #table hexGrid Hex geometry: origin x/z, heading cos/sin, spacing, rowSpacing, original distance, boxHY, spaceX, candidateCount and temporary initialSamples for zone seeds.
-- @field #table hexIndex Hex nodes indexed by axial q, then r.
-- @field #table rectIndex Rectangular nodes indexed by i, then j.
-- @field #table gridLinks Cached candidate adjacency, indexed by node id, then neighbour id. Does not cache rule results.
-- @field #table gridComponents Connected-component labels for grid candidates. Rebuilt when candidate adjacency changes.
-- @field #table GridDrawIDs F10 polygon ids owned by DrawGrid(), removed by UndrawGrid().
-- @field #table GridDrawOptions Last DrawGrid() style and batch settings, retained for incremental updates.
-- @field #table GridDrawCellIDs Drawn polygon ids indexed by grid node id.
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
--       Width = 40000, Margin = 10000, Spacing = 2000, MaxCells = 5000,
--       Expansion = {GrowthFactor = 1.5, MaxAttempts = 5}
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
-- # Shared GRID
--
-- Grid builders, topology, expansion and rendering are implemented by Core.Grid. The methods below remain forwarding conveniences.
-- Standalone grids select geometry with GRID:New(Name, GridType), then use SetOptions(), GetOptions(), CreateFromBounds() and CreateFromZone().
-- Automatic spacing is available through SetGridOptions({Resolution=GRID.Resolution.NORMAL, ...}); omit Spacing and CrossSpacing.
-- Alternatively call GetGrid():SetResolution(Level) before creation. GetGrid():GetResolutionInfo() reports the calculated spacing.
-- GetGrid():SetCorridor(GRID.Width.NORMAL, GRID.Margin.NORMAL) selects relative initial corridor dimensions.
-- The same presets are accepted as Width and Margin in SetGridOptions(); zone builders ignore them.
-- ASTAR keeps SetGridOptions() and CreateGrid()/CreateHexGrid() as convenience methods that supply the search endpoints.
-- Use ExpandGrid() for either geometry; SetGridNeighboursOnly() is the single switch for local search candidates.
-- GetGrid() returns the owned grid, even before construction. SetGrid(grid) attaches a built GRID to an unused ASTAR and enables local neighbours.
-- Before construction the owned grid defaults to rectangle; a hex convenience builder replaces that empty grid, preserving its configuration.
-- Set start/end coordinates on each search separately; they do not change the shared grid frame. A node.cell refers to its immutable grid cell.
-- Expansion/options are shared, but nodes, endpoints, connection/cost caches, component labels and ASTAR overlays are per search object.
-- Public searches and drawing calls synchronize new cells and invalidate topology when the grid version changes. Existing pair caches are retained.
-- Never mutate cell/node vectors or indices directly. Configuration setters and expansion are the supported mutation paths.
-- Calling grid:DrawGridWithPath(path) draws a grid-owned overlay; astar:DrawGridWithPath(path) owns a separate search overlay.
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
-- * MaxCells: positive integer budget shared by initial creation and later enlargement; default 5000. There is no unlimited default.
--
-- After a successful build the geometry and surface filter are locked, even if every cell was filtered out. Use a new ASTAR for another lattice.
-- Diagonals, limits and Expansion settings can still change: get the current options, edit the desired limits, then call SetGridOptions(options).
-- Lowering MaxCells below the existing candidate count does not remove nodes; expanding search returns cell_limit before searching.
--
-- @{#ASTAR.CreateGrid} and @{#ASTAR.CreateHexGrid} take no arguments. Configure first; passing old positional arguments is an error.
-- All builders return self on success or nil, "cell_limit" when the initial budget is exceeded. Rejection occurs before terrain sampling.
-- A successful build allows no second Create call on the same object. Manual nodes may precede rectangular creation; hex creation requires no nodes.
--
-- # Geometry and Zones
--
-- Hex grids use axial q/r indices with the third cube coordinate equal to -q-r. Their origin and orientation follow the original start-to-goal line.
-- Neighbor centers are one Spacing apart; drawn hexagons have circumradius Spacing/sqrt(3). Rectangular cells use Spacing and CrossSpacing as side lengths.
-- Grid centers have altitude zero; the surface filter samples their 2D position. Cell outlines are visual aids, not traversability guarantees.
--
-- @{#ASTAR.CreateGridFromZone}(zone) and @{#ASTAR.CreateHexGridFromZone}(zone) use circular, rectangular or polygonal MOOSE zones.
-- The zone determines the initial area; configured Width and Margin are not used to crop it. Spacing and MaxCells still apply.
-- Center membership is checked with zone:IsVec2InZone() before querying terrain. MaxCells counts candidate centers in the projected bounding rectangle,
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
-- Local mode is the default once a grid is built or attached. SetGridNeighboursOnly(false) explicitly enables all-pairs candidates.
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
-- Expansion.MaxWidth and Expansion.MaxMargin are optional meter limits; omitted values impose no spatial cap on that dimension.
-- Explicit dimension caps must be at least the existing dimensions when searching. They and MaxCells are independent: whichever prevents growth stops it.
-- Width grows by at least two transverse spacings (CrossSpacing for rectangles, Spacing for hex grids); margin grows by at least one Spacing.
-- Dimension caps apply to both increments. Zero initial dimensions can therefore grow.
-- Growth beyond finite numeric dimensions stops with size_limit, even when no explicit dimension caps are set.
-- If the requested step exceeds MaxCells, the search finds a smaller step without terrain sampling, then uses remaining room on either axis.
-- The discrete lattice may leave some budget unused. No cell is sampled beyond MaxCells. A fitted step consumes one normal search attempt.
-- Previously accepted and rejected cells are retained without resampling; the first real enlargement of a zone seed fills unsampled holes as well.
-- Manual ExpandGrid(width,margin) supports both geometries and uses the same budget and dimension caps, but rejects oversized requests instead of fitting them.
-- ExpandGrid(width,margin) remains available specifically for hex grids. Rectangular enlargement preserves original i/j indices, spacing and orientation.
-- Grid builders enable local neighbours by default. Hex expanding searches require this local mode.
--
-- GetPathWithExpansion returns path, report and stores the report in LastExpansionResult:
-- * Attempts: ordered entries with Width, Margin, Nodes, Failure and CPUSeconds.
-- * StopReason: path_found, attempt_limit, size_limit, cell_limit or missing_coordinates.
-- * Width, Margin, Nodes, CandidateCells: final dimensions, accepted node count and budgeted candidate-cell count.
-- * MaxCells, MaxWidth, MaxMargin: effective limits for this search; omitted dimension limits remain nil in the report.
-- * BudgetLimited: true if a smaller growth step was fitted to the cell budget.
-- * SearchCPUSeconds: total search and enlargement CPU time, if a CPU clock is available.
-- Manual nodes and exact endpoints do not consume MaxCells, so accepted Nodes can exceed CandidateCells.
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
-- @field #number id Node id, local to this search.
-- @field Core.Grid#GRID.Cell cell Shared immutable cell, or nil for manual nodes/endpoints.
-- @field Core.Grid#GRID grid Associated spatial grid; also identifies endpoints in grid-owned debug drawings.
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
-- @field #number MaxCells Shared candidate-cell limit before filtering, default 5000. Excludes manual nodes and endpoints.
-- @field #ASTAR.ExpansionOptions Expansion Expansion configuration.

--- Grid search expansion settings.
-- @type ASTAR.ExpansionOptions
-- @field #number GrowthFactor Finite multiplier greater than 1, default 1.5.
-- @field #number MaxAttempts Positive integer search limit including the first attempt, default 5.
-- @field #number MaxWidth Optional maximum width in meters; nil means no width limit.
-- @field #number MaxMargin Optional maximum margin at each end in meters; nil means no margin limit.

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
ASTAR.version="2.0.0"

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
  self.nodes={} self.counter=1 self.Nnodes=0
  self.Grid=GRID:New("ASTAR", GRID.Type.RECTANGLE)
  self._GridRevision=-1 self._CellNodes={} self._CellCursor=0
  self._NodeOwner={}

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
  node._owner=self._NodeOwner
  node.grid=self.Grid
  
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
  assert(Node and Node._owner==self._NodeOwner, "ASTAR: node must belong to this search")
  return Node.vector:GetCoordinate()
end

--- Add a node created by this ASTAR instance to the search node set.
-- Does not apply the grid surface filter. Adding the same node again does not increase the node count.
-- Invalidates grid candidate adjacency. Do not modify node ids, grid indices or coordinates after adding a node.
-- @param #ASTAR self
-- @param #ASTAR.Node Node The node to be added.
-- @return #ASTAR self
function ASTAR:AddNode(Node)

  assert(type(Node)=="table" and Node._owner==self._NodeOwner and Node.grid==self.Grid, "ASTAR: node must be created by this search for its current grid")
  assert(not self.nodes[Node.id] or self.nodes[Node.id]==Node, "ASTAR: existing nodes cannot be replaced")
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
  self:_SyncGrid()
  if Enabled==nil then Enabled=true end
  assert(type(Enabled)=="boolean", "ASTAR: Enabled must be a boolean")
  assert(not Enabled or self.hexGrid or self.rectGrid, "ASTAR: create a grid before enabling grid neighbours")
  self.GridNeighboursOnly=Enabled
  return self
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
  self:_SyncGrid()
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
  self:_SyncGrid()

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
  self:_SyncGrid()
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

--- Search a rectangular or hex-only grid and expand it as needed using SetGridOptions().Expansion and the shared MaxCells budget.
-- Stops at the first actual path or a configured limit. Fits a smaller growth step if the full step exceeds the budget.
-- Runs synchronously and never draws. Call DrawGridWithPath(path) or UpdateGridDrawing() explicitly afterwards.
-- @param #ASTAR self
-- @param #boolean ExcludeStartNode (Optional) Exclude the selected start node from the returned path.
-- @param #boolean ExcludeEndNode (Optional) Exclude the selected goal node from the returned path.
-- @return #table Ordered path nodes, or nil on failure. An empty table is a successful path.
-- @return #table Report with Attempts, StopReason, Width, Margin, Nodes, CandidateCells, MaxCells, MaxWidth, MaxMargin, BudgetLimited and SearchCPUSeconds.
-- Attempts contain Width, Margin, Nodes, Failure and CPUSeconds. StopReason is path_found, attempt_limit, size_limit, cell_limit or missing_coordinates.
-- @param ... Must be empty; additional positional arguments are rejected.
function ASTAR:GetPathWithExpansion(ExcludeStartNode, ExcludeEndNode, ...)
  self:_SyncGrid()
  assert(select("#",...)==0, "ASTAR: GetPathWithExpansion accepts only two endpoint exclusion flags")
  assert(ExcludeStartNode==nil or type(ExcludeStartNode)=="boolean", "ASTAR: configure Expansion in SetGridOptions; search arguments are endpoint exclusion flags")
  assert(ExcludeEndNode==nil or type(ExcludeEndNode)=="boolean", "ASTAR: endpoint exclusion flags must be booleans")
  assert(self.hexGrid or self.rectGrid, "ASTAR: create a rectangular or hex grid before expanding search")
  assert(not self.hexGrid or self.GridNeighboursOnly, "ASTAR: call SetGridNeighboursOnly(true) before expanding a hex grid")
  local options=self:GetGridOptions()
  local grid=self.hexGrid or self.rectGrid
  local factor=options.Expansion.GrowthFactor
  local maxAttempts=options.Expansion.MaxAttempts
  local maxCells=options.MaxCells
  local maxWidth=options.Expansion.MaxWidth
  local maxMargin=options.Expansion.MaxMargin
  assert(maxWidth==nil or maxWidth>=grid.boxHY, "ASTAR: MaxWidth must be at least the current width")
  assert(maxMargin==nil or maxMargin>=grid.spaceX, "ASTAR: MaxMargin must be at least the current margin")

  self.LastPathFailure=nil
  local searchClock=startCPUClock()
  local report={Attempts={},BudgetLimited=false}
  local function finish(path, reason)
    report.StopReason=reason
    report.Width=grid.boxHY
    report.Margin=grid.spaceX
    report.Nodes=self.Nnodes
    report.CandidateCells=grid.candidateCount
    report.MaxCells=maxCells
    report.MaxWidth=maxWidth
    report.MaxMargin=maxMargin
    report.SearchCPUSeconds=elapsedCPU(searchClock)
    self.LastExpansionResult=report
    self:T(self.lid..string.format("Expanding search finished: %s after %d attempts, width %.0f m, margin %.0f m, %d nodes, search %s",
      reason, #report.Attempts, grid.boxHY, grid.spaceX, self.Nnodes, cpuTimeText(report.SearchCPUSeconds)))
    if not path then self:_ReportPathFailure(self.LastPathFailure or reason, reason) end
    return path, report
  end

  if grid.candidateCount>maxCells then return finish(nil, "cell_limit") end
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

    local width=math.max(grid.boxHY*factor, grid.boxHY+2*(grid.crossSpacing or grid.spacing))
    local margin=math.max(grid.spaceX*factor, grid.spaceX+grid.spacing)
    if maxWidth then width=math.min(maxWidth,width) end
    if maxMargin then margin=math.min(maxMargin,margin) end
    if width==math.huge or margin==math.huge then return finish(nil,"size_limit") end
    if width==grid.boxHY and margin==grid.spaceX then return finish(nil, "size_limit") end
    local expanded, stopReason, limited=self.Grid:ExpandGrid(width,margin,true)
    if not expanded then return finish(nil,stopReason) end
    self:_SyncGrid()
    if limited then
      self:T(self.lid..string.format("Fitted expansion to MaxCells=%d: width %.1f m, margin %.1f m, %d candidate cells",maxCells,grid.boxHY,grid.spaceX,grid.candidateCount))
    end
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
-- @return #nil No return value; updates state or emits diagnostics.
function ASTAR:_ReportPathFailure(Reason, StopReason)
  local explanations={missing_coordinates="start and end coordinates are required",
    no_start_node="could not find a valid start node", no_goal_node="could not find a valid goal node",
    start_unattached="start has no attachment to nearby grid cells",
    goal_unattached="goal has no attachment to nearby grid cells",
    disconnected_grid="start and goal belong to disconnected grid components",
    connections_blocked="no route satisfies the connection rules and travel costs",
    cell_limit="the grid exceeds the candidate-cell limit"}
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
-- @return #string Failure reason, or nil when connectivity is possible.
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
  
  assert(type(cost)=="number" and cost>=0, "ASTAR: travel cost must be a non-negative number or math.huge")
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

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- GRID integration. Search nodes and drawing jobs belong to this ASTAR view, never to shared cells.
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Attach an existing built grid to an unused search object. Local grid neighbours are enabled.
-- Sharing a grid shares expansion and options; validity/cost caches, endpoints and ASTAR overlays remain independent.
-- @param #ASTAR self
-- @param Core.Grid#GRID Grid Built grid.
-- @return #ASTAR self.
function ASTAR:SetGrid(Grid)
  assert(Grid and Grid.ClassName=="GRID" and Grid.GridBuilt,"ASTAR: SetGrid requires a built GRID")
  assert(not self.GridBuilt and next(self.nodes)==nil,"ASTAR: attach a grid to an unused ASTAR object")
  self.Grid=Grid self._GridRevision=-1 self._CellCursor=0 self._CellNodes={}
  self.GridNeighboursOnly=true
  self:_SyncGrid()
  return self
end

--- Get the owned or shared GRID, including before initial construction.
-- @param #ASTAR self
-- @return Core.Grid#GRID Grid.
function ASTAR:GetGrid()
  return self.Grid
end

--- Import new shared cells without terrain queries or changing existing nodes and caches.
-- @param #ASTAR self
-- @return #nil No return value.
function ASTAR:_SyncGrid()
  local grid=self.Grid
  if not grid or self._GridRevision==grid.Version then return end
  self.hexGrid=grid.hexGrid self.rectGrid=grid.rectGrid
  self.GridOptions=grid.GridOptions self.ValidSurfaceTypes=grid.ValidSurfaceTypes
  self.GridBuilt=grid.GridBuilt self.GridCandidateCount=grid.GridCandidateCount
  if grid.GridBuilt and self.GridNeighboursOnly==nil then self.GridNeighboursOnly=true end
  if grid.hexGrid then self.hexIndex=self.hexIndex or {} end
  if grid.rectGrid then self.rectIndex=self.rectIndex or {} end
  for i=self._CellCursor+1,#grid.CellList do
    local cell=grid.CellList[i]
    local node={id=self.counter,vector=cell.vector,surfacetype=cell.surfacetype,
      q=cell.q,r=cell.r,i=cell.i,j=cell.j,rectGrid=cell.rectGrid,cell=cell,grid=grid,_owner=self._NodeOwner,valid={},cost={}}
    self.counter=self.counter+1
    self:AddNode(node)
    self._CellNodes[cell.id]=node
  end
  self._CellCursor=#grid.CellList self._GridRevision=grid.Version
  self.gridLinks=nil self.gridComponents=nil
end

--- Configure the grid surface filter before creation. See GRID:SetValidSurfaceTypes().
-- @param #ASTAR self
-- @param #table SurfaceTypes Allowed surface types, a single type, or nil for all.
-- @return #ASTAR self.
function ASTAR:SetValidSurfaceTypes(SurfaceTypes)
  self.Grid:SetValidSurfaceTypes(SurfaceTypes)
  self:_SyncGrid()
  return self
end

--- Configure geometry, diagonals and expansion limits on the owned/shared grid.
-- @param #ASTAR self
-- @param Core.Grid#GRID.GridOptions Options Grid configuration.
-- @return #ASTAR self.
function ASTAR:SetGridOptions(Options)
  self.Grid:SetOptions(Options)
  self:_SyncGrid()
  return self
end

--- Return a copy of the current grid configuration.
-- @param #ASTAR self
-- @return #table Options.
function ASTAR:GetGridOptions()
  self:_SyncGrid()
  return self.Grid:GetOptions()
end

--- Build the owned grid using search endpoints or zone-derived bounds.
-- @param #ASTAR self
-- @param #string Kind Convenience builder name.
-- @param Core.Zone#ZONE_BASE Zone (Optional) Initial circle, rectangle or polygon zone.
-- @return #ASTAR self, or nil when the cell budget is exceeded.
-- @return #string cell_limit on budget rejection; nil on success.
function ASTAR:_CreateGrid(Kind, Zone)
  assert(not self.Grid.GridBuilt,"ASTAR: a grid already exists; use a new grid")
  local hex=Kind=="CreateHexGrid" or Kind=="CreateHexGridFromZone"
  if hex then
    assert(next(self.nodes)==nil,"ASTAR: create a hex grid on an empty ASTAR object")
  end
  local grid=self.Grid
  local gridType=hex and GRID.Type.HEXAGON or GRID.Type.RECTANGLE
  if grid:GetType()~=gridType then
    assert(next(self.nodes)==nil,"ASTAR: select grid geometry before adding manual nodes")
    -- Copy configured options without turning resolved defaults into explicit settings.
    grid=GRID:New(grid:GetName(),gridType):SetOptions(grid.GridOptions)
    grid:SetValidSurfaceTypes(self.Grid.ValidSurfaceTypes)
    if self.Grid.startVector and self.Grid.endVector then
      grid:SetBounds(self.Grid.startVector,self.Grid.endVector)
    end
  end
  local built,reason
  if Zone~=nil or Kind=="CreateGridFromZone" or Kind=="CreateHexGridFromZone" then
    if self.startVector or self.endVector then grid:SetBounds(self.startVector,self.endVector) end
    built,reason=grid:CreateFromZone(Zone)
  else built,reason=grid:CreateFromBounds(self.startVector,self.endVector) end
  if built and grid~=self.Grid then
    self.Grid=grid
    self._GridRevision=-1
  end
  self:_SyncGrid()
  if not built then return nil,reason end
  return self
end

--- Build a rectangular grid using SetGridOptions() and SetValidSurfaceTypes().
-- Requires both endpoints and no prior grid. Retains manually added nodes and enables local topology by default. Centers have altitude zero.
-- No markers are created; call DrawGrid() or MarkGrid() explicitly.
-- @param #ASTAR self
-- @return #ASTAR self, or nil if MaxCells would be exceeded before surface filtering.
-- @return #string cell_limit on budget rejection; no nodes are added on rejection.
-- @param ... Must be empty; additional positional arguments are rejected.
function ASTAR:CreateGrid(...)
  assert(select("#",...)==0,"ASTAR: configure grid options before creation")
  return self:_CreateGrid("CreateGrid")
end

--- Build an initial hex grid using SetGridOptions() and SetValidSurfaceTypes().
-- Requires both endpoints and an empty node set. CrossSpacing is not supported. Centers have altitude zero.
-- Enables six-neighbour topology by default. No drawing is performed.
-- @param #ASTAR self
-- @return #ASTAR self, or nil if MaxCells would be exceeded before surface filtering.
-- @return #string cell_limit on budget rejection; no nodes are added on rejection.
-- @param ... Must be empty; additional positional arguments are rejected.
function ASTAR:CreateHexGrid(...)
  assert(select("#",...)==0,"ASTAR: configure grid options before creation")
  return self:_CreateGrid("CreateHexGrid")
end

--- Build rectangular centers inside a MOOSE circle, rectangle or polygon zone.
-- Requires no prior grid; endpoints optionally supply the orientation. Retains manual nodes. Uses configured spacing, MaxCells and surface types; ignores Width and Margin.
-- Checks the zone before terrain sampling. Expansion can subsequently leave the zone. No drawing is performed.
-- @param #ASTAR self
-- @param Core.Zone#ZONE_BASE Zone Initial zone.
-- @return #ASTAR self, or nil if the projected bounding-box candidates exceed MaxCells before either filter.
-- @return #string cell_limit on budget rejection.
-- @param ... Must be empty; additional positional arguments are rejected.
function ASTAR:CreateGridFromZone(Zone, ...)
  assert(select("#",...)==0,"ASTAR: configure grid options before creation")
  return self:_CreateGrid("CreateGridFromZone",Zone)
end

--- Build initial hex centers inside a MOOSE circle, rectangle or polygon zone.
-- Requires an empty node set; endpoints optionally supply the orientation. Uses configured Spacing, MaxCells and surface types; ignores Width and Margin.
-- Checks the zone before terrain sampling. Expansion can subsequently leave the zone. CrossSpacing is rejected.
-- @param #ASTAR self
-- @param Core.Zone#ZONE_BASE Zone Initial zone.
-- @return #ASTAR self, or nil if the projected bounding-box candidates exceed MaxCells before either filter.
-- @return #string cell_limit on budget rejection.
-- @param ... Must be empty; additional positional arguments are rejected.
function ASTAR:CreateHexGridFromZone(Zone, ...)
  assert(select("#",...)==0,"ASTAR: configure grid options before creation")
  return self:_CreateGrid("CreateHexGridFromZone",Zone)
end

--- Enlarge a rectangular or hex grid without replacing nodes, caches, spacing, origin or orientation.
-- Uses configured MaxCells, Expansion.MaxWidth and Expansion.MaxMargin. Does not draw; fitting to the cell budget is optional.
-- Previously sampled cells are retained; the first actual enlargement of a zone seed fills unsampled holes.
-- @param #ASTAR self
-- @param #number Width New total width, at least the current width.
-- @param #number Margin New margin at each end, at least the current margin.
-- @param #boolean FitBudget (Optional) Fit a smaller step when MaxCells is exceeded; default false.
-- @return #ASTAR self, or nil if a configured limit would be exceeded.
-- @return #string cell_limit or size_limit on rejection.
-- @return #boolean True if a successful step was reduced to fit MaxCells.
function ASTAR:ExpandGrid(Width, Margin, FitBudget)
  local grid,reason,limited=self.Grid:ExpandGrid(Width,Margin,FitBudget)
  self:_SyncGrid()
  if not grid then return nil,reason,limited end
  return self,nil,limited
end


--- Mark current nodes with separate F10 text labels. Replaces previous text labels only; does not draw polygons.
-- Snapshot of the current node list. Counts are evaluated when each batch runs; later additions are not marked automatically.
-- Candidate counts are cheap. CheckNeighbours evaluates the neighbour rule and can be expensive, especially without local grid mode.
-- Work is batched; one node's connection checks cannot be interrupted. Without a CPU clock only one marker is processed per batch.
-- @param #ASTAR self
-- @param #ASTAR.MarkGridOptions Options (Optional) Label fields, recipient and batch settings.
-- @return #ASTAR self. LastGridMarkResult contains Status, NodesQueued, NodesMarked, Batches and timing.
function ASTAR:MarkGrid(Options)
  self:_SyncGrid()
  return GRID.MarkGrid(self, Options)
end

--- Cancel pending node labels and remove this object's text markers. Leaves grid polygons intact.
-- @param #ASTAR self
-- @return #ASTAR self
function ASTAR:UnmarkGrid()
  self:_SyncGrid()
  return GRID.UnmarkGrid(self)
end

--- Process one batch of node text labels.
-- @param #ASTAR self
-- @param #table Job Marker job.
-- @return #boolean True when another batch is required; false when finished, failed or cancelled.
function ASTAR:_ProcessGridMarkJob(Job)
  self:_SyncGrid()
  return GRID._ProcessGridMarkJob(self, Job)
end

--- Finish, fail or cancel a marker job.
-- @param #ASTAR self
-- @param #table Job Marker job.
-- @param #string Status Completion status.
-- @param #string Error Optional error detail.
-- @return #nil No return value; updates state or emits diagnostics.
function ASTAR:_FinishGridMarking(Job, Status, Error)
  self:_SyncGrid()
  return GRID._FinishGridMarking(self, Job, Status, Error)
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
  self:_SyncGrid()
  return GRID.DrawGrid(self, Coalition, Color, Alpha, FillColor, FillAlpha, LineType, ReadOnly, DrawOptions)
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
  self:_SyncGrid()
  return GRID.DrawGridWithPath(self, Path, Options)
end

--- Validate batch settings and replace the overlay before starting a regular drawing or debug snapshot.
-- @param #ASTAR self
-- @param #table Style Owned style table.
-- @param #table DrawOptions Optional batch settings.
-- @return #ASTAR self
function ASTAR:_StartGridDrawing(Style, DrawOptions)
  self:_SyncGrid()
  return GRID._StartGridDrawing(self, Style, DrawOptions)
end

--- Add missing cell polygons to the current overlay, retaining its style and existing marks.
-- Also extends a pending drawing job without duplicating queued cells. Does nothing before DrawGrid() or for an already queued debug snapshot.
-- @param #ASTAR self
-- @return #ASTAR self
function ASTAR:UpdateGridDrawing()
  self:_SyncGrid()
  return GRID.UpdateGridDrawing(self)
end

--- Draw one batch, bounded by cell count and a CPU budget checked after each cell. Without a CPU clock draw at most one cell.
-- @param #ASTAR self
-- @param #table Job Current drawing job.
-- @return #boolean Whether the job needs another batch.
function ASTAR:_ProcessGridDrawJob(Job)
  self:_SyncGrid()
  return GRID._ProcessGridDrawJob(self, Job)
end

--- Complete or cancel a drawing job, retaining its result for callers.
-- @param #ASTAR self
-- @param #table Job Current drawing job.
-- @param #string Status complete, cancelled or error.
-- @param #string Error Optional error message.
-- @return #nil No return value; updates state or emits diagnostics.
function ASTAR:_FinishGridDrawing(Job, Status, Error)
  self:_SyncGrid()
  return GRID._FinishGridDrawing(self, Job, Status, Error)
end

--- Draw one generated grid cell using the saved style; manual endpoints have no polygon.
-- @param #ASTAR self
-- @param #ASTAR.Node Node Grid node.
-- @param #table Style Drawing options.
-- @return #number Mark id, or nil for a node without a cell.
function ASTAR:_DrawGridCell(Node, Style)
  self:_SyncGrid()
  return GRID._DrawGridCell(self, Node, Style)
end

--- Cancel pending drawing and remove polygons created by DrawGrid() without changing the grid or deleting other F10 marks.
-- Removal is synchronous. Safe to call repeatedly or before drawing. Does not remove MarkGrid text markers.
-- @param #ASTAR self
-- @return #ASTAR self
function ASTAR:UndrawGrid()
  self:_SyncGrid()
  return GRID.UndrawGrid(self)
end


--- Transform drawing offsets through the associated grid geometry.
-- @param #ASTAR self
-- @param #table grid Geometry with orientation and a default origin.
-- @param #number along Longitudinal offset in meters.
-- @param #number across Transverse offset in meters.
-- @param #table origin (Optional) Alternative origin with x and z fields.
-- @return #number World x coordinate.
-- @return #number World z coordinate.
function ASTAR:_GridPosition(grid, along, across, origin)
  return self.Grid:_GridPosition(grid, along, across, origin)
end

--- Get the search-node table for shared grid rendering.
-- @param #ASTAR self
-- @return #table Search nodes indexed by node ID; internal mutable reference.
function ASTAR:_GetGridCells()
  return self.nodes
end

--- Count search-node neighbours for the shared marker renderer.
-- @param #ASTAR self
-- @param #ASTAR.Node Node Owned search node.
-- @param #boolean CheckValid (Optional) Evaluate the neighbour rule; default false.
-- @return #number Neighbour count.
function ASTAR:_GetGridNeighbourCount(Node, CheckValid)
  return self:GetNodeNeighbourCount(Node, CheckValid)
end

--- Get the search-node result field used by the shared renderer.
-- @param #ASTAR self
-- @param #string Suffix Counter suffix: Queued, Drawn or Marked.
-- @return #string Node counter field name.
function ASTAR:_GridResultField(Suffix)
  return "Nodes"..Suffix
end

--- Get the label prefix used for search-node text markers.
-- @param #ASTAR self
-- @return #string Node label prefix.
function ASTAR:_GridElementLabel()
  return "Node "
end

--- Build search adjacency from shared cell neighbours and search-owned endpoint attachments.
-- Cell IDs are translated to this search's node IDs. Manual nodes attach only to nearby grid cells.
-- @param #ASTAR self
-- @return #ASTAR self.
function ASTAR:_BuildGridLinks()
  self:_SyncGrid()
  local links={}
  for id in pairs(self.nodes) do links[id]={} end
  for _,cell in ipairs(self.Grid.CellList) do
    local node=self._CellNodes[cell.id]
    for _,neighbor in ipairs(self.Grid:GetNeighbours(cell)) do
      links[node.id][self._CellNodes[neighbor.id].id]=true
    end
  end
  for id,node in pairs(self.nodes) do
    if not node.cell then
      for _,cell in ipairs(self.Grid:GetNearbyCells(node.vector)) do
        local neighbor=self._CellNodes[cell.id]
        links[id][neighbor.id]=true
        links[neighbor.id][id]=true
      end
    end
  end
  self.gridLinks=links
  self.gridComponents={}
  return self
end

--- Add search-rule checks to the common marker defaults.
-- @param #ASTAR self
-- @return #table Independent defaults for search-node markers.
function ASTAR:_GridMarkDefaults()
  local options=GRID._GridMarkDefaults(self)
  options.CheckNeighbours=false
  return options
end
