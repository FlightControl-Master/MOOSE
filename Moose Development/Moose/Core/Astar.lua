--- **Core** - A* Pathfinding.
--
-- **Main Features:**
--
--    * Find path from A to B.
--    * Pre-defined as well as custom valid neighbour functions.
--    * Pre-defined as well as custom cost functions.
--    * Rectangular or hexagonal grids, with optional local four/eight- or six-neighbour search.
--    * Sparse search that generates cells on demand, synchronously or in bounded work slices.
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
-- @field #table GridDrawIDs F10 polygon ids owned by DrawGrid(), removed by ClearDrawing(GRID.Drawing.POLYGONS).
-- @field #table GridDrawOptions Last DrawGrid() style and batch settings, retained for incremental updates.
-- @field #table GridDrawCellIDs Drawn polygon ids indexed by grid node id.
-- @field #table GridDrawJob Pending drawing queue, or nil once completed or cancelled.
-- @field #table LastGridDrawResult Last drawing job: Status, NodesQueued, NodesDrawn, Batches, CPUSeconds, MaxBatchCPUSeconds, ElapsedSimulationSeconds and optional Error.
-- @field #table LastSearchTiming Last search attempt: CPUSeconds, Failure and Nodes. CPUSeconds is nil when os.clock is unavailable.
-- @field #string LastPathFailure Reason the last search attempt failed; nil on success or when no attempt was made.
-- @field #ASTAR.SearchReport LastSearchResult Report from the most recent public search, also returned by FindPath() or StepSearch(). Live while a LAZY/LOCAL search runs; read-only for callers.
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
-- Resolution accepts a meter spacing or GRID.Resolution preset.
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
-- # Search Without a Prebuilt Area
--
-- FindPath(ASTAR.SearchMode.LAZY) starts from the endpoints and creates neighbouring cells only as the search needs them.
-- Do not call BuildGrid() first. Configure resolution, surface filtering and MaxCells through GetGrid() as usual.
-- The first search fixes the lattice origin at the start and its orientation towards the goal. Both grid types are supported.
-- Width, Margin and expansion settings are unused. Default spacing remains 2000 meters; automatic resolution uses endpoint distance.
--
--     local search = ASTAR:New(GRID.Type.HEXAGON)
--     search:SetEndpoints(start, goal)
--     search:GetGrid():SetResolution(200):SetMaxCells(5000)
--     search:SetValidNeighbourDepth(3.5, 50)
--     search:SetCostDepth(15, 10)
--     local path, report = search:FindPath(ASTAR.SearchMode.LAZY)
--     if path then search:DrawGrid(path) end
--
-- GRID caches accepted and surface-filtered positions separately from unknown positions. Unknown terrain is never treated as blocked.
-- ASTAR retains alternative branches, including detours initially leading away from the goal; it returns only a complete path.
-- This is a search strategy, not unit steering or NAVYGROUP's moving local planning window. Narrow passages still depend on resolution.
-- The selected symmetric neighbour and cost rules apply unchanged, including depth constraints and depth preference.
-- LAZY requires local grid neighbours and an unbuilt or sparse GRID; caller-added manual nodes and prebuilt area grids are unsupported.
-- Exact endpoints attach through local grid cells and the configured edge rules, as with other local searches.
--
-- MaxCells limits all sampled lattice positions, including filtered positions and samples retained from earlier searches.
-- StopReason="cell_limit" means the budget prevented further exploration, not that the goal is unreachable. FailureReason remains nil.
-- Increase GetGrid():SetMaxCells(...) and start again to reuse the samples. No automatic spacing change or budget increase occurs.
-- Changing endpoints preserves the existing lattice and samples. Create a new ASTAR for another frame, resolution or surface filter.
-- FIXED can search the materialized subset; EXPAND is unsupported on sparse grids. DrawGrid() displays materialized cells only.
--
-- # Resumable Search
--
-- StartSearch() initializes a LAZY search and at most two endpoint cells without starting a scheduler.
-- Call StepSearch(MaxNodes, MaxSeconds) from the caller's existing update/scheduler until report.Status is no longer "running":
--
--     search:StartSearch()
--     -- In each caller-owned update:
--     local path, report = search:StepSearch(100, 0.005)
--     if report.Status ~= "running" then
--       -- Stop scheduling this search; consume path or inspect report.StopReason.
--     end
--
-- Defaults are 100 newly expanded nodes and 0.005 CPU seconds per call. The frontier and an unfinished node survive between calls.
-- Time limits are cooperative: a terrain query, callback or small neighbour-generation batch cannot be interrupted.
-- Without os.clock, only the node limit applies. SearchCPUSeconds excludes time between calls.
-- StepSearch returns nil while pending; this alone is not a failure. A completed successful path may be an empty table after exclusions.
-- Its report is a live, read-only object, also available as LastSearchResult. Completion freezes it; a new search gets a new report.
-- Status is "complete" on success, search failure or cell limit, and "cancelled" after cancellation or detected reconfiguration.
-- StopReason additionally distinguishes running, path_found, search_failed, cell_limit, cancelled and search_changed.
-- NewCandidateCells counts this search's samples; ExpandedNodes counts expansions. Width/Margin are nil for sparse grids.
--
-- CancelSearch() releases pending exploration state while retaining sampled cells. StartSearch() cancels a previous pending search.
-- Changes to endpoints, rules, grid options or externally shared grid geometry cause search_changed when resuming.
-- Restart after such a change. External data hidden inside callbacks cannot be tracked: explicitly cancel/reconfigure when it changes.
-- Callback programming errors propagate. As with synchronous searches, cached rules/costs assume unchanged external data.
-- ASTAR owns no timer; the caller must stop its own scheduling. StartSearch/StepSearch report failures without player announcements.
--
-- # Local Paths Towards a Distant Goal
--
-- SetLocalWindow(Ahead, Width, Behind) configures a finite heading-aligned window in meters. Width is the full width.
-- StartLocalSearch(start, goal, heading) starts one request; omit heading to orient the window towards the goal.
-- Configure an unbuilt owned GRID first. Each request creates a fresh private window, with copied settings and no terrain queries yet.
-- Reacquire GetGrid() after starting. Prebuilt/shared grids, manual nodes and all-pairs neighbours are unsupported.
--
--     local search = ASTAR:New(GRID.Type.HEXAGON)
--     search:GetGrid():SetResolution(100):SetMaxCells(2000)
--     search:SetValidSurfaceTypes(land.SurfaceType.WATER)
--     search:SetValidNeighbourDepth(3.5, 50):SetCostDepth(15, 10)
--     search:SetLocalWindow(3000, 2000, 1000)
--     search:StartLocalSearch(start, goal)
--     -- In each caller-owned update, until the report stops running:
--     local path, report = search:StepSearch(100, 0.005)
--
-- LOCAL uses the shared resumable search with zero exploration heuristic to settle reachable costs once for all exits.
-- A checked exact in-window goal takes priority. Otherwise, up to eight geometric frontier sectors retain one candidate each.
-- Filtering terrain does not turn an interior obstacle into a window exit. Boundary centers may lie one lattice step inside it.
-- BaseScore is checked cost plus the compatible goal estimate; custom/road costs use zero instead of Euclidean meters.
-- Compatible requests keep a fixed lattice while moving/rotating the window mask. Score adds LearnedPenalty for the same cell.
-- A completed partial search propagates all frontier estimates backwards through checked directed edges to the explored cells.
-- SetLocalLearningLimit() bounds retained scalar estimates independently of GRID MaxCells (default 4096, zero disables learning).
-- Oldest inserted cells are evicted. No old node/window graphs are retained; eviction can remove useful progress information.
-- This soft local ranking does not forbid revisits or retreats and remains in the configured cost units, with node-ID ties.
-- Goal/rule/grid changes and InvalidateLocalCache() clear learning. Failed, limited or incomplete-data jobs do not update it.
-- Partial paths are local choices, with no global optimality or dead-end escape guarantee. Exit paths can lead away from the goal.
--
-- report.Outcome is "goal_path" or "partial_path" on success, and nil otherwise. report.Candidates holds independent path lists
-- and copied Vec3 Positions; nodes remain read-only within their owning request. Candidate 1 supplies the returned path.
-- A goal_path is a plan, never confirmation of arrival. UpdateLocalProgress(actualPosition) separately records actual movement.
-- StopReason="no_local_exit" means this window produced no checked continuation; it does not prove global unreachability.
-- A cell_limit publishes no provisional candidates, even if some exits were already reached. Boolean rules cannot diagnose missing data.
-- Rejected in-window goals may still permit partial exits. Goals outside the window are not sampled or attached.
-- Built-in depth checks report DataIncomplete and UnavailableEdges; no usable exit then yields data_unavailable.
-- Missing depth results are retryable. Valid alternatives may still succeed with DataIncomplete=true.
-- LOCAL applies MaxNodes also to initialization, edges, reconstruction and learning, preserving bounded work without os.clock.
-- Individual callbacks and finite neighbour batches remain non-interruptible. No core timer or controller is installed.
--
-- Request another section by calling StartLocalSearch with its planning anchor and the overall goal. This cancels pending work,
-- clears owned drawings, and reuses a compatible fixed window or replaces it. Old paths and reports remain usable.
-- SetLocalProgress(MinDistance,HistorySize,RepeatLimit) configures bounded advisory history (defaults 10 m, 32, 3).
-- report.Progress distinguishes unobserved, observed, repeated_planning and loop_detected. Future anchors are not movement.
-- ResetLocalProgress() clears movement diagnostics only. InvalidateLocalCache() clears learned costs and forces fresh samples.
-- Reapply rule/cost setters after changing arguments; custom callbacks are evaluated again for each new request.
-- NAVYGROUP consumes these local requests and owns ship safety, steering and scheduling. Use a separate ASTAR for full LAZY searches.
--
-- # Visual Debug
--
-- Building, searching and expanding never draw or update an overlay automatically.
-- DrawGrid() draws cell outlines; UpdateGridDrawing() explicitly appends missing cells after enlargement.
-- DrawGrid(path, options) creates a one-time snapshot with green path cells; later searches and updates do not change it.
-- DrawGrid(nil, options) styles a regular overlay. GRID.DrawOptions lists all named style and batch settings.
-- DrawGrid(path, {ColorByDepth=true, DepthMin=3.5, DepthMax=15}) colors cells by center depth and keeps green path outlines.
-- The display range is independent of search-depth rules/costs. Depth is sampled during drawing; it does not describe the whole cell.
-- ClearDrawing(Kind) cancels work and removes owned polygons, labels or both, using GRID.Drawing constants; default ALL.
-- Use DrawGrid(Path, Options) and ClearDrawing(Kind). GRID documents migration from the removed development aliases.
-- Grid and path overlays support timed batches and a CPU budget. One DCS call cannot be interrupted, so the budget is a soft limit.
-- ClearDrawing(GRID.Drawing.POLYGONS) cancels queued polygon work and removes only this object's polygons.
--
-- MarkGrid() creates separate text labels with ids, grid indices and candidate-neighbor counts. CheckNeighbours=true additionally evaluates valid connections.
-- Counts are evaluated when a batch runs. Keep the graph and rule unchanged while marking for a consistent snapshot.
-- Labels include manual endpoints, and use the same batching defaults as drawing: BatchSize=25, Interval=0.1, MaxBatchSeconds=0.005.
-- Without a CPU clock, both drawing and marking process one node per batch. LastGridDrawResult and LastGridMarkResult report progress and errors.
-- ClearDrawing(GRID.Drawing.LABELS) cancels queued text work and removes text labels without touching polygons. A new MarkGrid() replaces previous labels.
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

--- Search modes. FindPath accepts FIXED, EXPAND and LAZY; LOCAL is started through StartLocalSearch only.
-- @type ASTAR.SearchMode
-- @field #string FIXED Search the current graph once without enlarging it. The default mode.
-- @field #string EXPAND Retry with a larger grid after failure, stopping at the first path or a configured limit.
-- @field #string LAZY Generate cells on demand on an unbuilt or sparse grid, bounded by MaxCells.
-- @field #string LOCAL Explore an owned finite window through StartLocalSearch/StepSearch, returning a partial or exact-goal path.
ASTAR.SearchMode = {
  LOCAL = "local",
  LAZY = "lazy",
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

--- Result details returned by FindPath() or StepSearch(). Each new search creates a new report and attempt list.
-- The same report is stored in LastSearchResult (and LastExpansionResult for EXPAND); treat it as read-only.
-- LAZY/LOCAL reports update in place while running, then remain stable. Settings/counts never reference mutable configuration tables.
-- @type ASTAR.SearchReport
-- @field #string Mode ASTAR.SearchMode.FIXED, EXPAND, LAZY or LOCAL.
-- @field #string Status LAZY/LOCAL: running, complete or cancelled. A complete search may have failed or reached its cell limit.
-- @field #table Attempts Ordered ASTAR.SearchAttempt entries; empty while LAZY/LOCAL is running or if expansion was rejected before any search.
-- @field #string StopReason FIXED: path_found or search_failed. EXPAND adds attempt_limit, size_limit, cell_limit or missing_coordinates. LAZY/LOCAL: running, path_found, search_failed, cell_limit, cancelled or search_changed. LOCAL adds no_local_exit and data_unavailable (no usable exit with missing depth data, not proven unreachability).
-- @field #string FailureReason Last attempt failure: missing_coordinates, no_start_node, no_goal_node, start_unattached, goal_unattached, disconnected_grid or connections_blocked. LOCAL also has no_local_exit. Nil on success or when no attempt was made.
-- @field #number Width Final grid width in meters; nil without an area grid (including LAZY).
-- @field #number Margin Final grid margin in meters; nil without an area grid (including LAZY).
-- @field #number Spacing LAZY/LOCAL lattice spacing in meters; nil before construction.
-- @field #number Nodes Final search-node count, including manual and exact endpoint nodes.
-- @field #number CandidateCells Budgeted grid-cell count before filtering; nil without a built grid.
-- @field #number NewCandidateCells LAZY/LOCAL: positions sampled during this search, excluding earlier cached samples.
-- @field #number ExpandedNodes LAZY/LOCAL: node expansions processed so far.
-- @field #number MaxCells Configured grid-cell limit; nil without a built grid. FIXED searches do not enforce expansion limits.
-- @field #number MaxWidth Optional expansion width limit in meters; nil without a built grid or configured limit.
-- @field #number MaxMargin Optional expansion margin limit in meters; nil without a built grid or configured limit.
-- @field #boolean BudgetLimited EXPAND: a step was reduced to fit MaxCells. LAZY/LOCAL: stopped at cell_limit. Always false for FIXED.
-- @field #number SearchCPUSeconds Total search and enlargement CPU time in seconds; nil when no CPU clock is available.
-- @field #string Outcome LOCAL success only: partial_path or goal_path. Neither means the moving object has arrived.
-- @field #number RequestID LOCAL request number within this ASTAR instance.
-- @field #number WindowID LOCAL fixed-frame generation; increases only when the window is replaced.
-- @field #boolean WindowReused LOCAL: retained the compatible previous fixed window.
-- @field DCS#Vec3 PlanningStart LOCAL: copied requested anchor, which may differ from Window.Origin.
-- @field #table Window LOCAL copied Origin (Vec3), Heading (degrees), Ahead, Width and Behind (meters).
-- @field #boolean GoalInside LOCAL: whether the requested destination is geometrically inside this window.
-- @field #string GoalFailure LOCAL: no_goal_node when the in-window goal fails its surface filter; partial exits may still succeed.
-- @field #table Candidates LOCAL: up to eight ASTAR.LocalCandidate records, best first; empty until successful completion.
-- @field #number CandidateCount LOCAL: number of published candidates.
-- @field #number LearningEntries LOCAL: retained cell estimates, at most LearningLimit.
-- @field #number LearningLimit LOCAL: independent cell-memory limit, default 4096.
-- @field #number LearningUpdatedCells LOCAL: cell updates in the committed request, including entries evicted at capacity.
-- @field #number LearningWorkItems LOCAL: cooperative clone/seed/propagation/storage work items.
-- @field #boolean LearningUpdated LOCAL: this completed partial request committed changed estimates.
-- @field #number WorkItems LOCAL: bounded work items, including preparation, result construction and cell learning.
-- @field #number RetainedCells LOCAL: accepted cells retained in the current window; CandidateCells also counts filtered samples.
-- @field #number ValidityCacheHits LOCAL: validity cache hits during this request.
-- @field #number CostCacheHits LOCAL: travel-cost cache hits during this request.
-- @field #number RestoredCacheEntries LOCAL: copied cell-to-cell validity and cost entries, counting directions separately.
-- @field #boolean DataIncomplete LOCAL: at least one depth edge check lacked usable data. Returned paths still contain only validated edges; alternatives may be unknown.
-- @field #number UnavailableEdges LOCAL: distinct undirected edges with unavailable depth data during this request.
-- @field #table UnavailableReasons LOCAL: counts by depth failure cause, counting each edge once at its first failure.
-- @field #table FirstUnavailableEdge LOCAL: first missing-data Reason, From and To (copied Vec3 positions), or nil.
-- @field #ASTAR.LocalProgress Progress LOCAL: independent observation snapshot; live until completion, then stable.

--- Advisory diagnostics from explicitly observed positions, not from planning anchors or elapsed time.
-- Repeated planning counts completed partial requests near the latest observed position without intervening movement.
-- Loop detection counts repeated directed transitions in the bounded history; it does not prove a navigation failure.
-- @type ASTAR.LocalProgress
-- @field #string Status unobserved, observed, repeated_planning or loop_detected. Does not block searching or claim arrival.
-- @field DCS#Vec3 Position Last accepted actual position, copied; nil before the first observation.
-- @field #number HistoryCount Retained accepted positions, bounded by HistorySize.
-- @field #number Distance Accumulated horizontal observed displacement in meters since reset/goal change.
-- @field #number RepeatedPlans Completed partial requests near the actual position since the last accepted movement.
-- @field #number LoopCount Occurrences of the latest directed transition, including itself, in the retained history.

--- One completed local alternative. Treat this record, its path and copied positions as read-only.
-- Separate candidates own their path/position lists; path nodes are shared within the owning request.
-- @type ASTAR.LocalCandidate
-- @field #table Path Ordered ASTAR nodes, including the planning start and checked endpoint.
-- @field #table Positions Independent Vec3 copies for consumers retaining a route beyond this window's lifetime.
-- @field #number Cost Checked travel cost in the configured cost units.
-- @field #number BaseScore Cost plus the compatible goal heuristic; custom/road costs add zero, never meters.
-- @field #number LearnedPenalty Non-negative continuation-cost increase for the same stable lattice cell; zero for an exact goal.
-- @field #number Score BaseScore plus LearnedPenalty, used for local candidate ranking. Not a global lower bound.
-- @field #number Length Horizontal polyline length in meters, independent of the cost metric.
-- @field #number RemainingDistance Horizontal straight-line distance from the endpoint to the overall goal, in meters.
-- @field #boolean ReachesGoal True only when the exact requested goal was reached under the current endpoint metric.
-- @field #number Sector Partial exits only: 1 forward, 2 forward-right, 3 right, 4 rear-right, 5 rear, 6 rear-left, 7 left, 8 forward-left.

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

--- Result of an independent connection evaluation.
-- @type ASTAR.ConnectionReport
-- @field #boolean Valid True only when the rule accepts and the cost is finite.
-- @field #number Cost Configured travel cost, or math.huge on rejection. Custom costs retain their own units.
-- @field #string Status clear, blocked or unavailable. Only built-in depth checks identify missing terrain data.
-- @field #string Reason Rejection cause, or nil on success.
-- @field #string Stage rule, cost or configuration on rejection.
-- @field DCS#Vec3 Start Copy of the original start.
-- @field DCS#Vec3 Goal Copy of the original goal.
-- @field #table Depth Optional built-in depth evidence: RequiredDepth, CorridorWidth, Point, Depth, SurfaceType,
-- Cause, Location and ProfileOffset. Location/offset refer to the original input direction; positive offset is right.
-- Point contains usable numeric coordinates only; unknown height is omitted.
-- Evidence identifies the first rejected sample, not the first obstruction distance or a safe prefix.

--- Evaluate one fresh connection using the configured neighbour rule and travel cost.
-- Accepts arbitrary positions, including outside the current grid/window. Does not apply graph adjacency or
-- the cell surface filter; SetValidNeighbourSurface applies its configured surface rule as usual.
-- Returns independent data without changing endpoints, nodes, caches, counters, reports or a pending search.
-- Compatible built-in depth validity/cost use one evaluation, preserving failure evidence without a second query.
-- Custom callbacks receive temporary nodes (id 1/2, vector, surfacetype, empty valid/cost tables), without cell
-- membership. Their extra arguments, including trailing nil, are preserved; exceptions propagate.
-- Callbacks should not reconfigure the search; detected rule/cost replacement returns configuration_changed.
-- This checks a connection, not ship turning clearance. Depth uses center/edge profiles and linear samples.
-- @param #ASTAR self
-- @param Core.Vector#VECTOR Start Finite position; also COORDINATE, DCS Vec2 or Vec3.
-- @param Core.Vector#VECTOR Goal Finite position; also COORDINATE, DCS Vec2 or Vec3.
-- @return #boolean Whether the connection passes its rule and has a finite cost.
-- @return #number Travel cost or math.huge.
-- @return #ASTAR.ConnectionReport Caller-owned result.
function ASTAR:EvaluateConnection(Start, Goal)

  local first={id=1,vector=self.Grid:_PositionVector(Start),valid={},cost={}}
  local last={id=2,vector=self.Grid:_PositionVector(Goal),valid={},cost={}}
  local rule,ruleArgs=self.ValidNeighbourFunc,self.ValidNeighbourArg
  local costFunction,costArgs=self.CostFunc,self.CostArg
  local report={Start=first.vector:GetVec3(),Goal=last.vector:GetVec3()}

  local function current()
    return self.ValidNeighbourFunc==rule and self.ValidNeighbourArg==ruleArgs
      and self.CostFunc==costFunction and self.CostArg==costArgs
  end

  local function finish(valid,cost,status,reason,stage)
    if valid and cost==math.huge then
      valid,status,reason,stage=false,"blocked","cost_blocked","cost"
    end
    if not current() then
      valid,cost,status,reason,stage=false,math.huge,"unavailable","configuration_changed","configuration"
    end
    report.Valid,report.Cost,report.Status=valid,cost,status
    report.Reason,report.Stage=reason,stage
    return valid,cost,report
  end

  local function depth(arguments,includeCost)
    local evidence={}
    report.Depth=evidence
    local preferred,weight
    if includeCost then
      preferred,weight=arguments[3],arguments[4]
    end
    return ASTAR._DepthConnection(first,last,arguments[1],arguments[2],preferred,weight,evidence)
  end

  local combined=rule==ASTAR.Depth and costFunction==ASTAR.CostDepth
    and costArgs[1]==(ruleArgs[1] or 20) and costArgs[2]==(ruleArgs[2] or 0)
  if combined then
    local valid,reason,cost,status=depth(costArgs,true)
    return finish(valid,valid and cost or math.huge,status,reason,not valid and "rule" or nil)
  end

  -- Custom node callbacks retain the surface metadata normally supplied by CreateNode.
  local customRule=rule and rule~=ASTAR.Depth and rule~=ASTAR.LoS and rule~=ASTAR.DistMax and rule~=ASTAR.Road
  local customCost=costFunction and costFunction~=ASTAR.CostDepth and costFunction~=ASTAR.Dist2D
    and costFunction~=ASTAR.Dist3D and costFunction~=ASTAR.DistRoad
  if customRule or customCost then
    first.surfacetype=first.vector:GetSurfaceType()
    last.surfacetype=last.vector:GetSurfaceType()
  end

  local valid,reason,status=true,nil,"clear"
  if rule==ASTAR.Depth then
    local ignoredCost
    valid,reason,ignoredCost,status=depth(ruleArgs)
  elseif rule then
    valid=not not rule(first,last,unpack(ruleArgs,1,ruleArgs.n))
    status=valid and "clear" or "blocked"
    reason=not valid and "rule_rejected" or nil
  end
  if not valid or not current() then
    return finish(false,math.huge,status,reason,"rule")
  end

  local cost
  if costFunction==ASTAR.CostDepth then
    valid,reason,cost,status=depth(costArgs,true)
    if not valid then
      return finish(false,math.huge,status,reason,"cost")
    end
  elseif costFunction then
    cost=costFunction(first,last,unpack(costArgs,1,costArgs.n))
  else
    cost=ASTAR.Dist2D(first,last)
  end
  assert(type(cost)=="number" and cost>=0,"ASTAR: travel cost must be a non-negative number or math.huge")
  if cost==math.huge then
    return finish(false,cost,"blocked","cost_blocked","cost")
  end

  return finish(true,cost,"clear")

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

--- Retain rejection evidence only when requested by independent connection evaluation.
-- The point copy prevents native profile data from escaping into caller-owned reports.
function ASTAR._SetDepthEvidence(Evidence, Point, Location, Cause, Depth, Surface)

  if Evidence then
    Evidence.Location, Evidence.Cause=Location,Cause
    Evidence.Depth, Evidence.SurfaceType=Depth,Surface
    if type(Point)=="table" and type(Point.x)=="number" and math.abs(Point.x)<math.huge
      and type(Point.z)=="number" and math.abs(Point.z)<math.huge then
      -- Invalid native values may be tables; retain only usable numeric coordinates.
      local height=type(Point.y)=="number" and math.abs(Point.y)<math.huge and Point.y or nil
      Evidence.Point={x=Point.x,y=height,z=Point.z}
    end
  end

end

--- Check the endpoints and terrain profile of one water connection, optionally retaining depths for costs.
-- The first rejection ends this check. Locating an obstruction belongs to PATHLINE.CheckDepth().
-- @param DCS#Vec3 Start Start position at the water surface.
-- @param DCS#Vec3 Goal Goal position at the water surface.
-- @param #number Distance Horizontal distance between the endpoints, greater than zero.
-- @param #number MinDepth Minimum water depth in meters, inclusive.
-- @param #table Samples (Optional) Receives pairs of projected distance and depth for cost integration.
-- @param #table Evidence (Optional) Receives the first rejection sample and cause.
-- @return #boolean True when the connection is sufficiently deep water.
-- @return #string Reason for rejection, or nil on success.
-- @return #string clear, blocked or unavailable.
function ASTAR._CheckDepthLine(Start, Goal, Distance, MinDepth, Samples, Evidence)

  -- DCS may omit the endpoints from its profile. Always check their actual depths as well.
  for i=1,2 do
    local point=i==1 and Start or Goal
    local clear,status,cause,depth,surface=VECTOR._CheckDepthPoint(point,MinDepth,false)

    if not clear then
      ASTAR._SetDepthEvidence(Evidence,point,i==1 and "start" or "goal",cause,depth,surface)
      return false,status=="unavailable" and cause or (i==1 and "start_blocked" or "goal_blocked"),status
    end

    if Samples then Samples[#Samples+1]={i==1 and 0 or Distance,depth} end
  end

  local profile=PATHLINE._QueryDepthProfile(Start,Goal)
  if type(profile)~="table" then
    ASTAR._SetDepthEvidence(Evidence,nil,"profile","profile_unavailable")
    return false,"profile_unavailable","unavailable"
  end

  -- Under the linear-profile assumption, valid support points also bound the depths between them.
  for i=1,#profile do
    local point=profile[i]
    local clear,status,cause,depth,surface=VECTOR._CheckDepthPoint(point,MinDepth,true)

    if not clear then
      ASTAR._SetDepthEvidence(Evidence,point,"profile",cause,depth,surface)
      return false,status=="unavailable" and cause or "profile_blocked",status
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
      ASTAR._SetDepthEvidence(Evidence,nil,"profile_fallback","profile_fallback_limit")
      return false,"profile_fallback_limit","unavailable"
    end

    for i=1,intervals-1 do
      local fraction=i/intervals
      local point={x=Start.x+(Goal.x-Start.x)*fraction,z=Start.z+(Goal.z-Start.z)*fraction}
      local clear,status,cause,depth,surface=VECTOR._CheckDepthPoint(point,MinDepth,false)

      if not clear then
        ASTAR._SetDepthEvidence(Evidence,point,"profile_fallback",cause,depth,surface)
        return false,status=="unavailable" and cause or "profile_fallback_blocked",status
      end

      if Samples then Samples[#Samples+1]={fraction*Distance,depth} end
    end
  end

  return true,nil,"clear"

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
-- @return #number Horizontal distance on success, or nil.
-- @return #string clear, blocked or unavailable. Missing data must not be cached as a measured obstruction.
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
-- @return #string Depth rejection reason, or nil.
-- @return #string clear, blocked or unavailable.
function ASTAR.CostDepth(nodeA, nodeB, MinDepth, CorridorWidth, PreferredDepth, Weight)

  local clear,reason,cost,status=ASTAR._DepthConnection(nodeA,nodeB,MinDepth,CorridorWidth,PreferredDepth,Weight)
  return clear and cost or math.huge,reason,status

end

--- Evaluate depth validity and optional cost together, without querying a profile twice.
-- Plain validity checks retain the early-exit path and do not allocate or sort cost samples.
-- @param #ASTAR.Node nodeA First node.
-- @param #ASTAR.Node nodeB Second node.
-- @param #number MinDepth (Optional) Minimum depth in meters; default 20.
-- @param #number CorridorWidth (Optional) Total corridor width in meters; default 0.
-- @param #number PreferredDepth (Optional) Preferred depth in meters; nil disables the penalty.
-- @param #number Weight (Optional) Non-negative penalty strength; default 2.
-- @param #table Evidence (Optional) Receives rejection details relative to the original input direction.
-- @return #boolean Whether the connection is navigable.
-- @return #string Rejection reason, or nil.
-- @return #number Travel cost on success.
-- @return #string clear, blocked or unavailable.
function ASTAR._DepthConnection(nodeA, nodeB, MinDepth, CorridorWidth, PreferredDepth, Weight, Evidence)

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
  if Evidence then
    Evidence.RequiredDepth, Evidence.CorridorWidth=MinDepth,CorridorWidth
  end
  local profiles=PreferredDepth and PreferredDepth>MinDepth and Weight>0 and {} or nil

  local a,b=nodeA.vector,nodeB.vector
  local dx,dz=b.x-a.x,b.z-a.z
  local distance=math.sqrt(dx*dx+dz*dz)

  if not (distance<math.huge) then
    ASTAR._SetDepthEvidence(Evidence,nil,nil,"invalid_distance")
    return false,"invalid_distance",nil,"unavailable"
  end

  if distance==0 then
    local clear,status,cause,depth,surface=VECTOR._CheckDepthPoint(a,MinDepth,false)
    if not clear then
      ASTAR._SetDepthEvidence(Evidence,a,"start",cause,depth,surface)
      if Evidence then Evidence.ProfileOffset=0 end
    end
    return clear,not clear and (status=="unavailable" and cause or "start_blocked") or nil,clear and 0 or nil,status
  end

  -- Query DCS in the same direction for A -> B and B -> A, matching A*'s symmetric validity cache.
  local reverse=a.x>b.x or (a.x==b.x and a.z>b.z)
  if reverse then
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
    local clear,reason,status=ASTAR._CheckDepthLine(start,goal,distance,MinDepth,samples,Evidence)

    if not clear then
      if Evidence then
        Evidence.ProfileOffset=reverse and -offset or offset
        if reverse and (Evidence.Location=="start" or Evidence.Location=="goal") then
          Evidence.Location=Evidence.Location=="start" and "goal" or "start"
          if status=="blocked" then reason=Evidence.Location.."_blocked" end
        end
      end
      return false,reason,nil,status
    end

    if profiles then profiles[#profiles+1]=samples end
  end

  local cost=distance
  if profiles then cost=cost+Weight*ASTAR._DepthPenalty(profiles,distance,MinDepth,PreferredDepth) end

  return true,nil,cost,"clear"

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
  if (node and distance>1e-6) or (not node and self.Grid.Sparse) then
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
-- Sparse grids only resolve endpoints: unknown cells may still connect them, so this is not a connectivity proof.
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
-- LAZY creates cells on demand on an unbuilt or sparse grid, without BuildGrid() or an enclosing area.
-- Does not draw or assign routes to units. The selected cost and neighbour rules apply in all modes.
-- Invalid modes/flags are rejected before searching. A final search failure is announced once; Debug controls player messages.
-- @param #ASTAR self
-- @param #string Mode (Optional) ASTAR.SearchMode.FIXED, EXPAND or LAZY; nil selects FIXED.
-- @param #boolean ExcludeStartNode (Optional) Exclude the selected start node; default false.
-- @param #boolean ExcludeEndNode (Optional) Exclude the selected goal node; default false.
-- @return #table Ordered ASTAR.Node list, or nil on failure. An empty table is a successful path.
-- @return #ASTAR.SearchReport New report, also stored in LastSearchResult. FailureReason is the last search error; StopReason explains why searching stopped.
function ASTAR:FindPath(Mode, ExcludeStartNode, ExcludeEndNode)

  if Mode==nil then
    Mode=ASTAR.SearchMode.FIXED
  end
  assert(Mode==ASTAR.SearchMode.FIXED or Mode==ASTAR.SearchMode.EXPAND or Mode==ASTAR.SearchMode.LAZY,
    "ASTAR: FindPath accepts FIXED, EXPAND or LAZY; use StartLocalSearch for LOCAL")
  assert(ExcludeStartNode==nil or type(ExcludeStartNode)=="boolean", "ASTAR: endpoint exclusion flags must be booleans")
  assert(ExcludeEndNode==nil or type(ExcludeEndNode)=="boolean", "ASTAR: endpoint exclusion flags must be booleans")
  assert(Mode~=ASTAR.SearchMode.EXPAND or not self.Grid.Sparse, "ASTAR: use LAZY to grow a sparse grid")

  if Mode==ASTAR.SearchMode.LAZY then
    self:StartSearch(ExcludeStartNode,ExcludeEndNode)
    local path,report=self:StepSearch(1000,1)
    while report.Status=="running" do
      path,report=self:StepSearch(1000,1)
    end
    if not path then
      self:_ReportPathFailure(report.FailureReason or report.StopReason)
    end
    return path,report
  end

  self:CancelSearch()
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

-- Lazy searches keep one heap entry per open node. Stable ties make results independent of pairs() order.
local function lazyEarlier(a,b)
  if a.Score~=b.Score then
    return a.Score<b.Score
  end
  if a.Estimate~=b.Estimate then
    return a.Estimate<b.Estimate
  end
  return a.Node.id<b.Node.id
end

local function lazyPush(state,node,score,estimate)
  local heap,positions=state.Open,state.OpenPositions
  local index=positions[node.id] or (#heap+1)
  local entry=heap[index] or {Node=node}
  entry.Score,entry.Estimate=score,estimate
  while index>1 do
    local parent=math.floor(index/2)
    if not lazyEarlier(entry,heap[parent]) then
      break
    end
    heap[index]=heap[parent]
    positions[heap[index].Node.id]=index
    index=parent
  end
  heap[index]=entry
  positions[node.id]=index
end

local function lazyPop(state)
  local heap,positions=state.Open,state.OpenPositions
  local first=heap[1]
  if not first then
    return nil
  end
  local last=table.remove(heap)
  positions[first.Node.id]=nil
  if #heap>0 then
    local index=1
    while index*2<=#heap do
      local child=index*2
      if child<#heap and lazyEarlier(heap[child+1],heap[child]) then
        child=child+1
      end
      if not lazyEarlier(heap[child],last) then
        break
      end
      heap[index]=heap[child]
      positions[heap[index].Node.id]=index
      index=child
    end
    heap[index]=last
    positions[last.Node.id]=index
  end
  return first.Node
end

--- Configure the fixed extent of each local planning window. No default window is assumed.
-- A new configuration cancels pending local work with search_changed on the next StepSearch().
-- Does not change an already returned path or rebuild a window immediately.
-- @param #ASTAR self
-- @param #number Ahead Positive forward extent in meters from the requested planning start.
-- @param #number Width Positive total width in meters, half on each side of the heading.
-- @param #number Behind Non-negative rear extent in meters; zero allows no rear cell centers.
-- @return #ASTAR self.
function ASTAR:SetLocalWindow(Ahead, Width, Behind)

  assert(type(Ahead)=="number" and Ahead>0 and Ahead<math.huge, "ASTAR: Ahead must be finite and positive")
  assert(type(Width)=="number" and Width>0 and Width<math.huge, "ASTAR: Width must be finite and positive")
  assert(type(Behind)=="number" and Behind>=0 and Behind<math.huge, "ASTAR: Behind must be finite and non-negative")
  assert(Ahead+Behind<math.huge, "ASTAR: local window length must be finite")
  self._LocalWindow={Ahead=Ahead,Width=Width,Behind=Behind}

  return self

end

--- Start one local request without starting a timer or sampling terrain.
-- Requires SetLocalWindow() and an unbuilt owned GRID or the previous local window. Attached/built non-local grids
-- and manual nodes are rejected. Configure resolution, surface types and MaxCells through GetGrid() beforehand.
-- Reuses a fixed window only with unchanged configuration/rules, a heading change at most 10 degrees, and
-- an anchor within [-Behind/4,Ahead/4] along and +/-Width/8 across its original frame. Otherwise creates a new window.
-- Each request owns new nodes/caches. Known built-in rule/cost pairs reuse copied cell-edge results; custom callbacks
-- are evaluated again because they may depend on node identity. Exact endpoint caches are never carried forward.
-- Compatible requests retain lattice indices/world centers across new window origins and headings.
-- Completed partial requests learn continuation costs throughout the explored area; SetLocalLearningLimit() bounds memory.
-- Exit scores use these estimates to discourage returning to locally costly regions; no exit is forbidden by history.
-- Goal/configuration changes clear learning. Exact-goal preference and physical path costs remain unchanged.
-- External terrain or callback-state changes require InvalidateLocalCache(). Reacquire GetGrid() for drawing;
-- old owned drawings are cleared at every request. Caller-held older paths/results remain usable and consume caller memory.
-- Start/Goal are copied. Heading defaults towards Goal, or zero for coincident horizontal positions.
-- The distant goal supplies direction only: it is sampled/attached only when inside the window.
-- Use StepSearch()/CancelSearch() as for LAZY. Supply actual movement separately through UpdateLocalProgress().
-- @param #ASTAR self
-- @param #table Start Planning anchor; VECTOR, COORDINATE, Vec2 or Vec3. May be a future route endpoint.
-- @param #table Goal Overall destination, in the same position formats.
-- @param #number Heading (Optional) Finite degrees clockwise from DCS +x towards +z.
-- @return #ASTAR self. LastSearchResult is the new running report.
function ASTAR:StartLocalSearch(Start, Goal, Heading)

  local options=assert(self._LocalWindow,"ASTAR: call SetLocalWindow before StartLocalSearch")
  assert(not self.Grid.GridBuilt or self.Grid==self._LocalGrid, "ASTAR: local searches require an owned unbuilt grid or previous local window")
  assert(self.GridNeighboursOnly~=false, "ASTAR: local searches require grid neighbours")
  for id,node in pairs(self.nodes) do
    assert(node.cell or self._EndpointNodes[id]==node, "ASTAR: local searches do not accept caller-added manual nodes")
  end

  local clock=startCPUClock()
  local startVector=self.Grid:_PositionVector(Start)
  local endVector=self.Grid:_PositionVector(Goal)
  local distance=startVector:GetDistance(endVector,true)
  assert(distance<math.huge, "ASTAR: endpoint distance must be finite")
  local heading=Heading
  if heading==nil then
    heading=0
    if distance>0 then
      heading=startVector:GetHeadingTo(endVector)
    end
  end
  local previous=self._LazySearch
  local compatible=previous and previous.Local and self:_IsLazySearchCurrent(previous)
  local lattice=compatible and (self.Grid.hexGrid or self.Grid.rectGrid) or nil
  local window=self.Grid:_NewSparseWindow(startVector,heading,options.Ahead,options.Width,options.Behind,lattice)
  local reuse=compatible and self.Grid:_CanReuseSparseWindow(startVector,heading,options)
  local restore
  if reuse then
    window=self.Grid
    local rule,cost=self.ValidNeighbourFunc,self.CostFunc
    local standardRule=rule==nil or rule==ASTAR.Depth or rule==ASTAR.LoS or rule==ASTAR.DistMax or rule==ASTAR.Road
    local standardCost=cost==nil or cost==ASTAR.Dist2D or cost==ASTAR.Dist3D or cost==ASTAR.DistRoad or cost==ASTAR.CostDepth
    restore={Nodes=self.nodes,CellNodes=self._CellNodes,Index=1,Cache="valid",Edges=standardRule and standardCost}
  end

  -- Validate all new inputs before cancelling useful work or replacing its drawings and ownership.
  self:CancelSearch()
  self:ClearDrawing()
  if self._LocalGrid then
    self._LocalGrid:ClearDrawing()
  end
  self.Grid=window
  self._LocalGrid=window
  self.nodes={}
  self.counter,self.Nnodes=1,0
  self._CellNodes,self._EndpointNodes={},{}
  self._NodeOwner={}
  self._CellCursor,self._GridRevision=0,-1
  self.startNode,self.endNode=nil,nil
  self.startVector,self.endVector=startVector,endVector
  self.hexGrid,self.rectGrid=window.hexGrid,window.rectGrid
  self.GridNeighboursOnly=true
  self._ValiditySurfaceFilter=window.ValidSurfaceTypes
  self.gridLinks,self.gridComponents=nil,nil
  if not reuse then
    self:_SyncGrid()
    self._LocalWindowID=(self._LocalWindowID or 0)+1
  end

  self._LocalRequestID=(self._LocalRequestID or 0)+1
  local state={
    Local=true, Running=true, Phase=reuse and "restore_nodes" or "start", Grid=window, WindowOptions=options,
    Restore=restore,
    Open={}, OpenPositions={}, Scores={}, Previous={}, EndpointIndices={}, Exits={},
    Expanded=0, WorkItems=0, InitialCandidates=window:GetCandidateCount(),
    Target={vector=endVector}, GoalInside=window:_IsInsideWindow(endVector),
    InitialValidHits=self.nvalidcache, InitialCostHits=self.ncostcache,
    Report={
      Mode=ASTAR.SearchMode.LOCAL, Status="running", StopReason="running", Attempts={},
      BudgetLimited=false, SearchCPUSeconds=clock and 0 or nil,
      RequestID=self._LocalRequestID, WindowID=self._LocalWindowID,
      WindowReused=reuse and true or false, RestoredCacheEntries=0,
      UnavailableEdges=0, UnavailableReasons={}, DataIncomplete=false,
      PlanningStart=startVector:GetVec3(),
      Candidates={}, CandidateCount=0,
      Window={Origin=window.startVector:GetVec3(),Heading=window._SparseWindow.Heading,
        Ahead=options.Ahead,Width=options.Width,Behind=options.Behind},
    },
  }
  self._LazySearch=state
  self.LastSearchResult=state.Report
  self.LastPathFailure=nil
  state.StartVector,state.EndVector=self.startVector,self.endVector
  state.CostFunction,state.CostArguments=self.CostFunc,self.CostArg
  state.NeighbourFunction,state.NeighbourArguments=self.ValidNeighbourFunc,self.ValidNeighbourArg
  state.Options,state.GridVersion=window.GridOptions,window.Version
  state.NodeCount=self.Nnodes
  self:_BeginLocalProgress(state)
  self:_BeginLocalLearning(state,compatible)
  self:_UpdateLazyReport(state,clock)

  return self

end

--- Invalidate local terrain samples, connection caches and learned continuation costs after external inputs change.
-- Use after changing hidden callback state or terrain data; rule/cost setters already invalidate reuse.
-- Pending work ends with search_changed. The next request creates a fresh window. Completed results remain unchanged.
-- @param #ASTAR self
-- @return #ASTAR self.
function ASTAR:InvalidateLocalCache()

  self._LocalCacheRevision=(self._LocalCacheRevision or 0)+1
  self._LocalLearning=nil
  return self

end

--- Configure actual-movement diagnostics, resetting previous observations.
-- Diagnostics are advisory: neither repeated planning nor a loop prevents another local request.
-- @param #ASTAR self
-- @param #number MinDistance (Optional) Minimum accepted horizontal displacement in meters; default 10, finite and positive.
-- @param #number HistorySize (Optional) Maximum retained positions; integer 4..256, default 32.
-- @param #number RepeatLimit (Optional) Repeated plans or directed transitions needed for a warning; integer 2..HistorySize-1, default 3.
-- @return #ASTAR self.
function ASTAR:SetLocalProgress(MinDistance, HistorySize, RepeatLimit)

  if MinDistance==nil then
    MinDistance=10
  end
  if HistorySize==nil then
    HistorySize=32
  end
  if RepeatLimit==nil then
    RepeatLimit=3
  end
  assert(type(MinDistance)=="number" and MinDistance>0 and MinDistance<math.huge,
    "ASTAR: progress distance must be finite and positive")
  assert(type(HistorySize)=="number" and HistorySize>=4 and HistorySize<=256 and HistorySize==math.floor(HistorySize),
    "ASTAR: progress history must contain 4..256 positions")
  assert(type(RepeatLimit)=="number" and RepeatLimit>=2 and RepeatLimit<HistorySize and RepeatLimit==math.floor(RepeatLimit),
    "ASTAR: progress repeat limit must be an integer in 2..HistorySize-1")
  self._LocalProgressOptions={MinDistance=MinDistance,HistorySize=HistorySize,RepeatLimit=RepeatLimit}
  return self:ResetLocalProgress()

end

--- Forget movement observations and repeated-planning diagnostics without changing a search or its results.
-- @param #ASTAR self
-- @return #ASTAR self.
function ASTAR:ResetLocalProgress()

  self._LocalProgress={Positions={},Revision=0,Distance=0,RepeatedPlans=0,LoopCount=0}
  return self

end

--- Observe an actual position; future planning anchors never count as movement.
-- Copies the position. Displacements smaller than MinDistance are ignored relative to the last accepted point.
-- History contains only positions, never windows or results. Repeated directed transitions within MinDistance/2
-- of earlier endpoints indicate a possible loop. Detours away from the goal still count as movement.
-- @param #ASTAR self
-- @param #table Position Actual VECTOR, COORDINATE, Vec2 or Vec3 position.
-- @return #ASTAR self.
function ASTAR:UpdateLocalProgress(Position)

  local position=self.Grid:_PositionVector(Position)
  if not self._LocalProgressOptions then
    self:SetLocalProgress()
  elseif not self._LocalProgress then
    self:ResetLocalProgress()
  end
  local progress,options=self._LocalProgress,self._LocalProgressOptions
  local history=progress.Positions
  local previous=history[#history]
  local displacement=previous and position:GetDistance(previous,true) or 0
  if previous and displacement<options.MinDistance then
    return self
  end

  local repetitions=1
  if previous then
    for index=2,#history do
      if previous:GetDistance(history[index-1],true)<=options.MinDistance/2
        and position:GetDistance(history[index],true)<=options.MinDistance/2 then
        repetitions=repetitions+1
      end
    end
  end
  history[#history+1]=position
  if #history>options.HistorySize then
    table.remove(history,1)
  end
  progress.Revision=progress.Revision+1
  progress.Distance=progress.Distance+displacement
  progress.RepeatedPlans=0
  progress.LoopCount=previous and repetitions or 0
  return self

end

--- Associate observations with an overall goal, independently of future planning anchors.
-- A changed goal starts new diagnostics while retaining only the latest actual position.
-- @param #ASTAR self
-- @param #table State New local request.
function ASTAR:_BeginLocalProgress(State)

  local progress=self._LocalProgress
  if progress then
    local goal=progress.Goal
    if goal and goal:GetDistance(State.EndVector,false)>0 then
      local last=progress.Positions[#progress.Positions]
      self:ResetLocalProgress()
      progress=self._LocalProgress
      if last then
        progress.Positions[1]=last
      end
    end
    progress.Goal=State.EndVector
    State.Progress,State.ProgressRevision=progress,progress.Revision
  end
  State.CacheRevision=self._LocalCacheRevision

end

--- Copy movement diagnostics into this request's report; completed snapshots are never updated later.
-- @param #ASTAR self
-- @param #table State Current local request.
-- @param #boolean Complete Whether a result is being finalized.
function ASTAR:_ReportLocalProgress(State, Complete)

  local progress=self._LocalProgress
  local snapshot={Status="unobserved",HistoryCount=0,Distance=0,RepeatedPlans=0,LoopCount=0}
  if progress and #progress.Positions>0 then
    local options=self._LocalProgressOptions
    local last=progress.Positions[#progress.Positions]
    if Complete and State.Report.Outcome=="partial_path" and progress==State.Progress
      and progress.Revision==State.ProgressRevision and last:GetDistance(State.StartVector,true)<options.MinDistance then
      progress.RepeatedPlans=progress.RepeatedPlans+1
    end
    snapshot.Status="observed"
    if progress.RepeatedPlans>=options.RepeatLimit then
      snapshot.Status="repeated_planning"
    end
    if progress.LoopCount>=options.RepeatLimit then
      snapshot.Status="loop_detected"
    end
    snapshot.Position=last:GetVec3()
    snapshot.HistoryCount=#progress.Positions
    snapshot.Distance=progress.Distance
    snapshot.RepeatedPlans=progress.RepeatedPlans
    snapshot.LoopCount=progress.LoopCount
  end
  State.Report.Progress=snapshot

end

--- Set the independent bound on retained LOCAL cell estimates.
-- Defaults to 4096 cells; zero disables learning. Oldest inserted cells are evicted when full.
-- Changing the bound clears learning and invalidates pending local work. It does not change GRID MaxCells.
-- @param #ASTAR self
-- @param #number MaxCells Non-negative finite integer.
-- @return #ASTAR self.
function ASTAR:SetLocalLearningLimit(MaxCells)

  assert(type(MaxCells)=="number" and MaxCells>=0 and MaxCells<math.huge and MaxCells==math.floor(MaxCells),
    "ASTAR: learning limit must be a non-negative finite integer")
  if self.LocalLearningLimit~=MaxCells then
    self.LocalLearningLimit=MaxCells
    self:InvalidateLocalCache()
  end
  return self

end

-- Exact integer keys belong to a compatible fixed lattice, never to request-local node IDs.
local function localLearningKey(cell)
  local first,second=cell.q or cell.i,cell.r or cell.j
  -- Canonicalize signed zero while preserving integer precision beyond tostring's default format.
  if first==0 then
    first=0
  end
  if second==0 then
    second=0
  end
  return string.format("%.0f:%.0f",first,second)
end

--- Retain compact cell estimates across compatible local requests, resetting on changed inputs.
-- @param #ASTAR self
-- @param #table State New local request.
-- @param #boolean Compatible Whether the previous request still matches the current configuration.
function ASTAR:_BeginLocalLearning(State, Compatible)

  local learning=self._LocalLearning
  if not Compatible or not learning or learning.Goal:GetDistance(State.EndVector,false)>0 then
    local limit=self.LocalLearningLimit
    if limit==nil then
      limit=4096
    end
    learning={Goal=State.EndVector,Limit=limit,Entries={},Index={},Next=1}
    self._LocalLearning=learning
  end
  State.Learning=learning
  State.Boundary,State.ReverseEdges,State.Explored={},{},{}
  State.Report.LearningEntries=#learning.Entries
  State.Report.LearningLimit=learning.Limit
  State.Report.LearningUpdated=false
  State.Report.LearningUpdatedCells=0
  State.Report.LearningWorkItems=0

end

--- Estimate continuation from the same stable lattice cell in previous compatible windows.
-- Values remain in configured cost units; custom/road costs start with a zero base heuristic.
-- @param #ASTAR self
-- @param #table State Current local request.
-- @param #ASTAR.Node Node Checked exit.
-- @return #number Base remaining-cost estimate.
-- @return #number Non-negative learned increase.
function ASTAR:_LocalExitEstimate(State, Node)

  local base=self:_HeuristicCost(Node,State.Target)
  local learning=State.Learning
  local index=Node.cell and learning.Index[localLearningKey(Node.cell)]
  local entry=index and learning.Entries[index]
  local estimate=entry and math.max(base,entry.Estimate) or base
  return base,estimate-base

end

--- Advance transactional cell learning by one bounded work item.
-- Reverse Dijkstra propagates frontier estimates through checked directed edges to all explored cells.
-- No terrain/callback is queried again and no estimate crosses a blocked or unknown connection.
-- Clone, seed, edge relaxation and storage each yield through StepSearch, including without a CPU clock.
-- @param #ASTAR self
-- @param #table State Private local request.
function ASTAR:_StepLocalLearning(State)

  local learning=State.Learning
  local pending=State.PendingLearning
  local work=State.LearningSearch
  State.Report.LearningWorkItems=State.Report.LearningWorkItems+1

  if State.Phase=="learn_clone" then
    local index=State.LearningIndex
    local entry=learning.Entries[index]
    if entry then
      -- Entries are immutable scalar records; replacing an estimate never edits the previous snapshot.
      pending.Entries[index]=entry
      pending.Index[entry.Key]=index
      State.LearningIndex=index+1
    else
      State.LearningIndex=1
      State.Phase="learn_seed"
    end

  elseif State.Phase=="learn_seed" then
    local boundary=State.Boundary[State.LearningIndex]
    if boundary then
      work.Scores[boundary.Node.id]=boundary.Estimate
      lazyPush(work,boundary.Node,boundary.Estimate,0)
      State.LearningIndex=State.LearningIndex+1
    else
      State.Phase="learn_spread"
    end

  elseif State.Phase=="learn_spread" then
    if not work.Current then
      work.Current=lazyPop(work)
      work.EdgeIndex=1
      if not work.Current then
        State.LearningIndex=1
        State.Phase="learn_store"
      end
    else
      local edges=State.ReverseEdges[work.Current.id]
      local edge=edges and edges[work.EdgeIndex]
      if edge then
        local estimate=work.Scores[work.Current.id]+edge.Cost
        if estimate<(work.Scores[edge.Node.id] or math.huge) then
          work.Scores[edge.Node.id]=estimate
          lazyPush(work,edge.Node,estimate,0)
        end
        work.EdgeIndex=work.EdgeIndex+1
      else
        work.Current=nil
      end
    end

  elseif State.Phase=="learn_store" then
    local node=State.Explored[State.LearningIndex]
    if node then
      local estimate=work.Scores[node.id]
      if node.cell and estimate and estimate<math.huge then
        local key=localLearningKey(node.cell)
        local index=pending.Index[key]
        local previous=index and pending.Entries[index]
        local retainedIndex=learning.Index[key]
        local retained=retainedIndex and learning.Entries[retainedIndex]
        local base=self:_HeuristicCost(node,State.Target)
        -- An entry evicted earlier in this staging pass still supplies its known lower floor.
        estimate=math.max(base,estimate,retained and retained.Estimate or 0)
        if not previous or estimate>previous.Estimate then
          if not index then
            index=#pending.Entries+1
            if index>pending.Limit then
              index=pending.Next
              pending.Index[pending.Entries[index].Key]=nil
              pending.Next=index%pending.Limit+1
            end
          end
          pending.Entries[index]={Key=key,Estimate=estimate}
          pending.Index[key]=index
          State.LearningChanged=State.LearningChanged+1
        end
      end
      State.LearningIndex=State.LearningIndex+1
    else
      State.Phase="publish"
    end
  end

end

--- Publish copied results and atomically commit completed, complete-data cell learning.
-- Cancellation at any earlier phase leaves the previous memory and report intact.
-- @param #ASTAR self
-- @param #table State Private local request.
function ASTAR:_PublishLocalResult(State)

  local report=State.Report
  if State.PendingLearning and State.Learning==self._LocalLearning then
    self._LocalLearning=State.PendingLearning
    report.LearningEntries=#State.PendingLearning.Entries
    report.LearningUpdated=State.LearningChanged>0
    report.LearningUpdatedCells=State.LearningChanged
  end
  report.Candidates=State.Results
  report.CandidateCount=#State.Results
  report.Outcome=State.ReachedGoal and "goal_path" or "partial_path"
  self:_FinishLazySearch(State,State.Results[1].Path,"path_found")

end

--- Materialize one local endpoint and its geometric attachment indices, within a bounded work slice.
-- Only an in-window goal reaches this helper; exact positions still pass surface and edge rules.
-- @param #ASTAR self
-- @param #table State Private local search state.
-- @param Core.Vector#VECTOR Position Endpoint position.
-- @return #ASTAR.Node Endpoint or nil.
-- @return #string cell_limit on budget exhaustion, otherwise nil.
function ASTAR:_SeedLocalEndpoint(State, Position)

  local first,second=self.Grid:PositionToIndex(Position)
  local cell,reason=self.Grid:GetOrCreateCell(first,second)
  self:_SyncGrid()
  if reason=="cell_limit" then
    State.GridVersion,State.NodeCount=self.Grid.Version,self.Nnodes
    return nil,reason
  end

  local node=self:_FindEndpoint(Position,"local endpoint")
  if node and not node.cell then
    local indices={}
    for _,index in ipairs(self.Grid:_SparseNearbyIndices(node.vector)) do
      indices[index[1]]=indices[index[1]] or {}
      indices[index[1]][index[2]]=true
    end
    State.EndpointIndices[node.id]=indices
  end
  State.GridVersion,State.NodeCount=self.Grid.Version,self.Nnodes
  return node

end

-- Cost comparisons remain in the configured cost units, with stable node-ID ties.
local function localCandidateEarlier(first,second)
  if first.Score~=second.Score then
    return first.Score<second.Score
  end
  return first.Node.id<second.Node.id
end

--- Keep the cheapest settled exit in each geometric sector. No terrain-shaped frontier is invented.
-- @param #ASTAR self
-- @param #table State Private local search state.
-- @param #ASTAR.Node Node Settled reachable node.
function ASTAR:_RecordLocalExit(State, Node)

  if not Node.cell then
    return
  end
  local sector=State.Grid:_WindowExitSector(Node.cell)
  if not sector then
    return
  end

  local cost=State.Scores[Node.id]
  local remaining,penalty=self:_LocalExitEstimate(State,Node)
  -- Every geometric frontier cell seeds learning, including those not retained as sector winners.
  State.Boundary[#State.Boundary+1]={Node=Node,Estimate=remaining+penalty}
  if Node==State.Start then
    return
  end
  local baseScore=cost+remaining
  local candidate={Node=Node,Sector=sector,Cost=cost,BaseScore=baseScore,LearnedPenalty=penalty,Score=baseScore+penalty}
  local current=State.Exits[sector]
  if not current or localCandidateEarlier(candidate,current) then
    State.Exits[sector]=candidate
  end

end

--- Advance initialization or result construction by one bounded work item.
-- Reconstruction follows one predecessor or copies one position at a time, so long result paths also yield.
-- @param #ASTAR self
-- @param #table State Private local search state.
function ASTAR:_StepLocalPhase(State)

  if string.sub(State.Phase,1,6)=="learn_" then
    self:_StepLocalLearning(State)

  elseif State.Phase=="publish" then
    self:_PublishLocalResult(State)

  elseif State.Phase=="restore_nodes" or State.Phase=="restore_edges" then
    self:_RestoreLocalCache(State)

  elseif State.Phase=="start" or State.Phase=="goal" then
    -- Resolve the exact anchors first. An invalid goal may still allow a useful local exit.
    local isStart=State.Phase=="start"
    local position=isStart and self.startVector or self.endVector
    local node,reason=self:_SeedLocalEndpoint(State,position)
    if reason then
      self:_FinishLazySearch(State,nil,reason)
      return
    end

    if isStart then
      if not node then
        self:_FinishLazySearch(State,nil,"search_failed","no_start_node")
        return
      end
      State.Start,self.startNode=node,node
      State.Scores[node.id]=0
      lazyPush(State,node,0,0)
      State.Phase=State.GoalInside and "goal" or "explore"
    else
      State.Goal,self.endNode=node,node
      if not node then
        State.Report.GoalFailure="no_goal_node"
      end
      State.Phase="explore"
      if node==State.Start then
        State.Phase="coincident"
      end
    end

  elseif State.Phase=="coincident" then
    local valid,reason,status=self:_IsValidNeighbour(State.Start,State.Start)
    if not State.Running then
      return
    end
    self:_RecordUnavailableEdge(State,State.Start,State.Start,reason,status)
    if not self:_IsLazySearchCurrent(State) then
      self:_FinishLazySearch(State,nil,"search_changed")
    elseif valid then
      State.Phase="select"
      State.ReachedGoal=true
    else
      self:_FinishLazySearch(State,nil,"no_local_exit","no_local_exit")
    end

  elseif State.Phase=="select" then
    -- Selection is bounded to eight sectors; keep results private until every chosen path is copied.
    local selected={}
    if State.ReachedGoal then
      local cost=State.Scores[State.Goal.id]
      selected[1]={Node=State.Goal,Cost=cost,BaseScore=cost,LearnedPenalty=0,Score=cost,ReachesGoal=true}
    else
      for sector=1,8 do
        if State.Exits[sector] then
          selected[#selected+1]=State.Exits[sector]
        end
      end
      table.sort(selected,localCandidateEarlier)
    end
    if #selected==0 then
      self:_FinishLazySearch(State,nil,"no_local_exit","no_local_exit")
      return
    end
    State.Selected,State.Results=selected,{}
    State.CandidateIndex=1
    State.Reverse={}
    State.TraceNode=selected[1].Node
    State.Phase="unwind"

  elseif State.Phase=="unwind" then
    local node=State.TraceNode
    if node then
      State.Reverse[#State.Reverse+1]=node
      State.TraceNode=State.Previous[node]
    else
      local selected=State.Selected[State.CandidateIndex]
      State.Result={Path={},Positions={},Cost=selected.Cost,Score=selected.Score,
        BaseScore=selected.BaseScore,LearnedPenalty=selected.LearnedPenalty,Length=0,
        RemainingDistance=selected.Node.vector:GetDistance(State.Target.vector,true),
        ReachesGoal=selected.ReachesGoal or false,Sector=selected.Sector}
      State.CopyIndex=#State.Reverse
      State.Phase="copy"
    end

  elseif State.Phase=="copy" then
    local node=State.Reverse[State.CopyIndex]
    local result=State.Result
    if node then
      local previous=result.Path[#result.Path]
      if previous then
        result.Length=result.Length+previous.vector:GetDistance(node.vector,true)
      end
      result.Path[#result.Path+1]=node
      result.Positions[#result.Positions+1]=node.vector:GetVec3()
      State.CopyIndex=State.CopyIndex-1
    else
      State.Results[#State.Results+1]=result
      State.CandidateIndex=State.CandidateIndex+1
      local nextCandidate=State.Selected[State.CandidateIndex]
      if nextCandidate then
        State.Reverse={}
        State.TraceNode=nextCandidate.Node
        State.Phase="unwind"
      else
        local learning=State.Learning
        if not State.ReachedGoal and not State.Report.DataIncomplete and learning.Limit>0 then
          State.PendingLearning={Goal=learning.Goal,Limit=learning.Limit,Next=learning.Next,Entries={},Index={}}
          State.LearningSearch={Open={},OpenPositions={},Scores={}}
          State.LearningIndex,State.LearningChanged=1,0
          State.Phase="learn_clone"
        else
          State.Phase="publish"
        end
      end
    end
  end

end

--- Start a resumable LAZY search without building an enclosing grid or starting a timer.
-- Requires an unbuilt grid or a sparse grid; arbitrary caller-added nodes and all-pairs mode are unsupported.
-- Initializes the frame and at most two endpoint cells. Subsequent work is performed by StepSearch().
-- A new search cancels the previous pending search. Geometry/samples are retained between searches;
-- changing endpoints does not reorient an existing sparse lattice. Use a new ASTAR for new geometry.
-- @param #ASTAR self
-- @param #boolean ExcludeStartNode (Optional) Exclude the start from the completed path; default false.
-- @param #boolean ExcludeEndNode (Optional) Exclude the goal from the completed path; default false.
-- @return #ASTAR self. LastSearchResult describes running, complete or cancelled state.
function ASTAR:StartSearch(ExcludeStartNode, ExcludeEndNode)

  assert(ExcludeStartNode==nil or type(ExcludeStartNode)=="boolean", "ASTAR: endpoint exclusion flags must be booleans")
  assert(ExcludeEndNode==nil or type(ExcludeEndNode)=="boolean", "ASTAR: endpoint exclusion flags must be booleans")
  assert(not self.Grid.GridBuilt or self.Grid.Sparse, "ASTAR: LAZY requires an unbuilt or sparse grid")
  assert(not self.Grid._SparseWindow, "ASTAR: use StartLocalSearch for local windows; use a separate ASTAR for unbounded LAZY")
  assert(self.GridNeighboursOnly~=false, "ASTAR: LAZY requires local grid neighbours")
  for id,node in pairs(self.nodes) do
    assert(node.cell or self._EndpointNodes[id]==node, "ASTAR: LAZY does not accept caller-added manual nodes")
  end

  self:CancelSearch()
  local clock=startCPUClock()
  local state={
    Running=true,
    Grid=self.Grid,
    Open={},
    OpenPositions={},
    Scores={},
    Previous={},
    ExcludeStart=ExcludeStartNode,
    ExcludeEnd=ExcludeEndNode,
    Expanded=0,
    InitialCandidates=self.Grid:GetCandidateCount(),
    Report={
      Mode=ASTAR.SearchMode.LAZY,
      Status="running",
      StopReason="running",
      Attempts={},
      BudgetLimited=false,
      SearchCPUSeconds=clock and 0 or nil,
    },
  }
  self._LazySearch=state
  self.LastSearchResult=state.Report
  self.LastPathFailure=nil

  if not self.startVector or not self.endVector then
    self:_FinishLazySearch(state,nil,"search_failed","missing_coordinates")
  else
    if not self.Grid.GridBuilt then
      self.Grid:CreateSparse(self.startVector,self.endVector)
    end

    -- Seed the nearest endpoint cells only. Exact off-lattice endpoints keep their own validated nodes.
    for _,position in ipairs({self.startVector,self.endVector}) do
      local first,second=self.Grid:PositionToIndex(position)
      local cell,reason=self.Grid:GetOrCreateCell(first,second)
      if reason=="cell_limit" then
        self:_FinishLazySearch(state,nil,"cell_limit")
        break
      end
    end
    self:_SyncGrid()

    if state.Running then
      local start,goal,reason=self:_ResolveEndpoints()
      if reason then
        self:_FinishLazySearch(state,nil,"search_failed",reason)
      else
        state.Start,state.Goal=start,goal
        state.Scores[start.id]=0
        local estimate=self:_HeuristicCost(start,goal)
        lazyPush(state,start,estimate,estimate)

        -- A sparse graph is intentionally incomplete. Do not flood it or reject unknown goal connections.
        state.EndpointIndices={}
        for _,node in ipairs({start,goal}) do
          if not node.cell then
            local indices={}
            for _,index in ipairs(self.Grid:_SparseNearbyIndices(node.vector)) do
              indices[index[1]]=indices[index[1]] or {}
              indices[index[1]][index[2]]=true
            end
            state.EndpointIndices[node.id]=indices
          end
        end
      end
    end
  end

  state.StartVector,state.EndVector=self.startVector,self.endVector
  state.CostFunction,state.CostArguments=self.CostFunc,self.CostArg
  state.NeighbourFunction,state.NeighbourArguments=self.ValidNeighbourFunc,self.ValidNeighbourArg
  state.Options,state.GridVersion=self.Grid.GridOptions,self.Grid.Version
  state.NodeCount=self.Nnodes
  self:_UpdateLazyReport(state,clock)
  return self

end

--- Check that a paused search still describes the configured graph.
-- External mutations, including another search growing a shared grid, require a fresh StartSearch().
-- @param #ASTAR self
-- @param #table State Private search state.
-- @return #boolean True when resumption is safe.
function ASTAR:_IsLazySearchCurrent(State)

  return self._LazySearch==State and self.Grid==State.Grid and self.Grid.Version==State.GridVersion
    and self.Grid.GridOptions==State.Options and self.Nnodes==State.NodeCount and self.GridNeighboursOnly~=false
    and self.startVector==State.StartVector and self.endVector==State.EndVector
    and self.CostFunc==State.CostFunction and self.CostArg==State.CostArguments
    and self.ValidNeighbourFunc==State.NeighbourFunction and self.ValidNeighbourArg==State.NeighbourArguments
    and (not State.Local or (self._LocalWindow==State.WindowOptions and self._LocalCacheRevision==State.CacheRevision))

end

--- Generate only one node's finite geometric neighbourhood, retaining filtered samples in GRID.
-- Every returned edge still passes the normal ASTAR neighbour and cost callbacks.
-- @param #ASTAR self
-- @param #table State Private search state.
-- @param #ASTAR.Node Node Current node.
-- @return #table Neighbour nodes, or nil on a cell-budget limit.
-- @return #string cell_limit on budget rejection.
function ASTAR:_LazyNeighbours(State, Node)

  local grid=self.Grid
  local indices=Node.cell and grid:_NeighbourIndices(Node.cell) or grid:_SparseNearbyIndices(Node.vector)
  local failure
  for _,index in ipairs(indices) do
    local cell,reason=grid:GetOrCreateCell(index[1],index[2])
    if reason=="cell_limit" then
      failure=reason
      break
    end
  end
  self:_SyncGrid()
  State.GridVersion,State.NodeCount=grid.Version,self.Nnodes
  if failure then
    return nil,failure
  end

  local cells=Node.cell and grid:GetNeighbours(Node.cell) or grid:GetNearbyCells(Node.vector)
  local neighbors={}
  for _,cell in ipairs(cells) do
    neighbors[#neighbors+1]=self._CellNodes[cell.id]
  end

  -- Exact endpoints attach locally; an unknown region is never replaced by a long direct shortcut.
  if Node.cell then
    local first,second=Node.q or Node.i,Node.r or Node.j
    for _,endpoint in ipairs({State.Start,State.Goal}) do
      local attachments=State.EndpointIndices[endpoint.id]
      if attachments and attachments[first] and attachments[first][second] then
        neighbors[#neighbors+1]=endpoint
      end
    end
  end
  return neighbors

end

--- Perform bounded work on the current LAZY or LOCAL search, retaining its frontier and predecessor chain.
-- No scheduler is installed. Call again while report.Status is "running"; nil path alone does not mean failure.
-- At most MaxNodes new nodes are expanded per call. An unfinished node resumes first. CPU time is checked
-- between edges/nodes; one terrain/callback operation and one small neighbour batch cannot be interrupted.
-- Without os.clock the node limit still applies and SearchCPUSeconds is nil. Idle time is never counted.
-- Reconfiguration cancels with search_changed. Programmer errors in callbacks propagate to the caller.
-- LOCAL also limits work items to MaxNodes: an endpoint seed, finite neighbour batch, edge check, candidate
-- selection (at most eight), or one cache-restoration/reconstruction/copy/learning step.
-- Provisional candidates are never returned as success.
-- @param #ASTAR self
-- @param #number MaxNodes (Optional) Positive integer expansion limit per call; default 100.
-- @param #number MaxSeconds (Optional) Positive finite CPU budget in seconds; default 0.005.
-- @return #table Completed path, including an empty successful path, or nil while pending/unsuccessful.
-- @return #ASTAR.SearchReport Live report for this search; also stored in LastSearchResult.
function ASTAR:StepSearch(MaxNodes, MaxSeconds)

  if MaxNodes==nil then
    MaxNodes=100
  end
  if MaxSeconds==nil then
    MaxSeconds=0.005
  end
  assert(type(MaxNodes)=="number" and MaxNodes>=1 and MaxNodes<math.huge and MaxNodes==math.floor(MaxNodes),
    "ASTAR: MaxNodes must be a positive integer")
  assert(type(MaxSeconds)=="number" and MaxSeconds>0 and MaxSeconds<math.huge, "ASTAR: MaxSeconds must be finite and positive")
  local state=assert(self._LazySearch,"ASTAR: call StartSearch or StartLocalSearch before StepSearch")
  if not state.Running then
    return state.Path,state.Report
  end
  local clock=startCPUClock()
  if not clock then
    state.Report.SearchCPUSeconds=nil
  end
  local expanded,worked=0,false
  local localWork=0

  while state.Running do
    if not self:_IsLazySearchCurrent(state) then
      self:_FinishLazySearch(state,nil,"search_changed")
      break
    end
    if worked and clock and elapsedCPU(clock)>=MaxSeconds then
      break
    end
    if state.Local then
      if localWork>=MaxNodes then
        break
      end
      localWork=localWork+1
      state.WorkItems=state.WorkItems+1
    end

    if state.Local and state.Phase~="explore" then
      self:_StepLocalPhase(state)
      worked=true
    elseif not state.Current then
      if expanded>=MaxNodes then
        break
      end
      local current=lazyPop(state)
      if not current then
        if state.Local then
          state.Phase="select"
          worked=true
        else
          self:_FinishLazySearch(state,nil,"search_failed","connections_blocked")
          break
        end
      elseif current==state.Goal and state.Local then
        state.ReachedGoal=true
        state.Phase="select"
        worked=true
      elseif current==state.Goal then
        local path=self:_UnwindPath({},state.Previous,current)
        if not state.ExcludeEnd then
          path[#path+1]=current
        end
        if state.ExcludeStart and #path>0 then
          table.remove(path,1)
        end
        self:_FinishLazySearch(state,path,"path_found")
        break
      else
        if state.Local then
          state.Explored[#state.Explored+1]=current
          self:_RecordLocalExit(state,current)
        end
        state.Expanded=state.Expanded+1
        expanded=expanded+1
        worked=true
        local neighbors,reason=self:_LazyNeighbours(state,current)
        if not neighbors then
          self:_FinishLazySearch(state,nil,reason)
          break
        end
        state.Current,state.Neighbours,state.NextNeighbour=current,neighbors,1
      end
    else
      local neighbor=state.Neighbours[state.NextNeighbour]
      if not neighbor then
        state.Current,state.Neighbours=nil,nil
      else
        local current=state.Current
        local valid,reason,status=self:_IsValidNeighbour(current,neighbor)
        if not state.Running then
          break
        end
        if not self:_IsLazySearchCurrent(state) then
          self:_FinishLazySearch(state,nil,"search_changed")
          break
        end
        self:_RecordUnavailableEdge(state,current,neighbor,reason,status)
        if valid then
          local edgeCost,costReason,costStatus=self:_TravelCost(current,neighbor)
          if not state.Running then
            break
          end
          if not self:_IsLazySearchCurrent(state) then
            self:_FinishLazySearch(state,nil,"search_changed")
            break
          end
          self:_RecordUnavailableEdge(state,current,neighbor,costReason,costStatus)
          if state.Local and state.Learning.Limit>0 and edgeCost>=0 and edgeCost<math.huge then
            local edges=state.ReverseEdges[neighbor.id] or {}
            state.ReverseEdges[neighbor.id]=edges
            edges[#edges+1]={Node=current,Cost=edgeCost}
          end
          local cost=state.Scores[current.id]+edgeCost
          if cost<(state.Scores[neighbor.id] or math.huge) then
            state.Scores[neighbor.id]=cost
            state.Previous[neighbor]=current
            -- Local candidates share one Dijkstra exploration; their goal-directed scores are ranked separately.
            local estimate=0
            if not state.Local then
              estimate=self:_HeuristicCost(neighbor,state.Goal)
            end
            lazyPush(state,neighbor,cost+estimate,estimate)
          end
        end
        state.NextNeighbour=state.NextNeighbour+1
        worked=true
      end
    end
  end

  self:_UpdateLazyReport(state,clock)
  return state.Path,state.Report

end

--- Cancel a pending resumable search, retaining its sampled grid and previous result objects.
-- No timer is owned by ASTAR. A caller-owned scheduler must stop calling StepSearch() on cancellation.
-- @param #ASTAR self
-- @return #ASTAR self.
function ASTAR:CancelSearch()

  local state=self._LazySearch
  if state and state.Running then
    self:_FinishLazySearch(state,nil,"cancelled")
    self:_UpdateLazyReport(state)
  end
  return self

end

--- Complete one resumable search without claiming that a resource limit proves unreachability.
-- @param #ASTAR self
-- @param #table State Private search state.
-- @param #table Path Successful path (possibly a LOCAL partial path) or nil.
-- @param #string Reason Termination reason.
-- @param #string Failure (Optional) Proven search/endpoint failure, absent on limits and cancellation.
function ASTAR:_FinishLazySearch(State, Path, Reason, Failure)

  if not State.Running then
    return
  end
  State.Running=false
  State.Path=Path
  local report=State.Report
  if State.Local and Reason=="no_local_exit" and report.DataIncomplete then
    Reason,Failure="data_unavailable",nil
  end
  report.Status=(Reason=="cancelled" or Reason=="search_changed") and "cancelled" or "complete"
  report.StopReason,report.FailureReason=Reason,Failure
  report.BudgetLimited=Reason=="cell_limit"
  if State.Local then
    self:_ReportLocalProgress(State,true)
    State.Progress,State.Learning=nil,nil
  end
  if self._LazySearch==State then
    self.LastPathFailure=Failure
  end

  -- Release the exploration frontier; path nodes and per-edge caches remain available for inspection/reuse.
  State.Open,State.OpenPositions,State.Scores,State.Previous=nil,nil,nil,nil
  State.Current,State.Neighbours,State.EndpointIndices=nil,nil,nil
  State.Exits,State.Selected,State.Results,State.Reverse=nil,nil,nil,nil
  State.Result,State.TraceNode=nil,nil
  State.Restore,State.Unavailable=nil,nil
  State.Boundary,State.ReverseEdges,State.Explored=nil,nil,nil
  State.PendingLearning,State.LearningSearch=nil,nil
  self:T(self.lid..string.format("Resumable search finished: %s, %d expanded nodes, %d sampled cells",
    Reason,State.Expanded,State.Grid:GetCandidateCount()))

end

--- Refresh counts and accumulate active CPU time only; the report remains stable after completion.
-- @param #ASTAR self
-- @param #table State Private search state.
-- @param #table Clock (Optional) Measurement for this work slice.
function ASTAR:_UpdateLazyReport(State, Clock)

  local report=State.Report
  if Clock then
    if report.SearchCPUSeconds~=nil then
      report.SearchCPUSeconds=report.SearchCPUSeconds+elapsedCPU(Clock)
    end
  elseif State.Running then
    report.SearchCPUSeconds=nil
  end
  report.Nodes=State.NodeCount or self.Nnodes
  report.CandidateCells=State.Grid:GetCandidateCount()
  report.NewCandidateCells=report.CandidateCells-State.InitialCandidates
  report.MaxCells=State.Grid:GetOptions().MaxCells
  report.Spacing=State.Grid:GetResolutionInfo().Spacing
  report.ExpandedNodes=State.Expanded
  if State.Local then
    if State.Running then
      self:_ReportLocalProgress(State,false)
    end
    report.WorkItems=State.WorkItems
    report.GoalInside=State.GoalInside
    report.RetainedCells=State.Grid:GetCellCount()
    report.ValidityCacheHits=self.nvalidcache-State.InitialValidHits
    report.CostCacheHits=self.ncostcache-State.InitialCostHits
  end
  if not State.Running then
    report.Attempts[1]={Nodes=report.Nodes,Failure=report.FailureReason,CPUSeconds=report.SearchCPUSeconds}
    if self._LazySearch==State then
      self.LastSearchTiming={Nodes=report.Nodes,Failure=report.FailureReason,CPUSeconds=report.SearchCPUSeconds}
    end
  end

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

  assert(not self.Grid.Sparse, "ASTAR: use LAZY to grow a sparse grid")
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

  if self.Grid.Sparse or not self.GridNeighboursOnly or start.id==goal.id then
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

  local valid,reason,cost,status=ASTAR._DepthConnection(nodeA,nodeB,unpack(self.CostArg,1,self.CostArg.n))
  cost=valid and cost or math.huge

  -- Missing data is retryable, whereas a measured obstruction is a reusable result.
  if status~="unavailable" then
    nodeA.valid[nodeB.id],nodeB.valid[nodeA.id]=valid,valid
    nodeA.cost[nodeB.id],nodeB.cost[nodeA.id]=cost,cost
  end

  return valid,cost,reason,status

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

  local costFunction,costArguments=self.CostFunc,self.CostArg
  local neighbourFunction,neighbourArguments=self.ValidNeighbourFunc,self.ValidNeighbourArg
  local cost,reason,status
  if self.CostFunc==ASTAR.CostDepth and self.ValidNeighbourFunc==ASTAR.Depth
    and self.CostArg[1]==(self.ValidNeighbourArg[1] or 20) and self.CostArg[2]==(self.ValidNeighbourArg[2] or 0) then
    local valid
    valid,cost,reason,status=self:_EvaluateDepthEdge(nodeA,nodeB)
  elseif self.CostFunc==ASTAR.CostDepth then
    cost,reason,status=self.CostFunc(nodeA, nodeB, unpack(self.CostArg, 1, self.CostArg.n))
  elseif self.CostFunc then
    cost=self.CostFunc(nodeA, nodeB, unpack(self.CostArg, 1, self.CostArg.n))
  else
    cost=self:_DistNodes(nodeA, nodeB)
  end

  assert(type(cost)=="number" and cost>=0, "ASTAR: travel cost must be a non-negative number or math.huge")
  -- A callback may reconfigure/cancel a resumable search. Do not repopulate its newly cleared cache.
  if status~="unavailable" and self.CostFunc==costFunction and self.CostArg==costArguments
    and self.ValidNeighbourFunc==neighbourFunction and self.ValidNeighbourArg==neighbourArguments then
    nodeA.cost[nodeB.id]=cost
    nodeB.cost[nodeA.id]=cost
  end

  return cost,reason,status

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

  local neighbourFunction,neighbourArguments=self.ValidNeighbourFunc,self.ValidNeighbourArg
  local costFunction,costArguments=self.CostFunc,self.CostArg
  local valid,reason,status
  if self.CostFunc==ASTAR.CostDepth and self.ValidNeighbourFunc==ASTAR.Depth
    and self.CostArg[1]==(self.ValidNeighbourArg[1] or 20) and self.CostArg[2]==(self.ValidNeighbourArg[2] or 0) then
    local cost
    valid,cost,reason,status=self:_EvaluateDepthEdge(node,neighbor)
  elseif self.ValidNeighbourFunc==ASTAR.Depth then
    local cost
    valid,reason,cost,status=ASTAR.Depth(node,neighbor,unpack(self.ValidNeighbourArg,1,self.ValidNeighbourArg.n))
  elseif self.ValidNeighbourFunc then
    valid=self.ValidNeighbourFunc(node, neighbor, unpack(self.ValidNeighbourArg, 1, self.ValidNeighbourArg.n))
  else
    valid=true
  end

  -- Rules are required to be symmetric, allowing the reverse edge to reuse the same result.
  if status~="unavailable" and self.ValidNeighbourFunc==neighbourFunction and self.ValidNeighbourArg==neighbourArguments
    and self.CostFunc==costFunction and self.CostArg==costArguments then
    node.valid[neighbor.id]=valid
    neighbor.valid[node.id]=valid
  end

  return valid,reason,status

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
-- StartLocalSearch() also replaces it with a new owned bounded window for every local request.
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
  -- A public drawing/query call may synchronize all cells between work slices. Advance the owned
  -- restoration cursor as well, so that this harmless import neither duplicates nodes nor cancels the job.
  local state=self._LazySearch
  local restoring=state and state.Running and state.Local and state.Phase=="restore_nodes"
    and self:_IsLazySearchCurrent(state)

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
    self:_ImportGridCell(cell)
  end

  -- Advance only after importing the new cells; topology caches must reflect the new grid revision.
  self._CellCursor=#grid.CellList
  self._GridRevision=grid.Version
  self.gridLinks=nil
  self.gridComponents=nil
  if restoring then
    self:_FinishLocalNodeRestore(state)
  end

end

--- Import one cell into this search's independent node and edge-cache view.
-- @param #ASTAR self
-- @param Core.Grid#GRID.Cell Cell Cell belonging to the current grid.
function ASTAR:_ImportGridCell(Cell)

  local node={id=self.counter,vector=Cell.vector,surfacetype=Cell.surfacetype,
    q=Cell.q,r=Cell.r,i=Cell.i,j=Cell.j,rectGrid=Cell.rectGrid,cell=Cell,grid=self.Grid,
    _owner=self._NodeOwner,valid={},cost={}}
  self.counter=self.counter+1
  self:AddNode(node)

end

--- Restore one cell or cached edge per work item; never retain endpoint nodes from previous requests.
-- Old node caches remain untouched, including when an older path is still held by the caller.
-- @param #ASTAR self
-- @param #table State Current local request.
function ASTAR:_RestoreLocalCache(State)

  local restore=State.Restore
  local cell=State.Grid.CellList[restore.Index]
  if State.Phase=="restore_nodes" then
    if cell then
      self:_ImportGridCell(cell)
      self._CellCursor=restore.Index
      restore.Index=restore.Index+1
      State.NodeCount=self.Nnodes
    else
      self:_FinishLocalNodeRestore(State)
    end
    return
  end

  if not cell then
    State.Restore=nil
    State.Phase="start"
    return
  end
  local source=restore.CellNodes[cell.id]
  local key,value
  if source then
    key,value=next(source[restore.Cache],restore.Key)
  end
  restore.Key=key
  if key then
    local other=restore.Nodes[key]
    if other and other.cell then
      local target=self._CellNodes[other.cell.id]
      self._CellNodes[cell.id][restore.Cache][target.id]=value
      State.Report.RestoredCacheEntries=State.Report.RestoredCacheEntries+1
    end
  elseif restore.Cache=="valid" then
    restore.Cache="cost"
  else
    restore.Cache="valid"
    restore.Index=restore.Index+1
  end

end

--- Finish restoring nodes, including imports requested by public drawing/query methods between slices.
-- @param #ASTAR self
-- @param #table State Current local request.
function ASTAR:_FinishLocalNodeRestore(State)

  self._CellCursor=#State.Grid.CellList
  self._GridRevision=State.Grid.Version
  State.NodeCount=self.Nnodes
  State.Restore.Index=1
  if State.Restore.Edges then
    State.Phase="restore_edges"
  else
    State.Restore=nil
    State.Phase="start"
  end

end

--- Preserve retryable depth failures separately from measured obstructions, once per undirected edge.
-- @param #ASTAR self
-- @param #table State Current resumable request.
-- @param #ASTAR.Node First First endpoint.
-- @param #ASTAR.Node Last Other endpoint.
-- @param #string Reason Depth failure cause.
-- @param #string Status Explicit depth status; only unavailable is recorded.
function ASTAR:_RecordUnavailableEdge(State, First, Last, Reason, Status)

  if not State.Local or Status~="unavailable" then
    return
  end
  local key=math.min(First.id,Last.id)..":"..math.max(First.id,Last.id)
  State.Unavailable=State.Unavailable or {}
  if State.Unavailable[key] then
    return
  end
  State.Unavailable[key]=true
  local report=State.Report
  report.DataIncomplete=true
  report.UnavailableEdges=report.UnavailableEdges+1
  report.UnavailableReasons[Reason]=(report.UnavailableReasons[Reason] or 0)+1
  if not report.FirstUnavailableEdge then
    report.FirstUnavailableEdge={Reason=Reason,From=First.vector:GetVec3(),To=Last.vector:GetVec3()}
  end

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
-- ColorByDepth uses GRID's center-depth palette and preserves path outlines. DepthMin/DepthMax are display settings only.
-- Extra positional drawing arguments are rejected; all styling belongs in Options.
-- @param #ASTAR self
-- @param #table Path (Optional) Ordered ASTAR.Node entries from this search; nil draws without highlighting.
-- @param Core.Grid#GRID.DrawOptions Options (Optional) Named style and batch settings; see GRID.DrawOptions for all fields and defaults.
-- @return #ASTAR self; inspect LastGridDrawResult for asynchronous drawing progress.
function ASTAR:DrawGrid(Path, Options, ...)

  self:_SyncGrid()

  return GRID.DrawGrid(self, Path, Options, ...)

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

--- Cancel pending work and remove this search's selected overlays, leaving other views untouched.
-- @param #ASTAR self
-- @param #string Kind (Optional) GRID.Drawing.POLYGONS, GRID.Drawing.LABELS or GRID.Drawing.ALL; default ALL.
-- @return #ASTAR self
function ASTAR:ClearDrawing(Kind)

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
