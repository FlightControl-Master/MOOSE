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
      ---
    
      ---
      -- 1. Select best assets from legions
      ---    
    
      -- Get legions for mission.
      local legions=self:GetLegionsForMission(mission)
      
      -- Get ALL assets from pre-selected legions.
      local assets=self:GetAssets(InStock, legions, MissionTypes, Attributes)
      
      -- Now we select the best assets from all legions.
      legions={}
      if #assets>=mission.nassets then
      
        for _,_asset in pairs(assets) do
          local asset=_asset --Functional.Warehouse#WAREHOUSE.Assetitem
          asset.payload=asset.legion:FetchPayloadFromStock(asset.unittype, mission.type, mission.payloads)
          asset.score=asset.legion:CalculateAssetMissionScore(asset, mission, true)
        end
        
        --- Sort assets wrt to their mission score. Higher is better.
        local function optimize(assetA, assetB)
          return (assetA.score>assetB.score)
        end        
        table.sort(assets, optimize)

        -- Remove distance parameter.
        local text=string.format("Optimized assets for %s mission:", mission.type)
        for i,Asset in pairs(assets) do
          local asset=Asset --Functional.Warehouse#WAREHOUSE.Assetitem
          
          -- Score text.
          text=text..string.format("\n%s %s: score=%d", asset.squadname, asset.spawngroupname, asset.score)
          
          -- Nillify score.
          asset.score=nil
          
          -- Add assets to mission.
          if i<=mission.nassets then
          
            -- Add asset to mission.
            mission:AddAsset(Asset)
            
            -- Put into table.
            legions[asset.legion.alias]=asset.legion
            
            -- Number of assets requested from this legion.
            -- TODO: Check if this is really necessary as we do not go through the selection process.
            mission.Nassets=mission.Nassets or {}
            if mission.Nassets[asset.legion.alias] then
              mission.Nassets[asset.legion.alias]=mission.Nassets[asset.legion.alias]+1
            else
              mission.Nassets[asset.legion.alias]=1
            end 
            
          else
          
            -- Return payload of asset (if any).
            if asset.payload then
              asset.legion:ReturnPayloadFromAsset(asset)
            end
          
          end
        end
        self:T2(self.lid..text)
      
      else  
        self:T2(self.lid..string.format("Not enough assets available for mission"))
      end
      
      ---
      -- Assign Mission to Legions
      ---
      
      if legions then
      
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

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------