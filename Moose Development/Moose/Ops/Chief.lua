---- **Ops** - Chief of Staff.
--
-- **Main Features:**
--
--    * Stuff
--
-- ===
--
-- ### Author: **funkyfranky**
-- @module Ops.Chief
-- @image OPS_Chief.png


--- CHIEF class.
-- @type CHIEF
-- @field #string ClassName Name of the class.
-- @field #number verbose Verbosity level.
-- @field #string lid Class id string for output to DCS log file.
-- @field #table targetqueue Target queue.
-- @field #table zonequeue Strategic zone queue.
-- @field Core.Set#SET_ZONE borderzoneset Set of zones defining the border of our territory.
-- @field Core.Set#SET_ZONE yellowzoneset Set of zones defining the extended border. Defcon is set to YELLOW if enemy activity is detected.
-- @field Core.Set#SET_ZONE engagezoneset Set of zones where enemies are actively engaged.
-- @field #string Defcon Defence condition.
-- @field #string strategy Strategy of the CHIEF.
-- @field Ops.Commander#COMMANDER commander Commander of assigned legions.
-- @extends Ops.Intelligence#INTEL

--- Be surprised!
--
-- ===
--
-- # The CHIEF Concept
-- 
-- The Chief of staff gathers INTEL and assigns missions (AUFTRAG) the airforce, army and/or navy.
--
--
-- @field #CHIEF
CHIEF = {
  ClassName      = "CHIEF",
  verbose        =     0,
  lid            =   nil,
  targetqueue    =    {},
  zonequeue      =    {},
  borderzoneset  =   nil,
  yellowzoneset  =   nil,
  engagezoneset  =   nil,
}

--- Defence condition.
-- @type CHIEF.DEFCON
-- @field #string GREEN No enemy activities detected in our terretory or conflict zones.
-- @field #string YELLOW Enemy in conflict zones.
-- @field #string RED Enemy within our border.
CHIEF.DEFCON = {
  GREEN="Green",
  YELLOW="Yellow",
  RED="Red",
}

--- Strategy.
-- @type CHIEF.Strategy
-- @field #string PASSIVE No targets at all are engaged.
-- @field #string DEFENSIVE Only target in our own terretory are engaged.
-- @field #string OFFENSIVE Targets in own terretory and yellow zones are engaged.
-- @field #string AGGRESSIVE Targets in own terretory, conflict zones and attack zones are engaged.
-- @field #string TOTALWAR Anything is engaged anywhere.
CHIEF.Strategy = {
  PASSIVE="Passive",
  DEFENSIVE="Defensive",
  OFFENSIVE="Offensive",
  AGGRESSIVE="Aggressive",
  TOTALWAR="Total War"
}

--- Mission performance.
-- @type CHIEF.MissionPerformance
-- @field #string MissionType Mission Type.
-- @field #number Performance Performance: a number between 0 and 100, where 100 is best performance.

--- Strategic zone.
-- @type CHIEF.StrategicZone
-- @field Ops.OpsZone#OPSZONE opszone OPS zone.
-- @field #number prio Priority.
-- @field #number importance Importance
-- @field Ops.Auftrag#AUFTRAG missionPatrol Patrol mission.
-- @field Ops.Auftrag#AUFTRAG missionCAS CAS mission.


--- CHIEF class version.
-- @field #string version
CHIEF.version="0.0.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Tactical overview.
-- DONE: Add event for opsgroups on mission.
-- DONE: Add event for zone captured. 
-- TODO: Limits of missions?
-- DONE: Create a good mission, which can be passed on to the COMMANDER.
-- DONE: Capture OPSZONEs.
-- DONE: Get list of own assets and capabilities.
-- DONE: Get list/overview of enemy assets etc.
-- DONE: Put all contacts into target list. Then make missions from them.
-- DONE: Set of interesting zones.
-- DONE: Add/remove spawned flightgroups to detection set.
-- DONE: Borderzones.
-- NOGO: Maybe it's possible to preselect the assets for the mission.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new CHIEF object and start the FSM.
-- @param #CHIEF self
-- @param Core.Set#SET_GROUP AgentSet Set of agents (groups) providing intel. Default is an empty set.
-- @param #number Coalition Coalition side, e.g. `coaliton.side.BLUE`. Can also be passed as a string "red", "blue" or "neutral".
-- @param #string Alias An *optional* alias how this object is called in the logs etc.
-- @return #CHIEF self
function CHIEF:New(AgentSet, Coalition, Alias)

  -- Set alias.
  Alias=Alias or "CHIEF"

  -- Inherit everything from INTEL class.
  local self=BASE:Inherit(self, INTEL:New(AgentSet, Coalition, Alias)) --#CHIEF

  -- Defaults.
  self:SetBorderZones()
  self:SetConflictZones()
  self:SetAttackZones()
  self:SetThreatLevelRange()
  
  -- Init stuff.
  self.Defcon=CHIEF.DEFCON.GREEN
  self.strategy=CHIEF.Strategy.DEFENSIVE
  
  -- Create a new COMMANDER.
  self.commander=COMMANDER:New(Coalition)  

  -- Add FSM transitions.
  --                 From State   -->    Event                     -->    To State
  self:AddTransition("*",                "MissionAssign",                 "*")   -- Assign mission to a COMMANDER.  
  self:AddTransition("*",                "MissionCancel",                 "*")   -- Cancel mission.
  
  self:AddTransition("*",                "TransportCancel",               "*")   -- Cancel transport.
  
  self:AddTransition("*",                "OpsOnMission",                  "*")   -- An OPSGROUP was send on a Mission (AUFTRAG).
  
  self:AddTransition("*",                "ZoneCaptured",                  "*")   -- 
  self:AddTransition("*",                "ZoneLost",                      "*")   --
  self:AddTransition("*",                "ZoneEmpty",                     "*")   --
  self:AddTransition("*",                "ZoneAttacked",                  "*")   --
  
  self:AddTransition("*",                "DefconChange",                  "*")   -- Change defence condition. 
  self:AddTransition("*",                "StrategyChange",                "*")   -- Change strategy condition.

  ------------------------
  --- Pseudo Functions ---
  ------------------------

  --- Triggers the FSM event "Start".
  -- @function [parent=#CHIEF] Start
  -- @param #CHIEF self

  --- Triggers the FSM event "Start" after a delay.
  -- @function [parent=#CHIEF] __Start
  -- @param #CHIEF self
  -- @param #number delay Delay in seconds.


  --- Triggers the FSM event "Stop".
  -- @param #CHIEF self

  --- Triggers the FSM event "Stop" after a delay.
  -- @function [parent=#CHIEF] __Stop
  -- @param #CHIEF self
  -- @param #number delay Delay in seconds.


  --- Triggers the FSM event "Status".
  -- @function [parent=#CHIEF] Status
  -- @param #CHIEF self

  --- Triggers the FSM event "Status" after a delay.
  -- @function [parent=#CHIEF] __Status
  -- @param #CHIEF self
  -- @param #number delay Delay in seconds.


  --- Triggers the FSM event "DefconChange".
  -- @function [parent=#CHIEF] DefconChange
  -- @param #CHIEF self
  -- @param #string Defcon New Defence Condition.

  --- Triggers the FSM event "DefconChange" after a delay.
  -- @function [parent=#CHIEF] __DefconChange
  -- @param #CHIEF self
  -- @param #number delay Delay in seconds.
  -- @param #string Defcon New Defence Condition.

  --- On after "DefconChange" event.
  -- @function [parent=#CHIEF] OnAfterDefconChange
  -- @param #CHIEF self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #string Defcon New Defence Condition.


  --- Triggers the FSM event "StrategyChange".
  -- @function [parent=#CHIEF] StrategyChange
  -- @param #CHIEF self
  -- @param #string Strategy New strategy.

  --- Triggers the FSM event "StrategyChange" after a delay.
  -- @function [parent=#CHIEF] __StrategyChange
  -- @param #CHIEF self
  -- @param #number delay Delay in seconds.
  -- @param #string Strategy New strategy.

  --- On after "StrategyChange" event.
  -- @function [parent=#CHIEF] OnAfterStrategyChange
  -- @param #CHIEF self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #string Strategy New stragegy.


  --- Triggers the FSM event "MissionAssign".
  -- @function [parent=#CHIEF] MissionAssign
  -- @param #CHIEF self
  -- @param Ops.Legion#LEGION Legion The legion.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.

  --- Triggers the FSM event "MissionAssign" after a delay.
  -- @function [parent=#CHIEF] __MissionAssign
  -- @param #CHIEF self
  -- @param #number delay Delay in seconds.
  -- @param Ops.Legion#LEGION Legion The legion.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.

  --- On after "MissionAssign" event.
  -- @function [parent=#CHIEF] OnAfterMissionAssign
  -- @param #CHIEF self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.Legion#LEGION Legion The legion.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.


  --- Triggers the FSM event "MissionCancel".
  -- @function [parent=#CHIEF] MissionCancel
  -- @param #CHIEF self
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.

  --- Triggers the FSM event "MissionCancel" after a delay.
  -- @function [parent=#CHIEF] __MissionCancel
  -- @param #CHIEF self
  -- @param #number delay Delay in seconds.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.

  --- On after "MissionCancel" event.
  -- @function [parent=#CHIEF] OnAfterMissionCancel
  -- @param #CHIEF self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.


  --- Triggers the FSM event "TransportCancel".
  -- @function [parent=#CHIEF] TransportCancel
  -- @param #CHIEF self
  -- @param Ops.OpsTransport#OPSTRANSPORT Transport The transport.

  --- Triggers the FSM event "TransportCancel" after a delay.
  -- @function [parent=#CHIEF] __TransportCancel
  -- @param #CHIEF self
  -- @param #number delay Delay in seconds.
  -- @param Ops.OpsTransport#OPSTRANSPORT Transport The transport.

  --- On after "TransportCancel" event.
  -- @function [parent=#CHIEF] OnAfterTransportCancel
  -- @param #CHIEF self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.OpsTransport#OPSTRANSPORT Transport The transport.


  --- Triggers the FSM event "OpsOnMission".
  -- @function [parent=#CHIEF] OpsOnMission
  -- @param #CHIEF self
  -- @param Ops.OpsGroup#OPSGROUP OpsGroup The OPS group on mission.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.

  --- Triggers the FSM event "OpsOnMission" after a delay.
  -- @function [parent=#CHIEF] __OpsOnMission
  -- @param #CHIEF self
  -- @param #number delay Delay in seconds.
  -- @param Ops.OpsGroup#OPSGROUP OpsGroup The OPS group on mission.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.

  --- On after "OpsOnMission" event.
  -- @function [parent=#CHIEF] OnAfterOpsOnMission
  -- @param #CHIEF self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.OpsGroup#OPSGROUP OpsGroup The OPS group on mission.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.


  --- Triggers the FSM event "ZoneCaptured".
  -- @function [parent=#CHIEF] ZoneCaptured
  -- @param #CHIEF self
  -- @param Ops.OpsZone#OPSZONE OpsZone Zone that was captured.

  --- Triggers the FSM event "ZoneCaptured" after a delay.
  -- @function [parent=#CHIEF] __ZoneCaptured
  -- @param #CHIEF self
  -- @param #number delay Delay in seconds.
  -- @param Ops.OpsZone#OPSZONE OpsZone Zone that was captured.

  --- On after "ZoneCaptured" event.
  -- @function [parent=#CHIEF] OnAfterZoneCaptured
  -- @param #CHIEF self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.OpsZone#OPSZONE OpsZone Zone that was captured. 

  --- Triggers the FSM event "ZoneLost".
  -- @function [parent=#CHIEF] ZoneLost
  -- @param #CHIEF self
  -- @param Ops.OpsZone#OPSZONE OpsZone Zone that was lost.

  --- Triggers the FSM event "ZoneLost" after a delay.
  -- @function [parent=#CHIEF] __ZoneLost
  -- @param #CHIEF self
  -- @param #number delay Delay in seconds.
  -- @param Ops.OpsZone#OPSZONE OpsZone Zone that was lost.

  --- On after "ZoneLost" event.
  -- @function [parent=#CHIEF] OnAfterZoneLost
  -- @param #CHIEF self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.OpsZone#OPSZONE OpsZone Zone that was lost. 

  --- Triggers the FSM event "ZoneEmpty".
  -- @function [parent=#CHIEF] ZoneEmpty
  -- @param #CHIEF self
  -- @param Ops.OpsZone#OPSZONE OpsZone Zone that is empty now.

  --- Triggers the FSM event "ZoneEmpty" after a delay.
  -- @function [parent=#CHIEF] __ZoneEmpty
  -- @param #CHIEF self
  -- @param #number delay Delay in seconds.
  -- @param Ops.OpsZone#OPSZONE OpsZone Zone that is empty now.

  --- On after "ZoneEmpty" event.
  -- @function [parent=#CHIEF] OnAfterZoneEmpty
  -- @param #CHIEF self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.OpsZone#OPSZONE OpsZone Zone that is empty now.

  --- Triggers the FSM event "ZoneAttacked".
  -- @function [parent=#CHIEF] ZoneAttacked
  -- @param #CHIEF self
  -- @param Ops.OpsZone#OPSZONE OpsZone Zone that is beeing attacked.

  --- Triggers the FSM event "ZoneAttacked" after a delay.
  -- @function [parent=#CHIEF] __ZoneAttacked
  -- @param #CHIEF self
  -- @param #number delay Delay in seconds.
  -- @param Ops.OpsZone#OPSZONE OpsZone Zone that is beeing attacked.

  --- On after "ZoneAttacked" event.
  -- @function [parent=#CHIEF] OnAfterZoneAttacked
  -- @param #CHIEF self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.OpsZone#OPSZONE OpsZone Zone that is beeing attacked. 

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set this to be an air-to-any dispatcher, i.e. engaging air, ground and naval targets. This is the default anyway.
-- @param #CHIEF self
-- @return #CHIEF self
function CHIEF:SetAirToAny()

  self:SetFilterCategory({})
  
  return self
end

--- Set this to be an air-to-air dispatcher.
-- @param #CHIEF self
-- @return #CHIEF self
function CHIEF:SetAirToAir()

  self:SetFilterCategory({Unit.Category.AIRPLANE, Unit.Category.HELICOPTER})
  
  return self
end

--- Set this to be an air-to-ground dispatcher, i.e. engage only ground units
-- @param #CHIEF self
-- @return #CHIEF self
function CHIEF:SetAirToGround()

  self:SetFilterCategory({Unit.Category.GROUND_UNIT})
  
  return self
end

--- Set this to be an air-to-sea dispatcher, i.e. engage only naval units.
-- @param #CHIEF self
-- @return #CHIEF self
function CHIEF:SetAirToSea()

  self:SetFilterCategory({Unit.Category.SHIP})
  
  return self
end

--- Set this to be an air-to-surface dispatcher, i.e. engaging ground and naval groups.
-- @param #CHIEF self
-- @return #CHIEF self
function CHIEF:SetAirToSurface()

  self:SetFilterCategory({Unit.Category.GROUND_UNIT, Unit.Category.SHIP})
  
  return self
end

--- Set a threat level range that will be engaged. Threat level is a number between 0 and 10, where 10 is a very dangerous threat.
-- Targets with threat level 0 are usually harmless.
-- @param #CHIEF self
-- @param #number ThreatLevelMin Min threat level. Default 1.
-- @param #number ThreatLevelMax Max threat level. Default 10.
-- @return #CHIEF self
function CHIEF:SetThreatLevelRange(ThreatLevelMin, ThreatLevelMax)

  self.threatLevelMin=ThreatLevelMin or 1
  self.threatLevelMax=ThreatLevelMax or 10
  
  return self
end

--- Set defence condition.
-- @param #CHIEF self
-- @param #string Defcon Defence condition. See @{#CHIEF.DEFCON}, e.g. `CHIEF.DEFCON.RED`.
-- @return #CHIEF self
function CHIEF:SetDefcon(Defcon)

  -- Check if valid string was passed.
  local gotit=false
  for _,defcon in pairs(CHIEF.DEFCON) do
    if defcon==Defcon then
      gotit=true
    end
  end  
  if not gotit then
    self:E(self.lid..string.format("ERROR: Unknown DEFCON specified! Dont know defcon=%s", tostring(Defcon)))
    return self
  end
  
  -- Trigger event if defcon changed.
  if Defcon~=self.Defcon then
    self:DefconChange(Defcon)
  end

  -- Set new DEFCON.
  self.Defcon=Defcon
  
  return self
end

--- Get defence condition.
-- @param #CHIEF self
-- @param #string Current Defence condition. See @{#CHIEF.DEFCON}, e.g. `CHIEF.DEFCON.RED`.
function CHIEF:GetDefcon(Defcon)  
  return self.Defcon
end

--- Set stragegy.
-- @param #CHIEF self
-- @param #string Strategy Strategy. See @{#CHIEF.Stragegy}, e.g. `CHIEF.Strategy.DEFENSIVE` (default).
-- @return #CHIEF self
function CHIEF:SetStragety(Strategy)

  -- Trigger event if Strategy changed.
  if Strategy~=self.strategy then
    self:StrategyChange(Strategy)
  end

  -- Set new Strategy.
  self.strategy=Strategy
  
  return self
end

--- Get defence condition.
-- @param #CHIEF self
-- @param #string Current Defence condition. See @{#CHIEF.DEFCON}, e.g. `CHIEF.DEFCON.RED`.
function CHIEF:GetDefcon(Defcon)  
  return self.Defcon
end


--- Get the commander.
-- @param #CHIEF self
-- @return Ops.Commander#COMMANDER The commander.
function CHIEF:GetCommander()
  return self.commander
end


--- Add an AIRWING to the chief's commander.
-- @param #CHIEF self
-- @param Ops.AirWing#AIRWING Airwing The airwing to add.
-- @return #CHIEF self
function CHIEF:AddAirwing(Airwing)

  -- Add airwing to the commander.
  self:AddLegion(Airwing)
  
  return self
end

--- Add a BRIGADE to the chief's commander.
-- @param #CHIEF self
-- @param Ops.Brigade#BRIGADE Brigade The brigade to add.
-- @return #CHIEF self
function CHIEF:AddBrigade(Brigade)

  -- Add brigade to the commander
  self:AddLegion(Brigade)
  
  return self
end

--- Add a LEGION to the chief's commander.
-- @param #CHIEF self
-- @param Ops.Legion#LEGION Legion The legion to add.
-- @return #CHIEF self
function CHIEF:AddLegion(Legion)

  -- Set chief of the legion.
  Legion.chief=self

  -- Add legion to the commander.
  self.commander:AddLegion(Legion)
  
  return self
end


--- Add mission to mission queue of the COMMANDER.
-- @param #CHIEF self
-- @param Ops.Auftrag#AUFTRAG Mission Mission to be added.
-- @return #CHIEF self
function CHIEF:AddMission(Mission)

  Mission.chief=self
  
  self.commander:AddMission(Mission)
  
  return self
end

--- Remove mission from queue.
-- @param #CHIEF self
-- @param Ops.Auftrag#AUFTRAG Mission Mission to be removed.
-- @return #CHIEF self
function CHIEF:RemoveMission(Mission)

  Mission.chief=nil
  
  self.commander:RemoveMission(Mission)

  return self
end

--- Add transport to transport queue of the COMMANDER.
-- @param #CHIEF self
-- @param Ops.OpsTransport#OPSTRANSPORT Transport Transport to be added.
-- @return #CHIEF self
function CHIEF:AddOpsTransport(Transport)

  Transport.chief=self
  
  self.commander:AddOpsTransport(Transport)
  
  return self
end

--- Remove transport from queue.
-- @param #CHIEF self
-- @param Ops.OpsTransport#OPSTRANSPORT Transport Transport to be removed.
-- @return #CHIEF self
function CHIEF:RemoveTransport(Transport)

  Transport.chief=nil
  
  self.commander:RemoveTransport(Transport)

  return self
end

--- Add target.
-- @param #CHIEF self
-- @param Ops.Target#TARGET Target Target object to be added.
-- @return #CHIEF self
function CHIEF:AddTarget(Target)

  if not self:IsTarget(Target) then
    table.insert(self.targetqueue, Target)
  end

  return self
end

--- Check if a TARGET is already in the queue. 
-- @param #CHIEF self
-- @param Ops.Target#TARGET Target Target object to be added.
-- @return #boolean If `true`, target exists in the target queue.
function CHIEF:IsTarget(Target)

  for _,_target in pairs(self.targetqueue) do
    local target=_target --Ops.Target#TARGET
    if target.uid==Target.uid or target:GetName()==Target:GetName() then
      return true
    end
  end

  return false
end

--- Remove target from queue.
-- @param #CHIEF self
-- @param Ops.Target#TARGET Target The target.
-- @return #CHIEF self
function CHIEF:RemoveTarget(Target)

  for i,_target in pairs(self.targetqueue) do
    local target=_target --Ops.Target#TARGET
    
    if target.uid==Target.uid then
      self:I(self.lid..string.format("Removing target %s from queue", Target.name))
      table.remove(self.targetqueue, i)
      break
    end
    
  end

  return self
end

--- Add strategically important zone.
-- @param #CHIEF self
-- @param Ops.OpsZone#OPSZONE OpsZone OPS zone object.
-- @param #number Priority Priority.
-- @param #number Importance Importance.
-- @return #CHIEF self
function CHIEF:AddStrateticZone(OpsZone, Priority, Importance)

  local stratzone={} --#CHIEF.StrategicZone
  
  stratzone.opszone=OpsZone
  stratzone.prio=Priority or 50
  stratzone.importance=Importance

  -- Start ops zone.
  if OpsZone:IsStopped() then
    OpsZone:Start()
  end

  -- Add to table.
  table.insert(self.zonequeue, stratzone)
  
  -- Add chief so we get informed when something happens.
  OpsZone:_AddChief(self)

  return self
end

--- Add a rearming zone.
-- @param #CHIEF self
-- @param Core.Zone#ZONE RearmingZone Rearming zone.
-- @return Ops.Brigade#BRIGADE.SupplyZone The rearming zone data.
function CHIEF:AddRearmingZone(RearmingZone)

  -- Hand over to commander.
  local supplyzone=self.commander:AddRearmingZone(RearmingZone)

  return supplyzone
end

--- Add a refuelling zone.
-- @param #CHIEF self
-- @param Core.Zone#ZONE RefuellingZone Refuelling zone.
-- @return Ops.Brigade#BRIGADE.SupplyZone The refuelling zone data.
function CHIEF:AddRefuellingZone(RefuellingZone)

  -- Hand over to commander.
  local supplyzone=self.commander:AddRefuellingZone(RefuellingZone)

  return supplyzone
end

--- Add a CAP zone.
-- @param #CHIEF self
-- @param Core.Zone#ZONE Zone Zone.
-- @param #number Altitude Orbit altitude in feet. Default is 12,0000 feet.
-- @param #number Speed Orbit speed in KIAS. Default 350 kts.
-- @param #number Heading Heading of race-track pattern in degrees. Default 270 (East to West).
-- @param #number Leg Length of race-track in NM. Default 30 NM.
-- @return Ops.AirWing#AIRWING.PatrolZone The CAP zone data.
function CHIEF:AddCapZone(Zone, Altitude, Speed, Heading, Leg)

  -- Hand over to commander.
  local zone=self.commander:AddCapZone(Zone, Altitude, Speed, Heading, Leg)

  return zone
end


--- Add an AWACS zone.
-- @param #CHIEF self
-- @param Core.Zone#ZONE Zone Zone.
-- @param #number Altitude Orbit altitude in feet. Default is 12,0000 feet.
-- @param #number Speed Orbit speed in KIAS. Default 350 kts.
-- @param #number Heading Heading of race-track pattern in degrees. Default 270 (East to West).
-- @param #number Leg Length of race-track in NM. Default 30 NM.
-- @return Ops.AirWing#AIRWING.PatrolZone The AWACS zone data.
function CHIEF:AddAwacsZone(Zone, Altitude, Speed, Heading, Leg)

  -- Hand over to commander.
  local zone=self.commander:AddAwacsZone(Zone, Altitude, Speed, Heading, Leg)

  return zone
end

--- Add a refuelling tanker zone.
-- @param #CHIEF self
-- @param Core.Zone#ZONE Zone Zone.
-- @param #number Altitude Orbit altitude in feet. Default is 12,0000 feet.
-- @param #number Speed Orbit speed in KIAS. Default 350 kts.
-- @param #number Heading Heading of race-track pattern in degrees. Default 270 (East to West).
-- @param #number Leg Length of race-track in NM. Default 30 NM.
-- @param #number RefuelSystem Refuelling system.
-- @return Ops.AirWing#AIRWING.TankerZone The tanker zone data.
function CHIEF:AddTankerZone(Zone, Altitude, Speed, Heading, Leg, RefuelSystem)

  -- Hand over to commander.
  local zone=self.commander:AddTankerZone(Zone, Altitude, Speed, Heading, Leg, RefuelSystem)

  return zone
end


--- Set border zone set, defining your territory.
-- 
-- * Detected enemy troops in these zones will trigger defence condition `RED`.
-- * Enemies in these zones will only be engaged if strategy is at least `CHIEF.STRATEGY.DEFENSIVE`.
-- 
-- @param #CHIEF self
-- @param Core.Set#SET_ZONE BorderZoneSet Set of zones, defining our borders.
-- @return #CHIEF self
function CHIEF:SetBorderZones(BorderZoneSet)

  -- Border zones.
  self.borderzoneset=BorderZoneSet or SET_ZONE:New()
  
  return self
end

--- Add a zone defining your territory.
-- 
-- * Detected enemy troops in these zones will trigger defence condition `RED`.
-- * Enemies in these zones will only be engaged if strategy is at least `CHIEF.STRATEGY.DEFENSIVE`.
-- 
-- @param #CHIEF self
-- @param Core.Zone#ZONE Zone The zone.
-- @return #CHIEF self
function CHIEF:AddBorderZone(Zone)

  -- Add a border zone.
  self.borderzoneset:AddZone(Zone)
  
  return self
end

--- Set conflict zone set.
-- 
-- * Detected enemy troops in these zones will trigger defence condition `YELLOW`.
-- * Enemies in these zones will only be engaged if strategy is at least `CHIEF.STRATEGY.OFFENSIVE`.
-- 
-- @param #CHIEF self
-- @param Core.Set#SET_ZONE ZoneSet Set of zones.
-- @return #CHIEF self
function CHIEF:SetConflictZones(ZoneSet)

  -- Conflict zones.
  self.yellowzoneset=ZoneSet or SET_ZONE:New()
  
  return self
end

--- Add a conflict zone.
-- 
-- * Detected enemy troops in these zones will trigger defence condition `YELLOW`.
-- * Enemies in these zones will only be engaged if strategy is at least `CHIEF.STRATEGY.OFFENSIVE`.
-- 
-- @param #CHIEF self
-- @param Core.Zone#ZONE Zone The zone to add.
-- @return #CHIEF self
function CHIEF:AddConflictZone(Zone)

  -- Add a conflict zone.
  self.yellowzoneset:AddZone(Zone)
  
  return self
end

--- Set attack zone set.
-- 
-- * Enemies in these zones will only be engaged if strategy is at least `CHIEF.STRATEGY.AGGRESSIVE`.
-- 
-- @param #CHIEF self
-- @param Core.Set#SET_ZONE ZoneSet Set of zones.
-- @return #CHIEF self
function CHIEF:SetAttackZones(ZoneSet)

  -- Attacak zones.
  self.engagezoneset=ZoneSet or SET_ZONE:New()
  
  return self
end

--- Add an attack zone.
-- 
-- * Enemies in these zones will only be engaged if strategy is at least `CHIEF.STRATEGY.AGGRESSIVE`.
-- 
-- @param #CHIEF self
-- @param Core.Zone#ZONE Zone The zone to add.
-- @return #CHIEF self
function CHIEF:AddAttackZone(Zone)

  -- Add an attack zone.
  self.engagezoneset:AddZone(Zone)
  
  return self
end

--- Check if current strategy is passive.
-- @param #CHIEF self
-- @return #boolean If `true`, strategy is passive.
function CHIEF:IsPassive()
  return self.strategy==CHIEF.Strategy.PASSIVE
end

--- Check if current strategy is defensive.
-- @param #CHIEF self
-- @return #boolean If `true`, strategy is defensive.
function CHIEF:IsDefensive()
  return self.strategy==CHIEF.Strategy.DEFENSIVE
end

--- Check if current strategy is offensive.
-- @param #CHIEF self
-- @return #boolean If `true`, strategy is offensive.
function CHIEF:IsOffensive()
  return self.strategy==CHIEF.Strategy.OFFENSIVE
end

--- Check if current strategy is aggressive.
-- @param #CHIEF self
-- @return #boolean If `true`, strategy is agressive.
function CHIEF:IsAgressive()
  return self.strategy==CHIEF.Strategy.AGGRESSIVE
end

--- Check if current strategy is total war.
-- @param #CHIEF self
-- @return #boolean If `true`, strategy is total war.
function CHIEF:IsTotalWar()
  return self.strategy==CHIEF.Strategy.TOTALWAR
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Start & Status
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after Start event.
-- @param #CHIEF self
-- @param Wrapper.Group#GROUP Group Flight group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function CHIEF:onafterStart(From, Event, To)

  -- Short info.
  local text=string.format("Starting Chief of Staff")
  self:I(self.lid..text)

  -- Start parent INTEL.
  self:GetParent(self).onafterStart(self, From, Event, To)
  
  -- Start commander.
  if self.commander then
    if self.commander:GetState()=="NotReadyYet" then
      self.commander:Start()
    end
  end

end

--- On after "Status" event.
-- @param #CHIEF self
-- @param Wrapper.Group#GROUP Group Flight group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function CHIEF:onafterStatus(From, Event, To)

  -- Start parent INTEL.
  self:GetParent(self).onafterStatus(self, From, Event, To)

  -- FSM state.
  local fsmstate=self:GetState()

  ---
  -- CONTACTS: Mission Cleanup
  ---

  -- Clean up missions where the contact was lost.
  for _,_contact in pairs(self.ContactsLost) do
    local contact=_contact --Ops.Intelligence#INTEL.Contact
    
    if contact.mission and contact.mission:IsNotOver() then
    
      -- Debug info.
      local text=string.format("Lost contact to target %s! %s mission %s will be cancelled.", contact.groupname, contact.mission.type:upper(), contact.mission.name)
      MESSAGE:New(text, 120, "CHIEF"):ToAll()
      self:I(self.lid..text)
    
      -- Cancel this mission.
      contact.mission:Cancel()
          
    end
    
    -- Remove a target from the queue.
    if contact.target then
      self:RemoveTarget(contact.target)
    end    
    
  end

  ---
  -- CONTACTS: Create new TARGETS
  ---
  
  -- Create TARGETs for all new contacts.
  local Nborder=0 ; local Nconflict=0 ; local Nattack=0
  for _,_contact in pairs(self.Contacts) do
    local contact=_contact    --Ops.Intelligence#INTEL.Contact
    local group=contact.group --Wrapper.Group#GROUP
    
    -- Check if contact inside of our borders.
    local inred=self:CheckGroupInBorder(group)
    if inred then
      Nborder=Nborder+1
    end
    
    -- Check if contact is in the conflict zones.
    local inyellow=self:CheckGroupInConflict(group)
    if inyellow then
      Nconflict=Nconflict+1
    end
    
    -- Check if contact is in the attack zones.
    local inattack=self:CheckGroupInAttack(group)
    if inattack then
      Nattack=Nattack+1
    end
    

    -- Check if this is not already a target.
    if not contact.target then

      -- Create a new TARGET of the contact group.
      local Target=TARGET:New(contact.group)
      
      -- Set to contact.
      contact.target=Target
      
      -- Set contact to target. Might be handy.
      Target.contact=contact
      
      -- Add target to queue.
      self:AddTarget(Target)

    end

  end
  
  ---
  -- Defcon
  ---
  
  -- TODO: Need to introduce time check to avoid fast oscillation between different defcon states in case groups move in and out of the zones.
  if Nborder>0 then
    self:SetDefcon(CHIEF.DEFCON.RED)
  elseif Nconflict>0 then
    self:SetDefcon(CHIEF.DEFCON.YELLOW)
  else
    self:SetDefcon(CHIEF.DEFCON.GREEN)
  end
  
  ---
  -- Check Target Queue
  ---
    
  -- Check target queue and assign missions to new targets.
  self:CheckTargetQueue()
  
  ---
  -- Check Strategic Zone Queue
  ---
    
  -- Check target queue and assign missions to new targets.
  self:CheckOpsZoneQueue()  
  
  ---
  -- Info General
  ---  
  
  if self.verbose>=1 then
    local Nassets=self.commander:CountAssets()
    local Ncontacts=#self.Contacts
    local Nmissions=#self.commander.missionqueue
    local Ntargets=#self.targetqueue
    
    -- Info message
    local text=string.format("Defcon=%s Strategy=%s: Assets=%d, Contacts=%d [Border=%d, Conflict=%d, Attack=%d], Targets=%d, Missions=%d", 
    self.Defcon, self.strategy, Nassets, Ncontacts, Nborder, Nconflict, Nattack, Ntargets, Nmissions)
    self:I(self.lid..text)
    
  end
  
  ---
  -- Info Contacts
  ---
  
  -- Info about contacts.
  if self.verbose>=2 and #self.Contacts>0 then
    local text="Contacts:"
    for i,_contact in pairs(self.Contacts) do
      local contact=_contact --Ops.Intelligence#INTEL.Contact
      local mtext="N/A"
      if contact.mission then
        mtext=string.format("Mission %s (%s) %s", contact.mission.name, contact.mission.type, contact.mission.status:upper())
      end
      text=text..string.format("\n[%d] %s Type=%s (%s): Threat=%d Mission=%s", i, contact.groupname, contact.categoryname, contact.typename, contact.threatlevel, mtext)
    end
    self:I(self.lid..text)
  end

  ---
  -- Info Targets
  ---

  if self.verbose>=3 and #self.targetqueue>0 then
    local text="Targets:"
    for i,_target in pairs(self.targetqueue) do
      local target=_target --Ops.Target#TARGET
      
      text=text..string.format("\n[%d] %s: Category=%s, prio=%d, importance=%d, alive=%s [%.1f/%.1f]",
      i, target:GetName(), target.category, target.prio, target.importance or -1, tostring(target:IsAlive()), target:GetLife(), target:GetLife0())
          
    end
    self:I(self.lid..text)
  end

  ---
  -- Info Missions
  ---
  
  -- Mission queue.
  if self.verbose>=4 and #self.commander.missionqueue>0 then
    local text="Mission queue:"
    for i,_mission in pairs(self.commander.missionqueue) do
      local mission=_mission --Ops.Auftrag#AUFTRAG
      
      local target=mission:GetTargetName() or "unknown"
      
      text=text..string.format("\n[%d] %s (%s): status=%s, target=%s", i, mission.name, mission.type, mission.status, target)
    end
    self:I(self.lid..text)
  end
  
  ---
  -- Info Strategic Zones
  ---

  -- Loop over targets.
  if self.verbose>=4 and #self.zonequeue>0 then
    local text="Zone queue:"  
    for i,_stratzone in pairs(self.zonequeue) do
      local stratzone=_stratzone --#CHIEF.StrategicZone
      
      -- OPS zone object.
      local opszone=stratzone.opszone
      
      local owner=UTILS.GetCoalitionName(opszone.ownerCurrent)
      local prevowner=UTILS.GetCoalitionName(opszone.ownerPrevious)
      
      text=text..string.format("\n[%d] %s [%s]: owner=%s [%s] (prio=%d, importance=%s): Blue=%d, Red=%d, Neutral=%d", 
      i, opszone.zone:GetName(), opszone:GetState(), owner, prevowner, stratzone.prio, tostring(stratzone.importance), opszone.Nblu, opszone.Nred, opszone.Nnut)
            
    end
    self:I(self.lid..text)
  end
  

  ---
  -- Info Assets
  ---

  if self.verbose>=5 then
    local text="Assets:"
    for _,missiontype in pairs(AUFTRAG.Type) do
      local N=self.commander:CountAssets(nil, missiontype)
      if N>0 then
        text=text..string.format("\n- %s: %d", missiontype, N)
      end
    end
    self:I(self.lid..text)
    
    local text="Assets:"
    for _,attribute in pairs(WAREHOUSE.Attribute) do
      local N=self.commander:CountAssets(nil, nil, attribute)
      if N>0 or self.verbose>=10 then
        text=text..string.format("\n- %s: %d", attribute, N)
      end
    end
    self:I(self.lid..text)
  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Events
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after "MissionAssignToAny" event.
-- @param #CHIEF self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.Legion#LEGION Legion The legion.
-- @param Ops.Auftrag#AUFTRAG Mission The mission.
function CHIEF:onafterMissionAssign(From, Event, To, Legion, Mission)

  if self.commander then
    self:I(self.lid..string.format("Assigning mission %s (%s) to COMMANDER", Mission.name, Mission.type))
    Mission.chief=self
    Mission.statusChief=AUFTRAG.Status.QUEUED
    self.commander:MissionAssign(Legion, Mission)
  else
    self:E(self.lid..string.format("Mission cannot be assigned as no COMMANDER is defined!"))
  end

end

--- On after "MissionCancel" event.
-- @param #CHIEF self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.Auftrag#AUFTRAG Mission The mission.
function CHIEF:onafterMissionCancel(From, Event, To, Mission)

  -- Debug info.
  self:I(self.lid..string.format("Cancelling mission %s (%s) in status %s", Mission.name, Mission.type, Mission.status))
  
  -- Set status to CANCELLED.
  Mission.statusChief=AUFTRAG.Status.CANCELLED  
  
  if Mission:IsPlanned() then
  
    -- Mission is still in planning stage. Should not have any LEGIONS assigned ==> Just remove it form the COMMANDER queue.
    self:RemoveMission(Mission)
    
  else
  
    -- COMMANDER will cancel mission.
    if Mission.commander then
      Mission.commander:MissionCancel(Mission)
    end
    
  end

end

--- On after "TransportCancel" event.
-- @param #CHIEF self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.OpsTransport#OPSTRANSPORT Transport The transport.
function CHIEF:onafterTransportCancel(From, Event, To, Transport)

  -- Debug info.
  self:I(self.lid..string.format("Cancelling transport UID=%d in status %s", Transport.uid, Transport:GetState()))
  
  if Transport:IsPlanned() then
  
    -- Mission is still in planning stage. Should not have any LEGIONS assigned ==> Just remove it form the COMMANDER queue.
    self:RemoveTransport(Transport)
    
  else
  
    -- COMMANDER will cancel mission.
    if Transport.commander then
      Transport.commander:TransportCancel(Transport)
    end
    
  end

end

--- On after "DefconChange" event.
-- @param #CHIEF self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #string Defcon New defence condition.
function CHIEF:onafterDefconChange(From, Event, To, Defcon)
  self:I(self.lid..string.format("Changing Defcon from %s --> %s", self.Defcon, Defcon))
end

--- On after "StrategyChange" event.
-- @param #CHIEF self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #string Strategy
function CHIEF:onafterStrategyChange(From, Event, To, Strategy)
  self:I(self.lid..string.format("Changing Strategy from %s --> %s", self.strategy, Strategy))
end

--- On after "OpsOnMission".
-- @param #CHIEF self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.OpsGroup#OPSGROUP OpsGroup Ops group on mission
-- @param Ops.Auftrag#AUFTRAG Mission The requested mission.
function CHIEF:onafterOpsOnMission(From, Event, To, OpsGroup, Mission)
  -- Debug info.
  self:T(self.lid..string.format("Group %s on mission %s [%s]", OpsGroup:GetName(), Mission:GetName(), Mission:GetType()))
end


--- On after "ZoneCaptured".
-- @param #CHIEF self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.OpsZone#OPSZONE OpsZone The zone that was captured by us.
function CHIEF:onafterZoneCaptured(From, Event, To, OpsZone)
  -- Debug info.
  self:T(self.lid..string.format("Zone %s captured!", OpsZone:GetName()))
end


--- On after "ZoneLost".
-- @param #CHIEF self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.OpsZone#OPSZONE OpsZone The zone that was lost.
function CHIEF:onafterZoneLost(From, Event, To, OpsZone)
  -- Debug info.
  self:T(self.lid..string.format("Zone %s lost!", OpsZone:GetName()))
end

--- On after "ZoneEmpty".
-- @param #CHIEF self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.OpsZone#OPSZONE OpsZone The zone that is empty now.
function CHIEF:onafterZoneEmpty(From, Event, To, OpsZone)
  -- Debug info.
  self:T(self.lid..string.format("Zone %s empty!", OpsZone:GetName()))
end

--- On after "ZoneAttacked".
-- @param #CHIEF self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.OpsZone#OPSZONE OpsZone The zone that beeing attacked.
function CHIEF:onafterZoneAttacked(From, Event, To, OpsZone)
  -- Debug info.
  self:T(self.lid..string.format("Zone %s attacked!", OpsZone:GetName()))
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Target Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Check target queue and assign ONE valid target by adding it to the mission queue of the COMMANDER.
-- @param #CHIEF self 
function CHIEF:CheckTargetQueue()

  -- Number of missions.
  local Ntargets=#self.targetqueue

  -- Treat special cases.
  if Ntargets==0 then
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
    if target.importance and target.importance<vip then
      vip=target.importance
    end
  end

  -- Loop over targets.
  for _,_target in pairs(self.targetqueue) do
    local target=_target --Ops.Target#TARGET
    
    local isAlive=target:IsAlive()
    local isImportant=(target.importance==nil or target.importance<=vip)
    
    -- Is this a threat?
    local isThreat=target.threatlevel0>=self.threatLevelMin and target.threatlevel0<=self.threatLevelMax
    
    -- Debug message.
    self:T(self.lid..string.format("Target %s: Alive=%s, Threat=%s, Important=%s", target:GetName(), tostring(isAlive), tostring(isThreat), tostring(isImportant)))

    -- Check that target is alive and not already a mission has been assigned.
    if isAlive and isThreat and isImportant and not target.mission then
    
      -- Check if this target is "valid", i.e. fits with the current strategy.
      local valid=false
      if self.strategy==CHIEF.Strategy.PASSIVE then

        ---
        -- PASSIVE: No targets at all are attacked.
        ---

        valid=false
      
      elseif self.strategy==CHIEF.Strategy.DEFENSIVE then

        ---
        -- DEFENSIVE: Attack inside borders only.
        ---
      
        if self:CheckTargetInZones(target, self.borderzoneset) then
          valid=true
        end
      
      elseif self.strategy==CHIEF.Strategy.OFFENSIVE then

        ---
        -- OFFENSIVE: Attack inside borders and in yellow zones.
        ---
      
        if self:CheckTargetInZones(target, self.borderzoneset) or self:CheckTargetInZones(target, self.yellowzoneset) then
          valid=true
        end
      
      elseif self.strategy==CHIEF.Strategy.AGGRESSIVE then
      
        ---
        -- AGGRESSIVE: Attack in all zone sets.
        ---

        if self:CheckTargetInZones(target, self.borderzoneset) or self:CheckTargetInZones(target, self.yellowzoneset) or self:CheckTargetInZones(target, self.engagezoneset) then
          valid=true
        end
      
      elseif self.strategy==CHIEF.Strategy.TOTALWAR then
      
        ---
        -- TOTAL WAR: We attack anything we find.
        ---
      
        valid=true
      end 
      
      -- Valid target?
      if valid then
      
        -- Debug info.
        self:I(self.lid..string.format("Got valid target %s: category=%s, threatlevel=%d", target:GetName(), target.category, target.threatlevel0))
              
        -- Get mission performances for the given target.  
        local MissionPerformances=self:_GetMissionPerformanceFromTarget(target)
        
        -- Mission.
        local mission=nil --Ops.Auftrag#AUFTRAG
        local Legions=nil
        
        if #MissionPerformances>0 then

          --TODO: Number of required assets. How many do we want? Should depend on:
          --      * number of enemy units
          --      * target threatlevel
          --      * how many assets are still in stock
          --      * is it inside of our border         
          local NassetsMin=1
          local NassetsMax=3
          
          for _,_mp in pairs(MissionPerformances) do
            local mp=_mp --#CHIEF.MissionPerformance

            -- Debug info.
            self:I(self.lid..string.format("Recruiting assets for mission type %s [performance=%d] of target %s", mp.MissionType, mp.Performance, target:GetName()))
            
            -- Recruit assets.
            local recruited, assets, legions=self:RecruitAssetsForTarget(target, mp.MissionType, NassetsMin, NassetsMax)
            
            if recruited then
            
              -- Create a mission.
              mission=AUFTRAG:NewFromTarget(target, mp.MissionType)
                            
              -- Add asset to mission.
              if mission then
                for _,_asset in pairs(assets) do
                  local asset=_asset
                  mission:AddAsset(asset)
                end
                Legions=legions
                
                -- We got what we wanted ==> leave loop.
                break
              end
              
            end
          end
        end
        
        -- Check if mission could be defined.
        if mission and Legions then
        
          -- Set target mission entry.
          target.mission=mission
          
          -- Mission parameters.
          mission.prio=target.prio
          mission.importance=target.importance
                    
          -- Assign mission to legions.
          for _,Legion in pairs(Legions) do
            self:MissionAssign(Legion, mission)
          end
          
          -- Only ONE target is assigned per check.
          return
        end
                
      end
          
    end
  end
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Strategic Zone Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Check strategic zone queue.
-- @param #CHIEF self 
function CHIEF:CheckOpsZoneQueue()

  -- Passive strategy ==> Do not act.
  if self:IsPassive() then
    return
  end

  -- Number of zones.
  local Nzones=#self.zonequeue

  -- Treat special cases.
  if Nzones==0 then
    return nil
  end

  -- Sort results table wrt prio.
  local function _sort(a, b)
    local taskA=a --#CHIEF.StrategicZone
    local taskB=b --#CHIEF.StrategicZone
    return (taskA.prio<taskB.prio)
  end
  table.sort(self.zonequeue, _sort)

  -- Get the lowest importance value (lower means more important).
  -- If a zone with importance 1 exists that is not owned by us, zones with importance 2 will not be assigned. Zone with no importance (nil) can still be selected. 
  local vip=math.huge
  for _,_stratzone in pairs(self.zonequeue) do
    local stratzone=_stratzone --#CHIEF.StrategicZone
    if stratzone.importance and stratzone.importance<vip and stratzone.opszone:GetOwner()~=self.coalition then
      -- Most important zone that is NOT owned by us.
      vip=stratzone.importance
    end
  end

  -- Loop over strategic zones.
  for _,_startzone in pairs(self.zonequeue) do
    local stratzone=_startzone --#CHIEF.StrategicZone
    
    -- Current owner of the zone.
    local ownercoalition=stratzone.opszone:GetOwner()
        
    -- Check coalition and importance.
    if ownercoalition~=self.coalition and (stratzone.importance==nil or stratzone.importance<=vip) then
    
      -- Has a patrol mission?
      local hasMissionPatrol=stratzone.missionPatrol and stratzone.missionPatrol:IsNotOver() or false
      -- Has a CAS mission?
      local hasMissionCAS=stratzone.missionCAS and stratzone.missionCAS:IsNotOver() or false    

      -- Debug info.
      self:T(self.lid..string.format("Zone %s [%s] is owned by coalition %d", stratzone.opszone.zone:GetName(), stratzone.opszone:GetState(), ownercoalition))
    
      if stratzone.opszone:IsEmpty() then
      
        ---
        -- Zone is EMPTY
        -- 
        -- We send ground troops to capture the zone.
        ---
      
        if not hasMissionPatrol then
      
          -- Debug info.
          self:T3(self.lid..string.format("Zone is empty ==> Recruit Patrol zone infantry assets"))
      
          -- Recruit ground assets that
          local recruited=self:RecruitAssetsForZone(stratzone, AUFTRAG.Type.ONGUARD, 1, 3, {Group.Category.GROUND}, {GROUP.Attribute.GROUND_INFANTRY})

          -- Debug info.
          self:T(self.lid..string.format("Zone is empty ==> Recruit Patrol zone infantry assets=%s", tostring(recruited)))
          
        end
        
      else

        ---
        -- Zone is NOT EMPTY
        -- 
        -- We first send a CAS flight to eliminate enemy activity.
        ---
      
        if not hasMissionCAS then

          -- Debug message.
          self:T3(self.lid..string.format("Zone is NOT empty ==> Recruit CAS assets"))          

            
          -- Recruite CAS assets.
          local recruited=self:RecruitAssetsForZone(stratzone, AUFTRAG.Type.CAS, 1, 1)
          
          -- Debug message.
          self:T(self.lid..string.format("Zone is NOT empty ==> Recruit CAS assets=%s", tostring(recruited)))
          
        end
      
      end
          
    end    
  end

  -- Loop over strategic zone.
  for _,_startzone in pairs(self.zonequeue) do
    local stratzone=_startzone --#CHIEF.StrategicZone
    
    -- Current owner of the zone.
    local ownercoalition=stratzone.opszone:GetOwner()
            
    -- Has a patrol mission?
    local hasMissionPatrol=stratzone.missionPatrol and stratzone.missionPatrol:IsNotOver() or false
    
    -- Has a CAS mission?
    local hasMissionCAS=stratzone.missionCAS and stratzone.missionCAS:IsNotOver() or false
    
    if ownercoalition==self.coalition and stratzone.opszone:IsEmpty() and hasMissionCAS then
      -- Cancel CAS mission if zone is ours and no enemies are present.
      -- TODO: Might want to check if we still have CAS capable assets in stock?!
      stratzone.missionCAS:Cancel()
    end
    
     
        
  end
  
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Zone Check Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Check if group is inside our border.
-- @param #CHIEF self
-- @param Wrapper.Group#GROUP group The group.
-- @return #boolean If true, group is in any border zone.
function CHIEF:CheckGroupInBorder(group)

  local inside=self:CheckGroupInZones(group, self.borderzoneset)

  return inside
end

--- Check if group is in a conflict zone.
-- @param #CHIEF self
-- @param Wrapper.Group#GROUP group The group.
-- @return #boolean If true, group is in any conflict zone.
function CHIEF:CheckGroupInConflict(group)

  -- Check inside yellow but not inside our border.
  local inside=self:CheckGroupInZones(group, self.yellowzoneset) --and not self:CheckGroupInZones(group, self.borderzoneset)

  return inside
end

--- Check if group is in a attack zone.
-- @param #CHIEF self
-- @param Wrapper.Group#GROUP group The group.
-- @return #boolean If true, group is in any attack zone.
function CHIEF:CheckGroupInAttack(group)

  -- Check inside yellow but not inside our border.
  local inside=self:CheckGroupInZones(group, self.engagezoneset) --and not self:CheckGroupInZones(group, self.borderzoneset)

  return inside
end

--- Check if group is inside a zone.
-- @param #CHIEF self
-- @param Wrapper.Group#GROUP group The group.
-- @param Core.Set#SET_ZONE zoneset Set of zones.
-- @return #boolean If true, group is in any zone.
function CHIEF:CheckGroupInZones(group, zoneset)

  for _,_zone in pairs(zoneset.Set or {}) do
    local zone=_zone --Core.Zone#ZONE
    
    if group:IsInZone(zone) then
      return true
    end
  end

  return false
end

--- Check if group is inside a zone.
-- @param #CHIEF self
-- @param Ops.Target#TARGET target The target.
-- @param Core.Set#SET_ZONE zoneset Set of zones.
-- @return #boolean If true, group is in any zone.
function CHIEF:CheckTargetInZones(target, zoneset)

  for _,_zone in pairs(zoneset.Set or {}) do
    local zone=_zone --Core.Zone#ZONE
    
    if zone:IsCoordinateInZone(target:GetCoordinate()) then
      return true
    end
  end

  return false
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Resources
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a mission performance table.
-- @param #CHIEF self
-- @param #string MissionType Mission type.
-- @param #number Performance Performance.
-- @return #CHIEF.MissionPerformance Mission performance.
function CHIEF:_CreateMissionPerformance(MissionType, Performance)
  local mp={} --#CHIEF.MissionPerformance
  mp.MissionType=MissionType
  mp.Performance=Performance
  return mp
end

--- Get mission performance for a given TARGET.
-- @param #CHIEF self
-- @param Ops.Target#TARGET Target
-- @return #table Mission performances of type `#CHIEF.MissionPerformance`.
function CHIEF:_GetMissionPerformanceFromTarget(Target)

  -- Possible target objects.
  local group=nil      --Wrapper.Group#GROUP
  local airbase=nil    --Wrapper.Airbase#AIRBASE
  local scenery=nil    --Wrapper.Scenery#SCENERY
  local coordinate=nil --Core.Point#COORDINATE
  
  -- Get target objective.
  local target=Target:GetObject()

  if target:IsInstanceOf("GROUP") then
    group=target --Target is already a group.  
  elseif target:IsInstanceOf("UNIT") then
    group=target:GetGroup()
  elseif target:IsInstanceOf("AIRBASE") then
    airbase=target
  elseif target:IsInstanceOf("SCENERY") then
    scenery=target
  end
 
  -- Target category.
  local TargetCategory=Target:GetCategory()
    
  -- Mission performances.
  local missionperf={} --#CHIEF.MissionPerformance
  
  if group then

    local category=group:GetCategory()
    local attribute=group:GetAttribute()

    if category==Group.Category.AIRPLANE or category==Group.Category.HELICOPTER then
    
      ---
      -- A2A: Intercept
      ---
    
      table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.INTERCEPT, 100))
    
    elseif category==Group.Category.GROUND or category==Group.Category.TRAIN then
    
      ---
      -- GROUND
      ---

      if attribute==GROUP.Attribute.GROUND_SAM then
          
        -- SEAD/DEAD
          
        table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.SEAD, 100))
        
      elseif attribute==GROUP.Attribute.GROUND_AAA then
      
        table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.BAI, 100))
        
      elseif attribute==GROUP.Attribute.GROUND_ARTILLERY then
      
        table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.BAI, 100))
        table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.BOMBING, 70))
        table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.ARTY, 30))
      
      elseif attribute==GROUP.Attribute.GROUND_INFANTRY then
      
        table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.BAI, 100))
          
      else

        table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.BAI, 100))
      
      end

    
    elseif category==Group.Category.SHIP then
    
      ---
      -- NAVAL
      ---
    
      table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.ANTISHIP, 100))
  
    else
      self:E(self.lid.."ERROR: Unknown Group category!")
    end
    
  elseif airbase then
    table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.BOMBRUNWAY, 100))
  elseif scenery then
    table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.STRIKE, 100))
    table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.BOMBING, 70))
    table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.BOMBCARPET, 50))
    table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.ARTY, 30))
  elseif coordinate then
    table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.BOMBING, 100))
    table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.BOMBCARPET, 50))
    table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.ARTY, 30))
  end

  return missionperf
end

--- Get mission performances for a given Group Attribute.
-- @param #CHIEF self
-- @param #string Attribute Group attibute.
-- @return #table Mission performances of type `#CHIEF.MissionPerformance`.
function CHIEF:_GetMissionTypeForGroupAttribute(Attribute)

  local missionperf={} --#CHIEF.MissionPerformance

  if Attribute==GROUP.Attribute.AIR_ATTACKHELO then
  
    table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.INTERCEPT), 100)
    
  elseif Attribute==GROUP.Attribute.GROUND_AAA then
  
    table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.BAI),       100)
    table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.BOMBING),    80)
    table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.BOMBCARPET), 70)
    table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.ARTY),       30)

  elseif Attribute==GROUP.Attribute.GROUND_SAM then
  
    table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.SEAD), 100)
    table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.BAI),   90)
    table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.ARTY),  50)

  elseif Attribute==GROUP.Attribute.GROUND_EWR then
  
    table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.SEAD), 100)
    table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.BAI),  100)
    table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.ARTY),  50)
    
  end

  return missionperf
end

--- Recruit assets for a given TARGET.
-- @param #CHIEF self
-- @param Ops.Target#TARGET Target The target.
-- @param #string MissionType Mission Type.
-- @param #number NassetsMin Min number of required assets.
-- @param #number NassetsMax Max number of required assets.
-- @return #boolean If `true` enough assets could be recruited.
-- @return #table Assets that have been recruited from all legions.
-- @return #table Legions that have recruited assets.
function CHIEF:RecruitAssetsForTarget(Target, MissionType, NassetsMin, NassetsMax)

  -- Cohorts.
  local Cohorts={}
  for _,_legion in pairs(self.commander.legions) do
    local legion=_legion --Ops.Legion#LEGION
    
    -- Check that runway is operational.    
    local Runway=legion:IsAirwing() and legion:IsRunwayOperational() or true
    
    if legion:IsRunning() and Runway then    
    
      -- Loops over cohorts.
      for _,_cohort in pairs(legion.cohorts) do
        local cohort=_cohort --Ops.Cohort#COHORT
        table.insert(Cohorts, cohort)
      end
      
    end
  end  

  -- Target position.
  local TargetVec2=Target:GetVec2()
  
  -- Recruite assets.
  local recruited, assets, legions=LEGION.RecruitCohortAssets(Cohorts, MissionType, nil, NassetsMin, NassetsMax, TargetVec2)


  return recruited, assets, legions
end

--- Recruit assets for a given OPS zone.
-- @param #CHIEF self
-- @param #CHIEF.StrategicZone StratZone The stratetic zone.
-- @param #string MissionType Mission Type.
-- @param #number NassetsMin Min number of required assets.
-- @param #number NassetsMax Max number of required assets.
-- @param #table Categories Group categories of the assets.
-- @param #table Attributes Generalized group attributes.
-- @return #boolean If `true` enough assets could be recruited.
function CHIEF:RecruitAssetsForZone(StratZone, MissionType, NassetsMin, NassetsMax, Categories, Attributes)

  -- Cohorts.
  local Cohorts={}
  for _,_legion in pairs(self.commander.legions) do
    local legion=_legion --Ops.Legion#LEGION
    
    -- Check that runway is operational.    
    local Runway=legion:IsAirwing() and legion:IsRunwayOperational() or true
    
    if legion:IsRunning() and Runway then    
    
      -- Loops over cohorts.
      for _,_cohort in pairs(legion.cohorts) do
        local cohort=_cohort --Ops.Cohort#COHORT
        table.insert(Cohorts, cohort)
      end
      
    end
  end  

  -- Target position.
  local TargetVec2=StratZone.opszone.zone:GetVec2()

  -- Recruite infantry assets.
  local recruited, assets, legions=LEGION.RecruitCohortAssets(Cohorts, MissionType, nil, NassetsMin, NassetsMax, TargetVec2, nil, nil, nil, nil, Categories, Attributes)
  
  if recruited then
  
    if MissionType==AUFTRAG.Type.PATROLZONE or MissionType==AUFTRAG.Type.ONGUARD then
              
      -- Debug messgage.
      self:T2(self.lid..string.format("Recruited %d assets from for PATROL mission", #assets))
      
      local recruitedTrans=true
      local transport=nil
      if Attributes and Attributes[1]==GROUP.Attribute.GROUND_INFANTRY then
      
        -- Categories. Currently only helicopters are allowed due to problems with ground transports (might get stuck, might not be a land connection.
        -- TODO: Check if ground transport is possible. For example, by trying land.getPathOnRoad or something.
        local Categories={Group.Category.HELICOPTER}
        --local Categories={Group.Category.HELICOPTER, Group.Category.GROUND}
  
        -- Recruit transport assets for infantry.    
        recruitedTrans, transport=LEGION.AssignAssetsForTransport(self.commander, self.commander.legions, assets, 1, 1, StratZone.opszone.zone, nil, Categories)
        
      end
      
      if recruitedTrans then
    
        -- Create Patrol zone mission.
        local mission=nil  --Ops.Auftrag#AUFTRAG
        
        if MissionType==AUFTRAG.Type.PATROLZONE then
          mission=AUFTRAG:NewPATROLZONE(StratZone.opszone.zone)
        elseif MissionType==AUFTRAG.Type.ONGUARD then 
          mission=AUFTRAG:NewONGUARD(StratZone.opszone.zone:GetRandomCoordinate(), nil, nil, {land.SurfaceType.LAND})
        end
        mission:SetEngageDetected()            
            
        -- Add assets to mission.
        for _,asset in pairs(assets) do
          mission:AddAsset(asset)
        end
            
        -- Attach OPS transport to mission.
        mission.opstransport=transport
            
        -- Assign mission to legions.
        for _,_legion in pairs(legions) do
          local legion=_legion --Ops.Legion#LEGION
          self:MissionAssign(legion, mission)
        end
      
        -- Attach mission to ops zone.
        -- TODO: Need a better way!
        StratZone.missionPatrol=mission
        
      else
        LEGION.UnRecruitAssets(assets)
      end
      
    elseif MissionType==AUFTRAG.Type.CAS then

      -- Create Patrol zone mission.
      local mission=AUFTRAG:NewCAS(StratZone.opszone.zone, 7000)
                      
      -- Add assets to mission.
      for _,asset in pairs(assets) do
        mission:AddAsset(asset)
      end
          
      -- Assign mission to legions.
      for _,_legion in pairs(legions) do
        local legion=_legion --Ops.Legion#LEGION
        self:MissionAssign(legion, mission)
      end
    
      -- Attach mission to ops zone.
      -- TODO: Need a better way!
      StratZone.missionCAS=mission

    end
    
  end

  return nil
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------