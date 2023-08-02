--- **NAVIGATION** - Navigation Airspace Fix.
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
-- @module Navigation.NavFix
-- @image NAVIGATION_NavFix.png


--- NAVFIX class.
-- @type NAVFIX
-- @field #string ClassName Name of the class.
-- @field #number verbose Verbosity of output.
-- @field #string name Name of the fix.
-- @field Core.Point#COORDINATE coordinate Coordinate of the fix.
-- @field Wrapper.Marker#MARKER marker Marker of fix on F10 map.
-- @field #boolean isCompulsory Is this a compulsory fix.
-- @field #boolean isFlyover Is this a fly over fix.
-- @field #boolean isIAF Is initial approach fix (IAF). 
-- @field #boolean isIF Is intermediate fix (IF).
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
-- @return #NAVFIX self
function NAVFIX:New(Coordinate, Name)

  -- Inherit everything from SCENERY class.
  self=BASE:Inherit(self, BASE:New()) -- #NAVFIX
  
  self.coordinate=Coordinate
  
  self.name=Name
  
  self.marker=MARKER:New(Coordinate, self:_GetMarkerText())
  self.marker:ToAll()

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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

--- Set whether this fix is compulsory.
-- @param #NAVFIX self
-- @param #boolean Compulsory If `true`, this is a compusory fix. If `false` or nil, it is non-compulsory.
-- @return #NAVFIX self
function NAVFIX:SetCompulsory(Compulsory)
  self.isCompulsory=Compulsory
  return self
end

--- Set whether this fix is compulsory.
-- @param #NAVFIX self
-- @param #boolean FlyOver If `true`, this is a fly over fix. If `false` or nil, it is not.
-- @return #NAVFIX self
function NAVFIX:SetFlyOver(FlyOver)
  self.isFlyover=FlyOver
  return self
end

--- Set whether this is the intermediate fix.
-- @param #NAVFIX self
-- @param #boolean IntermediateFix If `true`, this is an intermediate fix.
-- @return #NAVFIX self
function NAVFIX:SetIntermediateFix(IntermediateFix)
  self.isIF=IntermediateFix
  return self
end

--- Set whether this is an initial approach fix (IAF).
-- @param #NAVFIX self
-- @param #boolean IntermediateFix If `true`, this is an intermediate fix.
-- @return #NAVFIX self
function NAVFIX:SetInitialApproachFix(IntermediateFix)
  self.isIAF=IntermediateFix
  return self
end

--- Get the altitude in feet MSL.
-- @param #NAVFIX self
-- @return #number Altitude in feet MSL. Can be `#nil`
function NAVFIX:GetAltitude()

  local alt=nil
  if self.altMin and self.altMax then
    alt=math.random(self.altMin, self.altMax)
  elseif self.altMin then
    alt=self.altMin
  elseif self.altMax then
    alt=self.altMax
  end

  return alt
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
