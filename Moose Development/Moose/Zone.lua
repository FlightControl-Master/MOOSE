--- This module contains the ZONE classes, inherited from @{Zone#ZONE_BASE}.
-- There are essentially two core functions that zones accomodate:
-- 
--   * Test if an object is within the zone boundaries.
--   * Provide the zone behaviour. Some zones are static, while others are moveable.
-- 
-- The object classes are using the zone classes to test the zone boundaries, which can take various forms:
-- 
--   * Test if completely within the zone.
--   * Test if partly within the zone (for @{Group#GROUP} objects).
--   * Test if not in the zone.
--   * Distance to the nearest intersecting point of the zone.
--   * Distance to the center of the zone.
--   * ...
-- 
-- Each of these ZONE classes have a zone name, and specific parameters defining the zone type:
--   
--   * @{Zone#ZONE_BASE}: The ZONE_BASE class defining the base for all other zone classes.
--   * @{Zone#ZONE_RADIUS}: The ZONE_RADIUS class defined by a zone name, a location and a radius.
--   * @{Zone#ZONE}: The ZONE class, defined by the zone name as defined within the Mission Editor.
--   * @{Zone#ZONE_UNIT}: The ZONE_UNIT class defined by a zone around a @{Unit#UNIT} with a radius.
--   * @{Zone#ZONE_POLYGON}: The ZONE_POLYGON class defined by a sequence of @{Group#GROUP} waypoints within the Mission Editor, forming a polygon.
-- 
-- Each zone implements two polymorphic functions defined in @{Zone#ZONE_BASE}:
-- 
--   * @{#ZONE_BASE.IsPointVec2InZone}: Returns if a location is within the zone.
--   * @{#ZONE_BASE.IsPointVec3InZone}: Returns if a point is within the zone.
-- 
-- ===
-- 
-- 1) @{Zone#ZONE_BASE} class, extends @{Base#BASE}
-- ================================================
-- The ZONE_BASE class defining the base for all other zone classes.
-- 
-- ===
-- 
-- 2) @{Zone#ZONE_RADIUS} class, extends @{Zone#ZONE_BASE}
-- =======================================================
-- The ZONE_RADIUS class defined by a zone name, a location and a radius.
-- 
-- ===
-- 
-- 3) @{Zone#ZONE} class, extends @{Zone#ZONE_RADIUS}
-- ==========================================
-- The ZONE class, defined by the zone name as defined within the Mission Editor.
-- 
-- ===
-- 
-- 4) @{Zone#ZONE_UNIT} class, extends @{Zone#ZONE_RADIUS}
-- =======================================================
-- The ZONE_UNIT class defined by a zone around a @{Unit#UNIT} with a radius.
-- 
-- ===
-- 
-- 5) @{Zone#ZONE_POLYGON} class, extends @{Zone#ZONE_BASE}
-- ========================================================
-- The ZONE_POLYGON class defined by a sequence of @{Group#GROUP} waypoints within the Mission Editor, forming a polygon.
-- 
-- ===
-- 
-- @module Zone
-- @author FlightControl









--- The ZONE_BASE class
-- @type ZONE_BASE
-- @field #string ZoneName Name of the zone.
-- @extends Base#BASE
ZONE_BASE = {
  ClassName = "ZONE_BASE",
  }

--- ZONE_BASE constructor
-- @param #ZONE_BASE self
-- @param #string ZoneName Name of the zone.
-- @return #ZONE_BASE self
function ZONE_BASE:New( ZoneName )
  local self = BASE:Inherit( self, BASE:New() )
  self:F( ZoneName )

  self.ZoneName = ZoneName
  
  return self
end

--- Returns if a location is within the zone.
-- @param #ZONE_RADIUS self
-- @param DCSTypes#Vec2 PointVec2 The location to test.
-- @return #boolean true if the location is within the zone.
function ZONE_BASE:IsPointVec2InZone( PointVec2 )
  self:F2( PointVec2 )

  return false
end

--- Returns if a point is within the zone.
-- @param #ZONE_RADIUS self
-- @param DCSTypes#Vec3 PointVec3 The point to test.
-- @return #boolean true if the point is within the zone.
function ZONE_BASE:IsPointVec3InZone( PointVec3 )
  self:F2( PointVec3 )

  local InZone = self:IsPointVec2InZone( { x = PointVec3.x, y = PointVec3.z } )

  return InZone
end

--- Smokes the zone boundaries in a color.
-- @param #ZONE_BASE self
-- @param SmokeColor The smoke color.
function ZONE_BASE:SmokeZone( SmokeColor )
  self:F2( SmokeColor )

end


--- The ZONE_RADIUS class, defined by a zone name, a location and a radius.
-- @type ZONE_RADIUS
-- @field DCSTypes#Vec2 PointVec2 The current location of the zone.
-- @field DCSTypes#Distance Radius The radius of the zone.
-- @extends Zone#ZONE_BASE
ZONE_RADIUS = {
	ClassName="ZONE_RADIUS",
	}

--- Constructor of ZONE_RADIUS, taking the zone name, the zone location and a radius.
-- @param #ZONE_RADIUS self
-- @param #string ZoneName Name of the zone.
-- @param DCSTypes#Vec2 PointVec2 The location of the zone.
-- @param DCSTypes#Distance Radius The radius of the zone.
-- @return #ZONE_RADIUS self
function ZONE_RADIUS:New( ZoneName, PointVec2, Radius )
	local self = BASE:Inherit( self, ZONE_BASE:New( ZoneName ) )
	self:F( { ZoneName, PointVec2, Radius } )

	self.Radius = Radius
	self.PointVec2 = PointVec2
	
	return self
end

--- Smokes the zone boundaries in a color.
-- @param #ZONE_RADIUS self
-- @param #POINT_VEC3.SmokeColor SmokeColor The smoke color.
-- @param #number Points (optional) The amount of points in the circle.
-- @return #ZONE_RADIUS self
function ZONE_RADIUS:SmokeZone( SmokeColor, Points )
  self:F2( SmokeColor )

  local Point = {}
  local PointVec2 = self:GetPointVec2()

  Points = Points and Points or 360

  local Angle
  local RadialBase = math.pi*2
  
  for Angle = 0, 360, 360 / Points do
    local Radial = Angle * RadialBase / 360
    Point.x = PointVec2.x + math.cos( Radial ) * self:GetRadius()
    Point.y = PointVec2.y + math.sin( Radial ) * self:GetRadius()
    POINT_VEC2:New( Point.x, Point.y ):Smoke( SmokeColor )
  end

  return self
end


--- Flares the zone boundaries in a color.
-- @param #ZONE_RADIUS self
-- @param #POINT_VEC3.FlareColor FlareColor The flare color.
-- @param #number Points (optional) The amount of points in the circle.
-- @param DCSTypes#Azimuth Azimuth (optional) Azimuth The azimuth of the flare.
-- @return #ZONE_RADIUS self
function ZONE_RADIUS:FlareZone( FlareColor, Points, Azimuth )
  self:F2( { FlareColor, Azimuth } )

  local Point = {}
  local PointVec2 = self:GetPointVec2()
  
  Points = Points and Points or 360

  local Angle
  local RadialBase = math.pi*2
  
  for Angle = 0, 360, 360 / Points do
    local Radial = Angle * RadialBase / 360
    Point.x = PointVec2.x + math.cos( Radial ) * self:GetRadius()
    Point.y = PointVec2.y + math.sin( Radial ) * self:GetRadius()
    POINT_VEC2:New( Point.x, Point.y ):Flare( FlareColor, Azimuth )
  end

  return self
end

--- Returns the radius of the zone.
-- @param #ZONE_RADIUS self
-- @return DCSTypes#Distance The radius of the zone.
function ZONE_RADIUS:GetRadius()
  self:F2( self.ZoneName )

  self:T2( { self.Radius } )

  return self.Radius
end

--- Sets the radius of the zone.
-- @param #ZONE_RADIUS self
-- @param DCSTypes#Distance Radius The radius of the zone.
-- @return DCSTypes#Distance The radius of the zone.
function ZONE_RADIUS:SetRadius( Radius )
  self:F2( self.ZoneName )

  self.Radius = Radius
  self:T2( { self.Radius } )

  return self.Radius
end

--- Returns the location of the zone.
-- @param #ZONE_RADIUS self
-- @return DCSTypes#Vec2 The location of the zone.
function ZONE_RADIUS:GetPointVec2()
	self:F2( self.ZoneName )

	self:T2( { self.PointVec2 } )
	
	return self.PointVec2	
end

--- Sets the location of the zone.
-- @param #ZONE_RADIUS self
-- @param DCSTypes#Vec2 PointVec2 The new location of the zone.
-- @return DCSTypes#Vec2 The new location of the zone.
function ZONE_RADIUS:SetPointVec2( PointVec2 )
  self:F2( self.ZoneName )
  
  self.PointVec2 = PointVec2

  self:T2( { self.PointVec2 } )
  
  return self.PointVec2 
end

--- Returns the point of the zone.
-- @param #ZONE_RADIUS self
-- @param DCSTypes#Distance Height The height to add to the land height where the center of the zone is located.
-- @return DCSTypes#Vec3 The point of the zone.
function ZONE_RADIUS:GetPointVec3( Height )
  self:F2( self.ZoneName )
  
  local PointVec2 = self:GetPointVec2()

  local PointVec3 = { x = PointVec2.x, y = land.getHeight( self:GetPointVec2() ) + Height, z = PointVec2.y }

  self:T2( { PointVec3 } )
  
  return PointVec3  
end


--- Returns if a location is within the zone.
-- @param #ZONE_RADIUS self
-- @param DCSTypes#Vec2 PointVec2 The location to test.
-- @return #boolean true if the location is within the zone.
function ZONE_RADIUS:IsPointVec2InZone( PointVec2 )
  self:F2( PointVec2 )
  
  local ZonePointVec2 = self:GetPointVec2()

  if (( PointVec2.x - ZonePointVec2.x )^2 + ( PointVec2.y - ZonePointVec2.y ) ^2 ) ^ 0.5 <= self:GetRadius() then
    return true
  end
  
  return false
end

--- Returns if a point is within the zone.
-- @param #ZONE_RADIUS self
-- @param DCSTypes#Vec3 PointVec3 The point to test.
-- @return #boolean true if the point is within the zone.
function ZONE_RADIUS:IsPointVec3InZone( PointVec3 )
  self:F2( PointVec3 )

  local InZone = self:IsPointVec2InZone( { x = PointVec3.x, y = PointVec3.z } )

  return InZone
end

--- Returns a random location within the zone.
-- @param #ZONE_RADIUS self
-- @return DCSTypes#Vec2 The random location within the zone.
function ZONE_RADIUS:GetRandomPointVec2()
	self:F( self.ZoneName )

	local Point = {}
	local PointVec2 = self:GetPointVec2()

	local angle = math.random() * math.pi*2;
	Point.x = PointVec2.x + math.cos( angle ) * math.random() * self:GetRadius();
	Point.y = PointVec2.y + math.sin( angle ) * math.random() * self:GetRadius();
	
	self:T( { Point } )
	
	return Point
end



--- The ZONE class, defined by the zone name as defined within the Mission Editor. The location and the radius are automatically collected from the mission settings.
-- @type ZONE
-- @extends Zone#ZONE_RADIUS
ZONE = {
  ClassName="ZONE",
  }


--- Constructor of ZONE, taking the zone name.
-- @param #ZONE self
-- @param #string ZoneName The name of the zone as defined within the mission editor.
-- @return #ZONE
function ZONE:New( ZoneName )

  local Zone = trigger.misc.getZone( ZoneName )
  
  if not Zone then
    error( "Zone " .. ZoneName .. " does not exist." )
    return nil
  end

  local self = BASE:Inherit( self, ZONE_RADIUS:New( ZoneName, { x = Zone.point.x, y = Zone.point.z }, Zone.radius ) )
  self:F( ZoneName )

  self.Zone = Zone
  
  return self
end


--- The ZONE_UNIT class defined by a zone around a @{Unit#UNIT} with a radius.
-- @type ZONE_UNIT
-- @field Unit#UNIT ZoneUNIT
-- @extends Zone#ZONE_RADIUS
ZONE_UNIT = {
  ClassName="ZONE_UNIT",
  }
  
--- Constructor to create a ZONE_UNIT instance, taking the zone name, a zone unit and a radius.
-- @param #ZONE_UNIT self
-- @param #string ZoneName Name of the zone.
-- @param Unit#UNIT ZoneUNIT The unit as the center of the zone.
-- @param DCSTypes#Distance Radius The radius of the zone.
-- @return #ZONE_UNIT self
function ZONE_UNIT:New( ZoneName, ZoneUNIT, Radius )
  local self = BASE:Inherit( self, ZONE_RADIUS:New( ZoneName, ZoneUNIT:GetPointVec2(), Radius ) )
  self:F( { ZoneName, ZoneUNIT:GetPointVec2(), Radius } )

  self.ZoneUNIT = ZoneUNIT
  
  return self
end


--- Returns the current location of the @{Unit#UNIT}.
-- @param #ZONE_UNIT self
-- @return DCSTypes#Vec2 The location of the zone based on the @{Unit#UNIT}location.
function ZONE_UNIT:GetPointVec2()
  self:F( self.ZoneName )
  
  local ZonePointVec2 = self.ZoneUNIT:GetPointVec2()

  self:T( { ZonePointVec2 } )
  
  return ZonePointVec2
end

-- Polygons

--- The ZONE_POLYGON_BASE class defined by an array of @{DCSTypes#Vec2}, forming a polygon.
-- @type ZONE_POLYGON_BASE
-- @field #ZONE_POLYGON_BASE.ListVec2 Polygon The polygon defined by an array of @{DCSTypes#Vec2}.
-- @extends Zone#ZONE_BASE
ZONE_POLYGON_BASE = {
  ClassName="ZONE_POLYGON_BASE",
  }

--- A points array.
-- @type ZONE_POLYGON_BASE.ListVec2
-- @list <DCSTypes#Vec2>

--- Constructor to create a ZONE_POLYGON_BASE instance, taking the zone name and an array of @{DCSTypes#Vec2}, forming a polygon.
-- The @{Group#GROUP} waypoints define the polygon corners. The first and the last point are automatically connected.
-- @param #ZONE_POLYGON_BASE self
-- @param #string ZoneName Name of the zone.
-- @param #ZONE_POLYGON_BASE.ListVec2 PointsArray An array of @{DCSTypes#Vec2}, forming a polygon..
-- @return #ZONE_POLYGON_BASE self
function ZONE_POLYGON_BASE:New( ZoneName, PointsArray )
  local self = BASE:Inherit( self, ZONE_BASE:New( ZoneName ) )
  self:F( { ZoneName, PointsArray } )

  local i = 0
  
  self.Polygon = {}
  
  for i = 1, #PointsArray do
    self.Polygon[i] = {}
    self.Polygon[i].x = PointsArray[i].x
    self.Polygon[i].y = PointsArray[i].y
  end

  return self
end

--- Flush polygon coordinates as a table in DCS.log.
-- @param #ZONE_POLYGON_BASE self
-- @return #ZONE_POLYGON_BASE self
function ZONE_POLYGON_BASE:Flush()
  self:F2()

  self:E( { Polygon = self.ZoneName, Coordinates = self.Polygon } )

  return self
end


--- Smokes the zone boundaries in a color.
-- @param #ZONE_POLYGON_BASE self
-- @param #POINT_VEC3.SmokeColor SmokeColor The smoke color.
-- @return #ZONE_POLYGON_BASE self
function ZONE_POLYGON_BASE:SmokeZone( SmokeColor )
  self:F2( SmokeColor )

  local i 
  local j 
  local Segments = 10
  
  i = 1
  j = #self.Polygon
  
  while i <= #self.Polygon do
    self:T( { i, j, self.Polygon[i], self.Polygon[j] } )
    
    local DeltaX = self.Polygon[j].x - self.Polygon[i].x
    local DeltaY = self.Polygon[j].y - self.Polygon[i].y
    
    for Segment = 0, Segments do -- We divide each line in 5 segments and smoke a point on the line.
      local PointX = self.Polygon[i].x + ( Segment * DeltaX / Segments )
      local PointY = self.Polygon[i].y + ( Segment * DeltaY / Segments )
      POINT_VEC2:New( PointX, PointY ):Smoke( SmokeColor )
    end
    j = i
    i = i + 1
  end

  return self
end




--- Returns if a location is within the zone.
-- @param #ZONE_POLYGON_BASE self
-- @param DCSTypes#Vec2 PointVec2 The location to test.
-- @return #boolean true if the location is within the zone.
function ZONE_POLYGON_BASE:IsPointVec2InZone( PointVec2 )
  self:F2( PointVec2 )

  local i 
  local j 
  local c = false
  
  i = 1
  j = #self.Polygon
  
  while i < #self.Polygon do
    j = i
    i = i + 1
    self:T( { i, j, self.Polygon[i], self.Polygon[j] } )
    if ( ( ( self.Polygon[i].y > PointVec2.y ) ~= ( self.Polygon[j].y > PointVec2.y ) ) and
         ( PointVec2.x < ( self.Polygon[j].x - self.Polygon[i].x ) * ( PointVec2.y - self.Polygon[i].y ) / ( self.Polygon[j].y - self.Polygon[i].y ) + self.Polygon[i].x ) 
       ) then
       c = not c
    end
    self:T2( { "c = ", c } )
  end

  self:T( { "c = ", c } )
  return c
end




--- The ZONE_POLYGON class defined by a sequence of @{Group#GROUP} waypoints within the Mission Editor, forming a polygon.
-- @type ZONE_POLYGON
-- @extends Zone#ZONE_POLYGON_BASE
ZONE_POLYGON = {
  ClassName="ZONE_POLYGON",
  }

--- Constructor to create a ZONE_POLYGON instance, taking the zone name and the name of the @{Group#GROUP} defined within the Mission Editor.
-- The @{Group#GROUP} waypoints define the polygon corners. The first and the last point are automatically connected by ZONE_POLYGON.
-- @param #ZONE_POLYGON self
-- @param #string ZoneName Name of the zone.
-- @param Group#GROUP ZoneGroup The GROUP waypoints as defined within the Mission Editor define the polygon shape.
-- @return #ZONE_POLYGON self
function ZONE_POLYGON:New( ZoneName, ZoneGroup )

  local GroupPoints = ZoneGroup:GetTaskRoute()

  local self = BASE:Inherit( self, ZONE_POLYGON_BASE:New( ZoneName, GroupPoints ) )
  self:F( { ZoneName, ZoneGroup, self.Polygon } )

  return self
end

