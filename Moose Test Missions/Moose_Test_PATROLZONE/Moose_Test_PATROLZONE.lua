
local PatrolZoneGroup = GROUP:FindByName( "Patrol Zone" )
local PatrolZone = ZONE_POLYGON:New( "PatrolZone", PatrolZoneGroup )

local PatrolGroup = GROUP:FindByName( "Patrol Group" )

local Patrol = PATROLZONE:New( PatrolGroup, PatrolZone, 3000, 6000, 300, 600 )
Patrol:ManageFuel( 0.2, 60 )