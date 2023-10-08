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
-- @field Core.Pathline#PATHLINE pathline Pathline of the plan.
-- @field Wrapper.Airbase#AIRBASE departureAirbase Departure airbase.
-- @field Wrapper.Airbase#AIRBASE destinationAirbase Destination airbase.
-- @field #number altitudeCruiseMin Minimum cruise altitude in feet MSL.
-- @field #number altitudeCruiseMax Maximum cruise altitude in feet MSL.
-- @extends Core.Pathline#PATHLINE

--- *Life is what happens to us while we are making other plans.* -- Allen Saunders
--
-- ===
--
-- # The FLIGHTPLAN Concept
--
-- This class has a great concept!
-- 
-- # Basic Setup
-- 
-- A new `FLIGHTPLAN` object can be created with the @{#FLIGHTPLAN.New}() function.
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
  IFRH = "IFR High",
  IFRL = "IFR Low",
  VFR  = "VFR",
}


  
--- FLIGHTPLAN class version.
-- @field #string version
FLIGHTPLAN.version="0.0.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ToDo list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: How to connect SID, STAR, ENROUTE, TRANSITION, APPROACH. Typical flightplan SID --> ENROUTE --> STAR --> APPROACH
-- TODO: Add approach.
-- DONE: How to handle the FLIGHTGROUP:_LandAtAirBase
-- TODO: Do we always need a holding pattern? https://www.faa.gov/air_traffic/publications/atpubs/aip_html/part2_enr_section_1.5.html#:~:text=If%20no%20holding%20pattern%20is,than%20that%20desired%20by%20ATC.
-- DOEN: Read from MSFS file.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new FLIGHTPLAN instance.
-- @param #FLIGHTPLAN self
-- @param #string Name Name of this flight plan.
-- @return #FLIGHTPLAN self
function FLIGHTPLAN:New(Name)

  -- Inherit everything from BASE class.
  self=BASE:Inherit(self, PATHLINE:New(Name)) -- #FLIGHTPLAN

  -- Set alias.
  self.alias=tostring(Name)
  
  -- Set some string id for output to DCS.log file.
  self.lid=string.format("FLIGHTPLAN %s | ", self.alias)
  
  --self.pathline=PATHLINE:New(Name)
  
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


--- Create a new FLIGHTPLAN instance from a given file.
-- Currently, the file has to be an MSFS 2020 .pln file as, *e.g.*, exported from [Navigraph](https://navigraph.com/).
-- 
-- **Note** that the flight plan does only cover the departure, enroute and arrival portions but **not the approach** part!
-- @param #FLIGHTPLAN self
-- @param #string FileName Full path to file.
-- @return #FLIGHTPLAN self
function FLIGHTPLAN:NewFromFile(FileName)

  if UTILS.FileExists(FileName) then
  
    self=FLIGHTPLAN._ReadFileMSFS(FileName)  
  
  else
    error(string.format("ERROR: File not found! File name=%s", tostring(FileName)))  
  end

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Add navigation fix to the flight plan.
-- @param #FLIGHTPLAN self
-- @param Navigation.Point#NAVPOINT NavFix The nav fix.
-- @return #FLIGHTPLAN self
function FLIGHTPLAN:AddNavFix(NavFix)

  table.insert(self.fixes, NavFix)
  
  local point=self:AddPointFromVec3(NavFix.vector:GetVec3(true))
  
  point.navpoint=NavFix

  return self
end


--- Set departure airbase.
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

--- Set cruise speed.
-- @param #FLIGHTPLAN self
-- @param #number SpeedMin Minimum speed in knots.
-- @param #number SpeedMax Maximum speed in knots. Default is `SpeedMin`.
-- @return #FLIGHTPLAN self
function FLIGHTPLAN:SetCruiseSpeed(SpeedMin, SpeedMax)

  self.speedCruiseMin=SpeedMin
  self.speedCruiseMax=SpeedMax or self.speedCruiseMin

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

--- Get cruise speed. This returns a random speed between the set min/max cruise speeds.
-- @param #FLIGHTPLAN self
-- @return #number Cruise speed in knots.
function FLIGHTPLAN:GetCruiseSpeed()

  local speed=250
  
  if self.speedCruiseMin and self.speedCruiseMax then
    speed=math.random(self.speedCruiseMin, self.speedCruiseMax)
  elseif self.speedCruiseMin then
    speed=self.speedCruiseMin
  elseif self.altitudeCruiseMax then
    speed=self.speedCruiseMax
  end
  
  return speed
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Read flight plan from a given MSFS 2020 .plt file.
-- @param #string FileName Name of the file.
-- @return #FLIGHTPLAN The flight plan.
function FLIGHTPLAN._ReadFileMSFS(FileName)

  local function readfile(filename)

    local lines = {}
    
    -- Open file in read binary mode.
    local file=assert(io.open(filename, "rb"), string.format("File not found! File name = %s", tostring(filename)))

    for line in file:lines() do
        lines[#lines+1] = line
    end
    
    -- Close file.
    file:close()
  
    -- Return data
    return lines
  end


  --- This function returns an XML element, i.e. the string between <...> and </...>.
  local function getXMLelement(line)
    local element=string.match(line, ">(.+)<")
    return element
  end

  --- This function returns Latitude and Longitude
  local function getLatLong(line)
    local latlong=getXMLelement(line)
    -- The format is "N41° 38' 20.00",E41° 33' 19.00",+000000.00" so we still need to process that.
    local lat,long=string.match(latlong, "(.+),(.+),")
    return lat,long
  end
  
  -- Read data from file.
  local data=readfile(FileName)

  local flightplan={}
  local waypoints={}
  local wp=nil
  
  local gotwaypoint=false
  for i,line in pairs(data) do
  
  
    --print(line)
  
    -- Title  
    if string.find(line, "<Title>") then
      flightplan.title=getXMLelement(line)
    end
  
    -- Departure ICAO
    if string.find(line, "<DepartureID>") then
      flightplan.departureICAO=getXMLelement(line)
    end
  
    -- Destination ICAO
    if string.find(line, "<DestinationID>") then
      flightplan.destinationICAO=getXMLelement(line)
    end
  
    -- FPType  
    if string.find(line, "<FPType>") then
      flightplan.plantype=getXMLelement(line)
    end
    
    -- Route type  
    if string.find(line, "<RouteType>") then
      flightplan.routetype=getXMLelement(line)
    end
  
    -- Cruise alt in feet
    if string.find(line, "<CruisingAlt>") then
      flightplan.altCruise=getXMLelement(line)
    end
  
    -- Departure LLA
    if string.find(line, "<DepartureLLA>") then
      local lat,long=getLatLong(line)    
    end
    
    -- Destination LLA
    if string.find(line, "<DestinationLLA>") then
      local lat,long=getLatLong(line)    
    end  
  
    -- Departure Name
    if string.find(line, "<DepartureName>") then
      local DepartureName=getXMLelement(line)
    end
      
    -- DestinationName
    if string.find(line, "<DestinationName>") then
      local DestinationName=getXMLelement(line)
    end
      
    ---
    -- Waypoint stuff
    ---
  
    -- New waypoint starts.
    if string.find(line, "ATCWaypoint id") then
    
      --Get string inside quotes " and ". 
      local wpid=string.match(line, [["(.+)"]]) 
      
      -- Create a new wp table.
      wp={}
      
      -- Set waypoint name.
      wp.name=wpid
    end
    
    -- Waypoint info ends.
    if string.find(line, "</ATCWaypoint>") then
      -- This is the end of the waypoint.
      
      -- Add info to waypoints table.
      table.insert(waypoints, wp)
      
      -- Set waypoint to nil. We create an empty table if the next wp starts.
      wp=nil
    end
    
    -- Waypoint type (Airport, Intersection, NDB, VORTAC)
    if string.find(line, "<ATCWaypointType>") then
      local wptype=getXMLelement(line)
      wp.type=wptype
    end
    
    -- Waypoint position.
    if string.find(line, "<WorldPosition>") then
      wp.lat, wp.long=getLatLong(line)
    end
    
    -- Runway should exist for initial and final WP if it is an airport.
    if string.find(line, "RunwayNumberFP") then
      wp.runway=getXMLelement(line)
    end
    
    -- Runway designator: LEFT, RIGHT, CENTER
    if string.find(line, "RunwayDesignatorFP") then 
      wp.runwayDesignator=getXMLelement(line)
    end  
    
    -- Segment is Departure
    if string.find(line, "<DepartureFP>") then
      wp.segment="Departure"
    end
    
    -- Segment is Arrival
    if string.find(line, "<ArrivalFP>") then
      wp.segment="Arrival"
    end
    
    -- Segment is Enroute
    if string.find(line, "<ATCAirway>") then
      wp.segment="Enroute"
    end
  
    -- Approach type: VORDME, LOCALIZER
    if string.find(line, "ApproachTypeFP") then
      flightplan.approachtype=getXMLelement(line)
    end
  
    -- Approach type suffic: Z
    if string.find(line, "SuffixFP") then
      local SuffixFP=getXMLelement(line)
    end
    
  end
    
  for key, value in pairs(flightplan) do
    env.info(string.format("Flightplan %s=%s", key, tostring(value)))
  end

  env.info(string.format("Number of waypoints=%d", #waypoints))  
  for i,wp in pairs(waypoints) do
    env.info(string.format("Waypoint name=%s type=%s segment=%s runway=%s lat=%s long=%s", wp.name, wp.type, tostring(wp.segment), tostring(wp.runway)..tostring(wp.runwayDesignator or ""), wp.lat, wp.long))
  end
  
  -- Create a new flightplan.
  local fp=FLIGHTPLAN:New(flightplan.title)
  
  -- Set cruise altitude.
  fp:SetCruiseAltitude(flightplan.altCruise)
  
  -- Set departure and destination airports.
  fp:SetDepartureAirbase(flightplan.departureICAO)
  fp:SetDestinationAirbase(flightplan.destinationICAO)
  
  --TODO: Remove first and last waypoint if they are identical to the departure/destination airport!
  
  for i,wp in pairs(waypoints) do
      
    -- Create a navpoint.
    local navpoint=NAVPOINT:NewFromLLDMS(wp.name, wp.type, wp.lat, wp.long)
    
    navpoint:SetAltMin(flightplan.altCruise)
  
    -- Add point to flightplan.
    -- TODO: section departure, enroute, arrival.
    fp:AddNavFix(navpoint)  
  end

  

  return fp
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
