--- **Ops** - Brigade Warehouse.
--
-- **Main Features:**
--
--    * Manage platoons
--
-- ===
--
-- ### Author: **funkyfranky**
-- 
-- @module Ops.Brigade
-- @image OPS_Brigade.png


--- BRIGADE class.
-- @type BRIGADE
-- @field #string ClassName Name of the class.
-- @field #number verbose Verbosity of output.
-- @extends Ops.Legion#LEGION

--- Be surprised!
--
-- ===
--
-- # The BRIGADE Concept
--
-- An BRIGADE consists of multiple PLATOONS. These platoons "live" in a WAREHOUSE that has a phyiscal struction (STATIC or UNIT) and can be captured or destroyed.
--
--
-- @field #BRIGADE
BRIGADE = {
  ClassName      = "BRIGADE",
  verbose        =     0,
}


--- BRIGADE class version.
-- @field #string version
BRIGADE.version="0.1.0"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ToDo list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- DONE: Add weapon range.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new BRIGADE class object.
-- @param #BRIGADE self
-- @param #string WarehouseName Name of the warehouse STATIC or UNIT object representing the warehouse.
-- @param #string BrigadeName Name of the brigade.
-- @return #BRIGADE self
function BRIGADE:New(WarehouseName, BrigadeName)

  -- Inherit everything from LEGION class.
  local self=BASE:Inherit(self, LEGION:New(WarehouseName, BrigadeName)) -- #BRIGADE

  -- Nil check.
  if not self then
    BASE:E(string.format("ERROR: Could not find warehouse %s!", WarehouseName))
    return nil
  end

  -- Set some string id for output to DCS.log file.
  self.lid=string.format("BRIGADE %s | ", self.alias)

  -- Add FSM transitions.
  --                 From State  -->   Event         -->      To State
  self:AddTransition("*",             "ArmyOnMission",       "*")           -- An ARMYGROUP was send on a Mission (AUFTRAG).

  ------------------------
  --- Pseudo Functions ---
  ------------------------

  --- Triggers the FSM event "Start". Starts the BRIGADE. Initializes parameters and starts event handlers.
  -- @function [parent=#BRIGADE] Start
  -- @param #BRIGADE self

  --- Triggers the FSM event "Start" after a delay. Starts the BRIGADE. Initializes parameters and starts event handlers.
  -- @function [parent=#BRIGADE] __Start
  -- @param #BRIGADE self
  -- @param #number delay Delay in seconds.


  --- Triggers the FSM event "Stop". Stops the BRIGADE and all its event handlers.
  -- @param #BRIGADE self

  --- Triggers the FSM event "Stop" after a delay. Stops the BRIGADE and all its event handlers.
  -- @function [parent=#BRIGADE] __Stop
  -- @param #BRIGADE self
  -- @param #number delay Delay in seconds.


  --- Triggers the FSM event "ArmyOnMission".
  -- @function [parent=#BRIGADE] ArmyOnMission
  -- @param #BRIGADE self
  -- @param Ops.ArmyGroup#ARMYGROUP ArmyGroup The ARMYGROUP on mission.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.

  --- Triggers the FSM event "ArmyOnMission" after a delay.
  -- @function [parent=#BRIGADE] __ArmyOnMission
  -- @param #BRIGADE self
  -- @param #number delay Delay in seconds.
  -- @param Ops.ArmyGroup#ARMYGROUP ArmyGroup The ARMYGROUP on mission.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.

  --- On after "ArmyOnMission" event.
  -- @function [parent=#BRIGADE] OnAfterArmyOnMission
  -- @param #BRIGADE self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.ArmyGroup#ARMYGROUP ArmyGroup The ARMYGROUP on mission.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Add a platoon to the brigade.
-- @param #BRIGADE self
-- @param Ops.Platoon#PLATOON Platoon The platoon object.
-- @return #BRIGADE self
function BRIGADE:AddPlatoon(Platoon)

  -- Add platoon to brigade.
  table.insert(self.cohorts, Platoon)

  -- Add assets to platoon.
  self:AddAssetToPlatoon(Platoon, Platoon.Ngroups)

  -- Set brigade of platoon.
  Platoon:SetBrigade(self)

  -- Start platoon.
  if Platoon:IsStopped() then
    Platoon:Start()
  end

  return self
end



--- Add asset group(s) to platoon.
-- @param #BRIGADE self
-- @param Ops.Platoon#PLATOON Platoon The platoon object.
-- @param #number Nassets Number of asset groups to add.
-- @return #BRIGADE self
function BRIGADE:AddAssetToPlatoon(Platoon, Nassets)

  if Platoon then

    -- Get the template group of the platoon.
    local Group=GROUP:FindByName(Platoon.templatename)

    if Group then

      -- Debug text.
      local text=string.format("Adding asset %s to platoon %s", Group:GetName(), Platoon.name)
      self:T(self.lid..text)

      -- Add assets to airwing warehouse.
      self:AddAsset(Group, Nassets, nil, nil, nil, nil, Platoon.skill, Platoon.livery, Platoon.name)

    else
      self:E(self.lid.."ERROR: Group does not exist!")
    end

  else
    self:E(self.lid.."ERROR: Platoon does not exit!")
  end

  return self
end

--- Get platoon by name.
-- @param #BRIGADE self
-- @param #string PlatoonName Name of the platoon.
-- @return Ops.Platoon#PLATOON The Platoon object.
function BRIGADE:GetPlatoon(PlatoonName)
  local platoon=self:_GetCohort(PlatoonName)
  return platoon
end

--- Get platoon of an asset.
-- @param #BRIGADE self
-- @param Functional.Warehouse#WAREHOUSE.Assetitem Asset The platoon asset.
-- @return Ops.Platoon#PLATOON The platoon object.
function BRIGADE:GetPlatoonOfAsset(Asset)
  local platoon=self:GetPlatoon(Asset.squadname)
  return platoon
end

--- Remove asset from platoon.
-- @param #BRIGADE self
-- @param Functional.Warehouse#WAREHOUSE.Assetitem Asset The platoon asset.
function BRIGADE:RemoveAssetFromPlatoon(Asset)
  local platoon=self:GetPlatoonOfAsset(Asset)
  if platoon then
    platoon:DelAsset(Asset)
  end
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Start BRIGADE FSM.
-- @param #BRIGADE self
function BRIGADE:onafterStart(From, Event, To)

  -- Start parent Warehouse.
  self:GetParent(self, BRIGADE).onafterStart(self, From, Event, To)

  -- Info.
  self:I(self.lid..string.format("Starting BRIGADE v%s", BRIGADE.version))

end

--- Update status.
-- @param #BRIGADE self
function BRIGADE:onafterStatus(From, Event, To)

  -- Status of parent Warehouse.
  self:GetParent(self).onafterStatus(self, From, Event, To)

  -- FSM state.
  local fsmstate=self:GetState()

  -- General info:
  if self.verbose>=1 then

    -- Count missions not over yet.
    local Nmissions=self:CountMissionsInQueue()

    -- Asset count.
    local Npq, Np, Nq=self:CountAssetsOnMission()

    -- Asset string.
    local assets=string.format("%d [OnMission: Total=%d, Active=%d, Queued=%d]", self:CountAssets(), Npq, Np, Nq)

    -- Output.
    local text=string.format("%s: Missions=%d, Platoons=%d, Assets=%s", fsmstate, Nmissions, #self.cohorts, assets)
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
  -- Platoon Info --
  -------------------
  if self.verbose>=3 then
    local text="Platoons:"
    for i,_platoon in pairs(self.cohorts) do
      local platoon=_platoon --Ops.Platoon#PLATOON

      local callsign=platoon.callsignName and UTILS.GetCallsignName(platoon.callsignName) or "N/A"
      local modex=platoon.modex and platoon.modex or -1
      local skill=platoon.skill and tostring(platoon.skill) or "N/A"

      -- Platoon text.
      text=text..string.format("\n* %s %s: %s*%d/%d, Callsign=%s, Modex=%d, Skill=%s", platoon.name, platoon:GetState(), platoon.aircrafttype, platoon:CountAssets(true), #platoon.assets, callsign, modex, skill)
    end
    self:I(self.lid..text)
  end

  ----------------
  -- Transport ---
  ----------------

  -- Check if any transports should be cancelled.
  --self:_CheckTransports()

  -- Get next mission.
  local transport=self:_GetNextTransport()

  -- Request mission execution.
  if transport then
    self:TransportRequest(transport)
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

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after "ArmyOnMission".
-- @param #BRIGADE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.ArmyGroup#ARMYGROUP ArmyGroup Ops army group on mission.
-- @param Ops.Auftrag#AUFTRAG Mission The requested mission.
function BRIGADE:onafterArmyOnMission(From, Event, To, ArmyGroup, Mission)
  -- Debug info.
  self:T(self.lid..string.format("Group %s on %s mission %s", ArmyGroup:GetName(), Mission:GetType(), Mission:GetName()))  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
