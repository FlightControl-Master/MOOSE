--- This core module contains the ZONE classes, inherited from @{Zone#ZONE_BASE}.
-- 
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
--   * @{Zone#ZONE_UNIT}: The ZONE_UNIT class defines by a zone around a @{Unit#UNIT} with a radius.
--   * @{Zone#ZONE_GROUP}: The ZONE_GROUP class defines by a zone around a @{Group#GROUP} with a radius.
--   * @{Zone#ZONE_POLYGON}: The ZONE_POLYGON class defines by a sequence of @{Group#GROUP} waypoints within the Mission Editor, forming a polygon.
-- 
-- ===
-- 
-- # 1) @{Zone#ZONE_BASE} class, extends @{Base#BASE}
-- 
-- This class is an abstract BASE class for derived classes, and is not meant to be instantiated.
-- 
-- ## 1.1) Each zone has a name:
-- 
--   * @{#ZONE_BASE.GetName}(): Returns the name of the zone.
-- 
-- ## 1.2) Each zone implements two polymorphic functions defined in @{Zone#ZONE_BASE}:
-- 
--   * @{#ZONE_BASE.IsPointVec2InZone}(): Returns if a @{Point#POINT_VEC2} is within the zone.
--   * @{#ZONE_BASE.IsPointVec3InZone}(): Returns if a @{Point#POINT_VEC3} is within the zone.
--   
-- ## 1.3) A zone has a probability factor that can be set to randomize a selection between zones:
-- 
--   * @{#ZONE_BASE.SetRandomizeProbability}(): Set the randomization probability of a zone to be selected, taking a value between 0 and 1 ( 0 = 0%, 1 = 100% )
--   * @{#ZONE_BASE.GetRandomizeProbability}(): Get the randomization probability of a zone to be selected, passing a value between 0 and 1 ( 0 = 0%, 1 = 100% )
--   * @{#ZONE_BASE.GetZoneMaybe}(): Get the zone taking into account the randomization probability. nil is returned if this zone is not a candidate.
-- 
-- ## 1.4) A zone manages Vectors:
-- 
--   * @{#ZONE_BASE.GetVec2}(): Returns the @{DCSTypes#Vec2} coordinate of the zone.
--   * @{#ZONE_BASE.GetRandomVec2}(): Define a random @{DCSTypes#Vec2} within the zone.
-- 
-- ## 1.5) A zone has a bounding square:
-- 
--   * @{#ZONE_BASE.GetBoundingSquare}(): Get the outer most bounding square of the zone.
-- 
-- ## 1.6) A zone can be marked: 
-- 
--   * @{#ZONE_BASE.SmokeZone}(): Smokes the zone boundaries in a color.
--   * @{#ZONE_BASE.FlareZone}(): Flares the zone boundaries in a color.
-- 
-- ===
-- 
-- # 2) @{Zone#ZONE_RADIUS} class, extends @{Zone#ZONE_BASE}
-- 
-- The ZONE_RADIUS class defined by a zone name, a location and a radius.
-- This class implements the inherited functions from Core.Zone#ZONE_BASE taking into account the own zone format and properties.
-- 
-- ## 2.1) @{Zone#ZONE_RADIUS} constructor
-- 
--   * @{#ZONE_RADIUS.New}(): Constructor.
--   
-- ## 2.2) Manage the radius of the zone
-- 
--   * @{#ZONE_RADIUS.SetRadius}(): Sets the radius of the zone.
--   * @{#ZONE_RADIUS.GetRadius}(): Returns the radius of the zone.
-- 
-- ## 2.3) Manage the location of the zone
-- 
--   * @{#ZONE_RADIUS.SetVec2}(): Sets the @{DCSTypes#Vec2} of the zone.
--   * @{#ZONE_RADIUS.GetVec2}(): Returns the @{DCSTypes#Vec2} of the zone.
--   * @{#ZONE_RADIUS.GetVec3}(): Returns the @{DCSTypes#Vec3} of the zone, taking an additional height parameter.
-- 
-- ## 2.4) Zone point randomization
-- 
-- Various functions exist to find random points within the zone.
-- 
--   * @{#ZONE_RADIUS.GetRandomVec2}(): Gets a random 2D point in the zone.
--   * @{#ZONE_RADIUS.GetRandomPointVec2}(): Gets a @{Point#POINT_VEC2} object representing a random 2D point in the zone.
--   * @{#ZONE_RADIUS.GetRandomPointVec3}(): Gets a @{Point#POINT_VEC3} object representing a random 3D point in the zone. Note that the height of the point is at landheight.
-- 
-- ===
-- 
-- # 3) @{Zone#ZONE} class, extends @{Zone#ZONE_RADIUS}
-- 
-- The ZONE class, defined by the zone name as defined within the Mission Editor.
-- This class implements the inherited functions from {Core.Zone#ZONE_RADIUS} taking into account the own zone format and properties.
-- 
-- ===
-- 
-- # 4) @{Zone#ZONE_UNIT} class, extends @{Zone#ZONE_RADIUS}
-- 
-- The ZONE_UNIT class defined by a zone around a @{Unit#UNIT} with a radius.
-- This class implements the inherited functions from @{Zone#ZONE_RADIUS} taking into account the own zone format and properties.
-- 
-- ===
-- 
-- # 5) @{Zone#ZONE_GROUP} class, extends @{Zone#ZONE_RADIUS}
-- 
-- The ZONE_GROUP class defines by a zone around a @{Group#GROUP} with a radius. The current leader of the group defines the center of the zone.
-- This class implements the inherited functions from @{Zone#ZONE_RADIUS} taking into account the own zone format and properties.
-- 
-- ===
-- 
-- # 6) @{Zone#ZONE_POLYGON_BASE} class, extends @{Zone#ZONE_BASE}
-- 
-- The ZONE_POLYGON_BASE class defined by a sequence of @{Group#GROUP} waypoints within the Mission Editor, forming a polygon.
-- This class implements the inherited functions from @{Zone#ZONE_RADIUS} taking into account the own zone format and properties.
-- This class is an abstract BASE class for derived classes, and is not meant to be instantiated.
-- 
-- ## 6.1) Zone point randomization
-- 
-- Various functions exist to find random points within the zone.
-- 
--   * @{#ZONE_POLYGON_BASE.GetRandomVec2}(): Gets a random 2D point in the zone.
--   * @{#ZONE_POLYGON_BASE.GetRandomPointVec2}(): Return a @{Point#POINT_VEC2} object representing a random 2D point within the zone.
--   * @{#ZONE_POLYGON_BASE.GetRandomPointVec3}(): Return a @{Point#POINT_VEC3} object representing a random 3D point at landheight within the zone.
-- 
-- 
-- ===
-- 
-- # 7) @{Zone#ZONE_POLYGON} class, extends @{Zone#ZONE_POLYGON_BASE}
-- 
-- The ZONE_POLYGON class defined by a sequence of @{Group#GROUP} waypoints within the Mission Editor, forming a polygon.
-- This class implements the inherited functions from @{Zone#ZONE_RADIUS} taking into account the own zone format and properties.
-- 
-- ====
-- 
-- **API CHANGE HISTORY**
-- ======================
-- 
-- The underlying change log documents the API changes. Please read this carefully. The following notation is used:
-- 
--   * **Added** parts are expressed in bold type face.
--   * _Removed_ parts are expressed in italic type face.
-- 
-- Hereby the change log:
-- 
-- 2017-02-18: ZONE_POLYGON_BASE:**GetRandomPointVec2()** added.
-- 
-- 2017-02-18: ZONE_POLYGON_BASE:**GetRandomPointVec3()** added.
-- 
-- 2017-02-18: ZONE_RADIUS:**GetRandomPointVec3( inner, outer )** added.
-- 
-- 2017-02-18: ZONE_RADIUS:**GetRandomPointVec2( inner, outer )** added.
-- 
-- 2016-08-15: ZONE_BASE:**GetName()** added.
-- 
-- 2016-08-15: ZONE_BASE:**SetZoneProbability( ZoneProbability )** added.
-- 
-- 2016-08-15: ZONE_BASE:**GetZoneProbability()** added.
-- 
-- 2016-08-15: ZONE_BASE:**GetZoneMaybe()** added.
-- 
-- ===
-- 
-- @module Zone
-- @author FlightControl


--- The ZONE_BASE class
-- @type ZONE_BASE
-- @field #string ZoneName Name of the zone.
-- @field #number ZoneProbability A value between 0 and 1. 0 = 0% and 1 = 100% probability.
-- @extends Core.Base#BASE
ZONE_BASE = {
  ClassName = "ZONE_BASE",
  ZoneName = "",
  ZoneProbability = 1,
  }


--- The ZONE_BASE.BoundingSquare
-- @type ZONE_BASE.BoundingSquare
-- @field Dcs.DCSTypes#Distance x1 The lower x coordinate (left down)
-- @field Dcs.DCSTypes#Distance y1 The lower y coordinate (left down)
-- @field Dcs.DCSTypes#Distance x2 The higher x coordinate (right up)
-- @field Dcs.DCSTypes#Distance y2 The higher y coordinate (right up)


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

--- Returns the name of the zone.
-- @param #ZONE_BASE self
-- @return #string The name of the zone.
function ZONE_BASE:GetName()
  self:F2()

  return self.ZoneName
end
--- Returns if a location is within the zone.
-- @param #ZONE_BASE self
-- @param Dcs.DCSTypes#Vec2 Vec2 The location to test.
-- @return #boolean true if the location is within the zone.
function ZONE_BASE:IsPointVec2InZone( Vec2 )
  self:F2( Vec2 )

  return false
end

--- Returns if a point is within the zone.
-- @param #ZONE_BASE self
-- @param Dcs.DCSTypes#Vec3 Vec3 The point to test.
-- @return #boolean true if the point is within the zone.
function ZONE_BASE:IsPointVec3InZone( Vec3 )
  self:F2( Vec3 )

  local InZone = self:IsPointVec2InZone( { x = Vec3.x, y = Vec3.z } )

  return InZone
end

--- Returns the @{DCSTypes#Vec2} coordinate of the zone.
-- @param #ZONE_BASE self
-- @return #nil.
function ZONE_BASE:GetVec2()
  self:F2( self.ZoneName )

  return nil 
end

--- Define a random @{DCSTypes#Vec2} within the zone.
-- @param #ZONE_BASE self
-- @return Dcs.DCSTypes#Vec2 The Vec2 coordinates.
function ZONE_BASE:GetRandomVec2()
  return nil
end

--- Define a random @{Point#POINT_VEC2} within the zone.
-- @param #ZONE_BASE self
-- @return Core.Point#POINT_VEC2 The PointVec2 coordinates.
function ZONE_BASE:GetRandomPointVec2()
  return nil
end

--- Get the bounding square the zone.
-- @param #ZONE_BASE self
-- @return #nil The bounding square.
function ZONE_BASE:GetBoundingSquare()
  --return { x1 = 0, y1 = 0, x2 = 0, y2 = 0 }
  return nil
end


--- Smokes the zone boundaries in a color.
-- @param #ZONE_BASE self
-- @param Utilities.Utils#SMOKECOLOR SmokeColor The smoke color.
function ZONE_BASE:SmokeZone( SmokeColor )
  self:F2( SmokeColor )

end

--- Set the randomization probability of a zone to be selected.
-- @param #ZONE_BASE self
-- @param ZoneProbability A value between 0 and 1. 0 = 0% and 1 = 100% probability.
function ZONE_BASE:SetZoneProbability( ZoneProbability )
  self:F2( ZoneProbability )
  
  self.ZoneProbability = ZoneProbability or 1
  return self
end

--- Get the randomization probability of a zone to be selected.
-- @param #ZONE_BASE self
-- @return #number A value between 0 and 1. 0 = 0% and 1 = 100% probability.
function ZONE_BASE:GetZoneProbability()
  self:F2()
  
  return self.ZoneProbability
end

--- Get the zone taking into account the randomization probability of a zone to be selected.
-- @param #ZONE_BASE self
-- @return #ZONE_BASE The zone is selected taking into account the randomization probability factor.
-- @return #nil The zone is not selected taking into account the randomization probability factor.
function ZONE_BASE:GetZoneMaybe()
  self:F2()
  
  local Randomization = math.random()
  if Randomization <= self.ZoneProbability then
    return self
  else
    return nil
  end
end


--- The ZONE_RADIUS class, defined by a zone name, a location and a radius.
-- @type ZONE_RADIUS
-- @field Dcs.DCSTypes#Vec2 Vec2 The current location of the zone.
-- @field Dcs.DCSTypes#Distance Radius The radius of the zone.
-- @extends Core.Zone#ZONE_BASE
ZONE_RADIUS = {
	ClassName="ZONE_RADIUS",
	}

--- Constructor of @{#ZONE_RADIUS}, taking the zone name, the zone location and a radius.
-- @param #ZONE_RADIUS self
-- @param #string ZoneName Name of the zone.
-- @param Dcs.DCSTypes#Vec2 Vec2 The location of the zone.
-- @param Dcs.DCSTypes#Distance Radius The radius of the zone.
-- @return #ZONE_RADIUS self
function ZONE_RADIUS:New( ZoneName, Vec2, Radius )
	local self = BASE:Inherit( self, ZONE_BASE:New( ZoneName ) )
	self:F( { ZoneName, Vec2, Radius } )

	self.Radius = Radius
	self.Vec2 = Vec2
	
	return self
end

--- Smokes the zone boundaries in a color.
-- @param #ZONE_RADIUS self
-- @param Utilities.Utils#SMOKECOLOR SmokeColor The smoke color.
-- @param #number Points (optional) The amount of points in the circle.
-- @return #ZONE_RADIUS self
function ZONE_RADIUS:SmokeZone( SmokeColor, Points )
  self:F2( SmokeColor )

  local Point = {}
  local Vec2 = self:GetVec2()

  Points = Points and Points or 360

  local Angle
  local RadialBase = math.pi*2
  
  for Angle = 0, 360, 360 / Points do
    local Radial = Angle * RadialBase / 360
    Point.x = Vec2.x + math.cos( Radial ) * self:GetRadius()
    Point.y = Vec2.y + math.sin( Radial ) * self:GetRadius()
    POINT_VEC2:New( Point.x, Point.y ):Smoke( SmokeColor )
  end

  return self
end


--- Flares the zone boundaries in a color.
-- @param #ZONE_RADIUS self
-- @param Utilities.Utils#FLARECOLOR FlareColor The flare color.
-- @param #number Points (optional) The amount of points in the circle.
-- @param Dcs.DCSTypes#Azimuth Azimuth (optional) Azimuth The azimuth of the flare.
-- @return #ZONE_RADIUS self
function ZONE_RADIUS:FlareZone( FlareColor, Points, Azimuth )
  self:F2( { FlareColor, Azimuth } )

  local Point = {}
  local Vec2 = self:GetVec2()
  
  Points = Points and Points or 360

  local Angle
  local RadialBase = math.pi*2
  
  for Angle = 0, 360, 360 / Points do
    local Radial = Angle * RadialBase / 360
    Point.x = Vec2.x + math.cos( Radial ) * self:GetRadius()
    Point.y = Vec2.y + math.sin( Radial ) * self:GetRadius()
    POINT_VEC2:New( Point.x, Point.y ):Flare( FlareColor, Azimuth )
  end

  return self
end

--- Returns the radius of the zone.
-- @param #ZONE_RADIUS self
-- @return Dcs.DCSTypes#Distance The radius of the zone.
function ZONE_RADIUS:GetRadius()
  self:F2( self.ZoneName )

  self:T2( { self.Radius } )

  return self.Radius
end

--- Sets the radius of the zone.
-- @param #ZONE_RADIUS self
-- @param Dcs.DCSTypes#Distance Radius The radius of the zone.
-- @return Dcs.DCSTypes#Distance The radius of the zone.
function ZONE_RADIUS:SetRadius( Radius )
  self:F2( self.ZoneName )

  self.Radius = Radius
  self:T2( { self.Radius } )

  return self.Radius
end

--- Returns the @{DCSTypes#Vec2} of the zone.
-- @param #ZONE_RADIUS self
-- @return Dcs.DCSTypes#Vec2 The location of the zone.
function ZONE_RADIUS:GetVec2()
	self:F2( self.ZoneName )

	self:T2( { self.Vec2 } )
	
	return self.Vec2	
end

--- Sets the @{DCSTypes#Vec2} of the zone.
-- @param #ZONE_RADIUS self
-- @param Dcs.DCSTypes#Vec2 Vec2 The new location of the zone.
-- @return Dcs.DCSTypes#Vec2 The new location of the zone.
function ZONE_RADIUS:SetVec2( Vec2 )
  self:F2( self.ZoneName )
  
  self.Vec2 = Vec2

  self:T2( { self.Vec2 } )
  
  return self.Vec2 
end

--- Returns the @{DCSTypes#Vec3} of the ZONE_RADIUS.
-- @param #ZONE_RADIUS self
-- @param Dcs.DCSTypes#Distance Height The height to add to the land height where the center of the zone is located.
-- @return Dcs.DCSTypes#Vec3 The point of the zone.
function ZONE_RADIUS:GetVec3( Height )
  self:F2( { self.ZoneName, Height } )

  Height = Height or 0
  local Vec2 = self:GetVec2()

  local Vec3 = { x = Vec2.x, y = land.getHeight( self:GetVec2() ) + Height, z = Vec2.y }

  self:T2( { Vec3 } )
  
  return Vec3  
end


--- Returns if a location is within the zone.
-- @param #ZONE_RADIUS self
-- @param Dcs.DCSTypes#Vec2 Vec2 The location to test.
-- @return #boolean true if the location is within the zone.
function ZONE_RADIUS:IsPointVec2InZone( Vec2 )
  self:F2( Vec2 )
  
  local ZoneVec2 = self:GetVec2()
  
  if ZoneVec2 then
    if (( Vec2.x - ZoneVec2.x )^2 + ( Vec2.y - ZoneVec2.y ) ^2 ) ^ 0.5 <= self:GetRadius() then
      return true
    end
  end
  
  return false
end

--- Returns if a point is within the zone.
-- @param #ZONE_RADIUS self
-- @param Dcs.DCSTypes#Vec3 Vec3 The point to test.
-- @return #boolean true if the point is within the zone.
function ZONE_RADIUS:IsPointVec3InZone( Vec3 )
  self:F2( Vec3 )

  local InZone = self:IsPointVec2InZone( { x = Vec3.x, y = Vec3.z } )

  return InZone
end

--- Returns a random Vec2 location within the zone.
-- @param #ZONE_RADIUS self
-- @param #number inner (optional) Minimal distance from the center of the zone. Default is 0.
-- @param #number outer (optional) Maximal distance from the outer edge of the zone. Default is the radius of the zone.
-- @return Dcs.DCSTypes#Vec2 The random location within the zone.
function ZONE_RADIUS:GetRandomVec2( inner, outer )
	self:F( self.ZoneName, inner, outer )

	local Point = {}
	local Vec2 = self:GetVec2()
	local _inner = inner or 0
	local _outer = outer or self:GetRadius()

	local angle = math.random() * math.pi * 2;
	Point.x = Vec2.x + math.cos( angle ) * math.random(_inner, _outer);
	Point.y = Vec2.y + math.sin( angle ) * math.random(_inner, _outer);
	
	self:T( { Point } )
	
	return Point
end

--- Returns a @{Point#POINT_VEC2} object reflecting a random 2D location within the zone.
-- @param #ZONE_RADIUS self
-- @param #number inner (optional) Minimal distance from the center of the zone. Default is 0.
-- @param #number outer (optional) Maximal distance from the outer edge of the zone. Default is the radius of the zone.
-- @return Core.Point#POINT_VEC2 The @{Point#POINT_VEC2} object reflecting the random 3D location within the zone.
function ZONE_RADIUS:GetRandomPointVec2( inner, outer )
  self:F( self.ZoneName, inner, outer )

  local PointVec2 = POINT_VEC2:NewFromVec2( self:GetRandomVec2() )

  self:T3( { PointVec2 } )
  
  return PointVec2
end

--- Returns a @{Point#POINT_VEC3} object reflecting a random 3D location within the zone.
-- @param #ZONE_RADIUS self
-- @param #number inner (optional) Minimal distance from the center of the zone. Default is 0.
-- @param #number outer (optional) Maximal distance from the outer edge of the zone. Default is the radius of the zone.
-- @return Core.Point#POINT_VEC3 The @{Point#POINT_VEC3} object reflecting the random 3D location within the zone.
function ZONE_RADIUS:GetRandomPointVec3( inner, outer )
  self:F( self.ZoneName, inner, outer )

  local PointVec3 = POINT_VEC3:NewFromVec2( self:GetRandomVec2() )

  self:T3( { PointVec3 } )
  
  return PointVec3
end



--- The ZONE class, defined by the zone name as defined within the Mission Editor. The location and the radius are automatically collected from the mission settings.
-- @type ZONE
-- @extends Core.Zone#ZONE_RADIUS
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
-- @field Wrapper.Unit#UNIT ZoneUNIT
-- @extends Core.Zone#ZONE_RADIUS
ZONE_UNIT = {
  ClassName="ZONE_UNIT",
  }
  
--- Constructor to create a ZONE_UNIT instance, taking the zone name, a zone unit and a radius.
-- @param #ZONE_UNIT self
-- @param #string ZoneName Name of the zone.
-- @param Wrapper.Unit#UNIT ZoneUNIT The unit as the center of the zone.
-- @param Dcs.DCSTypes#Distance Radius The radius of the zone.
-- @return #ZONE_UNIT self
function ZONE_UNIT:New( ZoneName, ZoneUNIT, Radius )
  local self = BASE:Inherit( self, ZONE_RADIUS:New( ZoneName, ZoneUNIT:GetVec2(), Radius ) )
  self:F( { ZoneName, ZoneUNIT:GetVec2(), Radius } )

  self.ZoneUNIT = ZoneUNIT
  self.LastVec2 = ZoneUNIT:GetVec2()
  
  return self
end


--- Returns the current location of the @{Unit#UNIT}.
-- @param #ZONE_UNIT self
-- @return Dcs.DCSTypes#Vec2 The location of the zone based on the @{Unit#UNIT}location.
function ZONE_UNIT:GetVec2()
  self:F( self.ZoneName )
  
  local ZoneVec2 = self.ZoneUNIT:GetVec2()
  if ZoneVec2 then
    self.LastVec2 = ZoneVec2
    return ZoneVec2
  else
    return self.LastVec2
  end

  self:T( { ZoneVec2 } )

  return nil  
end

--- Returns a random location within the zone.
-- @param #ZONE_UNIT self
-- @return Dcs.DCSTypes#Vec2 The random location within the zone.
function ZONE_UNIT:GetRandomVec2()
  self:F( self.ZoneName )

  local RandomVec2 = {}
  local Vec2 = self.ZoneUNIT:GetVec2()
  
  if not Vec2 then
    Vec2 = self.LastVec2
  end

  local angle = math.random() * math.pi*2;
  RandomVec2.x = Vec2.x + math.cos( angle ) * math.random() * self:GetRadius();
  RandomVec2.y = Vec2.y + math.sin( angle ) * math.random() * self:GetRadius();
  
  self:T( { RandomVec2 } )
  
  return RandomVec2
end

--- Returns the @{DCSTypes#Vec3} of the ZONE_UNIT.
-- @param #ZONE_UNIT self
-- @param Dcs.DCSTypes#Distance Height The height to add to the land height where the center of the zone is located.
-- @return Dcs.DCSTypes#Vec3 The point of the zone.
function ZONE_UNIT:GetVec3( Height )
  self:F2( self.ZoneName )
  
  Height = Height or 0
  
  local Vec2 = self:GetVec2()

  local Vec3 = { x = Vec2.x, y = land.getHeight( self:GetVec2() ) + Height, z = Vec2.y }

  self:T2( { Vec3 } )
  
  return Vec3  
end

--- The ZONE_GROUP class defined by a zone around a @{Group}, taking the average center point of all the units within the Group, with a radius.
-- @type ZONE_GROUP
-- @field Wrapper.Group#GROUP ZoneGROUP
-- @extends Core.Zone#ZONE_RADIUS
ZONE_GROUP = {
  ClassName="ZONE_GROUP",
  }
  
--- Constructor to create a ZONE_GROUP instance, taking the zone name, a zone @{Group#GROUP} and a radius.
-- @param #ZONE_GROUP self
-- @param #string ZoneName Name of the zone.
-- @param Wrapper.Group#GROUP ZoneGROUP The @{Group} as the center of the zone.
-- @param Dcs.DCSTypes#Distance Radius The radius of the zone.
-- @return #ZONE_GROUP self
function ZONE_GROUP:New( ZoneName, ZoneGROUP, Radius )
  local self = BASE:Inherit( self, ZONE_RADIUS:New( ZoneName, ZoneGROUP:GetVec2(), Radius ) )
  self:F( { ZoneName, ZoneGROUP:GetVec2(), Radius } )

  self.ZoneGROUP = ZoneGROUP
  
  return self
end


--- Returns the current location of the @{Group}.
-- @param #ZONE_GROUP self
-- @return Dcs.DCSTypes#Vec2 The location of the zone based on the @{Group} location.
function ZONE_GROUP:GetVec2()
  self:F( self.ZoneName )
  
  local ZoneVec2 = self.ZoneGROUP:GetVec2()

  self:T( { ZoneVec2 } )
  
  return ZoneVec2
end

--- Returns a random location within the zone of the @{Group}.
-- @param #ZONE_GROUP self
-- @return Dcs.DCSTypes#Vec2 The random location of the zone based on the @{Group} location.
function ZONE_GROUP:GetRandomVec2()
  self:F( self.ZoneName )

  local Point = {}
  local Vec2 = self.ZoneGROUP:GetVec2()

  local angle = math.random() * math.pi*2;
  Point.x = Vec2.x + math.cos( angle ) * math.random() * self:GetRadius();
  Point.y = Vec2.y + math.sin( angle ) * math.random() * self:GetRadius();
  
  self:T( { Point } )
  
  return Point
end



-- Polygons

--- The ZONE_POLYGON_BASE class defined by an array of @{DCSTypes#Vec2}, forming a polygon.
-- @type ZONE_POLYGON_BASE
-- @field #ZONE_POLYGON_BASE.ListVec2 Polygon The polygon defined by an array of @{DCSTypes#Vec2}.
-- @extends Core.Zone#ZONE_BASE
ZONE_POLYGON_BASE = {
  ClassName="ZONE_POLYGON_BASE",
  }

--- A points array.
-- @type ZONE_POLYGON_BASE.ListVec2
-- @list <Dcs.DCSTypes#Vec2>

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
-- @param Utilities.Utils#SMOKECOLOR SmokeColor The smoke color.
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
-- Source learned and taken from: https://www.ecse.rpi.edu/Homepages/wrf/Research/Short_Notes/pnpoly.html
-- @param #ZONE_POLYGON_BASE self
-- @param Dcs.DCSTypes#Vec2 Vec2 The location to test.
-- @return #boolean true if the location is within the zone.
function ZONE_POLYGON_BASE:IsPointVec2InZone( Vec2 )
  self:F2( Vec2 )

  local Next 
  local Prev 
  local InPolygon = false
  
  Next = 1
  Prev = #self.Polygon
  
  while Next <= #self.Polygon do
    self:T( { Next, Prev, self.Polygon[Next], self.Polygon[Prev] } )
    if ( ( ( self.Polygon[Next].y > Vec2.y ) ~= ( self.Polygon[Prev].y > Vec2.y ) ) and
         ( Vec2.x < ( self.Polygon[Prev].x - self.Polygon[Next].x ) * ( Vec2.y - self.Polygon[Next].y ) / ( self.Polygon[Prev].y - self.Polygon[Next].y ) + self.Polygon[Next].x ) 
       ) then
       InPolygon = not InPolygon
    end
    self:T2( { InPolygon = InPolygon } )
    Prev = Next
    Next = Next + 1
  end

  self:T( { InPolygon = InPolygon } )
  return InPolygon
end

--- Define a random @{DCSTypes#Vec2} within the zone.
-- @param #ZONE_POLYGON_BASE self
-- @return Dcs.DCSTypes#Vec2 The Vec2 coordinate.
function ZONE_POLYGON_BASE:GetRandomVec2()
  self:F2()

  --- It is a bit tricky to find a random point within a polygon. Right now i am doing it the dirty and inefficient way...
  local Vec2Found = false
  local Vec2
  local BS = self:GetBoundingSquare()
  
  self:T2( BS )
  
  while Vec2Found == false do
    Vec2 = { x = math.random( BS.x1, BS.x2 ), y = math.random( BS.y1, BS.y2 ) }
    self:T2( Vec2 )
    if self:IsPointVec2InZone( Vec2 ) then
      Vec2Found = true
    end
  end
  
  self:T2( Vec2 )

  return Vec2
end

--- Return a @{Point#POINT_VEC2} object representing a random 2D point at landheight within the zone.
-- @param #ZONE_POLYGON_BASE self
-- @return @{Point#POINT_VEC2}
function ZONE_POLYGON_BASE:GetRandomPointVec2()
  self:F2()

  local PointVec2 = POINT_VEC2:NewFromVec2( self:GetRandomVec2() )
  
  self:T2( PointVec2 )

  return PointVec2
end

--- Return a @{Point#POINT_VEC3} object representing a random 3D point at landheight within the zone.
-- @param #ZONE_POLYGON_BASE self
-- @return @{Point#POINT_VEC3}
function ZONE_POLYGON_BASE:GetRandomPointVec3()
  self:F2()

  local PointVec3 = POINT_VEC3:NewFromVec2( self:GetRandomVec2() )
  
  self:T2( PointVec3 )

  return PointVec3
end


--- Get the bounding square the zone.
-- @param #ZONE_POLYGON_BASE self
-- @return #ZONE_POLYGON_BASE.BoundingSquare The bounding square.
function ZONE_POLYGON_BASE:GetBoundingSquare()

  local x1 = self.Polygon[1].x
  local y1 = self.Polygon[1].y
  local x2 = self.Polygon[1].x
  local y2 = self.Polygon[1].y
  
  for i = 2, #self.Polygon do
    self:T2( { self.Polygon[i], x1, y1, x2, y2 } )
    x1 = ( x1 > self.Polygon[i].x ) and self.Polygon[i].x or x1
    x2 = ( x2 < self.Polygon[i].x ) and self.Polygon[i].x or x2
    y1 = ( y1 > self.Polygon[i].y ) and self.Polygon[i].y or y1
    y2 = ( y2 < self.Polygon[i].y ) and self.Polygon[i].y or y2
    
  end

  return { x1 = x1, y1 = y1, x2 = x2, y2 = y2 }
end





--- The ZONE_POLYGON class defined by a sequence of @{Group#GROUP} waypoints within the Mission Editor, forming a polygon.
-- @type ZONE_POLYGON
-- @extends Core.Zone#ZONE_POLYGON_BASE
ZONE_POLYGON = {
  ClassName="ZONE_POLYGON",
  }

--- Constructor to create a ZONE_POLYGON instance, taking the zone name and the name of the @{Group#GROUP} defined within the Mission Editor.
-- The @{Group#GROUP} waypoints define the polygon corners. The first and the last point are automatically connected by ZONE_POLYGON.
-- @param #ZONE_POLYGON self
-- @param #string ZoneName Name of the zone.
-- @param Wrapper.Group#GROUP ZoneGroup The GROUP waypoints as defined within the Mission Editor define the polygon shape.
-- @return #ZONE_POLYGON self
function ZONE_POLYGON:New( ZoneName, ZoneGroup )

  local GroupPoints = ZoneGroup:GetTaskRoute()

  local self = BASE:Inherit( self, ZONE_POLYGON_BASE:New( ZoneName, GroupPoints ) )
  self:F( { ZoneName, ZoneGroup, self.Polygon } )

  return self
end

