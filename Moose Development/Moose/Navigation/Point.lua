--- **NAVIGATION** - Navigation Airspace Points, Fixes and Aids.
--
-- **Main Features:**
--
--    * Navigation Fixes
--    * Navigation Aids
-- 
-- ===
--
-- ## Example Missions:
--
-- Demo missions can be found on [github](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/develop/Navigation%20-%20NavFix).
-- 
-- ===
--
-- ### Author: **funkyfranky**
-- 
-- ===
-- @module Navigation.Point
-- @image MOOSE.JPG


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- NAVFIX class.
-- @type NAVFIX
-- 
-- @field #string ClassName Name of the class.
-- @field #number verbose Verbosity of output.
-- @field #string name Name of the point.
-- @field #string typePoint Type of the point, *e.g. "Intersection", "VOR", "Airport".
-- @field Core.Vector#VECTOR vector Position vector of the fix.
-- @field Wrapper.Marker#MARKER marker Marker on F10 map.
-- @field #number altMin Minimum altitude in meters.
-- @field #number altMax Maximum altitude in meters.
-- @field #number speedMin Minimum speed in knots.
-- @field #number speedMax Maximum speed in knots.
-- 
-- @field #boolean isCompulsory Is this a compulsory fix.
-- @field #boolean isFlyover Is this a flyover fix (`true`) or turning point otherwise.
-- @field #boolean isFAF Is this a final approach fix.
-- @field #boolean isIAF Is this an initial approach fix.
-- @field #boolean isIF Is this an initial fix.
-- @field #boolean isMAF Is this an initial fix.
-- 
-- @extends Core.Base#BASE

--- *A fleet of British ships at war are the best negotiators.* -- Horatio Nelson
--
-- ===
--
-- # The NAVFIX Concept
--
-- The NAVFIX class has a great concept!
-- 
-- A NAVFIX describes a geo position and can, *e.g.*, be part of a FLIGHTPLAN. It has a unique name and is of a certain type, *e.g.* "Intersection", "VOR", "Airbase" etc.
-- It can also have further properties as min/max altitudes and speeds that aircraft need to obey when they pass the point.
-- 
-- # Basic Setup
-- 
-- A new `NAVFIX` object can be created with the @{#NAVFIX.New}() function.
-- 
--     myNavPoint=NAVFIX:New()
--     myTemplate:SetXYZ(X, Y, Z)
--     
-- This is how it works.
--
-- @field #NAVFIX
NAVFIX = {
  ClassName       = "NAVFIX",
  verbose         =          0,
}

--- Type of point.
-- @type NAVFIX.Type
-- @field #string POINT Waypoint.
-- @field #string INTERSECTION Intersection of airway.
-- @field #string AIRPORT Airport.
-- @field #string VOR Very High Frequency Omnidirectional Range Station.
-- @field #string DME Distance Measuring Equipment.
-- @field #string NDB Non-Directional Beacon.
-- @field #string VORDME Combined VHF omnidirectional range (VOR) with a distance-measuring equipment (DME).
-- @field #string LOC Localizer.
-- @field #string ILS Instrument Landing System.
-- @field #string TACAN TACtical Air Navigation System (TACAN).
NAVFIX.Type={
  POINT="Point",
  INTERSECTION="Intersection",
  AIRPORT="Airport",
  NDB="NDB",
  VOR="VOR",
  DME="DME",
  VORDME="VOR/DME",
  LOC="Localizer",
  ILS="ILS",
  TACAN="TACAN"
}

--- NAVFIX class version.
-- @field #string version
NAVFIX.version="0.1.0"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ToDo list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: A lot...

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor(s)
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new NAVFIX class instance from a given VECTOR.
-- @param #NAVFIX self
-- @param #string Name Name/ident of the point. Should be unique!
-- @param #string Type Type of the point. Default `NAVFIX.Type.POINT`.
-- @param Core.Vector#VECTOR Vector Position vector of the navpoint.
-- @return #NAVFIX self
function NAVFIX:NewFromVector(Name, Type, Vector)

  -- Inherit everything from BASE class.
  self=BASE:Inherit(self, BASE:New()) -- #NAVFIX
  
  -- Vector of point.
  self.vector=Vector
  
  -- Name of point.
  self.name=Name
  
  -- Type of the point.
  self.typePoint=Type or NAVFIX.Type.POINT
  
  local coord=COORDINATE:NewFromVec3(self.vector)
  
  -- Marker on F10.
  self.marker=MARKER:New(coord, self:_GetMarkerText())
  
  -- Log ID string.
  self.lid=string.format("NAVFIX %s [%s] | ", tostring(self.name), tostring(self.typePoint))
  
  -- Debug info.
  self:I(self.lid..string.format("Created NAVFIX"))

  return self
end


--- Create a new NAVFIX class instance from a given COORDINATE.
-- @param #NAVFIX self
-- @param #string Name Name of the fix. Should be unique!
-- @param #string Type Type of the point. Default `NAVFIX.Type.POINT`.
-- @param Core.Point#COORDINATE Coordinate Coordinate of the point.
-- @return #NAVFIX self
function NAVFIX:NewFromCoordinate(Name, Type, Coordinate)

  -- Create a VECTOR from the coordinate.
  local Vector=VECTOR:NewFromVec(Coordinate)
  
  -- Create NAVFIX.
  self=NAVFIX:NewFromVector(Name, Type, Vector)
  
  return self
end


--- Create a new NAVFIX instance from given latitude and longitude in degrees, minutes and seconds (DMS).
-- @param #NAVFIX self
-- @param #string Name Name of the fix. Should be unique!
-- @param #string Type Type of the point. Default `NAVFIX.Type.POINT`.
-- @param #string Latitude Latitude in DMS as string.
-- @param #string Longitude Longitude in DMS as string.
-- @return #NAVFIX self
function NAVFIX:NewFromLLDMS(Name, Type, Latitude, Longitude)

  -- Create a VECTOR from the coordinate.
  local Vector=VECTOR:NewFromLLDMS(Latitude, Longitude)

  -- Create NAVFIX.
  self=NAVFIX:NewFromVector(Name, Type, Vector)
  
  return self  
end

--- Create a new NAVFIX instance from given latitude and longitude in decimal degrees (DD).
-- @param #NAVFIX self
-- @param #string Name Name of the fix. Should be unique!
-- @param #string Type Type of the point. Default `NAVFIX.Type.POINT`.
-- @param #number Latitude Latitude in DD.
-- @param #number Longitude Longitude in DD.
-- @return #NAVFIX self
function NAVFIX:NewFromLLDD(Name, Type, Latitude, Longitude)

  -- Create a VECTOR from the coordinate.
  local Vector=VECTOR:NewFromLLDD(Latitude, Longitude)

  -- Create NAVFIX.
  self=NAVFIX:NewFromVector(Name, Type, Vector)
  
  return self  
end


--- Create a new NAVFIX class instance relative to a given other NAVFIX.
-- You have to specify the distance and bearing from the new point to the given point. *E.g.*, for a distance of 5 NM and a bearing of 090° (West), the
-- new nav point is created 5 NM East of the given nav point. The reason is that this corresponts to convention used in most maps.
-- You can, however, use the `Reciprocal` switch to create the new point in the direction you specify.
-- @param #NAVFIX self
-- @param #string Name Name of the fix. Should be unique!
-- @param #string Type Type of navfix.
-- @param #NAVFIX NavFix The given/existing navigation fix relative to which the new fix is created.
-- @param #number Distance Distance from the given to the new point in nautical miles.
-- @param #number Bearing Bearing [Deg] from the new point to the given one.
-- @param #boolean Reciprocal If `true` the reciprocal `Bearing` is taken so it specifies the direction from the given point to the new one. 
-- @return #NAVFIX self
function NAVFIX:NewFromNavFix(Name, Type, NavFix, Distance, Bearing, Reciprocal)

  -- Convert magnetic to true bearing by adding magnetic declination, e.g. mag. bearing 10°M ==> true bearing 16°M (for 6° variation on Caucasus map)
  Bearing=Bearing+UTILS.GetMagneticDeclination()

  if Reciprocal then
    Bearing=Bearing-180
  end
  
  -- Translate.
  local Vector=NavFix.vector:Translate(UTILS.NMToMeters(Distance), Bearing, true)
  
  self=NAVFIX:NewFromVector(Name, Type, Vector)
  
  return self
end

--- Create a new NAVFIX class instance from  BEACONS.Beacon data.
-- @param #NAVFIX self
-- @param Navigation.Beacons#BEACONS.Beacon Beacon The beacon data.
-- @return #NAVFIX self
function NAVFIX:NewFromBeacon(Beacon)
  local frequency, unit = BEACONS:_GetFrequency(Beacon.frequency)
  frequency = string.format("%.3f",frequency)
  if Beacon.typeName == "TACAN" then
    frequency = Beacon.channel
    unit = "X"
  end
  self = NAVFIX:NewFromVector(string.format("%s %s %s",Beacon.typeName,frequency,unit),Beacon.typeName,Beacon.vec3)
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set whether this is the intermediate fix (IF).
-- @param #NAVFIX self
-- @return #NAVFIX self
function NAVFIX:SetIntermediateFix(IntermediateFix)
  self.isIF=IntermediateFix
  return self
end

--- Set whether this is an initial approach fix (IAF).
-- The IAF is the point where the initial approach segment of an instrument approach begins.
-- It is usually a designated intersection, VHF omidirectional range (VOR) non-directional beacon (NDB)
-- or distance measuring equipment (DME) fix.
-- The IAF may be collocated with the intermediate fix (IF) of the instrument apprach an in such case they designate the
-- beginning of the intermediate segment of the approach. When the IAF and the IF are combined, there is no inital approach segment.
-- @param #NAVFIX self
-- @param #boolean IntermediateFix If `true`, this is an intermediate fix.
-- @return #NAVFIX self
function NAVFIX:SetInitialApproachFix(IntermediateFix)
  self.isIAF=IntermediateFix
  return self
end


--- Set whether this is the final approach fix (FAF).
-- @param #NAVFIX self
-- @param #boolean FinalApproachFix If `true`, this is a final approach fix.
-- @return #NAVFIX self
function NAVFIX:SetFinalApproachFix(FinalApproachFix)
  self.isFAF=FinalApproachFix
  return self
end

--- Set whether this is the final approach fix (FAF).
-- @param #NAVFIX self
-- @param #boolean FinalApproachFix If `true`, this is a final approach fix.
-- @return #NAVFIX self
function NAVFIX:SetMissedApproachFix(MissedApproachFix)
  self.isMAF=MissedApproachFix
  return self
end


--- Set minimum altitude.
-- @param #NAVFIX self
-- @param #number Altitude Min altitude in feet.
-- @return #NAVFIX self
function NAVFIX:SetAltMin(Altitude)

  self.altMin=Altitude

  return self
end

--- Set maximum altitude.
-- @param #NAVFIX self
-- @param #number Altitude Max altitude in feet.
-- @return #NAVFIX self
function NAVFIX:SetAltMax(Altitude)

  self.altMax=Altitude

  return self
end

--- Set mandatory altitude (min alt = max alt).
-- @param #NAVFIX self
-- @param #number Altitude Altitude in feet.
-- @return #NAVFIX self
function NAVFIX:SetAltMandatory(Altitude)

  self.altMin=Altitude
  self.altMax=Altitude

  return self
end

--- Set minimum allowed speed at this fix.
-- @param #NAVFIX self
-- @param #number Speed Min speed in knots.
-- @return #NAVFIX self
function NAVFIX:SetSpeedMin(Speed)

  self.speedMin=Speed

  return self
end

--- Set maximum allowed speed at this fix.
-- @param #NAVFIX self
-- @param #number Speed Max speed in knots.
-- @return #NAVFIX self
function NAVFIX:SetSpeedMax(Speed)

  self.speedMax=Speed

  return self
end

--- Set mandatory speed (min speed = max speed) at this fix.
-- @param #NAVFIX self
-- @param #number Speed Mandatory speed in knots.
-- @return #NAVFIX self
function NAVFIX:SetSpeedMandatory(Speed)

  self.speedMin=Speed
  self.speedMax=Speed

  return self
end


--- Set whether this fix is compulsory.
-- @param #NAVFIX self
-- @param #boolean Compulsory If `true`, this is a compulsory fix. If `false` or nil, it is non-compulsory.
-- @return #NAVFIX self
function NAVFIX:SetCompulsory(Compulsory)
  self.isCompulsory=Compulsory
  return self
end

--- Set whether this is a fly-over fix fix.
-- @param #NAVFIX self
-- @param #boolean FlyOver If `true`, this is a fly over fix. If `false` or nil, it is not.
-- @return #NAVFIX self
function NAVFIX:SetFlyOver(FlyOver)
  self.isFlyover=FlyOver
  return self
end


--- Get the altitude in feet MSL. If min and max altitudes are set, it will return a random altitude between min and max.
-- @param #NAVFIX self
-- @return #number Altitude in feet MSL. Can be `nil`, if neither min nor max altitudes have beeen set. 
function NAVFIX:GetAltitude()

  local alt=nil
  if self.altMin and self.altMax and self.altMin~=self.altMax then
    alt=math.random(self.altMin, self.altMax)
  elseif self.altMin then
    alt=self.altMin
  elseif self.altMax then
    alt=self.altMax
  end

  return alt
end


--- Get the speed. If min and max speeds are set, it will return a random speed between min and max.
-- @param #NAVFIX self
-- @return #number Speed in knots. Can be `nil`, if neither min nor max speeds have beeen set. 
function NAVFIX:GetSpeed()

  local speed=nil
  if self.speedMin and self.speedMax and self.speedMin~=self.speedMax then
    speed=math.random(self.speedMin, self.speedMax)
  elseif self.speedMin then
    speed=self.speedMin
  elseif self.speedMax then
    speed=self.speedMax
  end

  return speed
end



--- Add marker the NAVFIX on the F10 map.
-- @param #NAVFIX self
-- @return #NAVFIX self
function NAVFIX:MarkerShow()

  self.marker:ToAll()

  return self
end

--- Remove marker of the NAVFIX from the F10 map.
-- @param #NAVFIX self
-- @return #NAVFIX self
function NAVFIX:MarkerRemove()

  self.marker:Remove()

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get text displayed in the F10 marker.
-- @param #NAVFIX self
-- @return #string Marker text.
function NAVFIX:_GetMarkerText()

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

--- NAVAID class.
-- @type NAVAID
-- @field #string ClassName Name of the class.
-- @field #number verbose Verbosity of output.
-- @extends Navigation.Point#NAVFIX

--- *A fleet of British ships at war are the best negotiators.* -- Horatio Nelson
--
-- ===
--
-- # The NAVAID Concept
--
-- A NAVAID consists of one or multiple FLOTILLAs. These flotillas "live" in a WAREHOUSE that has a phyiscal struction (STATIC or UNIT) and can be captured or destroyed.
-- 
-- # Basic Setup
-- 
-- A new `NAVAID` object can be created with the @{#NAVAID.New}(`WarehouseName`, `FleetName`) function, where `WarehouseName` is the name of the static or unit object hosting the fleet
-- and `FleetName` is the name you want to give the fleet. This must be *unique*!
-- 
--     myFleet=NAVAID:New("myWarehouseName", "1st Fleet")
--     myFleet:SetPortZone(ZonePort1stFleet)
--     myFleet:Start()
--     
-- A fleet needs a *port zone*, which is set via the @{#NAVAID.SetPortZone}(`PortZone`) function. This is the zone where the naval assets are spawned and return to.
-- 
-- Finally, the fleet needs to be started using the @{#NAVAID.Start}() function. If the fleet is not started, it will not process any requests.
--
-- @field #NAVAID
NAVAID = {
  ClassName       = "NAVAID",
  verbose         =       0,
}
  
--- NAVAID class version.
-- @field #string version
NAVAID.version="0.1.0"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ToDo list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Add frequencies. Which unit MHz, kHz, Hz?
-- TODO: Add radial function

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new NAVAID class instance.
-- @param #NAVAID self
-- @param #string Name Name/ident of this navaid.
-- @param #string Type Type of the point. Default `NAVFIX.Type.POINT`.
-- @param #string ZoneName Name of the zone to scan the scenery.
-- @param #string SceneryName Name of the scenery object.
-- @return #NAVAID self
function NAVAID:NewFromScenery(Name, Type, ZoneName, SceneryName)

  -- Get the zone.
  local zone=ZONE:FindByName(ZoneName)
  
  -- Get coordinate.
  local Coordinate=zone:GetCoordinate()

  -- Inherit everything from NAVFIX class.
  self=BASE:Inherit(self, NAVFIX:NewFromCoordinate(Name, Type, Coordinate)) -- #NAVAID

  -- Set zone.
  self.zone=ZONE:FindByName(ZoneName)

  -- Try to get the scenery object. Note not all can be found unfortunately.
  if SceneryName then
    self.scenery=SCENERY:FindByNameInZone(SceneryName, ZoneName)
    if not self.scenery then
      self:E(string.format("ERROR: Could not find scenery object %s in zone %s", SceneryName, ZoneName))
    end
  end
  
  -- Alias.  
  self.alias=string.format("%s %s %s", tostring(ZoneName), tostring(SceneryName), tostring(Type))
  
  -- Set some string id for output to DCS.log file.
  self.lid=string.format("NAVAID %s | ", self.alias)
  
  -- Debug info.
  self:I(self.lid..string.format("Created NAVAID!"))

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set frequency the beacon transmits on.
-- @param #NAVAID self
-- @param #number Frequency Frequency in Hz.
-- @return #NAVAID self
function NAVAID:SetFrequency(Frequency)

  self.frequency=Frequency

  return self
end

--- Set channel of, *e.g.*, TACAN beacons.
-- @param #NAVAID self
-- @param #number Channel The channel.
-- @param #string Band The band either `"X"` (default) or `"Y"`. 
-- @return #NAVAID self
function NAVAID:SetChannel(Channel, Band)

  self.channel=Channel
  self.band=Band or "X"

  return self
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Add private CLASS functions here.
-- No private NAVAID functions yet.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
