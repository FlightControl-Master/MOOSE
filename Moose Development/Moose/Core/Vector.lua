--- **CORE** - Vector algebra.
--
-- **Main Features:**
--
--    * Easy vector algebra function
--    * Redefinition of `+`, `-`, `*`, `/`, `%` operators to be compatible with vectors
--    * Interface to DCS API functions
--    * Reduced confusion of DCS coordinate system
--    * Better performance than related classes (COORDINATE, POINT_VEC)
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
-- @field #number x Component pointing North if > 0 and South if < 0.
-- @field #number y Component pointing up if >0 and down if < 0. This describes the altitude above main sea level.
-- @field #number z Component pointing East if > 0 and West if < 0.

--- *Mathematics knows no races or geographic boundaries; for mathematics, the cultural world is one country.* --David Hilbert
--
-- ===
--
-- # The VECTOR Concept
--
-- The VECTOR class has a great concept!
-- 
-- https://github.com/automattf/vector.lua/blob/master/vector.lua
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
-- # Constructors
-- 
-- There are different ways to create a new instance of a VECTOR. All methods start with `New`.
-- 
-- ## From Components
-- 
-- ## From 2D or 3D Vectors
-- 
-- ## From Polar Coordinates
-- 
-- ## From Spherical Coordinates
-- 
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
-- ## Modulo [MATH] `%`
-- 
-- 
-- # DCS API Interface
-- 
-- This class offers easy and convenient ways to access all vector related DCS API functions.
-- 
-- ## Land and Surface
-- 
-- ## Atmosphere
-- 
-- ## Effects and Actions
-- 
-- ## Map Markings
-- 
-- ## Coordinates
-- 
-- # Inferface to other MOOSE Classes
-- 
-- Of course, this class is interfaced with other MOOSE classes in the sense that you can obtain and work with VECTOR instances from MOOSE objects, from which a position or direction
-- vector can be derived.
-- 
-- ## GROUP
-- 
-- ## UNIT
-- 
-- ## STATIC
-- 
-- ## SCENERY
-- 
-- ## ZONE
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
VECTOR.version="0.1.0"

--- VECTOR unique ID
_VECTORID=0

--- VECTOR private index.
-- @field #VECTOR __index
VECTOR.__index = VECTOR

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ToDo list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: 3D rotation
-- DONE: Markers
-- TODO: Documentation

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new VECTOR class instance from given cartesian coordinates `x`, `y` and `z`, where `z` is optional.
-- **Note** that whether the `z` component is passed or nil has great impact on the interpretation of the `y` component.
-- If `z` is not given (`nil`), then `y` is used as `z` (the coordinate pointing East) because we always constuct a 3D vector.
-- If `z` is given (not `nil`), then `y` is used as coordinate pointing up (out of plane) as for all 3D DCS vectors.
-- @param #VECTOR self
-- @param #number x Component of vector along x-axis (pointing North in both 2D and 3D).
-- @param #number y Component of vector along y-axis (pointing East in 2D and Up in 3D).
-- @param #number z (Optional) Component of the z-axis (pointing East in 3D).
-- @return #VECTOR self
function VECTOR:New(x, y, z)

  if z==nil then
    -- z-component is not given ==> 2D ==> we take y as z and set y=0.
    self=setmetatable({x=x or 0, y=0, z=y or 0}, VECTOR)
  else
    self=setmetatable({x=x or 0, y=y or 0, z=z or 0}, VECTOR)
  end
  
  _VECTORID=_VECTORID+1
  
  self.uid=_VECTORID

  return self
end

--- Create a new VECTOR class instance from given 2D or 3D vector object.
-- @param #VECTOR self
-- @param DCS#Vec3 Vec Vector object with `x`, `y` and optionally `z` components. Can be a DCS#Vec2, DCS#Vec3, `COORDINATE`, `VECTOR` object.
-- @return #VECTOR self
function VECTOR:NewFromVec(Vec)

  -- The :New function takes care whether this is a 2D or 3D vector.
  local vector=VECTOR:New(Vec.x, Vec.y, Vec.z)
  
  return vector
end

--- Create a new VECTOR class instance from polar coordinates (r, phi).
-- @param #VECTOR self
-- @param #number r Distance.
-- @param #number phi Angle in Degrees. Note that 0° corresponds to North, 90° East etc.
-- @return #VECTOR self
function VECTOR:NewFromPolar(r, phi)

  -- Convert deg to rad.
  local Phi=math.rad(phi)

  -- Polar coordinates. What we want in DCS is:
  -- North: Phi=0   ==> x= 1, y= 0
  -- East : Phi=90  ==> x= 0, y= 1
  -- South: Phi=180 ==> x=-1, y= 0
  -- West : Phi=270 ==> x= 0, y=-1
  
  -- sin(0)=0 sin(90)=1, sin(180)=0, sin(270)=-1 ==> y
  -- cos(0)=1 cos(90)=0, cos(180)=-1, cos(270)=0 ==> x
  
  local x=r*math.cos(phi)
  local y=r*math.sin(phi)
  
  -- Create new vector. As z is nil, the 2D character is taken care of.
  local v=VECTOR:New(x, y)
   
  return self
end

--- Create a new VECTOR class instance from spherical coordinates (r, theta, phi).
-- @param #VECTOR self
-- @param #number r Distance in meters with r>=0.
-- @param #number theta Polar angle in Degrees measured from a fixed polar axis or zenith direction. This angle is in [0°, 180°].
-- @param #number phi Azimuthal angle in Degrees. This angle is in [0°, 360°).
-- @return #VECTOR self
function VECTOR:NewFromSpherical(r, theta, phi)

  local sinPhi=math.sin(math.rad(phi))
  local cosPhi=math.cos(math.rad(phi))
  local sinTheta=math.sin(math.rad(theta))
  local cosTheta=math.cos(math.rad(theta))

  --TODO: Check x,y,z convention for DCS.
  local x=r*sinTheta*cosPhi
  local y=r*sinTheta*sinPhi
  local z=r*cosTheta
  
  local v=VECTOR:New(x, y, z)
   
  return self
end

--- Get the directional vector that points from a given vector `a` to another given vector `b`.
-- The vector is `c=-a+b=b-a`.
-- @param #VECTOR self
-- @param #VECTOR a Vector a. This can also be given as any table with x, y and z components (z optional).
-- @param #VECTOR b Vector b. This can also be given as any table with x, y and z components (z optional).
-- @return #VECTOR Directional vector from a to b.
function VECTOR:NewDirectionalVector(a, b)

  local x=b.x-a.x
  local y
  local z
    
  if a.z and b.z then
    -- Both given vectors are 3D
    y=b.y-a.y
    z=b.z-a.z
  elseif b.z then
    -- a is 2D and b is 3D
    y=b.y-0
    z=b.z-a.y
  elseif a.z then
    -- a is 3D and b is 2D
    y=0-a.y
    z=b.y-a.z
  else
    -- a is 2D and b is 2D
    y=b.y-a.y
    z=nil --We leave z=nil, so the New function takes care of the 2D character.
  end
  
  local c=VECTOR:New(x, y, z)
   
  return c
end


--- Creates a new VECTOR instance from given the latitude and longitude in decimal degrees (DD).
-- @param #VECTOR self
-- @param #number Latitude Latitude in decimal degrees.
-- @param #number Longitude Longitude in decimal degrees.
-- @param #number Altitude (Optional) Altitude in meters. Default is the land height at the 2D position.
-- @return #VECTOR self
function VECTOR:NewFromLLDD(Latitude, Longitude, Altitude)

  -- Returns a point from latitude and longitude in the vec3 format.
  local vec3=coord.LLtoLO(Latitude, Longitude)

  -- Convert vec3 to coordinate object.
  self=VECTOR:NewFromVec(vec3)
  
  -- Adjust height
  if Altitude then
    self.y=Altitude
  end

  return self
end

--- Creates a new VECTOR instance from given latitude and longitude in degrees, minutes and seconds (DMS).
-- **Note** that latitude and longitude are passed as strings and the characters `°`, `'` and `"` are important.
-- @param #VECTOR self
-- @param #string Latitude Latitude in DMS as string, e.g. "`42° 24' 14.3"`".
-- @param #string Longitude Longitude in DMS as string, e.g. "`42° 24' 14.3"`".
-- @param #number Altitude (Optional) Altitude in meters. Default is the land height at the coordinate.
-- @return #VECTOR
function VECTOR:NewFromLLDMS(Latitude, Longitude, Altitude)

  local lat=UTILS.LLDMSstringToDD(Latitude)
  local lon=UTILS.LLDMSstringToDD(Longitude)
  
  self=VECTOR:NewFromLLDD(lat, lon, Altitude)

  return self
end  

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get 2D vector as simple table.
-- @param #VECTOR self
-- @return DCS#Vec2 2D array {x, y}.
function VECTOR:GetVec2()

  local vec={x=self.x, y=self.z}
  
  return vec
end

--- Get 3D vector as simple table.
-- @param #VECTOR self
-- @param #boolean OnSurface If `true`, the `y` component is set the land height [m] of the 2D position.
-- @return DCS#Vec3 3D array {x=x, y=y, z=z}.
function VECTOR:GetVec3(OnSurface)

  local x=self.x
  local y=OnSurface and land.getHeight({x=self.x, y=self.z}) or self.y
  local z=self.z

  local vec={x=x, y=y, z=z} --DCS#Vec3
  
  return vec
end

--- Get a COORDINATE object.
-- @param #VECTOR self
-- @param #boolean OnSurface If `true`, the `y` component is set the land height [m] of the 2D position.
-- @return Core.Point#COORDINATE The COORDINATE object.
function VECTOR:GetCoordinate(OnSurface)

  local vec3=self:GetVec3(OnSurface)
  
  local coordinate=COORDINATE:NewFromVec3(vec3)
  
  return coordinate
end

--- Get the distance from this vector to another vector.
-- @param #VECTOR self
-- @param #VECTOR Vector Vector to which the distance is requested.
-- @param #boolean Only2D If `true`, calculate only the projected 2D distance. 
-- @return #number Distance in meters.
function VECTOR:GetDistance(Vector, Only2D)

  local dx=self.x-Vector.x
  local dy=0
  local dz=0
  
  if Vector.z then
    if not Only2D then
      dy=self.y-Vector.y
    end    
    dz=self.z-Vector.z
  else
    -- Given vector is 2D.
    dy=0
    dz=self.z-Vector.y
  end

  -- Calculate the distance.
  local dist=math.sqrt( dx*dx + dy*dy + dz*dz )
  
  return dist
end

--- Get the directional vector that points from this VECTOR to another VECTOR `a`.
-- @param #VECTOR self
-- @param #VECTOR a Vector `a`. This can also be given as any table with `x`, `y` and `z` components, where `z` is optional.
-- @return #VECTOR Directional vector from this vector to `a`.
function VECTOR:GetDirectionalVectorTo(a)

  local x=a.x-self.x
  local y=0
  local z=nil
    
  if a.z then
    -- a is 3D
    y=a.y-self.y
    z=a.z-self.z
  else
  -- a is 2D
    y=a.y-self.z
    z=nil --We leave z=nil, so the New function takes care of the 2D character.
  end
  
  local c=VECTOR:New(x, y, z)
   
  return c
end

--- Get the directional vector that points from another VECTOR `a` to this VECTOR.
-- @param #VECTOR self
-- @param #VECTOR a Vector a. This can also be given as any table with x,y and z components (z optional).
-- @return #VECTOR Directional vector from self to a.
function VECTOR:GetDirectionalVectorFrom(a)
  
  local x=self.x-a.x
  local y
  local z
    
  if a.z then
    -- a is 3D
    y=self.y-a.y
    z=self.z-a.z
  else
  -- a is 2D ==> we work in 2D and take z component of self
    y=self.z-a.y
    z=nil --We leave z=nil, so the New function takes care of the 2D character.
  end
  
  local c=VECTOR:New(x, y, z)
   
  return c
end

--- Get length/norm/magnitude of this vector.
-- @param #VECTOR self
-- @return #number Length of vector.
function VECTOR:GetLength()

  local l=math.sqrt(self.x*self.x+self.y*self.y+self.z*self.z)

  return l
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

  -- Get heading.
  local heading=math.atan2(self.z, self.x)
  
  -- Convert to degrees.
  heading=math.deg(heading)
  
  
  if To360==nil or To360==true then
    -- Adjust heading so it is in [0,360).
    heading=UTILS.AdjustHeading360(heading)
  else
    -- Just make sure 360 is returned a 0.
    if heading==360.0 then
      heading=0.0
    end  
  end

  return heading
end

--- Get the heading from this vector to another given vector.
-- @param #VECTOR self
-- @param #VECTOR Vector Vector to which the heading is requested.
-- @return #number Heading from this vector to the other vector in degrees.
function VECTOR:GetHeadingTo(Vector)

  -- Get directional vector from given vector to this vector.
  local a=self:GetDirectionalVectorTo(Vector)
  
  -- Get heading of directional vector.
  local heading=math.deg(math.atan2(a.z, a.x))  
  
  -- Adjust heading so it is in [0,360).
  heading=UTILS.AdjustHeading360(heading)
  
  return heading
end

--- Get the heading from a given vector to this vector.
-- @param #VECTOR self
-- @param #VECTOR Vector Vector from which the heading is requested.
-- @return #number Heading from the other vector to this vector in degrees.
function VECTOR:GetHeadingFrom(Vector)

  -- Get directional vector from given vector to this vector.
  local a=self:GetDirectionalVectorFrom(Vector)
  
  -- Get heading of directional vector.
  local heading=math.deg(math.atan2(a.z, a.x))

  -- Adjust heading so it is in [0,360).
  heading=UTILS.AdjustHeading360(heading)
  
  return heading
end


--- Get latitude and longitude of this vector.
-- @param #VECTOR self
-- @return #number Latitude in decimal degrees (DD).
-- @return #number Longitude in decimal degrees (DD).
function VECTOR:GetLatitudeLongitude()

  local vec3=self:GetVec3()

  local latitude, longitude, altitude=coord.LOtoLL(vec3)
  
  return latitude, longitude
end


--- Get MGRS information of this vector.
-- 
-- `MGRS = {UTMZone = string, MGRSDigraph = string, Easting = number, Northing = number}`
-- 
-- @param #VECTOR self
-- @return #table MGRS table with `UTMZone`, `MGRSDiGraph`, `Easting` and `Northing` keys.
function VECTOR:GetMGRS()

  local lat, long=self:GetLatitudeLongitude()

  local mgrs=coord.LLtoMGRS(lat, long)

  -- Example table returned by coord.LLtoMGRS
  --[[
  MGRS = {
    UTMZone = string,
    MGRSDigraph = string,
    Easting = number,
    Northing = number
  }
  ]]
  
  return mgrs
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

--- Return an intermediate VECTOR between this and another given vector.
-- @param #VECTOR self
-- @param #VECTOR Vector The destination vector.
-- @param #number Fraction The fraction (0,1) where the new vector is created. Default 0.5, *i.e.* in the middle.
-- @return #VECTOR Vector between this and the other vector.
function VECTOR:GetIntermediateVector(Vector, Fraction)

  local f=Fraction or 0.5

  -- Get the directional vector to the given Vector.
  local vec=self:GetDirectionalVectorTo(Vector)
  
  -- Get the length of the vector.
  local length=vec:GetLength()
  
  -- Set/scale the length.
  vec:SetLength(f*length)
 
  -- Get to the desired position.
  vec=self+vec
  
  return vec
end



--- Set length/norm/magnitude of this vector.
-- @param #VECTOR self
-- @param #number Length Desired length of vector.
function VECTOR:SetLength(Length)

  -- Normalize this vector to a length of 1.
  self:Normalize()
  
  -- Scale the vector to the desired length.
  local v=self*Length
  
  -- Replace with scaled version.
  self:Replace(v)
  
  return self
end

--- Set x-component of vector. The x-axis points to the North.
-- @param #VECTOR self
-- @param #number x Value of x. Default 0.
-- @return #VECTOR self
function VECTOR:SetX(x)
  self.x=x or 0
  return self
end

--- Set y-component of vector. The y-axis points to the upwards and describes the altitude above mean sea level.
-- @param #VECTOR self
-- @param #number y Value of y. Default land/surface height at this point.
-- @return #VECTOR self
function VECTOR:SetY(y)

  if y==nil then
    y=self:GetSurfaceHeight()
  end
  self.y=y
  return self
end

--- Set z-component of vector. The z-axis points to the East.
-- @param #VECTOR self
-- @param #number z Value of z. Default 0.
-- @return #VECTOR self
function VECTOR:SetZ(z)
  self.z=z or 0
  return self
end


--- Add a vector to this. This function works for DCS#Vec2, DCS#Vec3, VECTOR, COORDINATE objects.
-- Note that if you want to add a VECTOR, you can also simply use the `+` operator.
-- @param #VECTOR self
-- @param DCS#Vec3 Vec Vector to add. Can also be a DCS#Vec2, DCS#Vec3, COORDINATE or VECTOR object.
-- @return #VECTOR self
function VECTOR:AddVec(Vec)

  self.x=self.x+Vec.x
  
  if Vec.z then
    self.y=self.y+Vec.y
    self.z=self.z+Vec.z
  else
    -- Vec is 2D ==> we take its y-component.
    self.z=self.z+Vec.y  
  end
  
  return self
end

--- Subtract a vector from this one. This function works for DCS#Vec2, DCS#Vec3, VECTOR, COORDINATE objects.
-- 
-- **Note** that if you want to add a VECTOR, you can also simply use the `-` operator.
-- @param #VECTOR self
-- @param DCS#Vec3 Vec Vector to substract. Can also be a DCS#Vec2, DCS#Vec3, COORDINATE or VECTOR object.
-- @return #VECTOR self
function VECTOR:SubVec(Vec)

  self.x=self.x-Vec.x
  
  if Vec.z then
    self.y=self.y-Vec.y
    self.z=self.z-Vec.z
  else
    -- Vec is 2D ==> we take its y-component.
    self.z=self.z-Vec.y  
  end
   
  return self
end

--- Calculate the dot product of this VECTOR with another vector. This function works for DCS#Vec2, DCS#Vec3, VECTOR, COORDINATE objects.
-- @param #VECTOR self
-- @param DCS#Vec3 Vec The other vector. Can also be a DCS#Vec2, DCS#Vec3, COORDINATE or VECTOR object.
-- @return #number Dot product Sum_i(a[i]*b[i]). Note that this is a **scalar** and not a vector any more!
function VECTOR:Dot(Vec)

  local dot=self.x*Vec.x
  if Vec.z then
    dot=dot+self.y*Vec.y+self.z*Vec.z
  else
    -- Vec is 2D ==> we take its y-component for z.
    dot=dot+self.z*Vec.y
  end
   
  return dot
end

--- Calculate the rotation or cross product of this VECTOR with another vector. This function works for DCS#Vec2, DCS#Vec3, VECTOR, COORDINATE objects.
-- @param #VECTOR self
-- @param DCS#Vec3 Vec The other vector. Can also be a DCS#Vec2, DCS#Vec3, COORDINATE or VECTOR object.
-- @return #VECTOR The cross product vector.
function VECTOR:Rot(Vec)

  -- TODO:
  local dot=self.x*Vec.x
  if Vec.z then
    dot=dot+self.y*Vec.y+self.z*Vec.z
  else
    -- Vec is 2D ==> we take its y-component for z.
    dot=dot+self.z*Vec.y
  end
   
  return dot
end


--- Get a clone (deep copy) of this vector.
-- @param #VECTOR self
-- @return #VECTOR Copy of the vector.
function VECTOR:Copy()
  
  local c=VECTOR:New(self.x, self.y, self.z)
   
  return c
end

--- Replace this vector with another one.
-- If the given vector is 2D, we 
-- @param #VECTOR self
-- @param #VECTOR Vector The vector that is used to replace this vector.
-- @param #boolean Project2D If `true` and the given vector is 2D, we project the updated vector to 2D (`y=0`). Otherwise, we leave `y` untouched.
-- @return #VECTOR self updated
function VECTOR:Replace(Vector, Project2D)
  
  self.x=Vector.x
  
  if Vector.z then
    -- Given vector is 3D
    self.y=Vector.y
    self.z=Vector.z
  else
    -- Given vector is 2D
    if Project2D then
      self.y=0
    end
    self.z=Vector.y
  end

  return self
end

--- Normalize this vector, so that has a length of 1.
-- @param #VECTOR self
-- @return #VECTOR self
function VECTOR:Normalize()

  local l=self:GetLength()
  
  if l~=0 then
    self:Replace(self/l)
  end
   
  return self
end

--- Translate the vector by a given distance and angle.
-- @param #VECTOR self
-- @param #number Distance Distance in meters. Default 1000 meters.
-- @param #number Heading Heading angle in degrees. Default 0° = North.
-- @param #boolean Copy Create a copy of the VECTOR so the original stays unchanged.
-- @return #VECTOR The translated vector or a copy of it.
function VECTOR:Translate(Distance, Heading, Copy)

  -- Set default distance if not passed.
  Distance=Distance or 1000

  -- Angle in rad.
  local alpha = math.rad(Heading or 0)
  
  -- Create a copy if requested.
  local vector=Copy and self:Copy() or self

  -- Set new coordinates.
  vector.x = Distance * math.cos(alpha) + vector.x  -- New x
  vector.z = Distance * math.sin(alpha) + vector.z  -- New z
     
  return vector
end

--- Rotate the VECTOR clockwise in the 2D (x,z) plane.
-- @param #VECTOR self
-- @param #number Angle Rotation angle in degrees). Default 0.
-- @param #boolean Copy Create a copy of the VECTOR so the original stays unchanged.
-- @return #VECTOR The translated vector or a copy of it.
function VECTOR:Rotate2D(Angle, Copy)

  -- Angle in rad.
  local phi = -math.rad(Angle or 0)

  -- Sin/Cos of angle.
  local sinPhi = math.sin(phi)
  local cosPhi = math.cos(phi)
  
  -- Get more convenient notation.
  local X=self.z
  local Y=self.x
  
  -- Apply rotation matrix.
  local z = X*cosPhi - Y*sinPhi 
  local x = X*sinPhi + Y*cosPhi
  
  -- Create new vector.
  if Copy then
    local vector=VECTOR:New(x, self.y, z)
    return vector
  else
    self:SetX(x)
    self:SetZ(z)
    return self
  end
end



--- Provides an MGRS string.
-- @param #VECTOR self
-- @param Core.Settings#SETTINGS Settings (Optional) The settings. Can be nil, and in this case the default settings are used. If you want to specify your own settings, use the _SETTINGS object.
-- @return #string The MGRS text.
function VECTOR:ToStringMGRS(Settings)

  -- Get Accuracy.
  local MGRS_Accuracy = Settings and Settings.MGRS_Accuracy or _SETTINGS.MGRS_Accuracy
  
  local lat, lon = coord.LOtoLL( self:GetVec3() )
  
  local MGRS = coord.LLtoMGRS( lat, lon )
  
  local text="MGRS " .. UTILS.tostringMGRS( MGRS, MGRS_Accuracy )
  
  return text
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- DCS API Wrapper Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get the surface type at the vector.
-- 
-- * LAND = 1
-- * SHALLOW_WATER = 2
-- * WATER = 3
-- * ROAD = 4
-- * RUNWAY = 5
-- 
-- @param #VECTOR self
-- @return #number Surface type
function VECTOR:GetSurfaceType()

  local vec2=self:GetVec2()
  
  local s=land.getSurfaceType(vec2)
   
  return s
end


--- Get the name of surface type at the vector.
-- 
-- * LAND = 1
-- * SHALLOW_WATER = 2
-- * WATER = 3
-- * ROAD = 4
-- * RUNWAY = 5
-- 
-- @param #VECTOR self
-- @return #string Surface type name
function VECTOR:GetSurfaceTypeName()

  local vec2=self:GetVec2()
  
  local s=land.getSurfaceType(vec2)
  
  for name,id in land.SurfaceType() do
    if id==s then
      return name
    end
  end
   
  return "unknown"
end

--- Check if a given vector has line of sight with this vector.
-- @param #VECTOR self
-- @param #VECTOR Vec The other vector.
-- @return #number Surface Type
function VECTOR:IsVisible(Vec)

  local vec1=self:GetVec3()
  
  local vec2={x=Vec.x, Vec.y, Vec.z}
  
  local los=land.isVisible(vec1, vec2)

  return los
end

--- Get a vector on the closest road.
-- @param #VECTOR self
-- @return #VECTOR Closest vector to a road.
function VECTOR:GetClosestRoad()

  local vec2=self:GetVec2()

  local x,y=land.getClosestPointOnRoads('roads', vec2.x, vec2.y)
  
  local road=nil  
  if x and y then
    road=VECTOR:New(x, y)
  end

  return road
end

--- Get a vector on the closest railroad.
-- @param #VECTOR self
-- @return #VECTOR Closest vector to a railroad.
function VECTOR:GetClosestRailroad()

  local vec2=self:GetVec2()

  local x,y=land.getClosestPointOnRoads('railroads', vec2.x, vec2.y)
  
  local road=nil  
  if x and y then
    road=VECTOR:New(x, y)
  end

  return road
end


--- Get the path on road from this vector to a given other vector.
-- @param #VECTOR self
-- @param #VECTOR Vec The destination vector.
-- @return Core.Pathline#PATHLINE Pathline with points on road.
function VECTOR:GetPathOnRoad(Vec)

  local vec1=self:GetVec2()
  local vec2=Vec:GetVec2()
  
  local vec2points=land.findPathOnRoads("roads", vec1.x , vec1.y, vec2.x, vec2.y)
  
  local path=nil  
  if vec2points then    
    path=PATHLINE:NewFromVec2Array("Road", vec2points)
  end

  return path
end


--- Get profile of the land between the two passed points.
-- @param #VECTOR self
-- @param #VECTOR Vec3 The 3D destination vector. If a 2D vector is passed, `y` is set to the land height.
-- @return Core.Pathline#PATHLINE Pathline with points of the profile.
function VECTOR:GetProfile(Vec3)

  local vec3=self:GetVec3()

  -- Get profile
  local vec3s=land.profile(vec3, Vec3)

  local profile=nil
  if vec3s then
  
    profile=PATHLINE:NewFromVec3Array("Profile", vec3s)
  
  end

  return profile
end

--- Returns an intercept point at which a ray drawn from the this vector in the passed normalized direction for a specified distance.
-- @param #VECTOR self
-- @param DCS#Vec3 DirectionVector Directional vector.
-- @param #number Distance Distance in meters. Default 1000 m.
-- @return #VECTOR Intercept vector. Can be `nil` if no intercept point is found.
function VECTOR:GetInterceptPoint(DirectionVector, Distance)

  local vec3=self:GetVec3()

  local ip3=land.getIP(vec3, DirectionVector, Distance or 1000) --DCS#Vec3
  
  local ipvector=nil
  
  if ip3 then
    ipvector=VECTOR:New(ip3.x, ip3.y , ip3.z)
  end

  return ipvector
end

--- Returns the distance from sea level at this vector.
-- @param #VECTOR self
-- @return #number Distance above sea leavel in meters.
function VECTOR:GetSurfaceHeight()

  local vec2=self:GetVec2()

  local h=land.getHeight(vec2)
  
  return h
end


--- Returns the distance from sea level at this vector.
-- @param #VECTOR self
-- @return #number Heigh above sea leavel in meters.
-- @return #number Depth (positive) at this point in meters.
function VECTOR:GetSurfaceHeightAndDepth()

  local vec2=self:GetVec2()

  local h,d=land.getSurfaceHeightWithSeabed(vec2)

  return h,d
end

--- Returns a velocity vector of the wind at this vector. Turbolences can be optionally be included.
-- @param #VECTOR self
-- @param #boolean WithTurbulence If `true`, return wind including turbulence.
-- @return #VECTOR Velocity 3D vector [m/s] the wind is blowing to.
function VECTOR:GetWindVector(WithTurbulence)

  local vec3=self:GetVec3()

  local wind=nil
  if WithTurbulence then
    wind=atmosphere.getWindWithTurbulence(vec3)
    
  else
    wind=atmosphere.getWind(vec3)
  end
  
  local vector=VECTOR:New(wind)

  return vector
end

--- Returns a temperature and pressure at this vector.
-- @param #VECTOR self
-- @return #number Temperatur in Kelvin.
-- @return #number Pressure in Pascals.
function VECTOR:GetTemperaturAndPressure()

  local vec3=self:GetVec3()

  local t,p=atmosphere.getTemperatureAndPressure(vec3)

  return t,p
end

--- Creates a smoke at this vector.
-- @param #VECTOR self
-- @param #number Color Color of the smoke: 0=Green, 1=Red, 2=White, 3=Orange, 4=Blue. Default 0.
-- @param #number Duration (Optional) Duration of the smoke in seconds. Default nil.
-- @return #string Name of the smoke object. Can be used to stop it. 
function VECTOR:Smoke(Color, Duration)

  local vec3=self:GetVec3()
  
  Color=Color or 0

  -- Create a name for the smoke object
  local name=string.format("Vector-Smoke-%d", self.uid)
  
  -- Create smoke at this position
  trigger.action.smoke(vec3, Color, name)
  
  if Duration and Duration>0 then
    self:StopSmoke(name, Duration)
  end

  return name
end


--- Creates a large smoke and fire effect of a specified type and density at this vector.
-- 
-- * 1 = small smoke and fire
-- * 2 = medium smoke and fire
-- * 3 = large smoke and fire
-- * 4 = huge smoke and fire
-- * 5 = small smoke
-- * 6 = medium smoke 
-- * 7 = large smoke
-- * 8 = huge smoke
-- 
-- @param #VECTOR self
-- @param #number Preset Preset of smoke. Default `BIGSMOKEPRESET.LargeSmokeAndFire`.
-- @param #number Density Density between [0,1]. Default 0.5.
-- @param #number Duration (Optional) Duration of the smoke and fire in seconds.
-- @return #string Name of the smoke. Can be used to stop it. 
function VECTOR:SmokeAndFire(Preset, Density, Duration)

  Preset=Preset or BIGSMOKEPRESET.LargeSmokeAndFire
  Density=Density or 0.5

  local vec3=self:GetVec3()
  
  -- Get a name of this smoke & fire object
  local name=string.format("Vector-Fire-%d", self.uid)

  trigger.action.effectSmokeBig(vec3, Preset, Density, name)
  
  if Duration and Duration>0 then
    self:StopSmoke(name, Duration)
  end  

  return name
end

--- Stop smoke or fire effect.
-- @param #VECTOR self
-- @param #string Name Name of the smoke object.
-- @param #number Delay Delay in seconds before the smoke is stopped.
-- @return #VECTOR self
function VECTOR:StopSmoke(Name, Delay)

  if Delay and Delay>0 then
    TIMER:New(VECTOR.StopSmoke, self, Name):Start(Delay)
  else
    if Name then
      trigger.action.effectSmokeStop(Name)
    else
      env.error(string.format("No name provided in VECTOR.StopSmoke function!"))
    end
  end
  
  return self
end


--- Creates an illumination bomb at the specified point.
-- @param #VECTOR self
-- @param #number Power The power in Candela (cd). Should be between 1 and 1000000. Default 1000 cd.
-- @param #number Altitude (Optional) Altitude [m] at which the illumination bomb is created.
-- @return #VECTOR self
function VECTOR:IlluminationBomb(Power, Altitude)

  local vec3=self:GetVec3()
  
  if Altitude then
    vec3.y=Altitude
  end

  -- Create an illumination bomb.
  trigger.action.illuminationBomb(vec3, Power or 1000)

  return self
end

--- Creates an explosion at a given point at the specified power.
-- @param #VECTOR self
-- @param #number Power The power in kg TNT. Default 100 kg.
-- @return #VECTOR self
function VECTOR:Explosion(Power)

  local vec3=self:GetVec3()

  trigger.action.explosion(vec3, Power or 100)

  return self
end

--- Creates a signal flare at the given point in the specified color. The flare will be launched in the direction of the azimuth angle.
-- @param #VECTOR self
-- @param #number Color Color of flare. Default Green.
-- @param #number Azimuth Azimuth angle in degrees. Default 0.
-- @return #VECTOR self
function VECTOR:Flare(Color, Azimuth)

  local vec3=self:GetVec3()

  trigger.action.signalFlare(vec3, Color or 0, math.rad(Azimuth or 0))

  return self
end


--- Creates a arrow from this VECTOR to another vector on the F10 map.
-- @param #VECTOR self
-- @param #VECTOR Vector The vector defining the endpoint.
-- @param #number Coalition Coalition Id: -1=All, 0=Neutral, 1=Red, 2=Blue. Default -1.
-- @param #table Color RGB color with alpha {r, g, b, alpha}. Default {1, 0, 0, 0.7}.
-- @param #table FillColor RGB color with alpha {r, g, b, alpha}. Default {1, 0, 0, 0.5}.
-- @param #number LineType Line type: 0=No line, 1=Solid, 2=Dashed, 3=Dotted, 4=Dot Dash, 5=Long Dash, 6=Two Dash. Default 1.
-- @return #number Marker ID. Can be used to remove the drawing.
function VECTOR:ArrowTo(Vector, Coalition, Color, FillColor, LineType)

  local vec3End=self:GetVec3()
  local vec3Start=Vector:GetVec3()
  
  local id=UTILS.GetMarkID()
  
  Coalition=Coalition or -1
  Color=Color or {1,0,0,0.7}
  FillColor=FillColor or {1,0,0,0.5}
  LineType=LineType or 1
  
  local readOnly=false
  
  trigger.action.arrowToAll(Coalition , id, vec3Start, vec3End, Color, FillColor , LineType, readOnly, "")

  return id
end


--- Create mark on F10 map.
-- @param #VECTOR self
-- @param #string MarkText Free format text that shows the marking clarification.
-- @param #number Recipient Recipient of the mark: -1=All (default), 0=Neutral, 1=Red, 2=Blue. Can also be a `GROUP` object.
-- @param #boolean ReadOnly (Optional) Mark is readonly and cannot be removed by users. Default false.
-- @return #number Mark ID.
function VECTOR:Mark(MarkText, Recipient, ReadOnly)

  Recipient=Recipient or -1

  if type(Recipient)=="number" then
  
    local MarkID = UTILS.GetMarkID()
  
    if Recipient==-1 then
      trigger.action.markToAll(MarkID, MarkText, self:GetVec3(), ReadOnly, "")
    elseif Recipient==0 then
      trigger.action.markToCoalition(MarkID, MarkText, self:GetVec3(), coalition.side.NEUTRAL, ReadOnly, "")
    elseif Recipient==1 then
      trigger.action.markToCoalition(MarkID, MarkText, self:GetVec3(), coalition.side.RED, ReadOnly, "")
    elseif Recipient==2 then
      trigger.action.markToCoalition(MarkID, MarkText, self:GetVec3(), coalition.side.BLUE, ReadOnly, "")
    end
  
    return MarkID
      
  elseif type(Recipient)=="table" then
  
    local MarkID = UTILS.GetMarkID()
    
    local group=Recipient --Wrapper.Group#GROUP
    
    trigger.action.markToGroup( MarkID, MarkText, self:GetVec3(), group:GetID(), ReadOnly, "")
    
    return MarkID
    
  end

  return nil
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
-- @param #VECTOR a Vector a.
-- @param #VECTOR b Vector b.
-- @return #VECTOR Returns a new VECTOR c with c[i]=a[i]+b[i] for i=x,y,z.
function VECTOR.__add(a,b)

  assert(VECTOR._IsVector(a) and VECTOR._IsVector(b), "ERROR in VECTOR.__add: wrong argument types! (expected <vector> and <vector>)")
  
  local c=VECTOR:New(a.x+b.x, a.y+b.y, a.z+b.z)
  
  return c
end

--- Meta function to subtract vectors.
-- @param #VECTOR a Vector a.
-- @param #VECTOR b Vector b.
-- @return #VECTOR Returns a new VECTOR c with c[i]=a[i]-b[i] for i=x,y,z.
function VECTOR.__sub(a,b)

  assert(VECTOR._IsVector(a) and VECTOR._IsVector(b), "ERROR in VECTOR.__sub: wrong argument types: (expected <vector> and <vector>)")
  
  local c=VECTOR:New(a.x-b.x, a.y-b.y, a.z-b.z)
   
  return c
end


--- Meta function to multiplicate vector by another vector or a scalar.
-- @param #VECTOR a Vector a. Can also be a #number.
-- @param #VECTOR b Vector b. Can also be a #number.
-- @return #VECTOR Returns a new VECTOR c with c[i]=a[i]*b[i] for i=x,y,z.
function VECTOR.__mul(a, b)

  local c=nil --#VECTOR
  
  if type(a)=='number' then
    c=VECTOR:New(a*b.x, a*b.y, a*b.z)
  elseif type(b)=='number' then
    c=VECTOR:New(b*a.x, b*a.y, b*a.z)
  else
    c=VECTOR:New(a.x*b.x, a.y*b.y, a.z*b.z)
  end
   
  return c
end

--- Meta function for dividing a vector by a scalar or by another vector.
-- @param #VECTOR a Vector a.
-- @param #VECTOR b Vector b. Can also be a #number.
-- @return #VECTOR Returns a new VECTOR c with c[i]=a[i]/b or c[i]=a[i]/b[i] for i=x,y,z.
function VECTOR.__div(a, b)

  assert(VECTOR._IsVector(a) and (type(b) == "number" or VECTOR._IsVector(b)), "div: wrong argument types (expected <vector> and (<number> or <vector>))")

  local c=nil --#VECTOR

  if type(b) == "number" then
    c=VECTOR:New(a.x/b, a.y/b, a.z/b)
  else
    c=VECTOR:New(a.x/b.x, a.y/b.y, a.z/b.z)
  end

  return c
end

--- Meta function to make vectors negative.
-- @param #VECTOR v Vector v.
function VECTOR.__unm(v)
  local c=VECTOR:New(-v.x, -v.y, -v.z)
  return c
end

--- Meta function to check if two vectors are equal.
-- @param #VECTOR a Vector a.
-- @param #VECTOR b Vector b.
-- @return #boolean If `true`, both vectors are equal
function VECTOR.__eq(a, b)
  return a.x==b.x and a.y==b.y and a.z==b.z
end


--- Meta function to change how vectors appear as string.
-- @param #VECTOR self
-- @return #string String representation of vector.
function VECTOR:__tostring()
  local text=string.format("VECTOR: x=%.1f, y=%.1f, z=%.1f |v|=%.1f Phi=%4.1f°", self.x, self.y, self.z, self:GetLength(), self:GetHeading(false))
  return text
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
