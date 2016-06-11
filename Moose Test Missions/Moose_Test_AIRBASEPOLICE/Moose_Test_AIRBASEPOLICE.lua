
local PlanesClientSet = SET_CLIENT:New():FilterCategories( "plane" ):FilterStart()
local AirbasePolice = AIRBASEPOLICE:New( PlanesClientSet )

local PolygonBatumiTaxiwaysGroup1 = GROUP:FindByName( "Polygon Batumi Taxiways" )
local PolygonBatumiTaxi = ZONE_POLYGON:New( "Batumi Taxi", PolygonBatumiTaxiwaysGroup1 ):SmokeZone(POINT_VEC3.SmokeColor.White)
