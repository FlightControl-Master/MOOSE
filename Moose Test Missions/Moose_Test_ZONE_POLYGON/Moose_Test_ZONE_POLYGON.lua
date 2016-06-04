
Include.File( "Zone" )
Include.File( "Group" )
Include.File( "Scheduler" )

local GroupInside = GROUP:FindByName( "Test Inside Polygon" )
local GroupOutside = GROUP:FindByName( "Test Outside Polygon" )

local GroupPolygon = GROUP:FindByName( "Polygon A" )

local PolygonZone = ZONE_POLYGON:New( "Polygon A", GroupPolygon )

local function Message()

  

end

Messager = SCHEDULER:New( nil,
  function()
    GroupInside:MessageToAll( ( GroupInside:IsCompletelyInZone( PolygonZone ) ) and "Inside Polygon A" or "Outside Polygon A", 0.5 )
    if GroupInside:IsCompletelyInZone( PolygonZone ) then
      GroupInside:GetUnit(1):SmokeWhite()
    end
  end, 
  {}, 0, 0.5 )

