




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

