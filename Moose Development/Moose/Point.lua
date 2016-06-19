--- This module contains the POINT classes.
-- 
-- 1) @{Point#POINT_VEC3} class, extends @{Base#BASE}
-- ===============================================
-- The @{Point#POINT_VEC3} class defines a 3D point in the simulator.
-- 
-- 1.1) POINT_VEC3 constructor
-- ---------------------------
--  
-- A new POINT instance can be created with:
-- 
--  * @{#POINT_VEC3.New}(): a 3D point.
--
-- 2) @{Point#POINT_VEC2} class, extends @{Point#POINT_VEC3}
-- =========================================================
-- The @{Point#POINT_VEC2} class defines a 2D point in the simulator. The height coordinate (if needed) will be the land height + an optional added height specified.
-- 
-- 2.1) POINT_VEC2 constructor
-- ---------------------------
--  
-- A new POINT instance can be created with:
-- 
--  * @{#POINT_VEC2.New}(): a 2D point.
-- 
-- @module Point
-- @author FlightControl

--- The POINT_VEC3 class
-- @type POINT_VEC3
-- @extends Base#BASE
-- @field #POINT_VEC3.SmokeColor SmokeColor
-- @field #POINT_VEC3.FlareColor FlareColor
-- @field #POINT_VEC3.RoutePointAltType RoutePointAltType
-- @field #POINT_VEC3.RoutePointType RoutePointType
-- @field #POINT_VEC3.RoutePointAction RoutePointAction
POINT_VEC3 = {
  ClassName = "POINT_VEC3",
  SmokeColor = {
    Green = trigger.smokeColor.Green,
    Red = trigger.smokeColor.Red,
    White = trigger.smokeColor.White,
    Orange = trigger.smokeColor.Orange,
    Blue = trigger.smokeColor.Blue
  },
  FlareColor = {
    Green = trigger.flareColor.Green,
    Red = trigger.flareColor.Red,
    White = trigger.flareColor.White,
    Yellow = trigger.flareColor.Yellow
  },
  RoutePointAltType = {
    BARO = "BARO",
  },
  RoutePointType = {
    TurningPoint = "Turning Point",
  },
  RoutePointAction = {
    TurningPoint = "Turning Point",
  },
}


--- SmokeColor
-- @type POINT_VEC3.SmokeColor
-- @field Green
-- @field Red
-- @field White
-- @field Orange
-- @field Blue



--- FlareColor
-- @type POINT_VEC3.FlareColor
-- @field Green
-- @field Red
-- @field White
-- @field Yellow



--- RoutePoint AltTypes
-- @type POINT_VEC3.RoutePointAltType
-- @field BARO "BARO"



--- RoutePoint Types
-- @type POINT_VEC3.RoutePointType
-- @field TurningPoint "Turning Point"



--- RoutePoint Actions
-- @type POINT_VEC3.RoutePointAction
-- @field TurningPoint "Turning Point"



-- Constructor.
  
--- Create a new POINT_VEC3 object.
-- @param #POINT_VEC3 self
-- @param DCSTypes#Distance x The x coordinate of the Vec3 point, pointing to the North.
-- @param DCSTypes#Distance y The y coordinate of the Vec3 point, pointing Upwards.
-- @param DCSTypes#Distance z The z coordinate of the Vec3 point, pointing to the Right.
-- @return Point#POINT_VEC3 self
function POINT_VEC3:New( x, y, z )

  local self = BASE:Inherit( self, BASE:New() )
  self.PointVec3 = { x = x, y = y, z = z }
  self:F2( self.PointVec3 )
  return self
end


--- Build an air type route point.
-- @param #POINT_VEC3 self
-- @param #POINT_VEC3.RoutePointAltType AltType The altitude type.
-- @param #POINT_VEC3.RoutePointType Type The route point type.
-- @param #POINT_VEC3.RoutePointAction Action The route point action.
-- @param DCSTypes#Speed Speed Airspeed in km/h.
-- @param #boolean SpeedLocked true means the speed is locked.
-- @return #table The route point.
function POINT_VEC3:RoutePointAir( AltType, Type, Action, Speed, SpeedLocked )

  local RoutePoint = {}
  RoutePoint.x = self.PointVec3.x
  RoutePoint.y = self.PointVec3.z
  RoutePoint.alt = self.PointVec3.y
  RoutePoint.alt_type = AltType
  
  RoutePoint.type = Type
  RoutePoint.action = Action

  RoutePoint.speed = Speed
  RoutePoint.speed_locked = true

  RoutePoint.properties = {
    ["vnav"] = 1,
    ["scale"] = 0,
    ["angle"] = 0,
    ["vangle"] = 0,
    ["steer"] = 2,
  }
  
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


--- Smokes the point in a color.
-- @param #POINT_VEC3 self
-- @param Point#POINT_VEC3.SmokeColor SmokeColor
function POINT_VEC3:Smoke( SmokeColor )
  self:F2( { SmokeColor, self.PointVec3 } )
  trigger.action.smoke( self.PointVec3, SmokeColor )
end

--- Smoke the POINT_VEC3 Green.
-- @param #POINT_VEC3 self
function POINT_VEC3:SmokeGreen()
  self:F2()
  self:Smoke( POINT_VEC3.SmokeColor.Green )
end

--- Smoke the POINT_VEC3 Red.
-- @param #POINT_VEC3 self
function POINT_VEC3:SmokeRed()
  self:F2()
  self:Smoke( POINT_VEC3.SmokeColor.Red )
end

--- Smoke the POINT_VEC3 White.
-- @param #POINT_VEC3 self
function POINT_VEC3:SmokeWhite()
  self:F2()
  self:Smoke( POINT_VEC3.SmokeColor.White )
end

--- Smoke the POINT_VEC3 Orange.
-- @param #POINT_VEC3 self
function POINT_VEC3:SmokeOrange()
  self:F2()
  self:Smoke( POINT_VEC3.SmokeColor.Orange )
end

--- Smoke the POINT_VEC3 Blue.
-- @param #POINT_VEC3 self
function POINT_VEC3:SmokeBlue()
  self:F2()
  self:Smoke( POINT_VEC3.SmokeColor.Blue )
end

--- Flares the point in a color.
-- @param #POINT_VEC3 self
-- @param Point#POINT_VEC3.FlareColor
-- @param DCSTypes#Azimuth (optional) Azimuth The azimuth of the flare direction. The default azimuth is 0.
function POINT_VEC3:Flare( FlareColor, Azimuth )
  self:F2( { FlareColor, self.PointVec3 } )
  trigger.action.signalFlare( self.PointVec3, FlareColor, Azimuth and Azimuth or 0 )
end

--- Flare the POINT_VEC3 White.
-- @param #POINT_VEC3 self
-- @param DCSTypes#Azimuth (optional) Azimuth The azimuth of the flare direction. The default azimuth is 0.
function POINT_VEC3:FlareWhite( Azimuth )
  self:F2( Azimuth )
  self:Flare( POINT_VEC3.FlareColor.White, Azimuth )
end

--- Flare the POINT_VEC3 Yellow.
-- @param #POINT_VEC3 self
-- @param DCSTypes#Azimuth (optional) Azimuth The azimuth of the flare direction. The default azimuth is 0.
function POINT_VEC3:FlareYellow( Azimuth )
  self:F2( Azimuth )
  self:Flare( POINT_VEC3.FlareColor.Yellow, Azimuth )
end

--- Flare the POINT_VEC3 Green.
-- @param #POINT_VEC3 self
-- @param DCSTypes#Azimuth (optional) Azimuth The azimuth of the flare direction. The default azimuth is 0.
function POINT_VEC3:FlareGreen( Azimuth )
  self:F2( Azimuth )
  self:Flare( POINT_VEC3.FlareColor.Green, Azimuth )
end

--- Flare the POINT_VEC3 Red.
-- @param #POINT_VEC3 self
function POINT_VEC3:FlareRed( Azimuth )
  self:F2( Azimuth )
  self:Flare( POINT_VEC3.FlareColor.Red, Azimuth )
end


--- The POINT_VEC2 class
-- @type POINT_VEC2
-- @field DCSTypes#Vec2 PointVec2
-- @extends Point#POINT_VEC3
POINT_VEC2 = {
  ClassName = "POINT_VEC2",
  }

--- Create a new POINT_VEC2 object.
-- @param #POINT_VEC2 self
-- @param DCSTypes#Distance x The x coordinate of the Vec3 point, pointing to the North.
-- @param DCSTypes#Distance y The y coordinate of the Vec3 point, pointing to the Right.
-- @param DCSTypes#Distance LandHeightAdd (optional) The default height if required to be evaluated will be the land height of the x, y coordinate. You can specify an extra height to be added to the land height.
-- @return Point#POINT_VEC2
function POINT_VEC2:New( x, y, LandHeightAdd )

  local LandHeight = land.getHeight( { ["x"] = x, ["y"] = y } )
  if LandHeightAdd then
    LandHeight = LandHeight + LandHeightAdd
  end
  
  local self = BASE:Inherit( self, POINT_VEC3:New( x, LandHeight, y ) )
  self:F2( { x, y, LandHeightAdd } )
  
  self.PointVec2 = { x = x, y = y }

  return self
end

--- Calculate the distance from a reference @{Point#POINT_VEC2}.
-- @param #POINT_VEC2 self
-- @param #POINT_VEC2 PointVec2Reference The reference @{Point#POINT_VEC2}.
-- @return DCSTypes#Distance The distance from the reference @{Point#POINT_VEC2} in meters.
function POINT_VEC2:DistanceFromPointVec2( PointVec2Reference )
  self:F2( PointVec2Reference )
  
  local Distance = ( ( PointVec2Reference.PointVec2.x - self.PointVec2.x ) ^ 2 + ( PointVec2Reference.PointVec2.y - self.PointVec2.y ) ^2 ) ^0.5
  
  self:T2( Distance )
  return Distance
end

--- Calculate the distance from a reference @{DCSTypes#Vec2}.
-- @param #POINT_VEC2 self
-- @param DCSTypes#Vec2 Vec2Reference The reference @{DCSTypes#Vec2}.
-- @return DCSTypes#Distance The distance from the reference @{DCSTypes#Vec2} in meters.
function POINT_VEC2:DistanceFromVec2( Vec2Reference )
  self:F2( Vec2Reference )
  
  local Distance = ( ( Vec2Reference.x - self.PointVec2.x ) ^ 2 + ( Vec2Reference.y - self.PointVec2.y ) ^2 ) ^0.5
  
  self:T2( Distance )
  return Distance
end


