--- **Utilities** Enumerators.
-- 
-- See the [Simulator Scripting Engine Documentation](https://wiki.hoggitworld.com/view/Simulator_Scripting_Engine_Documentation) on Hoggit for further explanation and examples.
-- 
-- @module ENUMS
-- @image MOOSE.JPG

--- [DCS Enum world](https://wiki.hoggitworld.com/view/DCS_enum_world)
-- @type ENUMS

--- The world singleton contains functions centered around two different but extremely useful functions.
-- * Events and event handlers are all governed within world.
-- * A number of functions to get information about the game world.
-- 
-- See [https://wiki.hoggitworld.com/view/DCS_singleton_world](https://wiki.hoggitworld.com/view/DCS_singleton_world)
-- @field #ENUMS
ENUMS = {}

--- Rules of Engagement.
-- @type ENUMS.ROE
-- @field #number WeaponFree AI will engage any enemy group it detects. Target prioritization is based based on the threat of the target.
-- @field #number OpenFireWeaponFree AI will engage any enemy group it detects, but will prioritize targets specified in the groups tasking.
-- @field #number OpenFire AI will engage only targets specified in its taskings.
-- @field #number ReturnFire AI will only engage threats that shoot first.
-- @field #number WeaponHold AI will hold fire under all circumstances.
ENUMS.ROE = {
  WeaponFree=0,
  OpenFireWeaponFree=1,
  OpenFire=2,
  ReturnFire=3,
  WeaponHold=4,
  }

--- Reaction On Threat.
-- @type ENUMS.ROT
-- @field #number NoReaction No defensive actions will take place to counter threats.
-- @field #number PassiveDefense AI will use jammers and other countermeasures in an attempt to defeat the threat. AI will not attempt a maneuver to defeat a threat.
-- @field #number EvadeFire AI will react by performing defensive maneuvers against incoming threats. AI will also use passive defense.
-- @field #number BypassAndEscape AI will attempt to avoid enemy threat zones all together. This includes attempting to fly above or around threats.
-- @field #number AllowAbortMission If a threat is deemed severe enough the AI will abort its mission and return to base.
ENUMS.ROT = {
  NoReaction=0,
  PassiveDefense=1,
  EvadeFire=2,
  BypassAndEscape=3,
  AllowAbortMission=4,
}

--- Weapon types.
-- @type ENUMS.WeaponFlag
ENUMS.WeaponFlag={
  -- Combinations
  Auto=3221225470, --AnyWeapon (AnyBomb + AnyRocket + AnyMissile + Cannons)
  AnyAG=2956984318,
  AnyAA=264241152,
  AnyUnguided=2952822768,
  AnyGuided=268402702, 
  -- Bombs
  LGB=2,
  TvGB=4,
  SNSGB=8,
  HEBomb=16,
  Penetrator=32,
  NapalmBomb=64,
  FAEBomb=128,
  ClusterBomb=256,
  Dispencer=512,
  CandleBomb=1024,
  ParachuteBomb=2147483648,
  GuidedBomb=14, -- (LGB + TvGB + SNSGB)
  AnyUnguidedBomb=2147485680, -- (HeBomb + Penetrator + NapalmBomb + FAEBomb + ClusterBomb + Dispencer + CandleBomb + ParachuteBomb)
  AnyBomb=2147485694, -- (GuidedBomb + AnyUnguidedBomb)
  -- Rockets
  LightRocket=2048,
  MarkerRocket=4096,
  CandleRocket=8192,
  HeavyRocket=16384,
  AnyRocket=30720,  -- LightRocket + MarkerRocket + CandleRocket + HeavyRocket
  --- Air-To-Air Missiles
  SRAM=4194304,
  MRAAM=8388608, 
  LRAaM=16777216,
  IR_AAM=33554432,
  SAR_AAM=67108864,
  AR_AAM=134217728,
  AnyAAM=264241152,     -- IR_AAM + SAR_AAM + AR_AAM + SRAAM + MRAAM + LRAAM
  AnyMissile=268402688,  -- ASM + AnyAAM   
  AnyAutonomousMissile=36012032, --IR_AAM + AntiRadarMissile + AntiShipMissile + FireAndForgetASM + CruiseMissile
  --- Guns
  GUN_POD=268435456,
  BuiltInCannon=536870912,
  Cannos=805306368,             --GUN_POD + BuiltInCannon)    
}

--- Mission tasks.
-- @type ENUMS.MissionTask
-- @field #string NOTHING No special task. Group can perform the minimal tasks: Orbit, Refuelling, Follow and Aerobatics.
-- @field #string AFAC Forward Air Controller Air. Can perform the tasks: Attack Group, Attack Unit, FAC assign group, Bombing, Attack Map Object.
-- @field #string ANTISHIPSTRIKE Naval ops. Can perform the tasks: Attack Group, Attack Unit.
-- @field #string AWACS AWACS.
-- @field #string CAP Combat Air Patrol.
-- @field #string CAS Close Air Support.
-- @field #string ESCORT Escort another group.
-- @field #string FIGHTERSWEEP Fighter sweep.
-- @field #string INTERCEPT Intercept.
-- @field #string PINPOINTSTRIKE Pinpoint strike.
-- @field #string RECONNAISSANCE Reconnaissance mission.
-- @field #string REFUELLING Refuelling mission.
-- @field #string RUNWAYATTACK Attack the runway of an airdrome.
-- @field #string SEAD Suppression of Enemy Air Defenses.
-- @field #string TRANSPORT Troop transport.
ENUMS.MissionTask={
  NOTHING="Nothing",
  AFAC="AFAC",
  ANTISHIPSTRIKE="Antiship Strike",
  AWACS="AWACS",
  CAP="CAP",
  CAS="CAS",
  ESCORT="Escort",
  FIGHTERSWEEP="Fighter Sweep",
  GROUNDATTACK="Ground Attack",
  INTERCEPT="Intercept",
  PINPOINTSTRIKE="Pinpoint Strike",
  RECONNAISSANCE="Reconnaissance",
  REFUELING="Refueling",
  RUNWAYATTACK="Runway Attack",
  SEAD="SEAD",
  TRANSPORT="Transport",
}