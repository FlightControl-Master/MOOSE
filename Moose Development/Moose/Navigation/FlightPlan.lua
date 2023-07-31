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

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new FLIGHTPLAN class instance.
-- @param #FLIGHTPLAN self
-- @param #string ZoneName Name of the zone to scan the scenery.
-- @param #string SceneryName Name of the scenery object.
-- @param #string Type Type of Navaid.
-- @return #FLIGHTPLAN self
function FLIGHTPLAN:New(ZoneName, SceneryName, Type)

  -- Inherit everything from SCENERY class.
  self=BASE:Inherit(self, BASE:New()) -- #FLIGHTPLAN


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
  self.lid=string.format("FLIGHTPLAN %s | ", self.alias)
  
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

--- Set channel.
-- @param #FLIGHTPLAN self
-- @param #number Channel
-- @param #string Band
-- @return #FLIGHTPLAN self
function FLIGHTPLAN:SetChannel(Channel, Band)

  self.channel=Channel
  self.band=Band

  return self
end

--- Add marker the FLIGHTPLAN on the F10 map.
-- @param #FLIGHTPLAN self
-- @return #FLIGHTPLAN self
function FLIGHTPLAN:AddMarker()

  local text=string.format("I am a FLIGHTPLAN!")
  
  self.markID=self.coordinate:MarkToAll(text, true)

  return self
end

--- Remove marker of the FLIGHTPLAN from the F10 map.
-- @param #FLIGHTPLAN self
-- @return #FLIGHTPLAN self
function FLIGHTPLAN:DelMarker()

  if self.markID then
    UTILS.RemoveMark(self.markID)
  end

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
