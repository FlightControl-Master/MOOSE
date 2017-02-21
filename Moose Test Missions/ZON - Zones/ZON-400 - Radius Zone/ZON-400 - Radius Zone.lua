---
-- Name: ZON-400 - Radius Zone
-- Author: FlightControl
-- Date Created: 21 Feb 2017
--
-- # Situation:
-- 
-- A ZONE_RADIUS has been defined, which boundaries are smoking.
-- A vehicle is driving through the zone perimeters.
-- When the vehicle is driving in the zone, a red smoke is fired from the vehicle location.
-- 
-- # Test cases:
-- 
-- 1. Observe the polygon perimeter smoke.
-- 2. Observe the vehicle smoking a red smoke when driving through the zone.

local GroupInside = GROUP:FindByName( "Test Inside Polygon" )
local GroupOutside = GROUP:FindByName( "Test Outside Polygon" )

local House = STATIC:FindByName( "House" )
local ZoneA = ZONE_RADIUS:New( "Zone A", House:GetVec2(), 300 )
ZoneA:SmokeZone( SMOKECOLOR.White, 90 )

Messager = SCHEDULER:New( nil,
  function()
    GroupInside:MessageToAll( ( GroupInside:IsCompletelyInZone( ZoneA ) ) and "Inside Zone A" or "Outside Zone A", 1 )
    if GroupInside:IsCompletelyInZone( ZoneA ) then
      GroupInside:GetUnit(1):SmokeRed()
    end
  end, 
  {}, 0, 1 )

