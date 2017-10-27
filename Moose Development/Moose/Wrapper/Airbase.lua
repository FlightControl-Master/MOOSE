--- **Wrapper** -- AIRBASE is a wrapper class to handle the DCS Airbase objects.
-- 
-- ====
-- 
-- ### Author: **Sven Van de Velde (FlightControl)**
-- 
-- ### Contributions: 
-- 
-- ===
-- 
-- @module Airbase


--- @type AIRBASE
-- @extends Wrapper.Positionable#POSITIONABLE

--- # AIRBASE class, extends @{Positionable#POSITIONABLE}
-- 
-- AIRBASE is a wrapper class to handle the DCS Airbase objects:
-- 
--  * Support all DCS Airbase APIs.
--  * Enhance with Airbase specific APIs not in the DCS Airbase API set.
--  
-- ## AIRBASE reference methods
-- 
-- For each DCS Airbase object alive within a running mission, a AIRBASE wrapper object (instance) will be created within the _@{DATABASE} object.
-- This is done at the beginning of the mission (when the mission starts).
--  
-- The AIRBASE class **does not contain a :New()** method, rather it provides **:Find()** methods to retrieve the object reference
-- using the DCS Airbase or the DCS AirbaseName.
-- 
-- Another thing to know is that AIRBASE objects do not "contain" the DCS Airbase object. 
-- The AIRBASE methods will reference the DCS Airbase object by name when it is needed during API execution.
-- If the DCS Airbase object does not exist or is nil, the AIRBASE methods will return nil and log an exception in the DCS.log file.
--  
-- The AIRBASE class provides the following functions to retrieve quickly the relevant AIRBASE instance:
-- 
--  * @{#AIRBASE.Find}(): Find a AIRBASE instance from the _DATABASE object using a DCS Airbase object.
--  * @{#AIRBASE.FindByName}(): Find a AIRBASE instance from the _DATABASE object using a DCS Airbase name.
--  
-- IMPORTANT: ONE SHOULD NEVER SANATIZE these AIRBASE OBJECT REFERENCES! (make the AIRBASE object references nil).
-- 
-- ## DCS Airbase APIs
-- 
-- The DCS Airbase APIs are used extensively within MOOSE. The AIRBASE class has for each DCS Airbase API a corresponding method.
-- To be able to distinguish easily in your code the difference between a AIRBASE API call and a DCS Airbase API call,
-- the first letter of the method is also capitalized. So, by example, the DCS Airbase method @{DCSWrapper.Airbase#Airbase.getName}()
-- is implemented in the AIRBASE class as @{#AIRBASE.GetName}().
-- 
-- @field #AIRBASE AIRBASE
AIRBASE = {
  ClassName="AIRBASE",
  CategoryName = { 
    [Airbase.Category.AIRDROME]   = "Airdrome",
    [Airbase.Category.HELIPAD]    = "Helipad",
    [Airbase.Category.SHIP]       = "Ship",
    },
  }

--- Enumeration to identify the airbases in the Caucasus region.
-- 
-- These are all airbases of Caucasus:
-- 
--   * AIRBASE.Caucasus.Gelendzhik
--   * AIRBASE.Caucasus.Krasnodar_Pashkovsky
--   * AIRBASE.Caucasus.Sukhumi_Babushara
--   * AIRBASE.Caucasus.Gudauta
--   * AIRBASE.Caucasus.Batumi
--   * AIRBASE.Caucasus.Senaki_Kolkhi
--   * AIRBASE.Caucasus.Kobuleti
--   * AIRBASE.Caucasus.Kutaisi
--   * AIRBASE.Caucasus.Tbilisi_Lochini
--   * AIRBASE.Caucasus.Soganlug
--   * AIRBASE.Caucasus.Vaziani
--   * AIRBASE.Caucasus.Anapa_Vityazevo
--   * AIRBASE.Caucasus.Krasnodar_Center
--   * AIRBASE.Caucasus.Novorossiysk
--   * AIRBASE.Caucasus.Krymsk
--   * AIRBASE.Caucasus.Maykop_Khanskaya
--   * AIRBASE.Caucasus.Sochi_Adler
--   * AIRBASE.Caucasus.Mineralnye_Vody
--   * AIRBASE.Caucasus.Nalchik
--   * AIRBASE.Caucasus.Mozdok
--   * AIRBASE.Caucasus.Beslan
--   
-- @field Caucasus
AIRBASE.Caucasus = {
  ["Gelendzhik"] = "Gelendzhik",
  ["Krasnodar_Pashkovsky"] = "Krasnodar-Pashkovsky",
  ["Sukhumi_Babushara"] = "Sukhumi-Babushara",
  ["Gudauta"] = "Gudauta",
  ["Batumi"] = "Batumi",
  ["Senaki_Kolkhi"] = "Senaki-Kolkhi",
  ["Kobuleti"] = "Kobuleti",
  ["Kutaisi"] = "Kutaisi",
  ["Tbilisi_Lochini"] = "Tbilisi-Lochini",
  ["Soganlug"] = "Soganlug",
  ["Vaziani"] = "Vaziani",
  ["Anapa_Vityazevo"] = "Anapa-Vityazevo",
  ["Krasnodar_Center"] = "Krasnodar-Center",
  ["Novorossiysk"] = "Novorossiysk",
  ["Krymsk"] = "Krymsk",
  ["Maykop_Khanskaya"] = "Maykop-Khanskaya",
  ["Sochi_Adler"] = "Sochi-Adler",
  ["Mineralnye_Vody"] = "Mineralnye Vody",
  ["Nalchik"] = "Nalchik",
  ["Mozdok"] = "Mozdok",
  ["Beslan"] = "Beslan",
  }
  
--- @field Nevada
-- 
-- These are all airbases of Nevada:
-- 
--   * AIRBASE.Nevada.Creech_AFB
--   * AIRBASE.Nevada.Groom_Lake_AFB
--   * AIRBASE.Nevada.McCarran_International_Airport
--   * AIRBASE.Nevada.Nellis_AFB
--   * AIRBASE.Nevada.Beatty_Airport
--   * AIRBASE.Nevada.Boulder_City_Airport
--   * AIRBASE.Nevada.Echo_Bay
--   * AIRBASE.Nevada.Henderson_Executive_Airport
--   * AIRBASE.Nevada.Jean_Airport
--   * AIRBASE.Nevada.Laughlin_Airport
--   * AIRBASE.Nevada.Lincoln_County
--   * AIRBASE.Nevada.Mellan_Airstrip
--   * AIRBASE.Nevada.Mesquite
--   * AIRBASE.Nevada.Mina_Airport_3Q0
--   * AIRBASE.Nevada.North_Las_Vegas
--   * AIRBASE.Nevada.Pahute_Mesa_Airstrip
--   * AIRBASE.Nevada.Tonopah_Airport
--   * AIRBASE.Nevada.Tonopah_Test_Range_Airfield
--   
AIRBASE.Nevada = {
  ["Creech_AFB"] = "Creech AFB",
  ["Groom_Lake_AFB"] = "Groom Lake AFB",
  ["McCarran_International_Airport"] = "McCarran International Airport",
  ["Nellis_AFB"] = "Nellis AFB",
  ["Beatty_Airport"] = "Beatty Airport",
  ["Boulder_City_Airport"] = "Boulder City Airport",
  ["Echo_Bay"] = "Echo Bay",
  ["Henderson_Executive_Airport"] = "Henderson Executive Airport",
  ["Jean_Airport"] = "Jean Airport",
  ["Laughlin_Airport"] = "Laughlin Airport",
  ["Lincoln_County"] = "Lincoln County",
  ["Mellan_Airstrip"] = "Mellan Airstrip",
  ["Mesquite"] = "Mesquite",
  ["Mina_Airport_3Q0"] = "Mina Airport 3Q0",
  ["North_Las_Vegas"] = "North Las Vegas",
  ["Pahute_Mesa_Airstrip"] = "Pahute Mesa Airstrip",
  ["Tonopah_Airport"] = "Tonopah Airport",
  ["Tonopah_Test_Range_Airfield"] = "Tonopah Test Range Airfield",
  }

--- @field Normandy
-- 
-- These are all airbases of Normandy:
-- 
--   * AIRBASE.Normandy.Saint_Pierre_du_Mont
--   * AIRBASE.Normandy.Lignerolles
--   * AIRBASE.Normandy.Cretteville
--   * AIRBASE.Normandy.Maupertus
--   * AIRBASE.Normandy.Brucheville
--   * AIRBASE.Normandy.Meautis
--   * AIRBASE.Normandy.Cricqueville_en_Bessin
--   * AIRBASE.Normandy.Lessay
--   * AIRBASE.Normandy.Sainte_Laurent_sur_Mer
--   * AIRBASE.Normandy.Biniville
--   * AIRBASE.Normandy.Cardonville
--   * AIRBASE.Normandy.Deux_Jumeaux
--   * AIRBASE.Normandy.Chippelle
--   * AIRBASE.Normandy.Beuzeville
--   * AIRBASE.Normandy.Azeville
--   * AIRBASE.Normandy.Picauville
--   * AIRBASE.Normandy.Le_Molay
--   * AIRBASE.Normandy.Longues_sur_Mer
--   * AIRBASE.Normandy.Carpiquet
--   * AIRBASE.Normandy.Bazenville
--   * AIRBASE.Normandy.Sainte_Croix_sur_Mer
--   * AIRBASE.Normandy.Beny_sur_Mer
--   * AIRBASE.Normandy.Rucqueville
--   * AIRBASE.Normandy.Sommervieu
--   * AIRBASE.Normandy.Lantheuil
--   * AIRBASE.Normandy.Evreux
--   * AIRBASE.Normandy.Chailey
--   * AIRBASE.Normandy.Needs_Oar_Point
--   * AIRBASE.Normandy.Funtington
--   * AIRBASE.Normandy.Tangmere
--   * AIRBASE.Normandy.Ford
AIRBASE.Normandy = {
  ["Saint_Pierre_du_Mont"] = "Saint Pierre du Mont",
  ["Lignerolles"] = "Lignerolles",
  ["Cretteville"] = "Cretteville",
  ["Maupertus"] = "Maupertus",
  ["Brucheville"] = "Brucheville",
  ["Meautis"] = "Meautis",
  ["Cricqueville_en_Bessin"] = "Cricqueville-en-Bessin",
  ["Lessay"] = "Lessay",
  ["Sainte_Laurent_sur_Mer"] = "Sainte-Laurent-sur-Mer",
  ["Biniville"] = "Biniville",
  ["Cardonville"] = "Cardonville",
  ["Deux_Jumeaux"] = "Deux Jumeaux",
  ["Chippelle"] = "Chippelle",
  ["Beuzeville"] = "Beuzeville",
  ["Azeville"] = "Azeville",
  ["Picauville"] = "Picauville",
  ["Le_Molay"] = "Le Molay",
  ["Longues_sur_Mer"] = "Longues-sur-Mer",
  ["Carpiquet"] = "Carpiquet",
  ["Bazenville"] = "Bazenville",
  ["Sainte_Croix_sur_Mer"] = "Sainte-Croix-sur-Mer",
  ["Beny_sur_Mer"] = "Beny-sur-Mer",
  ["Rucqueville"] = "Rucqueville",
  ["Sommervieu"] = "Sommervieu",
  ["Lantheuil"] = "Lantheuil",
  ["Evreux"] = "Evreux",
  ["Chailey"] = "Chailey",
  ["Needs_Oar_Point"] = "Needs Oar Point",
  ["Funtington"] = "Funtington",
  ["Tangmere"] = "Tangmere",
  ["Ford"] = "Ford",
  }

-- Registration.
  
--- Create a new AIRBASE from DCSAirbase.
-- @param #AIRBASE self
-- @param #string AirbaseName The name of the airbase.
-- @return Wrapper.Airbase#AIRBASE
function AIRBASE:Register( AirbaseName )

  local self = BASE:Inherit( self, POSITIONABLE:New( AirbaseName ) )
  self.AirbaseName = AirbaseName
  self.AirbaseZone = ZONE_RADIUS:New( AirbaseName, self:GetVec2(), 2500 )
  return self
end

-- Reference methods.

--- Finds a AIRBASE from the _DATABASE using a DCSAirbase object.
-- @param #AIRBASE self
-- @param Dcs.DCSWrapper.Airbase#Airbase DCSAirbase An existing DCS Airbase object reference.
-- @return Wrapper.Airbase#AIRBASE self
function AIRBASE:Find( DCSAirbase )

  local AirbaseName = DCSAirbase:getName()
  local AirbaseFound = _DATABASE:FindAirbase( AirbaseName )
  return AirbaseFound
end

--- Find a AIRBASE in the _DATABASE using the name of an existing DCS Airbase.
-- @param #AIRBASE self
-- @param #string AirbaseName The Airbase Name.
-- @return Wrapper.Airbase#AIRBASE self
function AIRBASE:FindByName( AirbaseName )
  
  local AirbaseFound = _DATABASE:FindAirbase( AirbaseName )
  return AirbaseFound
end

function AIRBASE:GetDCSObject()
  local DCSAirbase = Airbase.getByName( self.AirbaseName )
  
  if DCSAirbase then
    return DCSAirbase
  end
    
  return nil
end

--- Get the airbase zone.
-- @param #AIRBASE self
-- @return Core.Zone#ZONE_RADIUS The zone radius of the airbase.
function AIRBASE:GetZone()
  return self.AirbaseZone
end



