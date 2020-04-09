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
-- @field Core.Set#SET_ZONE borderzoneset Set of zones defining the border of our territory.
-- @field Core.Set#SET_ZONE yellowzoneset Set of zones defining the extended border. Defcon is set to YELLOW if enemy activity is detected.
-- @field Core.Set#SET_ZONE engagezoneset Set of zones defining the extended border. Defcon is set to YELLOW if enemy activity is detected.
-- @field #string Defcon Defence condition.
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
  borderzoneset  =   nil,
  yellowzoneset  =   nil,
  engagezoneset  =   nil,
}

--- Contact details.
-- @type WINGCOMMANDER.Contact
-- @field Ops.Auftrag#AUFTRAG mission The assigned mission.
-- @extends Ops.Intelligence#INTEL.DetectedItem

--- Defence condition.
-- @type WINGCOMMANDER.DEFCON
-- @field #string GREEN No enemy activities detected.
-- @field #string YELLOW Enemy near our border.
-- @field #string RED Enemy within our border.
WINGCOMMANDER.DEFCON = {
  GREEN="Green",
  YELLOW="Yellow",
  RED="Red",
}

--- WINGCOMMANDER class version.
-- @field #string version
WINGCOMMANDER.version="0.0.3"

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
-- @param Core.Set#SET_GROUP AgentSet Set of agents (groups) providing intel. Default is an empty set.
-- @param #number Coalition Coalition side, e.g. `coaliton.side.BLUE`. Can also be passed as a string "red", "blue" or "neutral".
-- @return #WINGCOMMANDER self
function WINGCOMMANDER:New(AgentSet, Coalition)

  AgentSet=AgentSet or SET_GROUP:New()

  -- Inherit everything from INTEL class.
  local self=BASE:Inherit(self, INTEL:New(AgentSet, Coalition)) --#WINGCOMMANDER

  -- Set some string id for output to DCS.log file.
  --self.lid=string.format("WINGCOMMANDER | ")

  self:SetBorderZones()
  self:SetYellowZones()
  
  self:SetThreatLevelRange()
  
  self.Defcon=WINGCOMMANDER.DEFCON.GREEN

  -- Add FSM transitions.
  --                 From State   -->      Event           -->     To State
  self:AddTransition("*",              "MissionAssign",            "*")           -- Mission was assigned to an AIRWING.
  self:AddTransition("*",              "CancelMission",            "*")           -- Cancel mission.
  self:AddTransition("*",              "Defcon",                   "*")           -- Cancel mission.

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

--- Set this to be an air-to-any dispatcher, i.e. engaging air, ground and navel targets. This is the default anyway.
-- @param #WINGCOMMANDER self
-- @return #WINGCOMMANDER self
function WINGCOMMANDER:SetAirToAny()

  self:SetFilterCategory({})
  
  return self
end

--- Set this to be an air-to-air dispatcher.
-- @param #WINGCOMMANDER self
-- @return #WINGCOMMANDER self
function WINGCOMMANDER:SetAirToAir()

  self:SetFilterCategory({Unit.Category.AIRPLANE, Unit.Category.HELICOPTER})
  
  return self
end

--- Set this to be an air-to-ground dispatcher, i.e. engage only ground units
-- @param #WINGCOMMANDER self
-- @return #WINGCOMMANDER self
function WINGCOMMANDER:SetAirToGround()

  self:SetFilterCategory({Unit.Category.GROUND_UNIT})
  
  return self
end

--- Set this to be an air-to-sea dispatcher, i.e. engage only naval units.
-- @param #WINGCOMMANDER self
-- @return #WINGCOMMANDER self
function WINGCOMMANDER:SetAirToSea()

  self:SetFilterCategory({Unit.Category.SHIP})
  
  return self
end

--- Set this to be an air-to-surface dispatcher, i.e. engaging ground and naval groups.
-- @param #WINGCOMMANDER self
-- @return #WINGCOMMANDER self
function WINGCOMMANDER:SetAirToSurface()

  self:SetFilterCategory({Unit.Category.GROUND_UNIT, Unit.Category.SHIP})
  
  return self
end

--- Set a threat level range that will be engaged. Threat level is a number between 0 and 10, where 10 is a very dangerous threat.
-- Targets with threat level 0 are usually harmless.
-- @param #WINGCOMMANDER self
-- @param #number ThreatLevelMin Min threat level. Default 1.
-- @param #number ThreatLevelMax Max threat level. Default 10.
-- @return #WINGCOMMANDER self
function WINGCOMMANDER:SetThreatLevelRange(ThreatLevelMin, ThreatLevelMax)

  self.threatLevelMin=ThreatLevelMin or 1
  self.threatLevelMax=ThreatLevelMax or 10
  
  return self
end

--- Set defence condition.
-- @param #WINGCOMMANDER self
-- @param #string Defcon Defence condition. See @{#WINGCOMMANDER.DEFCON}, e.g. `WINGCOMMANDER.DEFCON.RED`.
-- @return #WINGCOMMANDER self
function WINGCOMMANDER:SetDefcon(Defcon)

  self.Defcon=Defcon
  --self:Defcon(Defcon)
  
  return self
end


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

--- Set border zone set.
-- @param #WINGCOMMANDER self
-- @param Core.Set#SET_ZONE BorderZoneSet Set of zones, defining our borders.
-- @return #WINGCOMMANDER self
function WINGCOMMANDER:SetBorderZones(BorderZoneSet)

  -- Border zones.
  self.borderzoneset=BorderZoneSet or SET_ZONE:New()
  
  return self
end

--- Add a zone defining your territory.
-- @param #WINGCOMMANDER self
-- @param Core.Zone#ZONE BorderZone The zone defining the border of your territory.
-- @return #WINGCOMMANDER self
function WINGCOMMANDER:AddBorderZone(BorderZone)

  -- Add a border zone.
  self.borderzoneset:AddZone(BorderZone)
  
  -- Set accept zone.
  --self:AddAcceptZone(BorderZone)
  
  return self
end

--- Set yellow zone set. Detected enemy troops in this zone will trigger defence condition YELLOW.
-- @param #WINGCOMMANDER self
-- @param Core.Set#SET_ZONE YellowZoneSet Set of zones, defining our borders.
-- @return #WINGCOMMANDER self
function WINGCOMMANDER:SetYellowZones(YellowZoneSet)

  -- Border zones.
  self.yellowzoneset=YellowZoneSet or SET_ZONE:New()
  
  return self
end

--- Add a zone defining an area outside your territory that is monitored for enemy activity.
-- @param #WINGCOMMANDER self
-- @param Core.Zone#ZONE YellowZone The zone defining the border of your territory.
-- @return #WINGCOMMANDER self
function WINGCOMMANDER:AddYellowZone(YellowZone)

  -- Add a border zone.
  self.yellowzoneset:AddZone(YellowZone)
  
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
  local Nred=0
  local Nyellow=0
  local Nengage=0
  for _,_contact in pairs(self.Contacts) do
    local contact=_contact --#WINGCOMMANDER.Contact
    local group=contact.group --Wrapper.Group#GROUP
    
    local inred=self:CheckGroupInBorder(group)
    if inred then
      Nred=Nred+1
    end
    
    local inyellow=self:CheckGroupInYellow(group)
    if inyellow then
      Nyellow=Nyellow+1
    end
    
    local threat=contact.threatlevel>=self.threatLevelMin and contact.threatlevel<=self.threatLevelMax
    
    if not contact.mission then
    
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
    
  end
  
  -- Set defcon.
  -- TODO: Need to introduce time check to avoid fast oscillation between different defcon states in case groups move in and out of the zones.
  if Nred>0 then
    self:SetDefcon(WINGCOMMANDER.DEFCON.RED)
  elseif Nyellow>0 then
    self:SetDefcon(WINGCOMMANDER.DEFCON.YELLOW)
  else
    self:SetDefcon(WINGCOMMANDER.DEFCON.GREEN)
  end
  
  
  -- Check mission queue and assign one PLANNED mission.
  self:CheckMissionQueue()
  
  local text=string.format("Defcon=%s   Missions=%d   Contacts: Total=%d Yellow=%d Red=%d", self.Defcon, #self.missionqueue, #self.Contacts, Nyellow, Nred)
  self:I(self.lid..text)
  
  -- Infor about contacts.
  if #self.Contacts>0 then
    local text="Contacts:"
    for i,_contact in pairs(self.Contacts) do
      local contact=_contact --#WINGCOMMANDER.Contact
      local mtext="N/A"
      if contact.mission then
        mtext=string.format("Mission %s (%s) %s", contact.mission.name, contact.mission.type, contact.mission.status:upper())
      end
      text=text..string.format("\n[%d] %s Type=%s (%s): Threat=%d Mission=%s", i, contact.groupname, contact.categoryname, contact.typename, contact.threatlevel, mtext)
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

--- On before "Defcon" event.
-- @param #WINGCOMMANDER self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #string Defcon New defence condition.
-- @param Ops.Auftrag#AUFTRAG Mission The mission.
function WINGCOMMANDER:onbeforeDefcon(From, Event, To, Defcon)

  local gotit=false
  for _,defcon in pairs(WINGCOMMANDER.DEFCON) do
    if defcon==Defcon then
      gotit=true
    end
  end
  
  if not gotit then
    self:E(self.lid..string.format("ERROR: Unknown DEFCON specified! Dont know defcon=%s", tostring(Defcon)))
    return false
  end
  
  -- Defcon did not change.
  if Defcon==self.Defcon then
    self:I(self.lid..string.format("Defcon %s unchanged. No processing transition.", tostring(Defcon)))
    return false
  end

  return true
end

--- On after "Defcon" event.
-- @param #WINGCOMMANDER self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #string Defcon New defence condition.
-- @param Ops.Auftrag#AUFTRAG Mission The mission.
function WINGCOMMANDER:onafterDefcon(From, Event, To, Defcon)
  self:I(self.lid..string.format("Changing Defcon from %s --> %s", self.Defcon, Defcon))
  
  -- Set new defcon.
  self.Defcon=Defcon
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

--- Check if group is inside our border.
-- @param #WINGCOMMANDER self
-- @param Wrapper.Group#GROUP group The group.
-- @return #boolean If true, group is in any zone.
function WINGCOMMANDER:CheckGroupInBorder(group)

  local inside=self:CheckGroupInZones(group, self.borderzoneset)

  return inside
end

--- Check if group is near our border (yellow zone).
-- @param #WINGCOMMANDER self
-- @param Wrapper.Group#GROUP group The group.
-- @return #boolean If true, group is in any zone.
function WINGCOMMANDER:CheckGroupInYellow(group)

  -- Check inside yellow but not inside our border.
  local inside=self:CheckGroupInZones(group, self.yellowzoneset) and not self:CheckGroupInZones(group, self.borderzoneset)

  return inside
end

--- Check if group is inside a zone.
-- @param #WINGCOMMANDER self
-- @param Wrapper.Group#GROUP group The group.
-- @param Core.Set#SET_ZONE zoneset Set of zones.
-- @return #boolean If true, group is in any zone.
function WINGCOMMANDER:CheckGroupInZones(group, zoneset)

  for _,_zone in pairs(zoneset.Set or {}) do
    local zone=_zone --Core.Zone#ZONE
    
    if group:IsPartlyOrCompletelyInZone(zone) then
      return true
    end
  end

  return false
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
