--- **Navigation** - Navigation aid.
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
-- Demo missions can be found on [github](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/develop/Navigation%20-%20Navaid).
-- 
-- ===
--
-- ### Author: **funkyfranky**
-- 
-- ===
-- @module Navigation.Navaid
-- @image Navigation_Navaid.png


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
-- @field #string VOR VOR
-- @field #string NDB NDB
NAVAID.TYPE={
  VOR="VOR",
  NDB="NDB",
}
  
--- NAVAID class version.
-- @field #string version
NAVAID.version="0.0.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ToDo list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: A lot...

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

  -- Inherit everything from SCENERY class.
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


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
