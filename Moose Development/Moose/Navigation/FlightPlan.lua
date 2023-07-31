--- **NAVIGATION** - Flight Plan.
--
-- **Main Features:**
--
--    * Manage navigation aids
--    * VOR, NDB
-- 
-- ===
--
-- ## Example Missions:
--
-- Demo missions can be found on [github](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/develop/Ops%20-%20FlightPlan).
-- 
-- ===
--
-- ### Author: **funkyfranky**
-- 
-- ===
-- @module Navigation.FlightPlan
-- @image NAVIGATION_FlightPlan.png


--- FLIGHTPLAN class.
-- @type FLIGHTPLAN
-- @field #string ClassName Name of the class.
-- @field #number verbose Verbosity of output.
-- @extends Core.Base#BASE

--- *A fleet of British ships at war are the best negotiators.* -- Horatio Nelson
--
-- ===
--
-- # The FLIGHTPLAN Concept
--
-- A FLIGHTPLAN consists of one or multiple FLOTILLAs. These flotillas "live" in a WAREHOUSE that has a phyiscal struction (STATIC or UNIT) and can be captured or destroyed.
-- 
-- # Basic Setup
-- 
-- A new `FLIGHTPLAN` object can be created with the @{#FLIGHTPLAN.New}(`WarehouseName`, `FleetName`) function, where `WarehouseName` is the name of the static or unit object hosting the fleet
-- and `FleetName` is the name you want to give the fleet. This must be *unique*!
-- 
--     myFleet=FLIGHTPLAN:New("myWarehouseName", "1st Fleet")
--     myFleet:SetPortZone(ZonePort1stFleet)
--     myFleet:Start()
--     
-- A fleet needs a *port zone*, which is set via the @{#FLIGHTPLAN.SetPortZone}(`PortZone`) function. This is the zone where the naval assets are spawned and return to.
-- 
-- Finally, the fleet needs to be started using the @{#FLIGHTPLAN.Start}() function. If the fleet is not started, it will not process any requests.
--
-- @field #FLIGHTPLAN
FLIGHTPLAN = {
  ClassName       = "FLIGHTPLAN",
  verbose         =       0,
}

--- Type of navaid
-- @type FLIGHTPLAN.Type
-- @field #string VOR VOR
-- @field #string NDB NDB
FLIGHTPLAN.TYPE={
  VOR="VOR",
  NDB="NDB",
}
  
--- FLIGHTPLAN class version.
-- @field #string version
FLIGHTPLAN.version="0.0.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ToDo list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: A lot...
-- TODO: How to handle the FLIGHTGROUP:_LandAtAirBase
-- TODO: Do we always need a holding pattern? https://www.faa.gov/air_traffic/publications/atpubs/aip_html/part2_enr_section_1.5.html#:~:text=If%20no%20holding%20pattern%20is,than%20that%20desired%20by%20ATC.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new FLIGHTPLAN class instance.
-- @param #FLIGHTPLAN self
-- @param #string ZoneName Name of the zone to scan the scenery.
-- @param #string SceneryName Name of the scenery object.
-- @param #string Type Type of Navaid.
-- @return #FLIGHTPLAN self
function FLIGHTPLAN:New(Name)

  -- Inherit everything from SCENERY class.
  self=BASE:Inherit(self, BASE:New()) -- #FLIGHTPLAN

  -- Set alias.
  self.alias=tostring(Name)
  
  -- Set some string id for output to DCS.log file.
  self.lid=string.format("FLIGHTPLAN %s | ", self.alias)
  
  -- Debug info.
  self:I(self.lid..string.format("Created FLIGHTPLAN!"))

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set frequency.
-- @param #FLIGHTPLAN self
-- @param #number Frequency Frequency in Hz.
-- @return #FLIGHTPLAN self
function FLIGHTPLAN:SetFrequency(Frequency)

  self.frequency=Frequency

  return self
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
