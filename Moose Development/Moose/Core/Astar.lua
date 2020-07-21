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
-- @field #func CheckNodeValid Function to check if a node is valid.
-- @extends Core.Base#BASE

--- Be surprised!
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
  CheckNodeValid =   nil,
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
ASTAR.version="0.0.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: A lot.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new ASTAR object and start the FSM.
-- @param #ASTAR self
-- @return #ASTAR self
function ASTAR:New()

  -- Inherit everything from INTEL class.
  local self=BASE:Inherit(self, BASE:New()) --#ASTAR


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

--- Set coordinate from where to go.
-- @param #ASTAR self
-- @param Core.Point#COORDINATE Coordinate end coordinate.
-- @return #ASTAR self
function ASTAR:SetEndCoordinate(Coordinate)

  self.endCoord=Coordinate
  
  return self
end

--- Add a node.
-- @param #ASTAR self
-- @param Core.Point#COORDINATE Coordinate The coordinate.
-- @return #ASTAR.Node The node.
function ASTAR:GetNodeFromCoordinate(Coordinate)

  local node={} --#ASTAR.Node
  
  node.coordinate=Coordinate
  node.surfacetype=Coordinate:GetSurfaceType()
  
  return node
end


--- Add a node.
-- @param #ASTAR self
-- @param #ASTAR.Node Node The node to be added to the nodes table.
-- @return #ASTAR self
function ASTAR:AddNode(Node)

  table.insert(self.nodes, Node) 
    
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Find the closest node from a given coordinate.
-- @param #ASTAR.Node nodeA 
-- @param #ASTAR.Node nodeB
function ASTAR.LoS(nodeA, nodeB)

  local los=nodeA.coordinate:IsLOS(nodeB.coordinate, 0.5)
  
  if los then
    local heading=nodeA.coordinate:HeadingTo(nodeB.coordinate)
    
    local Ap=nodeA.coordinate:Translate(100, heading+90)
    local Bp=nodeA.coordinate:Translate(100, heading+90)

    los=Ap:IsLOS(Bp, 0.5)
    
    if los then

      local Am=nodeA.coordinate:Translate(100, heading-90)
      local Bm=nodeA.coordinate:Translate(100, heading-90)
    
      los=Am:IsLOS(Bm, 0.5)
    end
    
  end

  return los
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Find the closest node from a given coordinate.
-- @param #ASTAR self
-- @param Core.Point#COORDINATE Coordinate.
-- @return #ASTAR.Node Cloest node to the coordinate.
function ASTAR:CreateGrid()

  local Dx=20000
  local Dz=10000
  local delta=2000
  
  local angle=self.startCoord:HeadingTo(self.endCoord)
  local dist=self.startCoord:Get2DDistance(self.endCoord)+2*Dz
  
  local co=COORDINATE:New(0, 0, 0)
 
  local do1=co:Get2DDistance(self.startCoord)
  local ho1=co:HeadingTo(self.startCoord)
  
  local xmin=-Dx
  local zmin=-Dz
  
  local nz=dist/delta+1
  local nx=2*Dx/delta+1
  
  env.info(string.format("FF building grid with nx=%d ny=%d total=%d nodes. Angle=%d, dist=%d meters", nx, nz, nx*nz, angle, dist))
  for i=1,nx do
  
    local x=xmin+delta*(i-1)
  
    for j=1,nz do
    
      local z=zmin+delta*(j-1)
      
      local vec3=UTILS.Rotate2D({x=x, y=0, z=z}, angle)
      
      local c=COORDINATE:New(vec3.z, vec3.y, vec3.x):Translate(do1, ho1, true)
      
      if c:IsSurfaceTypeWater() then
      
        --c:MarkToAll(string.format("i=%d, j=%d", i, j))
        
        local node=self:GetNodeFromCoordinate(c)
        self:AddNode(node)
        
      end      
    
    end
  end
  env.info("FF Done building grid!")

end

--- Find the closest node from a given coordinate.
-- @param #ASTAR self
-- @param Core.Point#COORDINATE Coordinate.
-- @return #ASTAR.Node Cloest node to the coordinate.
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
    
  return closeNode
end

--- Add a node.
-- @param #ASTAR self
-- @param #ASTAR.Node Node The node to be added to the nodes table.
-- @return #ASTAR self
function ASTAR:FindStartNode()

  self.startNode=self:FindClosestNode(self.startCoord)
    
  return self
end

--- Add a node.
-- @param #ASTAR self
-- @param #ASTAR.Node Node The node to be added to the nodes table.
-- @return #ASTAR self
function ASTAR:FindEndNode()

  self.endNode=self:FindClosestNode(self.endCoord)
    
  return self
end


--- Function
-- @param #ASTAR self
-- @param #ASTAR.Node nodeA Node A.
-- @param #ASTAR.Node nodeB Node B.
-- @return #number Distance between nodes in meters.
function ASTAR:DistNodes ( nodeA, nodeB )
  return nodeA.coordinate:Get2DDistance(nodeB.coordinate)
end

--- Function
-- @param #ASTAR self
-- @param #ASTAR.Node nodeA Node A.
-- @param #ASTAR.Node nodeB Node B.
-- @return #number Distance between nodes in meters.
function ASTAR:HeuristicCost( nodeA, nodeB )
  return self:DistNodes(nodeA, nodeB)
end

--- Function
-- @param #ASTAR self
function ASTAR:is_valid_node ( node, neighbor )

  self.CheckNodeValid=ASTAR.LoS

  if self.CheckNodeValid then
    return self.CheckNodeValid(node, neighbor)
  else
    return true
  end
end

--- Function
-- @param #ASTAR self
function ASTAR:lowest_f_score(set, f_score)

  local lowest, bestNode = ASTAR.INF, nil
  
  for _, node in ipairs ( set ) do
  
    local score = f_score [ node ]
    
    if score < lowest then
      lowest, bestNode = score, node
    end
  end
  
  return bestNode
end

--- Function
-- @param #ASTAR self
function ASTAR:neighbor_nodes(theNode, nodes)

  local neighbors = {}
  for _, node in ipairs ( nodes ) do
  
  
    if theNode ~= node and self:is_valid_node ( theNode, node ) then
      table.insert ( neighbors, node )
    end
    
  end
  return neighbors
end

--- Function
-- @param #ASTAR self
function ASTAR:not_in ( set, theNode )

  for _, node in ipairs ( set ) do
    if node == theNode then
      return false
    end
  end
  
  return true
end

--- Function
-- @param #ASTAR self
function ASTAR:remove_node(set, theNode)

  for i, node in ipairs ( set ) do
    if node == theNode then 
      set [ i ] = set [ #set ]
      set [ #set ] = nil
      break
    end
  end 
end

--- Function
-- @param #ASTAR self
function ASTAR:UnwindPath( flat_path, map, current_node )

  if map [ current_node ] then
    table.insert ( flat_path, 1, map [ current_node ] ) 
    return self:UnwindPath ( flat_path, map, map [ current_node ] )
  else
    return flat_path
  end
end

----------------------------------------------------------------
-- pathfinding functions
----------------------------------------------------------------

--- Function
-- @param #ASTAR self
function ASTAR:GetPath()

  self:FindStartNode()
  self:FindEndNode()

  local nodes=self.nodes
  local start=self.startNode
  local goal=self.endNode

  local closedset = {}
  local openset = { start }
  local came_from = {}

  local g_score, f_score = {}, {}
  
  g_score [ start ] = 0
  
  f_score [ start ] = g_score [ start ] + self:HeuristicCost ( start, goal )

  while #openset > 0 do
  
    local current = self:lowest_f_score ( openset, f_score )
    
    if current == goal then
      local path = self:UnwindPath ( {}, came_from, goal )
      table.insert(path, goal)
      return path
    end

    self:remove_node( openset, current )    
    table.insert ( closedset, current )
    
    local neighbors = self:neighbor_nodes( current, nodes )
    
    for _, neighbor in ipairs ( neighbors ) do
    
      if self:not_in ( closedset, neighbor ) then
      
        local tentative_g_score = g_score [ current ] + self:DistNodes ( current, neighbor )
         
        if self:not_in ( openset, neighbor ) or tentative_g_score < g_score [ neighbor ] then
        
          came_from   [ neighbor ] = current
          g_score   [ neighbor ] = tentative_g_score
          f_score   [ neighbor ] = g_score [ neighbor ] + self:HeuristicCost ( neighbor, goal )
          
          if self:not_in ( openset, neighbor ) then
            table.insert ( openset, neighbor )
          end
          
        end
      end
    end
  end
  
  return nil -- no valid path
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------