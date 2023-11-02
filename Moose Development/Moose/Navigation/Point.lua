--- **NAVIGATION** - Navigation Airspace Points, Fixes and Aids.
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
-- Demo missions can be found on [github](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/develop/Navigation%20-%20NavFix).
-- 
-- ===
--
-- ### Author: **funkyfranky**
-- 
-- ===
-- @module Navigation.Point
-- @image NAVIGATION_Point.png


--- NAVAID class.
-- @type NAVAID
-- @field #string ClassName Name of the class.
-- @field #number verbose Verbosity of output.
-- @extends Core.Base#BASE

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

--- Type of navaid
-- @type NAVAID.Type
-- @field #string VOR Very High Frequency Omnirange Station (VOR).
-- @field #string NDB Non-Directional Beacon (NDB).
-- @field #string DME Distance Measuring Equipment (DME).
-- @field #string TACAN TACtical Air Navigation System (TACAN).
-- @field #string LOC LOCalizer for horizontal guidance (LOC).
NAVAID.Type={
  VOR="VOR",
  NDB="NDB",
  DME="DME",
  TACAN="TACAN",
  LOC="Localizer"
}
  
--- NAVAID class version.
-- @field #string version
NAVAID.version="0.0.1"

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
-- @param #string ZoneName Name of the zone to scan the scenery.
-- @param #string SceneryName Name of the scenery object.
-- @param #string Type Type of Navaid.
-- @return #NAVAID self
function NAVAID:New(ZoneName, SceneryName, Type)

  -- Inherit everything from BASE class.
  self=BASE:Inherit(self, BASE:New()) -- #NAVAID


  self.zone=ZONE:FindByName(ZoneName)  
  
  self.coordinate=self.zone:GetCoordinate()
  
  if SceneryName then
    self.scenery=SCENERY:FindByNameInZone(SceneryName, ZoneName)
    if not self.scenery then
      self:E("ERROR: Could not find scenery object %s in zone %s", SceneryName, ZoneName)
    end
  end
  
  self.alias=string.format("%s %s %s", tostring(ZoneName), tostring(SceneryName), tostring(Type))
  

  -- Set some string id for output to DCS.log file.
  self.lid=string.format("NAVAID %s | ", self.alias)
  
  self:I(self.lid..string.format("Created NAVAID!"))

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set frequency.
-- @param #NAVAID self
-- @param #number Frequency Frequency in Hz.
-- @return #NAVAID self
function NAVAID:SetFrequency(Frequency)

  self.frequency=Frequency

  return self
end

--- Set channel.
-- @param #NAVAID self
-- @param #number Channel
-- @param #string Band
-- @return #NAVAID self
function NAVAID:SetChannel(Channel, Band)

  self.channel=Channel
  self.band=Band

  return self
end

--- Add marker the NAVAID on the F10 map.
-- @param #NAVAID self
-- @return #NAVAID self
function NAVAID:AddMarker()

  local text=string.format("I am a NAVAID!")
  
  self.markID=self.coordinate:MarkToAll(text, true)

  return self
end

--- Remove marker of the NAVAID from the F10 map.
-- @param #NAVAID self
-- @return #NAVAID self
function NAVAID:DelMarker()

  if self.markID then
    UTILS.RemoveMark(self.markID)
  end

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

--- NAVFIX class.
-- @type NAVFIX
-- @field #string ClassName Name of the class.
-- @field #boolean isIAF Is initial approach fix (IAF). 
-- @field #boolean isIF Is intermediate fix (IF).
-- @field #boolean isFAF Is final approach fix (FAF).
-- @field #boolean isMAF Is missed approach fix (MAF).
-- 
-- @extends Navigation.Point#NAVPOINT

--- *A fleet of British ships at war are the best negotiators.* -- Horatio Nelson
--
-- ===
--
-- # The NAVFIX Concept
--
-- The NAVFIX class has a great concept!
-- 
-- # Basic Setup
-- 
-- A new `NAVFIX` object can be created with the @{#NAVFIX.New}() function.
-- 
--     myTemplate=NAVFIX:New()
--     myTemplate:SetXYZ(X, Y, Z)
--     
-- This is how it works.
--
-- @field #NAVFIX
NAVFIX = {
  ClassName       = "NAVFIX",
  verbose         =       0,
}

--- Type of navaid
-- @type NAVFIX.Type
-- @field #string VOR VOR
-- @field #string NDB NDB
NAVFIX.Type={
  VOR="VOR",
  NDB="NDB",
}
  
--- NAVFIX class version.
-- @field #string version
NAVFIX.version="0.0.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ToDo list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: A lot...

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new NAVFIX class instance.
-- @param #NAVFIX self
-- @param #string Name Name of the fix. Should be unique!
-- @param Core.Point#COORDINATE Coordinate of the fix.
-- @return #NAVFIX self
function NAVFIX:NewFromCoordinate(Name, Coordinate)

  -- Inherit everything from SCENERY class.
  self=BASE:Inherit(self, BASE:New()) -- #NAVFIX
  
  self.coordinate=Coordinate
  
  self.name=Name
  
  self.marker=MARKER:New(Coordinate, self:_GetMarkerText())
  self.marker:ToAll()

  return self
end

--- Create a new NAVFIX class instance from a given NavAid.
-- @param #NAVFIX self
-- @param #string Name Name of the fix. Should be unique!
-- @param Navigation.NavFix#NAVFIX NavFix The navigation fix.
-- @param #number Distance Distance in nautical miles. 
-- @param #number Bearing Bearing from the given NavFix to the newly created one.
-- @param #boolean Reciprocal If `true` the reciprocal `Bearing` is taken so it specifies the direction from the new navfix to the given one. 
-- @return #NAVFIX self
function NAVFIX:NewFromNavFix(Name, NavFix, Distance, Bearing, Reciprocal)

  local coord=NavFix.coordinate
  
  local Angle=Bearing-90
  
  local coord=NavFix.coordinate:Translate(UTILS.NMToMeters(Distance), Angle)
  
  local self=NAVFIX:NewFromCoordinate(coord, Name)
  

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set whether this is the intermediate fix (IF).
-- @param #NAVFIX self
-- @param #boolean IntermediateFix If `true`, this is an intermediate fix.
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
  text=text..string.format("\nAltitude: %s - %s", altmin, altmax)
  text=text..string.format("\nSpeed: %s - %s", speedmin, speedmax)
  text=text..string.format("\nCompulsory: %s", tostring(self.isCompulsory))
  text=text..string.format("\nFly Over: %s", tostring(self.isFlyover))    
  
  return text
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- NAVPOINT class.
-- @type NAVPOINT
-- 
-- @field #string ClassName Name of the class.
-- @field #number verbose Verbosity of output.
-- @field #string name Name of the point.
-- @field #string typePoint Type of the point, *e.g. "Intersection", "VOR", "Airport".
-- @field Core.Vector#VECTOR vector Position vector of the fix.
-- @field Wrapper.Marker#MARKER marker Marker on F10 map.
-- @field #number altMin Minimum altitude in meters.
-- @field #number altMax Maximum altitude in meters.
-- 
-- @field #boolean isCompulsory Is this a compulsory fix.
-- 
-- @extends Core.Base#BASE

--- *A fleet of British ships at war are the best negotiators.* -- Horatio Nelson
--
-- ===
--
-- # The NAVPOINT Concept
--
-- The NAVPOINT class has a great concept!
-- 
-- A NAVPOINT describes a geo position and can, *e.g.*, be part of a FLIGHTPLAN. It has a unique name and is of a certain type, *e.g.* "Intersection", "VOR", "Airbase" etc.
-- It can also have further properties as min/max altitudes and speeds that aircraft need to obey when they pass the point.
-- 
-- # Basic Setup
-- 
-- A new `NAVPOINT` object can be created with the @{#NAVPOINT.New}() function.
-- 
--     myNavPoint=NAVPOINT:New()
--     myTemplate:SetXYZ(X, Y, Z)
--     
-- This is how it works.
--
-- @field #NAVPOINT
NAVPOINT = {
  ClassName       = "NAVPOINT",
  verbose         =          0,
}

--- Type of point.
-- @type NAVPOINT.Type
-- @field #string VOR VOR
-- @field #string NDB NDB
NAVPOINT.Type={
  POINT="Point",
  INTERSECTION="Intersection",
  AIRPORT="Airport",
  VOR="VOR",
  DME="DME",
  VORDME="VOR/DME",
  LOC="Localizer",
  NDB="NDB",
}

--- NAVPOINT class version.
-- @field #string version
NAVPOINT.version="0.0.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ToDo list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: A lot...

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor(s)
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new NAVPOINT class instance from a given VECTOR.
-- @param #NAVPOINT self
-- @param #string Name Name of the point. Should be unique!
-- @param #string Type Type of the point. Default `NAVPOINT.Type.POINT`.
-- @param Core.Vector#VECTOR Vector Position vector of the navpoint.
-- @return #NAVPOINT self
function NAVPOINT:NewFromVector(Name, Type, Vector)

  -- Inherit everything from BASE class.
  self=BASE:Inherit(self, BASE:New()) -- #NAVFIX
  
  -- Vector of point.
  self.vector=Vector
  
  -- Name of point.
  self.name=Name
  
  self.typePoint=Type or NAVPOINT.Type.POINT
  
  -- Marker on F10.
  self.marker=MARKER:New(Vector:GetCoordinate(true), self:_GetMarkerText())
  
  
  --self.marker:ToAll()

  return self
end


--- Create a new NAVPOINT class instance from a given COORDINATE.
-- @param #NAVPOINT self
-- @param #string Name Name of the fix. Should be unique!
-- @param #string Type Type of the point. Default `NAVPOINT.Type.POINT`.
-- @param Core.Point#COORDINATE Coordinate Coordinate of the point.
-- @return #NAVPOINT self
function NAVPOINT:NewFromCoordinate(Name, Type, Coordinate)

  -- Create a VECTOR from the coordinate.
  local Vector=VECTOR:NewFromVec(Coordinate)
  
  -- Create NAVPOINT.
  self=NAVPOINT:NewFromVector(Name, Type, Vector)
  
  return self
end


--- Create a new NAVPOINT instance from given latitude and longitude in degrees, minutes and seconds (DMS).
-- @param #NAVPOINT self
-- @param #string Name Name of the fix. Should be unique!
-- @param #string Type Type of the point. Default `NAVPOINT.Type.POINT`.
-- @param #string Latitude Latitude in DMS as string.
-- @param #string Longitude Longitude in DMS as string.
-- @return #NAVPOINT self
function NAVPOINT:NewFromLLDMS(Name, Type, Latitude, Longitude)

  -- Create a VECTOR from the coordinate.
  local Vector=VECTOR:NewFromLLDMS(Latitude, Longitude)

  -- Create NAVPOINT.
  self=NAVPOINT:NewFromVector(Name, Type, Vector)
  
  return self  
end

--- Create a new NAVPOINT instance from given latitude and longitude in decimal degrees (DD).
-- @param #NAVPOINT self
-- @param #string Name Name of the fix. Should be unique!
-- @param #string Type Type of the point. Default `NAVPOINT.Type.POINT`.
-- @param #number Latitude Latitude in DD.
-- @param #number Longitude Longitude in DD.
-- @return #NAVPOINT self
function NAVPOINT:NewFromLLDD(Name, Type, Latitude, Longitude)

  -- Create a VECTOR from the coordinate.
  local Vector=VECTOR:NewFromLLDD(Latitude, Longitude)

  -- Create NAVPOINT.
  self=NAVPOINT:NewFromVector(Name, Type, Vector)
  
  return self  
end


--- Create a new NAVPOINT class instance relative to a given other NAVPOINT.
-- You have to specify the distance and bearing from the new point to the given point. *E.g.*, for a distance of 5 NM and a bearing of 090° (West), the
-- new nav point is created 5 NM East of the given nav point. The reason is that this corresponts to convention used in most maps.
-- You can, however, use the `Reciprocal` switch to create the new point in the direction you specify.
-- @param #NAVFIX self
-- @param #string Name Name of the fix. Should be unique!
-- @param Navigation.Point#NAVPOINT NavPoint The given/existing navigation point.
-- @param #number Distance Distance from the given to the new point in nautical miles. 
-- @param #number Bearing Bearing [Deg] from the new point to the given one.
-- @param #boolean Reciprocal If `true` the reciprocal `Bearing` is taken so it specifies the direction from the given point to the new one. 
-- @return #NAVFIX self
function NAVPOINT:NewFromNavPoint(Name, NavPoint, Distance, Bearing, Reciprocal)

  if Reciprocal then
    Bearing=Bearing-180
  end
  
  -- Translate.
  local Vector=NavPoint.vector:Translate(UTILS.NMToMeters(Distance), Bearing)
  
  self=NavPoint:NewFromVector(Name, Vector)
  
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set minimum altitude.
-- @param #NAVPOINT self
-- @param #number Altitude Min altitude in feet.
-- @return #NAVPOINT self
function NAVPOINT:SetAltMin(Altitude)

  self.altMin=Altitude

  return self
end

--- Set maximum altitude.
-- @param #NAVPOINT self
-- @param #number Altitude Max altitude in feet.
-- @return #NAVPOINT self
function NAVPOINT:SetAltMax(Altitude)

  self.altMax=Altitude

  return self
end

--- Set mandatory altitude (min alt = max alt).
-- @param #NAVPOINT self
-- @param #number Altitude Altitude in feet.
-- @return #NAVPOINT self
function NAVPOINT:SetAltMandatory(Altitude)

  self.altMin=Altitude
  self.altMax=Altitude

  return self
end

--- Set minimum speed.
-- @param #NAVPOINT self
-- @param #number Speed Min speed in knots.
-- @return #NAVPOINT self
function NAVPOINT:SetSpeedMin(Speed)

  self.speedMin=Speed

  return self
end

--- Set maximum speed.
-- @param #NAVPOINT self
-- @param #number Speed Max speed in knots.
-- @return #NAVPOINT self
function NAVPOINT:SetSpeedMax(Speed)

  self.speedMax=Speed

  return self
end

--- Set mandatory speed (min speed = max speed).
-- @param #NAVPOINT self
-- @param #number Altitude Mandatory speed in knots.
-- @return #NAVPOINT self
function NAVPOINT:SetSpeedMandatory(Speed)

  self.speedMin=Speed
  self.speedMax=Speed

  return self
end


--- Set whether this fix is compulsory.
-- @param #NAVPOINT self
-- @param #boolean Compulsory If `true`, this is a compusory fix. If `false` or nil, it is non-compulsory.
-- @return #NAVPOINT self
function NAVPOINT:SetCompulsory(Compulsory)
  self.isCompulsory=Compulsory
  return self
end

--- Set whether this is a fly-over fix fix.
-- @param #NAVPOINT self
-- @param #boolean FlyOver If `true`, this is a fly over fix. If `false` or nil, it is not.
-- @return #NAVPOINT self
function NAVPOINT:SetFlyOver(FlyOver)
  self.isFlyover=FlyOver
  return self
end


--- Get the altitude in feet MSL. If min and max altitudes are set, it will return a random altitude between min and max.
-- @param #NAVPOINT self
-- @return #number Altitude in feet MSL. Can be `nil`, if neither min nor max altitudes have beeen set. 
function NAVPOINT:GetAltitude()

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
-- @param #NAVPOINT self
-- @return #number Speed in knots. Can be `nil`, if neither min nor max speeds have beeen set. 
function NAVPOINT:GetSpeed()

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

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get text displayed in the F10 marker.
-- @param #NAVPOINT self
-- @return #string Marker text.
function NAVPOINT:_GetMarkerText()

  local altmin=self.altMin and tostring(self.altMin) or ""
  local altmax=self.altMax and tostring(self.altMax) or ""
  local speedmin=self.speedMin and tostring(self.speedMin) or ""
  local speedmax=self.speedMax and tostring(self.speedMax) or ""


  local text=string.format("NAVPOINT %s", self.name)
  if self.isIAF then
    text=text..string.format(" (IAF)")
  end
  if self.isIF then
    text=text..string.format(" (IF)")
  end
  text=text..string.format("\nAltitude: %s - %s", altmin, altmax)
  text=text..string.format("\nSpeed: %s - %s", speedmin, speedmax)
  text=text..string.format("\nCompulsory: %s", tostring(self.isCompulsory))
  text=text..string.format("\nFly Over: %s", tostring(self.isFlyover))
  
  return text
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
