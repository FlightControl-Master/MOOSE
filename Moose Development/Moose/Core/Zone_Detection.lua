--- **Core** - The ZONE_DETECTION class, defined by a zone name, a detection object and a radius.
-- @module Core.Zone_Detection
-- @image MOOSE.JPG

--- @type ZONE_DETECTION
-- @field DCS#Vec2 Vec2 The current location of the zone.
-- @field DCS#Distance Radius The radius of the zone.
-- @extends #ZONE_BASE

--- The ZONE_DETECTION class defined by a zone name, a location and a radius.
-- This class implements the inherited functions from Core.Zone#ZONE_BASE taking into account the own zone format and properties.
-- 
-- ## ZONE_DETECTION constructor
-- 
--   * @{#ZONE_DETECTION.New}(): Constructor.
-- 
-- @field #ZONE_DETECTION
ZONE_DETECTION = {
  ClassName="ZONE_DETECTION",
  }

--- Constructor of @{#ZONE_DETECTION}, taking the zone name, the zone location and a radius.
-- @param #ZONE_DETECTION self
-- @param #string ZoneName Name of the zone.
-- @param Functional.Detection#DETECTION_BASE Detection The detection object defining the locations of the central detections.
-- @param DCS#Distance Radius The radius around the detections defining the combined zone.
-- @return #ZONE_DETECTION self
function ZONE_DETECTION:New( ZoneName, Detection, Radius )
  local self = BASE:Inherit( self, ZONE_BASE:New( ZoneName ) ) -- #ZONE_DETECTION
  self:F( { ZoneName, Detection, Radius } )

  self.Detection = Detection
  self.Radius = Radius

  return self
end

--- Bounds the zone with tires.
-- @param #ZONE_DETECTION self
-- @param #number Points (optional) The amount of points in the circle. Default 360.
-- @param DCS#country.id CountryID The country id of the tire objects, e.g. country.id.USA for blue or country.id.RUSSIA for red.
-- @param #boolean UnBound (Optional) If true the tyres will be destroyed.
-- @return #ZONE_DETECTION self
function ZONE_DETECTION:BoundZone( Points, CountryID, UnBound )

  local Point = {}
  local Vec2 = self:GetVec2()

  Points = Points and Points or 360

  local Angle
  local RadialBase = math.pi*2

  for Angle = 0, 360, (360 / Points ) do
    local Radial = Angle * RadialBase / 360
    Point.x = Vec2.x + math.cos( Radial ) * self:GetRadius()
    Point.y = Vec2.y + math.sin( Radial ) * self:GetRadius()

    local CountryName = _DATABASE.COUNTRY_NAME[CountryID]

    local Tire = {
        ["country"] = CountryName, 
        ["category"] = "Fortifications",
        ["canCargo"] = false,
        ["shape_name"] = "H-tyre_B_WF",
        ["type"] = "Black_Tyre_WF",
        --["unitId"] = Angle + 10000,
        ["y"] = Point.y,
        ["x"] = Point.x,
        ["name"] = string.format( "%s-Tire #%0d", self:GetName(), Angle ),
        ["heading"] = 0,
    } -- end of ["group"]

    local Group = coalition.addStaticObject( CountryID, Tire )
    if UnBound and UnBound == true then
      Group:destroy()
    end
  end

  return self
end


--- Smokes the zone boundaries in a color.
-- @param #ZONE_DETECTION self
-- @param Utilities.Utils#SMOKECOLOR SmokeColor The smoke color.
-- @param #number Points (optional) The amount of points in the circle.
-- @param #number AddHeight (optional) The height to be added for the smoke.
-- @param #number AddOffSet (optional) The angle to be added for the smoking start position.
-- @return #ZONE_DETECTION self
function ZONE_DETECTION:SmokeZone( SmokeColor, Points, AddHeight, AngleOffset )
  self:F2( SmokeColor )

  local Point = {}
  local Vec2 = self:GetVec2()
  
  AddHeight = AddHeight or 0
  AngleOffset = AngleOffset or 0

  Points = Points and Points or 360

  local Angle
  local RadialBase = math.pi*2
  
  for Angle = 0, 360, 360 / Points do
    local Radial = ( Angle + AngleOffset ) * RadialBase / 360
    Point.x = Vec2.x + math.cos( Radial ) * self:GetRadius()
    Point.y = Vec2.y + math.sin( Radial ) * self:GetRadius()
    POINT_VEC2:New( Point.x, Point.y, AddHeight ):Smoke( SmokeColor )
  end

  return self
end


--- Flares the zone boundaries in a color.
-- @param #ZONE_DETECTION self
-- @param Utilities.Utils#FLARECOLOR FlareColor The flare color.
-- @param #number Points (optional) The amount of points in the circle.
-- @param DCS#Azimuth Azimuth (optional) Azimuth The azimuth of the flare.
-- @param #number AddHeight (optional) The height to be added for the smoke.
-- @return #ZONE_DETECTION self
function ZONE_DETECTION:FlareZone( FlareColor, Points, Azimuth, AddHeight )
  self:F2( { FlareColor, Azimuth } )

  local Point = {}
  local Vec2 = self:GetVec2()
  
  AddHeight = AddHeight or 0
  
  Points = Points and Points or 360

  local Angle
  local RadialBase = math.pi*2
  
  for Angle = 0, 360, 360 / Points do
    local Radial = Angle * RadialBase / 360
    Point.x = Vec2.x + math.cos( Radial ) * self:GetRadius()
    Point.y = Vec2.y + math.sin( Radial ) * self:GetRadius()
    POINT_VEC2:New( Point.x, Point.y, AddHeight ):Flare( FlareColor, Azimuth )
  end

  return self
end

--- Returns the radius around the detected locations defining the combine zone.
-- @param #ZONE_DETECTION self
-- @return DCS#Distance The radius.
function ZONE_DETECTION:GetRadius()
  self:F2( self.ZoneName )

  self:T2( { self.Radius } )

  return self.Radius
end

--- Sets the radius around the detected locations defining the combine zone.
-- @param #ZONE_DETECTION self
-- @param DCS#Distance Radius The radius.
-- @return #ZONE_DETECTION self
function ZONE_DETECTION:SetRadius( Radius )
  self:F2( self.ZoneName )

  self.Radius = Radius
  self:T2( { self.Radius } )

  return self.Radius
end



--- Returns if a location is within the zone.
-- @param #ZONE_DETECTION self
-- @param DCS#Vec2 Vec2 The location to test.
-- @return #boolean true if the location is within the zone.
function ZONE_DETECTION:IsVec2InZone( Vec2 )
  self:F2( Vec2 )

  local Coordinates = self.Detection:GetDetectedItemCoordinates() -- This returns a list of coordinates that define the (central) locations of the detections.
  
  for CoordinateID, Coordinate in pairs( Coordinates ) do    
    local ZoneVec2 = Coordinate:GetVec2()    
    if ZoneVec2 then
      if (( Vec2.x - ZoneVec2.x )^2 + ( Vec2.y - ZoneVec2.y ) ^2 ) ^ 0.5 <= self:GetRadius() then
        return true
      end
    end
  end
  
  return false
end

--- Returns if a point is within the zone.
-- @param #ZONE_DETECTION self
-- @param DCS#Vec3 Vec3 The point to test.
-- @return #boolean true if the point is within the zone.
function ZONE_DETECTION:IsVec3InZone( Vec3 )
  self:F2( Vec3 )

  local InZone = self:IsVec2InZone( { x = Vec3.x, y = Vec3.z } )

  return InZone
end

