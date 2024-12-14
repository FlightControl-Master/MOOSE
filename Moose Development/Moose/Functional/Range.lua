--- **Functional** - Range Practice.
--
-- ===
--
-- The RANGE class enables easy set up of bombing and strafing ranges within DCS World.
--
-- Implementation is based on the [Simple Range Script](https://forums.eagle.ru/showthread.php?t=157991) by Ciribob, which itself was motivated
-- by a script by SNAFU [see here](https://forums.eagle.ru/showthread.php?t=109174).
--
-- [476th - Air Weapons Range Objects mod](https://www.476vfightergroup.com/downloads.php?do=download&downloadid=482) is highly recommended for this class.
--
-- **Main Features:**
--
--   * Impact points of bombs, rockets and missiles are recorded and distance to closest range target is measured and reported to the player.
--   * Number of hits on strafing passes are counted and reported. Also the percentage of hits w.r.t fired shots is evaluated.
--   * Results of all bombing and strafing runs are stored and top 10 results can be displayed.
--   * Range targets can be marked by smoke.
--   * Range can be illuminated by illumination bombs for night missions.
--   * Bomb, rocket and missile impact points can be marked by smoke.
--   * Direct hits on targets can trigger flares.
--   * Smoke and flare colors can be adjusted for each player via radio menu.
--   * Range information and weather at the range can be obtained via radio menu.
--   * Persistence: Bombing range results can be saved to disk and loaded the next time the mission is started.
--   * Range control voice overs (>40) for hit assessment.
--
-- ===
--
-- ## Youtube Videos:
--
--    * [MOOSE YouTube Channel](https://www.youtube.com/channel/UCjrA9j5LQoWsG4SpS8i79Qg)
--    * [MOOSE - On the Range - Demonstration Video](https://www.youtube.com/watch?v=kIXcxNB9_3M)
--
-- ===
--
-- ## Missions:
--
--    * [MAR - On the Range - MOOSE - SC](https://www.digitalcombatsimulator.com/en/files/3317765/) by shagrat
--
-- ===
--
-- ## Sound files: [MOOSE Sound Files](https://github.com/FlightControl-Master/MOOSE_SOUND/releases)
--
-- ===
--
-- ### Author: **funkyfranky**
--
-- ### Contributions: FlightControl, Ciribob
-- ### SRS Additions: Applevangelist
--
-- ===
-- @module Functional.Range
-- @image Range.JPG

--- RANGE class
-- @type RANGE
-- @field #string ClassName Name of the Class.
-- @field #boolean Debug If true, debug info is sent as messages on the screen.
-- @field #boolean verbose Verbosity level. Higher means more output to DCS log file.
-- @field #string lid String id of range for output in DCS log.
-- @field #string rangename Name of the range.
-- @field Core.Point#COORDINATE location Coordinate of the range location.
-- @field #number rangeradius Radius of range defining its total size for e.g. smoking bomb impact points and sending radio messages. Default 5 km.
-- @field Core.Zone#ZONE rangezone MOOSE zone object of the range. For example, no bomb impacts are smoked if bombs fall outside of the range zone.
-- @field #table strafeTargets Table of strafing targets.
-- @field #table bombingTargets Table of targets to bomb.
-- @field #number nbombtargets Number of bombing targets.
-- @field #number nstrafetargets Number of strafing targets.
-- @field #boolean messages Globally enable/disable all messages to players.
-- @field #table MenuAddedTo Table for monitoring which players already got an F10 menu.
-- @field #table planes Table for administration.
-- @field #table strafeStatus Table containing the current strafing target a player as assigned to.
-- @field #table strafePlayerResults Table containing the strafing results of each player.
-- @field #table bombPlayerResults Table containing the bombing results of each player.
-- @field #table PlayerSettings Individual player settings.
-- @field #number dtBombtrack Time step [sec] used for tracking released bomb/rocket positions. Default 0.005 seconds.
-- @field #number BombtrackThreshold Bombs/rockets/missiles are only tracked if player-range distance is smaller than this threshold [m]. Default 25000 m.
-- @field #number Tmsg Time [sec] messages to players are displayed. Default 30 sec.
-- @field #string examinergroupname Name of the examiner group which should get all messages.
-- @field #boolean examinerexclusive If true, only the examiner gets messages. If false, clients and examiner get messages.
-- @field #number strafemaxalt Maximum altitude in meters AGL for registering for a strafe run. Default is 914 m = 3000 ft.
-- @field #number ndisplayresult Number of (player) results that a displayed. Default is 10.
-- @field Utilities.Utils#SMOKECOLOR BombSmokeColor Color id used for smoking bomb targets.
-- @field Utilities.Utils#SMOKECOLOR StrafeSmokeColor Color id used to smoke strafe targets.
-- @field Utilities.Utils#SMOKECOLOR StrafePitSmokeColor Color id used to smoke strafe pit approach boxes.
-- @field #number illuminationminalt Minimum altitude in meters AGL at which illumination bombs are fired. Default is 500 m.
-- @field #number illuminationmaxalt Maximum altitude in meters AGL at which illumination bombs are fired. Default is 1000 m.
-- @field #number scorebombdistance Distance from closest target up to which bomb hits are counted. Default 1000 m.
-- @field #number TdelaySmoke Time delay in seconds between impact of bomb and starting the smoke. Default 3 seconds.
-- @field #boolean trackbombs If true (default), all bomb types are tracked and impact point to closest bombing target is evaluated.
-- @field #boolean trackrockets If true (default), all rocket types are tracked and impact point to closest bombing target is evaluated.
-- @field #boolean trackmissiles If true (default), all missile types are tracked and impact point to closest bombing target is evaluated.
-- @field #boolean defaultsmokebomb If true, initialize player settings to smoke bomb.
-- @field #boolean autosave If true, automatically save results every X seconds.
-- @field #number instructorfreq Frequency on which the range control transmitts.
-- @field Sound.RadioQueue#RADIOQUEUE instructor Instructor radio queue.
-- @field #number rangecontrolfreq Frequency on which the range control transmitts.
-- @field Sound.RadioQueue#RADIOQUEUE rangecontrol Range control radio queue.
-- @field #string rangecontrolrelayname Name of relay unit.
-- @field #string instructorrelayname Name of relay unit.
-- @field #string soundpath Path inside miz file where the sound files are located. Default is "Range Soundfiles/".
-- @field #boolean targetsheet If true, players can save their target sheets. Rangeboss will not work if targetsheets do not save.
-- @field #string targetpath Path where to save the target sheets.
-- @field #string targetprefix File prefix for target sheet files.
-- @field Sound.SRS#MSRS controlmsrs SRS wrapper for range controller.
-- @field Sound.SRS#MSRSQUEUE controlsrsQ SRS queue for range controller.
-- @field Sound.SRS#MSRS instructmsrs SRS wrapper for range instructor.
-- @field Sound.SRS#MSRSQUEUE instructsrsQ SRS queue for range instructor.
-- @field #number Coalition Coalition side for the menu, if any.
-- @field Core.Menu#MENU_MISSION menuF10root Specific user defined root F10 menu.
-- @extends Core.Fsm#FSM

--- *Don't only practice your art, but force your way into its secrets; art deserves that, for it and knowledge can raise man to the Divine.* - Ludwig van Beethoven
--
-- ===
--
-- ![Banner Image](..\Presentations\RANGE\RANGE_Main.png)
--
-- # The Range Concept
--
-- The RANGE class enables a mission designer to easily set up practice ranges in DCS. A new RANGE object can be created with the @{#RANGE.New}(*rangename*) contructor.
-- The parameter *rangename* defines the name of the range. It has to be unique since this is also the name displayed in the radio menu.
--
-- Generally, a range consists of strafe pits and bombing targets. For strafe pits the number of hits for each pass is counted and tabulated.
-- For bombing targets, the distance from the impact point of the bomb, rocket or missile to the closest range target is measured and tabulated.
-- Each player can display his best results via a function in the radio menu or see the best best results from all players.
--
-- When all targets have been defined in the script, the range is started by the @{#RANGE.Start}() command.
--
-- **IMPORTANT**
--
-- Due to a DCS bug, it is not possible to directly monitor when a player enters a plane. So in a mission with client slots, it is vital that
-- a player first enters as spectator or hits ESC twice and **after that** jumps into the slot of his aircraft!
-- If that is not done, the script is not started correctly. This can be checked by looking at the radio menues. If the mission was entered correctly,
-- there should be an "On the Range" menu items in the "F10. Other..." menu.
--
-- # Strafe Pits
--
-- Each strafe pit can consist of multiple targets. Often one finds two or three strafe targets next to each other.
--
-- A strafe pit can be added to the range by the @{#RANGE.AddStrafePit}(*targetnames, boxlength, boxwidth, heading, inverseheading, goodpass, foulline*) function.
--
-- * The first parameter *targetnames* defines the target or targets. This can be a single item or a Table with the name(s) of @{Wrapper.Unit} or @{Wrapper.Static} objects defined in the mission editor.
-- * In order to perform a valid pass on the strafe pit, the pilot has to begin his run from the correct direction. Therefore, an "approach box" is defined in front
--   of the strafe targets. The parameters *boxlength* and *boxwidth* define the size of the box in meters, while the *heading* parameter defines the heading of the box FROM the target.
--   For example, if heading 120 is set, the approach box will start FROM the target and extend outwards on heading 120. A strafe run approach must then be flown apx. heading 300 TOWARDS the target.
--   If the parameter *heading* is passed as **nil**, the heading is automatically taken from the heading set in the ME for the first target unit.
-- * The parameter *inverseheading* turns the heading around by 180 degrees. This is useful when the default heading of strafe target units point in the wrong/opposite direction.
-- * The parameter *goodpass* defines the number of hits a pilot has to achieve during a run to be judged as a "good" pass.
-- * The last parameter *foulline* sets the distance from the pit targets to the foul line. Hit from closer than this line are not counted!
--
-- Another function to add a strafe pit is @{#RANGE.AddStrafePitGroup}(*group, boxlength, boxwidth, heading, inverseheading, goodpass, foulline*). Here,
-- the first parameter *group* is a MOOSE @{Wrapper.Group} object and **all** units in this group define **one** strafe pit.
--
-- Finally, a valid approach has to be performed below a certain maximum altitude. The default is 914 meters (3000 ft) AGL. This is a parameter valid for all
-- strafing pits of the range and can be adjusted by the @{#RANGE.SetMaxStrafeAlt}(maxalt) function.
--
-- # Bombing targets
--
-- One ore multiple bombing targets can be added to the range by the @{#RANGE.AddBombingTargets}(targetnames, goodhitrange, randommove) function.
--
-- * The first parameter *targetnames* defines the target or targets. This can be a single item or a Table with the name(s) of @{Wrapper.Unit} or @{Wrapper.Static} objects defined in the mission editor.
-- * The (optional) parameter *goodhitrange* specifies the radius in metres around the target within which a bomb/rocket hit is considered to be "good".
-- * If final (optional) parameter "*randommove*" can be enabled to create moving targets. If this parameter is set to true, the units of this bombing target will randomly move within the range zone.
--   Note that there might be quirks since DCS units can get stuck in buildings etc. So it might be safer to manually define a route for the units in the mission editor if moving targets are desired.
--
-- ## Adding Groups
--
-- Another possibility to add bombing targets is the @{#RANGE.AddBombingTargetGroup}(*group, goodhitrange, randommove*) function. Here the parameter *group* is a MOOSE @{Wrapper.Group} object
-- and **all** units in this group are defined as bombing targets.
--
-- ## Specifying Coordinates
--
-- It is also possible to specify coordinates rather than unit or static objects as bombing target locations. This has the advantage, that even when the unit/static object is dead, the specified
-- coordinate will still be a valid impact point. This can be done via the @{#RANGE.AddBombingTargetCoordinate}(*coord*, *name*, *goodhitrange*) function.
--
-- # Fine Tuning
--
-- Many range parameters have good default values. However, the mission designer can change these settings easily with the supplied user functions:
--
-- * @{#RANGE.SetMaxStrafeAlt}() sets the max altitude for valid strafing runs.
-- * @{#RANGE.SetMessageTimeDuration}() sets the duration how long (most) messages are displayed.
-- * @{#RANGE.SetDisplayedMaxPlayerResults}() sets the number of results displayed.
-- * @{#RANGE.SetRangeRadius}() defines the total range area.
-- * @{#RANGE.SetBombTargetSmokeColor}() sets the color used to smoke bombing targets.
-- * @{#RANGE.SetStrafeTargetSmokeColor}() sets the color used to smoke strafe targets.
-- * @{#RANGE.SetStrafePitSmokeColor}() sets the color used to smoke strafe pit approach boxes.
-- * @{#RANGE.SetSmokeTimeDelay}() sets the time delay between smoking bomb/rocket impact points after impact.
-- * @{#RANGE.TrackBombsON}() or @{#RANGE.TrackBombsOFF}() can be used to enable/disable tracking and evaluating of all bomb types a player fires.
-- * @{#RANGE.TrackRocketsON}() or @{#RANGE.TrackRocketsOFF}() can be used to enable/disable tracking and evaluating of all rocket types a player fires.
-- * @{#RANGE.TrackMissilesON}() or @{#RANGE.TrackMissilesOFF}() can be used to enable/disable tracking and evaluating of all missile types a player fires.
--
-- # Radio Menu
--
-- Each range gets a radio menu with various submenus where each player can adjust his individual settings or request information about the range or his scores.
--
-- The main range menu can be found at "F10. Other..." --> "F*X*. On the Range..." --> "F1. <Range Name>...".
--
-- The range menu contains the following submenus:
--
-- ![Banner Image](..\Presentations\RANGE\Menu_Main.png)
--
-- * "F1. Statistics...": Range results of all players and personal stats.
-- * "F2. Mark Targets": Mark range targets by smoke or flares.
-- * "F3. My Settings" Personal settings.
-- * "F4. Range Info": Information about the range, such as bearing and range.
--
-- ## F1 Statistics
--
-- ![Banner Image](..\Presentations\RANGE\Menu_Stats.png)
--
-- ## F2 Mark Targets
--
-- ![Banner Image](..\Presentations\RANGE\Menu_Stats.png)
--
-- ## F3 My Settings
--
-- ![Banner Image](..\Presentations\RANGE\Menu_MySettings.png)
--
-- ## F4 Range Info
--
-- ![Banner Image](..\Presentations\RANGE\Menu_RangeInfo.png)
--
-- # Voice Overs
--
-- Voice over sound files can be downloaded from the Moose Discord. Check the pinned messages in the *#func-range* channel.
--
-- Instructor radio will inform players when they enter or exit the range zone and provide the radio frequency of the range control for hit assessment.
-- This can be enabled via the @{#RANGE.SetInstructorRadio}(*frequency*) functions, where *frequency* is the AM frequency in MHz.
--
-- The range control can be enabled via the @{#RANGE.SetRangeControl}(*frequency*) functions, where *frequency* is the AM frequency in MHz.
--
-- By default, the sound files are placed in the "Range Soundfiles/" folder inside the mission (.miz) file. Another folder can be specified via the @{#RANGE.SetSoundfilesPath}(*path*) function.
--
-- ## Voice output via SRS
--
-- Alternatively, the voice output can be fully done via SRS, **no sound file additions needed**. Set up SRS with @{#RANGE.SetSRS}().
-- Range control and instructor frequencies and voices can then be set via @{#RANGE.SetSRSRangeControl}() and @{#RANGE.SetSRSRangeInstructor}().
--
-- # Persistence
--
-- To automatically save bombing results to disk, use the @{#RANGE.SetAutosave}() function. Bombing results will be saved as csv file in your "Saved Games\DCS.openbeta\Logs" directory.
-- Each range has a separate file, which is named "RANGE-<*RangeName*>_BombingResults.csv".
--
-- The next time you start the mission, these results are also automatically loaded.
--
-- Strafing results are currently **not** saved.
--
-- # FSM Events
--
-- This class creates additional events that can be used by mission designers for custom reactions
--
-- * `EnterRange` when a player enters a range zone. See @{#RANGE.OnAfterEnterRange}
-- * `ExitRange`  when a player leaves a range zone. See @{#RANGE.OnAfterExitRange}
-- * `Impact` on impact of a player's weapon on a bombing target. See @{#RANGE.OnAfterImpact}
-- * `RollingIn` when a player rolls in on a strafing target. See @{#RANGE.OnAfterRollingIn}
-- * `StrafeResult` when a player finishes a strafing run. See @{#RANGE.OnAfterStrafeResult}
--
-- # Examples
--
-- ## Goldwater Range
--
-- This example shows hot to set up the [Barry M. Goldwater range](https://en.wikipedia.org/wiki/Barry_M._Goldwater_Air_Force_Range).
-- It consists of two strafe pits each has two targets plus three bombing targets.
--
--      -- Strafe pits. Each pit can consist of multiple targets. Here we have two pits and each of the pits has two targets.
--      -- These are names of the corresponding units defined in the ME.
--      local strafepit_left={"GWR Strafe Pit Left 1", "GWR Strafe Pit Left 2"}
--      local strafepit_right={"GWR Strafe Pit Right 1", "GWR Strafe Pit Right 2"}
--
--      -- Table of bombing target names. Again these are the names of the corresponding units as defined in the ME.
--      local bombtargets={"GWR Bomb Target Circle Left", "GWR Bomb Target Circle Right", "GWR Bomb Target Hard"}
--
--      -- Create a range object.
--      GoldwaterRange=RANGE:New("Goldwater Range")
--
--      -- Distance between strafe target and foul line. You have to specify the names of the unit or static objects.
--      -- Note that this could also be done manually by simply measuring the distance between the target and the foul line in the ME.
--      GoldwaterRange:GetFoullineDistance("GWR Strafe Pit Left 1", "GWR Foul Line Left")
--
--      -- Add strafe pits. Each pit (left and right) consists of two targets. Where "nil" is used as input, the default value is used.
--      GoldwaterRange:AddStrafePit(strafepit_left, 3000, 300, nil, true, 30, 500)
--      GoldwaterRange:AddStrafePit(strafepit_right, nil, nil, nil, true, nil, 500)
--
--      -- Add bombing targets. A good hit is if the bomb falls less then 50 m from the target.
--      GoldwaterRange:AddBombingTargets(bombtargets, 50)
--
--      -- Start range.
--      GoldwaterRange:Start()
--
-- The [476th - Air Weapons Range Objects mod](http://www.476vfightergroup.com/downloads.php?do=file&id=287) is (implicitly) used in this example.
--
--
-- # Debugging
--
-- In case you have problems, it is always a good idea to have a look at your DCS log file. You find it in your "Saved Games" folder, so for example in
--      C:\Users\<yourname>\Saved Games\DCS\Logs\dcs.log
-- All output concerning the RANGE class should have the string "RANGE" in the corresponding line.
--
-- The verbosity of the output can be increased by adding the following lines to your script:
--
--      BASE:TraceOnOff(true)
--      BASE:TraceLevel(1)
--      BASE:TraceClass("RANGE")
--
-- To get even more output you can increase the trace level to 2 or even 3, c.f. @{Core.Base#BASE} for more details.
--
-- The function @{#RANGE.DebugON}() can be used to send messages on screen. It also smokes all defined strafe and bombing targets, the strafe pit approach boxes and the range zone.
--
-- Note that it can happen that the RANGE radio menu is not shown. Check that the range object is defined as a **global** variable rather than a local one.
-- The could avoid the lua garbage collection to accidentally/falsely deallocate the RANGE objects.
--
-- @field #RANGE
RANGE = {
  ClassName = "RANGE",
  Debug = false,
  verbose = 0,
  id = nil,
  rangename = nil,
  location = nil,
  messages = true,
  rangeradius = 5000,
  rangezone = nil,
  strafeTargets = {},
  bombingTargets = {},
  nbombtargets = 0,
  nstrafetargets = 0,
  MenuAddedTo = {},
  planes = {},
  strafeStatus = {},
  strafePlayerResults = {},
  bombPlayerResults = {},
  PlayerSettings = {},
  dtBombtrack = 0.005,
  BombtrackThreshold = 25000,
  Tmsg = 30,
  examinergroupname = nil,
  examinerexclusive = nil,
  strafemaxalt = 914,
  ndisplayresult = 10,
  BombSmokeColor = SMOKECOLOR.Red,
  StrafeSmokeColor = SMOKECOLOR.Green,
  StrafePitSmokeColor = SMOKECOLOR.White,
  illuminationminalt = 500,
  illuminationmaxalt = 1000,
  scorebombdistance = 1000,
  TdelaySmoke = 3.0,
  trackbombs = true,
  trackrockets = true,
  trackmissiles = true,
  defaultsmokebomb = true,
  autosave = false,
  instructorfreq = nil,
  instructor = nil,
  rangecontrolfreq = nil,
  rangecontrol = nil,
  soundpath = "Range Soundfiles/",
  targetsheet = nil,
  targetpath = nil,
  targetprefix = nil,
  Coalition = nil,
  }

--- Default range parameters.
-- @type RANGE.Defaults
-- @param #number goodhitrange Radius for good hits in meters.
-- @param #number strafemaxalt Max altitude in meters for players to enter a strafing pit.
-- @param #number dtBombtrack Timer interval in seconds.
-- @param #number Tmsg Message display time in seconds.
-- @param #number ndisplayresults Number of results to display.
-- @param #number rangeradius Radius of range in meters.
-- @param #number TdelaySmoke Time delay in seconds before smoke is triggered.
-- @param #number boxlength Length of strafe pit box in meters.
-- @param #number boxwidth Width of strafe pit box in meters.
-- @param #number goodpass Number of hits for a good strafing pit pass.
-- @param #number foulline Distance of foul line in meters.
RANGE.Defaults = {
  goodhitrange = 25,
  strafemaxalt = 914,
  dtBombtrack = 0.005,
  Tmsg = 30,
  ndisplayresult = 10,
  rangeradius = 5000,
  TdelaySmoke = 3.0,
  boxlength = 3000,
  boxwidth = 300,
  goodpass = 20,
  foulline = 610
}

--- Target type, i.e. unit, static, or coordinate.
-- @type RANGE.TargetType
-- @field #string UNIT Target is a unitobject.
-- @field #string STATIC Target is a static object.
-- @field #string COORD Target is a coordinate.
-- @field #string SCENERY Target is a scenery object.
RANGE.TargetType = {
  UNIT = "Unit",
  STATIC = "Static",
  COORD = "Coordinate",
  SCENERY = "Scenery"
}

--- Player settings.
-- @type RANGE.PlayerData
-- @field #boolean smokebombimpact Smoke bomb impact points.
-- @field #boolean flaredirecthits Flare when player directly hits a target.
-- @field #number smokecolor Color of smoke.
-- @field #number flarecolor Color of flares.
-- @field #boolean messages Display info messages.
-- @field Wrapper.Client#CLIENT client Client object of player.
-- @field #string unitname Name of player aircraft unit.
-- @field Wrapper.Unit#UNIT unit Player unit.
-- @field #string playername Name of player.
-- @field #string airframe Aircraft type name.
-- @field #boolean inzone If true, player is inside the range zone.
-- @field #boolean targeton Target on.

--- Bomb target data.
-- @type RANGE.BombTarget
-- @field #string name Name of unit.
-- @field Wrapper.Unit#UNIT target Target unit.
-- @field Core.Point#COORDINATE coordinate Coordinate of the target.
-- @field #number goodhitrange Range in meters for a good hit.
-- @field #boolean move If true, unit move randomly.
-- @field #number speed Speed of unit.
-- @field #RANGE.TargetType type Type of target.

--- Strafe target data.
-- @type RANGE.StrafeTarget
-- @field #string name Name of the unit.
-- @field Core.Zone#ZONE_POLYGON polygon Polygon zone.
-- @field Core.Point#COORDINATE coordinate Center coordinate of the pit.
-- @field #number goodPass Number of hits for a good pass.
-- @field #table targets Table of target units.
-- @field #number foulline Foul line
-- @field #number smokepoints Number of smoke points.
-- @field #number heading Heading of pit.

--- Strafe status for player.
-- @type RANGE.StrafeStatus
-- @field #number hits Number of hits on target.
-- @field #number time Number of times.
-- @field #number ammo Amount of ammo.
-- @field #boolean pastfoulline If `true`, player passed foul line. Invalid pass.
-- @field #RANGE.StrafeTarget zone Strafe target.

--- Bomb target result.
-- @type RANGE.BombResult
-- @field #string name Name of closest target.
-- @field #number distance Distance in meters.
-- @field #number radial Radial in degrees.
-- @field #string weapon Name of the weapon.
-- @field #string quality Hit quality.
-- @field #string player Player name.
-- @field #string airframe Aircraft type of player.
-- @field #number time Time via timer.getAbsTime() in seconds of impact.
-- @field #string date OS date.
-- @field #number attackHdg Attack heading in degrees.
-- @field #number attackVel Attack velocity in knots.
-- @field #number attackAlt Attack altitude in feet.
-- @field #string clock Time of the run.
-- @field #string rangename Name of the range.

--- Strafe result.
-- @type RANGE.StrafeResult
-- @field #string player Player name.
-- @field #string airframe Aircraft type of player.
-- @field #number time Time via timer.getAbsTime() in seconds of impact.
-- @field #string date OS date.
-- @field #string name Name of the target pit.
-- @field #number roundsFired Number of rounds fired.
-- @field #number roundsHit Number of rounds that hit the target.
-- @field #number strafeAccuracy Accuracy of the run in percent.
-- @field #string clock Time of the run.
-- @field #string rangename Name of the range.
-- @field #boolean invalid Invalid pass.

--- Strafe result.
-- @type RANGE.StrafeResult
-- @field #string player Player name.
-- @field #string airframe Aircraft type of player.
-- @field #number time Time via timer.getAbsTime() in seconds of impact.
-- @field #string date OS date.

--- Sound file data.
-- @type RANGE.Soundfile
-- @field #string filename Name of the file
-- @field #number duration Duration in seconds.

--- Sound files.
-- @type RANGE.Sound
-- @field #RANGE.Soundfile RC0
-- @field #RANGE.Soundfile RC1
-- @field #RANGE.Soundfile RC2
-- @field #RANGE.Soundfile RC3
-- @field #RANGE.Soundfile RC4
-- @field #RANGE.Soundfile RC5
-- @field #RANGE.Soundfile RC6
-- @field #RANGE.Soundfile RC7
-- @field #RANGE.Soundfile RC8
-- @field #RANGE.Soundfile RC9
-- @field #RANGE.Soundfile RCAccuracy
-- @field #RANGE.Soundfile RCDegrees
-- @field #RANGE.Soundfile RCExcellentHit
-- @field #RANGE.Soundfile RCExcellentPass
-- @field #RANGE.Soundfile RCFeet
-- @field #RANGE.Soundfile RCFor
-- @field #RANGE.Soundfile RCGoodHit
-- @field #RANGE.Soundfile RCGoodPass
-- @field #RANGE.Soundfile RCHitsOnTarget
-- @field #RANGE.Soundfile RCImpact
-- @field #RANGE.Soundfile RCIneffectiveHit
-- @field #RANGE.Soundfile RCIneffectivePass
-- @field #RANGE.Soundfile RCInvalidHit
-- @field #RANGE.Soundfile RCLeftStrafePitTooQuickly
-- @field #RANGE.Soundfile RCPercent
-- @field #RANGE.Soundfile RCPoorHit
-- @field #RANGE.Soundfile RCPoorPass
-- @field #RANGE.Soundfile RCRollingInOnStrafeTarget
-- @field #RANGE.Soundfile RCTotalRoundsFired
-- @field #RANGE.Soundfile RCWeaponImpactedTooFar
-- @field #RANGE.Soundfile IR0
-- @field #RANGE.Soundfile IR1
-- @field #RANGE.Soundfile IR2
-- @field #RANGE.Soundfile IR3
-- @field #RANGE.Soundfile IR4
-- @field #RANGE.Soundfile IR5
-- @field #RANGE.Soundfile IR6
-- @field #RANGE.Soundfile IR7
-- @field #RANGE.Soundfile IR8
-- @field #RANGE.Soundfile IR9
-- @field #RANGE.Soundfile IRDecimal
-- @field #RANGE.Soundfile IRMegaHertz
-- @field #RANGE.Soundfile IREnterRange
-- @field #RANGE.Soundfile IRExitRange
RANGE.Sound = {
  RC0 = { filename = "RC-0.ogg", duration = 0.60 },
  RC1 = { filename = "RC-1.ogg", duration = 0.47 },
  RC2 = { filename = "RC-2.ogg", duration = 0.43 },
  RC3 = { filename = "RC-3.ogg", duration = 0.50 },
  RC4 = { filename = "RC-4.ogg", duration = 0.58 },
  RC5 = { filename = "RC-5.ogg", duration = 0.54 },
  RC6 = { filename = "RC-6.ogg", duration = 0.61 },
  RC7 = { filename = "RC-7.ogg", duration = 0.53 },
  RC8 = { filename = "RC-8.ogg", duration = 0.34 },
  RC9 = { filename = "RC-9.ogg", duration = 0.54 },
  RCAccuracy = { filename = "RC-Accuracy.ogg", duration = 0.67 },
  RCDegrees = { filename = "RC-Degrees.ogg", duration = 0.59 },
  RCExcellentHit = { filename = "RC-ExcellentHit.ogg", duration = 0.76 },
  RCExcellentPass = { filename = "RC-ExcellentPass.ogg", duration = 0.89 },
  RCFeet = { filename = "RC-Feet.ogg", duration = 0.49 },
  RCFor = { filename = "RC-For.ogg", duration = 0.64 },
  RCGoodHit = { filename = "RC-GoodHit.ogg", duration = 0.52 },
  RCGoodPass = { filename = "RC-GoodPass.ogg", duration = 0.62 },
  RCHitsOnTarget = { filename = "RC-HitsOnTarget.ogg", duration = 0.88 },
  RCImpact = { filename = "RC-Impact.ogg", duration = 0.61 },
  RCIneffectiveHit = { filename = "RC-IneffectiveHit.ogg", duration = 0.86 },
  RCIneffectivePass = { filename = "RC-IneffectivePass.ogg", duration = 0.99 },
  RCInvalidHit = { filename = "RC-InvalidHit.ogg", duration = 2.97 },
  RCLeftStrafePitTooQuickly = { filename = "RC-LeftStrafePitTooQuickly.ogg", duration = 3.09 },
  RCPercent = { filename = "RC-Percent.ogg", duration = 0.56 },
  RCPoorHit = { filename = "RC-PoorHit.ogg", duration = 0.54 },
  RCPoorPass = { filename = "RC-PoorPass.ogg", duration = 0.68 },
  RCRollingInOnStrafeTarget = { filename = "RC-RollingInOnStrafeTarget.ogg", duration = 1.38 },
  RCTotalRoundsFired = { filename = "RC-TotalRoundsFired.ogg", duration = 1.22 },
  RCWeaponImpactedTooFar = { filename = "RC-WeaponImpactedTooFar.ogg", duration = 3.73 },
  IR0 = { filename = "IR-0.ogg", duration = 0.55 },
  IR1 = { filename = "IR-1.ogg", duration = 0.41 },
  IR2 = { filename = "IR-2.ogg", duration = 0.37 },
  IR3 = { filename = "IR-3.ogg", duration = 0.41 },
  IR4 = { filename = "IR-4.ogg", duration = 0.37 },
  IR5 = { filename = "IR-5.ogg", duration = 0.43 },
  IR6 = { filename = "IR-6.ogg", duration = 0.55 },
  IR7 = { filename = "IR-7.ogg", duration = 0.43 },
  IR8 = { filename = "IR-8.ogg", duration = 0.38 },
  IR9 = { filename = "IR-9.ogg", duration = 0.55 },
  IRDecimal = { filename = "IR-Decimal.ogg", duration = 0.54 },
  IRMegaHertz = { filename = "IR-MegaHertz.ogg", duration = 0.87 },
  IREnterRange = { filename = "IR-EnterRange.ogg", duration = 4.83 },
  IRExitRange = { filename = "IR-ExitRange.ogg", duration = 3.10 },
}

--- Global list of all defined range names.
-- @field #table Names
RANGE.Names = {}

--- Main radio menu on group level.
-- @field #table MenuF10 Root menu table on group level.
RANGE.MenuF10 = {}

--- Main radio menu on mission level.
-- @field #table MenuF10Root Root menu on mission level.
RANGE.MenuF10Root = nil

--- Range script version.
-- @field #string version
RANGE.version = "2.8.0"

-- TODO list:
-- TODO: Verbosity level for messages.
-- TODO: Add option for default settings such as smoke off.
-- TODO: Add custom weapons, which can be specified by the user.
-- TODO: Check if units are still alive.
-- TODO: Option for custom sound files.
-- DONE: Scenery as targets.
-- DONE: Add statics for strafe pits.
-- DONE: Add missiles.
-- DONE: Convert env.info() to self:T()
-- DONE: Add user functions.
-- DONE: Rename private functions, i.e. start with _functionname.
-- DONE: number of displayed results variable.
-- DONE: Add tire option for strafe pits. ==> No really feasible since tires are very small and cannot be seen.
-- DONE: Check that menu texts are short enough to be correctly displayed in VR.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- RANGE contructor. Creates a new RANGE object.
-- @param #RANGE self
-- @param #string RangeName Name of the range. Has to be unique. Will we used to create F10 menu items etc.
-- @param #number Coalition (optional) Coalition of the range, if any, e.g. coalition.side.BLUE.
-- @return #RANGE RANGE object.
function RANGE:New( RangeName, Coalition )

  -- Inherit BASE.
  local self = BASE:Inherit( self, FSM:New() ) -- #RANGE

  -- Get range name.
  -- TODO: make sure that the range name is not given twice. This would lead to problems in the F10 radio menu.
  self.rangename = RangeName or "Practice Range"

  self.Coalition = Coalition

  -- Log id.
  self.lid = string.format( "RANGE %s | ", self.rangename )

  -- Debug info.
  local text = string.format( "Script version %s - creating new RANGE object %s.", RANGE.version, self.rangename )
  self:I( self.lid .. text )

  -- Defaults
  self:SetDefaultPlayerSmokeBomb()

  -- Start State.
  self:SetStartState( "Stopped" )

  ---
  -- Add FSM transitions.
  --                 From State   -->   Event        -->     To State
  self:AddTransition("Stopped",         "Start",             "Running")     -- Start RANGE script.
  self:AddTransition("*",               "Status",            "*")           -- Status of RANGE script.
  self:AddTransition("*",               "Impact",            "*")           -- Impact of bomb/rocket/missile.
  self:AddTransition("*",               "RollingIn",         "*")           -- Player rolling in on strafe target.
  self:AddTransition("*",               "StrafeResult",      "*")           -- Strafe result of player.
  self:AddTransition("*",               "EnterRange",        "*")           -- Player enters the range.
  self:AddTransition("*",               "ExitRange",         "*")           -- Player leaves the range.
  self:AddTransition("*",               "Save",              "*")           -- Save player results.
  self:AddTransition("*",               "Load",              "*")           -- Load player results.

  ------------------------
  --- Pseudo Functions ---
  ------------------------

  --- Triggers the FSM event "Start". Starts the RANGE. Initializes parameters and starts event handlers.
  -- @function [parent=#RANGE] Start
  -- @param #RANGE self

  --- Triggers the FSM event "Start" after a delay. Starts the RANGE. Initializes parameters and starts event handlers.
  -- @function [parent=#RANGE] __Start
  -- @param #RANGE self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Stop". Stops the RANGE and all its event handlers.
  -- @param #RANGE self

  --- Triggers the FSM event "Stop" after a delay. Stops the RANGE and all its event handlers.
  -- @function [parent=#RANGE] __Stop
  -- @param #RANGE self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Status".
  -- @function [parent=#RANGE] Status
  -- @param #RANGE self

  --- Triggers the FSM event "Status" after a delay.
  -- @function [parent=#RANGE] __Status
  -- @param #RANGE self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Impact".
  -- @function [parent=#RANGE] Impact
  -- @param #RANGE self
  -- @param #RANGE.BombResult result Data of bombing run.
  -- @param #RANGE.PlayerData player Data of player settings etc.

  --- Triggers the FSM delayed event "Impact".
  -- @function [parent=#RANGE] __Impact
  -- @param #RANGE self
  -- @param #number delay Delay in seconds before the function is called.
  -- @param #RANGE.BombResult result Data of the bombing run.
  -- @param #RANGE.PlayerData player Data of player settings etc.

  --- On after "Impact" event user function. Called when a bomb/rocket/missile impacted.
  -- @function [parent=#RANGE] OnAfterImpact
  -- @param #RANGE self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #RANGE.BombResult result Data of the bombing run.
  -- @param #RANGE.PlayerData player Data of player settings etc.


  --- Triggers the FSM event "RollingIn".
  -- @function [parent=#RANGE] RollingIn
  -- @param #RANGE self
  -- @param #RANGE.PlayerData player Data of player settings etc.
  -- @param #RANGE.StrafeTarget target Strafe target.

  --- On after "RollingIn" event user function. Called when a player rolls in to a strafe taret.
  -- @function [parent=#RANGE] OnAfterRollingIn
  -- @param #RANGE self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #RANGE.PlayerData player Data of player settings etc.
  -- @param #RANGE.StrafeTarget target Strafe target.

  --- Triggers the FSM event "StrafeResult".
  -- @function [parent=#RANGE] StrafeResult
  -- @param #RANGE self
  -- @param #RANGE.PlayerData player Data of player settings etc.
  -- @param #RANGE.StrafeResult result Data of the strafing run.

  --- On after "StrafeResult" event user function. Called when a player finished a strafing run.
  -- @function [parent=#RANGE] OnAfterStrafeResult
  -- @param #RANGE self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #RANGE.PlayerData player Data of player settings etc.
  -- @param #RANGE.StrafeResult result Data of the strafing run.

  --- Triggers the FSM event "EnterRange".
  -- @function [parent=#RANGE] EnterRange
  -- @param #RANGE self
  -- @param #RANGE.PlayerData player Data of player settings etc.

  --- Triggers the FSM delayed event "EnterRange".
  -- @function [parent=#RANGE] __EnterRange
  -- @param #RANGE self
  -- @param #number delay Delay in seconds before the function is called.
  -- @param #RANGE.PlayerData player Data of player settings etc.

  --- On after "EnterRange" event user function. Called when a player enters the range zone.
  -- @function [parent=#RANGE] OnAfterEnterRange
  -- @param #RANGE self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #RANGE.PlayerData player Data of player settings etc.

  --- Triggers the FSM event "ExitRange".
  -- @function [parent=#RANGE] ExitRange
  -- @param #RANGE self
  -- @param #RANGE.PlayerData player Data of player settings etc.

  --- Triggers the FSM delayed event "ExitRange".
  -- @function [parent=#RANGE] __ExitRange
  -- @param #RANGE self
  -- @param #number delay Delay in seconds before the function is called.
  -- @param #RANGE.PlayerData player Data of player settings etc.

  --- On after "ExitRange" event user function. Called when a player leaves the range zone.
  -- @function [parent=#RANGE] OnAfterExitRange
  -- @param #RANGE self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #RANGE.PlayerData player Data of player settings etc.

  -- Return object.
  return self
end

--- Initializes number of targets and location of the range. Starts the event handlers.
-- @param #RANGE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function RANGE:onafterStart()

  -- Location/coordinate of range.
  local _location = nil

  -- Count bomb targets.
  local _count = 0
  for _, _target in pairs( self.bombingTargets ) do
    _count = _count + 1

    -- Get range location.
    if _location == nil then
      _location = self:_GetBombTargetCoordinate( _target )
    end
  end
  self.nbombtargets = _count

  -- Count strafing targets.
  _count = 0
  for _, _target in pairs( self.strafeTargets ) do
    _count = _count + 1

    for _, _unit in pairs( _target.targets ) do
      if _location == nil then
        _location = _unit:GetCoordinate()
      end
    end
  end
  self.nstrafetargets = _count

  -- Location of the range. We simply take the first unit/target we find if it was not explicitly specified by the user.
  if self.location == nil then
    self.location = _location
  end

  if self.location == nil then
    local text = string.format( "ERROR! No range location found. Number of strafe targets = %d. Number of bomb targets = %d.", self.nstrafetargets, self.nbombtargets )
    self:E( self.lid .. text )
    return
  end

  -- Define a MOOSE zone of the range.
  if self.rangezone == nil then
    self.rangezone = ZONE_RADIUS:New( self.rangename, { x = self.location.x, y = self.location.z }, self.rangeradius )
  end

  -- Starting range.
  local text = string.format( "Starting RANGE %s. Number of strafe targets = %d. Number of bomb targets = %d.", self.rangename, self.nstrafetargets, self.nbombtargets )
  self:I( self.lid .. text )

  -- Event handling.
  self:HandleEvent( EVENTS.Birth )
  self:HandleEvent( EVENTS.Hit )
  self:HandleEvent( EVENTS.Shot )

  -- Make bomb target move randomly within the range zone.
  for _, _target in pairs( self.bombingTargets ) do
    local target=_target --#RANGE.BombTarget

    -- Check if unit and can move.
    if target.move and target.type==RANGE.TargetType.UNIT and target.speed > 1 then
      target.target:PatrolZones( { self.rangezone }, target.speed * 0.75, ENUMS.Formation.Vehicle.OffRoad )
    end

  end

  -- Init range control.
  if self.rangecontrolfreq and not self.useSRS then

    -- Radio queue.
    self.rangecontrol = RADIOQUEUE:New( self.rangecontrolfreq, nil, self.rangename )
    self.rangecontrol.schedonce = true

    -- Init numbers.
    self.rangecontrol:SetDigit( 0, self.Sound.RC0.filename, self.Sound.RC0.duration, self.soundpath )
    self.rangecontrol:SetDigit( 1, self.Sound.RC1.filename, self.Sound.RC1.duration, self.soundpath )
    self.rangecontrol:SetDigit( 2, self.Sound.RC2.filename, self.Sound.RC2.duration, self.soundpath )
    self.rangecontrol:SetDigit( 3, self.Sound.RC3.filename, self.Sound.RC3.duration, self.soundpath )
    self.rangecontrol:SetDigit( 4, self.Sound.RC4.filename, self.Sound.RC4.duration, self.soundpath )
    self.rangecontrol:SetDigit( 5, self.Sound.RC5.filename, self.Sound.RC5.duration, self.soundpath )
    self.rangecontrol:SetDigit( 6, self.Sound.RC6.filename, self.Sound.RC6.duration, self.soundpath )
    self.rangecontrol:SetDigit( 7, self.Sound.RC7.filename, self.Sound.RC7.duration, self.soundpath )
    self.rangecontrol:SetDigit( 8, self.Sound.RC8.filename, self.Sound.RC8.duration, self.soundpath )
    self.rangecontrol:SetDigit( 9, self.Sound.RC9.filename, self.Sound.RC9.duration, self.soundpath )

    -- Set location where the messages are transmitted from.
    self.rangecontrol:SetSenderCoordinate( self.location )
    self.rangecontrol:SetSenderUnitName( self.rangecontrolrelayname )

    -- Start range control radio queue.
    self.rangecontrol:Start( 1, 0.1 )

    -- Init range control.
    if self.instructorfreq and not self.useSRS then

      -- Radio queue.
      self.instructor = RADIOQUEUE:New( self.instructorfreq, nil, self.rangename )
      self.instructor.schedonce = true

      -- Init numbers.
      self.instructor:SetDigit( 0, self.Sound.IR0.filename, self.Sound.IR0.duration, self.soundpath )
      self.instructor:SetDigit( 1, self.Sound.IR1.filename, self.Sound.IR1.duration, self.soundpath )
      self.instructor:SetDigit( 2, self.Sound.IR2.filename, self.Sound.IR2.duration, self.soundpath )
      self.instructor:SetDigit( 3, self.Sound.IR3.filename, self.Sound.IR3.duration, self.soundpath )
      self.instructor:SetDigit( 4, self.Sound.IR4.filename, self.Sound.IR4.duration, self.soundpath )
      self.instructor:SetDigit( 5, self.Sound.IR5.filename, self.Sound.IR5.duration, self.soundpath )
      self.instructor:SetDigit( 6, self.Sound.IR6.filename, self.Sound.IR6.duration, self.soundpath )
      self.instructor:SetDigit( 7, self.Sound.IR7.filename, self.Sound.IR7.duration, self.soundpath )
      self.instructor:SetDigit( 8, self.Sound.IR8.filename, self.Sound.IR8.duration, self.soundpath )
      self.instructor:SetDigit( 9, self.Sound.IR9.filename, self.Sound.IR9.duration, self.soundpath )

      -- Set location where the messages are transmitted from.
      self.instructor:SetSenderCoordinate( self.location )
      self.instructor:SetSenderUnitName( self.instructorrelayname )

      -- Start instructor radio queue.
      self.instructor:Start( 1, 0.1 )

    end

  end

  -- Load prev results.
  if self.autosave then
    self:Load()
  end

  -- Debug mode: smoke all targets and range zone.
  if self.Debug then
    self:_MarkTargetsOnMap()
    self:_SmokeBombTargets()
    self:_SmokeStrafeTargets()
    self:_SmokeStrafeTargetBoxes()
    self.rangezone:SmokeZone( SMOKECOLOR.White )
  end

  self:__Status( -10 )
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set the root F10 menu under which the range F10 menu is created.
-- @param #RANGE self
-- @param Core.Menu#MENU_MISSION menu The root F10 menu.
-- @return #RANGE self
function RANGE:SetMenuRoot(menu)
  self.menuF10root=menu
  return self
end


--- Set maximal strafing altitude. Player entering a strafe pit above that altitude are not registered for a valid pass.
-- @param #RANGE self
-- @param #number maxalt Maximum altitude in meters AGL. Default is 914 m = 3000 ft.
-- @return #RANGE self
function RANGE:SetMaxStrafeAlt( maxalt )
  self.strafemaxalt = maxalt or RANGE.Defaults.strafemaxalt
  return self
end

--- Set time interval for tracking bombs. A smaller time step increases accuracy but needs more CPU time.
-- @param #RANGE self
-- @param #number dt Time interval in seconds. Default is 0.005 s.
-- @return #RANGE self
function RANGE:SetBombtrackTimestep( dt )
  self.dtBombtrack = dt or RANGE.Defaults.dtBombtrack
  return self
end

--- Set time how long (most) messages are displayed.
-- @param #RANGE self
-- @param #number time Time in seconds. Default is 30 s.
-- @return #RANGE self
function RANGE:SetMessageTimeDuration( time )
  self.Tmsg = time or RANGE.Defaults.Tmsg
  return self
end

--- Automatically save player results to disc.
-- @param #RANGE self
-- @return #RANGE self
function RANGE:SetAutosaveOn()
  self.autosave = true
  return self
end

--- Switch off auto save player results.
-- @param #RANGE self
-- @return #RANGE self
function RANGE:SetAutosaveOff()
  self.autosave = false
  return self
end

--- Enable saving of player's target sheets and specify an optional directory path.
-- @param #RANGE self
-- @param #string path (Optional) Path where to save the target sheets.
-- @param #string prefix (Optional) Prefix for target sheet files. File name will be saved as *prefix_aircrafttype-0001.csv*, *prefix_aircrafttype-0002.csv*, etc.
-- @return #RANGE self
function RANGE:SetTargetSheet( path, prefix )
  if io then
    self.targetsheet = true
    self.targetpath = path
    self.targetprefix = prefix
  else
    self:E( self.lid .. "ERROR: io is not desanitized. Cannot save target sheet." )
  end
  return self
end

--- Set FunkMan socket. Bombing and strafing results will be send to your Discord bot.
-- **Requires running FunkMan program**.
-- @param #RANGE self
-- @param #number Port Port. Default `10042`.
-- @param #string Host Host. Default "127.0.0.1".
-- @return #RANGE self
function RANGE:SetFunkManOn(Port, Host)

  self.funkmanSocket=SOCKET:New(Port, Host)

  return self
end

--- Set messages to examiner. The examiner will receive messages from all clients.
-- @param #RANGE self
-- @param #string examinergroupname Name of the group of the examiner.
-- @param #boolean exclusively If true, messages are send exclusively to the examiner, i.e. not to the clients.
-- @return #RANGE self
function RANGE:SetMessageToExaminer( examinergroupname, exclusively )
  self.examinergroupname = examinergroupname
  self.examinerexclusive = exclusively
  return self
end

--- Set max number of player results that are displayed.
-- @param #RANGE self
-- @param #number nmax Number of results. Default is 10.
-- @return #RANGE self
function RANGE:SetDisplayedMaxPlayerResults( nmax )
  self.ndisplayresult = nmax or RANGE.Defaults.ndisplayresult
  return self
end

--- Set range radius. Defines the area in which e.g. bomb impacts are smoked.
-- @param #RANGE self
-- @param #number radius Radius in km. Default 5 km.
-- @return #RANGE self
function RANGE:SetRangeRadius( radius )
  self.rangeradius = radius * 1000 or RANGE.Defaults.rangeradius
  return self
end

--- Set player setting whether bomb impact points are smoked or not.
-- @param #RANGE self
-- @param #boolean switch If true nor nil default is to smoke impact points of bombs.
-- @return #RANGE self
function RANGE:SetDefaultPlayerSmokeBomb( switch )
  if switch == true or switch == nil then
    self.defaultsmokebomb = true
  else
    self.defaultsmokebomb = false
  end
  return self
end

--- Set bomb track threshold distance. Bombs/rockets/missiles are only tracked if player-range distance is less than this distance. Default 25 km.
-- @param #RANGE self
-- @param #number distance Threshold distance in km. Default 25 km.
-- @return #RANGE self
function RANGE:SetBombtrackThreshold( distance )
  self.BombtrackThreshold = (distance or 25) * 1000
  return self
end

--- Set range location. If this is not done, one (random) unit position of the range is used to determine the location of the range.
-- The range location determines the position at which the weather data is evaluated.
-- @param #RANGE self
-- @param Core.Point#COORDINATE coordinate Coordinate of the range.
-- @return #RANGE self
function RANGE:SetRangeLocation( coordinate )
  self.location = coordinate
  return self
end

--- Set range zone. For example, no bomb impact points are smoked if a bomb falls outside of this zone.
-- If a zone is not explicitly specified, the range zone is determined by its location and radius.
-- @param #RANGE self
-- @param Core.Zone#ZONE zone MOOSE zone defining the range perimeters.
-- @return #RANGE self
function RANGE:SetRangeZone( zone )
  if zone and type(zone)=="string" then
    zone=ZONE:FindByName(zone)
  end
  self.rangezone = zone
  return self
end

--- Set smoke color for marking bomb targets. By default bomb targets are marked by red smoke.
-- @param #RANGE self
-- @param Utilities.Utils#SMOKECOLOR colorid Color id. Default `SMOKECOLOR.Red`.
-- @return #RANGE self
function RANGE:SetBombTargetSmokeColor( colorid )
  self.BombSmokeColor = colorid or SMOKECOLOR.Red
  return self
end

--- Set score bomb distance.
-- @param #RANGE self
-- @param #number distance Distance in meters. Default 1000 m.
-- @return #RANGE self
function RANGE:SetScoreBombDistance( distance )
  self.scorebombdistance = distance or 1000
  return self
end

--- Set smoke color for marking strafe targets. By default strafe targets are marked by green smoke.
-- @param #RANGE self
-- @param Utilities.Utils#SMOKECOLOR colorid Color id. Default `SMOKECOLOR.Green`.
-- @return #RANGE self
function RANGE:SetStrafeTargetSmokeColor( colorid )
  self.StrafeSmokeColor = colorid or SMOKECOLOR.Green
  return self
end

--- Set smoke color for marking strafe pit approach boxes. By default strafe pit boxes are marked by white smoke.
-- @param #RANGE self
-- @param Utilities.Utils#SMOKECOLOR colorid Color id. Default `SMOKECOLOR.White`.
-- @return #RANGE self
function RANGE:SetStrafePitSmokeColor( colorid )
  self.StrafePitSmokeColor = colorid or SMOKECOLOR.White
  return self
end

--- Set time delay between bomb impact and starting to smoke the impact point.
-- @param #RANGE self
-- @param #number delay Time delay in seconds. Default is 3 seconds.
-- @return #RANGE self
function RANGE:SetSmokeTimeDelay( delay )
  self.TdelaySmoke = delay or RANGE.Defaults.TdelaySmoke
  return self
end

--- Enable debug modus.
-- @param #RANGE self
-- @return #RANGE self
function RANGE:DebugON()
  self.Debug = true
  return self
end

--- Disable debug modus.
-- @param #RANGE self
-- @return #RANGE self
function RANGE:DebugOFF()
  self.Debug = false
  return self
end

--- Disable ALL messages to players.
-- @param #RANGE self
-- @return #RANGE self
function RANGE:SetMessagesOFF()
  self.messages = false
  return self
end

--- Enable messages to players. This is the default
-- @param #RANGE self
-- @return #RANGE self
function RANGE:SetMessagesON()
  self.messages = true
  return self
end

--- Enables tracking of all bomb types. Note that this is the default setting.
-- @param #RANGE self
-- @return #RANGE self
function RANGE:TrackBombsON()
  self.trackbombs = true
  return self
end

--- Disables tracking of all bomb types.
-- @param #RANGE self
-- @return #RANGE self
function RANGE:TrackBombsOFF()
  self.trackbombs = false
  return self
end

--- Enables tracking of all rocket types. Note that this is the default setting.
-- @param #RANGE self
-- @return #RANGE self
function RANGE:TrackRocketsON()
  self.trackrockets = true
  return self
end

--- Disables tracking of all rocket types.
-- @param #RANGE self
-- @return #RANGE self
function RANGE:TrackRocketsOFF()
  self.trackrockets = false
  return self
end

--- Enables tracking of all missile types. Note that this is the default setting.
-- @param #RANGE self
-- @return #RANGE self
function RANGE:TrackMissilesON()
  self.trackmissiles = true
  return self
end

--- Disables tracking of all missile types.
-- @param #RANGE self
-- @return #RANGE self
function RANGE:TrackMissilesOFF()
  self.trackmissiles = false
  return self
end

--- Use SRS Simple-Text-To-Speech for transmissions. No sound files necessary.
-- @param #RANGE self
-- @param #string PathToSRS Path to SRS directory.
-- @param #number Port SRS port. Default 5002.
-- @param #number Coalition Coalition side, e.g. `coalition.side.BLUE` or `coalition.side.RED`. Default `coalition.side.BLUE`.
-- @param #number Frequency Frequency to use. Default is 256 MHz for range control and 305 MHz for instructor. If given, both control and instructor get this frequency.
-- @param #number Modulation Modulation to use, defaults to radio.modulation.AM
-- @param #number Volume Volume, between 0.0 and 1.0. Defaults to 1.0
-- @param #string PathToGoogleKey Path to Google TTS credentials.
-- @return #RANGE self
function RANGE:SetSRS(PathToSRS, Port, Coalition, Frequency, Modulation, Volume, PathToGoogleKey)

  if PathToSRS or MSRS.path then

    self.useSRS=true

    self.controlmsrs=MSRS:New(PathToSRS or MSRS.path, Frequency or 256, Modulation or radio.modulation.AM)
    self.controlmsrs:SetPort(Port or MSRS.port)
    self.controlmsrs:SetCoalition(Coalition or coalition.side.BLUE)
    self.controlmsrs:SetLabel("RANGEC")
    self.controlmsrs:SetVolume(Volume or 1.0)
    self.controlsrsQ = MSRSQUEUE:New("CONTROL")

    self.instructmsrs=MSRS:New(PathToSRS or MSRS.path, Frequency or 305, Modulation or radio.modulation.AM)
    self.instructmsrs:SetPort(Port or MSRS.port)
    self.instructmsrs:SetCoalition(Coalition or coalition.side.BLUE)
    self.instructmsrs:SetLabel("RANGEI")
    self.instructmsrs:SetVolume(Volume or 1.0)
    self.instructsrsQ = MSRSQUEUE:New("INSTRUCT")
    
    if PathToGoogleKey then 
      self.controlmsrs:SetProviderOptionsGoogle(PathToGoogleKey,PathToGoogleKey)
      self.controlmsrs:SetProvider(MSRS.Provider.GOOGLE)
      self.instructmsrs:SetProviderOptionsGoogle(PathToGoogleKey,PathToGoogleKey)
      self.instructmsrs:SetProvider(MSRS.Provider.GOOGLE)
    end

  else
    self:E(self.lid..string.format("ERROR: No SRS path specified!"))
  end
  return self
end

--- (SRS) Set range control frequency and voice. Use `RANGE:SetSRS()` once first before using this function.
-- @param #RANGE self
-- @param #number frequency Frequency in MHz. Default 256 MHz.
-- @param #number modulation Modulation, defaults to radio.modulation.AM.
-- @param #string voice Voice.
-- @param #string culture Culture, defaults to "en-US".
-- @param #string gender Gender, defaults to "female".
-- @param #string relayunitname Name of the unit used for transmission location.
-- @return #RANGE self
function RANGE:SetSRSRangeControl( frequency, modulation, voice, culture, gender, relayunitname )
  if not self.instructmsrs then
    self:E(self.lid.."Use myrange:SetSRS() once first before using myrange:SetSRSRangeControl!")
    return self
  end
  self.rangecontrolfreq = frequency or 256
  self.controlmsrs:SetFrequencies(self.rangecontrolfreq)
  self.controlmsrs:SetModulations(modulation or radio.modulation.AM)
  self.controlmsrs:SetVoice(voice)
  self.controlmsrs:SetCulture(culture or "en-US")
  self.controlmsrs:SetGender(gender or "female")
  self.rangecontrol = true
  if relayunitname then
    local unit = UNIT:FindByName(relayunitname)
    local Coordinate = unit:GetCoordinate()
    self.rangecontrolrelayname = relayunitname
  end
  return self
end

--- (SRS) Set range instructor frequency and voice. Use `RANGE:SetSRS()` once first before using this function.
-- @param #RANGE self
-- @param #number frequency Frequency in MHz. Default 305 MHz.
-- @param #number modulation Modulation, defaults to radio.modulation.AM.
-- @param #string voice Voice.
-- @param #string culture Culture, defaults to "en-US".
-- @param #string gender Gender, defaults to "male".
-- @param #string relayunitname Name of the unit used for transmission location.
-- @return #RANGE self
function RANGE:SetSRSRangeInstructor( frequency, modulation, voice, culture, gender, relayunitname )
  if not self.instructmsrs then
    self:E(self.lid.."Use myrange:SetSRS() once first before using myrange:SetSRSRangeInstructor!")
    return self
  end
  self.instructorfreq = frequency or 305
  self.instructmsrs:SetFrequencies(self.instructorfreq)
  self.instructmsrs:SetModulations(modulation or radio.modulation.AM)
  self.instructmsrs:SetVoice(voice)
  self.instructmsrs:SetCulture(culture or "en-US")
  self.instructmsrs:SetGender(gender or "male")
  self.instructor = true
  if relayunitname then
    local unit = UNIT:FindByName(relayunitname)
    local Coordinate = unit:GetCoordinate()
    self.instructmsrs:SetCoordinate(Coordinate)
    self.instructorrelayname = relayunitname
  end
  return self
end

--- Enable range control and set frequency (non-SRS).
-- @param #RANGE self
-- @param #number frequency Frequency in MHz. Default 256 MHz.
-- @param #string relayunitname Name of the unit used for transmission.
-- @return #RANGE self
function RANGE:SetRangeControl( frequency, relayunitname )
  self.rangecontrolfreq = frequency or 256
  self.rangecontrolrelayname = relayunitname
  return self
end

--- Enable instructor radio and set frequency (non-SRS).
-- @param #RANGE self
-- @param #number frequency Frequency in MHz. Default 305 MHz.
-- @param #string relayunitname Name of the unit used for transmission.
-- @return #RANGE self
function RANGE:SetInstructorRadio( frequency, relayunitname )
  self.instructorfreq = frequency or 305
  self.instructorrelayname = relayunitname
  return self
end

--- Set sound files folder within miz file.
-- @param #RANGE self
-- @param #string path Path for sound files. Default "Range Soundfiles/". Mind the slash "/" at the end!
-- @return #RANGE self
function RANGE:SetSoundfilesPath( path )
  self.soundpath = tostring( path or "Range Soundfiles/" )
  self:T2( self.lid .. string.format( "Setting sound files path to %s", self.soundpath ) )
  return self
end

--- Set the path to the csv file that contains information about the used sound files.
-- The parameter file has to be located on your local disk (**not** inside the miz file).
-- @param #RANGE self
-- @param #string csvfile Full path to the csv file on your local disk.
-- @return #RANGE self
function RANGE:SetSoundfilesInfo( csvfile )

  --- Local function to return the ATIS.Soundfile for a given file name
  local function getSound(filename)
    for key,_soundfile in pairs(self.Sound) do
      local soundfile=_soundfile --#RANGE.Soundfile
      if filename==soundfile.filename then
        return soundfile
      end
    end
    return nil
  end

  -- Read csv file
  local data=UTILS.ReadCSV(csvfile)

  if data then

    for i,sound in pairs(data) do

      -- Get the ATIS.Soundfile
      local soundfile=getSound(sound.filename..".ogg") --#RANGE.Soundfile

      if soundfile then

        -- Set duration
        soundfile.duration=tonumber(sound.duration)

      else
        self:E(string.format("ERROR: Could not get info for sound file %s", sound.filename))
      end

    end
  else
    self:E(string.format("ERROR: Could not read sound csv file!"))
  end


  return self
end


--- Add new strafe pit. For a strafe pit, hits from guns are counted. One pit can consist of several units.
-- A strafe run approach is only valid if the player enters via a zone in front of the pit, which is defined by boxlength, boxwidth, and heading.
-- Furthermore, the player must not be too high and fly in the direction of the pit to make a valid target apporoach.
-- @param #RANGE self
-- @param #table targetnames Single or multiple (Table) unit or static names defining the strafe targets. The first target in the list determines the approach box origin (heading and box).
-- @param #number boxlength (Optional) Length of the approach box in meters. Default is 3000 m.
-- @param #number boxwidth (Optional) Width of the approach box in meters. Default is 300 m.
-- @param #number heading (Optional) Approach box heading in degrees (originating FROM the target). Default is the heading set in the ME for the first target unit
-- @param #boolean inverseheading (Optional) Use inverse heading (heading --> heading - 180 Degrees). Default is false.
-- @param #number goodpass (Optional) Number of hits for a "good" strafing pass. Default is 20.
-- @param #number foulline (Optional) Foul line distance. Hits from closer than this distance are not counted. Default is 610 m = 2000 ft. Set to 0 for no foul line.
-- @return #RANGE self
function RANGE:AddStrafePit( targetnames, boxlength, boxwidth, heading, inverseheading, goodpass, foulline )
  self:F( { targetnames = targetnames, boxlength = boxlength, boxwidth = boxwidth, heading = heading, inverseheading = inverseheading, goodpass = goodpass, foulline = foulline } )

  -- Create table if necessary.
  if type( targetnames ) ~= "table" then
    targetnames = { targetnames }
  end

  -- Make targets
  local _targets = {}
  local center = nil -- Wrapper.Unit#UNIT
  local ntargets = 0

  for _i, _name in ipairs( targetnames ) do

    -- Check if we have a static or unit object.
    local _isstatic = self:_CheckStatic( _name )

    local unit = nil
    if _isstatic == true then

      -- Add static object.
      self:T( self.lid .. string.format( "Adding STATIC object %s as strafe target #%d.", _name, _i ) )
      unit = STATIC:FindByName( _name, false )

    elseif _isstatic == false then

      -- Add unit object.
      self:T( self.lid .. string.format( "Adding UNIT object %s as strafe target #%d.", _name, _i ) )
      unit = UNIT:FindByName( _name )

    else

      -- Neither unit nor static object with this name could be found.
      local text = string.format( "ERROR! Could not find ANY strafe target object with name %s.", _name )
      self:E( self.lid .. text )

    end

    -- Add object to targets.
    if unit then
      table.insert( _targets, unit )
      -- Define center as the first unit we find
      if center == nil then
        center = unit
      end
      ntargets = ntargets + 1
    end

  end

  -- Check if at least one target could be found.
  if ntargets == 0 then
    local text = string.format( "ERROR! No strafe target could be found when calling RANGE:AddStrafePit() for range %s", self.rangename )
    self:E( self.lid .. text )
    return
  end

  -- Approach box dimensions.
  local l = boxlength or RANGE.Defaults.boxlength
  local w = (boxwidth or RANGE.Defaults.boxwidth) / 2

  -- Heading: either manually entered or automatically taken from unit heading.
  local heading = heading or center:GetHeading()

  -- Invert the heading since some units point in the "wrong" direction. In particular the strafe pit from 476th range objects.
  if inverseheading ~= nil then
    if inverseheading then
      heading = heading - 180
    end
  end
  if heading < 0 then
    heading = heading + 360
  end
  if heading > 360 then
    heading = heading - 360
  end

  -- Number of hits called a "good" pass.
  goodpass = goodpass or RANGE.Defaults.goodpass

  -- Foule line distance.
  foulline = foulline or RANGE.Defaults.foulline

  -- Coordinate of the range.
  local Ccenter = center:GetCoordinate()

  -- Name of the target defined as its unit name.
  local _name = center:GetName()

  -- Points defining the approach area.
  local p = {}
  p[#p + 1] = Ccenter:Translate( w, heading + 90 )
  p[#p + 1] = p[#p]:Translate( l, heading )
  p[#p + 1] = p[#p]:Translate( 2 * w, heading - 90 )
  p[#p + 1] = p[#p]:Translate( -l, heading )

  local pv2 = {}
  for i, p in ipairs( p ) do
    pv2[i] = { x = p.x, y = p.z }
  end

  -- Create polygon zone.
  local _polygon = ZONE_POLYGON_BASE:New( _name, pv2 )

  -- Create tires
  -- _polygon:BoundZone()

  local st = {} -- #RANGE.StrafeTarget
  st.name = _name
  st.polygon = _polygon
  st.coordinate = Ccenter
  st.goodPass = goodpass
  st.targets = _targets
  st.foulline = foulline
  st.smokepoints = p
  st.heading = heading

  -- Add zone to table.
  table.insert( self.strafeTargets, st )

  -- Debug info
  local text = string.format( "Adding new strafe target %s with %d targets: heading = %03d, box_L = %.1f, box_W = %.1f, goodpass = %d, foul line = %.1f", _name, ntargets, heading, l, w, goodpass, foulline )
  self:T( self.lid .. text )

  return self
end

--- Add all units of a group as one new strafe target pit.
-- For a strafe pit, hits from guns are counted. One pit can consist of several units.
-- Note, an approach is only valid, if the player enters via a zone in front of the pit, which defined by boxlength and boxheading.
-- Furthermore, the player must not be too high and fly in the direction of the pit to make a valid target apporoach.
-- @param #RANGE self
-- @param Wrapper.Group#GROUP group MOOSE group of unit names defining the strafe target pit. The first unit in the group determines the approach zone (heading and box).
-- @param #number boxlength (Optional) Length of the approach box in meters. Default is 3000 m.
-- @param #number boxwidth (Optional) Width of the approach box in meters. Default is 300 m.
-- @param #number heading (Optional) Approach heading in Degrees. Default is heading of the unit as defined in the mission editor.
-- @param #boolean inverseheading (Optional) Take inverse heading (heading --> heading - 180 Degrees). Default is false.
-- @param #number goodpass (Optional) Number of hits for a "good" strafing pass. Default is 20.
-- @param #number foulline (Optional) Foul line distance. Hits from closer than this distance are not counted. Default 610 m = 2000 ft. Set to 0 for no foul line.
-- @return #RANGE self
function RANGE:AddStrafePitGroup( group, boxlength, boxwidth, heading, inverseheading, goodpass, foulline )
  self:F( { group = group, boxlength = boxlength, boxwidth = boxwidth, heading = heading, inverseheading = inverseheading, goodpass = goodpass, foulline = foulline } )

  if group and group:IsAlive() then

    -- Get units of group.
    local _units = group:GetUnits()

    -- Make table of unit names.
    local _names = {}
    for _, _unit in ipairs( _units ) do

      local _unit = _unit -- Wrapper.Unit#UNIT

      if _unit and _unit:IsAlive() then
        local _name = _unit:GetName()
        table.insert( _names, _name )
      end

    end

    -- Add strafe pit.
    self:AddStrafePit( _names, boxlength, boxwidth, heading, inverseheading, goodpass, foulline )
  end

  return self
end

--- Add bombing target(s) to range.
-- @param #RANGE self
-- @param #table targetnames Single or multiple (Table) names of unit or static objects serving as bomb targets.
-- @param #number goodhitrange (Optional) Max distance from target unit (in meters) which is considered as a good hit. Default is 25 m.
-- @param #boolean randommove If true, unit will move randomly within the range. Default is false.
-- @return #RANGE self
function RANGE:AddBombingTargets( targetnames, goodhitrange, randommove )
  self:F( { targetnames = targetnames, goodhitrange = goodhitrange, randommove = randommove } )

  -- Create a table if necessary.
  if type( targetnames ) ~= "table" then
    targetnames = { targetnames }
  end

  -- Default range is 25 m.
  goodhitrange = goodhitrange or RANGE.Defaults.goodhitrange

  for _, name in pairs( targetnames ) do

    -- Check if we have a static or unit object.
    local _isstatic = self:_CheckStatic( name )

    if _isstatic == true then
      local _static = STATIC:FindByName( name )
      self:T2( self.lid .. string.format( "Adding static bombing target %s with hit range %d.", name, goodhitrange, false ) )
      self:AddBombingTargetUnit( _static, goodhitrange )
    elseif _isstatic == false then
      local _unit = UNIT:FindByName( name )
      self:T2( self.lid .. string.format( "Adding unit bombing target %s with hit range %d.", name, goodhitrange, randommove ) )
      self:AddBombingTargetUnit( _unit, goodhitrange, randommove )
    else
      self:E( self.lid .. string.format( "ERROR! Could not find bombing target %s.", name ) )
    end

  end

  return self
end

--- Add a unit or static object as bombing target.
-- @param #RANGE self
-- @param Wrapper.Positionable#POSITIONABLE unit Positionable (unit or static) of the bombing target.
-- @param #number goodhitrange Max distance from unit which is considered as a good hit.
-- @param #boolean randommove If true, unit will move randomly within the range. Default is false.
-- @return #RANGE self
function RANGE:AddBombingTargetUnit( unit, goodhitrange, randommove )
  self:F( { unit = unit, goodhitrange = goodhitrange, randommove = randommove } )

  -- Get name of positionable.
  local name = unit:GetName()

  -- Check if we have a static or unit object.
  local _isstatic = self:_CheckStatic( name )

  -- Default range is 25 m.
  goodhitrange = goodhitrange or RANGE.Defaults.goodhitrange

  -- Set randommove to false if it was not specified.
  if randommove == nil or _isstatic == true then
    randommove = false
  end

  -- Debug or error output.
  if _isstatic == true then
    self:T( self.lid .. string.format( "Adding STATIC bombing target %s with good hit range %d. Random move = %s.", name, goodhitrange, tostring( randommove ) ) )
  elseif _isstatic == false then
    self:T( self.lid .. string.format( "Adding UNIT bombing target %s with good hit range %d. Random move = %s.", name, goodhitrange, tostring( randommove ) ) )
  else
    self:E( self.lid .. string.format( "ERROR! No bombing target with name %s could be found. Carefully check all UNIT and STATIC names defined in the mission editor!", name ) )
  end

  -- Get max speed of unit in km/h.
  local speed = 0
  if _isstatic == false then
    speed = self:_GetSpeed( unit )
  end

  local target = {} -- #RANGE.BombTarget
  target.name = name
  target.target = unit
  target.goodhitrange = goodhitrange
  target.move = randommove
  target.speed = speed
  target.coordinate = unit:GetCoordinate()
  if _isstatic then
    target.type = RANGE.TargetType.STATIC
  else
    target.type = RANGE.TargetType.UNIT
  end

  -- Insert target to table.
  table.insert( self.bombingTargets, target )

  return self
end

--- Add a coordinate of a bombing target. This
-- @param #RANGE self
-- @param Core.Point#COORDINATE coord The coordinate.
-- @param #string name Name of target.
-- @param #number goodhitrange Max distance from unit which is considered as a good hit.
-- @return #RANGE self
function RANGE:AddBombingTargetCoordinate( coord, name, goodhitrange )

  local target = {} -- #RANGE.BombTarget
  target.name = name or "Bomb Target"
  target.target = nil
  target.goodhitrange = goodhitrange or RANGE.Defaults.goodhitrange
  target.move = false
  target.speed = 0
  target.coordinate = coord
  target.type = RANGE.TargetType.COORD

  -- Insert target to table.
  table.insert( self.bombingTargets, target )

  return self
end

--- Add a scenery object as bombing target.
-- @param #RANGE self
-- @param Wrapper.Scenery#SCENERY scenery Scenary object.
-- @param #number goodhitrange Max distance from unit which is considered as a good hit.
-- @return #RANGE self
function RANGE:AddBombingTargetScenery( scenery, goodhitrange)

  -- Get name of positionable.
  local name = scenery:GetName()

  -- Default range is 25 m.
  goodhitrange = goodhitrange or RANGE.Defaults.goodhitrange

  -- Debug or error output.
  if name then
    self:T( self.lid .. string.format( "Adding SCENERY bombing target %s with good hit range %d", name, goodhitrange) )
  else
    self:E( self.lid .. string.format( "ERROR! No bombing target with name %s could be found!", name ) )
  end


  local target = {} -- #RANGE.BombTarget
  target.name = name
  target.target = scenery
  target.goodhitrange = goodhitrange
  target.move = false
  target.speed = 0
  target.coordinate = scenery:GetCoordinate()
  target.type = RANGE.TargetType.SCENERY

  -- Insert target to table.
  table.insert( self.bombingTargets, target )

  return self
end

--- Add all units of a group as bombing targets.
-- @param #RANGE self
-- @param Wrapper.Group#GROUP group Group of bombing targets. Can also be given as group name.
-- @param #number goodhitrange Max distance from unit which is considered as a good hit.
-- @param #boolean randommove If true, unit will move randomly within the range. Default is false.
-- @return #RANGE self
function RANGE:AddBombingTargetGroup( group, goodhitrange, randommove )
  self:F( { group = group, goodhitrange = goodhitrange, randommove = randommove } )
  
  if group and type(group)=="string" then
    group=GROUP:FindByName(group)
  end

  if group then

    local _units = group:GetUnits()

    for _, _unit in pairs( _units ) do
      if _unit and _unit:IsAlive() then
        self:AddBombingTargetUnit( _unit, goodhitrange, randommove )
      end
    end
  end

  return self
end

--- Measures the foule line distance between two unit or static objects.
-- @param #RANGE self
-- @param #string namepit Name of the strafe pit target object.
-- @param #string namefoulline Name of the fould line distance marker object.
-- @return #number Foul line distance in meters.
function RANGE:GetFoullineDistance( namepit, namefoulline )
  self:F( { namepit = namepit, namefoulline = namefoulline } )

  -- Check if we have units or statics.
  local _staticpit = self:_CheckStatic( namepit )
  local _staticfoul = self:_CheckStatic( namefoulline )

  -- Get the unit or static pit object.
  local pit = nil
  if _staticpit == true then
    pit = STATIC:FindByName( namepit, false )
  elseif _staticpit == false then
    pit = UNIT:FindByName( namepit )
  else
    self:E( self.lid .. string.format( "ERROR! Pit object %s could not be found in GetFoullineDistance function. Check the name in the ME.", namepit ) )
  end

  -- Get the unit or static foul line object.
  local foul = nil
  if _staticfoul == true then
    foul = STATIC:FindByName( namefoulline, false )
  elseif _staticfoul == false then
    foul = UNIT:FindByName( namefoulline )
  else
    self:E( self.lid .. string.format( "ERROR! Foul line object %s could not be found in GetFoullineDistance function. Check the name in the ME.", namefoulline ) )
  end

  -- Get the distance between the two objects.
  local fouldist = 0
  if pit ~= nil and foul ~= nil then
    fouldist = pit:GetCoordinate():Get2DDistance( foul:GetCoordinate() )
  else
    self:E( self.lid .. string.format( "ERROR! Foul line distance could not be determined. Check pit object name %s and foul line object name %s in the ME.", namepit, namefoulline ) )
  end

  self:T( self.lid .. string.format( "Foul line distance = %.1f m.", fouldist ) )
  return fouldist
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Event Handling
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Range event handler for event birth.
-- @param #RANGE self
-- @param Core.Event#EVENTDATA EventData
function RANGE:OnEventBirth( EventData )
  self:F( { eventbirth = EventData } )

  if not EventData.IniPlayerName then return end

  local _unitName = EventData.IniUnitName
  local _unit, _playername = self:_GetPlayerUnitAndName( _unitName, EventData.IniPlayerName )

  self:T3( self.lid .. "BIRTH: unit   = " .. tostring( EventData.IniUnitName ) )
  self:T3( self.lid .. "BIRTH: group  = " .. tostring( EventData.IniGroupName ) )
  self:T3( self.lid .. "BIRTH: player = " .. tostring( _playername ) )

  if _unit and _playername then

    local _uid = _unit:GetID()
    local _group = _unit:GetGroup()
    local _gid = _group:GetID()
    local _callsign = _unit:GetCallsign()

    -- Debug output.
    local text = string.format( "Player %s, callsign %s entered unit %s (UID %d) of group %s (GID %d)", _playername, _callsign, _unitName, _uid, _group:GetName(), _gid )
    self:T( self.lid .. text )

    -- Reset current strafe status.
    self.strafeStatus[_uid] = nil

    if self.Coalition then
      if EventData.IniCoalition == self.Coalition then
        self:ScheduleOnce( 0.1, self._AddF10Commands, self, _unitName )
      end
    else
      -- Add Menu commands after a delay of 0.1 seconds.
      self:ScheduleOnce( 0.1, self._AddF10Commands, self, _unitName )
    end

    -- By default, some bomb impact points and do not flare each hit on target.
    self.PlayerSettings[_playername] = {} -- #RANGE.PlayerData
    self.PlayerSettings[_playername].smokebombimpact = self.defaultsmokebomb
    self.PlayerSettings[_playername].flaredirecthits = false
    self.PlayerSettings[_playername].smokecolor = SMOKECOLOR.Blue
    self.PlayerSettings[_playername].flarecolor = FLARECOLOR.Red
    self.PlayerSettings[_playername].delaysmoke = true
    self.PlayerSettings[_playername].messages = true
    self.PlayerSettings[_playername].client = CLIENT:FindByName( _unitName, nil, true )
    self.PlayerSettings[_playername].unitname = _unitName
    self.PlayerSettings[_playername].unit = _unit
    self.PlayerSettings[_playername].playername = _playername
    self.PlayerSettings[_playername].airframe = EventData.IniUnit:GetTypeName()
    self.PlayerSettings[_playername].inzone = false

    -- Start check in zone timer.
    if self.planes[_uid] ~= true then
      self.timerCheckZone = TIMER:New( self._CheckInZone, self, EventData.IniUnitName ):Start( 1, 1 )
      self.planes[_uid] = true
    end

  end
end

--- Range event handler for event hit.
-- @param #RANGE self
-- @param Core.Event#EVENTDATA EventData
function RANGE:OnEventHit( EventData )
  self:F( { eventhit = EventData } )

  -- Debug info.
  self:T3( self.lid .. "HIT: Ini unit   = " .. tostring( EventData.IniUnitName ) )
  self:T3( self.lid .. "HIT: Ini group  = " .. tostring( EventData.IniGroupName ) )
  self:T3( self.lid .. "HIT: Tgt target = " .. tostring( EventData.TgtUnitName ) )

  -- Player info
  local _unitName = EventData.IniUnitName
  local _unit, _playername = self:_GetPlayerUnitAndName( _unitName )
  if _unit == nil or _playername == nil then
    return
  end

  -- Unit ID
  local _unitID = _unit:GetID()

  -- Target
  local target = EventData.TgtUnit
  local targetname = EventData.TgtUnitName

  -- Current strafe target of player.
  local _currentTarget = self.strafeStatus[_unitID] --#RANGE.StrafeStatus

  -- Player has rolled in on a strafing target.
  if _currentTarget and target:IsAlive() then

    local playerPos = _unit:GetCoordinate()
    local targetPos = target:GetCoordinate()

    -- Loop over valid targets for this run.
    for _, _target in pairs( _currentTarget.zone.targets ) do

      -- Check the the target is the same that was actually hit.
      if _target and _target:IsAlive() and _target:GetName() == targetname then

        -- Get distance between player and target.
        local dist = playerPos:Get2DDistance( targetPos )

        if dist > _currentTarget.zone.foulline then
          -- Increase hit counter of this run.
          _currentTarget.hits = _currentTarget.hits + 1

          -- Flare target.
          if _unit and _playername and self.PlayerSettings[_playername].flaredirecthits then
            targetPos:Flare( self.PlayerSettings[_playername].flarecolor )
          end
        else
          -- Too close to the target.
          if _currentTarget.pastfoulline == false and _unit and _playername then
            local _d = _currentTarget.zone.foulline
            -- DONE - SRS output
            local text = string.format( "%s, Invalid hit!\nYou already passed foul line distance of %d m for target %s.", self:_myname( _unitName ), _d, targetname )
            if self.useSRS then
              local ttstext = string.format( "%s, Invalid hit! You already passed foul line distance of %d meters for target %s.", self:_myname( _unitName ), _d, targetname )
              self.controlsrsQ:NewTransmission(ttstext,nil,self.controlmsrs,nil,2)
            end
            self:_DisplayMessageToGroup( _unit, text )
            self:T2( self.lid .. text )
            _currentTarget.pastfoulline = true
          end
        end

      end
    end
  end

  -- Bombing Targets
  for _, _bombtarget in pairs( self.bombingTargets ) do

    local _target = _bombtarget.target -- Wrapper.Positionable#POSITIONABLE

    -- Check if one of the bomb targets was hit.
    if _target and _target:IsAlive() and _bombtarget.name == targetname then

      if _unit and _playername then

        -- Flare target.
        if self.PlayerSettings[_playername].flaredirecthits then

          -- Position of target.
          local targetPos = _target:GetCoordinate()

          targetPos:Flare( self.PlayerSettings[_playername].flarecolor )
        end

      end
    end
  end
end

--- Function called on impact of a tracked weapon.
-- @param Wrapper.Weapon#WEAPON weapon The weapon object.
-- @param #RANGE self RANGE object.
-- @param #RANGE.PlayerData playerData Player data table.
-- @param #number attackHdg Attack heading.
-- @param #number attackAlt Attack altitude.
-- @param #number attackVel Attack velocity.
function RANGE._OnImpact(weapon, self, playerData, attackHdg, attackAlt, attackVel)
  
  if not playerData then return end
  
  -- Get closet target to last position.
  local _closetTarget = nil -- #RANGE.BombTarget
  local _distance = nil
  local _closeCoord = nil   --Core.Point#COORDINATE
  local _hitquality = "POOR"

  -- Get callsign.
  local _callsign = self:_myname( playerData.unitname )

  local _playername=playerData.playername

  local _unit=playerData.unit

  -- Coordinate of impact point.
  local impactcoord = weapon:GetImpactCoordinate()

  -- Check if impact happened in range zone.+
  local insidezone = self.rangezone:IsCoordinateInZone( impactcoord )


  -- Smoke impact point of bomb.
  if playerData and playerData.smokebombimpact and insidezone then
    if playerData and playerData.delaysmoke then
      timer.scheduleFunction( self._DelayedSmoke, { coord = impactcoord, color = playerData.smokecolor }, timer.getTime() + self.TdelaySmoke )
    else
      impactcoord:Smoke( playerData.smokecolor )
    end
  end

  -- Loop over defined bombing targets.
  for _, _bombtarget in pairs( self.bombingTargets ) do
    local bombtarget=_bombtarget  --#RANGE.BombTarget

    -- Get target coordinate.
    local targetcoord = self:_GetBombTargetCoordinate( _bombtarget )

    if targetcoord then

      -- Distance between bomb and target.
      local _temp = impactcoord:Get2DDistance( targetcoord )

      -- Find closest target to last known position of the bomb.
      if _distance == nil or _temp < _distance then
        _distance = _temp
        _closetTarget = bombtarget
        _closeCoord   = targetcoord
        if _distance <= 1.53 then -- Rangeboss Edit
          _hitquality = "SHACK" -- Rangeboss Edit
        elseif _distance <= 0.5 * bombtarget.goodhitrange then -- Rangeboss Edit
          _hitquality = "EXCELLENT"
        elseif _distance <= bombtarget.goodhitrange then
          _hitquality = "GOOD"
        elseif _distance <= 2 * bombtarget.goodhitrange then
          _hitquality = "INEFFECTIVE"
        else
          _hitquality = "POOR"
        end

      end
    end
  end

  -- Count if bomb fell less than ~1 km away from the target.
  if _distance and _distance <= self.scorebombdistance then
    -- Init bomb player results.
    if not self.bombPlayerResults[_playername] then
      self.bombPlayerResults[_playername] = {}
    end

    -- Local results.
    local _results = self.bombPlayerResults[_playername]

    local result = {} -- #RANGE.BombResult
    result.command=SOCKET.DataType.BOMBRESULT
    result.name = _closetTarget.name or "unknown"
    result.distance = _distance
    result.radial = _closeCoord:HeadingTo( impactcoord )
    result.weapon = weapon:GetTypeName() or "unknown"
    result.quality = _hitquality
    result.player = playerData.playername
    result.time = timer.getAbsTime()
    result.clock = UTILS.SecondsToClock(result.time, true)
    result.midate = UTILS.GetDCSMissionDate()
    result.theatre = env.mission.theatre
    result.airframe = playerData.airframe
    result.roundsFired = 0 -- Rangeboss Edit
    result.roundsHit = 0 -- Rangeboss Edit
    result.roundsQuality = "N/A" -- Rangeboss Edit
    result.rangename = self.rangename
    result.attackHdg = attackHdg
    result.attackVel = attackVel
    result.attackAlt = attackAlt
    result.date=os and os.date() or "n/a"

    -- Add to table.
    table.insert( _results, result )

    -- Call impact.
    self:Impact( result, playerData )

  elseif insidezone then

    -- Send message.
    -- DONE SRS message
    local _message = string.format( "%s, weapon impacted too far from nearest range target (>%.1f km). No score!", _callsign, self.scorebombdistance / 1000 )
    if self.useSRS then
      local ttstext = string.format( "%s, weapon impacted too far from nearest range target, mor than %.1f kilometer. No score!", _callsign, self.scorebombdistance / 1000 )
      self.controlsrsQ:NewTransmission(ttstext,nil,self.controlmsrs,nil,2)
    end
    self:_DisplayMessageToGroup( _unit, _message, nil, false )

    if self.rangecontrol then
      -- weapon impacted too far from the nearest target! No Score!
      if self.useSRS then
        self.controlsrsQ:NewTransmission(_message,nil,self.controlmsrs,nil,1)
      else
        self.rangecontrol:NewTransmission( self.Sound.RCWeaponImpactedTooFar.filename, self.Sound.RCWeaponImpactedTooFar.duration, self.soundpath, nil, nil, _message, self.subduration )
      end
    end

  else
    self:T( self.lid .. "Weapon impacted outside range zone." )
  end

end

--- Range event handler for event shot (when a unit releases a rocket or bomb (but not a fast firing gun).
-- @param #RANGE self
-- @param Core.Event#EVENTDATA EventData
function RANGE:OnEventShot( EventData )
  self:F( { eventshot = EventData } )

  -- Nil checks.
  if EventData.Weapon == nil or EventData.IniDCSUnit == nil or EventData.IniPlayerName == nil then
    return
  end

  -- Create weapon object.
  local weapon=WEAPON:New(EventData.weapon)

  -- Check if any condition applies here.
  local _track = (weapon:IsBomb() and self.trackbombs) or (weapon:IsRocket() and self.trackrockets) or (weapon:IsMissile() and self.trackmissiles)

  -- Get unit name.
  local _unitName = EventData.IniUnitName

  -- Get player unit and name.
  local _unit, _playername = self:_GetPlayerUnitAndName( _unitName, EventData.IniPlayerName )

  -- Distance Player-to-Range. Set this to larger value than the threshold.
  local dPR = self.BombtrackThreshold * 2

  -- Distance player to range.
  if _unit and _playername then
    dPR = _unit:GetCoordinate():Get2DDistance( self.location )
    self:T( self.lid .. string.format( "Range %s, player %s, player-range distance = %d km.", self.rangename, _playername, dPR / 1000 ) )
  end

  -- Only track if distance player to range is < 25 km. Also check that a player shot. No need to track AI weapons.
  if _track and dPR <= self.BombtrackThreshold and _unit and _playername and self.PlayerSettings[_playername] then

    -- Player data.
    local playerData = self.PlayerSettings[_playername] -- #RANGE.PlayerData
    
    if not playerData then return end
    
    -- Attack parameters.
    local attackHdg=_unit:GetHeading()
    local attackAlt=_unit:GetHeight()
    attackAlt = UTILS.MetersToFeet(attackAlt)
    local attackVel=_unit:GetVelocityKNOTS()

    -- Tracking info and init of last bomb position.
    self:T( self.lid .. string.format( "RANGE %s: Tracking %s - %s.", self.rangename, weapon:GetTypeName(), weapon:GetName()))

    -- Set callback function on impact.
    weapon:SetFuncImpact(RANGE._OnImpact, self, playerData, attackHdg, attackAlt, attackVel)

    -- Weapon is not yet "alife" just yet. Start timer in 0.1 seconds.
    self:T( self.lid .. string.format( "Range %s, player %s: Tracking of weapon starts in 0.1 seconds.", self.rangename, _playername ) )
    weapon:StartTrack(0.1)

  end

end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Functions
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Check spawn queue and spawn aircraft if necessary.
-- @param #RANGE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function RANGE:onafterStatus( From, Event, To )

  if self.verbose > 0 then

    local fsmstate = self:GetState()

    local text = string.format( "Range status: %s", fsmstate )

    if self.instructor then
      local alive = "N/A"
      if self.instructorrelayname then
        local relay = UNIT:FindByName( self.instructorrelayname )
        if relay then
          alive = tostring( relay:IsAlive() )
        end
      end
      text = text .. string.format( ", Instructor %.3f MHz (Relay=%s alive=%s)", self.instructorfreq, tostring( self.instructorrelayname ), alive )
    end

    if self.rangecontrol then
      local alive = "N/A"
      if self.rangecontrolrelayname then
        local relay = UNIT:FindByName( self.rangecontrolrelayname )
        if relay then
          alive = tostring( relay:IsAlive() )
        end
      end
      text = text .. string.format( ", Control %.3f MHz (Relay=%s alive=%s)", self.rangecontrolfreq, tostring( self.rangecontrolrelayname ), alive )
    end

    -- Check range status.
    self:T( self.lid .. text )

  end

  -- Check player status.
  self:_CheckPlayers()

  -- Check back in ~10 seconds.
  self:__Status( -10 )
end

--- Function called after player enters the range zone.
-- @param #RANGE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #RANGE.PlayerData player Player data.
function RANGE:onafterEnterRange( From, Event, To, player )

  if self.instructor and self.rangecontrol then

    if self.useSRS then


      local text = string.format("You entered the bombing range. For hit assessment, contact the range controller at %.3f MHz", self.rangecontrolfreq)
      local ttstext = string.format("You entered the bombing range. For hit assessment, contact the range controller at %.3f mega hertz.", self.rangecontrolfreq)

      local group = player.client:GetGroup()

      self.instructsrsQ:NewTransmission(ttstext, nil, self.instructmsrs, nil, 1, {group}, text, 10)

    else

      -- Range control radio frequency split.
      local RF = UTILS.Split( string.format( "%.3f", self.rangecontrolfreq ), "." )

      -- Radio message that player entered the range

      -- You entered the bombing range. For hit assessment, contact the range controller at xy MHz
      self.instructor:NewTransmission( self.Sound.IREnterRange.filename, self.Sound.IREnterRange.duration, self.soundpath )
      self.instructor:Number2Transmission( RF[1] )

      if tonumber( RF[2] ) > 0 then
        self.instructor:NewTransmission( self.Sound.IRDecimal.filename, self.Sound.IRDecimal.duration, self.soundpath )
        self.instructor:Number2Transmission( RF[2] )
      end

      self.instructor:NewTransmission( self.Sound.IRMegaHertz.filename, self.Sound.IRMegaHertz.duration, self.soundpath )
    end
  end

end

--- Function called after player leaves the range zone.
-- @param #RANGE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #RANGE.PlayerData player Player data.
function RANGE:onafterExitRange( From, Event, To, player )

  if self.instructor then
    -- You left the bombing range zone. Have a nice day!
    if self.useSRS then

      local text = "You left the bombing range zone. "

      local r=math.random(5)

      if r==1 then
        text=text.."Have a nice day!"
      elseif r==2 then
        text=text.."Take care and bye bye!"
      elseif r==3 then
        text=text.."Talk to you soon!"
      elseif r==4 then
        text=text.."See you in two weeks!"
      elseif r==5 then
        text=text.."!"
      end

      self.instructsrsQ:NewTransmission(text, nil, self.instructmsrs, nil, 1, {player.client:GetGroup()}, text, 10)
    else
      self.instructor:NewTransmission( self.Sound.IRExitRange.filename, self.Sound.IRExitRange.duration, self.soundpath )
    end
  end

end

--- Function called after bomb impact on range.
-- @param #RANGE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #RANGE.BombResult result Result of bomb impact.
-- @param #RANGE.PlayerData player Player data table.
function RANGE:onafterImpact( From, Event, To, result, player )

  -- Only display target name if there is more than one bomb target.
  local targetname = nil
  if #self.bombingTargets > 1 then
    targetname = result.name
  end

  -- Send message to player.
  local text = string.format( "%s, impact %03d° for %d ft (%d m)", player.playername, result.radial, UTILS.MetersToFeet( result.distance ), result.distance )
  if targetname then
    text = text .. string.format( " from bulls of target %s.", targetname )
  else
    text = text .. "."
  end
  text = text .. string.format( " %s hit.", result.quality )

  if self.rangecontrol then

    if self.useSRS then
      local group = player.client:GetGroup()
      self.controlsrsQ:NewTransmission(text,nil,self.controlmsrs,nil,1,{group},text,10)
    else
      self.rangecontrol:NewTransmission( self.Sound.RCImpact.filename, self.Sound.RCImpact.duration, self.soundpath, nil, nil, text, self.subduration )
      self.rangecontrol:Number2Transmission( string.format( "%03d", result.radial ), nil, 0.1 )
      self.rangecontrol:NewTransmission( self.Sound.RCDegrees.filename, self.Sound.RCDegrees.duration, self.soundpath )
      self.rangecontrol:NewTransmission( self.Sound.RCFor.filename, self.Sound.RCFor.duration, self.soundpath )
      self.rangecontrol:Number2Transmission( string.format( "%d", UTILS.MetersToFeet( result.distance ) ) )
      self.rangecontrol:NewTransmission( self.Sound.RCFeet.filename, self.Sound.RCFeet.duration, self.soundpath )
      if result.quality == "POOR" then
        self.rangecontrol:NewTransmission( self.Sound.RCPoorHit.filename, self.Sound.RCPoorHit.duration, self.soundpath, nil, 0.5 )
      elseif result.quality == "INEFFECTIVE" then
        self.rangecontrol:NewTransmission( self.Sound.RCIneffectiveHit.filename, self.Sound.RCIneffectiveHit.duration, self.soundpath, nil, 0.5 )
      elseif result.quality == "GOOD" then
        self.rangecontrol:NewTransmission( self.Sound.RCGoodHit.filename, self.Sound.RCGoodHit.duration, self.soundpath, nil, 0.5 )
      elseif result.quality == "EXCELLENT" then
        self.rangecontrol:NewTransmission( self.Sound.RCExcellentHit.filename, self.Sound.RCExcellentHit.duration, self.soundpath, nil, 0.5 )
      end
    end
  end

  -- Unit.
  if player.unitname and not self.useSRS then

    -- Get unit.
    local unit = UNIT:FindByName( player.unitname )

    -- Send message.
      self:_DisplayMessageToGroup( unit, text, nil, true )
    self:T( self.lid .. text )
  end

  -- Save results.
  if self.autosave then
    self:Save()
  end

  -- Send result to FunkMan, which creates fancy MatLab figures and sends them to Discord via a bot.
  if self.funkmanSocket then
    self.funkmanSocket:SendTable(result)
  end

end

--- Function called after strafing run.
-- @param #RANGE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #RANGE.PlayerData player Player data table.
-- @param #RANGE.StrafeResult result Result of run.
function RANGE:onafterStrafeResult( From, Event, To, player, result)

  if self.funkmanSocket then
    self.funkmanSocket:SendTable(result)
  end

end

--- Function called before save event. Checks that io and lfs are desanitized.
-- @param #RANGE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function RANGE:onbeforeSave( From, Event, To )
  if io and lfs then
    return true
  else
    self:E( self.lid .. string.format( "WARNING: io and/or lfs not desanitized. Cannot save player results." ) )
    return false
  end
end

--- Function called after save.
-- @param #RANGE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function RANGE:onafterSave( From, Event, To )

  local function _savefile( filename, data )
    local f = io.open( filename, "wb" )
    if f then
      f:write( data )
      f:close()
      self:T( self.lid .. string.format( "Saving player results to file %s", tostring( filename ) ) )
    else
      self:E( self.lid .. string.format( "ERROR: Could not save results to file %s", tostring( filename ) ) )
    end
  end

  -- Path.
  local path = self.targetpath or lfs.writedir() .. [[Logs\]]

  -- Set file name.
  local filename = path .. string.format( "RANGE-%s_BombingResults.csv", self.rangename )

  -- Header line.
  local scores = "Name,Pass,Target,Distance,Radial,Quality,Weapon,Airframe,Mission Time"

  -- Loop over all players.
  for playername, results in pairs( self.bombPlayerResults ) do

    -- Loop over player grades table.
    for i, _result in pairs( results ) do
      local result = _result -- #RANGE.BombResult
      local distance = result.distance
      local weapon = result.weapon
      local target = result.name
      local radial = result.radial
      local quality = result.quality
      local time = UTILS.SecondsToClock(result.time, true)
      local airframe = result.airframe
      local date = result.date or "n/a"
      scores = scores .. string.format( "\n%s,%d,%s,%.2f,%03d,%s,%s,%s,%s,%s", playername, i, target, distance, radial, quality, weapon, airframe, time, date )
    end
  end

  _savefile( filename, scores )
end

--- Function called before save event. Checks that io and lfs are desanitized.
-- @param #RANGE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function RANGE:onbeforeLoad( From, Event, To )
  if io and lfs then
    return true
  else
    self:E( self.lid .. string.format( "WARNING: io and/or lfs not desanitized. Cannot load player results." ) )
    return false
  end
end

--- On after "Load" event. Loads results of all players from file.
-- @param #RANGE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function RANGE:onafterLoad( From, Event, To )

  --- Function that load data from a file.
  local function _loadfile( filename )
    local f = io.open( filename, "rb" )
    if f then
      -- self:I(self.lid..string.format("Loading player results from file %s", tostring(filename)))
      local data = f:read( "*all" )
      f:close()
      return data
    else
      self:E( self.lid .. string.format( "WARNING: Could not load player results from file %s. File might not exist just yet.", tostring( filename ) ) )
      return nil
    end
  end

  -- Path in DCS log file.
  local path = self.targetpath or lfs.writedir() .. [[Logs\]]

  -- Set file name.
  local filename = path .. string.format( "RANGE-%s_BombingResults.csv", self.rangename )

  -- Info message.
  local text = string.format( "Loading player bomb results from file %s", filename )
  self:T( self.lid .. text )

  -- Load asset data from file.
  local data = _loadfile( filename )

  if data then

    -- Split by line break.
    local results = UTILS.Split( data, "\n" )

    -- Remove first header line.
    table.remove( results, 1 )

    -- Init player scores table.
    self.bombPlayerResults = {}

    -- Loop over all lines.
    for _, _result in pairs( results ) do

      -- Parameters are separated by commata.
      local resultdata = UTILS.Split( _result, "," )

      -- Grade table
      local result = {} -- #RANGE.BombResult

      -- Player name.
      local playername = resultdata[1]
      result.player = playername

      -- Results data.
      result.name = tostring( resultdata[3] )
      result.distance = tonumber( resultdata[4] )
      result.radial = tonumber( resultdata[5] )
      result.quality = tostring( resultdata[6] )
      result.weapon = tostring( resultdata[7] )
      result.airframe = tostring( resultdata[8] )
      result.time = UTILS.ClockToSeconds( resultdata[9] or "00:00:00" )
      result.date = resultdata[10] or "n/a"

      -- Create player array if necessary.
      self.bombPlayerResults[playername] = self.bombPlayerResults[playername] or {}

      -- Add result to table.
      table.insert( self.bombPlayerResults[playername], result )
    end
  end
end

--- Save target sheet.
-- @param #RANGE self
-- @param #string _playername Player name.
-- @param #RANGE.StrafeResult result Results table.
function RANGE:_SaveTargetSheet( _playername, result ) -- RangeBoss Specific Function

  --- Function that saves data to file
  local function _savefile( filename, data )
    local f = io.open( filename, "wb" )
    if f then
      f:write( data )
      f:close()
    else
      env.info( "RANGEBOSS EDIT - could not save target sheet to file" )
      -- self:E(self.lid..string.format("ERROR: could not save target sheet to file %s.\nFile may contain invalid characters.", tostring(filename)))
    end
  end

  -- Set path or default.
  local path = self.targetpath
  if lfs then
    path = path or lfs.writedir() .. [[Logs\]]
  end

  -- Create unused file name.
  local filename = nil
  for i = 1, 9999 do

    -- Create file name
    if self.targetprefix then
      filename = string.format( "%s_%s-%04d.csv", self.targetprefix, result.airframe, i )
    else
      local name = UTILS.ReplaceIllegalCharacters( _playername, "_" )
      filename = string.format( "RANGERESULTS-%s_Targetsheet-%s-%04d.csv", self.rangename, name, i )
    end

    -- Set path.
    if path ~= nil then
      filename = path .. "\\" .. filename
    end

    -- Check if file exists.
    local _exists = UTILS.FileExists( filename )
    if not _exists then
      break
    end
  end

  -- Header line
  local data = "Name,Target,Rounds Fired,Rounds Hit,Rounds Quality,Airframe,Mission Time,OS Time\n"

  local target = result.name
  local airframe = result.airframe
  local roundsFired = result.roundsFired
  local roundsHit = result.roundsHit
  local strafeResult = result.roundsQuality
  local time = UTILS.SecondsToClock( result.time )
  local date = "n/a"
  if os then
    date = os.date()
  end
  data = data .. string.format( "%s,%s,%d,%d,%s,%s,%s,%s", _playername, target, roundsFired, roundsHit, strafeResult, airframe, time, date )

  -- Save file.
  _savefile( filename, data )
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Display Messages
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Start smoking a coordinate with a delay.
-- @param #table _args Argements passed.
function RANGE._DelayedSmoke( _args )
  _args.coord:Smoke(_args.color)
  --trigger.action.smoke( _args.coord:GetVec3(), _args.color )
end

--- Display top 10 stafing results of a specific player.
-- @param #RANGE self
-- @param #string _unitName Name of the player unit.
function RANGE:_DisplayMyStrafePitResults( _unitName )
  self:F( _unitName )

  -- Get player unit and name
  local _unit, _playername, _multiplayer = self:_GetPlayerUnitAndName( _unitName )

  if _unit and _playername then

    -- Message header.
    local _message = string.format( "My Top %d Strafe Pit Results:\n", self.ndisplayresult )

    -- Get player results.
    local _results = self.strafePlayerResults[_playername]

    -- Create message.
    if _results == nil then
      -- No score yet.
      _message = string.format( "%s: No Score yet.", _playername )
    else

      -- Sort results table wrt number of hits.
      local _sort = function( a, b )
        return a.roundsHit > b.roundsHit
      end
      table.sort( _results, _sort )

      -- Prepare message of best results.
      local _bestMsg = ""
      local _count = 1

      -- Loop over results
      for _, _result in pairs( _results ) do
        local result=_result --#RANGE.StrafeResult

        -- Message text.
        _message = _message .. string.format( "\n[%d] Hits %d - %s - %s", _count, result.roundsHit, result.name, result.roundsQuality )

        -- Best result.
        if _bestMsg == "" then
          _bestMsg = string.format( "Hits %d - %s - %s", result.roundsHit, result.name, result.roundsQuality)
        end

        -- 10 runs
        if _count == self.ndisplayresult then
          break
        end

        -- Increase counter
        _count = _count + 1
      end

      -- Message text.
      _message = _message .. "\n\nBEST: " .. _bestMsg
    end

    -- Send message to group.
    self:_DisplayMessageToGroup( _unit, _message, nil, true, true, _multiplayer )
  end
end

--- Display top 10 strafing results of all players.
-- @param #RANGE self
-- @param #string _unitName Name fo the player unit.
function RANGE:_DisplayStrafePitResults( _unitName )
  self:F( _unitName )

  -- Get player unit and name.
  local _unit, _playername, _multiplayer = self:_GetPlayerUnitAndName( _unitName )

  -- Check if we have a unit which is a player.
  if _unit and _playername then

    -- Results table.
    local _playerResults = {}

    -- Message text.
    local _message = string.format( "Strafe Pit Results - Top %d Players:\n", self.ndisplayresult )

    -- Loop over player results.
    for _playerName, _results in pairs( self.strafePlayerResults ) do

      -- Get the best result of the player.
      local _best = nil
      for _, _result in pairs( _results ) do
        if _best == nil or _result.roundsHit > _best.roundsHit then
          _best = _result
        end
      end

      -- Add best result to table.
      if _best ~= nil then
        local text = string.format( "%s: Hits %i - %s - %s", _playerName, _best.roundsHit, _best.name, _best.roundsQuality )
        table.insert( _playerResults, { msg = text, hits = _best.roundsHit } )
      end

    end

    -- Sort list!
    local _sort = function( a, b )
      return a.hits > b.hits
    end
    table.sort( _playerResults, _sort )

    -- Add top 10 results.
    for _i = 1, math.min( #_playerResults, self.ndisplayresult ) do
      _message = _message .. string.format( "\n[%d] %s", _i, _playerResults[_i].msg )
    end

    -- In case there are no scores yet.
    if #_playerResults < 1 then
      _message = _message .. "No player scored yet."
    end

    -- Send message.
    self:_DisplayMessageToGroup( _unit, _message, nil, true, true, _multiplayer )
  end
end

--- Display top 10 bombing run results of specific player.
-- @param #RANGE self
-- @param #string _unitName Name of the player unit.
function RANGE:_DisplayMyBombingResults( _unitName )
  self:F( _unitName )

  -- Get player unit and name.
  local _unit, _playername, _multiplayer = self:_GetPlayerUnitAndName( _unitName )

  if _unit and _playername then

    -- Init message.
    local _message = string.format( "My Top %d Bombing Results:\n", self.ndisplayresult )

    -- Results from player.
    local _results = self.bombPlayerResults[_playername]

    -- No score so far.
    if _results == nil then
      _message = _playername .. ": No Score yet."
    else

      -- Sort results wrt to distance.
      local _sort = function( a, b )
        return a.distance < b.distance
      end
      table.sort( _results, _sort )

      -- Loop over results.
      local _bestMsg = ""
      for i, _result in pairs( _results ) do
        local result = _result -- #RANGE.BombResult

        -- Message with name, weapon and distance.
        _message = _message .. "\n" .. string.format( "[%d] %d m %03d° - %s - %s - %s hit", i, result.distance, result.radial, result.name, result.weapon, result.quality )

        -- Store best/first result.
        if _bestMsg == "" then
          _bestMsg = string.format( "%d m %03d° - %s - %s - %s hit", result.distance, result.radial, result.name, result.weapon, result.quality )
        end

        -- Best 10 runs only.
        if i == self.ndisplayresult then
          break
        end

      end

      -- Message.
      _message = _message .. "\n\nBEST: " .. _bestMsg
    end

    -- Send message.
    self:_DisplayMessageToGroup( _unit, _message, nil, true, true, _multiplayer )
  end
end

--- Display best bombing results of top 10 players.
-- @param #RANGE self
-- @param #string _unitName Name of player unit.
function RANGE:_DisplayBombingResults( _unitName )
  self:F( _unitName )

  -- Results table.
  local _playerResults = {}

  -- Get player unit and name.
  local _unit, _player, _multiplayer = self:_GetPlayerUnitAndName( _unitName )

  -- Check if we have a unit with a player.
  if _unit and _player then

    -- Message header.
    local _message = string.format( "Bombing Results - Top %d Players:\n", self.ndisplayresult )

    -- Loop over players.
    for _playerName, _results in pairs( self.bombPlayerResults ) do

      -- Find best result of player.
      local _best = nil
      for _, _result in pairs( _results ) do
        if _best == nil or _result.distance < _best.distance then
          _best = _result
        end
      end

      -- Put best result of player into table.
      if _best ~= nil then
        local bestres = string.format( "%s: %d m - %s - %s - %s hit", _playerName, _best.distance, _best.name, _best.weapon, _best.quality )
        table.insert( _playerResults, { msg = bestres, distance = _best.distance } )
      end

    end

    -- Sort list of player results.
    local _sort = function( a, b )
      return a.distance < b.distance
    end
    table.sort( _playerResults, _sort )

    -- Loop over player results.
    for _i = 1, math.min( #_playerResults, self.ndisplayresult ) do
      _message = _message .. string.format( "\n[%d] %s", _i, _playerResults[_i].msg )
    end

    -- In case there are no scores yet.
    if #_playerResults < 1 then
      _message = _message .. "No player scored yet."
    end

    -- Send message.
    self:_DisplayMessageToGroup( _unit, _message, nil, true, true, _multiplayer )
  end
end

--- Report information like bearing and range from player unit to range.
-- @param #RANGE self
-- @param #string _unitname Name of the player unit.
function RANGE:_DisplayRangeInfo( _unitname )
  self:F( _unitname )

  -- Get player unit and player name.
  local unit, playername, _multiplayer = self:_GetPlayerUnitAndName( _unitname )

  -- Check if we have a player.
  if unit and playername then
    --self:I(playername)
    -- Message text.
    local text = ""

    -- Current coordinates.
    local coord = unit:GetCoordinate()

    if self.location then

      local settings = _DATABASE:GetPlayerSettings( playername ) or _SETTINGS -- Core.Settings#SETTINGS

      -- Direction vector from current position (coord) to target (position).
      local position = self.location -- Core.Point#COORDINATE
      local bulls = position:ToStringBULLS( unit:GetCoalition(), settings )
      local lldms = position:ToStringLLDMS( settings )
      local llddm = position:ToStringLLDDM( settings )
      local rangealt = position:GetLandHeight()
      local vec3 = coord:GetDirectionVec3( position )
      local angle = coord:GetAngleDegrees( vec3 )
      local range = coord:Get2DDistance( position )

      -- Bearing string.
      local Bs = string.format( '%03d°', angle )

      local texthit
      if self.PlayerSettings[playername].flaredirecthits then
        texthit = string.format( "Flare direct hits: ON (flare color %s)\n", self:_flarecolor2text( self.PlayerSettings[playername].flarecolor ) )
      else
        texthit = string.format( "Flare direct hits: OFF\n" )
      end
      local textbomb
      if self.PlayerSettings[playername].smokebombimpact then
        textbomb = string.format( "Smoke bomb impact points: ON (smoke color %s)\n", self:_smokecolor2text( self.PlayerSettings[playername].smokecolor ) )
      else
        textbomb = string.format( "Smoke bomb impact points: OFF\n" )
      end
      local textdelay
      if self.PlayerSettings[playername].delaysmoke then
        textdelay = string.format( "Smoke bomb delay: ON (delay %.1f seconds)", self.TdelaySmoke )
      else
        textdelay = string.format( "Smoke bomb delay: OFF" )
      end

      -- Player unit settings.
      local trange = string.format( "%.1f km", range / 1000 )
      local trangealt = string.format( "%d m", rangealt )
      local tstrafemaxalt = string.format( "%d m", self.strafemaxalt )
      if settings:IsImperial() then
        trange = string.format( "%.1f NM", UTILS.MetersToNM( range ) )
        trangealt = string.format( "%d feet", UTILS.MetersToFeet( rangealt ) )
        tstrafemaxalt = string.format( "%d feet", UTILS.MetersToFeet( self.strafemaxalt ) )
      end

      -- Message.
      text = text .. string.format( "Information on %s:\n", self.rangename )
      text = text .. string.format( "-------------------------------------------------------\n" )
      text = text .. string.format( "Bearing %s, Range %s\n", Bs, trange )
      text = text .. string.format( "%s\n", bulls )
      text = text .. string.format( "%s\n", lldms )
      text = text .. string.format( "%s\n", llddm )
      text = text .. string.format( "Altitude ASL: %s\n", trangealt )
      text = text .. string.format( "Max strafing alt AGL: %s\n", tstrafemaxalt )
      text = text .. string.format( "# of strafe targets: %d\n", self.nstrafetargets )
      text = text .. string.format( "# of bomb targets: %d\n", self.nbombtargets )
      if self.instructor then
        local alive = "N/A"
        if self.instructorrelayname then
          local relay = UNIT:FindByName( self.instructorrelayname )
          if relay then
            --alive = tostring( relay:IsAlive() )
            alive = relay:IsAlive() and "ok" or "N/A"
          end
        end
        text = text .. string.format( "Instructor %.3f MHz (Relay=%s)\n", self.instructorfreq, alive )
      end
      if self.rangecontrol then
        local alive = "N/A"
        if self.rangecontrolrelayname then
          local relay = UNIT:FindByName( self.rangecontrolrelayname )
          if relay then
            alive = tostring( relay:IsAlive() )
            alive = relay:IsAlive() and "ok" or "N/A"
          end
        end
        text = text .. string.format( "Control %.3f MHz (Relay=%s)\n", self.rangecontrolfreq, alive )
      end
      text = text .. texthit
      text = text .. textbomb
      text = text .. textdelay

      -- Send message to player group.
      self:_DisplayMessageToGroup( unit, text, nil, true, true, _multiplayer )

      -- Debug output.
      self:T2( self.lid .. text )
    end
  end
end

--- Display bombing target locations to player.
-- @param #RANGE self
-- @param #string _unitname Name of the player unit.
function RANGE:_DisplayBombTargets( _unitname )
  self:F( _unitname )

  -- Get player unit and player name.
  local _unit, _playername, _multiplayer = self:_GetPlayerUnitAndName( _unitname )

  -- Check if we have a player.
  if _unit and _playername then

    -- Player settings.
    local _settings = _DATABASE:GetPlayerSettings( _playername ) or _SETTINGS -- Core.Settings#SETTINGS

    -- Message text.
    local _text = "Bomb Target Locations:"

    for _, _bombtarget in pairs( self.bombingTargets ) do
      local bombtarget = _bombtarget -- #RANGE.BombTarget

      -- Coordinate of bombtarget.
      local coord = self:_GetBombTargetCoordinate( bombtarget )

      if coord then

        -- Get elevation
        local elevation = coord:GetLandHeight()
        local eltxt = string.format( "%d m", elevation )
        if not _settings:IsMetric() then
          elevation = UTILS.MetersToFeet( elevation )
          eltxt = string.format( "%d ft", elevation )
        end

        local ca2g = coord:ToStringA2G( _unit, _settings )
        _text = _text .. string.format( "\n- %s:\n%s @ %s", bombtarget.name or "unknown", ca2g, eltxt )
      end
    end

    self:_DisplayMessageToGroup( _unit, _text, 150, true, true, _multiplayer )
  end
end

--- Display pit location and heading to player.
-- @param #RANGE self
-- @param #string _unitname Name of the player unit.
function RANGE:_DisplayStrafePits( _unitname )
  self:F( _unitname )

  -- Get player unit and player name.
  local _unit, _playername, _multiplayer = self:_GetPlayerUnitAndName( _unitname )

  -- Check if we have a player.
  if _unit and _playername then

    -- Player settings.
    local _settings = _DATABASE:GetPlayerSettings( _playername ) or _SETTINGS -- Core.Settings#SETTINGS

    -- Message text.
    local _text = "Strafe Target Locations:"

    for _, _strafepit in pairs( self.strafeTargets ) do
      local _target = _strafepit -- Wrapper.Positionable#POSITIONABLE

      -- Pit parameters.
      local coord = _strafepit.coordinate -- Core.Point#COORDINATE
      local heading = _strafepit.heading

      -- Turn heading around ==> approach heading.
      if heading > 180 then
        heading = heading - 180
      else
        heading = heading + 180
      end

      local mycoord = coord:ToStringA2G( _unit, _settings )
      _text = _text .. string.format( "\n- %s: heading %03d°\n%s", _strafepit.name, heading, mycoord )
    end

    self:_DisplayMessageToGroup( _unit, _text, nil, true, true, _multiplayer )
  end
end

--- Report weather conditions at range. Temperature, QFE pressure and wind data.
-- @param #RANGE self
-- @param #string _unitname Name of the player unit.
function RANGE:_DisplayRangeWeather( _unitname )
  self:F( _unitname )

  -- Get player unit and player name.
  local unit, playername, _multiplayer = self:_GetPlayerUnitAndName( _unitname )

  -- Check if we have a player.
  if unit and playername then

    -- Message text.
    local text = ""

    -- Current coordinates.
    local coord = unit:GetCoordinate()

    if self.location then

      -- Get atmospheric data at range location.
      local position = self.location -- Core.Point#COORDINATE
      local T = position:GetTemperature()
      local P = position:GetPressure()
      local Wd, Ws = position:GetWind()

      -- Get Beaufort wind scale.
      local Bn, Bd = UTILS.BeaufortScale( Ws )

      local WD = string.format( '%03d°', Wd )
      local Ts = string.format( "%d°C", T )

      local hPa2inHg = 0.0295299830714
      local hPa2mmHg = 0.7500615613030

      local settings = _DATABASE:GetPlayerSettings( playername ) or _SETTINGS -- Core.Settings#SETTINGS
      local tT = string.format( "%d°C", T )
      local tW = string.format( "%.1f m/s", Ws )
      local tP = string.format( "%.1f mmHg", P * hPa2mmHg )
      if settings:IsImperial() then
        -- tT=string.format("%d°F", UTILS.CelsiusToFahrenheit(T))
        tW = string.format( "%.1f knots", UTILS.MpsToKnots( Ws ) )
        tP = string.format( "%.2f inHg", P * hPa2inHg )
      end

      -- Message text.
      text = text .. string.format( "Weather Report at %s:\n", self.rangename )
      text = text .. string.format( "--------------------------------------------------\n" )
      text = text .. string.format( "Temperature %s\n", tT )
      text = text .. string.format( "Wind from %s at %s (%s)\n", WD, tW, Bd )
      text = text .. string.format( "QFE %.1f hPa = %s", P, tP )
    else
      text = string.format( "No range location defined for range %s.", self.rangename )
    end

    -- Send message to player group.
    self:_DisplayMessageToGroup( unit, text, nil, true, true, _multiplayer )

    -- Debug output.
    self:T2( self.lid .. text )
  else
    self:T( self.lid .. string.format( "ERROR! Could not find player unit in RangeInfo! Name = %s", _unitname ) )
  end
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Timer Functions

--- Check status of players.
-- @param #RANGE self
-- @param #string _unitName Name of player unit.
function RANGE:_CheckPlayers()

  for playername, _playersettings in pairs( self.PlayerSettings ) do
    local playersettings = _playersettings -- #RANGE.PlayerData

    local unitname = playersettings.unitname
    local unit = UNIT:FindByName( unitname )

    if unit and unit:IsAlive() then

      if unit:IsInZone( self.rangezone ) then

        ------------------------------
        -- Player INSIDE Range Zone --
        ------------------------------

        if not playersettings.inzone then
          playersettings.inzone = true
          self:EnterRange( playersettings )
        end

      else

        -------------------------------
        -- Player OUTSIDE Range Zone --
        -------------------------------

        if playersettings.inzone == true then
          playersettings.inzone = false
          self:ExitRange( playersettings )
        end

      end
    end
  end

end

--- Check if player is inside a strafing zone. If he is, we start looking for hits. If he was and left the zone again, the result is stored.
-- @param #RANGE self
-- @param #string _unitName Name of player unit.
function RANGE:_CheckInZone( _unitName )
  self:F2( _unitName )

  -- Get player unit and name.
  local _unit, _playername = self:_GetPlayerUnitAndName( _unitName )
  local unitheading = 0 -- RangeBoss

  if _unit and _playername then

    -- Player data.
    local playerData=self.PlayerSettings[_playername] -- #RANGE.PlayerData

    --- Function to check if unit is in zone and facing in the right direction and is below the max alt.
    local function checkme( targetheading, _zone )
      local zone = _zone -- Core.Zone#ZONE

      -- Heading check.
      local unitheading = _unit:GetHeading()
      local pitheading = targetheading - 180
      local deltaheading = unitheading - pitheading
      local towardspit = math.abs( deltaheading ) <= 90 or math.abs( deltaheading - 360 ) <= 90

      if towardspit then

        local vec3 = _unit:GetVec3()
        local vec2 = { x = vec3.x, y = vec3.z } -- DCS#Vec2
        local landheight = land.getHeight( vec2 )
        local unitalt = vec3.y - landheight

        if unitalt <= self.strafemaxalt then
          local unitinzone = zone:IsVec2InZone( vec2 )
          return unitinzone
        end
      end

      return false
    end

    -- Current position of player unit.
    local _unitID = _unit:GetID()

    -- Currently strafing? (strafeStatus is nil if not)
    local _currentStrafeRun = self.strafeStatus[_unitID] --#RANGE.StrafeStatus

    if _currentStrafeRun then -- player has already registered for a strafing run.

      -- Get the current approach zone and check if player is inside.
      local zone = _currentStrafeRun.zone.polygon -- Core.Zone#ZONE_POLYGON_BASE

      -- Check if unit in zone and facing the right direction.
      local unitinzone = checkme( _currentStrafeRun.zone.heading, zone )

      -- Check if player is in strafe zone and below max alt.
      if unitinzone then
        -- Still in zone, keep counting hits. Increase counter.
        _currentStrafeRun.time = _currentStrafeRun.time + 1

      else

        -- Increase counter
        _currentStrafeRun.time = _currentStrafeRun.time + 1

        if _currentStrafeRun.time <= 3 then

          -- Reset current run.
          self.strafeStatus[_unitID] = nil

          -- Message text.
          local _msg = string.format( "%s left strafing zone %s too quickly. No Score.", _playername, _currentStrafeRun.zone.name )

          -- Send message.
          self:_DisplayMessageToGroup( _unit, _msg, nil, true )

          if self.rangecontrol then
            if self.useSRS then
              local group = _unit:GetGroup()
              local text = "You left the strafing zone too quickly! No score!"
              --self.controlsrsQ:NewTransmission(text,nil,self.controlmsrs,nil,1,{group},text,10)
              self.controlsrsQ:NewTransmission(text,nil,self.controlmsrs,nil,1)
            else
              -- You left the strafing zone too quickly! No score!
              self.rangecontrol:NewTransmission( self.Sound.RCLeftStrafePitTooQuickly.filename, self.Sound.RCLeftStrafePitTooQuickly.duration, self.soundpath )
            end
          end
        else

          -- Get current ammo.
          local _ammo = self:_GetAmmo( _unitName )

          -- Result.
          local _result = self.strafeStatus[_unitID] --#RANGE.StrafeStatus

          local _sound = nil -- #RANGE.Soundfile

          -- Calculate accuracy of run. Number of hits wrt number of rounds fired.
          local shots = _result.ammo - _ammo
          local accur = 0
          if shots > 0 then
            accur = _result.hits / shots * 100
            if accur > 100 then
              accur = 100
            end
          end

          -- Results text and sound message.
          local resulttext=""
          if _result.pastfoulline == true then --
            resulttext = "* INVALID - PASSED FOUL LINE *"
            _sound = self.Sound.RCPoorPass --
          else
            if accur >= 90 then
              resulttext = "DEADEYE PASS"
              _sound = self.Sound.RCExcellentPass
            elseif accur >= 75 then
              resulttext = "EXCELLENT PASS"
              _sound = self.Sound.RCExcellentPass
            elseif accur >= 50 then
              resulttext = "GOOD PASS"
              _sound = self.Sound.RCGoodPass
            elseif accur >= 25 then
              resulttext = "INEFFECTIVE PASS"
              _sound = self.Sound.RCIneffectivePass
            else
              resulttext = "POOR PASS"
              _sound = self.Sound.RCPoorPass
            end
          end

          -- Message text.
          local _text = string.format( "%s, hits on target %s: %d", self:_myname( _unitName ), _result.zone.name, _result.hits )
          local ttstext = string.format( "%s, hits on target %s: %d.", self:_myname( _unitName ), _result.zone.name, _result.hits )
          if shots and accur then
            _text = _text .. string.format( "\nTotal rounds fired %d. Accuracy %.1f %%.", shots, accur )
            ttstext = ttstext .. string.format( ". Total rounds fired %d. Accuracy %.1f percent.", shots, accur )
          end
          _text = _text .. string.format( "\n%s", resulttext )
          ttstext = ttstext .. string.format( " %s", resulttext )

          -- Send message.
          self:_DisplayMessageToGroup( _unit, _text )

          -- Strafe result.
          local result = {} -- #RANGE.StrafeResult
          result.command=SOCKET.DataType.STRAFERESULT
          result.player=_playername
          result.name=_result.zone.name or "unknown"
          result.time = timer.getAbsTime()
          result.clock = UTILS.SecondsToClock(result.time)
          result.midate = UTILS.GetDCSMissionDate()
          result.theatre = env.mission.theatre
          result.roundsFired = shots
          result.roundsHit = _result.hits
          result.roundsQuality = resulttext
          result.strafeAccuracy = accur
          result.rangename = self.rangename
          result.airframe=playerData.airframe
          result.invalid = _result.pastfoulline

          -- Griger Results.
          self:StrafeResult(playerData, result)

          -- Save trap sheet.
          if playerData and playerData.targeton and self.targetsheet then
            self:_SaveTargetSheet( _playername, result )
          end

          -- Voice over.
          if self.rangecontrol then
            if self.useSRS then
              self.controlsrsQ:NewTransmission(ttstext,nil,self.controlmsrs,nil,1)
            else
              self.rangecontrol:NewTransmission( self.Sound.RCHitsOnTarget.filename, self.Sound.RCHitsOnTarget.duration, self.soundpath )
              self.rangecontrol:Number2Transmission( string.format( "%d", _result.hits ) )
              if shots and accur then
                self.rangecontrol:NewTransmission( self.Sound.RCTotalRoundsFired.filename, self.Sound.RCTotalRoundsFired.duration, self.soundpath, nil, 0.2 )
                self.rangecontrol:Number2Transmission( string.format( "%d", shots ), nil, 0.2 )
                self.rangecontrol:NewTransmission( self.Sound.RCAccuracy.filename, self.Sound.RCAccuracy.duration, self.soundpath, nil, 0.2 )
                self.rangecontrol:Number2Transmission( string.format( "%d", UTILS.Round( accur, 0 ) ) )
                self.rangecontrol:NewTransmission( self.Sound.RCPercent.filename, self.Sound.RCPercent.duration, self.soundpath )
              end
              self.rangecontrol:NewTransmission( _sound.filename, _sound.duration, self.soundpath, nil, 0.5 )
            end
          end

          -- Set strafe status to nil.
          self.strafeStatus[_unitID] = nil

          -- Save stats so the player can retrieve them.
          local _stats = self.strafePlayerResults[_playername] or {}
          table.insert( _stats, result )
          self.strafePlayerResults[_playername] = _stats
        end

      end

    else

      -- Check to see if we're in any of the strafing zones (first time).
      for _, _targetZone in pairs( self.strafeTargets ) do
        local target=_targetZone --#RANGE.StrafeTarget

        -- Get the current approach zone and check if player is inside.
        local zone = target.polygon -- Core.Zone#ZONE_POLYGON_BASE

        -- Check if unit in zone and facing the right direction.
        local unitinzone = checkme( target.heading, zone )

        -- Player is inside zone.
        if unitinzone then

          -- Get ammo at the beginning of the run.
          local _ammo = self:_GetAmmo( _unitName )

          -- Init strafe status for this player.
          self.strafeStatus[_unitID] = { hits = 0, zone = target, time = 1, ammo = _ammo, pastfoulline = false }

          -- Rolling in!
          local _msg = string.format( "%s, rolling in on strafe pit %s.", self:_myname( _unitName ), target.name )

          if self.rangecontrol then
            if self.useSRS then
              self.controlsrsQ:NewTransmission(_msg,nil,self.controlmsrs,nil,1)
            else
              self.rangecontrol:NewTransmission( self.Sound.RCRollingInOnStrafeTarget.filename, self.Sound.RCRollingInOnStrafeTarget.duration, self.soundpath )
            end
          end

          -- Send message.
          self:_DisplayMessageToGroup( _unit, _msg, 10, true )

          -- Trigger event that player is rolling in.
          self:RollingIn(playerData, target)

          -- We found our player. Skip remaining checks.
          break

        end -- unit in zone check

      end -- loop over zones
    end
  end

end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Menu Functions
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Add menu commands for player.
-- @param #RANGE self
-- @param #string _unitName Name of player unit.
function RANGE:_AddF10Commands( _unitName )
  self:F( _unitName )

  -- Get player unit and name.
  local _unit, playername = self:_GetPlayerUnitAndName( _unitName )

  -- Check for player unit.
  if _unit and playername then

    -- Get group and ID.
    local group = _unit:GetGroup()
    local _gid = group:GetID()

    if group and _gid then

      if not self.MenuAddedTo[_gid] then

        -- Enable switch so we don't do this twice.
        self.MenuAddedTo[_gid] = true

        -- Range root menu path.
        local _rootMenu = nil

        if self.menuF10root then
        
          -------------------
          -- MISSION LEVEL --
          -------------------        
        
          --_rootMenu = MENU_GROUP:New( group, self.rangename, self.menuF10root )
          _rootMenu = self.menuF10root
          self:T2(self.lid..string.format("Creating F10 menu for group %s", group:GetName()))

        elseif RANGE.MenuF10Root then

          -- Main F10 menu: F10/<RANGE.MenuF10Root>/<Range Name>
          --_rootMenu = MENU_GROUP:New( group, self.rangename, RANGE.MenuF10Root )
          _rootMenu = RANGE.MenuF10Root

        else

          -----------------
          -- GROUP LEVEL --
          -----------------

          -- Main F10 menu: F10/On the Range/<Range Name>/
          if RANGE.MenuF10[_gid] == nil then
            self:T2(self.lid..string.format("Creating F10 menu 'On the Range' for group %s", group:GetName()))
          else
            self:T2(self.lid..string.format("F10 menu 'On the Range' already EXISTS for group %s", group:GetName()))
          end
          
          _rootMenu=RANGE.MenuF10[_gid] or MENU_GROUP:New( group, "On the Range" )
                    
        end
        
        -- Range menu
        local _rangePath = MENU_GROUP:New( group, self.rangename, _rootMenu )

        local _infoPath = MENU_GROUP:New( group, "Range Info", _rangePath )
        local _markPath = MENU_GROUP:New( group, "Mark Targets", _rangePath )
        local _statsPath = MENU_GROUP:New( group, "Statistics", _rangePath )
        local _settingsPath = MENU_GROUP:New( group, "My Settings", _rangePath )

        -- F10/On the Range/<Range Name>/My Settings/
        local _mysmokePath = MENU_GROUP:New( group, "Smoke Color", _settingsPath )
        local _myflarePath = MENU_GROUP:New( group, "Flare Color", _settingsPath )

        -- F10/On the Range/<Range Name>/Mark Targets/
        local _MoMap = MENU_GROUP_COMMAND:New( group, "Mark On Map", _markPath, self._MarkTargetsOnMap, self, _unitName )
        local _IllRng = MENU_GROUP_COMMAND:New( group, "Illuminate Range", _markPath, self._IlluminateBombTargets, self, _unitName )
        local _SSpit = MENU_GROUP_COMMAND:New( group, "Smoke Strafe Pits", _markPath, self._SmokeStrafeTargetBoxes, self, _unitName )
        local _SStgts = MENU_GROUP_COMMAND:New( group, "Smoke Strafe Tgts", _markPath, self._SmokeStrafeTargets, self, _unitName )
        local _SBtgts = MENU_GROUP_COMMAND:New( group, "Smoke Bomb Tgts", _markPath, self._SmokeBombTargets, self, _unitName )
        -- F10/On the Range/<Range Name>/Stats/
        local _AllSR = MENU_GROUP_COMMAND:New( group, "All Strafe Results", _statsPath, self._DisplayStrafePitResults, self, _unitName )
        local _AllBR = MENU_GROUP_COMMAND:New( group, "All Bombing Results", _statsPath, self._DisplayBombingResults, self, _unitName )
        local _MySR = MENU_GROUP_COMMAND:New( group, "My Strafe Results", _statsPath, self._DisplayMyStrafePitResults, self, _unitName )
        local _MyBR = MENU_GROUP_COMMAND:New( group, "My Bomb Results", _statsPath, self._DisplayMyBombingResults, self, _unitName )
        local _ResetST = MENU_GROUP_COMMAND:New( group, "Reset All Stats", _statsPath, self._ResetRangeStats, self, _unitName )
        -- F10/On the Range/<Range Name>/My Settings/Smoke Color/
        local _BlueSM = MENU_GROUP_COMMAND:New( group, "Blue Smoke", _mysmokePath, self._playersmokecolor, self, _unitName, SMOKECOLOR.Blue )
        local _GrSM = MENU_GROUP_COMMAND:New( group, "Green Smoke", _mysmokePath, self._playersmokecolor, self, _unitName, SMOKECOLOR.Green )
        local _OrSM = MENU_GROUP_COMMAND:New( group, "Orange Smoke", _mysmokePath, self._playersmokecolor, self, _unitName, SMOKECOLOR.Orange )
        local _ReSM = MENU_GROUP_COMMAND:New( group, "Red Smoke", _mysmokePath, self._playersmokecolor, self, _unitName, SMOKECOLOR.Red )
        local _WhSm = MENU_GROUP_COMMAND:New( group, "White Smoke", _mysmokePath, self._playersmokecolor, self, _unitName, SMOKECOLOR.White )
        -- F10/On the Range/<Range Name>/My Settings/Flare Color/
        local _GrFl = MENU_GROUP_COMMAND:New( group, "Green Flares", _myflarePath, self._playerflarecolor, self, _unitName, FLARECOLOR.Green )
        local _ReFl = MENU_GROUP_COMMAND:New( group, "Red Flares", _myflarePath, self._playerflarecolor, self, _unitName, FLARECOLOR.Red )
        local _WhFl = MENU_GROUP_COMMAND:New( group, "White Flares", _myflarePath, self._playerflarecolor, self, _unitName, FLARECOLOR.White )
        local _YeFl = MENU_GROUP_COMMAND:New( group, "Yellow Flares", _myflarePath, self._playerflarecolor, self, _unitName, FLARECOLOR.Yellow )
        -- F10/On the Range/<Range Name>/My Settings/
        local _SmDe = MENU_GROUP_COMMAND:New( group, "Smoke Delay On/Off", _settingsPath, self._SmokeBombDelayOnOff, self, _unitName )
        local _SmIm = MENU_GROUP_COMMAND:New( group, "Smoke Impact On/Off", _settingsPath, self._SmokeBombImpactOnOff, self, _unitName )
        local _FlHi = MENU_GROUP_COMMAND:New( group, "Flare Hits On/Off", _settingsPath, self._FlareDirectHitsOnOff, self, _unitName )
        local _AlMeA = MENU_GROUP_COMMAND:New( group, "All Messages On/Off", _settingsPath, self._MessagesToPlayerOnOff, self, _unitName )
        local _TrpSh = MENU_GROUP_COMMAND:New( group, "Targetsheet On/Off", _settingsPath, self._TargetsheetOnOff, self, _unitName )

        -- F10/On the Range/<Range Name>/Range Information
        local _WeIn = MENU_GROUP_COMMAND:New( group, "General Info", _infoPath, self._DisplayRangeInfo, self, _unitName )
        local _WeRe = MENU_GROUP_COMMAND:New( group, "Weather Report", _infoPath, self._DisplayRangeWeather, self, _unitName )
        local _BoTgtgs = MENU_GROUP_COMMAND:New( group, "Bombing Targets", _infoPath, self._DisplayBombTargets, self, _unitName )
        local _StrPits = MENU_GROUP_COMMAND:New( group, "Strafe Pits", _infoPath, self._DisplayStrafePits, self, _unitName ):Refresh()
      end
    else
      self:E( self.lid .. "Could not find group or group ID in AddF10Menu() function. Unit name: " .. _unitName or "N/A")
    end
  else
    self:E( self.lid .. "Player unit does not exist in AddF10Menu() function. Unit name: " .. _unitName or "N/A")
  end

end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Helper Functions
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get the number of shells a unit currently has.
-- @param #RANGE self
-- @param #RANGE.BombTarget target Bomb target data.
-- @return Core.Point#COORDINATE Target coordinate.
function RANGE:_GetBombTargetCoordinate( target )

  local coord = nil -- Core.Point#COORDINATE

  if target.type == RANGE.TargetType.UNIT then

    -- Check if alive
    if target.target and target.target:IsAlive() then
      -- Get current position.
      coord = target.target:GetCoordinate()
      -- Save as last known position in case target dies.
      target.coordinate=coord
    else
      -- Use stored position.
      coord = target.coordinate
    end

  elseif target.type == RANGE.TargetType.STATIC then

    -- Static targets dont move.
    coord = target.coordinate

  elseif target.type == RANGE.TargetType.COORD then

    -- Coordinates dont move.
    coord = target.coordinate

  elseif target.type == RANGE.TargetType.SCENERY then

    -- Coordinates dont move.
    coord = target.coordinate

  else
    self:E( self.lid .. "ERROR: Unknown target type." )
  end

  return coord
end

--- Get the number of shells a unit currently has.
-- @param #RANGE self
-- @param #string unitname Name of the player unit.
-- @return Number of shells left
function RANGE:_GetAmmo( unitname )
  self:F2( unitname )

  -- Init counter.
  local ammo = 0

  local unit, playername = self:_GetPlayerUnitAndName( unitname )

  if unit and playername then

    local has_ammo = false

    local ammotable = unit:GetAmmo()
    self:T2( { ammotable = ammotable } )

    if ammotable ~= nil then

      local weapons = #ammotable
      self:T2( self.lid .. string.format( "Number of weapons %d.", weapons ) )

      for w = 1, weapons do

        local Nammo = ammotable[w]["count"]
        local Tammo = ammotable[w]["desc"]["typeName"]

        -- We are specifically looking for shells here.
        if string.match( Tammo, "shell" ) then

          -- Add up all shells
          ammo = ammo + Nammo

          local text = string.format( "Player %s has %d rounds ammo of type %s", playername, Nammo, Tammo )
          self:T( self.lid .. text )
        else
          local text = string.format( "Player %s has %d ammo of type %s", playername, Nammo, Tammo )
          self:T( self.lid .. text )
        end
      end
    end
  end

  return ammo
end

--- Mark targets on F10 map.
-- @param #RANGE self
-- @param #string _unitName Name of the player unit.
function RANGE:_MarkTargetsOnMap( _unitName )
  self:F( _unitName )

  -- Get group.
  local group = nil -- Wrapper.Group#GROUP
  if _unitName then
    group = UNIT:FindByName( _unitName ):GetGroup()
  end

  -- Mark bomb targets.
  for _, _bombtarget in pairs( self.bombingTargets ) do
    local bombtarget = _bombtarget -- #RANGE.BombTarget
    local coord = self:_GetBombTargetCoordinate( _bombtarget )
    if group then
      coord:MarkToGroup( string.format( "Bomb target %s:\n%s\n%s", bombtarget.name, coord:ToStringLLDMS(), coord:ToStringBULLS( group:GetCoalition() ) ), group )
    else
      coord:MarkToAll( string.format( "Bomb target %s", bombtarget.name ) )
    end
  end

  -- Mark strafe targets.
  for _, _strafepit in pairs( self.strafeTargets ) do
    for _, _target in pairs( _strafepit.targets ) do
      local _target = _target -- Wrapper.Positionable#POSITIONABLE
      if _target and _target:IsAlive() then
        local coord = _target:GetCoordinate() -- Core.Point#COORDINATE
        if group then
          -- coord:MarkToGroup("Strafe target ".._target:GetName(), group)
          coord:MarkToGroup( string.format( "Strafe target %s:\n%s\n%s", _target:GetName(), coord:ToStringLLDMS(), coord:ToStringBULLS( group:GetCoalition() ) ), group )
        else
          coord:MarkToAll( "Strafe target " .. _target:GetName() )
        end
      end
    end
  end

  if _unitName then
    local _unit, _playername = self:_GetPlayerUnitAndName( _unitName )
    local text = string.format( "%s, %s, range targets are now marked on F10 map.", self.rangename, _playername )
    self:_DisplayMessageToGroup( _unit, text, 5 )
  end

end

--- Illuminate targets. Fires illumination bombs at one random bomb and one random strafe target at a random altitude between 400 and 800 m.
-- @param #RANGE self
-- @param #string _unitName (Optional) Name of the player unit.
function RANGE:_IlluminateBombTargets( _unitName )
  self:F( _unitName )

  -- All bombing target coordinates.
  local bomb = {}

  for _, _bombtarget in pairs( self.bombingTargets ) do
    local _target = _bombtarget.target -- Wrapper.Positionable#POSITIONABLE
    local coord = self:_GetBombTargetCoordinate( _bombtarget )
    if coord then
      table.insert( bomb, coord )
    end
  end

  if #bomb > 0 then
    local coord = bomb[math.random( #bomb )] -- Core.Point#COORDINATE
    local c = COORDINATE:New( coord.x, coord.y + math.random( self.illuminationminalt, self.illuminationmaxalt ), coord.z )
    c:IlluminationBomb()
  end

  -- All strafe target coordinates.
  local strafe = {}

  for _, _strafepit in pairs( self.strafeTargets ) do
    for _, _target in pairs( _strafepit.targets ) do
      local _target = _target -- Wrapper.Positionable#POSITIONABLE
      if _target and _target:IsAlive() then
        local coord = _target:GetCoordinate() -- Core.Point#COORDINATE
        table.insert( strafe, coord )
      end
    end
  end

  -- Pick a random strafe target.
  if #strafe > 0 then
    local coord = strafe[math.random( #strafe )] -- Core.Point#COORDINATE
    local c = COORDINATE:New( coord.x, coord.y + math.random( self.illuminationminalt, self.illuminationmaxalt ), coord.z )
    c:IlluminationBomb()
  end

  if _unitName then
    local _unit, _playername = self:_GetPlayerUnitAndName( _unitName )
    local text = string.format( "%s, %s, range targets are illuminated.", self.rangename, _playername )
    self:_DisplayMessageToGroup( _unit, text, 5 )
  end
end

--- Reset player statistics.
-- @param #RANGE self
-- @param #string _unitName Name of the player unit.
function RANGE:_ResetRangeStats( _unitName )
  self:F( _unitName )

  -- Get player unit and name.
  local _unit, _playername = self:_GetPlayerUnitAndName( _unitName )

  if _unit and _playername then
    self.strafePlayerResults[_playername] = nil
    self.bombPlayerResults[_playername] = nil
    local text = string.format( "%s, %s, your range stats were cleared.", self.rangename, _playername )
    self:DisplayMessageToGroup( _unit, text, 5, false, true )
  end
end

--- Display message to group.
-- @param #RANGE self
-- @param Wrapper.Unit#UNIT _unit Player unit.
-- @param #string _text Message text.
-- @param #number _time Duration how long the message is displayed.
-- @param #boolean _clear Clear up old messages.
-- @param #boolean display If true, display message regardless of player setting "Messages Off".
-- @param #boolean _togroup If true, display the message to the group in any case
function RANGE:_DisplayMessageToGroup( _unit, _text, _time, _clear, display, _togroup )
  self:F( { unit = _unit, text = _text, time = _time, clear = _clear } )

  -- Defaults
  _time = _time or self.Tmsg
  if _clear == nil or _clear == false then
    _clear = false
  else
    _clear = true
  end

  -- Messages globally disabled.
  if self.messages == false then
    return
  end

  -- Check if unit is alive.
  if _unit and _unit:IsAlive() then

    -- Group ID.
    local _gid = _unit:GetGroup():GetID()
    local _grp = _unit:GetGroup()

    -- Get playername and player settings
    local _, playername = self:_GetPlayerUnitAndName( _unit:GetName() )
    local playermessage = self.PlayerSettings[playername].messages

    -- Send message to player if messages enabled and not only for the examiner.

    if _gid and (playermessage == true or display) and (not self.examinerexclusive) then
      if _togroup and _grp then
        local m = MESSAGE:New(_text,_time,nil,_clear):ToGroup(_grp)
      else
        local m = MESSAGE:New(_text,_time,nil,_clear):ToUnit(_unit)
      end
    end

    -- Send message to examiner.
    if self.examinergroupname ~= nil then
      local _examinerid = GROUP:FindByName( self.examinergroupname )
      if _examinerid then
        local m = MESSAGE:New(_text,_time,nil,_clear):ToGroup(_examinerid)
      end
    end
  end

end

--- Toggle status of smoking bomb impact points.
-- @param #RANGE self
-- @param #string unitname Name of the player unit.
function RANGE:_SmokeBombImpactOnOff( unitname )
  self:F( unitname )

  local unit, playername, _multiplayer = self:_GetPlayerUnitAndName( unitname )
  if unit and playername then
    local text
    if self.PlayerSettings[playername].smokebombimpact == true then
      self.PlayerSettings[playername].smokebombimpact = false
      text = string.format( "%s, %s, smoking impact points of bombs is now OFF.", self.rangename, playername )
    else
      self.PlayerSettings[playername].smokebombimpact = true
      text = string.format( "%s, %s, smoking impact points of bombs is now ON.", self.rangename, playername )
    end
    self:_DisplayMessageToGroup( unit, text, 5, false, true )
  end

end

--- Toggle status of time delay for smoking bomb impact points
-- @param #RANGE self
-- @param #string unitname Name of the player unit.
function RANGE:_SmokeBombDelayOnOff( unitname )
  self:F( unitname )

  local unit, playername, _multiplayer = self:_GetPlayerUnitAndName( unitname )
  if unit and playername then
    local text
    if self.PlayerSettings[playername].delaysmoke == true then
      self.PlayerSettings[playername].delaysmoke = false
      text = string.format( "%s, %s, delayed smoke of bombs is now OFF.", self.rangename, playername )
    else
      self.PlayerSettings[playername].delaysmoke = true
      text = string.format( "%s, %s, delayed smoke of bombs is now ON.", self.rangename, playername )
    end
    self:_DisplayMessageToGroup( unit, text, 5, false, true )
  end

end

--- Toggle display messages to player.
-- @param #RANGE self
-- @param #string unitname Name of the player unit.
function RANGE:_MessagesToPlayerOnOff( unitname )
  self:F( unitname )

  local unit, playername, _multiplayer = self:_GetPlayerUnitAndName( unitname )
  if unit and playername then
    local text
    if self.PlayerSettings[playername].messages == true then
      text = string.format( "%s, %s, display of ALL messages is now OFF.", self.rangename, playername )
    else
      text = string.format( "%s, %s, display of ALL messages is now ON.", self.rangename, playername )
    end
    self:_DisplayMessageToGroup( unit, text, 5, false, true )
    self.PlayerSettings[playername].messages = not self.PlayerSettings[playername].messages
  end

end

--- Targetsheet saves if player on or off.
-- @param #RANGE self
-- @param #string _unitname Name of the player unit.
function RANGE:_TargetsheetOnOff( _unitname )
  self:F2( _unitname )

  -- Get player unit and player name.
  local unit, playername, _multiplayer = self:_GetPlayerUnitAndName( _unitname )

  -- Check if we have a player.
  if unit and playername then

    -- Player data.
    local playerData = self.PlayerSettings[playername] -- #RANGE.PlayerData

    if playerData then

      -- Check if option is enabled at all.
      local text = ""
      if self.targetsheet then

        -- Invert current setting.
        playerData.targeton = not playerData.targeton

        -- Inform player.
        if playerData and playerData.targeton == true then
          text = string.format( "Roger, your targetsheets are now SAVED." )
        else
          text = string.format( "Affirm, your targetsheets are NOT SAVED." )
        end

      else
        text = "Negative, target sheet data recorder is broken on this range."
      end

      -- Message to player.
      -- self:MessageToPlayer(playerData, text, nil, playerData.name, 5)
      self:_DisplayMessageToGroup( unit, text, 5, false, false )
    end
  end

end

--- Toggle status of flaring direct hits of range targets.
-- @param #RANGE self
-- @param #string unitname Name of the player unit.
function RANGE:_FlareDirectHitsOnOff( unitname )
  self:F( unitname )

  local unit, playername, _multiplayer = self:_GetPlayerUnitAndName( unitname )
  if unit and playername then
    local text
    if self.PlayerSettings[playername].flaredirecthits == true then
      self.PlayerSettings[playername].flaredirecthits = false
      text = string.format( "%s, %s, flaring direct hits is now OFF.", self.rangename, playername )
    else
      self.PlayerSettings[playername].flaredirecthits = true
      text = string.format( "%s, %s, flaring direct hits is now ON.", self.rangename, playername )
    end
    self:_DisplayMessageToGroup( unit, text, 5, false, true )
  end

end

--- Mark bombing targets with smoke.
-- @param #RANGE self
-- @param #string unitname Name of the player unit.
function RANGE:_SmokeBombTargets( unitname )
  self:F( unitname )

  for _, _bombtarget in pairs( self.bombingTargets ) do
    local _target = _bombtarget.target -- Wrapper.Positionable#POSITIONABLE
    local coord = self:_GetBombTargetCoordinate( _bombtarget )
    if coord then
      coord:Smoke( self.BombSmokeColor )
    end
  end

  if unitname then
    local unit, playername = self:_GetPlayerUnitAndName( unitname )
    local text = string.format( "%s, %s, bombing targets are now marked with %s smoke.", self.rangename, playername, self:_smokecolor2text( self.BombSmokeColor ) )
    self:_DisplayMessageToGroup( unit, text, 5 )
  end

end

--- Mark strafing targets with smoke.
-- @param #RANGE self
-- @param #string unitname Name of the player unit.
function RANGE:_SmokeStrafeTargets( unitname )
  self:F( unitname )

  for _, _target in pairs( self.strafeTargets ) do
    _target.coordinate:Smoke( self.StrafeSmokeColor )
  end

  if unitname then
    local unit, playername = self:_GetPlayerUnitAndName( unitname )
    local text = string.format( "%s, %s, strafing tragets are now marked with %s smoke.", self.rangename, playername, self:_smokecolor2text( self.StrafeSmokeColor ) )
    self:_DisplayMessageToGroup( unit, text, 5 )
  end

end

--- Mark approach boxes of strafe targets with smoke.
-- @param #RANGE self
-- @param #string unitname Name of the player unit.
function RANGE:_SmokeStrafeTargetBoxes( unitname )
  self:F( unitname )

  for _, _target in pairs( self.strafeTargets ) do
    local zone = _target.polygon -- Core.Zone#ZONE
    zone:SmokeZone( self.StrafePitSmokeColor, 4 )
    for _, _point in pairs( _target.smokepoints ) do
      _point:SmokeOrange() -- Corners are smoked orange.
    end
  end

  if unitname then
    local unit, playername = self:_GetPlayerUnitAndName( unitname )
    local text = string.format( "%s, %s, strafing pit approach boxes are now marked with %s smoke.", self.rangename, playername, self:_smokecolor2text( self.StrafePitSmokeColor ) )
    self:_DisplayMessageToGroup( unit, text, 5 )
  end

end

--- Sets the smoke color used to smoke players bomb impact points.
-- @param #RANGE self
-- @param #string _unitName Name of the player unit.
-- @param Utilities.Utils#SMOKECOLOR color ID of the smoke color.
function RANGE:_playersmokecolor( _unitName, color )
  self:F( { unitname = _unitName, color = color } )

  local _unit, _playername = self:_GetPlayerUnitAndName( _unitName )
  if _unit and _playername then
    self.PlayerSettings[_playername].smokecolor = color
    local text = string.format( "%s, %s, your bomb impacts are now smoked in %s.", self.rangename, _playername, self:_smokecolor2text( color ) )
    self:_DisplayMessageToGroup( _unit, text, 5 )
  end

end

--- Sets the flare color used when player makes a direct hit on target.
-- @param #RANGE self
-- @param #string _unitName Name of the player unit.
-- @param Utilities.Utils#FLARECOLOR color ID of flare color.
function RANGE:_playerflarecolor( _unitName, color )
  self:F( { unitname = _unitName, color = color } )

  local _unit, _playername = self:_GetPlayerUnitAndName( _unitName )
  if _unit and _playername then
    self.PlayerSettings[_playername].flarecolor = color
    local text = string.format( "%s, %s, your direct hits are now flared in %s.", self.rangename, _playername, self:_flarecolor2text( color ) )
    self:_DisplayMessageToGroup( _unit, text, 5 )
  end

end

--- Converts a smoke color id to text. E.g. SMOKECOLOR.Blue --> "blue".
-- @param #RANGE self
-- @param Utilities.Utils#SMOKECOLOR color Color Id.
-- @return #string Color text.
function RANGE:_smokecolor2text( color )
  self:F( color )

  local txt = ""
  if color == SMOKECOLOR.Blue then
    txt = "blue"
  elseif color == SMOKECOLOR.Green then
    txt = "green"
  elseif color == SMOKECOLOR.Orange then
    txt = "orange"
  elseif color == SMOKECOLOR.Red then
    txt = "red"
  elseif color == SMOKECOLOR.White then
    txt = "white"
  else
    txt = string.format( "unknown color (%s)", tostring( color ) )
  end

  return txt
end

--- Sets the flare color used to flare players direct target hits.
-- @param #RANGE self
-- @param Utilities.Utils#FLARECOLOR color Color Id.
-- @return #string Color text.
function RANGE:_flarecolor2text( color )
  self:F( color )

  local txt = ""
  if color == FLARECOLOR.Green then
    txt = "green"
  elseif color == FLARECOLOR.Red then
    txt = "red"
  elseif color == FLARECOLOR.White then
    txt = "white"
  elseif color == FLARECOLOR.Yellow then
    txt = "yellow"
  else
    txt = string.format( "unknown color (%s)", tostring( color ) )
  end

  return txt
end

--- Checks if a static object with a certain name exists. It also added it to the MOOSE data base, if it is not already in there.
-- @param #RANGE self
-- @param #string name Name of the potential static object.
-- @return #boolean Returns true if a static with this name exists. Retruns false if a unit with this name exists. Returns nil if neither unit or static exist.
function RANGE:_CheckStatic( name )
  self:F2( name )

  -- Get DCS static object.
  local _DCSstatic = StaticObject.getByName( name )

  if _DCSstatic and _DCSstatic:isExist() then

    -- Static does exist at least in DCS. Check if it also in the MOOSE DB.
    local _MOOSEstatic = STATIC:FindByName( name, false )

    -- If static is not yet in MOOSE DB, we add it. Can happen for cargo statics!
    if not _MOOSEstatic then
      self:T( self.lid .. string.format( "Adding DCS static to MOOSE database. Name = %s.", name ) )
      _DATABASE:AddStatic( name )
    end

    return true
  else
    self:T3( self.lid .. string.format( "No static object with name %s exists.", name ) )
  end

  -- Check if a unit has this name.
  if UNIT:FindByName( name ) then
    return false
  else
    self:T3( self.lid .. string.format( "No unit object with name %s exists.", name ) )
  end

  -- If not unit or static exist, we return nil.
  return nil
end

--- Get max speed of controllable.
-- @param #RANGE self
-- @param Wrapper.Controllable#CONTROLLABLE controllable
-- @return Maximum speed in km/h.
function RANGE:_GetSpeed( controllable )
  self:F2( controllable )

  -- Get DCS descriptors
  local desc = controllable:GetDesc()

  -- Get speed
  local speed = 0
  if desc then
    speed = desc.speedMax * 3.6
    self:T( { speed = speed } )
  end

  return speed
end

--- Returns the unit of a player and the player name. If the unit does not belong to a player, nil is returned.
-- @param #RANGE self
-- @param #string _unitName Name of the player unit.
-- @return Wrapper.Unit#UNIT Unit of player.
-- @return #string Name of the player.
-- @return #boolean If true, group has > 1 player in it
function RANGE:_GetPlayerUnitAndName( _unitName, PlayerName )
  --self:I( _unitName )

  if _unitName ~= nil then

    local multiplayer = false

    -- Get DCS unit from its name.
    local DCSunit = Unit.getByName( _unitName )

    if DCSunit and DCSunit.getPlayerName then

      local playername = DCSunit:getPlayerName() or PlayerName or "None"
      local unit = UNIT:Find( DCSunit )

      self:T2( { DCSunit = DCSunit, unit = unit, playername = playername } )
      if DCSunit and unit and playername then
        self:F2(playername)
        local grp = unit:GetGroup()
        if grp and grp:CountAliveUnits() > 1 then
          multiplayer = true
        end
        return unit, playername, multiplayer
      end

    end

  end

  -- Return nil if we could not find a player.
  return nil, nil, nil
end

--- Returns a string which consists of the player name.
-- @param #RANGE self
-- @param #string unitname Name of the player unit.
function RANGE:_myname( unitname )
  self:F2( unitname )
  local pname = "Ghost 1 1"
  local unit = UNIT:FindByName( unitname )
  if unit and unit:IsAlive() then
    local grp = unit:GetGroup()
    if grp and grp:IsAlive() then
      pname = grp:GetCustomCallSign(true,true)
    end
  end
  return pname
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
