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
-- @field #boolean GridNeighboursOnly Restrict candidates to direct grid edges and local endpoint attachments. Enabled automatically when a grid is built or attached.
-- @field #table hexGrid Hex geometry: origin x/z, heading cos/sin, spacing, rowSpacing, original distance, width, margin, candidateCount and temporary initialSamples for zone seeds.
-- @field #table gridLinks Cached candidate adjacency, indexed by node id, then neighbour id. Does not cache rule results.
-- @field #table gridComponents Connected-component labels for grid candidates. Rebuilt when candidate adjacency changes.
-- @field #table GridDrawIDs F10 polygon ids owned by DrawGrid(), removed by UndrawGrid().
-- @field #table GridDrawOptions Last DrawGrid() style and batch settings, retained for incremental updates.
-- @field #table GridDrawCellIDs Drawn polygon ids indexed by grid node id.
-- @field #table GridDrawJob Pending drawing queue, or nil once completed or cancelled.
-- @field #table LastGridDrawResult Last drawing job: Status, NodesQueued, NodesDrawn, Batches, CPUSeconds, MaxBatchCPUSeconds, ElapsedSimulationSeconds and optional Error.
-- @field #table LastSearchTiming Last search attempt: CPUSeconds, Failure and Nodes. CPUSeconds is nil when os.clock is unavailable.
-- @field #string LastPathFailure Reason the last search attempt failed; nil on success or when no attempt was made.
-- @field #ASTAR.SearchReport LastSearchResult Report from the most recent public search, also returned by FindPath().
-- @field #ASTAR.SearchReport LastExpansionResult Report from the most recent expanding search; unchanged by fixed searches.
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
-- FLIGHTGROUP, ARMYGROUP and NAVYGROUP accept node.vector in AddWaypoint, avoiding a temporary COORDINATE per waypoint.
--
--     local astar = ASTAR:New(GRID.Type.HEXAGON)
--     astar:SetEndpoints(ZONE:FindByName("Astar Start"):GetCoordinate(), ZONE:FindByName("Astar Goal"):GetCoordinate())
--     local grid = astar:GetGrid()
--     grid:SetValidSurfaceTypes({land.SurfaceType.WATER, land.SurfaceType.SHALLOW_WATER})
--     grid:SetCorridor(40000, 10000):SetResolution(2000)
--     grid:SetMaxCells(5000):SetExpansion(1.5, 5)
--     local built, reason = astar:BuildGrid()
--     if not built then
--       env.info("ASTAR: initial grid rejected: " .. reason)
--       return
--     end
--     astar:SetGridNeighboursOnly(true)
--     astar:SetValidNeighbourLoS(500)
--     local path, report = astar:FindPath(ASTAR.SearchMode.EXPAND)
--     if path then
--       astar:DrawGrid(path)
--       -- Optional text labels, separate from polygons:
--       -- astar:MarkGrid({ShowID=true, ShowGridIndex=true, ShowNeighbourCount=true})
--       -- navyGroup:AddWaypoint(path[1].vector, speed)
--     else
--       env.info("ASTAR: " .. report.StopReason)
--     end
--
-- # Shared GRID
--
-- Grid builders, topology, expansion and rendering are implemented by Core.Grid. The methods below remain forwarding conveniences.
-- Standalone grids select geometry with GRID:New(Name, GridType), then use dedicated setters, CreateFromBounds() and CreateFromZone().
-- Configure automatic spacing with GetGrid():SetResolution(GRID.Resolution.NORMAL) before creation; a numeric value selects manual meter spacing.
-- GetGrid():GetResolutionInfo() reports the calculated spacing.
-- GetGrid():SetCorridor(GRID.Width.NORMAL, GRID.Margin.NORMAL) selects relative initial corridor dimensions.
-- The same presets are accepted as Width and Margin in SetGridOptions(); zone builders ignore them.
-- BuildGrid() uses the owned grid type and search endpoints; BuildGrid(zone) uses zone bounds for either geometry.
-- SetGridOptions() and the four geometry-specific Create methods remain available for compatibility.
-- Use ExpandGrid() for either geometry; SetGridNeighboursOnly() is the single switch for local search candidates.
-- GetGrid() returns the owned grid, even before construction. SetGrid(grid) attaches a built GRID to an unused ASTAR and enables local neighbours.
-- New(GRID.Type.RECTANGLE) or New(GRID.Type.HEXAGON) selects the owned grid type before configuration; BuildGrid() follows this selection.
-- An explicit type keeps the same GRID through building, failed build retries and expansion. A conflicting builder is rejected before mutation.
-- New() without a type retains the legacy rectangle default: a hex convenience builder replaces that empty grid, preserving its configuration.
-- After that legacy replacement, call GetGrid() again instead of using a previously saved grid reference.
-- SetGrid(grid) is an explicit replacement and may attach either geometry, regardless of the constructor type.
-- Set start/end coordinates on each search separately; they do not change the shared grid frame. A node.cell refers to its immutable grid cell.
-- Spatial indices and grid settings belong to GRID. Use GetGridOptions() for configuration and GetGrid():GetDimensions()/GetCandidateCount() for current geometry and budget usage.
-- Expansion/options are shared, but nodes, endpoints, connection/cost caches, component labels and ASTAR overlays are per search object.
-- Public searches and drawing calls synchronize new cells and invalidate topology when the grid version changes. Existing pair caches are retained.
-- Never mutate cell/node vectors or indices directly. Configuration setters and expansion are the supported mutation paths.
-- Calling grid:DrawGrid(path) draws a grid-owned overlay; astar:DrawGrid(path) owns a separate search overlay.
--
-- # Grid Configuration
--
-- @{#ASTAR.SetValidSurfaceTypes} accepts a single DCS surface type or a list. Nil accepts all surfaces; an empty list accepts none.
-- @{#ASTAR.SetGridOptions} sets geometry, the shared candidate-cell budget and a nested Expansion table. Both setters copy their inputs.
-- SetGridOptions updates only supplied fields, including nested Expansion fields; nil or an empty table preserves the configuration.
-- GetGrid():ResetOptions() restores all option defaults, subject to the geometry lock after construction.
-- GetGrid():SetResolution(Resolution, CrossSpacing), SetMaxCells(MaxCells) and SetDiagonals(Diagonals) offer explicit setters.
-- Resolution accepts a meter spacing or GRID.Resolution preset; SetSpacing remains a manual-only alias.
-- GetGrid():SetExpansion(GrowthFactor, MaxAttempts, MaxWidth, MaxMargin) replaces all expansion settings.
-- For example, astar:GetGrid():SetResolution(GRID.Resolution.NORMAL):SetMaxCells(10000):SetExpansion(1.5, 5).
-- Omitted expansion limits remove previous limits. SetGridOptions({Expansion={MaxAttempts=3}}) instead preserves other expansion fields.
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
-- Diagonals, limits and Expansion settings can still change through partial SetGridOptions updates or the dedicated GRID setters.
-- Lowering MaxCells below the existing candidate count does not remove nodes; expanding search returns cell_limit before searching.
--
-- @{#ASTAR.BuildGrid} takes only an optional zone. Configure the grid through GetGrid() before creation.
-- Legacy CreateGrid() and CreateHexGrid() retain their fixed rectangle/hex meanings, including explicit-type mismatch checks.
-- All builders return self on success or nil, "cell_limit" when the initial budget is exceeded. Rejection occurs before terrain sampling.
-- A successful build allows no second Create call on the same object. Manual nodes may precede rectangular creation; hex creation requires no nodes.
--
-- # Geometry and Zones
--
-- Hex grids use axial q/r indices with the third cube coordinate equal to -q-r. Their origin and orientation follow the original start-to-goal line.
-- Neighbor centers are one Spacing apart; drawn hexagons have circumradius Spacing/sqrt(3). Rectangular cells use Spacing and CrossSpacing as side lengths.
-- Grid centers have altitude zero; the surface filter samples their 2D position. Cell outlines are visual aids, not traversability guarantees.
--
-- @{#ASTAR.BuildGrid}(zone) accepts circular, rectangular or polygonal MOOSE zones for either grid type.
-- The zone determines the initial area; configured Width and Margin are not used to crop it. Spacing and MaxCells still apply.
-- Center membership is checked with zone:IsVec2InZone() before querying terrain. MaxCells counts candidate centers in the projected bounding rectangle,
-- including centers rejected by either the zone or surface filter. This bounds preparation work, not only accepted nodes.
-- A zone constrains initial grid creation only. Exact endpoints and subsequent enlargement of either grid type may lie outside it.
-- For example, replace BuildGrid() above with astar:BuildGrid(ZONE:FindByName("Search Area")).
--
-- # Nodes and Endpoints
--
-- SetEndpoints(start,goal) accepts COORDINATE, VECTOR, Vec2 or Vec3 and validates both before changing either.
-- Each endpoint is stored as an independent VECTOR snapshot. Nil clears that endpoint; SetEndpoints() clears both.
-- SetStartCoordinate and SetEndCoordinate remain available to change just one endpoint.
-- Nodes contain id, vector, surfacetype and connection caches. Generated nodes also contain q/r or i/j indices. There is no node.coordinate field.
-- CreateNode(position) creates a node without adding it; AddNodeFromCoordinate creates and adds one. A supplied VECTOR is retained by reference;
-- other position types are copied. Do not mutate positions, indices or ids of added nodes: adjacency and costs are cached.
-- GetNodeFromCoordinate remains a compatibility alias for CreateNode, with the same return and ownership rules.
-- GetNodeCoordinate(node) creates a fresh COORDINATE with the node's exact altitude. It does not cache the result.
--
-- Endpoints reuse a coincident node within 0.000001 m, or add a surface-valid node at the requested position.
-- Coincidence uses 3D with SetCostMetric(ASTAR.CostMetric.DISTANCE_3D); default and custom cost rules use 2D, ignoring altitude.
-- Local grid mode attaches non-coincident endpoints to nearby grid centers; it never links manual nodes directly.
-- Obsolete automatically inserted endpoints are removed on endpoint resolution. Explicitly added nodes remain part of the graph.
-- FindPath(Mode, ExcludeStartNode, ExcludeEndNode) includes both endpoints by default. An empty table can be a successful path; nil means failure.
--
-- # Neighbours and Costs
--
-- SetGridNeighboursOnly(true) restricts regular nodes to indexed neighbors plus locally attached manual/endpoint nodes. Call it after building the grid.
-- Hex grids have six neighbors. Rectangles use four or eight according to Diagonals in SetGridOptions().
-- A diagonal requires both flanking cells to exist, preventing shortcuts between surface-filtered cells. The edge still undergoes the configured rule.
-- For example: astar:GetGrid():SetResolution(2000):SetDiagonals(false), followed by astar:BuildGrid().
-- To change Diagonals later, use GetGrid():SetDiagonals(false); the candidate graph is rebuilt on demand.
-- Local mode is the default once a grid is built or attached. SetGridNeighboursOnly(false) explicitly enables all-pairs candidates.
-- SetValidNeighbourDistance(maxDistance), SetValidNeighbourLoS(corridorWidth), SetValidNeighbourRoad(maxDistance), or
-- SetValidNeighbourFunction(function(nodeA,nodeB,...) ... end, ...) select the connection rule. Setting a rule replaces the previous rule.
-- Rules must be symmetric. Changing them clears validity caches. The LoS rule checks altitude 1 m above sea level, not the nodes' altitude;
-- its optional corridor tests the center line and two parallel offset lines. It is not a ship-depth or complete swept-area test.
-- SetValidNeighbourDepth(20, 1000) selects a naval depth rule: at least 20 meters of water along the center and both edges
-- of a 1000-meter-wide corridor. With no width, only the center is checked. It uses land.profile() and assumes linear
-- terrain between its support points. Actual endpoints are checked separately. Land and insufficient depth block an edge.
-- Direct depth queries at the profile points also apply; the shallower of the profile and direct depth is used.
-- This rule works without built grid cells and replaces the previous rule. It does not configure cell surface filtering.
-- Three profiles do not cover every point of the corridor or model a ship's turning arc. Missing terrain data blocks an edge.
--
-- Costs default to 2D distance. SetCostMetric(Metric) selects ASTAR.CostMetric.DISTANCE_2D, DISTANCE_3D or ROAD; nil restores DISTANCE_2D.
-- SetCostDist2D, SetCostDist3D and SetCostRoad remain compatibility aliases. SetCostFunction accepts symmetric, non-negative costs;
-- math.huge makes a connection impassable. Custom and road costs use a zero heuristic; built-in 2D/3D distances use their matching heuristic.
-- After SetValidNeighbourDepth(), SetCostDepth(30, 2) optionally prefers 30 meters of water while retaining the 2D heuristic.
-- Connections below the minimum stay blocked. Permitted shallow sections cost more, with no extra benefit beyond the preferred depth.
-- Changing cost functions clears cost caches. Costs and rule results are retained between searches, so recreate/reconfigure if their external data changes.
-- GetNodeNeighbourCount(node) counts candidates; GetNodeNeighbourCount(node,true) evaluates the neighbour rule but does not check travel costs.
--
-- # Expansion and Limits
--
-- FindPath() defaults to ASTAR.SearchMode.FIXED and searches the existing graph once.
-- FindPath(ASTAR.SearchMode.EXPAND) additionally enlarges a built rectangular or hex grid and retries after failure.
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
-- Rectangular enlargement preserves original i/j indices, spacing and orientation.
-- Grid builders enable local neighbours by default. Hex expanding searches require this local mode.
--
-- FindPath returns path, report and stores the report in LastSearchResult. Expanding searches also store it in LastExpansionResult.
-- GetPath() retains its single path return; GetPathWithExpansion() retains path, report. Both use the same search implementation.
-- Reports are new snapshots per call; treat them as read-only because the Last*Result fields refer to the returned table.
-- The report fields are documented in ASTAR.SearchReport:
-- * Mode: FIXED or EXPAND, using ASTAR.SearchMode values.
-- * Attempts: ordered entries with Width, Margin, Nodes, Failure and CPUSeconds.
-- * StopReason: path_found or search_failed for FIXED; path_found, attempt_limit, size_limit, cell_limit or missing_coordinates for EXPAND.
-- * FailureReason: concrete error from the last attempt, distinct from a reached expansion limit; nil on success or when no attempt was made.
-- * Width, Margin, Nodes, CandidateCells: final dimensions, accepted node count and budgeted candidate-cell count.
-- * MaxCells, MaxWidth, MaxMargin: effective limits for this search; omitted dimension limits remain nil in the report.
-- * BudgetLimited: true if a smaller growth step was fitted to the cell budget.
-- * SearchCPUSeconds: total search and enlargement CPU time, if a CPU clock is available.
-- Fixed searches on manual graphs have no grid dimensions, candidate-cell count or grid limits; those fields are nil.
-- Manual nodes and exact endpoints do not consume MaxCells, so accepted Nodes can exceed CandidateCells.
-- LastPathFailure contains missing_coordinates, no_start_node, no_goal_node, start_unattached, goal_unattached, disconnected_grid or connections_blocked.
-- Intermediate failures are trace-logged; final failure is announced once. Debug=true additionally enables player failure messages.
--
-- # Visual Debug
--
-- Building, searching and expanding never draw or update an overlay automatically.
-- DrawGrid() draws cell outlines; UpdateGridDrawing() explicitly appends missing cells after enlargement.
-- DrawGrid(path, options) creates a one-time snapshot with green path cells; later searches and updates do not change it.
-- DrawGrid(nil, options) styles a regular overlay. GRID.DrawOptions lists all named style and batch settings.
-- ClearDrawing(Kind) cancels work and removes owned polygons, labels or both, using GRID.Drawing constants; default ALL.
-- DrawGridWithPath(), UndrawGrid(), UnmarkGrid() and positional drawing arguments remain compatible.
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

--- Standard travel-cost metrics. Custom callbacks and depth preferences use their dedicated setters.
-- @type ASTAR.CostMetric
-- @field #string DISTANCE_2D Horizontal distance in meters, with a matching 2D heuristic. The default metric.
-- @field #string DISTANCE_3D Spatial distance in meters, with a matching 3D heuristic.
-- @field #string ROAD Road-path distance in meters, with a zero heuristic. Does not configure the neighbour rule.
ASTAR.CostMetric = {
  DISTANCE_2D = "distance_2d",
  DISTANCE_3D = "distance_3d",
  ROAD = "road",
}

--- Search modes for FindPath(). Both run synchronously and leave drawing to the caller.
-- @type ASTAR.SearchMode
-- @field #string FIXED Search the current graph once without enlarging it. The default mode.
-- @field #string EXPAND Retry with a larger grid after failure, stopping at the first path or a configured limit.
ASTAR.SearchMode = {
  FIXED = "fixed",
  EXPAND = "expand",
}

--- One search attempt, including exact endpoint resolution and connection checks.
-- @type ASTAR.SearchAttempt
-- @field #number Width Grid width in meters at this attempt; nil without a built grid.
-- @field #number Margin Grid margin in meters at this attempt; nil without a built grid.
-- @field #number Nodes Search-node count, including manual and exact endpoint nodes.
-- @field #string Failure Concrete search failure, or nil on success. See ASTAR.SearchReport.FailureReason.
-- @field #number CPUSeconds Attempt CPU time in seconds; nil when no CPU clock is available.

--- Result details returned by FindPath(). Each call creates a new report and attempt list.
-- The same report is stored in LastSearchResult (and LastExpansionResult for EXPAND); treat it as read-only.
-- Grid settings and counts are snapshots, not references to mutable configuration tables.
-- @type ASTAR.SearchReport
-- @field #string Mode ASTAR.SearchMode.FIXED or ASTAR.SearchMode.EXPAND.
-- @field #table Attempts Ordered ASTAR.SearchAttempt entries; empty if expansion was rejected before any search.
-- @field #string StopReason FIXED: path_found or search_failed. EXPAND: path_found, attempt_limit, size_limit, cell_limit or missing_coordinates.
-- @field #string FailureReason Last attempt failure: missing_coordinates, no_start_node, no_goal_node, start_unattached, goal_unattached, disconnected_grid or connections_blocked. Nil on success or when no attempt was made.
-- @field #number Width Final grid width in meters; nil without a built grid.
-- @field #number Margin Final grid margin in meters; nil without a built grid.
-- @field #number Nodes Final search-node count, including manual and exact endpoint nodes.
-- @field #number CandidateCells Budgeted grid-cell count before filtering; nil without a built grid.
-- @field #number MaxCells Configured grid-cell limit; nil without a built grid. FIXED searches do not enforce expansion limits.
-- @field #number MaxWidth Optional expansion width limit in meters; nil without a built grid or configured limit.
-- @field #number MaxMargin Optional expansion margin limit in meters; nil without a built grid or configured limit.
-- @field #boolean BudgetLimited Whether an expansion step was reduced to fit MaxCells. Always false for FIXED.
-- @field #number SearchCPUSeconds Total search and enlargement CPU time in seconds; nil when no CPU clock is available.

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

  if os and type(os.clock)=="function" then
    return {read=os.clock, start=os.clock()}
  end

end

local function elapsedCPU(clock)

  if clock then
    return math.max(0, clock.read()-clock.start)
  end

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
-- Select a type to configure and retain the same owned GRID before and after building. Builders must match this explicit type.
-- Without a type, legacy hex builders may replace the initially rectangular GRID; retrieve it again after building.
-- @param #ASTAR self
-- @param #string GridType (Optional) GRID.Type.RECTANGLE or GRID.Type.HEXAGON. Nil keeps legacy builder selection.
-- @return #ASTAR self
function ASTAR:New(GridType)

  assert(GridType==nil or GridType==GRID.Type.RECTANGLE or GridType==GRID.Type.HEXAGON,
    "ASTAR: GridType must be GRID.Type.RECTANGLE or GRID.Type.HEXAGON")

  -- Inherit from BASE.
  local self=BASE:Inherit(self, BASE:New()) --#ASTAR

  self.lid="ASTAR | "
  self.nodes={} 
  self.counter=1 
  self.Nnodes=0

  -- Geometry can be shared later; node ownership and search caches remain private to this instance.
  self.Grid=GRID:New("ASTAR", GridType or GRID.Type.RECTANGLE)
  self._GridTypeExplicit=GridType~=nil
  self._GridRevision=-1 
  self._CellNodes={} 
  self._CellCursor=0
  self._NodeOwner={}
  self._EndpointNodes={}

  return self

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set the requested start and goal together, validating both before changing either.
-- Stores independent VECTOR snapshots. Does not create nodes or rebuild/reorient an existing grid.
-- Use SetStartCoordinate() or SetEndCoordinate() to change only one endpoint.
-- @param #ASTAR self
-- @param Core.Point#COORDINATE Start Finite start position; also accepts VECTOR, DCS Vec2 or Vec3. Nil clears it.
-- @param Core.Point#COORDINATE Goal Finite goal position; also accepts VECTOR, DCS Vec2 or Vec3. Nil clears it.
-- @return #ASTAR self.
function ASTAR:SetEndpoints(Start, Goal)

  -- Resolve both snapshots first so a rejected goal cannot leave a new start behind.
  local startVector=Start~=nil and self.Grid:_PositionVector(Start) or nil
  local endVector=Goal~=nil and self.Grid:_PositionVector(Goal) or nil

  self.startVector=startVector
  self.endVector=endVector

  return self

end

--- Set the requested start coordinate. Does not create a node or rebuild the grid.
-- @param #ASTAR self
-- @param Core.Point#COORDINATE Coordinate Finite start position; also accepts VECTOR, DCS Vec2 or Vec3. Nil clears it.
-- @return #ASTAR self
function ASTAR:SetStartCoordinate(Coordinate)

  self.startVector=Coordinate~=nil and self.Grid:_PositionVector(Coordinate) or nil

  return self

end

--- Set the requested goal coordinate. Does not create a node or rebuild the grid.
-- @param #ASTAR self
-- @param Core.Point#COORDINATE Coordinate Finite goal position; also accepts VECTOR, DCS Vec2 or Vec3. Nil clears it.
-- @return #ASTAR self
function ASTAR:SetEndCoordinate(Coordinate)

  self.endVector=Coordinate~=nil and self.Grid:_PositionVector(Coordinate) or nil

  return self

end

--- Create a node without adding it to the search node set or applying the grid surface filter.
-- Stores a VECTOR and samples its current surface type. A supplied VECTOR is retained by reference;
-- other position types are copied into a new VECTOR. Do not mutate a retained VECTOR after adding the node.
-- @param #ASTAR self
-- @param Core.Point#COORDINATE Position Finite node position; also accepts VECTOR, DCS Vec2 or Vec3.
-- @return #ASTAR.Node The node.
function ASTAR:CreateNode(Position)

  local node={} --#ASTAR.Node

  node.vector=VECTOR._IsVector(Position) and Position or VECTOR:NewFromVec(Position)

  -- Validate before querying DCS or consuming an ID. Retain supplied VECTOR objects without copying them.
  for _,axis in ipairs({"x", "y", "z"}) do
    local value=node.vector[axis]
    assert(type(value)=="number" and value>-math.huge and value<math.huge, "ASTAR: node coordinates must be finite")
  end

  node.surfacetype=node.vector:GetSurfaceType()
  node.id=self.counter
  node._owner=self._NodeOwner
  node.grid=self.Grid

  node.valid={}
  node.cost={}

  self.counter=self.counter+1

  return node

end

--- Compatibility alias for CreateNode(). Creates a new node; does not look up or add an existing one.
-- @param #ASTAR self
-- @param Core.Point#COORDINATE Coordinate Finite node position; also accepts VECTOR, DCS Vec2 or Vec3.
-- @return #ASTAR.Node The node, with the same ownership and position-reference rules as CreateNode().
function ASTAR:GetNodeFromCoordinate(Coordinate)

  return self:CreateNode(Coordinate)

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
-- Does not apply the grid surface filter. Adding the same node again leaves the node count and caches unchanged.
-- Adding a new node invalidates grid candidate adjacency. Do not modify node ids, grid indices or coordinates after adding a node.
-- @param #ASTAR self
-- @param #ASTAR.Node Node The node to be added.
-- @return #ASTAR self
function ASTAR:AddNode(Node)

  assert(type(Node)=="table" and Node._owner==self._NodeOwner and Node.grid==self.Grid, "ASTAR: node must be created by this search for its current grid")
  local existing=self.nodes[Node.id]
  assert(not existing or existing==Node, "ASTAR: existing nodes cannot be replaced")
  if existing then
    return self
  end

  local cell=Node.cell
  if cell then
    assert(self.Grid:GetCell(cell.id)==cell, "ASTAR: node cell must belong to this grid")
    assert(not self._CellNodes[cell.id], "ASTAR: grid cell already contains a search node")
    assert(Node.q==cell.q and Node.r==cell.r and Node.i==cell.i and Node.j==cell.j and Node.rectGrid==cell.rectGrid,
      "ASTAR: node indices must match its grid cell")
    self._CellNodes[cell.id]=Node
  else
    assert(Node.q==nil and Node.r==nil and Node.i==nil and Node.j==nil and Node.rectGrid==nil,
      "ASTAR: manual nodes cannot have grid cell indices")
  end

  self.gridLinks=nil
  self.gridComponents=nil
  self.Nnodes=self.Nnodes+1
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

--- Replace the neighbour rule and clear cached validity results on all existing nodes.
-- The function receives nodeA, nodeB, then the optional arguments. It must be symmetric because results are cached in both directions.
-- Depth costs follow changes to the depth rule. Selecting another rule restores distance costs if depth costs were active.
-- @param #ASTAR self
-- @param #function NeighbourFunction Function returning true for an allowed connection, false otherwise. Nil allows all pairs.
-- @param ... Additional callback arguments, if any.
-- @return #ASTAR self
function ASTAR:SetValidNeighbourFunction(NeighbourFunction, ...)

  assert(NeighbourFunction==nil or type(NeighbourFunction)=="function", "ASTAR: neighbour rule must be a function or nil")

  self.ValidNeighbourFunc=NeighbourFunction

  self.ValidNeighbourArg={...}

  -- Preserve trailing nil callback arguments when unpacking them during rule evaluation.
  self.ValidNeighbourArg.n=select("#", ...)

  for _,node in pairs(self.nodes) do
    node.valid={}
  end

  -- Depth validity and costs share one profile evaluation and must use the same corridor and threshold.
  if self.CostFunc==ASTAR.CostDepth then
    if NeighbourFunction==ASTAR.Depth then
      self:SetCostFunction(ASTAR.CostDepth, self.ValidNeighbourArg[1] or 20, self.ValidNeighbourArg[2] or 0,
        self.CostArg[3], self.CostArg[4])
    else
      self:SetCostDist2D()
    end
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
  if Enabled==nil then
    Enabled=true
  end

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

  assert(CorridorWidth==nil or (type(CorridorWidth)=="number" and CorridorWidth>=0 and CorridorWidth<math.huge),
    "ASTAR: corridor width must be finite and non-negative")

  self:SetValidNeighbourFunction(ASTAR.LoS, CorridorWidth)

  return self

end

--- Replace the neighbour rule with a sampled surface corridor check using the grid's configured surface types.
-- Works with manual nodes and built grids. Includes endpoints; samples can miss obstacles smaller than their spacing.
-- Like other neighbour setters this replaces the previous rule. Reconfigure after changing external terrain data.
-- @param #ASTAR self
-- @param #number Step (Optional) Maximum terrain sample gap in meters; default 100.
-- @param #number CorridorWidth (Optional) Total corridor width in meters; default 0.
-- @return #ASTAR self.
---@param Step? number
---@param CorridorWidth? number
---@return ASTAR
function ASTAR:SetValidNeighbourSurface(Step, CorridorWidth)

  if Step==nil then
    Step=100
  end

  if CorridorWidth==nil then
    CorridorWidth=0
  end

  assert(type(Step)=="number" and Step>0 and Step<math.huge,"ASTAR: surface sample step must be finite and positive")
  assert(CorridorWidth>=0 and CorridorWidth<math.huge,"ASTAR: corridor width must be finite and non-negative")

  return self:SetValidNeighbourFunction(function(a,b)
    return self.Grid:CheckSurfacePath(a.vector,b.vector,Step,CorridorWidth)
  end)

end

--- Replace the neighbour rule with a minimum water depth check using terrain profiles.
-- Works with manual nodes and built grids, independently of the cell surface filter. WATER and SHALLOW_WATER are accepted
-- only when deep enough. Node altitude is ignored; depths are relative to the local water surface.
-- Assumes linear terrain between profile points. Checks actual endpoints separately and uses the shallower of profile
-- and directly queried depth at profile points. A corridor adds two parallel edge profiles, not a continuous area check.
-- A profile with fewer than two support points uses direct intermediate depth checks at a maximum gap of 100 meters.
-- Clears cached connection validity and any active depth costs. Reapply after external terrain data changes.
-- An active SetCostDepth() preference follows the new minimum and corridor; other cost rules and grid resolution stay unchanged.
-- @param #ASTAR self
-- @param #number MinDepth (Optional) Positive finite minimum water depth in meters, inclusive; default 20.
-- @param #number CorridorWidth (Optional) Non-negative finite total width in meters; default 0 (center line only).
-- @return #ASTAR self.
---@param MinDepth? number
---@param CorridorWidth? number
---@return ASTAR
function ASTAR:SetValidNeighbourDepth(MinDepth, CorridorWidth)

  if MinDepth==nil then
    MinDepth=20
  end

  if CorridorWidth==nil then
    CorridorWidth=0
  end

  assert(MinDepth>0 and MinDepth<math.huge,"ASTAR: minimum depth must be finite and positive")
  assert(CorridorWidth>=0 and CorridorWidth<math.huge,"ASTAR: corridor width must be finite and non-negative")

  return self:SetValidNeighbourFunction(ASTAR.Depth,MinDepth,CorridorWidth)

end

--- Replace the neighbour rule with a maximum 2D distance check, without checking terrain.
-- @param #ASTAR self
-- @param #number MaxDistance (Optional) Max distance between nodes in meters. Default is 2000 m.
-- @return #ASTAR self
function ASTAR:SetValidNeighbourDistance(MaxDistance)

  if MaxDistance==nil then
    MaxDistance=2000
  end

  assert(type(MaxDistance)=="number" and MaxDistance>=0 and MaxDistance<math.huge, "ASTAR: maximum distance must be finite and non-negative")

  self:SetValidNeighbourFunction(ASTAR.DistMax, MaxDistance)

  return self

end

--- Set valid neighbours to have a road connection within a maximum 2D distance.
-- Replaces the previous neighbour rule. Does not change the travel cost function; use SetCostRoad() separately for road costs.
-- @param #ASTAR self
-- @param #number MaxDistance (Optional) Maximum straight-line 2D distance between nodes in meters, inclusive. Default is 2000 m.
-- @return #ASTAR self
function ASTAR:SetValidNeighbourRoad(MaxDistance)

  if MaxDistance==nil then
    MaxDistance=2000
  end

  assert(type(MaxDistance)=="number" and MaxDistance>=0 and MaxDistance<math.huge, "ASTAR: maximum distance must be finite and non-negative")

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

  assert(CostFunction==nil or type(CostFunction)=="function", "ASTAR: cost rule must be a function or nil")

  self.CostFunc=CostFunction

  self.CostArg={...}

  -- Preserve the callback argument count, including trailing nil values.
  self.CostArg.n=select("#", ...)

  for _,node in pairs(self.nodes) do
    node.cost={}
  end

  return self

end

--- Select a standard travel-cost metric and its matching heuristic, clearing cached costs.
-- Does not change the neighbour rule. Replaces any custom cost function or soft depth preference.
-- Use SetCostFunction() for custom callbacks or SetCostDepth() for depth-weighted horizontal distance.
-- @param #ASTAR self
-- @param #string Metric (Optional) ASTAR.CostMetric.DISTANCE_2D, DISTANCE_3D or ROAD. Nil selects DISTANCE_2D.
-- @return #ASTAR self.
function ASTAR:SetCostMetric(Metric)

  if Metric==nil then
    Metric=ASTAR.CostMetric.DISTANCE_2D
  end

  local costFunction
  if Metric==ASTAR.CostMetric.DISTANCE_2D then
    costFunction=ASTAR.Dist2D
  elseif Metric==ASTAR.CostMetric.DISTANCE_3D then
    costFunction=ASTAR.Dist3D
  elseif Metric==ASTAR.CostMetric.ROAD then
    costFunction=ASTAR.DistRoad
  else
    error("ASTAR: Metric must be an ASTAR.CostMetric value")
  end

  -- The cost function also selects the existing admissible heuristic and endpoint distance metric.
  return self:SetCostFunction(costFunction)

end

--- Compatibility alias for SetCostMetric(ASTAR.CostMetric.DISTANCE_2D).
-- @param #ASTAR self
-- @return #ASTAR self
function ASTAR:SetCostDist2D()

  return self:SetCostMetric(ASTAR.CostMetric.DISTANCE_2D)

end

--- Prefer deeper water while retaining the configured minimum depth as a hard limit.
-- Call SetValidNeighbourDepth() first. Costs integrate a quadratic penalty along the terrain profiles,
-- using the shallowest of the center/edge profiles at each distance. At PreferredDepth and deeper,
-- cost equals horizontal distance; at the minimum depth the multiplier is 1 + Weight.
-- Nil restores ordinary distance costs. A preferred depth at/below the minimum, or zero weight,
-- adds no penalty. Changing the depth rule updates these costs; another neighbour rule disables them.
-- @param #ASTAR self
-- @param #number PreferredDepth (Optional) Positive finite preferred depth in meters; nil disables the preference.
-- @param #number Weight (Optional) Finite non-negative penalty strength; default 2.
-- @return #ASTAR self.
---@param PreferredDepth? number
---@param Weight? number
---@return ASTAR
function ASTAR:SetCostDepth(PreferredDepth, Weight)

  if PreferredDepth==nil then
    return self:SetCostDist2D()
  end

  if Weight==nil then Weight=2 end
  assert(PreferredDepth>0 and PreferredDepth<math.huge,"ASTAR: preferred depth must be finite and positive")
  assert(Weight>=0 and Weight<math.huge,"ASTAR: depth weight must be finite and non-negative")
  assert(self.ValidNeighbourFunc==ASTAR.Depth,"ASTAR: configure SetValidNeighbourDepth before depth costs")

  return self:SetCostFunction(ASTAR.CostDepth, self.ValidNeighbourArg[1] or 20, self.ValidNeighbourArg[2] or 0,
    PreferredDepth, Weight)

end

--- Compatibility alias for SetCostMetric(ASTAR.CostMetric.DISTANCE_3D).
-- @param #ASTAR self
-- @return #ASTAR self
function ASTAR:SetCostDist3D()

  return self:SetCostMetric(ASTAR.CostMetric.DISTANCE_3D)

end

--- Compatibility alias for SetCostMetric(ASTAR.CostMetric.ROAD), using a zero heuristic.
-- @param #ASTAR self
-- @return #ASTAR self
function ASTAR:SetCostRoad()

  return self:SetCostMetric(ASTAR.CostMetric.ROAD)

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
    if not self.gridLinks then
      self:_BuildGridLinks()
    end
    for id in pairs(self.gridLinks[Node.id] or {}) do
      if not CheckValid or self:_IsValidNeighbour(Node,self.nodes[id]) then
        count=count+1
      end
    end
  elseif not CheckValid then
    return math.max(0,self.Nnodes-1)
  else
    for id,other in pairs(self.nodes) do
      if id~=Node.id and self:_IsValidNeighbour(Node,other) then
        count=count+1
      end
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

  local cA=nodeA.vector:GetVec3()
  local cB=nodeB.vector:GetVec3()
  cA.y=offset
  cB.y=offset

  local los=land.isVisible(cA, cB)

  if los and corridor and corridor>0 then

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

--- Check the endpoints and terrain profile of one water connection, optionally retaining depths for costs.
-- The first rejection ends this check. Locating an obstruction belongs to PATHLINE.CheckDepth().
-- @param DCS#Vec3 Start Start position at the water surface.
-- @param DCS#Vec3 Goal Goal position at the water surface.
-- @param #number Distance Horizontal distance between the endpoints, greater than zero.
-- @param #number MinDepth Minimum water depth in meters, inclusive.
-- @param #table Samples (Optional) Receives pairs of projected distance and depth for cost integration.
-- @return #boolean True when the connection is sufficiently deep water.
-- @return #string Reason for rejection, or nil on success.
function ASTAR._CheckDepthLine(Start, Goal, Distance, MinDepth, Samples)

  -- DCS may omit the endpoints from its profile. Always check their actual depths as well.
  for i=1,2 do
    local point=i==1 and Start or Goal
    local clear,status,cause,depth=VECTOR._CheckDepthPoint(point,MinDepth,false)

    if not clear then
      return false,status=="unavailable" and cause or (i==1 and "start_blocked" or "goal_blocked")
    end

    if Samples then Samples[#Samples+1]={i==1 and 0 or Distance,depth} end
  end

  local profile=land.profile(Start,Goal)
  if type(profile)~="table" then
    return false,"profile_unavailable"
  end

  -- Under the linear-profile assumption, valid support points also bound the depths between them.
  for i=1,#profile do
    local point=profile[i]
    local clear,status,cause,depth=VECTOR._CheckDepthPoint(point,MinDepth,true)

    if not clear then
      return false,status=="unavailable" and cause or "profile_blocked"
    end

    if Samples then
      local along=((point.x-Start.x)*(Goal.x-Start.x)+(point.z-Start.z)*(Goal.z-Start.z))/Distance
      Samples[#Samples+1]={math.max(0,math.min(Distance,along)),depth}
    end
  end

  -- An empty or single-point profile cannot describe the whole connection.
  -- Check additional positions at most 100 m apart, with a bound on the amount of work.
  if #profile<2 then
    local intervals=math.max(2,math.ceil(Distance/100))
    if intervals>1000 then
      return false,"profile_fallback_limit"
    end

    for i=1,intervals-1 do
      local fraction=i/intervals
      local point={x=Start.x+(Goal.x-Start.x)*fraction,z=Start.z+(Goal.z-Start.z)*fraction}
      local clear,status,cause,depth=VECTOR._CheckDepthPoint(point,MinDepth,false)

      if not clear then
        return false,status=="unavailable" and cause or "profile_fallback_blocked"
      end

      if Samples then Samples[#Samples+1]={fraction*Distance,depth} end
    end
  end

  return true

end

--- Integrate the quadratic shallow-water penalty over one linear depth interval.
-- Split at the preferred depth: deeper water has zero penalty, not a reward for a detour.
-- @param #number Length Horizontal interval length in meters.
-- @param #number DepthA Depth at the interval start.
-- @param #number DepthB Depth at the interval end.
-- @param #number MinDepth Hard minimum depth.
-- @param #number PreferredDepth Preferred depth, greater than MinDepth.
-- @return #number Length-weighted penalty before applying the configured weight.
function ASTAR._DepthPenaltyInterval(Length, DepthA, DepthB, MinDepth, PreferredDepth)

  if DepthA>=PreferredDepth and DepthB>=PreferredDepth then return 0 end

  if DepthA>PreferredDepth then
    Length=Length*(PreferredDepth-DepthB)/(DepthA-DepthB)
    DepthA=PreferredDepth
  elseif DepthB>PreferredDepth then
    Length=Length*(PreferredDepth-DepthA)/(DepthB-DepthA)
    DepthB=PreferredDepth
  end

  local a=(PreferredDepth-DepthA)/(PreferredDepth-MinDepth)
  local b=(PreferredDepth-DepthB)/(PreferredDepth-MinDepth)
  return Length*(a*a+a*b+b*b)/3

end

--- Integrate the shallowest interpolated depth across the checked corridor profiles.
-- Actual distances make the result independent of profile sample density. Crossings between
-- side profiles split an interval so a shallow bank is never averaged away by deeper water.
-- @param #table Profiles Lists of distance/depth pairs, including both endpoints.
-- @param #number Distance Horizontal connection length in meters.
-- @param #number MinDepth Hard minimum depth.
-- @param #number PreferredDepth Preferred depth, greater than MinDepth.
-- @return #number Length-weighted quadratic penalty.
function ASTAR._DepthPenalty(Profiles, Distance, MinDepth, PreferredDepth)

  -- Most offshore edges have no penalty. Their support points already prove this without sorting.
  local deep=true
  for _,samples in ipairs(Profiles) do
    for _,sample in ipairs(samples) do
      if sample[2]<PreferredDepth then deep=false break end
    end
    if not deep then break end
  end
  if deep then return 0 end

  local indices={}
  for i,samples in ipairs(Profiles) do
    table.sort(samples,function(a,b) return a[1]<b[1] end)

    -- Endpoints and DCS support points can coincide. Keep the shallower observation.
    local count=0
    for j=1,#samples do
      local sample=samples[j]
      if count>0 and sample[1]==samples[count][1] then
        samples[count][2]=math.min(samples[count][2],sample[2])
      else
        count=count+1
        samples[count]=sample
      end
    end
    for j=#samples,count+1,-1 do samples[j]=nil end
    indices[i]=1
  end

  local position,penalty=0,0
  while position<Distance do
    local finish=Distance
    for i,samples in ipairs(Profiles) do
      finish=math.min(finish,samples[indices[i]+1][1])
    end

    local depths,cuts={},{0,1}
    for i,samples in ipairs(Profiles) do
      local a,b=samples[indices[i]],samples[indices[i]+1]
      local slope=(b[2]-a[2])/(b[1]-a[1])
      depths[i]={a[2]+slope*(position-a[1]),a[2]+slope*(finish-a[1])}
    end

    -- Between support points, the shallowest profile can change only at a line crossing.
    for i=1,#depths do
      for j=i+1,#depths do
        local deltaA=depths[i][1]-depths[j][1]
        local deltaB=depths[i][2]-depths[j][2]
        if deltaA*deltaB<0 then cuts[#cuts+1]=deltaA/(deltaA-deltaB) end
      end
    end
    table.sort(cuts)

    for i=2,#cuts do
      local from,to=cuts[i-1],cuts[i]
      local middle=(from+to)/2
      local selected,shallowest=nil,math.huge
      for _,depth in ipairs(depths) do
        local value=depth[1]+(depth[2]-depth[1])*middle
        if value<shallowest then selected,shallowest=depth,value end
      end

      local slope=selected[2]-selected[1]
      penalty=penalty+ASTAR._DepthPenaltyInterval((finish-position)*(to-from),
        selected[1]+slope*from,selected[1]+slope*to,MinDepth,PreferredDepth)
    end

    position=finish
    for i,samples in ipairs(Profiles) do
      if samples[indices[i]+1][1]==position then indices[i]=indices[i]+1 end
    end
  end

  return penalty

end

--- Check whether two nodes are connected by sufficiently deep water.
-- Checks actual endpoints and land.profile() support points, using the shallower of profile and direct depth.
-- Positive CorridorWidth also checks the two parallel edges; this does not cover the entire area between them.
-- Profiles with fewer than two points receive bounded direct samples at a maximum gap of 100 meters.
-- Coincident horizontal positions check only that position. Node altitude is ignored.
-- This neighbour rule returns immediately on rejection and does not build or sort diagnostic samples.
-- Use PATHLINE.CheckDepth() when the position and distance of the first obstruction are needed.
-- @param #ASTAR.Node nodeA First node.
-- @param #ASTAR.Node nodeB Second node.
-- @param #number MinDepth (Optional) Positive finite minimum water depth in meters, inclusive; default 20.
-- @param #number CorridorWidth (Optional) Non-negative finite total corridor width in meters; default 0.
-- @return #boolean True when every check passes; false for blocked or unusable terrain data.
-- @return #string Reason for rejection, or nil on success. Start/goal refer to the canonical query direction.
function ASTAR.Depth(nodeA, nodeB, MinDepth, CorridorWidth)

  return ASTAR._DepthConnection(nodeA,nodeB,MinDepth,CorridorWidth)

end

--- Calculate distance plus a length-weighted penalty for shallow but navigable water.
-- Uses the same hard depth/corridor checks as Depth(). A blocked or unavailable connection costs math.huge.
-- @param #ASTAR.Node nodeA First node.
-- @param #ASTAR.Node nodeB Second node.
-- @param #number MinDepth (Optional) Minimum water depth in meters; default 20.
-- @param #number CorridorWidth (Optional) Total checked corridor width in meters; default 0.
-- @param #number PreferredDepth (Optional) Preferred water depth in meters; nil adds no penalty.
-- @param #number Weight (Optional) Non-negative penalty strength; default 2.
-- @return #number Symmetric horizontal travel cost, or math.huge when blocked.
function ASTAR.CostDepth(nodeA, nodeB, MinDepth, CorridorWidth, PreferredDepth, Weight)

  local clear,reason,cost=ASTAR._DepthConnection(nodeA,nodeB,MinDepth,CorridorWidth,PreferredDepth,Weight)
  return clear and cost or math.huge

end

--- Evaluate depth validity and optional cost together, without querying a profile twice.
-- Plain validity checks retain the early-exit path and do not allocate or sort cost samples.
-- @param #ASTAR.Node nodeA First node.
-- @param #ASTAR.Node nodeB Second node.
-- @param #number MinDepth (Optional) Minimum depth in meters; default 20.
-- @param #number CorridorWidth (Optional) Total corridor width in meters; default 0.
-- @param #number PreferredDepth (Optional) Preferred depth in meters; nil disables the penalty.
-- @param #number Weight (Optional) Non-negative penalty strength; default 2.
-- @return #boolean Whether the connection is navigable.
-- @return #string Rejection reason, or nil.
-- @return #number Travel cost on success.
function ASTAR._DepthConnection(nodeA, nodeB, MinDepth, CorridorWidth, PreferredDepth, Weight)

  if MinDepth==nil then
    MinDepth=20
  end

  if CorridorWidth==nil then
    CorridorWidth=0
  end

  assert(MinDepth>0 and MinDepth<math.huge,"ASTAR: minimum depth must be finite and positive")
  assert(CorridorWidth>=0 and CorridorWidth<math.huge,"ASTAR: corridor width must be finite and non-negative")

  if Weight==nil then Weight=2 end
  if PreferredDepth~=nil then
    assert(PreferredDepth>0 and PreferredDepth<math.huge,"ASTAR: preferred depth must be finite and positive")
    assert(Weight>=0 and Weight<math.huge,"ASTAR: depth weight must be finite and non-negative")
  end
  local profiles=PreferredDepth and PreferredDepth>MinDepth and Weight>0 and {} or nil

  local a,b=nodeA.vector,nodeB.vector
  local dx,dz=b.x-a.x,b.z-a.z
  local distance=math.sqrt(dx*dx+dz*dz)

  if not (distance<math.huge) then
    return false,"invalid_distance"
  end

  if distance==0 then
    local clear,status,cause=VECTOR._CheckDepthPoint(a,MinDepth,false)
    return clear,not clear and (status=="unavailable" and cause or "start_blocked") or nil,clear and 0 or nil
  end

  -- Query DCS in the same direction for A -> B and B -> A, matching A*'s symmetric validity cache.
  if a.x>b.x or (a.x==b.x and a.z>b.z) then
    a,b=b,a
    dx,dz=-dx,-dz
  end

  local nx,nz=-dz/distance,dx/distance
  local lines=CorridorWidth>0 and 3 or 1

  for i=1,lines do
    local offset=i==2 and CorridorWidth/2 or (i==3 and -CorridorWidth/2 or 0)
    local start={x=a.x+nx*offset,y=0,z=a.z+nz*offset}
    local goal={x=b.x+nx*offset,y=0,z=b.z+nz*offset}
    local samples=profiles and {} or nil
    local clear,reason=ASTAR._CheckDepthLine(start,goal,distance,MinDepth,samples)

    if not clear then
      return false,reason
    end

    if profiles then profiles[#profiles+1]=samples end
  end

  local cost=distance
  if profiles then cost=cost+Weight*ASTAR._DepthPenalty(profiles,distance,MinDepth,PreferredDepth) end

  return true,nil,cost

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
-- Uses 3D distance with SetCostDist3D(), otherwise 2D distance, including for custom cost functions.
-- @return #ASTAR.Node Closest node, or nil if the node set is empty.
-- @return #number Distance to the closest node in meters, or math.huge if the node set is empty.
function ASTAR:FindClosestNode(Coordinate)

  local position=self.Grid:_PositionVector(Coordinate)
  self:_SyncGrid()

  local distMin=math.huge
  local closeNode=nil
  local horizontal=self.CostFunc~=ASTAR.Dist3D

  for _,_node in pairs(self.nodes) do
    local node=_node --#ASTAR.Node

    local dist=node.vector:GetDistance(position, horizontal)

    if dist<distMin then
      distMin=dist
      closeNode=node
    end

  end

  return closeNode, distMin

end

--- Reuse a coincident start node, or add one at the requested start position.
-- Uses the distance metric of FindClosestNode(), with a 0.000001-meter tolerance for numerical round-off.
-- Sets startNode to nil if the node set is empty or an added endpoint fails the surface filter.
-- @param #ASTAR self
-- @return #ASTAR self
function ASTAR:FindStartNode()

  self.startNode=self:_FindEndpoint(self.startVector, "start")

  return self

end

--- Reuse a coincident goal node, or add one at the requested goal position.
-- Uses the distance metric of FindClosestNode(), with a 0.000001-meter tolerance for numerical round-off.
-- Sets endNode to nil if the node set is empty or an added endpoint fails the surface filter.
-- @param #ASTAR self
-- @return #ASTAR self
function ASTAR:FindEndNode()

  self.endNode=self:_FindEndpoint(self.endVector, "end")

  return self

end

--- Remove automatic endpoints no longer requested by this search.
-- Keeps caller-added nodes and current endpoints. Previously returned paths retain their node objects for inspection.
-- @param #ASTAR self
-- @return #nil No return value; removes obsolete nodes, pair-cache entries and candidate adjacency.
function ASTAR:_PruneEndpointNodes()

  local removed={}
  local horizontal=self.CostFunc~=ASTAR.Dist3D

  -- Only automatically inserted endpoints expire; caller-added nodes stay in the graph.
  for id,node in pairs(self._EndpointNodes) do
    local atStart=self.startVector and node.vector:GetDistance(self.startVector, horizontal)<=1e-6
    local atGoal=self.endVector and node.vector:GetDistance(self.endVector, horizontal)<=1e-6

    if not atStart and not atGoal then
      removed[#removed+1]=id
      self.nodes[id]=nil
      self._EndpointNodes[id]=nil
      self.Nnodes=self.Nnodes-1
      node.valid={}
      node.cost={}
      if self.startNode==node then
        self.startNode=nil
      end
      if self.endNode==node then
        self.endNode=nil
      end
    end
  end

  if #removed>0 then
    -- Pair caches are symmetric; remove reverse references so moving endpoints cannot accumulate cache entries.
    for _,node in pairs(self.nodes) do
      for _,id in ipairs(removed) do
        node.valid[id]=nil
        node.cost[id]=nil
      end
    end

    self.gridLinks=nil
    self.gridComponents=nil
  end

end

--- Resolve one exact endpoint using the current distance metric and surface filter.
-- @param #ASTAR self
-- @param Core.Vector#VECTOR Coordinate Requested endpoint.
-- @param #string Label Endpoint name for trace output.
-- @return #ASTAR.Node Selected or added node, or nil.
function ASTAR:_FindEndpoint(Coordinate, Label)

  self:_PruneEndpointNodes()
  if not Coordinate then
    return nil
  end

  local node, distance=self:FindClosestNode(Coordinate)

  -- Reuse coincident nodes only. Snapping to a nearby node would skip the actual endpoint connection and its validity checks.
  if node and distance>1e-6 then
    self:T(self.lid.."Adding "..Label.." node to node grid!")
    node=self:GetNodeFromCoordinate(Coordinate)
    if not self.Grid:IsValidSurfaceType(node.surfacetype) then
      return nil
    end
    self:AddNode(node)
    self._EndpointNodes[node.id]=node
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
  self:_PruneEndpointNodes()
  if not self.startVector or not self.endVector then
    return nil, nil, "missing_coordinates"
  end
  self:FindStartNode()
  self:FindEndNode()
  local reason
  if not self.startNode then
    reason="no_start_node"
  elseif not self.endNode then
    reason="no_goal_node"
  end

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
  if reason then
    return false, reason
  end

  return self:_HasPotentialPath(start, goal)

end

--- Search synchronously between the configured endpoints, returning a path and a result report.
-- FIXED searches the existing graph once. EXPAND enlarges a built rectangular or hex grid after failure,
-- using GRID expansion settings and limits, and stops at the first path. Hex expansion requires local grid neighbours.
-- Does not draw or assign routes to units. The selected cost and neighbour rules apply in both modes.
-- Invalid modes/flags are rejected before searching. A final search failure is announced once; Debug controls player messages.
-- @param #ASTAR self
-- @param #string Mode (Optional) ASTAR.SearchMode.FIXED or EXPAND; nil selects FIXED.
-- @param #boolean ExcludeStartNode (Optional) Exclude the selected start node; default false.
-- @param #boolean ExcludeEndNode (Optional) Exclude the selected goal node; default false.
-- @return #table Ordered ASTAR.Node list, or nil on failure. An empty table is a successful path.
-- @return #ASTAR.SearchReport New report, also stored in LastSearchResult. FailureReason is the last search error; StopReason explains why searching stopped.
function ASTAR:FindPath(Mode, ExcludeStartNode, ExcludeEndNode)

  if Mode==nil then
    Mode=ASTAR.SearchMode.FIXED
  end
  assert(Mode==ASTAR.SearchMode.FIXED or Mode==ASTAR.SearchMode.EXPAND, "ASTAR: Mode must be an ASTAR.SearchMode value")
  assert(ExcludeStartNode==nil or type(ExcludeStartNode)=="boolean", "ASTAR: endpoint exclusion flags must be booleans")
  assert(ExcludeEndNode==nil or type(ExcludeEndNode)=="boolean", "ASTAR: endpoint exclusion flags must be booleans")

  local path,report
  if Mode==ASTAR.SearchMode.EXPAND then
    path,report=self:_FindPathWithExpansion(ExcludeStartNode,ExcludeEndNode)
  else
    self.LastPathFailure=nil
    local failure
    path,failure=self:_SearchPath(ExcludeStartNode,ExcludeEndNode)
    self.LastPathFailure=failure

    -- Fixed searches also support manual graphs without any grid geometry.
    local grid=self.hexGrid or self.rectGrid
    local options=self:GetGridOptions()
    local width=grid and grid.width
    local margin=grid and grid.margin
    local attempt={
      Width=width,
      Margin=margin,
      Nodes=self.Nnodes,
      Failure=failure,
      CPUSeconds=self.LastSearchTiming.CPUSeconds,
    }
    report={
      Mode=Mode,
      StopReason=path and "path_found" or "search_failed",
      FailureReason=failure,
      Width=width,
      Margin=margin,
      Nodes=self.Nnodes,
      CandidateCells=grid and grid.candidateCount,
      MaxCells=grid and options.MaxCells,
      MaxWidth=grid and options.Expansion.MaxWidth,
      MaxMargin=grid and options.Expansion.MaxMargin,
      BudgetLimited=false,
      SearchCPUSeconds=self.LastSearchTiming.CPUSeconds,
      Attempts={attempt},
    }
  end

  -- Only the public entry point announces failure; intermediate expansion attempts stay quiet.
  self.LastSearchResult=report
  if not path then
    if Mode==ASTAR.SearchMode.EXPAND then
      self:_ReportPathFailure(report.FailureReason or report.StopReason,report.StopReason)
    else
      self:_ReportPathFailure(report.FailureReason)
    end
  end

  return path,report

end

--- Compatibility alias for FindPath(ASTAR.SearchMode.EXPAND, ExcludeStartNode, ExcludeEndNode).
-- Retains the two return values and LastExpansionResult. Stops at the first path or a configured limit.
-- @param #ASTAR self
-- @param #boolean ExcludeStartNode (Optional) Exclude the selected start node from the returned path.
-- @param #boolean ExcludeEndNode (Optional) Exclude the selected goal node from the returned path.
-- @return #table Ordered path nodes, or nil on failure. An empty table is a successful path.
-- @return #ASTAR.SearchReport Expansion report, also stored in LastExpansionResult and LastSearchResult.
function ASTAR:GetPathWithExpansion(ExcludeStartNode, ExcludeEndNode)

  return self:FindPath(ASTAR.SearchMode.EXPAND,ExcludeStartNode,ExcludeEndNode)

end

--- Search a built grid and expand it as needed without announcing final failure.
-- @param #ASTAR self
-- @param #boolean ExcludeStartNode Exclude the selected start node.
-- @param #boolean ExcludeEndNode Exclude the selected goal node.
-- @return #table Ordered path nodes, including an empty successful path, or nil.
-- @return #ASTAR.SearchReport Expansion report.
function ASTAR:_FindPathWithExpansion(ExcludeStartNode, ExcludeEndNode)

  self:_SyncGrid()
  assert(self.hexGrid or self.rectGrid, "ASTAR: create a rectangular or hex grid before expanding search")
  assert(not self.hexGrid or self.GridNeighboursOnly, "ASTAR: call SetGridNeighboursOnly(true) before expanding a hex grid")
  local options=self:GetGridOptions()
  local grid=self.hexGrid or self.rectGrid
  local factor=options.Expansion.GrowthFactor
  local maxAttempts=options.Expansion.MaxAttempts
  local maxCells=options.MaxCells
  local maxWidth=options.Expansion.MaxWidth
  local maxMargin=options.Expansion.MaxMargin
  assert(maxWidth==nil or maxWidth>=grid.width, "ASTAR: MaxWidth must be at least the current width")
  assert(maxMargin==nil or maxMargin>=grid.margin, "ASTAR: MaxMargin must be at least the current margin")

  self.LastPathFailure=nil

  -- Include both searches and grid enlargement in the overall timing report.
  local searchClock=startCPUClock()
  local report={Mode=ASTAR.SearchMode.EXPAND,Attempts={},BudgetLimited=false}

  local function finish(path, reason)
    -- All exit paths publish the same final dimensions, limits and attempt history.
    report.StopReason=reason
    report.FailureReason=self.LastPathFailure
    report.Width=grid.width
    report.Margin=grid.margin
    report.Nodes=self.Nnodes
    report.CandidateCells=grid.candidateCount
    report.MaxCells=maxCells
    report.MaxWidth=maxWidth
    report.MaxMargin=maxMargin
    report.SearchCPUSeconds=elapsedCPU(searchClock)
    self.LastExpansionResult=report
    self:T(self.lid..string.format("Expanding search finished: %s after %d attempts, width %.0f m, margin %.0f m, %d nodes, search %s",
      reason, #report.Attempts, grid.width, grid.margin, self.Nnodes, cpuTimeText(report.SearchCPUSeconds)))
    return path, report
  end

  if grid.candidateCount>maxCells then
    return finish(nil, "cell_limit")
  end

  for attempt=1,maxAttempts do
    self:T(self.lid..string.format("Expanding search attempt %d/%d: width %.0f m, margin %.0f m, %d nodes",
      attempt, maxAttempts, grid.width, grid.margin, self.Nnodes))
    self.LastPathFailure=nil
    local path, failure=self:_SearchPath(ExcludeStartNode, ExcludeEndNode)
    self.LastPathFailure=failure
    if failure then
      self:T(self.lid.."Search attempt failed: "..failure)
    end
    report.Attempts[#report.Attempts+1]={Width=grid.width, Margin=grid.margin, Nodes=self.Nnodes, Failure=self.LastPathFailure, CPUSeconds=self.LastSearchTiming.CPUSeconds}

    if path then
      return finish(path, "path_found")
    end

    if self.LastPathFailure=="missing_coordinates" then
      return finish(nil, "missing_coordinates")
    end

    if attempt==maxAttempts then
      return finish(nil, "attempt_limit")
    end

    -- Grow by at least one spacing per side so zero or small initial dimensions can still expand.
    local width=math.max(grid.width*factor, grid.width+2*(grid.crossSpacing or grid.spacing))
    local margin=math.max(grid.margin*factor, grid.margin+grid.spacing)
    if maxWidth then
      width=math.min(maxWidth,width)
    end
    if maxMargin then
      margin=math.min(maxMargin,margin)
    end

    if width==math.huge or margin==math.huge then
      return finish(nil,"size_limit")
    end

    if width==grid.width and margin==grid.margin then
      return finish(nil, "size_limit")
    end

    -- Let GRID fit a smaller step to the cell budget while preserving existing cells and samples.
    local expanded, stopReason, limited=self.Grid:ExpandGrid(width,margin,true)
    if not expanded then
      return finish(nil,stopReason)
    end
    self:_SyncGrid()
    if limited then
      self:T(self.lid..string.format("Fitted expansion to MaxCells=%d: width %.1f m, margin %.1f m, %d candidate cells",maxCells,grid.width,grid.margin,grid.candidateCount))
    end
    report.BudgetLimited=report.BudgetLimited or limited
  end

end

--- Compatibility wrapper for FindPath(ASTAR.SearchMode.FIXED, ExcludeStartNode, ExcludeEndNode), returning only the path.
-- Returns nodes in travel order; pass node.vector to FLIGHTGROUP/ARMYGROUP/NAVYGROUP:AddWaypoint or use GetNodeCoordinate(node) for APIs requiring COORDINATE.
-- Does not assign a route to a unit or group.
-- Endpoint exclusions can produce an empty table for a successful search. Nil indicates failure.
-- In local grid mode, rejects disconnected candidate components before evaluating any neighbour rule or cost.
-- LastSearchResult holds the report; LastPathFailure retains the concrete failure reason.
-- @param #ASTAR self
-- @param #boolean ExcludeStartNode If *true*, do not include start node in found path. Default is to include it.
-- @param #boolean ExcludeEndNode If *true*, do not include end node in found path. Default is to include it.
-- @return #table Ordered list of ASTAR.Node entries (possibly empty), or nil for missing coordinates, missing endpoint nodes, or an unreachable goal.
function ASTAR:GetPath(ExcludeStartNode, ExcludeEndNode)

  local path=self:FindPath(ASTAR.SearchMode.FIXED,ExcludeStartNode,ExcludeEndNode)

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
  if reason then
    return finish(nil, reason)
  end

  -- Reject disconnected geometry before spending work on terrain rules and travel costs.
  local potential, failure=self:_HasPotentialPath(start, goal)
  if not potential then
    return finish(nil, failure)
  end

  local nodes=self.nodes

  -- Keep tentative scores and predecessors local to this attempt; pair caches live on the nodes.
  local openset   = {}
  local closedset = {}
  local came_from = {}
  local g_score   = {}
  local f_score   = {}

  openset[start.id]=true
  local Nopen=1

  -- g_score is the cost already travelled; f_score adds a lower bound on the remaining cost.
  g_score[start.id]=0
  f_score[start.id]=g_score[start.id]+self:_HeuristicCost(start, goal)

  -- Debug message.
  local text=string.format("Starting A* pathfinding with %d Nodes", self.Nnodes)
  self:T(self.lid..text)

  -- Loop while we still have an open set.
  while Nopen > 0 do

    -- Expand the open node with the lowest estimated total cost.
    local current=self:_LowestFscore(openset, f_score)

    -- No finite score remains: all remaining connections are unreachable.
    if not current then
      break
    end

    -- Reconstruct only after the goal is selected, then apply the requested endpoint exclusions.
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

    -- Filter geometric candidates through the configured rule before evaluating travel costs.
    local neighbors=self:_NeighbourNodes(current, nodes)

    -- Loop over neighbours.
    for _,neighbor in pairs(neighbors) do

      if closedset[neighbor.id]==nil then

        local tentative_g_score=g_score[current.id]+self:_TravelCost(current, neighbor)

        -- Replace the predecessor only when this route improves the known cost to the neighbour.
        if tentative_g_score < (g_score[neighbor.id] or ASTAR.INF) then

          came_from[neighbor]=current

          g_score[neighbor.id]=tentative_g_score
          f_score[neighbor.id]=g_score[neighbor.id]+self:_HeuristicCost(neighbor, goal)

          if openset[neighbor.id]==nil then
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
  if StopReason then
    text=text.." (expansion stopped: "..StopReason..")"
  end
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

  if not start then
    return false, "no_start_node"
  end

  if not goal then
    return false, "no_goal_node"
  end

  if not self.GridNeighboursOnly or start.id==goal.id then
    return true
  end

  if not self.gridLinks then
    self:_BuildGridLinks()
  end

  if not (start.q~=nil or start.rectGrid==self.rectGrid and start.i~=nil) and next(self.gridLinks[start.id] or {})==nil then
    return false, "start_unattached"
  end

  if not (goal.q~=nil or goal.rectGrid==self.rectGrid and goal.i~=nil) and next(self.gridLinks[goal.id] or {})==nil then
    return false, "goal_unattached"
  end

  -- Flood the whole candidate component once; later endpoint checks can reuse its label.
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

  if components[goal.id]==component then
    return true
  end

  return false, "disconnected_grid"

end

--- Lower bound on the remaining travel cost. Custom and road costs use zero.
-- @param #ASTAR self
-- @param #ASTAR.Node nodeA Node A.
-- @param #ASTAR.Node nodeB Node B.
-- @return #number Estimated remaining cost.
function ASTAR:_HeuristicCost(nodeA, nodeB)

  if not self.CostFunc or self.CostFunc==ASTAR.Dist2D or self.CostFunc==ASTAR.CostDepth then
    return ASTAR.Dist2D(nodeA, nodeB)
  elseif self.CostFunc==ASTAR.Dist3D then
    return ASTAR.Dist3D(nodeA, nodeB)
  end

  -- Custom and road costs have no known distance lower bound; zero avoids overestimating them.
  return 0

end

--- Evaluate and cache both results of a depth-weighted connection.
-- Used by validity and cost requests, in either order. Node caches belong only to this search.
-- @param #ASTAR self
-- @param #ASTAR.Node nodeA First node.
-- @param #ASTAR.Node nodeB Second node.
-- @return #boolean Whether the connection is navigable.
-- @return #number Travel cost, or math.huge when blocked.
function ASTAR:_EvaluateDepthEdge(nodeA, nodeB)

  local valid,reason,cost=ASTAR._DepthConnection(nodeA,nodeB,unpack(self.CostArg,1,self.CostArg.n))
  cost=valid and cost or math.huge

  nodeA.valid[nodeB.id],nodeB.valid[nodeA.id]=valid,valid
  nodeA.cost[nodeB.id],nodeB.cost[nodeA.id]=cost,cost

  return valid,cost

end

--- Cached travel cost from node A to node B. Defaults to their 2D distance.
-- @param #ASTAR self
-- @param #ASTAR.Node nodeA Node A.
-- @param #ASTAR.Node nodeB Node B.
-- @return #number Travel cost.
function ASTAR:_TravelCost(nodeA, nodeB)

  -- Counter.
  self.ncost=self.ncost+1

  -- Reuse previously evaluated costs; zero is a valid cached result.
  local cost=nodeA.cost[nodeB.id]
  if cost~=nil then
    self.ncostcache=self.ncostcache+1
    return cost
  end

  local cost=nil
  if self.CostFunc==ASTAR.CostDepth and self.ValidNeighbourFunc==ASTAR.Depth
    and self.CostArg[1]==(self.ValidNeighbourArg[1] or 20) and self.CostArg[2]==(self.ValidNeighbourArg[2] or 0) then
    local valid
    valid,cost=self:_EvaluateDepthEdge(nodeA,nodeB)
  elseif self.CostFunc then
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

  -- A cached false is meaningful: blocked connections must not trigger repeated terrain checks.
  local valid=node.valid[neighbor.id]
  if valid~=nil then
    --env.info(string.format("Node %d has valid=%s neighbour %d", node.id, tostring(valid), neighbor.id))
    self.nvalidcache=self.nvalidcache+1
    return valid
  end

  local valid=nil
  if self.CostFunc==ASTAR.CostDepth and self.ValidNeighbourFunc==ASTAR.Depth
    and self.CostArg[1]==(self.ValidNeighbourArg[1] or 20) and self.CostArg[2]==(self.ValidNeighbourArg[2] or 0) then
    valid=self:_EvaluateDepthEdge(node,neighbor)
  elseif self.ValidNeighbourFunc then
    valid=self.ValidNeighbourFunc(node, neighbor, unpack(self.ValidNeighbourArg, 1, self.ValidNeighbourArg.n))
  else
    valid=true
  end

  -- Rules are required to be symmetric, allowing the reverse edge to reuse the same result.
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
    if not self.gridLinks then
      self:_BuildGridLinks()
    end
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

  for i=#flat_path,1,-1 do
    flat_path[i+count]=flat_path[i]
  end

  for i=1,count do
    flat_path[i]=reverse[count-i+1]
  end

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
-- This explicitly replaces the owned grid and accepts either geometry, even when New() selected a different type.
-- @param #ASTAR self
-- @param Core.Grid#GRID Grid Built grid.
-- @return #ASTAR self.
function ASTAR:SetGrid(Grid)

  assert(Grid and Grid.ClassName=="GRID" and Grid.GridBuilt,"ASTAR: SetGrid requires a built GRID")
  assert(not self.Grid.GridBuilt and next(self.nodes)==nil,"ASTAR: attach a grid to an unused ASTAR object")
  self.Grid=Grid
  self._GridRevision=-1
  self._CellCursor=0
  self._CellNodes={}
  self.GridNeighboursOnly=true
  self:_SyncGrid()

  return self

end

--- Get the owned or shared GRID, including before initial construction.
-- New(GridType) retains this reference through matching builders. Legacy New():CreateHexGrid()/CreateHexGridFromZone()
-- can replace the default rectangle; retrieve the grid again afterwards. SetGrid() explicitly replaces it as well.
-- @param #ASTAR self
-- @return Core.Grid#GRID Grid.
---@return GRID
function ASTAR:GetGrid()

  return self.Grid

end

--- Import new shared cells without terrain queries or changing existing nodes and caches.
-- @param #ASTAR self
-- @return #nil No return value.
function ASTAR:_SyncGrid()

  local grid=self.Grid
  if not grid or self._GridRevision==grid.Version then
    return
  end

  -- Track the filter used by validity caches, including changes made through GetGrid() before building.
  if self._ValiditySurfaceFilter~=grid.ValidSurfaceTypes then
    for _,node in pairs(self.nodes) do
      node.valid={}
    end
    self._ValiditySurfaceFilter=grid.ValidSurfaceTypes
  end

  self.hexGrid=grid.hexGrid
  self.rectGrid=grid.rectGrid
  if grid.GridBuilt and self.GridNeighboursOnly==nil then
    self.GridNeighboursOnly=true
  end

  -- Import only appended cells. Reuse their geometry, but give every search its own IDs and caches.
  for i=self._CellCursor+1,#grid.CellList do
    local cell=grid.CellList[i]
    local node={id=self.counter,vector=cell.vector,surfacetype=cell.surfacetype,
      q=cell.q,r=cell.r,i=cell.i,j=cell.j,rectGrid=cell.rectGrid,cell=cell,grid=grid,_owner=self._NodeOwner,valid={},cost={}}
    self.counter=self.counter+1
    self:AddNode(node)
  end

  -- Advance only after importing the new cells; topology caches must reflect the new grid revision.
  self._CellCursor=#grid.CellList
  self._GridRevision=grid.Version
  self.gridLinks=nil
  self.gridComponents=nil

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

--- Update supplied geometry, diagonal and expansion settings on the owned/shared grid.
-- Omitted fields are preserved, including nested Expansion fields. Use the dedicated GRID setters to clear optional values.
-- @param #ASTAR self
-- @param Core.Grid#GRID.GridOptions Options (Optional) Partial grid configuration.
-- @return #ASTAR self.
function ASTAR:SetGridOptions(Options)

  self.Grid:SetOptions(Options)
  self:_SyncGrid()

  return self

end

--- Return a copy of the current grid configuration.
-- @param #ASTAR self
-- @return Core.Grid#GRID.GridOptions Configuration copy.
---@return GRID.GridOptions
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
    -- Explicit geometry protects references held by callers; only legacy builders may replace the empty grid.
    assert(not self._GridTypeExplicit,"ASTAR: builder must match the selected grid type")
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
    if self.startVector or self.endVector then
      grid:SetBounds(self.startVector,self.endVector)
    end
    built,reason=grid:CreateFromZone(Zone)
  else
    built,reason=grid:CreateFromBounds(self.startVector,self.endVector)
  end

  -- Commit a changed geometry type only after the replacement grid has been built successfully.
  if built and grid~=self.Grid then
    self.Grid=grid
    self._GridRevision=-1
  end
  self:_SyncGrid()
  if not built then
    return nil,reason
  end

  return self

end

--- Build the owned grid using the geometry selected by New(GridType).
-- Without a zone, both search endpoints are required and GRID corridor settings define the initial area.
-- With a zone, its bounds and center membership define the initial area; both endpoints may be omitted.
-- If zone endpoints are supplied, both are required and determine orientation. Width and Margin do not crop the zone.
-- Retains the existing GRID reference. A successful build enables local neighbours and allows no second build.
-- Manual nodes may precede rectangular creation; hex creation requires an empty node set. Does not draw.
-- @param #ASTAR self
-- @param Core.Zone#ZONE_BASE Zone (Optional) Initial circular, rectangular or polygonal MOOSE zone. Nil builds from endpoints.
-- @return #ASTAR self on success, or nil when the initial candidate-cell budget is exceeded before terrain sampling.
-- @return #string cell_limit on budget rejection; nil on success.
function ASTAR:BuildGrid(Zone)

  local kind="CreateGrid"
  if self.Grid:GetType()==GRID.Type.HEXAGON then
    kind="CreateHexGrid"
  end
  if Zone~=nil then
    kind=kind.."FromZone"
  end

  return self:_CreateGrid(kind,Zone)

end

--- Legacy rectangular builder. For type-selected construction use BuildGrid().
-- Requires both endpoints and no prior grid. Retains manually added nodes and enables local topology by default. Centers have altitude zero.
-- No markers are created; call DrawGrid() or MarkGrid() explicitly.
-- @param #ASTAR self
-- @return #ASTAR self, or nil if MaxCells would be exceeded before surface filtering.
-- @return #string cell_limit on budget rejection; no nodes are added on rejection.
function ASTAR:CreateGrid()

  return self:_CreateGrid("CreateGrid")

end

--- Legacy hex builder. For type-selected construction use BuildGrid().
-- Requires both endpoints and an empty node set. CrossSpacing is not supported. Centers have altitude zero.
-- Enables six-neighbour topology by default. No drawing is performed.
-- @param #ASTAR self
-- @return #ASTAR self, or nil if MaxCells would be exceeded before surface filtering.
-- @return #string cell_limit on budget rejection; no nodes are added on rejection.
function ASTAR:CreateHexGrid()

  return self:_CreateGrid("CreateHexGrid")

end

--- Legacy rectangular zone builder. For type-selected construction use BuildGrid(Zone).
-- Requires no prior grid; endpoints optionally supply the orientation. Retains manual nodes. Uses configured spacing, MaxCells and surface types; ignores Width and Margin.
-- Checks the zone before terrain sampling. Expansion can subsequently leave the zone. No drawing is performed.
-- @param #ASTAR self
-- @param Core.Zone#ZONE_BASE Zone Initial zone.
-- @return #ASTAR self, or nil if the projected bounding-box candidates exceed MaxCells before either filter.
-- @return #string cell_limit on budget rejection.
function ASTAR:CreateGridFromZone(Zone)

  return self:_CreateGrid("CreateGridFromZone",Zone)

end

--- Legacy hex zone builder. For type-selected construction use BuildGrid(Zone).
-- Requires an empty node set; endpoints optionally supply the orientation. Uses configured Spacing, MaxCells and surface types; ignores Width and Margin.
-- Checks the zone before terrain sampling. Expansion can subsequently leave the zone. CrossSpacing is rejected.
-- @param #ASTAR self
-- @param Core.Zone#ZONE_BASE Zone Initial zone.
-- @return #ASTAR self, or nil if the projected bounding-box candidates exceed MaxCells before either filter.
-- @return #string cell_limit on budget rejection.
function ASTAR:CreateHexGridFromZone(Zone)

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
  if not grid then
    return nil,reason,limited
  end

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

--- Draw this search's grid, optionally highlighting a previously returned path.
-- Nil Path creates an extendable regular overlay; a supplied path (including {}) creates a fixed snapshot.
-- Manual nodes and exact endpoints have no polygon. The path must belong to this search, even when the GRID is shared.
-- Colors and path selection are copied. No search or route assignment is performed; polygons do not guarantee navigability.
-- The legacy positional form DrawGrid(Coalition, Color, Alpha, FillColor, FillAlpha, LineType, ReadOnly, DrawOptions) remains accepted.
-- @param #ASTAR self
-- @param #table Path (Optional) Ordered ASTAR.Node entries from this search; nil draws without highlighting.
-- @param Core.Grid#GRID.DrawOptions Options (Optional) Named style and batch settings; see GRID.DrawOptions for all fields and defaults.
-- @return #ASTAR self; inspect LastGridDrawResult for asynchronous drawing progress.
function ASTAR:DrawGrid(Path, Options, ...)

  self:_SyncGrid()

  return GRID.DrawGrid(self, Path, Options, ...)

end

--- Draw a fixed path snapshot. Compatibility alias for DrawGrid(Path, Options).
-- Nil Path is rejected; an empty successful path is accepted. Options.GridColor remains an alias for Color.
-- @param #ASTAR self
-- @param #table Path Ordered node list from a successful search on this ASTAR object.
-- @param Core.Grid#GRID.DrawOptions Options (Optional) Drawing style and batch settings.
-- @return #ASTAR self; inspect LastGridDrawResult for progress.
function ASTAR:DrawGridWithPath(Path, Options)

  return GRID.DrawGridWithPath(self, Path, Options)

end

--- Collect search-node IDs for a fixed overlay; shared GRID cell IDs are not search-node IDs.
-- @param #ASTAR self
-- @param #table Path Sequential path nodes belonging to this search.
-- @return #table Selected node IDs mapped to true.
function ASTAR:_GetPathCellIDs(Path)

  local count=GRID._PathEntryCount(Path)
  local selected={}

  for i=1,count do
    local node=Path[i]
    assert(type(node)=="table" and node._owner==self._NodeOwner and node.grid==self.Grid,
      "ASTAR: path nodes must belong to this search")

    -- Old exact endpoints may have been removed after a later search; they have no polygon.
    if node.cell then
      assert(self.nodes[node.id]==node, "ASTAR: path grid nodes must belong to this search")
      selected[node.id]=true
    end
  end

  return selected

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

--- Cancel pending work and remove this search's selected overlays, leaving other views untouched.
-- @param #ASTAR self
-- @param #string Kind (Optional) GRID.Drawing.POLYGONS, GRID.Drawing.LABELS or GRID.Drawing.ALL; default ALL.
-- @return #ASTAR self
function ASTAR:ClearDrawing(Kind)

  self:_SyncGrid()

  return GRID.ClearDrawing(self, Kind)

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
-- Read GRID's cached adjacency once; avoid sorted intermediate lists while keeping search-owned link sets.
-- @param #ASTAR self
-- @return #ASTAR self.
function ASTAR:_BuildGridLinks()

  self:_SyncGrid()
  local cellLinks=self.Grid:_GetGridLinks()
  local cellNodes=self._CellNodes
  local links={}

  for id in pairs(self.nodes) do
    links[id]={}
  end

  -- Translate shared cell IDs into this search's node IDs without sharing mutable adjacency tables.
  for _,cell in ipairs(self.Grid.CellList) do
    local neighbors=links[cellNodes[cell.id].id]
    for neighborID in pairs(cellLinks[cell.id]) do
      neighbors[cellNodes[neighborID].id]=true
    end
  end

  -- Attach exact endpoints and other manual nodes locally; do not create direct manual-to-manual links.
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
