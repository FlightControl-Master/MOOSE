--- **Ops** - Enhanced Airborne Group.
--
-- **Main Features:**
--
--    * Monitor flight status of elements or entire group.
--    * Monitor fuel and ammo status.
--    * Sophisticated task queueing system.
--    * Many additional events for each element and the whole group.
--
-- ===
--
-- ### Author: **funkyfranky**
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
-- @field #FLIGHTGROUP.Ammo ammo Ammunition data. Number of Guns, Rockets, Bombs, Missiles. 
-- @field #boolean ai If true, flight is purely AI. If false, flight contains at least one human player.
-- @field #boolean fuellow Fuel low switch.
-- @field #number fuellowthresh Low fuel threshold in percent.
-- @field #boolean fuellowrtb RTB on low fuel switch.
-- @field #boolean fuelcritical Fuel critical switch.
-- @field #number fuelcriticalthresh Critical fuel threshold in percent.
-- @field #boolean fuelcriticalrtb RTB on critical fuel switch.
-- @field Ops.AirWing#AIRWING airwing The airwing the flight group belongs to.
-- @field Ops.FlightControl#FLIGHTCONTROL flightcontrol The flightcontrol handling this group.
-- @field Ops.Airboss#AIRBOSS airboss The airboss handling this group.
-- @field Core.UserFlag#USERFLAG flaghold Flag for holding.
-- @field #number Tholding Abs. mission time stamp when the group reached the holding point.
-- @field #number Tparking Abs. mission time stamp when the group was spawned uncontrolled and is parking.
-- @field #table menu F10 radio menu.
-- @field #string controlstatus Flight control status.
-- @field #boolean ishelo If true, the is a helicopter group.
-- 
-- @field #number tacanChannelDefault The default TACAN channel.
-- @field #string tacanMorseDefault The default TACAN morse code.
-- @field #number tacanChannel The currenly used TACAN channel.
-- @field #string tacanMorse The currently used TACAN morse code.
-- @field #boolean tacanOn If true, TACAN is currently active.
-- @field Wrapper.Unit#UNIT tacanBeacon The unit acting as TACAN beacon.
-- 
-- @field #number radioFreqDefault Default radio frequency in MHz.
-- @field #number radioFreq Currently used radio frequency in MHz.
-- @field #number radioModuDefault Default Radio modulation `radio.modulation.AM` or `radio.modulation.FM`.
-- @field #number radioModu Currently used radio modulation `radio.modulation.AM` or `radio.modulation.FM`.
-- @field #boolean radioOn If true, radio is currently turned on.
-- @field Core.RadioQueue#RADIOQUEUE radioQueue Radio queue.
-- 
-- @field #number CallsignName Call sign name.
-- @field #number CallsignNumber Call sign number.
-- 
-- @field #boolean eplrsDefault Default EPLRS data link setting.
-- @field #boolean eplrs If true, EPLRS data link is on.
-- 
-- @field #string roeDefault Default ROE setting.
-- @field #string rotDefault Default ROT setting.
-- @field #string roe Current ROE setting.
-- @field #string rot Current ROT setting.
-- 
-- @field #number formationDefault Default formation setting.
-- @field #number formation Current formation setting.
-- 
-- @extends Ops.OpsGroup#OPSGROUP

--- *To invent an airplane is nothing. To build one is something. To fly is everything.* -- Otto Lilienthal
--
-- ===
--
-- ![Banner Image](..\Presentations\FlightGroup\FLIGHTGROUP_Main.jpg)
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
-- # Missions
-- 
-- ## Anti-ship
-- 
-- ## AWACS
-- 
-- ## INTERCEPT
-- 
-- 
-- # Examples
-- 
-- Here are some examples to show how things are done.
-- 
-- ## 1. Spawn
-- 
-- ## 2. Attack Group
-- 
-- ## 3. Whatever
-- 
-- ## 4. Simple Tanker
-- 
-- ## 5. Simple AWACS
-- 
-- ## 6. Scheduled Tasks
-- 
-- ## 7. Waypoint Tasks
-- 
-- ## 8. Enroute Tasks
-- 
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
  speedmax           =   nil,
  rangemax           =   nil,
  ceiling            =   nil,
  fuellow            = false,
  fuellowthresh      =   nil,
  fuellowrtb         =   nil,
  fuelcritical       =   nil,  
  fuelcriticalthresh =   nil,
  fuelcriticalrtb    = false,
  squadron           =   nil,
  flightcontrol      =   nil,
  flaghold           =   nil,
  Tholding           =   nil,
  Tparking           =   nil,
  menu               =   nil,
  ishelo             =   nil,
}


--- Status of flight group element.
-- @type FLIGHTGROUP.ElementStatus
-- @field #string INUTERO Element was not spawned yet or its status is unknown so far.
-- @field #string SPAWNED Element was spawned into the world.
-- @field #string PARKING Element is parking after spawned on ramp.
-- @field #string ENGINEON Element started its engines.
-- @field #string TAXIING Element is taxiing after engine startup.
-- @field #string TAKEOFF Element took of after takeoff event.
-- @field #string AIRBORNE Element is airborne. Either after takeoff or after air start.
-- @field #string LANDING Element is landing.
-- @field #string LANDED Element landed and is taxiing to its parking spot.
-- @field #string ARRIVED Element arrived at its parking spot and shut down its engines.
-- @field #string DEAD Element is dead after it crashed, pilot ejected or pilot dead events.
FLIGHTGROUP.ElementStatus={
  INUTERO="inutero",
  SPAWNED="spawned",
  PARKING="parking",
  ENGINEON="engineon",
  TAXIING="taxiing",
  TAKEOFF="takeoff",
  AIRBORNE="airborne",
  LANDING="landing",
  LANDED="landed",
  ARRIVED="arrived",
  DEAD="dead",
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
-- @field #string status Status, i.e. born, parking, taxiing. See @{#FLIGHTGROUP.ElementStatus}.
-- @field #number damage Damage of element in percent.
-- @field Wrapper.Airbase#AIRBASE.ParkingSpot parking The parking spot table the element is parking on.

--- Ammo data.
-- @type FLIGHTGROUP.Ammo
-- @field #number Total Total amount of ammo.
-- @field #number Guns Amount of gun shells.
-- @field #number Bombs Amount of bombs.
-- @field #number Rockets Amount of rockets.
-- @field #number Missiles Amount of missiles.
-- @field #number MissilesAA Amount of air-to-air missiles.
-- @field #number MissilesAG Amount of air-to-ground missiles.
-- @field #number MissilesAS Amount of anti-ship missiles.


--- FLIGHTGROUP class version.
-- @field #string version
FLIGHTGROUP.version="0.4.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Use new UnitLost event instead of crash/dead.
-- TODO: Options EPLRS, Afterburner restrict etc.
-- DONE: Add TACAN beacon.
-- TODO: Damage?
-- TODO: shot events?
-- TODO: Marks to add waypoints/tasks on-the-fly.
-- TODO: Mark assigned parking spot on F10 map.
-- TODO: Let user request a parking spot via F10 marker :)
-- TODO: Monitor traveled distance in air ==> calculate fuel consumption ==> calculate range remaining. Will this give half way accurate results?
-- TODO: Out of AG/AA missiles. Safe state of out-of-ammo.
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
-- @param #string groupname Name of the group.
-- @param #string autostart (Optional) If `true` or `nil` automatically start the FSM (default). If `false`, use FLIGHTGROUP:Start() manually.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:New(groupname, autostart)

  -- First check if we already have a flight group for this group.
  local fg=_DATABASE:GetFlightGroup(groupname)
  if fg then
    fg:I(fg.lid..string.format("WARNING: Flight group %s already exists in data base!", groupname))
    return fg
  end

  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, OPSGROUP:New(groupname)) -- #FLIGHTGROUP

  -- Set some string id for output to DCS.log file.
  self.lid=string.format("FLIGHTGROUP %s | ", self.groupname)

  -- Defaults
  self:SetFuelLowThreshold()
  self:SetFuelCriticalThreshold()
  self:SetDefaultROE()
  self:SetDefaultROT()
  self:SetDetection()

  -- Holding flag.  
  self.flaghold=USERFLAG:New(string.format("%s_FlagHold", self.groupname))
  self.flaghold:Set(0)

  -- Add FSM transitions.
  --                 From State  -->   Event      -->      To State  
  self:AddTransition("*",             "RTB",               "Inbound")     -- Group is returning to destination base.
  self:AddTransition("*",             "RTZ",               "Inbound")     -- Group is returning to destination zone. Not implemented yet!
  self:AddTransition("Inbound",       "Holding",           "Holding")     -- Group is in holding pattern.
  
  self:AddTransition("*",             "Refuel",            "Going4Fuel")  -- Group is send to refuel at a tanker. Not implemented yet!
  self:AddTransition("Going4Fuel",    "Refueled",          "Airborne")    -- Group is send to refuel at a tanker. Not implemented yet!
  
  self:AddTransition("*",             "LandAt",            "LandingAt")   -- Helo group is ordered to land at a specific point.
  self:AddTransition("LandingAt",     "LandedAt",          "LandedAt")    -- Helo group landed landed at a specific point.

  self:AddTransition("*",             "Wait",              "Waiting")     -- Group is orbiting.
  
  self:AddTransition("*",             "FuelLow",           "*")          -- Fuel state of group is low. Default ~25%.
  self:AddTransition("*",             "FuelCritical",      "*")          -- Fuel state of group is critical. Default ~10%.
  
  self:AddTransition("*",             "OutOfMissilesAA",   "*")          -- Group is out of A2A missiles. Not implemented yet!
  self:AddTransition("*",             "OutOfMissilesAG",   "*")          -- Group is out of A2G missiles. Not implemented yet!
  self:AddTransition("*",             "OutOfMissilesAS",   "*")          -- Group is out of A2G missiles. Not implemented yet!

  self:AddTransition("Airborne",      "EngageTargets",    "Engaging")    -- Engage targets.
  self:AddTransition("Engaging",      "Disengage",        "Airborne")    -- Engagement over.
    
  self:AddTransition("*",             "ElementSpawned",   "*")           -- An element was spawned.
  self:AddTransition("*",             "ElementParking",   "*")           -- An element is parking.
  self:AddTransition("*",             "ElementEngineOn",  "*")           -- An element spooled up the engines.
  self:AddTransition("*",             "ElementTaxiing",   "*")           -- An element is taxiing to the runway.
  self:AddTransition("*",             "ElementTakeoff",   "*")           -- An element took off.
  self:AddTransition("*",             "ElementAirborne",  "*")           -- An element is airborne.
  self:AddTransition("*",             "ElementLanded",    "*")           -- An element landed.
  self:AddTransition("*",             "ElementArrived",   "*")           -- An element arrived.
  self:AddTransition("*",             "ElementDead",      "*")           -- An element crashed, ejected, or pilot dead.

  self:AddTransition("*",             "ElementOutOfAmmo", "*")           -- An element is completely out of ammo.
  
  self:AddTransition("*",             "FlightSpawned",    "Spawned")     -- The whole flight group was spawned.
  self:AddTransition("*",             "FlightParking",    "Parking")     -- The whole flight group is parking.
  self:AddTransition("*",             "FlightTaxiing",    "Taxiing")     -- The whole flight group is taxiing.
  self:AddTransition("*",             "FlightTakeoff",    "Airborne")    -- The whole flight group is airborne.
  self:AddTransition("*",             "FlightAirborne",   "Airborne")    -- The whole flight group is airborne.
  self:AddTransition("*",             "FlightLanding",    "Landing")     -- The whole flight group is landing.
  self:AddTransition("*",             "FlightLanded",     "Landed")      -- The whole flight group has landed.
  self:AddTransition("*",             "FlightArrived",    "Arrived")     -- The whole flight group has arrived.
  self:AddTransition("*",             "FlightDead",       "Dead")        -- The whole flight group is dead.

  ------------------------
  --- Pseudo Functions ---
  ------------------------

  --- Triggers the FSM event "Start". Starts the FLIGHTGROUP. Initializes parameters and starts event handlers.
  -- @function [parent=#FLIGHTGROUP] Start
  -- @param #FLIGHTGROUP self

  --- Triggers the FSM event "Start" after a delay. Starts the FLIGHTGROUP. Initializes parameters and starts event handlers.
  -- @function [parent=#FLIGHTGROUP] __Start
  -- @param #FLIGHTGROUP self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Stop". Stops the FLIGHTGROUP and all its event handlers.
  -- @param #FLIGHTGROUP self

  --- Triggers the FSM event "Stop" after a delay. Stops the FLIGHTGROUP and all its event handlers.
  -- @function [parent=#FLIGHTGROUP] __Stop
  -- @param #FLIGHTGROUP self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "FlightStatus".
  -- @function [parent=#FLIGHTGROUP] FlightStatus
  -- @param #FLIGHTGROUP self

  --- Triggers the FSM event "FlightStatus" after a delay.
  -- @function [parent=#FLIGHTGROUP] __FlightStatus
  -- @param #FLIGHTGROUP self
  -- @param #number delay Delay in seconds.


  -- Debug trace.
  if false then
    BASE:TraceOnOff(true)
    BASE:TraceClass(self.ClassName)
    BASE:TraceLevel(1)
  end
  
  -- Add to data base.
  _DATABASE:AddFlightGroup(self)

  -- Autostart.
  if autostart==true or autostart==nil then
    self:Start()
  end

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
  self:I(self.lid..string.format("Add flight to AIRWING %s", airwing.alias))
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
  if self.ai==false then
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
-- @param #boolean rtb If true, RTB on fuel critical event.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:SetFuelCriticalThreshold(threshold, rtb)
  self.fuelcriticalthresh=threshold or 10
  self.fuelcriticalrtb=rtb
  return self
end



--- Check if flight is in state in utero.
-- @param #FLIGHTGROUP self
-- @return #boolean If true, flight is not spawned yet.
function FLIGHTGROUP:IsInUtero()
  return self:Is("InUtero")
end

--- Check if flight is in state spawned.
-- @param #FLIGHTGROUP self
-- @return #boolean If true, flight is spawned.
function FLIGHTGROUP:IsSpawned()
  return self:Is("Spawned")
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

--- Check if flight is dead.
-- @param #FLIGHTGROUP self
-- @return #boolean If true, all units/elements of the flight are dead.
function FLIGHTGROUP:IsDead()
  return self:Is("Dead")
end

--- Check if flight FSM is stopped.
-- @param #FLIGHTGROUP self
-- @return #boolean If true, FSM state is stopped.
function FLIGHTGROUP:IsStopped()
  return self:Is("Stopped")
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
      self:I(self.lid.."Starting uncontrolled group")
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
      self:I(self.lid..string.format("Clear to land ==> setting holding flag to 1 (true)")) 
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

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Start & Status
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after Start event. Starts the FLIGHTGROUP FSM and event handlers.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterStart(From, Event, To)

  -- Short info.
  local text=string.format("Starting flight group v%s", FLIGHTGROUP.version)
  self:I(self.lid..text)

  -- Set current waypoint. Counting starts a one.
  self.currentwp=1
  
  -- Check if the group is already alive and if so, add its elements.
  local group=GROUP:FindByName(self.groupname)
  
  if group then
  
    -- Set group object.
    self.group=group

    -- Get units of group.
    local units=group:GetUnits() or {}

    -- Add elemets.
    for _,unit in pairs(units) do
      local element=self:AddElementByName(unit:GetName())
    end
    
    if not self.groupinitialized then
      self:_InitGroup()
    end
  
    if group:IsAlive() then
      
      -- Debug info.    
      self:T(self.lid..string.format("Found EXISTING and ALIVE group %s at start with %d/%d units/elements", group:GetName(), #units, #self.elements))
                     
      -- Trigger spawned event for all elements.
      for _,element in pairs(self.elements) do
        -- Add a little delay or the OnAfterSpawned function is not even initialized and will not be called.
        self:__ElementSpawned(0.1, element)    
      end
      
    else
      -- Debug info.    
      self:T(self.lid..string.format("Found EXISTING but LATE ACTIVATED group %s at start with %d/%d units/elements", group:GetName(), #units, #self.elements))
    end
    
  end    
  
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

  -- Start the status monitoring.
  self:__CheckZone(-1)
  self:__Status(-2)
  self:__QueueUpdate(-3)
end

--- On after Start event. Starts the FLIGHTGROUP FSM and event handlers.
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
      
    -- Destroy group. No event is generated.
    self.group:Destroy(false)
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
  
  self.CallScheduler:Clear()
  
  _DATABASE.FLIGHTGROUPS[self.groupname]=nil

  self:I(self.lid.."STOPPED! Unhandled events, cleared scheduler and removed from database.")
end


--- On after "Status" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterStatus(From, Event, To)

  -- FSM state.
  local fsmstate=self:GetState()

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
          if element.status==FLIGHTGROUP.ElementStatus.ENGINEON then
            self:ElementTaxiing(element)
          end
        end
        
      else
        --self:E(self.lid..string.format("Element %s is in PARKING queue but has no parking spot assigned!", element.name))
      end
    end  
  end
  
  ---
  -- Elements
  ---
  
  local nTaskTot, nTaskSched, nTaskWP=self:CountRemainingTasks()
  local nMissions=self:CountRemainingMissison()

  -- Short info.
  if self.verbose>0 then  
    local text=string.format("Status %s [%d/%d]: Tasks=%d (%d,%d) Current=%d. Missions=%s. Waypoint=%d/%d. Detected=%d. Destination=%s, FC=%s",
    fsmstate, #self.elements, #self.elements, nTaskTot, nTaskSched, nTaskWP, self.taskcurrent, nMissions, self.currentwp or 0, self.waypoints and #self.waypoints or 0, 
    self.detectedunits:Count(), self.destbase and self.destbase:GetName() or "unknown", self.flightcontrol and self.flightcontrol.airbasename or "none")
    self:I(self.lid..text)
  end

  -- Element status.
  if self.verbose>1 then  
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
      if life<0 and element.status~=FLIGHTGROUP.ElementStatus.DEAD and element.status~=FLIGHTGROUP.ElementStatus.INUTERO then
        self:ElementDead(element)
      end
      
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

  if self.verbose>1 and self:IsAlive() and self.position then

    local time=timer.getAbsTime()
    
    -- Current position.
    local position=self:GetCoordinate()
    
    -- Travelled distance since last check.
    local ds=self.position:Get3DDistance(position)
    
    -- Time interval.
    local dt=time-self.traveltime
    
    -- Speed.
    local v=ds/dt
    
    -- Add up travelled distance.
    self.traveldist=self.traveldist+ds
    
    
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
    

    -- Update parameters.
    self.traveltime=time
    self.position=position    
  end  
  
  ---
  -- Tasks
  ---
  
  -- Task queue.
  if #self.taskqueue>0 and self.verbose>1 then  
    local text=string.format("Tasks #%d", #self.taskqueue)
    for i,_task in pairs(self.taskqueue) do
      local task=_task --#FLIGHTGROUP.Task
      local name=task.description
      local taskid=task.dcstask.id or "unknown"
      local status=task.status
      local clock=UTILS.SecondsToClock(task.time, true)
      local eta=task.time-timer.getAbsTime()
      local started=task.timestamp and UTILS.SecondsToClock(task.timestamp, true) or "N/A"
      local duration=-1
      if task.duration then
        duration=task.duration
        if task.timestamp then
          -- Time the task is running.
          duration=task.duration-(timer.getAbsTime()-task.timestamp)
        else
          -- Time the task is supposed to run.
          duration=task.duration
        end
      end
      -- Output text for element.
      if task.type==FLIGHTGROUP.TaskType.SCHEDULED then
        text=text..string.format("\n[%d] %s (%s): status=%s, scheduled=%s (%d sec), started=%s, duration=%d", i, taskid, name, status, clock, eta, started, duration)
      elseif task.type==FLIGHTGROUP.TaskType.WAYPOINT then
        text=text..string.format("\n[%d] %s (%s): status=%s, waypoint=%d, started=%s, duration=%d, stopflag=%d", i, taskid, name, status, task.waypoint, started, duration, task.stopflag:Get())
      end
    end
    self:I(self.lid..text)
  end
  
  ---
  -- Missions
  ---
  
  -- Current mission name.
  if self.verbose>0 then  
    local Mission=self:GetMissionByID(self.currentmission)
    
    -- Current status.
    local text=string.format("Missions %d, Current: %s", self:CountRemainingMissison(), Mission and Mission.name or "none")
    for i,_mission in pairs(self.missionqueue) do
      local mission=_mission --Ops.Auftrag#AUFTRAG
      local Cstart= UTILS.SecondsToClock(mission.Tstart, true)
      local Cstop = mission.Tstop and UTILS.SecondsToClock(mission.Tstop, true) or "INF"
      text=text..string.format("\n[%d] %s (%s) status=%s (%s), Time=%s-%s, prio=%d wp=%s targets=%d", 
      i, tostring(mission.name), mission.type, mission:GetFlightStatus(self), tostring(mission.status), Cstart, Cstop, mission.prio, tostring(mission:GetFlightWaypointIndex(self)), mission:CountMissionTargets())
    end
    self:I(self.lid..text)
  end

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
    
  end

  ---
  -- Airboss Helo
  ---
  if self.ishelo and self.airboss and self:IsHolding() then
    if self.airboss:IsRecovering() or self:IsFuelCritical() then
      self:ClearToLand()
    end  
  end


  -- Next check in ~30 seconds.
  if not self:IsStopped() then
    self:__Status(-30)
  end
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Queue Update: Missions & Tasks
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after "QueueUpdate" event. 
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterQueueUpdate(From, Event, To)

  ---
  -- Mission
  ---

   -- First check if group is alive? Late activated groups are activated and uncontrolled units are started automatically.
  if self:IsAlive()~=nil then
  
    local mission=self:_GetNextMission()
    
    if mission then
    
      local currentmission=self:GetMissionCurrent()
      
      if currentmission then
      
        -- Current mission but new mission is urgent with higher prio.
        if mission.urgent and mission.prio<currentmission.prio then
          self:MissionCancel(currentmission)
          self:__MissionStart(1, mission)
        end
        
      else
        -- No current mission.
        self:MissionStart(mission)        
      end
    end
  end

  ---
  -- Tasks
  ---

  -- Check no current task.
  if self:IsAirborne() and self.taskcurrent<=0 then

    -- Get task from queue.
    local task=self:_GetNextTask()

    -- Execute task if any.
    if task then
      self:TaskExecute(task)
    end
    
  end

  -- Update queue every ~5 sec.
  if not self:IsStopped() then
    self:__QueueUpdate(-5)
  end
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Events
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Flightgroup event function, handling the birth of a unit.
-- @param #FLIGHTGROUP self
-- @param Core.Event#EVENTDATA EventData Event data.
function FLIGHTGROUP:OnEventBirth(EventData)

  -- Check that this is the right group.
  if EventData and EventData.IniGroup and EventData.IniUnit and EventData.IniGroupName and EventData.IniGroupName==self.groupname then
    local unit=EventData.IniUnit
    local group=EventData.IniGroup
    local unitname=EventData.IniUnitName

    -- Set group.
    self.group=self.group or EventData.IniGroup
    
    if not self.groupinitialized then
      --TODO: actually that is not very good here as if the first unit is born and in initgroup we initialize all elements!
      self:_InitGroup()
    end
    
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
          
      -- Get element.
      local element=self:GetElementByName(unitname)
  
      -- Create element spawned event if not already present.
      if not self:_IsElement(unitname) then
        element=self:AddElementByName(unitname)
      end
        
      -- Set element to spawned state.
      self:T3(self.lid..string.format("EVENT: Element %s born ==> spawned", element.name))            
      self:ElementSpawned(element)
      
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
        if self.ai then
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
    
        local airbase=element.unit:GetCoordinate():GetClosestAirbase()
        local parking=self:GetParkingSpot(element, 10, airbase)
        
        if airbase and parking then
          self:ElementArrived(element, airbase, parking)
          self:T3(self.lid..string.format("EVENT: Element %s shut down engines ==> arrived", element.name))
        else
          self:T3(self.lid..string.format("EVENT: Element %s shut down engines (in air) ==> dead", element.name))
          self:ElementDead(element)
        end
        
      else
      
        self:I(self.lid..string.format("EVENT: Element %s shut down engines but is NOT alive ==> waiting for crash event (==> dead)", element.name))

      end
      
    else
      -- element is nil
    end

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

    if element then
      self:T3(self.lid..string.format("EVENT: Element %s crashed ==> dead", element.name))
      self:ElementDead(element)
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
      self:I(self.lid..string.format("EVENT: Element %s removed ==> dead", element.name))
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
  self:_UpdateStatus(Element, FLIGHTGROUP.ElementStatus.SPAWNED)

  if Element.unit:InAir() then
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
      self:E(self.lid..string.format("Element spawned not in air but not on any parking spot."))
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
-- @param #FLIGHTGROUP.ParkingSpot Spot Parking Spot.
function FLIGHTGROUP:onafterElementParking(From, Event, To, Element, Spot)
  self:T(self.lid..string.format("Element parking %s at spot %s", Element.name, Element.parking and tostring(Element.parking.TerminalID) or "N/A"))
  
  -- Set element status.
  self:_UpdateStatus(Element, FLIGHTGROUP.ElementStatus.PARKING)
  
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
  self:_UpdateStatus(Element, FLIGHTGROUP.ElementStatus.ENGINEON)
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
  self:I(self.lid..string.format("Element taxiing %s. Parking spot %s is now free", Element.name, TerminalID))

  -- Set parking spot to free. Also for FC.
  self:_SetElementParkingFree(Element)
  
  -- Set element status.
  self:_UpdateStatus(Element, FLIGHTGROUP.ElementStatus.TAXIING)
end

--- On after "ElementTakeoff" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #FLIGHTGROUP.Element Element The flight group element.
-- @param Wrapper.Airbase#AIRBASE airbase The airbase if applicable or nil.
function FLIGHTGROUP:onafterElementTakeoff(From, Event, To, Element, airbase)
  self:I(self.lid..string.format("Element takeoff %s at %s airbase.", Element.name, airbase and airbase:GetName() or "unknown"))

  -- Helos with skids just take off without taxiing!
  if Element.parking then
    self:_SetElementParkingFree(Element)
  end

  -- Set element status.
  self:_UpdateStatus(Element, FLIGHTGROUP.ElementStatus.TAKEOFF, airbase)
    
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
  self:_UpdateStatus(Element, FLIGHTGROUP.ElementStatus.AIRBORNE)
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
  
  -- Helos with skids land directly on parking spots.
  if self.ishelo then
  
    local Spot=self:GetParkingSpot(Element, 10, airbase)
   
    self:_SetElementParkingAt(Element, Spot)
    
  end

  -- Set element status.
  self:_UpdateStatus(Element, FLIGHTGROUP.ElementStatus.LANDED, airbase)
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
  self:_UpdateStatus(Element, FLIGHTGROUP.ElementStatus.ARRIVED)
end

--- On after "ElementDead" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #FLIGHTGROUP.Element Element The flight group element.
function FLIGHTGROUP:onafterElementDead(From, Event, To, Element)
  self:T(self.lid..string.format("Element dead %s.", Element.name))

  if self.flightcontrol and Element.parking then
    self.flightcontrol:SetParkingFree(Element.parking)
  end      
  
  -- Not parking any more.
  Element.parking=nil

  -- Set element status.
  self:_UpdateStatus(Element, FLIGHTGROUP.ElementStatus.DEAD)
end


--- On after "FlightSpawned" event. Sets the template, initializes the waypoints.
-- @param #FLIGHTGROUP self
-- @param Wrapper.Group#GROUP Group Flight group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterFlightSpawned(From, Event, To)
  self:I(self.lid..string.format("Flight spawned!"))
    
  if self.ai then
  
    -- Set default ROE and ROT options.
    self:SetOptionROE()
    self:SetOptionROT()
    
    -- TODO: make this input.
    self.group:SetOption(AI.Option.Air.id.PROHIBIT_JETT, true)
    self.group:SetOption(AI.Option.Air.id.PROHIBIT_AB, true)   -- Does not seem to work. AI still used the after burner.
    self.group:SetOption(AI.Option.Air.id.RTB_ON_BINGO, false)
    --self.group:SetOption(AI.Option.Air.id.RADAR_USING, AI.Option.Air.val.RADAR_USING.FOR_CONTINUOUS_SEARCH)
    
    -- Turn TACAN beacon on.
    if self.tacanChannelDefault then
      self:SwitchTACANOn(self.tacanChannelDefault, self.tacanMorseDefault)
    end
    
    -- Turn on the radio.
    if self.radioFreqDefault then
      self:SwitchRadioOn(self.radioFreqDefault, self.radioModuDefault)
    end
      
  else
  
    -- F10 other menu.
    self:_UpdateMenu()
    
  end  
    
end

--- On after "FlightParking" event. Add flight to flightcontrol of airbase.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterFlightParking(From, Event, To)
  self:I(self.lid..string.format("Flight is parking"))

  local airbase=self.group:GetCoordinate():GetClosestAirbase()
  
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
      if not self.ai then
        self:_UpdateMenu(0.5)
      end
            
    end
  end  
end

--- On after "FlightTaxiing" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterFlightTaxiing(From, Event, To)
  self:T(self.lid..string.format("Flight is taxiing"))
  
  -- Parking over.
  self.Tparking=nil

  -- TODO: need a better check for the airbase.
  local airbase=self.group:GetCoordinate():GetClosestAirbase(nil, self.group:GetCoalition())

  if self.flightcontrol and airbase and self.flightcontrol.airbasename==airbase:GetName() then    

    -- Add AI flight to takeoff queue.
    if self.ai then
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

--- On after "FlightTakeoff" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Airbase#AIRBASE airbase The airbase the flight landed.
function FLIGHTGROUP:onafterFlightTakeoff(From, Event, To, airbase)
  self:T(self.lid..string.format("Flight takeoff from %s", airbase and airbase:GetName() or "unknown airbase"))

  -- Remove flight from all FC queues.
  if self.flightcontrol and airbase and self.flightcontrol.airbasename==airbase:GetName() then
    self.flightcontrol:_RemoveFlight(self)
    self.flightcontrol=nil
  end
  
end

--- On after "FlightAirborne" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterFlightAirborne(From, Event, To)
  self:I(self.lid..string.format("Flight airborne"))
  
  if not self.ai then
    self:_UpdateMenu()
  end
end

--- On after "FlightLanding" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterFlightLanding(From, Event, To)
  self:T(self.lid..string.format("Flight is landing"))

  self:_SetElementStatusAll(FLIGHTGROUP.ElementStatus.LANDING)
  
end

--- On after "FlightLanded" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Airbase#AIRBASE airbase The airbase the flight landed.
function FLIGHTGROUP:onafterFlightLanded(From, Event, To, airbase)
  self:T(self.lid..string.format("Flight landed at %s", airbase and airbase:GetName() or "unknown place"))

  if self:IsLandingAt() then
    self:LandedAt()
  else
    if self.flightcontrol and airbase and self.flightcontrol.airbasename==airbase:GetName() then
      -- Add flight to taxiinb queue.
      self.flightcontrol:SetFlightStatus(self, FLIGHTCONTROL.FlightStatus.TAXIINB)
    end
  end
end

--- On after "FlightArrived" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterFlightArrived(From, Event, To)
  self:T(self.lid..string.format("Flight arrived"))

  -- Flight Control
  if self.flightcontrol then
    -- Add flight to arrived queue.
    self.flightcontrol:SetFlightStatus(self, FLIGHTCONTROL.FlightStatus.ARRIVED)    
  end
  
  -- Stop and despawn in 5 min.
  self:__Stop(5*60)  
end

--- On after "FlightDead" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterFlightDead(From, Event, To)
  self:I(self.lid..string.format("Flight dead!"))

  -- Delete waypoints so they are re-initialized at the next spawn.
  self.waypoints=nil
  self.groupinitialized=false
  
  -- Remove flight from all FC queues.
  if self.flightcontrol then  
    self.flightcontrol:_RemoveFlight(self)
    self.flightcontrol=nil
  end
  
  -- Cancel all mission.    
  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG
  
    self:MissionCancel(mission)
    mission:FlightDead(self)
  
  end
  
  -- Stop
  self:Stop()
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

  if self:IsAlive() and (self:IsAirborne() or self:IsWaiting() or self:IsInbound() or self:IsHolding()) then
    -- Alive & Airborne ==> Update route possible.
    self:T3(self.lid.."Update route possible. Group is ALIVE and AIRBORNE or WAITING or INBOUND or HOLDING")
  elseif self:IsDead()  then
    -- Group is dead! No more updates.
    self:E(self.lid.."Update route denied. Group is DEAD!")
    allowed=false
  else
    -- Not airborne yet. Try again in 1 sec.
    self:T3(self.lid.."FF update route denied ==> checking back in 5 sec")
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
    self:E(self.lid.."FF update route denied because N=nil or N<1")
    trepeat=-5
    allowed=false    
  end
  
  if self.taskcurrent>0 then
    self:E(self.lid.."Update route denied because taskcurrent>0")
    allowed=false
  end
  
  -- Not good, because mission will never start. Better only check if there is a current task!
  --if self.currentmission then
  --end

  -- Only AI flights.  
  if not self.ai then
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
  self:_UpdateWaypointTasks()

  -- Waypoints.
  local wp={}
  
  -- Current velocity.
  local speed=self.group and self.group:GetVelocityKMH() or 100
  
  -- Set current waypoint or we get problem that the _PassingWaypoint function is triggered too early, i.e. right now and not when passing the next WP.
  local current=self.group:GetCoordinate():WaypointAir("BARO", COORDINATE.WaypointType.TurningPoint, COORDINATE.WaypointAction.TurningPoint, speed, true, nil, {}, "Current")
  table.insert(wp, current)
  
  -- Add remaining waypoints to route.
  for i=n, #self.waypoints do
    table.insert(wp, self.waypoints[i])
  end
  
  -- Debug info.
  local hb=self.homebase and self.homebase:GetName() or "unknown"
  local db=self.destbase and self.destbase:GetName() or "unknown"
  self:T(self.lid..string.format("Updating route for WP #%d-%d  homebase=%s destination=%s", n, #wp, hb, db))

  
  if #wp>1 then

    -- Route group to all defined waypoints remaining.
    self:Route(wp, 1)
    
  else
  
    ---
    -- No waypoints left
    ---
  
    self:_CheckFlightDone()
          
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

--- On after "PassingWaypoint" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number n Waypoint number passed.
-- @param #number N Final waypoint number.
function FLIGHTGROUP:onafterPassingWaypoint(From, Event, To, n, N)
  local text=string.format("Flight passed waypoint %d/%d", n, N)
  self:T(self.lid..text)
  MESSAGE:New(text, 30, "DEBUG"):ToAllIf(self.Debug)
  
  -- Get all waypoint tasks.
  local tasks=self:GetTasksWaypoint(n)
  
  -- Debug info.
  local text=string.format("WP %d/%d tasks:", n, N)
  if #tasks>0 then
    for i,_task in pairs(tasks) do
      local task=_task --#FLIGHTGROUP.Task
      text=text..string.format("\n[%d] %s", i, task.description)
    end
  else
    text=text.." None"
  end
  self:T(self.lid..text)
  

  -- Tasks at this waypoints.
  local taskswp={}
  
  -- TODO: maybe set waypoint enroute tasks?
    
  for _,task in pairs(tasks) do
    local Task=task --#FLIGHTGROUP.Task          
    
    -- Task execute.
    table.insert(taskswp, self.group:TaskFunction("FLIGHTGROUP._TaskExecute", self, Task))

    -- Stop condition if userflag is set to 1 or task duration over.
    local TaskCondition=self.group:TaskCondition(nil, Task.stopflag:GetName(), 1, nil, Task.duration)
    
    -- Controlled task.      
    table.insert(taskswp, self.group:TaskControlled(Task.dcstask, TaskCondition))
   
    -- Task done.
    table.insert(taskswp, self.group:TaskFunction("FLIGHTGROUP._TaskDone", self, Task))
    
  end

  -- Execute waypoint tasks.
  if #taskswp>0 then
    self:SetTask(self.group:TaskCombo(taskswp))
  end
  
  -- Final AIR waypoint reached?
  if n==N then

    -- Set switch to true.    
    self.passedfinalwp=true
    
    -- Check if all tasks/mission are done? If so, RTB or WAIT.
    -- Note, we delay it for a second to let the OnAfterPassingwaypoint function to be executed in case someone wants to add another waypoint there.
    if #taskswp==0 then
      self:_CheckFlightDone(1)
    end

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
function FLIGHTGROUP:_CheckFlightDone(delay)

  if self:IsAlive() and self.ai then

    if delay and delay>0 then
      -- Delayed call.
      self:ScheduleOnce(delay, FLIGHTGROUP._CheckFlightDone, self)
    else
    
      -- First check if there is a paused mission that 
      if self.missionpaused then
        self:UnpauseMission()
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
      
            -- Send flight to destination.
            if self.destbase then
              self:I(self.lid.."Passed Final WP and No current and/or future missions/task ==> RTB!")
              self:__RTB(-3, self.destbase)
            elseif self.destzone then
              self:I(self.lid.."Passed Final WP and No current and/or future missions/task ==> RTZ!")
              self:__RTZ(-3, self.destzone)
            else
              self:I(self.lid.."Passed Final WP and NO Tasks/Missions left. No DestBase or DestZone ==> Wait!")
              self:__Wait(-1)        
            end
            
          else
              self:I(self.lid..string.format("Passed Final WP but Tasks=%d or Missions=%d left in the queue. Wait!", nTasks, nMissions))
              self:__Wait(-1)              
          end
        else
          self:I(self.lid..string.format("Passed Final WP but still have current Task (#%s) or Mission (#%s) left to do", tostring(self.taskcurrent), tostring(self.currentmission)))
        end  
      else
        self:I(self.lid..string.format("Flight (status=%s) did NOT pass the final waypoint yet ==> update route", self:GetState()))
        self:__UpdateRoute(-1)
      end  
    end
    
  end
  
end

--- On after "GotoWaypoint" event. Group will got to the given waypoint and execute its route from there.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number n The goto waypoint number.
function FLIGHTGROUP:onafterGotoWaypoint(From, Event, To, n)

  -- The last waypoint passed was n-1
  self.currentwp=n-1
  
  -- TODO: switch to re-enable waypoint tasks.
  if false then
    local tasks=self:GetTasksWaypoint(n)
    
    for _,_task in pairs(tasks) do
      local task=_task --#FLIGHTGROUP.Task
      task.status=FLIGHTGROUP.TaskStatus.SCHEDULED
    end
    
  end
  
  -- Update the route.
  self:UpdateRoute()
  
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
      self:I(self.lid..string.format("WARNING: Group is not AIRBORNE  ==> RTB event is suspended for 10 sec."))
      allowed=false
      Tsuspend=-10  
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

  self:I(self.lid..string.format("RTB: event=%s: %s --> %s to %s", Event, From, To, airbase:GetName()))
  
  -- Set the destination base.
  self.destbase=airbase
  
  -- Clear holding time in any case.
  self.Tholding=nil
  
  -- Defaults:
  SpeedTo=SpeedTo or UTILS.KmphToKnots(self.speedCruise)
  SpeedHold=SpeedHold or (self.ishelo and 80 or 250)
  SpeedLand=SpeedLand or (self.ishelo and 40 or 170)

  -- Debug message.
  local text=string.format("Flight group set to hold at airbase %s. SpeedTo=%d, SpeedHold=%d, SpeedLand=%d", airbase:GetName(), SpeedTo, SpeedHold, SpeedLand)
  MESSAGE:New(text, 10, "DEBUG"):ToAllIf(self.Debug)
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
 
  if self.ai then
 
    local routeto=false
    if fc or world.event.S_EVENT_KILL then
      routeto=true
    end
  
    -- Clear all tasks.
    self:ClearTasks()
   
    -- Respawn?
    if routeto then
    
      --self:I(self.lid.."FF route (not repawn)")
      
      -- Just route the group. Respawn might happen when going from holding to final.
      self:Route(wp, 1)
   
    else 
    
      --self:I(self.lid.."FF respawn (not route)")
    
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
  MESSAGE:New(text, 30, "DEBUG"):ToAllIf(self.Debug)
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
  MESSAGE:New(text, 30, "DEBUG"):ToAllIf(self.Debug)
  self:I(self.lid..text)

  --TODO: set ROE passive. introduce roe event/state/variable.

  --TODO: cancel current task

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
  
  self:Route({wp0, wp9})
  
end

--- On after "Refueled" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterRefueled(From, Event, To)
  -- Debug message.
  local text=string.format("Flight group finished refuelling")
  MESSAGE:New(text, 30, "DEBUG"):ToAllIf(self.Debug)
  self:I(self.lid..text)
  
  -- Check if flight is done.
  self:_CheckFlightDone(1)
  
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
  MESSAGE:New(text, 10, "DEBUG"):ToAllIf(self.Debug)
  self:I(self.lid..text)
  
  -- Add flight to waiting/holding queue.
  if self.flightcontrol then
    
    -- Set flight status to holding
    self.flightcontrol:SetFlightStatus(self, FLIGHTCONTROL.FlightStatus.HOLDING)
    
    if not self.ai then
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

--- On after "EngageTargets" event. Order to engage a set of units.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Set#SET_UNIT TargetUnitSet
function FLIGHTGROUP:onafterEngageTargets(From, Event, To, TargetUnitSet)

  local DCSTasks={}
  
  for _,_unit in paris(TargetUnitSet:GetSet()) do
    local unit=_unit  --Wrapper.Unit#UNIT
    local task=self.group:TaskAttackUnit(unit, true)
    table.insert(DCSTasks)
  end
  
  -- Task combo.
  local DCSTask=self.group:TaskCombo(DCSTasks)
  
  --TODO needs a task function that calls EngageDone or so event and updates the route again.
  
  -- Lets try if pushtask actually leaves the remaining tasks untouched.
  self:SetTask(DCSTask)
  
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
  MESSAGE:New(text, 30, "DEBUG"):ToAllIf(self.Debug)
  self:I(self.lid..text)
  
  -- Set switch to true.
  self.fuellow=true

  -- Back to destination or home.
  local airbase=self.destbase or self.homebase
  
  if self.airwing then
  
    -- Get closest tanker from airwing that can refuel this flight.
    local tanker=self.airwing:GetTankerForFlight(self)
    
    if tanker then
    
      -- Send flight to tanker with refueling task.
      self:Refuel(tanker.flightgroup:GetCoordinate())
      
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
    
        self:Refuel()
        
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
  MESSAGE:New(text, 30, "DEBUG"):ToAllIf(self.Debug)
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




-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Task functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------





--- On after TaskExecute event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #FLIGHTGROUP.Task Task The task.
function FLIGHTGROUP:onafterTaskExecute(From, Event, To, Task)

  -- Debug message.
  local text=string.format("Task %s ID=%d execute.", tostring(Task.description), Task.id)
  MESSAGE:New(text, 10, "DEBUG"):ToAllIf(self.Debug)
  self:I(self.lid..text)
  
  -- Cancel current task if there is any.
  if self.taskcurrent>0 then
    self:TaskCancel()
  end

  -- Set current task.
  self.taskcurrent=Task.id
  
  -- Set time stamp.
  Task.timestamp=timer.getAbsTime()

  -- Task status executing.
  Task.status=FLIGHTGROUP.TaskStatus.EXECUTING
  
  if Task.dcstask.id=="Formation" then

    -- Set of group(s) to follow Mother.
    local followSet=SET_GROUP:New():AddGroup(self.group)
    
    local param=Task.dcstask.params
    
    local followUnit=UNIT:FindByName(param.unitname)
    
    -- Define AI Formation object.
    Task.formation=AI_FORMATION:New(followUnit, followSet, "Formation", "Follow X at given parameters.")
    
    -- Formation parameters.
    Task.formation:FormationCenterWing(-param.offsetX, 50, math.abs(param.altitude), 50, param.offsetZ, 50)
    
    -- Set follow time interval.
    Task.formation:SetFollowTimeInterval(param.dtFollow)
    
    -- Formation mode.
    Task.formation:SetFlightModeFormation(self.group)
    
    -- Start formation FSM.
    Task.formation:Start()  
  
  else

    -- If task is scheduled (not waypoint) set task.
    if Task.type==FLIGHTGROUP.TaskType.SCHEDULED then
      
      local DCStasks={}
      if Task.dcstask.id=='ComboTask' then
        -- Loop over all combo tasks.
        for TaskID, Task in ipairs(Task.dcstask.params.tasks) do
          table.insert(DCStasks, Task)
        end    
      else
        table.insert(DCStasks, Task.dcstask)
      end
  
      -- Combo task.
      local TaskCombo=self.group:TaskCombo(DCStasks)
  
      -- Stop condition!    
      local TaskCondition=self.group:TaskCondition(nil, Task.stopflag:GetName(), 1, nil, Task.duration)
      
      -- Controlled task.      
      local TaskControlled=self.group:TaskControlled(TaskCombo, TaskCondition)
      
      -- Task done.
      local TaskDone=self.group:TaskFunction("FLIGHTGROUP._TaskDone", self, Task)
      
      -- Final task.
      local TaskFinal=self.group:TaskCombo({TaskControlled, TaskDone})
        
      -- Set task for group.
      self:SetTask(TaskFinal, 1)
          
    end
    
  end

  -- Get mission of this task (if any).
  local Mission=self:GetMissionByTaskID(self.taskcurrent)
  if Mission then
    -- Set AUFTRAG status.
    self:MissionExecute(Mission)
  end
  
end

--- On after "TaskPause" event. Pauses the current task.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterTaskPause(From, Event, To)

  local Task=self:GetTaskCurrent()

  if Task then

    -- Clear all tasks.
    self:ClearTasks()

    -- Task status executing.
    Task.status=FLIGHTGROUP.TaskStatus.PAUSED

  end

end

--- On after "TaskUnPause" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterTaskUnpause(From, Event, To)

  --self.task
end

--- On after "TaskCancel" event. Cancels the current task or simply sets the status to DONE if the task is not the current one.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #FLIGHTGROUP.Task Task The task to cancel. Default is the current task (if any).
function FLIGHTGROUP:onafterTaskCancel(From, Event, To, Task)
  
  -- Get current task.
  local currenttask=self:GetTaskCurrent()
  
  -- If no task, we take the current task. But this could also be *nil*!
  Task=Task or currenttask
  
  if Task then
  
    -- Check if the task is the current task?
    if currenttask and Task.id==currenttask.id then
    
      -- Current stop flag value. I noticed cases, where setting the flag to 1 would not cancel the task, e.g. when firing HARMS on a dead ship.
      local stopflag=Task.stopflag:Get()
    
      -- Debug info.
      local text=string.format("Current task %s ID=%d cancelled (flag %s=%d)", Task.description, Task.id, Task.stopflag:GetName(), stopflag)
      MESSAGE:New(text, 10, "DEBUG"):ToAllIf(self.Debug)    
      self:I(self.lid..text)
      
      -- Set stop flag. When the flag is true, the _TaskDone function is executed and calls :TaskDone()
      Task.stopflag:Set(1)
      
      if Task.dcstask.id=="Formation" then
        Task.formation:Stop()
        self:TaskDone(Task)
      elseif stopflag==1 then
        -- Manual call TaskDone if setting flag to one was not successful.
        self:TaskDone(Task)
      end
  
    else
            
      -- Debug info.
      self:I(self.lid..string.format("TaskCancel: Setting task %s ID=%d to DONE", Task.description, Task.id))
      
      -- Call task done function.      
      self:TaskDone(Task)
      
      
      --[[
      local mission=self:GetMissionByTaskID(Task.id)
      
      -- Is this a waypoint task?
      if Task.type==FLIGHTGROUP.TaskType.WAYPOINT and Task.waypoint then

        -- Check that this is a mission waypoint and no other tasks are defined here.      
        if mission and #self:GetTasksWaypoint(Task.waypoint)==0 then
          self:RemoveWaypoint(Task.waypoint)
        end
      end
      ]]
    end
    
  else
  
    local text=string.format("WARNING: No (current) task to cancel!")
    MESSAGE:New(text, 10, "DEBUG"):ToAllIf(self.Debug)
    self:E(self.lid..text)
    
  end
  
end

--- On before "TaskDone" event. Deny transition if task status is PAUSED.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #FLIGHTGROUP.Task Task
function FLIGHTGROUP:onbeforeTaskDone(From, Event, To, Task)

  local allowed=true

  if Task.status==FLIGHTGROUP.TaskStatus.PAUSED then
    allowed=false
  end

  return allowed
end

--- On after "TaskDone" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #FLIGHTGROUP.Task Task
function FLIGHTGROUP:onafterTaskDone(From, Event, To, Task)

  -- Debug message.
  local text=string.format("Task done: %s ID=%d", Task.description, Task.id)
  MESSAGE:New(text, 10, "DEBUG"):ToAllIf(self.Debug)
  self:I(self.lid..text)

  -- No current task.
  if Task.id==self.taskcurrent then
    self.taskcurrent=0
  end
  
  -- Task status done.
  Task.status=FLIGHTGROUP.TaskStatus.DONE
  
  -- Check if this task was the task of the current mission ==> Mission Done!
  local Mission=self:GetMissionByTaskID(Task.id)
  
  if Mission and Mission:IsNotOver() then
  
    local status=Mission:GetFlightStatus(self)  
  
    if status~=AUFTRAG.FlightStatus.PAUSED then
      self:I(self.lid.."FF Task Done ==> Mission Done!")
      self:MissionDone(Mission)
    else
      --Mission paused. Do nothing!
    end
  else
    self:I(self.lid.."FF Task Done but NO mission found ==> _CheckFlightDone in 1 sec")
    self:_CheckFlightDone(1)
  end
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Mission functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On before "MissionStart" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.Auftrag#AUFTRAG Mission The mission table.
function FLIGHTGROUP:onbeforeMissionStart(From, Event, To, Mission)

  -- Debug info.
  self:I(self.lid..string.format("Starting mission %s, FSM=%s, LateActivated=%s, UnControlled=%s", tostring(Mission.name), self:GetState(), tostring(self:IsLateActivated()), tostring(self:IsUncontrolled())))

  -- Delay for route to mission. Group needs to be activated and controlled.
  local delay=1

  -- Check if group is spawned.
  if self:IsInUtero() then

    -- Activate group if it is late activated.
    if self:IsLateActivated() then
      self:Activate(delay)
      delay=delay+1
    end
  
  end
  
  -- Startup group if it is uncontrolled.
  if self:IsParking() and self:IsUncontrolled() then
    self:StartUncontrolled(delay)
  else
    --env.info("FF hallo!")
    --self:StartUncontrolled(5)
  end  

  return true
end

--- On after "MissionStart" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.Auftrag#AUFTRAG Mission The mission table.
function FLIGHTGROUP:onafterMissionStart(From, Event, To, Mission)

  -- Debug output.
  local text=string.format("Starting %s Mission %s, target %s", Mission.type, tostring(Mission.name), Mission:GetTargetName())
  self:T(self.lid..text)
  MESSAGE:New(text, 30, self.groupname):ToAllIf(true)

  -- Set current mission.
  self.currentmission=Mission.auftragsnummer
    
  -- Set flight mission status to STARTED.
  Mission:SetFlightStatus(self, AUFTRAG.FlightStatus.STARTED)
  
  -- Set mission status to STARTED.
  Mission:Started()

  -- Route flight to mission zone.
  self:RouteToMission(Mission, 3)
  
end

--- On after "MissionExecute" event. Mission execution began.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.Auftrag#AUFTRAG Mission The mission table.
function FLIGHTGROUP:onafterMissionExecute(From, Event, To, Mission)

  local text=string.format("Executing %s Mission %s, target %s", Mission.type, tostring(Mission.name), Mission:GetTargetName())
  self:T(self.lid..text)
  MESSAGE:New(text, 30, self.groupname):ToAllIf(true)
  
  -- Set flight mission status to EXECUTING.
  Mission:SetFlightStatus(self, AUFTRAG.FlightStatus.EXECUTING)
  
  -- Set mission status to EXECUTING.
  Mission:Executing()
  
  -- Formation
  if Mission.optionFormation then
    self:SwitchFormation(Mission.optionFormation)
  end  
  
end

--- On after "PauseMission" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterPauseMission(From, Event, To)

  local Mission=self:GetMissionCurrent()
  
  if Mission then

    -- Set flight mission status to PAUSED.
    Mission:SetFlightStatus(self, AUFTRAG.FlightStatus.PAUSED)
  
    -- Get mission waypoint task.
    local Task=Mission:GetFlightWaypointTask(self)
    
    -- Debug message.
    self:I(self.lid..string.format("FF pausing current mission %s. Task=%s", tostring(Mission.name), tostring(Task and Task.description or "WTF")))
  
    -- Cancelling the mission is actually cancelling the current task.
    self:TaskCancel(Task)
    
    -- Set mission to pause so we can unpause it later.
    self.missionpaused=Mission
    
  end

end

--- On after "UnpauseMission" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLIGHTGROUP:onafterUnpauseMission(From, Event, To)

  self:I(self.lid..string.format("Unpausing mission"))
  
  if self.missionpaused then
  
    local mission=self:GetMissionByID(self.missionpaused.auftragsnummer)
    
    self:MissionStart(mission)
    
    self.missionpaused=nil
  else
    self:E(self.lid.."ERROR: No mission to unpause!")
  end
  
end


--- On after "MissionCancel" event. Cancels the mission.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.Auftrag#AUFTRAG Mission The mission to be cancelled.
function FLIGHTGROUP:onafterMissionCancel(From, Event, To, Mission)

  if self.currentmission and Mission.auftragsnummer==self.currentmission then
    
    -- Get mission waypoint task.
    local Task=Mission:GetFlightWaypointTask(self)
    
    -- Debug info.
    self:I(self.lid..string.format("FF Cancel current mission %s. Task=%s", tostring(Mission.name), tostring(Task and Task.description or "WTF")))

    -- Cancelling the mission is actually cancelling the current task.
    -- Note that two things can happen.
    -- 1.) Flight is still on the way to the waypoint (status should be STARTED). In this case there would not be a current task!
    -- 2.) Flight already passed the mission waypoint (status should be EXECUTING).
    
    self:TaskCancel(Task)
        
  else
  
    -- Not the current mission.
    -- TODO: remove mission from queue?
 
    -- Set mission flight status.
    Mission:SetFlightStatus(self, AUFTRAG.FlightStatus.CANCELLED) 
    
    -- Send flight RTB or WAIT if nothing left to do.
    self:_CheckFlightDone(1)
    
  end
  
end

--- On after "MissionDone" event.
-- @param #FLIGHTGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.Auftrag#AUFTRAG Mission
function FLIGHTGROUP:onafterMissionDone(From, Event, To, Mission)

  -- Debug info.
  local text=string.format("Mission %s DONE!", Mission.name)
  self:I(self.lid..text)
  MESSAGE:New(text, 30, self.groupname):ToAllIf(true)
  
  -- Set Flight status.
  Mission:SetFlightStatus(self, AUFTRAG.FlightStatus.DONE)
  
  -- Set current mission to nil.
  if self.currentmission and Mission.auftragsnummer==self.currentmission then
    self.currentmission=nil
  end
  
  -- Remove mission waypoint.
  local wpidx=Mission:GetFlightWaypointIndex(self)
  if wpidx then
    self:RemoveWaypoint(wpidx)
  end
  
  -- Decrease patrol data.
  if Mission.patroldata then
    Mission.patroldata.noccupied=Mission.patroldata.noccupied-1
    AIRWING.UpdatePatrolPointMarker(Mission.patroldata)
  end

  -- TODO: reset mission specific parameters like radio, ROE etc.  
  
  -- Check if flight is done.
  self:_CheckFlightDone(1)

end

--- Route group to mission.
-- @param #FLIGHTGROUP self
-- @param Ops.Auftrag#AUFTRAG mission The mission table.
-- @param #number delay Delay in seconds.
function FLIGHTGROUP:RouteToMission(mission, delay)

  if delay and delay>0 then
    -- Delayed call.
    self:ScheduleOnce(delay, FLIGHTGROUP.RouteToMission, self, mission)
  else
        
    -- Next waypoint.
    local nextwaypoint=self.currentwp+1
    
    -- Create waypoint coordinate half way between us and the target.
    local waypointcoord=self.group:GetCoordinate():GetIntermediateCoordinate(mission:GetTargetCoordinate(), mission.missionFraction)
    local alt=waypointcoord.y
    
    -- Add some randomization.
    waypointcoord=ZONE_RADIUS:New("Temp", waypointcoord:GetVec2(), 1000):GetRandomCoordinate():SetAltitude(alt, false)
    
    -- Set altitude of mission waypoint.
    if mission.missionAltitude then
      waypointcoord:SetAltitude(mission.missionAltitude, true)
    end
    env.info(string.format("FF mission alt=%d", waypointcoord.y))
    
    -- Add enroute tasks.
    for _,task in pairs(mission.enrouteTasks) do
      self:AddTaskEnroute(task)
    end
  
    -- Add waypoint.
    self:AddWaypointAir(waypointcoord, nextwaypoint, UTILS.KmphToKnots(self.speedCruise), false)
    
    -- Special for Troop transport.
    if mission.type==AUFTRAG.Type.TROOPTRANSPORT then
    
      -- Refresh DCS task with the known controllable.  
      mission.DCStask=mission:GetDCSMissionTask(self.group)
            
      -- Add task to embark for the troops.
      for _,_group in pairs(mission.transportGroupSet.Set) do
        local group=_group --Wrapper.Group#GROUP
        
        if group and group:IsAlive() then
          local DCSTask=group:TaskEmbarkToTransport(mission.transportPickup, 500)
          group:SetTask(DCSTask, 5)
        end
      
      end
    
    end
    
    -- Add waypoint task. UpdateRoute is called inside.
    local waypointtask=self:AddTaskWaypoint(mission.DCStask, nextwaypoint, mission.name, mission.prio, mission.duration)
    
    -- Set waypoint task.
    mission:SetFlightWaypointTask(self, waypointtask)
    
    -- Set waypoint index.
    mission:SetFlightWaypointIndex(self, nextwaypoint)
    
    ---
    -- Mission Specific Settings
    ---
    
    -- ROE
    if mission.optionROE then
      self:SetOptionROE(mission.optionROE)
    end
    -- ROT
    if mission.optionROT then
      self:SetOptionROT(mission.optionROT)
    end
    -- Radio
    if mission.radioFreq then
      self:SwitchRadioOn(mission.radioFreq, mission.radioModu)
    end
    -- TACAN
    if mission.tacanChannel then
      self:SwitchTACANOn(mission.tacanChannel, mission.tacanMorse)
    end
    -- Formation
    if mission.optionFormation then
      self:SwitchFormation(mission.optionFormation)
    end
    
  end
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Special Task Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Function called when flight has reached the holding point.
-- @param Wrapper.Group#GROUP group Group object.
-- @param #FLIGHTGROUP flightgroup Flight group object.
function FLIGHTGROUP._ReachedHolding(group, flightgroup)
  flightgroup:I(flightgroup.lid..string.format("Group reached holding point"))

  -- Trigger Holding event.
  flightgroup:__Holding(-1)
end

--- Function called when flight has reached the holding point.
-- @param Wrapper.Group#GROUP group Group object.
-- @param #FLIGHTGROUP flightgroup Flight group object.
function FLIGHTGROUP._ClearedToLand(group, flightgroup)
  flightgroup:I(flightgroup.lid..string.format("Group was cleared to land"))

  -- Trigger FlightLanding event.
  flightgroup:__FlightLanding(-1)
end

--- Function called when flight finished refuelling.
-- @param Wrapper.Group#GROUP group Group object.
-- @param #FLIGHTGROUP flightgroup Flight group object.
function FLIGHTGROUP._FinishedRefuelling(group, flightgroup)
  flightgroup:T(flightgroup.lid..string.format("Group finished refueling"))

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

  -- Get template of group.
  self.template=self.group:GetTemplate()

  -- Helo group.
  self.ishelo=self.group:IsHelicopter()
  
  -- Is (template) group uncontrolled.
  self.isUncontrolled=self.template.uncontrolled
  
  -- Is (template) group late activated.
  self.isLateActivated=self.template.lateActivation
  
  -- Max speed in km/h.
  self.speedmax=self.group:GetSpeedMax()
  
  -- Cruise speed limit 350 kts for fixed and 80 knots for rotary wings.
  local speedCruiseLimit=self.ishelo and UTILS.KnotsToKmph(80) or UTILS.KnotsToKmph(350)
  
  -- Cruise speed: 70% of max speed but within limit.
  self.speedCruise=math.min(self.speedmax*0.7, speedCruiseLimit)
  
  -- Group ammo.
  self.ammo=self:GetAmmoTot()
  
  -- Initial fuel mass.
  -- TODO: this is a unit property!
  self.fuelmass=0
  
  self.traveldist=0
  self.traveltime=timer.getAbsTime()
  self.position=self:GetCoordinate()
  
  -- Radio parameters from template.
  self.radioOn=self.template.communication
  self.radioFreq=self.template.frequency
  self.radioModu=self.template.modulation
  
  -- If not set by the use explicitly yet, we take the template values as defaults.
  if not self.radioFreqDefault then
    self.radioFreqDefault=self.radioFreq
    self.radioModuDefault=self.radioModu
  end
  
  -- Set default formation.
  if not self.formationDefault then
    if self.ishelo then
      self.formationDefault=ENUMS.Formation.RotaryWing.EchelonLeft.D300
    else
      self.formationDefault=ENUMS.Formation.FixedWing.EchelonLeft.Group
    end
  end
  
  self.ai=not self:_IsHuman(self.group)
  
  if not self.ai then
    self.menu=self.menu or {}
    self.menu.atc=self.menu.atc or {}
    self.menu.atc.root=self.menu.atc.root or MENU_GROUP:New(self.group, "ATC")  
  end
  
  self:SwitchFormation(self.formationDefault)
  
  -- Get first unit. This is used to extract other parameters.
  local unit=self.group:GetUnit(1)
  
  if unit then
    
    self.rangemax=unit:GetRange()
    
    self.descriptors=unit:GetDesc()
    
    self.actype=unit:GetTypeName()
    
    self.ceiling=self.descriptors.Hmax
    
    self.tankertype=select(2, unit:IsTanker())
    self.refueltype=select(2, unit:IsRefuelable())
  
    -- Init waypoints.
    if not self.waypoints then
      self:InitWaypoints()
    end
    
    -- Debug info.
    local text=string.format("Initialized Flight Group %s:\n", self.groupname)
    text=text..string.format("AC type      = %s\n", self.actype)
    text=text..string.format("Speed max    = %.1f Knots\n", UTILS.KmphToKnots(self.speedmax))
    text=text..string.format("Range max    = %.1f km\n", self.rangemax/1000)
    text=text..string.format("Ceiling      = %.1f feet\n", UTILS.MetersToFeet(self.ceiling))
    text=text..string.format("Tanker type  = %s\n", tostring(self.tankertype))
    text=text..string.format("Refuel type  = %s\n", tostring(self.refueltype))
    text=text..string.format("AI           = %s\n", tostring(self.ai))
    text=text..string.format("Helicopter   = %s\n", tostring(self.group:IsHelicopter()))
    text=text..string.format("Elements     = %d\n", #self.elements)
    text=text..string.format("Waypoints    = %d\n", #self.waypoints)
    text=text..string.format("Radio        = %.1f MHz %s %s\n", self.radioFreq, UTILS.GetModulationName(self.radioModu), tostring(self.radioOn))
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
    element.status=FLIGHTGROUP.ElementStatus.INUTERO
    element.group=unit:GetGroup()
    
    element.modex=element.unit:GetTemplate().onboard_num
    element.skill=element.unit:GetTemplate().skill
    element.pylons=element.unit:GetTemplatePylons()
    element.fuelmass0=element.unit:GetTemplatePayload().fuel
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
    
    local text=string.format("Adding element %s: status=%s, skill=%s, modex=%s, fuelmass=%.1f (%d %%), category=%d, categoryname=%s, callsign=%s, ai=%s",
    element.name, element.status, element.skill, element.modex, element.fuelmass, element.fuelrel, element.category, element.categoryname, element.callsign, tostring(element.ai))
    self:I(self.lid..text)

    -- Add element to table.
    table.insert(self.elements, element)

    return element
  end

  return nil
end

--- Check if a unit is and element of the flightgroup.
-- @param #FLIGHTGROUP self
-- @param #string unitname Name of unit.
-- @return #FLIGHTGROUP.Element The element.
function FLIGHTGROUP:GetElementByName(unitname)

  for _,_element in pairs(self.elements) do
    local element=_element --#FLIGHTGROUP.Element

    if element.name==unitname then
      return element
    end

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
      local airbaseID=wp.airdromeId or wp.helipadId
      
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
-- @return Wrapper.Group#GROUP Closest tanker group #nil.
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


--- Check if this group is currently "late activated" and needs to be "activated" to appear in the mission.
-- @param #FLIGHTGROUP self
-- @return #boolean Is this the group late activated?
function FLIGHTGROUP:IsLateActivated()
  return self.isLateActivated
end

--- Check if this group is currently "uncontrolled" and needs to be "started" to begin its route.
-- @param #FLIGHTGROUP self
-- @return #boolean If this group uncontrolled.
function FLIGHTGROUP:IsUncontrolled()
  return self.isUncontrolled
end

--- Check if task description is unique.
-- @param #FLIGHTGROUP self
-- @param #string description Task destription
-- @return #boolean If true, no other task has the same description.
function FLIGHTGROUP:CheckTaskDescriptionUnique(description)

  -- Loop over tasks in queue
  for _,_task in pairs(self.taskqueue) do
    local task=_task --#FLIGHTGROUP.Task
    if task.description==description then
      return false
    end    
  end
  
  return true
end




--- Get next waypoint of the flight group.
-- @param #FLIGHTGROUP self
-- @return Core.Point#COORDINATE Coordinate of the next waypoint.
-- @return #number Number of waypoint.
function FLIGHTGROUP:GetNextWaypoint()

  -- Next waypoint.
  local Nextwp=nil
  if self.currentwp==#self.waypoints then
    Nextwp=1
  else
    Nextwp=self.currentwp+1
  end

  -- Next waypoint.
  local nextwp=self.waypoints[Nextwp] --Core.Point#COORDINATE

  return nextwp,Nextwp
end

--- Get next waypoint coordinates.
-- @param #FLIGHTGROUP self
-- @param #table wp Waypoint table.
-- @return Core.Point#COORDINATE Coordinate of the next waypoint.
function FLIGHTGROUP:GetWaypointCoordinate(wp)
  -- TODO: move this to COORDINATE class.
  return COORDINATE:New(wp.x, wp.alt, wp.y)
end

--- Initialize Mission Editor waypoints.
-- @param #FLIGHTGROUP self
function FLIGHTGROUP:_UpdateWaypointTasks()

  local waypoints=self.waypoints
  local nwaypoints=#waypoints

  for i,wp in pairs(waypoints) do
    
    if i>self.currentwp or nwaypoints==1 then
    
      -- Debug info.
      self:T2(self.lid..string.format("Updating waypoint task for waypoint %d/%d. Last waypoint passed %d.", i, nwaypoints, self.currentwp))
  
      -- Tasks of this waypoint
      local taskswp={}
    
      -- At each waypoint report passing.
      local TaskPassingWaypoint=self.group:TaskFunction("FLIGHTGROUP._PassingWaypoint", self, i)      
      table.insert(taskswp, TaskPassingWaypoint)      
          
      -- Waypoint task combo.
      wp.task=self.group:TaskCombo(taskswp)
      
    end
  end

end

--- Initialize Mission Editor waypoints.
-- @param #FLIGHTGROUP self
-- @param #table waypoints Table of waypoints. Default is from group template.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:InitWaypoints(waypoints)

  -- Template waypoints.
  self.waypoints0=self.group:GetTemplateRoutePoints()

  -- Waypoints of group as defined in the ME.
  self.waypoints=waypoints or UTILS.DeepCopy(self.waypoints0)
  
  -- Get home and destination airbases from waypoints.
  self.homebase=self:GetHomebaseFromWaypoints()
  self.destbase=self:GetDestinationFromWaypoints()
  
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
    
    -- Update route (when airborne).
    --self:_CheckFlightDone(1)
    self:__UpdateRoute(-1)
  end

  return self
end

--- Add a waypoint to the flight plan.
-- @param #FLIGHTGROUP self
-- @param Core.Point#COORDINATE coordinate The coordinate of the waypoint. Use COORDINATE:SetAltitude(altitude) to define the altitude.
-- @param #number wpnumber Waypoint number. Default at the end.
-- @param #number speed Speed in knots. Default 350 kts.
-- @param #boolean updateroute If true or nil, call UpdateRoute. If false, no call.
-- @return #number Waypoint index.
function FLIGHTGROUP:AddWaypointAir(coordinate, wpnumber, speed, updateroute)

  -- Waypoint number. Default is at the end.
  wpnumber=wpnumber or #self.waypoints+1
  
  if wpnumber>self.currentwp then
    self.passedfinalwp=false
  end
  
  -- Speed in knots.
  speed=speed or 350

  -- Speed at waypoint.
  local speedkmh=UTILS.KnotsToKmph(speed)

  -- Create air waypoint.
  local wp=coordinate:WaypointAir(COORDINATE.WaypointAltType.BARO, COORDINATE.WaypointType.TurningPoint, COORDINATE.WaypointAction.TurningPoint, speedkmh, true, nil, {}, string.format("Added Waypoint #%d", wpnumber))
  
  -- Add to table.
  table.insert(self.waypoints, wpnumber, wp)
  
  -- Debug info.
  self:T(self.lid..string.format("Adding AIR waypoint #%d, speed=%.1f knots. Last waypoint passed was #%s. Total waypoints #%d", wpnumber, speed, self.currentwp, #self.waypoints))
  
  -- Shift all waypoint tasks after the inserted waypoint.
  for _,_task in pairs(self.taskqueue) do
    local task=_task --#FLIGHTGROUP.Task
    if task.type==FLIGHTGROUP.TaskType.WAYPOINT and task.waypoint and task.waypoint>=wpnumber then
      task.waypoint=task.waypoint+1
    end
  end  

  -- Shift all mission waypoints after the inserted waypoint.
  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG

    -- Get mission waypoint index.
    local wpidx=mission:GetFlightWaypointIndex(self)
    
    -- Increase number if this waypoint lies in the future.
    if wpidx and wpidx>=wpnumber then
      mission:SetFlightWaypointIndex(self, wpidx+1)
    end    
    
  end
  
  -- Update route.
  if updateroute==nil or updateroute==true then
    self:_CheckFlightDone(1)
    --self:__UpdateRoute(-1)
  end
  
  return wpnumber
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

--- Check if all elements of the flight group have the same status (or are dead).
-- @param #FLIGHTGROUP self
-- @param #string unitname Name of unit.
function FLIGHTGROUP:_AllSameStatus(status)

  for _,_element in pairs(self.elements) do
    local element=_element --#FLIGHTGROUP.Element

    if element.status==FLIGHTGROUP.ElementStatus.DEAD then
      -- Do nothing. Element is already dead and does not count.
    elseif element.status~=status then
      -- At least this element has a different status.
      return false
    end

  end

  return true
end

--- Check if all elements of the flight group have the same status (or are dead).
-- @param #FLIGHTGROUP self
-- @param #string status Status to check.
-- @return #boolean If true, all elements have a similar status.
function FLIGHTGROUP:_AllSimilarStatus(status)

  -- Check if all are dead.
  if status==FLIGHTGROUP.ElementStatus.DEAD then
    for _,_element in pairs(self.elements) do
      local element=_element --#FLIGHTGROUP.Element
      if element.status~=FLIGHTGROUP.ElementStatus.DEAD then
        -- At least one is still alive.
        return false
      end
    end
    return true
  end

  for _,_element in pairs(self.elements) do
    local element=_element --#FLIGHTGROUP.Element
    
    self:T3(self.lid..string.format("Status=%s, element %s status=%s", status, element.name, element.status))

    -- Dead units dont count ==> We wont return false for those.
    if element.status~=FLIGHTGROUP.ElementStatus.DEAD then
    
      ----------
      -- ALIVE
      ----------

      if status==FLIGHTGROUP.ElementStatus.SPAWNED then

        -- Element SPAWNED: Check that others are not still IN UTERO
        if element.status~=status and
          element.status==FLIGHTGROUP.ElementStatus.INUTERO  then
          return false
        end

      elseif status==FLIGHTGROUP.ElementStatus.PARKING then

        -- Element PARKING: Check that the other are not still SPAWNED
        if element.status~=status or
         (element.status==FLIGHTGROUP.ElementStatus.INUTERO or
          element.status==FLIGHTGROUP.ElementStatus.SPAWNED) then
          return false
        end

      elseif status==FLIGHTGROUP.ElementStatus.ENGINEON then

        -- Element TAXIING: Check that the other are not still SPAWNED or PARKING
        if element.status~=status and
         (element.status==FLIGHTGROUP.ElementStatus.INUTERO or
          element.status==FLIGHTGROUP.ElementStatus.SPAWNED or
          element.status==FLIGHTGROUP.ElementStatus.PARKING) then
          return false
        end

      elseif status==FLIGHTGROUP.ElementStatus.TAXIING then

        -- Element TAXIING: Check that the other are not still SPAWNED or PARKING
        if element.status~=status and
         (element.status==FLIGHTGROUP.ElementStatus.INUTERO or
          element.status==FLIGHTGROUP.ElementStatus.SPAWNED or
          element.status==FLIGHTGROUP.ElementStatus.PARKING or
          element.status==FLIGHTGROUP.ElementStatus.ENGINEON) then
          return false
        end        

      elseif status==FLIGHTGROUP.ElementStatus.TAKEOFF then

        -- Element TAKEOFF: Check that the other are not still SPAWNED, PARKING or TAXIING
        if element.status~=status and
         (element.status==FLIGHTGROUP.ElementStatus.INUTERO or
          element.status==FLIGHTGROUP.ElementStatus.SPAWNED or
          element.status==FLIGHTGROUP.ElementStatus.PARKING or
          element.status==FLIGHTGROUP.ElementStatus.ENGINEON or
          element.status==FLIGHTGROUP.ElementStatus.TAXIING) then
          return false
        end

      elseif status==FLIGHTGROUP.ElementStatus.AIRBORNE then

        -- Element AIRBORNE: Check that the other are not still SPAWNED, PARKING, TAXIING or TAKEOFF
        if element.status~=status and
         (element.status==FLIGHTGROUP.ElementStatus.INUTERO or
          element.status==FLIGHTGROUP.ElementStatus.SPAWNED or
          element.status==FLIGHTGROUP.ElementStatus.PARKING or
          element.status==FLIGHTGROUP.ElementStatus.ENGINEON or
          element.status==FLIGHTGROUP.ElementStatus.TAXIING or 
          element.status==FLIGHTGROUP.ElementStatus.TAKEOFF) then
          return false
        end

      elseif status==FLIGHTGROUP.ElementStatus.LANDED then

        -- Element LANDED: check that the others are not still AIRBORNE or LANDING
        if element.status~=status and
         (element.status==FLIGHTGROUP.ElementStatus.AIRBORNE or
          element.status==FLIGHTGROUP.ElementStatus.LANDING) then
          return false
        end

      elseif status==FLIGHTGROUP.ElementStatus.ARRIVED then

        -- Element ARRIVED: check that the others are not still AIRBORNE, LANDING, or LANDED (taxiing).
        if element.status~=status and
         (element.status==FLIGHTGROUP.ElementStatus.AIRBORNE or
          element.status==FLIGHTGROUP.ElementStatus.LANDING  or
          element.status==FLIGHTGROUP.ElementStatus.LANDED)  then
          return false
        end

      end
      
    else
      -- Element is dead. We don't care unless all are dead.
    end --DEAD

  end

  -- Debug info.
  self:T3(self.lid..string.format("All %d elements have similar status %s ==> returning TRUE", #self.elements, status))
  
  return true
end

--- Check if all elements of the flight group have the same status or are dead.
-- @param #FLIGHTGROUP self
-- @param #FLIGHTGROUP.Element element Element.
-- @param #string newstatus New status of element
-- @param Wrapper.Airbase#AIRBASE airbase Airbase if applicable.
function FLIGHTGROUP:_UpdateStatus(element, newstatus, airbase)

  -- Old status.
  local oldstatus=element.status

  -- Update status of element.
  element.status=newstatus
  
  -- Debug
  self:T3(self.lid..string.format("UpdateStatus element=%s: %s --> %s", element.name, oldstatus, newstatus))  
  for _,_element in pairs(self.elements) do
    local Element=_element -- #FLIGHTGROUP.Element
    self:T3(self.lid..string.format("Element %s: %s", Element.name, Element.status))
  end

  if newstatus==FLIGHTGROUP.ElementStatus.SPAWNED then
    ---
    -- SPAWNED
    ---

    if self:_AllSimilarStatus(newstatus) then
      self:__FlightSpawned(-0.5)
    end
    
  elseif newstatus==FLIGHTGROUP.ElementStatus.PARKING then
    ---
    -- PARKING
    ---

    if self:_AllSimilarStatus(newstatus) then
      self:__FlightParking(-0.5)
    end

  elseif newstatus==FLIGHTGROUP.ElementStatus.ENGINEON then
    ---
    -- ENGINEON
    ---

    -- No FLIGHT status. Waiting for taxiing.

  elseif newstatus==FLIGHTGROUP.ElementStatus.TAXIING then
    ---
    -- TAXIING
    ---

    if self:_AllSimilarStatus(newstatus) then
      self:__FlightTaxiing(-0.5)
    end
    
  elseif newstatus==FLIGHTGROUP.ElementStatus.TAKEOFF then
    ---
    -- TAKEOFF
    ---

    if self:_AllSimilarStatus(newstatus) then
      -- Trigger takeoff event. Also triggers airborne event.
      self:__FlightTakeoff(-0.5, airbase)
    end

  elseif newstatus==FLIGHTGROUP.ElementStatus.AIRBORNE then
    ---
    -- AIRBORNE
    ---

    if self:_AllSimilarStatus(newstatus) then
      self:__FlightAirborne(-0.5)
    end

  elseif newstatus==FLIGHTGROUP.ElementStatus.LANDED then
    ---
    -- LANDED
    ---

    if self:_AllSimilarStatus(newstatus) then
      self:FlightLanded(airbase)
    end

  elseif newstatus==FLIGHTGROUP.ElementStatus.ARRIVED then
    ---
    -- ARRIVED
    ---

    if self:_AllSimilarStatus(newstatus) then

      if self:IsLanded() then
        self:FlightArrived()
      elseif self:IsAirborne() then
        self:FlightLanded()
        self:FlightArrived()
      end

    end

  elseif newstatus==FLIGHTGROUP.ElementStatus.DEAD then
    ---
    -- DEAD
    ---

    if self:_AllSimilarStatus(newstatus) then
      self:FlightDead()
    end

  end
end

--- Set status for all elements (except dead ones).
-- @param #FLIGHTGROUP self
-- @param #string status Element status.
function FLIGHTGROUP:_SetElementStatusAll(status)

  for _,_element in pairs(self.elements) do
    local element=_element --#FLIGHTGROUP.Element
    if element.status~=FLIGHTGROUP.ElementStatus.DEAD then
      element.status=status
    end
  end

end

--- Set parking spot of element.
-- @param #FLIGHTGROUP self
-- @param #FLIGHTGROUP.Element Element The element.
-- @param Wrapper.Airbase#AIRBASE.ParkingSpot Spot Parking Spot.
function FLIGHTGROUP:_SetElementParkingAt(Element, Spot)

  -- Element is parking here.
  Element.parking=Spot
    
  if Spot then
  
    env.info(string.format("FF Element %s is parking on spot %d", Element.name, Spot.TerminalID))  
  
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


--- Check if flight is in zones.
-- @param #FLIGHTGROUP self
function FLIGHTGROUP:_CheckInZones()

  if self.checkzones then
  
    local Ncheck=self.checkzones:Count()
    local Ninside=self.inzones:Count()
    
    -- Debug info.
    self:T(self.lid..string.format("Check if flight is in %d zones. Currently it is in %d zones.", self.checkzones:Count(), self.inzones:Count()))

    -- Firstly, check if group is still inside zone it was already in. If not, remove zones and trigger LeaveZone() event.
    local leftzones={}
    for inzonename, inzone in pairs(self.inzones:GetSet()) do
        
      -- Check if group is still inside the zone.
      local isstillinzone=self.group:IsPartlyOrCompletelyInZone(inzone)
      
      -- If not, trigger, LeaveZone event.
      if not isstillinzone then
        table.insert(leftzones, inzone)
      end      
    end
    
    -- Trigger leave zone event.
    for _,leftzone in pairs(leftzones) do
      self:LeaveZone(leftzone)
    end
    
    
    -- Now, run of all check zones and see if the group entered a  zone.
    local enterzones={}
    for checkzonename,_checkzone in pairs(self.checkzones:GetSet()) do
      local checkzone=_checkzone --Core.Zone#ZONE
      
      -- Is flight currtently in this check zone?
      local isincheckzone=self.group:IsPartlyOrCompletelyInZone(checkzone)

      if isincheckzone and not self.inzones:_Find(checkzonename) then
        table.insert(enterzones, checkzone)
      end
    end
    
    -- Trigger enter zone event.
    for _,enterzone in pairs(enterzones) do
      self:EnterZone(enterzone)
    end
    
    
  end

end

--- Check detected units.
-- @param #FLIGHTGROUP self
function FLIGHTGROUP:_CheckDetectedUnits()

  if self.group and not self:IsDead() then

    -- Get detected DCS units.
    local detectedtargets=self.group:GetDetectedTargets()

    local detected={}
    for DetectionObjectID, Detection in pairs(detectedtargets or {}) do
      local DetectedObject=Detection.object -- DCS#Object

      if DetectedObject and DetectedObject:isExist() and DetectedObject.id_<50000000 then
        local unit=UNIT:Find(DetectedObject)
        
        if unit and unit:IsAlive() then
        
          -- Name of detected unit
          local unitname=unit:GetName()

          -- Add unit to detected table of this run.        
          table.insert(detected, unit)
          
          -- Trigger detected unit event.
          self:DetectedUnit(unit)
          
          if self.detectedunits:FindUnit(unitname) then
            -- Unit is already in the detected unit set ==> Trigger "DetectedUnitKnown" event.
            self:DetectedUnitKnown(unit)
          else
            -- Unit is was not detected ==> Trigger "DetectedUnitNew" event.
            self:DetectedUnitNew(unit)
          end
          
        end
      end
    end

    -- Loop over units in detected set.
    local lost={}
    for _,_unit in pairs(self.detectedunits:GetSet()) do
      local unit=_unit --Wrapper.Unit#UNIT

      -- Loop over detected units
      local gotit=false
      for _,_du in pairs(detected) do
        local du=_du --Wrapper.Unit#UNIT
        if unit:GetName()==du:GetName() then
          gotit=true
        end
      end

      if not gotit then
        table.insert(lost, unit:GetName())
        self:DetectedUnitLost(unit)
      end

    end
    
    -- Remove lost units from detected set.
    self.detectedunits:RemoveUnitsByName(lost)

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

--- Get the number of shells a unit or group currently has. For a group the ammo count of all units is summed up.
-- @param #FLIGHTGROUP self
-- @param #FLIGHTGROUP.Element element The element.
-- @return #FLIGHTGROUP.Ammo Ammo data.
function FLIGHTGROUP:GetAmmoElement(element)
  return self:GetAmmoUnit(element.unit)
end

--- Get total amount of ammunition of the whole group.
-- @param #FLIGHTGROUP self
-- @return #FLIGHTGROUP.Ammo Ammo data.
function FLIGHTGROUP:GetAmmoTot()

  local units=self.group:GetUnits()
  
  local Ammo={} --#FLIGHTGROUP.Ammo
  Ammo.Total=0
  Ammo.Guns=0
  Ammo.Rockets=0
  Ammo.Bombs=0
  Ammo.Missiles=0
  Ammo.MissilesAA=0
  Ammo.MissilesAG=0
  Ammo.MissilesAS=0
  
  for _,_unit in pairs(units) do
    local unit=_unit --Wrapper.Unit#UNIT
    
    if unit and unit:IsAlive()~=nil then
      
      -- Get ammo of the unit.
      local ammo=self:GetAmmoUnit(unit)
      
      -- Add up total.
      Ammo.Total=Ammo.Total+ammo.Total
      Ammo.Guns=Ammo.Guns+ammo.Guns
      Ammo.Rockets=Ammo.Rockets+ammo.Rockets
      Ammo.Bombs=Ammo.Bombs+ammo.Bombs
      Ammo.Missiles=Ammo.Missiles+ammo.Missiles
      Ammo.MissilesAA=Ammo.MissilesAA+ammo.MissilesAA
      Ammo.MissilesAG=Ammo.MissilesAG+ammo.MissilesAG
      Ammo.MissilesAS=Ammo.MissilesAS+ammo.MissilesAS
    
    end
    
  end

  return Ammo
end

--- Get the number of shells a unit or group currently has. For a group the ammo count of all units is summed up.
-- @param #FLIGHTGROUP self
-- @param Wrapper.Unit#UNIT unit The unit object.
-- @param #boolean display Display ammo table as message to all. Default false.
-- @return #FLIGHTGROUP.Ammo Ammo data.
function FLIGHTGROUP:GetAmmoUnit(unit, display)

  -- Default is display false.
  if display==nil then
    display=false
  end

  -- Init counter.
  local nammo=0
  local nshells=0
  local nrockets=0
  local nmissiles=0
  local nmissilesAA=0
  local nmissilesAG=0
  local nmissilesAS=0
  local nbombs=0

  -- Output.
  local text=string.format("FLIGHTGROUP group %s - unit %s:\n", self.groupname, unit:GetName())

  -- Get ammo table.
  local ammotable=unit:GetAmmo()

  if ammotable then

    local weapons=#ammotable

    -- Loop over all weapons.
    for w=1,weapons do

      -- Number of current weapon.
      local Nammo=ammotable[w]["count"]

      -- Type name of current weapon.
      local Tammo=ammotable[w]["desc"]["typeName"]

      local _weaponString = UTILS.Split(Tammo,"%.")
      local _weaponName   = _weaponString[#_weaponString]

      -- Get the weapon category: shell=0, missile=1, rocket=2, bomb=3
      local Category=ammotable[w].desc.category

      -- Get missile category: Weapon.MissileCategory AAM=1, SAM=2, BM=3, ANTI_SHIP=4, CRUISE=5, OTHER=6
      local MissileCategory=nil
      if Category==Weapon.Category.MISSILE then
        MissileCategory=ammotable[w].desc.missileCategory
      end

      -- We are specifically looking for shells or rockets here.
      if Category==Weapon.Category.SHELL then

        -- Add up all shells.
        nshells=nshells+Nammo

        -- Debug info.
        text=text..string.format("- %d shells of type %s\n", Nammo, _weaponName)

      elseif Category==Weapon.Category.ROCKET then

        -- Add up all rockets.
        nrockets=nrockets+Nammo

        -- Debug info.
        text=text..string.format("- %d rockets of type %s\n", Nammo, _weaponName)

      elseif Category==Weapon.Category.BOMB then

        -- Add up all rockets.
        nbombs=nbombs+Nammo

        -- Debug info.
        text=text..string.format("- %d bombs of type %s\n", Nammo, _weaponName)

      elseif Category==Weapon.Category.MISSILE then

        -- Add up all cruise missiles (category 5)
        if MissileCategory==Weapon.MissileCategory.AAM then
          nmissiles=nmissiles+Nammo
          nmissilesAA=nmissilesAA+Nammo
        elseif MissileCategory==Weapon.MissileCategory.ANTI_SHIP then
          nmissiles=nmissiles+Nammo
          nmissilesAS=nmissilesAS+Nammo
        elseif MissileCategory==Weapon.MissileCategory.BM then
          nmissiles=nmissiles+Nammo
          nmissilesAG=nmissilesAG+Nammo
        elseif MissileCategory==Weapon.MissileCategory.OTHER then
          nmissiles=nmissiles+Nammo
          nmissilesAG=nmissilesAG+Nammo
        end

        -- Debug info.
        text=text..string.format("- %d %s missiles of type %s\n", Nammo, self:_MissileCategoryName(MissileCategory), _weaponName)

      else

        -- Debug info.
        text=text..string.format("- %d unknown ammo of type %s (category=%d, missile category=%s)\n", Nammo, Tammo, Category, tostring(MissileCategory))

      end

    end
  end

  -- Debug text and send message.
  if display then
    self:I(self.lid..text)
  else
    self:T3(self.lid..text)
  end
  MESSAGE:New(text, 10):ToAllIf(display)

  -- Total amount of ammunition.
  nammo=nshells+nrockets+nmissiles+nbombs

  local ammo={} --#FLIGHTGROUP.Ammo
  ammo.Total=nammo
  ammo.Guns=nshells
  ammo.Rockets=nrockets
  ammo.Bombs=nbombs
  ammo.Missiles=nmissiles
  ammo.MissilesAA=nmissilesAA
  ammo.MissilesAG=nmissilesAG
  ammo.MissilesAS=nmissilesAS

  return ammo
end


--- Returns a name of a missile category.
-- @param #FLIGHTGROUP self
-- @param #number categorynumber Number of missile category from weapon missile category enumerator. See https://wiki.hoggitworld.com/view/DCS_Class_Weapon
-- @return #string Missile category name.
function FLIGHTGROUP:_MissileCategoryName(categorynumber)
  local cat="unknown"
  if categorynumber==Weapon.MissileCategory.AAM then
    cat="air-to-air"
  elseif categorynumber==Weapon.MissileCategory.SAM then
    cat="surface-to-air"
  elseif categorynumber==Weapon.MissileCategory.BM then
    cat="ballistic"
  elseif categorynumber==Weapon.MissileCategory.ANTI_SHIP then
    cat="anti-ship"
  elseif categorynumber==Weapon.MissileCategory.CRUISE then
    cat="cruise"
  elseif categorynumber==Weapon.MissileCategory.OTHER then
    cat="other"
  end
  return cat
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

  airbase=airbase or coord:GetClosestAirbase(nil, self:GetCoalition())
  
  local spot=nil --Wrapper.Airbase#AIRBASE.ParkingSpot
  local dist=nil
  local distmin=math.huge 
  for _,_parking in pairs(airbase.parking) do
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

--- Get number of elements alive.
-- @param #FLIGHTGROUP self
-- @param #string status (Optional) Only count number, which are in a special status.
-- @return #number Number of elements.
function FLIGHTGROUP:GetNelements(status)

  local n=0
  for _,_element in pairs(self.elements) do
    local element=_element --#FLIGHTGROUP.Element
    if element.status~=FLIGHTGROUP.ElementStatus.DEAD then
      if element.unit and element.unit:IsAlive() then
        if status==nil or element.status==status then
          n=n+1
        end
      end
    end
  end

  
  return n
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
  
  local group=self.group

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

--- Set the default ROE for the group. This is the ROE state gets when the group is spawned or to which it defaults back after a mission.
-- @param #FLIGHTGROUP self
-- @param #number roe ROE of group. Default is `ENUMS.ROE.ReturnFire`.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:SetDefaultROE(roe)
  self.roeDefault=roe or ENUMS.ROE.ReturnFire
  return self
end

--- Set current ROE for the group.
-- @param #FLIGHTGROUP self
-- @param #string roe ROE of group. Default is the value defined by :SetDefaultROE().
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:SetOptionROE(roe)

  roe=roe or self.roeDefault
  
  if self:IsAlive() then
  
    self.group:OptionROE(roe)
    
    self.roe=roe
    
    self:T2(self.lid..string.format("Setting current ROE=%d (0=WeaponFree, 1=OpenFireWeaponFree, 2=OpenFire, 3=ReturnFire, 4=WeaponHold)", self.roe))
  else
    -- TODO WARNING
  end
  
  return self
end

--- Set the default ROT for the group. This is the ROT state gets when the group is spawned or to which it defaults back after a mission.
-- @param #FLIGHTGROUP self
-- @param #number roe ROE of group. Default is ENUMS.ROT.PassiveDefense.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:SetDefaultROT(roe)
  self.rotDefault=roe or ENUMS.ROT.PassiveDefense
  return self
end

--- Set ROT for the group.
-- @param #FLIGHTGROUP self
-- @param #string rot ROT of group. Default is the value defined by :SetDefaultROT().
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:SetOptionROT(rot)

  rot=rot or self.rotDefault
  
  if self:IsAlive() then
  
    self.group:OptionROT(rot)
    
    self.rot=rot
    
    self:T2(self.lid..string.format("Setting current ROT=%d (0=NoReaction, 1=Passive, 2=Evade, 3=ByPass, 4=AllowAbort)", self.rot))
  else
    -- TODO WARNING
  end
  
  return self
end

--- Set default TACAN parameters. AA TACANs are always on "Y" band.
-- @param #FLIGHTGROUP self
-- @param #number Channel TACAN channel.
-- @param #string Morse Morse code. Default "XXX".
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:SetDefaultTACAN(Channel, Morse)

  self.tacanChannelDefault=Channel
  self.tacanMorseDefault=Morse or "XXX"
  
  return self
end

--- Activate TACAN beacon.
-- @param #FLIGHTGROUP self
-- @param #number TACANChannel TACAN Channel.
-- @param #string TACANMorse TACAN morse code.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:SwitchTACANOn(TACANChannel, TACANMorse)

  if self:IsAlive() then
    
    local unit=self.group:GetUnit(1)
    
    if unit and unit:IsAlive() then
    
      local Type=5
      local System=4
      local UnitID=unit:GetID()
      local TACANMode="Y"
      local Frequency=UTILS.TACANToFrequency(TACANChannel, TACANMode) 
      
      unit:CommandActivateBeacon(Type, System, Frequency, UnitID, TACANChannel, TACANMode, true, TACANMorse, true)
      
      self.tacanBeacon=unit
      self.tacanChannel=TACANChannel
      self.tacanMorse=TACANMorse
      
      self.tacanOn=true
      
      self:I(self.lid..string.format("Switching TACAN to Channel %dY Morse %s", self.tacanChannel, tostring(self.tacanMorse)))
    
    end
    
  end

  return self
end

--- Deactivate TACAN beacon.
-- @param #FLIGHTGROUP self
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:SwitchTACANOff()

  if self.tacanBeacon and self.tacanBeacon:IsAlive() then
    self.tacanBeacon:CommandDeactivateBeacon()  
  end
  
  self:I(self.lid..string.format("Switching TACAN OFF"))
  
  self.tacanOn=false

end

--- Set default Radio frequency and modulation.
-- @param #FLIGHTGROUP self
-- @param #number Frequency Radio frequency in MHz. Default 251 MHz.
-- @param #number Modulation Radio modulation. Default `radio.Modulation.AM`.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:SetDefaultRadio(Frequency, Modulation)

  self.radioFreqDefault=Frequency or 251
  self.radioModuDefault=Modulation or radio.modulation.AM

  self.radioOn=false
  
  self.radioUse=true
  
  return self
end

--- Get current Radio frequency and modulation.
-- @param #FLIGHTGROUP self
-- @return #number Radio frequency in MHz or nil.
-- @return #number Radio modulation or nil.
function FLIGHTGROUP:GetRadio()
  return self.radioFreq, self.radioModu
end

--- Turn radio on.
-- @param #FLIGHTGROUP self
-- @param #number Frequency Radio frequency in MHz.
-- @param #number Modulation Radio modulation. Default `radio.Modulation.AM`.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:SwitchRadioOn(Frequency, Modulation)

  if self:IsAlive() and Frequency then

    Modulation=Modulation or radio.Modulation.AM
  
    self.group:SetOption(AI.Option.Air.id.SILENCE, false)
  
    self.group:CommandSetFrequency(Frequency, Modulation)
    
    self.radioFreq=Frequency
    self.radioModu=Modulation
    self.radioOn=true
    
    self:I(self.lid..string.format("Switching radio to frequency %.3f MHz %s", self.radioFreq, UTILS.GetModulationName(self.radioModu)))
    
  end
  
  return self
end

--- Turn radio off.
-- @param #FLIGHTGROUP self
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:SwitchRadioOff()

  if self:IsAlive() then

    self.group:SetOption(AI.Option.Air.id.SILENCE, true)
  
    self.radioFreq=nil
    self.radioModu=nil
    self.radioOn=false
    
    self:I(self.lid..string.format("Switching radio OFF"))
    
  end
  
  return self
end

--- Set default formation.
-- @param #FLIGHTGROUP self
-- @param #number Formation The formation the groups flies in.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:SetDefaultFormation(Formation)

  self.formationDefault=Formation
  
  return self
end

--- Switch to a specific formation.
-- @param #FLIGHTGROUP self
-- @param #number Formation New formation the group will fly in.
-- @return #FLIGHTGROUP self
function FLIGHTGROUP:SwitchFormation(Formation)

  if self:IsAlive() and Formation then
    
    self.group:SetOption(AI.Option.Air.id.FORMATION, Formation)

    self.formation=Formation
    
    self:I(self.lid..string.format("Switching formation to %d", self.formation))
  
  end
  
  return self
end


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
