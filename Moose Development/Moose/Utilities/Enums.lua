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
-- Other Moose classes also have enumerators. For example, the AIRBASE class has enumerators for airbase names.
-- 
-- @module Utilities.Enums
-- @image MOOSE.JPG

--- [DCS Enum world](https://wiki.hoggitworld.com/view/DCS_enum_world)
-- @type ENUMS

--- Because ENUMS are just better practice.
-- 
--  The ENUMS class adds some handy variables, which help you to make your code better and more general.
--
-- @field #ENUMS
ENUMS = {}

--- Suppress the error box
env.setErrorMessageBoxEnabled( false )

--- Rules of Engagement.
-- @type ENUMS.ROE
-- @field #number WeaponFree [AIR] AI will engage any enemy group it detects. Target prioritization is based based on the threat of the target.
-- @field #number OpenFireWeaponFree [AIR] AI will engage any enemy group it detects, but will prioritize targets specified in the groups tasking.
-- @field #number OpenFire [AIR, GROUND, NAVAL] AI will engage only targets specified in its taskings.
-- @field #number ReturnFire [AIR, GROUND, NAVAL] AI will only engage threats that shoot first.
-- @field #number WeaponHold [AIR, GROUND, NAVAL] AI will hold fire under all circumstances.
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
  --- Torpedo
  Torpedo              = 4294967296,
  ---
  -- Even More Genral
  Auto                 = 3221225470, -- Any Weapon (AnyBomb + AnyRocket + AnyMissile + Cannons)
  AutoDCS              = 1073741822, -- Something if often see
  AnyAG                = 2956984318, -- Any Air-To-Ground Weapon
  AnyAA                =  264241152, -- Any Air-To-Air Weapon
  AnyUnguided          = 2952822768, -- Any Unguided Weapon
  AnyGuided            =  268402702, -- Any Guided Weapon
}

--- Weapon types by category. See the [Weapon Flag](https://wiki.hoggitworld.com/view/DCS_enum_weapon_flag) enumerator on hoggit wiki.
-- @type ENUMS.WeaponType
-- @field #table Bomb Bombs.
-- @field #table Rocket Rocket.
-- @field #table Gun Guns.
-- @field #table Missile Missiles.
-- @field #table AAM Air-to-Air missiles.
-- @field #table Torpedo Torpedos.
-- @field #table Any Combinations.
ENUMS.WeaponType={}
ENUMS.WeaponType.Bomb={
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
  -- Combinations
  GuidedBomb           =         14, -- (LGB + TvGB + SNSGB)
  AnyUnguidedBomb      = 2147485680, -- (HeBomb + Penetrator + NapalmBomb + FAEBomb + ClusterBomb + Dispencer + CandleBomb + ParachuteBomb)
  AnyBomb              = 2147485694, -- (GuidedBomb + AnyUnguidedBomb)
}
ENUMS.WeaponType.Rocket={
  -- Rockets
  LightRocket          =       2048,
  MarkerRocket         =       4096,
  CandleRocket         =       8192,
  HeavyRocket          =      16384,
  -- Combinations
  AnyRocket            =      30720, -- LightRocket + MarkerRocket + CandleRocket + HeavyRocket
}
ENUMS.WeaponType.Gun={
  -- Guns
  GunPod               =  268435456,
  BuiltInCannon        =  536870912,
  -- Combinations
  Cannons              =  805306368, -- GUN_POD + BuiltInCannon
}
ENUMS.WeaponType.Missile={
  -- Missiles
  AntiRadarMissile     =      32768,
  AntiShipMissile      =      65536,
  AntiTankMissile      =     131072,
  FireAndForgetASM     =     262144,
  LaserASM             =     524288,
  TeleASM              =    1048576,
  CruiseMissile        =    2097152,
  AntiRadarMissile2    = 1073741824,
  -- Combinations
  GuidedASM            =    1572864, -- (LaserASM + TeleASM)
  TacticalASM          =    1835008, -- (GuidedASM + FireAndForgetASM)
  AnyASM               =    4161536, -- (AntiRadarMissile + AntiShipMissile + AntiTankMissile + FireAndForgetASM + GuidedASM + CruiseMissile)
  AnyASM2              = 1077903360, -- 4161536+1073741824,
  AnyAutonomousMissile =   36012032, -- IR_AAM + AntiRadarMissile + AntiShipMissile + FireAndForgetASM + CruiseMissile
  AnyMissile           =  268402688, -- AnyASM + AnyAAM
}
ENUMS.WeaponType.AAM={
  -- Air-To-Air Missiles
  SRAM                 =    4194304,
  MRAAM                =    8388608,
  LRAAM                =   16777216,
  IR_AAM               =   33554432,
  SAR_AAM              =   67108864,
  AR_AAM               =  134217728,
  -- Combinations
  AnyAAM               =  264241152, -- IR_AAM + SAR_AAM + AR_AAM + SRAAM + MRAAM + LRAAM
}
ENUMS.WeaponType.Torpedo={
  -- Torpedo
  Torpedo              = 4294967296,
}
ENUMS.WeaponType.Any={
  -- General combinations
  Weapon               = 3221225470, -- Any Weapon (AnyBomb + AnyRocket + AnyMissile + Cannons)
  AG                   = 2956984318, -- Any Air-To-Ground Weapon
  AA                   =  264241152, -- Any Air-To-Air Weapon
  Unguided             = 2952822768, -- Any Unguided Weapon
  Guided               =  268402702, -- Any Guided Weapon
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
-- @field #string GROUNDESCORT Ground escort another group.
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
  GROUNDESCORT="Ground escort",
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

--- Reporting Names (NATO). See the [Wikipedia](https://en.wikipedia.org/wiki/List_of_NATO_reporting_names_for_fighter_aircraft).
-- DCS known aircraft types
-- 
-- @type ENUMS.ReportingName
ENUMS.ReportingName =
{
  NATO = {
    -- Fighters
    Dragon = "JF-17", -- China, correctly Fierce Dragon, Thunder for PAC
    Fagot = "MiG-15",
    Farmer = "MiG-19", -- Shenyang J-6 and Mikoyan-Gurevich MiG-19
    Felon = "Su-57",
    Fencer = "Su-24",
    Fishbed = "MiG-21",
    Fitter = "Su-17", -- Sukhoi Su-7 and Su-17/Su-20/Su-22
    Flogger = "MiG-23",  --and MiG-27
    Flogger_D = "MiG-27",  --and MiG-23
    Flagon = "Su-15",
    Foxbat = "MiG-25",
    Fulcrum = "MiG-29",
    Foxhound = "MiG-31",
    Flanker = "Su-27", -- Sukhoi Su-27/Su-30/Su-33/Su-35/Su-37 and Shenyang J-11/J-15/J-16
    Flanker_C = "Su-30",
    Flanker_E = "Su-35",
    Flanker_F = "Su-37",
    Flanker_L = "J-11A",
    Firebird = "J-10",
    Sea_Flanker = "Su-33",
    Fullback = "Su-34", -- also Su-32
    Frogfoot = "Su-25",
    Tomcat = "F-14", -- Iran
    Mirage = "Mirage", -- various non-NATO
    Codling = "Yak-40",
    Maya = "L-39",
    -- Fighters US/NATO
    Warthog = "A-10",
    --Mosquito = "A-20",
    Skyhawk = "A-4E",
    Viggen = "AJS37",
    Harrier_B = "AV8BNA",
    Harrier = "AV-8B",
    Spirit = "B-2",
    Aviojet = "C-101",
    Nighthawk = "F-117A",
    Eagle = "F-15C",
    Mudhen = "F-15E",
    Viper = "F-16",
    Phantom = "F-4E",
    Tiger = "F-5", -- was thinkg to name this MiG-25 ;)
    Sabre = "F-86",
    Hornet = "A-18", -- avoiding the slash
    Hawk = "Hawk",
    Albatros = "L-39",
    Goshawk = "T-45",
    Starfighter = "F-104",
    Tornado = "Tornado",
    -- Transport / Bomber / Others
    Atlas = "A400",
    Lancer = "B1-B",
    Stratofortress = "B-52H",
    Herc = "C-130",
    Hercules = "C-130J-30",
    Super_Hercules = "Hercules",
    Globemaster = "C-17",
    Greyhound = "C-2A",
    Galaxy = "C-5",
    Hawkeye = "E-2D",
    Sentry = "E-3A",
    Stratotanker = "KC-135",
    Gasstation = "KC-135MPRS",
    Extender = "KC-10",
    Orion = "P-3C",
    Viking = "S-3B",
    Osprey = "V-22",
    Intruder = "A6E",
    -- Bomber Rus
    Badger = "H6-J",
    Bear_J = "Tu-142", -- also Tu-95
    Bear = "Tu-95", -- also Tu-142
    Blinder = "Tu-22",
    Blackjack = "Tu-160",
    -- AIC / Transport / Other
    Clank = "An-30",
    Curl = "An-26",
    Candid = "IL-76",
    Midas = "IL-78",
    Mainstay = "A-50",
    Mainring = "KJ-2000", -- A-50 China
    Yak = "Yak-52",
    -- Helos
    Helix = "Ka-27",
    Shark = "Ka-50",
    Hind = "Mi-24",
    Halo = "Mi-26",
    Hip = "Mi-8",
    Havoc = "Mi-28",
    Gazelle = "SA342",
    -- Helos US
    Huey = "UH-1H",
    Cobra = "AH-1",
    Apache = "AH-64",
    Chinook = "CH-47",
    Sea_Stallion = "CH-53",
    Kiowa = "OH-58",
    Seahawk = "SH-60",
    Blackhawk = "UH-60",
    Sea_King = "S-61",
    -- Drones
    UCAV = "WingLoong",
    Reaper = "MQ-9",
    Predator = "MQ-1A",
  }
}

--- Enums for Link16 transmit power
-- @type ENUMS.Link16Power
ENUMS.Link16Power = {
  none = 0,
  low = 1,
  medium = 2,
  high = 3,
}


--- Enums for the STORAGE class for stores - which need to be in ""
-- @type ENUMS.Storage
-- @type ENUMS.Storage.weapons
-- @type ENUMS.Storage.weapons.missiles
-- @type ENUMS.Storage.weapons.bombs
-- @type ENUMS.Storage.weapons.nurs
-- @type ENUMS.Storage.weapons.containers
-- @type ENUMS.Storage.weapons.droptanks
-- @type ENUMS.Storage.weapons.adapters
-- @type ENUMS.Storage.weapons.torpedoes
-- @type ENUMS.Storage.weapons.Gazelle
-- @type ENUMS.Storage.weapons.CH47
-- @type ENUMS.Storage.weapons.OH58
-- @type ENUMS.Storage.weapons.UH1H
-- @type ENUMS.Storage.weapons.AH64D
ENUMS.Storage = {
  weapons = {
    missiles = {}, -- Missiles
    bombs = {}, -- Bombs
    nurs = {}, --  Rockets and unguided
    containers = {}, -- Containers
    shells = {}, -- Shells
    gunmounts = {}, -- Gun Mounts
    droptanks = {}, -- Droptanks
    adapters = {}, -- Adapter
    torpedoes = {}, -- Torpedoes
    Gazelle = {}, -- Gazelle specifics
    CH47 = {}, -- Chinook specifics
    OH58 = {}, -- Kiowa specifics
    UH1H = {}, -- Huey specifics
    AH64D = {}, -- Huey specifics
    UH60L = {}, -- Blackhawk specifics
  }
}

ENUMS.Storage.weapons.containers.APK9 = 'weapons.containers.APK-9'
ENUMS.Storage.weapons.shells.KDA_35_FAPDS = 'weapons.shells.KDA_35_FAPDS'
ENUMS.Storage.weapons.shells.BR_354N = 'weapons.shells.BR_354N'
ENUMS.Storage.weapons.droptanks.HB_F4E_EXT_WingTank_EMPTY = 'weapons.droptanks.HB_F-4E_EXT_WingTank_EMPTY'
ENUMS.Storage.weapons.nurs.HYDRA_70_M151_M433 = 'weapons.nurs.HYDRA_70_M151_M433'
ENUMS.Storage.weapons.shells.Rh202_20_HE = 'weapons.shells.Rh202_20_HE'
ENUMS.Storage.weapons.bombs.GBU_38 = 'weapons.bombs.GBU_38'
ENUMS.Storage.weapons.containers._16c_hts_pod = 'weapons.containers.16c_hts_pod'
ENUMS.Storage.weapons.missiles.AGM_65G = 'weapons.missiles.AGM_65G'
ENUMS.Storage.weapons.gunmounts.NR30 = 'weapons.gunmounts.NR-30'
ENUMS.Storage.weapons.gunmounts.MB339_ANM3_L = 'weapons.gunmounts.{MB339_ANM3_L}'
ENUMS.Storage.weapons.adapters.UB13 = 'weapons.adapters.UB-13'
ENUMS.Storage.weapons.shells.N37_37x155_HEI_T = 'weapons.shells.N37_37x155_HEI_T'
ENUMS.Storage.weapons.bombs.AN_M30A1 = 'weapons.bombs.AN_M30A1'
ENUMS.Storage.weapons.adapters.APU601 = 'weapons.adapters.APU-60-1'
ENUMS.Storage.weapons.adapters.M2000C_AUF2 = 'weapons.adapters.M-2000C_AUF2'
ENUMS.Storage.weapons.shells.MG_20x82_API = 'weapons.shells.MG_20x82_API'
ENUMS.Storage.weapons.adapters.Carrier_N1_EM_EF = 'weapons.adapters.Carrier_N-1_EM_EF'
ENUMS.Storage.weapons.gunmounts.OH58D_M3P_L500 = 'weapons.gunmounts.OH58D_M3P_L500'
ENUMS.Storage.weapons.adapters.RB15pylon = 'weapons.adapters.RB15pylon'
ENUMS.Storage.weapons.bombs.AGM_62 = 'weapons.bombs.AGM_62'
ENUMS.Storage.weapons.shells.GSH23_23_AP = 'weapons.shells.GSH23_23_AP'
ENUMS.Storage.weapons.shells.Mauser7_92x57_S_m_K_Ub_m_Zerl = 'weapons.shells.Mauser7.92x57_S.m.K._Ub.m.Zerl.'
ENUMS.Storage.weapons.shells.M2_12_7 = 'weapons.shells.M2_12_7'
ENUMS.Storage.weapons.shells.M230_HEDPM789 = 'weapons.shells.M230_HEDP M789'
ENUMS.Storage.weapons.adapters.UB_32A = 'weapons.adapters.UB_32A'
ENUMS.Storage.weapons.shells.L23A1_APFSDS = 'weapons.shells.L23A1_APFSDS'
ENUMS.Storage.weapons.shells.DEFA553_30HE = 'weapons.shells.DEFA553_30HE'
ENUMS.Storage.weapons.bombs.LYSBOMB11087 = 'weapons.bombs.LYSBOMB 11087'
ENUMS.Storage.weapons.shells.KS19_100HE = 'weapons.shells.KS19_100HE'
ENUMS.Storage.weapons.droptanks.M2KC_RPL_522_EMPTY = 'weapons.droptanks.M2KC_RPL_522_EMPTY'
ENUMS.Storage.weapons.droptanks.M2KC_08_RPL541 = 'weapons.droptanks.M2KC_08_RPL541'
ENUMS.Storage.weapons.shells._50Browning_API_M8_Corsair = 'weapons.shells.50Browning_API_M8_Corsair'
ENUMS.Storage.weapons.adapters.OH58D_M260 = 'weapons.adapters.OH58D_M260'
ENUMS.Storage.weapons.missiles.Rb05A = 'weapons.missiles.Rb 05A'
ENUMS.Storage.weapons.adapters.HB_F14_EXT_SHOULDER_PHX_L = 'weapons.adapters.HB_F14_EXT_SHOULDER_PHX_L'
ENUMS.Storage.weapons.shells.MG_13x64_HEI_T = 'weapons.shells.MG_13x64_HEI_T'
ENUMS.Storage.weapons.droptanks.M2KC_08_RPL541_EMPTY = 'weapons.droptanks.M2KC_08_RPL541_EMPTY'
ENUMS.Storage.weapons.missiles.HQ16 = 'weapons.missiles.HQ-16'
ENUMS.Storage.weapons.nurs.SMERCH_9M55F = 'weapons.nurs.SMERCH_9M55F'
ENUMS.Storage.weapons.nurs.M26 = 'weapons.nurs.M26'
ENUMS.Storage.weapons.shells._2A38_30_AP = 'weapons.shells.2A38_30_AP'
ENUMS.Storage.weapons.missiles.LS_6 = 'weapons.missiles.LS_6'
ENUMS.Storage.weapons.containers.EclairM_60 = 'weapons.containers.{EclairM_60}'
ENUMS.Storage.weapons.bombs.FAB_100 = 'weapons.bombs.FAB_100'
ENUMS.Storage.weapons.missiles.MALUTKA = 'weapons.missiles.MALUTKA'
ENUMS.Storage.weapons.containers.HB_ALE_40_0_120 = 'weapons.containers.HB_ALE_40_0_120'
ENUMS.Storage.weapons.bombs.M485_FLARE = 'weapons.bombs.M485_FLARE'
ENUMS.Storage.weapons.nurs.AGR_20_M282_unguided = 'weapons.nurs.AGR_20_M282_unguided'
ENUMS.Storage.weapons.droptanks.F15E_Drop_Tank = 'weapons.droptanks.F-15E_Drop_Tank'
ENUMS.Storage.weapons.shells._20mm_M70LD_SAPHEI = 'weapons.shells.20mm_M70LD_SAPHEI'
ENUMS.Storage.weapons.adapters.CHAP_Mi28N_ataka = 'weapons.adapters.CHAP_Mi28N_ataka'
ENUMS.Storage.weapons.bombs.GBU_30 = 'weapons.bombs.GBU_30'
ENUMS.Storage.weapons.bombs.AGM_62_I = 'weapons.bombs.AGM_62_I'
ENUMS.Storage.weapons.bombs.BETAB500S = 'weapons.bombs.BETAB-500S'
ENUMS.Storage.weapons.shells.ZTZ_125_HE = 'weapons.shells.ZTZ_125_HE'
ENUMS.Storage.weapons.shells.HP30_30_AP = 'weapons.shells.HP30_30_AP'
ENUMS.Storage.weapons.missiles.SM_6 = 'weapons.missiles.SM_6'
ENUMS.Storage.weapons.gunmounts.MINIGUN = 'weapons.gunmounts.MINIGUN'
ENUMS.Storage.weapons.bombs.CBU_87 = 'weapons.bombs.CBU_87'
ENUMS.Storage.weapons.adapters.B8V20A = 'weapons.adapters.B-8V20A'
ENUMS.Storage.weapons.containers.AN_ASQ_228 = 'weapons.containers.AN_ASQ_228'
ENUMS.Storage.weapons.missiles.Sea_Dart = 'weapons.missiles.Sea_Dart'
ENUMS.Storage.weapons.adapters.apu13mt = 'weapons.adapters.apu-13mt'
ENUMS.Storage.weapons.adapters.HB_ORD_Missile_Well_Adapter = 'weapons.adapters.HB_ORD_Missile_Well_Adapter'
ENUMS.Storage.weapons.shells.AK176_76 = 'weapons.shells.AK176_76'
ENUMS.Storage.weapons.missiles.X_29T = 'weapons.missiles.X_29T'
ENUMS.Storage.weapons.nurs.HYDRA_70_MK61 = 'weapons.nurs.HYDRA_70_MK61'
ENUMS.Storage.weapons.shells.M393A3_105_HE = 'weapons.shells.M393A3_105_HE'
ENUMS.Storage.weapons.bombs.AN_M57 = 'weapons.bombs.AN_M57'
ENUMS.Storage.weapons.missiles.AIM_7 = 'weapons.missiles.AIM_7'
ENUMS.Storage.weapons.gunmounts.GIAT_M621_SAPHEI = 'weapons.gunmounts.{GIAT_M621_SAPHEI}'
ENUMS.Storage.weapons.containers.MATRAPHIMAT = 'weapons.containers.MATRA-PHIMAT'
ENUMS.Storage.weapons.shells.M61_20_AP = 'weapons.shells.M61_20_AP'
ENUMS.Storage.weapons.droptanks.droptank_150_gal = 'weapons.droptanks.droptank_150_gal'
ENUMS.Storage.weapons.missiles.SA48H6E2 = 'weapons.missiles.SA48H6E2'
ENUMS.Storage.weapons.nurs.HVARUSNMk28Mod4 = 'weapons.nurs.HVAR USN Mk28 Mod4'
ENUMS.Storage.weapons.adapters.KMGU2 = 'weapons.adapters.KMGU-2'
ENUMS.Storage.weapons.missiles.C_701T = 'weapons.missiles.C_701T'
ENUMS.Storage.weapons.shells.DM53_120_AP = 'weapons.shells.DM53_120_AP'
ENUMS.Storage.weapons.adapters._9M114PYLON_EMPTY = 'weapons.adapters.9M114-PYLON_EMPTY'
ENUMS.Storage.weapons.missiles.P_500 = 'weapons.missiles.P_500'
ENUMS.Storage.weapons.bombs.S_8OM_FLARE = 'weapons.bombs.S_8OM_FLARE'
ENUMS.Storage.weapons.adapters.LAU115C2_LAU127 = 'weapons.adapters.LAU-115C+2_LAU127'
ENUMS.Storage.weapons.shells.M256_120_HE = 'weapons.shells.M256_120_HE'
ENUMS.Storage.weapons.shells._7_62x51tr = 'weapons.shells.7_62x51tr'
ENUMS.Storage.weapons.adapters.adapter_gdj_kd63 = 'weapons.adapters.adapter_gdj_kd63'
ENUMS.Storage.weapons.missiles.CM802AKG = 'weapons.missiles.CM-802AKG'
ENUMS.Storage.weapons.missiles.C_802AK = 'weapons.missiles.C_802AK'
ENUMS.Storage.weapons.bombs.GBU_39 = 'weapons.bombs.GBU_39'
ENUMS.Storage.weapons.bombs.BETAB500M = 'weapons.bombs.BETAB-500M'
ENUMS.Storage.weapons.adapters.LAU117 = 'weapons.adapters.LAU-117'
ENUMS.Storage.weapons.missiles.BK90_MJ1 = 'weapons.missiles.BK90_MJ1'
ENUMS.Storage.weapons.missiles.R60 = 'weapons.missiles.R-60'
ENUMS.Storage.weapons.shells.PJ26_76_PFHE = 'weapons.shells.PJ26_76_PFHE'
ENUMS.Storage.weapons.nurs.AGR_20_M151_unguided = 'weapons.nurs.AGR_20_M151_unguided'
ENUMS.Storage.weapons.shells.HEDPM430 = 'weapons.shells.HEDPM430'
ENUMS.Storage.weapons.shells.GSH_23_HE = 'weapons.shells.GSH_23_HE'
ENUMS.Storage.weapons.gunmounts.CC420_GUN_POD = 'weapons.gunmounts.{CC420_GUN_POD}'
ENUMS.Storage.weapons.shells.Hispano_Mk_II_SAPI = 'weapons.shells.Hispano_Mk_II_SAP/I'
ENUMS.Storage.weapons.adapters.Spitfire_pilon2L = 'weapons.adapters.Spitfire_pilon2L'
ENUMS.Storage.weapons.bombs.RBK_500SOAB = 'weapons.bombs.RBK_500SOAB'
ENUMS.Storage.weapons.bombs.M_117 = 'weapons.bombs.M_117'
ENUMS.Storage.weapons.missiles.SPIKE_ER2 = 'weapons.missiles.SPIKE_ER2'
ENUMS.Storage.weapons.bombs.BDU_45LGB = 'weapons.bombs.BDU_45LGB'
ENUMS.Storage.weapons.missiles.AGM_65H = 'weapons.missiles.AGM_65H'
ENUMS.Storage.weapons.adapters.adapter_df4b = 'weapons.adapters.adapter_df4b'
ENUMS.Storage.weapons.nurs.SNEB_TYPE252_F1B = 'weapons.nurs.SNEB_TYPE252_F1B'
ENUMS.Storage.weapons.droptanks._800LTank = 'weapons.droptanks.800L Tank'
ENUMS.Storage.weapons.missiles.X_31A = 'weapons.missiles.X_31A'
ENUMS.Storage.weapons.containers.LANTIRNF14TARGET = 'weapons.containers.LANTIRN-F14-TARGET'
ENUMS.Storage.weapons.bombs.CBU_52B = 'weapons.bombs.CBU_52B'
ENUMS.Storage.weapons.adapters.b52mbd_mk84 = 'weapons.adapters.b52-mbd_mk84'
ENUMS.Storage.weapons.adapters.J11A_twinpylon_l = 'weapons.adapters.J-11A_twinpylon_l'
ENUMS.Storage.weapons.gunmounts.MB339_DEFA553_R = 'weapons.gunmounts.{MB339_DEFA553_R}'
ENUMS.Storage.weapons.containers.BARAX = 'weapons.containers.BARAX'
ENUMS.Storage.weapons.shells.DEFA554_30_HE = 'weapons.shells.DEFA554_30_HE'
ENUMS.Storage.weapons.droptanks.i16_eft = 'weapons.droptanks.i16_eft'
ENUMS.Storage.weapons.bombs.BLU3B_GROUP = 'weapons.bombs.BLU-3B_GROUP'
ENUMS.Storage.weapons.missiles.Sea_Cat = 'weapons.missiles.Sea_Cat'
ENUMS.Storage.weapons.adapters.aero3b = 'weapons.adapters.aero-3b'
ENUMS.Storage.weapons.nurs.SNEB_TYPE251_F1B = 'weapons.nurs.SNEB_TYPE251_F1B'
ENUMS.Storage.weapons.missiles.FIM_92C = 'weapons.missiles.FIM_92C'
ENUMS.Storage.weapons.missiles.SM_2ER = 'weapons.missiles.SM_2ER'
ENUMS.Storage.weapons.missiles.AGM_114K = 'weapons.missiles.AGM_114K'
ENUMS.Storage.weapons.bombs.AB_250_2_SD_10A = 'weapons.bombs.AB_250_2_SD_10A'
ENUMS.Storage.weapons.missiles.X_65 = 'weapons.missiles.X_65'
ENUMS.Storage.weapons.bombs.British_GP_500LB_Bomb_Mk4 = 'weapons.bombs.British_GP_500LB_Bomb_Mk4'
ENUMS.Storage.weapons.shells._50Browning_Ball_M2 = 'weapons.shells.50Browning_Ball_M2'
ENUMS.Storage.weapons.containers.HB_F14_EXT_TARPS = 'weapons.containers.HB_F14_EXT_TARPS'
ENUMS.Storage.weapons.gunmounts.PKT_7_62 = 'weapons.gunmounts.PKT_7_62'
ENUMS.Storage.weapons.shells._50Browning_I_M1 = 'weapons.shells.50Browning_I_M1'
ENUMS.Storage.weapons.shells.British303_Ball_Mk8 = 'weapons.shells.British303_Ball_Mk8'
ENUMS.Storage.weapons.adapters.F4PILON = 'weapons.adapters.F4-PILON'
ENUMS.Storage.weapons.missiles.P_77 = 'weapons.missiles.P_77'
ENUMS.Storage.weapons.missiles.SA9M338K = 'weapons.missiles.SA9M338K'
ENUMS.Storage.weapons.shells.ZTZ_7_62 = 'weapons.shells.ZTZ_7_62'
ENUMS.Storage.weapons.shells.Mauser7_92x57_B = 'weapons.shells.Mauser7.92x57_B.'
ENUMS.Storage.weapons.missiles.X_28 = 'weapons.missiles.X_28'
ENUMS.Storage.weapons.missiles.KD_20 = 'weapons.missiles.KD_20'
ENUMS.Storage.weapons.missiles.TGM_65G = 'weapons.missiles.TGM_65G'
ENUMS.Storage.weapons.adapters.mbd4 = 'weapons.adapters.mbd-4'
ENUMS.Storage.weapons.shells.Mauser7_92x57_S_m_K_ = 'weapons.shells.Mauser7.92x57_S.m.K.'
ENUMS.Storage.weapons.missiles.M39A1 = 'weapons.missiles.M39A1'
ENUMS.Storage.weapons.adapters.m559 = 'weapons.adapters.m559'
ENUMS.Storage.weapons.missiles.AGM_12B = 'weapons.missiles.AGM_12B'
ENUMS.Storage.weapons.shells.M39_20_HEI = 'weapons.shells.M39_20_HEI'
ENUMS.Storage.weapons.bombs.British_GP_500LB_Bomb_Mk4_Short = 'weapons.bombs.British_GP_500LB_Bomb_Mk4_Short'
ENUMS.Storage.weapons.missiles.Rb15F = 'weapons.missiles.Rb 15F'
ENUMS.Storage.weapons.missiles.AIM_120C = 'weapons.missiles.AIM_120C'
ENUMS.Storage.weapons.shells.Mauser7_92x57_SmK_Lspurweiss = "weapons.shells.Mauser7.92x57_S.m.K._L'spur(weiss)"
ENUMS.Storage.weapons.nurs.S_5KP = 'weapons.nurs.S_5KP'
ENUMS.Storage.weapons.bombs.GBU_31_V_4B = 'weapons.bombs.GBU_31_V_4B'
ENUMS.Storage.weapons.missiles.HQ7B = 'weapons.missiles.HQ-7B'
ENUMS.Storage.weapons.bombs.ODAB500PM = 'weapons.bombs.ODAB-500PM'
ENUMS.Storage.weapons.bombs.BAP100 = 'weapons.bombs.BAP-100'
ENUMS.Storage.weapons.shells.MK_108_MGsch = 'weapons.shells.MK_108_MGsch'
ENUMS.Storage.weapons.bombs.British_MC_500LB_Bomb_Mk1_Short = 'weapons.bombs.British_MC_500LB_Bomb_Mk1_Short'
ENUMS.Storage.weapons.adapters.BRU42_LS_LAU131 = 'weapons.adapters.BRU-42_LS_(LAU-131)'
ENUMS.Storage.weapons.containers.SHPIL = 'weapons.containers.SHPIL'
ENUMS.Storage.weapons.torpedoes.Mark_46 = 'weapons.torpedoes.Mark_46'
ENUMS.Storage.weapons.bombs.SAB_100MN = 'weapons.bombs.SAB_100MN'
ENUMS.Storage.weapons.missiles.SA3M9M = 'weapons.missiles.SA3M9M'
ENUMS.Storage.weapons.adapters.LAU61 = 'weapons.adapters.LAU-61'
ENUMS.Storage.weapons.adapters.mer2 = 'weapons.adapters.mer2'
ENUMS.Storage.weapons.shells.ship_Bofors_40mm_HE = 'weapons.shells.ship_Bofors_40mm_HE'
ENUMS.Storage.weapons.nurs.S24A = 'weapons.nurs.S-24A'
ENUMS.Storage.weapons.shells.GSh_30_2K_AP_Tr = 'weapons.shells.GSh_30_2K_AP_Tr'
ENUMS.Storage.weapons.missiles.AIM7F = 'weapons.missiles.AIM-7F'
ENUMS.Storage.weapons.shells.M383 = 'weapons.shells.M383'
ENUMS.Storage.weapons.nurs.HYDRA_70_M257 = 'weapons.nurs.HYDRA_70_M257'
ENUMS.Storage.weapons.droptanks.PTB_580G_F1 = 'weapons.droptanks.PTB_580G_F1'
ENUMS.Storage.weapons.gunmounts.C101DEFA553 = 'weapons.gunmounts.{C-101-DEFA553}'
ENUMS.Storage.weapons.missiles.MICA_R = 'weapons.missiles.MICA_R'
ENUMS.Storage.weapons.shells.M53_APT_RED = 'weapons.shells.M53_APT_RED'
ENUMS.Storage.weapons.missiles.AIM9P5 = 'weapons.missiles.AIM-9P5'
ENUMS.Storage.weapons.adapters._306M2 = 'weapons.adapters.30-6-M2'
ENUMS.Storage.weapons.shells._75mm_AA_JAP = 'weapons.shells.75mm_AA_JAP'
ENUMS.Storage.weapons.nurs.TinyTim = 'weapons.nurs.Tiny Tim'
ENUMS.Storage.weapons.missiles.X_22 = 'weapons.missiles.X_22'
ENUMS.Storage.weapons.nurs.S25O = 'weapons.nurs.S-25-O'
ENUMS.Storage.weapons.missiles.X_101 = 'weapons.missiles.X_101'
ENUMS.Storage.weapons.missiles.AIM_54A_Mk47 = 'weapons.missiles.AIM_54A_Mk47'
ENUMS.Storage.weapons.containers.ECM_POD_L_175V = 'weapons.containers.{ECM_POD_L_175V}'
ENUMS.Storage.weapons.shells._2A28_73 = 'weapons.shells.2A28_73'
ENUMS.Storage.weapons.shells.GAU8_30_AP = 'weapons.shells.GAU8_30_AP'
ENUMS.Storage.weapons.shells.British303_Ball_Mk1c = 'weapons.shells.British303_Ball_Mk1c'
ENUMS.Storage.weapons.missiles.AIM_9 = 'weapons.missiles.AIM_9'
ENUMS.Storage.weapons.missiles.SD10 = 'weapons.missiles.SD-10'
ENUMS.Storage.weapons.droptanks.M2KC_RPL_522 = 'weapons.droptanks.M2KC_RPL_522'
ENUMS.Storage.weapons.missiles.AGM_130 = 'weapons.missiles.AGM_130'
ENUMS.Storage.weapons.gunmounts.defa_553 = 'weapons.gunmounts.defa_553'
ENUMS.Storage.weapons.nurs.BRM1_90MM_UG = 'weapons.nurs.BRM1_90MM_UG'
ENUMS.Storage.weapons.gunmounts.CH47_STBD_M60D = 'weapons.gunmounts.{CH47_STBD_M60D}'
ENUMS.Storage.weapons.adapters.LAU10 = 'weapons.adapters.LAU-10'
ENUMS.Storage.weapons.shells.L31_120mm_HESH = 'weapons.shells.L31_120mm_HESH'
ENUMS.Storage.weapons.gunmounts.CH47_AFT_M60D = 'weapons.gunmounts.{CH47_AFT_M60D}'
ENUMS.Storage.weapons.shells._20mm_M53_API = 'weapons.shells.20mm_M53_API'
ENUMS.Storage.weapons.adapters.HB_F14_EXT_LAU7 = 'weapons.adapters.HB_F14_EXT_LAU-7'
ENUMS.Storage.weapons.shells.CHAP_76_PFHE = 'weapons.shells.CHAP_76_PFHE'
ENUMS.Storage.weapons.bombs.KAB_500KrOD = 'weapons.bombs.KAB_500KrOD'
ENUMS.Storage.weapons.adapters.PU_9S846_STRELEC = 'weapons.adapters.PU_9S846_STRELEC'
ENUMS.Storage.weapons.containers.EclairM_51 = 'weapons.containers.{EclairM_51}'
ENUMS.Storage.weapons.containers.HB_ORD_Pave_Spike = 'weapons.containers.HB_ORD_Pave_Spike'
ENUMS.Storage.weapons.shells.MINGR55_NO_TRC = 'weapons.shells.MINGR55_NO_TRC'
ENUMS.Storage.weapons.nurs.PG_9V = 'weapons.nurs.PG_9V'
ENUMS.Storage.weapons.gunmounts.M61A1 = 'weapons.gunmounts.M-61A1'
ENUMS.Storage.weapons.nurs.PG_16V = 'weapons.nurs.PG_16V'
ENUMS.Storage.weapons.shells.British303_G_Mk4 = 'weapons.shells.British303_G_Mk4'
ENUMS.Storage.weapons.missiles.SA5B55 = 'weapons.missiles.SA5B55'
ENUMS.Storage.weapons.adapters.b52_CSRL_ALCM = 'weapons.adapters.b-52_CSRL_ALCM'
ENUMS.Storage.weapons.adapters._9M114PILON = 'weapons.adapters.9M114-PILON'
ENUMS.Storage.weapons.shells._50Browning_APIT_M20_Corsair = 'weapons.shells.50Browning_APIT_M20_Corsair'
ENUMS.Storage.weapons.shells.PJ87_100_PFHE = 'weapons.shells.PJ87_100_PFHE'
ENUMS.Storage.weapons.bombs._2503 = 'weapons.bombs.250-3'
ENUMS.Storage.weapons.shells._2A42_30_AP = 'weapons.shells.2A42_30_AP'
ENUMS.Storage.weapons.shells._37mm_Type_100_JAP = 'weapons.shells.37mm_Type_100_JAP'
ENUMS.Storage.weapons.droptanks.oiltank = 'weapons.droptanks.oiltank'
ENUMS.Storage.weapons.droptanks.AV8BNA_AERO1D = 'weapons.droptanks.AV8BNA_AERO1D'
ENUMS.Storage.weapons.containers.smoke_pod = 'weapons.containers.smoke_pod'
ENUMS.Storage.weapons.missiles.AGM_12A = 'weapons.missiles.AGM_12A'
ENUMS.Storage.weapons.missiles.MICA_T = 'weapons.missiles.MICA_T'
ENUMS.Storage.weapons.droptanks._1100LTankEmpty = 'weapons.droptanks.1100L Tank Empty'
ENUMS.Storage.weapons.adapters.CHAP_Mi28N_igla = 'weapons.adapters.CHAP_Mi28N_igla'
ENUMS.Storage.weapons.bombs.GBU_15_V_1_B = 'weapons.bombs.GBU_15_V_1_B'
ENUMS.Storage.weapons.missiles.Rb24 = 'weapons.missiles.Rb 24'
ENUMS.Storage.weapons.missiles.RB75 = 'weapons.missiles.RB75'
ENUMS.Storage.weapons.shells.M2_12_7_T = 'weapons.shells.M2_12_7_T'
ENUMS.Storage.weapons.shells._2A42_30_HE = 'weapons.shells.2A42_30_HE'
ENUMS.Storage.weapons.containers.HVAR_rocket = 'weapons.containers.HVAR_rocket'
ENUMS.Storage.weapons.gunmounts.GIAT_M621_APHE = 'weapons.gunmounts.{GIAT_M621_APHE}'
ENUMS.Storage.weapons.nurs.SNEB_TYPE253_F1B = 'weapons.nurs.SNEB_TYPE253_F1B'
ENUMS.Storage.weapons.shells.M230_HEIM799 = 'weapons.shells.M230_HEI M799'
ENUMS.Storage.weapons.containers.HB_F14_EXT_BRU34 = 'weapons.containers.HB_F14_EXT_BRU34'
ENUMS.Storage.weapons.shells.Sprgr_34_L48 = 'weapons.shells.Sprgr_34_L48'
ENUMS.Storage.weapons.shells._7_62x39 = 'weapons.shells.7_62x39'
ENUMS.Storage.weapons.containers.LANTIRN = 'weapons.containers.LANTIRN'
ENUMS.Storage.weapons.shells.GSH23_23_HE = 'weapons.shells.GSH23_23_HE'
ENUMS.Storage.weapons.bombs.KAB_1500Kr = 'weapons.bombs.KAB_1500Kr'
ENUMS.Storage.weapons.bombs.British_MC_250LB_Bomb_Mk1 = 'weapons.bombs.British_MC_250LB_Bomb_Mk1'
ENUMS.Storage.weapons.gunmounts.ANM3 = 'weapons.gunmounts.{AN-M3}'
ENUMS.Storage.weapons.droptanks.Spitfire_tank_1 = 'weapons.droptanks.Spitfire_tank_1'
ENUMS.Storage.weapons.missiles.AGM_78B = 'weapons.missiles.AGM_78B'
ENUMS.Storage.weapons.adapters.hj12launchertube = 'weapons.adapters.hj12-launcher-tube'
ENUMS.Storage.weapons.shells.M242_25_HE_M792 = 'weapons.shells.M242_25_HE_M792'
ENUMS.Storage.weapons.shells.M46 = 'weapons.shells.M46'
ENUMS.Storage.weapons.droptanks.HB_F14_EXT_DROPTANK_EMPTY = 'weapons.droptanks.HB_F14_EXT_DROPTANK_EMPTY'
ENUMS.Storage.weapons.missiles.AIM_120 = 'weapons.missiles.AIM_120'
ENUMS.Storage.weapons.missiles.Rb15FforA_I__ = 'weapons.missiles.Rb 15F (for A.I.)'
ENUMS.Storage.weapons.gunmounts.NR23 = 'weapons.gunmounts.NR-23'
ENUMS.Storage.weapons.missiles.Vikhr_M = 'weapons.missiles.Vikhr_M'
ENUMS.Storage.weapons.bombs.Mk_83 = 'weapons.bombs.Mk_83'
ENUMS.Storage.weapons.adapters._9m114pilon = 'weapons.adapters.9m114-pilon'
ENUMS.Storage.weapons.bombs.RBK_500U_OAB_2_5RT = 'weapons.bombs.RBK_500U_OAB_2_5RT'
ENUMS.Storage.weapons.shells._50Browning_AP_M2_Corsair = 'weapons.shells.50Browning_AP_M2_Corsair'
ENUMS.Storage.weapons.shells.British303_G_Mk2 = 'weapons.shells.British303_G_Mk2'
ENUMS.Storage.weapons.gunmounts.UPK_23_25 = 'weapons.gunmounts.UPK_23_25'
ENUMS.Storage.weapons.shells.M242_25_AP_M919 = 'weapons.shells.M242_25_AP_M919'
ENUMS.Storage.weapons.bombs.Type_200A = 'weapons.bombs.Type_200A'
ENUMS.Storage.weapons.containers.SORBCIJA_L = 'weapons.containers.SORBCIJA_L'
ENUMS.Storage.weapons.shells.M322_120_AP = 'weapons.shells.M322_120_AP'
ENUMS.Storage.weapons.missiles.AGR_20A = 'weapons.missiles.AGR_20A'
ENUMS.Storage.weapons.missiles._9M723 = 'weapons.missiles.9M723'
ENUMS.Storage.weapons.bombs.BKF_AO2_5RT = 'weapons.bombs.BKF_AO2_5RT'
ENUMS.Storage.weapons.missiles.P_33E = 'weapons.missiles.P_33E'
ENUMS.Storage.weapons.adapters.b52mbd_m117 = 'weapons.adapters.b52-mbd_m117'
ENUMS.Storage.weapons.missiles.Ataka_9M120 = 'weapons.missiles.Ataka_9M120'
ENUMS.Storage.weapons.bombs.MK76 = 'weapons.bombs.MK76'
ENUMS.Storage.weapons.bombs.AB_250_2_SD_2 = 'weapons.bombs.AB_250_2_SD_2'
ENUMS.Storage.weapons.adapters.OH58D_HRACK_R = 'weapons.adapters.OH58D_HRACK_R'
ENUMS.Storage.weapons.missiles.AGM_78A = 'weapons.missiles.AGM_78A'
ENUMS.Storage.weapons.bombs.FAB_100SV = 'weapons.bombs.FAB_100SV'
ENUMS.Storage.weapons.adapters.F4E_dual_LAU7 = 'weapons.adapters.F4E_dual_LAU7'
ENUMS.Storage.weapons.shells.CHAP_76_HE_T = 'weapons.shells.CHAP_76_HE_T'
ENUMS.Storage.weapons.adapters.HB_F14_EXT_SPARROW_PYLON = 'weapons.adapters.HB_F14_EXT_SPARROW_PYLON'
ENUMS.Storage.weapons.missiles.P_27PE = 'weapons.missiles.P_27PE'
ENUMS.Storage.weapons.shells._2A38_30_HE = 'weapons.shells.2A38_30_HE'
ENUMS.Storage.weapons.nurs.WGr21 = 'weapons.nurs.WGr21'
ENUMS.Storage.weapons.droptanks.HB_F4E_EXT_WingTank_R_EMPTY = 'weapons.droptanks.HB_F-4E_EXT_WingTank_R_EMPTY'
ENUMS.Storage.weapons.shells.British303_G_Mk5 = 'weapons.shells.British303_G_Mk5'
ENUMS.Storage.weapons.gunmounts.SUU_23_POD = 'weapons.gunmounts.{SUU_23_POD}'
ENUMS.Storage.weapons.bombs.British_GP_250LB_Bomb_Mk1 = 'weapons.bombs.British_GP_250LB_Bomb_Mk1'
ENUMS.Storage.weapons.bombs.RBK_500U_BETAB_M = 'weapons.bombs.RBK_500U_BETAB_M'
ENUMS.Storage.weapons.gunmounts.SA342_M134_SIDE_R = 'weapons.gunmounts.{SA342_M134_SIDE_R}'
ENUMS.Storage.weapons.adapters.LAU_127 = 'weapons.adapters.LAU_127'
ENUMS.Storage.weapons.missiles.TGM_65D = 'weapons.missiles.TGM_65D'
ENUMS.Storage.weapons.shells.ZTZ_125_AP = 'weapons.shells.ZTZ_125_AP'
ENUMS.Storage.weapons.missiles.P_73 = 'weapons.missiles.P_73'
ENUMS.Storage.weapons.gunmounts.M134_R = 'weapons.gunmounts.M134_R'
ENUMS.Storage.weapons.shells.M39_20_TP = 'weapons.shells.M39_20_TP'
ENUMS.Storage.weapons.shells.GAU8_30_HE = 'weapons.shells.GAU8_30_HE'
ENUMS.Storage.weapons.bombs.GBU_12 = 'weapons.bombs.GBU_12'
ENUMS.Storage.weapons.bombs.SC_250_T3_J = 'weapons.bombs.SC_250_T3_J'
ENUMS.Storage.weapons.gunmounts.OH_58_BRAUNING = 'weapons.gunmounts.OH_58_BRAUNING'
ENUMS.Storage.weapons.shells.KDA_35_AP = 'weapons.shells.KDA_35_AP'
ENUMS.Storage.weapons.shells.CL3143_120_AP = 'weapons.shells.CL3143_120_AP'
ENUMS.Storage.weapons.shells.M61_20_TP_T = 'weapons.shells.M61_20_TP_T'
ENUMS.Storage.weapons.containers.ANAWW_13 = 'weapons.containers.ANAWW_13'
ENUMS.Storage.weapons.droptanks.droptank_108_gal = 'weapons.droptanks.droptank_108_gal'
ENUMS.Storage.weapons.containers.US_M10_SMOKE_TANK_BLUE = 'weapons.containers.{US_M10_SMOKE_TANK_BLUE}'
ENUMS.Storage.weapons.missiles.GAR8 = 'weapons.missiles.GAR-8'
ENUMS.Storage.weapons.missiles.ASM_N_2 = 'weapons.missiles.ASM_N_2'
ENUMS.Storage.weapons.bombs.BR_250 = 'weapons.bombs.BR_250'
ENUMS.Storage.weapons.containers.F18FLIRPOD = 'weapons.containers.F-18-FLIR-POD'
ENUMS.Storage.weapons.containers.EclairM_42 = 'weapons.containers.{EclairM_42}'
ENUMS.Storage.weapons.missiles.P_27P = 'weapons.missiles.P_27P'
ENUMS.Storage.weapons.bombs.British_SAP_500LB_Bomb_Mk5 = 'weapons.bombs.British_SAP_500LB_Bomb_Mk5'
ENUMS.Storage.weapons.shells.NR23_23x115_API = 'weapons.shells.NR23_23x115_API'
ENUMS.Storage.weapons.shells.KPVT_14_5 = 'weapons.shells.KPVT_14_5'
ENUMS.Storage.weapons.gunmounts.M60_SIDE_L = 'weapons.gunmounts.M60_SIDE_L'
ENUMS.Storage.weapons.nurs.S5M1_HEFRAG_FFAR = 'weapons.nurs.S5M1_HEFRAG_FFAR'
ENUMS.Storage.weapons.bombs.SAB_100_FLARE = 'weapons.bombs.SAB_100_FLARE'
ENUMS.Storage.weapons.adapters.HB_F4E_BRU42 = 'weapons.adapters.HB_F-4E_BRU-42'
ENUMS.Storage.weapons.containers.F15E_AAQ33_XR_ATPSE = 'weapons.containers.F-15E_AAQ-33_XR_ATP-SE'
ENUMS.Storage.weapons.adapters.MBD267 = 'weapons.adapters.MBD-2-67'
ENUMS.Storage.weapons.adapters.OH58D_SRACK_R = 'weapons.adapters.OH58D_SRACK_R'
ENUMS.Storage.weapons.adapters.UB16 = 'weapons.adapters.UB-16'
ENUMS.Storage.weapons.nurs.HYDRA_70_WTU1B = 'weapons.nurs.HYDRA_70_WTU1B'
ENUMS.Storage.weapons.shells.L14A2_30_APDS = 'weapons.shells.L14A2_30_APDS'
ENUMS.Storage.weapons.missiles.SVIR = 'weapons.missiles.SVIR'
ENUMS.Storage.weapons.adapters.APU170 = 'weapons.adapters.APU-170'
ENUMS.Storage.weapons.missiles.AIM9E = 'weapons.missiles.AIM-9E'
ENUMS.Storage.weapons.adapters.adapter_df4a = 'weapons.adapters.adapter_df4a'
ENUMS.Storage.weapons.missiles.Super_530F = 'weapons.missiles.Super_530F'
ENUMS.Storage.weapons.adapters.Rocket_Launcher_4_5inch = 'weapons.adapters.Rocket_Launcher_4_5inch'
ENUMS.Storage.weapons.adapters.JF17_PF12_twin = 'weapons.adapters.JF-17_PF12_twin'
ENUMS.Storage.weapons.adapters.CLB_30 = 'weapons.adapters.CLB_30'
ENUMS.Storage.weapons.gunmounts.KORD_12_7_MI24_R = 'weapons.gunmounts.KORD_12_7_MI24_R'
ENUMS.Storage.weapons.gunmounts.KORD_12_7_MI24_L = 'weapons.gunmounts.KORD_12_7_MI24_L'
ENUMS.Storage.weapons.adapters._9M120_pylon = 'weapons.adapters.9M120_pylon'
ENUMS.Storage.weapons.missiles.REFLEX = 'weapons.missiles.REFLEX'
ENUMS.Storage.weapons.adapters.oro57k_edm = 'weapons.adapters.oro-57k.edm'
ENUMS.Storage.weapons.bombs.GBU_31_V_2B = 'weapons.bombs.GBU_31_V_2B'
ENUMS.Storage.weapons.missiles.P_40T = 'weapons.missiles.P_40T'
ENUMS.Storage.weapons.adapters.suu25 = 'weapons.adapters.suu-25'
ENUMS.Storage.weapons.missiles.GB6 = 'weapons.missiles.GB-6'
ENUMS.Storage.weapons.missiles.DWS39_MJ1 = 'weapons.missiles.DWS39_MJ1'
ENUMS.Storage.weapons.bombs.FAB_250 = 'weapons.bombs.FAB_250'
ENUMS.Storage.weapons.bombs.SD_500_A = 'weapons.bombs.SD_500_A'
ENUMS.Storage.weapons.gunmounts.M60_SIDE_R = 'weapons.gunmounts.M60_SIDE_R'
ENUMS.Storage.weapons.shells.L21A1_30_HE = 'weapons.shells.L21A1_30_HE'
ENUMS.Storage.weapons.missiles.KD_63 = 'weapons.missiles.KD_63'
ENUMS.Storage.weapons.gunmounts.GAU_12_Equalizer_HE = 'weapons.gunmounts.{GAU_12_Equalizer_HE}'
ENUMS.Storage.weapons.bombs.ROCKEYE = 'weapons.bombs.ROCKEYE'
ENUMS.Storage.weapons.shells.GSh_30_2K_HE = 'weapons.shells.GSh_30_2K_HE'
ENUMS.Storage.weapons.adapters.LAU3 = 'weapons.adapters.LAU-3'
ENUMS.Storage.weapons.shells.M39_20_API = 'weapons.shells.M39_20_API'
ENUMS.Storage.weapons.nurs.HVAR = 'weapons.nurs.HVAR'
ENUMS.Storage.weapons.adapters.F15E_LAU117 = 'weapons.adapters.F-15E_LAU-117'
ENUMS.Storage.weapons.adapters.SA342_LAU_HOT3_2x = 'weapons.adapters.SA342_LAU_HOT3_2x'
ENUMS.Storage.weapons.droptanks.PTB800MIG21 = 'weapons.droptanks.PTB-800-MIG21'
ENUMS.Storage.weapons.missiles.AGM_114 = 'weapons.missiles.AGM_114'
ENUMS.Storage.weapons.shells._2A46M_125_AP = 'weapons.shells.2A46M_125_AP'
ENUMS.Storage.weapons.droptanks.MB339_TT320_L = 'weapons.droptanks.MB339_TT320_L'
ENUMS.Storage.weapons.shells.M61_20_HEIT_RED = 'weapons.shells.M61_20_HEIT_RED'
ENUMS.Storage.weapons.shells.KS19_100AP = 'weapons.shells.KS19_100AP'
ENUMS.Storage.weapons.containers.KINGAL = 'weapons.containers.KINGAL'
ENUMS.Storage.weapons.nurs.RS82 = 'weapons.nurs.RS-82'
ENUMS.Storage.weapons.missiles.HOT2 = 'weapons.missiles.HOT2'
ENUMS.Storage.weapons.adapters.Schloss_500XIIC = 'weapons.adapters.Schloss_500XIIC'
ENUMS.Storage.weapons.droptanks.fueltank450 = 'weapons.droptanks.fueltank450'
ENUMS.Storage.weapons.missiles.X_59M = 'weapons.missiles.X_59M'
ENUMS.Storage.weapons.droptanks.PTB450 = 'weapons.droptanks.PTB-450'
ENUMS.Storage.weapons.containers.SPS141 = 'weapons.containers.SPS-141'
ENUMS.Storage.weapons.adapters.mbd3 = 'weapons.adapters.mbd-3'
ENUMS.Storage.weapons.bombs.OFAB100120TU = 'weapons.bombs.OFAB-100-120TU'
ENUMS.Storage.weapons.shells._20mm_M56_HEI = 'weapons.shells.20mm_M56_HEI'
ENUMS.Storage.weapons.containers.HB_ALE_40_30_0 = 'weapons.containers.HB_ALE_40_30_0'
ENUMS.Storage.weapons.droptanks.HB_HIGH_PERFORMANCE_CENTERLINE_600_GAL = 'weapons.droptanks.HB_HIGH_PERFORMANCE_CENTERLINE_600_GAL'
ENUMS.Storage.weapons.shells.M61 = 'weapons.shells.M61'
ENUMS.Storage.weapons.missiles.PL12 = 'weapons.missiles.PL-12'
ENUMS.Storage.weapons.missiles.R3R = 'weapons.missiles.R-3R'
ENUMS.Storage.weapons.bombs.GBU_54_V_1B = 'weapons.bombs.GBU_54_V_1B'
ENUMS.Storage.weapons.droptanks.MB339_TT320_R = 'weapons.droptanks.MB339_TT320_R'
ENUMS.Storage.weapons.bombs.GBU_10 = 'weapons.bombs.GBU_10'
ENUMS.Storage.weapons.adapters.b52mbd_agm86 = 'weapons.adapters.b52-mbd_agm86'
ENUMS.Storage.weapons.adapters.Spitfire_pilon2R = 'weapons.adapters.Spitfire_pilon2R'
ENUMS.Storage.weapons.adapters.apu602_R = 'weapons.adapters.apu-60-2_R'
ENUMS.Storage.weapons.shells._50Browning_APIT_M20 = 'weapons.shells.50Browning_APIT_M20'
ENUMS.Storage.weapons.bombs.FAB_50 = 'weapons.bombs.FAB_50'
ENUMS.Storage.weapons.shells._2A46M_125_HE = 'weapons.shells.2A46M_125_HE'
ENUMS.Storage.weapons.containers.sa342_dipole_antenna = 'weapons.containers.sa342_dipole_antenna'
ENUMS.Storage.weapons.shells._50Browning_T_M1 = 'weapons.shells.50Browning_T_M1'
ENUMS.Storage.weapons.bombs.OFAB100Jupiter = 'weapons.bombs.OFAB-100 Jupiter'
ENUMS.Storage.weapons.adapters.MER5E = 'weapons.adapters.MER-5E'
ENUMS.Storage.weapons.shells.NR30_30x155_APT = 'weapons.shells.NR30_30x155_APT'
ENUMS.Storage.weapons.containers.ALQ184 = 'weapons.containers.ALQ-184'
ENUMS.Storage.weapons.missiles.AGM_45B = 'weapons.missiles.AGM_45B'
ENUMS.Storage.weapons.containers.SKY_SHADOW = 'weapons.containers.SKY_SHADOW'
ENUMS.Storage.weapons.gunmounts.FN_HMP400_200 = 'weapons.gunmounts.{FN_HMP400_200}'
ENUMS.Storage.weapons.containers.US_M10_SMOKE_TANK_GREEN = 'weapons.containers.{US_M10_SMOKE_TANK_GREEN}'
ENUMS.Storage.weapons.bombs.BLU3_GROUP = 'weapons.bombs.BLU-3_GROUP'
ENUMS.Storage.weapons.adapters.gdjiv1 = 'weapons.adapters.gdj-iv1'
ENUMS.Storage.weapons.missiles.SPIKE_ER = 'weapons.missiles.SPIKE_ER'
ENUMS.Storage.weapons.shells.AK630_30_AP = 'weapons.shells.AK630_30_AP'
ENUMS.Storage.weapons.missiles.AGM_65L = 'weapons.missiles.AGM_65L'
ENUMS.Storage.weapons.gunmounts.MG_151_20 = 'weapons.gunmounts.MG_151_20'
ENUMS.Storage.weapons.droptanks.PTB490MIG21 = 'weapons.droptanks.PTB-490-MIG21'
ENUMS.Storage.weapons.shells.MG_20x82_HEI_T = 'weapons.shells.MG_20x82_HEI_T'
ENUMS.Storage.weapons.adapters._143M2 = 'weapons.adapters.14-3-M2'
ENUMS.Storage.weapons.adapters.OH58D_Gorgona = 'weapons.adapters.OH-58D_Gorgona'
ENUMS.Storage.weapons.missiles.Rb_04 = 'weapons.missiles.Rb_04'
ENUMS.Storage.weapons.nurs.C_8CM_RD = 'weapons.nurs.C_8CM_RD'
ENUMS.Storage.weapons.missiles.AKD10 = 'weapons.missiles.AKD-10'
ENUMS.Storage.weapons.missiles.X_29L = 'weapons.missiles.X_29L'
ENUMS.Storage.weapons.containers.F14LANTIRNTP = 'weapons.containers.{F14-LANTIRN-TP}'
ENUMS.Storage.weapons.adapters.apu6 = 'weapons.adapters.apu-6'
ENUMS.Storage.weapons.bombs.AO_2_5RT = 'weapons.bombs.AO_2_5RT'
ENUMS.Storage.weapons.shells.L23_120_AP = 'weapons.shells.L23_120_AP'
ENUMS.Storage.weapons.missiles.AIM9L = 'weapons.missiles.AIM-9L'
ENUMS.Storage.weapons.containers.ALQ131 = 'weapons.containers.ALQ-131'
ENUMS.Storage.weapons.shells._25mm_AA_JAP = 'weapons.shells.25mm_AA_JAP'
ENUMS.Storage.weapons.nurs.C_8 = 'weapons.nurs.C_8'
ENUMS.Storage.weapons.missiles.YJ83 = 'weapons.missiles.YJ-83'
ENUMS.Storage.weapons.shells.MK_108_HEI = 'weapons.shells.MK_108_HEI'
ENUMS.Storage.weapons.droptanks.PTB400_MIG19 = 'weapons.droptanks.PTB400_MIG19'
ENUMS.Storage.weapons.adapters.BRU42_LS = 'weapons.adapters.BRU-42_LS'
ENUMS.Storage.weapons.adapters.M299_AGM114 = 'weapons.adapters.M299_AGM114'
ENUMS.Storage.weapons.containers.US_M10_SMOKE_TANK_ORANGE = 'weapons.containers.{US_M10_SMOKE_TANK_ORANGE}'
ENUMS.Storage.weapons.adapters.B1B_Conventional_Rotary_Launcher = 'weapons.adapters.B-1B_Conventional_Rotary_Launcher'
ENUMS.Storage.weapons.nurs.S_5M = 'weapons.nurs.S_5M'
ENUMS.Storage.weapons.shells.MG_13x64_I_T = 'weapons.shells.MG_13x64_I_T'
ENUMS.Storage.weapons.bombs.CBU_99 = 'weapons.bombs.CBU_99'
ENUMS.Storage.weapons.bombs.LUU_2B = 'weapons.bombs.LUU_2B'
ENUMS.Storage.weapons.containers.aaq28LEFTlitening = 'weapons.containers.aaq-28LEFT litening'
ENUMS.Storage.weapons.containers.F4PILON = 'weapons.containers.F4-PILON'
ENUMS.Storage.weapons.missiles.X_25MP = 'weapons.missiles.X_25MP'
ENUMS.Storage.weapons.nurs.SNEB_TYPE252_H1 = 'weapons.nurs.SNEB_TYPE252_H1'
ENUMS.Storage.weapons.adapters.LAU105 = 'weapons.adapters.LAU-105'
ENUMS.Storage.weapons.nurs.FFARMk1HE = 'weapons.nurs.FFAR Mk1 HE'
ENUMS.Storage.weapons.shells.M39_20_TP_T = 'weapons.shells.M39_20_TP_T'
ENUMS.Storage.weapons.containers.FAS = 'weapons.containers.FAS'
ENUMS.Storage.weapons.missiles.X_31P = 'weapons.missiles.X_31P'
ENUMS.Storage.weapons.missiles.R13M = 'weapons.missiles.R-13M'
ENUMS.Storage.weapons.missiles.AGM_154B = 'weapons.missiles.AGM_154B'
ENUMS.Storage.weapons.bombs.BAT120 = 'weapons.bombs.BAT-120'
ENUMS.Storage.weapons.shells.OF_350 = 'weapons.shells.OF_350'
ENUMS.Storage.weapons.adapters.BRU42_LS_LAU68 = 'weapons.adapters.BRU-42_LS_(LAU-68)'
ENUMS.Storage.weapons.shells.M134_7_62_T = 'weapons.shells.M134_7_62_T'
ENUMS.Storage.weapons.shells.DM33_120_AP = 'weapons.shells.DM33_120_AP'
ENUMS.Storage.weapons.shells.M256_120_HE_L55 = 'weapons.shells.M256_120_HE_L55'
ENUMS.Storage.weapons.shells.Hispano_Mk_II_Mk_Z_Ball = 'weapons.shells.Hispano_Mk_II_Mk_Z_Ball'
ENUMS.Storage.weapons.containers.aispodt50_r = 'weapons.containers.ais-pod-t50_r'
ENUMS.Storage.weapons.bombs.GBU_11 = 'weapons.bombs.GBU_11'
ENUMS.Storage.weapons.gunmounts.m3_browning = 'weapons.gunmounts.m3_browning'
ENUMS.Storage.weapons.containers.ah64d_radar = 'weapons.containers.ah-64d_radar'
ENUMS.Storage.weapons.shells.YakB_12_7 = 'weapons.shells.YakB_12_7'
ENUMS.Storage.weapons.nurs.HYDRA_70_M151 = 'weapons.nurs.HYDRA_70_M151'
ENUMS.Storage.weapons.droptanks.fueltank200 = 'weapons.droptanks.fueltank200'
ENUMS.Storage.weapons.adapters.ER4_Rack = 'weapons.adapters.ER4_Rack'
ENUMS.Storage.weapons.containers.HB_ALE_40_30_60 = 'weapons.containers.HB_ALE_40_30_60'
ENUMS.Storage.weapons.bombs.LS_6_100 = 'weapons.bombs.LS_6_100'
ENUMS.Storage.weapons.containers.SORBCIJA_R = 'weapons.containers.SORBCIJA_R'
ENUMS.Storage.weapons.missiles.R13M1 = 'weapons.missiles.R-13M1'
ENUMS.Storage.weapons.missiles.ALARM = 'weapons.missiles.ALARM'
ENUMS.Storage.weapons.gunmounts.AKAN_NO_TRC = 'weapons.gunmounts.{AKAN_NO_TRC}'
ENUMS.Storage.weapons.missiles.RS2US = 'weapons.missiles.RS2US'
ENUMS.Storage.weapons.shells.M230_30 = 'weapons.shells.M230_30'
ENUMS.Storage.weapons.bombs.BLG66_EG = 'weapons.bombs.BLG66_EG'
ENUMS.Storage.weapons.bombs.FAB_500 = 'weapons.bombs.FAB_500'
ENUMS.Storage.weapons.adapters.lau118a = 'weapons.adapters.lau-118a'
ENUMS.Storage.weapons.missiles.BGM_109B = 'weapons.missiles.BGM_109B'
ENUMS.Storage.weapons.missiles.LD10 = 'weapons.missiles.LD-10'
ENUMS.Storage.weapons.shells._120_EXPL_F1_120mm_HE = 'weapons.shells.120_EXPL_F1_120mm_HE'
ENUMS.Storage.weapons.missiles.ROLAND_R = 'weapons.missiles.ROLAND_R'
ENUMS.Storage.weapons.droptanks.PTB300_MIG15 = 'weapons.droptanks.PTB300_MIG15'
ENUMS.Storage.weapons.missiles.SPIKE_ERA = 'weapons.missiles.SPIKE_ERA'
ENUMS.Storage.weapons.adapters.b52_suu67 = 'weapons.adapters.b-52_suu67'
ENUMS.Storage.weapons.shells.VOG17 = 'weapons.shells.VOG17'
ENUMS.Storage.weapons.adapters.JF17_GDJII19L = 'weapons.adapters.JF-17_GDJ-II19L'
ENUMS.Storage.weapons.containers.F4U1D_SMOKE_WHITE = 'weapons.containers.{F4U1D_SMOKE_WHITE}'
ENUMS.Storage.weapons.shells.GSh_30_2K_AP = 'weapons.shells.GSh_30_2K_AP'
ENUMS.Storage.weapons.shells.M61_20_PGU30 = 'weapons.shells.M61_20_PGU30'
ENUMS.Storage.weapons.nurs.HYDRA_70_M274 = 'weapons.nurs.HYDRA_70_M274'
ENUMS.Storage.weapons.bombs.Mk_84 = 'weapons.bombs.Mk_84'
ENUMS.Storage.weapons.bombs.BDU_50LD = 'weapons.bombs.BDU_50LD'
ENUMS.Storage.weapons.gunmounts.A20_TopTurret_M2_R = 'weapons.gunmounts.A20_TopTurret_M2_R'
ENUMS.Storage.weapons.gunmounts.MG_131 = 'weapons.gunmounts.MG_131'
ENUMS.Storage.weapons.adapters.AUF2_RACK = 'weapons.adapters.AUF2_RACK'
ENUMS.Storage.weapons.missiles.Mistral = 'weapons.missiles.Mistral'
ENUMS.Storage.weapons.bombs.LUU_2BB = 'weapons.bombs.LUU_2BB'
ENUMS.Storage.weapons.adapters.JF17_GDJII19R = 'weapons.adapters.JF-17_GDJ-II19R'
ENUMS.Storage.weapons.shells.PGU32_SAPHEI_T = 'weapons.shells.PGU32_SAPHEI_T'
ENUMS.Storage.weapons.adapters.F15E_LAU88 = 'weapons.adapters.F-15E_LAU-88'
ENUMS.Storage.weapons.missiles.AGM_154 = 'weapons.missiles.AGM_154'
ENUMS.Storage.weapons.gunmounts.A20_TopTurret_M2_L = 'weapons.gunmounts.A20_TopTurret_M2_L'
ENUMS.Storage.weapons.missiles.TOW2 = 'weapons.missiles.TOW2'
ENUMS.Storage.weapons.shells.British303_B_Mk6z = 'weapons.shells.British303_B_Mk6z'
ENUMS.Storage.weapons.bombs.P50T = 'weapons.bombs.P-50T'
ENUMS.Storage.weapons.shells._5_56x45_NOtr = 'weapons.shells.5_56x45_NOtr'
ENUMS.Storage.weapons.missiles.SA9M333 = 'weapons.missiles.SA9M333'
ENUMS.Storage.weapons.nurs.HYDRA_70_M259 = 'weapons.nurs.HYDRA_70_M259'
ENUMS.Storage.weapons.shells._50Browning_API_M8 = 'weapons.shells.50Browning_API_M8'
ENUMS.Storage.weapons.missiles.AGM_84E = 'weapons.missiles.AGM_84E'
ENUMS.Storage.weapons.droptanks.FuelTank_350L = 'weapons.droptanks.FuelTank_350L'
ENUMS.Storage.weapons.adapters._9k121 = 'weapons.adapters.9k121'
ENUMS.Storage.weapons.missiles.KD_63B = 'weapons.missiles.KD_63B'
ENUMS.Storage.weapons.droptanks.FuelTank_150L = 'weapons.droptanks.FuelTank_150L'
ENUMS.Storage.weapons.shells._5_45x39 = 'weapons.shells.5_45x39'
ENUMS.Storage.weapons.missiles.AIM_54C_Mk60 = 'weapons.missiles.AIM_54C_Mk60'
ENUMS.Storage.weapons.missiles.CATM_9M = 'weapons.missiles.CATM_9M'
ENUMS.Storage.weapons.droptanks.Drop_Tank_300_Liter = 'weapons.droptanks.Drop_Tank_300_Liter'
ENUMS.Storage.weapons.gunmounts.GUV_VOG = 'weapons.gunmounts.GUV_VOG'
ENUMS.Storage.weapons.bombs.Mk_83AIR = 'weapons.bombs.Mk_83AIR'
ENUMS.Storage.weapons.adapters.MAK79_VAR_4 = 'weapons.adapters.MAK-79_VAR_4'
ENUMS.Storage.weapons.shells.M39_20_HEI_T = 'weapons.shells.M39_20_HEI_T'
ENUMS.Storage.weapons.bombs.Mk_84AIR_TP = 'weapons.bombs.Mk_84AIR_TP'
ENUMS.Storage.weapons.bombs.GBU_31_V_3B = 'weapons.bombs.GBU_31_V_3B'
ENUMS.Storage.weapons.shells.CHAP_125_3BM69_APFSDS_T = 'weapons.shells.CHAP_125_3BM69_APFSDS_T'
ENUMS.Storage.weapons.adapters.BRU_42A = 'weapons.adapters.BRU_42A'
ENUMS.Storage.weapons.missiles.TGM_65H = 'weapons.missiles.TGM_65H'
ENUMS.Storage.weapons.bombs.GBU_27 = 'weapons.bombs.GBU_27'
ENUMS.Storage.weapons.adapters.APU1240 = 'weapons.adapters.APU-12-40'
ENUMS.Storage.weapons.droptanks.F4U1D_Drop_Tank_Aux = 'weapons.droptanks.F4U-1D_Drop_Tank_Aux'
ENUMS.Storage.weapons.shells.DM12_L55_120mm_HEAT_MP_T = 'weapons.shells.DM12_L55_120mm_HEAT_MP_T'
ENUMS.Storage.weapons.shells.British303_O_Mk1 = 'weapons.shells.British303_O_Mk1'
ENUMS.Storage.weapons.missiles.HBAIM7E2 = 'weapons.missiles.HB-AIM-7E-2'
ENUMS.Storage.weapons.containers.Spear = 'weapons.containers.Spear'
ENUMS.Storage.weapons.bombs.BetAB_500 = 'weapons.bombs.BetAB_500'
ENUMS.Storage.weapons.adapters.HB_F14_EXT_BRU34 = 'weapons.adapters.HB_F14_EXT_BRU34'
ENUMS.Storage.weapons.missiles.Rb24J = 'weapons.missiles.Rb 24J'
ENUMS.Storage.weapons.shells.M256_120_AP = 'weapons.shells.M256_120_AP'
ENUMS.Storage.weapons.bombs.SAMP250HD = 'weapons.bombs.SAMP250HD'
ENUMS.Storage.weapons.containers.alq184long = 'weapons.containers.alq-184long'
ENUMS.Storage.weapons.shells.UOF412_100HE = 'weapons.shells.UOF412_100HE'
ENUMS.Storage.weapons.bombs.Mk_83CT = 'weapons.bombs.Mk_83CT'
ENUMS.Storage.weapons.nurs.SNEB_TYPE254_F1B_YELLOW = 'weapons.nurs.SNEB_TYPE254_F1B_YELLOW'
ENUMS.Storage.weapons.missiles.AT_6 = 'weapons.missiles.AT_6'
ENUMS.Storage.weapons.nurs.SNEB_TYPE254_H1_GREEN = 'weapons.nurs.SNEB_TYPE254_H1_GREEN'
ENUMS.Storage.weapons.gunmounts.HispanoMkII = 'weapons.gunmounts.HispanoMkII'
ENUMS.Storage.weapons.missiles.C_701IR = 'weapons.missiles.C_701IR'
ENUMS.Storage.weapons.missiles.P_9M133 = 'weapons.missiles.P_9M133'
ENUMS.Storage.weapons.containers.HB_ALE_40_0_0 = 'weapons.containers.HB_ALE_40_0_0'
ENUMS.Storage.weapons.missiles.KONKURS = 'weapons.missiles.KONKURS'
ENUMS.Storage.weapons.bombs.HB_F4E_GBU15V1 = 'weapons.bombs.HB_F4E_GBU15V1'
ENUMS.Storage.weapons.bombs.SC_50 = 'weapons.bombs.SC_50'
ENUMS.Storage.weapons.bombs.AN_M66 = 'weapons.bombs.AN_M66'
ENUMS.Storage.weapons.adapters.UB32 = 'weapons.adapters.UB-32'
ENUMS.Storage.weapons.adapters.HB_ORD_LAU88 = 'weapons.adapters.HB_ORD_LAU-88'
ENUMS.Storage.weapons.bombs.RBK_250 = 'weapons.bombs.RBK_250'
ENUMS.Storage.weapons.shells._6_5mm_Type_91_JAP = 'weapons.shells.6_5mm_Type_91_JAP'
ENUMS.Storage.weapons.gunmounts.ADEN_GUNPOD = 'weapons.gunmounts.{ADEN_GUNPOD}'
ENUMS.Storage.weapons.bombs.MK106 = 'weapons.bombs.MK106'
ENUMS.Storage.weapons.bombs.RBK_250S = 'weapons.bombs.RBK_250S'
ENUMS.Storage.weapons.shells.M61_20_PGU28 = 'weapons.shells.M61_20_PGU28'
ENUMS.Storage.weapons.gunmounts.OH58D_M3P = 'weapons.gunmounts.OH58D_M3P'
ENUMS.Storage.weapons.containers.EclairM_15 = 'weapons.containers.{EclairM_15}'
ENUMS.Storage.weapons.containers.EclairM_33 = 'weapons.containers.{EclairM_33}'
ENUMS.Storage.weapons.shells.NR30_30x155_APHE = 'weapons.shells.NR30_30x155_APHE'
ENUMS.Storage.weapons.gunmounts.GAU_12_Equalizer = 'weapons.gunmounts.{GAU_12_Equalizer}'
ENUMS.Storage.weapons.bombs.IAB500 = 'weapons.bombs.IAB-500'
ENUMS.Storage.weapons.bombs.OH58D_Green_Smoke_Grenade = 'weapons.bombs.OH58D_Green_Smoke_Grenade'
ENUMS.Storage.weapons.adapters.ptab2_5ko_block1 = 'weapons.adapters.ptab-2_5ko_block1'
ENUMS.Storage.weapons.shells._7_7mm_Type_97_JAP = 'weapons.shells.7_7mm_Type_97_JAP'
ENUMS.Storage.weapons.missiles.R_530F_IR = 'weapons.missiles.R_530F_IR'
ENUMS.Storage.weapons.bombs.FAB250M54 = 'weapons.bombs.FAB-250M54'
ENUMS.Storage.weapons.missiles.RIM_116A = 'weapons.missiles.RIM_116A'
ENUMS.Storage.weapons.shells.PINK_PROJECTILE = 'weapons.shells.PINK_PROJECTILE'
ENUMS.Storage.weapons.shells.CHAP_76_HESH_T = 'weapons.shells.CHAP_76_HESH_T'
ENUMS.Storage.weapons.bombs.CBU_103 = 'weapons.bombs.CBU_103'
ENUMS.Storage.weapons.containers.US_M10_SMOKE_TANK_RED = 'weapons.containers.{US_M10_SMOKE_TANK_RED}'
ENUMS.Storage.weapons.missiles.Sea_Eagle = 'weapons.missiles.Sea_Eagle'
ENUMS.Storage.weapons.shells.PKT_7_62 = 'weapons.shells.PKT_7_62'
ENUMS.Storage.weapons.missiles.PL5EII = 'weapons.missiles.PL-5EII'
ENUMS.Storage.weapons.bombs.GBU_16 = 'weapons.bombs.GBU_16'
ENUMS.Storage.weapons.shells.OFL_120F2_AP = 'weapons.shells.OFL_120F2_AP'
ENUMS.Storage.weapons.missiles.AIM_54A_Mk60 = 'weapons.missiles.AIM_54A_Mk60'
ENUMS.Storage.weapons.bombs.CBU_97 = 'weapons.bombs.CBU_97'
ENUMS.Storage.weapons.adapters.XM158 = 'weapons.adapters.XM158'
ENUMS.Storage.weapons.containers.M2KC_AGF = 'weapons.containers.{M2KC_AGF}'
ENUMS.Storage.weapons.adapters.CBLS200 = 'weapons.adapters.CBLS-200'
ENUMS.Storage.weapons.containers.SPRD99 = 'weapons.containers.SPRD-99'
ENUMS.Storage.weapons.missiles.DWS39_MJ1_MJ2 = 'weapons.missiles.DWS39_MJ1_MJ2'
ENUMS.Storage.weapons.bombs.BDU_33 = 'weapons.bombs.BDU_33'
ENUMS.Storage.weapons.missiles.TOW = 'weapons.missiles.TOW'
ENUMS.Storage.weapons.gunmounts.OH58D_M3P_L400 = 'weapons.gunmounts.OH58D_M3P_L400'
ENUMS.Storage.weapons.bombs.KAB_1500LG = 'weapons.bombs.KAB_1500LG'
ENUMS.Storage.weapons.shells.MK45_127mm_AP_Essex = 'weapons.shells.MK45_127mm_AP_Essex'
ENUMS.Storage.weapons.shells.M61_20_HE_gr = 'weapons.shells.M61_20_HE_gr'
ENUMS.Storage.weapons.missiles.BRM1_90MM = 'weapons.missiles.BRM-1_90MM'
ENUMS.Storage.weapons.missiles.Ataka_9M120F = 'weapons.missiles.Ataka_9M120F'
ENUMS.Storage.weapons.adapters.lau88 = 'weapons.adapters.lau-88'
ENUMS.Storage.weapons.missiles.Sea_Wolf = 'weapons.missiles.Sea_Wolf'
ENUMS.Storage.weapons.shells.M61_20_PGU27 = 'weapons.shells.M61_20_PGU27'
ENUMS.Storage.weapons.missiles.CM400AKG = 'weapons.missiles.CM-400AKG'
ENUMS.Storage.weapons.containers.F15E_AAQ14_LANTIRN = 'weapons.containers.F-15E_AAQ-14_LANTIRN'
ENUMS.Storage.weapons.containers.wmd7 = 'weapons.containers.wmd7'
ENUMS.Storage.weapons.missiles.AIM7E2 = 'weapons.missiles.AIM-7E-2'
ENUMS.Storage.weapons.shells.Utes_12_7x108 = 'weapons.shells.Utes_12_7x108'
ENUMS.Storage.weapons.containers.HB_ORD_Pave_Spike_Fast = 'weapons.containers.HB_ORD_Pave_Spike_Fast'
ENUMS.Storage.weapons.adapters.MAK79_VAR_2 = 'weapons.adapters.MAK-79_VAR_2'
ENUMS.Storage.weapons.missiles.AGM_65D = 'weapons.missiles.AGM_65D'
ENUMS.Storage.weapons.missiles.AGM_86 = 'weapons.missiles.AGM_86'
ENUMS.Storage.weapons.shells.British303_G_Mk3 = 'weapons.shells.British303_G_Mk3'
ENUMS.Storage.weapons.shells.M61_20_AP_gr = 'weapons.shells.M61_20_AP_gr'
ENUMS.Storage.weapons.adapters.UB_32A_24 = 'weapons.adapters.UB_32A_24'
ENUMS.Storage.weapons.containers.F15E_AAQ28_LITENING = 'weapons.containers.F-15E_AAQ-28_LITENING'
ENUMS.Storage.weapons.bombs.OH58D_Blue_Smoke_Grenade = 'weapons.bombs.OH58D_Blue_Smoke_Grenade'
ENUMS.Storage.weapons.bombs.KAB_500Kr = 'weapons.bombs.KAB_500Kr'
ENUMS.Storage.weapons.containers.SPS141100 = 'weapons.containers.SPS-141-100'
ENUMS.Storage.weapons.missiles.AIM9JULI = 'weapons.missiles.AIM-9JULI'
ENUMS.Storage.weapons.droptanks.MB339_TT500_R = 'weapons.droptanks.MB339_TT500_R'
ENUMS.Storage.weapons.adapters.towpilon = 'weapons.adapters.tow-pilon'
ENUMS.Storage.weapons.nurs.SNEB_TYPE254_H1_YELLOW = 'weapons.nurs.SNEB_TYPE254_H1_YELLOW'
ENUMS.Storage.weapons.missiles.M30 = 'weapons.missiles.M30'
ENUMS.Storage.weapons.bombs.Durandal = 'weapons.bombs.Durandal'
ENUMS.Storage.weapons.adapters.apu7 = 'weapons.adapters.apu-7'
ENUMS.Storage.weapons.nurs.C_8CM_VT = 'weapons.nurs.C_8CM_VT'
ENUMS.Storage.weapons.containers.aispodt50 = 'weapons.containers.ais-pod-t50'
ENUMS.Storage.weapons.shells.M485_155_IL = 'weapons.shells.M485_155_IL'
ENUMS.Storage.weapons.bombs.RN24 = 'weapons.bombs.RN-24'
ENUMS.Storage.weapons.shells._2A64_152 = 'weapons.shells.2A64_152'
ENUMS.Storage.weapons.containers._ = 'weapons.containers.'
ENUMS.Storage.weapons.shells.M61_20_HE = 'weapons.shells.M61_20_HE'
ENUMS.Storage.weapons.gunmounts.CPG_M4 = 'weapons.gunmounts.CPG_M4'
ENUMS.Storage.weapons.shells._57mm_Type_90_JAP = 'weapons.shells.57mm_Type_90_JAP'
ENUMS.Storage.weapons.missiles.ADM_141A = 'weapons.missiles.ADM_141A'
ENUMS.Storage.weapons.containers.KBpod = 'weapons.containers.KBpod'
ENUMS.Storage.weapons.shells.DEFA554_30_HE_TRACERS = 'weapons.shells.DEFA554_30_HE_TRACERS'
ENUMS.Storage.weapons.missiles.SA_IRIS_T_SL = 'weapons.missiles.SA_IRIS_T_SL'
ENUMS.Storage.weapons.missiles.R55 = 'weapons.missiles.R-55'
ENUMS.Storage.weapons.adapters.BRU42_HS = 'weapons.adapters.BRU-42_HS'
ENUMS.Storage.weapons.shells.Hispano_Mk_II_MKIIZ_AP = 'weapons.shells.Hispano_Mk_II_MKIIZ_AP'
ENUMS.Storage.weapons.missiles.SA2V755 = 'weapons.missiles.SA2V755'
ENUMS.Storage.weapons.missiles.PL8B = 'weapons.missiles.PL-8B'
ENUMS.Storage.weapons.droptanks.Mosquito_Drop_Tank_100gal = 'weapons.droptanks.Mosquito_Drop_Tank_100gal'
ENUMS.Storage.weapons.shells.MG_13x64_HE = 'weapons.shells.MG_13x64_HE'
ENUMS.Storage.weapons.shells.Hispano_Mk_II_Tracer_G = 'weapons.shells.Hispano_Mk_II_Tracer_G'
ENUMS.Storage.weapons.nurs.SNEB_TYPE253_H1 = 'weapons.nurs.SNEB_TYPE253_H1'
ENUMS.Storage.weapons.nurs.ARAKM70BAPPX = 'weapons.nurs.ARAKM70BAPPX'
ENUMS.Storage.weapons.adapters.TER9A = 'weapons.adapters.TER-9A'
ENUMS.Storage.weapons.missiles._9M317 = 'weapons.missiles.9M317'
ENUMS.Storage.weapons.adapters.LAU115C = 'weapons.adapters.LAU-115C'
ENUMS.Storage.weapons.gunmounts.M134_L = 'weapons.gunmounts.M134_L'
ENUMS.Storage.weapons.shells._20mm_M220_Tracer = 'weapons.shells.20mm_M220_Tracer'
ENUMS.Storage.weapons.containers.EclairM_06 = 'weapons.containers.{EclairM_06}'
ENUMS.Storage.weapons.bombs.RBK_500AO = 'weapons.bombs.RBK_500AO'
ENUMS.Storage.weapons.shells.Bofors_40mm_Essex = 'weapons.shells.Bofors_40mm_Essex'
ENUMS.Storage.weapons.containers.MB339_Vinten = 'weapons.containers.MB339_Vinten'
ENUMS.Storage.weapons.nurs.ARAKM70BHE = 'weapons.nurs.ARAKM70BHE'
ENUMS.Storage.weapons.bombs.FAB250M62 = 'weapons.bombs.FAB-250-M62'
ENUMS.Storage.weapons.missiles.Rb04E = 'weapons.missiles.Rb 04E'
ENUMS.Storage.weapons.droptanks.PTB400_MIG15 = 'weapons.droptanks.PTB400_MIG15'
ENUMS.Storage.weapons.bombs.PTAB_2_5KO = 'weapons.bombs.PTAB_2_5KO'
ENUMS.Storage.weapons.adapters.M2000C_LRF4_edm = 'weapons.adapters.M-2000C_LRF4.edm'
ENUMS.Storage.weapons.missiles.AIM_9X = 'weapons.missiles.AIM_9X'
ENUMS.Storage.weapons.shells.MG_13x64_I = 'weapons.shells.MG_13x64_I'
ENUMS.Storage.weapons.bombs.GBU_8_B = 'weapons.bombs.GBU_8_B'
ENUMS.Storage.weapons.missiles.SA9M31 = 'weapons.missiles.SA9M31'
ENUMS.Storage.weapons.containers.rightSeat = 'weapons.containers.rightSeat'
ENUMS.Storage.weapons.shells.Pzgr_3940 = 'weapons.shells.Pzgr_39/40'
ENUMS.Storage.weapons.shells._2A60_120 = 'weapons.shells.2A60_120'
ENUMS.Storage.weapons.bombs.GBU_17 = 'weapons.bombs.GBU_17'
ENUMS.Storage.weapons.missiles.HHQ9 = 'weapons.missiles.HHQ-9'
ENUMS.Storage.weapons.bombs.Mk_84AIR_GP = 'weapons.bombs.Mk_84AIR_GP'
ENUMS.Storage.weapons.bombs.RBK_250_275_AO_1SCH = 'weapons.bombs.RBK_250_275_AO_1SCH'
ENUMS.Storage.weapons.missiles.AIM7E = 'weapons.missiles.AIM-7E'
ENUMS.Storage.weapons.missiles.AGR_20_M282 = 'weapons.missiles.AGR_20_M282'
ENUMS.Storage.weapons.droptanks.MB339_FT330 = 'weapons.droptanks.MB339_FT330'
ENUMS.Storage.weapons.shells.MK_108_MGsch_T = 'weapons.shells.MK_108_MGsch_T'
ENUMS.Storage.weapons.missiles.GB6HE = 'weapons.missiles.GB-6-HE'
ENUMS.Storage.weapons.nurs.SNEB_TYPE254_H1_RED = 'weapons.nurs.SNEB_TYPE254_H1_RED'
ENUMS.Storage.weapons.shells.HP30_30_HE = 'weapons.shells.HP30_30_HE'
ENUMS.Storage.weapons.bombs.RN28 = 'weapons.bombs.RN-28'
ENUMS.Storage.weapons.shells.L31A7_HESH = 'weapons.shells.L31A7_HESH'
ENUMS.Storage.weapons.shells.GSH301_30_AP = 'weapons.shells.GSH301_30_AP'
ENUMS.Storage.weapons.bombs.RBK_500U = 'weapons.bombs.RBK_500U'
ENUMS.Storage.weapons.droptanks.HB_F4E_EXT_Center_Fuel_Tank = 'weapons.droptanks.HB_F-4E_EXT_Center_Fuel_Tank'
ENUMS.Storage.weapons.containers.F15E_AAQ13_LANTIRN = 'weapons.containers.F-15E_AAQ-13_LANTIRN'
ENUMS.Storage.weapons.droptanks._800LTankEmpty = 'weapons.droptanks.800L Tank Empty'
ENUMS.Storage.weapons.missiles.MIM_104 = 'weapons.missiles.MIM_104'
ENUMS.Storage.weapons.shells.MG_13x64_API = 'weapons.shells.MG_13x64_API'
ENUMS.Storage.weapons.shells.M61_20_TP = 'weapons.shells.M61_20_TP'
ENUMS.Storage.weapons.bombs.LUU_19 = 'weapons.bombs.LUU_19'
ENUMS.Storage.weapons.shells.M55A2_TP_RED = 'weapons.shells.M55A2_TP_RED'
ENUMS.Storage.weapons.adapters.su27twinpylon = 'weapons.adapters.su-27-twinpylon'
ENUMS.Storage.weapons.nurs.M26HE = 'weapons.nurs.M26HE'
ENUMS.Storage.weapons.bombs.BLU4B_GROUP = 'weapons.bombs.BLU-4B_GROUP'
ENUMS.Storage.weapons.nurs.HYDRA_70_M156 = 'weapons.nurs.HYDRA_70_M156'
ENUMS.Storage.weapons.shells.DM23_105_AP = 'weapons.shells.DM23_105_AP'
ENUMS.Storage.weapons.missiles.SM_1 = 'weapons.missiles.SM_1'
ENUMS.Storage.weapons.missiles.OH58D_FIM_92 = 'weapons.missiles.OH58D_FIM_92'
ENUMS.Storage.weapons.containers.F18LDTPOD = 'weapons.containers.F-18-LDT-POD'
ENUMS.Storage.weapons.missiles.AGM_65K = 'weapons.missiles.AGM_65K'
ENUMS.Storage.weapons.shells.Bofors_40mm_HE = 'weapons.shells.Bofors_40mm_HE'
ENUMS.Storage.weapons.missiles.HAWK_RAKETA = 'weapons.missiles.HAWK_RAKETA'
ENUMS.Storage.weapons.shells._7_62x54 = 'weapons.shells.7_62x54'
ENUMS.Storage.weapons.shells.DM12_120mm_HEAT_MP_T = 'weapons.shells.DM12_120mm_HEAT_MP_T'
ENUMS.Storage.weapons.bombs.AN_M64 = 'weapons.bombs.AN_M64'
ENUMS.Storage.weapons.containers.rearCargoSeats = 'weapons.containers.rearCargoSeats'
ENUMS.Storage.weapons.bombs.AN_M65 = 'weapons.bombs.AN_M65'
ENUMS.Storage.weapons.missiles.Rb74 = 'weapons.missiles.Rb 74'
ENUMS.Storage.weapons.shells.DEFA553_30AP = 'weapons.shells.DEFA553_30AP'
ENUMS.Storage.weapons.nurs.S5M = 'weapons.nurs.S-5M'
ENUMS.Storage.weapons.gunmounts.M134_SIDE_R = 'weapons.gunmounts.M134_SIDE_R'
ENUMS.Storage.weapons.missiles.HJ12 = 'weapons.missiles.HJ-12'
ENUMS.Storage.weapons.shells.PLZ_155_HE = 'weapons.shells.PLZ_155_HE'
ENUMS.Storage.weapons.adapters.BRU_33A = 'weapons.adapters.BRU_33A'
ENUMS.Storage.weapons.nurs.ARAKM70BAP = 'weapons.nurs.ARAKM70BAP'
ENUMS.Storage.weapons.missiles.MMagicII = 'weapons.missiles.MMagicII'
ENUMS.Storage.weapons.nurs.HYDRA_70_M282 = 'weapons.nurs.HYDRA_70_M282'
ENUMS.Storage.weapons.nurs.ARF8M3HEI = 'weapons.nurs.ARF8M3HEI'
ENUMS.Storage.weapons.shells._76mm_AA_JAP = 'weapons.shells.76mm_AA_JAP'
ENUMS.Storage.weapons.missiles.Igla_1E = 'weapons.missiles.Igla_1E'
ENUMS.Storage.weapons.nurs.SMERCH_9M55K = 'weapons.nurs.SMERCH_9M55K'
ENUMS.Storage.weapons.nurs.C_24 = 'weapons.nurs.C_24'
ENUMS.Storage.weapons.shells.GSH301_30_HE = 'weapons.shells.GSH301_30_HE'
ENUMS.Storage.weapons.nurs.SNEB_TYPE256_H1 = 'weapons.nurs.SNEB_TYPE256_H1'
ENUMS.Storage.weapons.adapters.T45_PMBR = 'weapons.adapters.T45_PMBR'
ENUMS.Storage.weapons.containers.EclairM_24 = 'weapons.containers.{EclairM_24}'
ENUMS.Storage.weapons.droptanks.MB339_TT500_L = 'weapons.droptanks.MB339_TT500_L'
ENUMS.Storage.weapons.bombs.BKF_PTAB2_5KO = 'weapons.bombs.BKF_PTAB2_5KO'
ENUMS.Storage.weapons.shells.Br303 = 'weapons.shells.Br303'
ENUMS.Storage.weapons.shells.DANA_152 = 'weapons.shells.DANA_152'
ENUMS.Storage.weapons.nurs.S5MO_HEFRAG_FFAR = 'weapons.nurs.S5MO_HEFRAG_FFAR'
ENUMS.Storage.weapons.missiles.AIM9P3 = 'weapons.missiles.AIM-9P3'
ENUMS.Storage.weapons.gunmounts.GAU_12 = 'weapons.gunmounts.GAU_12'
ENUMS.Storage.weapons.shells.MK45_127 = 'weapons.shells.MK45_127'
ENUMS.Storage.weapons.nurs.C_8CM_GN = 'weapons.nurs.C_8CM_GN'
ENUMS.Storage.weapons.nurs.C_13 = 'weapons.nurs.C_13'
ENUMS.Storage.weapons.gunmounts.OH58D_M3P_L300 = 'weapons.gunmounts.OH58D_M3P_L300'
ENUMS.Storage.weapons.missiles.AGM_65A = 'weapons.missiles.AGM_65A'
ENUMS.Storage.weapons.containers.AV8BNA_ALQ164 = 'weapons.containers.AV8BNA_ALQ164'
ENUMS.Storage.weapons.bombs.OH58D_Red_Smoke_Grenade = 'weapons.bombs.OH58D_Red_Smoke_Grenade'
ENUMS.Storage.weapons.bombs.FAB_1500 = 'weapons.bombs.FAB_1500'
ENUMS.Storage.weapons.shells.M230_TPM788 = 'weapons.shells.M230_TP M788'
ENUMS.Storage.weapons.containers.leftSeat = 'weapons.containers.leftSeat'
ENUMS.Storage.weapons.missiles.Kormoran = 'weapons.missiles.Kormoran'
ENUMS.Storage.weapons.adapters.boz100 = 'weapons.adapters.boz-100'
ENUMS.Storage.weapons.nurs.HYDRA_70_MK1 = 'weapons.nurs.HYDRA_70_MK1'
ENUMS.Storage.weapons.shells.Utes_12_7x108_T = 'weapons.shells.Utes_12_7x108_T'
ENUMS.Storage.weapons.missiles.AGM_154A = 'weapons.missiles.AGM_154A'
ENUMS.Storage.weapons.adapters.MBD3LAU68 = 'weapons.adapters.MBD-3-LAU-68'
ENUMS.Storage.weapons.nurs.C_8CM_WH = 'weapons.nurs.C_8CM_WH'
ENUMS.Storage.weapons.missiles.MatraSuper530D = 'weapons.missiles.Matra Super 530D'
ENUMS.Storage.weapons.bombs.BDU_50HD = 'weapons.bombs.BDU_50HD'
ENUMS.Storage.weapons.adapters.M2000c_BAP_Rack = 'weapons.adapters.M-2000c_BAP_Rack'
ENUMS.Storage.weapons.shells._7_92x57sS = 'weapons.shells.7_92x57sS'
ENUMS.Storage.weapons.shells.M20_50_aero_APIT = 'weapons.shells.M20_50_aero_APIT'
ENUMS.Storage.weapons.bombs.KAB_500 = 'weapons.bombs.KAB_500'
ENUMS.Storage.weapons.gunmounts.AKAN = 'weapons.gunmounts.{AKAN}'
ENUMS.Storage.weapons.shells._20MM_M242_HEIT = 'weapons.shells.20MM_M242_HEI-T'
ENUMS.Storage.weapons.gunmounts.GAU_12_Equalizer_AP = 'weapons.gunmounts.{GAU_12_Equalizer_AP}'
ENUMS.Storage.weapons.gunmounts.FN_HMP400 = 'weapons.gunmounts.{FN_HMP400}'
ENUMS.Storage.weapons.containers.dlpod_akg = 'weapons.containers.dlpod_akg'
ENUMS.Storage.weapons.droptanks.PTB600_MIG15 = 'weapons.droptanks.PTB600_MIG15'
ENUMS.Storage.weapons.adapters.apu602_L = 'weapons.adapters.apu-60-2_L'
ENUMS.Storage.weapons.missiles.SeaSparrow = 'weapons.missiles.SeaSparrow'
ENUMS.Storage.weapons.droptanks._ = 'weapons.droptanks.'
ENUMS.Storage.weapons.adapters.lau117 = 'weapons.adapters.lau-117'
ENUMS.Storage.weapons.shells.M197_20 = 'weapons.shells.M197_20'
ENUMS.Storage.weapons.shells.Br303_tr = 'weapons.shells.Br303_tr'
ENUMS.Storage.weapons.adapters.MBD3LAU61 = 'weapons.adapters.MBD-3-LAU-61'
ENUMS.Storage.weapons.bombs.British_SAP_250LB_Bomb_Mk5 = 'weapons.bombs.British_SAP_250LB_Bomb_Mk5'
ENUMS.Storage.weapons.adapters.apu68m3 = 'weapons.adapters.apu-68m3'
ENUMS.Storage.weapons.shells.British303_Ball_Mk6 = 'weapons.shells.British303_Ball_Mk6'
ENUMS.Storage.weapons.shells._7_62x54_NOTRACER = 'weapons.shells.7_62x54_NOTRACER'
ENUMS.Storage.weapons.nurs.SNEB_TYPE250_F1B = 'weapons.nurs.SNEB_TYPE250_F1B'
ENUMS.Storage.weapons.shells.ZTZ_14_5 = 'weapons.shells.ZTZ_14_5'
ENUMS.Storage.weapons.bombs.CBU_105 = 'weapons.bombs.CBU_105'
ENUMS.Storage.weapons.droptanks.FW190_FuelTank = 'weapons.droptanks.FW-190_Fuel-Tank'
ENUMS.Storage.weapons.missiles.X_58 = 'weapons.missiles.X_58'
ENUMS.Storage.weapons.bombs.LYSBOMB11089 = 'weapons.bombs.LYSBOMB 11089'
ENUMS.Storage.weapons.containers.PAVETACK = 'weapons.containers.PAVETACK'
ENUMS.Storage.weapons.bombs.GBU_24 = 'weapons.bombs.GBU_24'
ENUMS.Storage.weapons.gunmounts.FN_HMP400_100 = 'weapons.gunmounts.{FN_HMP400_100}'
ENUMS.Storage.weapons.missiles.AIM7MH = 'weapons.missiles.AIM-7MH'
ENUMS.Storage.weapons.adapters.rb05pylon = 'weapons.adapters.rb05pylon'
ENUMS.Storage.weapons.shells.DEFA553_30APIT = 'weapons.shells.DEFA553_30APIT'
ENUMS.Storage.weapons.shells.Flak18_Sprgr_39 = 'weapons.shells.Flak18_Sprgr_39'
ENUMS.Storage.weapons.missiles.X_35 = 'weapons.missiles.X_35'
ENUMS.Storage.weapons.bombs.BL_755 = 'weapons.bombs.BL_755'
ENUMS.Storage.weapons.containers.ETHER = 'weapons.containers.ETHER'
ENUMS.Storage.weapons.droptanks.F4U1D_Drop_Tank_Mk5 = 'weapons.droptanks.F4U-1D_Drop_Tank_Mk5'
ENUMS.Storage.weapons.containers.CE2_SMOKE_WHITE = 'weapons.containers.{CE2_SMOKE_WHITE}'
ENUMS.Storage.weapons.bombs.Mk_82Y = 'weapons.bombs.Mk_82Y'
ENUMS.Storage.weapons.bombs.British_MC_500LB_Bomb_Mk2 = 'weapons.bombs.British_MC_500LB_Bomb_Mk2'
ENUMS.Storage.weapons.adapters.HB_ORD_SUU_7 = 'weapons.adapters.HB_ORD_SUU_7'
ENUMS.Storage.weapons.shells.MK75_76 = 'weapons.shells.MK75_76'
ENUMS.Storage.weapons.shells.M68_105_AP = 'weapons.shells.M68_105_AP'
ENUMS.Storage.weapons.missiles.SA57E6 = 'weapons.missiles.SA57E6'
ENUMS.Storage.weapons.missiles.AGM_86C = 'weapons.missiles.AGM_86C'
ENUMS.Storage.weapons.missiles.P_24T = 'weapons.missiles.P_24T'
ENUMS.Storage.weapons.adapters.OH58D_HRACK_L = 'weapons.adapters.OH58D_HRACK_L'
ENUMS.Storage.weapons.gunmounts.MK_108 = 'weapons.gunmounts.MK_108'
ENUMS.Storage.weapons.adapters.APU68 = 'weapons.adapters.APU-68'
ENUMS.Storage.weapons.shells.British303_G_Mk6z = 'weapons.shells.British303_G_Mk6z'
ENUMS.Storage.weapons.containers.aispodt50_l = 'weapons.containers.ais-pod-t50_l'
ENUMS.Storage.weapons.gunmounts.N37 = 'weapons.gunmounts.N-37'
ENUMS.Storage.weapons.missiles.X_555 = 'weapons.missiles.X_555'
ENUMS.Storage.weapons.bombs.FAB500M54 = 'weapons.bombs.FAB-500M54'
ENUMS.Storage.weapons.containers.AN_AAQ_33 = 'weapons.containers.AN_AAQ_33'
ENUMS.Storage.weapons.containers.M2KC_AAF = 'weapons.containers.{M2KC_AAF}'
ENUMS.Storage.weapons.shells.NR23_23x115_HEI_T = 'weapons.shells.NR23_23x115_HEI_T'
ENUMS.Storage.weapons.shells.KPVT_14_5_T = 'weapons.shells.KPVT_14_5_T'
ENUMS.Storage.weapons.shells.M56A3_HE_RED = 'weapons.shells.M56A3_HE_RED'
ENUMS.Storage.weapons.bombs.FAB500SL = 'weapons.bombs.FAB-500SL'
ENUMS.Storage.weapons.bombs.KAB_500S = 'weapons.bombs.KAB_500S'
ENUMS.Storage.weapons.bombs.SAMP400LD = 'weapons.bombs.SAMP400LD'
ENUMS.Storage.weapons.bombs.BDU_45B = 'weapons.bombs.BDU_45B'
ENUMS.Storage.weapons.adapters.APU73 = 'weapons.adapters.APU-73'
ENUMS.Storage.weapons.missiles._9M723_HE = 'weapons.missiles.9M723_HE'
ENUMS.Storage.weapons.bombs.GBU_15_V_31_B = 'weapons.bombs.GBU_15_V_31_B'
ENUMS.Storage.weapons.adapters.CHAP_Tu95MS_rotary_launcher = 'weapons.adapters.CHAP_Tu95MS_rotary_launcher'
ENUMS.Storage.weapons.droptanks.HB_F4E_EXT_WingTank = 'weapons.droptanks.HB_F-4E_EXT_WingTank'
ENUMS.Storage.weapons.bombs.SC_250_T1_L2 = 'weapons.bombs.SC_250_T1_L2'
ENUMS.Storage.weapons.torpedoes.mk46torp_name = 'weapons.torpedoes.mk46torp_name'
ENUMS.Storage.weapons.nurs.C_25 = 'weapons.nurs.C_25'
ENUMS.Storage.weapons.adapters.MAK79_VAR_3 = 'weapons.adapters.MAK-79_VAR_3'
ENUMS.Storage.weapons.adapters._9m120 = 'weapons.adapters.9m120'
ENUMS.Storage.weapons.shells.GSh_30_2K_HE_Tr = 'weapons.shells.GSh_30_2K_HE_Tr'
ENUMS.Storage.weapons.adapters.hf20_pod = 'weapons.adapters.hf20_pod'
ENUMS.Storage.weapons.missiles.AGM_122 = 'weapons.missiles.AGM_122'
ENUMS.Storage.weapons.missiles.P_60 = 'weapons.missiles.P_60'
ENUMS.Storage.weapons.shells.K307_155HE = 'weapons.shells.K307_155HE'
ENUMS.Storage.weapons.shells.A222_130 = 'weapons.shells.A222_130'
ENUMS.Storage.weapons.nurs.Zuni_127 = 'weapons.nurs.Zuni_127'
ENUMS.Storage.weapons.missiles.AIM9J = 'weapons.missiles.AIM-9J'
ENUMS.Storage.weapons.shells.BK_27 = 'weapons.shells.BK_27'
ENUMS.Storage.weapons.adapters.M272_AGM114 = 'weapons.adapters.M272_AGM114'
ENUMS.Storage.weapons.shells.M242_25_AP_M791 = 'weapons.shells.M242_25_AP_M791'
ENUMS.Storage.weapons.adapters.HB_F14_EXT_SHOULDER_PHX_R = 'weapons.adapters.HB_F14_EXT_SHOULDER_PHX_R'
ENUMS.Storage.weapons.gunmounts.OH58D_M3P_L100 = 'weapons.gunmounts.OH58D_M3P_L100'
ENUMS.Storage.weapons.bombs.BetAB_500ShP = 'weapons.bombs.BetAB_500ShP'
ENUMS.Storage.weapons.nurs.British_HE_60LBSAPNo2_3INCHNo1 = 'weapons.nurs.British_HE_60LBSAPNo2_3INCHNo1'
ENUMS.Storage.weapons.missiles.DWS39_MJ2 = 'weapons.missiles.DWS39_MJ2'
ENUMS.Storage.weapons.bombs.HEBOMBD = 'weapons.bombs.HEBOMBD'
ENUMS.Storage.weapons.missiles.Ataka_9M220 = 'weapons.missiles.Ataka_9M220'
ENUMS.Storage.weapons.adapters.rb04pylon = 'weapons.adapters.rb04pylon'
ENUMS.Storage.weapons.bombs.GBU_28 = 'weapons.bombs.GBU_28'
ENUMS.Storage.weapons.nurs.C_8CM_YE = 'weapons.nurs.C_8CM_YE'
ENUMS.Storage.weapons.droptanks.HB_F14_EXT_DROPTANK = 'weapons.droptanks.HB_F14_EXT_DROPTANK'
ENUMS.Storage.weapons.adapters.M2000C_LRF4 = 'weapons.adapters.M-2000C_LRF4'
ENUMS.Storage.weapons.shells.HESH_105 = 'weapons.shells.HESH_105'
ENUMS.Storage.weapons.gunmounts.CH47_PORT_M240H = 'weapons.gunmounts.{CH47_PORT_M240H}'
ENUMS.Storage.weapons.containers.SMOKE_WHITE = 'weapons.containers.{SMOKE_WHITE}'
ENUMS.Storage.weapons.bombs.British_GP_250LB_Bomb_Mk4 = 'weapons.bombs.British_GP_250LB_Bomb_Mk4'
ENUMS.Storage.weapons.gunmounts.GIAT_M621_HEAP = 'weapons.gunmounts.{GIAT_M621_HEAP}'
ENUMS.Storage.weapons.nurs.ARF8M3TPSM = 'weapons.nurs.ARF8M3TPSM'
ENUMS.Storage.weapons.nurs.M8rocket = 'weapons.nurs.M8rocket'
ENUMS.Storage.weapons.missiles.X_25MR = 'weapons.missiles.X_25MR'
ENUMS.Storage.weapons.droptanks.fueltank230 = 'weapons.droptanks.fueltank230'
ENUMS.Storage.weapons.droptanks.PTB490CMIG21 = 'weapons.droptanks.PTB-490C-MIG21'
ENUMS.Storage.weapons.droptanks.M2KC_02_RPL541 = 'weapons.droptanks.M2KC_02_RPL541'
ENUMS.Storage.weapons.nurs.SNEB_TYPE254_F1B_GREEN = 'weapons.nurs.SNEB_TYPE254_F1B_GREEN'
ENUMS.Storage.weapons.adapters.mbd = 'weapons.adapters.mbd'
ENUMS.Storage.weapons.droptanks.HB_F4E_EXT_Center_Fuel_Tank_EMPTY = 'weapons.droptanks.HB_F-4E_EXT_Center_Fuel_Tank_EMPTY'
ENUMS.Storage.weapons.missiles.AGM_84D = 'weapons.missiles.AGM_84D'
ENUMS.Storage.weapons.bombs.M257_FLARE = 'weapons.bombs.M257_FLARE'
ENUMS.Storage.weapons.missiles.AGM_84A = 'weapons.missiles.AGM_84A'
ENUMS.Storage.weapons.gunmounts.GIAT_M621_HE = 'weapons.gunmounts.{GIAT_M621_HE}'
ENUMS.Storage.weapons.missiles.AIM_54C_Mk47 = 'weapons.missiles.AIM_54C_Mk47'
ENUMS.Storage.weapons.containers.MPS410 = 'weapons.containers.MPS-410'
ENUMS.Storage.weapons.missiles.HY2 = 'weapons.missiles.HY-2'
ENUMS.Storage.weapons.bombs.Mk_81 = 'weapons.bombs.Mk_81'
ENUMS.Storage.weapons.shells.Oerlikon_20mm_Essex = 'weapons.shells.Oerlikon_20mm_Essex'
ENUMS.Storage.weapons.adapters.PylonM71 = 'weapons.adapters.PylonM71'
ENUMS.Storage.weapons.droptanks._1100LTank = 'weapons.droptanks.1100L Tank'
ENUMS.Storage.weapons.bombs.BAP_100 = 'weapons.bombs.BAP_100'
ENUMS.Storage.weapons.gunmounts.PK3 = 'weapons.gunmounts.{PK-3}'
ENUMS.Storage.weapons.adapters.b52_CRL_mod1 = 'weapons.adapters.b-52_CRL_mod1'
ENUMS.Storage.weapons.adapters._9m120m = 'weapons.adapters.9m120m'
ENUMS.Storage.weapons.droptanks.M2KC_02_RPL541_EMPTY = 'weapons.droptanks.M2KC_02_RPL541_EMPTY'
ENUMS.Storage.weapons.bombs.BR_500 = 'weapons.bombs.BR_500'
ENUMS.Storage.weapons.adapters._9K114_Shturm = 'weapons.adapters.9K114_Shturm'
ENUMS.Storage.weapons.adapters.f4pilon = 'weapons.adapters.f4-pilon'
ENUMS.Storage.weapons.gunmounts.SPPU_22 = 'weapons.gunmounts.SPPU_22'
ENUMS.Storage.weapons.gunmounts.GSh232taildefense = 'weapons.gunmounts.GSh-23-2 tail defense'
ENUMS.Storage.weapons.bombs.FAB250M54TU = 'weapons.bombs.FAB-250M54TU'
ENUMS.Storage.weapons.nurs.HYDRA_70_M229 = 'weapons.nurs.HYDRA_70_M229'
ENUMS.Storage.weapons.shells.M185_155 = 'weapons.shells.M185_155'
ENUMS.Storage.weapons.adapters.sa342_ATAM_Tube_2x = 'weapons.adapters.sa342_ATAM_Tube_2x'
ENUMS.Storage.weapons.shells._53UBR281U = 'weapons.shells.53-UBR-281U'
ENUMS.Storage.weapons.nurs.SNEB_TYPE259E_H1 = 'weapons.nurs.SNEB_TYPE259E_H1'
ENUMS.Storage.weapons.bombs.SAB_250_200 = 'weapons.bombs.SAB_250_200'
ENUMS.Storage.weapons.missiles.ADM_141B = 'weapons.missiles.ADM_141B'
ENUMS.Storage.weapons.adapters.kmgu2 = 'weapons.adapters.kmgu-2'
ENUMS.Storage.weapons.adapters.B20 = 'weapons.adapters.B-20'
ENUMS.Storage.weapons.containers.U22A = 'weapons.containers.U22A'
ENUMS.Storage.weapons.shells.M246_20_HE_gr = 'weapons.shells.M246_20_HE_gr'
ENUMS.Storage.weapons.nurs.SNEB_TYPE251_H1 = 'weapons.nurs.SNEB_TYPE251_H1'
ENUMS.Storage.weapons.missiles.Kh25MP_PRGS1VP = 'weapons.missiles.Kh25MP_PRGS1VP'
ENUMS.Storage.weapons.adapters.BR21Gerat = 'weapons.adapters.BR21-Gerat'
ENUMS.Storage.weapons.adapters.apu13u2 = 'weapons.adapters.apu-13u-2'
ENUMS.Storage.weapons.shells.Hispano_Mk_II_MKI_HEI = 'weapons.shells.Hispano_Mk_II_MKI_HE/I'
ENUMS.Storage.weapons.nurs.FFAR_Mk61 = 'weapons.nurs.FFAR_Mk61'
ENUMS.Storage.weapons.containers.BRD4250 = 'weapons.containers.BRD-4-250'
ENUMS.Storage.weapons.containers.HB_ORD_MER = 'weapons.containers.HB_ORD_MER'
ENUMS.Storage.weapons.droptanks.PTB_1200_F1 = 'weapons.droptanks.PTB_1200_F1'
ENUMS.Storage.weapons.bombs.British_GP_500LB_Bomb_Mk1 = 'weapons.bombs.British_GP_500LB_Bomb_Mk1'
ENUMS.Storage.weapons.missiles.AGM_119 = 'weapons.missiles.AGM_119'
ENUMS.Storage.weapons.shells._3BM59_125_AP = 'weapons.shells.3BM59_125_AP'
ENUMS.Storage.weapons.shells.M2_50_aero_AP = 'weapons.shells.M2_50_aero_AP'
ENUMS.Storage.weapons.adapters.LAU68 = 'weapons.adapters.LAU-68'
ENUMS.Storage.weapons.nurs.C_5 = 'weapons.nurs.C_5'
ENUMS.Storage.weapons.nurs.S24B = 'weapons.nurs.S-24B'
ENUMS.Storage.weapons.adapters.HB_F4E_LAU34 = 'weapons.adapters.HB_F-4E_LAU-34'
ENUMS.Storage.weapons.shells._2A18_122 = 'weapons.shells.2A18_122'
ENUMS.Storage.weapons.missiles.SCUD_RAKETA = 'weapons.missiles.SCUD_RAKETA'
ENUMS.Storage.weapons.adapters.b52_HSAB = 'weapons.adapters.b-52_HSAB'
ENUMS.Storage.weapons.nurs.R4M = 'weapons.nurs.R4M'
ENUMS.Storage.weapons.bombs.LYSBOMB11086 = 'weapons.bombs.LYSBOMB 11086'
ENUMS.Storage.weapons.bombs.SD_250_Stg = 'weapons.bombs.SD_250_Stg'
ENUMS.Storage.weapons.nurs.SNEB_TYPE256_F1B = 'weapons.nurs.SNEB_TYPE256_F1B'
ENUMS.Storage.weapons.missiles.AGM_84H = 'weapons.missiles.AGM_84H'
ENUMS.Storage.weapons.missiles.AIM_54 = 'weapons.missiles.AIM_54'
ENUMS.Storage.weapons.bombs.AB_500_1_SD_10A = 'weapons.bombs.AB_500_1_SD_10A'
ENUMS.Storage.weapons.containers.Eclair = 'weapons.containers.{Eclair}'
ENUMS.Storage.weapons.gunmounts.MB339_ANM3_R = 'weapons.gunmounts.{MB339_ANM3_R}'
ENUMS.Storage.weapons.shells.N37_37x155_API_T = 'weapons.shells.N37_37x155_API_T'
ENUMS.Storage.weapons.shells.MG_20x82_MGsch = 'weapons.shells.MG_20x82_MGsch'
ENUMS.Storage.weapons.containers.fullCargoSeats = 'weapons.containers.fullCargoSeats'
ENUMS.Storage.weapons.shells.British303_G_Mk1 = 'weapons.shells.British303_G_Mk1'
ENUMS.Storage.weapons.adapters.LR25 = 'weapons.adapters.LR-25'
ENUMS.Storage.weapons.gunmounts.CH47_PORT_M134D = 'weapons.gunmounts.{CH47_PORT_M134D}'
ENUMS.Storage.weapons.containers.MIG21_SMOKE_RED = 'weapons.containers.{MIG21_SMOKE_RED}'
ENUMS.Storage.weapons.shells.M53_AP_RED = 'weapons.shells.M53_AP_RED'
ENUMS.Storage.weapons.gunmounts.GIAT_M621_AP = 'weapons.gunmounts.{GIAT_M621_AP}'
ENUMS.Storage.weapons.nurs.C_8CM = 'weapons.nurs.C_8CM'
ENUMS.Storage.weapons.missiles.P_40R = 'weapons.missiles.P_40R'
ENUMS.Storage.weapons.missiles.YJ12 = 'weapons.missiles.YJ-12'
ENUMS.Storage.weapons.missiles.CM_802AKG = 'weapons.missiles.CM_802AKG'
ENUMS.Storage.weapons.missiles.SA9M38M1 = 'weapons.missiles.SA9M38M1'
ENUMS.Storage.weapons.droptanks.AV8BNA_AERO1D_EMPTY = 'weapons.droptanks.AV8BNA_AERO1D_EMPTY'
ENUMS.Storage.weapons.bombs.British_GP_250LB_Bomb_Mk5 = 'weapons.bombs.British_GP_250LB_Bomb_Mk5'
ENUMS.Storage.weapons.shells.British303_Ball_Mk7 = 'weapons.shells.British303_Ball_Mk7'
ENUMS.Storage.weapons.bombs.GBU_43 = 'weapons.bombs.GBU_43'
ENUMS.Storage.weapons.missiles.AGM_88 = 'weapons.missiles.AGM_88'
ENUMS.Storage.weapons.droptanks.droptank_110_gal = 'weapons.droptanks.droptank_110_gal'
ENUMS.Storage.weapons.missiles.GB6SFW = 'weapons.missiles.GB-6-SFW'
ENUMS.Storage.weapons.bombs.SAB_250_FLARE = 'weapons.bombs.SAB_250_FLARE'
ENUMS.Storage.weapons.adapters.ao2_5rt_block1 = 'weapons.adapters.ao-2_5rt_block1'
ENUMS.Storage.weapons.shells._7_62x51 = 'weapons.shells.7_62x51'
ENUMS.Storage.weapons.gunmounts.AKAN_NO_TRC = 'weapons.gunmounts.AKAN_NO_TRC'
ENUMS.Storage.weapons.bombs.LYSBOMB11088 = 'weapons.bombs.LYSBOMB 11088'
ENUMS.Storage.weapons.shells.PKT_7_62_T = 'weapons.shells.PKT_7_62_T'
ENUMS.Storage.weapons.gunmounts.BrowningM2 = 'weapons.gunmounts.BrowningM2'
ENUMS.Storage.weapons.containers.MIG21_SMOKE_WHITE = 'weapons.containers.{MIG21_SMOKE_WHITE}'
ENUMS.Storage.weapons.adapters.BRU_57 = 'weapons.adapters.BRU_57'
ENUMS.Storage.weapons.bombs.MK_82AIR = 'weapons.bombs.MK_82AIR'
ENUMS.Storage.weapons.missiles.R_550 = 'weapons.missiles.R_550'
ENUMS.Storage.weapons.shells.Hispano_Mk_II_APT = 'weapons.shells.Hispano_Mk_II_AP/T'
ENUMS.Storage.weapons.adapters.MAK79_VAR_1 = 'weapons.adapters.MAK-79_VAR_1'
ENUMS.Storage.weapons.nurs.GRAD_9M22U = 'weapons.nurs.GRAD_9M22U'
ENUMS.Storage.weapons.gunmounts.CH47_AFT_M240H = 'weapons.gunmounts.{CH47_AFT_M240H}'
ENUMS.Storage.weapons.shells.GSH_23_AP = 'weapons.shells.GSH_23_AP'
ENUMS.Storage.weapons.missiles.SA9M33 = 'weapons.missiles.SA9M33'
ENUMS.Storage.weapons.missiles.YJ83K = 'weapons.missiles.YJ-83K'
ENUMS.Storage.weapons.shells.MG_13x64_APT = 'weapons.shells.MG_13x64_APT'
ENUMS.Storage.weapons.missiles.AIM7P = 'weapons.missiles.AIM-7P'
ENUMS.Storage.weapons.shells._50Browning_Ball_M2_Corsair = 'weapons.shells.50Browning_Ball_M2_Corsair'
ENUMS.Storage.weapons.nurs.C_8CM_BU = 'weapons.nurs.C_8CM_BU'
ENUMS.Storage.weapons.bombs.OH58D_Yellow_Smoke_Grenade = 'weapons.bombs.OH58D_Yellow_Smoke_Grenade'
ENUMS.Storage.weapons.bombs.GBU_32_V_2B = 'weapons.bombs.GBU_32_V_2B'
ENUMS.Storage.weapons.nurs.SNEB_TYPE257_F1B = 'weapons.nurs.SNEB_TYPE257_F1B'
ENUMS.Storage.weapons.missiles.Rb04EforA_I__ = 'weapons.missiles.Rb 04E (for A.I.)'
ENUMS.Storage.weapons.containers.MB339_SMOKEPOD = 'weapons.containers.MB339_SMOKE-POD'
ENUMS.Storage.weapons.containers.HB_F14_EXT_LAU7 = 'weapons.containers.HB_F14_EXT_LAU-7'
ENUMS.Storage.weapons.missiles.P_27T = 'weapons.missiles.P_27T'
ENUMS.Storage.weapons.adapters.B1B_28store_Conventional_Bomb_Module = 'weapons.adapters.B-1B_28-store_Conventional_Bomb_Module'
ENUMS.Storage.weapons.shells.GAU8_30_TP = 'weapons.shells.GAU8_30_TP'
ENUMS.Storage.weapons.droptanks.LNS_VIG_XTANK = 'weapons.droptanks.LNS_VIG_XTANK'
ENUMS.Storage.weapons.shells._2A7_23_HE = 'weapons.shells.2A7_23_HE'
ENUMS.Storage.weapons.shells.MINGR55 = 'weapons.shells.MINGR55'
ENUMS.Storage.weapons.gunmounts.M230 = 'weapons.gunmounts.M230'
ENUMS.Storage.weapons.shells.MK45_127mm_Essex = 'weapons.shells.MK45_127mm_Essex'
ENUMS.Storage.weapons.droptanks.F15E_Drop_Tank_Empty = 'weapons.droptanks.F-15E_Drop_Tank_Empty'
ENUMS.Storage.weapons.nurs.British_HE_60LBFNo1_3INCHNo1 = 'weapons.nurs.British_HE_60LBFNo1_3INCHNo1'
ENUMS.Storage.weapons.torpedoes.LTF_5B = 'weapons.torpedoes.LTF_5B'
ENUMS.Storage.weapons.adapters.HB_F4E_LAU117 = 'weapons.adapters.HB_F4E_LAU117'
ENUMS.Storage.weapons.containers.HB_ORD_Missile_Well_Adapter = 'weapons.containers.HB_ORD_Missile_Well_Adapter'
ENUMS.Storage.weapons.bombs.SC_500_J = 'weapons.bombs.SC_500_J'
ENUMS.Storage.weapons.adapters.AKU58 = 'weapons.adapters.AKU-58'
ENUMS.Storage.weapons.missiles.PL8A = 'weapons.missiles.PL-8A'
ENUMS.Storage.weapons.gunmounts.MB339_DEFA553_L = 'weapons.gunmounts.{MB339_DEFA553_L}'
ENUMS.Storage.weapons.adapters.UB1657UMP = 'weapons.adapters.UB-16-57UMP'
ENUMS.Storage.weapons.droptanks.fuel_tank_230 = 'weapons.droptanks.fuel_tank_230'
ENUMS.Storage.weapons.nurs.SNEB_TYPE257_H1 = 'weapons.nurs.SNEB_TYPE257_H1'
ENUMS.Storage.weapons.missiles.RB75B = 'weapons.missiles.RB75B'
ENUMS.Storage.weapons.shells.NR30_30x155_HEI_T = 'weapons.shells.NR30_30x155_HEI_T'
ENUMS.Storage.weapons.adapters.apu68um3 = 'weapons.adapters.apu-68um3'
ENUMS.Storage.weapons.missiles.R_550_M1 = 'weapons.missiles.R_550_M1'
ENUMS.Storage.weapons.adapters.OH58D_SRACK_L = 'weapons.adapters.OH58D_SRACK_L'
ENUMS.Storage.weapons.gunmounts.M61 = 'weapons.gunmounts.M-61'
ENUMS.Storage.weapons.missiles.X_41 = 'weapons.missiles.X_41'
ENUMS.Storage.weapons.gunmounts.GSH_23 = 'weapons.gunmounts.GSH_23'
ENUMS.Storage.weapons.missiles.R_530F_EM = 'weapons.missiles.R_530F_EM'
ENUMS.Storage.weapons.containers.kg600 = 'weapons.containers.kg600'
ENUMS.Storage.weapons.missiles.M31 = 'weapons.missiles.M31'
ENUMS.Storage.weapons.bombs._2502 = 'weapons.bombs.250-2'
ENUMS.Storage.weapons.gunmounts.M134_SIDE_L = 'weapons.gunmounts.M134_SIDE_L'
ENUMS.Storage.weapons.missiles.AGM_65B = 'weapons.missiles.AGM_65B'
ENUMS.Storage.weapons.adapters.BRD4250 = 'weapons.adapters.BRD-4-250'
ENUMS.Storage.weapons.bombs.SAMP250LD = 'weapons.bombs.SAMP250LD'
ENUMS.Storage.weapons.containers.AAQ28_LITENING = 'weapons.containers.AAQ-28_LITENING'
ENUMS.Storage.weapons.droptanks.Mosquito_Drop_Tank_50gal = 'weapons.droptanks.Mosquito_Drop_Tank_50gal'
ENUMS.Storage.weapons.shells._7_92x57_Smkl = 'weapons.shells.7_92x57_Smkl'
ENUMS.Storage.weapons.shells.M68_105_HE = 'weapons.shells.M68_105_HE'
ENUMS.Storage.weapons.containers.SPRD_99Twin = 'weapons.containers.SPRD_99Twin'
ENUMS.Storage.weapons.missiles.HBAIM7E = 'weapons.missiles.HB-AIM-7E'
ENUMS.Storage.weapons.shells.M2_12_7_TG = 'weapons.shells.M2_12_7_TG'
ENUMS.Storage.weapons.torpedoes.YU6 = 'weapons.torpedoes.YU-6'
ENUMS.Storage.weapons.bombs.British_MC_250LB_Bomb_Mk2 = 'weapons.bombs.British_MC_250LB_Bomb_Mk2'
ENUMS.Storage.weapons.droptanks.PTB_120_F86F35 = 'weapons.droptanks.PTB_120_F86F35'
ENUMS.Storage.weapons.shells.M256_120_AP_L55 = 'weapons.shells.M256_120_AP_L55'
ENUMS.Storage.weapons.gunmounts.GUV_YakB_GSHP = 'weapons.gunmounts.GUV_YakB_GSHP'
ENUMS.Storage.weapons.bombs.GBU_29 = 'weapons.bombs.GBU_29'
ENUMS.Storage.weapons.gunmounts.GIAT_M261 = 'weapons.gunmounts.GIAT_M261'
ENUMS.Storage.weapons.missiles.R3S = 'weapons.missiles.R-3S'
ENUMS.Storage.weapons.adapters.LAU131 = 'weapons.adapters.LAU-131'
ENUMS.Storage.weapons.gunmounts.KORD_12_7 = 'weapons.gunmounts.KORD_12_7'
ENUMS.Storage.weapons.shells.M230_ADEMDEFA = 'weapons.shells.M230_ADEM/DEFA'
ENUMS.Storage.weapons.missiles.SM_2 = 'weapons.missiles.SM_2'
ENUMS.Storage.weapons.gunmounts.CH47_STBD_M134D = 'weapons.gunmounts.{CH47_STBD_M134D}'
ENUMS.Storage.weapons.missiles.P_27TE = 'weapons.missiles.P_27TE'
ENUMS.Storage.weapons.missiles.X_25ML = 'weapons.missiles.X_25ML'
ENUMS.Storage.weapons.containers.lau105 = 'weapons.containers.lau-105'
ENUMS.Storage.weapons.droptanks.FPU_8A = 'weapons.droptanks.FPU_8A'
ENUMS.Storage.weapons.bombs.BLG66 = 'weapons.bombs.BLG66'
ENUMS.Storage.weapons.shells._2A33_152 = 'weapons.shells.2A33_152'
ENUMS.Storage.weapons.nurs.MO_10104M = 'weapons.nurs.MO_10104M'
ENUMS.Storage.weapons.shells.M825A1_155_SM = 'weapons.shells.M825A1_155_SM'
ENUMS.Storage.weapons.gunmounts.AKAN = 'weapons.gunmounts.AKAN'
ENUMS.Storage.weapons.gunmounts.Browning303MkII = 'weapons.gunmounts.Browning303MkII'
ENUMS.Storage.weapons.nurs.URAGAN_9M27F = 'weapons.nurs.URAGAN_9M27F'
ENUMS.Storage.weapons.nurs.FFARMk5HEAT = 'weapons.nurs.FFAR Mk5 HEAT'
ENUMS.Storage.weapons.nurs.ARF8M3API = 'weapons.nurs.ARF8M3API'
ENUMS.Storage.weapons.shells._3UBM11_100mm_AP = 'weapons.shells.3UBM11_100mm_AP'
ENUMS.Storage.weapons.containers.ASO2 = 'weapons.containers.ASO-2'
ENUMS.Storage.weapons.shells.DEFA552_30 = 'weapons.shells.DEFA552_30'
ENUMS.Storage.weapons.gunmounts.DEFA_553 = 'weapons.gunmounts.DEFA_553'
ENUMS.Storage.weapons.missiles.AGM_45A = 'weapons.missiles.AGM_45A'
ENUMS.Storage.weapons.missiles.Super_530D = 'weapons.missiles.Super_530D'
ENUMS.Storage.weapons.adapters.mbd3u668 = 'weapons.adapters.mbd3-u6-68'
ENUMS.Storage.weapons.adapters.BRU_55 = 'weapons.adapters.BRU_55'
ENUMS.Storage.weapons.adapters.SA342_Telson8 = 'weapons.adapters.SA342_Telson8'
ENUMS.Storage.weapons.adapters.c25pu = 'weapons.adapters.c-25pu'
ENUMS.Storage.weapons.bombs.FAB500TA = 'weapons.bombs.FAB-500TA'
ENUMS.Storage.weapons.bombs.SAMP125LD = 'weapons.bombs.SAMP125LD'
ENUMS.Storage.weapons.bombs.LYSBOMB_CANDLE = 'weapons.bombs.LYSBOMB_CANDLE'
ENUMS.Storage.weapons.missiles.AGM_65F = 'weapons.missiles.AGM_65F'
ENUMS.Storage.weapons.shells._50Browning_AP_M2 = 'weapons.shells.50Browning_AP_M2'
ENUMS.Storage.weapons.shells._5_56x45 = 'weapons.shells.5_56x45'
ENUMS.Storage.weapons.adapters.MatraF1Rocket = 'weapons.adapters.Matra-F1-Rocket'
ENUMS.Storage.weapons.missiles.LS_6_500 = 'weapons.missiles.LS_6_500'
ENUMS.Storage.weapons.missiles.SA9M311 = 'weapons.missiles.SA9M311'
ENUMS.Storage.weapons.shells.AK100_100 = 'weapons.shells.AK100_100'
ENUMS.Storage.weapons.bombs.BLG66_BELOUGA = 'weapons.bombs.BLG66_BELOUGA'
ENUMS.Storage.weapons.bombs.BIN_200 = 'weapons.bombs.BIN_200'
ENUMS.Storage.weapons.containers.pl5eii = 'weapons.containers.pl5eii'
ENUMS.Storage.weapons.gunmounts.CH47_STBD_M240H = 'weapons.gunmounts.{CH47_STBD_M240H}'
ENUMS.Storage.weapons.droptanks.Spitfire_slipper_tank = 'weapons.droptanks.Spitfire_slipper_tank'
ENUMS.Storage.weapons.missiles.HOT3_MBDA = 'weapons.missiles.HOT3_MBDA'
ENUMS.Storage.weapons.shells._53UOR281U = 'weapons.shells.53-UOR-281U'
ENUMS.Storage.weapons.bombs.BDU_50LGB = 'weapons.bombs.BDU_50LGB'
ENUMS.Storage.weapons.gunmounts.SHKAS_GUN = 'weapons.gunmounts.SHKAS_GUN'
ENUMS.Storage.weapons.shells.British303_W_Mk1z = 'weapons.shells.British303_W_Mk1z'
ENUMS.Storage.weapons.adapters.J11A_twinpylon_r = 'weapons.adapters.J-11A_twinpylon_r'
ENUMS.Storage.weapons.missiles.P_700 = 'weapons.missiles.P_700'
ENUMS.Storage.weapons.missiles.SA5V28 = 'weapons.missiles.SA5V28'
ENUMS.Storage.weapons.missiles.MIM_72G = 'weapons.missiles.MIM_72G'
ENUMS.Storage.weapons.adapters.CLB_4 = 'weapons.adapters.CLB_4'
ENUMS.Storage.weapons.droptanks.PTB_200_F86F35 = 'weapons.droptanks.PTB_200_F86F35'
ENUMS.Storage.weapons.shells.Mauser7_92x57_SmK_Lspurgelb = "weapons.shells.Mauser7.92x57_S.m.K._L'spur(gelb)"
ENUMS.Storage.weapons.droptanks.PTB_1500_MIG29A = 'weapons.droptanks.PTB_1500_MIG29A'
ENUMS.Storage.weapons.bombs.GBU_31 = 'weapons.bombs.GBU_31'
ENUMS.Storage.weapons.missiles.Kh66_Grom = 'weapons.missiles.Kh-66_Grom'
ENUMS.Storage.weapons.containers.HB_ALE_40_15_90 = 'weapons.containers.HB_ALE_40_15_90'
ENUMS.Storage.weapons.containers.U22 = 'weapons.containers.U22'
ENUMS.Storage.weapons.adapters.Spitfire_pilon1 = 'weapons.adapters.Spitfire_pilon1'
ENUMS.Storage.weapons.bombs.OH58D_Violet_Smoke_Grenade = 'weapons.bombs.OH58D_Violet_Smoke_Grenade'
ENUMS.Storage.weapons.adapters.adapter_gdj_yj83k = 'weapons.adapters.adapter_gdj_yj83k'
ENUMS.Storage.weapons.adapters.M299 = 'weapons.adapters.M299'
ENUMS.Storage.weapons.adapters.HB_ORD_MER = 'weapons.adapters.HB_ORD_MER'
ENUMS.Storage.weapons.shells.Mauser7_92x57_SmKH = 'weapons.shells.Mauser7.92x57_S.m.K.H.'
ENUMS.Storage.weapons.gunmounts.HMP400 = 'weapons.gunmounts.HMP400'
ENUMS.Storage.weapons.containers.F15E_AXQ14_DATALINK = 'weapons.containers.F-15E_AXQ-14_DATALINK'
ENUMS.Storage.weapons.adapters._9m114_pylon2 = 'weapons.adapters.9m114_pylon2'
ENUMS.Storage.weapons.bombs.BEER_BOMB = 'weapons.bombs.BEER_BOMB'
ENUMS.Storage.weapons.nurs.C_8OFP2 = 'weapons.nurs.C_8OFP2'
ENUMS.Storage.weapons.nurs.SNEB_TYPE254_F1B_RED = 'weapons.nurs.SNEB_TYPE254_F1B_RED'
ENUMS.Storage.weapons.nurs.C_8OM = 'weapons.nurs.C_8OM'
ENUMS.Storage.weapons.shells.M61_20_HE_INVIS = 'weapons.shells.M61_20_HE_INVIS'
ENUMS.Storage.weapons.droptanks.HB_F4E_EXT_WingTank_R = 'weapons.droptanks.HB_F-4E_EXT_WingTank_R'
ENUMS.Storage.weapons.missiles.CATM_65K = 'weapons.missiles.CATM_65K'
ENUMS.Storage.weapons.nurs.FFARM156WP = 'weapons.nurs.FFAR M156 WP'
ENUMS.Storage.weapons.bombs.MK_82SNAKEYE = 'weapons.bombs.MK_82SNAKEYE'
ENUMS.Storage.weapons.shells.Rh202_20_AP = 'weapons.shells.Rh202_20_AP'
ENUMS.Storage.weapons.adapters.M261 = 'weapons.adapters.M261'
ENUMS.Storage.weapons.bombs.KAB_1500T = 'weapons.bombs.KAB_1500T'
ENUMS.Storage.weapons.shells.M339_120mm_HEAT_MP_T = 'weapons.shells.M339_120mm_HEAT_MP_T'
ENUMS.Storage.weapons.shells.UOF_17_100HE = 'weapons.shells.UOF_17_100HE'
ENUMS.Storage.weapons.nurs.SNEB_TYPE259E_F1B = 'weapons.nurs.SNEB_TYPE259E_F1B'
ENUMS.Storage.weapons.shells._5_45x39_NOtr = 'weapons.shells.5_45x39_NOtr'
ENUMS.Storage.weapons.gunmounts.CH47_AFT_M3M = 'weapons.gunmounts.{CH47_AFT_M3M}'
ENUMS.Storage.weapons.containers.Fantasm = 'weapons.containers.Fantasm'
ENUMS.Storage.weapons.missiles.AGM_12C_ED = 'weapons.missiles.AGM_12C_ED'
ENUMS.Storage.weapons.droptanks.PTB760_MIG19 = 'weapons.droptanks.PTB760_MIG19'
ENUMS.Storage.weapons.missiles.SA9M330 = 'weapons.missiles.SA9M330'
ENUMS.Storage.weapons.missiles.BK90_MJ1_MJ2 = 'weapons.missiles.BK90_MJ1_MJ2'
ENUMS.Storage.weapons.containers.HB_F14_EXT_AN_APQ167 = 'weapons.containers.HB_F14_EXT_AN_APQ-167'
ENUMS.Storage.weapons.containers.MB339_TravelPod = 'weapons.containers.MB339_TravelPod'
ENUMS.Storage.weapons.gunmounts.OH58D_M3P_L200 = 'weapons.gunmounts.OH58D_M3P_L200'
ENUMS.Storage.weapons.adapters.B1B_10store_Conventional_Bomb_Module = 'weapons.adapters.B-1B_10-store_Conventional_Bomb_Module'
ENUMS.Storage.weapons.shells.GSH23_23_HE_T = 'weapons.shells.GSH23_23_HE_T'
ENUMS.Storage.weapons.containers.TANGAZH = 'weapons.containers.TANGAZH'
ENUMS.Storage.weapons.nurs.HYDRA_70_MK5 = 'weapons.nurs.HYDRA_70_MK5'
ENUMS.Storage.weapons.bombs.FAB_100M = 'weapons.bombs.FAB_100M'
ENUMS.Storage.weapons.gunmounts.CH47_PORT_M60D = 'weapons.gunmounts.{CH47_PORT_M60D}'
ENUMS.Storage.weapons.missiles.M48 = 'weapons.missiles.M48'
ENUMS.Storage.weapons.shells.MAUZER30_30 = 'weapons.shells.MAUZER30_30'
ENUMS.Storage.weapons.adapters.tu22m3mbd = 'weapons.adapters.tu-22m3-mbd'
ENUMS.Storage.weapons.gunmounts.DEFA554 = 'weapons.gunmounts.DEFA 554'
ENUMS.Storage.weapons.droptanks.F4U1D_Drop_Tank_Mk6 = 'weapons.droptanks.F4U-1D_Drop_Tank_Mk6'
ENUMS.Storage.weapons.containers.US_M10_SMOKE_TANK_YELLOW = 'weapons.containers.{US_M10_SMOKE_TANK_YELLOW}'
ENUMS.Storage.weapons.bombs.HEBOMB = 'weapons.bombs.HEBOMB'
ENUMS.Storage.weapons.nurs.Rkt_901_HE = 'weapons.nurs.Rkt_90-1_HE'
ENUMS.Storage.weapons.adapters.HB_F14_EXT_BRU42 = 'weapons.adapters.HB_F14_EXT_BRU42'
ENUMS.Storage.weapons.missiles.YJ62 = 'weapons.missiles.YJ-62'
ENUMS.Storage.weapons.shells.KDA_35_HE = 'weapons.shells.KDA_35_HE'
ENUMS.Storage.weapons.shells._2A7_23_AP = 'weapons.shells.2A7_23_AP'
ENUMS.Storage.weapons.adapters.SA342_LAU_HOT3_1x = 'weapons.adapters.SA342_LAU_HOT3_1x'
ENUMS.Storage.weapons.missiles.P_9M117 = 'weapons.missiles.P_9M117'
ENUMS.Storage.weapons.adapters.MBD267U = 'weapons.adapters.MBD-2-67U'
ENUMS.Storage.weapons.shells.AK630_30_HE = 'weapons.shells.AK630_30_HE'
ENUMS.Storage.weapons.bombs.British_GP_500LB_Bomb_Mk5 = 'weapons.bombs.British_GP_500LB_Bomb_Mk5'
ENUMS.Storage.weapons.bombs.LUU_2AB = 'weapons.bombs.LUU_2AB'
ENUMS.Storage.weapons.missiles.BK90_MJ2 = 'weapons.missiles.BK90_MJ2'
ENUMS.Storage.weapons.shells.British303_B_Mk4z = 'weapons.shells.British303_B_Mk4z'
ENUMS.Storage.weapons.adapters.BRU_41A = 'weapons.adapters.BRU_41A'
ENUMS.Storage.weapons.bombs.BDU_45 = 'weapons.bombs.BDU_45'
ENUMS.Storage.weapons.adapters.b20 = 'weapons.adapters.b-20'
ENUMS.Storage.weapons.missiles.Rapier = 'weapons.missiles.Rapier'
ENUMS.Storage.weapons.missiles.P_24R = 'weapons.missiles.P_24R'
ENUMS.Storage.weapons.missiles.AGM_84S = 'weapons.missiles.AGM_84S'
ENUMS.Storage.weapons.adapters.C25PU = 'weapons.adapters.C-25PU'
ENUMS.Storage.weapons.containers.BOZ100 = 'weapons.containers.BOZ-100'
ENUMS.Storage.weapons.missiles.AGM_65E = 'weapons.missiles.AGM_65E'
ENUMS.Storage.weapons.adapters._9M120_pylon2 = 'weapons.adapters.9M120_pylon2'
ENUMS.Storage.weapons.shells.YakB_12_7_T = 'weapons.shells.YakB_12_7_T'
ENUMS.Storage.weapons.containers.IRDeflector = 'weapons.containers.IRDeflector'
ENUMS.Storage.weapons.missiles.AIM9P = 'weapons.missiles.AIM-9P'
ENUMS.Storage.weapons.missiles.SA5B27 = 'weapons.missiles.SA5B27'
ENUMS.Storage.weapons.bombs.SC_500_L2 = 'weapons.bombs.SC_500_L2'
ENUMS.Storage.weapons.containers.HB_F14_EXT_ECA = 'weapons.containers.HB_F14_EXT_ECA'
ENUMS.Storage.weapons.bombs.SAMP400HD = 'weapons.bombs.SAMP400HD'
ENUMS.Storage.weapons.adapters.ARAKM70B = 'weapons.adapters.ARAKM70B'
ENUMS.Storage.weapons.adapters.M260 = 'weapons.adapters.M260'
ENUMS.Storage.weapons.shells.Mauser7_92x57_PmK = 'weapons.shells.Mauser7.92x57_P.m.K.'
ENUMS.Storage.weapons.missiles.RB75T = 'weapons.missiles.RB75T'
ENUMS.Storage.weapons.missiles.YJ82 = 'weapons.missiles.YJ-82'
ENUMS.Storage.weapons.bombs.FAB500M54TU = 'weapons.bombs.FAB-500M54TU'
ENUMS.Storage.weapons.bombs.OH58D_White_Smoke_Grenade = 'weapons.bombs.OH58D_White_Smoke_Grenade'
ENUMS.Storage.weapons.missiles.X_29TE = 'weapons.missiles.X_29TE'
ENUMS.Storage.weapons.missiles.S_25L = 'weapons.missiles.S_25L'
ENUMS.Storage.weapons.nurs.British_AP_25LBNo1_3INCHNo1 = 'weapons.nurs.British_AP_25LBNo1_3INCHNo1'
ENUMS.Storage.weapons.adapters.lau105 = 'weapons.adapters.lau-105'
ENUMS.Storage.weapons.containers.US_M10_SMOKE_TANK_WHITE = 'weapons.containers.{US_M10_SMOKE_TANK_WHITE}'
ENUMS.Storage.weapons.bombs.Mk_82 = 'weapons.bombs.Mk_82'
ENUMS.Storage.weapons.adapters.BRU42_LS_SUU25 = 'weapons.adapters.BRU-42_LS_(SUU-25)'
ENUMS.Storage.weapons.missiles.Aster_30_Blk_1 = 'weapons.missiles.Aster 30 Blk 1'
ENUMS.Storage.weapons.missiles.Aster_30_Blk_1NT = 'weapons.missiles.Aster 30 Blk 1NT'
ENUMS.Storage.weapons.missiles.Aster_30_Blk_2 = 'weapons.missiles.Aster 30 Blk 2'
ENUMS.Storage.weapons.missiles.SA9M83M = 'weapons.missiles.SA9M83M'
ENUMS.Storage.weapons.gunmounts.C130_M4_Rifle = 'weapons.gunmounts.C130_M4_Rifle'
ENUMS.Storage.weapons.gunmounts.C130_M18_Sidearm_ = 'weapons.gunmounts.{C130-M18-Sidearm}'
ENUMS.Storage.weapons.gunmounts.C130_Cargo_Bay_M4 = 'weapons.gunmounts.{C130-Cargo-Bay-M4}'
ENUMS.Storage.weapons.gunmounts.C130_M18_Sidearm = 'weapons.gunmounts.C130_M18_Sidearm'
ENUMS.Storage.weapons.droptanks.C130J_Ext_Tank_R = 'weapons.droptanks.C130J_Ext_Tank_R'
ENUMS.Storage.weapons.droptanks.C130J_Ext_Tank_L = 'weapons.droptanks.C130J_Ext_Tank_L'
ENUMS.Storage.weapons.missiles.SAHQ2 = 'weapons.missiles.SAHQ2'
ENUMS.Storage.weapons.missiles.Strela_2 = 'weapons.missiles.Strela-2'
ENUMS.Storage.weapons.missiles.Strela_2M = 'weapons.missiles.Strela-2M'
ENUMS.Storage.weapons.missiles.Strela_3 = 'weapons.missiles.Strela-3'
ENUMS.Storage.weapons.missiles.SA9M83 = 'weapons.missiles.SA9M83'
ENUMS.Storage.weapons.missiles.SAV601P = 'weapons.missiles.SAV601P'
ENUMS.Storage.weapons.missiles.SA2V759 = 'weapons.missiles.SA2V759'
ENUMS.Storage.weapons.missiles.SA9M317 = 'weapons.missiles.SA9M317'
ENUMS.Storage.weapons.missiles.SA9M82M = 'weapons.missiles.SA9M82M'
ENUMS.Storage.weapons.missiles.SA9M82 = 'weapons.missiles.SA9M82'
ENUMS.Storage.weapons.missiles.Igla_S = 'weapons.missiles.Igla_S'
ENUMS.Storage.weapons.gunmounts.AKAN_NO_TRC = 'weapons.gunmounts.{AKAN_NO_TRC}'
ENUMS.Storage.weapons.gunmounts.AKAN = 'weapons.gunmounts.{AKAN}'
ENUMS.Storage.weapons.shells.M882_9x19 = 'weapons.shells.9x19_m882'
ENUMS.Storage.weapons.droptanks.fuel_tank_370gal = "weapons.droptanks.fuel_tank_370gal"
ENUMS.Storage.weapons.droptanks.fuel_tank_300gal  = "weapons.droptanks.fuel_tank_300gal"

-- NEW
ENUMS.Storage.weapons.adapters.HB_F_4E_ORD_LAU_77 = 'weapons.adapters.HB_F-4E_ORD_LAU_77'
ENUMS.Storage.weapons.adapters.hb_a_6e_lau7_adu299 = 'weapons.adapters.hb_a-6e_lau7_adu299'

ENUMS.Storage.weapons.bombs.AH6_SMOKE_BLUE = 'weapons.bombs.AH6_SMOKE_BLUE'
ENUMS.Storage.weapons.bombs.AH6_SMOKE_GREEN = 'weapons.bombs.AH6_SMOKE_GREEN'
ENUMS.Storage.weapons.bombs.AH6_SMOKE_RED = 'weapons.bombs.AH6_SMOKE_RED'
ENUMS.Storage.weapons.bombs.AH6_SMOKE_YELLOW = 'weapons.bombs.AH6_SMOKE_YELLOW'

ENUMS.Storage.weapons.missiles.HB_AGM_78 = 'weapons.missiles.HB_AGM_78'
ENUMS.Storage.weapons.missiles.V_1 = 'weapons.missiles.V-1'

ENUMS.Storage.weapons.shells.Oerlikon_20mm_HE = 'weapons.shells.Oerlikon_20mm_HE'
ENUMS.Storage.weapons.shells.RM_15cm_HE = 'weapons.shells.RM_15cm_HE'
ENUMS.Storage.weapons.shells.HE_T_MkII_40mm = 'weapons.shells.HE_T_MkII_40mm'
ENUMS.Storage.weapons.shells.APCBC = 'weapons.shells.APCBC'
ENUMS.Storage.weapons.shells.Sprgr_43_L71 = 'weapons.shells.Sprgr_43_L71'
ENUMS.Storage.weapons.shells.Mk_20_HE_shell = 'weapons.shells.Mk_20_HE_shell'
ENUMS.Storage.weapons.shells.Pzgr_39_42 = 'weapons.shells.Pzgr_39/42'
ENUMS.Storage.weapons.shells.M1_37mm_37AP_T = 'weapons.shells.M1_37mm_37AP-T'
ENUMS.Storage.weapons.shells.Sprgr_38 = 'weapons.shells.Sprgr_38'
ENUMS.Storage.weapons.shells.Sprgr_39 = 'weapons.shells.Sprgr_39'
ENUMS.Storage.weapons.shells.Pzgr_39_43 = 'weapons.shells.Pzgr_39/43'
ENUMS.Storage.weapons.shells.Pzgr_39_5cm = 'weapons.shells.Pzgr_39_5cm'
ENUMS.Storage.weapons.shells.AP_2A20_115mm = 'weapons.shells.2A20_115mm_AP'
ENUMS.Storage.weapons.shells.AP_T_MkI_40mm = 'weapons.shells.AP_T_MkI_40mm'
ENUMS.Storage.weapons.shells.AP_37x263 = 'weapons.shells.37x263_AP'
ENUMS.Storage.weapons.shells.AP_20x138B = 'weapons.shells.20x138B_AP'
ENUMS.Storage.weapons.shells.Besa7_92x57T = 'weapons.shells.Besa7_92x57T'
ENUMS.Storage.weapons.shells.Sprgr_34_L70 = 'weapons.shells.Sprgr_34_L70'
ENUMS.Storage.weapons.shells.QF94_AA_HE = 'weapons.shells.QF94_AA_HE'
ENUMS.Storage.weapons.shells.AH_6762x51mm_M62 = 'weapons.shells.AH-6 7.62x51mm M62'
ENUMS.Storage.weapons.shells.AH_6762x51mm_M80 = 'weapons.shells.AH-6 7.62x51mm M80'
ENUMS.Storage.weapons.shells.AH_6_762x51mm_M61 = 'weapons.shells.AH-6 7.62x51mm M61'
ENUMS.Storage.weapons.shells.leFH18_105HE = 'weapons.shells.leFH18_105HE'
ENUMS.Storage.weapons.shells.M63_37HE = 'weapons.shells.M63_37HE'
ENUMS.Storage.weapons.shells.QF95_206R_fixed = 'weapons.shells.QF95_206R_fixed'
ENUMS.Storage.weapons.shells.UBR_365_85AP = 'weapons.shells.UBR_365_85AP'
ENUMS.Storage.weapons.shells.M101 = 'weapons.shells.M101'
ENUMS.Storage.weapons.shells.HE_M1_Shell = 'weapons.shells.HE_M1_Shell'
ENUMS.Storage.weapons.shells.UO_365K_85HE = 'weapons.shells.UO_365K_85HE'
ENUMS.Storage.weapons.shells.Flak41_Sprgr_39 = 'weapons.shells.Flak41_Sprgr_39'
ENUMS.Storage.weapons.shells.M1_37mm_HE_T = 'weapons.shells.M1_37mm_HE-T'
ENUMS.Storage.weapons.shells.QF17_HE = 'weapons.shells.QF17_HE'
ENUMS.Storage.weapons.shells.Pzgr_39 = 'weapons.shells.Pzgr_39'
ENUMS.Storage.weapons.shells.Besa7_92x57 = 'weapons.shells.Besa7_92x57'
ENUMS.Storage.weapons.shells.I_Gr_33 = 'weapons.shells.I_Gr_33'
ENUMS.Storage.weapons.shells.M62_APC = 'weapons.shells.M62_APC'
ENUMS.Storage.weapons.shells.Mk_12_HE_shell = 'weapons.shells.Mk_12_HE_shell'
ENUMS.Storage.weapons.shells.M51_37AP = 'weapons.shells.M51_37AP'
ENUMS.Storage.weapons.shells.M42A1_HE = 'weapons.shells.M42A1_HE'
ENUMS.Storage.weapons.shells.HE_20x138B = 'weapons.shells.20x138B_HE'
ENUMS.Storage.weapons.shells.HE_37x263 = 'weapons.shells.37x263_HE'
ENUMS.Storage.weapons.shells.HE_2A20_115mm = 'weapons.shells.2A20_115mm_HE'

ENUMS.Storage.weapons.gunmounts.B17_TailTurret_M2_L = 'weapons.gunmounts.B17_TailTurret_M2_L'
ENUMS.Storage.weapons.gunmounts.AH6_M134L = 'weapons.gunmounts.{AH6_M134L}'
ENUMS.Storage.weapons.gunmounts.B17_Left_Nose_M2 = 'weapons.gunmounts.B17_Left_Nose_M2'
ENUMS.Storage.weapons.gunmounts.Ju88_Turret_Top_Right_MG_81 = 'weapons.gunmounts.Ju88_Turret_Top_Right_MG_81'
ENUMS.Storage.weapons.gunmounts.Ju88_Turret_Bottom_MG_81_L = 'weapons.gunmounts.Ju88_Turret_Bottom_MG_81_L'
ENUMS.Storage.weapons.gunmounts.B17_ChinTurret_M2_R = 'weapons.gunmounts.B17_ChinTurret_M2_R'
ENUMS.Storage.weapons.gunmounts.B17_Waist_Right_M2 = 'weapons.gunmounts.B17_Waist_Right_M2'
ENUMS.Storage.weapons.gunmounts.AH_6_Door_Gun = 'weapons.gunmounts.AH-6_Door_Gun'
ENUMS.Storage.weapons.gunmounts.B17_BallTurret_M2_L = 'weapons.gunmounts.B17_BallTurret_M2_L'
ENUMS.Storage.weapons.gunmounts.B17_BallTurret_M2_R = 'weapons.gunmounts.B17_BallTurret_M2_R'
ENUMS.Storage.weapons.gunmounts.B17_TopTurret_M2_R = 'weapons.gunmounts.B17_TopTurret_M2_R'
ENUMS.Storage.weapons.gunmounts.B17_Right_Nose_M2 = 'weapons.gunmounts.B17_Right_Nose_M2'
ENUMS.Storage.weapons.gunmounts.Ju88_Turret_Bottom_MG_81_R = 'weapons.gunmounts.Ju88_Turret_Bottom_MG_81_R'
ENUMS.Storage.weapons.gunmounts.B17_TopTurret_M2_L = 'weapons.gunmounts.B17_TopTurret_M2_L'
ENUMS.Storage.weapons.gunmounts.B17_Waist_Left_M2 = 'weapons.gunmounts.B17_Waist_Left_M2'
ENUMS.Storage.weapons.gunmounts.Ju88_Turret_ahead_MG_81 = 'weapons.gunmounts.Ju88_Turret_ahead_MG_81'
ENUMS.Storage.weapons.gunmounts.AH6_M134R = 'weapons.gunmounts.{AH6_M134R}'
ENUMS.Storage.weapons.gunmounts.Ju88_Turret_Top_Left_MG_81 = 'weapons.gunmounts.Ju88_Turret_Top_Left_MG_81'
ENUMS.Storage.weapons.gunmounts.B17_TailTurret_M2_R = 'weapons.gunmounts.B17_TailTurret_M2_R'
ENUMS.Storage.weapons.gunmounts.AKAN_NO_TRC = 'weapons.gunmounts.AKAN_NO_TRC'
ENUMS.Storage.weapons.gunmounts.AKAN = 'weapons.gunmounts.AKAN'
ENUMS.Storage.weapons.gunmounts.B17_ChinTurret_M2_L = 'weapons.gunmounts.B17_ChinTurret_M2_L'
ENUMS.Storage.weapons.gunmounts.AKAN = 'weapons.gunmounts.AKAN'
ENUMS.Storage.weapons.gunmounts.AKAN_NO_TRC = 'weapons.gunmounts.AKAN_NO_TRC'
ENUMS.Storage.weapons.gunmounts.AH_6_Door = 'weapons.gunmounts.{AH-6_Door}'
ENUMS.Storage.weapons.gunmounts.AH_6_FN_HMP400 = 'weapons.gunmounts.{AH-6_FN_HMP400}'
ENUMS.Storage.weapons.gunmounts.AH_6_M134L = 'weapons.gunmounts.AH-6_M134L'
ENUMS.Storage.weapons.gunmounts.AH_6_M134R = 'weapons.gunmounts.AH-6_M134R'
ENUMS.Storage.weapons.gunmounts.AH_6_HMP400 = 'weapons.gunmounts.AH-6_HMP400'

ENUMS.Storage.weapons.droptanks.PTB_800 = 'weapons.droptanks.PTB-800'
ENUMS.Storage.weapons.droptanks.PTB_275 = 'weapons.droptanks.PTB-275'
ENUMS.Storage.weapons.droptanks.HB_A6E_AERO1D_EMPTY = 'weapons.droptanks.HB_A6E_AERO1D_EMPTY'
ENUMS.Storage.weapons.droptanks.Drop_tank_75gal = 'weapons.droptanks.Drop tank 75gal'
ENUMS.Storage.weapons.droptanks.S_3_PTB = 'weapons.droptanks.S-3-PTB'
ENUMS.Storage.weapons.droptanks.PTB_3000 = 'weapons.droptanks.PTB-3000'
ENUMS.Storage.weapons.droptanks.HB_A6E_D704 = 'weapons.droptanks.HB_A6E_D704'
ENUMS.Storage.weapons.droptanks.PTB_1150_29 = 'weapons.droptanks.PTB-1150-29'
ENUMS.Storage.weapons.droptanks.f_18c_ptb = 'weapons.droptanks.f-18c-ptb'
ENUMS.Storage.weapons.droptanks.F4_BAK_L = 'weapons.droptanks.F4-BAK-L'
ENUMS.Storage.weapons.droptanks.HB_A6E_AERO1D = 'weapons.droptanks.HB_A6E_AERO1D'
ENUMS.Storage.weapons.droptanks.IAFS_ComboPak_100 = 'weapons.droptanks.{IAFS_ComboPak_100}'
ENUMS.Storage.weapons.droptanks.PTB_2000 = 'weapons.droptanks.PTB-2000'
ENUMS.Storage.weapons.droptanks.M2000_PTB = 'weapons.droptanks.M2000-PTB'
ENUMS.Storage.weapons.droptanks.PTB_150 = 'weapons.droptanks.PTB-150'
ENUMS.Storage.weapons.droptanks.PTB_1150 = 'weapons.droptanks.PTB-1150'
ENUMS.Storage.weapons.droptanks.fuel_tank_300gal = 'weapons.droptanks.fuel_tank_300gal'
ENUMS.Storage.weapons.droptanks.MIG_25_PTB = 'weapons.droptanks.MIG-25-PTB'
ENUMS.Storage.weapons.droptanks.PTB_1500 = 'weapons.droptanks.PTB-1500'
ENUMS.Storage.weapons.droptanks.MIG_23_PTB = 'weapons.droptanks.MIG-23-PTB'
ENUMS.Storage.weapons.droptanks.FT600 = 'weapons.droptanks.FT600'
ENUMS.Storage.weapons.droptanks.F15_PTB = 'weapons.droptanks.F15-PTB'
ENUMS.Storage.weapons.droptanks.ah6_auxtank = 'weapons.droptanks.ah6_auxtank'
ENUMS.Storage.weapons.droptanks.T_PTB = 'weapons.droptanks.T-PTB'
ENUMS.Storage.weapons.droptanks.fuel_tank_370gal = 'weapons.droptanks.fuel_tank_370gal'
ENUMS.Storage.weapons.droptanks.F4_BAK_C = 'weapons.droptanks.F4-BAK-C'
ENUMS.Storage.weapons.droptanks.F16_PTB_N2 = 'weapons.droptanks.F-16-PTB-N2'
ENUMS.Storage.weapons.droptanks.PTB_800 = 'weapons.droptanks.PTB-800'
ENUMS.Storage.weapons.droptanks.PTB_275 = 'weapons.droptanks.PTB-275'
ENUMS.Storage.weapons.droptanks.T_PTB = 'weapons.droptanks.T-PTB'
ENUMS.Storage.weapons.droptanks.F16_PTB_N2 = 'weapons.droptanks.F-16-PTB-N2'
ENUMS.Storage.weapons.droptanks.F4_BAK_C = 'weapons.droptanks.F4-BAK-C'
ENUMS.Storage.weapons.droptanks.PTB_1150_29 = 'weapons.droptanks.PTB-1150-29'
ENUMS.Storage.weapons.droptanks.PTB_1150 = 'weapons.droptanks.PTB-1150'
ENUMS.Storage.weapons.droptanks.fuel_tank_300gal = 'weapons.droptanks.fuel_tank_300gal'
ENUMS.Storage.weapons.droptanks.MIG_25_PTB = 'weapons.droptanks.MIG-25-PTB'
ENUMS.Storage.weapons.droptanks.PTB_1500 = 'weapons.droptanks.PTB-1500'
ENUMS.Storage.weapons.droptanks.FT600 = 'weapons.droptanks.FT600'
ENUMS.Storage.weapons.droptanks.Drop_tank_75gal = 'weapons.droptanks.Drop tank 75gal'
ENUMS.Storage.weapons.droptanks.F15_PTB = 'weapons.droptanks.F15-PTB'
ENUMS.Storage.weapons.droptanks.M2000_PTB = 'weapons.droptanks.M2000-PTB'
ENUMS.Storage.weapons.droptanks.PTB_150 = 'weapons.droptanks.PTB-150'
ENUMS.Storage.weapons.droptanks.F4_BAK_L = 'weapons.droptanks.F4-BAK-L'
ENUMS.Storage.weapons.droptanks.PTB_3000 = 'weapons.droptanks.PTB-3000'
ENUMS.Storage.weapons.droptanks.PTB_2000 = 'weapons.droptanks.PTB-2000'
ENUMS.Storage.weapons.droptanks.S_3_PTB = 'weapons.droptanks.S-3-PTB'
ENUMS.Storage.weapons.droptanks.fuel_tank_370gal = 'weapons.droptanks.fuel_tank_370gal'
ENUMS.Storage.weapons.droptanks.MIG_23_PTB = 'weapons.droptanks.MIG-23-PTB'
ENUMS.Storage.weapons.droptanks.f_18c_ptb = 'weapons.droptanks.f-18c-ptb'

ENUMS.Storage.weapons.containers.FN_HMP400_100 = 'weapons.containers.{FN_HMP400_100}'
ENUMS.Storage.weapons.containers.AN_M3 = 'weapons.containers.{AN-M3}'
ENUMS.Storage.weapons.containers.OH58D_M3P_L500 = 'weapons.containers.OH58D_M3P_L500'
ENUMS.Storage.weapons.containers.GIAT_M621_HE = 'weapons.containers.{GIAT_M621_HE}'
ENUMS.Storage.weapons.containers.KORD_12_7_MI24_L = 'weapons.containers.KORD_12_7_MI24_L'
ENUMS.Storage.weapons.containers.CH47_STBD_M240H = 'weapons.containers.{CH47_STBD_M240H}'
ENUMS.Storage.weapons.containers.CH47_AFT_M60D = 'weapons.containers.{CH47_AFT_M60D}'
ENUMS.Storage.weapons.containers.UPK_23_250_MiG_21 = 'weapons.containers.{UPK-23-250 MiG-21}'
ENUMS.Storage.weapons.containers.CH47_STBD_M134D = 'weapons.containers.{CH47_STBD_M134D}'
ENUMS.Storage.weapons.containers.GAU_12_Equalizer = 'weapons.containers.{GAU_12_Equalizer}'
ENUMS.Storage.weapons.containers.PKT_7_62 = 'weapons.containers.PKT_7_62'
ENUMS.Storage.weapons.containers.CH47_AFT_M240H = 'weapons.containers.{CH47_AFT_M240H}'
ENUMS.Storage.weapons.containers.GIAT_M621_SAPHEI = 'weapons.containers.{GIAT_M621_SAPHEI}'
ENUMS.Storage.weapons.containers.ADEN_GUNPOD = 'weapons.containers.{ADEN_GUNPOD}'
ENUMS.Storage.weapons.containers.GAU_12_Equalizer_HE = 'weapons.containers.{GAU_12_Equalizer_HE}'
ENUMS.Storage.weapons.containers.M60_SIDE_L = 'weapons.containers.M60_SIDE_L'
ENUMS.Storage.weapons.containers.KORD_12_7_MI24_R = 'weapons.containers.KORD_12_7_MI24_R'
ENUMS.Storage.weapons.containers.GIAT_M621_APHE = 'weapons.containers.{GIAT_M621_APHE}'
ENUMS.Storage.weapons.containers.MB339_ANM3_L = 'weapons.containers.{MB339_ANM3_L}'
ENUMS.Storage.weapons.containers.FN_HMP400 = 'weapons.containers.{FN_HMP400}'
ENUMS.Storage.weapons.containers.AH_6_Door = 'weapons.containers.{AH-6_Door}'
ENUMS.Storage.weapons.containers.MB339_DEFA553_L = 'weapons.containers.{MB339_DEFA553_L}'
ENUMS.Storage.weapons.containers.MB339_ANM3_R = 'weapons.containers.{MB339_ANM3_R}'
ENUMS.Storage.weapons.containers.PK_3 = 'weapons.containers.{PK-3}'
ENUMS.Storage.weapons.containers.GUV_VOG = 'weapons.containers.GUV_VOG'
ENUMS.Storage.weapons.containers.SA342_M134_SIDE_R = 'weapons.containers.{SA342_M134_SIDE_R}'
ENUMS.Storage.weapons.containers.OH58D_M3P_L100 = 'weapons.containers.OH58D_M3P_L100'
ENUMS.Storage.weapons.containers.MXU_648 = 'weapons.containers.MXU-648'
ENUMS.Storage.weapons.containers.OH58D_M3P_L400 = 'weapons.containers.OH58D_M3P_L400'
ENUMS.Storage.weapons.containers.FN_HMP400_200 = 'weapons.containers.{FN_HMP400_200}'
ENUMS.Storage.weapons.containers.GIAT_M621_HE = 'weapons.containers.{GIAT_M621_HE}'
ENUMS.Storage.weapons.containers.M134_L = 'weapons.containers.M134_L'
ENUMS.Storage.weapons.containers.OH58D_M3P_L200 = 'weapons.containers.OH58D_M3P_L200'
ENUMS.Storage.weapons.containers.GIAT_M621_AP = 'weapons.containers.{GIAT_M621_AP}'
ENUMS.Storage.weapons.containers.CH47_STBD_M134D = 'weapons.containers.{CH47_STBD_M134D}'
ENUMS.Storage.weapons.containers.PKT_7_62 = 'weapons.containers.PKT_7_62'
ENUMS.Storage.weapons.containers.OH58D_M3P_L300 = 'weapons.containers.OH58D_M3P_L300'
ENUMS.Storage.weapons.containers.GIAT_M621_SAPHEI = 'weapons.containers.{GIAT_M621_SAPHEI}'
ENUMS.Storage.weapons.containers.M60_SIDE_L = 'weapons.containers.M60_SIDE_L'
ENUMS.Storage.weapons.containers.CH47_PORT_M134D = 'weapons.containers.{CH47_PORT_M134D}'
ENUMS.Storage.weapons.containers.CH47_PORT_M60D = 'weapons.containers.{CH47_PORT_M60D}'
ENUMS.Storage.weapons.containers.ADEN_GUNPOD = 'weapons.containers.{ADEN_GUNPOD}'
ENUMS.Storage.weapons.containers.C_101_DEFA553 = 'weapons.containers.{C-101-DEFA553}'
ENUMS.Storage.weapons.containers.MB339_ANM3_R = 'weapons.containers.{MB339_ANM3_R}'
ENUMS.Storage.weapons.containers.CH47_AFT_M60D = 'weapons.containers.{CH47_AFT_M60D}'
ENUMS.Storage.weapons.containers.KORD_12_7 = 'weapons.containers.KORD_12_7'
ENUMS.Storage.weapons.containers.GIAT_M621_HEAP = 'weapons.containers.{GIAT_M621_HEAP}'
ENUMS.Storage.weapons.containers.CH47_AFT_M3M = 'weapons.containers.{CH47_AFT_M3M}'
ENUMS.Storage.weapons.containers.GUV_YakB_GSHP = 'weapons.containers.GUV_YakB_GSHP'
ENUMS.Storage.weapons.containers.R_73U = 'weapons.containers.R-73U'
ENUMS.Storage.weapons.containers.GUV_VOG = 'weapons.containers.GUV_VOG'
ENUMS.Storage.weapons.containers.KORD_12_7_MI24_L = 'weapons.containers.KORD_12_7_MI24_L'
ENUMS.Storage.weapons.containers.OH58D_M3P_L100 = 'weapons.containers.OH58D_M3P_L100'
ENUMS.Storage.weapons.containers.OH58D_M3P_L400 = 'weapons.containers.OH58D_M3P_L400'
ENUMS.Storage.weapons.containers.CH47_STBD_M240H = 'weapons.containers.{CH47_STBD_M240H}'
ENUMS.Storage.weapons.containers.CH47_PORT_M240H = 'weapons.containers.{CH47_PORT_M240H}'
ENUMS.Storage.weapons.containers.CC420_GUN_POD = 'weapons.containers.{CC420_GUN_POD}'
ENUMS.Storage.weapons.containers.FN_HMP400_100 = 'weapons.containers.{FN_HMP400_100}'
ENUMS.Storage.weapons.containers.MB339_ANM3_L = 'weapons.containers.{MB339_ANM3_L}'
ENUMS.Storage.weapons.containers.MB339_DEFA553_R = 'weapons.containers.{MB339_DEFA553_R}'
ENUMS.Storage.weapons.containers.GAU_12_Equalizer_HE = 'weapons.containers.{GAU_12_Equalizer_HE}'
ENUMS.Storage.weapons.containers.OH58D_M3P_L500 = 'weapons.containers.OH58D_M3P_L500'
ENUMS.Storage.weapons.containers.SUU_23_POD = 'weapons.containers.{SUU_23_POD}'
ENUMS.Storage.weapons.containers.PK_3 = 'weapons.containers.{PK-3}'
ENUMS.Storage.weapons.containers.AKAN = 'weapons.containers.{AKAN}'
ENUMS.Storage.weapons.containers.CH47_STBD_M60D = 'weapons.containers.{CH47_STBD_M60D}'
ENUMS.Storage.weapons.containers.SA342_M134_SIDE_R = 'weapons.containers.{SA342_M134_SIDE_R}'
ENUMS.Storage.weapons.containers.M60_SIDE_R = 'weapons.containers.M60_SIDE_R'
ENUMS.Storage.weapons.containers.GAU_12_Equalizer_AP = 'weapons.containers.{GAU_12_Equalizer_AP}'
ENUMS.Storage.weapons.containers.GAU_12_Equalizer = 'weapons.containers.{GAU_12_Equalizer}'
ENUMS.Storage.weapons.containers.KORD_12_7_MI24_R = 'weapons.containers.KORD_12_7_MI24_R'
ENUMS.Storage.weapons.containers.M134_SIDE_R = 'weapons.containers.M134_SIDE_R'
ENUMS.Storage.weapons.containers.AKAN_NO_TRC = 'weapons.containers.{AKAN_NO_TRC}'
ENUMS.Storage.weapons.containers.oh_58_brauning = 'weapons.containers.oh-58-brauning'
ENUMS.Storage.weapons.containers.MXU_648 = 'weapons.containers.MXU-648'
ENUMS.Storage.weapons.containers.M134_R = 'weapons.containers.M134_R'
ENUMS.Storage.weapons.containers.AN_M3 = 'weapons.containers.{AN-M3}'
ENUMS.Storage.weapons.containers.GIAT_M621_APHE = 'weapons.containers.{GIAT_M621_APHE}'
ENUMS.Storage.weapons.containers.AIM_9S = 'weapons.containers.AIM-9S'
ENUMS.Storage.weapons.containers.CH47_AFT_M240H = 'weapons.containers.{CH47_AFT_M240H}'
ENUMS.Storage.weapons.containers.FN_HMP400 = 'weapons.containers.{FN_HMP400}'
ENUMS.Storage.weapons.containers.M134_SIDE_L = 'weapons.containers.M134_SIDE_L'
ENUMS.Storage.weapons.containers.MB339_DEFA553_L = 'weapons.containers.{MB339_DEFA553_L}'
ENUMS.Storage.weapons.containers.MISC_1 = 'weapons.containers.{05544F1A-C39C-466b-BC37-5BD1D52E57BB}'
ENUMS.Storage.weapons.containers.MISC_2 = 'weapons.containers.{E92CBFE5-C153-11d8-9897-000476191836}'
ENUMS.Storage.weapons.containers.hvar_SmokeGenerator = 'weapons.containers.hvar_SmokeGenerator'
ENUMS.Storage.weapons.containers.INV_SMOKE_RED = 'weapons.containers.{INV-SMOKE-RED}'
ENUMS.Storage.weapons.containers.INV_SMOKE_YELLOW = 'weapons.containers.{INV-SMOKE-YELLOW}'
ENUMS.Storage.weapons.containers.INV_SMOKE_BLUE = 'weapons.containers.{INV-SMOKE-BLUE}'
ENUMS.Storage.weapons.containers.INV_SMOKE_GREEN = 'weapons.containers.{INV-SMOKE-GREEN}'
ENUMS.Storage.weapons.containers.INV_SMOKE_WHITE = 'weapons.containers.{INV-SMOKE-WHITE}'
ENUMS.Storage.weapons.containers.INV_SMOKE_ORANGE = 'weapons.containers.{INV-SMOKE-ORANGE}'
ENUMS.Storage.weapons.containers.GAU_12_Equalizer_AP = 'weapons.containers.{GAU_12_Equalizer_AP}'
ENUMS.Storage.weapons.containers.AH_6_Gunners = 'weapons.containers.{AH-6_Gunners}'
ENUMS.Storage.weapons.containers.AH_6_FN_HMP400 = 'weapons.containers.{AH-6_FN_HMP400}'
ENUMS.Storage.weapons.containers.R_73U = 'weapons.containers.R-73U'
ENUMS.Storage.weapons.containers.M60_SIDE_R = 'weapons.containers.M60_SIDE_R'
ENUMS.Storage.weapons.containers.CH47_AFT_M3M = 'weapons.containers.{CH47_AFT_M3M}'
ENUMS.Storage.weapons.containers.GUV_YakB_GSHP = 'weapons.containers.GUV_YakB_GSHP'
ENUMS.Storage.weapons.containers.RKL609_L = 'weapons.containers.{RKL609_L}'
ENUMS.Storage.weapons.containers.CH47_PORT_M134D = 'weapons.containers.{CH47_PORT_M134D}'
ENUMS.Storage.weapons.containers.CH47_PORT_M60D = 'weapons.containers.{CH47_PORT_M60D}'
ENUMS.Storage.weapons.containers.RKL609_R = 'weapons.containers.{RKL609_R}'
ENUMS.Storage.weapons.containers.C_101_DEFA553 = 'weapons.containers.{C-101-DEFA553}'
ENUMS.Storage.weapons.containers.AH6_M134L = 'weapons.containers.{AH6_M134L}'
ENUMS.Storage.weapons.containers.KORD_12_7 = 'weapons.containers.KORD_12_7'
ENUMS.Storage.weapons.containers.C130_M18_Sidearm = 'weapons.containers.{C130-M18-Sidearm}'
ENUMS.Storage.weapons.containers.GIAT_M621_HEAP = 'weapons.containers.{GIAT_M621_HEAP}'
ENUMS.Storage.weapons.containers.BRU_42_LS = 'weapons.containers.BRU-42_LS'
ENUMS.Storage.weapons.containers.CH47_STBD_M60D = 'weapons.containers.{CH47_STBD_M60D}'
ENUMS.Storage.weapons.containers.SUU_23_POD = 'weapons.containers.{SUU_23_POD}'
ENUMS.Storage.weapons.containers.M134_SIDE_R = 'weapons.containers.M134_SIDE_R'
ENUMS.Storage.weapons.containers.AKAN_NO_TRC = 'weapons.containers.{AKAN_NO_TRC}'
ENUMS.Storage.weapons.containers.oh_58_brauning = 'weapons.containers.oh-58-brauning'
ENUMS.Storage.weapons.containers.AH_6_DOORS = 'weapons.containers.{AH-6_DOORS}'
ENUMS.Storage.weapons.containers.CC420_GUN_POD = 'weapons.containers.{CC420_GUN_POD}'
ENUMS.Storage.weapons.containers.CH47_PORT_M240H = 'weapons.containers.{CH47_PORT_M240H}'
ENUMS.Storage.weapons.containers.MB339_DEFA553_R = 'weapons.containers.{MB339_DEFA553_R}'
ENUMS.Storage.weapons.containers.AIM_9S = 'weapons.containers.AIM-9S'
ENUMS.Storage.weapons.containers.hvar_SmokeGenerator = 'weapons.containers.hvar_SmokeGenerator'
ENUMS.Storage.weapons.containers.M134_L = 'weapons.containers.M134_L'
ENUMS.Storage.weapons.containers.AKAN = 'weapons.containers.{AKAN}'
ENUMS.Storage.weapons.containers.C130_Cargo_Bay_M4 = 'weapons.containers.{C130-Cargo-Bay-M4}'
ENUMS.Storage.weapons.containers.M134_SIDE_L = 'weapons.containers.M134_SIDE_L'
ENUMS.Storage.weapons.containers.FN_HMP400_200 = 'weapons.containers.{FN_HMP400_200}'
ENUMS.Storage.weapons.containers.OH58D_M3P_L200 = 'weapons.containers.OH58D_M3P_L200'
ENUMS.Storage.weapons.containers.GIAT_M621_AP = 'weapons.containers.{GIAT_M621_AP}'
ENUMS.Storage.weapons.containers.M134_R = 'weapons.containers.M134_R'
ENUMS.Storage.weapons.containers.OH58D_M3P_L300 = 'weapons.containers.OH58D_M3P_L300'
ENUMS.Storage.weapons.containers.AH6_M134R = 'weapons.containers.{AH6_M134R}'

ENUMS.Storage.weapons.torpedoes.G7A_T1 = 'weapons.torpedoes.G7A_T1'

-- UH-60L Mod
ENUMS.Storage.weapons.gunmounts.UH60LGAU19 = 'weapons.gunmounts.UH-60L GAU-19'
ENUMS.Storage.weapons.gunmounts.UH60L_M134 = 'weapons.gunmounts.UH60L_M134'
ENUMS.Storage.weapons.gunmounts.UH60_M134 = 'weapons.gunmounts.UH60_M134'
ENUMS.Storage.weapons.adapters.uh60l_lwl12 = 'weapons.adapters.uh60l_lwl12'
ENUMS.Storage.weapons.droptanks.uh60l_iafts = 'weapons.droptanks.uh60l_iafts'
ENUMS.Storage.weapons.gunmounts.UH60_GAU19_LEFT = 'weapons.gunmounts.{UH60_GAU19_LEFT}'
ENUMS.Storage.weapons.gunmounts.UH60_GAU19_RIGHT = 'weapons.gunmounts.{UH60_GAU19_RIGHT}'
ENUMS.Storage.weapons.gunmounts.UH60_M134_LEFT = 'weapons.gunmounts.{UH60_M134_LEFT}'
ENUMS.Storage.weapons.gunmounts.UH60_M134_RIGHT = 'weapons.gunmounts.{UH60_M134_RIGHT}'
ENUMS.Storage.weapons.gunmounts.UH60L_M134_GUNNER = 'weapons.gunmounts.{UH60L_M134_GUNNER}'
ENUMS.Storage.weapons.gunmounts.UH60L_M60_GUNNER = 'weapons.gunmounts.{UH60L_M60_GUNNER}'
ENUMS.Storage.weapons.gunmounts.UH60L_M2_GUNNER = 'weapons.gunmounts.{UH60L_M2_GUNNER}'
ENUMS.Storage.weapons.gunmounts.UH60_M230_LEFT = 'weapons.gunmounts.{UH60_M230_LEFT}'
ENUMS.Storage.weapons.gunmounts.UH60_M230_RIGHT = 'weapons.gunmounts.{UH60_M230_RIGHT}'
ENUMS.Storage.weapons.containers.UH60_M134_RIGHT = 'weapons.containers.{UH60_M134_RIGHT}'
ENUMS.Storage.weapons.containers.UH60_M134_LEFT = 'weapons.containers.{UH60_M134_LEFT}'
ENUMS.Storage.weapons.containers.UH60_M230_LEFT = 'weapons.containers.{UH60_M230_LEFT}'
ENUMS.Storage.weapons.containers.UH60L_M134_GUNNER = 'weapons.containers.{UH60L_M134_GUNNER}'
ENUMS.Storage.weapons.containers.UH60_GAU19_LEFT = 'weapons.containers.{UH60_GAU19_LEFT}'
ENUMS.Storage.weapons.containers.UH60L_M60_GUNNER = 'weapons.containers.{UH60L_M60_GUNNER}'
ENUMS.Storage.weapons.containers.UH60_GAU19_RIGHT = 'weapons.containers.{UH60_GAU19_RIGHT}'
ENUMS.Storage.weapons.containers.UH60_M230_RIGHT = 'weapons.containers.{UH60_M230_RIGHT}'
ENUMS.Storage.weapons.containers.UH60L_M2_GUNNER = 'weapons.containers.{UH60L_M2_GUNNER}'

---
-- @type ENUMS.FARPType
-- @field #string FARP
-- @field #string INVISIBLE
-- @field #string HELIPADSINGLE
-- @field #string PADSINGLE
ENUMS.FARPType = {
  FARP = "FARP",
  INVISIBLE = "INVISIBLE",
  HELIPADSINGLE = "HELIPADSINGLE",
  PADSINGLE = "PADSINGLE",
}


---
-- @type ENUMS.FARPObjectTypeNamesAndShape
-- @field #string FARP
-- @field #string INVISIBLE
-- @field #string HELIPADSINGLE
-- @field #string PADSINGLE
ENUMS.FARPObjectTypeNamesAndShape ={
  [ENUMS.FARPType.FARP] = { TypeName="FARP", ShapeName="FARPS"},
  [ENUMS.FARPType.INVISIBLE] = { TypeName="Invisible FARP", ShapeName="invisiblefarp"},
  [ENUMS.FARPType.HELIPADSINGLE] = { TypeName="SINGLE_HELIPAD", ShapeName="FARP"},
  [ENUMS.FARPType.PADSINGLE] = { TypeName="FARP_SINGLE_01", ShapeName="FARP_SINGLE_01"},
}

--- Radio frequency bands (HF, VHF, UHF)
-- @type ENUMS.FrequencyBand
-- @field #number HF High frequency
-- @field #number VHF_LOW Very high frequency
-- @field #number VHF_HI Very high frequency
-- @field #number UHF Ultra high frequency
ENUMS.FrequencyBand = {
  HF = 0,
  VHF_LOW = 1,
  VHF_HI = 2,
  UHF = 3,
}

--- Radio modulation types (AM, FM)
-- @type ENUMS.ModulationType
-- @field #number AM Amplitude modulation
-- @field #number FM Frequency modulation
-- @field #number AMFM Amplitude and frequency modulation
-- @field #number DISCARD Discard modulation
ENUMS.ModulationType = {
  AM = 0,
  FM = 1,
  AMFM = 2,
  DISCARD = -1,
}
