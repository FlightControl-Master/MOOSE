--- **Utilities** Enumerators.
-- 
-- An enumerator is a variable that holds a constant value. Enumerators are very useful because they make the code easier to read and to change in general.
-- 
-- For example, instead of using the same value at multiple different places in your code, you should use a variable set to that value.
-- If, for whatever reason, the value needs to be changed, you only have to change the variable once and do not have to search through you code and reset
-- every value by hand.
-- 
-- Another big advantage is that the LDT intellisense "knows" the enumerators. So you can use the autocompletion feature and do not have to keep all the
-- values in your head or look them up in the docs. 
-- 
-- DCS itself provides a lot of enumerators for various things. See [Enumerators](https://wiki.hoggitworld.com/view/Category:Enumerators) on Hoggit.
-- 
-- Other Moose classe also have enumerators. For example, the AIRBASE class has enumerators for airbase names.
-- 
-- @module ENUMS
-- @image MOOSE.JPG

--- [DCS Enum world](https://wiki.hoggitworld.com/view/DCS_enum_world)
-- @type ENUMS

--- Because ENUMS are just better practice.
-- 
--  The ENUMS class adds some handy variables, which help you to make your code better and more general.
--
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

--- Alarm state.
-- @type ENUMS.AlarmState
-- @field #number Auto AI will automatically switch alarm states based on the presence of threats. The AI kind of cheats in this regard.
-- @field #number Green Group is not combat ready. Sensors are stowed if possible.
-- @field #number Red Group is combat ready and actively searching for targets. Some groups like infantry will not move in this state.
ENUMS.AlarmState = {
  Auto=0,
  Green=1,
  Red=2,
}

--- Weapon types. See the [Weapon Flag](https://wiki.hoggitworld.com/view/DCS_enum_weapon_flag) enumerotor on hoggit wiki.
-- @type ENUMS.WeaponFlag
ENUMS.WeaponFlag={
  -- Bombs
  LGB                  =          2,
  TvGB                 =          4,
  SNSGB                =          8,
  HEBomb               =         16,
  Penetrator           =         32,
  NapalmBomb           =         64,
  FAEBomb              =        128,
  ClusterBomb          =        256,
  Dispencer            =        512,
  CandleBomb           =       1024,
  ParachuteBomb        = 2147483648,
  -- Rockets
  LightRocket          =       2048,
  MarkerRocket         =       4096,
  CandleRocket         =       8192,
  HeavyRocket          =      16384,
  -- Air-To-Surface Missiles
  AntiRadarMissile     =      32768,
  AntiShipMissile      =      65536,
  AntiTankMissile      =     131072,
  FireAndForgetASM     =     262144,
  LaserASM             =     524288,
  TeleASM              =    1048576,
  CruiseMissile        =    2097152,
  AntiRadarMissile2    = 1073741824,
  -- Air-To-Air Missiles
  SRAM                 =    4194304,
  MRAAM                =    8388608, 
  LRAAM                =   16777216,
  IR_AAM               =   33554432,
  SAR_AAM              =   67108864,
  AR_AAM               =  134217728,
  --- Guns
  GunPod               =  268435456,
  BuiltInCannon        =  536870912,
  ---
  -- Combinations
  --
  -- Bombs
  GuidedBomb           =         14, -- (LGB + TvGB + SNSGB)
  AnyUnguidedBomb      = 2147485680, -- (HeBomb + Penetrator + NapalmBomb + FAEBomb + ClusterBomb + Dispencer + CandleBomb + ParachuteBomb)
  AnyBomb              = 2147485694, -- (GuidedBomb + AnyUnguidedBomb)
  --- Rockets
  AnyRocket            =      30720, -- LightRocket + MarkerRocket + CandleRocket + HeavyRocket
  --- Air-To-Surface Missiles
  GuidedASM            =    1572864, -- (LaserASM + TeleASM)
  TacticalASM          =    1835008, -- (GuidedASM + FireAndForgetASM)
  AnyASM               =    4161536, -- (AntiRadarMissile + AntiShipMissile + AntiTankMissile + FireAndForgetASM + GuidedASM + CruiseMissile)
  AnyASM2              = 1077903360, -- 4161536+1073741824,
  --- Air-To-Air Missiles
  AnyAAM               =  264241152, -- IR_AAM + SAR_AAM + AR_AAM + SRAAM + MRAAM + LRAAM
  AnyAutonomousMissile =   36012032, -- IR_AAM + AntiRadarMissile + AntiShipMissile + FireAndForgetASM + CruiseMissile
  AnyMissile           =  268402688, -- AnyASM + AnyAAM   
  --- Guns
  Cannons              =  805306368, -- GUN_POD + BuiltInCannon
  ---
  -- Even More Genral  
  Auto                 = 3221225470, -- Any Weapon (AnyBomb + AnyRocket + AnyMissile + Cannons)
  AutoDCS              = 1073741822, -- Something if often see
  AnyAG                = 2956984318, -- Any Air-To-Ground Weapon
  AnyAA                =  264241152, -- Any Air-To-Air Weapon
  AnyUnguided          = 2952822768, -- Any Unguided Weapon
  AnyGuided            =  268402702, -- Any Guided Weapon   
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
-- @field #string GROUNDATTACK Ground attack.
-- @field #string INTERCEPT Intercept.
-- @field #string PINPOINTSTRIKE Pinpoint strike.
-- @field #string RECONNAISSANCE Reconnaissance mission.
-- @field #string REFUELING Refueling mission.
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

--- Formations (new). See the [Formations](https://wiki.hoggitworld.com/view/DCS_enum_formation) on hoggit wiki.
-- @type ENUMS.Formation
ENUMS.Formation={}
ENUMS.Formation.FixedWing={}
ENUMS.Formation.FixedWing.LineAbreast={}
ENUMS.Formation.FixedWing.LineAbreast.Close = 65537
ENUMS.Formation.FixedWing.LineAbreast.Open  = 65538
ENUMS.Formation.FixedWing.LineAbreast.Group = 65539
ENUMS.Formation.FixedWing.Trail={}
ENUMS.Formation.FixedWing.Trail.Close = 131073
ENUMS.Formation.FixedWing.Trail.Open  = 131074
ENUMS.Formation.FixedWing.Trail.Group = 131075
ENUMS.Formation.FixedWing.Wedge={}
ENUMS.Formation.FixedWing.Wedge.Close = 196609
ENUMS.Formation.FixedWing.Wedge.Open  = 196610
ENUMS.Formation.FixedWing.Wedge.Group = 196611
ENUMS.Formation.FixedWing.EchelonRight={}
ENUMS.Formation.FixedWing.EchelonRight.Close = 262145
ENUMS.Formation.FixedWing.EchelonRight.Open  = 262146
ENUMS.Formation.FixedWing.EchelonRight.Group = 262147
ENUMS.Formation.FixedWing.EchelonLeft={}
ENUMS.Formation.FixedWing.EchelonLeft.Close = 327681
ENUMS.Formation.FixedWing.EchelonLeft.Open  = 327682
ENUMS.Formation.FixedWing.EchelonLeft.Group = 327683
ENUMS.Formation.FixedWing.FingerFour={}
ENUMS.Formation.FixedWing.FingerFour.Close = 393217
ENUMS.Formation.FixedWing.FingerFour.Open  = 393218
ENUMS.Formation.FixedWing.FingerFour.Group = 393219
ENUMS.Formation.FixedWing.Spread={}
ENUMS.Formation.FixedWing.Spread.Close = 458753
ENUMS.Formation.FixedWing.Spread.Open  = 458754
ENUMS.Formation.FixedWing.Spread.Group = 458755
ENUMS.Formation.FixedWing.BomberElement={}
ENUMS.Formation.FixedWing.BomberElement.Close = 786433
ENUMS.Formation.FixedWing.BomberElement.Open  = 786434
ENUMS.Formation.FixedWing.BomberElement.Group = 786435
ENUMS.Formation.FixedWing.BomberElementHeight={}
ENUMS.Formation.FixedWing.BomberElementHeight.Close = 851968
ENUMS.Formation.FixedWing.FighterVic={}
ENUMS.Formation.FixedWing.FighterVic.Close = 917505
ENUMS.Formation.FixedWing.FighterVic.Open  = 917506
ENUMS.Formation.RotaryWing={}
ENUMS.Formation.RotaryWing.Column={}
ENUMS.Formation.RotaryWing.Column.D70=720896
ENUMS.Formation.RotaryWing.Wedge={}
ENUMS.Formation.RotaryWing.Wedge.D70=8
ENUMS.Formation.RotaryWing.FrontRight={}
ENUMS.Formation.RotaryWing.FrontRight.D300=655361
ENUMS.Formation.RotaryWing.FrontRight.D600=655362
ENUMS.Formation.RotaryWing.FrontLeft={}
ENUMS.Formation.RotaryWing.FrontLeft.D300=655617
ENUMS.Formation.RotaryWing.FrontLeft.D600=655618
ENUMS.Formation.RotaryWing.EchelonRight={}
ENUMS.Formation.RotaryWing.EchelonRight.D70 =589825
ENUMS.Formation.RotaryWing.EchelonRight.D300=589826
ENUMS.Formation.RotaryWing.EchelonRight.D600=589827
ENUMS.Formation.RotaryWing.EchelonLeft={}
ENUMS.Formation.RotaryWing.EchelonLeft.D70 =590081
ENUMS.Formation.RotaryWing.EchelonLeft.D300=590082
ENUMS.Formation.RotaryWing.EchelonLeft.D600=590083
ENUMS.Formation.Vehicle={}
ENUMS.Formation.Vehicle.Vee="Vee"
ENUMS.Formation.Vehicle.EchelonRight="EchelonR"
ENUMS.Formation.Vehicle.OffRoad="Off Road"
ENUMS.Formation.Vehicle.Rank="Rank"
ENUMS.Formation.Vehicle.EchelonLeft="EchelonL"
ENUMS.Formation.Vehicle.OnRoad="On Road"
ENUMS.Formation.Vehicle.Cone="Cone"
ENUMS.Formation.Vehicle.Diamond="Diamond"

--- Formations (old). The old format is a simplified version of the new formation enums, which allow more sophisticated settings.
-- See the [Formations](https://wiki.hoggitworld.com/view/DCS_enum_formation) on hoggit wiki.
-- @type ENUMS.FormationOld
ENUMS.FormationOld={}
ENUMS.FormationOld.FixedWing={}
ENUMS.FormationOld.FixedWing.LineAbreast=1
ENUMS.FormationOld.FixedWing.Trail=2
ENUMS.FormationOld.FixedWing.Wedge=3
ENUMS.FormationOld.FixedWing.EchelonRight=4
ENUMS.FormationOld.FixedWing.EchelonLeft=5
ENUMS.FormationOld.FixedWing.FingerFour=6
ENUMS.FormationOld.FixedWing.SpreadFour=7
ENUMS.FormationOld.FixedWing.BomberElement=12
ENUMS.FormationOld.FixedWing.BomberElementHeight=13
ENUMS.FormationOld.FixedWing.FighterVic=14
ENUMS.FormationOld.RotaryWing={}
ENUMS.FormationOld.RotaryWing.Wedge=8
ENUMS.FormationOld.RotaryWing.Echelon=9
ENUMS.FormationOld.RotaryWing.Front=10
ENUMS.FormationOld.RotaryWing.Column=11


--- Morse Code. See the [Wikipedia](https://en.wikipedia.org/wiki/Morse_code).
-- 
-- * Short pulse "*"
-- * Long pulse "-"
-- 
-- Pulses are separated by a blank character " ".
-- 
-- @type ENUMS.Morse
ENUMS.Morse={}
ENUMS.Morse.A="* -"
ENUMS.Morse.B="- * * *"
ENUMS.Morse.C="- * - *"
ENUMS.Morse.D="- * *"
ENUMS.Morse.E="*"
ENUMS.Morse.F="* * - *"
ENUMS.Morse.G="- - *"
ENUMS.Morse.H="* * * *"
ENUMS.Morse.I="* *"
ENUMS.Morse.J="* - - -"
ENUMS.Morse.K="- * -"
ENUMS.Morse.L="* - * *"
ENUMS.Morse.M="- -"
ENUMS.Morse.N="- *"
ENUMS.Morse.O="- - -"
ENUMS.Morse.P="* - - *"
ENUMS.Morse.Q="- - * -"
ENUMS.Morse.R="* - *"
ENUMS.Morse.S="* * *"
ENUMS.Morse.T="-"
ENUMS.Morse.U="* * -"
ENUMS.Morse.V="* * * -"
ENUMS.Morse.W="* - -"
ENUMS.Morse.X="- * * -"
ENUMS.Morse.Y="- * - -"
ENUMS.Morse.Z="- - * *"
ENUMS.Morse.N1="* - - - -"
ENUMS.Morse.N2="* * - - -"
ENUMS.Morse.N3="* * * - -"
ENUMS.Morse.N4="* * * * -"
ENUMS.Morse.N5="* * * * *"
ENUMS.Morse.N6="- * * * *"
ENUMS.Morse.N7="- - * * *"
ENUMS.Morse.N8="- - - * *"
ENUMS.Morse.N9="- - - - *"
ENUMS.Morse.N0="- - - - -"
ENUMS.Morse[" "]=" "

--- ISO (639-1) 2-letter Language Codes. See the [Wikipedia](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes).
-- 
-- @type ENUMS.ISOLang
ENUMS.ISOLang = 
{
  Arabic    = 'AR',
  Chinese   = 'ZH',
  English   = 'EN',
  French    = 'FR',
  German    = 'DE',
  Russian   = 'RU',
  Spanish   = 'ES',
  Japanese  = 'JA',
  Italian   = 'IT',
}

--- Phonetic Alphabet (NATO). See the [Wikipedia](https://en.wikipedia.org/wiki/NATO_phonetic_alphabet).
-- 
-- @type ENUMS.Phonetic
ENUMS.Phonetic =
{
  A = 'Alpha',
  B = 'Bravo',
  C = 'Charlie',
  D = 'Delta',
  E = 'Echo',
  F = 'Foxtrot',
  G = 'Golf',
  H = 'Hotel',
  I = 'India',
  J = 'Juliett',
  K = 'Kilo',
  L = 'Lima',
  M = 'Mike',
  N = 'November',
  O = 'Oscar',
  P = 'Papa',
  Q = 'Quebec',
  R = 'Romeo',
  S = 'Sierra',
  T = 'Tango',
  U = 'Uniform',
  V = 'Victor',
  W = 'Whiskey',
  X = 'Xray',
  Y = 'Yankee',
  Z = 'Zulu',
}