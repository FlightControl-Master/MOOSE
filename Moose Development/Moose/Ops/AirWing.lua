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
-- @field #boolean Debug Debug mode. Messages to all about status.
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
-- ![Banner Image](..\Presentations\CarrierAirWing\AIRWING_Main.jpg)
--
-- # The AIRWING Concept
--
--
--
-- @field #AIRWING
AIRWING = {
  ClassName      = "AIRWING",
  Debug          = false,
  verbose        =     0,
  lid            =   nil,
  menu           =   nil,
  squadrons      =    {},
  missionqueue   =    {},
  payloads       =    {},
  pointsCAP      =    {},
  pointsTANKER   =    {},
  pointsAWACS    =    {},
  wingcommander  =   nil,
}

--- Squadron asset.
-- @type AIRWING.SquadronAsset
-- @field #AIRWING.Payload payload The payload of the asset.
-- @field Ops.FlightGroup#FLIGHTGROUP flightgroup The flightgroup object.
-- @field #string squadname Name of the squadron this asset belongs to.
-- @extends Functional.Warehouse#WAREHOUSE.Assetitem

--- Payload data.
-- @type AIRWING.Payload
-- @field #string unitname Name of the unit this pylon was extracted from.
-- @field #string aircrafttype Type of aircraft, which can use this payload.
-- @field #table capabilities Mission types and performances for which this payload can be used.
-- @field #table pylons Pylon data extracted for the unit template.
-- @field #number navail Number of available payloads of this type.
-- @field #boolean unlimited If true, this payload is unlimited and does not get consumed.

--- Patrol data.
-- @type AIRWING.PatrolData
-- @field Core.Point#COORDINATE coord Patrol coordinate.
-- @field #number heading Heading in degrees.
-- @field #number leg Leg length in NM.
-- @field #number speed Speed in knots.
-- @field #number noccupied Number of flights on this patrol point.

--- AIRWING class version.
-- @field #string version
AIRWING.version="0.1.7"

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
  --                 From State  -->   Event      -->     To State
  self:AddTransition("*",             "MissionRequest",   "*")           -- Add a (mission) request to the warehouse.
  self:AddTransition("*",             "MissionCancel",    "*")           -- Cancel mission.

  -- Defaults:
  self.nflightsCAP=0
  self.nflightsAWACS=0
  self.nflightsTANKERboom=0
  self.nflightsTANKERprobe=0
  self.nflightsRecoveryTanker=0
  self.nflightsRescueHelo=0

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


  -- Debug trace.
  if false then
    self.Debug=true
    self:TraceOnOff(true)
    self:TraceClass(self.ClassName)
    self:TraceLevel(1)
  end

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
    Unit=UNIT:FindByName(Unit)
    if not Unit then
      Unit=GROUP:FindByName(Unit)
    end
  end

  -- If a GROUP object was given, get the first unit.
  if Unit:IsInstanceOf("GROUP") then
    Unit=Unit:GetUnit(1)
  end

  -- Ensure Missiontypes is a table.
  if MissionTypes and type(MissionTypes)~="table" then
    MissionTypes={MissionTypes}
  end
  
  if Unit then
    
    local payload={} --#AIRWING.Payload
    
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
    self:I(self.lid..string.format("Adding new payload from unit %s for aircraft type %s: N=%d (unlimited=%s), performance=%d, missions: %s", 
    payload.unitname, payload.aircrafttype, payload.navail, tostring(payload.unlimited), Performance, table.concat(MissionTypes, ", ")))

    -- Add payload
    table.insert(self.payloads, payload)
    
    return payload
  end

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
-- @return #AIRWING.Payload Payload table or *nil*.
function AIRWING:FetchPayloadFromStock(UnitType, MissionType)

  if not self.payloads or #self.payloads==0 then
    self:I(self.lid.."WARNING: No payloads in stock!")
    return nil
  end
  
  --[[
  for i,_payload in pairs(self.payloads) do
    local payload=_payload --#AIRWING.Payload
    self:I(self.lid..string.format("%d Payload type=%s navail=%d", i, payload.aircrafttype, payload.navail))
  end
  ]]

  --- Sort payload wrt the following criteria:
  -- 1) Highest performance is the main selection criterion.
  -- 2) If payloads have the same performance, unlimited payloads are preferred over limited ones. 
  -- 3) If payloads have the same performance _and_ are limited, the more abundant one is preferred.
  local function sortpayloads(a,b)
    local pA=a --#AIRWING.Payload
    local pB=b --#AIRWING.Payload
    if a and b then  --TODO: Strangely, I had the case that a or b were nil even though the self.payloads table was looking okay. Very strange!
      local performanceA=self:GetPayloadPeformance(a, MissionType)
      local performanceB=self:GetPayloadPeformance(b, MissionType)
      return (performanceA>performanceB) or (performanceA==performanceB and a.unlimited==true) or (performanceA==performanceB and a.unlimited==true and b.unlimited==true and a.navail>b.navail)
    elseif not a then
      return false
    elseif not b then
      return true
    else
      return true
    end
  end  
  table.sort(self.payloads, sortpayloads)

  if self.Debug then
    env.info("FF Sorted payloads for mission type X and aircraft type=Y:")
    for _,_payload in ipairs(self.payloads) do
      local payload=_payload --#AIRWING.Payload
      if payload.aircrafttype==UnitType and self:CheckMissionCapability(MissionType, payload.capabilities) then
        local performace=self:GetPayloadPeformance(payload, MissionType)
        self:I(string.format("FF %s payload for %s: avail=%d performace=%d", MissionType, payload.aircrafttype, payload.navail, performace))
      end
    end
  end
  
  for _,_payload in ipairs(self.payloads) do
    local payload=_payload --#AIRWING.Payload
    
    
    -- Check right type, mission and available.
    if payload.aircrafttype==UnitType and payload.navail>0 and self:CheckMissionCapability(MissionType, payload.capabilities) then
    
      -- Consume if not unlimited.
      if not payload.unlimited then
        payload.navail=payload.navail-1
      end
      
      self:T(string.format("FETCHING %s payload for %s: avail=%d performance=%d", MissionType, payload.aircrafttype, payload.navail, self:GetPayloadPeformance(payload, MissionType)))
      
      -- Return a copy of the table.
      return payload
    end
    
  end
  
  self:T(self.lid.."Warning could not find a payload for airframe X mission type Y!")
  return nil
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

--- Get squadron of an asset.
-- @param #AIRWING self
-- @param #AIRWING.SquadronAsset Asset The squadron asset.
-- @return Ops.Squadron#SQUADRON The squadron object.
function AIRWING:GetSquadronOfAsset(Asset)
  return self:GetSquadron(Asset.squadname)
end

--- Remove asset from squadron.
-- @param #AIRWING self
-- @param #AIRWING.SquadronAsset Asset
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
  self:I(self.lid..text)
  
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

--- Set number of TANKER flights constantly in the air.
-- @param #AIRWING self
-- @param #number Nboom Number of flights. Default 1.
-- @param #number Nprobe Number of flights. Default 1.
-- @return #AIRWING self
function AIRWING:SetNumberTANKER(Nboom, Nprobe)
  self.nflightsTANKERboom=Nboom or 1
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


--- Create a new generic patrol point.
-- @param #AIRWING self
-- @param Core.Point#COORDINATE Coordinate Coordinate of the patrol point. Default 10-15 NM away from the location of the airwing.
-- @param #number Heading Heading in degrees. Default random (0, 360] degrees.
-- @param #number LegLength Length of race-track orbit in NM. Default 15 NM.
-- @param #number Altitude Orbit altitude in feet. Default random between Angels 10 and 20.
-- @param #number Speed Orbit speed in knots. Default 350 knots.
-- @return #AIRWING.PatrolData Patrol point table.
function AIRWING:NewPatrolPoint(Coordinate, Heading, LegLength, Altitude, Speed)

  local cappoint={}  --#AIRWING.PatrolData
  cappoint.coord=Coordinate or self:GetCoordinate():Translate(UTILS.NMToMeters(math.random(10, 15)), math.random(360))
  cappoint.heading=Heading or math.random(360)
  cappoint.leg=LegLength or 15
  cappoint.altitude=Altitude or math.random(10,20)*1000
  cappoint.speed=Speed or 350
  cappoint.noccupied=0

  return cappoint
end

--- Add a patrol Point for CAP missions.
-- @param #AIRWING self
-- @param Core.Point#COORDINATE Coordinate Coordinate of the patrol point.
-- @param #number Heading Heading in degrees.
-- @param #number LegLength Length of race-track orbit in NM.
-- @param #number Altitude Orbit altitude in feet.
-- @param #number Speed Orbit speed in knots.
-- @return #AIRWING self
function AIRWING:AddPatrolPointCAP(Coordinate, Heading, LegLength, Altitude, Speed)
  
  local cappoint=self:NewPatrolPoint(Coordinate, Heading, LegLength, Altitude, Speed)
  
  cappoint.coord:MarkToAll(string.format("CAP Point alt=%d", cappoint.altitude))

  table.insert(self.pointsCAP, cappoint)

  return self
end

--- Add a patrol Point for TANKER missions.
-- @param #AIRWING self
-- @param Core.Point#COORDINATE Coordinate Coordinate of the patrol point.
-- @param #number Heading Heading in degrees.
-- @param #number LegLength Length of race-track orbit in NM.
-- @param #number Altitude Orbit altitude in feet.
-- @param #number Speed Orbit speed in knots.
-- @return #AIRWING self
function AIRWING:AddPatrolPointTANKER(Coordinate, Heading, LegLength, Altitude, Speed)
  
  local cappoint=self:NewPatrolPoint(Coordinate, Heading, LegLength, Altitude, Speed)
  
  cappoint.coord:MarkToAll(string.format("Tanker Point alt=%d", cappoint.altitude))

  table.insert(self.pointsTANKER, cappoint)

  return self
end

--- Add a patrol Point for AWACS missions.
-- @param #AIRWING self
-- @param Core.Point#COORDINATE Coordinate Coordinate of the patrol point.
-- @param #number Heading Heading in degrees.
-- @param #number LegLength Length of race-track orbit in NM.
-- @param #number Altitude Orbit altitude in feet.
-- @param #number Speed Orbit speed in knots.
-- @return #AIRWING self
function AIRWING:AddPatrolPointAWACS(Coordinate, Heading, LegLength, Altitude, Speed)
  
  local cappoint=self:NewPatrolPoint(Coordinate, Heading, LegLength, Altitude, Speed)
  
  cappoint.coord:MarkToAll(string.format("AWACS Point alt=%d", cappoint.altitude))

  table.insert(self.pointsAWACS, cappoint)

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

  -- Menu.
  if false then

    -- Add F10 radio menu.
    self:_SetMenuCoalition()
  
    for _,_squadron in pairs(self.squadrons) do
      local squadron=_squadron --Ops.Squadron#SQUADRON
      self:_AddSquadonMenu(squadron)
    end
    
  end

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
  
  -- Count missions not over yet.
  local nmissions=self:CountMissionsInQueue()
  
  -- Count ALL payloads in stock. If any payload is unlimited, this gives 999.
  local Npayloads=self:CountPayloadsInStock(AUFTRAG.Type)
  
  -- General info:
  -- TODO: assets total
  local text=string.format("Status %s: missions=%d, payloads=%d (%d), squads=%d", fsmstate, nmissions, #self.payloads, Npayloads, #self.squadrons)
  self:I(self.lid..text)
  
  ------------------
  -- Mission Info --
  ------------------
  local text=string.format("Missions Total=%d:", #self.missionqueue)
  for i,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG
    text=text..string.format("\n[%d] %s: Status=%s, Nassets=%d, Prio=%d, ID=%d (%s)", i, mission.type, mission.status, mission.nassets, mission.prio, mission.auftragsnummer, mission.name)
  end
  self:I(self.lid..text)

  -------------------
  -- Squadron Info --
  -------------------
  local text="Squadrons:"
  for i,_squadron in pairs(self.squadrons) do
    local squadron=_squadron --Ops.Squadron#SQUADRON
    
    local callsign=squadron.callsignName and UTILS.GetCallsignName(squadron.callsignName) or "N/A"
    local modex=squadron.modex and squadron.modex or -1
    local skill=squadron.skill and tostring(squadron.skill) or "N/A"
    
    -- Squadron text
    text=text..string.format("\n* %s %s: %s*%d, Callsign=%s, Modex=%d, Skill=%s", squadron.name, squadron:GetState(), squadron.aircrafttype, #squadron.assets, callsign, modex, skill)
    
    -- Loop over all assets.
    if self.verbose>1 then
      for j,_asset in pairs(squadron.assets) do
        local asset=_asset --#AIRWING.SquadronAsset
        local assignment=asset.assignment or "none"
        local name=asset.templatename
        local spawned=tostring(asset.spawned)
        local groupname=asset.spawngroupname
        local typename=asset.unittype
        
        local mission=self:GetAssetCurrentMission(asset)
        local missiontext=""
        if mission then
          local distance=asset.flightgroup and UTILS.MetersToNM(mission:GetTargetDistance(asset.flightgroup.group:GetCoordinate())) or 0
          missiontext=string.format(" [%s (%s): status=%s, distance=%.1f NM]", mission.type, mission.name, mission.status, distance)
        end
              
        text=text..string.format("\n  -[%d] %s*%d \"%s\": spawned=%s, mission=%s%s", j, typename, asset.nunits, asset.spawngroupname, spawned, tostring(self:IsAssetOnMission(asset)), missiontext)
        
        --TODO
        --local payload=asset.payload and table.concat(asset.payload.missiontypes, ", ") or "None"
        --text=text.." payload="..payload
        
        text=text..", flight: "
        if asset.flightgroup and asset.flightgroup:IsAlive() then
          local status=asset.flightgroup:GetState()
          local fuelmin=asset.flightgroup:GetFuelMin()
          local fuellow=asset.flightgroup:IsFuelLow()
          local fuelcri=asset.flightgroup:IsFuelCritical()
          
          text=text..string.format("%s fuel=%d", status, fuelmin)
          if fuelcri then
            text=text.." (critical!)"
          elseif fuellow then
            text=text.." (low)"
          end
          
          local lifept, lifept0=asset.flightgroup:GetLifePoints()
          text=text..string.format(" life=%d/%d", lifept, lifept0)
        else
          text=text.."N/A"
        end
      end
      
    end
  end
  self:I(self.lid..text)
   
  --------------
  -- Mission ---
  --------------
  
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

  local Ncap=self:CountMissionsInQueue({AUFTRAG.Type.PATROL, AUFTRAG.Type.INTERCEPT})
  
  for i=1,self.nflightsCAP-Ncap do
  
    local patrol=self:_GetPatrolData(self.pointsCAP)
    
    local missionCAP=AUFTRAG:NewPATROL(patrol.coord, patrol.speed, patrol.heading, patrol.leg, patrol.altitude)
    
    missionCAP.patroldata=patrol
    
    patrol.noccupied=patrol.noccupied+1
    
    self:AddMission(missionCAP)
      
  end
  
  return self
end

--- Check how many TANKER missions are assigned and add number of missing missions.
-- @param #AIRWING self
-- @return #AIRWING self
function AIRWING:CheckTANKER()

  --local N=self:CountMissionsInQueue({AUFTRAG.Type.TANKER})
  --local N=self:CountAssetsOnMission({AUFTRAG.Type.TANKER})
  
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
    
    patrol.coord:MarkToAll("Patrol point boom")
    
    local mission=AUFTRAG:NewTANKER(patrol.coord, patrol.speed, patrol.heading, patrol.leg, patrol.altitude, 0)
    
    mission.patroldata=patrol
    
    patrol.noccupied=patrol.noccupied+1
    
    self:AddMission(mission)
      
  end
  
  for i=1,self.nflightsTANKERprobe-Nprob do
  
    local patrol=self:_GetPatrolData(self.pointsTANKER)
    
    patrol.coord:MarkToAll("Patrol point probe")
    
    local mission=AUFTRAG:NewTANKER(patrol.coord, patrol.speed, patrol.heading, patrol.leg, patrol.altitude, 1)
    
    mission.patroldata=patrol
    
    patrol.noccupied=patrol.noccupied+1
    
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
    
    local mission=AUFTRAG:NewAWACS(patrol.coord, patrol.speed, patrol.heading, patrol.leg, patrol.altitude)
    
    mission.patroldata=patrol
    
    patrol.noccupied=patrol.noccupied+1
    
    self:AddMission(mission)
      
  end
  
  return self
end

--- Check how many Rescue helos are currently in the air.
-- @param #AIRWING self
-- @return #AIRWING self
function AIRWING:CheckRescuhelo()

  local N=self:CountMissionsInQueue({AUFTRAG.Type.RESCUEHELO})
  
  local carrier=UNIT:FindByName(self.airbase:GetName())
  
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
        
        table.insert(tankeropt, {tanker=tanker, dist=dist})
      end
    end
    
    -- Sort tankers wrt to distance.
    table.sort(tankeropt, function(a,b) return a.dist<b.dist end)
    
    -- Return tanker asset.
    return tankeropt[1].tanker
  end

  return nil
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
  
  -- Current time.
  local time=timer.getAbsTime()

  -- Look for first task that is not accomplished.
  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG
    
    -- Firstly, check if mission is due?
    if mission:IsQueued() and time>=mission.Tstart then
        
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
            local payload=self:FetchPayloadFromStock(asset.unittype, mission.type)
            if payload then
              asset.payload=payload
              table.insert(gotpayload, asset.uid)
            else
              table.insert(remove, asset.uid)
            end
          end
        end        
        self:I(self.lid..string.format("Provided %d assets with payloads. Could not get payload for %d assets", #gotpayload, #remove))
        
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
          self:E(self.lid..string.format("ERROR: Not enought payloads for mission assets! Can only do %d/%d", #assets, mission.nassets))
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

--- Calcuate the mission score of an asset.
-- @param #AIRWING self
-- @param #AIRWING.SquadronAsset asset Asset
-- @param Ops.Auftrag#AUFTRAG Mission Mission for which the best assets are desired.
-- @param #boolean includePayload If true, include the payload in the calulation if the asset has one attached.
-- @return #number Mission score.
function AIRWING:CalculateAssetMissionScore(asset, Mission, includePayload)

  local score=0
  
  -- Prefer highly skilled assets.
  if asset.skill==AI.Skill.GOOD then
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

  local TargetCoordinate=Mission:GetTargetCoordinate()

  local dStock=self:GetCoordinate():Get2DDistance(TargetCoordinate)
  
  -- Calculate distance to mission target.
  local distmin=math.huge
  local distmax=0
  for _,_asset in pairs(assets) do
    local asset=_asset --#AIRWING.SquadronAsset
    
    if asset.spawned then
      local group=GROUP:FindByName(asset.spawngroupname)
      asset.dist=group:GetCoordinate():Get2DDistance(TargetCoordinate)
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
  local text=string.format("Optimized assets for mission (payload=%s):", tostring(includePayload))
  for i,Asset in pairs(assets) do
    local asset=Asset --#AIRWING.SquadronAsset
    text=text..string.format("\n%s %s: score=%d, distance=%.1f km", asset.squadname, asset.spawngroupname, asset.score, asset.dist/1000)
    asset.dist=nil
    asset.score=nil
  end
  self:I(self.lid..text)

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

  -- Assets to be requested
  local Assetlist={}
  
  for _,_asset in pairs(Mission.assets) do
    local asset=_asset --#AIRWING.SquadronAsset
    
    if asset.spawned then
    
      if asset.flightgroup then

        -- Add new mission.
        asset.flightgroup:AddMission(Mission)
        
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
  
  self:I(self.lid..string.format("Cancel mission %s", Mission.name))
  
  if Mission:IsPlanned() or Mission:IsQueued() or Mission:IsRequested() then
  
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
-- @param Functional.Warehouse#WAREHOUSE.Assetitem asset The asset that has just been added.
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
  
      -- Debug text.
      local text=string.format("Adding asset to squadron %s: assignment=%s, type=%s, attribute=%s", squad.name, assignment, asset.unittype, asset.attribute)
      self:I(self.lid..text)
      
      -- Create callsign and modex.
      squad:GetCallsign(asset)
      squad:GetModex(asset)

      -- Add asset to squadron.
      squad:AddAsset(asset)
            
      --asset.terminalType=AIRBASE.TerminalType.OpenBig      
    else
    
      self:I(self.lid..string.format("Asset %s from squadron %s returned! asset.assignment=\"%s\", assignment=\"%s\"", asset.spawngroupname, squad.name, tostring(asset.assignment), tostring(assignment)))
      self:ReturnPayloadFromAsset(asset)
    
    end
        
  end
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
  
  -- Set RTB on fuel critical.
  flightgroup:SetFuelCriticalThreshold(nil, true)
  
  -- Set airwing.
  flightgroup:SetAirwing(self)
  
  -- Set asset flightgroup.
  asset.flightgroup=flightgroup
  
  local squadron=self:GetSquadronOfAsset(asset)
  local Tacan=squadron:GetTACAN()
  if Tacan then
    flightgroup:SetTACAN(Tacan)
  end
  
  -- Not requested any more.
  asset.requested=nil
  
  -- Get Mission (if any).
  local mission=self:GetMissionByID(request.assignment)  

  -- Add mission to flightgroup queue.
  if mission then
  
    -- RTB on low fuel if on PATROL.
    if mission.type==AUFTRAG.Type.PATROL then
      flightgroup:SetFuelLowThreshold(nil, true)    
    end
      
    -- Add mission to flightgroup queue.
    asset.flightgroup:AddMission(mission)
  end
  
  -- Add group to the detection set of the WINGCOMMANDER.
  if self.wingcommander then
    self.wingcommander.detectionset:AddGroup(asset.flightgroup.group)
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
  if self.wingcommander then
    self.wingcommander.detectionset:RemoveGroupsByName({asset.spawngroupname})
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
        local status=mission:GetFlightStatus(asset.flightgroup)
        
        -- Only if mission is started or executing.
        if (status==AUFTRAG.FlightStatus.STARTED or status==AUFTRAG.FlightStatus.EXECUTING) and self:CheckMissionType(mission.type, MissionTypes) then
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
-- @return #number Count of available payloads in stock.
function AIRWING:CountPayloadsInStock(MissionTypes, UnitTypes)

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

  local n=0
  for _,_payload in pairs(self.payloads) do
    local payload=_payload --#AIRWING.Payload
    
    if self:CheckMissionCapability(MissionTypes, payload.capabilities) and _checkUnitTypes(payload) then
    
      if payload.unlimited then
        -- Payload is unlimited. Return a BIG number.
        return 999
      else
        n=n+payload.navail
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

--- Count assets on mission.
-- @param #AIRWING self
-- @param #table MissionTypes Types on mission to be checked. Default all.
-- @return #number Number of pending and queued assets.
-- @return #number Number of pending assets.
-- @return #number Number of queued assets.
function AIRWING:CountAssetsOnMission(MissionTypes)
  
  local Nq=0
  local Np=0

  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG
    
    -- Check if this mission type is requested.
    if self:CheckMissionType(mission.type, MissionTypes) then
    
      for _,_asset in pairs(mission.assets or {}) do
        local asset=_asset --#AIRWING.SquadronAsset
        
        local request, isqueued=self:GetRequestByID(mission.requestID)
        
        if isqueued then
          Nq=Nq+1
        else
          Np=Np+1
        end
        
      end      
    end
  end

  return Np+Nq, Np, Nq
end

--- Count assets on mission.
-- @param #AIRWING self
-- @param #table MissionTypes Types on mission to be checked. Default all.
-- @return #table Assets on pending requests.
function AIRWING:GetAssetsOnMission(MissionTypes, IncludeQueued)
  
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
-- @return #boolean onlyactive Count only the active ones.
-- @return #table Table of unit types.
function AIRWING:GetAircraftTypes(onlyactive)

  -- Get all unit types that can do the job.
  local unittypes={}
  
  -- Loop over all squadrons.
  for squadname,_squadron in pairs(self.squadrons) do
    local squadron=_squadron --Ops.Squadron#SQUADRON
    
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

  local unittypes=self:GetAircraftTypes(true)
  
  local Npayloads=self:CountPayloadsInStock(Mission.type, unittypes)
  
  if Npayloads<Mission.nassets then
    self:I(self.lid..string.format("INFO: Not enough PAYLOADS available! Got %d but need at least %d", Npayloads, Mission.nassets))
    return false, Assets
  end

  for squadname,_squadron in pairs(self.squadrons) do
    local squadron=_squadron --Ops.Squadron#SQUADRON

    -- Check if this squadron can.
    local can=squadron:CanMission(Mission)
    
    if can then
    
      -- Number of payloads available.
      local Npayloads=self:CountPayloadsInStock(Mission.type, squadron.aircrafttype)
      
      local assets=squadron:RecruitAssets(Mission, Npayloads)    
          
      -- Total number.
      for _,asset in pairs(assets) do
        table.insert(Assets, asset)
      end
      
      -- Debug output.
      local text=string.format("Mission=%s, squadron=%s, payloads=%d, can=%s, assets=%d. Found %d/%d", Mission.type, squadron.name, Npayloads, tostring(can), #assets, #Assets, Mission.nassets)
      self:I(self.lid..text)
      
    end

  end

  -- Payloads are not fetched from stock any more.
  --[[
  -- Now clear all reserved payloads.
  for _,_asset in pairs(Assets) do
    local asset=_asset --#AIRWING.SquadronAsset
    -- Only unspawned payloads are returned.
    if not asset.spawned and not asset.requested then
      self:ReturnPayloadFromAsset(asset)
    end
  end
  ]]

  -- Check if required assets are present.
  if Mission.nassets and Mission.nassets > #Assets then
    self:I(self.lid..string.format("INFO: Not enough assets available! Got %d but need at least %d", #Assets, Mission.nassets))
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
-- @param #string MissionType Type of mission.
-- @return #number Performance or -1.
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
-- Menu Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Patrol carrier.
-- @param #AIRWING self
-- @return #AIRWING self
function AIRWING:_SetMenuCoalition()

  -- Get coalition.
  local Coalition=self:GetCoalition()

  -- Init menu table.
  self.menu=self.menu or {}

  -- Init menu coalition table.
  self.menu[Coalition]=self.menu[Coalition] or {}

  -- Shortcut.
  local menu=self.menu[Coalition]

  if self.menusingle then
    -- F10/Skipper/...
    if not menu.AIRWING then
      menu.AIRWING=MENU_COALITION:New(Coalition, "AIRWING")
    end
  else
    -- F10/Skipper/<Carrier Alias>/...
    if not menu.Root then
      menu.Root=MENU_COALITION:New(Coalition, "AIRWING")
    end
    menu.AIRWING=MENU_COALITION:New(Coalition, self.alias, menu.Root)
  end

  -------------------
  -- Squadron Menu --
  -------------------

  menu.Squadron={}
  menu.Squadron.Main= MENU_COALITION:New(Coalition, "Squadrons", menu.AIRWING)

  menu.Warehouse={}
  menu.Warehouse.Main    = MENU_COALITION:New(Coalition, "Warehouse", menu.AIRWING)
  menu.Warehouse.Reports = MENU_COALITION_COMMAND:New(Coalition, "Reports On/Off", menu.Warehouse.Main, self.WarehouseReportsToggle, self)
  menu.Warehouse.Assets  = MENU_COALITION_COMMAND:New(Coalition, "Report Assets",  menu.Warehouse.Main, self.ReportWarehouseStock, self)
  
  menu.ReportSquadrons = MENU_COALITION_COMMAND:New(Coalition, "Report Squadrons",  menu.AIRWING, self.ReportSquadrons, self)

end

--- Report squadron status.
-- @param #AIRWING self
function AIRWING:ReportSquadrons()

  local text="Squadron Report:"
  
  for i,_squadron in pairs(self.squadrons) do
    local squadron=_squadron
    
    local name=squadron.name
    
    local nspawned=0
    local nstock=0
    for _,_asset in pairs(squadron.assets) do
      local asset=_asset --Functional.Warehouse#WAREHOUSE.Assetitem
      
      local n=asset.nunits
      
      if asset.spawned then
        nspawned=nspawned+n
      else
        nstock=nstock+n
      end
      
    end
    
    text=string.format("\n%s: AC on duty=%d, in stock=%d", name, nspawned, nstock)
    
  end
  
  self:I(self.lid..text)
  MESSAGE:New(text, 10, "AIRWING", true):ToCoalition(self:GetCoalition())

end


--- Add sub menu for this intruder.
-- @param #AIRWING self
-- @param Ops.Squadron#SQUADRON squadron The squadron data.
function AIRWING:_AddSquadonMenu(squadron)

  local Coalition=self:GetCoalition()

  local root=self.menu[Coalition].Squadron.Main

  local menu=MENU_COALITION:New(Coalition, squadron.name, root)

  MENU_COALITION_COMMAND:New(Coalition, "Report",    menu, self._ReportSq, self, squadron)
  MENU_COALITION_COMMAND:New(Coalition, "Launch CAP", menu, self._LaunchCAP, self, squadron)

  -- Set menu.
  squadron.menu=menu

end


--- Report squadron status.
-- @param #AIRWING self
-- @param Ops.Squadron#SQUADRON squadron The squadron object.
function AIRWING:_ReportSq(squadron)

  local text=string.format("%s: %s assets:", squadron.name, tostring(squadron.categoryname))
  for i,_asset in pairs(squadron.assets) do
    local asset=_asset --Functional.Warehouse#WAREHOUSE.Assetitem
    text=text..string.format("%d.) ")
  end
end

--- Warehouse reports on/off.
-- @param #AIRWING self
function AIRWING:WarehouseReportsToggle()
  self.Report=not self.Report
  MESSAGE:New(string.format("Warehouse reports are now %s", tostring(self.Report)), 10, "AIRWING", true):ToCoalition(self:GetCoalition())
end


--- Report warehouse stock.
-- @param #AIRWING self
function AIRWING:ReportWarehouseStock()
  local text=self:_GetStockAssetsText(false)
  MESSAGE:New(text, 10, "AIRWING", true):ToCoalition(self:GetCoalition())
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
