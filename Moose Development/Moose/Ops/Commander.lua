--- **Ops** - Commander of Airwings, Brigades and Fleets.
--
-- **Main Features:**
--
--    * Manages AIRWINGS, BRIGADEs and FLEETs
--    * Handles missions (AUFTRAG) and finds the best assets for the job 
--
-- ===
--
-- ### Author: **funkyfranky**
-- 
-- ===
-- @module Ops.Commander
-- @image OPS_Commander.png


--- COMMANDER class.
-- @type COMMANDER
-- @field #string ClassName Name of the class.
-- @field #number verbose Verbosity level.
-- @field #string lid Class id string for output to DCS log file.
-- @field #number coalition Coalition side of the commander.
-- @field #string alias Alias name.
-- @field #table legions Table of legions which are commanded.
-- @field #table missionqueue Mission queue.
-- @field #table transportqueue Transport queue.
-- @field #table targetqueue Target queue.
-- @field #table opsqueue Operations queue.
-- @field #table rearmingZones Rearming zones. Each element is of type `#BRIGADE.SupplyZone`.
-- @field #table refuellingZones Refuelling zones. Each element is of type `#BRIGADE.SupplyZone`.
-- @field #table capZones CAP zones. Each element is of type `#AIRWING.PatrolZone`.
-- @field #table gcicapZones GCICAP zones. Each element is of type `#AIRWING.PatrolZone`.
-- @field #table awacsZones AWACS zones. Each element is of type `#AIRWING.PatrolZone`.
-- @field #table tankerZones Tanker zones. Each element is of type `#AIRWING.TankerZone`.
-- @field Ops.Chief#CHIEF chief Chief of staff.
-- @field #table limitMission Table of limits for mission types.
-- @extends Core.Fsm#FSM

--- *He who has never leared to obey cannot be a good commander.* -- Aristotle
--
-- ===
--
-- # The COMMANDER Concept
-- 
-- A commander is the head of legions. He/she will find the best LEGIONs to perform an assigned AUFTRAG (mission) or OPSTRANSPORT.
-- A legion can be an AIRWING, BRIGADE or FLEET.
--
-- # Constructor
-- 
-- A new COMMANDER object is created with the @{#COMMANDER.New}(*Coalition, Alias*) function, where the parameter *Coalition* is the coalition side.
-- It can be `coalition.side.RED`, `coalition.side.BLUE` or `coalition.side.NEUTRAL`. This parameter is mandatory!
-- 
-- The second parameter *Alias* is optional and can be used to give the COMMANDER a "name", which is used for output in the dcs.log file.
-- 
--     local myCommander=COMANDER:New(coalition.side.BLUE, "General Patton")
-- 
-- # Adding Legions
-- 
-- Legions, i.e. AIRWINGS, BRIGADES and FLEETS can be added via the @{#COMMANDER.AddLegion}(*Legion*) command:
-- 
--     myCommander:AddLegion(myLegion)
-- 
-- ## Adding Airwings
-- 
-- It is also possible to use @{#COMMANDER.AddAirwing}(*myAirwing*) function. This does the same as the `AddLegion` function but might be a bit more intuitive.
-- 
-- ## Adding Brigades
-- 
-- It is also possible to use @{#COMMANDER.AddBrigade}(*myBrigade*) function. This does the same as the `AddLegion` function but might be a bit more intuitive.
-- 
-- ## Adding Fleets
-- 
-- It is also possible to use @{#COMMANDER.AddFleet}(*myFleet*) function. This does the same as the `AddLegion` function but might be a bit more intuitive.
-- 
-- # Adding Missions
-- 
-- Mission can be added via the @{#COMMANDER.AddMission}(*myMission*) function.
-- 
-- # Adding OPS Transports
-- 
-- Transportation assignments can be added via the @{#COMMANDER.AddOpsTransport}(*myTransport*) function.
-- 
-- # Adding CAP Zones
-- 
-- A CAP zone can be added via the @{#COMMANDER.AddCapZone}() function.
-- 
-- # Adding Rearming Zones
-- 
-- A rearming zone can be added via the @{#COMMANDER.AddRearmingZone}() function.
-- 
-- # Adding Refuelling Zones
-- 
-- A refuelling zone can be added via the @{#COMMANDER.AddRefuellingZone}() function.
-- 
-- 
-- # FSM Events
-- 
-- The COMMANDER will 
-- 
-- ## OPSGROUP on Mission
-- 
-- Whenever an OPSGROUP (FLIGHTGROUP, ARMYGROUP or NAVYGROUP) is send on a mission, the `OnAfterOpsOnMission()` event is triggered.
-- Mission designers can hook into the event with the @{#COMMANDER.OnAfterOpsOnMission}() function
-- 
--     function myCommander:OnAfterOpsOnMission(From, Event, To, OpsGroup, Mission)
--       -- Your code
--     end
--     
-- ## Canceling a Mission
-- 
-- A mission can be cancelled with the @{#COMMMANDER.MissionCancel}() function
-- 
--     myCommander:MissionCancel(myMission)
--     
-- or
--     myCommander:__MissionCancel(5*60, myMission)
--     
-- The last commander cancels the mission after 5 minutes (300 seconds).
-- 
-- The cancel command will be forwarded to all assigned legions and OPS groups, which will abort their mission or remove it from their queue.
--
-- @field #COMMANDER
COMMANDER = {
  ClassName       = "COMMANDER",
  verbose         =     0,
  coalition       =   nil,
  legions         =    {},
  missionqueue    =    {},
  transportqueue  =    {},
  targetqueue     =    {},
  opsqueue        =    {},
  rearmingZones   =    {},
  refuellingZones =    {},
  capZones        =    {},
  gcicapZones     =    {},
  awacsZones      =    {},
  tankerZones     =    {},
  limitMission    =    {},
  maxMissionsAssignPerCycle = 1,
}

--- COMMANDER class version.
-- @field #string version
COMMANDER.version="0.1.4"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- DONE: Add CAP zones.
-- DONE: Add tanker zones.
-- DONE: Improve legion selection. Mostly done!
-- DONE: Find solution for missions, which require a transport. This is not as easy as it sounds since the selected mission assets restrict the possible transport assets.
-- DONE: Add ops transports.
-- DONE: Allow multiple Legions for one mission.
-- NOGO: Maybe it's possible to preselect the assets for the mission.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new COMMANDER object and start the FSM.
-- @param #COMMANDER self
-- @param #number Coalition Coaliton of the commander.
-- @param #string Alias Some name you want the commander to be called.
-- @return #COMMANDER self
function COMMANDER:New(Coalition, Alias)

  -- Inherit everything from INTEL class.
  local self=BASE:Inherit(self, FSM:New()) --#COMMANDER

  if Coalition==nil then
    env.error("ERROR: Coalition parameter is nil in COMMANDER:New() call!")
    return nil
  end
  
  -- Set coaliton.
  self.coalition=Coalition
  
  -- Alias name.
  self.alias=Alias
  
  -- Choose a name for red or blue.
  if self.alias==nil then
    if Coalition==coalition.side.BLUE then
      self.alias="George S. Patton"
    elseif Coalition==coalition.side.RED then
      self.alias="Georgy Zhukov"
    elseif Coalition==coalition.side.NEUTRAL then
      self.alias="Mahatma Gandhi"
    end
  end
  
  -- Log ID.
  self.lid=string.format("COMMANDER %s [%s] | ", self.alias, UTILS.GetCoalitionName(self.coalition))

  -- Start state.
  self:SetStartState("NotReadyYet")

  -- Add FSM transitions.
  --                 From State     -->      Event        -->     To State
  self:AddTransition("NotReadyYet",        "Start",               "OnDuty")      -- Start COMMANDER.
  self:AddTransition("*",                  "Status",              "*")           -- Status report.
  self:AddTransition("*",                  "Stop",                "Stopped")     -- Stop COMMANDER.
  
  self:AddTransition("*",                  "MissionAssign",       "*")           -- Mission is assigned to a or multiple LEGIONs.
  self:AddTransition("*",                  "MissionCancel",       "*")           -- COMMANDER cancels a mission.

  self:AddTransition("*",                  "TransportAssign",     "*")           -- Transport is assigned to a or multiple LEGIONs.
  self:AddTransition("*",                  "TransportCancel",     "*")           -- COMMANDER cancels a Transport.

  self:AddTransition("*",                  "OpsOnMission",        "*")           -- An OPSGROUP was send on a Mission (AUFTRAG).
  
  self:AddTransition("*",                  "LegionLost",          "*")           -- Out of our legions was lost to the enemy.

  ------------------------
  --- Pseudo Functions ---
  ------------------------

  --- Triggers the FSM event "Start". Starts the COMMANDER.
  -- @function [parent=#COMMANDER] Start
  -- @param #COMMANDER self

  --- Triggers the FSM event "Start" after a delay. Starts the COMMANDER.
  -- @function [parent=#COMMANDER] __Start
  -- @param #COMMANDER self
  -- @param #number delay Delay in seconds.


  --- Triggers the FSM event "Stop". Stops the COMMANDER.
  -- @param #COMMANDER self

  --- Triggers the FSM event "Stop" after a delay. Stops the COMMANDER.
  -- @function [parent=#COMMANDER] __Stop
  -- @param #COMMANDER self
  -- @param #number delay Delay in seconds.


  --- Triggers the FSM event "Status".
  -- @function [parent=#COMMANDER] Status
  -- @param #COMMANDER self

  --- Triggers the FSM event "Status" after a delay.
  -- @function [parent=#COMMANDER] __Status
  -- @param #COMMANDER self
  -- @param #number delay Delay in seconds.


  --- Triggers the FSM event "MissionAssign". Mission is added to a LEGION mission queue and already requested. Needs assets to be added to the mission!
  -- @function [parent=#COMMANDER] MissionAssign
  -- @param #COMMANDER self
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.
  -- @param #table Legions The Legion(s) to which the mission is assigned.

  --- Triggers the FSM event "MissionAssign" after a delay. Mission is added to a LEGION mission queue and already requested. Needs assets to be added to the mission!
  -- @function [parent=#COMMANDER] __MissionAssign
  -- @param #COMMANDER self
  -- @param #number delay Delay in seconds.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.
  -- @param #table Legions The Legion(s) to which the mission is assigned.

  --- On after "MissionAssign" event.
  -- @function [parent=#COMMANDER] OnAfterMissionAssign
  -- @param #COMMANDER self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.
  -- @param #table Legions The Legion(s) to which the mission is assigned.


  --- Triggers the FSM event "MissionCancel".
  -- @function [parent=#COMMANDER] MissionCancel
  -- @param #COMMANDER self
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.

  --- Triggers the FSM event "MissionCancel" after a delay.
  -- @function [parent=#COMMANDER] __MissionCancel
  -- @param #COMMANDER self
  -- @param #number delay Delay in seconds.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.

  --- On after "MissionCancel" event.
  -- @function [parent=#COMMANDER] OnAfterMissionCancel
  -- @param #COMMANDER self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.


  --- Triggers the FSM event "TransportAssign".
  -- @function [parent=#COMMANDER] TransportAssign
  -- @param #COMMANDER self
  -- @param Ops.OpsTransport#OPSTRANSPORT Transport The transport.
  -- @param #table Legions The legion(s) to which this transport is assigned.

  --- Triggers the FSM event "TransportAssign" after a delay.
  -- @function [parent=#COMMANDER] __TransportAssign
  -- @param #COMMANDER self
  -- @param #number delay Delay in seconds.
  -- @param Ops.OpsTransport#OPSTRANSPORT Transport The transport.
  -- @param #table Legions The legion(s) to which this transport is assigned.

  --- On after "TransportAssign" event.
  -- @function [parent=#COMMANDER] OnAfterTransportAssign
  -- @param #COMMANDER self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.OpsTransport#OPSTRANSPORT Transport The transport.
  -- @param #table Legions The legion(s) to which this transport is assigned.


  --- Triggers the FSM event "TransportCancel".
  -- @function [parent=#COMMANDER] TransportCancel
  -- @param #COMMANDER self
  -- @param Ops.OpsTransport#OPSTRANSPORT Transport The transport.

  --- Triggers the FSM event "TransportCancel" after a delay.
  -- @function [parent=#COMMANDER] __TransportCancel
  -- @param #COMMANDER self
  -- @param #number delay Delay in seconds.
  -- @param Ops.OpsTransport#OPSTRANSPORT Transport The transport.

  --- On after "TransportCancel" event.
  -- @function [parent=#COMMANDER] OnAfterTransportCancel
  -- @param #COMMANDER self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.OpsTransport#OPSTRANSPORT Transport The transport.


  --- Triggers the FSM event "OpsOnMission".
  -- @function [parent=#COMMANDER] OpsOnMission
  -- @param #COMMANDER self
  -- @param Ops.OpsGroup#OPSGROUP OpsGroup The OPS group on mission.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.

  --- Triggers the FSM event "OpsOnMission" after a delay.
  -- @function [parent=#COMMANDER] __OpsOnMission
  -- @param #COMMANDER self
  -- @param #number delay Delay in seconds.
  -- @param Ops.OpsGroup#OPSGROUP OpsGroup The OPS group on mission.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.

  --- On after "OpsOnMission" event.
  -- @function [parent=#COMMANDER] OnAfterOpsOnMission
  -- @param #COMMANDER self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.OpsGroup#OPSGROUP OpsGroup The OPS group on mission.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.


  --- Triggers the FSM event "LegionLost".
  -- @function [parent=#COMMANDER] LegionLost
  -- @param #COMMANDER self
  -- @param Ops.Legion#LEGION Legion The legion that was lost.
  -- @param DCS#coalition.side Coalition which captured the warehouse.
  -- @param DCS#country.id Country which has captured the warehouse.

  --- Triggers the FSM event "LegionLost".
  -- @function [parent=#COMMANDER] __LegionLost
  -- @param #COMMANDER self
  -- @param #number delay Delay in seconds.
  -- @param Ops.Legion#LEGION Legion The legion that was lost.
  -- @param DCS#coalition.side Coalition which captured the warehouse.
  -- @param DCS#country.id Country which has captured the warehouse.

  --- On after "LegionLost" event.
  -- @function [parent=#COMMANDER] OnAfterLegionLost
  -- @param #COMMANDER self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.Legion#LEGION Legion The legion that was lost.
  -- @param DCS#coalition.side Coalition which captured the warehouse.
  -- @param DCS#country.id Country which has captured the warehouse.

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set verbosity level.
-- @param #COMMANDER self
-- @param #number VerbosityLevel Level of output (higher=more). Default 0.
-- @return #COMMANDER self
function COMMANDER:SetVerbosity(VerbosityLevel)
  self.verbose=VerbosityLevel or 0
  return self
end

--- Set limit for number of total or specific missions to be executed simultaniously.
-- @param #COMMANDER self
-- @param #number Limit Number of max. mission of this type. Default 10.
-- @param #string MissionType Type of mission, e.g. `AUFTRAG.Type.BAI`. Default `"Total"` for total number of missions.
-- @return #COMMANDER self
function COMMANDER:SetLimitMission(Limit, MissionType)
  MissionType=MissionType or "Total"
  if MissionType then
    self.limitMission[MissionType]=Limit or 10
  else
    self:E(self.lid.."ERROR: No mission type given for setting limit!")
  end
  return self
end


--- Get coalition.
-- @param #COMMANDER self
-- @return #number Coalition.
function COMMANDER:GetCoalition()
  return self.coalition
end

--- Add an AIRWING to the commander.
-- @param #COMMANDER self
-- @param Ops.Airwing#AIRWING Airwing The airwing to add.
-- @return #COMMANDER self
function COMMANDER:AddAirwing(Airwing)

  -- Add legion.
  self:AddLegion(Airwing)
  
  return self
end

--- Add a BRIGADE to the commander.
-- @param #COMMANDER self
-- @param Ops.Brigade#BRIGADE Brigade The brigade to add.
-- @return #COMMANDER self
function COMMANDER:AddBrigade(Brigade)

  -- Add legion.
  self:AddLegion(Brigade)
  
  return self
end

--- Add a FLEET to the commander.
-- @param #COMMANDER self
-- @param Ops.Fleet#FLEET Fleet The fleet to add.
-- @return #COMMANDER self
function COMMANDER:AddFleet(Fleet)

  -- Add legion.
  self:AddLegion(Fleet)
  
  return self
end


--- Add a LEGION to the commander.
-- @param #COMMANDER self
-- @param Ops.Legion#LEGION Legion The legion to add.
-- @return #COMMANDER self
function COMMANDER:AddLegion(Legion)

  -- This legion is managed by the commander. 
  Legion.commander=self

  -- Add to legions.
  table.insert(self.legions, Legion)  
  
  return self
end

--- Remove a LEGION to the commander.
-- @param #COMMANDER self
-- @param Ops.Legion#LEGION Legion The legion to be removed.
-- @return #COMMANDER self
function COMMANDER:RemoveLegion(Legion)
    
  for i,_legion in pairs(self.legions) do
    local legion=_legion --Ops.Legion#LEGION
    if legion.alias==Legion.alias then
      table.remove(self.legions, i)
      Legion.commander=nil
    end
  end
  
  return self
end

--- Add mission to mission queue.
-- @param #COMMANDER self
-- @param Ops.Auftrag#AUFTRAG Mission Mission to be added.
-- @return #COMMANDER self
function COMMANDER:AddMission(Mission)

  if not self:IsMission(Mission) then

    Mission.commander=self
    
    Mission.statusCommander=AUFTRAG.Status.PLANNED
  
    table.insert(self.missionqueue, Mission)
    
  end

  return self
end

--- Add transport to queue.
-- @param #COMMANDER self
-- @param Ops.OpsTransport#OPSTRANSPORT Transport The OPS transport to be added.
-- @return #COMMANDER self
function COMMANDER:AddOpsTransport(Transport)

  Transport.commander=self
  
  Transport.statusCommander=OPSTRANSPORT.Status.PLANNED

  table.insert(self.transportqueue, Transport)

  return self
end

--- Remove mission from queue.
-- @param #COMMANDER self
-- @param Ops.Auftrag#AUFTRAG Mission Mission to be removed.
-- @return #COMMANDER self
function COMMANDER:RemoveMission(Mission)

  for i,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG
    
    if mission.auftragsnummer==Mission.auftragsnummer then
      self:T(self.lid..string.format("Removing mission %s (%s) status=%s from queue", Mission.name, Mission.type, Mission.status))
      mission.commander=nil
      table.remove(self.missionqueue, i)
      break
    end
    
  end

  return self
end

--- Remove transport from queue.
-- @param #COMMANDER self
-- @param Ops.OpsTransport#OPSTRANSPORT Transport The OPS transport to be removed.
-- @return #COMMANDER self
function COMMANDER:RemoveTransport(Transport)

  for i,_transport in pairs(self.transportqueue) do
    local transport=_transport --Ops.OpsTransport#OPSTRANSPORT
    
    if transport.uid==Transport.uid then
      self:T(self.lid..string.format("Removing transport UID=%d status=%s from queue", transport.uid, transport:GetState()))
      transport.commander=nil
      table.remove(self.transportqueue, i)
      break
    end
    
  end

  return self
end

--- Add target.
-- @param #COMMANDER self
-- @param Ops.Target#TARGET Target Target object to be added.
-- @return #COMMANDER self
function COMMANDER:AddTarget(Target)

  if not self:IsTarget(Target) then
    table.insert(self.targetqueue, Target)
  end

  return self
end

--- Add operation.
-- @param #COMMANDER self
-- @param Ops.Operation#OPERATION Operation The operation to be added.
-- @return #COMMANDER self
function COMMANDER:AddOperation(Operation)

  -- TODO: Check that is not already added.
  
  -- Add operation to table.
  table.insert(self.opsqueue, Operation)
  
  return self
end

--- Check if a TARGET is already in the queue. 
-- @param #COMMANDER self
-- @param Ops.Target#TARGET Target Target object to be added.
-- @return #boolean If `true`, target exists in the target queue.
function COMMANDER:IsTarget(Target)

  for _,_target in pairs(self.targetqueue) do
    local target=_target --Ops.Target#TARGET
    if target.uid==Target.uid or target:GetName()==Target:GetName() then
      return true
    end
  end

  return false
end

--- Remove target from queue.
-- @param #COMMANDER self
-- @param Ops.Target#TARGET Target The target.
-- @return #COMMANDER self
function COMMANDER:RemoveTarget(Target)

  for i,_target in pairs(self.targetqueue) do
    local target=_target --Ops.Target#TARGET
    
    if target.uid==Target.uid then
      self:T(self.lid..string.format("Removing target %s from queue", Target.name))
      table.remove(self.targetqueue, i)
      break
    end
    
  end

  return self
end

--- Add a rearming zone.
-- @param #COMMANDER self
-- @param Core.Zone#ZONE RearmingZone Rearming zone.
-- @return Ops.Brigade#BRIGADE.SupplyZone The rearming zone data.
function COMMANDER:AddRearmingZone(RearmingZone)

  local rearmingzone={} --Ops.Brigade#BRIGADE.SupplyZone
  
  rearmingzone.zone=RearmingZone
  rearmingzone.mission=nil
  --rearmingzone.marker=MARKER:New(rearmingzone.zone:GetCoordinate(), "Rearming Zone"):ToCoalition(self:GetCoalition())

  table.insert(self.rearmingZones, rearmingzone)

  return rearmingzone
end

--- Add a refuelling zone.
-- @param #COMMANDER self
-- @param Core.Zone#ZONE RefuellingZone Refuelling zone.
-- @return Ops.Brigade#BRIGADE.SupplyZone The refuelling zone data.
function COMMANDER:AddRefuellingZone(RefuellingZone)

  local rearmingzone={} --Ops.Brigade#BRIGADE.SupplyZone
  
  rearmingzone.zone=RefuellingZone
  rearmingzone.mission=nil
  --rearmingzone.marker=MARKER:New(rearmingzone.zone:GetCoordinate(), "Refuelling Zone"):ToCoalition(self:GetCoalition())

  table.insert(self.refuellingZones, rearmingzone)

  return rearmingzone
end

--- Add a CAP zone.
-- @param #COMMANDER self
-- @param Core.Zone#ZONE Zone CapZone Zone.
-- @param #number Altitude Orbit altitude in feet. Default is 12,000 feet.
-- @param #number Speed Orbit speed in KIAS. Default 350 kts.
-- @param #number Heading Heading of race-track pattern in degrees. Default 270 (East to West).
-- @param #number Leg Length of race-track in NM. Default 30 NM.
-- @return Ops.Airwing#AIRWING.PatrolZone The CAP zone data.
function COMMANDER:AddCapZone(Zone, Altitude, Speed, Heading, Leg)

  local patrolzone={} --Ops.Airwing#AIRWING.PatrolZone
  
  patrolzone.zone=Zone
  patrolzone.altitude=Altitude or 12000
  patrolzone.heading=Heading or 270
  --patrolzone.speed=UTILS.KnotsToAltKIAS(Speed or 350, patrolzone.altitude)
  patrolzone.speed=Speed or 350
  patrolzone.leg=Leg or 30
  patrolzone.mission=nil
  --patrolzone.marker=MARKER:New(patrolzone.zone:GetCoordinate(), "CAP Zone"):ToCoalition(self:GetCoalition())

  table.insert(self.capZones, patrolzone)

  return patrolzone
end

--- Add a GCICAP zone.
-- @param #COMMANDER self
-- @param Core.Zone#ZONE Zone CapZone Zone.
-- @param #number Altitude Orbit altitude in feet. Default is 12,000 feet.
-- @param #number Speed Orbit speed in KIAS. Default 350 kts.
-- @param #number Heading Heading of race-track pattern in degrees. Default 270 (East to West).
-- @param #number Leg Length of race-track in NM. Default 30 NM.
-- @return Ops.Airwing#AIRWING.PatrolZone The CAP zone data.
function COMMANDER:AddGciCapZone(Zone, Altitude, Speed, Heading, Leg)

  local patrolzone={} --Ops.Airwing#AIRWING.PatrolZone
  
  patrolzone.zone=Zone
  patrolzone.altitude=Altitude or 12000
  patrolzone.heading=Heading or 270
  --patrolzone.speed=UTILS.KnotsToAltKIAS(Speed or 350, patrolzone.altitude)
  patrolzone.speed=Speed or 350
  patrolzone.leg=Leg or 30
  patrolzone.mission=nil
  --patrolzone.marker=MARKER:New(patrolzone.zone:GetCoordinate(), "GCICAP Zone"):ToCoalition(self:GetCoalition())

  table.insert(self.gcicapZones, patrolzone)

  return patrolzone
end

--- Remove a GCI CAP.
-- @param #COMMANDER self
-- @param Core.Zone#ZONE Zone Zone, where the flight orbits.
function COMMANDER:RemoveGciCapZone(Zone)

  local patrolzone={} --Ops.Airwing#AIRWING.PatrolZone
  
  patrolzone.zone=Zone
  for i,_patrolzone in pairs(self.gcicapZones) do
    if _patrolzone.zone == patrolzone.zone then
      if _patrolzone.mission and _patrolzone.mission:IsNotOver() then
          _patrolzone.mission:Cancel()
      end
      table.remove(self.gcicapZones, i)
      break
    end
  end
  return patrolzone
end

--- Add an AWACS zone.
-- @param #COMMANDER self
-- @param Core.Zone#ZONE Zone Zone.
-- @param #number Altitude Orbit altitude in feet. Default is 12,000 feet.
-- @param #number Speed Orbit speed in KIAS. Default 350 kts.
-- @param #number Heading Heading of race-track pattern in degrees. Default 270 (East to West).
-- @param #number Leg Length of race-track in NM. Default 30 NM.
-- @return Ops.Airwing#AIRWING.PatrolZone The AWACS zone data.
function COMMANDER:AddAwacsZone(Zone, Altitude, Speed, Heading, Leg)

  local awacszone={} --Ops.Airwing#AIRWING.PatrolZone
  
  awacszone.zone=Zone
  awacszone.altitude=Altitude or 12000
  awacszone.heading=Heading or 270
  --awacszone.speed=UTILS.KnotsToAltKIAS(Speed or 350, awacszone.altitude)
  awacszone.speed=Speed or 350
  awacszone.speed=Speed or 350
  awacszone.leg=Leg or 30
  awacszone.mission=nil
  --awacszone.marker=MARKER:New(awacszone.zone:GetCoordinate(), "AWACS Zone"):ToCoalition(self:GetCoalition())

  table.insert(self.awacsZones, awacszone)

  return awacszone
end

--- Remove a AWACS zone.
-- @param #COMMANDER self
-- @param Core.Zone#ZONE Zone Zone, where the flight orbits.
function COMMANDER:RemoveAwacsZone(Zone)

  local awacszone={} --Ops.Airwing#AIRWING.PatrolZone
  
  awacszone.zone=Zone
  for i,_awacszone in pairs(self.awacsZones) do
    if _awacszone.zone == awacszone.zone then
      if _awacszone.mission and _awacszone.mission:IsNotOver() then
          _awacszone.mission:Cancel()
      end
      table.remove(self.awacsZones, i)
      break
    end
  end
  return awacszone
end

--- Add a refuelling tanker zone.
-- @param #COMMANDER self
-- @param Core.Zone#ZONE Zone Zone.
-- @param #number Altitude Orbit altitude in feet. Default is 12,000 feet.
-- @param #number Speed Orbit speed in KIAS. Default 350 kts.
-- @param #number Heading Heading of race-track pattern in degrees. Default 270 (East to West).
-- @param #number Leg Length of race-track in NM. Default 30 NM.
-- @param #number RefuelSystem Refuelling system.
-- @return Ops.Airwing#AIRWING.TankerZone The tanker zone data.
function COMMANDER:AddTankerZone(Zone, Altitude, Speed, Heading, Leg, RefuelSystem)

  local tankerzone={} --Ops.Airwing#AIRWING.TankerZone
  
  tankerzone.zone=Zone
  tankerzone.altitude=Altitude or 12000
  tankerzone.heading=Heading or 270
  --tankerzone.speed=UTILS.KnotsToAltKIAS(Speed or 350, tankerzone.altitude) -- speed translation to alt will be done by AUFTRAG anyhow
  tankerzone.speed = Speed or 350
  tankerzone.leg=Leg or 30
  tankerzone.refuelsystem=RefuelSystem
  tankerzone.mission=nil
  tankerzone.marker=MARKER:New(tankerzone.zone:GetCoordinate(), "Tanker Zone"):ToCoalition(self:GetCoalition())

  table.insert(self.tankerZones, tankerzone)

  return tankerzone
end

--- Remove a refuelling tanker zone.
-- @param #COMMANDER self
-- @param Core.Zone#ZONE Zone Zone, where the flight orbits.
function COMMANDER:RemoveTankerZone(Zone)

  local tankerzone={} --Ops.Airwing#AIRWING.PatrolZone
  
  tankerzone.zone=Zone
  for i,_tankerzone in pairs(self.tankerZones) do
    if _tankerzone.zone == tankerzone.zone then
      if _tankerzone.mission and _tankerzone.mission:IsNotOver() then
          _tankerzone.mission:Cancel()
      end
      table.remove(self.tankerZones, i)
      break
    end
  end
  return tankerzone
end

--- Check if this mission is already in the queue.
-- @param #COMMANDER self
-- @param Ops.Auftrag#AUFTRAG Mission The mission.
-- @return #boolean If `true`, this mission is in the queue.
function COMMANDER:IsMission(Mission)

  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG
    if mission.auftragsnummer==Mission.auftragsnummer then
      return true
    end 
  end

  return false
end

--- Relocate a cohort to another legion.
-- Assets in stock are spawned and routed to the new legion.
-- If assets are spawned, running missions will be cancelled.
-- Cohort assets will not be available until relocation is finished.
-- @param #COMMANDER self
-- @param Ops.Cohort#COHORT Cohort The cohort to be relocated.
-- @param Ops.Legion#LEGION Legion The legion where the cohort is relocated to.
-- @param #number Delay Delay in seconds before relocation takes place. Default `nil`, *i.e.* ASAP.
-- @param #number NcarriersMin Min number of transport carriers in case the troops should be transported. Default `nil` for no transport.
-- @param #number NcarriersMax Max number of transport carriers.
-- @param #table TransportLegions Legion(s) assigned for transportation. Default is all legions of the commander.
-- @return #COMMANDER self
function COMMANDER:RelocateCohort(Cohort, Legion, Delay, NcarriersMin, NcarriersMax, TransportLegions)

  if Delay and Delay>0 then
    self:ScheduleOnce(Delay, COMMANDER.RelocateCohort, self, Cohort, Legion, 0, NcarriersMin, NcarriersMax, TransportLegions)
  else
  
    -- Add cohort to legion.
    if Legion:IsCohort(Cohort.name) then
      self:E(self.lid..string.format("ERROR: Cohort %s is already part of new legion %s ==> CANNOT Relocate!", Cohort.name, Legion.alias))
      return self
    else
      table.insert(Legion.cohorts, Cohort)      
    end
    
    -- Old legion.
    local LegionOld=Cohort.legion
    
    -- Check that cohort is part of this legion
    if not LegionOld:IsCohort(Cohort.name) then
      self:E(self.lid..string.format("ERROR: Cohort %s is NOT part of this legion %s ==> CANNOT Relocate!", Cohort.name, self.alias))
      return self    
    end
    
    -- Check that legions are different.
    if LegionOld.alias==Legion.alias then
      self:E(self.lid..string.format("ERROR: old legion %s is same as new legion %s ==> CANNOT Relocate!", LegionOld.alias, Legion.alias))
      return self    
    end
    
    -- Trigger Relocate event.
    Cohort:Relocate()
    
    -- Create a relocation mission.
    local mission=AUFTRAG:_NewRELOCATECOHORT(Legion, Cohort)
   
    -- Assign cohort to mission.
    mission:AssignCohort(Cohort)
    
    -- All assets required.
    mission:SetRequiredAssets(#Cohort.assets)
    
    -- Set transportation.
    if NcarriersMin and NcarriersMin>0 then
      mission:SetRequiredTransport(Legion.spawnzone, NcarriersMin, NcarriersMax)
    end
    
    -- Assign transport legions.
    if TransportLegions then
      for _,legion in pairs(TransportLegions) do
        mission:AssignTransportLegion(legion)
      end
    else
      for _,legion in pairs(self.legions) do
        mission:AssignTransportLegion(legion)
      end 
    end
    
      -- Set mission range very large. Mission designer should know...
      mission:SetMissionRange(10000)    
    
    -- Add mission.
    self:AddMission(mission)
      
  end

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Start & Status
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after Start event. Starts the FLIGHTGROUP FSM and event handlers.
-- @param #COMMANDER self
-- @param Wrapper.Group#GROUP Group Flight group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function COMMANDER:onafterStart(From, Event, To)

  -- Short info.
  local text=string.format("Starting Commander")
  self:I(self.lid..text)
  
  -- Start attached legions.
  for _,_legion in pairs(self.legions) do
    local legion=_legion --Ops.Legion#LEGION
    if legion:GetState()=="NotReadyYet" then
      legion:Start()
    end
  end

  self:__Status(-1)
end

--- On after "Status" event.
-- @param #COMMANDER self
-- @param Wrapper.Group#GROUP Group Flight group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function COMMANDER:onafterStatus(From, Event, To)

  -- FSM state.
  local fsmstate=self:GetState()

  -- Status.
  if self.verbose>=1 then
    local text=string.format("Status %s: Legions=%d, Missions=%d, Targets=%d, Transports=%d", fsmstate, #self.legions, #self.missionqueue, #self.targetqueue, #self.transportqueue)
    self:T(self.lid..text)
  end
  
  -- Check Operations queue.
  self:CheckOpsQueue()    
  
  -- Check target queue and add missions.
  self:CheckTargetQueue()  

  -- Check mission queue and assign one PLANNED mission.
  self:CheckMissionQueue()
  
  -- Check transport queue and assign one PLANNED transport.
  self:CheckTransportQueue()
  
  -- Check rearming zones.
  for _,_rearmingzone in pairs(self.rearmingZones) do
    local rearmingzone=_rearmingzone --Ops.Brigade#BRIGADE.SupplyZone
    -- Check if mission is nil or over.      
    if (not rearmingzone.mission) or rearmingzone.mission:IsOver() then
      rearmingzone.mission=AUFTRAG:NewAMMOSUPPLY(rearmingzone.zone)
      self:AddMission(rearmingzone.mission)
    end
  end
  
  -- Check refuelling zones.
  for _,_supplyzone in pairs(self.refuellingZones) do
    local supplyzone=_supplyzone --Ops.Brigade#BRIGADE.SupplyZone
    -- Check if mission is nil or over.      
    if (not supplyzone.mission) or supplyzone.mission:IsOver() then
      supplyzone.mission=AUFTRAG:NewFUELSUPPLY(supplyzone.zone)
      self:AddMission(supplyzone.mission)
    end
  end


  -- Check CAP zones.
  for _,_patrolzone in pairs(self.capZones) do
    local patrolzone=_patrolzone --Ops.Airwing#AIRWING.PatrolZone
    -- Check if mission is nil or over.
    if (not patrolzone.mission) or patrolzone.mission:IsOver() then
      local Coordinate=patrolzone.zone:GetCoordinate()
      patrolzone.mission=AUFTRAG:NewCAP(patrolzone.zone, patrolzone.altitude, patrolzone.speed, Coordinate, patrolzone.heading, patrolzone.leg)
      self:AddMission(patrolzone.mission)
    end
  end

  -- Check GCICAP zones.
  for _,_patrolzone in pairs(self.gcicapZones) do
    local patrolzone=_patrolzone --Ops.Airwing#AIRWING.PatrolZone
    -- Check if mission is nil or over.
    if (not patrolzone.mission) or patrolzone.mission:IsOver() then
      local Coordinate=patrolzone.zone:GetCoordinate()
      patrolzone.mission=AUFTRAG:NewGCICAP(Coordinate, patrolzone.altitude, patrolzone.speed, patrolzone.heading, patrolzone.leg)
      self:AddMission(patrolzone.mission)
    end
  end
  
  -- Check AWACS zones.
  for _,_awacszone in pairs(self.awacsZones) do
    local awacszone=_awacszone --Ops.Airwing#AIRWING.Patrol
    -- Check if mission is nil or over.
    if (not awacszone.mission) or awacszone.mission:IsOver() then
      local Coordinate=awacszone.zone:GetCoordinate()
      awacszone.mission=AUFTRAG:NewAWACS(Coordinate, awacszone.altitude, awacszone.speed, awacszone.heading, awacszone.leg)
      self:AddMission(awacszone.mission)
    end
  end 

  -- Check Tanker zones.
  for _,_tankerzone in pairs(self.tankerZones) do
    local tankerzone=_tankerzone --Ops.Airwing#AIRWING.TankerZone
    -- Check if mission is nil or over.
    if (not tankerzone.mission) or tankerzone.mission:IsOver() then
      local Coordinate=tankerzone.zone:GetCoordinate()
      tankerzone.mission=AUFTRAG:NewTANKER(Coordinate, tankerzone.altitude, tankerzone.speed, tankerzone.heading, tankerzone.leg, tankerzone.refuelsystem)
      self:AddMission(tankerzone.mission)
    end
  end      
    
  ---
  -- LEGIONS
  ---
 
  if self.verbose>=2 and #self.legions>0 then
  
    local text="Legions:"
    for _,_legion in pairs(self.legions) do
      local legion=_legion --Ops.Legion#LEGION
      local Nassets=legion:CountAssets()
      local Nastock=legion:CountAssets(true)
      text=text..string.format("\n* %s [%s]: Assets=%s stock=%s", legion.alias, legion:GetState(), Nassets, Nastock)
      for _,aname in pairs(AUFTRAG.Type) do
        local na=legion:CountAssets(true, {aname})
        local np=legion:CountPayloadsInStock({aname})
        local nm=legion:CountAssetsOnMission({aname})
        if na>0 or np>0 then
          text=text..string.format("\n   - %s: assets=%d, payloads=%d, on mission=%d", aname, na, np, nm)
        end
      end            
    end
    self:T(self.lid..text)
    
    
    if self.verbose>=3 then
    
      -- Count numbers
      local Ntotal=0
      local Nspawned=0
      local Nrequested=0
      local Nreserved=0
      local Nstock=0
      
      local text="\n===========================================\n"
      text=text.."Assets:"
      for _,_legion in pairs(self.legions) do
        local legion=_legion --Ops.Legion#LEGION
  
        for _,_cohort in pairs(legion.cohorts) do
          local cohort=_cohort --Ops.Cohort#COHORT
          
          for _,_asset in pairs(cohort.assets) do
            local asset=_asset --Functional.Warehouse#WAREHOUSE.Assetitem

            local state="In Stock"
            if asset.flightgroup then
              state=asset.flightgroup:GetState()
              local mission=legion:GetAssetCurrentMission(asset)
              if mission then
                state=state..string.format(", Mission \"%s\" [%s]", mission:GetName(), mission:GetType())
              end
            else
              if asset.spawned then
                env.info("FF ERROR: asset has opsgroup but is NOT spawned!")
              end
              if asset.requested and asset.isReserved then
                env.info("FF ERROR: asset is requested and reserved. Should not be both!")
                state="Reserved+Requested!"
              elseif asset.isReserved then
                state="Reserved"
              elseif asset.requested then
                state="Requested"
              end
            end
                        
            -- Text.
            text=text..string.format("\n[UID=%03d] %s Legion=%s [%s]: State=%s [RID=%s]", 
            asset.uid, asset.spawngroupname, legion.alias, cohort.name, state, tostring(asset.rid))
            
            
            if asset.spawned then
              Nspawned=Nspawned+1
            end            
            if asset.requested then
              Nrequested=Nrequested+1
            end  
            if asset.isReserved then
              Nreserved=Nreserved+1
            end                      
            if not (asset.spawned or asset.requested or asset.isReserved) then
              Nstock=Nstock+1
            end
            
            Ntotal=Ntotal+1
            
          end
          
        end
  
      end
      text=text.."\n-------------------------------------------"
      text=text..string.format("\nNstock     = %d", Nstock)
      text=text..string.format("\nNreserved  = %d", Nreserved)
      text=text..string.format("\nNrequested = %d", Nrequested)
      text=text..string.format("\nNspawned   = %d", Nspawned)
      text=text..string.format("\nNtotal     = %d (=%d)", Ntotal, Nstock+Nspawned+Nrequested+Nreserved)
      text=text.."\n==========================================="
      self:I(self.lid..text)
    end
    
  end
  
  ---
  -- MISSIONS
  ---
    
  -- Mission queue.
  if self.verbose>=2 and #self.missionqueue>0 then
    local text="Mission queue:"
    for i,_mission in pairs(self.missionqueue) do
      local mission=_mission --Ops.Auftrag#AUFTRAG      
      local target=mission:GetTargetName() or "unknown"      
      text=text..string.format("\n[%d] %s (%s): status=%s, target=%s", i, mission.name, mission.type, mission.status, target)
    end
    self:I(self.lid..text)    
  end


  ---
  -- TARGETS
  ---
    
  -- Target queue.
  if self.verbose>=2 and #self.targetqueue>0 then
    local text="Target queue:"
    for i,_target in pairs(self.targetqueue) do      
      local target=_target --Ops.Target#TARGET      
      text=text..string.format("\n[%d] %s: status=%s, life=%d", i, target:GetName(), target:GetState(), target:GetLife())
    end
    self:I(self.lid..text)    
  end
  
  ---
  -- TRANSPORTS
  ---
    
  -- Transport queue.
  if self.verbose>=2 and #self.transportqueue>0 then
    local text="Transport queue:"
    for i,_transport in pairs(self.transportqueue) do
      local transport=_transport --Ops.OpsTransport#OPSTRANSPORT            
      text=text..string.format("\n[%d] UID=%d: status=%s", i, transport.uid, transport:GetState())
    end
    self:I(self.lid..text)    
  end  

  self:__Status(-30)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Events
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after "MissionAssign" event. Mission is added to a LEGION mission queue and already requested. Needs assets to be added to the mission already.
-- @param #COMMANDER self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.Auftrag#AUFTRAG Mission The mission.
-- @param #table Legions The Legion(s) to which the mission is assigned.
function COMMANDER:onafterMissionAssign(From, Event, To, Mission, Legions)
    
  -- Add mission to queue.
  self:AddMission(Mission)

  -- Set mission commander status to QUEUED as it is now queued at a legion.
  Mission.statusCommander=AUFTRAG.Status.QUEUED

  for _,_Legion in pairs(Legions) do
    local Legion=_Legion --Ops.Legion#LEGION

    -- Debug info.
    self:T(self.lid..string.format("Assigning mission \"%s\" [%s] to legion \"%s\"", Mission.name, Mission.type, Legion.alias))

    -- Add mission to legion.
    Legion:AddMission(Mission)
    
    -- Directly request the mission as the assets have already been selected.
    Legion:MissionRequest(Mission)
    
  end

end

--- On after "MissionCancel" event.
-- @param #COMMANDER self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.Auftrag#AUFTRAG Mission The mission.
function COMMANDER:onafterMissionCancel(From, Event, To, Mission)

  -- Debug info.
  self:T(self.lid..string.format("Cancelling mission \"%s\" [%s] in status %s", Mission.name, Mission.type, Mission.status))
  
  -- Set commander status.
  Mission.statusCommander=AUFTRAG.Status.CANCELLED
  
  if Mission:IsPlanned() then
  
    -- Mission is still in planning stage. Should not have a legion assigned ==> Just remove it form the queue.
    self:RemoveMission(Mission)
    
  else
  
    -- Legion will cancel mission.
    if #Mission.legions>0 then
      for _,_legion in pairs(Mission.legions) do
        local legion=_legion --Ops.Legion#LEGION
        
        -- TODO: Should check that this legions actually belongs to this commander.
        
        -- Legion will cancel the mission.
        legion:MissionCancel(Mission)
      end
    end
    
  end

end

--- On after "TransportAssign" event. Transport is added to a LEGION transport queue.
-- @param #COMMANDER self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.OpsTransport#OPSTRANSPORT Transport The transport.
  -- @param #table Legions The legion(s) to which this transport is assigned.
function COMMANDER:onafterTransportAssign(From, Event, To, Transport, Legions)
  
  -- Set mission commander status to QUEUED as it is now queued at a legion.
  Transport.statusCommander=OPSTRANSPORT.Status.QUEUED
  
  for _,_Legion in pairs(Legions) do
    local Legion=_Legion --Ops.Legion#LEGION

    -- Debug info.
    self:T(self.lid..string.format("Assigning transport UID=%d to legion \"%s\"", Transport.uid, Legion.alias))
  
    -- Add mission to legion.
    Legion:AddOpsTransport(Transport)
    
    -- Directly request the mission as the assets have already been selected.
    Legion:TransportRequest(Transport)
    
  end

end

--- On after "TransportCancel" event.
-- @param #COMMANDER self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.OpsTransport#OPSTRANSPORT Transport The transport.
function COMMANDER:onafterTransportCancel(From, Event, To, Transport)

  -- Debug info.
  self:T(self.lid..string.format("Cancelling Transport UID=%d in status %s", Transport.uid, Transport:GetState()))
  
  -- Set commander status.
  Transport.statusCommander=OPSTRANSPORT.Status.CANCELLED
  
  if Transport:IsPlanned() then
  
    -- Transport is still in planning stage. Should not have a legion assigned ==> Just remove it form the queue.
    self:RemoveTransport(Transport)
    
  else
  
    -- Legion will cancel mission.
    if #Transport.legions>0 then
      for _,_legion in pairs(Transport.legions) do
        local legion=_legion --Ops.Legion#LEGION
        
        -- TODO: Should check that this legions actually belongs to this commander.
        
        -- Legion will cancel the mission.
        legion:TransportCancel(Transport)
      end
    end
    
  end

end

--- On after "OpsOnMission".
-- @param #COMMANDER self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.OpsGroup#OPSGROUP OpsGroup Ops group on mission
-- @param Ops.Auftrag#AUFTRAG Mission The requested mission.
function COMMANDER:onafterOpsOnMission(From, Event, To, OpsGroup, Mission)
  -- Debug info.
  self:T2(self.lid..string.format("Group \"%s\" on mission \"%s\" [%s]", OpsGroup:GetName(), Mission:GetName(), Mission:GetType()))
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Mission Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Check OPERATIONs queue.
-- @param #COMMANDER self 
function COMMANDER:CheckOpsQueue()

  -- Number of missions.
  local Nops=#self.opsqueue

  -- Treat special cases.
  if Nops==0 then
    return nil
  end
  
  -- Loop over operations.
  for _,_ops in pairs(self.opsqueue) do
    local operation=_ops --Ops.Operation#OPERATION
    
    if operation:IsRunning() then
    
      -- Loop over missions.
      for _,_mission in pairs(operation.missions or {}) do
        local mission=_mission --Ops.Auftrag#AUFTRAG
        
        if mission.phase==nil or (mission.phase and mission.phase==operation.phase) and mission:IsPlanned() then
          self:AddMission(mission)
        end
      end
      
      -- Loop over targets.
      for _,_target in pairs(operation.targets or {}) do
        local target=_target --Ops.Target#TARGET
        
        if (target.phase==nil or (target.phase and target.phase==operation.phase)) and (not self:IsTarget(target)) then
          self:AddTarget(target)
        end
      end    
    
    end
    
  end
  
end

--- Check target queue and assign ONE valid target by adding it to the mission queue of the COMMANDER.
-- @param #COMMANDER self 
function COMMANDER:CheckTargetQueue()

  -- Number of missions.
  local Ntargets=#self.targetqueue

  -- Treat special cases.
  if Ntargets==0 then
    return nil
  end
  
  -- Remove done targets.
  for i=#self.targetqueue,1,-1 do
    local target=self.targetqueue[i] --Ops.Target#TARGET
    if (not target:IsAlive()) or target:EvalConditionsAny(target.conditionStop) then   
      for _,_resource in pairs(target.resources) do
        local resource=_resource --Ops.Target#TARGET.Resource
        if resource.mission and resource.mission:IsNotOver() then
          self:MissionCancel(resource.mission)
        end
      end
      table.remove(self.targetqueue, i)
    end
  end
  
  -- Check if total number of missions is reached.
  local NoLimit=self:_CheckMissionLimit("Total")
  if NoLimit==false then
    return nil
  end

  -- Sort results table wrt prio and threatlevel.
  local function _sort(a, b)
    local taskA=a --Ops.Target#TARGET
    local taskB=b --Ops.Target#TARGET
    return (taskA.prio<taskB.prio) or (taskA.prio==taskB.prio and taskA.threatlevel0>taskB.threatlevel0)
  end
  table.sort(self.targetqueue, _sort)

  -- Get the lowest importance value (lower means more important).
  -- If a target with importance 1 exists, targets with importance 2 will not be assigned. Targets with no importance (nil) can still be selected. 
  local vip=math.huge
  for _,_target in pairs(self.targetqueue) do
    local target=_target --Ops.Target#TARGET
    if target:IsAlive() and target.importance and target.importance<vip then
      vip=target.importance
    end
  end

  -- Loop over targets.
  for _,_target in pairs(self.targetqueue) do
    local target=_target --Ops.Target#TARGET
    
    -- Is target still alive.
    local isAlive=target:IsAlive()
    
    -- Is this target important enough.
    local isImportant=(target.importance==nil or target.importance<=vip)
    
    -- Check ALL start conditions are true.
    local isReadyStart=target:EvalConditionsAll(target.conditionStart)
    
    -- Debug message.
    local text=string.format("Target %s: Alive=%s, Important=%s", target:GetName(), tostring(isAlive), tostring(isImportant))
    self:T2(self.lid..text)

    -- Check that target is alive and not already a mission has been assigned.
    if isAlive and isImportant then

      for _,_resource in pairs(target.resources or {}) do
        local resource=_resource --Ops.Target#TARGET.Resource
        
        -- Mission type.
        local missionType=resource.MissionType

        if (not resource.mission) or resource.mission:IsOver() then

          -- Debug info.
          self:T2(self.lid..string.format("Target \"%s\" ==> Creating mission type %s: Nmin=%d, Nmax=%d", target:GetName(), missionType, resource.Nmin, resource.Nmax))          
          
          -- Create a mission.
          local mission=AUFTRAG:NewFromTarget(target, missionType)
          
          if mission then
          
            -- Set mission parameters.
            mission:SetRequiredAssets(resource.Nmin, resource.Nmax)
            mission:SetRequiredAttribute(resource.Attributes)
            mission:SetRequiredProperty(resource.Properties)
            
            -- Set operation (if any).
            mission.operation=target.operation
            
            -- Set resource mission.
            resource.mission=mission
            
            -- Add mission to queue.
            self:AddMission(resource.mission)
            
          end
         
        end
      
      end
              
    end
  end
  
end


--- Check mission queue and assign ONE planned mission.
-- @param #COMMANDER self 
function COMMANDER:CheckMissionQueue()

  -- Number of missions.
  local Nmissions=#self.missionqueue

  -- Treat special cases.
  if Nmissions==0 then
    return nil
  end
  
  local NoLimit=self:_CheckMissionLimit("Total")  
  if NoLimit==false then
    return nil
  end

  -- Sort results table wrt prio and start time.
  local function _sort(a, b)
    local taskA=a --Ops.Auftrag#AUFTRAG
    local taskB=b --Ops.Auftrag#AUFTRAG
    return (taskA.prio<taskB.prio) or (taskA.prio==taskB.prio and taskA.Tstart<taskB.Tstart)
  end
  table.sort(self.missionqueue, _sort)

  -- Get the lowest importance value (lower means more important).
  -- If a mission with importance 1 exists, mission with importance 2 will not be assigned. Missions with no importance (nil) can still be selected. 
  local vip=math.huge
  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG
    if mission.importance and mission.importance<vip then
      vip=mission.importance
    end
  end

  local missionsAssigned = 0

  -- Loop over missions in queue.
  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG
    
    -- We look for PLANNED missions.
    if mission:IsPlanned() and mission:IsReadyToGo() and (mission.importance==nil or mission.importance<=vip) and self:_CheckMissionLimit(mission.type) then
    
      ---
      -- PLANNNED Mission
      -- 
      -- 1. Select best assets from legions
      -- 2. Assign mission to legions that have the best assets.
      ---    
    
      -- Recruite assets from legions.      
      local recruited, assets, legions=self:RecruitAssetsForMission(mission)
      
      if recruited then
      
        -- Add asset to mission.
        mission:_AddAssets(assets)
        
        -- Recruit asset for escorting recruited mission assets.
        local EscortAvail=self:RecruitAssetsForEscort(mission, assets)
        
        -- Transport available (or not required).
        local TransportAvail=true
        
        -- Escort requested and available.
        if EscortAvail then

          -- Check if mission assets need a transport.
          if mission.NcarriersMin then
          
            -- Recruit carrier assets for transport.
            local Transport=nil
            local Legions=mission.transportLegions or self.legions
            
            TransportAvail, Transport=LEGION.AssignAssetsForTransport(self, Legions, assets, mission.NcarriersMin, mission.NcarriersMax, mission.transportDeployZone, mission.transportDisembarkZone, mission.carrierCategories, mission.carrierAttributes, mission.carrierProperties)
            
            -- Add opstransport to mission.
            if TransportAvail and Transport then
              mission.opstransport=Transport
            end
          
          end
          
        end
        
        -- Escort and transport must be available (or not required).
        if EscortAvail and TransportAvail then
        
          -- Add mission to legion.
          self:MissionAssign(mission, legions)
        
        else
          -- Recruited assets but no requested escort available. Unrecruit assets!
          LEGION.UnRecruitAssets(assets, mission)
        end        

        missionsAssigned = missionsAssigned + 1
        if missionsAssigned >= (self.maxMissionsAssignPerCycle or 1) then
            return
        end

      end
      
    else

      ---
      -- Missions NOT in PLANNED state
      ---    
    
    end
  
  end
  
end

--- Set how many missions can be assigned in a single status iteration. (eg. This is useful for persistent missions where you need to load all AUFTRAGs on mission start and then change it back to default)
--- Warning: Increasing this value will increase the number of missions started per iteration and thus may lead to performance issues if too many missions are started at once.
-- @param #COMMANDER self
-- @param #number Number of missions assigned per status iteration. Default is 1.
-- @return #COMMANDER self.
function COMMANDER:SetMaxMissionsAssignPerCycle(MaxMissionsAssignPerCycle)
  self.maxMissionsAssignPerCycle = MaxMissionsAssignPerCycle or 1
  return self
end

--- Get cohorts.
-- @param #COMMANDER self
-- @param #table Legions Special legions.
-- @param #table Cohorts Special cohorts.
-- @param Ops.Operation#OPERATION Operation Operation.
-- @return #table Cohorts.
function COMMANDER:_GetCohorts(Legions, Cohorts, Operation)
  
  --- Function that check if a legion or cohort is part of an operation.
  local function CheckOperation(LegionOrCohort)
    -- No operations ==> no problem!
    if #self.opsqueue==0 then
      return true
    end
    
    -- Cohort is not dedicated to a running(!) operation. We assume so.
    local isAvail=true
    
    -- Only available...
    if Operation then
      isAvail=false
    end
        
    for _,_operation in pairs(self.opsqueue) do
      local operation=_operation --Ops.Operation#OPERATION
      
      -- Legion is assigned to this operation.
      local isOps=operation:IsAssignedCohortOrLegion(LegionOrCohort)
      
      if isOps and operation:IsRunning() then
        
        -- Is dedicated.
        isAvail=false
      
        if Operation==nil then
          -- No Operation given and this is dedicated to at least one operation.
          return false
        else
          if Operation.uid==operation.uid then
            -- Operation given and is part of it.
            return true
          end        
        end
      end
    end
    
    return isAvail
  end    

  -- Chosen cohorts.
  local cohorts={}
  
  -- Check if there are any special legions and/or cohorts.
  if (Legions and #Legions>0) or (Cohorts and #Cohorts>0) then
  
    -- Add cohorts of special legions.
    for _,_legion in pairs(Legions or {}) do
      local legion=_legion --Ops.Legion#LEGION
  
      -- Check that runway is operational.
      local Runway=true
      if legion:IsAirwing() then
        Runway=legion:IsRunwayOperational() and legion.airbase and legion.airbase:GetCoalition() == legion:GetCoalition()
      end

      -- Legion has to be running.
      if legion:IsRunning() and Runway then
      
        -- Add cohorts of legion.
        for _,_cohort in pairs(legion.cohorts) do
          local cohort=_cohort --Ops.Cohort#COHORT

          if CheckOperation(cohort.legion) or CheckOperation(cohort) then
            table.insert(cohorts, cohort)
          end
        end
        
      end
    end
    
    -- Add special cohorts.
    for _,_cohort in pairs(Cohorts or {}) do
      local cohort=_cohort --Ops.Cohort#COHORT
      
      if CheckOperation(cohort) then
        table.insert(cohorts, cohort)
      end
    end
    
  else

    -- No special mission legions/cohorts found ==> take own legions.
    for _,_legion in pairs(self.legions) do
      local legion=_legion --Ops.Legion#LEGION
      
      -- Check that runway is operational.
      local Runway=true
      if legion:IsAirwing() then
        Runway=legion:IsRunwayOperational() and legion.airbase and legion.airbase:GetCoalition() == legion:GetCoalition()
      end

      -- Legion has to be running.
      if legion:IsRunning() and Runway then
      
        -- Add cohorts of legion.
        for _,_cohort in pairs(legion.cohorts) do
          local cohort=_cohort --Ops.Cohort#COHORT
          
          if CheckOperation(cohort.legion) or CheckOperation(cohort) then
            table.insert(cohorts, cohort)
          end
        end
        
      end
    end
    
  end

  return cohorts
end

--- Checks whether or not any of the legions con run a mission.
-- @param #COMMANDER self
-- @param Ops.Auftrag#AUFTRAG Mission The mission.
-- @return #boolean If `true`, one of the cohorts can run the mission.
function COMMANDER:CanMission(Mission)
    local commander = self

    -- Target position.
    local TargetVec2 = Mission:GetTargetVec2()

    local MaxWeight = nil

    if Mission.NcarriersMin then

        local legions = commander.legions
        local cohorts = nil
        if Mission.transportLegions or Mission.transportCohorts then
            legions = Mission.transportLegions
            cohorts = Mission.transportCohorts
        end

        -- Get transport cohorts.
        local Cohorts = LEGION._GetCohorts(legions, cohorts)

        -- Filter cohorts that can actually perform transport missions.
        local transportcohorts = {}
        for _, _cohort in pairs(Cohorts) do
            local cohort = _cohort --Ops.Cohort#COHORT

            -- Check if cohort can perform transport to target.
            local can = LEGION._CohortCan(cohort, AUFTRAG.Type.OPSTRANSPORT, Mission.carrierCategories, Mission.carrierAttributes, Mission.carrierProperties, nil, TargetVec2)

            -- MaxWeight of cargo assets is limited by the largets available cargo bay. We don't want to select, e.g., tanks that cannot be transported by APCs or helos.
            if can and (MaxWeight == nil or cohort.cargobayLimit > MaxWeight) then
                MaxWeight = cohort.cargobayLimit
            end
        end

    end

    local legions = commander.legions
    local cohorts = nil
    if Mission.specialLegions or Mission.specialCohorts then
        legions = Mission.specialLegions
        cohorts = Mission.specialCohorts
    end

    -- Get cohorts.
    local Cohorts = LEGION._GetCohorts(legions, cohorts, Mission.operation, commander.opsqueue)

    for _, _cohort in pairs(Cohorts) do
        local cohort = _cohort --Ops.Cohort#COHORT

        -- Check if cohort can do the mission.
        local can = LEGION._CohortCan(cohort, Mission.type, nil, Mission.attributes, Mission.properties, { Mission.engageWeaponType }, TargetVec2, Mission.engageRange, Mission.refuelSystem, nil, MaxWeight)
        if can then
            return true
        end

    end

    return false
end

--- Recruit assets for a given mission.
-- @param #COMMANDER self
-- @param Ops.Auftrag#AUFTRAG Mission The mission.
-- @return #boolean If `true` enough assets could be recruited.
-- @return #table Recruited assets.
-- @return #table Legions that have recruited assets.
function COMMANDER:RecruitAssetsForMission(Mission)

  -- Debug info.
  self:T2(self.lid..string.format("Recruiting assets for mission \"%s\" [%s]", Mission:GetName(), Mission:GetType()))

  -- Number of required assets.
  local NreqMin, NreqMax=Mission:GetRequiredAssets()

  -- Target position.
  local TargetVec2=Mission:GetTargetVec2()
  
  -- Special payloads.
  local Payloads=Mission.payloads  
  
  -- Largest cargo bay available of available carrier assets if mission assets need to be transported.
  local MaxWeight=nil
  
  if Mission.NcarriersMin then
  
    local legions=self.legions
    local cohorts=nil
    if Mission.transportLegions or Mission.transportCohorts then
      legions=Mission.transportLegions
      cohorts=Mission.transportCohorts
    end  
  
    -- Get transport cohorts.
    local Cohorts=LEGION._GetCohorts(legions, cohorts)
    
    -- Filter cohorts that can actually perform transport missions.    
    local transportcohorts={}
    for _,_cohort in pairs(Cohorts) do
      local cohort=_cohort --Ops.Cohort#COHORT
      
      -- Check if cohort can perform transport to target.
      local can=LEGION._CohortCan(cohort, AUFTRAG.Type.OPSTRANSPORT, Mission.carrierCategories, Mission.carrierAttributes, Mission.carrierProperties, nil, TargetVec2)
      
      -- MaxWeight of cargo assets is limited by the largets available cargo bay. We don't want to select, e.g., tanks that cannot be transported by APCs or helos.
      if can and (MaxWeight==nil or cohort.cargobayLimit>MaxWeight) then
        MaxWeight=cohort.cargobayLimit
      end
    end

    if MaxWeight then
        self:T(self.lid..string.format("Largest cargo bay available=%.1f", MaxWeight))
    end
  end
  
  local legions=self.legions
  local cohorts=nil
  if Mission.specialLegions or Mission.specialCohorts then
    legions=Mission.specialLegions
    cohorts=Mission.specialCohorts
  end    
  
  -- Get cohorts.
  local Cohorts=LEGION._GetCohorts(legions, cohorts, Mission.operation, self.opsqueue)
  
  -- Debug info.
  self:T(self.lid..string.format("Found %d cohort candidates for mission", #Cohorts))
  
  -- Recruite assets.
  local recruited, assets, legions=LEGION.RecruitCohortAssets(Cohorts, Mission.type, Mission.alert5MissionType, NreqMin, NreqMax, TargetVec2, Payloads,
   Mission.engageRange, Mission.refuelSystem, nil, nil, MaxWeight, nil, Mission.attributes, Mission.properties, {Mission.engageWeaponType})

  return recruited, assets, legions
end

--- Recruit assets performing an escort mission for a given asset.
-- @param #COMMANDER self
-- @param Ops.Auftrag#AUFTRAG Mission The mission.
-- @param #table Assets Table of assets to be escorted.
-- @return #boolean If `true`, enough assets could be recruited or no escort was required in the first place.
function COMMANDER:RecruitAssetsForEscort(Mission, Assets)

  -- Is an escort requested in the first place?
  if Mission.NescortMin and Mission.NescortMax and (Mission.NescortMin>0 or Mission.NescortMax>0) then

    -- Cohorts.
    local Cohorts=self:_GetCohorts(Mission.escortLegions, Mission.escortCohorts, Mission.operation)
    
    -- Call LEGION function but provide COMMANDER as self.
    local assigned=LEGION.AssignAssetsForEscort(self, Cohorts, Assets, Mission.NescortMin, Mission.NescortMax, Mission.escortMissionType, Mission.escortTargetTypes, Mission.escortEngageRange)
    
    return assigned    
  end

  return true
end

--- Recruit assets for a given TARGET.
-- @param #COMMANDER self
-- @param Ops.Target#TARGET Target The target.
-- @param #string MissionType Mission Type.
-- @param #number NassetsMin Min number of required assets.
-- @param #number NassetsMax Max number of required assets.
-- @return #boolean If `true` enough assets could be recruited.
-- @return #table Assets that have been recruited from all legions.
-- @return #table Legions that have recruited assets.
function COMMANDER:RecruitAssetsForTarget(Target, MissionType, NassetsMin, NassetsMax)

  -- Cohorts.
  local Cohorts=self:_GetCohorts()

  -- Target position.
  local TargetVec2=Target:GetVec2()
  
  -- Recruite assets.
  local recruited, assets, legions=LEGION.RecruitCohortAssets(Cohorts, MissionType, nil, NassetsMin, NassetsMax, TargetVec2)


  return recruited, assets, legions
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Transport Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Check transport queue and assign ONE planned transport.
-- @param #COMMANDER self 
function COMMANDER:CheckTransportQueue()

  -- Number of missions.
  local Ntransports=#self.transportqueue

  -- Treat special cases.
  if Ntransports==0 then
    return nil
  end

  -- Sort results table wrt prio and start time.
  local function _sort(a, b)
    local taskA=a --Ops.Auftrag#AUFTRAG
    local taskB=b --Ops.Auftrag#AUFTRAG
    return (taskA.prio<taskB.prio) or (taskA.prio==taskB.prio and taskA.Tstart<taskB.Tstart)
  end
  table.sort(self.transportqueue, _sort)

  -- Get the lowest importance value (lower means more important).
  -- If a mission with importance 1 exists, mission with importance 2 will not be assigned. Missions with no importance (nil) can still be selected. 
  local vip=math.huge
  for _,_transport in pairs(self.transportqueue) do
    local transport=_transport --Ops.OpsTransport#OPSTRANSPORT
    if transport.importance and transport.importance<vip then
      vip=transport.importance
    end
  end

  for _,_transport in pairs(self.transportqueue) do
    local transport=_transport --Ops.OpsTransport#OPSTRANSPORT
    
    -- We look for PLANNED missions.
    if transport:IsPlanned() and transport:IsReadyToGo() and (transport.importance==nil or transport.importance<=vip) then
    
      ---
      -- PLANNNED Mission
      -- 
      -- 1. Select best assets from legions
      -- 2. Assign mission to legions that have the best assets.
      ---    

      -- Get all undelivered cargo ops groups.
      local cargoOpsGroups=transport:GetCargoOpsGroups(false)
      
      -- Weight of the heaviest cargo group. Necessary condition that this fits into on carrier unit!
      local weightGroup=0
      local TotalWeight=0
      
      -- Calculate the max weight so we know which cohorts can provide carriers.
      if #cargoOpsGroups>0 then  
        for _,_opsgroup in pairs(cargoOpsGroups) do
          local opsgroup=_opsgroup --Ops.OpsGroup#OPSGROUP
          local weight=opsgroup:GetWeightTotal()
          if weight>weightGroup then
            weightGroup=weight
          end
          TotalWeight=TotalWeight+weight
        end    
      end
      
      if weightGroup>0 then
    
        -- Recruite assets from legions.      
        local recruited, assets, legions=self:RecruitAssetsForTransport(transport, weightGroup, TotalWeight)
        
        if recruited then
        
          -- Add asset to transport.
          for _,_asset in pairs(assets) do
            local asset=_asset --Functional.Warehouse#WAREHOUSE.Assetitem
            transport:AddAsset(asset)
          end        
  
          -- Assign transport to legion(s).
          self:TransportAssign(transport, legions)
      
          -- Only ONE transport is assigned.
          return
        else
          -- Not recruited.
          LEGION.UnRecruitAssets(assets)
        end
        
      end
      
    else

      ---
      -- Missions NOT in PLANNED state
      ---    
    
    end
  
  end
  
end

--- Recruit assets for a given OPS transport.
-- @param #COMMANDER self
-- @param Ops.OpsTransport#OPSTRANSPORT Transport The OPS transport.
-- @param #number CargoWeight Weight of the heaviest cargo group.
-- @param #number TotalWeight Total weight of all cargo groups.
-- @return #boolean If `true`, enough assets could be recruited.
-- @return #table Recruited assets.
-- @return #table Legions that have recruited assets.
function COMMANDER:RecruitAssetsForTransport(Transport, CargoWeight, TotalWeight)
  
  if CargoWeight==0 then
    -- No cargo groups!
    return false, {}, {}
  end
  
  -- Cohorts.
  local Cohorts=self:_GetCohorts()

  -- Target is the deploy zone.
  local TargetVec2=Transport:GetDeployZone():GetVec2()

  -- Number of required carriers.
  local NreqMin,NreqMax=Transport:GetRequiredCarriers()
  
  -- Recruit assets and legions.
  local recruited, assets, legions=LEGION.RecruitCohortAssets(Cohorts, AUFTRAG.Type.OPSTRANSPORT, nil, NreqMin, NreqMax, TargetVec2, nil, nil, nil, CargoWeight, TotalWeight)

  return recruited, assets, legions  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Resources
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Check if limit of missions has been reached.
-- @param #COMMANDER self 
-- @param #string MissionType Type of mission.
-- @return #boolean If `true`, mission limit has **not** been reached. If `false`, limit has been reached.
function COMMANDER:_CheckMissionLimit(MissionType)

  local limit=self.limitMission[MissionType]
  
  if limit then
  
    if MissionType=="Total" then
      MissionType=AUFTRAG.Type    
    end
  
    local N=self:CountMissions(MissionType, true)
    
    if N>=limit then
      return false
    end
  end
  
  return true
end


--- Count assets of all assigned legions.
-- @param #COMMANDER self
-- @param #boolean InStock If true, only assets that are in the warehouse stock/inventory are counted.
-- @param #table MissionTypes (Optional) Count only assest that can perform certain mission type(s). Default is all types.
-- @param #table Attributes (Optional) Count only assest that have a certain attribute(s), e.g. `WAREHOUSE.Attribute.AIR_BOMBER`.
-- @return #number Amount of asset groups.
function COMMANDER:CountAssets(InStock, MissionTypes, Attributes)

  local N=0
  for _,_legion in pairs(self.legions) do
    local legion=_legion --Ops.Legion#LEGION
    N=N+legion:CountAssets(InStock, MissionTypes, Attributes)
  end

  return N
end

--- Count assets of all assigned legions.
-- @param #COMMANDER self
-- @param #table MissionTypes (Optional) Count only missions of these types. Default is all types.
-- @param #boolean OnlyRunning If `true`, only count running missions.
-- @return #number Amount missions.
function COMMANDER:CountMissions(MissionTypes, OnlyRunning)

  local N=0
  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG
    
    if (not OnlyRunning) or (mission.statusCommander~=AUFTRAG.Status.PLANNED) then

      -- Check if this mission type is requested.
      if AUFTRAG.CheckMissionType(mission.type, MissionTypes) then
        N=N+1
      end
      
    end
  end


  return N
end

--- Count assets of all assigned legions.
-- @param #COMMANDER self
-- @param #boolean InStock If true, only assets that are in the warehouse stock/inventory are counted.
-- @param #table Legions (Optional) Table of legions. Default is all legions.
-- @param #table MissionTypes (Optional) Count only assest that can perform certain mission type(s). Default is all types.
-- @param #table Attributes (Optional) Count only assest that have a certain attribute(s), e.g. `WAREHOUSE.Attribute.AIR_BOMBER`.
-- @return #number Amount of asset groups.
function COMMANDER:GetAssets(InStock, Legions, MissionTypes, Attributes)

  -- Selected assets.
  local assets={}

  for _,_legion in pairs(Legions or self.legions) do
    local legion=_legion --Ops.Legion#LEGION
    
    --TODO Check if legion is running and maybe if runway is operational if air assets are requested.

    for _,_cohort in pairs(legion.cohorts) do
      local cohort=_cohort --Ops.Cohort#COHORT
      
      for _,_asset in pairs(cohort.assets) do
        local asset=_asset --Functional.Warehouse#WAREHOUSE.Assetitem
        
        -- TODO: Check if repaired.
        -- TODO: currently we take only unspawned assets.
        if not (asset.spawned or asset.isReserved or asset.requested) then
          table.insert(assets, asset)
        end
        
      end
    end
  end
  
  return assets
end

--- Check all legions if they are able to do a specific mission type at a certain location with a given number of assets.
-- @param #COMMANDER self
-- @param Ops.Auftrag#AUFTRAG Mission The mission.
-- @return #table Table of LEGIONs that can do the mission and have at least one asset available right now.
function COMMANDER:GetLegionsForMission(Mission)

  -- Table of legions that can do the mission.
  local legions={}
  
  -- Loop over all legions.
  for _,_legion in pairs(self.legions) do
    local legion=_legion --Ops.Legion#LEGION
    
    -- Count number of assets in stock.
    local Nassets=0    
    if legion:IsAirwing() then
      Nassets=legion:CountAssetsWithPayloadsInStock(Mission.payloads, {Mission.type}, Attributes)
    else    
      Nassets=legion:CountAssets(true, {Mission.type}, Attributes) --Could also specify the attribute if Air or Ground mission.
    end    
    
    -- Has it assets that can?
    if Nassets>0  and false then        
      
      -- Get coordinate of the target.
      local coord=Mission:GetTargetCoordinate()
      
      if coord then
      
        -- Distance from legion to target.
        local distance=UTILS.MetersToNM(coord:Get2DDistance(legion:GetCoordinate()))
        
        -- Round: 55 NM ==> 5.5 ==> 6, 63 NM ==> 6.3 ==> 6
        local dist=UTILS.Round(distance/10, 0)
        
        -- Debug info.
        self:T(self.lid..string.format("Got legion %s with Nassets=%d and dist=%.1f NM, rounded=%.1f", legion.alias, Nassets, distance, dist))
      
        -- Add legion to table of legions that can.
        table.insert(legions, {airwing=legion, distance=distance, dist=dist, targetcoord=coord, nassets=Nassets})
        
      end
      
    end
    
    -- Add legion if it can provide at least 1 asset.    
    if Nassets>0 then
      table.insert(legions, legion)
    end
            
  end
  
  return legions
end

--- Get assets on given mission or missions.
-- @param #COMMANDER self
-- @param #table MissionTypes Types on mission to be checked. Default all.
-- @return #table Assets on pending requests.
function COMMANDER:GetAssetsOnMission(MissionTypes)

  local assets={}

  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG

    -- Check if this mission type is requested.
    if AUFTRAG.CheckMissionType(mission.type, MissionTypes) then

      for _,_asset in pairs(mission.assets or {}) do
        local asset=_asset --Functional.Warehouse#WAREHOUSE.Assetitem
          table.insert(assets, asset)
       end
    end
  end

  return assets
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
