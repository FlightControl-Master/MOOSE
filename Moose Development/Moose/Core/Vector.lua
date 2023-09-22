--- **CORE** - Vector algebra.
--
-- **Main Features:**
--
--    * Easy vector algebra function
--    * Redefinition of +,-,* operators
-- 
-- ===
--
-- ## Example Missions:
--
-- Demo missions can be found on [github](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/develop/Core%20-%20Vector).
-- 
-- ===
--
-- ### Author: **funkyfranky**
-- 
-- ===
-- @module Core.Vector
-- @image CORE_Vector.png


--- VECTOR class.
-- @type VECTOR
-- @field #string ClassName Name of the class.
-- @field #number verbose Verbosity of output.
-- @field #number x Component.
-- @field #number y Component.
-- @field #number z Component.

--- *A fleet of British ships at war are the best negotiators.* -- Horatio Nelson
--
-- ===
--
-- # The VECTOR Concept
--
-- The VECTOR class has a great concept!
-- 
-- # The DCS Coordinate System
-- 
-- DCS has a rather unconventional way to define the coordinate system. The definition even depends whether you work with a 2D vector or a 3D vector.
-- The good think is, that you usually do not need to worry about this unless you directly call the DCS API functions. Plus, this class tries to
-- hide the differences between 2D and 3D conventions as good as possible with internal if-cases.
-- 
-- Still, it is important to unterstand the differences. So let us explain:
-- 
-- Usually, we draw a coordinate system in 2D and label the horizonal axis (pointing right) as the x-axis. The vertical axis (poining up on a piece of paper)
-- 
-- ## 3D
-- 
-- The x-axis points North. The z-axis points East. The y-axis points upwards and defines the altitue with respect to the mean sea level.
-- 
-- ## 2D
-- 
-- The x-axis points North (just like in the 3D) case. The y-axis points East.
-- 
-- # Operators
-- 
-- ## Addition [MATH] `+`
-- 
-- ## Subtraction [MATH] `-`
-- 
-- ## Multiplication [MATH] `*`
-- 
-- ## Devision [MATH] `/`
-- 
-- 
-- # Examples
-- 
-- A new `VECTOR` object can be created with the @{#VECTOR.New} function.
-- Here we create two vectors, a and b, and add them to create a new vector c. 
-- 
--     local a=VECTOR:New(1, 0)
--     local b=VECTOR:New(0, 1)
--     local c=a+b
--     
-- This is how it works.
--
-- @field #VECTOR
VECTOR = {
  ClassName       = "VECTOR",
  verbose         =        0,
}

--- VECTOR class version.
-- @field #string version
VECTOR.version="0.0.1"

--- VECTOR private index.
-- @field #VECTOR __index
VECTOR.__index = VECTOR

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ToDo list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: A lot...

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new VECTOR class instance from given cartesian coordinates `x`, `y`, `z` (`z` is optional).
-- If only `x` and `y` are given (`z`=nil), then a 2D vector is constructed.
-- If `z` is passed, then a 3D vector is constucted.
-- @param #VECTOR self
-- @param #number x Component of vector along x-axis (pointing North).
-- @param #number y Component of vector along y-axis (pointing East in 2D and Up in 3D).
-- @param #number z (Optional) Component of the z-axis (pointing East in 3D).
-- @return #VECTOR self
function VECTOR:New(x, y, z)

  self=setmetatable({x=x or 0, y=y or 0, z=z}, VECTOR)
   
  return self
end

--- Create a new VECTOR class instance from polar coordinates (r, phi).
-- @param #VECTOR self
-- @param #number r Distance.
-- @param #number phi Angle
-- @return #VECTOR self
function VECTOR:NewFromPolar(r, phi)

  --TODO: convert.
  local x=1
  local y=1
  
  local v=VECTOR:New(x, y)
   
  return self
end

--- Create a new VECTOR class instance from spherical coordinates (r, theta, phi).
-- @param #VECTOR self
-- @param #number r Distance
-- @param #number theta Angle
-- @param #number phi Angle
-- @return #VECTOR self
function VECTOR:NewFromSpherical(r, theta, phi)

  --TODO: convert.
  local x=1
  local y=1
  local z=1
  
  local v=VECTOR:New(x, y, z)
   
  return self
end

--- Get the directional vector that points from a given vector `a` to another given vector `b`.
-- The vector is `c=-a+b=b-a`.
-- @param #VECTOR self
-- @param #VECTOR a Vector a. This can also be given as any table with x,y and z components (z optional).
-- @param #VECTOR b Vector b. This can also be given as any table with x,y and z components (z optional).
-- @return #VECTOR Directional vector from a to b.
function VECTOR:NewDirectionalVector(a, b)
  
  local x=b.x-a.x
  local y=b.y-a.y
  
  local c=VECTOR:New(x, y)  
   
  return c
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get 2D vector as simple table.
-- @param #VECTOR self
-- @return DCS#Vec2 2D array {x=x, y=y}
function VECTOR:GetVec2()

  local vec2=nil
  
  if self.z then
    vec2={x=self.x, y=self.z}
  else
    vec2={x=self.x, y=self.y}
  end
  
  return vec2
end

--- Get 3D vector as simple table.
-- If the original vector was 2D, we return the land height at the 2D position.
-- @param #VECTOR self
-- @return DCS#Vec3 2D array {x=x, y=y, z=z}
function VECTOR:GetVec3()

  local vec=nil --DCS#Vec3
  
  if self.z then
    vec={x=self.x, y=self.z}
  else
    -- Originally, we had a 2D vector, so we get the land height for y.
    vec={x=self.x, y=land.getHeight({x=self.x, y=self.y}), z=self.y}
  end
  
  return vec
end

--- Get the directional vector that points from this VECTOR to another VECTOR `a`.
-- @param #VECTOR self
-- @param #VECTOR a Vector a. This can also be given as any table with x,y and z components (z optional).
-- @return #VECTOR Directional vector from self to a.
function VECTOR:GetDirectionalVectorTo(a)
  
  local x=a.x-self.x
  local y=a.y-self.y
  
  local c=VECTOR:New(x, y)  
   
  return c
end

--- Get the directional vector that points from another VECTOR `a` to this VECTOR.
-- @param #VECTOR self
-- @param #VECTOR a Vector a. This can also be given as any table with x,y and z components (z optional).
-- @return #VECTOR Directional vector from self to a.
function VECTOR:GetDirectionalVectorFrom(a)
  
  local x=self.x-a.x
  local y=self.y-a.y
  
  local c=VECTOR:New(x, y)  
   
  return c
end


--- Get heading of vector.
-- Note that a heading of
--  
-- * 000° = North
-- * 090° = East
-- * 180° = South
-- * 270° = West.
-- 
-- @param #VECTOR self
-- @param #boolean To360 If `true` or `nil`, adjust heading to [0,360) range. If `false`, headings not in this range can occur.
-- @return #number Heading in degrees.
function VECTOR:GetHeading(To360)

  local heading=0
  
  if self.z then
    heading=math.atan2(self.z, self.x)
  else
    heading=math.atan2(self.y, self.x)
  end
  
  -- Convert to degrees.
  heading=math.deg(heading)
  
  if heading==360.0 then
    heading=0.0
  end
  
  if To360==nil or To360==true then
    if heading>=360 then  
      heading=heading-360  
    elseif heading<360 then  
      heading=heading+360  
    end
  end

  return heading
end

--- Get the heading from this vector to another given vector.
-- @param #VECTOR self
-- @param #VECTOR Vector Vector to which the heading is requested.
-- @return #number Heading from this vector to the other vector in degrees.
function VECTOR:GetHeadingTo(Vector)

  local x=Vector.x-self.x
  
  local y=0
  if Vector.z and self.z then
    y=Vector.z-self.z
  elseif Vector.z then
    y=Vector.z-self.y
  elseif self.z then
    y=Vector.y-self.z    
  else
    y=Vector.y-self.y
  end
  
  local heading=math.deg(math.atan2(y, x))
  
  if heading<0 then
    heading=heading+360
  elseif heading>=360 then
    heading=heading-360  
  end
  
  return heading
end

--- Get the heading from a given vector to this vector.
-- @param #VECTOR self
-- @param #VECTOR Vector Vector from which the heading is requested.
-- @return #number Heading from the other vector to this vector in degrees.
function VECTOR:GetHeadingFrom(Vector)

  local x=self.x-Vector.x
  
  local y=0
  if Vector.z and self.z then
    y=self.z-Vector.z
  elseif Vector.z then
    y=self.y-Vector.z
  elseif self.z then
    y=self.z-Vector.y-self.z    
  else
    y=self.y-Vector.y
  end
  
  local heading=math.deg(math.atan2(y, x))
  
  if heading<0 then
    heading=heading+360
  elseif heading>=360 then
    heading=heading-360  
  end
  
  return heading
end

--- Get the difference of the heading of this vector w.
-- 
-- **Example 1:**
-- This vector has a heading of 90° (pointing East) and the other vector has a heading of 225° (pointing South-West),
-- we would optain a delta of 225°-90°=135°.
-- 
-- **Example 2:**
-- This vector has a heading of 180 (pointing South) and the other vector has a heading of 90° (pointing East),
-- we would optain a delta of 90°-180°=-90°.
-- 
-- @param #VECTOR self
-- @param #VECTOR Vector Vector to which the heading is requested.
-- @return #number Heading from this vector to the other vector in degrees.
function VECTOR:GetHeadingDelta(Vector)

  local h1=self:GetHeading(false)
  
  local h2=Vector:GetHeading(false)

  local delta=h2-h1
  
  return delta
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Check if passed object is a Vector.
-- @param #table t The object to be tested. 
-- @return #boolean Returns `true` if `t` is a #VECTOR and `false` otherwise.
function VECTOR._IsVector(t)
  return getmetatable(t) == VECTOR
end

--- Meta function to add vectors together.
-- ex: (vector(5,6) + vector(6,5)) is the same as vector(11,11)
-- @param #VECTOR a Vector a.
-- @param #VECTOR b Vector b.
-- @return #VECTOR Returns a new VECTOR c with c[i]=a[i]+b[i] for i=x,y,z.
function VECTOR.__add(a,b)
  assert(VECTOR._IsVector(a) and VECTOR._IsVector(b), "ERROR in VECTOR.__add: wrong argument types! (expected <vector> and <vector>)")
  local c=VECTOR:New(a.x+b.x, a.y+b.y)
  return c
end

--- Meta function to substract vectors.
-- @param #VECTOR a Vector a.
-- @param #VECTOR b Vector b.
-- @return #VECTOR Returns a new VECTOR c with c[i]=a[i]-b[i] for i=x,y,z.
function VECTOR.__sub(a,b)
  assert(VECTOR._IsVector(a) and VECTOR._IsVector(b), "sub: wrong argument types: (expected <vector> and <vector>)")
  local c=nil
  if a.z and b.z then
    c=VECTOR:New(a.x-b.x, a.y-b.y)
  else
    c=VECTOR:New(a.x-b.x, a.y-b.y)
  end 
  return c
end


--- Meta function to multiplicate vectors.
-- @param #VECTOR a Vector a. Can also be a #number.
-- @param #VECTOR b Vector b. Can also be a #number.
-- @return #VECTOR Returns a new VECTOR c with c[i]=a[i]*b[i] for i=x,y,z.
function VECTOR.__mul(a, b)

  local c=nil --#VECTOR
  
  if type(a)=='number' then
    if b.z then
      c=VECTOR:New(a*b.x, a*b.y, a*b.z)
    else
      c=VECTOR:New(a*b.x, a*b.y)
    end
  elseif type(b)=='number' then
    if a.z then
      c=VECTOR:New(b*a.x, b*a.y, b*a.z)
    else    
      c=VECTOR:New(b*a.x, b*a.y)
    end
  else
    if a.z and b.z then
      c=VECTOR:New(a.x*b.x, a.y*b.y, a.z*b.z)
    elseif a.z then
      c=VECTOR:New(a.x*b.x, a.y*b.y, a.z)
    elseif b.z then
      c=VECTOR:New(a.x*b.x, a.y*b.y, b.z)
    else    
      c=VECTOR:New(a.x*b.x, a.y*b.y)
    end
  end
   
  return c
end

--- Meta function to change how vectors appear as string.
-- @param #VECTOR self
-- @return #string String representation of vector.
function VECTOR:__tostring()
  local text=""
  if self.z then
    text=string.format("(x=%.3f, y=%.3f, z=%.3f) Heading=%3.3f°", self.x, self.y, self.z, self:GetHeading(false))
  else
    text=string.format("(x=%.3f, y=%.3f) Heading=%3.3f°", self.x, self.y, self:GetHeading(false))
  end
  return text
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
