--- **Wrapper** - AIRBASE is a wrapper class to handle the DCS Airbase objects.
--
-- ===
--
-- ### Author: **FlightControl**
--
-- ### Contributions: **funkyfranky**
--
-- ===
--
-- @module Wrapper.Airbase
-- @image Wrapper_Airbase.JPG

---
-- @type AIRBASE
-- @field #string ClassName Name of the class, i.e. "AIRBASE".
-- @field #table CategoryName Names of airbase categories.
-- @field #string AirbaseName Name of the airbase.
-- @field #number AirbaseID Airbase ID.
-- @field Core.Zone#ZONE AirbaseZone Circular zone around the airbase with a radius of 2500 meters. For ships this is a ZONE_UNIT object.
-- @field #number category Airbase category.
-- @field #table descriptors DCS descriptors.
-- @field #boolean isAirdrome Airbase is an airdrome.
-- @field #boolean isHelipad Airbase is a helipad.
-- @field #boolean isShip Airbase is a ship.
-- @field #table parking Parking spot data.
-- @field #table parkingByID Parking spot data table with ID as key.
-- @field #table parkingWhitelist List of parking spot terminal IDs considered for spawning.
-- @field #table parkingBlacklist List of parking spot terminal IDs **not** considered for spawning.
-- @field #table runways Runways of airdromes.
-- @field #AIRBASE.Runway runwayLanding Runway used for landing.
-- @field #AIRBASE.Runway runwayTakeoff Runway used for takeoff.
-- @field Wrapper.Storage#STORAGE storage The DCS warehouse storage.
-- @extends Wrapper.Positionable#POSITIONABLE

--- Wrapper class to handle the DCS Airbase objects:
--
--  * Support all DCS Airbase APIs.
--  * Enhance with Airbase specific APIs not in the DCS Airbase API set.
--
-- ## AIRBASE reference methods
--
-- For each DCS Airbase object alive within a running mission, a AIRBASE wrapper object (instance) will be created within the global _DATABASE object (an instance of @{Core.Database#DATABASE}).
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
--  * @{#AIRBASE.Find}(): Find a AIRBASE instance from the global _DATABASE object (an instance of @{Core.Database#DATABASE}) using a DCS Airbase object.
--  * @{#AIRBASE.FindByName}(): Find a AIRBASE instance from the global _DATABASE object (an instance of @{Core.Database#DATABASE}) using a DCS Airbase name.
--
-- IMPORTANT: ONE SHOULD NEVER SANITIZE these AIRBASE OBJECT REFERENCES! (make the AIRBASE object references nil).
--
-- ## DCS Airbase APIs
--
-- The DCS Airbase APIs are used extensively within MOOSE. The AIRBASE class has for each DCS Airbase API a corresponding method.
-- To be able to distinguish easily in your code the difference between a AIRBASE API call and a DCS Airbase API call,
-- the first letter of the method is also capitalized. So, by example, the DCS Airbase method DCSWrapper.Airbase#Airbase.getName()
-- is implemented in the AIRBASE class as @{#AIRBASE.GetName}().
-- 
-- ## Note on the "H" heli pads in the Syria map:
-- 
-- As of the time of writing (Oct 2024, DCS DCS 2.9.8.1107), these 143 objects have the **same name and object ID**, which makes them unusable in Moose, e.g. you cannot find a specific one for spawning etc.
-- Waiting for Ugra and ED to fix this issue.
--
-- @field #AIRBASE AIRBASE
AIRBASE = {
  ClassName = "AIRBASE",
  CategoryName = {
    [Airbase.Category.AIRDROME] = "Airdrome",
    [Airbase.Category.HELIPAD] = "Helipad",
    [Airbase.Category.SHIP] = "Ship",
  },
  activerwyno = nil,
}

--- Enumeration to identify the airbases in the Caucasus region.
--
-- Airbases of the Caucasus map:
--
-- * AIRBASE.Caucasus.Anapa_Vityazevo
-- * AIRBASE.Caucasus.Batumi
-- * AIRBASE.Caucasus.Beslan
-- * AIRBASE.Caucasus.Gelendzhik
-- * AIRBASE.Caucasus.Gudauta
-- * AIRBASE.Caucasus.Kobuleti
-- * AIRBASE.Caucasus.Krasnodar_Center
-- * AIRBASE.Caucasus.Krasnodar_Pashkovsky
-- * AIRBASE.Caucasus.Krymsk
-- * AIRBASE.Caucasus.Kutaisi
-- * AIRBASE.Caucasus.Maykop_Khanskaya
-- * AIRBASE.Caucasus.Mineralnye_Vody
-- * AIRBASE.Caucasus.Mozdok
-- * AIRBASE.Caucasus.Nalchik
-- * AIRBASE.Caucasus.Novorossiysk
-- * AIRBASE.Caucasus.Senaki_Kolkhi
-- * AIRBASE.Caucasus.Sochi_Adler
-- * AIRBASE.Caucasus.Soganlug
-- * AIRBASE.Caucasus.Sukhumi_Babushara
-- * AIRBASE.Caucasus.Tbilisi_Lochini
-- * AIRBASE.Caucasus.Vaziani
--
-- @field Caucasus
AIRBASE.Caucasus = {
  ["Anapa_Vityazevo"] = "Anapa-Vityazevo",
  ["Batumi"] = "Batumi",
  ["Beslan"] = "Beslan",
  ["Gelendzhik"] = "Gelendzhik",
  ["Gudauta"] = "Gudauta",
  ["Kobuleti"] = "Kobuleti",
  ["Krasnodar_Center"] = "Krasnodar-Center",
  ["Krasnodar_Pashkovsky"] = "Krasnodar-Pashkovsky",
  ["Krymsk"] = "Krymsk",
  ["Kutaisi"] = "Kutaisi",
  ["Maykop_Khanskaya"] = "Maykop-Khanskaya",
  ["Mineralnye_Vody"] = "Mineralnye Vody",
  ["Mozdok"] = "Mozdok",
  ["Nalchik"] = "Nalchik",
  ["Novorossiysk"] = "Novorossiysk",
  ["Senaki_Kolkhi"] = "Senaki-Kolkhi",
  ["Sochi_Adler"] = "Sochi-Adler",
  ["Soganlug"] = "Soganlug",
  ["Sukhumi_Babushara"] = "Sukhumi-Babushara",
  ["Tbilisi_Lochini"] = "Tbilisi-Lochini",
  ["Vaziani"] = "Vaziani",
}

--- Airbases of the Nevada map:
--
-- * AIRBASE.Nevada.Beatty
-- * AIRBASE.Nevada.Boulder_City
-- * AIRBASE.Nevada.Creech
-- * AIRBASE.Nevada.Echo_Bay
-- * AIRBASE.Nevada.Groom_Lake
-- * AIRBASE.Nevada.Henderson_Executive
-- * AIRBASE.Nevada.Jean
-- * AIRBASE.Nevada.Laughlin
-- * AIRBASE.Nevada.Lincoln_County
-- * AIRBASE.Nevada.McCarran_International
-- * AIRBASE.Nevada.Mesquite
-- * AIRBASE.Nevada.Mina
-- * AIRBASE.Nevada.Nellis
-- * AIRBASE.Nevada.North_Las_Vegas
-- * AIRBASE.Nevada.Pahute_Mesa
-- * AIRBASE.Nevada.Tonopah
-- * AIRBASE.Nevada.Tonopah_Test_Range
--
-- @field Nevada
AIRBASE.Nevada = {
  ["Beatty"] = "Beatty",
  ["Boulder_City"] = "Boulder City",
  ["Creech"] = "Creech",
  ["Echo_Bay"] = "Echo Bay",
  ["Groom_Lake"] = "Groom Lake",
  ["Henderson_Executive"] = "Henderson Executive",
  ["Jean"] = "Jean",
  ["Laughlin"] = "Laughlin",
  ["Lincoln_County"] = "Lincoln County",
  ["McCarran_International"] = "McCarran International",
  ["Mesquite"] = "Mesquite",
  ["Mina"] = "Mina",
  ["Nellis"] = "Nellis",
  ["North_Las_Vegas"] = "North Las Vegas",
  ["Pahute_Mesa"] = "Pahute Mesa",
  ["Tonopah"] = "Tonopah",
  ["Tonopah_Test_Range"] = "Tonopah Test Range",
}

--- Airbases of the Normandy map:
--
-- * AIRBASE.Normandy.Abbeville_Drucat
-- * AIRBASE.Normandy.Amiens_Glisy
-- * AIRBASE.Normandy.Argentan
-- * AIRBASE.Normandy.Avranches_Le_Val_Saint_Pere
-- * AIRBASE.Normandy.Azeville
-- * AIRBASE.Normandy.Barville
-- * AIRBASE.Normandy.Bazenville
-- * AIRBASE.Normandy.Beaumont_le_Roger
-- * AIRBASE.Normandy.Beauvais_Tille
-- * AIRBASE.Normandy.Beny_sur_Mer
-- * AIRBASE.Normandy.Bernay_Saint_Martin
-- * AIRBASE.Normandy.Beuzeville
-- * AIRBASE.Normandy.Biggin_Hill
-- * AIRBASE.Normandy.Biniville
-- * AIRBASE.Normandy.Broglie
-- * AIRBASE.Normandy.Brucheville
-- * AIRBASE.Normandy.Cardonville
-- * AIRBASE.Normandy.Carpiquet
-- * AIRBASE.Normandy.Chailey
-- * AIRBASE.Normandy.Chippelle
-- * AIRBASE.Normandy.Conches
-- * AIRBASE.Normandy.Cormeilles_en_Vexin
-- * AIRBASE.Normandy.Creil
-- * AIRBASE.Normandy.Cretteville
-- * AIRBASE.Normandy.Cricqueville_en_Bessin
-- * AIRBASE.Normandy.Deanland
-- * AIRBASE.Normandy.Deauville
-- * AIRBASE.Normandy.Detling
-- * AIRBASE.Normandy.Deux_Jumeaux
-- * AIRBASE.Normandy.Dinan_Trelivan
-- * AIRBASE.Normandy.Dunkirk_Mardyck
-- * AIRBASE.Normandy.Essay
-- * AIRBASE.Normandy.Evreux
-- * AIRBASE.Normandy.Farnborough
-- * AIRBASE.Normandy.Fecamp_Benouville
-- * AIRBASE.Normandy.Flers
-- * AIRBASE.Normandy.Ford
-- * AIRBASE.Normandy.Friston
-- * AIRBASE.Normandy.Funtington
-- * AIRBASE.Normandy.Goulet
-- * AIRBASE.Normandy.Gravesend
-- * AIRBASE.Normandy.Guyancourt
-- * AIRBASE.Normandy.Hauterive
-- * AIRBASE.Normandy.Heathrow
-- * AIRBASE.Normandy.High_Halden
-- * AIRBASE.Normandy.Kenley
-- * AIRBASE.Normandy.Lantheuil
-- * AIRBASE.Normandy.Le_Molay
-- * AIRBASE.Normandy.Lessay
-- * AIRBASE.Normandy.Lignerolles
-- * AIRBASE.Normandy.Longues_sur_Mer
-- * AIRBASE.Normandy.Lonrai
-- * AIRBASE.Normandy.Lymington
-- * AIRBASE.Normandy.Lympne
-- * AIRBASE.Normandy.Manston
-- * AIRBASE.Normandy.Maupertus
-- * AIRBASE.Normandy.Meautis
-- * AIRBASE.Normandy.Merville_Calonne
-- * AIRBASE.Normandy.Needs_Oar_Point
-- * AIRBASE.Normandy.Odiham
-- * AIRBASE.Normandy.Orly
-- * AIRBASE.Normandy.Picauville
-- * AIRBASE.Normandy.Poix
-- * AIRBASE.Normandy.Ronai
-- * AIRBASE.Normandy.Rouen_Boos
-- * AIRBASE.Normandy.Rucqueville
-- * AIRBASE.Normandy.Saint_Andre_de_lEure
-- * AIRBASE.Normandy.Saint_Aubin
-- * AIRBASE.Normandy.Saint_Omer_Wizernes
-- * AIRBASE.Normandy.Saint_Pierre_du_Mont
-- * AIRBASE.Normandy.Sainte_Croix_sur_Mer
-- * AIRBASE.Normandy.Sainte_Laurent_sur_Mer
-- * AIRBASE.Normandy.Sommervieu
-- * AIRBASE.Normandy.Stoney_Cross
-- * AIRBASE.Normandy.Tangmere
-- * AIRBASE.Normandy.Triqueville
-- * AIRBASE.Normandy.Villacoublay
-- * AIRBASE.Normandy.Vrigny
-- * AIRBASE.Normandy.West_Malling
-- * AIRBASE.Normandy.Eastchurch
-- * AIRBASE.Normandy.Headcorn
-- * AIRBASE.Normandy.Hawkinge
--
-- @field Normandy
AIRBASE.Normandy = {
  ["Abbeville_Drucat"] = "Abbeville Drucat",
  ["Amiens_Glisy"] = "Amiens-Glisy",
  ["Argentan"] = "Argentan",
  ["Avranches_Le_Val_Saint_Pere"] = "Avranches Le Val-Saint-Pere",
  ["Azeville"] = "Azeville",
  ["Barville"] = "Barville",
  ["Bazenville"] = "Bazenville",
  ["Beaumont_le_Roger"] = "Beaumont-le-Roger",
  ["Beauvais_Tille"] = "Beauvais-Tille",
  ["Beny_sur_Mer"] = "Beny-sur-Mer",
  ["Bernay_Saint_Martin"] = "Bernay Saint Martin",
  ["Beuzeville"] = "Beuzeville",
  ["Biggin_Hill"] = "Biggin Hill",
  ["Biniville"] = "Biniville",
  ["Broglie"] = "Broglie",
  ["Brucheville"] = "Brucheville",
  ["Cardonville"] = "Cardonville",
  ["Carpiquet"] = "Carpiquet",
  ["Chailey"] = "Chailey",
  ["Chippelle"] = "Chippelle",
  ["Conches"] = "Conches",
  ["Cormeilles_en_Vexin"] = "Cormeilles-en-Vexin",
  ["Creil"] = "Creil",
  ["Cretteville"] = "Cretteville",
  ["Cricqueville_en_Bessin"] = "Cricqueville-en-Bessin",
  ["Deanland"] = "Deanland",
  ["Deauville"] = "Deauville",
  ["Detling"] = "Detling",
  ["Deux_Jumeaux"] = "Deux Jumeaux",
  ["Dinan_Trelivan"] = "Dinan-Trelivan",
  ["Dunkirk_Mardyck"] = "Dunkirk-Mardyck",
  ["Essay"] = "Essay",
  ["Evreux"] = "Evreux",
  ["Farnborough"] = "Farnborough",
  ["Fecamp_Benouville"] = "Fecamp-Benouville",
  ["Flers"] = "Flers",
  ["Ford"] = "Ford",
  ["Friston"] = "Friston",
  ["Funtington"] = "Funtington",
  ["Goulet"] = "Goulet",
  ["Gravesend"] = "Gravesend",
  ["Guyancourt"] = "Guyancourt",
  ["Hauterive"] = "Hauterive",
  ["Heathrow"] = "Heathrow",
  ["High_Halden"] = "High Halden",
  ["Kenley"] = "Kenley",
  ["Lantheuil"] = "Lantheuil",
  ["Le_Molay"] = "Le Molay",
  ["Lessay"] = "Lessay",
  ["Lignerolles"] = "Lignerolles",
  ["Longues_sur_Mer"] = "Longues-sur-Mer",
  ["Lonrai"] = "Lonrai",
  ["Lymington"] = "Lymington",
  ["Lympne"] = "Lympne",
  ["Manston"] = "Manston",
  ["Maupertus"] = "Maupertus",
  ["Meautis"] = "Meautis",
  ["Merville_Calonne"] = "Merville Calonne",
  ["Needs_Oar_Point"] = "Needs Oar Point",
  ["Odiham"] = "Odiham",
  ["Orly"] = "Orly",
  ["Picauville"] = "Picauville",
  ["Poix"] = "Poix",
  ["Ronai"] = "Ronai",
  ["Rouen_Boos"] = "Rouen-Boos",
  ["Rucqueville"] = "Rucqueville",
  ["Saint_Andre_de_lEure"] = "Saint-Andre-de-lEure",
  ["Saint_Aubin"] = "Saint-Aubin",
  ["Saint_Omer_Wizernes"] = "Saint-Omer Wizernes",
  ["Saint_Pierre_du_Mont"] = "Saint Pierre du Mont",
  ["Sainte_Croix_sur_Mer"] = "Sainte-Croix-sur-Mer",
  ["Sainte_Laurent_sur_Mer"] = "Sainte-Laurent-sur-Mer",
  ["Sommervieu"] = "Sommervieu",
  ["Stoney_Cross"] = "Stoney Cross",
  ["Tangmere"] = "Tangmere",
  ["Triqueville"] = "Triqueville",
  ["Villacoublay"] = "Villacoublay",
  ["Vrigny"] = "Vrigny",
  ["West_Malling"] = "West Malling",
  ["Eastchurch"] = "Eastchurch",
  ["Headcorn"] = "Headcorn",
  ["Hawkinge"] = "Hawkinge",
}

--- Airbases of the Persion Gulf Map:
--
-- * AIRBASE.PersianGulf.Abu_Dhabi_Intl
-- * AIRBASE.PersianGulf.Abu_Musa_Island
-- * AIRBASE.PersianGulf.Al_Ain_Intl
-- * AIRBASE.PersianGulf.Al_Bateen
-- * AIRBASE.PersianGulf.Al_Dhafra_AFB
-- * AIRBASE.PersianGulf.Al_Maktoum_Intl
-- * AIRBASE.PersianGulf.Al_Minhad_AFB
-- * AIRBASE.PersianGulf.Bandar_Abbas_Intl
-- * AIRBASE.PersianGulf.Bandar_Lengeh
-- * AIRBASE.PersianGulf.Bandar_e_Jask
-- * AIRBASE.PersianGulf.Dubai_Intl
-- * AIRBASE.PersianGulf.Fujairah_Intl
-- * AIRBASE.PersianGulf.Havadarya
-- * AIRBASE.PersianGulf.Jiroft
-- * AIRBASE.PersianGulf.Kerman
-- * AIRBASE.PersianGulf.Khasab
-- * AIRBASE.PersianGulf.Kish_Intl
-- * AIRBASE.PersianGulf.Lar
-- * AIRBASE.PersianGulf.Lavan_Island
-- * AIRBASE.PersianGulf.Liwa_AFB
-- * AIRBASE.PersianGulf.Qeshm_Island
-- * AIRBASE.PersianGulf.Quasoura_airport
-- * AIRBASE.PersianGulf.Ras_Al_Khaimah_Intl
-- * AIRBASE.PersianGulf.Sas_Al_Nakheel
-- * AIRBASE.PersianGulf.Sharjah_Intl
-- * AIRBASE.PersianGulf.Shiraz_Intl
-- * AIRBASE.PersianGulf.Sir_Abu_Nuayr
-- * AIRBASE.PersianGulf.Sirri_Island
-- * AIRBASE.PersianGulf.Tunb_Island_AFB
-- * AIRBASE.PersianGulf.Tunb_Kochak
--
-- @field PersianGulf
AIRBASE.PersianGulf = {
  ["Abu_Dhabi_Intl"] = "Abu Dhabi Intl",
  ["Abu_Musa_Island"] = "Abu Musa Island",
  ["Al_Ain_Intl"] = "Al Ain Intl",
  ["Al_Bateen"] = "Al-Bateen",
  ["Al_Dhafra_AFB"] = "Al Dhafra AFB",
  ["Al_Maktoum_Intl"] = "Al Maktoum Intl",
  ["Al_Minhad_AFB"] = "Al Minhad AFB",
  ["Bandar_Abbas_Intl"] = "Bandar Abbas Intl",
  ["Bandar_Lengeh"] = "Bandar Lengeh",
  ["Bandar_e_Jask"] = "Bandar-e-Jask",
  ["Dubai_Intl"] = "Dubai Intl",
  ["Fujairah_Intl"] = "Fujairah Intl",
  ["Havadarya"] = "Havadarya",
  ["Jiroft"] = "Jiroft",
  ["Kerman"] = "Kerman",
  ["Khasab"] = "Khasab",
  ["Kish_Intl"] = "Kish Intl",
  ["Lar"] = "Lar",
  ["Lavan_Island"] = "Lavan Island",
  ["Liwa_AFB"] = "Liwa AFB",
  ["Qeshm_Island"] = "Qeshm Island",
  ["Quasoura_airport"] = "Quasoura_airport",
  ["Ras_Al_Khaimah_Intl"] = "Ras Al Khaimah Intl",
  ["Sas_Al_Nakheel"] = "Sas Al Nakheel",
  ["Sharjah_Intl"] = "Sharjah Intl",
  ["Shiraz_Intl"] = "Shiraz Intl",
  ["Sir_Abu_Nuayr"] = "Sir Abu Nuayr",
  ["Sirri_Island"] = "Sirri Island",
  ["Tunb_Island_AFB"] = "Tunb Island AFB",
  ["Tunb_Kochak"] = "Tunb Kochak",
}

--- Airbases of The Channel Map:
--
-- * AIRBASE.TheChannel.Abbeville_Drucat
-- * AIRBASE.TheChannel.Biggin_Hill
-- * AIRBASE.TheChannel.Detling
-- * AIRBASE.TheChannel.Dunkirk_Mardyck
-- * AIRBASE.TheChannel.Eastchurch
-- * AIRBASE.TheChannel.Hawkinge
-- * AIRBASE.TheChannel.Headcorn
-- * AIRBASE.TheChannel.High_Halden
-- * AIRBASE.TheChannel.Lympne
-- * AIRBASE.TheChannel.Manston
-- * AIRBASE.TheChannel.Merville_Calonne
-- * AIRBASE.TheChannel.Saint_Omer_Longuenesse
--
-- @field TheChannel
AIRBASE.TheChannel = {
  ["Abbeville_Drucat"] = "Abbeville Drucat",
  ["Biggin_Hill"] = "Biggin Hill",
  ["Detling"] = "Detling",
  ["Dunkirk_Mardyck"] = "Dunkirk Mardyck",
  ["Eastchurch"] = "Eastchurch",
  ["Hawkinge"] = "Hawkinge",
  ["Headcorn"] = "Headcorn",
  ["High_Halden"] = "High Halden",
  ["Lympne"] = "Lympne",
  ["Manston"] = "Manston",
  ["Merville_Calonne"] = "Merville Calonne",
  ["Saint_Omer_Longuenesse"] = "Saint Omer Longuenesse",
}

--- Airbases of the Syria map:
--
-- * AIRBASE.Syria.Abu_al_Duhur
-- * AIRBASE.Syria.Adana_Sakirpasa
-- * AIRBASE.Syria.Akrotiri
-- * AIRBASE.Syria.Al_Dumayr
-- * AIRBASE.Syria.Al_Qusayr
-- * AIRBASE.Syria.Aleppo
-- * AIRBASE.Syria.Amman
-- * AIRBASE.Syria.An_Nasiriyah
-- * AIRBASE.Syria.At_Tanf
-- * AIRBASE.Syria.Bassel_Al_Assad
-- * AIRBASE.Syria.Beirut_Rafic_Hariri
-- * AIRBASE.Syria.Damascus
-- * AIRBASE.Syria.Deir_ez_Zor
-- * AIRBASE.Syria.Ercan
-- * AIRBASE.Syria.Eyn_Shemer
-- * AIRBASE.Syria.Gaziantep
-- * AIRBASE.Syria.Gazipasa
-- * AIRBASE.Syria.Gecitkale
-- * AIRBASE.Syria.H
-- * AIRBASE.Syria.H3
-- * AIRBASE.Syria.H3_Northwest
-- * AIRBASE.Syria.H3_Southwest
-- * AIRBASE.Syria.H4
-- * AIRBASE.Syria.Haifa
-- * AIRBASE.Syria.Hama
-- * AIRBASE.Syria.Hatay
-- * AIRBASE.Syria.Herzliya
-- * AIRBASE.Syria.Incirlik
-- * AIRBASE.Syria.Jirah
-- * AIRBASE.Syria.Khalkhalah
-- * AIRBASE.Syria.Kharab_Ishk
-- * AIRBASE.Syria.King_Abdullah_II
-- * AIRBASE.Syria.King_Hussein_Air_College
-- * AIRBASE.Syria.Kingsfield
-- * AIRBASE.Syria.Kiryat_Shmona
-- * AIRBASE.Syria.Kuweires
-- * AIRBASE.Syria.Lakatamia
-- * AIRBASE.Syria.Larnaca
-- * AIRBASE.Syria.Marj_Ruhayyil
-- * AIRBASE.Syria.Marj_as_Sultan_North
-- * AIRBASE.Syria.Marj_as_Sultan_South
-- * AIRBASE.Syria.Megiddo
-- * AIRBASE.Syria.Mezzeh
-- * AIRBASE.Syria.Minakh
-- * AIRBASE.Syria.Muwaffaq_Salti
-- * AIRBASE.Syria.Naqoura
-- * AIRBASE.Syria.Nicosia
-- * AIRBASE.Syria.Palmyra
-- * AIRBASE.Syria.Paphos
-- * AIRBASE.Syria.Pinarbashi
-- * AIRBASE.Syria.Prince_Hassan
-- * AIRBASE.Syria.Qabr_as_Sitt
-- * AIRBASE.Syria.Ramat_David
-- * AIRBASE.Syria.Rayak
-- * AIRBASE.Syria.Rene_Mouawad
-- * AIRBASE.Syria.Rosh_Pina
-- * AIRBASE.Syria.Ruwayshid
-- * AIRBASE.Syria.Sanliurfa
-- * AIRBASE.Syria.Sayqal
-- * AIRBASE.Syria.Shayrat
-- * AIRBASE.Syria.Tabqa
-- * AIRBASE.Syria.Taftanaz
-- * AIRBASE.Syria.Tal_Siman
-- * AIRBASE.Syria.Tha_lah
-- * AIRBASE.Syria.Tiyas
-- * AIRBASE.Syria.Wujah_Al_Hajar
-- * AIRBASE.Syria.Ben_Gurion 
-- * AIRBASE.Syria.Hatzor
-- * AIRBASE.Syria.Palmashim
-- * AIRBASE.Syria.Tel_Nof
--
--@field Syria
AIRBASE.Syria={
  ["Abu_al_Duhur"] = "Abu al-Duhur",
  ["Adana_Sakirpasa"] = "Adana Sakirpasa",
  ["Akrotiri"] = "Akrotiri",
  ["Al_Dumayr"] = "Al-Dumayr",
  ["Al_Qusayr"] = "Al Qusayr",
  ["Aleppo"] = "Aleppo",
  ["Amman"] = "Amman",
  ["An_Nasiriyah"] = "An Nasiriyah",
  ["At_Tanf"] = "At Tanf",
  ["Bassel_Al_Assad"] = "Bassel Al-Assad",
  ["Beirut_Rafic_Hariri"] = "Beirut-Rafic Hariri",
  ["Damascus"] = "Damascus",
  ["Deir_ez_Zor"] = "Deir ez-Zor",
  ["Ercan"] = "Ercan",
  ["Eyn_Shemer"] = "Eyn Shemer",
  ["Gaziantep"] = "Gaziantep",
  ["Gazipasa"] = "Gazipasa",
  ["Gecitkale"] = "Gecitkale",
  ["H"] = "H",
  ["H3"] = "H3",
  ["H3_Northwest"] = "H3 Northwest",
  ["H3_Southwest"] = "H3 Southwest",
  ["H4"] = "H4",
  ["Haifa"] = "Haifa",
  ["Hama"] = "Hama",
  ["Hatay"] = "Hatay",
  ["Herzliya"] = "Herzliya",
  ["Incirlik"] = "Incirlik",
  ["Jirah"] = "Jirah",
  ["Khalkhalah"] = "Khalkhalah",
  ["Kharab_Ishk"] = "Kharab Ishk",
  ["King_Abdullah_II"] = "King Abdullah II",
  ["King_Hussein_Air_College"] = "King Hussein Air College",
  ["Kingsfield"] = "Kingsfield",
  ["Kiryat_Shmona"] = "Kiryat Shmona",
  ["Kuweires"] = "Kuweires",
  ["Lakatamia"] = "Lakatamia",
  ["Larnaca"] = "Larnaca",
  ["Marj_Ruhayyil"] = "Marj Ruhayyil",
  ["Marj_as_Sultan_North"] = "Marj as Sultan North",
  ["Marj_as_Sultan_South"] = "Marj as Sultan South",
  ["Megiddo"] = "Megiddo",
  ["Mezzeh"] = "Mezzeh",
  ["Minakh"] = "Minakh",
  ["Muwaffaq_Salti"] = "Muwaffaq Salti",
  ["Naqoura"] = "Naqoura",
  ["Nicosia"] = "Nicosia",
  ["Palmyra"] = "Palmyra",
  ["Paphos"] = "Paphos",
  ["Pinarbashi"] = "Pinarbashi",
  ["Prince_Hassan"] = "Prince Hassan",
  ["Qabr_as_Sitt"] = "Qabr as Sitt",
  ["Ramat_David"] = "Ramat David",
  ["Rayak"] = "Rayak",
  ["Rene_Mouawad"] = "Rene Mouawad",
  ["Rosh_Pina"] = "Rosh Pina",
  ["Ruwayshid"] = "Ruwayshid",
  ["Sanliurfa"] = "Sanliurfa",
  ["Sayqal"] = "Sayqal",
  ["Shayrat"] = "Shayrat",
  ["Tabqa"] = "Tabqa",
  ["Taftanaz"] = "Taftanaz",
  ["Tal_Siman"] = "Tal Siman",
  ["Tha_lah"] = "Tha'lah",
  ["Tiyas"] = "Tiyas",
  ["Wujah_Al_Hajar"] = "Wujah Al Hajar",
  ["Ben_Gurion"] = "Ben Gurion",
  ["Hatzor"] = "Hatzor",
  ["Palmashim"] = "Palmashim",
  ["Tel_Nof"] = "Tel Nof",
}

--- Airbases of the Mariana Islands map:
--
-- * AIRBASE.MarianaIslands.Andersen_AFB
-- * AIRBASE.MarianaIslands.Antonio_B_Won_Pat_Intl
-- * AIRBASE.MarianaIslands.North_West_Field
-- * AIRBASE.MarianaIslands.Olf_Orote
-- * AIRBASE.MarianaIslands.Pagan_Airstrip
-- * AIRBASE.MarianaIslands.Rota_Intl
-- * AIRBASE.MarianaIslands.Saipan_Intl
-- * AIRBASE.MarianaIslands.Tinian_Intl
--
-- @field MarianaIslands
AIRBASE.MarianaIslands = {
  ["Andersen_AFB"] = "Andersen AFB",
  ["Antonio_B_Won_Pat_Intl"] = "Antonio B. Won Pat Intl",
  ["North_West_Field"] = "North West Field",
  ["Olf_Orote"] = "Olf Orote",
  ["Pagan_Airstrip"] = "Pagan Airstrip",
  ["Rota_Intl"] = "Rota Intl",
  ["Saipan_Intl"] = "Saipan Intl",
  ["Tinian_Intl"] = "Tinian Intl",
}

--- Airbases of the South Atlantic map:
--
-- * AIRBASE.SouthAtlantic.Almirante_Schroeders
-- * AIRBASE.SouthAtlantic.Comandante_Luis_Piedrabuena
-- * AIRBASE.SouthAtlantic.Cullen
-- * AIRBASE.SouthAtlantic.El_Calafate
-- * AIRBASE.SouthAtlantic.Franco_Bianco
-- * AIRBASE.SouthAtlantic.Gobernador_Gregores
-- * AIRBASE.SouthAtlantic.Goose_Green
-- * AIRBASE.SouthAtlantic.Gull_Point
-- * AIRBASE.SouthAtlantic.Hipico_Flying_Club
-- * AIRBASE.SouthAtlantic.Mount_Pleasant
-- * AIRBASE.SouthAtlantic.O_Higgins
-- * AIRBASE.SouthAtlantic.Pampa_Guanaco
-- * AIRBASE.SouthAtlantic.Port_Stanley
-- * AIRBASE.SouthAtlantic.Porvenir
-- * AIRBASE.SouthAtlantic.Puerto_Natales
-- * AIRBASE.SouthAtlantic.Puerto_Santa_Cruz
-- * AIRBASE.SouthAtlantic.Puerto_Williams
-- * AIRBASE.SouthAtlantic.Punta_Arenas
-- * AIRBASE.SouthAtlantic.Rio_Chico
-- * AIRBASE.SouthAtlantic.Rio_Gallegos
-- * AIRBASE.SouthAtlantic.Rio_Grande
-- * AIRBASE.SouthAtlantic.Rio_Turbio
-- * AIRBASE.SouthAtlantic.San_Carlos_FOB
-- * AIRBASE.SouthAtlantic.San_Julian
-- * AIRBASE.SouthAtlantic.Tolhuin
-- * AIRBASE.SouthAtlantic.Ushuaia
-- * AIRBASE.SouthAtlantic.Ushuaia_Helo_Port
--
--@field SouthAtlantic
AIRBASE.SouthAtlantic={
  ["Almirante_Schroeders"] = "Almirante Schroeders",
  ["Comandante_Luis_Piedrabuena"] = "Comandante Luis Piedrabuena",
  ["Cullen"] = "Cullen",
  ["El_Calafate"] = "El Calafate",
  ["Franco_Bianco"] = "Franco Bianco",
  ["Gobernador_Gregores"] = "Gobernador Gregores",
  ["Goose_Green"] = "Goose Green",
  ["Gull_Point"] = "Gull Point",
  ["Hipico_Flying_Club"] = "Hipico Flying Club",
  ["Mount_Pleasant"] = "Mount Pleasant",
  ["O_Higgins"] = "O'Higgins",
  ["Pampa_Guanaco"] = "Pampa Guanaco",
  ["Port_Stanley"] = "Port Stanley",
  ["Porvenir"] = "Porvenir",
  ["Puerto_Natales"] = "Puerto Natales",
  ["Puerto_Santa_Cruz"] = "Puerto Santa Cruz",
  ["Puerto_Williams"] = "Puerto Williams",
  ["Punta_Arenas"] = "Punta Arenas",
  ["Rio_Chico"] = "Rio Chico",
  ["Rio_Gallegos"] = "Rio Gallegos",
  ["Rio_Grande"] = "Rio Grande",
  ["Rio_Turbio"] = "Rio Turbio",
  ["San_Carlos_FOB"] = "San Carlos FOB",
  ["San_Julian"] = "San Julian",
  ["Tolhuin"] = "Tolhuin",
  ["Ushuaia"] = "Ushuaia",
  ["Ushuaia_Helo_Port"] = "Ushuaia Helo Port",
}

--- Airbases of the Sinai map:
--
-- * AIRBASE.Sinai.Abu_Rudeis
-- * AIRBASE.Sinai.Abu_Suwayr
-- * AIRBASE.Sinai.Al_Bahr_al_Ahmar
-- * AIRBASE.Sinai.Al_Ismailiyah
-- * AIRBASE.Sinai.Al_Khatatbah
-- * AIRBASE.Sinai.Al_Mansurah
-- * AIRBASE.Sinai.Al_Rahmaniyah_Air_Base
-- * AIRBASE.Sinai.As_Salihiyah
-- * AIRBASE.Sinai.AzZaqaziq
-- * AIRBASE.Sinai.Baluza
-- * AIRBASE.Sinai.Ben_Gurion
-- * AIRBASE.Sinai.Beni_Suef
-- * AIRBASE.Sinai.Bilbeis_Air_Base
-- * AIRBASE.Sinai.Bir_Hasanah
-- * AIRBASE.Sinai.Birma_Air_Base
-- * AIRBASE.Sinai.Borj_El_Arab_International_Airport
-- * AIRBASE.Sinai.Cairo_International_Airport
-- * AIRBASE.Sinai.Cairo_West
-- * AIRBASE.Sinai.Difarsuwar_Airfield
-- * AIRBASE.Sinai.El_Arish
-- * AIRBASE.Sinai.El_Gora
-- * AIRBASE.Sinai.El_Minya
-- * AIRBASE.Sinai.Fayed
-- * AIRBASE.Sinai.Gebel_El_Basur_Air_Base
-- * AIRBASE.Sinai.Hatzerim
-- * AIRBASE.Sinai.Hatzor
-- * AIRBASE.Sinai.Hurghada_International_Airport
-- * AIRBASE.Sinai.Inshas_Airbase
-- * AIRBASE.Sinai.Jiyanklis_Air_Base
-- * AIRBASE.Sinai.Kedem
-- * AIRBASE.Sinai.Kibrit_Air_Base
-- * AIRBASE.Sinai.Kom_Awshim
-- * AIRBASE.Sinai.Melez
-- * AIRBASE.Sinai.Nevatim
-- * AIRBASE.Sinai.Ovda
-- * AIRBASE.Sinai.Palmachim
-- * AIRBASE.Sinai.Quwaysina
-- * AIRBASE.Sinai.Ramon_Airbase
-- * AIRBASE.Sinai.Ramon_International_Airport
-- * AIRBASE.Sinai.Sde_Dov
-- * AIRBASE.Sinai.Sharm_El_Sheikh_International_Airport
-- * AIRBASE.Sinai.St_Catherine
-- * AIRBASE.Sinai.Tel_Nof
-- * AIRBASE.Sinai.Wadi_Abu_Rish
-- * AIRBASE.Sinai.Wadi_al_Jandali
--
-- @field Sinai
AIRBASE.Sinai = {
  ["Abu_Rudeis"] = "Abu Rudeis",
  ["Abu_Suwayr"] = "Abu Suwayr",
  ["Al_Bahr_al_Ahmar"] = "Al Bahr al Ahmar",
  ["Al_Ismailiyah"] = "Al Ismailiyah",
  ["Al_Khatatbah"] = "Al Khatatbah",
  ["Al_Mansurah"] = "Al Mansurah",
  ["Al_Rahmaniyah_Air_Base"] = "Al Rahmaniyah Air Base",
  ["As_Salihiyah"] = "As Salihiyah",
  ["AzZaqaziq"] = "AzZaqaziq",
  ["Baluza"] = "Baluza",
  ["Ben_Gurion"] = "Ben-Gurion",
  ["Beni_Suef"] = "Beni Suef",
  ["Bilbeis_Air_Base"] = "Bilbeis Air Base",
  ["Bir_Hasanah"] = "Bir Hasanah",
  ["Birma_Air_Base"] = "Birma Air Base",
  ["Borj_El_Arab_International_Airport"] = "Borj El Arab International Airport",
  ["Cairo_International_Airport"] = "Cairo International Airport",
  ["Cairo_West"] = "Cairo West",
  ["Difarsuwar_Airfield"] = "Difarsuwar Airfield",
  ["El_Arish"] = "El Arish",
  ["El_Gora"] = "El Gora",
  ["El_Minya"] = "El Minya",
  ["Fayed"] = "Fayed",
  ["Gebel_El_Basur_Air_Base"] = "Gebel El Basur Air Base",
  ["Hatzerim"] = "Hatzerim",
  ["Hatzor"] = "Hatzor",
  ["Hurghada_International_Airport"] = "Hurghada International Airport",
  ["Inshas_Airbase"] = "Inshas Airbase",
  ["Jiyanklis_Air_Base"] = "Jiyanklis Air Base",
  ["Kedem"] = "Kedem",
  ["Kibrit_Air_Base"] = "Kibrit Air Base",
  ["Kom_Awshim"] = "Kom Awshim",
  ["Melez"] = "Melez",
  ["Nevatim"] = "Nevatim",
  ["Ovda"] = "Ovda",
  ["Palmachim"] = "Palmachim",
  ["Quwaysina"] = "Quwaysina",
  ["Ramon_Airbase"] = "Ramon Airbase",
  ["Ramon_International_Airport"] = "Ramon International Airport",
  ["Sde_Dov"] = "Sde Dov",
  ["Sharm_El_Sheikh_International_Airport"] = "Sharm El Sheikh International Airport",
  ["St_Catherine"] = "St Catherine",
  ["Tel_Nof"] = "Tel Nof",
  ["Wadi_Abu_Rish"] = "Wadi Abu Rish",
  ["Wadi_al_Jandali"] = "Wadi al Jandali",
}

--- Airbases of the Kola map
-- 
-- * AIRBASE.Kola.Banak
-- * AIRBASE.Kola.Bodo
-- * AIRBASE.Kola.Ivalo
-- * AIRBASE.Kola.Jokkmokk
-- * AIRBASE.Kola.Kalixfors
-- * AIRBASE.Kola.Kallax
-- * AIRBASE.Kola.Kemi_Tornio
-- * AIRBASE.Kola.Kirkenes
-- * AIRBASE.Kola.Kiruna
-- * AIRBASE.Kola.Kuusamo
-- * AIRBASE.Kola.Monchegorsk
-- * AIRBASE.Kola.Murmansk_International
-- * AIRBASE.Kola.Olenya
-- * AIRBASE.Kola.Rovaniemi
-- * AIRBASE.Kola.Severomorsk_1
-- * AIRBASE.Kola.Severomorsk_3
-- * AIRBASE.Kola.Vidsel
-- * AIRBASE.Kola.Vuojarvi
-- * AIRBASE.Kola.Andoya
-- * AIRBASE.Kola.Alakourtti
-- * AIRBASE.Kola.Kittila
-- * AIRBASE.Kola.Bardufoss
--
-- @field Kola
AIRBASE.Kola = {
  ["Banak"] = "Banak",
  ["Bodo"] = "Bodo",
  ["Ivalo"] = "Ivalo",
  ["Jokkmokk"] = "Jokkmokk",
  ["Kalixfors"] = "Kalixfors",
  ["Kallax"] = "Kallax",
  ["Kemi_Tornio"] = "Kemi Tornio",
  ["Kirkenes"] = "Kirkenes",
  ["Kiruna"] = "Kiruna",
  ["Kuusamo"] = "Kuusamo",
  ["Monchegorsk"] = "Monchegorsk",
  ["Murmansk_International"] = "Murmansk International",
  ["Olenya"] = "Olenya",
  ["Rovaniemi"] = "Rovaniemi",
  ["Severomorsk_1"] = "Severomorsk-1",
  ["Severomorsk_3"] = "Severomorsk-3",
  ["Vidsel"] = "Vidsel",
  ["Vuojarvi"] = "Vuojarvi",
  ["Andoya"] = "Andoya",
  ["Alakourtti"] = "Alakourtti",
  ["Kittila"] = "Kittila",
  ["Bardufoss"] = "Bardufoss",
}

--- Airbases of the Afghanistan map
-- 
-- * AIRBASE.Afghanistan.Bost
-- * AIRBASE.Afghanistan.Camp_Bastion
-- * AIRBASE.Afghanistan.Camp_Bastion_Heliport
-- * AIRBASE.Afghanistan.Chaghcharan
-- * AIRBASE.Afghanistan.Dwyer
-- * AIRBASE.Afghanistan.Farah
-- * AIRBASE.Afghanistan.Herat
-- * AIRBASE.Afghanistan.Kandahar
-- * AIRBASE.Afghanistan.Kandahar_Heliport
-- * AIRBASE.Afghanistan.Maymana_Zahiraddin_Faryabi
-- * AIRBASE.Afghanistan.Nimroz
-- * AIRBASE.Afghanistan.Qala_i_Naw
-- * AIRBASE.Afghanistan.Shindand
-- * AIRBASE.Afghanistan.Shindand_Heliport
-- * AIRBASE.Afghanistan.Tarinkot
-- 
-- @field Afghanistan
AIRBASE.Afghanistan = {
  ["Bost"] = "Bost",
  ["Camp_Bastion"] = "Camp Bastion",
  ["Camp_Bastion_Heliport"] = "Camp Bastion Heliport",
  ["Chaghcharan"] = "Chaghcharan",
  ["Dwyer"] = "Dwyer",
  ["Farah"] = "Farah",
  ["Herat"] = "Herat",
  ["Kandahar"] = "Kandahar",
  ["Kandahar_Heliport"] = "Kandahar Heliport",
  ["Maymana_Zahiraddin_Faryabi"] = "Maymana Zahiraddin Faryabi",
  ["Nimroz"] = "Nimroz",
  ["Qala_i_Naw"] = "Qala i Naw",
  ["Shindand"] = "Shindand",
  ["Shindand_Heliport"] = "Shindand Heliport",
  ["Tarinkot"] = "Tarinkot",
}

--- Airbases of the Iraq map
--
-- * AIRBASE.Iraq.Baghdad_International_Airport
-- * AIRBASE.Iraq.Sulaimaniyah_International_Airport
-- * AIRBASE.Iraq.Al_Sahra_Airport
-- * AIRBASE.Iraq.Erbil_International_Airpor
-- * AIRBASE.Iraq.Al_Taji_Airport
-- * AIRBASE.Iraq.Al_Asad_Airbase
-- * AIRBASE.Iraq.Al_Salam_Airbase
-- * AIRBASE.Iraq.Balad_Airbase
-- * AIRBASE.Iraq.Kirkuk_International_Airport
-- * AIRBASE.Iraq.Bashur_Airport
-- * AIRBASE.Iraq.Al_Taquddum_Airport
-- * AIRBASE.Iraq.Qayyarah_Airfield_West
-- * AIRBASE.Iraq.K1_Base
--
-- @field Iraq
AIRBASE.Iraq = {
  ["Baghdad_International_Airport"] = "Baghdad International Airport",
  ["Sulaimaniyah_International_Airport"] = "Sulaimaniyah International Airport",
  ["Al_Sahra_Airport"] = "Al-Sahra Airport",
  ["Erbil_International_Airport"] = "Erbil International Airport",
  ["Al_Taji_Airport"] = "Al-Taji Airport",
  ["Al_Asad_Airbase"] = "Al-Asad Airbase",
  ["Al_Salam_Airbase"] = "Al-Salam Airbase",
  ["Balad_Airbase"] = "Balad Airbase",
  ["Kirkuk_International_Airport"] = "Kirkuk International Airport",
  ["Bashur_Airport"] = "Bashur Airport",
  ["Al_Taquddum_Airport"] = "Al-Taquddum Airport",
  ["Qayyarah_Airfield_West"] = "Qayyarah Airfield West",
  ["K1_Base"] = "K1 Base",
}

--- AIRBASE.ParkingSpot ".Coordinate, ".TerminalID", ".TerminalType", ".TOAC", ".Free", ".TerminalID0", ".DistToRwy".
-- @type AIRBASE.ParkingSpot
-- @field Core.Point#COORDINATE Coordinate Coordinate of the parking spot.
-- @field #number TerminalID Terminal ID of the spot. Generally, this is not the same number as displayed in the mission editor.
-- @field #AIRBASE.TerminalType TerminalType Type of the spot, i.e. for which type of aircraft it can be used.
-- @field #boolean TOAC Takeoff or landing aircarft. I.e. this stop is occupied currently by an aircraft until it took of or until it landed.
-- @field #boolean Free This spot is currently free, i.e. there is no alive aircraft on it at the present moment.
-- @field #number TerminalID0 Unknown what this means. If you know, please tell us!
-- @field #number DistToRwy Distance to runway in meters. Currently bugged and giving the same number as the TerminalID.
-- @field #string AirbaseName Name of the airbase.
-- @field #number MarkerID Numerical ID of marker placed at parking spot.
-- @field Wrapper.Marker#MARKER Marker The marker on the F10 map.
-- @field #string ClientSpot If `true`, this is a parking spot of a client aircraft.
-- @field #string ClientName Client unit name of this spot.
-- @field #string Status Status of spot e.g. `AIRBASE.SpotStatus.FREE`.
-- @field #string OccupiedBy Name of the aircraft occupying the spot or "unknown". Can be *nil* if spot is not occupied.
-- @field #string ReservedBy Name of the aircraft for which this spot is reserved. Can be *nil* if spot is not reserved.

--- Terminal Types of parking spots. See also https://wiki.hoggitworld.com/view/DCS_func_getParking
--
-- Supported types are:
--
-- * AIRBASE.TerminalType.Runway = 16: Valid spawn points on runway.
-- * AIRBASE.TerminalType.HelicopterOnly = 40: Special spots for Helicopers.
-- * AIRBASE.TerminalType.Shelter = 68: Hardened Air Shelter. Currently only on Caucaus map.
-- * AIRBASE.TerminalType.OpenMed = 72: Open/Shelter air airplane only.
-- * AIRBASE.TerminalType.OpenBig = 104: Open air spawn points. Generally larger but does not guarantee large aircraft are capable of spawning there.
-- * AIRBASE.TerminalType.OpenMedOrBig = 176: Combines OpenMed and OpenBig spots.
-- * AIRBASE.TerminalType.HelicopterUsable = 216: Combines HelicopterOnly, OpenMed and OpenBig.
-- * AIRBASE.TerminalType.FighterAircraft = 244: Combines Shelter. OpenMed and OpenBig spots. So effectively all spots usable by fixed wing aircraft.
--
-- @type AIRBASE.TerminalType
-- @field #number Runway 16: Valid spawn points on runway.
-- @field #number HelicopterOnly 40: Special spots for Helicopers.
-- @field #number Shelter 68: Hardened Air Shelter. Currently only on Caucaus map.
-- @field #number OpenMed 72: Open/Shelter air airplane only.
-- @field #number OpenBig 104: Open air spawn points. Generally larger but does not guarantee large aircraft are capable of spawning there.
-- @field #number OpenMedOrBig 176: Combines OpenMed and OpenBig spots.
-- @field #number HelicopterUsable 216: Combines HelicopterOnly, OpenMed and OpenBig.
-- @field #number FighterAircraft 244: Combines Shelter. OpenMed and OpenBig spots. So effectively all spots usable by fixed wing aircraft.
-- @field #number SmallSizeFigher 100: Tight spots for smaller type fixed wing aircraft, like the F-16. Example of these spots: 04, 05, 06 on Muwaffaq_Salti. A Viper sized plane can spawn here, but an A-10 or Strike Eagle can't
AIRBASE.TerminalType = {
  Runway=16,
  HelicopterOnly=40,
  Shelter=68,
  OpenMed=72,
  SmallSizeFighter=100,
  OpenBig=104,
  OpenMedOrBig=176,
  HelicopterUsable=216,
  FighterAircraft=244,
}

--- Status of a parking spot.
-- @type AIRBASE.SpotStatus
-- @field #string FREE Spot is free.
-- @field #string OCCUPIED Spot is occupied.
-- @field #string RESERVED Spot is reserved.
AIRBASE.SpotStatus = {
  FREE="Free",
  OCCUPIED="Occupied",
  RESERVED="Reserved",
}

--- Runway data.
-- @type AIRBASE.Runway
-- @field #string name Runway name.
-- @field #string idx Runway ID: heading 070° ==> idx="07".
-- @field #number heading True heading of the runway in degrees.
-- @field #number magheading Magnetic heading of the runway in degrees. This is what is marked on the runway.
-- @field #number length Length of runway in meters.
-- @field #number width Width of runway in meters.
-- @field Core.Zone#ZONE_POLYGON zone Runway zone.
-- @field Core.Point#COORDINATE center Center of the runway.
-- @field Core.Point#COORDINATE position Position of runway start.
-- @field Core.Point#COORDINATE endpoint End point of runway.
-- @field #boolean isLeft If `true`, this is the left of two parallel runways. If `false`, this is the right of two runways. If `nil`, no parallel runway exists.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Registration
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new AIRBASE from DCSAirbase.
-- @param #AIRBASE self
-- @param #string AirbaseName The name of the airbase.
-- @return #AIRBASE self
function AIRBASE:Register(AirbaseName)

  -- Inherit everything from positionable.
  local self=BASE:Inherit(self, POSITIONABLE:New(AirbaseName)) --#AIRBASE

  -- Set airbase name.
  self.AirbaseName=AirbaseName

  -- Set airbase ID.
  self.AirbaseID=self:GetID(true)

  -- Get descriptors.
  self.descriptors=self:GetDesc()

  -- Debug info.
  --self:I({airbase=AirbaseName, descriptors=self.descriptors})
  
  -- Category.
  self.category=self.descriptors and self.descriptors.category or Airbase.Category.AIRDROME

  -- H2 is bugged
  --if self.AirbaseName == "H4" and self.descriptors == nil then
    --self:E("***** H4 on Syria map is currently bugged!")
    --return nil
  --end

  -- Set category.
if self.category==Airbase.Category.AIRDROME then
  self.isAirdrome=true
elseif self.category==Airbase.Category.HELIPAD or self.descriptors.typeName=="FARP_SINGLE_01" then
  self.isHelipad=true
elseif self.category==Airbase.Category.SHIP then
  self.isShip=true
  -- DCS bug: Oil rigs and gas platforms have category=2 (ship). Also they cannot be retrieved by coalition.getStaticObjects()
  if self.descriptors.typeName=="Oil rig" or self.descriptors.typeName=="Ga" then
    self.isHelipad=true
    self.isShip=false
    self.category=Airbase.Category.HELIPAD
    _DATABASE:AddStatic(AirbaseName)
  end
else
  self:E("ERROR: Unknown airbase category!")
end

  -- Init Runways.
  self:_InitRunways()

  -- Set the active runways based on wind direction.
  if self.isAirdrome then
    self:SetActiveRunway()
  end

  -- Init parking spots.
  self:_InitParkingSpots()

  -- Get 2D position vector.
  local vec2=self:GetVec2()

  -- Init coordinate.
  self:GetCoordinate()

  -- Storage.
  self.storage=_DATABASE:AddStorage(AirbaseName)

  if vec2 then
    if self.isShip then
      local unit=UNIT:FindByName(AirbaseName)
      if unit then
        self.AirbaseZone=ZONE_UNIT:New(AirbaseName, unit, 2500)
      end
    else
      self.AirbaseZone=ZONE_RADIUS:New(AirbaseName, vec2, 2500)
    end
  else
    self:E(string.format("ERROR: Cound not get position Vec2 of airbase %s", AirbaseName))
  end

  -- Debug info.
  self:T2(string.format("Registered airbase %s", tostring(self.AirbaseName)))

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Reference methods
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Finds a AIRBASE from the _DATABASE using a DCSAirbase object.
-- @param #AIRBASE self
-- @param DCS#Airbase DCSAirbase An existing DCS Airbase object reference.
-- @return Wrapper.Airbase#AIRBASE self
function AIRBASE:Find( DCSAirbase )

  local AirbaseName = DCSAirbase:getName()
  local AirbaseFound = _DATABASE:FindAirbase( AirbaseName )
  return AirbaseFound
end

--- Find a AIRBASE in the _DATABASE using the name of an existing DCS Airbase.
-- @param #AIRBASE self
-- @param #string AirbaseName The Airbase Name.
-- @return #AIRBASE self
function AIRBASE:FindByName( AirbaseName )

  local AirbaseFound = _DATABASE:FindAirbase( AirbaseName )
  return AirbaseFound
end

--- Find a AIRBASE in the _DATABASE by its ID.
-- @param #AIRBASE self
-- @param #number id Airbase ID.
-- @return #AIRBASE self
function AIRBASE:FindByID(id)

  for name,_airbase in pairs(_DATABASE.AIRBASES) do
    local airbase=_airbase --#AIRBASE

    local aid=tonumber(airbase:GetID(true))

    if aid==id then
      return airbase
    end

  end

  return nil
end

--- Get the DCS object of an airbase
-- @param #AIRBASE self
-- @return DCS#Airbase DCS airbase object.
function AIRBASE:GetDCSObject()

  -- Get the DCS object.
  local DCSAirbase = Airbase.getByName(self.AirbaseName)

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

--- Get the DCS warehouse.
-- @param #AIRBASE self
-- @return DCS#Warehouse The DCS warehouse object.
function AIRBASE:GetWarehouse()
  local warehouse=nil --DCS#Warehouse
  local airbase=self:GetDCSObject()
  if airbase and Airbase.getWarehouse then
    warehouse=airbase:getWarehouse()
  end
  return warehouse
end

--- Get the warehouse storage of this airbase. The returned `STORAGE` object is the wrapper of the DCS warehouse.
-- This allows you to add and remove items such as aircraft, liquids, weapons and other equipment.
-- @param #AIRBASE self
-- @return Wrapper.Storage#STORAGE The storage.
function AIRBASE:GetStorage()
  return self.storage
end

--- Enables or disables automatic capturing of the airbase.
-- @param #AIRBASE self
-- @param #boolean Switch If `true`, enable auto capturing. If `false`, disable it.
-- @return #AIRBASE self
function AIRBASE:SetAutoCapture(Switch)

  local airbase=self:GetDCSObject()

  if airbase then
    airbase:autoCapture(Switch)
  end

  return self
end

--- Enables automatic capturing of the airbase.
-- @param #AIRBASE self
-- @return #AIRBASE self
function AIRBASE:SetAutoCaptureON()
  self:SetAutoCapture(true)
  return self
end

--- Disables automatic capturing of the airbase.
-- @param #AIRBASE self
-- @return #AIRBASE self
function AIRBASE:SetAutoCaptureOFF()
  self:SetAutoCapture(false)
  return self
end

--- Returns whether auto capturing of the airbase is on or off.
-- @param #AIRBASE self
-- @return #boolean Returns `true` if auto capturing is on, `false` if off and `nil` if the airbase object cannot be retrieved.
function AIRBASE:IsAutoCapture()

  local airbase=self:GetDCSObject()

  local auto=nil
  if airbase then
    auto=airbase:autoCaptureIsOn()
  end

  return auto
end

--- Sets the coalition of the airbase.
-- @param #AIRBASE self
-- @param #number Coal Coalition that the airbase should have (0=Neutral, 1=Red, 2=Blue).
-- @return #AIRBASE self
function AIRBASE:SetCoalition(Coal)

  local airbase=self:GetDCSObject()

  if airbase then
    airbase:setCoalition(Coal)
  end

  return self
end

--- Get all airbases of the current map. This includes ships and FARPS.
-- @param DCS#Coalition coalition (Optional) Return only airbases belonging to the specified coalition. By default, all airbases of the map are returned.
-- @param #number category (Optional) Return only airbases of a certain category, e.g. Airbase.Category.FARP
-- @return #table Table containing all airbase objects of the current map.
function AIRBASE.GetAllAirbases(coalition, category)

  local airbases={}
  for _,_airbase in pairs(_DATABASE.AIRBASES) do
    local airbase=_airbase --#AIRBASE
    if coalition==nil or airbase:GetCoalition()==coalition then
      if category==nil or category==airbase:GetAirbaseCategory() then
        table.insert(airbases, airbase)
      end
    end
  end

  return airbases
end

--- Get all airbase names of the current map. This includes ships and FARPS.
-- @param DCS#Coalition coalition (Optional) Return only airbases belonging to the specified coalition. By default, all airbases of the map are returned.
-- @param #number category (Optional) Return only airbases of a certain category, e.g. `Airbase.Category.HELIPAD`.
-- @return #table Table containing all airbase names of the current map.
function AIRBASE.GetAllAirbaseNames(coalition, category)

  local airbases={}
  for airbasename,_airbase in pairs(_DATABASE.AIRBASES) do
    local airbase=_airbase --#AIRBASE
    if coalition==nil or airbase:GetCoalition()==coalition then
      if category==nil or category==airbase:GetAirbaseCategory() then
        table.insert(airbases, airbasename)
      end
    end
  end

  return airbases
end

--- Get ID of the airbase.
-- @param #AIRBASE self
-- @param #boolean unique (Optional) If true, ships will get a negative sign as the unit ID might be the same as an airbase ID. Default off!
-- @return #number The airbase ID.
function AIRBASE:GetID(unique)

  if self.AirbaseID then

    return unique and self.AirbaseID or math.abs(self.AirbaseID)

  else

   for DCSAirbaseId, DCSAirbase in ipairs(world.getAirbases()) do

      -- Get the airbase name.
      local AirbaseName = DCSAirbase:getName()

      -- This gives the incorrect value to be inserted into the airdromeID for DCS 2.5.6!
      local airbaseID=tonumber(DCSAirbase:getID())

      local airbaseCategory=self:GetAirbaseCategory()

      if AirbaseName==self.AirbaseName then
        if airbaseCategory==Airbase.Category.SHIP or airbaseCategory==Airbase.Category.HELIPAD then
          -- Ships get a negative sign as their unit number might be the same as the ID of another airbase.
          return unique and -airbaseID or airbaseID
        else
          return airbaseID
        end
      end

    end

  end

  return nil
end

--- Set parking spot whitelist. Only these spots will be considered for spawning.
-- Black listed spots overrule white listed spots.
-- **NOTE** that terminal IDs are not necessarily the same as those displayed in the mission editor!
-- @param #AIRBASE self
-- @param #table TerminalIdWhitelist Table of white listed terminal IDs.
-- @return #AIRBASE self
-- @usage AIRBASE:FindByName("Batumi"):SetParkingSpotWhitelist({2, 3, 4}) --Only allow terminal IDs 2, 3, 4
function AIRBASE:SetParkingSpotWhitelist(TerminalIdWhitelist)

  if TerminalIdWhitelist==nil then
    self.parkingWhitelist={}
    return self
  end

  -- Ensure we got a table.
  if type(TerminalIdWhitelist)~="table" then
    TerminalIdWhitelist={TerminalIdWhitelist}
  end

  self.parkingWhitelist=TerminalIdWhitelist

  return self
end

--- Set parking spot blacklist. These parking spots will *not* be used for spawning.
-- Black listed spots overrule white listed spots.
-- **NOTE** that terminal IDs are not necessarily the same as those displayed in the mission editor!
-- @param #AIRBASE self
-- @param #table TerminalIdBlacklist Table of black listed terminal IDs.
-- @return #AIRBASE self
-- @usage AIRBASE:FindByName("Batumi"):SetParkingSpotBlacklist({2, 3, 4}) --Forbit terminal IDs 2, 3, 4
function AIRBASE:SetParkingSpotBlacklist(TerminalIdBlacklist)

  if TerminalIdBlacklist==nil then
    self.parkingBlacklist={}
    return self
  end

  -- Ensure we got a table.
  if type(TerminalIdBlacklist)~="table" then
    TerminalIdBlacklist={TerminalIdBlacklist}
  end

  self.parkingBlacklist=TerminalIdBlacklist

  return self
end

--- Sets the ATC belonging to an airbase object to be silent and unresponsive. This is useful for disabling the award winning ATC behavior in DCS.
-- Note that this DOES NOT remove the airbase from the list. It just makes it unresponsive and silent to any radio calls to it.
-- @param #AIRBASE self
-- @param #boolean Silent If `true`, enable silent mode. If `false` or `nil`, disable silent mode.
-- @return #AIRBASE self
function AIRBASE:SetRadioSilentMode(Silent)

  -- Get DCS airbase object.
  local airbase=self:GetDCSObject()

  -- Set mode.
  if airbase then
    airbase:setRadioSilentMode(Silent)
  end

  return self
end

--- Check whether or not the airbase has been silenced.
-- @param #AIRBASE self
-- @return #boolean If `true`, silent mode is enabled.
function AIRBASE:GetRadioSilentMode()

  -- Is silent?
  local silent=nil

  -- Get DCS airbase object.
  local airbase=self:GetDCSObject()

  -- Set mode.
  if airbase then
    silent=airbase:getRadioSilentMode()
  end

  return silent
end

--- Get category of airbase.
-- @param #AIRBASE self
-- @return #number Category of airbase from GetDesc().category.
function AIRBASE:GetAirbaseCategory()
  return self.category
end

--- Check if airbase is an airdrome.
-- @param #AIRBASE self
-- @return #boolean If true, airbase is an airdrome.
function AIRBASE:IsAirdrome()
  return self.isAirdrome
end

--- Check if airbase is a helipad.
-- @param #AIRBASE self
-- @return #boolean If true, airbase is a helipad.
function AIRBASE:IsHelipad()
  return self.isHelipad
end

--- Check if airbase is a ship.
-- @param #AIRBASE self
-- @return #boolean If true, airbase is a ship.
function AIRBASE:IsShip()
  return self.isShip
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Parking
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Returns a table of parking data for a given airbase. If the optional parameter *available* is true only available parking will be returned, otherwise all parking at the base is returned. Term types have the following enumerated values:
--
-- * 16 : Valid spawn points on runway
-- * 40 : Helicopter only spawn
-- * 68 : Hardened Air Shelter
-- * 72 : Open/Shelter air airplane only
-- * 104: Open air spawn
--
-- Note that only Caucuses will return 68 as it is the only map currently with hardened air shelters.
-- 104 are also generally larger, but does not guarantee a large aircraft like the B-52 or a C-130 are capable of spawning there.
--
-- Table entries:
--
-- * Term_index is the id for the parking
-- * vTerminal pos is its vec3 position in the world
-- * fDistToRW is the distance to the take-off position for the active runway from the parking.
--
-- @param #AIRBASE self
-- @param #boolean available If true, only available parking spots will be returned.
-- @return #table Table with parking data. See https://wiki.hoggitworld.com/view/DCS_func_getParking
function AIRBASE:GetParkingData(available)
  self:F2(available)

  -- Get DCS airbase object.
  local DCSAirbase=self:GetDCSObject()

  -- Get parking data.
  local parkingdata=nil
  if DCSAirbase then
    parkingdata=DCSAirbase:getParking(available)
  end

  self:T2({parkingdata=parkingdata})
  return parkingdata
end

--- Get number of parking spots at an airbase. Optionally, a specific terminal type can be requested.
-- @param #AIRBASE self
-- @param #AIRBASE.TerminalType termtype Terminal type of which the number of spots is counted. Default all spots but spawn points on runway.
-- @return #number Number of parking spots at this airbase.
function AIRBASE:GetParkingSpotsNumber(termtype)

  -- Get free parking spots data.
  local parkingdata=self:GetParkingData(false)

  local nspots=0
  for _,parkingspot in pairs(parkingdata) do
    if AIRBASE._CheckTerminalType(parkingspot.Term_Type, termtype) then
      nspots=nspots+1
    end
  end

  return nspots
end

--- Get number of free parking spots at an airbase.
-- @param #AIRBASE self
-- @param #AIRBASE.TerminalType termtype Terminal type.
-- @param #boolean allowTOAC If true, spots are considered free even though TO_AC is true. Default is off which is saver to avoid spawning aircraft on top of each other. Option might be enabled for FARPS and ships.
-- @return #number Number of free parking spots at this airbase.
function AIRBASE:GetFreeParkingSpotsNumber(termtype, allowTOAC)

  -- Get free parking spots data.
  local parkingdata=self:GetParkingData(true)

  local nfree=0
  for _,parkingspot in pairs(parkingdata) do
    -- Spots on runway are not counted unless explicitly requested.
    if AIRBASE._CheckTerminalType(parkingspot.Term_Type, termtype) then
      if (allowTOAC and allowTOAC==true) or parkingspot.TO_AC==false then
        nfree=nfree+1
      end
    end
  end

  return nfree
end

--- Get the coordinates of free parking spots at an airbase.
-- @param #AIRBASE self
-- @param #AIRBASE.TerminalType termtype Terminal type.
-- @param #boolean allowTOAC If true, spots are considered free even though TO_AC is true. Default is off which is saver to avoid spawning aircraft on top of each other. Option might be enabled for FARPS and ships.
-- @return #table Table of coordinates of the free parking spots.
function AIRBASE:GetFreeParkingSpotsCoordinates(termtype, allowTOAC)

  -- Get free parking spots data.
  local parkingdata=self:GetParkingData(true)

  -- Put coordinates of free spots into table.
  local spots={}
  for _,parkingspot in pairs(parkingdata) do
    -- Coordinates on runway are not returned unless explicitly requested.
    if AIRBASE._CheckTerminalType(parkingspot.Term_Type, termtype) then
      if (allowTOAC and allowTOAC==true) or parkingspot.TO_AC==false then
        table.insert(spots, COORDINATE:NewFromVec3(parkingspot.vTerminalPos))
      end
    end
  end

  return spots
end

--- Get the coordinates of all parking spots at an airbase. Optionally only those of a specific terminal type. Spots on runways are excluded if not explicitly requested by terminal type.
-- @param #AIRBASE self
-- @param #AIRBASE.TerminalType termtype (Optional) Terminal type. Default all.
-- @return #table Table of coordinates of parking spots.
function AIRBASE:GetParkingSpotsCoordinates(termtype)

  -- Get all parking spots data.
  local parkingdata=self:GetParkingData(false)

  -- Put coordinates of free spots into table.
  local spots={}
  for _,parkingspot in ipairs(parkingdata) do

    -- Coordinates on runway are not returned unless explicitly requested.
    if AIRBASE._CheckTerminalType(parkingspot.Term_Type, termtype) then

      -- Get coordinate from Vec3 terminal position.
      local _coord=COORDINATE:NewFromVec3(parkingspot.vTerminalPos)

      -- Add to table.
      table.insert(spots, _coord)
    end

  end

  return spots
end

--- Get a table containing the coordinates, terminal index and terminal type of free parking spots at an airbase.
-- @param #AIRBASE self
-- @return#AIRBASE self
function AIRBASE:_InitParkingSpots()

  -- Get parking data of all spots (free or occupied)
  local parkingdata=self:GetParkingData(false)

  -- Init table.
  self.parking={}
  self.parkingByID={}

  self.NparkingTotal=0
  self.NparkingTerminal={}
  for _,terminalType in pairs(AIRBASE.TerminalType) do
    self.NparkingTerminal[terminalType]=0
  end

  -- Get client coordinates.
  local function isClient(coord)
    local clients=_DATABASE.CLIENTS
    for clientname, _client in pairs(clients) do
      local client=_client --Wrapper.Client#CLIENT
      if client and client.SpawnCoord then
        local dist=client.SpawnCoord:Get2DDistance(coord)
        if dist<2 then
          return true, clientname
        end
      end
    end
    return false, nil
  end

  -- Put coordinates of parking spots into table.
  for _,spot in pairs(parkingdata) do

    -- New parking spot.
    local park={} --#AIRBASE.ParkingSpot
    park.Vec3=spot.vTerminalPos
    park.Coordinate=COORDINATE:NewFromVec3(spot.vTerminalPos)
    park.DistToRwy=spot.fDistToRW
    park.Free=nil
    park.TerminalID=spot.Term_Index
    park.TerminalID0=spot.Term_Index_0
    park.TerminalType=spot.Term_Type
    park.TOAC=spot.TO_AC
    park.ClientSpot, park.ClientName=isClient(park.Coordinate)
    park.AirbaseName=self.AirbaseName

    self.NparkingTotal=self.NparkingTotal+1

    for _,terminalType in pairs(AIRBASE.TerminalType) do
      if self._CheckTerminalType(terminalType, park.TerminalType) then
        self.NparkingTerminal[terminalType]=self.NparkingTerminal[terminalType]+1
      end
    end

    self.parkingByID[park.TerminalID]=park
    table.insert(self.parking, park)
  end

  return self
end

--- Get a table containing the coordinates, terminal index and terminal type of free parking spots at an airbase.
-- @param #AIRBASE self
-- @param #number TerminalID Terminal ID.
-- @return #AIRBASE.ParkingSpot Parking spot.
function AIRBASE:_GetParkingSpotByID(TerminalID)
  return self.parkingByID[TerminalID]
end

--- Get a table containing the coordinates, terminal index and terminal type of free parking spots at an airbase.
-- @param #AIRBASE self
-- @param #AIRBASE.TerminalType termtype Terminal type.
-- @return #table Table free parking spots. Table has the elements ".Coordinate, ".TerminalID", ".TerminalType", ".TOAC", ".Free", ".TerminalID0", ".DistToRwy".
function AIRBASE:GetParkingSpotsTable(termtype)

  -- Get parking data of all spots (free or occupied)
  local parkingdata=self:GetParkingData(false)

  -- Get parking data of all free spots.
  local parkingfree=self:GetParkingData(true)

  -- Function to ckeck if any parking spot is free.
  local function _isfree(_tocheck)
    for _,_spot in pairs(parkingfree) do
      if _spot.Term_Index==_tocheck.Term_Index then
        return true
      end
    end
    return false
  end

  -- Put coordinates of parking spots into table.
  local spots={}
  for _,_spot in pairs(parkingdata) do

    if AIRBASE._CheckTerminalType(_spot.Term_Type, termtype) then

      local spot=self:_GetParkingSpotByID(_spot.Term_Index)

      if spot then

        spot.Free=_isfree(_spot) -- updated
        spot.TOAC=_spot.TO_AC    -- updated
        spot.AirbaseName=self.AirbaseName

        table.insert(spots, spot)

      else

        self:E(string.format("ERROR: Parking spot %s is nil!", tostring(_spot.Term_Index)))

      end

    end

  end

  return spots
end

--- Get a table containing the coordinates, terminal index and terminal type of free parking spots at an airbase.
-- @param #AIRBASE self
-- @param #AIRBASE.TerminalType termtype Terminal type.
-- @param #boolean allowTOAC If true, spots are considered free even though TO_AC is true. Default is off which is saver to avoid spawning aircraft on top of each other. Option might be enabled for FARPS and ships.
-- @return #table Table free parking spots. Table has the elements ".Coordinate, ".TerminalID", ".TerminalType", ".TOAC", ".Free", ".TerminalID0", ".DistToRwy".
function AIRBASE:GetFreeParkingSpotsTable(termtype, allowTOAC)

  -- Get parking data of all free spots.
  local parkingfree=self:GetParkingData(true)

  -- Put coordinates of free spots into table.
  local freespots={}
  for _,_spot in pairs(parkingfree) do
    if AIRBASE._CheckTerminalType(_spot.Term_Type, termtype) then -- and _spot.Term_Index>0 then --Not sure why I had this in. But caused problems now for a Gas platform where a valid spot was not included!
      if (allowTOAC and allowTOAC==true) or _spot.TO_AC==false then

        local spot=self:_GetParkingSpotByID(_spot.Term_Index)

        spot.Free=true -- updated
        spot.TOAC=_spot.TO_AC    -- updated
        spot.AirbaseName=self.AirbaseName

        table.insert(freespots, spot)

      end
    end
  end

  return freespots
end

--- Get a table containing the coordinates, terminal index and terminal type of free parking spots at an airbase.
-- @param #AIRBASE self
-- @param #number TerminalID The terminal ID of the parking spot.
-- @return #AIRBASE.ParkingSpot Table free parking spots. Table has the elements ".Coordinate, ".TerminalID", ".TerminalType", ".TOAC", ".Free", ".TerminalID0", ".DistToRwy".
function AIRBASE:GetParkingSpotData(TerminalID)

  -- Get parking data.
  local parkingdata=self:GetParkingSpotsTable()

  for _,_spot in pairs(parkingdata) do
    local spot=_spot --#AIRBASE.ParkingSpot
    self:T({TerminalID=spot.TerminalID,TerminalType=spot.TerminalType})
    if TerminalID==spot.TerminalID then
      return spot
    end
  end

  self:E("ERROR: Could not find spot with Terminal ID="..tostring(TerminalID))
  return nil
end

--- Place markers of parking spots on the F10 map.
-- @param #AIRBASE self
-- @param #AIRBASE.TerminalType termtype Terminal type for which marks should be placed.
-- @param #boolean mark If false, do not place markers but only give output to DCS.log file. Default true.
function AIRBASE:MarkParkingSpots(termtype, mark)

  -- Default is true.
  if mark==nil then
    mark=true
  end

  -- Get parking data from getParking() wrapper function.
  local parkingdata=self:GetParkingSpotsTable(termtype)

  -- Get airbase name.
  local airbasename=self:GetName()
  self:E(string.format("Parking spots at %s for terminal type %s:", airbasename, tostring(termtype)))

  for _,_spot in pairs(parkingdata) do

    -- Mark text.
    local _text=string.format("Term Index=%d, Term Type=%d, Free=%s, TOAC=%s, Term ID0=%d, Dist2Rwy=%.1f m",
    _spot.TerminalID, _spot.TerminalType,tostring(_spot.Free),tostring(_spot.TOAC),_spot.TerminalID0,_spot.DistToRwy)

    -- Create mark on the F10 map.
    if mark then
      _spot.Coordinate:MarkToAll(_text)
    end

    -- Info to DCS.log file.
    local _text=string.format("%s, Term Index=%3d, Term Type=%03d, Free=%5s, TOAC=%5s, Term ID0=%3d, Dist2Rwy=%.1f m",
    airbasename, _spot.TerminalID, _spot.TerminalType,tostring(_spot.Free),tostring(_spot.TOAC),_spot.TerminalID0,_spot.DistToRwy)
    self:E(_text)
  end
end

--- Seach unoccupied parking spots at the airbase for a specific group of aircraft. The routine also optionally checks for other unit, static and scenery options in a certain radius around the parking spot.
-- The dimension of the spawned aircraft and of the potential obstacle are taken into account. Note that the routine can only return so many spots that are free.
-- @param #AIRBASE self
-- @param Wrapper.Group#GROUP group Aircraft group for which the parking spots are requested.
-- @param #AIRBASE.TerminalType terminaltype (Optional) Only search spots at a specific terminal type. Default is all types execpt on runway.
-- @param #number scanradius (Optional) Radius in meters around parking spot to scan for obstacles. Default 50 m.
-- @param #boolean scanunits (Optional) Scan for units as obstacles. Default true.
-- @param #boolean scanstatics (Optional) Scan for statics as obstacles. Default true.
-- @param #boolean scanscenery (Optional) Scan for scenery as obstacles. Default false. Can cause problems with e.g. shelters.
-- @param #boolean verysafe (Optional) If true, wait until an aircraft has taken off until the parking spot is considered to be free. Defaul false.
-- @param #number nspots (Optional) Number of freeparking spots requested. Default is the number of aircraft in the group.
-- @param #table parkingdata (Optional) Parking spots data table. If not given it is automatically derived from the GetParkingSpotsTable() function.
-- @return #table Table of coordinates and terminal IDs of free parking spots. Each table entry has the elements .Coordinate and .TerminalID.
function AIRBASE:FindFreeParkingSpotForAircraft(group, terminaltype, scanradius, scanunits, scanstatics, scanscenery, verysafe, nspots, parkingdata)

  -- Init default
  scanradius=scanradius or 50
  if scanunits==nil then
    scanunits=true
  end
  if scanstatics==nil then
    scanstatics=true
  end
  if scanscenery==nil then
    scanscenery=false
  end
  if verysafe==nil then
    verysafe=false
  end

  -- Function calculating the overlap of two (square) objects.
  local function _overlap(object1, object2, dist)
    local pos1=object1 --Wrapper.Positionable#POSITIONABLE
    local pos2=object2 --Wrapper.Positionable#POSITIONABLE
    local r1=pos1:GetBoundingRadius()
    local r2=pos2:GetBoundingRadius()
    if r1 and r2 then
      local safedist=(r1+r2)*1.1
      local safe = (dist > safedist)
      self:T2(string.format("r1=%.1f r2=%.1f s=%.1f d=%.1f ==> safe=%s", r1, r2, safedist, dist, tostring(safe)))
      return safe
    else
      return true
    end
  end

  -- Get airport name.
  local airport=self:GetName()

  -- Get parking spot data table. This contains free and "non-free" spots.
  -- Note that there are three major issues with the DCS getParking() function:
  -- 1. A spot is considered as NOT free until an aircraft that is present has finally taken off. This might be a bit long especiall at smaller airports.
  -- 2. A "free" spot does not take the aircraft size into accound. So if two big aircraft are spawned on spots next to each other, they might overlap and get destroyed.
  -- 3. The routine return a free spot, if there a static objects placed on the spot.
  parkingdata=parkingdata or self:GetParkingSpotsTable(terminaltype)

  -- Get the aircraft size, i.e. it's longest side of x,z.
  local aircraft = nil -- fix local problem below
  -- SU27 dimensions as default
  local _aircraftsize = 23
  local ax = 23 -- l
  local ay = 7 -- h
  local az = 17 -- w
  if group and group.ClassName == "GROUP" then
    aircraft=group:GetUnit(1)
    if aircraft then
      _aircraftsize, ax,ay,az=aircraft:GetObjectSize()
    end
  end


  -- Number of spots we are looking for. Note that, e.g. grouping can require a number different from the group size!
  local _nspots=nspots or group:GetSize()

  -- Debug info.
  self:T(string.format("%s: Looking for %d parking spot(s) for aircraft of size %.1f m (x=%.1f,y=%.1f,z=%.1f) at terminal type %s.", airport, _nspots, _aircraftsize, ax, ay, az, tostring(terminaltype)))

  -- Table of valid spots.
  local validspots={}
  local nvalid=0

  -- Test other stuff if no parking spot is available.
  local _test=false
  if _test then
    return validspots
  end

  -- Mark all found obstacles on F10 map for debugging.
  local markobstacles=false

  -- Loop over all known parking spots
  for _,parkingspot in pairs(parkingdata) do

    -- Coordinate of the parking spot.
    local _spot=parkingspot.Coordinate   -- Core.Point#COORDINATE
    local _termid=parkingspot.TerminalID

    -- Check terminal type and black/white listed parking spots.
    if AIRBASE._CheckTerminalType(parkingspot.TerminalType, terminaltype) and self:_CheckParkingLists(_termid) then

      -- Very safe uses the DCS getParking() info to check if a spot is free. Unfortunately, the function returns free=false until the aircraft has actually taken-off.
      if verysafe and (parkingspot.Free==false or parkingspot.TOAC==true) then

        -- DCS getParking() routine returned that spot is not free.
        self:T(string.format("%s: Parking spot id %d NOT free (or aircraft has not taken off yet). Free=%s, TOAC=%s.", airport, parkingspot.TerminalID, tostring(parkingspot.Free), tostring(parkingspot.TOAC)))

      else

        -- Scan a radius of 50 meters around the spot.
        local _,_,_,_units,_statics,_sceneries=_spot:ScanObjects(scanradius, scanunits, scanstatics, scanscenery)

        -- Loop over objects within scan radius.
        local occupied=false

        -- Check all units.
        for _,unit in pairs(_units) do
          local _coord=unit:GetCoordinate()
          local _dist=_coord:Get2DDistance(_spot)
          local _safe=_overlap(aircraft, unit, _dist)

          if markobstacles then
            local l,x,y,z=unit:GetObjectSize()
            _coord:MarkToAll(string.format("Unit %s\nx=%.1f y=%.1f z=%.1f\nl=%.1f d=%.1f\nspot %d safe=%s", unit:GetName(),x,y,z,l,_dist, _termid, tostring(_safe)))
          end

          if scanunits and not _safe then
            occupied=true
          end
        end

        -- Check all statics.
        for _,static in pairs(_statics) do
          local _static=STATIC:Find(static)
          local _vec3=static:getPoint()
          local _coord=COORDINATE:NewFromVec3(_vec3)
          local _dist=_coord:Get2DDistance(_spot)
          local _safe=_overlap(aircraft,_static,_dist)

          if markobstacles then
            local l,x,y,z=_static:GetObjectSize()
            _coord:MarkToAll(string.format("Static %s\nx=%.1f y=%.1f z=%.1f\nl=%.1f d=%.1f\nspot %d safe=%s", static:getName(),x,y,z,l,_dist, _termid, tostring(_safe)))
          end

          if scanstatics and not _safe then
            occupied=true
          end
        end

        -- Check all scenery.
        for _,scenery in pairs(_sceneries) do
          local _scenery=SCENERY:Register(scenery:getTypeName(), scenery)
          local _vec3=scenery:getPoint()
          local _coord=COORDINATE:NewFromVec3(_vec3)
          local _dist=_coord:Get2DDistance(_spot)
          local _safe=_overlap(aircraft,_scenery,_dist)

          if markobstacles then
            local l,x,y,z=scenery:GetObjectSize(scenery)
            _coord:MarkToAll(string.format("Scenery %s\nx=%.1f y=%.1f z=%.1f\nl=%.1f d=%.1f\nspot %d safe=%s", scenery:getTypeName(),x,y,z,l,_dist, _termid, tostring(_safe)))
          end

          if scanscenery and not _safe then
            occupied=true
          end
        end

        -- Now check the already given spots so that we do not put a large aircraft next to one we already assigned a nearby spot.
        for _,_takenspot in pairs(validspots) do
          local _dist=_takenspot.Coordinate:Get2DDistance(_spot)
          local _safe=_overlap(aircraft, aircraft, _dist)
          if not _safe then
            occupied=true
          end
        end

        --_spot:MarkToAll(string.format("Parking spot %d free=%s", parkingspot.TerminalID, tostring(not occupied)))
        if occupied then
          self:T(string.format("%s: Parking spot id %d occupied.", airport, _termid))
        else
          self:T(string.format("%s: Parking spot id %d free.", airport, _termid))
          if nvalid<_nspots then
            table.insert(validspots, {Coordinate=_spot, TerminalID=_termid})
          end
          nvalid=nvalid+1
          self:T(string.format("%s: Parking spot id %d free. Nfree=%d/%d.", airport, _termid, nvalid,_nspots))
        end

      end -- loop over units

      -- We found enough spots.
      if nvalid>=_nspots then
        return validspots
      end
    end -- check terminal type
  end

  -- Retrun spots we found, even if there were not enough.
  return validspots

end

--- Check black and white lists.
-- @param #AIRBASE self
-- @param #number TerminalID Terminal ID to check.
-- @return #boolean `true` if this is a valid spot.
function AIRBASE:_CheckParkingLists(TerminalID)

  -- First check the black list. If we find a match, this spot is forbidden!
  if self.parkingBlacklist and #self.parkingBlacklist>0 then
    for _,terminalID in pairs(self.parkingBlacklist or {}) do
      if terminalID==TerminalID then
        -- This is a invalid spot.
        return false
      end
    end
  end


  -- Check if a whitelist was defined.
  if self.parkingWhitelist and #self.parkingWhitelist>0 then
    for _,terminalID in pairs(self.parkingWhitelist or {}) do
      if terminalID==TerminalID then
        -- This is a valid spot.
        return true
      end
    end
    -- No match ==> invalid spot
    return false
  end

  -- Neither black nor white lists were defined or spot is not in black list.
  return true
end

--- Helper function to check for the correct terminal type including "artificial" ones.
-- @param #number Term_Type Terminal type from getParking routine.
-- @param #AIRBASE.TerminalType termtype Terminal type from AIRBASE.TerminalType enumerator.
-- @return #boolean True if terminal types match.
function AIRBASE._CheckTerminalType(Term_Type, termtype)

  -- Nill check for Term_Type.
  if Term_Type==nil then
    return false
  end

  -- If no terminal type is requested, we return true. BUT runways are excluded unless explicitly requested.
  if termtype==nil then
    if Term_Type==AIRBASE.TerminalType.Runway then
      return false
    else
      return true
    end
  end

  -- Init no match.
  local match=false

  -- Standar case.
  if Term_Type==termtype then
    match=true
  end

  -- Artificial cases. Combination of terminal types.
  if termtype==AIRBASE.TerminalType.OpenMedOrBig then
    if Term_Type==AIRBASE.TerminalType.OpenMed or Term_Type==AIRBASE.TerminalType.OpenBig then
      match=true
    end
  elseif termtype==AIRBASE.TerminalType.HelicopterUsable then
    if Term_Type==AIRBASE.TerminalType.OpenMed or Term_Type==AIRBASE.TerminalType.OpenBig or Term_Type==AIRBASE.TerminalType.HelicopterOnly then
      match=true
     end
  elseif termtype==AIRBASE.TerminalType.FighterAircraft then
    if Term_Type==AIRBASE.TerminalType.OpenMed or Term_Type==AIRBASE.TerminalType.OpenBig or Term_Type==AIRBASE.TerminalType.Shelter or Term_Type==AIRBASE.TerminalType.SmallSizeFighter then
      match=true
    end
  end

  return match
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Runway
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get runways.
-- @param #AIRBASE self
-- @return #table Runway data.
function AIRBASE:GetRunways()
  return self.runways or {}
end

--- Get runway by its name.
-- @param #AIRBASE self
-- @param #string Name Name of the runway, e.g. "31" or "21L".
-- @return #AIRBASE.Runway Runway data.
function AIRBASE:GetRunwayByName(Name)

  if Name==nil then
    return
  end

  if Name then
    for _,_runway in pairs(self.runways) do
      local runway=_runway --#AIRBASE.Runway

      -- Name including L or R, e.g. "31L".
      local name=self:GetRunwayName(runway)

      if name==Name:upper() then
        return runway
      end
    end
  end

  self:E("ERROR: Could not find runway with name "..tostring(Name))
  return nil
end

--- Init runways.
-- @param #AIRBASE self
-- @param #boolean IncludeInverse If `true` or `nil`, include inverse runways.
-- @return #table Runway data.
function AIRBASE:_InitRunways(IncludeInverse)

  -- Default is true.
  if IncludeInverse==nil then
    IncludeInverse=true
  end

  -- Runway table.
  local Runways={}

  if self:GetAirbaseCategory()~=Airbase.Category.AIRDROME then
    self.runways={}
    return {}
  end

  --- Function to create a runway data table.
  local function _createRunway(name, course, width, length, center)

    -- Bearing in rad.
    local bearing=-1*course

    -- Heading in degrees.
    local heading=math.deg(bearing)

    -- Data table.
    local runway={} --#AIRBASE.Runway

    local namefromheading = math.floor(heading/10)

    if self.AirbaseName == AIRBASE.Syria.Beirut_Rafic_Hariri and math.abs(namefromheading-name) > 1 then
      runway.name=string.format("%02d", tonumber(namefromheading))
    else
     runway.name=string.format("%02d", tonumber(name))
    end

    --runway.name=string.format("%02d", tonumber(name))
    runway.magheading=tonumber(runway.name)*10
    runway.heading=heading
    runway.width=width or 0
    runway.length=length or 0
    runway.center=COORDINATE:NewFromVec3(center)

    -- Ensure heading is [0,360]
    if runway.heading>360 then
      runway.heading=runway.heading-360
    elseif runway.heading<0 then
      runway.heading=runway.heading+360
    end

    -- For example at Nellis, DCS reports two runways, i.e. 03 and 21, BUT the "course" of both is -0.700 rad = 40 deg!
    -- As a workaround, I check the difference between the "magnetic" heading derived from the name and the true heading.
    -- If this is too large then very likely the "inverse" heading is the one we are looking for.
    if math.abs(runway.heading-runway.magheading)>60 then
      self:T(string.format("WARNING: Runway %s: heading=%.1f magheading=%.1f", runway.name, runway.heading, runway.magheading))
      runway.heading=runway.heading-180
    end

    -- Ensure heading is [0,360]
    if runway.heading>360 then
      runway.heading=runway.heading-360
    elseif runway.heading<0 then
      runway.heading=runway.heading+360
    end

    -- Start and endpoint of runway.
    runway.position=runway.center:Translate(-runway.length/2, runway.heading)
    runway.endpoint=runway.center:Translate( runway.length/2, runway.heading)

    local init=runway.center:GetVec3()
    local width = runway.width/2
    local L2=runway.length/2

    local offset1 = {x = init.x + (math.cos(bearing + math.pi) * L2), y = init.z + (math.sin(bearing + math.pi) * L2)}
    local offset2 = {x = init.x - (math.cos(bearing + math.pi) * L2), y = init.z - (math.sin(bearing + math.pi) * L2)}

    local points={}
    points[1] = {x = offset1.x + (math.cos(bearing + (math.pi/2)) * width), y = offset1.y + (math.sin(bearing + (math.pi/2)) * width)}
    points[2] = {x = offset1.x + (math.cos(bearing - (math.pi/2)) * width), y = offset1.y + (math.sin(bearing - (math.pi/2)) * width)}
    points[3] = {x = offset2.x + (math.cos(bearing - (math.pi/2)) * width), y = offset2.y + (math.sin(bearing - (math.pi/2)) * width)}
    points[4] = {x = offset2.x + (math.cos(bearing + (math.pi/2)) * width), y = offset2.y + (math.sin(bearing + (math.pi/2)) * width)}

    -- Runway zone.
    runway.zone=ZONE_POLYGON_BASE:New(string.format("%s Runway %s", self.AirbaseName, runway.name), points)

    return runway
  end


  -- Get DCS object.
  local airbase=self:GetDCSObject()

  if airbase then


    -- Get DCS runways.
    local runways=airbase:getRunways()

    -- Debug info.
    self:T2(runways)

    if runways then

      -- Loop over runways.
      for _,rwy in pairs(runways) do

        -- Debug info.
        self:T(rwy)

        -- Get runway data.
        local runway=_createRunway(rwy.Name, rwy.course, rwy.width, rwy.length, rwy.position) --#AIRBASE.Runway

        -- Add to table.
        table.insert(Runways, runway)

        -- Include "inverse" runway.
        if IncludeInverse then

          -- Create "inverse".
          local idx=tonumber(runway.name)
          local name2=tostring(idx-18)
          if idx<18 then
            name2=tostring(idx+18)
          end

          -- Create "inverse" runway.
          local runway=_createRunway(name2, rwy.course-math.pi, rwy.width, rwy.length, rwy.position) --#AIRBASE.Runway

          -- Add inverse to table.
          table.insert(Runways, runway)

        end

      end

    end

  end

  -- Look for identical (parallel) runways, e.g. 03L and 03R at Nellis.
  local rpairs={}
  for i,_ri in pairs(Runways) do
    local ri=_ri --#AIRBASE.Runway
    for j,_rj in pairs(Runways) do
      local rj=_rj --#AIRBASE.Runway
      if i<j then
        if ri.name==rj.name then
          rpairs[i]=j
        end
      end
    end
  end

  local function isLeft(a, b, c)
    --return ((b.x - a.x)*(c.z - a.z) - (b.z - a.z)*(c.x - a.x)) > 0
    return ((b.z - a.z)*(c.x - a.x) - (b.x - a.x)*(c.z - a.z)) > 0
  end

  for i,j in pairs(rpairs) do
    local ri=Runways[i] --#AIRBASE.Runway
    local rj=Runways[j] --#AIRBASE.Runway

    -- Draw arrow.
    --ri.center:ArrowToAll(rj.center)

    local c0=ri.center

    -- Vector in the direction of the runway.
    local a=UTILS.VecTranslate(c0, 1000, ri.heading)

    -- Vector from runway i to runway j.
    local b=UTILS.VecSubstract(rj.center, ri.center)
    b=UTILS.VecAdd(ri.center, b)

    -- Check if rj is left of ri.
    local left=isLeft(c0, a, b)

    --env.info(string.format("Found pair %s: i=%d, j=%d, left==%s", ri.name, i, j, tostring(left)))

    if left then
      ri.isLeft=false
      rj.isLeft=true
    else
      ri.isLeft=true
      rj.isLeft=false
    end

    --break
  end

  -- Set runways.
  self.runways=Runways

  return Runways
end


--- Get runways data. Only for airdromes!
-- @param #AIRBASE self
-- @param #number magvar (Optional) Magnetic variation in degrees.
-- @param #boolean mark (Optional) Place markers with runway data on F10 map.
-- @return #table Runway data.
function AIRBASE:GetRunwayData(magvar, mark)

  -- Runway table.
  local runways={}

  if self:GetAirbaseCategory()~=Airbase.Category.AIRDROME then
    return {}
  end

  -- Get spawn points on runway. These can be used to determine the runway heading.
  local runwaycoords=self:GetParkingSpotsCoordinates(AIRBASE.TerminalType.Runway)

  -- Debug: For finding the numbers of the spawn points belonging to each runway.
  if false then
    for i,_coord in pairs(runwaycoords) do
      local coord=_coord --Core.Point#COORDINATE
      coord:Translate(100, 0):MarkToAll("Runway i="..i)
    end
  end

  -- Magnetic declination.
  magvar=magvar or UTILS.GetMagneticDeclination()

  -- Number of runways.
  local N=#runwaycoords
  local N2=N/2
  local exception=false

  -- Airbase name.
  local name=self:GetName()


  -- Exceptions
  if name==AIRBASE.Nevada.Jean_Airport or
     name==AIRBASE.Nevada.Creech_AFB   or
     name==AIRBASE.PersianGulf.Abu_Dhabi_International_Airport or
     name==AIRBASE.PersianGulf.Dubai_Intl or
     name==AIRBASE.PersianGulf.Shiraz_International_Airport or
     name==AIRBASE.PersianGulf.Kish_International_Airport or
     name==AIRBASE.MarianaIslands.Andersen_AFB then

    -- 1-->4, 2-->3, 3-->2, 4-->1
    exception=1

  elseif UTILS.GetDCSMap()==DCSMAP.Syria and N>=2 and
    name~=AIRBASE.Syria.Minakh and
    name~=AIRBASE.Syria.Damascus and
    name~=AIRBASE.Syria.Khalkhalah and
    name~=AIRBASE.Syria.Marj_Ruhayyil and
    name~=AIRBASE.Syria.Beirut_Rafic_Hariri then

    -- 1-->3, 2-->4, 3-->1, 4-->2
    exception=2

  end

  --- Function returning the index of the runway coordinate belonding to the given index i.
  local function f(i)

    local j

    if exception==1 then

      j=N-(i-1)  -- 1-->4, 2-->3

    elseif exception==2 then

      if i<=N2 then
        j=i+N2  -- 1-->3, 2-->4
      else
        j=i-N2  -- 3-->1, 4-->3
      end

    else

      if i%2==0 then
        j=i-1  -- even 2-->1, 4-->3
      else
        j=i+1  -- odd  1-->2, 3-->4
      end

    end

    -- Special case where there is no obvious order.
    if name==AIRBASE.Syria.Beirut_Rafic_Hariri then
      if i==1 then
        j=3
      elseif i==2 then
        j=6
      elseif i==3 then
        j=1
      elseif i==4 then
        j=5
      elseif i==5 then
        j=4
      elseif i==6 then
        j=2
      end
    end

    if name==AIRBASE.Syria.Ramat_David then
      if i==1 then
        j=4
      elseif i==2 then
        j=6
      elseif i==3 then
        j=5
      elseif i==4 then
        j=1
      elseif i==5 then
        j=3
      elseif i==6 then
        j=2
      end
    end

    return j
  end


  for i=1,N do

    -- Get the other spawn point coordinate.
    local j=f(i)

    -- Debug info.
    --env.info(string.format("Runway i=%s j=%s (N=%d #runwaycoord=%d)", tostring(i), tostring(j), N, #runwaycoords))

    -- Coordinates of the two runway points.
    local c1=runwaycoords[i] --Core.Point#COORDINATE
    local c2=runwaycoords[j] --Core.Point#COORDINATE

    -- Heading of runway.
    local hdg=c1:HeadingTo(c2)

    -- Runway ID: heading=070° ==> idx="07"
    local idx=string.format("%02d", UTILS.Round((hdg-magvar)/10, 0))

    -- Runway table.
    local runway={} --#AIRBASE.Runway
    runway.heading=hdg
    runway.idx=idx
    runway.length=c1:Get2DDistance(c2)
    runway.position=c1
    runway.endpoint=c2

    -- Debug info.
    --self:I(string.format("Airbase %s: Adding runway id=%s, heading=%03d, length=%d m i=%d j=%d", self:GetName(), runway.idx, runway.heading, runway.length, i, j))

    -- Debug mark
    if mark then
      runway.position:MarkToAll(string.format("Runway %s: true heading=%03d (magvar=%d), length=%d m, i=%d, j=%d", runway.idx, runway.heading, magvar, runway.length, i, j))
    end

    -- Add runway.
    table.insert(runways, runway)

  end

  return runways
end

--- Set the active runway for landing and takeoff.
-- @param #AIRBASE self
-- @param #string Name Name of the runway, e.g. "31" or "02L" or "90R". If not given, the runway is determined from the wind direction.
-- @param #boolean PreferLeft If `true`, perfer the left runway. If `false`, prefer the right runway. If `nil` (default), do not care about left or right.
function AIRBASE:SetActiveRunway(Name, PreferLeft)

  self:SetActiveRunwayTakeoff(Name, PreferLeft)

  self:SetActiveRunwayLanding(Name,PreferLeft)

end

--- Set the active runway for landing.
-- @param #AIRBASE self
-- @param #string Name Name of the runway, e.g. "31" or "02L" or "90R". If not given, the runway is determined from the wind direction.
-- @param #boolean PreferLeft If `true`, perfer the left runway. If `false`, prefer the right runway. If `nil` (default), do not care about left or right.
-- @return #AIRBASE.Runway The active runway for landing.
function AIRBASE:SetActiveRunwayLanding(Name, PreferLeft)

  local runway=self:GetRunwayByName(Name)

  if not runway then
    runway=self:GetRunwayIntoWind(PreferLeft)
  end

  if runway then
    self:T(string.format("%s: Setting active runway for landing as %s", self.AirbaseName, self:GetRunwayName(runway)))
  else
    self:E("ERROR: Could not set the runway for landing!")
  end

  self.runwayLanding=runway

  return runway
end

--- Get the active runways.
-- @param #AIRBASE self
-- @return #AIRBASE.Runway The active runway for landing.
-- @return #AIRBASE.Runway The active runway for takeoff.
function AIRBASE:GetActiveRunway()
  return self.runwayLanding, self.runwayTakeoff
end


--- Get the active runway for landing.
-- @param #AIRBASE self
-- @return #AIRBASE.Runway The active runway for landing.
function AIRBASE:GetActiveRunwayLanding()
  return self.runwayLanding
end

--- Get the active runway for takeoff.
-- @param #AIRBASE self
-- @return #AIRBASE.Runway The active runway for takeoff.
function AIRBASE:GetActiveRunwayTakeoff()
  return self.runwayTakeoff
end


--- Set the active runway for takeoff.
-- @param #AIRBASE self
-- @param #string Name Name of the runway, e.g. "31" or "02L" or "90R". If not given, the runway is determined from the wind direction.
-- @param #boolean PreferLeft If `true`, perfer the left runway. If `false`, prefer the right runway. If `nil` (default), do not care about left or right.
-- @return #AIRBASE.Runway The active runway for landing.
function AIRBASE:SetActiveRunwayTakeoff(Name, PreferLeft)

  local runway=self:GetRunwayByName(Name)

  if not runway then
    runway=self:GetRunwayIntoWind(PreferLeft)
  end

  if runway then
    self:T(string.format("%s: Setting active runway for takeoff as %s", self.AirbaseName, self:GetRunwayName(runway)))
  else
    self:E("ERROR: Could not set the runway for takeoff!")
  end

  self.runwayTakeoff=runway

  return runway
end


--- Get the runway where aircraft would be taking of or landing into the direction of the wind.
-- NOTE that this requires the wind to be non-zero as set in the mission editor.
-- @param #AIRBASE self
-- @param #boolean PreferLeft If `true`, perfer the left runway. If `false`, prefer the right runway. If `nil` (default), do not care about left or right.
-- @return #AIRBASE.Runway Active runway data table.
function AIRBASE:GetRunwayIntoWind(PreferLeft)

  -- Get runway data.
  local runways=self:GetRunways()

  -- Get wind vector.
  local Vwind=self:GetCoordinate():GetWindWithTurbulenceVec3()
  local norm=UTILS.VecNorm(Vwind)

  -- Active runway number.
  local iact=1

  -- Check if wind is blowing (norm>0).
  if norm>0 then

    -- Normalize wind (not necessary).
    Vwind.x=Vwind.x/norm
    Vwind.y=0
    Vwind.z=Vwind.z/norm

    -- Loop over runways.
    local dotmin=nil
    for i,_runway in pairs(runways) do
      local runway=_runway --#AIRBASE.Runway

      if PreferLeft==nil or PreferLeft==runway.isLeft then

        -- Angle in rad.
        local alpha=math.rad(runway.heading)

        -- Runway vector.
        local Vrunway={x=math.cos(alpha), y=0, z=math.sin(alpha)}

        -- Dot product: parallel component of the two vectors.
        local dot=UTILS.VecDot(Vwind, Vrunway)

        -- New min?
        if dotmin==nil or dot<dotmin then
          dotmin=dot
          iact=i
        end

      end

    end
  else
    self:E("WARNING: Norm of wind is zero! Cannot determine runway based on wind direction")
  end

  return runways[iact]
end

--- Get name of a given runway, e.g. "31L".
-- @param #AIRBASE self
-- @param #AIRBASE.Runway Runway The runway. Default is the active runway.
-- @param #boolean LongLeftRight If `true`, return "Left" or "Right" instead of "L" or "R".
-- @return #string Name of the runway or "XX" if it could not be found.
function AIRBASE:GetRunwayName(Runway, LongLeftRight)

  Runway=Runway or self:GetActiveRunway()

  local name="XX"
  if Runway then
    name=Runway.name
    if Runway.isLeft==true then
      if LongLeftRight then
        name=name.." Left"
      else
        name=name.."L"
      end
    elseif Runway.isLeft==false then
      if LongLeftRight then
        name=name.." Right"
      else
        name=name.."R"
      end
    end
  end

  return name
end

--- Function that checks if at leat one unit of a group has been spawned close to a spawn point on the runway.
-- @param #AIRBASE self
-- @param Wrapper.Group#GROUP group Group to be checked.
-- @param #number radius Radius around the spawn point to be checked. Default is 50 m.
-- @param #boolean despawn If true, the group is destroyed.
-- @return #boolean True if group is within radius around spawn points on runway.
function AIRBASE:CheckOnRunWay(group, radius, despawn)

  -- Default radius.
  radius=radius or 50

  -- We only check at real airbases (not FARPS or ships).
  if self:GetAirbaseCategory()~=Airbase.Category.AIRDROME then
    return false
  end

  if group and group:IsAlive() then

    -- Debug.
    self:T(string.format("%s, checking if group %s is on runway?",self:GetName(), group:GetName()))

    -- Get coordinates on runway.
    local runwaypoints=self:GetParkingSpotsCoordinates(AIRBASE.TerminalType.Runway)

    -- Get units of group.
    local units=group:GetUnits()

    -- Loop over units.
    for _,_unit in pairs(units) do

      local unit=_unit --Wrapper.Unit#UNIT

      -- Check if unit is alive and not in air.
      if unit and unit:IsAlive() and not unit:InAir() then
        self:T(string.format("%s, checking if unit %s is on runway?",self:GetName(), unit:GetName()))

        -- Loop over runway spawn points.
        for _i,_coord in pairs(runwaypoints) do

          -- Distance between unit and spawn pos.
          local dist=unit:GetCoordinate():Get2DDistance(_coord)

          -- Mark unit spawn points for debugging.
          --unit:GetCoordinate():MarkToAll(string.format("unit %s distance to rwy %d = %d",unit:GetName(),_i, dist))

          -- Check if unit is withing radius.
          if dist<radius  then
            self:E(string.format("%s, unit %s of group %s was spawned on runway #%d. Distance %.1f < radius %.1f m. Despawn = %s.", self:GetName(), unit:GetName(), group:GetName(),_i, dist, radius, tostring(despawn)))
            --unit:FlareRed()
            if despawn then
              group:Destroy(true)
            end
            return true
          else
            self:T(string.format("%s, unit %s of group %s was NOT spawned on runway #%d. Distance %.1f > radius %.1f m. Despawn = %s.", self:GetName(), unit:GetName(), group:GetName(),_i, dist, radius, tostring(despawn)))
            --unit:FlareGreen()
          end

        end
      else
        self:T(string.format("%s, checking if unit %s of group %s is on runway. Unit is NOT alive.",self:GetName(), unit:GetName(), group:GetName()))
      end
    end
  else
    self:T(string.format("%s, checking if group %s is on runway. Group is NOT alive.",self:GetName(), group:GetName()))
  end

  return false
end

--- Get category of airbase.
-- @param #AIRBASE self
-- @return #number Category of airbase from GetDesc().category.
function AIRBASE:GetCategory()
  return self.category
end

--- Get category name of airbase.
-- @param #AIRBASE self
-- @return #string Category of airbase, i.e. Airdrome, Ship, or Helipad
function AIRBASE:GetCategoryName()
  return AIRBASE.CategoryName[self.category]
end
