--- **Core** - Define zones within your mission of various forms, with various capabilities.
--
-- ===
--
-- ## Features:
--
--   * Create radius zones.
--   * Create trigger zones.
--   * Create polygon zones.
--   * Create moving zones around a unit.
--   * Create moving zones around a group.
--   * Provide the zone behavior. Some zones are static, while others are moveable.
--   * Enquiry if a coordinate is within a zone.
--   * Smoke zones.
--   * Set a zone probability to control zone selection.
--   * Get zone coordinates.
--   * Get zone properties.
--   * Get zone bounding box.
--   * Set/get zone name.
--   * Draw zones (circular and polygon) on the F10 map.
--
--
-- There are essentially two core functions that zones accommodate:
--
--   * Test if an object is within the zone boundaries.
--   * Provide the zone behavior. Some zones are static, while others are moveable.
--
-- The object classes are using the zone classes to test the zone boundaries, which can take various forms:
--
--   * Test if completely within the zone.
--   * Test if partly within the zone (for @{Wrapper.Group#GROUP} objects).
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
--   * @{#ZONE_UNIT}: The ZONE_UNIT class defines by a zone around a @{Wrapper.Unit#UNIT} with a radius.
--   * @{#ZONE_GROUP}: The ZONE_GROUP class defines by a zone around a @{Wrapper.Group#GROUP} with a radius.
--   * @{#ZONE_POLYGON}: The ZONE_POLYGON class defines by a sequence of @{Wrapper.Group#GROUP} waypoints within the Mission Editor, forming a polygon.
--
-- ===
--
-- ### Author: **FlightControl**
-- ### Contributions: **Applevangelist**, **FunkyFranky**
--
-- ===
--
-- @module Core.Zone
-- @image Core_Zones.JPG

--- @type ZONE_BASE
-- @field #string ZoneName Name of the zone.
-- @field #number ZoneProbability A value between 0 and 1. 0 = 0% and 1 = 100% probability.
-- @field #number DrawID Unique ID of the drawn zone on the F10 map.
-- @field #table Color Table with four entries, e.g. {1, 0, 0, 0.15}. First three are RGB color code. Fourth is the transparency Alpha value.
-- @field #table FillColor Table with four entries, e.g. {1, 0, 0, 0.15}. First three are RGB color code. Fourth is the transparency Alpha value.
-- @field #number drawCoalition Draw coalition.
-- @field #number ZoneID ID of zone. Only zones defined in the ME have an ID!
-- @field #table Table of any trigger zone properties from the ME. The key is the Name of the property, and the value is the property's Value.
-- @field #number Surface Type of surface. Only determined at the center of the zone!
-- @extends Core.Fsm#FSM


--- This class is an abstract BASE class for derived classes, and is not meant to be instantiated.
--
-- ## Each zone has a name:
--
--   * @{#ZONE_BASE.GetName}(): Returns the name of the zone.
--   * @{#ZONE_BASE.SetName}(): Sets the name of the zone.
--
--
-- ## Each zone implements two polymorphic functions defined in @{#ZONE_BASE}:
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
-- ## A zone might have additional Properties created in the DCS Mission Editor, which can be accessed:
--
--   *@{#ZONE_BASE.GetProperty}(): Returns the Value of the zone with the given PropertyName, or nil if no matching property exists.
--   *@{#ZONE_BASE.GetAllProperties}(): Returns the zone Properties table.  
--
-- @field #ZONE_BASE
ZONE_BASE = {
  ClassName = "ZONE_BASE",
  ZoneName = "",
  ZoneProbability = 1,
  DrawID=nil,
  Color={},
  ZoneID=nil,
  Properties={},
  Surface=nil,
}

--- The ZONE_BASE.BoundingSquare
-- @type ZONE_BASE.BoundingSquare
-- @field DCS#Distance x1 The lower x coordinate (left down)
-- @field DCS#Distance y1 The lower y coordinate (left down)
-- @field DCS#Distance x2 The higher x coordinate (right up)
-- @field DCS#Distance y2 The higher y coordinate (right up)

--- ZONE_BASE constructor
-- @param #ZONE_BASE self
-- @param #string ZoneName Name of the zone.
-- @return #ZONE_BASE self
function ZONE_BASE:New( ZoneName )
  local self = BASE:Inherit( self, FSM:New() )
  self:F( ZoneName )

  self.ZoneName = ZoneName

  --_DATABASE:AddZone(ZoneName,self)

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
-- @param DCS#Vec2 Vec2 The Vec2 to test.
-- @return #boolean true if the Vec2 is within the zone.
function ZONE_BASE:IsVec2InZone( Vec2 )
  self:F2( Vec2 )

  return false
end

--- Returns if a Vec3 is within the zone.
-- @param #ZONE_BASE self
-- @param DCS#Vec3 Vec3 The point to test.
-- @return #boolean true if the Vec3 is within the zone.
function ZONE_BASE:IsVec3InZone( Vec3 )
  if not Vec3 then return false end
  local InZone = self:IsVec2InZone( { x = Vec3.x, y = Vec3.z } )
  return InZone
end

--- Returns if a Coordinate is within the zone.
-- @param #ZONE_BASE self
-- @param Core.Point#COORDINATE Coordinate The coordinate to test.
-- @return #boolean true if the coordinate is within the zone.
function ZONE_BASE:IsCoordinateInZone( Coordinate )
  local InZone = self:IsVec2InZone( Coordinate:GetVec2() )
  return InZone
end

--- Returns if a PointVec2 is within the zone. (Name is misleading, actually takes a #COORDINATE)
-- @param #ZONE_BASE self
-- @param Core.Point#COORDINATE PointVec2 The coordinate to test.
-- @return #boolean true if the PointVec2 is within the zone.
function ZONE_BASE:IsPointVec2InZone( Coordinate )
  local InZone = self:IsVec2InZone( Coordinate:GetVec2() )
  return InZone
end

--- Returns if a PointVec3 is within the zone.
-- @param #ZONE_BASE self
-- @param Core.Point#POINT_VEC3 PointVec3 The PointVec3 to test.
-- @return #boolean true if the PointVec3 is within the zone.
function ZONE_BASE:IsPointVec3InZone( PointVec3 )
  local InZone = self:IsPointVec2InZone( PointVec3 )
  return InZone
end

--- Returns the @{DCS#Vec2} coordinate of the zone.
-- @param #ZONE_BASE self
-- @return #nil.
function ZONE_BASE:GetVec2()
  return nil
end

--- Returns a @{Core.Point#POINT_VEC2} of the zone.
-- @param #ZONE_BASE self
-- @param DCS#Distance Height The height to add to the land height where the center of the zone is located.
-- @return Core.Point#POINT_VEC2 The PointVec2 of the zone.
function ZONE_BASE:GetPointVec2()
  self:F2( self.ZoneName )

  local Vec2 = self:GetVec2()

  local PointVec2 = POINT_VEC2:NewFromVec2( Vec2 )

  self:T2( { PointVec2 } )

  return PointVec2
end

--- Returns the @{DCS#Vec3} of the zone.
-- @param #ZONE_BASE self
-- @param DCS#Distance Height The height to add to the land height where the center of the zone is located.
-- @return DCS#Vec3 The Vec3 of the zone.
function ZONE_BASE:GetVec3( Height )
  self:F2( self.ZoneName )

  Height = Height or 0

  local Vec2 = self:GetVec2()

  local Vec3 = { x = Vec2.x, y = Height and Height or land.getHeight( self:GetVec2() ), z = Vec2.y }

  self:T2( { Vec3 } )

  return Vec3
end

--- Returns a @{Core.Point#POINT_VEC3} of the zone.
-- @param #ZONE_BASE self
-- @param DCS#Distance Height The height to add to the land height where the center of the zone is located.
-- @return Core.Point#POINT_VEC3 The PointVec3 of the zone.
function ZONE_BASE:GetPointVec3( Height )
  self:F2( self.ZoneName )

  local Vec3 = self:GetVec3( Height )

  local PointVec3 = POINT_VEC3:NewFromVec3( Vec3 )

  self:T2( { PointVec3 } )

  return PointVec3
end

--- Returns a @{Core.Point#COORDINATE} of the zone.
-- @param #ZONE_BASE self
-- @param DCS#Distance Height The height to add to the land height where the center of the zone is located.
-- @return Core.Point#COORDINATE The Coordinate of the zone.
function ZONE_BASE:GetCoordinate( Height ) --R2.1
  self:F2(self.ZoneName)

  local Vec3 = self:GetVec3( Height )

  if self.Coordinate then

    -- Update coordinates.
    self.Coordinate.x=Vec3.x
    self.Coordinate.y=Vec3.y
    self.Coordinate.z=Vec3.z

    --env.info("FF GetCoordinate NEW for ZONE_BASE "..tostring(self.ZoneName))
  else

    -- Create a new coordinate object.
    self.Coordinate=COORDINATE:NewFromVec3(Vec3)

    --env.info("FF GetCoordinate NEW for ZONE_BASE "..tostring(self.ZoneName))
  end

  return self.Coordinate
end

--- Get 2D distance to a coordinate.
-- @param #ZONE_BASE self
-- @param Core.Point#COORDINATE Coordinate Reference coordinate. Can also be a DCS#Vec2 or DCS#Vec3 object.
-- @return #number Distance to the reference coordinate in meters.
function ZONE_BASE:Get2DDistance(Coordinate)
  local a=self:GetVec2()
  local b={}
  if Coordinate.z then
    b.x=Coordinate.x
    b.y=Coordinate.z
  else
    b.x=Coordinate.x
    b.y=Coordinate.y
  end  
  local dist=UTILS.VecDist2D(a,b)
  return dist
end

--- Define a random @{DCS#Vec2} within the zone.
-- @param #ZONE_BASE self
-- @return DCS#Vec2 The Vec2 coordinates.
function ZONE_BASE:GetRandomVec2()
  return nil
end

--- Define a random @{Core.Point#POINT_VEC2} within the zone.
-- @param #ZONE_BASE self
-- @return Core.Point#POINT_VEC2 The PointVec2 coordinates.
function ZONE_BASE:GetRandomPointVec2()
  return nil
end

--- Define a random @{Core.Point#POINT_VEC3} within the zone.
-- @param #ZONE_BASE self
-- @return Core.Point#POINT_VEC3 The PointVec3 coordinates.
function ZONE_BASE:GetRandomPointVec3()
  return nil
end

--- Get the bounding square the zone.
-- @param #ZONE_BASE self
-- @return #nil The bounding square.
function ZONE_BASE:GetBoundingSquare()
  return nil
end

--- Get surface type of the zone.
-- @param #ZONE_BASE self
-- @return DCS#SurfaceType Type of surface.
function ZONE_BASE:GetSurfaceType()
  local coord=self:GetCoordinate()
  local surface=coord:GetSurfaceType()
  return surface
end

--- Bound the zone boundaries with a tires.
-- @param #ZONE_BASE self
function ZONE_BASE:BoundZone()
  self:F2()
end

--- Set draw coalition of zone.
-- @param #ZONE_BASE self
-- @param #number Coalition Coalition. Default -1.
-- @return #ZONE_BASE self
function ZONE_BASE:SetDrawCoalition(Coalition)
  self.drawCoalition=Coalition or -1
  return self
end

--- Get draw coalition of zone.
-- @param #ZONE_BASE self
-- @return #number Draw coalition.
function ZONE_BASE:GetDrawCoalition()
  return self.drawCoalition or -1
end

--- Set color of zone.
-- @param #ZONE_BASE self
-- @param #table RGBcolor RGB color table. Default `{1, 0, 0}`.
-- @param #number Alpha Transparency between 0 and 1. Default 0.15.
-- @return #ZONE_BASE self
function ZONE_BASE:SetColor(RGBcolor, Alpha)

  RGBcolor=RGBcolor or {1, 0, 0}
  Alpha=Alpha or 0.15

  self.Color={}
  self.Color[1]=RGBcolor[1]
  self.Color[2]=RGBcolor[2]
  self.Color[3]=RGBcolor[3]
  self.Color[4]=Alpha

  return self
end

--- Get color table of the zone.
-- @param #ZONE_BASE self
-- @return #table Table with four entries, e.g. {1, 0, 0, 0.15}. First three are RGB color code. Fourth is the transparency Alpha value.
function ZONE_BASE:GetColor()
  return self.Color or {1, 0, 0, 0.15}
end

--- Get RGB color of zone.
-- @param #ZONE_BASE self
-- @return #table Table with three entries, e.g. {1, 0, 0}, which is the RGB color code.
function ZONE_BASE:GetColorRGB()
  local rgb={}
  local Color=self:GetColor()
  rgb[1]=Color[1]
  rgb[2]=Color[2]
  rgb[3]=Color[3]
  return rgb
end

--- Get transparency Alpha value of zone.
-- @param #ZONE_BASE self
-- @return #number Alpha value.
function ZONE_BASE:GetColorAlpha()
  local Color=self:GetColor()
  local alpha=Color[4]
  return alpha
end

--- Set fill color of zone.
-- @param #ZONE_BASE self
-- @param #table RGBcolor RGB color table. Default `{1, 0, 0}`.
-- @param #number Alpha Transparacy between 0 and 1. Default 0.15.
-- @return #ZONE_BASE self
function ZONE_BASE:SetFillColor(RGBcolor, Alpha)

  RGBcolor=RGBcolor or {1, 0, 0}
  Alpha=Alpha or 0.15

  self.FillColor={}
  self.FillColor[1]=RGBcolor[1]
  self.FillColor[2]=RGBcolor[2]
  self.FillColor[3]=RGBcolor[3]
  self.FillColor[4]=Alpha

  return self
end

--- Get fill color table of the zone.
-- @param #ZONE_BASE self
-- @return #table Table with four entries, e.g. {1, 0, 0, 0.15}. First three are RGB color code. Fourth is the transparency Alpha value.
function ZONE_BASE:GetFillColor()
  return self.FillColor or {1, 0, 0, 0.15}
end

--- Get RGB fill color of zone.
-- @param #ZONE_BASE self
-- @return #table Table with three entries, e.g. {1, 0, 0}, which is the RGB color code.
function ZONE_BASE:GetFillColorRGB()
  local rgb={}
  local FillColor=self:GetFillColor()
  rgb[1]=FillColor[1]
  rgb[2]=FillColor[2]
  rgb[3]=FillColor[3]
  return rgb
end

--- Get transparency Alpha fill value of zone.
-- @param #ZONE_BASE self
-- @return #number Alpha value.
function ZONE_BASE:GetFillColorAlpha()
  local FillColor=self:GetFillColor()
  local alpha=FillColor[4]
  return alpha
end

--- Remove the drawing of the zone from the F10 map.
-- @param #ZONE_BASE self
-- @param #number Delay (Optional) Delay before the drawing is removed.
-- @return #ZONE_BASE self
function ZONE_BASE:UndrawZone(Delay)
  if Delay and Delay>0 then
    self:ScheduleOnce(Delay, ZONE_BASE.UndrawZone, self)
  else
    if self.DrawID then
      UTILS.RemoveMark(self.DrawID)
    end
  end
  return self
end

--- Get ID of the zone object drawn on the F10 map.
-- The ID can be used to remove the drawn object from the F10 map view via `UTILS.RemoveMark(MarkID)`.
-- @param #ZONE_BASE self
-- @return #number Unique ID of the
function ZONE_BASE:GetDrawID()
  return self.DrawID
end


--- Smokes the zone boundaries in a color.
-- @param #ZONE_BASE self
-- @param Utilities.Utils#SMOKECOLOR SmokeColor The smoke color.
function ZONE_BASE:SmokeZone( SmokeColor )
  self:F2( SmokeColor )

end

--- Set the randomization probability of a zone to be selected.
-- @param #ZONE_BASE self
-- @param #number ZoneProbability A value between 0 and 1. 0 = 0% and 1 = 100% probability.
-- @return #ZONE_BASE self
function ZONE_BASE:SetZoneProbability( ZoneProbability )
  self:F( { self:GetName(), ZoneProbability = ZoneProbability } )

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
-- @usage
--
-- local ZoneArray = { ZONE:New( "Zone1" ), ZONE:New( "Zone2" ) }
--
-- -- We set a zone probability of 70% to the first zone and 30% to the second zone.
-- ZoneArray[1]:SetZoneProbability( 0.5 )
-- ZoneArray[2]:SetZoneProbability( 0.5 )
--
-- local ZoneSelected = nil
--
-- while ZoneSelected == nil do
--   for _, Zone in pairs( ZoneArray ) do
--     ZoneSelected = Zone:GetZoneMaybe()
--     if ZoneSelected ~= nil then
--       break
--     end
--   end
-- end
--
-- -- The result should be that Zone1 would be more probable selected than Zone2.
--
function ZONE_BASE:GetZoneMaybe()
  self:F2()

  local Randomization = math.random()
  if Randomization <= self.ZoneProbability then
    return self
  else
    return nil
  end
end

--- Returns the Value of the zone with the given PropertyName, or nil if no matching property exists.
-- @param #ZONE_BASE self
-- @param #string PropertyName The name of a the TriggerZone Property to be retrieved.
-- @return #string The Value of the TriggerZone Property with the given PropertyName, or nil if absent.
-- @usage
-- 
-- local PropertiesZone = ZONE:FindByName("Properties Zone")
-- local Property = "ExampleProperty"
-- local PropertyValue = PropertiesZone:GetProperty(Property)
--
function ZONE_BASE:GetProperty(PropertyName)
  return self.Properties[PropertyName]
end

--- Returns the zone Properties table.
-- @param #ZONE_BASE self
-- @return #table The Key:Value table of TriggerZone properties of the zone.
function ZONE_BASE:GetAllProperties()
  return self.Properties
end

--- The ZONE_RADIUS class, defined by a zone name, a location and a radius.
-- @type ZONE_RADIUS
-- @field DCS#Vec2 Vec2 The current location of the zone.
-- @field DCS#Distance Radius The radius of the zone.
-- @extends #ZONE_BASE

--- The ZONE_RADIUS class defined by a zone name, a location and a radius.
-- This class implements the inherited functions from @{#ZONE_BASE} taking into account the own zone format and properties.
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
--   * @{#ZONE_RADIUS.SetVec2}(): Sets the @{DCS#Vec2} of the zone.
--   * @{#ZONE_RADIUS.GetVec2}(): Returns the @{DCS#Vec2} of the zone.
--   * @{#ZONE_RADIUS.GetVec3}(): Returns the @{DCS#Vec3} of the zone, taking an additional height parameter.
--
-- ## Zone point randomization
--
-- Various functions exist to find random points within the zone.
--
--   * @{#ZONE_RADIUS.GetRandomVec2}(): Gets a random 2D point in the zone.
--   * @{#ZONE_RADIUS.GetRandomPointVec2}(): Gets a @{Core.Point#POINT_VEC2} object representing a random 2D point in the zone.
--   * @{#ZONE_RADIUS.GetRandomPointVec3}(): Gets a @{Core.Point#POINT_VEC3} object representing a random 3D point in the zone. Note that the height of the point is at landheight.
--
-- ## Draw zone
--
--   * @{#ZONE_RADIUS.DrawZone}(): Draws the zone on the F10 map.
--
-- @field #ZONE_RADIUS
ZONE_RADIUS = {
  ClassName="ZONE_RADIUS",
  }

--- Constructor of @{#ZONE_RADIUS}, taking the zone name, the zone location and a radius.
-- @param #ZONE_RADIUS self
-- @param #string ZoneName Name of the zone.
-- @param DCS#Vec2 Vec2 The location of the zone.
-- @param DCS#Distance Radius The radius of the zone.
-- @param DCS#Boolean DoNotRegisterZone Determines if the Zone should not be registered in the _Database Table. Default=false
-- @return #ZONE_RADIUS self
function ZONE_RADIUS:New( ZoneName, Vec2, Radius, DoNotRegisterZone )

  -- Inherit ZONE_BASE.
  local self = BASE:Inherit( self, ZONE_BASE:New( ZoneName ) ) -- #ZONE_RADIUS
  self:F( { ZoneName, Vec2, Radius } )

  self.Radius = Radius
  self.Vec2 = Vec2

  if not DoNotRegisterZone then
    _EVENTDISPATCHER:CreateEventNewZone(self)
  end
  
  --self.Coordinate=COORDINATE:NewFromVec2(Vec2)

  return self
end

--- Update zone from a 2D vector.
-- @param #ZONE_RADIUS self
-- @param DCS#Vec2 Vec2 The location of the zone.
-- @param DCS#Distance Radius The radius of the zone.
-- @return #ZONE_RADIUS self
function ZONE_RADIUS:UpdateFromVec2(Vec2, Radius)

  -- New center of the zone.
  self.Vec2=Vec2

  if Radius then
    self.Radius=Radius
  end

  return self
end

--- Update zone from a 2D vector.
-- @param #ZONE_RADIUS self
-- @param DCS#Vec3 Vec3 The location of the zone.
-- @param DCS#Distance Radius The radius of the zone.
-- @return #ZONE_RADIUS self
function ZONE_RADIUS:UpdateFromVec3(Vec3, Radius)

  -- New center of the zone.
  self.Vec2.x=Vec3.x
  self.Vec2.y=Vec3.z

  if Radius then
    self.Radius=Radius
  end

  return self
end

--- Mark the zone with markers on the F10 map.
-- @param #ZONE_RADIUS self
-- @param #number Points (Optional) The amount of points in the circle. Default 360.
-- @return #ZONE_RADIUS self
function ZONE_RADIUS:MarkZone(Points)

  local Point = {}
  local Vec2 = self:GetVec2()

  Points = Points and Points or 360

  local Angle
  local RadialBase = math.pi*2

  for Angle = 0, 360, (360 / Points ) do

    local Radial = Angle * RadialBase / 360

    Point.x = Vec2.x + math.cos( Radial ) * self:GetRadius()
    Point.y = Vec2.y + math.sin( Radial ) * self:GetRadius()

    COORDINATE:NewFromVec2(Point):MarkToAll(self:GetName())

  end

end

--- Draw the zone circle on the F10 map.
-- @param #ZONE_RADIUS self
-- @param #number Coalition Coalition: All=-1, Neutral=0, Red=1, Blue=2. Default -1=All.
-- @param #table Color RGB color table {r, g, b}, e.g. {1,0,0} for red.
-- @param #number Alpha Transparency [0,1]. Default 1.
-- @param #table FillColor RGB color table {r, g, b}, e.g. {1,0,0} for red. Default is same as `Color` value.
-- @param #number FillAlpha Transparency [0,1]. Default 0.15.
-- @param #number LineType Line type: 0=No line, 1=Solid, 2=Dashed, 3=Dotted, 4=Dot dash, 5=Long dash, 6=Two dash. Default 1=Solid.
-- @param #boolean ReadOnly (Optional) Mark is readonly and cannot be removed by users. Default false.
-- @return #ZONE_RADIUS self
function ZONE_RADIUS:DrawZone(Coalition, Color, Alpha, FillColor, FillAlpha, LineType, ReadOnly)

  local coordinate=self:GetCoordinate()

  local Radius=self:GetRadius()

  Color=Color or self:GetColorRGB()
  Alpha=Alpha or 1
  FillColor=FillColor or UTILS.DeepCopy(Color)
  FillAlpha=FillAlpha or self:GetColorAlpha()

  self.DrawID=coordinate:CircleToAll(Radius, Coalition, Color, Alpha, FillColor, FillAlpha, LineType, ReadOnly)

  return self
end

--- Bounds the zone with tires.
-- @param #ZONE_RADIUS self
-- @param #number Points (optional) The amount of points in the circle. Default 360.
-- @param DCS#country.id CountryID The country id of the tire objects, e.g. country.id.USA for blue or country.id.RUSSIA for red.
-- @param #boolean UnBound (Optional) If true the tyres will be destroyed.
-- @return #ZONE_RADIUS self
function ZONE_RADIUS:BoundZone( Points, CountryID, UnBound )

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
-- @param DCS#Azimuth Azimuth (optional) Azimuth The azimuth of the flare.
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
-- @return DCS#Distance The radius of the zone.
function ZONE_RADIUS:GetRadius()
  self:F2( self.ZoneName )

  self:T2( { self.Radius } )

  return self.Radius
end

--- Sets the radius of the zone.
-- @param #ZONE_RADIUS self
-- @param DCS#Distance Radius The radius of the zone.
-- @return DCS#Distance The radius of the zone.
function ZONE_RADIUS:SetRadius( Radius )
  self:F2( self.ZoneName )

  self.Radius = Radius
  self:T2( { self.Radius } )

  return self.Radius
end

--- Returns the @{DCS#Vec2} of the zone.
-- @param #ZONE_RADIUS self
-- @return DCS#Vec2 The location of the zone.
function ZONE_RADIUS:GetVec2()
  self:F2( self.ZoneName )

  self:T2( { self.Vec2 } )

  return self.Vec2
end

--- Sets the @{DCS#Vec2} of the zone.
-- @param #ZONE_RADIUS self
-- @param DCS#Vec2 Vec2 The new location of the zone.
-- @return DCS#Vec2 The new location of the zone.
function ZONE_RADIUS:SetVec2( Vec2 )
  self:F2( self.ZoneName )

  self.Vec2 = Vec2

  self:T2( { self.Vec2 } )

  return self.Vec2
end

--- Returns the @{DCS#Vec3} of the ZONE_RADIUS.
-- @param #ZONE_RADIUS self
-- @param DCS#Distance Height The height to add to the land height where the center of the zone is located.
-- @return DCS#Vec3 The point of the zone.
function ZONE_RADIUS:GetVec3( Height )
  self:F2( { self.ZoneName, Height } )

  Height = Height or 0
  local Vec2 = self:GetVec2()

  local Vec3 = { x = Vec2.x, y = land.getHeight( self:GetVec2() ) + Height, z = Vec2.y }

  self:T2( { Vec3 } )

  return Vec3
end

--- Scan the zone for the presence of units of the given ObjectCategories.
-- Note that **only after** a zone has been scanned, the zone can be evaluated by:
--
--   * @{ZONE_RADIUS.IsAllInZoneOfCoalition}(): Scan the presence of units in the zone of a coalition.
--   * @{ZONE_RADIUS.IsAllInZoneOfOtherCoalition}(): Scan the presence of units in the zone of an other coalition.
--   * @{ZONE_RADIUS.IsSomeInZoneOfCoalition}(): Scan if there is some presence of units in the zone of the given coalition.
--   * @{ZONE_RADIUS.IsNoneInZoneOfCoalition}(): Scan if there isn't any presence of units in the zone of an other coalition than the given one.
--   * @{ZONE_RADIUS.IsNoneInZone}(): Scan if the zone is empty.
-- @param #ZONE_RADIUS self
-- @param ObjectCategories An array of categories of the objects to find in the zone. E.g. `{Object.Category.UNIT}`
-- @param UnitCategories An array of unit categories of the objects to find in the zone. E.g. `{Unit.Category.GROUND_UNIT,Unit.Category.SHIP}`
-- @usage
--    myzone:Scan({Object.Category.UNIT},{Unit.Category.GROUND_UNIT})
--    local IsAttacked = myzone:IsSomeInZoneOfCoalition( self.Coalition )
function ZONE_RADIUS:Scan( ObjectCategories, UnitCategories )

  self.ScanData = {}
  self.ScanData.Coalitions = {}
  self.ScanData.Scenery = {}
  self.ScanData.SceneryTable = {}
  self.ScanData.Units = {}

  local ZoneCoord = self:GetCoordinate()
  local ZoneRadius = self:GetRadius()

  --self:F({ZoneCoord = ZoneCoord, ZoneRadius = ZoneRadius, ZoneCoordLL = ZoneCoord:ToStringLLDMS()})

  local SphereSearch = {
    id = world.VolumeType.SPHERE,
      params = {
      point = ZoneCoord:GetVec3(),
      radius = ZoneRadius,
      }
    }

  local function EvaluateZone( ZoneObject )
    --if ZoneObject:isExist() then --FF: isExist always returns false for SCENERY objects since DCS 2.2 and still in DCS 2.5
    if ZoneObject then

      local ObjectCategory = ZoneObject:getCategory()

      --local name=ZoneObject:getName()
      --env.info(string.format("Zone object %s", tostring(name)))
      --self:E(ZoneObject)

      if ( ObjectCategory == Object.Category.UNIT and ZoneObject:isExist() and ZoneObject:isActive() ) or (ObjectCategory == Object.Category.STATIC and ZoneObject:isExist()) then

        local CoalitionDCSUnit = ZoneObject:getCoalition()

        local Include = false
        if not UnitCategories then
          -- Anythink found is included.
          Include = true
        else
          -- Check if found object is in specified categories.
          local CategoryDCSUnit = ZoneObject:getDesc().category

          for UnitCategoryID, UnitCategory in pairs( UnitCategories ) do
            if UnitCategory == CategoryDCSUnit then
              Include = true
              break
            end
          end

        end

        if Include then

          local CoalitionDCSUnit = ZoneObject:getCoalition()

          -- This coalition is inside the zone.
          self.ScanData.Coalitions[CoalitionDCSUnit] = true

          self.ScanData.Units[ZoneObject] = ZoneObject

          self:F2( { Name = ZoneObject:getName(), Coalition = CoalitionDCSUnit } )
        end
      end

      if ObjectCategory == Object.Category.SCENERY then
        local SceneryType = ZoneObject:getTypeName()
        local SceneryName = ZoneObject:getName()
        --BASE:I("SceneryType "..SceneryType.."SceneryName"..SceneryName)
        self.ScanData.Scenery[SceneryType] = self.ScanData.Scenery[SceneryType] or {}
        self.ScanData.Scenery[SceneryType][SceneryName] = SCENERY:Register( SceneryName, ZoneObject )
        table.insert(self.ScanData.SceneryTable,self.ScanData.Scenery[SceneryType][SceneryName] )
        self:T( { SCENERY =  self.ScanData.Scenery[SceneryType][SceneryName] } )
      end

    end

    return true
  end

  -- Search objects.
  world.searchObjects( ObjectCategories, SphereSearch, EvaluateZone )

end

--- Remove junk inside the zone using the `world.removeJunk` function.
-- @param #ZONE_RADIUS self
-- @return #number Number of deleted objects.
function ZONE_RADIUS:RemoveJunk()

  local radius=self.Radius
  local vec3=self:GetVec3()

  local volS = {
    id = world.VolumeType.SPHERE,
    params = {point = vec3, radius = radius}
  }

  local n=world.removeJunk(volS)

  return n
end

--- Count the number of different coalitions inside the zone.
-- @param #ZONE_RADIUS self
-- @return #table Table of DCS units and DCS statics inside the zone.
function ZONE_RADIUS:GetScannedUnits()

  return self.ScanData.Units
end

--- Get a set of scanned units.
-- @param #ZONE_RADIUS self
-- @return Core.Set#SET_UNIT Set of units and statics inside the zone.
function ZONE_RADIUS:GetScannedSetUnit()

  local SetUnit = SET_UNIT:New()

  if self.ScanData then
    for ObjectID, UnitObject in pairs( self.ScanData.Units ) do
      local UnitObject = UnitObject -- DCS#Unit
      if UnitObject:isExist() then
        local FoundUnit = UNIT:FindByName( UnitObject:getName() )
        if FoundUnit then
          SetUnit:AddUnit( FoundUnit )
        else
          local FoundStatic = STATIC:FindByName( UnitObject:getName() )
          if FoundStatic then
            SetUnit:AddUnit( FoundStatic )
          end
        end
      end
    end
  end

  return SetUnit
end

--- Get a set of scanned units.
-- @param #ZONE_RADIUS self
-- @return Core.Set#SET_GROUP Set of groups.
function ZONE_RADIUS:GetScannedSetGroup()

  self.ScanSetGroup=self.ScanSetGroup or SET_GROUP:New() --Core.Set#SET_GROUP

  self.ScanSetGroup.Set={}

  if self.ScanData then
    for ObjectID, UnitObject in pairs( self.ScanData.Units ) do
      local UnitObject = UnitObject -- DCS#Unit
      if UnitObject:isExist() then

        local FoundUnit=UNIT:FindByName(UnitObject:getName())
        if FoundUnit then
          local group=FoundUnit:GetGroup()
          self.ScanSetGroup:AddGroup(group)
        end
      end
    end
  end

  return self.ScanSetGroup
end

--- Count the number of different coalitions inside the zone.
-- @param #ZONE_RADIUS self
-- @return #number Counted coalitions.
function ZONE_RADIUS:CountScannedCoalitions()

  local Count = 0

  for CoalitionID, Coalition in pairs( self.ScanData.Coalitions ) do
    Count = Count + 1
  end

  return Count
end

--- Check if a certain coalition is inside a scanned zone.
-- @param #ZONE_RADIUS self
-- @param #number Coalition The coalition id, e.g. coalition.side.BLUE.
-- @return #boolean If true, the coalition is inside the zone.
function ZONE_RADIUS:CheckScannedCoalition( Coalition )
  if Coalition then
    return self.ScanData.Coalitions[Coalition]
  end
  return nil
end

--- Get Coalitions of the units in the Zone, or Check if there are units of the given Coalition in the Zone.
-- Returns nil if there are none to two Coalitions in the zone!
-- Returns one Coalition if there are only Units of one Coalition in the Zone.
-- Returns the Coalition for the given Coalition if there are units of the Coalition in the Zone.
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

--- Get scanned scenery type
-- @param #ZONE_RADIUS self
-- @return #table Table of DCS scenery type objects.
function ZONE_RADIUS:GetScannedSceneryType( SceneryType )
  return self.ScanData.Scenery[SceneryType]
end

--- Get scanned scenery table
-- @param #ZONE_RADIUS self
-- @return #table Structured object table: [type].[name].SCENERY
function ZONE_RADIUS:GetScannedScenery()
  return self.ScanData.Scenery
end

--- Get table of scanned scenery objects
-- @param #ZONE_RADIUS self
-- @return #table Table of SCENERY objects.
function ZONE_RADIUS:GetScannedSceneryObjects()
  return self.ScanData.SceneryTable
end

--- Get set of scanned scenery objects
-- @param #ZONE_RADIUS self
-- @return #table Table of Wrapper.Scenery#SCENERY scenery objects.
function ZONE_RADIUS:GetScannedSetScenery()
  local scenery = SET_SCENERY:New()
  local objects = self:GetScannedSceneryObjects()
  for _,_obj in pairs (objects) do
    scenery:AddScenery(_obj)
  end
  return scenery
end

--- Is All in Zone of Coalition?
-- Check if only the specified coalition is inside the zone and no one else.
-- @param #ZONE_RADIUS self
-- @param #number Coalition Coalition ID of the coalition which is checked to be the only one in the zone.
-- @return #boolean True, if **only** that coalition is inside the zone and no one else.
-- @usage
--    self.Zone:Scan()
--    local IsGuarded = self.Zone:IsAllInZoneOfCoalition( self.Coalition )
function ZONE_RADIUS:IsAllInZoneOfCoalition( Coalition )

  --self:E( { Coalitions = self.Coalitions, Count = self:CountScannedCoalitions() } )
  return self:CountScannedCoalitions() == 1 and self:GetScannedCoalition( Coalition ) == true
end

--- Is All in Zone of Other Coalition?
-- Check if only one coalition is inside the zone and the specified coalition is not the one.
-- You first need to use the @{#ZONE_RADIUS.Scan} method to scan the zone before it can be evaluated!
-- Note that once a zone has been scanned, multiple evaluations can be done on the scan result set.
-- @param #ZONE_RADIUS self
-- @param #number Coalition Coalition ID of the coalition which is not supposed to be in the zone.
-- @return #boolean True, if and only if only one coalition is inside the zone and the specified coalition is not it.
-- @usage
--    self.Zone:Scan()
--    local IsCaptured = self.Zone:IsAllInZoneOfOtherCoalition( self.Coalition )
function ZONE_RADIUS:IsAllInZoneOfOtherCoalition( Coalition )

  --self:E( { Coalitions = self.Coalitions, Count = self:CountScannedCoalitions() } )
  return self:CountScannedCoalitions() == 1 and self:GetScannedCoalition( Coalition ) == nil
end

--- Is Some in Zone of Coalition?
-- Check if more than one coalition is inside the zone and the specified coalition is one of them.
-- You first need to use the @{#ZONE_RADIUS.Scan} method to scan the zone before it can be evaluated!
-- Note that once a zone has been scanned, multiple evaluations can be done on the scan result set.
-- @param #ZONE_RADIUS self
-- @param #number Coalition ID of the coalition which is checked to be inside the zone.
-- @return #boolean True if more than one coalition is inside the zone and the specified coalition is one of them.
-- @usage
--    self.Zone:Scan()
--    local IsAttacked = self.Zone:IsSomeInZoneOfCoalition( self.Coalition )
function ZONE_RADIUS:IsSomeInZoneOfCoalition( Coalition )

  return self:CountScannedCoalitions() > 1 and self:GetScannedCoalition( Coalition ) == true
end

--- Is None in Zone of Coalition?
-- You first need to use the @{#ZONE_RADIUS.Scan} method to scan the zone before it can be evaluated!
-- Note that once a zone has been scanned, multiple evaluations can be done on the scan result set.
-- @param #ZONE_RADIUS self
-- @param Coalition
-- @return #boolean
-- @usage
--    self.Zone:Scan()
--    local IsOccupied = self.Zone:IsNoneInZoneOfCoalition( self.Coalition )
function ZONE_RADIUS:IsNoneInZoneOfCoalition( Coalition )

  return self:GetScannedCoalition( Coalition ) == nil
end

--- Is None in Zone?
-- You first need to use the @{#ZONE_RADIUS.Scan} method to scan the zone before it can be evaluated!
-- Note that once a zone has been scanned, multiple evaluations can be done on the scan result set.
-- @param #ZONE_RADIUS self
-- @return #boolean
-- @usage
--    self.Zone:Scan()
--    local IsEmpty = self.Zone:IsNoneInZone()
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

  self:F({ZoneCoord = ZoneCoord, ZoneRadius = ZoneRadius, ZoneCoordLL = ZoneCoord:ToStringLLDMS()})

  local SphereSearch = {
    id = world.VolumeType.SPHERE,
      params = {
      point = ZoneCoord:GetVec3(),
      radius = ZoneRadius / 2,
      }
    }

  local function EvaluateZone( ZoneDCSUnit )


    local ZoneUnit = UNIT:Find( ZoneDCSUnit )

    return EvaluateFunction( ZoneUnit )
  end

  world.searchObjects( Object.Category.UNIT, SphereSearch, EvaluateZone )

end

--- Returns if a location is within the zone.
-- @param #ZONE_RADIUS self
-- @param DCS#Vec2 Vec2 The location to test.
-- @return #boolean true if the location is within the zone.
function ZONE_RADIUS:IsVec2InZone( Vec2 )
  self:F2( Vec2 )

  if not Vec2 then return false end 

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
-- @param DCS#Vec3 Vec3 The point to test.
-- @return #boolean true if the point is within the zone.
function ZONE_RADIUS:IsVec3InZone( Vec3 )
  self:F2( Vec3 )
  if not Vec3 then return false end  
  local InZone = self:IsVec2InZone( { x = Vec3.x, y = Vec3.z } )

  return InZone
end

--- Returns a random Vec2 location within the zone.
-- @param #ZONE_RADIUS self
-- @param #number inner (Optional) Minimal distance from the center of the zone. Default is 0.
-- @param #number outer (Optional) Maximal distance from the outer edge of the zone. Default is the radius of the zone.
-- @param #table surfacetypes (Optional) Table of surface types. Can also be a single surface type. We will try max 100 times to find the right type!
-- @return DCS#Vec2 The random location within the zone.
function ZONE_RADIUS:GetRandomVec2(inner, outer, surfacetypes)

  local Vec2 = self:GetVec2()
  local _inner = inner or 0
  local _outer = outer or self:GetRadius()

  if surfacetypes and type(surfacetypes)~="table" then
    surfacetypes={surfacetypes}
  end

  local function _getpoint()
    local point = {}
    local angle = math.random() * math.pi * 2
    point.x = Vec2.x + math.cos(angle) * math.random(_inner, _outer)
    point.y = Vec2.y + math.sin(angle) * math.random(_inner, _outer)
    return point
  end

  local function _checkSurface(point)
    local stype=land.getSurfaceType(point)
    for _,sf in pairs(surfacetypes) do
      if sf==stype then
        return true
      end
    end
    return false
  end

  local point=_getpoint()

  if surfacetypes then
    local N=1 ; local Nmax=100 ; local gotit=false
    while gotit==false and N<=Nmax do
      gotit=_checkSurface(point)
      if gotit then
        --env.info(string.format("Got random coordinate with surface type %d after N=%d/%d iterations", land.getSurfaceType(point), N, Nmax))
      else
        point=_getpoint()
        N=N+1
      end
    end
  end

  return point
end

--- Returns a @{Core.Point#POINT_VEC2} object reflecting a random 2D location within the zone.
-- @param #ZONE_RADIUS self
-- @param #number inner (optional) Minimal distance from the center of the zone. Default is 0.
-- @param #number outer (optional) Maximal distance from the outer edge of the zone. Default is the radius of the zone.
-- @return Core.Point#POINT_VEC2 The @{Core.Point#POINT_VEC2} object reflecting the random 3D location within the zone.
function ZONE_RADIUS:GetRandomPointVec2( inner, outer )
  self:F( self.ZoneName, inner, outer )

  local PointVec2 = POINT_VEC2:NewFromVec2( self:GetRandomVec2( inner, outer ) )

  self:T3( { PointVec2 } )

  return PointVec2
end

--- Returns Returns a random Vec3 location within the zone.
-- @param #ZONE_RADIUS self
-- @param #number inner (optional) Minimal distance from the center of the zone. Default is 0.
-- @param #number outer (optional) Maximal distance from the outer edge of the zone. Default is the radius of the zone.
-- @return DCS#Vec3 The random location within the zone.
function ZONE_RADIUS:GetRandomVec3( inner, outer )
  self:F( self.ZoneName, inner, outer )

  local Vec2 = self:GetRandomVec2( inner, outer )

  self:T3( { x = Vec2.x, y = self.y, z = Vec2.y } )

  return { x = Vec2.x, y = self.y, z = Vec2.y }
end


--- Returns a @{Core.Point#POINT_VEC3} object reflecting a random 3D location within the zone.
-- @param #ZONE_RADIUS self
-- @param #number inner (optional) Minimal distance from the center of the zone. Default is 0.
-- @param #number outer (optional) Maximal distance from the outer edge of the zone. Default is the radius of the zone.
-- @return Core.Point#POINT_VEC3 The @{Core.Point#POINT_VEC3} object reflecting the random 3D location within the zone.
function ZONE_RADIUS:GetRandomPointVec3( inner, outer )
  self:F( self.ZoneName, inner, outer )

  local PointVec3 = POINT_VEC3:NewFromVec2( self:GetRandomVec2( inner, outer ) )

  self:T3( { PointVec3 } )

  return PointVec3
end


--- Returns a @{Core.Point#COORDINATE} object reflecting a random 3D location within the zone.
-- @param #ZONE_RADIUS self
-- @param #number inner (Optional) Minimal distance from the center of the zone in meters. Default is 0 m.
-- @param #number outer (Optional) Maximal distance from the outer edge of the zone in meters. Default is the radius of the zone.
-- @param #table surfacetypes (Optional) Table of surface types. Can also be a single surface type. We will try max 100 times to find the right type!
-- @return Core.Point#COORDINATE The random coordinate.
function ZONE_RADIUS:GetRandomCoordinate(inner, outer, surfacetypes)

  local vec2=self:GetRandomVec2(inner, outer, surfacetypes)

  local Coordinate = COORDINATE:NewFromVec2(vec2)

  return Coordinate
end

--- Returns a @{Core.Point#COORDINATE} object reflecting a random location within the zone where there are no **map objects** of type "Building". 
-- Does not find statics you might have placed there. **Note** This might be quite CPU intensive, use with care.
-- @param #ZONE_RADIUS self
-- @param #number inner (Optional) Minimal distance from the center of the zone in meters. Default is 0m.
-- @param #number outer (Optional) Maximal distance from the outer edge of the zone in meters. Default is the radius of the zone.
-- @param #number distance (Optional) Minimum distance from any building coordinate. Defaults to 100m.
-- @param #boolean markbuildings (Optional) Place markers on found buildings (if any).
-- @param #boolean markfinal (Optional) Place marker on the final coordinate (if any).
-- @return Core.Point#COORDINATE The random coordinate or `nil` if cannot be found in 1000 iterations.
function ZONE_RADIUS:GetRandomCoordinateWithoutBuildings(inner,outer,distance,markbuildings,markfinal)

  local dist = distance or 100

  local objects = {}

  if self.ScanData and self.ScanData.Scenery then
    objects = self:GetScannedScenery()
  else
    self:Scan({Object.Category.SCENERY})
    objects = self:GetScannedScenery()
  end

  local T0 = timer.getTime()
  local T1 = timer.getTime()

  local buildings = {}
  if self.ScanData and self.ScanData.BuildingCoordinates then
    buildings = self.ScanData.BuildingCoordinates
  else
    -- build table of buildings coordinates
    for _,_object in pairs (objects) do
      for _,_scen in pairs (_object) do
         local scenery = _scen -- Wrapper.Scenery#SCENERY
         local description=scenery:GetDesc()
         if description and description.attributes and description.attributes.Buildings then
          if markbuildings then
            MARKER:New(scenery:GetCoordinate(),"Building"):ToAll()
          end
          buildings[#buildings+1] = scenery:GetCoordinate()
         end
      end
    end
    self.ScanData.BuildingCoordinates = buildings
  end

  -- max 1000 tries
  local rcoord = nil  
  local found = false
  local iterations = 0

  for i=1,1000 do
    iterations = iterations + 1
    rcoord = self:GetRandomCoordinate(inner,outer)
    found = false
    for _,_coord in pairs (buildings) do
      local coord = _coord -- Core.Point#COORDINATE
      -- keep >50m dist from buildings
      if coord:Get3DDistance(rcoord) > dist then
        found = true
      else
        found = false
      end
    end
    if found then 
      -- we have a winner!
      if markfinal then
        MARKER:New(rcoord,"FREE"):ToAll()
      end
      break 
    end
  end
  
  T1=timer.getTime()
  
  self:T(string.format("Found a coordinate: %s | Iterations: %d | Time: %d",tostring(found),iterations,T1-T0))
  
  if found then return rcoord else return nil end
  
end

--- @type ZONE
-- @extends #ZONE_RADIUS


--- The ZONE class, defined by the zone name as defined within the Mission Editor.
-- This class implements the inherited functions from @{#ZONE_RADIUS} taking into account the own zone format and properties.
--
-- ## ZONE constructor
--
--   * @{#ZONE.New}(): Constructor. This will search for a trigger zone with the name given, and will return for you a ZONE object.
--
-- ## Declare a ZONE directly in the DCS mission editor!
--
-- You can declare a ZONE using the DCS mission editor by adding a trigger zone in the mission editor.
--
-- Then during mission startup, when loading Moose.lua, this trigger zone will be detected as a ZONE declaration.
-- Within the background, a ZONE object will be created within the @{Core.Database}.
-- The ZONE name will be the trigger zone name.
--
-- So, you can search yourself for the ZONE object by using the @{#ZONE.FindByName}() method.
-- In this example, `local TriggerZone = ZONE:FindByName( "DefenseZone" )` would return the ZONE object
-- that was created at mission startup, and reference it into the `TriggerZone` local object.
--
-- Refer to mission `ZON-110` for a demonstration.
--
-- This is especially handy if you want to quickly setup a SET_ZONE...
-- So when you would declare `local SetZone = SET_ZONE:New():FilterPrefixes( "Defense" ):FilterStart()`,
-- then SetZone would contain the ZONE object `DefenseZone` as part of the zone collection,
-- without much scripting overhead!!!
--
--
-- @field #ZONE
ZONE = {
  ClassName="ZONE",
  }


--- Constructor of ZONE taking the zone name.
-- @param #ZONE self
-- @param #string ZoneName The name of the zone as defined within the mission editor.
-- @return #ZONE self
function ZONE:New( ZoneName )

  -- First try to find the zone in the DB.
  local zone=_DATABASE:FindZone(ZoneName)

  if zone then
    --env.info("FF found zone in DB")
    return zone
  end

  -- Get zone from DCS trigger function.
  local Zone = trigger.misc.getZone( ZoneName )

  -- Error!
  if not Zone then
    env.error( "ERROR: Zone " .. ZoneName .. " does not exist!" )
    return nil
  end

  -- Create a new ZONE_RADIUS.
  local self=BASE:Inherit( self, ZONE_RADIUS:New(ZoneName, {x=Zone.point.x, y=Zone.point.z}, Zone.radius, true))
  self:F(ZoneName)

  -- Color of zone.
  self.Color={1, 0, 0, 0.15}

  -- DCS zone.
  self.Zone = Zone

  return self
end

--- Find a zone in the _DATABASE using the name of the zone.
-- @param #ZONE self
-- @param #string ZoneName The name of the zone.
-- @return #ZONE self
function ZONE:FindByName( ZoneName )

  local ZoneFound = _DATABASE:FindZone( ZoneName )
  return ZoneFound
end



--- @type ZONE_UNIT
-- @field Wrapper.Unit#UNIT ZoneUNIT
-- @extends Core.Zone#ZONE_RADIUS


--- # ZONE_UNIT class, extends @{#ZONE_RADIUS}
--
-- The ZONE_UNIT class defined by a zone attached to a @{Wrapper.Unit#UNIT} with a radius and optional offsets.
-- This class implements the inherited functions from @{#ZONE_RADIUS} taking into account the own zone format and properties.
--
-- @field #ZONE_UNIT
ZONE_UNIT = {
  ClassName="ZONE_UNIT",
  }

--- Constructor to create a ZONE_UNIT instance, taking the zone name, a zone unit and a radius and optional offsets in X and Y directions.
-- @param #ZONE_UNIT self
-- @param #string ZoneName Name of the zone.
-- @param Wrapper.Unit#UNIT ZoneUNIT The unit as the center of the zone.
-- @param Dcs.DCSTypes#Distance Radius The radius of the zone.
-- @param #table Offset A table specifying the offset. The offset table may have the following elements:
--  dx The offset in X direction, +x is north.
--  dy The offset in Y direction, +y is east.
--  rho The distance of the zone from the unit
--  theta The azimuth of the zone relative to unit
--  relative_to_unit If true, theta is measured clockwise from unit's direction else clockwise from north. If using dx, dy setting this to true makes +x parallel to unit heading.
--  dx, dy OR rho, theta may be used, not both.
-- @return #ZONE_UNIT self
function ZONE_UNIT:New( ZoneName, ZoneUNIT, Radius, Offset)

  if Offset then
    -- check if the inputs was reasonable, either (dx, dy) or (rho, theta) can be given, else raise an exception.
    if (Offset.dx or Offset.dy) and (Offset.rho or Offset.theta) then
      error("Cannot use (dx, dy) with (rho, theta)")
    end

    self.dy = Offset.dy or 0.0
    self.dx = Offset.dx or 0.0
    self.rho = Offset.rho or 0.0
    self.theta = (Offset.theta or 0.0) * math.pi / 180.0
    self.relative_to_unit = Offset.relative_to_unit or false
  end

  local self = BASE:Inherit( self, ZONE_RADIUS:New( ZoneName, ZoneUNIT:GetVec2(), Radius, true ) )

  self:F( { ZoneName, ZoneUNIT:GetVec2(), Radius } )

  self.ZoneUNIT = ZoneUNIT
  self.LastVec2 = ZoneUNIT:GetVec2()

  -- Zone objects are added to the _DATABASE and SET_ZONE objects.
  _EVENTDISPATCHER:CreateEventNewZone( self )

  return self
end


--- Returns the current location of the @{Wrapper.Unit#UNIT}.
-- @param #ZONE_UNIT self
-- @return DCS#Vec2 The location of the zone based on the @{Wrapper.Unit#UNIT}location and the offset, if any.
function ZONE_UNIT:GetVec2()
  self:F2( self.ZoneName )

  local ZoneVec2 = self.ZoneUNIT:GetVec2()
  if ZoneVec2 then

    local heading
    if self.relative_to_unit then
        heading = ( self.ZoneUNIT:GetHeading() or 0.0 ) * math.pi / 180.0
      else
        heading = 0.0
    end

    -- update the zone position with the offsets.
    if (self.dx or self.dy) then

      -- use heading to rotate offset relative to unit using rotation matrix in 2D.
      -- see: https://en.wikipedia.org/wiki/Rotation_matrix
      ZoneVec2.x = ZoneVec2.x + self.dx * math.cos( -heading ) + self.dy * math.sin( -heading )
      ZoneVec2.y = ZoneVec2.y - self.dx * math.sin( -heading ) + self.dy * math.cos( -heading )
    end

    -- if using the polar coordinates
    if (self.rho or self.theta) then
       ZoneVec2.x = ZoneVec2.x + self.rho * math.cos( self.theta + heading )
       ZoneVec2.y = ZoneVec2.y + self.rho * math.sin( self.theta + heading )
    end

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
-- @return DCS#Vec2 The random location within the zone.
function ZONE_UNIT:GetRandomVec2()
  self:F( self.ZoneName )

  local RandomVec2 = {}
  --local Vec2 = self.ZoneUNIT:GetVec2()  -- FF: This does not take care of the new offset feature!
  local Vec2 = self:GetVec2()

  if not Vec2 then
    Vec2 = self.LastVec2
  end

  local angle = math.random() * math.pi*2;
  RandomVec2.x = Vec2.x + math.cos( angle ) * math.random() * self:GetRadius();
  RandomVec2.y = Vec2.y + math.sin( angle ) * math.random() * self:GetRadius();

  self:T( { RandomVec2 } )

  return RandomVec2
end

--- Returns the @{DCS#Vec3} of the ZONE_UNIT.
-- @param #ZONE_UNIT self
-- @param DCS#Distance Height The height to add to the land height where the center of the zone is located.
-- @return DCS#Vec3 The point of the zone.
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


--- The ZONE_GROUP class defines by a zone around a @{Wrapper.Group#GROUP} with a radius. The current leader of the group defines the center of the zone.
-- This class implements the inherited functions from @{#ZONE_RADIUS} taking into account the own zone format and properties.
--
-- @field #ZONE_GROUP
ZONE_GROUP = {
  ClassName="ZONE_GROUP",
  }

--- Constructor to create a ZONE_GROUP instance, taking the zone name, a zone @{Wrapper.Group#GROUP} and a radius.
-- @param #ZONE_GROUP self
-- @param #string ZoneName Name of the zone.
-- @param Wrapper.Group#GROUP ZoneGROUP The @{Wrapper.Group} as the center of the zone.
-- @param DCS#Distance Radius The radius of the zone.
-- @return #ZONE_GROUP self
function ZONE_GROUP:New( ZoneName, ZoneGROUP, Radius )
  local self = BASE:Inherit( self, ZONE_RADIUS:New( ZoneName, ZoneGROUP:GetVec2(), Radius, true ) )
  self:F( { ZoneName, ZoneGROUP:GetVec2(), Radius } )

  self._.ZoneGROUP = ZoneGROUP
  self._.ZoneVec2Cache = self._.ZoneGROUP:GetVec2()

  -- Zone objects are added to the _DATABASE and SET_ZONE objects.
  _EVENTDISPATCHER:CreateEventNewZone( self )

  return self
end


--- Returns the current location of the @{Wrapper.Group}.
-- @param #ZONE_GROUP self
-- @return DCS#Vec2 The location of the zone based on the @{Wrapper.Group} location.
function ZONE_GROUP:GetVec2()
  self:F( self.ZoneName )

  local ZoneVec2 = nil

  if self._.ZoneGROUP:IsAlive() then
    ZoneVec2 = self._.ZoneGROUP:GetVec2()
    self._.ZoneVec2Cache = ZoneVec2
  else
    ZoneVec2 = self._.ZoneVec2Cache
  end

  self:T( { ZoneVec2 } )

  return ZoneVec2
end

--- Returns a random location within the zone of the @{Wrapper.Group}.
-- @param #ZONE_GROUP self
-- @return DCS#Vec2 The random location of the zone based on the @{Wrapper.Group} location.
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

--- Returns a @{Core.Point#POINT_VEC2} object reflecting a random 2D location within the zone.
-- @param #ZONE_GROUP self
-- @param #number inner (optional) Minimal distance from the center of the zone. Default is 0.
-- @param #number outer (optional) Maximal distance from the outer edge of the zone. Default is the radius of the zone.
-- @return Core.Point#POINT_VEC2 The @{Core.Point#POINT_VEC2} object reflecting the random 3D location within the zone.
function ZONE_GROUP:GetRandomPointVec2( inner, outer )
  self:F( self.ZoneName, inner, outer )

  local PointVec2 = POINT_VEC2:NewFromVec2( self:GetRandomVec2() )

  self:T3( { PointVec2 } )

  return PointVec2
end


--- @type ZONE_POLYGON_BASE
-- @field #ZONE_POLYGON_BASE.ListVec2 Polygon The polygon defined by an array of @{DCS#Vec2}.
-- @extends #ZONE_BASE


--- The ZONE_POLYGON_BASE class defined by a sequence of @{Wrapper.Group#GROUP} waypoints within the Mission Editor, forming a polygon.
-- This class implements the inherited functions from @{#ZONE_RADIUS} taking into account the own zone format and properties.
-- This class is an abstract BASE class for derived classes, and is not meant to be instantiated.
--
-- ## Zone point randomization
--
-- Various functions exist to find random points within the zone.
--
--   * @{#ZONE_POLYGON_BASE.GetRandomVec2}(): Gets a random 2D point in the zone.
--   * @{#ZONE_POLYGON_BASE.GetRandomPointVec2}(): Return a @{Core.Point#POINT_VEC2} object representing a random 2D point within the zone.
--   * @{#ZONE_POLYGON_BASE.GetRandomPointVec3}(): Return a @{Core.Point#POINT_VEC3} object representing a random 3D point at landheight within the zone.
--
-- ## Draw zone
--
--   * @{#ZONE_POLYGON_BASE.DrawZone}(): Draws the zone on the F10 map.
--   * @{#ZONE_POLYGON_BASE.Boundary}(): Draw a frontier on the F10 map with small filled circles.
--
--
-- @field #ZONE_POLYGON_BASE
ZONE_POLYGON_BASE = {
  ClassName="ZONE_POLYGON_BASE",
  }

--- A 2D points array.
-- @type ZONE_POLYGON_BASE.ListVec2
-- @list <DCS#Vec2> Table of 2D vectors.

--- A 3D points array.
-- @type ZONE_POLYGON_BASE.ListVec3
-- @list <DCS#Vec3> Table of 3D vectors.

--- Constructor to create a ZONE_POLYGON_BASE instance, taking the zone name and an array of @{DCS#Vec2}, forming a polygon.
-- The @{Wrapper.Group#GROUP} waypoints define the polygon corners. The first and the last point are automatically connected.
-- @param #ZONE_POLYGON_BASE self
-- @param #string ZoneName Name of the zone.
-- @param #ZONE_POLYGON_BASE.ListVec2 PointsArray An array of @{DCS#Vec2}, forming a polygon.
-- @return #ZONE_POLYGON_BASE self
function ZONE_POLYGON_BASE:New( ZoneName, PointsArray )

  -- Inherit ZONE_BASE.
  local self = BASE:Inherit( self, ZONE_BASE:New( ZoneName ) )
  self:F( { ZoneName, PointsArray } )

  if PointsArray then

    self._.Polygon = {}

    for i = 1, #PointsArray do
      self._.Polygon[i] = {}
      self._.Polygon[i].x = PointsArray[i].x
      self._.Polygon[i].y = PointsArray[i].y
    end

  end

  return self
end

--- Update polygon points with an array of @{DCS#Vec2}.
-- @param #ZONE_POLYGON_BASE self
-- @param #ZONE_POLYGON_BASE.ListVec2 Vec2Array An array of @{DCS#Vec2}, forming a polygon.
-- @return #ZONE_POLYGON_BASE self
function ZONE_POLYGON_BASE:UpdateFromVec2(Vec2Array)

  self._.Polygon = {}

  for i=1,#Vec2Array do
    self._.Polygon[i] = {}
    self._.Polygon[i].x=Vec2Array[i].x
    self._.Polygon[i].y=Vec2Array[i].y
  end

  return self
end

--- Update polygon points with an array of @{DCS#Vec3}.
-- @param #ZONE_POLYGON_BASE self
-- @param #ZONE_POLYGON_BASE.ListVec3 Vec2Array An array of @{DCS#Vec3}, forming a polygon.
-- @return #ZONE_POLYGON_BASE self
function ZONE_POLYGON_BASE:UpdateFromVec3(Vec3Array)

  self._.Polygon = {}

  for i=1,#Vec3Array do
    self._.Polygon[i] = {}
    self._.Polygon[i].x=Vec3Array[i].x
    self._.Polygon[i].y=Vec3Array[i].z
  end

  return self
end

--- Returns the center location of the polygon.
-- @param #ZONE_POLYGON_BASE self
-- @return DCS#Vec2 The location of the zone based on the @{Wrapper.Group} location.
function ZONE_POLYGON_BASE:GetVec2()
  self:F( self.ZoneName )

  local Bounds = self:GetBoundingSquare()

  return { x = ( Bounds.x2 + Bounds.x1 ) / 2, y = ( Bounds.y2 + Bounds.y1 ) / 2 }
end

--- Get a vertex of the polygon.
-- @param #ZONE_POLYGON_BASE self
-- @param #number Index Index of the vertex. Default 1.
-- @return DCS#Vec2 Vertex of the polygon.
function ZONE_POLYGON_BASE:GetVertexVec2(Index)
  return self._.Polygon[Index or 1]
end

--- Get a vertex of the polygon.
-- @param #ZONE_POLYGON_BASE self
-- @param #number Index Index of the vertex. Default 1.
-- @return DCS#Vec3 Vertex of the polygon.
function ZONE_POLYGON_BASE:GetVertexVec3(Index)
  local vec2=self:GetVertexVec2(Index)
  if vec2 then
    local vec3={x=vec2.x, y=land.getHeight(vec2), z=vec2.y}
    return vec3
  end
  return nil
end

--- Get a vertex of the polygon.
-- @param #ZONE_POLYGON_BASE self
-- @param #number Index Index of the vertex. Default 1.
-- @return Core.Point#COORDINATE Vertex of the polygon.
function ZONE_POLYGON_BASE:GetVertexCoordinate(Index)
  local vec2=self:GetVertexVec2(Index)
  if vec2 then
    local coord=COORDINATE:NewFromVec2(vec2)
    return coord
  end
  return nil
end


--- Get a list of verticies of the polygon.
-- @param #ZONE_POLYGON_BASE self
-- @return <DCS#Vec2> List of DCS#Vec2 verticies defining the edges of the polygon.
function ZONE_POLYGON_BASE:GetVerticiesVec2()
  return self._.Polygon
end

--- Get a list of verticies of the polygon.
-- @param #ZONE_POLYGON_BASE self
-- @return #table List of DCS#Vec3 verticies defining the edges of the polygon.
function ZONE_POLYGON_BASE:GetVerticiesVec3()

  local coords={}

  for i,vec2 in ipairs(self._.Polygon) do
    local vec3={x=vec2.x, y=land.getHeight(vec2), z=vec2.y}
    table.insert(coords, vec3)
  end

  return coords
end

--- Get a list of verticies of the polygon.
-- @param #ZONE_POLYGON_BASE self
-- @return #table List of COORDINATES verticies defining the edges of the polygon.
function ZONE_POLYGON_BASE:GetVerticiesCoordinates()

  local coords={}

  for i,vec2 in ipairs(self._.Polygon) do
    local coord=COORDINATE:NewFromVec2(vec2)
    table.insert(coords, coord)
  end

  return coords
end

--- Flush polygon coordinates as a table in DCS.log.
-- @param #ZONE_POLYGON_BASE self
-- @return #ZONE_POLYGON_BASE self
function ZONE_POLYGON_BASE:Flush()
  self:F2()

  self:F( { Polygon = self.ZoneName, Coordinates = self._.Polygon } )

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

--- Draw the zone on the F10 map.  **NOTE** Currently, only polygons **up to ten points** are supported!
-- @param #ZONE_POLYGON_BASE self
-- @param #number Coalition Coalition: All=-1, Neutral=0, Red=1, Blue=2. Default -1=All.
-- @param #table Color RGB color table {r, g, b}, e.g. {1,0,0} for red.
-- @param #number Alpha Transparency [0,1]. Default 1.
-- @param #table FillColor RGB color table {r, g, b}, e.g. {1,0,0} for red. Default is same as `Color` value.
-- @param #number FillAlpha Transparency [0,1]. Default 0.15.
-- @param #number LineType Line type: 0=No line, 1=Solid, 2=Dashed, 3=Dotted, 4=Dot dash, 5=Long dash, 6=Two dash. Default 1=Solid.
-- @param #boolean ReadOnly (Optional) Mark is readonly and cannot be removed by users. Default false.
-- @return #ZONE_POLYGON_BASE self
function ZONE_POLYGON_BASE:DrawZone(Coalition, Color, Alpha, FillColor, FillAlpha, LineType, ReadOnly)

  if self._.Polygon and #self._.Polygon>=3 then

    local coordinate=COORDINATE:NewFromVec2(self._.Polygon[1])

    Coalition=Coalition or self:GetDrawCoalition()

    -- Set draw coalition.
    self:SetDrawCoalition(Coalition)

    Color=Color or self:GetColorRGB()
    Alpha=Alpha or 1

    -- Set color.
    self:SetColor(Color, Alpha)

    FillColor=FillColor or self:GetFillColorRGB()
    if not FillColor then UTILS.DeepCopy(Color) end
    FillAlpha=FillAlpha or self:GetFillColorAlpha()
    if not FillAlpha then FillAlpha=0.15 end

    -- Set fill color.
    self:SetFillColor(FillColor, FillAlpha)

    if #self._.Polygon==4 then

      local Coord2=COORDINATE:NewFromVec2(self._.Polygon[2])
      local Coord3=COORDINATE:NewFromVec2(self._.Polygon[3])
      local Coord4=COORDINATE:NewFromVec2(self._.Polygon[4])

      self.DrawID=coordinate:QuadToAll(Coord2, Coord3, Coord4, Coalition, Color, Alpha, FillColor, FillAlpha, LineType, ReadOnly)

    else

      local Coordinates=self:GetVerticiesCoordinates()
      table.remove(Coordinates, 1)

      self.DrawID=coordinate:MarkupToAllFreeForm(Coordinates, Coalition, Color, Alpha, FillColor, FillAlpha, LineType, ReadOnly)

    end

  end

  return self
end

--- Get the smallest radius encompassing all points of the polygon zone. 
-- @param #ZONE_POLYGON_BASE self
-- @return #number Radius of the zone in meters.
function ZONE_POLYGON_BASE:GetRadius()

  local center=self:GetVec2()

  local radius=0
    
  for _,_vec2 in pairs(self._.Polygon) do
    local vec2=_vec2 --DCS#Vec2
    
    local r=UTILS.VecDist2D(center, vec2)
    
    if r>radius then
      radius=r
    end
    
  end

  return radius
end

--- Get the smallest circular zone encompassing all points of the polygon zone. 
-- @param #ZONE_POLYGON_BASE self
-- @param #string ZoneName (Optional) Name of the zone. Default is the name of the polygon zone.
-- @param #boolean DoNotRegisterZone (Optional) If `true`, zone is not registered.
-- @return #ZONE_RADIUS The circular zone.
function ZONE_POLYGON_BASE:GetZoneRadius(ZoneName, DoNotRegisterZone)

  local center=self:GetVec2()

  local radius=self:GetRadius()
  
  local zone=ZONE_RADIUS:New(ZoneName or self.ZoneName, center, radius, DoNotRegisterZone)

  return zone
end


--- Get the smallest rectangular zone encompassing all points points of the polygon zone. 
-- @param #ZONE_POLYGON_BASE self
-- @param #string ZoneName (Optional) Name of the zone. Default is the name of the polygon zone.
-- @param #boolean DoNotRegisterZone (Optional) If `true`, zone is not registered.
-- @return #ZONE_POLYGON The rectangular zone.
function ZONE_POLYGON_BASE:GetZoneQuad(ZoneName, DoNotRegisterZone)
 
  local vec1, vec3=self:GetBoundingVec2()
  
  local vec2={x=vec1.x, y=vec3.y}
  local vec4={x=vec3.x, y=vec1.y}
  
  local zone=ZONE_POLYGON_BASE:New(ZoneName or self.ZoneName, {vec1, vec2, vec3, vec4})

  return zone
end

--- Remove junk inside the zone. Due to DCS limitations, this works only for rectangular zones. So we get the smallest rectangular zone encompassing all points points of the polygon zone.
-- @param #ZONE_POLYGON_BASE self
-- @param #number Height Height of the box in meters. Default 1000.
-- @return #number Number of removed objects.
function ZONE_POLYGON_BASE:RemoveJunk(Height)

  Height=Height or 1000
 
  local vec2SW, vec2NE=self:GetBoundingVec2()

  local vec3SW={x=vec2SW.x, y=-Height, z=vec2SW.y} --DCS#Vec3
  local vec3NE={x=vec2NE.x, y= Height, z=vec2NE.y} --DCS#Vec3
  
  --local coord1=COORDINATE:NewFromVec3(vec3SW):MarkToAll("SW")
  --local coord1=COORDINATE:NewFromVec3(vec3NE):MarkToAll("NE")
  
  local volume = {
    id = world.VolumeType.BOX,
    params = {
      min=vec3SW,
      max=vec3SW
    }
  }

  local n=world.removeJunk(volume)  

  return n
end

--- Smokes the zone boundaries in a color.
-- @param #ZONE_POLYGON_BASE self
-- @param Utilities.Utils#SMOKECOLOR SmokeColor The smoke color.
-- @param #number Segments (Optional) Number of segments within boundary line. Default 10.
-- @return #ZONE_POLYGON_BASE self
function ZONE_POLYGON_BASE:SmokeZone( SmokeColor, Segments )
  self:F2( SmokeColor )

  Segments=Segments or 10

  local i=1
  local j=#self._.Polygon

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

--- Flare the zone boundaries in a color.
-- @param #ZONE_POLYGON_BASE self
-- @param Utilities.Utils#FLARECOLOR FlareColor The flare color.
-- @param #number Segments (Optional) Number of segments within boundary line. Default 10.
-- @param DCS#Azimuth Azimuth (optional) Azimuth The azimuth of the flare.
-- @param #number AddHeight (optional) The height to be added for the smoke.
-- @return #ZONE_POLYGON_BASE self
function ZONE_POLYGON_BASE:FlareZone( FlareColor, Segments, Azimuth, AddHeight )
  self:F2(FlareColor)

  Segments=Segments or 10

  AddHeight = AddHeight or 0

  local i=1
  local j=#self._.Polygon

  while i <= #self._.Polygon do
    self:T( { i, j, self._.Polygon[i], self._.Polygon[j] } )

    local DeltaX = self._.Polygon[j].x - self._.Polygon[i].x
    local DeltaY = self._.Polygon[j].y - self._.Polygon[i].y

    for Segment = 0, Segments do -- We divide each line in 5 segments and smoke a point on the line.
      local PointX = self._.Polygon[i].x + ( Segment * DeltaX / Segments )
      local PointY = self._.Polygon[i].y + ( Segment * DeltaY / Segments )
      POINT_VEC2:New( PointX, PointY, AddHeight ):Flare(FlareColor, Azimuth)
    end
    j = i
    i = i + 1
  end

  return self
end

--- Returns if a location is within the zone.
-- Source learned and taken from: https://www.ecse.rpi.edu/Homepages/wrf/Research/Short_Notes/pnpoly.html
-- @param #ZONE_POLYGON_BASE self
-- @param DCS#Vec2 Vec2 The location to test.
-- @return #boolean true if the location is within the zone.
function ZONE_POLYGON_BASE:IsVec2InZone( Vec2 )
  self:F2( Vec2 )
  if not Vec2 then return false end 
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

--- Returns if a point is within the zone.
-- @param #ZONE_POLYGON_BASE self
-- @param DCS#Vec3 Vec3 The point to test.
-- @return #boolean true if the point is within the zone.
function ZONE_POLYGON_BASE:IsVec3InZone( Vec3 )
  self:F2( Vec3 )
  
  if not Vec3 then return false end 
    
  local InZone = self:IsVec2InZone( { x = Vec3.x, y = Vec3.z } )

  return InZone
end

--- Define a random @{DCS#Vec2} within the zone.
-- @param #ZONE_POLYGON_BASE self
-- @return DCS#Vec2 The Vec2 coordinate.
function ZONE_POLYGON_BASE:GetRandomVec2()

  -- It is a bit tricky to find a random point within a polygon. Right now i am doing it the dirty and inefficient way...

  -- Get the bounding square.
  local BS = self:GetBoundingSquare()

  local Nmax=1000 ; local n=0
  while n<Nmax do

    -- Random point in the bounding square.
    local Vec2={x=math.random(BS.x1, BS.x2), y=math.random(BS.y1, BS.y2)}

    -- Check if this is in the polygon.
    if self:IsVec2InZone(Vec2) then
      return Vec2
    end

    n=n+1
  end

  self:E("Could not find a random point in the polygon zone!")
  return nil
end

--- Return a @{Core.Point#POINT_VEC2} object representing a random 2D point at landheight within the zone.
-- @param #ZONE_POLYGON_BASE self
-- @return @{Core.Point#POINT_VEC2}
function ZONE_POLYGON_BASE:GetRandomPointVec2()
  self:F2()

  local PointVec2 = POINT_VEC2:NewFromVec2( self:GetRandomVec2() )

  self:T2( PointVec2 )

  return PointVec2
end

--- Return a @{Core.Point#POINT_VEC3} object representing a random 3D point at landheight within the zone.
-- @param #ZONE_POLYGON_BASE self
-- @return @{Core.Point#POINT_VEC3}
function ZONE_POLYGON_BASE:GetRandomPointVec3()
  self:F2()

  local PointVec3 = POINT_VEC3:NewFromVec2( self:GetRandomVec2() )

  self:T2( PointVec3 )

  return PointVec3
end


--- Return a @{Core.Point#COORDINATE} object representing a random 3D point at landheight within the zone.
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

--- Get the bounding 2D vectors of the polygon.
-- @param #ZONE_POLYGON_BASE self
-- @return DCS#Vec2 Coordinates of western-southern-lower vertex of the box.
-- @return DCS#Vec2 Coordinates of eastern-northern-upper vertex of the box.
function ZONE_POLYGON_BASE:GetBoundingVec2()

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
  
  local vec1={x=x1, y=y1}
  local vec2={x=x2, y=y2}

  return vec1, vec2
end

--- Draw a frontier on the F10 map with small filled circles.
-- @param #ZONE_POLYGON_BASE self
-- @param #number Coalition (Optional) Coalition: All=-1, Neutral=0, Red=1, Blue=2. Default -1= All.
-- @param #table Color (Optional) RGB color table {r, g, b}, e.g. {1, 0, 0} for red. Default {1, 1, 1}= White.
-- @param #number Radius (Optional) Radius of the circles in meters. Default 1000.
-- @param #number Alpha (Optional) Alpha transparency [0,1]. Default 1.
-- @param #number Segments (Optional) Number of segments within boundary line. Default 10.
-- @param #boolean Closed (Optional) Link the last point with the first one to obtain a closed boundary. Default false
-- @return #ZONE_POLYGON_BASE self
function ZONE_POLYGON_BASE:Boundary(Coalition, Color, Radius, Alpha, Segments, Closed)
    Coalition = Coalition or -1
    Color = Color or {1, 1, 1}
    Radius = Radius or 1000
    Alpha = Alpha or 1
    Segments = Segments or 10
    Closed = Closed or false
    local i = 1
    local j = #self._.Polygon
    if (Closed) then
        Limit = #self._.Polygon + 1
    else
        Limit = #self._.Polygon
    end
    while i <= #self._.Polygon do
        self:T( { i, j, self._.Polygon[i], self._.Polygon[j] } )
        if j ~= Limit then
            local DeltaX = self._.Polygon[j].x - self._.Polygon[i].x
            local DeltaY = self._.Polygon[j].y - self._.Polygon[i].y
            for Segment = 0, Segments do
                local PointX = self._.Polygon[i].x + ( Segment * DeltaX / Segments )
                local PointY = self._.Polygon[i].y + ( Segment * DeltaY / Segments )
                --ZONE_RADIUS:New( "Zone", {x = PointX, y = PointY}, Radius ):DrawZone(Coalition, Color, 1, Color, Alpha, nil, true)
            end
        end
        j = i
        i = i + 1
    end
    return self
end

--- @type ZONE_POLYGON
-- @extends #ZONE_POLYGON_BASE


--- The ZONE_POLYGON class defined by a sequence of @{Wrapper.Group#GROUP} waypoints within the Mission Editor, forming a polygon.
-- This class implements the inherited functions from @{#ZONE_RADIUS} taking into account the own zone format and properties.
--
-- ## Declare a ZONE_POLYGON directly in the DCS mission editor!
--
-- You can declare a ZONE_POLYGON using the DCS mission editor by adding the #ZONE_POLYGON tag in the group name.
--
-- So, imagine you have a group declared in the mission editor, with group name `DefenseZone#ZONE_POLYGON`.
-- Then during mission startup, when loading Moose.lua, this group will be detected as a ZONE_POLYGON declaration.
-- Within the background, a ZONE_POLYGON object will be created within the @{Core.Database} using the properties of the group.
-- The ZONE_POLYGON name will be the group name without the #ZONE_POLYGON tag.
--
-- So, you can search yourself for the ZONE_POLYGON by using the @{#ZONE_POLYGON.FindByName}() method.
-- In this example, `local PolygonZone = ZONE_POLYGON:FindByName( "DefenseZone" )` would return the ZONE_POLYGON object
-- that was created at mission startup, and reference it into the `PolygonZone` local object.
--
-- Mission `ZON-510` shows a demonstration of this feature or method.
--
-- This is especially handy if you want to quickly setup a SET_ZONE...
-- So when you would declare `local SetZone = SET_ZONE:New():FilterPrefixes( "Defense" ):FilterStart()`,
-- then SetZone would contain the ZONE_POLYGON object `DefenseZone` as part of the zone collection,
-- without much scripting overhead!
--
-- @field #ZONE_POLYGON
ZONE_POLYGON = {
  ClassName="ZONE_POLYGON",
  }

--- Constructor to create a ZONE_POLYGON instance, taking the zone name and the @{Wrapper.Group#GROUP} defined within the Mission Editor.
-- The @{Wrapper.Group#GROUP} waypoints define the polygon corners. The first and the last point are automatically connected by ZONE_POLYGON.
-- @param #ZONE_POLYGON self
-- @param #string ZoneName Name of the zone.
-- @param Wrapper.Group#GROUP ZoneGroup The GROUP waypoints as defined within the Mission Editor define the polygon shape.
-- @return #ZONE_POLYGON self
function ZONE_POLYGON:New( ZoneName, ZoneGroup )

  local GroupPoints = ZoneGroup:GetTaskRoute()

  local self = BASE:Inherit( self, ZONE_POLYGON_BASE:New( ZoneName, GroupPoints ) )
  self:F( { ZoneName, ZoneGroup, self._.Polygon } )

  -- Zone objects are added to the _DATABASE and SET_ZONE objects.
  _EVENTDISPATCHER:CreateEventNewZone( self )

  return self
end

--- Constructor to create a ZONE_POLYGON instance, taking the zone name and an array of DCS#Vec2, forming a polygon.
-- @param #ZONE_POLYGON self
-- @param #string ZoneName Name of the zone.
-- @param  #ZONE_POLYGON_BASE.ListVec2 PointsArray An array of @{DCS#Vec2}, forming a polygon.
-- @return #ZONE_POLYGON self
function ZONE_POLYGON:NewFromPointsArray( ZoneName, PointsArray )

  local self = BASE:Inherit( self, ZONE_POLYGON_BASE:New( ZoneName, PointsArray ) )
  self:F( { ZoneName, self._.Polygon } )

  -- Zone objects are added to the _DATABASE and SET_ZONE objects.
  _EVENTDISPATCHER:CreateEventNewZone( self )

  return self
end

--- Constructor to create a ZONE_POLYGON instance, taking the zone name and the **name** of the @{Wrapper.Group#GROUP} defined within the Mission Editor.
-- The @{Wrapper.Group#GROUP} waypoints define the polygon corners. The first and the last point are automatically connected by ZONE_POLYGON.
-- @param #ZONE_POLYGON self
-- @param #string GroupName The group name of the GROUP defining the waypoints within the Mission Editor to define the polygon shape.
-- @return #ZONE_POLYGON self
function ZONE_POLYGON:NewFromGroupName( GroupName )

  local ZoneGroup = GROUP:FindByName( GroupName )

  local GroupPoints = ZoneGroup:GetTaskRoute()

  local self = BASE:Inherit( self, ZONE_POLYGON_BASE:New( GroupName, GroupPoints ) )
  self:F( { GroupName, ZoneGroup, self._.Polygon } )

  -- Zone objects are added to the _DATABASE and SET_ZONE objects.
  _EVENTDISPATCHER:CreateEventNewZone( self )

  return self
end


--- Find a polygon zone in the _DATABASE using the name of the polygon zone.
-- @param #ZONE_POLYGON self
-- @param #string ZoneName The name of the polygon zone.
-- @return #ZONE_POLYGON self
function ZONE_POLYGON:FindByName( ZoneName )

  local ZoneFound = _DATABASE:FindZone( ZoneName )
  return ZoneFound
end

--- Scan the zone for the presence of units of the given ObjectCategories. Does **not** scan for scenery at the moment.
-- Note that **only after** a zone has been scanned, the zone can be evaluated by:
--
--   * @{ZONE_POLYGON.IsAllInZoneOfCoalition}(): Scan the presence of units in the zone of a coalition.
--   * @{ZONE_POLYGON.IsAllInZoneOfOtherCoalition}(): Scan the presence of units in the zone of an other coalition.
--   * @{ZONE_POLYGON.IsSomeInZoneOfCoalition}(): Scan if there is some presence of units in the zone of the given coalition.
--   * @{ZONE_POLYGON.IsNoneInZoneOfCoalition}(): Scan if there isn't any presence of units in the zone of an other coalition than the given one.
--   * @{ZONE_POLYGON.IsNoneInZone}(): Scan if the zone is empty.
-- @param #ZONE_POLYGON self
-- @param ObjectCategories An array of categories of the objects to find in the zone. E.g. `{Object.Category.UNIT}`
-- @param UnitCategories An array of unit categories of the objects to find in the zone. E.g. `{Unit.Category.GROUND_UNIT,Unit.Category.SHIP}`
-- @usage
--    myzone:Scan({Object.Category.UNIT},{Unit.Category.GROUND_UNIT})
--    local IsAttacked = myzone:IsSomeInZoneOfCoalition( self.Coalition )
function ZONE_POLYGON:Scan( ObjectCategories, UnitCategories )

  self.ScanData = {}
  self.ScanData.Coalitions = {}
  self.ScanData.Scenery = {}
  self.ScanData.SceneryTable = {}
  self.ScanData.Units = {}
  
  local vectors = self:GetBoundingSquare()
  
  local minVec3 = {x=vectors.x1, y=0, z=vectors.y1}
  local maxVec3 = {x=vectors.x2, y=0, z=vectors.y2}
  
  local minmarkcoord = COORDINATE:NewFromVec3(minVec3)
  local maxmarkcoord = COORDINATE:NewFromVec3(maxVec3)
  local ZoneRadius = minmarkcoord:Get2DDistance(maxmarkcoord)/2
  
  local CenterVec3 = self:GetCoordinate():GetVec3()
  
 --[[ this a bit shaky in functionality it seems
  local VolumeBox = {
   id = world.VolumeType.BOX,
   params = {
     min = minVec3,
     max = maxVec3
   }
  }
  --]]
  
  local SphereSearch = {
  id = world.VolumeType.SPHERE,
    params = {
    point = CenterVec3,
    radius = ZoneRadius,
    }
  }
    
  local function EvaluateZone( ZoneObject )

    if ZoneObject then

      local ObjectCategory = ZoneObject:getCategory()
      
      if ( ObjectCategory == Object.Category.UNIT and ZoneObject:isExist() and ZoneObject:isActive() ) or (ObjectCategory == Object.Category.STATIC and ZoneObject:isExist()) then

        local CoalitionDCSUnit = ZoneObject:getCoalition()

        local Include = false
        if not UnitCategories then
          -- Anything found is included.
          Include = true
        else
          -- Check if found object is in specified categories.
          local CategoryDCSUnit = ZoneObject:getDesc().category

          for UnitCategoryID, UnitCategory in pairs( UnitCategories ) do
            if UnitCategory == CategoryDCSUnit then
              Include = true
              break
            end
          end

        end

        if Include then

          local CoalitionDCSUnit = ZoneObject:getCoalition()

          -- This coalition is inside the zone.
          self.ScanData.Coalitions[CoalitionDCSUnit] = true

          self.ScanData.Units[ZoneObject] = ZoneObject

          self:F2( { Name = ZoneObject:getName(), Coalition = CoalitionDCSUnit } )
        end
      end
      
      -- trying with box search
      if ObjectCategory == Object.Category.SCENERY and self:IsVec3InZone(ZoneObject:getPoint()) then
        local SceneryType = ZoneObject:getTypeName()
        local SceneryName = ZoneObject:getName()
        self.ScanData.Scenery[SceneryType] = self.ScanData.Scenery[SceneryType] or {}
        self.ScanData.Scenery[SceneryType][SceneryName] = SCENERY:Register( SceneryName, ZoneObject )
        table.insert(self.ScanData.SceneryTable,self.ScanData.Scenery[SceneryType][SceneryName])
        self:T( { SCENERY =  self.ScanData.Scenery[SceneryType][SceneryName] } )
      end

    end

    return true
  end

  -- Search objects.
  local inzoneunits = SET_UNIT:New():FilterZones({self}):FilterOnce()
  local inzonestatics = SET_STATIC:New():FilterZones({self}):FilterOnce()
  
  inzoneunits:ForEach(
    function(unit)
      local Unit = unit --Wrapper.Unit#UNIT
      local DCS = Unit:GetDCSObject()
      EvaluateZone(DCS)
    end
  )
  
  inzonestatics:ForEach(
    function(static)
      local Static = static --Wrapper.Static#STATIC
      local DCS = Static:GetDCSObject()
      EvaluateZone(DCS)
    end
  )
  
  local searchscenery = false
  for _,_type in pairs(ObjectCategories) do
    if _type == Object.Category.SCENERY then
      searchscenery = true
    end
  end
  
  if searchscenery then
    -- Search objects.
    world.searchObjects({Object.Category.SCENERY}, SphereSearch, EvaluateZone )
  end
  
end

--- Count the number of different coalitions inside the zone.
-- @param #ZONE_POLYGON self
-- @return #table Table of DCS units and DCS statics inside the zone.
function ZONE_POLYGON:GetScannedUnits()
  return self.ScanData.Units
end

--- Get a set of scanned units.
-- @param #ZONE_POLYGON self
-- @return Core.Set#SET_UNIT Set of units and statics inside the zone.
function ZONE_POLYGON:GetScannedSetUnit()

  local SetUnit = SET_UNIT:New()

  if self.ScanData then
    for ObjectID, UnitObject in pairs( self.ScanData.Units ) do
      local UnitObject = UnitObject -- DCS#Unit
      if UnitObject:isExist() then
        local FoundUnit = UNIT:FindByName( UnitObject:getName() )
        if FoundUnit then
          SetUnit:AddUnit( FoundUnit )
        else
          local FoundStatic = STATIC:FindByName( UnitObject:getName() )
          if FoundStatic then
            SetUnit:AddUnit( FoundStatic )
          end
        end
      end
    end
  end

  return SetUnit
end

--- Get a set of scanned units.
-- @param #ZONE_POLYGON self
-- @return Core.Set#SET_GROUP Set of groups.
function ZONE_POLYGON:GetScannedSetGroup()

  self.ScanSetGroup=self.ScanSetGroup or SET_GROUP:New() --Core.Set#SET_GROUP

  self.ScanSetGroup.Set={}

  if self.ScanData then
    for ObjectID, UnitObject in pairs( self.ScanData.Units ) do
      local UnitObject = UnitObject -- DCS#Unit
      if UnitObject:isExist() then

        local FoundUnit=UNIT:FindByName(UnitObject:getName())
        if FoundUnit then
          local group=FoundUnit:GetGroup()
          self.ScanSetGroup:AddGroup(group)
        end
      end
    end
  end

  return self.ScanSetGroup
end

--- Count the number of different coalitions inside the zone.
-- @param #ZONE_POLYGON self
-- @return #number Counted coalitions.
function ZONE_POLYGON:CountScannedCoalitions()

  local Count = 0

  for CoalitionID, Coalition in pairs( self.ScanData.Coalitions ) do
    Count = Count + 1
  end

  return Count
end

--- Check if a certain coalition is inside a scanned zone.
-- @param #ZONE_POLYGON self
-- @param #number Coalition The coalition id, e.g. coalition.side.BLUE.
-- @return #boolean If true, the coalition is inside the zone.
function ZONE_POLYGON:CheckScannedCoalition( Coalition )
  if Coalition then
    return self.ScanData.Coalitions[Coalition]
  end
  return nil
end

--- Get Coalitions of the units in the Zone, or Check if there are units of the given Coalition in the Zone.
-- Returns nil if there are none to two Coalitions in the zone!
-- Returns one Coalition if there are only Units of one Coalition in the Zone.
-- Returns the Coalition for the given Coalition if there are units of the Coalition in the Zone.
-- @param #ZONE_POLYGON self
-- @return #table
function ZONE_POLYGON:GetScannedCoalition( Coalition )

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

--- Get scanned scenery types
-- @param #ZONE_POLYGON self
-- @return #table Table of DCS scenery type objects.
function ZONE_POLYGON:GetScannedSceneryType( SceneryType )
  return self.ScanData.Scenery[SceneryType]
end

--- Get scanned scenery table
-- @param #ZONE_POLYGON self
-- @return #table Table of Wrapper.Scenery#SCENERY scenery objects.
function ZONE_POLYGON:GetScannedSceneryObjects()
  return self.ScanData.SceneryTable
end

--- Get scanned scenery table
-- @param #ZONE_POLYGON self
-- @return #table Structured table of [type].[name].Wrapper.Scenery#SCENERY scenery objects.
function ZONE_POLYGON:GetScannedScenery()
  return self.ScanData.Scenery
end

--- Get scanned set of scenery objects
-- @param #ZONE_POLYGON self
-- @return #table Table of Wrapper.Scenery#SCENERY scenery objects.
function ZONE_POLYGON:GetScannedSetScenery()
  local scenery = SET_SCENERY:New()
  local objects = self:GetScannedSceneryObjects()
  for _,_obj in pairs (objects) do
    scenery:AddScenery(_obj)
  end
  return scenery
end

--- Is All in Zone of Coalition?
-- Check if only the specified coalition is inside the zone and noone else.
-- @param #ZONE_POLYGON self
-- @param #number Coalition Coalition ID of the coalition which is checked to be the only one in the zone.
-- @return #boolean True, if **only** that coalition is inside the zone and no one else.
-- @usage
--    self.Zone:Scan()
--    local IsGuarded = self.Zone:IsAllInZoneOfCoalition( self.Coalition )
function ZONE_POLYGON:IsAllInZoneOfCoalition( Coalition )
  return self:CountScannedCoalitions() == 1 and self:GetScannedCoalition( Coalition ) == true
end

--- Is All in Zone of Other Coalition?
-- Check if only one coalition is inside the zone and the specified coalition is not the one.
-- You first need to use the @{#ZONE_POLYGON.Scan} method to scan the zone before it can be evaluated!
-- Note that once a zone has been scanned, multiple evaluations can be done on the scan result set.
-- @param #ZONE_POLYGON self
-- @param #number Coalition Coalition ID of the coalition which is not supposed to be in the zone.
-- @return #boolean True, if and only if only one coalition is inside the zone and the specified coalition is not it.
-- @usage
--    self.Zone:Scan()
--    local IsCaptured = self.Zone:IsAllInZoneOfOtherCoalition( self.Coalition )
function ZONE_POLYGON:IsAllInZoneOfOtherCoalition( Coalition )
  return self:CountScannedCoalitions() == 1 and self:GetScannedCoalition( Coalition ) == nil
end

--- Is Some in Zone of Coalition?
-- Check if more than one coalition is inside the zone and the specified coalition is one of them.
-- You first need to use the @{#ZONE_POLYGON.Scan} method to scan the zone before it can be evaluated!
-- Note that once a zone has been scanned, multiple evaluations can be done on the scan result set.
-- @param #ZONE_POLYGON self
-- @param #number Coalition ID of the coalition which is checked to be inside the zone.
-- @return #boolean True if more than one coalition is inside the zone and the specified coalition is one of them.
-- @usage
--    self.Zone:Scan()
--    local IsAttacked = self.Zone:IsSomeInZoneOfCoalition( self.Coalition )
function ZONE_POLYGON:IsSomeInZoneOfCoalition( Coalition )
  return self:CountScannedCoalitions() > 1 and self:GetScannedCoalition( Coalition ) == true
end

--- Is None in Zone of Coalition?
-- You first need to use the @{#ZONE_POLYGON.Scan} method to scan the zone before it can be evaluated!
-- Note that once a zone has been scanned, multiple evaluations can be done on the scan result set.
-- @param #ZONE_POLYGON self
-- @param Coalition
-- @return #boolean
-- @usage
--    self.Zone:Scan()
--    local IsOccupied = self.Zone:IsNoneInZoneOfCoalition( self.Coalition )
function ZONE_POLYGON:IsNoneInZoneOfCoalition( Coalition )
  return self:GetScannedCoalition( Coalition ) == nil
end

--- Is None in Zone?
-- You first need to use the @{#ZONE_POLYGON.Scan} method to scan the zone before it can be evaluated!
-- Note that once a zone has been scanned, multiple evaluations can be done on the scan result set.
-- @param #ZONE_POLYGON self
-- @return #boolean
-- @usage
--    self.Zone:Scan()
--    local IsEmpty = self.Zone:IsNoneInZone()
function ZONE_POLYGON:IsNoneInZone()
  return self:CountScannedCoalitions() == 0
end


do -- ZONE_ELASTIC

  --- @type ZONE_ELASTIC
  -- @field #table points Points in 2D.
  -- @field #table setGroups Set of GROUPs.
  -- @field #table setOpsGroups Set of OPSGROUPS.
  -- @field #table setUnits Set of UNITs.
  -- @field #number updateID Scheduler ID for updating.
  -- @extends #ZONE_POLYGON_BASE

  --- The ZONE_ELASTIC class defines a dynamic polygon zone, where only the convex hull is used.
  --
  -- @field #ZONE_ELASTIC
  ZONE_ELASTIC = {
    ClassName="ZONE_ELASTIC",
    points={},
    setGroups={}
    }

  --- Constructor to create a ZONE_ELASTIC instance.
  -- @param #ZONE_ELASTIC self
  -- @param #string ZoneName Name of the zone.
  -- @param DCS#Vec2 Points (Optional) Fixed points.
  -- @return #ZONE_ELASTIC self
  function ZONE_ELASTIC:New(ZoneName, Points)

    local self=BASE:Inherit(self, ZONE_POLYGON_BASE:New(ZoneName, Points)) --#ZONE_ELASTIC
  
    -- Zone objects are added to the _DATABASE and SET_ZONE objects.
    _EVENTDISPATCHER:CreateEventNewZone( self )
  
    if Points then
      self.points=Points
    end
  
    return self
  end

  --- Add a vertex (point) to the polygon.
  -- @param #ZONE_ELASTIC self
  -- @param DCS#Vec2 Vec2 Point in 2D (with x and y coordinates).
  -- @return #ZONE_ELASTIC self
  function ZONE_ELASTIC:AddVertex2D(Vec2)
  
    -- Add vec2 to points.
    table.insert(self.points, Vec2)
  
    return self
  end


  --- Add a vertex (point) to the polygon.
  -- @param #ZONE_ELASTIC self
  -- @param DCS#Vec3 Vec3 Point in 3D (with x, y and z coordinates). Only the x and z coordinates are used.
  -- @return #ZONE_ELASTIC self
  function ZONE_ELASTIC:AddVertex3D(Vec3)
    
    -- Add vec2 from vec3 to points.
    table.insert(self.points, {x=Vec3.x, y=Vec3.z})
  
    return self
  end


  --- Add a set of groups. Positions of the group will be considered as polygon vertices when contructing the convex hull.
  -- @param #ZONE_ELASTIC self
  -- @param Core.Set#SET_GROUP GroupSet Set of groups.
  -- @return #ZONE_ELASTIC self
  function ZONE_ELASTIC:AddSetGroup(GroupSet)
  
    -- Add set to table.
    table.insert(self.setGroups, GroupSet)
    
    return self
  end


  --- Update the convex hull of the polygon.
  -- This uses the [Graham scan](https://en.wikipedia.org/wiki/Graham_scan).
  -- @param #ZONE_ELASTIC self
  -- @param #number Delay Delay in seconds before the zone is updated. Default 0.
  -- @param #boolean Draw Draw the zone. Default `nil`.
  -- @return #ZONE_ELASTIC self
  function ZONE_ELASTIC:Update(Delay, Draw)
    
    -- Debug info.
    self:T(string.format("Updating ZONE_ELASTIC %s", tostring(self.ZoneName)))
  
    -- Copy all points.
    local points=UTILS.DeepCopy(self.points or {})
    
    if self.setGroups then
      for _,_setGroup in pairs(self.setGroups) do
        local setGroup=_setGroup --Core.Set#SET_GROUP
        for _,_group in pairs(setGroup.Set) do
          local group=_group --Wrapper.Group#GROUP
          if group and group:IsAlive() then
            table.insert(points, group:GetVec2())
          end
        end
      end
    end

    -- Update polygon verticies from points.
    self._.Polygon=self:_ConvexHull(points)
    
    if Draw~=false then
      if self.DrawID or Draw==true then
        self:UndrawZone()
        self:DrawZone()
      end
    end

    return self
  end
  
  --- Start the updating scheduler.
  -- @param #ZONE_ELASTIC self
  -- @param #number Tstart Time in seconds before the updating starts.
  -- @param #number dT Time interval in seconds between updates. Default 60 sec.
  -- @param #number Tstop Time in seconds after which the updating stops. Default `nil`.
  -- @param #boolean Draw Draw the zone. Default `nil`.
  -- @return #ZONE_ELASTIC self
  function ZONE_ELASTIC:StartUpdate(Tstart, dT, Tstop, Draw)
  
    self.updateID=self:ScheduleRepeat(Tstart, dT, 0, Tstop, ZONE_ELASTIC.Update, self, 0, Draw)
  
    return self
  end

  --- Stop the updating scheduler.
  -- @param #ZONE_ELASTIC self
  -- @param #number Delay Delay in seconds before the scheduler will be stopped. Default 0.
  -- @return #ZONE_ELASTIC self
  function ZONE_ELASTIC:StopUpdate(Delay)
  
    if Delay and Delay>0 then
      self:ScheduleOnce(Delay, ZONE_ELASTIC.StopUpdate, self)
    else
  
      if self.updateID then
      
        self:ScheduleStop(self.updateID)
        
        self.updateID=nil
        
      end
      
    end
  
    return self
  end
  

  --- Create a convec hull.
  -- @param #ZONE_ELASTIC self
  -- @param #table pl Points
  -- @return #table Points
  function ZONE_ELASTIC:_ConvexHull(pl)
  
    if #pl == 0 then
      return {}
    end
    
    table.sort(pl, function(left,right)
      return left.x < right.x
    end)
 
    local h = {}
    
    -- Function: ccw > 0 if three points make a counter-clockwise turn, clockwise if ccw < 0, and collinear if ccw = 0.
    local function ccw(a,b,c)
      return (b.x - a.x) * (c.y - a.y) > (b.y - a.y) * (c.x - a.x)
    end
 
    -- lower hull
    for i,pt in pairs(pl) do
      while #h >= 2 and not ccw(h[#h-1], h[#h], pt) do
        table.remove(h,#h)
      end
      table.insert(h,pt)
    end
 
    -- upper hull
    local t = #h + 1
    for i=#pl, 1, -1 do
      local pt = pl[i]
      while #h >= t and not ccw(h[#h-1], h[#h], pt) do
        table.remove(h, #h)
      end
      table.insert(h, pt)
    end
 
    table.remove(h, #h)
    
    return h
  end  
  
end

do -- ZONE_AIRBASE

  --- @type ZONE_AIRBASE
  -- @field #boolean isShip If `true`, airbase is a ship.
  -- @field #boolean isHelipad If `true`, airbase is a helipad.
  -- @field #boolean isAirdrome If `true`, airbase is an airdrome.
  -- @extends #ZONE_RADIUS


  --- The ZONE_AIRBASE class defines by a zone around a @{Wrapper.Airbase#AIRBASE} with a radius.
  -- This class implements the inherited functions from @{#ZONE_RADIUS} taking into account the own zone format and properties.
  --
  -- @field #ZONE_AIRBASE
  ZONE_AIRBASE = {
    ClassName="ZONE_AIRBASE",
    }



  --- Constructor to create a ZONE_AIRBASE instance, taking the zone name, a zone @{Wrapper.Airbase#AIRBASE} and a radius.
  -- @param #ZONE_AIRBASE self
  -- @param #string AirbaseName Name of the airbase.
  -- @param DCS#Distance Radius (Optional)The radius of the zone in meters. Default 4000 meters.
  -- @return #ZONE_AIRBASE self
  function ZONE_AIRBASE:New( AirbaseName, Radius )

    Radius=Radius or 4000

    local Airbase = AIRBASE:FindByName( AirbaseName )

    local self = BASE:Inherit( self, ZONE_RADIUS:New( AirbaseName, Airbase:GetVec2(), Radius, true ) )

    self._.ZoneAirbase = Airbase
    self._.ZoneVec2Cache = self._.ZoneAirbase:GetVec2()
    
    if Airbase:IsShip() then
      self.isShip=true
      self.isHelipad=false
      self.isAirdrome=false
    elseif Airbase:IsHelipad() then
      self.isShip=false
      self.isHelipad=true
      self.isAirdrome=false    
    elseif Airbase:IsAirdrome() then
      self.isShip=false
      self.isHelipad=false
      self.isAirdrome=true    
    end

    -- Zone objects are added to the _DATABASE and SET_ZONE objects.
    _EVENTDISPATCHER:CreateEventNewZone( self )

    return self
  end

  --- Get the airbase as part of the ZONE_AIRBASE object.
  -- @param #ZONE_AIRBASE self
  -- @return Wrapper.Airbase#AIRBASE The airbase.
  function ZONE_AIRBASE:GetAirbase()
    return self._.ZoneAirbase
  end

  --- Returns the current location of the AIRBASE.
  -- @param #ZONE_AIRBASE self
  -- @return DCS#Vec2 The location of the zone based on the AIRBASE location.
  function ZONE_AIRBASE:GetVec2()
    self:F( self.ZoneName )

    local ZoneVec2 = nil

    if self._.ZoneAirbase:IsAlive() then
      ZoneVec2 = self._.ZoneAirbase:GetVec2()
      self._.ZoneVec2Cache = ZoneVec2
    else
      ZoneVec2 = self._.ZoneVec2Cache
    end

    self:T( { ZoneVec2 } )

    return ZoneVec2
  end

  --- Returns a @{Core.Point#POINT_VEC2} object reflecting a random 2D location within the zone.
  -- @param #ZONE_AIRBASE self
  -- @param #number inner (optional) Minimal distance from the center of the zone. Default is 0.
  -- @param #number outer (optional) Maximal distance from the outer edge of the zone. Default is the radius of the zone.
  -- @return Core.Point#POINT_VEC2 The @{Core.Point#POINT_VEC2} object reflecting the random 3D location within the zone.
  function ZONE_AIRBASE:GetRandomPointVec2( inner, outer )
    self:F( self.ZoneName, inner, outer )

    local PointVec2 = POINT_VEC2:NewFromVec2( self:GetRandomVec2() )

    self:T3( { PointVec2 } )

    return PointVec2
  end

end
