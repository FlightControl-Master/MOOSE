--- **NAVIGATION** - Prodedures for Departure (*e.g.* SID), Enroute, Arrival (*e.g.* STAR) and Approach.
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
-- @field Navigation.Point#NAVAID navaid Primary navigation aid.
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
-- @field #string VFR Visual Flight Rules.
-- @field #string VOR VOR
-- @field #string NDB NDB
APPROACH.Type={
  VFR="VFR",
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
-- @field Navigation.Point#NAVFIX navfix The navigation fix that determines the coordinates of this point.
  
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
  
  -- Set approach type.
  -- TODO: Check if this is a valid/known approach type.
  self.apptype=Type
  
  if type(Airbase)=="string" then
    self.airbase=AIRBASE:FindByName(Airbase)
  else
    self.airbase=Airbase
  end
  
  if type(Runway)=="string" then
    self.runway=self.airbase:GetRunwayByName(Runway)
  else
    self.runway=Runway
  end
  
  -- Debug info.
  self:I("Created new approach for airbase %s: type=%s, runway=%s", self.airbase:GetName(), self.apptype, self.runway.name)
  
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set the primary navigation aid used in the approach.
-- @param #APPROACH self
-- @param Navigation.Point#NAVAID NavAid The NAVAID.
-- @return #APPROACH self
function APPROACH:SetNavAid(NavAid)

  self.navaid=NavAid

  return self
end

--- Add a waypoint to the path of the approach.
-- @param #APPROACH self
-- @param Navigation.Point#NAVFIX NavFix The navigation fix.
-- @param #string Segment The approach segment this fix belongs to.
-- @return #APPROACH.Waypoint The waypoint data table.
function APPROACH:AddNavFix(NavFix, Segment)

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

-- Add private functions here.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- DEPARTURE class.
-- @type DEPARTURE
-- @field #string ClassName Name of the class.
-- @field #number verbose Verbosity of output.
-- @field #string apptype DEPARTURE type (ILS, VOR, LOC).
-- @field Wrapper.Airbase#AIRBASE airbase Airbase of this DEPARTURE.
-- @field Wrapper.Airbase#AIRBASE.Runway runway Runway of this DEPARTURE.
-- @field Navigation.Point#NAVAID navaid Primary navigation aid.
-- @field #number wpcounter Running number counting the waypoints to generate its UID.
-- @list <#DEPARTURE.Waypoint> path Path of DEPARTURE consisting of waypoints.
-- @extends Core.Base#BASE

--- *A fleet of British ships at war are the best negotiators.* -- Horatio Nelson
--
-- ===
--
-- # The DEPARTURE Concept
-- 
-- Bla.
--
-- @field #DEPARTURE
DEPARTURE = {
  ClassName       = "DEPARTURE",
  verbose         =       0,
  wpcounter       =       0,
}

--- Type of DEPARTURE.
-- @type DEPARTURE.Type
-- @field #string VOR VOR
-- @field #string NDB NDB
DEPARTURE.Type={
  VOR="VOR",
  ILS="ILS",
}


--- Setments of  DEPARTURE.
-- @type DEPARTURE.Segment
-- @field #string INITIAL Initial DEPARTURE segment.
-- @field #string INTERMEDIATE Intermediate DEPARTURE segment.
-- @field #string FINAL Final DEPARTURE segment.
-- @field #string MISSED Missed DEPARTURE segment.
DEPARTURE.Segment={
  INITIAL="Initial",
  INTERMEDIATE="Intermediate",
  FINAL="Final",
  MISSED="Missed",
}
 
--- Waypoint of the DEPARTURE.
-- @type DEPARTURE.Waypoint
-- @field #number uid Unique ID of the point.
-- @field #string segment The segment this point belongs to.
-- @field Navigation.Point#NAVFIX navfix The navigation fix that determines the coordinates of this point.
  
--- DEPARTURE class version.
-- @field #string version
DEPARTURE.version="0.0.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ToDo list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: A lot...
-- Initial DEPARTURE segment --> Intermediate DEPARTURE segment: starts at IF --> Final DEPARTURE segment

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new DEPARTURE class instance.
-- @param #DEPARTURE self
-- @param Wrapper.Airbase#AIRBASE Airbase The airbase or name of the airbase.
-- @param Wrapper.Airbase#AIRBASE.Runway Runway The runway or name of the runway.
-- @param #string Type Type of DEPARTURE (ILS, VOR, LOC).
-- @return #DEPARTURE self
function DEPARTURE:New(Airbase, Runway)

  -- Inherit everything from BASE class.
  self=BASE:Inherit(self, BASE:New()) -- #DEPARTURE

  if type(Airbase)=="string" then
    self.airbase=AIRBASE:FindByName(Airbase)
  else
    self.airbase=Airbase
  end
  
  if type(Runway)=="string" then
    self.runway=self.airbase:GetRunwayByName(Runway)
  else
    self.runway=Runway
  end

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set the primary navigation aid used in the DEPARTURE.
-- @param #DEPARTURE self
-- @param Navigation.Point#NAVAID NavAid The NAVAID.
-- @return #DEPARTURE self
function DEPARTURE:SetNavAid(NavAid)

  self.navaid=NavAid

  return self
end

--- Add a waypoint to the path of the DEPARTURE.
-- @param #DEPARTURE self
-- @param Navigation.Point#NAVFIX NavFix The navigation fix.
-- @param #string Segment The DEPARTURE segment this fix belongs to.
-- @return #DEPARTURE.Waypoint The waypoint data.
function DEPARTURE:AddWaypoint(NavFix, Segment)

  self.wpcounter=self.wpcounter+1

  local point={} --#DEPARTURE.Waypoint
  point.uid=self.wpcounter
  point.segment=Segment
  point.navfix=NavFix

  table.insert(self.path, point)

  return point
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Add DEPARTURE private functions here.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

