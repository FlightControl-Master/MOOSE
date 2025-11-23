--- **NAVIGATION** - Beacons of the map/theatre.
--
-- **Main Features:**
--
--    * Access beacons of the map
--    * Find closest beacon
--    * Get frequencies and channels
-- 
-- ===
--
-- ## Example Missions:
--
-- Demo missions can be found on [github](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/develop/Navigation%20-%20Beacons).
-- 
-- ===
--
-- ### Author: **funkyfranky**
-- 
-- ===
-- @module Navigation.Beacons
-- @image MOOSE.JPG

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- BEACONS class.
-- @type BEACONS
-- 
-- @field #string ClassName Name of the class.
-- @field #number verbose Verbosity of output.
-- @field #table beacons Beacons.
-- 
-- @extends Core.Base#BASE

--- *Hope is the beacon that guides lost ships back to the shore.*
--
-- ===
--
-- # The BEACONS Concept
--
-- This class is designed to make information about beacons of a map/theatre easier accessible. The information contains location, type and frequencies of all or specific beacons of the map.
-- 
-- **Note** that try to avoid hard coding stuff in Moose since DCS is updated frequently and things change. Therefore, the main source of information is either a file `beacons.lua` that can be
-- found in the installation directory of DCS for each map or a table that the user needs to provide.
-- **Note** your `MissionScripting` environment needs to be desanitized to read this data. `Package` als needs to be available.
-- 
-- # Basic Setup
-- 
-- A new `BEACONS` object can be created with the @{#BEACONS.NewFromFile}(*beacons_lua_file*) function.
-- 
--     local beacons=BEACONS:NewFromFile("<DCS_Install_Directory>\Mods\terrains\<Map_Name>\beacons.lua")
--     beacons:MarkerShow()
-- 
-- This will load the beacons from the `<DCS_Install_Directory>` for the specific map and place markers on the F10 map. This is the first step you should do to ensure that the file
-- you provided is correct and all relevant beacons are present.
-- 
-- # User Functions
-- 
-- ## F10 Map Markers
-- 
-- ## Position
-- 
-- ## Get Closest Beacon
-- 
--
-- @field #BEACONS
BEACONS = {
  ClassName  = "BEACONS",
  verbose    =         1,
  beacons    =        {},
}

--- Mission capability.
-- @type BEACONS.Beacon
-- @field #function display_name Function that returns the localized name.
-- @field #number type Beacon type.
-- @field #string beaconId Beacon ID.
-- @field #string callsign Call sign.
-- @field #number frequency Frequency in Hz.
-- @field #number channel TACAN, RSBN or PRMG channel depending on type.
-- @field #table position Position table.
-- @field #number direction Direction in degrees.
-- @field #table positionGeo Table with latitude and longitude.
-- @field #table sceneObjects Table with scenery objects, e.g. `{t:393396742}`.
-- @field #number chartOffsetX No idea what this offset is?!
-- @field DCS#Vec3 vec3 Position vector 3D.
-- @field #number markerID ID for the F10 marker.
-- @field #string typeName Name of becon type.
-- @field Wrapper.Scenery#SCENERY scenery The scenery object.

--- BEACONS class version.
-- @field #string version
BEACONS.version="0.1.0"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ToDo list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: A lot...
-- DONE: TACAN channel from frequency (was already in beacon.lua as channel)
-- DONE: Scenery object

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor(s)
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new BEACONS class instance from a given table.
-- @param #BEACONS self
-- @param #table BeaconTable Table with beacon info.
-- @return #BEACONS self
function BEACONS:NewFromTable(BeaconTable)

  -- Inherit everything from BASE class.
  self=BASE:Inherit(self, BASE:New()) -- #BEACONS
  
  for _,_beacon in pairs(BeaconTable) do
    local beacon=_beacon --#BEACONS.Beacon
    
    -- Get 3D vector
    beacon.vec3={x=beacon.position[1], y=beacon.position[2], z=beacon.position[3]}
    
    -- Get coordinate
    beacon.coordinate=COORDINATE:NewFromVec3(beacon.vec3)
    
    -- Get type name
    beacon.typeName=self:_GetTypeName(beacon.type)
    
    -- Find closest scenery object from scan
    beacon.scenery=beacon.coordinate:FindClosestScenery(20)
    
    -- Debug stuff for scenery object
    if false then
      if beacon.scenery then
        env.info(string.format("FF Beacon %s %s %s got scenery object %s, %s", beacon.callsign, beacon.beaconId, beacon.typeName, beacon.scenery:GetName(), beacon.scenery:GetTypeName() ))
        UTILS.PrintTableToLog(beacon.scenery.SceneryObject)
        UTILS.PrintTableToLog(beacon.sceneObjects)
      else
        env.info(string.format("FF NO scenery object  %s %s %s ", beacon.callsign, beacon.beaconId, beacon.typeName))
      end
    end
    
    -- Add to table
    table.insert(self.beacons, beacon)
  end
  
  -- Debug output
  self:I(string.format("Added %d beacons", #self.beacons))
  
  if self.verbose > 0 then
    local text="Beacon types:"
    for typeName,typeID in pairs(BEACON.Type) do
      local n=self:CountBeacons(typeID)
      text=text..string.format("\n%s = %d", typeName, n)      
    end
    self:I(text)
  end
  
  return self
end


--- Create a new BEACONS class instance from a given file.
-- @param #BEACONS self
-- @param #string FileName Full path to the file containing the map beacons.
-- @return #BEACONS self
function BEACONS:NewFromFile(FileName)

  -- Inherit everything from BASE class.
  self=BASE:Inherit(self, BASE:New()) -- #BEACONS
  
  local exists=UTILS.FileExists(FileName)
  
  if exists==false then
    self:E(string.format("ERROR: file with beacon info does not exist!"))
    return nil
  end

  -- This will create a global table `beacons`  
  dofile(FileName)

  -- Get beacons from table.
  self=self:NewFromTable(beacons)
  
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get 3D position vector of a specific beacon.
-- @param #BEACONS self
-- @param #BEACONS.Beacon beacon The beacon data structure.
-- @return DCS#Vec3 Position vector.
function BEACONS:GetVec3(beacon)
  return beacon.vec3
end

--- Get COORDINATE of a specific beacon.
-- @param #BEACONS self
-- @param #BEACONS.Beacon beacon The beacon data structure.
-- @return Core.Point#COORDINATE The coordinate.
function BEACONS:GetCoordinate(beacon)
  local coordinate=COORDINATE:NewFromVec3(beacon.vec3)
  return coordinate
end

--- Find closest beacon to a given coordinate.
-- @param #BEACONS self
-- @param Core.Point#COORDINATE Coordinate The reference coordinate.
-- @param #number TypeID (Optional) Only search for specific beacon types, *e.g.* `BEACON.Type.TACAN`.
-- @param #number DistMax (Optional) Max search distance in meters.
-- @param #table ExcludeList (Optional) List of beacons to exclude.
-- @return #BEACONS.Beacon The closest beacon.
function BEACONS:GetClosestBeacon(Coordinate, TypeID, DistMax, ExcludeList)

  local beacon=nil --#BEACONS.Beacon
  local distmin=math.huge
  
  ExcludeList=ExcludeList or {}
  
  for _,_beacon in pairs(self.beacons) do
    local bc=_beacon --#BEACONS.Beacon
    
    if (TypeID==nil or TypeID==bc.type) and (not UTILS.IsInTable(ExcludeList, bc, "beaconId")) then
    
      local dist=Coordinate:Get2DDistance(bc.vec3)
      
      if dist<distmin and (DistMax==nil or dist<=DistMax) then
        distmin=dist
        beacon=bc
      end
      
    end
    
  end  
  
  return beacon
end

--- Find closest beacons to a given coordinate.
-- @param #BEACONS self
-- @param Core.Point#COORDINATE Coordinate The reference coordinate.
-- @param #number Nmax Max number of beacons. Default 5.
-- @param #number TypeID (Optional) Only search for specific beacon types, *e.g.* `BEACON.Type.TACAN`.
-- @param #number DistMax (Optional) Max search distance in meters.
-- @return #table Table of #BEACONS.Beacon closest beacons.
function BEACONS:GetClosestBeacons(Coordinate, Nmax, TypeID, DistMax)

    Nmax=Nmax or 5
    
    local closest={}
    for i=1,Nmax do
    
      local beacon=self:GetClosestBeacon(Coordinate, TypeID, DistMax, closest)
      
      if beacon then
        table.insert(closest, beacon)
      else
        break
      end
      
    end

  return closest
end

--- Get table of all beacons, optionally of a given type.
-- @param #BEACONS self
-- @param #number TypeID (Optional) Only return specific beacon types, *e.g.* `BEACON.Type.TACAN`. Can be handed in as tanle of beacon types.
-- @return #table Table of beacons. Each element is of type #BEACON.Beacon.
function BEACONS:GetBeacons(TypeID)

  local beacons={}
  local keys = {}
  
  if TypeID~=nil and type(TypeID) ~= "table" then 
    TypeID = {TypeID}
  end
  
  for _,_typeid in pairs(TypeID or {}) do
    if _typeid ~= nil then
      keys[_typeid] = _typeid
    end
  end

  for _,_beacon in pairs(self.beacons) do
    local bc=_beacon --#BEACONS.Beacon
    
    if TypeID==nil or keys[bc.type] ~= nil then
      table.insert(beacons, bc)
    end
    
  end  

  return beacons
end

--- Count beacons, optionally of a given type.
-- @param #BEACONS self
-- @param #number TypeID (Optional) Only count specific beacon types, *e.g.* `BEACON.Type.TACAN`.
-- @return #number Number of beacons.
function BEACONS:CountBeacons(TypeID)

  local n=0
  
  if TypeID then
    for _,_beacon in pairs(self.beacons) do
      local bc=_beacon --#BEACONS.Beacon
      
      if TypeID==bc.type then
        n=n+1
      end 
    end
  else
    n=#self.beacons
  end

  return n
end

--- Add markers for all beacons on the F10 map. Optionally, only a specific beacon or a certain beacon type can be marked.
-- @param #BEACONS self
-- @param #BEACONS.Beacon Beacon (Optional) Only this specifc beacon.
-- @param #number TypeID (Optional) Only show specific beacon types, *e.g.* `BEACON.Type.TACAN`.
-- @return #BEACONS self
function BEACONS:MarkerShow(Beacon, TypeID)

  for _,_beacon in pairs(self.beacons) do
    local beacon=_beacon --#BEACONS.Beacon
    if Beacon==nil or Beacon.beaconId==beacon.beaconId then
      if TypeID==nil or beacon.type==TypeID then
        local text=self:_GetMarkerText(beacon)
        local coord=COORDINATE:NewFromVec3(beacon.vec3)
        if beacon.markerID then
          UTILS.RemoveMark(beacon.markerID)
        end
        beacon.markerID=coord:MarkToAll(text)
      end
    end
  end

  return self
end

--- Remove markers of all beacons from the F10 map. Optionally, remove only marker of a specific beacon or a certain beacon type.
-- @param #BEACONS self
-- @param #BEACONS.Beacon Beacon (Optional) Only this specifc beacon.
-- @param #number TypeID (Optional) Only show specific beacon types, *e.g.* `BEACON.Type.TACAN`.
-- @return #BEACONS self
function BEACONS:MarkerRemove(Beacon, TypeID)

  for _,_beacon in pairs(self.beacons) do
    local beacon=_beacon --#BEACONS.Beacon
    if Beacon==nil or Beacon.beaconId==beacon.beaconId then    
      if TypeID==nil or beacon.type==TypeID then    
        if beacon.markerID then
          UTILS.RemoveMark(beacon.markerID)
          beacon.markerID=nil
        end
      end
    end
  end

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get text displayed in the F10 marker.
-- @param #BEACONS self
-- @param #BEACONS.Beacon beacon The beacon data structure.
-- @return #string Marker text.
function BEACONS:_GetMarkerText(beacon)

  local frequency, funit=self:_GetFrequency(beacon.frequency)
  local direction=beacon.direction~=nil and beacon.direction or -1

  local text=string.format("Beacon %s [ID=%s]", tostring(beacon.typeName), tostring(beacon.beaconId))  
  text=text..string.format("\nCallsign: %s", tostring(beacon.callsign))
  if UTILS.IsInTable({BEACON.Type.TACAN, BEACON.Type.RSBN, BEACON.Type.PRMG_GLIDESLOPE, BEACON.Type.PRMG_LOCALIZER}, beacon.type) then
    text=text..string.format("\nChannel: %s", tostring(beacon.channel))
  end
  text=text..string.format("\nFrequency: %.3f %s", frequency, funit)
  text=text..string.format("\nDirection: %.1f°", direction)
  
  return text
end


--- Get converted frequency.
-- @param #BEACONS self
-- @param #number freq Frequency in Hz.
-- @return #number Frequency in better unit.
-- @return #string Unit ("Hz", "kHz", "MHz").
function BEACONS:_GetFrequency(freq)

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

--- Get name of beacon type.
-- @param #BEACONS self
-- @param #number typeID Beacon type number.
-- @return #string Type name.
function BEACONS:_GetTypeName(typeID)

  if typeID~=nil then  
    for typeName,_typeID in pairs(BEACON.Type) do
      if _typeID==typeID then
        return typeName
      end  
    end
  end

  return "Unknown"
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
