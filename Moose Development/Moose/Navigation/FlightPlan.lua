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
-- @field #table fixes Navigation fixes.
-- @field Wrapper.Airbase#AIRBASE departureAirbase Departure airbase.
-- @field Wrapper.Airbase#AIRBASE destinationAirbase Destination airbase.
-- @field #number altitudeCruiseMin Minimum cruise altitude in feet MSL.
-- @field #number altitudeCruiseMax Maximum cruise altitude in feet MSL.
-- @extends Core.Base#BASE

--- *Life is what happens to us while we are making other plans.* -- Allen Saunders
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
--     myFlightplan=FLIGHTPLAN:New("Plan A")
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
  fixes           = {}
}

--- Type of  flightplan.
-- @type FLIGHTPLAN.Type
-- @field #string IFRH Instrument Flying Rules High Altitude.
-- @field #string IFRL Instrument Flying Rules Low Altitude.
-- @field #string VFR Visual Flight Rules.
FLIGHTPLAN.Type={
  IFRH="IFR Heigh",
  IFRL="IFR Low",
  VFR="VFR",
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

--- Create a new FLIGHTPLAN instance.
-- @param #FLIGHTPLAN self
-- @param #string Name Name of this flight plan.
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

--- Create a new FLIGHTPLAN instance from another FLIGHTPLAN acting as blue print.
-- The newly created flight plan is deep copied from the given one.
-- @param #FLIGHTPLAN self
-- @param #FLIGHTPLAN FlightPlan Blue print of the flight plan to copy.
-- @return #FLIGHTPLAN self
function FLIGHTPLAN:NewFromFlightPlan(FlightPlan)
  self=UTILS.DeepCopy(FlightPlan)
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Add navigation fix to the flight plan.
-- @param #FLIGHTPLAN self
-- @param Navigation.NavFix#NAVFIX NavFix The nav fix.
-- @return #FLIGHTPLAN self
function FLIGHTPLAN:AddNavFix(NavFix)

  table.insert(self.fixes, NavFix)

  return self
end


--- Set depature airbase.
-- @param #FLIGHTPLAN self
-- @param #string AirbaseName Name of the airbase or AIRBASE object.
-- @return #FLIGHTPLAN self
function FLIGHTPLAN:SetDepartureAirbase(AirbaseName)

  self.departureAirbase=AIRBASE:FindByName(AirbaseName)

  return self
end

--- Set destination airbase.
-- @param #FLIGHTPLAN self
-- @param #string AirbaseName Name of the airbase or AIRBASE object.
-- @return #FLIGHTPLAN self
function FLIGHTPLAN:SetDestinationAirbase(AirbaseName)

  self.destinationAirbase=AIRBASE:FindByName(AirbaseName)

  return self
end


--- Set cruise altitude.
-- @param #FLIGHTPLAN self
-- @param #number AltMin Minimum altitude in feet MSL.
-- @param #number AltMax Maximum altitude in feet MSL. Default is `AltMin`.
-- @return #FLIGHTPLAN self
function FLIGHTPLAN:SetCruiseAltitude(AltMin, AltMax)

  self.altitudeCruiseMin=AltMin
  self.altitudeCruiseMax=AltMax or self.altitudeCruiseMin

  return self
end


--- Get the name of this flight plan.
-- @param #FLIGHTPLAN self
-- @return #string The name.
function FLIGHTPLAN:GetName()
  return self.alias
end


--- Get cruise altitude. This returns a random altitude between the set min/max cruise altitudes.
-- @param #FLIGHTPLAN self
-- @return #number Cruise altitude in feet MSL.
function FLIGHTPLAN:GetCruiseAltitude()

  local alt=10000
  if self.altitudeCruiseMin and self.altitudeCruiseMax then
    alt=math.random(self.altitudeCruiseMin, self.altitudeCruiseMax)
  elseif self.altitudeCruiseMin then
    alt=self.altitudeCruiseMin
  elseif self.altitudeCruiseMax then
    alt=self.altitudeCruiseMax
  end
  
  return alt
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------






-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
