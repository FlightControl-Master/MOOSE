--- **NAVIGATION** - Beacons of the map/theatre.
--
-- **Main Features:**
--
--    * Find towns of map
--    * Road and rail connections
-- 
-- ===
--
-- ## Example Missions:
--
-- Demo missions can be found on [github](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/develop/Navigation%20-%20Towns).
-- 
-- ===
--
-- ### Author: **funkyfranky**
-- 
-- ===
-- @module Navigation.Towns
-- @image NAVIGATION_Towns.png

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- TOWNS class.
-- @type TOWNS
-- 
-- @field #string ClassName Name of the class.
-- @field #number verbose Verbosity of output.
-- @field #table towns Towns.
-- 
-- @extends Core.Base#BASE

--- *Hope is the beacon that guides lost ships back to the shore.*
--
-- ===
--
-- # The TOWNS Concept
--
-- This class is desinged to make information about towns of a map/theatre easier accessible. The information contains location and road/rail connections of the towns.
-- 
-- **Note** that try to avoid hard coding stuff in Moose since DCS is updated frequently and things change. Therefore, the main source of information is either a file `towns.lua` that can be
-- found in the installation directory of DCS for each map or a table that the user needs to provide.
-- 
-- # Basic Setup
-- 
-- A new `TOWNS` object can be created with the @{#TOWNS.NewFromFile}(*towns_lua_file*) function.
-- 
--     local towns=TOWNS:NewFromFile("<DCS_Install_Directory>\Mods\terrains\<Map_Name>\towns.lua")
--     towns:MarkerShow()
-- 
-- This will load the towns from the `<DCS_Install_Directory>` for the specific map and place markers on the F10 map. This is the first step you should do to ensure that the file
-- you provided is correct and all relevant towns are present.
-- 
-- # User Functions
-- 
-- ## F10 Map Markers
-- 
-- ## Position
-- 
-- ## Get Closest Town
-- 
--
-- @field #TOWNS
TOWNS = {
  ClassName  =   "TOWNS",
  verbose    =         0,
  towns      =        {},
}

--- Town data.
-- @type TOWNS.Town
-- @field #string display_name Displayed name.
-- @field #string name Name of the town.
-- @field #number latitude Latitude.
-- @field #number longitude Longitude
-- @field DCS#Vec3 vec3 Position vector 3D.
-- @field Core.Point#COORDINATE coordinate The coordinate.
-- @field Core.Point#COORDINATE coordRoad The coordinate of the closest road.
-- @field Core.Point#COORDINATE coordRail The coordinate of the closest railway.
-- @field #number markerID ID for the F10 marker.

--- TOWNS class version.
-- @field #string version
TOWNS.version="0.0.0"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ToDo list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: A lot...
-- TODO: Road connection
-- TODO: Rail connection

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor(s)
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new TOWNS class instance from a given table.
-- @param #TOWNS self
-- @param #table TownTable Table with all towns data.
-- @return #TOWNS self
function TOWNS:NewFromTable(TownTable)

  -- Inherit everything from BASE class.
  self=BASE:Inherit(self, BASE:New()) -- #TOWNS
  
  for TownName,_town in pairs(TownTable) do
    local town=_town --#TOWNS.Town
    
    town.name=TownName    

    -- Get coordinate
    town.coordinate=COORDINATE:NewFromLLDD(town.latitude, town.longitude)
    
    -- Add to table
    table.insert(self.towns, town)
  end
  
  -- Debug output
  self:I(string.format("Added %d towns", #self.towns))
  
  return self
end


--- Create a new TOWNS class instance from a given file.
-- @param #TOWNS self
-- @param #string FileName Full path to the file containing the towns data.
-- @return #TOWNS self
function TOWNS:NewFromFile(FileName)

  -- Inherit everything from BASE class.
  self=BASE:Inherit(self, BASE:New()) -- #TOWNS
  
  local exists=UTILS.FileExists(FileName)
  
  if exists==false then
    self:E(string.format("ERROR: file with towns info does not exist!"))
    return nil
  end

  -- This will create a global table `towns`  
  dofile(FileName)

  -- Get towns from table.
  self=self:NewFromTable(towns)
  
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get 3D position vector of a specific town.
-- @param #TOWNS self
-- @param #TOWNS.Town town The town data structure.
-- @return DCS#Vec3 Position vector.
function TOWNS:GetVec3(town)
  return town.vec3
end

--- Get COORDINATE of a specific town.
-- @param #TOWNS self
-- @param #TOWNS.Town town The town data structure.
-- @return Core.Point#COORDINATE The coordinate.
function TOWNS:GetCoordinate(town)
  return town.coordinate
end

--- Find closest town to a given coordinate.
-- @param #TOWNS self
-- @param Core.Point#COORDINATE Coordinate The reference coordinate.
-- @return #TOWNS.Town The closest town.
function TOWNS:GetClosestTown(Coordinate)

  local Town=nil --#TOWNS.Town
  local distmin=math.huge
  
  for _,_town in pairs(self.towns) do
    local town=_town --#TOWNS.Town
    
    local dist=Coordinate:Get2DDistance(bc.coordinate)
    
    if dist<distmin then
      distmin=dist
      Town=town
    end    
  end
  
  return Town
end

--- Get table of all towns, optionally of a given type.
-- @param #TOWNS self
-- @return #table Table of towns. Each element is of type #TOWN.Town.
function TOWNS:GetTowns()
  return self.towns
end

--- Add markers for all towns on the F10 map.
-- @param #TOWNS self
-- @param #TOWNS.Town Town (Optional) Only this specifc town.
-- @return #TOWNS self
function TOWNS:MarkerShow(Town)

  for _,_town in pairs(self.towns) do
    local town=_town --#TOWNS.Town
    if Town==nil or Town.name==Town.name then
      local text=self:_GetMarkerText(Town)
      local coord=town.coordinate
      if town.markerID then
        UTILS.RemoveMark(town.markerID)
      end
      town.markerID=coord:MarkToAll(text)
    end
  end

  return self
end

--- Remove markers of all towns from the F10 map.
-- @param #TOWNS self
-- @param #TOWNS.Town Town (Optional) Only this specifc town.
-- @return #TOWNS self
function TOWNS:MarkerRemove(Town)

  for _,_town in pairs(self.towns) do
    local town=_town --#TOWNS.Town
    if Town==nil or Town.name==town.name then    
      if town.markerID then
        UTILS.RemoveMark(town.markerID)
        town.markerID=nil
      end
    end
  end

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get text displayed in the F10 marker.
-- @param #TOWNS self
-- @param #TOWNS.Town town The town data structure.
-- @return #string Marker text.
function TOWNS:_GetMarkerText(town)

  local text=string.format("Town %s", town.name)  
  --text=text..string.format("\nCallsign: %s", tostring(beacon.callsign))
  
  return text
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
