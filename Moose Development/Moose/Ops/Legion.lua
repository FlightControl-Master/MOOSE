--- **Ops** - Legion Warehouse.
--
-- Parent class of Airwings, Brigades and Fleets.
--
-- ===
--
-- ### Author: **funkyfranky**
-- 
-- ===
-- @module Ops.Legion
-- @image OPS_Legion.png


--- LEGION class.
-- @type LEGION
-- @field #string ClassName Name of the class.
-- @field #number verbose Verbosity of output.
-- @field #string lid Class id string for output to DCS log file.
-- @field #table missionqueue Mission queue table.
-- @field #table transportqueue Transport queue.
-- @field #table cohorts Cohorts of this legion.
-- @field Ops.Commander#COMMANDER commander Commander of this legion.
-- @field Ops.Chief#CHIEF chief Chief of this legion.
-- @field #boolean tacview If `true`, show tactical overview on status update.
-- @extends Functional.Warehouse#WAREHOUSE

--- *Per aspera ad astra.*
--
-- ===
--
-- # The LEGION Concept
-- 
-- The LEGION class contains all functions that are common for the AIRWING, BRIGADE and FLEET classes, which inherit the LEGION class.
-- 
-- An LEGION consists of multiple COHORTs. These cohorts "live" in a WAREHOUSE, i.e. a physical structure that can be destroyed or captured.
-- 
-- ** The LEGION class is not meant to be used directly. Use AIRWING, BRIGADE or FLEET instead! **
--
-- @field #LEGION
LEGION = {
  ClassName      = "LEGION",
  verbose        =     0,
  lid            =   nil,
  missionqueue   =    {},
  transportqueue =    {},
  cohorts        =    {},
}

--- Random score that is added to the asset score in the selection process.
-- @field #number RandomAssetScore
LEGION.RandomAssetScore=1


--- LEGION class version.
-- @field #string version
LEGION.version="0.5.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ToDo list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- DONE: Create FLEED class.
-- DONE: Relocate cohorts.
-- DONE: Aircraft will not start hot on Alert5.
-- DONE: OPS transport.
-- DONE: Make general so it can be inherited by AIRWING and BRIGADE classes.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new LEGION class object.
-- @param #LEGION self
-- @param #string WarehouseName Name of the warehouse STATIC or UNIT object representing the warehouse.
-- @param #string LegionName Name of the legion. Must be **unique**!
-- @return #LEGION self
function LEGION:New(WarehouseName, LegionName)

  -- Inherit everything from WAREHOUSE class.
  local self=BASE:Inherit(self, WAREHOUSE:New(WarehouseName, LegionName)) -- #LEGION

  -- Nil check.
  if not self then
    BASE:E(string.format("ERROR: Could not find warehouse %s!", WarehouseName))
    return nil
  end

  -- Set some string id for output to DCS.log file.
  self.lid=string.format("LEGION %s | ", self.alias)
  
  -- Defaults:
  self:SetMarker(false)
  
  -- Dead and crash events are handled via opsgroups.
  self:UnHandleEvent(EVENTS.Crash)
  self:UnHandleEvent(EVENTS.Dead)

  -- Add FSM transitions.
  --                 From State  -->   Event        -->      To State
  self:AddTransition("*",             "MissionRequest",      "*")           -- Add a (mission) request to the warehouse.
  self:AddTransition("*",             "MissionCancel",       "*")           -- Cancel mission.
  self:AddTransition("*",             "MissionAssign",       "*")           -- Recruit assets, add to queue and request immediately.
  
  self:AddTransition("*",             "TransportRequest",    "*")           -- Add a (mission) request to the warehouse.
  self:AddTransition("*",             "TransportCancel",     "*")           -- Cancel transport.
  self:AddTransition("*",             "TransportAssign",     "*")           -- Recruit assets, add to queue and request immediately.  
  
  self:AddTransition("*",             "OpsOnMission",        "*")           -- An OPSGROUP was send on a Mission (AUFTRAG).
  
  self:AddTransition("*",             "LegionAssetReturned", "*")           -- An asset returned (from a mission) to the Legion warehouse.
  
  ------------------------
  --- Pseudo Functions ---
  ------------------------

  --- Triggers the FSM event "Start". Starts the LEGION. Initializes parameters and starts event handlers.
  -- @function [parent=#LEGION] Start
  -- @param #LEGION self

  --- Triggers the FSM event "Start" after a delay. Starts the LEGION. Initializes parameters and starts event handlers.
  -- @function [parent=#LEGION] __Start
  -- @param #LEGION self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Stop". Stops the LEGION and all its event handlers.
  -- @param #LEGION self

  --- Triggers the FSM event "Stop" after a delay. Stops the LEGION and all its event handlers.
  -- @function [parent=#LEGION] __Stop
  -- @param #LEGION self
  -- @param #number delay Delay in seconds.


  --- Triggers the FSM event "MissionCancel".
  -- @function [parent=#LEGION] MissionCancel
  -- @param #LEGION self
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.


  --- Triggers the FSM event "MissionAssign".
  -- @function [parent=#LEGION] MissionAssign
  -- @param #LEGION self
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.
  -- @param #table Legions The legion(s) from which the mission assets are requested.

  --- Triggers the FSM event "MissionAssign" after a delay.
  -- @function [parent=#LEGION] __MissionAssign
  -- @param #LEGION self
  -- @param #number delay Delay in seconds.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.
  -- @param #table Legions The legion(s) from which the mission assets are requested.

  --- On after "MissionAssign" event.
  -- @function [parent=#LEGION] OnAfterMissionAssign
  -- @param #LEGION self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.
  -- @param #table Legions The legion(s) from which the mission assets are requested.


  --- Triggers the FSM event "MissionRequest".
  -- @function [parent=#LEGION] MissionRequest
  -- @param #LEGION self
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.
  -- @param #table Assets (Optional) Assets to add.

  --- Triggers the FSM event "MissionRequest" after a delay.
  -- @function [parent=#LEGION] __MissionRequest
  -- @param #LEGION self
  -- @param #number delay Delay in seconds.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.
  -- @param #table Assets (Optional) Assets to add.

  --- On after "MissionRequest" event.
  -- @function [parent=#LEGION] OnAfterMissionRequest
  -- @param #LEGION self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.
  -- @param #table Assets (Optional) Assets to add.


  --- Triggers the FSM event "MissionCancel" after a delay.
  -- @function [parent=#LEGION] __MissionCancel
  -- @param #LEGION self
  -- @param #number delay Delay in seconds.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.

  --- On after "MissionCancel" event.
  -- @function [parent=#LEGION] OnAfterMissionCancel
  -- @param #LEGION self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.


  --- Triggers the FSM event "TransportAssign".
  -- @function [parent=#LEGION] TransportAssign
  -- @param #LEGION self
  -- @param Ops.OpsTransport#OPSTRANSPORT Transport The transport.
  -- @param #table Legions The legion(s) to which this transport is assigned.

  --- Triggers the FSM event "TransportAssign" after a delay.
  -- @function [parent=#LEGION] __TransportAssign
  -- @param #LEGION self
  -- @param #number delay Delay in seconds.
  -- @param Ops.OpsTransport#OPSTRANSPORT Transport The transport.
  -- @param #table Legions The legion(s) to which this transport is assigned.

  --- On after "TransportAssign" event.
  -- @function [parent=#LEGION] OnAfterTransportAssign
  -- @param #LEGION self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.OpsTransport#OPSTRANSPORT Transport The transport.
  -- @param #table Legions The legion(s) to which this transport is assigned.


  --- Triggers the FSM event "TransportRequest".
  -- @function [parent=#LEGION] TransportRequest
  -- @param #LEGION self
  -- @param Ops.OpsTransport#OPSTRANSPORT Transport The transport.

  --- Triggers the FSM event "TransportRequest" after a delay.
  -- @function [parent=#LEGION] __TransportRequest
  -- @param #LEGION self
  -- @param #number delay Delay in seconds.
  -- @param Ops.OpsTransport#OPSTRANSPORT Transport The transport.

  --- On after "TransportRequest" event.
  -- @function [parent=#LEGION] OnAfterTransportRequest
  -- @param #LEGION self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.OpsTransport#OPSTRANSPORT Transport The transport.


  --- Triggers the FSM event "TransportCancel".
  -- @function [parent=#LEGION] TransportCancel
  -- @param #LEGION self
  -- @param Ops.OpsTransport#OPSTRANSPORT Transport The transport.

  --- Triggers the FSM event "TransportCancel" after a delay.
  -- @function [parent=#LEGION] __TransportCancel
  -- @param #LEGION self
  -- @param #number delay Delay in seconds.
  -- @param Ops.OpsTransport#OPSTRANSPORT Transport The transport.

  --- On after "TransportCancel" event.
  -- @function [parent=#LEGION] OnAfterTransportCancel
  -- @param #LEGION self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.OpsTransport#OPSTRANSPORT Transport The transport.


  --- Triggers the FSM event "OpsOnMission".
  -- @function [parent=#LEGION] OpsOnMission
  -- @param #LEGION self
  -- @param Ops.OpsGroup#OPSGROUP OpsGroup The OPS group on mission.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.

  --- Triggers the FSM event "OpsOnMission" after a delay.
  -- @function [parent=#LEGION] __OpsOnMission
  -- @param #LEGION self
  -- @param #number delay Delay in seconds.
  -- @param Ops.OpsGroup#OPSGROUP OpsGroup The OPS group on mission.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.

  --- On after "OpsOnMission" event.
  -- @function [parent=#LEGION] OnAfterOpsOnMission
  -- @param #LEGION self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.OpsGroup#OPSGROUP OpsGroup The OPS group on mission.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.


  --- Triggers the FSM event "LegionAssetReturned".
  -- @function [parent=#LEGION] LegionAssetReturned
  -- @param #LEGION self
  -- @param Ops.Cohort#COHORT Cohort The cohort the asset belongs to.
  -- @param Functional.Warehouse#WAREHOUSE.Assetitem Asset The asset that returned.

  --- Triggers the FSM event "LegionAssetReturned" after a delay.
  -- @function [parent=#LEGION] __LegionAssetReturned
  -- @param #LEGION self
  -- @param #number delay Delay in seconds. 
  -- @param Ops.Cohort#COHORT Cohort The cohort the asset belongs to.
  -- @param Functional.Warehouse#WAREHOUSE.Assetitem Asset The asset that returned.

  --- On after "LegionAssetReturned" event. Triggered when an asset group returned to its Legion.
  -- @function [parent=#LEGION] OnAfterLegionAssetReturned
  -- @param #LEGION self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.Cohort#COHORT Cohort The cohort the asset belongs to.
  -- @param Functional.Warehouse#WAREHOUSE.Assetitem Asset The asset that returned.


  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set verbosity level.
-- @param #LEGION self
-- @param #number VerbosityLevel Level of output (higher=more). Default 0.
-- @return #LEGION self
function LEGION:SetVerbosity(VerbosityLevel)
  self.verbose=VerbosityLevel or 0
  return self
end

--- Set tactical overview on.
-- @param #LEGION self
-- @return #LEGION self
function LEGION:SetTacticalOverviewOn()  
  self.tacview=true
  return self
end

--- Add a mission for the legion. It will pick the best available assets for the mission and lauch it when ready. 
-- @param #LEGION self
-- @param Ops.Auftrag#AUFTRAG Mission Mission for this legion.
-- @return #LEGION self
function LEGION:AddMission(Mission)

  -- Set status to QUEUED. This event is only allowed for the first legion that calls it.
  Mission:Queued()
  
  -- Set legion status.
  Mission:SetLegionStatus(self, AUFTRAG.Status.QUEUED)
  
  -- Add legion to mission.
  Mission:AddLegion(self)
  
  -- Set target for ALERT 5.
  if Mission.type==AUFTRAG.Type.ALERT5 then
    Mission:_TargetFromObject(self:GetCoordinate())
  end

  -- Add mission to queue.
  table.insert(self.missionqueue, Mission)

  -- Info text.
  local text=string.format("Added mission %s (type=%s). Starting at %s. Stopping at %s",
  tostring(Mission.name), tostring(Mission.type), UTILS.SecondsToClock(Mission.Tstart, true), Mission.Tstop and UTILS.SecondsToClock(Mission.Tstop, true) or "INF")
  self:T(self.lid..text)

  return self
end

--- Remove mission from queue.
-- @param #LEGION self
-- @param Ops.Auftrag#AUFTRAG Mission Mission to be removed.
-- @return #LEGION self
function LEGION:RemoveMission(Mission)

  for i,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG

    if mission.auftragsnummer==Mission.auftragsnummer then
      mission:RemoveLegion(self)
      table.remove(self.missionqueue, i)
      break
    end

  end

  return self
end

--- Add transport assignment to queue. 
-- @param #LEGION self
-- @param Ops.OpsTransport#OPSTRANSPORT OpsTransport Transport assignment.
-- @return #LEGION self
function LEGION:AddOpsTransport(OpsTransport)

  -- Is not queued at a legion.
  OpsTransport:Queued()
  
  -- Set legion status.
  OpsTransport:SetLegionStatus(self, AUFTRAG.Status.QUEUED)  

  -- Add mission to queue.
  table.insert(self.transportqueue, OpsTransport)
  
  -- Add this legion to the transport.
  OpsTransport:AddLegion(self)

  -- Info text.
  local text=string.format("Added Transport %s. Starting at %s-%s",
  tostring(OpsTransport.uid), UTILS.SecondsToClock(OpsTransport.Tstart, true), OpsTransport.Tstop and UTILS.SecondsToClock(OpsTransport.Tstop, true) or "INF")
  self:T(self.lid..text)

  return self
end

--- Add cohort to cohort table of this legion.
-- @param #LEGION self
-- @param Ops.Cohort#COHORT Cohort The cohort to be added.
-- @return #LEGION self
function LEGION:AddCohort(Cohort)
  
  if self:IsCohort(Cohort.name) then
  
    self:E(self.lid..string.format("ERROR: A cohort with name %s already exists in this legion. Cohorts must have UNIQUE names!"))
  
  else
  
    -- Add cohort to legion.
    table.insert(self.cohorts, Cohort)
    
  end

  return self
end

--- Remove cohort from cohor table of this legion.
-- @param #LEGION self
-- @param Ops.Cohort#COHORT Cohort The cohort to be added.
-- @return #LEGION self
function LEGION:DelCohort(Cohort)

  for i=#self.cohorts,1,-1 do
    local cohort=self.cohorts[i] --Ops.Cohort#COHORT
    if cohort.name==Cohort.name then
      self:T(self.lid..string.format("Removing Cohort %s", tostring(cohort.name)))
      table.remove(self.cohorts, i)
    end
  end

  return self
end

--- Remove specific asset from legion.
-- @param #LEGION self
-- @param Functional.Warehouse#WAREHOUSE.Assetitem Asset The asset.
-- @return #LEGION self
function LEGION:DelAsset(Asset)

  if Asset.cohort then
    Asset.cohort:DelAsset(Asset)
  else
    self:E(self.lid..string.format("ERROR: Asset has not cohort attached. Cannot remove it from legion!"))
  end
  
  return self
end


--- Relocate a cohort to another legion.
-- Assets in stock are spawned and routed to the new legion.
-- If assets are spawned, running missions will be cancelled.
-- Cohort assets will not be available until relocation is finished.
-- @param #LEGION self
-- @param Ops.Cohort#COHORT Cohort The cohort to be relocated.
-- @param Ops.Legion#LEGION Legion The legion where the cohort is relocated to.
-- @param #number Delay Delay in seconds before relocation takes place. Default `nil`, *i.e.* ASAP.
-- @param #number NcarriersMin Min number of transport carriers in case the troops should be transported. Default `nil` for no transport.
-- @param #number NcarriersMax Max number of transport carriers.
-- @param #table TransportLegions Legion(s) assigned for transportation. Default is that transport assets can only be recruited from this legion.
-- @return #LEGION self
function LEGION:RelocateCohort(Cohort, Legion, Delay, NcarriersMin, NcarriersMax, TransportLegions)

  if Delay and Delay>0 then
    self:ScheduleOnce(Delay, LEGION.RelocateCohort, self, Cohort, Legion, 0, NcarriersMin, NcarriersMax, TransportLegions)
  else
  
    -- Add cohort to legion.
    if Legion:IsCohort(Cohort.name) then
      self:E(self.lid..string.format("ERROR: Cohort %s is already part of new legion %s ==> CANNOT Relocate!", Cohort.name, Legion.alias))
      return self
    else
      table.insert(Legion.cohorts, Cohort)      
    end
    
    -- Check that cohort is part of this legion
    if not self:IsCohort(Cohort.name) then
      self:E(self.lid..string.format("ERROR: Cohort %s is NOT part of this legion %s ==> CANNOT Relocate!", Cohort.name, self.alias))
      return self    
    end
    
    -- Check that legions are different.
    if self.alias==Legion.alias then
      self:E(self.lid..string.format("ERROR: old legion %s is same as new legion %s ==> CANNOT Relocate!", self.alias, Legion.alias))
      return self    
    end
    
    -- Trigger Relocate event.
    Cohort:Relocate()
    
    -- Create a relocation mission.
    local mission=AUFTRAG:_NewRELOCATECOHORT(Legion, Cohort)
    
    if false then
      --- Disabled for now.
    
      -- Add assets to mission.
      mission:_AddAssets(Cohort.assets)
  
      -- Debug info.
      self:I(self.lid..string.format("Relocating Cohort %s [nassets=%d] to legion %s", Cohort.name, #Cohort.assets, Legion.alias))
      
      -- Assign mission to this legion.
      self:MissionAssign(mission, {self})
    
    else
    
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
      end
      
      -- Set mission range very large. Mission designer should know...
      mission:SetMissionRange(10000)
      
      -- Add mission.
      self:AddMission(mission)
    end
      
  end

  return self
end

--- Get cohort by name.
-- @param #LEGION self
-- @param #string CohortName Name of the platoon.
-- @return Ops.Cohort#COHORT The Cohort object.
function LEGION:_GetCohort(CohortName)

  for _,_cohort in pairs(self.cohorts) do
    local cohort=_cohort --Ops.Cohort#COHORT

    if cohort.name==CohortName then
      return cohort
    end

  end

  return nil
end

--- Check if cohort is part of this legion.
-- @param #LEGION self
-- @param #string CohortName Name of the platoon.
-- @return #boolean If `true`, cohort is part of this legion.
function LEGION:IsCohort(CohortName)

  for _,_cohort in pairs(self.cohorts) do
    local cohort=_cohort --Ops.Cohort#COHORT

    if cohort.name==CohortName then
      return true
    end

  end

  return false
end

--- Get name of legion. This is the alias of the warehouse.
-- @param #LEGION self
-- @return #string Name of legion.
function LEGION:GetName()
  return self.alias
end

--- Get cohort of an asset.
-- @param #LEGION self
-- @param Functional.Warehouse#WAREHOUSE.Assetitem Asset The asset.
-- @return Ops.Cohort#COHORT The Cohort object.
function LEGION:_GetCohortOfAsset(Asset)
  local cohort=self:_GetCohort(Asset.squadname)
  return cohort
end


--- Check if a BRIGADE class is calling.
-- @param #LEGION self
-- @return #boolean If true, this is a BRIGADE.
function LEGION:IsBrigade()
  local is=self.ClassName==BRIGADE.ClassName
  return is
end

--- Check if the AIRWING class is calling.
-- @param #LEGION self
-- @return #boolean If true, this is an AIRWING.
function LEGION:IsAirwing()
  local is=self.ClassName==AIRWING.ClassName
  return is
end

--- Check if the FLEET class is calling.
-- @param #LEGION self
-- @return #boolean If true, this is a FLEET.
function LEGION:IsFleet()
  local is=self.ClassName==FLEET.ClassName
  return is
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Start & Status
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Start LEGION FSM.
-- @param #LEGION self
function LEGION:onafterStart(From, Event, To)

  -- Start parent Warehouse.
  self:GetParent(self, LEGION).onafterStart(self, From, Event, To)

  -- Info.
  self:T3(self.lid..string.format("Starting LEGION v%s", LEGION.version))

end

--- Check mission queue and assign ONE mission.
-- @param #LEGION self
-- @return #boolean If `true`, a mission was found and requested.
function LEGION:CheckMissionQueue()

  -- Number of missions.
  local Nmissions=#self.missionqueue

  -- Treat special cases.
  if Nmissions==0 then
    return nil
  end

  -- Loop over missions in queue.
  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG

    if mission:IsNotOver() and mission:IsReadyToCancel() then
      mission:Cancel()
    end
    
    -- Housekeeping
    local TNow = timer.getTime()
    if mission:IsOver() and mission:IsNotRepeatable() and mission.DeletionTimstamp == nil then
      mission.DeletionTimstamp = TNow
    end
    if mission.DeletionTimstamp ~= nil and TNow - mission.DeletionTimstamp > 1800 then
      mission = nil
    end
  end
  
  -- Check that runway is operational and that carrier is not recovering.
  if self:IsAirwing() then
    if self:IsRunwayOperational()==false then
      return nil
    end
    local airboss=self.airboss --Ops.Airboss#AIRBOSS
    if airboss then
      if not airboss:IsIdle() then
        return nil
      end
    end
  end

  -- Sort results table wrt prio and start time.
  local function _sort(a, b)
    local taskA=a --Ops.Auftrag#AUFTRAG
    local taskB=b --Ops.Auftrag#AUFTRAG
    return (taskA.prio<taskB.prio) or (taskA.prio==taskB.prio and taskA.Tstart<taskB.Tstart)
  end
  table.sort(self.missionqueue, _sort)

  -- Search min importance.
  local vip=math.huge
  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG
    if mission.importance and mission.importance<vip then
      vip=mission.importance
    end
  end

  -- Look for first task that is not accomplished.
  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG
    
    -- Check if reinforcement is necessary.
    local reinforce=false
    if mission:IsExecuting() and mission.reinforce and mission.reinforce>0 then
    
      -- Number of current opsgroups.
      local N=mission.Nassigned-mission.Ndead
      
      if N<mission.NassetsMin then
        reinforce=true
      end
      
      -- Debug info.
      self:T(self.lid..string.format("Checking Reinforcement Nreinf=%d, Nops=%d, Nassigned=%d, Ndead=%d, Nmin=%d ==> Reinforce=%s", 
      mission.reinforce, N, mission.Nassigned, mission.Ndead, mission.NassetsMin, tostring(reinforce)))
    end

    -- Firstly, check if mission is due?
    if (mission:IsQueued(self) or reinforce) and mission:IsReadyToGo() and (mission.importance==nil or mission.importance<=vip) then

      -- Recruit best assets for the job.    
      local recruited, assets, legions=self:RecruitAssetsForMission(mission)

      -- Did we find enough assets?
      if recruited then
    
        -- Add to mission.
        --mission:_AddAssets(assets)
  
        -- Recruit asset for escorting recruited mission assets.
        local EscortAvail=self:RecruitAssetsForEscort(mission, assets)

        -- Transport available (or not required).
        local TransportAvail=true
        
        -- Is escort required and available?
        if EscortAvail then
        
          -- Recruit carrier assets for transport.
          local Transport=nil
          if mission.NcarriersMin then
          
            -- Transport legions.
            local Legions=mission.transportLegions or {self}
                        
            -- Assign carrier assets for transport.
            TransportAvail, Transport=self:AssignAssetsForTransport(Legions, assets, mission.NcarriersMin, mission.NcarriersMax, mission.transportDeployZone, mission.transportDisembarkZone, mission.carrierCategories, mission.carrierAttributes, mission.carrierProperties)
          end
          
          -- Add opstransport to mission.
          if TransportAvail and Transport then
            mission.opstransport=Transport
          end
          
        end
        
        if EscortAvail and TransportAvail then
        
          -- Got a mission.
          self:MissionRequest(mission, assets)
          
          -- Reduce number of reinforcements.
          if reinforce then
            mission.reinforce=mission.reinforce-#assets
            self:T(self.lid..string.format("Reinforced with N=%d Nreinforce=%d", #assets, mission.reinforce))
          end
          
          return true
        else
          -- Recruited assets but no requested escort available. Unrecruit assets!
          LEGION.UnRecruitAssets(assets, mission)
        end
        
      end -- recruited mission assets

    end -- mission due?
  end -- mission loop

  return nil
end

--- Check transport queue and assign ONE transport.
-- @param #LEGION self
-- @return #boolean If `true`, a transport was found and requested.
function LEGION:CheckTransportQueue()

  -- Number of missions.
  local Ntransports=#self.transportqueue

  -- Treat special cases.
  if Ntransports==0 then
    return nil
  end
  
  -- TODO: Remove transports that are over!
  
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
  
  -- Look for first task that is not accomplished.
  for _,_transport in pairs(self.transportqueue) do
    local transport=_transport --Ops.OpsTransport#OPSTRANSPORT

    -- Check if transport is still queued and ready.
    if transport:IsQueued(self) and transport:IsReadyToGo() and (transport.importance==nil or transport.importance<=vip) then
    
      -- Recruit assets for transport.
      local recruited, assets, _=self:RecruitAssetsForTransport(transport)
      
      -- Did we find enough assets?
      if recruited then
      
        -- Add asset to transport.
        for _,_asset in pairs(assets) do
          local asset=_asset --Functional.Warehouse#WAREHOUSE.Assetitem
          transport:AddAsset(asset)
        end
        
        -- Got transport ==> Request and return.
        self:TransportRequest(transport)
        return true
      end
      
    end
  end
  
  -- No transport found.
  return nil
end



-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Events
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after "MissionAssign" event. Mission is added to a LEGION mission queue and already requested. Needs assets to be added to the mission already.
-- @param #LEGION self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.Auftrag#AUFTRAG Mission The mission.
-- @param #table Legions The LEGIONs.
function LEGION:onafterMissionAssign(From, Event, To, Mission, Legions)
  
  for _,_Legion in pairs(Legions) do
    local Legion=_Legion --Ops.Legion#LEGION

    -- Debug info.
    self:T(self.lid..string.format("Assigning mission %s (%s) to legion %s", Mission.name, Mission.type, Legion.alias))
 
    -- Add mission to legion.
    Legion:AddMission(Mission)
    
    -- Directly request the mission as the assets have already been selected.
    Legion:MissionRequest(Mission)
    
  end

end

--- Create a request and add it to the warehouse queue.
-- @param #LEGION self
-- @param Functional.Warehouse#WAREHOUSE.Descriptor AssetDescriptor Descriptor describing the asset that is requested.
-- @param AssetDescriptorValue Value of the asset descriptor. Type depends on descriptor, i.e. could be a string, etc.
-- @param #number nAsset Number of groups requested that match the asset specification.
-- @param #number Prio Priority of the request. Number ranging from 1=high to 100=low.
-- @param #string Assignment A keyword or text that can later be used to identify this request and postprocess the assets.
-- @return Functional.Warehouse#WAREHOUSE.Queueitem The request.
function LEGION:_AddRequest(AssetDescriptor, AssetDescriptorValue, nAsset, Prio, Assignment)

  -- Defaults.
  nAsset=nAsset or 1
  Prio=Prio or 50

  -- Increase id.
  self.queueid=self.queueid+1

  -- Request queue table item.
  local request={
  uid=self.queueid,
  prio=Prio,
  warehouse=self,
  assetdesc=AssetDescriptor,
  assetdescval=AssetDescriptorValue,
  nasset=nAsset,
  transporttype=WAREHOUSE.TransportType.SELFPROPELLED,
  ntransport=0,
  assignment=tostring(Assignment),
  airbase=self:GetAirbase(),
  category=self:GetAirbaseCategory(),
  ndelivered=0,
  ntransporthome=0,
  assets={},
  toself=true,
  } --Functional.Warehouse#WAREHOUSE.Queueitem
  

  -- Add request to queue.
  table.insert(self.queue, request)
  
  local descval="assetlist"
  if request.assetdesc==WAREHOUSE.Descriptor.ASSETLIST then
  
  else
    descval=tostring(request.assetdescval)
  end

  local text=string.format("Warehouse %s: New request from warehouse %s.\nDescriptor %s=%s, #assets=%s; Transport=%s, #transports=%s.",
  self.alias, self.alias, request.assetdesc, descval, tostring(request.nasset), request.transporttype, tostring(request.ntransport))
  self:_DebugMessage(text, 5)

  return request
end


--- On after "MissionRequest" event. Performs a self request to the warehouse for the mission assets. Sets mission status to REQUESTED.
-- @param #LEGION self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.Auftrag#AUFTRAG Mission The requested mission.
-- @param #table Assets (Optional) Assets to add.
function LEGION:onafterMissionRequest(From, Event, To, Mission, Assets)

  -- Debug info.
  self:T(self.lid..string.format("MissionRequest for mission %s [%s]", Mission:GetName(), Mission:GetType()))
  
  -- Take provided assets or that of the mission.
  Assets=Assets or Mission.assets

  -- Set mission status from QUEUED to REQUESTED.
  Mission:Requested()
  
  -- Set legion status. Ensures that it is not considered in the next selection.
  Mission:SetLegionStatus(self, AUFTRAG.Status.REQUESTED)

  ---
  -- Some assets might already be spawned and even on a different mission (orbit).
  -- Need to dived to set into spawned and instock assets and handle the other
  ---

  -- Assets to be requested.
  local Assetlist={}

  for _,_asset in pairs(Assets) do
    local asset=_asset --Functional.Warehouse#WAREHOUSE.Assetitem

    -- Check that this asset belongs to this Legion warehouse.
    if asset.wid==self.uid then

      if asset.spawned then
      
        ---
        -- Spawned Assets
        ---
  
        if asset.flightgroup and not asset.flightgroup:IsMissionInQueue(Mission) then
          
          -- Add new mission.
          asset.flightgroup:AddMission(Mission)
          
          ---
          -- Special Missions
          ---
          
          -- Get current mission.
          local currM=asset.flightgroup:GetMissionCurrent()
                              
          if currM then
          
            -- Cancel?
            local cancel=false
            -- Pause?
            local pause=false
          
            -- Check if mission is INTERCEPT and asset is currently on GCI mission. If so, GCI is paused.
            if (currM.type==AUFTRAG.Type.GCICAP or currM.type==AUFTRAG.Type.PATROLRACETRACK) and Mission.type==AUFTRAG.Type.INTERCEPT then
              pause=true
            elseif (currM.type==AUFTRAG.Type.ONGUARD or currM.type==AUFTRAG.Type.PATROLZONE) and (Mission.type==AUFTRAG.Type.ARTY or Mission.type==AUFTRAG.Type.GROUNDATTACK) then
              pause=true
            elseif currM.type==AUFTRAG.Type.NOTHING then
              pause=true
            end
            
            -- Cancel current ALERT5 mission.
            if currM.type==AUFTRAG.Type.ALERT5 then
              cancel=true
            end
                        
            -- Cancel current mission for relcation.
            if Mission.type==AUFTRAG.Type.RELOCATECOHORT then
              cancel=true
              
              -- Get request.
              local request=currM:_GetRequest(self)
              
              if request then
                self:T2(self.lid.."Removing group from cargoset")
                request.cargogroupset:Remove(asset.spawngroupname, true)
              else
                self:E(self.lid.."ERROR: no request for spawned asset!")
              end              
              
            end
            
            -- Cancel mission.
            if cancel then
              self:T(self.lid..string.format("Cancel current mission %s [%s] to send group on mission %s [%s]", currM.name, currM.type, Mission.name, Mission.type))
              asset.flightgroup:MissionCancel(currM)
            elseif pause then
              self:T(self.lid..string.format("Pausing current mission %s [%s] to send group on mission %s [%s]", currM.name, currM.type, Mission.name, Mission.type))
              asset.flightgroup:PauseMission()
            end
            
            -- Not reserved any more.
            asset.isReserved=false
          
          end
          
          -- Add asset to mission.
          Mission:AddAsset(asset)
          
          -- Trigger event.
          self:__OpsOnMission(2, asset.flightgroup, Mission)
  
        else
          self:T(self.lid.."ERROR: OPSGROUP for asset does NOT exist but it seems to be SPAWNED (asset.spawned=true)!")
        end
  
      else

        ---
        -- Stock Assets
        ---      
      
        -- These assets need to be requested and spawned.
        table.insert(Assetlist, asset)
        
      end
      
    end
  end

  -- Add request to legion warehouse.
  if #Assetlist>0 then

    --local text=string.format("Requesting assets for mission %s:", Mission.name)
    for i,_asset in pairs(Assetlist) do
      local asset=_asset --Functional.Warehouse#WAREHOUSE.Assetitem

      -- Set asset to requested! Important so that new requests do not use this asset!
      asset.requested=true
      
      -- Spawned asset are not requested.
      if asset.spawned then
        asset.requested=false
      end
      
      -- Not reserved and more.
      asset.isReserved=false

      -- Set mission task so that the group is spawned with the right one.
      if Mission.missionTask then
        asset.missionTask=Mission.missionTask
      end
      
      -- Set takeoff type to parking for ALERT5 missions. We dont want them to take off without a proper mission if squadron start is hot.
      if Mission.type==AUFTRAG.Type.ALERT5 then
        asset.takeoffType=COORDINATE.WaypointType.TakeOffParking
      end
      
      -- Add asset to mission.
      Mission:AddAsset(asset)

    end
    
    -- Set assignment.
    -- TODO: Get/set functions for assignment string.
    local assignment=string.format("Mission-%d", Mission.auftragsnummer)
    
    --local request=Mission:_GetRequest(self)

    -- Add request to legion warehouse.
    --self:AddRequest(self, WAREHOUSE.Descriptor.ASSETLIST, Assetlist, #Assetlist, nil, nil, Mission.prio, assignment)
    local request=self:_AddRequest(WAREHOUSE.Descriptor.ASSETLIST, Assetlist, #Assetlist, Mission.prio, assignment)
    
    -- Debug Info.
    self:T(self.lid..string.format("Added request=%d for Nasssets=%d", request.uid, #Assetlist))

    -- The queueid has been increased in the onafterAddRequest function. So we can simply use it here.
    --Mission.requestID[self.alias]=self.queueid
    Mission:_SetRequestID(self, self.queueid)
    
    -- Get request.
    --local request=self:GetRequestByID(self.queueid)
    
    -- Debug info.
    self:T(self.lid..string.format("Mission %s [%s] got Request ID=%d", Mission:GetName(), Mission:GetType(), self.queueid))
    
    -- Request ship.
    if request then
      if self:IsShip() then
        self:T(self.lid.."Warehouse physical structure is SHIP. Requestes assets will be late activated!")
        request.lateActivation=true
      end
    end    
    
  end

end

--- On after "TransportAssign" event. Transport is added to a LEGION transport queue and assets are requested from the LEGION warehouse.
-- @param #LEGION self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.OpsTransport#OPSTRANSPORT Transport The transport.
-- @param #table Legions The legion(s) to which the transport is assigned.
function LEGION:onafterTransportAssign(From, Event, To, Transport, Legions)

  for _,_Legion in pairs(Legions) do
    local Legion=_Legion --Ops.Legion#LEGION

    -- Debug info.
    self:T(self.lid..string.format("Assigning transport %d to legion %s", Transport.uid, Legion.alias))
      
    -- Add mission to legion.
    Legion:AddOpsTransport(Transport)
    
    -- Directly request the mission as the assets have already been selected.
    Legion:TransportRequest(Transport)

  end

end

--- On after "TransportRequest" event. Performs a self request to the warehouse for the transport assets. Sets transport status to REQUESTED.
-- @param #LEGION self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.OpsTransport#OPSTRANSPORT Opstransport The requested mission.
function LEGION:onafterTransportRequest(From, Event, To, OpsTransport)
  
  -- List of assets that will be requested.
  local AssetList={}
  
  --TODO: Find spawned assets on ALERT 5 mission OPSTRANSPORT.

  --local text=string.format("Requesting assets for mission %s:", Mission.name)
  for i,_asset in pairs(OpsTransport.assets) do
    local asset=_asset --Functional.Warehouse#WAREHOUSE.Assetitem
    
    -- Check that this asset belongs to this Legion warehouse.
    if asset.wid==self.uid then      

      -- Set asset to requested! Important so that new requests do not use this asset!
      asset.requested=true
      asset.isReserved=false

      -- Set transport mission task.
      asset.missionTask=ENUMS.MissionTask.TRANSPORT
      
      -- Add asset to list.
      table.insert(AssetList, asset)      
    end
  end
  
  if #AssetList>0 then

    -- Set mission status from QUEUED to REQUESTED.
    OpsTransport:Requested()
    
    -- Set legion status. Ensures that it is not considered in the next selection.
    OpsTransport:SetLegionStatus(self, OPSTRANSPORT.Status.REQUESTED)
    
    -- TODO: Get/set functions for assignment string.
    local assignment=string.format("Transport-%d", OpsTransport.uid)

    -- Add request to legion warehouse.
    --self:AddRequest(self, WAREHOUSE.Descriptor.ASSETLIST, AssetList, #AssetList, nil, nil, OpsTransport.prio, assignment)
    self:_AddRequest(WAREHOUSE.Descriptor.ASSETLIST, AssetList, #AssetList, OpsTransport.prio, assignment)

    -- The queueid has been increased in the onafterAddRequest function. So we can simply use it here.
    OpsTransport.requestID[self.alias]=self.queueid
  end

end

--- On after "TransportCancel" event.
-- @param #LEGION self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.OpsTransport#OPSTRANSPORT Transport The transport to be cancelled.
function LEGION:onafterTransportCancel(From, Event, To, Transport)

  -- Info message.
  self:T(self.lid..string.format("Cancel transport UID=%d", Transport.uid))

  -- Set status to cancelled.
  Transport:SetLegionStatus(self, OPSTRANSPORT.Status.CANCELLED)

  for i=#Transport.assets, 1, -1 do
    local asset=Transport.assets[i] --Functional.Warehouse#WAREHOUSE.Assetitem
    
    -- Asset should belong to this legion.
    if asset.wid==self.uid then

      local opsgroup=asset.flightgroup

      if opsgroup then
        opsgroup:TransportCancel(Transport)
      end
      
      -- Delete awaited transport.
      local cargos=Transport:GetCargoOpsGroups(false)
      for _,_cargo in pairs(cargos) do
        local cargo=_cargo --Ops.OpsGroup#OPSGROUP
        
        -- Remover my lift.
        cargo:_DelMyLift(Transport)
        
        -- Legion of cargo group
        local legion=cargo.legion
        
        -- Add asset back to legion.
        if legion then                  
          legion:T(self.lid..string.format("Adding cargo group %s back to legion", cargo:GetName()))
          legion:__AddAsset(0.1, cargo.group, 1)
        end
      end
      
      -- Remove asset from mission.
      Transport:DelAsset(asset)

      -- Not requested any more (if it was).
      asset.requested=nil
      asset.isReserved=nil
      
    end      
  end

  -- Remove queued request (if any).
  if Transport.requestID[self.alias] then
    self:_DeleteQueueItemByID(Transport.requestID[self.alias], self.queue)
  end

end


--- On after "MissionCancel" event. Cancels the missions of all flightgroups. Deletes request from warehouse queue.
-- @param #LEGION self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.Auftrag#AUFTRAG Mission The mission to be cancelled.
function LEGION:onafterMissionCancel(From, Event, To, Mission)

  -- Info message.
  self:T(self.lid..string.format("Cancel mission %s", Mission.name))

  -- Set status to cancelled.
  Mission:SetLegionStatus(self, AUFTRAG.Status.CANCELLED)

  for i=#Mission.assets, 1, -1 do
    local asset=Mission.assets[i] --Functional.Warehouse#WAREHOUSE.Assetitem
    
    -- Asset should belong to this legion.
    if asset.wid==self.uid then

      local opsgroup=asset.flightgroup

      if opsgroup then
        opsgroup:MissionCancel(Mission)
      end
      
      -- Remove asset from mission.
      Mission:DelAsset(asset)

      -- Not requested any more (if it was).
      asset.requested=nil
      asset.isReserved=nil
      
    end      
  end

  -- Remove queued request (if any).
  local requestID=Mission:_GetRequestID(self)
  if requestID then
    self:_DeleteQueueItemByID(requestID, self.queue)
  end

end

--- On after "OpsOnMission".
-- @param #LEGION self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.OpsGroup#OPSGROUP OpsGroup Ops group on mission
-- @param Ops.Auftrag#AUFTRAG Mission The requested mission.
function LEGION:onafterOpsOnMission(From, Event, To, OpsGroup, Mission)
  -- Debug info.
  self:T2(self.lid..string.format("Group %s on mission %s [%s]", OpsGroup:GetName(), Mission:GetName(), Mission:GetType()))

  if self:IsAirwing() then
    -- Trigger event for Airwings.
    self:FlightOnMission(OpsGroup, Mission)
  elseif self:IsBrigade() then
    -- Trigger event for Brigades.
    self:ArmyOnMission(OpsGroup, Mission)
  else
    -- Trigger event for Fleets.
    self:NavyOnMission(OpsGroup, Mission)
  end
  
  -- Load group as cargo because it cannot swim! We pause the mission.
  if self:IsBrigade() and self:IsShip() then
    OpsGroup:PauseMission()
    self.warehouseOpsGroup:Load(OpsGroup, self.warehouseOpsElement)
  end
  
  -- Trigger event for chief.
  if self.chief then
    self.chief:OpsOnMission(OpsGroup, Mission)
  end
  
  -- Trigger event for commander.
  if self.commander then
    self.commander:OpsOnMission(OpsGroup, Mission)
  end

end

--- On after "NewAsset" event. Asset is added to the given cohort (asset assignment).
-- @param #LEGION self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Functional.Warehouse#WAREHOUSE.Assetitem asset The asset that has just been added.
-- @param #string assignment The (optional) assignment for the asset.
function LEGION:onafterNewAsset(From, Event, To, asset, assignment)

  -- Call parent WAREHOUSE function first.
  self:GetParent(self, LEGION).onafterNewAsset(self, From, Event, To, asset, assignment)

  -- Debug text.
  local text=string.format("New asset %s with assignment %s and request assignment %s", asset.spawngroupname, tostring(asset.assignment), tostring(assignment))
  self:T(self.lid..text)

  -- Get cohort.
  local cohort=self:_GetCohort(asset.assignment)

  -- Check if asset is already part of the squadron. If an asset returns, it will be added again! We check that asset.assignment is also assignment.
  if cohort then

    if asset.assignment==assignment then
    
      ---
      -- Asset is added to the COHORT for the first time
      ---

      local nunits=#asset.template.units

      -- Debug text.
      local text=string.format("Adding asset to cohort %s: assignment=%s, type=%s, attribute=%s, nunits=%d ngroup=%s", cohort.name, assignment, asset.unittype, asset.attribute, nunits, tostring(cohort.ngrouping))
      self:T(self.lid..text)

      -- Adjust number of elements in the group.
      if cohort.ngrouping then
        local template=asset.template

        local N=math.max(#template.units, cohort.ngrouping)
        
        -- We need to recalc the total weight and cargo bay.
        asset.weight=0
        asset.cargobaytot=0

        -- Handle units.
        for i=1,N do

          -- Unit template.
          local unit = template.units[i]

          -- If grouping is larger than units present, copy first unit.
          if i>nunits then
            table.insert(template.units, UTILS.DeepCopy(template.units[1]))
            asset.cargobaytot=asset.cargobaytot+asset.cargobay[1]
            asset.weight=asset.weight+asset.weights[1]
            template.units[i].x=template.units[1].x+5*(i-nunits)
            template.units[i].y=template.units[1].y+5*(i-nunits)
          else
            if i<=cohort.ngrouping then
              asset.weight=asset.weight+asset.weights[i]
              asset.cargobaytot=asset.cargobaytot+asset.cargobay[i]
            end
          end

          -- Remove units if original template contains more than in grouping.
          if i>cohort.ngrouping then
            template.units[i]=nil
          end
        end

        -- Set number of units.
        asset.nunits=cohort.ngrouping
        
        -- Debug info.
        self:T(self.lid..string.format("After regrouping: Nunits=%d, weight=%.1f cargobaytot=%.1f kg", #asset.template.units, asset.weight, asset.cargobaytot))
      end

      -- Set takeoff type.
      asset.takeoffType=cohort.takeoffType~=nil and cohort.takeoffType or self.takeoffType
      
      -- Set parking IDs.
      asset.parkingIDs=cohort.parkingIDs

      -- Create callsign and modex (needs to be after grouping).
      cohort:GetCallsign(asset)
      cohort:GetModex(asset)

      -- Set spawn group name. This has to include "AID-" for warehouse.
      asset.spawngroupname=string.format("%s_AID-%d", cohort.name, asset.uid)

      -- Add asset to cohort.
      cohort:AddAsset(asset)

    else

      ---
      -- Asset is returned to the COHORT
      ---
      
      self:T(self.lid..string.format("Asset returned to legion ==> calling LegionAssetReturned event"))
      
      -- Set takeoff type in case it was overwritten for an ALERT5 mission.
      asset.takeoffType=cohort.takeoffType
      
      -- Trigger event.
      self:LegionAssetReturned(cohort, asset)

    end

  end
end

--- On after "LegionAssetReturned" event. Triggered when an asset group returned to its legion.
-- @param #LEGION self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.Cohort#COHORT Cohort The cohort the asset belongs to.
-- @param Functional.Warehouse#WAREHOUSE.Assetitem Asset The asset that returned.
function LEGION:onafterLegionAssetReturned(From, Event, To, Cohort, Asset)
  -- Debug message.
  self:T(self.lid..string.format("Asset %s from Cohort %s returned! asset.assignment=\"%s\"", Asset.spawngroupname, Cohort.name, tostring(Asset.assignment)))

  -- Stop flightgroup.
  if Asset.flightgroup and not Asset.flightgroup:IsStopped() then
    Asset.flightgroup:Stop()
  end

  -- Return payload.
  if Asset.flightgroup:IsFlightgroup() then
    self:ReturnPayloadFromAsset(Asset)
  end

  -- Return tacan channel.
  if Asset.tacan then
    Cohort:ReturnTacan(Asset.tacan)
  end

  -- Set timestamp.
  Asset.Treturned=timer.getAbsTime()
  
end


--- On after "AssetSpawned" event triggered when an asset group is spawned into the cruel world.
-- Creates a new flightgroup element and adds the mission to the flightgroup queue.
-- @param #LEGION self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Group#GROUP group The group spawned.
-- @param Functional.Warehouse#WAREHOUSE.Assetitem asset The asset that was spawned.
-- @param Functional.Warehouse#WAREHOUSE.Pendingitem request The request of the dead asset.
function LEGION:onafterAssetSpawned(From, Event, To, group, asset, request)
  self:T({From, Event, To, group:GetName(), asset.assignment, request.assignment})
  
  -- Call parent warehouse function first.
  self:GetParent(self, LEGION).onafterAssetSpawned(self, From, Event, To, group, asset, request)

  -- Get the COHORT of the asset.
  local cohort=self:_GetCohortOfAsset(asset)

  -- Check if we have a cohort or if this was some other request.
  if cohort then
  
    -- Debug info.
    self:T(self.lid..string.format("Cohort asset spawned %s", asset.spawngroupname))

    -- Create a flight group.
    local flightgroup=self:_CreateFlightGroup(asset)

    ---
    -- Asset
    ---

    -- Set asset flightgroup.
    asset.flightgroup=flightgroup

    -- Not requested any more.
    asset.requested=nil

    -- Did not return yet.
    asset.Treturned=nil


    ---
    -- Cohort
    ---

    -- Get TACAN channel.
    local Tacan=cohort:FetchTacan()
    if Tacan then
      asset.tacan=Tacan
      flightgroup:SwitchTACAN(Tacan, Morse, UnitName, Band)
    end

    -- Set radio frequency and modulation
    local radioFreq, radioModu=cohort:GetRadio()
    if radioFreq then
      flightgroup:SwitchRadio(radioFreq, radioModu)
    end

    if cohort.fuellow then
      flightgroup:SetFuelLowThreshold(cohort.fuellow)
    end

    if cohort.fuellowRefuel then
      flightgroup:SetFuelLowRefuel(cohort.fuellowRefuel)
    end
    
    -- Assignment.
    local assignment=request.assignment
    
    -- Set pathfinding for naval groups.
    if self:IsFleet() then
      flightgroup:SetPathfinding(self.pathfinding)
    end
    
    if string.find(assignment, "Mission-") then

      ---
      -- Mission
      ---
      
      local uid=UTILS.Split(assignment, "-")[2]
  
      -- Get Mission (if any).
      local mission=self:GetMissionByID(uid)
      
      local despawnLanding=cohort.despawnAfterLanding~=nil and cohort.despawnAfterLanding or self.despawnAfterLanding
      if despawnLanding then
        flightgroup:SetDespawnAfterLanding()
      end
      
      local despawnHolding=cohort.despawnAfterHolding~=nil and cohort.despawnAfterHolding or self.despawnAfterHolding
      if despawnHolding then
        flightgroup:SetDespawnAfterHolding()
      end      
  
      -- Add mission to flightgroup queue.
      if mission then
  
        if Tacan then
          --mission:SetTACAN(Tacan, Morse, UnitName, Band)
        end
        
        -- Add mission to flightgroup queue. If mission has an OPSTRANSPORT attached, all added OPSGROUPS are added as CARGO for a transport.
        flightgroup:AddMission(mission)
        
        -- RTZ on out of ammo.
        if self:IsBrigade() or self:IsFleet() then
          flightgroup:SetReturnOnOutOfAmmo()
        end
                  
        -- Trigger event.
        self:__OpsOnMission(5, flightgroup, mission)
  
      else
  
        if Tacan then
          --flightgroup:SwitchTACAN(Tacan, Morse, UnitName, Band)
        end
  
      end
  
      -- Add group to the detection set of the CHIEF (INTEL).
      local chief=self.chief or (self.commander and self.commander.chief or nil) --Ops.Chief#CHIEF
      if chief then
        self:T(self.lid..string.format("Adding group %s to agents of CHIEF", group:GetName()))
        chief.detectionset:AddGroup(asset.flightgroup.group)
      end
      
    elseif string.find(assignment, "Transport-") then
    
      ---
      -- Transport
      ---
      
      local uid=UTILS.Split(assignment, "-")[2] 

            -- Get Mission (if any).
      local transport=self:GetTransportByID(uid)
  
      -- Add mission to flightgroup queue.
      if transport then
        flightgroup:AddOpsTransport(transport)
      end
  
    end
    
  end
  
end

--- On after "AssetDead" event triggered when an asset group died.
-- @param #LEGION self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Functional.Warehouse#WAREHOUSE.Assetitem asset The asset that is dead.
-- @param Functional.Warehouse#WAREHOUSE.Pendingitem request The request of the dead asset.
function LEGION:onafterAssetDead(From, Event, To, asset, request)

  -- Call parent warehouse function first.
  self:GetParent(self, LEGION).onafterAssetDead(self, From, Event, To, asset, request)
  
  -- Remove group from the detection set of the CHIEF (INTEL).
  if self.commander and self.commander.chief then
    self.commander.chief.detectionset:RemoveGroupsByName({asset.spawngroupname})
  end
  
  -- Remove asset from cohort and legion.
  self:DelAsset(asset)

  -- Remove asset from mission is done via Mission:AssetDead() call from flightgroup onafterFlightDead function
  -- Remove asset from squadron same
end

--- On after "Destroyed" event. Remove assets from cohorts. Stop cohorts.
-- @param #LEGION self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function LEGION:onafterDestroyed(From, Event, To)

  -- Debug message.
  self:T(self.lid.."Legion warehouse destroyed!")

  -- Cancel all missions.
  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG
    mission:Cancel()
  end

  -- Remove all cohort assets.
  for _,_cohort in pairs(self.cohorts) do
    local cohort=_cohort --Ops.Cohort#COHORT
    -- Stop Cohort. This also removes all assets.
    cohort:Stop()
  end

  -- Call parent warehouse function first.
  self:GetParent(self, LEGION).onafterDestroyed(self, From, Event, To)

end


--- On after "Request" event.
-- @param #LEGION self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Functional.Warehouse#WAREHOUSE.Queueitem Request Information table of the request.
function LEGION:onafterRequest(From, Event, To, Request)

  if Request.toself then

    -- Assets
    local assets=Request.cargoassets
  
    -- Get Mission
    local Mission=self:GetMissionByID(Request.assignment)
  
    if Mission and assets then
  
      for _,_asset in pairs(assets) do
        local asset=_asset --Functional.Warehouse#WAREHOUSE.Assetitem
        -- This would be the place to modify the asset table before the asset is spawned.
      end
  
    end
    
  end

  -- Call parent warehouse function after assets have been adjusted.
  self:GetParent(self, LEGION).onafterRequest(self, From, Event, To, Request)

end

--- On after "SelfRequest" event.
-- @param #LEGION self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Set#SET_GROUP groupset The set of asset groups that was delivered to the warehouse itself.
-- @param Functional.Warehouse#WAREHOUSE.Pendingitem request Pending self request.
function LEGION:onafterSelfRequest(From, Event, To, groupset, request)

  -- Call parent warehouse function first.
  self:GetParent(self, LEGION).onafterSelfRequest(self, From, Event, To, groupset, request)

  -- Get Mission
  local mission=self:GetMissionByID(request.assignment)

  for _,_asset in pairs(request.assets) do
    local asset=_asset --Functional.Warehouse#WAREHOUSE.Assetitem
  end

  for _,_group in pairs(groupset:GetSet()) do
    local group=_group --Wrapper.Group#GROUP
  end

end

--- On after "RequestSpawned" event.
-- @param #LEGION self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Functional.Warehouse#WAREHOUSE.Pendingitem Request Information table of the request.
-- @param Core.Set#SET_GROUP CargoGroupSet Set of cargo groups.
-- @param Core.Set#SET_GROUP TransportGroupSet Set of transport groups if any.
function LEGION:onafterRequestSpawned(From, Event, To, Request, CargoGroupSet, TransportGroupSet)

  -- Call parent warehouse function.
  self:GetParent(self, LEGION).onafterRequestSpawned(self, From, Event, To, Request, CargoGroupSet, TransportGroupSet)

end

--- On after "Captured" event.
-- @param #LEGION self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param DCS#coalition.side Coalition which captured the warehouse.
-- @param DCS#country.id Country which has captured the warehouse.
function LEGION:onafterCaptured(From, Event, To, Coalition, Country)

  -- Call parent warehouse function.
  self:GetParent(self, LEGION).onafterCaptured(self, From, Event, To, Coalition, Country)
  
  
  if self.chief then
    -- Trigger event for chief and commander.
    self.chief.commander:LegionLost(self, Coalition, Country)
    self.chief:LegionLost(self, Coalition, Country)
    -- Remove legion from chief and commander.
    self.chief:RemoveLegion(self)    
  elseif self.commander then
    -- Trigger event.
    self.commander:LegionLost(self, Coalition,Country)
    -- Remove legion from commander.
    self.commander:RemoveLegion(self)
  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Mission Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new OPS group after an asset was spawned.
-- @param #LEGION self
-- @param Functional.Warehouse#WAREHOUSE.Assetitem asset The asset.
-- @return Ops.FlightGroup#FLIGHTGROUP The created flightgroup object.
function LEGION:_CreateFlightGroup(asset)

  -- Create flightgroup.
  local opsgroup=nil --Ops.OpsGroup#OPSGROUP  
  
  if self:IsAirwing() then
  
    ---
    -- FLIGHTGROUP
    ---
  
    opsgroup=FLIGHTGROUP:New(asset.spawngroupname)
    
  elseif self:IsBrigade() then
  
    ---
    -- ARMYGROUP
    ---  
  
    opsgroup=ARMYGROUP:New(asset.spawngroupname)
    opsgroup:SetValidateAndRepositionGroundUnits(self.ValidateAndRepositionGroundUnits)
    
  elseif self:IsFleet() then

    ---
    -- NAVYGROUP
    ---  
  
    opsgroup=NAVYGROUP:New(asset.spawngroupname)
    
  else
    self:E(self.lid.."ERROR: not airwing or brigade!")
  end

  -- Set legion.
  opsgroup:_SetLegion(self)

  -- Set cohort.
  opsgroup.cohort=self:_GetCohortOfAsset(asset)

  -- Set home base.
  opsgroup.homebase=self.airbase
  
  -- Set destination base
  opsgroup.destbase=self.airbase
  
  -- Set home zone.
  opsgroup.homezone=self.spawnzone  

  -- Set weapon data.
  if opsgroup.cohort.weaponData then
    local text="Weapon data for group:"
    opsgroup.weaponData=opsgroup.weaponData or {}
    for bittype,_weapondata in pairs(opsgroup.cohort.weaponData) do
      local weapondata=_weapondata --Ops.OpsGroup#OPSGROUP.WeaponData
      opsgroup.weaponData[bittype]=UTILS.DeepCopy(weapondata) -- Careful with the units.
      text=text..string.format("\n- Bit=%s: Rmin=%.1f km, Rmax=%.1f km", bittype, weapondata.RangeMin/1000, weapondata.RangeMax/1000)
    end
    self:T3(self.lid..text)
  end      

  return opsgroup
end

--- Display tactical overview.
-- @param #LEGION self 
function LEGION:_TacticalOverview()

  if self.tacview then

    local NassetsTotal=self:CountAssets(nil)
    local NassetsStock=self:CountAssets(true)
    local NassetsActiv=self:CountAssets(false)
  
    local NmissionsTotal=#self.missionqueue
    local NmissionsRunni=self:CountMissionsInQueue()
  
    -- Info message
    local text=string.format("Tactical Overview %s\n", self.alias)
    text=text..string.format("===================================\n")
  
    -- Asset info.
    text=text..string.format("Assets: %d [Active=%d, Stock=%d]\n", NassetsTotal, NassetsActiv, NassetsStock)
  
    -- Mission info.
    text=text..string.format("Missions: %d [Running=%d]\n", NmissionsTotal, NmissionsRunni)
    for _,mtype in pairs(AUFTRAG.Type) do
      local n=self:CountMissionsInQueue(mtype)
      if n>0 then
        local N=self:CountMissionsInQueue(mtype, true)
        text=text..string.format("  - %s: %d [Running=%d]\n", mtype, n, N)
      end
    end
  
    
    local Ntransports=#self.transportqueue
    if Ntransports>0 then
      text=text..string.format("Transports: %d\n", Ntransports)
      for _,_transport in pairs(self.transportqueue) do
        local transport=_transport --Ops.OpsTransport#OPSTRANSPORT
        text=text..string.format(" - %s", transport:GetState())
      end
    end
  
    -- Message to coalition.
    MESSAGE:New(text, 60, nil, true):ToCoalition(self:GetCoalition())  
  
    
  end
  
end

--- Check if an asset is currently on a mission (STARTED or EXECUTING).
-- @param #LEGION self
-- @param Functional.Warehouse#WAREHOUSE.Assetitem asset The asset.
-- @param #table MissionTypes Types on mission to be checked. Default all.
-- @return #boolean If true, asset has at least one mission of that type in the queue.
function LEGION:IsAssetOnMission(asset, MissionTypes)

  if MissionTypes then
    if type(MissionTypes)~="table" then
      MissionTypes={MissionTypes}
    end
  else
    -- Check all possible types.
    MissionTypes=AUFTRAG.Type
  end

  if asset.flightgroup and asset.flightgroup:IsAlive() then

    -- Loop over mission queue.
    for _,_mission in pairs(asset.flightgroup.missionqueue or {}) do
      local mission=_mission --Ops.Auftrag#AUFTRAG

      if mission:IsNotOver() then

        -- Get flight status.
        local status=mission:GetGroupStatus(asset.flightgroup)

        -- Only if mission is started or executing.
        if (status==AUFTRAG.GroupStatus.STARTED or status==AUFTRAG.GroupStatus.EXECUTING) and AUFTRAG.CheckMissionType(mission.type, MissionTypes) then
          return true
        end

      end

    end

  end
  
  return false
end

--- Get the current mission of the asset.
-- @param #LEGION self
-- @param Functional.Warehouse#WAREHOUSE.Assetitem asset The asset.
-- @return Ops.Auftrag#AUFTRAG Current mission or *nil*.
function LEGION:GetAssetCurrentMission(asset)

  if asset.flightgroup then
    return asset.flightgroup:GetMissionCurrent()
  end

  return nil
end

--- Count payloads in stock.
-- @param #LEGION self
-- @param #table MissionTypes Types on mission to be checked. Default *all* possible types `AUFTRAG.Type`.
-- @param #table UnitTypes Types of units.
-- @param #table Payloads Specific payloads to be counted only.
-- @return #number Count of available payloads in stock.
function LEGION:CountPayloadsInStock(MissionTypes, UnitTypes, Payloads)

  if MissionTypes then
    if type(MissionTypes)=="string" then
      MissionTypes={MissionTypes}
    end
  end

  if UnitTypes then
    if type(UnitTypes)=="string" then
      UnitTypes={UnitTypes}
    end
  end

  local function _checkUnitTypes(payload)
    if UnitTypes then
      for _,unittype in pairs(UnitTypes) do
        if unittype==payload.aircrafttype then
          return true
        end
      end
    else
      -- Unit type was not specified.
      return true
    end
    return false
  end

  local function _checkPayloads(payload)
    if Payloads then
      for _,Payload in pairs(Payloads) do
        if Payload.uid==payload.uid then
          return true
        end
      end
    else
      -- Payload was not specified.
      return nil
    end
    return false
  end

  local n=0
  for _,_payload in pairs(self.payloads or {}) do
    local payload=_payload --Ops.Airwing#AIRWING.Payload

    for _,MissionType in pairs(MissionTypes) do

      local specialpayload=_checkPayloads(payload)
      local compatible=AUFTRAG.CheckMissionCapability(MissionType, payload.capabilities)

      local goforit = specialpayload or (specialpayload==nil and compatible)

      if goforit and _checkUnitTypes(payload) then

        if payload.unlimited then
          -- Payload is unlimited. Return a BIG number.
          return 999
        else
          n=n+payload.navail
        end

      end

    end
  end

  return n
end

--- Count missions in mission queue.
-- @param #LEGION self
-- @param #table MissionTypes Types on mission to be checked. Default *all* possible types `AUFTRAG.Type`.
-- @param #boolean OnlyRunning If `true`, only count running missions.
-- @return #number Number of missions that are not over yet.
function LEGION:CountMissionsInQueue(MissionTypes, OnlyRunning)

  MissionTypes=MissionTypes or AUFTRAG.Type

  local N=0
  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG
    
    if (not OnlyRunning) or (mission.statusLegion~=AUFTRAG.Status.PLANNED) then

      -- Check if this mission type is requested.
      if mission:IsNotOver() and AUFTRAG.CheckMissionType(mission.type, MissionTypes) then
        N=N+1
      end
      
    end

  end

  return N
end

--- Count total number of assets of the legion.
-- @param #LEGION self
-- @param #boolean InStock If `true`, only assets that are in the warehouse stock/inventory are counted. If `false`, only assets that are NOT in stock (i.e. spawned) are counted. If `nil`, all assets are counted.
-- @param #table MissionTypes (Optional) Count only assest that can perform certain mission type(s). Default is all types.
-- @param #table Attributes (Optional) Count only assest that have a certain attribute(s), e.g. `GROUP.Attribute.AIR_BOMBER`.
-- @return #number Amount of asset groups in stock.
function LEGION:CountAssets(InStock, MissionTypes, Attributes)

  local N=0

  for _,_cohort in pairs(self.cohorts) do
    local cohort=_cohort --Ops.Cohort#COHORT
    N=N+cohort:CountAssets(InStock, MissionTypes, Attributes)
  end

  return N
end

--- Get OPSGROUPs that are spawned and alive.
-- @param #LEGION self
-- @param #table MissionTypes (Optional) Get only assest that can perform certain mission type(s). Default is all types.
-- @param #table Attributes (Optional) Get only assest that have a certain attribute(s), e.g. `WAREHOUSE.Attribute.AIR_BOMBER`.
-- @return Core.Set#SET_OPSGROUP The set of OPSGROUPs. Can be empty if no groups are spawned or alive!
function LEGION:GetOpsGroups(MissionTypes, Attributes)

  local setLegion=SET_OPSGROUP:New()

  for _,_cohort in pairs(self.cohorts) do
    local cohort=_cohort --Ops.Cohort#COHORT
    
    -- Get cohort set.
    local setCohort=cohort:GetOpsGroups(MissionTypes, Attributes)
    
    -- Debug info.
    self:T2(self.lid..string.format("Found %d opsgroups of cohort %s", setCohort:Count(), cohort.name))
    
    -- Add to legion set.
    setLegion:AddSet(setCohort)
  end

  return setLegion
end

--- Count total number of assets in LEGION warehouse stock that also have a payload.
-- @param #LEGION self
-- @param #boolean Payloads (Optional) Specifc payloads to consider. Default all.
-- @param #table MissionTypes (Optional) Count only assest that can perform certain mission type(s). Default is all types.
-- @param #table Attributes (Optional) Count only assest that have a certain attribute(s), e.g. `WAREHOUSE.Attribute.AIR_BOMBER`.
-- @return #number Amount of asset groups in stock.
function LEGION:CountAssetsWithPayloadsInStock(Payloads, MissionTypes, Attributes)

  -- Total number counted.
  local N=0
  
  -- Number of payloads in stock per aircraft type.
  local Npayloads={}
  
  -- First get payloads for aircraft types of squadrons.
  for _,_cohort in pairs(self.cohorts) do
    local cohort=_cohort --Ops.Cohort#COHORT
    if Npayloads[cohort.aircrafttype]==nil then    
      Npayloads[cohort.aircrafttype]=self:CountPayloadsInStock(MissionTypes, cohort.aircrafttype, Payloads)
      self:T3(self.lid..string.format("Got Npayloads=%d for type=%s",Npayloads[cohort.aircrafttype], cohort.aircrafttype))
    end
  end

  for _,_cohort in pairs(self.cohorts) do
    local cohort=_cohort --Ops.Cohort#COHORT
    
    -- Number of assets in stock.
    local n=cohort:CountAssets(true, MissionTypes, Attributes)
    
    -- Number of payloads.
    local p=Npayloads[cohort.aircrafttype] or 0
    
    -- Only the smaller number of assets or paylods is really available.        
    local m=math.min(n, p)
    
    -- Add up what we have. Could also be zero.
    N=N+m
    
    -- Reduce number of available payloads.
    Npayloads[cohort.aircrafttype]=Npayloads[cohort.aircrafttype]-m
  end

  return N
end

--- Count assets on mission.
-- @param #LEGION self
-- @param #table MissionTypes Types on mission to be checked. Default all.
-- @param Ops.Cohort#COHORT Cohort Only count assets of this cohort. Default count assets of all cohorts.
-- @return #number Number of pending and queued assets.
-- @return #number Number of pending assets.
-- @return #number Number of queued assets.
function LEGION:CountAssetsOnMission(MissionTypes, Cohort)

  local Nq=0
  local Np=0

  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG

    -- Check if this mission type is requested.
    if AUFTRAG.CheckMissionType(mission.type, MissionTypes or AUFTRAG.Type) then

      for _,_asset in pairs(mission.assets or {}) do
        local asset=_asset --Functional.Warehouse#WAREHOUSE.Assetitem
        
        -- Ensure asset belongs to this letion.
        if asset.wid==self.uid then

          if Cohort==nil or Cohort.name==asset.squadname then
  
            local request, isqueued=self:GetRequestByID(mission.requestID[self.alias])
  
            if isqueued then
              Nq=Nq+1
            else
              Np=Np+1
            end
  
          end
          
        end
      end
    end
  end

  return Np+Nq, Np, Nq
end

--- Get assets on mission.
-- @param #LEGION self
-- @param #table MissionTypes Types on mission to be checked. Default all.
-- @return #table Assets on pending requests.
function LEGION:GetAssetsOnMission(MissionTypes)

  local assets={}
  local Np=0

  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG

    -- Check if this mission type is requested.
    if AUFTRAG.CheckMissionType(mission.type, MissionTypes) then

      for _,_asset in pairs(mission.assets or {}) do
        local asset=_asset --Functional.Warehouse#WAREHOUSE.Assetitem
        
        -- Ensure asset belongs to this legion.
        if asset.wid==self.uid then

          table.insert(assets, asset)
          
        end

      end
    end
  end

  return assets
end

--- Get the unit types of this legion. These are the unit types of all assigned cohorts.
-- @param #LEGION self
-- @param #boolean onlyactive Count only the active ones.
-- @param #table cohorts Table of cohorts. Default all.
-- @return #table Table of unit types.
function LEGION:GetAircraftTypes(onlyactive, cohorts)

  -- Get all unit types that can do the job.
  local unittypes={}

  -- Loop over all cohorts.
  for _,_cohort in pairs(cohorts or self.cohorts) do
    local cohort=_cohort --Ops.Cohort#COHORT

    if (not onlyactive) or cohort:IsOnDuty() then

      local gotit=false
      for _,unittype in pairs(unittypes) do
        if cohort.aircrafttype==unittype then
          gotit=true
          break
        end
      end
      if not gotit then
        table.insert(unittypes, cohort.aircrafttype)
      end

    end
  end

  return unittypes
end

--- Count payloads of all cohorts for all unit types.
-- @param #LEGION self
-- @param #string MissionType Mission type.
-- @param #table Cohorts Cohorts included.
-- @param #table Payloads (Optional) Special payloads.
-- @return #table Table of payloads for each unit type.
function LEGION:_CountPayloads(MissionType, Cohorts, Payloads)

  -- Number of payloads in stock per aircraft type.
  local Npayloads={}

  -- First get payloads for aircraft types of squadrons.
  for _,_cohort in pairs(Cohorts) do
    local cohort=_cohort --Ops.Cohort#COHORT
    
    -- We only need that element once.
    if Npayloads[cohort.aircrafttype]==nil then
      
      -- Count number of payloads in stock for the cohort aircraft type.
      Npayloads[cohort.aircrafttype]=cohort.legion:IsAirwing() and self:CountPayloadsInStock(MissionType, cohort.aircrafttype, Payloads) or 999
      
      -- Debug info.
      self:T2(self.lid..string.format("Got N=%d payloads for mission type=%s and unit type=%s", Npayloads[cohort.aircrafttype], MissionType, cohort.aircrafttype))
    end
  end

  return Npayloads
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Recruiting Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Recruit assets for a given mission.
-- @param #LEGION self
-- @param Ops.Auftrag#AUFTRAG Mission The mission.
-- @return #boolean If `true` enough assets could be recruited.
-- @return #table Recruited assets.
-- @return #table Legions of recruited assets.
function LEGION:RecruitAssetsForMission(Mission)

  -- Get required assets.
  local NreqMin, NreqMax=Mission:GetRequiredAssets()
  
  -- Target position vector.
  local TargetVec2=Mission:GetTargetVec2()
  
  -- Payloads.
  local Payloads=Mission.payloads
  
  -- Largest cargo bay available of available carrier assets if mission assets need to be transported.
  local MaxWeight=nil
  
  if Mission.NcarriersMin then
  
    local legions={self}
    local cohorts=self.cohorts
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
    
    self:T(self.lid..string.format("Largest cargo bay available=%.1f", MaxWeight or 0))
  end
  
  
  local legions={self}
  local cohorts=self.cohorts
  if Mission.specialLegions or Mission.specialCohorts then
    legions=Mission.specialLegions
    cohorts=Mission.specialCohorts
  end  

  -- Get cohorts.  
  local Cohorts=LEGION._GetCohorts(legions, cohorts, Operation, OpsQueue)

  -- Recuit assets.
  local recruited, assets, legions=LEGION.RecruitCohortAssets(Cohorts, Mission.type, Mission.alert5MissionType, NreqMin, NreqMax, TargetVec2, Payloads, 
  Mission.engageRange, Mission.refuelSystem, nil, nil, MaxWeight, nil, Mission.attributes, Mission.properties, {Mission.engageWeaponType})

  return recruited, assets, legions
end

--- Recruit assets for a given OPS transport.
-- @param #LEGION self
-- @param Ops.OpsTransport#OPSTRANSPORT Transport The OPS transport.
-- @return #boolean If `true`, enough assets could be recruited.
-- @return #table assets Recruited assets.
-- @return #table legions Legions of recruited assets.
function LEGION:RecruitAssetsForTransport(Transport)

  -- Get all undelivered cargo ops groups.
  local cargoOpsGroups=Transport:GetCargoOpsGroups(false)
  
  local weightGroup=0
  local TotalWeight=nil
  
  -- At least one group should be spawned.
  if #cargoOpsGroups>0 then
  
    -- Calculate the max weight so we know which cohorts can provide carriers.
    TotalWeight=0
    for _,_opsgroup in pairs(cargoOpsGroups) do
      local opsgroup=_opsgroup --Ops.OpsGroup#OPSGROUP
      local weight=opsgroup:GetWeightTotal()
      if weight>weightGroup then
        weightGroup=weight
      end
      TotalWeight=TotalWeight+weight
    end
  else
    -- No cargo groups!
    return false
  end


  -- TODO: Special transport cohorts/legions.

  -- Target is the deploy zone.
  local TargetVec2=Transport:GetDeployZone():GetVec2()
  
  -- Number of required carriers.
  local NreqMin,NreqMax=Transport:GetRequiredCarriers()
  

  -- Recruit assets and legions.
  local recruited, assets, legions=LEGION.RecruitCohortAssets(self.cohorts, AUFTRAG.Type.OPSTRANSPORT, nil, NreqMin, NreqMax, TargetVec2, nil, nil, nil, weightGroup, TotalWeight)

  return recruited, assets, legions  
end

--- Recruit assets performing an escort mission for a given asset.
-- @param #LEGION self
-- @param Ops.Auftrag#AUFTRAG Mission The mission.
-- @param #table Assets Table of assets.
-- @return #boolean If `true`, enough assets could be recruited or no escort was required in the first place.
function LEGION:RecruitAssetsForEscort(Mission, Assets)

  -- Is an escort requested in the first place?
  if Mission.NescortMin and Mission.NescortMax and (Mission.NescortMin>0 or Mission.NescortMax>0) then
  
    -- Debug info.
    self:T(self.lid..string.format("Requested escort for mission %s [%s]. Required assets=%d-%d", Mission:GetName(), Mission:GetType(), Mission.NescortMin,Mission.NescortMax))
    
    -- Get special escort legions and/or cohorts.
    local Cohorts={}
    for _,_legion in pairs(Mission.escortLegions or {}) do
      local legion=_legion --Ops.Legion#LEGION
      for _,_cohort in pairs(legion.cohorts) do
        local cohort=_cohort --Ops.Cohort#COHORT
        table.insert(Cohorts, cohort)
      end
    end
    for _,_cohort in pairs(Mission.escortCohorts or {}) do
      local cohort=_cohort --Ops.Cohort#COHORT
      table.insert(Cohorts, cohort)
    end

    -- No escort cohorts/legions given ==> take own cohorts.    
    if #Cohorts==0 then
      Cohorts=self.cohorts
    end    
    
    -- Call LEGION function but provide COMMANDER as self.
    local assigned=LEGION.AssignAssetsForEscort(self, Cohorts, Assets, Mission.NescortMin, Mission.NescortMax, Mission.escortMissionType, Mission.escortTargetTypes)
    
    return assigned
  end

  return true
end

--- Get cohorts.
-- @param #table Legions Special legions.
-- @param #table Cohorts Special cohorts.
-- @param Ops.Operation#OPERATION Operation Operation.
-- @param #table OpsQueue Queue of operations.
-- @return #table Cohorts.
function LEGION._GetCohorts(Legions, Cohorts, Operation, OpsQueue)

  OpsQueue=OpsQueue or {}
  
  --- Function that check if a legion or cohort is part of an operation.
  local function CheckOperation(LegionOrCohort)
    -- No operations ==> no problem!
    if #OpsQueue==0 then
      return true
    end
    
    -- Cohort is not dedicated to a running(!) operation. We assume so.
    local isAvail=true
    
    -- Only available...
    if Operation then
      isAvail=false
    end
        
    for _,_operation in pairs(OpsQueue) do
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
          if (CheckOperation(cohort.legion) or CheckOperation(cohort)) and not UTILS.IsInTable(cohorts, cohort, "name") then
            table.insert(cohorts, cohort)
          end
        end
        
      end
    end
   
    -- Add special cohorts.
    for _,_cohort in pairs(Cohorts or {}) do
      local cohort=_cohort --Ops.Cohort#COHORT
      if CheckOperation(cohort) and not UTILS.IsInTable(cohorts, cohort, "name") then
        table.insert(cohorts, cohort)
      end
    end

  end

  return cohorts
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Recruiting and Optimization Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Recruit assets from Cohorts for the given parameters. **NOTE** that we set the `asset.isReserved=true` flag so it cant be recruited by anyone else.
-- @param Ops.Cohort#COHORT Cohort The Cohort.
-- @param #string MissionType Misson type(s).
-- @param #table Categories Group categories.
-- @param #table Attributes Group attributes. See `GROUP.Attribute.`
-- @param #table Properties DCS attributes.
-- @param #table WeaponTypes Bit of weapon types.
-- @param DCS#Vec2 TargetVec2 Target position.
-- @param RangeMax Max range in meters.
-- @param #number RefuelSystem Refueling system (boom or probe).
-- @param #number CargoWeight Cargo weight [kg]. This checks the cargo bay of the cohort assets and ensures that it is large enough to carry the given cargo weight.
-- @param #number MaxWeight Max weight [kg]. This checks whether the cohort asset group is not too heavy.
-- @return #boolean Returns `true` if given cohort can meet all requirements.
function LEGION._CohortCan(Cohort, MissionType, Categories, Attributes, Properties, WeaponTypes, TargetVec2, RangeMax, RefuelSystem, CargoWeight, MaxWeight)

  --- Function to check category.
  local function CheckCategory(_cohort)
    local cohort=_cohort --Ops.Cohort#COHORT
    if Categories and #Categories>0 then
      for _,category in pairs(Categories) do
        if category==cohort.category then
          return true
        end
      end
    else
      return true
    end
  end
  
  --- Function to check attribute.
  local function CheckAttribute(_cohort)
    local cohort=_cohort --Ops.Cohort#COHORT
    if Attributes and #Attributes>0 then
      for _,attribute in pairs(Attributes) do
        if attribute==cohort.attribute then
          return true
        end
      end
    else
      return true
    end
  end
  
  --- Function to check property.
  local function CheckProperty(_cohort)
    local cohort=_cohort --Ops.Cohort#COHORT
    if Properties and #Properties>0 then
      for _,Property in pairs(Properties) do
        for property,value in pairs(cohort.properties) do
          if Property==property then
            return true
          end
        end
      end
    else
      return true
    end
  end
  
  --- Function to check weapon type.
  local function CheckWeapon(_cohort)
    local cohort=_cohort --Ops.Cohort#COHORT
    if WeaponTypes and #WeaponTypes>0 then
      for _,WeaponType in pairs(WeaponTypes) do
        if WeaponType==ENUMS.WeaponFlag.Auto then
          return true
        else
          for _,_weaponData in pairs(cohort.weaponData or {}) do
            local weaponData=_weaponData --Ops.OpsGroup#OPSGROUP.WeaponData
            if weaponData.BitType==WeaponType then
              return true
            end
          end
        end
      end
      return false
    else
      return true
    end
  end

  --- Function to check range.
  local function CheckRange(_cohort)
    local cohort=_cohort --Ops.Cohort#COHORT
    
    -- Distance to target.
    local TargetDistance=TargetVec2 and UTILS.VecDist2D(TargetVec2, cohort.legion:GetVec2()) or 0
 
    -- Is in range?
    local Rmax=cohort:GetMissionRange(WeaponTypes)
    local RangeMax = RangeMax or 0    
    local InRange=(RangeMax and math.max(RangeMax, Rmax) or Rmax) >= TargetDistance
    
    --env.info(string.format("Range TargetDist=%.1f Rmax=%.1f RangeMax=%.1f InRange=%s", TargetDistance, Rmax, RangeMax, tostring(InRange)))
    
    return InRange    
  end


  --- Function to check weapon type.
  local function CheckRefueling(_cohort)
    local cohort=_cohort --Ops.Cohort#COHORT
    
    -- Has the requested refuelsystem?
    --local Refuel=RefuelSystem~=nil and (RefuelSystem==cohort.tankerSystem) or true
    
    -- STRANGE: Why did the above line did not give the same result?! Above Refuel is always true!
    if RefuelSystem then
      if cohort.tankerSystem then
        return RefuelSystem==cohort.tankerSystem
      else
        return false
      end
    else
      return true
    end    
  end

  --- Function to check cargo weight.
  local function CheckCargoWeight(_cohort)
    local cohort=_cohort --Ops.Cohort#COHORT
    if CargoWeight~=nil then
      return cohort.cargobayLimit>=CargoWeight
    else
      return true
    end    
  end

  --- Function to check cargo weight.
  local function CheckMaxWeight(_cohort)
    local cohort=_cohort --Ops.Cohort#COHORT
    if MaxWeight~=nil then
      cohort:T(string.format("Cohort weight=%.1f | max weight=%.1f", cohort.weightAsset, MaxWeight))
      return cohort.weightAsset<=MaxWeight
    else
      return true
    end    
  end

  
  -- Is capable of the mission type?
  local can=AUFTRAG.CheckMissionCapability(MissionType, Cohort.missiontypes)
  
  
  if can then
    can=CheckCategory(Cohort)
  else
    Cohort:T(Cohort.lid..string.format("Cohort %s cannot because of mission types", Cohort.name))
    return false    
  end
  
  if can then
    if MissionType==AUFTRAG.Type.RELOCATECOHORT then
      can=Cohort:IsRelocating()
    else
      can=Cohort:IsOnDuty()  
    end
  else
    Cohort:T(Cohort.lid..string.format("Cohort %s cannot because of category", Cohort.name))
    return false  
  end
  
  if can then
    can=CheckAttribute(Cohort)
  else
    Cohort:T(Cohort.lid..string.format("Cohort %s cannot because of readyiness", Cohort.name))
    return false
  end
  
  if can then
    can=CheckProperty(Cohort)
  else
    Cohort:T(Cohort.lid..string.format("Cohort %s cannot because of attribute", Cohort.name))
    return false
  end

  if can then
    can=CheckWeapon(Cohort)
  else
    Cohort:T(Cohort.lid..string.format("Cohort %s cannot because of property", Cohort.name))
    return false
  end

  if can then
    can=CheckRange(Cohort)
  else
    Cohort:T(Cohort.lid..string.format("Cohort %s cannot because of weapon type", Cohort.name))
    return false
  end
  
  if can then
    can=CheckRefueling(Cohort)
  else
    Cohort:T(Cohort.lid..string.format("Cohort %s cannot because of range", Cohort.name))
    return false
  end

  if can then
    can=CheckCargoWeight(Cohort)
  else
    Cohort:T(Cohort.lid..string.format("Cohort %s cannot because of refueling system", Cohort.name))
    return false
  end
  
  if can then
    can=CheckMaxWeight(Cohort)
  else
    Cohort:T(Cohort.lid..string.format("Cohort %s cannot because of cargo weight", Cohort.name))
    return false
  end
  
  if can then
    return true
  else
    Cohort:T(Cohort.lid..string.format("Cohort %s cannot because of max weight", Cohort.name))
    return false
  end
  
  return nil
end

--- Recruit assets from Cohorts for the given parameters. **NOTE** that we set the `asset.isReserved=true` flag so it cannot be recruited by anyone else.
-- @param #table Cohorts Cohorts included.
-- @param #string MissionTypeRecruit Mission type for recruiting the cohort assets.
-- @param #string MissionTypeOpt Mission type for which the assets are optimized. Default is the same as `MissionTypeRecruit`.
-- @param #number NreqMin Minimum number of required assets.
-- @param #number NreqMax Maximum number of required assets.
-- @param DCS#Vec2 TargetVec2 Target position as 2D vector.
-- @param #table Payloads Special payloads.
-- @param #number RangeMax Max range in meters.
-- @param #number RefuelSystem Refuelsystem.
-- @param #number CargoWeight Cargo weight for recruiting transport carriers.
-- @param #number TotalWeight Total cargo weight in kg.
-- @param #number MaxWeight Max weight [kg] of the asset group.
-- @param #table Categories Group categories. 
-- @param #table Attributes Group attributes. See `GROUP.Attribute.`
-- @param #table Properties DCS attributes.
-- @param #table WeaponTypes Bit of weapon types.
-- @return #boolean If `true` enough assets could be recruited.
-- @return #table Recruited assets. **NOTE** that we set the `asset.isReserved=true` flag so it cant be recruited by anyone else.
-- @return #table Legions of recruited assets.
function LEGION.RecruitCohortAssets(Cohorts, MissionTypeRecruit, MissionTypeOpt, NreqMin, NreqMax, TargetVec2, Payloads, RangeMax, RefuelSystem, CargoWeight, TotalWeight, MaxWeight, Categories, Attributes, Properties, WeaponTypes)

  -- The recruited assets.
  local Assets={}

  -- Legions of recruited assets.
  local Legions={}
  
  -- Set MissionTypeOpt to Recruit if nil.
  if MissionTypeOpt==nil then
    MissionTypeOpt=MissionTypeRecruit
  end
    
  -- Loops over cohorts.
  for _,_cohort in pairs(Cohorts) do
    local cohort=_cohort --Ops.Cohort#COHORT
    
    -- Check if cohort can do the mission.
    local can=LEGION._CohortCan(cohort, MissionTypeRecruit, Categories, Attributes, Properties, WeaponTypes, TargetVec2, RangeMax, RefuelSystem, CargoWeight, MaxWeight)

    --env.info(string.format("RecruitCohortAssets %s Cohort=%s can=%s", MissionTypeRecruit, cohort:GetName(), tostring(can)))
    
    -- Check OnDuty, capable, in range and refueling type (if TANKER).
    if can then

      -- Recruit assets from cohort.
      local assets, npayloads=cohort:RecruitAssets(MissionTypeRecruit, 999)
      
      -- Add assets to the list.
      for _,asset in pairs(assets) do
        table.insert(Assets, asset)
      end
      
    end
    
  end
  
  -- Break if no assets could be found
  if #Assets==0 then
    --env.info(string.format("LEGION.RecruitCohortAssets: No assets could be recruited for mission type %s [Nmin=%s, Nmax=%s]", MissionTypeRecruit, tostring(NreqMin), tostring(NreqMax)))
    return false, {}, {}  
  end
  
  -- Now we have a long list with assets.
  LEGION._OptimizeAssetSelection(Assets, MissionTypeOpt, TargetVec2, false, TotalWeight)
  
  
  -- Get payloads for air assets.
  for _,_asset in pairs(Assets) do
    local asset=_asset --Functional.Warehouse#WAREHOUSE.Assetitem
    
    -- Only assets that have no payload. Should be only spawned assets!
    if asset.legion:IsAirwing() and not asset.payload then
    
      -- Fetch payload for asset. This can be nil!
      asset.payload=asset.legion:FetchPayloadFromStock(asset.unittype, MissionTypeOpt, Payloads)
              
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
  LEGION._OptimizeAssetSelection(Assets, MissionTypeOpt, TargetVec2, true, TotalWeight)

  -- Number of assets. At most NreqMax.
  local Nassets=math.min(#Assets, NreqMax)
  
  if #Assets>=NreqMin then
  
    ---
    -- Found enough assets
    ---

    -- Total cargo bay of all carrier assets.
    local cargobay=0

    -- Add assets to mission.
    for i=1,Nassets do
      local asset=Assets[i] --Functional.Warehouse#WAREHOUSE.Assetitem
      
      -- Asset is reserved and will not be picked for other missions.
      asset.isReserved=true
      
      -- Add legion.
      Legions[asset.legion.alias]=asset.legion
      
      -- Check if total cargo weight was given.
      if TotalWeight then
      
        -- Number of 
        local N=math.floor(asset.cargobaytot/asset.nunits / CargoWeight)*asset.nunits
        --env.info(string.format("cargobaytot=%d, cargoweight=%d ==> N=%d", asset.cargobaytot, CargoWeight, N))
        
        -- Sum up total cargo bay of all carrier assets.
        cargobay=cargobay + N*CargoWeight        
        
        -- Check if enough carrier assets were found to transport all cargo.
        if cargobay>=TotalWeight then
          --env.info(string.format("FF found enough assets to transport all cargo! N=%d [%d], cargobay=%.1f >= %.1f kg total weight", i, Nassets, cargobay, TotalWeight))
          Nassets=i
          break
        end
        
      end
      
    end
    
    -- Return payloads of not needed assets.
    for i=#Assets,Nassets+1,-1 do
      local asset=Assets[i] --Functional.Warehouse#WAREHOUSE.Assetitem
      if asset.legion:IsAirwing() and not asset.spawned then
        asset.legion:T2(asset.legion.lid..string.format("Returning payload from asset %s", asset.spawngroupname))
        asset.legion:ReturnPayloadFromAsset(asset)
      end
      table.remove(Assets, i)
    end
    
    -- Found enough assets.
    return true, Assets, Legions
  else

    ---
    -- NOT enough assets
    ---
  
    -- Return payloads of assets.    
    for i=1,#Assets do
      local asset=Assets[i] --Functional.Warehouse#WAREHOUSE.Assetitem
      if asset.legion:IsAirwing() and not asset.spawned then
        asset.legion:T2(asset.legion.lid..string.format("Returning payload from asset %s", asset.spawngroupname))
        asset.legion:ReturnPayloadFromAsset(asset)
      end
    end
      
    -- Not enough assets found.
    return false, {}, {}
  end

  return false, {}, {}
end

--- Unrecruit assets. Set `isReserved` to false, return payload to airwing and (optionally) remove from assigned mission.
-- @param #table Assets List of assets.
-- @param Ops.Auftrag#AUFTRAG Mission (Optional) The mission from which the assets will be deleted.
function LEGION.UnRecruitAssets(Assets, Mission)

  -- Return payloads of assets.    
  for i=1,#Assets do
    local asset=Assets[i] --Functional.Warehouse#WAREHOUSE.Assetitem
    -- Not reserved any more.
    asset.isReserved=false
    -- Return payload.
    if asset.legion:IsAirwing() and not asset.spawned then
      asset.legion:T2(asset.legion.lid..string.format("Returning payload from asset %s", asset.spawngroupname))
      asset.legion:ReturnPayloadFromAsset(asset)
    end
    -- Remove from mission.
    if Mission then
      Mission:DelAsset(asset)
    end    
  end  

end


--- Recruit and assign assets performing an escort mission for a given asset list. Note that each asset gets an escort.
-- @param #LEGION self
-- @param #table Cohorts Cohorts for escorting assets.
-- @param #table Assets Table of assets to be escorted.
-- @param #number NescortMin Min number of escort groups required per escorted asset.
-- @param #number NescortMax Max number of escort groups required per escorted asset.
-- @param #string MissionType Mission type.
-- @param #string TargetTypes Types of targets that are engaged.
-- @param #number EngageRange EngageRange in Nautical Miles.
-- @return #boolean If `true`, enough assets could be recruited or no escort was required in the first place.
function LEGION:AssignAssetsForEscort(Cohorts, Assets, NescortMin, NescortMax, MissionType, TargetTypes, EngageRange)

  -- Is an escort requested in the first place?
  if NescortMin and NescortMax and (NescortMin>0 or NescortMax>0) then
  
    -- Debug info.
    self:T(self.lid..string.format("Requested escort for %d assets from %d cohorts. Required escort assets=%d-%d", #Assets, #Cohorts, NescortMin, NescortMax))
    
    -- Escorts for each asset.        
    local Escorts={}
    
    local EscortAvail=true
    for _,_asset in pairs(Assets) do
      local asset=_asset --Functional.Warehouse#WAREHOUSE.Assetitem
      
      -- Target vector is the legion of the asset.
      local TargetVec2=asset.legion:GetVec2()
      
      -- We want airplanes for airplanes and helos for everything else.
      local Categories={Group.Category.HELICOPTER}
      local targetTypes={"Ground Units"}
      if asset.category==Group.Category.AIRPLANE then
        Categories={Group.Category.AIRPLANE}
        targetTypes={"Air"}
      end
      
      TargetTypes=TargetTypes or targetTypes
      
      -- Recruit escort asset for the mission asset.
      local Erecruited, eassets, elegions=LEGION.RecruitCohortAssets(Cohorts, AUFTRAG.Type.ESCORT, MissionType, NescortMin, NescortMax, TargetVec2, nil, nil, nil, nil, nil, nil, Categories)
      
      if Erecruited then
        Escorts[asset.spawngroupname]={EscortLegions=elegions, EscortAssets=eassets, ecategory=asset.category}
      else
        -- Could not find escort for this asset ==> Escort not possible ==> Break the loop.
        EscortAvail=false
        break
      end
    end
    
    -- ALL escorts could be recruited. 
    if EscortAvail then
    
      local N=0
      for groupname,value in pairs(Escorts) do
      
        local Elegions=value.EscortLegions
        local Eassets=value.EscortAssets
        local ecategory=value.ecategory
        
        for _,_legion in pairs(Elegions) do
          local legion=_legion --Ops.Legion#LEGION
    
          local OffsetVector=nil --DCS#Vec3
          if ecategory==Group.Category.GROUND then
            -- Overhead at 1000 ft.
            OffsetVector={}
            OffsetVector.x=0
            OffsetVector.y=UTILS.FeetToMeters(1000)
            OffsetVector.z=0
          elseif MissionType==AUFTRAG.Type.SEAD then
            -- Overhead slightly higher and right.
            OffsetVector={}
            OffsetVector.x=-100
            OffsetVector.y= 500
            OffsetVector.z= 500
          end
    
          -- Create and ESCORT mission for this asset.
          local escort=AUFTRAG:NewESCORT(groupname, OffsetVector, EngageRange, TargetTypes)
          
          -- For a SEAD mission, we also adjust the mission task.
          if MissionType==AUFTRAG.Type.SEAD then
            escort.missionTask=ENUMS.MissionTask.SEAD
            -- Add enroute task SEAD.
            local DCStask=CONTROLLABLE.EnRouteTaskSEAD(nil)
            table.insert(escort.enrouteTasks, DCStask)       
          end
          
          -- Reserve assts and add to mission.
          for _,_asset in pairs(Eassets) do
            local asset=_asset --Functional.Warehouse#WAREHOUSE.Assetitem
            escort:AddAsset(asset)
            N=N+1
          end
          
          -- Assign mission to legion.
          self:MissionAssign(escort, {legion})
        end
      end
      
      -- Debug info.
      self:T(self.lid..string.format("Recruited %d escort assets", N))
    
      -- Yup!
      return true    
    else

      -- Debug info.
      self:T(self.lid..string.format("Could not get at least one escort!"))      
    
      -- Could not get at least one escort. Unrecruit all recruited ones.
      for groupname,value in pairs(Escorts) do      
        local Eassets=value.EscortAssets
        LEGION.UnRecruitAssets(Eassets)
      end
      
      -- No,no!
      return false      
    end
    
  else
    -- No escort required.
    self:T(self.lid..string.format("No escort required! NescortMin=%s, NescortMax=%s", tostring(NescortMin), tostring(NescortMax)))
    return true
  end      

end

--- Recruit and assign assets performing an OPSTRANSPORT for a given asset list.
-- @param #LEGION self
-- @param #table Legions Transport legions.
-- @param #table CargoAssets Weight of the heaviest cargo group to be transported.
-- @param #number NcarriersMin Min number of carrier assets.
-- @param #number NcarriersMax Max number of carrier assets.
-- @param Core.Zone#ZONE DeployZone Deploy zone.
-- @param Core.Zone#ZONE DisembarkZone (Optional) Disembark zone. 
-- @param #table Categories Group categories.
-- @param #table Attributes Generalizes group attributes.
-- @param #table Properties DCS attributes.
-- @return #boolean If `true`, enough assets could be recruited and an OPSTRANSPORT object was created.
-- @return Ops.OpsTransport#OPSTRANSPORT Transport The transport.
function LEGION:AssignAssetsForTransport(Legions, CargoAssets, NcarriersMin, NcarriersMax, DeployZone, DisembarkZone, Categories, Attributes, Properties)

  -- Is an escort requested in the first place?
  if NcarriersMin and NcarriersMax and (NcarriersMin>0 or NcarriersMax>0) then
  
    -- Get cohorts.
    local Cohorts=LEGION._GetCohorts(Legions)
    
    -- Get all legions and heaviest cargo group weight
    local CargoLegions={} ; local CargoWeight=nil ; local TotalWeight=0
    for _,_asset in pairs(CargoAssets) do
      local asset=_asset --Functional.Warehouse#WAREHOUSE.Assetitem
      CargoLegions[asset.legion.alias]=asset.legion
      if CargoWeight==nil or asset.weight>CargoWeight then
        CargoWeight=asset.weight
      end
      TotalWeight=TotalWeight+asset.weight
    end
    
    -- Debug info.
    self:T(self.lid..string.format("Cargo weight=%.1f", CargoWeight))
    self:T(self.lid..string.format("Total weight=%.1f", TotalWeight))
  
    -- Target is the deploy zone.
    local TargetVec2=DeployZone:GetVec2()
    
    -- Recruit assets and legions.
    local TransportAvail, CarrierAssets, CarrierLegions=
    LEGION.RecruitCohortAssets(Cohorts, AUFTRAG.Type.OPSTRANSPORT, nil, NcarriersMin, NcarriersMax, TargetVec2, nil, nil, nil, CargoWeight, TotalWeight, nil, Categories, Attributes, Properties)
  
    if TransportAvail then
    
      -- Create and OPSTRANSPORT assignment.
      local Transport=OPSTRANSPORT:New(nil, nil, DeployZone)
      if DisembarkZone then
        Transport:SetDisembarkZone(DisembarkZone)
      end
      
      -- Debug info.    
      self:T(self.lid..string.format("Transport available with %d carrier assets", #CarrierAssets))
    
      -- Add cargo assets to transport.
      for _,_legion in pairs(CargoLegions) do
        local legion=_legion --Ops.Legion#LEGION
        
        -- Set pickup zone to spawn zone or airbase if the legion has one that is operational.
        local pickupzone=legion.spawnzone
        
        -- Add TZC from legion spawn zone to deploy zone.
        local tpz=Transport:AddTransportZoneCombo(nil, pickupzone, Transport:GetDeployZone())
        
        -- Set pickup airbase if the legion has an airbase. Could also be the ship itself.
        tpz.PickupAirbase=legion:IsRunwayOperational() and legion.airbase or nil
        
        -- Set embark zone to spawn zone.
        Transport:SetEmbarkZone(legion.spawnzone, tpz)
        
        -- Add cargo assets to transport.
        for _,_asset in pairs(CargoAssets) do
          local asset=_asset --Functional.Warehouse#WAREHOUSE.Assetitem
          if asset.legion.alias==legion.alias then
            Transport:AddAssetCargo(asset, tpz)
          end
        end
      end
      
      -- Add carrier assets.
      for _,_asset in pairs(CarrierAssets) do
        local asset=_asset --Functional.Warehouse#WAREHOUSE.Assetitem
        Transport:AddAsset(asset)
      end
          
      -- Assign TRANSPORT to legions. This also sends the request for the assets.
      self:TransportAssign(Transport, CarrierLegions)
      
      -- Got transport.
      return true, Transport
    else
      -- Debug info.    
      self:T(self.lid..string.format("Transport assets could not be allocated ==> Unrecruiting assets"))    
    
      -- Uncrecruit transport assets.
      LEGION.UnRecruitAssets(CarrierAssets)
      return false, nil
    end
  
    return nil, nil  
  end
  
  -- No transport requested in the first place.
  return true, nil
end


--- Calculate the mission score of an asset.
-- @param Functional.Warehouse#WAREHOUSE.Assetitem asset Asset
-- @param #string MissionType Mission type for which the best assets are desired.
-- @param DCS#Vec2 TargetVec2 Target 2D vector.
-- @param #boolean IncludePayload If `true`, include the payload in the calulation if the asset has one attached.
-- @param #number TotalWeight The total weight of the cargo to be transported, if applicable.
-- @return #number Mission score.
function LEGION.CalculateAssetMissionScore(asset, MissionType, TargetVec2, IncludePayload, TotalWeight)
  
  -- Mission score.
  local score=0

  -- Prefer highly skilled assets.
  if asset.skill==AI.Skill.AVERAGE then
    score=score+0
  elseif asset.skill==AI.Skill.GOOD then
    score=score+10
  elseif asset.skill==AI.Skill.HIGH then
    score=score+20
  elseif asset.skill==AI.Skill.EXCELLENT then
    score=score+30
  end

  -- Add mission performance to score.
  score=score+asset.cohort:GetMissionPeformance(MissionType)

  -- Add payload performance to score.
  local function scorePayload(Payload, MissionType)
    for _,Capability in pairs(Payload.capabilities) do
      local capability=Capability --Ops.Auftrag#AUFTRAG.Capability
      if capability.MissionType==MissionType then
        return capability.Performance
      end
    end
    return 0
  end
  
  if IncludePayload and asset.payload then
    score=score+scorePayload(asset.payload, MissionType)
  end
    
  -- Origin: We take the OPSGROUP position or the one of the legion.
  local OrigVec2=asset.flightgroup and asset.flightgroup:GetVec2() or asset.legion:GetVec2()
  
  -- Distance factor.
  local distance=0
  if TargetVec2 and OrigVec2 then
  
    -- Distance in NM.
    distance=UTILS.MetersToNM(UTILS.VecDist2D(OrigVec2, TargetVec2))
    
    if asset.category==Group.Category.AIRPLANE or asset.category==Group.Category.HELICOPTER then
      -- Round: 55 NM ==> 5.5 ==> 6, 63 NM ==> 6.3 ==> 6
      distance=UTILS.Round(distance/10, 0)
    else
      -- For ground units the distance is a more important factor
      distance=UTILS.Round(distance, 0)
    end
    
  end
  
  -- Reduce score for legions that are futher away.
  score=score-distance
  
  -- Check for spawned assets.
  if asset.spawned and asset.flightgroup and asset.flightgroup:IsAlive() then
  
    -- Get current mission.
    local currmission=asset.flightgroup:GetMissionCurrent()
    
    if currmission then
    
      if currmission.type==AUFTRAG.Type.ALERT5 and currmission.alert5MissionType==MissionType then
        -- Prefer assets that are on ALERT5 for this mission type.
        score=score+25
      elseif (currmission.type==AUFTRAG.Type.GCICAP or currmission.type==AUFTRAG.Type.PATROLRACETRACK) and MissionType==AUFTRAG.Type.INTERCEPT then
        -- Prefer assets that are on GCICAP to perform INTERCEPTS. We set this even higher than alert5 because they are already in the air.
        score=score+35
      elseif (currmission.type==AUFTRAG.Type.ONGUARD or currmission.type==AUFTRAG.Type.PATROLZONE) and (MissionType==AUFTRAG.Type.ARTY  or MissionType==AUFTRAG.Type.GROUNDATTACK) then
        score=score+25
      elseif currmission.type==AUFTRAG.Type.NOTHING then
        score=score+30
      end
      
    end
  
    if MissionType==AUFTRAG.Type.OPSTRANSPORT or MissionType==AUFTRAG.Type.AMMOSUPPLY or MissionType==AUFTRAG.Type.AWACS or MissionType==AUFTRAG.Type.FUELSUPPLY or MissionType==AUFTRAG.Type.TANKER then
      -- TODO: need to check for missions that do not require ammo like transport, recon, awacs, tanker etc.
      -- We better take a fresh asset. Sometimes spawned assets do something else, which is difficult to check.
      score=score-10
    else
      -- Combat mission.
      if asset.flightgroup:IsOutOfAmmo() then
        -- Assets that are out of ammo are not considered.
        score=score-1000
      end
    end
  end
  
  -- TRANSPORT specific.
  if MissionType==AUFTRAG.Type.OPSTRANSPORT then
    if TotalWeight then
      -- Add 1 score point for each 10 kg of cargo bay capacity up to the total cargo weight,
      -- and then subtract 1 score point for each excess 10kg of cargo bay capacity.
      if asset.cargobaymax < TotalWeight then
        score=score+UTILS.Round(asset.cargobaymax/10, 0)
      else
        score=score+UTILS.Round(TotalWeight/10, 0)
      end
    else
      -- Add 1 score point for each 10 kg of cargo bay.
      score=score+UTILS.Round(asset.cargobaymax/10, 0)
    end
  end  

  -- TODO: This could be vastly improved. Need to gather ideas during testing.
  -- Calculate ETA? Assets on orbit missions should arrive faster even if they are further away.
  -- Max speed of assets.
  -- Fuel amount?
  -- Range of assets?
  
  if asset.legion and asset.legion.verbose>=2 then
    asset.legion:I(asset.legion.lid..string.format("Asset %s [spawned=%s] score=%d", asset.spawngroupname, tostring(asset.spawned), score))
  end

  return score
end

--- Optimize chosen assets for the mission at hand.
-- @param #table assets Table of (unoptimized) assets.
-- @param #string MissionType Mission type.
-- @param DCS#Vec2 TargetVec2 Target position as 2D vector.
-- @param #boolean IncludePayload If `true`, include the payload in the calulation if the asset has one attached.
-- @param #number TotalWeight The total weight of the cargo to be transported, if applicable.
function LEGION._OptimizeAssetSelection(assets, MissionType, TargetVec2, IncludePayload, TotalWeight)

  -- Calculate the mission score of all assets.
  for _,_asset in pairs(assets) do
    local asset=_asset --Functional.Warehouse#WAREHOUSE.Assetitem
    
    -- Calculate the asset score.
    asset.score=LEGION.CalculateAssetMissionScore(asset, MissionType, TargetVec2, IncludePayload, TotalWeight)
    
    if IncludePayload then
    
      -- Max random asset score.
      local RandomScoreMax=asset.legion and asset.legion.RandomAssetScore or LEGION.RandomAssetScore
      
      -- Random score.
      local RandomScore=math.random(0, RandomScoreMax)
      
      -- Debug info.
      --env.info(string.format("Asset %s: randomscore=%d, max=%d", asset.spawngroupname, RandomScore, RandomScoreMax))
      
      -- Add a bit of randomness.
      asset.score=asset.score+RandomScore
      
    end
  end

  --- Sort assets wrt to their mission score. Higher is better.
  local function optimize(a, b)
    local assetA=a --Functional.Warehouse#WAREHOUSE.Assetitem
    local assetB=b --Functional.Warehouse#WAREHOUSE.Assetitem
    -- Higher score wins. If equal score ==> closer wins.
    return (assetA.score>assetB.score)
  end
  table.sort(assets, optimize)

  -- Remove distance parameter.
  if LEGION.verbose>0 then
    local text=string.format("Optimized %d assets for %s mission/transport (payload=%s):", #assets, MissionType, tostring(IncludePayload))
    for i,Asset in pairs(assets) do
      local asset=Asset --Functional.Warehouse#WAREHOUSE.Assetitem
      text=text..string.format("\n%d. %s [%s]: score=%d", i, asset.spawngroupname, asset.squadname, asset.score or -1)
      asset.score=nil
    end
    env.info(text)
  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Returns the mission for a given mission ID (Autragsnummer).
-- @param #LEGION self
-- @param #number mid Mission ID (Auftragsnummer).
-- @return Ops.Auftrag#AUFTRAG Mission table.
function LEGION:GetMissionByID(mid)

  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG

    if mission.auftragsnummer==tonumber(mid) then
      return mission
    end

  end

  return nil
end

--- Returns the mission for a given ID.
-- @param #LEGION self
-- @param #number uid Transport UID.
-- @return Ops.OpsTransport#OPSTRANSPORT Transport assignment.
function LEGION:GetTransportByID(uid)

  for _,_transport in pairs(self.transportqueue) do
    local transport=_transport --Ops.OpsTransport#OPSTRANSPORT

    if transport.uid==tonumber(uid) then
      return transport
    end

  end

  return nil
end

--- Returns the mission for a given request ID.
-- @param #LEGION self
-- @param #number RequestID Unique ID of the request.
-- @return Ops.Auftrag#AUFTRAG Mission table or *nil*.
function LEGION:GetMissionFromRequestID(RequestID)
  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG
    local mid=mission.requestID[self.alias]
    if  mid and mid==RequestID then
      return mission
    end
  end
  return nil
end

--- Returns the mission for a given request.
-- @param #LEGION self
-- @param Functional.Warehouse#WAREHOUSE.Queueitem Request The warehouse request.
-- @return Ops.Auftrag#AUFTRAG Mission table or *nil*.
function LEGION:GetMissionFromRequest(Request)
  return self:GetMissionFromRequestID(Request.uid)
end

--- Fetch a payload from the airwing resources for a given unit and mission type.
-- The payload with the highest priority is preferred.
-- @param #LEGION self
-- @param #string UnitType The type of the unit.
-- @param #string MissionType The mission type.
-- @param #table Payloads Specific payloads only to be considered.
-- @return Ops.Airwing#AIRWING.Payload Payload table or *nil*.
function LEGION:FetchPayloadFromStock(UnitType, MissionType, Payloads)
  -- Polymorphic. Will return something when called by airwing.
  return nil
end

--- Return payload from asset back to stock.
-- @param #LEGION self
-- @param Functional.Warehouse#WAREHOUSE.Assetitem asset The squadron asset.
function LEGION:ReturnPayloadFromAsset(asset)
  -- Polymorphic.
  return nil
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
