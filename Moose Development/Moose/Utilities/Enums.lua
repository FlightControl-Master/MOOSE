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
    Hercules = "C-130", 
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
    droptanks = {}, -- Droptanks
    adapters = {}, -- Adapter
    torpedoes = {}, -- Torpedoes
    Gazelle = {}, -- Gazelle specifics
    CH47 = {}, -- Chinook specifics
    OH58 = {}, -- Kiowa specifics
    UH1H = {}, -- Huey specifics
    AH64D = {}, -- Huey specifics
  }
}

ENUMS.Storage.weapons.nurs.SNEB_TYPE253_F1B = "weapons.nurs.SNEB_TYPE253_F1B" 
ENUMS.Storage.weapons.missiles.P_24T = "weapons.missiles.P_24T" 
ENUMS.Storage.weapons.bombs.BLU_3B_OLD = "weapons.bombs.BLU-3B_OLD" 
ENUMS.Storage.weapons.missiles.AGM_154 = "weapons.missiles.AGM_154" 
ENUMS.Storage.weapons.nurs.HYDRA_70_M151_M433 = "weapons.nurs.HYDRA_70_M151_M433" 
ENUMS.Storage.weapons.bombs.SAM_Avenger_M1097_Skid_7090lb = "weapons.bombs.SAM Avenger M1097 Skid [7090lb]" 
ENUMS.Storage.weapons.bombs.British_GP_250LB_Bomb_Mk5 = "weapons.bombs.British_GP_250LB_Bomb_Mk5" 
ENUMS.Storage.weapons.containers.OV10_SMOKE = "weapons.containers.{OV10_SMOKE}" 
ENUMS.Storage.weapons.bombs.BLU_4B_OLD = "weapons.bombs.BLU-4B_OLD" 
ENUMS.Storage.weapons.bombs.FAB_500M54 = "weapons.bombs.FAB-500M54" 
ENUMS.Storage.weapons.bombs.GBU_38 = "weapons.bombs.GBU_38" 
ENUMS.Storage.weapons.containers.F_15E_AXQ_14_DATALINK = "weapons.containers.F-15E_AXQ-14_DATALINK" 
ENUMS.Storage.weapons.bombs.BEER_BOMB = "weapons.bombs.BEER_BOMB" 
ENUMS.Storage.weapons.bombs.P_50T = "weapons.bombs.P-50T" 
ENUMS.Storage.weapons.nurs.C_8CM_GN = "weapons.nurs.C_8CM_GN" 
ENUMS.Storage.weapons.bombs.FAB_500SL = "weapons.bombs.FAB-500SL" 
ENUMS.Storage.weapons.bombs.KAB_1500Kr = "weapons.bombs.KAB_1500Kr" 
ENUMS.Storage.weapons.bombs.two50_2 = "weapons.bombs.250-2" 
ENUMS.Storage.weapons.droptanks.Spitfire_tank_1 = "weapons.droptanks.Spitfire_tank_1" 
ENUMS.Storage.weapons.missiles.AGM_65G = "weapons.missiles.AGM_65G" 
ENUMS.Storage.weapons.missiles.AGM_65A = "weapons.missiles.AGM_65A" 
ENUMS.Storage.weapons.containers.Hercules_JATO = "weapons.containers.Hercules_JATO" 
ENUMS.Storage.weapons.nurs.HYDRA_70_M259 = "weapons.nurs.HYDRA_70_M259" 
ENUMS.Storage.weapons.missiles.AGM_84E = "weapons.missiles.AGM_84E" 
ENUMS.Storage.weapons.bombs.AN_M30A1 = "weapons.bombs.AN_M30A1" 
ENUMS.Storage.weapons.nurs.C_25 = "weapons.nurs.C_25" 
ENUMS.Storage.weapons.containers.AV8BNA_ALQ164 = "weapons.containers.AV8BNA_ALQ164" 
ENUMS.Storage.weapons.containers.lav_25 = "weapons.containers.lav-25" 
ENUMS.Storage.weapons.missiles.P_60 = "weapons.missiles.P_60" 
ENUMS.Storage.weapons.bombs.FAB_1500 = "weapons.bombs.FAB_1500" 
ENUMS.Storage.weapons.droptanks.FuelTank_350L = "weapons.droptanks.FuelTank_350L" 
ENUMS.Storage.weapons.bombs.AAA_Vulcan_M163_Skid_21577lb = "weapons.bombs.AAA Vulcan M163 Skid [21577lb]" 
ENUMS.Storage.weapons.missiles.Kormoran = "weapons.missiles.Kormoran" 
ENUMS.Storage.weapons.droptanks.HB_F14_EXT_DROPTANK_EMPTY = "weapons.droptanks.HB_F14_EXT_DROPTANK_EMPTY" 
ENUMS.Storage.weapons.droptanks.FuelTank_150L = "weapons.droptanks.FuelTank_150L" 
ENUMS.Storage.weapons.missiles.Rb_15F_for_A_I = "weapons.missiles.Rb 15F (for A.I.)" 
ENUMS.Storage.weapons.missiles.RB75T = "weapons.missiles.RB75T" 
ENUMS.Storage.weapons.missiles.Vikhr_M = "weapons.missiles.Vikhr_M" 
ENUMS.Storage.weapons.nurs.FFAR_M156_WP = "weapons.nurs.FFAR M156 WP" 
ENUMS.Storage.weapons.nurs.British_HE_60LBSAPNo2_3INCHNo1 = "weapons.nurs.British_HE_60LBSAPNo2_3INCHNo1" 
ENUMS.Storage.weapons.missiles.DWS39_MJ2 = "weapons.missiles.DWS39_MJ2" 
ENUMS.Storage.weapons.bombs.HEBOMBD = "weapons.bombs.HEBOMBD" 
ENUMS.Storage.weapons.missiles.CATM_9M = "weapons.missiles.CATM_9M" 
ENUMS.Storage.weapons.bombs.Mk_81 = "weapons.bombs.Mk_81" 
ENUMS.Storage.weapons.droptanks.Drop_Tank_300_Liter = "weapons.droptanks.Drop_Tank_300_Liter" 
ENUMS.Storage.weapons.containers.HMMWV_M1025 = "weapons.containers.HMMWV_M1025" 
ENUMS.Storage.weapons.bombs.SAM_CHAPARRAL_Air_21624lb = "weapons.bombs.SAM CHAPARRAL Air [21624lb]" 
ENUMS.Storage.weapons.missiles.AGM_154A = "weapons.missiles.AGM_154A" 
ENUMS.Storage.weapons.bombs.Mk_84AIR_TP = "weapons.bombs.Mk_84AIR_TP" 
ENUMS.Storage.weapons.bombs.GBU_31_V_3B = "weapons.bombs.GBU_31_V_3B" 
ENUMS.Storage.weapons.nurs.C_8CM_WH = "weapons.nurs.C_8CM_WH" 
ENUMS.Storage.weapons.missiles.Matra_Super_530D = "weapons.missiles.Matra Super 530D" 
ENUMS.Storage.weapons.nurs.ARF8M3TPSM = "weapons.nurs.ARF8M3TPSM" 
ENUMS.Storage.weapons.missiles.TGM_65H = "weapons.missiles.TGM_65H" 
ENUMS.Storage.weapons.nurs.M8rocket = "weapons.nurs.M8rocket" 
ENUMS.Storage.weapons.bombs.GBU_27 = "weapons.bombs.GBU_27" 
ENUMS.Storage.weapons.missiles.AGR_20A = "weapons.missiles.AGR_20A" 
ENUMS.Storage.weapons.missiles.LS_6_250 = "weapons.missiles.LS-6-250" 
ENUMS.Storage.weapons.droptanks.M2KC_RPL_522_EMPTY = "weapons.droptanks.M2KC_RPL_522_EMPTY" 
ENUMS.Storage.weapons.droptanks.M2KC_02_RPL541 = "weapons.droptanks.M2KC_02_RPL541" 
ENUMS.Storage.weapons.missiles.AGM_45 = "weapons.missiles.AGM_45" 
ENUMS.Storage.weapons.missiles.AGM_84A = "weapons.missiles.AGM_84A" 
ENUMS.Storage.weapons.bombs.APC_BTR_80_Air_23936lb = "weapons.bombs.APC BTR-80 Air [23936lb]" 
ENUMS.Storage.weapons.missiles.P_33E = "weapons.missiles.P_33E" 
ENUMS.Storage.weapons.missiles.Ataka_9M120 = "weapons.missiles.Ataka_9M120" 
ENUMS.Storage.weapons.bombs.MK76 = "weapons.bombs.MK76" 
ENUMS.Storage.weapons.bombs.AB_250_2_SD_2 = "weapons.bombs.AB_250_2_SD_2" 
ENUMS.Storage.weapons.missiles.Rb_05A = "weapons.missiles.Rb 05A" 
ENUMS.Storage.weapons.bombs.ART_GVOZDIKA_34720lb = "weapons.bombs.ART GVOZDIKA [34720lb]" 
ENUMS.Storage.weapons.bombs.Generic_Crate_20000lb = "weapons.bombs.Generic Crate [20000lb]" 
ENUMS.Storage.weapons.bombs.FAB_100SV = "weapons.bombs.FAB_100SV" 
ENUMS.Storage.weapons.bombs.BetAB_500 = "weapons.bombs.BetAB_500" 
ENUMS.Storage.weapons.droptanks.M2KC_02_RPL541_EMPTY = "weapons.droptanks.M2KC_02_RPL541_EMPTY" 
ENUMS.Storage.weapons.droptanks.PTB600_MIG15 = "weapons.droptanks.PTB600_MIG15" 
ENUMS.Storage.weapons.missiles.Rb_24J = "weapons.missiles.Rb 24J" 
ENUMS.Storage.weapons.nurs.C_8CM_BU = "weapons.nurs.C_8CM_BU" 
ENUMS.Storage.weapons.nurs.SNEB_TYPE259E_F1B = "weapons.nurs.SNEB_TYPE259E_F1B" 
ENUMS.Storage.weapons.nurs.WGr21 = "weapons.nurs.WGr21" 
ENUMS.Storage.weapons.bombs.SAMP250HD = "weapons.bombs.SAMP250HD" 
ENUMS.Storage.weapons.containers.alq_184long = "weapons.containers.alq-184long" 
ENUMS.Storage.weapons.nurs.SNEB_TYPE259E_H1 = "weapons.nurs.SNEB_TYPE259E_H1" 
ENUMS.Storage.weapons.bombs.British_SAP_250LB_Bomb_Mk5 = "weapons.bombs.British_SAP_250LB_Bomb_Mk5" 
ENUMS.Storage.weapons.bombs.Transport_UAZ_469_Air_3747lb = "weapons.bombs.Transport UAZ-469 Air [3747lb]" 
ENUMS.Storage.weapons.bombs.Mk_83CT = "weapons.bombs.Mk_83CT" 
ENUMS.Storage.weapons.missiles.AIM_7P = "weapons.missiles.AIM-7P" 
ENUMS.Storage.weapons.missiles.AT_6 = "weapons.missiles.AT_6" 
ENUMS.Storage.weapons.nurs.SNEB_TYPE254_H1_GREEN = "weapons.nurs.SNEB_TYPE254_H1_GREEN" 
ENUMS.Storage.weapons.nurs.SNEB_TYPE250_F1B = "weapons.nurs.SNEB_TYPE250_F1B" 
ENUMS.Storage.weapons.containers.U22A = "weapons.containers.U22A" 
ENUMS.Storage.weapons.bombs.British_GP_250LB_Bomb_Mk1 = "weapons.bombs.British_GP_250LB_Bomb_Mk1" 
ENUMS.Storage.weapons.bombs.CBU_105 = "weapons.bombs.CBU_105" 
ENUMS.Storage.weapons.droptanks.FW_190_Fuel_Tank = "weapons.droptanks.FW-190_Fuel-Tank" 
ENUMS.Storage.weapons.missiles.X_58 = "weapons.missiles.X_58" 
ENUMS.Storage.weapons.missiles.BK90_MJ1_MJ2 = "weapons.missiles.BK90_MJ1_MJ2" 
ENUMS.Storage.weapons.missiles.TGM_65D = "weapons.missiles.TGM_65D" 
ENUMS.Storage.weapons.containers.BRD_4_250 = "weapons.containers.BRD-4-250" 
ENUMS.Storage.weapons.missiles.P_73 = "weapons.missiles.P_73" 
ENUMS.Storage.weapons.bombs.AN_M66 = "weapons.bombs.AN_M66" 
ENUMS.Storage.weapons.bombs.APC_LAV_25_Air_22520lb = "weapons.bombs.APC LAV-25 Air [22520lb]" 
ENUMS.Storage.weapons.missiles.AIM_7MH = "weapons.missiles.AIM-7MH" 
ENUMS.Storage.weapons.containers.MB339_TravelPod = "weapons.containers.MB339_TravelPod" 
ENUMS.Storage.weapons.bombs.GBU_12 = "weapons.bombs.GBU_12" 
ENUMS.Storage.weapons.bombs.SC_250_T3_J = "weapons.bombs.SC_250_T3_J" 
ENUMS.Storage.weapons.missiles.KD_20 = "weapons.missiles.KD-20" 
ENUMS.Storage.weapons.missiles.AGM_86C = "weapons.missiles.AGM_86C" 
ENUMS.Storage.weapons.missiles.X_35 = "weapons.missiles.X_35" 
ENUMS.Storage.weapons.bombs.MK106 = "weapons.bombs.MK106" 
ENUMS.Storage.weapons.bombs.BETAB_500S = "weapons.bombs.BETAB-500S" 
ENUMS.Storage.weapons.nurs.C_5 = "weapons.nurs.C_5" 
ENUMS.Storage.weapons.nurs.S_24B = "weapons.nurs.S-24B" 
ENUMS.Storage.weapons.bombs.British_MC_500LB_Bomb_Mk2 = "weapons.bombs.British_MC_500LB_Bomb_Mk2" 
ENUMS.Storage.weapons.containers.ANAWW_13 = "weapons.containers.ANAWW_13" 
ENUMS.Storage.weapons.droptanks.droptank_108_gal = "weapons.droptanks.droptank_108_gal" 
ENUMS.Storage.weapons.droptanks.DFT_300_GAL_A4E_LR = "weapons.droptanks.DFT_300_GAL_A4E_LR" 
ENUMS.Storage.weapons.bombs.CBU_87 = "weapons.bombs.CBU_87" 
ENUMS.Storage.weapons.missiles.GAR_8 = "weapons.missiles.GAR-8" 
ENUMS.Storage.weapons.bombs.BELOUGA = "weapons.bombs.BELOUGA" 
ENUMS.Storage.weapons.containers.EclairM_33 = "weapons.containers.{EclairM_33}" 
ENUMS.Storage.weapons.bombs.ART_2S9_NONA_Air_19140lb = "weapons.bombs.ART 2S9 NONA Air [19140lb]" 
ENUMS.Storage.weapons.bombs.BR_250 = "weapons.bombs.BR_250" 
ENUMS.Storage.weapons.bombs.IAB_500 = "weapons.bombs.IAB-500" 
ENUMS.Storage.weapons.containers.AN_ASQ_228 = "weapons.containers.AN_ASQ_228" 
ENUMS.Storage.weapons.missiles.P_27P = "weapons.missiles.P_27P" 
ENUMS.Storage.weapons.bombs.SD_250_Stg = "weapons.bombs.SD_250_Stg" 
ENUMS.Storage.weapons.missiles.R_530F_IR = "weapons.missiles.R_530F_IR" 
ENUMS.Storage.weapons.bombs.British_SAP_500LB_Bomb_Mk5 = "weapons.bombs.British_SAP_500LB_Bomb_Mk5" 
ENUMS.Storage.weapons.bombs.FAB_250M54 = "weapons.bombs.FAB-250M54" 
ENUMS.Storage.weapons.containers.M2KC_AAF = "weapons.containers.{M2KC_AAF}" 
ENUMS.Storage.weapons.missiles.CM_802AKG_AI = "weapons.missiles.CM-802AKG_AI" 
ENUMS.Storage.weapons.bombs.CBU_103 = "weapons.bombs.CBU_103" 
ENUMS.Storage.weapons.containers.US_M10_SMOKE_TANK_RED = "weapons.containers.{US_M10_SMOKE_TANK_RED}" 
ENUMS.Storage.weapons.missiles.X_29T = "weapons.missiles.X_29T" 
ENUMS.Storage.weapons.bombs.HEMTT_TFFT_34400lb = "weapons.bombs.HEMTT TFFT [34400lb]" 
ENUMS.Storage.weapons.missiles.C_701IR = "weapons.missiles.C-701IR" 
ENUMS.Storage.weapons.containers.fullCargoSeats = "weapons.containers.fullCargoSeats" 
ENUMS.Storage.weapons.bombs.GBU_15_V_31_B = "weapons.bombs.GBU_15_V_31_B" 
ENUMS.Storage.weapons.bombs.APC_M1043_HMMWV_Armament_Air_7023lb = "weapons.bombs.APC M1043 HMMWV Armament Air [7023lb]" 
ENUMS.Storage.weapons.missiles.PL_5EII = "weapons.missiles.PL-5EII" 
ENUMS.Storage.weapons.bombs.SC_250_T1_L2 = "weapons.bombs.SC_250_T1_L2" 
ENUMS.Storage.weapons.torpedoes.mk46torp_name = "weapons.torpedoes.mk46torp_name" 
ENUMS.Storage.weapons.containers.F_15E_AAQ_33_XR_ATP_SE = "weapons.containers.F-15E_AAQ-33_XR_ATP-SE" 
ENUMS.Storage.weapons.missiles.AIM_7 = "weapons.missiles.AIM_7" 
ENUMS.Storage.weapons.missiles.AGM_122 = "weapons.missiles.AGM_122" 
ENUMS.Storage.weapons.bombs.HEBOMB = "weapons.bombs.HEBOMB" 
ENUMS.Storage.weapons.bombs.CBU_97 = "weapons.bombs.CBU_97" 
ENUMS.Storage.weapons.bombs.MK_81SE = "weapons.bombs.MK-81SE" 
ENUMS.Storage.weapons.nurs.Zuni_127 = "weapons.nurs.Zuni_127" 
ENUMS.Storage.weapons.containers.M2KC_AGF = "weapons.containers.{M2KC_AGF}" 
ENUMS.Storage.weapons.droptanks.Hercules_ExtFuelTank = "weapons.droptanks.Hercules_ExtFuelTank" 
ENUMS.Storage.weapons.containers.SMOKE_WHITE = "weapons.containers.{SMOKE_WHITE}" 
ENUMS.Storage.weapons.droptanks.droptank_150_gal = "weapons.droptanks.droptank_150_gal" 
ENUMS.Storage.weapons.nurs.HYDRA_70_WTU1B = "weapons.nurs.HYDRA_70_WTU1B" 
ENUMS.Storage.weapons.missiles.GB_6_SFW = "weapons.missiles.GB-6-SFW" 
ENUMS.Storage.weapons.missiles.KD_63 = "weapons.missiles.KD-63" 
ENUMS.Storage.weapons.bombs.GBU_28 = "weapons.bombs.GBU_28" 
ENUMS.Storage.weapons.nurs.C_8CM_YE = "weapons.nurs.C_8CM_YE" 
ENUMS.Storage.weapons.droptanks.HB_F14_EXT_DROPTANK = "weapons.droptanks.HB_F14_EXT_DROPTANK" 
ENUMS.Storage.weapons.missiles.Super_530F = "weapons.missiles.Super_530F" 
ENUMS.Storage.weapons.missiles.Ataka_9M220 = "weapons.missiles.Ataka_9M220" 
ENUMS.Storage.weapons.bombs.BDU_33 = "weapons.bombs.BDU_33" 
ENUMS.Storage.weapons.bombs.British_GP_250LB_Bomb_Mk4 = "weapons.bombs.British_GP_250LB_Bomb_Mk4" 
ENUMS.Storage.weapons.missiles.TOW = "weapons.missiles.TOW" 
ENUMS.Storage.weapons.bombs.ATGM_M1045_HMMWV_TOW_Air_7183lb = "weapons.bombs.ATGM M1045 HMMWV TOW Air [7183lb]" 
ENUMS.Storage.weapons.missiles.X_25MR = "weapons.missiles.X_25MR" 
ENUMS.Storage.weapons.droptanks.fueltank230 = "weapons.droptanks.fueltank230" 
ENUMS.Storage.weapons.droptanks.PTB_490C_MIG21 = "weapons.droptanks.PTB-490C-MIG21" 
ENUMS.Storage.weapons.bombs.M1025_HMMWV_Air_6160lb = "weapons.bombs.M1025 HMMWV Air [6160lb]" 
ENUMS.Storage.weapons.nurs.SNEB_TYPE254_F1B_GREEN = "weapons.nurs.SNEB_TYPE254_F1B_GREEN" 
ENUMS.Storage.weapons.missiles.R_550 = "weapons.missiles.R_550" 
ENUMS.Storage.weapons.bombs.KAB_1500LG = "weapons.bombs.KAB_1500LG" 
ENUMS.Storage.weapons.missiles.AGM_84D = "weapons.missiles.AGM_84D" 
ENUMS.Storage.weapons.missiles.YJ_83K = "weapons.missiles.YJ-83K" 
ENUMS.Storage.weapons.missiles.AIM_54C_Mk47 = "weapons.missiles.AIM_54C_Mk47" 
ENUMS.Storage.weapons.missiles.BRM_1_90MM = "weapons.missiles.BRM-1_90MM" 
ENUMS.Storage.weapons.missiles.Ataka_9M120F = "weapons.missiles.Ataka_9M120F" 
ENUMS.Storage.weapons.droptanks.Eleven00L_Tank = "weapons.droptanks.1100L Tank" 
ENUMS.Storage.weapons.bombs.BAP_100 = "weapons.bombs.BAP_100" 
ENUMS.Storage.weapons.adapters.lau_88 = "weapons.adapters.lau-88" 
ENUMS.Storage.weapons.missiles.P_40T = "weapons.missiles.P_40T" 
ENUMS.Storage.weapons.missiles.GB_6 = "weapons.missiles.GB-6" 
ENUMS.Storage.weapons.bombs.FAB_250M54TU = "weapons.bombs.FAB-250M54TU" 
ENUMS.Storage.weapons.missiles.DWS39_MJ1 = "weapons.missiles.DWS39_MJ1" 
ENUMS.Storage.weapons.missiles.CM_802AKG = "weapons.missiles.CM-802AKG" 
ENUMS.Storage.weapons.bombs.FAB_250 = "weapons.bombs.FAB_250" 
ENUMS.Storage.weapons.missiles.C_802AK = "weapons.missiles.C_802AK" 
ENUMS.Storage.weapons.bombs.SD_500_A = "weapons.bombs.SD_500_A" 
ENUMS.Storage.weapons.bombs.GBU_32_V_2B = "weapons.bombs.GBU_32_V_2B" 
ENUMS.Storage.weapons.containers.marder = "weapons.containers.marder" 
ENUMS.Storage.weapons.missiles.ADM_141B = "weapons.missiles.ADM_141B" 
ENUMS.Storage.weapons.bombs.ROCKEYE = "weapons.bombs.ROCKEYE" 
ENUMS.Storage.weapons.missiles.BK90_MJ1 = "weapons.missiles.BK90_MJ1" 
ENUMS.Storage.weapons.containers.BTR_80 = "weapons.containers.BTR-80" 
ENUMS.Storage.weapons.bombs.SAM_ROLAND_ADS_34720lb = "weapons.bombs.SAM ROLAND ADS [34720lb]" 
ENUMS.Storage.weapons.containers.wmd7 = "weapons.containers.wmd7" 
ENUMS.Storage.weapons.missiles.C_701T = "weapons.missiles.C-701T" 
ENUMS.Storage.weapons.missiles.AIM_7E_2 = "weapons.missiles.AIM-7E-2" 
ENUMS.Storage.weapons.nurs.HVAR = "weapons.nurs.HVAR" 
ENUMS.Storage.weapons.containers.HMMWV_M1043 = "weapons.containers.HMMWV_M1043" 
ENUMS.Storage.weapons.droptanks.PTB_800_MIG21 = "weapons.droptanks.PTB-800-MIG21" 
ENUMS.Storage.weapons.missiles.AGM_114 = "weapons.missiles.AGM_114" 
ENUMS.Storage.weapons.bombs.APC_M1126_Stryker_ICV_29542lb = "weapons.bombs.APC M1126 Stryker ICV [29542lb]" 
ENUMS.Storage.weapons.bombs.APC_M113_Air_21624lb = "weapons.bombs.APC M113 Air [21624lb]" 
ENUMS.Storage.weapons.bombs.M_117 = "weapons.bombs.M_117" 
ENUMS.Storage.weapons.missiles.AGM_65D = "weapons.missiles.AGM_65D" 
ENUMS.Storage.weapons.droptanks.MB339_TT320_L = "weapons.droptanks.MB339_TT320_L" 
ENUMS.Storage.weapons.missiles.AGM_86 = "weapons.missiles.AGM_86" 
ENUMS.Storage.weapons.bombs.BDU_45LGB = "weapons.bombs.BDU_45LGB" 
ENUMS.Storage.weapons.missiles.AGM_65H = "weapons.missiles.AGM_65H" 
ENUMS.Storage.weapons.nurs.RS_82 = "weapons.nurs.RS-82" 
ENUMS.Storage.weapons.nurs.SNEB_TYPE252_F1B = "weapons.nurs.SNEB_TYPE252_F1B" 
ENUMS.Storage.weapons.bombs.BL_755 = "weapons.bombs.BL_755" 
ENUMS.Storage.weapons.containers.F_15E_AAQ_28_LITENING = "weapons.containers.F-15E_AAQ-28_LITENING" 
ENUMS.Storage.weapons.nurs.SNEB_TYPE256_F1B = "weapons.nurs.SNEB_TYPE256_F1B" 
ENUMS.Storage.weapons.missiles.AGM_84H = "weapons.missiles.AGM_84H" 
ENUMS.Storage.weapons.missiles.AIM_54 = "weapons.missiles.AIM_54" 
ENUMS.Storage.weapons.missiles.X_31A = "weapons.missiles.X_31A" 
ENUMS.Storage.weapons.bombs.KAB_500Kr = "weapons.bombs.KAB_500Kr" 
ENUMS.Storage.weapons.containers.SPS_141_100 = "weapons.containers.SPS-141-100" 
ENUMS.Storage.weapons.missiles.BK90_MJ2 = "weapons.missiles.BK90_MJ2" 
ENUMS.Storage.weapons.missiles.Super_530D = "weapons.missiles.Super_530D" 
ENUMS.Storage.weapons.bombs.CBU_52B = "weapons.bombs.CBU_52B" 
ENUMS.Storage.weapons.droptanks.PTB_450 = "weapons.droptanks.PTB-450" 
ENUMS.Storage.weapons.bombs.IFV_MCV_80_34720lb = "weapons.bombs.IFV MCV-80 [34720lb]" 
ENUMS.Storage.weapons.containers.Two_c9 = "weapons.containers.2-c9" 
ENUMS.Storage.weapons.missiles.AIM_9JULI = "weapons.missiles.AIM-9JULI" 
ENUMS.Storage.weapons.droptanks.MB339_TT500_R = "weapons.droptanks.MB339_TT500_R" 
ENUMS.Storage.weapons.nurs.C_8CM = "weapons.nurs.C_8CM" 
ENUMS.Storage.weapons.containers.BARAX = "weapons.containers.BARAX" 
ENUMS.Storage.weapons.missiles.P_40R = "weapons.missiles.P_40R" 
ENUMS.Storage.weapons.missiles.YJ_12 = "weapons.missiles.YJ-12" 
ENUMS.Storage.weapons.missiles.CM_802AKG = "weapons.missiles.CM_802AKG" 
ENUMS.Storage.weapons.nurs.SNEB_TYPE254_H1_YELLOW = "weapons.nurs.SNEB_TYPE254_H1_YELLOW" 
ENUMS.Storage.weapons.bombs.Durandal = "weapons.bombs.Durandal" 
ENUMS.Storage.weapons.droptanks.i16_eft = "weapons.droptanks.i16_eft" 
ENUMS.Storage.weapons.droptanks.AV8BNA_AERO1D_EMPTY = "weapons.droptanks.AV8BNA_AERO1D_EMPTY" 
ENUMS.Storage.weapons.containers.Hercules_Battle_Station_TGP = "weapons.containers.Hercules_Battle_Station_TGP" 
ENUMS.Storage.weapons.nurs.C_8CM_VT = "weapons.nurs.C_8CM_VT" 
ENUMS.Storage.weapons.missiles.PL_12 = "weapons.missiles.PL-12" 
ENUMS.Storage.weapons.missiles.R_3R = "weapons.missiles.R-3R" 
ENUMS.Storage.weapons.bombs.GBU_54_V_1B = "weapons.bombs.GBU_54_V_1B" 
ENUMS.Storage.weapons.droptanks.MB339_TT320_R = "weapons.droptanks.MB339_TT320_R" 
ENUMS.Storage.weapons.bombs.RN_24 = "weapons.bombs.RN-24" 
ENUMS.Storage.weapons.containers.Twoc6m = "weapons.containers.2c6m" 
ENUMS.Storage.weapons.bombs.ARV_BRDM_2_Air_12320lb = "weapons.bombs.ARV BRDM-2 Air [12320lb]" 
ENUMS.Storage.weapons.bombs.ARV_BRDM_2_Skid_12210lb = "weapons.bombs.ARV BRDM-2 Skid [12210lb]" 
ENUMS.Storage.weapons.nurs.SNEB_TYPE251_F1B = "weapons.nurs.SNEB_TYPE251_F1B" 
ENUMS.Storage.weapons.missiles.X_41 = "weapons.missiles.X_41" 
ENUMS.Storage.weapons.containers.MIG21_SMOKE_WHITE = "weapons.containers.{MIG21_SMOKE_WHITE}" 
ENUMS.Storage.weapons.bombs.MK_82AIR = "weapons.bombs.MK_82AIR" 
ENUMS.Storage.weapons.missiles.R_530F_EM = "weapons.missiles.R_530F_EM" 
ENUMS.Storage.weapons.bombs.SAMP400LD = "weapons.bombs.SAMP400LD" 
ENUMS.Storage.weapons.bombs.FAB_50 = "weapons.bombs.FAB_50" 
ENUMS.Storage.weapons.bombs.AB_250_2_SD_10A = "weapons.bombs.AB_250_2_SD_10A" 
ENUMS.Storage.weapons.missiles.ADM_141A = "weapons.missiles.ADM_141A" 
ENUMS.Storage.weapons.containers.KBpod = "weapons.containers.KBpod" 
ENUMS.Storage.weapons.bombs.British_GP_500LB_Bomb_Mk4 = "weapons.bombs.British_GP_500LB_Bomb_Mk4" 
ENUMS.Storage.weapons.missiles.AGM_65E = "weapons.missiles.AGM_65E" 
ENUMS.Storage.weapons.containers.sa342_dipole_antenna = "weapons.containers.sa342_dipole_antenna" 
ENUMS.Storage.weapons.bombs.OFAB_100_Jupiter = "weapons.bombs.OFAB-100 Jupiter" 
ENUMS.Storage.weapons.nurs.SNEB_TYPE257_F1B = "weapons.nurs.SNEB_TYPE257_F1B" 
ENUMS.Storage.weapons.missiles.Rb_04E_for_A_I = "weapons.missiles.Rb 04E (for A.I.)" 
ENUMS.Storage.weapons.bombs.AN_M66A2 = "weapons.bombs.AN-M66A2" 
ENUMS.Storage.weapons.missiles.P_27T = "weapons.missiles.P_27T" 
ENUMS.Storage.weapons.droptanks.LNS_VIG_XTANK = "weapons.droptanks.LNS_VIG_XTANK" 
ENUMS.Storage.weapons.missiles.R_55 = "weapons.missiles.R-55" 
ENUMS.Storage.weapons.torpedoes.YU_6 = "weapons.torpedoes.YU-6" 
ENUMS.Storage.weapons.bombs.British_MC_250LB_Bomb_Mk2 = "weapons.bombs.British_MC_250LB_Bomb_Mk2" 
ENUMS.Storage.weapons.droptanks.PTB_120_F86F35 = "weapons.droptanks.PTB_120_F86F35" 
ENUMS.Storage.weapons.missiles.PL_8B = "weapons.missiles.PL-8B" 
ENUMS.Storage.weapons.droptanks.F_15E_Drop_Tank_Empty = "weapons.droptanks.F-15E_Drop_Tank_Empty" 
ENUMS.Storage.weapons.nurs.British_HE_60LBFNo1_3INCHNo1 = "weapons.nurs.British_HE_60LBFNo1_3INCHNo1" 
ENUMS.Storage.weapons.missiles.P_77 = "weapons.missiles.P_77" 
ENUMS.Storage.weapons.torpedoes.LTF_5B = "weapons.torpedoes.LTF_5B" 
ENUMS.Storage.weapons.missiles.R_3S = "weapons.missiles.R-3S" 
ENUMS.Storage.weapons.nurs.SNEB_TYPE253_H1 = "weapons.nurs.SNEB_TYPE253_H1" 
ENUMS.Storage.weapons.missiles.PL_8A = "weapons.missiles.PL-8A" 
ENUMS.Storage.weapons.bombs.APC_BTR_82A_Skid_24888lb = "weapons.bombs.APC BTR-82A Skid [24888lb]" 
ENUMS.Storage.weapons.containers.Sborka = "weapons.containers.Sborka" 
ENUMS.Storage.weapons.missiles.AGM_65L = "weapons.missiles.AGM_65L" 
ENUMS.Storage.weapons.missiles.X_28 = "weapons.missiles.X_28" 
ENUMS.Storage.weapons.missiles.TGM_65G = "weapons.missiles.TGM_65G" 
ENUMS.Storage.weapons.nurs.SNEB_TYPE257_H1 = "weapons.nurs.SNEB_TYPE257_H1" 
ENUMS.Storage.weapons.missiles.RB75B = "weapons.missiles.RB75B" 
ENUMS.Storage.weapons.missiles.X_25ML = "weapons.missiles.X_25ML" 
ENUMS.Storage.weapons.droptanks.FPU_8A = "weapons.droptanks.FPU_8A" 
ENUMS.Storage.weapons.bombs.BLG66 = "weapons.bombs.BLG66" 
ENUMS.Storage.weapons.nurs.C_8CM_RD = "weapons.nurs.C_8CM_RD" 
ENUMS.Storage.weapons.containers.EclairM_06 = "weapons.containers.{EclairM_06}" 
ENUMS.Storage.weapons.bombs.RBK_500AO = "weapons.bombs.RBK_500AO" 
ENUMS.Storage.weapons.missiles.AIM_9P = "weapons.missiles.AIM-9P" 
ENUMS.Storage.weapons.bombs.British_GP_500LB_Bomb_Mk4_Short = "weapons.bombs.British_GP_500LB_Bomb_Mk4_Short" 
ENUMS.Storage.weapons.containers.MB339_Vinten = "weapons.containers.MB339_Vinten" 
ENUMS.Storage.weapons.missiles.Rb_15F = "weapons.missiles.Rb 15F" 
ENUMS.Storage.weapons.nurs.ARAKM70BHE = "weapons.nurs.ARAKM70BHE" 
ENUMS.Storage.weapons.bombs.AAA_Vulcan_M163_Air_21666lb = "weapons.bombs.AAA Vulcan M163 Air [21666lb]" 
ENUMS.Storage.weapons.missiles.X_29L = "weapons.missiles.X_29L" 
ENUMS.Storage.weapons.containers.F14_LANTIRN_TP = "weapons.containers.{F14-LANTIRN-TP}" 
ENUMS.Storage.weapons.bombs.FAB_250_M62 = "weapons.bombs.FAB-250-M62" 
ENUMS.Storage.weapons.missiles.AIM_120C = "weapons.missiles.AIM_120C" 
ENUMS.Storage.weapons.bombs.EWR_SBORKA_Air_21624lb = "weapons.bombs.EWR SBORKA Air [21624lb]" 
ENUMS.Storage.weapons.bombs.SAMP250LD = "weapons.bombs.SAMP250LD" 
ENUMS.Storage.weapons.droptanks.Spitfire_slipper_tank = "weapons.droptanks.Spitfire_slipper_tank" 
ENUMS.Storage.weapons.missiles.LS_6_500 = "weapons.missiles.LS-6-500" 
ENUMS.Storage.weapons.bombs.GBU_31_V_4B = "weapons.bombs.GBU_31_V_4B" 
ENUMS.Storage.weapons.droptanks.PTB400_MIG15 = "weapons.droptanks.PTB400_MIG15" 
ENUMS.Storage.weapons.containers.m_113 = "weapons.containers.m-113" 
ENUMS.Storage.weapons.bombs.SPG_M1128_Stryker_MGS_33036lb = "weapons.bombs.SPG M1128 Stryker MGS [33036lb]" 
ENUMS.Storage.weapons.missiles.AIM_9L = "weapons.missiles.AIM-9L" 
ENUMS.Storage.weapons.missiles.AIM_9X = "weapons.missiles.AIM_9X" 
ENUMS.Storage.weapons.nurs.C_8 = "weapons.nurs.C_8" 
ENUMS.Storage.weapons.bombs.SAM_CHAPARRAL_Skid_21516lb = "weapons.bombs.SAM CHAPARRAL Skid [21516lb]" 
ENUMS.Storage.weapons.missiles.P_27TE = "weapons.missiles.P_27TE" 
ENUMS.Storage.weapons.bombs.ODAB_500PM = "weapons.bombs.ODAB-500PM" 
ENUMS.Storage.weapons.bombs.MK77mod1_WPN = "weapons.bombs.MK77mod1-WPN" 
ENUMS.Storage.weapons.droptanks.PTB400_MIG19 = "weapons.droptanks.PTB400_MIG19" 
ENUMS.Storage.weapons.torpedoes.Mark_46 = "weapons.torpedoes.Mark_46" 
ENUMS.Storage.weapons.containers.rightSeat = "weapons.containers.rightSeat" 
ENUMS.Storage.weapons.containers.US_M10_SMOKE_TANK_ORANGE = "weapons.containers.{US_M10_SMOKE_TANK_ORANGE}" 
ENUMS.Storage.weapons.bombs.SAB_100MN = "weapons.bombs.SAB_100MN" 
ENUMS.Storage.weapons.nurs.FFAR_Mk5_HEAT = "weapons.nurs.FFAR Mk5 HEAT" 
ENUMS.Storage.weapons.bombs.IFV_TPZ_FUCH_33440lb = "weapons.bombs.IFV TPZ FUCH [33440lb]" 
ENUMS.Storage.weapons.bombs.IFV_M2A2_Bradley_34720lb = "weapons.bombs.IFV M2A2 Bradley [34720lb]" 
ENUMS.Storage.weapons.bombs.MK77mod0_WPN = "weapons.bombs.MK77mod0-WPN" 
ENUMS.Storage.weapons.containers.ASO_2 = "weapons.containers.ASO-2" 
ENUMS.Storage.weapons.bombs.Mk_84AIR_GP = "weapons.bombs.Mk_84AIR_GP" 
ENUMS.Storage.weapons.nurs.S_24A = "weapons.nurs.S-24A" 
ENUMS.Storage.weapons.bombs.RBK_250_275_AO_1SCH = "weapons.bombs.RBK_250_275_AO_1SCH" 
ENUMS.Storage.weapons.bombs.Transport_Tigr_Skid_15730lb = "weapons.bombs.Transport Tigr Skid [15730lb]" 
ENUMS.Storage.weapons.missiles.AIM_7F = "weapons.missiles.AIM-7F" 
ENUMS.Storage.weapons.bombs.CBU_99 = "weapons.bombs.CBU_99" 
ENUMS.Storage.weapons.bombs.LUU_2B = "weapons.bombs.LUU_2B" 
ENUMS.Storage.weapons.bombs.FAB_500TA = "weapons.bombs.FAB-500TA" 
ENUMS.Storage.weapons.missiles.AGR_20_M282 = "weapons.missiles.AGR_20_M282" 
ENUMS.Storage.weapons.droptanks.MB339_FT330 = "weapons.droptanks.MB339_FT330" 
ENUMS.Storage.weapons.bombs.SAMP125LD = "weapons.bombs.SAMP125LD" 
ENUMS.Storage.weapons.missiles.X_25MP = "weapons.missiles.X_25MP" 
ENUMS.Storage.weapons.nurs.SNEB_TYPE252_H1 = "weapons.nurs.SNEB_TYPE252_H1" 
ENUMS.Storage.weapons.missiles.AGM_65F = "weapons.missiles.AGM_65F" 
ENUMS.Storage.weapons.missiles.AIM_9P5 = "weapons.missiles.AIM-9P5" 
ENUMS.Storage.weapons.bombs.Transport_Tigr_Air_15900lb = "weapons.bombs.Transport Tigr Air [15900lb]" 
ENUMS.Storage.weapons.nurs.SNEB_TYPE254_H1_RED = "weapons.nurs.SNEB_TYPE254_H1_RED" 
ENUMS.Storage.weapons.nurs.FFAR_Mk1_HE = "weapons.nurs.FFAR Mk1 HE" 
ENUMS.Storage.weapons.nurs.SPRD_99 = "weapons.nurs.SPRD-99" 
ENUMS.Storage.weapons.bombs.BIN_200 = "weapons.bombs.BIN_200" 
ENUMS.Storage.weapons.bombs.BLU_4B_GROUP = "weapons.bombs.BLU_4B_GROUP" 
ENUMS.Storage.weapons.bombs.GBU_24 = "weapons.bombs.GBU_24" 
ENUMS.Storage.weapons.missiles.Rb_04E = "weapons.missiles.Rb 04E" 
ENUMS.Storage.weapons.missiles.Rb_74 = "weapons.missiles.Rb 74" 
ENUMS.Storage.weapons.containers.leftSeat = "weapons.containers.leftSeat" 
ENUMS.Storage.weapons.bombs.LS_6_100 = "weapons.bombs.LS-6-100" 
ENUMS.Storage.weapons.bombs.Transport_URAL_375_14815lb = "weapons.bombs.Transport URAL-375 [14815lb]" 
ENUMS.Storage.weapons.containers.US_M10_SMOKE_TANK_GREEN = "weapons.containers.{US_M10_SMOKE_TANK_GREEN}" 
ENUMS.Storage.weapons.missiles.X_22 = "weapons.missiles.X_22" 
ENUMS.Storage.weapons.containers.FAS = "weapons.containers.FAS" 
ENUMS.Storage.weapons.nurs.S_25_O = "weapons.nurs.S-25-O" 
ENUMS.Storage.weapons.droptanks.para = "weapons.droptanks.para" 
ENUMS.Storage.weapons.droptanks.F_15E_Drop_Tank = "weapons.droptanks.F-15E_Drop_Tank" 
ENUMS.Storage.weapons.droptanks.M2KC_08_RPL541_EMPTY = "weapons.droptanks.M2KC_08_RPL541_EMPTY" 
ENUMS.Storage.weapons.missiles.X_31P = "weapons.missiles.X_31P" 
ENUMS.Storage.weapons.bombs.RBK_500U = "weapons.bombs.RBK_500U" 
ENUMS.Storage.weapons.missiles.AIM_54A_Mk47 = "weapons.missiles.AIM_54A_Mk47" 
ENUMS.Storage.weapons.droptanks.oiltank = "weapons.droptanks.oiltank" 
ENUMS.Storage.weapons.missiles.AGM_154B = "weapons.missiles.AGM_154B" 
ENUMS.Storage.weapons.containers.MB339_SMOKE_POD = "weapons.containers.MB339_SMOKE-POD" 
ENUMS.Storage.weapons.containers.ECM_POD_L_175V = "weapons.containers.{ECM_POD_L_175V}" 
ENUMS.Storage.weapons.droptanks.PTB_580G_F1 = "weapons.droptanks.PTB_580G_F1" 
ENUMS.Storage.weapons.containers.EclairM_15 = "weapons.containers.{EclairM_15}" 
ENUMS.Storage.weapons.containers.F_15E_AAQ_13_LANTIRN = "weapons.containers.F-15E_AAQ-13_LANTIRN" 
ENUMS.Storage.weapons.droptanks.Eight00L_Tank_Empty = "weapons.droptanks.800L Tank Empty" 
ENUMS.Storage.weapons.containers.One6c_hts_pod = "weapons.containers.16c_hts_pod" 
ENUMS.Storage.weapons.bombs.AN_M81 = "weapons.bombs.AN-M81" 
ENUMS.Storage.weapons.droptanks.Mosquito_Drop_Tank_100gal = "weapons.droptanks.Mosquito_Drop_Tank_100gal" 
ENUMS.Storage.weapons.droptanks.Mosquito_Drop_Tank_50gal = "weapons.droptanks.Mosquito_Drop_Tank_50gal" 
ENUMS.Storage.weapons.droptanks.DFT_150_GAL_A4E = "weapons.droptanks.DFT_150_GAL_A4E" 
ENUMS.Storage.weapons.missiles.AIM_9 = "weapons.missiles.AIM_9" 
ENUMS.Storage.weapons.bombs.IFV_BTR_D_Air_18040lb = "weapons.bombs.IFV BTR-D Air [18040lb]" 
ENUMS.Storage.weapons.containers.EclairM_42 = "weapons.containers.{EclairM_42}" 
ENUMS.Storage.weapons.bombs.KAB_1500T = "weapons.bombs.KAB_1500T" 
ENUMS.Storage.weapons.droptanks.PTB_490_MIG21 = "weapons.droptanks.PTB-490-MIG21" 
ENUMS.Storage.weapons.droptanks.PTB_200_F86F35 = "weapons.droptanks.PTB_200_F86F35" 
ENUMS.Storage.weapons.droptanks.PTB760_MIG19 = "weapons.droptanks.PTB760_MIG19" 
ENUMS.Storage.weapons.bombs.GBU_43_B_MOAB = "weapons.bombs.GBU-43/B(MOAB)" 
ENUMS.Storage.weapons.torpedoes.G7A_T1 = "weapons.torpedoes.G7A_T1" 
ENUMS.Storage.weapons.bombs.IFV_BMD_1_Air_18040lb = "weapons.bombs.IFV BMD-1 Air [18040lb]" 
ENUMS.Storage.weapons.bombs.SAM_LINEBACKER_34720lb = "weapons.bombs.SAM LINEBACKER [34720lb]" 
ENUMS.Storage.weapons.containers.ais_pod_t50_r = "weapons.containers.ais-pod-t50_r" 
ENUMS.Storage.weapons.containers.CE2_SMOKE_WHITE = "weapons.containers.{CE2_SMOKE_WHITE}" 
ENUMS.Storage.weapons.droptanks.fuel_tank_230 = "weapons.droptanks.fuel_tank_230" 
ENUMS.Storage.weapons.droptanks.M2KC_RPL_522 = "weapons.droptanks.M2KC_RPL_522" 
ENUMS.Storage.weapons.missiles.AGM_130 = "weapons.missiles.AGM_130" 
ENUMS.Storage.weapons.droptanks.Eight00L_Tank = "weapons.droptanks.800L Tank" 
ENUMS.Storage.weapons.bombs.IFV_BTR_D_Skid_17930lb = "weapons.bombs.IFV BTR-D Skid [17930lb]" 
ENUMS.Storage.weapons.containers.bmp_1 = "weapons.containers.bmp-1" 
ENUMS.Storage.weapons.bombs.GBU_31 = "weapons.bombs.GBU_31" 
ENUMS.Storage.weapons.containers.aaq_28LEFT_litening = "weapons.containers.aaq-28LEFT litening" 
ENUMS.Storage.weapons.missiles.Kh_66_Grom = "weapons.missiles.Kh-66_Grom" 
ENUMS.Storage.weapons.containers.MIG21_SMOKE_RED = "weapons.containers.{MIG21_SMOKE_RED}" 
ENUMS.Storage.weapons.containers.U22 = "weapons.containers.U22" 
ENUMS.Storage.weapons.bombs.IFV_BMD_1_Skid_17930lb = "weapons.bombs.IFV BMD-1 Skid [17930lb]" 
ENUMS.Storage.weapons.droptanks.Bidon = "weapons.droptanks.Bidon" 
ENUMS.Storage.weapons.bombs.GBU_31_V_2B = "weapons.bombs.GBU_31_V_2B" 
ENUMS.Storage.weapons.bombs.Mk_82Y = "weapons.bombs.Mk_82Y" 
ENUMS.Storage.weapons.containers.pl5eii = "weapons.containers.pl5eii" 
ENUMS.Storage.weapons.bombs.RBK_500U_OAB_2_5RT = "weapons.bombs.RBK_500U_OAB_2_5RT" 
ENUMS.Storage.weapons.bombs.British_GP_500LB_Bomb_Mk5 = "weapons.bombs.British_GP_500LB_Bomb_Mk5" 
ENUMS.Storage.weapons.containers.Eclair = "weapons.containers.{Eclair}" 
ENUMS.Storage.weapons.nurs.S5MO_HEFRAG_FFAR = "weapons.nurs.S5MO_HEFRAG_FFAR" 
ENUMS.Storage.weapons.bombs.BETAB_500M = "weapons.bombs.BETAB-500M" 
ENUMS.Storage.weapons.bombs.Transport_M818_16000lb = "weapons.bombs.Transport M818 [16000lb]" 
ENUMS.Storage.weapons.bombs.British_MC_250LB_Bomb_Mk1 = "weapons.bombs.British_MC_250LB_Bomb_Mk1" 
ENUMS.Storage.weapons.nurs.SNEB_TYPE251_H1 = "weapons.nurs.SNEB_TYPE251_H1" 
ENUMS.Storage.weapons.bombs.TYPE_200A = "weapons.bombs.TYPE-200A" 
ENUMS.Storage.weapons.nurs.HYDRA_70_M151 = "weapons.nurs.HYDRA_70_M151" 
ENUMS.Storage.weapons.bombs.IFV_BMP_3_32912lb = "weapons.bombs.IFV BMP-3 [32912lb]" 
ENUMS.Storage.weapons.bombs.APC_MTLB_Air_26400lb = "weapons.bombs.APC MTLB Air [26400lb]" 
ENUMS.Storage.weapons.nurs.HYDRA_70_M229 = "weapons.nurs.HYDRA_70_M229" 
ENUMS.Storage.weapons.bombs.BDU_45 = "weapons.bombs.BDU_45" 
ENUMS.Storage.weapons.bombs.OFAB_100_120TU = "weapons.bombs.OFAB-100-120TU" 
ENUMS.Storage.weapons.missiles.AIM_9J = "weapons.missiles.AIM-9J" 
ENUMS.Storage.weapons.nurs.ARF8M3API = "weapons.nurs.ARF8M3API" 
ENUMS.Storage.weapons.bombs.BetAB_500ShP = "weapons.bombs.BetAB_500ShP" 
ENUMS.Storage.weapons.nurs.C_8OFP2 = "weapons.nurs.C_8OFP2" 
ENUMS.Storage.weapons.bombs.GBU_10 = "weapons.bombs.GBU_10" 
ENUMS.Storage.weapons.bombs.APC_MTLB_Skid_26290lb = "weapons.bombs.APC MTLB Skid [26290lb]" 
ENUMS.Storage.weapons.nurs.SNEB_TYPE254_F1B_RED = "weapons.nurs.SNEB_TYPE254_F1B_RED" 
ENUMS.Storage.weapons.missiles.X_65 = "weapons.missiles.X_65" 
ENUMS.Storage.weapons.missiles.R_550_M1 = "weapons.missiles.R_550_M1" 
ENUMS.Storage.weapons.missiles.AGM_65K = "weapons.missiles.AGM_65K" 
ENUMS.Storage.weapons.nurs.SNEB_TYPE254_F1B_YELLOW = "weapons.nurs.SNEB_TYPE254_F1B_YELLOW" 
ENUMS.Storage.weapons.missiles.AGM_88 = "weapons.missiles.AGM_88" 
ENUMS.Storage.weapons.nurs.C_8OM = "weapons.nurs.C_8OM" 
ENUMS.Storage.weapons.bombs.SAM_ROLAND_LN_34720b = "weapons.bombs.SAM ROLAND LN [34720b]" 
ENUMS.Storage.weapons.missiles.AIM_120 = "weapons.missiles.AIM_120" 
ENUMS.Storage.weapons.missiles.HOT3_MBDA = "weapons.missiles.HOT3_MBDA" 
ENUMS.Storage.weapons.missiles.R_13M = "weapons.missiles.R-13M" 
ENUMS.Storage.weapons.missiles.AIM_54C_Mk60 = "weapons.missiles.AIM_54C_Mk60" 
ENUMS.Storage.weapons.bombs.AAA_GEPARD_34720lb = "weapons.bombs.AAA GEPARD [34720lb]" 
ENUMS.Storage.weapons.missiles.R_13M1 = "weapons.missiles.R-13M1" 
ENUMS.Storage.weapons.bombs.APC_Cobra_Air_10912lb = "weapons.bombs.APC Cobra Air [10912lb]" 
ENUMS.Storage.weapons.bombs.RBK_250 = "weapons.bombs.RBK_250" 
ENUMS.Storage.weapons.bombs.SC_500_J = "weapons.bombs.SC_500_J" 
ENUMS.Storage.weapons.missiles.AGM_114K = "weapons.missiles.AGM_114K" 
ENUMS.Storage.weapons.missiles.ALARM = "weapons.missiles.ALARM" 
ENUMS.Storage.weapons.bombs.Mk_83 = "weapons.bombs.Mk_83" 
ENUMS.Storage.weapons.missiles.AGM_65B = "weapons.missiles.AGM_65B" 
ENUMS.Storage.weapons.bombs.MK_82SNAKEYE = "weapons.bombs.MK_82SNAKEYE" 
ENUMS.Storage.weapons.nurs.HYDRA_70_MK1 = "weapons.nurs.HYDRA_70_MK1" 
ENUMS.Storage.weapons.bombs.BLG66_BELOUGA = "weapons.bombs.BLG66_BELOUGA" 
ENUMS.Storage.weapons.containers.EclairM_51 = "weapons.containers.{EclairM_51}" 
ENUMS.Storage.weapons.missiles.AIM_54A_Mk60 = "weapons.missiles.AIM_54A_Mk60" 
ENUMS.Storage.weapons.droptanks.DFT_300_GAL_A4E = "weapons.droptanks.DFT_300_GAL_A4E" 
ENUMS.Storage.weapons.bombs.ATGM_M1134_Stryker_30337lb = "weapons.bombs.ATGM M1134 Stryker [30337lb]" 
ENUMS.Storage.weapons.bombs.BAT_120 = "weapons.bombs.BAT-120" 
ENUMS.Storage.weapons.missiles.DWS39_MJ1_MJ2 = "weapons.missiles.DWS39_MJ1_MJ2" 
ENUMS.Storage.weapons.containers.SPRD = "weapons.containers.SPRD" 
ENUMS.Storage.weapons.bombs.BR_500 = "weapons.bombs.BR_500" 
ENUMS.Storage.weapons.bombs.British_GP_500LB_Bomb_Mk1 = "weapons.bombs.British_GP_500LB_Bomb_Mk1" 
ENUMS.Storage.weapons.bombs.BDU_50HD = "weapons.bombs.BDU_50HD" 
ENUMS.Storage.weapons.missiles.RS2US = "weapons.missiles.RS2US" 
ENUMS.Storage.weapons.bombs.IFV_BMP_2_25168lb = "weapons.bombs.IFV BMP-2 [25168lb]" 
ENUMS.Storage.weapons.bombs.SAMP400HD = "weapons.bombs.SAMP400HD" 
ENUMS.Storage.weapons.containers.Hercules_Battle_Station = "weapons.containers.Hercules_Battle_Station" 
ENUMS.Storage.weapons.bombs.AN_M64 = "weapons.bombs.AN_M64" 
ENUMS.Storage.weapons.containers.rearCargoSeats = "weapons.containers.rearCargoSeats" 
ENUMS.Storage.weapons.bombs.Mk_82 = "weapons.bombs.Mk_82" 
ENUMS.Storage.weapons.missiles.AKD_10 = "weapons.missiles.AKD-10" 
ENUMS.Storage.weapons.bombs.BDU_50LGB = "weapons.bombs.BDU_50LGB" 
ENUMS.Storage.weapons.missiles.SD_10 = "weapons.missiles.SD-10" 
ENUMS.Storage.weapons.containers.IRDeflector = "weapons.containers.IRDeflector" 
ENUMS.Storage.weapons.bombs.FAB_500 = "weapons.bombs.FAB_500" 
ENUMS.Storage.weapons.bombs.KAB_500 = "weapons.bombs.KAB_500" 
ENUMS.Storage.weapons.nurs.S_5M = "weapons.nurs.S-5M" 
ENUMS.Storage.weapons.missiles.MICA_R = "weapons.missiles.MICA_R" 
ENUMS.Storage.weapons.missiles.X_59M = "weapons.missiles.X_59M" 
ENUMS.Storage.weapons.nurs.UG_90MM = "weapons.nurs.UG_90MM" 
ENUMS.Storage.weapons.bombs.LYSBOMB = "weapons.bombs.LYSBOMB" 
ENUMS.Storage.weapons.nurs.R4M = "weapons.nurs.R4M" 
ENUMS.Storage.weapons.containers.dlpod_akg = "weapons.containers.dlpod_akg" 
ENUMS.Storage.weapons.missiles.LD_10 = "weapons.missiles.LD-10" 
ENUMS.Storage.weapons.bombs.SC_50 = "weapons.bombs.SC_50" 
ENUMS.Storage.weapons.nurs.HYDRA_70_MK5 = "weapons.nurs.HYDRA_70_MK5" 
ENUMS.Storage.weapons.bombs.FAB_100M = "weapons.bombs.FAB_100M" 
ENUMS.Storage.weapons.missiles.Rb_24 = "weapons.missiles.Rb 24" 
ENUMS.Storage.weapons.bombs.BDU_45B = "weapons.bombs.BDU_45B" 
ENUMS.Storage.weapons.missiles.GB_6_HE = "weapons.missiles.GB-6-HE" 
ENUMS.Storage.weapons.missiles.KD_63B = "weapons.missiles.KD-63B" 
ENUMS.Storage.weapons.missiles.P_27PE = "weapons.missiles.P_27PE" 
ENUMS.Storage.weapons.droptanks.PTB300_MIG15 = "weapons.droptanks.PTB300_MIG15" 
ENUMS.Storage.weapons.bombs.Two50_3 = "weapons.bombs.250-3" 
ENUMS.Storage.weapons.bombs.SC_500_L2 = "weapons.bombs.SC_500_L2" 
ENUMS.Storage.weapons.containers.HMMWV_M1045 = "weapons.containers.HMMWV_M1045" 
ENUMS.Storage.weapons.bombs.FAB_500M54TU = "weapons.bombs.FAB-500M54TU" 
ENUMS.Storage.weapons.containers.US_M10_SMOKE_TANK_YELLOW = "weapons.containers.{US_M10_SMOKE_TANK_YELLOW}" 
ENUMS.Storage.weapons.containers.EclairM_60 = "weapons.containers.{EclairM_60}" 
ENUMS.Storage.weapons.bombs.SAB_250_200 = "weapons.bombs.SAB_250_200" 
ENUMS.Storage.weapons.bombs.FAB_100 = "weapons.bombs.FAB_100" 
ENUMS.Storage.weapons.bombs.KAB_500S = "weapons.bombs.KAB_500S" 
ENUMS.Storage.weapons.missiles.AGM_45A = "weapons.missiles.AGM_45A" 
ENUMS.Storage.weapons.missiles.Kh25MP_PRGS1VP = "weapons.missiles.Kh25MP_PRGS1VP" 
ENUMS.Storage.weapons.nurs.S5M1_HEFRAG_FFAR = "weapons.nurs.S5M1_HEFRAG_FFAR" 
ENUMS.Storage.weapons.containers.kg600 = "weapons.containers.kg600" 
ENUMS.Storage.weapons.bombs.AN_M65 = "weapons.bombs.AN_M65" 
ENUMS.Storage.weapons.bombs.AN_M57 = "weapons.bombs.AN_M57" 
ENUMS.Storage.weapons.bombs.BLU_3B_GROUP = "weapons.bombs.BLU_3B_GROUP" 
ENUMS.Storage.weapons.bombs.BAP_100 = "weapons.bombs.BAP-100" 
ENUMS.Storage.weapons.containers.HEMTT = "weapons.containers.HEMTT" 
ENUMS.Storage.weapons.bombs.British_MC_500LB_Bomb_Mk1_Short = "weapons.bombs.British_MC_500LB_Bomb_Mk1_Short" 
ENUMS.Storage.weapons.nurs.ARAKM70BAP = "weapons.nurs.ARAKM70BAP" 
ENUMS.Storage.weapons.missiles.AGM_119 = "weapons.missiles.AGM_119" 
ENUMS.Storage.weapons.missiles.MMagicII = "weapons.missiles.MMagicII" 
ENUMS.Storage.weapons.bombs.AB_500_1_SD_10A = "weapons.bombs.AB_500_1_SD_10A" 
ENUMS.Storage.weapons.nurs.HYDRA_70_M282 = "weapons.nurs.HYDRA_70_M282" 
ENUMS.Storage.weapons.droptanks.DFT_400_GAL_A4E = "weapons.droptanks.DFT_400_GAL_A4E" 
ENUMS.Storage.weapons.nurs.HYDRA_70_M257 = "weapons.nurs.HYDRA_70_M257" 
ENUMS.Storage.weapons.droptanks.AV8BNA_AERO1D = "weapons.droptanks.AV8BNA_AERO1D" 
ENUMS.Storage.weapons.containers.US_M10_SMOKE_TANK_BLUE = "weapons.containers.{US_M10_SMOKE_TANK_BLUE}" 
ENUMS.Storage.weapons.nurs.ARF8M3HEI = "weapons.nurs.ARF8M3HEI" 
ENUMS.Storage.weapons.bombs.RN_28 = "weapons.bombs.RN-28" 
ENUMS.Storage.weapons.bombs.Squad_30_x_Soldier_7950lb = "weapons.bombs.Squad 30 x Soldier [7950lb]" 
ENUMS.Storage.weapons.containers.uaz_469 = "weapons.containers.uaz-469" 
ENUMS.Storage.weapons.containers.Otokar_Cobra = "weapons.containers.Otokar_Cobra" 
ENUMS.Storage.weapons.bombs.APC_BTR_82A_Air_24998lb = "weapons.bombs.APC BTR-82A Air [24998lb]" 
ENUMS.Storage.weapons.nurs.HYDRA_70_M274 = "weapons.nurs.HYDRA_70_M274" 
ENUMS.Storage.weapons.missiles.P_24R = "weapons.missiles.P_24R" 
ENUMS.Storage.weapons.nurs.HYDRA_70_MK61 = "weapons.nurs.HYDRA_70_MK61" 
ENUMS.Storage.weapons.missiles.Igla_1E = "weapons.missiles.Igla_1E" 
ENUMS.Storage.weapons.missiles.C_802AK = "weapons.missiles.C-802AK" 
ENUMS.Storage.weapons.nurs.C_24 = "weapons.nurs.C_24" 
ENUMS.Storage.weapons.droptanks.M2KC_08_RPL541 = "weapons.droptanks.M2KC_08_RPL541" 
ENUMS.Storage.weapons.nurs.C_13 = "weapons.nurs.C_13" 
ENUMS.Storage.weapons.droptanks.droptank_110_gal = "weapons.droptanks.droptank_110_gal" 
ENUMS.Storage.weapons.bombs.Mk_84 = "weapons.bombs.Mk_84" 
ENUMS.Storage.weapons.missiles.Sea_Eagle = "weapons.missiles.Sea_Eagle" 
ENUMS.Storage.weapons.droptanks.PTB_1200_F1 = "weapons.droptanks.PTB_1200_F1" 
ENUMS.Storage.weapons.nurs.SNEB_TYPE256_H1 = "weapons.nurs.SNEB_TYPE256_H1" 
ENUMS.Storage.weapons.containers.MATRA_PHIMAT = "weapons.containers.MATRA-PHIMAT" 
ENUMS.Storage.weapons.containers.smoke_pod = "weapons.containers.smoke_pod" 
ENUMS.Storage.weapons.containers.F_15E_AAQ_14_LANTIRN = "weapons.containers.F-15E_AAQ-14_LANTIRN" 
ENUMS.Storage.weapons.containers.EclairM_24 = "weapons.containers.{EclairM_24}" 
ENUMS.Storage.weapons.bombs.GBU_16 = "weapons.bombs.GBU_16" 
ENUMS.Storage.weapons.nurs.HYDRA_70_M156 = "weapons.nurs.HYDRA_70_M156" 
ENUMS.Storage.weapons.missiles.R_60 = "weapons.missiles.R-60" 
ENUMS.Storage.weapons.containers.zsu_23_4 = "weapons.containers.zsu-23-4" 
ENUMS.Storage.weapons.missiles.RB75 = "weapons.missiles.RB75" 
ENUMS.Storage.weapons.missiles.Mistral = "weapons.missiles.Mistral" 
ENUMS.Storage.weapons.droptanks.MB339_TT500_L = "weapons.droptanks.MB339_TT500_L" 
ENUMS.Storage.weapons.bombs.SAM_SA_13_STRELA_21624lb = "weapons.bombs.SAM SA-13 STRELA [21624lb]" 
ENUMS.Storage.weapons.bombs.SAM_Avenger_M1097_Air_7200lb = "weapons.bombs.SAM Avenger M1097 Air [7200lb]" 
ENUMS.Storage.weapons.droptanks.Eleven00L_Tank_Empty = "weapons.droptanks.1100L Tank Empty" 
ENUMS.Storage.weapons.bombs.AN_M88 = "weapons.bombs.AN-M88" 
ENUMS.Storage.weapons.missiles.S_25L = "weapons.missiles.S_25L" 
ENUMS.Storage.weapons.nurs.British_AP_25LBNo1_3INCHNo1 = "weapons.nurs.British_AP_25LBNo1_3INCHNo1" 
ENUMS.Storage.weapons.bombs.BDU_50LD = "weapons.bombs.BDU_50LD"
ENUMS.Storage.weapons.bombs.AGM_62 = "weapons.bombs.AGM_62"
ENUMS.Storage.weapons.containers.US_M10_SMOKE_TANK_WHITE = "weapons.containers.{US_M10_SMOKE_TANK_WHITE}" 
ENUMS.Storage.weapons.missiles.MICA_T = "weapons.missiles.MICA_T" 
ENUMS.Storage.weapons.containers.HVAR_rocket = "weapons.containers.HVAR_rocket"
-- Gazelle
ENUMS.Storage.weapons.Gazelle.HMP400_100RDS = {4,15,46,1771}
ENUMS.Storage.weapons.Gazelle.HMP400_200RDS = {4,15,46,1770}
ENUMS.Storage.weapons.Gazelle.HMP400_400RDS = {4,15,46,1769}
ENUMS.Storage.weapons.Gazelle.GIAT_M261_AP = {4,15,46,1768}
ENUMS.Storage.weapons.Gazelle.GIAT_M261_SAPHEI = {4,15,46,1767}
ENUMS.Storage.weapons.Gazelle.GIAT_M261_HE = {4,15,46,1766}
ENUMS.Storage.weapons.Gazelle.GIAT_M261_HEAP = {4,15,46,1765}
ENUMS.Storage.weapons.Gazelle.GIAT_M261_APHE = {4,15,46,1764}
ENUMS.Storage.weapons.Gazelle.GAZELLE_IR_DEFLECTOR = {4,15,47,680}
ENUMS.Storage.weapons.Gazelle.GAZELLE_FAS_SANDFILTER = {4,15,47,679}
-- Chinook
ENUMS.Storage.weapons.CH47.CH47_PORT_M60D = {4,15,46,2476}
ENUMS.Storage.weapons.CH47.CH47_STBD_M60D = {4,15,46,2477}
ENUMS.Storage.weapons.CH47.CH47_AFT_M60D = {4,15,46,2478}
ENUMS.Storage.weapons.CH47.CH47_PORT_M134D = {4,15,46,2482}
ENUMS.Storage.weapons.CH47.CH47_STBD_M134D = {4,15,46,2483}
ENUMS.Storage.weapons.CH47.CH47_AFT_M3M = {4,15,46,2484}
ENUMS.Storage.weapons.CH47.CH47_PORT_M240H = {4,15,46,2479}
ENUMS.Storage.weapons.CH47.CH47_STBD_M240H = {4,15,46,2480}
ENUMS.Storage.weapons.CH47.CH47_AFT_M240H = {4,15,46,2481}
-- Huey
ENUMS.Storage.weapons.UH1H.M134_MiniGun_Right = {4,15,46,161}
ENUMS.Storage.weapons.UH1H.M134_MiniGun_Left = {4,15,46,160}
ENUMS.Storage.weapons.UH1H.M134_MiniGun_Right_Door  =  {4,15,46,175}
ENUMS.Storage.weapons.UH1H.M60_MG_Right_Door  =  {4,15,46,177}
ENUMS.Storage.weapons.UH1H.M134_MiniGun_Left_Door  =  {4,15,46,174}
ENUMS.Storage.weapons.UH1H.M60_MG_Left_Door  =  {4,15,46,176}
-- Kiowa
ENUMS.Storage.weapons.OH58.FIM92  =  {4,4,7,449}
ENUMS.Storage.weapons.OH58.MG_M3P100  =  {4,15,46,2611}
ENUMS.Storage.weapons.OH58.MG_M3P200  =  {4,15,46,2610}
ENUMS.Storage.weapons.OH58.MG_M3P300  =  {4,15,46,2609}
ENUMS.Storage.weapons.OH58.MG_M3P400  =  {4,15,46,2608}
ENUMS.Storage.weapons.OH58.MG_M3P500  =  {4,15,46,2607}
ENUMS.Storage.weapons.OH58.Smk_Grenade_Blue  =  {4,5,9,488}
ENUMS.Storage.weapons.OH58.Smk_Grenade_Green  =  {4,5,9,489}
ENUMS.Storage.weapons.OH58.Smk_Grenade_Red  =  {4,5,9,487}
ENUMS.Storage.weapons.OH58.Smk_Grenade_Violet  =  {4,5,9,490}
ENUMS.Storage.weapons.OH58.Smk_Grenade_White  =  {4,5,9,492}
ENUMS.Storage.weapons.OH58.Smk_Grenade_Yellow  =  {4,5,9,491}
-- Apache
ENUMS.Storage.weapons.AH64D.AN_APG78 = {4,15,44,2138}
ENUMS.Storage.weapons.AH64D.Internal_Aux_FuelTank = {1,3,43,1700}

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
