--- **Core** - A* Pathfinding.
--
-- **Main Features:**
--
--    * Find path from A to B.
--    * Pre-defined as well as custom valid neighbour functions.
--    * Pre-defined as well as custom cost functions.
--    * Rectangular or hexagonal grids, with optional six-neighbour hex search.
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
-- @field #boolean HexNeighboursOnly Restrict candidates to hex edges and local endpoint attachments. Disabled by default.
-- @field #table hexGrid Hex geometry: origin x/z, heading cos/sin, spacing, rowSpacing, original distance, boxHY, spaceX, candidateCount and temporary initialSamples for zone seeds.
-- @field #table hexIndex Hex nodes indexed by axial q, then r.
-- @field #table hexLinks Cached candidate adjacency, indexed by node id, then neighbour id. Does not cache rule results.
-- @field #table hexComponents Connected-component labels for hex candidates. Rebuilt when candidate adjacency changes.
-- @field #table GridDrawIDs F10 polygon ids owned by DrawGrid(), removed by UndrawGrid().
-- @field #table GridDrawOptions Last DrawGrid() style and batch settings, retained for incremental updates.
-- @field #table GridDrawNodeIDs Drawn polygon ids indexed by grid node id.
-- @field #table GridDrawJob Pending drawing queue, or nil once completed or cancelled.
-- @field #table LastGridDrawResult Last drawing job: Status, NodesQueued, NodesDrawn, Batches, CPUSeconds, MaxBatchCPUSeconds, ElapsedSimulationSeconds and optional Error.
-- @field #table LastSearchTiming Last search attempt: CPUSeconds, Failure and Nodes. CPUSeconds is nil when os.clock is unavailable.
-- @field #string LastPathFailure Reason the last search attempt failed; nil on success or when no attempt was made.
-- @field #table LastExpansionResult Attempt history and stop reason from GetPathWithExpansion().
-- @extends Core.Base#BASE

--- *When nothing goes right... Go left!*
--
-- ===
--
-- # The ASTAR Concept
--
-- ASTAR finds a least-cost path through a set of coordinate nodes. A neighbour rule decides which connections can be used,
-- and a cost function assigns a travel cost to each connection. The search returns nodes in travel order.
-- It does not move units or assign DCS routes; the caller must turn the returned coordinates into suitable waypoints.
-- For example, NAVYGROUP uses ASTAR to calculate intermediate waypoints for detours on water.
--
-- The usual setup is:
--
-- 1. Create an object with @{#ASTAR.New} and set the start and end coordinates.
-- 2. Create a rectangular or hexagonal grid, or add your own nodes.
-- 3. Select a neighbour rule and, optionally, a travel cost function.
-- 4. Call @{#ASTAR.GetPath} and check the result before using its nodes.
--
-- # Start and Goal
--
-- @{#ASTAR.SetStartCoordinate} and @{#ASTAR.SetEndCoordinate} accept COORDINATE, VECTOR, DCS Vec2 or Vec3 positions.
-- They store independent VECTOR snapshots; later changes to the inputs do not move the requested endpoints.
-- Set both coordinates before calling @{#ASTAR.CreateGrid}, @{#ASTAR.CreateHexGrid}, or @{#ASTAR.GetPath}.
--
-- At search time, each endpoint is mapped to the nearest existing node using 2D distance. If the distance is at most
-- 1000 meters, that node is used. If it is greater, ASTAR adds a node at the requested coordinate, provided its surface
-- passes the filter from the grid builder. Its connections must still pass the neighbour rule.
-- An empty grid is not populated automatically by GetPath().
-- With SetHexNeighboursOnly(true), the 1000-meter snapping threshold is replaced by a 0.000001-meter coincidence tolerance:
-- endpoints at different 2D positions are added at their requested coordinates, then attached locally as described below.
--
-- Therefore, a returned path does not necessarily begin or end at the exact requested coordinates.
-- For exact endpoints, explicitly add them with @{#ASTAR.AddNodeFromCoordinate} after checking their suitability.
-- Manually added nodes are not checked against the grid surface filter.
--
-- # Nodes and Grids
--
-- Each @{#ASTAR.Node} contains an id, a `vector`, the surface type sampled when it was created, and caches for
-- connection validity and travel cost. Use `node.vector` for geometry, Vec2/Vec3 access and lightweight debug marks.
-- Use `astar:GetNodeCoordinate(node)` when a MOOSE waypoint or another API requires a COORDINATE.
-- Each call creates a fresh COORDINATE at the node altitude; it is not cached or stored in the node.
-- For example, `navyGroup:AddWaypoint(astar:GetNodeCoordinate(node), speed)` converts only a selected path node.
-- Nodes no longer expose a `coordinate` field. Custom callbacks must use `node.vector` or explicitly convert the node.
-- @{#ASTAR.AddNodeFromCoordinate} creates and adds a node and returns that node, rather than the ASTAR object.
-- @{#ASTAR.GetNodeFromCoordinate} only creates a node; call @{#ASTAR.AddNode} to include it in the search.
--
-- ## Rectangular Grid
--
-- @{#ASTAR.CreateGrid} accepts `ValidSurfaceTypes, BoxHY, SpaceX, deltaX, deltaY, MarkGrid, MaxGridNodes`.
-- The grid is aligned with the line from start to goal. All dimensions are in meters:
--
-- * `ValidSurfaceTypes`: a list of accepted surface types, or a single surface type. Nil accepts all types.
-- * `BoxHY`: total width perpendicular to start-goal, default 40000 (20000 on each side).
-- * `SpaceX`: extra space before the start and beyond the goal, default 10000 at each end.
-- * `deltaX`: node spacing along start-goal, default 2000; must be positive.
-- * `deltaY`: perpendicular node spacing, default the value of deltaX; must be positive.
-- * `MarkGrid`: set true to mark accepted grid nodes on the F10 map; disabled by default.
-- * `MaxGridNodes`: optional positive integer limit on centers sampled by this call, BEFORE surface filtering. Omitted means no limit.
--
-- Both grid builders return `nil, "node_limit"` if this limit would be exceeded, before sampling terrain or changing the object.
-- On success they return the ASTAR object, as before. When supplying a limit, check the result before chaining further methods.
-- Existing nodes do not count towards the rectangular builder's per-call limit. Invalid dimensions or limits raise an error.
-- Grid creation only builds geometry; configure connection rules before calling GetPath() or GetPathWithExpansion().
--
-- Make the width and end margins large enough to contain the detours you want to consider. Finer spacing can represent
-- narrower passages, but increases the number of nodes. As a starting point, choose spacing smaller than half the width
-- of the narrowest relevant passage, then check the result in the mission.
-- CreateGrid() adds to the existing node set. Use a new ASTAR object to build a replacement grid.
--
-- ## Hexagonal Grid
--
-- @{#ASTAR.CreateHexGrid} accepts `ValidSurfaceTypes, BoxHY, SpaceX, Spacing, MarkGrid, MaxGridNodes`.
-- The surface filter, search width, end margins, markers and optional creation limit have the same meanings and defaults as for CreateGrid().
-- `Spacing` is the distance between adjacent cell centers, default 2000 meters, not the distance to a hexagon vertex.
-- The vertex radius would be `Spacing / math.sqrt(3)`. Grid nodes have altitude zero.
--
-- The lattice starts at the requested start position and rotates with the start-to-goal heading. Each grid node stores
-- integer axial coordinates `q` and `r`; the third cube coordinate is `-q-r`. Along and across the search area, centers are at
-- `Spacing * (q + r/2)` and `Spacing * math.sqrt(3)/2 * r`. Only centers within the search rectangle and on accepted surfaces are added.
--
-- CreateHexGrid() requires an empty ASTAR object with both endpoints set. Use a new object to rebuild the lattice or switch
-- between hexagonal and rectangular grids. Additional manual nodes may be added after creating the hex grid.
-- To enlarge the same lattice, use @{#ASTAR.ExpandHexGrid}; to enlarge it automatically while searching, use @{#ASTAR.GetPathWithExpansion}.
-- Invalid dimensions or a non-empty setup raise an error before creating the grid: Spacing must be finite and positive;
-- BoxHY and SpaceX must be finite and non-negative. All dimensions are in meters.
--
-- By default, hex nodes still use the existing all-pairs candidate search, allowing long direct connections when the neighbour rule permits them.
-- Call @{#ASTAR.SetHexNeighboursOnly}(true) after creating the grid to restrict grid-to-grid connections to the six adjacent cells.
-- This mode is separate from the neighbour rule, so it can be combined with SetValidNeighbourLoS(), road checks or a custom rule.
-- SetHexNeighboursOnly(false) restores all-pairs selection; it does not remove nodes added by previous searches.
--
-- Non-grid nodes, including automatically added exact endpoints, attach in both directions to existing grid centers within one Spacing.
-- These attachments also pass through the configured neighbour rule and cost function. There are no direct connections between two non-grid nodes.
-- A grid node can therefore have extra endpoint attachments in addition to its six grid neighbours.
-- A point too far from all accepted centers is disconnected; enlarge the search area or adjust its resolution rather than expecting a long jump.
-- Filtered-out cells are not recreated by the neighbour lookup. User-added nodes remain the caller's responsibility.
--
-- Hex mode does not change the cost functions or heuristic. Paths may contain more waypoints and follow raster directions;
-- ASTAR does not smooth the result automatically. No MIST installation is required.
--
-- ## Initial Grid from a MOOSE Zone
--
-- @{#ASTAR.CreateHexGridFromZone} and @{#ASTAR.CreateGridFromZone} restrict initial grid centers to a MOOSE zone.
-- Supported shapes are circular zones (ZONE / ZONE_RADIUS), square or rectangular mission-editor zones, and ZONE_POLYGON / ZONE_POLYGON_BASE.
-- MOOSE registers mission-editor quadrilateral zones as polygons; use ZONE:FindByName() to obtain the registered zone object.
-- Both endpoints must already be set. The lattice is anchored at start and aligned with the start-to-goal line.
-- Zone membership is checked before creating vectors or querying terrain, using IsVec2InZone() and the zone's boundary rules.
-- Polygons may be concave. Only cell centers are clipped; cell outlines and connections may cross the zone boundary.
--
-- CreateHexGridFromZone(Zone, ValidSurfaceTypes, Spacing, MarkGrid, MaxGridNodes) requires an empty object, like CreateHexGrid().
-- CreateGridFromZone(Zone, ValidSurfaceTypes, deltaX, deltaY, MarkGrid, MaxGridNodes) adds rectangular cells to existing non-hex nodes.
-- Spacing defaults to 2000 m; deltaY defaults to deltaX. All other filter, marker and return conventions match the existing builders.
-- The optional limit counts candidate centers in the zone bounding box projected into the grid's axes BEFORE either zone or surface filtering.
-- It therefore also bounds membership-test work. Limit rejection returns nil, "node_limit" before terrain sampling or object mutation.
--
-- The zone defines the INITIAL grid, not a permanent movement restriction. Automatically added exact endpoints are only surface-filtered.
-- GetPathWithExpansion() may enlarge a zone-based hex grid beyond the zone. The first enlargement also fills cells previously omitted by the zone,
-- including gaps inside its bounding rectangle; previously sampled terrain cells are not queried again. Later zone movement or edits have no effect.
-- For expansion, boxHY and spaceX describe a symmetric start-to-goal rectangle enclosing the projected zone bounds. Spacing and orientation stay fixed.
-- Calling ExpandHexGrid() with unchanged dimensions leaves the zone-shaped grid unchanged. Automatic expansion still requires hex-only mode.
--
--     local startZone = ZONE:FindByName("Astar Start")
--     local goalZone = ZONE:FindByName("Astar Goal")
--     local initialZone = ZONE:FindByName("Astar Grid") -- Circle, quadrilateral or registered polygon.
--     assert(startZone and goalZone and initialZone, "Create the three ASTAR zones")
--     local astar = ASTAR:New()
--     astar:SetStartCoordinate(startZone:GetCoordinate()):SetEndCoordinate(goalZone:GetCoordinate())
--     local grid, reason = astar:CreateHexGridFromZone(initialZone, {land.SurfaceType.WATER}, 2000, false, 5000)
--     if not grid then
--       env.info("ASTAR: initial zone grid rejected: " .. reason)
--       return
--     end
--     astar:SetHexNeighboursOnly(true):SetValidNeighbourLoS(500)
--     local path = astar:GetPathWithExpansion({MaxGridNodes=5000, Redraw=false})
--     if path then astar:DrawGridWithPath(path) end
--
-- ## Draw the Grid on the F10 Map
--
-- @{#ASTAR.DrawGrid} draws the accepted cells as polygons: hexagons for CreateHexGrid(), rectangles for CreateGrid().
-- Each cell is centered on its node and rotates with the grid. Manual nodes and automatically added endpoints have no cell outline.
-- Only the node center was surface-filtered; a drawn cell may still cover unsuitable terrain or extend beyond the search rectangle.
-- The outlines show the sampling grid, not the allowed connections or guaranteed traversable areas.
--
-- By default, all coalitions see blue solid outlines with no fill. Optional coalition, RGB colors, opacity, line style,
-- and read-only settings follow the MOOSE coordinate drawing functions. One DCS polygon is created per accepted cell.
-- DrawGrid() cancels pending drawing and removes its previous polygons, then builds the overlay with the requested style.
-- Each batch draws at most 25 cells and stops after reaching 0.005 CPU seconds, with 0.1 simulation seconds between batches.
-- The optional eighth argument is `{BatchSize=25, Interval=0.1, MaxBatchSeconds=0.005}`. Values must be positive; BatchSize must be an integer.
-- Large jobs defer their first batch. Small jobs start immediately but schedule remaining cells if the time budget is reached.
-- The budget is checked after each cell: one expensive DCS call can exceed it and cannot be interrupted. Without os.clock, batches use one cell.
-- Smaller budgets reduce callback work; the complete overlay takes longer to appear. A batch is still synchronous.
-- @{#ASTAR.UpdateGridDrawing} adds only missing cell polygons with the saved style and extends an active queue without duplicates.
-- Use it after adding nodes or calling ExpandHexGrid(). GetPathWithExpansion() invokes it automatically after enlargement unless Redraw=false.
-- Updates also work when the initial overlay is still queued. They do nothing if DrawGrid() has not selected a style.
-- @{#ASTAR.UndrawGrid} cancels pending batches and synchronously removes owned polygons; it preserves nodes, paths and MarkGrid text markers.
-- GridDrawIDs contains only completed polygons. LastGridDrawResult tracks the live job: Status (queued, running, complete, cancelled, error),
-- NodesQueued, NodesDrawn, Batches, CPUSeconds (sum of batches), MaxBatchCPUSeconds, and ElapsedSimulationSeconds (set when the job ends).
-- A drawing error stops that job and logs the error; UpdateGridDrawing() can retry missing cells in a regular overlay. Request a new snapshot to retry it.
--
-- On an existing ASTAR object with a generated grid:
--
--     astar:DrawGrid()                             -- Blue outlines; large grids finish in scheduled batches.
--     astar:DrawGrid(2, {0, 0.5, 1}, 0.8, nil, 0.1) -- Replace with a lightly filled grid for blue coalition.
--     -- Later, when the overlay is no longer needed:
--     astar:UndrawGrid()
--
-- ## Surface Filtering
--
-- For a water-only grid, pass `{land.SurfaceType.WATER}`. This accepts exactly that type, excluding SHALLOW_WATER.
-- The filter checks the position of each node, not the terrain along connections. Two water nodes can still have land
-- between them. A suitable neighbour rule is needed to reject such connections.
--
-- ## One-Time Grid and Path Debug View
--
-- @{#ASTAR.DrawGridWithPath} draws the current grid in blue and the supplied path's grid cells with green outlines and translucent green fill.
-- It uses the existing rectangular or hexagonal cell shapes and draws one polygon per cell. It does not recompute or change the path.
-- Exact endpoints and manual nodes without a cell polygon are skipped; long connections do not color intermediate cells not present in the path.
-- The selection is captured when called. Later searches and enlargements do not refresh this debug snapshot, even with Redraw=true.
-- Call DrawGridWithPath() again for a new snapshot, DrawGrid() to return to a regular overlay, or UndrawGrid() to remove it.
-- Existing overlays on this object are replaced. Large snapshots finish in scheduled batches and stop once complete.
-- Options include Coalition, GridColor, PathColor, PathFillAlpha and the same batch settings as DrawGrid().
--
--     local path, report = astar:GetPathWithExpansion({Redraw=false})
--     if path then
--       astar:DrawGridWithPath(path) -- One-time grid view; path cells are green.
--     end
--
-- # Valid Neighbours
--
-- By default, every other node is a potential neighbour, including distant nodes. Without a neighbour rule, all candidate pairs are allowed.
-- The optional hex-only mode restricts candidates before applying the rule.
-- Each neighbour setter replaces the previous rule; calling two setters does not combine their conditions.
--
-- * @{#ASTAR.SetValidNeighbourDistance}: allow connections whose 2D distance is at most MaxDistance (default 2000 m).
--   This limits step length but does not check terrain. For a square grid with spacing d, diagonal steps need at least `d * math.sqrt(2)`.
-- * @{#ASTAR.SetValidNeighbourLoS}: use `land.isVisible` at a fixed altitude of 1 meter above sea level.
--   With a CorridorWidth, also check two parallel lines offset by half that width on either side.
--   This is intended for water routes; it is not a general visibility test at the nodes' actual altitudes or a full corridor clearance check.
-- * @{#ASTAR.SetValidNeighbourRoad}: require a DCS road path and a 2D endpoint distance at most MaxDistance (default 2000 m).
--   The limit is straight-line distance, not the length of the road path. This rule does not select road travel costs.
-- * @{#ASTAR.SetValidNeighbourFunction}: supply `function(nodeA, nodeB, ...)` returning a boolean.
--   Extra arguments are forwarded after the two nodes. Pass nil as the function to allow all pairs again.
--
-- Rules must be symmetric: A-to-B and B-to-A must give the same result because the result is cached in both directions.
-- To combine conditions, use one custom function; an example appears below.
--
-- # Travel Costs and Heuristics
--
-- The search ranks nodes by travel cost accumulated so far plus an estimate of the remaining cost (the heuristic).
-- The selected travel cost is applied to every traversed connection:
--
-- * Default, or @{#ASTAR.SetCostDist2D}: 2D distance in meters; the heuristic is also 2D distance.
-- * @{#ASTAR.SetCostDist3D}: 3D distance in meters; the heuristic is also 3D distance.
--   Supply nodes with appropriate altitudes; neither grid builder creates a three-dimensional flight grid.
-- * @{#ASTAR.SetCostRoad}: length of the path returned by `land.findPathOnRoads`; a missing connection costs `math.huge`.
--   The heuristic is zero. Returned ASTAR nodes do not include the detailed DCS road path between them.
-- * @{#ASTAR.SetCostFunction}: supply `function(nodeA, nodeB, ...)` returning a non-negative, symmetric numeric travel cost.
--   Use `math.huge` for an impassable connection, and keep the same cost units for all connections.
--   Custom functions use a zero heuristic. Pass nil to restore the default 2D distance.
--
-- A zero heuristic makes the search equivalent to Dijkstra's algorithm and avoids overestimating unknown custom costs.
-- The least-cost result is relative to the available nodes, allowed connections, and selected costs, not every possible route through the terrain.
-- Since version 0.4.1, SetCostFunction() determines actual travel costs; earlier versions applied it only to the heuristic.
--
-- # Fast Connectivity Precheck
--
-- @{#ASTAR.HasPotentialPath} checks whether the requested endpoints can be connected before applying neighbour rules and travel costs.
-- In hex-only mode it traverses the existing hex candidate graph, including local attachments for exact endpoints and manual nodes.
-- It does not query visibility or roads or execute custom neighbour/cost callbacks.
-- Like GetPath(), it resolves endpoints and may add nodes at their requested coordinates; newly created nodes sample their surface types.
--
-- * False means there is no candidate route in the current graph, or valid endpoints are missing. GetPath() cannot find a route in that state.
-- * True means a route is possible, not guaranteed. A visibility rule, a missing road or an infinite cost can still prevent the final path.
--
-- GetPath() automatically performs this precheck in hex-only mode and returns nil for disconnected endpoints before starting A*.
-- Call HasPotentialPath() explicitly when you want to decide whether to construct a larger grid first. The precheck does not resize the grid.
-- Increasing BoxHY or SpaceX may include a missing detour. GetPathWithExpansion() can do this automatically.
-- Smaller Spacing may resolve a narrow passage, but changing spacing requires a new ASTAR object.
--
-- Connected components are cached independently of neighbour/cost results. The first check builds candidate adjacency as needed
-- and visits the start component with a breadth-first traversal, linear in its nodes and candidate edges.
-- Later checks reuse the complete component labels until nodes change. Endpoint selection still scans the node set.
-- Changing a neighbour rule or travel cost does not invalidate this cache because neither is used in the connectivity test.
--
-- Outside hex-only mode, all node pairs are candidates. HasPotentialPath() therefore returns true whenever both endpoints can be resolved;
-- it does not use hex adjacency to reject possible long connections. Missing coordinates or an empty node set still return false.
--
-- # Search with Automatic Grid Expansion
--
-- @{#ASTAR.GetPathWithExpansion} is an opt-in alternative to GetPath() for a hex grid with SetHexNeighboursOnly(true).
-- It searches the current grid first, expands its width and both end margins after failure, and retries until an actual path is found
-- or a limit is reached. Passing the connectivity precheck alone is not enough: the full search must satisfy the configured rules and costs.
-- Existing nodes, ids, manual points, callbacks, and lattice orientation are retained; newly added cells use the existing surface filter.
-- A grid created with CreateHexGridFromZone() uses the zone only for its initial cells; enlargement can leave the zone.
-- Previously sampled cells, including surface-filtered cells, are not sampled again. Use a new object if the surface filter or the original lattice must change.
--
-- The first argument is an optional settings table:
--
-- * `GrowthFactor`: multiply width and end margins by this factor, default 1.5; must be finite and greater than 1.
-- * `MaxAttempts`: maximum number of searches, including the initial grid, default 5.
-- * `MaxGridNodes`: maximum number of lattice centers BEFORE surface filtering, default 5000. Includes filtered cells because they require
--   terrain sampling, but excludes manual points and exact endpoint nodes. Expansion is rejected before sampling if it would exceed the limit.
-- * `MaxBoxHY`: maximum total width, default the larger of the initial width and 200000 meters.
-- * `MaxSpaceX`: maximum margin at each end, default the larger of the initial margin and 100000 meters.
-- * `Redraw`: append missing cells to an existing or pending DrawGrid() overlay after searching, retaining its style and batch settings; default true.
--
-- Width grows by at least two Spacing and margins by at least one Spacing, so zero initial margins can grow as well.
-- Dimension caps take precedence. Explicit dimension caps cannot be smaller than the current grid; attempt and cell limits must be positive integers.
-- An initial grid already above MaxGridNodes is rejected without running a search. A rejected expansion leaves the current grid intact.
-- This search limit cannot protect the earlier initial build: pass MaxGridNodes to CreateHexGrid() as well to bound its terrain sampling.
--
-- GetPathWithExpansion(Options, ExcludeStartNode, ExcludeEndNode) returns `path, report`. Endpoint exclusion flags behave as in GetPath().
-- A successful empty path is still success. The report is also stored in `astar.LastExpansionResult` and contains:
--
-- * `Attempts`: one entry per search, with BoxHY, SpaceX, accepted Nodes (including extra endpoints), CPUSeconds, and Failure (nil on success).
-- * `StopReason`: path_found, attempt_limit, size_limit, node_limit, or missing_coordinates.
-- * `BoxHY`, `SpaceX`, `Nodes`: final dimensions and accepted node count. The expanded grid stays on the same object for drawing or reuse.
-- * `SearchCPUSeconds`: total CPU time for attempts and grid enlargement, excluding overlay drawing.
-- * `Drawing`: optional reference to the live drawing result when the overlay was updated. A pending initial job may be included.
--   Status and counters continue to change after the path is returned; the report does not wait for queued drawing to finish.
--
-- `HasPotentialPath()` also returns a second value on failure; GetPath() stores its reason in `LastPathFailure`:
-- missing_coordinates, no_start_node, no_goal_node, start_unattached, goal_unattached, or disconnected_grid.
-- The unattached reasons specifically mean a non-grid endpoint has no accepted hex center within one Spacing.
-- If candidate connectivity exists but the full search fails, LastPathFailure is connections_blocked.
-- Attempts, failure reasons and dimensions are trace-logged, allowing you to see why and how far the search grew.
-- Intermediate failures do not generate error logs or player messages. Only a final unsuccessful result announces failure.
-- LastPathFailure describes the last search attempt; it is nil when the grid budget rejects the request before any attempt.
--
-- This operation is synchronous. Use modest limits in a running mission; no limit guarantees a route exists.
-- Enlargement cannot fix a passage missed by the fixed spacing, a permanently invalid endpoint, or rules that forbid every route.
--
-- # Calculate and Use the Path
--
-- @{#ASTAR.GetPath} returns an ordered list of nodes, including start and goal by default.
-- `GetPath(true, false)` omits the start, `GetPath(false, true)` omits the goal, and `GetPath(true, true)` returns only intermediate nodes.
-- These options exclude the selected nodes, which may differ from the requested endpoint coordinates.
-- A successful result can be an empty table when all its nodes were excluded; an empty table is true in Lua.
--
-- A nil result means no valid path was found. Check for:
--
-- * Missing start or end coordinates, or an empty node set (including a grid rejected entirely by its surface filter).
-- * An automatically added endpoint rejected by the grid surface filter, or disconnected from the hex grid.
-- * A grid that does not cover the required detour, or spacing too coarse to represent a passage.
-- * A maximum neighbour distance too small to connect the nodes, or other neighbour rules blocking the route.
-- * Connections with infinite travel cost, such as missing road connections.
--
-- # Reuse and Performance
--
-- GetPath() runs synchronously. By default it scans all nodes when finding neighbours; hex-only mode uses an indexed,
-- sparse candidate graph built once after node additions, then checks only adjacent cells and local attachments.
-- Selection of the next open node and initial endpoint lookup still use linear scans. Large grids and expensive road/visibility
-- checks can pause the simulation; start with a small search area and add detail only as needed.
-- F10 markers for large grids can also be expensive. Set `astar.Debug = true` to enable the no-path message to players;
-- search statistics are written through the normal MOOSE logging facilities.
-- DrawGrid() creates one polygon per cell from plain Vec3 vertices and schedules work in time-limited batches. Enlargement retains existing polygons.
-- Search completion and drawing completion are logged separately. Search CPU time includes endpoint resolution and connectivity checks.
-- CPU measurements use os.clock when available; they are not wall-clock durations. In a sanitized environment they are reported as unavailable,
-- with nil timing fields. Drawing's elapsed simulation time includes scheduler delays and is labelled separately.
-- Replacing an overlay with DrawGrid() or removing it with UndrawGrid() still removes existing polygons synchronously.
--
-- Connection validity and travel costs are cached on the nodes. Calling SetValidNeighbourFunction() or one of its convenience
-- setters clears validity results; calling SetCostFunction() or a cost setter clears travel costs.
-- If a callback depends on changing mission data, call its setter again before searching to invalidate the corresponding cache.
-- Merely changing a callback's external data does not invalidate it. Create a new object and nodes when replacing the grid or moving nodes.
--
-- # Examples
--
-- ## Water Route Between Two Mission Editor Zones
--
-- Load MOOSE and create trigger zones named `Astar Start` and `Astar Goal`, with both centers on water.
-- Adjust the grid dimensions to the area. This example marks the resulting path; it does not assign a route to a group.
--
--     local startZone = ZONE:FindByName("Astar Start")
--     local goalZone = ZONE:FindByName("Astar Goal")
--     assert(startZone and goalZone, "Create the Astar Start and Astar Goal trigger zones")
--     local astar = ASTAR:New()
--     astar:SetStartCoordinate(startZone:GetCoordinate())
--     astar:SetEndCoordinate(goalZone:GetCoordinate())
--     astar:CreateGrid({land.SurfaceType.WATER}, 40000, 10000, 2000, 2000, false)
--     astar:SetValidNeighbourLoS(500)
--     local path = astar:GetPath()
--     if path then
--       for i, node in ipairs(path) do
--         node.vector:Mark(string.format("ASTAR waypoint %d", i))
--       end
--     else
--       env.info("ASTAR: no water route found")
--     end
--
-- ## Find a Water Route with Automatic Expansion
--
-- Use the same two water-based trigger zones as above. This starts with a 40 km wide grid and 10 km end margins.
-- GetPathWithExpansion() handles the precheck internally; do not abort the script first when HasPotentialPath() is false.
-- The same 5000-cell budget protects both the initial build and later expansions.
--
--     local startZone = ZONE:FindByName("Astar Start")
--     local goalZone = ZONE:FindByName("Astar Goal")
--     assert(startZone and goalZone, "Create the Astar Start and Astar Goal trigger zones")
--     local astar = ASTAR:New()
--     astar:SetStartCoordinate(startZone:GetCoordinate())
--     astar:SetEndCoordinate(goalZone:GetCoordinate())
--     local grid, reason = astar:CreateHexGrid({land.SurfaceType.WATER}, 40000, 10000, 2000, false, 5000)
--     if not grid then
--       env.info("ASTAR: initial grid rejected: " .. reason)
--       return
--     end
--     astar:SetHexNeighboursOnly(true)
--     astar:SetValidNeighbourLoS(500)
--     local path, report = astar:GetPathWithExpansion({
--       GrowthFactor = 1.5, MaxAttempts = 5, MaxGridNodes = 5000,
--       MaxBoxHY = 200000, MaxSpaceX = 100000
--     })
--     astar:DrawGrid()
--     if path then
--       for i, node in ipairs(path) do
--         node.vector:Mark(string.format("Expanded route waypoint %d", i))
--       end
--     else
--       env.info("ASTAR: stopped expanding: " .. report.StopReason)
--     end
--
-- ## Combine Distance and Visibility
--
-- On an existing `astar` object, replace the neighbour rule with a combined check before calling GetPath():
--
--     astar:SetValidNeighbourFunction(function(nodeA, nodeB, maxDistance, corridorWidth)
--       return ASTAR.DistMax(nodeA, nodeB, maxDistance)
--         and ASTAR.LoS(nodeA, nodeB, corridorWidth)
--     end, 3000, 500)
--
-- ## Hexagonal Water Route
--
-- As in the water example, create the `Astar Start` and `Astar Goal` trigger zones on water before running this code.
-- This enables six-neighbour traversal with a 500-meter visibility corridor. Exact endpoints attach to nearby accepted centers.
-- The optional explicit precheck distinguishes an insufficiently connected grid from a route blocked by the actual connection rules.
--
--     local startZone = ZONE:FindByName("Astar Start")
--     local goalZone = ZONE:FindByName("Astar Goal")
--     assert(startZone and goalZone, "Create the Astar Start and Astar Goal trigger zones")
--     local astar = ASTAR:New()
--     astar:SetStartCoordinate(startZone:GetCoordinate())
--     astar:SetEndCoordinate(goalZone:GetCoordinate())
--     astar:CreateHexGrid({land.SurfaceType.WATER}, 40000, 10000, 2000, false)
--     astar:SetHexNeighboursOnly(true)
--     astar:SetValidNeighbourLoS(500)
--     if not astar:HasPotentialPath() then
--       env.info("ASTAR: no candidate route; check endpoints, grid extent and spacing")
--       return
--     end
--     local path = astar:GetPath()
--     if path then
--       for i, node in ipairs(path) do
--         node.vector:Mark(string.format("Hex route waypoint %d", i))
--       end
--     else
--       env.info("ASTAR: no hex water route found")
--     end
--
-- ## Custom Nodes and Costs
--
-- This small abstract graph illustrates a penalty on one connection. Its sample coordinates are not a terrain-validated route.
-- All connections are allowed, but the direct start-goal connection receives an extra cost of 10000.
-- The cheapest result therefore visits the middle node. Custom cost callbacks receive nodes, not coordinates.
--
--     local astar = ASTAR:New()
--     local start = astar:AddNodeFromCoordinate(VECTOR:New(0, 0, 0))
--     local middle = astar:AddNodeFromCoordinate(VECTOR:New(1000, 0, 1000))
--     local goal = astar:AddNodeFromCoordinate(VECTOR:New(2000, 0, 0))
--     astar:SetStartCoordinate(start.vector)
--     astar:SetEndCoordinate(goal.vector)
--     astar:SetCostFunction(function(nodeA, nodeB, penalty)
--       local direct = (nodeA == start and nodeB == goal) or (nodeA == goal and nodeB == start)
--       return ASTAR.Dist2D(nodeA, nodeB) + (direct and penalty or 0)
--     end, 10000)
--     local path = astar:GetPath()
--     assert(path and #path == 3 and path[2] == middle, "Expected the route through the middle node")
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
-- @field #table rectGrid Drawing geometry for a node created by CreateGrid(): half-length, half-width, heading cosine and sine.

--- ASTAR infinity.
-- @field #number INF
ASTAR.INF=1/0

--- ASTAR class version.
-- @field #string version
ASTAR.version="0.8.0"

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
  assert(type(width)=="number" and width>=0 and width<math.huge, "ASTAR: BoxHY must be finite and non-negative")
  assert(type(margin)=="number" and margin>=0 and margin<math.huge, "ASTAR: SpaceX must be finite and non-negative")
end

local function checkGridNodeLimit(limit)
  assert(limit==nil or (type(limit)=="number" and limit>=1 and limit<math.huge and limit==math.floor(limit)),
    "ASTAR: MaxGridNodes must be a positive integer")
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
-- Invalidates hex candidate adjacency. Do not modify node ids, hex indices or coordinates after adding a node.
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
    self.hexLinks=nil
  end

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


--- Limit candidates to six adjacent hex cells and local attachments for non-grid nodes.
-- Call CreateHexGrid() first. Does not replace the validity rule: LoS, distance, road or custom checks still apply.
-- In this mode, non-coincident endpoints are added at their exact coordinates if their surfaces are allowed.
-- Non-grid nodes attach only to existing hex centers within one Spacing, in both directions; they do not connect directly to each other.
-- @param #ASTAR self
-- @param #boolean Enabled (Optional) Enable the mode, default true. False restores all-pairs candidate selection.
-- @return #ASTAR self
function ASTAR:SetHexNeighboursOnly(Enabled)

  if Enabled==nil then Enabled=true end
  assert(type(Enabled)=="boolean", "ASTAR: Enabled must be a boolean")
  assert(not Enabled or self.hexGrid, "ASTAR: call CreateHexGrid before enabling hex neighbours")
  self.HexNeighboursOnly=Enabled

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

--- Add a rectangular grid of nodes aligned with the start-to-goal line.
-- Both endpoint coordinates must be set first. Existing nodes are retained; use a new ASTAR object for a replacement grid.
-- Cannot be called on an object that already contains a hex lattice.
-- The surface filter applies to new grid nodes and automatically added distant endpoints, not to the connections between them.
-- @param #ASTAR self
-- @param #table ValidSurfaceTypes (Optional) Allowed surface types; a single numeric surface type is also accepted. Nil allows all surfaces.
-- @param #number BoxHY (Optional) Total grid width perpendicular to start-to-goal, in meters. Default 40000 meters (40 km).
-- @param #number SpaceX (Optional) Additional space in meters before start and after end coordinate. Default 10000 meters (10 km).
-- @param #number deltaX (Optional) Finite positive spacing along start-to-goal in meters. Default 2000 meters.
-- @param #number deltaY (Optional) Finite positive perpendicular spacing in meters. Default is the same as deltaX.
-- @param #boolean MarkGrid (Optional) If true, create F10 markers at accepted grid nodes. Disabled by default; large grids can stall DCS.
-- @param #number MaxGridNodes (Optional) Positive integer cap on centers sampled by this call before surface filtering. Nil means unlimited.
-- @return #ASTAR self on success, or nil if the candidate-cell limit would be exceeded. Rejection leaves the object unchanged.
-- @return #string Failure reason: node_limit, or nil on success.
function ASTAR:CreateGrid(ValidSurfaceTypes, BoxHY, SpaceX, deltaX, deltaY, MarkGrid, MaxGridNodes)

  assert(not self.hexGrid, "ASTAR: use a new object for a rectangular grid after a hex grid")
  assert(self.startVector and self.endVector, "ASTAR: start and end coordinates are required for a grid")
  BoxHY=BoxHY or 40000
  SpaceX=SpaceX or 10000
  deltaX=deltaX or 2000
  deltaY=deltaY or deltaX
  checkGridDimensions(BoxHY, SpaceX)
  assert(type(deltaX)=="number" and deltaX>0 and deltaX<math.huge, "ASTAR: deltaX must be finite and positive")
  assert(type(deltaY)=="number" and deltaY>0 and deltaY<math.huge, "ASTAR: deltaY must be finite and positive")
  checkGridNodeLimit(MaxGridNodes)

  local distance=self.startVector:GetDistance(self.endVector, true)
  -- Match the original numeric-for loop counts even when dimensions are not spacing multiples.
  local nx=math.floor(BoxHY/deltaY+1)
  local nz=math.floor((distance+2*SpaceX)/deltaX+1)
  if MaxGridNodes and nx>MaxGridNodes/nz then return nil, "node_limit" end

  local angle=math.rad(self.startVector:GetHeadingTo(self.endVector))
  
  local grid={x=self.startVector.x, z=self.startVector.z, cos=math.cos(angle), sin=math.sin(angle), along=deltaX/2, across=deltaY/2}
  
  self.ValidSurfaceTypes=ValidSurfaceTypes
  
  self:T(self.lid..string.format("Building grid with nx=%d ny=%d => total=%d nodes", nx, nz, nx*nz))
  
  for i=1,nx do
    for j=1,nz do
      local vector=gridVector(grid, -SpaceX+deltaX*(j-1), -BoxHY/2+deltaY*(i-1))
      local node=self:GetNodeFromCoordinate(vector)
      if self:CheckValidSurfaceType(node, ValidSurfaceTypes) then
        node.rectGrid=grid
        self:AddNode(node)
        if MarkGrid then
          vector:Mark(string.format("i=%d, j=%d surface=%d", i, j, node.surfacetype))
        end
      end
    end
  end
  self:T2(self.lid.."Done building grid!")
  return self
end

--- Create a hexagonal lattice of nodes within a rectangular start-to-goal search area.
-- Requires start and goal coordinates and an empty node set; only one hex lattice can be created per object.
-- The origin is the start position, q follows start-to-goal, and r advances in 60-degree steps from that axis.
-- Nodes are created at altitude zero and clipped by their centers to the search area. Surface filtering applies before indexing.
-- Does not enable the six-neighbour mode automatically; call SetHexNeighboursOnly(true) to use local hex edges.
-- @param #ASTAR self
-- @param #table ValidSurfaceTypes (Optional) Allowed surfaces, or a single numeric type. Nil allows all types.
-- @param #number BoxHY (Optional) Total perpendicular search width in meters, default 40000. Must be finite and non-negative.
-- @param #number SpaceX (Optional) Margin before start and after goal in meters, default 10000. Must be finite and non-negative.
-- @param #number Spacing (Optional) Distance between adjacent hex centers in meters, default 2000. Must be finite and positive.
-- @param #boolean MarkGrid (Optional) Mark accepted hex centers on the F10 map, default false.
-- @param #number MaxGridNodes (Optional) Positive integer cap on centers sampled by this call before surface filtering. Nil means unlimited.
-- @return #ASTAR self on success, or nil if the candidate-cell limit would be exceeded. Rejection leaves the object unchanged.
-- @return #string Failure reason: node_limit, or nil on success.
function ASTAR:CreateHexGrid(ValidSurfaceTypes, BoxHY, SpaceX, Spacing, MarkGrid, MaxGridNodes)

  BoxHY=BoxHY or 40000
  SpaceX=SpaceX or 10000
  Spacing=Spacing or 2000
  assert(self.startVector and self.endVector, "ASTAR: start and end coordinates are required for a hex grid")
  assert(not self.hexGrid and next(self.nodes)==nil, "ASTAR: create a hex grid on an empty ASTAR object")
  checkGridDimensions(BoxHY, SpaceX)
  assert(type(Spacing)=="number" and Spacing>0 and Spacing<math.huge, "ASTAR: Spacing must be finite and positive")
  checkGridNodeLimit(MaxGridNodes)

  local distance=self.startVector:GetDistance(self.endVector, true)
  local angle=distance>0 and math.rad(self.startVector:GetHeadingTo(self.endVector)) or 0
  local grid={x=self.startVector.x, z=self.startVector.z, cos=math.cos(angle), sin=math.sin(angle), spacing=Spacing,
    rowSpacing=Spacing*math.sqrt(3)/2, distance=distance, markGrid=MarkGrid}
  local bounds=hexBounds(grid, BoxHY, SpaceX, MaxGridNodes)
  if not bounds then return nil, "node_limit" end

  self.hexGrid=grid
  self.hexIndex={}
  self.ValidSurfaceTypes=ValidSurfaceTypes
  self:_PopulateHexGrid(bounds, BoxHY, SpaceX)
  self:T(self.lid..string.format("Built hex grid with %d nodes, spacing %.1f m", self.Nnodes, Spacing))
  return self
end

--- Create a hex grid whose initial cell centers are restricted to a MOOSE circle, square/rectangle or polygon zone.
-- Requires both endpoints and an empty node set. The lattice origin and heading still follow start-to-goal.
-- Uses the zone only during creation. A later enlargement may add cells outside it, including unvisited cells inside its bounding box.
-- Zone and surface filters apply to centers, not cell outlines or connections. Exact endpoints added by a search are not zone-filtered.
-- @param #ASTAR self
-- @param Core.Zone#ZONE_BASE Zone Initial grid zone; mission-editor zones can be obtained with ZONE:FindByName().
-- @param #table ValidSurfaceTypes (Optional) Allowed surface types; nil accepts all types.
-- @param #number Spacing (Optional) Finite positive center spacing, default 2000 m.
-- @param #boolean MarkGrid (Optional) Mark accepted centers, default false.
-- @param #number MaxGridNodes (Optional) Positive cap on candidate centers in the projected zone bounding box, before zone or surface filtering.
-- @return #ASTAR self, or nil if the candidate-cell limit is exceeded. A limit rejection leaves the object unchanged.
-- @return #string Failure reason node_limit, or nil on success.
function ASTAR:CreateHexGridFromZone(Zone, ValidSurfaceTypes, Spacing, MarkGrid, MaxGridNodes)
  assert(not self.hexGrid and next(self.nodes)==nil, "ASTAR: create a hex grid on an empty ASTAR object")
  Spacing=Spacing or 2000
  assert(type(Spacing)=="number" and Spacing>0 and Spacing<math.huge, "ASTAR: Spacing must be finite and positive")
  checkGridNodeLimit(MaxGridNodes)
  local grid,area=zoneGridArea(self,Zone)
  grid.spacing=Spacing grid.rowSpacing=Spacing*math.sqrt(3)/2 grid.markGrid=MarkGrid
  local width=2*math.max(math.abs(area.acrossMin),math.abs(area.acrossMax))
  local margin=math.max(0,-area.alongMin,area.alongMax-grid.distance)
  checkGridDimensions(width,margin)
  local bounds=hexBounds(grid,width,margin,MaxGridNodes,area)
  if not bounds then return nil,"node_limit" end
  self.hexGrid=grid
  self.hexIndex={}
  self.ValidSurfaceTypes=ValidSurfaceTypes
  self:_PopulateHexGrid(bounds,width,margin,Zone)
  self:T(self.lid..string.format("Built zone hex grid with %d nodes, spacing %.1f m",self.Nnodes,Spacing))
  return self
end

--- Add a rectangular grid whose initial cell centers lie inside a MOOSE circle, square/rectangle or polygon zone.
-- Requires both endpoints. Preserves existing nodes and aligns the lattice to start-to-goal, with a center at the start if it is in the zone.
-- Zone membership is checked before terrain sampling. It is not a permanent path constraint. Rectangular automatic enlargement is not supported.
-- @param #ASTAR self
-- @param Core.Zone#ZONE_BASE Zone Initial grid zone.
-- @param #table ValidSurfaceTypes (Optional) Allowed surface types; nil accepts all types.
-- @param #number deltaX (Optional) Finite positive spacing along start-to-goal, default 2000 m.
-- @param #number deltaY (Optional) Finite positive perpendicular spacing, default deltaX.
-- @param #boolean MarkGrid (Optional) Mark accepted centers, default false.
-- @param #number MaxGridNodes (Optional) Positive cap on candidate centers in the projected bounding box before either filter. Excludes existing nodes.
-- @return #ASTAR self, or nil if the candidate-cell limit is exceeded. A limit rejection leaves the object unchanged.
-- @return #string Failure reason node_limit, or nil on success.
function ASTAR:CreateGridFromZone(Zone, ValidSurfaceTypes, deltaX, deltaY, MarkGrid, MaxGridNodes)
  assert(not self.hexGrid, "ASTAR: use a new object for a rectangular grid after a hex grid")
  deltaX=deltaX or 2000 deltaY=deltaY or deltaX
  assert(type(deltaX)=="number" and deltaX>0 and deltaX<math.huge, "ASTAR: deltaX must be finite and positive")
  assert(type(deltaY)=="number" and deltaY>0 and deltaY<math.huge, "ASTAR: deltaY must be finite and positive")
  checkGridNodeLimit(MaxGridNodes)
  local grid,area=zoneGridArea(self,Zone)
  local imin,imax=math.ceil(area.acrossMin/deltaY-1e-9),math.floor(area.acrossMax/deltaY+1e-9)
  local jmin,jmax=math.ceil(area.alongMin/deltaX-1e-9),math.floor(area.alongMax/deltaX+1e-9)
  local nx,nz=math.max(0,imax*1.0-imin+1),math.max(0,jmax*1.0-jmin+1)
  if MaxGridNodes and nz>0 and nx>MaxGridNodes/nz then return nil,"node_limit" end
  grid.along=deltaX/2 grid.across=deltaY/2
  self.ValidSurfaceTypes=ValidSurfaceTypes
  for i=imin,imax do
    for j=jmin,jmax do
      local x,z=gridPosition(grid,j*deltaX,i*deltaY)
      if Zone:IsVec2InZone({x=x,y=z}) then
        local vector=VECTOR:New(x,0,z)
        local node=self:GetNodeFromCoordinate(vector)
        if self:CheckValidSurfaceType(node,ValidSurfaceTypes) then
          node.rectGrid=grid
          self:AddNode(node)
          if MarkGrid then vector:Mark(string.format("i=%d, j=%d surface=%d",i,j,node.surfacetype)) end
        end
      end
    end
  end
  self:T(self.lid..string.format("Built zone rectangular grid with %d total nodes",self.Nnodes))
  return self
end

--- Enlarge an existing hex lattice without replacing its nodes, origin, orientation or spacing.
-- Adds centers outside the previous search rectangle. The first enlargement of a zone seed also fills previously unvisited cells inside that rectangle.
-- Previously sampled cells, including surface-filtered ones, are retained without resampling. Identical dimensions leave a zone seed unchanged.
-- Does not change endpoints or redraw polygons automatically. MarkGrid text markers follow the original grid setting.
-- @param #ASTAR self
-- @param #number BoxHY New total perpendicular width in meters; must be finite and at least the current width.
-- @param #number SpaceX New margin at both ends of the original start-to-goal line; must be finite and at least the current margin.
-- @param #number MaxGridNodes (Optional) Maximum number of lattice centers before surface filtering. Checked before any additions.
-- @return #ASTAR self on success, or nil if the candidate-cell limit would be exceeded.
-- @return #string Failure reason: node_limit, or nil on success.
function ASTAR:ExpandHexGrid(BoxHY, SpaceX, MaxGridNodes)

  local grid=self.hexGrid
  assert(grid, "ASTAR: call CreateHexGrid before expanding")
  checkGridDimensions(BoxHY, SpaceX)
  assert(BoxHY>=grid.boxHY and SpaceX>=grid.spaceX, "ASTAR: hex width and margin cannot shrink")
  checkGridNodeLimit(MaxGridNodes)
  if BoxHY==grid.boxHY and SpaceX==grid.spaceX then
    if MaxGridNodes and grid.candidateCount>MaxGridNodes then return nil,"node_limit" end
    return self
  end
  local bounds=hexBounds(grid, BoxHY, SpaceX, MaxGridNodes)
  if not bounds then return nil, "node_limit" end
  return self:_PopulateHexGrid(bounds, BoxHY, SpaceX)
end

--- Add the new cells from preflighted hex bounds. Used by creation and enlargement.
-- @param #ASTAR self
-- @param #table Bounds Axial row ranges and candidate count.
-- @param #number BoxHY New total width.
-- @param #number SpaceX New margin.
-- @param Core.Zone#ZONE_BASE Zone Optional zone filter for the initial build only.
-- @return #ASTAR self
function ASTAR:_PopulateHexGrid(Bounds, BoxHY, SpaceX, Zone)

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
            if grid.markGrid then
              vector:Mark(string.format("Hex q=%d r=%d surface=%d", q, r, node.surfacetype))
            end
          end
        end
      end
    end
  end
  grid.initialSamples=sampled
  grid.boxHY=BoxHY
  grid.spaceX=SpaceX
  grid.candidateCount=Bounds.count
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Grid drawing
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Draw accepted grid cells on the F10 map, replacing the previous DrawGrid() overlay.
-- Draws one polygon per generated node, with the original grid orientation. Manual nodes and extra endpoints are skipped.
-- Hex vertex radius is Spacing / sqrt(3); rectangular half-sizes are deltaX/2 and deltaY/2.
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
-- In hex-only mode, any 2D displacement greater than 0.000001 meters creates an exact endpoint instead of snapping.
-- Sets startNode to nil if the node set is empty or an added endpoint fails the surface filter.
-- @param #ASTAR self
-- @return #ASTAR self
function ASTAR:FindStartNode()
  self.startNode=self:_FindEndpoint(self.startVector, "start")
  return self
end

--- Select the closest goal node, or add an exact goal node if the closest is more than 1000 meters away.
-- In hex-only mode, any 2D displacement greater than 0.000001 meters creates an exact endpoint instead of snapping.
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
  local threshold=self.HexNeighboursOnly and 1e-6 or 1000
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
-- In hex-only mode, floods candidate adjacency (including non-grid attachments) and caches complete connected components.
-- False rules out a path in the current graph. True is only a necessary condition: LoS, road rules or infinite costs may still block the route.
-- Outside hex-only mode, all node pairs are candidates, so valid endpoint nodes return true without a graph traversal.
-- Does not call neighbour/cost callbacks or DCS visibility/road queries; newly added endpoints still sample their surface types.
-- @param #ASTAR self
-- @return #boolean Whether a path is possible before applying neighbour rules and travel costs.
-- @return #string Failure reason: missing_coordinates, no_start_node, no_goal_node, start_unattached, goal_unattached or disconnected_grid; nil on success.
function ASTAR:HasPotentialPath()
  local start, goal, reason=self:_ResolveEndpoints()
  if reason then return false, reason end
  return self:_HasPotentialPath(start, goal)
end

--- Search for a path, enlarging the hex search rectangle between failed attempts.
-- Requires a hex grid with SetHexNeighboursOnly(true). Preserves all existing nodes, callback references, spacing and lattice orientation.
-- Uses the same internal search and cheap connectivity precheck as GetPath(). A connected grid still has to pass the real rules and costs.
-- Grows width and end margins by GrowthFactor, with minimum increments of two Spacing and one Spacing respectively.
-- Stops at the first actual path (including an empty successful result), or a configured limit. Runs synchronously.
-- Retries produce trace output; error logs and optional player failure messages are emitted only at final failure.
-- @param #ASTAR self
-- @param #table Options (Optional) GrowthFactor=1.5, MaxAttempts=5 (includes initial attempt), MaxGridNodes=5000 (before surface filtering),
-- MaxBoxHY=at least the initial width or 200000 m, MaxSpaceX=at least the initial margin or 100000 m, Redraw=true.
-- Explicit dimension limits must not be smaller than the current grid. MaxGridNodes excludes manually added nodes and endpoints.
-- Redraw appends missing cells to an existing or pending overlay using its saved batch settings; it does not create an overlay without DrawGrid().
-- @param #boolean ExcludeStartNode (Optional) Same exclusion behavior as GetPath().
-- @param #boolean ExcludeEndNode (Optional) Same exclusion behavior as GetPath().
-- @return #table Path nodes, or nil on failure. The expanded grid remains available for drawing or later searches.
-- @return #table Report with Attempts (BoxHY, SpaceX, Nodes, Failure, CPUSeconds), StopReason, BoxHY, SpaceX, Nodes, SearchCPUSeconds and optional live Drawing result.
-- StopReason is path_found, attempt_limit, size_limit, node_limit or missing_coordinates. Stored in LastExpansionResult as well.
function ASTAR:GetPathWithExpansion(Options, ExcludeStartNode, ExcludeEndNode)

  assert(self.hexGrid and self.HexNeighboursOnly, "ASTAR: expanding search requires a hex grid with hex-only neighbours")
  Options=Options or {}
  assert(type(Options)=="table", "ASTAR: expansion options must be a table")
  local grid=self.hexGrid
  local factor=Options.GrowthFactor or 1.5
  local maxAttempts=Options.MaxAttempts or 5
  local maxNodes=Options.MaxGridNodes or 5000
  local maxWidth=Options.MaxBoxHY or math.max(grid.boxHY, 200000)
  local maxMargin=Options.MaxSpaceX or math.max(grid.spaceX, 100000)
  assert(type(factor)=="number" and factor>1 and factor<math.huge, "ASTAR: GrowthFactor must be finite and greater than one")
  assert(type(maxAttempts)=="number" and maxAttempts>=1 and maxAttempts<math.huge and maxAttempts==math.floor(maxAttempts), "ASTAR: MaxAttempts must be a positive integer")
  checkGridNodeLimit(maxNodes)
  assert(type(maxWidth)=="number" and maxWidth>=grid.boxHY and maxWidth<math.huge, "ASTAR: MaxBoxHY must be finite and at least the current width")
  assert(type(maxMargin)=="number" and maxMargin>=grid.spaceX and maxMargin<math.huge, "ASTAR: MaxSpaceX must be finite and at least the current margin")

  self.LastPathFailure=nil
  local searchClock=startCPUClock()
  local report={Attempts={}}
  local redraw=Options.Redraw~=false and self.GridDrawOptions~=nil and not self.GridDrawOptions.Snapshot
  local expanded=false
  local function finish(path, reason)
    report.StopReason=reason
    report.BoxHY=grid.boxHY
    report.SpaceX=grid.spaceX
    report.Nodes=self.Nnodes
    report.SearchCPUSeconds=elapsedCPU(searchClock)
    self.LastExpansionResult=report
    self:T(self.lid..string.format("Expanding search finished: %s after %d attempts, width %.0f m, margin %.0f m, %d nodes, search %s",
      reason, #report.Attempts, grid.boxHY, grid.spaceX, self.Nnodes, cpuTimeText(report.SearchCPUSeconds)))
    if not path then self:_ReportPathFailure(self.LastPathFailure or reason, reason) end
    if expanded and redraw then
      self:UpdateGridDrawing()
      report.Drawing=self.LastGridDrawResult
    end
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
    report.Attempts[#report.Attempts+1]={BoxHY=grid.boxHY, SpaceX=grid.spaceX, Nodes=self.Nnodes, Failure=self.LastPathFailure, CPUSeconds=self.LastSearchTiming.CPUSeconds}
    if path then return finish(path, "path_found") end
    if self.LastPathFailure=="missing_coordinates" then return finish(nil, "missing_coordinates") end
    if attempt==maxAttempts then return finish(nil, "attempt_limit") end

    local width=math.min(maxWidth, math.max(grid.boxHY*factor, grid.boxHY+2*grid.spacing))
    local margin=math.min(maxMargin, math.max(grid.spaceX*factor, grid.spaceX+grid.spacing))
    if width==grid.boxHY and margin==grid.spaceX then return finish(nil, "size_limit") end
    local success, reason=self:ExpandHexGrid(width, margin, maxNodes)
    if not success then return finish(nil, reason) end
    expanded=true
  end
end

--- Search synchronously for a least-cost path between the selected start and goal nodes.
-- Returns nodes in travel order; use GetNodeCoordinate(node) to obtain COORDINATE objects for waypoints.
-- Does not assign a route to a unit or group.
-- Endpoint exclusions can produce an empty table for a successful search. Nil indicates failure.
-- In hex-only mode, rejects disconnected candidate components before evaluating any neighbour rule or cost.
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
  if not self.HexNeighboursOnly or start.id==goal.id then return true end
  if not self.hexLinks then self:_BuildHexLinks() end

  if start.q==nil and next(self.hexLinks[start.id] or {})==nil then return false, "start_unattached" end
  if goal.q==nil and next(self.hexLinks[goal.id] or {})==nil then return false, "goal_unattached" end

  local components=self.hexComponents
  local component=components[start.id]
  if not component then
    component=start.id
    local queue={start.id}
    local head=1
    components[start.id]=component
    while head<=#queue do
      local nid=queue[head]
      head=head+1
      for neighborID in pairs(self.hexLinks[nid] or {}) do
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

  if self.HexNeighboursOnly then
    if not self.hexLinks then self:_BuildHexLinks() end
    for nid in pairs(self.hexLinks[theNode.id] or {}) do
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

  self.hexLinks=links
  self.hexComponents={}
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
