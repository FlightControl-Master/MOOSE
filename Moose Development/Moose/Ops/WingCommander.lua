--- **Ops** - Commander Air Wing.
--
-- **Main Features:**
--
--    * Stuff
--
-- ===
--
-- ### Author: **funkyfranky**
-- @module Ops.WingCommander
-- @image OPS_WingCommander.png


--- WINGCOMMANDER class.
-- @type WINGCOMMANDER
-- @field #string ClassName Name of the class.
-- @field #boolean Debug Debug mode. Messages to all about status.
-- @field #string lid Class id string for output to DCS log file.
-- @field #table airwings Table of airwings which are commanded.
-- @field #table missionqueue Mission queue.
-- @field Ops.ChiefOfStaff#CHIEF chief Chief of staff.
-- @extends Core.Fsm#FSM

--- Be surprised!
--
-- ===
--
-- ![Banner Image](..\Presentations\WingCommander\WINGCOMMANDER_Main.jpg)
--
-- # The WINGCOMMANDER Concept
-- 
-- A wing commander is the head of airwings. He will find the best AIRWING to perform an assigned AUFTRAG (mission).
--
--
-- @field #WINGCOMMANDER
WINGCOMMANDER = {
  ClassName      = "WINGCOMMANDER",
  Debug          =   nil,
  lid            =   nil,
  airwings       =    {},
  missionqueue   =    {},
}

--- WINGCOMMANDER class version.
-- @field #string version
WINGCOMMANDER.version="0.1.0"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Define A2A and A2G parameters.
-- TODO: Improve airwing selection. Mostly done!
-- DONE: Add/remove spawned flightgroups to detection set.
-- DONE: Borderzones.
-- NOGO: Maybe it's possible to preselect the assets for the mission.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new WINGCOMMANDER object and start the FSM.
-- @param #WINGCOMMANDER self
-- @return #WINGCOMMANDER self
function WINGCOMMANDER:New()

  -- Inherit everything from INTEL class.
  local self=BASE:Inherit(self, FSM:New()) --#WINGCOMMANDER
  
  self.lid="WINGCOMMANDER | "

  -- Start state.
  self:SetStartState("NotReadyYet")

  -- Add FSM transitions.
  --                 From State     -->      Event        -->     To State
  self:AddTransition("NotReadyYet",        "Start",               "OnDuty")      -- Start WC.
  self:AddTransition("*",                  "Status",              "*")           -- Status report.
  self:AddTransition("*",                  "MissionAssign",       "*")           -- Mission was assigned to an AIRWING.
  self:AddTransition("*",                  "CancelMission",       "*")           -- Cancel mission.
  self:AddTransition("*",                  "Defcon",              "*")           -- Cancel mission.

  ------------------------
  --- Pseudo Functions ---
  ------------------------

  --- Triggers the FSM event "Start". Starts the WINGCOMMANDER. Initializes parameters and starts event handlers.
  -- @function [parent=#WINGCOMMANDER] Start
  -- @param #WINGCOMMANDER self

  --- Triggers the FSM event "Start" after a delay. Starts the WINGCOMMANDER. Initializes parameters and starts event handlers.
  -- @function [parent=#WINGCOMMANDER] __Start
  -- @param #WINGCOMMANDER self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Stop". Stops the WINGCOMMANDER and all its event handlers.
  -- @param #WINGCOMMANDER self

  --- Triggers the FSM event "Stop" after a delay. Stops the WINGCOMMANDER and all its event handlers.
  -- @function [parent=#WINGCOMMANDER] __Stop
  -- @param #WINGCOMMANDER self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Status".
  -- @function [parent=#WINGCOMMANDER] Status
  -- @param #WINGCOMMANDER self

  --- Triggers the FSM event "Status" after a delay.
  -- @function [parent=#WINGCOMMANDER] __Status
  -- @param #WINGCOMMANDER self
  -- @param #number delay Delay in seconds.


  -- Debug trace.
  if false then
    self.Debug=true
    BASE:TraceOnOff(true)
    BASE:TraceClass(self.ClassName)
    BASE:TraceLevel(1)
  end
  self.Debug=true

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Add an airwing to the wingcommander.
-- @param #WINGCOMMANDER self
-- @param Ops.AirWing#AIRWING Airwing The airwing to add.
-- @return #WINGCOMMANDER self
function WINGCOMMANDER:AddAirwing(Airwing)

  -- This airwing is managed by this wing commander. 
  Airwing.wingcommander=self

  table.insert(self.airwings, Airwing)  
  
  return self
end

--- Add mission to mission queue.
-- @param #WINGCOMMANDER self
-- @param Ops.Auftrag#AUFTRAG Mission Mission to be added.
-- @return #WINGCOMMANDER self
function WINGCOMMANDER:AddMission(Mission)

  Mission.wingcommander=self

  table.insert(self.missionqueue, Mission)

  return self
end

--- Remove mission from queue.
-- @param #WINGCOMMANDER self
-- @param Ops.Auftrag#AUFTRAG Mission Mission to be removed.
-- @return #WINGCOMMANDER self
function WINGCOMMANDER:RemoveMission(Mission)

  for i,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG
    
    if mission.auftragsnummer==Mission.auftragsnummer then
      self:I(self.lid..string.format("Removing mission %s (%s) status=%s from queue", Mission.name, Mission.type, Mission.status))
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
-- @param #WINGCOMMANDER self
-- @param Wrapper.Group#GROUP Group Flight group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function WINGCOMMANDER:onafterStart(From, Event, To)

  -- Short info.
  local text=string.format("Starting Wing Commander")
  self:I(self.lid..text)
  
  -- Start attached airwings.
  for _,_airwing in pairs(self.airwings) do
    local airwing=_airwing --Ops.AirWing#AIRWING
    if airwing:GetState()=="NotReadyYet" then
      airwing:Start()
    end
  end

  self:__Status(-1)
end

--- On after "Status" event.
-- @param #WINGCOMMANDER self
-- @param Wrapper.Group#GROUP Group Flight group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function WINGCOMMANDER:onafterStatus(From, Event, To)

  -- FSM state.
  local fsmstate=self:GetState()

  -- Check mission queue and assign one PLANNED mission.
  self:CheckMissionQueue()
  
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

--- On after "MissionAssign" event. Mission is added to the AIRWING mission queue.
-- @param #WINGCOMMANDER self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.AirWing#AIRWING Airwing The AIRWING.
-- @param Ops.Auftrag#AUFTRAG Mission The mission.
function WINGCOMMANDER:onafterMissionAssign(From, Event, To, Airwing, Mission)

  self:I(self.lid..string.format("Assigning mission %s (%s) to airwing %s", Mission.name, Mission.type, Airwing.alias))
  Airwing:AddMission(Mission)

end

--- On after "CancelMission" event.
-- @param #WINGCOMMANDER self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.Auftrag#AUFTRAG Mission The mission.
function WINGCOMMANDER:onafterCancelMission(From, Event, To, Mission)

  self:I(self.lid..string.format("Cancelling mission %s (%s) in status %s", Mission.name, Mission.type, Mission.status))
  
  if Mission.status==AUFTRAG.Status.PLANNED then
  
    -- Mission is still in planning stage. Should not have an airbase assigned ==> Just remove it form the queue.
    self:RemoveMission(Mission)
    
  else
  
    -- Airwing will cancel mission.
    if Mission.airwing then
      Mission.airwing:MissionCancel(Mission)
    end
    
  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Resources
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Check mission queue and assign ONE planned mission.
-- @param #WINGCOMMANDER self 
function WINGCOMMANDER:CheckMissionQueue()

  -- TODO: Sort mission queue. wrt what? Threat level?

  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG
    
    -- We look for PLANNED missions.
    if mission.status==AUFTRAG.Status.PLANNED then
    
      ---
      -- PLANNNED Mission
      ---
    
      local airwing=self:GetAirwingForMission(mission)
        
      if airwing then
      
        -- Add mission to airwing.
        self:MissionAssign(airwing, mission)
    
        return
      end
      
    else

      ---
      -- Missions NOT in PLANNED state
      ---    
    
    end
  
  end
  
end

--- Check all airwings if they are able to do a specific mission type at a certain location with a given number of assets.
-- @param #WINGCOMMANDER self
-- @param Ops.Auftrag#AUFTRAG Mission The mission.
-- @return Ops.AirWing#AIRWING The airwing best for this mission.
function WINGCOMMANDER:GetAirwingForMission(Mission)

  -- Table of airwings that can do the mission.
  local airwings={}
  
  -- Loop over all airwings.
  for _,_airwing in pairs(self.airwings) do
    local airwing=_airwing --Ops.AirWing#AIRWING
    
    -- Check if airwing can do this mission.
    local can,assets=airwing:CanMission(Mission)
    
    -- Can it?
    if can then        
      
      -- Get coordinate of the target.
      local coord=Mission:GetTargetCoordinate()
      
      if coord then
      
        -- Distance from airwing to target.
        local dist=UTILS.MetersToNM(coord:Get2DDistance(airwing:GetCoordinate()))
      
        -- Add airwing to table of airwings that can.
        table.insert(airwings, {airwing=airwing, dist=dist, targetcoord=coord, nassets=#assets})
        
      end
      
    end
            
  end
  
  -- Can anyone?
  if #airwings>0 then
  
    --- Something like:
    -- * Closest airwing that can should be first prio.
    -- * However, there should be a certain "quantization". if wing is 50 or 60 NM way should not really matter. In that case, the airwing with more resources should get the job.
    local function score(a)
      local d=math.round(a.dist/10)
    end
  
    -- Sort table wrt distance and number of assets.
    -- Distances within 10 NM are equal and the airwing with more assets is preferred.
    local function sortdist(a,b)
      local ad=math.round(a.dist/10)  -- dist 55 NM ==> 5.5 ==> 6
      local bd=math.round(b.dist/10)  -- dist 63 NM ==> 6.3 ==> 6
      return ad<bd or (ad==bd and a.nassets>b.nassets)
    end
    table.sort(airwings, sortdist)    
  
    -- This is the closest airwing to the target.
    local airwing=airwings[1].airwing  --Ops.AirWing#AIRWING
    
    return airwing
  end

  return nil
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
