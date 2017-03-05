---
-- Name: ZON-502 - Polygon Zone Boundary
-- Author: FlightControl
-- Date Created: 18 Feb 2017
--
-- # Situation:
-- 
-- A ZONE_POLYGON has been defined, which boundaries are tires.
-- A vehicle is driving through the zone perimeters.
-- When the vehicle is driving in the zone, a red smoke is fired from the vehicle location.
-- 
-- # Test cases:
-- 
-- 1. Observe the polygon perimeter smoke.
-- 2. Observe the vehicle smoking a red smoke when driving through the zone.
 
local GroupInside = GROUP:FindByName( "Test Inside Polygon" )
local GroupOutside = GROUP:FindByName( "Test Outside Polygon" )

local GroupPolygon = GROUP:FindByName( "Polygon A" )

local PolygonZone = ZONE_POLYGON:New( "Polygon A", GroupPolygon )
PolygonZone:BoundZone()

Messager = SCHEDULER:New( nil,
  function()
    GroupInside:MessageToAll( ( GroupInside:IsCompletelyInZone( PolygonZone ) ) and "Inside Polygon A" or "Outside Polygon A", 1 )
    if GroupInside:IsCompletelyInZone( PolygonZone ) then
      GroupInside:GetUnit(1):SmokeRed()
    end
  end, 
  {}, 0, 1 )

