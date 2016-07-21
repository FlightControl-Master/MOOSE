local GroupInside = GROUP:FindByName( "Test Inside Polygon" )
local GroupOutside = GROUP:FindByName( "Test Outside Polygon" )

local Tank = GROUP:FindByName( "Tank" )
local ZoneA = ZONE_GROUP:New( "Zone A", Tank, 100 )

Messager = SCHEDULER:New( nil,
  function()
    GroupInside:MessageToAll( ( GroupInside:IsCompletelyInZone( ZoneA ) ) and "Inside Zone A" or "Outside Zone A", 1 )
    if GroupInside:IsCompletelyInZone( ZoneA ) then
      GroupInside:GetUnit(1):SmokeRed()
    end
  end, 
  {}, 0, 1 )

TankZoneColoring = SCHEDULER:New( nil,
  function()
    ZoneA:FlareZone( POINT_VEC3.FlareColor.White, 90, 60 )
  end, 
  {}, 0, 5 )