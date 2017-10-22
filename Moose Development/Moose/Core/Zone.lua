--- **Core** -- ZONE classes define **zones** within your mission of **various forms**, with **various capabilities**.
-- 
-- ![Banner Image](..\Presentations\ZONE\Dia1.JPG)
-- 
-- ====
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
--   * @{#ZONE_BASE}: The ZONE_BASE class defining the base for all other zone classes.
--   * @{#ZONE_RADIUS}: The ZONE_RADIUS class defined by a zone name, a location and a radius.
--   * @{#ZONE}: The ZONE class, defined by the zone name as defined within the Mission Editor.
--   * @{#ZONE_UNIT}: The ZONE_UNIT class defines by a zone around a @{Unit#UNIT} with a radius.
--   * @{#ZONE_GROUP}: The ZONE_GROUP class defines by a zone around a @{Group#GROUP} with a radius.
--   * @{#ZONE_POLYGON}: The ZONE_POLYGON class defines by a sequence of @{Group#GROUP} waypoints within the Mission Editor, forming a polygon.
--
-- ==== 
-- 
-- ### Author: **Sven Van de Velde (FlightControl)**
-- ### Contributions: 
-- 
-- ====
-- 
-- @module Zone


--- @type ZONE_BASE
-- @field #string ZoneName Name of the zone.
-- @field #number ZoneProbability A value between 0 and 1. 0 = 0% and 1 = 100% probability.
-- @extends Core.Base#BASE


--- # ZONE_BASE class, extends @{Base#BASE}
-- 
-- This class is an abstract BASE class for derived classes, and is not meant to be instantiated.
-- 
-- ## Each zone has a name:
-- 
--   * @{#ZONE_BASE.GetName}(): Returns the name of the zone.
--   * @{#ZONE_BASE.SetName}(): Sets the name of the zone.
--   
-- 
-- ## Each zone implements two polymorphic functions defined in @{Zone#ZONE_BASE}:
-- 
--   * @{#ZONE_BASE.IsVec2InZone}(): Returns if a 2D vector is within the zone.
--   * @{#ZONE_BASE.IsVec3InZone}(): Returns if a 3D vector is within the zone.
--   * @{#ZONE_BASE.IsPointVec2InZone}(): Returns if a 2D point vector is within the zone.
--   * @{#ZONE_BASE.IsPointVec3InZone}(): Returns if a 3D point vector is within the zone.
--   
-- ## A zone has a probability factor that can be set to randomize a selection between zones:
-- 
--   * @{#ZONE_BASE.SetZoneProbability}(): Set the randomization probability of a zone to be selected, taking a value between 0 and 1 ( 0 = 0%, 1 = 100% )
--   * @{#ZONE_BASE.GetZoneProbability}(): Get the randomization probability of a zone to be selected, passing a value between 0 and 1 ( 0 = 0%, 1 = 100% )
--   * @{#ZONE_BASE.GetZoneMaybe}(): Get the zone taking into account the randomization probability. nil is returned if this zone is not a candidate.
-- 
-- ## A zone manages vectors:
-- 
--   * @{#ZONE_BASE.GetVec2}(): Returns the 2D vector coordinate of the zone.
--   * @{#ZONE_BASE.GetVec3}(): Returns the 3D vector coordinate of the zone.
--   * @{#ZONE_BASE.GetPointVec2}(): Returns the 2D point vector coordinate of the zone.
--   * @{#ZONE_BASE.GetPointVec3}(): Returns the 3D point vector coordinate of the zone.
--   * @{#ZONE_BASE.GetRandomVec2}(): Define a random 2D vector within the zone.
--   * @{#ZONE_BASE.GetRandomPointVec2}(): Define a random 2D point vector within the zone.
--   * @{#ZONE_BASE.GetRandomPointVec3}(): Define a random 3D point vector within the zone.
-- 
-- ## A zone has a bounding square:
-- 
--   * @{#ZONE_BASE.GetBoundingSquare}(): Get the outer most bounding square of the zone.
-- 
-- ## A zone can be marked: 
-- 
--   * @{#ZONE_BASE.SmokeZone}(): Smokes the zone boundaries in a color.
--   * @{#ZONE_BASE.FlareZone}(): Flares the zone boundaries in a color.
-- 
-- @field #ZONE_BASE
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


--- Sets the name of the zone.
-- @param #ZONE_BASE self
-- @param #string ZoneName The name of the zone.
-- @return #ZONE_BASE
function ZONE_BASE:SetName( ZoneName )
  self:F2()

  self.ZoneName = ZoneName
end

--- Returns if a Vec2 is within the zone.
-- @param #ZONE_BASE self
-- @param Dcs.DCSTypes#Vec2 Vec2 The Vec2 to test.
-- @return #boolean true if the Vec2 is within the zone.
function ZONE_BASE:IsVec2InZone( Vec2 )
  self:F2( Vec2 )

  return false
end

--- Returns if a Vec3 is within the zone.
-- @param #ZONE_BASE self
-- @param Dcs.DCSTypes#Vec3 Vec3 The point to test.
-- @return #boolean true if the Vec3 is within the zone.
function ZONE_BASE:IsVec3InZone( Vec3 )
  self:F2( Vec3 )

  local InZone = self:IsVec2InZone( { x = Vec3.x, y = Vec3.z } )

  return InZone
end

--- Returns if a PointVec2 is within the zone.
-- @param #ZONE_BASE self
-- @param Core.Point#POINT_VEC2 PointVec2 The PointVec2 to test.
-- @return #boolean true if the PointVec2 is within the zone.
function ZONE_BASE:IsPointVec2InZone( PointVec2 )
  self:F2( PointVec2 )
  
  local InZone = self:IsVec2InZone( PointVec2:GetVec2() )

  return InZone
end

--- Returns if a PointVec3 is within the zone.
-- @param #ZONE_BASE self
-- @param Core.Point#POINT_VEC3 PointVec3 The PointVec3 to test.
-- @return #boolean true if the PointVec3 is within the zone.
function ZONE_BASE:IsPointVec3InZone( PointVec3 )
  self:F2( PointVec3 )

  local InZone = self:IsPointVec2InZone( PointVec3 )

  return InZone
end


--- Returns the @{DCSTypes#Vec2} coordinate of the zone.
-- @param #ZONE_BASE self
-- @return #nil.
function ZONE_BASE:GetVec2()
  self:F2( self.ZoneName )

  return nil 
end

--- Returns a @{Point#POINT_VEC2} of the zone.
-- @param #ZONE_BASE self
-- @param Dcs.DCSTypes#Distance Height The height to add to the land height where the center of the zone is located.
-- @return Core.Point#POINT_VEC2 The PointVec2 of the zone.
function ZONE_BASE:GetPointVec2()
  self:F2( self.ZoneName )
  
  local Vec2 = self:GetVec2()

  local PointVec2 = POINT_VEC2:NewFromVec2( Vec2 )

  self:T2( { PointVec2 } )
  
  return PointVec2  
end


--- Returns a @{Point#COORDINATE} of the zone.
-- @param #ZONE_BASE self
-- @return Core.Point#COORDINATE The Coordinate of the zone.
function ZONE_BASE:GetCoordinate()
  self:F2( self.ZoneName )
  
  local Vec2 = self:GetVec2()

  local Coordinate = COORDINATE:NewFromVec2( Vec2 )

  self:T2( { Coordinate } )
  
  return Coordinate  
end


--- Returns the @{DCSTypes#Vec3} of the zone.
-- @param #ZONE_BASE self
-- @param Dcs.DCSTypes#Distance Height The height to add to the land height where the center of the zone is located.
-- @return Dcs.DCSTypes#Vec3 The Vec3 of the zone.
function ZONE_BASE:GetVec3( Height )
  self:F2( self.ZoneName )
  
  Height = Height or 0
  
  local Vec2 = self:GetVec2()

  local Vec3 = { x = Vec2.x, y = Height and Height or land.getHeight( self:GetVec2() ), z = Vec2.y }

  self:T2( { Vec3 } )
  
  return Vec3  
end

--- Returns a @{Point#POINT_VEC3} of the zone.
-- @param #ZONE_BASE self
-- @param Dcs.DCSTypes#Distance Height The height to add to the land height where the center of the zone is located.
-- @return Core.Point#POINT_VEC3 The PointVec3 of the zone.
function ZONE_BASE:GetPointVec3( Height )
  self:F2( self.ZoneName )
  
  local Vec3 = self:GetVec3( Height )

  local PointVec3 = POINT_VEC3:NewFromVec3( Vec3 )

  self:T2( { PointVec3 } )
  
  return PointVec3  
end

--- Returns a @{Point#COORDINATE} of the zone.
-- @param #ZONE_BASE self
-- @param Dcs.DCSTypes#Distance Height The height to add to the land height where the center of the zone is located.
-- @return Core.Point#COORDINATE The Coordinate of the zone.
function ZONE_BASE:GetCoordinate( Height ) --R2.1
  self:F2( self.ZoneName )
  
  local Vec3 = self:GetVec3( Height )

  local PointVec3 = COORDINATE:NewFromVec3( Vec3 )

  self:T2( { PointVec3 } )
  
  return PointVec3  
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

--- Define a random @{Point#POINT_VEC3} within the zone.
-- @param #ZONE_BASE self
-- @return Core.Point#POINT_VEC3 The PointVec3 coordinates.
function ZONE_BASE:GetRandomPointVec3()
  return nil
end

--- Get the bounding square the zone.
-- @param #ZONE_BASE self
-- @return #nil The bounding square.
function ZONE_BASE:GetBoundingSquare()
  --return { x1 = 0, y1 = 0, x2 = 0, y2 = 0 }
  return nil
end

--- Bound the zone boundaries with a tires.
-- @param #ZONE_BASE self
function ZONE_BASE:BoundZone()
  self:F2()

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
-- @extends #ZONE_BASE

--- # ZONE_RADIUS class, extends @{Zone#ZONE_BASE}
-- 
-- The ZONE_RADIUS class defined by a zone name, a location and a radius.
-- This class implements the inherited functions from Core.Zone#ZONE_BASE taking into account the own zone format and properties.
-- 
-- ## ZONE_RADIUS constructor
-- 
--   * @{#ZONE_RADIUS.New}(): Constructor.
--   
-- ## Manage the radius of the zone
-- 
--   * @{#ZONE_RADIUS.SetRadius}(): Sets the radius of the zone.
--   * @{#ZONE_RADIUS.GetRadius}(): Returns the radius of the zone.
-- 
-- ## Manage the location of the zone
-- 
--   * @{#ZONE_RADIUS.SetVec2}(): Sets the @{DCSTypes#Vec2} of the zone.
--   * @{#ZONE_RADIUS.GetVec2}(): Returns the @{DCSTypes#Vec2} of the zone.
--   * @{#ZONE_RADIUS.GetVec3}(): Returns the @{DCSTypes#Vec3} of the zone, taking an additional height parameter.
-- 
-- ## Zone point randomization
-- 
-- Various functions exist to find random points within the zone.
-- 
--   * @{#ZONE_RADIUS.GetRandomVec2}(): Gets a random 2D point in the zone.
--   * @{#ZONE_RADIUS.GetRandomPointVec2}(): Gets a @{Point#POINT_VEC2} object representing a random 2D point in the zone.
--   * @{#ZONE_RADIUS.GetRandomPointVec3}(): Gets a @{Point#POINT_VEC3} object representing a random 3D point in the zone. Note that the height of the point is at landheight.
-- 
-- @field #ZONE_RADIUS
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
	local self = BASE:Inherit( self, ZONE_BASE:New( ZoneName ) ) -- #ZONE_RADIUS
	self:F( { ZoneName, Vec2, Radius } )

	self.Radius = Radius
	self.Vec2 = Vec2
	
	return self
end

--- Bounds the zone with tires.
-- @param #ZONE_RADIUS self
-- @param #number Points (optional) The amount of points in the circle.
-- @param #boolean UnBound If true the tyres will be destroyed.
-- @return #ZONE_RADIUS self
function ZONE_RADIUS:BoundZone( Points, CountryID, UnBound )

  local Point = {}
  local Vec2 = self:GetVec2()

  Points = Points and Points or 360

  local Angle
  local RadialBase = math.pi*2
  
  --
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
-- @param #ZONE_RADIUS self
-- @param Utilities.Utils#SMOKECOLOR SmokeColor The smoke color.
-- @param #number Points (optional) The amount of points in the circle.
-- @param #number AddHeight (optional) The height to be added for the smoke.
-- @param #number AddOffSet (optional) The angle to be added for the smoking start position.
-- @return #ZONE_RADIUS self
function ZONE_RADIUS:SmokeZone( SmokeColor, Points, AddHeight, AngleOffset )
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
-- @param #ZONE_RADIUS self
-- @param Utilities.Utils#FLARECOLOR FlareColor The flare color.
-- @param #number Points (optional) The amount of points in the circle.
-- @param Dcs.DCSTypes#Azimuth Azimuth (optional) Azimuth The azimuth of the flare.
-- @param #number AddHeight (optional) The height to be added for the smoke.
-- @return #ZONE_RADIUS self
function ZONE_RADIUS:FlareZone( FlareColor, Points, Azimuth, AddHeight )
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


--- Scan the zone
-- @param #ZONE_RADIUS self
-- @param ObjectCategories
-- @param Coalition
function ZONE_RADIUS:Scan( ObjectCategories )

  self.ScanData = {}
  self.ScanData.Coalitions = {}
  self.ScanData.Scenery = {}

  local ZoneCoord = self:GetCoordinate()
  local ZoneRadius = self:GetRadius()
  
  self:E({ZoneCoord = ZoneCoord, ZoneRadius = ZoneRadius, ZoneCoordLL = ZoneCoord:ToStringLLDMS()})

  local SphereSearch = {
    id = world.VolumeType.SPHERE,
      params = {
      point = ZoneCoord:GetVec3(),
      radius = ZoneRadius,
      }
    }

  local function EvaluateZone( ZoneObject )
    if ZoneObject:isExist() then
      local ObjectCategory = ZoneObject:getCategory()
      if ( ObjectCategory == Object.Category.UNIT and ZoneObject:isActive() ) or 
         ObjectCategory == Object.Category.STATIC then
        local CoalitionDCSUnit = ZoneObject:getCoalition()
        self.ScanData.Coalitions[CoalitionDCSUnit] = true
        self:E( { Name = ZoneObject:getName(), Coalition = CoalitionDCSUnit } )
      end
      if ObjectCategory == Object.Category.SCENERY then
        local SceneryType = ZoneObject:getTypeName()
        local SceneryName = ZoneObject:getName()
        self.ScanData.Scenery[SceneryType] = self.ScanData.Scenery[SceneryType] or {}
        self.ScanData.Scenery[SceneryType][SceneryName] = SCENERY:Register( SceneryName, ZoneObject )
        self:E( { SCENERY =  self.ScanData.Scenery[SceneryType][SceneryName] } )
      end
    end
    return true
  end

  world.searchObjects( ObjectCategories, SphereSearch, EvaluateZone )
  
end


function ZONE_RADIUS:CountScannedCoalitions()

  local Count = 0
  
  for CoalitionID, Coalition in pairs( self.ScanData.Coalitions ) do
    Count = Count + 1
  end
  return Count
end


--- Get Coalitions of the units in the Zone, or Check if there are units of the given Coalition in the Zone.
-- Returns nil if there are none ot two Coalitions in the zone!
-- Returns one Coalition if there are only Units of one Coalition in the Zone.
-- Returns the Coalition for the given Coalition if there are units of the Coalition in the Zone
-- @param #ZONE_RADIUS self
-- @return #table
function ZONE_RADIUS:GetScannedCoalition( Coalition )

  if Coalition then
    return self.ScanData.Coalitions[Coalition]
  else
    local Count = 0
    local ReturnCoalition = nil
    
    for CoalitionID, Coalition in pairs( self.ScanData.Coalitions ) do
      Count = Count + 1
      ReturnCoalition = CoalitionID
    end
    
    if Count ~= 1 then
      ReturnCoalition = nil
    end
    
    return ReturnCoalition
  end
end


function ZONE_RADIUS:GetScannedSceneryType( SceneryType )
  return self.ScanData.Scenery[SceneryType]
end


function ZONE_RADIUS:GetScannedScenery()
  return self.ScanData.Scenery
end


--- Is All in Zone of Coalition?
-- @param #ZONE_RADIUS self
-- @param Coalition
-- @return #boolean
function ZONE_RADIUS:IsAllInZoneOfCoalition( Coalition )

  return self:CountScannedCoalitions() == 1 and self:GetScannedCoalition( Coalition ) == true
end


--- Is All in Zone of Other Coalition?
-- @param #ZONE_RADIUS self
-- @param Coalition
-- @return #boolean
function ZONE_RADIUS:IsAllInZoneOfOtherCoalition( Coalition )

  self:E( { Coalitions = self.Coalitions, Count = self:CountScannedCoalitions() } )
  return self:CountScannedCoalitions() == 1 and self:GetScannedCoalition( Coalition ) == nil
end


--- Is Some in Zone of Coalition?
-- @param #ZONE_RADIUS self
-- @param Coalition
-- @return #boolean
function ZONE_RADIUS:IsSomeInZoneOfCoalition( Coalition )

  return self:CountScannedCoalitions() > 1 and self:GetScannedCoalition( Coalition ) == true
end


--- Is None in Zone of Coalition?
-- @param #ZONE_RADIUS self
-- @param Coalition
-- @return #boolean
function ZONE_RADIUS:IsNoneInZoneOfCoalition( Coalition )

  return self:GetScannedCoalition( Coalition ) == nil
end


--- Is None in Zone?
-- @param #ZONE_RADIUS self
-- @return #boolean
function ZONE_RADIUS:IsNoneInZone()

  return self:CountScannedCoalitions() == 0
end




--- Searches the zone
-- @param #ZONE_RADIUS self
-- @param ObjectCategories A list of categories, which are members of Object.Category
-- @param EvaluateFunction
function ZONE_RADIUS:SearchZone( EvaluateFunction, ObjectCategories )

  local SearchZoneResult = true

  local ZoneCoord = self:GetCoordinate()
  local ZoneRadius = self:GetRadius()
  
  self:E({ZoneCoord = ZoneCoord, ZoneRadius = ZoneRadius, ZoneCoordLL = ZoneCoord:ToStringLLDMS()})

  local SphereSearch = {
    id = world.VolumeType.SPHERE,
      params = {
      point = ZoneCoord:GetVec3(),
      radius = ZoneRadius / 2,
      }
    }

  local function EvaluateZone( ZoneDCSUnit )
  
    env.info( ZoneDCSUnit:getName() ) 
  
    local ZoneUnit = UNIT:Find( ZoneDCSUnit )

    return EvaluateFunction( ZoneUnit )
  end

  world.searchObjects( Object.Category.UNIT, SphereSearch, EvaluateZone )

end

--- Returns if a location is within the zone.
-- @param #ZONE_RADIUS self
-- @param Dcs.DCSTypes#Vec2 Vec2 The location to test.
-- @return #boolean true if the location is within the zone.
function ZONE_RADIUS:IsVec2InZone( Vec2 )
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
function ZONE_RADIUS:IsVec3InZone( Vec3 )
  self:F2( Vec3 )

  local InZone = self:IsVec2InZone( { x = Vec3.x, y = Vec3.z } )

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


--- Returns a @{Point#COORDINATE} object reflecting a random 3D location within the zone.
-- @param #ZONE_RADIUS self
-- @param #number inner (optional) Minimal distance from the center of the zone. Default is 0.
-- @param #number outer (optional) Maximal distance from the outer edge of the zone. Default is the radius of the zone.
-- @return Core.Point#COORDINATE
function ZONE_RADIUS:GetRandomCoordinate( inner, outer )
  self:F( self.ZoneName, inner, outer )

  local Coordinate = COORDINATE:NewFromVec2( self:GetRandomVec2() )

  self:T3( { Coordinate = Coordinate } )
  
  return Coordinate
end



--- @type ZONE
-- @extends #ZONE_RADIUS


--- # ZONE class, extends @{Zone#ZONE_RADIUS}
-- 
-- The ZONE class, defined by the zone name as defined within the Mission Editor.
-- This class implements the inherited functions from @{#ZONE_RADIUS} taking into account the own zone format and properties.
-- 
-- @field #ZONE 
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


--- @type ZONE_UNIT
-- @field Wrapper.Unit#UNIT ZoneUNIT
-- @extends Core.Zone#ZONE_RADIUS

--- # ZONE_UNIT class, extends @{Zone#ZONE_RADIUS}
-- 
-- The ZONE_UNIT class defined by a zone around a @{Unit#UNIT} with a radius.
-- This class implements the inherited functions from @{#ZONE_RADIUS} taking into account the own zone format and properties.
-- 
-- @field #ZONE_UNIT
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
  self:F2( self.ZoneName )
  
  local ZoneVec2 = self.ZoneUNIT:GetVec2()
  if ZoneVec2 then
    self.LastVec2 = ZoneVec2
    return ZoneVec2
  else
    return self.LastVec2
  end

  self:T2( { ZoneVec2 } )

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

--- @type ZONE_GROUP
-- @extends #ZONE_RADIUS


--- # ZONE_GROUP class, extends @{Zone#ZONE_RADIUS}
-- 
-- The ZONE_GROUP class defines by a zone around a @{Group#GROUP} with a radius. The current leader of the group defines the center of the zone.
-- This class implements the inherited functions from @{Zone#ZONE_RADIUS} taking into account the own zone format and properties.
-- 
-- @field #ZONE_GROUP
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

  self._.ZoneGROUP = ZoneGROUP
  
  return self
end


--- Returns the current location of the @{Group}.
-- @param #ZONE_GROUP self
-- @return Dcs.DCSTypes#Vec2 The location of the zone based on the @{Group} location.
function ZONE_GROUP:GetVec2()
  self:F( self.ZoneName )
  
  local ZoneVec2 = self._.ZoneGROUP:GetVec2()

  self:T( { ZoneVec2 } )
  
  return ZoneVec2
end

--- Returns a random location within the zone of the @{Group}.
-- @param #ZONE_GROUP self
-- @return Dcs.DCSTypes#Vec2 The random location of the zone based on the @{Group} location.
function ZONE_GROUP:GetRandomVec2()
  self:F( self.ZoneName )

  local Point = {}
  local Vec2 = self._.ZoneGROUP:GetVec2()

  local angle = math.random() * math.pi*2;
  Point.x = Vec2.x + math.cos( angle ) * math.random() * self:GetRadius();
  Point.y = Vec2.y + math.sin( angle ) * math.random() * self:GetRadius();
  
  self:T( { Point } )
  
  return Point
end

--- Returns a @{Point#POINT_VEC2} object reflecting a random 2D location within the zone.
-- @param #ZONE_GROUP self
-- @param #number inner (optional) Minimal distance from the center of the zone. Default is 0.
-- @param #number outer (optional) Maximal distance from the outer edge of the zone. Default is the radius of the zone.
-- @return Core.Point#POINT_VEC2 The @{Point#POINT_VEC2} object reflecting the random 3D location within the zone.
function ZONE_GROUP:GetRandomPointVec2( inner, outer )
  self:F( self.ZoneName, inner, outer )

  local PointVec2 = POINT_VEC2:NewFromVec2( self:GetRandomVec2() )

  self:T3( { PointVec2 } )
  
  return PointVec2
end


--- @type ZONE_POLYGON_BASE
-- --@field #ZONE_POLYGON_BASE.ListVec2 Polygon The polygon defined by an array of @{DCSTypes#Vec2}.
-- @extends #ZONE_BASE


--- # ZONE_POLYGON_BASE class, extends @{Zone#ZONE_BASE}
-- 
-- The ZONE_POLYGON_BASE class defined by a sequence of @{Group#GROUP} waypoints within the Mission Editor, forming a polygon.
-- This class implements the inherited functions from @{Zone#ZONE_RADIUS} taking into account the own zone format and properties.
-- This class is an abstract BASE class for derived classes, and is not meant to be instantiated.
-- 
-- ## Zone point randomization
-- 
-- Various functions exist to find random points within the zone.
-- 
--   * @{#ZONE_POLYGON_BASE.GetRandomVec2}(): Gets a random 2D point in the zone.
--   * @{#ZONE_POLYGON_BASE.GetRandomPointVec2}(): Return a @{Point#POINT_VEC2} object representing a random 2D point within the zone.
--   * @{#ZONE_POLYGON_BASE.GetRandomPointVec3}(): Return a @{Point#POINT_VEC3} object representing a random 3D point at landheight within the zone.
-- 
-- @field #ZONE_POLYGON_BASE
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
  
  self._.Polygon = {}
  
  for i = 1, #PointsArray do
    self._.Polygon[i] = {}
    self._.Polygon[i].x = PointsArray[i].x
    self._.Polygon[i].y = PointsArray[i].y
  end

  return self
end

--- Returns the center location of the polygon.
-- @param #ZONE_GROUP self
-- @return Dcs.DCSTypes#Vec2 The location of the zone based on the @{Group} location.
function ZONE_POLYGON_BASE:GetVec2()
  self:F( self.ZoneName )

  local Bounds = self:GetBoundingSquare()
  
  return { x = ( Bounds.x2 + Bounds.x1 ) / 2, y = ( Bounds.y2 + Bounds.y1 ) / 2 }  
end

--- Flush polygon coordinates as a table in DCS.log.
-- @param #ZONE_POLYGON_BASE self
-- @return #ZONE_POLYGON_BASE self
function ZONE_POLYGON_BASE:Flush()
  self:F2()

  self:E( { Polygon = self.ZoneName, Coordinates = self._.Polygon } )

  return self
end

--- Smokes the zone boundaries in a color.
-- @param #ZONE_POLYGON_BASE self
-- @param #boolean UnBound If true, the tyres will be destroyed.
-- @return #ZONE_POLYGON_BASE self
function ZONE_POLYGON_BASE:BoundZone( UnBound )

  local i 
  local j 
  local Segments = 10
  
  i = 1
  j = #self._.Polygon
  
  while i <= #self._.Polygon do
    self:T( { i, j, self._.Polygon[i], self._.Polygon[j] } )
    
    local DeltaX = self._.Polygon[j].x - self._.Polygon[i].x
    local DeltaY = self._.Polygon[j].y - self._.Polygon[i].y
    
    for Segment = 0, Segments do -- We divide each line in 5 segments and smoke a point on the line.
      local PointX = self._.Polygon[i].x + ( Segment * DeltaX / Segments )
      local PointY = self._.Polygon[i].y + ( Segment * DeltaY / Segments )
      local Tire = {
          ["country"] = "USA", 
          ["category"] = "Fortifications",
          ["canCargo"] = false,
          ["shape_name"] = "H-tyre_B_WF",
          ["type"] = "Black_Tyre_WF",
          ["y"] = PointY,
          ["x"] = PointX,
          ["name"] = string.format( "%s-Tire #%0d", self:GetName(), ((i - 1) * Segments) + Segment ),
          ["heading"] = 0,
      } -- end of ["group"]
      
      local Group = coalition.addStaticObject( country.id.USA, Tire )
      if UnBound and UnBound == true then
        Group:destroy()
      end
      
    end
    j = i
    i = i + 1
  end

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
  j = #self._.Polygon
  
  while i <= #self._.Polygon do
    self:T( { i, j, self._.Polygon[i], self._.Polygon[j] } )
    
    local DeltaX = self._.Polygon[j].x - self._.Polygon[i].x
    local DeltaY = self._.Polygon[j].y - self._.Polygon[i].y
    
    for Segment = 0, Segments do -- We divide each line in 5 segments and smoke a point on the line.
      local PointX = self._.Polygon[i].x + ( Segment * DeltaX / Segments )
      local PointY = self._.Polygon[i].y + ( Segment * DeltaY / Segments )
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
function ZONE_POLYGON_BASE:IsVec2InZone( Vec2 )
  self:F2( Vec2 )

  local Next 
  local Prev 
  local InPolygon = false
  
  Next = 1
  Prev = #self._.Polygon
  
  while Next <= #self._.Polygon do
    self:T( { Next, Prev, self._.Polygon[Next], self._.Polygon[Prev] } )
    if ( ( ( self._.Polygon[Next].y > Vec2.y ) ~= ( self._.Polygon[Prev].y > Vec2.y ) ) and
         ( Vec2.x < ( self._.Polygon[Prev].x - self._.Polygon[Next].x ) * ( Vec2.y - self._.Polygon[Next].y ) / ( self._.Polygon[Prev].y - self._.Polygon[Next].y ) + self._.Polygon[Next].x ) 
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
    if self:IsVec2InZone( Vec2 ) then
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


--- Return a @{Point#COORDINATE} object representing a random 3D point at landheight within the zone.
-- @param #ZONE_POLYGON_BASE self
-- @return Core.Point#COORDINATE
function ZONE_POLYGON_BASE:GetRandomCoordinate()
  self:F2()

  local Coordinate = COORDINATE:NewFromVec2( self:GetRandomVec2() )
  
  self:T2( Coordinate )

  return Coordinate
end


--- Get the bounding square the zone.
-- @param #ZONE_POLYGON_BASE self
-- @return #ZONE_POLYGON_BASE.BoundingSquare The bounding square.
function ZONE_POLYGON_BASE:GetBoundingSquare()

  local x1 = self._.Polygon[1].x
  local y1 = self._.Polygon[1].y
  local x2 = self._.Polygon[1].x
  local y2 = self._.Polygon[1].y
  
  for i = 2, #self._.Polygon do
    self:T2( { self._.Polygon[i], x1, y1, x2, y2 } )
    x1 = ( x1 > self._.Polygon[i].x ) and self._.Polygon[i].x or x1
    x2 = ( x2 < self._.Polygon[i].x ) and self._.Polygon[i].x or x2
    y1 = ( y1 > self._.Polygon[i].y ) and self._.Polygon[i].y or y1
    y2 = ( y2 < self._.Polygon[i].y ) and self._.Polygon[i].y or y2
    
  end

  return { x1 = x1, y1 = y1, x2 = x2, y2 = y2 }
end


--- @type ZONE_POLYGON
-- @extends #ZONE_POLYGON_BASE


--- # ZONE_POLYGON class, extends @{Zone#ZONE_POLYGON_BASE}
-- 
-- The ZONE_POLYGON class defined by a sequence of @{Group#GROUP} waypoints within the Mission Editor, forming a polygon.
-- This class implements the inherited functions from @{Zone#ZONE_RADIUS} taking into account the own zone format and properties.
-- 
-- @field #ZONE_POLYGON
ZONE_POLYGON = {
  ClassName="ZONE_POLYGON",
  }

--- Constructor to create a ZONE_POLYGON instance, taking the zone name and the @{Group#GROUP} defined within the Mission Editor.
-- The @{Group#GROUP} waypoints define the polygon corners. The first and the last point are automatically connected by ZONE_POLYGON.
-- @param #ZONE_POLYGON self
-- @param #string ZoneName Name of the zone.
-- @param Wrapper.Group#GROUP ZoneGroup The GROUP waypoints as defined within the Mission Editor define the polygon shape.
-- @return #ZONE_POLYGON self
function ZONE_POLYGON:New( ZoneName, ZoneGroup )

  local GroupPoints = ZoneGroup:GetTaskRoute()

  local self = BASE:Inherit( self, ZONE_POLYGON_BASE:New( ZoneName, GroupPoints ) )
  self:F( { ZoneName, ZoneGroup, self._.Polygon } )

  return self
end


--- Constructor to create a ZONE_POLYGON instance, taking the zone name and the **name** of the @{Group#GROUP} defined within the Mission Editor.
-- The @{Group#GROUP} waypoints define the polygon corners. The first and the last point are automatically connected by ZONE_POLYGON.
-- @param #ZONE_POLYGON self
-- @param #string ZoneName Name of the zone.
-- @param #string GroupName The group name of the GROUP defining the waypoints within the Mission Editor to define the polygon shape.
-- @return #ZONE_POLYGON self
function ZONE_POLYGON:NewFromGroupName( ZoneName, GroupName )

  local ZoneGroup = GROUP:FindByName( GroupName )

  local GroupPoints = ZoneGroup:GetTaskRoute()

  local self = BASE:Inherit( self, ZONE_POLYGON_BASE:New( ZoneName, GroupPoints ) )
  self:F( { ZoneName, ZoneGroup, self._.Polygon } )

  return self
end

