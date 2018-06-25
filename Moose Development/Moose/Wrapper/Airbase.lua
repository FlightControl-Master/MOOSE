--- **Wrapper** -- AIRBASE is a wrapper class to handle the DCS Airbase objects.
-- 
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ### Contributions: 
-- 
-- ===
-- 
-- @module Wrapper.Airbase
-- @image Wrapper_Airbase.JPG


--- @type AIRBASE
-- @extends Wrapper.Positionable#POSITIONABLE

--- Wrapper class to handle the DCS Airbase objects:
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
--  
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
--
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
--
--- @field PersianGulf
-- 
-- These are all airbases of the Persion Gulf Map:
-- 
--  * AIRBASE.PersianGulf.Fujairah_Intl
--  * AIRBASE.PersianGulf.Qeshm_Island
--  * AIRBASE.PersianGulf.Sir_Abu_Nuayr
--  * AIRBASE.PersianGulf.Abu_Musa_Island_Airport
--  * AIRBASE.PersianGulf.Bandar_Abbas_Intl
--  * AIRBASE.PersianGulf.Bandar_Lengeh
--  * AIRBASE.PersianGulf.Tunb_Island_AFB
--  * AIRBASE.PersianGulf.Havadarya
--  * AIRBASE.PersianGulf.Lar_Airbase
--  * AIRBASE.PersianGulf.Sirri_Island
--  * AIRBASE.PersianGulf.Tunb_Kochak
--  * AIRBASE.PersianGulf.Al_Dhafra_AB
--  * AIRBASE.PersianGulf.Dubai_Intl
--  * AIRBASE.PersianGulf.Al_Maktoum_Intl
--  * AIRBASE.PersianGulf.Khasab
--  * AIRBASE.PersianGulf.Al_Minhad_AB
 -- * AIRBASE.PersianGulf.Sharjah_Intl
AIRBASE.PersianGulf = {
  ["Fujairah_Intl"] = "Fujairah Intl",
  ["Qeshm_Island"] = "Qeshm Island",
  ["Sir_Abu_Nuayr"] = "Sir Abu Nuayr",
  ["Abu_Musa_Island_Airport"] = "Abu Musa Island Airport",
  ["Bandar_Abbas_Intl"] = "Bandar Abbas Intl",
  ["Bandar_Lengeh"] = "Bandar Lengeh",
  ["Tunb_Island_AFB"] = "Tunb Island AFB",
  ["Havadarya"] = "Havadarya",
  ["Lar_Airbase"] = "Lar Airbase",
  ["Sirri_Island"] = "Sirri Island",
  ["Tunb_Kochak"] = "Tunb Kochak",
  ["Al_Dhafra_AB"] = "Al Dhafra AB",
  ["Dubai_Intl"] = "Dubai Intl",
  ["Al_Maktoum_Intl"] = "Al Maktoum Intl",
  ["Khasab"] = "Khasab",
  ["Al_Minhad_AB"] = "Al Minhad AB",
  ["Sharjah_Intl"] = "Sharjah Intl",
  }
--
--- @field Terminal Types of parking spots.
AIRBASE.TerminalType = {
  Runway=16,
  Helicopter=40,
  HardenedShelter=68,
  OpenOrShelter=72,
  OpenAir=104,
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
-- @return Wrapper.Airbase#AIRBASE self
function AIRBASE:FindByName( AirbaseName )
  
  local AirbaseFound = _DATABASE:FindAirbase( AirbaseName )
  return AirbaseFound
end

--- Get the DCS object of an airbase
-- @param #AIRBASE self
-- @return DCS#Airbase DCS airbase object.
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

--- Get all airbases of the current map. This includes ships and FARPS.
-- @param #AIRBASE self
-- @param DCS#Coalition coalition (Optional) Return only airbases belonging to the specified coalition. By default, all airbases of the map are returned.
-- @return #table Table containing all airbase objects of the current map.
function AIRBASE:GetAllAirbases(coalition)
  
  local airbases={}
  for _,airbase in pairs(_DATABASE.AIRBASES) do
    if (coalition~=nil and self:GetCoalition()==coalition) or coalition==nil then
      table.insert(airbases, airbase)
    end
  end
  
  return airbases
end

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

  -- Get DCS airbase object.
  local DCSAirbase=self:GetDCSObject()
  
  -- Get parking data.
  local parkingdata=nil
  if DCSAirbase then
    parkingdata=DCSAirbase:getParking(available)
  end
  
  return parkingdata
end

--- Get number parking spots at an airbase. Optionally, for a specific terminal type. Spots on runway are exculded if not explicitly requested by terminal type
-- @param #AIRBASE self
-- @param #number termtype Terminal type.
-- @return #number Number of free parking spots at this airbase.
function AIRBASE:GetParkingSpotsNumber(termtype)

  -- Get free parking spots data.
  local parkingdata=self:GetParkingData(false)
  
  local nfree=0
  for _,parkingspot in pairs(parkingdata) do
    -- Spots on runway are not counted unless explicitly requested.
    if (termtype~=nil and parkingspot.Term_Type==termtype) or (termtype==nil and parkingspot.Term_Type~=AIRBASE.TerminalType.Runway) then
      nfree=nfree+1
    end
  end
  
  return nfree
end

--- Get number of free parking spots at an airbase.
-- @param #AIRBASE self
-- @param #number termtype Terminal type.
-- @param #boolean allowTOAC If true, spots are considered free even though TO_AC is true. Default is off which is saver to avoid spawning aircraft on top of each other. Option might be enabled for FARPS and ships. 
-- @return #number Number of free parking spots at this airbase.
function AIRBASE:GetFreeParkingSpotsNumber(termtype, allowTOAC)

  -- Get free parking spots data.
  local parkingdata=self:GetParkingData(true)
  
  local nfree=0
  for _,parkingspot in pairs(parkingdata) do
    -- Spots on runway are not counted unless explicitly requested.
    if (termtype~=nil and parkingspot.Term_Type==termtype) or (termtype==nil and parkingspot.Term_Type~=AIRBASE.TerminalType.Runway) then
      if (allowTOAC and allowTOAC==true) or parkingspot.TO_AC==false then
        nfree=nfree+1
      end
    end
  end
  
  return nfree
end

--- Get the coordinates of free parking spots at an airbase.
-- @param #AIRBASE self
-- @param #number termtype Terminal type.
-- @param #boolean allowTOAC If true, spots are considered free even though TO_AC is true. Default is off which is saver to avoid spawning aircraft on top of each other. Option might be enabled for FARPS and ships.
-- @return #table Table of coordinates of the free parking spots.
function AIRBASE:GetFreeParkingSpotsCoordinates(termtype, allowTOAC)

  -- Get free parking spots data.
  local parkingdata=self:GetParkingData(true)
  
  -- Put coordinates of free spots into table.
  local spots={}
  for _,parkingspot in pairs(parkingdata) do
    -- Coordinates on runway are not returned unless explicitly requested.
    if (termtype and parkingspot.Term_Type==termtype) or (termtype==nil and parkingspot.Term_Type~=AIRBASE.TerminalType.Runway) then
      if (allowTOAC and allowTOAC==true) or parkingspot.TO_AC==false then
        table.insert(spots, COORDINATE:NewFromVec3(parkingspot.vTerminalPos))
      end
    end
  end
  
  return spots
end

--- Get the coordinates of all parking spots at an airbase. Optionally only those of a specific terminal type. Spots on runways are excluded if not explicitly requested by terminal type.
-- @param #AIRBASE self
-- @param #number termtype (Optional) Terminal type. Default all.
-- @return #table Table of coordinates of parking spots.
function AIRBASE:GetParkingSpotsCoordinates(termtype)

  -- Get all parking spots data.
  local parkingdata=self:GetParkingData(false)
  
  -- Put coordinates of free spots into table.
  local spots={}
  for _,parkingspot in pairs(parkingdata) do
    -- Coordinates on runway are not returned unless explicitly requested.
    if (termtype and parkingspot.Term_Type==termtype) or (termtype==nil and parkingspot.Term_Type~=AIRBASE.TerminalType.Runway) then
      local _coord=COORDINATE:NewFromVec3(parkingspot.vTerminalPos)
      local gotunits,gotstatics,gotscenery,_,statics,_=_coord:ScanObjects(.5)
      env.info(string.format("FF scan: terminal index %03d, type = %03d, gotunits=%s, gotstatics=%s, gotscenery=%s", parkingspot.Term_Index+1, parkingspot.Term_Type, tostring(gotunits), tostring(gotstatics), tostring(gotscenery)))
      if gotstatics then
        for _,static in pairs(statics) do
          env.info(string.format("FF Static name= %s", tostring(static:getName())))
        end
      end
      table.insert(spots, _coord)
    end
  end
  
  return spots
end


--- Get a table containing the coordinates, terminal index and terminal type of free parking spots at an airbase.
-- @param #AIRBASE self
-- @param #number termtype Terminal type.
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
  
  -- Put coordinates of free spots into table.
  local freespots={}
  for _,_spot in pairs(parkingdata) do
    if (termtype and _spot.Term_Type==termtype) or (termtype==nil and _spot.Term_Type~=AIRBASE.TerminalType.Runway) then
      local _free=_isfree(_spot)
      local _coord=COORDINATE:NewFromVec3(_spot.vTerminalPos)
      table.insert(freespots, {Coordinate=_coord, TerminalID=_spot.Term_Index, TerminalType=_spot.Term_Type, TOAC=_spot.TO_AC, Free=_free, TerminalID0=_spot.Term_Index_0, DistToRwy=_spot.fDistToRW})
    end
  end
  
  return freespots
end

--- Get a table containing the coordinates, terminal index and terminal type of free parking spots at an airbase.
-- @param #AIRBASE self
-- @param #number termtype Terminal type.
-- @param #boolean allowTOAC If true, spots are considered free even though TO_AC is true. Default is off which is saver to avoid spawning aircraft on top of each other. Option might be enabled for FARPS and ships. 
-- @return #table Table free parking spots. Table has the elements ".Coordinate, ".TerminalID", ".TerminalType", ".TOAC", ".Free", ".TerminalID0", ".DistToRwy".
function AIRBASE:GetFreeParkingSpotsTable(termtype, allowTOAC)

  -- Get parking data of all free spots.
  local parkingfree=self:GetParkingData(true)
    
  -- Put coordinates of free spots into table.
  local freespots={}
  for _,_spot in pairs(parkingfree) do
    if (termtype and _spot.Term_Type==termtype) or (termtype==nil and _spot.Term_Type~=AIRBASE.TerminalType.Runway) then
      if (allowTOAC and allowTOAC==true) or _spot.TO_AC==false then
        local _coord=COORDINATE:NewFromVec3(_spot.vTerminalPos)
        table.insert(freespots, {Coordinate=_coord, TerminalID=_spot.Term_Index, TerminalType=_spot.Term_Type, TOAC=_spot.TO_AC, Free=true, TerminalID0=_spot.Term_Index_0, DistToRwy=_spot.fDistToRW})
      end
    end
  end
  
  return freespots
end

--- Place markers of parking spots on the F10 map.
-- @param #AIRBASE self
-- @param #number termtype Terminal type for which marks should be placed.
function AIRBASE:MarkParkingSpots(termtype)

  local parkingdata=self:GetParkingSpotsTable(termtype)

  local airbasename=self:GetName()
  self:E(string.format("Parking spots at %s for termial type %s:", airbasename, tostring(termtype)))
  
  for _,_spot in pairs(parkingdata) do
    
    -- Mark text.
    local _text=string.format("%s, Term Index = %3d, Term Type = %03d, Free = %5s, TOAC = %5s, Term ID0 = %3d, Dist2Rwy = %.1f",
    airbasename, _spot.TerminalID, _spot.TerminalType,tostring(_spot.Free),tostring(_spot.TOAC),_spot.TerminalID0,_spot.DistToRwy)
    
    -- Create mark on the F10 map.
    _spot.Coordinate:MarkToAll(_text)
    
    -- Info to DCS.log file.
    self:E(_text)
  end
end