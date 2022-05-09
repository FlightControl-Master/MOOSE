--- **Functional** - Autolase targets in the field.
--
-- ===
-- 
-- **AUOTLASE** - Autolase targets in the field.
-- 
-- ===
-- 
-- ## Missions:
--
-- ### [Autolase](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/develop/)
-- 
-- ===
-- 
-- **Main Features:**
--
--    * Detect and lase contacts automatically
--    * Targets are lased by threat priority order
--    * Use FSM events to link functionality into your scripts
--    * Easy setup
--
-- ===
-- 
--- Spot on!
-- 
-- ===
-- 
-- # 1 Autolase concept
-- 
-- * Detect and lase contacts automatically
-- * Targets are lased by threat priority order
-- * Use FSM events to link functionality into your scripts
-- * Set laser codes and smoke colors per Recce unit
-- * Easy set-up
-- 
-- # 2 Basic usage
-- 
-- ## 2.2 Set up a group of Recce Units:
-- 
--            local FoxSet = SET_GROUP:New():FilterPrefixes("Recce"):FilterCoalitions("blue"):FilterStart()
--            
-- ## 2.3 (Optional) Set up a group of pilots, this will drive who sees the F10 menu entry:
-- 
--            local Pilotset = SET_CLIENT:New():FilterCoalitions("blue"):FilterActive(true):FilterStart()
--            
-- ## 2.4 Set up and start Autolase:
-- 
--            local autolaser = AUTOLASE:New(FoxSet,coalition.side.BLUE,"Wolfpack",Pilotset)
--            
-- ## 2.5 Example - Using a fixed laser code and color for a specific Recce unit:
-- 
--            local recce = SPAWN:New("Reaper")
--              :InitDelayOff()
--              :OnSpawnGroup(
--                function (group)
--                  local unit = group:GetUnit(1)
--                  local name = unit:GetName()
--                  autolaser:SetRecceLaserCode(name,1688)
--                  autolaser:SetRecceSmokeColor(name,SMOKECOLOR.Red)
--                end
--              )
--              :InitCleanUp(60)
--              :InitLimit(1,0)
--              :SpawnScheduled(30,0.5)
--              
-- ## 2.6 Example - Inform pilots about events:
-- 
--            autolaser:SetNotifyPilots(true) -- defaults to true, also shown if debug == true
--            -- Note - message are shown to pilots in the #SET_CLIENT only if using the pilotset option, else to the coalition.
--
--
-- ### Author: **applevangelist**
-- @module Functional.Autolase
-- @image Designation.JPG
--
-- Date: 24 Oct 2021
--
--- Class AUTOLASE
-- @type AUTOLASE
-- @field #string ClassName
-- @field #string lid
-- @field #number verbose
-- @field #string alias
-- @field #boolean debug
-- @field #string version
-- @extends Ops.Intel#INTEL

---
-- @field #AUTOLASE
AUTOLASE = {
  ClassName = "AUTOLASE",
  lid = "",
  verbose = 0,
  alias = "",
  debug = false,
}

--- Laser spot info
-- @type AUTOLASE.LaserSpot
-- @field Core.Spot#SPOT laserspot 
-- @field Wrapper.Unit#UNIT lasedunit
-- @field Wrapper.Unit#UNIT lasingunit
-- @field #number lasercode
-- @field #string location
-- @field #number timestamp
-- @field #string unitname
-- @field #string reccename
-- @field #string unittype

--- AUTOLASE class version.
-- @field #string version
AUTOLASE.version = "0.0.11"

-------------------------------------------------------------------
-- Begin Functional.Autolase.lua
-------------------------------------------------------------------

--- Constructor for a new Autolase instance.
-- @param #AUTOLASE self
-- @param Core.Set#SET_GROUP RecceSet Set of detecting and lasing units
-- @param #number Coalition Coalition side. Can also be passed as a string "red", "blue" or "neutral".
-- @param #string Alias (Optional) An alias how this object is called in the logs etc.
-- @param Core.Set#SET_CLIENT PilotSet (Optional) Set of clients for precision bombing, steering menu creation. Leave nil for a coalition-wide F10 entry and display.
-- @return #AUTOLASE self 
function AUTOLASE:New(RecceSet, Coalition, Alias, PilotSet)
  BASE:T({RecceSet, Coalition, Alias, PilotSet})
  
  -- Inherit everything from BASE class.
  local self=BASE:Inherit(self, BASE:New()) -- #AUTOLASE
  
  if Coalition and type(Coalition)=="string" then
    if Coalition=="blue" then
      self.coalition=coalition.side.BLUE
    elseif Coalition=="red" then
      self.coalition=coalition.side.RED
    elseif Coalition=="neutral" then
      self.coalition=coalition.side.NEUTRAL
    else
      self:E("ERROR: Unknown coalition in AUTOLASE!")
    end
  end
  
  -- Set alias.
  if Alias then
    self.alias=tostring(Alias)
  else
    self.alias="Lion"  
    if self.coalition then
      if self.coalition==coalition.side.RED then
        self.alias="Wolf"
      elseif self.coalition==coalition.side.BLUE then
        self.alias="Fox"
      end
    end
  end 
  
  -- inherit from INTEL
  local self=BASE:Inherit(self, INTEL:New(RecceSet, Coalition, Alias)) -- #AUTOLASE
  
  self.RecceSet = RecceSet
  self.DetectVisual = true
  self.DetectOptical = true
  self.DetectRadar = true
  self.DetectIRST = true
  self.DetectRWR = true
  self.DetectDLINK = true
  self.LaserCodes = UTILS.GenerateLaserCodes()
  self.LaseDistance = 5000
  self.LaseDuration = 300
  self.GroupsByThreat = {}
  self.UnitsByThreat = {}
  self.RecceNames = {}
  self.RecceLaserCode = {}
  self.RecceSmokeColor = {}
  self.RecceUnitNames= {}
  self.maxlasing = 4
  self.CurrentLasing = {}
  self.lasingindex = 0
  self.deadunitnotes = {}
  self.usepilotset = false
  self.reporttimeshort = 10
  self.reporttimelong = 30
  self.smoketargets = false
  self.smokecolor = SMOKECOLOR.Red
  self.notifypilots = true
  self.targetsperrecce = {}
  self.RecceUnits = {}
  self.forcecooldown = true
  self.cooldowntime = 60
  self.useSRS = false
  self.SRSPath = ""
  self.SRSFreq = 251
  self.SRSMod = radio.modulation.AM
  
  -- Set some string id for output to DCS.log file.
  self.lid=string.format("AUTOLASE %s (%s) | ", self.alias, self.coalition and UTILS.GetCoalitionName(self.coalition) or "unknown")
  
  -- Add FSM transitions.
  --                 From State  -->   Event        -->     To State
  self:AddTransition("*",             "Monitor",              "*")     -- Start FSM
  self:AddTransition("*",             "Lasing",               "*")     -- Lasing target
  self:AddTransition("*",             "TargetLost",           "*")     -- Lost target
  self:AddTransition("*",             "TargetDestroyed",      "*")     -- Target destroyed
  self:AddTransition("*",             "RecceKIA",             "*")     -- Recce KIA
  self:AddTransition("*",             "LaserTimeout",         "*")     -- Laser timed out
  self:AddTransition("*",             "Cancel",               "*")     -- Stop Autolase
  
  -- Menu Entry
  if not PilotSet then
    self.Menu = MENU_COALITION_COMMAND:New(self.coalition,"Autolase",nil,self.ShowStatus,self)
  else
    self.usepilotset = true
    self.pilotset = PilotSet
    self:HandleEvent(EVENTS.PlayerEnterAircraft)
    self:SetPilotMenu()
  end
  
  self:SetClusterAnalysis(false, false)
  
  self:__Start(2)
  self:__Monitor(math.random(5,10))
  
  return self
  
  ------------------------
  --- Pseudo Functions ---
  ------------------------
  
  --- Triggers the FSM event "Monitor".
  -- @function [parent=#AUTOLASE] Status
  -- @param #AUTOLASE self

  --- Triggers the FSM event "Monitor" after a delay.
  -- @function [parent=#AUTOLASE] __Status
  -- @param #AUTOLASE self
  -- @param #number delay Delay in seconds.
  
  --- Triggers the FSM event "Cancel".
  -- @function [parent=#AUTOLASE] Cancel
  -- @param #AUTOLASE self

  --- Triggers the FSM event "Cancel" after a delay.
  -- @function [parent=#AUTOLASE] __Cancel
  -- @param #AUTOLASE self
  -- @param #number delay Delay in seconds.
  
  --- On After "RecceKIA" event.
  -- @function [parent=#AUTOLASE] OnAfterRecceKIA
  -- @param #AUTOLASE self
  -- @param #string From The from state
  -- @param #string Event The event
  -- @param #string To The to state
  -- @param #string RecceName The lost Recce
    
  --- On After "TargetDestroyed" event.
  -- @function [parent=#AUTOLASE] OnAfterTargetDestroyed
  -- @param #AUTOLASE self
  -- @param #string From The from state
  -- @param #string Event The event
  -- @param #string To The to state
  -- @param #string UnitName The destroyed unit\'s name
  -- @param #string RecceName The Recce name lasing
  
  --- On After "TargetLost" event.
  -- @function [parent=#AUTOLASE] OnAfterTargetLost
  -- @param #AUTOLASE self
  -- @param #string From The from state
  -- @param #string Event The event
  -- @param #string To The to state
  -- @param #string UnitName The lost unit\'s name
  -- @param #string RecceName The Recce name lasing
  
  --- On After "LaserTimeout" event.
  -- @function [parent=#AUTOLASE] OnAfterLaserTimeout
  -- @param #AUTOLASE self
  -- @param #string From The from state
  -- @param #string Event The event
  -- @param #string To The to state
  -- @param #string UnitName The lost unit\'s name
  -- @param #string RecceName The Recce name lasing
  
  --- On After "Lasing" event.
  -- @function [parent=#AUTOLASE] OnAfterLasing
  -- @param #AUTOLASE self
  -- @param #string From The from state
  -- @param #string Event The event
  -- @param #string To The to state
  -- @param Functional.Autolase#AUTOLASE.LaserSpot LaserSpot The LaserSpot data table
  
end

-------------------------------------------------------------------
-- Helper Functions
-------------------------------------------------------------------

--- (Internal) Function to set pilot menu.
-- @param #AUTOLASE self
-- @return #AUTOLASE self 
function AUTOLASE:SetPilotMenu()
  if self.usepilotset then
    local pilottable = self.pilotset:GetSetObjects() or {}
    for _,_unit in pairs (pilottable) do
      local Unit = _unit -- Wrapper.Unit#UNIT
      if Unit and Unit:IsAlive() then
        local Group = Unit:GetGroup()
        local lasemenu = MENU_GROUP_COMMAND:New(Group,"Autolase Status",nil,self.ShowStatus,self,Group)
        lasemenu:Refresh()
      end
    end
  end
  return self
end

--- (Internal) Event function for new pilots.
-- @param #AUTOLASE self
-- @param Core.Event#EVENTDATA EventData
-- @return #AUTOLASE self 
function AUTOLASE:OnEventPlayerEnterAircraft(EventData)
  self:SetPilotMenu()
  return self
end

--- (Internal) Function to get a laser code by recce name
-- @param #AUTOLASE self
-- @param #string RecceName Unit(!) name of the Recce
-- @return #AUTOLASE self 
function AUTOLASE:GetLaserCode(RecceName)
  local code = 1688
  if self.RecceLaserCode[RecceName] == nil then
    code = self.LaserCodes[math.random(#self.LaserCodes)]
    self.RecceLaserCode[RecceName] = code
  else
    code = self.RecceLaserCode[RecceName]
  end
  return code
end

--- (Internal) Function to get a smoke color by recce name
-- @param #AUTOLASE self
-- @param #string RecceName Unit(!) name of the Recce
-- @return #AUTOLASE self 
function AUTOLASE:GetSmokeColor(RecceName)
  local color = self.smokecolor
  if self.RecceSmokeColor[RecceName] == nil then
    self.RecceSmokeColor[RecceName] = color
  else
    color = self.RecceSmokeColor[RecceName]
  end
  return color
end

--- (User) Function enable sending messages via SRS.
-- @param #AUTOLASE self
-- @param #boolean OnOff Switch usage on and off
-- @param #string Path Path to SRS directory, e.g. C:\\Program Files\\DCS-SimpleRadio-Standalon
-- @param #number Frequency Frequency to send, e.g. 243
-- @param #number Modulation Modulation i.e. radio.modulation.AM or radio.modulation.FM
-- @return #AUTOLASE self 
function AUTOLASE:SetUsingSRS(OnOff,Path,Frequency,Modulation)
  self.useSRS = OnOff or true
  self.SRSPath = Path or "E:\\Program Files\\DCS-SimpleRadio-Standalone"
  self.SRSFreq = Frequency or 271
  self.SRSMod = Modulation or radio.modulation.AM
  return self
end

--- (User) Function set max lasing targets
-- @param #AUTOLASE self
-- @param #number Number Max number of targets to lase at once
-- @return #AUTOLASE self 
function AUTOLASE:SetMaxLasingTargets(Number)
  self.maxlasing = Number or 4
  return self
end

--- (Internal) Function set notify pilots on events
-- @param #AUTOLASE self
-- @param #boolean OnOff Switch messaging on (true) or off (false)
-- @return #AUTOLASE self 
function AUTOLASE:SetNotifyPilots(OnOff)
  self.notifypilots = OnOff and true
  return self
end

--- (User) Function to set a specific code to a Recce.
-- @param #AUTOLASE self
-- @param #string RecceName (Unit!) Name of the Recce
-- @param #number Code The lase code
-- @return #AUTOLASE self 
function AUTOLASE:SetRecceLaserCode(RecceName, Code)
  local code = Code or 1688
  self.RecceLaserCode[RecceName] = code
  return self
end

--- (User) Function to set a specific smoke color for a Recce.
-- @param #AUTOLASE self
-- @param #string RecceName (Unit!) Name of the Recce
-- @param #number Color The color, e.g. SMOKECOLOR.Red, SMOKECOLOR.Green etc
-- @return #AUTOLASE self 
function AUTOLASE:SetRecceSmokeColor(RecceName, Color)
  local color = Color or self.smokecolor
  self.RecceSmokeColor[RecceName] = color
  return self
end

--- (User) Function to force laser cooldown and cool down time
-- @param #AUTOLASE self
-- @param #boolean OnOff Switch cool down on (true) or off (false) - defaults to true
-- @param #number Seconds Number of seconds for cooldown - dafaults to 60 seconds
-- @return #AUTOLASE self 
function AUTOLASE:SetLaserCoolDown(OnOff, Seconds)
  self.forcecooldown = OnOff and true
  self.cooldowntime = Seconds or 60
  return self
end
  
--- (User) Function to set message show times.
-- @param #AUTOLASE self
-- @param #number long Longer show time
-- @param #number short Shorter show time
-- @return #AUTOLASE self 
function AUTOLASE:SetReportingTimes(long, short)
  self.reporttimeshort = short or 10
  self.reporttimelong = long or 30
  return self
end

--- (User) Function to set lasing distance in meters and duration in seconds
-- @param #AUTOLASE self
-- @param #number Distance (Max) distance for lasing in meters - default 5000 meters
-- @param #number Duration (Max) duration for lasing in seconds - default 300 secs
-- @return #AUTOLASE self 
function AUTOLASE:SetLasingParameters(Distance, Duration)
  self.LaseDistance = Distance or 5000
  self.LaseDuration = Duration or 300
  return self
end

--- (User) Function to set smoking of targets.
-- @param #AUTOLASE self
-- @param #boolean OnOff Switch smoking on or off
-- @param #number Color Smokecolor, e.g. SMOKECOLOR.Red
-- @return #AUTOLASE self 
function AUTOLASE:SetSmokeTargets(OnOff,Color)
  self.smoketargets = OnOff
  self.smokecolor = Color or SMOKECOLOR.Red
  return self
end

--- (Internal) Function to calculate line of sight.
-- @param #AUTOLASE self
-- @param Wrapper.Unit#UNIT Unit 
-- @return #number LOS Line of sight in meters
function AUTOLASE:GetLosFromUnit(Unit)
  local lasedistance = self.LaseDistance
  local unitheight = Unit:GetHeight()
  local coord = Unit:GetCoordinate()
  local landheight = coord:GetLandHeight()
  local asl = unitheight - landheight
  if asl > 100 then
    local absquare = lasedistance^2+asl^2
    lasedistance = math.sqrt(absquare)
  end
  return lasedistance
end

--- (Internal) Function to check on lased targets.
-- @param #AUTOLASE self
-- @return #AUTOLASE self
function AUTOLASE:CleanCurrentLasing()
  local lasingtable = self.CurrentLasing
  local newtable = {}
  local newreccecount = {}
  local lasing = 0
  
  for _ind,_entry in pairs(lasingtable) do
    local entry = _entry -- #AUTOLASE.LaserSpot
    if not newreccecount[entry.reccename] then
      newreccecount[entry.reccename] = 0
    end
  end
  
  for _,_recce in pairs (self.RecceSet:GetSetObjects()) do
    local recce = _recce --Wrapper.Group#GROUP
    if recce and recce:IsAlive() then
      local unit = recce:GetUnit(1)
      local name = unit:GetName()
      if not self.RecceUnits[name] then
        self.RecceUnits[name] = { name=name, unit=unit, cooldown = false, timestamp = timer.getAbsTime() }
      end
    end
  end
  
  for _ind,_entry in pairs(lasingtable) do
    local entry = _entry -- #AUTOLASE.LaserSpot
    local valid = 0
    local reccedead = false
    local unitdead = false
    local lostsight = false
    local timeout = false
    local Tnow = timer.getAbsTime()
    -- check recce dead
    local recce = entry.lasingunit
    if recce and recce:IsAlive() then
      valid = valid + 1
    else
      reccedead = true
      self:__RecceKIA(2,entry.reccename)
    end
    -- check entry dead
    local unit = entry.lasedunit
    if unit and unit:IsAlive() == true then
      valid = valid + 1
    else
      unitdead = true
      if not self.deadunitnotes[entry.unitname] then
        self.deadunitnotes[entry.unitname] = true
        self:__TargetDestroyed(2,entry.unitname,entry.reccename)
      end
    end
    -- check entry out of sight
    if not reccedead and not unitdead then
      if self:CanLase(recce,unit) then
        valid = valid + 1
      else
        lostsight = true
        entry.laserspot:LaseOff()
        self:__TargetLost(2,entry.unitname,entry.reccename)
      end
    end
    -- check timed out
    local timestamp = entry.timestamp
    if Tnow - timestamp < self.LaseDuration and not lostsight then
      valid = valid + 1
    else
      timeout = true
      entry.laserspot:LaseOff()
      
      self.RecceUnits[entry.reccename].cooldown = true
      self.RecceUnits[entry.reccename].timestamp = timer.getAbsTime()
      
      if not lostsight then
        self:__LaserTimeout(2,entry.unitname,entry.reccename)
      end
    end
    if valid == 4 then
     self.lasingindex = self.lasingindex + 1
     newtable[self.lasingindex] = entry
     newreccecount[entry.reccename] = newreccecount[entry.reccename] + 1
     lasing = lasing + 1
    end
  end
  self.CurrentLasing = newtable
  self.targetsperrecce = newreccecount
  return lasing
end

--- (Internal) Function to show status.
-- @param #AUTOLASE self
-- @param Wrapper.Group#GROUP Group (Optional) show to a certain group
-- @return #AUTOLASE self
function AUTOLASE:ShowStatus(Group)
  local report = REPORT:New("Autolase")
  local reccetable = self.RecceSet:GetSetObjects()
  for _,_recce in pairs(reccetable) do
    if _recce and _recce:IsAlive() then
      local unit = _recce:GetUnit(1)
      local name = unit:GetName()
      local code = self:GetLaserCode(name)
      report:Add(string.format("Recce %s has code %d",name,code))
    end
  end
  local lines = 0
  for _ind,_entry in pairs(self.CurrentLasing) do
    local entry = _entry -- #AUTOLASE.LaserSpot
    local reccename = entry.reccename
    local typename = entry.unittype
    local code = entry.lasercode
    local locationstring = entry.location
    local text = string.format("%s lasing %s code %d\nat %s",reccename,typename,code,locationstring)
    report:Add(text)
    lines = lines + 1
  end
  if lines == 0 then
    report:Add("No targets!")
  end
  local reporttime = self.reporttimelong
  if lines == 0 then reporttime = self.reporttimeshort end
  if Group and Group:IsAlive() then
    local m = MESSAGE:New(report:Text(),reporttime,"Info"):ToGroup(Group)
  else
    local m = MESSAGE:New(report:Text(),reporttime,"Info"):ToCoalition(self.coalition)
  end
  return self
end

--- (Internal) Function to show messages.
-- @param #AUTOLASE self
-- @param #string Message The message to be sent
-- @param #number Duration Duration in seconds
-- @return #AUTOLASE self
function AUTOLASE:NotifyPilots(Message,Duration)
  if self.usepilotset then
    local pilotset = self.pilotset:GetSetObjects() --#table
    for _,_pilot in pairs(pilotset) do
      local pilot = _pilot -- Wrapper.Unit#UNIT
      if pilot and pilot:IsAlive() then
       local Group = pilot:GetGroup()
       local m = MESSAGE:New(Message,Duration,"Autolase"):ToGroup(Group)
      end
    end
  elseif not self.debug then
    local m = MESSAGE:New(Message,Duration,"Autolase"):ToCoalition(self.coalition)
  else
    local m = MESSAGE:New(Message,Duration,"Autolase"):ToAll()
  end
  if self.debug then self:I(Message) end
  return self
end

--- (User) Send messages via SRS.
-- @param #AUTOLASE self
-- @param #string Message The (short!) message to be sent, e.g. "Lasing target!"
-- @return #AUTOLASE self
-- @usage Step 1 - set up the radio basics **once** with
--            my_autolase:SetUsingSRS(true,"C:\\path\\SRS-Folder",251,radio.modulation.AM)
-- Step 2 - send a message, e.g.
--            function my_autolase:OnAfterLasing(From, Event, To, LaserSpot)
--                my_autolase:NotifyPilotsWithSRS("Reaper lasing new target!")
--            end
function AUTOLASE:NotifyPilotsWithSRS(Message)
  if self.useSRS then
   -- Create a SOUNDTEXT object.
   if self.debug then
     BASE:TraceOn()
     BASE:TraceClass("SOUNDTEXT")
     BASE:TraceClass("MSRS")
   end
   local path = self.SRSPath or "C:\\Program Files\\DCS-SimpleRadio-Standalone"
   local freq = self.SRSFreq or 271
   local mod = self.SRSMod or radio.modulation.AM
   local text=SOUNDTEXT:New(Message)  
   -- MOOSE SRS 
   local msrs=MSRS:New(path, freq, mod)
   -- Text-to speech with default voice after 2 seconds.
   msrs:PlaySoundText(text, 2)
  end
  if self.debug then self:I(Message) end
  return self
end

--- (Internal) Function to check if a unit is already lased.
-- @param #AUTOLASE self
-- @param #string unitname Name of the unit to check
-- @return #boolean outcome True or false
function AUTOLASE:CheckIsLased(unitname)
  local outcome = false
  for _,_laserspot in pairs(self.CurrentLasing) do
    local spot = _laserspot -- #AUTOLASE.LaserSpot
    if spot.unitname == unitname then
      outcome = true
      break
    end
  end
  return outcome
end

--- (Internal) Function to check if a unit can be lased.
-- @param #AUTOLASE self
-- @param Wrapper.Unit#UNIT Recce The Recce #UNIT
-- @param Wrapper.Unit#UNIT Unit The lased #UNIT
-- @return #boolean outcome True or false
function AUTOLASE:CanLase(Recce,Unit)
  local canlase = false
  -- cooldown?
  if Recce and Recce:IsAlive() == true then
    local name = Recce:GetName()
    local cooldown = self.RecceUnits[name].cooldown and self.forcecooldown
    if cooldown then
      local Tdiff = timer.getAbsTime() - self.RecceUnits[name].timestamp
      if Tdiff < self.cooldowntime then
        return false
      else
        self.RecceUnits[name].cooldown = false
      end
    end
    -- calculate LOS
    local reccecoord = Recce:GetCoordinate()
    local unitcoord = Unit:GetCoordinate()
    local islos = reccecoord:IsLOS(unitcoord,2.5)
    -- calculate distance
    local distance = math.floor(reccecoord:Get3DDistance(unitcoord))
    local lasedistance = self:GetLosFromUnit(Recce)
    if distance <= lasedistance and islos then
      canlase = true
    end
  end
  return canlase
end

-------------------------------------------------------------------
-- FSM Functions
-------------------------------------------------------------------

--- (Internal) FSM Function for monitoring
-- @param #AUTOLASE self
-- @param #string From The from state
-- @param #string Event The event
-- @param #string To The to state
-- @return #AUTOLASE self
function AUTOLASE:onbeforeMonitor(From, Event, To)
  self:T({From, Event, To})
  -- Check if group has detected any units.
  self:UpdateIntel()
  return self
end

--- (Internal) FSM Function for monitoring
-- @param #AUTOLASE self
-- @param #string From The from state
-- @param #string Event The event
-- @param #string To The to state
-- @return #AUTOLASE self
function AUTOLASE:onafterMonitor(From, Event, To)
  self:T({From, Event, To})

  -- Housekeeping
  local countlases = self:CleanCurrentLasing()
  
  self:SetPilotMenu()
  
  local detecteditems = self.Contacts or {} -- #table of Ops.Intelligence#INTEL.Contact
  local groupsbythreat = {}
  local report = REPORT:New("Detections")
  local lines = 0
  for _,_contact in pairs(detecteditems) do
    local contact = _contact -- Ops.Intelligence#INTEL.Contact
    local grp = contact.group
    local coord = contact.position
    local reccename = contact.recce or "none"
    local reccegrp = UNIT:FindByName(reccename)
    if reccegrp then
      local reccecoord = reccegrp:GetCoordinate()
      local distance = math.floor(reccecoord:Get3DDistance(coord))
      local text = string.format("%s of %s | Distance %d km | Threatlevel %d",contact.attribute, contact.groupname, math.floor(distance/1000), contact.threatlevel)
      report:Add(text)
      self:T(text)
      if self.debug then self:I(text) end
      lines = lines  +  1
      -- sort out groups beyond sight
      local lasedistance = self:GetLosFromUnit(reccegrp)
      if grp:IsGround() and lasedistance >= distance then
        table.insert(groupsbythreat,{contact.group,contact.threatlevel})
        self.RecceNames[contact.groupname] = contact.recce
      end
    end
  end
  
  self.GroupsByThreat = groupsbythreat
  
  if self.verbose > 2 and lines > 0 then
    local m=MESSAGE:New(report:Text(),self.reporttimeshort,"Autolase"):ToAll()
  end
  
  table.sort(self.GroupsByThreat, function(a,b)
      local aNum = a[2] -- Coin value of a
      local bNum = b[2] -- Coin value of b
      return aNum > bNum -- Return their comparisons, < for ascending, > for descending
    end)
  
  -- build table of Units
  local unitsbythreat = {}
  for _,_entry in pairs(self.GroupsByThreat) do
    local group = _entry[1] -- Wrapper.Group#GROUP
    if group and group:IsAlive() then
      local units = group:GetUnits()
      local reccename = self.RecceNames[group:GetName()]
      for _,_unit in pairs(units) do
        local unit = _unit -- Wrapper.Unit#UNIT
        if unit and unit:IsAlive() then
          local threat = unit:GetThreatLevel()
          local coord = unit:GetCoordinate()
          if threat > 0 then
            local unitname = unit:GetName()
            table.insert(unitsbythreat,{unit,threat})
            self.RecceUnitNames[unitname] = reccename
          end
        end
      end
    end
  end
  
  self.UnitsByThreat = unitsbythreat
  
  table.sort(self.UnitsByThreat, function(a,b)
      local aNum = a[2] -- Coin value of a
      local bNum = b[2] -- Coin value of b
      return aNum > bNum -- Return their comparisons, < for ascending, > for descending
    end)
  
  local unitreport = REPORT:New("Detected Units")
  
  local lines = 0 
  for _,_entry in pairs(self.UnitsByThreat) do
    local threat = _entry[2]
    local unit = _entry[1]
    local unitname = unit:GetName()
    local text = string.format("Unit %s | Threatlevel %d | Detected by %s",unitname,threat,self.RecceUnitNames[unitname])
    unitreport:Add(text)
    lines = lines + 1
    self:T(text)
    if self.debug then self:I(text) end
  end
  
  if self.verbose > 2 and lines > 0 then
    local m=MESSAGE:New(unitreport:Text(),self.reporttimeshort,"Autolase"):ToAll()
  end
  
  for _,_detectingunit in pairs(self.RecceUnits) do
    
    local reccename = _detectingunit.name
    local recce = _detectingunit.unit
    local reccecount = self.targetsperrecce[reccename] or 0
    local targets = 0
    for _,_entry in pairs(self.UnitsByThreat) do
      local unit = _entry[1] -- Wrapper.Unit#UNIT
      local unitname = unit:GetName()
      local canlase = self:CanLase(recce,unit)
      if targets+reccecount < self.maxlasing and not self:CheckIsLased(unitname) and unit:IsAlive() and canlase then
        targets = targets + 1
        local code = self:GetLaserCode(reccename)
        local spot = SPOT:New(recce)
        spot:LaseOn(unit,code,self.LaseDuration)
        local locationstring = unit:GetCoordinate():ToStringLLDDM()
        local laserspot = { -- #AUTOLASE.LaserSpot
          laserspot = spot,
          lasedunit = unit,
          lasingunit = recce,
          lasercode = code,
          location = locationstring,
          timestamp = timer.getAbsTime(),
          unitname = unitname,
          reccename = reccename,
          unittype = unit:GetTypeName(),
          }
       if self.smoketargets then
          local coord = unit:GetCoordinate()
          local color = self:GetSmokeColor(reccename)
          coord:Smoke(color)
       end
       self.lasingindex = self.lasingindex + 1 
       self.CurrentLasing[self.lasingindex] = laserspot
       self:__Lasing(2,laserspot)  
      end
    end
  end
  
  self:__Monitor(-30)
  return self
end

--- (Internal) FSM Function onbeforeRecceKIA
-- @param #AUTOLASE self
-- @param #string From The from state
-- @param #string Event The event
-- @param #string To The to state
-- @param #string RecceName The lost Recce
-- @return #AUTOLASE self
function AUTOLASE:onbeforeRecceKIA(From,Event,To,RecceName)
  self:T({From, Event, To, RecceName})
  if self.notifypilots or self.debug then
    local text = string.format("Recce %s KIA!",RecceName)
    self:NotifyPilots(text,self.reporttimeshort)
  end
  return self
end

--- (Internal) FSM Function onbeforeTargetDestroyed
-- @param #AUTOLASE self
-- @param #string From The from state
-- @param #string Event The event
-- @param #string To The to state
-- @param #string UnitName The destroyed unit\'s name
-- @param #string RecceName The Recce name lasing
-- @return #AUTOLASE self
function AUTOLASE:onbeforeTargetDestroyed(From,Event,To,UnitName,RecceName)
  self:T({From, Event, To, UnitName, RecceName})
  if self.notifypilots or self.debug then
    local text = string.format("Unit %s destroyed! Good job!",UnitName)
    self:NotifyPilots(text,self.reporttimeshort)
  end
  return self
end

--- (Internal) FSM Function onbeforeTargetLost
-- @param #AUTOLASE self
-- @param #string From The from state
-- @param #string Event The event
-- @param #string To The to state
-- @param #string UnitName The lost unit\'s name
-- @param #string RecceName The Recce name lasing
-- @return #AUTOLASE self
function AUTOLASE:onbeforeTargetLost(From,Event,To,UnitName,RecceName)
  self:T({From, Event, To, UnitName,RecceName})
  if self.notifypilots or self.debug then
    local text = string.format("%s lost sight of unit %s.",RecceName,UnitName)
    self:NotifyPilots(text,self.reporttimeshort)
  end
  return self
end

--- (Internal) FSM Function onbeforeLaserTimeout
-- @param #AUTOLASE self
-- @param #string From The from state
-- @param #string Event The event
-- @param #string To The to state
-- @param #string UnitName The lost unit\'s name
-- @param #string RecceName The Recce name lasing
-- @return #AUTOLASE self
function AUTOLASE:onbeforeLaserTimeout(From,Event,To,UnitName,RecceName)
  self:T({From, Event, To, UnitName,RecceName})
  if self.notifypilots or self.debug then
    local text = string.format("%s laser timeout on unit %s.",RecceName,UnitName)
    self:NotifyPilots(text,self.reporttimeshort)
  end
  return self
end

--- (Internal) FSM Function onbeforeLasing
-- @param #AUTOLASE self
-- @param #string From The from state
-- @param #string Event The event
-- @param #string To The to state
-- @param Functional.Autolase#AUTOLASE.LaserSpot LaserSpot The LaserSpot data table
-- @return #AUTOLASE self
function AUTOLASE:onbeforeLasing(From,Event,To,LaserSpot)
  self:T({From, Event, To, LaserSpot.unittype})
  if self.notifypilots or self.debug then
    local laserspot = LaserSpot -- #AUTOLASE.LaserSpot
    local text = string.format("%s is lasing %s code %d\nat %s",laserspot.reccename,laserspot.unittype,laserspot.lasercode,laserspot.location)
    self:NotifyPilots(text,self.reporttimeshort+5)
  end
  return self
end

--- (Internal) FSM Function onbeforeCancel
-- @param #AUTOLASE self
-- @param #string From The from state
-- @param #string Event The event
-- @param #string To The to state
-- @return #AUTOLASE self
function AUTOLASE:onbeforeCancel(From,Event,To)
  self:UnHandleEvent(EVENTS.PlayerEnterAircraft)
  self:__Stop(2)
  return self
end

-------------------------------------------------------------------
-- End Functional.Autolase.lua
-------------------------------------------------------------------
