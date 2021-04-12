--- **Ops** - Enhanced Airborne Group.
--
-- ## Main Features:
--
--    * Monitor flight status of elements and/or the entire group
--    * Monitor fuel and ammo status
--    * Conveniently set radio freqencies, TACAN, ROE etc
--    * Order helos to land at specifc coordinates
--    * Dynamically add and remove waypoints
--    * Sophisticated task queueing system (know when DCS tasks start and end)
--    * Convenient checks when the group enters or leaves a zone
--    * Detection events for new, known and lost units
--    * Simple LASER and IR-pointer setup
--    * Compatible with AUFTRAG class
--    * Many additional events that the mission designer can hook into
--
-- ===
--
-- ## Example Missions:
-- 
-- Demo missions can be found on [github](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/develop/OPS%20-%20Flightgroup).
--    
-- ===
--
-- ### Author: **funkyfranky**
-- 
-- ===
-- @module Ops.FlightGroup
-- @image OPS_FlightGroup.png


--- FLIGHTGROUP class.
-- @type FLIGHTGROUP
-- @field Wrapper.Airbase#AIRBASE homebase The home base of the flight group.
-- @field Wrapper.Airbase#AIRBASE destbase The destination base of the flight group.
-- @field Core.Zone#ZONE homezone The home zone of the flight group. Set when spawn happens in air.
-- @field Core.Zone#ZONE destzone The destination zone of the flight group. Set when final waypoint is in air.
-- @field #string actype Type name of the aircraft.
-- @field #number rangemax Max range in km.
-- @field #number ceiling Max altitude the aircraft can fly at in meters.
-- @field #number tankertype The refueling system type (0=boom, 1=probe), if the group is a tanker.
-- @field #number refueltype The refueling system type (0=boom, 1=probe), if the group can refuel from a tanker.
-- @field Ops.OpsGroup#OPSGROUP.Ammo ammo Ammunition data. Number of Guns, Rockets, Bombs, Missiles.
-- @field #boolean ai If true, flight is purely AI. If false, flight contains at least one human player.
-- @field #boolean fuellow Fuel low switch.
-- @field #number fuellowthresh Low fuel threshold in percent.
-- @field #boolean fuellowrtb RTB on low fuel switch.
-- @field #boolean fuelcritical Fuel critical switch.
-- @field #number fuelcriticalthresh Critical fuel threshold in percent.
-- @field #boolean fuelcriticalrtb RTB on critical fuel switch.
-- @field Ops.Squadron#SQUADRON squadron The squadron of this flight group.
-- @field Ops.AirWing#AIRWING airwing The airwing the flight group belongs to.
-- @field Ops.FlightControl#FLIGHTCONTROL flightcontrol The flightcontrol handling this group.
-- @field Ops.Airboss#AIRBOSS airboss The airboss handling this group.
-- @field Core.UserFlag#USERFLAG flaghold Flag for holding.
-- @field #number Tholding Abs. mission time stamp when the group reached the holding point.
-- @field #number Tparking Abs. mission time stamp when the group was spawned uncontrolled and is parking.
-- @field #table menu F10 radio menu.
-- @field #string controlstatus Flight control status.
-- @field #boolean ishelo If true, the is a helicopter group.
-- @field #number callsignName Callsign name.
-- @field #number callsignNumber Callsign number.
-- @field #boolean despawnAfterLanding If true, group is despawned after landed at an airbase.
--
-- @extends Ops.OpsGroup#OPSGROUP

--- *To invent an airplane is nothing; to build one is something; to fly is everything.* -- Otto Lilienthal
--
-- ===
--
-- ![Banner Image](..\Presentations\OPS\FlightGroup\_Main.png)
--
-- # The FLIGHTGROUP Concept
--
-- # Events
--
-- This class introduces a lot of additional events that will be handy in many situations.
-- Certain events like landing, takeoff etc. are triggered for each element and also have a corresponding event when the whole group reaches this state.
--
-- ## Spawning
--
-- ## Parking
--
-- ## Taxiing
--
-- ## Takeoff
--
-- ## Airborne
--
-- ## Landed
--
-- ## Arrived
--
-- ## Dead
--
-- ## Fuel
--
-- ## Ammo
--
-- ## Detected Units
--
-- ## Check In Zone
--
-- ## Passing Waypoint
--
--
-- # Tasking
--
-- The FLIGHTGROUP class significantly simplifies the monitoring of DCS tasks. Two types of tasks can be set
--
--     * **Scheduled Tasks**
--     * **Waypoint Tasks**
--
-- ## Scheduled Tasks
--
-- ## Waypoint Tasks
--
-- # Examples
--
-- Here are some examples to show how things are done.
--
-- ## 1. Spawn
--
--
--
-- @field #FLIGHTGROUP
FLIGHTGROUP = {
  ClassName          = "FLIGHTGROUP",
  homebase           =   nil,
  destbase           =   nil,
  homezone           =   nil,
  destzone           =   nil,
  actype             =   nil,
  speedMax           =   nil,
  rangemax           =   nil,
  ceiling            =   nil,
  fuellow            = false,
  fuellowthresh      =   nil,
  fuellowrtb         =   nil,
  fuelcritical       =   nil,
  fuelcriticalthresh =   nil,
  fuelcriticalrtb    = false,
  outofAAMrtb        =  true,
  outofAGMrtb        =  true,
  squadron           =   nil,
  flightcontrol      =   nil,
  flaghold           =   nil,
  Tholding           =   nil,
  Tparking           =   nil,
  menu               =   nil,
  ishelo             =   nil,
  RTBRecallCount     =   0,
}


--- Generalized attribute. See [DCS attributes](https://wiki.hoggitworld.com/view/DCS_enum_attributes) on hoggit.
-- @type FLIGHTGROUP.Attribute
-- @field #string TRANSPORTPLANE Airplane with transport capability. This can be used to transport other assets.
-- @field #string AWACS Airborne Early Warning and Control System.
-- @field #string FIGHTER Fighter, interceptor, ... airplane.
-- @field #string BOMBER Aircraft which can be used for strategic bombing.
-- @field #string TANKER Airplane which can refuel other aircraft.
-- @field #string TRANSPORTHELO Helicopter with transport capability. This can be used to transport other assets.
-- @field #string ATTACKHELO Attack helicopter.
-- @field #string UAV Unpiloted Aerial Vehicle, e.g. drones.
-- @field #string OTHER Other aircraft type.
FLIGHTGROUP.Attribute = {
  TRANSPORTPLANE="TransportPlane",
  AWACS="AWACS",
  FIGHTER="Fighter",
  BOMBER="Bomber",
  TANKER="Tanker",
  TRANSPORTHELO="TransportHelo",
  ATTACKHELO="AttackHelo",
  UAV="UAV",
  OTHER="Other",
}

--- Flight group element.
-- @type FLIGHTGROUP.Element
-- @field #string name Name of the element, i.e. the unit/client.
-- @field Wrapper.Unit#UNIT unit Element unit object.
-- @field Wrapper.Group#GROUP group Group object of the element.
-- @field #string modex Tail number.
-- @field #string skill Skill level.
-- @field #boolean ai If true, element is AI.
-- @field Wrapper.Client#CLIENT client The client if element is occupied by a human player.
-- @field #table pylons Table of pylons.
-- @field #number fuelmass Mass of fuel in kg.
-- @field #number category Aircraft category.
-- @field #string categoryname Aircraft category name.
-- @field #string callsign Call sign, e.g. "Uzi 1-1".
-- @field #string status Status, i.e. born, parking, taxiing. See @{#OPSGROUP.ElementStatus}.
-- @field #number damage Damage of element in percent.
-- @field Wrapper.Airbase#AIRBASE.ParkingSpot parking The parking spot table the element is parking on.


--- FLIGHTGROUP class version.
-- @field #string version
FLIGHTGROUP.version="0.6.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: VTOL aircraft.
-- TODO: Use new UnitLost event instead of crash/dead.
-- TODO: Options EPLRS, Afterburner restrict etc.
-- DONE: Add TACAN beacon.
-- TODO: Damage?
-- TODO: shot events?
-- TODO: Marks to add waypoints/tasks on-the-fly.
-- TODO: Mark assigned parking spot on F10 map.
-- TODO: Let user request a parking spot via F10 marker :)
-- TODO: Monitor traveled distance in air ==> calculate fuel consumption ==> calculate range remaining. Will this give half way accurate results?
-- DONE: Out of AG/AA missiles. Safe state of out-of-ammo.
-- DONE: Add tasks.
-- DONE: Waypoints, read, add, insert, detour.
-- DONE: Get ammo.
-- DONE: Get pylons.
-- DONE: Fuel threshhold ==> RTB.
-- DONE: ROE
-- NOGO: Respawn? With correct loadout, fuelstate. Solved in DCS 2.5.6!

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new FLIGHTGROUP object and start the FSM.
-- @param #FLIGHTGROUP self
-- @param Wrapper.Group#GROUP group The group object. Can also be given by its group name as `#string`.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:New(group)

  -- First check if we already have a flight group for this group.
  local fg=_DATABASE:GetFlightGroup(group)
  if fg then
    fg:I(fg.lid..string.format("WARNING: Flight group already exists in data base!"))
    return fg
  end

  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, OPSGROUP:New(group)) -- #FLIGHTGROUP

  -- Set some string id for output to DCS.log file.
  self.lid=string.format("FLIGHTGROUP %s | ", self.groupname)

  -- Defaults
  --self:SetVerbosity(0)
  self:SetFuelLowThreshold()
  self:SetFuelLowRTB()
  self:SetFuelCriticalThreshold()
  self:SetFuelCriticalRTB()
  self:SetDefaultROE()
  self:SetDefaultROT()
  self:SetDetection()
  self.isFlightgroup=true

  -- Holding flag.
  self.flaghold=USERFLAG:New(string.format("%s_FlagHold", self.groupname))
  self.flaghold:Set(0)

  -- Add FSM transitions.
  --                 From State  -->   Event      -->      To State
  self:AddTransition("*",             "RTB",               "Inbound")     -- Group is returning to destination base.
  self:AddTransition("*",             "RTZ",               "Inbound")     -- Group is returning to destination zone. Not implemented yet!
  self:AddTransition("Inbound",       "Holding",           "Holding")     -- Group is in holding pattern.

  self:AddTransition("*",             "Refuel",            "Going4Fuel")  -- Group is send to refuel at a tanker.
  self:AddTransition("Going4Fuel",    "Refueled",          "Airborne")    -- Group finished refueling.

  self:AddTransition("*",             "LandAt",            "LandingAt")   -- Helo group is ordered to land at a specific point.
  self:AddTransition("LandingAt",     "LandedAt",          "LandedAt")    -- Helo group landed landed at a specific point.

  self:AddTransition("*",             "Wait",              "*")           -- Group is orbiting.

  self:AddTransition("*",             "FuelLow",           "*")          -- Fuel state of group is low. Default ~25%.
  self:AddTransition("*",             "FuelCritical",      "*")          -- Fuel state of group is critical. Default ~10%.

  self:AddTransition("*",             "OutOfMissilesAA",   "*")          -- Group is out of A2A missiles. 
  self:AddTransition("*",             "OutOfMissilesAG",   "*")          -- Group is out of A2G missiles. 
  self:AddTransition("*",             "OutOfMissilesAS",   "*")          -- Group is out of A2S(ship) missiles. Not implemented yet!

  self:AddTransition("Airborne",      "EngageTarget",     "Engaging")    -- Engage targets.
  self:AddTransition("Engaging",      "Disengage",        "Airborne")    -- Engagement over.

  self:AddTransition("*",             "ElementParking",   "*")           -- An element is parking.
  self:AddTransition("*",             "ElementEngineOn",  "*")           -- An element spooled up the engines.
  self:AddTransition("*",             "ElementTaxiing",   "*")           -- An element is taxiing to the runway.
  self:AddTransition("*",             "ElementTakeoff",   "*")           -- An element took off.
  self:AddTransition("*",             "ElementAirborne",  "*")           -- An element is airborne.
  self:AddTransition("*",             "ElementLanded",    "*")           -- An element landed.
  self:AddTransition("*",             "ElementArrived",   "*")           -- An element arrived.

  self:AddTransition("*",             "ElementOutOfAmmo", "*")           -- An element is completely out of ammo.

  self:AddTransition("*",             "Parking",          "Parking")     -- The whole flight group is parking.
  self:AddTransition("*",             "Taxiing",          "Taxiing")     -- The whole flight group is taxiing.
  self:AddTransition("*",             "Takeoff",          "Airborne")    -- The whole flight group is airborne.
  self:AddTransition("*",             "Airborne",         "Airborne")    -- The whole flight group is airborne.
  self:AddTransition("*",             "Landing",          "Landing")     -- The whole flight group is landing.
  self:AddTransition("*",             "Landed",           "Landed")      -- The whole flight group has landed.
  self:AddTransition("*",             "Arrived",          "Arrived")     -- The whole flight group has arrived.


  ------------------------
  --- Pseudo Functions ---
  ------------------------

  --- Triggers the FSM event "Stop". Stops the FLIGHTGROUP and all its event handlers.
  -- @param #FLIGHTGROUP self

  --- Triggers the FSM event "Stop" after a delay. Stops the FLIGHTGROUP and all its event handlers.
  -- @function [parent=#FLIGHTGROUP] __Stop
  -- @param #FLIGHTGROUP self
  -- @param #number delay Delay in seconds.

  -- TODO: Add pseudo functions.

  -- Debug trace.
  if false then
    BASE:TraceOnOff(true)
    BASE:TraceClass(self.ClassName)
    BASE:TraceLevel(1)
  end

  -- Add to data base.
  _DATABASE:AddFlightGroup(self)

  -- Handle events:
  self:HandleEvent(EVENTS.Birth,          self.OnEventBirth)
  self:HandleEvent(EVENTS.EngineStartup,  self.OnEventEngineStartup)
  self:HandleEvent(EVENTS.Takeoff,        self.OnEventTakeOff)
  self:HandleEvent(EVENTS.Land,           self.OnEventLanding)
  self:HandleEvent(EVENTS.EngineShutdown, self.OnEventEngineShutdown)
  self:HandleEvent(EVENTS.PilotDead,      self.OnEventPilotDead)
  self:HandleEvent(EVENTS.Ejection,       self.OnEventEjection)
  self:HandleEvent(EVENTS.Crash,          self.OnEventCrash)
  self:HandleEvent(EVENTS.RemoveUnit,     self.OnEventRemoveUnit)
  self:HandleEvent(EVENTS.UnitLost,       self.OnEventUnitLost)
  self:HandleEvent(EVENTS.Kill,           self.OnEventKill)

  -- Init waypoints.
  self:InitWaypoints()

  -- Initialize group.
  self:_InitGroup()

  -- Start the status monitoring.
  self:__Status(-1)
  
  -- Start queue update timer.
  self.timerQueueUpdate=TIMER:New(self._QueueUpdate, self):Start(2, 5)
  
  -- Start check zone timer.
  self.timerCheckZone=TIMER:New(self._CheckInZones, self):Start(3, 10)

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Add an *enroute* task to attack targets in a certain **circular** zone.
-- @param #FLIGHTGROUP self
-- @param Core.Zone#ZONE_RADIUS ZoneRadius The circular zone, where to engage targets.
-- @param #table TargetTypes (Optional) The target types, passed as a table, i.e. mind the curly brackets {}. Default {"Air"}.
-- @param #number Priority (Optional) Priority. Default 0.
function FLIGHTGROUP:AddTaskEnrouteEngageTargetsInZone(ZoneRadius, TargetTypes, Priority)
  local Task=self.group:EnRouteTaskEngageTargetsInZone(ZoneRadius:GetVec2(), ZoneRadius:GetRadius(), TargetTypes, Priority)
  self:AddTaskEnroute(Task)
end

--- Set AIRWING the flight group belongs to.
-- @param #FLIGHTGROUP self
-- @param Ops.AirWing#AIRWING airwing The AIRWING object.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:SetAirwing(airwing)
  self:T(self.lid..string.format("Add flight to AIRWING %s", airwing.alias))
  self.airwing=airwing
  return self
end

--- Get airwing the flight group belongs to.
-- @param #FLIGHTGROUP self
-- @return Ops.AirWing#AIRWING The AIRWING object.
function FLIGHTGROUP:GetAirWing()
  return self.airwing
end

--- Set the FLIGHTCONTROL controlling this flight group.
-- @param #FLIGHTGROUP self
-- @param Ops.FlightControl#FLIGHTCONTROL flightcontrol The FLIGHTCONTROL object.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:SetFlightControl(flightcontrol)

  -- Check if there is already a FC.
  if self.flightcontrol then
    if self.flightcontrol.airbasename==flightcontrol.airbasename then
      -- Flight control is already controlling this flight!
      return
    else
      -- Remove flight from previous FC.
      self.flightcontrol:_RemoveFlight(self)
    end
  end

  -- Set FC.
  self:I(self.lid..string.format("Setting FLIGHTCONTROL to airbase %s", flightcontrol.airbasename))
  self.flightcontrol=flightcontrol

  -- Add flight to all flights.
  table.insert(flightcontrol.flights, self)

  -- Update flight's F10 menu.
  if self.isAI==false then
    self:_UpdateMenu(0.5)
  end

  return self
end

--- Get the FLIGHTCONTROL controlling this flight group.
-- @param #FLIGHTGROUP self
-- @return Ops.FlightControl#FLIGHTCONTROL The FLIGHTCONTROL object.
function FLIGHTGROUP:GetFlightControl()
  return self.flightcontrol
end


--- Set the homebase.
-- @param #FLIGHTGROUP self
-- @param Wrapper.Airbase#AIRBASE HomeAirbase The home airbase.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:SetHomebase(HomeAirbase)
  self.homebase=HomeAirbase
  return self
end

--- Set the destination airbase. This is where the flight will go, when the final waypoint is reached.
-- @param #FLIGHTGROUP self
-- @param Wrapper.Airbase#AIRBASE DestinationAirbase The destination airbase.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:SetDestinationbase(DestinationAirbase)
  self.destbase=DestinationAirbase
  return self
end


--- Set the AIRBOSS controlling this flight group.
-- @param #FLIGHTGROUP self
-- @param Ops.Airboss#AIRBOSS airboss The AIRBOSS object.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:SetAirboss(airboss)
  self.airboss=airboss
  return self
end

--- Set low fuel threshold. Triggers event "FuelLow" and calls event function "OnAfterFuelLow".
-- @param #FLIGHTGROUP self
-- @param #number threshold Fuel threshold in percent. Default 25 %.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:SetFuelLowThreshold(threshold)
  self.fuellowthresh=threshold or 25
  return self
end

--- Set if low fuel threshold is reached, flight goes RTB.
-- @param #FLIGHTGROUP self
-- @param #boolean switch If true or nil, flight goes RTB. If false, turn this off.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:SetFuelLowRTB(switch)
  if switch==false then
    self.fuellowrtb=false
  else
    self.fuellowrtb=true
  end
  return self
end

--- Set if flight is out of Air-Air-Missiles, flight goes RTB.
-- @param #FLIGHTGROUP self
-- @param #boolean switch If true or nil, flight goes RTB. If false, turn this off.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:SetOutOfAAMRTB(switch)
  if switch==false then
    self.outofAAMrtb=false
  else
    self.outofAAMrtb=true
  end
  return self
end

--- Set if flight is out of Air-Ground-Missiles, flight goes RTB.
-- @param #FLIGHTGROUP self
-- @param #boolean switch If true or nil, flight goes RTB. If false, turn this off.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:SetOutOfAGMRTB(switch)
  if switch==false then
    self.outofAGMrtb=false
  else
    self.outofAGMrtb=true
  end
  return self
end

--- Set if low fuel threshold is reached, flight tries to refuel at the neares tanker.
-- @param #FLIGHTGROUP self
-- @param #boolean switch If true or nil, flight goes for refuelling. If false, turn this off.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:SetFuelLowRefuel(switch)
  if switch==false then
    self.fuellowrefuel=false
  else
    self.fuellowrefuel=true
  end
  return self
end

--- Set fuel critical threshold. Triggers event "FuelCritical" and event function "OnAfterFuelCritical".
-- @param #FLIGHTGROUP self
-- @param #number threshold Fuel threshold in percent. Default 10 %.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:SetFuelCriticalThreshold(threshold)
  self.fuelcriticalthresh=threshold or 10
  return self
end

--- Set if critical fuel threshold is reached, flight goes RTB.
-- @param #FLIGHTGROUP self
-- @param #boolean switch If true or nil, flight goes RTB. If false, turn this off.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:SetFuelCriticalRTB(switch)
  if switch==false then
    self.fuelcriticalrtb=false
  else
    self.fuelcriticalrtb=true
  end
  return self
end

--- Enable to automatically engage detected targets. 
-- @param #FLIGHTGROUP self
-- @param #number RangeMax Max range in NM. Only detected targets within this radius from the group will be engaged. Default is 25 NM.
-- @param #table TargetTypes Types of target attributes that will be engaged. See [DCS enum attributes](https://wiki.hoggitworld.com/view/DCS_enum_attributes). Default "All".
-- @param Core.Set#SET_ZONE EngageZoneSet Set of zones in which targets are engaged. Default is anywhere.
-- @param Core.Set#SET_ZONE NoEngageZoneSet Set of zones in which targets are *not* engaged. Default is nowhere.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:SetEngageDetectedOn(RangeMax, TargetTypes, EngageZoneSet, NoEngageZoneSet)

  -- Ensure table.
  if TargetTypes then
    if type(TargetTypes)~="table" then
      TargetTypes={TargetTypes}
    end
  else
    TargetTypes={"All"}
  end
  
  -- Ensure SET_ZONE if ZONE is provided.
  if EngageZoneSet and EngageZoneSet:IsInstanceOf("ZONE_BASE") then
    local zoneset=SET_ZONE:New():AddZone(EngageZoneSet)
    EngageZoneSet=zoneset
  end
  if NoEngageZoneSet and NoEngageZoneSet:IsInstanceOf("ZONE_BASE") then
    local zoneset=SET_ZONE:New():AddZone(NoEngageZoneSet)
    NoEngageZoneSet=zoneset
  end

  -- Set parameters.
  self.engagedetectedOn=true
  self.engagedetectedRmax=UTILS.NMToMeters(RangeMax or 25)
  self.engagedetectedTypes=TargetTypes
  self.engagedetectedEngageZones=EngageZoneSet
  self.engagedetectedNoEngageZones=NoEngageZoneSet

  -- Ensure detection is ON or it does not make any sense.
  self:SetDetection(true)

  return self
end

--- Disable to automatically engage detected targets. 
-- @param #FLIGHTGROUP self
-- @return #OPSGROUP self
function FLIGHTGROUP:SetEngageDetectedOff()
  self.engagedetectedOn=false
  return self
end


--- Enable that the group is despawned after landing. This can be useful to avoid DCS taxi issues with other AI or players or jamming taxiways.
-- @param #FLIGHTGROUP self
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:SetDespawnAfterLanding()
  self.despawnAfterLanding=true
  return self
end


--- Check if flight is parking.
-- @param #FLIGHTGROUP self
-- @return #boolean If true, flight is parking after spawned.
function FLIGHTGROUP:IsParking()
  return self:Is("Parking")
end

--- Check if flight is parking.
-- @param #FLIGHTGROUP self
-- @return #boolean If true, flight is taxiing after engine start up.
function FLIGHTGROUP:IsTaxiing()
  return self:Is("Taxiing")
end

--- Check if flight is airborne.
-- @param #FLIGHTGROUP self
-- @return #boolean If true, flight is airborne.
function FLIGHTGROUP:IsAirborne()
  return self:Is("Airborne")
end

--- Check if flight is waiting after passing final waypoint.
-- @param #FLIGHTGROUP self
-- @return #boolean If true, flight is waiting.
function FLIGHTGROUP:IsWaiting()
  return self:Is("Waiting")
end

--- Check if flight is landing.
-- @param #FLIGHTGROUP self
-- @return #boolean If true, flight is landing, i.e. on final approach.
function FLIGHTGROUP:IsLanding()
  return self:Is("Landing")
end

--- Check if flight has landed and is now taxiing to its parking spot.
-- @param #FLIGHTGROUP self
-- @return #boolean If true, flight has landed
function FLIGHTGROUP:IsLanded()
  return self:Is("Landed")
end

--- Check if flight has arrived at its destination parking spot.
-- @param #FLIGHTGROUP self
-- @return #boolean If true, flight has arrived at its destination and is parking.
function FLIGHTGROUP:IsArrived()
  return self:Is("Arrived")
end

--- Check if flight is inbound and traveling to holding pattern.
-- @param #FLIGHTGROUP self
-- @return #boolean If true, flight is holding.
function FLIGHTGROUP:IsInbound()
  return self:Is("Inbound")
end

--- Check if flight is holding and waiting for landing clearance.
-- @param #FLIGHTGROUP self
-- @return #boolean If true, flight is holding.
function FLIGHTGROUP:IsHolding()
  return self:Is("Holding")
end

--- Check if flight is going for fuel.
-- @param #FLIGHTGROUP self
-- @return #boolean If true, flight is refueling.
function FLIGHTGROUP:IsGoing4Fuel()
  return self:Is("Going4Fuel")
end

--- Check if helo(!) flight is ordered to land at a specific point.
-- @param #FLIGHTGROUP self
-- @return #boolean If true, group has task to land somewhere.
function FLIGHTGROUP:IsLandingAt()
  return self:Is("LandingAt")
end

--- Check if helo(!) flight is currently landed at a specific point.
-- @param #FLIGHTGROUP self
-- @return #boolean If true, group is currently landed at the assigned position and waiting until task is complete.
function FLIGHTGROUP:IsLandedAt()
  return self:Is("LandedAt")
end

--- Check if flight is low on fuel.
-- @param #FLIGHTGROUP self
-- @return #boolean If true, flight is low on fuel.
function FLIGHTGROUP:IsFuelLow()
  return self.fuellow
end

--- Check if flight is critical on fuel.
-- @param #FLIGHTGROUP self
-- @return #boolean If true, flight is critical on fuel.
function FLIGHTGROUP:IsFuelCritical()
  return self.fuelcritical
end

--- Check if flight can do air-to-ground tasks.
-- @param #FLIGHTGROUP self
-- @param #boolean ExcludeGuns If true, exclude gun
-- @return #boolean *true* if has air-to-ground weapons.
function FLIGHTGROUP:CanAirToGround(ExcludeGuns)
  local ammo=self:GetAmmoTot()
  if ExcludeGuns then
    return ammo.MissilesAG+ammo.Rockets+ammo.Bombs>0
  else
    return ammo.MissilesAG+ammo.Rockets+ammo.Bombs+ammo.Guns>0
  end
end

--- Check if flight can do air-to-air attacks.
-- @param #FLIGHTGROUP self
-- @param #boolean ExcludeGuns If true, exclude available gun shells.
-- @return #boolean *true* if has air-to-ground weapons.
function FLIGHTGROUP:CanAirToAir(ExcludeGuns)
  local ammo=self:GetAmmoTot()
  if ExcludeGuns then
    return ammo.MissilesAA>0
  else
    return ammo.MissilesAA+ammo.Guns>0
  end
end



--- Start an *uncontrolled* group.
-- @param #FLIGHTGROUP self
-- @param #number delay (Optional) Delay in seconds before the group is started. Default is immediately.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:StartUncontrolled(delay)

  if delay and delay>0 then
    self:T2(self.lid..string.format("Starting uncontrolled group in %d seconds", delay))
    self:ScheduleOnce(delay, FLIGHTGROUP.StartUncontrolled, self)
  else

    if self:IsAlive() then
      --TODO: check Alive==true and Alive==false ==> Activate first
      self:T(self.lid.."Starting uncontrolled group")
      self.group:StartUncontrolled(delay)
      self.isUncontrolled=true
    else
      self:E(self.lid.."ERROR: Could not start uncontrolled group as it is NOT alive!")
    end

  end

  return self
end

--- Clear the group for landing when it is holding.
-- @param #FLIGHTGROUP self
-- @param #number Delay Delay in seconds before landing clearance is given.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:ClearToLand(Delay)

  if Delay and Delay>0 then
    self:ScheduleOnce(Delay, FLIGHTGROUP.ClearToLand, self)
  else

    if self:IsHolding() then
      self:T(self.lid..string.format("Clear to land ==> setting holding flag to 1 (true)"))
      self.flaghold:Set(1)
    end

  end
  return self
end

--- Get min fuel of group. This returns the relative fuel amount of the element lowest fuel in the group.
-- @param #FLIGHTGROUP self
-- @return #number Relative fuel in percent.
function FLIGHTGROUP:GetFuelMin()

  local fuelmin=math.huge
  for i,_element in pairs(self.elements) do
    local element=_element --#FLIGHTGROUP.Element

    local unit=element.unit

    local life=unit:GetLife()

    if unit and unit:IsAlive() and life>1 then
      local fuel=unit:GetFuel()
      if fuel<fuelmin then
        fuelmin=fuel
      end
    end

  end

  return fuelmin*100
end

--- Get number of kills of this group.
-- @param #FLIGHTGROUP self
-- @return #number Number of units killed.
function FLIGHTGROUP:GetKills()
  return self.Nkills
end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Status
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

---- Update status.
-- @param #FLIGHTGROUP self
function FLIGHTGROUP:onbeforeStatus(From, Event, To)

  -- First we check if elements are still alive. Could be that they were despawned without notice, e.g. when landing on a too small airbase.
  for i,_element in pairs(self.elements) do
    local element=_element --#FLIGHTGROUP.Element
    
    -- Check that element is not already dead or not yet alive.
    if element.status~=OPSGROUP.ElementStatus.DEAD and element.status~=OPSGROUP.ElementStatus.INUTERO then
    
      -- Unit shortcut.
      local unit=element.unit
      
      local isdead=false      
      if unit and unit:IsAlive() then
      
        -- Get life points.
        local life=unit:GetLife() or 0
    
        -- Units with life <=1 are dead.
        if life<=1 then
          --env.info(string.format("FF unit %s: live<=1 in status at T=%.3f", unit:GetName(), timer.getTime()))
          isdead=true
        end
        
      else
        -- Not alive any more.
        --env.info(string.format("FF unit %s: NOT alive in status at T=%.3f", unit:GetName(), timer.getTime()))
        isdead=true
      end
      
      -- This one is dead.
      if isdead then
        local text=string.format("Element %s is dead at t=%.3f! Maybe despawned without notice or landed at a too small airbase. Calling ElementDead in 60 sec to give other events a chance", 
        tostring(element.name), timer.getTime())
        self:E(self.lid..text)
        self:__ElementDead(60, element)
      end
      
    end    
  end

  if self:IsDead() then  
    self:T(self.lid..string.format("Onbefore Status DEAD ==> false"))
    return false   
  elseif self:IsStopped() then
    self:T(self.lid..string.format("Onbefore Status STOPPED ==> false"))
    return false
  end

  return true
end

--- On after "Status" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterStatus(From, Event, To)

  -- FSM state.
  local fsmstate=self:GetState()
  
  -- Update position.
  self:_UpdatePosition()

  ---
  -- Detection
  ---

  -- Check if group has detected any units.
  if self.detectionOn then
    self:_CheckDetectedUnits()
  end

  ---
  -- Parking
  ---

  -- Check if flight began to taxi (if it was parking).
  if self:IsParking() then
    for _,_element in pairs(self.elements) do
      local element=_element --#FLIGHTGROUP.Element
      if element.parking then

        -- Get distance to assigned parking spot.
        local dist=element.unit:GetCoordinate():Get2DDistance(element.parking.Coordinate)

        -- If distance >10 meters, we consider the unit as taxiing.
        -- TODO: Check distance threshold! If element is taxiing, the parking spot is free again.
        --       When the next plane is spawned on this spot, collisions should be avoided!
        if dist>10 then
          if element.status==OPSGROUP.ElementStatus.ENGINEON then
            self:ElementTaxiing(element)
          end
        end

      else
        --self:E(self.lid..string.format("Element %s is in PARKING queue but has no parking spot assigned!", element.name))
      end
    end
  end

  ---
  -- Group
  ---

  -- Short info.
  if self.verbose>=1 then
  
    local nTaskTot, nTaskSched, nTaskWP=self:CountRemainingTasks()
    local nMissions=self:CountRemainingMissison()
  
  
    local text=string.format("Status %s [%d/%d]: Tasks=%d (%d,%d) Curr=%d, Missions=%s, Waypoint=%d/%d, Detected=%d, Home=%s, Destination=%s",
    fsmstate, #self.elements, #self.elements, nTaskTot, nTaskSched, nTaskWP, self.taskcurrent, nMissions, self.currentwp or 0, self.waypoints and #self.waypoints or 0,
    self.detectedunits:Count(), self.homebase and self.homebase:GetName() or "unknown", self.destbase and self.destbase:GetName() or "unknown")
    self:I(self.lid..text)
    
  end

  ---
  -- Elements
  ---
  
  if self.verbose>=2 then
    local text="Elements:"
    for i,_element in pairs(self.elements) do
      local element=_element --#FLIGHTGROUP.Element

      local name=element.name
      local status=element.status
      local unit=element.unit
      local fuel=unit:GetFuel() or 0
      local life=unit:GetLifeRelative() or 0
      local parking=element.parking and tostring(element.parking.TerminalID) or "X"

      -- Check if element is not dead and we missed an event.
      --if life<=0 and element.status~=OPSGROUP.ElementStatus.DEAD and element.status~=OPSGROUP.ElementStatus.INUTERO then
      --  self:ElementDead(element)
      --end

      -- Get ammo.
      local ammo=self:GetAmmoElement(element)

      -- Output text for element.
      text=text..string.format("\n[%d] %s: status=%s, fuel=%.1f, life=%.1f, guns=%d, rockets=%d, bombs=%d, missiles=%d (AA=%d, AG=%d, AS=%s), parking=%s",
      i, name, status, fuel*100, life*100, ammo.Guns, ammo.Rockets, ammo.Bombs, ammo.Missiles, ammo.MissilesAA, ammo.MissilesAG, ammo.MissilesAS, parking)
    end
    if #self.elements==0 then
      text=text.." none!"
    end
    self:I(self.lid..text)
  end

  ---
  -- Distance travelled
  ---

  if self.verbose>=4 and self:IsAlive() then

    -- Travelled distance since last check.
    local ds=self.travelds

    -- Time interval.
    local dt=self.dTpositionUpdate

    -- Speed.
    local v=ds/dt


    -- Max fuel time remaining.
    local TmaxFuel=math.huge

    for _,_element in pairs(self.elements) do
      local element=_element --#FLIGHTGROUP.Element

      -- Get relative fuel of element.
      local fuel=element.unit:GetFuel() or 0

      -- Relative fuel used since last check.
      local dFrel=element.fuelrel-fuel

      -- Relative fuel used per second.
      local dFreldt=dFrel/dt

      -- Fuel remaining in seconds.
      local Tfuel=fuel/dFreldt

      if Tfuel<TmaxFuel then
        TmaxFuel=Tfuel
      end

      -- Element consumption.
      self:T3(self.lid..string.format("Fuel consumption %s F=%.1f: dF=%.3f  dF/min=%.3f ==> Tfuel=%.1f min", element.name, fuel*100, dFrel*100, dFreldt*100*60, Tfuel/60))

      -- Store rel fuel.
      element.fuelrel=fuel
    end

    -- Log outut.
    self:I(self.lid..string.format("Travelled ds=%.1f km dt=%.1f s ==> v=%.1f knots. Fuel left for %.1f min", self.traveldist/1000, dt, UTILS.MpsToKnots(v), TmaxFuel/60))
    
  end

  ---
  -- Tasks & Missions
  ---

  self:_PrintTaskAndMissionStatus()

  ---
  -- Fuel State
  ---

  -- Only if group is in air.
  if self:IsAlive() and self.group:IsAirborne(true) then

    local fuelmin=self:GetFuelMin()

    if fuelmin>=self.fuellowthresh then
      self.fuellow=false
    end

    if fuelmin>=self.fuelcriticalthresh then
      self.fuelcritical=false
    end


    -- Low fuel?
    if fuelmin<self.fuellowthresh and not self.fuellow then
      self:FuelLow()
    end

    -- Critical fuel?
    if fuelmin<self.fuelcriticalthresh and not self.fuelcritical then
      self:FuelCritical()
    end
    
    -- Out of AA Missiles? CAP, GCICAP, INTERCEPT
    local CurrIsCap = false
    -- Out of AG Missiles? BAI, SEAD, CAS, STRIKE
    local CurrIsA2G = false
    -- Check AUFTRAG Type
    local CurrAuftrag = self:GetMissionCurrent()
    if CurrAuftrag then 
      local CurrAuftragType = CurrAuftrag:GetType()
      if CurrAuftragType == "CAP" or CurrAuftragType == "GCICAP" or CurrAuftragType == "INTERCEPT" then CurrIsCap = true end
      if CurrAuftragType == "BAI" or CurrAuftragType == "CAS" or CurrAuftragType == "SEAD" or CurrAuftragType == "STRIKE"  then CurrIsA2G = true end
    end
    
    -- Check A2A
    if (not self:CanAirToAir(true)) and CurrIsCap then
      self:OutOfMissilesAA()
    end
    
    -- Check A2G
    if (not self:CanAirToGround(false)) and CurrIsA2G then
      self:OutOfMissilesAG()
    end

  end

  ---
  -- Airboss Helo
  ---
  if self.ishelo and self.airboss and self:IsHolding() then
    if self.airboss:IsRecovering() or self:IsFuelCritical() then
      self:ClearToLand()
    end
  end

  ---
  -- Engage Detected Targets
  ---  
  if self:IsAirborne() and self.detectionOn and self.engagedetectedOn and not (self.fuellow or self.fuelcritical) then
  
    -- Target.
    local targetgroup=nil --Wrapper.Group#GROUP
    local targetdist=math.huge
    
    -- Loop over detected groups.
    for _,_group in pairs(self.detectedgroups:GetSet()) do
      local group=_group --Wrapper.Group#GROUP
      
      if group and group:IsAlive() then
      
        -- Get 3D vector of target.
        local targetVec3=group:GetVec3()

        -- Distance to target.        
        local distance=UTILS.VecDist3D(self.position, targetVec3)
        
        if distance<=self.engagedetectedRmax and distance<targetdist then
        
          -- Check type attribute.
          local righttype=false
          for _,attribute in pairs(self.engagedetectedTypes) do
            local gotit=group:HasAttribute(attribute, false)
            --self:I(self.lid..string.format("Group %s has attribute %s = %s", group:GetName(), attribute, tostring(gotit)))
            if gotit then
              righttype=true
              break
            end
          end
          
          -- We got the right type.
          if righttype then
        
            local insideEngage=true
            local insideNoEngage=false
            
            -- Check engage zones.
            if self.engagedetectedEngageZones then
              insideEngage=false
              for _,_zone in pairs(self.engagedetectedEngageZones.Set) do
                local zone=_zone --Core.Zone#ZONE
                local inzone=zone:IsVec3InZone(targetVec3)
                if inzone then
                  insideEngage=true
                  break
                end             
              end
            end
          
            -- Check no engage zones.
            if self.engagedetectedNoEngageZones then
              for _,_zone in pairs(self.engagedetectedNoEngageZones.Set) do
                local zone=_zone --Core.Zone#ZONE
                local inzone=zone:IsVec3InZone(targetVec3)
                if inzone then
                  insideNoEngage=true
                  break
                end
              end
            end
            
            -- If inside engage but not inside no engage zones.
            if insideEngage and not insideNoEngage then
              targetdist=distance
              targetgroup=group
            end
            
          end
          
        end        
      end
    end
    
    -- If we found a group, we engage it.
    if targetgroup then
      --self:I(self.lid..string.format("Engaging target group %s at distance %d meters", targetgroup:GetName(), targetdist))
      self:EngageTarget(targetgroup)
    end
  
  end


  -- Next check in ~30 seconds.
  if not self:IsStopped() then
    self:__Status(-30)
  end
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Events
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Flightgroup event function, handling the birth of a unit.
-- @param #FLIGHTGROUP self
-- @param Core.Event#EVENTDATA EventData Event data.
function FLIGHTGROUP:OnEventBirth(EventData)

  --env.info(string.format("EVENT: Birth for unit %s", tostring(EventData.IniUnitName)))

  -- Check that this is the right group.
  if EventData and EventData.IniGroup and EventData.IniUnit and EventData.IniGroupName and EventData.IniGroupName==self.groupname then
    local unit=EventData.IniUnit
    local group=EventData.IniGroup
    local unitname=EventData.IniUnitName

    -- Set group.
    self.group=self.group or EventData.IniGroup

    if self.respawning then

      local function reset()
        self.respawning=nil
      end

      -- Reset switch in 1 sec. This should allow all birth events of n>1 groups to have passed.
      -- TODO: Can I do this more rigorously?
      self:ScheduleOnce(1, reset)

    else

      -- Set homebase if not already set.
      if EventData.Place then
        self.homebase=self.homebase or EventData.Place
      end
      
      if self.homebase and not self.destbase then
        self.destbase=self.homebase
      end

      -- Get element.
      local element=self:GetElementByName(unitname)

      -- Create element spawned event if not already present.
      if not self:_IsElement(unitname) then
        element=self:AddElementByName(unitname)
      end

      -- Set element to spawned state.
      self:T(self.lid..string.format("EVENT: Element %s born at airbase %s==> spawned", element.name, self.homebase and self.homebase:GetName() or "unknown"))
      -- This is delayed by a millisec because inAir check for units spawned in air failed (returned false even though the unit was spawned in air).
      self:__ElementSpawned(0.0, element)

    end

  end

end

--- Flightgroup event function handling the crash of a unit.
-- @param #FLIGHTGROUP self
-- @param Core.Event#EVENTDATA EventData Event data.
function FLIGHTGROUP:OnEventEngineStartup(EventData)

  -- Check that this is the right group.
  if EventData and EventData.IniGroup and EventData.IniUnit and EventData.IniGroupName and EventData.IniGroupName==self.groupname then
    local unit=EventData.IniUnit
    local group=EventData.IniGroup
    local unitname=EventData.IniUnitName

    -- Get element.
    local element=self:GetElementByName(unitname)

    if element then

      if self:IsAirborne() or self:IsInbound() or self:IsHolding() then
        -- TODO: what?
      else
        self:T3(self.lid..string.format("EVENT: Element %s started engines ==> taxiing (if AI)", element.name))
        -- TODO: could be that this element is part of a human flight group.
        -- Problem: when player starts hot, the AI does too and starts to taxi immidiately :(
        --          when player starts cold, ?
        if self.isAI then
          self:ElementEngineOn(element)
        else
          if element.ai then
            -- AI wingmen will start taxiing even if the player/client is still starting up his engines :(
            self:ElementEngineOn(element)
          end
        end
      end

    end

  end

end

--- Flightgroup event function handling the crash of a unit.
-- @param #FLIGHTGROUP self
-- @param Core.Event#EVENTDATA EventData Event data.
function FLIGHTGROUP:OnEventTakeOff(EventData)

  -- Check that this is the right group.
  if EventData and EventData.IniGroup and EventData.IniUnit and EventData.IniGroupName and EventData.IniGroupName==self.groupname then
    local unit=EventData.IniUnit
    local group=EventData.IniGroup
    local unitname=EventData.IniUnitName

    -- Get element.
    local element=self:GetElementByName(unitname)

    if element then
      self:T3(self.lid..string.format("EVENT: Element %s took off ==> airborne", element.name))
      self:ElementTakeoff(element, EventData.Place)
    end

  end

end

--- Flightgroup event function handling the crash of a unit.
-- @param #FLIGHTGROUP self
-- @param Core.Event#EVENTDATA EventData Event data.
function FLIGHTGROUP:OnEventLanding(EventData)

  -- Check that this is the right group.
  if EventData and EventData.IniGroup and EventData.IniUnit and EventData.IniGroupName and EventData.IniGroupName==self.groupname then
    local unit=EventData.IniUnit
    local group=EventData.IniGroup
    local unitname=EventData.IniUnitName

    -- Get element.
    local element=self:GetElementByName(unitname)

    local airbase=EventData.Place

    local airbasename="unknown"
    if airbase then
      airbasename=tostring(airbase:GetName())
    end

    if element then
      self:T3(self.lid..string.format("EVENT: Element %s landed at %s ==> landed", element.name, airbasename))
      self:ElementLanded(element, airbase)
    end

  end

end

--- Flightgroup event function handling the crash of a unit.
-- @param #FLIGHTGROUP self
-- @param Core.Event#EVENTDATA EventData Event data.
function FLIGHTGROUP:OnEventEngineShutdown(EventData)

  -- Check that this is the right group.
  if EventData and EventData.IniGroup and EventData.IniUnit and EventData.IniGroupName and EventData.IniGroupName==self.groupname then
    local unit=EventData.IniUnit
    local group=EventData.IniGroup
    local unitname=EventData.IniUnitName

    -- Get element.
    local element=self:GetElementByName(unitname)

    if element then

      if element.unit and element.unit:IsAlive() then

        local airbase=self:GetClosestAirbase()
        local parking=self:GetParkingSpot(element, 10, airbase)

        if airbase and parking then
          self:ElementArrived(element, airbase, parking)
          self:T3(self.lid..string.format("EVENT: Element %s shut down engines ==> arrived", element.name))
        else
          self:T3(self.lid..string.format("EVENT: Element %s shut down engines but is not parking. Is it dead?", element.name))
        end

      else
        --self:I(self.lid..string.format("EVENT: Element %s shut down engines but is NOT alive ==> waiting for crash event (==> dead)", element.name))
      end

    end -- element nil?

  end

end


--- Flightgroup event function handling the crash of a unit.
-- @param #FLIGHTGROUP self
-- @param Core.Event#EVENTDATA EventData Event data.
function FLIGHTGROUP:OnEventCrash(EventData)

  -- Check that this is the right group.
  if EventData and EventData.IniGroup and EventData.IniUnit and EventData.IniGroupName and EventData.IniGroupName==self.groupname then
    local unit=EventData.IniUnit
    local group=EventData.IniGroup
    local unitname=EventData.IniUnitName

    -- Get element.
    local element=self:GetElementByName(unitname)

    if element and element.status~=OPSGROUP.ElementStatus.DEAD then
      self:T(self.lid..string.format("EVENT: Element %s crashed ==> destroyed", element.name))      
      self:ElementDestroyed(element)
    end

  end

end

--- Flightgroup event function handling the crash of a unit.
-- @param #FLIGHTGROUP self
-- @param Core.Event#EVENTDATA EventData Event data.
function FLIGHTGROUP:OnEventUnitLost(EventData)

  -- Check that this is the right group.
  if EventData and EventData.IniGroup and EventData.IniUnit and EventData.IniGroupName and EventData.IniGroupName==self.groupname then
    self:T2(self.lid..string.format("EVENT: Unit %s lost at t=%.3f", EventData.IniUnitName, timer.getTime()))
    
    local unit=EventData.IniUnit
    local group=EventData.IniGroup
    local unitname=EventData.IniUnitName

    -- Get element.
    local element=self:GetElementByName(unitname)

    if element and element.status~=OPSGROUP.ElementStatus.DEAD then
      self:T(self.lid..string.format("EVENT: Element %s unit lost ==> destroyed t=%.3f", element.name, timer.getTime()))
      self:ElementDestroyed(element)
    end
    
  end

end

--- Flightgroup event function handling the crash of a unit.
-- @param #FLIGHTGROUP self
-- @param Core.Event#EVENTDATA EventData Event data.
function FLIGHTGROUP:OnEventKill(EventData)

  -- Check that this is the right group.
  if EventData and EventData.IniGroup and EventData.IniUnit and EventData.IniGroupName and EventData.IniGroupName==self.groupname then
  
    -- Target name
    local targetname=tostring(EventData.TgtUnitName)
  
    -- Debug info.
    self:T2(self.lid..string.format("EVENT: Unit %s killed object %s!", tostring(EventData.IniUnitName), targetname))
    
    -- Check if this was a UNIT or STATIC object.
    local target=UNIT:FindByName(targetname)    
    if not target then
      target=STATIC:FindByName(targetname, false)
    end

    -- Only count UNITS and STATICs (not SCENERY)
    if target then

      -- Debug info.
      self:T(self.lid..string.format("EVENT: Unit %s killed unit/static %s!", tostring(EventData.IniUnitName), targetname))

      -- Kill counter.
      self.Nkills=self.Nkills+1
      
      -- Check if on a mission.
      local mission=self:GetMissionCurrent()
      if mission then
        mission.Nkills=mission.Nkills+1 -- Increase mission kill counter.
      end
      
    end
    
  end

end

--- Flightgroup event function handling the crash of a unit.
-- @param #FLIGHTGROUP self
-- @param Core.Event#EVENTDATA EventData Event data.
function FLIGHTGROUP:OnEventRemoveUnit(EventData)

  -- Check that this is the right group.
  if EventData and EventData.IniGroup and EventData.IniUnit and EventData.IniGroupName and EventData.IniGroupName==self.groupname then
    local unit=EventData.IniUnit
    local group=EventData.IniGroup
    local unitname=EventData.IniUnitName

    -- Get element.
    local element=self:GetElementByName(unitname)

    if element then
      self:T3(self.lid..string.format("EVENT: Element %s removed ==> dead", element.name))
      self:ElementDead(element)
    end

  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after "ElementSpawned" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #FLIGHTGROUP.Element Element The flight group element.
function FLIGHTGROUP:onafterElementSpawned(From, Event, To, Element)
  self:T(self.lid..string.format("Element spawned %s", Element.name))

  -- Set element status.
  self:_UpdateStatus(Element, OPSGROUP.ElementStatus.SPAWNED)

  if Element.unit:InAir(true) then
    -- Trigger ElementAirborne event. Add a little delay because spawn is also delayed!
    self:__ElementAirborne(0.11, Element)
  else

    -- Get parking spot.
    local spot=self:GetParkingSpot(Element, 10)

    if spot then

      -- Trigger ElementParking event. Add a little delay because spawn is also delayed!
      self:__ElementParking(0.11, Element, spot)

    else
      -- TODO: This can happen if spawned on deck of a carrier!
      self:T(self.lid..string.format("Element spawned not in air but not on any parking spot."))
      self:__ElementParking(0.11, Element)
    end
  end
end

--- On after "ElementParking" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #FLIGHTGROUP.Element Element The flight group element.
-- @param Wrapper.Airbase#AIRBASE.ParkingSpot Spot Parking Spot.
function FLIGHTGROUP:onafterElementParking(From, Event, To, Element, Spot)
  self:T(self.lid..string.format("Element parking %s at spot %s", Element.name, Element.parking and tostring(Element.parking.TerminalID) or "N/A"))

  -- Set element status.
  self:_UpdateStatus(Element, OPSGROUP.ElementStatus.PARKING)

  if Spot then
    self:_SetElementParkingAt(Element, Spot)
  end

  if self:IsTakeoffCold() then
    -- Wait for engine startup event.
  elseif self:IsTakeoffHot() then
    self:__ElementEngineOn(0.5, Element)  -- delay a bit to allow all elements
  elseif self:IsTakeoffRunway() then
    self:__ElementEngineOn(0.5, Element)
  end
end

--- On after "ElementEngineOn" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #FLIGHTGROUP.Element Element The flight group element.
function FLIGHTGROUP:onafterElementEngineOn(From, Event, To, Element)

  -- Debug info.
  self:T(self.lid..string.format("Element %s started engines", Element.name))

  -- Set element status.
  self:_UpdateStatus(Element, OPSGROUP.ElementStatus.ENGINEON)
end

--- On after "ElementTaxiing" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #FLIGHTGROUP.Element Element The flight group element.
function FLIGHTGROUP:onafterElementTaxiing(From, Event, To, Element)

  -- Get terminal ID.
  local TerminalID=Element.parking and tostring(Element.parking.TerminalID) or "N/A"

  -- Debug info.
  self:T(self.lid..string.format("Element taxiing %s. Parking spot %s is now free", Element.name, TerminalID))

  -- Set parking spot to free. Also for FC.
  self:_SetElementParkingFree(Element)

  -- Set element status.
  self:_UpdateStatus(Element, OPSGROUP.ElementStatus.TAXIING)
end

--- On after "ElementTakeoff" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #FLIGHTGROUP.Element Element The flight group element.
-- @param Wrapper.Airbase#AIRBASE airbase The airbase if applicable or nil.
function FLIGHTGROUP:onafterElementTakeoff(From, Event, To, Element, airbase)
  self:T(self.lid..string.format("Element takeoff %s at %s airbase.", Element.name, airbase and airbase:GetName() or "unknown"))

  -- Helos with skids just take off without taxiing!
  if Element.parking then
    self:_SetElementParkingFree(Element)
  end

  -- Set element status.
  self:_UpdateStatus(Element, OPSGROUP.ElementStatus.TAKEOFF, airbase)

  -- Trigger element airborne event.
  self:__ElementAirborne(2, Element)
end

--- On after "ElementAirborne" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #FLIGHTGROUP.Element Element The flight group element.
function FLIGHTGROUP:onafterElementAirborne(From, Event, To, Element)
  self:T2(self.lid..string.format("Element airborne %s", Element.name))

  -- Set element status.
  self:_UpdateStatus(Element, OPSGROUP.ElementStatus.AIRBORNE)
end

--- On after "ElementLanded" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #FLIGHTGROUP.Element Element The flight group element.
-- @param Wrapper.Airbase#AIRBASE airbase The airbase if applicable or nil.
function FLIGHTGROUP:onafterElementLanded(From, Event, To, Element, airbase)
  self:T2(self.lid..string.format("Element landed %s at %s airbase", Element.name, airbase and airbase:GetName() or "unknown"))
  
  if self.despawnAfterLanding then
  
    -- Despawn the element.
    self:DespawnElement(Element)
  
  else

    -- Helos with skids land directly on parking spots.
    if self.ishelo then
  
      local Spot=self:GetParkingSpot(Element, 10, airbase)
  
      self:_SetElementParkingAt(Element, Spot)
  
    end
  
    -- Set element status.
    self:_UpdateStatus(Element, OPSGROUP.ElementStatus.LANDED, airbase)
    
  end
end

--- On after "ElementArrived" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #FLIGHTGROUP.Element Element The flight group element.
-- @param Wrapper.Airbase#AIRBASE airbase The airbase, where the element arrived.
-- @param Wrapper.Airbase#AIRBASE.ParkingSpot Parking The Parking spot the element has.
function FLIGHTGROUP:onafterElementArrived(From, Event, To, Element, airbase, Parking)
  self:T(self.lid..string.format("Element arrived %s at %s airbase using parking spot %d", Element.name, airbase and airbase:GetName() or "unknown", Parking and Parking.TerminalID or -99))

  self:_SetElementParkingAt(Element, Parking)

  -- Set element status.
  self:_UpdateStatus(Element, OPSGROUP.ElementStatus.ARRIVED)
end

--- On after "ElementDestroyed" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #FLIGHTGROUP.Element Element The flight group element.
function FLIGHTGROUP:onafterElementDestroyed(From, Event, To, Element)

  -- Call OPSGROUP function.
  self:GetParent(self).onafterElementDestroyed(self, From, Event, To, Element)
  
end

--- On after "ElementDead" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #FLIGHTGROUP.Element Element The flight group element.
function FLIGHTGROUP:onafterElementDead(From, Event, To, Element)

  -- Call OPSGROUP function.
  self:GetParent(self).onafterElementDead(self, From, Event, To, Element)

  if self.flightcontrol and Element.parking then
    self.flightcontrol:SetParkingFree(Element.parking)
  end

  -- Not parking any more.
  Element.parking=nil
  
end


--- On after "Spawned" event. Sets the template, initializes the waypoints.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterSpawned(From, Event, To)
  self:T(self.lid..string.format("Flight spawned"))

  -- Update position.  
  self:_UpdatePosition()

  if self.isAI then

    -- Set ROE.
    self:SwitchROE(self.option.ROE)

    -- Set ROT.
    self:SwitchROT(self.option.ROT)
    
    -- Set Formation
    self:SwitchFormation(self.option.Formation)
        
    -- Set TACAN beacon.
    self:_SwitchTACAN()
    
    -- Set radio freq and modu.
    if self.radioDefault then
      self:SwitchRadio()
    else
      self:SetDefaultRadio(self.radio.Freq, self.radio.Modu, self.radio.On)
    end
    
    -- Set callsign.
    if self.callsignDefault then
      self:SwitchCallsign(self.callsignDefault.NumberSquad, self.callsignDefault.NumberGroup)
    else
      self:SetDefaultCallsign(self.callsign.NumberSquad, self.callsign.NumberGroup)
    end
    
    -- TODO: make this input.
    self:GetGroup():SetOption(AI.Option.Air.id.PROHIBIT_JETT, true)
    self:GetGroup():SetOption(AI.Option.Air.id.PROHIBIT_AB,   true)   -- Does not seem to work. AI still used the after burner.
    self:GetGroup():SetOption(AI.Option.Air.id.RTB_ON_BINGO, false)
    --self.group:SetOption(AI.Option.Air.id.RADAR_USING, AI.Option.Air.val.RADAR_USING.FOR_CONTINUOUS_SEARCH)    

    -- Update route.
    self:__UpdateRoute(-0.5)

  else

    -- F10 other menu.
    self:_UpdateMenu()

  end

end

--- On after "Parking" event. Add flight to flightcontrol of airbase.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterParking(From, Event, To)
  self:T(self.lid..string.format("Flight is parking"))

  local airbase=self:GetClosestAirbase() --self.group:GetCoordinate():GetClosestAirbase()

  local airbasename=airbase:GetName() or "unknown"

  -- Parking time stamp.
  self.Tparking=timer.getAbsTime()

  -- Get FC of this airbase.
  local flightcontrol=_DATABASE:GetFlightControl(airbasename)

  if flightcontrol then

    -- Set FC for this flight
    self:SetFlightControl(flightcontrol)

    if self.flightcontrol then

      -- Set flight status.
      self.flightcontrol:SetFlightStatus(self, FLIGHTCONTROL.FlightStatus.PARKING)

      -- Update player menu.
      if not self.isAI then
        self:_UpdateMenu(0.5)
      end

    end
  end
end

--- On after "Taxiing" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterTaxiing(From, Event, To)
  self:T(self.lid..string.format("Flight is taxiing"))

  -- Parking over.
  self.Tparking=nil

  -- TODO: need a better check for the airbase.
  local airbase=self:GetClosestAirbase() --self.group:GetCoordinate():GetClosestAirbase(nil, self.group:GetCoalition())

  if self.flightcontrol and airbase and self.flightcontrol.airbasename==airbase:GetName() then

    -- Add AI flight to takeoff queue.
    if self.isAI then
      -- AI flights go directly to TAKEOFF as we don't know when they finished taxiing.
      self.flightcontrol:SetFlightStatus(self, FLIGHTCONTROL.FlightStatus.TAKEOFF)
    else
      -- Human flights go to TAXI OUT queue. They will go to the ready for takeoff queue when they request it.
      self.flightcontrol:SetFlightStatus(self, FLIGHTCONTROL.FlightStatus.TAXIOUT)
      -- Update menu.
      self:_UpdateMenu()
    end

  end

end

--- On after "Takeoff" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Airbase#AIRBASE airbase The airbase the flight landed.
function FLIGHTGROUP:onafterTakeoff(From, Event, To, airbase)
  self:T(self.lid..string.format("Flight takeoff from %s", airbase and airbase:GetName() or "unknown airbase"))

  -- Remove flight from all FC queues.
  if self.flightcontrol and airbase and self.flightcontrol.airbasename==airbase:GetName() then
    self.flightcontrol:_RemoveFlight(self)
    self.flightcontrol=nil
  end

end

--- On after "Airborne" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterAirborne(From, Event, To)
  self:T(self.lid..string.format("Flight airborne"))

  if self.isAI then
    self:_CheckGroupDone(1)
  else
    self:_UpdateMenu()
  end
end

--- On after "Landing" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterLanding(From, Event, To)
  self:T(self.lid..string.format("Flight is landing"))

  self:_SetElementStatusAll(OPSGROUP.ElementStatus.LANDING)

end


--- On after "Landed" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Airbase#AIRBASE airbase The airbase the flight landed.
function FLIGHTGROUP:onafterLanded(From, Event, To, airbase)
  self:T(self.lid..string.format("Flight landed at %s", airbase and airbase:GetName() or "unknown place"))

  if self.flightcontrol and airbase and self.flightcontrol.airbasename==airbase:GetName() then
    -- Add flight to taxiinb queue.
    self.flightcontrol:SetFlightStatus(self, FLIGHTCONTROL.FlightStatus.TAXIINB)
  end
    
end

--- On after "LandedAt" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterLandedAt(From, Event, To)
  self:T(self.lid..string.format("Flight landed at"))    
end


--- On after "Arrived" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterArrived(From, Event, To)
  self:T(self.lid..string.format("Flight arrived"))

  -- Flight Control
  if self.flightcontrol then
    -- Add flight to arrived queue.
    self.flightcontrol:SetFlightStatus(self, FLIGHTCONTROL.FlightStatus.ARRIVED)
  end

  -- Despawn in 5 min.
  if not self.airwing then
    self:Despawn(5*60)
  end
end

--- On after "Dead" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterDead(From, Event, To)

  -- Remove flight from all FC queues.
  if self.flightcontrol then
    self.flightcontrol:_RemoveFlight(self)
    self.flightcontrol=nil
  end
  
  if self.Ndestroyed==#self.elements then
    if self.squadron then
      -- All elements were destroyed ==> Asset group is gone.
      self.squadron:DelGroup(self.groupname)
    end    
  else
    if self.airwing then
      -- Not all assets were destroyed (despawn) ==> Add asset back to airwing.
      self.airwing:AddAsset(self.group, 1)    
    end
  end  

  -- Call OPSGROUP function.
  self:GetParent(self).onafterDead(self, From, Event, To)
  
end


--- On before "UpdateRoute" event. Update route of group, e.g after new waypoints and/or waypoint tasks have been added.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number n Waypoint number.
-- @return #boolean Transision allowed?
function FLIGHTGROUP:onbeforeUpdateRoute(From, Event, To, n)

  -- Is transition allowed? We assume yes until proven otherwise.
  local allowed=true
  local trepeat=nil

  if self:IsAlive() then -- and (self:IsAirborne() or self:IsWaiting() or self:IsInbound() or self:IsHolding()) then
    -- Alive & Airborne ==> Update route possible.
    self:T3(self.lid.."Update route possible. Group is ALIVE")
  elseif self:IsDead()  then
    -- Group is dead! No more updates.
    self:E(self.lid.."Update route denied. Group is DEAD!")
    allowed=false
  else
    -- Not airborne yet. Try again in 5 sec.
    self:T(self.lid.."Update route denied ==> checking back in 5 sec")
    trepeat=-5
    allowed=false
  end

  if n and n<1 then
    self:E(self.lid.."Update route denied because waypoint n<1!")
    allowed=false
  end

  if not self.currentwp then
    self:E(self.lid.."Update route denied because self.currentwp=nil!")
    allowed=false
  end

  local N=n or self.currentwp+1
  if not N or N<1 then
    self:E(self.lid.."Update route denied because N=nil or N<1")
    trepeat=-5
    allowed=false
  end

  if self.taskcurrent>0 then
  
    --local task=self:GetTaskCurrent()
    local task=self:GetTaskByID(self.taskcurrent)
    
    if task then
      if task.dcstask.id=="PatrolZone" then
        -- For patrol zone, we need to allow the update.
      else
        local taskname=task and task.description or "No description"
        self:E(self.lid..string.format("WARNING: Update route denied because taskcurrent=%d>0! Task description = %s", self.taskcurrent, tostring(taskname)))
        allowed=false
      end
    else
      -- Now this can happen, if we directly use TaskExecute as the task is not in the task queue and cannot be removed.
      self:T(self.lid..string.format("WARNING: before update route taskcurrent=%d>0 but no task?!", self.taskcurrent))
      -- Anyhow, a task is running so we do not allow to update the route!
      allowed=false
    end
  end

  -- Not good, because mission will never start. Better only check if there is a current task!
  --if self.currentmission then
  --end

  -- Only AI flights.
  if not self.isAI then
    allowed=false
  end

  -- Debug info.
  self:T2(self.lid..string.format("Onbefore Updateroute allowed=%s state=%s repeat in %s", tostring(allowed), self:GetState(), tostring(trepeat)))

  if trepeat then
    self:__UpdateRoute(trepeat, n)
  end

  return allowed
end

--- On after "UpdateRoute" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number n Waypoint number. Default is next waypoint.
function FLIGHTGROUP:onafterUpdateRoute(From, Event, To, n)

  -- Update route from this waypoint number onwards.
  n=n or self.currentwp+1

  -- Update waypoint tasks, i.e. inject WP tasks into waypoint table.
  self:_UpdateWaypointTasks(n)

  -- Waypoints.
  local wp={}

  -- Current velocity.
  local speed=self.group and self.group:GetVelocityKMH() or 100

  -- Set current waypoint or we get problem that the _PassingWaypoint function is triggered too early, i.e. right now and not when passing the next WP.
  local current=self.group:GetCoordinate():WaypointAir(COORDINATE.WaypointAltType.BARO, COORDINATE.WaypointType.TurningPoint, COORDINATE.WaypointAction.TurningPoint, speed, true, nil, {}, "Current")
  table.insert(wp, current)
  
  local Nwp=self.waypoints and #self.waypoints or 0

  -- Add remaining waypoints to route.
  for i=n, Nwp do
    table.insert(wp, self.waypoints[i])
  end

  -- Debug info.
  local hb=self.homebase and self.homebase:GetName() or "unknown"
  local db=self.destbase and self.destbase:GetName() or "unknown"
  self:T(self.lid..string.format("Updating route for WP #%d-%d  homebase=%s destination=%s", n, #wp, hb, db))


  if #wp>1 then

    -- Route group to all defined waypoints remaining.
    self:Route(wp)

  else

    ---
    -- No waypoints left
    ---
    
    if self:IsAirborne() then
      self:T(self.lid.."No waypoints left ==> CheckGroupDone")
      self:_CheckGroupDone()
    end

  end

end

--- On after "Respawn" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #table Template The template used to respawn the group.
function FLIGHTGROUP:onafterRespawn(From, Event, To, Template)

  self:T(self.lid.."Respawning group!")

  local template=UTILS.DeepCopy(Template or self.template)

  if self.group and self.group:InAir() then
    template.lateActivation=false
    self.respawning=true
    self.group=self.group:Respawn(template)
  end

end

--- On after "OutOfMissilesAA" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterOutOfMissilesAA(From, Event, To)
  self:I(self.lid.."Group is out of AA Missiles!")
  if self.outofAAMrtb then
    -- Back to destination or home.
    local airbase=self.destbase or self.homebase
    self:__RTB(-5,airbase)
  end
end

--- On after "OutOfMissilesAG" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterOutOfMissilesAG(From, Event, To)
  self:I(self.lid.."Group is out of AG Missiles!")
  if self.outofAGMrtb then
    -- Back to destination or home.
    local airbase=self.destbase or self.homebase
    self:__RTB(-5,airbase)
  end
end

--- Check if flight is done, i.e.
--
--  * passed the final waypoint,
--  * no current task
--  * no current mission
--  * number of remaining tasks is zero
--  * number of remaining missions is zero
--
-- @param #FLIGHTGROUP self
-- @param #number delay Delay in seconds.
function FLIGHTGROUP:_CheckGroupDone(delay)

  if self:IsAlive() and self.isAI then

    if delay and delay>0 then
      -- Delayed call.
      self:ScheduleOnce(delay, FLIGHTGROUP._CheckGroupDone, self)
    else

      -- First check if there is a paused mission that
      if self.missionpaused then
        self:UnpauseMission()
        return
      end
      
      -- Group is currently engaging.
      if self:IsEngaging() then
        return
      end

      -- Number of tasks remaining.
      local nTasks=self:CountRemainingTasks()

      -- Number of mission remaining.
      local nMissions=self:CountRemainingMissison()

      -- Final waypoint passed?
      if self.passedfinalwp then

        -- Got current mission or task?
        if self.currentmission==nil and self.taskcurrent==0 then

          -- Number of remaining tasks/missions?
          if nTasks==0 and nMissions==0 then
          
            local destbase=self.destbase or self.homebase
            local destzone=self.destzone or self.homezone

            -- Send flight to destination.
            if destbase then
              self:T(self.lid.."Passed Final WP and No current and/or future missions/task ==> RTB!")
              self:__RTB(-3, destbase)
            elseif destzone then
              self:T(self.lid.."Passed Final WP and No current and/or future missions/task ==> RTZ!")
              self:__RTZ(-3, destzone)
            else
              self:T(self.lid.."Passed Final WP and NO Tasks/Missions left. No DestBase or DestZone ==> Wait!")
              self:__Wait(-1)
            end

          else
              self:T(self.lid..string.format("Passed Final WP but Tasks=%d or Missions=%d left in the queue. Wait!", nTasks, nMissions))
              self:__Wait(-1)
          end
        else
          self:T(self.lid..string.format("Passed Final WP but still have current Task (#%s) or Mission (#%s) left to do", tostring(self.taskcurrent), tostring(self.currentmission)))
        end
      else
        self:T(self.lid..string.format("Flight (status=%s) did NOT pass the final waypoint yet ==> update route", self:GetState()))
        self:__UpdateRoute(-1)
      end
    end

  end

end

--- On before "RTB" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Airbase#AIRBASE airbase The airbase to hold at.
-- @param #number SpeedTo Speed used for travelling from current position to holding point in knots.
-- @param #number SpeedHold Holding speed in knots.
function FLIGHTGROUP:onbeforeRTB(From, Event, To, airbase, SpeedTo, SpeedHold)

  if self:IsAlive() then

    local allowed=true
    local Tsuspend=nil

    if airbase==nil then
      self:E(self.lid.."ERROR: Airbase is nil in RTB() call!")
      allowed=false
    end

    -- Check that coaliton is okay. We allow same (blue=blue, red=red) or landing on neutral bases.
    if airbase and airbase:GetCoalition()~=self.group:GetCoalition() and airbase:GetCoalition()>0 then
      self:E(self.lid..string.format("ERROR: Wrong airbase coalition %d in RTB() call! We allow only same as group %d or neutral airbases 0.", airbase:GetCoalition(), self.group:GetCoalition()))
      allowed=false
    end

    if not self.group:IsAirborne(true) then
      -- this should really not happen, either the AUFTRAG is cancelled before the group was airborne or it is stuck at the ground for some reason
      self:I(self.lid..string.format("WARNING: Group is not AIRBORNE  ==> RTB event is suspended for 20 sec."))
      allowed=false
      Tsuspend=-20
      local groupspeed = self.group:GetVelocityMPS()
      if groupspeed <= 1 then self.RTBRecallCount = self.RTBRecallCount+1 end
      if self.RTBRecallCount > 6 then
        self:Despawn(5)
      end
    end
      
    -- Only if fuel is not low or critical.
    if not (self:IsFuelLow() or self:IsFuelCritical()) then

      -- Check if there are remaining tasks.
      local Ntot,Nsched, Nwp=self:CountRemainingTasks()

      if self.taskcurrent>0 then
        self:I(self.lid..string.format("WARNING: Got current task ==> RTB event is suspended for 10 sec."))
        Tsuspend=-10
        allowed=false
      end

      if Nsched>0 then
        self:I(self.lid..string.format("WARNING: Still got %d SCHEDULED tasks in the queue ==> RTB event is suspended for 10 sec.", Nsched))
        Tsuspend=-10
        allowed=false
      end

      if Nwp>0 then
        self:I(self.lid..string.format("WARNING: Still got %d WAYPOINT tasks in the queue ==> RTB event is suspended for 10 sec.", Nwp))
        Tsuspend=-10
        allowed=false
      end

    end

    if Tsuspend and not allowed then
      self:__RTB(Tsuspend, airbase, SpeedTo, SpeedHold)
    end

    return allowed

  else
    self:E(self.lid.."WARNING: Group is not alive! RTB call not allowed.")
    return false
  end

end

--- On after "RTB" event. Order flight to hold at an airbase and wait for signal to land.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Airbase#AIRBASE airbase The airbase to hold at.
-- @param #number SpeedTo Speed used for traveling from current position to holding point in knots. Default 75% of max speed.
-- @param #number SpeedHold Holding speed in knots. Default 250 kts.
-- @param #number SpeedLand Landing speed in knots. Default 170 kts.
function FLIGHTGROUP:onafterRTB(From, Event, To, airbase, SpeedTo, SpeedHold, SpeedLand)

  -- Debug info.
  self:T(self.lid..string.format("RTB: event=%s: %s --> %s to %s", Event, From, To, airbase:GetName()))

  -- Set the destination base.
  self.destbase=airbase

  -- Clear holding time in any case.
  self.Tholding=nil
  
  -- Cancel all missions.
  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG
    local mystatus=mission:GetGroupStatus(self)
    
    -- Check if mission is already over!
    if not (mystatus==AUFTRAG.GroupStatus.DONE or mystatus==AUFTRAG.GroupStatus.CANCELLED) then
      local text=string.format("Canceling mission %s in state=%s", mission.name, mission.status)
      self:T(self.lid..text)
      self:MissionCancel(mission)
    end
    
  end

  -- Defaults:
  SpeedTo=SpeedTo or UTILS.KmphToKnots(self.speedCruise)
  SpeedHold=SpeedHold or (self.ishelo and 80 or 250)
  SpeedLand=SpeedLand or (self.ishelo and 40 or 170)

  -- Debug message.
  local text=string.format("Flight group set to hold at airbase %s. SpeedTo=%d, SpeedHold=%d, SpeedLand=%d", airbase:GetName(), SpeedTo, SpeedHold, SpeedLand)
  self:T(self.lid..text)

  local althold=self.ishelo and 1000+math.random(10)*100 or math.random(4,10)*1000

  -- Holding points.
  local c0=self.group:GetCoordinate()
  local p0=airbase:GetZone():GetRandomCoordinate():SetAltitude(UTILS.FeetToMeters(althold))
  local p1=nil
  local wpap=nil

  -- Do we have a flight control?
  local fc=_DATABASE:GetFlightControl(airbase:GetName())
  if fc then
    -- Get holding point from flight control.
    local HoldingPoint=fc:_GetHoldingpoint(self)
    p0=HoldingPoint.pos0
    p1=HoldingPoint.pos1

    -- Debug marks.
    if self.Debug then
      p0:MarkToAll("Holding point P0")
      p1:MarkToAll("Holding point P1")
    end

    -- Set flightcontrol for this flight.
    self:SetFlightControl(fc)

    -- Add flight to inbound queue.
    self.flightcontrol:SetFlightStatus(self, FLIGHTCONTROL.FlightStatus.INBOUND)
  end

   -- Altitude above ground for a glide slope of 3 degrees.
  local x1=self.ishelo and UTILS.NMToMeters(5.0) or UTILS.NMToMeters(10)
  local x2=self.ishelo and UTILS.NMToMeters(2.5) or UTILS.NMToMeters(5)
  local alpha=math.rad(3)
  local h1=x1*math.tan(alpha)
  local h2=x2*math.tan(alpha)

  local runway=airbase:GetActiveRunway()

  -- Set holding flag to 0=false.
  self.flaghold:Set(0)

  local holdtime=5*60
  if fc or self.airboss then
    holdtime=nil
  end

  -- Task fuction when reached holding point.
  local TaskArrived=self.group:TaskFunction("FLIGHTGROUP._ReachedHolding", self)

  -- Orbit until flaghold=1 (true) but max 5 min if no FC is giving the landing clearance.
  local TaskOrbit = self.group:TaskOrbit(p0, nil, UTILS.KnotsToMps(SpeedHold), p1)
  local TaskLand  = self.group:TaskCondition(nil, self.flaghold.UserFlagName, 1, nil, holdtime)
  local TaskHold  = self.group:TaskControlled(TaskOrbit, TaskLand)
  local TaskKlar  = self.group:TaskFunction("FLIGHTGROUP._ClearedToLand", self)  -- Once the holding flag becomes true, set trigger FLIGHTLANDING, i.e. set flight STATUS to LANDING.

  -- Waypoints from current position to holding point.
  local wp={}
  wp[#wp+1]=c0:WaypointAir(nil, COORDINATE.WaypointType.TurningPoint, COORDINATE.WaypointAction.TurningPoint, UTILS.KnotsToKmph(SpeedTo), true , nil, {}, "Current Pos")
  wp[#wp+1]=p0:WaypointAir(nil, COORDINATE.WaypointType.TurningPoint, COORDINATE.WaypointAction.TurningPoint, UTILS.KnotsToKmph(SpeedTo), true , nil, {TaskArrived, TaskHold, TaskKlar}, "Holding Point")

  -- Approach point: 10 NN in direction of runway.
  if airbase:GetAirbaseCategory()==Airbase.Category.AIRDROME then

    ---
    -- Airdrome
    ---

    local papp=airbase:GetCoordinate():Translate(x1, runway.heading-180):SetAltitude(h1)
    wp[#wp+1]=papp:WaypointAirTurningPoint(nil, UTILS.KnotsToKmph(SpeedLand), {}, "Final Approach")

    -- Okay, it looks like it's best to specify the coordinates not at the airbase but a bit away. This causes a more direct landing approach.
    local pland=airbase:GetCoordinate():Translate(x2, runway.heading-180):SetAltitude(h2)
    wp[#wp+1]=pland:WaypointAirLanding(UTILS.KnotsToKmph(SpeedLand), airbase, {}, "Landing")

  elseif airbase:GetAirbaseCategory()==Airbase.Category.SHIP then

    ---
    -- Ship
    ---

    local pland=airbase:GetCoordinate()
    wp[#wp+1]=pland:WaypointAirLanding(UTILS.KnotsToKmph(SpeedLand), airbase, {}, "Landing")

  end

  if self.isAI then

    local routeto=false
    if fc or world.event.S_EVENT_KILL then
      routeto=true
    end

    -- Clear all tasks.
    -- Warning, looks like this can make DCS CRASH! Had this after calling RTB once passed the final waypoint.
    --self:ClearTasks()

    -- Respawn?
    if routeto then
    
       -- Just route the group. Respawn might happen when going from holding to final.
      self:Route(wp, 1)

    else
    
      -- Get group template.
      local Template=self.group:GetTemplate()

      -- Set route points.
      Template.route.points=wp

      --Respawn the group with new waypoints.
      self:Respawn(Template)

    end

  end

end

--- On before "Wait" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Point#COORDINATE Coord Coordinate where to orbit. Default current position.
-- @param #number Altitude Altitude in feet. Default 10000 ft.
-- @param #number Speed Speed in knots. Default 250 kts.
function FLIGHTGROUP:onbeforeWait(From, Event, To, Coord, Altitude, Speed)

  local allowed=true
  local Tsuspend=nil

  -- Check if there are remaining tasks.
  local Ntot,Nsched, Nwp=self:CountRemainingTasks()

  if self.taskcurrent>0 then
    self:I(self.lid..string.format("WARNING: Got current task ==> WAIT event is suspended for 10 sec."))
    Tsuspend=-10
    allowed=false
  end

  if Nsched>0 then
    self:I(self.lid..string.format("WARNING: Still got %d SCHEDULED tasks in the queue ==> WAIT event is suspended for 10 sec.", Nsched))
    Tsuspend=-10
    allowed=false
  end

  if Nwp>0 then
    self:I(self.lid..string.format("WARNING: Still got %d WAYPOINT tasks in the queue ==> WAIT event is suspended for 10 sec.", Nwp))
    Tsuspend=-10
    allowed=false
  end

  if Tsuspend and not allowed then
    self:__Wait(Tsuspend, Coord, Altitude, Speed)
  end

  return allowed
end


--- On after "Wait" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Point#COORDINATE Coord Coordinate where to orbit. Default current position.
-- @param #number Altitude Altitude in feet. Default 10000 ft.
-- @param #number Speed Speed in knots. Default 250 kts.
function FLIGHTGROUP:onafterWait(From, Event, To, Coord, Altitude, Speed)

  Coord=Coord or self.group:GetCoordinate()
  Altitude=Altitude or (self.ishelo and 1000 or 10000)
  Speed=Speed or (self.ishelo and 80 or 250)

  -- Debug message.
  local text=string.format("Flight group set to wait/orbit at altitude %d m and speed %.1f km/h", Altitude, Speed)
  self:T(self.lid..text)

  --TODO: set ROE passive. introduce roe event/state/variable.

  -- Orbit task.
  local TaskOrbit=self.group:TaskOrbit(Coord, UTILS.FeetToMeters(Altitude), UTILS.KnotsToMps(Speed))

  -- Set task.
  self:SetTask(TaskOrbit)

end


--- On after "Refuel" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Point#COORDINATE Coordinate The coordinate.
function FLIGHTGROUP:onafterRefuel(From, Event, To, Coordinate)

  -- Debug message.
  local text=string.format("Flight group set to refuel at the nearest tanker")
  self:I(self.lid..text)

  --TODO: set ROE passive. introduce roe event/state/variable.
  --TODO: cancel current task

  -- Pause current mission if there is any.
  self:PauseMission()

  -- Refueling task.
  local TaskRefuel=self.group:TaskRefueling()
  local TaskFunction=self.group:TaskFunction("FLIGHTGROUP._FinishedRefuelling", self)
  local DCSTasks={TaskRefuel, TaskFunction}

  local Speed=self.speedCruise

  local coordinate=self.group:GetCoordinate()

  Coordinate=Coordinate or coordinate:Translate(UTILS.NMToMeters(5), self.group:GetHeading(), true)

  local wp0=coordinate:WaypointAir("BARO", COORDINATE.WaypointType.TurningPoint, COORDINATE.WaypointAction.TurningPoint, Speed, true)
  local wp9=Coordinate:WaypointAir("BARO", COORDINATE.WaypointType.TurningPoint, COORDINATE.WaypointAction.TurningPoint, Speed, true, nil, DCSTasks, "Refuel")

  self:Route({wp0, wp9}, 1)

end

--- On after "Refueled" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterRefueled(From, Event, To)

  -- Debug message.
  local text=string.format("Flight group finished refuelling")
  self:I(self.lid..text)

  -- Check if flight is done.
  self:_CheckGroupDone(1)

end


--- On after "Holding" event. Flight arrived at the holding point.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterHolding(From, Event, To)

  -- Set holding flag to 0 (just in case).
  self.flaghold:Set(0)

  -- Holding time stamp.
  self.Tholding=timer.getAbsTime()

  local text=string.format("Flight group %s is HOLDING now", self.groupname)
  self:T(self.lid..text)

  -- Add flight to waiting/holding queue.
  if self.flightcontrol then

    -- Set flight status to holding
    self.flightcontrol:SetFlightStatus(self, FLIGHTCONTROL.FlightStatus.HOLDING)

    if not self.isAI then
      self:_UpdateMenu()
    end

  elseif self.airboss then

    if self.ishelo then

      local carrierpos=self.airboss:GetCoordinate()
      local carrierheading=self.airboss:GetHeading()

      local Distance=UTILS.NMToMeters(5)
      local Angle=carrierheading+90
      local altitude=math.random(12, 25)*100
      local oc=carrierpos:Translate(Distance,Angle):SetAltitude(altitude, true)

      -- Orbit until flaghold=1 (true) but max 5 min if no FC is giving the landing clearance.
      local TaskOrbit=self.group:TaskOrbit(oc, nil, UTILS.KnotsToMps(50))
      local TaskLand=self.group:TaskCondition(nil, self.flaghold.UserFlagName, 1)
      local TaskHold=self.group:TaskControlled(TaskOrbit, TaskLand)
      local TaskKlar=self.group:TaskFunction("FLIGHTGROUP._ClearedToLand", self)  -- Once the holding flag becomes true, set trigger FLIGHTLANDING, i.e. set flight STATUS to LANDING.

      local DCSTask=self.group:TaskCombo({TaskOrbit, TaskHold, TaskKlar})

      self:SetTask(DCSTask)
    end

  end

end

--- On after "EngageTarget" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #table Target Target object. Can be a UNIT, STATIC, GROUP, SET_UNIT or SET_GROUP object.
function FLIGHTGROUP:onafterEngageTarget(From, Event, To, Target)

  -- DCS task.
  local DCStask=nil

  -- Check target object.
  if Target:IsInstanceOf("UNIT") or Target:IsInstanceOf("STATIC") then
  
    DCStask=self:GetGroup():TaskAttackUnit(Target, true)
  
  elseif Target:IsInstanceOf("GROUP") then

    DCStask=self:GetGroup():TaskAttackGroup(Target, nil, nil, nil, nil, nil, nil, true)
  
  elseif Target:IsInstanceOf("SET_UNIT") then

    local DCSTasks={}
  
    for _,_unit in pairs(Target:GetSet()) do --detected by =HRP= Zero
      local unit=_unit  --Wrapper.Unit#UNIT
      local task=self:GetGroup():TaskAttackUnit(unit, true)
      table.insert(DCSTasks)
    end
  
    -- Task combo.
    DCStask=self:GetGroup():TaskCombo(DCSTasks)

  elseif Target:IsInstanceOf("SET_GROUP") then

    local DCSTasks={}
  
    for _,_unit in pairs(Target:GetSet()) do --detected by =HRP= Zero
      local unit=_unit  --Wrapper.Unit#UNIT
      local task=self:GetGroup():TaskAttackGroup(Target, nil, nil, nil, nil, nil, nil, true)
      table.insert(DCSTasks)
    end
  
    -- Task combo.
    DCStask=self:GetGroup():TaskCombo(DCSTasks)
  
  else
    self:E("ERROR: unknown Target in EngageTarget! Needs to be a UNIT, STATIC, GROUP, SET_UNIT or SET_GROUP")
    return
  end

  -- Create new task.The description "Engage_Target" is checked so do not change that lightly.
  local Task=self:NewTaskScheduled(DCStask, 1, "Engage_Target", 0)
  
  -- Backup ROE setting.
  Task.backupROE=self:GetROE()
  
  -- Switch ROE to open fire
  self:SwitchROE(ENUMS.ROE.OpenFire)

  -- Pause current mission.
  local mission=self:GetMissionCurrent()
  if mission then
    self:PauseMission()
  end

  -- Execute task.
  self:TaskExecute(Task)  

end

--- On after "Disengage" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Set#SET_UNIT TargetUnitSet
function FLIGHTGROUP:onafterDisengage(From, Event, To)
  self:T(self.lid.."Disengage target")
end

--- On before "LandAt" event. Check we have a helo group.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Point#COORDINATE Coordinate The coordinate where to land. Default is current position.
-- @param #number Duration The duration in seconds to remain on ground. Default 600 sec (10 min).
function FLIGHTGROUP:onbeforeLandAt(From, Event, To, Coordinate, Duration)
  return self.ishelo
end

--- On after "LandAt" event. Order helicopter to land at a specific point.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Point#COORDINATE Coordinate The coordinate where to land. Default is current position.
-- @param #number Duration The duration in seconds to remain on ground. Default 600 sec (10 min).
function FLIGHTGROUP:onafterLandAt(From, Event, To, Coordinate, Duration)

  -- Duration.
  Duration=Duration or 600

  Coordinate=Coordinate or self:GetCoordinate()

  local DCStask=self.group:TaskLandAtVec2(Coordinate:GetVec2(), Duration)

  local Task=self:NewTaskScheduled(DCStask, 1, "Task_Land_At", 0)

  -- Add task with high priority.
  --self:AddTask(task, 1, "Task_Land_At", 0)

  self:TaskExecute(Task)

end

--- On after "FuelLow" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterFuelLow(From, Event, To)

  -- Debug message.
  local text=string.format("Low fuel for flight group %s", self.groupname)
  self:I(self.lid..text)

  -- Set switch to true.
  self.fuellow=true

  -- Back to destination or home.
  local airbase=self.destbase or self.homebase

  if self.airwing then

    -- Get closest tanker from airwing that can refuel this flight.
    local tanker=self.airwing:GetTankerForFlight(self)

    if tanker then
    
      self:I(self.lid..string.format("Send to refuel at tanker %s", tanker.flightgroup:GetName()))
      
      -- Get a coordinate towards the tanker.
      local coordinate=self:GetCoordinate():GetIntermediateCoordinate(tanker.flightgroup:GetCoordinate(), 0.75)

      -- Send flight to tanker with refueling task.
      self:Refuel(coordinate)

    else

      if airbase and self.fuellowrtb then
        self:RTB(airbase)
        --TODO: RTZ
      end

    end

  else

    if self.fuellowrefuel and self.refueltype then

      local tanker=self:FindNearestTanker(50)

      if tanker then

        self:I(self.lid..string.format("Send to refuel at tanker %s", tanker:GetName()))

        -- Get a coordinate towards the tanker.
        local coordinate=self:GetCoordinate():GetIntermediateCoordinate(tanker:GetCoordinate(), 0.75)

        self:Refuel(coordinate)

        return
      end
    end

    if airbase and self.fuellowrtb then
      self:RTB(airbase)
      --TODO: RTZ
    end

  end

end

--- On after "FuelCritical" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterFuelCritical(From, Event, To)

  -- Debug message.
  local text=string.format("Critical fuel for flight group %s", self.groupname)
  self:I(self.lid..text)

  -- Set switch to true.
  self.fuelcritical=true

  -- Airbase.
  local airbase=self.destbase or self.homebase

  if airbase and self.fuelcriticalrtb and not self:IsGoing4Fuel() then
    self:RTB(airbase)
    --TODO: RTZ
  end
end

--- On after "Stop" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterStop(From, Event, To)

  -- Check if group is still alive.
  if self:IsAlive() then

    -- Set element parking spot to FREE (after arrived for example).
    if self.flightcontrol then
      for _,_element in pairs(self.elements) do
        local element=_element --#FLIGHTGROUP.Element
        self:_SetElementParkingFree(element)
      end
    end

  end

  -- Handle events:
  self:UnHandleEvent(EVENTS.Birth)
  self:UnHandleEvent(EVENTS.EngineStartup)
  self:UnHandleEvent(EVENTS.Takeoff)
  self:UnHandleEvent(EVENTS.Land)
  self:UnHandleEvent(EVENTS.EngineShutdown)
  self:UnHandleEvent(EVENTS.PilotDead)
  self:UnHandleEvent(EVENTS.Ejection)
  self:UnHandleEvent(EVENTS.Crash)
  self:UnHandleEvent(EVENTS.RemoveUnit)
    
  -- Call OPSGROUP function.
  self:GetParent(self).onafterStop(self, From, Event, To)
  
  -- Remove flight from data base.
  _DATABASE.FLIGHTGROUPS[self.groupname]=nil  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Task functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Mission functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Special Task Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Function called when flight has reached the holding point.
-- @param Wrapper.Group#GROUP group Group object.
-- @param #FLIGHTGROUP flightgroup Flight group object.
function FLIGHTGROUP._ReachedHolding(group, flightgroup)
  flightgroup:T2(flightgroup.lid..string.format("Group reached holding point"))

  -- Trigger Holding event.
  flightgroup:__Holding(-1)
end

--- Function called when flight has reached the holding point.
-- @param Wrapper.Group#GROUP group Group object.
-- @param #FLIGHTGROUP flightgroup Flight group object.
function FLIGHTGROUP._ClearedToLand(group, flightgroup)
  flightgroup:T2(flightgroup.lid..string.format("Group was cleared to land"))

  -- Trigger Landing event.
  flightgroup:__Landing(-1)
end

--- Function called when flight finished refuelling.
-- @param Wrapper.Group#GROUP group Group object.
-- @param #FLIGHTGROUP flightgroup Flight group object.
function FLIGHTGROUP._FinishedRefuelling(group, flightgroup)
  flightgroup:T2(flightgroup.lid..string.format("Group finished refueling"))

  -- Trigger Holding event.
  flightgroup:__Refueled(-1)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Initialize group parameters. Also initializes waypoints if self.waypoints is nil.
-- @param #FLIGHTGROUP self
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:_InitGroup()

  -- First check if group was already initialized.
  if self.groupinitialized then
    self:E(self.lid.."WARNING: Group was already initialized!")
    return
  end
  
  -- Group object.
  local group=self.group --Wrapper.Group#GROUP

  -- Get template of group.
  self.template=group:GetTemplate()

  -- Define category.
  self.isAircraft=true
  self.isNaval=false
  self.isGround=false

  -- Helo group.
  self.ishelo=group:IsHelicopter()

  -- Is (template) group uncontrolled.
  self.isUncontrolled=self.template.uncontrolled

  -- Is (template) group late activated.
  self.isLateActivated=self.template.lateActivation

  -- Max speed in km/h.
  self.speedMax=group:GetSpeedMax()

  -- Cruise speed limit 350 kts for fixed and 80 knots for rotary wings.
  local speedCruiseLimit=self.ishelo and UTILS.KnotsToKmph(80) or UTILS.KnotsToKmph(350)

  -- Cruise speed: 70% of max speed but within limit.
  self.speedCruise=math.min(self.speedMax*0.7, speedCruiseLimit)

  -- Group ammo.
  self.ammo=self:GetAmmoTot()

  -- Radio parameters from template. Default is set on spawn if not modified by user.
  self.radio.Freq=tonumber(self.template.frequency)
  self.radio.Modu=tonumber(self.template.modulation)
  self.radio.On=self.template.communication
  
  -- Set callsign. Default is set on spawn if not modified by user.
  local callsign=self.template.units[1].callsign
  if type(callsign)=="number" then  -- Sometimes callsign is just "101".
    local cs=tostring(callsign)
    callsign={}
    callsign[1]=cs:sub(1,1)
    callsign[2]=cs:sub(2,2)
    callsign[3]=cs:sub(3,3)
  end
  self.callsign.NumberSquad=callsign[1]
  self.callsign.NumberGroup=callsign[2]
  self.callsign.NumberElement=callsign[3]  -- First element only
  self.callsign.NameSquad=UTILS.GetCallsignName(self.callsign.NumberSquad)

  -- Set default formation.
  if self.ishelo then
    self.optionDefault.Formation=ENUMS.Formation.RotaryWing.EchelonLeft.D300
  else
    self.optionDefault.Formation=ENUMS.Formation.FixedWing.EchelonLeft.Group
  end
  
  -- Default TACAN off.
  self:SetDefaultTACAN(nil, nil, nil, nil, true)
  self.tacan=UTILS.DeepCopy(self.tacanDefault)

  -- Is this purely AI?
  self.isAI=not self:_IsHuman(group)

  -- Create Menu.
  if not self.isAI then
    self.menu=self.menu or {}
    self.menu.atc=self.menu.atc or {}
    self.menu.atc.root=self.menu.atc.root or MENU_GROUP:New(self.group, "ATC")
  end

  -- Add elemets.
  for _,unit in pairs(self.group:GetUnits()) do
    local element=self:AddElementByName(unit:GetName())
  end

  -- Get first unit. This is used to extract other parameters.
  local unit=self.group:GetUnit(1)

  if unit then

    self.rangemax=unit:GetRange()

    self.descriptors=unit:GetDesc()

    self.actype=unit:GetTypeName()

    self.ceiling=self.descriptors.Hmax

    self.tankertype=select(2, unit:IsTanker())
    self.refueltype=select(2, unit:IsRefuelable())

    -- Debug info.
    if self.verbose>=1 then
      local text=string.format("Initialized Flight Group %s:\n", self.groupname)
      text=text..string.format("Unit type     = %s\n", self.actype)
      text=text..string.format("Speed max    = %.1f Knots\n", UTILS.KmphToKnots(self.speedMax))
      text=text..string.format("Range max    = %.1f km\n", self.rangemax/1000)
      text=text..string.format("Ceiling      = %.1f feet\n", UTILS.MetersToFeet(self.ceiling))
      text=text..string.format("Tanker type  = %s\n", tostring(self.tankertype))
      text=text..string.format("Refuel type  = %s\n", tostring(self.refueltype))
      text=text..string.format("AI           = %s\n", tostring(self.isAI))
      text=text..string.format("Helicopter   = %s\n", tostring(self.group:IsHelicopter()))
      text=text..string.format("Elements     = %d\n", #self.elements)
      text=text..string.format("Waypoints    = %d\n", #self.waypoints)
      text=text..string.format("Radio        = %.1f MHz %s %s\n", self.radio.Freq, UTILS.GetModulationName(self.radio.Modu), tostring(self.radio.On))
      text=text..string.format("Ammo         = %d (G=%d/R=%d/B=%d/M=%d)\n", self.ammo.Total, self.ammo.Guns, self.ammo.Rockets, self.ammo.Bombs, self.ammo.Missiles)
      text=text..string.format("FSM state    = %s\n", self:GetState())
      text=text..string.format("Is alive     = %s\n", tostring(self.group:IsAlive()))
      text=text..string.format("LateActivate = %s\n", tostring(self:IsLateActivated()))
      text=text..string.format("Uncontrolled = %s\n", tostring(self:IsUncontrolled()))
      text=text..string.format("Start Air    = %s\n", tostring(self:IsTakeoffAir()))
      text=text..string.format("Start Cold   = %s\n", tostring(self:IsTakeoffCold()))
      text=text..string.format("Start Hot    = %s\n", tostring(self:IsTakeoffHot()))
      text=text..string.format("Start Rwy    = %s\n", tostring(self:IsTakeoffRunway()))
      self:I(self.lid..text)
    end

    -- Init done.
    self.groupinitialized=true

  end

  return self
end

--- Add an element to the flight group.
-- @param #FLIGHTGROUP self
-- @param #string unitname Name of unit.
-- @return #FLIGHTGROUP.Element The element or nil.
function FLIGHTGROUP:AddElementByName(unitname)

  local unit=UNIT:FindByName(unitname)

  if unit then

    local element={} --#FLIGHTGROUP.Element

    element.name=unitname
    element.unit=unit
    element.status=OPSGROUP.ElementStatus.INUTERO
    element.group=unit:GetGroup()

    -- TODO: this is wrong when grouping is used!
    local unittemplate=element.unit:GetTemplate()

    element.modex=unittemplate.onboard_num
    element.skill=unittemplate.skill
    element.payload=unittemplate.payload
    element.pylons=unittemplate.payload and unittemplate.payload.pylons or nil --element.unit:GetTemplatePylons()
    element.fuelmass0=unittemplate.payload and unittemplate.payload.fuel or 0 --element.unit:GetTemplatePayload().fuel
    element.fuelmass=element.fuelmass0
    element.fuelrel=element.unit:GetFuel()
    element.category=element.unit:GetUnitCategory()
    element.categoryname=element.unit:GetCategoryName()
    element.callsign=element.unit:GetCallsign()
    element.size=element.unit:GetObjectSize()

    if element.skill=="Client" or element.skill=="Player" then
      element.ai=false
      element.client=CLIENT:FindByName(unitname)
    else
      element.ai=true
    end

    -- Debug text.
    local text=string.format("Adding element %s: status=%s, skill=%s, modex=%s, fuelmass=%.1f (%d), category=%d, categoryname=%s, callsign=%s, ai=%s",
    element.name, element.status, element.skill, element.modex, element.fuelmass, element.fuelrel*100, element.category, element.categoryname, element.callsign, tostring(element.ai))
    self:T(self.lid..text)

    -- Add element to table.
    table.insert(self.elements, element)

    if unit:IsAlive() then
      self:ElementSpawned(element)
    end

    return element
  end

  return nil
end


--- Check if a unit is and element of the flightgroup.
-- @param #FLIGHTGROUP self
-- @return Wrapper.Airbase#AIRBASE Final destination airbase or #nil.
function FLIGHTGROUP:GetHomebaseFromWaypoints()

  local wp=self:GetWaypoint(1)

  if wp then

    if wp and wp.action and wp.action==COORDINATE.WaypointAction.FromParkingArea
                         or wp.action==COORDINATE.WaypointAction.FromParkingAreaHot
                         or wp.action==COORDINATE.WaypointAction.FromRunway  then

      -- Get airbase ID depending on airbase category.
      local airbaseID=nil
      
      if wp.airdromeId then
        airbaseID=wp.airdromeId
      else
        airbaseID=-wp.helipadId
      end

      local airbase=AIRBASE:FindByID(airbaseID)
      
      return airbase
    end

    --TODO: Handle case where e.g. only one WP but that is not landing.
    --TODO: Probably other cases need to be taken care of.

  end

  return nil
end

--- Find the nearest friendly airbase (same or neutral coalition).
-- @param #FLIGHTGROUP self
-- @param #number Radius Search radius in NM. Default 50 NM.
-- @return Wrapper.Airbase#AIRBASE Closest tanker group #nil.
function FLIGHTGROUP:FindNearestAirbase(Radius)

  local coord=self:GetCoordinate()

  local dmin=math.huge
  local airbase=nil --Wrapper.Airbase#AIRBASE
  for _,_airbase in pairs(AIRBASE.GetAllAirbases()) do
    local ab=_airbase --Wrapper.Airbase#AIRBASE

    local coalitionAB=ab:GetCoalition()

    if coalitionAB==self:GetCoalition() or coalitionAB==coalition.side.NEUTRAL then

      if airbase then
        local d=ab:GetCoordinate():Get2DDistance(coord)

        if d<dmin then
          d=dmin
          airbase=ab
        end

      end

    end


  end

  return airbase
end

--- Find the nearest tanker.
-- @param #FLIGHTGROUP self
-- @param #number Radius Search radius in NM. Default 50 NM.
-- @return Wrapper.Group#GROUP Closest tanker group or `nil` if no tanker is in the given radius.
function FLIGHTGROUP:FindNearestTanker(Radius)

  Radius=UTILS.NMToMeters(Radius or 50)

  if self.refueltype then

    local coord=self:GetCoordinate()

    local units=coord:ScanUnits(Radius)

    local dmin=math.huge
    local tanker=nil --Wrapper.Unit#UNIT
    for _,_unit in pairs(units.Set) do
      local unit=_unit --Wrapper.Unit#UNIT

      local istanker, refuelsystem=unit:IsTanker()

      if istanker and self.refueltype==refuelsystem then

        -- Distance.
        local d=unit:GetCoordinate():Get2DDistance(coord)

        if d<dmin then
          d=dmin
          tanker=unit
        end

      end

    end

    if tanker then
      return tanker:GetGroup()
    end

  end

  return nil
end

--- Check if a unit is and element of the flightgroup.
-- @param #FLIGHTGROUP self
-- @return Wrapper.Airbase#AIRBASE Final destination airbase or #nil.
function FLIGHTGROUP:GetDestinationFromWaypoints()

  local wp=self:GetWaypointFinal()

  if wp then

    if wp and wp.action and wp.action==COORDINATE.WaypointAction.Landing then

      -- Get airbase ID depending on airbase category.
      local airbaseID=wp.airdromeId or wp.helipadId

      local airbase=AIRBASE:FindByID(airbaseID)

      return airbase
    end

    --TODO: Handle case where e.g. only one WP but that is not landing.
    --TODO: Probably other cases need to be taken care of.

  end

  return nil
end

--- Check if this is a hot start.
-- @param #FLIGHTGROUP self
-- @return #boolean Hot start?
function FLIGHTGROUP:IsTakeoffHot()

  local wp=self:GetWaypoint(1)

  if wp then

    if wp.action and wp.action==COORDINATE.WaypointAction.FromParkingAreaHot then
      return true
    else
      return false
    end

  end

  return nil
end

--- Check if this is a cold start.
-- @param #FLIGHTGROUP self
-- @return #boolean Cold start, i.e. engines off when spawned?
function FLIGHTGROUP:IsTakeoffCold()

  local wp=self:GetWaypoint(1)

  if wp then

    if wp.action and wp.action==COORDINATE.WaypointAction.FromParkingArea then
      return true
    else
      return false
    end

  end

  return nil
end

--- Check if this is a runway start.
-- @param #FLIGHTGROUP self
-- @return #boolean Runway start?
function FLIGHTGROUP:IsTakeoffRunway()

  local wp=self:GetWaypoint(1)

  if wp then

    if wp.action and wp.action==COORDINATE.WaypointAction.FromRunway then
      return true
    else
      return false
    end

  end

  return nil
end

--- Check if this is an air start.
-- @param #FLIGHTGROUP self
-- @return #boolean Air start?
function FLIGHTGROUP:IsTakeoffAir()

  local wp=self:GetWaypoint(1)

  if wp then

    if wp.action and wp.action==COORDINATE.WaypointAction.TurningPoint or wp.action==COORDINATE.WaypointAction.FlyoverPoint then
      return true
    else
      return false
    end

  end

  return nil
end

--- Check if the final waypoint is in the air.
-- @param #FLIGHTGROUP self
-- @param #table wp Waypoint. Default final waypoint.
-- @return #boolean If `true` final waypoint is a turning or flyover but not a landing type waypoint.
function FLIGHTGROUP:IsLandingAir(wp)

  wp=wp or self:GetWaypointFinal()

  if wp then

    if wp.action and wp.action==COORDINATE.WaypointAction.TurningPoint or wp.action==COORDINATE.WaypointAction.FlyoverPoint then
      return true
    else
      return false
    end

  end

  return nil
end

--- Check if the final waypoint is at an airbase.
-- @param #FLIGHTGROUP self
-- @param #table wp Waypoint. Default final waypoint.
-- @return #boolean If `true`, final waypoint is a landing waypoint at an airbase.
function FLIGHTGROUP:IsLandingAirbase(wp)

  wp=wp or self:GetWaypointFinal()

  if wp then

    if wp.action and wp.action==COORDINATE.WaypointAction.LANDING then
      return true
    else
      return false
    end

  end

  return nil
end

--- Initialize Mission Editor waypoints.
-- @param #FLIGHTGROUP self
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:InitWaypoints()

  -- Template waypoints.
  self.waypoints0=self.group:GetTemplateRoutePoints()

  -- Waypoints  
  self.waypoints={}
  
  for index,wp in pairs(self.waypoints0) do
 
    local waypoint=self:_CreateWaypoint(wp)    
    self:_AddWaypoint(waypoint)
     
  end

  -- Get home and destination airbases from waypoints.
  self.homebase=self.homebase or self:GetHomebaseFromWaypoints()
  self.destbase=self.destbase or self:GetDestinationFromWaypoints()

  -- Remove the landing waypoint. We use RTB for that. It makes adding new waypoints easier as we do not have to check if the last waypoint is the landing waypoint.
  if self.destbase then
    table.remove(self.waypoints, #self.waypoints)
  else
    self.destbase=self.homebase
  end

  -- Debug info.
  self:T(self.lid..string.format("Initializing %d waypoints. Homebase %s ==> %s Destination", #self.waypoints, self.homebase and self.homebase:GetName() or "unknown", self.destbase and self.destbase:GetName() or "uknown"))

  -- Update route.
  if #self.waypoints>0 then

    -- Check if only 1 wp?
    if #self.waypoints==1 then
      self.passedfinalwp=true
    end

  end

  return self
end

--- Add an AIR waypoint to the flight plan.
-- @param #FLIGHTGROUP self
-- @param Core.Point#COORDINATE Coordinate The coordinate of the waypoint. Use COORDINATE:SetAltitude(altitude) to define the altitude.
-- @param #number Speed Speed in knots. Default 350 kts.
-- @param #number AfterWaypointWithID Insert waypoint after waypoint given ID. Default is to insert as last waypoint.
-- @param #number Altitude Altitude in feet. Default is y-component of Coordinate. Note that these altitudes are wrt to sea level (barometric altitude).
-- @param #boolean Updateroute If true or nil, call UpdateRoute. If false, no call.
-- @return Ops.OpsGroup#OPSGROUP.Waypoint Waypoint table.
function FLIGHTGROUP:AddWaypoint(Coordinate, Speed, AfterWaypointWithID, Altitude, Updateroute)

  -- Set waypoint index.
  local wpnumber=self:GetWaypointIndexAfterID(AfterWaypointWithID)

  if wpnumber>self.currentwp then
    self.passedfinalwp=false
  end

  -- Speed in knots.
  Speed=Speed or 350

  -- Create air waypoint.
  local wp=Coordinate:WaypointAir(COORDINATE.WaypointAltType.BARO, COORDINATE.WaypointType.TurningPoint, COORDINATE.WaypointAction.TurningPoint, UTILS.KnotsToKmph(Speed), true, nil, {})

  -- Create waypoint data table.
  local waypoint=self:_CreateWaypoint(wp)
  
  -- Set altitude.
  if Altitude then
    waypoint.alt=UTILS.FeetToMeters(Altitude)
  end

  -- Add waypoint to table.
  self:_AddWaypoint(waypoint, wpnumber)

  -- Debug info.
  self:T(self.lid..string.format("Adding AIR waypoint #%d, speed=%.1f knots. Last waypoint passed was #%s. Total waypoints #%d", wpnumber, Speed, self.currentwp, #self.waypoints))

  -- Update route.
  if Updateroute==nil or Updateroute==true then
    self:__UpdateRoute(-1)
  end

  return waypoint
end



--- Check if a unit is an element of the flightgroup.
-- @param #FLIGHTGROUP self
-- @param #string unitname Name of unit.
-- @return #boolean If true, unit is element of the flight group or false if otherwise.
function FLIGHTGROUP:_IsElement(unitname)

  for _,_element in pairs(self.elements) do
    local element=_element --#FLIGHTGROUP.Element

    if element.name==unitname then
      return true
    end

  end

  return false
end



--- Set parking spot of element.
-- @param #FLIGHTGROUP self
-- @param #FLIGHTGROUP.Element Element The element.
-- @param Wrapper.Airbase#AIRBASE.ParkingSpot Spot Parking Spot.
function FLIGHTGROUP:_SetElementParkingAt(Element, Spot)

  -- Element is parking here.
  Element.parking=Spot

  if Spot then

    -- Debug info.
    self:T(self.lid..string.format("Element %s is parking on spot %d", Element.name, Spot.TerminalID))

    if self.flightcontrol then

      -- Set parking spot to OCCUPIED.
      self.flightcontrol:SetParkingOccupied(Element.parking, Element.name)
    end

  end

end

--- Set parking spot of element to free
-- @param #FLIGHTGROUP self
-- @param #FLIGHTGROUP.Element Element The element.
function FLIGHTGROUP:_SetElementParkingFree(Element)

  if Element.parking then

    -- Set parking to FREE.
    if self.flightcontrol then
      self.flightcontrol:SetParkingFree(Element.parking)
    end

    -- Not parking any more.
    Element.parking=nil

  end

end

--- Get onboard number.
-- @param #FLIGHTGROUP self
-- @param #string unitname Name of the unit.
-- @return #string Modex.
function FLIGHTGROUP:_GetOnboardNumber(unitname)

  local group=UNIT:FindByName(unitname):GetGroup()

  -- Units of template group.
  local units=group:GetTemplate().units

  -- Get numbers.
  local numbers={}
  for _,unit in pairs(units) do

    if unitname==unit.name then
      return tostring(unit.onboard_num)
    end

  end

  return nil
end

--- Checks if a human player sits in the unit.
-- @param #FLIGHTGROUP self
-- @param Wrapper.Unit#UNIT unit Aircraft unit.
-- @return #boolean If true, human player inside the unit.
function FLIGHTGROUP:_IsHumanUnit(unit)

  -- Get player unit or nil if no player unit.
  local playerunit=self:_GetPlayerUnitAndName(unit:GetName())

  if playerunit then
    return true
  else
    return false
  end
end

--- Checks if a group has a human player.
-- @param #FLIGHTGROUP self
-- @param Wrapper.Group#GROUP group Aircraft group.
-- @return #boolean If true, human player inside group.
function FLIGHTGROUP:_IsHuman(group)

  -- Get all units of the group.
  local units=group:GetUnits()

  -- Loop over all units.
  for _,_unit in pairs(units) do
    -- Check if unit is human.
    local human=self:_IsHumanUnit(_unit)
    if human then
      return true
    end
  end

  return false
end

--- Returns the unit of a player and the player name. If the unit does not belong to a player, nil is returned.
-- @param #FLIGHTGROUP self
-- @param #string _unitName Name of the player unit.
-- @return Wrapper.Unit#UNIT Unit of player or nil.
-- @return #string Name of the player or nil.
function FLIGHTGROUP:_GetPlayerUnitAndName(_unitName)
  self:F2(_unitName)

  if _unitName ~= nil then

    -- Get DCS unit from its name.
    local DCSunit=Unit.getByName(_unitName)

    if DCSunit then

      local playername=DCSunit:getPlayerName()
      local unit=UNIT:Find(DCSunit)

      if DCSunit and unit and playername then
        return unit, playername
      end

    end

  end

  -- Return nil if we could not find a player.
  return nil,nil
end

--- Returns the parking spot of the element.
-- @param #FLIGHTGROUP self
-- @param #FLIGHTGROUP.Element element Element of the flight group.
-- @param #number maxdist Distance threshold in meters. Default 5 m.
-- @param Wrapper.Airbase#AIRBASE airbase (Optional) The airbase to check for parking. Default is closest airbase to the element.
-- @return Wrapper.Airbase#AIRBASE.ParkingSpot Parking spot or nil if no spot is within distance threshold.
function FLIGHTGROUP:GetParkingSpot(element, maxdist, airbase)

  local coord=element.unit:GetCoordinate()

  airbase=airbase or self:GetClosestAirbase() --coord:GetClosestAirbase(nil, self:GetCoalition())

  -- TODO: replace by airbase.parking if AIRBASE is updated.
  local parking=airbase:GetParkingSpotsTable()

  local spot=nil --Wrapper.Airbase#AIRBASE.ParkingSpot
  local dist=nil
  local distmin=math.huge
  for _,_parking in pairs(parking) do
    local parking=_parking --Wrapper.Airbase#AIRBASE.ParkingSpot
    dist=coord:Get2DDistance(parking.Coordinate)
    if dist<distmin then
      distmin=dist
      spot=_parking
    end
  end

  if distmin<=maxdist and not element.unit:InAir() then
    return spot
  else
    return nil
  end
end

--- Get holding time.
-- @param #FLIGHTGROUP self
-- @return #number Holding time in seconds or -1 if flight is not holding.
function FLIGHTGROUP:GetHoldingTime()
  if self.Tholding then
    return timer.getAbsTime()-self.Tholding
  end

  return -1
end

--- Get parking time.
-- @param #FLIGHTGROUP self
-- @return #number Holding time in seconds or -1 if flight is not holding.
function FLIGHTGROUP:GetParkingTime()
  if self.Tparking then
    return timer.getAbsTime()-self.Tparking
  end

  return -1
end

--- Search unoccupied parking spots at the airbase for all flight elements.
-- @param #FLIGHTGROUP self
-- @return Wrapper.Airbase#AIRBASE Closest airbase
function FLIGHTGROUP:GetClosestAirbase()

  local group=self.group --Wrapper.Group#GROUP
  
  local coord=group:GetCoordinate()
  local coalition=self:GetCoalition()
  
  local airbase=coord:GetClosestAirbase() --(nil, coalition)
  
  return airbase
end

--- Search unoccupied parking spots at the airbase for all flight elements.
-- @param #FLIGHTGROUP self
-- @param Wrapper.Airbase#AIRBASE airbase The airbase where we search for parking spots.
-- @return #table Table of coordinates and terminal IDs of free parking spots.
function FLIGHTGROUP:GetParking(airbase)

  -- Init default
  local scanradius=50
  local scanunits=true
  local scanstatics=true
  local scanscenery=false
  local verysafe=true

  -- Function calculating the overlap of two (square) objects.
  local function _overlap(l1,l2,dist)
    local safedist=(l1/2+l2/2)*1.05  -- 5% safety margine added to safe distance!
    local safe = (dist > safedist)
    return safe
  end

  -- Get client coordinates.
  local function _clients()
    local clients=_DATABASE.CLIENTS
    local coords={}
    for clientname, client in pairs(clients) do
      local template=_DATABASE:GetGroupTemplateFromUnitName(clientname)
      local units=template.units
      for i,unit in pairs(units) do
        local coord=COORDINATE:New(unit.x, unit.alt, unit.y)
        coords[unit.name]=coord
      end
    end
    return coords
  end

  -- Get airbase category.
  local airbasecategory=airbase:GetAirbaseCategory()

  -- Get parking spot data table. This contains all free and "non-free" spots.
  local parkingdata=airbase:GetParkingSpotsTable()

  -- List of obstacles.
  local obstacles={}

  -- Loop over all parking spots and get the currently present obstacles.
  -- How long does this take on very large airbases, i.e. those with hundereds of parking spots? Seems to be okay!
  -- The alternative would be to perform the scan once but with a much larger radius and store all data.
  for _,_parkingspot in pairs(parkingdata) do
    local parkingspot=_parkingspot --Wrapper.Airbase#AIRBASE.ParkingSpot

    -- Scan a radius of 100 meters around the spot.
    local _,_,_,_units,_statics,_sceneries=parkingspot.Coordinate:ScanObjects(scanradius, scanunits, scanstatics, scanscenery)

    -- Check all units.
    for _,_unit in pairs(_units) do
      local unit=_unit --Wrapper.Unit#UNIT
      local _coord=unit:GetCoordinate()
      local _size=self:_GetObjectSize(unit:GetDCSObject())
      local _name=unit:GetName()
      table.insert(obstacles, {coord=_coord, size=_size, name=_name, type="unit"})
    end

    -- Check all clients.
    local clientcoords=_clients()
    for clientname,_coord in pairs(clientcoords) do
      table.insert(obstacles, {coord=_coord, size=15, name=clientname, type="client"})
    end

    -- Check all statics.
    for _,static in pairs(_statics) do
      local _vec3=static:getPoint()
      local _coord=COORDINATE:NewFromVec3(_vec3)
      local _name=static:getName()
      local _size=self:_GetObjectSize(static)
      table.insert(obstacles, {coord=_coord, size=_size, name=_name, type="static"})
    end

    -- Check all scenery.
    for _,scenery in pairs(_sceneries) do
      local _vec3=scenery:getPoint()
      local _coord=COORDINATE:NewFromVec3(_vec3)
      local _name=scenery:getTypeName()
      local _size=self:_GetObjectSize(scenery)
      table.insert(obstacles,{coord=_coord, size=_size, name=_name, type="scenery"})
    end

  end

  -- Parking data for all assets.
  local parking={}

  -- Get terminal type.
  local terminaltype=self:_GetTerminal(self.attribute, airbase:GetAirbaseCategory())

  -- Loop over all units - each one needs a spot.
  for i,_element in pairs(self.elements) do
    local element=_element --#FLIGHTGROUP.Element

    -- Loop over all parking spots.
    local gotit=false
    for _,_parkingspot in pairs(parkingdata) do
      local parkingspot=_parkingspot --Wrapper.Airbase#AIRBASE.ParkingSpot

      -- Check correct terminal type for asset. We don't want helos in shelters etc.
      if AIRBASE._CheckTerminalType(parkingspot.TerminalType, terminaltype) then

        -- Assume free and no problematic obstacle.
        local free=true
        local problem=nil

        -- Safe parking using TO_AC from DCS result.
        if verysafe and parkingspot.TOAC then
          free=false
          self:T2(self.lid..string.format("Parking spot %d is occupied by other aircraft taking off (TOAC).", parkingspot.TerminalID))
        end

        -- Loop over all obstacles.
        for _,obstacle in pairs(obstacles) do

          -- Check if aircraft overlaps with any obstacle.
          local dist=parkingspot.Coordinate:Get2DDistance(obstacle.coord)
          local safe=_overlap(element.size, obstacle.size, dist)

          -- Spot is blocked.
          if not safe then
            free=false
            problem=obstacle
            problem.dist=dist
            break
          end

        end

        -- Check flightcontrol data.
        if self.flightcontrol and self.flightcontrol.airbasename==airbase:GetName() then
          local problem=self.flightcontrol:IsParkingReserved(parkingspot) or self.flightcontrol:IsParkingOccupied(parkingspot)
          if problem then
            free=false
          end
        end

        -- Check if spot is free
        if free then

          -- Add parkingspot for this element.
          table.insert(parking, parkingspot)

          self:T2(self.lid..string.format("Parking spot %d is free for element %s!", parkingspot.TerminalID, element.name))

          -- Add the unit as obstacle so that this spot will not be available for the next unit.
          table.insert(obstacles, {coord=parkingspot.Coordinate, size=element.size, name=element.name, type="element"})

          gotit=true
          break

        else

          -- Debug output for occupied spots.
          self:T2(self.lid..string.format("Parking spot %d is occupied or not big enough!", parkingspot.TerminalID))
          --if self.Debug then
          --  local coord=problem.coord --Core.Point#COORDINATE
          --  local text=string.format("Obstacle blocking spot #%d is %s type %s with size=%.1f m and distance=%.1f m.", _termid, problem.name, problem.type, problem.size, problem.dist)
          --  coord:MarkToAll(string.format(text))
          --end

        end

      end -- check terminal type
    end -- loop over parking spots

    -- No parking spot for at least one asset :(
    if not gotit then
      self:E(self.lid..string.format("WARNING: No free parking spot for element %s", element.name))
      return nil
    end

  end -- loop over asset units

  return parking
end

--- Size of the bounding box of a DCS object derived from the DCS descriptor table. If boundinb box is nil, a size of zero is returned.
-- @param #FLIGHTGROUP self
-- @param DCS#Object DCSobject The DCS object for which the size is needed.
-- @return #number Max size of object in meters (length (x) or width (z) components not including height (y)).
-- @return #number Length (x component) of size.
-- @return #number Height (y component) of size.
-- @return #number Width (z component) of size.
function FLIGHTGROUP:_GetObjectSize(DCSobject)
  local DCSdesc=DCSobject:getDesc()
  if DCSdesc.box then
    local x=DCSdesc.box.max.x+math.abs(DCSdesc.box.min.x)  --length
    local y=DCSdesc.box.max.y+math.abs(DCSdesc.box.min.y)  --height
    local z=DCSdesc.box.max.z+math.abs(DCSdesc.box.min.z)  --width
    return math.max(x,z), x , y, z
  end
  return 0,0,0,0
end

--- Get the generalized attribute of a group.
-- @param #FLIGHTGROUP self
-- @return #string Generalized attribute of the group.
function FLIGHTGROUP:_GetAttribute()

  -- Default
  local attribute=FLIGHTGROUP.Attribute.OTHER

  local group=self.group  --Wrapper.Group#GROUP

  if group then

    --- Planes
    local transportplane=group:HasAttribute("Transports") and group:HasAttribute("Planes")
    local awacs=group:HasAttribute("AWACS")
    local fighter=group:HasAttribute("Fighters") or group:HasAttribute("Interceptors") or group:HasAttribute("Multirole fighters") or (group:HasAttribute("Bombers") and not group:HasAttribute("Strategic bombers"))
    local bomber=group:HasAttribute("Strategic bombers")
    local tanker=group:HasAttribute("Tankers")
    local uav=group:HasAttribute("UAVs")
    --- Helicopters
    local transporthelo=group:HasAttribute("Transport helicopters")
    local attackhelicopter=group:HasAttribute("Attack helicopters")

    -- Define attribute. Order is important.
    if transportplane then
      attribute=FLIGHTGROUP.Attribute.AIR_TRANSPORTPLANE
    elseif awacs then
      attribute=FLIGHTGROUP.Attribute.AIR_AWACS
    elseif fighter then
      attribute=FLIGHTGROUP.Attribute.AIR_FIGHTER
    elseif bomber then
      attribute=FLIGHTGROUP.Attribute.AIR_BOMBER
    elseif tanker then
      attribute=FLIGHTGROUP.Attribute.AIR_TANKER
    elseif transporthelo then
      attribute=FLIGHTGROUP.Attribute.AIR_TRANSPORTHELO
    elseif attackhelicopter then
      attribute=FLIGHTGROUP.Attribute.AIR_ATTACKHELO
    elseif uav then
      attribute=FLIGHTGROUP.Attribute.AIR_UAV
    end

  end

  return attribute
end

--- Get the proper terminal type based on generalized attribute of the group.
--@param #FLIGHTGROUP self
--@param #FLIGHTGROUP.Attribute _attribute Generlized attibute of unit.
--@param #number _category Airbase category.
--@return Wrapper.Airbase#AIRBASE.TerminalType Terminal type for this group.
function FLIGHTGROUP:_GetTerminal(_attribute, _category)

  -- Default terminal is "large".
  local _terminal=AIRBASE.TerminalType.OpenBig

  if _attribute==FLIGHTGROUP.Attribute.AIR_FIGHTER then
    -- Fighter ==> small.
    _terminal=AIRBASE.TerminalType.FighterAircraft
  elseif _attribute==FLIGHTGROUP.Attribute.AIR_BOMBER or _attribute==FLIGHTGROUP.Attribute.AIR_TRANSPORTPLANE or _attribute==FLIGHTGROUP.Attribute.AIR_TANKER or _attribute==FLIGHTGROUP.Attribute.AIR_AWACS then
    -- Bigger aircraft.
    _terminal=AIRBASE.TerminalType.OpenBig
  elseif _attribute==FLIGHTGROUP.Attribute.AIR_TRANSPORTHELO or _attribute==FLIGHTGROUP.Attribute.AIR_ATTACKHELO then
    -- Helicopter.
    _terminal=AIRBASE.TerminalType.HelicopterUsable
  else
    --_terminal=AIRBASE.TerminalType.OpenMedOrBig
  end

  -- For ships, we allow medium spots for all fixed wing aircraft. There are smaller tankers and AWACS aircraft that can use a carrier.
  if _category==Airbase.Category.SHIP then
    if not (_attribute==FLIGHTGROUP.Attribute.AIR_TRANSPORTHELO or _attribute==FLIGHTGROUP.Attribute.AIR_ATTACKHELO) then
      _terminal=AIRBASE.TerminalType.OpenMedOrBig
    end
  end

  return _terminal
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- OPTION FUNCTIONS
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------




-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- MENU FUNCTIONS
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get the proper terminal type based on generalized attribute of the group.
--@param #FLIGHTGROUP self
--@param #number delay Delay in seconds.
function FLIGHTGROUP:_UpdateMenu(delay)

  if delay and delay>0 then
    self:I(self.lid..string.format("FF updating menu in %.1f sec", delay))
    self:ScheduleOnce(delay, FLIGHTGROUP._UpdateMenu, self)
  else

    self:I(self.lid.."FF updating menu NOW")

    -- Get current position of group.
    local position=self.group:GetCoordinate()

    -- Get all FLIGHTCONTROLS
    local fc={}
    for airbasename,_flightcontrol in pairs(_DATABASE.FLIGHTCONTROLS) do

      local airbase=AIRBASE:FindByName(airbasename)

      local coord=airbase:GetCoordinate()

      local dist=coord:Get2DDistance(position)

      local fcitem={airbasename=airbasename, dist=dist}

      table.insert(fc, fcitem)
    end

    -- Sort table wrt distance to airbases.
    local function _sort(a,b)
      return a.dist<b.dist
    end
    table.sort(fc, _sort)

    -- If there is a designated FC, we put it first.
    local N=8
    if self.flightcontrol then
      self.flightcontrol:_CreatePlayerMenu(self, self.menu.atc)
      N=7
    end

    -- Max 8 entries in F10 menu.
    for i=1,math.min(#fc,N) do
      local airbasename=fc[i].airbasename
      local flightcontrol=_DATABASE:GetFlightControl(airbasename)
      flightcontrol:_CreatePlayerMenu(self, self.menu.atc)
    end
  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
