---- **Ops** - Chief of Staff.
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
-- @field #number verbose Verbosity level.
-- @field #string lid Class id string for output to DCS log file.
-- @field #table targetqueue Target queue.
-- @field #table zonequeue Strategic zone queue.
-- @field Core.Set#SET_ZONE borderzoneset Set of zones defining the border of our territory.
-- @field Core.Set#SET_ZONE yellowzoneset Set of zones defining the extended border. Defcon is set to YELLOW if enemy activity is detected.
-- @field Core.Set#SET_ZONE engagezoneset Set of zones where enemies are actively engaged.
-- @field #string Defcon Defence condition.
-- @field Ops.Commander#COMMANDER commander Commander of assigned legions.
-- @extends Ops.Intelligence#INTEL

--- Be surprised!
--
-- ===
--
-- # The CHIEF Concept
-- 
-- The Chief of staff gathers INTEL and assigns missions (AUFTRAG) the airforce, army and/or navy.
--
--
-- @field #CHIEF
CHIEF = {
  ClassName      = "CHIEF",
  verbose        =     0,
  lid            =   nil,
  targetqueue    =    {},
  zonequeue      =    {},
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

--- Strategy.
-- @type CHIEF.Strategy
-- @field #string DEFENSIVE Only target in our own terretory are engaged.
-- @field #string OFFENSIVE Targets in own terretory and yellow zones are engaged.
-- @field #string AGGRESSIVE Targets in own terretroy, yellow zones and engage zones are engaged.
-- @field #string TOTALWAR Anything is engaged anywhere.
CHIEF.Strategy = {
  DEFENSIVE="Defensive",
  OFFENSIVE="Offensive",
  AGGRESSIVE="Aggressive",
  TOTALWAR="Total War"
}

--- Strategy.
-- @type CHIEF.MissionTypePerformance
-- @field #string MissionType Mission Type.
-- @field #number Performance Performance: a number between 0 and 100, where 100 is best performance.


--- Strategy.
-- @type CHIEF.MissionTypeMapping
-- @field #string Attribute Generalized attibute
-- @field #table MissionTypes 


--- CHIEF class version.
-- @field #string version
CHIEF.version="0.0.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Create a good mission, which can be passed on to the COMMANDER.
-- TODO: Capture OPSZONEs.
-- TODO: Get list of own assets and capabilities.
-- TODO: Get list/overview of enemy assets etc.
-- TODO: Put all contacts into target list. Then make missions from them.
-- TODO: Set of interesting zones.
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
-- @param #string Alias An *optional* alias how this object is called in the logs etc.
-- @return #CHIEF self
function CHIEF:New(AgentSet, Coalition, Alias)

  -- Set alias.
  Alias=Alias or "CHIEF"

  -- Inherit everything from INTEL class.
  local self=BASE:Inherit(self, INTEL:New(AgentSet, Coalition, Alias)) --#CHIEF

  -- Define zones.
  self:SetBorderZones()
  self:SetYellowZones()
  
  self:SetThreatLevelRange()
  
  -- Create a new COMMANDER.
  self.commander=COMMANDER:New()
  
  -- Init DEFCON.
  self.Defcon=CHIEF.DEFCON.GREEN

  -- Add FSM transitions.
  --                 From State   -->    Event                     -->    To State
  self:AddTransition("*",                "MissionAssignToAny",            "*")   -- Assign mission to a COMMANDER.
  
  self:AddTransition("*",                "MissionAssignToAirfore",        "*")   -- Assign mission to a COMMANDER but request only AIR assets.
  self:AddTransition("*",                "MissionAssignToNavy",           "*")   -- Assign mission to a COMMANDER but request only NAVAL assets.
  self:AddTransition("*",                "MissionAssignToArmy",           "*")   -- Assign mission to a COMMANDER but request only GROUND assets.
  
  self:AddTransition("*",                "MissionCancel",                 "*")   -- Cancel mission.
  self:AddTransition("*",                "TransportCancel",               "*")   -- Cancel transport.
  
  self:AddTransition("*",                "Defcon",                        "*")   -- Change defence condition.
  
  self:AddTransition("*",                "Stategy",                       "*")   -- Change strategy condition.
  
  self:AddTransition("*",                "DeclareWar",                    "*")   -- Declare War.

  ------------------------
  --- Pseudo Functions ---
  ------------------------

  --- Triggers the FSM event "Start".
  -- @function [parent=#CHIEF] Start
  -- @param #CHIEF self

  --- Triggers the FSM event "Start" after a delay.
  -- @function [parent=#CHIEF] __Start
  -- @param #CHIEF self
  -- @param #number delay Delay in seconds.


  --- Triggers the FSM event "Stop".
  -- @param #CHIEF self

  --- Triggers the FSM event "Stop" after a delay.
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


  --- Triggers the FSM event "MissionAssignToAny".
  -- @function [parent=#CHIEF] MissionAssignToAny
  -- @param #CHIEF self
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.

  --- Triggers the FSM event "MissionAssignToAny" after a delay.
  -- @function [parent=#CHIEF] __MissionAssignToAny
  -- @param #CHIEF self
  -- @param #number delay Delay in seconds.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.

  --- On after "MissionAssignToAny" event.
  -- @function [parent=#CHIEF] OnAfterMissionAssignToAny
  -- @param #CHIEF self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.


  --- Triggers the FSM event "MissionCancel".
  -- @function [parent=#CHIEF] MissionCancel
  -- @param #CHIEF self
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.

  --- Triggers the FSM event "MissionCancel" after a delay.
  -- @function [parent=#CHIEF] __MissionCancel
  -- @param #CHIEF self
  -- @param #number delay Delay in seconds.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.

  --- On after "MissionCancel" event.
  -- @function [parent=#CHIEF] OnAfterMissionCancel
  -- @param #CHIEF self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.Auftrag#AUFTRAG Mission The mission.


  --- Triggers the FSM event "TransportCancel".
  -- @function [parent=#CHIEF] TransportCancel
  -- @param #CHIEF self
  -- @param Ops.OpsTransport#OPSTRANSPORT Transport The transport.

  --- Triggers the FSM event "TransportCancel" after a delay.
  -- @function [parent=#CHIEF] __TransportCancel
  -- @param #CHIEF self
  -- @param #number delay Delay in seconds.
  -- @param Ops.OpsTransport#OPSTRANSPORT Transport The transport.

  --- On after "TransportCancel" event.
  -- @function [parent=#CHIEF] OnAfterTransportCancel
  -- @param #CHIEF self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Ops.OpsTransport#OPSTRANSPORT Transport The transport.

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


--- Get the commander.
-- @param #CHIEF self
-- @return Ops.Commander#COMMANDER The commander.
function CHIEF:GetCommander()
  return self.commander
end

--- Add mission to mission queue of the COMMANDER.
-- @param #CHIEF self
-- @param Ops.Auftrag#AUFTRAG Mission Mission to be added.
-- @return #CHIEF self
function CHIEF:AddMission(Mission)

  Mission.chief=self
  
  self.commander:AddMission(Mission)
  
  return self
end

--- Remove mission from queue.
-- @param #CHIEF self
-- @param Ops.Auftrag#AUFTRAG Mission Mission to be removed.
-- @return #CHIEF self
function CHIEF:RemoveMission(Mission)

  Mission.chief=nil
  
  self.commander:RemoveMission(Mission)

  return self
end

--- Add transport to transport queue of the COMMANDER.
-- @param #CHIEF self
-- @param Ops.OpsTransport#OPSTRANSPORT Transport Transport to be added.
-- @return #CHIEF self
function CHIEF:AddOpsTransport(Transport)

  Transport.chief=self
  
  self.commander:AddOpsTransport(Transport)
  
  return self
end

--- Remove transport from queue.
-- @param #CHIEF self
-- @param Ops.OpsTransport#OPSTRANSPORT Transport Transport to be removed.
-- @return #CHIEF self
function CHIEF:RemoveTransport(Transport)

  Transport.chief=nil
  
  self.commander:RemoveTransport(Transport)

  return self
end

--- Add target.
-- @param #CHIEF self
-- @param Ops.Target#TARGET Target Target object to be added.
-- @return #CHIEF self
function CHIEF:AddTarget(Target)

  Target:SetPriority()
  Target:SetImportance()

  table.insert(self.targetqueue, Target)

  return self
end

--- Add strategically important zone.
-- @param #CHIEF self
-- @param Core.Zone#ZONE_RADIUS Zone Strategic zone.
-- @return #CHIEF self
function CHIEF:AddStrateticZone(Zone)

  local opszone=OPSZONE:New(Zone, CoalitionOwner)

  table.insert(self.zonequeue, opszone)

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
  
  -- Start commander.
  if self.commander then
    if self.commander:GetState()=="NotReadyYet" then
      self.commander:Start()
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

  ---
  -- CONTACTS: Mission Cleanup
  ---

  -- Clean up missions where the contact was lost.
  for _,_contact in pairs(self.ContactsLost) do
    local contact=_contact --Ops.Intelligence#INTEL.Contact
    
    if contact.mission and contact.mission:IsNotOver() then
    
      -- Debug info.
      local text=string.format("Lost contact to target %s! %s mission %s will be cancelled.", contact.groupname, contact.mission.type:upper(), contact.mission.name)
      MESSAGE:New(text, 120, "CHIEF"):ToAll()
      self:I(self.lid..text)
    
      -- Cancel this mission.
      contact.mission:Cancel()
      
      -- TODO: contact.target
          
    end
    
  end

  ---
  -- CONTACTS: Create new TARGETS
  ---
  
  -- Create TARGETs for all new contacts.
  local Nred=0 ; local Nyellow=0 ; local Nengage=0
  for _,_contact in pairs(self.Contacts) do
    local contact=_contact    --Ops.Intelligence#INTEL.Contact
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
    
    if redalert and threat and not contact.target then
    
      local Target=TARGET:New(contact.group)
      
      self:AddTarget(Target)
      
    end
    
  end
  
  ---
  -- Defcon
  ---
  
  -- TODO: Need to introduce time check to avoid fast oscillation between different defcon states in case groups move in and out of the zones.
  if Nred>0 then
    self:SetDefcon(CHIEF.DEFCON.RED)
  elseif Nyellow>0 then
    self:SetDefcon(CHIEF.DEFCON.YELLOW)
  else
    self:SetDefcon(CHIEF.DEFCON.GREEN)
  end
  
  ---
  -- Check Target Queue
  ---
    
  -- Check target queue and assign missions to new targets.
  self:CheckTargetQueue()
  
  ---
  -- Info General
  ---  
  
  if self.verbose>=1 then
    local Nassets=self.commander:CountAssets()
    local Ncontacts=#self.Contacts
    local Nmissions=#self.commander.missionqueue
    local Ntargets=#self.targetqueue
    
    -- Info message
    local text=string.format("Defcon=%s Assets=%d, Contacts: Total=%d Yellow=%d Red=%d, Targets=%d, Missions=%d", self.Defcon, Nassets, Ncontacts, Nyellow, Nred, Ntargets, Nmissions)
    self:I(self.lid..text)
    
  end
  
  ---
  -- Info Contacts
  ---
  
  -- Info about contacts.
  if self.verbose>=2 and #self.Contacts>0 then
    local text="Contacts:"
    for i,_contact in pairs(self.Contacts) do
      local contact=_contact --Ops.Intelligence#INTEL.Contact
      local mtext="N/A"
      if contact.mission then
        mtext=string.format("Mission %s (%s) %s", contact.mission.name, contact.mission.type, contact.mission.status:upper())
      end
      text=text..string.format("\n[%d] %s Type=%s (%s): Threat=%d Mission=%s", i, contact.groupname, contact.categoryname, contact.typename, contact.threatlevel, mtext)
    end
    self:I(self.lid..text)
  end

  ---
  -- Info Targets
  ---

  if self.verbose>=3 and #self.targetqueue>0 then
    local text="Targets:"
    for i,_target in pairs(self.targetqueue) do
      local target=_target --Ops.Target#TARGET
      
      text=text..string.format("\n[%d] %s: Category=%s, prio=%d, importance=%d, alive=%s [%.1f/%.1f]",
      i, target:GetName(), target.category, target.prio, target.importance or -1, tostring(target:IsAlive()), target:GetLife(), target:GetLife0())
          
    end
    self:I(self.lid..text)
  end

  ---
  -- Info Missions
  ---
  
  -- Mission queue.
  if self.verbose>=4 and #self.commander.missionqueue>0 then
    local text="Mission queue:"
    for i,_mission in pairs(self.commander.missionqueue) do
      local mission=_mission --Ops.Auftrag#AUFTRAG
      
      local target=mission:GetTargetName() or "unknown"
      
      text=text..string.format("\n[%d] %s (%s): status=%s, target=%s", i, mission.name, mission.type, mission.status, target)
    end
    self:I(self.lid..text)
  end  

  ---
  -- Info Assets
  ---

  if self.verbose>=5 then
    local text="Assets:"
    for _,missiontype in pairs(AUFTRAG.Type) do
      local N=self.commander:CountAssets(nil, missiontype)
      if N>0 then
        text=text..string.format("\n- %s %d", missiontype, N)
      end
    end
    self:I(self.lid..text)
    
    local text="Assets:"
    for _,attribute in pairs(WAREHOUSE.Attribute) do
      local N=self.commander:CountAssets(nil, nil, attribute)
      if N>0 or self.verbose>=10 then
        text=text..string.format("\n- %s %d", attribute, N)
      end
    end
    self:I(self.lid..text)
  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Events
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after "MissionAssignToAny" event.
-- @param #CHIEF self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.Auftrag#AUFTRAG Mission The mission.
function CHIEF:onafterMissionAssignToAny(From, Event, To, Mission)

  if self.commander then
    self:I(self.lid..string.format("Assigning mission %s (%s) to COMMANDER", Mission.name, Mission.type))
    --TODO: Request only air assets.
    self.commander:AddMission(Mission)
  else
    self:E(self.lid..string.format("Mission cannot be assigned as no COMMANDER is defined!"))
  end

end

--- On after "MissionAssignToAirforce" event.
-- @param #CHIEF self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.Auftrag#AUFTRAG Mission The mission.
function CHIEF:onafterMissionAssignToAirforce(From, Event, To, Mission)

  if self.commander then
    self:I(self.lid..string.format("Assigning mission %s (%s) to COMMANDER", Mission.name, Mission.type))
    --TODO: Request only air assets.
    self.commander:AddMission(Mission)
  else
    self:E(self.lid..string.format("Mission cannot be assigned as no COMMANDER is defined!"))
  end

end

--- On after "MissionAssignToArmy" event.
-- @param #CHIEF self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.Auftrag#AUFTRAG Mission The mission.
function CHIEF:onafterMissionAssignToArmy(From, Event, To, Mission)

  if self.commander then
    self:I(self.lid..string.format("Assigning mission %s (%s) to COMMANDER", Mission.name, Mission.type))
    --TODO: Request only ground assets.
    self.commander:AddMission(Mission)
  else
    self:E(self.lid..string.format("Mission cannot be assigned as no COMMANDER is defined!"))
  end

end

--- On after "MissionCancel" event.
-- @param #CHIEF self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.Auftrag#AUFTRAG Mission The mission.
function CHIEF:onafterMissionCancel(From, Event, To, Mission)

  -- Debug info.
  self:I(self.lid..string.format("Cancelling mission %s (%s) in status %s", Mission.name, Mission.type, Mission.status))
  
  if Mission:IsPlanned() then
  
    -- Mission is still in planning stage. Should not have any LEGIONS assigned ==> Just remove it form the COMMANDER queue.
    self:RemoveMission(Mission)
    
  else
  
    -- COMMANDER will cancel mission.
    if Mission.commander then
      Mission.commander:MissionCancel(Mission)
    end
    
  end

end

--- On after "TransportCancel" event.
-- @param #CHIEF self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.OpsTransport#OPSTRANSPORT Transport The transport.
function CHIEF:onafterTransportCancel(From, Event, To, Transport)

  -- Debug info.
  self:I(self.lid..string.format("Cancelling transport UID=%d in status %s", Transport.uid, Transport:GetState()))
  
  if Transport:IsPlanned() then
  
    -- Mission is still in planning stage. Should not have any LEGIONS assigned ==> Just remove it form the COMMANDER queue.
    self:RemoveTransport(Transport)
    
  else
  
    -- COMMANDER will cancel mission.
    if Transport.commander then
      Transport.commander:TransportCancel(Transport)
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
    self:I(self.lid..string.format("Defcon %s unchanged. Not processing transition!", tostring(Defcon)))
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
-- Target Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Check target queue and assign ONE valid target by adding it to the mission queue of the COMMANDER.
-- @param #CHIEF self 
function CHIEF:CheckTargetQueue()

  -- TODO: Sort mission queue. wrt what? Threat level?

  for _,_target in pairs(self.targetqueue) do
    local target=_target --Ops.Target#TARGET

    if target:IsAlive() and not target.mission then

      -- TODO: stategry
      self.strategy=CHIEF.Strategy.TOTALWAR
    
      local valid=false
      if self.strategy==CHIEF.Strategy.DEFENSIVE then
      
        if self:CheckTargetInZones(target, self.borderzoneset) then
          valid=true
        end
      
      elseif self.strategy==CHIEF.Strategy.OFFENSIVE then
      
        if self:CheckTargetInZones(target, self.borderzoneset) or self:CheckTargetInZones(target, self.yellowzoneset) then
          valid=true
        end
      
      elseif self.strategy==CHIEF.Strategy.AGGRESSIVE then

        if self:CheckTargetInZones(target, self.borderzoneset) or self:CheckTargetInZones(target, self.yellowzoneset) or self:CheckTargetInZones(target, self.engagezoneset) then
          valid=true
        end
      
      elseif self.strategy==CHIEF.Strategy.TOTALWAR then
        valid=true
      end 
      
      -- Valid target?
      if valid then
      
        env.info("FF got valid target "..target:GetName())
              
        -- Get mission performances for the given target.  
        local MissionPerformances=self:_GetMissionPerformanceFromTarget(target)
        
        -- Mission.
        local mission=nil --Ops.Auftrag#AUFTRAG
        
        if #MissionPerformances>0 then
        
          env.info(string.format("FF found mission performance N=%d", #MissionPerformances))
        
          -- Mission Type.
          local MissionType=nil
          
          for _,_mp in pairs(MissionPerformances) do
            local mp=_mp --#CHIEF.MissionTypePerformance
            local n=self.commander:CountAssets(true, {mp.MissionType})
            env.info(string.format("FF Found N=%d assets in stock for mission type %s [Performance=%d]", n, mp.MissionType, mp.Performance))
            if n>0 then
              mission=AUFTRAG:NewFromTarget(target, mp.MissionType)              
              break
            end
          end
        
          
        end
        
        if mission then
        
          -- Set target mission entry.
          target.mission=mission
          
          -- Mission parameters.
          mission.prio=target.prio
          mission.importance=target.importance
          
          -- Add mission to COMMANDER queue.
          self:AddMission(mission)
          
          -- Only ONE target is assigned per check.
          return
        end
                
      end
          
    end
  end
  
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Resources
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

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

--- Check if group is inside a zone.
-- @param #CHIEF self
-- @param Ops.Target#TARGET target The target.
-- @param Core.Set#SET_ZONE zoneset Set of zones.
-- @return #boolean If true, group is in any zone.
function CHIEF:CheckTargetInZones(target, zoneset)

  for _,_zone in pairs(zoneset.Set or {}) do
    local zone=_zone --Core.Zone#ZONE
    
    if zone:IsCoordinateInZone(target:GetCoordinate()) then
      return true
    end
  end

  return false
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Resources
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Check resources.
-- @param #CHIEF self
-- @param Ops.Target#TARGET Target Target.
-- @return #table 
function CHIEF:CheckResources(Target)

  local objective=Target:GetObjective()
  
  local missionperformances={}
  
  for _,missionperformance in pairs(missionperformances) do
    local mp=missionperformance --#CHIEF.MissionTypePerformance
    
  
  end


end

--- Create a mission performance table.
-- @param #CHIEF self
-- @param #string MissionType Mission type.
-- @param #number Performance Performance.
-- @return #CHIEF.MissionPerformance Mission performance.
function CHIEF:_CreateMissionPerformance(MissionType, Performance)
  local mp={} --#CHIEF.MissionTypePerformance
  mp.MissionType=MissionType
  mp.Performance=Performance
  return mp
end

--- Create a mission to attack a group. Mission type is automatically chosen from the group category.
-- @param #CHIEF self
-- @param Ops.Target#TARGET Target
-- @return #table Mission performances of type #CHIEF.MissionPerformance
function CHIEF:_GetMissionPerformanceFromTarget(Target)

  local group=nil      --Wrapper.Group#GROUP
  local airbase=nil    --Wrapper.Airbase#AIRBASE
  local scenery=nil    --Wrapper.Scenery#SCENERY
  local coordinate=nil --Core.Point#COORDINATE
  
  -- Get target objective.
  local target=Target:GetObject()

  if target:IsInstanceOf("GROUP") then
    group=target --Target is already a group.  
  elseif target:IsInstanceOf("UNIT") then
    group=target:GetGroup()
  elseif target:IsInstanceOf("AIRBASE") then
    airbase=target
  elseif target:IsInstanceOf("SCENERY") then
    scenery=target
  end
 
  local TargetCategory=Target:GetCategory()
    
  local missionperf={} --#CHIEF.MissionTypePerformance
  
  if group then

    local category=group:GetCategory()
    local attribute=group:GetAttribute()

    if category==Group.Category.AIRPLANE or category==Group.Category.HELICOPTER then
    
      ---
      -- A2A: Intercept
      ---
    
      table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.INTERCEPT, 100))
    
    elseif category==Group.Category.GROUND or category==Group.Category.TRAIN then
    
      ---
      -- GROUND
      ---

      if attribute==GROUP.Attribute.GROUND_SAM then
          
        -- SEAD/DEAD
          
        table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.SEAD, 100))
        
      elseif attribute==GROUP.Attribute.GROUND_AAA then
      
        table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.BAI, 100))
        
      elseif attribute==GROUP.Attribute.GROUND_ARTILLERY then
      
        table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.BAI, 100))
        table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.BOMBING, 70))
        table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.ARTY, 30))
      
      elseif attribute==GROUP.Attribute.GROUND_INFANTRY then
      
        table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.BAI, 100))
          
      else

        table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.BAI, 100))
      
      end

    
    elseif category==Group.Category.SHIP then
    
      ---
      -- NAVAL
      ---
    
      table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.ANTISHIP, 100))
  
    else
      self:E(self.lid.."ERROR: Unknown Group category!")
    end
    
  elseif airbase then
    table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.BOMBRUNWAY, 100))   
  elseif scenery then
    table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.STRIKE, 100))
    table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.BOMBING, 70))
    table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.ARTY, 30))
  elseif coordinate then
    table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.BOMBING, 100))
    table.insert(missionperf, self:_CreateMissionPerformance(AUFTRAG.Type.ARTY, 30))
  end

  return missionperf
end

--- Check if group is inside our border.
-- @param #CHIEF self
-- @param #string Attribute Group attibute.
-- @return #table Mission types
function CHIEF:_GetMissionTypeForGroupAttribute(Attribute)

  local missiontypes={}

  if Attribute==GROUP.Attribute.AIR_ATTACKHELO then
  
    local mt={} --#CHIEF.MissionTypePerformance
    mt.MissionType=AUFTRAG.Type.INTERCEPT
    mt.Performance=100
    table.insert(missiontypes, mt)
    
  elseif Attribute==GROUP.Attribute.GROUND_AAA then
  
    local mt={} --#CHIEF.MissionTypePerformance
    mt.MissionType=AUFTRAG.Type.BAI
    mt.Performance=100        
    table.insert(missiontypes, mt)

    local mt={} --#CHIEF.MissionTypePerformance
    mt.MissionType=AUFTRAG.Type.BOMBING
    mt.Performance=70
    table.insert(missiontypes, mt)

    local mt={} --#CHIEF.MissionTypePerformance
    mt.MissionType=AUFTRAG.Type.BOMBCARPET
    mt.Performance=70
    table.insert(missiontypes, mt)

    local mt={} --#CHIEF.MissionTypePerformance
    mt.MissionType=AUFTRAG.Type.ARTY
    mt.Performance=30
    table.insert(missiontypes, mt)

  elseif Attribute==GROUP.Attribute.GROUND_SAM then
  
    local mt={} --#CHIEF.MissionTypePerformance
    mt.MissionType=AUFTRAG.Type.SEAD
    mt.Performance=100        
    table.insert(missiontypes, mt)

    local mt={} --#CHIEF.MissionTypePerformance
    mt.MissionType=AUFTRAG.Type.BAI
    mt.Performance=100        
    table.insert(missiontypes, mt)

    local mt={} --#CHIEF.MissionTypePerformance
    mt.MissionType=AUFTRAG.Type.ARTY
    mt.Performance=50
    table.insert(missiontypes, mt)

  elseif Attribute==GROUP.Attribute.GROUND_EWR then
  
    local mt={} --#CHIEF.MissionTypePerformance
    mt.MissionType=AUFTRAG.Type.SEAD
    mt.Performance=100        
    table.insert(missiontypes, mt)

    local mt={} --#CHIEF.MissionTypePerformance
    mt.MissionType=AUFTRAG.Type.BAI
    mt.Performance=100        
    table.insert(missiontypes, mt)

    local mt={} --#CHIEF.MissionTypePerformance
    mt.MissionType=AUFTRAG.Type.ARTY
    mt.Performance=50
    table.insert(missiontypes, mt)
  
    
  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------