--- **Functional** - Modular, Automatic and Network capable Targeting and Interception System for Air Defenses.
--
-- ===
--
-- ## Features:
--
--  * Moose derived  Modular, Automatic and Network capable Targeting and Interception System.
--  * Controls a network of SAM sites. Uses detection to switch on the AA site closest to the enemy.   
--  * Automatic mode (default since 0.8) can set-up your SAM site network automatically for you.   
--  * Leverage evasiveness from SEAD, leverage attack range setting.   
--
-- ===
--
-- ## Missions:
--
-- ### [MANTIS - Modular, Automatic and Network capable Targeting and Interception System](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master/Functional/Mantis)
--
-- ===
--
-- ### Author : **applevangelist **
--
-- @module Functional.Mantis
-- @image Functional.Mantis.jpg
--
-- Last Update: Jan 2025

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
-- @field #boolean checkforfriendlies If true, do not activate a SAM installation if a friendly aircraft is in firing range.
-- @field #table FilterZones Table of Core.Zone#ZONE Zones Consider SAM groups in this zone(s) only for this MANTIS instance, must be handed as #table of Zone objects.
-- @extends Core.Base#BASE


--- *The worst thing that can happen to a good cause is, not to be skillfully attacked, but to be ineptly defended.* - Frédéric Bastiat
--
-- Moose class for a more intelligent Air Defense System
--
-- # MANTIS
-- 
-- * Moose derived  Modular, Automatic and Network capable Targeting and Interception System.
-- * Controls a network of SAM sites. Uses detection to switch on the SAM site closest to the enemy.
-- * **Automatic mode** (default since 0.8) can set-up your SAM site network automatically for you
-- * **Classic mode** behaves like before
-- * Leverage evasiveness from SEAD, leverage attack range setting
-- * Automatic setup of SHORAD based on groups of the class "short-range"
--
-- # 0. Base considerations and naming conventions
-- 
-- **Before** you start to set up your SAM sites in the mission editor, please think of naming conventions. This is especially critical to make
-- eveything work as intended, also if you have both a blue and a red installation!
-- 
-- You need three **non-overlapping** "name spaces" for everything to work properly:
-- 
-- * SAM sites, e.g. each **group name** begins with "Red SAM"
-- * EWR network and AWACS, e.g. each **group name** begins with "Red EWR" and *not* e.g. "Red SAM EWR" (overlap with  "Red SAM"), "Red EWR Awacs" will be found by "Red EWR"
-- * SHORAD, e.g. each **group name** begins with "Red SHORAD" and *not" e.g. just "SHORAD" because you might also have "Blue SHORAD"
-- 
-- It's important to get this right because of the nature of the filter-system in @{Core.Set#SET_GROUP}. Filters are "greedy", that is they
-- will match *any* string that contains the search string - hence we need to avoid that SAMs, EWR and SHORAD step on each other\'s toes.
-- 
-- Second, for auto-mode to work, the SAMs need the **SAM Type Name** in their group name, as MANTIS will determine their capabilities from this.
-- This is case-sensitive, so "sa-11" is not equal to "SA-11" is not equal to "Sa-11"!
-- 
-- Known SAM types at the time of writing are:
-- 
-- * Avenger
-- * Chaparral
-- * Hawk
-- * Linebacker
-- * NASAMS
-- * Patriot
-- * Rapier
-- * Roland
-- * Silkworm (though strictly speaking this is a surface to ship missile)
-- * SA-2, SA-3, SA-5, SA-6, SA-7, SA-8, SA-9, SA-10, SA-11, SA-13, SA-15, SA-19
-- * From IDF mod: STUNNER IDFA, TAMIR IDFA (Note all caps!)
-- * From HDS (see note on HDS below): SA-2, SA-3, SA-10B, SA-10C, SA-12, SA-17, SA-20A, SA-20B, SA-23, HQ-2
-- 
-- * From SMA: RBS98M, RBS70, RBS90, RBS90M, RBS103A, RBS103B, RBS103AM, RBS103BM, Lvkv9040M 
-- **NOTE** If you are using the Swedish Military Assets (SMA), please note that the **group name** for RBS-SAM types also needs to contain the keyword "SMA"
-- 
-- * From CH: 2S38, PantsirS1, PantsirS2, PGL-625, HQ-17A, M903PAC2, M903PAC3, TorM2, TorM2K, TorM2M, NASAMS3-AMRAAMER, NASAMS3-AIM9X2, C-RAM, PGZ-09, S350-9M100, S350-9M96D
-- **NOTE** If you are using the Military Assets by Currenthill (CH), please note that the **group name** for CH-SAM types also needs to contain the keyword "CHM"
-- 
-- Following the example started above, an SA-6 site group name should start with "Red SAM SA-6" then, or a blue Patriot installation with e.g. "Blue SAM Patriot". 
-- **NOTE** If you are using the High-Digit-Sam Mod, please note that the **group name** for the following SAM types also needs to contain the keyword "HDS":
-- 
-- * SA-2 (with V759 missile, e.g. "Red SAM SA-2 HDS")
-- * SA-2 (with HQ-2 launcher, use HQ-2 in the group name, e.g. "Red SAM HQ-2" )
-- * SA-3 (with V601P missile, e.g. "Red SAM SA-3 HDS")
-- * SA-10B (overlap with other SA-10 types, e.g. "Red SAM SA-10B HDS")
-- * SA-10C (overlap with other SA-10 types, e.g. "Red SAM SA-10C HDS")
-- * SA-12 (launcher dependent range, e.g. "Red SAM SA-12 HDS")
-- * SA-23 (launcher dependent range, e.g. "Red SAM SA-23 HDS") 
-- 
-- The other HDS types work like the rest of the known SAM systems.
-- 
-- # 0.1 Set-up in the mission editor
-- 
-- Set up your SAM sites in the mission editor. Name the groups using a systematic approach like above.
-- Set up your EWR system in the mission editor. Name the groups using a systematic approach like above. Can be e.g. AWACS or a combination of AWACS and Search Radars like e.g. EWR 1L13 etc. 
-- Search Radars usually have "SR" or "STR" in their names. Use the encyclopedia in the mission editor to inform yourself.
-- Set up your SHORAD systems. They need to be **close** to (i.e. around) the SAM sites to be effective. Use **one** group per SAM location. SA-15 TOR systems offer a good missile defense.
-- 
-- [optional] Set up your HQ. Can be any group, e.g. a command vehicle.
--
-- # 1. Basic tactical considerations when setting up your SAM sites
--
-- ## 1.1 Radar systems and AWACS
--
--  Typically, your setup should consist of EWR (early warning) radars to detect and track targets, accompanied by AWACS if your scenario forsees that. Ensure that your EWR radars have a good coverage of the area you want to track.
--  **Location** is of highest importance here. Whilst AWACS in DCS has almost the "all seeing eye", EWR don't have that. Choose your location wisely, against a mountain backdrop or inside a valley even the best EWR system
--  doesn't work well. Prefer higher-up locations with a good view; use F7 in-game to check where you actually placed your EWR and have a look around. Apart from the obvious choice, do also consider other radar units
--  for this role, most have "SR" (search radar) or "STR" (search and track radar) in their names, use the encyclopedia to see what they actually do.
--
-- ## 1.2 SAM sites
--
-- Typically your SAM should cover all attack ranges. The closer the enemy gets, the more systems you will need to deploy to defend your location. Use a combination of long-range systems like the SA-5/10/11, midrange like SA-6 and short-range like
-- SA-2 for defense (Patriot, Hawk, Gepard, Blindfire for the blue side). For close-up defense and defense against HARMs or low-flying aircraft, helicopters it is also advisable to deploy SA-15 TOR systems, Shilka, Strela and Tunguska units, as well as manpads (Think Gepard, Avenger, Chaparral,
-- Linebacker, Roland systems for the blue side). If possible, overlap ranges for mutual coverage.
--
-- ## 1.3 Typical problems
--
-- Often times, people complain because the detection cannot "see" oncoming targets and/or Mantis switches on too late. Three typial problems here are
--
--   * bad placement of radar units,
--   * overestimation how far units can "see" and
--   * not taking into account that a SAM site will take (e.g for a SA-6) 30-40 seconds between switching on, acquiring the target and firing.
--
-- An attacker doing 350knots will cover ca 180meters/second or thus more than 6km until the SA-6 fires. Use triggers zones and the ruler in the mission editor to understand distances and zones. Take into account that the ranges given by the circles
-- in the mission editor are absolute maximum ranges; in-game this is rather 50-75% of that depending on the system. Fiddle with placement and options to see what works best for your scenario, and remember **everything in here is in meters**.
--
-- # 2. Start up your MANTIS with a basic setting
--
--        myredmantis = MANTIS:New("myredmantis","Red SAM","Red EWR",nil,"red",false)
--        myredmantis:Start()
--
-- Use
--
--  *     MANTIS:SetEWRGrouping(radius) [classic mode]
--  *     MANTIS:SetSAMRadius(radius) [classic mode]
--  *     MANTIS:SetDetectInterval(interval) [classic & auto modes]
--  *     MANTIS:SetAutoRelocate(hq, ewr) [classic & auto modes]
--
-- before starting #MANTIS to fine-tune your setup.
--
-- If you want to use a separate AWACS unit to support your EWR system, use e.g. the following setup:
--
--        mybluemantis = MANTIS:New("bluemantis","Blue SAM","Blue EWR",nil,"blue",false,"Blue Awacs")
--        mybluemantis:Start()
-- 
-- ## 2.1 Auto mode features
-- 
-- ### 2.1.1 You can now add Accept-, Reject- and Conflict-Zones to your setup, e.g. to consider borders or de-militarized zones:   
-- 
--        -- Parameters are tables of Core.Zone#ZONE objects!   
--        -- This is effectively a 3-stage filter allowing for zone overlap. A coordinate is accepted first when   
--        -- it is inside any AcceptZone. Then RejectZones are checked, which enforces both borders, but also overlaps of   
--        -- Accept- and RejectZones. Last, if it is inside a conflict zone, it is accepted.   
--        mybluemantis:AddZones(AcceptZones,RejectZones,ConflictZones)   
--        
--        
-- ### 2.1.2 Change the number of long-, mid- and short-range systems going live on a detected target:   
-- 
--        -- parameters are numbers. Defaults are 1,2,2,6 respectively
--        mybluemantis:SetMaxActiveSAMs(Short,Mid,Long,Classic)
-- 
-- ### 2.1.3 SHORAD will automatically be added from SAM sites of type "short-range"   
--        
-- ### 2.1.4 Advanced features   
-- 
--        -- switch off auto mode **before** you start MANTIS.   
--        mybluemantis.automode = false
--        
--        -- switch off auto shorad **before** you start MANTIS.   
--        mybluemantis.autoshorad = false
--        
--        -- scale of the activation range, i.e. don't activate at the fringes of max range, defaults below.   
--        -- also see engagerange below.   
--            self.radiusscale[MANTIS.SamType.LONG] = 1.1   
--            self.radiusscale[MANTIS.SamType.MEDIUM] = 1.2   
--            self.radiusscale[MANTIS.SamType.SHORT] = 1.3 
--        
-- ### 2.1.5 Friendlies check in firing range
-- 
--        -- For some scenarios, like Cold War, it might be useful not to activate SAMs if friendly aircraft are around to avoid death by friendly fire.
--        mybluemantis.checkforfriendlies = true  
-- 
-- # 3. Default settings [both modes unless stated otherwise]
--
-- By default, the following settings are active:
--
--  * SAM_Templates_Prefix = "Red SAM" - SAM site group names in the mission editor begin with "Red SAM"
--  * EWR_Templates_Prefix = "Red EWR" - EWR group names in the mission editor begin with "Red EWR" - can also be combined with an AWACS unit
--  * [classic mode] checkradius = 25000 (meters) - SAMs will engage enemy flights, if they are within a 25km around each SAM site - `MANTIS:SetSAMRadius(radius)`
--  * grouping = 5000 (meters) - Detection (EWR) will group enemy flights to areas of 5km for tracking - `MANTIS:SetEWRGrouping(radius)`
--  * detectinterval = 30 (seconds) - MANTIS will decide every 30 seconds which SAM to activate - `MANTIS:SetDetectInterval(interval)`
--  * engagerange = 95 (percent) - SAMs will only fire if flights are inside of a 95% radius of their max firerange - `MANTIS:SetSAMRange(range)`
--  * dynamic = false - Group filtering is set to once, i.e. newly added groups will not be part of the setup by default - `MANTIS:New(name,samprefix,ewrprefix,hq,coalition,dynamic)`
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
-- # 5. Integrate SHORAD [classic mode, not necessary in automode]
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
--  If you systematically name your SHORAD groups starting with "Blue SHORAD" you'll need exactly **one** SHORAD instance to manage all SHORAD groups.
--  
--  (Optionally) you can remove the link later on with
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
  HQ_Template_CC        = "",
  HQ_CC                 = nil,
  SAM_Table             = {},
  SAM_Table_Long        = {},
  SAM_Table_Medium      = {},
  SAM_Table_Short       = {},
  lid                   = "",
  Detection             = nil,
  AWACS_Detection       = nil,
  debug                 = false,
  checkradius           = 25000,
  grouping              = 5000,
  acceptrange           = 80000,
  detectinterval        = 30,
  engagerange           = 95,
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
  ShoradActDistance     = 25000,
  UseEmOnOff            = false,
  TimeStamp             = 0,
  state2flag            = false,
  SamStateTracker       = {},
  DLink                 = false,
  DLTimeStamp           = 0,
  Padding               = 10,
  SuppressedGroups      = {},
  automode              = true,
  autoshorad            = true,
  ShoradGroupSet        = nil,
  checkforfriendlies    = false,
}

--- Advanced state enumerator
-- @type MANTIS.AdvancedState
MANTIS.AdvancedState = {
  GREEN = 0,
  AMBER = 1,
  RED = 2,
}

--- SAM Type
-- @type MANTIS.SamType
MANTIS.SamType = {
  SHORT = "Short",
  MEDIUM = "Medium",
  LONG = "Long",
}

--- SAM data
-- @type MANTIS.SamData
-- @field #number Range Max firing range in km
-- @field #number Blindspot no-firing range (green circle)
-- @field #number Height Max firing height in km
-- @field #string Type #MANTIS.SamType of SAM, i.e. SHORT, MEDIUM or LONG (range)
-- @field #string Radar Radar typename on unit level (used as key)
MANTIS.SamData = {
  ["Hawk"] = { Range=35, Blindspot=0, Height=12, Type="Medium", Radar="Hawk" }, -- measures in km
  ["NASAMS"] = { Range=14, Blindspot=0, Height=7, Type="Short", Radar="NSAMS" }, -- AIM 120B
  ["Patriot"] = { Range=99, Blindspot=0, Height=25, Type="Long", Radar="Patriot" },
  ["Rapier"] = { Range=10, Blindspot=0, Height=3, Type="Short", Radar="rapier" },
  ["SA-2"] = { Range=40, Blindspot=7, Height=25, Type="Medium", Radar="S_75M_Volhov" },
  ["SA-3"] = { Range=18, Blindspot=6, Height=18, Type="Short", Radar="5p73 s-125 ln" },
  ["SA-5"] = { Range=250, Blindspot=7, Height=40, Type="Long", Radar="5N62V" },
  ["SA-6"] = { Range=25, Blindspot=0, Height=8, Type="Medium", Radar="1S91" },
  ["SA-10"] = { Range=119, Blindspot=0, Height=18, Type="Long" , Radar="S-300PS 4"},
  ["SA-11"] = { Range=35, Blindspot=0, Height=20, Type="Medium", Radar="SA-11" },
  ["Roland"] = { Range=5, Blindspot=0, Height=5, Type="Short", Radar="Roland" },
  ["HQ-7"] = { Range=12, Blindspot=0, Height=3, Type="Short", Radar="HQ-7" },
  ["SA-9"] = { Range=4, Blindspot=0, Height=3, Type="Short", Radar="Strela" },
  ["SA-8"] = { Range=10, Blindspot=0, Height=5, Type="Short", Radar="Osa 9A33" },
  ["SA-19"] = { Range=8, Blindspot=0, Height=3, Type="Short", Radar="Tunguska" },
  ["SA-15"] = { Range=11, Blindspot=0, Height=6, Type="Short", Radar="Tor 9A331" },
  ["SA-13"] = { Range=5, Blindspot=0, Height=3, Type="Short", Radar="Strela" },
  ["Avenger"] = { Range=4, Blindspot=0, Height=3, Type="Short", Radar="Avenger" },
  ["Chaparral"] = { Range=8, Blindspot=0, Height=3, Type="Short", Radar="Chaparral" },
  ["Linebacker"] = { Range=4, Blindspot=0, Height=3, Type="Short", Radar="Linebacker" },
  ["Silkworm"] = { Range=90, Blindspot=1, Height=0.2, Type="Long", Radar="Silkworm" },
  -- units from HDS Mod, multi launcher options is tricky
  ["SA-10B"] = { Range=75, Blindspot=0, Height=18, Type="Medium" , Radar="SA-10B"},
  ["SA-17"] = { Range=50, Blindspot=3, Height=30, Type="Medium", Radar="SA-17" },
  ["SA-20A"] = { Range=150, Blindspot=5, Height=27, Type="Long" , Radar="S-300PMU1"},
  ["SA-20B"] = { Range=200, Blindspot=4, Height=27, Type="Long" , Radar="S-300PMU2"},
  ["HQ-2"] = { Range=50, Blindspot=6, Height=35, Type="Medium", Radar="HQ_2_Guideline_LN" },
  ["SHORAD"] = { Range=3, Blindspot=0, Height=3, Type="Short", Radar="Igla" },
  ["TAMIR IDFA"] = { Range=20, Blindspot=0.6, Height=12.3, Type="Short", Radar="IRON_DOME_LN" },
  ["STUNNER IDFA"] = { Range=250, Blindspot=1, Height=45, Type="Long", Radar="DAVID_SLING_LN" },   
}

--- SAM data HDS
-- @type MANTIS.SamDataHDS
-- @field #number Range Max firing range in km
-- @field #number Blindspot no-firing range (green circle)
-- @field #number Height Max firing height in km
-- @field #string Type #MANTIS.SamType of SAM, i.e. SHORT, MEDIUM or LONG (range)
-- @field #string Radar Radar typename on unit level (used as key)
MANTIS.SamDataHDS = {
  -- units from HDS Mod, multi launcher options is tricky
  -- group name MUST contain HDS to ID launcher type correctly!
  ["SA-2 HDS"] = { Range=56, Blindspot=7, Height=30, Type="Medium", Radar="V759" }, 
  ["SA-3 HDS"] = { Range=20, Blindspot=6, Height=30, Type="Short", Radar="V-601P" },  
  ["SA-10C HDS 2"] = { Range=90, Blindspot=5, Height=25, Type="Long" , Radar="5P85DE ln"}, -- V55RUD
  ["SA-10C HDS 1"] = { Range=90, Blindspot=5, Height=25, Type="Long" , Radar="5P85CE ln"}, -- V55RUD
  ["SA-12 HDS 2"] = { Range=100, Blindspot=10, Height=25, Type="Long" , Radar="S-300V 9A82 l"},
  ["SA-12 HDS 1"] = { Range=75, Blindspot=1, Height=25, Type="Long" , Radar="S-300V 9A83 l"},
  ["SA-23 HDS 2"] = { Range=200, Blindspot=5, Height=37, Type="Long", Radar="S-300VM 9A82ME" },
  ["SA-23 HDS 1"] = { Range=100, Blindspot=1, Height=50, Type="Long", Radar="S-300VM 9A83ME" },
  ["HQ-2 HDS"] = { Range=50, Blindspot=6, Height=35, Type="Medium", Radar="HQ_2_Guideline_LN" },
}

--- SAM data SMA
-- @type MANTIS.SamDataSMA
-- @field #number Range Max firing range in km
-- @field #number Blindspot no-firing range (green circle)
-- @field #number Height Max firing height in km
-- @field #string Type #MANTIS.SamType of SAM, i.e. SHORT, MEDIUM or LONG (range)
-- @field #string Radar Radar typename on unit level (used as key)
MANTIS.SamDataSMA = {
  -- units from SMA Mod (Sweedish Military Assets)
  -- https://forum.dcs.world/topic/295202-swedish-military-assets-for-dcs-by-currenthill/
  -- group name MUST contain SMA to ID launcher type correctly!
  ["RBS98M SMA"] = { Range=20, Blindspot=0, Height=8, Type="Short", Radar="RBS-98" },
  ["RBS70 SMA"] = { Range=8, Blindspot=0, Height=5.5, Type="Short", Radar="RBS-70" },  
  ["RBS70M SMA"] = { Range=8, Blindspot=0, Height=5.5, Type="Short", Radar="BV410_RBS70" }, 
  ["RBS90 SMA"] = { Range=8, Blindspot=0, Height=5.5, Type="Short", Radar="RBS-90" }, 
  ["RBS90M SMA"] = { Range=8, Blindspot=0, Height=5.5, Type="Short", Radar="BV410_RBS90" },  
  ["RBS103A SMA"] = { Range=150, Blindspot=3, Height=24.5, Type="Long", Radar="LvS-103_Lavett103_Rb103A" },
  ["RBS103B SMA"] = { Range=35, Blindspot=0, Height=36, Type="Medium", Radar="LvS-103_Lavett103_Rb103B" }, 
  ["RBS103AM SMA"] = { Range=150, Blindspot=3, Height=24.5, Type="Long", Radar="LvS-103_Lavett103_HX_Rb103A" },
  ["RBS103BM SMA"] = { Range=35, Blindspot=0, Height=36, Type="Medium", Radar="LvS-103_Lavett103_HX_Rb103B" },
  ["Lvkv9040M SMA"] = { Range=4, Blindspot=0, Height=2.5, Type="Short", Radar="LvKv9040" },      
}

--- SAM data CH
-- @type MANTIS.SamDataCH
-- @field #number Range Max firing range in km
-- @field #number Blindspot no-firing range (green circle)
-- @field #number Height Max firing height in km
-- @field #string Type #MANTIS.SamType of SAM, i.e. SHORT, MEDIUM or LONG (range)
-- @field #string Radar Radar typename on unit level (used as key)
MANTIS.SamDataCH = {
    -- units from CH (Military Assets by Currenthill)
    -- https://www.currenthill.com/
    -- group name MUST contain CHM to ID launcher type correctly!
   ["2S38 CHM"] = { Range=8, Blindspot=0.5, Height=6, Type="Short", Radar="2S38" },
   ["PantsirS1 CHM"] = { Range=20, Blindspot=1.2, Height=15, Type="Short", Radar="PantsirS1" }, 
   ["PantsirS2 CHM"] = { Range=30, Blindspot=1.2, Height=18, Type="Medium", Radar="PantsirS2" }, 
   ["PGL-625 CHM"] = { Range=10, Blindspot=0.5, Height=5, Type="Short", Radar="PGL_625" }, 
   ["HQ-17A CHM"] = { Range=20, Blindspot=1.5, Height=10, Type="Short", Radar="HQ17A" }, 
   ["M903PAC2 CHM"] = { Range=160, Blindspot=3, Height=24.5, Type="Long", Radar="MIM104_M903_PAC2" },
   ["M903PAC3 CHM"] = { Range=120, Blindspot=1, Height=40, Type="Long", Radar="MIM104_M903_PAC3" }, 
   ["TorM2 CHM"] = { Range=12, Blindspot=1, Height=10, Type="Short", Radar="TorM2" },
   ["TorM2K CHM"] = { Range=12, Blindspot=1, Height=10, Type="Short", Radar="TorM2K" },
   ["TorM2M CHM"] = { Range=16, Blindspot=1, Height=10, Type="Short", Radar="TorM2M" }, 
   ["NASAMS3-AMRAAMER CHM"] = { Range=50, Blindspot=2, Height=35.7, Type="Medium", Radar="CH_NASAMS3_LN_AMRAAM_ER" }, 
   ["NASAMS3-AIM9X2 CHM"] = { Range=20, Blindspot=0.2, Height=18, Type="Short", Radar="CH_NASAMS3_LN_AIM9X2" },
   ["C-RAM CHM"] = { Range=2, Blindspot=0, Height=2, Type="Short", Radar="CH_Centurion_C_RAM" }, 
   ["PGZ-09 CHM"] = { Range=4, Blindspot=0, Height=3, Type="Short", Radar="CH_PGZ09" },
   ["S350-9M100 CHM"] = { Range=15, Blindspot=1.5, Height=8, Type="Short", Radar="CH_S350_50P6_9M100" },
   ["S350-9M96D CHM"] = { Range=150, Blindspot=2.5, Height=30, Type="Long", Radar="CH_S350_50P6_9M96D" },
   ["LAV-AD CHM"] = { Range=8, Blindspot=0.2, Height=4.8, Type="Short", Radar="CH_LAVAD" }, 
   ["HQ-22 CHM"] = { Range=170, Blindspot=5, Height=27, Type="Long", Radar="CH_HQ22_LN" }, 
   ["PGZ-95 CHM"] = { Range=2, Blindspot=0, Height=2, Type="Short", Radar="CH_PGZ95" },
   ["LD-3000 CHM"] = { Range=3, Blindspot=0, Height=3, Type="Short", Radar="CH_LD3000_stationary" }, 
   ["LD-3000M CHM"] = { Range=3, Blindspot=0, Height=3, Type="Short", Radar="CH_LD3000" },  
   ["FlaRakRad CHM"] = { Range=8, Blindspot=1.5, Height=6, Type="Short", Radar="HQ17A" },  
   ["IRIS-T SLM CHM"] = { Range=40, Blindspot=0.5, Height=20, Type="Medium", Radar="CH_IRIST_SLM" }, 
   ["M903PAC2KAT1 CHM"] = { Range=160, Blindspot=3, Height=24.5, Type="Long", Radar="CH_MIM104_M903_PAC2_KAT1" }, 
   ["Skynex CHM"] = { Range=3.5, Blindspot=0, Height=3.5, Type="Short", Radar="CH_SkynexHX" },
   ["Skyshield CHM"] = { Range=3.5, Blindspot=0, Height=3.5, Type="Short", Radar="CH_Skyshield_Gun" },
   ["WieselOzelot CHM"] = { Range=8, Blindspot=0.2, Height=4.8, Type="Short", Radar="CH_Wiesel2Ozelot" }, 
   ["BukM3-9M317M CHM"] = { Range=70, Blindspot=0.25, Height=35, Type="Medium", Radar="CH_BukM3_9A317M" },  
   ["BukM3-9M317MA CHM"] = { Range=70, Blindspot=0.25, Height=35, Type="Medium", Radar="CH_BukM3_9A317MA" },  
   ["SkySabre CHM"] = { Range=30, Blindspot=0.5, Height=10, Type="Medium", Radar="CH_SkySabreLN" },  
   ["Stormer CHM"] = { Range=7.5, Blindspot=0.3, Height=7, Type="Short", Radar="CH_StormerHVM" },  
   ["THAAD CHM"] = { Range=200, Blindspot=40, Height=150, Type="Long", Radar="CH_THAAD_M1120" },  
   ["USInfantryFIM92K CHM"] = { Range=8, Blindspot=0.2, Height=4.8, Type="Short", Radar="CH_USInfantry_FIM92" }, 
   ["RBS98M CHM"] = { Range=20, Blindspot=0, Height=8, Type="Short", Radar="RBS-98" },
   ["RBS70 CHM"] = { Range=8, Blindspot=0, Height=5.5, Type="Short", Radar="RBS-70" },  
   ["RBS90 CHM"] = { Range=8, Blindspot=0, Height=5.5, Type="Short", Radar="RBS-90" },  
   ["RBS103A CHM"] = { Range=150, Blindspot=3, Height=24.5, Type="Long", Radar="LvS-103_Lavett103_Rb103A" },
   ["RBS103B CHM"] = { Range=35, Blindspot=0, Height=36, Type="Medium", Radar="LvS-103_Lavett103_Rb103B" }, 
   ["RBS103AM CHM"] = { Range=150, Blindspot=3, Height=24.5, Type="Long", Radar="LvS-103_Lavett103_HX_Rb103A" },
   ["RBS103BM CHM"] = { Range=35, Blindspot=0, Height=36, Type="Medium", Radar="LvS-103_Lavett103_HX_Rb103B" },
   ["Lvkv9040M CHM"] = { Range=4, Blindspot=0, Height=2.5, Type="Short", Radar="LvKv9040" },  
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
  --@param #string coalition Coalition side of your setup, e.g. "blue", "red" or "neutral"
  --@param #boolean dynamic Use constant (true) filtering or just filter once (false, default) (optional)
  --@param #string awacs Group name of your Awacs (optional)
  --@param #boolean EmOnOff Make MANTIS switch Emissions on and off instead of changing the alarm state between RED and GREEN (optional)
  --@param #number Padding For #SEAD - Extra number of seconds to add to radar switch-back-on time (optional)
  --@param #table Zones Table of Core.Zone#ZONE Zones Consider SAM groups in this zone(s) only for this MANTIS instance, must be handed as #table of Zone objects
  --@return #MANTIS self
  --@usage Start up your MANTIS with a basic setting
  --
  --        myredmantis = MANTIS:New("myredmantis","Red SAM","Red EWR",nil,"red",false)
  --        myredmantis:Start()
  --
  -- [optional] Use
  --
  --        myredmantis:SetDetectInterval(interval)
  --        myredmantis:SetAutoRelocate(hq, ewr)
  --
  -- before starting #MANTIS to fine-tune your setup.
  --
  -- If you want to use a separate AWACS unit (default detection range: 250km) to support your EWR system, use e.g. the following setup:
  --
  --        mybluemantis = MANTIS:New("bluemantis","Blue SAM","Blue EWR",nil,"blue",false,"Blue Awacs")
  --        mybluemantis:Start()
  --
  function MANTIS:New(name,samprefix,ewrprefix,hq,coalition,dynamic,awacs, EmOnOff, Padding, Zones)
    
    
    -- Inherit everything from BASE class.
    local self = BASE:Inherit(self, FSM:New()) -- #MANTIS
    
    -- DONE: Create some user functions for these
    -- DONE: Make HQ useful
    -- DONE: Set SAMs to auto if EWR dies
    -- DONE: Refresh SAM table in dynamic mode
    -- DONE: Treat Awacs separately, since they might be >80km off site
    -- DONE: Allow tables of prefixes for the setup
    -- DONE: Auto-Mode with range setups for various known SAM types.
    
    self.name = name or "mymantis"
    self.SAM_Templates_Prefix = samprefix or "Red SAM"
    self.EWR_Templates_Prefix = ewrprefix or "Red EWR"
    self.HQ_Template_CC = hq or nil
    self.Coalition = coalition or "red"
    self.SAM_Table = {}
    self.SAM_Table_Long = {}
    self.SAM_Table_Medium = {}
    self.SAM_Table_Short = {}
    self.dynamic = dynamic or false
    self.checkradius = 25000
    self.grouping = 5000
    self.acceptrange = 80000
    self.detectinterval = 30
    self.engagerange = 95
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
    self.ShoradActDistance = 25000
    self.TimeStamp = timer.getAbsTime()
    self.relointerval = math.random(1800,3600) -- random between 30 and 60 mins
    self.state2flag = false
    self.SamStateTracker = {} -- table to hold alert states, so we don't trigger state changes twice in adv mode
    self.DLink = false
    self.Padding = Padding or 10
    self.SuppressedGroups = {}
    -- 0.8 additions
    self.automode = true
    self.radiusscale = {}
    self.radiusscale[MANTIS.SamType.LONG] = 1.1
    self.radiusscale[MANTIS.SamType.MEDIUM] = 1.2
    self.radiusscale[MANTIS.SamType.SHORT] = 1.3
    --self.SAMCheckRanges = {}
    self.usezones = false
    self.AcceptZones = {}
    self.RejectZones = {}
    self.ConflictZones = {}
    self.maxlongrange = 1
    self.maxmidrange = 2
    self.maxshortrange = 2
    self.maxclassic = 6
    self.autoshorad = true
    self.ShoradGroupSet = SET_GROUP:New() -- Core.Set#SET_GROUP
    self.FilterZones = Zones
    
    self.SkateZones = nil
    self.SkateNumber =  3
    self.shootandscoot = false   
    
    self.UseEmOnOff = true
    if EmOnOff == false then
      self.UseEmOnOff = false
    end

    if type(awacs) == "string" then
      self.advAwacs = true
    else
      self.advAwacs = false
    end

    -- Set the string id for output to DCS.log file.
    self.lid=string.format("MANTIS %s | ", self.name)

    -- Debug trace.
    if self.debug then
      BASE:TraceOnOff(true)
      BASE:TraceClass(self.ClassName)
      --BASE:TraceClass("SEAD")
      BASE:TraceLevel(1)
    end
    
    self.ewr_templates = {}
    if type(samprefix) ~= "table" then
      self.SAM_Templates_Prefix = {samprefix}
    end
    
    if type(ewrprefix) ~= "table" then
      self.EWR_Templates_Prefix = {ewrprefix}
    end
    
    for _,_group in pairs (self.SAM_Templates_Prefix) do
      table.insert(self.ewr_templates,_group)
    end
    
    for _,_group in pairs (self.EWR_Templates_Prefix) do
      table.insert(self.ewr_templates,_group)
    end
    
    if self.advAwacs then
      table.insert(self.ewr_templates,awacs)
    end
    
    self:T({self.ewr_templates})
    
    self.SAM_Group = SET_GROUP:New():FilterPrefixes(self.SAM_Templates_Prefix):FilterCoalitions(self.Coalition)
    self.EWR_Group = SET_GROUP:New():FilterPrefixes(self.ewr_templates):FilterCoalitions(self.Coalition)
    
    if self.FilterZones then
      self.SAM_Group:FilterZones(self.FilterZones)
    end
    
    if self.dynamic then
      -- Set SAM SET_GROUP
      self.SAM_Group:FilterStart()
      -- Set EWR SET_GROUP
      self.EWR_Group:FilterStart()
    else
      -- Set SAM SET_GROUP
      self.SAM_Group:FilterOnce()
      -- Set EWR SET_GROUP
      self.EWR_Group:FilterOnce()
    end

    -- set up CC
    if self.HQ_Template_CC then
      self.HQ_CC = GROUP:FindByName(self.HQ_Template_CC)
    end
    
    -- TODO Version
    -- @field #string version
    self.version="0.8.22"
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
  -- @param Wrapper.Group#GROUP Attacker The attacking GROUP object

  --- On After "SeadSuppressionStart" event. Mantis has switched off a site to defend a SEAD attack.
  -- @function [parent=#MANTIS] OnAfterSeadSuppressionStart
  -- @param #MANTIS self
  -- @param #string From The From State
  -- @param #string Event The Event
  -- @param #string To The To State
  -- @param Wrapper.Group#GROUP Group The suppressed GROUP object
  -- @param #string Name Name of the suppressed group
  -- @param Wrapper.Group#GROUP Attacker The attacking GROUP object

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
  
  --- Add a SET_ZONE of zones for Shoot&Scoot - SHORAD units will move around
  -- @param #MANTIS self
  -- @param Core.Set#SET_ZONE ZoneSet Set of zones to be used. Units will move around to the next (random) zone between 100m and 3000m away.
  -- @param #number Number Number of closest zones to be considered, defaults to 3.
  -- @param #boolean Random If true, use a random coordinate inside the next zone to scoot to.
  -- @param #string Formation Formation to use, defaults to "Cone". See mission editor dropdown for options.
  -- @return #MANTIS self
  function MANTIS:AddScootZones(ZoneSet, Number, Random, Formation)
    self:T(self.lid .. " AddScootZones")
    self.SkateZones = ZoneSet
    self.SkateNumber = Number or 3
    self.shootandscoot = true
    self.ScootRandom = Random
    self.ScootFormation = Formation or "Cone"    
    return self
  end
  
  --- Function to set accept and reject zones.
  -- @param #MANTIS self
  -- @param #table AcceptZones Table of @{Core.Zone#ZONE} objects
  -- @param #table RejectZones Table of @{Core.Zone#ZONE} objects
  -- @param #table ConflictZones Table of @{Core.Zone#ZONE} objects
  -- @return #MANTIS self
  -- @usage
  -- Parameters are **tables of Core.Zone#ZONE** objects!   
  -- This is effectively a 3-stage filter allowing for zone overlap. A coordinate is accepted first when   
  -- it is inside any AcceptZone. Then RejectZones are checked, which enforces both borders, but also overlaps of   
  -- Accept- and RejectZones. Last, if it is inside a conflict zone, it is accepted.   
  function MANTIS:AddZones(AcceptZones,RejectZones, ConflictZones)
    self:T(self.lid .. "AddZones")
    self.AcceptZones = AcceptZones or {}
    self.RejectZones = RejectZones or {}
    self.ConflictZones = ConflictZones or {}
    if #self.AcceptZones > 0 or #self.RejectZones > 0 or #self.ConflictZones > 0 then
      self.usezones = true
    end
    return self
  end
  
  --- Function to set the detection radius of the EWR in meters. (Deprecated, SAM range is used)
  -- @param #MANTIS self
  -- @param #number radius Radius of the EWR detection zone
  function MANTIS:SetEWRRange(radius)
    self:T(self.lid .. "SetEWRRange")
    --local radius = radius or 80000
    -- self.acceptrange = radius
    return self
  end

  --- Function to set switch-on/off zone for the SAM sites in meters. Overwritten per SAM in automode.
  -- @param #MANTIS self
  -- @param #number radius Radius of the firing zone in classic mode
  function MANTIS:SetSAMRadius(radius)
    self:T(self.lid .. "SetSAMRadius")
    local radius = radius or 25000
    self.checkradius = radius
    return self
  end

  --- Function to set SAM firing engage range, 0-100 percent, e.g. 85
  -- @param #MANTIS self
  -- @param #number range Percent of the max fire range
  function MANTIS:SetSAMRange(range)
    self:T(self.lid .. "SetSAMRange")
    local range = range or 95
    if range < 0 or range > 100 then
      range = 95
    end
    self.engagerange = range
    return self
  end
  
    --- Function to set number of SAMs going active on a valid, detected thread
    -- @param #MANTIS self
    -- @param #number Short Number of short-range systems activated, defaults to 1.
    -- @param #number Mid Number of mid-range systems activated, defaults to 2.
    -- @param #number Long Number of long-range systems activated, defaults to 2.
    -- @param #number Classic (non-automode) Number of overall systems activated, defaults to 6.
    -- @return #MANTIS self
  function MANTIS:SetMaxActiveSAMs(Short,Mid,Long,Classic)
    self:T(self.lid .. "SetMaxActiveSAMs")
    self.maxclassic = Classic or 6
    self.maxlongrange = Long or 1
    self.maxmidrange = Mid or 2
    self.maxshortrange = Short or 2
    return self
  end

  --- Function to set a new SAM firing engage range, use this method to adjust range while running MANTIS, e.g. for different setups day and night
  -- @param #MANTIS self
  -- @param #number range Percent of the max fire range
  function MANTIS:SetNewSAMRangeWhileRunning(range)
    self:T(self.lid .. "SetNewSAMRangeWhileRunning")
    local range = range or 95
    if range < 0 or range > 100 then
      range = 95
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
  -- @return Wrapper.Group#GROUP The HQ #GROUP object or *nil* if it doesn't exist
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
  -- @param Wrapper.Group#GROUP group The #GROUP object to be set as HQ
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

  --- Set using your own #INTEL_DLINK object instead of #DETECTION
  -- @param #MANTIS self
  -- @param Ops.Intel#INTEL_DLINK DLink The data link object to be used.
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
  -- @return #MANTIS self 
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
          _hqgrp:RelocateGroundRandomInRadius(20,500,true,true,nil,true)
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
              _grp:RelocateGroundRandomInRadius(20,500,true,true,nil,true)
             end
         end
      end
    end
    return self
  end
  
  --- [Internal] Function to check accept and reject zones
  -- @param #MANTIS self
  -- @param Core.Point#COORDINATE coord The coordinate to check
  -- @return #boolean outcome
  function MANTIS:_CheckCoordinateInZones(coord)
    -- DEBUG
    self:T(self.lid.."_CheckCoordinateInZones")
    local inzone = false
    -- acceptzones
    if #self.AcceptZones > 0 then
      for _,_zone in pairs(self.AcceptZones) do
        local zone = _zone -- Core.Zone#ZONE
        if zone:IsCoordinateInZone(coord) then
          inzone = true
          self:T(self.lid.."Target coord in Accept Zone!")
          break
        end
      end
    end
    -- rejectzones
    if #self.RejectZones > 0 and inzone then -- maybe in accept zone, but check the overlaps
      for _,_zone in pairs(self.RejectZones) do
        local zone = _zone -- Core.Zone#ZONE
        if zone:IsCoordinateInZone(coord) then
          inzone = false
          self:T(self.lid.."Target coord in Reject Zone!")
          break
        end
      end
    end
    -- conflictzones
    if #self.ConflictZones > 0 and not inzone then -- if not already accepted, might be in conflict zones
      for _,_zone in pairs(self.ConflictZones) do
        local zone = _zone -- Core.Zone#ZONE
        if zone:IsCoordinateInZone(coord) then
          inzone = true
          self:T(self.lid.."Target coord in Conflict Zone!")
          break
        end
      end
    end   
    return inzone
  end
  
  --- [Internal] Function to prefilter height based
  -- @param #MANTIS self
  -- @param #number height
  -- @return #table set
  function MANTIS:_PreFilterHeight(height)
    self:T(self.lid.."_PreFilterHeight")   
    local set = {}
    local dlink = self.Detection -- Ops.Intel#INTEL_DLINK
    local detectedgroups = dlink:GetContactTable()
    for _,_contact in pairs(detectedgroups) do
      local contact = _contact -- Ops.Intel#INTEL.Contact
      local grp = contact.group -- Wrapper.Group#GROUP
      if grp:IsAlive() then
        if grp:GetHeight(true) < height then
          local coord = grp:GetCoordinate()
          table.insert(set,coord)
        end
      end
    end
    return set
  end
  
  --- [Internal] Function to check if any object is in the given SAM zone
  -- @param #MANTIS self
  -- @param #table dectset Table of coordinates of detected items
  -- @param Core.Point#COORDINATE samcoordinate Coordinate object.
  -- @param #number radius Radius to check.
  -- @param #number height Height to check.
  -- @param #boolean dlink Data from DLINK.
  -- @return #boolean True if in any zone, else false
  -- @return #number Distance Target distance in meters or zero when no object is in zone
  function MANTIS:_CheckObjectInZone(dectset, samcoordinate, radius, height, dlink)
    self:T(self.lid.."_CheckObjectInZone")
    -- check if non of the coordinate is in the given defense zone
    local rad = radius or self.checkradius
    local set = dectset
    if dlink then
      -- DEBUG
      set = self:_PreFilterHeight(height)
    end
    --self.friendlyset -- Core.Set#SET_GROUP
    if self.checkforfriendlies == true and self.friendlyset == nil then
      self.friendlyset = SET_GROUP:New():FilterCoalitions(self.Coalition):FilterCategories({"plane","helicopter"}):FilterFunction(function(grp) if grp and grp:InAir() then return true else return false end end):FilterStart()
    end
    for _,_coord in pairs (set) do
      local coord = _coord  -- get current coord to check
      -- output for cross-check
      local targetdistance = samcoordinate:DistanceFromPointVec2(coord)
      if not targetdistance then
        targetdistance = samcoordinate:Get2DDistance(coord)
      end
      -- check accept/reject zones
      local zonecheck = true
      if self.usezones then
        -- DONE
        zonecheck = self:_CheckCoordinateInZones(coord)
      end
      if self.verbose and self.debug then
        --local dectstring = coord:ToStringLLDMS()
        local samstring = samcoordinate:ToStringMGRS({MGRS_Accuracy=0})
        samstring = string.gsub(samstring,"%s","")
        local inrange = "false"
        if targetdistance <= rad then
          inrange = "true"
        end
        local text = string.format("Checking SAM at %s | Tgtdist %.1fkm | Rad %.1fkm | Inrange %s", samstring, targetdistance/1000, rad/1000, inrange)
        local m = MESSAGE:New(text,10,"Check"):ToAllIf(self.debug)
        self:T(self.lid..text)
      end
      -- friendlies around?
      local nofriendlies = true
      if self.checkforfriendlies == true then
        local closestfriend, distance = self.friendlyset:GetClosestGroup(samcoordinate)
        if closestfriend and distance and distance < rad then
          nofriendlies = false
        end
      end
      -- end output to cross-check
      if targetdistance <= rad and zonecheck == true and nofriendlies == true then
        return true, targetdistance
      end
    end
    return false, 0
  end

  --- [Internal] Function to start the detection via EWR groups - if INTEL isn\'t available
  -- @param #MANTIS self
  -- @return Functional.Detection #DETECTION_AREAS The running detection set
  function MANTIS:StartDetection()
    self:T(self.lid.."Starting Detection")

    -- start detection
    local groupset = self.EWR_Group
    local grouping = self.grouping or 5000
    --local acceptrange = self.acceptrange or 80000
    local interval = self.detectinterval or 20
    
    local MANTISdetection = DETECTION_AREAS:New( groupset, grouping ) --[Internal] Grouping detected objects to 5000m zones
    MANTISdetection:FilterCategories({ Unit.Category.AIRPLANE, Unit.Category.HELICOPTER })
    --MANTISdetection:SetAcceptRange(acceptrange) -- deprecated - in range of SAMs is used anyway
    MANTISdetection:SetRefreshTimeInterval(interval)
    MANTISdetection:__Start(2)

    return MANTISdetection
  end
  
  --- [Internal] Function to start the detection with INTEL via EWR groups
  -- @param #MANTIS self
  -- @return Ops.Intel#INTEL_DLINK The running detection set
  function MANTIS:StartIntelDetection()
    self:T(self.lid.."Starting Intel Detection")
    -- DEBUG
    -- start detection
    local groupset = self.EWR_Group
    local samset = self.SAM_Group
    
    self.intelset = {}
    
    local IntelOne = INTEL:New(groupset,self.Coalition,self.name.." IntelOne")
    --IntelOne:SetClusterAnalysis(true,true)
    --IntelOne:SetClusterRadius(5000)
    IntelOne:Start()
    
    local IntelTwo = INTEL:New(samset,self.Coalition,self.name.." IntelTwo")
    --IntelTwo:SetClusterAnalysis(true,true)
    --IntelTwo:SetClusterRadius(5000)
    IntelTwo:Start()
    
    local IntelDlink = INTEL_DLINK:New({IntelOne,IntelTwo},self.name.." DLINK",22,300)
    IntelDlink:__Start(1)
    
    self:SetUsingDLink(IntelDlink)
    
    table.insert(self.intelset, IntelOne)
    table.insert(self.intelset, IntelTwo)
    
    return IntelDlink
  end
  
  --- [Internal] Function to start the detection via AWACS if defined as separate (classic)
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

    return MANTISAwacs
  end
  
   --- [Internal] Function to get SAM firing data from units types.
  -- @param #MANTIS self
  -- @param #string grpname Name of the group
  -- @param #boolean mod HDS mod flag
  -- @param #boolean sma SMA mod flag
  -- @param #boolean chm CH mod flag
  -- @return #number range Max firing range
  -- @return #number height Max firing height
  -- @return #string type Long, medium or short range
  -- @return #number blind "blind" spot
  function MANTIS:_GetSAMDataFromUnits(grpname,mod,sma,chm)
    self:T(self.lid.."_GetSAMDataFromUnits")
    local found = false
    local range = self.checkradius
    local height = 3000
    local type = MANTIS.SamType.MEDIUM
    local radiusscale = self.radiusscale[type]
    local blind = 0
    local group = GROUP:FindByName(grpname) -- Wrapper.Group#GROUP
    local units = group:GetUnits()
    local SAMData = self.SamData
    if mod then
      SAMData = self.SamDataHDS
    elseif sma then
      SAMData = self.SamDataSMA
    elseif chm then
      SAMData = self.SamDataCH
    end
    --self:T("Looking to auto-match for "..grpname)
    for _,_unit in pairs(units) do
      local unit = _unit -- Wrapper.Unit#UNIT
      local type = string.lower(unit:GetTypeName())
      --self:I(string.format("Matching typename: %s",type))
      for idx,entry in pairs(SAMData) do
        local _entry = entry -- #MANTIS.SamData
        local _radar = string.lower(_entry.Radar)
        --self:I(string.format("Trying typename: %s",_radar))
        if string.find(type,_radar,1,true) then
          type = _entry.Type
          radiusscale = self.radiusscale[type]
          range = _entry.Range * 1000 * radiusscale -- max firing range used as switch-on
          height = _entry.Height * 1000 -- max firing height
          blind = _entry.Blindspot * 100 -- blind spot range 
          --self:I(string.format("Match: %s - %s",_radar,type))
          found = true
          break
        end
      end
      if found then break end
    end
    if not found then
      self:E(self.lid .. string.format("*****Could not match radar data for %s! Will default to midrange values!",grpname))
    end
    return range, height, type, blind
  end
  
  --- [Internal] Function to get SAM firing data
  -- @param #MANTIS self
  -- @param #string grpname Name of the group
  -- @return #number range Max firing range
  -- @return #number height Max firing height
  -- @return #string type Long, medium or short range
  -- @return #number blind "blind" spot
  function MANTIS:_GetSAMRange(grpname)
    self:T(self.lid.."_GetSAMRange for "..tostring(grpname))
    local range = self.checkradius
    local height = 3000
    local type = MANTIS.SamType.MEDIUM
    local radiusscale = self.radiusscale[type]
    local blind = 0
    local found = false
    local HDSmod = false
    local SMAMod = false
    local CHMod = false
    if string.find(grpname,"HDS",1,true) then
      HDSmod = true
    elseif string.find(grpname,"SMA",1,true) then
      SMAMod = true
    elseif string.find(grpname,"CHM",1,true) then
      CHMod = true
    end
    --if self.automode then
      for idx,entry in pairs(self.SamData) do
        self:T("ID = " .. idx)
        if string.find(grpname,idx,1,true) then
          local _entry = entry -- #MANTIS.SamData
          type = _entry.Type
          radiusscale = self.radiusscale[type]
          range = _entry.Range * 1000 * radiusscale -- max firing range
          height = _entry.Height * 1000 -- max firing height        
          blind = _entry.Blindspot 
          self:T("Matching Groupname = " .. grpname .. " Range= " .. range)
          found = true
          break
        end
      end
    --end
    -- secondary filter if not found
    if (not found) or HDSmod or SMAMod or CHMod then
      range, height, type = self:_GetSAMDataFromUnits(grpname,HDSmod,SMAMod,CHMod)
    elseif not found then
      self:E(self.lid .. string.format("*****Could not match radar data for %s! Will default to midrange values!",grpname))
    end
    if string.find(grpname,"SHORAD",1,true) then
      type = MANTIS.SamType.SHORT -- force short on match
    end
    return range, height, type, blind
  end
  
  --- [Internal] Function to set the SAM start state
  -- @param #MANTIS self
  -- @return #MANTIS self
  function MANTIS:SetSAMStartState()
    -- DONE: if using dynamic filtering, update SAM_Table and the (active) SEAD groups, pull req #1405/#1406
    -- DONE: Auto mode
    self:T(self.lid.."Setting SAM Start States")
     -- get SAM Group
     local SAM_SET = self.SAM_Group
     local SAM_Grps = SAM_SET.Set --table of objects
     local SAM_Tbl = {} -- table of SAM defense zones
     local SAM_Tbl_lg = {} -- table of long range SAM defense zones
     local SAM_Tbl_md = {} -- table of mid range SAM defense zones
     local SAM_Tbl_sh = {} -- table of short range SAM defense zones
     local SEAD_Grps = {} -- table of SAM names to make evasive
     local engagerange = self.engagerange -- firing range in % of max
     --cycle through groups and set alarm state etc
     for _i,_group in pairs (SAM_Grps) do
      if _group:IsGround() and _group:IsAlive() then
        local group = _group -- Wrapper.Group#GROUP
        -- DONE: add emissions on/off
        if self.UseEmOnOff then
          group:OptionAlarmStateRed()
          group:EnableEmission(false)
          --group:SetAIOff()
        else
          group:OptionAlarmStateGreen() -- AI off
        end
        group:OptionEngageRange(engagerange)  --default engagement will be 95% of firing range
        local grpname = group:GetName()
        local grpcoord = group:GetCoordinate()
        local grprange,grpheight,type,blind  = self:_GetSAMRange(grpname)
        table.insert( SAM_Tbl, {grpname, grpcoord, grprange, grpheight, blind})
        --table.insert( SEAD_Grps, grpname )
        if type == MANTIS.SamType.LONG then
          table.insert( SAM_Tbl_lg, {grpname, grpcoord, grprange, grpheight, blind})
          table.insert( SEAD_Grps, grpname )
          --self:T("SAM "..grpname.." is type LONG")
        elseif type == MANTIS.SamType.MEDIUM then
         table.insert( SAM_Tbl_md, {grpname, grpcoord, grprange, grpheight, blind})
         table.insert( SEAD_Grps, grpname )
         --self:T("SAM "..grpname.." is type MEDIUM")
        elseif type == MANTIS.SamType.SHORT then
          table.insert( SAM_Tbl_sh, {grpname, grpcoord, grprange, grpheight, blind})
          --self:T("SAM "..grpname.." is type SHORT")
          self.ShoradGroupSet:Add(grpname,group)
          if not self.autoshorad then
            table.insert( SEAD_Grps, grpname )
          end
        end
        self.SamStateTracker[grpname] = "GREEN"
        end
     end
     self.SAM_Table = SAM_Tbl
     self.SAM_Table_Long = SAM_Tbl_lg
     self.SAM_Table_Medium = SAM_Tbl_md
     self.SAM_Table_Short = SAM_Tbl_sh
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
     local SAM_Tbl_lg = {} -- table of long range SAM defense zones
     local SAM_Tbl_md = {} -- table of mid range SAM defense zones
     local SAM_Tbl_sh = {} -- table of short range SAM defense zon
     local SEAD_Grps = {} -- table of SAM names to make evasive
     local engagerange = self.engagerange -- firing range in % of max
     --cycle through groups and set alarm state etc
     for _i,_group in pairs (SAM_Grps) do
        local group = _group -- Wrapper.Group#GROUP
        group:OptionEngageRange(engagerange)  --engagement will be 95% of firing range
        if group:IsGround() and group:IsAlive() then
          local grpname = group:GetName()
          local grpcoord = group:GetCoordinate()
          local grprange, grpheight,type,blind  = self:_GetSAMRange(grpname)
          table.insert( SAM_Tbl, {grpname, grpcoord, grprange, grpheight, blind}) -- make the table lighter, as I don't really use the zone here
          table.insert( SEAD_Grps, grpname )
          if type == MANTIS.SamType.LONG then
            table.insert( SAM_Tbl_lg, {grpname, grpcoord, grprange, grpheight, blind})
            --self:I({grpname,grprange, grpheight})
          elseif type == MANTIS.SamType.MEDIUM then
           table.insert( SAM_Tbl_md, {grpname, grpcoord, grprange, grpheight, blind})
           --self:I({grpname,grprange, grpheight})
          elseif type == MANTIS.SamType.SHORT then
            table.insert( SAM_Tbl_sh, {grpname, grpcoord, grprange, grpheight, blind})
            --self:I({grpname,grprange, grpheight})
            self.ShoradGroupSet:Add(grpname,group)
            if self.autoshorad then
              self.Shorad.Groupset = self.ShoradGroupSet
            end
          end
        end
     end
     self.SAM_Table = SAM_Tbl
     self.SAM_Table_Long = SAM_Tbl_lg
     self.SAM_Table_Medium = SAM_Tbl_md
     self.SAM_Table_Short = SAM_Tbl_sh
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
  -- @param #table samset Table of SAM data
  -- @param #table detset Table of COORDINATES
  -- @param #boolean dlink Using DLINK
  -- @param #number limit of SAM sites to go active on a contact
  -- @return #MANTIS self
  function MANTIS:_CheckLoop(samset,detset,dlink,limit)
    self:T(self.lid .. "CheckLoop " .. #detset .. " Coordinates")
    local switchedon = 0
    local instatusred = 0
    local instatusgreen = 0
    local activeshorads = 0
    local SEADactive = 0
    for _,_data in pairs (samset) do
      local samcoordinate = _data[2]
      local name = _data[1]
      local radius = _data[3]
      local height = _data[4]
      local blind = _data[5] * 1.25 + 1
      local samgroup = GROUP:FindByName(name)
      local IsInZone, Distance = self:_CheckObjectInZone(detset, samcoordinate, radius, height, dlink)
      local suppressed = self.SuppressedGroups[name] or false
      local activeshorad = false
      if self.Shorad and self.Shorad.ActiveGroups and self.Shorad.ActiveGroups[name] then
       activeshorad = true
      end
      if IsInZone and not suppressed and not activeshorad then --check any target in zone and not currently managed by SEAD
        if samgroup:IsAlive() then
          -- switch on SAM
          local switch = false
          if self.UseEmOnOff and switchedon < limit then
            -- DONE: add emissions on/off
            samgroup:EnableEmission(true)
            switchedon = switchedon + 1
            switch = true
          elseif (not self.UseEmOnOff) and switchedon < limit then
            samgroup:OptionAlarmStateRed()
            switchedon = switchedon + 1
            switch = true           
          end
          if self.SamStateTracker[name] ~= "RED" and switch then
            self:__RedState(1,samgroup)
            self.SamStateTracker[name] = "RED"
          end
          -- link in to SHORAD if available
          -- DONE: Test integration fully
          if self.ShoradLink and (Distance < self.ShoradActDistance or Distance < blind ) then -- don't give SHORAD position away too early
            local Shorad = self.Shorad
            local radius = self.checkradius
            local ontime = self.ShoradTime
            Shorad:WakeUpShorad(name, radius, ontime)
            self:__ShoradActivated(1,name, radius, ontime)
          end
          -- debug output
          if (self.debug or self.verbose) and switch then
            local text = string.format("SAM %s in alarm state RED!", name)
            --local m=MESSAGE:New(text,10,"MANTIS"):ToAllIf(self.debug
            if self.verbose then self:I(self.lid..text) end
          end
        end --end alive
      else
        if samgroup:IsAlive() and not suppressed and not activeshorad then
          -- switch off SAM
          if self.UseEmOnOff  then
            samgroup:EnableEmission(false)
          else
            samgroup:OptionAlarmStateGreen()
          end
          if self.SamStateTracker[name] ~= "GREEN" then
            self:__GreenState(1,samgroup)
            self.SamStateTracker[name] = "GREEN"
          end
          if self.debug or self.verbose then
            local text = string.format("SAM %s in alarm state GREEN!", name)
            --local m=MESSAGE:New(text,10,"MANTIS"):ToAllIf(self.debug)
            if self.verbose then self:I(self.lid..text) end
          end
        end --end alive
      end --end check     
    end --for loop
    if self.debug then
      for _,_status in pairs(self.SamStateTracker) do
        if _status == "GREEN" then
          instatusgreen=instatusgreen+1
        elseif _status == "RED" then
          instatusred=instatusred+1
        end
      end
      if self.Shorad then
        for _,_name in pairs(self.Shorad.ActiveGroups or {}) do
          activeshorads=activeshorads+1
        end
      end
    end
    return instatusred, instatusgreen, activeshorads
  end
  
  --- [Internal] Check detection function
  -- @param #MANTIS self
  -- @param Functional.Detection#DETECTION_AREAS detection Detection object
  -- @param #boolean dlink
  -- @return #MANTIS self
  function MANTIS:_Check(detection,dlink)
    self:T(self.lid .. "Check")
    --get detected set
    local detset = detection:GetDetectedItemCoordinates()
    --self:T("Check:", {detset})
    -- randomly update SAM Table
    local rand = math.random(1,100)
    if rand > 65 then -- 1/3 of cases
      self:_RefreshSAMTable()
    end
    local instatusred = 0
    local instatusgreen = 0
    local activeshorads = 0
    -- switch SAMs on/off if (n)one of the detected groups is inside their reach
    if self.automode then
      local samset = self.SAM_Table_Long -- table of i.1=names, i.2=coordinates, i.3=firing range, i.4=firing height
      self:_CheckLoop(samset,detset,dlink,self.maxlongrange)
      local samset = self.SAM_Table_Medium -- table of i.1=names, i.2=coordinates, i.3=firing range, i.4=firing height
      self:_CheckLoop(samset,detset,dlink,self.maxmidrange)
      local samset = self.SAM_Table_Short -- table of i.1=names, i.2=coordinates, i.3=firing range, i.4=firing height
      instatusred, instatusgreen, activeshorads = self:_CheckLoop(samset,detset,dlink,self.maxshortrange)
    else
      local samset = self:_GetSAMTable() -- table of i.1=names, i.2=coordinates, i.3=firing range, i.4=firing height
      instatusred, instatusgreen, activeshorads = self:_CheckLoop(samset,detset,dlink,self.maxclassic)
    end
    if self.debug or self.verbose then
      local statusreport = REPORT:New("\nMANTIS Status "..self.name)
      statusreport:Add("+-----------------------------+")
      statusreport:Add(string.format("+ SAM in RED State: %2d",instatusred))
      statusreport:Add(string.format("+ SAM in GREEN State: %2d",instatusgreen))
      if self.Shorad then
       statusreport:Add(string.format("+ SHORAD active: %2d",activeshorads))  
      end
      statusreport:Add("+-----------------------------+")
      MESSAGE:New(statusreport:Text(),10):ToAll():ToLog()
    end
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
              -- DONE: add emissions on/off
              --samgroup:SetAIOn()
              samgroup:EnableEmission(true)
            else
              samgroup:OptionAlarmStateRed()
            end
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
    local dlink = self.Detection -- Ops.Intel#INTEL_DLINK
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
    if not INTEL then
      self.Detection = self:StartDetection()
    else
      self.Detection = self:StartIntelDetection()
    end
    --[[
    if self.advAwacs and not self.automode then
      self.AWACS_Detection = self:StartAwacsDetection()
    end
    --]]
    if self.autoshorad then
      self.Shorad = SHORAD:New(self.name.."-SHORAD","SHORAD",self.SAM_Group,self.ShoradActDistance,self.ShoradTime,self.coalition,self.UseEmOnOff)
      self.Shorad:SetDefenseLimits(80,95)
      self.ShoradLink = true
      self.Shorad.Groupset=self.ShoradGroupSet
      self.Shorad.debug = self.debug
    end
    if self.shootandscoot and self.SkateZones and self.Shorad then
      self.Shorad:AddScootZones(self.SkateZones,self.SkateNumber or 3,self.ScootRandom,self.ScootFormation)
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
      self:_Check(self.Detection,self.DLink)
    end

    --[[ check Awacs
    if self.advAwacs and not self.state2flag then
      self:_Check(self.AWACS_Detection,false)
    end
    --]]
    
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
    if self.debug and self.verbose then
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
    self:T({From, Event, To, Group:GetName()})
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
    self:T({From, Event, To, Group:GetName()})
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
  -- @param Wrapper.Group#GROUP Attacker The attacking GROUP object
  function MANTIS:onafterSeadSuppressionStart(From, Event, To, Group, Name, Attacker)
    self:T({From, Event, To, Name})
    self.SuppressedGroups[Name] = true
    if self.ShoradLink then
      local Shorad = self.Shorad
      local radius = self.checkradius
      local ontime = self.ShoradTime
      Shorad:WakeUpShorad(Name, radius, ontime)
      self:__ShoradActivated(1,Name, radius, ontime)
    end
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
  -- @param Wrapper.Group#GROUP Attacker The attacking GROUP object
  function MANTIS:onafterSeadSuppressionPlanned(From, Event, To, Group, Name, SuppressionStartTime, SuppressionEndTime, Attacker)
    self:T({From, Event, To, Name})
    return self
  end
  
end
-----------------------------------------------------------------------
-- MANTIS end
-----------------------------------------------------------------------
