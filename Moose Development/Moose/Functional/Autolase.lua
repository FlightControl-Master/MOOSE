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
-- None yet.
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
-- Last Update: Mar 2025
--
--- Class AUTOLASE
-- @type AUTOLASE
-- @field #string ClassName
-- @field #string lid
-- @field #number verbose
-- @field #string alias
-- @field #boolean debug
-- @field #string version
-- @field Core.Set#SET_GROUP RecceSet
-- @field #table LaserCodes
-- @field #table playermenus
-- @field #boolean smokemenu
-- @field #boolean threatmenu
-- @field #number RoundingPrecision
-- @field #table smokeoffset
-- @field #boolean increasegroundawareness
-- @field #number MonitorFrequency
-- @extends Ops.Intel#INTEL

---
-- @field #AUTOLASE
AUTOLASE = {
  ClassName = "AUTOLASE",
  lid = "",
  verbose = 0,
  alias = "",
  debug = false,
  smokemenu = true,
  RoundingPrecision = 0,
  increasegroundawareness = false,
  MonitorFrequency = 30,
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
-- @field Core.Point#COORDINATE coordinate


--- AUTOLASE class version.
-- @field #string version
AUTOLASE.version = "0.1.31"

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
  self.smokeoffset = nil
  self.notifypilots = true
  self.targetsperrecce = {}
  self.RecceUnits = {}
  self.forcecooldown = true
  self.cooldowntime = 60
  self.useSRS = false
  self.SRSPath = ""
  self.SRSFreq = 251
  self.SRSMod = radio.modulation.AM
  self.NoMenus = false
  self.minthreatlevel = 0
  self.blacklistattributes = {}
  self:SetLaserCodes( { 1688, 1130, 4785, 6547, 1465, 4578 } ) -- set self.LaserCodes
  self.playermenus = {}
  self.smokemenu = true
  self.threatmenu = true
  self.RoundingPrecision = 0
  self.increasegroundawareness = false
  self.MonitorFrequency = 30
  
  self:EnableSmokeMenu({Angle=math.random(0,359),Distance=math.random(10,20)})
  
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
  if PilotSet then
    self.usepilotset = true
    self.pilotset = PilotSet
    self:HandleEvent(EVENTS.PlayerEnterAircraft,self._EventHandler)
    --self:SetPilotMenu()
  end
  --self.SetPilotMenu()
  
  
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

--- [User] When using Monitor, set the frequency here in which the report will appear
-- @param #AUTOLASE self
-- @param #number Seconds Run the report loop every number of seconds defined here.
-- @return #AUTOLASE self
function AUTOLASE:SetMonitorFrequency(Seconds)
  self.MonitorFrequency = Seconds or 30
  return self
end

--- [User] Set a table of possible laser codes.
-- Each new RECCE can select a code from this table, default is { 1688, 1130, 4785, 6547, 1465, 4578 }.
-- @param #AUTOLASE self
-- @param #list<#number> LaserCodes
-- @return #AUTOLASE self
function AUTOLASE:SetLaserCodes( LaserCodes )
  self.LaserCodes = ( type( LaserCodes ) == "table" ) and LaserCodes or { LaserCodes }
  return self
end

--- [User] Improve ground unit detection by using a zone scan and LOS check.
-- @param #AUTOLASE self
-- @return #AUTOLASE self 
function AUTOLASE:EnableImproveGroundUnitsDetection()
  self.increasegroundawareness = true
  return self
end

--- [User] Do not improve ground unit detection by using a zone scan and LOS check.
-- @param #AUTOLASE self
-- @return #AUTOLASE self 
function AUTOLASE:DisableImproveGroundUnitsDetection()
  self.increasegroundawareness = false
  return self
end

--- (Internal) Function to set pilot menu.
-- @param #AUTOLASE self
-- @return #AUTOLASE self 
function AUTOLASE:SetPilotMenu()
  if self.usepilotset then
    local pilottable = self.pilotset:GetSetObjects() or {}
    local grouptable = {}
    for _,_unit in pairs (pilottable) do
      local Unit = _unit -- Wrapper.Unit#UNIT
      if Unit and Unit:IsAlive() then
        local Group = Unit:GetGroup()
        local GroupName = Group:GetName() or "none"
        local unitname = Unit:GetName()
        if not grouptable[GroupName] == true then
          if self.playermenus[unitname] then self.playermenus[unitname]:Remove() end -- menus
          local lasetopm = MENU_GROUP:New(Group,"Autolase",nil)
          self.playermenus[unitname] = lasetopm
          local lasemenu = MENU_GROUP_COMMAND:New(Group,"Status",lasetopm,self.ShowStatus,self,Group,Unit)
          if self.smokemenu then
            local smoke = (self.smoketargets == true) and "off" or "on"
            local smoketext = string.format("Switch smoke targets to %s",smoke)
            local smokemenu = MENU_GROUP_COMMAND:New(Group,smoketext,lasetopm,self.SetSmokeTargets,self,(not self.smoketargets))
          end -- smokement
         if self.threatmenu then
             local threatmenutop = MENU_GROUP:New(Group,"Set min lasing threat",lasetopm)
             for i=0,10,2 do
              local text = "Threatlevel "..tostring(i)
              local threatmenu = MENU_GROUP_COMMAND:New(Group,text,threatmenutop,self.SetMinThreatLevel,self,i)
             end -- threatlevel
         end -- threatmenu
          for _,_grp in pairs(self.RecceSet.Set) do
            local grp = _grp -- Wrapper.Group#GROUP
            local unit = grp:GetUnit(1)
            --local name = grp:GetName()
            if unit and unit:IsAlive() then
              local name = unit:GetName()
              local mname = string.gsub(name,".%d+.%d+$","")
              local code = self:GetLaserCode(name)
              local unittop = MENU_GROUP:New(Group,"Change laser code for "..mname,lasetopm)
              for _,_code in pairs(self.LaserCodes) do
                local text = tostring(_code)
                if _code == code then text = text.."(*)" end
                local changemenu = MENU_GROUP_COMMAND:New(Group,text,unittop,self.SetRecceLaserCode,self,name,_code,true)
              end -- Codes
            end -- unit alive
          end -- Recceset
          grouptable[GroupName] = true
        end -- grouptable[GroupName] 
        --lasemenu:Refresh()
      end -- unit alive
    end -- pilot loop
  else
    if not self.NoMenus then
      self.Menu = MENU_COALITION_COMMAND:New(self.coalition,"Autolase",nil,self.ShowStatus,self)
    end
  end
  return self
end

--- (Internal) Event function for new pilots.
-- @param #AUTOLASE self
-- @param Core.Event#EVENTDATA EventData
-- @return #AUTOLASE self 
function AUTOLASE:_EventHandler(EventData)
  self:SetPilotMenu()
  return self
end

--- (User) Set minimum threat level for target selection, can be 0 (lowest) to 10 (highest).
-- @param #AUTOLASE self
-- @param #number Level Level used for filtering, defaults to 0. SAM systems and manpads have level 7 to 10, AAA level 6, MTBs and armoured vehicles level 3 to 5, APC, Artillery, Infantry and EWR level 1 to 2.
-- @return #AUTOLASE self
-- @usage Filter for level 3 and above:
--            `myautolase:SetMinThreatLevel(3)`
function AUTOLASE:SetMinThreatLevel(Level)
  local level = Level or 0
  if level < 0 or level > 10 then level = 0 end
  self.minthreatlevel = level
  return self 
end

--- (User) Set list of #UNIT level attributes that won't be lased. For list of attributes see [Hoggit Wiki](https://wiki.hoggitworld.com/view/DCS_enum_attributes) and [GitHub](https://github.com/mrSkortch/DCS-miscScripts/tree/master/ObjectDB) 
-- @param #AUTOLASE self
-- @param #table Attributes Table of #string attributes to blacklist. Can be handed over as a single #string.
-- @return #AUTOLASE self
-- @usage To exclude e.g. manpads from being lased:
-- 
--            `myautolase:AddBlackListAttributes("MANPADS")`
-- 
-- To exclude trucks and artillery:
-- 
--            `myautolase:AddBlackListAttributes({"Trucks","Artillery"})`
--            
function AUTOLASE:AddBlackListAttributes(Attributes)
  local attributes = Attributes
  if type(attributes) ~= "table" then
    attributes = {attributes}
  end
  for _,_attr in pairs(attributes) do
    table.insert(self.blacklistattributes,_attr)
  end
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
-- @param #string Path Path to SRS TTS directory, e.g. C:\\Program Files\\DCS-SimpleRadio-Standalone\\ExternalAudio
-- @param #number Frequency Frequency to send, e.g. 243
-- @param #number Modulation Modulation i.e. radio.modulation.AM or radio.modulation.FM
-- @param #string Label (Optional) Short label to be used on the SRS Client Overlay
-- @param #string Gender (Optional) Defaults to "male"
-- @param #string Culture (Optional) Defaults to "en-US"
-- @param #number Port (Optional) Defaults to 5002
-- @param #string Voice (Optional) Use a specifc voice with the @{Sound.SRS#SetVoice} function, e.g, `:SetVoice("Microsoft Hedda Desktop")`.
-- Note that this must be installed on your windows system. Can also be Google voice types, if you are using Google TTS.
-- @param #number Volume (Optional) Volume - between 0.0 (silent) and 1.0 (loudest)
-- @param #string PathToGoogleKey (Optional) Path to your google key if you want to use google TTS
-- @return #AUTOLASE self 
function AUTOLASE:SetUsingSRS(OnOff,Path,Frequency,Modulation,Label,Gender,Culture,Port,Voice,Volume,PathToGoogleKey)
  if OnOff then
    self.useSRS = true
    self.SRSPath = Path or MSRS.path or "C:\\Program Files\\DCS-SimpleRadio-Standalone\\ExternalAudio"
    self.SRSFreq = Frequency or 271
    self.SRSMod = Modulation or radio.modulation.AM
    self.Gender = Gender or MSRS.gender or "male"
    self.Culture = Culture or MSRS.culture or "en-US"
    self.Port = Port or MSRS.port or 5002
    self.Voice = Voice 
    self.PathToGoogleKey = PathToGoogleKey
    self.Volume = Volume or 1.0
    self.Label = Label
    -- set up SRS
    self.SRS = MSRS:New(self.SRSPath,self.SRSFreq,self.SRSMod)
    self.SRS:SetCoalition(self.coalition)
    self.SRS:SetLabel(self.MenuName or self.Name)
    self.SRS:SetGender(self.Gender)
    self.SRS:SetCulture(self.Culture)
    self.SRS:SetPort(self.Port)
    self.SRS:SetVoice(self.Voice)
    self.SRS:SetCoalition(self.coalition)
    self.SRS:SetVolume(self.Volume)
    if self.PathToGoogleKey then
      self.SRS:SetProviderOptionsGoogle(PathToGoogleKey,PathToGoogleKey)
      self.SRS:SetProvider(MSRS.Provider.GOOGLE)
    end
    self.SRSQueue = MSRSQUEUE:New(self.alias)
  else
    self.useSRS = false
    self.SRS= nil
    self.SRSQueue = nil
  end
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
-- @param #boolean Refresh If true, refresh menu entries
-- @return #AUTOLASE self 
function AUTOLASE:SetRecceLaserCode(RecceName, Code, Refresh)
  local code = Code or 1688
  self.RecceLaserCode[RecceName] = code
  if Refresh then
    self:SetPilotMenu()
    if self.notifypilots then
      if string.find(RecceName,"#") then
        RecceName = string.match(RecceName,"^(.*)#")
      end
      self:NotifyPilots(string.format("Code for %s set to: %d",RecceName,Code),15)
    end
  end
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
  local smktxt = OnOff == true and "on" or "off"
  local Message = "Smoking targets is now "..smktxt.."!"
  self:NotifyPilots(Message,10)
  return self
end

--- (User) Function to set rounding precision for BR distance output.
-- @param #AUTOLASE self
-- @param #number IDP Rounding precision before/after the decimal sign. Defaults to zero. Positive values round right of the decimal sign, negative ones left of the decimal sign. 
-- @return #AUTOLASE self 
function AUTOLASE:SetRoundingPrecsion(IDP)
  self.RoundingPrecision = IDP or 0
  return self
end

--- (User) Show the "Switch smoke target..." menu entry for pilots. On by default.
-- @param #AUTOLASE self
-- @param #table Offset (Optional) Define an offset for the smoke, i.e. not directly on the unit itself, angle is degrees and distance is meters. E.g. `autolase:EnableSmokeMenu({Angle=30,Distance=20})`
-- @return #AUTOLASE self 
function AUTOLASE:EnableSmokeMenu(Offset)
  self.smokemenu = true
  if Offset then
    self.smokeoffset = {}
    self.smokeoffset.Distance = Offset.Distance or math.random(10,20)
    self.smokeoffset.Angle = Offset.Angle or math.random(0,359)
  end
  return self
end

--- (User) Do not show the "Switch smoke target..." menu entry for pilots.
-- @param #AUTOLASE self
-- @return #AUTOLASE self 
function AUTOLASE:DisableSmokeMenu()
  self.smokemenu = false
  self.smokeoffset = nil
  return self
end

--- (User) Show the "Switch min threat lasing..." menu entry for pilots. On by default.
-- @param #AUTOLASE self
-- @return #AUTOLASE self 
function AUTOLASE:EnableThreatLevelMenu()
  self.threatmenu = true
  return self
end

--- (User) Do not show the "Switch min threat lasing..." menu entry for pilots.
-- @param #AUTOLASE self
-- @return #AUTOLASE self 
function AUTOLASE:DisableThreatLevelMenu()
  self.threatmenu = false
  return self
end

--- (Internal) Function to calculate line of sight.
-- @param #AUTOLASE self
-- @param Wrapper.Unit#UNIT Unit 
-- @return #number LOS Line of sight in meters
function AUTOLASE:GetLosFromUnit(Unit)
  local lasedistance = self.LaseDistance
  local unitheight = Unit:GetHeight()
  local coord = Unit:GetCoord()
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
        local isground = (unit and unit.IsGround) and unit:IsGround() or false
        self.RecceUnits[name] = { name=name, unit=unit, cooldown = false, timestamp = timer.getAbsTime(), isground=isground }
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
-- @param Wrapper.Unit#UNIT Unit (Optional) show to a certain unit
-- @return #AUTOLASE self
function AUTOLASE:ShowStatus(Group,Unit)
  local report = REPORT:New("Autolase")
  local reccetable = self.RecceSet:GetSetObjects()
  for _,_recce in pairs(reccetable) do
    if _recce and _recce:IsAlive() then
      local unit = _recce:GetUnit(1)
      local name = unit:GetName()
      if string.find(name,"#") then
        name = string.match(name,"^(.*)#")
      end
      local code = self:GetLaserCode(unit:GetName())
      report:Add(string.format("Recce %s has code %d",name,code))
      report:Add("---------------")
    end
  end
  report:Add(string.format("Lasing min threat level %d",self.minthreatlevel))
  report:Add("---------------")
  local lines = 0
  for _ind,_entry in pairs(self.CurrentLasing) do
    local entry = _entry -- #AUTOLASE.LaserSpot
    local reccename = entry.reccename
    if string.find(reccename,"#") then
      reccename = string.match(reccename,"^(.*)#")
    end
    local typename = entry.unittype
    local code = entry.lasercode
    local locationstring = entry.location
    local playername = nil
    if Unit and Unit:IsAlive() then
      playername = Unit:GetPlayerName()
    elseif Group and Group:IsAlive() then
     playername = Group:GetPlayerName()
    end
    if playername then
      local settings = _DATABASE:GetPlayerSettings(playername)
      if settings then
        self:T("Get Settings ok!")
        if settings:IsA2G_MGRS() then
          locationstring = entry.coordinate:ToStringMGRS(settings)
        elseif settings:IsA2G_LL_DMS() then
          locationstring = entry.coordinate:ToStringLLDMS(settings)
        elseif settings:IsA2G_LL_DDM() then
         locationstring = entry.coordinate:ToStringLLDDM(settings)
        elseif settings:IsA2G_BR() then
          -- attention this is the distance from the ASKING unit to target, not from RECCE to target!
          local startcoordinate = Unit:GetCoord() or Group:GetCoord()
          locationstring = entry.coordinate:ToStringBR(startcoordinate,settings,false,self.RoundingPrecision)
        end
      end
    end
    local text = string.format("+ %s lasing %s code %d\nat %s",reccename,typename,code,locationstring)
    report:Add(text)
    report:Add("---------------")
    lines = lines + 1
  end
  if lines == 0 then
    report:Add("No targets!")
    report:Add("---------------")
  end
  local reporttime = self.reporttimelong
  if lines == 0 then reporttime = self.reporttimeshort end
  if Unit and Unit:IsAlive() then
    local m = MESSAGE:New(report:Text(),reporttime,"Info"):ToUnit(Unit)
  elseif Group and Group:IsAlive() then
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
   self.SRSQueue:NewTransmission(Message,nil,self.SRS,nil,2)
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
  
  local function HasNoBlackListAttribute(Unit)
    local nogos = self.blacklistattributes or {}
    local having = true
    local unit = Unit -- Wrapper.Unit#UNIT
    for _,_attribute in pairs (nogos) do
      if unit:HasAttribute(_attribute) then
        having = false
        break
      end
    end
    return having
  end

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
    local reccecoord = Recce:GetCoord()
    local unitcoord = Unit:GetCoord()
    local islos = reccecoord:IsLOS(unitcoord,2.5)
    -- calculate distance
    local distance = math.floor(reccecoord:Get3DDistance(unitcoord))
    local lasedistance = self:GetLosFromUnit(Recce)
    if distance <= lasedistance and islos and HasNoBlackListAttribute(Unit) then
      canlase = true
    end
  end
  return canlase
end

--- (Internal) Function to do a zone check per ground Recce and make found units and statics "known".
-- @param #AUTOLASE self
-- @return #AUTOLASE self 
function AUTOLASE:_Prescient()
  -- self.RecceUnits[name] = { name=name, unit=unit, cooldown = false, timestamp = timer.getAbsTime(), isground=isground }
  for _,_data in pairs(self.RecceUnits) do
    -- ground units only
    if _data.isground and _data.unit and _data.unit:IsAlive() then
      local unit = _data.unit -- Wrapper.Unit#UNIT
      local position = unit:GetCoordinate() -- Core.Point#COORDINATE
      local needsinit = false
      if position then
        local lastposition = unit:GetProperty("lastposition")
        -- property initiated?
        if not lastposition then
          unit:SetProperty("lastposition",position)
          lastposition = position
          needsinit = true
        end
        -- has moved?
        local dist = position:Get2DDistance(lastposition)
        -- refresh?
        local TNow = timer.getAbsTime()
        -- check
        if dist > 10 or needsinit==true or TNow - _data.timestamp > 29 then
          -- init scan objects
          local hasunits,hasstatics,_,Units,Statics = position:ScanObjects(self.LaseDistance,true,true,false)
          -- loop found units
          if hasunits then
            self:T(self.lid.."Checking possibly visible UNITs for Recce "..unit:GetName())
            for _,_target in pairs(Units) do -- Wrapper.Unit#UNIT object here
              local target = _target -- Wrapper.Unit#UNIT
              if target and target:GetCoalition() ~= self.coalition then
                if unit:IsLOS(target) and (not target:IsUnitDetected(unit))then
                  unit:KnowUnit(target,true,true)
                end
              end
            end
          end
          -- loop found statics
          if hasstatics then
           self:T(self.lid.."Checking possibly visible STATICs for Recce "..unit:GetName())
            for _,_static in pairs(Statics) do -- DCS static object here
              local static = STATIC:Find(_static)
              if static and static:GetCoalition() ~= self.coalition and static:GetCoord() then
                local IsLOS = position:IsLOS(static:GetCoord())
                if IsLOS then
                  unit:KnowUnit(static,true,true)
                end
              end
            end
          end
        end
      end
    end
  end
  return self
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
  if self.increasegroundawareness then
    self:_Prescient()
  end
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
  
  local detecteditems = self.Contacts or {} -- #table of Ops.Intel#INTEL.Contact
  local groupsbythreat = {}
  local report = REPORT:New("Detections")
  local lines = 0
  for _,_contact in pairs(detecteditems) do
    local contact = _contact -- Ops.Intel#INTEL.Contact
    local grp = contact.group
    local coord = contact.position
    local reccename = contact.recce or "none"
    local threat = contact.threatlevel or 0
    local reccegrp = UNIT:FindByName(reccename)
    if reccegrp then
      local reccecoord = reccegrp:GetCoord()
      local distance = math.floor(reccecoord:Get3DDistance(coord))
      local text = string.format("%s of %s | Distance %d km | Threatlevel %d",contact.attribute, contact.groupname, math.floor(distance/1000), contact.threatlevel)
      report:Add(text)
      self:T(text)
      if self.debug then self:I(text) end
      lines = lines  +  1
      -- sort out groups beyond sight
      local lasedistance = self:GetLosFromUnit(reccegrp)
      if grp:IsGround() and lasedistance >= distance and threat >= self.minthreatlevel then
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
          if threat >= self.minthreatlevel then
            local unitname = unit:GetName()
            -- prefer radar units
            if unit:HasAttribute("RADAR_BAND1_FOR_ARM") or unit:HasAttribute("RADAR_BAND2_FOR_ARM") or unit:HasAttribute("Optical Tracker") then
              threat = 11
            end
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
        local locationstring = unit:GetCoord():ToStringLLDDM()
        if _SETTINGS:IsA2G_MGRS() then
          local precision = _SETTINGS:GetMGRS_Accuracy()
          local settings = {}
          settings.MGRS_Accuracy = precision
          locationstring = unit:GetCoord():ToStringMGRS(settings)
        elseif _SETTINGS:IsA2G_LL_DMS() then
          locationstring = unit:GetCoord():ToStringLLDMS(_SETTINGS)
        elseif _SETTINGS:IsA2G_BR() then
          locationstring = unit:GetCoord():ToStringBULLS(self.coalition,_SETTINGS)
        end
  
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
          coordinate = unit:GetCoord(),
          }
       if self.smoketargets then
          local coord = unit:GetCoordinate()
          if self.smokeoffset then
            coord:Translate(self.smokeoffset.Distance,self.smokeoffset.Angle,true,true)
          end
          local color = self:GetSmokeColor(reccename)
          coord:Smoke(color)
       end
       self.lasingindex = self.lasingindex + 1 
       self.CurrentLasing[self.lasingindex] = laserspot
       self:__Lasing(2,laserspot)  
      end
    end
  end
  
  local nextloop = -self.MonitorFrequency or -30
  self:__Monitor(nextloop)
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
    if string.find(RecceName,"#") then
      RecceName = string.match(RecceName,"^(.*)#")
    end
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
    if string.find(RecceName,"#") then
      RecceName = string.match(RecceName,"^(.*)#")
    end
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
    if string.find(RecceName,"#") then
      RecceName = string.match(RecceName,"^(.*)#")
    end
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
    local name = laserspot.reccename    if string.find(name,"#") then
        name = string.match(name,"^(.*)#")
    end
    local text = string.format("%s is lasing %s code %d\nat %s",name,laserspot.unittype,laserspot.lasercode,laserspot.location)
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
