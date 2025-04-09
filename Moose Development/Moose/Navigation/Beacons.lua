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

--- *A fleet of British ships at war are the best negotiators.* -- Horatio Nelson
--
-- ===
--
-- # The BEACONS Concept
--
-- The NAVFIX class has a great concept!
-- 
-- Bla, bla...
-- 
-- # Basic Setup
-- 
-- A new `BEACONS` object can be created with the @{#BEACONS.New}() function.
-- 
--     local beacons=BEACONS:New("G:\Games\DCS World Testing\Mods\terrains\GermanyColdWar\beacons.lua")
--     
-- This is how it works.
--
-- @field #BEACONS
BEACONS = {
  ClassName  = "BEACONS",
  verbose    =         0,
  beacons    =        {},
}

--- BEACONS class version.
-- @field #string version
BEACONS.version="0.0.0"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ToDo list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: A lot...

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor(s)
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new BECAONS class instance from a given file.
-- @param #BEACONS self
-- @param #string FileName Full path to the file containing the map beacons.
-- @return #BEACONS self
function BEACONS:NewFromFile(FileName)

  -- Inherit everything from BASE class.
  self=BASE:Inherit(self, BASE:New()) -- #BEACONS

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Add marker all beacons on the F10 map.
-- @param #BEACONS self
-- @return #BEACONS self
function BEACONS:MarkerShow()

  return self
end

--- Remove markers of all beacons from the F10 map.
-- @param #BEACONS self
-- @return #BEACONS self
function BEACONS:MarkerRemove()

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get text displayed in the F10 marker.
-- @param #BEACONS self
-- @return #string Marker text.
function BEACONS:_GetMarkerText(beacon)

  local altmin=self.altMin and tostring(self.altMin) or ""
  local altmax=self.altMax and tostring(self.altMax) or ""
  local speedmin=self.speedMin and tostring(self.speedMin) or ""
  local speedmax=self.speedMax and tostring(self.speedMax) or ""


  local text=string.format("NAVFIX %s", self.name)
  if self.isIAF then
    text=text..string.format(" (IAF)")
  end
  if self.isIF then
    text=text..string.format(" (IF)")
  end
  text=text..string.format("\nAltitude [ft]: %s - %s", altmin, altmax)
  text=text..string.format("\nSpeed [knots]: %s - %s", speedmin, speedmax)
  text=text..string.format("\nCompulsory: %s", tostring(self.isCompulsory))
  text=text..string.format("\nFly Over: %s", tostring(self.isFlyover))
  
  return text
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
