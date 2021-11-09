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
--
-- Date: Nov 2021

-------------------------------------------------------------------------
--- **MANTIS** class, extends Core.Base#BASE
-- @type MANTIS
-- @field #string ClassName
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
-- @field #boolean UseEmOnOff Decide if we are using Emissions on/off (true) or AlarmState red/green (default)
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
--        myredmantis = MANTIS:New("myredmantis","Red SAM","Red EWR",nil,"red",false)
--        myredmantis:Start()
--
-- [optional] Use
--
--  *     MANTIS:SetEWRGrouping(radius)
--  *     MANTIS:SetEWRRange(radius)
--  *     MANTIS:SetSAMRadius(radius)
--  *     MANTIS:SetDetectInterval(interval)
--  *     MANTIS:SetAutoRelocate(hq, ewr)
--
-- before starting #MANTIS to fine-tune your setup.
--
-- If you want to use a separate AWACS unit (default detection range: 250km) to support your EWR system, use e.g. the following setup:
--
--        mybluemantis = MANTIS:New("bluemantis","Blue SAM","Blue EWR",nil,"blue",false,"Blue Awacs")
--        mybluemantis:Start()
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
--  E.g.        mymantis:SetAdvancedMode( true, 90 )
--
--  Use this option if you want to make use of or allow advanced SEAD tactics.
--
-- # 5. Integrate SHORAD
--
--  You can also choose to integrate Mantis with @{Functional.Shorad#SHORAD} for protection against HARMs and AGMs. When SHORAD detects a missile fired at one of MANTIS' SAM sites, it will activate SHORAD systems in
--  the given defense checkradius around that SAM site. Create a SHORAD object first, then integrate with MANTIS like so:
--
--          local SamSet = SET_GROUP:New():FilterPrefixes("Blue SAM"):FilterCoalitions("blue"):FilterStart()
--          myshorad = SHORAD:New("BlueShorad", "Blue SHORAD", SamSet, 22000, 600, "blue")
--          -- now set up MANTIS
--          mymantis = MANTIS:New("BlueMantis","Blue SAM","Blue EWR",nil,"blue",false,"Blue Awacs")
--          mymantis:AddShorad(myshorad,720)
--          mymantis:Start()
--
--  and (optionally) remove the link later on with
--
--          mymantis:RemoveShorad()
--
-- # 6. Integrated SEAD
--  
--  MANTIS is using @{Functional.Sead#SEAD} internally to both detect and evade HARM attacks. No extra efforts needed to set this up! 
--  Once a HARM attack is detected, MANTIS (via SEAD) will shut down the radars of the attacked SAM site and take evasive action by moving the SAM
--  vehicles around (*if they are __drivable__*, that is). There's a component of randomness in detection and evasion, which is based on the
--  skill set of the SAM set (the higher the skill, the more likely). When a missile is fired from far away, the SAM will stay active for a 
--  period of time to stay defensive, before it takes evasive actions.
--  
--  You can link into the SEAD driven events of MANTIS like so:
--  
--        function mymantis:OnAfterSeadSuppressionPlanned(From, Event, To, Group, Name, SuppressionStartTime, SuppressionEndTime)
--          -- your code here - SAM site shutdown and evasion planned, but not yet executed
--          -- Time entries relate to timer.getTime() - see https://wiki.hoggitworld.com/view/DCS_func_getTime
--        end
--        
--        function mymantis:OnAfterSeadSuppressionStart(From, Event, To, Group, Name)
--          -- your code here - SAM site is emissions off and possibly moving
--        end
--        
--        function mymantis:OnAfterSeadSuppressionEnd(From, Event, To, Group, Name)
--          -- your code here - SAM site is back online
--        end
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
  UseEmOnOff            = false,
  TimeStamp             = 0,
  state2flag            = false,
  SamStateTracker       = {},
  DLink                 = false,
  DLTimeStamp           = 0,
  Padding               = 10,
  SuppressedGroups       = {},
}

--- Advanced state enumerator
-- @type MANTIS.AdvancedState
MANTIS.AdvancedState = {
  GREEN = 0,
  AMBER = 1,
  RED = 2,
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
  --@param #boolean EmOnOff Make MANTIS switch Emissions on and off instead of changing the alarm state between RED and GREEN (optional)
  --@param #number Padding For #SEAD - Extra number of seconds to add to radar switch-back-on time (optional)
  --@return #MANTIS self
  --@usage Start up your MANTIS with a basic setting
  --
  --        myredmantis = MANTIS:New("myredmantis","Red SAM","Red EWR",nil,"red",false)
  --        myredmantis:Start()
  --
  -- [optional] Use
  --
  --  * MANTIS:SetEWRGrouping(radius)
  --  * MANTIS:SetEWRRange(radius)
  --  * MANTIS:SetSAMRadius(radius)
  --  * MANTIS:SetDetectInterval(interval)
  --  * MANTIS:SetAutoRelocate(hq, ewr)
  --
  -- before starting #MANTIS to fine-tune your setup.
  --
  -- If you want to use a separate AWACS unit (default detection range: 250km) to support your EWR system, use e.g. the following setup:
  --
  --        mybluemantis = MANTIS:New("bluemantis","Blue SAM","Blue EWR",nil,"blue",false,"Blue Awacs")
  --        mybluemantis:Start()
  --
  function MANTIS:New(name,samprefix,ewrprefix,hq,coaltion,dynamic,awacs, EmOnOff, Padding)

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
    self.TimeStamp = timer.getAbsTime()
    self.relointerval = math.random(1800,3600) -- random between 30 and 60 mins
    self.state2flag = false
    self.SamStateTracker = {} -- table to hold alert states, so we don't trigger state changes twice in adv mode
    self.DLink = false
    self.Padding = Padding or 10
    self.SuppressedGroups = {}

    if EmOnOff then
      if EmOnOff == false then
        self.UseEmOnOff = false
      else
        self.UseEmOnOff = true
      end
    end

    if type(awacs) == "string" then
      self.advAwacs = true
    else
      self.advAwacs = false
    end

    -- Inherit everything from BASE class.
    local self = BASE:Inherit(self, FSM:New()) -- #MANTIS

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
    self.version="0.7.1"
    self:I(string.format("***** Starting MANTIS Version %s *****", self.version))

    --- FSM Functions ---

      -- Start State.
  self:SetStartState("Stopped")

  -- Add FSM transitions.
  --                 From State  -->   Event            -->     To State
  self:AddTransition("Stopped",       "Start",                   "Running")     -- Start FSM.
  self:AddTransition("*",             "Status",                  "*")           -- MANTIS status update.
  self:AddTransition("*",             "Relocating",              "*")           -- MANTIS HQ and EWR are relocating.
  self:AddTransition("*",             "GreenState",              "*")           -- MANTIS A SAM switching to GREEN state.
  self:AddTransition("*",             "RedState",                "*")           -- MANTIS A SAM switching to RED state.
  self:AddTransition("*",             "AdvStateChange",          "*")           -- MANTIS advanced mode state change.
  self:AddTransition("*",             "ShoradActivated",         "*")           -- MANTIS woke up a connected SHORAD.
  self:AddTransition("*",             "SeadSuppressionStart",    "*")           -- SEAD has switched off one group.
  self:AddTransition("*",             "SeadSuppressionEnd",      "*")           -- SEAD has switched on one group.
  self:AddTransition("*",             "SeadSuppressionPlanned",  "*")           -- SEAD has planned a suppression.
  self:AddTransition("*",             "Stop",                    "Stopped")     -- Stop FSM.

  ------------------------
  --- Pseudo Functions ---
  ------------------------

  --- Triggers the FSM event "Start". Starts the MANTIS. Initializes parameters and starts event handlers.
  -- @function [parent=#MANTIS] Start
  -- @param #MANTIS self

  --- Triggers the FSM event "Start" after a delay. Starts the MANTIS. Initializes parameters and starts event handlers.
  -- @function [parent=#MANTIS] __Start
  -- @param #MANTIS self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Stop". Stops the MANTIS and all its event handlers.
  -- @param #MANTIS self

  --- Triggers the FSM event "Stop" after a delay. Stops the MANTIS and all its event handlers.
  -- @function [parent=#MANTIS] __Stop
  -- @param #MANTIS self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Status".
  -- @function [parent=#MANTIS] Status
  -- @param #MANTIS self

  --- Triggers the FSM event "Status" after a delay.
  -- @function [parent=#MANTIS] __Status
  -- @param #MANTIS self
  -- @param #number delay Delay in seconds.

  --- On After "Relocating" event. HQ and/or EWR moved.
  -- @function [parent=#MANTIS] OnAfterRelocating
  -- @param #MANTIS self
  -- @param #string From The From State
  -- @param #string Event The Event
  -- @param #string To The To State
  -- @return #MANTIS self

  --- On After "GreenState" event. A SAM group was switched to GREEN alert.
  -- @function [parent=#MANTIS] OnAfterGreenState
  -- @param #MANTIS self
  -- @param #string From The From State
  -- @param #string Event The Event
  -- @param #string To The To State
  -- @param Wrapper.Group#GROUP Group The GROUP object whose state was changed
  -- @return #MANTIS self

  --- On After "RedState" event. A SAM group was switched to RED alert.
  -- @function [parent=#MANTIS] OnAfterRedState
  -- @param #MANTIS self
  -- @param #string From The From State
  -- @param #string Event The Event
  -- @param #string To The To State
  -- @param Wrapper.Group#GROUP Group The GROUP object whose state was changed
  -- @return #MANTIS self

  --- On After "AdvStateChange" event. Advanced state changed, influencing detection speed.
  -- @function [parent=#MANTIS] OnAfterAdvStateChange
  -- @param #MANTIS self
  -- @param #string From The From State
  -- @param #string Event The Event
  -- @param #string To The To State
  -- @param #number Oldstate Old state - 0 = green, 1 = amber, 2 = red
  -- @param #number Newstate New state - 0 = green, 1 = amber, 2 = red
  -- @param #number Interval Calculated detection interval based on state and advanced feature setting
  -- @return #MANTIS self

  --- On After "ShoradActivated" event. Mantis has activated a SHORAD.
  -- @function [parent=#MANTIS] OnAfterShoradActivated
  -- @param #MANTIS self
  -- @param #string From The From State
  -- @param #string Event The Event
  -- @param #string To The To State
  -- @param #string Name Name of the GROUP which SHORAD shall protect
  -- @param #number Radius Radius around the named group to find SHORAD groups
  -- @param #number Ontime Seconds the SHORAD will stay active

  --- On After "SeadSuppressionPlanned" event. Mantis has planned to switch off a site to defend SEAD attack.
  -- @function [parent=#MANTIS] OnAfterSeadSuppressionPlanned
  -- @param #MANTIS self
  -- @param #string From The From State
  -- @param #string Event The Event
  -- @param #string To The To State
  -- @param Wrapper.Group#GROUP Group The suppressed GROUP object
  -- @param #string Name Name of the suppressed group
  -- @param #number SuppressionStartTime Model start time of the suppression from `timer.getTime()`
  -- @param #number SuppressionEndTime Model end time of the suppression from `timer.getTime()`

  --- On After "SeadSuppressionStart" event. Mantis has switched off a site to defend a SEAD attack.
  -- @function [parent=#MANTIS] OnAfterSeadSuppressionStart
  -- @param #MANTIS self
  -- @param #string From The From State
  -- @param #string Event The Event
  -- @param #string To The To State
  -- @param Wrapper.Group#GROUP Group The suppressed GROUP object
  -- @param #string Name Name of the suppressed groupe

  --- On After "SeadSuppressionEnd" event. Mantis has switched on a site after a SEAD attack.
  -- @function [parent=#MANTIS] OnAfterSeadSuppressionEnd
  -- @param #MANTIS self
  -- @param #string From The From State
  -- @param #string Event The Event
  -- @param #string To The To State
  -- @param Wrapper.Group#GROUP Group The suppressed GROUP object
  -- @param #string Name Name of the suppressed group
  
  return self
 end

-----------------------------------------------------------------------
-- MANTIS helper functions
-----------------------------------------------------------------------

  --- [Internal] Function to get the self.SAM_Table
  -- @param #MANTIS self
  -- @return #table table
  function MANTIS:_GetSAMTable()
    self:T(self.lid .. "GetSAMTable")
    return self.SAM_Table
  end

  --- [Internal] Function to set the self.SAM_Table
  -- @param #MANTIS self
  -- @return #MANTIS self
  function MANTIS:_SetSAMTable(table)
    self:T(self.lid .. "SetSAMTable")
    self.SAM_Table = table
    return self
  end

  --- Function to set the grouping radius of the detection in meters
  -- @param #MANTIS self
  -- @param #number radius Radius upon which detected objects will be grouped
  function MANTIS:SetEWRGrouping(radius)
    self:T(self.lid .. "SetEWRGrouping")
    local radius = radius or 5000
    self.grouping = radius
    return self
  end

  --- Function to set the detection radius of the EWR in meters
  -- @param #MANTIS self
  -- @param #number radius Radius of the EWR detection zone
  function MANTIS:SetEWRRange(radius)
    self:T(self.lid .. "SetEWRRange")
    local radius = radius or 80000
    self.acceptrange = radius
    return self
  end

  --- Function to set switch-on/off zone for the SAM sites in meters
  -- @param #MANTIS self
  -- @param #number radius Radius of the firing zone
  function MANTIS:SetSAMRadius(radius)
    self:T(self.lid .. "SetSAMRadius")
    local radius = radius or 25000
    self.checkradius = radius
    return self
  end

  --- Function to set SAM firing engage range, 0-100 percent, e.g. 75
  -- @param #MANTIS self
  -- @param #number range Percent of the max fire range
  function MANTIS:SetSAMRange(range)
    self:T(self.lid .. "SetSAMRange")
    local range = range or 75
    if range < 0 or range > 100 then
      range = 75
    end
    self.engagerange = range
    return self
  end

  --- Function to set a new SAM firing engage range, use this method to adjust range while running MANTIS, e.g. for different setups day and night
  -- @param #MANTIS self
  -- @param #number range Percent of the max fire range
  function MANTIS:SetNewSAMRangeWhileRunning(range)
    self:T(self.lid .. "SetNewSAMRangeWhileRunning")
    local range = range or 75
    if range < 0 or range > 100 then
      range = 75
    end
    self.engagerange = range
    self:_RefreshSAMTable()
    self.mysead.EngagementRange = range
    return self
  end

  --- Function to set switch-on/off the debug state
  -- @param #MANTIS self
  -- @param #boolean onoff Set true to switch on
  function MANTIS:Debug(onoff)
    self:T(self.lid .. "SetDebug")
    local onoff = onoff or false
    self.debug = onoff
    if onoff then
      -- Debug trace.
      BASE:TraceOn()
      BASE:TraceClass("MANTIS")
      BASE:TraceLevel(1)
    else
      BASE:TraceOff()
    end
    return self
  end

  --- Function to get the HQ object for further use
  -- @param #MANTIS self
  -- @return Wrapper.GROUP#GROUP The HQ #GROUP object or *nil* if it doesn't exist
  function MANTIS:GetCommandCenter()
    self:T(self.lid .. "GetCommandCenter")
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
    self:T(self.lid .. "SetAwacs")
    if prefix ~= nil then
      if type(prefix) == "string" then
        self.AWACS_Prefix = prefix
        self.advAwacs = true
      end
    end
    return self
  end

  --- Function to set AWACS detection range. Defaults to 250.000m (250km) - use **before** starting your Mantis!
  -- @param #MANTIS self
  -- @param #number range Detection range of the AWACS group
  function MANTIS:SetAwacsRange(range)
    self:T(self.lid .. "SetAwacsRange")
    local range = range or 250000
    self.awacsrange = range
    return self
  end

  --- Function to set the HQ object for further use
  -- @param #MANTIS self
  -- @param Wrapper.GROUP#GROUP group The #GROUP object to be set as HQ
  function MANTIS:SetCommandCenter(group)
    self:T(self.lid .. "SetCommandCenter")
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
    return self
  end

  --- Function to set the detection interval
  -- @param #MANTIS self
  -- @param #number interval The interval in seconds
  function MANTIS:SetDetectInterval(interval)
    self:T(self.lid .. "SetDetectInterval")
    local interval = interval or 30
    self.detectinterval = interval
    return self
  end

  --- Function to set Advanded Mode
  -- @param #MANTIS self
  -- @param #boolean onoff If true, will activate Advanced Mode
  -- @param #number ratio [optional] Percentage to use for advanced mode, defaults to 100%
  -- @usage Advanced mode will *decrease* reactivity of MANTIS, if HQ and/or EWR network dies.  Set SAMs to RED state if both are dead.  Requires usage of an **HQ** object and the **dynamic** option.
  -- E.g. `mymantis:SetAdvancedMode(true, 90)`
  function MANTIS:SetAdvancedMode(onoff, ratio)
    self:T(self.lid .. "SetAdvancedMode")
    --self:T({onoff, ratio})
    local onoff = onoff or false
    local ratio = ratio or 100
    if (type(self.HQ_Template_CC) == "string") and onoff and self.dynamic then
      self.adv_ratio = ratio
      self.advanced = true
      self.adv_state = 0
      self.Adv_EWR_Group = SET_GROUP:New():FilterPrefixes(self.EWR_Templates_Prefix):FilterCoalitions(self.Coalition):FilterStart()
      self:I(string.format("***** Starting Advanced Mode MANTIS Version %s *****", self.version))
    else
      local text = self.lid.." Advanced Mode requires a HQ and dynamic to be set. Revisit your MANTIS:New() statement to add both."
      local m= MESSAGE:New(text,10,"MANTIS",true):ToAll()
      self:E(text)
    end
    return self
  end

  --- Set using Emissions on/off instead of changing alarm state
  -- @param #MANTIS self
  -- @param #boolean switch Decide if we are changing alarm state or Emission state
  function MANTIS:SetUsingEmOnOff(switch)
    self:T(self.lid .. "SetUsingEmOnOff")
    self.UseEmOnOff = switch or false
    return self
  end

  --- Set using an #INTEL_DLINK object instead of #DETECTION
  -- @param #MANTIS self
  -- @param Ops.Intelligence#INTEL_DLINK DLink The data link object to be used.
  function MANTIS:SetUsingDLink(DLink)
    self:T(self.lid .. "SetUsingDLink")
    self.DLink = true
    self.Detection = DLink
    self.DLTimeStamp = timer.getAbsTime()
    return self
  end

  --- [Internal] Function to check if HQ is alive
  -- @param #MANTIS self
  -- @return #boolean True if HQ is alive, else false
  function MANTIS:_CheckHQState()
    self:T(self.lid .. "CheckHQState")
    local text = self.lid.." Checking HQ State"
    local m= MESSAGE:New(text,10,"MANTIS"):ToAllIf(self.debug)
    if self.verbose then self:I(text) end
    -- start check
    if self.advanced then
      local hq = self.HQ_Template_CC
      local hqgrp = GROUP:FindByName(hq)
      if hqgrp then
        if hqgrp:IsAlive() then -- ok we're on, hq exists and as alive
          --self:T(self.lid.." HQ is alive!")
          return true
        else
          --self:T(self.lid.." HQ is dead!")
          return false
        end
      end
    end
    return self
  end

  --- [Internal] Function to check if EWR is (at least partially) alive
  -- @param #MANTIS self
  -- @return #boolean True if EWR is alive, else false
  function MANTIS:_CheckEWRState()
    self:T(self.lid .. "CheckEWRState")
    local text = self.lid.." Checking EWR State"
    --self:T(text)
    local m= MESSAGE:New(text,10,"MANTIS"):ToAllIf(self.debug)
    if self.verbose then self:I(text) end
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
      --self:T(self.lid..string.format(" No of EWR alive is %d", nalive))
      if nalive > 0 then
        return true
      else
        return false
      end
    end
    return self
  end

  --- [Internal] Function to determine state of the advanced mode
  -- @param #MANTIS self
  -- @return #number Newly calculated interval
  -- @return #number Previous state for tracking 0, 1, or 2
  function MANTIS:_CalcAdvState()
    self:T(self.lid .. "CalcAdvState")
    local m=MESSAGE:New(self.lid.." Calculating Advanced State",10,"MANTIS"):ToAllIf(self.debug)
    if self.verbose then self:I(self.lid.." Calculating Advanced State") end
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
    if self.debug or self.verbose then
      local text = self.lid..string.format(" Calculated OldState/NewState/Interval: %d / %d / %d", currstate, self.adv_state, newinterval)
      --self:T(text)
      local m=MESSAGE:New(text,10,"MANTIS"):ToAllIf(self.debug)
      if self.verbose then self:I(text) end
    end
    return newinterval, currstate
  end

  --- Function to set autorelocation for HQ and EWR objects. Note: Units must be actually mobile in DCS!
  -- @param #MANTIS self
  -- @param #boolean hq If true, will relocate HQ object
  -- @param #boolean ewr If true, will relocate  EWR objects
  function MANTIS:SetAutoRelocate(hq, ewr)
    self:T(self.lid .. "SetAutoRelocate")
    --self:T({hq, ewr})
    local hqrel = hq or false
    local ewrel = ewr or false
    if hqrel or ewrel then
      self.autorelocate = true
      self.autorelocateunits = { HQ = hqrel, EWR = ewrel }
      --self:T({self.autorelocate, self.autorelocateunits})
    end
    return self
  end

  --- [Internal] Function to execute the relocation
  -- @param #MANTIS self
  function MANTIS:_RelocateGroups()
    self:T(self.lid .. "RelocateGroups")
    local text = self.lid.." Relocating Groups"
    local m= MESSAGE:New(text,10,"MANTIS",true):ToAllIf(self.debug)
    if self.verbose then self:I(text) end
    if self.autorelocate then
      -- relocate HQ
      local HQGroup = self.HQ_CC
      if self.autorelocateunits.HQ and self.HQ_CC and HQGroup:IsAlive() then --only relocate if HQ exists
        local _hqgrp = self.HQ_CC
        --self:T(self.lid.." Relocating HQ")
        local text = self.lid.." Relocating HQ"
        --local m= MESSAGE:New(text,10,"MANTIS"):ToAll()
          _hqgrp:RelocateGroundRandomInRadius(20,500,true,true)
      end
      --relocate EWR
      -- TODO: maybe dependent on AlarmState? Observed: SA11 SR only relocates if no objects in reach
      if self.autorelocateunits.EWR then
         -- get EWR Group
         local EWR_GRP = SET_GROUP:New():FilterPrefixes(self.EWR_Templates_Prefix):FilterCoalitions(self.Coalition):FilterOnce()
         local EWR_Grps = EWR_GRP.Set --table of objects in SET_GROUP
         for _,_grp in pairs (EWR_Grps) do
             if _grp:IsAlive() and _grp:IsGround() then
              --self:T(self.lid.." Relocating EWR ".._grp:GetName())
              local text = self.lid.." Relocating EWR ".._grp:GetName()
              local m= MESSAGE:New(text,10,"MANTIS"):ToAllIf(self.debug)
              if self.verbose then self:I(text) end
              _grp:RelocateGroundRandomInRadius(20,500,true,true)
             end
         end
      end
    end
    return self
  end

  --- [Internal] Function to check if any object is in the given SAM zone
  -- @param #MANTIS self
  -- @param #table dectset Table of coordinates of detected items
  -- @param Core.Point#COORDINATE samcoordinate Coordinate object.
  -- @return #boolean True if in any zone, else false
  -- @return #number Distance Target distance in meters or zero when no object is in zone
  function MANTIS:CheckObjectInZone(dectset, samcoordinate)
    self:T(self.lid.."CheckObjectInZone")
    -- check if non of the coordinate is in the given defense zone
    local radius = self.checkradius
    local set = dectset
    for _,_coord in pairs (set) do
      local coord = _coord  -- get current coord to check
      -- output for cross-check
      local targetdistance = samcoordinate:DistanceFromPointVec2(coord)
      if self.verbose or self.debug then
        local dectstring = coord:ToStringLLDMS()
        local samstring = samcoordinate:ToStringLLDMS()
        local text = string.format("Checking SAM at % s - Distance %d m - Target %s", samstring, targetdistance, dectstring)
        local m = MESSAGE:New(text,10,"Check"):ToAllIf(self.debug)
        self:I(self.lid..text)
      end
      -- end output to cross-check
      if targetdistance <= radius then
        return true, targetdistance
      end
    end
    return false, 0
  end

  --- [Internal] Function to start the detection via EWR groups
  -- @param #MANTIS self
  -- @return Functional.Detection #DETECTION_AREAS The running detection set
  function MANTIS:StartDetection()
    self:T(self.lid.."Starting Detection")

    -- start detection
    local groupset = self.EWR_Group
    local grouping = self.grouping or 5000
    local acceptrange = self.acceptrange or 80000
    local interval = self.detectinterval or 60

    --@param Functional.Detection #DETECTION_AREAS _MANTISdetection [Internal] The MANTIS detection object
    local MANTISdetection = DETECTION_AREAS:New( groupset, grouping ) --[Internal] Grouping detected objects to 5000m zones
    MANTISdetection:FilterCategories({ Unit.Category.AIRPLANE, Unit.Category.HELICOPTER })
    MANTISdetection:SetAcceptRange(acceptrange)
    MANTISdetection:SetRefreshTimeInterval(interval)
    MANTISdetection:Start()

    function MANTISdetection:OnAfterDetectedItem(From,Event,To,DetectedItem)
      --BASE:I( { From, Event, To, DetectedItem })
      local debug = false
      if DetectedItem.IsDetected and debug then
        local Coordinate = DetectedItem.Coordinate -- Core.Point#COORDINATE
        local text = "MANTIS: Detection at "..Coordinate:ToStringLLDMS()
        local m = MESSAGE:New(text,10,"MANTIS"):ToAllIf(self.debug)
      end
    end
    return MANTISdetection
  end

 --- [Internal] Function to start the detection via AWACS if defined as separate
  -- @param #MANTIS self
  -- @return Functional.Detection #DETECTION_AREAS The running detection set
  function MANTIS:StartAwacsDetection()
    self:T(self.lid.."Starting Awacs Detection")

    -- start detection
    local group = self.AWACS_Prefix
    local groupset = SET_GROUP:New():FilterPrefixes(group):FilterCoalitions(self.Coalition):FilterStart()
    local grouping = self.grouping or 5000
    --local acceptrange = self.acceptrange or 80000
    local interval = self.detectinterval or 60

    --@param Functional.Detection #DETECTION_AREAS _MANTISdetection [Internal] The MANTIS detection object
    local MANTISAwacs = DETECTION_AREAS:New( groupset, grouping ) --[Internal] Grouping detected objects to 5000m zones
    MANTISAwacs:FilterCategories({ Unit.Category.AIRPLANE, Unit.Category.HELICOPTER })
    MANTISAwacs:SetAcceptRange(self.awacsrange)  --250km
    MANTISAwacs:SetRefreshTimeInterval(interval)
    MANTISAwacs:Start()

    function MANTISAwacs:OnAfterDetectedItem(From,Event,To,DetectedItem)
      --BASE:I( { From, Event, To, DetectedItem })
      local debug = false
      if DetectedItem.IsDetected and debug then
        local Coordinate = DetectedItem.Coordinate -- Core.Point#COORDINATE
        local text = "Awacs Detection at "..Coordinate:ToStringLLDMS()
        local m = MESSAGE:New(text,10,"MANTIS"):ToAllIf(self.debug)
      end
    end
    return MANTISAwacs
  end

  --- [Internal] Function to set the SAM start state
  -- @param #MANTIS self
  -- @return #MANTIS self
  function MANTIS:SetSAMStartState()
    -- DONE: if using dynamic filtering, update SAM_Table and the (active) SEAD groups, pull req #1405/#1406
    self:T(self.lid.."Setting SAM Start States")
     -- get SAM Group
     local SAM_SET = self.SAM_Group
     local SAM_Grps = SAM_SET.Set --table of objects
     local SAM_Tbl = {} -- table of SAM defense zones
     local SEAD_Grps = {} -- table of SAM names to make evasive
     local engagerange = self.engagerange -- firing range in % of max
     --cycle through groups and set alarm state etc
     for _i,_group in pairs (SAM_Grps) do
        local group = _group -- Wrapper.Group#GROUP
        -- TODO: add emissions on/off
        if self.UseEmOnOff then
          group:OptionAlarmStateRed()
          group:EnableEmission(false)
          --group:SetAIOff()
        else
          group:OptionAlarmStateGreen() -- AI off
        end
        group:SetOption(AI.Option.Ground.id.AC_ENGAGEMENT_RANGE_RESTRICTION,engagerange)  --default engagement will be 75% of firing range
        if group:IsGround() and group:IsAlive() then
          local grpname = group:GetName()
          local grpcoord = group:GetCoordinate()
          table.insert( SAM_Tbl, {grpname, grpcoord})
          table.insert( SEAD_Grps, grpname )
          self.SamStateTracker[grpname] = "GREEN"
        end
     end
     self.SAM_Table = SAM_Tbl
     -- make SAMs evasive
     local mysead = SEAD:New( SEAD_Grps, self.Padding ) -- Functional.Sead#SEAD
     mysead:SetEngagementRange(engagerange)
     mysead:AddCallBack(self)
     if self.UseEmOnOff then
      mysead:SwitchEmissions(true)
     end
     self.mysead = mysead
     return self
  end

  --- [Internal] Function to update SAM table and SEAD state
  -- @param #MANTIS self
  -- @return #MANTIS self
  function MANTIS:_RefreshSAMTable()
    self:T(self.lid.."RefreshSAMTable")
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
        if group:IsGround() and group:IsAlive() then
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
    self:T(self.lid.."AddShorad")
    local Shorad = Shorad or nil
    local ShoradTime = Shoradtime or 600
    local ShoradLink = true
    if Shorad:IsInstanceOf("SHORAD") then
      self.ShoradLink = ShoradLink
      self.Shorad = Shorad --#SHORAD
      self.ShoradTime = Shoradtime -- #number
    end
    return self
  end

  --- Function to unlink #MANTIS from a #SHORAD installation
  -- @param #MANTIS self
  function MANTIS:RemoveShorad()
    self:T(self.lid.."RemoveShorad")
    self.ShoradLink = false
    return self
  end

-----------------------------------------------------------------------
-- MANTIS main functions
-----------------------------------------------------------------------

  --- [Internal] Check detection function
  -- @param #MANTIS self
  -- @param Functional.Detection#DETECTION_AREAS detection Detection object
  -- @return #MANTIS self
  function MANTIS:_Check(detection)
    self:T(self.lid .. "Check")
    --get detected set
    local detset = detection:GetDetectedItemCoordinates()
    self:T("Check:", {detset})
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
      local suppressed = self.SuppressedGroups[name] or false
      if IsInZone then --check any target in zone and not curr managed by SEAD
        if samgroup:IsAlive() then
          -- switch on SAM
          if self.UseEmOnOff and not suppressed then
            -- DONE: add emissions on/off
            --samgroup:SetAIOn()
            samgroup:EnableEmission(true)
          elseif not self.UseEmOnOff and not suppressed then
            samgroup:OptionAlarmStateRed()
          end
          if self.SamStateTracker[name] ~= "RED" and not suppressed then
            self:__RedState(1,samgroup)
            self.SamStateTracker[name] = "RED"
          end
          -- link in to SHORAD if available
          -- DONE: Test integration fully
          if self.ShoradLink and (Distance < self.ShoradActDistance or suppressed) then -- don't give SHORAD position away too early
            local Shorad = self.Shorad
            local radius = self.checkradius
            local ontime = self.ShoradTime
            Shorad:WakeUpShorad(name, radius, ontime)
            self:__ShoradActivated(1,name, radius, ontime)
          end
          -- debug output
          if self.debug or self.verbose and not suppressed then
            local text = string.format("SAM %s switched to alarm state RED!", name)
            local m=MESSAGE:New(text,10,"MANTIS"):ToAllIf(self.debug)
            if self.verbose then self:I(self.lid..text) end
          end
        end --end alive
      else
        if samgroup:IsAlive() then
          -- switch off SAM
          if self.UseEmOnOff and not suppressed then
            samgroup:EnableEmission(false)
          elseif not self.UseEmOnOff and not suppressed then
            samgroup:OptionAlarmStateGreen()
          end
          if self.SamStateTracker[name] ~= "GREEN" and not suppressed then
            self:__GreenState(1,samgroup)
            self.SamStateTracker[name] = "GREEN"
          end
          if self.debug or self.verbose and not suppressed then
            local text = string.format("SAM %s switched to alarm state GREEN!", name)
            local m=MESSAGE:New(text,10,"MANTIS"):ToAllIf(self.debug)
            if self.verbose then self:I(self.lid..text) end
          end
        end --end alive
      end --end check
    end --for for loop
    return self
  end

  --- [Internal] Relocation relay function
  -- @param #MANTIS self
  -- @return #MANTIS self
  function MANTIS:_Relocate()
    self:T(self.lid .. "Relocate")
    self:_RelocateGroups()
    return self
  end

  --- [Internal] Check advanced state
  -- @param #MANTIS self
  -- @return #MANTIS self
  function MANTIS:_CheckAdvState()
    self:T(self.lid .. "CheckAdvSate")
    local interval, oldstate = self:_CalcAdvState()
    local newstate = self.adv_state
    if newstate ~= oldstate then
      -- deal with new state
      self:__AdvStateChange(1,oldstate,newstate,interval)
      if newstate == 2 then
        -- switch alarm state RED
        self.state2flag = true
        local samset = self:_GetSAMTable() -- table of i.1=names, i.2=coordinates
        for _,_data in pairs (samset) do
          local name = _data[1]
          local samgroup = GROUP:FindByName(name)
          if samgroup:IsAlive() then
            if self.UseEmOnOff then
              -- TODO: add emissions on/off
              --samgroup:SetAIOn()
              samgroup:EnableEmission(true)
            end
            samgroup:OptionAlarmStateRed()
          end -- end alive
        end -- end for loop
      elseif newstate <= 1 then
        -- change MantisTimer to slow down or speed up
        self.detectinterval = interval
        self.state2flag = false
      end
    end -- end newstate vs oldstate
    return self
  end

  --- [Internal] Check DLink state
  -- @param #MANTIS self
  -- @return #MANTIS self
  function MANTIS:_CheckDLinkState()
    self:T(self.lid .. "_CheckDLinkState")
    local dlink = self.Detection -- Ops.Intelligence#INTEL_DLINK
    local TS = timer.getAbsTime()
    if not dlink:Is("Running") and (TS - self.DLTimeStamp > 29) then
      self.DLink = false
      self.Detection = self:StartDetection() -- fall back
      self:I(self.lid .. "Intel DLink not running - switching back to single detection!")
    end
  end

  --- [Internal] Function to set start state
  -- @param #MANTIS self
  -- @param #string From The From State
  -- @param #string Event The Event
  -- @param #string To The To State
  -- @return #MANTIS self
  function MANTIS:onafterStart(From, Event, To)
    self:T({From, Event, To})
    self:T(self.lid.."Starting MANTIS")
    self:SetSAMStartState()
    if not self.DLink then
      self.Detection = self:StartDetection()
    end
    if self.advAwacs then
      self.AWACS_Detection = self:StartAwacsDetection()
    end
    self:__Status(-math.random(1,10))
    return self
  end

  --- [Internal] Before status function for MANTIS
  -- @param #MANTIS self
  -- @param #string From The From State
  -- @param #string Event The Event
  -- @param #string To The To State
  -- @return #MANTIS self
  function MANTIS:onbeforeStatus(From, Event, To)
    self:T({From, Event, To})
    -- check detection
    if not self.state2flag then
      self:_Check(self.Detection)
    end

    -- check Awacs
    if self.advAwacs and not self.state2flag then
      self:_Check(self.AWACS_Detection)
    end

    -- relocate HQ and EWR
    if self.autorelocate then
      local relointerval = self.relointerval
      local thistime = timer.getAbsTime()
      local timepassed = thistime - self.TimeStamp

      local halfintv = math.floor(timepassed / relointerval)

      --self:T({timepassed=timepassed, halfintv=halfintv})

      if halfintv >= 1 then
        self.TimeStamp = timer.getAbsTime()
        self:_Relocate()
        self:__Relocating(1)
      end
    end

    -- advanced state check
    if self.advanced then
      self:_CheckAdvState()
    end

    -- check DLink state
    if self.DLink then
      self:_CheckDLinkState()
    end

    return self
  end

  --- [Internal] Status function for MANTIS
  -- @param #MANTIS self
  -- @param #string From The From State
  -- @param #string Event The Event
  -- @param #string To The To State
  -- @return #MANTIS self
  function MANTIS:onafterStatus(From,Event,To)
    self:T({From, Event, To})
    -- Display some states
    if self.debug then
      self:I(self.lid .. "Status Report")
      for _name,_state in pairs(self.SamStateTracker) do
        self:I(string.format("Site %s\tStatus %s",_name,_state))
      end
    end
    local interval = self.detectinterval * -1
    self:__Status(interval)
    return self
  end

  --- [Internal] Function to stop MANTIS
  -- @param #MANTIS self
  -- @param #string From The From State
  -- @param #string Event The Event
  -- @param #string To The To State
  -- @return #MANTIS self
  function MANTIS:onafterStop(From, Event, To)
    self:T({From, Event, To})
    return self
  end

  --- [Internal] Function triggered by Event Relocating
  -- @param #MANTIS self
  -- @param #string From The From State
  -- @param #string Event The Event
  -- @param #string To The To State
  -- @return #MANTIS self
  function MANTIS:onafterRelocating(From, Event, To)
    self:T({From, Event, To})
    return self
  end

  --- [Internal] Function triggered by Event GreenState
  -- @param #MANTIS self
  -- @param #string From The From State
  -- @param #string Event The Event
  -- @param #string To The To State
  -- @param Wrapper.Group#GROUP Group The GROUP object whose state was changed
  -- @return #MANTIS self
  function MANTIS:onafterGreenState(From, Event, To, Group)
    self:T({From, Event, To, Group})
    return self
  end

  --- [Internal] Function triggered by Event RedState
  -- @param #MANTIS self
  -- @param #string From The From State
  -- @param #string Event The Event
  -- @param #string To The To State
  -- @param Wrapper.Group#GROUP Group The GROUP object whose state was changed
  -- @return #MANTIS self
  function MANTIS:onafterRedState(From, Event, To, Group)
    self:T({From, Event, To, Group})
    return self
  end

  --- [Internal] Function triggered by Event AdvStateChange
  -- @param #MANTIS self
  -- @param #string From The From State
  -- @param #string Event The Event
  -- @param #string To The To State
  -- @param #number Oldstate Old state - 0 = green, 1 = amber, 2 = red
  -- @param #number Newstate New state - 0 = green, 1 = amber, 2 = red
  -- @param #number Interval Calculated detection interval based on state and advanced feature setting
  -- @return #MANTIS self
  function MANTIS:onafterAdvStateChange(From, Event, To, Oldstate, Newstate, Interval)
    self:T({From, Event, To, Oldstate, Newstate, Interval})
    return self
  end

  --- [Internal] Function triggered by Event ShoradActivated
  -- @param #MANTIS self
  -- @param #string From The From State
  -- @param #string Event The Event
  -- @param #string To The To State
  -- @param #string Name Name of the GROUP which SHORAD shall protect
  -- @param #number Radius Radius around the named group to find SHORAD groups
  -- @param #number Ontime Seconds the SHORAD will stay active
  function MANTIS:onafterShoradActivated(From, Event, To, Name, Radius, Ontime)
    self:T({From, Event, To, Name, Radius, Ontime})
    return self
  end
  
    --- [Internal] Function triggered by Event SeadSuppressionStart
  -- @param #MANTIS self
  -- @param #string From The From State
  -- @param #string Event The Event
  -- @param #string To The To State
  -- @param Wrapper.Group#GROUP Group The suppressed GROUP object
  -- @param #string Name Name of the suppressed group
  function MANTIS:onafterSeadSuppressionStart(From, Event, To, Group, Name)
    self:T({From, Event, To, Name})
    self.SuppressedGroups[Name] = true
    return self
  end
  
    --- [Internal] Function triggered by Event SeadSuppressionEnd
  -- @param #MANTIS self
  -- @param #string From The From State
  -- @param #string Event The Event
  -- @param #string To The To State
  -- @param Wrapper.Group#GROUP Group The suppressed GROUP object
  -- @param #string Name Name of the suppressed group
  function MANTIS:onafterSeadSuppressionEnd(From, Event, To, Group, Name)
    self:T({From, Event, To, Name})
    self.SuppressedGroups[Name] = false
    return self
  end
  
    --- [Internal] Function triggered by Event SeadSuppressionPlanned
  -- @param #MANTIS self
  -- @param #string From The From State
  -- @param #string Event The Event
  -- @param #string To The To State
  -- @param Wrapper.Group#GROUP Group The suppressed GROUP object
  -- @param #string Name Name of the suppressed group
  -- @param #number SuppressionStartTime Model start time of the suppression from `timer.getTime()`
  -- @param #number SuppressionEndTime Model end time of the suppression from `timer.getTime()`
  function MANTIS:onafterSeadSuppressionPlanned(From, Event, To, Group, Name, SuppressionStartTime, SuppressionEndTime)
    self:T({From, Event, To, Name})
    return self
  end
  
end
-----------------------------------------------------------------------
-- MANTIS end
-----------------------------------------------------------------------
