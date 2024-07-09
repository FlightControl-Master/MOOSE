--- **Ops** - Fleet Warehouse.
--
-- **Main Features:**
--
--    * Manage flotillas
--    * Carry out ARTY and PATROLZONE missions (AUFTRAG)
-- 
-- ===
--
-- ## Example Missions:
--
-- Demo missions can be found on [github](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/develop/Ops/Fleet).
-- 
-- ===
--
-- ### Author: **funkyfranky**
-- 
-- ===
-- @module Ops.Fleet
-- @image OPS_Fleet.png


--- FLEET class.
-- @type FLEET
-- @field #string ClassName Name of the class.
-- @field #number verbose Verbosity of output.
-- @field Core.Set#SET_ZONE retreatZones Retreat zone set.
-- @field #boolean pathfinding Set pathfinding on for all spawned navy groups.
-- @extends Ops.Legion#LEGION

--- *A fleet of British ships at war are the best negotiators.* -- Horatio Nelson
--
-- ===
--
-- # The FLEET Concept
--
-- A FLEET consists of one or multiple FLOTILLAs. These flotillas "live" in a WAREHOUSE that has a phyiscal struction (STATIC or UNIT) and can be captured or destroyed.
-- 
-- # Basic Setup
-- 
-- A new `FLEET` object can be created with the @{#FLEET.New}(`WarehouseName`, `FleetName`) function, where `WarehouseName` is the name of the static or unit object hosting the fleet
-- and `FleetName` is the name you want to give the fleet. This must be *unique*!
-- 
--     myFleet=FLEET:New("myWarehouseName", "1st Fleet")
--     myFleet:SetPortZone(ZonePort1stFleet)
--     myFleet:Start()
--     
-- A fleet needs a *port zone*, which is set via the @{#FLEET.SetPortZone}(`PortZone`) function. This is the zone where the naval assets are spawned and return to.
-- 
-- Finally, the fleet needs to be started using the @{#FLEET.Start}() function. If the fleet is not started, it will not process any requests.
-- 
-- ## Adding Flotillas
-- 
-- Flotillas can be added via the @{#FLEET.AddFlotilla}(`Flotilla`) function. See @{Ops.Flotilla#FLOTILLA} for how to create a flotilla.
-- 
--     myFleet:AddFlotilla(FlotillaTiconderoga)
--     myFleet:AddFlotilla(FlotillaPerry)
--     
--
--
-- @field #FLEET
FLEET = {
  ClassName       = "FLEET",
  verbose         =       0,
  pathfinding     =   false,
}

--- Supply Zone.
-- @type FLEET.SupplyZone
-- @field Core.Zone#ZONE zone The zone.
-- @field Ops.Auftrag#AUFTRAG mission Mission assigned to supply ammo or fuel.
-- @field #boolean markerOn If `true`, marker is on.
-- @field Wrapper.Marker#MARKER marker F10 marker.

--- FLEET class version.
-- @field #string version
FLEET.version="0.0.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ToDo list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Add routes?
-- DONE: Add weapon range.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new FLEET class object.
-- @param #FLEET self
-- @param #string WarehouseName Name of the warehouse STATIC or UNIT object representing the warehouse.
-- @param #string FleetName Name of the fleet.
-- @return #FLEET self
function FLEET:New(WarehouseName, FleetName)

  -- Inherit everything from LEGION class.
  local self=BASE:Inherit(self, LEGION:New(WarehouseName, FleetName)) -- #FLEET

  -- Nil check.
  if not self then
    BASE:E(string.format("ERROR: Could not find warehouse %s!", WarehouseName))
    return nil
  end

  -- Set some string id for output to DCS.log file.
  self.lid=string.format("FLEET %s | ", self.alias)
  
  -- Defaults
  self:SetRetreatZones()
  
  -- Turn ship into NAVYGROUP.
  if self:IsShip() then
    local wh=self.warehouse --Wrapper.Unit#UNIT
    local group=wh:GetGroup()
    self.warehouseOpsGroup=NAVYGROUP:New(group) --Ops.NavyGroup#NAVYGROUP
    self.warehouseOpsElement=self.warehouseOpsGroup:GetElementByName(wh:GetName())
  end


  -- Add FSM transitions.
  --                 From State  -->   Event         -->      To State
  self:AddTransition("*",             "NavyOnMission",        "*")           -- An NAVYGROUP was send on a Mission (AUFTRAG).

  ------------------------
  --- Pseudo Functions ---
  ------------------------

  --- Triggers the FSM event "Start". Starts the FLEET. Initializes parameters and starts event handlers.
  -- @function [parent=#FLEET] Start
  -- @param #FLEET self

  --- Triggers the FSM event "Start" after a delay. Starts the FLEET. Initializes parameters and starts event handlers.
  -- @function [parent=#FLEET] __Start
  -- @param #FLEET self
  -- @param #number delay Delay in seconds.


  --- Triggers the FSM event "Stop". Stops the FLEET and all its event handlers.
  -- @param #FLEET self

  --- Triggers the FSM event "Stop" after a delay. Stops the FLEET and all its event handlers.
  -- @function [parent=#FLEET] __Stop
  -- @param #FLEET self
  -- @param #number delay Delay in seconds.


  --- Triggers the FSM event "NavyOnMission".
  -- @function [parent=#FLEET] NavyOnMission
  -- @param #FLEET self
  -- @param Ops.NavyGroup#NAVYGROUP ArmyGroup The NAVYGROUP on mission.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.

  --- Triggers the FSM event "NavyOnMission" after a delay.
  -- @function [parent=#FLEET] __NavyOnMission
  -- @param #FLEET self
  -- @param #number delay Delay in seconds.
  -- @param Ops.NavyGroup#NAVYGROUP ArmyGroup The NAVYGROUP on mission.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.

  --- On after "NavyOnMission" event.
  -- @function [parent=#FLEET] OnAfterNavyOnMission
  -- @param #FLEET self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.NavyGroup#NAVYGROUP NavyGroup The NAVYGROUP on mission.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Add a flotilla to the fleet.
-- @param #FLEET self
-- @param Ops.Flotilla#FLOTILLA Flotilla The flotilla object.
-- @return #FLEET self
function FLEET:AddFlotilla(Flotilla)

  -- Add flotilla to fleet.
  table.insert(self.cohorts, Flotilla)

  -- Add assets to flotilla.
  self:AddAssetToFlotilla(Flotilla, Flotilla.Ngroups)

  -- Set fleet of flotilla.
  Flotilla:SetFleet(self)

  -- Start flotilla.
  if Flotilla:IsStopped() then
    Flotilla:Start()
  end

  return self
end

--- Add asset group(s) to flotilla.
-- @param #FLEET self
-- @param Ops.Flotilla#FLOTILLA Flotilla The flotilla object.
-- @param #number Nassets Number of asset groups to add.
-- @return #FLEET self
function FLEET:AddAssetToFlotilla(Flotilla, Nassets)

  if Flotilla then

    -- Get the template group of the flotilla.
    local Group=GROUP:FindByName(Flotilla.templatename)

    if Group then

      -- Debug text.
      local text=string.format("Adding asset %s to flotilla %s", Group:GetName(), Flotilla.name)
      self:T(self.lid..text)

      -- Add assets to airwing warehouse.
      self:AddAsset(Group, Nassets, nil, nil, nil, nil, Flotilla.skill, Flotilla.livery, Flotilla.name)

    else
      self:E(self.lid.."ERROR: Group does not exist!")
    end

  else
    self:E(self.lid.."ERROR: Flotilla does not exit!")
  end

  return self
end

--- Set pathfinding for all spawned naval groups.
-- @param #FLEET self
-- @param #boolean Switch If `true`, pathfinding is used.
-- @return #FLEET self
function FLEET:SetPathfinding(Switch)
  self.pathfinding=Switch
  return self
end

--- Define a set of retreat zones.
-- @param #FLEET self
-- @param Core.Set#SET_ZONE RetreatZoneSet Set of retreat zones.
-- @return #FLEET self
function FLEET:SetRetreatZones(RetreatZoneSet)
  self.retreatZones=RetreatZoneSet or SET_ZONE:New()
  return self
end

--- Add a retreat zone.
-- @param #FLEET self
-- @param Core.Zone#ZONE RetreatZone Retreat zone.
-- @return #FLEET self
function FLEET:AddRetreatZone(RetreatZone)
  self.retreatZones:AddZone(RetreatZone)
  return self
end

--- Get retreat zones.
-- @param #FLEET self
-- @return Core.Set#SET_ZONE Set of retreat zones.
function FLEET:GetRetreatZones()
  return self.retreatZones
end

--- Get flotilla by name.
-- @param #FLEET self
-- @param #string FlotillaName Name of the flotilla.
-- @return Ops.Flotilla#FLOTILLA The Flotilla object.
function FLEET:GetFlotilla(FlotillaName)
  local flotilla=self:_GetCohort(FlotillaName)
  return flotilla
end

--- Get flotilla of an asset.
-- @param #FLEET self
-- @param Functional.Warehouse#WAREHOUSE.Assetitem Asset The flotilla asset.
-- @return Ops.Flotilla#FLOTILLA The flotilla object.
function FLEET:GetFlotillaOfAsset(Asset)
  local flotilla=self:GetFlotilla(Asset.squadname)
  return flotilla
end

--- Remove asset from flotilla.
-- @param #FLEET self
-- @param Functional.Warehouse#WAREHOUSE.Assetitem Asset The flotilla asset.
function FLEET:RemoveAssetFromFlotilla(Asset)
  local flotilla=self:GetFlotillaOfAsset(Asset)
  if flotilla then
    flotilla:DelAsset(Asset)
  end
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Start FLEET FSM.
-- @param #FLEET self
function FLEET:onafterStart(From, Event, To)

  -- Start parent Warehouse.
  self:GetParent(self, FLEET).onafterStart(self, From, Event, To)

  -- Info.
  self:I(self.lid..string.format("Starting FLEET v%s", FLEET.version))

end

--- Update status.
-- @param #FLEET self
function FLEET:onafterStatus(From, Event, To)

  -- Status of parent Warehouse.
  self:GetParent(self).onafterStatus(self, From, Event, To)

  -- FSM state.
  local fsmstate=self:GetState()
  
  ----------------
  -- Transport ---
  ----------------
  
  self:CheckTransportQueue()

  --------------
  -- Mission ---
  --------------

  -- Check if any missions should be cancelled.
  self:CheckMissionQueue()

  -----------
  -- Info ---
  -----------    

  -- Display tactival overview.
  self:_TacticalOverview()

  -- General info:
  if self.verbose>=1 then

    -- Count missions not over yet.
    local Nmissions=self:CountMissionsInQueue()

    -- Asset count.
    local Npq, Np, Nq=self:CountAssetsOnMission()

    -- Asset string.
    local assets=string.format("%d [OnMission: Total=%d, Active=%d, Queued=%d]", self:CountAssets(), Npq, Np, Nq)

    -- Output.
    local text=string.format("%s: Missions=%d, Flotillas=%d, Assets=%s", fsmstate, Nmissions, #self.cohorts, assets)
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
      local assets=string.format("%d/%d", mission:CountOpsGroups(), mission.Nassets or 0)
      local target=string.format("%d/%d Damage=%.1f", mission:CountMissionTargets(), mission:GetTargetInitialNumber(), mission:GetTargetDamage())

      text=text..string.format("\n[%d] %s %s: Status=%s, Prio=%s, Assets=%s, Targets=%s", i, mission.name, mission.type, mission.status, prio, assets, target)
    end
    self:I(self.lid..text)
  end

  --------------------
  -- Transport Info --
  --------------------
  if self.verbose>=2 then
    local text=string.format("Transports Total=%d:", #self.transportqueue)
    for i,_transport in pairs(self.transportqueue) do
      local transport=_transport --Ops.OpsTransport#OPSTRANSPORT

      local prio=string.format("%d/%s", transport.prio, tostring(transport.importance)) ; if transport.urgent then prio=prio.." (!)" end
      local carriers=string.format("Ncargo=%d/%d, Ncarriers=%d", transport.Ncargo, transport.Ndelivered, transport.Ncarrier)

      text=text..string.format("\n[%d] UID=%d: Status=%s, Prio=%s, Cargo: %s", i, transport.uid, transport:GetState(), prio, carriers)
    end
    self:I(self.lid..text)
  end

  -------------------
  -- Flotilla Info --
  -------------------
  if self.verbose>=3 then
    local text="Flotillas:"
    for i,_flotilla in pairs(self.cohorts) do
      local flotilla=_flotilla --Ops.Flotilla#FLOTILLA

      local callsign=flotilla.callsignName and UTILS.GetCallsignName(flotilla.callsignName) or "N/A"
      local modex=flotilla.modex and flotilla.modex or -1
      local skill=flotilla.skill and tostring(flotilla.skill) or "N/A"

      -- Flotilla text.
      text=text..string.format("\n* %s %s: %s*%d/%d, Callsign=%s, Modex=%d, Skill=%s", flotilla.name, flotilla:GetState(), flotilla.aircrafttype, flotilla:CountAssets(true), #flotilla.assets, callsign, modex, skill)
    end
    self:I(self.lid..text)
  end
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after "NavyOnMission".
-- @param #FLEET self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.ArmyGroup#ARMYGROUP ArmyGroup Ops army group on mission.
-- @param Ops.Auftrag#AUFTRAG Mission The requested mission.
function FLEET:onafterNavyOnMission(From, Event, To, NavyGroup, Mission)
  -- Debug info.
  self:T(self.lid..string.format("Group %s on %s mission %s", NavyGroup:GetName(), Mission:GetType(), Mission:GetName()))  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
