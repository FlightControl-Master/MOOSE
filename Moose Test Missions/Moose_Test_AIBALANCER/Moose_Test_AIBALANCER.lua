
local US_PlanesClientSet = SET_CLIENT:New():FilterCountries( "USA" ):FilterCategories( "plane" ):FilterStart()
local US_PlanesSpawn1 = SPAWN:New( "AI US 1" )
local US_PlanesSpawn2 = SPAWN:New( "AI US 2" )
local US_AIBalancer = AIBALANCER:New( US_PlanesClientSet, { US_PlanesSpawn1, US_PlanesSpawn2 } )

local RU_PlanesClientSet = SET_CLIENT:New():FilterCountries( "RUSSIA" ):FilterCategories( "plane" ):FilterStart()
local RU_PlanesSpawn = SPAWN:New( "AI RU" )
local RU_AIBalancer = AIBALANCER:New( RU_PlanesClientSet, RU_PlanesSpawn )

local RU_AirbasesSet = SET_AIRBASE:New():FilterCoalitions("red"):FilterStart()
RU_AirbasesSet:Flush()
RU_AIBalancer:ReturnToNearestAirbases( 10000, RU_AirbasesSet )
--RU_AIBalancer:ReturnToHomeAirbase( 10000 )

local PatrolZoneGroup = GROUP:FindByName( "Patrol Zone" )
local PatrolZone = ZONE_POLYGON:New( "PatrolZone", PatrolZoneGroup )
local PatrolZone = PATROLZONE:New( PatrolZone, 3000, 6000, 300, 600 ):ManageFuel( 0.2, 60 )
RU_AIBalancer:SetPatrolZone( PatrolZone )
