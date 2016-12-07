
local RU_PlanesClientSet = SET_CLIENT:New():FilterCountries( "RUSSIA" ):FilterCategories( "plane" ):FilterStart()
local RU_PlanesSpawn = SPAWN:New( "AI RU" ):InitCleanUp( 20 )
local RU_AIBalancer = AIBALANCER:New( RU_PlanesClientSet, RU_PlanesSpawn )
