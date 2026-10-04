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
-- Last Update: January 2026

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
-- @field #boolean SmokeDecoy If true, smoke short range SAM units as decoy if a plane is in firing range.
-- @field #number SmokeDecoyColor Color to use, defaults to SMOKECOLOR.White.
-- @field #number checkcounter Counter for SAM Table refreshes.
-- @field #number DLinkCacheTime Seconds after which cached contacts in DLink will decay.
-- @field #boolean logsamstatus Log SAM status in dcs.log every cycle if true.
-- @field #boolean DetectAccoustic Set if we can also detect units accousticly.
-- @field #number DetectAccousticRadius We can hear in this range.
-- @field #table DetectAccousticCategories We can hear these categories.
-- @extends Core.Base#BASE


--- *The worst thing that can happen to a good cause is, not to be skillfully attacked, but to be ineptly defended.* - Frédéric Bastiat
--
-- Moose class for a more intelligent Air Defense System
--
-- # MANTIS
-- 
-- * Moose derived  Modular, Automatic and Network capable Targeting and Interception System.
-- * Controls a network of SAM sites. Uses detection to switch on the SAM site closest to the enemy.
-- * **Automatic mode** (default) will set-up your SAM site network automatically for you.
-- * Leverage evasiveness from SEAD, leverage attack range setting.
-- * Automatic setup of SHORAD based on groups of the class "short-range".
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
-- * Point Defense, e.g. each **group name** begins with "Red AAA" and *not" e.g. just "AAA" because you might also have "Blue AAA"
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
-- * IRIS-T SLM
-- * Pantsir S1
-- * TOR M2
-- * C-RAM
-- * Silkworm (though strictly speaking this is a surface to ship missile)
-- * SA-2, SA-3, SA-5, SA-6, SA-7, SA-8, SA-9, SA-10, SA-11, SA-13, SA-15, SA-19, S-300VM, S-300V4, S-400 (SA-21)
-- * From IDF mod: STUNNER IDFA, TAMIR IDFA (Note all caps!)
-- * From HDS (see note on HDS below): SA-2, SA-3, SA-10B, SA-10C, SA-12, SA-17, SA-20A, SA-20B, SA-23, HQ-2, SAMP/T Block 1, SAMP/T Block 1INT,  SAMP/T Block2
-- * Other Mods: Nike
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
-- * SA-10B (overlap with other SA-10 types, e.g. "Red SAM SA-10B HDS" with 5P85CE launcher)
-- * SA-10C (overlap with other SA-10 types, e.g. "Red SAM SA-10C HDS" with 5P85SE launcher)
-- * SA-12 (e.g. "Red SAM SA-12 HDS")
-- * SA-23 (e.g. "Red SAM SA-23 HDS")
-- * SAMP/T (launcher dependent range, e.g. "Blue SAM SAMPT Block 1 HDS" for Block 1, "Blue SAM SAMPT Block 1INT HDS", "Blue SAM SAMPT Block 2 HDS")
-- 
-- The other HDS types work like the rest of the known SAM systems.
-- 
-- # 0.1 Set-up in the mission editor
-- 
-- Set up your SAM sites in the mission editor. Name the groups using a systematic approach like above.Can be e.g. AWACS or a combination of AWACS and Search Radars like e.g. EWR 1L13 etc. 
-- Search Radars usually have "SR" or "STR" in their names. Use the encyclopedia in the mission editor to inform yourself.
-- Set up your SHORAD systems. They need to be **close** to (i.e. around) the SAM sites to be effective. Use **one unit ** per group (multiple groups) for the SAM location. 
-- Else, evasive manoevers might club up all defenders in one place. Red SA-15 TOR systems offer a good missile defense.
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
--  **HINT** Set at least one EWR on invisible and immortal so MANTIS doesn't stop working.
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
-- ### 2.1.1 You can add Accept-, Reject- and Conflict-Zones to your setup, e.g. to consider borders or de-militarized zones:   
-- 
--        -- Parameters are tables of Core.Zone#ZONE objects!   
--        -- This is effectively a 3-stage filter allowing for zone overlap. A coordinate is accepted first when   
--        -- it is inside any AcceptZone. Then RejectZones are checked, which enforces both borders, but also overlaps of   
--        -- Accept- and RejectZones. Last, if it is inside a conflict zone, it is accepted.   
--        mybluemantis:AddZones(AcceptZones,RejectZones,ConflictZones)   
--        
--        
-- ### 2.1.2 Change the number of long-, mid- and short-range, point defense systems going live on a detected target:   
-- 
--        -- parameters are numbers. Defaults are 1,2,2,6,6 respectively
--        mybluemantis:SetMaxActiveSAMs(Short,Mid,Long,Classic,Point)
-- 
-- ### 2.1.3 SHORAD/Point defense will automatically be added from SAM sites of type "point" or if the range is less than 5km or if the type is AAA. 
--        
-- ### 2.1.4 Advanced features   
--        
--        -- Option to set the scale of the activation range, i.e. don't activate at the fringes of max range, defaults below.   
--        -- also see engagerange below.   
--            self.radiusscale[MANTIS.SamType.LONG] = 1.1   
--            self.radiusscale[MANTIS.SamType.MEDIUM] = 1.2   
--            self.radiusscale[MANTIS.SamType.SHORT] = 1.3 
--            self.radiusscale[MANTIS.SamType.POINT] = 1.4 
--        
-- ### 2.1.5 Friendlies check in firing range
-- 
--        -- For some scenarios, like Cold War, it might be useful not to activate SAMs if friendly aircraft are around to avoid death by friendly fire.
--        mybluemantis.checkforfriendlies = true  
--        
-- ### 2.1.6 Shoot & Scoot
-- 
--        -- Option to make the (driveable) SHORAD units drive around and shuffle positions
--        -- We use a SET_ZONE for that, number of zones to consider defaults to three, Random is true for random coordinates and Formation is e.g. "Vee".
--        mybluemantis:AddScootZones(ZoneSet, Number, Random, Formation)
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
-- # 5. Integrated SEAD
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
  version               = "0.9.44",
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
  SAM_Table_PointDef    = {},
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
  SmokeDecoy            = false,
  SmokeDecoyColor       = SMOKECOLOR.White,
  checkcounter          = 1,
  DLinkCacheTime        = 120,
  logsamstatus          = false,
  DetectAccoustic       = false,
  DetectAccousticRadius = 2000,
  DetectAccousticCategories = {Unit.Category.HELICOPTER},
  ARMWeaponSeen = {},
  InboundARMs = {},
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
  POINT = "Point",
}

--- SAM Radiusscale
-- @type MANTIS.radiusscale
MANTIS.radiusscale = {}
MANTIS.radiusscale[MANTIS.SamType.LONG] = 1.1
MANTIS.radiusscale[MANTIS.SamType.MEDIUM] = 1.2
MANTIS.radiusscale[MANTIS.SamType.SHORT] = 1.75
MANTIS.radiusscale[MANTIS.SamType.POINT] = 3

--- SAM data
-- @type MANTIS.SamData
-- @field #number Range Max firing range in km
-- @field #number Blindspot no-firing range (green circle)
-- @field #number Height Max firing height in km
-- @field #string Type #MANTIS.SamType of SAM, i.e. SHORT, MEDIUM or LONG (range)
-- @field #string Radar Radar typename on unit level (used as key)
-- @field #string Point Point defense capable
-- @field ARMCapacit ARMCapacity ie how many (H)ARMs the system can defend at the same time
MANTIS.SamData = {
  ["Hawk"] = { Range=35, Blindspot=0, Height=12, Type="Medium", Radar="Hawk" }, -- measures in km
  ["NASAMS"] = { Range=14, Blindspot=0, Height=7, Type="Short", Radar="NSAMS", ARMCapacity=1 }, -- AIM 120B
  ["Patriot"] = { Range=99, Blindspot=0, Height=25, Type="Long", Radar="Patriot str" },
  ["Rapier"] = { Range=10, Blindspot=0, Height=3, Type="Short", Radar="rapier" },
  ["SA-2"] = { Range=40, Blindspot=7, Height=25, Type="Medium", Radar="S_75M_Volhov" },
  ["SA-3"] = { Range=18, Blindspot=6, Height=18, Type="Short", Radar="5p73 s-125 ln" },
  ["SA-5"] = { Range=250, Blindspot=7, Height=40, Type="Long", Radar="5N62V" },
  ["SA-6"] = { Range=25, Blindspot=0, Height=8, Type="Medium", Radar="1S91" },
  ["SA-10"] = { Range=119, Blindspot=0, Height=18, Type="Long" , Radar="S-300PS 4", ARMCapacity=4},
  ["SA-11"] = { Range=35, Blindspot=0, Height=20, Type="Medium", Radar="SA-11" },
  ["Roland"] = { Range=6, Blindspot=0, Height=5, Type="Short", Radar="Roland", ARMCapacity=1 },
  ["Gepard"] = { Range=5, Blindspot=0, Height=4, Type="Point", Radar="Gepard" },
  ["HQ-7"] = { Range=12, Blindspot=0, Height=3, Type="Short", Radar="HQ-7" },
  ["SA-9"] = { Range=4, Blindspot=0, Height=3, Type="Point", Radar="Strela", Point="true" },
  ["SA-8"] = { Range=10, Blindspot=0, Height=5, Type="Short", Radar="Osa 9A33" },
  ["SA-19"] = { Range=8, Blindspot=0, Height=3, Type="Short", Radar="Tunguska" },
  ["SA-15"] = { Range=11, Blindspot=0, Height=6, Type="Point", Radar="Tor 9A331", Point="true", ARMCapacity=2 },
  ["SA-13"] = { Range=5, Blindspot=0, Height=3, Type="Point", Radar="Strela", Point="true" },
  ["Avenger"] = { Range=4, Blindspot=0, Height=3, Type="Short", Radar="Avenger" },
  ["Chaparral"] = { Range=8, Blindspot=0, Height=3, Type="Short", Radar="Chaparral" },
  ["Linebacker"] = { Range=4, Blindspot=0, Height=3, Type="Point", Radar="Linebacker", Point="true" },
  ["Silkworm"] = { Range=90, Blindspot=1, Height=0.2, Type="Long", Radar="Silkworm" },
  ["C-RAM"] = { Range=2, Blindspot=0, Height=2, Type="Point", Radar="HEMTT_C-RAM_Phalanx", Point="true" },
  -- units from HDS Mod, multi launcher options is tricky
  ["SA-10B"] = { Range=75, Blindspot=0, Height=18, Type="Medium" , Radar="SA-10B", ARMCapacity=4},
  ["SA-17"] = { Range=50, Blindspot=3, Height=50, Type="Medium", Radar="SA-17", ARMCapacity=4 },
  ["SA-20A"] = { Range=150, Blindspot=5, Height=27, Type="Long" , Radar="S-300PMU1", ARMCapacity=16},
  ["SA-20B"] = { Range=200, Blindspot=4, Height=27, Type="Long" , Radar="S-300PMU2", ARMCapacity=18},
  ["S-300VM"] = { Range=200, Blindspot=5, Height=30, Type="Long" , Radar="9S32ME", ARMCapacity=4},  -- SA-23 Gladiator/Giant
  ["S-300V4"] = { Range=380, Blindspot=5, Height=30, Type="Long" , Radar="9S32M-1E", ARMCapacity=4},  -- SA-23B
  ["S-400"] = { Range=380, Blindspot=5, Height=30, Type="Long" , Radar="92N6E", ARMCapacity=4},  -- SA-21 Growler
  ["HQ-2"] = { Range=50, Blindspot=6, Height=35, Type="Medium", Radar="HQ_2_Guideline_LN" },
  ["TAMIR IDFA"] = { Range=20, Blindspot=0.6, Height=12.3, Type="Short", Radar="IRON_DOME_LN" },
  ["STUNNER IDFA"] = { Range=250, Blindspot=1, Height=45, Type="Long", Radar="DAVID_SLING_LN" },
  ["Nike"] = { Range=155, Blindspot=6, Height=30, Type="Long", Radar="HIPAR" },
  ["Dog Ear"] = { Range=11, Blindspot=0, Height=9, Type="Point", Radar="Dog Ear", Point="true" },
  -- CH Added to DCS core 2.9.19.x
  ["Pantsir S1"] = { Range=20, Blindspot=1.2, Height=15, Type="Point", Radar="PantsirS1" , Point="true", ARMCapacity=3 }, 
  ["Tor M2"] = { Range=12, Blindspot=1, Height=10, Type="Point", Radar="TorM2", Point="true", ARMCapacity=4  },
  ["IRIS-T SLM"] = { Range=40, Blindspot=0.5, Height=20, Type="Medium", Radar="CH_IRIST_SLM", ARMCapacity=12  }, -- 4 per starter, usually 3 starters in a battery
  ["SON-9"] = { Range=20, Blindspot=0, Height=14, Type="Point", Radar="SON_9", Point="true" }, -- Fire Can FCR for S-60/KS-19 AAA
}

--- SAM data HDS
-- @type MANTIS.SamDataHDS
-- @field #number Range Max firing range in km
-- @field #number Blindspot no-firing range (green circle)
-- @field #number Height Max firing height in km
-- @field #string Type #MANTIS.SamType of SAM, i.e. SHORT, MEDIUM or LONG (range)
-- @field #string Radar Radar typename on unit level (used as key)
-- @field #string Point Point defense capable
MANTIS.SamDataHDS = {
  -- units from HDS Mod, multi launcher options is tricky
  -- group name MUST contain HDS to ID launcher type correctly!
  ["SA-2 HDS"] = { Range=56, Blindspot=7, Height=30, Type="Medium", Radar="V759" }, 
  ["SA-3 HDS"] = { Range=20, Blindspot=6, Height=30, Type="Short", Radar="V-601P" },  
  ["SA-10B HDS"] = { Range=90, Blindspot=5, Height=25, Type="Long" , Radar="5P85CE ln", ARMCapacity=8}, -- V55RUD
  ["SA-10C HDS"] = { Range=75, Blindspot=5, Height=25, Type="Long" , Radar="5P85SE ln", ARMCapacity=3}, -- V55RUD
  ["SA-17 HDS"] = { Range=50, Blindspot=3, Height=50, Type="Medium", Radar="SA-17", ARMCapacity=4 },
  ["SA-12 HDS"] = { Range=100, Blindspot=6, Height=30, Type="Long" , Radar="S-300V 9A82 l", ARMCapacity=12},
  ["SA-23 HDS"] = { Range=200, Blindspot=1, Height=50, Type="Long", Radar="S-300VM 9A82ME", ARMCapacity=14 },
  ["HQ-2 HDS"] = { Range=50, Blindspot=6, Height=35, Type="Medium", Radar="HQ_2_Guideline_LN" },
  ["SAMPT Block 1 HDS"] = { Range=120, Blindspot=1, Height=20, Type="long", Radar="SAMPT_MLT_Blk1" }, -- Block 1 Launcher
  ["SAMPT Block 1INT HDS"] = { Range=150, Blindspot=1, Height=25, Type="long", Radar="SAMPT_MLT_Blk1NT" }, -- Block 1-INT Launcher
  ["SAMPT Block 2 HDS"] = { Range=200, Blindspot=10, Height=70, Type="long", Radar="SAMPT_MLT_Blk2" }, -- Block 2 Launcher
}

--- SAM data SMA
-- @type MANTIS.SamDataSMA
-- @field #number Range Max firing range in km
-- @field #number Blindspot no-firing range (green circle)
-- @field #number Height Max firing height in km
-- @field #string Type #MANTIS.SamType of SAM, i.e. SHORT, MEDIUM or LONG (range)
-- @field #string Radar Radar typename on unit level (used as key)
-- @field #string Point Point defense capable
MANTIS.SamDataSMA = {
  -- units from SMA Mod (Sweedish Military Assets)
  -- https://forum.dcs.world/topic/295202-swedish-military-assets-for-dcs-by-currenthill/
  -- group name MUST contain SMA to ID launcher type correctly!
   ["RBS98M SMA"] = { Range=20, Blindspot=0.2, Height=8, Type="Short", Radar="RBS-98" },
   ["RBS70 SMA"] = { Range=8, Blindspot=0.25, Height=6, Type="Short", Radar="RBS-70" },  
   ["RBS70M SMA"] = { Range=8, Blindspot=0.25, Height=6, Type="Short", Radar="BV410_RBS70" }, 
   ["RBS90 SMA"] = { Range=8, Blindspot=0.25, Height=6, Type="Short", Radar="RBS-90" }, 
   ["RBS90M SMA"] = { Range=8, Blindspot=0.25, Height=6, Type="Short", Radar="BV410_RBS90" },  
   ["RBS103A SMA"] = { Range=160, Blindspot=1, Height=36, Type="Long", Radar="LvS-103_Lavett103_Rb103A" },
   ["RBS103B SMA"] = { Range=120, Blindspot=3, Height=24.5, Type="Long", Radar="LvS-103_Lavett103_Rb103B" }, 
   ["RBS103AM SMA"] = { Range=160, Blindspot=1, Height=36, Type="Long", Radar="LvS-103_Lavett103_HX_Rb103A" },
   ["RBS103BM SMA"] = { Range=120, Blindspot=3, Height=24.5, Type="Long", Radar="LvS-103_Lavett103_HX_Rb103B" },
   ["Lvkv9040M SMA"] = { Range=2, Blindspot=0.1, Height=1.2, Type="Point", Radar="LvKv9040",Point="true" },   
}

--- SAM data CH
-- @type MANTIS.SamDataCH
-- @field #number Range Max firing range in km
-- @field #number Blindspot no-firing range (green circle)
-- @field #number Height Max firing height in km
-- @field #string Type #MANTIS.SamType of SAM, i.e. SHORT, MEDIUM or LONG (range)
-- @field #string Radar Radar typename on unit level (used as key)
-- @field #string Point Point defense capable
MANTIS.SamDataCH = {
    -- units from CH (Military Assets by Currenthill)
    -- https://www.currenthill.com/
    -- group name MUST contain CHM to ID launcher type correctly!
   ["2S38 CHM"] = { Range=6, Blindspot=0.1, Height=4.5, Type="Short", Radar="2S38" },
   ["PantsirS1 CHM"] = { Range=20, Blindspot=1.2, Height=15, Type="Point", Radar="PantsirS1", Point="true", ARMCapacity=3 }, 
   ["PantsirS2 CHM"] = { Range=30, Blindspot=1.2, Height=18, Type="Medium", Radar="PantsirS2", ARMCapacity=4 }, 
   ["PGL-625 CHM"] = { Range=10, Blindspot=1, Height=5, Type="Short", Radar="PGL_625" }, 
   ["HQ-17A CHM"] = { Range=15, Blindspot=1.5, Height=10, Type="Short", Radar="HQ17A" }, 
   ["M903PAC2 CHM"] = { Range=120, Blindspot=3, Height=24.5, Type="Long", Radar="MIM104_M903_PAC2" },
   ["M903PAC3 CHM"] = { Range=160, Blindspot=1, Height=40, Type="Long", Radar="MIM104_M903_PAC3" }, 
   ["TorM2 CHM"] = { Range=12, Blindspot=1, Height=10, Type="Point", Radar="TorM2", Point="true", ARMCapacity=3  },
   ["TorM2K CHM"] = { Range=12, Blindspot=1, Height=10, Type="Point", Radar="TorM2K", Point="true", ARMCapacity=4  },
   ["TorM2M CHM"] = { Range=16, Blindspot=1, Height=10, Type="Point", Radar="TorM2M", Point="true", ARMCapacity=4  }, 
   ["NASAMS3-AMRAAMER CHM"] = { Range=50, Blindspot=2, Height=35.7, Type="Medium", Radar="CH_NASAMS3_LN_AMRAAM_ER" }, 
   ["NASAMS3-AIM9X2 CHM"] = { Range=20, Blindspot=0.2, Height=18, Type="Short", Radar="CH_NASAMS3_LN_AIM9X2" },
   ["C-RAM CHM"] = { Range=2, Blindspot=0, Height=2, Type="Point", Radar="CH_Centurion_C_RAM", Point="true" }, 
   ["PGZ-09 CHM"] = { Range=4, Blindspot=0.5, Height=3, Type="Point", Radar="CH_PGZ09", Point="true" },
   ["S350-9M100 CHM"] = { Range=15, Blindspot=1, Height=8, Type="Short", Radar="CH_S350_50P6_9M100", ARMCapacity=20 },
   ["S350-9M96D CHM"] = { Range=150, Blindspot=2.5, Height=30, Type="Long", Radar="CH_S350_50P6_9M96D", ARMCapacity=20 },
   ["LAV-AD CHM"] = { Range=8, Blindspot=0.16, Height=4.8, Type="Short", Radar="CH_LAVAD" }, 
   ["HQ-22 CHM"] = { Range=170, Blindspot=5, Height=27, Type="Long", Radar="CH_HQ22_LN" }, 
   ["PGZ-95 CHM"] = { Range=2.5, Blindspot=0.5, Height=2, Type="Point", Radar="CH_PGZ95",Point="true" },
   ["LD-3000 CHM"] = { Range=2.5, Blindspot=0.1, Height=3, Type="Point", Radar="CH_LD3000_stationary", Point="true" }, 
   ["LD-3000M CHM"] = { Range=2.5, Blindspot=0.1, Height=3, Type="Point", Radar="CH_LD3000", Point="true" },  
   ["FlaRakRad CHM"] = { Range=8, Blindspot=1.5, Height=6, Type="Short", Radar="CH_FlaRakRad" },  
   ["IRIS-T SLM CHM"] = { Range=40, Blindspot=0.5, Height=20, Type="Medium", Radar="CH_IRIST_SLM" }, 
   ["M903PAC2KAT1 CHM"] = { Range=120, Blindspot=3, Height=24.5, Type="Long", Radar="CH_MIM104_M903_PAC2_KAT1" }, 
   ["Skynex CHM"] = { Range=3.5, Blindspot=0.1, Height=3.5, Type="Point", Radar="CH_SkynexHX", Point="true" },
   ["Skyshield CHM"] = { Range=3.5, Blindspot=0.1, Height=3.5, Type="Point", Radar="CH_Skyshield_Gun", Point="true" },
   ["WieselOzelot CHM"] = { Range=8, Blindspot=0.16, Height=4.8, Type="Short", Radar="CH_Wiesel2Ozelot" }, 
   ["BukM3-9M317M CHM"] = { Range=70, Blindspot=0.25, Height=35, Type="Medium", Radar="CH_BukM3_9A317M", ARMCapacity=20 },  
   ["BukM3-9M317MA CHM"] = { Range=70, Blindspot=0.25, Height=35, Type="Medium", Radar="CH_BukM3_9A317MA",  ARMCapacity=20 },  
   ["SkySabre CHM"] = { Range=30, Blindspot=0.5, Height=10, Type="Medium", Radar="CH_SkySabreLN" },  
   ["Stormer CHM"] = { Range=7.5, Blindspot=0.3, Height=7, Type="Short", Radar="CH_StormerHVM" },  
   ["THAAD CHM"] = { Range=200, Blindspot=40, Height=150, Type="Long", Radar="CH_THAAD_M1120" },  
   ["USInfantryFIM92K CHM"] = { Range=8, Blindspot=0.16, Height=4.8, Type="Short", Radar="CH_USInfantry_FIM92" },
   ["RBS98M CHM"] = { Range=20, Blindspot=0.2, Height=8, Type="Short", Radar="RBS-98" },
   ["RBS70 CHM"] = { Range=8, Blindspot=0.25, Height=6, Type="Short", Radar="RBS-70" },  
   ["RBS70M CHM"] = { Range=8, Blindspot=0.25, Height=6, Type="Short", Radar="BV410_RBS70" }, 
   ["RBS90 CHM"] = { Range=8, Blindspot=0.25, Height=6, Type="Short", Radar="RBS-90" }, 
   ["RBS90M CHM"] = { Range=8, Blindspot=0.25, Height=6, Type="Short", Radar="BV410_RBS90" },  
   ["RBS103A CHM"] = { Range=160, Blindspot=1, Height=36, Type="Long", Radar="LvS-103_Lavett103_Rb103A" },
   ["RBS103B CHM"] = { Range=120, Blindspot=3, Height=24.5, Type="Long", Radar="LvS-103_Lavett103_Rb103B" }, 
   ["RBS103AM CHM"] = { Range=160, Blindspot=1, Height=36, Type="Long", Radar="LvS-103_Lavett103_HX_Rb103A" },
   ["RBS103BM CHM"] = { Range=120, Blindspot=3, Height=24.5, Type="Long", Radar="LvS-103_Lavett103_HX_Rb103B" },
   ["Lvkv9040M CHM"] = { Range=2, Blindspot=0.1, Height=1.2, Type="Point", Radar="LvKv9040",Point="true" },   
}


--- @type MANTIS.SamDataNaval
MANTIS.SamDataNaval = {
  ---------------------------------------------------------------------
  -- CurrentHill (CH) surface combatants
  ---------------------------------------------------------------------
  -- USA -- AEGIS / SM-family, S-band (SPY-1) or S-band AESA (SPY-6)
  ["Ticonderoga"]        = { Range=150, Blindspot=4, Height=33, Type="Long",   Radar="CH_Ticonderoga" },
  ["Ticonderoga CMP"]    = { Range=150, Blindspot=4, Height=33, Type="Long",   Radar="CH_Ticonderoga_CMP" },
  ["Arleigh Burke IIA"]  = { Range=150, Blindspot=4, Height=33, Type="Long",   Radar="CH_Arleigh_Burke_IIA" },
  ["Arleigh Burke III"]  = { Range=180, Blindspot=3, Height=33, Type="Long",   Radar="CH_Arleigh_Burke_III" },
  ["Constellation"]      = { Range=120, Blindspot=3, Height=27, Type="Long",   Radar="CH_Constellation" },

  -- UK
  ["Type 45"]            = { Range=120, Blindspot=3, Height=30, Type="Long",   Radar="Type45" },            -- Aster 15/30, SAMPSON
  ["Type 26"]            = { Range=25,  Blindspot=1, Height=10, Type="Medium", Radar="CH_Type26" },          -- Sea Ceptor / CAMM

  -- Germany
  ["F124 Sachsen"]       = { Range=120, Blindspot=3, Height=24, Type="Long",   Radar="CH_F124" },            -- SM-2/ESSM, APAR (X-band)

  -- China
  ["Type 052D"]          = { Range=100, Blindspot=5, Height=27, Type="Long",   Radar="Type052D" },           -- HHQ-9
  ["Type 055"]           = { Range=150, Blindspot=5, Height=30, Type="Long",   Radar="Type055" },            -- HHQ-9B
  ["Type 054B"]          = { Range=70,  Blindspot=2, Height=20, Type="Medium", Radar="CH_Type054B" },         -- HHQ-16
  ["Type 056A"]          = { Range=9,   Blindspot=0.3, Height=6, Type="Point", Radar="CH_Type056A", Point="true" }, -- HHQ-10 (IR)

  -- Russia
  ["Admiral Gorshkov"]   = { Range=150, Blindspot=3, Height=30, Type="Long",   Radar="CH_Admiral_Gorshkov" }, -- Poliment-Redut 9M96D
  ["Grigorovich AShM"]   = { Range=50,  Blindspot=2, Height=15, Type="Medium", Radar="CH_Grigorovich_AShM" }, -- Shtil-1
  ["Grigorovich LACM"]   = { Range=50,  Blindspot=2, Height=15, Type="Medium", Radar="CH_Grigorovich_LACM" },
  ["Steregushchiy"]      = { Range=50,  Blindspot=1.5, Height=20, Type="Medium", Radar="CH_Steregushchiy" },  -- Redut 9M96
  ["Gremyashchiy AShM"]  = { Range=50,  Blindspot=1.5, Height=20, Type="Medium", Radar="CH_Gremyashchiy_AShM" },
  ["Gremyashchiy LACM"]  = { Range=50,  Blindspot=1.5, Height=20, Type="Medium", Radar="CH_Gremyashchiy_LACM" },
  ["Karakurt AShM"]      = { Range=20,  Blindspot=1, Height=15, Type="Point",  Radar="CH_Karakurt_AShM", Point="true" }, -- Pantsir-M
  ["Karakurt LACM"]      = { Range=20,  Blindspot=1, Height=15, Type="Point",  Radar="CH_Karakurt_LACM", Point="true" },

  -- Point-defense / MANPADS-only hulls (treated as close-in; also usable as EWR pickets)
  ["Type 022 FAC"]       = { Range=5,   Blindspot=0.2, Height=4, Type="Point", Radar="CH_Type022", Point="true" },
  ["IRGCN FAC AShM"]     = { Range=5,   Blindspot=0.2, Height=4, Type="Point", Radar="CH_IranFAC_MG", Point="true" },       -- MANPADS
  ["IRGCN FAC Igla"]     = { Range=5,   Blindspot=0.2, Height=4, Type="Point", Radar="CH_IranFAC_MG_AShM", Point="true" },  -- Igla
  ["Strb 90 FAC"]        = { Range=4,   Blindspot=0.2, Height=3, Type="Point", Radar="Strb90", Point="true" },
  ["Visby"]              = { Range=4,   Blindspot=0.2, Height=3, Type="Point", Radar="HSwMS_Visby", Point="true" },         -- gun/CIWS

  ---------------------------------------------------------------------
  -- Base-game DCS surface combatants  (type ids from pydcs / DCS export)
  -- Only air-defence-capable hulls are listed. Pure-gun / no-AD hulls
  -- (Leander gun refits, La Combattante, cargo, subs, WWII) are omitted
  -- on purpose; add them as POINT if you want them to appear at all.
  ---------------------------------------------------------------------
  -- USA
  ["CG Ticonderoga"]        = { Range=120, Blindspot=3, Height=30, Type="Long",   Radar="TICONDEROG" },  -- SM-2/SPY-1  NOTE: id has NO trailing 'E'
  ["DDG Arleigh Burke IIa"] = { Range=120, Blindspot=3, Height=30, Type="Long",   Radar="USS_Arleigh_Burke_IIa" }, -- SM-2/SPY-1D
  ["FFG Perry"]             = { Range=38,  Blindspot=2, Height=15, Type="Medium", Radar="PERRY" },        -- SM-1MR (est. real range)
  ["CVN Roosevelt"]         = { Range=15,  Blindspot=1, Height=8,  Type="Point",  Radar="CVN_71", Point="true" }, -- NSSM/RAM
  ["CVN Lincoln"]           = { Range=15,  Blindspot=1, Height=8,  Type="Point",  Radar="CVN_72", Point="true" },
  ["CVN Washington"]        = { Range=15,  Blindspot=1, Height=8,  Type="Point",  Radar="CVN_73", Point="true" },
  ["CVN Stennis"]           = { Range=15,  Blindspot=1, Height=8,  Type="Point",  Radar="Stennis", Point="true" },
  ["CVN Truman"]            = { Range=15,  Blindspot=1, Height=8,  Type="Point",  Radar="CVN_75", Point="true" },
  ["CVN Vinson"]            = { Range=15,  Blindspot=1, Height=8,  Type="Point",  Radar="VINSON", Point="true" },
  ["LHA Tarawa"]            = { Range=15,  Blindspot=1, Height=8,  Type="Point",  Radar="LHA_Tarawa", Point="true" }, -- RAM/Sea Sparrow
  -- Russia
  ["Cruiser Moskva"]        = { Range=75,  Blindspot=5, Height=25, Type="Long",   Radar="MOSCOW" },       -- S-300F (SA-N-6)
  ["BC Pyotr Velikiy"]      = { Range=150, Blindspot=5, Height=27, Type="Long",   Radar="PIOTR" },        -- S-300F/FM
  ["Frigate Neustrashimy"]  = { Range=12,  Blindspot=1, Height=6,  Type="Short",  Radar="NEUSTRASH" },    -- Kinzhal (SA-N-9)
  ["Frigate Rezky"]         = { Range=15,  Blindspot=1, Height=5,  Type="Short",  Radar="REZKY" },        -- OSA-M (SA-N-4)
  ["Corvette Grisha"]       = { Range=15,  Blindspot=1, Height=5,  Type="Short",  Radar="ALBATROS" },     -- OSA-M (SA-N-4)
  ["Corvette Molniya"]      = { Range=5,   Blindspot=0.3, Height=3, Type="Point", Radar="MOLNIYA", Point="true" }, -- Strela
  ["CV Kuznetsov"]          = { Range=12,  Blindspot=1, Height=6,  Type="Short",  Radar="KUZNECOW" },     -- Kinzhal/Kashtan
  ["CV Kuznetsov 2017"]     = { Range=12,  Blindspot=1, Height=6,  Type="Short",  Radar="CV_1143_5" },
  ["Patrol Bykov TorM2KM"]  = { Range=15,  Blindspot=1, Height=6,  Type="Short",  Radar="CHAP_Project22160_TorM2KM" }, -- Tor
  ["Patrol Bykov"]          = { Range=7,   Blindspot=0.3, Height=4, Type="Point", Radar="CHAP_Project22160", Point="true" },
  -- China
  ["Type 052C"]             = { Range=100, Blindspot=5, Height=27, Type="Long",   Radar="Type_052C" },    -- HHQ-9
  ["Type 052B"]             = { Range=30,  Blindspot=2, Height=15, Type="Medium", Radar="Type_052B" },    -- HHQ-16/Shtil
  ["Type 054A"]             = { Range=45,  Blindspot=2, Height=18, Type="Medium", Radar="Type_054A" },    -- HHQ-16
  ["Type 071 LPD"]          = { Range=9,   Blindspot=0.5, Height=6, Type="Point", Radar="Type_071", Point="true" }, -- HHQ-10
  -- UK
  ["HMS Invincible"]        = { Range=40,  Blindspot=2, Height=18, Type="Medium", Radar="hms_invincible" }, -- Sea Dart

  ---------------------------------------------------------------------
  -- desdemicabina-simulation 3.2 (Spanish/Australian navies)
  -- AEGIS hulls: two ship_MK41_SM2 launchers (SM-2, 64 cells) + AEGIS-class
  -- trackers (150km/30km alt, ECM_K 0.5). NOTE: this pack's airWeaponDist=45km
  -- UNDERSTATES the fit -- Range below follows the SM-2 launcher (~100km), the
  -- inverse of the Admiral pack's inflated values.
  ---------------------------------------------------------------------
  ["HMAS Hobart DDG-39"]       = { Range=100, Blindspot=3, Height=30, Type="Long",  Radar="DDG39" }, -- AEGIS SPY-1D(V), SM-2
  ["F100 Alvaro de Bazan"]     = { Range=100, Blindspot=3, Height=30, Type="Long",  Radar="F100" },  -- AEGIS SPY-1D, SM-2
  ["F105 Cristobal Colon"]     = { Range=100, Blindspot=3, Height=30, Type="Long",  Radar="F105" },  -- AEGIS SPY-1D, SM-2
  ["LHD Canberra L02"]         = { Range=3,   Blindspot=0.1, Height=2, Type="Point", Radar="L02", Point="true" }, -- 3x Phalanx only
  ["LPD Castilla L52"]         = { Range=3,   Blindspot=0.1, Height=2, Type="Point", Radar="L52", Point="true" }, -- 2x Phalanx (NO_SAM attr)
  ["LHD Juan Carlos I L61"]    = { Range=1.5, Blindspot=0.1, Height=0.8, Type="Point", Radar="L61", Point="true" }, -- .50cal mounts only

  ---------------------------------------------------------------------
  -- Admiral mod surface combatants
  -- Worked example (USS America LHA-6). Read each field from the ship's
  -- GT def file:
  --   Radar     <- GT.Name  (the typeName; the essential, non-guessable key)
  --   Range     <- GT.airWeaponDist / 1000            (20000 -> 20)
  --   Height    <- launcher max_trg_alt / 1000        (15000 -> 15)
  --   Blindspot <- launcher distanceMin / 1000        (400   -> 0.4)
  --   Type      <- from armament fit (Sea Sparrow => SHORT)
  ---------------------------------------------------------------------
  ["USS America LHA-6"] = { Range=20, Blindspot=0.4, Height=15, Type="Short", Radar="USS America LHA-6" }, -- Sea Sparrow + RAM + Phalanx

  -- IMPORTANT: these Range values come from the actual weapon launcher's distanceMax
  -- / the real system, NOT GT.airWeaponDist (which is unreliable here -- e.g. Blue
  -- Ridge and Henry Kaiser both claim 100-150km with only CIWS/MGs).
  -- LONG -- area SAM
  ["HMS Duncan (Type 45)"]     = { Range=100, Blindspot=3, Height=30, Type="Long",   Radar="HMS Duncan" },             -- Aster/Sea Viper (mod: MK41_SM2)
  ["Aquitaine D650 (FREMM)"]   = { Range=120, Blindspot=3, Height=27, Type="Long",   Radar="Aquitaine D650" },          -- SYLVER Aster 30 (distanceMax 120km)
  ["Normandie D651 (FREMM)"]   = { Range=120, Blindspot=3, Height=27, Type="Long",   Radar="D651_Normandie" },          -- SYLVER Aster 30
  -- MEDIUM
  ["MEKO-200HN Hydra"]         = { Range=50,  Blindspot=2, Height=20, Type="Medium", Radar="MEKO_HN" },                 -- MK41 (mod SM-2 / real ESSM)
  ["MEKO-200TN Barbaros"]      = { Range=50,  Blindspot=2, Height=20, Type="Medium", Radar="MEKO_TN" },                 -- MK41 + SeaZenith CIWS
  ["Sovremenny Adm. Ushakov"]  = { Range=46,  Blindspot=2, Height=15, Type="Medium", Radar="Admiral Ushakov" },         -- SA-N-7 Gadfly
  -- SHORT
  ["Udaloy II Chabanenko"]     = { Range=12,  Blindspot=1, Height=6,  Type="Short",  Radar="Udaloy II DDG Admiral Chabanenko" }, -- SA-N-9 Klinok
  ["USS San Antonio LPD-17"]   = { Range=15,  Blindspot=1, Height=8,  Type="Short",  Radar="USS San Antonio LPD-17" },  -- Sea Sparrow
  -- POINT -- CIWS / RAM / gun / IR only (no area SAM); unjammable in the jammer table
  ["USS Oak Hill LSD-51"]      = { Range=9,   Blindspot=0.5, Height=6, Type="Point", Radar="USS_Oak_Hill LSD-51", Point="true" }, -- RAM + Phalanx
  ["USS Blue Ridge LCC-19"]    = { Range=3,   Blindspot=0.1, Height=2, Type="Point", Radar="USS_Blue_Ridge", Point="true" },      -- Phalanx only
  ["Sacramento AOE-1"]         = { Range=9,   Blindspot=0.5, Height=6, Type="Point", Radar="USS_Support_Ship_Sacramento_AOE-1", Point="true" }, -- RAM + Phalanx
  ["Henry Kaiser T-AO-187"]    = { Range=1.5, Blindspot=0.1, Height=0.8,Type="Point", Radar="USNS_Henry_Kaiser", Point="true" },  -- .50cal only (negligible)
  ["HMS Albion L14"]           = { Range=3,   Blindspot=0.1, Height=2, Type="Point", Radar="HMS_Albion L14", Point="true" },      -- Phalanx only
  ["LPD Foudre"]               = { Range=6,   Blindspot=0.3, Height=4, Type="Point", Radar="LPD_Foundre", Point="true" },         -- Mistral (IR)
  ["Osa-I Missile Boat"]       = { Range=4,   Blindspot=0.2, Height=3, Type="Point", Radar="OSA_One", Point="true" },             -- AK-230 (NO_SAM)
  ["Osa-II Missile Boat"]      = { Range=4,   Blindspot=0.2, Height=3, Type="Point", Radar="OSA_Two", Point="true" },             -- AK-230
  ["IRIS Alvand"]              = { Range=4,   Blindspot=0.2, Height=3, Type="Point", Radar="IRIS_Alvand", Point="true" },         -- OtoBreda 40mm / 20mm
}

-----------------------------------------------------------------------
-- MANTIS Jammer Extension v2.0.0
-- Standoff Jamming (SOJ) aircraft support for MANTIS IADS networks
-- Physics-based jamming: asymmetric Gaussian rise + exponential decay
-- Compatible with v7 jammer curves
-----------------------------------------------------------------------

--- Jammer Loadout Configurations (v8: Max 3 Pods)
-- @type MANTIS.JammerLoadouts
MANTIS.JammerLoadouts = {
  ["1xALQ99"]={name="1x AN/ALQ-99",description="Baseline single pod. Full 64MHz-20GHz spectrum.",mult_LOW=1.12,mult_S=1.10,mult_IJ=1.12,mult_OPT=1.00,bt_mod=1.00,range_mod=1.00,tier="ALQ99"},
  ["2xALQ99"]={name="2x AN/ALQ-99",description="Two pods. Improved ERP with log stacking.",mult_LOW=1.40,mult_S=1.36,mult_IJ=1.40,mult_OPT=1.02,bt_mod=1.00,range_mod=1.03,tier="ALQ99"},
  ["3xALQ99"]={name="3x AN/ALQ-99 (Maximum Legacy)",description="Max legacy barrage. Highest broadband ERP.",mult_LOW=1.58,mult_S=1.52,mult_IJ=1.58,mult_OPT=1.04,bt_mod=1.00,range_mod=1.06,tier="ALQ99"},
  ["1xALQ249"]={name="1x AN/ALQ-249 (AESA)",description="AESA 2-18GHz. High peak+wider window. Blind <2GHz.",mult_LOW=0.15,mult_S=1.82,mult_IJ=1.70,mult_OPT=1.00,bt_mod=1.28,range_mod=1.16,tier="ALQ249"},
  ["2xALQ249"]={name="2x AN/ALQ-249",description="Two AESA pods. Strong S/IJ dominance.",mult_LOW=0.15,mult_S=2.30,mult_IJ=2.15,mult_OPT=1.00,bt_mod=1.38,range_mod=1.26,tier="ALQ249"},
  ["3xALQ249"]={name="3x AN/ALQ-249 (Maximum AESA)",description="Max AESA ERP. Extreme S/IJ. No LOW coverage.",mult_LOW=0.15,mult_S=2.75,mult_IJ=2.58,mult_OPT=1.00,bt_mod=1.48,range_mod=1.35,tier="ALQ249"},
  ["1xALQ99_1xALQ249"]={name="1x ALQ-99 + 1x ALQ-249",description="Balanced coverage. AESA S/IJ + ALQ-99 LOW-band.",mult_LOW=1.14,mult_S=1.90,mult_IJ=1.80,mult_OPT=1.01,bt_mod=1.22,range_mod=1.12,tier="Mixed"},
  ["1xALQ99_2xALQ249"]={name="1x ALQ-99 + 2x ALQ-249 [Recommended]",description="Best all-around. High AESA ERP + LOW coverage.",mult_LOW=1.10,mult_S=2.38,mult_IJ=2.22,mult_OPT=1.01,bt_mod=1.35,range_mod=1.24,tier="Mixed"},
  ["2xALQ99_1xALQ249"]={name="2x ALQ-99 + 1x ALQ-249",description="Strong LOW-band + AESA S/IJ boost.",mult_LOW=1.42,mult_S=2.10,mult_IJ=2.04,mult_OPT=1.03,bt_mod=1.25,range_mod=1.15,tier="Mixed"},
}

--- Tiered loadout keys for F10 menu (v8: 3/3/3)
-- @type MANTIS.JammerLoadoutTiers
MANTIS.JammerLoadoutTiers = {
  ALQ99  = {"1xALQ99","2xALQ99","3xALQ99"},
  ALQ249 = {"1xALQ249","2xALQ249","3xALQ249"},
  Mixed  = {"1xALQ99_1xALQ249","1xALQ99_2xALQ249","2xALQ99_1xALQ249"},
}

--- Jitter configuration: ±10% per evaluation (EW Fundamentals Ch.9)
-- @type MANTIS.JammerJitterPercent
MANTIS.JammerJitterPercent = 0.10

--- Jammer SAM Parameters — v9 curves (v8.1) {peak%, mu_nm, sigma_L, tail_dist, band, floor%}
-- v9 changes from v8:
--   * Width rework: curves now track radar detection/track envelope (not just missile range)
--   * Long-range systems widened (SA-5, SA-21, SA-23, Nike, PAC-2, S-300/400 family)
--   * Short-range systems tightened (SA-19, SON-9, HQ-7, Rapier)
--   * HAWK widened to match CW illuminator envelope (~90nm)
-- floor: residual effectiveness inside burnthrough (now tapers past mu with R^2 falloff)
--   5 = legacy radar, no ECCM | 3 = moderate ECCM | 2 = advanced ECCM/AESA | 0 = optical/IR
-- @type MANTIS.JammerSAMParams
MANTIS.JammerSAMParams = {
  -- Standard SamData (canonical entries — aliases below point to these)
  ["Nike"]       ={peak=78,mu=55,sigma_L=22,tail_dist=110,band="S",  floor=5},
  ["Hawk"]       ={peak=30,mu=22,sigma_L=9, tail_dist=55, band="IJ", floor=3},
  ["SA-2"]       ={peak=75,mu=40,sigma_L=16,tail_dist=90, band="S",  floor=5},
  ["SA-3"]       ={peak=45,mu=22,sigma_L=10,tail_dist=52, band="IJ", floor=5},
  ["SA-5"]       ={peak=52,mu=75,sigma_L=26,tail_dist=145,band="S",  floor=5},
  ["SA-6"]       ={peak=33,mu=18,sigma_L=8, tail_dist=48, band="IJ", floor=3},
  ["SA-8"]       ={peak=38,mu=10,sigma_L=4, tail_dist=24, band="IJ", floor=3},
  ["SA-9"]       ={peak=3, mu=3, sigma_L=1, tail_dist=5,  band="OPT",floor=0},
  ["SA-10"]      ={peak=32,mu=50,sigma_L=20,tail_dist=95, band="S",  floor=3},
  ["SA-10B"]     ={peak=30,mu=52,sigma_L=20,tail_dist=100,band="S",  floor=3},
  ["SA-11"]      ={peak=52,mu=28,sigma_L=12,tail_dist=58, band="IJ", floor=3},
  ["SA-13"]      ={peak=3, mu=3, sigma_L=1, tail_dist=5,  band="OPT",floor=0},
  ["SA-15"]      ={peak=30,mu=11,sigma_L=5, tail_dist=22, band="IJ", floor=3},
  ["SA-17"]      ={peak=24,mu=32,sigma_L=14,tail_dist=68, band="IJ", floor=2},
  ["SA-19"]      ={peak=25,mu=8, sigma_L=3.5,tail_dist=16,band="IJ", floor=2},
  ["SA-20A"]     ={peak=22,mu=65,sigma_L=24,tail_dist=115,band="S",  floor=2},
  ["SA-20B"]     ={peak=20,mu=68,sigma_L=24,tail_dist=120,band="S",  floor=2},
  ["S-300VM"]    ={peak=16,mu=80,sigma_L=30,tail_dist=135,band="S",  floor=2}, -- SA-23 canonical
  ["S-300V4"]    ={peak=14,mu=85,sigma_L=30,tail_dist=145,band="S",  floor=2}, -- SA-23B canonical
  ["S-400"]      ={peak=18,mu=80,sigma_L=30,tail_dist=150,band="S",  floor=2}, -- SA-21 canonical
  ["NASAMS"]     ={peak=25,mu=28,sigma_L=12,tail_dist=52, band="IJ", floor=2},
  ["Patriot"]    ={peak=32,mu=62,sigma_L=24,tail_dist=110,band="S",  floor=3},
  ["Rapier"]     ={peak=12,mu=6, sigma_L=2.5,tail_dist=14,band="IJ", floor=0},
  ["Gepard"]     ={peak=18,mu=6, sigma_L=2, tail_dist=18, band="IJ", floor=0},
  ["Roland"]     ={peak=35,mu=5, sigma_L=2, tail_dist=12, band="IJ", floor=3},
  ["HQ-7"]       ={peak=38,mu=8, sigma_L=3.5,tail_dist=18,band="IJ", floor=3},
  ["HQ-2"]       ={peak=70,mu=38,sigma_L=15,tail_dist=80, band="S",  floor=5},
  ["C-RAM"]      ={peak=3, mu=3, sigma_L=1, tail_dist=5,  band="OPT",floor=0},
  ["Avenger"]    ={peak=3, mu=3, sigma_L=1, tail_dist=5,  band="OPT",floor=0},
  ["Chaparral"]  ={peak=3, mu=3, sigma_L=1, tail_dist=5,  band="OPT",floor=0},
  ["Linebacker"] ={peak=3, mu=3, sigma_L=1, tail_dist=5,  band="OPT",floor=0},
  ["Silkworm"]   ={peak=35,mu=20,sigma_L=8, tail_dist=40, band="IJ", floor=3},
  ["Dog Ear"]    ={peak=40,mu=10,sigma_L=4, tail_dist=20, band="IJ", floor=5},
  ["Pantsir S1"] ={peak=10,mu=9, sigma_L=4, tail_dist=20, band="IJ", floor=0}, -- SA-22 canonical
  ["Tor M2"]     ={peak=28,mu=14,sigma_L=6, tail_dist=30, band="IJ", floor=3},
  ["IRIS-T SLM"] ={peak=18,mu=22,sigma_L=10,tail_dist=50, band="IJ", floor=2},
  ["SON-9"]      ={peak=48,mu=14,sigma_L=6, tail_dist=30, band="IJ", floor=5},
  -- IDF Mod
  ["TAMIR IDFA"]  ={peak=19,mu=25,sigma_L=12,tail_dist=52,band="S",  floor=2},
  ["STUNNER IDFA"]={peak=16,mu=45,sigma_L=18,tail_dist=80,band="S",  floor=2},
  -- HDS Mod (canonical for keys with no base equivalent)
  ["SA-10C HDS"]         ={peak=30,mu=50,sigma_L=20,tail_dist=92, band="S",  floor=3},
  ["SA-12 HDS"]          ={peak=35,mu=50,sigma_L=18,tail_dist=90, band="S",  floor=3},
  ["SAMPT Block 1 HDS"]  ={peak=28,mu=45,sigma_L=18,tail_dist=85, band="S",  floor=3},
  ["SAMPT Block 1INT HDS"]={peak=26,mu=48,sigma_L=18,tail_dist=88,band="S",  floor=3},
  ["SAMPT Block 2 HDS"]  ={peak=22,mu=52,sigma_L=20,tail_dist=92, band="S",  floor=2},
  -- SMA Mod (canonical for SMA-only keys)
  ["RBS70 SMA"]    ={peak=5, mu=4, sigma_L=2, tail_dist=10,band="OPT",floor=0},  -- canonical for RBS70 family
  ["RBS90 SMA"]    ={peak=5, mu=4, sigma_L=2, tail_dist=10,band="OPT",floor=0},  -- canonical for RBS90 family
  ["RBS98M SMA"]   ={peak=25,mu=12,sigma_L=5, tail_dist=25,band="IJ", floor=3},  -- canonical
  ["RBS103A SMA"]  ={peak=20,mu=55,sigma_L=20,tail_dist=90,band="S",  floor=2},  -- canonical
  ["RBS103B SMA"]  ={peak=22,mu=45,sigma_L=18,tail_dist=80,band="S",  floor=2},  -- canonical
  ["Lvkv9040M SMA"]={peak=15,mu=3, sigma_L=1, tail_dist=8, band="OPT",floor=0},  -- canonical
  -- CH Mod (canonical for CHM-only keys)
  ["2S38 CHM"]             ={peak=8, mu=3, sigma_L=1, tail_dist=8,  band="OPT",floor=0},
  ["PGL-625 CHM"]          ={peak=12,mu=6, sigma_L=2.5,tail_dist=14,band="OPT",floor=0}, -- Type-08
  ["HQ-17A CHM"]           ={peak=30,mu=11,sigma_L=5, tail_dist=24, band="IJ", floor=3},
  ["M903PAC3 CHM"]         ={peak=15,mu=58,sigma_L=22,tail_dist=105,band="S",  floor=2},
  ["TorM2M CHM"]           ={peak=26,mu=16,sigma_L=6, tail_dist=32, band="IJ", floor=3}, -- variant
  ["NASAMS3-AMRAAMER CHM"] ={peak=20,mu=35,sigma_L=14,tail_dist=65, band="IJ", floor=2},
  ["NASAMS3-AIM9X2 CHM"]   ={peak=10,mu=15,sigma_L=6, tail_dist=30, band="IJ", floor=0},
  ["PGZ-09 CHM"]           ={peak=22,mu=5, sigma_L=2, tail_dist=14, band="IJ", floor=0}, -- Type-09
  ["PGZ-95 CHM"]           ={peak=15,mu=4, sigma_L=2, tail_dist=10, band="OPT",floor=0},
  ["S350-9M100 CHM"]       ={peak=18,mu=35,sigma_L=15,tail_dist=78, band="IJ", floor=2}, -- SA-28 canonical
  ["HQ-22 CHM"]            ={peak=20,mu=70,sigma_L=26,tail_dist=120,band="S",  floor=2},
  ["IRIS-T SLM CHM"]       ={peak=18,mu=22,sigma_L=10,tail_dist=50, band="IJ", floor=2}, -- will be aliased
  ["Skynex CHM"]           ={peak=12,mu=4, sigma_L=2, tail_dist=10, band="OPT",floor=0},
  ["Skyshield CHM"]        ={peak=12,mu=4, sigma_L=2, tail_dist=10, band="OPT",floor=0},
  ["BukM3-9M317M CHM"]     ={peak=22,mu=38,sigma_L=16,tail_dist=75, band="IJ", floor=2}, -- SA-27 canonical
  ["SkySabre CHM"]         ={peak=18,mu=18,sigma_L=7, tail_dist=40, band="IJ", floor=2},
  ["Stormer CHM"]          ={peak=10,mu=5, sigma_L=2, tail_dist=12, band="OPT",floor=0},
  ["THAAD CHM"]            ={peak=10,mu=90,sigma_L=38,tail_dist=140,band="IJ", floor=0},
  ["WieselOzelot CHM"]     ={peak=3, mu=3, sigma_L=1, tail_dist=5,  band="OPT",floor=0},
  ["USInfantryFIM92K CHM"] ={peak=3, mu=3, sigma_L=1, tail_dist=5,  band="OPT",floor=0},
}

-- Alias entries: point alias keys to the canonical entry's table.
-- Modifying any canonical entry above automatically updates all its aliases.
-- This prevents parameter drift when updating values.
do
  local p = MANTIS.JammerSAMParams
  -- NATO designation aliases
  p["SA-21"]  = p["S-400"]      -- SA-21 Growler
  p["SA-22"]  = p["Pantsir S1"] -- SA-22 Greyhound
  p["SA-23"]  = p["S-300VM"]    -- SA-23 Gladiator
  p["SA-23B"] = p["S-300V4"]    -- SA-23B Antey-2500 (improved)
  p["SA-27"]  = p["BukM3-9M317M CHM"]  -- SA-27 Gollum (Buk-M3)
  p["SA-28"]  = p["S350-9M100 CHM"]    -- SA-28 Vityaz (S-350)
  -- Buk-M3 variants (same radar)
  p["BukM3-9M317MA CHM"] = p["BukM3-9M317M CHM"]
  -- S-350 variants (same radar)
  p["S350-9M96D CHM"] = p["S350-9M100 CHM"]
  -- Pantsir variants
  p["PantsirS1 CHM"] = p["Pantsir S1"]
  p["PantsirS2 CHM"] = p["Pantsir S1"]
  -- Tor-M2 variants
  p["TorM2 CHM"]  = p["Tor M2"]
  p["TorM2K CHM"] = p["Tor M2"]
  -- Patriot PAC-2 (same MPQ-65 radar)
  p["M903PAC2 CHM"]     = p["Patriot"]
  p["M903PAC2KAT1 CHM"] = p["Patriot"]
  -- IRIS-T (base and CHM are same system)
  p["IRIS-T SLM CHM"] = p["IRIS-T SLM"]
  -- HDS variants (same radar as base entry)
  p["SA-2 HDS"]    = p["SA-2"]
  p["SA-3 HDS"]    = p["SA-3"]
  p["SA-10B HDS"]  = p["SA-10B"]
  p["SA-17 HDS"]   = p["SA-17"]
  p["SA-23 HDS"]   = p["S-300VM"]
  p["HQ-2 HDS"]    = p["HQ-2"]
  -- Roland / FlaRakRad (same system)
  p["FlaRakRad CHM"] = p["Roland"]
  -- Phalanx-class CIWS (Ka-band, essentially unjammable)
  p["C-RAM CHM"]    = p["C-RAM"]
  p["LD-3000 CHM"]  = p["C-RAM"]
  p["LD-3000M CHM"] = p["C-RAM"]
  -- SMA / CHM Swedish duplicates (CH mod re-implements SMA assets)
  p["RBS70 CHM"]    = p["RBS70 SMA"]
  p["RBS70M SMA"]   = p["RBS70 SMA"]
  p["RBS70M CHM"]   = p["RBS70 SMA"]
  p["RBS90 CHM"]    = p["RBS90 SMA"]
  p["RBS90M SMA"]   = p["RBS90 SMA"]
  p["RBS90M CHM"]   = p["RBS90 SMA"]
  p["RBS98M CHM"]   = p["RBS98M SMA"]
  p["RBS103A CHM"]  = p["RBS103A SMA"]
  p["RBS103AM SMA"] = p["RBS103A SMA"]
  p["RBS103AM CHM"] = p["RBS103A SMA"]
  p["RBS103B CHM"]  = p["RBS103B SMA"]
  p["RBS103BM SMA"] = p["RBS103B SMA"]
  p["RBS103BM CHM"] = p["RBS103B SMA"]
  p["Lvkv9040M CHM"]= p["Lvkv9040M SMA"]
  -- IR MANPADS (all near-zero, different systems but share params)
  p["LAV-AD CHM"]           = p["SA-9"]
  -- NOTE: SA-13, Avenger, Chaparral, Linebacker kept separate (different real systems)
end


--- @type MANTIS.JammerSAMParamsNaval
MANTIS.JammerSAMParamsNaval = {
  -- Calibration note (research pass): high power-aperture warship radars
  -- (SPY-1/SPY-6/SAMPSON/Poliment/HHQ-9B) are modeled HARDER to jam than their
  -- ground peers -- lower peak/floor, mu pushed outward -- reflecting shipboard
  -- prime power, large multi-face arrays, low sidelobes and sensor redundancy.
  -- Documented ECM-weak legacy sets (SPG-51 CW illum, Type 909) slightly easier.
  -- Navalized twins remain anchored to ground counterparts (Shtil=SA-11,
  -- Klinok=Tor, OSA-M=SA-8, S-300F=SA-10). Open sources support ordering, not
  -- exact percentages -- tune in-mission as needed.
  -- USA AEGIS
  ["CH_Ticonderoga"]        = { peak=17, mu=70, sigma_L=24, tail_dist=115, band="S",  floor=2 },
  ["CH_Ticonderoga_CMP"]    = { peak=17, mu=70, sigma_L=24, tail_dist=115, band="S",  floor=2 },
  ["CH_Arleigh_Burke_IIA"]  = { peak=17, mu=70, sigma_L=24, tail_dist=115, band="S",  floor=2 },
  ["CH_Arleigh_Burke_III"]  = { peak=14, mu=83, sigma_L=28, tail_dist=130, band="S",  floor=2 }, -- SPY-6 AESA
  ["CH_Constellation"]      = { peak=14, mu=63, sigma_L=22, tail_dist=100, band="S",  floor=2 }, -- SPY-6(V)3
  -- UK
  ["Type45"]                = { peak=16, mu=62, sigma_L=24, tail_dist=110, band="S",  floor=2 }, -- SAMPSON
  ["CH_Type26"]             = { peak=18, mu=18, sigma_L=7,  tail_dist=40,  band="IJ", floor=2 }, -- CAMM active RH
  -- Germany
  ["CH_F124"]               = { peak=18, mu=62, sigma_L=24, tail_dist=110, band="IJ", floor=2 }, -- APAR X-band
  -- China
  ["Type052D"]              = { peak=20, mu=55, sigma_L=22, tail_dist=110, band="S",  floor=2 },
  ["Type055"]               = { peak=16, mu=65, sigma_L=24, tail_dist=120, band="S",  floor=2 },
  ["CH_Type054B"]           = { peak=22, mu=38, sigma_L=16, tail_dist=75,  band="S",  floor=3 },
  ["CH_Type056A"]           = { peak=8,  mu=5,  sigma_L=2,  tail_dist=12,  band="OPT",floor=0 }, -- HHQ-10 IR
  -- Russia
  ["CH_Admiral_Gorshkov"]   = { peak=16, mu=80, sigma_L=30, tail_dist=145, band="S",  floor=2 }, -- Poliment AESA
  ["CH_Grigorovich_AShM"]   = { peak=50, mu=28, sigma_L=12, tail_dist=58,  band="IJ", floor=3 }, -- Shtil-1
  ["CH_Grigorovich_LACM"]   = { peak=50, mu=28, sigma_L=12, tail_dist=58,  band="IJ", floor=3 },
  ["CH_Steregushchiy"]      = { peak=22, mu=35, sigma_L=15, tail_dist=70,  band="S",  floor=2 }, -- Redut
  ["CH_Gremyashchiy_AShM"]  = { peak=22, mu=35, sigma_L=15, tail_dist=70,  band="S",  floor=2 },
  ["CH_Gremyashchiy_LACM"]  = { peak=22, mu=35, sigma_L=15, tail_dist=70,  band="S",  floor=2 },
  ["CH_Karakurt_AShM"]      = { peak=10, mu=9,  sigma_L=4,  tail_dist=20,  band="IJ", floor=0 }, -- Pantsir-M
  ["CH_Karakurt_LACM"]      = { peak=10, mu=9,  sigma_L=4,  tail_dist=20,  band="IJ", floor=0 },
  -- CIWS / MANPADS-only hulls -> optical, essentially unjammable (floor 0)
  ["CH_Type022"]            = { peak=3,  mu=3,  sigma_L=1,  tail_dist=5,   band="OPT",floor=0 },
  ["CH_IranFAC_MG"]         = { peak=3,  mu=3,  sigma_L=1,  tail_dist=5,   band="OPT",floor=0 },
  ["CH_IranFAC_MG_AShM"]    = { peak=3,  mu=3,  sigma_L=1,  tail_dist=5,   band="OPT",floor=0 },
  ["Strb90"]                = { peak=3,  mu=3,  sigma_L=1,  tail_dist=5,   band="OPT",floor=0 },
  ["HSwMS_Visby"]           = { peak=3,  mu=3,  sigma_L=1,  tail_dist=5,   band="OPT",floor=0 }, -- gun/CIWS: unjammable

  -- Base-game DCS hulls (canonical entries; aliases set in the do-block below)
  ["TICONDEROG"]            = { peak=17, mu=60, sigma_L=22, tail_dist=110, band="S",  floor=2 }, -- SPY-1  (NO trailing E)
  ["USS_Arleigh_Burke_IIa"] = { peak=17, mu=60, sigma_L=22, tail_dist=110, band="S",  floor=2 }, -- SPY-1D
  ["PERRY"]                 = { peak=33, mu=20, sigma_L=9,  tail_dist=48,  band="IJ", floor=3 }, -- SM-1 / SPG-51 (X-band illum)
  ["MOSCOW"]                = { peak=32, mu=42, sigma_L=18, tail_dist=90,  band="S",  floor=3 }, -- S-300F
  ["PIOTR"]                 = { peak=28, mu=70, sigma_L=26, tail_dist=130, band="S",  floor=3 }, -- S-300F/FM
  ["NEUSTRASH"]             = { peak=28, mu=8,  sigma_L=3.5,tail_dist=18,  band="IJ", floor=2 }, -- Kinzhal
  ["REZKY"]                 = { peak=35, mu=8,  sigma_L=3.5,tail_dist=18,  band="IJ", floor=3 }, -- OSA-M
  ["MOLNIYA"]               = { peak=3,  mu=3,  sigma_L=1,  tail_dist=5,   band="OPT",floor=0 }, -- Strela
  ["KUZNECOW"]              = { peak=24, mu=8,  sigma_L=3.5,tail_dist=18,  band="IJ", floor=2 }, -- Kinzhal/Kashtan
  ["CHAP_Project22160_TorM2KM"] = { peak=28, mu=12, sigma_L=5, tail_dist=28, band="IJ", floor=3 }, -- Tor M2KM
  ["Type_052C"]             = { peak=20, mu=55, sigma_L=22, tail_dist=110, band="S",  floor=2 }, -- HHQ-9
  ["Type_052B"]             = { peak=30, mu=20, sigma_L=10, tail_dist=48,  band="S",  floor=3 }, -- HHQ-16/Shtil
  ["Type_054A"]             = { peak=26, mu=28, sigma_L=12, tail_dist=58,  band="S",  floor=3 }, -- HHQ-16
  ["hms_invincible"]        = { peak=36, mu=25, sigma_L=11, tail_dist=52,  band="IJ", floor=3 }, -- Sea Dart / Type 909
  ["CVN_71"]                = { peak=8,  mu=5,  sigma_L=2,  tail_dist=12,  band="OPT",floor=0 }, -- NSSM/RAM (carrier point)

  -- Admiral mod -- worked example (USS America LHA-6):
  --   band  <- radar band (Sea Sparrow Mk 95 illuminator = X-band => IJ)
  --   floor <- inverse of GT ECM_K hint (ECM_K 0.65 = moderate => floor ~2-3)
  --   mu    <- engagement range in nm (20 km ~= 11 nm)
  --   peak/sigma_L/tail_dist <- copy nearest short-IJ analog (Sea Sparrow ~ NASAMS/SA-11 class)
  ["USS America LHA-6"] = { peak=22, mu=11, sigma_L=5, tail_dist=25, band="IJ", floor=3 },
  -- desdemicabina AEGIS hulls: SPY-1 family fingerprint (peak 17 / floor 2 / S),
  -- mu scaled to the ~100km SM-2 envelope of these units.
  ["DDG39"]                             = { peak=17, mu=55, sigma_L=22, tail_dist=110, band="S", floor=2 }, -- SPY-1D(V)
  ["F100"]                              = { peak=17, mu=55, sigma_L=22, tail_dist=110, band="S", floor=2 }, -- SPY-1D
  ["F105"]                              = { peak=17, mu=55, sigma_L=22, tail_dist=110, band="S", floor=2 }, -- SPY-1D
  -- Admiral SAM shooters (POINT hulls are aliased to the CIWS OPT entry in the do-block below)
  ["HMS Duncan"]                        = { peak=16, mu=54, sigma_L=22, tail_dist=110, band="S",  floor=2 }, -- Aster (ECM_K 0.65)
  ["Aquitaine D650"]                    = { peak=16, mu=65, sigma_L=24, tail_dist=120, band="S",  floor=2 }, -- Aster 30 (mod ECM_K 5.0 - see note)
  ["D651_Normandie"]                    = { peak=16, mu=65, sigma_L=24, tail_dist=120, band="S",  floor=2 }, -- Aster 30
  ["MEKO_HN"]                           = { peak=22, mu=27, sigma_L=12, tail_dist=55,  band="IJ", floor=2 }, -- ESSM/SM-2
  ["MEKO_TN"]                           = { peak=22, mu=27, sigma_L=12, tail_dist=55,  band="IJ", floor=2 },
  ["Admiral Ushakov"]                   = { peak=48, mu=25, sigma_L=11, tail_dist=55,  band="IJ", floor=3 }, -- SA-N-7 Gadfly
  ["Udaloy II DDG Admiral Chabanenko"]  = { peak=28, mu=7,  sigma_L=3,  tail_dist=18,  band="IJ", floor=3 }, -- SA-N-9 Klinok
  ["USS San Antonio LPD-17"]            = { peak=22, mu=8,  sigma_L=4,  tail_dist=20,  band="IJ", floor=3 }, -- Sea Sparrow
  ["LPD_Foundre"]                       = { peak=10, mu=3,  sigma_L=2,  tail_dist=10,  band="OPT",floor=0 }, -- Mistral (IR, near-unjammable)
}

-- Naval jammer aliases: variants that share a hull/radar point to one curve,
-- so tuning the canonical entry updates all of them (mirrors JammerSAMParams).
do
  local n = MANTIS.JammerSAMParamsNaval
  -- US carriers + LHA + Type 071: point self-defence (NSSM/RAM/HHQ-10), optical-grade
  n["CVN_72"]   = n["CVN_71"]; n["CVN_73"] = n["CVN_71"]; n["CVN_75"] = n["CVN_71"]
  n["Stennis"]  = n["CVN_71"]; n["VINSON"] = n["CVN_71"]; n["LHA_Tarawa"] = n["CVN_71"]
  n["Type_071"] = n["CVN_71"]
  -- Grisha shares the SA-N-4 (OSA-M) curve with Rezky
  n["ALBATROS"] = n["REZKY"]
  -- Kuznetsov 2017 variant
  n["CV_1143_5"] = n["KUZNECOW"]
  -- Vasily Bykov base (gun) ~ Strela-grade optical
  n["CHAP_Project22160"] = n["MOLNIYA"]
  -- Admiral mod CIWS / RAM / gun-only hulls: all optical-grade, essentially unjammable.
  -- Aliased to the base OPT curve so they resolve without cluttering the table.
  n["USS_Oak_Hill LSD-51"]                    = n["MOLNIYA"]  -- RAM + Phalanx
  n["USS_Blue_Ridge"]                         = n["MOLNIYA"]  -- Phalanx
  n["USS_Support_Ship_Sacramento_AOE-1"]      = n["MOLNIYA"]  -- RAM + Phalanx
  n["USNS_Henry_Kaiser"]                      = n["MOLNIYA"]  -- .50cal
  n["HMS_Albion L14"]                         = n["MOLNIYA"]  -- Phalanx
  n["OSA_One"]                                = n["MOLNIYA"]  -- AK-230 (NO_SAM)
  n["OSA_Two"]                                = n["MOLNIYA"]  -- AK-230
  n["IRIS_Alvand"]                            = n["MOLNIYA"]  -- OtoBreda 40mm / 20mm
  -- desdemicabina amphibs: CIWS / gun-only, optical-grade unjammable
  n["L02"]                                    = n["MOLNIYA"]  -- 3x Phalanx
  n["L52"]                                    = n["MOLNIYA"]  -- 2x Phalanx (NO_SAM)
  n["L61"]                                    = n["MOLNIYA"]  -- .50cal only
end


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
  --@param #string Coalition Coalition side of your setup, e.g. "blue", "red" or "neutral"
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
  function MANTIS:New(name,samprefix,ewrprefix,hq,Coalition,dynamic,awacs, EmOnOff, Padding, Zones)
    -- Inject NAVYGROUP:SetMANTIS convenience API (safe if NAVYGROUP not loaded/already done)
    MANTIS._InjectNavyGroupAPI()
    
    
    -- Inherit everything from BASE class.
    local self = BASE:Inherit(self, FSM:New()) -- #MANTIS
    
    -- DONE: Create some user functions for these
    -- DONE: Make HQ useful
    -- DONE: Set SAMs to auto if EWR dies
    -- DONE: Refresh SAM table in dynamic mode
    -- DONE: Treat Awacs separately, since they might be >80km off site
    -- DONE: Allow tables of prefixes for the setup
    -- DONE: Auto-Mode with range setups for various known SAM types.
    -- DONE: Added reaction on HIT and UNIT LOST events.
    
    self.name = name or "mymantis"
    self.SAM_Templates_Prefix = samprefix or "Red SAM"
    self.EWR_Templates_Prefix = ewrprefix or "Red EWR"
    self.HQ_Template_CC = hq or nil
    self.Coalition = Coalition or "red"
    self.coalition = Coalition == "blue" and coalition.side.BLUE or coalition.side.RED
    self.SAM_Table = {}
    self.SAM_Table_Long = {}
    self.SAM_Table_Medium = {}
    self.SAM_Table_Short = {}
    self.SAM_Table_PointDef = {}
    self.dynamic = dynamic or false
    self.checkradius = 25000
    self.grouping = 5000
    self.acceptrange = 80000
    self.detectinterval = 30
    self.SEADNaval = false -- ships hard-kill inbound missiles; they do not go EMCON under SEAD (see SetNavalSEAD)
    self.NavalSurfaceWakeup = true -- quiet ships go active when enemy surface combatants close (see SetNavalSurfaceWakeup)
    self.NavalSurfaceWakeupRadius = nil -- meters; nil = each ship uses its own engagement radius
    self.NavalPerUnit = true -- classify & switch every ship unit individually (see SetNavalPerUnit)
    self.NavalAutonomy = true -- ship groups outside EWR radar coverage go alarm RED and search autonomously (see SetNavalAutonomy)
    self.NavalAutonomyRadius = 150000 -- meters; a ship group within this distance of an alive EWR group counts as covered
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
    --self.SAMCheckRanges = {}
    self.usezones = false
    self.AcceptZones = {}
    self.RejectZones = {}
    self.ConflictZones = {}
    self.maxlongrange = 1
    self.maxmidrange = 2
    self.maxshortrange = 2
    self.maxpointdefrange = 6 
    self.maxclassic = 6
    self.autoshorad = true
    self.ShoradGroupSet = SET_GROUP:New() -- Core.Set#SET_GROUP
    self.FilterZones = Zones
    self.LastThreatEval = {}
    self.InboundARMs = {}
    
    self.SkateZones = nil
    self.SkateNumber =  3
    self.shootandscoot = false
    
    self.SmokeDecoy = false
    self.SmokeDecoyColor = SMOKECOLOR.White
    
    self.UseEmOnOff = true
    if EmOnOff == false then
      self.UseEmOnOff = false
    end

    if type(awacs) == "string" then
      self.advAwacs = true
    else
      self.advAwacs = false
    end
    
    self:SetDLinkCacheTime()
    
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
    
    self.logsamstatus = false
    
    self:T({self.ewr_templates})
    
    self.SAM_Group = SET_GROUP:New():FilterPrefixes(self.SAM_Templates_Prefix):FilterCoalitions(self.Coalition)
    --- [Internal] Invalidate the cached SAM composition when this group is added to the SAM set.
    -- @param Core.Set#SET_GROUP self The SAM set.
    -- @param #string From The From State.
    -- @param #string Event The Event.
    -- @param #string To The To State.
    -- @param #string Name The added group name.
    -- @param Wrapper.Group#GROUP Group The added group.
    function self.SAM_Group:onafterAdded(From,Event,To,Name,Group)
      local ammo = Group:GetProperty("MANTIS_AMMO") -- #table
      if ammo then ammo.trUnits = nil end
    end
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
    
    -- counter for SAM table updates
    self.checkcounter = 1
    
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
  self:AddTransition("*",             "SAMUnitHit",              "*")           -- A SAM unit was hit
  self:AddTransition("*",             "SAMUnitLost",             "*")           -- A SAM Unit was lost
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
  
  --- On After "SAMUnitHit" event. A SAM Unit was hit.
  -- @function [parent=#MANTIS] OnAfterSeadSuppressionEnd
  -- @param #MANTIS self
  -- @param #string From The From State
  -- @param #string Event The Event
  -- @param #string To The To State
  -- @param Wrapper.Group#GROUP Group The GROUP of the hit UNIT object
  -- @param #string Name Name of the suppressed group
  
  --- On After "SAMUnitLoast" event. A SAM Unit was lost.
  -- @function [parent=#MANTIS] OnAfterSeadSuppressionEnd
  -- @param #MANTIS self
  -- @param #string From The From State
  -- @param #string Event The Event
  -- @param #string To The To State
  -- @param Wrapper.Group#GROUP Group The GROUP of the lost UNIT object
  -- @param #string Name Name of the suppressed group
  
  return self
 end

-----------------------------------------------------------------------
-- MANTIS helper functions
-----------------------------------------------------------------------

  --- Set to accept accoustic detection. Set this *before* MANTIS starts!
  -- @param #MANTIS self
  -- @param #number Radius (Optional) Radius in which we can "hear" units. Defaults to 2000 meters.
  -- @param #table UnitCategories (Optional) Set what Unit Categories we can "hear". Defaults to `{Unit.Category.HELICOPTER}`
  -- @return #MANTIS self
  function MANTIS:SetAccousticDetectionOn(Radius,UnitCategories)
    self.DetectAccoustic = true
    self.DetectAccousticRadius = Radius or 2000
    self.DetectAccousticCategories = UnitCategories or {Unit.Category.HELICOPTER}
    return self
  end
  
  --- Switch off accoustic detection.
  -- @param #MANTIS self
  -- @return #MANTIS self
  function MANTIS:SetAccousticDetectionOff()
    self.DetectAccoustic = false
    return self
  end
  
  --- [Internal] Function to manage hits on SAM units
  -- @param #MANTIS self
  -- @param Core.Event#EVENTDATA EventData The EVENT data
  -- @return #MANTIS self
  function MANTIS:_EventHandler(EventData)
   self:T(self.lid .. "_EventHandler")
   
   local function IsOneOfOurs(name)
      for _,_name in pairs(self.ewr_templates) do
        if string.find(name,_name,1,true) then
          return true
        end
      end
      return false
   end
   
   --- [Internal] Wake an eligible site after a hit or unit loss.
   -- @param #string Name The affected group name.
   -- @param Wrapper.Group#GROUP Group The affected group.
   -- @param #string lostUnitName (Optional) Unit reported lost by the current event.
   local function SwitchSAMOn(Name,Group,lostUnitName)
    if self.NavalPerUnit and Group and Group:IsShip() and self._navalSAMs then
      -- Per-unit naval: a hit wakes this group's managed radars individually
      if not self.SuppressedGroups[Name] then
        for _,_unit in pairs(Group:GetUnits() or {}) do
          local uname = _unit:GetName()
          if self._navalSAMs[uname] and self.SamStateTracker[uname] == "GREEN"
            and not (self._jammerEnabled and self._jammedSAMs and self._jammedSAMs[uname]) then
            self.SamStateTracker[uname] = "RED"
          end
        end
        self:_ApplyNavalAlarmState() -- apply group alarm state immediately on hit
        self:__RedState(1,Group)
      end
      return
    end
    local suppressed = self.SuppressedGroups[Name] or false
    local jammed = self._jammerEnabled and self._jammedSAMs and self._jammedSAMs[Name] or false
    local ammo = Group:GetProperty("MANTIS_AMMO") -- #table
    if ammo and lostUnitName and (not ammo.trUnits or ammo.trUnits[lostUnitName]) then
      self:_RefreshSAMTracking(Group,Name,ammo,lostUnitName)
    end
    if not suppressed and not jammed and not (ammo and (ammo.trLost or ammo.canSleep and ammo.empty)) and self.SamStateTracker[Name] == "GREEN" then
      self.SamStateTracker[Name] = "RED"
      if self.UseEmOnOff then
        -- DONE: add emissions on/off
        Group:EnableEmission(true)
      elseif (not self.UseEmOnOff) then
        Group:OptionAlarmStateRed()          
      end
      self:__RedState(1,Group)
      if self.SmokeDecoy == true then
        self:_SmokeUnits(Group)
      end
    end
   end
   
   local coordinate -- Core.Point#COORDINATE
   local Name -- #string
   local Group -- Wrapper.Group#GROUP
   local lasthit = 0
   local firsthit = false
   local alerton = false
   
   -- Check if we can get a location
   
   local data = EventData -- Core.Event#EVENTDATA
   if data.id == EVENTS.Hit then
    -- Unit hit, one of ours?
    if data.TgtGroupName and IsOneOfOurs(data.TgtGroupName) then
      self:T("Unit hit in group: "..data.TgtGroupName)
      if data.TgtGroup then
        lasthit = data.TgtGroup:GetProperty("MANTIS_LASTHIT")
        firsthit = (lasthit==nil) and true or false
        if firsthit == true then alerton = true end
        if lasthit ~= nil and timer.getTime()-lasthit > self.ShoradTime then alerton = true end
        if alerton or self.debug then coordinate = data.TgtGroup:GetCoordinate() end
        Name = data.TgtGroupName
        Group = data.TgtGroup
        if alerton == true then
          self:__SAMUnitHit(1,Group,Name)
          SwitchSAMOn(Name,Group) 
        end
        if coordinate and self.debug then
          local text = coordinate:ToStringMGRS()
          self:I("Location: "..text)
        end
      end
    end
   end
      
   if data.id == EVENTS.UnitLost then 
    if data.IniGroupName and IsOneOfOurs(data.IniGroupName) then
      self:T("Unit lost in group: "..data.IniGroupName)
      if data.IniGroup then
        lasthit = data.IniGroup:GetProperty("MANTIS_LASTHIT")
        firsthit = (lasthit==nil) and true or false
        if firsthit == true then alerton = true end
        if lasthit ~= nil and timer.getTime()-lasthit > self.ShoradTime then alerton = true end
        coordinate = data.IniGroup:GetCoordinate()
        Name = data.IniGroupName
        Group = data.IniGroup
        alerton = true
        SwitchSAMOn(Name,Group,data.IniUnitName)
        self:__SAMUnitLost(1,Group,Name)    
        if coordinate and self.debug then
          local text = coordinate:ToStringMGRS()
          self:I("Location: "..text)
        end
      end
    end
   end
   
   if firsthit == true or alerton == true then
    Group:SetProperty("MANTIS_LASTHIT",timer.getTime())
   end
   
   
   if coordinate ~= nil and Name ~= nil and Group ~=nil and alerton == true then
    if self.ShoradLink then
      self:T("Shorad activated for: "..Name)
      local Shorad = self.Shorad -- Functional.Shorad#SHORAD
      local radius = self.checkradius
      local ontime = self.ShoradTime
      Shorad:WakeUpShorad(Name, radius, ontime, nil, true)
      self:__ShoradActivated(1,Name, radius, ontime)
    end
    if self.autorelocate and Group then
      Group:RelocateGroundRandomInRadius(20,500,true,true,nil,true)
    end
   end
   
   return self
  end


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
  -- @param #number Number (Optional) Number of closest zones to be considered, defaults to 3.
  -- @param #boolean Random If true, use a random coordinate inside the next zone to scoot to.
  -- @param #string Formation (Optional) Formation to use, defaults to "Cone". See mission editor dropdown for options.
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
    self.AcceptZonesNo = UTILS.TableLength(self.AcceptZones)
    self.RejectZonesNo = UTILS.TableLength(self.RejectZones)
    self.ConflictZonesNo = UTILS.TableLength(self.ConflictZones)
    self:T(string.format("AcceptZonesNo = %d | RejectZonesNo = %d | ConflictZonesNo = %d",self.AcceptZonesNo,self.RejectZonesNo,self.ConflictZonesNo))
    if self.AcceptZonesNo > 0 or self.RejectZonesNo > 0 or self.ConflictZonesNo > 0 then
      self.usezones = true
    end
    return self
  end
  
  --- Add a single reject zone to MANTIS.
  -- @param #MANTIS self
  -- @param Core.Zone#ZONE Zone The zone to be added
  -- @return #MANTIS self
  function MANTIS:AddRejectZone(Zone)
    if Zone and Zone:IsInstanceOf("ZONE_BASE") then
      table.insert(self.RejectZones,Zone)
      self.usezones = true
    end
    return self
  end
  
  --- Add a single accept zone to MANTIS.
  -- @param #MANTIS self
  -- @param Core.Zone#ZONE Zone The zone to be added
  -- @return #MANTIS self
  function MANTIS:AddAcceptZone(Zone)
    if Zone and Zone:IsInstanceOf("ZONE_BASE") then
      table.insert(self.AcceptZones,Zone)
      self.usezones = true
    end
    return self
  end
  
  --- Add a single conflict zone to MANTIS.
  -- @param #MANTIS self
  -- @param Core.Zone#ZONE Zone The zone to be added
  -- @return #MANTIS self
  function MANTIS:AddConflictZone(Zone)
    if Zone and Zone:IsInstanceOf("ZONE_BASE") then
      table.insert(self.ConflictZones,Zone)
      self.usezones = true
    end
    return self
  end
  
  --- Function to set corridor zones.
  -- @param #MANTIS self
  -- @param Core.Set#SET_ZONE CorridorZones Can be handed in as SET\_ZONE or single ZONE object.
  -- @return #MANTIS self
  function MANTIS:SetCorridorZones(CorridorZones)
    self:T(self.lid .. "SetCorridorZones")
    if CorridorZones and CorridorZones:IsInstanceOf("SET_ZONE") then
      self.corridorzones = CorridorZones
      self.usecorridors = true
    elseif CorridorZones and CorridorZones:IsInstanceOf("ZONE_BASE") then
      if not self.corridorzones then self.corridorzones = SET_ZONE:New() end
      self.corridorzones:AddZone(CorridorZones)
      self.usecorridors = true
    end
    if self.intelset then
      for _,_intel in pairs(self.intelset) do
        _intel:SetCorridorZones(self.corridorzones)
      end
    end
    return self
  end
  
  --- Function to add one corridor zone.
  -- @param #MANTIS self
  -- @param Core.Zone#ZONE CorridorZone The ZONE object to be added.
  -- @return #MANTIS self
  function MANTIS:AddCorridorZone(CorridorZone)
    self:T(self.lid .. "AddCorridorZone")
    self:SetCorridorZones(CorridorZone)
    return self
  end
  
  --- Function to set corridor zone floor and ceiling in FEET.
  -- @param #MANTIS self
  -- @param #number Floor Floor altitude ASL in feet.
  -- @param #number Ceiling Ceiling altitude ASL in feet.
  -- @return #MANTIS self
  function MANTIS:SetCorridorZoneFloorAndCeiling(Floor,Ceiling)
    self.corridorfloor = UTILS.FeetToMeters(Floor)
    self.corridorceiling = UTILS.FeetToMeters(Ceiling)
    if self.intelset then
      for _,_intel in pairs(self.intelset) do
        _intel:SetCorridorLimits(self.corridorfloor,self.corridorceiling)
      end
    end
    return self
  end
  
  --- Function to set corridor zone floor and ceiling in METERS.
  -- @param #MANTIS self
  -- @param #number Floor Floor altitude ASL in meters.
  -- @param #number Ceiling Ceiling altitude ASL in meters.
  -- @return #MANTIS self
  function MANTIS:SetCorridorZoneFloorAndCeilingMeters(Floor,Ceiling)
    self.corridorfloor = Floor    
    self.corridorceiling = Ceiling
    if self.intelset then
      for _,_intel in pairs(self.intelset) do
        _intel:SetCorridorLimits(self.corridorfloor,self.corridorceiling)
      end
    end
    return self
  end
  
  --- Function to set the detection radius of the EWR in meters. (Deprecated, SAM range is used)
  -- @param #MANTIS self
  -- @param #number radius Radius of the EWR detection zone
  function MANTIS:SetEWRRange(radius)
    self:T(self.lid .. "SetEWRRange")
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
  
  --- Function to set Short Range SAMs to spit out smoke as decoy, if an enemy plane is in range.
  -- @param #MANTIS self
  -- @param #boolean Onoff Set to true for on and nil/false for off.
  -- @param #number Color (Optional) Color to use, defaults to `SMOKECOLOR.White`
  function MANTIS:SetSmokeDecoy(Onoff,Color)
    self.SmokeDecoy = Onoff
    self.SmokeDecoyColor = Color or SMOKECOLOR.White
    return self
  end
  
    --- Function to set number of SAMs going active on a valid, detected thread
    -- @param #MANTIS self
    -- @param #number Short (Optional) Number of short-range systems activated, defaults to 2.
    -- @param #number Mid (Optional) Number of mid-range systems activated, defaults to 2.
    -- @param #number Long (Optional) Number of long-range systems activated, defaults to 1.
    -- @param #number Classic (Optional) (non-automode) Number of overall systems activated, defaults to 6.
    -- @param #number Point (Optional) Number of point defense and AAA systems activated, defaults to 6.
    -- @return #MANTIS self
  function MANTIS:SetMaxActiveSAMs(Short,Mid,Long,Classic,Point)
    self:T(self.lid .. "SetMaxActiveSAMs")
    self.maxclassic = Classic or 6
    self.maxlongrange = Long or 1
    self.maxmidrange = Mid or 2
    self.maxshortrange = Short or 2
    self.maxpointdefrange= Point or 6
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
  
  --- Function to set how long INTEL DLINK remembers contacts.
  -- @param #MANTIS self
  -- @param #number seconds Remember this many seconds, at least 5 seconds.
  -- @return #MANTIS self
  function MANTIS:SetDLinkCacheTime(seconds)
    self.DLinkCacheTime = math.abs(seconds or 120)
    if self.DLinkCacheTime < 5 then self.DLinkCacheTime = 5 end
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
  -- @param #number ratio (Optional)  Percentage to use for advanced mode, defaults to 100%
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
  
  --- [Internal] Check if any EWR or AWACS is still alive
  -- @param #MANTIS self
  -- @return #boolean outcome
    function MANTIS:_CheckAnyEWRAlive()
      self:T(self.lid .. "_CheckAnyEWRAlive")
    
      for _, group in pairs(self.EWR_Group:GetSet()) do
        if group and group:IsAlive() then
          return true
        end
      end
      if self.AWACS_Prefix then
        local awacs = GROUP:FindByName(self.AWACS_Prefix)
        if awacs and awacs:IsAlive() then
          return true
        end
      end
      return false
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
    self:T(string.format("AcceptZonesNo = %d | RejectZonesNo = %d | ConflictZonesNo = %d",self.AcceptZonesNo,self.RejectZonesNo,self.ConflictZonesNo))
    if self.AcceptZonesNo > 0 then
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
    if self.RejectZonesNo > 0 then 
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
    if self.ConflictZonesNo > 0 then
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
  
  --- [Internal] Function to prefilter height based and check for Helo activity.
  -- @param #MANTIS self
  -- @param #number height
  -- @param Core.Point#COORDINATE SamCoordinate
  -- @param #table contactSnapshot Contact facts captured once for the current check.
  -- @return #table set
  function MANTIS:_PreFilterHeight(height,SamCoordinate,contactSnapshot)
    self:T(self.lid.."_PreFilterHeight")   
    local set = {}
    for _,contact in pairs(contactSnapshot) do
      local grp = contact.group -- Wrapper.Group#GROUP
      local coord = contact.coordinate
      local dist = 0
      local include = true
      if contact.isGround then include = false end
      if contact.isShip then include = false end -- MANTIS is anti-air: surface contacts are not engageable targets
      if contact.coalition == self.coalition then include = false end
      if coord and SamCoordinate and contact.isHelicopter then
        dist = coord:Get2DDistance(SamCoordinate) or 0
        if dist > self.ShoradActDistance then include = false end -- we do not want long range shooting at helos
      end
      if self.debug then
        local text = "Looking at Group: "..grp:GetName() or "N/A"
        text = text .. " Include = "..tostring(include)
        MESSAGE:New(text,10,"MANTIS"):ToAllIf(self.verbose):ToLog()
      end
      local grpalt = contact.height
      if grpalt < height and grpalt > 10 and include == true then
        table.insert(set,coord)
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
  -- @param #table contactSnapshot Contact facts captured once for the current check.
  -- @param #number closeRadius (Optional) Radius requiring a qualifying close threat.
  -- @param #table zoneResults (Optional) Coordinate-zone results shared only within the current check.
  -- @return #boolean True if in any zone, else false
  -- @return #number Distance Target distance in meters or zero when no object is in zone
  -- @return #boolean CloseThreat True if a qualifying target is within closeRadius; nil when no close check is requested or no target qualifies.
  function MANTIS:_CheckObjectInZone(dectset, samcoordinate, radius, height, dlink, contactSnapshot, closeRadius, zoneResults)
    self:T(self.lid.."_CheckObjectInZone")
    -- check if non of the coordinate is in the given defense zone
    local rad = radius or self.checkradius
    local set = dectset
    if dlink then
      -- DEBUG
      set = self:_PreFilterHeight(height,samcoordinate,contactSnapshot)
    end
    --self.friendlyset -- Core.Set#SET_GROUP
    if self.checkforfriendlies == true and self.friendlyset == nil then
      self.friendlyset = SET_GROUP:New():FilterCoalitions(self.Coalition):FilterCategories({"plane","helicopter"}):FilterFunction(function(grp) if grp and grp:InAir() then return true else return false end end):FilterStart()
    end
    local detectedDistance = nil
    local nofriendlies
    for _,_coord in pairs (set) do
      local coord = _coord  -- get current coord to check
      -- output for cross-check
      local targetdistance = samcoordinate:DistanceFromPointVec2(coord)
      if not targetdistance then
        targetdistance = samcoordinate:Get2DDistance(coord)
      end
      -- check accept/reject zones
      local zonecheck = true
      self:T("self.usezones = "..tostring(self.usezones))
      if self.usezones then
        -- DONE
        if zoneResults then
          zonecheck = zoneResults[coord]
        end
        if not zoneResults or zonecheck == nil then
          zonecheck = self:_CheckCoordinateInZones(coord)
          if zoneResults then zoneResults[coord] = zonecheck end
        end
      end
      if self.verbose and self.debug then
        --local dectstring = coord:ToStringLLDMS()
        local samstring = samcoordinate:ToStringMGRS({MGRS_Accuracy=0})
        samstring = string.gsub(samstring,"%s","")
        local inrange = "false"
        if targetdistance <= rad then
          inrange = "true"
        end
        local text = string.format("Checking SAM at %s | Tgtdist %.1fkm | Rad %.1fkm | Inrange %s | Zonecheck %s", samstring, targetdistance/1000, rad/1000, inrange, tostring(zonecheck))
        -- Naval per-unit state summary
        if self._navalSAMs and next(self._navalSAMs) ~= nil then
          local ntot, nred, njam = 0, 0, 0
          local detail = ""
          for uname,_ in pairs(self._navalSAMs) do
            local u = UNIT:FindByName(uname)
            if u and u:IsAlive() then
              ntot = ntot + 1
              local st = self.SamStateTracker[uname] or "GREEN"
              if st == "RED" then nred = nred + 1 end
              local jm = ""
              if self._jammedSAMs and self._jammedSAMs[uname] then njam = njam + 1 jm = " (JAMMED)" end
              local pk = ""
              local parent = self._navalUnitParent and self._navalUnitParent[uname]
              if parent and self._navalAutonomous and self._navalAutonomous[parent] then pk = " [AUTONOMOUS]" end
              if self.verbose then detail = detail..string.format("\n  %s: %s%s%s",uname,st,jm,pk) end
            end
          end
          if ntot > 0 then
            text = text..string.format("\nNaval units: %d | RED %d | GREEN %d | jammed %d",ntot,nred,ntot-nred,njam)..detail
          end
        end
        local m = MESSAGE:New(text,10,"Check"):ToAllIf(self.debug)
        self:T(self.lid..text)
      end
      -- friendlies around?
      if nofriendlies == nil and targetdistance <= rad and zonecheck == true then
        nofriendlies = true
        if self.checkforfriendlies == true then
          local closestfriend, distance = self.friendlyset:GetClosestGroup(samcoordinate)
          if closestfriend and distance and distance < rad then
            nofriendlies = false
          end
        end
      end
      -- end output to cross-check
      if targetdistance <= rad and zonecheck == true and nofriendlies == true then
        if not closeRadius then
          return true, targetdistance
        end
        -- Keep the original distance for SHORAD; a later contact may qualify for the close-threat allowance.
        detectedDistance = detectedDistance or targetdistance
        if targetdistance <= closeRadius then
          return true, detectedDistance, true
        end
      end
    end
    if detectedDistance then
      return true, detectedDistance, false
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
    
    local IntelOne = INTEL:New(groupset,self.coalition,self.name.." IntelOne")
    IntelOne._detectionBatchSize = 1
    IntelOne._detectionBatchInterval = 0.1
    IntelOne.DetectAccoustic = self.DetectAccoustic
    IntelOne.DetectAccousticRadius = self.DetectAccousticRadius or 2000
    IntelOne.DetectAccousticUnitTypes = self.DetectAccousticCategories or {Unit.Category.HELICOPTER}
    --IntelOne:SetClusterAnalysis(true,true,true)
    if self.usecorridors == true then
      IntelOne:SetCorridorZones(self.corridorzones)
      if self.corridorfloor or self.corridorceiling then
        IntelOne:SetCorridorLimits(self.corridorfloor,self.corridorceiling)
      end
    end
    IntelOne:Start()
    
    local IntelTwo = INTEL:New(samset,self.coalition,self.name.." IntelTwo")
    IntelTwo._detectionBatchSize = 1
    IntelTwo._detectionBatchInterval = 0.1
    IntelTwo.DetectAccoustic = self.DetectAccoustic
    IntelTwo.DetectAccousticRadius = self.DetectAccousticRadius or 2000
    IntelTwo.DetectAccousticUnitTypes = self.DetectAccousticCategories or {Unit.Category.HELICOPTER}
    --IntelTwo:SetClusterAnalysis(true,true,true)
    if self.usecorridors == true then
      IntelTwo:SetCorridorZones(self.corridorzones)
      if self.corridorfloor or self.corridorceiling then
        IntelTwo:SetCorridorLimits(self.corridorfloor,self.corridorceiling)
      end
    end
    IntelTwo:Start()
    
    local CacheTime = self.DLinkCacheTime or 120
    local IntelDlink = INTEL_DLINK:New({IntelOne,IntelTwo},self.name.." DLINK",22,CacheTime)
    
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
  -- @param Wrapper.Group#GROUP group (Optional) Already resolved group.
  -- @return #number range Max firing range
  -- @return #number height Max firing height
  -- @return #string type Long, medium or short range
  -- @return #number blind "blind" spot
  function MANTIS:_GetSAMDataFromUnits(grpname,mod,sma,chm,group)
    self:T(self.lid.."_GetSAMDataFromUnits")
    local found = false
    local range = self.checkradius
    local height = 3000
    local type = MANTIS.SamType.MEDIUM
    local radiusscale = self.radiusscale[type]
    local blind = 0
    group = group or GROUP:FindByName(grpname) -- Wrapper.Group#GROUP
    local units = group:GetUnits()
    local ARMCapacity
    -- Ordered multi-table search: the mod-tagged table (if any) first, then all
    -- others. This lets groups classify by radar TYPE NAME alone, so ground SAM
    -- groups no longer need the designation (or even the mod tag) in their name.
    local SearchTables
    if mod then
      SearchTables = { {self.SamDataHDS,"HDS"}, {self.SamData,nil}, {self.SamDataSMA,"SMA"}, {self.SamDataCH,"CHM"} }
    elseif sma then
      SearchTables = { {self.SamDataSMA,"SMA"}, {self.SamData,nil}, {self.SamDataHDS,"HDS"}, {self.SamDataCH,"CHM"} }
    elseif chm then
      SearchTables = { {self.SamDataCH,"CHM"}, {self.SamData,nil}, {self.SamDataHDS,"HDS"}, {self.SamDataSMA,"SMA"} }
    else
      SearchTables = { {self.SamData,nil}, {self.SamDataHDS,"HDS"}, {self.SamDataSMA,"SMA"}, {self.SamDataCH,"CHM"} }
    end
    self:T("Looking to auto-match for "..grpname)
    for _,_unit in pairs(units) do
      local unit = _unit -- Wrapper.Unit#UNIT
      local typename = string.lower(unit:GetTypeName())
      self:T(string.format("Matching typename: %s",typename))
      -- Longest-match wins across ALL tables. This prevents a short Radar key in
      -- one table (e.g. base "TorM2") from shadowing a more specific key in
      -- another (e.g. CH "TorM2K"), and makes the typename path deterministic
      -- (plain pairs() order no longer decides between overlapping keys).
      -- Table order (mod-tagged table first) breaks exact-length ties.
      local bestentry, bestidx, besttag, bestlen = nil, nil, nil, 0
      for _,searchentry in ipairs(SearchTables) do
        local SAMData, modtag = searchentry[1], searchentry[2]
        if SAMData then
          for idx,entry in pairs(SAMData) do
            local _radar = string.lower(entry.Radar)
            if #_radar > bestlen and string.find(typename,_radar,1,true) then
              bestentry, bestidx, besttag, bestlen = entry, idx, modtag, #_radar
            end
          end
        end
      end
      if bestentry then
        local _entry = bestentry -- #MANTIS.SamData
        type = _entry.Type
        radiusscale = self.radiusscale[type]
        range = _entry.Range * 1000 * radiusscale -- max firing range used as switch-on
        height = _entry.Height * 1000 -- max firing height
        blind = _entry.Blindspot * 100 -- blind spot range
        ARMCapacity = _entry.ARMCapacity
        self:T(string.format("Match: %s - %s",string.lower(_entry.Radar),type))
        -- Stash the jammer curve by DESIGNATION (table key), so groups named
        -- without a designation remain jammable. Reuses _ResolveJammerParams
        -- (aliases, digit-boundary matching, mod bucketing) via a synthetic name.
        self._samJammerParams = self._samJammerParams or {}
        if self._samJammerParams[grpname] == nil then
          local synth = bestidx
          if besttag and not string.find(bestidx, besttag, 1, true) then
            synth = bestidx .. " " .. besttag
          end
          local jp = self:_ResolveJammerParams(synth)
          if jp then self._samJammerParams[grpname] = jp end
        end
        found = true
        break
      end
    end
    --- AAA or Point Defense
    if not found then
      local grp = group -- Wrapper.Group#GROUP
      if (grp and grp:IsAlive() and grp:IsAAA()) or string.find(grpname,"AAA",1,true) then
        range = 2000
        height = 2000
        blind = 50
        type = MANTIS.SamType.POINT
        found = true
      end
    end
    if not found then
      self:E(self.lid .. string.format("*****Could not match radar data for %s! Will default to midrange values!",grpname))
    end
    return range, height, type, blind, ARMCapacity
  end
  
  --- [Internal] Function to get SAM firing data for naval (ship) groups.
  -- Matches the unit type name exactly against #MANTIS.SamDataNaval and, as a side
  -- effect, stashes the hull's jammer curve in self._samJammerParams[grpname] so the
  -- SOJ jammer extension can suppress it by type name (not group name).
  -- @param #MANTIS self
  -- @param #string grpname Name of the ship group
  -- @param Wrapper.Group#GROUP group (Optional) Already resolved ship group.
  -- @return #number range Max firing range (m)
  -- @return #number height Max firing height (m)
  -- @return #string type #MANTIS.SamType
  -- @return #number blind Blind spot
  -- @return #number ARMCapacity
  function MANTIS:_GetNavalSAMData(grpname,group)
    self:T(self.lid.."_GetNavalSAMData for "..tostring(grpname))
    self._navalSAMs = self._navalSAMs or {}
    self._navalSAMs[grpname] = true
    self._samJammerParams = self._samJammerParams or {}
    local range = self.checkradius
    local height = 3000
    local type = MANTIS.SamType.POINT
    local blind = 0
    local ARMCapacity = 0
    group = group or GROUP:FindByName(grpname) -- Wrapper.Group#GROUP
    if not group then
      self._samJammerParams[grpname] = nil
      return range, height, type, blind, ARMCapacity
    end
    local units = group:GetUnits() or {}
    for _,_unit in pairs(units) do
      local typename = string.lower(_unit:GetTypeName())
      for _,entry in pairs(self.SamDataNaval) do
        if typename == string.lower(entry.Radar) then
          type = entry.Type
          local radiusscale = self.radiusscale[type] or 1
          range = entry.Range * 1000 * radiusscale
          height = entry.Height * 1000
          blind = entry.Blindspot
          ARMCapacity = entry.ARMCapacity or 0
          self._samJammerParams[grpname] = self.JammerSAMParamsNaval[entry.Radar]
          self:T(string.format("Naval match: %s -> %s (range %sm)", typename, tostring(type), tostring(range)))
          return range, height, type, blind, ARMCapacity
        end
      end
    end
    -- Unmatched ship: conservative point-defence default (mirrors AAA fallback), no jammer curve.
    self._samJammerParams[grpname] = nil
    self:E(self.lid..string.format("*****Could not match naval radar data for %s! Defaulting to POINT.",grpname))
    return 2000, 2000, MANTIS.SamType.POINT, 50, 0
  end

  --- [Internal] Classify a naval group PER UNIT. Each hull matching #MANTIS.SamDataNaval
  -- becomes its own SAM-table record keyed by UNIT name, record[8] = parent group name.
  -- @param #MANTIS self
  -- @return #boolean handled True if at least one unit was classified.
  function MANTIS:_BuildNavalUnitEntries(group, grpname, SAM_Tbl, SAM_Tbl_lg, SAM_Tbl_md, SAM_Tbl_sh, SAM_Tbl_pt, SEAD_Grps)
    self:T(self.lid.."_BuildNavalUnitEntries for "..tostring(grpname))
    self._navalSAMs = self._navalSAMs or {}
    self._samJammerParams = self._samJammerParams or {}
    local entries = 0
    local seadadded = false
    local units = group:GetUnits() or {}
    for _,_unit in pairs(units) do
      if _unit and _unit:IsAlive() then
        local typename = string.lower(_unit:GetTypeName())
        for _,entry in pairs(self.SamDataNaval) do
          if typename == string.lower(entry.Radar) then
            local unitname = _unit:GetName()
            local type = entry.Type
            local radiusscale = self.radiusscale[type] or 1
            local range = entry.Range * 1000 * radiusscale
            local height = entry.Height * 1000
            local blind = entry.Blindspot
            local coord = _unit:GetCoordinate()
            local record = {unitname, coord, range, height, blind, type, nil, grpname}
            table.insert( SAM_Tbl, record )
            if type == MANTIS.SamType.LONG then table.insert( SAM_Tbl_lg, record )
            elseif type == MANTIS.SamType.MEDIUM then table.insert( SAM_Tbl_md, record )
            elseif type == MANTIS.SamType.SHORT then table.insert( SAM_Tbl_sh, record )
            elseif type == MANTIS.SamType.POINT then table.insert( SAM_Tbl_pt, record ) end
            self._navalSAMs[unitname] = true
            self._navalUnitParent = self._navalUnitParent or {}
            self._navalUnitParent[unitname] = grpname
            self._samJammerParams[unitname] = self.JammerSAMParamsNaval[entry.Radar]
            if self.SamStateTracker[unitname] == nil then self.SamStateTracker[unitname] = "GREEN" end
            if self.SEADNaval and not seadadded then
              table.insert( SEAD_Grps, grpname ) -- SEAD keys on GROUP names; add once
              seadadded = true
            end
            entries = entries + 1
            self:T(string.format("Naval per-unit match: %s (%s) -> %s",unitname,typename,tostring(type)))
            break
          end
        end
      end
    end
    return entries > 0
  end

  --- [Internal] Group ALARM-STATE arbiter for per-unit naval control.
  -- DCS reliably honors only GROUP-level alarm state on ships, so per-unit
  -- tracking decides intent and this function applies ONE alarm state per ship
  -- group as the final word of each cycle:
  --   RED   if any managed unit is RED and not jammed (threat / hit / surface
  --         wake), or the group is outside EWR radar coverage (autonomous
  --         search, see SetNavalAutonomy) with at least one unjammed unit;
  --   GREEN otherwise -- including full jamming suppression, which overrides
  --         autonomy (a fully jammed group cannot search).
  -- @param #MANTIS self
  -- @return #MANTIS self
  function MANTIS:_ApplyNavalAlarmState()
    if not (self.NavalPerUnit and self._navalUnitParent) then return self end
    local wants, seen, unjammed = {}, {}, {}
    for uname, grpname in pairs(self._navalUnitParent) do
      local u = UNIT:FindByName(uname)
      if u and u:IsAlive() then
        seen[grpname] = true
        local jammed = self._jammerEnabled and self._jammedSAMs and self._jammedSAMs[uname]
        if not jammed then unjammed[grpname] = true end
        if self.SamStateTracker[uname] == "RED" and not jammed then
          wants[grpname] = true
        end
      end
    end
    -- coverage sources: every alive EWR group (incl. EWR-role ships and AWACS ships in the EWR set)
    local sources = {}
    if self.NavalAutonomy and next(seen) then
      -- Managed naval SAM groups cannot be their own coverage: when GREEN their
      -- radars are dark, so a "BOTH"-role group must not self-license through
      -- its EWR-set membership. Only UNMANAGED emitters count as sources:
      -- land EWR, AWACS, and EWR-only ships (never state-switched, always
      -- radiating).
      local managed = {}
      for _, gname in pairs(self._navalUnitParent) do managed[gname] = true end
      self.EWR_Group:ForEachGroupAlive(
        function(grp)
          if not managed[grp:GetName()] then
            local c = grp:GetCoordinate()
            if c then table.insert(sources, c) end
          end
        end)
    end
    self._navalAutonomous = self._navalAutonomous or {}
    self._navalGroupState = self._navalGroupState or {}
    for grpname,_ in pairs(seen) do
      local grp = GROUP:FindByName(grpname)
      if grp and grp:IsAlive() then
        local red = wants[grpname] or false
        local autonomous = false
        if self.NavalAutonomy and unjammed[grpname] and not red then
          local covered = false
          local gc = grp:GetCoordinate()
          if gc then
            for _,c in ipairs(sources) do
              if c:Get2DDistance(gc) <= self.NavalAutonomyRadius then
                covered = true
                break
              end
            end
          end
          self:T(self.lid..string.format("%s EWR coverage: %s (%d unmanaged source(s), radius %dkm)",grpname,tostring(covered),#sources,self.NavalAutonomyRadius/1000))
          if not covered then
            red = true
            autonomous = true
          end
        end
        self._navalAutonomous[grpname] = autonomous or nil
        local newstate = red and "RED" or "GREEN"
        if self._navalGroupState[grpname] ~= newstate then
          self._navalGroupState[grpname] = newstate
          if red then
            grp:OptionAlarmStateRed()
            self:T(self.lid..grpname.." naval group -> alarm RED"..(autonomous and " (autonomous: no EWR coverage)" or ""))
          else
            grp:OptionAlarmStateGreen()
            self:T(self.lid..grpname.." naval group -> alarm GREEN")
          end
        end
      end
    end
    return self
  end


  --- [Internal] Function to get SAM firing data
  -- @param #MANTIS self
  -- @param #string grpname Name of the group
  -- @param Wrapper.Group#GROUP group (Optional) Already resolved group.
  -- @param #boolean isship (Optional) Already resolved ship classification.
  -- @return #number range Max firing range
  -- @return #number height Max firing height
  -- @return #string type Long, medium or short range
  -- @return #number blind "blind" spot
  function MANTIS:_GetSAMRange(grpname,group,isship)
    self:T(self.lid.."_GetSAMRange for "..tostring(grpname))
    -- Naval hulls: match by exact unit type name against SamDataNaval and stash the
    -- jammer curve; bypass the ground name-matching below.
    group = group or GROUP:FindByName(grpname) -- Wrapper.Group#GROUP
    if group and (isship == true or isship == nil and group:IsShip()) then
      return self:_GetNavalSAMData(grpname,group)
    end
    local range = self.checkradius
    local height = 3000
    local type = MANTIS.SamType.MEDIUM
    local radiusscale = self.radiusscale[type]
    local blind = 0
    local found = false
    local HDSmod = false
    local SMAMod = false
    local CHMod = false
    local ARMCapacity = 0
    if string.find(grpname,"HDS",1,true) then
      HDSmod = true
    elseif string.find(grpname,"SMA",1,true) then
      SMAMod = true
    elseif string.find(grpname,"CHM",1,true) then
      CHMod = true
    end
    --if self.automode then
      for idx,entry in pairs(self.SamData) do
        self:T2("ID = " .. idx)
        if string.find(grpname,idx,1,true) then
          local _entry = entry -- #MANTIS.SamData
          type = _entry.Type
          radiusscale = self.radiusscale[type]
          range = _entry.Range * 1000 * radiusscale -- max firing range
          height = _entry.Height * 1000 -- max firing height        
          blind = _entry.Blindspot 
          ARMCapacity = _entry.ARMCapacity or 0
          self:T("Matching Groupname = " .. grpname .. " Range= " .. range)
          found = true
          break
        end
      end
    --end
    --- Secondary - AAA or Point Defense
    if not found then
      local grp = group -- Wrapper.Group#GROUP
      if (grp and grp:IsAlive() and grp:IsAAA()) or string.find(grpname,"AAA",1,true) then
        range = 2000
        height = 2000
        blind = 50
        type = MANTIS.SamType.POINT
        found = true
      end
    end
    --- Tertiary filter if not found
    if (not found) or HDSmod or SMAMod or CHMod then
      range, height, type, blind, ARMCapacity = self:_GetSAMDataFromUnits(grpname,HDSmod,SMAMod,CHMod,group)
    elseif not found then
      self:E(self.lid .. string.format("*****Could not match radar data for %s! Will default to midrange values!",grpname))
    end
    if found and string.find(grpname,"SHORAD",1,true) then
      type = MANTIS.SamType.POINT -- force short on match
    end
    return range, height, type, blind, ARMCapacity
  end
  
  --- [Internal] Check tracking radar availability and switch off sites without a working TR.
  -- @param #MANTIS self
  -- @param Wrapper.Group#GROUP group The SAM group.
  -- @param #string grpname The group name.
  -- @param #table ammo The group's cached ammunition and tracking state.
  -- @param #string lostUnitName (Optional) Unit reported lost by the current event.
  function MANTIS:_RefreshSAMTracking(group,grpname,ammo,lostUnitName)
    if not ammo.trUnits then
      ammo.trUnits = {}
      ammo.trLost = nil
      if not self.dynamic then ammo.units = {} end
      -- The spawn composition distinguishes a lost TR from a site that never needed one.
      local template = _DATABASE:GetGroupTemplate(grpname) -- #table
      if ammo.units then ammo.template = template end
      if template then
        local trTypes = {}
        for _,unit in pairs(template.units) do
          if ammo.units then ammo.units[unit.name] = Unit.getByName(unit.name) end
          local tracking = trTypes[unit.type]
          if tracking == nil then
            tracking = Unit.getDescByName(unit.type).attributes["SAM TR"] == true
            trTypes[unit.type] = tracking
          end
          if tracking then ammo.trUnits[unit.name] = true end
        end
      else
        -- Raw DCS spawns may have no registered MOOSE template.
        for _,unit in pairs(group:GetUnits()) do
          local name = unit:GetName()
          local DCSUnit = unit:GetDCSObject() -- DCS#Unit
          if ammo.units then ammo.units[name] = DCSUnit end
          if DCSUnit:getDesc().attributes["SAM TR"] then ammo.trUnits[name] = true end
        end
      end
    end
    -- Dynamic sets invalidate through Added; static sets still need periodic repair checks.
    if self.dynamic and ammo.trLost then return end
    local trackingLost = next(ammo.trUnits) ~= nil
    for unitname in pairs(ammo.trUnits) do
      if unitname ~= lostUnitName then
        local unit = Unit.getByName(unitname) -- DCS#Unit
        if unit and unit:isExist() and unit:getLife() > 0 then
          trackingLost = false
          break
        end
      end
    end
    if trackingLost and (not ammo.trLost or self.SamStateTracker[grpname] ~= "GREEN") then
      if self.UseEmOnOff then group:EnableEmission(false) else group:OptionAlarmStateGreen() end
      if self.state2flag then ammo.advancedSleeping = true end
      if self.SamStateTracker[grpname] ~= "GREEN" then
        self.SamStateTracker[grpname] = "GREEN"
        self:__GreenState(1,group)
      end
      if self.debug or self.verbose then
        MESSAGE:New(self.lid.."SAM "..grpname.." | TR Destroyed",10,"MANTIS"):ToAllIf(self.debug):ToLog()
      end
    end
    ammo.trLost = trackingLost
  end

  --- [Internal] Refresh the ground group's ammunition and tracking state in MANTIS_AMMO.
  -- Cache fields: object is the native DCS group identity; units and template identify static-set replacements;
  -- isSAM records radar SAM classification;
  -- missiles is the latest missile count; empty requires two consecutive zero samples;
  -- canSleep enables the empty-ammo veto outside POINT; trUnits contains expected tracking radar names;
  -- trLost records loss of every required TR; advancedSleeping records a site held off in advanced state 2.
  -- @param #MANTIS self
  -- @param Wrapper.Group#GROUP group The ground group.
  -- @param #string grpname The group name.
  -- @param #boolean reset Recreate the cache for startup.
  -- @param #string samType The classified #MANTIS.SamType.
  -- @return #MANTIS self
  function MANTIS:_RefreshSAMAmmo(group,grpname,reset,samType)
    local DCSGroup = group:GetDCSObject() -- DCS#Group
    local ammo = group:GetProperty("MANTIS_AMMO") -- #table
    local replaced = false
    if not self.dynamic and not reset and ammo and ammo.trUnits and ammo.object == DCSGroup and ammo.units then
      local DCSUnit = DCSGroup:getUnit(1) -- DCS#Unit
      -- An original survivor is not a respawn, even when the first unit has died.
      replaced = (DCSUnit and ammo.units[DCSUnit:getName()] ~= DCSUnit)
        or ammo.template ~= _DATABASE:GetGroupTemplate(grpname)
    end
    if reset or not ammo or not ammo.trUnits or ammo.object ~= DCSGroup or replaced then
      local advancedSleeping = ammo and ammo.advancedSleeping
      ammo = {
        object = DCSGroup,
        isSAM = group:IsSAM(),
        advancedSleeping = advancedSleeping,
      }
      group:SetProperty("MANTIS_AMMO",ammo)
    end
    self:_RefreshSAMTracking(group,grpname,ammo)
    local missiles = select(5,group:GetAmmunition())
    -- Cache every ground group's missiles; only non-POINT radar SAMs use the sleep veto.
    ammo.canSleep = ammo.isSAM and samType ~= MANTIS.SamType.POINT
    -- Two scheduled zero samples leave one refresh cycle for the last salvo.
    ammo.empty = missiles == 0 and ammo.missiles == 0
    ammo.missiles = missiles
    if not self.state2flag then
      ammo.advancedSleeping = nil
    end
    return self
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
     local SAM_Tbl_pt = {} -- table of point defense/AAA
     local SEAD_Grps = {} -- table of SAM names to make evasive
     local engagerange = self.engagerange -- firing range in % of max
     --cycle through groups and set alarm state etc
     for _i,_group in pairs (SAM_Grps) do
      local isground = _group:IsGround()
      if (isground or _group:IsShip()) and _group:IsAlive() then
        local group = _group -- Wrapper.Group#GROUP
        -- DONE: add emissions on/off
        if (not isground) and self.NavalPerUnit then
          -- Per-unit naval control: ships are switched by GROUP ALARM STATE only,
          -- the one mechanism DCS reliably honors on naval groups. Baseline is
          -- GREEN; the alarm arbiter (_ApplyNavalAlarmState) raises the group RED
          -- on threat, hit, surface contact, or loss of EWR coverage.
          group:OptionAlarmStateGreen()
        elseif self.UseEmOnOff then
          group:OptionAlarmStateRed()
          group:EnableEmission(false)
          --group:SetAIOff()
        else
          group:OptionAlarmStateGreen() -- AI off
        end
        group:OptionEngageRange(engagerange)  --default engagement will be 95% of firing range
        local grpname = group:GetName()
        local grpcoord = group:GetCoordinate()
        if (not isground) and self.NavalPerUnit
          and self:_BuildNavalUnitEntries(group, grpname, SAM_Tbl, SAM_Tbl_lg, SAM_Tbl_md, SAM_Tbl_sh, SAM_Tbl_pt, SEAD_Grps) then
          self:T(grpname.." handled as per-unit naval group")
        else
        local grprange,grpheight,type,blind,ARMCapacity  = self:_GetSAMRange(grpname,group,not isground)
        if isground then self:_RefreshSAMAmmo(group,grpname,true,type) end
        if ARMCapacity and ARMCapacity>0 then _group:SetProperty("ARMCapacity",ARMCapacity) end
        local record = {grpname, grpcoord, grprange, grpheight, blind, type, ARMCapacity}
        table.insert( SAM_Tbl, record)
        --table.insert( SEAD_Grps, grpname )
        if type == MANTIS.SamType.LONG then
          table.insert( SAM_Tbl_lg, record)
          if (isground) or self.SEADNaval then
            table.insert( SEAD_Grps, grpname )
          end
          self:T("SAM "..grpname.." is type LONG")
        elseif type == MANTIS.SamType.MEDIUM then
         table.insert( SAM_Tbl_md, record)
         if (isground) or self.SEADNaval then
           table.insert( SEAD_Grps, grpname )
         end
         self:T("SAM "..grpname.." is type MEDIUM")
        elseif type == MANTIS.SamType.SHORT then
          table.insert( SAM_Tbl_sh, record)
          if (isground) or self.SEADNaval then
            table.insert( SEAD_Grps, grpname )
          end
          self:T("SAM "..grpname.." is type SHORT")
        elseif type == MANTIS.SamType.POINT then
          table.insert( SAM_Tbl_pt, record)
          self:T("SAM "..grpname.." is type POINT")
          if (not isground) then
            if self.SEADNaval then
              table.insert( SEAD_Grps, grpname ) -- naval point-defence -> SEAD only when opted in; never SHORAD scoot
            end
          else
            self.ShoradGroupSet:Add(grpname,group)
            if not self.autoshorad then
              table.insert( SEAD_Grps, grpname )
            end
          end
        end
        end -- else: per-unit naval group handled above
        self.SamStateTracker[grpname] = "GREEN"
        end
     end
     self.SAM_Table = SAM_Tbl
     self.SAM_Table_Long = SAM_Tbl_lg
     self.SAM_Table_Medium = SAM_Tbl_md
     self.SAM_Table_Short = SAM_Tbl_sh
     self.SAM_Table_PointDef = SAM_Tbl_pt
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
     local SAM_Tbl_sh = {} -- table of short range SAM defense zones
     local SAM_Tbl_pt = {} -- table of point defense/AAA
     local SEAD_Grps = {} -- table of SAM names to make evasive
     local engagerange = self.engagerange -- firing range in % of max
     --cycle through groups and set alarm state etc
     for _i,_group in pairs (SAM_Grps) do
        local group = _group -- Wrapper.Group#GROUP
        group:OptionEngageRange(engagerange)  --engagement will be 95% of firing range
        local isground = group:IsGround()
        if (isground or group:IsShip()) and group:IsAlive() then
          local grpname = group:GetName()
          local grpcoord = group:GetCoord()
          if grpcoord then grpcoord.Heading = group:GetHeading() or 0 end
          if (not isground) and self.NavalPerUnit
            and self:_BuildNavalUnitEntries(group, grpname, SAM_Tbl, SAM_Tbl_lg, SAM_Tbl_md, SAM_Tbl_sh, SAM_Tbl_pt, SEAD_Grps) then
            self:T(grpname.." handled as per-unit naval group")
          else
          local grprange, grpheight,type,blind, ARMCapacity  = self:_GetSAMRange(grpname,group,not isground)
          if isground then self:_RefreshSAMAmmo(group,grpname,false,type) end
          -- TODO the below might stop working at some point after some hours, needs testing
          --local radaralive = group:IsSAM()
          if ARMCapacity and ARMCapacity>0 then _group:SetProperty("ARMCapacity",ARMCapacity) end
          local radaralive = true
          local record = {grpname, grpcoord, grprange, grpheight, blind, type, ARMCapacity}
          table.insert( SAM_Tbl, record) -- make the table lighter, as I don't really use the zone here
          if type ~= MANTIS.SamType.POINT and ((isground) or self.SEADNaval) then
            table.insert( SEAD_Grps, grpname )
          end
          if type == MANTIS.SamType.LONG and radaralive then
            table.insert( SAM_Tbl_lg, record)
            self:T({grpname,grprange, grpheight})
          elseif type == MANTIS.SamType.MEDIUM and radaralive then
           table.insert( SAM_Tbl_md, record)
           self:T({grpname,grprange, grpheight})
          elseif type == MANTIS.SamType.SHORT and radaralive then
           table.insert( SAM_Tbl_sh, record)
           self:T({grpname,grprange, grpheight})
          elseif type == MANTIS.SamType.POINT or (not radaralive) then
            table.insert( SAM_Tbl_pt, record)
            self:T({grpname,grprange, grpheight})
            if (not isground) then
              if self.SEADNaval then
                table.insert( SEAD_Grps, grpname ) -- naval point-defence -> SEAD only when opted in; never SHORAD scoot
              end
            else
              self.ShoradGroupSet:Add(grpname,group)
              if self.autoshorad then
                self.Shorad.Groupset = self.ShoradGroupSet
              end
            end
          end
          end -- else: per-unit naval group handled above
        end
     end
     self.SAM_Table = SAM_Tbl
     self.SAM_Table_Long = SAM_Tbl_lg
     self.SAM_Table_Medium = SAM_Tbl_md
     self.SAM_Table_Short = SAM_Tbl_sh
     self.SAM_Table_PointDef = SAM_Tbl_pt
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
  
   --- [Internal] Function to smoke a group in decoy.
  -- @param #MANTIS self
  -- @param Wrapper.Group#GROUP Group
  -- @return #MANTIS self
  function MANTIS:_SmokeUnits(Group)
    self:T("Smoking")
    local LastSmoketime=Group:GetProperty("MANTIS_LASTSMOKE_TIME") or 0
    local TNow = timer.getTime()
    if TNow - LastSmoketime > 290 then -- Smoking lasts 5 minutes
      Group:SetProperty("MANTIS_LASTSMOKE_TIME",TNow)
      local units = Group:GetUnits() or {}
      local smoke = self.SmokeDecoyColor or SMOKECOLOR.White
      for _,unit in pairs(units) do
        if unit and unit:IsAlive() then
          unit:GetCoordinate():Smoke(smoke)
        end
      end
    end
    return self
  end

-----------------------------------------------------------------------
-- MANTIS main functions
-----------------------------------------------------------------------

--- [Internal] Check if a system can and should defend for HARMs itself
-- @param #MANTIS self
-- @param Wrapper.Group#GROUP targetGroup
-- @param #string targetName
-- @param Wrapper.Group#GROUP attackerGroup
-- @param #string weaponName
-- @param Wrapper.Weapon#WEAPON weaponWrapper
-- @param #number tti
-- @param #number delay
-- @return #boolean Outcome
function MANTIS:SeadAllowSuppression(targetGroup, targetName, attackerGroup, weaponName, weaponWrapper, tti, delay)
  self:T(self.lid.."SeadAllowSuppression")
  
  --- Thanks to @Goon Jan 2026
  ----------------------------------------------------------------
  -- LOG INCOMING REQUEST
  ----------------------------------------------------------------
  self:T(string.format("MANTIS:SeadAllowSuppression REQUEST | target=%s | weapon=%s | tti=%s | delay=%s",tostring(targetName),
    tostring(weaponName),tostring(tti),tostring(delay)))

  ----------------------------------------------------------------
  -- JAMMER CHECK: if SAM is currently jammed, deny SEAD suppression.
  -- The jammer is already keeping the SAM off. SEAD suppression would
  -- cause SuppressionStop to briefly re-enable the radar and relocate
  -- the SAM (potentially out of jammer range). Let the jammer handle it.
  ----------------------------------------------------------------
  if self._jammerEnabled and self._jammedSAMs and self._jammedSAMs[targetName] then
    self:T(string.format("MANTIS:SeadAllowSuppression DECISION -> DENIED (JAMMED %.0f%%) | target=%s",
      self._jammedSAMs[targetName] * 100, tostring(targetName)))
    return false
  end

  ----------------------------------------------------------------
  -- LOOK UP ARM CAPACITY FOR THIS SAM
  ----------------------------------------------------------------
  local armcap = targetGroup:GetProperty("ARMCapacity")
  
  if not armcap then
    for _, sam in pairs(self.SAM_Table or {}) do
      if sam[1] == targetName then
        armcap = sam[7] -- ARMCapacity
        break
      end
    end
  end

  self:T(string.format("MANTIS:SeadAllowSuppression SAM DATA | target=%s | ARMCapacity=%s",tostring(targetName),armcap and tostring(armcap) or "nil"))

  ----------------------------------------------------------------
  -- TRACK SEAD THREATS (PER TARGET)
  ----------------------------------------------------------------
  local THREAT_WINDOW = 0.1  -- seconds 
  
  self.LastThreatEval = self.LastThreatEval or {}
  self.InboundARMs    = self.InboundARMs or {}
  
  local now = timer.getTime()
  local last = self.LastThreatEval[targetName] or 0
  
  if (now - last) >= THREAT_WINDOW then
    self.InboundARMs[targetName] = (self.InboundARMs[targetName] or 0) + 1
    self.LastThreatEval[targetName] = now
    self:T(string.format("MANTIS:SeadAllowSuppression NEW threat accepted | Δt=%.3f",now - last))
  else
    self:T(string.format("MANTIS:SeadAllowSuppression duplicate evaluation ignored | Δt=%.3f",now - last))
  end

  local inbound = self.InboundARMs[targetName] or 0

  self:T(string.format("MANTIS:SeadAllowSuppression THREAT COUNT | target=%s | inboundThreats=%d",tostring(targetName),inbound))

  ----------------------------------------------------------------
  -- DECISION GATE
  ----------------------------------------------------------------
  
  -- No missiles left over → legacy behavior
  if targetGroup and targetGroup:IsAlive() then
    local AmmoM = select(5,targetGroup:GetAmmunition())
    -- TODO Check C-RAM probably needs an exception as it is a gun, need to check its effectiveness
    if AmmoM and AmmoM == 0 then
      self:T(string.format("MANTIS:SeadAllowSuppression DECISION -> APPROVED (no MISSILES) | target=%s",tostring(targetName)))
      return true
    end
  end
  
  -- No ARM capacity defined → legacy behavior
  if (not armcap) or armcap == 0 then
    self:T(string.format("MANTIS:SeadAllowSuppression DECISION -> APPROVED (no ARMCAP) | target=%s",tostring(targetName)))
    return true
  end

  -- Suppress only once enough threats accumulated
  if inbound >= armcap then
    self:T(string.format("MANTIS:SeadAllowSuppression DECISION -> APPROVED (inbound %d >= cap %d) | target=%s",inbound,armcap,tostring(targetName)))
    return true
  end

  self:T(string.format("MANTIS:SeadAllowSuppression DECISION -> DENIED (inbound %d < cap %d) | target=%s",inbound,armcap,tostring(targetName)))

  return false

  end
  
  --- [Internal] Check detection function
  -- @param #MANTIS self
  -- @param #table samset Table of SAM data
  -- @param #table detset Table of COORDINATES
  -- @param #boolean dlink Using DLINK
  -- @param #number limit of SAM sites to go active on a contact
  -- @param #table contactSnapshot Contact facts captured once for the current check.
  -- @param #table zoneResults (Optional) Coordinate-zone results shared only within the current check.
  -- @return #number instatusred
  -- @return #number instatusgreen
  -- @return #number activeshorads
  function MANTIS:_CheckLoop(samset,detset,dlink,limit,contactSnapshot,zoneResults)
    self:T(self.lid .. "CheckLoop " .. #detset .. " Coordinates")
    local switchedon = 0
    local instatusred = 0
    local instatusgreen = 0
    local activeshorads = 0
    local SEADactive = 0
    for _,_data in pairs (samset) do
      local samcoordinate = _data[2]
      local name = _data[1]
      local navalparent = _data[8] -- per-unit naval entry: name is a UNIT name
      local radius = _data[3]
      local height = _data[4]
      local blind = _data[5] * 1.25 + 1
      local shortsam = (_data[6] ~= MANTIS.SamType.LONG) and true or false
      if not shortsam then
        shortsam = (_data[6] == MANTIS.SamType.POINT) and true or false
      end
      local samunit = nil
      local samgroup = nil
      if navalparent then
        samunit = UNIT:FindByName(name)
        samgroup = (samunit and samunit:GetGroup()) or GROUP:FindByName(navalparent)
      else
        samgroup = GROUP:FindByName(name)
      end
      local samalive = false
      if navalparent then samalive = (samunit ~= nil) and samunit:IsAlive() or false
      elseif samgroup then samalive = samgroup:IsAlive() or false end
      local ammo = samalive and samgroup:GetProperty("MANTIS_AMMO") -- #table
      local IsInZone, Distance, CloseThreat = false, 0, false
      if samalive and not (ammo and (ammo.trLost or ammo.canSleep and ammo.empty)) then
        IsInZone, Distance, CloseThreat = self:_CheckObjectInZone(detset, samcoordinate, radius, height, dlink, contactSnapshot, not shortsam and limit > 0 and switchedon >= limit and radius * 0.5 or nil, zoneResults)
      end
      -- Naval surface wake-up: quiet ships activate when enemy surface combatants
      -- close within the trigger radius. Jamming has precedence and holds them down.
      if samalive and (not IsInZone) and self.NavalSurfaceWakeup and self._navalSAMs and self._navalSAMs[name]
        and not (self._jammerEnabled and self._jammedSAMs and self._jammedSAMs[name]) then
        local wakeradius = self.NavalSurfaceWakeupRadius or radius
        if self:_EnemySurfaceInRange(samcoordinate, wakeradius) then
          IsInZone = true
          Distance = wakeradius -- keep distance-based proximity behaviors (smoke, SHORAD link) inert
        end
      end
      local suppressed = self.SuppressedGroups[name] or (navalparent and self.SuppressedGroups[navalparent]) or false
      local activeshorad = false
      if self.Shorad and self.Shorad.ActiveGroups and self.Shorad.ActiveGroups[name] then
       activeshorad = true
      end
      if samgroup:GetProperty("SHORAD_ACTIVE") == true and activeshorad == false then activeshorad = true end
      -- Close long-range threats may exceed the active limit.
      local canSwitch = switchedon < limit or CloseThreat
      if IsInZone and (shortsam or canSwitch) and (not suppressed) and (not activeshorad) then --check any target in zone and not currently managed by SEAD
        if samalive then
          -- switch on SAM
          local switch = false
          if navalparent and canSwitch then
            -- per-unit naval: mark THIS unit RED; the group alarm arbiter
            -- (_ApplyNavalAlarmState) applies the group switch at cycle end
            switchedon = switchedon + 1
            switch = true
          elseif self.UseEmOnOff and canSwitch then
            -- DONE: add emissions on/off
            samgroup:EnableEmission(true)
            switchedon = switchedon + 1
            switch = true
          elseif (not self.UseEmOnOff) and canSwitch then
            samgroup:OptionAlarmStateRed()
            switchedon = switchedon + 1
            switch = true           
          end
          if self.SamStateTracker[name] ~= "RED" and switch then
            self.SamStateTracker[name] = "RED"
            self:__RedState(1,samgroup)
          end
          -- DONE Restrict on Distance
          if shortsam == true and (not navalparent) and self.SmokeDecoy == true and Distance < self.DetectAccousticRadius*1.5 then 
            self:T("Smoking")
            self:_SmokeUnits(samgroup)
          end
          -- link in to SHORAD if available
          -- DONE: Test integration fully
          if self.ShoradLink and (not navalparent) and (Distance < self.ShoradActDistance or Distance < blind ) then -- don't give SHORAD position away too early; ships never SHORAD-link
            local Shorad = self.Shorad  --Functional.Shorad#SHORAD
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
        if samalive and not suppressed and not activeshorad then
          -- switch off SAM
          if navalparent then
            -- per-unit naval: tracker-only; group alarm state applied by the arbiter
          elseif self.UseEmOnOff  then
            samgroup:EnableEmission(false)
          else
            samgroup:OptionAlarmStateGreen()
          end
          if self.SamStateTracker[name] ~= "GREEN" then
            self.SamStateTracker[name] = "GREEN"
            self:__GreenState(1,samgroup)
          end
          if self.debug or self.verbose then
            local text = string.format("SAM %s in alarm state GREEN!", name)
            --local m=MESSAGE:New(text,10,"MANTIS"):ToAllIf(self.debug)
            if self.verbose then self:I(self.lid..text) end
          end
        end --end alive
      end --end check     
    end --for loop
    --[[
    if self.debug or self.verbose or self.logsamstatus then
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
    self:T(self.lid..string.format("SAM State Count: GREEN %d | RED %d | SHORAD %d",instatusred, instatusgreen, activeshorads))
    --]]
    return instatusred, instatusgreen, activeshorads
  end
  
  --- [Internal] Check detection function
  -- @param #MANTIS self
  -- @param Functional.Detection#DETECTION_AREAS detection Detection object
  -- @param #boolean dlink
  -- @param #boolean reporttolog
  -- @return #MANTIS self
  function MANTIS:_Check(detection,dlink,reporttolog)
    self:T(self.lid .. "Check")
    --get detected set
    local detset = detection:GetDetectedItemCoordinates()
    --self:T("Check:", {detset})
    local contactSnapshot = nil
    local zoneResults = self.usezones and {} or nil
    if dlink then
      contactSnapshot = {}
      for _,contact in pairs(detection:GetContactTable()) do
        local grp = contact.group -- Wrapper.Group#GROUP
        if grp:IsAlive() then
          local category = grp:GetCategory()
          local side = grp:GetCoalition()
          if self.debug or (category ~= Group.Category.GROUND and category ~= Group.Category.SHIP and side ~= self.coalition) then
            local coord = grp:GetCoord()
            contactSnapshot[#contactSnapshot + 1] = {
              group = grp,
              coordinate = coord,
              height = grp:GetHeight(true),
              coalition = side,
              isGround = category == Group.Category.GROUND,
              isShip = category == Group.Category.SHIP,
              isHelicopter = category == Group.Category.HELICOPTER,
            }
          end
        end
      end
    end
    local instatusred = 0
    local instatusgreen = 0
    local activeshorads = 0
    -- switch SAMs on/off if (n)one of the detected groups is inside their reach
    if self.automode then
      local samset = self.SAM_Table_Long -- table of i.1=names, i.2=coordinates, i.3=firing range, i.4=firing height
      local instatusredl, instatusgreenl, activeshoradsl = self:_CheckLoop(samset,detset,dlink,self.maxlongrange,contactSnapshot,zoneResults)
      local samset = self.SAM_Table_Medium -- table of i.1=names, i.2=coordinates, i.3=firing range, i.4=firing height
      local instatusredm, instatusgreenm, activeshoradsm = self:_CheckLoop(samset,detset,dlink,self.maxmidrange,contactSnapshot,zoneResults)
      local samset = self.SAM_Table_Short -- table of i.1=names, i.2=coordinates, i.3=firing range, i.4=firing height
      local instatusreds, instatusgreens, activeshoradss = self:_CheckLoop(samset,detset,dlink,self.maxshortrange,contactSnapshot,zoneResults)
      local samset = self.SAM_Table_PointDef -- table of i.1=names, i.2=coordinates, i.3=firing range, i.4=firing height
      local instatusred, instatusgreen, activeshorads = self:_CheckLoop(samset,detset,dlink,self.maxpointdefrange,contactSnapshot,zoneResults)
    else
      local samset = self:_GetSAMTable() -- table of i.1=names, i.2=coordinates, i.3=firing range, i.4=firing height
      local instatusred, instatusgreen, activeshorads = self:_CheckLoop(samset,detset,dlink,self.maxclassic,contactSnapshot,zoneResults)
    end
    
    local function GetReport()
      
      if self.debug or self.verbose or self.logsamstatus then
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
      
      local statusreport = REPORT:New("\nMANTIS Status "..self.name)
      statusreport:Add("+-----------------------------+")
      statusreport:Add(string.format("+ SAM in RED State: %2d",instatusred))
      statusreport:Add(string.format("+ SAM in GREEN State: %2d",instatusgreen))
      if self.Shorad then
       statusreport:Add(string.format("+ SHORAD active: %2d",activeshorads))  
      end
      statusreport:Add("+-----------------------------+")
      return statusreport
    end
    
    -- apply naval group alarm states as the final word of this cycle
    self:_ApplyNavalAlarmState()

    if self.debug or self.verbose then
      local statusreport = GetReport()
      MESSAGE:New(statusreport:Text(),10):ToAll():ToLog()
    elseif reporttolog == true then
      local statusreport = GetReport()
      MESSAGE:New(statusreport:Text(),10):ToLog()
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
    -- Reuse the scheduled ammo refresh cadence for the existing fail-open policy.
    if newstate ~= oldstate or (newstate == 2 and self.checkcounter%3 == 1) then
      -- deal with new state
      if newstate ~= oldstate then
        self:__AdvStateChange(1,oldstate,newstate,interval)
      end
      if newstate == 2 then
        -- switch alarm state RED
        self.state2flag = true
        local samset = self:_GetSAMTable() -- table of i.1=names, i.2=coordinates
        for _,_data in pairs (samset) do
          local name = _data[1]
          local navalparent = _data[8] -- per-unit naval entry: name is a UNIT name
          local samunit = nil
          local samgroup = nil
          if navalparent then
            samunit = UNIT:FindByName(name)
            samgroup = (samunit and samunit:GetGroup()) or GROUP:FindByName(navalparent)
          else
            samgroup = GROUP:FindByName(name)
          end
          local samalive = false
          if navalparent then samalive = (samunit ~= nil) and samunit:IsAlive() or false
          elseif samgroup then samalive = samgroup:IsAlive() or false end
          if samalive then
            local ammo = samgroup:GetProperty("MANTIS_AMMO") -- #table
            if newstate ~= oldstate or (ammo and (ammo.trLost or ammo.advancedSleeping or ammo.canSleep and ammo.empty)) then
              if not (ammo and (ammo.trLost or ammo.canSleep and ammo.empty)) then
                if not (ammo and ammo.advancedSleeping and (self.SuppressedGroups[name]
                  or (self._jammerEnabled and self._jammedSAMs and self._jammedSAMs[name]))) then
                  if navalparent then
                    self.SamStateTracker[name] = "RED" -- arbiter raises the group
                  elseif self.UseEmOnOff then
                    -- DONE: add emissions on/off
                    --samgroup:SetAIOn()
                    samgroup:EnableEmission(true)
                  else
                    samgroup:OptionAlarmStateRed()
                  end
                  if ammo and ammo.advancedSleeping then
                    ammo.advancedSleeping = nil
                    if self.SamStateTracker[name] ~= "RED" then
                      self.SamStateTracker[name] = "RED"
                      self:__RedState(1,samgroup)
                    end
                  end
                end
              elseif not ammo.advancedSleeping then
                if self.UseEmOnOff then samgroup:EnableEmission(false) else samgroup:OptionAlarmStateGreen() end
                ammo.advancedSleeping = true
                if self.SamStateTracker[name] ~= "GREEN" then
                  self.SamStateTracker[name] = "GREEN"
                  self:__GreenState(1,samgroup)
                end
              end
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

    if self.autoshorad then
      self.Shorad = SHORAD:New(self.name.."-SHORAD","SHORAD",self.SAM_Group,self.ShoradActDistance,self.ShoradTime,self.Coalition,self.UseEmOnOff,self.SmokeDecoy,self.SmokeDecoyColor)
      self.Shorad:SetDefenseLimits(80,95)
      self.ShoradLink = true
      self.Shorad.Groupset=self.ShoradGroupSet
      self.Shorad.debug = self.debug
      self.Shorad:AddCallBack(self)
    end
    if self.shootandscoot and self.SkateZones and self.Shorad then
      self.Shorad:AddScootZones(self.SkateZones,self.SkateNumber or 3,self.ScootRandom,self.ScootFormation)
    end
    
    self:HandleEvent(EVENTS.Hit,self._EventHandler)
    self:HandleEvent(EVENTS.UnitLost,self._EventHandler)
    
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
    -- update SAM Table evey 3 runs
    if self.checkcounter%3 == 0 then
      self:_RefreshSAMTable()
    end
    self.checkcounter = self.checkcounter + 1
    -- check detection
    if not self.state2flag then
      self:_Check(self.Detection,self.DLink,self.logsamstatus)
    end
  
    local EWRAlive = self:_CheckAnyEWRAlive()
    
    local function FindSAMSRTR()
      local selected = nil -- Wrapper.Group#GROUP
      local eligible = 0
      for _,randomsam in pairs(self.SAM_Group:GetSet()) do
        if randomsam and randomsam:IsAlive() then
          local ammo = randomsam:GetProperty("MANTIS_AMMO") -- #table
          if not (ammo and (ammo.trLost or ammo.canSleep and ammo.empty)) and (ammo and ammo.isSAM or not ammo and randomsam:IsSAM()) then
            eligible = eligible + 1
            if math.random(eligible) == 1 then selected = randomsam end
          end
        end
      end
      return selected
    end
    
    -- Switch on a random SR/TR if no EWR left over
    if not EWRAlive then
      local randomsam = FindSAMSRTR() -- Wrapper.Group#GROUP
      if randomsam and randomsam:IsAlive() then
        if self.UseEmOnOff then
          randomsam:EnableEmission(true)
        else
          randomsam:OptionAlarmStateRed()
        end
        local name = randomsam:GetName()
        if self.SamStateTracker[name] ~= "RED" then
          self:__RedState(1,randomsam)
          self.SamStateTracker[name] = "RED"
        end
      end
    end
    
    -- relocate HQ and EWR
    if self.autorelocate then
      local relointerval = self.relointerval
      local thistime = timer.getAbsTime()
      local timepassed = thistime - self.TimeStamp

      local halfintv = math.floor(timepassed / relointerval)

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
        self:I(string.format("Site %s | Status %s",_name,_state))
      end
    end
    local interval = self.detectinterval * -1
    self:__Status(interval)
    return self
  end

  --- [Internal] Function to stop MANTIS and its INTEL detectors.
  -- @param #MANTIS self
  -- @param #string From The From State
  -- @param #string Event The Event
  -- @param #string To The To State
  -- @return #MANTIS self
  function MANTIS:onafterStop(From, Event, To)
    self:T({From, Event, To})
    if self.intelset then
      for _,_intel in pairs(self.intelset) do
        _intel:Stop()
      end
    end
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
      Shorad:WakeUpShorad(Name, radius, ontime, nil, true)
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
    self.InboundARMs[Name] = 0
    local ammo = Group:GetProperty("MANTIS_AMMO") -- #table
    if ammo and (ammo.trLost or ammo.canSleep and ammo.empty) and Group:IsAlive() then
      if self.UseEmOnOff then Group:EnableEmission(false) else Group:OptionAlarmStateGreen() end
      if self.SamStateTracker[Name] ~= "GREEN" then
        self.SamStateTracker[Name] = "GREEN"
        self:__GreenState(1,Group)
      end
    end
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
  
-----------------------------------------------------------------------
-- MANTIS Jammer Extension v2.0.0 - Functions
-----------------------------------------------------------------------

  --- Add client jammer aircraft support. Call BEFORE :Start().
  -- @param #MANTIS self
  -- @param Core.Set#SET_GROUP clientSet SET_GROUP of client jammer aircraft, or a prefix string
  -- @param #string defaultLoadout Default loadout key (default "1xALQ99_2xALQ249")
  -- @return #MANTIS self
  function MANTIS:AddJammer(clientSet, defaultLoadout)
    self:T(self.lid .. "AddJammer")
    self._jammerEnabled = true
    -- Allow string prefix shorthand
    if type(clientSet) == "string" then
      clientSet = SET_GROUP:New():FilterPrefixes(clientSet):FilterActive(true):FilterStart()
    end
    self._jammerClientSet = clientSet
    self._jammerDefaultLoadout = defaultLoadout or "1xALQ99_2xALQ249"
    self._jammerAircraft = self._jammerAircraft or {}
    self._jammerAISets = self._jammerAISets or {}
    self._jammerSnapshot = self._jammerSnapshot or {}
    self._jammedSAMs = self._jammedSAMs or {}
    self._jammerMenusBuilt = self._jammerMenusBuilt or {}
    if not self._jammerHasTransitions then
      self:AddTransition("*", "JammerSuppression", "*")
      self:AddTransition("*", "JammerActivated",   "*")
      self:AddTransition("*", "JammerDeactivated", "*")
      self._jammerHasTransitions = true
    end
    -- Start fast client menu scheduler (5s interval) so menus appear quickly
    -- instead of waiting for the next MANTIS Status cycle (~30s)
    if not self._jammerMenuScheduler then
      self._jammerMenuScheduler = SCHEDULER:New(nil, function()
        if not self._jammerEnabled then return end
        if self._jammerClientSet then
          self:_IterateJammerSet(self._jammerClientSet, function(unit, group)
            local unitName = unit:GetName()
            if not self._jammerAircraft[unitName] then
              self._jammerAircraft[unitName] = {
                loadout    = self._jammerDefaultLoadout,
                active     = false,
                isClient   = unit:IsPlayer(),
                hasLoadout = false,
              }
            elseif not self._jammerAircraft[unitName].isClient and unit:IsPlayer() then
              self._jammerAircraft[unitName].isClient = true
            end
            if self._jammerAircraft[unitName].isClient and not self._jammerMenusBuilt[unitName] then
              self:_SetupJammerMenu(unit, group)
            end
          end)
        end
      end, {}, 2, 5)  -- start in 2s, repeat every 5s
    end
    self:I(string.format("%sJammer configured | default=%s", self.lid, self._jammerDefaultLoadout))
    return self
  end

  --- Add AI jammer aircraft. Call BEFORE :Start(). Can be called multiple times.
  -- AI jammers start OFF; use SetJammerActive(unitName, true) to activate via script.
  -- @param #MANTIS self
  -- @param Core.Set#SET_GROUP aiSet SET_GROUP or prefix string for AI jammer aircraft
  -- @param #string loadout Loadout key for these AI aircraft (default "1xALQ99_2xALQ249")
  -- @return #MANTIS self
  function MANTIS:AddJammerAI(aiSet, loadout)
    self:T(self.lid .. "AddJammerAI")
    self._jammerEnabled = true
    self._jammerAircraft = self._jammerAircraft or {}
    self._jammerAISets = self._jammerAISets or {}
    self._jammerSnapshot = self._jammerSnapshot or {}
    self._jammedSAMs = self._jammedSAMs or {}
    self._jammerMenusBuilt = self._jammerMenusBuilt or {}
    local actualSet = aiSet
    if type(aiSet) == "string" then
      actualSet = SET_GROUP:New():FilterPrefixes(aiSet):FilterActive(true):FilterStart()
    end
    table.insert(self._jammerAISets, { set = actualSet, loadout = loadout or "1xALQ99_2xALQ249" })
    if not self._jammerHasTransitions then
      self:AddTransition("*", "JammerSuppression", "*")
      self:AddTransition("*", "JammerActivated",   "*")
      self:AddTransition("*", "JammerDeactivated", "*")
      self._jammerHasTransitions = true
    end
    self:I(string.format("%sJammer AI configured | loadout=%s", self.lid, loadout or "1xALQ99_2xALQ249"))
    return self
  end

  --- [Internal] Core jamming probability curve (v9 / v8.1 engine).
  -- Features: decoupled bt_mod/range_mod, tapering residual floor, ±10% jitter.
  -- @param #MANTIS self
  -- @param #number d Distance in nautical miles
  -- @param #table params {peak, mu, sigma_L, tail_dist, band, floor}
  -- @param #string loadoutKey Key into JammerLoadouts
  -- @return #number Jamming probability as fraction (0.0-0.95)
  function MANTIS:_JamGaussianExp(d, params, loadoutKey)
    if d < 0 or d > 200 then return 0 end
    if not params then return 0 end
    local cfg = self.JammerLoadouts[loadoutKey]
    if not cfg then return 0 end
    local peak, mu, sigma_L, tail_dist, band = params.peak, params.mu, params.sigma_L, params.tail_dist, params.band
    local floor = params.floor or 0
    local bm
    if     band == "LOW" then bm = cfg.mult_LOW
    elseif band == "S"   then bm = cfg.mult_S
    elseif band == "IJ"  then bm = cfg.mult_IJ
    else                      bm = cfg.mult_OPT end
    -- Decoupled window modifiers
    local eff_sigma_L   = sigma_L   / cfg.bt_mod
    local eff_tail_dist = tail_dist * cfg.range_mod
    local eff_peak = math.min(95, peak * bm)
    local raw
    if d < mu then
      raw = eff_peak * math.exp(-0.5 * ((d - mu) / eff_sigma_L) ^ 2)
    else
      local lambda = math.log(100.0) / eff_tail_dist
      raw = eff_peak * math.exp(-lambda * (d - mu))
    end
    -- Tapering residual floor (v9): floor full inside engagement band (d <= mu),
    -- attenuates with R^2-like falloff past mu over 2.5x the main decay distance.
    -- Prevents artificial hard cliff at 200nm cap; matches real radar/jammer physics.
    local eff_floor = floor * bm
    if eff_floor > 0 and d > mu then
      local floorLambda = math.log(100.0) / (eff_tail_dist * 2.5)
      eff_floor = eff_floor * math.exp(-floorLambda * (d - mu))
    end
    raw = math.max(eff_floor, raw)
    -- Stochastic jitter ±10% applied AFTER floor (v9), so residual also varies.
    -- Prevents gameable flat long-range value. Reflects S/N, RCS, atmospheric fluctuation.
    local jitter = 1.0 + (math.random() * 2 - 1) * (self.JammerJitterPercent or 0.10)
    raw = raw * jitter
    return math.max(0, math.min(95, raw)) / 100.0
  end

  --- [Internal] Build cached sorted key lists for the resolver.
  -- Called once on first use. Avoids re-scanning/re-sorting JammerSAMParams every cycle.
  -- @param #MANTIS self
  -- @return #MANTIS self
  function MANTIS:_BuildJammerKeyCache()
    self._jammerSortedHDS = {}
    self._jammerSortedSMA = {}
    self._jammerSortedCHM = {}
    self._jammerSortedBase = {}
    for key, _ in pairs(self.JammerSAMParams) do
      if     string.find(key, "HDS", 1, true) then table.insert(self._jammerSortedHDS, key)
      elseif string.find(key, "SMA", 1, true) then table.insert(self._jammerSortedSMA, key)
      elseif string.find(key, "CHM", 1, true) then table.insert(self._jammerSortedCHM, key)
      else                                          table.insert(self._jammerSortedBase, key) end
    end
    local byLenDesc = function(a, b) return #a > #b end
    table.sort(self._jammerSortedHDS,  byLenDesc)
    table.sort(self._jammerSortedSMA,  byLenDesc)
    table.sort(self._jammerSortedCHM,  byLenDesc)
    table.sort(self._jammerSortedBase, byLenDesc)
    self._jammerResolverCache = {}
    return self
  end

  --- [Internal] Resolve a SAM group name to its jammer parameters.
  -- Uses cached sorted key lists and per-name memoization for performance.
  -- Substring matching with digit-boundary protection prevents false matches
  -- (e.g. "SA-22 Pantsir" no longer matches "SA-2").
  -- @param #MANTIS self
  -- @param #string grpname The SAM group name
  -- @return #table params or nil
  function MANTIS:_ResolveJammerParams(grpname)
    if not grpname then return nil end
    -- Lazy-build cache on first use
    if not self._jammerSortedBase then self:_BuildJammerKeyCache() end
    -- Memoization: same group name resolves to same params (params don't change at runtime)
    local cached = self._jammerResolverCache[grpname]
    if cached ~= nil then
      if cached == false then return nil end  -- false sentinel = "no match"
      return cached
    end
    -- Helper: check key match with digit-boundary protection
    local function safeMatch(name, key)
      local startPos, endPos = string.find(name, key, 1, true)
      if not startPos then return false end
      local nextChar = string.sub(name, endPos + 1, endPos + 1)
      if nextChar == "" then return true end
      if string.match(nextChar, "%d") then return false end
      return true
    end
    -- Detect mod type and select pre-sorted key list
    local keyList
    if     string.find(grpname, "HDS", 1, true) then keyList = self._jammerSortedHDS
    elseif string.find(grpname, "SMA", 1, true) then keyList = self._jammerSortedSMA
    elseif string.find(grpname, "CHM", 1, true) then keyList = self._jammerSortedCHM end
    -- First pass: mod-specific keys
    if keyList then
      for i = 1, #keyList do
        if safeMatch(grpname, keyList[i]) then
          local params = self.JammerSAMParams[keyList[i]]
          self._jammerResolverCache[grpname] = params
          return params
        end
      end
    end
    -- Second pass: base keys
    local baseKeys = self._jammerSortedBase
    for i = 1, #baseKeys do
      if safeMatch(grpname, baseKeys[i]) then
        local params = self.JammerSAMParams[baseKeys[i]]
        self._jammerResolverCache[grpname] = params
        return params
      end
    end
    self._jammerResolverCache[grpname] = false  -- cache "no match" too
    return nil
  end

  --- [Internal] Count table entries
  function MANTIS:_CountTable(t)
    local c = 0
    for _ in pairs(t) do c = c + 1 end
    return c
  end

  --- [Internal] Iterate any supported SET type, calling fn(unit, group) for each alive unit.
  -- Supports SET_GROUP (via ForEachGroupAlive) and SET_CLIENT/SET_PLAYER (via ForEachClient).
  -- Note: callback receives ALL alive units — caller must check InAir() for snapshot logic.
  -- Menu setup happens for ground units too so clients see the menu before takeoff.
  -- @param #MANTIS self
  -- @param set The SET object (SET_GROUP, SET_CLIENT, or SET_PLAYER)
  -- @param #function fn Callback receiving (unit, group)
  -- @return #MANTIS self
  function MANTIS:_IterateJammerSet(set, fn)
    if not set then return self end
    if type(set.ForEachClient) == "function" then
      set:ForEachClient(function(client)
        if not client then return end
        local unit = client:GetClientGroupUnit()
        if not unit or not unit:IsAlive() then return end
        local group = unit:GetGroup()
        if not group then return end
        fn(unit, group)
      end)
    elseif type(set.ForEachGroupAlive) == "function" then
      set:ForEachGroupAlive(function(group)
        if not group then return end
        local units = group:GetUnits()
        if not units then return end
        for _, unit in pairs(units) do
          if unit and unit:IsAlive() then
            fn(unit, group)
          end
        end
      end)
    else
      self:E(self.lid .. "ERROR: jammer set is not SET_GROUP, SET_CLIENT, or SET_PLAYER (no ForEachGroupAlive or ForEachClient method).")
    end
    return self
  end

  --- [Internal] Update jammer aircraft states and build snapshot.
  -- @param #MANTIS self
  -- @return #MANTIS self
  function MANTIS:_UpdateJammers()
    if not self._jammerEnabled then return self end
    self._jammerSnapshot = {}
    -- Process client aircraft
    if self._jammerClientSet then
      self:_IterateJammerSet(self._jammerClientSet, function(unit, group)
        local unitName = unit:GetName()
        if not self._jammerAircraft[unitName] then
          self._jammerAircraft[unitName] = {
            loadout    = self._jammerDefaultLoadout,
            active     = false,
            isClient   = unit:IsPlayer(),
            hasLoadout = false,
          }
        else
          -- Re-check IsPlayer in case a human took the slot after first detection
          if not self._jammerAircraft[unitName].isClient and unit:IsPlayer() then
            self._jammerAircraft[unitName].isClient = true
          end
        end
        -- Setup menu for clients (works on ground or airborne)
        if self._jammerAircraft[unitName].isClient and not self._jammerMenusBuilt[unitName] then
          self:_SetupJammerMenu(unit, group)
        end
        -- Snapshot only includes airborne armed jammers
        local state = self._jammerAircraft[unitName]
        if state.active and unit:InAir() then
          local coord = unit:GetCoordinate()
          if coord then
            table.insert(self._jammerSnapshot, { coord = coord, loadout = state.loadout, name = unitName })
          end
        end
      end)
    end
    -- Process AI aircraft
    for _, aiEntry in ipairs(self._jammerAISets or {}) do
      self:_IterateJammerSet(aiEntry.set, function(unit, group)
        local unitName = unit:GetName()
        if not self._jammerAircraft[unitName] then
          self._jammerAircraft[unitName] = {
            loadout    = aiEntry.loadout,
            active     = false,
            isClient   = false,
            hasLoadout = true,
          }
        end
        -- Snapshot only includes airborne armed jammers
        local state = self._jammerAircraft[unitName]
        if state.active and unit:InAir() then
          local coord = unit:GetCoordinate()
          if coord then
            table.insert(self._jammerSnapshot, { coord = coord, loadout = state.loadout, name = unitName })
          end
        end
      end)
    end
    -- Clean up dead units only (keep ground-bound clients so menus persist)
    -- Respawn detection: when client respawns, slot may briefly disappear then reappear
    local toRemove = {}
    for unitName, state in pairs(self._jammerAircraft) do
      local unit = UNIT:FindByName(unitName)
      if not unit or not unit:IsAlive() then
        table.insert(toRemove, unitName)
      end
    end
    for _, unitName in ipairs(toRemove) do
      if self._jammerAircraft[unitName] and self._jammerAircraft[unitName].active then
        self:__JammerDeactivated(1, unitName)
      end
      self._jammerAircraft[unitName] = nil
      self._jammerMenusBuilt[unitName] = nil
    end
    return self
  end

  --- [Internal] Compute which SAMs are jammed this cycle.
  -- @param #MANTIS self
  -- @return #MANTIS self
  function MANTIS:_ComputeJammedSAMs()
    self._jammedSAMs = {}
    if not self._jammerEnabled then return self end
    if #self._jammerSnapshot == 0 then return self end
    local M_TO_NM = 1.0 / 1852.0
    local allSAMs = {}
    local tables = self.automode
      and { self.SAM_Table_Long, self.SAM_Table_Medium, self.SAM_Table_Short, self.SAM_Table_PointDef }
      or  { self.SAM_Table }
    for _, samTable in ipairs(tables) do
      for _, _data in pairs(samTable) do
        if not allSAMs[_data[1]] then allSAMs[_data[1]] = _data[2] end
      end
    end
    for samName, samCoord in pairs(allSAMs) do
      local params = (self._samJammerParams and self._samJammerParams[samName]) or self:_ResolveJammerParams(samName)
      if params then
        local survival = 1.0
        for _, jammer in ipairs(self._jammerSnapshot) do
          local distNM = samCoord:Get2DDistance(jammer.coord) * M_TO_NM
          local pJam = self:_JamGaussianExp(distNM, params, jammer.loadout)
          if pJam > 0 then survival = survival * (1.0 - pJam) end
        end
        local combinedProb = 1.0 - survival
        if combinedProb > 0 and math.random() < combinedProb then
          self._jammedSAMs[samName] = combinedProb
        end
      end
    end
    -- Cycle debug logging (mirrors JammerDebug output, gated on MANTIS debug/verbose flags)
    if self.debug or self.verbose then
      local activeCount = #(self._jammerSnapshot or {})
      local jamCount = self:_CountTable(self._jammedSAMs)
      -- Only log if there's something interesting to report
      if activeCount > 0 or jamCount > 0 then
        local lines = {}
        table.insert(lines, string.format("%sJammer cycle: %d active aircraft, %d SAMs jammed",
          self.lid, activeCount, jamCount))
        -- List active jammers
        for _, jammer in ipairs(self._jammerSnapshot) do
          local cfg = self.JammerLoadouts[jammer.loadout]
          table.insert(lines, string.format("  ACTIVE: %s | loadout=%s",
            jammer.name, cfg and cfg.name or jammer.loadout))
        end
        -- List jammed SAMs
        for samName, prob in pairs(self._jammedSAMs) do
          table.insert(lines, string.format("  JAMMED: %s @ %.0f%%", samName, prob * 100))
        end
        local text = table.concat(lines, "\n")
        self:I(text)
        if self.debug then
          MESSAGE:New(text, 10, "MANTIS"):ToAll()
        end
      end
    end
    return self
  end

  --- [Internal] Set up tiered F10 jammer menu for a player unit.
  -- @param #MANTIS self
  -- @param Wrapper.Unit#UNIT unit
  -- @param Wrapper.Group#GROUP group
  -- @return #MANTIS self
  function MANTIS:_SetupJammerMenu(unit, group)
    local unitName = unit:GetName()
    local groupName = group:GetName()
    if self._jammerMenusBuilt[unitName] then return self end
    self._jammerMenusBuilt[unitName] = true
    -- If this group already has a menu tree (e.g. respawn), remove it first
    if self._jammerGroupMenus and self._jammerGroupMenus[groupName] then
      self._jammerGroupMenus[groupName]:Remove()
      self._jammerGroupMenus[groupName] = nil
    end
    self._jammerGroupMenus = self._jammerGroupMenus or {}
    local rootMenu = MENU_GROUP:New(group, "Jammer Controls")
    self._jammerGroupMenus[groupName] = rootMenu
    -- Tiered loadout submenus
    local alq99Menu  = MENU_GROUP:New(group, "ALQ-99 Loadouts", rootMenu)
    local alq249Menu = MENU_GROUP:New(group, "ALQ-249 Loadouts", rootMenu)
    local mixedMenu  = MENU_GROUP:New(group, "Mixed Loadouts", rootMenu)
    local tierMenus = { ALQ99 = alq99Menu, ALQ249 = alq249Menu, Mixed = mixedMenu }
    for tierName, keys in pairs(self.JammerLoadoutTiers) do
      local parentMenu = tierMenus[tierName]
      for _, loadoutKey in ipairs(keys) do
        local cfg = self.JammerLoadouts[loadoutKey]
        if cfg then
          MENU_GROUP_COMMAND:New(group, cfg.name, parentMenu,
            self._JammerMenuSetLoadout, self, unitName, loadoutKey, group, rootMenu)
        end
      end
    end
    MESSAGE:New("JAMMER ONLINE\nSelect a loadout from the Jammer Controls menu.", 15, "JAMMER"):ToGroup(group)
    return self
  end

  --- [Internal] F10 callback: Set loadout and show Music toggle
  function MANTIS:_JammerMenuSetLoadout(unitName, loadoutKey, group, rootMenu)
    local state = self._jammerAircraft[unitName]
    if not state then return end
    state.loadout = loadoutKey
    state.hasLoadout = true
    local cfg = self.JammerLoadouts[loadoutKey]
    MESSAGE:New(string.format("LOADOUT SELECTED: %s\n%s", cfg and cfg.name or loadoutKey, cfg and cfg.description or ""), 12, "JAMMER"):ToGroup(group)
    -- Add Music toggle if not already present
    if not state._musicMenuAdded then
      state._musicMenuAdded = true
      state._musicOnMenu = nil
      state._musicOffMenu = nil
      self:_ShowMusicOn(unitName, group, rootMenu)
    end
  end

  --- [Internal] Show "Music On" menu entry (jammer is OFF, click to turn ON)
  function MANTIS:_ShowMusicOn(unitName, group, rootMenu)
    local state = self._jammerAircraft[unitName]
    if not state then return end
    if state._musicOffMenu then state._musicOffMenu:Remove() state._musicOffMenu = nil end
    state._musicOnMenu = MENU_GROUP_COMMAND:New(group, "Music On", rootMenu,
      function()
        local s = self._jammerAircraft[unitName]
        if not s then return end
        s.active = true
        MESSAGE:New(string.format("JAMMER ACTIVE\n%s", self.JammerLoadouts[s.loadout] and self.JammerLoadouts[s.loadout].name or s.loadout), 10, "JAMMER"):ToGroup(group)
        self:__JammerActivated(1, unitName, s.loadout)
        self:_ShowMusicOff(unitName, group, rootMenu)
      end)
  end

  --- [Internal] Show "Music Off" menu entry (jammer is ON, click to turn OFF)
  function MANTIS:_ShowMusicOff(unitName, group, rootMenu)
    local state = self._jammerAircraft[unitName]
    if not state then return end
    if state._musicOnMenu then state._musicOnMenu:Remove() state._musicOnMenu = nil end
    state._musicOffMenu = MENU_GROUP_COMMAND:New(group, "Music Off", rootMenu,
      function()
        local s = self._jammerAircraft[unitName]
        if not s then return end
        s.active = false
        MESSAGE:New("JAMMER SAFE", 10, "JAMMER"):ToGroup(group)
        self:__JammerDeactivated(1, unitName)
        self:_ShowMusicOn(unitName, group, rootMenu)
      end)
  end

  --- On After "JammerSuppression" event
  function MANTIS:onafterJammerSuppression(From, Event, To, Group, Name, Probability)
    self:T({From, Event, To, Name, Probability})
    return self
  end

  --- On After "JammerActivated" event
  function MANTIS:onafterJammerActivated(From, Event, To, UnitName, Loadout)
    self:T({From, Event, To, UnitName, Loadout})
    return self
  end

  --- On After "JammerDeactivated" event
  function MANTIS:onafterJammerDeactivated(From, Event, To, UnitName)
    self:T({From, Event, To, UnitName})
    return self
  end

  --- Get table of currently jammed SAM group names.
  -- @param #MANTIS self
  -- @return #table {samName = probability}
  function MANTIS:GetJammedSAMs()
    return self._jammedSAMs or {}
  end

  --- Get number of active jammer aircraft.
  -- @param #MANTIS self
  -- @return #number
  function MANTIS:GetActiveJammerCount()
    return self._jammerSnapshot and #self._jammerSnapshot or 0
  end

  --- Print a debug report of the jammer system to dcs.log and screen.
  -- Lists registered aircraft, their states, snapshot count, and currently
  -- jammed SAMs with their probabilities. Use this to diagnose menu issues,
  -- missing aircraft, or unexpected SAM matching.
  -- @param #MANTIS self
  -- @param #boolean toScreen If true, also display report on screen (default false)
  -- @return #MANTIS self
  function MANTIS:JammerDebug(toScreen)
    local lines = {}
    table.insert(lines, "=== MANTIS JAMMER DEBUG REPORT ===")
    table.insert(lines, string.format("Enabled: %s | Default loadout: %s",
      tostring(self._jammerEnabled), tostring(self._jammerDefaultLoadout)))
    table.insert(lines, string.format("Has client set: %s | AI sets: %d",
      tostring(self._jammerClientSet ~= nil), #(self._jammerAISets or {})))
    -- Aircraft state
    local count = 0
    for unitName, state in pairs(self._jammerAircraft or {}) do
      count = count + 1
      table.insert(lines, string.format("  [%s] active=%s isClient=%s loadout=%s hasLoadout=%s",
        unitName, tostring(state.active), tostring(state.isClient),
        tostring(state.loadout), tostring(state.hasLoadout)))
    end
    table.insert(lines, string.format("Total tracked aircraft: %d", count))
    table.insert(lines, string.format("Active jammer snapshot: %d aircraft airborne+armed", #(self._jammerSnapshot or {})))
    -- Jammed SAMs
    local jcount = 0
    for samName, prob in pairs(self._jammedSAMs or {}) do
      jcount = jcount + 1
      table.insert(lines, string.format("  JAMMED: %s @ %.0f%%", samName, prob * 100))
    end
    table.insert(lines, string.format("Currently jammed SAMs: %d", jcount))
    table.insert(lines, "=== END REPORT ===")
    local report = table.concat(lines, "\n")
    self:I(report)
    if toScreen then
      MESSAGE:New(report, 30, "JAMMER DEBUG"):ToAll()
    end
    return self
  end

  --- Test the SAM resolver against a hypothetical group name.
  -- Useful for verifying naming convention before mission start.
  -- @param #MANTIS self
  -- @param #string testName The hypothetical SAM group name to test
  -- @return #string Matched JammerSAMParams key, or "NO MATCH"
  function MANTIS:JammerTestResolver(testName)
    local params = self:_ResolveJammerParams(testName)
    if not params then
      self:I(string.format("[JammerTestResolver] '%s' -> NO MATCH", testName))
      return "NO MATCH"
    end
    -- Find which key matched
    for key, p in pairs(self.JammerSAMParams) do
      if p == params then
        self:I(string.format("[JammerTestResolver] '%s' -> '%s' {peak=%d, mu=%d, band=%s, floor=%d}",
          testName, key, params.peak, params.mu, params.band, params.floor or 0))
        return key
      end
    end
    return "MATCHED (key unknown)"
  end

  --- Manually set a jammer aircraft loadout (AI scripted control).
  -- @param #MANTIS self
  -- @param #string unitName DCS unit name
  -- @param #string loadoutKey Key into JammerLoadouts
  -- @return #MANTIS self
  function MANTIS:SetJammerLoadout(unitName, loadoutKey)
    if self._jammerAircraft and self._jammerAircraft[unitName] then
      self._jammerAircraft[unitName].loadout = loadoutKey
      self._jammerAircraft[unitName].hasLoadout = true
    end
    return self
  end

  --- Manually activate/deactivate a jammer aircraft (AI scripted control).
  -- @param #MANTIS self
  -- @param #string unitName DCS unit name
  -- @param #boolean active true=on, false=off
  -- @return #MANTIS self
  function MANTIS:SetJammerActive(unitName, active)
    if self._jammerAircraft and self._jammerAircraft[unitName] then
      local wasActive = self._jammerAircraft[unitName].active
      self._jammerAircraft[unitName].active = active
      if active and not wasActive then
        self:__JammerActivated(1, unitName, self._jammerAircraft[unitName].loadout)
      elseif not active and wasActive then
        self:__JammerDeactivated(1, unitName)
      end
    end
    return self
  end

-----------------------------------------------------------------------
-- MANTIS Jammer Extension - Hook Overrides
-----------------------------------------------------------------------

  -- Guard: only save originals once (prevents infinite recursion if file loaded twice)
  if not MANTIS._CheckLoopOriginal then
    MANTIS._CheckLoopOriginal = MANTIS._CheckLoop
  end
  if not MANTIS._onbeforeStatusOriginal then
    MANTIS._onbeforeStatusOriginal = MANTIS.onbeforeStatus
  end

  --- [Internal] Override: _CheckLoop with jammer suppression.
  -- @param #MANTIS self
  -- @param #table samset Table of SAM data.
  -- @param #table detset Table of COORDINATES.
  -- @param #boolean dlink Using DLINK.
  -- @param #number limit Number of SAM sites allowed active on a contact.
  -- @param #table contactSnapshot Contact facts captured once for the current check.
  -- @param #table zoneResults (Optional) Coordinate-zone results shared only within the current check.
  -- @return #number instatusred
  -- @return #number instatusgreen
  -- @return #number activeshorads
  function MANTIS:_CheckLoop(samset, detset, dlink, limit, contactSnapshot, zoneResults)
    local r, g, s = self:_CheckLoopOriginal(samset, detset, dlink, limit, contactSnapshot, zoneResults)
    if self._jammerEnabled and self._jammedSAMs then
      for _, _data in pairs(samset) do
        local name = _data[1]
        local navalparent = _data[8] -- per-unit naval entry: name is a UNIT name
        if self._jammedSAMs[name] and self.SamStateTracker[name] == "RED" then
          local samunit = nil
          local samgroup = nil
          if navalparent then
            samunit = UNIT:FindByName(name)
            samgroup = (samunit and samunit:GetGroup()) or GROUP:FindByName(navalparent)
          else
            samgroup = GROUP:FindByName(name)
          end
          local samalive = false
          if navalparent then samalive = (samunit ~= nil) and samunit:IsAlive() or false
          elseif samgroup then samalive = samgroup:IsAlive() or false end
          if samalive then
            if navalparent then
              -- per-unit naval: tracker set GREEN below; arbiter darkens the group if no unit remains RED
            elseif self.UseEmOnOff then
              samgroup:EnableEmission(false)
            else
              samgroup:OptionAlarmStateGreen()
            end
            self.SamStateTracker[name] = "GREEN"
            self:__JammerSuppression(1, samgroup, name, self._jammedSAMs[name])
            if self.ShoradLink then
              local Shorad = self.Shorad
              local shoradradius = self.checkradius
              local ontime = self.ShoradTime
              Shorad:WakeUpShorad(name, shoradradius, ontime, nil, true)
              self:__ShoradActivated(1, name, shoradradius, ontime)
            end
            if self.debug or self.verbose then
              self:T(string.format("%sJAMMED: %s forced GREEN (%.1f%%)", self.lid, name, self._jammedSAMs[name] * 100))
            end
          end
        end
      end
    end
    return r, g, s
  end

  --- [Internal] Override: onbeforeStatus with jammer update.
  function MANTIS:onbeforeStatus(From, Event, To)
    if self._jammerEnabled then
      self:_UpdateJammers()
      self:_ComputeJammedSAMs()
    end
    return self:_onbeforeStatusOriginal(From, Event, To)
  end

end

-- ===================================================================================================
-- MANTIS Naval Extension: NAVYGROUP integration
-- Lets Ops.NavyGroup#NAVYGROUP objects (cruise control, missions, carrier ops) serve as
-- MANTIS-managed SAM shooters and/or EWR pickets:
--   mymantis:AddNavyGroup(navygroup, "SAM")     -- managed shooter (or "EWR" = radiating picket)
--   navygroup:SetMANTIS(mymantis, "SAM")        -- convenience, same effect
-- The ship group is added to the running set(s) regardless of name prefix; classification
-- and jamming resolve by hull type name as usual. MANTIS takes over emission/alarm
-- switching: the NAVYGROUP's default Emission/Alarmstate are neutralized so its
-- spawn-time option reset does not fight MANTIS.
-- ===================================================================================================
do
  -- Guard MOOSE's ground relocation against ships. SEAD suppression (and any other
  -- caller) invokes RelocateGroundRandomInRadius on suppressed SAM groups without a
  -- category check; on a ship this clobbers the sailing route with a ground-formation
  -- hop (and with onland=true can target a LAND point near a coast). Radar-off
  -- evasion still applies to ships; only the ground move becomes a no-op.
  if CONTROLLABLE and CONTROLLABLE.RelocateGroundRandomInRadius and not CONTROLLABLE._MANTISNavalRelocateGuard then
    CONTROLLABLE._MANTISNavalRelocateGuard = true
    local _origRelocate = CONTROLLABLE.RelocateGroundRandomInRadius
    function CONTROLLABLE:RelocateGroundRandomInRadius( speed, radius, onroad, shortcut, formation, onland )
      if self.IsShip and self:IsShip() then
        return self
      end
      return _origRelocate( self, speed, radius, onroad, shortcut, formation, onland )
    end
  end

  --- [Internal] Check if any enemy surface combatant is within radius of a coordinate.
  -- Builds a live enemy-ship SET_GROUP lazily on first use.
  -- @param #MANTIS self
  -- @param Core.Point#COORDINATE coord Ship position.
  -- @param #number radius Trigger radius in meters.
  -- @return #boolean found
  function MANTIS:_EnemySurfaceInRange(coord, radius)
    if self.NavalThreatSet == nil then
      local own = string.lower(self.Coalition or "")
      local enemy = (own == "red" and "blue") or (own == "blue" and "red") or nil
      if not enemy then
        self:E(self.lid.."NavalSurfaceWakeup: cannot derive enemy coalition from "..tostring(self.Coalition).." - disabling.")
        self.NavalSurfaceWakeup = false
        self.NavalThreatSet = false
        return false
      end
      self.NavalThreatSet = SET_GROUP:New():FilterCoalitions(enemy):FilterCategoryShip():FilterStart()
    end
    if self.NavalThreatSet == false or not coord then return false end
    local found = false
    self.NavalThreatSet:ForEachGroupAlive(
      function(grp)
        if not found then
          local gc = grp:GetCoordinate()
          if gc and gc:Get2DDistance(coord) <= radius then found = true end
        end
      end)
    return found
  end

  --- Configure naval AUTONOMY outside EWR coverage. Default: ENABLED, 150km.
  -- Ships mirror the ground-SAM umbrella concept: a ship group within CoverageKM
  -- of any alive EWR group (including EWR-role ships or AWACS ships in the EWR
  -- set) is managed normally -- alarm GREEN until MANTIS detects a threat inside
  -- one of its units' envelopes. A group OUTSIDE coverage goes alarm RED and
  -- searches/engages autonomously on its own radars until coverage is restored.
  -- Full jamming suppression overrides autonomy and forces the group GREEN.
  -- @param #MANTIS self
  -- @param #boolean onoff Enable (true) or disable (false).
  -- @param #number coveragekm (Optional) Coverage radius in KILOMETERS around each alive EWR (default 150).
  -- @return #MANTIS self
  function MANTIS:SetNavalAutonomy(onoff, coveragekm)
    self.NavalAutonomy = onoff and true or false
    if coveragekm then self.NavalAutonomyRadius = coveragekm * 1000 end
    return self
  end

  --- Enable/disable PER-UNIT classification and switching for naval groups. Default: ENABLED.
  -- Mixed-hull ship groups (e.g. a carrier escorted by destroyers) get one SAM entry PER
  -- SHIP -- each hull with its own type, range, state and jamming curve, switched via
  -- UNIT:EnableEmission while the group stays alarm RED (weapons hot). Disable to revert
  -- to legacy group-level naval handling (first matched hull defines the whole group).
  -- @param #MANTIS self
  -- @param #boolean onoff Enable (true) or disable (false).
  -- @return #MANTIS self
  function MANTIS:SetNavalPerUnit(onoff)
    self.NavalPerUnit = onoff and true or false
    return self
  end

  --- Enable/disable the naval surface wake-up and optionally set a fixed trigger radius.
  -- Default: ENABLED, radius = each ship's own engagement radius from SamDataNaval.
  -- When enabled, a MANTIS-quiet ship goes active (RED / emissions on) whenever an
  -- enemy surface combatant closes within the trigger radius, so anti-ship
  -- engagements are not blocked by EMCON. Jamming still wins: a jammed ship stays
  -- suppressed. Ships only -- ground SAM behavior is unchanged.
  -- @param #MANTIS self
  -- @param #boolean onoff Enable (true) or disable (false).
  -- @param #number radiuskm (Optional) Fixed trigger radius in KILOMETERS for all ships.
  -- @return #MANTIS self
  function MANTIS:SetNavalSurfaceWakeup(onoff, radiuskm)
    self.NavalSurfaceWakeup = onoff and true or false
    self.NavalSurfaceWakeupRadius = radiuskm and radiuskm * 1000 or nil
    return self
  end

  --- Include or exclude naval SAMs from SEAD emission-shutdown evasion. Default: EXCLUDED.
  -- Surface combatants engage inbound ARMs/ASMs with hard-kill defenses (SAMs, CIWS);
  -- going emissions-dark would disable exactly those defenses. Ground SAM behavior is
  -- unchanged. Takes effect at the next SAM table refresh (every 3rd detection cycle).
  -- @param #MANTIS self
  -- @param #boolean onoff If true, ships use SEAD EMCON evasion like ground SAMs.
  -- @return #MANTIS self
  function MANTIS:SetNavalSEAD(onoff)
    self.SEADNaval = onoff and true or false
    -- SEAD:UpdateSet() only ever ADDS names. When switching OFF mid-mission we
    -- must actively remove ship groups already registered with the SEAD
    -- instance, or they would keep evading until mission end.
    if (not self.SEADNaval) and self.mysead and self.mysead.SEADGroupPrefixes then
      for name,_ in pairs(self.mysead.SEADGroupPrefixes) do
        local grp = GROUP:FindByName(name)
        if grp and grp:IsShip() then
          self.mysead.SEADGroupPrefixes[name] = nil
        end
      end
    end
    return self
  end

  --- Add a NAVYGROUP to this MANTIS as SAM shooter and/or EWR picket.
  -- IMPORTANT: MANTIS does not change ROE. NAVYGROUP defaults to Return Fire --
  -- set NavyGroup:SwitchROE(ENUMS.ROE.WeaponFree) in your mission if the ship
  -- should engage detected targets rather than only return fire.
  -- @param #MANTIS self
  -- @param Ops.NavyGroup#NAVYGROUP NavyGroup The navy group to add.
  -- @param #string Role "SAM" (default) = managed shooter, or "EWR" = unmanaged, always-radiating sensor/picket (coverage source). "BOTH" is deprecated and treated as SAM.
  -- @return #MANTIS self
  function MANTIS:AddNavyGroup(NavyGroup, Role)
    local role = string.upper(Role or "SAM")
    if role == "BOTH" then
      -- Deprecated: a MANAGED shooter cannot double as a sensor -- its radars
      -- are dark whenever MANTIS holds it GREEN, so EWR membership senses
      -- nothing and only pollutes EWR-alive counting and the advanced-mode
      -- network ratio. Use a SEPARATE ship group with Role="EWR" as a
      -- radiating picket instead.
      self:E(self.lid.."AddNavyGroup: Role BOTH is deprecated -- treating as SAM. Use a separate EWR-role group as a radiating picket.")
      role = "SAM"
    end
    if not (NavyGroup and NavyGroup.ClassName and string.find(NavyGroup.ClassName,"NAVYGROUP",1,true)) then
      self:E(self.lid.."AddNavyGroup: object passed is not a NAVYGROUP!")
      return self
    end
    local grp = NavyGroup:GetGroup()
    if not (grp and grp:IsAlive()) then
      self:E(self.lid.."AddNavyGroup: NAVYGROUP has no alive GROUP (late-activated? Call after activation).")
      return self
    end
    -- Hand emission/alarm control to MANTIS. NAVYGROUP re-applies its default
    -- Alarmstate/Emission at (re)spawn, which would fight MANTIS switching:
    -- set defaults to Emission ON / Alarmstate AUTO so the reset is neutral.
    if NavyGroup.SetDefaultEmission   then NavyGroup:SetDefaultEmission(true) end
    if NavyGroup.SetDefaultAlarmstate then NavyGroup:SetDefaultAlarmstate(0)  end -- 0 = Auto
    -- NOTE: MANTIS deliberately does NOT touch ROE -- that is the mission
    -- designer's call. Be aware OPSGROUP's default ROE is Return Fire: a
    -- MANTIS-managed NAVYGROUP will radiate when RED but hold its weapons
    -- unless the mission sets e.g. NavyGroup:SwitchROE(ENUMS.ROE.WeaponFree).
    self._navyGroups = self._navyGroups or {}
    self._navyGroups[grp:GetName()] = NavyGroup
    if role == "SAM" then
      self.SAM_Group:AddGroup(grp)
      -- If MANTIS is already up, classify the new ship immediately; otherwise
      -- SetSAMStartState will pick it up at Start.
      if self.SAM_Table then
        self:_RefreshSAMTable()
      end
    elseif role == "EWR" then
      self.EWR_Group:AddGroup(grp)
      if self.Adv_EWR_Group then
        self.Adv_EWR_Group:AddGroup(grp)
      end
    else
      self:E(self.lid.."AddNavyGroup: unknown Role "..tostring(Role).." - use SAM or EWR.")
    end
    self:I(self.lid..string.format("Added NAVYGROUP %s as %s",grp:GetName(),role))
    return self
  end

  --- [Internal, static] Inject NAVYGROUP:SetMANTIS. Idempotent; safe if NAVYGROUP absent.
  function MANTIS._InjectNavyGroupAPI()
    if NAVYGROUP and not NAVYGROUP.SetMANTIS then
      --- Register this NAVYGROUP with a MANTIS instance as SAM shooter and/or EWR picket.
      -- @param Ops.NavyGroup#NAVYGROUP self
      -- @param Functional.Mantis#MANTIS Mantis The MANTIS instance.
      -- @param #string Role "SAM" (default) = managed shooter, or "EWR" = unmanaged, always-radiating sensor/picket (coverage source). "BOTH" is deprecated and treated as SAM.
      -- @return Ops.NavyGroup#NAVYGROUP self
      function NAVYGROUP:SetMANTIS(Mantis, Role)
        if Mantis and Mantis.AddNavyGroup then
          Mantis:AddNavyGroup(self, Role)
        else
          self:E(self.lid.."SetMANTIS: no valid MANTIS instance passed!")
        end
        return self
      end
    end
  end
  -- Try immediately in case NAVYGROUP is already loaded (also runs from MANTIS:New).
  MANTIS._InjectNavyGroupAPI()
end

-----------------------------------------------------------------------
-- MANTIS end
-----------------------------------------------------------------------
