--- **Ops** - Commander of Airwings, Brigades and Flotillas.
--
-- **Main Features:**
--
--    * Manages AIRWINGS, BRIGADEs and FLOTILLAs
--    * Handles missions (AUFTRAG) and finds the best man for the job 
--
-- ===
--
-- ### Author: **funkyfranky**
-- @module Ops.Commander
-- @image OPS_Commander.png


--- COMMANDER class.
-- @type COMMANDER
-- @field #string ClassName Name of the class.
-- @field #number verbose Verbosity level.
-- @field #string lid Class id string for output to DCS log file.
-- @field #table legions Table of legions which are commanded.
-- @field #table missionqueue Mission queue.
-- @field Ops.ChiefOfStaff#CHIEF chief Chief of staff.
-- @extends Core.Fsm#FSM

--- Be surprised!
--
-- ===
--
-- # The COMMANDER Concept
-- 
-- A commander is the head of legions. He/she will find the best LEGIONs to perform an assigned AUFTRAG (mission).
--
--
-- @field #COMMANDER
COMMANDER = {
  ClassName      = "COMMANDER",
  verbose        =     0,
  legions        =    {},
  missionqueue   =    {},
}

--- COMMANDER class version.
-- @field #string version
COMMANDER.version="0.1.0"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Improve legion selection. Mostly done!
-- TODO: Allow multiple Legions for one mission.
-- TODO: Add ops transports.
-- TODO: Find solution for missions, which require a transport. This is not as easy as it sounds since the selected mission assets restrict the possible transport assets.
-- NOGO: Maybe it's possible to preselect the assets for the mission.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new COMMANDER object and start the FSM.
-- @param #COMMANDER self
-- @return #COMMANDER self
function COMMANDER:New()

  -- Inherit everything from INTEL class.
  local self=BASE:Inherit(self, FSM:New()) --#COMMANDER
  
  -- Log ID.
  self.lid="COMMANDER | "

  -- Start state.
  self:SetStartState("NotReadyYet")

  -- Add FSM transitions.
  --                 From State     -->      Event        -->     To State
  self:AddTransition("NotReadyYet",        "Start",               "OnDuty")      -- Start COMMANDER.
  self:AddTransition("*",                  "Status",              "*")           -- Status report.
  self:AddTransition("*",                  "Stop",                "Stopped")     -- Stop COMMANDER.
  
  self:AddTransition("*",                  "MissionAssign",       "*")           -- Mission is assigned to a or multiple LEGIONs.
  self:AddTransition("*",                  "MissionCancel",       "*")           -- COMMANDER cancels a mission.

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


  --- Triggers the FSM event "MissionAssign".
  -- @function [parent=#COMMANDER] MissionAssign
  -- @param #COMMANDER self
  -- @param Ops.Legion#LEGION Legion The Legion.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.

  --- Triggers the FSM event "MissionAssign" after a delay.
  -- @function [parent=#COMMANDER] __MissionAssign
  -- @param #COMMANDER self
  -- @param #number delay Delay in seconds.
  -- @param Ops.Legion#LEGION Legion The Legion.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.

  --- On after "MissionAssign" event.
  -- @function [parent=#COMMANDER] OnAfterMissionAssign
  -- @param #COMMANDER self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.Legion#LEGION Legion The Legion.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.


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

--- Add an AIRWING to the commander.
-- @param #COMMANDER self
-- @param Ops.AirWing#AIRWING Airwing The airwing to add.
-- @return #COMMANDER self
function COMMANDER:AddAirwing(Airwing)

  -- Add legion.
  self:AddLegion(Airwing)
  
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

--- Add mission to mission queue.
-- @param #COMMANDER self
-- @param Ops.Auftrag#AUFTRAG Mission Mission to be added.
-- @return #COMMANDER self
function COMMANDER:AddMission(Mission)

  Mission.commander=self
  
  Mission.statusCommander=AUFTRAG.Status.PLANNED

  table.insert(self.missionqueue, Mission)

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
      self:I(self.lid..string.format("Removing mission %s (%s) status=%s from queue", Mission.name, Mission.type, Mission.status))
      mission.commander=nil
      table.remove(self.missionqueue, i)
      break
    end
    
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
    local text=string.format("Status %s: Legions=%d, Missions=%d", fsmstate, #self.legions, #self.missionqueue)
    self:I(self.lid..text)
  end

  -- Check mission queue and assign one PLANNED mission.
  self:CheckMissionQueue()
    
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
    self:I(self.lid..text)
    
    
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
            
            -- Text.
            text=text..string.format("\n- %s [UID=%d] Legion=%s, Cohort=%s: Spawned=%s, Requested=%s [RID=%s], Reserved=%s", 
            asset.spawngroupname, asset.uid, legion.alias, cohort.name, tostring(asset.spawned), tostring(asset.requested), tostring(asset.rid), tostring(asset.isReserved))
            
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

  self:__Status(-30)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Events
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after "MissionAssign" event. Mission is added to a LEGION mission queue.
-- @param #COMMANDER self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.Legion#LEGION Legion The LEGION.
-- @param Ops.Auftrag#AUFTRAG Mission The mission.
function COMMANDER:onafterMissionAssign(From, Event, To, Legion, Mission)

  -- Debug info.
  self:I(self.lid..string.format("Assigning mission %s (%s) to legion %s", Mission.name, Mission.type, Legion.alias))
  
  -- Set mission commander status to QUEUED as it is now queued at a legion.
  Mission.statusCommander=AUFTRAG.Status.QUEUED
  
  -- Add mission to legion.
  Legion:AddMission(Mission)
  
  -- Directly request the mission as the assets have already been selected.
  Legion:MissionRequest(Mission)

end

--- On after "MissionCancel" event.
-- @param #COMMANDER self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.Auftrag#AUFTRAG Mission The mission.
function COMMANDER:onafterMissionCancel(From, Event, To, Mission)

  -- Debug info.
  self:I(self.lid..string.format("Cancelling mission %s (%s) in status %s", Mission.name, Mission.type, Mission.status))
  
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

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Resources
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Check mission queue and assign ONE planned mission.
-- @param #COMMANDER self 
function COMMANDER:CheckMissionQueue()

  -- TODO: Sort mission queue. wrt what? Threat level?
  --       Currently, we sort wrt to priority. So that should reflect the threat level of the mission target.

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

  -- Get the lowest importance value (lower means more important).
  -- If a mission with importance 1 exists, mission with importance 2 will not be assigned. Missions with no importance (nil) can still be selected. 
  local vip=math.huge
  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG
    if mission.importance and mission.importance<vip then
      vip=mission.importance
    end
  end

  -- Loop over missions in queue.
  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG
    
    -- We look for PLANNED missions.
    if mission:IsPlanned() and mission:IsReadyToGo() and (mission.importance==nil or mission.importance<=vip) then
    
      ---
      -- PLANNNED Mission
      -- 
      -- 1. Select best assets from legions
      -- 2. Assign mission to legions that have the best assets.
      ---    
    
      -- Recruite assets from legions.      
      local recruited, legions=self:RecruitAssets(mission)
      
      if recruited then

        for _,_legion in pairs(legions) do
          local legion=_legion --Ops.Legion#LEGION
          
          -- Debug message.
          self:I(self.lid..string.format("Assigning mission %s [%s] to legion %s", mission:GetName(), mission:GetType(), legion.alias))
      
          -- Add mission to legion.
          self:MissionAssign(legion, mission)
          
        end
    
        -- Only ONE mission is assigned.
        return        
      end
      
    else

      ---
      -- Missions NOT in PLANNED state
      ---    
    
    end
  
  end
  
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
        self:I(self.lid..string.format("Got legion %s with Nassets=%d and dist=%.1f NM, rounded=%.1f", legion.alias, Nassets, distance, dist))
      
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

--- Recruit assets for a given mission.
-- @param #COMMANDER self
-- @param Ops.Auftrag#AUFTRAG Mission The mission.
-- @return #boolean If `true` enough assets could be recruited.
-- @return #table Legions that have recruited assets.
function COMMANDER:RecruitAssets(Mission)
  
  -- The recruited assets.
  local Assets={}
  
  -- Legions we consider for selecting assets.
  local legions=Mission.mylegions or self.legions
  
  -- Legions which have the best assets for the Mission.
  local Legions={}
  
  for _,_legion in pairs(legions) do
    local legion=_legion --Ops.Legion#LEGION

    -- Number of payloads in stock per aircraft type.
    local Npayloads={}
    
    -- First get payloads for aircraft types of squadrons.
    for _,_cohort in pairs(legion.cohorts) do
      local cohort=_cohort --Ops.Cohort#COHORT
      if Npayloads[cohort.aircrafttype]==nil then    
        Npayloads[cohort.aircrafttype]=legion:IsAirwing() and legion:CountPayloadsInStock(Mission.type, cohort.aircrafttype, Mission.payloads) or 999
        self:I(self.lid..string.format("Got Npayloads=%d for type=%s", Npayloads[cohort.aircrafttype], cohort.aircrafttype))
      end
    end
    
    -- Loops over cohorts.
    for _,_cohort in pairs(legion.cohorts) do
      local cohort=_cohort --Ops.Cohort#COHORT
      
      local npayloads=Npayloads[cohort.aircrafttype]
      
      if cohort:CanMission(Mission) and npayloads>0 then
      
        -- Recruit assets from squadron.
        local assets, npayloads=cohort:RecruitAssets(Mission, npayloads)
        
        Npayloads[cohort.aircrafttype]=npayloads
        
        for _,asset in pairs(assets) do
          table.insert(Assets, asset)
        end
        
      end
      
    end
    
  end
  
  -- Now we have a long list with assets.
  self:_OptimizeAssetSelection(Assets, Mission, false)
    
  for _,_asset in pairs(Assets) do
    local asset=_asset --Functional.Warehouse#WAREHOUSE.Assetitem
    
    if asset.legion:IsAirwing() then
     
      -- Only assets that have no payload. Should be only spawned assets!
      if not asset.payload then
      
        -- Fetch payload for asset. This can be nil!
        asset.payload=asset.legion:FetchPayloadFromStock(asset.unittype, Mission.type, Mission.payloads)
                
      end
      
    end
    
  end
  
  -- Remove assets that dont have a payload.
  for i=#Assets,1,-1 do
    local asset=Assets[i] --Functional.Warehouse#WAREHOUSE.Assetitem
    if asset.legion:IsAirwing() and not asset.payload then
      table.remove(Assets, i)
    end
  end
  
  -- Now find the best asset for the given payloads.
  self:_OptimizeAssetSelection(Assets, Mission, true)    
  
  local Nassets=Mission:GetRequiredAssets(self)
  
  if #Assets>=Nassets then
  
    ---
    -- Found enough assets
    ---
  
    -- Add assets to mission.
    for i=1,Nassets do
      local asset=Assets[i] --Functional.Warehouse#WAREHOUSE.Assetitem
      self:T(self.lid..string.format("Adding asset %s to mission %s [%s]", asset.spawngroupname, Mission.name, Mission.type))
      Mission:AddAsset(asset)
      Legions[asset.legion.alias]=asset.legion
    end
    
    
    -- Return payloads of not needed assets.
    for i=Nassets+1,#Assets do
      local asset=Assets[i] --Functional.Warehouse#WAREHOUSE.Assetitem
      if asset.legion:IsAirwing() and not asset.spawned then
        self:T(self.lid..string.format("Returning payload from asset %s", asset.spawngroupname))
        asset.legion:ReturnPayloadFromAsset(asset)
      end
    end
    
    -- Found enough assets.
    return true, Legions
  else

    ---
    -- NOT enough assets
    ---
  
    -- Return payloads of assets.
    if self:IsAirwing() then    
      for i=1,#Assets do
        local asset=Assets[i] --Functional.Warehouse#WAREHOUSE.Assetitem
        if asset.legion:IsAirwing() and not asset.spawned then
          self:T2(self.lid..string.format("Returning payload from asset %s", asset.spawngroupname))
          asset.legion:ReturnPayloadFromAsset(asset)
        end
      end      
    end
      
    -- Not enough assets found.
    return false, {}
  end

  return nil, {}
end

--- Optimize chosen assets for the mission at hand.
-- @param #COMMANDER self
-- @param #table assets Table of (unoptimized) assets.
-- @param Ops.Auftrag#AUFTRAG Mission Mission for which the best assets are desired.
-- @param #boolean includePayload If true, include the payload in the calulation if the asset has one attached.
function COMMANDER:_OptimizeAssetSelection(assets, Mission, includePayload)

  -- Get target position.
  local TargetVec2=Mission:GetTargetVec2()

  -- Calculate distance to mission target.
  local distmin=math.huge
  local distmax=0
  for _,_asset in pairs(assets) do
    local asset=_asset --Functional.Warehouse#WAREHOUSE.Assetitem

    if asset.spawned then
      local group=GROUP:FindByName(asset.spawngroupname)
      asset.dist=UTILS.VecDist2D(group:GetVec2(), TargetVec2)
    else
      asset.dist=UTILS.VecDist2D(asset.legion:GetVec2(), TargetVec2)
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
    local asset=_asset --Functional.Warehouse#WAREHOUSE.Assetitem
    asset.score=asset.legion:CalculateAssetMissionScore(asset, Mission, includePayload)
  end

  --- Sort assets wrt to their mission score. Higher is better.
  local function optimize(a, b)
    local assetA=a --Functional.Warehouse#WAREHOUSE.Assetitem
    local assetB=b --Functional.Warehouse#WAREHOUSE.Assetitem

    -- Higher score wins. If equal score ==> closer wins.
    -- TODO: Need to include the distance in a smarter way!
    return (assetA.score>assetB.score) or (assetA.score==assetB.score and assetA.dist<assetB.dist)
  end
  table.sort(assets, optimize)

  -- Remove distance parameter.
  local text=string.format("Optimized %d assets for %s mission (payload=%s):", #assets, Mission.type, tostring(includePayload))
  for i,Asset in pairs(assets) do
    local asset=Asset --Functional.Warehouse#WAREHOUSE.Assetitem
    text=text..string.format("\n%s %s: score=%d, distance=%.1f km", asset.squadname, asset.spawngroupname, asset.score, asset.dist/1000)
    asset.dist=nil
    asset.score=nil
  end
  self:T2(self.lid..text)

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------