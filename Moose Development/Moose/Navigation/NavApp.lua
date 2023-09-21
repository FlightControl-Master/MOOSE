--- **NAVIGATION** - Template.
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
-- @module Navigation.Template
-- @image NAVIGATION_Template.png


--- NAVAPP class.
-- @type NAVAPP
-- @field #string ClassName Name of the class.
-- @field #number verbose Verbosity of output.
-- @field #string apptype Approach type (ILS, VOR, LOC).
-- @field Wrapper.Airbase#AIRBASE airbase Airbase of this approach.
-- @field Wrapper.Airbase#AIRBASE.Runway runway Runway of this approach.
-- @field #number wpcounter Running number counting the waypoints to generate its UID.
-- @list <#NAVAPP.Waypoint> path Path of approach consisting of waypoints.
-- @extends Core.Base#BASE

--- *A fleet of British ships at war are the best negotiators.* -- Horatio Nelson
--
-- ===
--
-- # The NAVAPP Concept
--
-- The NAVAPP class has a great concept!
-- 
-- A typical approach has (up to) three segments. It starts with the initial approach segment, followed by the intermediate approach segment, followed
-- by the final approach segment.
-- 
-- The initial approach segment starts at the initial approach fix (IAF). The segment can contain multiple other fixes, that need to be passed.
-- An approach procedure can have more than one segment and IAF.
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
-- A new `NAVAPP` object can be created with the @{#NAVAPP.New}() function.
-- 
--     myTemplate=NAVAPP:New()
--     myTemplate:SetXYZ(X, Y, Z)
--     
-- This is how it works.
--
-- @field #NAVAPP
NAVAPP = {
  ClassName       = "NAVAPP",
  verbose         =       0,
  wpcounter       =       0,
}

--- Type of approach.
-- @type NAVAPP.Type
-- @field #string VOR VOR
-- @field #string NDB NDB
NAVAPP.Type={
  VOR="VOR",
  ILS="ILS",
}


--- Setments of  approach.
-- @type NAVAPP.Segment
-- @field #string INITIAL Initial approach segment.
-- @field #string INTERMEDIATE Intermediate approach segment.
-- @field #string FINAL Final approach segment.
-- @field #string MISSED Missed approach segment.
NAVAPP.Segment={
  INITIAL="Initial",
  INTERMEDIATE="Intermediate",
  FINAL="Final",
  MISSED="Missed",
}
 
--- Waypoint of the approach.
-- @type NAVAPP.Waypoint
-- @field #number uid Unique ID of the point.
-- @field #string segment The segment this point belongs to.
-- @field Navigation.NavFix#NAVFIX navfix The navigation fix that determines the coordinates of this point.
  
--- NAVAPP class version.
-- @field #string version
NAVAPP.version="0.0.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ToDo list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: A lot...
-- Initial approach segment --> Intermediate approach segment: starts at IF --> Final approach segment

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new NAVAPP class instance.
-- @param #NAVAPP self
-- @param #string Type Type of approach (ILS, VOR, LOC).
-- @param Wrapper.Airbase#AIRBASE Airbase The airbase or name of the airbase.
-- @param Wrapper.Airbase#AIRBASE.Runway Runway The runway or name of the runway.
-- @return #NAVAPP self
function NAVAPP:New(Type, Airbase, Runway)

  -- Inherit everything from BASE class.
  self=BASE:Inherit(self, BASE:New()) -- #NAVAPP
  
  self.apptype=Type
  
  self.airbase=Airbase
  
  self.runway=Runway

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set the primary navigation aid used in the approach.
-- @param #NAVAPP self
-- @param Navigation.NavAid#NAVAID NavAid The NAVAID.
-- @return #NAVAPP self
function NAVAPP:SetNavAid(NavAid)

  self.navaid=NavAid

  return self
end

--- Add a waypoint to the path of the approach.
-- @param #NAVAPP self
-- @param Navigation.NavAid#NAVAID NavAid The NAVAID.
-- @param #string Segment The approach segment this fix belongs to.
-- @return #NAVAPP self
function NAVAPP:AddWaypoint(NavFix, Segment)

  self.wpcounter=self.wpcounter+1

  local point={} --#NAVAPP.Waypoint
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
