




local GroupInside = GROUP:FindByName( "Test Inside Polygon" )
local GroupOutside = GROUP:FindByName( "Test Outside Polygon" )

local GroupPolygon = GROUP:FindByName( "Polygon A" )

local PolygonZone = ZONE_POLYGON:New( "Polygon A", GroupPolygon ):SmokeZone( POINT_VEC3.SmokeColor.White, 20 )

Messager = SCHEDULER:New( nil,
  function()
    GroupInside:MessageToAll( ( GroupInside:IsCompletelyInZone( PolygonZone ) ) and "Inside Polygon A" or "Outside Polygon A", 1 )
    if GroupInside:IsCompletelyInZone( PolygonZone ) then
      GroupInside:GetUnit(1):SmokeRed()
    end
  end, 
  {}, 0, 1 )

