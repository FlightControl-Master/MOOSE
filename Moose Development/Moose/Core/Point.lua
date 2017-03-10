--- **Core** - **POINT\_VEC** classes define an **extensive API** to **manage 3D points** in the simulation space.
-- 
-- 1) @{Point#POINT_VEC3} class, extends @{Base#BASE}
-- ==================================================
-- The @{Point#POINT_VEC3} class defines a 3D point in the simulator.
-- 
-- **Important Note:** Most of the functions in this section were taken from MIST, and reworked to OO concepts.
-- In order to keep the credibility of the the author, I want to emphasize that the of the MIST framework was created by Grimes, who you can find on the Eagle Dynamics Forums.
-- 
-- ## 1.1) POINT_VEC3 constructor
-- 
-- A new POINT_VEC3 instance can be created with:
-- 
--  * @{Point#POINT_VEC3.New}(): a 3D point.
--  * @{Point#POINT_VEC3.NewFromVec3}(): a 3D point created from a @{DCSTypes#Vec3}.
-- 
-- ## 1.2) Manupulate the X, Y, Z coordinates of the point
-- 
-- A POINT_VEC3 class works in 3D space. It contains internally an X, Y, Z coordinate.
-- Methods exist to manupulate these coordinates.
-- 
-- The current X, Y, Z axis can be retrieved with the methods @{#POINT_VEC3.GetX}(), @{#POINT_VEC3.GetY}(), @{#POINT_VEC3.GetZ}() respectively.
-- The methods @{#POINT_VEC3.SetX}(), @{#POINT_VEC3.SetY}(), @{#POINT_VEC3.SetZ}() change the respective axis with a new value.
-- The current axis values can be changed by using the methods @{#POINT_VEC3.AddX}(), @{#POINT_VEC3.AddY}(), @{#POINT_VEC3.AddZ}()
-- to add or substract a value from the current respective axis value.
-- Note that the Set and Add methods return the current POINT_VEC3 object, so these manipulation methods can be chained... For example:
-- 
--      local Vec3 = PointVec3:AddX( 100 ):AddZ( 150 ):GetVec3()
-- 
-- ## 1.3) Create waypoints for routes
-- 
-- A POINT_VEC3 can prepare waypoints for Ground, Air and Naval groups to be embedded into a Route.
-- 
-- 
-- ## 1.5) Smoke, flare, explode, illuminate
-- 
-- At the point a smoke, flare, explosion and illumination bomb can be triggered. Use the following methods:
-- 
-- ### 1.5.1) Smoke
-- 
--   * @{#POINT_VEC3.Smoke}(): To smoke the point in a certain color.
--   * @{#POINT_VEC3.SmokeBlue}(): To smoke the point in blue.
--   * @{#POINT_VEC3.SmokeRed}(): To smoke the point in red.
--   * @{#POINT_VEC3.SmokeOrange}(): To smoke the point in orange.
--   * @{#POINT_VEC3.SmokeWhite}(): To smoke the point in white.
--   * @{#POINT_VEC3.SmokeGreen}(): To smoke the point in green.
--   
-- ### 1.5.2) Flare
-- 
--   * @{#POINT_VEC3.Flare}(): To flare the point in a certain color.
--   * @{#POINT_VEC3.FlareRed}(): To flare the point in red.
--   * @{#POINT_VEC3.FlareYellow}(): To flare the point in yellow.
--   * @{#POINT_VEC3.FlareWhite}(): To flare the point in white.
--   * @{#POINT_VEC3.FlareGreen}(): To flare the point in green.
-- 
-- ### 1.5.3) Explode
-- 
--   * @{#POINT_VEC3.Explosion}(): To explode the point with a certain intensity.
--   
-- ### 1.5.4) Illuminate
-- 
--   * @{#POINT_VEC3.IlluminationBomb}(): To illuminate the point.
-- 
--
-- 2) @{Point#POINT_VEC2} class, extends @{Point#POINT_VEC3}
-- =========================================================
-- The @{Point#POINT_VEC2} class defines a 2D point in the simulator. The height coordinate (if needed) will be the land height + an optional added height specified.
-- 
-- 2.1) POINT_VEC2 constructor
-- ---------------------------
-- A new POINT_VEC2 instance can be created with:
-- 
--  * @{Point#POINT_VEC2.New}(): a 2D point, taking an additional height parameter.
--  * @{Point#POINT_VEC2.NewFromVec2}(): a 2D point created from a @{DCSTypes#Vec2}.
-- 
-- ## 1.2) Manupulate the X, Altitude, Y coordinates of the 2D point
-- 
-- A POINT_VEC2 class works in 2D space, with an altitude setting. It contains internally an X, Altitude, Y coordinate.
-- Methods exist to manupulate these coordinates.
-- 
-- The current X, Altitude, Y axis can be retrieved with the methods @{#POINT_VEC2.GetX}(), @{#POINT_VEC2.GetAlt}(), @{#POINT_VEC2.GetY}() respectively.
-- The methods @{#POINT_VEC2.SetX}(), @{#POINT_VEC2.SetAlt}(), @{#POINT_VEC2.SetY}() change the respective axis with a new value.
-- The current Lat(itude), Alt(itude), Lon(gitude) values can also be retrieved with the methods @{#POINT_VEC2.GetLat}(), @{#POINT_VEC2.GetAlt}(), @{#POINT_VEC2.GetLon}() respectively.
-- The current axis values can be changed by using the methods @{#POINT_VEC2.AddX}(), @{#POINT_VEC2.AddAlt}(), @{#POINT_VEC2.AddY}()
-- to add or substract a value from the current respective axis value.
-- Note that the Set and Add methods return the current POINT_VEC2 object, so these manipulation methods can be chained... For example:
-- 
--      local Vec2 = PointVec2:AddX( 100 ):AddY( 2000 ):GetVec2()
-- 
-- ===
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
-- 2017-03-03: POINT\_VEC3:**Explosion( ExplosionIntensity )** added.  
-- 2017-03-03: POINT\_VEC3:**IlluminationBomb()** added.  
-- 
-- 2017-02-18: POINT\_VEC3:**NewFromVec2( Vec2, LandHeightAdd )** added.
-- 
-- 2016-08-12: POINT\_VEC3:**Translate( Distance, Angle )** added.
-- 
-- 2016-08-06: Made PointVec3 and Vec3, PointVec2 and Vec2 terminology used in the code consistent.
-- 
--   * Replaced method _Point_Vec3() to **Vec3**() where the code manages a Vec3. Replaced all references to the method.
--   * Replaced method _Point_Vec2() to **Vec2**() where the code manages a Vec2. Replaced all references to the method.
--   * Replaced method Random_Point_Vec3() to **RandomVec3**() where the code manages a Vec3. Replaced all references to the method.
-- .
-- ===
--  
-- ### Authors: 
-- 
--   * FlightControl : Design & Programming
--   
-- ### Contributions: 
-- 
-- @module Point

--- The POINT_VEC3 class
-- @type POINT_VEC3
-- @field #number x The x coordinate in 3D space.
-- @field #number y The y coordinate in 3D space.
-- @field #number z The z coordiante in 3D space.
-- @field Utilities.Utils#SMOKECOLOR SmokeColor
-- @field Utilities.Utils#FLARECOLOR FlareColor
-- @field #POINT_VEC3.RoutePointAltType RoutePointAltType
-- @field #POINT_VEC3.RoutePointType RoutePointType
-- @field #POINT_VEC3.RoutePointAction RoutePointAction
-- @extends Core.Base#BASE
POINT_VEC3 = {
  ClassName = "POINT_VEC3",
  Metric = true,
  RoutePointAltType = {
    BARO = "BARO",
  },
  RoutePointType = {
    TakeOffParking = "TakeOffParking",
    TurningPoint = "Turning Point",
  },
  RoutePointAction = {
    FromParkingArea = "From Parking Area",
    TurningPoint = "Turning Point",
  },
}

--- The POINT_VEC2 class
-- @type POINT_VEC2
-- @field Dcs.DCSTypes#Distance x The x coordinate in meters.
-- @field Dcs.DCSTypes#Distance y the y coordinate in meters.
-- @extends Core.Point#POINT_VEC3
POINT_VEC2 = {
  ClassName = "POINT_VEC2",
}


do -- POINT_VEC3

--- RoutePoint AltTypes
-- @type POINT_VEC3.RoutePointAltType
-- @field BARO "BARO"

--- RoutePoint Types
-- @type POINT_VEC3.RoutePointType
-- @field TakeOffParking "TakeOffParking"
-- @field TurningPoint "Turning Point"

--- RoutePoint Actions
-- @type POINT_VEC3.RoutePointAction
-- @field FromParkingArea "From Parking Area"
-- @field TurningPoint "Turning Point"

-- Constructor.
  
--- Create a new POINT_VEC3 object.
-- @param #POINT_VEC3 self
-- @param Dcs.DCSTypes#Distance x The x coordinate of the Vec3 point, pointing to the North.
-- @param Dcs.DCSTypes#Distance y The y coordinate of the Vec3 point, pointing Upwards.
-- @param Dcs.DCSTypes#Distance z The z coordinate of the Vec3 point, pointing to the Right.
-- @return Core.Point#POINT_VEC3 self
function POINT_VEC3:New( x, y, z )

  local self = BASE:Inherit( self, BASE:New() )
  self.x = x
  self.y = y
  self.z = z
  
  return self
end

--- Create a new POINT_VEC3 object from Vec2 coordinates.
-- @param #POINT_VEC3 self
-- @param Dcs.DCSTypes#Vec2 Vec2 The Vec2 point.
-- @return Core.Point#POINT_VEC3 self
function POINT_VEC3:NewFromVec2( Vec2, LandHeightAdd )

  local LandHeight = land.getHeight( Vec2 )

  LandHeightAdd = LandHeightAdd or 0
  LandHeight = LandHeight + LandHeightAdd
  
  self = self:New( Vec2.x, LandHeight, Vec2.y )
  
  self:F2( self )

  return self
end

--- Create a new POINT_VEC3 object from  Vec3 coordinates.
-- @param #POINT_VEC3 self
-- @param Dcs.DCSTypes#Vec3 Vec3 The Vec3 point.
-- @return Core.Point#POINT_VEC3 self
function POINT_VEC3:NewFromVec3( Vec3 )

  self = self:New( Vec3.x, Vec3.y, Vec3.z )
  self:F2( self )
  return self
end


--- Return the coordinates of the POINT_VEC3 in Vec3 format.
-- @param #POINT_VEC3 self
-- @return Dcs.DCSTypes#Vec3 The Vec3 coodinate.
function POINT_VEC3:GetVec3()
  return { x = self.x, y = self.y, z = self.z }
end

--- Return the coordinates of the POINT_VEC3 in Vec2 format.
-- @param #POINT_VEC3 self
-- @return Dcs.DCSTypes#Vec2 The Vec2 coodinate.
function POINT_VEC3:GetVec2()
  return { x = self.x, y = self.z }
end


--- Return the x coordinate of the POINT_VEC3.
-- @param #POINT_VEC3 self
-- @return #number The x coodinate.
function POINT_VEC3:GetX()
  return self.x
end

--- Return the y coordinate of the POINT_VEC3.
-- @param #POINT_VEC3 self
-- @return #number The y coodinate.
function POINT_VEC3:GetY()
  return self.y
end

--- Return the z coordinate of the POINT_VEC3.
-- @param #POINT_VEC3 self
-- @return #number The z coodinate.
function POINT_VEC3:GetZ()
  return self.z
end

--- Set the x coordinate of the POINT_VEC3.
-- @param #POINT_VEC3 self
-- @param #number x The x coordinate.
-- @return #POINT_VEC3
function POINT_VEC3:SetX( x )
  self.x = x
  return self
end

--- Set the y coordinate of the POINT_VEC3.
-- @param #POINT_VEC3 self
-- @param #number y The y coordinate.
-- @return #POINT_VEC3
function POINT_VEC3:SetY( y )
  self.y = y
  return self
end

--- Set the z coordinate of the POINT_VEC3.
-- @param #POINT_VEC3 self
-- @param #number z The z coordinate.
-- @return #POINT_VEC3
function POINT_VEC3:SetZ( z )
  self.z = z
  return self
end

--- Add to the x coordinate of the POINT_VEC3.
-- @param #POINT_VEC3 self
-- @param #number x The x coordinate value to add to the current x coodinate.
-- @return #POINT_VEC3
function POINT_VEC3:AddX( x )
  self.x = self.x + x
  return self
end

--- Add to the y coordinate of the POINT_VEC3.
-- @param #POINT_VEC3 self
-- @param #number y The y coordinate value to add to the current y coodinate.
-- @return #POINT_VEC3
function POINT_VEC3:AddY( y )
  self.y = self.y + y
  return self
end

--- Add to the z coordinate of the POINT_VEC3.
-- @param #POINT_VEC3 self
-- @param #number z The z coordinate value to add to the current z coodinate.
-- @return #POINT_VEC3
function POINT_VEC3:AddZ( z )
  self.z = self.z +z
  return self
end

--- Return a random Vec2 within an Outer Radius and optionally NOT within an Inner Radius of the POINT_VEC3.
-- @param #POINT_VEC3 self
-- @param Dcs.DCSTypes#Distance OuterRadius
-- @param Dcs.DCSTypes#Distance InnerRadius
-- @return Dcs.DCSTypes#Vec2 Vec2
function POINT_VEC3:GetRandomVec2InRadius( OuterRadius, InnerRadius )
  self:F2( { OuterRadius, InnerRadius } )

  local Theta = 2 * math.pi * math.random()
  local Radials = math.random() + math.random()
  if Radials > 1 then
    Radials = 2 - Radials
  end

  local RadialMultiplier
  if InnerRadius and InnerRadius <= OuterRadius then
    RadialMultiplier = ( OuterRadius - InnerRadius ) * Radials + InnerRadius
  else
    RadialMultiplier = OuterRadius * Radials
  end

  local RandomVec2
  if OuterRadius > 0 then
    RandomVec2 = { x = math.cos( Theta ) * RadialMultiplier + self:GetX(), y = math.sin( Theta ) * RadialMultiplier + self:GetZ() }
  else
    RandomVec2 = { x = self:GetX(), y = self:GetZ() }
  end
  
  return RandomVec2
end

--- Return a random POINT_VEC2 within an Outer Radius and optionally NOT within an Inner Radius of the POINT_VEC3.
-- @param #POINT_VEC3 self
-- @param Dcs.DCSTypes#Distance OuterRadius
-- @param Dcs.DCSTypes#Distance InnerRadius
-- @return #POINT_VEC2
function POINT_VEC3:GetRandomPointVec2InRadius( OuterRadius, InnerRadius )
  self:F2( { OuterRadius, InnerRadius } )
  
  return POINT_VEC2:NewFromVec2( self:GetRandomVec2InRadius( OuterRadius, InnerRadius ) )
end

--- Return a random Vec3 within an Outer Radius and optionally NOT within an Inner Radius of the POINT_VEC3.
-- @param #POINT_VEC3 self
-- @param Dcs.DCSTypes#Distance OuterRadius
-- @param Dcs.DCSTypes#Distance InnerRadius
-- @return Dcs.DCSTypes#Vec3 Vec3
function POINT_VEC3:GetRandomVec3InRadius( OuterRadius, InnerRadius )

  local RandomVec2 = self:GetRandomVec2InRadius( OuterRadius, InnerRadius )
  local y = self:GetY() + math.random( InnerRadius, OuterRadius )
  local RandomVec3 = { x = RandomVec2.x, y = y, z = RandomVec2.y }

  return RandomVec3
end

--- Return a random POINT_VEC3 within an Outer Radius and optionally NOT within an Inner Radius of the POINT_VEC3.
-- @param #POINT_VEC3 self
-- @param Dcs.DCSTypes#Distance OuterRadius
-- @param Dcs.DCSTypes#Distance InnerRadius
-- @return #POINT_VEC3
function POINT_VEC3:GetRandomPointVec3InRadius( OuterRadius, InnerRadius )

  return POINT_VEC3:NewFromVec3( self:GetRandomVec3InRadius( OuterRadius, InnerRadius ) )
end


--- Return a direction vector Vec3 from POINT_VEC3 to the POINT_VEC3.
-- @param #POINT_VEC3 self
-- @param #POINT_VEC3 TargetPointVec3 The target POINT_VEC3.
-- @return Dcs.DCSTypes#Vec3 DirectionVec3 The direction vector in Vec3 format.
function POINT_VEC3:GetDirectionVec3( TargetPointVec3 )
  return { x = TargetPointVec3:GetX() - self:GetX(), y = TargetPointVec3:GetY() - self:GetY(), z = TargetPointVec3:GetZ() - self:GetZ() }
end

--- Get a correction in radians of the real magnetic north of the POINT_VEC3.
-- @param #POINT_VEC3 self
-- @return #number CorrectionRadians The correction in radians.
function POINT_VEC3:GetNorthCorrectionRadians()
  local TargetVec3 = self:GetVec3()
  local lat, lon = coord.LOtoLL(TargetVec3)
  local north_posit = coord.LLtoLO(lat + 1, lon)
  return math.atan2( north_posit.z - TargetVec3.z, north_posit.x - TargetVec3.x )
end


--- Return a direction in radians from the POINT_VEC3 using a direction vector in Vec3 format.
-- @param #POINT_VEC3 self
-- @param Dcs.DCSTypes#Vec3 DirectionVec3 The direction vector in Vec3 format.
-- @return #number DirectionRadians The direction in radians.
function POINT_VEC3:GetDirectionRadians( DirectionVec3 )
  local DirectionRadians = math.atan2( DirectionVec3.z, DirectionVec3.x )
  --DirectionRadians = DirectionRadians + self:GetNorthCorrectionRadians()
  if DirectionRadians < 0 then
    DirectionRadians = DirectionRadians + 2 * math.pi  -- put dir in range of 0 to 2*pi ( the full circle )
  end
  return DirectionRadians
end

--- Return the 2D distance in meters between the target POINT_VEC3 and the POINT_VEC3.
-- @param #POINT_VEC3 self
-- @param #POINT_VEC3 TargetPointVec3 The target POINT_VEC3.
-- @return Dcs.DCSTypes#Distance Distance The distance in meters.
function POINT_VEC3:Get2DDistance( TargetPointVec3 )
  local TargetVec3 = TargetPointVec3:GetVec3()
  local SourceVec3 = self:GetVec3()
  return ( ( TargetVec3.x - SourceVec3.x ) ^ 2 + ( TargetVec3.z - SourceVec3.z ) ^ 2 ) ^ 0.5
end

--- Return the 3D distance in meters between the target POINT_VEC3 and the POINT_VEC3.
-- @param #POINT_VEC3 self
-- @param #POINT_VEC3 TargetPointVec3 The target POINT_VEC3.
-- @return Dcs.DCSTypes#Distance Distance The distance in meters.
function POINT_VEC3:Get3DDistance( TargetPointVec3 )
  local TargetVec3 = TargetPointVec3:GetVec3()
  local SourceVec3 = self:GetVec3()
  return ( ( TargetVec3.x - SourceVec3.x ) ^ 2 + ( TargetVec3.y - SourceVec3.y ) ^ 2 + ( TargetVec3.z - SourceVec3.z ) ^ 2 ) ^ 0.5
end

--- Provides a Bearing / Range string
-- @param #POINT_VEC3 self
-- @param #number AngleRadians The angle in randians
-- @param #number Distance The distance
-- @return #string The BR Text
function POINT_VEC3:ToStringBR( AngleRadians, Distance )

  AngleRadians = UTILS.Round( UTILS.ToDegree( AngleRadians ), 0 )
  if self:IsMetric() then
    Distance = UTILS.Round( Distance / 1000, 2 )
  else
    Distance = UTILS.Round( UTILS.MetersToNM( Distance ), 2 )
  end

  local s = string.format( '%03d', AngleRadians ) .. ' for ' .. Distance

  s = s .. self:GetAltitudeText() -- When the POINT is a VEC2, there will be no altitude shown.

  return s
end

--- Provides a Bearing / Range string
-- @param #POINT_VEC3 self
-- @param #number AngleRadians The angle in randians
-- @param #number Distance The distance
-- @return #string The BR Text
function POINT_VEC3:ToStringLL( acc, DMS )

  acc = acc or 3
  local lat, lon = coord.LOtoLL( self:GetVec3() )
  return UTILS.tostringLL(lat, lon, acc, DMS)
end

--- Return the altitude text of the POINT_VEC3.
-- @param #POINT_VEC3 self
-- @return #string Altitude text.
function POINT_VEC3:GetAltitudeText()
  if self:IsMetric() then
    return ' at ' .. UTILS.Round( self:GetY(), 0 )
  else
    return ' at ' .. UTILS.Round( UTILS.MetersToFeet( self:GetY() ), 0 )
  end
end

--- Return a BR string from a POINT_VEC3 to the POINT_VEC3.
-- @param #POINT_VEC3 self
-- @param #POINT_VEC3 TargetPointVec3 The target POINT_VEC3.
-- @return #string The BR text.
function POINT_VEC3:GetBRText( TargetPointVec3 )
    local DirectionVec3 = self:GetDirectionVec3( TargetPointVec3 )
    local AngleRadians =  self:GetDirectionRadians( DirectionVec3 )
    local Distance = self:Get2DDistance( TargetPointVec3 )
    return self:ToStringBR( AngleRadians, Distance )
end

--- Sets the POINT_VEC3 metric or NM.
-- @param #POINT_VEC3 self
-- @param #boolean Metric true means metric, false means NM.
function POINT_VEC3:SetMetric( Metric )
  self.Metric = Metric
end

--- Gets if the POINT_VEC3 is metric or NM.
-- @param #POINT_VEC3 self
-- @return #boolean Metric true means metric, false means NM.
function POINT_VEC3:IsMetric()
  return self.Metric
end

--- Add a Distance in meters from the POINT_VEC3 horizontal plane, with the given angle, and calculate the new POINT_VEC3.
-- @param #POINT_VEC3 self
-- @param Dcs.DCSTypes#Distance Distance The Distance to be added in meters.
-- @param Dcs.DCSTypes#Angle Angle The Angle in degrees.
-- @return #POINT_VEC3 The new calculated POINT_VEC3.
function POINT_VEC3:Translate( Distance, Angle )
  local SX = self:GetX()
  local SZ = self:GetZ()
  local Radians = Angle / 180 * math.pi
  local TX = Distance * math.cos( Radians ) + SX
  local TZ = Distance * math.sin( Radians ) + SZ
  
  return POINT_VEC3:New( TX, self:GetY(), TZ )
end



--- Build an air type route point.
-- @param #POINT_VEC3 self
-- @param #POINT_VEC3.RoutePointAltType AltType The altitude type.
-- @param #POINT_VEC3.RoutePointType Type The route point type.
-- @param #POINT_VEC3.RoutePointAction Action The route point action.
-- @param Dcs.DCSTypes#Speed Speed Airspeed in km/h.
-- @param #boolean SpeedLocked true means the speed is locked.
-- @return #table The route point.
function POINT_VEC3:RoutePointAir( AltType, Type, Action, Speed, SpeedLocked )
  self:F2( { AltType, Type, Action, Speed, SpeedLocked } )

  local RoutePoint = {}
  RoutePoint.x = self.x
  RoutePoint.y = self.z
  RoutePoint.alt = self.y
  RoutePoint.alt_type = AltType
  
  RoutePoint.type = Type
  RoutePoint.action = Action

  RoutePoint.speed = Speed / 3.6
  RoutePoint.speed_locked = true
  
--  ["task"] = 
--  {
--      ["id"] = "ComboTask",
--      ["params"] = 
--      {
--          ["tasks"] = 
--          {
--          }, -- end of ["tasks"]
--      }, -- end of ["params"]
--  }, -- end of ["task"]


  RoutePoint.task = {}
  RoutePoint.task.id = "ComboTask"
  RoutePoint.task.params = {}
  RoutePoint.task.params.tasks = {}
  
  
  return RoutePoint
end

--- Build an ground type route point.
-- @param #POINT_VEC3 self
-- @param Dcs.DCSTypes#Speed Speed Speed in km/h.
-- @param #POINT_VEC3.RoutePointAction Formation The route point Formation.
-- @return #table The route point.
function POINT_VEC3:RoutePointGround( Speed, Formation )
  self:F2( { Formation, Speed } )

  local RoutePoint = {}
  RoutePoint.x = self.x
  RoutePoint.y = self.z
  
  RoutePoint.action = Formation or ""
    

  RoutePoint.speed = Speed / 3.6
  RoutePoint.speed_locked = true
  
--  ["task"] = 
--  {
--      ["id"] = "ComboTask",
--      ["params"] = 
--      {
--          ["tasks"] = 
--          {
--          }, -- end of ["tasks"]
--      }, -- end of ["params"]
--  }, -- end of ["task"]


  RoutePoint.task = {}
  RoutePoint.task.id = "ComboTask"
  RoutePoint.task.params = {}
  RoutePoint.task.params.tasks = {}
  
  
  return RoutePoint
end

--- Creates an explosion at the point of a certain intensity.
-- @param #POINT_VEC3 self
-- @param #number ExplosionIntensity
function POINT_VEC3:Explosion( ExplosionIntensity )
  self:F2( { ExplosionIntensity } )
  trigger.action.explosion( self:GetVec3(), ExplosionIntensity )
end

--- Creates an illumination bomb at the point.
-- @param #POINT_VEC3 self
function POINT_VEC3:IlluminationBomb()
  self:F2()
  trigger.action.illuminationBomb( self:GetVec3() )
end


--- Smokes the point in a color.
-- @param #POINT_VEC3 self
-- @param Utilities.Utils#SMOKECOLOR SmokeColor
function POINT_VEC3:Smoke( SmokeColor )
  self:F2( { SmokeColor } )
  trigger.action.smoke( self:GetVec3(), SmokeColor )
end

--- Smoke the POINT_VEC3 Green.
-- @param #POINT_VEC3 self
function POINT_VEC3:SmokeGreen()
  self:F2()
  self:Smoke( SMOKECOLOR.Green )
end

--- Smoke the POINT_VEC3 Red.
-- @param #POINT_VEC3 self
function POINT_VEC3:SmokeRed()
  self:F2()
  self:Smoke( SMOKECOLOR.Red )
end

--- Smoke the POINT_VEC3 White.
-- @param #POINT_VEC3 self
function POINT_VEC3:SmokeWhite()
  self:F2()
  self:Smoke( SMOKECOLOR.White )
end

--- Smoke the POINT_VEC3 Orange.
-- @param #POINT_VEC3 self
function POINT_VEC3:SmokeOrange()
  self:F2()
  self:Smoke( SMOKECOLOR.Orange )
end

--- Smoke the POINT_VEC3 Blue.
-- @param #POINT_VEC3 self
function POINT_VEC3:SmokeBlue()
  self:F2()
  self:Smoke( SMOKECOLOR.Blue )
end

--- Flares the point in a color.
-- @param #POINT_VEC3 self
-- @param Utilities.Utils#FLARECOLOR FlareColor
-- @param Dcs.DCSTypes#Azimuth (optional) Azimuth The azimuth of the flare direction. The default azimuth is 0.
function POINT_VEC3:Flare( FlareColor, Azimuth )
  self:F2( { FlareColor } )
  trigger.action.signalFlare( self:GetVec3(), FlareColor, Azimuth and Azimuth or 0 )
end

--- Flare the POINT_VEC3 White.
-- @param #POINT_VEC3 self
-- @param Dcs.DCSTypes#Azimuth (optional) Azimuth The azimuth of the flare direction. The default azimuth is 0.
function POINT_VEC3:FlareWhite( Azimuth )
  self:F2( Azimuth )
  self:Flare( FLARECOLOR.White, Azimuth )
end

--- Flare the POINT_VEC3 Yellow.
-- @param #POINT_VEC3 self
-- @param Dcs.DCSTypes#Azimuth (optional) Azimuth The azimuth of the flare direction. The default azimuth is 0.
function POINT_VEC3:FlareYellow( Azimuth )
  self:F2( Azimuth )
  self:Flare( FLARECOLOR.Yellow, Azimuth )
end

--- Flare the POINT_VEC3 Green.
-- @param #POINT_VEC3 self
-- @param Dcs.DCSTypes#Azimuth (optional) Azimuth The azimuth of the flare direction. The default azimuth is 0.
function POINT_VEC3:FlareGreen( Azimuth )
  self:F2( Azimuth )
  self:Flare( FLARECOLOR.Green, Azimuth )
end

--- Flare the POINT_VEC3 Red.
-- @param #POINT_VEC3 self
function POINT_VEC3:FlareRed( Azimuth )
  self:F2( Azimuth )
  self:Flare( FLARECOLOR.Red, Azimuth )
end

end

do -- POINT_VEC2



--- POINT_VEC2 constructor.
-- @param #POINT_VEC2 self
-- @param Dcs.DCSTypes#Distance x The x coordinate of the Vec3 point, pointing to the North.
-- @param Dcs.DCSTypes#Distance y The y coordinate of the Vec3 point, pointing to the Right.
-- @param Dcs.DCSTypes#Distance LandHeightAdd (optional) The default height if required to be evaluated will be the land height of the x, y coordinate. You can specify an extra height to be added to the land height.
-- @return Core.Point#POINT_VEC2
function POINT_VEC2:New( x, y, LandHeightAdd )

  local LandHeight = land.getHeight( { ["x"] = x, ["y"] = y } )
  
  LandHeightAdd = LandHeightAdd or 0
  LandHeight = LandHeight + LandHeightAdd
  
  self = BASE:Inherit( self, POINT_VEC3:New( x, LandHeight, y ) )
  self:F2( self )
  
  return self
end

--- Create a new POINT_VEC2 object from  Vec2 coordinates.
-- @param #POINT_VEC2 self
-- @param Dcs.DCSTypes#Vec2 Vec2 The Vec2 point.
-- @return Core.Point#POINT_VEC2 self
function POINT_VEC2:NewFromVec2( Vec2, LandHeightAdd )

  local LandHeight = land.getHeight( Vec2 )

  LandHeightAdd = LandHeightAdd or 0
  LandHeight = LandHeight + LandHeightAdd
  
  self = BASE:Inherit( self, POINT_VEC3:New( Vec2.x, LandHeight, Vec2.y ) )
  self:F2( self )

  return self
end

--- Create a new POINT_VEC2 object from  Vec3 coordinates.
-- @param #POINT_VEC2 self
-- @param Dcs.DCSTypes#Vec3 Vec3 The Vec3 point.
-- @return Core.Point#POINT_VEC2 self
function POINT_VEC2:NewFromVec3( Vec3 )

  local self = BASE:Inherit( self, BASE:New() )
  local Vec2 = { x = Vec3.x, y = Vec3.z }

  local LandHeight = land.getHeight( Vec2 )
  
  self = BASE:Inherit( self, POINT_VEC3:New( Vec2.x, LandHeight, Vec2.y ) )
  self:F2( self )

  return self
end

--- Return the x coordinate of the POINT_VEC2.
-- @param #POINT_VEC2 self
-- @return #number The x coodinate.
function POINT_VEC2:GetX()
  return self.x
end

--- Return the y coordinate of the POINT_VEC2.
-- @param #POINT_VEC2 self
-- @return #number The y coodinate.
function POINT_VEC2:GetY()
  return self.z
end

--- Return the altitude (height) of the land at the POINT_VEC2.
-- @param #POINT_VEC2 self
-- @return #number The land altitude.
function POINT_VEC2:GetAlt()
  return land.getHeight( { x = self.x, y = self.z } )
end

--- Return Return the Lat(itude) coordinate of the POINT_VEC2 (ie: (parent)POINT_VEC3.x).
-- @param #POINT_VEC2 self
-- @return #number The x coodinate.
function POINT_VEC2:GetLat()
  return self.x
end

--- Return the Lon(gitude) coordinate of the POINT_VEC2 (ie: (parent)POINT_VEC3.z).
-- @param #POINT_VEC2 self
-- @return #number The y coodinate.
function POINT_VEC2:GetLon()
  return self.z
end

--- Set the x coordinate of the POINT_VEC2.
-- @param #POINT_VEC2 self
-- @param #number x The x coordinate.
-- @return #POINT_VEC2
function POINT_VEC2:SetX( x )
  self.x = x
  return self
end

--- Set the y coordinate of the POINT_VEC2.
-- @param #POINT_VEC2 self
-- @param #number y The y coordinate.
-- @return #POINT_VEC2
function POINT_VEC2:SetY( y )
  self.z = y
  return self
end

--- Set the Lat(itude) coordinate of the POINT_VEC2 (ie: POINT_VEC3.x).
-- @param #POINT_VEC2 self
-- @param #number x The x coordinate.
-- @return #POINT_VEC2
function POINT_VEC2:SetLat( x )
  self.x = x
  return self
end

--- Set the altitude of the POINT_VEC2.
-- @param #POINT_VEC2 self
-- @param #number Altitude The land altitude. If nothing (nil) is given, then the current land altitude is set.
-- @return #POINT_VEC2
function POINT_VEC2:SetAlt( Altitude )
  self.y = Altitude or land.getHeight( { x = self.x, y = self.z } )
  return self
end

--- Set the Lon(gitude) coordinate of the POINT_VEC2 (ie: POINT_VEC3.z).
-- @param #POINT_VEC2 self
-- @param #number y The y coordinate.
-- @return #POINT_VEC2
function POINT_VEC2:SetLon( z )
  self.z = z
  return self
end

--- Add to the x coordinate of the POINT_VEC2.
-- @param #POINT_VEC2 self
-- @param #number x The x coordinate.
-- @return #POINT_VEC2
function POINT_VEC2:AddX( x )
  self.x = self.x + x
  return self
end

--- Add to the y coordinate of the POINT_VEC2.
-- @param #POINT_VEC2 self
-- @param #number y The y coordinate.
-- @return #POINT_VEC2
function POINT_VEC2:AddY( y )
  self.z = self.z + y
  return self
end

--- Add to the current land height an altitude.
-- @param #POINT_VEC2 self
-- @param #number Altitude The Altitude to add. If nothing (nil) is given, then the current land altitude is set.
-- @return #POINT_VEC2
function POINT_VEC2:AddAlt( Altitude )
  self.y = land.getHeight( { x = self.x, y = self.z } ) + Altitude or 0
  return self
end



--- Calculate the distance from a reference @{#POINT_VEC2}.
-- @param #POINT_VEC2 self
-- @param #POINT_VEC2 PointVec2Reference The reference @{#POINT_VEC2}.
-- @return Dcs.DCSTypes#Distance The distance from the reference @{#POINT_VEC2} in meters.
function POINT_VEC2:DistanceFromPointVec2( PointVec2Reference )
  self:F2( PointVec2Reference )
  
  local Distance = ( ( PointVec2Reference:GetX() - self:GetX() ) ^ 2 + ( PointVec2Reference:GetY() - self:GetY() ) ^2 ) ^0.5
  
  self:T2( Distance )
  return Distance
end

--- Calculate the distance from a reference @{DCSTypes#Vec2}.
-- @param #POINT_VEC2 self
-- @param Dcs.DCSTypes#Vec2 Vec2Reference The reference @{DCSTypes#Vec2}.
-- @return Dcs.DCSTypes#Distance The distance from the reference @{DCSTypes#Vec2} in meters.
function POINT_VEC2:DistanceFromVec2( Vec2Reference )
  self:F2( Vec2Reference )
  
  local Distance = ( ( Vec2Reference.x - self:GetX() ) ^ 2 + ( Vec2Reference.y - self:GetY() ) ^2 ) ^0.5
  
  self:T2( Distance )
  return Distance
end


--- Return no text for the altitude of the POINT_VEC2.
-- @param #POINT_VEC2 self
-- @return #string Empty string.
function POINT_VEC2:GetAltitudeText()
  return ''
end

--- Add a Distance in meters from the POINT_VEC2 orthonormal plane, with the given angle, and calculate the new POINT_VEC2.
-- @param #POINT_VEC2 self
-- @param Dcs.DCSTypes#Distance Distance The Distance to be added in meters.
-- @param Dcs.DCSTypes#Angle Angle The Angle in degrees.
-- @return #POINT_VEC2 The new calculated POINT_VEC2.
function POINT_VEC2:Translate( Distance, Angle )
  local SX = self:GetX()
  local SY = self:GetY()
  local Radians = Angle / 180 * math.pi
  local TX = Distance * math.cos( Radians ) + SX
  local TY = Distance * math.sin( Radians ) + SY
  
  return POINT_VEC2:New( TX, TY )
end

end


