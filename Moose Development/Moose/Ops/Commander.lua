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
-- A commander is the head of legions. He will find the best LEGIONs to perform an assigned AUFTRAG (mission).
--
--
-- @field #COMMANDER
COMMANDER = {
  ClassName      = "COMMANDER",
  Debug          =   nil,
  lid            =   nil,
  legions       =     {},
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
  
  self:AddTransition("*",                  "MissionAssign",       "*")           -- Mission was assigned to a LEGION.
  self:AddTransition("*",                  "MissionCancel",       "*")           -- Cancel mission.

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

  -- Check mission queue and assign one PLANNED mission.
  self:CheckMissionQueue()
  
  -- Status.
  local text=string.format("Status %s: Legions=%d, Missions=%d", fsmstate, #self.legions, #self.missionqueue)
  self:I(self.lid..text)
  
  -- Legion info.
  if #self.legions>0 then
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
  end
  
  -- Mission queue.
  if #self.missionqueue>0 then
  
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

  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG
    
    -- We look for PLANNED missions.
    if mission:IsPlanned() then
    
      ---
      -- PLANNNED Mission
      ---
    
      -- Get legions for mission.
      local legions=self:GetLegionsForMission(mission)
        
      if legions then
      
        for _,_legion in pairs(legions) do
          local legion=_legion --Ops.Legion#LEGION
      
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
    if Nassets>0 then        
      
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
            
  end
  
  -- Can anyone?
  if #legions>0 then
  
    --- Something like:
    -- * Closest legion that can should be first prio.
    -- * However, there should be a certain "quantization". if wing is 50 or 60 NM way should not really matter. In that case, the legion with more resources should get the job.
    local function score(a)
      local d=math.round(a.dist/10)
    end
    
    env.info(self.lid.."FF #legions="..#legions)
  
    -- Sort table wrt distance and number of assets.
    -- Distances within 10 NM are equal and the legion with more assets is preferred.
    local function sortdist(a,b)
      local ad=a.dist
      local bd=b.dist 
      return ad<bd or (ad==bd and a.nassets>b.nassets)
    end
    table.sort(legions, sortdist)

    
    -- Loops over all legions and stop if enough assets are summed up.
    local selection={} ; local N=0
    for _,leg in ipairs(legions) do
      local legion=leg.airwing --Ops.Legion#LEGION
      
      Mission.Nassets=Mission.Nassets or {}
      Mission.Nassets[legion.alias]=leg.nassets
          
      table.insert(selection, legion)
      
      N=N+leg.nassets
      
      if N>=Mission.nassets then
        self:I(self.lid..string.format("Found enough assets!"))
        break
      end
    end
    
    if N>=Mission.nassets then
      self:I(self.lid..string.format("Found %d legions that can do mission %s (%s) requiring %d assets", #selection, Mission:GetName(), Mission:GetType(), Mission.nassets))
      return selection
    else
      self:T(self.lid..string.format("Not enough LEGIONs found that could do the job :/ Number of assets avail %d < %d required for the mission", N, Mission.nassets))
      return nil
    end
    
  else
    self:T(self.lid..string.format("No LEGION found that could do the job :/"))
  end

  return nil
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

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------