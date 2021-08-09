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
-- @field Ops.General#GENERAL general The genral responsible for this brigade.
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
  verbose        =     3,
  genral         =   nil,
}


--- BRIGADE class version.
-- @field #string version
BRIGADE.version="0.0.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ToDo list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: A lot!

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
  --                 From State  -->   Event          -->     To State
  self:AddTransition("*",             "PlatoonOnMission",     "*")           -- Add a (mission) request to the warehouse.

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

  -- Add squadron to airwing.
  table.insert(self.cohorts, Platoon)

  -- Add assets to squadron.
  self:AddAssetToPlatoon(Platoon, Platoon.Ngroups)

  -- Set airwing to squadron.
  Platoon:SetBrigade(self)

  -- Start squadron.
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

    -- Get the template group of the squadron.
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
    self:E(self.lid.."ERROR: Squadron does not exit!")
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
-- @param Ops.Warehouse#WAREHOUSE.Assetitem Asset The platoon asset.
-- @return Ops.Platoon#PLATOON The platoon object.
function BRIGADE:GetSquadronOfAsset(Asset)
  local platoon=self:GetPlatoon(Asset.squadname)
  return platoon
end

--- Remove asset from squadron.
-- @param #BRIGADE self
-- @param #BRIGADE.SquadronAsset Asset The squad asset.
function BRIGADE:RemoveAssetFromSquadron(Asset)
  local squad=self:GetSquadronOfAsset(Asset)
  if squad then
    squad:DelAsset(Asset)
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

  local fsmstate=self:GetState()
  
  env.info("FF Brigade status "..fsmstate)

  -- General info:
  if self.verbose>=1 then

    -- Count missions not over yet.
    local Nmissions=self:CountMissionsInQueue()

    -- Assets tot
    local Npq, Np, Nq=self:CountAssetsOnMission()

    local assets=string.format("%d (OnMission: Total=%d, Active=%d, Queued=%d)", self:CountAssets(), Npq, Np, Nq)

    -- Output.
    local text=string.format("%s: Missions=%d, Squads=%d, Assets=%s", fsmstate, Nmissions, #self.cohorts, assets)
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
    local text="Platoons:"
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



-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
