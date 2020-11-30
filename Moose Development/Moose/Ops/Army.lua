--- **Ops** - Army Warehouse.
--
-- **Main Features:**
--
--    * Manage platoons
--
-- ===
--
-- ### Author: **funkyfranky**
-- @module Ops.Army
-- @image OPS_AirWing.png


--- ARMY class.
-- @type ARMY
-- @field #string ClassName Name of the class.
-- @field #number verbose Verbosity of output.
-- @field #string lid Class id string for output to DCS log file.
-- @field #table menu Table of menu items.
-- @field #table squadrons Table of squadrons.
-- @field #table missionqueue Mission queue table.
-- @field #table payloads Playloads for specific aircraft and mission types. 
-- @field #number payloadcounter Running index of payloads.
-- @field Core.Set#SET_ZONE zonesetCAP Set of CAP zones.
-- @field Core.Set#SET_ZONE zonesetTANKER Set of TANKER zones.
-- @field Core.Set#SET_ZONE zonesetAWACS Set of AWACS zones.
-- @field #number nflightsCAP Number of CAP flights constantly in the air.
-- @field #number nflightsAWACS Number of AWACS flights constantly in the air.
-- @field #number nflightsTANKERboom Number of TANKER flights with BOOM constantly in the air.
-- @field #number nflightsTANKERprobe Number of TANKER flights with PROBE constantly in the air. 
-- @field #number nflightsRescueHelo Number of Rescue helo flights constantly in the air.
-- @field #table pointsCAP Table of CAP points.
-- @field #table pointsTANKER Table of Tanker points.
-- @field #table pointsAWACS Table of AWACS points.
-- @field Ops.WingCommander#WINGCOMMANDER wingcommander The wing commander responsible for this airwing.
-- 
-- @field Ops.RescueHelo#RESCUEHELO rescuehelo The rescue helo.
-- @field Ops.RecoveryTanker#RECOVERYTANKER recoverytanker The recoverytanker.
-- 
-- @extends Functional.Warehouse#WAREHOUSE

--- Be surprised!
--
-- ===
--
-- ![Banner Image](..\Presentations\OPS\AirWing\_Main.png)
--
-- # The ARMY Concept
-- 
-- An ARMY consists of multiple SQUADRONS. These squadrons "live" in a WAREHOUSE, i.e. a physical structure that is connected to an airbase (airdrome, FRAP or ship).
-- For an airwing to be operational, it needs airframes, weapons/fuel and an airbase.
-- 
-- # Create an Army
-- 
-- ## Constructing the Army
-- 
--     airwing=ARMY:New("Warehouse Batumi", "8th Fighter Wing")
--     airwing:Start()
--     
-- The first parameter specified the warehouse, i.e. the static building housing the airwing (or the name of the aircraft carrier). The second parameter is optional
-- and sets an alias.
-- 
-- ## Adding Squadrons
-- 
-- At this point the airwing does not have any assets (aircraft). In order to add these, one needs to first define SQUADRONS.
-- 
--     VFA151=SQUADRON:New("F-14 Group", 8, "VFA-151 (Vigilantes)")
--     VFA151:AddMissionCapability({AUFTRAG.Type.GCICAP, AUFTRAG.Type.INTERCEPT})
--     
--     airwing:AddSquadron(VFA151)
--     
-- This adds eight Tomcat groups beloning to VFA-151 to the airwing. This squadron has the ability to perform combat air patrols and intercepts.
-- 
-- ## Adding Payloads
-- 
-- Adding pure airframes is not enough. The aircraft also need weapons (and fuel) for certain missions. These must be given to the airwing from template groups
-- defined in the Mission Editor.
-- 
--     -- F-14 payloads for CAP and INTERCEPT. Phoenix are first, sparrows are second choice.
--     airwing:NewPayload(GROUP:FindByName("F-14 Payload AIM-54C"), 2, {AUFTRAG.Type.INTERCEPT, AUFTRAG.Type.GCICAP}, 80)
--     airwing:NewPayload(GROUP:FindByName("F-14 Payload AIM-7M"), 20, {AUFTRAG.Type.INTERCEPT, AUFTRAG.Type.GCICAP})
-- 
-- This will add two AIM-54C and 20 AIM-7M payloads.
-- 
-- If the airwing gets an intercept or patrol mission assigned, it will first use the AIM-54s. Once these are consumed, the AIM-7s are attached to the aircraft.
-- 
-- When an airwing does not have a payload for a certain mission type, the mission cannot be carried out.
-- 
-- You can set the number of payloads to "unlimited" by setting its quantity to -1.
-- 
-- # Adding Missions
-- 
-- Various mission types can be added easily via the AUFTRAG class.
-- 
-- Once you created an AUFTRAG you can add it to the ARMY with the :AddMission(mission) function.
-- 
-- This mission will be put into the ARMY queue. Once the mission start time is reached and all resources (airframes and pylons) are available, the mission is started.
-- If the mission stop time is over (and the mission is not finished), it will be cancelled and removed from the queue. This applies also to mission that were not even
-- started.
-- 
-- # Command an Army
-- 
-- An airwing can receive missions from a WINGCOMMANDER. See docs of that class for details.
-- 
-- However, you are still free to add missions at anytime.
--
--
-- @field #ARMY
ARMY = {
  ClassName      = "ARMY",
  verbose        =     0,
  lid            =   nil,
  menu           =   nil,
  squadrons      =    {},
  missionqueue   =    {},
  payloads       =    {},
  payloadcounter =     0,
  pointsCAP      =    {},
  pointsTANKER   =    {},
  pointsAWACS    =    {},
  wingcommander  =   nil,
}

--- Squadron asset.
-- @type ARMY.SquadronAsset
-- @field #ARMY.Payload payload The payload of the asset.
-- @field Ops.FlightGroup#FLIGHTGROUP flightgroup The flightgroup object.
-- @field #string squadname Name of the squadron this asset belongs to.
-- @field #number Treturned Time stamp when asset returned to the airwing.
-- @extends Functional.Warehouse#WAREHOUSE.Assetitem

--- ARMY class version.
-- @field #string version
ARMY.version="0.0.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ToDo list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: A lot!

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new ARMY class object.
-- @param #ARMY self
-- @param #string warehousename Name of the warehouse static or unit object representing the warehouse.
-- @param #string airwingname Name of the air wing, e.g. "ARMY-8".
-- @return #ARMY self
function ARMY:New(warehousename, airwingname)

  -- Inherit everything from WAREHOUSE class.
  local self=BASE:Inherit(self, WAREHOUSE:New(warehousename, airwingname)) -- #ARMY

  -- Nil check.
  if not self then
    BASE:E(string.format("ERROR: Could not find warehouse %s!", warehousename))
    return nil
  end

  -- Set some string id for output to DCS.log file.
  self.lid=string.format("ARMY %s | ", self.alias)

  -- Add FSM transitions.
  --                 From State  -->   Event        -->     To State
  self:AddTransition("*",             "MissionRequest",     "*")           -- Add a (mission) request to the warehouse.
  self:AddTransition("*",             "MissionCancel",      "*")           -- Cancel mission.

  ------------------------
  --- Pseudo Functions ---
  ------------------------

  --- Triggers the FSM event "Start". Starts the ARMY. Initializes parameters and starts event handlers.
  -- @function [parent=#ARMY] Start
  -- @param #ARMY self

  --- Triggers the FSM event "Start" after a delay. Starts the ARMY. Initializes parameters and starts event handlers.
  -- @function [parent=#ARMY] __Start
  -- @param #ARMY self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Stop". Stops the ARMY and all its event handlers.
  -- @param #ARMY self

  --- Triggers the FSM event "Stop" after a delay. Stops the ARMY and all its event handlers.
  -- @function [parent=#ARMY] __Stop
  -- @param #ARMY self
  -- @param #number delay Delay in seconds.

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Start & Status
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Start AIRWING FSM.
-- @param #AIRWING self
function AIRWING:onafterStart(From, Event, To)

  -- Start parent Warehouse.
  self:GetParent(self).onafterStart(self, From, Event, To)

  -- Info.
  self:I(self.lid..string.format("Starting AIRWING v%s", AIRWING.version))

end

--- Update status.
-- @param #AIRWING self
function AIRWING:onafterStatus(From, Event, To)

  -- Status of parent Warehouse.
  self:GetParent(self).onafterStatus(self, From, Event, To)

  local fsmstate=self:GetState()

  
  -- General info:
  if self.verbose>=1 then

    -- Count missions not over yet.
    local Nmissions=self:CountMissionsInQueue()
    
    -- Assets tot
    local Npq, Np, Nq=self:CountAssetsOnMission()
    
    local assets=string.format("%d (OnMission: Total=%d, Active=%d, Queued=%d)", self:CountAssets(), Npq, Np, Nq)

    -- Output.
    local text=string.format("%s: Missions=%d, Payloads=%d (%d), Squads=%d, Assets=%s", fsmstate, Nmissions, Npayloads, #self.payloads, #self.squadrons, assets)
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
    local text="Squadrons:"
    for i,_squadron in pairs(self.squadrons) do
      local squadron=_squadron --Ops.Squadron#SQUADRON
      
      local callsign=squadron.callsignName and UTILS.GetCallsignName(squadron.callsignName) or "N/A"
      local modex=squadron.modex and squadron.modex or -1
      local skill=squadron.skill and tostring(squadron.skill) or "N/A"
      
      -- Squadron text
      text=text..string.format("\n* %s %s: %s*%d/%d, Callsign=%s, Modex=%d, Skill=%s", squadron.name, squadron:GetState(), squadron.aircrafttype, squadron:CountAssetsInStock(), #squadron.assets, callsign, modex, skill)
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
-- Stuff
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Check if mission is not over and ready to cancel.
-- @param #AIRWING self
function AIRWING:_CheckMissions()

  -- Loop over missions in queue.
  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG
    
    if mission:IsNotOver() and mission:IsReadyToCancel() then    
      mission:Cancel()
    end
  end
  
end
--- Get next mission.
-- @param #AIRWING self
-- @return Ops.Auftrag#AUFTRAG Next mission or *nil*.
function AIRWING:_GetNextMission()

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
  
  -- Look for first mission that is SCHEDULED.
  local vip=math.huge
  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG    
    if mission.importance and mission.importance<vip then
      vip=mission.importance
    end
  end
  
  -- Current time.
  local time=timer.getAbsTime()

  -- Look for first task that is not accomplished.
  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG
    
    -- Firstly, check if mission is due?
    if mission:IsQueued() and mission:IsReadyToGo() and (mission.importance==nil or mission.importance<=vip) then
        
      -- Check if airwing can do the mission and gather required assets.
      local can, assets=self:CanMission(mission)
      
      -- Check that mission is still scheduled, time has passed and enough assets are available.
       if can then        
       
        -- Optimize the asset selection. Most useful assets will come first. We do not include the payload as some assets have and some might not.
        self:_OptimizeAssetSelection(assets, mission, false)
        
        -- Assign assets to mission.
        local remove={}
        local gotpayload={}
        for i=1,#assets do
          local asset=assets[i] --#AIRWING.SquadronAsset
          
          -- Get payload for the asset.
          if not asset.payload then
            local payload=self:FetchPayloadFromStock(asset.unittype, mission.type, mission.payloads)
            if payload then
              asset.payload=payload
              table.insert(gotpayload, asset.uid)
            else
              table.insert(remove, asset.uid)
            end
          end
        end        
        self:T(self.lid..string.format("Provided %d assets with payloads. Could not get payload for %d assets", #gotpayload, #remove))
        
        -- Now remove assets for which we don't have a payload.
        for i=#assets,1,-1 do
          local asset=assets[i] --#AIRWING.SquadronAsset
          for _,uid in pairs(remove) do
            if uid==asset.uid then
              table.remove(assets, i)
            end
          end
        end
        
        -- Another check.
        if #assets<mission.nassets then
          self:E(self.lid..string.format("ERROR: Not enough payloads for mission assets! Can only do %d/%d", #assets, mission.nassets))
        end
        
        -- Optimize the asset selection. Now we include the payload performance as this could change the result.
        self:_OptimizeAssetSelection(assets, mission, true)        
      
        -- Check that mission.assets table is clean.
        if mission.assets and #mission.assets>0 then
          self:E(self.lid..string.format("ERROR: mission %s of type %s has already assets attached!", mission.name, mission.type))
        end
        mission.assets={}
      
        -- Assign assets to mission.
        for i=1,mission.nassets do
          local asset=assets[i] --#AIRWING.SquadronAsset
                    
          -- Should not happen as we just checked!
          if not asset.payload then
            self:E(self.lid.."ERROR: No payload for asset! This should not happen!")
          end
          
          -- Add asset to mission.
          mission:AddAsset(asset)
        end
        
        -- Now return the remaining payloads.
        for i=mission.nassets+1,#assets do
          local asset=assets[i] --#AIRWING.SquadronAsset
          for _,uid in pairs(gotpayload) do
            if uid==asset.uid then
              self:ReturnPayloadFromAsset(asset)
              break
            end
          end
        end
        
        return mission
      end

    end -- mission due?
  end -- mission loop

  return nil
end