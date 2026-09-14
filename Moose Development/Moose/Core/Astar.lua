--- **Core** - A* Pathfinding.
--
-- **Main Features:**
--
--    * Find path from A to B.
--    * Pre-defined as well as custom valid neighbour functions.
--    * Pre-defined as well as custom cost functions.
--    * Easy rectangular grid setup.
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
-- @field #table ValidSurfaceTypes Surface filter used when creating the grid and adding distant endpoints; may also be a single numeric surface type.
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
-- 2. Create a rectangular grid or add your own nodes.
-- 3. Select a neighbour rule and, optionally, a travel cost function.
-- 4. Call @{#ASTAR.GetPath} and check the result before using its nodes.
--
-- # Start and Goal
--
-- @{#ASTAR.SetStartCoordinate} and @{#ASTAR.SetEndCoordinate} take MOOSE COORDINATE objects.
-- Set both coordinates before calling @{#ASTAR.CreateGrid} or @{#ASTAR.GetPath}.
--
-- At search time, each endpoint is mapped to the nearest existing node using 2D distance. If the distance is at most
-- 1000 meters, that node is used. If it is greater, ASTAR adds a node at the requested coordinate, provided its surface
-- passes the filter from CreateGrid(). Its connections must still pass the neighbour rule.
-- An empty grid is not populated automatically by GetPath().
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
-- ## Surface Filtering
--
-- For a water-only grid, pass `{land.SurfaceType.WATER}`. This accepts exactly that type, excluding SHALLOW_WATER.
-- The filter checks the position of each node, not the terrain along connections. Two water nodes can still have land
-- between them. A suitable neighbour rule is needed to reject such connections.
--
-- # Valid Neighbours
--
-- Every other node is a potential neighbour, including distant nodes. Without a neighbour rule, all pairs are allowed.
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
--   Supply nodes with appropriate altitudes; CreateGrid() does not build a three-dimensional flight grid.
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
-- * A distant endpoint rejected by the grid surface filter.
-- * A grid that does not cover the required detour, or spacing too coarse to represent a passage.
-- * A maximum neighbour distance too small to connect the nodes, or other neighbour rules blocking the route.
-- * Connections with infinite travel cost, such as missing road connections.
--
-- # Reuse and Performance
--
-- GetPath() runs synchronously and scans all nodes when finding neighbours. Large grids and expensive road/visibility
-- checks can pause the simulation; start with a small search area and add detail only as needed.
-- F10 markers for large grids can also be expensive. Set `astar.Debug = true` to enable the no-path message to players;
-- search statistics are written through the normal MOOSE logging facilities.
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
-- ## Combine Distance and Visibility
--
-- On an existing `astar` object, replace the neighbour rule with a combined check before calling GetPath():
--
--     astar:SetValidNeighbourFunction(function(nodeA, nodeB, maxDistance, corridorWidth)
--       return ASTAR.DistMax(nodeA, nodeB, maxDistance)
--         and ASTAR.LoS(nodeA, nodeB, corridorWidth)
--     end, 3000, 500)
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

--- ASTAR infinity.
-- @field #number INF
ASTAR.INF=1/0

--- ASTAR class version.
-- @field #string version
ASTAR.version="0.4.1"

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
-- @param #ASTAR self
-- @param #ASTAR.Node Node The node to be added.
-- @return #ASTAR self
function ASTAR:AddNode(Node)

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
        self:AddNode(node)
        
      end
    
    end
  end
    
  -- Debug info.
  local text=string.format("Done building grid!")
  self:T2(self.lid..text)

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
-- Sets startNode to nil if the node set is empty or an added endpoint fails the surface filter.
-- @param #ASTAR self
-- @return #ASTAR self
function ASTAR:FindStartNode()

  local node, dist=self:FindClosestNode(self.startCoord)
  
  self.startNode=node
  
  if node and dist>1000 then
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
-- Sets endNode to nil if the node set is empty or an added endpoint fails the surface filter.
-- @param #ASTAR self
-- @return #ASTAR self
function ASTAR:FindEndNode()

  local node, dist=self:FindClosestNode(self.endCoord)

  self.endNode=node
  
  if node and dist>1000 then
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

--- Search synchronously for a least-cost path between the selected start and goal nodes.
-- Returns nodes in travel order; use each node's coordinate to create waypoints. Does not assign a route to a unit or group.
-- Endpoint exclusions can produce an empty table for a successful search. Nil indicates failure.
-- @param #ASTAR self
-- @param #boolean ExcludeStartNode If *true*, do not include start node in found path. Default is to include it.
-- @param #boolean ExcludeEndNode If *true*, do not include end node in found path. Default is to include it.
-- @return #table Ordered list of ASTAR.Node entries (possibly empty), or nil for missing coordinates, missing endpoint nodes, or an unreachable goal.
function ASTAR:GetPath(ExcludeStartNode, ExcludeEndNode)

  if not self.startCoord or not self.endCoord then
    self:E(self.lid.."Start and end coordinates are required!")
    return nil
  end

  self:FindStartNode()
  self:FindEndNode()

  local nodes=self.nodes
  local start=self.startNode
  local goal=self.endNode

  if not start or not goal then
    self:E(self.lid.."Could NOT find valid start/end nodes!")
    return nil
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
  self:E(self.lid..text)
  MESSAGE:New(text, 60, "ASTAR"):ToAllIf(self.Debug)
  
  return nil -- no valid path
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- A* pathfinding helper functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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
