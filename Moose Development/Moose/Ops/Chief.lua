--- **Ops** - Chief of Staff.
--
-- **Main Features:**
--
--    * Automatic target engagement based on detection network
--    * Define multiple border, conflict and attack zones
--    * Define strategic "capture" zones 
--    * Set strategy of chief from passive to agressive
--    * Manual target engagement via AUFTRAG and TARGET classes
--    * Add AIRWINGS, BRIGADES and FLEETS as resources
--    * Seamless air-to-air, air-to-ground, ground-to-ground dispatching
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
-- @field #number threatLevelMin Lowest threat level of targets to attack.
-- @field #number threatLevelMax Highest threat level of targets to attack.
-- @field #string Defcon Defence condition.
-- @field #string strategy Strategy of the CHIEF.
-- @field Ops.Commander#COMMANDER commander Commander of assigned legions.
-- @field #number Nsuccess Number of successful missions.
-- @field #number Nfailure Number of failed mission.
-- @extends Ops.Intelligence#INTEL

--- *In preparing for battle I have always found that plans are useless, but planning is indispensable* -- Dwight D Eisenhower
--
-- ===
--
-- # The CHIEF Concept
-- 
-- The Chief of staff gathers INTEL and assigns missions (AUFTRAG) the airforce, army and/or navy.
-- 
-- # Territory
-- 
-- The chief class allows you to define boarder zones, conflict zones and attack zones.
-- 
-- ## Border Zones
-- 
-- Border zones define your own territory.
-- They can be set via the @{#CHIEF.SetBorderZones}() function as a set or added zone by zone via the @{#CHIEF.AddBorderZone}() function.
-- 
-- ## Conflict Zones
-- 
-- Conflict zones define areas, which usually are under dispute of different coalitions.
-- They can be set via the @{#CHIEF.SetConflictZones}() function as a set or added zone by zone via the @{#CHIEF.AddConflictZone}() function.
-- 
-- ## Attack Zones
-- 
-- Attack zones are zones that usually lie within the enemy territory. They are only enganged with an agressive strategy.
-- They can be set via the @{#CHIEF.SetAttackZones}() function as a set or added zone by zone via the @{#CHIEF.AddAttackZone}() function.
--
-- # Defense Condition
-- 
-- The defence condition (DEFCON) depends on enemy activity detected in the different zone types and is set automatically.
-- 
-- * `CHIEF.Defcon.GREEN`: No enemy activities detected.
-- * `CHIEF.Defcon.YELLOW`: Enemy activity detected in conflict zones.
-- * `CHIEF.Defcon.RED`: Enemy activity detected in border zones.
-- 
-- The current DEFCON can be retrieved with the @(#CHIEF.GetDefcon)() function.
-- 
-- When the DEFCON changed, an FSM event @{#CHIEF.DefconChange} is triggered. Mission designers can hook into this event via the @{#CHIEF.OnAfterDefconChange}() function:
--
--     --- Function called when the DEFCON changes.
--     function myChief:OnAfterDefconChange(From, Event, To, Defcon)
--       local text=string.format("Changed DEFCON to %s", Defcon)
--       MESSAGE:New(text, 120):ToAll()    
--     end
--
-- # Strategy
-- 
-- The strategy of the chief determines, in which areas targets are engaged automatically.
-- 
-- * `CHIEF.Strategy.PASSIVE`: Chief is completely passive. No targets at all are engaged automatically.
-- * `CHIEF.Strategy.DEFENSIVE`: Chief acts defensively. Only targets in his own territory are engaged.
-- * `CHIEF.Strategy.OFFENSIVE`: Chief behaves offensively. Targets in his own territory and in conflict zones are enganged.
-- * `CHIEF.Strategy.AGGRESSIVE`: Chief is aggressive. Targets in his own territory, in conflict zones and in attack zones are enganged.
-- * `CHIEF.Strategy.TOTALWAR`: Anything anywhere is enganged.
-- 
-- The strategy can be set by the @(#CHIEF.SetStrategy)() and retrieved with the @(#CHIEF.GetStrategy)() function.
-- 
-- When the strategy is changed, the FSM event @{#CHIEF.StrategyChange} is triggered and customized code can be added to the @{#CHIEF.OnAfterStrategyChange}() function:
-- 
--     --- Function called when the STRATEGY changes.
--     function myChief:OnAfterStrategyChange(From, Event, To, Strategy)
--       local text=string.format("Strategy changd to %s", Strategy)
--       MESSAGE:New(text, 120):ToAll()
--     end
--     
-- # Resources
-- 
-- A chief needs resources such as air, ground and naval assets. These can be added in form of AIRWINGs, BRIGADEs and FLEETs.
-- 
-- Whenever the chief detects a target or receives a mission, he will select the best available assets and assign them to the mission.
-- The best assets are determined by their mission performance, payload performance (in case of air), distance to the target, skill level, etc.
-- 
-- ## Adding Airwings 
-- 
-- Airwings can be added via the @{#CHIEF.AddAirwing}() function.
-- 
-- ## Adding Brigades
-- 
-- Brigades can be added via the @{#CHIEF.AddBrigade}() function.
-- 
-- ## Adding Fleets
-- 
-- Fleets can be added via the @{#CHIEF.AddFleet}() function.
-- 
--  
-- # Strategic (Capture) Zones
-- 
-- Strategically important zones, which should be captured can be added via the @{#CHIEF.AddStrategicZone}(*OpsZone, Prio, Importance*) function.
-- The first parameter *OpsZone* is an @{Ops.OpsZone#OPSZONE} specifying the zone. This has to be a **circular zone** due to DCS API restrictions.
-- The second parameter *Prio* is the priority. The zone queue is sorted wrt to lower prio values. By default this is set to 50.
-- The third parameter *Importance* is the importance of the zone. By default this is `nil`. If you specify one zone with importance 2 and a second zone with
-- importance 3, then the zone of importance 2 is attacked first and only if that zone has been captured, zones that have importances with higher values are attacked.
-- 
-- For example:
-- 
--     local myStratZone=myChief:AddStrategicZone(myOpsZone, nil , 2)
-- 
-- Will at a strategic zone with importance 2.
-- 
-- If the zone is currently owned by another coalition and enemy ground troops are present in the zone, a CAS and an ARTY mission are lauchned:
-- 
-- * A mission of type `AUFTRAG.Type.CASENHANCED` is started if assets are available that can carry out this mission type.
-- * A mission of type `AUFTRAG.Type.ARTY` is started provided assets are available.
-- 
-- The CAS flight(s) will patrol the zone randomly and take out enemy ground units they detect. It can always be possible that the enemies cannot be detected however.
-- The assets will shell the zone. However, it is unlikely that they hit anything as they do not have any information about the location of the enemies.
-- 
-- Once the zone is cleaned of enemy forces, ground troops are send there. By default, two missions are launched:
-- 
-- * First mission is of type `AUFTRAG.Type.ONGUARD` and will send infantry groups. These are transported by helicopters. Therefore, helo assets with `AUFTRAG.Type.OPSTRANSPORT` need to be available.
-- * The second mission is also of type `AUFTRAG.Type.ONGUARD` but will send tanks if these are available.
-- 
-- ## Customized Reaction
-- 
-- The default mission types and number of assets can be customized for the two scenarious (zone empty or zone occupied by the enemy).
-- 
-- In order to do this, you need to create resource lists (one for each scenario) via the @{#CHIEF.CreateResource}() function.
-- These lists can than passed as additional parameters to the @{#CHIEF.AddStrategicZone} function.
-- 
-- For example:
--     
--     --- Create a resource list of mission types and required assets for the case that the zone is OCCUPIED.
--     --
--     -- Here, we create an enhanced CAS mission and employ at least on and at most two asset groups.
--     local ResourceOccupied=myChief:CreateResource(AUFTRAG.Type.CASENHANCED, 1, 2)
--     -- We also add ARTY missions with at least one and at most two assets. We additionally require these to be MLRS groups (and not howitzers).
--     myChief:AddToResource(ResourceOccupied, AUFTRAG.Type.ARTY, 1, 2, nil, "MLRS")
--     -- Add at least one RECON mission that uses UAV type assets.
--     myChief:AddToResource(ResourceOccupied, AUFTRAG.Type.RECON, 1, nil, GROUP.Attribute.AIR_UAV)
--     -- Add at least one but at most two BOMBCARPET missions.
--     myChief:AddToResource(ResourceOccupied, AUFTRAG.Type.BOMBCARPET, 1, 2)
--     
--     --- Create a resource list of mission types and required assets for the case that the zone is EMPTY.
--     --
--     -- Here, we create an ONGUARD mission and employ at least on and at most five infantry assets.
--     local ResourceEmpty=myChief:CreateResource(AUFTRAG.Type.ONGUARD, 1, 5, GROUP.Attribute.GROUND_INFANTRY)
--     -- Additionally, we send up to three tank groups.
--     myChief:AddToResource(ResourceEmpty, AUFTRAG.Type.ONGUARD, 1, 3, GROUP.Attribute.GROUND_TANK)
--     -- Finally, we send two groups that patrol the zone.
--     myChief:AddToResource(ResourceEmpty, AUFTRAG.Type.PATROLZONE, 2)
--     
--     -- Add stratetic zone with customized reaction.
--     myChief:AddStrategicZone(myOpsZone, nil , 2, ResourceOccupied, ResourceEmpty)
-- 
-- As the location of the enemies is not known, only mission types that don't require an explicit target group are possible. These are
-- 
-- * `AUFTRAG.Type.CASENHANCED`
-- * `AUFTRAG.Type.ARTY`
-- * `AUFTRAG.Type.PATROLZONE`
-- * `AUFTRAG.Type.ONGUARD`
-- * `AUFTRAG.Type.RECON`
-- * `AUFTRAG.Type.AMMOSUPPLY`
-- * `AUFTRAG.Type.BOMBING`
-- * `AUFTRAG.Type.BOMBCARPET`
-- * `AUFTRAG.Type.BARRAGE`
-- 
-- ## Events
-- 
-- Whenever a strategic zone is captured by us the FSM event @{#CHIEF.ZoneCaptured} is triggered and customized further actions can be executed 
-- with the @{#CHIEF.OnAfterZoneCaptured}() function.
-- 
-- Whenever a strategic zone is lost (captured by the enemy), the FSM event @{#CHIEF.ZoneLost} is triggered and customized further actions can be executed 
-- with the @{#CHIEF.OnAfterZoneLost}() function.
-- 
-- Further events are 
-- 
-- * @{#CHIEF.ZoneEmpty}, once the zone is completely empty of ground troops. Code can be added to the  @{#CHIEF.OnAfterZoneEmpty}() function.
-- * @{#CHIEF.ZoneAttacked}, once the zone is under attack. Code can be added to the  @{#CHIEF.OnAfterZoneAttacked}() function.
-- 
-- Note that the ownership of a zone is determined via zone scans, i.e. not via the detection network. In other words, there is an all knowing eye.
-- Think of it as the local population providing the intel. It's not totally realistic but the best compromise within the limits of DCS.
-- 
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
  tacview        = false,
  Nsuccess       =     0,
  Nfailure       =     0,
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
-- @field #number importance Importance.
-- @field #table resourceEmpty Resource list.
-- @field #table resourceOccup Resource list.
-- @field #table missions Mission.

--- Resource.
-- @type CHIEF.Resource
-- @field #string MissionType Mission type, e.g. `AUFTRAG.Type.BAI`.
-- @field #number Nmin Min number of assets.
-- @field #number Nmax Max number of assets.
-- @field #table Attributes Generalized attribute, e.g. `{GROUP.Attribute.GROUND_INFANTRY}`.
-- @field #table Properties Properties ([DCS attributes](https://wiki.hoggitworld.com/view/DCS_enum_attributes)), e.g. `"Attack helicopters"` or `"Mobile AAA"`.
-- @field Ops.Auftrag#AUFTRAG mission Attached mission.

--- CHIEF class version.
-- @field #string version
CHIEF.version="0.3.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Let user specify amount of resources.
-- DONE: Tactical overview.
-- DONE: Add event for opsgroups on mission.
-- DONE: Add event for zone captured. 
-- DONE: Limits of missions?
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
-- @param #number Coalition Coalition side, e.g. `coaliton.side.BLUE`. Can also be passed as a string "red", "blue" or "neutral".
-- @param Core.Set#SET_GROUP AgentSet Set of agents (groups) providing intel. Default is an empty set.
-- @param #string Alias An *optional* alias how this object is called in the logs etc.
-- @return #CHIEF self
function CHIEF:New(Coalition, AgentSet, Alias)

  -- Set alias.
  Alias=Alias or "CHIEF"
  
  -- coalition
  if type(Coalition) == "string" then
    if string.lower(Coalition) == "blue" then
      Coalition = coalition.side.BLUE
    elseif string.lower(Coalition) == "red" then
      Coalition = coalition.side.RED
    else
      Coalition = coalition.side.NEUTRAL
    end
  end
  
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
  self.TransportCategories = {Group.Category.HELICOPTER}
  
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
  -- @param #string Strategy New strategy.


  --- Triggers the FSM event "MissionAssign".
  -- @function [parent=#CHIEF] MissionAssign
  -- @param #CHIEF self
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.
  -- @param #table Legions The Legion(s) to which the mission is assigned.

  --- Triggers the FSM event "MissionAssign" after a delay.
  -- @function [parent=#CHIEF] __MissionAssign
  -- @param #CHIEF self
  -- @param #number delay Delay in seconds.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.
  -- @param #table Legions The Legion(s) to which the mission is assigned.

  --- On after "MissionAssign" event.
  -- @function [parent=#CHIEF] OnAfterMissionAssign
  -- @param #CHIEF self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.
  -- @param #table Legions The Legion(s) to which the mission is assigned.

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
  -- @param Ops.OpsZone#OPSZONE OpsZone Zone that is being attacked.

  --- Triggers the FSM event "ZoneAttacked" after a delay.
  -- @function [parent=#CHIEF] __ZoneAttacked
  -- @param #CHIEF self
  -- @param #number delay Delay in seconds.
  -- @param Ops.OpsZone#OPSZONE OpsZone Zone that is being attacked.

  --- On after "ZoneAttacked" event.
  -- @function [parent=#CHIEF] OnAfterZoneAttacked
  -- @param #CHIEF self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.OpsZone#OPSZONE OpsZone Zone that is being attacked. 

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

--- Create a new resource list of required assets.
-- @param #CHIEF self
-- @param #string MissionType The mission type.
-- @param #number Nmin Min number of required assets. Default 1.
-- @param #number Nmax Max number of requried assets. Default 1.
-- @param #table Attributes Generalized attribute(s). Default `nil`.
-- @param #table Properties DCS attribute(s). Default `nil`.
-- @return #table The resource object.
function CHIEF:CreateResource(MissionType, Nmin, Nmax, Attributes, Properties)

  local resource={}
  
  self:AddToResource(resource, MissionType, Nmin, Nmax, Attributes, Properties)
    
  return resource
end

--- Add mission type and number of required assets to resource.
-- @param #CHIEF self
-- @param #table Resource Resource table.
-- @param #string MissionType Mission Type.
-- @param #number Nmin Min number of required assets.
-- @param #number Nmax Max number of requried assets.
-- @param #table Attributes Generalized attribute(s).
-- @param #table Properties DCS attribute(s). Default `nil`.
-- @return #CHIEF self
function CHIEF:AddToResource(Resource, MissionType, Nmin, Nmax, Attributes, Properties)
  
  -- Ensure table.
  if Attributes and type(Attributes)~="table" then
    Attributes={Attributes}
  end
  
  -- Ensure table.
  if Properties and type(Properties)~="table" then
    Properties={Properties}
  end
  
  -- Create new resource table.
  local resource={} --#CHIEF.Resource
  resource.MissionType=MissionType
  resource.Nmin=Nmin or 1
  resource.Nmax=Nmax or 1
  resource.Attributes=Attributes or {}
  resource.Properties=Properties or {}
  
  -- Add to table.
  table.insert(Resource, resource)
  
  -- Debug output.
  if self.verbose>10 then
    local text="Resource:"
    for _,_r in pairs(Resource) do
      local r=_r --#CHIEF.Resource
      text=text..string.format("\nmission=%s, Nmin=%d, Nmax=%d, attribute=%s, properties=%s", r.MissionType, r.Nmin, r.Nmax, tostring(r.Attributes[1]), tostring(r.Properties[1]))
    end
    self:I(self.lid..text)
  end
    
  return self
end

--- Delete mission type from resource list. All running missions are cancelled.
-- @param #CHIEF self
-- @param #table Resource Resource table.
-- @param #string MissionType Mission Type.
-- @return #CHIEF self
function CHIEF:DeleteFromResource(Resource, MissionType)
  
  for i=#Resource,1,-1 do
    local resource=Resource[i] --#CHIEF.Resource
    if resource.MissionType==MissionType then
      if resource.mission and resource.mission:IsNotOver() then
        resource.mission:Cancel()
      end
      table.remove(Resource, i)
    end    
  end
  
  return self
end

--- Get defence condition.
-- @param #CHIEF self
-- @param #string Current Defence condition. See @{#CHIEF.DEFCON}, e.g. `CHIEF.DEFCON.RED`.
function CHIEF:GetDefcon(Defcon)  
  return self.Defcon
end

--- Set limit for number of total or specific missions to be executed simultaniously.
-- @param #CHIEF self
-- @param #number Limit Number of max. mission of this type. Default 10.
-- @param #string MissionType Type of mission, e.g. `AUFTRAG.Type.BAI`. Default `"Total"` for total number of missions.
-- @return #CHIEF self
function CHIEF:SetLimitMission(Limit, MissionType)
  self.commander:SetLimitMission(Limit, MissionType)
  return self
end

--- Set tactical overview on.
-- @param #CHIEF self
-- @return #CHIEF self
function CHIEF:SetTacticalOverviewOn()  
  self.tacview=true
  return self
end

--- Set tactical overview off.
-- @param #CHIEF self
-- @return #CHIEF self
function CHIEF:SetTacticalOverviewOff()  
  self.tacview=false
  return self
end


--- Set strategy.
-- @param #CHIEF self
-- @param #string Strategy Strategy. See @{#CHIEF.strategy}, e.g. `CHIEF.Strategy.DEFENSIVE` (default).
-- @return #CHIEF self
function CHIEF:SetStrategy(Strategy)

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

  -- Add brigade to the commander.
  self:AddLegion(Brigade)
  
  return self
end

--- Add a FLEET to the chief's commander.
-- @param #CHIEF self
-- @param Ops.Fleet#FLEET Fleet The fleet to add.
-- @return #CHIEF self
function CHIEF:AddFleet(Fleet)

  -- Add fleet to the commander.
  self:AddLegion(Fleet)
  
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
  
  Mission.statusChief=AUFTRAG.Status.PLANNED
  
  self:I(self.lid..string.format("Adding mission #%d", Mission.auftragsnummer))
  
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
      self:T(self.lid..string.format("Removing target %s from queue", Target.name))
      table.remove(self.targetqueue, i)
      break
    end
    
  end

  return self
end

--- Add strategically important zone.
-- By default two resource lists are created. One for the case that the zone is empty and the other for the case that the zone is occupied.
-- 
-- Occupied:
-- 
-- * `AUFTRAG.Type.ARTY` with Nmin=1, Nmax=2
-- * `AUFTRAG.Type.CASENHANCED` with Nmin=1, Nmax=2
-- 
-- Empty:
-- 
-- * `AUFTRAG.Type.ONGUARD` with Nmin=1 and Nmax=3 assets, Attribute=`GROUP.Attribute.GROUND_INFANTRY`.
-- * `AUFTRAG.Type.ONGURAD` with Nmin=1 and Nmax=1 assets, Attribute=`GROUP.Attribute.GROUND_TANK`.
-- 
-- Resources can be created with the @{#CHIEF.CreateResource} and @{#CHIEF.AddToResource} functions.
-- 
-- @param #CHIEF self
-- @param Ops.OpsZone#OPSZONE OpsZone OPS zone object.
-- @param #number Priority Priority. Default 50.
-- @param #number Importance Importance. Default nil.
-- @param #CHIEF.Resource ResourceOccupied (Optional) Resources used then zone is occupied by the enemy.
-- @param #CHIEF.Resource ResourceEmpty (Optional) Resources used then zone is empty.
-- @return #CHIEF.StrategicZone The strategic zone.
function CHIEF:AddStrategicZone(OpsZone, Priority, Importance, ResourceOccupied, ResourceEmpty)

  local stratzone={} --#CHIEF.StrategicZone
  
  stratzone.opszone=OpsZone
  stratzone.prio=Priority or 50
  stratzone.importance=Importance
  
  stratzone.missions={}

  -- Start ops zone.
  if OpsZone:IsStopped() then
    OpsZone:Start()
  end
  
  -- Add resources if zone is occupied.
  if ResourceOccupied then
    stratzone.resourceOccup=UTILS.DeepCopy(ResourceOccupied)
  else
    stratzone.resourceOccup=self:CreateResource(AUFTRAG.Type.ARTY, 1, 2)
    self:AddToResource(stratzone.resourceOccup, AUFTRAG.Type.CASENHANCED, 1, 2)
  end
  
  -- Add resources if zone is empty
  if ResourceEmpty then
    stratzone.resourceEmpty=UTILS.DeepCopy(ResourceEmpty)
  else
    stratzone.resourceEmpty=self:CreateResource(AUFTRAG.Type.ONGUARD, 1, 3, GROUP.Attribute.GROUND_INFANTRY)
    self:AddToResource(stratzone.resourceEmpty, AUFTRAG.Type.ONGUARD, 1, 1, GROUP.Attribute.GROUND_TANK)
  end

  -- Add to table.
  table.insert(self.zonequeue, stratzone)
  
  -- Add chief so we get informed when something happens.
  OpsZone:_AddChief(self)

  return stratzone
end

--- Set the resource list of missions and assets employed when the zone is empty.
-- @param #CHIEF self
-- @param #CHIEF.StrategicZone StrategicZone The strategic zone.
-- @param #CHIEF.Resource Resource Resource list of missions and assets.
-- @param #boolean NoCopy If `true`, do **not** create a deep copy of the resource.
-- @return #CHIEF self
function CHIEF:SetStrategicZoneResourceEmpty(StrategicZone, Resource, NoCopy)
  if NoCopy then
    StrategicZone.resourceEmpty=Resource
  else
    StrategicZone.resourceEmpty=UTILS.DeepCopy(Resource)
  end
  return self
end

--- Set the resource list of missions and assets employed when the zone is occupied by the enemy.
-- @param #CHIEF self
-- @param #CHIEF.StrategicZone StrategicZone The strategic zone.
-- @param #CHIEF.Resource Resource Resource list of missions and assets.
-- @param #boolean NoCopy If `true`, do **not** create a deep copy of the resource.
-- @return #CHIEF self
function CHIEF:SetStrategicZoneResourceOccupied(StrategicZone, Resource, NoCopy)
  if NoCopy then
    StrategicZone.resourceOccup=Resource
  else
    StrategicZone.resourceOccup=UTILS.DeepCopy(Resource)
  end
  return self
end

--- Get the resource list of missions and assets employed when the zone is empty.
-- @param #CHIEF self
-- @param #CHIEF.StrategicZone StrategicZone The strategic zone.
-- @return #CHIEF.Resource Resource list of missions and assets.
function CHIEF:GetStrategicZoneResourceEmpty(StrategicZone)
  return StrategicZone.resourceEmpty
end

--- Get the resource list of missions and assets employed when the zone is occupied by the enemy.
-- @param #CHIEF self
-- @param #CHIEF.StrategicZone StrategicZone The strategic zone.
-- @return #CHIEF.Resource Resource list of missions and assets.
function CHIEF:GetStrategicZoneResourceOccupied(StrategicZone)
  return StrategicZone.resourceOccup
end


--- Remove strategically important zone. All runing missions are cancelled.
-- @param #CHIEF self
-- @param Ops.OpsZone#OPSZONE OpsZone OPS zone object.
-- @param #number Delay Delay in seconds before the zone is removed. Default immidiately.
-- @return #CHIEF self
function CHIEF:RemoveStrategicZone(OpsZone, Delay)

  if Delay and Delay>0 then
    -- Delayed call.
    self:ScheduleOnce(Delay, CHIEF.RemoveStrategicZone, self, OpsZone)  
  else
  
    -- Loop over all zones in the queue.
    for i=#self.zonequeue,1,-1 do
      local stratzone=self.zonequeue[i] --#CHIEF.StrategicZone
      
      if OpsZone.zoneName==stratzone.opszone.zoneName then
      
        -- Debug info.
        self:T(self.lid..string.format("Removing OPS zone \"%s\" from queue! All running missions will be cancelled", OpsZone.zoneName))

        -- Cancel running missions.
        for _,_resource in pairs(stratzone.resourceEmpty) do
          local resource=_resource --#CHIEF.Resource
          if resource.mission and resource.mission:IsNotOver() then
            resource.mission:Cancel()
          end
        end
        
        -- Cancel running missions.
        for _,_resource in pairs(stratzone.resourceOccup) do
          local resource=_resource --#CHIEF.Resource
          if resource.mission and resource.mission:IsNotOver() then
            resource.mission:Cancel()
          end
        end
                
        -- Remove from table.    
        table.remove(self.zonequeue, i)
        
        -- Done!
        return self
      end
    end
  
  end

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

--- Add a CAP zone. Flights will engage detected targets inside this zone. 
-- @param #CHIEF self
-- @param Core.Zone#ZONE Zone CAP Zone. Has to be a circular zone.
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

--- Add a GCI CAP.
-- @param #CHIEF self
-- @param Core.Zone#ZONE Zone Zone, where the flight orbits.
-- @param #number Altitude Orbit altitude in feet. Default is 12,0000 feet.
-- @param #number Speed Orbit speed in KIAS. Default 350 kts.
-- @param #number Heading Heading of race-track pattern in degrees. Default 270 (East to West).
-- @param #number Leg Length of race-track in NM. Default 30 NM.
-- @return Ops.AirWing#AIRWING.PatrolZone The CAP zone data.
function CHIEF:AddGciCapZone(Zone, Altitude, Speed, Heading, Leg)

  -- Hand over to commander.
  local zone=self.commander:AddGciCapZone(Zone, Altitude, Speed, Heading, Leg)

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

--- Allow chief to use GROUND units for transport tasks. Helicopters are still preferred, and be aware there's no check as of now
-- if a destination can be reached on land.
-- @param #CHIEF self
-- @return #CHIEF self
function CHIEF:AllowGroundTransport()
  self.TransportCategories = {Group.Category.GROUND, Group.Category.HELICOPTER}
  return self
end

--- Forbid chief to use GROUND units for transport tasks. Restrict to Helicopters. This is the default
-- @param #CHIEF self
-- @return #CHIEF self
function CHIEF:ForbidGroundTransport()
  self.TransportCategories = {Group.Category.HELICOPTER}
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
      self:T(self.lid..text)
    
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
  self.Nborder=0 ; self.Nconflict=0 ; self.Nattack=0
  for _,_contact in pairs(self.Contacts) do
    local contact=_contact    --Ops.Intelligence#INTEL.Contact
    local group=contact.group --Wrapper.Group#GROUP
    
    -- Check if contact inside of our borders.
    local inred=self:CheckGroupInBorder(group)
    if inred then
      self.Nborder=self.Nborder+1
    end
    
    -- Check if contact is in the conflict zones.
    local inyellow=self:CheckGroupInConflict(group)
    if inyellow then
      self.Nconflict=self.Nconflict+1
    end
    
    -- Check if contact is in the attack zones.
    local inattack=self:CheckGroupInAttack(group)
    if inattack then
      self.Nattack=self.Nattack+1
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
  if self.Nborder>0 then
    self:SetDefcon(CHIEF.DEFCON.RED)
  elseif self.Nconflict>0 then
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
  
  
  -- Display tactival overview.
  self:_TacticalOverview()
  
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
    self.Defcon, self.strategy, Nassets, Ncontacts, self.Nborder, self.Nconflict, self.Nattack, Ntargets, Nmissions)
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
        mtext=string.format("\"%s\" [%s] %s", contact.mission:GetName(), contact.mission:GetType(), contact.mission.status:upper())
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

      local mtext="N/A"
      if target.mission then
        mtext=string.format("\"%s\" [%s] %s", target.mission:GetName(), target.mission:GetType(), target.mission.status:upper())
      end      
      text=text..string.format("\n[%d] %s: Category=%s, prio=%d, importance=%d, alive=%s [%.1f/%.1f], Mission=%s",
      i, target:GetName(), target.category, target.prio, target.importance or -1, tostring(target:IsAlive()), target:GetLife(), target:GetLife0(), mtext)          
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
    self:T(self.lid..text)
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
-- @param Ops.Auftrag#AUFTRAG Mission The mission.
  -- @param #table Legions The Legion(s) to which the mission is assigned.
function CHIEF:onafterMissionAssign(From, Event, To, Mission, Legions)

  if self.commander then
    self:T(self.lid..string.format("Assigning mission %s (%s) to COMMANDER", Mission.name, Mission.type))
    Mission.chief=self
    Mission.statusChief=AUFTRAG.Status.QUEUED
    self.commander:MissionAssign(Mission, Legions)
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
  self:T(self.lid..string.format("Cancelling mission %s (%s) in status %s", Mission.name, Mission.type, Mission.status))
  
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
  self:T(self.lid..string.format("Cancelling transport UID=%d in status %s", Transport.uid, Transport:GetState()))
  
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
  self:T(self.lid..string.format("Changing Defcon from %s --> %s", self.Defcon, Defcon))
end

--- On after "StrategyChange" event.
-- @param #CHIEF self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #string Strategy
function CHIEF:onafterStrategyChange(From, Event, To, Strategy)
  self:T(self.lid..string.format("Changing Strategy from %s --> %s", self.strategy, Strategy))
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
-- @param Ops.OpsZone#OPSZONE OpsZone The zone that being attacked.
function CHIEF:onafterZoneAttacked(From, Event, To, OpsZone)
  -- Debug info.
  self:T(self.lid..string.format("Zone %s attacked!", OpsZone:GetName()))
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Target Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Display tactical overview.
-- @param #CHIEF self 
function CHIEF:_TacticalOverview()

  if self.tacview then

    local NassetsTotal=self.commander:CountAssets()
    local NassetsStock=self.commander:CountAssets(true)
    local Ncontacts=#self.Contacts
    local NmissionsTotal=#self.commander.missionqueue
    local NmissionsRunni=self.commander:CountMissions(AUFTRAG.Type, true)
    local Ntargets=#self.targetqueue
    local Nzones=#self.zonequeue
    local Nagents=self.detectionset:CountAlive()
    
    -- Info message
    local text=string.format("Tactical Overview\n")
    text=text..string.format("=================\n")
    
    -- Strategy and defcon info.
    text=text..string.format("Strategy: %s - Defcon: %s - Agents=%s\n", self.strategy, self.Defcon, Nagents)
    
    -- Contact info.
    text=text..string.format("Contacts: %d [Border=%d, Conflict=%d, Attack=%d]\n", Ncontacts, self.Nborder, self.Nconflict, self.Nattack)
    
    -- Asset info.
    text=text..string.format("Assets: %d [Active=%d, Stock=%d]\n", NassetsTotal, NassetsTotal-NassetsStock, NassetsStock)

    -- Target info.    
    text=text..string.format("Targets: %d\n", Ntargets)
    
    -- Mission info.
    text=text..string.format("Missions: %d [Running=%d/%d - Success=%d, Failure=%d]\n", NmissionsTotal, NmissionsRunni, self:GetMissionLimit("Total"), self.Nsuccess, self.Nfailure)
    for _,mtype in pairs(AUFTRAG.Type) do
      local n=self.commander:CountMissions(mtype)
      if n>0 then
        local N=self.commander:CountMissions(mtype, true)
        local limit=self:GetMissionLimit(mtype)
        text=text..string.format("  - %s: %d [Running=%d/%d]\n", mtype, n, N, limit)
      end
    end
    
    -- Strategic zone info.
    text=text..string.format("Strategic Zones: %d\n", Nzones)
    for _,_stratzone in pairs(self.zonequeue) do
      local stratzone=_stratzone --#CHIEF.StrategicZone
      local owner=stratzone.opszone:GetOwnerName()
      text=text..string.format("  - %s: %s - %s [I=%d, P=%d]\n", stratzone.opszone:GetName(), owner, stratzone.opszone:GetState(), stratzone.importance, stratzone.prio)
    end
    
    -- Message to coalition.
    MESSAGE:New(text, 60, nil, true):ToCoalition(self.coalition)
    
    -- Output to log.
    if self.verbose>=4 then
      self:I(self.lid..text)
    end
    
  end

end


--- Check target queue and assign ONE valid target by adding it to the mission queue of the COMMANDER.
-- @param #CHIEF self 
function CHIEF:CheckTargetQueue()

  -- Number of missions.
  local Ntargets=#self.targetqueue

  -- Treat special cases.
  if Ntargets==0 then
    return nil
  end
  
  -- Check if total number of missions is reached.
  local NoLimit=self:_CheckMissionLimit("Total")
  --env.info("FF chief total nolimit="..tostring(NoLimit))
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
    
    -- Get threat level of target.
    local threatlevel=target:GetThreatLevelMax()
    
    -- Is this a threat?
    local isThreat=threatlevel>=self.threatLevelMin and threatlevel<=self.threatLevelMax
    
    -- Airbases, Zones and Coordinates have threat level 0. We consider them threads independent of min/max threat level set.
    if target.category==TARGET.Category.AIRBASE or target.category==TARGET.Category.ZONE or target.Category==TARGET.Category.COORDINATE then
      isThreat=true
    end
    
    -- Debug message.
    local text=string.format("Target %s: Alive=%s, Threat=%s, Important=%s", target:GetName(), tostring(isAlive), tostring(isThreat), tostring(isImportant))
        
    -- Check if mission is done.
    if target.mission then
      text=text..string.format(", Mission \"%s\" (%s) [%s]", target.mission:GetName(), target.mission:GetState(), target.mission:GetType())
      if target.mission:IsOver() then
        text=text..string.format(" - DONE ==> removing mission")
        target.mission=nil
      end
    else
      text=text..string.format(", NO mission yet")
    end
    self:T2(self.lid..text)

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
        self:T(self.lid..string.format("Got valid target %s: category=%s, threatlevel=%d", target:GetName(), target.category, threatlevel))
              
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
          --      * add damping factor
          
          local NassetsMin=1
          local NassetsMax=1
          
          if threatlevel>=8 and target.N0 >=10 then
            NassetsMax=3
          elseif threatlevel>=5 then
            NassetsMax=2
          else
            NassetsMax=1          
          end
          
          for _,_mp in pairs(MissionPerformances) do
            local mp=_mp --#CHIEF.MissionPerformance
            
            -- Check mission type limit.
            local notlimited=self:_CheckMissionLimit(mp.MissionType)
            
            --env.info(string.format("FF chief %s nolimit=%s", mp.MissionType, tostring(NoLimit)))
            
            if notlimited then

              -- Debug info.
              self:T2(self.lid..string.format("Recruiting assets for mission type %s [performance=%d] of target %s", mp.MissionType, mp.Performance, target:GetName()))
              
              -- Recruit assets.
              local recruited, assets, legions=self:RecruitAssetsForTarget(target, mp.MissionType, NassetsMin, NassetsMax)
              
              if recruited then
              
                self:T(self.lid..string.format("Recruited %d assets for mission type %s [performance=%d] of target %s", #assets, mp.MissionType, mp.Performance, target:GetName()))
              
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
              else
                self:T(self.lid..string.format("Could NOT recruit assets for mission type %s [performance=%d] of target %s", mp.MissionType, mp.Performance, target:GetName()))
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
          self:MissionAssign(mission, Legions)
          
          -- Only ONE target is assigned per check.
          return
        end
                
      end
          
    end
  end
  
end

--- Check if limit of missions has been reached.
-- @param #CHIEF self 
-- @param #string MissionType Type of mission.
-- @return #boolean If `true`, mission limit has **not** been reached. If `false`, limit has been reached.
function CHIEF:_CheckMissionLimit(MissionType)
  return self.commander:_CheckMissionLimit(MissionType)
end

--- Get mission limit.
-- @param #CHIEF self 
-- @param #string MissionType Type of mission.
-- @return #number Limit. Unlimited mission types are returned as 999.
function CHIEF:GetMissionLimit(MissionType)
  local l=self.commander.limitMission[MissionType]
  if not l then
    l=999
  end
  return l
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Strategic Zone Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Check strategic zone queue.
-- @param #CHIEF self 
function CHIEF:CheckOpsZoneQueue()

  -- Number of zones.
  local Nzones=#self.zonequeue

  -- Treat special cases.
  if Nzones==0 then
    return nil
  end

  -- Loop over strategic zone and remove stopped zones.
  for i=Nzones, 1, -1 do
    local stratzone=self.zonequeue[i] --#CHIEF.StrategicZone
    if stratzone.opszone:IsStopped() then
      self:RemoveStrategicZone(stratzone.opszone)
    end
  end
  
  -- Loop over strategic zones and cancel missions for occupied zones if zone is not occupied any more.
  for _,_startzone in pairs(self.zonequeue) do
    local stratzone=_startzone --#CHIEF.StrategicZone
    
    -- Current owner of the zone.
    local ownercoalition=stratzone.opszone:GetOwner()

    -- Check if we own the zone or it is empty.
    if ownercoalition==self.coalition or stratzone.opszone:IsEmpty() then

      -- Loop over resources.
      for _,_resource in pairs(stratzone.resourceOccup or {}) do
        local resource=_resource --#CHIEF.Resource
        
        -- Cancel running missions.
        if resource.mission then
          resource.mission:Cancel()
        end
        
      end
    end
  end  

  -- Passive strategy ==> Do not act.
  if self:IsPassive() then
    return
  end
  
  -- Check if total number of missions is reached.
  local NoLimit=self:_CheckMissionLimit("Total")
  if NoLimit==false then
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
    
    -- Name of the zone.
    local zoneName=stratzone.opszone.zone:GetName()
        
    -- Check coalition and importance.
    if ownercoalition~=self.coalition and (stratzone.importance==nil or stratzone.importance<=vip) and (not stratzone.opszone:IsStopped()) then

      -- Debug info.
      self:T(self.lid..string.format("Zone %s [%s] is owned by coalition %d", zoneName, stratzone.opszone:GetState(), ownercoalition))
    
      if stratzone.opszone:IsEmpty() then
      
        ---
        -- Zone is EMPTY
        -- 
        -- We send ground troops to capture the zone.
        ---

        for _,_resource in pairs(stratzone.resourceEmpty or {}) do
          local resource=_resource --#CHIEF.Resource
          
          -- Mission type.
          local missionType=resource.MissionType

          if (not resource.mission) or resource.mission:IsOver() then

            -- Debug info.
            self:T2(self.lid..string.format("Zone \"%s\" is empty ==> Recruiting for mission type %s: Nmin=%d, Nmax=%d", zoneName, missionType, resource.Nmin, resource.Nmax))          
          
            -- Recruit assets.
            local recruited=self:RecruitAssetsForZone(stratzone, resource)
            
            if recruited then
              self:T(self.lid..string.format("Successfully recruited assets for empty zone \"%s\" [mission type=%s]", zoneName, missionType))
            else
              self:T(self.lid..string.format("Could not recruited assets for empty zone \"%s\" [mission type=%s]", zoneName, missionType))
            end
            
          end
        
        end
        
      else

        ---
        -- Zone is NOT EMPTY
        -- 
        -- We first send a CAS flight to eliminate enemy activity.
        ---

        for _,_resource in pairs(stratzone.resourceOccup or {}) do
          local resource=_resource --#CHIEF.Resource
          
          -- Mission type.
          local missionType=resource.MissionType
          
          if (not resource.mission) or resource.mission:IsOver() then

            -- Debug info.
            self:T2(self.lid..string.format("Zone %s is NOT empty ==> Recruiting for mission type %s: Nmin=%d, Nmax=%d", zoneName, missionType, resource.Nmin, resource.Nmax))
          
            -- Recruit assets.
            local recruited=self:RecruitAssetsForZone(stratzone, resource)
            
            if recruited then
              self:T(self.lid..string.format("Successfully recruited assets for occupied zone %s, mission type=%s", zoneName, missionType))
            else
              self:T(self.lid..string.format("Could not recruited assets for occupied zone %s, mission type=%s", zoneName, missionType))
            end            
            
          end
        
        end

      end
          
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
-- @param Ops.Target#TARGET Target The target.
-- @return #table Mission performances of type `#CHIEF.MissionPerformance`.
function CHIEF:_GetMissionPerformanceFromTarget(Target)

  -- Possible target objects.
  local group=nil      --Wrapper.Group#GROUP
  local airbase=nil    --Wrapper.Airbase#AIRBASE
  local scenery=nil    --Wrapper.Scenery#SCENERY
  local static=nil     --Wrapper.Static#STATIC
  local coordinate=nil --Core.Point#COORDINATE
  
  -- Get target objective.
  local target=Target:GetObject()

  if target:IsInstanceOf("GROUP") then
    group=target --Target is already a group.  
  elseif target:IsInstanceOf("UNIT") then
    group=target:GetGroup()
  elseif target:IsInstanceOf("AIRBASE") then
    airbase=target
  elseif target:IsInstanceOf("STATIC") then
    static=target
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
        table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.GROUNDATTACK, 50))
        table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.ARTY, 30))
        
      elseif attribute==GROUP.Attribute.GROUND_EWR then

        -- EWR
        
        table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.BAI,  100))  
        table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.GROUNDATTACK, 50))
        table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.ARTY, 30))
        
      elseif attribute==GROUP.Attribute.GROUND_AAA then
      
        -- AAA
      
        table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.BAI, 100))
        table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.GROUNDATTACK, 50))
        table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.ARMORATTACK, 40))
        
      elseif attribute==GROUP.Attribute.GROUND_ARTILLERY then
      
        -- ARTY
      
        table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.BAI, 100))
        table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.GROUNDATTACK, 75))
        table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.ARMORATTACK, 70))
        table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.BOMBING, 70))
        table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.ARTY, 30))        
      
      elseif attribute==GROUP.Attribute.GROUND_INFANTRY then
      
        -- Infantry
                
        table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.BAI, 100))
        table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.GROUNDATTACK, 50))
        table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.ARMORATTACK, 40))
          
      elseif attribute==GROUP.Attribute.GROUND_TANK then
      
        -- Tanks
        
        table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.CAS, 100))
        table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.GROUNDATTACK, 50))
        table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.ARMORATTACK, 40))
        table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.ARTY, 30))
        
      else

        table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.BAI, 100))
        table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.GROUNDATTACK, 50))
        table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.ARTY, 30))
      
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
  
    ---
    -- AIRBASE
    ---
  
    -- Bomb runway.
    table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.BOMBRUNWAY, 100))
    table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.ARTY,        30))

  elseif static then
  
    ---
    -- STATIC
    ---

    table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.BAI,       100))
    table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.BOMBING,    70))
    table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.BOMBCARPET, 50))
    table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.ARTY,       30))
    
  elseif scenery then
  
    ---
    -- SCENERY
    ---
  
    table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.STRIKE,    100))
    table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.BOMBING,    70))
    table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.BOMBCARPET, 50))
    table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.ARTY,       30))
    
  elseif coordinate then
  
    ---
    -- COORDINATE
    ---
  
    table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.BOMBING,   100))
    table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.BOMBCARPET, 50))
    table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.ARTY,       30))
    
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
    
    -- Check that runway is operational.d 
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
-- @param #CHIEF.StrategicZone StratZone The strategic zone.
-- @param #CHIEF.Resource Resource The required resources.
-- @return #boolean If `true` enough assets could be recruited.
function CHIEF:RecruitAssetsForZone(StratZone, Resource)

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
  
  -- Shortcuts.
  local MissionType=Resource.MissionType
  local NassetsMin=Resource.Nmax
  local NassetsMax=Resource.Nmax
  local Categories=Resource.Categories
  local Attributes=Resource.Attributes
  local Properties=Resource.Properties

  -- Target position.
  local TargetVec2=StratZone.opszone.zone:GetVec2()
  
  -- Max range in meters.
  local RangeMax=nil
  
  -- Set max range to 250 NM because we use helos as transport for the infantry.
  if MissionType==AUFTRAG.Type.PATROLZONE or MissionType==AUFTRAG.Type.ONGUARD then
    RangeMax=UTILS.NMToMeters(250)
  end
  
  -- Set max range to 50 NM because we use armor.
  if MissionType==AUFTRAG.Type.ARMOREDGUARD then
    RangeMax=UTILS.NMToMeters(50)
  end

  -- Recruite infantry assets.
  local recruited, assets, legions=LEGION.RecruitCohortAssets(Cohorts, MissionType, nil, NassetsMin, NassetsMax, TargetVec2, nil, RangeMax, nil, nil, nil, Categories, Attributes, Properties)
  
  if recruited then
  
    -- Mission for zone.
    local mission=nil  --Ops.Auftrag#AUFTRAG  
  
    -- Debug messgage.
    self:T2(self.lid..string.format("Recruited %d assets for %s mission STRATEGIC zone %s", #assets, MissionType, tostring(StratZone.opszone.zoneName)))
    
    local TargetZone  = StratZone.opszone.zone
    local TargetCoord = TargetZone:GetCoordinate()    
  
    if MissionType==AUFTRAG.Type.PATROLZONE or MissionType==AUFTRAG.Type.ONGUARD then
    
      ---
      -- PATROLZONE or ONGUARD
      ---
     
      -- Debug messgage.
      self:T2(self.lid..string.format("Recruited %d assets for PATROL mission", #assets))
      
      -- First check if we need a transportation.
      local recruitedTrans=true ; local transport=nil
      if Attributes and Attributes[1]==GROUP.Attribute.GROUND_INFANTRY then
      
        -- Categories. Currently only helicopters are allowed due to problems with ground transports (might get stuck, might not be a land connection.
        -- TODO: Check if ground transport is possible. For example, by trying land.getPathOnRoad or something.
        local Categories=self.TransportCategories
  
        -- Recruit transport assets for infantry.    
        recruitedTrans, transport=LEGION.AssignAssetsForTransport(self.commander, self.commander.legions, assets, 1, 1, TargetZone, nil, Categories)
        
      end
      
      if recruitedTrans then
        
        if MissionType==AUFTRAG.Type.PATROLZONE then
          mission=AUFTRAG:NewPATROLZONE(TargetZone)
          
        elseif MissionType==AUFTRAG.Type.ONGUARD then 
          mission=AUFTRAG:NewONGUARD(TargetZone:GetRandomCoordinate(nil, nil, {land.SurfaceType.LAND}))
        end
        
        -- Engage detected targets.
        mission:SetEngageDetected(25, {"Ground Units", "Light armed ships", "Helicopters"})            
                        
        -- Attach OPS transport to mission.
        mission.opstransport=transport
                    
        -- Set ops zone to transport.
        if transport then
          transport.opszone=StratZone.opszone
          transport.chief=self
          transport.commander=self.commander
        end

      else
        -- No transport ==> no mission!
        self:T(self.lid..string.format("Could not allocate transport of OPSZONE infantry!"))
        LEGION.UnRecruitAssets(assets)
        return false
      end
      
    elseif MissionType==AUFTRAG.Type.CASENHANCED then
    
      ---
      -- CAS ENHANCED
      ---

      -- Create Patrol zone mission.
      local height = UTILS.MetersToFeet(TargetCoord:GetLandHeight())+2500
      
      local Speed=200
      if assets[1] then
        if assets[1].speedmax then
          Speed = UTILS.KmphToKnots(assets[1].speedmax * 0.7) or 200
        end
      end

      -- CAS mission.
      mission=AUFTRAG:NewCASENHANCED(TargetZone, height, Speed)

    elseif MissionType==AUFTRAG.Type.CAS then
    
      ---
      -- CAS
      ---

      -- Create Patrol zone mission.
      local height = UTILS.MetersToFeet(TargetCoord:GetLandHeight())+2500
      
      local Speed = 200      
      if assets[1] then
        if assets[1].speedmax then
          Speed = UTILS.KmphToKnots(assets[1].speedmax * 0.7) or 200
        end
      end
      
      -- Leg length.
      local Leg = TargetZone:GetRadius() <= 10000 and 5 or UTILS.MetersToNM(TargetZone:GetRadius())
      
      -- CAS mission.
      mission=AUFTRAG:NewCAS(TargetZone, height, Speed, TargetCoord, math.random(0,359), Leg)

    elseif MissionType==AUFTRAG.Type.ARTY then
    
      ---
      -- ARTY
      ---
      
      -- Create ARTY zone mission.
      local Radius = TargetZone:GetRadius()
      
      mission=AUFTRAG:NewARTY(TargetCoord, 120, Radius)

    elseif MissionType==AUFTRAG.Type.ARMOREDGUARD then
    
      --- 
      -- ARMORGUARD
      ---
      
      -- Create Armored on guard mission
      mission=AUFTRAG:NewARMOREDGUARD(TargetCoord)
      
    elseif MissionType==AUFTRAG.Type.BOMBCARPET then
    
      ---
      -- BOMB CARPET
      ---
    
      -- Create ARTY zone mission.
      mission=AUFTRAG:NewBOMBCARPET(TargetCoord, nil, 1000)

    elseif MissionType==AUFTRAG.Type.BOMBING then

      ---
      -- BOMBING
      ---
    
      local coord=TargetZone:GetRandomCoordinate()
    
      mission=AUFTRAG:NewBOMBING(TargetCoord)
      
    elseif MissionType==AUFTRAG.Type.RECON then
    
      ---
      -- RECON
      ---    
    
      mission=AUFTRAG:NewRECON(TargetZone, nil, 5000)
      
    elseif MissionType==AUFTRAG.Type.BARRAGE then

      ---
      -- BARRAGE
      ---    
      
      mission=AUFTRAG:NewBARRAGE(TargetZone)
      
    elseif MissionType==AUFTRAG.Type.AMMOSUPPLY then

      ---
      -- AMMO SUPPLY
      ---    
    
      mission=AUFTRAG:NewAMMOSUPPLY(TargetZone)

    end
    
    if mission then

      -- Add assets to mission.
      for _,asset in pairs(assets) do
        mission:AddAsset(asset)
      end
          
      -- Assign mission to legions.
      self:MissionAssign(mission, legions)
    
      -- Attach mission to ops zone.
      StratZone.opszone:_AddMission(self.coalition, MissionType, mission)
      
      -- Attach mission to resource.
      Resource.mission=mission
    
      return true      
    else
      
      -- Mission not supported.
      self:E(self.lid..string.format("ERROR: Mission type not supported for OPSZONE! Unrecruiting assets..."))
      LEGION.UnRecruitAssets(assets)
      
      return false  
    end
    
  end

    -- Debug messgage.
    self:T2(self.lid..string.format("Could NOT recruit assets for %s mission of STRATEGIC zone %s", MissionType, tostring(StratZone.opszone.zoneName)))  

  return false
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
