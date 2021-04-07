--- **Ops** - Airwing Warehouse.
--
-- **Main Features:**
--
--    * Manage squadrons.
--
-- ===
--
-- ### Author: **funkyfranky**
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
-- @field #number nflightsCAP Number of CAP flights constantly in the air.
-- @field #number nflightsAWACS Number of AWACS flights constantly in the air.
-- @field #number nflightsTANKERboom Number of TANKER flights with BOOM constantly in the air.
-- @field #number nflightsTANKERprobe Number of TANKER flights with PROBE constantly in the air. 
-- @field #number nflightsRescueHelo Number of Rescue helo flights constantly in the air.
-- @field #table pointsCAP Table of CAP points.
-- @field #table pointsTANKER Table of Tanker points.
-- @field #table pointsAWACS Table of AWACS points.
-- @field Ops.WingCommander#WINGCOMMANDER wingcommander The wing commander responsible for this airwing.
-- 
-- @field Ops.RescueHelo#RESCUEHELO rescuehelo The rescue helo.
-- @field Ops.RecoveryTanker#RECOVERYTANKER recoverytanker The recoverytanker.
-- 
-- @extends Functional.Warehouse#WAREHOUSE

--- Be surprised!
--
-- ===
--
-- ![Banner Image](..\Presentations\OPS\AirWing\_Main.png)
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
-- This mission will be put into the AIRWING queue. Once the mission start time is reached and all resources (airframes and pylons) are available, the mission is started.
-- If the mission stop time is over (and the mission is not finished), it will be cancelled and removed from the queue. This applies also to mission that were not even
-- started.
-- 
-- # Command an Airwing
-- 
-- An airwing can receive missions from a WINGCOMMANDER. See docs of that class for details.
-- 
-- However, you are still free to add missions at anytime.
--
--
-- @field #AIRWING
AIRWING = {
  ClassName      = "AIRWING",
  verbose        =     0,
  lid            =   nil,
  menu           =   nil,
  squadrons      =    {},
  missionqueue   =    {},
  payloads       =    {},
  payloadcounter =     0,
  pointsCAP      =    {},
  pointsTANKER   =    {},
  pointsAWACS    =    {},
  wingcommander  =   nil,
  markpoints     =   false,
}

--- Squadron asset.
-- @type AIRWING.SquadronAsset
-- @field #AIRWING.Payload payload The payload of the asset.
-- @field Ops.FlightGroup#FLIGHTGROUP flightgroup The flightgroup object.
-- @field #string squadname Name of the squadron this asset belongs to.
-- @field #number Treturned Time stamp when asset returned to the airwing.
-- @extends Functional.Warehouse#WAREHOUSE.Assetitem

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
-- @field #number noccupied Number of flights on this patrol point.
-- @field Wrapper.Marker#MARKER marker F10 marker.

--- AIRWING class version.
-- @field #string version
AIRWING.version="0.5.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ToDo list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Spawn in air or hot ==> Needs WAREHOUSE update.
-- TODO: Make special request to transfer squadrons to anther airwing (or warehouse).
-- TODO: Check that airbase has enough parking spots if a request is BIG. Alternatively, split requests.
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

  -- Inherit everything from WAREHOUSE class.
  local self=BASE:Inherit(self, WAREHOUSE:New(warehousename, airwingname)) -- #AIRWING

  -- Nil check.
  if not self then
    BASE:E(string.format("ERROR: Could not find warehouse %s!", warehousename))
    return nil
  end

  -- Set some string id for output to DCS.log file.
  self.lid=string.format("AIRWING %s | ", self.alias)

  -- Add FSM transitions.
  --                 From State  -->   Event        -->     To State
  self:AddTransition("*",             "MissionRequest",     "*")           -- Add a (mission) request to the warehouse.
  self:AddTransition("*",             "MissionCancel",      "*")           -- Cancel mission.
  
  self:AddTransition("*",             "SquadAssetReturned", "*")           -- Flight was spawned with a mission.
  
  self:AddTransition("*",             "FlightOnMission",    "*")           -- Flight was spawned with a mission.

  -- Defaults:
  --self:SetVerbosity(0)
  self.nflightsCAP=0
  self.nflightsAWACS=0
  self.nflightsTANKERboom=0
  self.nflightsTANKERprobe=0
  self.nflightsRecoveryTanker=0
  self.nflightsRescueHelo=0
  self.markpoints = false

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
 
  --- On after "FlightOnMission" event. Triggered when an asset group starts a mission.
   -- @function [parent=#AIRWING] OnAfterFlightOnMission
   -- @param #AIRWING self
   -- @param #string From The From state
   -- @param #string Event The Event called
   -- @param #string To The To state
   -- @param Ops.FlightGroup#FLIGHTGROUP Flightgroup The Flightgroup on mission
   -- @param Ops.Auftrag#AUFTRAG Mission The Auftrag of the Flightgroup
   
   --- On after "AssetReturned" event. Triggered when an asset group returned to its airwing.
    -- @function [parent=#AIRWING] OnAfterAssetReturned
    -- @param #AIRWING self
    -- @param #string From From state.
    -- @param #string Event Event.
    -- @param #string To To state.
    -- @param Ops.Squadron#SQUADRON Squadron The asset squadron.
    -- @param #AIRWING.SquadronAsset Asset The asset that returned.

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
  table.insert(self.squadrons, Squadron)
  
  -- Add assets to squadron.
  self:AddAssetToSquadron(Squadron, Squadron.Ngroups)
  
  -- Tanker and AWACS get unlimited payloads.
  if Squadron.attribute==GROUP.Attribute.AIR_AWACS then
    self:NewPayload(Squadron.templategroup, -1, AUFTRAG.Type.AWACS)
  elseif Squadron.attribute==GROUP.Attribute.AIR_TANKER then
    self:NewPayload(Squadron.templategroup, -1, AUFTRAG.Type.TANKER)
  end

  -- Set airwing to squadron.
  Squadron:SetAirwing(self)
  
  -- Start squadron.
  if Squadron:IsStopped() then
    Squadron:Start()
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
    payload.unlimited=Npayloads<0
    if payload.unlimited then
      payload.navail=1
    else
      payload.navail=Npayloads or 99
    end
    
    payload.capabilities={}
    for _,missiontype in pairs(MissionTypes) do
      local capability={} --Ops.Auftrag#AUFTRAG.Capability
      capability.MissionType=missiontype
      capability.Performance=Performance
      table.insert(payload.capabilities, capability)
    end
    
    -- Add ORBIT for all.  
    if not self:CheckMissionType(AUFTRAG.Type.ORBIT, MissionTypes) then
      local capability={}  --Ops.Auftrag#AUFTRAG.Capability
      capability.MissionType=AUFTRAG.Type.ORBIT
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
      return (performanceA>performanceB) or (performanceA==performanceB and a.unlimited==true) or (performanceA==performanceB and a.unlimited==true and b.unlimited==true and a.navail>b.navail)
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
    local compatible=self:CheckMissionCapability(MissionType, payload.capabilities)
    
    local goforit = specialpayload or (specialpayload==nil and compatible)

    if payload.aircrafttype==UnitType and payload.navail>0 and goforit then
      table.insert(payloads, payload)
    end
  end
  
  -- Debug.
  if self.verbose>=4 then
    self:I(self.lid..string.format("Sorted payloads for mission type X and aircraft type=Y:"))
    for _,_payload in ipairs(self.payloads) do
      local payload=_payload --#AIRWING.Payload
      if payload.aircrafttype==UnitType and self:CheckMissionCapability(MissionType, payload.capabilities) then
        local performace=self:GetPayloadPeformance(payload, MissionType)
        self:I(self.lid..string.format("FF %s payload for %s: avail=%d performace=%d", MissionType, payload.aircrafttype, payload.navail, performace))
      end
    end
  end
  
  -- Cases:
  if #payloads==0 then
    -- No payload available.
    self:T(self.lid.."Warning could not find a payload for airframe X mission type Y!")
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
-- @param #AIRWING.SquadronAsset asset The squadron asset.
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

  for _,_squadron in pairs(self.squadrons) do
    local squadron=_squadron --Ops.Squadron#SQUADRON
    
    if squadron.name==SquadronName then
      return squadron
    end
    
  end

  return nil
end

--- Set verbosity level.
-- @param #AIRWING self
-- @param #number VerbosityLevel Level of output (higher=more). Default 0.
-- @return #AIRWING self
function AIRWING:SetVerbosity(VerbosityLevel)
  self.verbose=VerbosityLevel or 0
  return self
end

--- Get squadron of an asset.
-- @param #AIRWING self
-- @param #AIRWING.SquadronAsset Asset The squadron asset.
-- @return Ops.Squadron#SQUADRON The squadron object.
function AIRWING:GetSquadronOfAsset(Asset)
  return self:GetSquadron(Asset.squadname)
end

--- Remove asset from squadron.
-- @param #AIRWING self
-- @param #AIRWING.SquadronAsset Asset The squad asset.
function AIRWING:RemoveAssetFromSquadron(Asset)
  local squad=self:GetSquadronOfAsset(Asset)
  if squad then
    squad:DelAsset(Asset)
  end
end

--- Add mission to queue.
-- @param #AIRWING self
-- @param Ops.Auftrag#AUFTRAG Mission for this group.
-- @return #AIRWING self
function AIRWING:AddMission(Mission)
  
  -- Set status to QUEUED. This also attaches the airwing to this mission.
  Mission:Queued(self)
  
  -- Add mission to queue.
  table.insert(self.missionqueue, Mission)
  
  -- Info text.
  local text=string.format("Added mission %s (type=%s). Starting at %s. Stopping at %s", 
  tostring(Mission.name), tostring(Mission.type), UTILS.SecondsToClock(Mission.Tstart, true), Mission.Tstop and UTILS.SecondsToClock(Mission.Tstop, true) or "INF")
  self:T(self.lid..text)
  
  return self
end

--- Remove mission from queue.
-- @param #AIRWING self
-- @param Ops.Auftrag#AUFTRAG Mission Mission to be removed.
-- @return #AIRWING self
function AIRWING:RemoveMission(Mission)

  for i,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG
    
    if mission.auftragsnummer==Mission.auftragsnummer then
      table.remove(self.missionqueue, i)
      break
    end
    
  end

  return self
end

--- Set number of CAP flights constantly carried out.
-- @param #AIRWING self
-- @param #number n Number of flights. Default 1.
-- @return #AIRWING self
function AIRWING:SetNumberCAP(n)
  self.nflightsCAP=n or 1
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
-- @param #AIRWING.PatrolData point Patrol point table.
function AIRWING.UpdatePatrolPointMarker(point)
    local text=string.format("%s Occupied=%d\nheading=%03d, leg=%d NM, alt=%d ft, speed=%d kts", 
    point.type, point.noccupied, point.heading, point.leg, point.altitude, point.speed)
  
    point.marker:UpdateText(text, 1)
end


--- Create a new generic patrol point.
-- @param #AIRWING self
-- @param #string Type Patrol point type, e.g. "CAP" or "AWACS". Default "Unknown".
-- @param Core.Point#COORDINATE Coordinate Coordinate of the patrol point. Default 10-15 NM away from the location of the airwing.
-- @param #number Altitude Orbit altitude in feet. Default random between Angels 10 and 20.
-- @param #number Heading Heading in degrees. Default random (0, 360] degrees.
-- @param #number LegLength Length of race-track orbit in NM. Default 15 NM.
-- @param #number Speed Orbit speed in knots. Default 350 knots.
-- @return #AIRWING.PatrolData Patrol point table.
function AIRWING:NewPatrolPoint(Type, Coordinate, Altitude, Speed, Heading, LegLength)

  local patrolpoint={}  --#AIRWING.PatrolData
  patrolpoint.type=Type or "Unknown"
  patrolpoint.coord=Coordinate or self:GetCoordinate():Translate(UTILS.NMToMeters(math.random(10, 15)), math.random(360))
  patrolpoint.heading=Heading or math.random(360)
  patrolpoint.leg=LegLength or 15
  patrolpoint.altitude=Altitude or math.random(10,20)*1000
  patrolpoint.speed=Speed or 350
  patrolpoint.noccupied=0
  
  if self.markpoints then
    patrolpoint.marker=MARKER:New(Coordinate, "New Patrol Point"):ToAll()
    AIRWING.UpdatePatrolPointMarker(patrolpoint)
  end
  
  return patrolpoint
end

--- Add a patrol Point for CAP missions.
-- @param #AIRWING self
-- @param Core.Point#COORDINATE Coordinate Coordinate of the patrol point.
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

--- Add a patrol Point for TANKER missions.
-- @param #AIRWING self
-- @param Core.Point#COORDINATE Coordinate Coordinate of the patrol point.
-- @param #number Altitude Orbit altitude in feet.
-- @param #number Speed Orbit speed in knots.
-- @param #number Heading Heading in degrees.
-- @param #number LegLength Length of race-track orbit in NM.
-- @return #AIRWING self
function AIRWING:AddPatrolPointTANKER(Coordinate, Altitude, Speed, Heading, LegLength)
  
  local patrolpoint=self:NewPatrolPoint("Tanker", Coordinate, Altitude, Speed, Heading, LegLength)

  table.insert(self.pointsTANKER, patrolpoint)

  return self
end

--- Add a patrol Point for AWACS missions.
-- @param #AIRWING self
-- @param Core.Point#COORDINATE Coordinate Coordinate of the patrol point.
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

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Start & Status
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Start AIRWING FSM.
-- @param #AIRWING self
function AIRWING:onafterStart(From, Event, To)

  -- Start parent Warehouse.
  self:GetParent(self).onafterStart(self, From, Event, To)

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
    local text=string.format("%s: Missions=%d, Payloads=%d (%d), Squads=%d, Assets=%s", fsmstate, Nmissions, Npayloads, #self.payloads, #self.squadrons, assets)
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
      local assets=string.format("%d/%d", mission:CountOpsGroups(), mission.nassets)
      local target=string.format("%d/%d Damage=%.1f", mission:CountMissionTargets(), mission:GetTargetInitialNumber(), mission:GetTargetDamage())
      
      text=text..string.format("\n[%d] %s %s: Status=%s, Prio=%s, Assets=%s, Targets=%s", i, mission.name, mission.type, mission.status, prio, assets, target)
    end
    self:I(self.lid..text)
  end
  
  -------------------
  -- Squadron Info --
  -------------------
  if self.verbose>=3 then
    local text="Squadrons:"
    for i,_squadron in pairs(self.squadrons) do
      local squadron=_squadron --Ops.Squadron#SQUADRON
      
      local callsign=squadron.callsignName and UTILS.GetCallsignName(squadron.callsignName) or "N/A"
      local modex=squadron.modex and squadron.modex or -1
      local skill=squadron.skill and tostring(squadron.skill) or "N/A"
      
      -- Squadron text
      text=text..string.format("\n* %s %s: %s*%d/%d, Callsign=%s, Modex=%d, Skill=%s", squadron.name, squadron:GetState(), squadron.aircrafttype, squadron:CountAssetsInStock(), #squadron.assets, callsign, modex, skill)
    end
    self:I(self.lid..text)
  end
   
  --------------
  -- Mission ---
  --------------

  -- Check if any missions should be cancelled.
  self:_CheckMissions()

  -- Get next mission.
  local mission=self:_GetNextMission()

  -- Request mission execution.  
  if mission then
    self:MissionRequest(mission)
  end

end

--- Get patrol data
-- @param #AIRWING self
-- @param #table PatrolPoints Patrol data points.
-- @return #AIRWING.PatrolData
function AIRWING:_GetPatrolData(PatrolPoints)

  -- Sort wrt lowest number of flights on this point.
  local function sort(a,b)
    return a.noccupied<b.noccupied
  end

  if PatrolPoints and #PatrolPoints>0 then
  
    -- Sort data wrt number of flights at that point.
    table.sort(PatrolPoints, sort)
    return PatrolPoints[1]

  else
    
    return self:NewPatrolPoint()
      
  end
  
end

--- Check how many CAP missions are assigned and add number of missing missions.
-- @param #AIRWING self
-- @return #AIRWING self
function AIRWING:CheckCAP()

  local Ncap=self:CountMissionsInQueue({AUFTRAG.Type.GCICAP, AUFTRAG.Type.INTERCEPT})
  
  for i=1,self.nflightsCAP-Ncap do
  
    local patrol=self:_GetPatrolData(self.pointsCAP)
    
    local altitude=patrol.altitude+1000*patrol.noccupied
    
    local missionCAP=AUFTRAG:NewGCICAP(patrol.coord, altitude, patrol.speed, patrol.heading, patrol.leg)
    
    missionCAP.patroldata=patrol
    
    patrol.noccupied=patrol.noccupied+1
    
    if self.markpoints then AIRWING.UpdatePatrolPointMarker(patrol) end
    
    self:AddMission(missionCAP)
      
  end
  
  return self
end

--- Check how many TANKER missions are assigned and add number of missing missions.
-- @param #AIRWING self
-- @return #AIRWING self
function AIRWING:CheckTANKER()

  local Nboom=0
  local Nprob=0
  
  -- Count tanker mission.
  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG
    
    if mission:IsNotOver() and mission.type==AUFTRAG.Type.TANKER then
      if mission.refuelSystem==0 then
        Nboom=Nboom+1
      elseif mission.refuelSystem==1 then
        Nprob=Nprob+1
      end
    
    end
  
  end
  
  for i=1,self.nflightsTANKERboom-Nboom do
  
    local patrol=self:_GetPatrolData(self.pointsTANKER)
    
    local altitude=patrol.altitude+1000*patrol.noccupied
    
    local mission=AUFTRAG:NewTANKER(patrol.coord, altitude, patrol.speed, patrol.heading, patrol.leg, 1)
    
    mission.patroldata=patrol
    
    patrol.noccupied=patrol.noccupied+1
    
    if self.markpoints then AIRWING.UpdatePatrolPointMarker(patrol) end
    
    self:AddMission(mission)
      
  end
  
  for i=1,self.nflightsTANKERprobe-Nprob do
  
    local patrol=self:_GetPatrolData(self.pointsTANKER)
    
    local altitude=patrol.altitude+1000*patrol.noccupied
    
    local mission=AUFTRAG:NewTANKER(patrol.coord, altitude, patrol.speed, patrol.heading, patrol.leg, 0)
    
    mission.patroldata=patrol
    
    patrol.noccupied=patrol.noccupied+1
    
    if self.markpoints then AIRWING.UpdatePatrolPointMarker(patrol) end
    
    self:AddMission(mission)
      
  end  
  
  return self
end

--- Check how many AWACS missions are assigned and add number of missing missions.
-- @param #AIRWING self
-- @return #AIRWING self
function AIRWING:CheckAWACS()

  local N=self:CountMissionsInQueue({AUFTRAG.Type.AWACS})
  
  for i=1,self.nflightsAWACS-N do
  
    local patrol=self:_GetPatrolData(self.pointsAWACS)
    
    local altitude=patrol.altitude+1000*patrol.noccupied
    
    local mission=AUFTRAG:NewAWACS(patrol.coord, altitude, patrol.speed, patrol.heading, patrol.leg)
    
    mission.patroldata=patrol
    
    patrol.noccupied=patrol.noccupied+1
    
    if self.markpoints then AIRWING.UpdatePatrolPointMarker(patrol) end
    
    self:AddMission(mission)
      
  end
  
  return self
end

--- Check how many Rescue helos are currently in the air.
-- @param #AIRWING self
-- @return #AIRWING self
function AIRWING:CheckRescuhelo()

  local N=self:CountMissionsInQueue({AUFTRAG.Type.RESCUEHELO})
  
  local name=self.airbase:GetName()
  
  local carrier=UNIT:FindByName(name)
  
  for i=1,self.nflightsRescueHelo-N do
    
    local mission=AUFTRAG:NewRESCUEHELO(carrier)
    
    self:AddMission(mission)
      
  end
  
  return self
end

--- Check how many AWACS missions are assigned and add number of missing missions.
-- @param #AIRWING self
-- @param Ops.FlightGroup#FLIGHTGROUP flightgroup The flightgroup.
-- @return #AIRWING.SquadronAsset The tanker asset.
function AIRWING:GetTankerForFlight(flightgroup)

  local tankers=self:GetAssetsOnMission(AUFTRAG.Type.TANKER)
  
  if #tankers>0 then
  
    local tankeropt={}
    for _,_tanker in pairs(tankers) do
      local tanker=_tanker --#AIRWING.SquadronAsset
      
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


--- Check if mission is not over and ready to cancel.
-- @param #AIRWING self
function AIRWING:_CheckMissions()

  -- Loop over missions in queue.
  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG
    
    if mission:IsNotOver() and mission:IsReadyToCancel() then    
      mission:Cancel()
    end
  end
  
end
--- Get next mission.
-- @param #AIRWING self
-- @return Ops.Auftrag#AUFTRAG Next mission or *nil*.
function AIRWING:_GetNextMission()

  -- Number of missions.
  local Nmissions=#self.missionqueue

  -- Treat special cases.
  if Nmissions==0 then
    return nil
  end

  -- Sort results table wrt prio and start time.
  local function _sort(a, b)
    local taskA=a --Ops.Auftrag#AUFTRAG
    local taskB=b --Ops.Auftrag#AUFTRAG
    return (taskA.prio<taskB.prio) or (taskA.prio==taskB.prio and taskA.Tstart<taskB.Tstart)
  end
  table.sort(self.missionqueue, _sort)
  
  -- Look for first mission that is SCHEDULED.
  local vip=math.huge
  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG    
    if mission.importance and mission.importance<vip then
      vip=mission.importance
    end
  end
  
  -- Current time.
  local time=timer.getAbsTime()

  -- Look for first task that is not accomplished.
  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG
    
    -- Firstly, check if mission is due?
    if mission:IsQueued() and mission:IsReadyToGo() and (mission.importance==nil or mission.importance<=vip) then
        
      -- Check if airwing can do the mission and gather required assets.
      local can, assets=self:CanMission(mission)
      
      -- Check that mission is still scheduled, time has passed and enough assets are available.
       if can then        
       
        -- Optimize the asset selection. Most useful assets will come first. We do not include the payload as some assets have and some might not.
        self:_OptimizeAssetSelection(assets, mission, false)
        
        -- Assign assets to mission.
        local remove={}
        local gotpayload={}
        for i=1,#assets do
          local asset=assets[i] --#AIRWING.SquadronAsset
          
          -- Get payload for the asset.
          if not asset.payload then
            local payload=self:FetchPayloadFromStock(asset.unittype, mission.type, mission.payloads)
            if payload then
              asset.payload=payload
              table.insert(gotpayload, asset.uid)
            else
              table.insert(remove, asset.uid)
            end
          end
        end        
        self:T(self.lid..string.format("Provided %d assets with payloads. Could not get payload for %d assets", #gotpayload, #remove))
        
        -- Now remove assets for which we don't have a payload.
        for i=#assets,1,-1 do
          local asset=assets[i] --#AIRWING.SquadronAsset
          for _,uid in pairs(remove) do
            if uid==asset.uid then
              table.remove(assets, i)
            end
          end
        end
        
        -- Another check.
        if #assets<mission.nassets then
          self:E(self.lid..string.format("ERROR: Not enough payloads for mission assets! Can only do %d/%d", #assets, mission.nassets))
        end
        
        -- Optimize the asset selection. Now we include the payload performance as this could change the result.
        self:_OptimizeAssetSelection(assets, mission, true)        
      
        -- Check that mission.assets table is clean.
        if mission.assets and #mission.assets>0 then
          self:E(self.lid..string.format("ERROR: mission %s of type %s has already assets attached!", mission.name, mission.type))
        end
        mission.assets={}
      
        -- Assign assets to mission.
        for i=1,mission.nassets do
          local asset=assets[i] --#AIRWING.SquadronAsset
                    
          -- Should not happen as we just checked!
          if not asset.payload then
            self:E(self.lid.."ERROR: No payload for asset! This should not happen!")
          end
          
          -- Add asset to mission.
          mission:AddAsset(asset)
        end
        
        -- Now return the remaining payloads.
        for i=mission.nassets+1,#assets do
          local asset=assets[i] --#AIRWING.SquadronAsset
          for _,uid in pairs(gotpayload) do
            if uid==asset.uid then
              self:ReturnPayloadFromAsset(asset)
              break
            end
          end
        end
        
        return mission
      end

    end -- mission due?
  end -- mission loop

  return nil
end

--- Calculate the mission score of an asset.
-- @param #AIRWING self
-- @param #AIRWING.SquadronAsset asset Asset
-- @param Ops.Auftrag#AUFTRAG Mission Mission for which the best assets are desired.
-- @param #boolean includePayload If true, include the payload in the calulation if the asset has one attached.
-- @return #number Mission score.
function AIRWING:CalculateAssetMissionScore(asset, Mission, includePayload)

  local score=0
  
  -- Prefer highly skilled assets.
  if asset.skill==AI.Skill.AVERAGE then
    score=score+0
  elseif asset.skill==AI.Skill.GOOD then
    score=score+10
  elseif asset.skill==AI.Skill.HIGH then
    score=score+20
  elseif asset.skill==AI.Skill.EXCELLENT then
    score=score+30
  end
  
  -- Add mission performance to score.
  local squad=self:GetSquadronOfAsset(asset)
  local missionperformance=squad:GetMissionPeformance(Mission.type)
  score=score+missionperformance
  
  -- Add payload performance to score.
  if includePayload and asset.payload then
    score=score+self:GetPayloadPeformance(asset.payload, Mission.type)
  end
  
  -- Intercepts need to be carried out quickly. We prefer spawned assets.
  if Mission.type==AUFTRAG.Type.INTERCEPT then
    if asset.spawned then
      self:T(self.lid.."Adding 25 to asset because it is spawned")
      score=score+25
    end
  end
  
  -- TODO: This could be vastly improved. Need to gather ideas during testing.
  -- Calculate ETA? Assets on orbit missions should arrive faster even if they are further away.
  -- Max speed of assets.
  -- Fuel amount?
  -- Range of assets?  
  
  return score
end

--- Optimize chosen assets for the mission at hand.
-- @param #AIRWING self
-- @param #table assets Table of (unoptimized) assets.
-- @param Ops.Auftrag#AUFTRAG Mission Mission for which the best assets are desired.
-- @param #boolean includePayload If true, include the payload in the calulation if the asset has one attached.
function AIRWING:_OptimizeAssetSelection(assets, Mission, includePayload)

  local TargetVec2=Mission:GetTargetVec2()

  --local dStock=self:GetCoordinate():Get2DDistance(TargetCoordinate)
  
  local dStock=UTILS.VecDist2D(TargetVec2, self:GetVec2())
  
  -- Calculate distance to mission target.
  local distmin=math.huge
  local distmax=0
  for _,_asset in pairs(assets) do
    local asset=_asset --#AIRWING.SquadronAsset
    
    if asset.spawned then
      local group=GROUP:FindByName(asset.spawngroupname)
      --asset.dist=group:GetCoordinate():Get2DDistance(TargetCoordinate)
      asset.dist=UTILS.VecDist2D(group:GetVec2(), TargetVec2)
    else
      asset.dist=dStock
    end
    
    if asset.dist<distmin then
      distmin=asset.dist
    end
    
    if asset.dist>distmax then
      distmax=asset.dist
    end
     
  end
  
  -- Calculate the mission score of all assets.
  for _,_asset in pairs(assets) do
    local asset=_asset --#AIRWING.SquadronAsset
    --self:I(string.format("FF asset %s has payload %s", asset.spawngroupname, asset.payload and "yes" or "no!"))
    asset.score=self:CalculateAssetMissionScore(asset, Mission, includePayload)
  end
    
  --- Sort assets wrt to their mission score. Higher is better. 
  local function optimize(a, b)
    local assetA=a --#AIRWING.SquadronAsset
    local assetB=b --#AIRWING.SquadronAsset
    
    -- Higher score wins. If equal score ==> closer wins.
    -- TODO: Need to include the distance in a smarter way!
    return (assetA.score>assetB.score) or (assetA.score==assetB.score and assetA.dist<assetB.dist)
  end
  table.sort(assets, optimize)
  
  -- Remove distance parameter.
  local text=string.format("Optimized assets for %s mission (payload=%s):", Mission.type, tostring(includePayload))
  for i,Asset in pairs(assets) do
    local asset=Asset --#AIRWING.SquadronAsset
    text=text..string.format("\n%s %s: score=%d, distance=%.1f km", asset.squadname, asset.spawngroupname, asset.score, asset.dist/1000)
    asset.dist=nil
    asset.score=nil
  end
  self:T2(self.lid..text)

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Events
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after "MissionRequest" event. Performs a self request to the warehouse for the mission assets. Sets mission status to REQUESTED.
-- @param #AIRWING self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.Auftrag#AUFTRAG Mission The requested mission.
function AIRWING:onafterMissionRequest(From, Event, To, Mission)

  -- Set mission status from QUEUED to REQUESTED. Ensures that it is not considered in the next selection.
  Mission:Requested()
  
  ---
  -- Some assets might already be spawned and even on a different mission (orbit).
  -- Need to dived to set into spawned and instock assets and handle the other
  ---

  -- Assets to be requested.
  local Assetlist={}
  
  for _,_asset in pairs(Mission.assets) do
    local asset=_asset --#AIRWING.SquadronAsset
    
    if asset.spawned then
    
      if asset.flightgroup then

        -- Add new mission.
        asset.flightgroup:AddMission(Mission)
        
        -- Trigger event.
        self:FlightOnMission(asset.flightgroup, Mission)
        
      else
        self:E(self.lid.."ERROR: flight group for asset does NOT exist!")
      end    
    
    else
      -- These assets need to be requested and spawned.
      table.insert(Assetlist, asset)
    end
  end

  -- Add request to airwing warehouse.
  if #Assetlist>0 then
  
    --local text=string.format("Requesting assets for mission %s:", Mission.name)
    for i,_asset in pairs(Assetlist) do
      local asset=_asset --#AIRWING.SquadronAsset
      
      -- Set asset to requested! Important so that new requests do not use this asset!
      asset.requested=true
      
      if Mission.missionTask then
        asset.missionTask=Mission.missionTask
      end
      
    end
  
    -- Add request to airwing warehouse.
    -- TODO: better Assignment string.
    self:AddRequest(self, WAREHOUSE.Descriptor.ASSETLIST, Assetlist, #Assetlist, nil, nil, Mission.prio, tostring(Mission.auftragsnummer))
    
    -- The queueid has been increased in the onafterAddRequest function. So we can simply use it here.
    Mission.requestID=self.queueid
  end

end

--- On after "MissionCancel" event. Cancels the missions of all flightgroups. Deletes request from warehouse queue.
-- @param #AIRWING self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.Auftrag#AUFTRAG Mission The mission to be cancelled.
function AIRWING:onafterMissionCancel(From, Event, To, Mission)
  
  -- Info message.
  self:I(self.lid..string.format("Cancel mission %s", Mission.name))
  
  local Ngroups = Mission:CountOpsGroups()
  
  if Mission:IsPlanned() or Mission:IsQueued() or Mission:IsRequested() or Ngroups == 0 then
  
    Mission:Done()
  
  else
  
    for _,_asset in pairs(Mission.assets) do
      local asset=_asset --#AIRWING.SquadronAsset
      
      local flightgroup=asset.flightgroup
      
      if flightgroup then
        flightgroup:MissionCancel(Mission)
      end
      
      -- Not requested any more (if it was).
      asset.requested=nil
    end
    
  end
  
  -- Remove queued request (if any).
  if Mission.requestID then
    self:_DeleteQueueItemByID(Mission.requestID, self.queue)
  end
  
end

--- On after "NewAsset" event. Asset is added to the given squadron (asset assignment).
-- @param #AIRWING self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #AIRWING.SquadronAsset asset The asset that has just been added.
-- @param #string assignment The (optional) assignment for the asset.
function AIRWING:onafterNewAsset(From, Event, To, asset, assignment)

  -- Call parent warehouse function first.
  self:GetParent(self).onafterNewAsset(self, From, Event, To, asset, assignment)
  
  -- Debug text.
  local text=string.format("New asset %s with assignment %s and request assignment %s", asset.spawngroupname, tostring(asset.assignment), tostring(assignment))
  self:T3(self.lid..text)
  
  -- Get squadron.
  local squad=self:GetSquadron(asset.assignment)

  -- Check if asset is already part of the squadron. If an asset returns, it will be added again! We check that asset.assignment is also assignment.
  if squad then

    if asset.assignment==assignment then
    
      local nunits=#asset.template.units
  
      -- Debug text.
      local text=string.format("Adding asset to squadron %s: assignment=%s, type=%s, attribute=%s, nunits=%d %s", squad.name, assignment, asset.unittype, asset.attribute, nunits, tostring(squad.ngrouping))
      self:T(self.lid..text)
      
      -- Adjust number of elements in the group.
      if squad.ngrouping then
        local template=asset.template
        
        local N=math.max(#template.units, squad.ngrouping)
  
        -- Handle units.
        for i=1,N do
      
          -- Unit template.
          local unit = template.units[i]
          
          -- If grouping is larger than units present, copy first unit. 
          if i>nunits then
            table.insert(template.units, UTILS.DeepCopy(template.units[1]))
          end
          
          -- Remove units if original template contains more than in grouping.
          if squad.ngrouping<nunits and i>nunits then
            unit=nil
          end
        end
      
        asset.nunits=squad.ngrouping
      end

      -- Create callsign and modex (needs to be after grouping).
      squad:GetCallsign(asset)
      squad:GetModex(asset)
      
      -- Set spawn group name. This has to include "AID-" for warehouse.
      asset.spawngroupname=string.format("%s_AID-%d", squad.name, asset.uid)

      -- Add asset to squadron.
      squad:AddAsset(asset)
            
      -- TODO
      --asset.terminalType=AIRBASE.TerminalType.OpenBig
    else
    
      --env.info("FF squad asset returned")
      self:SquadAssetReturned(squad, asset)
      
    end
        
  end
end

--- On after "AssetReturned" event. Triggered when an asset group returned to its airwing.
-- @param #AIRWING self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.Squadron#SQUADRON Squadron The asset squadron.
-- @param #AIRWING.SquadronAsset Asset The asset that returned.
function AIRWING:onafterSquadAssetReturned(From, Event, To, Squadron, Asset)
  -- Debug message.
  self:T(self.lid..string.format("Asset %s from squadron %s returned! asset.assignment=\"%s\"", Asset.spawngroupname, Squadron.name, tostring(Asset.assignment)))
  
  -- Stop flightgroup.
  if Asset.flightgroup and not Asset.flightgroup:IsStopped() then
    Asset.flightgroup:Stop()
  end
  
  -- Return payload.
  self:ReturnPayloadFromAsset(Asset)
  
  -- Return tacan channel.
  if Asset.tacan then
    Squadron:ReturnTacan(Asset.tacan)
  end
  
  -- Set timestamp.
  Asset.Treturned=timer.getAbsTime()
end


--- On after "AssetSpawned" event triggered when an asset group is spawned into the cruel world. 
-- Creates a new flightgroup element and adds the mission to the flightgroup queue.
-- @param #AIRWING self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Group#GROUP group The group spawned.
-- @param #AIRWING.SquadronAsset asset The asset that was spawned.
-- @param Functional.Warehouse#WAREHOUSE.Pendingitem request The request of the dead asset.
function AIRWING:onafterAssetSpawned(From, Event, To, group, asset, request)

  -- Call parent warehouse function first.
  self:GetParent(self).onafterAssetSpawned(self, From, Event, To, group, asset, request)

  -- Create a flight group.
  local flightgroup=self:_CreateFlightGroup(asset)
  
  
  ---
  -- Asset
  ---
  
  -- Set asset flightgroup.
  asset.flightgroup=flightgroup
  
  -- Not requested any more.
  asset.requested=nil
  
  -- Did not return yet.
  asset.Treturned=nil  

  ---
  -- Squadron
  ---
  
  -- Get the SQUADRON of the asset.
  local squadron=self:GetSquadronOfAsset(asset)
  
  -- Get TACAN channel.
  local Tacan=squadron:FetchTacan()
  if Tacan then
    asset.tacan=Tacan
  end
  
  -- Set radio frequency and modulation
  local radioFreq, radioModu=squadron:GetRadio()
  if radioFreq then
    flightgroup:SwitchRadio(radioFreq, radioModu)
  end
    
  if squadron.fuellow then
    flightgroup:SetFuelLowThreshold(squadron.fuellow)
  end
  
  if squadron.fuellowRefuel then
    flightgroup:SetFuelLowRefuel(squadron.fuellowRefuel)
  end  

  ---
  -- Mission
  ---
  
  -- Get Mission (if any).
  local mission=self:GetMissionByID(request.assignment)

  -- Add mission to flightgroup queue.
  if mission then
  
    if Tacan then
      mission:SetTACAN(Tacan, Morse, UnitName, Band)
    end
      
    -- Add mission to flightgroup queue.
    asset.flightgroup:AddMission(mission)
    
    -- Trigger event.
    self:FlightOnMission(flightgroup, mission)
    
  else
    
    if Tacan then
      flightgroup:SwitchTACAN(Tacan, Morse, UnitName, Band)    
    end
  
  end
  
    
  
  -- Add group to the detection set of the WINGCOMMANDER.
  if self.wingcommander and self.wingcommander.chief then
    self.wingcommander.chief.detectionset:AddGroup(asset.flightgroup.group)
  end
  
end

--- On after "AssetDead" event triggered when an asset group died.
-- @param #AIRWING self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #AIRWING.SquadronAsset asset The asset that is dead.
-- @param Functional.Warehouse#WAREHOUSE.Pendingitem request The request of the dead asset.
function AIRWING:onafterAssetDead(From, Event, To, asset, request)

  -- Call parent warehouse function first.
  self:GetParent(self).onafterAssetDead(self, From, Event, To, asset, request)

  -- Add group to the detection set of the WINGCOMMANDER.
  if self.wingcommander and self.wingcommander.chief then
    self.wingcommander.chief.detectionset:RemoveGroupsByName({asset.spawngroupname})
  end
  
  -- Remove asset from mission is done via Mission:AssetDead() call from flightgroup onafterFlightDead function
  -- Remove asset from squadron same
end

--- On after "Destroyed" event. Remove assets from squadrons. Stop squadrons. Remove airwing from wingcommander.
-- @param #AIRWING self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function AIRWING:onafterDestroyed(From, Event, To)

  self:I(self.lid.."Airwing warehouse destroyed!")

  -- Cancel all missions.
  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG
    mission:Cancel()
  end

  -- Remove all squadron assets.
  for _,_squadron in pairs(self.squadrons) do
    local squadron=_squadron --Ops.Squadron#SQUADRON
    -- Stop Squadron. This also removes all assets.
    squadron:Stop()
  end

  -- Call parent warehouse function first.
  self:GetParent(self).onafterDestroyed(self, From, Event, To)

end


--- On after "Request" event.
-- @param #AIRWING self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Functional.Warehouse#WAREHOUSE.Queueitem Request Information table of the request.
function AIRWING:onafterRequest(From, Event, To, Request)

  -- Assets
  local assets=Request.cargoassets
  
  -- Get Mission
  local Mission=self:GetMissionByID(Request.assignment)
  
  if Mission and assets then
  
    for _,_asset in pairs(assets) do
      local asset=_asset --#AIRWING.SquadronAsset      
      -- This would be the place to modify the asset table before the asset is spawned.
    end
    
  end

  -- Call parent warehouse function after assets have been adjusted.
  self:GetParent(self).onafterRequest(self, From, Event, To, Request)
  
end

--- On after "SelfRequest" event.
-- @param #AIRWING self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Set#SET_GROUP groupset The set of asset groups that was delivered to the warehouse itself.
-- @param Functional.Warehouse#WAREHOUSE.Pendingitem request Pending self request.
function AIRWING:onafterSelfRequest(From, Event, To, groupset, request)

  -- Call parent warehouse function first.
  self:GetParent(self).onafterSelfRequest(self, From, Event, To, groupset, request)

  -- Get Mission
  local mission=self:GetMissionByID(request.assignment)
  
  for _,_asset in pairs(request.assets) do
    local asset=_asset --#AIRWING.SquadronAsset
  end
    
  for _,_group in pairs(groupset:GetSet()) do
    local group=_group --Wrapper.Group#GROUP      
  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new flight group after an asset was spawned.
-- @param #AIRWING self
-- @param #AIRWING.SquadronAsset asset The asset.
-- @return Ops.FlightGroup#FLIGHTGROUP The created flightgroup object.
function AIRWING:_CreateFlightGroup(asset)

  -- Create flightgroup.
  local flightgroup=FLIGHTGROUP:New(asset.spawngroupname)

  -- Set airwing.
  flightgroup:SetAirwing(self)
  
  -- Set squadron.
  flightgroup.squadron=self:GetSquadronOfAsset(asset)

  -- Set home base.
  flightgroup.homebase=self.airbase
  
  --[[
  
  --- Check if out of missiles. For A2A missions ==> RTB.
  function flightgroup:OnAfterOutOfMissiles()  
    local airwing=flightgroup:GetAirWing()
    
  end
  
  --- Check if out of missiles. For A2G missions ==> RTB. But need to check A2G missiles, rockets as well.
  function flightgroup:OnAfterOutOfBombs()  
    local airwing=flightgroup:GetAirWing()
  
  end

  --- Mission started.
  function flightgroup:OnAfterMissionStart(From, Event, To, Mission)
    local airwing=flightgroup:GetAirWing()
  
  end
  
  --- Flight is DEAD.
  function flightgroup:OnAfterFlightDead(From, Event, To)  
    local airwing=flightgroup:GetAirWing()
        
  end
  
  ]]
  
  return flightgroup
end


--- Check if an asset is currently on a mission (STARTED or EXECUTING).
-- @param #AIRWING self
-- @param #AIRWING.SquadronAsset asset The asset.
-- @param #table MissionTypes Types on mission to be checked. Default all.
-- @return #boolean If true, asset has at least one mission of that type in the queue.
function AIRWING:IsAssetOnMission(asset, MissionTypes)

  if MissionTypes then
    if type(MissionTypes)~="table" then
      MissionTypes={MissionTypes}
    end
  else
    -- Check all possible types.
    MissionTypes=AUFTRAG.Type
  end

  if asset.flightgroup and asset.flightgroup:IsAlive() then
  
    -- Loop over mission queue.
    for _,_mission in pairs(asset.flightgroup.missionqueue or {}) do
      local mission=_mission --Ops.Auftrag#AUFTRAG
      
      if mission:IsNotOver() then
      
        -- Get flight status.
        local status=mission:GetGroupStatus(asset.flightgroup)
        
        -- Only if mission is started or executing.
        if (status==AUFTRAG.GroupStatus.STARTED or status==AUFTRAG.GroupStatus.EXECUTING) and self:CheckMissionType(mission.type, MissionTypes) then
          return true
        end
        
      end
      
    end
  
  end
  
  -- Alternative: run over all missions and compare to mission assets.
  --[[
  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG
    
    if mission:IsNotOver() then
      for _,_asset in pairs(mission.assets) do
        local sqasset=_asset --#AIRWING.SquadronAsset
        
        if sqasset.uid==asset.uid then
          return true
        end
        
      end
    end
    
  end
  ]]
  
  return false
end

--- Get the current mission of the asset.
-- @param #AIRWING self
-- @param #AIRWING.SquadronAsset asset The asset.
-- @return Ops.Auftrag#AUFTRAG Current mission or *nil*.
function AIRWING:GetAssetCurrentMission(asset)

  if asset.flightgroup then  
    return asset.flightgroup:GetMissionCurrent()  
  end

  return nil
end

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
      local compatible=self:CheckMissionCapability(MissionType, payload.capabilities)
      
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

--- Count missions in mission queue.
-- @param #AIRWING self
-- @param #table MissionTypes Types on mission to be checked. Default *all* possible types `AUFTRAG.Type`.
-- @return #number Number of missions that are not over yet.
function AIRWING:CountMissionsInQueue(MissionTypes)

  MissionTypes=MissionTypes or AUFTRAG.Type

  local N=0
  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG
    
    -- Check if this mission type is requested.
    if mission:IsNotOver() and self:CheckMissionType(mission.type, MissionTypes) then
      N=N+1
    end
    
  end

  return N
end

--- Count total number of assets. This is the sum of all squadron assets.
-- @param #AIRWING self
-- @return #number Amount of asset groups.
function AIRWING:CountAssets()

  local N=0
  
  for _,_squad in pairs(self.squadrons) do
    local squad=_squad --Ops.Squadron#SQUADRON
    N=N+#squad.assets
  end

  return N
end

--- Count assets on mission.
-- @param #AIRWING self
-- @param #table MissionTypes Types on mission to be checked. Default all.
-- @param Ops.Squadron#SQUADRON Squadron Only count assets of this squadron. Default count assets of all squadrons.
-- @return #number Number of pending and queued assets.
-- @return #number Number of pending assets.
-- @return #number Number of queued assets.
function AIRWING:CountAssetsOnMission(MissionTypes, Squadron)
  
  local Nq=0
  local Np=0

  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG
    
    -- Check if this mission type is requested.
    if self:CheckMissionType(mission.type, MissionTypes or AUFTRAG.Type) then
    
      for _,_asset in pairs(mission.assets or {}) do
        local asset=_asset --#AIRWING.SquadronAsset
        
        if Squadron==nil or Squadron.name==asset.squadname then
        
          local request, isqueued=self:GetRequestByID(mission.requestID)
          
          if isqueued then
            Nq=Nq+1
          else
            Np=Np+1
          end
          
        end
        
      end      
    end
  end

  --env.info(string.format("FF N=%d Np=%d, Nq=%d", Np+Nq, Np, Nq))
  return Np+Nq, Np, Nq
end

--- Count assets on mission.
-- @param #AIRWING self
-- @param #table MissionTypes Types on mission to be checked. Default all.
-- @return #table Assets on pending requests.
function AIRWING:GetAssetsOnMission(MissionTypes)
  
  local assets={}
  local Np=0

  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG
    
    -- Check if this mission type is requested.
    if self:CheckMissionType(mission.type, MissionTypes) then
    
      for _,_asset in pairs(mission.assets or {}) do
        local asset=_asset --#AIRWING.SquadronAsset

        table.insert(assets, asset)        
        
      end      
    end
  end

  return assets
end

--- Get the aircraft types of this airwing.
-- @param #AIRWING self
-- @param #boolean onlyactive Count only the active ones.
-- @param #table squadrons Table of squadrons. Default all.
-- @return #table Table of unit types.
function AIRWING:GetAircraftTypes(onlyactive, squadrons)

  -- Get all unit types that can do the job.
  local unittypes={}
  
  -- Loop over all squadrons.
  for _,_squadron in pairs(squadrons or self.squadrons) do
    local squadron=_squadron --Ops.Squadron#SQUADRON
    
    if (not onlyactive) or squadron:IsOnDuty() then 
    
      local gotit=false
      for _,unittype in pairs(unittypes) do
        if squadron.aircrafttype==unittype then
          gotit=true
          break
        end
      end
      if not gotit then
        table.insert(unittypes, squadron.aircrafttype)
      end
      
    end
  end  

  return unittypes
end

--- Check if assets for a given mission type are available.
-- @param #AIRWING self
-- @param Ops.Auftrag#AUFTRAG Mission The mission.
-- @return #boolean If true, enough assets are available.
-- @return #table Assets that can do the required mission.
function AIRWING:CanMission(Mission)

  -- Assume we CAN and NO assets are available.
  local Can=true
  local Assets={}
  
  -- Squadrons for the job. If user assigned to mission or simply all.
  local squadrons=Mission.squadrons or self.squadrons

  -- Get aircraft unit types for the job.
  local unittypes=self:GetAircraftTypes(true, squadrons)
  
  -- Count all payloads in stock.
  local Npayloads=self:CountPayloadsInStock(Mission.type, unittypes, Mission.payloads)
  
  if Npayloads<Mission.nassets then
    self:T(self.lid..string.format("INFO: Not enough PAYLOADS available! Got %d but need at least %d", Npayloads, Mission.nassets))
    return false, Assets
  end

  for squadname,_squadron in pairs(squadrons) do
    local squadron=_squadron --Ops.Squadron#SQUADRON

    -- Check if this squadron can.
    local can=squadron:CanMission(Mission)
    
    if can then
    
      -- Number of payloads available.
      local Npayloads=self:CountPayloadsInStock(Mission.type, squadron.aircrafttype, Mission.payloads)
      
      local assets=squadron:RecruitAssets(Mission, Npayloads)    
          
      -- Total number.
      for _,asset in pairs(assets) do
        table.insert(Assets, asset)
      end
      
      -- Debug output.
      local text=string.format("Mission=%s, squadron=%s, payloads=%d, can=%s, assets=%d. Found %d/%d", Mission.type, squadron.name, Npayloads, tostring(can), #assets, #Assets, Mission.nassets)
      self:T(self.lid..text)
      
    end

  end

  -- Check if required assets are present.
  if Mission.nassets and Mission.nassets > #Assets then
    self:T(self.lid..string.format("INFO: Not enough assets available! Got %d but need at least %d", #Assets, Mission.nassets))
    Can=false
  end
  
  return Can, Assets
end

--- Check if assets for a given mission type are available.
-- @param #AIRWING self
-- @param Ops.Auftrag#AUFTRAG Mission The mission.
-- @return #table Assets that can do the required mission.
function AIRWING:RecruitAssets(Mission)

end


--- Check if a mission type is contained in a list of possible types.
-- @param #AIRWING self
-- @param #string MissionType The requested mission type.
-- @param #table PossibleTypes A table with possible mission types.
-- @return #boolean If true, the requested mission type is part of the possible mission types.
function AIRWING:CheckMissionType(MissionType, PossibleTypes)

  if type(PossibleTypes)=="string" then
    PossibleTypes={PossibleTypes}
  end

  for _,canmission in pairs(PossibleTypes) do
    if canmission==MissionType then
      return true
    end   
  end

  return false
end

--- Check if a mission type is contained in a list of possible capabilities.
-- @param #AIRWING self
-- @param #string MissionType The requested mission type.
-- @param #table Capabilities A table with possible capabilities.
-- @return #boolean If true, the requested mission type is part of the possible mission types.
function AIRWING:CheckMissionCapability(MissionType, Capabilities)

  for _,cap in pairs(Capabilities) do
    local capability=cap --Ops.Auftrag#AUFTRAG.Capability
    if capability.MissionType==MissionType then
      return true
    end   
  end

  return false
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

--- Returns the mission for a given mission ID (Autragsnummer).
-- @param #AIRWING self
-- @param #number mid Mission ID (Auftragsnummer).
-- @return Ops.Auftrag#AUFTRAG Mission table.
function AIRWING:GetMissionByID(mid)

  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG
    
    if mission.auftragsnummer==tonumber(mid) then
      return mission
    end
    
  end
  
  return nil
end

--- Returns the mission for a given request ID.
-- @param #AIRWING self
-- @param #number RequestID Unique ID of the request.
-- @return Ops.Auftrag#AUFTRAG Mission table or *nil*.
function AIRWING:GetMissionFromRequestID(RequestID)
  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG
    if mission.requestID and mission.requestID==RequestID then
      return mission
    end
  end
  return nil
end

--- Returns the mission for a given request.
-- @param #AIRWING self
-- @param Functional.Warehouse#WAREHOUSE.Queueitem Request The warehouse request.
-- @return Ops.Auftrag#AUFTRAG Mission table or *nil*.
function AIRWING:GetMissionFromRequest(Request)
  return self:GetMissionFromRequestID(Request.uid)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
