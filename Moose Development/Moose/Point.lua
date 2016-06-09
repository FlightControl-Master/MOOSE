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

-- Constructor.
  
--- Create a new POINT_VEC3 object.
-- @param #POINT_VEC3 self
-- @param DCSTypes#Distance x The x coordinate of the Vec3 point, pointing to the North.
-- @param DCSTypes#Distance y The y coordinate of the Vec3 point, pointing Upwards.
-- @param DCSTypes#Distance z The z coordinate of the Vec3 point, pointing to the Right.
-- @return Point#POINT_VEC3
function POINT_VEC3:New( x, y, z )

  local self = BASE:Inherit( self, BASE:New() )
  self:F2( { x, y, z } )
  self.PointVec3 = { x = x, y = y, z = z }
  return self
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

  return self
end


