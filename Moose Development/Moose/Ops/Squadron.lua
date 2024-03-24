--- **Ops** - Airwing Squadron.
--
-- **Main Features:**
--
--    * Set parameters like livery, skill valid for all squadron members.
--    * Define modex and callsigns.
--    * Define mission types, this squadron can perform (see Ops.Auftrag#AUFTRAG).
--    * Pause/unpause squadron operations.
--
-- ===
--
-- ### Author: **funkyfranky**
-- @module Ops.Squadron
-- @image OPS_Squadron.png


--- SQUADRON class.
-- @type SQUADRON
-- @field #string ClassName Name of the class.
-- @field #number verbose Verbosity level.
-- @field #string lid Class id string for output to DCS log file.
-- @field #string name Name of the squadron.
-- @field #string templatename Name of the template group.
-- @field #string aircrafttype Type of the airframe the squadron is using.
-- @field Wrapper.Group#GROUP templategroup Template group.
-- @field #number ngrouping User defined number of units in the asset group.
-- @field #table assets Squadron assets.
-- @field #table missiontypes Capabilities (mission types and performances) of the squadron.
-- @field #number fuellow Low fuel threshold.
-- @field #boolean fuellowRefuel If `true`, flight tries to refuel at the nearest tanker.
-- @field #number maintenancetime Time in seconds needed for maintenance of a returned flight.
-- @field #number repairtime Time in seconds for each
-- @field #string livery Livery of the squadron.
-- @field #number skill Skill of squadron members.
-- @field #number modex Modex.
-- @field #number modexcounter Counter to incease modex number for assets.
-- @field #string callsignName Callsign name.
-- @field #number callsigncounter Counter to increase callsign names for new assets.
-- @field #number Ngroups Number of asset flight groups this squadron has. 
-- @field #number engageRange Mission range in meters.
-- @field #string attribute Generalized attribute of the squadron template group.
-- @field #number tankerSystem For tanker squads, the refuel system used (boom=0 or probpe=1). Default nil.
-- @field #number refuelSystem For refuelable squads, the refuel system used (boom=0 or probe=1). Default nil.
-- @field #table tacanChannel List of TACAN channels available to the squadron.
-- @field #number radioFreq Radio frequency in MHz the squad uses.
-- @field #number radioModu Radio modulation the squad uses.
-- @field #string takeoffType Take of type.
-- @field #table parkingIDs Parking IDs for this squadron.
-- @field #boolean despawnAfterLanding Aircraft are despawned after landing.
-- @field #boolean despawnAfterHolding Aircraft are despawned after holding.
-- @extends Ops.Cohort#COHORT

--- *It is unbelievable what a squadron of twelve aircraft did to tip the balance* -- Adolf Galland
--
-- ===
--
-- # The SQUADRON Concept
-- 
-- A SQUADRON is essential part of an @{Ops.Airwing#AIRWING} and consists of **one** type of aircraft.
-- 
-- 
--
-- @field #SQUADRON
SQUADRON = {
  ClassName      = "SQUADRON",
  verbose        =     0,
  modex          =   nil,
  modexcounter   =     0,
  callsignName   =   nil,
  callsigncounter=    11,
  tankerSystem   =   nil,
  refuelSystem   =   nil,
}

--- SQUADRON class version.
-- @field #string version
SQUADRON.version="0.8.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- DONE: Parking spots for squadrons?
-- DONE: Engage radius.
-- DONE: Modex.
-- DONE: Call signs.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new SQUADRON object and start the FSM.
-- @param #SQUADRON self
-- @param #string TemplateGroupName Name of the template group.
-- @param #number Ngroups Number of asset groups of this squadron. Default 3.
-- @param #string SquadronName Name of the squadron, e.g. "VFA-37". Must be **unique**!
-- @return #SQUADRON self
function SQUADRON:New(TemplateGroupName, Ngroups, SquadronName)

  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, COHORT:New(TemplateGroupName, Ngroups, SquadronName)) -- #SQUADRON

  -- Everyone can ORBIT.
  self:AddMissionCapability(AUFTRAG.Type.ORBIT)
  
  -- Is air.
  self.isAir=true

  -- Refueling system.
  self.refuelSystem=select(2, self.templategroup:GetUnit(1):IsRefuelable())
  self.tankerSystem=select(2, self.templategroup:GetUnit(1):IsTanker())

  ------------------------
  --- Pseudo Functions ---
  ------------------------

  -- See COHORT class

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set number of units in groups.
-- @param #SQUADRON self
-- @param #number nunits Number of units. Must be >=1 and <=4. Default 2.
-- @return #SQUADRON self
function SQUADRON:SetGrouping(nunits)
  self.ngrouping=nunits or 2
  if self.ngrouping<1 then self.ngrouping=1 end
  if self.ngrouping>4 then self.ngrouping=4 end
  return self
end

--- Set valid parking spot IDs. Assets of this squad are only allowed to be spawned at these parking spots. **Note** that the IDs are different from the ones displayed in the mission editor!
-- @param #SQUADRON self
-- @param #table ParkingIDs Table of parking ID numbers or a single `#number`.
-- @return #SQUADRON self
function SQUADRON:SetParkingIDs(ParkingIDs)
  if type(ParkingIDs)~="table" then
    ParkingIDs={ParkingIDs}
  end
  self.parkingIDs=ParkingIDs
  return self
end


--- Set takeoff type. All assets of this squadron will be spawned with cold (default) or hot engines.
-- Spawning on runways is not supported.
-- @param #SQUADRON self
-- @param #string TakeoffType Take off type: "Cold" (default) or "Hot" with engines on or "Air" for spawning in air.
-- @return #SQUADRON self
function SQUADRON:SetTakeoffType(TakeoffType)
  TakeoffType=TakeoffType or "Cold"
  if TakeoffType:lower()=="hot" then
    self.takeoffType=COORDINATE.WaypointType.TakeOffParkingHot
  elseif TakeoffType:lower()=="cold" then
    self.takeoffType=COORDINATE.WaypointType.TakeOffParking
  elseif TakeoffType:lower()=="air" then
    self.takeoffType=COORDINATE.WaypointType.TurningPoint    
  else
    self.takeoffType=COORDINATE.WaypointType.TakeOffParking
  end
  return self
end

--- Set takeoff type cold (default). All assets of this squadron will be spawned with engines off (cold).
-- @param #SQUADRON self
-- @return #SQUADRON self
function SQUADRON:SetTakeoffCold()
  self:SetTakeoffType("Cold")
  return self
end

--- Set takeoff type hot. All assets of this squadron will be spawned with engines on (hot).
-- @param #SQUADRON self
-- @return #SQUADRON self
function SQUADRON:SetTakeoffHot()
  self:SetTakeoffType("Hot")
  return self
end

--- Set takeoff type air. All assets of this squadron will be spawned in air above the airbase.
-- @param #SQUADRON self
-- @return #SQUADRON self
function SQUADRON:SetTakeoffAir()
  self:SetTakeoffType("Air")
  return self
end

--- Set despawn after landing. Aircraft will be despawned after the landing event.
-- Can help to avoid DCS AI taxiing issues.
-- @param #SQUADRON self
-- @param #boolean Switch If `true` (default), activate despawn after landing.
-- @return #SQUADRON self
function SQUADRON:SetDespawnAfterLanding(Switch)
  if Switch then
    self.despawnAfterLanding=Switch
  else
    self.despawnAfterLanding=true
  end
  return self
end

--- Set despawn after holding. Aircraft will be despawned when they arrive at their holding position at the airbase.
-- Can help to avoid DCS AI taxiing issues.
-- @param #SQUADRON self
-- @param #boolean Switch If `true` (default), activate despawn after holding.
-- @return #SQUADRON self
function SQUADRON:SetDespawnAfterHolding(Switch)
  if Switch then
    self.despawnAfterHolding=Switch
  else
    self.despawnAfterHolding=true
  end
  return self
end


--- Set low fuel threshold.
-- @param #SQUADRON self
-- @param #number LowFuel Low fuel threshold in percent. Default 25.
-- @return #SQUADRON self
function SQUADRON:SetFuelLowThreshold(LowFuel)
  self.fuellow=LowFuel or 25
  return self
end

--- Set if low fuel threshold is reached, flight tries to refuel at the neares tanker.
-- @param #SQUADRON self
-- @param #boolean switch If true or nil, flight goes for refuelling. If false, turn this off.
-- @return #SQUADRON self
function SQUADRON:SetFuelLowRefuel(switch)
  if switch==false then
    self.fuellowRefuel=false
  else
    self.fuellowRefuel=true
  end
  return self
end

--- Set airwing.
-- @param #SQUADRON self
-- @param Ops.Airwing#AIRWING Airwing The airwing.
-- @return #SQUADRON self
function SQUADRON:SetAirwing(Airwing)
  self.legion=Airwing
  return self
end

--- Get airwing.
-- @param #SQUADRON self
-- @return Ops.Airwing#AIRWING The airwing.
function SQUADRON:GetAirwing(Airwing)
  return self.legion
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Start & Status
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after Start event. Starts the FLIGHTGROUP FSM and event handlers.
-- @param #SQUADRON self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function SQUADRON:onafterStart(From, Event, To)

  -- Short info.
  local text=string.format("Starting SQUADRON", self.name)
  self:T(self.lid..text)

  -- Start the status monitoring.
  self:__Status(-1)
end

--- On after "Status" event.
-- @param #SQUADRON self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function SQUADRON:onafterStatus(From, Event, To)

  if self.verbose>=1 then

    -- FSM state.
    local fsmstate=self:GetState()
  
    local callsign=self.callsignName and UTILS.GetCallsignName(self.callsignName) or "N/A"
    local modex=self.modex and self.modex or -1
    local skill=self.skill and tostring(self.skill) or "N/A"
    
    local NassetsTot=#self.assets
    local NassetsInS=self:CountAssets(true)
    local NassetsQP=0 ; local NassetsP=0 ; local NassetsQ=0  
    if self.legion then
      NassetsQP, NassetsP, NassetsQ=self.legion:CountAssetsOnMission(nil, self)
    end
    
    -- Short info.
    local text=string.format("%s [Type=%s, Call=%s, Modex=%d, Skill=%s]: Assets Total=%d, Stock=%d, Mission=%d [Active=%d, Queue=%d]", 
    fsmstate, self.aircrafttype, callsign, modex, skill, NassetsTot, NassetsInS, NassetsQP, NassetsP, NassetsQ)
    self:I(self.lid..text)
    
    -- Check if group has detected any units.
    self:_CheckAssetStatus()
    
  end  
  
  if not self:IsStopped() then
    self:__Status(-60)
  end
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

