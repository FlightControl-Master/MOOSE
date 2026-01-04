--- **Ops** - Airwing Warehouse.
--
-- **Main Features:**
--
--    * Manage squadrons.
--    * Launch A2A and A2G missions (AUFTRAG)
-- 
-- 
-- ===
--
-- ## Example Missions:
--
-- Demo missions can be found on [github](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/develop/Ops/Airwing).
--
-- ===
--
-- ### Author: **funkyfranky**
-- 
-- ===
-- @module Ops.Airwing
-- @image OPS_AirWing.png


--- AIRWING class.
-- @type AIRWING
-- @field #string ClassName Name of the class.
-- @field #number verbose Verbosity of output.
-- @field #string lid Class id string for output to DCS log file.
-- @field #table menu Table of menu items.
-- @field #table squadrons Table of squadrons.
-- @field #table missionqueue Mission queue table.
-- @field #table payloads Playloads for specific aircraft and mission types.
-- @field #number payloadcounter Running index of payloads.
-- @field Core.Set#SET_ZONE zonesetCAP Set of CAP zones.
-- @field Core.Set#SET_ZONE zonesetTANKER Set of TANKER zones.
-- @field Core.Set#SET_ZONE zonesetAWACS Set of AWACS zones.
-- @field Core.Set#SET_ZONE zonesetRECON Set of RECON zones. 
-- @field #number nflightsCAP Number of CAP flights constantly in the air.
-- @field #number nflightsAWACS Number of AWACS flights constantly in the air.
-- @field #number nflightsTANKERboom Number of TANKER flights with BOOM constantly in the air.
-- @field #number nflightsTANKERprobe Number of TANKER flights with PROBE constantly in the air.
-- @field #number nflightsRescueHelo Number of Rescue helo flights constantly in the air.
-- @field #number nflightsRecon Number of Recon flights constantly in the air.
-- @field #table pointsCAP Table of CAP points.
-- @field #table pointsTANKER Table of Tanker points.
-- @field #table pointsAWACS Table of AWACS points.
-- @field #table pointsRecon Table of RECON points.
-- @field #boolean markpoints Display markers on the F10 map.
-- @field Ops.Airboss#AIRBOSS airboss Airboss attached to this wing.
--
-- @field Ops.RescueHelo#RESCUEHELO rescuehelo The rescue helo.
-- @field Ops.RecoveryTanker#RECOVERYTANKER recoverytanker The recoverytanker.
-- 
-- @field #string takeoffType Take of type.
-- @field #boolean despawnAfterLanding Aircraft are despawned after landing.
-- @field #boolean despawnAfterHolding Aircraft are despawned after holding.
-- @field #boolean capOptionPatrolRaceTrack Use closer patrol race track or standard orbit auftrag.
-- @field #number capFormation If capOptionPatrolRaceTrack is true, set the formation, also.
-- @field #number capOptionVaryStartTime If set, vary mission start time for CAP missions generated random between capOptionVaryStartTime and capOptionVaryEndTime
-- @field #number capOptionVaryEndTime If set, vary mission start time for CAP missions generated random between capOptionVaryStartTime and capOptionVaryEndTime
-- 
-- @extends Ops.Legion#LEGION

--- *I fly because it releases my mind from the tyranny of petty things.* -- Antoine de Saint-Exupery
--
-- ===
--
-- # The AIRWING Concept
--
-- An AIRWING consists of multiple SQUADRONS. These squadrons "live" in a WAREHOUSE, i.e. a physical structure that is connected to an airbase (airdrome, FRAP or ship).
-- For an airwing to be operational, it needs airframes, weapons/fuel and an airbase.
--
-- # Create an Airwing
--
-- ## Constructing the Airwing
--
--     airwing=AIRWING:New("Warehouse Batumi", "8th Fighter Wing")
--     airwing:Start()
--
-- The first parameter specified the warehouse, i.e. the static building housing the airwing (or the name of the aircraft carrier). The second parameter is optional
-- and sets an alias.
--
-- ## Adding Squadrons
--
-- At this point the airwing does not have any assets (aircraft). In order to add these, one needs to first define SQUADRONS.
--
--     VFA151=SQUADRON:New("F-14 Group", 8, "VFA-151 (Vigilantes)")
--     VFA151:AddMissionCapability({AUFTRAG.Type.GCICAP, AUFTRAG.Type.INTERCEPT})
--
--     airwing:AddSquadron(VFA151)
--
-- This adds eight Tomcat groups beloning to VFA-151 to the airwing. This squadron has the ability to perform combat air patrols and intercepts.
--
-- ## Adding Payloads
--
-- Adding pure airframes is not enough. The aircraft also need weapons (and fuel) for certain missions. These must be given to the airwing from template groups
-- defined in the Mission Editor.
--
--     -- F-14 payloads for CAP and INTERCEPT. Phoenix are first, sparrows are second choice.
--     airwing:NewPayload(GROUP:FindByName("F-14 Payload AIM-54C"), 2, {AUFTRAG.Type.INTERCEPT, AUFTRAG.Type.GCICAP}, 80)
--     airwing:NewPayload(GROUP:FindByName("F-14 Payload AIM-7M"), 20, {AUFTRAG.Type.INTERCEPT, AUFTRAG.Type.GCICAP})
--
-- This will add two AIM-54C and 20 AIM-7M payloads.
--
-- If the airwing gets an intercept or patrol mission assigned, it will first use the AIM-54s. Once these are consumed, the AIM-7s are attached to the aircraft.
--
-- When an airwing does not have a payload for a certain mission type, the mission cannot be carried out.
--
-- You can set the number of payloads to "unlimited" by setting its quantity to -1.
--
-- # Adding Missions
--
-- Various mission types can be added easily via the AUFTRAG class.
--
-- Once you created an AUFTRAG you can add it to the AIRWING with the :AddMission(mission) function.
--
-- This mission will be put into the AIRWING queue. Once the mission start time is reached and all resources (airframes and payloads) are available, the mission is started.
-- If the mission stop time is over (and the mission is not finished), it will be cancelled and removed from the queue. This applies also to mission that were not even
-- started.
--
--
-- @field #AIRWING
AIRWING = {
  ClassName      = "AIRWING",
  verbose        =     0,
  lid            =   nil,
  menu           =   nil,
  payloads       =    {},
  payloadcounter =     0,
  pointsCAP      =    {},
  pointsTANKER   =    {},
  pointsAWACS    =    {},
  pointsRecon    =    {},
  markpoints     =   false,
  capOptionPatrolRaceTrack = false,
  capFormation   =    nil,
  capOptionVaryStartTime =    nil,
  capOptionVaryEndTime =    nil,
}

--- Payload data.
-- @type AIRWING.Payload
-- @field #number uid Unique payload ID.
-- @field #string unitname Name of the unit this pylon was extracted from.
-- @field #string aircrafttype Type of aircraft, which can use this payload.
-- @field #table capabilities Mission types and performances for which this payload can be used.
-- @field #table pylons Pylon data extracted for the unit template.
-- @field #number navail Number of available payloads of this type.
-- @field #boolean unlimited If true, this payload is unlimited and does not get consumed.

--- Patrol data.
-- @type AIRWING.PatrolData
-- @field #string type Type name.
-- @field Core.Point#COORDINATE coord Patrol coordinate.
-- @field #number altitude Altitude in feet.
-- @field #number heading Heading in degrees.
-- @field #number leg Leg length in NM.
-- @field #number speed Speed in knots.
-- @field #number refuelsystem Refueling system type: `0=Unit.RefuelingSystem.BOOM_AND_RECEPTACLE`, `1=Unit.RefuelingSystem.PROBE_AND_DROGUE`.
-- @field #number noccupied Number of flights on this patrol point.
-- @field Wrapper.Marker#MARKER marker F10 marker.
-- @field #boolean IsZonePoint flag for using a (moving) zone as point for patrol etc.
-- @field Core.Zone#ZONE_BASE patrolzone in case Patrol coordinate was handed as zone, store here.

--- Patrol zone.
-- @type AIRWING.PatrolZone
-- @field Core.Zone#ZONE zone Zone.
-- @field #number altitude Altitude in feet.
-- @field #number heading Heading in degrees.
-- @field #number leg Leg length in NM.
-- @field #number speed Speed in knots.
-- @field Ops.Auftrag#AUFTRAG mission Mission assigned.
-- @field Wrapper.Marker#MARKER marker F10 marker.

--- AWACS zone.
-- @type AIRWING.AwacsZone
-- @field Core.Zone#ZONE zone Zone.
-- @field #number altitude Altitude in feet.
-- @field #number heading Heading in degrees.
-- @field #number leg Leg length in NM.
-- @field #number speed Speed in knots.
-- @field Ops.Auftrag#AUFTRAG mission Mission assigned.
-- @field Wrapper.Marker#MARKER marker F10 marker.

--- Tanker zone.
-- @type AIRWING.TankerZone
-- @field #number refuelsystem Refueling system type: `0=Unit.RefuelingSystem.BOOM_AND_RECEPTACLE`, `1=Unit.RefuelingSystem.PROBE_AND_DROGUE`.
-- @extends #AIRWING.PatrolZone

--- AIRWING class version.
-- @field #string version
AIRWING.version="0.9.7"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ToDo list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Check that airbase has enough parking spots if a request is BIG.
-- DONE: Allow (moving) zones as base for patrol points.
-- DONE: Spawn in air ==> Needs WAREHOUSE update.
-- DONE: Spawn hot.
-- DONE: Make special request to transfer squadrons to anther airwing (or warehouse).
-- DONE: Add squadrons to warehouse.
-- DONE: Build mission queue.
-- DONE: Find way to start missions.
-- DONE: Check if missions are done/cancelled.
-- DONE: Payloads as resources.
-- DONE: Define CAP zones.
-- DONE: Define TANKER zones for refuelling.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new AIRWING class object for a specific aircraft carrier unit.
-- @param #AIRWING self
-- @param #string warehousename Name of the warehouse static or unit object representing the warehouse.
-- @param #string airwingname Name of the air wing, e.g. "AIRWING-8".
-- @return #AIRWING self
function AIRWING:New(warehousename, airwingname)

  -- Inherit everything from LEGION class.
  local self=BASE:Inherit(self, LEGION:New(warehousename, airwingname)) -- #AIRWING

  -- Nil check.
  if not self then
    BASE:E(string.format("ERROR: Could not find warehouse %s!", warehousename))
    return nil
  end

  -- Set some string id for output to DCS.log file.
  self.lid=string.format("AIRWING %s | ", self.alias)
  
  -- Defaults:
  self.nflightsCAP=0
  self.nflightsAWACS=0
  self.nflightsRecon=0
  self.nflightsTANKERboom=0
  self.nflightsTANKERprobe=0
  self.nflightsRecoveryTanker=0
  self.nflightsRescueHelo=0
  self.markpoints=false  

  -- Add FSM transitions.
  --                 From State  -->   Event         -->      To State
  self:AddTransition("*",             "FlightOnMission",       "*")           -- A FLIGHTGROUP was send on a Mission (AUFTRAG).

  ------------------------
  --- Pseudo Functions ---
  ------------------------

  --- Triggers the FSM event "Start". Starts the AIRWING. Initializes parameters and starts event handlers.
  -- @function [parent=#AIRWING] Start
  -- @param #AIRWING self

  --- Triggers the FSM event "Start" after a delay. Starts the AIRWING. Initializes parameters and starts event handlers.
  -- @function [parent=#AIRWING] __Start
  -- @param #AIRWING self
  -- @param #number delay Delay in seconds.


  --- Triggers the FSM event "Stop". Stops the AIRWING and all its event handlers.
  -- @param #AIRWING self

  --- Triggers the FSM event "Stop" after a delay. Stops the AIRWING and all its event handlers.
  -- @function [parent=#AIRWING] __Stop
  -- @param #AIRWING self
  -- @param #number delay Delay in seconds.


  --- Triggers the FSM event "FlightOnMission".
  -- @function [parent=#AIRWING] FlightOnMission
  -- @param #AIRWING self
  -- @param Ops.FlightGroup#FLIGHTGROUP FlightGroup The FLIGHTGROUP on mission.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.

  --- Triggers the FSM event "FlightOnMission" after a delay.
  -- @function [parent=#AIRWING] __FlightOnMission
  -- @param #AIRWING self
  -- @param #number delay Delay in seconds.
  -- @param Ops.FlightGroup#FLIGHTGROUP FlightGroup The FLIGHTGROUP on mission.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.

  --- On after "FlightOnMission" event.
  -- @function [parent=#AIRWING] OnAfterFlightOnMission
  -- @param #AIRWING self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.FlightGroup#FLIGHTGROUP FlightGroup  The FLIGHTGROUP on mission.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Add a squadron to the air wing.
-- @param #AIRWING self
-- @param Ops.Squadron#SQUADRON Squadron The squadron object.
-- @return #AIRWING self
function AIRWING:AddSquadron(Squadron)

  -- Add squadron to airwing.
  table.insert(self.cohorts, Squadron)

  -- Add assets to squadron.
  self:AddAssetToSquadron(Squadron, Squadron.Ngroups)

  -- Tanker and AWACS get unlimited payloads.
  if Squadron.attribute==GROUP.Attribute.AIR_AWACS then
    self:NewPayload(Squadron.templategroup, -1, AUFTRAG.Type.AWACS)
  elseif Squadron.attribute==GROUP.Attribute.AIR_TANKER then
    self:NewPayload(Squadron.templategroup, -1, AUFTRAG.Type.TANKER)
  end
  
  -- Relocate mission.
  self:NewPayload(Squadron.templategroup, -1, AUFTRAG.Type.RELOCATECOHORT, 0)

  -- Set airwing to squadron.
  Squadron:SetAirwing(self)

  -- Start squadron.
  if Squadron:IsStopped() then
    Squadron:Start()
  end
  
  -- if storage is limited, add the amount of aircraft needed
  local airbasename = self:GetAirbaseName()
  
  if airbasename then
    local group = Squadron.templategroup
      if group then
      local Nunits = 1
      local units
      if group then units = group:GetUnits() end
      if units then Nunits = #units end
      local typename = Squadron.aircrafttype or "none"
      local NAssets = Squadron.Ngroups * Nunits
      local storage = STORAGE:New(airbasename)
      
      self:T(self.lid.."Adding "..typename.." #"..NAssets)
      if storage and storage.warehouse and storage:IsLimitedAircraft() and typename ~= "none" then
        local NInStore = storage:GetItemAmount(typename) or 0
        if NAssets > NInStore then
          storage:AddItem(typename,NAssets)
        end
      end
      
      local unit = group:GetUnit(1)
      -- if storage is limited, add the amount of liquids needed
      if unit and storage and storage.warehouse and storage:IsLimitedLiquids() and typename ~= "none" then
        local fuel = unit:GetFuelMassMax()
        local neededfuel = (fuel*NAssets) -- kgs of fuel
        local NInStore = storage:GetLiquidAmount(STORAGE.Liquid.JETFUEL) or 0
        self:T(string.format(self.lid.."Fuel Needed: %dt | Fuel in store: %dt",neededfuel/1000,NInStore/1000))
        if neededfuel > NInStore then
          storage:AddLiquid(STORAGE.Liquid.JETFUEL,neededfuel)
        end
      end
    end
  end

  return self
end

--- Add a **new** payload to the airwing resources.
-- @param #AIRWING self
-- @param Wrapper.Unit#UNIT Unit The unit, the payload is extracted from. Can also be given as *#string* name of the unit.
-- @param #number Npayloads Number of payloads to add to the airwing resources. Default 99 (which should be enough for most scenarios). Set to -1 for unlimited.
-- @param #table MissionTypes Mission types this payload can be used for.
-- @param #number Performance A number between 0 (worst) and 100 (best) to describe the performance of the loadout for the given mission types. Default is 50.
-- @return #AIRWING.Payload The payload table or nil if the unit does not exist.
function AIRWING:NewPayload(Unit, Npayloads, MissionTypes,  Performance)

  -- Default performance.
  Performance=Performance or 50

  if type(Unit)=="string" then
    local name=Unit
    Unit=UNIT:FindByName(name)
    if not Unit then
      Unit=GROUP:FindByName(name)
    end
  end

  if Unit then

    -- If a GROUP object was given, get the first unit.
    if Unit:IsInstanceOf("GROUP") then
      Unit=Unit:GetUnit(1)
    end

    -- Ensure Missiontypes is a table.
    if MissionTypes and type(MissionTypes)~="table" then
      MissionTypes={MissionTypes}
    end

    -- Create payload.
    local payload={} --#AIRWING.Payload
    payload.uid=self.payloadcounter
    payload.unitname=Unit:GetName()
    payload.aircrafttype=Unit:GetTypeName()
    payload.pylons=Unit:GetTemplatePayload()
    
    -- Set the number of available payloads.
    self:SetPayloadAmount(payload, Npayloads)

    -- Payload capabilities.
    payload.capabilities={}
    for _,missiontype in pairs(MissionTypes) do
      local capability={} --Ops.Auftrag#AUFTRAG.Capability
      capability.MissionType=missiontype
      capability.Performance=Performance
      table.insert(payload.capabilities, capability)
    end

    -- Add ORBIT for all.
    if not AUFTRAG.CheckMissionType(AUFTRAG.Type.ORBIT, MissionTypes) then
      local capability={}  --Ops.Auftrag#AUFTRAG.Capability
      capability.MissionType=AUFTRAG.Type.ORBIT
      capability.Performance=50
      table.insert(payload.capabilities, capability)
    end
    
    -- Add RELOCATION for all.
    if not AUFTRAG.CheckMissionType(AUFTRAG.Type.RELOCATECOHORT, MissionTypes) then
      local capability={}  --Ops.Auftrag#AUFTRAG.Capability
      capability.MissionType=AUFTRAG.Type.RELOCATECOHORT
      capability.Performance=50
      table.insert(payload.capabilities, capability)
    end    

    -- Info
    self:T(self.lid..string.format("Adding new payload from unit %s for aircraft type %s: ID=%d, N=%d (unlimited=%s), performance=%d, missions: %s",
    payload.unitname, payload.aircrafttype, payload.uid, payload.navail, tostring(payload.unlimited), Performance, table.concat(MissionTypes, ", ")))

    -- Add payload
    table.insert(self.payloads, payload)

    -- Increase counter
    self.payloadcounter=self.payloadcounter+1

    return payload

  end

  self:E(self.lid.."ERROR: No UNIT found to create PAYLOAD!")
  return nil
end

--- Set the number of payload available.
-- @param #AIRWING self
-- @param #AIRWING.Payload Payload The payload table created by the `:NewPayload` function.
-- @param #number Navailable Number of payloads available to the airwing resources. Default 99 (which should be enough for most scenarios). Set to -1 for unlimited.
-- @return #AIRWING self
function AIRWING:SetPayloadAmount(Payload, Navailable)

  Navailable=Navailable or 99

  if Payload then

    Payload.unlimited=Navailable<0
    if Payload.unlimited then
      Payload.navail=1
    else
      Payload.navail=Navailable
    end
    
  end

  return self
end

--- Increase or decrease the amount of available payloads. Unlimited playloads first need to be set to a limited number with the `SetPayloadAmount` function.
-- @param #AIRWING self
-- @param #AIRWING.Payload Payload The payload table created by the `:NewPayload` function.
-- @param #number N Number of payloads to be added. Use negative number to decrease amount. Default 1.
-- @return #AIRWING self
function AIRWING:IncreasePayloadAmount(Payload, N)

  N=N or 1
  
  if Payload and Payload.navail>=0 then
  
    -- Increase/decrease amount.
    Payload.navail=Payload.navail+N
  
    -- Ensure playload does not drop below 0.
    Payload.navail=math.max(Payload.navail, 0) 
  
  end
  
  return self
end

--- Get amount of payloads available for a given playload.
-- @param #AIRWING self
-- @param #AIRWING.Payload Payload The payload table created by the `:NewPayload` function.
-- @return #number Number of payloads available. Unlimited payloads will return -1.
function AIRWING:GetPayloadAmount(Payload)
  return Payload.navail
end

--- Get capabilities of a given playload.
-- @param #AIRWING self
-- @param #AIRWING.Payload Payload The payload data table.
-- @return #table Capabilities.
function AIRWING:GetPayloadCapabilities(Payload)
  return Payload.capabilities
end

--- Add a mission capability to an existing payload.
-- @param #AIRWING self
-- @param #AIRWING.Payload Payload The payload table to which the capability should be added.
-- @param #table MissionTypes Mission types to be added.
-- @param #number Performance A number between 0 (worst) and 100 (best) to describe the performance of the loadout for the given mission types. Default is 50.
-- @return #AIRWING self
function AIRWING:AddPayloadCapability(Payload, MissionTypes, Performance)

  -- Ensure Missiontypes is a table.
  if MissionTypes and type(MissionTypes)~="table" then
    MissionTypes={MissionTypes}
  end

  Payload.capabilities=Payload.capabilities or {}

  for _,missiontype in pairs(MissionTypes) do

    local capability={} --Ops.Auftrag#AUFTRAG.Capability
    capability.MissionType=missiontype
    capability.Performance=Performance

    --TODO: check that capability does not already exist!

    table.insert(Payload.capabilities, capability)
  end

  return self
end

--- Fetch a payload from the airwing resources for a given unit and mission type.
-- The payload with the highest priority is preferred.
-- @param #AIRWING self
-- @param #string UnitType The type of the unit.
-- @param #string MissionType The mission type.
-- @param #table Payloads Specific payloads only to be considered.
-- @return #AIRWING.Payload Payload table or *nil*.
function AIRWING:FetchPayloadFromStock(UnitType, MissionType, Payloads)

  -- Quick check if we have any payloads.
  if not self.payloads or #self.payloads==0 then
    self:T(self.lid.."WARNING: No payloads in stock!")
    return nil
  end

  -- Debug.
  if self.verbose>=4 then
    self:I(self.lid..string.format("Looking for payload for unit type=%s and mission type=%s", UnitType, MissionType))
    for i,_payload in pairs(self.payloads) do
      local payload=_payload --#AIRWING.Payload
      local performance=self:GetPayloadPeformance(payload, MissionType)
      self:I(self.lid..string.format("[%d] Payload type=%s navail=%d unlimited=%s", i, payload.aircrafttype, payload.navail, tostring(payload.unlimited)))
    end
  end

  --- Sort payload wrt the following criteria:
  -- 1) Highest performance is the main selection criterion.
  -- 2) If payloads have the same performance, unlimited payloads are preferred over limited ones.
  -- 3) If payloads have the same performance _and_ are limited, the more abundant one is preferred.
  local function sortpayloads(a,b)
    local pA=a --#AIRWING.Payload
    local pB=b --#AIRWING.Payload
    if a and b then  -- I had the case that a or b were nil even though the self.payloads table was looking okay. Very strange! Seems to be solved by pre-selecting valid payloads.
      local performanceA=self:GetPayloadPeformance(a, MissionType)
      local performanceB=self:GetPayloadPeformance(b, MissionType)
      return (performanceA>performanceB) or (performanceA==performanceB and a.unlimited==true and b.unlimited~=true) or (performanceA==performanceB and a.unlimited==true and b.unlimited==true and a.navail>b.navail)
    elseif not a then
      self:I(self.lid..string.format("FF ERROR in sortpayloads: a is nil"))
      return false
    elseif not b then
      self:I(self.lid..string.format("FF ERROR in sortpayloads: b is nil"))
      return true
    else
      self:I(self.lid..string.format("FF ERROR in sortpayloads: a and b are nil"))
      return false
    end
  end

  local function _checkPayloads(payload)
    if Payloads then
      for _,Payload in pairs(Payloads) do
        if Payload.uid==payload.uid then
          return true
        end
      end
    else
      -- Payload was not specified.
      return nil
    end
    return false
  end

  -- Pre-selection: filter out only those payloads that are valid for the airframe and mission type and are available.
  local payloads={}
  for _,_payload in pairs(self.payloads) do
    local payload=_payload --#AIRWING.Payload

    local specialpayload=_checkPayloads(payload)
    local compatible=AUFTRAG.CheckMissionCapability(MissionType, payload.capabilities)

    local goforit = specialpayload or (specialpayload==nil and compatible)

    if payload.aircrafttype==UnitType and payload.navail>0 and goforit then
      table.insert(payloads, payload)
    end
  end

  -- Debug.
  if self.verbose>=4 then
    self:I(self.lid..string.format("Sorted payloads for mission type %s and aircraft type=%s:", MissionType, UnitType))
    for _,_payload in ipairs(self.payloads) do
      local payload=_payload --#AIRWING.Payload
      if payload.aircrafttype==UnitType and AUFTRAG.CheckMissionCapability(MissionType, payload.capabilities) then
        local performace=self:GetPayloadPeformance(payload, MissionType)
        self:I(self.lid..string.format("- %s payload for %s: avail=%d performace=%d", MissionType, payload.aircrafttype, payload.navail, performace))
      end
    end
  end

  -- Cases:
  if #payloads==0 then
    -- No payload available.
    self:T(self.lid..string.format("WARNING: Could not find a payload for airframe %s mission type %s!", UnitType, MissionType))
    return nil
  elseif #payloads==1 then
    -- Only one payload anyway.
    local payload=payloads[1] --#AIRWING.Payload
    if not payload.unlimited then
      payload.navail=payload.navail-1
    end
    return payload
  else
    -- Sort payloads.
    table.sort(payloads, sortpayloads)
    local payload=payloads[1] --#AIRWING.Payload
    if not payload.unlimited then
      payload.navail=payload.navail-1
    end
    return payload
  end

end

--- Return payload from asset back to stock.
-- @param #AIRWING self
-- @param Functional.Warehouse#WAREHOUSE.Assetitem asset The squadron asset.
function AIRWING:ReturnPayloadFromAsset(asset)

  local payload=asset.payload

  if payload then

    -- Increase count if not unlimited.
    if not payload.unlimited then
      payload.navail=payload.navail+1
    end

    -- Remove asset payload.
    asset.payload=nil

  else
    self:E(self.lid.."ERROR: asset had no payload attached!")
  end

end


--- Add asset group(s) to squadron.
-- @param #AIRWING self
-- @param Ops.Squadron#SQUADRON Squadron The squadron object.
-- @param #number Nassets Number of asset groups to add.
-- @return #AIRWING self
function AIRWING:AddAssetToSquadron(Squadron, Nassets)

  if Squadron then

    -- Get the template group of the squadron.
    local Group=GROUP:FindByName(Squadron.templatename)

    if Group then

      -- Debug text.
      local text=string.format("Adding asset %s to squadron %s", Group:GetName(), Squadron.name)
      self:T(self.lid..text)

      -- Add assets to airwing warehouse.
      self:AddAsset(Group, Nassets, nil, nil, nil, nil, Squadron.skill, Squadron.livery, Squadron.name)

    else
      self:E(self.lid.."ERROR: Group does not exist!")
    end

  else
    self:E(self.lid.."ERROR: Squadron does not exit!")
  end

  return self
end

--- Get squadron by name.
-- @param #AIRWING self
-- @param #string SquadronName Name of the squadron, e.g. "VFA-37".
-- @return Ops.Squadron#SQUADRON The squadron object.
function AIRWING:GetSquadron(SquadronName)
  local squad=self:_GetCohort(SquadronName)
  return squad
end

--- Get squadron of an asset.
-- @param #AIRWING self
-- @param Functional.Warehouse#WAREHOUSE.Assetitem Asset The squadron asset.
-- @return Ops.Squadron#SQUADRON The squadron object.
function AIRWING:GetSquadronOfAsset(Asset)
  return self:GetSquadron(Asset.squadname)
end

--- Remove asset from squadron.
-- @param #AIRWING self
-- @param Functional.Warehouse#WAREHOUSE.Assetitem Asset The squad asset.
function AIRWING:RemoveAssetFromSquadron(Asset)
  local squad=self:GetSquadronOfAsset(Asset)
  if squad then
    squad:DelAsset(Asset)
  end
end

--- Set number of CAP flights constantly carried out.
-- @param #AIRWING self
-- @param #number n Number of flights. Default 1.
-- @return #AIRWING self
function AIRWING:SetNumberCAP(n)
  self.nflightsCAP=n or 1
  return self
end

--- Set CAP flight formation.
-- @param #AIRWING self
-- @param #number Formation Formation to take, e.g. ENUMS.Formation.FixedWing.Trail.Close, also see [Hoggit Wiki](https://wiki.hoggitworld.com/view/DCS_option_formation).
-- @return #AIRWING self
function AIRWING:SetCAPFormation(Formation)
  self.capFormation = Formation
  return self
end

--- Set CAP close race track.We'll utilize the AUFTRAG PatrolRaceTrack instead of a standard race track orbit task.
-- @param #AIRWING self
-- @param #boolean OnOff If true, switch this on, else switch off. Off by default.
-- @return #AIRWING self
function AIRWING:SetCapCloseRaceTrack(OnOff)
  self.capOptionPatrolRaceTrack = OnOff
  return self
end

--- Set CAP mission start to vary randomly between Start end End seconds.
-- @param #AIRWING self
-- @param #number Start
-- @param #number End 
-- @return #AIRWING self
function AIRWING:SetCapStartTimeVariation(Start, End)
  self.capOptionVaryStartTime = Start or 5
  self.capOptionVaryEndTime = End or 60
  return self
end

--- Set number of TANKER flights with Boom constantly in the air.
-- @param #AIRWING self
-- @param #number Nboom Number of flights. Default 1.
-- @return #AIRWING self
function AIRWING:SetNumberTankerBoom(Nboom)
  self.nflightsTANKERboom=Nboom or 1
  return self
end

--- Set markers on the map for Patrol Points.
-- @param #AIRWING self
-- @param #boolean onoff Set to true to switch markers on.
-- @return #AIRWING self
function AIRWING:ShowPatrolPointMarkers(onoff)
  if onoff then
    self.markpoints = true
  else
    self.markpoints = false
  end
  return self
end

--- Set number of TANKER flights with Probe constantly in the air.
-- @param #AIRWING self
-- @param #number Nprobe Number of flights. Default 1.
-- @return #AIRWING self
function AIRWING:SetNumberTankerProbe(Nprobe)
  self.nflightsTANKERprobe=Nprobe or 1
  return self
end

--- Set number of AWACS flights constantly in the air.
-- @param #AIRWING self
-- @param #number n Number of flights. Default 1.
-- @return #AIRWING self
function AIRWING:SetNumberAWACS(n)
  self.nflightsAWACS=n or 1
  return self
end

--- Set number of RECON flights constantly in the air.
-- @param #AIRWING self
-- @param #number n Number of flights. Default 1.
-- @return #AIRWING self
function AIRWING:SetNumberRecon(n)
  self.nflightsRecon=n or 1
  return self
end

--- Set number of Rescue helo flights constantly in the air.
-- @param #AIRWING self
-- @param #number n Number of flights. Default 1.
-- @return #AIRWING self
function AIRWING:SetNumberRescuehelo(n)
  self.nflightsRescueHelo=n or 1
  return self
end

---
-- @param #AIRWING self
-- @param #AIRWING.PatrolData point Patrol point table.
-- @return #string Marker text.
function AIRWING:_PatrolPointMarkerText(point)

  local text=string.format("%s Occupied=%d, \nheading=%03d, leg=%d NM, alt=%d ft, speed=%d kts",
  point.type, point.noccupied, point.heading, point.leg, point.altitude, point.speed)

  return text
end

--- Update marker of the patrol point.
-- @param #AIRWING self
-- @param #AIRWING.PatrolData point Patrol point table.
function AIRWING:UpdatePatrolPointMarker(point)

  if self and self.markpoints then -- sometimes there's a direct call from #OPSGROUP
    local text=string.format("%s Occupied=%d\nheading=%03d, leg=%d NM, alt=%d ft, speed=%d kts",
    point.type, point.noccupied, point.heading, point.leg, point.altitude, point.speed)
 
    if point.IsZonePoint and point.IsZonePoint == true and point.patrolzone then
      -- update position
      local Coordinate = point.patrolzone:GetCoordinate()
      point.marker:UpdateCoordinate(Coordinate)
      point.marker:UpdateText(text, 1.5)
    else
      point.marker:UpdateText(text, 1)
    end
  end
end


--- Create a new generic patrol point.
-- @param #AIRWING self
-- @param #string Type Patrol point type, e.g. "CAP" or "AWACS". Default "Unknown".
-- @param Core.Point#COORDINATE Coordinate Coordinate of the patrol point. Default 10-15 NM away from the location of the airwing. Can be handed as a Core.Zone#ZONE object (e.g. in case you want  the point to align with a moving zone).
-- @param #number Altitude Orbit altitude in feet. Default random between Angels 10 and 20.
-- @param #number Heading Heading in degrees. Default random (0, 360] degrees.
-- @param #number LegLength Length of race-track orbit in NM. Default 15 NM.
-- @param #number Speed Orbit speed in knots. Default 350 knots.
-- @param #number RefuelSystem Refueling system: 0=Boom, 1=Probe. Default nil=any.
-- @return #AIRWING.PatrolData Patrol point table.
function AIRWING:NewPatrolPoint(Type, Coordinate, Altitude, Speed, Heading, LegLength, RefuelSystem)

  local patrolpoint={}  --#AIRWING.PatrolData
  patrolpoint.type=Type or "Unknown"
  patrolpoint.coord=Coordinate or self:GetCoordinate():Translate(UTILS.NMToMeters(math.random(10, 15)), math.random(360))
  if Coordinate and Coordinate:IsInstanceOf("ZONE_BASE") then
    patrolpoint.IsZonePoint = true
    patrolpoint.patrolzone = Coordinate
    patrolpoint.coord = patrolpoint.patrolzone:GetCoordinate()
  else
    patrolpoint.IsZonePoint = false
  end
  patrolpoint.heading=Heading or math.random(360)
  patrolpoint.leg=LegLength or 15
  patrolpoint.altitude=Altitude or math.random(10,20)*1000
  patrolpoint.speed=Speed or 350
  patrolpoint.noccupied=0
  patrolpoint.refuelsystem=RefuelSystem

  if self.markpoints then
    patrolpoint.marker=MARKER:New(Coordinate, "New Patrol Point"):ToAll()
    self:UpdatePatrolPointMarker(patrolpoint)
  end

  return patrolpoint
end

--- Add a patrol Point for CAP missions.
-- @param #AIRWING self
-- @param Core.Point#COORDINATE Coordinate Coordinate of the patrol point. Can be handed as a Core.Zone#ZONE object (e.g. in case you want  the point to align with a moving zone).
-- @param #number Altitude Orbit altitude in feet.
-- @param #number Speed Orbit speed in knots.
-- @param #number Heading Heading in degrees.
-- @param #number LegLength Length of race-track orbit in NM.
-- @return #AIRWING self
function AIRWING:AddPatrolPointCAP(Coordinate, Altitude, Speed, Heading, LegLength)

  local patrolpoint=self:NewPatrolPoint("CAP", Coordinate, Altitude, Speed, Heading, LegLength)

  table.insert(self.pointsCAP, patrolpoint)

  return self
end

--- Add a patrol Point for RECON missions.
-- @param #AIRWING self
-- @param Core.Point#COORDINATE Coordinate Coordinate of the patrol point. Can be handed as a Core.Zone#ZONE object (e.g. in case you want  the point to align with a moving zone).
-- @param #number Altitude Orbit altitude in feet.
-- @param #number Speed Orbit speed in knots.
-- @param #number Heading Heading in degrees.
-- @param #number LegLength Length of race-track orbit in NM.
-- @return #AIRWING self
function AIRWING:AddPatrolPointRecon(Coordinate, Altitude, Speed, Heading, LegLength)

  local patrolpoint=self:NewPatrolPoint("RECON", Coordinate, Altitude, Speed, Heading, LegLength)

  table.insert(self.pointsRecon, patrolpoint)

  return self
end

--- Add a patrol Point for TANKER missions.
-- @param #AIRWING self
-- @param Core.Point#COORDINATE Coordinate Coordinate of the patrol point. Can be handed as a Core.Zone#ZONE object (e.g. in case you want  the point to align with a moving zone).
-- @param #number Altitude Orbit altitude in feet.
-- @param #number Speed Orbit speed in knots.
-- @param #number Heading Heading in degrees.
-- @param #number LegLength Length of race-track orbit in NM.
-- @param #number RefuelSystem Set refueling system of tanker: 0=boom, 1=probe. Default any (=nil).
-- @return #AIRWING self
function AIRWING:AddPatrolPointTANKER(Coordinate, Altitude, Speed, Heading, LegLength, RefuelSystem)

  local patrolpoint=self:NewPatrolPoint("Tanker", Coordinate, Altitude, Speed, Heading, LegLength, RefuelSystem)

  table.insert(self.pointsTANKER, patrolpoint)

  return self
end

--- Add a patrol Point for AWACS missions.
-- @param #AIRWING self
-- @param Core.Point#COORDINATE Coordinate Coordinate of the patrol point. Can be handed as a Core.Zone#ZONE object (e.g. in case you want  the point to align with a moving zone).
-- @param #number Altitude Orbit altitude in feet.
-- @param #number Speed Orbit speed in knots.
-- @param #number Heading Heading in degrees.
-- @param #number LegLength Length of race-track orbit in NM.
-- @return #AIRWING self
function AIRWING:AddPatrolPointAWACS(Coordinate, Altitude, Speed, Heading, LegLength)

  local patrolpoint=self:NewPatrolPoint("AWACS", Coordinate, Altitude, Speed, Heading, LegLength)

  table.insert(self.pointsAWACS, patrolpoint)

  return self
end

--- Set airboss of this wing. He/she will take care that no missions are launched if the carrier is recovering.
-- @param #AIRWING self
-- @param Ops.Airboss#AIRBOSS airboss The AIRBOSS object.
-- @return #AIRWING self
function AIRWING:SetAirboss(airboss)
  self.airboss=airboss
  return self
end

--- Set takeoff type. All assets of this airwing will be spawned with this takeoff type.
-- Spawning on runways is not supported.
-- @param #AIRWING self
-- @param #string TakeoffType Take off type: "Cold" (default) or "Hot" with engines on or "Air" for spawning in air.
-- @return #AIRWING self
function AIRWING:SetTakeoffType(TakeoffType)
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
-- @param #AIRWING self
-- @return #AIRWING self
function AIRWING:SetTakeoffCold()
  self:SetTakeoffType("Cold")
  return self
end

--- Set takeoff type hot. All assets of this squadron will be spawned with engines on (hot).
-- @param #AIRWING self
-- @return #AIRWING self
function AIRWING:SetTakeoffHot()
  self:SetTakeoffType("Hot")
  return self
end

--- Set takeoff type air. All assets of this squadron will be spawned in air above the airbase.
-- @param #AIRWING self
-- @return #AIRWING self
function AIRWING:SetTakeoffAir()
  self:SetTakeoffType("Air")
  return self
end

--- Set the aircraft of the AirWing to land straight in.
-- @param #AIRWING self
-- @return #FLIGHTGROUP self
function AIRWING:SetLandingStraightIn()
  self.OptionLandingStraightIn = true
  return self
end

--- Set the aircraft of the AirWing to land in pairs for groups > 1 aircraft.
-- @param #AIRWING self
-- @return #AIRWING self
function AIRWING:SetLandingForcePair()
  self.OptionLandingForcePair = true
  return self
end

--- Set the aircraft of the AirWing to NOT land in pairs.
-- @param #AIRWING self
-- @return #AIRWING self
function AIRWING:SetLandingRestrictPair()
  self.OptionLandingRestrictPair = true
  return self
end

--- Set the aircraft of the AirWing to land after overhead break.
-- @param #AIRWING self
-- @return #AIRWING self
function AIRWING:SetLandingOverheadBreak()
  self.OptionLandingOverheadBreak = true
  return self
end

--- [Helicopter] Set the aircraft of the AirWing to prefer vertical takeoff and landing.
-- @param #AIRWING self
-- @return #AIRWING self
function AIRWING:SetOptionPreferVerticalLanding()
  self.OptionPreferVerticalLanding = true
  return self
end

--- Set despawn after landing. Aircraft will be despawned after the landing event.
-- Can help to avoid DCS AI taxiing issues.
-- @param #AIRWING self
-- @param #boolean Switch If `true` (default), activate despawn after landing.
-- @return #AIRWING self
function AIRWING:SetDespawnAfterLanding(Switch)
  if Switch then
    self.despawnAfterLanding=Switch
  else
    self.despawnAfterLanding=true
  end
  return self
end

--- Set despawn after holding. Aircraft will be despawned when they arrive at their holding position at the airbase.
-- Can help to avoid DCS AI taxiing issues.
-- @param #AIRWING self
-- @param #boolean Switch If `true` (default), activate despawn after landing.
-- @return #AIRWING self
function AIRWING:SetDespawnAfterHolding(Switch)
  if Switch then
    self.despawnAfterHolding=Switch
  else
    self.despawnAfterHolding=true
  end
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Start & Status
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Start AIRWING FSM.
-- @param #AIRWING self
function AIRWING:onafterStart(From, Event, To)

  -- Start parent Warehouse.
  self:GetParent(self, AIRWING).onafterStart(self, From, Event, To)

  -- Info.
  self:I(self.lid..string.format("Starting AIRWING v%s", AIRWING.version))

end

--- Update status.
-- @param #AIRWING self
function AIRWING:onafterStatus(From, Event, To)

  -- Status of parent Warehouse.
  self:GetParent(self).onafterStatus(self, From, Event, To)

  local fsmstate=self:GetState()

  -- Check CAP missions.
  self:CheckCAP()

  -- Check TANKER missions.
  self:CheckTANKER()

  -- Check AWACS missions.
  self:CheckAWACS()

  -- Check Rescue Helo missions.
  self:CheckRescuhelo()

  -- Check Recon missions.
  self:CheckRECON()
  
  -- Display tactival overview.
  self:_TacticalOverview()  

  ----------------
  -- Transport ---
  ----------------

  -- Check transport queue.
  self:CheckTransportQueue()

  --------------
  -- Mission ---
  --------------

  -- Check mission queue.
  self:CheckMissionQueue()


  -- General info:
  if self.verbose>=1 then

    -- Count missions not over yet.
    local Nmissions=self:CountMissionsInQueue()

    -- Count ALL payloads in stock. If any payload is unlimited, this gives 999.
    local Npayloads=self:CountPayloadsInStock(AUFTRAG.Type)

    -- Assets tot
    local Npq, Np, Nq=self:CountAssetsOnMission()

    local assets=string.format("%d (OnMission: Total=%d, Active=%d, Queued=%d)", self:CountAssets(), Npq, Np, Nq)

    -- Output.
    local text=string.format("%s: Missions=%d, Payloads=%d (%d), Squads=%d, Assets=%s", fsmstate, Nmissions, Npayloads, #self.payloads, #self.cohorts, assets)
    self:I(self.lid..text)
  end

  ------------------
  -- Mission Info --
  ------------------
  if self.verbose>=2 then
    local text=string.format("Missions Total=%d:", #self.missionqueue)
    for i,_mission in pairs(self.missionqueue) do
      local mission=_mission --Ops.Auftrag#AUFTRAG

      local prio=string.format("%d/%s", mission.prio, tostring(mission.importance)) ; if mission.urgent then prio=prio.." (!)" end
      local assets=string.format("%d/%d", mission:CountOpsGroups(), mission:GetNumberOfRequiredAssets())
      local target=string.format("%d/%d Damage=%.1f", mission:CountMissionTargets(), mission:GetTargetInitialNumber(), mission:GetTargetDamage())
      local mystatus=mission:GetLegionStatus(self)

      text=text..string.format("\n[%d] %s %s: Status=%s [%s], Prio=%s, Assets=%s, Targets=%s", i, mission.name, mission.type, mystatus, mission.status, prio, assets, target)
    end
    self:I(self.lid..text)
  end

  -------------------
  -- Squadron Info --
  -------------------
  if self.verbose>=3 then
    local text="Squadrons:"
    for i,_squadron in pairs(self.cohorts) do
      local squadron=_squadron --Ops.Squadron#SQUADRON

      local callsign=squadron.callsignName and UTILS.GetCallsignName(squadron.callsignName) or "N/A"
      local modex=squadron.modex and squadron.modex or -1
      local skill=squadron.skill and tostring(squadron.skill) or "N/A"

      -- Squadron text
      text=text..string.format("\n* %s %s: %s*%d/%d, Callsign=%s, Modex=%d, Skill=%s", squadron.name, squadron:GetState(), squadron.aircrafttype, squadron:CountAssets(true), #squadron.assets, callsign, modex, skill)
    end
    self:I(self.lid..text)
  end

end

--- Get patrol data.
-- @param #AIRWING self
-- @param #table PatrolPoints Patrol data points.
-- @param #number RefuelSystem If provided, only return points with the specific refueling system.
-- @return #AIRWING.PatrolData Patrol point data table.
function AIRWING:_GetPatrolData(PatrolPoints, RefuelSystem)

  -- Sort wrt lowest number of flights on this point.
  local function sort(a,b)
    return a.noccupied<b.noccupied
  end

  if PatrolPoints and #PatrolPoints>0 then

    -- Sort data wrt number of flights at that point.
    table.sort(PatrolPoints, sort)

    for _,_patrolpoint in pairs(PatrolPoints) do
      local patrolpoint=_patrolpoint --#AIRWING.PatrolData
      if patrolpoint.IsZonePoint and patrolpoint.IsZonePoint == true and patrolpoint.patrolzone then
        -- update
        patrolpoint.coord = patrolpoint.patrolzone:GetCoordinate()
      end
      if (RefuelSystem and patrolpoint.refuelsystem and RefuelSystem==patrolpoint.refuelsystem) or RefuelSystem==nil or patrolpoint.refuelsystem==nil then
        return patrolpoint
      end
    end

  end

  -- Return a new point.
  return self:NewPatrolPoint()
end

--- Check how many CAP missions are assigned and add number of missing missions.
-- @param #AIRWING self
-- @return #AIRWING self
function AIRWING:CheckCAP()

  local Ncap=0 


  -- Count CAP missions.
  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG

    if mission:IsNotOver() and (mission.type==AUFTRAG.Type.GCICAP or mission.type == AUFTRAG.Type.PATROLRACETRACK) and mission.patroldata then
      Ncap=Ncap+1
    end

  end

  for i=1,self.nflightsCAP-Ncap do

    local patrol=self:_GetPatrolData(self.pointsCAP)

    local altitude=patrol.altitude+1000*patrol.noccupied

    local missionCAP = nil -- Ops.Auftrag#AUFTRAG
    
    if self.capOptionPatrolRaceTrack then
      
      missionCAP=AUFTRAG:NewPATROL_RACETRACK(patrol.coord,altitude,patrol.speed,patrol.heading,patrol.leg, self.capFormation)
      
    else
        
      missionCAP=AUFTRAG:NewGCICAP(patrol.coord, altitude, patrol.speed, patrol.heading, patrol.leg)
    
    end
    
    if self.capOptionVaryStartTime then
    
      local ClockStart = math.random(self.capOptionVaryStartTime, self.capOptionVaryEndTime)
    
      missionCAP:SetTime(ClockStart)
    
    end
    
    missionCAP.patroldata=patrol

    patrol.noccupied=patrol.noccupied+1

    if self.markpoints then self:UpdatePatrolPointMarker(patrol) end

    self:AddMission(missionCAP)

  end

  return self
end

--- Check how many RECON missions are assigned and add number of missing missions.
-- @param #AIRWING self
-- @return #AIRWING self
function AIRWING:CheckRECON()

  local Ncap=0

  -- Count CAP missions.
  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG

    if mission:IsNotOver() and mission.type==AUFTRAG.Type.RECON and mission.patroldata then
      Ncap=Ncap+1
    end

  end
  
  --self:I(self.lid.."Number of active RECON Missions: "..Ncap)
  
  for i=1,self.nflightsRecon-Ncap do
    
    --self:I(self.lid.."Creating RECON Missions: "..i)
    
    local patrol=self:_GetPatrolData(self.pointsRecon)

    local altitude=patrol.altitude  --+1000*patrol.noccupied
    
    local ZoneSet = SET_ZONE:New()
    local Zone = ZONE_RADIUS:New(self.alias.." Recon "..math.random(1,10000),patrol.coord:GetVec2(),UTILS.NMToMeters(patrol.leg/2))
    
    ZoneSet:AddZone(Zone)
    
    if self.Debug then
      Zone:DrawZone(self.coalition,{0,0,1},Alpha,FillColor,FillAlpha,2,true)
    end
    
    local missionRECON=AUFTRAG:NewRECON(ZoneSet,patrol.speed,patrol.altitude,true)
    
    missionRECON.patroldata=patrol
    missionRECON.categories={AUFTRAG.Category.AIRCRAFT}

    patrol.noccupied=patrol.noccupied+1

    if self.markpoints then self:UpdatePatrolPointMarker(patrol) end

    self:AddMission(missionRECON)

  end

  return self
end

--- Check how many TANKER missions are assigned and add number of missing missions.
-- @param #AIRWING self
-- @return #AIRWING self
function AIRWING:CheckTANKER()

  local Nboom=0
  local Nprob=0

  -- Count tanker missions.
  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG

    if mission:IsNotOver() and mission.type==AUFTRAG.Type.TANKER and mission.patroldata then
      if mission.refuelSystem==Unit.RefuelingSystem.BOOM_AND_RECEPTACLE then
        Nboom=Nboom+1
      elseif mission.refuelSystem==Unit.RefuelingSystem.PROBE_AND_DROGUE then
        Nprob=Nprob+1
      end

    end

  end

  -- Check missing boom tankers.
  for i=1,self.nflightsTANKERboom-Nboom do

    local patrol=self:_GetPatrolData(self.pointsTANKER)

    local altitude=patrol.altitude+1000*patrol.noccupied

    local mission=AUFTRAG:NewTANKER(patrol.coord, altitude, patrol.speed, patrol.heading, patrol.leg, Unit.RefuelingSystem.BOOM_AND_RECEPTACLE)

    mission.patroldata=patrol

    patrol.noccupied=patrol.noccupied+1

    if self.markpoints then self:UpdatePatrolPointMarker(patrol) end

    self:AddMission(mission)

  end

  -- Check missing probe tankers.
  for i=1,self.nflightsTANKERprobe-Nprob do

    local patrol=self:_GetPatrolData(self.pointsTANKER)

    local altitude=patrol.altitude+1000*patrol.noccupied

    local mission=AUFTRAG:NewTANKER(patrol.coord, altitude, patrol.speed, patrol.heading, patrol.leg, Unit.RefuelingSystem.PROBE_AND_DROGUE)

    mission.patroldata=patrol

    patrol.noccupied=patrol.noccupied+1

    if self.markpoints then self:UpdatePatrolPointMarker(patrol) end

    self:AddMission(mission)

  end

  return self
end

--- Check how many AWACS missions are assigned and add number of missing missions.
-- @param #AIRWING self
-- @return #AIRWING self
function AIRWING:CheckAWACS()

  local N=0 --self:CountMissionsInQueue({AUFTRAG.Type.AWACS})

  -- Count AWACS missions.
  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG

    if mission:IsNotOver() and mission.type==AUFTRAG.Type.AWACS and mission.patroldata then
      N=N+1
    end

  end

  for i=1,self.nflightsAWACS-N do

    local patrol=self:_GetPatrolData(self.pointsAWACS)

    local altitude=patrol.altitude+1000*patrol.noccupied

    local mission=AUFTRAG:NewAWACS(patrol.coord, altitude, patrol.speed, patrol.heading, patrol.leg)

    mission.patroldata=patrol

    patrol.noccupied=patrol.noccupied+1

    if self.markpoints then self:UpdatePatrolPointMarker(patrol) end

    self:AddMission(mission)

  end

  return self
end

--- Check how many Rescue helos are currently in the air.
-- @param #AIRWING self
-- @return #AIRWING self
function AIRWING:CheckRescuhelo()

  local N=self:CountMissionsInQueue({AUFTRAG.Type.RESCUEHELO})

  if self.airbase then
  
    local name=self.airbase:GetName()
  
    local carrier=UNIT:FindByName(name)
  
    for i=1,self.nflightsRescueHelo-N do
  
      local mission=AUFTRAG:NewRESCUEHELO(carrier)
  
      self:AddMission(mission)
  
    end
    
  end

  return self
end

--- Check how many AWACS missions are assigned and add number of missing missions.
-- @param #AIRWING self
-- @param Ops.FlightGroup#FLIGHTGROUP flightgroup The flightgroup.
-- @return Functional.Warehouse#WAREHOUSE.Assetitem The tanker asset.
function AIRWING:GetTankerForFlight(flightgroup)

  local tankers=self:GetAssetsOnMission(AUFTRAG.Type.TANKER)

  if #tankers>0 then

    local tankeropt={}
    for _,_tanker in pairs(tankers) do
      local tanker=_tanker --Functional.Warehouse#WAREHOUSE.Assetitem

      -- Check that donor and acceptor use the same refuelling system.
      if flightgroup.refueltype and flightgroup.refueltype==tanker.flightgroup.tankertype then

        local tankercoord=tanker.flightgroup.group:GetCoordinate()
        local assetcoord=flightgroup.group:GetCoordinate()

        local dist=assetcoord:Get2DDistance(tankercoord)

        -- Ensure that the flight does not find itself. Asset could be a tanker!
        if dist>5 then
          table.insert(tankeropt, {tanker=tanker, dist=dist})
        end

      end
    end

    -- Sort tankers wrt to distance.
    table.sort(tankeropt, function(a,b) return a.dist<b.dist end)

    -- Return tanker asset.
    if #tankeropt>0 then
      return tankeropt[1].tanker
    else
      return nil
    end
  end

  return nil
end

--- Add the ability to call back an Ops.AWACS#AWACS object with an FSM call "FlightOnMission(FlightGroup, Mission)".
-- @param #AIRWING self
-- @param Ops.AWACS#AWACS ConnectecdAwacs
-- @return #AIRWING self
function AIRWING:SetUsingOpsAwacs(ConnectecdAwacs)
  self:I(self.lid .. "Added AWACS Object: "..ConnectecdAwacs:GetName() or "unknown")
  self.UseConnectedOpsAwacs = true
  self.ConnectedOpsAwacs = ConnectecdAwacs
  return self
end

--- Remove the ability to call back an Ops.AWACS#AWACS object with an FSM call "FlightOnMission(FlightGroup, Mission)".
-- @param #AIRWING self
-- @return #AIRWING self
function AIRWING:RemoveUsingOpsAwacs()
  self:I(self.lid .. "Reomve AWACS Object: "..self.ConnectedOpsAwacs:GetName() or "unknown")
  self.UseConnectedOpsAwacs = false
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Events
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after "FlightOnMission".
-- @param #AIRWING self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.FlightGroup#FLIGHTGROUP FlightGroup Ops flight group on mission.
-- @param Ops.Auftrag#AUFTRAG Mission The requested mission.
function AIRWING:onafterFlightOnMission(From, Event, To, FlightGroup, Mission)
  -- Debug info.
  self:T(self.lid..string.format("Group %s on %s mission %s", FlightGroup:GetName(), Mission:GetType(), Mission:GetName()))
  if self.UseConnectedOpsAwacs and self.ConnectedOpsAwacs then
    self.ConnectedOpsAwacs:__FlightOnMission(2,FlightGroup,Mission)
  end
  -- Landing Options  
  if self.OptionLandingForcePair then
    FlightGroup:SetOptionLandingForcePair()
  elseif self.OptionLandingOverheadBreak then
   FlightGroup:SetOptionLandingOverheadBreak()
  elseif self.OptionLandingRestrictPair then
   FlightGroup:SetOptionLandingRestrictPair()
  elseif self.OptionLandingStraightIn then
    FlightGroup:SetOptionLandingStraightIn()
  end
  -- Landing Options Helo
  if self.OptionPreferVerticalLanding then
    FlightGroup:SetOptionPreferVertical()
  end
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Count payloads in stock.
-- @param #AIRWING self
-- @param #table MissionTypes Types on mission to be checked. Default *all* possible types `AUFTRAG.Type`.
-- @param #table UnitTypes Types of units.
-- @param #table Payloads Specific payloads to be counted only.
-- @return #number Count of available payloads in stock.
function AIRWING:CountPayloadsInStock(MissionTypes, UnitTypes, Payloads)

  if MissionTypes then
    if type(MissionTypes)=="string" then
      MissionTypes={MissionTypes}
    end
  end

  if UnitTypes then
    if type(UnitTypes)=="string" then
      UnitTypes={UnitTypes}
    end
  end

  local function _checkUnitTypes(payload)
    if UnitTypes then
      for _,unittype in pairs(UnitTypes) do
        if unittype==payload.aircrafttype then
          return true
        end
      end
    else
      -- Unit type was not specified.
      return true
    end
    return false
  end

  local function _checkPayloads(payload)
    if Payloads then
      for _,Payload in pairs(Payloads) do
        if Payload.uid==payload.uid then
          return true
        end
      end
    else
      -- Payload was not specified.
      return nil
    end
    return false
  end

  local n=0
  for _,_payload in pairs(self.payloads) do
    local payload=_payload --#AIRWING.Payload

    for _,MissionType in pairs(MissionTypes) do

      local specialpayload=_checkPayloads(payload)
      local compatible=AUFTRAG.CheckMissionCapability(MissionType, payload.capabilities)

      local goforit = specialpayload or (specialpayload==nil and compatible)

      if goforit and _checkUnitTypes(payload) then

        if payload.unlimited then
          -- Payload is unlimited. Return a BIG number.
          return 999
        else
          n=n+payload.navail
        end

      end

    end
  end

  return n
end

--- Get payload performance for a given type of misson type.
-- @param #AIRWING self
-- @param #AIRWING.Payload Payload The payload table.
-- @param #string MissionType Type of mission.
-- @return #number Performance or -1.
function AIRWING:GetPayloadPeformance(Payload, MissionType)

  if Payload then

    for _,Capability in pairs(Payload.capabilities) do
      local capability=Capability --Ops.Auftrag#AUFTRAG.Capability
      if capability.MissionType==MissionType then
        return capability.Performance
      end
    end

  else
    self:E(self.lid.."ERROR: Payload is nil!")
  end

  return -1
end

--- Get mission types a payload can perform.
-- @param #AIRWING self
-- @param #AIRWING.Payload Payload The payload table.
-- @return #table Mission types.
function AIRWING:GetPayloadMissionTypes(Payload)

  local missiontypes={}

  for _,Capability in pairs(Payload.capabilities) do
    local capability=Capability --Ops.Auftrag#AUFTRAG.Capability
    table.insert(missiontypes, capability.MissionType)
  end

  return missiontypes
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
