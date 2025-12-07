--- **NAVIGATION** - Airbase radios.
--
-- **Main Features:**
--
--    * Get radio frequencies of airbases
--    * Find closest airbase radios
--    * Mark radio frequencies on F10 map
-- 
-- ===
--
-- ## Example Missions:
--
-- Demo missions can be found on [github](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/develop/Navigation%20-%20Radios).
-- 
-- ===
--
-- ### Author: **funkyfranky**
-- 
-- ===
-- @module Navigation.Radios
-- @image MOOSE.JPG

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- RADIOS class.
-- @type RADIOS
-- 
-- @field #string ClassName Name of the class.
-- @field #number verbose Verbosity of output.
-- @field #table radios Radios.
-- 
-- @extends Core.Base#BASE

--- *It's not true I had nothing on, I had the radio on.* -- *Marilyn Monroe*
--
-- ===
--
-- # The RADIOS Concept
--
-- This class is designed to make information about radios of a map/theatre easier accessible. The information contains mostly the frequencies of airbases of the map.
-- 
-- **Note** that try to avoid hard coding stuff in Moose since DCS is updated frequently and things change. Therefore, the main source of information is either a file `radio.lua` that can be
-- found in the installation directory of DCS for each map or a table that the user needs to provide.
-- **Note** your `MissionScripting` environment needs to be desanitized to read this data.
-- 
-- # Basic Setup
-- 
-- A new `RADIOS` object can be created with the @{#RADIOS.NewFromFile}(*radio_lua_file*) function.
-- 
--     local radios=RADIOS:NewFromFile("<DCS_Install_Directory>\Mods\terrains\<Map_Name>\Radio.lua")
--     radios:MarkerShow()
-- 
-- This will load the radios from the `<DCS_Install_Directory>` for the specific map and place markers on the F10 map. This is the first step you should do to ensure that the file
-- you provided is correct and all relevant radios are present.
-- 
-- # User Functions
-- 
-- ## F10 Map Markers
-- 
-- ## Position
-- 
-- ## Closest Radio
-- 
--
-- @field #RADIOS
RADIOS = {
  ClassName  = "RADIOS",
  verbose    =        0,
  radios    =        {},
}

--- Radio item data structure.
-- @type RADIOS.Radio
-- @field #string radioId Radio ID.
-- @field #table role Roles of the radio (usually {"ground", "tower", "approach"}).
-- @field #table callsign Callsigns of the radio (usually the airbase name).
-- @field #table frequency Frequencies of the radios.
-- @field #table position Position table.
-- @field #table sceneObjects Scenery objects.
-- @field #string name Name of the airbase.
-- @field Wrapper.Airbase#AIRBASE airbase Airbase.
-- @field Core.Point#COORDINATE coordinate The COORDINATE of the radio.
-- @field DCS#Vec3 vec3 3D vector.
-- @field #number markerID Marker ID.

--- Radio item data structure.
-- @type RADIOS.Frequency
-- @field #number modu Modulation type.
-- @field #number freq Frequency in Hz.


--- RADIOS class version.
-- @field #string version
RADIOS.version="0.1.0"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ToDo list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: A lot...

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor(s)
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new RADIOS class instance from a given table.
-- @param #RADIOS self
-- @param #table RadioTable Table with radios info.
-- @return #RADIOS self
function RADIOS:NewFromTable(RadioTable)

  -- Inherit everything from BASE class.
  self=BASE:Inherit(self, BASE:New()) -- #RADIOS
  
  --local airbasenames=AIRBASE.GetAllAirbaseNames()
  
  -- Get all airdromes
  local airdromes=AIRBASE.GetAllAirbases(nil, Airbase.Category.AIRDROME)
  
  for _,_radio in pairs(RadioTable) do
    local radio=_radio --#RADIOS.Radio

    -- The table structure of callsign is a bit awkward. We need to get the airbase name.
    -- Note that unfortunately, the callsign does not always correspond to the airbase name.
    if false then
      local cs=radio.callsign[1]
      if cs and cs.common then
        radio.name=cs.common[1]
      elseif cs and cs.nato then
        radio.name=cs.nato[1]
      else
        radio.name="Unknown"
      end
      radio.name=self:_GetAirbaseName(airbasenames, radio.name)    
      radio.airbase=AIRBASE:FindByName(radio.name)
    end
    
    -- Each radio item has a key radioId = 'airfield106_0', where 106 is the UID of the airbase.
    -- So we can use that to get the airbase.
    local aid = tonumber(string.match(radio.radioId, "airfield(%d+)_"))
    
    -- Get airbase
    radio.airbase=self:_GetAirbaseByID(airdromes, aid)
    
    -- Set other stuff
    if radio.airbase then
      radio.coordinate=radio.airbase:GetCoordinate()
      radio.vec3=radio.airbase:GetVec3()
      radio.name=radio.airbase:GetName()
    end
    
    -- Add to table
    table.insert(self.radios, radio)
  end
  
  -- Debug output
  self:I(string.format("Added %d radios", #self.radios))
  
  return self
end


--- Create a new RADIOS class instance from a given file.
-- @param #RADIOS self
-- @param #string FileName Full path to the file containing the map radios.
-- @return #RADIOS self
function RADIOS:NewFromFile(FileName)

  -- Inherit everything from BASE class.
  self=BASE:Inherit(self, BASE:New()) -- #RADIOS
  
  local exists=UTILS.FileExists(FileName)
  
  if exists==false then
    self:E(string.format("ERROR: file with radios info does not exist! File=%s", tostring(FileName)))
    return nil
  end
  
  -- Backup DCS radio table
  local radiobak=UTILS.DeepCopy(radio)

  -- This will create a global table `radio`  
  dofile(FileName)

  -- Get radios from table.
  self=self:NewFromTable(radio)
  
  -- Restore DCS radio table
  radio=UTILS.DeepCopy(radiobak)
  
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get 3D position vector of a specific radio.
-- @param #RADIOS self
-- @param #RADIOS.Radio radio The radio data structure.
-- @return DCS#Vec3 Position vector.
function RADIOS:GetVec3(radio)
  return radio.vec3
end

--- Get COORDINATE of a specific radio.
-- @param #RADIOS self
-- @param #RADIOS.Radio radio The radio data structure.
-- @return Core.Point#COORDINATE The coordinate.
function RADIOS:GetCoordinate(radio)
  return radio.coordinate
end


--- Find closest radio to a given coordinate.
-- @param #RADIOS self
-- @param Core.Point#COORDINATE Coordinate The reference coordinate.
-- @param #number DistMax (Optional) Max search distance in meters.
-- @param #table ExcludeList (Optional) List of radios to exclude.
-- @return #RADIOS.Radio The closest radio.
function RADIOS:GetClosestRadio(Coordinate, DistMax, ExcludeList)

  local radio=nil --#RADIOS.Radio
  local distmin=math.huge
  
  ExcludeList=ExcludeList or {}
  
  for _,_radio in pairs(self.radios) do
    local ra=_radio --#RADIOS.Radio
    
    if (not UTILS.IsInTable(ExcludeList, ra, "radioId")) then
    
      local dist=Coordinate:Get2DDistance(ra.coordinate)
      
      if dist<distmin and (DistMax==nil or dist<=DistMax) then
        distmin=dist
        radio=ra
      end
      
    end
    
  end  
  
  return radio
end

--- Find closest radios to a given coordinate.
-- @param #RADIOS self
-- @param Core.Point#COORDINATE Coordinate The reference coordinate.
-- @param #number Nmax Max number of radios. Default 5.
-- @param #number DistMax (Optional) Max search distance in meters.
-- @return #table Table of #RADIOS.Radio closest radios.
function RADIOS:GetClosestRadios(Coordinate, Nmax, DistMax)

    Nmax=Nmax or 5
    
    local closest={}
    for i=1,Nmax do
    
      local radio=self:GetClosestRadio(Coordinate, DistMax, closest)
      
      if radio then
        table.insert(closest, radio)
      else
        break
      end
      
    end

  return closest
end


--- Add markers for all radios on the F10 map.
-- @param #RADIOS self
-- @param #RADIOS.Radio Radio (Optional) Only this specifc radio.
-- @return #RADIOS self
function RADIOS:MarkerShow(Radio)

  for _,_radio in pairs(self.radios) do
    local radio=_radio --#RADIOS.Radio
    if Radio==nil or Radio.radioId==radio.radioId then
      local coord=self:GetCoordinate(radio)
      if coord then
        local text=self:_GetMarkerText(radio)
        if radio.markerID then
          UTILS.RemoveMark(radio.markerID)
        end
        radio.markerID=coord:MarkToAll(text)
      end
    end
  end

  return self
end

--- Remove markers of all radios from the F10 map.
-- @param #RADIOS self
-- @param #RADIOS.Radio Radio (Optional) Only this specifc radio.
-- @return #RADIOS self
function RADIOS:MarkerRemove(Radio)

  for _,_radio in pairs(self.radios) do
    local radio=_radio --#RADIOS.Radio
    if Radio==nil or Radio.radioId==radio.radioId then    
      if radio.markerID then
        UTILS.RemoveMark(radio.markerID)
        radio.markerID=nil
      end
    end
  end

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get text displayed in the F10 marker.
-- @param #RADIOS self
-- @param #RADIOS.Radio radio The radio data structure.
-- @return #string Marker text.
function RADIOS:_GetMarkerText(radio)

  local text=string.format("Radio %s", tostring(radio.name))
  for b,f in pairs(radio.frequency) do
    local frequency=f --#RADIOS.Frequency
    local mod=frequency[1]
    local fre=frequency[2]
    local freq, funit=self:_GetFrequency(fre)
    --UTILS.PrintTableToLog(frequency)
    local band=self:_GetBandName(b)
    text=text..string.format("\n%s: %.3f %s", band, freq, funit)
  end
    
  return text
end


--- Get converted frequency.
-- @param #RADIOS self
-- @param #number freq Frequency in Hz.
-- @return #number Frequency in better unit.
-- @return #string Unit ("Hz", "kHz", "MHz").
function RADIOS:_GetFrequency(freq)

  freq=freq or 0
  local unit="Hz"
  
  if freq>=1e6 then
    freq=freq/1e6
    unit="MHz"
  elseif freq>=1e3 then
    freq=freq/1e3
    unit="kHz"
  end

  return freq, unit
end

--- Get name of frequency band.
-- @param #RADIOS self
-- @param #number BandNumber Band as number.
-- @return #string Band name.
function RADIOS:_GetBandName(BandNumber)

  if BandNumber~=nil then  
    for bandName,bandNumber in pairs(ENUMS.FrequencyBand) do
      if bandNumber==BandNumber then
        return bandName
      end  
    end
  end

  return "Unknown"
end

--- Get name of frequency band.
-- @param #RADIOS self
-- @param #table airbasenames Names of all airbases.
-- @param #string name Name of airbase.
-- @return #string Name of airbase
function RADIOS:_GetAirbaseName(airbasenames, name)

  local airbase=AIRBASE:FindByName(name)
  
  if airbase then
    return name    
  else
    for _,airbasename in pairs(airbasenames) do
      if string.find(airbasename, name) then
        return airbasename
      end    
    end
  end

  return "Unknown"
end

--- Get name of frequency band.
-- @param #RADIOS self
-- @param #table airbases Table of airbases.
-- @param #number aid Airbase ID.
-- @return Wrapper.Airbase#AIRBASE Airbase matching the ID or nil.
function RADIOS:_GetAirbaseByID(airbases, aid)

  for _,_airbase in pairs(airbases) do
    local airbase=_airbase --Wrapper.Airbase#AIRBASE
    local id=airbase:GetID(true)
    if id==aid then
      return airbase
    end
  end

  return nil
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
