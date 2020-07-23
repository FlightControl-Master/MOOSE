--- **Core** - A* Pathfinding.
--
-- **Main Features:**
--
--    * Stuff
--
-- ===
--
-- ### Author: **funkyfranky**
-- @module Core.Astar
-- @image CORE_Atar.png


--- ASTAR class.
-- @type ASTAR
-- @field #string ClassName Name of the class.
-- @field #boolean Debug Debug mode. Messages to all about status.
-- @field #string lid Class id string for output to DCS log file.
-- @field #table nodes Table of nodes.
-- @field #ASTAR.Node startNode Start node.
-- @field #ASTAR.Node endNode End node.
-- @field Core.Point#COORDINATE startCoord Start coordinate.
-- @field Core.Point#COORDINATE endCoord End coordinate.
-- @field #func ValidNeighbourFunc Function to check if a node is valid.
-- @field #table ValidNeighbourArg Optional arguments passed to the valid neighbour function.
-- @extends Core.Base#BASE

--- When nothing goes right... Go left!
--
-- ===
--
-- ![Banner Image](..\Presentations\WingCommander\ASTAR_Main.jpg)
--
-- # The ASTAR Concept
-- 
-- Pathfinding algorithm.
-- 
--
--
-- @field #ASTAR
ASTAR = {
  ClassName      = "ASTAR",
  Debug          =   nil,
  lid            =   nil,
  nodes          =    {},
}

--- Defence condition.
-- @type ASTAR.Node
-- @field Core.Point#COORDINATE coordinate Coordinate of the node.
-- @field #number surfacetype Surface type.

--- ASTAR infinity
-- @field #string INF
ASTAR.INF=1/0

--- ASTAR class version.
-- @field #string version
ASTAR.version="0.1.0"

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
  
  return node
end


--- Add a node to the table of grid nodes.
-- @param #ASTAR self
-- @param #ASTAR.Node Node The node to be added.
-- @return #ASTAR self
function ASTAR:AddNode(Node)

  table.insert(self.nodes, Node) 
    
  return self
end

--- Add a node to the table of grid nodes specifying its coordinate.
-- @param #ASTAR self
-- @param Core.Point#COORDINATE Coordinate The coordinate where the node is created.
-- @return #ASTAR self
function ASTAR:AddNodeFromCoordinate(Coordinate)

  local node=self:GetNodeFromCoordinate(Coordinate)
  
  self:AddNode(node)
    
  return self
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
  self:I(self.lid..text)
  MESSAGE:New(text, 10, "ASTAR"):ToAllIf(self.Debug)
  
  
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
  self:I(self.lid..text)
  MESSAGE:New(text, 10, "ASTAR"):ToAllIf(self.Debug)

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

  local offset=0.1
  
  local dx=corridor and corridor/2 or nil
  local dy=dx
  
  local cA=nodeA.coordinate:SetAltitude(0, true)
  local cB=nodeB.coordinate:SetAltitude(0, true)

  local los=cA:IsLOS(cB, offset)
  
  if los and corridor then
    local heading=cA:HeadingTo(cB)
    
    local Ap=cA:Translate(dx, heading+90)
    local Bp=cB:Translate(dx, heading+90)

    los=Ap:IsLOS(Bp, offset)
    
    if los then

      local Am=cA:Translate(dy, heading-90)
      local Bm=cB:Translate(dy, heading-90)
    
      los=Am:IsLOS(Bm, offset)
    end
    
  end

  return los
end

--- Function to check if two nodes have line of sight (LoS).
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

  local closedset = {}
  local openset = { start }
  local came_from = {}

  local g_score, f_score = {}, {}
  
  g_score[start]=0
  f_score[start]=g_score[start]+self:HeuristicCost(start, goal)
  
  -- Set start time.
  local T0=timer.getAbsTime()

  -- Debug message.
  local text=string.format("Starting A* pathfinding")
  self:I(self.lid..text)
  MESSAGE:New(text, 10, "ASTAR"):ToAllIf(self.Debug)

  while #openset > 0 do
  
    local current=self:LowestFscore(openset, f_score)
    
    -- Check if we are at the end node.
    if current==goal then
    
      local path=self:UnwindPath({}, came_from, goal)
      
      if not ExcludeEndNode then
        table.insert(path, goal)
      end
      
      if ExcludeStartNode then
        table.remove(path, 1)
      end
      
      -- Debug message.
      local text=string.format("Found path with %d nodes", #path)
      self:I(self.lid..text)
      MESSAGE:New(text, 60, "ASTAR"):ToAllIf(self.Debug)
      
      return path
    end

    self:RemoveNode(openset, current)
    table.insert(closedset, current)
    
    local neighbors=self:NeighbourNodes(current, nodes)
    
    -- Loop over neighbours.
    for _,neighbor in ipairs(neighbors) do
    
      if self:NotIn(closedset, neighbor) then
      
        local tentative_g_score=g_score[current]+self:DistNodes(current, neighbor)
         
        if self:NotIn(openset, neighbor) or tentative_g_score < g_score[neighbor] then
        
          came_from[neighbor]=current
          
          g_score[neighbor]=tentative_g_score
          f_score[neighbor]=g_score[neighbor]+self:HeuristicCost(neighbor, goal)
          
          if self:NotIn(openset, neighbor) then
            table.insert(openset, neighbor)
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

--- Calculate 2D distance between two nodes.
-- @param #ASTAR self
-- @param #ASTAR.Node nodeA Node A.
-- @param #ASTAR.Node nodeB Node B.
-- @return #number Distance between nodes in meters.
function ASTAR:DistNodes(nodeA, nodeB)
  return nodeA.coordinate:Get2DDistance(nodeB.coordinate)
end

--- Heuristic cost function to go from node A to node B. That is simply the distance here.
-- @param #ASTAR self
-- @param #ASTAR.Node nodeA Node A.
-- @param #ASTAR.Node nodeB Node B.
-- @return #number Distance between nodes in meters.
function ASTAR:HeuristicCost(nodeA, nodeB)
  return self:DistNodes(nodeA, nodeB)
end

--- Check if going from a node to a neighbour is possible.
-- @param #ASTAR self
-- @param #ASTAR.Node node A node.
-- @param #ASTAR.Node neighbor Neighbour node.
-- @return #boolean If true, transition between nodes is possible.
function ASTAR:IsValidNeighbour(node, neighbor)

  if self.ValidNeighbourFunc then
  
    return self.ValidNeighbourFunc(node, neighbor, unpack(self.ValidNeighbourArg))
  
  else
    return true
  end

end

--- Function
-- @param #ASTAR self
function ASTAR:LowestFscore(set, f_score)

  local lowest, bestNode = ASTAR.INF, nil
  
  for _, node in ipairs ( set ) do
  
    local score = f_score [ node ]
    
    if score < lowest then
      lowest, bestNode = score, node
    end
  end
  
  return bestNode
end

--- Function to get valid neighbours of a node.
-- @param #ASTAR self
-- @param #ASTAR.Node theNode The node.
-- @param #table nodes Possible neighbours.
-- @param #table Valid neighbour nodes.
function ASTAR:NeighbourNodes(theNode, nodes)

  local neighbors = {}
  for _, node in ipairs ( nodes ) do
  
    if theNode~=node then
    
      local isvalid=self:IsValidNeighbour(theNode, node)
    
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
function ASTAR:NotIn(set, theNode)

  for _, node in ipairs ( set ) do
    if node == theNode then
      return false
    end
  end
  
  return true
end

--- Function to remove a node from a set.
-- @param #ASTAR self
-- @param #table set Set of nodes.
-- @param #ASTAR.Node theNode The node to check.
function ASTAR:RemoveNode(set, theNode)

  for i, node in ipairs ( set ) do
    if node == theNode then 
      set [ i ] = set [ #set ]
      set [ #set ] = nil
      break
    end
  end
  
end

--- Unwind path function.
-- @param #ASTAR self
-- @param #table flat_path Flat path.
-- @param #table map Map.
-- @param #ASTAR.Node current_node The current node.
-- @return #table Unwinded path.
function ASTAR:UnwindPath( flat_path, map, current_node )

  if map [ current_node ] then
    table.insert ( flat_path, 1, map [ current_node ] ) 
    return self:UnwindPath ( flat_path, map, map [ current_node ] )
  else
    return flat_path
  end
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------