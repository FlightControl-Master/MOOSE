--- **Ops** - Brigade Warehouse.
--
-- **Main Features:**
--
--    * Manage platoons
--    * Carry out ARTY and PATROLZONE missions (AUFTRAG)
--    * Define rearming zones
-- 
-- ===
--
-- ## Example Missions:
--
-- Demo missions can be found on [github](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/develop/Ops/Brigade).
-- 
-- ===
--
-- ### Author: **funkyfranky**
-- 
-- ===
-- @module Ops.Brigade
-- @image OPS_Brigade_.png


--- BRIGADE class.
-- @type BRIGADE
-- @field #string ClassName Name of the class.
-- @field #number verbose Verbosity of output.
-- @field #table rearmingZones Rearming zones. Each element is of type `#BRIGADE.SupplyZone`.
-- @field #table refuellingZones Refuelling zones. Each element is of type `#BRIGADE.SupplyZone`.
-- @field Core.Set#SET_ZONE retreatZones Retreat zone set.
-- @extends Ops.Legion#LEGION

--- *I am not afraid of an Army of lions lead by a sheep; I am afraid of sheep lead by a lion* -- Alexander the Great
--
-- ===
--
-- # The BRIGADE Concept
--
-- A BRIGADE consists of one or multiple PLATOONs. These platoons "live" in a WAREHOUSE that has a phyiscal struction (STATIC or UNIT) and can be captured or destroyed.
--
--
-- @field #BRIGADE
BRIGADE = {
  ClassName       = "BRIGADE",
  verbose         =     0,
  rearmingZones   =    {},
  refuellingZones =    {}, 
}

--- Supply Zone.
-- @type BRIGADE.SupplyZone
-- @field Core.Zone#ZONE zone The zone.
-- @field Ops.Auftrag#AUFTRAG mission Mission assigned to supply ammo or fuel.
-- @field #boolean markerOn If `true`, marker is on.
-- @field Wrapper.Marker#MARKER marker F10 marker.

--- BRIGADE class version.
-- @field #string version
BRIGADE.version="0.1.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ToDo list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Spawn when hosting warehouse is a ship or oil rig or gas platform.
-- TODO: Rearming zones.
-- TODO: Retreat zones.
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

--- Define a set of retreat zones.
-- @param #BRIGADE self
-- @param Core.Set#SET_ZONE RetreatZoneSet Set of retreat zones.
-- @return #BRIGADE self
function BRIGADE:SetRetreatZones(RetreatZoneSet)
  self.retreatZones=RetreatZoneSet or SET_ZONE:New()
  return self
end

--- Add a retreat zone.
-- @param #BRIGADE self
-- @param Core.Zone#ZONE RetreatZone Retreat zone.
-- @return #BRIGADE self
function BRIGADE:AddRetreatZone(RetreatZone)
  self.retreatZones:AddZone(RetreatZone)
  return self
end

--- Get retreat zones.
-- @param #BRIGADE self
-- @return Core.Set#SET_ZONE Set of retreat zones.
function BRIGADE:GetRetreatZones()
  return self.retreatZones
end

--- Add a rearming zone.
-- @param #BRIGADE self
-- @param Core.Zone#ZONE RearmingZone Rearming zone.
-- @return #BRIGADE.SupplyZone The rearming zone data.
function BRIGADE:AddRearmingZone(RearmingZone)

  local rearmingzone={} --#BRIGADE.SupplyZone
  
  rearmingzone.zone=RearmingZone
  rearmingzone.mission=nil
  rearmingzone.marker=MARKER:New(rearmingzone.zone:GetCoordinate(), "Rearming Zone"):ToCoalition(self:GetCoalition())

  table.insert(self.rearmingZones, rearmingzone)

  return rearmingzone
end


--- Add a refuelling zone.
-- @param #BRIGADE self
-- @param Core.Zone#ZONE RefuellingZone Refuelling zone.
-- @return #BRIGADE.SupplyZone The refuelling zone data.
function BRIGADE:AddRefuellingZone(RefuellingZone)

  local supplyzone={} --#BRIGADE.SupplyZone
  
  supplyzone.zone=RefuellingZone
  supplyzone.mission=nil
  supplyzone.marker=MARKER:New(supplyzone.zone:GetCoordinate(), "Refuelling Zone"):ToCoalition(self:GetCoalition())

  table.insert(self.refuellingZones, supplyzone)

  return supplyzone
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


--- [ GROUND ] Function to load back an asset in the field that has been filed before.
-- @param #BRIGADE self
-- @param #string Templatename e.g."1 PzDv LogRg I\_AID-976" - that's the alias (name) of an platoon spawned as `"platoon - alias"_AID-"asset-ID"`
-- @param Core.Point#COORDINATE Position where to spawn the platoon
-- @return #BRIGADE self
-- @usage
-- Prerequisites:
-- Save the assets spawned by BRIGADE/CHIEF regularly (~every 5 mins) into a file, e.g. like this: 
--   
--              local Path = FilePath or "C:\\Users\\<yourname>\\Saved Games\\DCS\\Missions\\" -- example path
--              local BlueOpsFilename = BlueFileName or "ExamplePlatoonSave.csv" -- example filename 
--              local BlueSaveOps = SET_OPSGROUP:New():FilterCoalitions("blue"):FilterCategoryGround():FilterOnce()
--              UTILS.SaveSetOfOpsGroups(BlueSaveOps,Path,BlueOpsFilename)
--          
-- where Path and Filename are strings, as chosen by you.
-- You can then load back the assets at the start of your next mission run. Be aware that it takes a couple of seconds for the 
-- platoon data to arrive in brigade, so make this an action after ~20 seconds, e.g. like so:
-- 
--            function LoadBackAssets()
--              local Path = FilePath or "C:\\Users\\<yourname>\\Saved Games\\DCS\\Missions\\" -- example path
--              local BlueOpsFilename = BlueFileName or "ExamplePlatoonSave.csv" -- example filename  
--              if UTILS.CheckFileExists(Path,BlueOpsFilename) then
--                local loadback = UTILS.LoadSetOfOpsGroups(Path,BlueOpsFilename,false)
--                for _,_platoondata in pairs (loadback) do
--                  local groupname = _platoondata.groupname -- #string
--                  local coordinate = _platoondata.coordinate -- Core.Point#COORDINATE
--                  Your_Brigade:LoadBackAssetInPosition(groupname,coordinate)
--                end
--              end
--            end
--  
--            local AssetLoader = TIMER:New(LoadBackAssets)
--            AssetLoader:Start(20)
-- 
-- The assets loaded back into the mission will be considered for AUFTRAG type missions from CHIEF and BRIGADE.
function BRIGADE:LoadBackAssetInPosition(Templatename,Position)
  self:T(self.lid .. "LoadBackAssetInPosition: " .. tostring(Templatename))
  
  -- get Platoon alias from Templatename
  local nametbl = UTILS.Split(Templatename,"_")

  local name = nametbl[1]
  
  self:T(string.format("*** Target Platoon = %s ***",name))
  
  -- find a matching asset table from BRIGADE
  local cohorts = self.cohorts or {}
  local thisasset = nil --Functional.Warehouse#WAREHOUSE.Assetitem
  local found = false
  
  for _,_cohort in pairs(cohorts) do
    local asset = _cohort:GetName()
    self:T(string.format("*** Looking at Platoon = %s ***",asset))
    if asset == name then
      self:T("**** Found Platoon ****")
      local cohassets = _cohort.assets or {}
      for _,_zug in pairs (cohassets) do
        local zug = _zug -- Functional.Warehouse#WAREHOUSE.Assetitem   
        if zug.assignment == name and zug.requested == false then
          self:T("**** Found Asset ****")
          found = true
          thisasset = zug --Functional.Warehouse#WAREHOUSE.Assetitem         
        break
        end
      end
    end
  end
  
  if found then
  
    -- prep asset
    thisasset.rid = thisasset.uid
    thisasset.requested = false
    thisasset.score=100
    thisasset.missionTask="CAS"
    thisasset.spawned = true
    local template = thisasset.templatename
    local alias = thisasset.spawngroupname
            
    -- Spawn group
    local spawnasset = SPAWN:NewWithAlias(template,alias)
      :InitDelayOff()
      :SpawnFromCoordinate(Position)
    
    -- build a new self request
    local request = {} --Functional.Warehouse#WAREHOUSE.Pendingitem
    request.assignment = name
    request.warehouse = self
    request.assets = {thisasset}
    request.ntransporthome = 0
    request.ndelivered = 0
    request.ntransport = 0
    request.cargoattribute = thisasset.attribute
    request.category = thisasset.category
    request.cargoassets = {thisasset}
    request.assetdesc = WAREHOUSE.Descriptor.ASSETLIST
    request.cargocategory = thisasset.category
    request.toself = true
    request.transporttype = WAREHOUSE.TransportType.SELFPROPELLED
    request.assetproblem = {}
    request.born = true
    request.prio = 50
    request.uid = thisasset.uid
    request.airbase = nil
    request.timestamp = timer.getAbsTime()
    request.assetdescval = {thisasset}
    request.nasset = 1
    request.cargogroupset = SET_GROUP:New()
    request.cargogroupset:AddGroup(spawnasset)
    request.iscargo = true
    
    -- Call Brigade self
    self:__AssetSpawned(2, spawnasset, thisasset, request) 
     
  end
  return self
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
  
  ----------------
  -- Transport ---
  ----------------
  
  self:CheckTransportQueue()

  --------------
  -- Mission ---
  --------------

  -- Check if any missions should be cancelled.
  self:CheckMissionQueue()

  ---------------------
  -- Rearming Zones ---
  ---------------------

  for _,_rearmingzone in pairs(self.rearmingZones) do
    local rearmingzone=_rearmingzone --#BRIGADE.SupplyZone
    if (not rearmingzone.mission) or rearmingzone.mission:IsOver() then
      rearmingzone.mission=AUFTRAG:NewAMMOSUPPLY(rearmingzone.zone)
      self:AddMission(rearmingzone.mission)
    end
  end

  -----------------------
  -- Refuelling Zones ---
  -----------------------

  -- Check refuelling zones.
  for _,_supplyzone in pairs(self.refuellingZones) do
    local supplyzone=_supplyzone --#BRIGADE.SupplyZone
    -- Check if mission is nil or over.      
    if (not supplyzone.mission) or supplyzone.mission:IsOver() then
      supplyzone.mission=AUFTRAG:NewFUELSUPPLY(supplyzone.zone)
      self:AddMission(supplyzone.mission)
    end
  end    


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

  -------------------
  -- Rearming Info --
  -------------------
  if self.verbose>=4 then
    local text="Rearming Zones:"
    for i,_rearmingzone in pairs(self.rearmingZones) do
      local rearmingzone=_rearmingzone --#BRIGADE.SupplyZone
      -- Info text.
      text=text..string.format("\n* %s: Mission status=%s, suppliers=%d", rearmingzone.zone:GetName(), rearmingzone.mission:GetState(), rearmingzone.mission:CountOpsGroups())      
    end
    self:I(self.lid..text)
  end
  
  ---------------------
  -- Refuelling Info --
  ---------------------
  if self.verbose>=4 then
    local text="Refuelling Zones:"
    for i,_refuellingzone in pairs(self.refuellingZones) do
      local refuellingzone=_refuellingzone --#BRIGADE.SupplyZone
      -- Info text.
      text=text..string.format("\n* %s: Mission status=%s, suppliers=%d", refuellingzone.zone:GetName(), refuellingzone.mission:GetState(), refuellingzone.mission:CountOpsGroups())      
    end
    self:I(self.lid..text)
  end
  
  ----------------
  -- Asset Info --
  ----------------
  if self.verbose>=5 then
    local text="Assets in stock:"
    for i,_asset in pairs(self.stock) do
      local asset=_asset --Functional.Warehouse#WAREHOUSE.Assetitem
      -- Info text.
      text=text..string.format("\n* %s: spawned=%s", asset.spawngroupname, tostring(asset.spawned))      
    end
    self:I(self.lid..text)
  end

  if self.verbose>=3 then
  
    -- Count numbers
    local Ntotal=0
    local Nspawned=0
    local Nrequested=0
    local Nreserved=0
    local Nstock=0
    
    local text="\n===========================================\n"
    text=text.."Assets:"
    local legion=self --Ops.Legion#LEGION

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
