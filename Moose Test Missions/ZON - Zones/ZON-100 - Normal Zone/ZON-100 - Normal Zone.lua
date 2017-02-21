---
-- Name: ZON-100 - Normal Zone
-- Author: FlightControl
-- Date Created: 21 Feb 2017
--
-- # Situation:
-- 
-- A ZONE has been defined, which boundaries are smoking.
-- A vehicle is driving through the zone perimeters.
-- When the vehicle is driving in the zone, a red smoke is fired from the vehicle location.
-- 
-- # Test cases:
-- 
-- 1. Observe the zone perimeter smoke.
-- 2. Observe the vehicle smoking a red smoke when driving through the zone.


local GroupInside = GROUP:FindByName( "Test Inside Polygon" )
local GroupOutside = GROUP:FindByName( "Test Outside Polygon" )

local ZoneA = ZONE:New( "Zone A" )
ZoneA:SmokeZone( SMOKECOLOR.White, 90 )

Messager = SCHEDULER:New( nil,
  function()
    GroupInside:MessageToAll( ( GroupInside:IsCompletelyInZone( ZoneA ) ) and "Inside Zone A" or "Outside Zone A", 1 )
    if GroupInside:IsCompletelyInZone( ZoneA ) then
      GroupInside:GetUnit(1):SmokeRed()
    end
  end, 
  {}, 0, 1 )

