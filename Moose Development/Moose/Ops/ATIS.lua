--- **Ops** - Automatic Terminal Information Service (ATIS).
--
-- ===
--
-- **Main Features:**
--
--    * Wind direction and speed
--    * Visibility
--    * Cloud coverage, base and ceiling
--    * Temperature
--    * Dew point (approximate as there is no relative humidity in DCS yet)    
--    * Pressure QNH/QFE
--    * Weather phenomena: rain, thunderstorm, fog, dust
--    * Active runway based on wind direction
--    * Tower frequencies
--    * More than 180 voice overs
--    * Airbase names pronounced in locale accent (russian, US, french, arabic)
--    * Option to present information in imperial or metric units
--    * Runway length and airfield elevation (optional)
--    * Frequencies/channels of nav aids (ILS, VOR, NDB, TACAN, PRMG, RSBN) (optional)
--
-- ===
--
-- ## Youtube Videos:
--
--    * [ATIS v0.1 Caucasus - Batumi (WIP)](https://youtu.be/MdH9FmbNabo)
--    * [ATIS v0.2 Nevada - Nellis AFB (WIP)](https://youtu.be/8CT_9AoPrTk)
--    * [ATIS v0.3 Persion Gulf - Abu Dhabi/Dubai International](https://youtu.be/NjkKvPz6ovM)
--    * [ATIS Airport Names Sound Check](https://youtu.be/qIE_OUQNAc0)
--
-- ===
--
-- ## Missions: Example missions can be found [here](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/develop/OPS%20-%20ATIS)
--
-- ===
--
-- ## Sound files: Check out the pinned messages in the Moose discord #ops-atis channel.
--
-- ===
--
-- Automatic terminal information service, or ATIS, is a continuous broadcast of recorded aeronautical information in busier terminal areas, *i.e.* airports and their immediate surroundings.
-- ATIS broadcasts contain essential information, such as current weather information, active runways, and any other information required by the pilots.
--
-- ===
--
-- ### Author: **funkyfranky**
-- @module Ops.Atis
-- @image OPS_ATIS.png


--- ATIS class.
-- @type ATIS
-- @field #string ClassName Name of the class.
-- @field #boolean Debug Debug mode. Messages to all about status.
-- @field #string lid Class id string for output to DCS log file.
-- @field #string theatre DCS map name.
-- @field #string airbasename The name of the airbase.
-- @field Wrapper.Airbase#AIRBASE airbase The airbase object.
-- @field #number frequency Radio frequency in MHz.
-- @field #number modulation Radio modulation 0=AM or 1=FM.
-- @field #number power Radio power in Watts. Default 100 W.
-- @field Core.RadioQueue#RADIOQUEUE radioqueue Radio queue for broadcasing messages.
-- @field #string soundpath Path to sound files.
-- @field #string relayunitname Name of the radio relay unit.
-- @field #table towerfrequency Table with tower frequencies.
-- @field #string activerunway The active runway specified by the user.
-- @field #number subduration Duration how long subtitles are displayed in seconds.
-- @field #boolean metric If true, use metric units. If false, use imperial (default).
-- @field #boolean PmmHg If true, give pressure in millimeters of Mercury. Default is inHg for imperial and hecto Pascal (=mili Bars) for metric units.
-- @field #boolean qnhonly If true, suppresses reporting QFE. Default is to report both QNH and QFE.
-- @field #boolean TDegF If true, give temperature in degrees Fahrenheit. Default is in degrees Celsius independent of chosen unit system.
-- @field #number zuludiff Time difference local vs. zulu in hours.
-- @field #boolean zulutimeonly If true, suppresses report of local time, sunrise, and sunset.
-- @field #number magvar Magnetic declination/variation at the airport in degrees.
-- @field #table ils Table of ILS frequencies (can be runway specific).
-- @field #table ndbinner Table of inner NDB frequencies (can be runway specific).
-- @field #table ndbouter Table of outer NDB frequencies (can be runway specific).
-- @field #number tacan TACAN channel.
-- @field #number vor VOR frequency.
-- @field #number rsbn RSBN channel.
-- @field #table prmg PRMG channels (can be runway specific).
-- @field #boolean rwylength If true, give info on runway length.
-- @field #boolean elevation If true, give info on airfield elevation.
-- @field #table runwaymag Table of magnetic runway headings.
-- @field #number runwaym2t Optional correction for magnetic to true runway heading conversion (and vice versa) in degrees.
-- @field #boolean windtrue Report true (from) heading of wind. Default is magnetic.
-- @field #boolean altimeterQNH Report altimeter QNH.
-- @field #boolean usemarker Use mark on the F10 map.
-- @field #number markerid Numerical ID of the F10 map mark point.
-- @field #number relHumidity Relative humidity (used to approximately calculate the dew point).
-- @extends Core.Fsm#FSM

--- *It is a very sad thing that nowadays there is so little useless information.* - Oscar Wilde
--
-- ===
--
-- ![Banner Image](..\Presentations\ATIS\ATIS_Main.png)
--
-- # The ATIS Concept
--
-- Automatic terminal information service, or ATIS, is a continuous broadcast of recorded aeronautical information in busier terminal areas, *i.e.* airports and their immediate surroundings.
-- ATIS broadcasts contain essential information, such as current weather information, active runways, and any other information required by the pilots.
--
-- # DCS Limitations
--
-- Unfortunately, the DCS API only allow to get the temperature, pressure as well as wind direction and speed. Therefore, some other information such as cloud coverage, base and ceiling are not available
-- when dynamic weather is used.
--
-- # Scripting
--
-- The lua script to create an ATIS at an airport is pretty easy:
--
--     -- ATIS at Batumi Airport on 143.00 MHz AM.
--     atisBatumi=ATIS:New("Batumi", 143.00)
--     atisBatumi:Start()
--
-- The @{#ATIS.New}(*airbasename*, *frequency*) creates a new ATIS object. The parameter *airbasename* is the name of the airbase or airport. Note that this has to be spelled exactly as in the DCS mission editor.
-- The parameter *frequency* is the frequency the ATIS broadcasts in MHz.
--
-- Broadcasting is started via the @{#ATIS.Start}() function. The start can be delayed by useing @{#ATIS.__Start}(*delay*), where *delay* is the delay in seconds.
--
-- ## Subtitles
--
-- Currently, DCS allows for displaying subtitles of radio transmissions only from airborne units, *i.e.* airplanes and helicopters. Therefore, if you want to have subtitles, it is necessary to place an
-- additonal aircraft on the ATIS airport and set it to uncontrolled. This unit can then function as a radio relay to transmit messages with subtitles. These subtitles will only be displayed, if the
-- player has tuned in the correct ATIS frequency.
--
-- Radio transmissions via an airborne unit can be set via the @{#ATIS.SetRadioRelayUnitName}(*unitname*) function, where the parameter *unitname* is the name of the unit passed as string, *e.g.*
--
--     atisBatumi:SetRadioRelayUnitName("Radio Relay Batumi")
--
-- With a unit set in the mission editor with name "Radio Relay Batumi".
--
-- **Note** that you should use a different relay unit for each ATIS!
--
-- By default, subtitles are displayed for 10 seconds. This can be changed using @{#ATIS.SetSubtitleDuration}(*duration*) with *duration* being the duration in seconds.
-- Setting a *duration* of 0 will completely disable all subtitles.
--
-- ## Active Runway
--
-- By default, the currently active runway is determined automatically by analysing the wind direction. Therefore, you should obviously set the wind speed to be greater zero in your mission.
--
-- Note however, there are a few special cases, where automatic detection does not yield the correct or desired result.
-- For example, there are airports with more than one runway facing in the same direction (usually denoted left and right). In this case, there is obviously no *unique* result depending on the wind vector.
--
-- If the automatic runway detection fails, the active runway can be specified manually in the script via the @{#ATIS.SetActiveRunway}(*runway*) function.
-- The parameter *runway* is a string which can be used to specify the runway heading and, if applicable, whether the left or right runway is in use.
--
-- For example, setting runway 21L would be
--
--     atisNellis:SetActiveRunway("21L")
--
-- The script will examine the string and search for the characters "L" (left) and "R" (right).
--
-- If only left or right should be set and the direction determined by the wind vector, the runway heading can be left out, *e.g.*
--
--     atisAbuDhabi:SetActiveRunway("L")
--
-- The first two digits of the runway are determined by converting the *true* runway heading into its magnetic heading. The magnetic declination (or variation) is assumed to be constant on the given map.
-- An explicit correction factor can be set via @{#ATIS.SetRunwayCorrectionMagnetic2True}.
--
-- ## Tower Frequencies
--
-- The tower frequency (or frequencies) can also be included in the ATIS information. However, there is no way to get these automatically. Therefore, it is necessary to manually specify them in the script via the
-- @{#ATIS.SetTowerFrequencies}(*frequencies*) function. The parameter *frequencies* can be a plain number if only one frequency is necessary or it can be a table of frequencies.
--
-- ## Nav Aids
--
-- Frequencies or channels of navigation aids can be specified by the user and are then provided as additional information. Unfortunately, it is **not possible** to aquire this information via the DCS API
-- we have access to.
--
-- As they say, all road lead to Rome but (for me) the easiest way to obtain the available nav aids data of an airport, is to start a mission and click on an airport symbol.
--
-- For example, the *AIRDROME DATA* for **Batumi** reads:
--
--    * **TACAN** *16X* - set via @{#ATIS.SetTACAN}
--    * **VOR** *N/A* - set via @{#ATIS.SetVOR}
--    * **RSBN** *N/A* - set via @{#ATIS.SetRSBN}
--    * **ATC** *260.000*, *131.000*, *40.400*, *4.250* - set via @{#ATIS.SetTowerFrequencies}
--    * **Runways** *31* and *13* - automatic but can be set manually via @{#ATIS.SetRunwayHeadingsMagnetic}
--    * **ILS** *110.30* for runway *13* - set via @{#ATIS.AddILS}
--    * **PRMG** *N/A* - set via @{#ATIS.AddPRMG}
--    * **OUTER NDB** *N/A* - set via @{#ATIS.AddNDBouter}
--    * **INNER NDB** *N/A* - set via @{#ATIS.AddNDBinner}
--
-- ![Banner Image](..\Presentations\ATIS\NavAid_Batumi.png)
--
-- And the *AIRDROME DATA* for **Kobuleti** reads:
--
--    * **TACAN** *67X* - set via @{#ATIS.SetTACAN}
--    * **VOR** *N/A* - set via @{#ATIS.SetVOR}
--    * **RSBN** *N/A* - set via @{#ATIS.SetRSBN}
--    * **ATC** *262.000*, *133.000*, *40.800*, *4.350* - set via @{#ATIS.SetTowerFrequencies}
--    * **Runways** *25* and *07* - automatic but can be set manually via @{#ATIS.SetRunwayHeadingsMagnetic}
--    * **ILS** *111.50* for runway *07* - set via @{#ATIS.AddILS}
--    * **PRMG** *N/A* - set via @{#ATIS.AddPRMG}
--    * **OUTER NDB** *870.00* - set via @{#ATIS.AddNDBouter}
--    * **INNER NDB** *490.00* - set via @{#ATIS.AddNDBinner}
--
-- ![Banner Image](..\Presentations\ATIS\NavAid_Kobuleti.png)
--
-- ### TACAN
--
-- The TACtical Air Navigation system [(TACAN)](https://en.wikipedia.org/wiki/Tactical_air_navigation_system) channel can be set via the @{#ATIS.SetTACAN}(*channel*) function, where *channel* is the TACAN channel. Band is always assumed to be X-ray.
--
-- ### VOR
--
-- The Very high frequency Omni-directional Range [(VOR)](https://en.wikipedia.org/wiki/VHF_omnidirectional_range) frequency can be set via the @{#ATIS.SetVOR}(*frequency*) function, where *frequency* is the VOR frequency.
--
-- ### ILS
--
-- The Instrument Landing System [(ILS)](https://en.wikipedia.org/wiki/Instrument_landing_system) frequency can be set via the @{#ATIS.AddILS}(*frequency*, *runway*) function, where *frequency* is the ILS frequency and *runway* the two letter string of the corresponding runway, *e.g.* "31".
-- If the parameter *runway* is omitted (nil) then the frequency is supposed to be valid for all runways of the airport.
--
-- ### NDB
--
-- Inner and outer Non-Directional (radio) Beacons [NDBs](https://en.wikipedia.org/wiki/Non-directional_beacon) can be set via the @{#ATIS.AddNDBinner}(*frequency*, *runway*) and @{#ATIS.AddNDBouter}(*frequency*, *runway*) functions, respectively.
--
-- In both cases, the parameter *frequency* is the NDB frequency and *runway* the two letter string of the corresponding runway, *e.g.* "31".
-- If the parameter *runway* is omitted (nil) then the frequency is supposed to be valid for all runways of the airport.
--
-- ## RSBN
--
-- The RSBN channel can be set via the @{#ATIS.SetRSBN}(*channel*) function.
--
-- ## PRMG
--
-- The PRMG channel can be set via the @{#ATIS.AddPRMG}(*channel*, *runway*) function for each *runway*.
--
-- ## Unit System
--
-- By default, information is given in imperial units, *i.e.* wind speed in knots, pressure in inches of mercury, visibility in Nautical miles, etc.
--
-- If you prefer metric units, you can enable this via the @{#ATIS.SetMetricUnits}() function,
--
--     atisBatumi:SetMetricUnits()
--
-- With this, wind speed is given in meters per second, pressure in hecto Pascal (mbar), visibility in kilometers etc.
--
-- # Sound Files
--
-- More than 180 individual sound files have been created using a text-to-speech program. All ATIS information is given with en-US accent.
--
-- Check out the pinned messages in the Moose discord #ops-atis channel.
--
-- To include the files, open the mission (.miz) file with, *e.g.*, 7-zip. Then just drag-n-drop the file into the miz.
--
-- ![Banner Image](..\Presentations\ATIS\ATIS_SoundFolder.png)
--
-- **Note** that the default folder name is *ATIS Soundfiles/*. If you want to change it, you can use the @{#ATIS.SetSoundfilesPath}(*path*), where *path* is the path of the directory. This must end with a slash "/"!
--
-- # Marks on the F10 Map
--
-- You can place marks on the F10 map via the @{#ATIS.SetMapMarks}() function. These will contain info about the ATIS frequency, the currently active runway and some basic info about the weather (wind, pressure and temperature).
--
-- # Examples
--
-- ## Caucasus: Batumi
--
--     -- ATIS Batumi Airport on 143.00 MHz AM.
--     atisBatumi=ATIS:New(AIRBASE.Caucasus.Batumi, 143.00)
--     atisBatumi:SetRadioRelayUnitName("Radio Relay Batumi")
--     atisBatumi:Start()
--
-- ## Nevada: Nellis AFB
--
--     -- ATIS Nellis AFB on 270.10 MHz AM.
--     atisNellis=ATIS:New(AIRBASE.Nevada.Nellis_AFB, 270.1)
--     atisNellis:SetRadioRelayUnitName("Radio Relay Nellis")
--     atisNellis:SetActiveRunway("21L")
--     atisNellis:SetTowerFrequencies({327.000, 132.550})
--     atisNellis:SetTACAN(12)
--     atisNellis:AddILS(109.1, "21")
--     atisNellis:Start()
--
-- ## Persian Gulf: Abu Dhabi International Airport
--
--     -- ATIS Abu Dhabi International on 125.1 MHz AM.
--     atisAbuDhabi=ATIS:New(AIRBASE.PersianGulf.Abu_Dhabi_International_Airport, 125.1)
--     atisAbuDhabi:SetRadioRelayUnitName("Radio Relay Abu Dhabi International Airport")
--     atisAbuDhabi:SetMetricUnits()
--     atisAbuDhabi:SetActiveRunway("L")
--     atisAbuDhabi:SetTowerFrequencies({250.5, 119.2})
--     atisAbuDhabi:SetVOR(114.25)
--     atisAbuDhabi:Start()
--
--
-- @field #ATIS
ATIS = {
  ClassName      = "ATIS",
  Debug          = false,
  lid            =   nil,
  theatre        =   nil,
  airbasename    =   nil,
  airbase        =   nil,
  frequency      =   nil,
  modulation     =   nil,
  power          =   nil,
  radioqueue     =   nil,
  soundpath      =   nil,
  relayunitname  =   nil,
  towerfrequency =   nil,
  activerunway   =   nil,
  subduration    =   nil,
  metric         =   nil,
  PmmHg          =   nil,
  qnhonly        =   false,
  TDegF          =   nil,
  zuludiff       =   nil,
  zulutimeonly   =   false,
  magvar         =   nil,
  ils            =    {},
  ndbinner       =    {},
  ndbouter       =    {},
  vor            =   nil,
  tacan          =   nil,
  rsbn           =   nil,
  prmg           =    {},
  rwylength      =   nil,
  elevation      =   nil,
  runwaymag      =    {},
  runwaym2t      =   nil,
  windtrue       =   nil,
  altimeterQNH   =   nil,
  usemarker      =   nil,
  markerid       =   nil,
  relHumidity    =   nil,
}

--- NATO alphabet.
-- @type ATIS.Alphabet
ATIS.Alphabet = {
  [1]  = "Alfa",
  [2]  = "Bravo",
  [3]  = "Charlie",
  [4]  = "Delta",
  [5]  = "Echo",
  [6]  = "Delta",
  [7]  = "Echo",
  [8]  = "Foxtrot",
  [9]  = "Golf",
  [10] = "Hotel",
  [11] = "India",
  [12] = "Juliett",
  [13] = "Kilo",
  [14] = "Lima",
  [15] = "Mike",
  [16] = "November",
  [17] = "Oscar",
  [18] = "Papa",
  [19] = "Quebec",
  [20] = "Romeo",
  [21] = "Sierra",
  [22] = "Tango",
  [23] = "Uniform",
  [24] = "Victor",
  [25] = "Whiskey",
  [26] = "Xray",
  [27] = "Yankee",
  [28] = "Zulu",
}

--- Runway correction for converting true to magnetic heading.
-- @type ATIS.RunwayM2T
-- @field #number Caucasus 0° (East).
-- @field #number Nevada +12° (East).
-- @field #number Normandy -10° (West).
-- @field #number PersianGulf +2° (East).
-- @field #number TheChannel -10° (West).
-- @field #number Syria +5° (East).
ATIS.RunwayM2T={
  Caucasus=0,
  Nevada=12,
  Normandy=-10,
  PersianGulf=2,
  TheChannel=-10,
  Syria=5,
}

--- Whether ICAO phraseology is used for ATIS broadcasts.
-- @type ATIS.ICAOPhraseology
-- @field #boolean Caucasus true.
-- @field #boolean Nevada false.
-- @field #boolean Normandy true.
-- @field #boolean PersianGulf true.
-- @field #boolean TheChannel true.
-- @field #boolean Syria true.
ATIS.ICAOPhraseology={
  Caucasus=true,
  Nevada=false,
  Normandy=true,
  PersianGulf=true,
  TheChannel=true,
  Syria=true,
}

--- Nav point data.
-- @type ATIS.NavPoint
-- @field #number frequency Nav point frequency.
-- @field #string runway Runway, *e.g.* "21".
-- @field #boolean leftright If true, runway has left "L" and right "R" runways.

--- Sound file data.
-- @type ATIS.Soundfile
-- @field #string filename Name of the file
-- @field #number duration Duration in seconds.

--- Sound files.
-- @type ATIS.Sound
-- @field #ATIS.Soundfile ActiveRunway
-- @field #ATIS.Soundfile AdviceOnInitial
-- @field #ATIS.Soundfile Airport
-- @field #ATIS.Soundfile Altimeter
-- @field #ATIS.Soundfile At
-- @field #ATIS.Soundfile CloudBase
-- @field #ATIS.Soundfile CloudCeiling
-- @field #ATIS.Soundfile CloudsBroken
-- @field #ATIS.Soundfile CloudsFew
-- @field #ATIS.Soundfile CloudsNo
-- @field #ATIS.Soundfile CloudsNotAvailable
-- @field #ATIS.Soundfile CloudsOvercast
-- @field #ATIS.Soundfile CloudsScattered
-- @field #ATIS.Soundfile Decimal
-- @field #ATIS.Soundfile DegreesCelsius
-- @field #ATIS.Soundfile DegreesFahrenheit
-- @field #ATIS.Soundfile DewPoint
-- @field #ATIS.Soundfile Dust
-- @field #ATIS.Soundfile Elevation
-- @field #ATIS.Soundfile EndOfInformation
-- @field #ATIS.Soundfile Feet
-- @field #ATIS.Soundfile Fog
-- @field #ATIS.Soundfile Gusting
-- @field #ATIS.Soundfile HectoPascal
-- @field #ATIS.Soundfile Hundred
-- @field #ATIS.Soundfile InchesOfMercury
-- @field #ATIS.Soundfile Information
-- @field #ATIS.Soundfile Kilometers
-- @field #ATIS.Soundfile Knots
-- @field #ATIS.Soundfile Left
-- @field #ATIS.Soundfile MegaHertz
-- @field #ATIS.Soundfile Meters
-- @field #ATIS.Soundfile MetersPerSecond
-- @field #ATIS.Soundfile Miles
-- @field #ATIS.Soundfile MillimetersOfMercury
-- @field #ATIS.Soundfile N0
-- @field #ATIS.Soundfile N1
-- @field #ATIS.Soundfile N2
-- @field #ATIS.Soundfile N3
-- @field #ATIS.Soundfile N4
-- @field #ATIS.Soundfile N5
-- @field #ATIS.Soundfile N6
-- @field #ATIS.Soundfile N7
-- @field #ATIS.Soundfile N8
-- @field #ATIS.Soundfile N9
-- @field #ATIS.Soundfile NauticalMiles
-- @field #ATIS.Soundfile None
-- @field #ATIS.Soundfile QFE
-- @field #ATIS.Soundfile QNH
-- @field #ATIS.Soundfile Rain
-- @field #ATIS.Soundfile Right
-- @field #ATIS.Soundfile Snow
-- @field #ATIS.Soundfile SnowStorm
-- @field #ATIS.Soundfile SunriseAt
-- @field #ATIS.Soundfile SunsetAt
-- @field #ATIS.Soundfile Temperature
-- @field #ATIS.Soundfile Thousand
-- @field #ATIS.Soundfile ThunderStorm
-- @field #ATIS.Soundfile TimeLocal
-- @field #ATIS.Soundfile TimeZulu
-- @field #ATIS.Soundfile TowerFrequency
-- @field #ATIS.Soundfile Visibilty
-- @field #ATIS.Soundfile WeatherPhenomena
-- @field #ATIS.Soundfile WindFrom
-- @field #ATIS.Soundfile ILSFrequency
-- @field #ATIS.Soundfile InnerNDBFrequency
-- @field #ATIS.Soundfile OuterNDBFrequency
-- @field #ATIS.Soundfile PRMGChannel
-- @field #ATIS.Soundfile RSBNChannel
-- @field #ATIS.Soundfile RunwayLength
-- @field #ATIS.Soundfile TACANChannel
-- @field #ATIS.Soundfile VORFrequency
ATIS.Sound = {
  ActiveRunway={filename="ActiveRunway.ogg", duration=0.99},
  AdviceOnInitial={filename="AdviceOnInitial.ogg", duration=3.00},
  Airport={filename="Airport.ogg", duration=0.66},
  Altimeter={filename="Altimeter.ogg", duration=0.68},
  At={filename="At.ogg", duration=0.41},
  CloudBase={filename="CloudBase.ogg", duration=0.82},
  CloudCeiling={filename="CloudCeiling.ogg", duration=0.61},
  CloudsBroken={filename="CloudsBroken.ogg", duration=1.07},
  CloudsFew={filename="CloudsFew.ogg", duration=0.99},
  CloudsNo={filename="CloudsNo.ogg", duration=1.01},
  CloudsNotAvailable={filename="CloudsNotAvailable.ogg", duration=2.35},
  CloudsOvercast={filename="CloudsOvercast.ogg", duration=0.83},
  CloudsScattered={filename="CloudsScattered.ogg", duration=1.18},
  Decimal={filename="Decimal.ogg", duration=0.54},
  DegreesCelsius={filename="DegreesCelsius.ogg", duration=1.27},
  DegreesFahrenheit={filename="DegreesFahrenheit.ogg", duration=1.23},
  DewPoint={filename="DewPoint.ogg", duration=0.65},
  Dust={filename="Dust.ogg", duration=0.54},
  Elevation={filename="Elevation.ogg", duration=0.78},
  EndOfInformation={filename="EndOfInformation.ogg", duration=1.15},
  Feet={filename="Feet.ogg", duration=0.45},
  Fog={filename="Fog.ogg", duration=0.47},
  Gusting={filename="Gusting.ogg", duration=0.55},
  HectoPascal={filename="HectoPascal.ogg", duration=1.15},
  Hundred={filename="Hundred.ogg", duration=0.47},
  InchesOfMercury={filename="InchesOfMercury.ogg", duration=1.16},
  Information={filename="Information.ogg", duration=0.85},
  Kilometers={filename="Kilometers.ogg", duration=0.78},
  Knots={filename="Knots.ogg", duration=0.59},
  Left={filename="Left.ogg", duration=0.54},
  MegaHertz={filename="MegaHertz.ogg", duration=0.87},
  Meters={filename="Meters.ogg", duration=0.59},
  MetersPerSecond={filename="MetersPerSecond.ogg", duration=1.14},
  Miles={filename="Miles.ogg", duration=0.60},
  MillimetersOfMercury={filename="MillimetersOfMercury.ogg", duration=1.53},
  Minus={filename="Minus.ogg", duration=0.64},
  N0={filename="N-0.ogg", duration=0.55},
  N1={filename="N-1.ogg", duration=0.41},
  N2={filename="N-2.ogg", duration=0.37},
  N3={filename="N-3.ogg", duration=0.41},
  N4={filename="N-4.ogg", duration=0.37},
  N5={filename="N-5.ogg", duration=0.43},
  N6={filename="N-6.ogg", duration=0.55},
  N7={filename="N-7.ogg", duration=0.43},
  N8={filename="N-8.ogg", duration=0.38},
  N9={filename="N-9.ogg", duration=0.55},
  NauticalMiles={filename="NauticalMiles.ogg", duration=1.04},
  None={filename="None.ogg", duration=0.43},
  QFE={filename="QFE.ogg", duration=0.63},
  QNH={filename="QNH.ogg", duration=0.71},
  Rain={filename="Rain.ogg", duration=0.41},
  Right={filename="Right.ogg", duration=0.44},
  Snow={filename="Snow.ogg", duration=0.48},
  SnowStorm={filename="SnowStorm.ogg", duration=0.82},
  StatuteMiles={filename="StatuteMiles.ogg", duration=1.15},
  SunriseAt={filename="SunriseAt.ogg", duration=0.92},
  SunsetAt={filename="SunsetAt.ogg", duration=0.95},
  Temperature={filename="Temperature.ogg", duration=0.64},
  Thousand={filename="Thousand.ogg", duration=0.55},
  ThunderStorm={filename="ThunderStorm.ogg", duration=0.81},
  TimeLocal={filename="TimeLocal.ogg", duration=0.90},
  TimeZulu={filename="TimeZulu.ogg", duration=0.86},
  TowerFrequency={filename="TowerFrequency.ogg", duration=1.19},
  Visibilty={filename="Visibility.ogg", duration=0.79},
  WeatherPhenomena={filename="WeatherPhenomena.ogg", duration=1.07},
  WindFrom={filename="WindFrom.ogg", duration=0.60},
  ILSFrequency={filename="ILSFrequency.ogg", duration=1.30},
  InnerNDBFrequency={filename="InnerNDBFrequency.ogg", duration=1.56},
  OuterNDBFrequency={filename="OuterNDBFrequency.ogg", duration=1.59},
  RunwayLength={filename="RunwayLength.ogg", duration=0.91},
  VORFrequency={filename="VORFrequency.ogg", duration=1.38},
  TACANChannel={filename="TACANChannel.ogg", duration=0.88},
  PRMGChannel={filename="PRMGChannel.ogg", duration=1.18},
  RSBNChannel={filename="RSBNChannel.ogg", duration=1.14},
  Zulu={filename="Zulu.ogg", duration=0.62},
}


--- ATIS table containing all defined ATISes.
-- @field #table _ATIS
_ATIS={}

--- ATIS class version.
-- @field #string version
ATIS.version="0.9.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Add new Normany airfields.
-- TODO: Zulu time --> Zulu in output.
-- TODO: Correct fog for elevation.
-- DONE: Add text report for output.
-- DONE: Add stop FMS functions.
-- NOGO: Use local time. Not realisitc!
-- DONE: Dew point. Approx. done.
-- DONE: Metric units.
-- DONE: Set UTC correction.
-- DONE: Set magnetic variation.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new ATIS class object for a specific aircraft carrier unit.
-- @param #ATIS self
-- @param #string airbasename Name of the airbase.
-- @param #number frequency Radio frequency in MHz. Default 143.00 MHz.
-- @param #number modulation Radio modulation: 0=AM, 1=FM. Default 0=AM. See `radio.modulation.AM` and `radio.modulation.FM` enumerators
-- @return #ATIS self
function ATIS:New(airbasename, frequency, modulation)

  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, FSM:New()) -- #ATIS

  self.airbasename=airbasename
  self.airbase=AIRBASE:FindByName(airbasename)

  if self.airbase==nil then
    self:E("ERROR: Airbase %s for ATIS could not be found!", tostring(airbasename))
    return nil
  end

  -- Default freq and modulation.
  self.frequency=frequency or 143.00
  self.modulation=modulation or 0

  -- Get map.
  self.theatre=env.mission.theatre

  -- Set some string id for output to DCS.log file.
  self.lid=string.format("ATIS %s | ", self.airbasename)

  -- This is just to hinder the garbage collector deallocating the ATIS object.
  _ATIS[#_ATIS+1]=self

  -- Defaults:
  self:SetSoundfilesPath()
  self:SetSubtitleDuration()
  self:SetMagneticDeclination()
  self:SetRunwayCorrectionMagnetic2True()
  self:SetRadioPower()
  self:SetAltimeterQNH(true)
  self:SetMapMarks(false)
  self:SetRelativeHumidity()

  -- Start State.
  self:SetStartState("Stopped")

  -- Add FSM transitions.
  --                 From State  -->   Event      -->     To State
  self:AddTransition("Stopped",       "Start",           "Running") -- Start FSM.
  self:AddTransition("*",             "Status",          "*")       -- Update status.
  self:AddTransition("*",             "Broadcast",       "*")       -- Broadcast ATIS message.
  self:AddTransition("*",             "CheckQueue",      "*")       -- Check if radio queue is empty.
  self:AddTransition("*",             "Report",          "*")       -- Report ATIS text.
  self:AddTransition("*",             "Stop",            "Stopped") -- Stop.

  ------------------------
  --- Pseudo Functions ---
  ------------------------

  --- Triggers the FSM event "Start". Starts the ATIS.
  -- @function [parent=#ATIS] Start
  -- @param #ATIS self

  --- Triggers the FSM event "Start" after a delay.
  -- @function [parent=#ATIS] __Start
  -- @param #ATIS self
  -- @param #number delay Delay in seconds.


  --- Triggers the FSM event "Stop". Stops the ATIS.
  -- @function [parent=#ATIS] Stop
  -- @param #ATIS self

  --- Triggers the FSM event "Stop" after a delay.
  -- @function [parent=#ATIS] __Stop
  -- @param #ATIS self
  -- @param #number delay Delay in seconds.


  --- Triggers the FSM event "Status".
  -- @function [parent=#ATIS] Status
  -- @param #ATIS self

  --- Triggers the FSM event "Status" after a delay.
  -- @function [parent=#ATIS] __Status
  -- @param #ATIS self
  -- @param #number delay Delay in seconds.


  --- Triggers the FSM event "Broadcast".
  -- @function [parent=#ATIS] Broadcast
  -- @param #ATIS self

  --- Triggers the FSM event "Broadcast" after a delay.
  -- @function [parent=#ATIS] __Broadcast
  -- @param #ATIS self
  -- @param #number delay Delay in seconds.


  --- Triggers the FSM event "CheckQueue".
  -- @function [parent=#ATIS] CheckQueue
  -- @param #ATIS self

  --- Triggers the FSM event "CheckQueue" after a delay.
  -- @function [parent=#ATIS] __CheckQueue
  -- @param #ATIS self
  -- @param #number delay Delay in seconds.


  --- Triggers the FSM event "Report".
  -- @function [parent=#ATIS] Report
  -- @param #ATIS self
  -- @param #string Text Report text.

  --- Triggers the FSM event "Report" after a delay.
  -- @function [parent=#ATIS] __Report
  -- @param #ATIS self
  -- @param #number delay Delay in seconds.
  -- @param #string Text Report text.

  --- On after "Report" event user function.
  -- @function [parent=#ATIS] OnAfterReport
  -- @param #ATIS self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #string Text Report text.


  -- Debug trace.
  if false then
    self.Debug=true
    BASE:TraceOnOff(true)
    BASE:TraceClass(self.ClassName)
    BASE:TraceLevel(1)
  end

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set sound files folder within miz file.
-- @param #ATIS self
-- @param #string path Path for sound files. Default "ATIS Soundfiles/". Mind the slash "/" at the end!
-- @return #ATIS self
function ATIS:SetSoundfilesPath(path)
  self.soundpath=tostring(path or "ATIS Soundfiles/")
  self:I(self.lid..string.format("Setting sound files path to %s", self.soundpath))
  return self
end

--- Set airborne unit (airplane or helicopter), used to transmit radio messages including subtitles.
-- Best is to place the unit on a parking spot of the airbase and set it to *uncontrolled* in the mission editor.
-- @param #ATIS self
-- @param #string unitname Name of the unit.
-- @return #ATIS self
function ATIS:SetRadioRelayUnitName(unitname)
  self.relayunitname=unitname
  self:I(self.lid..string.format("Setting radio relay unit to %s", self.relayunitname))
  return self
end

--- Set tower frequencies.
-- @param #ATIS self
-- @param #table freqs Table of frequencies in MHz. A single frequency can be given as a plain number (*i.e.* must not be table).
-- @return #ATIS self
function ATIS:SetTowerFrequencies(freqs)
  if type(freqs)=="table" then
    -- nothing to do
  else
    freqs={freqs}
  end
  self.towerfrequency=freqs
  return self
end

--- Set active runway. This can be used if the automatic runway determination via the wind direction gives incorrect results.
-- For example, use this if there are two runways with the same directions.
-- @param #ATIS self
-- @param #string runway Active runway, *e.g.* "31L".
-- @return #ATIS self
function ATIS:SetActiveRunway(runway)
  self.activerunway=tostring(runway)
  return self
end

--- Give information on runway length.
-- @param #ATIS self
-- @return #ATIS self
function ATIS:SetRunwayLength()
  self.rwylength=true
  return self
end

--- Give information on airfield elevation
-- @param #ATIS self
-- @return #ATIS self
function ATIS:SetElevation()
  self.elevation=true
  return self
end

--- Set radio power. Note that this only applies if no relay unit is used.
-- @param #ATIS self
-- @param #number power Radio power in Watts. Default 100 W.
-- @return #ATIS self
function ATIS:SetRadioPower(power)
  self.power=power or 100
  return self
end

--- Use F10 map mark points.
-- @param #ATIS self
-- @param #boolean switch If *true* or *nil*, marks are placed on F10 map. If *false* this feature is set to off (default).
-- @return #ATIS self
function ATIS:SetMapMarks(switch)
  if switch==nil or switch==true then
    self.usemarker=true
  else
    self.usemarker=false
  end
  return self
end

--- Set magnetic runway headings as depicted on the runway, *e.g.* "13" for 130° or "25L" for the left runway with magnetic heading 250°.
-- @param #ATIS self
-- @param #table headings Magnetic headings. Inverse (-180°) headings are added automatically. You only need to specify one heading per runway direction. "L"eft and "R" right can also be appended.
-- @return #ATIS self
function ATIS:SetRunwayHeadingsMagnetic(headings)

  -- First make sure, we have a table.
  if type(headings)=="table" then
    -- nothing to do
  else
    headings={headings}
  end

  for _,heading in pairs(headings) do

    if type(heading)=="number" then
      heading=string.format("%02d", heading)
    end

    -- Add runway heading to table.
    self:I(self.lid..string.format("Adding user specified magnetic runway heading %s", heading))
    table.insert(self.runwaymag, heading)

    local h=self:GetRunwayWithoutLR(heading)

    local head2=tonumber(h)-18
    if head2<0 then
      head2=head2+36
    end

    -- Convert to string.
    head2=string.format("%02d", head2)

    -- Append "L" or "R" if necessary.
    local left=self:GetRunwayLR(heading)
    if left==true then
      head2=head2.."L"
    elseif left==false then
      head2=head2.."R"
    end

    -- Add inverse runway heading to table.
    self:I(self.lid..string.format("Adding user specified magnetic runway heading %s (inverse)", head2))
    table.insert(self.runwaymag, head2)
  end

  return self
end

--- Set duration how long subtitles are displayed.
-- @param #ATIS self
-- @param #number duration Duration in seconds. Default 10 seconds.
-- @return #ATIS self
function ATIS:SetSubtitleDuration(duration)
  self.subduration=tonumber(duration or 10)
  return self
end

--- Set unit system to metric units.
-- @param #ATIS self
-- @return #ATIS self
function ATIS:SetMetricUnits()
  self.metric=true
  return self
end

--- Set unit system to imperial units.
-- @param #ATIS self
-- @return #ATIS self
function ATIS:SetImperialUnits()
  self.metric=false
  return self
end

--- Set pressure unit to millimeters of mercury (mmHg).
-- Default is inHg for imperial and hPa (=mBar) for metric units.
-- @param #ATIS self
-- @return #ATIS self
function ATIS:SetPressureMillimetersMercury()
  self.PmmHg=true
  return self
end

--- Set temperature to be given in degrees Fahrenheit.
-- @param #ATIS self
-- @return #ATIS self
function ATIS:SetTemperatureFahrenheit()
  self.TDegF=true
  return self
end

--- Set relative humidity. This is used to approximately calculate the dew point.
-- Note that the dew point is only an artificial information as DCS does not have an atmospheric model that includes humidity (yet). 
-- @param #ATIS self
-- @param #number Humidity Relative Humidity, i.e. a number between 0 and 100 %. Default is 50 %. 
-- @return #ATIS self
function ATIS:SetRelativeHumidity(Humidity)
  self.relHumidity=Humidity or 50  
  return self
end

--- Report altimeter QNH.
-- @param #ATIS self
-- @param #boolean switch If true or nil, report altimeter QHN. If false, report QFF.
-- @return #ATIS self
function ATIS:SetAltimeterQNH(switch)

  if switch==true or switch==nil then
    self.altimeterQNH=true
  else
    self.altimeterQNH=false
  end

  return self
end

--- Suppresses QFE readout. Default is to report both QNH and QFE.
-- @param #ATIS self
-- @return #ATIS self
function ATIS:ReportQNHOnly()
  self.qnhonly=true
  return self
end

--- Set magnetic declination/variation at the airport.
--
-- Default is per map:
--
-- * Caucasus +6 (East), year ~ 2011
-- * NTTR +12 (East), year ~ 2011
-- * Normandy -10 (West), year ~ 1944
-- * Persian Gulf +2 (East), year ~ 2011
--
-- To get *true* from *magnetic* heading one has to add easterly or substract westerly variation, e.g
--
-- A magnetic heading of 180° corresponds to a true heading of
--
--   * 186° on the Caucaus map
--   * 192° on the Nevada map
--   * 170° on the Normany map
--   * 182° on the Persian Gulf map
--
-- Likewise, to convert *magnetic* into *true* heading, one has to substract easterly and add westerly variation.
--
-- @param #ATIS self
-- @param #number magvar Magnetic variation in degrees. Positive for easterly and negative for westerly variation. Default is magnatic declinaton of the used map, c.f. @{Utilities.UTils#UTILS.GetMagneticDeclination}.
-- @return #ATIS self
function ATIS:SetMagneticDeclination(magvar)
  self.magvar=magvar or UTILS.GetMagneticDeclination()
  return self
end

--- Explicitly set correction of magnetic to true heading for runways.
-- @param #ATIS self
-- @param #number correction Correction of magnetic to true heading for runways in degrees.
-- @return #ATIS self
function ATIS:SetRunwayCorrectionMagnetic2True(correction)
  self.runwaym2t=correction or ATIS.RunwayM2T[UTILS.GetDCSMap()]
  return self
end

--- Set wind direction (from) to be reported as *true* heading. Default is magnetic.
-- @param #ATIS self
-- @return #ATIS self
function ATIS:SetReportWindTrue()
  self.windtrue=true
  return self
end

--- Set time local difference with respect to Zulu time.
-- Default is per map:
--
--    * Caucasus +4
--    * Nevada -8
--    * Normandy 0
--    * Persian Gulf +4
--    * The Channel +2 (should be 0)
--
-- @param #ATIS self
-- @param #number delta Time difference in hours.
-- @return #ATIS self
function ATIS:SetZuluTimeDifference(delta)
  self.zuludiff=delta
  return self
end

--- Suppresses local time, sunrise, and sunset. Default is to report all these times.
-- @param #ATIS self
-- @return #ATIS self
function ATIS:ReportZuluTimeOnly()
  self.zulutimeonly=true
  return self
end

--- Add ILS station. Note that this can be runway specific.
-- @param #ATIS self
-- @param #number frequency ILS frequency in MHz.
-- @param #string runway (Optional) Runway for which the given ILS frequency applies. Default all (*nil*).
-- @return #ATIS self
function ATIS:AddILS(frequency, runway)
  local ils={} --#ATIS.NavPoint
  ils.frequency=tonumber(frequency)
  ils.runway=runway and tostring(runway) or nil
  table.insert(self.ils, ils)
  return self
end

--- Set VOR station.
-- @param #ATIS self
-- @param #number frequency VOR frequency.
-- @return #ATIS self
function ATIS:SetVOR(frequency)
  self.vor=frequency
  return self
end

--- Add outer NDB. Note that this can be runway specific.
-- @param #ATIS self
-- @param #number frequency NDB frequency in MHz.
-- @param #string runway (Optional) Runway for which the given NDB frequency applies. Default all (*nil*).
-- @return #ATIS self
function ATIS:AddNDBouter(frequency, runway)
  local ndb={} --#ATIS.NavPoint
  ndb.frequency=tonumber(frequency)
  ndb.runway=runway and tostring(runway) or nil
  table.insert(self.ndbouter, ndb)
  return self
end

--- Add inner NDB. Note that this can be runway specific.
-- @param #ATIS self
-- @param #number frequency NDB frequency in MHz.
-- @param #string runway (Optional) Runway for which the given NDB frequency applies. Default all (*nil*).
-- @return #ATIS self
function ATIS:AddNDBinner(frequency, runway)
  local ndb={} --#ATIS.NavPoint
  ndb.frequency=tonumber(frequency)
  ndb.runway=runway and tostring(runway) or nil
  table.insert(self.ndbinner, ndb)
  return self
end

--- Set TACAN channel.
-- @param #ATIS self
-- @param #number channel TACAN channel.
-- @return #ATIS self
function ATIS:SetTACAN(channel)
  self.tacan=channel
  return self
end

--- Set RSBN channel.
-- @param #ATIS self
-- @param #number channel RSBN channel.
-- @return #ATIS self
function ATIS:SetRSBN(channel)
  self.rsbn=channel
  return self
end

--- Add PRMG channel. Note that this can be runway specific.
-- @param #ATIS self
-- @param #number channel PRMG channel.
-- @param #string runway (Optional) Runway for which the given PRMG channel applies. Default all (*nil*).
-- @return #ATIS self
function ATIS:AddPRMG(channel, runway)
  local ndb={} --#ATIS.NavPoint
  ndb.frequency=tonumber(channel)
  ndb.runway=runway and tostring(runway) or nil
  table.insert(self.prmg, ndb)
  return self
end


--- Place marks with runway data on the F10 map.
-- @param #ATIS self
-- @param #boolean markall If true, mark all runways of the map. By default only the current ATIS runways are marked.
function ATIS:MarkRunways(markall)
  local airbases=AIRBASE.GetAllAirbases()
  for _,_airbase in pairs(airbases) do
    local airbase=_airbase --Wrapper.Airbase#AIRBASE
    if (not markall and airbase:GetName()==self.airbasename) or markall==true then
      airbase:GetRunwayData(self.runwaym2t, true)
    end
  end
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Start & Status
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Start ATIS FSM.
-- @param #ATIS self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function ATIS:onafterStart(From, Event, To)

  -- Check that this is an airdrome.
  if self.airbase:GetAirbaseCategory()~=Airbase.Category.AIRDROME then
    self:E(self.lid..string.format("ERROR: Cannot start ATIS for airbase %s! Only AIRDROMES are supported but NOT FARPS or SHIPS.", self.airbasename))
    return
  end

  -- Info.
  self:I(self.lid..string.format("Starting ATIS v%s for airbase %s on %.3f MHz Modulation=%d", ATIS.version, self.airbasename, self.frequency, self.modulation))

  -- Start radio queue.
  self.radioqueue=RADIOQUEUE:New(self.frequency, self.modulation, string.format("ATIS %s", self.airbasename))

  -- Send coordinate is airbase coord.
  self.radioqueue:SetSenderCoordinate(self.airbase:GetCoordinate())

  -- Set relay unit if we have one.
  self.radioqueue:SetSenderUnitName(self.relayunitname)

  -- Set radio power.
  self.radioqueue:SetRadioPower(self.power)

  -- Init numbers.
  self.radioqueue:SetDigit(0, ATIS.Sound.N0.filename, ATIS.Sound.N0.duration, self.soundpath)
  self.radioqueue:SetDigit(1, ATIS.Sound.N1.filename, ATIS.Sound.N1.duration, self.soundpath)
  self.radioqueue:SetDigit(2, ATIS.Sound.N2.filename, ATIS.Sound.N2.duration, self.soundpath)
  self.radioqueue:SetDigit(3, ATIS.Sound.N3.filename, ATIS.Sound.N3.duration, self.soundpath)
  self.radioqueue:SetDigit(4, ATIS.Sound.N4.filename, ATIS.Sound.N4.duration, self.soundpath)
  self.radioqueue:SetDigit(5, ATIS.Sound.N5.filename, ATIS.Sound.N5.duration, self.soundpath)
  self.radioqueue:SetDigit(6, ATIS.Sound.N6.filename, ATIS.Sound.N6.duration, self.soundpath)
  self.radioqueue:SetDigit(7, ATIS.Sound.N7.filename, ATIS.Sound.N7.duration, self.soundpath)
  self.radioqueue:SetDigit(8, ATIS.Sound.N8.filename, ATIS.Sound.N8.duration, self.soundpath)
  self.radioqueue:SetDigit(9, ATIS.Sound.N9.filename, ATIS.Sound.N9.duration, self.soundpath)

  -- Start radio queue.
  self.radioqueue:Start(1, 0.1)

  -- Init status updates.
  self:__Status(-2)
  self:__CheckQueue(-3)
end

--- Update status.
-- @param #ATIS self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function ATIS:onafterStatus(From, Event, To)

  -- Get FSM state.
  local fsmstate=self:GetState()

  local relayunitstatus="N/A"
  if self.relayunitname then
    local ru=UNIT:FindByName(self.relayunitname)
    if ru then
      relayunitstatus=tostring(ru:IsAlive())
    end
  end

    -- Info text.
  local text=string.format("State %s: Freq=%.3f MHz %s, Relay unit=%s (alive=%s)", fsmstate, self.frequency, UTILS.GetModulationName(self.modulation), tostring(self.relayunitname), relayunitstatus)
  self:I(self.lid..text)

  self:__Status(-60)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Events
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Check if radio queue is empty. If so, start broadcasting the message again.
-- @param #ATIS self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function ATIS:onafterCheckQueue(From, Event, To)

  if #self.radioqueue.queue==0 then
    self:T(self.lid..string.format("Radio queue empty. Repeating message."))
    self:Broadcast()
  else
    self:T2(self.lid..string.format("Radio queue %d transmissions queued.", #self.radioqueue.queue))
  end

  -- Check back in 5 seconds.
  self:__CheckQueue(-5)
end

--- Broadcast ATIS radio message.
-- @param #ATIS self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function ATIS:onafterBroadcast(From, Event, To)

  -- Get current coordinate.
  local coord=self.airbase:GetCoordinate()

  -- Get elevation.
  local height=coord:GetLandHeight()

  ----------------
  --- Pressure ---
  ----------------

  -- Pressure in hPa.
  local qfe=coord:GetPressure(height)
  local qnh=coord:GetPressure(0)

  if self.altimeterQNH then

    -- Some constants.
    local L=-0.0065    --[K/m]
    local R= 8.31446   --[J/mol/K]
    local g= 9.80665   --[m/s^2]
    local M= 0.0289644 --[kg/mol]
    local T0=coord:GetTemperature(0)+273.15 --[K] Temp at sea level.
    local TS=288.15   -- Standard Temperature assumed by Altimeter is 15°C
    local q=qnh*100

    -- Calculate Pressure.
    local P=q*(1+L*height/T0)^(-g*M/(R*L))    -- Pressure at sea level
    local Q=P/(1+L*height/TS)^(-g*M/(R*L))    -- Altimeter QNH
    local A=(T0/L)*((P/q)^(((-R*L)/(g*M)))-1) -- Altitude check


    -- Debug aoutput
    self:T2(self.lid..string.format("height=%.1f, A=%.1f, T0=%.1f, QFE=%.1f, QNH=%.1f, P=%.1f, Q=%.1f hPa = %.2f", height, A, T0-273.15, qfe, qnh, P/100, Q/100, UTILS.hPa2inHg(Q/100)))

    -- Set QNH value in hPa.
    qnh=Q/100

  end


  -- Convert to inHg.
  if self.PmmHg then
    qfe=UTILS.hPa2mmHg(qfe)
    qnh=UTILS.hPa2mmHg(qnh)
  else
    if not self.metric then
      qfe=UTILS.hPa2inHg(qfe)
      qnh=UTILS.hPa2inHg(qnh)
    end
  end

  local QFE=UTILS.Split(string.format("%.2f", qfe), ".")
  local QNH=UTILS.Split(string.format("%.2f", qnh), ".")

  if self.PmmHg then
    QFE=UTILS.Split(string.format("%.1f", qfe), ".")
    QNH=UTILS.Split(string.format("%.1f", qnh), ".")
  else
    if self.metric then
      QFE=UTILS.Split(string.format("%.1f", qfe), ".")
      QNH=UTILS.Split(string.format("%.1f", qnh), ".")
    end
  end

  ------------
  --- Wind ---
  ------------

  -- Get wind direction and speed in m/s.
  local windFrom, windSpeed=coord:GetWind(height+10)

  -- Wind in magnetic or true.
  local magvar=self.magvar
  if self.windtrue then
    magvar=0
  end
  windFrom=windFrom-magvar
  
  -- Correct negative values.
  if windFrom<0 then
    windFrom=windFrom+360
  end

  local WINDFROM=string.format("%03d", windFrom)
  local WINDSPEED=string.format("%d", UTILS.MpsToKnots(windSpeed))
  
  -- Report North as 0.
  if WINDFROM=="000" then
    WINDFROM="360"
  end

  if self.metric then
    WINDSPEED=string.format("%d", windSpeed)
  end

  --------------
  --- Runway ---
  --------------

  local runway, rwyLeft=self:GetActiveRunway()

  ------------
  --- Time ---
  ------------
  local time=timer.getAbsTime()

  -- Conversion to Zulu time.
  if self.zuludiff then
    -- User specified.
    time=time-self.zuludiff*60*60
  else
    time=time-UTILS.GMTToLocalTimeDifference()*60*60
  end

  if time < 0 then
     time = 24*60*60 + time --avoid negative time around midnight
  end
  
  local clock=UTILS.SecondsToClock(time)
  local zulu=UTILS.Split(clock, ":")
  local ZULU=string.format("%s%s", zulu[1], zulu[2])


  -- NATO time stamp. 0=Alfa, 1=Bravo, 2=Charlie, etc.
  local NATO=ATIS.Alphabet[tonumber(zulu[1])+1]

  -- Debug.
  self:T3(string.format("clock=%s", tostring(clock)))
  self:T3(string.format("zulu1=%s", tostring(zulu[1])))
  self:T3(string.format("zulu2=%s", tostring(zulu[2])))
  self:T3(string.format("ZULU =%s", tostring(ZULU)))
  self:T3(string.format("NATO =%s", tostring(NATO)))

  --------------------------
  --- Sunrise and Sunset ---
  --------------------------

  local sunrise=coord:GetSunrise()
  sunrise=UTILS.Split(sunrise, ":")
  local SUNRISE=string.format("%s%s", sunrise[1], sunrise[2])

  local sunset=coord:GetSunset()  
  sunset=UTILS.Split(sunset, ":")
  local SUNSET=string.format("%s%s", sunset[1], sunset[2])

  ---------------------------------
  --- Temperature and Dew Point ---
  ---------------------------------

  -- Temperature in °C.
  local temperature=coord:GetTemperature(height+5)
  
  -- Dew point in °C.
  local dewpoint=temperature-(100-self.relHumidity)/5

  -- Convert to °F.
  if self.TDegF then
    temperature=UTILS.CelciusToFarenheit(temperature)
    dewpoint=UTILS.CelciusToFarenheit(dewpoint)
  end

  local TEMPERATURE=string.format("%d", math.abs(temperature))
  local DEWPOINT=string.format("%d", math.abs(dewpoint))

  ---------------
  --- Weather ---
  ---------------

  -- Get mission weather info. Most of this is static.
  local clouds, visibility, turbulence, fog, dust, static=self:GetMissionWeather()

  -- Check that fog is actually "thick" enough to reach the airport. If an airport is in the mountains, fog might not affect it as it is measured from sea level.
  if fog and fog.thickness<height+25 then
    fog=nil
  end

  -- Dust only up to 1500 ft = 457 m ASL.
  if dust and height+25>UTILS.FeetToMeters(1500) then
    dust=nil
  end

  ------------------
  --- Visibility ---
  ------------------

  -- Get min visibility.
  local visibilitymin=visibility

  if fog then
    if fog.visibility<visibilitymin then
      visibilitymin=fog.visibility
    end
  end

  if dust then
    if dust<visibilitymin then
      visibilitymin=dust
    end
  end
  
  local VISIBILITY=""

  if self.metric then
    -- Visibility in km.
    local reportedviz=UTILS.Round(visibilitymin/1000)
    -- max reported visibility 9999 m
    if reportedviz > 10 then
      reportedviz=10
    end
    VISIBILITY=string.format("%d", reportedviz)
  else
    -- max reported visibility 10 NM
    local reportedviz=UTILS.Round(UTILS.MetersToSM(visibilitymin))
    if reportedviz > 10 then
      reportedviz=10
    end
    VISIBILITY=string.format("%d", reportedviz)
  end

  --------------
  --- Clouds ---
  --------------

  local cloudbase=clouds.base
  local cloudceil=clouds.base+clouds.thickness
  local clouddens=clouds.density

  -- Cloud preset (DCS 2.7)  
  local cloudspreset=clouds.preset or "Nothing"
  
  -- Precepitation: 0=None, 1=Rain, 2=Thunderstorm, 3=Snow, 4=Snowstorm.
  local precepitation=0  

  if cloudspreset:find("Preset10") then
    -- Scattered 5
    clouddens=4
  elseif cloudspreset:find("Preset11") then
    -- Scattered 6
    clouddens=4
  elseif cloudspreset:find("Preset12") then
    -- Scattered 7
    clouddens=4
  elseif cloudspreset:find("Preset13") then
    -- Broken 1
    clouddens=7
  elseif cloudspreset:find("Preset14") then
    -- Broken 2
    clouddens=7        
  elseif cloudspreset:find("Preset15") then
    -- Broken 3
    clouddens=7        
  elseif cloudspreset:find("Preset16") then
    -- Broken 4
    clouddens=7        
  elseif cloudspreset:find("Preset17") then
    -- Broken 5
    clouddens=7        
  elseif cloudspreset:find("Preset18") then
    -- Broken 6
    clouddens=7        
  elseif cloudspreset:find("Preset19") then
    -- Broken 7
    clouddens=7        
  elseif cloudspreset:find("Preset20") then
    -- Broken 8
    clouddens=7        
  elseif cloudspreset:find("Preset21") then
    -- Overcast 1
    clouddens=9        
  elseif cloudspreset:find("Preset22") then
    -- Overcast 2
    clouddens=9        
  elseif cloudspreset:find("Preset23") then
    -- Overcast 3
    clouddens=9        
  elseif cloudspreset:find("Preset24") then
    -- Overcast 4
    clouddens=9        
  elseif cloudspreset:find("Preset25") then
    -- Overcast 5
    clouddens=9        
  elseif cloudspreset:find("Preset26") then
    -- Overcast 6
    clouddens=9        
  elseif cloudspreset:find("Preset27") then
    -- Overcast 7
    clouddens=9                        
  elseif cloudspreset:find("Preset1") then
    -- Light Scattered 1
    clouddens=1
  elseif cloudspreset:find("Preset2") then
    -- Light Scattered 2
    clouddens=1
  elseif cloudspreset:find("Preset3") then
    -- High Scattered 1
    clouddens=4
  elseif cloudspreset:find("Preset4") then
    -- High Scattered 2
    clouddens=4
  elseif cloudspreset:find("Preset5") then
    -- Scattered 1
    clouddens=4
  elseif cloudspreset:find("Preset6") then
    -- Scattered 2
    clouddens=4
  elseif cloudspreset:find("Preset7") then
    -- Scattered 3
    clouddens=4
  elseif cloudspreset:find("Preset8") then
    -- High Scattered 3
    clouddens=4
  elseif cloudspreset:find("Preset9") then
    -- Scattered 4
    clouddens=4
  elseif cloudspreset:find("RainyPreset") then
    -- Overcast + Rain
    clouddens=9
    if temperature>5 then
      precepitation=1  -- rain
    else
      precepitation=3  -- snow
    end
  end
  
  local CLOUDBASE=string.format("%d", UTILS.MetersToFeet(cloudbase))
  local CLOUDCEIL=string.format("%d", UTILS.MetersToFeet(cloudceil))

  if self.metric then
    CLOUDBASE=string.format("%d", cloudbase)
    CLOUDCEIL=string.format("%d", cloudceil)
  end

  -- Cloud base/ceiling in thousands and hundrets of ft/meters.
  local CLOUDBASE1000, CLOUDBASE0100=self:_GetThousandsAndHundreds(UTILS.MetersToFeet(cloudbase))
  local CLOUDCEIL1000, CLOUDCEIL0100=self:_GetThousandsAndHundreds(UTILS.MetersToFeet(cloudceil))

  if self.metric then
    CLOUDBASE1000, CLOUDBASE0100=self:_GetThousandsAndHundreds(cloudbase)
    CLOUDCEIL1000, CLOUDCEIL0100=self:_GetThousandsAndHundreds(cloudceil)
  end

  -- No cloud info for dynamic weather.
  local CloudCover={} --#ATIS.Soundfile
  CloudCover=ATIS.Sound.CloudsNotAvailable
  local CLOUDSsub="Cloud coverage information not available"

  -- Only valid for static weather.
  if static then
    if clouddens>=9 then
      -- Overcast 9,10
      CloudCover=ATIS.Sound.CloudsOvercast
      CLOUDSsub="Overcast"
    elseif clouddens>=7 then
      -- Broken 7,8
      CloudCover=ATIS.Sound.CloudsBroken
      CLOUDSsub="Broken clouds"
    elseif clouddens>=4 then
      -- Scattered 4,5,6
      CloudCover=ATIS.Sound.CloudsScattered
      CLOUDSsub="Scattered clouds"
    elseif clouddens>=1 then
      -- Few 1,2,3
      CloudCover=ATIS.Sound.CloudsFew
      CLOUDSsub="Few clouds"
    else
      -- No clouds
      CLOUDBASE=nil
      CLOUDCEIL=nil
      CloudCover=ATIS.Sound.CloudsNo
      CLOUDSsub="No clouds"
    end
  end

  --------------------
  --- Transmission ---
  --------------------

  -- Subtitle
  local subtitle=""

  --Airbase name
  subtitle=string.format("%s", self.airbasename)
  if self.airbasename:find("AFB")==nil and self.airbasename:find("Airport")==nil and self.airbasename:find("Airstrip")==nil and self.airbasename:find("airfield")==nil and self.airbasename:find("AB")==nil then
    subtitle=subtitle.." Airport"
  end
  self.radioqueue:NewTransmission(string.format("%s/%s.ogg", self.theatre, self.airbasename), 3.0, self.soundpath, nil, nil, subtitle, self.subduration)
  local alltext=subtitle

  -- Information tag
  subtitle=string.format("Information %s", NATO)
  local _INFORMATION=subtitle
  self:Transmission(ATIS.Sound.Information, 0.5, subtitle)
  self.radioqueue:NewTransmission(string.format("NATO Alphabet/%s.ogg", NATO), 0.75, self.soundpath)
  alltext=alltext..";\n"..subtitle

  -- Zulu Time
  subtitle=string.format("%s Zulu", ZULU)
  self.radioqueue:Number2Transmission(ZULU, nil, 0.5)
  self:Transmission(ATIS.Sound.Zulu, 0.2, subtitle)
  alltext=alltext..";\n"..subtitle
  
  if not self.zulutimeonly then

    -- Sunrise Time
    subtitle=string.format("Sunrise at %s local time", SUNRISE)
    self:Transmission(ATIS.Sound.SunriseAt, 0.5, subtitle)
    self.radioqueue:Number2Transmission(SUNRISE, nil, 0.2)
    self:Transmission(ATIS.Sound.TimeLocal, 0.2)
    alltext=alltext..";\n"..subtitle
  
    -- Sunset Time
    subtitle=string.format("Sunset at %s local time", SUNSET)
    self:Transmission(ATIS.Sound.SunsetAt, 0.5, subtitle)
    self.radioqueue:Number2Transmission(SUNSET, nil, 0.5)
    self:Transmission(ATIS.Sound.TimeLocal, 0.2)
    alltext=alltext..";\n"..subtitle
  end
  
  -- Wind
  if self.metric then
    subtitle=string.format("Wind from %s at %s m/s", WINDFROM, WINDSPEED)
  else
    subtitle=string.format("Wind from %s at %s knots", WINDFROM, WINDSPEED)
  end
  if turbulence>0 then
    subtitle=subtitle..", gusting"
  end
  local _WIND=subtitle
  self:Transmission(ATIS.Sound.WindFrom, 1.0, subtitle)
  self.radioqueue:Number2Transmission(WINDFROM)
  self:Transmission(ATIS.Sound.At, 0.2)
  self.radioqueue:Number2Transmission(WINDSPEED)
  if self.metric then
    self:Transmission(ATIS.Sound.MetersPerSecond, 0.2)
  else
    self:Transmission(ATIS.Sound.Knots, 0.2)
  end
  if turbulence>0 then
    self:Transmission(ATIS.Sound.Gusting, 0.2)
  end
  alltext=alltext..";\n"..subtitle

  -- Visibility
  if self.metric then
    subtitle=string.format("Visibility %s km", VISIBILITY)
  else
    subtitle=string.format("Visibility %s SM", VISIBILITY)
  end
  self:Transmission(ATIS.Sound.Visibilty, 1.0, subtitle)
  self.radioqueue:Number2Transmission(VISIBILITY)
  if self.metric then
    self:Transmission(ATIS.Sound.Kilometers, 0.2)
  else
    self:Transmission(ATIS.Sound.StatuteMiles, 0.2)
  end
  alltext=alltext..";\n"..subtitle
  
  -- Weather phenomena
  local wp=false
  local wpsub=""
  if precepitation==1 then
    wp=true
    wpsub=wpsub.." rain"
  elseif precepitation==2 then
    if wp then
      wpsub=wpsub..","
    end
    wpsub=wpsub.." thunderstorm"
    wp=true
  elseif precepitation==3 then
    wpsub=wpsub.." snow"
    wp=true
  elseif precepitation==4 then
    wpsub=wpsub.." snowstorm"
    wp=true
  end
  if fog then
    if wp then
      wpsub=wpsub..","
    end
    wpsub=wpsub.." fog"
    wp=true
  end
  if dust then
    if wp then
      wpsub=wpsub..","
    end
    wpsub=wpsub.." dust"
    wp=true
  end
  -- Actual output
  if wp then
    subtitle=string.format("Weather phenomena:%s", wpsub)
    self:Transmission(ATIS.Sound.WeatherPhenomena, 1.0, subtitle)
    if precepitation==1 then
      self:Transmission(ATIS.Sound.Rain, 0.5)
    elseif precepitation==2 then
      self:Transmission(ATIS.Sound.ThunderStorm, 0.5)
    elseif precepitation==3 then
      self:Transmission(ATIS.Sound.Snow, 0.5)
    elseif precepitation==4 then
      self:Transmission(ATIS.Sound.SnowStorm, 0.5)
    end
    if fog then
      self:Transmission(ATIS.Sound.Fog, 0.5)
    end
    if dust then
      self:Transmission(ATIS.Sound.Dust, 0.5)
    end
    alltext=alltext..";\n"..subtitle
  end

  -- Cloud base
  self:Transmission(CloudCover, 1.0, CLOUDSsub)
  if CLOUDBASE and static then
    -- Base
    if self.metric then
      subtitle=string.format("Cloudbase %s, ceiling %s meters", CLOUDBASE, CLOUDCEIL)
    else
      subtitle=string.format("Cloudbase %s, ceiling %s ft", CLOUDBASE, CLOUDCEIL)
    end
    self:Transmission(ATIS.Sound.CloudBase, 1.0, subtitle)
    if tonumber(CLOUDBASE1000)>0 then
      self.radioqueue:Number2Transmission(CLOUDBASE1000)
      self:Transmission(ATIS.Sound.Thousand, 0.1)
    end
    if tonumber(CLOUDBASE0100)>0 then
      self.radioqueue:Number2Transmission(CLOUDBASE0100)
      self:Transmission(ATIS.Sound.Hundred, 0.1)
    end
    -- Ceiling
    self:Transmission(ATIS.Sound.CloudCeiling, 0.5)
    if tonumber(CLOUDCEIL1000)>0 then
      self.radioqueue:Number2Transmission(CLOUDCEIL1000)
      self:Transmission(ATIS.Sound.Thousand, 0.1)
    end
    if tonumber(CLOUDCEIL0100)>0 then
      self.radioqueue:Number2Transmission(CLOUDCEIL0100)
      self:Transmission(ATIS.Sound.Hundred, 0.1)
    end
    if self.metric then
      self:Transmission(ATIS.Sound.Meters, 0.1)
    else
      self:Transmission(ATIS.Sound.Feet, 0.1)
    end
  end
  alltext=alltext..";\n"..subtitle
  
  -- Temperature
  if self.TDegF then
    if temperature<0 then
      subtitle=string.format("Temperature -%s °F", TEMPERATURE)
    else
      subtitle=string.format("Temperature %s °F", TEMPERATURE)
    end
  else
    if temperature<0 then
      subtitle=string.format("Temperature -%s °C", TEMPERATURE)
    else
      subtitle=string.format("Temperature %s °C", TEMPERATURE)
    end
  end
  local _TEMPERATURE=subtitle
  self:Transmission(ATIS.Sound.Temperature, 1.0, subtitle)
  if temperature<0 then
    self:Transmission(ATIS.Sound.Minus, 0.2)
  end
  self.radioqueue:Number2Transmission(TEMPERATURE)
  if self.TDegF then
    self:Transmission(ATIS.Sound.DegreesFahrenheit, 0.2)
  else
    self:Transmission(ATIS.Sound.DegreesCelsius, 0.2)
  end
  alltext=alltext..";\n"..subtitle
  
  -- Dew point
  if self.TDegF then
    if dewpoint<0 then
      subtitle=string.format("Dew point -%s °F", DEWPOINT)
    else
      subtitle=string.format("Dew point %s °F", DEWPOINT)
    end
  else
    if dewpoint<0 then
      subtitle=string.format("Dew point -%s °C", DEWPOINT)
    else
      subtitle=string.format("Dew point %s °C", DEWPOINT)
    end
  end
  local _DEWPOINT=subtitle
  self:Transmission(ATIS.Sound.DewPoint, 1.0, subtitle)
  if dewpoint<0 then
    self:Transmission(ATIS.Sound.Minus, 0.2)
  end
  self.radioqueue:Number2Transmission(DEWPOINT)
  if self.TDegF then
    self:Transmission(ATIS.Sound.DegreesFahrenheit, 0.2)
  else
    self:Transmission(ATIS.Sound.DegreesCelsius, 0.2)
  end
  alltext=alltext..";\n"..subtitle

  -- Altimeter QNH/QFE.
  if self.PmmHg then
    if self.qnhonly then
      subtitle=string.format("Altimeter %s.%s mmHg", QNH[1], QNH[2])
    else
      subtitle=string.format("Altimeter QNH %s.%s, QFE %s.%s mmHg", QNH[1], QNH[2], QFE[1], QFE[2])
    end
  else
    if self.metric then
      if self.qnhonly then
        subtitle=string.format("Altimeter %s.%s hPa", QNH[1], QNH[2])
      else
        subtitle=string.format("Altimeter QNH %s.%s, QFE %s.%s hPa", QNH[1], QNH[2], QFE[1], QFE[2])
      end
    else
      if self.qnhonly then
        subtitle=string.format("Altimeter %s.%s inHg", QNH[1], QNH[2])
      else
        subtitle=string.format("Altimeter QNH %s.%s, QFE %s.%s inHg", QNH[1], QNH[2], QFE[1], QFE[2])
      end
    end
  end
  local _ALTIMETER=subtitle
  self:Transmission(ATIS.Sound.Altimeter, 1.0, subtitle)
  if not self.qnhonly then
    self:Transmission(ATIS.Sound.QNH, 0.5)
  end
  self.radioqueue:Number2Transmission(QNH[1])

  if ATIS.ICAOPhraseology[UTILS.GetDCSMap()] then
    self:Transmission(ATIS.Sound.Decimal, 0.2)
  end
  self.radioqueue:Number2Transmission(QNH[2])
  
  if not self.qnhonly then
    self:Transmission(ATIS.Sound.QFE, 0.75)
    self.radioqueue:Number2Transmission(QFE[1])
    if ATIS.ICAOPhraseology[UTILS.GetDCSMap()] then
      self:Transmission(ATIS.Sound.Decimal, 0.2)
    end
    self.radioqueue:Number2Transmission(QFE[2])
  end
  
  if self.PmmHg then
    self:Transmission(ATIS.Sound.MillimetersOfMercury, 0.1)
  else
    if self.metric then
      self:Transmission(ATIS.Sound.HectoPascal, 0.1)
    else
      self:Transmission(ATIS.Sound.InchesOfMercury, 0.1)
    end
  end
  alltext=alltext..";\n"..subtitle

  -- Active runway.
  local subtitle=string.format("Active runway %s", runway)
  if rwyLeft==true then
    subtitle=subtitle.." Left"
  elseif rwyLeft==false then
    subtitle=subtitle.." Right"
  end
  local _RUNACT=subtitle
  self:Transmission(ATIS.Sound.ActiveRunway, 1.0, subtitle)
  self.radioqueue:Number2Transmission(runway)
  if rwyLeft==true then
    self:Transmission(ATIS.Sound.Left, 0.2)
  elseif rwyLeft==false then
    self:Transmission(ATIS.Sound.Right, 0.2)
  end
  alltext=alltext..";\n"..subtitle

  -- Runway length.
  if self.rwylength then

    local runact=self.airbase:GetActiveRunway(self.runwaym2t)
    local length=runact.length
    if not self.metric then
      length=UTILS.MetersToFeet(length)
    end

    -- Length in thousands and hundrets of ft/meters.
    local L1000, L0100=self:_GetThousandsAndHundreds(length)

    -- Subtitle.
    local subtitle=string.format("Runway length %d", length)
    if self.metric then
      subtitle=subtitle.." meters"
    else
      subtitle=subtitle.." feet"
    end

    -- Transmit.
    self:Transmission(ATIS.Sound.RunwayLength, 1.0, subtitle)
    if tonumber(L1000)>0 then
      self.radioqueue:Number2Transmission(L1000)
      self:Transmission(ATIS.Sound.Thousand, 0.1)
    end
    if tonumber(L0100)>0 then
      self.radioqueue:Number2Transmission(L0100)
      self:Transmission(ATIS.Sound.Hundred, 0.1)
    end
    if self.metric then
      self:Transmission(ATIS.Sound.Meters, 0.1)
    else
      self:Transmission(ATIS.Sound.Feet, 0.1)
    end

    alltext=alltext..";\n"..subtitle
  end

  -- Airfield elevation
  if self.elevation then

    local elevation=self.airbase:GetHeight()
    if not self.metric then
      elevation=UTILS.MetersToFeet(elevation)
    end

    -- Length in thousands and hundrets of ft/meters.
    local L1000, L0100=self:_GetThousandsAndHundreds(elevation)

    -- Subtitle.
    local subtitle=string.format("Elevation %d", elevation)
    if self.metric then
      subtitle=subtitle.." meters"
    else
      subtitle=subtitle.." feet"
    end

    -- Transmitt.
    self:Transmission(ATIS.Sound.Elevation, 1.0, subtitle)
    if tonumber(L1000)>0 then
      self.radioqueue:Number2Transmission(L1000)
      self:Transmission(ATIS.Sound.Thousand, 0.1)
    end
    if tonumber(L0100)>0 then
      self.radioqueue:Number2Transmission(L0100)
      self:Transmission(ATIS.Sound.Hundred, 0.1)
    end
    if self.metric then
      self:Transmission(ATIS.Sound.Meters, 0.1)
    else
      self:Transmission(ATIS.Sound.Feet, 0.1)
    end

    alltext=alltext..";\n"..subtitle
  end

  -- Tower frequency.
  if self.towerfrequency then
    local freqs=""
    for i,freq in pairs(self.towerfrequency) do
      freqs=freqs..string.format("%.3f MHz", freq)
      if i<#self.towerfrequency then
        freqs=freqs..", "
      end
    end
    subtitle=string.format("Tower frequency %s", freqs)
    self:Transmission(ATIS.Sound.TowerFrequency, 1.0, subtitle)
    for _,freq in pairs(self.towerfrequency) do
      local f=string.format("%.3f", freq)
      f=UTILS.Split(f, ".")
      self.radioqueue:Number2Transmission(f[1], nil, 0.5)
      if tonumber(f[2])>0 then
        self:Transmission(ATIS.Sound.Decimal, 0.2)
        self.radioqueue:Number2Transmission(f[2])
      end
      self:Transmission(ATIS.Sound.MegaHertz, 0.2)
    end
    
    alltext=alltext..";\n"..subtitle
  end

  -- ILS
  local ils=self:GetNavPoint(self.ils, runway, rwyLeft)
  if ils then
    subtitle=string.format("ILS frequency %.2f MHz", ils.frequency)
    self:Transmission(ATIS.Sound.ILSFrequency, 1.0, subtitle)
    local f=string.format("%.2f", ils.frequency)
    f=UTILS.Split(f, ".")
    self.radioqueue:Number2Transmission(f[1], nil, 0.5)
    if tonumber(f[2])>0 then
      self:Transmission(ATIS.Sound.Decimal, 0.2)
      self.radioqueue:Number2Transmission(f[2])
    end
    self:Transmission(ATIS.Sound.MegaHertz, 0.2)
    
    alltext=alltext..";\n"..subtitle
  end

  -- Outer NDB
  local ndb=self:GetNavPoint(self.ndbouter, runway, rwyLeft)
  if ndb then
    subtitle=string.format("Outer NDB frequency %.2f MHz", ndb.frequency)
    self:Transmission(ATIS.Sound.OuterNDBFrequency, 1.0, subtitle)
    local f=string.format("%.2f", ndb.frequency)
    f=UTILS.Split(f, ".")
    self.radioqueue:Number2Transmission(f[1], nil, 0.5)
    if tonumber(f[2])>0 then
      self:Transmission(ATIS.Sound.Decimal, 0.2)
      self.radioqueue:Number2Transmission(f[2])
    end
    self:Transmission(ATIS.Sound.MegaHertz, 0.2)
    
    alltext=alltext..";\n"..subtitle
  end

  -- Inner NDB
  local ndb=self:GetNavPoint(self.ndbinner, runway, rwyLeft)
  if ndb then
    subtitle=string.format("Inner NDB frequency %.2f MHz", ndb.frequency)
    self:Transmission(ATIS.Sound.InnerNDBFrequency, 1.0, subtitle)
    local f=string.format("%.2f", ndb.frequency)
    f=UTILS.Split(f, ".")
    self.radioqueue:Number2Transmission(f[1], nil, 0.5)
    if tonumber(f[2])>0 then
      self:Transmission(ATIS.Sound.Decimal, 0.2)
      self.radioqueue:Number2Transmission(f[2])
    end
    self:Transmission(ATIS.Sound.MegaHertz, 0.2)
    
    alltext=alltext..";\n"..subtitle
  end

  -- VOR
  if self.vor then
    subtitle=string.format("VOR frequency %.2f MHz", self.vor)
    self:Transmission(ATIS.Sound.VORFrequency, 1.0, subtitle)
    local f=string.format("%.2f", self.vor)
    f=UTILS.Split(f, ".")
    self.radioqueue:Number2Transmission(f[1], nil, 0.5)
    if tonumber(f[2])>0 then
      self:Transmission(ATIS.Sound.Decimal, 0.2)
      self.radioqueue:Number2Transmission(f[2])
    end
    self:Transmission(ATIS.Sound.MegaHertz, 0.2)
    
    alltext=alltext..";\n"..subtitle
  end

  -- TACAN
  if self.tacan then
    subtitle=string.format("TACAN channel %dX", self.tacan)
    self:Transmission(ATIS.Sound.TACANChannel, 1.0, subtitle)
    self.radioqueue:Number2Transmission(tostring(self.tacan), nil, 0.2)
    self.radioqueue:NewTransmission("NATO Alphabet/Xray.ogg", 0.75, self.soundpath, nil, 0.2)
    
    alltext=alltext..";\n"..subtitle
  end

  -- RSBN
  if self.rsbn then
    subtitle=string.format("RSBN channel %d", self.rsbn)
    self:Transmission(ATIS.Sound.RSBNChannel, 1.0, subtitle)
    self.radioqueue:Number2Transmission(tostring(self.rsbn), nil, 0.2)
    
    alltext=alltext..";\n"..subtitle
  end

  -- PRMG
  local ndb=self:GetNavPoint(self.prmg, runway, rwyLeft)
  if ndb then
    subtitle=string.format("PRMG channel %d", ndb.frequency)
    self:Transmission(ATIS.Sound.PRMGChannel, 1.0, subtitle)
    self.radioqueue:Number2Transmission(tostring(ndb.frequency), nil, 0.5)
    
    alltext=alltext..";\n"..subtitle
  end
  
  -- Advice on initial...
  subtitle=string.format("Advise on initial contact, you have information %s", NATO)
  self:Transmission(ATIS.Sound.AdviceOnInitial, 0.5, subtitle)
  self.radioqueue:NewTransmission(string.format("NATO Alphabet/%s.ogg", NATO), 0.75, self.soundpath)
  
  alltext=alltext..";\n"..subtitle
  
  -- Report ATIS text.
  self:Report(alltext)

  -- Update F10 marker.
  if self.usemarker then
    self:UpdateMarker(_INFORMATION, _RUNACT, _WIND, _ALTIMETER, _TEMPERATURE)
  end

end

--- Text report of ATIS information. Information delimitor is a semicolon ";" and a line break "\n".
-- @param #ATIS self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #string Text Report text.
function ATIS:onafterReport(From, Event, To, Text)
  self:T(self.lid..string.format("Report:\n%s", Text))
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Update F10 map marker.
-- @param #ATIS self
-- @param #string information Information tag text.
-- @param #string runact Active runway text.
-- @param #string wind Wind text.
-- @param #string altimeter Altimeter text.
-- @param #string temperature Temperature text.
-- @return #number Marker ID.
function ATIS:UpdateMarker(information, runact, wind, altimeter, temperature)

  if self.markerid then
    self.airbase:GetCoordinate():RemoveMark(self.markerid)
  end

  local text=string.format("ATIS on %.3f %s, %s:\n", self.frequency, UTILS.GetModulationName(self.modulation), tostring(information))
  text=text..string.format("%s\n", tostring(runact))
  text=text..string.format("%s\n", tostring(wind))
  text=text..string.format("%s\n", tostring(altimeter))
  text=text..string.format("%s",   tostring(temperature))
  -- More info is not displayed on the marker!

  -- Place new mark
  self.markerid=self.airbase:GetCoordinate():MarkToAll(text, true)

  return self.markerid
end

--- Get active runway runway.
-- @param #ATIS self
-- @return #string Active runway, e.g. "31" for 310 deg.
-- @return #boolean Use Left=true, Right=false, or nil.
function ATIS:GetActiveRunway()

  local coord=self.airbase:GetCoordinate()
  local height=coord:GetLandHeight()

  -- Get wind direction and speed in m/s.
  local windFrom, windSpeed=coord:GetWind(height+10)

  -- Get active runway data based on wind direction.
  local runact=self.airbase:GetActiveRunway(self.runwaym2t)

  -- Active runway "31".
  local runway=self:GetMagneticRunway(windFrom) or runact.idx

  -- Left or right in case there are two runways with the same heading.
  local rwyLeft=nil

  -- Check if user explicitly specified a runway.
  if self.activerunway then

    -- Get explicit runway heading if specified.
    local runwayno=self:GetRunwayWithoutLR(self.activerunway)
    if runwayno~="" then
      runway=runwayno
    end

    -- Was "L"eft or "R"ight given?
    rwyLeft=self:GetRunwayLR(self.activerunway)
  end

  return runway, rwyLeft
end

--- Get runway from user supplied magnetic heading.
-- @param #ATIS self
-- @param #number windfrom Wind direction (from) in degrees.
-- @return #string Runway magnetic heading divided by ten (and rounded). Eg, "13" for 130°.
function ATIS:GetMagneticRunway(windfrom)

  local diffmin=nil
  local runway=nil
  for _,heading in pairs(self.runwaymag) do

    local hdg=self:GetRunwayWithoutLR(heading)

    local diff=UTILS.HdgDiff(windfrom, tonumber(hdg)*10)
    if diffmin==nil or diff<diffmin then
      diffmin=diff
      runway=hdg
    end

  end

  return runway
end

--- Get nav aid data.
-- @param #ATIS self
-- @param #table navpoints Nav points data table.
-- @param #string runway (Active) runway, *e.g.* "31".
-- @param #boolean left If *true*, left runway, if *false, right, else does not matter.
-- @return #ATIS.NavPoint Nav point data table.
function ATIS:GetNavPoint(navpoints, runway, left)

  -- Loop over all defined nav aids.
  for _,_nav in pairs(navpoints or {}) do
    local nav=_nav --#ATIS.NavPoint

    if nav.runway==nil then
      -- No explicit runway data specified ==> data is valid for all runways.
      return nav
    else

      local navy=tonumber(self:GetRunwayWithoutLR(nav.runway))*10
      local rwyy=tonumber(self:GetRunwayWithoutLR(runway))*10

      local navL=self:GetRunwayLR(nav.runway)
      local hdgD=UTILS.HdgDiff(navy,rwyy)

      if hdgD<=15 then --We allow an error of +-15° here.
        if navL==nil or (navL==true and left==true) or (navL==false and left==false) then
          return nav
        end
      end
    end
  end

  return nil
end

--- Get runway heading without left or right info.
-- @param #ATIS self
-- @param #string runway Runway heading, *e.g.* "31L".
-- @return #string Runway heading without left or right, *e.g.* "31".
function ATIS:GetRunwayWithoutLR(runway)
  local rwywo=runway:gsub("%D+", "")
  --self:I(string.format("FF runway=%s ==> rwywo=%s", runway, rwywo))
  return rwywo
end

--- Get info if left or right runway is active.
-- @param #ATIS self
-- @param #string runway Runway heading, *e.g.* "31L".
-- @return #boolean If *true*, left runway is active. If *false*, right runway. If *nil*, neither applies.
function ATIS:GetRunwayLR(runway)

  -- Get left/right if specified.
  local rwyL=runway:lower():find("l")
  local rwyR=runway:lower():find("r")

  if rwyL then
    return true
  elseif rwyR then
    return false
  else
    return nil
  end

end

--- Transmission via RADIOQUEUE.
-- @param #ATIS self
-- @param #ATIS.Soundfile sound ATIS sound object.
-- @param #number interval Interval in seconds after the last transmission finished.
-- @param #string subtitle Subtitle of the transmission.
-- @param #string path Path to sound file. Default self.soundpath.
function ATIS:Transmission(sound, interval, subtitle, path)
  self.radioqueue:NewTransmission(sound.filename, sound.duration, path or self.soundpath, nil, interval, subtitle, self.subduration)
end

--- Play all audio files.
-- @param #ATIS self
function ATIS:SoundCheck()

  for _,_sound in pairs(ATIS.Sound) do
    local sound=_sound --#ATIS.Soundfile
    local subtitle=string.format("Playing sound file %s, duration %.2f sec", sound.filename, sound.duration)
    self:Transmission(sound, nil, subtitle)
    MESSAGE:New(subtitle, 5, "ATIS"):ToAll()
  end

end

--- Get weather of this mission from env.mission.weather variable.
-- @param #ATIS self
-- @return #table Clouds table which has entries "thickness", "density", "base", "iprecptns".
-- @return #number Visibility distance in meters.
-- @return #number Ground turbulence in m/s.
-- @return #table Fog table, which has entries "thickness", "visibility" or nil if fog is disabled in the mission.
-- @return #number Dust density or nil if dust is disabled in the mission.
-- @return #boolean static If true, static weather is used. If false, dynamic weather is used.
function ATIS:GetMissionWeather()

  -- Weather data from mission file.
  local weather=env.mission.weather

  -- Clouds
  --[[
  ["clouds"] =
  {
      ["thickness"] = 430,
      ["density"] = 7,
      ["base"] = 0,
      ["iprecptns"] = 1,
  }, -- end of ["clouds"]
  ]]
  local clouds=weather.clouds

  -- 0=static, 1=dynamic
  local static=weather.atmosphere_type==0

  -- Visibilty distance in meters.
  local visibility=weather.visibility.distance

  -- Ground turbulence.
  local turbulence=weather.groundTurbulence

  -- Dust
  --[[
  ["enable_dust"] = false,
  ["dust_density"] = 0,
  ]]
  local dust=nil
  if weather.enable_dust==true then
    dust=weather.dust_density
  end

  -- Fog
  --[[
  ["enable_fog"] = false,
  ["fog"] =
  {
      ["thickness"] = 0,
      ["visibility"] = 25,
  }, -- end of ["fog"]
  ]]
  local fog=nil
  if weather.enable_fog==true then
    fog=weather.fog
  end

  self:T("FF weather:")
  self:T({clouds=clouds})
  self:T({visibility=visibility})
  self:T({turbulence=turbulence})
  self:T({fog=fog})
  self:T({dust=dust})
  self:T({static=static})
  return clouds, visibility, turbulence, fog, dust, static
end


--- Get thousands of a number.
-- @param #ATIS self
-- @param #number n Number, *e.g.* 4359.
-- @return #string Thousands of n, *e.g.* "4" for 4359.
-- @return #string Hundreds of n, *e.g.* "4" for 4359 because its rounded.
function ATIS:_GetThousandsAndHundreds(n)

  local N=UTILS.Round(n/1000, 1)

  local S=UTILS.Split(string.format("%.1f", N), ".")

  local t=S[1]
  local h=S[2]

  return t, h
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
