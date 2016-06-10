
local US_PlanesClientSet = SET_CLIENT:New():FilterCountries( "USA" ):FilterCategories( "plane" ):FilterStart()
local US_PlanesSpawn = SPAWN:New( "AI US" )
local RU_AIBalancer = AIBALANCER:New( US_PlanesClientSet, US_PlanesSpawn )

local RU_PlanesClientSet = SET_CLIENT:New():FilterCountries( "RUSSIA" ):FilterCategories( "plane" ):FilterStart()
local RU_PlanesSpawn = SPAWN:New( "AI RU" )
local RU_AIBalancer = AIBALANCER:New( RU_PlanesClientSet, RU_PlanesSpawn )
