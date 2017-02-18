---
-- Name: ZON-401 - Radius Zone - Random Point
-- Author: FlightControl
-- Date Created: 18 Feb 2017
--
-- # Situation:
-- 
-- Three zones are defined.
-- 15 points are smoked in each zone.
-- The first 15 points are blue smoked using the GetRandomVec2() API.
-- The second 15 points are orange smoked using the GetRandomPointVec2() API.
-- The third 15 points are red smoked using the GetRandomPointVec3() API.
-- Note: The zones perimeters are also smoked in white, so you can observe the random point placement.
-- Note: At each zone an vehicle is placed, so you can view the smoking in external view.
-- 
-- # Test cases:
-- 
-- 1. Observe smoking of Blue smoke in Zone 1.
-- 2. Observe smoking of Orange smoke in Zone 2.
-- 3. Observe smoking of Red smoke in Zone 3. 

local Unit1 = UNIT:FindByName( "Zone 1" )
local Unit2 = UNIT:FindByName( "Zone 2" )
local Unit3 = UNIT:FindByName( "Zone 3" )


local Zone1 = ZONE_RADIUS:New( "Zone 1", Unit1:GetVec2(), 300 )
local Zone2 = ZONE_RADIUS:New( "Zone 2", Unit2:GetVec2(), 300 )
local Zone3 = ZONE_RADIUS:New( "Zone 3", Unit3:GetVec2(), 300 )

Zone1:SmokeZone( SMOKECOLOR.White, 18 )
Zone2:SmokeZone( SMOKECOLOR.White, 18 )
Zone3:SmokeZone( SMOKECOLOR.White, 18 )

for i = 1, 15 do
  -- Zone 1
  local Vec2 = Zone1:GetRandomVec2()
  local PointVec2 = POINT_VEC2:NewFromVec2( Vec2 )
  PointVec2:SmokeBlue()
  
  -- Zone 2
  local PointVec2 = Zone2:GetRandomPointVec2()
  PointVec2:SmokeOrange()
  
  -- Zone 3
  local PointVec3 = Zone3:GetRandomPointVec3()
  PointVec3:SmokeRed()
end
