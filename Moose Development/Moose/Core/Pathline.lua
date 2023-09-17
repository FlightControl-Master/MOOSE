--- **Core** - Path from A to B.
--
-- **Main Features:**
--
--    * Path from A to B
--    * Arbitrary number of points
--    * Automatically from lines drawtool
--    * Draw line or mark points on F10 map
--    * Find closest points to path
--
-- ===
--
-- ### Author: **funkyfranky**
-- 
-- ===
-- @module Core.Pathline
-- @image CORE_Pathline.png


--- PATHLINE class.
-- @type PATHLINE
-- @field #string ClassName Name of the class.
-- @field #string lid Class id string for output to DCS log file.
-- @field #string name Name of the path line.
-- @field #table points List of 3D points defining the path.
-- @field #number counter Running number counting the point IDs.
-- @extends Core.Base#BASE

--- *The shortest distance between two points is a straight line.* -- Archimedes
--
-- ===
--
-- # The PATHLINE Concept
-- 
-- List of points defining a path from A to B. The pathline can consist of multiple points. Each point holds the information of its position, the surface type, the land height
-- and the water depth (if over sea).
-- 
-- Line drawings created in the mission editor are automatically registered as pathlines and stored in the MOOSE database.
-- They can be accessed with the @{#PATHLINE.FindByName) function.
-- 
-- # Constructor
-- 
-- The @{PATHLINE.New) function creates a new PATHLINE object. This does not hold any points. Points can be added with the @{#PATHLINE.AddPointFromVec2} and @{#PATHLINE.AddPointFromVec3}
-- 
-- For a given table of 2D or 3D positions, a new PATHLINE object can be created with the @{#PATHLINE.NewFromVec2Array} or @{#PATHLINE.NewFromVec3Array}, respectively.
-- 
-- # Line Drawings
-- 
-- The most convenient way to create a pathline is the draw panel feature in the DCS mission editor. You can select "Line" and then "Segments", "Segment" or "Free" to draw your lines.
-- These line drawings are then automatically added to the MOOSE database as PATHLINE objects and can be retrieved with the @{#PATHLINE.FindByName) function, where the name is the one
-- you specify in the draw panel.
-- 
-- # Mark on F10 map
-- 
-- The ponints of the PATHLINE can be marked on the F10 map with the @{#PATHLINE.MarkPoints}(`true`) function. The mark points contain information of the surface type, land height and 
-- water depth.
-- 
-- To remove the marks, use @{#PATHLINE.MarkPoints}(`false`).
--
-- @field #PATHLINE
PATHLINE = {
  ClassName      = "PATHLINE",
  lid            =   nil,
  points         =    {},
  counter        =     0,
}

--- Point of line.
-- @type PATHLINE.Point
-- @field #number uid Unique ID of this point.
-- @field #string mother Name of the pathline this point belongs to.
-- @field #string name Name of this point.
-- @field DCS#Vec3 vec3 3D position.
-- @field DCS#Vec2 vec2 2D position.
-- @field #number surfaceType Surface type.
-- @field #number landHeight Land height in meters.
-- @field #number depth Water depth in meters.
-- @field #number markerID Marker ID.
-- @field #number lineID Marker of pathline ID.

--- Segment of line.
-- @type PATHLINE.Segment
-- @field #PATHLINE.Point p1 First point.
-- @field #PATHLINE.Point p2 Second point.


--- PATHLINE class version.
-- @field #string version
PATHLINE.version="0.3.0"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: A lot...

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new PATHLINE object. Points need to be added later.
-- @param #PATHLINE self
-- @param #string Name Name of the path.
-- @return #PATHLINE self
function PATHLINE:New(Name)

  -- Inherit everything from INTEL class.
  local self=BASE:Inherit(self, BASE:New()) --#PATHLINE
  
  self.name=Name or "Unknown Path"

  self.lid=string.format("PATHLINE %s | ", Name)

  return self
end

--- Create a new PATHLINE object from a given list of 2D points.
-- @param #PATHLINE self
-- @param #string Name Name of the pathline.
-- @param #table Vec2Array List of DCS#Vec2 points.
-- @return #PATHLINE self
function PATHLINE:NewFromVec2Array(Name, Vec2Array)

  local self=PATHLINE:New(Name)

  for i=1,#Vec2Array do
    self:AddPointFromVec2(Vec2Array[i])
  end

  return self
end

--- Create a new PATHLINE object from a given list of 3D points.
-- @param #PATHLINE self
-- @param #string Name Name of the pathline.
-- @param #table Vec3Array List of DCS#Vec3 points.
-- @return #PATHLINE self
function PATHLINE:NewFromVec3Array(Name, Vec3Array)

  local self=PATHLINE:New(Name)

  for i=1,#Vec3Array do
    self:AddPointFromVec3(Vec3Array[i])
  end

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Find a pathline in the database.
-- @param #PATHLINE self
-- @param #string Name The name of the pathline.
-- @return #PATHLINE self
function PATHLINE:FindByName(Name)
  local pathline = _DATABASE:FindPathline(Name)
  return pathline
end



--- Add a point to the path from a given 2D position. The third dimension is determined from the land height.
-- @param #PATHLINE self
-- @param DCS#Vec2 Vec2 The 2D vector (x,y) to add.
-- @param #number Index Index to add this point, *e.g.* 1 for first point or 2 for second point. Default is at the end.
-- @param #PATHLINE.Point Point Add point after given point. Default is at the end or at given index.
-- @return #PATHLINE self
function PATHLINE:AddPointFromVec2(Vec2, Index, Point)

  if Vec2 then
  
    -- Create a new point.
    local point=self:_CreatePoint(Vec2)

    if Index then
      -- Add at given index.
      table.insert(self.points, Index, point)
    else
      if Point then
        -- Get index of given point.
        local i=self:_GetPointIndex(Point)
        -- Add new point after given point.
        table.insert(self.points, i+1, point)
      else
        -- Add add the end.
        table.insert(self.points, point)
      end
    end 
  end
  
  return self
end

--- Add a point to the path from a given 3D position.
-- @param #PATHLINE self
-- @param DCS#Vec3 Vec3 The 3D vector (x,y) to add.
-- @param #number Index Index to add this point, *e.g.* 1 for first point or 2 for second point. Default is at the end.
-- @param #PATHLINE.Point Point Add point after given point. Default is at the end or at given index.
-- @return #PATHLINE.Point Point that was added.
function PATHLINE:AddPointFromVec3(Vec3, Index, Point)

  if Vec3 then
  
    local point=self:_CreatePoint(Vec3)

    if Index then
      -- Add add given index.
      table.insert(self.points, Index, point)
    else
      if Point then
        local i=self:_GetPointIndex(Point)
        table.insert(self.points, i+1, point)
      else
        -- Add add the end.
        table.insert(self.points, point)
      end
    end
  
    return point  
  end
  
  return nil
end

--- Get name of pathline.
-- @param #PATHLINE self
-- @return #string Name of the pathline.
function PATHLINE:GetName()  
  return self.name
end

--- Get number of points.
-- @param #PATHLINE self
-- @return #number Number of points.
function PATHLINE:GetNumberOfPoints()
  local N=#self.points
  return N
end

--- Get points of pathline. Not that points are tables, that contain more information as just the 2D or 3D position but also the surface type etc.
-- @param #PATHLINE self
-- @return <Core.Pathline#PATHLINE.Point> List of points.
function PATHLINE:GetPoints()  
  return self.points
end

--- Get segments of pathline.
-- @param #PATHLINE self
-- @return <Core.Pathline#PATHLINE.Segment> List of points.
function PATHLINE:GetSetments()

  local segments={}

  for i=1,#self.points-1 do
    local segment={} --#PATHLINE.Segment
    segment.p1=self.points[i]
    segment.p2=self.points[i+1]
    table.insert(segments, segment)
  end
  
  return segments
end

--- Get 3D points of pathline.
-- @param #PATHLINE self
-- @return <DCS#Vec3> List of DCS#Vec3 points.
function PATHLINE:GetPoints3D()

  local vecs={}
  
  for _,_point in pairs(self.points) do
    local point=_point --#PATHLINE.Point
    table.insert(vecs, point.vec3)
  end

  return vecs
end

--- Get 2D points of pathline.
-- @param #PATHLINE self
-- @return <DCS#Vec2> List of DCS#Vec2 points.
function PATHLINE:GetPoints2D()

  local vecs={}
  
  for _,_point in pairs(self.points) do
    local point=_point --#PATHLINE.Point
    table.insert(vecs, point.vec2)
  end

  return vecs
end

--- Get COORDINATES of pathline. Note that COORDINATE objects are created when calling this function. That does involve deep copy calls and can have an impact on performance if done too often.
-- @param #PATHLINE self
-- @return <Core.Point#COORDINATE> List of COORDINATES points.
function PATHLINE:GetCoordinats()

  local vecs={}
  
  for _,_point in pairs(self.points) do
    local point=_point --#PATHLINE.Point
    local coord=COORDINATE:NewFromVec3(point.vec3)
    table.insert(vecs, coord)
  end

  return vecs
end

--- Get the n-th point of the pathline.
-- @param #PATHLINE self
-- @param #number n The index of the point. Default is the first point.
-- @return #PATHLINE.Point Point.
function PATHLINE:GetPointFromIndex(n)

  local N=self:GetNumberOfPoints()
  
  n=n or 1

  local point=nil --#PATHLINE.Point
  
  if n>=1 and n<=N then
    point=self.point[n]
  else
    self:E(self.lid..string.format("ERROR: No point in pathline for N=%s", tostring(n)))
  end

  return point
end

--- Get the 3D position of the n-th point.
-- @param #PATHLINE self
-- @param #number n The n-th point.
-- @return DCS#VEC3 Position in 3D.
function PATHLINE:GetPoint3DFromIndex(n)

  local point=self:GetPointFromIndex(n)
  
  if point then
    return point.vec3
  end
  
  return nil
end

--- Get the 2D position of the n-th point.
-- @param #PATHLINE self
-- @param #number n The n-th point.
-- @return DCS#VEC2 Position in 3D.
function PATHLINE:GetPoint2DFromIndex(n)

  local point=self:GetPointFromIndex(n)
  
  if point then
    return point.vec2
  end
  
  return nil
end


--- Mark points on F10 map.
-- @param #PATHLINE self
-- @param #boolean Switch If `true` or nil, set marks. If `false`, remove marks.
-- @return #PATHLINE self
function PATHLINE:MarkPoints(Switch)

  for i,_point in pairs(self.points) do
    local point=_point --#PATHLINE.Point
    
    if Switch==false then
      
      if point.markerID then
        UTILS.RemoveMark(point.markerID)
      end
      
    else
    
      if point.markerID then
        UTILS.RemoveMark(point.markerID)
      end
    
      point.markerID=UTILS.GetMarkID()
      
      local text=string.format("Pathline %s: Point #%d [UID=%d]\nSurface Type=%d\nHeight=%.1f m\nDepth=%.1f m", self.name, i, point.uid, point.surfaceType, point.landHeight, point.depth)
      
      trigger.action.markToAll(point.markerID, text, point.vec3, "")
    
    end
  end
  
  return self
end


--- Draw line on F10 map.
-- @param #PATHLINE self
-- @param #boolean Switch If `true` or nil, draw pathline. If `false`, remove drawing.
-- @param #number Coalition Coalition side. Default -1 for all.
-- @param #table Color RGB color and alpha `{r, g, b, a}`. Default {0, 1, 0, 0.5}.
-- @param #number LineType Line type. Default 1=solid.
-- @return #PATHLINE self
function PATHLINE:Draw(Switch, Coalition, Color, LineType)

  Coalition=Coalition or -1
  Color=Color or {0, 1, 0, 0.5}
  LineType=LineType or -1

  if Switch==false then

    for i,_point in pairs(self.points) do
      local point=_point --#PATHLINE.Point
        
      if point.lineID then
        UTILS.RemoveMark(point.lineID)
      end
      
    end
      
  else

    for i=2,#self.points do
      
      local p1=self.points[i-1] --#PATHLINE.Point
      local p2=self.points[i]   --#PATHLINE.Point
      
      if p2.lineID then
        UTILS.RemoveMark(p2.lineID)
      end
    
      p2.lineID=UTILS.GetMarkID()      
    
      trigger.action.lineToAll(Coalition, p2.lineID, p1.vec3, p2.vec3, Color, LineType)
      
    end
    
  end
  
  return self
end

--- Get the closest point on the pathline for a given reference point.
-- @param #PATHLINE self
-- @param DCS#Vec2 Vec2 Reference Point in 2D.
-- @return DCS#Vec2 Cloest point on pathline.
-- @return #number Distance from closest point to ref point in meters.
-- @return #PATHLINE.Segment Closest segment of ref point.
function PATHLINE:GetClosestPoint2D(Vec2)

  local P=nil --DCS#Vec2  
  local D=math.huge
  local S={} --#PATHLINE.Segment
  
  for i=2,#self.points do

    local A=self.points[i-1] --#PATHLINE.Point
    local B=self.points[i]   --#PATHLINE.Point
    
    local a=A.vec2
    local b=B.vec2
        
    local ab=UTILS.Vec2Substract(b, a)  
    local ap=UTILS.Vec2Substract(Vec2, a)
    
    local proj=UTILS.Vec2Dot(ap, ab)
    
    local lab=UTILS.Vec2Norm(ab)
    
    local f=proj/lab/lab
    
    -- Debug info.
    local text=string.format("FF Proj=%.1f, |ab|=%.1f, f=%.1f", proj, lab, f)
    self:T(self.lid..text)
    
    -- Cases for finite segment.
    local p=nil --DCS#Vec2
    if f<0 then
      p=a
    elseif f>1 then
      p=b
    else
      local r=UTILS.Vec2Mult(ab, f)
      p=UTILS.Vec2Add(a, r)  
    end
    
    -- Distance.
    local d=UTILS.VecDist2D(p, Vec2)
    
    if d<=D then
      D=d
      P=p
      S.p1=A
      S.p2=B
    end
    
  end
  
  return P, D, S
end

--- Get the closest point on the pathline for a given reference point.
-- This point does not necessarily is a node of the pathline. In general it will be somewhere in between the nodes defining the pathline.
-- @param #PATHLINE self
-- @param DCS#Vec3 Vec3 Reference Point in 3D. Can also be a `COORDINATE`.
-- @return DCS#Vec3 Closest point on pathline.
-- @return #number Distance from closest point to ref point in meters.
-- @return #PATHLINE.Segment Closest segment of ref point.
function PATHLINE:GetClosestPoint3D(Vec3)

  local P=nil --DCS#Vec3
  local D=math.huge
  local S={} --#PATHLINE.Segment
  
  if not Vec3 then
    self:E(self.lid.."ERROR: input Vec3 is nil!")
    return nil, nil, nil
  end
  
  for i=2,#self.points do

    local A=self.points[i-1] --#PATHLINE.Point
    local B=self.points[i]   --#PATHLINE.Point
    
    local a=A.vec3
    local b=B.vec3
        
    local ab=UTILS.VecSubstract(b, a)  
    local ap=UTILS.VecSubstract(Vec3, a)
    
    local proj=UTILS.VecDot(ap, ab)
    
    local lab=UTILS.VecNorm(ab)
    
    local f=proj/lab/lab
    
    -- Debug info.
    self:T(self.lid..string.format("Proj=%.1f, |ab|=%.1f, f=%.1f", proj, lab, f))
    
    -- Cases for finite segment.
    local p=nil --DCS#Vec2
    if f<0 then
      p=a
    elseif f>1 then
      p=b
    else
      local r=UTILS.VecMult(ab, f)
      p=UTILS.VecAdd(a, r)  
    end
    
    -- Distance.
    local d=UTILS.VecDist3D(p, Vec3)
    
    if d<=D then
      D=d
      P=p
      S.p1=A
      S.p2=B
    end
    
  end
 
  return P, D, S
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get 3D points of pathline.
-- @param #PATHLINE self
-- @param DCS#Vec3 Vec Position vector. Can also be a DCS#Vec2 in which case the altitude at landheight is taken.
-- @return #PATHLINE.Point Pathline Point.
function PATHLINE:_CreatePoint(Vec)

  local point={} --#PATHLINE.Point
  
  self.counter=self.counter+1
  
  point.uid=self.counter
  point.mother=self.name
  
  point.name=string.format("%s #%d", self.name, point.uid)

  if Vec.z then
    -- Given vec is 3D
    point.vec3=UTILS.DeepCopy(Vec)
    point.vec2={x=Vec.x, y=Vec.z}
  else
    -- Given vec is 2D  
    point.vec2=UTILS.DeepCopy(Vec)
    point.vec3={x=Vec.x, y=land.getHeight(Vec), z=Vec.y}
  end

  -- Get surface type.
  point.surfaceType=land.getSurfaceType(point.vec2)
  
  -- Get land height and depth.
  point.landHeight, point.depth=land.getSurfaceHeightWithSeabed(point.vec2)
  
  point.markerID=nil

  return point
end

--- Get index of point in the lua table.
-- @param #PATHLINE self
-- @param #PATHLINE.Point Point Given point.
-- @return #number index
function PATHLINE:_GetPointIndex(Point)

  for i,_point in pairs(self.points) do
    local point=_point --#PATHLINE.Point
   
    if point.uid==Point.uid then
      return i
    end
  
  end

  return nil
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------