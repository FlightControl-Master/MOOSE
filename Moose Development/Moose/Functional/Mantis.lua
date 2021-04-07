--- **Functional** -- Modular, Automatic and Network capable Targeting and Interception System for Air Defenses
-- 
-- ===
-- 
-- **MANTIS** - Moose derived  Modular, Automatic and Network capable Targeting and Interception System
-- Controls a network of SAM sites. Use detection to switch on the AA site closest to the enemy
-- Leverage evasiveness from SEAD
-- Leverage attack range setup added by DCS in 11/20
-- 
-- ===
-- 
-- ## Missions:
--
-- ### [MANTIS - Modular, Automatic and Network capable Targeting and Interception System](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master/MTS%20-%20Mantis/MTS-010%20-%20Basic%20Mantis%20Demo)
-- 
-- ===
-- 
-- ### Author : **applevangelist **
-- 
-- @module Functional.Mantis
-- @image Functional.Mantis.jpg

-- Date: Apr 2021

-------------------------------------------------------------------------
--- **MANTIS** class, extends #Core.Base#BASE
-- @type MANTIS
-- @field #string Classname
-- @field #string name Name of this Mantis
-- @field #string SAM_Templates_Prefix Prefix to build the #SET_GROUP for SAM sites
-- @field Core.Set#SET_GROUP SAM_Group The SAM #SET_GROUP
-- @field #string EWR_Templates_Prefix Prefix to build the #SET_GROUP for EWR group
-- @field Core.Set#SET_GROUP EWR_Group The EWR #SET_GROUP
-- @field Core.Set#SET_GROUP Adv_EWR_Group The EWR #SET_GROUP used for advanced mode
-- @field #string HQ_Template_CC The ME name of the HQ object
-- @field Wrapper.Group#GROUP HQ_CC The #GROUP object of the HQ
-- @field #table SAM_Table Table of SAM sites
-- @field #string lid Prefix for logging
-- @field Functional.Detection#DETECTION_AREAS Detection The #DETECTION_AREAS object for EWR
-- @field Functional.Detection#DETECTION_AREAS AWACS_Detection The #DETECTION_AREAS object for AWACS
-- @field #boolean debug Switch on extra messages
-- @field #boolean verbose Switch on extra logging
-- @field #number checkradius Radius of the SAM sites
-- @field #number grouping Radius to group detected objects
-- @field #number acceptrange Radius of the EWR detection
-- @field #number detectinterval Interval in seconds for the target detection
-- @field #number engagerange Firing engage range of the SAMs, see [https://wiki.hoggitworld.com/view/DCS_option_engagementRange]
-- @field #boolean autorelocate Relocate HQ and EWR groups in random intervals. Note: You need to select units for this which are *actually mobile*
-- @field #boolean advanced Use advanced mode, will decrease reactivity of MANTIS, if HQ and/or EWR network dies. Set SAMs to RED state if both are dead. Requires usage of an HQ object
-- @field #number adv_ratio Percentage to use for advanced mode, defaults to 100%
-- @field #number adv_state Advanced mode state tracker
-- @field #boolean advAwacs Boolean switch to use Awacs as a separate detection stream
-- @field #number awacsrange Detection range of an optional Awacs unit
-- @field #boolean UseAIOnOff Decide if we are using AI on/off (true) or AlarmState red/green (default)
-- @field Functional.Shorad#SHORAD Shorad SHORAD Object, if available
-- @field #boolean ShoradLink If true, #MANTIS has #SHORAD enabled
-- @field #number ShoradTime Timer in seconds, how long #SHORAD will be active after a detection inside of the defense range
-- @field #number ShoradActDistance Distance of an attacker in meters from a Mantis SAM site, on which Shorad will be switched on. Useful to not give away Shorad sites too early. Default 15km. Should be smaller than checkradius.
-- @extends Core.Base#BASE


--- *The worst thing that can happen to a good cause is, not to be skillfully attacked, but to be ineptly defended.* - Frédéric Bastiat 
-- 
-- Simple Class for a more intelligent Air Defense System
-- 
-- #MANTIS
-- Moose derived  Modular, Automatic and Network capable Targeting and Interception System.
-- Controls a network of SAM sites. Use detection to switch on the AA site closest to the enemy.
-- Leverage evasiveness from @{Functional.Sead#SEAD}.
-- Leverage attack range setup added by DCS in 11/20.
--
-- Set up your SAM sites in the mission editor. Name the groups with common prefix like "Red SAM".
-- Set up your EWR system in the mission editor. Name the groups with common prefix like "Red EWR". Can be e.g. AWACS or a combination of AWACS and Search Radars like e.g. EWR 1L13 etc.
-- [optional] Set up your HQ. Can be any group, e.g. a command vehicle.
-- 
-- # 1. Basic tactical considerations when setting up your SAM sites
-- 
-- ## 1.1 Radar systems and AWACS
-- 
--  Typically, your setup should consist of EWR (early warning) radars to detect and track targets, accompanied by AWACS if your scenario forsees that. Ensure that your EWR radars have a good coverage of the area you want to track.
--  **Location** is of highest importantance here. Whilst AWACS in DCS has almost the "all seeing eye", EWR don't have that. Choose your location wisely, against a mountain backdrop or inside a valley even the best EWR system
--  doesn't work well. Prefer higher-up locations with a good view; use F7 in-game to check where you actually placed your EWR and have a look around. Apart from the obvious choice, do also consider other radar units
--  for this role, most have "SR" (search radar) or "STR" (search and track radar) in their names, use the encyclopedia to see what they actually do.  
--  
-- ## 1.2 SAM sites
-- 
-- Typically your SAM should cover all attack ranges. The closer the enemy gets, the more systems you will need to deploy to defend your location. Use a combination of long-range systems like the SA-10/11, midrange like SA-6 and short-range like 
-- SA-2 for defense (Patriot, Hawk, Gepard, Blindfire for the blue side). For close-up defense and defense against HARMs or low-flying aircraft, helicopters it is also advisable to deploy SA-15 TOR systems, Shilka, Strela and Tunguska units, as well as manpads (Think Gepard, Avenger, Chaparral, 
-- Linebacker, Roland systems for the blue side). If possible, overlap ranges for mutual coverage.
-- 
-- ## 1.3 Typical problems
-- 
-- Often times, people complain because the detection cannot "see" oncoming targets and/or Mantis switches on too late. Three typial problems here are  
--  
--   * bad placement of radar units, 
--   * overestimation how far units can "see" and 
--   * not taking into account that a SAM site will take (e.g for a SA-6) 30-40 seconds between switching to RED, acquiring the target and firing. 
-- 
-- An attacker doing 350knots will cover ca 180meters/second or thus more than 6km until the SA-6 fires. Use triggers zones and the ruler in the missione editor to understand distances and zones. Take into account that the ranges given by the circles
-- in the mission editor are absolute maximum ranges; in-game this is rather 50-75% of that depending on the system. Fiddle with placement and options to see what works best for your scenario, and remember **everything in here is in meters**.
-- 
-- # 2. Start up your MANTIS with a basic setting
-- 
--    `myredmantis = MANTIS:New("myredmantis","Red SAM","Red EWR",nil,"red",false)`  
--    `myredmantis:Start()`
--    
-- [optional] Use  
-- 
--  * `MANTIS:SetEWRGrouping(radius)`  
--  * `MANTIS:SetEWRRange(radius)`  
--  * `MANTIS:SetSAMRadius(radius)`  
--  * `MANTIS:SetDetectInterval(interval)`
--  * `MANTIS:SetAutoRelocate(hq, ewr)`
--        
-- before starting #MANTIS to fine-tune your setup.
-- 
-- If you want to use a separate AWACS unit (default detection range: 250km) to support your EWR system, use e.g. the following setup:
-- 
--    `mybluemantis = MANTIS:New("bluemantis","Blue SAM","Blue EWR",nil,"blue",false,"Blue Awacs")`  
--    `mybluemantis:Start()`
--
-- # 3. Default settings
-- 
-- By default, the following settings are active:
--
--  * SAM_Templates_Prefix = "Red SAM" - SAM site group names in the mission editor begin with "Red SAM"
--  * EWR_Templates_Prefix = "Red EWR" - EWR group names in the mission editor begin with "Red EWR" - can also be combined with an AWACS unit
--  * checkradius = 25000 (meters) - SAMs will engage enemy flights, if they are within a 25km around each SAM site - `MANTIS:SetSAMRadius(radius)`
--  * grouping = 5000 (meters) - Detection (EWR) will group enemy flights to areas of 5km for tracking - `MANTIS:SetEWRGrouping(radius)`
--  * acceptrange = 80000 (meters) - Detection (EWR) will on consider flights inside a 80km radius - `MANTIS:SetEWRRange(radius)`  
--  * detectinterval = 30 (seconds) - MANTIS will decide every 30 seconds which SAM to activate - `MANTIS:SetDetectInterval(interval)`
--  * engagerange = 85 (percent) - SAMs will only fire if flights are inside of a 85% radius of their max firerange - `MANTIS:SetSAMRange(range)`
--  * dynamic = false - Group filtering is set to once, i.e. newly added groups will not be part of the setup by default - `MANTIS:New(name,samprefix,ewrprefix,hq,coaltion,dynamic)`
--  * autorelocate = false - HQ and (mobile) EWR system will not relocate in random intervals between 30mins and 1 hour - `MANTIS:SetAutoRelocate(hq, ewr)`
--  * debug = false - Debugging reports on screen are set to off - `MANTIS:Debug(onoff)`
--
-- # 4. Advanced Mode
-- 
--  Advanced mode will *decrease* reactivity of MANTIS, if HQ and/or EWR  network dies.  Awacs is counted as one EWR unit. It will set SAMs to RED state if both are dead.  Requires usage of an **HQ** object and the **dynamic** option.  
--  
--  E.g.        `mymantis:SetAdvancedMode( true, 90 )`  
--  
--  Use this option if you want to make use of or allow advanced SEAD tactics.  
--  
-- # 5. Integrate SHORAD
--  
--  You can also choose to integrate Mantis with @{Functional.Shorad#SHORAD} for protection against HARMs and AGMs. When SHORAD detects a missile fired at one of MANTIS' SAM sites, it will activate SHORAD systems in
--  the given defense checkradius around that SAM site. Create a SHORAD object first, then integrate with MANTIS like so:
--  
--      `local SamSet = SET_GROUP:New():FilterPrefixes("Blue SAM"):FilterCoalitions("blue"):FilterStart()`
--      `myshorad = SHORAD:New("BlueShorad", "Blue SHORAD", SamSet, 22000, 600, "blue")`
--      `-- now set up MANTIS`
--      `mymantis = MANTIS:New("BlueMantis","Blue SAM","Blue EWR",nil,"blue",false,"Blue Awacs")`
--      `mymantis:AddShorad(myshorad,720)`
--      `mymantis:Start()`
-- 
--  and (optionally) remove the link later on with
--  
--        `mymantis:RemoveShorad()`    
--
-- @field #MANTIS
MANTIS = {
  ClassName             = "MANTIS",
  name                  = "mymantis",
  SAM_Templates_Prefix  = "",
  SAM_Group             = nil,
  EWR_Templates_Prefix  = "",
  EWR_Group             = nil,
  Adv_EWR_Group         = nil,
  HQ_Template_CC      = "",
  HQ_CC               = nil,
  SAM_Table             = {},
  lid                   = "",
  Detection             = nil,
  AWACS_Detection       = nil,
  debug                 = false,
  checkradius           = 25000,
  grouping              = 5000,
  acceptrange           = 80000,
  detectinterval        = 30,
  engagerange           = 75,
  autorelocate          = false,
  advanced              = false,
  adv_ratio             = 100,
  adv_state             = 0,
  AWACS_Prefix          = "",
  advAwacs              = false,
  verbose               = false,
  awacsrange            = 250000,
  Shorad                = nil,
  ShoradLink            = false,
  ShoradTime            = 600,
  ShoradActDistance     = 15000,
  UseAIOnOff            = false, 
}

-----------------------------------------------------------------------
-- MANTIS System
-----------------------------------------------------------------------

do
  --- Function to instantiate a new object of class MANTIS
  --@param #MANTIS self
  --@param #string name Name of this MANTIS for reporting
  --@param #string samprefix Prefixes for the SAM groups from the ME, e.g. all groups starting with "Red Sam..."
  --@param #string ewrprefix Prefixes for the EWR groups from the ME, e.g. all groups starting with "Red EWR..."
  --@param #string hq Group name of your HQ (optional)
  --@param #string coaltion Coalition side of your setup, e.g. "blue", "red" or "neutral"
  --@param #boolean dynamic Use constant (true) filtering or just filter once (false, default) (optional)
  --@param #string awacs Group name of your Awacs (optional)
  --@param #boolean AIOnOff Make MANTIS switch AI on and off instead of changing the alarm state between RED and GREEN (optional)
  --@return #MANTIS self
  --@usage Start up your MANTIS with a basic setting
  --
  --    `myredmantis = MANTIS:New("myredmantis","Red SAM","Red EWR",nil,"red",false)`  
  --    `myredmantis:Start()`
  --    
  -- [optional] Use  
  -- 
  --  * `MANTIS:SetEWRGrouping(radius)`  
  --  * `MANTIS:SetEWRRange(radius)`  
  --  * `MANTIS:SetSAMRadius(radius)`  
  --  * `MANTIS:SetDetectInterval(interval)`
  --  * `MANTIS:SetAutoRelocate(hq, ewr)`
  --        
  -- before starting #MANTIS to fine-tune your setup.
  -- 
  -- If you want to use a separate AWACS unit (default detection range: 250km) to support your EWR system, use e.g. the following setup:
  -- 
  --    `mybluemantis = MANTIS:New("bluemantis","Blue SAM","Blue EWR",nil,"blue",false,"Blue Awacs")`  
  --    `mybluemantis:Start()`
  --    
  function MANTIS:New(name,samprefix,ewrprefix,hq,coaltion,dynamic,awacs, AIOnOff)
    
    -- DONE: Create some user functions for these
    -- DONE: Make HQ useful
    -- DONE: Set SAMs to auto if EWR dies
    -- DONE: Refresh SAM table in dynamic mode
    -- DONE: Treat Awacs separately, since they might be >80km off site

    self.name = name or "mymantis"
    self.SAM_Templates_Prefix = samprefix or "Red SAM"
    self.EWR_Templates_Prefix = ewrprefix or "Red EWR"
    self.HQ_Template_CC = hq or nil
    self.Coalition = coaltion or "red"
    self.SAM_Table = {}
    self.dynamic = dynamic or false
    self.checkradius = 25000
    self.grouping = 5000
    self.acceptrange = 80000
    self.detectinterval = 30
    self.engagerange = 75
    self.autorelocate = false
    self.autorelocateunits = { HQ = false, EWR = false}
    self.advanced = false
    self.adv_ratio = 100
    self.adv_state = 0 
    self.verbose = false
    self.Adv_EWR_Group = nil
    self.AWACS_Prefix = awacs or nil
    self.awacsrange = 250000      --DONE: 250km, User Function to change
    self.Shorad = nil
    self.ShoradLink = false
    self.ShoradTime = 600
    self.ShoradActDistance = 15000
    -- TODO: add emissions on/off when available .... in 2 weeks
    self.UseAIOnOff = AIOnOff or false     
     
    if type(awacs) == "string" then
      self.advAwacs = true
    else
      self.advAwacs = false
    end
    
    -- Inherit everything from BASE class.
    local self = BASE:Inherit(self, BASE:New()) -- #MANTIS
    
    -- Set the string id for output to DCS.log file.
    self.lid=string.format("MANTIS %s | ", self.name)
  
    -- Debug trace.
    if self.debug then
      BASE:TraceOnOff(true)
      BASE:TraceClass(self.ClassName)
      --BASE:TraceClass("SEAD")
      BASE:TraceLevel(1)
    end
    
    if self.dynamic then
      -- Set SAM SET_GROUP
      self.SAM_Group = SET_GROUP:New():FilterPrefixes(self.SAM_Templates_Prefix):FilterCoalitions(self.Coalition):FilterStart()
      -- Set EWR SET_GROUP
      self.EWR_Group = SET_GROUP:New():FilterPrefixes({self.SAM_Templates_Prefix,self.EWR_Templates_Prefix}):FilterCoalitions(self.Coalition):FilterStart()
    else
      -- Set SAM SET_GROUP
      self.SAM_Group = SET_GROUP:New():FilterPrefixes(self.SAM_Templates_Prefix):FilterCoalitions(self.Coalition):FilterOnce()
      -- Set EWR SET_GROUP
      self.EWR_Group = SET_GROUP:New():FilterPrefixes({self.SAM_Templates_Prefix,self.EWR_Templates_Prefix}):FilterCoalitions(self.Coalition):FilterOnce()
    end
    
    -- set up CC
    if self.HQ_Template_CC then
      self.HQ_CC = GROUP:FindByName(self.HQ_Template_CC)
    end
    
    -- @field #string version
    self.version="0.4.0"
    self:I(string.format("***** Starting MANTIS Version %s *****", self.version))
    
    return self    
  end

-----------------------------------------------------------------------
-- MANTIS helper functions
-----------------------------------------------------------------------  
  
  --- [internal] Function to get the self.SAM_Table
  -- @param #MANTIS self
  -- @return #table table  
  function MANTIS:_GetSAMTable()
    return self.SAM_Table
  end
  
  --- [internal] Function to set the self.SAM_Table
  -- @param #MANTIS self
  -- @return #MANTIS self
  function MANTIS:_SetSAMTable(table)
    self.SAM_Table = table
    return self
  end
 
  --- Function to set the grouping radius of the detection in meters
  -- @param #MANTIS self
  -- @param #number radius Radius upon which detected objects will be grouped
  function MANTIS:SetEWRGrouping(radius)
    local radius = radius or 5000
    self.grouping = radius
  end

  --- Function to set the detection radius of the EWR in meters
  -- @param #MANTIS self
  -- @param #number radius Radius of the EWR detection zone
  function MANTIS:SetEWRRange(radius)
    local radius = radius or 80000
    self.acceptrange = radius
  end
  
  --- Function to set switch-on/off zone for the SAM sites in meters
  -- @param #MANTIS self
  -- @param #number radius Radius of the firing zone  
  function MANTIS:SetSAMRadius(radius)
    local radius = radius or 25000
    self.checkradius = radius
  end
  
  --- Function to set SAM firing engage range, 0-100 percent, e.g. 75
  -- @param #MANTIS self
  -- @param #number range Percent of the max fire range
  function MANTIS:SetSAMRange(range)
    local range = range or 75
    if range < 0 or range > 100 then
      range = 75
    end
    self.engagerange = range
  end
  
  --- Function to set a new SAM firing engage range, use this method to adjust range while running MANTIS, e.g. for different setups day and night
  -- @param #MANTIS self
  -- @param #number range Percent of the max fire range
  function MANTIS:SetNewSAMRangeWhileRunning(range)
    local range = range or 75
    if range < 0 or range > 100 then
      range = 75
    end
    self.engagerange = range
    self:_RefreshSAMTable()
    self.mysead.EngagementRange = range
  end
  
  --- Function to set switch-on/off the debug state
  -- @param #MANTIS self
  -- @param #boolean onoff Set true to switch on
  function MANTIS:Debug(onoff)
    local onoff = onoff or false
    self.debug = onoff
  end
     
  --- Function to get the HQ object for further use
  -- @param #MANTIS self
  -- @return Wrapper.GROUP#GROUP The HQ #GROUP object or *nil* if it doesn't exist
  function MANTIS:GetCommandCenter()
    if self.HQ_CC then
      return self.HQ_CC
    else
      return nil      
    end   
  end
  
  --- Function to set separate AWACS detection instance
  -- @param #MANTIS self
  -- @param #string prefix Name of the AWACS group in the mission editor
  function MANTIS:SetAwacs(prefix)
    if prefix ~= nil then
      if type(prefix) == "string" then
        self.AWACS_Prefix = prefix
        self.advAwacs = true
      end
    end
  end

  --- Function to set AWACS detection range. Defaults to 250.000m (250km) - use **before** starting your Mantis!
  -- @param #MANTIS self
  -- @param #number range Detection range of the AWACS group
  function MANTIS:SetAwacsRange(range)
      local range = range or 250000
      self.awacsrange = range
  end
  
  --- Function to set the HQ object for further use
  -- @param #MANTIS self
  -- @param Wrapper.GROUP#GROUP group The #GROUP object to be set as HQ
  function MANTIS:SetCommandCenter(group)
    local group = group or nil
    if group ~= nil then
      if type(group) == "string" then
        self.HQ_CC = GROUP:FindByName(group)
        self.HQ_Template_CC = group
      else
        self.HQ_CC = group
        self.HQ_Template_CC = group:GetName()
      end
    end
  end
          
  --- Function to set the detection interval
  -- @param #MANTIS self
  -- @param #number interval The interval in seconds
  function MANTIS:SetDetectInterval(interval)
    local interval = interval or 30
    self.detectinterval = interval
  end  
  
  --- Function to set Advanded Mode
  -- @param #MANTIS self
  -- @param #boolean onoff If true, will activate Advanced Mode
  -- @param #number ratio [optional] Percentage to use for advanced mode, defaults to 100%
  -- @usage Advanced mode will *decrease* reactivity of MANTIS, if HQ and/or EWR network dies.  Set SAMs to RED state if both are dead.  Requires usage of an **HQ** object and the **dynamic** option.
  -- E.g. `mymantis:SetAdvancedMode(true, 90)`
  function MANTIS:SetAdvancedMode(onoff, ratio)
    self:F({onoff, ratio})
    local onoff = onoff or false
    local ratio = ratio or 100
    if (type(self.HQ_Template_CC) == "string") and onoff and self.dynamic then
      self.adv_ratio = ratio
      self.advanced = true
      self.adv_state = 0
      self.Adv_EWR_Group = SET_GROUP:New():FilterPrefixes(self.EWR_Templates_Prefix):FilterCoalitions(self.Coalition):FilterStart()
      env.info(string.format("***** Starting Advanced Mode MANTIS Version %s *****", self.version))
    else
      local text = self.lid.." Advanced Mode requires a HQ and dynamic to be set. Revisit your MANTIS:New() statement to add both."
      local m= MESSAGE:New(text,10,"MANTIS",true):ToAll()
      BASE:E(text)
    end
  end
  
  --- Set using AI on/off instead of changing alarm state
  -- @param #MANTIS self
  -- @param #boolean switch Decide if we are changing alarm state or AI state
  function MANTIS:SetUsingAIOnOff(switch)
    self.UseAIOnOff = switch or false
  end
  
  --- [Internal] Function to check if HQ is alive
  -- @param #MANTIS self
  -- @return #boolean True if HQ is alive, else false
  function MANTIS:_CheckHQState()
    local text = self.lid.." Checking HQ State"
    self:T(text)
    local m= MESSAGE:New(text,10,"MANTIS"):ToAllIf(self.debug)
    if self.verbose then env.info(text) end
    -- start check
    if self.advanced then
      local hq = self.HQ_Template_CC
      local hqgrp = GROUP:FindByName(hq)
      if hqgrp then
        if hqgrp:IsAlive() then -- ok we're on, hq exists and as alive
          env.info(self.lid.." HQ is alive!")
          return true
        else
          env.info(self.lid.." HQ is dead!")
          return false  
        end
      end
    end 
  end

  --- [Internal] Function to check if EWR is (at least partially) alive
  -- @param #MANTIS self
  -- @return #boolean True if EWR is alive, else false
  function MANTIS:_CheckEWRState()
    local text = self.lid.." Checking EWR State"
    self:F(text)
    local m= MESSAGE:New(text,10,"MANTIS"):ToAllIf(self.debug)
    if self.verbose then env.info(text) end
    -- start check
    if self.advanced then
      local EWR_Group = self.Adv_EWR_Group
      --local EWR_Set = EWR_Group.Set
      local nalive = EWR_Group:CountAlive()
      if self.advAwacs then
        local awacs = GROUP:FindByName(self.AWACS_Prefix)
        if awacs ~= nil then
          if awacs:IsAlive() then
            nalive = nalive+1
          end
        end
      end
      env.info(self.lid..string.format(" No of EWR alive is %d", nalive))
      if nalive > 0 then
        return true
      else
        return false
      end
    end 
  end

  --- [Internal] Function to determine state of the advanced mode
  -- @param #MANTIS self
  -- @return #number Newly calculated interval
  -- @return #number Previous state for tracking 0, 1, or 2
  function MANTIS:_CheckAdvState()
    local text = self.lid.." Checking Advanced State"
    self:F(text)
    local m=MESSAGE:New(text,10,"MANTIS"):ToAllIf(self.debug)
    if self.verbose then env.info(text) end
    -- start check
    local currstate = self.adv_state -- save curr state for comparison later
    local EWR_State = self:_CheckEWRState()
    local HQ_State = self:_CheckHQState()
    -- set state
    if EWR_State and HQ_State then -- both alive
      self.adv_state = 0 --everything is fine
    elseif EWR_State or HQ_State then -- one alive
      self.adv_state = 1 --slow down level 1
    else -- none alive
      self.adv_state = 2 --slow down level 2
    end
    -- calculate new detectioninterval
    local interval = self.detectinterval -- e.g. 30
    local ratio = self.adv_ratio / 100 -- e.g. 80/100 = 0.8
    ratio = ratio * self.adv_state -- e.g 0.8*2 = 1.6
    local newinterval = interval + (interval * ratio) -- e.g. 30+(30*1.6) = 78
    local text = self.lid..string.format(" Calculated OldState/NewState/Interval: %d / %d / %d", currstate, self.adv_state, newinterval)
    self:F(text)
    local m=MESSAGE:New(text,10,"MANTIS"):ToAllIf(self.debug)
    if self.verbose then env.info(text) end
    return newinterval, currstate
  end
  
  --- Function to set autorelocation for HQ and EWR objects. Note: Units must be actually mobile in DCS!
  -- @param #MANTIS self
  -- @param #boolean hq If true, will relocate HQ object
  -- @param #boolean ewr If true, will relocate  EWR objects
  function MANTIS:SetAutoRelocate(hq, ewr)
    self:F({hq, ewr})
    local hqrel = hq or false
    local ewrel = ewr or false
    if hqrel or ewrel then
      self.autorelocate = true
      self.autorelocateunits = { HQ = hqrel, EWR = ewrel }
      self:T({self.autorelocate, self.autorelocateunits})
    end
  end    
  
  --- [Internal] Function to execute the relocation
  -- @param #MANTIS self
  function MANTIS:_RelocateGroups()
    self:T(self.lid.." Relocating Groups")
    local text = self.lid.." Relocating Groups"
    local m= MESSAGE:New(text,10,"MANTIS",true):ToAllIf(self.debug)
    if self.verbose then env.info(text) end
    if self.autorelocate then
      -- relocate HQ
      if self.autorelocateunits.HQ and self.HQ_CC then --only relocate if HQ exists
        local _hqgrp = self.HQ_CC
        self:T(self.lid.." Relocating HQ")
        local text = self.lid.." Relocating HQ"
        local m= MESSAGE:New(text,10,"MANTIS"):ToAll()
        _hqgrp:RelocateGroundRandomInRadius(20,500,true,true)
      end
      --relocate EWR
      -- TODO: maybe dependent on AlarmState? Observed: SA11 SR only relocates if no objects in reach
      if self.autorelocateunits.EWR then
         -- get EWR Group
         local EWR_GRP = SET_GROUP:New():FilterPrefixes(self.EWR_Templates_Prefix):FilterCoalitions(self.Coalition):FilterOnce()
         local EWR_Grps = EWR_GRP.Set --table of objects in SET_GROUP
         for _,_grp in pairs (EWR_Grps) do
             if _grp:IsGround() then
              self:T(self.lid.." Relocating EWR ".._grp:GetName())
              local text = self.lid.." Relocating EWR ".._grp:GetName()
              local m= MESSAGE:New(text,10,"MANTIS"):ToAllIf(self.debug)
              if self.verbose then env.info(text) end
              _grp:RelocateGroundRandomInRadius(20,500,true,true)
             end
         end
      end
    end
  end
     
  --- (Internal) Function to check if any object is in the given SAM zone
  -- @param #MANTIS self
  -- @param #table dectset Table of coordinates of detected items
  -- @param samcoordinate Core.Point#COORDINATE Coordinate object.
  -- @return #boolean True if in any zone, else false
  -- @return #number Distance Target distance in meters or zero when no object is in zone
  function MANTIS:CheckObjectInZone(dectset, samcoordinate)
    self:F(self.lid.."CheckObjectInZone Called")
    -- check if non of the coordinate is in the given defense zone
    local radius = self.checkradius
    local set = dectset
    for _,_coord in pairs (set) do
      local coord = _coord  -- get current coord to check
      -- output for cross-check
      local dectstring = coord:ToStringLLDMS()
      local samstring = samcoordinate:ToStringLLDMS()
      local targetdistance = samcoordinate:DistanceFromPointVec2(coord)
      local text = string.format("Checking SAM at % s - Distance %d m - Target %s", samstring, targetdistance, dectstring)
      local m = MESSAGE:New(text,10,"Check"):ToAllIf(self.debug)
      if self.verbose then env.info(self.lid..text) end
      -- end output to cross-check
      if targetdistance <= radius then
        return true, targetdistance
      end
    end
    return false, 0
  end

  --- (Internal) Function to start the detection via EWR groups
  -- @param #MANTIS self
  -- @return Functional.Detection #DETECTION_AREAS The running detection set
  function MANTIS:StartDetection()
    self:F(self.lid.."Starting Detection")
    
    -- start detection
    local groupset = self.EWR_Group
    local grouping = self.grouping or 5000
    local acceptrange = self.acceptrange or 80000
    local interval = self.detectinterval or 60
    
    --@param Functional.Detection #DETECTION_AREAS _MANTISdetection [internal] The MANTIS detection object
    _MANTISdetection = DETECTION_AREAS:New( groupset, grouping ) --[internal] Grouping detected objects to 5000m zones
    _MANTISdetection:FilterCategories({ Unit.Category.AIRPLANE, Unit.Category.HELICOPTER })
    _MANTISdetection:SetAcceptRange(acceptrange)
    _MANTISdetection:SetRefreshTimeInterval(interval)
    _MANTISdetection:Start()
    
    function _MANTISdetection:OnAfterDetectedItem(From,Event,To,DetectedItem)
      --BASE:I( { From, Event, To, DetectedItem })
      local debug = false
      if DetectedItem.IsDetected and debug then
        local Coordinate = DetectedItem.Coordinate -- Core.Point#COORDINATE
        local text = "MANTIS: Detection at "..Coordinate:ToStringLLDMS()
        local m = MESSAGE:New(text,10,"MANTIS"):ToAllIf(self.debug)
      end
    end  
    return _MANTISdetection
  end
  
 --- (Internal) Function to start the detection via AWACS if defined as separate
  -- @param #MANTIS self
  -- @return Functional.Detection #DETECTION_AREAS The running detection set
  function MANTIS:StartAwacsDetection()
    self:F(self.lid.."Starting Awacs Detection")
    
    -- start detection
    local group = self.AWACS_Prefix
    local groupset = SET_GROUP:New():FilterPrefixes(group):FilterCoalitions(self.Coalition):FilterStart()
    local grouping = self.grouping or 5000
    --local acceptrange = self.acceptrange or 80000
    local interval = self.detectinterval or 60
    
    --@param Functional.Detection #DETECTION_AREAS _MANTISdetection [internal] The MANTIS detection object
    _MANTISAwacs = DETECTION_AREAS:New( groupset, grouping ) --[internal] Grouping detected objects to 5000m zones
    _MANTISAwacs:FilterCategories({ Unit.Category.AIRPLANE, Unit.Category.HELICOPTER })
    _MANTISAwacs:SetAcceptRange(self.awacsrange)  --250km
    _MANTISAwacs:SetRefreshTimeInterval(interval)
    _MANTISAwacs:Start()
    
    function _MANTISAwacs:OnAfterDetectedItem(From,Event,To,DetectedItem)
      --BASE:I( { From, Event, To, DetectedItem })
      local debug = false
      if DetectedItem.IsDetected and debug then
        local Coordinate = DetectedItem.Coordinate -- Core.Point#COORDINATE
        local text = "Awacs Detection at "..Coordinate:ToStringLLDMS()
        local m = MESSAGE:New(text,10,"MANTIS"):ToAllIf(self.debug)
      end
    end  
    return _MANTISAwacs
  end
  
  --- (Internal) Function to set the SAM start state
  -- @param #MANTIS self
  -- @return #MANTIS self
  function MANTIS:SetSAMStartState()
    -- DONE: if using dynamic filtering, update SAM_Table and the (active) SEAD groups, pull req #1405/#1406
    self:F(self.lid.."Setting SAM Start States")
     -- get SAM Group
     local SAM_SET = self.SAM_Group
     local SAM_Grps = SAM_SET.Set --table of objects
     local SAM_Tbl = {} -- table of SAM defense zones
     local SEAD_Grps = {} -- table of SAM names to make evasive
     local engagerange = self.engagerange -- firing range in % of max
     --cycle through groups and set alarm state etc
     for _i,_group in pairs (SAM_Grps) do
        local group = _group
        -- TODO: add emissions on/off
        if self.UseAIOnOff then
          group:SetAIOff()
        else
          group:OptionAlarmStateGreen() -- AI off
        end
        group:SetOption(AI.Option.Ground.id.AC_ENGAGEMENT_RANGE_RESTRICTION,engagerange)  --default engagement will be 75% of firing range
        if group:IsGround() then
          local grpname = group:GetName()
          local grpcoord = group:GetCoordinate()
          table.insert( SAM_Tbl, {grpname, grpcoord})
          table.insert( SEAD_Grps, grpname )
        end
     end
     self.SAM_Table = SAM_Tbl
     -- make SAMs evasive
     local mysead = SEAD:New( SEAD_Grps )
     mysead:SetEngagementRange(engagerange)
     self.mysead = mysead
     return self
  end
  
  --- (Internal) Function to update SAM table and SEAD state
  -- @param #MANTIS self
  -- @return #MANTIS self
  function MANTIS:_RefreshSAMTable()
    self:F(self.lid.."Setting SAM Start States")
    -- Requires SEAD 0.2.2 or better
     -- get SAM Group
     local SAM_SET = self.SAM_Group
     local SAM_Grps = SAM_SET.Set --table of objects
     local SAM_Tbl = {} -- table of SAM defense zones
     local SEAD_Grps = {} -- table of SAM names to make evasive
     local engagerange = self.engagerange -- firing range in % of max
     --cycle through groups and set alarm state etc
     for _i,_group in pairs (SAM_Grps) do
        local group = _group
        group:SetOption(AI.Option.Ground.id.AC_ENGAGEMENT_RANGE_RESTRICTION,engagerange)  --engagement will be 75% of firing range
        if group:IsGround() then
          local grpname = group:GetName()
          local grpcoord = group:GetCoordinate()
          table.insert( SAM_Tbl, {grpname, grpcoord}) -- make the table lighter, as I don't really use the zone here
          table.insert( SEAD_Grps, grpname )
        end
     end
     self.SAM_Table = SAM_Tbl
     -- make SAMs evasive
     if self.mysead ~= nil then
      local mysead = self.mysead
      mysead:UpdateSet( SEAD_Grps )
     end
     return self
  end
  
  --- Function to link up #MANTIS with a #SHORAD installation
  -- @param #MANTIS self
  -- @param Functional.Shorad#SHORAD Shorad The #SHORAD object
  -- @param #number Shoradtime Number of seconds #SHORAD stays active post wake-up
  function MANTIS:AddShorad(Shorad,Shoradtime)
    local Shorad = Shorad or nil
    local ShoradTime = Shoradtime or 600
    local ShoradLink = true
    if Shorad:IsInstanceOf("SHORAD") then
      self.ShoradLink = ShoradLink
      self.Shorad = Shorad --#SHORAD
      self.ShoradTime = Shoradtime -- #number
    end
  end
  
  --- Function to unlink #MANTIS from a #SHORAD installation
  -- @param #MANTIS self
  function MANTIS:RemoveShorad()
    self.ShoradLink = false
  end
  
-----------------------------------------------------------------------
-- MANTIS main functions
-----------------------------------------------------------------------    
  
  --- Function to set the SAM start state
  -- @param #MANTIS self
  -- @return #MANTIS self
  function MANTIS:Start()
    self:F(self.lid.."Starting MANTIS")
    self:SetSAMStartState()
    self.Detection = self:StartDetection()
    if self.advAwacs then
      self.AWACS_Detection = self:StartAwacsDetection()
    end
    -- detection function
    local function check(detection)
      --get detected set
      local detset = detection:GetDetectedItemCoordinates()
      self:F("Check:", {detset})
      -- randomly update SAM Table
      local rand = math.random(1,100)
      if rand > 65 then -- 1/3 of cases
        self:_RefreshSAMTable()
      end
      -- switch SAMs on/off if (n)one of the detected groups is inside their reach
      local samset = self:_GetSAMTable() -- table of i.1=names, i.2=coordinates
      for _,_data in pairs (samset) do
        local samcoordinate = _data[2]
        local name = _data[1]
        local samgroup = GROUP:FindByName(name)
        local IsInZone, Distance = self:CheckObjectInZone(detset, samcoordinate)
        if IsInZone then --check any target in zone
          if samgroup:IsAlive() then
            -- switch on SAM
            if self.UseAIOnOff then
              -- TODO: add emissions on/off
              samgroup:SetAIOn()
            end
            samgroup:OptionAlarmStateRed()
            -- link in to SHORAD if available
            -- DONE: Test integration fully
            if self.ShoradLink and Distance < self.ShoradActDistance then -- don't give SHORAD position away too early
              local Shorad = self.Shorad
              local radius = self.checkradius
              local ontime = self.ShoradTime
              Shorad:WakeUpShorad(name, radius, ontime)
            end
            -- debug output
            local text = string.format("SAM %s switched to alarm state RED!", name)
            local m=MESSAGE:New(text,10,"MANTIS"):ToAllIf(self.debug)
            if self.verbose then env.info(self.lid..text) end
          end --end alive
        else 
          if samgroup:IsAlive() then
            -- switch off SAM
            if self.UseAIOnOff then
              -- TODO: add emissions on/off
              samgroup:SetAIOff()
            else
              samgroup:OptionAlarmStateGreen()
            end
            --samgroup:OptionROEWeaponFree()
            --samgroup:SetAIOn()
            local text = string.format("SAM %s switched to alarm state GREEN!", name)
            local m=MESSAGE:New(text,10,"MANTIS"):ToAllIf(self.debug)
            if self.verbose then env.info(self.lid..text) end
          end --end alive
        end --end check
      end --for for loop
    end --end function
    -- relocation relay function
    local function relocate()
      self:_RelocateGroups()
    end
    -- check advanced state
    local function checkadvstate()
        local interval, oldstate = self:_CheckAdvState()
        local newstate = self.adv_state
        if newstate ~= oldstate then
          -- deal with new state
          if newstate == 2 then
            -- switch alarm state RED
            if self.MantisTimer.isrunning then 
              self.MantisTimer:Stop() 
              self.MantisTimer.isrunning = false
            end -- stop Awacs timer
            if self.MantisATimer.isrunning then 
              self.MantisATimer:Stop() 
              self.MantisATimer.isrunning = false
            end -- stop timer
            local samset = self:_GetSAMTable() -- table of i.1=names, i.2=coordinates
            for _,_data in pairs (samset) do
              local name = _data[1]
              local samgroup = GROUP:FindByName(name)
              if samgroup:IsAlive() then
                if self.UseAIOnOff then
                  -- TODO: add emissions on/off
                  samgroup:SetAIOn()
                end
                samgroup:OptionAlarmStateRed()
              end -- end alive
            end -- end for loop
          elseif newstate <= 1 then
            -- change MantisTimer to slow down or speed up
            if self.MantisTimer.isrunning then 
              self.MantisTimer:Stop()
              self.MantisTimer.isrunning = false
            end
            if self.MantisATimer.isrunning then 
              self.MantisATimer:Stop()
              self.MantisATimer.isrunning = false
            end
            self.MantisTimer = TIMER:New(check,self.Detection)
            self.MantisTimer:Start(5,interval,nil) 
            self.MantisTimer.isrunning = true
            if self.advAwacs then
              self.MantisATimer = TIMER:New(check,self.AWACS_Detection)
              self.MantisATimer:Start(15,interval,nil)
              self.MantisATimer.isrunning = true    
            end
          end
        end -- end newstate vs oldstate
    end
    -- timers to run the system
    local interval = self.detectinterval
    self.MantisTimer = TIMER:New(check,self.Detection)
    self.MantisTimer:Start(5,interval,nil)
    self.MantisTimer.isrunning = true
    -- Awacs timer
    if self.advAwacs then
      self.MantisATimer = TIMER:New(check,self.AWACS_Detection)
      self.MantisATimer:Start(15,interval,nil)
      self.MantisATimer.isrunning = true    
    end
    -- timer to relocate HQ and EWR
    if self.autorelocate then
      local relointerval = math.random(1800,3600) -- random between 30 and 60 mins
      self.MantisReloTimer = TIMER:New(relocate)
      self.MantisReloTimer:Start(relointerval,relointerval,nil)
    end
    -- timer for advanced state check
    if self.advanced then
      self.MantisAdvTimer = TIMER:New(checkadvstate)
      self.MantisAdvTimer:Start(30,interval*5,nil)
    end
    return self
  end
  
  --- Function to stop MANTIS
  -- @param #MANTIS self
  -- @return #MANTIS self
  function MANTIS:Stop()
    if self.MantisTimer.isrunning then
      self.MantisTimer:Stop()
    end
    if self.MantisATimer.isrunning then
      self.MantisATimer:Stop()
    end
    if self.autorelocate then
      self.MantisReloTimer:Stop()
    end
    if self.advanced then
      self.MantisAdvTimer:Stop()
    end
  return self        
  end
  
end
-----------------------------------------------------------------------
-- MANTIS end
-----------------------------------------------------------------------
