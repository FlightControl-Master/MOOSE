
local US_PlanesClientSet = SET_CLIENT:New():FilterCountries( "USA" ):FilterCategories( "plane" ):FilterStart()

local US_PlanesSpawn = SPAWN:New( "AI US" ):InitCleanUp( 20 )
local US_AI_Balancer = AI_BALANCER:New( US_PlanesClientSet, US_PlanesSpawn )

local RU_PlanesClientSet = SET_CLIENT:New():FilterCountries( "RUSSIA" ):FilterCategories( "plane" ):FilterStart()
local RU_PlanesSpawn = SPAWN:New( "AI RU" ):InitCleanUp( 20 )
local RU_AI_Balancer = AI_BALANCER:New( RU_PlanesClientSet, RU_PlanesSpawn )

local RU_AirbasesSet = SET_AIRBASE:New():FilterCoalitions("red"):FilterStart()
RU_AirbasesSet:Flush()
RU_AI_Balancer:ReturnToNearestAirbases( 10000, RU_AirbasesSet )
--RU_AI_Balancer:ReturnToHomeAirbase( 10000 )

--local PatrolZoneGroup = GROUP:FindByName( "Patrol Zone Blue" )
--local PatrolZoneBlue = ZONE_POLYGON:New( "PatrolZone", PatrolZoneGroup )
--local PatrolZoneB = AI_PATROLZONE:New( PatrolZoneBlue, 3000, 6000, 900, 1100 ):ManageFuel( 0.2, 180 )
--US_AI_Balancer:SetPatrolZone( PatrolZoneB )
--
--local PatrolZoneGroup = GROUP:FindByName( "Patrol Zone Red" )
--local PatrolZoneRed = ZONE_POLYGON:New( "PatrolZone", PatrolZoneGroup )
--local PatrolZoneR = AI_PATROLZONE:New( PatrolZoneRed, 3000, 6000, 900, 1100 ):ManageFuel( 0.2, 180 )
--RU_AI_Balancer:SetPatrolZone( PatrolZoneR )
