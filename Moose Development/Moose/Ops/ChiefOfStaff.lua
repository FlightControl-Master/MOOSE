--- **Ops** - Chief of Staff.
--
-- **Main Features:**
--
--    * Stuff
--
-- ===
--
-- ### Author: **funkyfranky**
-- @module Ops.Chief
-- @image OPS_Chief.png


--- CHIEF class.
-- @type CHIEF
-- @field #string ClassName Name of the class.
-- @field #boolean Debug Debug mode. Messages to all about status.
-- @field #string lid Class id string for output to DCS log file.
-- @field #table missionqueue Mission queue.
-- @field Core.Set#SET_ZONE borderzoneset Set of zones defining the border of our territory.
-- @field Core.Set#SET_ZONE yellowzoneset Set of zones defining the extended border. Defcon is set to YELLOW if enemy activity is detected.
-- @field Core.Set#SET_ZONE engagezoneset Set of zones where enemies are actively engaged.
-- @field #string Defcon Defence condition.
-- @field Ops.WingCommander#WINGCOMMANDER wingcommander Wing commander, commanding airborne forces.
-- @field Ops.Admiral#ADMIRAL admiral Admiral commanding navy forces.
-- @field Ops.General#GENERAL genaral General commanding army forces.
-- @extends Ops.Intelligence#INTEL

--- Be surprised!
--
-- ===
--
-- ![Banner Image](..\Presentations\WingCommander\CHIEF_Main.jpg)
--
-- # The CHIEF Concept
-- 
-- The Chief of staff gathers intel and assigns missions (AUFTRAG) the airforce (WINGCOMMANDER), army (GENERAL) or navy (ADMIRAL).
-- 
-- **Note** that currently only assignments to airborne forces (WINGCOMMANDER) are implemented.
--
--
-- @field #CHIEF
CHIEF = {
  ClassName      = "CHIEF",
  Debug          =   nil,
  lid            =   nil,
  wingcommander  =   nil,
  admiral        =   nil,
  general        =   nil,
  missionqueue   =    {},
  borderzoneset  =   nil,
  yellowzoneset  =   nil,
  engagezoneset  =   nil,
}

--- Defence condition.
-- @type CHIEF.DEFCON
-- @field #string GREEN No enemy activities detected.
-- @field #string YELLOW Enemy near our border.
-- @field #string RED Enemy within our border.
CHIEF.DEFCON = {
  GREEN="Green",
  YELLOW="Yellow",
  RED="Red",
}

--- CHIEF class version.
-- @field #string version
CHIEF.version="0.0.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Define A2A and A2G parameters.
-- DONE: Add/remove spawned flightgroups to detection set.
-- DONE: Borderzones.
-- NOGO: Maybe it's possible to preselect the assets for the mission.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new CHIEF object and start the FSM.
-- @param #CHIEF self
-- @param Core.Set#SET_GROUP AgentSet Set of agents (groups) providing intel. Default is an empty set.
-- @param #number Coalition Coalition side, e.g. `coaliton.side.BLUE`. Can also be passed as a string "red", "blue" or "neutral".
-- @return #CHIEF self
function CHIEF:New(AgentSet, Coalition)

  AgentSet=AgentSet or SET_GROUP:New()

  -- Inherit everything from INTEL class.
  local self=BASE:Inherit(self, INTEL:New(AgentSet, Coalition)) --#CHIEF

  -- Set some string id for output to DCS.log file.
  --self.lid=string.format("CHIEF | ")

  self:SetBorderZones()
  self:SetYellowZones()
  
  self:SetThreatLevelRange()
  
  self.Defcon=CHIEF.DEFCON.GREEN

  -- Add FSM transitions.
  --                 From State    -->   Event             -->              To State
  self:AddTransition("*",                "AssignMissionAirforce", "*")   -- Assign mission to a WINGCOMMANDER.
  self:AddTransition("*",                "AssignMissionNavy",     "*")   -- Assign mission to an ADMIRAL.
  self:AddTransition("*",                "AssignMissionArmy",     "*")   -- Assign mission to a GENERAL.
  self:AddTransition("*",                "CancelMission",         "*")   -- Cancel mission.
  self:AddTransition("*",                "Defcon",                "*")   -- Change defence condition.
  self:AddTransition("*",                "DeclareWar",            "*")   -- Declare War.

  ------------------------
  --- Pseudo Functions ---
  ------------------------

  --- Triggers the FSM event "Start". Starts the CHIEF. Initializes parameters and starts event handlers.
  -- @function [parent=#CHIEF] Start
  -- @param #CHIEF self

  --- Triggers the FSM event "Start" after a delay. Starts the CHIEF. Initializes parameters and starts event handlers.
  -- @function [parent=#CHIEF] __Start
  -- @param #CHIEF self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Stop". Stops the CHIEF and all its event handlers.
  -- @param #CHIEF self

  --- Triggers the FSM event "Stop" after a delay. Stops the CHIEF and all its event handlers.
  -- @function [parent=#CHIEF] __Stop
  -- @param #CHIEF self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Status".
  -- @function [parent=#CHIEF] Status
  -- @param #CHIEF self

  --- Triggers the FSM event "Status" after a delay.
  -- @function [parent=#CHIEF] __Status
  -- @param #CHIEF self
  -- @param #number delay Delay in seconds.


  -- Debug trace.
  if false then
    self.Debug=true
    BASE:TraceOnOff(true)
    BASE:TraceClass(self.ClassName)
    BASE:TraceLevel(1)
  end

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set this to be an air-to-any dispatcher, i.e. engaging air, ground and naval targets. This is the default anyway.
-- @param #CHIEF self
-- @return #CHIEF self
function CHIEF:SetAirToAny()

  self:SetFilterCategory({})
  
  return self
end

--- Set this to be an air-to-air dispatcher.
-- @param #CHIEF self
-- @return #CHIEF self
function CHIEF:SetAirToAir()

  self:SetFilterCategory({Unit.Category.AIRPLANE, Unit.Category.HELICOPTER})
  
  return self
end

--- Set this to be an air-to-ground dispatcher, i.e. engage only ground units
-- @param #CHIEF self
-- @return #CHIEF self
function CHIEF:SetAirToGround()

  self:SetFilterCategory({Unit.Category.GROUND_UNIT})
  
  return self
end

--- Set this to be an air-to-sea dispatcher, i.e. engage only naval units.
-- @param #CHIEF self
-- @return #CHIEF self
function CHIEF:SetAirToSea()

  self:SetFilterCategory({Unit.Category.SHIP})
  
  return self
end

--- Set this to be an air-to-surface dispatcher, i.e. engaging ground and naval groups.
-- @param #CHIEF self
-- @return #CHIEF self
function CHIEF:SetAirToSurface()

  self:SetFilterCategory({Unit.Category.GROUND_UNIT, Unit.Category.SHIP})
  
  return self
end

--- Set a threat level range that will be engaged. Threat level is a number between 0 and 10, where 10 is a very dangerous threat.
-- Targets with threat level 0 are usually harmless.
-- @param #CHIEF self
-- @param #number ThreatLevelMin Min threat level. Default 1.
-- @param #number ThreatLevelMax Max threat level. Default 10.
-- @return #CHIEF self
function CHIEF:SetThreatLevelRange(ThreatLevelMin, ThreatLevelMax)

  self.threatLevelMin=ThreatLevelMin or 1
  self.threatLevelMax=ThreatLevelMax or 10
  
  return self
end

--- Set defence condition.
-- @param #CHIEF self
-- @param #string Defcon Defence condition. See @{#CHIEF.DEFCON}, e.g. `CHIEF.DEFCON.RED`.
-- @return #CHIEF self
function CHIEF:SetDefcon(Defcon)

  self.Defcon=Defcon
  --self:Defcon(Defcon)
  
  return self
end


--- Set the wing commander for the airforce.
-- @param #CHIEF self
-- @param Ops.WingCommander#WINGCOMMANDER WingCommander The WINGCOMMANDER object.
-- @return #CHIEF self
function CHIEF:SetWingCommander(WingCommander)

  self.wingcommander=WingCommander
  
  self.wingcommander.chief=self
  
  return self
end

--- Add mission to mission queue.
-- @param #CHIEF self
-- @param Ops.Auftrag#AUFTRAG Mission Mission to be added.
-- @return #CHIEF self
function CHIEF:AddMission(Mission)

  table.insert(self.missionqueue, Mission)

  return self
end

--- Remove mission from queue.
-- @param #CHIEF self
-- @param Ops.Auftrag#AUFTRAG Mission Mission to be removed.
-- @return #CHIEF self
function CHIEF:RemoveMission(Mission)

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
-- @param #CHIEF self
-- @param Core.Set#SET_ZONE BorderZoneSet Set of zones, defining our borders.
-- @return #CHIEF self
function CHIEF:SetBorderZones(BorderZoneSet)

  -- Border zones.
  self.borderzoneset=BorderZoneSet or SET_ZONE:New()
  
  return self
end

--- Add a zone defining your territory.
-- @param #CHIEF self
-- @param Core.Zone#ZONE BorderZone The zone defining the border of your territory.
-- @return #CHIEF self
function CHIEF:AddBorderZone(BorderZone)

  -- Add a border zone.
  self.borderzoneset:AddZone(BorderZone)
  
  return self
end

--- Set yellow zone set. Detected enemy troops in this zone will trigger defence condition YELLOW.
-- @param #CHIEF self
-- @param Core.Set#SET_ZONE YellowZoneSet Set of zones, defining our borders.
-- @return #CHIEF self
function CHIEF:SetYellowZones(YellowZoneSet)

  -- Border zones.
  self.yellowzoneset=YellowZoneSet or SET_ZONE:New()
  
  return self
end

--- Add a zone defining an area outside your territory that is monitored for enemy activity.
-- @param #CHIEF self
-- @param Core.Zone#ZONE YellowZone The zone defining the border of your territory.
-- @return #CHIEF self
function CHIEF:AddYellowZone(YellowZone)

  -- Add a border zone.
  self.yellowzoneset:AddZone(YellowZone)
  
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Start & Status
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after Start event.
-- @param #CHIEF self
-- @param Wrapper.Group#GROUP Group Flight group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function CHIEF:onafterStart(From, Event, To)

  -- Short info.
  local text=string.format("Starting Chief of Staff")
  self:I(self.lid..text)

  -- Start parent INTEL.
  self:GetParent(self).onafterStart(self, From, Event, To)
  
  -- Start wingcommander.
  if self.wingcommander then
    if self.wingcommander:GetState()=="NotReadyYet" then
      self.wingcommander:Start()
    end
  end

end

--- On after "Status" event.
-- @param #CHIEF self
-- @param Wrapper.Group#GROUP Group Flight group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function CHIEF:onafterStatus(From, Event, To)

  -- Start parent INTEL.
  self:GetParent(self).onafterStatus(self, From, Event, To)

  -- FSM state.
  local fsmstate=self:GetState()

  
  -- Clean up missions where the contact was lost.
  for _,_contact in pairs(self.ContactsLost) do
    local contact=_contact --#INTEL.Contact
    
    if contact.mission and contact.mission:IsNotOver() then
    
      local text=string.format("Lost contact to target %s! %s mission %s will be cancelled.", contact.groupname, contact.mission.type:upper(), contact.mission.name)
      MESSAGE:New(text, 120, "CHIEF"):ToAll()
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
    local contact=_contact --#CHIEF.Contact
    local group=contact.group --Wrapper.Group#GROUP
    
    local inred=self:CheckGroupInBorder(group)
    if inred then
      Nred=Nred+1
    end
    
    local inyellow=self:CheckGroupInYellow(group)
    if inyellow then
      Nyellow=Nyellow+1
    end
    
    -- Is this a threat?
    local threat=contact.threatlevel>=self.threatLevelMin and contact.threatlevel<=self.threatLevelMax
    
    local redalert=true
    if self.borderzoneset:Count()>0 then
      redalert=inred
    end
    
    if redalert and threat and not contact.mission then
    
      -- Create a mission based on group category.
      local mission=AUFTRAG:NewAUTO(group)      
      
      -- Add mission to queue.
      if mission then
      
        --TODO: Better amount of necessary assets. Count units in asset and in contact. Might need nassetMin/Max.
        mission.nassets=1
        
        -- Missons are repeated max 3 times on failure.
        mission.NrepeatFailure=3
        
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
    self:SetDefcon(CHIEF.DEFCON.RED)
  elseif Nyellow>0 then
    self:SetDefcon(CHIEF.DEFCON.YELLOW)
  else
    self:SetDefcon(CHIEF.DEFCON.GREEN)
  end
  
  
  -- Check mission queue and assign one PLANNED mission.
  self:CheckMissionQueue()
  
  local text=string.format("Defcon=%s   Missions=%d   Contacts: Total=%d Yellow=%d Red=%d", self.Defcon, #self.missionqueue, #self.Contacts, Nyellow, Nred)
  self:I(self.lid..text)
  
  -- Infor about contacts.
  if #self.Contacts>0 then
    local text="Contacts:"
    for i,_contact in pairs(self.Contacts) do
      local contact=_contact --#CHIEF.Contact
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

--- On after "AssignMissionAssignAirforce" event.
-- @param #CHIEF self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.Auftrag#AUFTRAG Mission The mission.
function CHIEF:onafterAssignMissionAirforce(From, Event, To, Mission)

  if self.wingcommander then
    self:I(self.lid..string.format("Assigning mission %s (%s) to WINGCOMMANDER", Mission.name, Mission.type))
    self.wingcommander:AddMission(Mission)
  else
    self:E(self.lid..string.format("Mission cannot be assigned as no WINGCOMMANDER is defined."))
  end

end

--- On after "CancelMission" event.
-- @param #CHIEF self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.Auftrag#AUFTRAG Mission The mission.
function CHIEF:onafterCancelMission(From, Event, To, Mission)

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
-- @param #CHIEF self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #string Defcon New defence condition.
function CHIEF:onbeforeDefcon(From, Event, To, Defcon)

  local gotit=false
  for _,defcon in pairs(CHIEF.DEFCON) do
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
-- @param #CHIEF self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #string Defcon New defence condition.
function CHIEF:onafterDefcon(From, Event, To, Defcon)
  self:I(self.lid..string.format("Changing Defcon from %s --> %s", self.Defcon, Defcon))
  
  -- Set new defcon.
  self.Defcon=Defcon
end

--- On after "DeclareWar" event.
-- @param #CHIEF self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #CHIEF Chief The Chief we declared war on.
function CHIEF:onafterDeclareWar(From, Event, To, Chief)

  if Chief then
    self:AddWarOnChief(Chief)
  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Resources
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Check mission queue and assign ONE planned mission.
-- @param #CHIEF self 
function CHIEF:CheckMissionQueue()

  -- TODO: Sort mission queue. wrt what? Threat level?

  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG
    
    -- We look for PLANNED missions.
    if mission.status==AUFTRAG.Status.PLANNED then
    
      ---
      -- PLANNNED Mission
      ---
    
      -- Check if there is an airwing that can do the mission.
      local airwing=self:GetAirwingForMission(mission)
        
      if airwing then
      
        -- Add mission to airwing.
        self:AssignMissionAirforce(mission)
    
        return
        
      else
        self:T(self.lid.."NO airwing")
      end
      
    else

      ---
      -- Missions NOT in PLANNED state
      ---    
    
    end
  
  end
  
end

--- Check all airwings if they are able to do a specific mission type at a certain location with a given number of assets.
-- @param #CHIEF self
-- @param Ops.Auftrag#AUFTRAG Mission The mission.
-- @return Ops.AirWing#AIRWING The airwing best for this mission.
function CHIEF:GetAirwingForMission(Mission)

  if self.wingcommander then
    return self.wingcommander:GetAirwingForMission(Mission)
  end

  return nil
end

--- Check if group is inside our border.
-- @param #CHIEF self
-- @param Wrapper.Group#GROUP group The group.
-- @return #boolean If true, group is in any zone.
function CHIEF:CheckGroupInBorder(group)

  local inside=self:CheckGroupInZones(group, self.borderzoneset)

  return inside
end

--- Check if group is near our border (yellow zone).
-- @param #CHIEF self
-- @param Wrapper.Group#GROUP group The group.
-- @return #boolean If true, group is in any zone.
function CHIEF:CheckGroupInYellow(group)

  -- Check inside yellow but not inside our border.
  local inside=self:CheckGroupInZones(group, self.yellowzoneset) and not self:CheckGroupInZones(group, self.borderzoneset)

  return inside
end

--- Check if group is inside a zone.
-- @param #CHIEF self
-- @param Wrapper.Group#GROUP group The group.
-- @param Core.Set#SET_ZONE zoneset Set of zones.
-- @return #boolean If true, group is in any zone.
function CHIEF:CheckGroupInZones(group, zoneset)

  for _,_zone in pairs(zoneset.Set or {}) do
    local zone=_zone --Core.Zone#ZONE
    
    if group:IsPartlyOrCompletelyInZone(zone) then
      return true
    end
  end

  return false
end

--- Check resources.
-- @param #CHIEF self
-- @return #table 
function CHIEF:CheckResources()

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