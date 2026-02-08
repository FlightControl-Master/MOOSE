--- **Ops** - Transport assignment for OPS groups and storage.
-- 
-- ## Main Features:
--
--    * Transport troops from A to B
--    * Transport of warehouse storage (fuel, weapons and equipment)
--    * Supports ground, naval and airborne (airplanes and helicopters) units as carriers
--    * Use combined forces (ground, naval, air) to transport the troops
--    * Additional FSM events to hook into and customize your mission design
--
-- ===
--
-- ## Example Missions:
-- 
-- Demo missions can be found on [github](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/develop/Ops/Transport).
--    
-- ===
--
-- ### Author: **funkyfranky**
-- 
-- ===
-- @module Ops.OpsTransport
-- @image OPS_OpsTransport.png


--- OPSTRANSPORT class.
-- @type OPSTRANSPORT
-- @field #string ClassName Name of the class.
-- @field #string lid Log ID.
-- @field #number uid Unique ID of the transport.
-- @field #number verbose Verbosity level.
-- 
-- @field #number prio Priority of this transport. Should be a number between 0 (high prio) and 100 (low prio).
-- @field #boolean urgent If true, transport is urgent.
-- @field #number importance Importance of this transport. Smaller=higher.
-- @field #number Tstart Start time in *abs.* seconds.
-- @field #number Tstop Stop time in *abs.* seconds. Default `#nil` (never stops).
-- @field #number duration Duration (`Tstop-Tstart`) of the transport in seconds.
-- @field #table conditionStart Start conditions.
-- 
-- @field #table carriers Carriers assigned for this transport.
-- @field #table carrierTransportStatus Status of each carrier.
--  
-- @field #table tzCombos Table of transport zone combos. Each element of the table is of type `#OPSTRANSPORT.TransportZoneCombo`.
-- @field #number tzcCounter Running number of added transport zone combos.
-- @field #OPSTRANSPORT.TransportZoneCombo tzcDefault Default transport zone combo.
-- 
-- @field #number Ncargo Total number of cargo groups.
-- @field #number Ncarrier Total number of assigned carriers.
-- @field #number Ndelivered Total number of cargo groups delivered.
-- @field #number NcarrierDead Total number of dead carrier groups
-- @field #number NcargoDead Totalnumber of dead cargo groups.
-- 
-- @field #string formationArmy Default formation for ground vehicles.
-- @field #string formationHelo Default formation for helicopters.
-- @field #string formationPlane Default formation for airplanes.
-- 
-- @field Ops.Auftrag#AUFTRAG mission The mission attached to this transport.
-- @field #table assets Warehouse assets assigned for this transport.
-- @field #table legions Assigned legions.
-- @field #table statusLegion Transport status of all assigned LEGIONs.
-- @field #string statusCommander Staus of the COMMANDER.
-- @field Ops.Commander#COMMANDER commander Commander of the transport.
-- @field Ops.Chief#CHIEF chief Chief of the transport.
-- @field Ops.OpsZone#OPSZONE opszone OPS zone.
-- @field #table requestID The ID of the queued warehouse request. Necessary to cancel the request if the transport was cancelled before the request is processed.
-- @field #number cargocounter Running number to generate cargo UIDs.
-- 
-- @extends Core.Fsm#FSM

--- *Victory is the beautiful, bright-colored flower; Transport is the stem without which it could never have blossomed* -- Winston Churchill
--
-- ===
--
-- # The OPSTRANSPORT Concept
-- 
-- This class simulates troop transport using carriers such as APCs, ships, helicopters or airplanes. The carriers and transported groups need to be OPSGROUPS (see ARMYGROUP, NAVYGROUP and FLIGHTGROUP classes).
-- 
-- **IMPORTANT NOTES**
-- 
-- * Cargo groups are **not** split and distributed into different carrier *units*. That means that the whole cargo group **must fit** into one of the carrier units.
-- * Cargo groups must be inside the pickup zones to be considered for loading. Groups not inside the pickup zone will not get the command to board. 
-- 
-- # Troop Transport
-- 
-- A new cargo transport assignment is created with the @{#OPSTRANSPORT.New}() function
-- 
--     local opstransport=OPSTRANSPORT:New(Cargo, PickupZone, DeployZone)
-- 
-- Here `Cargo` is an object of the troops to be transported. This can be a GROUP, OPSGROUP, SET_GROUP or SET_OPSGROUP object.
-- 
-- `PickupZone` is the zone where the troops are picked up by the transport carriers. **Note** that troops *must* be inside this zone to be considered for loading!
-- 
-- `DeployZone` is the zone where the troops are transported to.
-- 
-- ## Assign to Carrier(s)
-- 
-- A transport can be assigned to one or multiple carrier OPSGROUPS with this @{Ops.OpsGroup#OPSGROUP.AddOpsTransport}() function
-- 
--     myopsgroup:AddOpsTransport(opstransport)
-- 
-- There is no restriction to the type of the carrier. It can be a ground group (e.g. an APC), a helicopter, an airplane or even a ship.
-- 
-- You can also mix carrier types. For instance, you can assign the same transport to APCs and helicopters. Or to helicopters and airplanes.
-- 
-- # Storage Transport
-- 
-- An instance of the OPSTRANSPORT class is created similarly to the troop transport case. However, the first parameter is `nil` as not troops 
-- are transported.
-- 
--     local storagetransport=OPSTRANSPORT:New(nil, PickupZone, DeployZone) 
-- 
-- ## Defining Storage
-- 
-- The storage warehouses from which the cargo is taken and to which the cargo is delivered have to be specified
-- 
--     storagetransport:AddCargoStorage(berlinStorage, batumiStorage, STORAGE.Liquid.JETFUEL, 1000)
--     
-- Here `berlinStorage` and `batumiStorage` are @{Wrapper.Storage#STORAGE} objects of DCS warehouses. 
-- 
-- Furthermore, that type of cargo (liquids or weapons/equipment) and the amount has to be specified. If weapons/equipment is the cargo,
-- we also need to specify the weight per storage item as this cannot be retrieved from the DCS API and is not stored in any MOOSE database.
-- 
--     storagetransport:AddCargoStorage(berlinStorage, batumiStorage, ENUMS.Storage.weapons.bombs.Mk_82, 9, 230)     
--
-- Finally, the transport is assigned to one or multiple groups, which carry out the transport
-- 
--     myopsgroup:AddOpsTransport(storagetransport)
-- 
-- # Examples
--
-- A carrier group is assigned to transport infantry troops from zone "Zone Kobuleti X" to zone "Zone Alpha".
--
--     -- Carrier group.
--     local carrier=ARMYGROUP:New("TPz Fuchs Group")
--       
--     -- Set of groups to transport.
--     local infantryset=SET_GROUP:New():FilterPrefixes("Infantry Platoon Alpha"):FilterOnce()
--     
--     -- Cargo transport assignment.
--     local opstransport=OPSTRANSPORT:New(infantryset, ZONE:New("Zone Kobuleti X"), ZONE:New("Zone Alpha"))
--     
--     -- Assign transport to carrier.
--     carrier:AddOpsTransport(opstransport)
-- 
-- 
-- @field #OPSTRANSPORT
OPSTRANSPORT = {
  ClassName       = "OPSTRANSPORT",
  verbose         =   0,
  carriers        =  {},
  carrierTransportStatus = {},
  tzCombos        =  {},
  tzcCounter      =   0,
  conditionStart  =  {},
  assets          =  {},
  legions         =  {},
  statusLegion    =  {},
  requestID       =  {},
  cargocounter    =   0,
}

--- Cargo transport status.
-- @type OPSTRANSPORT.Status
-- @field #string PLANNED Planning state.
-- @field #string QUEUED Queued state.
-- @field #string REQUESTED Requested state.
-- @field #string SCHEDULED Transport is scheduled in the cargo queue.
-- @field #string EXECUTING Transport is being executed.
-- @field #string DELIVERED Transport was delivered. 
-- @field #string CANCELLED Transport was cancelled.
-- @field #string SUCCESS Transport was a success.
-- @field #string FAILED Transport failed.
OPSTRANSPORT.Status={
  PLANNED="planned",
  QUEUED="queued",
  REQUESTED="requested",
  SCHEDULED="scheduled",
  EXECUTING="executing",
  DELIVERED="delivered",
  CANCELLED="cancelled",
  SUCCESS="success",
  FAILED="failed",  
}

--- Transport zone combination.
-- @type OPSTRANSPORT.TransportZoneCombo
-- @field #number uid Unique ID of the TZ combo.
-- @field #number Ncarriers Number of carrier groups using this transport zone.
-- @field #number Ncargo Number of cargos assigned. This is a running number and *not* decreased if cargo is delivered or dead.
-- @field #table Cargos Cargo groups of the TZ combo. Each element is of type `Ops.OpsGroup#OPSGROUP.CargoGroup`.
-- @field Core.Zone#ZONE PickupZone Pickup zone.
-- @field Core.Zone#ZONE DeployZone Deploy zone.
-- @field Core.Zone#ZONE EmbarkZone Embark zone if different from pickup zone.
-- @field Core.Zone#ZONE DisembarkZone Zone where the troops are disembared to.
-- @field Wrapper.Airbase#AIRBASE PickupAirbase Airbase for pickup.
-- @field Wrapper.Airbase#AIRBASE DeployAirbase Airbase for deploy.
-- @field #table PickupPaths Paths for pickup. 
-- @field #table TransportPaths Path for Transport. Each elment of the table is of type `#OPSTRANSPORT.Path`. 
-- @field #table RequiredCargos Required cargos.
-- @field #table DisembarkCarriers Carriers where the cargo is directly disembarked to.
-- @field #boolean disembarkToCarriers If `true`, cargo is supposed to embark to another carrier.
-- @field #boolean disembarkActivation If true, troops are spawned in late activated state when disembarked from carrier.
-- @field #boolean disembarkInUtero If true, troops are disembarked "in utero".
-- @field #boolean assets Cargo assets.
-- @field #number PickupFormation Formation used to pickup.
-- @field #number TransportFormation Formation used to transport.

--- Path used for pickup or transport.
-- @type OPSTRANSPORT.Path
-- @field #table waypoints Table of waypoints.
-- @field #number category Category for which carriers this path is used.
-- @field #number radius Radomization radius for waypoints in meters. Default 0 m.
-- @field #boolean reverse If `true`, path is used in reversed order.

--- Storage data.
-- @type OPSTRANSPORT.Storage
-- @field Wrapper.Storage#STORAGE storageFrom Storage from.
-- @field Wrapper.Storage#STORAGE storageTo Storage To.
-- @field #string cargoType Type of cargo.
-- @field #number cargoAmount Amount of cargo that should be transported.
-- @field #number cargoReserved Amount of cargo that is reserved for a carrier group.
-- @field #number cargoDelivered Amount of cargo that has been delivered.
-- @field #number cargoLost Amount of cargo that was lost.
-- @field #number cargoLoaded Amount of cargo that is loading.
-- @field #number cargoWeight Weight of one single cargo item in kg. Default 1 kg.

--- Storage data.
-- @type OPSTRANSPORT.CargoType
-- @field #string OPSGROUP Cargo is an OPSGROUP.
-- @field #string STORAGE Cargo is storage of DCS warehouse.
OPSTRANSPORT.CargoType={
  OPSGROUP="OPSGROUP",
  STORAGE="STORAGE",
}

--- Generic transport condition.
-- @type OPSTRANSPORT.Condition
-- @field #function func Callback function to check for a condition. Should return a #boolean.
-- @field #table arg Optional arguments passed to the condition callback function.

--- Transport ID.
_OPSTRANSPORTID=0

--- Army Group version.
-- @field #string version
OPSTRANSPORT.version="0.9.0"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Trains.
-- TODO: Stop transport.
-- TODO: Improve pickup and transport paths.
-- DONE: Storage.
-- DONE: Disembark parameters per cargo group.
-- DONE: Special transport cohorts/legions. Similar to mission.
-- DONE: Cancel transport.
-- DONE: Allow multiple pickup/depoly zones.
-- DONE: Add start conditions.
-- DONE: Check carrier(s) dead.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new OPSTRANSPORT class object. Essential input are the troops that should be transported and the zones where the troops are picked up and deployed.
-- @param #OPSTRANSPORT self
-- @param Core.Set#SET_GROUP CargoGroups Groups to be transported as cargo. Can also be a single @{Wrapper.Group#GROUP} or @{Ops.OpsGroup#OPSGROUP} object.
-- @param Core.Zone#ZONE PickupZone Pickup zone. This is the zone, where the carrier is going to pickup the cargo. **Important**: only cargo is considered, if it is in this zone when the carrier starts loading!
-- @param Core.Zone#ZONE DeployZone Deploy zone. This is the zone, where the carrier is going to drop off the cargo.
-- @return #OPSTRANSPORT self
function OPSTRANSPORT:New(CargoGroups, PickupZone, DeployZone)

  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, FSM:New()) -- #OPSTRANSPORT
  
  -- Increase ID counter.
  _OPSTRANSPORTID=_OPSTRANSPORTID+1
  
  -- Set some string id for output to DCS.log file.
  self.lid=string.format("OPSTRANSPORT [UID=%d] | ", _OPSTRANSPORTID)
  
  -- UID of this transport.
  self.uid=_OPSTRANSPORTID
      
  -- Defaults.
  self:SetPriority()
  self:SetTime()
  self:SetRequiredCarriers()
  
  self.formationArmy=ENUMS.Formation.Vehicle.OnRoad
  self.formationHelo=ENUMS.Formation.RotaryWing.Wedge
  self.formationPlane=ENUMS.Formation.FixedWing.Wedge
  
  -- Init arrays and counters.
  self.carriers={}  
  self.Ncargo=0
  self.Ncarrier=0
  self.Ndelivered=0
  self.NcargoDead=0
  self.NcarrierDead=0
  
  -- Set default TZC.
  self.tzcDefault=self:AddTransportZoneCombo(CargoGroups, PickupZone, DeployZone)  
  
  -- FMS start state is PLANNED.
  self:SetStartState(OPSTRANSPORT.Status.PLANNED)
  
  -- PLANNED --> SCHEDULED --> EXECUTING --> DELIVERED  
  self:AddTransition("*",                           "Planned",          OPSTRANSPORT.Status.PLANNED)     -- Cargo transport was planned.
  self:AddTransition(OPSTRANSPORT.Status.PLANNED,   "Queued",           OPSTRANSPORT.Status.QUEUED)      -- Cargo is queued at at least one carrier.
  self:AddTransition(OPSTRANSPORT.Status.QUEUED,    "Requested",        OPSTRANSPORT.Status.REQUESTED)   -- Transport assets have been requested from a warehouse.
  self:AddTransition(OPSTRANSPORT.Status.REQUESTED, "Scheduled",        OPSTRANSPORT.Status.SCHEDULED)   -- Cargo is queued at at least one carrier.
  self:AddTransition(OPSTRANSPORT.Status.PLANNED,   "Scheduled",        OPSTRANSPORT.Status.SCHEDULED)   -- Cargo is queued at at least one carrier.  
  self:AddTransition(OPSTRANSPORT.Status.SCHEDULED, "Executing",        OPSTRANSPORT.Status.EXECUTING)   -- Cargo is being transported.  
  self:AddTransition("*",                           "Delivered",        OPSTRANSPORT.Status.DELIVERED)   -- Cargo was delivered.
  
  self:AddTransition("*",                           "StatusUpdate",     "*")
  self:AddTransition("*",                           "Stop",             "*")
  
  self:AddTransition("*",                           "Cancel",           OPSTRANSPORT.Status.CANCELLED)   -- Command to cancel the transport.  
  
  self:AddTransition("*",                           "Loaded",           "*")
  self:AddTransition("*",                           "Unloaded",         "*")
  
  self:AddTransition("*",                           "DeadCarrierUnit",  "*")
  self:AddTransition("*",                           "DeadCarrierGroup", "*")
  self:AddTransition("*",                           "DeadCarrierAll",   "*")

  ------------------------
  --- Pseudo Functions ---
  ------------------------

  --- Triggers the FSM event "StatusUpdate".
  -- @function [parent=#OPSTRANSPORT] StatusUpdate
  -- @param #OPSTRANSPORT self

  --- Triggers the FSM event "Status" after a delay.
  -- @function [parent=#OPSTRANSPORT] __StatusUpdate
  -- @param #OPSTRANSPORT self
  -- @param #number delay Delay in seconds.


  --- Triggers the FSM event "Planned".
  -- @function [parent=#OPSTRANSPORT] Planned
  -- @param #OPSTRANSPORT self

  --- Triggers the FSM event "Planned" after a delay.
  -- @function [parent=#OPSTRANSPORT] __Planned
  -- @param #OPSTRANSPORT self
  -- @param #number delay Delay in seconds.

  --- On after "Planned" event.
  -- @function [parent=#OPSTRANSPORT] OnAfterPlanned
  -- @param #OPSTRANSPORT self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.


  --- Triggers the FSM event "Queued".
  -- @function [parent=#OPSTRANSPORT] Queued
  -- @param #OPSTRANSPORT self

  --- Triggers the FSM event "Queued" after a delay.
  -- @function [parent=#OPSTRANSPORT] __Queued
  -- @param #OPSTRANSPORT self
  -- @param #number delay Delay in seconds.

  --- On after "Queued" event.
  -- @function [parent=#OPSTRANSPORT] OnAfterQueued
  -- @param #OPSTRANSPORT self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.


  --- Triggers the FSM event "Requested".
  -- @function [parent=#OPSTRANSPORT] Requested
  -- @param #OPSTRANSPORT self

  --- Triggers the FSM event "Requested" after a delay.
  -- @function [parent=#OPSTRANSPORT] __Requested
  -- @param #OPSTRANSPORT self
  -- @param #number delay Delay in seconds.

  --- On after "Requested" event.
  -- @function [parent=#OPSTRANSPORT] OnAfterRequested
  -- @param #OPSTRANSPORT self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.


  --- Triggers the FSM event "Scheduled".
  -- @function [parent=#OPSTRANSPORT] Scheduled
  -- @param #OPSTRANSPORT self

  --- Triggers the FSM event "Scheduled" after a delay.
  -- @function [parent=#OPSTRANSPORT] __Scheduled
  -- @param #OPSTRANSPORT self
  -- @param #number delay Delay in seconds.

  --- On after "Scheduled" event.
  -- @function [parent=#OPSTRANSPORT] OnAfterScheduled
  -- @param #OPSTRANSPORT self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.


  --- Triggers the FSM event "Executing".
  -- @function [parent=#OPSTRANSPORT] Executing
  -- @param #OPSTRANSPORT self

  --- Triggers the FSM event "Executing" after a delay.
  -- @function [parent=#OPSTRANSPORT] __Executing
  -- @param #OPSTRANSPORT self
  -- @param #number delay Delay in seconds.

  --- On after "Executing" event.
  -- @function [parent=#OPSTRANSPORT] OnAfterExecuting
  -- @param #OPSTRANSPORT self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.


  --- Triggers the FSM event "Delivered".
  -- @function [parent=#OPSTRANSPORT] Delivered
  -- @param #OPSTRANSPORT self

  --- Triggers the FSM event "Delivered" after a delay.
  -- @function [parent=#OPSTRANSPORT] __Delivered
  -- @param #OPSTRANSPORT self
  -- @param #number delay Delay in seconds.

  --- On after "Delivered" event.
  -- @function [parent=#OPSTRANSPORT] OnAfterDelivered
  -- @param #OPSTRANSPORT self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.


  --- Triggers the FSM event "Cancel".
  -- @function [parent=#OPSTRANSPORT] Cancel
  -- @param #OPSTRANSPORT self

  --- Triggers the FSM event "Cancel" after a delay.
  -- @function [parent=#OPSTRANSPORT] __Cancel
  -- @param #OPSTRANSPORT self
  -- @param #number delay Delay in seconds.

  --- On after "Cancel" event.
  -- @function [parent=#OPSTRANSPORT] OnAfterCancel
  -- @param #OPSTRANSPORT self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.


  --- Triggers the FSM event "Loaded".
  -- @function [parent=#OPSTRANSPORT] Loaded
  -- @param #OPSTRANSPORT self
  -- @param Ops.OpsGroup#OPSGROUP OpsGroupCargo OPSGROUP that was loaded into a carrier.
  -- @param Ops.OpsGroup#OPSGROUP OpsGroupCarrier OPSGROUP that was loaded into a carrier.
  -- @param Ops.OpsGroup#OPSGROUP.Element CarrierElement Carrier element.

  --- Triggers the FSM event "Loaded" after a delay.
  -- @function [parent=#OPSTRANSPORT] __Loaded
  -- @param #OPSTRANSPORT self
  -- @param #number delay Delay in seconds.
  -- @param Ops.OpsGroup#OPSGROUP OpsGroupCargo OPSGROUP that was loaded into a carrier.
  -- @param Ops.OpsGroup#OPSGROUP OpsGroupCarrier OPSGROUP that was loaded into a carrier.
  -- @param Ops.OpsGroup#OPSGROUP.Element CarrierElement Carrier element.

  --- On after "Loaded" event.
  -- @function [parent=#OPSTRANSPORT] OnAfterLoaded
  -- @param #OPSTRANSPORT self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.OpsGroup#OPSGROUP OpsGroupCargo OPSGROUP that was loaded into a carrier.
  -- @param Ops.OpsGroup#OPSGROUP OpsGroupCarrier OPSGROUP that was loaded into a carrier.
  -- @param Ops.OpsGroup#OPSGROUP.Element CarrierElement Carrier element.


  --- Triggers the FSM event "Unloaded".
  -- @function [parent=#OPSTRANSPORT] Unloaded
  -- @param #OPSTRANSPORT self
  -- @param Ops.OpsGroup#OPSGROUP OpsGroupCargo Cargo OPSGROUP that was unloaded from a carrier.
  -- @param Ops.OpsGroup#OPSGROUP OpsGroupCarrier Carrier OPSGROUP that unloaded the cargo.

  --- Triggers the FSM event "Unloaded" after a delay.
  -- @function [parent=#OPSTRANSPORT] __Unloaded
  -- @param #OPSTRANSPORT self
  -- @param #number delay Delay in seconds.
  -- @param Ops.OpsGroup#OPSGROUP OpsGroupCargo Cargo OPSGROUP that was unloaded from a carrier.
  -- @param Ops.OpsGroup#OPSGROUP OpsGroupCarrier Carrier OPSGROUP that unloaded the cargo.

  --- On after "Unloaded" event.
  -- @function [parent=#OPSTRANSPORT] OnAfterUnloaded
  -- @param #OPSTRANSPORT self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.OpsGroup#OPSGROUP OpsGroupCargo Cargo OPSGROUP that was unloaded from a carrier.
  -- @param Ops.OpsGroup#OPSGROUP OpsGroupCarrier Carrier OPSGROUP that unloaded the cargo.

  
  --TODO: Psydofunctions

  -- Call status update.
  self:__StatusUpdate(-1)
  
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Add pickup and deploy zone combination.
-- @param #OPSTRANSPORT self
-- @param Core.Set#SET_GROUP CargoGroups Groups to be transported as cargo. Can also be a single @{Wrapper.Group#GROUP} or @{Ops.OpsGroup#OPSGROUP} object.
-- @param Core.Zone#ZONE PickupZone Zone where the troops are picked up.
-- @param Core.Zone#ZONE DeployZone Zone where the troops are picked up.
-- @return #OPSTRANSPORT.TransportZoneCombo Transport zone table.
function OPSTRANSPORT:AddTransportZoneCombo(CargoGroups, PickupZone, DeployZone)

  -- Increase counter.
  self.tzcCounter=self.tzcCounter+1  
  
  local tzcombo={} --#OPSTRANSPORT.TransportZoneCombo

  -- Init.
  tzcombo.uid=self.tzcCounter
  tzcombo.Ncarriers=0
  tzcombo.Ncargo=0
  tzcombo.Cargos={}
  tzcombo.RequiredCargos={}
  tzcombo.DisembarkCarriers={}
  tzcombo.PickupPaths={}
  tzcombo.TransportPaths={}
  
  -- Set zones.
  self:SetPickupZone(PickupZone, tzcombo)
  self:SetDeployZone(DeployZone, tzcombo)
  self:SetEmbarkZone(nil, tzcombo)
  
  -- Add cargo groups (could also be added later).
  if CargoGroups then
    self:AddCargoGroups(CargoGroups, tzcombo)
  end  
    
  -- Add to table.
  table.insert(self.tzCombos, tzcombo)
  
  return tzcombo
end

--- Add cargo groups to be transported.
-- @param #OPSTRANSPORT self
-- @param Core.Set#SET_GROUP GroupSet Set of groups to be transported. Can also be passed as a single GROUP or OPSGROUP object.
-- @param #OPSTRANSPORT.TransportZoneCombo TransportZoneCombo Transport zone combo.
-- @param #boolean DisembarkActivation If `true`, cargo group is activated when disembarked. If `false`, cargo groups are late activated when disembarked. Default `nil` (usually activated).
-- @param Core.Zone#ZONE DisembarkZone Zone where the groups disembark to.
-- @param Core.Set#SET_OPSGROUP DisembarkCarriers Carrier groups where the cargo directly disembarks to.
-- @return #OPSTRANSPORT self
function OPSTRANSPORT:AddCargoGroups(GroupSet, TransportZoneCombo, DisembarkActivation, DisembarkZone, DisembarkCarriers)

  -- Use default TZC if no transport zone combo is provided.
  TransportZoneCombo=TransportZoneCombo or self.tzcDefault

  -- Check type of GroupSet provided.
  if GroupSet:IsInstanceOf("GROUP") or GroupSet:IsInstanceOf("OPSGROUP") then

    -- We got a single GROUP or OPSGROUP object.
    local cargo=self:_CreateCargoGroupData(GroupSet, TransportZoneCombo, DisembarkActivation, DisembarkZone, DisembarkCarriers)
    
    if cargo then
    
      -- Add to main table.
      --table.insert(self.cargos, cargo)
      self.Ncargo=self.Ncargo+1
      
      -- Add to TZC table.
      table.insert(TransportZoneCombo.Cargos, cargo)
      TransportZoneCombo.Ncargo=TransportZoneCombo.Ncargo+1
      
      cargo.opsgroup:_AddMyLift(self)
      
    end
    
  else
  
    -- We got a SET_GROUP object.
    
    for _,group in pairs(GroupSet.Set) do
    
      -- Call iteravely for each group.
      self:AddCargoGroups(group, TransportZoneCombo, DisembarkActivation)
      
    end
    
    -- Use FSM function to keep the SET up-to-date. Note that it overwrites the user FMS function, which cannot be used any more now.
    local groupset=GroupSet --Core.Set#SET_OPSGROUP
    function groupset.OnAfterAdded(groupset, From, Event, To, ObjectName, Object)
    
      self:T(self.lid..string.format("Adding Cargo Group %s", tostring(ObjectName)))
      self:AddCargoGroups(Object, TransportZoneCombo, DisembarkActivation, DisembarkZone, DisembarkCarriers)
    
    end    
    
  end
  
  -- Debug info.
  if self.verbose>=1 then
    local text=string.format("Added cargo groups:")
    local Weight=0
    for _,_cargo in pairs(self:GetCargos()) do
      local cargo=_cargo --Ops.OpsGroup#OPSGROUP.CargoGroup
      local weight=cargo.opsgroup:GetWeightTotal()
      Weight=Weight+weight
      text=text..string.format("\n- %s [%s] weight=%.1f kg", cargo.opsgroup:GetName(), cargo.opsgroup:GetState(), weight)
    end
    text=text..string.format("\nTOTAL: Ncargo=%d, Weight=%.1f kg", self.Ncargo, Weight)
    self:I(self.lid..text)
  end


  return self
end

--- Add cargo warehouse storage to be transported. This adds items such as fuel, weapons and other equipment, which is to be transported
-- from one DCS warehouse to another.
-- For weapons and equipment, the weight per item has to be specified explicitly as these cannot be retrieved by the DCS API. For liquids the
-- default value of 1 kg per item should be used as the amount of liquid is already given in kg.
-- @param #OPSTRANSPORT self
-- @param Wrapper.Storage#STORAGE StorageFrom Storage warehouse from which the cargo is taken.
-- @param Wrapper.Storage#STORAGE StorageTo Storage warehouse to which the cargo is delivered.
-- @param #string CargoType Type of cargo, *e.g.* `"weapons.bombs.Mk_84"` or liquid type as #number.
-- @param #number CargoAmount Amount of cargo. Liquids in kg.
-- @param #number CargoWeight Weight of a single cargo item in kg. Default 1 kg.
-- @param #OPSTRANSPORT.TransportZoneCombo TransportZoneCombo Transport zone combo if other than default.
-- @return #OPSTRANSPORT self
function OPSTRANSPORT:AddCargoStorage(StorageFrom, StorageTo, CargoType, CargoAmount, CargoWeight, TransportZoneCombo)

  -- Use default TZC if no transport zone combo is provided.
  TransportZoneCombo=TransportZoneCombo or self.tzcDefault

  -- Cargo data.
  local cargo=self:_CreateCargoStorage(StorageFrom,StorageTo, CargoType, CargoAmount, CargoWeight, TransportZoneCombo)
  
  if cargo then
  
    -- Add total amount of ever assigned cargos.
    self.Ncargo=self.Ncargo+1

    -- Add to TZC table.
    table.insert(TransportZoneCombo.Cargos, cargo)

  end

end


--- Set pickup zone.
-- @param #OPSTRANSPORT self
-- @param Core.Zone#ZONE PickupZone Zone where the troops are picked up.
-- @param #OPSTRANSPORT.TransportZoneCombo TransportZoneCombo Transport zone combo.
-- @return #OPSTRANSPORT self
function OPSTRANSPORT:SetPickupZone(PickupZone, TransportZoneCombo)

  -- Use default TZC if no transport zone combo is provided.
  TransportZoneCombo=TransportZoneCombo or self.tzcDefault

  TransportZoneCombo.PickupZone=PickupZone

  if PickupZone and PickupZone:IsInstanceOf("ZONE_AIRBASE") then
    TransportZoneCombo.PickupAirbase=PickupZone._.ZoneAirbase
  end
  
  return self
end

--- Get pickup zone.
-- @param #OPSTRANSPORT self
-- @param #OPSTRANSPORT.TransportZoneCombo TransportZoneCombo Transport zone combo.
-- @return Core.Zone#ZONE Zone where the troops are picked up.
function OPSTRANSPORT:GetPickupZone(TransportZoneCombo)

  -- Use default TZC if no transport zone combo is provided.
  TransportZoneCombo=TransportZoneCombo or self.tzcDefault

  return TransportZoneCombo.PickupZone
end

--- Set deploy zone.
-- @param #OPSTRANSPORT self
-- @param Core.Zone#ZONE DeployZone Zone where the troops are deployed.
-- @param #OPSTRANSPORT.TransportZoneCombo TransportZoneCombo Transport zone combo.
-- @return #OPSTRANSPORT self
function OPSTRANSPORT:SetDeployZone(DeployZone, TransportZoneCombo)

  -- Use default TZC if no transport zone combo is provided.
  TransportZoneCombo=TransportZoneCombo or self.tzcDefault

  -- Set deploy zone.
  TransportZoneCombo.DeployZone=DeployZone

  -- Check if this is an airbase.
  if DeployZone and DeployZone:IsInstanceOf("ZONE_AIRBASE") then
    TransportZoneCombo.DeployAirbase=DeployZone._.ZoneAirbase
  end
  
  return self
end

--- Get deploy zone.
-- @param #OPSTRANSPORT self
-- @param #OPSTRANSPORT.TransportZoneCombo TransportZoneCombo Transport zone combo.
-- @return Core.Zone#ZONE Zone where the troops are deployed.
function OPSTRANSPORT:GetDeployZone(TransportZoneCombo)

  -- Use default TZC if no transport zone combo is provided.
  TransportZoneCombo=TransportZoneCombo or self.tzcDefault

  return TransportZoneCombo.DeployZone
end

--- Set embark zone.
-- @param #OPSTRANSPORT self
-- @param Core.Zone#ZONE EmbarkZone Zone where the troops are embarked.
-- @param #OPSTRANSPORT.TransportZoneCombo TransportZoneCombo Transport zone combo.
-- @return #OPSTRANSPORT self
function OPSTRANSPORT:SetEmbarkZone(EmbarkZone, TransportZoneCombo)

  -- Use default TZC if no transport zone combo is provided.
  TransportZoneCombo=TransportZoneCombo or self.tzcDefault

  TransportZoneCombo.EmbarkZone=EmbarkZone or TransportZoneCombo.PickupZone
  
  return self
end

--- Get embark zone.
-- @param #OPSTRANSPORT self
-- @param #OPSTRANSPORT.TransportZoneCombo TransportZoneCombo Transport zone combo.
-- @return Core.Zone#ZONE Zone where the troops are embarked from.
function OPSTRANSPORT:GetEmbarkZone(TransportZoneCombo)

  -- Use default TZC if no transport zone combo is provided.
  TransportZoneCombo=TransportZoneCombo or self.tzcDefault

  return TransportZoneCombo.EmbarkZone
end

--- Set disembark zone.
-- @param #OPSTRANSPORT self
-- @param Core.Zone#ZONE DisembarkZone Zone where the troops are disembarked.
-- @param #OPSTRANSPORT.TransportZoneCombo TransportZoneCombo Transport zone combo.
-- @return #OPSTRANSPORT self
function OPSTRANSPORT:SetDisembarkZone(DisembarkZone, TransportZoneCombo)

  -- Use default TZC if no transport zone combo is provided.
  TransportZoneCombo=TransportZoneCombo or self.tzcDefault

  TransportZoneCombo.DisembarkZone=DisembarkZone
  
  return self
end

--- Get disembark zone.
-- @param #OPSTRANSPORT self
-- @param #OPSTRANSPORT.TransportZoneCombo TransportZoneCombo Transport zone combo.
-- @return Core.Zone#ZONE Zone where the troops are disembarked to.
function OPSTRANSPORT:GetDisembarkZone(TransportZoneCombo)

  -- Use default TZC if no transport zone combo is provided.
  TransportZoneCombo=TransportZoneCombo or self.tzcDefault

  return TransportZoneCombo.DisembarkZone
end

--- Set activation status of group when disembarked from transport carrier.
-- @param #OPSTRANSPORT self
-- @param #boolean Active If `true` or `nil`, group is activated when disembarked. If `false`, group is late activated and needs to be activated manually.
-- @param #OPSTRANSPORT.TransportZoneCombo TransportZoneCombo Transport zone combo.
-- @return #OPSTRANSPORT self
function OPSTRANSPORT:SetDisembarkActivation(Active, TransportZoneCombo)

  -- Use default TZC if no transport zone combo is provided.
  TransportZoneCombo=TransportZoneCombo or self.tzcDefault

  if Active==true or Active==nil then
    TransportZoneCombo.disembarkActivation=true
  else
    TransportZoneCombo.disembarkActivation=false
  end
  
  return self
end

--- Get disembark activation.
-- @param #OPSTRANSPORT self
-- @param #OPSTRANSPORT.TransportZoneCombo TransportZoneCombo Transport zone combo.
-- @return #boolean If `true`, groups are spawned in late activated state.
function OPSTRANSPORT:GetDisembarkActivation(TransportZoneCombo)

  -- Use default TZC if no transport zone combo is provided.
  TransportZoneCombo=TransportZoneCombo or self.tzcDefault

  return TransportZoneCombo.disembarkActivation
end

--- Set/add transfer carrier(s). These are carrier groups, where the cargo is directly loaded into when disembarked.
-- @param #OPSTRANSPORT self
-- @param Core.Set#SET_GROUP Carriers Carrier set. Can also be passed as a #GROUP, #OPSGROUP or #SET_OPSGROUP object.
-- @param #OPSTRANSPORT.TransportZoneCombo TransportZoneCombo Transport zone combo.
-- @return #OPSTRANSPORT self
function OPSTRANSPORT:SetDisembarkCarriers(Carriers, TransportZoneCombo)

  -- Debug info.
  self:T(self.lid.."Setting transfer carriers!")
  
  -- Use default TZC if no transport zone combo is provided.
  TransportZoneCombo=TransportZoneCombo or self.tzcDefault
  
  -- Set that we want to disembark to carriers.
  TransportZoneCombo.disembarkToCarriers=true
  
  self:_AddDisembarkCarriers(Carriers, TransportZoneCombo.DisembarkCarriers)

  return self
end

--- Set/add transfer carrier(s). These are carrier groups, where the cargo is directly loaded into when disembarked.
-- @param #OPSTRANSPORT self
-- @param Core.Set#SET_GROUP Carriers Carrier set. Can also be passed as a #GROUP, #OPSGROUP or #SET_OPSGROUP object.
-- @param #table Table the table to add.
-- @return #OPSTRANSPORT self
function OPSTRANSPORT:_AddDisembarkCarriers(Carriers, Table)

  if Carriers:IsInstanceOf("GROUP") or Carriers:IsInstanceOf("OPSGROUP") then
  
    local carrier=self:_GetOpsGroupFromObject(Carriers)
    if  carrier then
      table.insert(Table, carrier)
    end
      
  elseif Carriers:IsInstanceOf("SET_GROUP") or Carriers:IsInstanceOf("SET_OPSGROUP") then
  
    for _,object in pairs(Carriers:GetSet()) do
      local carrier=self:_GetOpsGroupFromObject(object)
      if carrier then
        table.insert(Table, carrier)
      end
    end
    
  else  
    self:E(self.lid.."ERROR: Carriers must be a GROUP, OPSGROUP, SET_GROUP or SET_OPSGROUP object!")    
  end


end

--- Get transfer carrier(s). These are carrier groups, where the cargo is directly loaded into when disembarked.
-- @param #OPSTRANSPORT self
-- @param #OPSTRANSPORT.TransportZoneCombo TransportZoneCombo Transport zone combo.
-- @return #table Table of carrier OPS groups.
function OPSTRANSPORT:GetDisembarkCarriers(TransportZoneCombo)

  -- Use default TZC if no transport zone combo is provided.
  TransportZoneCombo=TransportZoneCombo or self.tzcDefault
  
  return TransportZoneCombo.DisembarkCarriers
end


--- Set if group remains *in utero* after disembarkment from carrier. Can be used to directly load the group into another carrier. Similar to disembark in late activated state.
-- @param #OPSTRANSPORT self
-- @param #boolean InUtero If `true` or `nil`, group remains *in utero* after disembarkment.
-- @param #OPSTRANSPORT.TransportZoneCombo TransportZoneCombo Transport zone combo.
-- @return #OPSTRANSPORT self
function OPSTRANSPORT:SetDisembarkInUtero(InUtero, TransportZoneCombo)

  -- Use default TZC if no transport zone combo is provided.
  TransportZoneCombo=TransportZoneCombo or self.tzcDefault  

  if InUtero==true or InUtero==nil then
    TransportZoneCombo.disembarkInUtero=true
  else
    TransportZoneCombo.disembarkInUtero=false
  end
  
  return self
end

--- Get disembark in utero.
-- @param #OPSTRANSPORT self
-- @param #OPSTRANSPORT.TransportZoneCombo TransportZoneCombo Transport zone combo.
-- @return #boolean If `true`, groups stay in utero after disembarkment.
function OPSTRANSPORT:GetDisembarkInUtero(TransportZoneCombo)

  -- Use default TZC if no transport zone combo is provided.
  TransportZoneCombo=TransportZoneCombo or self.tzcDefault

  return TransportZoneCombo.disembarkInUtero
end

--- Set pickup formation.
-- @param #OPSTRANSPORT self
-- @param #number Formation Pickup formation.
-- @param #OPSTRANSPORT.TransportZoneCombo TransportZoneCombo Transport zone combo.
-- @return #OPSTRANSPORT self
function OPSTRANSPORT:SetFormationPickup(Formation, TransportZoneCombo)

  -- Use default TZC if no transport zone combo is provided.
  TransportZoneCombo=TransportZoneCombo or self.tzcDefault  

  TransportZoneCombo.PickupFormation=Formation
  
  return self
end

--- Get pickup formation.
-- @param #OPSTRANSPORT self
-- @param Ops.OpsGroup#OPSGROUP OpsGroup
-- @return #string Formation.
function OPSTRANSPORT:_GetFormationDefault(OpsGroup)

  if OpsGroup.isArmygroup then
  
    return self.formationArmy
    
  elseif OpsGroup.isFlightgroup then
  
    if OpsGroup.isHelo then
      return self.formationHelo
    else
      return self.formationPlane
    end
  
  else
    return ENUMS.Formation.Vehicle.OffRoad
  end
  
  return nil
end

--- Get pickup formation.
-- @param #OPSTRANSPORT self
-- @param #OPSTRANSPORT.TransportZoneCombo TransportZoneCombo Transport zone combo.
-- @param Ops.OpsGroup#OPSGROUP OpsGroup
-- @return #number Formation.
function OPSTRANSPORT:_GetFormationPickup(TransportZoneCombo, OpsGroup)

  -- Use default TZC if no transport zone combo is provided.
  TransportZoneCombo=TransportZoneCombo or self.tzcDefault
  
  local formation=TransportZoneCombo.PickupFormation or self:_GetFormationDefault(OpsGroup)

  return formation
end

--- Set transport formation.
-- @param #OPSTRANSPORT self
-- @param #number Formation Pickup formation.
-- @param #OPSTRANSPORT.TransportZoneCombo TransportZoneCombo Transport zone combo.
-- @return #OPSTRANSPORT self
function OPSTRANSPORT:SetFormationTransport(Formation, TransportZoneCombo)

  -- Use default TZC if no transport zone combo is provided.
  TransportZoneCombo=TransportZoneCombo or self.tzcDefault  

  TransportZoneCombo.TransportFormation=Formation
  
  return self
end

--- Get transport formation.
-- @param #OPSTRANSPORT self
-- @param #OPSTRANSPORT.TransportZoneCombo TransportZoneCombo Transport zone combo.
-- @param Ops.OpsGroup#OPSGROUP OpsGroup
-- @return #number Formation.
function OPSTRANSPORT:_GetFormationTransport(TransportZoneCombo, OpsGroup)

  -- Use default TZC if no transport zone combo is provided.
  TransportZoneCombo=TransportZoneCombo or self.tzcDefault
  
  local formation=TransportZoneCombo.TransportFormation or self:_GetFormationDefault(OpsGroup)

  return formation
end



--- Set required cargo. This is a list of cargo groups that need to be loaded before the **first** transport will start.
-- @param #OPSTRANSPORT self
-- @param Core.Set#SET_GROUP Cargos Required cargo set. Can also be passed as a #GROUP, #OPSGROUP or #SET_OPSGROUP object.
-- @param #OPSTRANSPORT.TransportZoneCombo TransportZoneCombo Transport zone combo.
-- @return #OPSTRANSPORT self
function OPSTRANSPORT:SetRequiredCargos(Cargos, TransportZoneCombo)

  -- Debug info.
  self:T(self.lid.."Setting required cargos!")
  
  -- Use default TZC if no transport zone combo is provided.
  TransportZoneCombo=TransportZoneCombo or self.tzcDefault  

  -- Create table.
  TransportZoneCombo.RequiredCargos=TransportZoneCombo.RequiredCargos or {}

  if Cargos:IsInstanceOf("GROUP") or Cargos:IsInstanceOf("OPSGROUP") then
  
    local cargo=self:_GetOpsGroupFromObject(Cargos)
    if cargo then
      table.insert(TransportZoneCombo.RequiredCargos, cargo)
    end
      
  elseif Cargos:IsInstanceOf("SET_GROUP") or Cargos:IsInstanceOf("SET_OPSGROUP") then
  
    for _,object in pairs(Cargos:GetSet()) do
      local cargo=self:_GetOpsGroupFromObject(object)
      if cargo then
        table.insert(TransportZoneCombo.RequiredCargos, cargo)
      end
    end
    
  else  
    self:E(self.lid.."ERROR: Required Cargos must be a GROUP, OPSGROUP, SET_GROUP or SET_OPSGROUP object!")    
  end

  return self
end

--- Get required cargos. This is a list of cargo groups that need to be loaded before the **first** transport will start.
-- @param #OPSTRANSPORT self
-- @param #OPSTRANSPORT.TransportZoneCombo TransportZoneCombo Transport zone combo.
-- @return #table Table of required cargo ops groups.
function OPSTRANSPORT:GetRequiredCargos(TransportZoneCombo)

  -- Use default TZC if no transport zone combo is provided.
  TransportZoneCombo=TransportZoneCombo or self.tzcDefault  
  
  return TransportZoneCombo.RequiredCargos
end

--- Set number of required carrier groups for an OPSTRANSPORT assignment. Only used if transport is assigned at **LEGION** or higher level.
-- @param #OPSTRANSPORT self
-- @param #number NcarriersMin Number of carriers *at least* required. Default 1.
-- @param #number NcarriersMax Number of carriers *at most* used for transportation. Default is same as `NcarriersMin`.
-- @return #OPSTRANSPORT self
function OPSTRANSPORT:SetRequiredCarriers(NcarriersMin, NcarriersMax)

  self.nCarriersMin=NcarriersMin or 1
  
  self.nCarriersMax=NcarriersMax or self.nCarriersMin

  -- Ensure that max is at least equal to min.
  if self.nCarriersMax<self.nCarriersMin then
    self.nCarriersMax=self.nCarriersMin
  end

  return self
end

--- Get the number of required carrier groups for an OPSTRANSPORT assignment. Only used if transport is assigned at **LEGION** or higher level.
-- @param #OPSTRANSPORT self
-- @return #number Number of carriers *at least* required.
-- @return #number Number of carriers *at most* used for transportation.
function OPSTRANSPORT:GetRequiredCarriers()
  return self.nCarriersMin, self.nCarriersMax
end


--- Add a carrier assigned for this transport.
-- @param #OPSTRANSPORT self
-- @param Ops.OpsGroup#OPSGROUP CarrierGroup Carrier OPSGROUP.
-- @return #OPSTRANSPORT self
function OPSTRANSPORT:_AddCarrier(CarrierGroup)

  -- Check that this is not already an assigned carrier.
  if not self:IsCarrier(CarrierGroup) then
  
    -- Increase carrier count.
    self.Ncarrier=self.Ncarrier+1

    -- Set transport status to SCHEDULED.
    self:SetCarrierTransportStatus(CarrierGroup, OPSTRANSPORT.Status.SCHEDULED)
    
    -- Call scheduled event.
    self:Scheduled()
    
    -- Add carrier to table.
    table.insert(self.carriers, CarrierGroup)
    
  end 
  
  return self
end

--- Remove group from the current carrier list/table.
-- @param #OPSTRANSPORT self
-- @param Ops.OpsGroup#OPSGROUP CarrierGroup Carrier OPSGROUP.
-- @param #number Delay Delay in seconds before the carrier is removed.
-- @return #OPSTRANSPORT self
function OPSTRANSPORT:_DelCarrier(CarrierGroup, Delay)

  if Delay and Delay>0 then
    self:ScheduleOnce(Delay, OPSTRANSPORT._DelCarrier, self, CarrierGroup)
  else
    if self:IsCarrier(CarrierGroup) then
   
      for i=#self.carriers,1,-1 do
        local carrier=self.carriers[i] --Ops.OpsGroup#OPSGROUP
        if carrier.groupname==CarrierGroup.groupname then
          self:T(self.lid..string.format("Removing carrier %s", CarrierGroup.groupname))
          table.remove(self.carriers, i)
        end
      end
          
    end
  end 
  
  return self
end

--- Get a list of alive carriers.
-- @param #OPSTRANSPORT self
-- @return #table Names of all carriers
function OPSTRANSPORT:_GetCarrierNames()

  local names={}
  for _,_carrier in pairs(self.carriers) do
    local carrier=_carrier --Ops.OpsGroup#OPSGROUP
    if carrier:IsAlive()~=nil then
      table.insert(names, carrier.groupname)
    end
  end
  
  return names
end

--- Get (all) cargo @{Ops.OpsGroup#OPSGROUP}s. Optionally, only delivered or undelivered groups can be returned.
-- @param #OPSTRANSPORT self
-- @param #boolean Delivered If `true`, only delivered groups are returned. If `false` only undelivered groups are returned. If `nil`, all groups are returned.
-- @param Ops.OpsGroup#OPSGROUP Carrier (Optional) Only count cargo groups that fit into the given carrier group. Current cargo is not a factor.
-- @param #OPSTRANSPORT.TransportZoneCombo TransportZoneCombo Transport zone combo.
-- @return #table Cargo Ops groups. Can be and empty table `{}`.
function OPSTRANSPORT:GetCargoOpsGroups(Delivered, Carrier, TransportZoneCombo)

  local cargos=self:GetCargos(TransportZoneCombo, Carrier, Delivered)

  local opsgroups={}
  for _,_cargo in pairs(cargos) do
    local cargo=_cargo --Ops.OpsGroup#OPSGROUP.CargoGroup
    if cargo.type=="OPSGROUP" then
      if cargo.opsgroup and not (cargo.opsgroup:IsDead() or cargo.opsgroup:IsStopped()) then
        table.insert(opsgroups, cargo.opsgroup)
      end
    end
  end
    
  return opsgroups
end

--- Get (all) cargo @{Ops.OpsGroup#OPSGROUP}s. Optionally, only delivered or undelivered groups can be returned.
-- @param #OPSTRANSPORT self
-- @param #boolean Delivered If `true`, only delivered groups are returned. If `false` only undelivered groups are returned. If `nil`, all groups are returned.
-- @param Ops.OpsGroup#OPSGROUP Carrier (Optional) Only count cargo groups that fit into the given carrier group. Current cargo is not a factor.
-- @param #OPSTRANSPORT.TransportZoneCombo TransportZoneCombo Transport zone combo.
-- @return #table Cargo Ops groups. Can be and empty table `{}`.
function OPSTRANSPORT:GetCargoStorages(Delivered, Carrier, TransportZoneCombo)

  local cargos=self:GetCargos(TransportZoneCombo, Carrier, Delivered)

  local opsgroups={}
  for _,_cargo in pairs(cargos) do
    local cargo=_cargo --Ops.OpsGroup#OPSGROUP.CargoGroup
    if cargo.type=="STORAGE" then
      table.insert(opsgroups, cargo.storage)
    end
  end
    
  return opsgroups
end

--- Get carriers.
-- @param #OPSTRANSPORT self
-- @return #table Carrier Ops groups.
function OPSTRANSPORT:GetCarriers()
  return self.carriers
end

--- Get cargos.
-- @param #OPSTRANSPORT self
-- @param #OPSTRANSPORT.TransportZoneCombo TransportZoneCombo Transport zone combo.
-- @param Ops.OpsGroup#OPSGROUP Carrier Specific carrier.
-- @param #boolean Delivered Delivered status.
-- @return #table Cargos.
function OPSTRANSPORT:GetCargos(TransportZoneCombo, Carrier, Delivered)
  
  local tczs=self.tzCombos
  if TransportZoneCombo then
    tczs={TransportZoneCombo}
  end

  local cargos={}
  for _,_tcz in pairs(tczs) do
    local tcz=_tcz --#OPSTRANSPORT.TransportZoneCombo
    for _,_cargo in pairs(tcz.Cargos) do
      local cargo=_cargo --Ops.OpsGroup#OPSGROUP.CargoGroup
      if Delivered==nil or cargo.delivered==Delivered  then
        if Carrier==nil or Carrier:CanCargo(cargo) then
          table.insert(cargos, cargo)
        end
      end
    end
  end

  return cargos
end

--- Get total weight.
-- @param #OPSTRANSPORT self
-- @param Ops.OpsGroup#OPSGROUP.CargoGroup Cargo Cargo data.
-- @param #boolean IncludeReserved Include reserved cargo.
-- @return #number Weight in kg.
function OPSTRANSPORT:GetCargoTotalWeight(Cargo, IncludeReserved)

  local weight=0

  if Cargo.type==OPSTRANSPORT.CargoType.OPSGROUP then
    weight=Cargo.opsgroup:GetWeightTotal(nil, IncludeReserved)
  else
    if type(Cargo.storage.cargoType)=="number" then
      if IncludeReserved then
        return Cargo.storage.cargoAmount+Cargo.storage.cargoReserved
      else
        return Cargo.storage.cargoAmount
      end
    else
      if IncludeReserved then
        return Cargo.storage.cargoAmount*100 -- Assume 100 kg per item
      else
        return (Cargo.storage.cargoAmount+Cargo.storage.cargoReserved)*100 -- Assume 100 kg per item
      end
    end
  end

  return weight
end

--- Set transport start and stop time.
-- @param #OPSTRANSPORT self
-- @param #string ClockStart Time the transport is started, e.g. "05:00" for 5 am. If specified as a #number, it will be relative (in seconds) to the current mission time. Default is 5 seconds after mission was added.
-- @param #string ClockStop (Optional) Time the transport is stopped, e.g. "13:00" for 1 pm. If mission could not be started at that time, it will be removed from the queue. If specified as a #number it will be relative (in seconds) to the current mission time.
-- @return #OPSTRANSPORT self
function OPSTRANSPORT:SetTime(ClockStart, ClockStop)

  -- Current mission time.
  local Tnow=timer.getAbsTime()
  
  -- Set start time. Default in 5 sec.
  local Tstart=Tnow+5
  if ClockStart and type(ClockStart)=="number" then
    Tstart=Tnow+ClockStart
  elseif ClockStart and type(ClockStart)=="string" then
    Tstart=UTILS.ClockToSeconds(ClockStart)
  end

  -- Set stop time. Default nil.
  local Tstop=nil
  if ClockStop and type(ClockStop)=="number" then
    Tstop=Tnow+ClockStop
  elseif ClockStop and type(ClockStop)=="string" then
    Tstop=UTILS.ClockToSeconds(ClockStop)
  end
  
  self.Tstart=Tstart
  self.Tstop=Tstop

  if Tstop then
    self.duration=self.Tstop-self.Tstart
  end  

  return self
end

--- Set mission priority and (optional) urgency. Urgent missions can cancel other running missions. 
-- @param #OPSTRANSPORT self
-- @param #number Prio Priority 1=high, 100=low. Default 50.
-- @param #number Importance Number 1-10. If missions with lower value are in the queue, these have to be finished first. Default is `nil`.
-- @param #boolean Urgent If *true*, another running mission might be cancelled if it has a lower priority.
-- @return #OPSTRANSPORT self
function OPSTRANSPORT:SetPriority(Prio, Importance, Urgent)
  self.prio=Prio or 50
  self.urgent=Urgent
  self.importance=Importance
  return self
end

--- Set verbosity. 
-- @param #OPSTRANSPORT self
-- @param #number Verbosity Be more verbose. Default 0
-- @return #OPSTRANSPORT self
function OPSTRANSPORT:SetVerbosity(Verbosity)
  self.verbose=Verbosity or 0
  return self
end

--- Add start condition.
-- @param #OPSTRANSPORT self
-- @param #function ConditionFunction Function that needs to be true before the transport can be started. Must return a #boolean.
-- @param ... Condition function arguments if any.
-- @return #OPSTRANSPORT self
function OPSTRANSPORT:AddConditionStart(ConditionFunction, ...)

  if ConditionFunction then
  
    local condition={} --#OPSTRANSPORT.Condition
    
    condition.func=ConditionFunction
    condition.arg={}
    if arg then
      condition.arg=arg
    end
    
    table.insert(self.conditionStart, condition)
    
  end
  
  return self
end

--- Add path used for transportation from the pickup to the deploy zone.
-- If multiple paths are defined, a random one is chosen. The path is retrieved from the waypoints of a given group.
-- **NOTE** that the category group defines for which carriers this path is valid.
-- For example, if you specify a GROUND group to provide the waypoints, only assigned GROUND carriers will use the
-- path. 
-- @param #OPSTRANSPORT self
-- @param Wrapper.Group#GROUP PathGroup A (late activated) GROUP defining a transport path by their waypoints.
-- @param #number Radius Randomization radius in meters. Default 0 m.
-- @param #OPSTRANSPORT.TransportZoneCombo TransportZoneCombo Transport Zone combo.
-- @return #OPSTRANSPORT self
function OPSTRANSPORT:AddPathTransport(PathGroup, Reversed, Radius, TransportZoneCombo)

  -- Use default TZC if no transport zone combo is provided.
  TransportZoneCombo=TransportZoneCombo or self.tzcDefault  

  if type(PathGroup)=="string" then
    PathGroup=GROUP:FindByName(PathGroup)
  end

  local path={} --#OPSTRANSPORT.Path
  path.category=PathGroup:GetCategory()
  path.radius=Radius or 0
  path.waypoints=PathGroup:GetTaskRoute()
  
  -- TODO: Check that only flyover waypoints are given for aircraft.

  -- Add path.
  table.insert(TransportZoneCombo.TransportPaths, path)

  return self
end

--- Get a path for transportation.
-- @param #OPSTRANSPORT self
-- @param #number Category Group category.
-- @param #OPSTRANSPORT.TransportZoneCombo TransportZoneCombo Transport Zone combo.
-- @return #OPSTRANSPORT.Path The path object.
function OPSTRANSPORT:_GetPathTransport(Category, TransportZoneCombo)

  -- Use default TZC if no transport zone combo is provided.
  TransportZoneCombo=TransportZoneCombo or self.tzcDefault
  
  local pathsTransport=TransportZoneCombo.TransportPaths

  if pathsTransport and #pathsTransport>0 then
  
    local paths={}
    
    for _,_path in pairs(pathsTransport) do
      local path=_path --#OPSTRANSPORT.Path
      if path.category==Category then
        table.insert(paths, path)
      end
    end
    
    if #paths>0 then
    
      local path=paths[math.random(#paths)] --#OPSTRANSPORT.Path
      
      return path
    end
  end

  return nil
end

--- Add a carrier assigned for this transport.
-- @param #OPSTRANSPORT self
-- @param Ops.OpsGroup#OPSGROUP CarrierGroup Carrier OPSGROUP.
-- @param #string Status Carrier Status.
-- @return #OPSTRANSPORT self
function OPSTRANSPORT:SetCarrierTransportStatus(CarrierGroup, Status)

  -- Old status
  local oldstatus=self:GetCarrierTransportStatus(CarrierGroup)
  
  -- Debug info.
  self:T(self.lid..string.format("New carrier transport status for %s: %s --> %s", CarrierGroup:GetName(), oldstatus, Status))

  -- Set new status.
  self.carrierTransportStatus[CarrierGroup.groupname]=Status
    
  return self
end

--- Get carrier transport status.
-- @param #OPSTRANSPORT self
-- @param Ops.OpsGroup#OPSGROUP CarrierGroup Carrier OPSGROUP.
-- @return #string Carrier status.
function OPSTRANSPORT:GetCarrierTransportStatus(CarrierGroup)
  local status=self.carrierTransportStatus[CarrierGroup.groupname] or "unknown"
  return status
end

--- Get unique ID of the transport assignment.
-- @param #OPSTRANSPORT self
-- @return #number UID.
function OPSTRANSPORT:GetUID()
  return self.uid
end

--- Get number of delivered cargo groups.
-- @param #OPSTRANSPORT self
-- @return #number Total number of delivered cargo groups.
function OPSTRANSPORT:GetNcargoDelivered()
  return self.Ndelivered
end

--- Get number of cargo groups.
-- @param #OPSTRANSPORT self
-- @return #number Total number of cargo groups.
function OPSTRANSPORT:GetNcargoTotal()
  return self.Ncargo
end

--- Get number of carrier groups assigned for this transport.
-- @param #OPSTRANSPORT self
-- @return #number Total number of carrier groups.
function OPSTRANSPORT:GetNcarrier()
  return self.Ncarrier
end

--- Add carrier asset to transport.
-- @param #OPSTRANSPORT self
-- @param Functional.Warehouse#WAREHOUSE.Assetitem Asset The asset to be added.
-- @param #OPSTRANSPORT.TransportZoneCombo TransportZoneCombo Transport zone combo.
-- @return #OPSTRANSPORT self
function OPSTRANSPORT:AddAsset(Asset, TransportZoneCombo)

  -- Debug info
  self:T(self.lid..string.format("Adding asset carrier \"%s\" to transport", tostring(Asset.spawngroupname)))

  -- Add asset to table.
  self.assets=self.assets or {}
    
  table.insert(self.assets, Asset)

  return self
end

--- Delete carrier asset from transport.
-- @param #OPSTRANSPORT self
-- @param Functional.Warehouse#WAREHOUSE.Assetitem Asset The asset to be removed.
-- @return #OPSTRANSPORT self
function OPSTRANSPORT:DelAsset(Asset)

  for i,_asset in pairs(self.assets or {}) do
    local asset=_asset --Functional.Warehouse#WAREHOUSE.Assetitem
    
    if asset.uid==Asset.uid then
      self:T(self.lid..string.format("Removing asset \"%s\" from transport", tostring(Asset.spawngroupname)))
      table.remove(self.assets, i)
      return self
    end
    
  end

  return self
end

--- Add cargo asset.
-- @param #OPSTRANSPORT self
-- @param Functional.Warehouse#WAREHOUSE.Assetitem Asset The asset to be added.
-- @param #OPSTRANSPORT.TransportZoneCombo TransportZoneCombo Transport zone combo.
-- @return #OPSTRANSPORT self
function OPSTRANSPORT:AddAssetCargo(Asset, TransportZoneCombo)

  -- Debug info
  self:T(self.lid..string.format("Adding asset cargo \"%s\" to transport and TZC=%s", tostring(Asset.spawngroupname), TransportZoneCombo and TransportZoneCombo.uid or "N/A"))

  -- Add asset to table.
  self.assetsCargo=self.assetsCargo or {}
    
  table.insert(self.assetsCargo, Asset)
  
  TransportZoneCombo.assetsCargo=TransportZoneCombo.assetsCargo or {}
  
  TransportZoneCombo.assetsCargo[Asset.spawngroupname]=Asset
  
  return self
end

--- Get transport zone combo of cargo group.
-- @param #OPSTRANSPORT self
-- @param #string GroupName Group name of cargo.
-- @return #OPSTRANSPORT.TransportZoneCombo TransportZoneCombo Transport zone combo.
function OPSTRANSPORT:GetTZCofCargo(GroupName)

  for _,_tzc in pairs(self.tzCombos) do
    local tzc=_tzc --#OPSTRANSPORT.TransportZoneCombo
    for _,_cargo in pairs(tzc.Cargos) do
      local cargo=_cargo --Ops.OpsGroup#OPSGROUP.CargoGroup
      if cargo.opsgroup:GetName()==GroupName then
        return tzc
      end
    end
  end

  return nil
end

--- Add LEGION to the transport.
-- @param #OPSTRANSPORT self
-- @param Ops.Legion#LEGION Legion The legion.
-- @return #OPSTRANSPORT self
function OPSTRANSPORT:AddLegion(Legion)

  -- Debug info.
  self:T(self.lid..string.format("Adding legion %s", Legion.alias))

  -- Add legion to table.
  table.insert(self.legions, Legion)
  
  return self
end

--- Remove LEGION from transport.
-- @param #OPSTRANSPORT self
-- @param Ops.Legion#LEGION Legion The legion.
-- @return #OPSTRANSPORT self
function OPSTRANSPORT:RemoveLegion(Legion)

  -- Loop over legions
  for i=#self.legions,1,-1 do
    local legion=self.legions[i] --Ops.Legion#LEGION
    if legion.alias==Legion.alias then
      -- Debug info.
      self:T(self.lid..string.format("Removing legion %s", Legion.alias))    
      table.remove(self.legions, i)
      return self
    end
  end
  
  self:E(self.lid..string.format("ERROR: Legion %s not found and could not be removed!", Legion.alias))
  return self
end

--- Check if an OPS group is assigned as carrier for this transport.
-- @param #OPSTRANSPORT self
-- @param Ops.OpsGroup#OPSGROUP CarrierGroup Potential carrier OPSGROUP.
-- @return #boolean If true, group is an assigned carrier. 
function OPSTRANSPORT:IsCarrier(CarrierGroup)

  if CarrierGroup then
    for _,_carrier in pairs(self.carriers) do
      local carrier=_carrier --Ops.OpsGroup#OPSGROUP
      if carrier.groupname==CarrierGroup.groupname then
        return true
      end
    end
  end

  return false
end

--- Check if transport is ready to be started.
-- * Start time passed.
-- * Stop time did not pass already.
-- * All start conditions are true.
-- @param #OPSTRANSPORT self
-- @return #boolean If true, mission can be started.
function OPSTRANSPORT:IsReadyToGo()

  -- Debug text.
  local text=self.lid.."Is ReadyToGo? "
  
  -- Current abs time.
  local Tnow=timer.getAbsTime()
  
  -- Pickup AND deploy zones must be set.
  local gotzones=false
  for _,_tz in pairs(self.tzCombos) do
    local tz=_tz --#OPSTRANSPORT.TransportZoneCombo
    if tz.PickupZone and tz.DeployZone then
      gotzones=true
      break
    end
  end
  if not gotzones then
    text=text.."No, pickup/deploy zone combo not yet defined!"
    return false
  end
  
  -- Start time did not pass yet.
  if self.Tstart and Tnow<self.Tstart then
    text=text.."No, start time not passed!"
    return false
  end
  
  -- Stop time already passed.
  if self.Tstop and Tnow>self.Tstop then
    text=text.."Nope, stop time already passed!"
    self:T(text)
    return false
  end
  
  -- All start conditions true?
  local startme=self:EvalConditionsAll(self.conditionStart)
  
  -- Nope, not yet.
  if not startme then
    text=text..("No way, at least one start condition is not true!")
    self:T(text)
    return false
  end
  
  -- We're good to go!
  text=text.."Yes!"
  self:T(text)
  return true
end

--- Set LEGION transport status.
-- @param #OPSTRANSPORT self
-- @param Ops.Legion#LEGION Legion The legion.
-- @param #string Status New status.
-- @return #OPSTRANSPORT self
function OPSTRANSPORT:SetLegionStatus(Legion, Status)

  -- Old status
  local status=self:GetLegionStatus(Legion)

  -- Debug info.
  self:T(self.lid..string.format("Setting LEGION %s to status %s-->%s", Legion.alias, tostring(status), tostring(Status)))

  -- New status.
  self.statusLegion[Legion.alias]=Status

  return self
end

--- Get LEGION transport status.
-- @param #OPSTRANSPORT self
-- @param Ops.Legion#LEGION Legion The legion.
-- @return #string status Current status.
function OPSTRANSPORT:GetLegionStatus(Legion)

  -- Current status.
  local status=self.statusLegion[Legion.alias] or "unknown"

  return status
end

--- Check if state is PLANNED.
-- @param #OPSTRANSPORT self
-- @return #boolean If true, status is PLANNED. 
function OPSTRANSPORT:IsPlanned()
  local is=self:is(OPSTRANSPORT.Status.PLANNED)
  return is
end

--- Check if state is QUEUED.
-- @param #OPSTRANSPORT self
-- @param Ops.Legion#LEGION Legion (Optional) Check if transport is queued at this legion.
-- @return #boolean If true, status is QUEUED. 
function OPSTRANSPORT:IsQueued(Legion)
  local is=self:is(OPSTRANSPORT.Status.QUEUED)
  if Legion then
    is=self:GetLegionStatus(Legion)==OPSTRANSPORT.Status.QUEUED
  end  
  return is
end

--- Check if state is REQUESTED.
-- @param #OPSTRANSPORT self
-- @param Ops.Legion#LEGION Legion (Optional) Check if transport is queued at this legion.
-- @return #boolean If true, status is REQUESTED. 
function OPSTRANSPORT:IsRequested(Legion)
  local is=self:is(OPSTRANSPORT.Status.REQUESTED)
  if Legion then
    is=self:GetLegionStatus(Legion)==OPSTRANSPORT.Status.REQUESTED
  end  
  return is
end

--- Check if state is SCHEDULED.
-- @param #OPSTRANSPORT self
-- @return #boolean If true, status is SCHEDULED. 
function OPSTRANSPORT:IsScheduled()
  local is=self:is(OPSTRANSPORT.Status.SCHEDULED)
  return is
end

--- Check if state is EXECUTING.
-- @param #OPSTRANSPORT self
-- @return #boolean If true, status is EXECUTING. 
function OPSTRANSPORT:IsExecuting()
  local is=self:is(OPSTRANSPORT.Status.EXECUTING)
  return is
end

--- Check if all cargo was delivered (or is dead).
-- @param #OPSTRANSPORT self
-- @param #number Nmin Number of groups that must be actually delivered (and are not dead). Default 0.
-- @return #boolean If true, all possible cargo was delivered. 
function OPSTRANSPORT:IsDelivered(Nmin)
  local is=self:is(OPSTRANSPORT.Status.DELIVERED)
  
--  Nmin=Nmin or 0
--  if Nmin>self.Ncargo then
--    Nmin=self.Ncargo
--  end
--  
--  if self.Ndelivered<Nmin then
--    is=false
--  end

  -- Check if Ndelivered is at least Nmin (if given)
  if is==false and Nmin and self.Ndelivered>=math.min(self.Ncargo, Nmin) then
    is=true
  end
  
  return is
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Status Update
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after "StatusUpdate" event.
-- @param #OPSTRANSPORT self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPSTRANSPORT:onafterStatusUpdate(From, Event, To)

  -- Current FSM state.
  local fsmstate=self:GetState()
  
  if self.verbose>=1 then
  
    -- Info text.    
    local text=string.format("%s: Ncargo=%d/%d, Ncarrier=%d/%d, Nlegions=%d", fsmstate:upper(), self.Ncargo, self.Ndelivered, #self.carriers, self.Ncarrier, #self.legions)

    -- Info about cargo and carrier.    
    if self.verbose>=2 then
    
      for i,_tz in pairs(self.tzCombos) do
        local tz=_tz --#OPSTRANSPORT.TransportZoneCombo
        local pickupzone=tz.PickupZone and tz.PickupZone:GetName() or "Unknown"
        local deployzone=tz.DeployZone and tz.DeployZone:GetName() or "Unknown"
        text=text..string.format("\n[%d] %s --> %s: Ncarriers=%d, Ncargo=%d (%d)", i, pickupzone, deployzone, tz.Ncarriers, #tz.Cargos, tz.Ncargo)
      end
    
    end

    -- Info about cargo and carrier.    
    if self.verbose>=3 then
    
      text=text..string.format("\nCargos:")
      for _,_cargo in pairs(self:GetCargos()) do
        local cargo=_cargo  --Ops.OpsGroup#OPSGROUP.CargoGroup
        if cargo.type==OPSTRANSPORT.CargoType.OPSGROUP then
          local carrier=cargo.opsgroup:_GetMyCarrierElement()
          local name=carrier and carrier.name or "none"
          local cstate=carrier and carrier.status or "N/A"
          text=text..string.format("\n- %s: %s [%s], weight=%d kg, carrier=%s [%s], delivered=%s [UID=%s]", 
          cargo.opsgroup:GetName(), cargo.opsgroup.cargoStatus:upper(), cargo.opsgroup:GetState(), cargo.opsgroup:GetWeightTotal(), name, cstate, tostring(cargo.delivered), tostring(cargo.opsgroup.cargoTransportUID))
        else
          --TODO: Storage
          local storage=cargo.storage
          text=text..string.format("\n- storage type=%s: amount: total=%d loaded=%d, lost=%d, delivered=%d, delivered=%s [UID=%s]",
          storage.cargoType, storage.cargoAmount, storage.cargoLoaded, storage.cargoLost, storage.cargoDelivered, tostring(cargo.delivered), tostring(cargo.uid))
        end
      end
      
      text=text..string.format("\nCarriers:")
      for _,_carrier in pairs(self.carriers) do
        local carrier=_carrier --Ops.OpsGroup#OPSGROUP
        text=text..string.format("\n- %s: %s [%s], Cargo Bay [current/reserved/total]=%d/%d/%d kg [free %d/%d/%d kg]", 
        carrier:GetName(), carrier.carrierStatus:upper(), carrier:GetState(), 
        carrier:GetWeightCargo(nil, false), carrier:GetWeightCargo(), carrier:GetWeightCargoMax(), 
        carrier:GetFreeCargobay(nil, false), carrier:GetFreeCargobay(), carrier:GetFreeCargobayMax())
      end
    end
    
    self:I(self.lid..text)
  end
  
  -- Check if all cargo was delivered (or is dead).
  self:_CheckDelivered()

  -- Update status again.
  if not self:IsDelivered() then
    self:__StatusUpdate(-30)
  end
end

--- Check if a cargo group was delivered.
-- @param #OPSTRANSPORT self
-- @param #string GroupName Name of the group.
-- @return #boolean If `true`, cargo was delivered.
function OPSTRANSPORT:IsCargoDelivered(GroupName)

  for _,_cargo in pairs(self:GetCargos()) do
    local cargo=_cargo  --Ops.OpsGroup#OPSGROUP.CargoGroup
    
    if cargo.opsgroup:GetName()==GroupName then
      return cargo.delivered
    end
    
  end
  
  return nil
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Event Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after "Planned" event.
-- @param #OPSTRANSPORT self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPSTRANSPORT:onafterPlanned(From, Event, To)
  self:T(self.lid..string.format("New status: %s-->%s", From, To))
end

--- On after "Scheduled" event.
-- @param #OPSTRANSPORT self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPSTRANSPORT:onafterScheduled(From, Event, To)
  self:T(self.lid..string.format("New status: %s-->%s", From, To))
end

--- On after "Executing" event.
-- @param #OPSTRANSPORT self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPSTRANSPORT:onafterExecuting(From, Event, To)
  self:T(self.lid..string.format("New status: %s-->%s", From, To))
end

--- On before "Delivered" event.
-- @param #OPSTRANSPORT self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPSTRANSPORT:onbeforeDelivered(From, Event, To)

  -- Check that we do not call delivered again.
  if From==OPSTRANSPORT.Status.DELIVERED then
    return false
  end

  return true
end

--- On after "Delivered" event.
-- @param #OPSTRANSPORT self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPSTRANSPORT:onafterDelivered(From, Event, To)
  self:T(self.lid..string.format("New status: %s-->%s", From, To))
  
  -- Inform all assigned carriers that cargo was delivered. They can have this in the queue or are currently processing this transport.
  for i=#self.carriers, 1, -1 do
    local carrier=self.carriers[i] --Ops.OpsGroup#OPSGROUP
    if self:GetCarrierTransportStatus(carrier)~=OPSTRANSPORT.Status.DELIVERED then
      carrier:Delivered(self)
    end 
  end
  
end

--- On after "Loaded" event.
-- @param #OPSTRANSPORT self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.OpsGroup#OPSGROUP OpsGroupCargo OPSGROUP that was loaded into a carrier.
-- @param Ops.OpsGroup#OPSGROUP OpsGroupCarrier OPSGROUP that was loaded into a carrier.
-- @param Ops.OpsGroup#OPSGROUP.Element CarrierElement Carrier element.
function OPSTRANSPORT:onafterLoaded(From, Event, To, OpsGroupCargo, OpsGroupCarrier, CarrierElement)
  self:I(self.lid..string.format("Loaded OPSGROUP %s into carrier %s", OpsGroupCargo:GetName(), tostring(CarrierElement.name)))
end

--- On after "Unloaded" event.
-- @param #OPSTRANSPORT self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.OpsGroup#OPSGROUP OpsGroupCargo Cargo OPSGROUP that was unloaded from a carrier.
-- @param Ops.OpsGroup#OPSGROUP OpsGroupCarrier Carrier OPSGROUP that unloaded the cargo.
function OPSTRANSPORT:onafterUnloaded(From, Event, To, OpsGroupCargo, OpsGroupCarrier)
  self:I(self.lid..string.format("Unloaded OPSGROUP %s", OpsGroupCargo:GetName()))
end

--- On after "DeadCarrierGroup" event.
-- @param #OPSTRANSPORT self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.OpsGroup#OPSGROUP OpsGroup Carrier OPSGROUP that is dead. 
function OPSTRANSPORT:onafterDeadCarrierGroup(From, Event, To, OpsGroup)
  self:I(self.lid..string.format("Carrier OPSGROUP %s dead!", OpsGroup:GetName()))

  -- Increase dead counter.
  self.NcarrierDead=self.NcarrierDead+1

  -- Remove group from carrier list/table.  
  self:_DelCarrier(OpsGroup)
  
  if #self.carriers==0 then
    self:DeadCarrierAll()
  end    
end

--- On after "DeadCarrierAll" event.
-- @param #OPSTRANSPORT self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state. 
function OPSTRANSPORT:onafterDeadCarrierAll(From, Event, To)
  self:I(self.lid..string.format("ALL Carrier OPSGROUPs are dead!"))

  if self.opszone then

    self:I(self.lid..string.format("Cancelling transport on CHIEF level"))
    self.chief:TransportCancel(self)
    
    --for _,_legion in pairs(self.legions) do
    --  local legion=_legion --Ops.Legion#LEGION
    --  legion:TransportCancel(self)
    --end

  else
  
    -- Check if cargo was delivered.
    self:_CheckDelivered()
    
    -- Set state back to PLANNED if not delivered.
    if not self:IsDelivered() then
      self:Planned()
    end
  
  end
  
end

--- On after "Cancel" event.
-- @param #OPSTRANSPORT self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPSTRANSPORT:onafterCancel(From, Event, To)

  -- Number of OPSGROUPS assigned and alive.
  local Ngroups = #self.carriers

  -- Debug info.
  self:I(self.lid..string.format("CANCELLING transport in status %s. Will wait for %d carrier groups to report DONE before evaluation", self:GetState(), Ngroups))
  
  -- Time stamp.
  self.Tover=timer.getAbsTime()
  
  
  if self.chief then

    -- Debug info.
    self:T(self.lid..string.format("CHIEF will cancel the transport. Will wait for mission DONE before evaluation!"))
    
    -- CHIEF will cancel the transport.
    self.chief:TransportCancel(self)
  
  elseif self.commander then
  
    -- Debug info.
    self:T(self.lid..string.format("COMMANDER will cancel the transport. Will wait for transport DELIVERED before evaluation!"))
    
    -- COMMANDER will cancel the transport.
    self.commander:TransportCancel(self)

  elseif self.legions and #self.legions>0 then
  
    -- Loop over all LEGIONs.
    for _,_legion in pairs(self.legions or {}) do
      local legion=_legion --Ops.Legion#LEGION
    
      -- Debug info.
      self:T(self.lid..string.format("LEGION %s will cancel the transport. Will wait for transport DELIVERED before evaluation!", legion.alias))
    
      -- Legion will cancel all flight missions and remove queued request from warehouse queue.
      legion:TransportCancel(self)
      
    end
    
  else  
  
    -- Debug info.
    self:T(self.lid..string.format("No legion, commander or chief. Attached OPS groups will cancel the transport on their own. Will wait for transport DELIVERED before evaluation!"))
  
    -- Loop over all carrier groups.
    for _,_carrier in pairs(self:GetCarriers()) do
      local carrier=_carrier --Ops.OpsGroup#OPSGROUP
      carrier:TransportCancel(self)
    end
    
    -- Delete awaited transport.
    local cargos=self:GetCargoOpsGroups(false)
    for _,_cargo in pairs(cargos) do
      local cargo=_cargo --Ops.OpsGroup#OPSGROUP
        cargo:_DelMyLift(self)
    end
    
    
  end

  -- Special mission states.
  if self:IsPlanned() or self:IsQueued() or self:IsRequested() or Ngroups==0 then
    self:T(self.lid..string.format("Cancelled transport was in %s stage with %d carrier groups assigned and alive. Call it DELIVERED!", self:GetState(), Ngroups))
    self:Delivered()
  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Check if all cargo of this transport assignment was delivered.
-- @param #OPSTRANSPORT self
function OPSTRANSPORT:_CheckDelivered()

  -- First check that at least one cargo was added (as we allow to do that later).
  if self.Ncargo>0 then

    local done=true
    local dead=true
    for _,_cargo in pairs(self:GetCargos()) do
      local cargo=_cargo --Ops.OpsGroup#OPSGROUP.CargoGroup
      
      if cargo.delivered then
        -- This one is delivered.
        dead=false
      elseif cargo.type==OPSTRANSPORT.CargoType.OPSGROUP and cargo.opsgroup==nil then
        -- This one is nil?!
        dead=false
      elseif cargo.type==OPSTRANSPORT.CargoType.OPSGROUP and cargo.opsgroup:IsDestroyed() then
        -- This one was destroyed.
      elseif cargo.type==OPSTRANSPORT.CargoType.OPSGROUP and cargo.opsgroup:IsDead() then
        -- This one is dead.
      elseif cargo.type==OPSTRANSPORT.CargoType.OPSGROUP and cargo.opsgroup:IsStopped() then
        -- This one is stopped.
        dead=false
      else
        done=false --Someone is not done!
        dead=false
      end
     
    end
    
    if dead then
      self:I(self.lid.."All cargo DEAD ==> Delivered!")
      self:Delivered()
    elseif done then
      self:I(self.lid.."All cargo DONE ==> Delivered!")
      self:Delivered()  
    end
    
  end
  
end

--- Check if all required cargos are loaded.
-- @param #OPSTRANSPORT self
-- @param #OPSTRANSPORT.TransportZoneCombo TransportZoneCombo Transport zone combo.
-- @param Ops.OpsGroup#OPSGROUP CarrierGroup The carrier group asking.
-- @return #boolean If true, all required cargos are loaded or there is no required cargo or asking carrier is full.
function OPSTRANSPORT:_CheckRequiredCargos(TransportZoneCombo, CarrierGroup)

  -- Use default TZC if no transport zone combo is provided.
  TransportZoneCombo=TransportZoneCombo or self.tzcDefault
  
  -- Use input or take all cargos.
  local requiredCargos=TransportZoneCombo.Cargos
  
  -- Check if required cargos was set by user.
  if TransportZoneCombo.RequiredCargos and #TransportZoneCombo.RequiredCargos>0 then
    requiredCargos=TransportZoneCombo.RequiredCargos
  else
    requiredCargos={}
    for _,_cargo in pairs(TransportZoneCombo.Cargos) do
      local cargo=_cargo --Ops.OpsGroup#OPSGROUP.CargoGroup
      if not cargo.delivered then
        table.insert(requiredCargos, cargo.opsgroup)
      end
    end
  end 
  
  if requiredCargos==nil or #requiredCargos==0 then
    return true
  end
  
  -- All carrier names.
  local carrierNames=self:_GetCarrierNames()
  
  -- Cargo groups not loaded yet.
  local weightmin=nil
  
  for _,_cargo in pairs(requiredCargos) do
    local cargo=_cargo --Ops.OpsGroup#OPSGROUP
    
    -- Is this cargo loaded into any carrier?
    local isLoaded=cargo:IsLoaded(carrierNames)
    
    if not isLoaded then
      local weight=cargo:GetWeightTotal()
      
      if weightmin==nil or weight<weightmin then
        weightmin=weight
      end
    end
    
  end
  
  if weightmin then
  
    -- Free space of carrier.
    local freeSpace=CarrierGroup:GetFreeCargobayMax(true)
    
    -- Debug info.
    self:T(self.lid..string.format("Check required cargos for carrier=%s free=%.1f, weight=%.1f", CarrierGroup:GetName(), freeSpace, weightmin))
    
    if weightmin<freeSpace then
      -- This group can still take cargo.
      return false    
    else
      -- This group is full! Even if there is cargo left, we cannot transport it.
      return true
    end
    
  end
  
  -- No cargo left.
  return true
end

--- Check if all given condition are true.
-- @param #OPSTRANSPORT self
-- @param #table Conditions Table of conditions.
-- @return #boolean If true, all conditions were true. Returns false if at least one condition returned false.
function OPSTRANSPORT:EvalConditionsAll(Conditions)

  -- Any stop condition must be true.
  for _,_condition in pairs(Conditions or {}) do
    local condition=_condition --#OPSTRANSPORT.Condition
  
    -- Call function.
    local istrue=condition.func(unpack(condition.arg))
    
    -- Any false will return false.
    if not istrue then
      return false
    end
    
  end

  -- All conditions were true.
  return true
end



--- Find transfer carrier element for cargo group.
-- @param #OPSTRANSPORT self
-- @param Ops.OpsGroup#OPSGROUP CargoGroup The cargo group that needs to be loaded into a carrier unit/element of the carrier group.
-- @param Core.Zone#ZONE Zone (Optional) Zone where the carrier must be in.
-- @param #table DisembarkCarriers Disembark carriers.
-- @param Wrapper.Airbase#AIRBASE DeployAirbase Airbase where to deploy.
-- @return Ops.OpsGroup#OPSGROUP.Element New carrier element for cargo or nil.
-- @return Ops.OpsGroup#OPSGROUP New carrier group for cargo or nil.
function OPSTRANSPORT:FindTransferCarrierForCargo(CargoGroup, Zone, DisembarkCarriers, DeployAirbase)

  -- Use default TZC if no transport zone combo is provided.
  --TransportZoneCombo=TransportZoneCombo or self.tzcDefault

  local carrier=nil --Ops.OpsGroup#OPSGROUP.Element
  local carrierGroup=nil --Ops.OpsGroup#OPSGROUP
  
  --TODO: maybe sort the carriers wrt to largest free cargo bay. Or better smallest free cargo bay that can take the cargo group weight.
  
  for _,_carrier in pairs(DisembarkCarriers or {}) do
    local carrierGroup=_carrier --Ops.OpsGroup#OPSGROUP
    
    -- First check if carrier is alive and loading cargo.
    if carrierGroup and carrierGroup:IsAlive() and (carrierGroup:IsLoading() or DeployAirbase) then
    
      -- Find an element of the group that has enough free space.
      carrier=carrierGroup:FindCarrierForCargo(CargoGroup)
      
      if carrier then
        if Zone==nil or Zone:IsVec2InZone(carrier.unit:GetVec2()) then
          return carrier, carrierGroup      
        else
          self:T2(self.lid.."Got transfer carrier but carrier not in zone (yet)!")
        end
      else
        self:T2(self.lid.."No transfer carrier available!")
      end
      
    end
  end

  self:T2(self.lid.."Could NOT find any carrier that is ALIVE and LOADING (or DELOYAIRBASE))!")
  return nil, nil
end

--- Create a cargo group data structure.
-- @param #OPSTRANSPORT self
-- @param Wrapper.Group#GROUP group The GROUP or OPSGROUP object.
-- @param #OPSTRANSPORT.TransportZoneCombo TransportZoneCombo Transport zone combo.
-- @param #boolean DisembarkActivation If `true`, cargo group is activated when disembarked. 
-- @param Core.Zone#ZONE DisembarkZone Disembark zone, where the cargo is spawned when delivered.
-- @param Core.Set#SET_OPSGROUP DisembarkCarriers Disembark carriers cargo is directly loaded into when delivered.
-- @return Ops.OpsGroup#OPSGROUP.CargoGroup Cargo group data.
function OPSTRANSPORT:_CreateCargoGroupData(group, TransportZoneCombo, DisembarkActivation, DisembarkZone, DisembarkCarriers)

  -- Get ops group.
  local opsgroup=self:_GetOpsGroupFromObject(group)

  -- First check that this group is not already contained in this TZC.  
  for _,_cargo in pairs(TransportZoneCombo.Cargos or {}) do
    local cargo=_cargo --Ops.OpsGroup#OPSGROUP.CargoGroup
    if cargo.opsgroup.groupname==opsgroup.groupname then
      -- Group is already contained.
      return nil
    end
  end

  self.cargocounter=self.cargocounter+1

  -- Create a new data item.
  local cargo={} --Ops.OpsGroup#OPSGROUP.CargoGroup
  cargo.uid=self.cargocounter
  cargo.type="OPSGROUP"
  cargo.opsgroup=opsgroup
  cargo.delivered=false
  cargo.status="Unknown"
  cargo.tzcUID=TransportZoneCombo
  cargo.disembarkZone=DisembarkZone
  if DisembarkCarriers then
    cargo.disembarkCarriers={}
    self:_AddDisembarkCarriers(DisembarkCarriers, cargo.disembarkCarriers)
  end

  return cargo
end

--- Create a cargo group data structure.
-- @param #OPSTRANSPORT self
-- @param Wrapper.Storage#STORAGE StorageFrom Storage from.
-- @param Wrapper.Storage#STORAGE StorageTo Storage to.
-- @param #string CargoType Type of cargo.
-- @param #number CargoAmount Total amount of cargo that should be transported. Liquids in kg.
-- @param #number CargoWeight Weight of a single cargo item in kg. Default 1 kg.
-- @param #OPSTRANSPORT.TransportZoneCombo TransportZoneCombo Transport zone combo.
-- @return Ops.OpsGroup#OPSGROUP.CargoGroup Cargo group data.
function OPSTRANSPORT:_CreateCargoStorage(StorageFrom, StorageTo, CargoType, CargoAmount, CargoWeight, TransportZoneCombo)

  local storage={}  --#OPSTRANSPORT.Storage
  storage.storageFrom=StorageFrom
  storage.storageTo=StorageTo
  storage.cargoType=CargoType
  storage.cargoAmount=CargoAmount
  storage.cargoDelivered=0
  storage.cargoLost=0
  storage.cargoReserved=0
  storage.cargoLoaded=0
  storage.cargoWeight=CargoWeight or 1

  self.cargocounter=self.cargocounter+1  

  -- Create a new data item.
  local cargo={} --Ops.OpsGroup#OPSGROUP.CargoGroup
  cargo.uid=self.cargocounter
  cargo.type="STORAGE"
  cargo.opsgroup=nil
  cargo.storage=storage
  cargo.delivered=false
  cargo.status="Unknown"
  cargo.tzcUID=TransportZoneCombo
  cargo.disembarkZone=nil
  cargo.disembarkCarriers=nil

  return cargo
end

--- Count how many cargo groups are inside a zone.
-- @param #OPSTRANSPORT self
-- @param Core.Zone#ZONE Zone The zone object.
-- @param #boolean Delivered If `true`, only delivered groups are returned. If `false` only undelivered groups are returned. If `nil`, all groups are returned.
-- @param Ops.OpsGroup#OPSGROUP Carrier (Optional) Only count cargo groups that fit into the given carrier group. Current cargo is not a factor.
-- @param #OPSTRANSPORT.TransportZoneCombo TransportZoneCombo Transport zone combo.
-- @return #number Number of cargo groups.
function OPSTRANSPORT:_CountCargosInZone(Zone, Delivered, Carrier, TransportZoneCombo)

  -- Get cargo ops groups.
  --local cargos=self:GetCargoOpsGroups(Delivered, Carrier, TransportZoneCombo)
  
  local cargos=self:GetCargos(TransportZoneCombo, Carrier, Delivered)
  
  --- Function to check if carrier is supposed to be disembarked to.
  local function iscarrier(_cargo)
    local cargo=_cargo --Ops.OpsGroup#OPSGROUP
    
    local mycarrier=cargo:_GetMyCarrierGroup()
    
    if mycarrier and mycarrier:IsUnloading() then
    
      -- Get disembark carriers.
      local carriers=mycarrier.cargoTransport:GetDisembarkCarriers(mycarrier.cargoTZC)
    
      -- Check if carrier is in the list.
      for _,_carrier in pairs(carriers) do
        local carrier=_carrier --Ops.OpsGroup#OPSGROUP
        if Carrier:GetName()==carrier:GetName() then
          return true
        end
      end
      
      if mycarrier.cargoTZC and mycarrier.cargoTZC.Cargos then
        for _,_cargodata in pairs(mycarrier.cargoTZC.Cargos) do
          local cargodata=_cargodata --Ops.OpsGroup#OPSGROUP.CargoGroup
          if cargo:GetName()==cargodata.opsgroup:GetName() then          
            for _,_carrier in pairs(cargodata.disembarkCarriers) do
              local carrier=_carrier --Ops.OpsGroup#OPSGROUP
              if Carrier:GetName()==carrier:GetName() then
                return true
              end            
            end
          end
        end
      end
      
    end
    
    return false
  end
  
  local N=0
  for _,_cargo in pairs(cargos) do
    local cargo=_cargo --Ops.OpsGroup#OPSGROUP.CargoGroup
    
    local isNotCargo=true
    local isInZone=true
    local isInUtero=true
    
    if cargo.type==OPSTRANSPORT.CargoType.OPSGROUP then
      local opsgroup=cargo.opsgroup

      -- Is not cargo? 
      isNotCargo=opsgroup:IsNotCargo(true)
      if not isNotCargo then
        isNotCargo=iscarrier(opsgroup)
      end    
  
      -- Is in zone?
      isInZone=opsgroup:IsInZone(Zone)
      
      -- Is in utero?
      isInUtero=opsgroup:IsInUtero()

      -- Debug info.
      self:T(self.lid..string.format("Cargo=%s: notcargo=%s, iscarrier=%s inzone=%s, inutero=%s", opsgroup:GetName(), tostring(opsgroup:IsNotCargo(true)), tostring(iscarrier(opsgroup)), tostring(isInZone), tostring(isInUtero)))

      
    end


    -- We look for groups that are not cargo, in the zone or in utero.
    if isNotCargo and (isInZone or isInUtero) then
      N=N+1
    end
  end
  
  -- Debug info.
  self:T(self.lid..string.format("Found %d units in zone %s", N, Zone:GetName()))

  return N
end

--- Get a transport zone combination (TZC) for a carrier group. The pickup zone will be a zone, where the most cargo groups are located that fit into the carrier.
-- @param #OPSTRANSPORT self
-- @param Ops.OpsGroup#OPSGROUP Carrier The carrier OPS group.
-- @return Core.Zone#ZONE Pickup zone or `#nil`.
function OPSTRANSPORT:_GetTransportZoneCombo(Carrier)

  --- Selection criteria
  -- * Distance: pickup zone should be as close as possible.
  -- * Ncargo: Number of cargo groups. Pickup, where there is most cargo.
  -- * Ncarrier: Number of carriers already "working" on this TZC. Would be better if not all carriers work on the same combo while others are ignored.  
  
  -- Get carrier position.
  local vec2=Carrier:GetVec2()

  --- Penalty function.
  local function penalty(candidate)      
    local p=candidate.ncarriers*10-candidate.ncargo+candidate.distance/10
    return p
  end
  
  -- TZC candidates.
  local candidates={}
  
  for i,_transportzone in pairs(self.tzCombos) do
    local tz=_transportzone --#OPSTRANSPORT.TransportZoneCombo
    
    -- Check that pickup and deploy zones were defined.
    if tz.PickupZone and tz.DeployZone and tz.EmbarkZone then
    
      --TODO: Check if Carrier is an aircraft and if so, check that pickup AND deploy zones are airbases (not ships, not farps).
    
      -- Count undelivered cargos in embark(!) zone that fit into the carrier.
      local ncargo=self:_CountCargosInZone(tz.EmbarkZone, false, Carrier, tz)
      
      -- At least one group in the zone.
      if ncargo>=1 then
        
        -- Distance to the carrier in meters.
        local dist=tz.PickupZone:Get2DDistance(vec2)
        
        local ncarriers=0
        for _,_carrier in pairs(self.carriers) do
          local carrier=_carrier --Ops.OpsGroup#OPSGROUP
          if carrier and carrier:IsAlive() and carrier.cargoTZC and carrier.cargoTZC.uid==tz.uid then
            ncarriers=ncarriers+1
          end
        end
        
        -- New candidate.
        local candidate={tzc=tz, distance=dist/1000, ncargo=ncargo, ncarriers=ncarriers}
        
        -- Calculdate penalty of candidate.
        candidate.penalty=penalty(candidate)
        
        -- Add candidate.
        table.insert(candidates, candidate)
        
      end
    end
  end
  
  if #candidates>0 then
   
    -- Minimize penalty.
    local function optTZC(candA, candB)
      return candA.penalty<candB.penalty
    end
    table.sort(candidates, optTZC)
    
    -- Debug output.
    if self.verbose>=3 then
      local text="TZC optimized"
      for i,candidate in pairs(candidates) do
        text=text..string.format("\n[%d] TPZ=%d, Ncarriers=%d, Ncargo=%d, Distance=%.1f km, PENALTY=%d", i, candidate.tzc.uid, candidate.ncarriers, candidate.ncargo, candidate.distance, candidate.penalty)
      end
      self:I(self.lid..text)
    end
    
    -- Return best candidate.
    return candidates[1].tzc    
  else
    -- No candidates.
    self:T(self.lid..string.format("Could NOT find a pickup zone (with cargo) for carrier group %s", Carrier:GetName()))
  end  

  return nil
end

--- Get an OPSGROUP from a given OPSGROUP or GROUP object. If the object is a GROUP, an OPSGROUP is created automatically. 
-- @param #OPSTRANSPORT self
-- @param Core.Base#BASE Object The object, which can be a GROUP or OPSGROUP.
-- @return Ops.OpsGroup#OPSGROUP Ops Group.
function OPSTRANSPORT:_GetOpsGroupFromObject(Object)

  local opsgroup=nil

  if Object:IsInstanceOf("OPSGROUP") then
    -- We already have an OPSGROUP
    opsgroup=Object
  elseif Object:IsInstanceOf("GROUP") then
  
    -- Look into DB and try to find an existing OPSGROUP.
    opsgroup=_DATABASE:GetOpsGroup(Object)
    
    if not opsgroup then
      if Object:IsAir() then
        opsgroup=FLIGHTGROUP:New(Object)
      elseif Object:IsShip() then
        opsgroup=NAVYGROUP:New(Object)
      else
        opsgroup=ARMYGROUP:New(Object)
      end
    end
    
  else
    self:E(self.lid.."ERROR: Object must be a GROUP or OPSGROUP object!")
    return nil
  end

  return opsgroup
end
