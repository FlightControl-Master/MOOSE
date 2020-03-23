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
-- @field #table airwings Table of airwings.
-- @field #table missionqueue Mission queue.
-- @extends Ops.Intelligence#INTEL

--- Be surprised!
--
-- ===
--
-- ![Banner Image](..\Presentations\CarrierAirWing\WINGCOMMANDER_Main.jpg)
--
-- # The WINGCOMMANDER Concept
--
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

--- Contact details.
-- @type WINGCOMMANDER.Contact
-- @field Ops.Auftrag#AUFTRAG mission The assigned mission.
-- @extends Ops.Intelligence#INTEL.DetectedItem

--- WINGCOMMANDER class version.
-- @field #string version
WINGCOMMANDER.version="0.0.3"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- DONE: Add/remove spawned flightgroups to detection set.
-- TODO: Define A2A and A2G parameters. Engagedistance, etc.
-- TODO: Borderzones.
-- TODO: Improve airwing selection. Look at CAP flights near by etc.
-- TODO: Maybe it's possible to preselect the assets for the mission.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new WINGCOMMANDER object and start the FSM.
-- @param #WINGCOMMANDER self
-- @param Core.Set#SET_UNITS AgentSet Set of agents (units) providing intel. 
-- @return #WINGCOMMANDER self
function WINGCOMMANDER:New(AgentSet)

  -- Inherit everything from INTEL class.
  local self=BASE:Inherit(self, INTEL:New(AgentSet)) --#WINGCOMMANDER

  -- Set some string id for output to DCS.log file.
  self.lid=string.format("WINGCOMMANDER | ")

  -- Add FSM transitions.
  --                 From State   -->      Event           -->     To State
  self:AddTransition("*",              "MissionAssign",            "*")           -- Mission was assigned to an AIRWING.

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

  --- Triggers the FSM event "SkipperStatus" after a delay.
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

  -- Start parent INTEL.
  self:GetParent(self).onafterStart(self, From, Event, To)
  
  -- Start attached airwings.
  for _,_airwing in pairs(self.airwings) do
    local airwing=_airwing --Ops.AirWing#AIRWING
    if airwing:GetState()=="NotReadyYet" then
      airwing:Start()
    end
  end

end

--- On after "Status" event.
-- @param #WINGCOMMANDER self
-- @param Wrapper.Group#GROUP Group Flight group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function WINGCOMMANDER:onafterStatus(From, Event, To)

  -- Start parent INTEL.
  self:GetParent(self).onafterStatus(self, From, Event, To)

  -- FSM state.
  local fsmstate=self:GetState()

  
  -- Clean up missions where the contact was lost.
  for _,_contact in pairs(self.ContactsLost) do
    local contact=_contact --#WINGCOMMANDER.Contact
    
    if contact.mission and contact.mission:IsNotOver() then
    
      local text=string.format("Lost contact to target %s! %s mission %s will be cancelled.", contact.groupname, contact.mission.type:upper(), contact.mission.name)
      MESSAGE:New(text, 120, "WINGCOMMANDER"):ToAll()
      self:I(self.lid..text)
    
      -- Cancel this mission.
      contact.mission:Cancel()
          
    end
    
  end
  
 
  -- Create missions for all new contacts.
  for _,_contact in pairs(self.ContactsUnknown) do
    local contact=_contact --#WINGCOMMANDER.Contact
    local group=contact.group --Wrapper.Group#GROUP
    
    -- Create a mission based on group category.
    local mission=AUFTRAG:NewAUTO(group)
    
    
    -- Add mission to queue.
    if mission then
    
      --TODO: Better amount of necessary assets. Count units in asset and in contact. Might need nassetMin/Max.
      mission.nassets=1
      
      -- Set mission contact.
      contact.mission=mission
      
      -- Add mission to queue.
      self:AddMission(mission)
    end
  end
  
  
  -- Check mission queue and assign one PLANNED mission.
  self:CheckMissionQueue()

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

  Airwing:AddMission(Mission)

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Resources
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Check mission queue and assign ONE planned mission.
-- @param #WINGCOMMANDER self 
function WINGCOMMANDER:CheckMissionQueue()

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
        local dist=coord:Get2DDistance(airwing:GetCoordinate())
      
        -- Add airwing to table of airwings that can.
        table.insert(airwings, {airwing=airwing, dist=dist, targetcoord=coord})
        
      end
      
    end
            
  end
  
  -- Can anyone?
  if #airwings>0 then
  
    -- Sort table wrt distace
    local function sortdist(a,b)
      return a.dist<b.dist
    end
    table.sort(airwings, sortdist)    
  
    -- This is the closest airwing to the target.
    local airwing=airwings[1].airwing  --Ops.AirWing#AIRWING
    
    return airwing
  end

  return nil
end

--- Check resources.
-- @param #WINGCOMMANDER self
-- @return #table 
function WINGCOMMANDER:CheckResources()

  local capabilities={}
   
  for _,MissionType in pairs(AUFTRAG.Type) do
    capabilities[MissionType]=0
  
    for _,_airwing in pairs(self.airwings) do
      local airwing=_airwing --Ops.AirWing#AIRWING
        
      -- Get Number of assets that can do this type of missions.
      local _,assets=airwing:CanMission(MissionType)
      
      -- Add up airwing resources.
      capabilities[MissionType]=capabilities[MissionType]+#assets
    end
  
  end

  return capabilities
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
