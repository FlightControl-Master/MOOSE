--- **NAVIGATION** - Airbase radios.
--
-- **Main Features:**
--
--    * Get radio frequencies of airbases
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
-- @image NAVIGATION_Radios.png

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
-- This class is desinged to make information about radios of a map/theatre easier accessible. The information contains mostly the frequencies of airbases of the map.
-- 
-- **Note** that try to avoid hard coding stuff in Moose since DCS is updated frequently and things change. Therefore, the main source of information is either a file `radio.lua` that can be
-- found in the installation directory of DCS for each map or a table that the user needs to provide.
-- 
-- # Basic Setup
-- 
-- A new `RADIOS` object can be created with the @{#RADIOS.NewFromFile}(*radio_lua_file*) function.
-- 
--     local radios=RADIOS:NewFromFile("<DCS_Install_Directory>\Mods\terrains\<Map_Name>\radios.lua")
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
  verbose    =         0,
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

--- Radio item data structure.
-- @type RADIOS.Frequency
-- @field #number modu Modulation type.
-- @field #number freq Frequency in Hz.


--- RADIOS class version.
-- @field #string version
RADIOS.version="0.0.0"

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
  
  local airbasenames=AIRBASE.GetAllAirbaseNames()
  
  for _,_radio in pairs(RadioTable) do
    local radio=_radio --#RADIOS.Radio
    
    --UTILS.PrintTableToLog(radio)
    --UTILS.PrintTableToLog(radio.callsign)
    
    -- The table structure of callsign is a bit awkward. We need to get the airbase name.
    local cs=radio.callsign[1]
    if cs and cs.common then
      radio.name=cs.common[1]
    elseif cs and cs.nato then
      radio.name=cs.nato[1]
    else
      radio.name="Unknown"
    end
    
    --UTILS.PrintTableToLog(radio.callsign)
    
    radio.name=self:_GetAirbaseName(airbasenames, radio.name)
    
    radio.airbase=AIRBASE:FindByName(radio.name)
    
    if radio.airbase then
      radio.coordinate=radio.airbase:GetCoordinate()
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

  -- This will create a global table `radio`  
  dofile(FileName)

  -- Get radios from table.
  self=self:NewFromTable(radio)
  
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

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
