--- **NAVIGATION** - Beacons of the map/theatre.
--
-- **Main Features:**
--
--    * Beacons of the map
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
-- @image NAVIGATION_Beacons.png

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
-- This class is desinged to make information about beacons of a map/theatre easier accessible. The information contains location, type and frequencies of all or specific beacons of the map.
-- 
-- **Note** that try to avoid hard coding stuff in Moose since DCS is updated frequently and things change. Therefore, the main source of information is either a file `beacons.lua` that can be
-- found in the installation directory of DCS for each map or a table that the user needs to provide.
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
-- ## Get Closest Beacon
-- 
--
-- @field #BEACONS
BEACONS = {
  ClassName  = "BEACONS",
  verbose    =         0,
  beacons    =        {},
}

--- Mission capability.
-- @type BEACONS.Beacon
-- @field #function display_name Function that returns the localized name.
-- @field #number type Beacon type.
-- @field #string beaconId Beacon ID.
-- @field #string callsign Call sign.
-- @field #number frequency Frequency in Hz.
-- @field #table position Position table.
-- @field #number direction Direction in degrees.
-- @field #table positionGeo Table with latitude and longitude.
-- @field #table sceneObjects Table with scenery objects, e.g. `{t:393396742}`.
-- @field #number chartOffsetX No idea what this offset is?!
-- @field DCS#Vec3 vec3 Position vector 3D.
-- @field #number markerID ID for the F10 marker.

--- BEACONS class version.
-- @field #string version
BEACONS.version="0.0.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ToDo list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: A lot...
-- TODO: TACAN channel from frequency
-- TODO: Scenery object

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor(s)
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new BECAONS class instance from a given table.
-- @param #BEACONS self
-- @param #table BeaconTable Table with beacon info.
-- @return #BEACONS self
function BEACONS:NewFromTable(BeaconTable)

  -- Inherit everything from BASE class.
  self=BASE:Inherit(self, BASE:New()) -- #BEACONS
  
  for _,_beacon in pairs(BeaconTable) do
    local beacon=_beacon --#BEACONS.Beacon
    
    beacon.vec3={x=beacon.position[1], y=beacon.position[2], z=beacon.position[3]}
    
    table.insert(self.beacons, beacon)
  end
  
  self:I(string.format("Added %d beacons", #self.beacons))
  
  
  return self
end


--- Create a new BECAONS class instance from a given file.
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
-- @return #BEACONS.Beacon The closest beacon.
function BEACONS:GetClosestBeacon(Coordinate, TypeID)

  local beacon=nil --#BEACONS.Beacon
  local distmin=math.huge
  
  for _,_beacon in pairs(self.beacons) do
    local bc=_beacon --#BEACONS.Beacon
    
    if TypeID==nil or TypeID==bc.type then
    
      local dist=Coordinate:Get2DDistance(bc.vec3)
      
      if dist<distmin then
        distmin=dist
        beacon=bc
      end
      
    end
    
  end  
  
  return beacon
end

--- Get table of all beacons, optionally of a given type.
-- @param #BEACONS self
-- @param #number TypeID (Optional) Only return specific beacon types, *e.g.* `BEACON.Type.TACAN`.
-- @return #table Table of beacons. Each element is of type #BEACON.Beacon.
function BEACONS:GetBeacons(TypeID)
  
  local beacons={}
  
  for _,_beacon in pairs(self.beacons) do
    local bc=_beacon --#BEACONS.Beacon
    
    if TypeID==nil or TypeID==bc.type then
      table.insert(beacons, bc)
    end
    
  end  

  return beacons
end



--- Add markers for all beacons on the F10 map.
-- @param #BEACONS self
-- @param #BEACONS.Beacon Beacon (Optional) Only this specifc beacon.
-- @return #BEACONS self
function BEACONS:MarkerShow(Beacon)

  for _,_beacon in pairs(self.beacons) do
    local beacon=_beacon --#BEACONS.Beacon
    if Beacon==nil or Beacon.beaconId==beacon.beaconId then
      local text=self:_GetMarkerText(beacon)
      local coord=COORDINATE:NewFromVec3(beacon.vec3)
      if beacon.markerID then
        UTILS.RemoveMark(beacon.markerID)
      end
      beacon.markerID=coord:MarkToAll(text)
    end
  end

  return self
end

--- Remove markers of all beacons from the F10 map.
-- @param #BEACONS self
-- @param #BEACONS.Beacon Beacon (Optional) Only this specifc beacon.
-- @return #BEACONS self
function BEACONS:MarkerRemove(Beacon)

  for _,_beacon in pairs(self.beacons) do
    local beacon=_beacon --#BEACONS.Beacon
    if Beacon==nil or Beacon.beaconId==beacon.beaconId then    
      if beacon.markerID then
        UTILS.RemoveMark(beacon.markerID)
        beacon.markerID=nil
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

  local frequency=beacon.frequency~=nil and beacon.frequency/1000 or -1
  local direction=beacon.direction~=nil and beacon.direction or -1

  local text=string.format("Beacon %s", tostring(beacon.beaconId))  
  text=text..string.format("\nCallsign: %s", tostring(beacon.callsign))
  text=text..string.format("\nType: %s", tostring(self:_GetTypeName(beacon.type)))
  text=text..string.format("\nFrequency: %.3f kHz", frequency)
  text=text..string.format("\nDirection: %.1f°", direction)
  
  return text
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
