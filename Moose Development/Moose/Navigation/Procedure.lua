--- **NAVIGATION** - Prodedures for Departure (SID), Arrival (STAR) and Approach.
--
-- **Main Features:**
--
--    * Stuff
--    * More Stuff
-- 
-- ===
--
-- ## Example Missions:
--
-- Demo missions can be found on [github](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/develop/Navigation%20-%20Template).
-- 
-- ===
--
-- ### Author: **funkyfranky**
-- 
-- ===
-- @module Navigation.Procedure
-- @image NAVIGATION_Procedure.png


--- APPROACH class.
-- @type APPROACH
-- @field #string ClassName Name of the class.
-- @field #number verbose Verbosity of output.
-- @field #string apptype Approach type (ILS, VOR, LOC).
-- @field Wrapper.Airbase#AIRBASE airbase Airbase of this approach.
-- @field Wrapper.Airbase#AIRBASE.Runway runway Runway of this approach.
-- @field #number wpcounter Running number counting the waypoints to generate its UID.
-- @list <#APPROACH.Waypoint> path Path of approach consisting of waypoints.
-- @extends Core.Base#BASE

--- *A fleet of British ships at war are the best negotiators.* -- Horatio Nelson
--
-- ===
--
-- # The APPROACH Concept
-- 
-- A typical approach has (up to) four segments. It starts with the initial approach segment, followed by the intermediate approach segment, followed
-- by the final approach segment. In case something goes wrong during the final approach, the missed approach segment kicks in. 
-- 
-- The initial approach segment starts at the initial approach fix (IAF). The segment can contain multiple other fixes, that need to be passed.
-- Note, that an approach procedure can have more than one intitial approach segment and IAF.
-- 
-- The intermediate approach segment starts at the intermediate fix (IF). The intermediate approach segment blends the initial approach segment into the final approach segment. 
-- It is the segment in which aircraft configuration, speed, and positioning adjustments are made for entry into the final approach segment.
-- 
-- 
-- https://en.wikipedia.org/wiki/Visual_approach
-- https://en.wikipedia.org/wiki/Instrument_approach
-- 
-- # Basic Setup
-- 
-- A new `APPROACH` object can be created with the @{#APPROACH.New}() function.
-- 
--     myTemplate=APPROACH:New()
--     myTemplate:SetXYZ(X, Y, Z)
--     
-- This is how it works.
--
-- @field #APPROACH
APPROACH = {
  ClassName       = "APPROACH",
  verbose         =       0,
  wpcounter       =       0,
}

--- Type of approach.
-- @type APPROACH.Type
-- @field #string VOR VOR
-- @field #string NDB NDB
APPROACH.Type={
  VOR="VOR",
  ILS="ILS",
}


--- Setments of  approach.
-- @type APPROACH.Segment
-- @field #string INITIAL Initial approach segment.
-- @field #string INTERMEDIATE Intermediate approach segment.
-- @field #string FINAL Final approach segment.
-- @field #string MISSED Missed approach segment.
APPROACH.Segment={
  INITIAL="Initial",
  INTERMEDIATE="Intermediate",
  FINAL="Final",
  MISSED="Missed",
}
 
--- Waypoint of the approach.
-- @type APPROACH.Waypoint
-- @field #number uid Unique ID of the point.
-- @field #string segment The segment this point belongs to.
-- @field Navigation.NavFix#NAVFIX navfix The navigation fix that determines the coordinates of this point.
  
--- APPROACH class version.
-- @field #string version
APPROACH.version="0.0.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ToDo list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: A lot...
-- Initial approach segment --> Intermediate approach segment: starts at IF --> Final approach segment

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new APPROACH class instance.
-- @param #APPROACH self
-- @param #string Type Type of approach (ILS, VOR, LOC).
-- @param Wrapper.Airbase#AIRBASE Airbase The airbase or name of the airbase.
-- @param Wrapper.Airbase#AIRBASE.Runway Runway The runway or name of the runway.
-- @return #APPROACH self
function APPROACH:New(Type, Airbase, Runway)

  -- Inherit everything from BASE class.
  self=BASE:Inherit(self, BASE:New()) -- #APPROACH
  
  self.apptype=Type
  
  self.airbase=Airbase
  
  self.runway=Runway

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set the primary navigation aid used in the approach.
-- @param #APPROACH self
-- @param Navigation.NavAid#NAVAID NavAid The NAVAID.
-- @return #APPROACH self
function APPROACH:SetNavAid(NavAid)

  self.navaid=NavAid

  return self
end

--- Add a waypoint to the path of the approach.
-- @param #APPROACH self
-- @param Navigation.NavAid#NAVAID NavAid The NAVAID.
-- @param #string Segment The approach segment this fix belongs to.
-- @return #APPROACH self
function APPROACH:AddWaypoint(NavFix, Segment)

  self.wpcounter=self.wpcounter+1

  local point={} --#APPROACH.Waypoint
  point.uid=self.wpcounter
  point.segment=Segment
  point.navfix=NavFix

  table.insert(self.path, point)

  return point
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
