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

--- Add a 2D point to the path. The third dimension is determined from the land height.
-- @param #PATHLINE self
-- @param DCS#Vec2 Vec2 The 2D vector (x,y) to add.
-- @return #PATHLINE self
function PATHLINE:AddPointFromVec2(Vec2)

  if Vec2 then

    local Vec3={x=Vec2.x, y=land.getHeight(Vec2), z=Vec2.y}
  
    self:AddPointFromVec3(Vec3)
    
  end
  
  return self
end

--- Add a 3D point to the path.
-- @param #PATHLINE self
-- @param DCS#Vec3 Vec3 The §D vector (x,y) to add.
-- @return #PATHLINE self
function PATHLINE:AddPointFromVec3(Vec3)

  if Vec3 then

    table.insert(self.points, Vec3)
    
  end
  
  return self
end

--- Get 3D points of pathline.
-- @param #PATHLINE self
-- @return <DCS#Vec3> List of DCS#Vec3 points.
function PATHLINE:GetPoints3D()  
  return self.points
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------