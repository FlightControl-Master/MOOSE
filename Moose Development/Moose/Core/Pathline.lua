--- **Core** - Path from A to B.
--
-- **Main Features:**
--
--    * Path from A to B
--    * Arbitrary number of segments
--    * Automatically from lines drawtool
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
-- @extends Core.Base#BASE

--- *When nothing goes right... Go left!*
--
-- ===
--
-- # The PATHLINE Concept
-- 
-- List of points defining a path from A to B.
-- 
-- Line drawings created in the mission editor are automatically registered as pathlines and stored in the MOOSE database.
-- They can be accessed with the @{#PATHLINE.FindByName) function.
-- 
--
-- @field #PATHLINE
PATHLINE = {
  ClassName      = "PATHLINE",
  lid            =   nil,
  points         =    {},
}

--- Point of line.
-- @type PATHLINE.Point
-- @field DCS#Vec3 vec3 3D position.
-- @field DCS#Vec2 vec2 2D position.
-- @field #number surfaceType Surface type.
-- @field #number landHeight Land height in meters.
-- @field #number depth Water depth in meters.
-- @field #number markerID Marker ID.


--- PATHLINE class version.
-- @field #string version
PATHLINE.version="0.0.1"

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
-- @return #PATHLINE self
function PATHLINE:AddPointFromVec2(Vec2)

  if Vec2 then
  
    local point=self:_CreatePoint(Vec2)

    table.insert(self.points, point)
    
  end
  
  return self
end

--- Add a point to the path from a given 3D position.
-- @param #PATHLINE self
-- @param DCS#Vec3 Vec3 The 3D vector (x,y) to add.
-- @return #PATHLINE self
function PATHLINE:AddPointFromVec3(Vec3)

  if Vec3 then
  
    local point=self:_CreatePoint(Vec3)

    table.insert(self.points, point)
    
  end
  
  return self
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
-- @return <#PATHLINE.Point> List of points.
function PATHLINE:GetPoints()  
  return self.points
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
  end

  return vecs
end

--- Get the n-th point.
-- @param #PATHLINE self
-- @param #number n The n-th point.
-- @return #number Number of points.
function PATHLINE:GetPoint3D(n)

  local N=self:GetNumberOfPoints()

  local vec3=nil
  if n and n>=1 and n<=N then

    vec3=self.point[n]
  else
    self:E(self.lid..string.format("ERROR: No point in pathline for N=%s", tostring(n)))
  end
  
  return vec3
end




--- Mark points on F10 map.
-- @param #PATHLINE self
-- @param #boolean Switch If `true` or nil, set marks. If `false`, remove marks.
-- @return <DCS#Vec3> List of DCS#Vec3 points.
function PATHLINE:MarkPoints(Switch)
  for i,_point in pairs(self.points) do
    local point=_point --#PATHLINE.Point
    if Switch==false then
      
      if point.markerID then
        UTILS.RemoveMark(point.markerID, Delay)
      end
      
    else
    
      if point.markerID then
        UTILS.RemoveMark(point.markerID)
      end
    
      point.markerID=UTILS.GetMarkID()
      
      local text=string.format("Pathline %s: Point #%d\nSurface Type=%d\nHeight=%.1f m\nDepth=%.1f m", self.name, i, point.surfaceType, point.landHeight, point.depth)
      
      trigger.action.markToAll(point.markerID, text, point.vec3, "")
    
    end
  end
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get 3D points of pathline.
-- @param #PATHLINE self
-- @param DCS#Vec3 Vec Position vector. Can also be a DCS#Vec2 in which case the altitude at landheight is taken.
-- @return #PATHLINE.Point
function PATHLINE:_CreatePoint(Vec)

  local point={} --#PATHLINE.Point

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


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------