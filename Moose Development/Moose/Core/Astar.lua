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
-- @module Core.Astar
-- @image CORE_Astar.png


--- ASTAR class.
-- @type ASTAR
-- @field #string ClassName Name of the class.
-- @field #boolean Debug Debug mode. Messages to all about status.
-- @field #string lid Class id string for output to DCS log file.
-- @field #table nodes Table of nodes.
-- @field #number counter Node counter.
-- @field #number Nnodes Number of nodes.
-- @field #number nvalid Number of nvalid calls.
-- @field #number nvalidcache Number of cached valid evals.
-- @field #number ncost Number of cost evaluations.
-- @field #number ncostcache Number of cached cost evals.
-- @field #ASTAR.Node startNode Start node.
-- @field #ASTAR.Node endNode End node.
-- @field Core.Point#COORDINATE startCoord Start coordinate.
-- @field Core.Point#COORDINATE endCoord End coordinate.
-- @field #function ValidNeighbourFunc Function to check if a node is valid.
-- @field #table ValidNeighbourArg Optional arguments passed to the valid neighbour function.
-- @field #function CostFunc Function to calculate the heuristic "cost" to go from one node to another.
-- @field #table CostArg Optional arguments passed to the cost function. 
-- @extends Core.Base#BASE

--- **When nothing goes right... Go left!**
--
-- ===
--
-- ![Banner Image](..\Presentations\Astar\ASTAR_Main.jpg)
--
-- # The ASTAR Concept
-- 
-- Pathfinding algorithm.
-- 
-- 
-- # Start and Goal
-- 
-- The first thing we need to define is obviously the place where we want to start and where we want to go eventually.
-- 
-- ## Start
-- 
-- The start
-- 
-- ## Goal 
-- 
-- 
-- # Nodes
-- 
-- ## Rectangular Grid
-- 
-- A rectangular grid can be created using the @{#ASTAR.CreateGrid}(*ValidSurfaceTypes, BoxHY, SpaceX, deltaX, deltaY, MarkGrid*), where
-- 
-- * *ValidSurfaceTypes* is a table of valid surface types. By default all surface types are valid.
-- * *BoxXY* is the width of the grid perpendicular the the line between start and end node. Default is 40,000 meters (40 km).
-- * *SpaceX* is the additional space behind the start and end nodes. Default is 20,000 meters (20 km).
-- * *deltaX* is the grid spacing between nodes in the direction of start and end node. Default is 2,000 meters (2 km).
-- * *deltaY* is the grid spacing perpendicular to the direction of start and end node. Default is the same as *deltaX*.
-- * *MarkGrid* If set to *true*, this places marker on the F10 map on each grid node. Note that this can stall DCS if too many nodes are created. 
-- 
-- ## Valid Surfaces
-- 
-- Certain unit types can only travel on certain surfaces types, for example
-- 
-- * Naval units can only travel on water (that also excludes shallow water in DCS currently),
-- * Ground units can only traval on land.
-- 
-- By restricting the surface type in the grid construction, we also reduce the number of nodes, which makes the algorithm more efficient.
-- 
-- ## Box Width (BoxHY)
-- 
-- The box width needs to be large enough to capture all paths you want to consider.
-- 
-- ## Space in X
-- 
-- The space in X value is important if the algorithm needs to to backwards from the start node or needs to extend even further than the end node.
-- 
-- ## Grid Spacing
-- 
-- The grid spacing is an important factor as it determines the number of nodes and hence the performance of the algorithm. It should be as large as possible.
-- However, if the value is too large, the algorithm might fail to get a valid path.
-- 
-- A good estimate of the grid spacing is to set it to be smaller (~ half the size) of the smallest gap you need to path.
-- 
-- # Valid Neighbours
-- 
-- The A* algorithm needs to know if a transition from one node to another is allowed or not. By default, hopping from one node to another is always possible.
-- 
-- ## Line of Sight
-- 
-- For naval
--  
-- 
-- # Heuristic Cost
-- 
-- In order to determine the optimal path, the pathfinding algorithm needs to know, how costly it is to go from one node to another.
-- Often, this can simply be determined by the distance between two nodes. Therefore, the default cost function is set to be the 2D distance between two nodes.
-- 
-- 
-- # Calculate the Path
-- 
-- Finally, we have to calculate the path. This is done by the @{ASTAR.GetPath}(*ExcludeStart, ExcludeEnd*) function. This function returns a table of nodes, which
-- describe the optimal path from the start node to the end node.
-- 
-- By default, the start and end node are include in the table that is returned.
-- 
-- Note that a valid path must not always exist. So you should check if the function returns *nil*.
-- 
-- Common reasons that a path cannot be found are:
-- 
-- * The grid is too small ==> increase grid size, e.g. *BoxHY* and/or *SpaceX* if you use a rectangular grid.  
-- * The grid spacing is too large ==> decrease *deltaX* and/or *deltaY*
-- * There simply is no valid path ==> you are screwed :(
-- 
-- 
-- # Examples
-- 
-- ## Strait of Hormuz
-- 
-- Carrier Group finds its way through the Stait of Hormuz.
-- 
-- ## 
-- 
--
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
-- @field #number surfacetype Surface type.
-- @field #table valid Cached valid/invalid nodes.
-- @field #table cost Cached cost.

--- ASTAR infinity.
-- @field #number INF
ASTAR.INF=1/0

--- ASTAR class version.
-- @field #string version
ASTAR.version="0.4.0"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Add more valid neighbour functions.
-- TODO: Write docs.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new ASTAR object.
-- @param #ASTAR self
-- @return #ASTAR self
function ASTAR:New()

  -- Inherit everything from INTEL class.
  local self=BASE:Inherit(self, BASE:New()) --#ASTAR

  self.lid="ASTAR | "

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set coordinate from where to start.
-- @param #ASTAR self
-- @param Core.Point#COORDINATE Coordinate Start coordinate.
-- @return #ASTAR self
function ASTAR:SetStartCoordinate(Coordinate)

  self.startCoord=Coordinate
  
  return self
end

--- Set coordinate where you want to go.
-- @param #ASTAR self
-- @param Core.Point#COORDINATE Coordinate end coordinate.
-- @return #ASTAR self
function ASTAR:SetEndCoordinate(Coordinate)

  self.endCoord=Coordinate
  
  return self
end

--- Create a node from a given coordinate.
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


--- Add a node to the table of grid nodes.
-- @param #ASTAR self
-- @param #ASTAR.Node Node The node to be added.
-- @return #ASTAR self
function ASTAR:AddNode(Node)

  self.nodes[Node.id]=Node
  self.Nnodes=self.Nnodes+1 
    
  return self
end

--- Add a node to the table of grid nodes specifying its coordinate.
-- @param #ASTAR self
-- @param Core.Point#COORDINATE Coordinate The coordinate where the node is created.
-- @return #ASTAR.Node The node.
function ASTAR:AddNodeFromCoordinate(Coordinate)

  local node=self:GetNodeFromCoordinate(Coordinate)
  
  self:AddNode(node)
    
  return node
end

--- Check if the coordinate of a node has is at a valid surface type.
-- @param #ASTAR self
-- @param #ASTAR.Node Node The node to be added.
-- @param #table SurfaceTypes Surface types, for example `{land.SurfaceType.WATER}`. By default all surface types are valid.
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

--- Add a function to determine if a neighbour of a node is valid.
-- @param #ASTAR self
-- @param #function NeighbourFunction Function that needs to return *true* for a neighbour to be valid.
-- @param ... Condition function arguments if any.
-- @return #ASTAR self
function ASTAR:SetValidNeighbourFunction(NeighbourFunction, ...)

  self.ValidNeighbourFunc=NeighbourFunction
  
  self.ValidNeighbourArg={}
  if arg then
    self.ValidNeighbourArg=arg
  end
  
  return self
end


--- Set valid neighbours to require line of sight between two nodes.
-- @param #ASTAR self
-- @param #number CorridorWidth Width of LoS corridor in meters.
-- @return #ASTAR self
function ASTAR:SetValidNeighbourLoS(CorridorWidth)

  self:SetValidNeighbourFunction(ASTAR.LoS, CorridorWidth)

  return self
end

--- Set valid neighbours to be in a certain distance.
-- @param #ASTAR self
-- @param #number MaxDistance Max distance between nodes in meters. Default is 2000 m.
-- @return #ASTAR self
function ASTAR:SetValidNeighbourDistance(MaxDistance)

  self:SetValidNeighbourFunction(ASTAR.DistMax, MaxDistance)

  return self
end

--- Set valid neighbours to be in a certain distance.
-- @param #ASTAR self
-- @param #number MaxDistance Max distance between nodes in meters. Default is 2000 m.
-- @return #ASTAR self
function ASTAR:SetValidNeighbourRoad(MaxDistance)

  self:SetValidNeighbourFunction(ASTAR.Road, MaxDistance)

  return self
end

--- Set the function which calculates the "cost" to go from one to another node.
-- The first to arguments of this function are always the two nodes under consideration. But you can add optional arguments.
-- Very often the distance between nodes is a good measure for the cost.
-- @param #ASTAR self
-- @param #function CostFunction Function that returns the "cost".
-- @param ... Condition function arguments if any.
-- @return #ASTAR self
function ASTAR:SetCostFunction(CostFunction, ...)

  self.CostFunc=CostFunction
  
  self.CostArg={}
  if arg then
    self.CostArg=arg
  end
  
  return self
end

--- Set heuristic cost to go from one node to another to be their 2D distance.
-- @param #ASTAR self
-- @return #ASTAR self
function ASTAR:SetCostDist2D()

  self:SetCostFunction(ASTAR.Dist2D)

  return self
end

--- Set heuristic cost to go from one node to another to be their 3D distance.
-- @param #ASTAR self
-- @return #ASTAR self
function ASTAR:SetCostDist3D()

  self:SetCostFunction(ASTAR.Dist3D)

  return self
end

--- Set heuristic cost to go from one node to another to be their 3D distance.
-- @param #ASTAR self
-- @return #ASTAR self
function ASTAR:SetCostRoad()

  self:SetCostFunction(ASTAR)

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Grid functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a rectangular grid of nodes between star and end coordinate.
-- The coordinate system is oriented along the line between start and end point.
-- @param #ASTAR self
-- @param #table ValidSurfaceTypes Valid surface types. By default is all surfaces are allowed.
-- @param #number BoxHY Box "height" in meters along the y-coordinate. Default 40000 meters (40 km).
-- @param #number SpaceX Additional space in meters before start and after end coordinate. Default 10000 meters (10 km).
-- @param #number deltaX Increment in the direction of start to end coordinate in meters. Default 2000 meters.
-- @param #number deltaY Increment perpendicular to the direction of start to end coordinate in meters. Default is same as deltaX.
-- @param #boolean MarkGrid If true, create F10 map markers at grid nodes.
-- @return #ASTAR self
function ASTAR:CreateGrid(ValidSurfaceTypes, BoxHY, SpaceX, deltaX, deltaY, MarkGrid)

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

--- Function to check if two nodes have line of sight (LoS).
-- @param #ASTAR.Node nodeA First node.
-- @param #ASTAR.Node nodeB Other node.
-- @param #number corridor (Optional) Width of corridor in meters.
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

--- Function to check if two nodes have a road connection.
-- @param #ASTAR.Node nodeA First node.
-- @param #ASTAR.Node nodeB Other node.
-- @return #boolean If true, two nodes are connected via a road.
function ASTAR.Road(nodeA, nodeB)

  local path=land.findPathOnRoads("roads", nodeA.coordinate.x, nodeA.coordinate.z, nodeB.coordinate.x, nodeB.coordinate.z)
  
  if path then
    return true    
  else
    return false
  end

end

--- Function to check if distance between two nodes is less than a threshold distance.
-- @param #ASTAR.Node nodeA First node.
-- @param #ASTAR.Node nodeB Other node.
-- @param #number distmax Max distance in meters. Default is 2000 m.
-- @return #boolean If true, distance between the two nodes is below threshold.
function ASTAR.DistMax(nodeA, nodeB, distmax)

  distmax=distmax or 2000

  local dist=nodeA.coordinate:Get2DDistance(nodeB.coordinate)
  
  return dist<=distmax
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Heuristic cost functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Heuristic cost is given by the 2D distance between the nodes. 
-- @param #ASTAR.Node nodeA First node.
-- @param #ASTAR.Node nodeB Other node.
-- @return #number Distance between the two nodes.
function ASTAR.Dist2D(nodeA, nodeB)
  local dist=nodeA.coordinate:Get2DDistance(nodeB)
  return dist
end

--- Heuristic cost is given by the 3D distance between the nodes. 
-- @param #ASTAR.Node nodeA First node.
-- @param #ASTAR.Node nodeB Other node.
-- @return #number Distance between the two nodes.
function ASTAR.Dist3D(nodeA, nodeB)
  local dist=nodeA.coordinate:Get3DDistance(nodeB.coordinate)
  return dist
end

--- Heuristic cost is given by the distance between the nodes on road. 
-- @param #ASTAR.Node nodeA First node.
-- @param #ASTAR.Node nodeB Other node.
-- @return #number Distance between the two nodes.
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
-- @param Core.Point#COORDINATE Coordinate.
-- @return #ASTAR.Node Cloest node to the coordinate.
-- @return #number Distance to closest node in meters.
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

--- Find the start node.
-- @param #ASTAR self
-- @param #ASTAR.Node Node The node to be added to the nodes table.
-- @return #ASTAR self
function ASTAR:FindStartNode()

  local node, dist=self:FindClosestNode(self.startCoord)
  
  self.startNode=node
  
  if dist>1000 then
    self:T(self.lid.."Adding start node to node grid!")
    self:AddNode(node)
  end
    
  return self
end

--- Add a node.
-- @param #ASTAR self
-- @param #ASTAR.Node Node The node to be added to the nodes table.
-- @return #ASTAR self
function ASTAR:FindEndNode()

  local node, dist=self:FindClosestNode(self.endCoord)

  self.endNode=node
  
  if dist>1000 then
    self:T(self.lid.."Adding end node to node grid!")
    self:AddNode(node)
  end
    
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Main A* pathfinding function
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- A* pathfinding function. This seaches the path along nodes between start and end nodes/coordinates.
-- @param #ASTAR self
-- @param #boolean ExcludeStartNode If *true*, do not include start node in found path. Default is to include it.
-- @param #boolean ExcludeEndNode If *true*, do not include end node in found path. Default is to include it.
-- @return #table Table of nodes from start to finish.
function ASTAR:GetPath(ExcludeStartNode, ExcludeEndNode)

  self:FindStartNode()
  self:FindEndNode()

  local nodes=self.nodes
  local start=self.startNode
  local goal=self.endNode

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
    
    -- Check if we are at the end node.
    if current.id==goal.id then
    
      local path=self:_UnwindPath({}, came_from, goal)
      
      if not ExcludeEndNode then
        table.insert(path, goal)
      end
      
      if ExcludeStartNode then
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
      
        local tentative_g_score=g_score[current.id]+self:_DistNodes(current, neighbor)
         
        if self:_NotIn(openset, neighbor.id) or tentative_g_score < g_score[neighbor.id] then
        
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

--- Heuristic "cost" function to go from node A to node B. Default is the distance between the nodes.
-- @param #ASTAR self
-- @param #ASTAR.Node nodeA Node A.
-- @param #ASTAR.Node nodeB Node B.
-- @return #number "Cost" to go from node A to node B.
function ASTAR:_HeuristicCost(nodeA, nodeB)
  
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
    cost=self.CostFunc(nodeA, nodeB, unpack(self.CostArg))
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
    valid=self.ValidNeighbourFunc(node, neighbor, unpack(self.ValidNeighbourArg))  
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
-- @param #number f_score F score.
-- @return #ASTAR.Node Best node.
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
-- @param #ASTAR.Node theNode The node.
-- @param #table nodes Possible neighbours.
-- @param #table Valid neighbour nodes.
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
-- @param #ASTAR.Node theNode The node to check.
-- @return #boolean If true, the node is not in the set.
function ASTAR:_NotIn(set, theNode)
  return set[theNode]==nil
end

--- Unwind path function.
-- @param #ASTAR self
-- @param #table flat_path Flat path.
-- @param #table map Map.
-- @param #ASTAR.Node current_node The current node.
-- @return #table Unwinded path.
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