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
-- @field Core.Point#COORDINATE startCoord Start coordinate.
-- @field Core.Point#COORDINATE endCoord End coordinate.
-- @field #function ValidNeighbourFunc Symmetric function to check whether a connection between two nodes is valid.
-- @field #table ValidNeighbourArg Optional arguments passed to the valid neighbour function.
-- @field #function CostFunc Function to calculate the travel cost from one node to another.
-- @field #table CostArg Optional arguments passed to the cost function. 
-- @field #table ValidSurfaceTypes Surface filter used by the grid builder and automatically added endpoints; may also be a single numeric surface type.
-- @field #boolean HexNeighboursOnly Restrict candidates to hex edges and local endpoint attachments. Disabled by default.
-- @field #table hexGrid Hex geometry: origin x/z, heading cos/sin, spacing, rowSpacing, original distance, boxHY, spaceX and candidateCount.
-- @field #table hexIndex Hex nodes indexed by axial q, then r.
-- @field #table hexLinks Cached candidate adjacency, indexed by node id, then neighbour id. Does not cache rule results.
-- @field #table hexComponents Connected-component labels for hex candidates. Rebuilt when candidate adjacency changes.
-- @field #table GridDrawIDs F10 polygon ids owned by DrawGrid(), removed by UndrawGrid().
-- @field #table GridDrawOptions Last DrawGrid() style, used to refresh an expanded grid overlay.
-- @field #string LastPathFailure Reason the last GetPath() failed; nil on success.
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
-- @{#ASTAR.SetStartCoordinate} and @{#ASTAR.SetEndCoordinate} take MOOSE COORDINATE objects.
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
-- Each @{#ASTAR.Node} contains an id, a `coordinate`, the surface type sampled when it was created, and caches for
-- connection validity and travel cost. Use `node.coordinate` when consuming the path.
-- @{#ASTAR.AddNodeFromCoordinate} creates and adds a node and returns that node, rather than the ASTAR object.
-- @{#ASTAR.GetNodeFromCoordinate} only creates a node; call @{#ASTAR.AddNode} to include it in the search.
--
-- ## Rectangular Grid
--
-- @{#ASTAR.CreateGrid} accepts `ValidSurfaceTypes, BoxHY, SpaceX, deltaX, deltaY, MarkGrid`.
-- The grid is aligned with the line from start to goal. All dimensions are in meters:
--
-- * `ValidSurfaceTypes`: a list of accepted surface types, or a single surface type. Nil accepts all types.
-- * `BoxHY`: total width perpendicular to start-goal, default 40000 (20000 on each side).
-- * `SpaceX`: extra space before the start and beyond the goal, default 10000 at each end.
-- * `deltaX`: node spacing along start-goal, default 2000; must be positive.
-- * `deltaY`: perpendicular node spacing, default the value of deltaX; must be positive.
-- * `MarkGrid`: set true to mark accepted grid nodes on the F10 map; disabled by default.
--
-- Make the width and end margins large enough to contain the detours you want to consider. Finer spacing can represent
-- narrower passages, but increases the number of nodes. As a starting point, choose spacing smaller than half the width
-- of the narrowest relevant passage, then check the result in the mission.
-- CreateGrid() adds to the existing node set. Use a new ASTAR object to build a replacement grid.
--
-- ## Hexagonal Grid
--
-- @{#ASTAR.CreateHexGrid} accepts `ValidSurfaceTypes, BoxHY, SpaceX, Spacing, MarkGrid`.
-- The surface filter, search width, end margins and markers have the same meanings and defaults as for CreateGrid().
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
-- ## Draw the Grid on the F10 Map
--
-- @{#ASTAR.DrawGrid} draws the accepted cells as polygons: hexagons for CreateHexGrid(), rectangles for CreateGrid().
-- Each cell is centered on its node and rotates with the grid. Manual nodes and automatically added endpoints have no cell outline.
-- Only the node center was surface-filtered; a drawn cell may still cover unsuitable terrain or extend beyond the search rectangle.
-- The outlines show the sampling grid, not the allowed connections or guaranteed traversable areas.
--
-- By default, all coalitions see blue solid outlines with no fill. Optional coalition, RGB colors, opacity, line style,
-- and read-only settings follow the MOOSE coordinate drawing functions. One DCS polygon is created per accepted cell.
-- DrawGrid() first removes its previous polygons, so calling it again updates the display without accumulating duplicates.
-- @{#ASTAR.UndrawGrid} removes only those polygons; it preserves nodes, paths and the separate text markers from MarkGrid=true.
-- Adding nodes or calling ExpandHexGrid() does not redraw automatically. Call DrawGrid() again after changing the node set.
-- GetPathWithExpansion() can refresh an existing overlay automatically once its attempts finish.
--
-- On an existing ASTAR object with a generated grid:
--
--     astar:DrawGrid()                             -- All coalitions, blue outlines, no fill.
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
-- Old cells, including rejected cells, are not sampled again. Use a new object if the surface filter or the original lattice must change.
--
-- The first argument is an optional settings table:
--
-- * `GrowthFactor`: multiply width and end margins by this factor, default 1.5; must be finite and greater than 1.
-- * `MaxAttempts`: maximum number of searches, including the initial grid, default 5.
-- * `MaxGridNodes`: maximum number of lattice centers BEFORE surface filtering, default 5000. Includes filtered cells because they require
--   terrain sampling, but excludes manual points and exact endpoint nodes. Expansion is rejected before sampling if it would exceed the limit.
-- * `MaxBoxHY`: maximum total width, default the larger of the initial width and 200000 meters.
-- * `MaxSpaceX`: maximum margin at each end, default the larger of the initial margin and 100000 meters.
-- * `Redraw`: refresh an existing DrawGrid() overlay once at completion, with its original style; default true. Set false to manage drawing yourself.
--
-- Width grows by at least two Spacing and margins by at least one Spacing, so zero initial margins can grow as well.
-- Dimension caps take precedence. Explicit dimension caps cannot be smaller than the current grid; attempt and cell limits must be positive integers.
-- An initial grid already above MaxGridNodes is rejected without running a search. A rejected expansion leaves the current grid intact.
--
-- GetPathWithExpansion(Options, ExcludeStartNode, ExcludeEndNode) returns `path, report`. Endpoint exclusion flags behave as in GetPath().
-- A successful empty path is still success. The report is also stored in `astar.LastExpansionResult` and contains:
--
-- * `Attempts`: one entry per search, with BoxHY, SpaceX, accepted Nodes (including extra endpoints), and Failure (nil on success).
-- * `StopReason`: path_found, attempt_limit, size_limit, node_limit, or missing_coordinates.
-- * `BoxHY`, `SpaceX`, `Nodes`: final dimensions and accepted node count. The expanded grid stays on the same object for drawing or reuse.
--
-- `HasPotentialPath()` also returns a second value on failure; GetPath() stores its reason in `LastPathFailure`:
-- missing_coordinates, no_start_node, no_goal_node, start_unattached, goal_unattached, or disconnected_grid.
-- The unattached reasons specifically mean a non-grid endpoint has no accepted hex center within one Spacing.
-- If candidate connectivity exists but the full search fails, LastPathFailure is connections_blocked.
-- Attempts and dimensions are logged, allowing you to see why and how far the search grew.
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
-- DrawGrid() also runs synchronously and creates one polygon per cell; use it on reasonably sized grids and remove the overlay when finished.
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
--         node.coordinate:MarkToAll(string.format("ASTAR waypoint %d", i))
--       end
--     else
--       env.info("ASTAR: no water route found")
--     end
--
-- ## Find a Water Route with Automatic Expansion
--
-- Use the same two water-based trigger zones as above. This starts with a 40 km wide grid and 10 km end margins.
-- GetPathWithExpansion() handles the precheck internally; do not abort the script first when HasPotentialPath() is false.
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
--     local path, report = astar:GetPathWithExpansion({
--       GrowthFactor = 1.5, MaxAttempts = 5, MaxGridNodes = 5000,
--       MaxBoxHY = 200000, MaxSpaceX = 100000
--     })
--     astar:DrawGrid()
--     if path then
--       for i, node in ipairs(path) do
--         node.coordinate:MarkToAll(string.format("Expanded route waypoint %d", i))
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
--         node.coordinate:MarkToAll(string.format("Hex route waypoint %d", i))
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
--     local start = astar:AddNodeFromCoordinate(COORDINATE:New(0, 0, 0))
--     local middle = astar:AddNodeFromCoordinate(COORDINATE:New(1000, 0, 1000))
--     local goal = astar:AddNodeFromCoordinate(COORDINATE:New(2000, 0, 0))
--     astar:SetStartCoordinate(start.coordinate)
--     astar:SetEndCoordinate(goal.coordinate)
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
-- @field Core.Point#COORDINATE coordinate Coordinate of the node.
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
ASTAR.version="0.6.0"

-- Six axial offsets; adjacent centers are one spacing apart.
local hexDirections={{1,0}, {0,1}, {-1,1}, {-1,0}, {0,-1}, {1,-1}}

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
-- @param Core.Point#COORDINATE Coordinate Start coordinate.
-- @return #ASTAR self
function ASTAR:SetStartCoordinate(Coordinate)

  self.startCoord=Coordinate
  
  return self
end

--- Set the requested goal coordinate. Does not create a node or rebuild the grid.
-- @param #ASTAR self
-- @param Core.Point#COORDINATE Coordinate end coordinate.
-- @return #ASTAR self
function ASTAR:SetEndCoordinate(Coordinate)

  self.endCoord=Coordinate
  
  return self
end

--- Create a node from a coordinate without adding it to the search node set.
-- The coordinate reference and its current surface type are stored in the node.
-- @param #ASTAR self
-- @param Core.Point#COORDINATE Coordinate The coordinate where to create the node.
-- @return #ASTAR.Node The node.
function ASTAR:GetNodeFromCoordinate(Coordinate)

  local node={} --#ASTAR.Node
  
  node.coordinate=Coordinate
  node.surfacetype=Coordinate:GetSurfaceType()
  node.id=self.counter
  
  node.valid={}
  node.cost={}
  
  self.counter=self.counter+1
  
  return node
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
-- @param Core.Point#COORDINATE Coordinate The coordinate where the node is created.
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
-- @param #number deltaX (Optional) Positive spacing along start-to-goal in meters. Default 2000 meters.
-- @param #number deltaY (Optional) Positive perpendicular spacing in meters. Default is the same as deltaX.
-- @param #boolean MarkGrid (Optional) If true, create F10 markers at accepted grid nodes. Disabled by default; large grids can stall DCS.
-- @return #ASTAR self
function ASTAR:CreateGrid(ValidSurfaceTypes, BoxHY, SpaceX, deltaX, deltaY, MarkGrid)

  assert(not self.hexGrid, "ASTAR: use a new object for a rectangular grid after a hex grid")
  self.ValidSurfaceTypes=ValidSurfaceTypes

  -- Note that internally
  -- x coordinate is z: x-->z  Line from start to end
  -- y coordinate is x: y-->x  Perpendicular

  -- Grid length and width.
  local Dz=SpaceX or 10000
  local Dx=BoxHY and BoxHY/2 or 20000

  -- Increments.
  local dz=deltaX or 2000  
  local dx=deltaY or dz
  
  -- Heading from start to end coordinate.
  local angle=self.startCoord:HeadingTo(self.endCoord)

  -- Retain each generated grid's orientation and cell size for optional F10 drawing.
  local rectGrid={along=dz/2, across=dx/2, cos=math.cos(math.rad(angle)), sin=math.sin(math.rad(angle))}
  
  --Distance between start and end.
  local dist=self.startCoord:Get2DDistance(self.endCoord)+2*Dz
  
  -- Origin of map. Needed to translate back to wanted position.
  local co=COORDINATE:New(0, 0, 0)
  local do1=co:Get2DDistance(self.startCoord)
  local ho1=co:HeadingTo(self.startCoord)
  
  -- Start of grid.
  local xmin=-Dx
  local zmin=-Dz
  
  -- Number of grid points.
  local nz=dist/dz+1
  local nx=2*Dx/dx+1
  
  -- Debug info.
  local text=string.format("Building grid with nx=%d ny=%d => total=%d nodes", nx, nz, nx*nz)
  self:T(self.lid..text)
  
  -- Loop over x and z coordinate to create a 2D grid.
  for i=1,nx do
  
    -- x coordinate perpendicular to z.
    local x=xmin+dx*(i-1)
  
    for j=1,nz do
    
      -- z coordinate connecting start and end.
      local z=zmin+dz*(j-1)
      
      -- Rotate 2D.
      local vec3=UTILS.Rotate2D({x=x, y=0, z=z}, angle)
      
      -- Coordinate of the node.
      local c=COORDINATE:New(vec3.z, vec3.y, vec3.x):Translate(do1, ho1, true)
        
      -- Create a node at this coordinate.
      local node=self:GetNodeFromCoordinate(c)
        
      -- Check if node has valid surface type.
      if self:CheckValidSurfaceType(node, ValidSurfaceTypes) then
          
        if MarkGrid then
          c:MarkToAll(string.format("i=%d, j=%d surface=%d", i, j, node.surfacetype))
        end
          
        -- Add node to grid.
        node.rectGrid=rectGrid
        self:AddNode(node)
        
      end
    
    end
  end
    
  -- Debug info.
  local text=string.format("Done building grid!")
  self:T2(self.lid..text)

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
-- @return #ASTAR self
function ASTAR:CreateHexGrid(ValidSurfaceTypes, BoxHY, SpaceX, Spacing, MarkGrid)

  BoxHY=BoxHY or 40000
  SpaceX=SpaceX or 10000
  Spacing=Spacing or 2000
  assert(self.startCoord and self.endCoord, "ASTAR: start and end coordinates are required for a hex grid")
  assert(not self.hexGrid and next(self.nodes)==nil, "ASTAR: create a hex grid on an empty ASTAR object")
  assert(type(BoxHY)=="number" and BoxHY>=0 and BoxHY<math.huge, "ASTAR: BoxHY must be finite and non-negative")
  assert(type(SpaceX)=="number" and SpaceX>=0 and SpaceX<math.huge, "ASTAR: SpaceX must be finite and non-negative")
  assert(type(Spacing)=="number" and Spacing>0 and Spacing<math.huge, "ASTAR: Spacing must be finite and positive")

  local distance=self.startCoord:Get2DDistance(self.endCoord)
  local angle=distance>0 and math.rad(self.startCoord:HeadingTo(self.endCoord)) or 0
  local rowSpacing=Spacing*math.sqrt(3)/2
  self.hexGrid={x=self.startCoord.x, z=self.startCoord.z, cos=math.cos(angle), sin=math.sin(angle), spacing=Spacing, rowSpacing=rowSpacing,
    distance=distance, markGrid=MarkGrid}
  self.hexIndex={}
  self.ValidSurfaceTypes=ValidSurfaceTypes

  self:ExpandHexGrid(BoxHY, SpaceX)
  self:T(self.lid..string.format("Built hex grid with %d nodes, spacing %.1f m", self.Nnodes, Spacing))
  return self
end

--- Enlarge an existing hex lattice without replacing its nodes, origin, orientation or spacing.
-- Adds only centers outside the previous search rectangle, including when the old cells were surface-filtered out.
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
  assert(type(BoxHY)=="number" and BoxHY>=0 and BoxHY<math.huge and BoxHY>=(grid.boxHY or 0), "ASTAR: hex width must be finite and cannot shrink")
  assert(type(SpaceX)=="number" and SpaceX>=0 and SpaceX<math.huge and SpaceX>=(grid.spaceX or 0), "ASTAR: hex margin must be finite and cannot shrink")
  if MaxGridNodes~=nil then
    assert(type(MaxGridNodes)=="number" and MaxGridNodes>=1 and MaxGridNodes<math.huge and MaxGridNodes==math.floor(MaxGridNodes), "ASTAR: MaxGridNodes must be a positive integer")
  end

  local Spacing=grid.spacing
  local rowSpacing=grid.rowSpacing
  -- Local coordinates: along = spacing * (q + r/2), across = rowSpacing * r.
  -- The small tolerance includes centers on a boundary despite floating-point rounding.
  local epsilon=1e-9
  local rmin=math.ceil(-BoxHY/2/rowSpacing-epsilon)
  local rmax=math.floor(BoxHY/2/rowSpacing+epsilon)
  -- Count candidates first; filtered cells still consume sampling work. No DCS queries are needed here.
  local candidates=0
  for r=rmin,rmax do
    local qmin=math.ceil(-SpaceX/Spacing-r/2-epsilon)
    local qmax=math.floor((grid.distance+SpaceX)/Spacing-r/2+epsilon)
    candidates=candidates+math.max(0, qmax-qmin+1)
    if MaxGridNodes and candidates>MaxGridNodes then return nil, "node_limit" end
  end

  local oldRmin=grid.boxHY and math.ceil(-grid.boxHY/2/rowSpacing-epsilon)
  local oldRmax=grid.boxHY and math.floor(grid.boxHY/2/rowSpacing+epsilon)
  for r=rmin,rmax do
    local qmin=math.ceil(-SpaceX/Spacing-r/2-epsilon)
    local qmax=math.floor((grid.distance+SpaceX)/Spacing-r/2+epsilon)
    local oldQmin=grid.spaceX and math.ceil(-grid.spaceX/Spacing-r/2-epsilon)
    local oldQmax=grid.spaceX and math.floor((grid.distance+grid.spaceX)/Spacing-r/2+epsilon)
    for q=qmin,qmax do
      local existingCell=oldRmin and r>=oldRmin and r<=oldRmax and q>=oldQmin and q<=oldQmax
      if not existingCell then
        local along=Spacing*(q+r/2)
        local across=rowSpacing*r
        local coordinate=COORDINATE:New(grid.x+along*grid.cos-across*grid.sin, 0, grid.z+along*grid.sin+across*grid.cos)
        local node=self:GetNodeFromCoordinate(coordinate)
        if self:CheckValidSurfaceType(node, self.ValidSurfaceTypes) then
          node.q=q
          node.r=r
          self:AddNode(node)
          if grid.markGrid then
            coordinate:MarkToAll(string.format("Hex q=%d r=%d surface=%d", q, r, node.surfacetype))
          end
        end
      end
    end
  end

  grid.boxHY=BoxHY
  grid.spaceX=SpaceX
  grid.candidateCount=candidates
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Grid drawing
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Draw accepted grid cells on the F10 map, replacing the previous DrawGrid() overlay.
-- Draws one polygon per generated node, with the original grid orientation. Manual nodes and extra endpoints are skipped.
-- Hex vertex radius is Spacing / sqrt(3); rectangular half-sizes are deltaX/2 and deltaY/2.
-- Cells may extend beyond the search area or cover terrain rejected at other node positions. The overlay does not show connectivity.
-- Does not change pathfinding. Large grids can stall DCS while drawing.
-- @param #ASTAR self
-- @param #number Coalition (Optional) All=-1, Neutral=0, Red=1, Blue=2. Default -1.
-- @param #table Color (Optional) Outline RGB values in [0,1], default {0,0,1} (blue).
-- @param #number Alpha (Optional) Outline opacity in [0,1], default 1.
-- @param #table FillColor (Optional) Fill RGB values, default the outline color.
-- @param #number FillAlpha (Optional) Fill opacity in [0,1], default 0 (transparent).
-- @param #number LineType (Optional) 0=none, 1=solid, 2=dashed, 3=dotted, 4=dot dash, 5=long dash, 6=two dash. Default 1.
-- @param #boolean ReadOnly (Optional) Prevent users from removing polygons manually. Default true.
-- @return #ASTAR self
function ASTAR:DrawGrid(Coalition, Color, Alpha, FillColor, FillAlpha, LineType, ReadOnly)

  self:UndrawGrid()
  Coalition=Coalition or -1
  Color=Color or {0,0,1}
  FillColor=FillColor or Color
  -- COORDINATE drawing functions add alpha to color tables; keep caller-owned RGB tables unchanged.
  local outline={Color[1], Color[2], Color[3]}
  local fill={FillColor[1], FillColor[2], FillColor[3]}
  Alpha=Alpha or 1
  FillAlpha=FillAlpha or 0
  LineType=LineType or 1
  if ReadOnly==nil then ReadOnly=true end

  self.GridDrawOptions={Coalition=Coalition, Color={outline[1],outline[2],outline[3]}, Alpha=Alpha,
    FillColor={fill[1],fill[2],fill[3]}, FillAlpha=FillAlpha, LineType=LineType, ReadOnly=ReadOnly}

  for _,node in pairs(self.nodes) do
    local corners={}
    local grid=node.rectGrid
    if self.hexGrid and node.q~=nil and node.r~=nil then
      grid=self.hexGrid
      local radius=grid.spacing/math.sqrt(3)
      for i=0,5 do
        -- Vertex bearings are 30 degrees from the q axis; sides bisect adjacent node centers.
        local angle=math.rad(30+60*i)
        local along=radius*math.cos(angle)
        local across=radius*math.sin(angle)
        corners[#corners+1]=COORDINATE:New(node.coordinate.x+along*grid.cos-across*grid.sin, 0,
          node.coordinate.z+along*grid.sin+across*grid.cos)
      end
    elseif grid then
      for _,offset in ipairs({{grid.along,grid.across}, {-grid.along,grid.across}, {-grid.along,-grid.across}, {grid.along,-grid.across}}) do
        corners[#corners+1]=COORDINATE:New(node.coordinate.x+offset[1]*grid.cos-offset[2]*grid.sin, 0,
          node.coordinate.z+offset[1]*grid.sin+offset[2]*grid.cos)
      end
    end

    if #corners>0 then
      local first=table.remove(corners, 1)
      local markID=first:MarkupToAllFreeForm(corners, Coalition, outline, Alpha, fill, FillAlpha, LineType, ReadOnly)
      self.GridDrawIDs[#self.GridDrawIDs+1]=markID
    end
  end

  return self
end

--- Remove polygons created by DrawGrid() without changing the grid or deleting other F10 marks.
-- Safe to call repeatedly or before drawing. Does not remove text markers created with MarkGrid=true.
-- @param #ASTAR self
-- @return #ASTAR self
function ASTAR:UndrawGrid()

  for _,markID in ipairs(self.GridDrawIDs or {}) do
    COORDINATE:RemoveMark(markID)
  end
  self.GridDrawIDs={}
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
  
  local cA=nodeA.coordinate:GetVec3()
  local cB=nodeB.coordinate:GetVec3()
  cA.y=offset
  cB.y=offset

  local los=land.isVisible(cA, cB)
  
  if los and corridor then
  
    -- Heading from A to B.
    local heading=nodeA.coordinate:HeadingTo(nodeB.coordinate)
    
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

  local path=land.findPathOnRoads("roads", nodeA.coordinate.x, nodeA.coordinate.z, nodeB.coordinate.x, nodeB.coordinate.z)
  
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

  local dist=nodeA.coordinate:Get2DDistance(nodeB.coordinate)
  
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
  local dist=nodeA.coordinate:Get2DDistance(nodeB.coordinate)
  return dist
end

--- Return the straight-line 3D distance between two nodes, including their altitudes.
-- @param #ASTAR.Node nodeA First node.
-- @param #ASTAR.Node nodeB Other node.
-- @return #number Distance between the two nodes.
function ASTAR.Dist3D(nodeA, nodeB)
  local dist=nodeA.coordinate:Get3DDistance(nodeB.coordinate)
  return dist
end

--- Return the length of the road path from land.findPathOnRoads between two nodes.
-- @param #ASTAR.Node nodeA First node.
-- @param #ASTAR.Node nodeB Other node.
-- @return #number Road path length in meters, or math.huge if DCS returns no path.
function ASTAR.DistRoad(nodeA, nodeB)

  -- Get the path.
  local path=land.findPathOnRoads("roads", nodeA.coordinate.x, nodeA.coordinate.z, nodeB.coordinate.x, nodeB.coordinate.z)
  
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
-- @param Core.Point#COORDINATE Coordinate Reference coordinate.
-- @return #ASTAR.Node Closest node by 2D distance, or nil if the node set is empty.
-- @return #number Distance to the closest node in meters, or math.huge if the node set is empty.
function ASTAR:FindClosestNode(Coordinate)

  local distMin=math.huge
  local closeNode=nil
  
  for _,_node in pairs(self.nodes) do
    local node=_node --#ASTAR.Node
    
    local dist=node.coordinate:Get2DDistance(Coordinate)
    
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

  local node, dist=self:FindClosestNode(self.startCoord)
  
  self.startNode=node
  
  local threshold=self.HexNeighboursOnly and 1e-6 or 1000
  if node and dist>threshold then
    self:T(self.lid.."Adding start node to node grid!")
    local endpoint=self:GetNodeFromCoordinate(self.startCoord)
    self.startNode=nil
    if self:CheckValidSurfaceType(endpoint, self.ValidSurfaceTypes) then
      self:AddNode(endpoint)
      self.startNode=endpoint
    end
  end
    
  return self
end

--- Select the closest goal node, or add an exact goal node if the closest is more than 1000 meters away.
-- In hex-only mode, any 2D displacement greater than 0.000001 meters creates an exact endpoint instead of snapping.
-- Sets endNode to nil if the node set is empty or an added endpoint fails the surface filter.
-- @param #ASTAR self
-- @return #ASTAR self
function ASTAR:FindEndNode()

  local node, dist=self:FindClosestNode(self.endCoord)

  self.endNode=node
  
  local threshold=self.HexNeighboursOnly and 1e-6 or 1000
  if node and dist>threshold then
    self:T(self.lid.."Adding end node to node grid!")
    local endpoint=self:GetNodeFromCoordinate(self.endCoord)
    self.endNode=nil
    if self:CheckValidSurfaceType(endpoint, self.ValidSurfaceTypes) then
      self:AddNode(endpoint)
      self.endNode=endpoint
    end
  end
    
  return self
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

  if not self.startCoord or not self.endCoord then return false, "missing_coordinates" end
  self:FindStartNode()
  self:FindEndNode()
  return self:_HasPotentialPath(self.startNode, self.endNode)
end

--- Search for a path, enlarging the hex search rectangle between failed attempts.
-- Requires a hex grid with SetHexNeighboursOnly(true). Preserves all existing nodes, callback references, spacing and lattice orientation.
-- Each attempt runs GetPath(), including its cheap connectivity precheck. A connected grid still has to pass the real rules and costs.
-- Grows width and end margins by GrowthFactor, with minimum increments of two Spacing and one Spacing respectively.
-- Stops at the first actual path (including an empty successful result), or a configured limit. Runs synchronously.
-- @param #ASTAR self
-- @param #table Options (Optional) GrowthFactor=1.5, MaxAttempts=5 (includes initial attempt), MaxGridNodes=5000 (before surface filtering),
-- MaxBoxHY=at least the initial width or 200000 m, MaxSpaceX=at least the initial margin or 100000 m, Redraw=true.
-- Explicit dimension limits must not be smaller than the current grid. MaxGridNodes excludes manually added nodes and endpoints.
-- Redraw refreshes an existing DrawGrid() overlay once at completion, preserving its style; it does not create an overlay if none was drawn.
-- @param #boolean ExcludeStartNode (Optional) Forwarded to GetPath().
-- @param #boolean ExcludeEndNode (Optional) Forwarded to GetPath().
-- @return #table Path nodes, or nil on failure. The expanded grid remains available for drawing or later searches.
-- @return #table Report with Attempts (BoxHY, SpaceX, Nodes, Failure), StopReason, BoxHY, SpaceX and Nodes.
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
  assert(type(maxNodes)=="number" and maxNodes>=1 and maxNodes<math.huge and maxNodes==math.floor(maxNodes), "ASTAR: MaxGridNodes must be a positive integer")
  assert(type(maxWidth)=="number" and maxWidth>=grid.boxHY and maxWidth<math.huge, "ASTAR: MaxBoxHY must be finite and at least the current width")
  assert(type(maxMargin)=="number" and maxMargin>=grid.spaceX and maxMargin<math.huge, "ASTAR: MaxSpaceX must be finite and at least the current margin")

  local report={Attempts={}}
  local style=self.GridDrawOptions
  local redraw=Options.Redraw~=false and style and #(self.GridDrawIDs or {})>0
  local expanded=false
  local function finish(path, reason)
    report.StopReason=reason
    report.BoxHY=grid.boxHY
    report.SpaceX=grid.spaceX
    report.Nodes=self.Nnodes
    self.LastExpansionResult=report
    if expanded and redraw then
      self:DrawGrid(style.Coalition, style.Color, style.Alpha, style.FillColor, style.FillAlpha, style.LineType, style.ReadOnly)
    end
    self:T(self.lid..string.format("Expanding search finished: %s after %d attempts, width %.0f m, margin %.0f m, %d nodes",
      reason, #report.Attempts, grid.boxHY, grid.spaceX, self.Nnodes))
    return path, report
  end

  if grid.candidateCount>maxNodes then return finish(nil, "node_limit") end
  for attempt=1,maxAttempts do
    self:T(self.lid..string.format("Expanding search attempt %d/%d: width %.0f m, margin %.0f m, %d nodes",
      attempt, maxAttempts, grid.boxHY, grid.spaceX, self.Nnodes))
    local path=self:GetPath(ExcludeStartNode, ExcludeEndNode)
    report.Attempts[#report.Attempts+1]={BoxHY=grid.boxHY, SpaceX=grid.spaceX, Nodes=self.Nnodes, Failure=self.LastPathFailure}
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
-- Returns nodes in travel order; use each node's coordinate to create waypoints. Does not assign a route to a unit or group.
-- Endpoint exclusions can produce an empty table for a successful search. Nil indicates failure.
-- In hex-only mode, rejects disconnected candidate components before evaluating any neighbour rule or cost.
-- @param #ASTAR self
-- @param #boolean ExcludeStartNode If *true*, do not include start node in found path. Default is to include it.
-- @param #boolean ExcludeEndNode If *true*, do not include end node in found path. Default is to include it.
-- @return #table Ordered list of ASTAR.Node entries (possibly empty), or nil for missing coordinates, missing endpoint nodes, or an unreachable goal.
function ASTAR:GetPath(ExcludeStartNode, ExcludeEndNode)

  self.LastPathFailure=nil
  if not self.startCoord or not self.endCoord then
    self.LastPathFailure="missing_coordinates"
    self:E(self.lid.."Start and end coordinates are required!")
    return nil
  end

  self:FindStartNode()
  self:FindEndNode()

  local nodes=self.nodes
  local start=self.startNode
  local goal=self.endNode

  if not start or not goal then
    self.LastPathFailure=not start and "no_start_node" or "no_goal_node"
    self:E(self.lid.."Could NOT find valid start/end nodes!")
    return nil
  end

  if self.HexNeighboursOnly then
    local potential, reason=self:_HasPotentialPath(start, goal)
    if not potential then
      self.LastPathFailure=reason
      local explanations={start_unattached="start has no hex attachment within one grid spacing",
        goal_unattached="goal has no hex attachment within one grid spacing",
        disconnected_grid="start and goal belong to disconnected grid components"}
      local text="Could NOT find valid path: "..(explanations[reason] or reason).." ["..reason.."]"
      self:E(self.lid..text)
      MESSAGE:New(text, 60, "ASTAR"):ToAllIf(self.Debug)
      return nil
    end
  end

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
  
  -- Set start time.
  local T0=timer.getAbsTime()

  -- Debug message.
  local text=string.format("Starting A* pathfinding with %d Nodes", self.Nnodes)
  self:T(self.lid..text)
  
  local Tstart=UTILS.GetOSTime()

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
      
      local Tstop=UTILS.GetOSTime()
      
      local dT=nil
      if Tstart and Tstop then
        dT=Tstop-Tstart
      end
      
      -- Debug message.
      local text=string.format("Found path with %d nodes (%d total)", #path, self.Nnodes)
      if dT then
        text=text..string.format(", OS Time %.6f sec", dT)
      end
      text=text..string.format(", Nvalid=%d [%d cached]", self.nvalid, self.nvalidcache)
      text=text..string.format(", Ncost=%d [%d cached]", self.ncost, self.ncostcache)
      self:T(self.lid..text)
      
      return path
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

  -- Debug message.
  local text=string.format("WARNING: Could NOT find valid path!")
  self.LastPathFailure="connections_blocked"
  self:E(self.lid..text)
  MESSAGE:New(text, 60, "ASTAR"):ToAllIf(self.Debug)
  
  return nil -- no valid path
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
  return nodeA.coordinate:Get2DDistance(nodeB.coordinate)
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
      local dx=node.coordinate.x-grid.x
      local dz=node.coordinate.z-grid.z
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

--- Reconstruct the predecessor chain, excluding the current node itself.
-- @param #ASTAR self
-- @param #table flat_path Flat path.
-- @param #table map Map.
-- @param #ASTAR.Node current_node The current node.
-- @return #table Ordered predecessor nodes.
function ASTAR:_UnwindPath( flat_path, map, current_node )

  if map [current_node] then
    table.insert (flat_path, 1, map[current_node]) 
    return self:_UnwindPath(flat_path, map, map[current_node])
  else
    return flat_path
  end
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
